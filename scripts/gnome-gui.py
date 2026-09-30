#!/usr/bin/python3
"""GNOME のセッションの画面を撮り、キーボードとポインタの入力を送る。

docs/gnome-headless-session.md で常駐させた GNOME のセッションを、同じユーザーの
シェル（SSH など）から扱う。Claude Code が GUI の動作を確かめるときに使う。
使うのは Mutter の公式の D-Bus API で、GNOME Shell の unsafe mode は要らない。

  shot FILE.png [--no-cursor]  画面を PNG にする（ScreenCast → PipeWire → GStreamer）
  windows                      アプリと窓のタイトルの一覧（AT-SPI）
  key KEY...                   キーを押して離す。ctrl+l のように + でつなぐと同時押し
                               （文字キーは小文字で書く。大文字は Shift も付く）
  type TEXT                    文字を打つ（今のキー配列にある文字だけ。改行は Return）
  move X Y                     ポインタを動かす（画面の左上が 0 0）
  click X Y [left|middle|right] [--double]
                               クリックする（既定は left）
  scroll X Y STEPS             ホイールを回す（正で下、負で上）
  launch DESKTOP_ID [ARG...]   アプリを起動する（例: org.gnome.TextEditor）

入力は、コマンドごとに RemoteDesktop のセッションを作って送り、止める。
作った直後の入力と、止める直前の入力が Mutter に捨てられることがあったので、
害の無い入力（Control_L の押して離す・動かない相対移動）を先に送り、前後に間を置く。

使っている間は、上部バーに画面共有の表示が出る（画面の写しにも写る）。
キー配列に無い文字（é や日本語）は、Mutter が黙って捨てる。日本語は IBus で
ローマ字を打つ形になるはず（確かめていない）。

/usr/bin/python3 で動かす（Homebrew の python3 には gi が無い）。
"""
import os
import re
import shlex
import shutil
import subprocess
import sys
import time

import gi

gi.require_version('Atspi', '2.0')
gi.require_version('Gdk', '4.0')
gi.require_version('Gst', '1.0')
from gi.repository import Atspi, Gdk, Gio, GLib, Gst  # noqa: E402

RD = 'org.gnome.Mutter.RemoteDesktop'
SC = 'org.gnome.Mutter.ScreenCast'
DC = 'org.gnome.Mutter.DisplayConfig'
SETTLE = 0.3   # 入力の前後に置く間（秒）
PACE = 0.01    # キーを 1 つ打つごとの間（秒）
BUTTONS = {'left': 0x110, 'right': 0x111, 'middle': 0x112}  # BTN_LEFT など（linux/input-event-codes.h）
ALIASES = {'ctrl': 'Control_L', 'control': 'Control_L', 'alt': 'Alt_L', 'shift': 'Shift_L',
           'super': 'Super_L', 'enter': 'Return', 'esc': 'Escape', 'del': 'Delete'}

bus = Gio.bus_get_sync(Gio.BusType.SESSION)


def call(dest, path, iface, method, args=None, rtype=None):
    try:
        ret = bus.call_sync(dest, path, iface, method, args,
                            GLib.VariantType(rtype) if rtype else None,
                            Gio.DBusCallFlags.NONE, 10000, None)
    except GLib.Error as e:
        if 'ServiceUnknown' in e.message or 'NameHasNoOwner' in e.message:
            sys.exit(f'中断: {dest} がセッションバスに無い。GNOME のセッションが動いていない'
                     '（docs/gnome-headless-session.md）')
        raise
    return ret.unpack() if ret is not None else None


def primary_connector():
    """主のモニター（ヘッドレスのセッションでは仮想モニター Meta-0）のコネクタ名。"""
    _serial, _monitors, logical, _props = call(DC, '/org/gnome/Mutter/DisplayConfig', DC,
                                               'GetCurrentState', None,
                                               '(ua((ssss)a(siiddada{sv})a{sv})a(iiduba(ssss)a{sv})a{sv})')
    for _x, _y, _scale, _transform, primary, specs, _p in logical:
        if primary and specs:
            return specs[0][0]
    if logical and logical[0][5]:
        return logical[0][5][0][0]
    sys.exit('中断: モニターが 1 枚も無い。gnome-shell に --virtual-monitor が付いていない'
             '（docs/gnome-headless-session.md の手順）')


