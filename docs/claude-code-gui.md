# Claude Code から GNOME の GUI を撮って操作する手順（ヘッドレスのセッション）

## 実施手順

- [検証記録](verification/claude-code-gui.md)・[参考資料](reference/claude-code-gui.md)・[ロールバックと注意点](extra/claude-code-gui.md)

> [!IMPORTANT]
> - **Claude Code が動くユーザー本人のシェル（SSH でよい）で貼る**。`sudo -i` / `su -` したシェルでは貼らない
> - 前提は [gnome-headless-session.md 手順 1・2](gnome-headless-session.md#実施手順)（ヘッドレスのセッションを動かすところまで。RDP の設定は要らない）と、[AlmaLinux 10 の初期設定の「画面オフ・画面ロック・自動サスペンドを止める（任意）」](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)の手順 1・2（ロックされると、画面の前にいない Claude Code には解けない）
> - このリポジトリの [`scripts/gnome-gui.py`](../scripts/gnome-gui.py) を使う。clone した場所を手順 1 の `REPO` に入れる

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: Claude Code からの使い方は[使い方の基本](#使い方の基本)。仮想モニターの大きさを変えるなら[仮想モニターの大きさを変える（任意）](#仮想モニターの大きさを変える任意)。戻すときは[ロールバック](extra/claude-code-gui.md#ロールバック)

1. 変数を設定する。

   ```bash
   REPO=~/setup-notes                  # このリポジトリを clone した場所（scripts/gnome-gui.py を使う）。<REPO>
   VIRTUAL_MONITOR=1920x1080           # 仮想モニターの大きさ（幅x高さ）。<VIRTUAL_MONITOR>
   for v in USER REPO VIRTUAL_MONITOR; do
     printf '%-16s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須の変数は無い**。clone した場所が `~/setup-notes` なら、既定のままでよい
   - 最後に値を読み戻して確かめる
   - `USER` が `root` なら、ここで止めて、Claude Code が動くユーザーのシェルで貼り直す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**、手順 1 のブロックを貼り直してから先へ進む

1. gnome-shell に仮想モニターを付けるドロップインを置く。

   ```bash
   if [ -z "${VIRTUAL_MONITOR}" ]; then echo '中断: 手順 1 の VIRTUAL_MONITOR が空のまま。手順 1 を貼り直す' >&2; else
   mkdir -p ~/.config/systemd/user/org.gnome.Shell@wayland.service.d
   cat > ~/.config/systemd/user/org.gnome.Shell@wayland.service.d/virtual-monitor.conf <<EOF
   [Service]
   ExecStart=
   ExecStart=/usr/bin/gnome-shell --virtual-monitor ${VIRTUAL_MONITOR}
   EOF
   systemctl --user daemon-reload
   systemctl --user cat org.gnome.Shell@wayland.service | grep '^ExecStart'
   fi
   ```

   - `ExecStart=/usr/bin/gnome-shell`（元の行）・`ExecStart=`・`ExecStart=/usr/bin/gnome-shell --virtual-monitor <VIRTUAL_MONITOR>` の 3 行が出ればよい
   - このユーザーの GNOME のセッションすべてに効く（[注意点](extra/claude-code-gui.md#注意点)）
   - 動いているセッションには、手順 3 で起動し直したときに効く

1. セッションを止め、終わるのを待って起動し直し、仮想モニターの付いたセッションができたかを確かめる。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。セッションを使うユーザーのシェルで貼り直す' >&2
   else
     sudo systemctl stop "gnome-headless-session@${USER}.service"
     for i in $(seq 1 30); do [ -z "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"')" ] && break; sleep 1; done
     sleep 3
     sudo systemctl start "gnome-headless-session@${USER}.service"
     for i in $(seq 1 30); do
       busctl --user status org.gnome.Mutter.ScreenCast >/dev/null 2>&1 &&
         [ -n "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"')" ] && break
       sleep 1
     done
     loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"'
     pgrep -a -u "${USER}" -x gnome-shell
   fi
   ```

   - `stop` と `start` は何も出さない。動いていたアプリは閉じる
   - `<SESSION_ID> <UID> <USER> - <PID> user headless no -` の形の行と、`<PID> /usr/bin/gnome-shell --virtual-monitor <VIRTUAL_MONITOR>` が出ればよい
   - `for` の行は、gnome-shell のバス名と `loginctl` のセッションの両方が出るまで、30 秒まで待つ。`loginctl` の行は、このユーザーのヘッドレスのセッションの行だけを出す（[gnome-headless-session.md 手順 2](gnome-headless-session.md#実施手順) の補足）
   - `systemctl restart` は使わない（参考資料を参照）

1. 画面を撮って、大きさを確かめる。

   ```bash
   if [ -z "${REPO}" ]; then echo '中断: 手順 1 の REPO が空のまま。手順 1 を貼り直す' >&2; else
   if "${REPO}/scripts/gnome-gui.py" shot ~/gnome-gui-test.png &&
      file --mime-type ~/gnome-gui-test.png | grep -q 'image/png'; then
     file ~/gnome-gui-test.png
   else
     echo '中断: 正常な PNG を撮れていない。セッションの状態を確かめて、この手順を貼り直す' >&2
   fi
   fi
   ```

   - PNG のパスと、`/home/<USER>/gnome-gui-test.png: PNG image data, <幅> x <高さ>, 8-bit/color RGBA, non-interlaced` の 2 行が出ればよい（大きさは `VIRTUAL_MONITOR`）
   - **この 2 行と、PNG の画面を確かめてから次へ進む**。`中断:` や `empty` の場合は進まない
   - 起動直後は最初の映像がまだ届かず、`15 秒以内に PipeWire のストリームから 1 コマも届かなかった` と出ることがある。少し待って同じブロックを貼り直し、正常な PNG が撮れたことを確かめる。繰り返しても撮れなければ、手順 3 のサービスの状態とログを見る
   - Claude Code は、この PNG を Read で開いて画面を見る。人が見るなら、scp などで手元に持ってきて開く
   - セッションを始めた直後の画面は、上に検索欄のあるアクティビティ画面（手順 5 の最初の `key Escape` で閉じる）
   - クリーンインストール後の最初のセッションでは「AlmaLinux へようこそ」の案内が重なることがある。そのときは先に `key Escape` → `sleep 1` → `shot` で案内を閉じたことを確かめてから、手順 5 へ進む。案内を閉じてもアクティビティ画面は残る

1. 電卓を起動して、キーボードの入力が届くかを確かめる。

   ```bash
   if [ -z "${REPO}" ]; then echo '中断: 手順 1 の REPO が空のまま。手順 1 を貼り直す' >&2; else
   "${REPO}/scripts/gnome-gui.py" key Escape
   sleep 1
   "${REPO}/scripts/gnome-gui.py" shot ~/gnome-gui-desktop.png
   "${REPO}/scripts/gnome-gui.py" launch org.gnome.Calculator
   for i in $(seq 1 30); do
     "${REPO}/scripts/gnome-gui.py" windows | grep -q '^gnome-calculator' && break
     sleep 1
   done
   if "${REPO}/scripts/gnome-gui.py" windows | grep -q '^gnome-calculator'; then
     "${REPO}/scripts/gnome-gui.py" shot ~/gnome-gui-calc-ready.png
     "${REPO}/scripts/gnome-gui.py" windows
     "${REPO}/scripts/gnome-gui.py" type '12*34'
     "${REPO}/scripts/gnome-gui.py" shot ~/gnome-gui-calc-input.png
     "${REPO}/scripts/gnome-gui.py" key Return
     "${REPO}/scripts/gnome-gui.py" shot ~/gnome-gui-calc.png
   else
     echo '中断: 電卓の窓が出ない。画面と起動した unit のログを確かめる' >&2
   fi
   fi
   ```

   - `gnome-gui-org.gnome.Calculator-<PID>`（起動した unit の名前）、`gnome-calculator` と `Calculator`（日本語 UI は「電卓」）の行（間はタブ）、PNG のパスが出ればよい
   - 窓の一覧に電卓が出るまで待つ。固定の `sleep 3` だけで起動完了を判断しない
   - `~/gnome-gui-calc.png` に、電卓の窓と `12×34 = 408` が写っていればよい
   - 最初の `key Escape` は、セッションを始めた直後に開いているアクティビティ画面を閉じる（参考資料を参照）

1. ポインタの入力が届くかを確かめて、電卓を閉じる。

   ```bash
   if [ -z "${REPO}" ]; then echo '中断: 手順 1 の REPO が空のまま。手順 1 を貼り直す' >&2; else
   "${REPO}/scripts/gnome-gui.py" click 70 15
   "${REPO}/scripts/gnome-gui.py" shot ~/gnome-gui-overview.png
   "${REPO}/scripts/gnome-gui.py" key Escape
   sleep 1
   "${REPO}/scripts/gnome-gui.py" key ctrl+q
   sleep 1
   "${REPO}/scripts/gnome-gui.py" windows
   fi
   ```

   - `~/gnome-gui-overview.png` が、アクティビティ画面（上に検索欄、真ん中に電卓の窓）になっていればよい
   - 最後の `windows` が何も出さなければ、電卓は閉じた
   - 確かめ用の PNG は、要らなければ `rm ~/gnome-gui-*.png` で消す

- **GDM を再起動すると、このセッションが消えることがある**: `sudo systemctl start gnome-headless-session@<USER>.service` で起動し直す（[注意点](extra/gnome-headless-session.md#注意点)）
---

## 使い方の基本

Claude Code は、リポジトリの直下で `scripts/gnome-gui.py` を呼び、撮った PNG を Read で見て、次の操作を決める。

| コマンド | すること |
|---|---|
| `scripts/gnome-gui.py shot FILE.png [--no-cursor]` | 画面を PNG にする（既定ではポインタも写す） |
| `scripts/gnome-gui.py windows` | アプリの名前と窓のタイトルを出す |
| `scripts/gnome-gui.py launch DESKTOP_ID [ARG...]` | アプリを起動する（`/usr/share/applications` の `.desktop` の名前。例: `org.gnome.TextEditor`） |
| `scripts/gnome-gui.py key KEY...` | キーを押して離す（`Return`・`Escape`・`Tab`・`F1`・`ctrl+l`・`super` など。`+` でつなぐと同時押し。文字キーは小文字で書く。大文字は Shift も付く） |
| `scripts/gnome-gui.py type TEXT` | 文字を打つ（キー配列にある文字だけ。改行は `Return`） |
| `scripts/gnome-gui.py move X Y` | ポインタを動かす |
| `scripts/gnome-gui.py click X Y [left\|middle\|right] [--double]` | クリックする |
| `scripts/gnome-gui.py scroll X Y STEPS` | ホイールを回す（正で下、負で上） |

- 操作の後は `shot` で撮り直して、効いたかを確かめる
- アクティビティ画面が開いているとき（セッションを始めた直後も）に `launch` した窓には、フォーカスが移らず、`type` の文字は検索欄に入る。先に `key Escape` で閉じる
- 画面が動くキー（アクティビティ画面を閉じる `Escape`・開く `super` など）の後は、`sleep 1` を挟んでから次のキーを送る。動いている間に送ったキーは捨てられた
- `scroll` と `click` は、ポインタの下にあるものに効く。デスクトップの上で `scroll` すると、ワークスペースが切り替わった
- `windows` は、同じ窓を 2 行出すことがある（Text Editor で見た）
- 撮った PNG を利用者に見せるときは、リモートコントロールのチャットに送る
- アプリを閉じるのは、アプリのキー（`ctrl+q` など）か、`systemctl --user stop gnome-gui-<名前>-<PID>`（`launch` が出した unit の名前）

---

## 仮想モニターの大きさを変える（任意）

- 大きさの値は、手順 1 の `VIRTUAL_MONITOR` だけに置く（この節で別に設定しない）

> [!WARNING]
> **この節の手順 1 は、セッションを起動し直す**。動いているアプリは閉じ、保存していない内容は失われる。

1. [手順 1](#実施手順) の `VIRTUAL_MONITOR` を新しい大きさに書き換えて、[手順 1〜3](#実施手順) のブロックを貼り直す。

   - 手順 1 の読み戻しに新しい大きさが出て、手順 2 の最後の行が `ExecStart=/usr/bin/gnome-shell --virtual-monitor <VIRTUAL_MONITOR>`（新しい大きさ）になればよい
   - **次の手順は、[手順 3](#実施手順) が終わってから貼る**（手順 3 の `sudo` が、続けて貼った行を読んで捨てる）

1. 新しい大きさで撮れるかを確かめる。

   ```bash
   if [ -z "${REPO}" ]; then echo '中断: 手順 1 の REPO が空のまま。手順 1 を貼り直す' >&2; else
   for i in $(seq 1 30); do busctl --user status org.gnome.Mutter.ScreenCast >/dev/null 2>&1 && break; sleep 1; done
   if "${REPO}/scripts/gnome-gui.py" shot ~/gnome-gui-test.png &&
      file --mime-type ~/gnome-gui-test.png | grep -q 'image/png'; then
     file ~/gnome-gui-test.png
   else
     echo '中断: 正常な PNG を撮れていない。セッションの状態を確かめて、この手順を貼り直す' >&2
   fi
   fi
   ```

   - `PNG image data, <幅> x <高さ>` が新しい大きさになっていればよい
   - PNG の画面も開いて確かめてから使う。撮れなかったときの再試行は[実施手順 4](#実施手順)と同じ
