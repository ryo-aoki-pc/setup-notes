# GNOME のデスクトップ共有の手順（PC の画面のデスクトップに RDP でつなぐ。CLI だけで設定する）

## 実施手順

- [検証記録](verification/gnome-desktop-sharing.md)・[参考資料](reference/gnome-desktop-sharing.md)

> [!IMPORTANT]
> - **PC の画面で、共有するユーザーがパスワードでログインしておく**。共有するのはそのデスクトップで、RDP の資格情報はそのとき開くログインのキーリングに置く（自動ログインで使うなら[自動ログインで使う（任意）](#自動ログインで使う任意)）
> - **そのユーザー本人のシェル（SSH でよい）で貼る**。`sudo -i` / `su -` したシェルでは貼らない（設定と資格情報は、貼ったユーザーのものになるため）
> - 前提は [gnome-power.md 手順 1・2](gnome-power.md#実施手順)（サスペンドできる PC では、同書の手順 3・4 も）。画面が暗くなるかロックされると、RDP の接続が切れる
> - **手順 5 は RDP のユーザー名とパスワードの対話入力がある**。入力し終えてから次の手順を貼る
> - 手順 10（クライアントからの接続）だけ別のマシンで行う
> - 同じユーザーの[ヘッドレスのセッション](gnome-headless-session.md)とは併用できない。[リモートログイン](gnome-remote-desktop.md)と同じ PC で使うときは、手順 1 でポートが自動で 3390 になる

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: [見るだけにする（任意）](#見るだけにする任意)・[接続元を LAN に絞る（任意）](#接続元を-lan-に絞る任意)・[自動ログインで使う（任意）](#自動ログインで使う任意)。戻すときは[ロールバック](#ロールバック)

> [!WARNING]
> **この手順書は、実機でも VM でも流していない（未検証）**。上流のソースと RHEL 10 の文書から書き、確かめたのはブロックの構文と、自動ログインの節のキーリングの操作をコンテナで模擬したことだけ（[検証記録](verification/gnome-desktop-sharing.md)）。確認の箇条書きにある出力も、実物のものではない。

1. 変数を設定する（`SERVER_IP` は必ず値を入れる）。

   ```bash
   SERVER_IP=192.168.10.100            # ← 自分の値に書き換える。クライアントが接続に使う IP。<SERVER_IP>
   ```

   ```bash
   SERVER_NAME=$(hostname)             # 証明書の CN と SAN に入る（自動）。<HOSTNAME>
   SERVER_FQDN=$(hostname -f)          # 同上。<HOSTNAME>.<DOMAIN>
   RDP_PORT=$(if [ "$(systemctl is-enabled gnome-remote-desktop.service 2>/dev/null)" = enabled ]; then echo 3390; else echo 3389; fi)   # 待ち受けるポート（自動）。<RDP_PORT>
   for v in USER SERVER_IP SERVER_NAME SERVER_FQDN RDP_PORT; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須なのは `SERVER_IP` の 1 行だけ**。残りは既定のままでよい
   - `RDP_PORT` は、リモートログインのシステムのデーモン（`gnome-remote-desktop.service`）が有効なら `3390`、そうでなければ `3389` になる
   - 最後に値を読み戻して確かめる
   - `USER` が `root` なら、ここで止めて、共有するユーザーのシェルで貼り直す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**、手順 1 の 2 つのブロックを貼り直してから先へ進む

1. PC の画面のセッション・キーリング・画面の設定を確かめる。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。共有するユーザーのシェルで貼り直す' >&2
   else
     loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $4 == "seat0"'
     busctl --user status org.gnome.Mutter.ScreenCast >/dev/null 2>&1 && echo 'ScreenCast: ok'
     busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked
     /usr/bin/gsettings get org.gnome.desktop.session idle-delay
     /usr/bin/gsettings get org.gnome.desktop.screensaver lock-enabled
     /usr/bin/gsettings get org.gnome.desktop.remote-desktop.rdp enable
     systemctl --user is-enabled gnome-remote-desktop-headless.service
   fi
   ```

   - 次の 7 行が出ればよい
     - `<SESSION_ID> <UID> <USER> seat0 …` の形の行（PC の画面のセッション）
     - `ScreenCast: ok`
     - `b false`（ログインのキーリングが開いている）
     - `uint32 0` と `false`（画面を消さず、ロックしない）
     - `false`（デスクトップ共有はまだ無効）
     - `disabled`
   - 1 行目が出ないときは、PC の画面でこのユーザーでログインしてから貼り直す
   - `b true` なら、キーリングが閉じている。PC の画面でパスワードでログインし直す（自動ログイン・指紋でのログインでは開かない）
   - `uint32 0` と `false` でなければ、[gnome-power.md 手順 1・2](gnome-power.md#実施手順) を行う
   - `true` なら、設定アプリなどでデスクトップ共有を有効にしてある。この手順の設定で上書きする
   - `enabled` なら、同じユーザーのヘッドレスのセッションの RDP を使っている。ここで止める

1. 変える設定の元値と共用する TLS 設定を退避し、証明書と鍵を作る（既にあれば作らない）。

   ```bash
   if [ -z "${SERVER_IP}" ] || [ -z "${SERVER_NAME}" ] || [ -z "${SERVER_FQDN}" ]; then
     echo '中断: 手順 1 の変数が空のまま。手順 1 を貼り直す' >&2
   else
     (
       set -e
       trap 'echo "中断: 手順 3 が失敗した。手順 4 へ進まない" >&2' ERR
       umask 077
       if [ -e ~/.local/state/gnome-desktop-sharing-setup ] || [ -L ~/.local/state/gnome-desktop-sharing-setup ]; then
         if [ -L ~/.local/state/gnome-desktop-sharing-setup ] ||
            [ ! -f ~/.local/state/gnome-desktop-sharing-setup/backup-complete ]; then
           echo '中断: 設定の退避が不完全。退避内容を確認し、先へ進まない' >&2
           exit 1
         fi
       else
         mkdir -p ~/.local/state
         mkdir ~/.local/state/gnome-desktop-sharing-setup
         for key in port negotiate-port view-only tls-cert tls-key; do
           dconf read "/org/gnome/desktop/remote-desktop/rdp/${key}" > ~/.local/state/gnome-desktop-sharing-setup/"${key}"
         done
         touch ~/.local/state/gnome-desktop-sharing-setup/backup-complete
       fi
       rm -f ~/.local/state/gnome-desktop-sharing-setup/ready ~/.local/state/gnome-desktop-sharing-setup/restored
       if [ -e ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] || [ -L ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] ||
          [ -e ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ] || [ -L ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ]; then
         if [ ! -s ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] ||
            [ ! -s ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ]; then
           echo '中断: 証明書と鍵の両方が必要。既存ファイルは上書きしていない' >&2
           exit 1
         fi
       else
         mkdir -p ~/.local/share/gnome-remote-desktop/certificates
         touch ~/.local/state/gnome-desktop-sharing-setup/created-certificate
         openssl req -x509 -newkey rsa:2048 -noenc -days 3650 \
           -subj "/CN=${SERVER_NAME}" \
           -addext "subjectAltName=DNS:${SERVER_NAME},DNS:${SERVER_FQDN},DNS:${SERVER_IP},IP:${SERVER_IP}" \
           -addext "extendedKeyUsage=serverAuth" \
           -keyout ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key \
           -out    ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
         chmod 644 ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
         sha256sum ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt \
           ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key > ~/.local/state/gnome-desktop-sharing-setup/created.sha256
       fi
       openssl x509 -in ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt -noout
       openssl pkey -in ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key -passin pass: -noout
       touch ~/.local/state/gnome-desktop-sharing-setup/ready
       ls -l ~/.local/share/gnome-remote-desktop/certificates
       echo '設定の退避と証明書の準備が完了'
     )
   fi
   ```

   - 最後に `設定の退避と証明書の準備が完了` と出れば、手順 4 へ進む
   - 新規生成した場合は `rdp-tls.crt`（`-rw-r--r--`）と `rdp-tls.key`（`-rw-------`）が出る。既存の証明書と鍵は上書きしない
   - 証明書のパスは、[ヘッドレスのセッション](gnome-headless-session.md)の手順書と同じ。そちらで作ってあれば、それを使う
   - `中断:` が出たら、手順 4 以降へ進まない。[ロールバック](#ロールバック)の手順 3・4 で戻す

1. `grdctl` で、証明書と鍵・ポートと、リモートからの操作を設定する。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: 手順 1 の RDP_PORT が空のまま。手順 1 を貼り直す' >&2
   elif [ ! -f ~/.local/state/gnome-desktop-sharing-setup/ready ]; then
     echo '中断: 手順 3 が完了していない。設定は変更しない' >&2
   else
     rm -f ~/.local/state/gnome-desktop-sharing-setup/restored &&
     grdctl rdp set-tls-cert ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt &&
     grdctl rdp set-tls-key ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key &&
     grdctl rdp set-port "${RDP_PORT}" &&
     grdctl rdp disable-port-negotiation &&
     grdctl rdp disable-view-only &&
     /usr/bin/gsettings list-recursively org.gnome.desktop.remote-desktop.rdp
   fi
   ```

   - 最後の行で読み戻す。`negotiate-port false`・`port uint16 <RDP_PORT>`・`tls-cert` と `tls-key` の証明書と鍵のパス・`view-only false` が出ればよい
   - `disable-view-only` は、クライアントからのキーボードとマウスを受け付ける設定（既定は見るだけ）

1. RDP のユーザー名とパスワードを、引数なしで対話入力する。

   ```bash
   grdctl rdp set-credentials
   ```

   - ユーザー名とパスワードを聞かれる。クライアントが接続するときに入れるもので、OS のアカウントと違ってよい
   - 引数なしで打つのは、パスワードをシェルの履歴に残さないため
   - ログインのキーリングに保存される
   - **次の手順は、ユーザー名とパスワードを入力し終えてから貼る**（続けて貼ると入力として食われる）

1. デスクトップ共有を有効にする。

   ```bash
   grdctl rdp enable
   systemctl --user is-enabled gnome-remote-desktop.service
   ```

   - `enabled` と出ればよい
   - `grdctl rdp enable` は、ユーザーの `gnome-remote-desktop.service` を有効にして起動する。ログインするたびに起動する
   - 待ち受けたかは、手順 8 で確かめる

1. ファイアウォールで、`RDP_PORT` の TCP を開ける。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: 手順 1 の RDP_PORT が空のまま。手順 1 を貼り直す' >&2; else
   sudo firewall-cmd --permanent --add-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   fi
   ```

   - `success` が 2 行出て、最後に `<RDP_PORT>/tcp` を含む行が出ればよい

1. デーモンが待ち受けているかを確かめる。

   ```bash
   grdctl status
   ss -Hlntp "sport = :${RDP_PORT:?手順 1 の RDP_PORT が空のまま}"
   ```

   - `grdctl status` で、`Unit status: active`・`Status: enabled`・`Port: <RDP_PORT>`・`View-only: no`・`Negotiate port: no`・`Username: (hidden)`・`Password: (hidden)` を確かめる
   - `TLS fingerprint` の値を控えておく（手順 9 と手順 10 で使う）
   - `ss` が `LISTEN … *:<RDP_PORT> … users:(("gnome-remote-de",…))` の 1 行を出せばよい
   - **注意**: `grdctl status` の `Port:` は設定した値で、実際に待ち受けたポートではない。ポートは `ss` で見る

1. TLS のハンドシェイクと、提示される証明書を確かめる。

   ```bash
   cat > ~/rdp_tls_probe.py <<'PY'
   #!/usr/bin/env python3
   # usage: python3 rdp_tls_probe.py <host> [port]
   import socket, ssl, struct, sys, hashlib, subprocess
   host = sys.argv[1]; port = int(sys.argv[2]) if len(sys.argv) > 2 else 3389
   # X.224 Connection Request + RDP_NEG_REQ (PROTOCOL_SSL|PROTOCOL_HYBRID)
   neg = struct.pack('<BBHI', 0x01, 0x00, 8, 0x00000003)
   x224 = bytes([len(neg) + 6, 0xE0, 0, 0, 0, 0, 0]) + neg
   tpkt = struct.pack('>BBH', 3, 0, 4 + len(x224)) + x224
   s = socket.create_connection((host, port), timeout=10)
   s.sendall(tpkt)
   resp = s.recv(1024)
   t, flags, length, proto = struct.unpack('<BBHI', resp[11:19])
   print(f"negotiation: type=0x{t:02x} ({'RESPONSE' if t == 2 else 'FAILURE'}) selectedProtocol=0x{proto:x}")
   if t != 2: sys.exit(1)
   ctx = ssl.create_default_context(); ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE
   ts = ctx.wrap_socket(s, server_hostname=host)
   der = ts.getpeercert(binary_form=True)
   print("tls:", ts.version(), ts.cipher()[0])
   print("fingerprint:", ':'.join(f'{b:02x}' for b in hashlib.sha256(der).digest()))
   pem = ssl.DER_cert_to_PEM_cert(der)
   print(subprocess.run(['openssl', 'x509', '-noout', '-subject', '-ext', 'subjectAltName'], input=pem, capture_output=True, text=True).stdout, end='')
   ts.close()
   PY
   /usr/bin/python3 ~/rdp_tls_probe.py "${SERVER_IP}" "${RDP_PORT}"
   grdctl status 2>/dev/null | grep 'TLS fingerprint'
   ```

   - 次の 3 つがそろえばよい
     - `selectedProtocol=0x2` でネゴシエーションが成立する
     - `fingerprint:` の行が、最後の `TLS fingerprint:` の行と**完全一致**する
     - SAN に、接続に使う名前が `DNS:` エントリとして含まれている
   - 確認が済んだら `rm ~/rdp_tls_probe.py` で消してよい（この手順書が作る唯一の作業ファイル）

1. LAN 内の別のマシンから、RDP クライアントでつなぐ。

   - AlmaLinux 10 の FreeRDP（`freerdp` パッケージ）なら `xfreerdp /v:<SERVER_IP>:<RDP_PORT> /u:<RDP のユーザー名>` の形でつなぐ。Windows なら「リモート デスクトップ接続」で `<SERVER_IP>:<RDP_PORT>` につなぐ
   - `<SERVER_IP>`・`<RDP_PORT>`・`<RDP のユーザー名>` は、手順 1 と手順 5 の値に読み替える
   - 証明書の確認を聞かれたら、表示された Thumbprint が手順 8 の `TLS fingerprint` と同じかを見てから受け入れる
   - FreeRDP は `Domain:` も聞く。空のまま Enter を押す
   - パスワードは手順 5 のもの。通ると、PC の画面に出ているデスクトップが、PC の画面の解像度のまま出る
   - クライアントでの操作は、PC の画面にもそのまま出る。PC の上部バーには、共有中の印が出る
   - 問題があれば、PC で `journalctl --user -b -u gnome-remote-desktop.service` を見る

---

## 見るだけにする（任意）

- **クライアントから操作させるなら、この節は不要**
- 実施手順の後に、このユーザーのシェルで貼る。つないでいるクライアントにもすぐ効く

1. クライアントからのキーボードとマウスを受け付けないようにする。

   ```bash
   grdctl rdp enable-view-only
   grdctl status | grep 'View-only'
   ```

   - `View-only: yes` と出ればよい

1. 元に戻すときは、クライアントからの操作を受け付ける。

   ```bash
   grdctl rdp disable-view-only
   grdctl status | grep 'View-only'
   ```

   - `View-only: no` と出ればよい

---

## 接続元を LAN に絞る（任意）

- **接続元を制限しないなら、この節は不要**
- [手順 7](#実施手順) は、public ゾーンに属するすべての NIC で `RDP_PORT` の TCP を開く
- 手順 1 の変数を設定したシェルで貼る

1. LAN に絞るなら、送信元サブネットを入れ、ポートの開放を rich rule に置き換える。

   ```bash
   LAN_SUBNET=192.168.10.0/24           # ← 自分の値に書き換える。<LAN_SUBNET>
   ```

   ```bash
   if [ -z "${LAN_SUBNET}" ] || [ -z "${RDP_PORT}" ]; then echo '中断: LAN_SUBNET か、手順 1 の RDP_PORT が空のまま。値を入れて貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=${RDP_PORT} protocol=tcp accept"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   sudo firewall-cmd --list-rich-rules        # source address と port に実際の値が入っていることを確認する
   fi
   ```

   - `success` が 3 行出て、`--list-ports` に `<RDP_PORT>/tcp` が無く、rich rule に `<LAN_SUBNET>` と `<RDP_PORT>` が入っていればよい
   - rich rule は**二重引用符**で囲む。単一引用符だと変数が展開されない（[gnome-remote-desktop.md の同じ節](gnome-remote-desktop.md#接続元を-lan-に絞る任意)）

---

## 自動ログインで使う（任意）

- **PC の起動のたびに PC の画面でパスワードでログインするなら、この節は不要**
- 実施手順を済ませ、PC の画面でパスワードでログインしている間に、このユーザーのシェルで貼る
- 自動ログインではログインのキーリングが開かないので、RDP の資格情報を、パスワードの無い別のキーリング（`rdp`）へ移す。ほかのパスワードはログインのキーリングに残り、暗号化されたまま
- **この節の手順 4 は PC を再起動する**。起動し直してから SSH で入り直し、手順 1 の 2 つのブロックを貼り直してから先へ進む

> [!WARNING]
> **自動ログインにすると、PC の前にいる人は誰でも、パスワード無しでこのユーザーのデスクトップを使える**（前提の gnome-power.md で、ロックもしない）。また、この節の手順 1 で移した RDP のユーザー名とパスワードは、暗号化されずに `~/.local/share/keyrings/` に置かれる。PC を置く場所を信用できるときだけ行う。

1. 手順 5 で入れた RDP の資格情報を、パスワードの無いキーリングへ移す。

   ```bash
   /usr/bin/python3 - <<'PY'
   from gi.repository import Gio, GLib
   bus = Gio.bus_get_sync(Gio.BusType.SESSION)
   svc = '/org/freedesktop/secrets'
   def call(path, iface, method, args, rtype):
       return bus.call_sync('org.freedesktop.secrets', path, iface, method, args,
                            GLib.VariantType(rtype), Gio.DBusCallFlags.NONE, -1, None).unpack()
   def prop(path, iface, name):
       return call(path, 'org.freedesktop.DBus.Properties', 'Get', GLib.Variant('(ss)', (iface, name)), '(v)')[0]
   attrs = {'xdg:schema': 'org.gnome.RemoteDesktop.RdpCredentials'}
   cols = [c for c in prop(svc, 'org.freedesktop.Secret.Service', 'Collections')
           if prop(c, 'org.freedesktop.Secret.Collection', 'Label') == 'rdp']
   unlocked, locked = call(svc, 'org.freedesktop.Secret.Service', 'SearchItems', GLib.Variant('(a{ss})', (attrs,)), '(aoao)')
   if locked:
       raise SystemExit('中断: 閉じたキーリングに RDP の資格情報がある。PC の画面でパスワードでログインしてから貼る')
   src = [i for i in unlocked if not any(i.startswith(c + '/') for c in cols)]
   if not src:
       if unlocked:
           print('すでに移してある:', unlocked[0])
           raise SystemExit(0)
       raise SystemExit('中断: 開いたキーリングに RDP の資格情報が無い。実施手順 5 を済ませてから貼る')
   _, session = call(svc, 'org.freedesktop.Secret.Service', 'OpenSession', GLib.Variant('(sv)', ('plain', GLib.Variant('s', ''))), '(vo)')
   secret = call(svc, 'org.freedesktop.Secret.Service', 'GetSecrets', GLib.Variant('(aoo)', ([src[0]], session)), '(a{o(oayays)})')[0][src[0]]
   if not cols:
       cols = [call(svc, 'org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface', 'CreateWithMasterPassword',
                    GLib.Variant('(a{sv}(oayays))', ({'org.freedesktop.Secret.Collection.Label': GLib.Variant('s', 'rdp')},
                                                     (session, b'', b'', 'text/plain'))), '(o)')[0]]
   props = {'org.freedesktop.Secret.Item.Label': GLib.Variant('s', 'GNOME Remote Desktop RDP credentials'),
            'org.freedesktop.Secret.Item.Attributes': GLib.Variant('a{ss}', attrs)}
   item, _ = call(cols[0], 'org.freedesktop.Secret.Collection', 'CreateItem',
                  GLib.Variant('(a{sv}(oayays)b)', (props, (session, b'', bytes(secret[2]), secret[3]), True)), '(oo)')
   for i in src:
       call(i, 'org.freedesktop.Secret.Item', 'Delete', None, '(o)')
   print('移した先:', item)
   PY
   ```

   - `移した先: /org/freedesktop/secrets/collection/rdp/<N>` の形の行が出ればよい
   - 移した後は、ログインのキーリングに RDP の資格情報が残らない（残っていると、自動ログインの後に、PC の画面へキーリングを開く窓が出るはず）
   - 貼り直したときは `すでに移してある:` と出て、何も変えない
   - `中断:` が出たら、何も変えていない

1. RDP の資格情報が、移したキーリングにだけあることを確かめる。

   ```bash
   busctl --user call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service SearchItems 'a{ss}' 1 xdg:schema org.gnome.RemoteDesktop.RdpCredentials
   busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/rdp org.freedesktop.Secret.Collection Locked
   ```

   - `aoao 1 "/org/freedesktop/secrets/collection/rdp/<N>" 0` と、`b false` が出ればよい
   - 1 つ目の `ao` に `/collection/login/` のパスがあれば、この節の手順 1 を貼り直す
   - **注意**: 自動ログインにした後は、実施手順 5 の `grdctl rdp set-credentials` を貼らない（閉じたログインのキーリングに書こうとして、PC の画面に窓を出して止まる）。資格情報を変えるときは、この節の手順 7 で戻してから行う

1. GDM の自動ログインを、このユーザーで有効にする。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。共有するユーザーのシェルで貼り直す' >&2
   elif grep -q '^AutomaticLogin' /etc/gdm/custom.conf; then echo '中断: /etc/gdm/custom.conf に自動ログインの行がすでにある。中身を確かめる' >&2
   else
     sudo sed -i "/^\[daemon\]/a AutomaticLoginEnable=True\nAutomaticLogin=${USER}" /etc/gdm/custom.conf
     grep -A 2 '^\[daemon\]' /etc/gdm/custom.conf
   fi
   ```

   - `[daemon]`・`AutomaticLoginEnable=True`・`AutomaticLogin=<USER>` の 3 行が出ればよい

1. PC を再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - SSH の接続が切れる。PC が起動すると、GDM がこのユーザーで自動でログインする
   - **次の手順は、PC が起動してから SSH で入り直し、手順 1 の 2 つのブロックを貼り直してから貼る**

1. 自動でログインしたセッションで、デスクトップ共有が待ち受けているかを確かめる。

   ```bash
   loginctl show-session "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $4 == "seat0" {print $1}')" -p Service
   grdctl status
   busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/login org.freedesktop.Secret.Collection Locked
   busctl --user get-property org.freedesktop.secrets /org/freedesktop/secrets/collection/rdp org.freedesktop.Secret.Collection Locked
   ss -Hlntp "sport = :${RDP_PORT:?手順 1 の RDP_PORT が空のまま}"
   ```

   - `Service=gdm-autologin` が出る
   - `grdctl status` で `Unit status: active` と `Username: (hidden)` を確かめる
   - 続いて `b true`（ログインのキーリングは閉じたまま）と `b false`（移したキーリングは開いている）が出る。移したキーリングは、パスワードを聞かずに開く
   - `ss` が、[手順 8](#実施手順) と同じ 1 行を出せばよい

1. 別のマシンから、[手順 10](#実施手順) と同じようにつなぐ。

   - 手順 5 のユーザー名とパスワードでつながればよい
   - PC の画面に、キーリングのパスワードを聞く窓が出ていないことを確かめる

1. 元に戻すときは、自動ログインの行と、移したキーリングを消す。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。共有するユーザーのシェルで貼り直す' >&2
   else
     sudo sed -i "/^AutomaticLoginEnable=True$/d; /^AutomaticLogin=${USER}$/d" /etc/gdm/custom.conf
     grep -c '^AutomaticLogin' /etc/gdm/custom.conf
     busctl --user call org.freedesktop.secrets /org/freedesktop/secrets/collection/rdp org.freedesktop.Secret.Collection Delete
   fi
   ```

   - `0` と、`o "/"` が出ればよい
   - RDP の資格情報も消える。次に PC を起動したら、PC の画面でパスワードでログインし、[手順 5](#実施手順) を貼り直す

---

## ロールバック

- 手順 1 の変数を設定したシェルで、上から順に貼る
- [自動ログインで使う](#自動ログインで使う任意)を行ったなら、先に同節の手順 7 で戻し、PC を再起動して PC の画面でパスワードでログインしてから始める（この節の手順 3 は、ログインのキーリングの資格情報を消す）
- [gnome-power.md](gnome-power.md) で変えた値は残る。戻すなら同書の[ロールバック](gnome-power.md#ロールバック)
- この節の手順 3 は、手順 3 で退避した元値に戻す。[ヘッドレスのセッション](gnome-headless-session.md)の RDP を有効にしているときは、共用の TLS 設定と証明書は残す

> [!CAUTION]
> **この節の手順 4 で消す証明書の秘密鍵は取り戻せない**。この手順書が生成し、生成したときの中身のままのものだけを消し、既存の証明書と鍵は残す。

1. ファイアウォールで開けたポートを閉じる。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: 手順 1 の RDP_PORT が空のまま。手順 1 を貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   fi
   ```

   - `success` が 2 行出て、`--list-ports` に `<RDP_PORT>/tcp` が無ければよい

1. [接続元を LAN に絞る](#接続元を-lan-に絞る任意)を行ったときは（この節の手順 1 の代わりに）、rich rule を消す。

   ```bash
   if [ -z "${LAN_SUBNET}" ] || [ -z "${RDP_PORT}" ]; then echo '中断: LAN_SUBNET か、手順 1 の RDP_PORT が空のまま。値を入れて貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=${RDP_PORT} protocol=tcp accept"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-rich-rules
   fi
   ```

   - `LAN_SUBNET` は、[接続元を LAN に絞る](#接続元を-lan-に絞る任意)の手順 1 の 1 つ目のブロックを貼り直して入れる
   - `success` が 2 行出て、その rich rule が消えていればよい

1. デスクトップ共有を止めて資格情報を消し、変えた設定を元値に戻す。

   ```bash
   (
     set -e
     trap 'echo "中断: 復元が失敗した。この節の手順 4 へ進まない" >&2' ERR
     if { [ -e ~/.local/state/gnome-desktop-sharing-setup ] || [ -L ~/.local/state/gnome-desktop-sharing-setup ]; } &&
        { [ -L ~/.local/state/gnome-desktop-sharing-setup ] ||
          [ ! -f ~/.local/state/gnome-desktop-sharing-setup/backup-complete ]; }; then
       echo '中断: 設定の退避が不完全。設定とファイルは変更しない' >&2
       exit 1
     fi
     rm -f ~/.local/state/gnome-desktop-sharing-setup/restored ~/.local/state/gnome-desktop-sharing-setup/keep-tls
     grdctl rdp disable
     grdctl rdp clear-credentials
     if [ -f ~/.local/state/gnome-desktop-sharing-setup/backup-complete ]; then
       keys='port negotiate-port view-only tls-cert tls-key'
       if [ "$(dconf read /org/gnome/desktop/remote-desktop/rdp/headless/enable)" = true ]; then
         keys='port negotiate-port view-only'
         touch ~/.local/state/gnome-desktop-sharing-setup/keep-tls
         echo 'ヘッドレスのセッションの RDP が有効: 共用 TLS 設定と証明書は保持する'
       fi
       for key in ${keys}; do
         if [ -s ~/.local/state/gnome-desktop-sharing-setup/"${key}" ]; then
           dconf write "/org/gnome/desktop/remote-desktop/rdp/${key}" "$(cat ~/.local/state/gnome-desktop-sharing-setup/"${key}")"
         else
           dconf reset "/org/gnome/desktop/remote-desktop/rdp/${key}"
         fi
       done
       touch ~/.local/state/gnome-desktop-sharing-setup/restored
     else
       echo '退避なし: ポート・操作・TLS の設定と証明書は保持する'
     fi
     systemctl --user is-enabled gnome-remote-desktop.service || true
   )
   ```

   - 最後に `disabled` と出ればよい
   - `grdctl rdp disable` は、ユーザーの `gnome-remote-desktop.service` を止めて無効にする
   - `中断:` やエラーが出たら、この節の手順 4 へ進まない

1. この手順で生成した証明書と鍵、設定の退避を消す（取り戻せない）。

   ```bash
   if [ -L ~/.local/state/gnome-desktop-sharing-setup ]; then
     echo '中断: 設定の退避先がリンクになっている。ファイルは削除しない' >&2
   elif [ ! -e ~/.local/state/gnome-desktop-sharing-setup ]; then
     echo '退避なし: 証明書と鍵は削除しない'
   elif [ ! -f ~/.local/state/gnome-desktop-sharing-setup/restored ]; then
     echo '中断: 設定を戻していない。この節の手順 3 を先に完了する' >&2
   else
     (
       set -e
       if [ -f ~/.local/state/gnome-desktop-sharing-setup/created-certificate ] &&
          [ ! -f ~/.local/state/gnome-desktop-sharing-setup/keep-tls ]; then
         if [ ! -f ~/.local/state/gnome-desktop-sharing-setup/created.sha256 ] ||
            [ -L ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] ||
            [ -L ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ]; then
           echo '中断: 生成物を照合できないか、リンクへ置き換わっている。証明書と退避は削除しない' >&2
           exit 1
         fi
         if ! sha256sum --check ~/.local/state/gnome-desktop-sharing-setup/created.sha256; then
           echo '中断: 生成後に証明書か鍵が変わっている。証明書と退避は削除しない' >&2
           exit 1
         fi
         rm -f ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
         rmdir --ignore-fail-on-non-empty ~/.local/share/gnome-remote-desktop/certificates
       fi
       for f in port negotiate-port view-only tls-cert tls-key backup-complete ready restored keep-tls created-certificate created.sha256; do
         rm -f ~/.local/state/gnome-desktop-sharing-setup/"${f}"
       done
       rmdir --ignore-fail-on-non-empty ~/.local/state/gnome-desktop-sharing-setup
       rm -f ~/rdp_tls_probe.py
     )
   fi
   ```

   - 今回生成し、生成時の中身のままの証明書だけが消える。既存の証明書・ほかのファイルは残る
   - ヘッドレスのセッションの RDP が有効なとき（この節の手順 3 で `保持する` と出たとき）は、証明書を残す
   - `中断:` のときは、後から差し替えたものを手で確認する。照合できないものは自動削除しない

---

## 注意点

- **画面が暗くなるかロックされると、RDP の接続が切れる**: GNOME は、ロック画面（無操作で暗くなるときを含む）の間、画面の共有を止める
  - PC でロックを解くまで、新しい接続もできない。前提の [gnome-power.md 手順 1・2](gnome-power.md#実施手順) で、画面を消さず、ロックしないようにしておく
  - クライアントから Super+L などでロックしても切れる
- **ログアウト・再起動の後は、ログインし直すまで使えない**: 共有するデスクトップが無いため。再起動の後は PC の画面でパスワードでログインするか、[自動ログインで使う](#自動ログインで使う任意)
- **PC の画面に、クライアントの操作がすべて見える**: PC の前の人も同じ画面を操作できる。PC の上部バーの共有中の印から、PC の側で共有を止められる
- **写るのは PC の主モニター 1 枚で、解像度は PC のまま**: クライアントの窓の大きさには合わせない
- **同じユーザーのヘッドレスのセッションとは併用できない**: ヘッドレスのデーモンの unit が、この unit と衝突する（`Conflicts=`）
- **後からリモートログインを有効にしたとき**: リモートログインのデーモンが 3389 を使う。この手順で 3389 にしてあれば、手順 1 を貼り直して `RDP_PORT` が 3390 になったのを確かめ、手順 4・7・8 をやり直す（3389 の開放は、[ロールバック](#ロールバック)の手順 1 と同じブロックで閉じる）
  - ほかのユーザーの[ヘッドレスのセッション](gnome-headless-session.md)が 3390 を使っているなら、手順 1 の `RDP_PORT` に空いている別のポートを入れる
- **キーリングが閉じているときに、設定アプリの「リモート デスクトップ」を開かない**: 開いただけで、RDP のパスワードが乱数に書き換えられることがある（設定アプリ 47.7 の既知の不具合）
- **OS のパスワードを SSH の `passwd` で変えると、ログインのキーリングのパスワードと食い違う**: 次のログインでキーリングが開かず、RDP の資格情報を読めない。パスワードは PC の画面の設定アプリで変える
- **Homebrew が PATH の先頭にあると、`gsettings`・`python3` が Homebrew のものになる**（[homebrew.md の注意点](homebrew.md#注意点)）。この手順書は `/usr/bin/` を付けて呼ぶ
- **自己署名証明書**: クライアントは初回に証明書の確認を出す。証明書を作り直したら、クライアントで保存済みの証明書を消すか、変更の警告を承認する（gnome-remote-desktop.md の注意点と同じ）