def start_and_wait(session_path, session_iface, stream_path):
    """セッションを始め、ストリームの PipeWire のノードができるまで待つ。"""
    node = []
    loop = GLib.MainLoop()

    def on_added(_conn, _sender, _path, _iface, _signal, params):
        node.append(params.unpack()[0])
        loop.quit()

    sub = bus.signal_subscribe(None, SC + '.Stream', 'PipeWireStreamAdded', stream_path,
                               None, Gio.DBusSignalFlags.NONE, on_added)
    call(RD if session_iface.startswith(RD) else SC, session_path, session_iface, 'Start')
    timeout = GLib.timeout_add_seconds(10, loop.quit)
    loop.run()
    if node:
        GLib.source_remove(timeout)
    bus.signal_unsubscribe(sub)
    if not node:
        sys.exit('中断: 10 秒待っても PipeWire のストリームができなかった')
    return node[0]


def shot(path, cursor=True):
    session = call(SC, '/org/gnome/Mutter/ScreenCast', SC, 'CreateSession',
                   GLib.Variant('(a{sv})', ({},)), '(o)')[0]
    stream = call(SC, session, SC + '.Session', 'RecordMonitor',
                  GLib.Variant('(sa{sv})', (primary_connector(),
                                            {'cursor-mode': GLib.Variant('u', 1 if cursor else 0)})),
                  '(o)')[0]
    node = start_and_wait(session, SC + '.Session', stream)
    try:
        Gst.init(None)
        # path= は PipeWire 1.4 で非推奨だが、target-object= は Mutter が渡すノードの ID を受け付けなかった
        pipe = Gst.parse_launch(f'pipewiresrc path={node} always-copy=true ! videoconvert ! '
                                'pngenc snapshot=true ! filesink name=sink')
        pipe.get_by_name('sink').set_property('location', path)
        pipe.set_state(Gst.State.PLAYING)
        msg = pipe.get_bus().timed_pop_filtered(15 * Gst.SECOND,
                                                Gst.MessageType.EOS | Gst.MessageType.ERROR)
        pipe.set_state(Gst.State.NULL)
        if msg is None:
            sys.exit('中断: 15 秒待っても画面が 1 コマも届かなかった')
        if msg.type == Gst.MessageType.ERROR:
            sys.exit(f'中断: GStreamer のエラー: {msg.parse_error()[0].message}')
    finally:
        call(SC, session, SC + '.Session', 'Stop')
    print(path)


class Input:
    """RemoteDesktop のセッション。with の中で入力を送る。"""

    def __enter__(self):
        self.rd = call(RD, '/org/gnome/Mutter/RemoteDesktop', RD, 'CreateSession', None, '(o)')[0]
        sid = call(RD, self.rd, 'org.freedesktop.DBus.Properties', 'Get',
                   GLib.Variant('(ss)', (RD + '.Session', 'SessionId')), '(v)')[0]
        sc = call(SC, '/org/gnome/Mutter/ScreenCast', SC, 'CreateSession',
                  GLib.Variant('(a{sv})', ({'remote-desktop-session-id': GLib.Variant('s', sid)},)),
                  '(o)')[0]
        # ポインタの絶対位置は、このストリーム（主のモニター）の座標で送る
        self.stream = call(SC, sc, SC + '.Session', 'RecordMonitor',
                           GLib.Variant('(sa{sv})', (primary_connector(), {})), '(o)')[0]
        start_and_wait(self.rd, RD + '.Session', self.stream)
        self.keysym(Gdk.KEY_Control_L, True)
        self.keysym(Gdk.KEY_Control_L, False)
        self.notify('NotifyPointerMotionRelative', '(dd)', 0.0, 0.0)
        time.sleep(SETTLE)
        return self

    def __exit__(self, *_exc):
        time.sleep(SETTLE)
        call(RD, self.rd, RD + '.Session', 'Stop')

    def notify(self, method, sig, *args):
        call(RD, self.rd, RD + '.Session', method, GLib.Variant(sig, args))

    def keysym(self, keysym, pressed):
        self.notify('NotifyKeyboardKeysym', '(ub)', keysym, pressed)

    def tap(self, keysyms):
        for k in keysyms:
            self.keysym(k, True)
        for k in reversed(keysyms):
            self.keysym(k, False)
        time.sleep(PACE)

    def move(self, x, y):
        self.notify('NotifyPointerMotionAbsolute', '(sdd)', self.stream, float(x), float(y))


def parse_combo(combo):
    keysyms = []
    for name in combo.split('+'):
        name = ALIASES.get(name.lower(), name)
        k = Gdk.keyval_from_name(name)
        if k in (0, Gdk.KEY_VoidSymbol):
            sys.exit(f'中断: キーの名前が分からない: {name}（Return・Escape・Tab・F1・a など）')
        keysyms.append(k)
    return keysyms


def windows():
    desktop = Atspi.get_desktop(0)
    for i in range(desktop.get_child_count()):
        app = desktop.get_child_at_index(i)
        if app is None:
            continue
        for j in range(app.get_child_count()):
            w = app.get_child_at_index(j)
            if w is None or w.get_role() not in (Atspi.Role.FRAME, Atspi.Role.WINDOW, Atspi.Role.DIALOG):
                continue
            if app.get_name() == 'gnome-shell':
                continue  # 'Main stage' は窓ではない
            # GTK4 のアプリは窓の active の状態を出さなかったので、フォーカスは示さない
            print(f'{app.get_name()}\t{w.get_name()}')


def launch(desktop_id, args):
    if not desktop_id.endswith('.desktop'):
        desktop_id += '.desktop'
    try:
        info = Gio.DesktopAppInfo.new(desktop_id)
    except TypeError:
        info = None
    if info is None:
        sys.exit(f'中断: {desktop_id} が見つからない（/usr/share/applications などの .desktop の名前）')
    # フィールドコード（%U や --file=%f）を含む引数は、ファイルを渡さないので外す。%% は % に戻す
    argv = [a.replace('%%', '%') for a in shlex.split(info.get_commandline())
            if not re.search(r'%[a-zA-Z]', a.replace('%%', ''))]
    # 実行ファイルは、GNOME Shell から起動したときと同じく、ユーザーの systemd の PATH で探す
    # （このシェルの PATH の先頭は Homebrew のことがある）
    env = dict(line.split('=', 1) for line in subprocess.run(
        ['systemctl', '--user', 'show-environment'], capture_output=True, text=True,
        check=True).stdout.splitlines() if '=' in line)
    exe = shutil.which(argv[0], path=env.get('PATH', '/usr/bin:/bin')) or argv[0]
    unit = 'gnome-gui-' + re.sub(r'[^A-Za-z0-9_.-]', '_', desktop_id[:-len('.desktop')]) + f'-{os.getpid()}'
    # アプリを一時的なサービスの主のプロセスにする（gio launch を挟むと、gio が終わったときにアプリも止められた）
    subprocess.run(['systemd-run', '--user', '--collect', '--quiet', f'--unit={unit}',
                    '--', exe, *argv[1:], *args], check=True)
    print(unit)


def usage(code):
    print(__doc__.split('\n\n')[2], file=sys.stdout if code == 0 else sys.stderr)
    return code


def numbers(args, kinds):
    """引数を数に直す。セッションを作る前に確かめる（作った後に失敗すると、途中で止まる）。"""
    try:
        return [kind(a) for kind, a in zip(kinds, args)]
    except ValueError:
        sys.exit(f'中断: 数ではない引数がある: {" ".join(args)}')


def main(argv):
    if argv and argv[0] in ('-h', '--help'):
        return usage(0)
    if not argv:
        return usage(2)
    cmd, args = argv[0], argv[1:]
    if cmd == 'shot' and args:
        shot(args[0], cursor='--no-cursor' not in args[1:])
    elif cmd == 'windows':
        windows()
    elif cmd == 'launch' and args:
        launch(args[0], args[1:])
    elif cmd == 'key' and args:
        combos = [parse_combo(a) for a in args]
        with Input() as inp:
            for keysyms in combos:
                inp.tap(keysyms)
    elif cmd == 'type' and len(args) == 1:
        special = {'\n': Gdk.KEY_Return, '\t': Gdk.KEY_Tab}
        with Input() as inp:
            for ch in args[0]:
                inp.tap([special.get(ch) or Gdk.unicode_to_keyval(ord(ch))])
    elif cmd == 'move' and len(args) == 2:
        x, y = numbers(args, (float, float))
        with Input() as inp:
            inp.move(x, y)
    elif cmd == 'click' and len(args) >= 2 and all(a in BUTTONS or a == '--double' for a in args[2:]):
        x, y = numbers(args[:2], (float, float))
        button = BUTTONS[next((a for a in args[2:] if a in BUTTONS), 'left')]
        with Input() as inp:
            inp.move(x, y)
            time.sleep(PACE)
            for _ in range(2 if '--double' in args[2:] else 1):
                inp.notify('NotifyPointerButton', '(ib)', button, True)
                inp.notify('NotifyPointerButton', '(ib)', button, False)
                time.sleep(PACE)
    elif cmd == 'scroll' and len(args) == 3:
        x, y, steps = numbers(args, (float, float, int))
        with Input() as inp:
            inp.move(x, y)
            time.sleep(PACE)
            inp.notify('NotifyPointerAxisDiscrete', '(ui)', 0, steps)
    else:
        return usage(2)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
