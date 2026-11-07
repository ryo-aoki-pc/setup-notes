# GNOME のリモート操作のセットアップ（AlmaLinux 10）

- AlmaLinux 10 の GNOME のデスクトップに、別の PC から RDP でつなぐ。今の画面を共有する（デスクトップ共有）、モニターの無い PC に自分のデスクトップを常駐させる（ヘッドレスセッション）、GDM のログイン画面からログインする（リモートログイン）の 3 つ
- 検証記録・参考資料・注意点は、各用途の末尾の「補足と注意点」から開く

> [!IMPORTANT]
> - **前提と実行場所（ユーザー・端末・別のマシン）は、各項のリードに従う**。`sudo -i`・`su -` のシェルでは行わない
> - AlmaLinux 10 の項は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)と同じく、パスワードを聞かない `sudo` を前提に書いてある。各項のリードの前提に無くても、その項を行うユーザーで[ログインと sudo](almalinux-setup.md#ログインと-sudo)を先に通す

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- bash のブロックは、ブラケットペーストの効く端末（GNOME の端末・WezTerm・SSH の先）に貼り、貼った後に Enter を押す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- 3 つの項には更新の項は無い。使う GNOME の部品は、[AlmaLinux 10 のセットアップの「更新」](almalinux-setup.md#更新)の OS の更新で上がる

## AlmaLinux 10 で使う

- GNOME のデスクトップ共有・ヘッドレスセッション・リモートログイン

### GNOME のデスクトップ共有

> [!IMPORTANT]
> - **PC の画面・キーボード・マウスは使わない**。共有するユーザーで SSH でログインしたシェルに貼り、画面は[再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 4 で RDP のクライアントから確かめる
> - **そのユーザー本人のシェルで貼る**。`sudo -i` / `su -` したシェルでは貼らない
> - [再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 4（クライアントからの接続）だけ別のマシンで行う
> - 同じユーザーの[ヘッドレスセッション](#gnome-のヘッドレスセッション)とは併用できない
> - [リモートログイン](#gnome-のリモートログイン)を併用済みなら、[前提確認](#gnome-のデスクトップ共有-前提を確かめる)の手順 1 でポートが 3390 になる

- 変数のある項は、その項の手順 1 で変数を設定したシェルに貼る

> [!WARNING]
> - **自動ログインにするので、PC の前にいる人は誰でも、パスワード無しでこのユーザーのデスクトップを使える**（前提の画面オフ・画面ロック・自動サスペンドを止める項で、ロックもしない）
> - [RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4 で入れる RDP のユーザー名とパスワードは、暗号化されずに `~/.local/share/keyrings/` に置かれる
> - PC を置く場所を信用できるときだけ行う

#### GNOME のデスクトップ共有: 前提を確かめる

- デスクトップ共有を設定する前に、SSH・GDM・モニター・画面の設定・ポート・自動ログイン・RDP の資格情報の状態を確かめる
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)と、[システムの設定](almalinux-setup.md#システムの設定)の手順 3・4（SSH の待ち受け）を通してある。[画面オフ・画面ロック・自動サスペンドを止める](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)の手順 1〜4 も通してある（遠隔の PC は、眠ると起こせない。画面が暗くなるかロックされると、RDP の接続が切れる）
- 実行場所: 共有するユーザーで SSH でログインしたシェル（bash）

1. 変数を設定する。

   ```bash
   RDP_PORT=$(if [ "$(systemctl is-enabled gnome-remote-desktop.service 2>/dev/null)" = enabled ]; then echo 3390; else echo 3389; fi)   # 待ち受けるポート（自動）。<RDP_PORT>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in USER RDP_PORT; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須の変数は無い**
   - `USER` が `root` なら、ここで止めて、共有するユーザーのシェルで貼り直す
   - **新しいシェルを開いたら**、この項の手順 1 を貼り直してから先へ進む

1. 再起動の後も SSH で入り直せて、GNOME が自動で起動するかを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # SSH の自動起動と受信の許可を確認する
   systemctl is-enabled sshd.service
   sudo firewall-cmd --permanent --query-service=ssh
   # GNOME の起動設定を確認する
   systemctl get-default
   systemctl is-enabled gdm.service
   # 接続しているモニターの数を確認する
   cat /sys/class/drm/card*-*/status 2>/dev/null | grep -cx connected
   # 暗号化したディスクの数を確認する
   lsblk -rno TYPE | grep -cx crypt
   ```

   - `enabled`・`yes`・`graphical.target`・`enabled`・`1` 以上・`0` が順に出ればよい
   - 1 行目が `enabled` でなければ、`sudo systemctl enable sshd.service` を貼る（[自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 3 の再起動の後に SSH で入れなくなる）
   - 2 行目が `no` なら、`sudo firewall-cmd --permanent --add-service=ssh` を貼る。SSH を別のポートやゾーンで通しているなら、それが永続の設定にあることを確かめる
   - 3 行目が `graphical.target` でなければ、`sudo systemctl set-default graphical.target` を貼る
   - 4 行目が `enabled` でなければ、GDM が起動しない。先に GDM を使える状態にする
   - 5 行目は、PC につながっているモニターの数。`0` なら、写す画面が無い。モニターの無い PC は[ヘッドレスのセッション](#gnome-のヘッドレスセッション)を使う
   - 6 行目は、暗号化したディスクの数。`0` でなければ、起動のときにパスフレーズを PC の画面で入れるかを確かめる
     - 入れるなら、[自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 3 の再起動から戻らないので、この用途（デスクトップ共有）の手順は使えない（TPM などで自動で開くなら続けてよい）

1. 共有するユーザーの画面の設定・共有とヘッドレスの状態・ポート・自動ログインの設定・資格情報を確かめる。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ] || [ -z "${RDP_PORT}" ]; then echo '中断: USER が空か root、または「前提を確かめる」の手順 1 の RDP_PORT が空のまま。共有するユーザーのシェルで「前提を確かめる」の手順 1 を貼り直す' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     # 画面オフとロック、サスペンドの設定を確認する
     /usr/bin/gsettings get org.gnome.desktop.session idle-delay
     /usr/bin/gsettings get org.gnome.desktop.screensaver lock-enabled
     systemctl is-enabled suspend.target
     # デスクトップ共有とヘッドレスの状態を確認する
     /usr/bin/gsettings get org.gnome.desktop.remote-desktop.rdp enable
     systemctl --user is-enabled gnome-remote-desktop-headless.service
     systemctl --user is-active gnome-remote-desktop-headless.service
     if systemctl --user is-enabled --quiet gnome-remote-desktop-headless.service ||
        systemctl --user is-active --quiet gnome-remote-desktop-headless.service; then
       echo '中断: ヘッドレスの unit が有効か起動中。以降は貼らず、利用状況を確認する' >&2
     fi
     # RDP ポートの使用状況を確認する
     ss -Hlnt "sport = :${RDP_PORT}" | wc -l
     # GDM の自動ログインの設定を確認する
     grep -c '^AutomaticLogin' /etc/gdm/custom.conf
     # 保存済みの RDP 資格情報を検索する
     busctl --user call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service SearchItems 'a{ss}' 1 xdg:schema org.gnome.RemoteDesktop.RdpCredentials
     # PC の画面のセッションを確認する
     loginctl list-sessions --no-legend | awk '$4 == "seat0"'
   fi
   ```

   - 次の 9 行の後に、PC の画面のセッションの行が出ればよい
     - `uint32 0`・`false`・`masked`（画面を消さず、ロックせず、眠らない）
     - `false`（デスクトップ共有はまだ無効）
     - `disabled` と `inactive`（同じユーザーのヘッドレスの RDP は無効で停止中）
     - `0`（`RDP_PORT` で待ち受けているものが無い）
     - `0`（GDM の自動ログインはまだ無い）
     - `aoao 0 0`（RDP の資格情報はまだ無い）
   - 最後の行は、PC の画面のセッション。誰もログインしていなければ、ログイン画面の `gdm` の行（`greeter`）だけが出る
     - ほかのユーザーの行があれば、[自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 3 の再起動で、そのセッションは閉じる
   - 1〜3 行目が `uint32 0`・`false`・`masked` でなければ、[画面オフ・画面ロック・自動サスペンドを止める](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)の手順 1〜4 を行う
   - 4 行目が `true` なら、設定アプリなどでデスクトップ共有を有効にしてある
     - 先に `grdctl rdp disable` で止めてから貼り直す
   - ヘッドレスの unit が有効か起動中なら、ここで止める。利用状況を確認してから、どちらを使うか決める
   - `RDP_PORT` の行が `0` でなければ、ほかのもの（ほかのユーザーの[ヘッドレスのセッション](#gnome-のヘッドレスセッション)など）がそのポートを使っている
     - この項の手順 1 の `RDP_PORT` の行を、空いているポート（`3391` など）に書き換えて貼り直し、この手順を貼り直す
   - `AutomaticLogin` の行が `0` でなければ、自動ログインがすでに設定してある。[自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 1 で、このユーザーかを確かめる
   - `aoao 0 0` なら、この項の手順 4 は飛ばす。それ以外なら、RDP の資格情報がすでにあるので、この項の手順 4 を行う

1. 前に入れた RDP の資格情報が残っているときだけ、[RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4 のキーリングの外にあるものを消す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/python3 - <<'PY'
   import getpass
   from pathlib import Path
   from gi.repository import Gio, GLib
   marker = Path.home() / '.local/state/gnome-desktop-sharing-setup/autologin-keyring'
   owned = marker.read_text().strip() if marker.is_file() and not marker.is_symlink() else ''
   bus = Gio.bus_get_sync(Gio.BusType.SESSION)
   svc = '/org/freedesktop/secrets'
   def call(path, iface, method, args, rtype):
       return bus.call_sync('org.freedesktop.secrets', path, iface, method, args,
                            GLib.VariantType(rtype), Gio.DBusCallFlags.NONE, -1, None).unpack()
   def prop(path, iface, name):
       return call(path, 'org.freedesktop.DBus.Properties', 'Get', GLib.Variant('(ss)', (iface, name)), '(v)')[0]
   attrs = {'xdg:schema': 'org.gnome.RemoteDesktop.RdpCredentials'}
   unlocked, locked = call(svc, 'org.freedesktop.Secret.Service', 'SearchItems', GLib.Variant('(a{ss})', (attrs,)), '(aoao)')
   stale = [i for i in unlocked + locked if not (owned and i.startswith(owned + '/'))]
   if not stale:
       print('ほかのキーリングに RDP の資格情報は無い')
       raise SystemExit(0)
   closed = sorted({i.rsplit('/', 1)[0] for i in stale if i in locked})
   opened = []
   try:
       if closed:
           password = getpass.getpass('閉じたキーリングのパスワード（ふつうは OS のパスワード）: ')
           _, session = call(svc, 'org.freedesktop.Secret.Service', 'OpenSession', GLib.Variant('(sv)', ('plain', GLib.Variant('s', ''))), '(vo)')
           for col in closed:
               try:
                   call(svc, 'org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface', 'UnlockWithMasterPassword',
                        GLib.Variant('(o(oayays))', (col, (session, b'', password.encode(), 'text/plain'))), '()')
               except GLib.Error as e:
                   raise SystemExit(f'中断: {col} を開けない（{e.message}）。資格情報は消していない')
               if prop(col, 'org.freedesktop.Secret.Collection', 'Locked'):
                   raise SystemExit(f'中断: {col} を開けない。資格情報は消していない')
               opened.append(col)
       for item in stale:
           prompt, = call(item, 'org.freedesktop.Secret.Item', 'Delete', None, '(o)')
           if prompt != '/':
               raise SystemExit(f'中断: {item} の削除が終わらない')
           print('消した:', item)
   finally:
       if opened:
           call(svc, 'org.freedesktop.Secret.Service', 'Lock', GLib.Variant('(ao)', (opened,)), '(aoo)')
           print('閉じ直した:', ' '.join(opened))
   PY
   ```

   - 資格情報が閉じたキーリング（自動ログインのときのログインのキーリングなど）にあれば、そのパスワードを聞かれる。ログインのキーリングなら、ふつうは OS のパスワード
   - `消した:` と出ればよい。キーリングを開いたときは `閉じ直した:` も確かめる
   - キーリングを開けないときの `中断:`（`を開けない`）では、何も消していない。パスワードが違うときは、貼り直す
   - 対象は `~/.local/state/gnome-desktop-sharing-setup/autologin-keyring` に記録されている。ほかに無ければ `ほかのキーリングに RDP の資格情報は無い` と出る
   - **次の手順は、パスワードを聞かれたなら、入力し終えてから貼る**（終わる前に貼ると、動いているコマンドへの入力になる）

#### GNOME のデスクトップ共有: RDP を設定する

- 共有するユーザーで、RDP の証明書と鍵・ポート・資格情報を設定し、デスクトップ共有を有効にして、ファイアウォールを開ける
- 前提: [前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)を通してある
- 実行場所: 共有するユーザーで SSH でログインしたシェル（bash）

1. 変数を設定する（`SERVER_IP` は必ず値を入れる）。

   ```bash
   SERVER_IP=192.0.2.100               # ← 自分の値に書き換える。クライアントが接続に使う IP。<SERVER_IP>
   ```

   ```bash
   SERVER_NAME=$(hostname)             # 証明書の CN と SAN に入る（自動）。<HOSTNAME>
   SERVER_FQDN=$(hostname -f)          # 同上。<HOSTNAME>.<DOMAIN>
   RDP_PORT=$(if [ "$(systemctl is-enabled gnome-remote-desktop.service 2>/dev/null)" = enabled ]; then echo 3390; else echo 3389; fi)   # 待ち受けるポート（自動）。<RDP_PORT>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in USER SERVER_IP SERVER_NAME SERVER_FQDN RDP_PORT; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須なのは `SERVER_IP` の 1 行だけ**
   - [前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 1 の `RDP_PORT` を書き換えたとき（同じ項の手順 3 の分岐）は、2 つ目のブロックの `RDP_PORT` の行も同じ値に書き換える
   - `USER` が `root` なら、ここで止めて、共有するユーザーのシェルで貼り直す
   - **新しいシェルを開いたら**、この項の手順 1 の 2 つのブロックを貼り直してから先へ進む

1. 変える設定の元値と共用する TLS 設定を退避し、証明書と鍵を作る（既にあれば作らない）。

   ```bash
   # 変更前の RDP 設定を退避する
   if [ -z "${SERVER_IP}" ] || [ -z "${SERVER_NAME}" ] || [ -z "${SERVER_FQDN}" ]; then
     echo '中断: この項の手順 1 の変数が空のまま。この項の手順 1 を貼り直す' >&2
   else
     (
       set -e
       trap 'echo "中断: この項の手順 2 が失敗した。この項の手順 3 へ進まない" >&2' ERR
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
       # 証明書と鍵を用意し、生成物を記録する
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
       # 証明書と鍵を読み、公開鍵の一致を確認する
       openssl x509 -in ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt -noout
       openssl pkey -in ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key -passin pass: -noout
       CERT_PUBLIC_KEY=$(openssl x509 -in ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt -pubkey -noout)
       KEY_PUBLIC_KEY=$(openssl pkey -in ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key -passin pass: -pubout)
       if [ "${CERT_PUBLIC_KEY}" != "${KEY_PUBLIC_KEY}" ]; then
         echo '中断: 証明書と秘密鍵の公開鍵が一致しない。既存ファイルを確認する' >&2
         exit 1
       fi
       printf '\n\033[7m 確認 \033[0m\n'
       echo '証明書と秘密鍵の公開鍵: 一致'
       touch ~/.local/state/gnome-desktop-sharing-setup/ready
       ls -l ~/.local/share/gnome-remote-desktop/certificates
       echo '設定の退避と証明書の準備が完了'
     )
   fi
   ```

   - 最後に `設定の退避と証明書の準備が完了` と出れば、この項の手順 3 へ進む
   - `中断:` が出たら、この項の手順 3 以降へ進まない。原因を直してから、この手順を貼り直す
   - `設定の退避が不完全` と出たら、`~/.local/state/gnome-desktop-sharing-setup` の中身を手で確かめる。何も変えていなければ、このディレクトリを消してから貼り直す

1. `grdctl` で、証明書と鍵・ポートと、リモートからの操作を設定する。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: この項の手順 1 の RDP_PORT が空のまま。この項の手順 1 を貼り直す' >&2
   elif [ ! -f ~/.local/state/gnome-desktop-sharing-setup/ready ]; then
     echo '中断: この項の手順 2 が完了していない。設定は変更しない' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     rm -f ~/.local/state/gnome-desktop-sharing-setup/restored &&
     grdctl rdp set-tls-cert ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt &&
     grdctl rdp set-tls-key ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key &&
     grdctl rdp set-port "${RDP_PORT}" &&
     grdctl rdp disable-port-negotiation &&
     grdctl rdp disable-view-only &&
     {
       if systemctl --user is-active --quiet gnome-remote-desktop.service; then
         systemctl --user restart gnome-remote-desktop.service
       fi
     } &&
     /usr/bin/gsettings list-recursively org.gnome.desktop.remote-desktop.rdp
   fi
   ```

   - `negotiate-port false`・設定した `port`・証明書と鍵のパス・`view-only false` が出ればよい
   - 初回の `BIO_new failed for certificate` と `RDP server certificate is invalid.` は正常
   - `中断:` が出たら、この項の手順 4 以降へ進まない
   - 起動中のデーモンを再起動するので、接続中の RDP クライアントは切れる
   - 貼り直したときの `Warning: The unit file, … changed on disk.` は、再起動されていれば正常
   - ほかに `enable` と `screen-share-mode` の行も出る（`enable` は、[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 5 で有効にするまで `false`）

1. RDP の資格情報をパスワードの無いキーリングに入れ、保存先を確認する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/python3 - <<'PY'
   import getpass
   import sys
   from pathlib import Path
   from gi.repository import Gio, GLib
   state = Path.home() / '.local/state/gnome-desktop-sharing-setup'
   marker = state / 'autologin-keyring'
   if (state.is_symlink() or not (state / 'ready').is_file() or marker.is_symlink()
           or (marker.exists() and not marker.is_file())):
       raise SystemExit('中断: この項の手順 2 が完了していないか、キーリングの記録が不正。資格情報は入れない')
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
   owned = marker.read_text().strip() if marker.exists() else None
   if owned == '':
       raise SystemExit('中断: キーリングの記録が空。autologin-keyring を確認する')
   if cols and (len(cols) != 1 or owned != cols[0]):
       raise SystemExit('中断: この手順で作ったと確認できない rdp キーリングがある。既存の項目は変更しない')
   if owned and not cols:
       raise SystemExit('中断: 記録したキーリングが見つからない。autologin-keyring と既存のキーリングを確認する')
   if cols:
       _, prompt = call(svc, 'org.freedesktop.Secret.Service', 'Unlock', GLib.Variant('(ao)', (cols,)), '(aoo)')
       if prompt != '/' or prop(cols[0], 'org.freedesktop.Secret.Collection', 'Locked'):
           raise SystemExit('中断: 記録したキーリングをパスワードなしで開けない。既存の項目は変更しない')
   unlocked, locked = call(svc, 'org.freedesktop.Secret.Service', 'SearchItems', GLib.Variant('(a{ss})', (attrs,)), '(aoao)')
   if [i for i in unlocked + locked if not (cols and i.startswith(cols[0] + '/'))]:
       raise SystemExit('中断: ほかのキーリングに RDP の資格情報がある。「前提を確かめる」の手順 4 で消してから貼る')
   sys.stdin = open('/dev/tty')
   username = input('RDP のユーザー名: ').strip()
   password = getpass.getpass('RDP のパスワード: ')
   if not username or not password or password != getpass.getpass('RDP のパスワード（もう一度）: '):
       raise SystemExit('中断: ユーザー名かパスワードが空か、2 回のパスワードが違う。資格情報は変えていない')
   value = GLib.Variant('a{sv}', {'username': GLib.Variant('s', username),
                                  'password': GLib.Variant('s', password)}).print_(True)
   _, session = call(svc, 'org.freedesktop.Secret.Service', 'OpenSession', GLib.Variant('(sv)', ('plain', GLib.Variant('s', ''))), '(vo)')
   if not cols:
       cols = [call(svc, 'org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface', 'CreateWithMasterPassword',
                    GLib.Variant('(a{sv}(oayays))', ({'org.freedesktop.Secret.Collection.Label': GLib.Variant('s', 'rdp')},
                                                     (session, b'', b'', 'text/plain'))), '(o)')[0]]
       with marker.open('x') as f:
           f.write(cols[0] + '\n')
   props = {'org.freedesktop.Secret.Item.Label': GLib.Variant('s', 'GNOME Remote Desktop RDP credentials'),
            'org.freedesktop.Secret.Item.Attributes': GLib.Variant('a{ss}', attrs)}
   item, prompt = call(cols[0], 'org.freedesktop.Secret.Collection', 'CreateItem',
                       GLib.Variant('(a{sv}(oayays)b)', (props, (session, b'', value.encode(), 'text/plain'), True)), '(oo)')
   if item == '/' or prompt != '/':
       raise SystemExit('中断: 資格情報を入れた項目を確認できない')
   print('入れた先:', item)
   print('キーリングの記録:', marker)
   PY
   busctl --user call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service SearchItems 'a{ss}' 1 xdg:schema org.gnome.RemoteDesktop.RdpCredentials
   RDP_KEYRING=$(cat ~/.local/state/gnome-desktop-sharing-setup/autologin-keyring) &&
   printf '記録したキーリング: %s\n' "${RDP_KEYRING}" &&
   busctl --user get-property org.freedesktop.secrets "${RDP_KEYRING}" org.freedesktop.Secret.Collection Locked
   ```

   - RDP のユーザー名とパスワードを入力し、パスワードをもう一度入力する（OS のアカウントと違ってよい）
   - `入れた先:` と `キーリングの記録:` が出ればよい
   - `中断:` やエラーが出たら、有効化へ進まない
   - `aoao 1 "<コレクションのパス>/<N>" 0` と `記録したキーリング: <コレクションのパス>`、`b false` が出ればよい。項目のパスが、記録したキーリングの直下であることを確かめる
   - 記録したキーリングの外のパスがあれば、[前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 4 を行ってから、この手順を貼り直す

1. デスクトップ共有を有効にする。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。共有するユーザーのシェルで貼り直す' >&2
   elif [ ! -f ~/.local/state/gnome-desktop-sharing-setup/ready ]; then echo '中断: この項の手順 2 が完了していない。有効にしない' >&2
   elif [ ! -s ~/.local/state/gnome-desktop-sharing-setup/autologin-keyring ]; then echo '中断: この項の手順 4 が完了していない。有効にしない' >&2
   elif systemctl --user is-enabled --quiet gnome-remote-desktop-headless.service ||
        systemctl --user is-active --quiet gnome-remote-desktop-headless.service; then
     echo '中断: 同じユーザーのヘッドレスのセッションの RDP が有効か起動中。有効にしない' >&2
   else
     # デスクトップ共有の RDP を有効にする
     grdctl rdp enable
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl --user is-enabled gnome-remote-desktop.service
   fi
   ```

   - `enabled` と出ればよい
   - PC の画面にこのユーザーのセッションがまだ無ければ、デーモンは待ち受けない。待ち受けは、[再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 2 で確かめる

1. ファイアウォールで、`RDP_PORT` の TCP を開ける。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: この項の手順 1 の RDP_PORT が空のまま。この項の手順 1 を貼り直す' >&2; else
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --permanent --add-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   fi
   ```

   - `success` が出て、最後に設定した `RDP_PORT` の TCP があればよい

#### GNOME のデスクトップ共有: 自動ログインにして再起動する

- PC の画面のセッションを GDM の自動ログインで作るようにし、起動画面を止めて、PC を再起動する
- 前提: [RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)を通してある
- 実行場所: 共有するユーザーで SSH でログインしたシェル（bash）

1. GDM の自動ログインを、このユーザーで有効にする。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。共有するユーザーのシェルで貼り直す' >&2
   elif grep -qx 'AutomaticLoginEnable=True' /etc/gdm/custom.conf && grep -qx "AutomaticLogin=${USER}" /etc/gdm/custom.conf &&
        [ "$(grep -c '^AutomaticLogin' /etc/gdm/custom.conf)" = 2 ]; then
     echo 'このユーザーの自動ログインは設定済み'
     grep -A 2 '^\[daemon\]' /etc/gdm/custom.conf
   elif grep -q '^AutomaticLogin' /etc/gdm/custom.conf; then echo '中断: /etc/gdm/custom.conf に自動ログインの行がすでにある。中身を確かめる' >&2
   else
     sudo sed -i "/^\[daemon\]/a AutomaticLoginEnable=True\nAutomaticLogin=${USER}" /etc/gdm/custom.conf
     grep -A 2 '^\[daemon\]' /etc/gdm/custom.conf
   fi
   ```

   - `[daemon]`・`AutomaticLoginEnable=True`・`AutomaticLogin=<USER>` の 3 行が出ればよい
   - `中断:` なら、ほかのユーザーの自動ログインなどが書いてある。`/etc/gdm/custom.conf` を確かめ、要らない行を消してから貼り直す

1. 起動画面（plymouth）を止め、自動ログインの後にログイン画面が前に出ないようにする。

   ```bash
   # 起動画面を無効にする引数をカーネルに設定する
   sudo grubby --update-kernel=ALL --args="rd.plymouth=0 plymouth.enable=0"
   printf '\n\033[7m 確認 \033[0m\n'
   sudo grubby --info=DEFAULT | grep '^args='
   ```

   - `args=` の行に `rd.plymouth=0 plymouth.enable=0` が入っていればよい

1. PC を再起動する。

   ```bash
   systemctl reboot -i
   ```

   - `sudo` は付けず、このユーザーの OS のパスワードを入れる
   - 数分待っても SSH で入れないときは、PC の前での対処が要る（[前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 2 の確認を見直す）
   - **PC が起動したら SSH で入り直し、[再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)へ進む**
   - SSH の接続が切れる。PC が起動すると、GDM がこのユーザーで自動でログインする

#### GNOME のデスクトップ共有: 再起動の後に確かめてつなぐ

- 再起動の後に、自動でログインしたセッションと、RDP の待ち受け・証明書を確かめ、別のマシンからつなぐ
- 前提: [自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)で再起動し、PC が起動している
- 実行場所: 共有するユーザーで SSH でログインし直したシェル（bash）。この項の手順 4 は、RDP のクライアントのある別のマシンで行う

1. 変数を設定する（`SERVER_IP` は必ず値を入れる）。

   ```bash
   SERVER_IP=192.0.2.100               # ← 自分の値に書き換える。クライアントが接続に使う IP。<SERVER_IP>
   ```

   ```bash
   RDP_PORT=$(if [ "$(systemctl is-enabled gnome-remote-desktop.service 2>/dev/null)" = enabled ]; then echo 3390; else echo 3389; fi)   # 待ち受けるポート（自動）。<RDP_PORT>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in USER SERVER_IP RDP_PORT; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須なのは `SERVER_IP` の 1 行だけ**。[RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)で証明書を作ったときと同じ値を入れる
   - [前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 1 の `RDP_PORT` を書き換えたとき（同じ項の手順 3 の分岐）は、2 つ目のブロックの `RDP_PORT` の行も同じ値に書き換える
   - `USER` が `root` なら、ここで止めて、共有するユーザーのシェルで貼り直す
   - **新しいシェルを開いたら**、この項の手順 1 の 2 つのブロックを貼り直してから先へ進む

1. 自動でログインしたセッションと、デーモンの待ち受けを確かめる。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: この項の手順 1 の RDP_PORT が空のまま。この項の手順 1 を貼り直す' >&2
   elif [ -z "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $4 == "seat0"')" ]; then
     echo '中断: PC の画面にこのユーザーのセッションが無い（自動ログインしていない）' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     # 自動ログインと画面の共有機能を確認する
     loginctl show-session "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $4 == "seat0" {print $1}')" -p Service -p Active
     busctl --user status org.gnome.Mutter.ScreenCast >/dev/null 2>&1 && echo 'ScreenCast: ok'
     # RDP サービスと待ち受けを確認する
     systemctl --user is-active gnome-remote-desktop.service
     (
       for attempt in {1..30}; do
         RDP_LISTENER=$(ss -Hlntp "sport = :${RDP_PORT}")
         if printf '%s\n' "${RDP_LISTENER}" | grep -q 'gnome-remote-de'; then
           printf '%s\n' "${RDP_LISTENER}"
           exit 0
         fi
         sleep 1
       done
       echo "中断: ${RDP_PORT}/tcp の待ち受けを 30 秒以内に確認できない。この項の手順 3 へ進まず、デーモンのログを確認する" >&2
       exit 1
     )
   fi
   ```

   - `Service=gdm-autologin` と `Active=yes`、`ScreenCast: ok`、`active` が出る
   - `ss` に、共有のデーモンが `RDP_PORT` で `LISTEN` していればよい
   - `Active=no` なら GDM のログイン画面が出ており、RDP は真っ黒になる
   - [自動ログイン](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 2 を `sudo grubby --info=DEFAULT` で確かめ、[復旧手順](#gnome-のデスクトップ共有-つながらなくなったとき)の手順 2 で戻す
   - セッションが無いと出たら、[自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 1 の `/etc/gdm/custom.conf` を確かめる
   - `中断:` が出たら、この項の手順 3 へ進まない。`journalctl -b _SYSTEMD_USER_UNIT=gnome-remote-desktop.service` で理由を見る
     - ほかのプロセスがポートを使っていると、`Error binding to address [::]:<RDP_PORT>: Address already in use` が出ている
     - 原因を直したら、[RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 3 を貼り直し（起動中のデーモンを再起動する）、この手順を貼り直す

1. 設定を読み戻し、TLS のハンドシェイクと、提示される証明書を確かめる。

   ```bash
   # TLS 確認用のスクリプトを作成する
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
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/python3 ~/rdp_tls_probe.py "${SERVER_IP}" "${RDP_PORT}" &&
   grdctl status &&
   openssl x509 -in ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt -noout -fingerprint -sha1
   ```

   - プローブで、`selectedProtocol=0x2` でネゴシエーションが成立し、SAN に接続に使う名前が `DNS:` エントリとして含まれていればよい
   - `grdctl status` で `Unit status: active`・`Status: enabled`・`Port: <RDP_PORT>` を確認する
   - `View-only: no`・`Negotiate port: no`・`Username: (hidden)`・`Password: (hidden)` も確認する
   - プローブの `fingerprint:` の行が、`grdctl status` の `TLS fingerprint:` の行と**完全一致**すればよい。この値をこの項の手順 4 で使う
   - Windows からつなぐ場合は、最後の `sha1 Fingerprint=` の値も控える（この項の手順 4 で照合する）
   - **注意**: `grdctl status` の `Port:` は設定した値で、実際に待ち受けたポートではない。ポートはこの項の手順 2 の `ss` で見る

1. 別のマシンから、RDP クライアントでつなぐ。

   - AlmaLinux 10 の FreeRDP（`freerdp` パッケージ）なら `xfreerdp /v:<SERVER_IP>:<RDP_PORT> /u:<RDP のユーザー名>` の形でつなぐ
   - Windows なら「リモート デスクトップ接続」で `<SERVER_IP>:<RDP_PORT>` につなぐ
   - `<SERVER_IP>`・`<RDP_PORT>` はこの項の手順 1 の値に、`<RDP のユーザー名>` は [RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4 の値に読み替える
   - FreeRDP は、証明書の `Thumbprint:` を出して `Do you trust the above certificate? (Y/T/N)` と聞く。この項の手順 3 の `TLS fingerprint` と同じなら `Y` で受け入れる
     - 初めてつなぐときも、その前に `REMOTE HOST IDENTIFICATION HAS CHANGED!` などの警告が出る。続く `Thumbprint:` で判断する
   - Windows は、拇印を出さずに「このリモート コンピューターの ID を識別できません」と聞く
     - 「証明書の表示」→「詳細」の「拇印」（SHA-1）が、この項の手順 3 の `sha1 Fingerprint=` の値と同じかを見てから「はい」を押す（拇印はコロンが無く小文字なので、そこは違ってよい）
   - FreeRDP は `Domain:` も聞く。空のまま Enter を押す
   - パスワードは [RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4 のもの。通ると、PC の画面に出ているデスクトップが、PC の画面の解像度のまま出る
     - FreeRDP は、パスワードの後に `[ERROR][com.winpr.sspi.Kerberos]` の `krb5_parse_name (Configuration file does not specify default realm …)` の行を出すことがある。デスクトップが出れば、害は無い
   - このユーザーが初めてデスクトップにログインしたなら、「AlmaLinux 10.2 (Lavender Lion) へようこそ」の窓が出ている。RDP の画面で「スキップ」を押す
   - RDP の画面に、キーリングのパスワードを聞く窓が出ていないことを確かめる
   - クライアントでの操作は、PC の画面にもそのまま出る。PC の上部バーには、共有中の印が出る
   - 問題があれば、PC で `journalctl -b _SYSTEMD_USER_UNIT=gnome-remote-desktop.service` を見る（`journalctl --user` は、既定の構成では `No journal files were found.` になる）
     - この項の手順 3 を貼った時刻の `client authentication failure` と `Network or intentional disconnect, stopping session` などの行は、そのプローブが残したもの。害は無い

#### GNOME のデスクトップ共有: 見るだけにする

- デスクトップ共有を見るだけにし、クライアントからのキーボードとマウスを受け付けないようにする
- 前提: [RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)を通してある
- 実行場所: 共有するユーザーで SSH でログインしたシェル（bash）
- **クライアントから操作させるなら、この項は不要**

1. クライアントからのキーボードとマウスを受け付けないようにする。

   ```bash
   # 共有を読み取り専用に切り替える
   grdctl rdp enable-view-only
   printf '\n\033[7m 確認 \033[0m\n'
   grdctl status | grep 'View-only'
   ```

   - `View-only: yes` と出ればよい

1. 元に戻すときは、クライアントからの操作を受け付ける。

   ```bash
   # 共有を操作できる状態に切り替える
   grdctl rdp disable-view-only
   printf '\n\033[7m 確認 \033[0m\n'
   grdctl status | grep 'View-only'
   ```

   - `View-only: no` と出ればよい

#### GNOME のデスクトップ共有: 接続元を LAN に絞る

- デスクトップ共有の RDP のポートを、LAN の送信元サブネットからだけ受け付けるようにする
- 前提: [RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)を通してある
- 実行場所: 共有するユーザーで SSH でログインしたシェル（bash）
- **接続元を制限しないなら、この項は不要**
- 別の拠点からつなぐなら、`LAN_SUBNET` には、PC に届くときの接続元のサブネットを入れる（この項は 1 つのサブネットだけを通す）

1. 変数を設定する。

   ```bash
   RDP_PORT=$(if [ "$(systemctl is-enabled gnome-remote-desktop.service 2>/dev/null)" = enabled ]; then echo 3390; else echo 3389; fi)   # 待ち受けるポート（自動）。<RDP_PORT>
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'RDP_PORT = %s\n' "${RDP_PORT}"
   ```

   - [前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 1 の `RDP_PORT` を書き換えたとき（同じ項の手順 3 の分岐）は、`RDP_PORT` の行も同じ値に書き換える
   - **新しいシェルを開いたら**、この項の手順 1 を貼り直してから先へ進む

1. LAN に絞るなら、送信元サブネットを入れ、ポートの開放を rich rule に置き換える。

   ```bash
   LAN_SUBNET=192.0.2.0/24              # ← 自分の値に書き換える。<LAN_SUBNET>
   ```

   ```bash
   if [ -z "${LAN_SUBNET}" ] || [ -z "${RDP_PORT}" ]; then echo '中断: LAN_SUBNET か、この項の手順 1 の RDP_PORT が空のまま。値を入れて貼り直す' >&2; else
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --permanent --remove-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=${RDP_PORT} protocol=tcp accept"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   sudo firewall-cmd --list-rich-rules        # source address と port に実際の値が入っていることを確認する
   fi
   ```

   - `success` が出て、ポート一覧から `RDP_PORT` の TCP が消え、rich rule に `LAN_SUBNET` と `RDP_PORT` があればよい

#### GNOME のデスクトップ共有: リモートログインと併用する

- デスクトップ共有を使っている PC で後からリモートログインを有効にしたとき、共有の待ち受けを 3389 から 3390 へ移す
- 前提: [GNOME のデスクトップ共有](#gnome-のデスクトップ共有)と[GNOME のリモートログイン](#gnome-のリモートログイン)を通してある
- 実行場所: デスクトップ共有を使うユーザー本人で SSH でログインしたシェル（bash）
- リモートログインが使う `rdp` のサービスは残す

1. 変数を設定する（接続元を LAN に絞ってあるときは、`LAN_SUBNET` に必ず同じ値を入れる）。

   ```bash
   LAN_SUBNET=   # ← 接続元を LAN に絞ったときの値。絞っていなければ空のままでよい。<LAN_SUBNET>
   ```

   ```bash
   RDP_PORT=3389
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'RDP_PORT = %s\nLAN_SUBNET = %s\n' "${RDP_PORT}" "${LAN_SUBNET}"
   ```

   - 共有のポートが `3389` であることを確かめる。既に `3390` なら、この項は行わない
   - 接続元を LAN に絞ってあるときは、この項の手順 2 を飛ばして手順 3 へ進む

1. 接続元を LAN に絞っていないときだけ、デスクトップ共有で開けた 3389/tcp を閉じる。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: この項の手順 1 の RDP_PORT が空のまま。この項の手順 1 を貼り直す' >&2; else
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --permanent --remove-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   fi
   ```

   - `success` が出て、ポート一覧から `RDP_PORT` の TCP が消えていればよい

1. 接続元を LAN に絞ってあるときだけ、デスクトップ共有で開けた rich rule を消す（この項の手順 2 の代わりに）。

   ```bash
   if [ -z "${LAN_SUBNET}" ] || [ -z "${RDP_PORT}" ]; then echo '中断: LAN_SUBNET か、この項の手順 1 の RDP_PORT が空のまま。値を入れて貼り直す' >&2; else
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=${RDP_PORT} protocol=tcp accept"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-rich-rules
   fi
   ```

   - `LAN_SUBNET` は、[接続元を LAN に絞る](#gnome-のデスクトップ共有-接続元を-lan-に絞る)の手順 2 の 1 つ目のブロックを貼り直して入れる
   - `success` が出て、その rich rule が消えていればよい

1. 共有の待ち受けを 3390 へ変え、つながることを確かめる。

   - [前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 1 を貼り直し、`RDP_PORT` が `3390` になったのを確かめる
   - ほかのユーザーのヘッドレスのセッションが `3390` を使っていれば、同じ項の手順 1 の `RDP_PORT` に空いている別のポートを入れる
   - [RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 3・6 を通す。接続元を LAN に絞っていたなら、同じ項の手順 6 の後に[接続元を LAN に絞る](#gnome-のデスクトップ共有-接続元を-lan-に絞る)も通す
   - [再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 1〜4 を通す

#### GNOME のデスクトップ共有: つながらなくなったとき

- デスクトップ共有でつながらなくなったときに、**PC の画面を触らずに、SSH から直す**
- 前提: [再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)まで通してある
- 実行場所: 共有するユーザーで SSH でログインしたシェル（bash）
- 当てはまる手順だけを貼る。どれも[前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 1 の変数は要らない

1. 画面がロックされて切れたとき（クライアントから Super+L を押したときなど）は、ロックを解く。

   ```bash
   if [ -z "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $4 == "seat0"')" ]; then
     echo '中断: PC の画面にこのユーザーのセッションが無い。この項の手順 3 を行う' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     busctl --user call org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver GetActive
     loginctl unlock-session "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $4 == "seat0" {print $1}')"
     sleep 2
     busctl --user call org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver GetActive
   fi
   ```

   - `b true` の後に `b false` が出ればよい。クライアントからつなぎ直す

1. RDP の画面が真っ黒なとき（PC の画面にログイン画面が前に出たとき）は、自動ログインのセッションを前に戻す。

   ```bash
   if [ -z "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $4 == "seat0"')" ]; then
     echo '中断: PC の画面にこのユーザーのセッションが無い。この項の手順 3 を行う' >&2
   else
     # 共有するデスクトップを前面に戻す
     sudo loginctl activate "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $4 == "seat0" {print $1}')"
     printf '\n\033[7m 確認 \033[0m\n'
     loginctl show-session "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $4 == "seat0" {print $1}')" -p Active
   fi
   ```

   - `Active=yes` と出ればよい。つないだままのクライアントにも、また画面が写る（切れていれば、つなぎ直す）
   - 再起動のたびに起きるなら、[自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 2 の起動の引数を確かめる

1. PC の画面のセッションが無いとき（クライアントから「ログアウト」を選んだときなど）は、PC を再起動して自動ログインさせる。

   ```bash
   systemctl reboot -i
   ```

   - パスワードの聞かれ方は、[自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 3 と同じ
   - 起動したら SSH で入り直し、[再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 1・2 で確かめる

<details id="gnome-のデスクトップ共有-の補足と注意点">
  <summary>GNOME のデスクトップ共有 の補足と注意点</summary>

**注意点**

- **画面が暗くなるかロックされると、RDP の接続が切れる**: GNOME は、ロック画面（無操作で暗くなるときを含む）の間、画面の共有を止める
  - ロックされている間は、新しい接続もできない。SSH から[GNOME のデスクトップ共有: つながらなくなったとき](#gnome-のデスクトップ共有-つながらなくなったとき)の手順 1 で解く
  - 前提の[画面オフ・画面ロック・自動サスペンドを止める](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)の手順 1・2 で、画面を消さず、ロックしないようにしておく。クライアントから Super+L などでロックしても切れる
- **クライアントから「ログアウト」「電源オフ」を選ばない**: 自動ログインは起動のときにしか行われないので、ログアウトすると、再起動するまでつながらない（[GNOME のデスクトップ共有: つながらなくなったとき](#gnome-のデスクトップ共有-つながらなくなったとき)の手順 3）
  - 誤って選んだら、確認の窓で「キャンセル」を押す。押さないと、60 秒で自動でログアウトする
  - 電源を切ると、遠隔では入れ直せない。「再起動」なら、自動ログインで戻る
- **PC の画面に、クライアントの操作がすべて見える**: PC の前の人も同じ画面を操作できる。PC の上部バーの共有中の印から、PC の側で共有を止められる
- **写るのは PC の主モニター 1 枚で、解像度は PC のまま**: クライアントの窓の大きさには合わせない
- **同じユーザーのヘッドレスのセッションとは併用できない**: ヘッドレスのデーモンの unit が、この unit と衝突する（`Conflicts=`）
- **後からリモートログインを有効にしたとき**: リモートログインのデーモンが 3389 で待ち受ける。この手順で 3389 にしてあれば、共有のデーモンは待ち受けられなくなる（`Address already in use`）。次の順で 3390 へ移す
  - [GNOME のデスクトップ共有: リモートログインと併用する](#gnome-のデスクトップ共有-リモートログインと併用する)で、3389 の開放を閉じてから共有のポートを変える
- **RDP のユーザー名とパスワードを変えるとき**: [GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4 を貼り直す（上書きする）。`grdctl rdp set-credentials` は使わない（閉じたログインのキーリングに書こうとして、PC の画面に「認証が必要です」の窓を出して止まる）
  - 誤って貼ったら、Ctrl+C で止める。PC の画面の窓は残るので、RDP の画面で「キャンセル」を押して閉じる
- **設定アプリの「リモート デスクトップ」を開かない**: 自動ログインでは、ログインのキーリングがいつも閉じている。閉じているときに開くと、RDP のパスワードが乱数に書き換えられることがある（設定アプリ 47.7 の既知の不具合）
- **Homebrew が PATH の先頭にあると、`gsettings`・`python3` が Homebrew のものになる**（[AlmaLinux 10 のセットアップの「Homebrew の補足と注意点」](almalinux-setup.md#homebrew-の補足と注意点)）。この手順書は `/usr/bin/` を付けて呼ぶ
- **自己署名証明書**: クライアントは初回に証明書の確認を出す。証明書を作り直したら、クライアントで保存済みの証明書を消すか、変更の警告を承認する（[GNOME のリモートログイン の補足と注意点](#gnome-のリモートログイン-の補足と注意点)の「注意点」と同じ）

**[GNOME のデスクトップ共有](#gnome-のデスクトップ共有)のリード**

- PC の画面のセッションは、GDM の自動ログインで作る（[GNOME のデスクトップ共有: 自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 1〜3）。PC の前でログインしておく必要は無い

- [GNOME のデスクトップ共有: 前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 4 は**対話入力を終えてから次を貼る**

- [GNOME のデスクトップ共有: 自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 3 で**再起動する**。OS のパスワードを入力する

- 後からリモートログインを有効にする場合はこの折りたたみの「注意点」を参照する

- 設定と資格情報は、貼ったユーザーのものになる

**[GNOME のデスクトップ共有: 前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 1**

- **編集が必須の変数は無い**。既定のままでよい

**[GNOME のデスクトップ共有: 前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 1: 変数について**

- `RDP_PORT` の式は、[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション) の手順 1 と同じ。`systemctl is-enabled gnome-remote-desktop.service` は `--user` を付けないので、システムの unit（リモートログイン）を見る
  - ユーザーの unit も同じ名前（`gnome-remote-desktop.service`）なので、ユーザーの unit を見るときは必ず `--user` を付ける
- RHEL 10 の文書の 1.1 も、リモートログインと併用するときはデスクトップ共有のポートが 3390 になると書いている
- `RDP_PORT` は、リモートログインのシステムのデーモン（`gnome-remote-desktop.service`）が有効なら `3390`、そうでなければ `3389` になる
- 任意の変数のブロックは、最後に値を読み戻す
- 変数はそのシェルの中だけで有効なので、新しいシェルでは（[GNOME のデスクトップ共有: 自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 3 の再起動の後も）、使う項の手順 1 を貼り直す

**[GNOME のデスクトップ共有: 前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 2**

- `enabled`・`yes`・`graphical.target`・`enabled`・`1` 以上・`0` の 6 行が出ればよい

**[GNOME のデスクトップ共有: 前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 2: 再起動の前に確かめること**

- この手順書は、[GNOME のデスクトップ共有: 自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 3 で PC を再起動して、自動ログインでデスクトップを作る。PC の画面を触れないので、再起動から戻ってこられないと、遠隔では直せない
- 確かめるのは、再起動の後に SSH で入り直せること（`sshd.service` が enabled、firewalld の永続の設定に `ssh` がある）と、GNOME が自動で起動すること（既定の target が `graphical.target`、`gdm.service` が enabled）
- `/sys/class/drm/card*-*/status` の `connected` の数は、PC につながっているモニターの数。デスクトップ共有は PC の主モニターを写す（`screen-share-mode='mirror-primary'`）ので、モニターの無い PC には写すものが無い
  - aarch64 の実機の検証では、HDMI をつないでいない aarch64 の実機の seat0 に、GNOME Shell の仮想モニターを足して写した（検証記録: `docs/verification/gnome-desktop-sharing.md` の「付録: このホストでの検証（2026-10-07）」）。手順書には入れず、モニターの無い PC は[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)を使う（「選択した方針」）
- 既定の target が `graphical.target` でないと、再起動の後に GNOME が起動しない。`gdm.service` が要るのは、この手順書が GDM の自動ログインを使うため
- `lsblk` の `crypt` は、LUKS などで暗号化したブロックデバイス。起動のときにパスフレーズを PC の画面で入れる構成なら、[GNOME のデスクトップ共有: 自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 3 の再起動の後に入力を待って止まる。TPM などで自動で開く構成かどうかは、この確認では分からないので、手順書は利用者に確かめさせる

**[GNOME のデスクトップ共有: 前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 3: 確かめる前提**

- **PC の画面のセッション**: デスクトップ共有のデーモン（`gnome-remote-desktop-daemon` をオプション無しで動かしたもの）は、セッションの Mutter の ScreenCast と RemoteDesktop の D-Bus を使う。そのユーザーのグラフィカルなセッションが無いと、何も共有しない
  - この手順書では、セッションは[GNOME のデスクトップ共有: 自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 3 の再起動の後に、GDM の自動ログインで作る。[GNOME のデスクトップ共有: 前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 3 では、PC の画面のセッションを前提にしない（一覧を出すだけ）
- **資格情報の置き場所**: ユーザーのモードの資格情報は、GNOME のキーリング（libsecret）に置く
  - schema は `org.gnome.RemoteDesktop.RdpCredentials`、ラベルは `GNOME Remote Desktop RDP credentials`、値は GVariant の文字列 `{'username': <'…'>, 'password': <'…'>}`。設定アプリ（gnome-control-center 47.7）も同じ項目を読み書きする
  - ヘッドレスとシステムのモードの資格情報（TPM か `credentials.ini`）とは別の場所なので、ぶつからない
  - ログインのキーリングを開くのは、GDM でパスワードを入れてログインしたときの `pam_gnome_keyring`（gdm 47.0 の `gdm-password` の PAM）。SSH のログイン（sshd の PAM に `pam_gnome_keyring` が無い）と自動ログイン（パスワードが無い）では開かない
  - [GNOME のデスクトップ共有: 前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 3 の `SearchItems` は、項目を読むだけで、キーリングを開かない。SSH のシェルからでも、gnome-keyring は D-Bus で起動する（`org.freedesktop.secrets` が activatable）
- **画面の設定**: gnome-shell は、ロック画面（`unlock-dialog` のモード）の間、`inhibit_remote_access` で画面の共有を止め、Mutter はつながっているリモートのセッションを閉じる（上流の README の「locking the screen also closes the remote desktop connection」、上流 #119・#172）
  - 無操作で暗くなったとき（`idle-delay`）も、シールドが出て同じモードになる。`lock-enabled` が false でも切れる
  - なので、`idle-delay` を 0 に、`lock-enabled` を false にする（[AlmaLinux 10 の初期設定](almalinux-setup.md)の「画面オフ・画面ロック・自動サスペンドを止める」の手順 1・2 の既定値）
  - 遠隔の PC は、眠ると起こす手段が無いので、サスペンドの mask（同書の手順 4）も前提にし、`suspend.target` が `masked` かを見る
- **ヘッドレスのセッション**: ヘッドレスのユーザーの unit（`gnome-remote-desktop-headless.service`）には `Conflicts=gnome-remote-desktop.service` がある。同じユーザーでは、片方を起動するともう片方が止まる
  - `disabled` でも、手動で起動した unit は `active` になり得るので、`is-active` も見る
- **設定アプリで有効にしてあったとき**: 4 行目が `true` のときは、この手順の設定で上書きする
- **残っている資格情報の出どころ**: `aoao 0 0` 以外のときの資格情報は、設定アプリ・この手順書の[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4 で入れたもの

**[GNOME のデスクトップ共有: 前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 4**

- [GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4 で作るキーリングの項目は消さない


- `消した: <コレクションのパス>/<N>` の形の行が出ればよい。開いたキーリングは、消した後に閉じ直す（`閉じ直した:` の行）

**[GNOME のデスクトップ共有: 前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 4: 残っている資格情報を消す理由**

- 設定アプリで入れた資格情報は、ログインのキーリングにある。自動ログインでは、ログインのキーリングは閉じたまま
- libsecret 0.21.2 の読み出しは、同じ属性の項目が開いたキーリングにあればそれを使い、閉じたキーリングにしか無ければ、最初に見つかった 1 つ（`locked[0]`）を開こうとする
  - 起動の直後は、[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4 のキーリング（パスワード無し）もまだ閉じている。ログインのキーリングの項目が先に返ると、そのキーリングを開く窓が PC の画面に出るはずで、遠隔からは答えられない
  - なので、[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4 のキーリングの外にある項目は消す（写すのではなく、[GNOME のデスクトップ共有: 前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 4 で入れ直す）
- 閉じたキーリングの項目は、開かないと消せない。PC の画面に窓を出さずに開くには、gnome-keyring の `org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface.UnlockWithMasterPassword` に、そのキーリングのパスワードを渡す（Secret Service の `Unlock` は、PC の画面に窓を出す）
  - VM では、違うパスワードで `org.gnome.keyring.Error.Denied: The password was invalid` が返り、何も消さずに止まった
- 開いたキーリングは、消した後に `Lock` で閉じ直す（自動ログインのときと同じ状態に戻す）。もとから開いていたキーリングは閉じない
- パスワードは `getpass` で読み、画面とシェルの履歴に残さない。Secret Service のセッションは、それを開いた D-Bus の接続でしか使えないので、1 つの接続の Python（Gio）で書いた

**[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 1**

- 最後に値を読み戻して確かめる

- **編集が必須なのは `SERVER_IP` の 1 行だけ**。残りは既定のままでよい

**[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 1: 変数について**

- `SERVER_IP`・`SERVER_NAME`・`SERVER_FQDN` は、[GNOME のリモートログイン](#gnome-のリモートログイン) の手順 1 と同じ。証明書の SAN に入れる（[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 2）

**[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 2**

- その前に `証明書と秘密鍵の公開鍵: 一致` と出る

- 新規生成した場合は `rdp-tls.crt`（`-rw-r--r--`）と `rdp-tls.key`（`-rw-------`）が出る

**[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 2: 退避と証明書**

- 中身は [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 3 と同じ形。違うのは、退避先（`~/.local/state/gnome-desktop-sharing-setup`）と、退避するキーの数（5 つ）
- `証明書と秘密鍵の公開鍵: 一致` は、既存の証明書と鍵も、組み合わせが正しいことを確かめたもの。既存の証明書と鍵は上書きしない
- 退避するのは、[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 3 で変える dconf のキー（`/org/gnome/desktop/remote-desktop/rdp/` の `port`・`negotiate-port`・`view-only`・`tls-cert`・`tls-key`）。未設定だったキーは空ファイルになる
- `tls-cert` と `tls-key` は、デスクトップ共有とヘッドレスのモードで共用する（ヘッドレスの専用のキーは `rdp/headless/` の下の `port`・`negotiate-port`・`enable` だけ）。`rdp/` を `dconf reset -f` すると `rdp/headless/` も消えるので、キーごとに戻す
- 証明書のパス（`~/.local/share/gnome-remote-desktop/certificates/rdp-tls.{crt,key}`）は、ヘッドレスの手順書・RHEL 10 の文書の 1.4・設定アプリ 47.7 が自分で作るときと同じ。ヘッドレスの手順書で作ってあれば、それを使う
- RHEL の文書は `winpr-makecert` で作るが、ここでは SAN を付けるために openssl で作る（[GNOME のリモートログイン の補足と注意点](#gnome-のリモートログイン-の補足と注意点)の「注意点」）

**[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 3**


- 最後の行で読み戻す。`negotiate-port false`・`port uint16 <RDP_PORT>`・`tls-cert` と `tls-key` の証明書と鍵のパス・`view-only false` が出ればよい

- 初めて設定するときだけ、`[x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` が 1 回ずつ出る。害は無い

- デーモンが起動した後に貼り直すと、再起動のときに `Warning: The unit file, … of gnome-remote-desktop.service changed on disk.` が出ることがある。再起動はされ、害は無い

**[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 3: grdctl（オプション無し）**

- `--headless` も `--system` も付けない `grdctl` は、デスクトップ共有（上流のソースでは `GRD_RUNTIME_MODE_SCREEN_SHARE`）の設定を変える。書き先は dconf の `/org/gnome/desktop/remote-desktop/rdp/`
- dconf への書き込みなので、PC の画面のセッションが無くても（SSH だけでも）設定できる
- 既定は `view-only=true`（見るだけ）・`negotiate-port=true`・`port=3389`・`screen-share-mode='mirror-primary'`
- `disable-view-only` は、クライアントからのキーボードとマウスを受け付ける設定
- `disable-port-negotiation` は、指定したポートが使われていたときに次のポートを順に試すのを止める。ポートが勝手に変わって、[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 6 で開けたポートと食い違うのを防ぐ。代わりに、ポートが使われていると待ち受けに失敗し、再試行しない
- `set-tls-cert` と `set-tls-key` は絶対パスだけを受け付ける（`~` はシェルが展開する）
- 初めて設定するときの `[x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` は、`grdctl` が設定を読み込むとき（49.3 の `src/grd-settings.c` の `update_rdp_server_fingerprint`）に、まだ空の `tls-cert` で証明書を読もうとして出すもの
  - 最初の `set-tls-cert` だけが出し、後の `grdctl` は設定済みのパスを読むので出さない（[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 4 と同じ）
- `port` と `negotiate-port` は、次に待ち受けるときに効く。[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 3 は、既に起動しているデーモンを再起動してポートと TLS の設定を反映する。`view-only` 自体は、つないでいるクライアントにもすぐ効く
- 読み戻しの `gsettings list-recursively` は、このスキーマのキーを全部出す。手順書の箇条書きの 5 つのほかに、`enable` と `screen-share-mode` の行も並ぶ
  - 2026-10-11 の Hyper-V の VM では、`enable false`・`negotiate-port false`・`port uint16 3389`・`screen-share-mode 'mirror-primary'`・`tls-cert`・`tls-key`・`view-only false` の 7 行だった（検証記録: `docs/verification/gnome-desktop-sharing.md` の「付録: Hyper-V の VM で通した記録（2026-10-11）」）
  - `enable` が `true` になるのは、[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 5 の後（同じ VM で、[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 5 の後の dconf は `enable=true`）

**[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4**

- 貼り直すと、同じキーリングの資格情報を上書きする（ユーザー名とパスワードを変えるときも、この手順を貼り直す）

- `RDP のユーザー名:`・`RDP のパスワード:`・`RDP のパスワード（もう一度）:` を聞かれる。クライアントが接続するときに入れるもので、OS のアカウントと違ってよい

- `入れた先: <コレクションのパス>/<N>` と `キーリングの記録: …/autologin-keyring` の形の行が出ればよい。初めてなら、コレクションのパスは `/org/freedesktop/secrets/collection/rdp` になる

**[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4: パスワードの無いキーリングに直接入れる**

- g-r-d は、ユーザーのパスワードを知らないのでキーリングを開けない（上流 #27 の開発者の説明）。自動ログインでは、ログインのキーリングは閉じたままになる
- 上流 #27 で知られている回避策は 2 つ
  - ログインのキーリングのパスワードを空にする: ほかのパスワード（ブラウザーなど）もすべて暗号化されずに置かれる
  - パスワードの無い別のキーリングに RDP の資格情報だけを置く: この手順書はこちらを採る
- `grdctl rdp set-credentials` は、libsecret の既定のコレクション（`default` の別名。通常は `login`）に書く。ログインのキーリングが閉じていると、PC の画面に「認証が必要です」の窓を出して待ち続ける（上流 #166・#338）
  - VM では、Ctrl+C で `grdctl` を止めても PC の画面の窓は残り、RDP の画面で「キャンセル」を押して閉じた（検証記録: `docs/verification/gnome-desktop-sharing.md` の「付録: PC の画面を触らない版を x86_64 の VM で通した記録（2026-10-07）」）
  - 画面で一度もログインしていないユーザーには、ログインのキーリングがそもそも無く、書き込みはキーリングを作る窓を出すはず
- そこで、`grdctl` を使わず、Python（Gio）で Secret Service に直接書く
  - パスワードの無いキーリングを、PC の画面に窓を出さずに作るには、gnome-keyring の `CreateWithMasterPassword` を空のパスワードで呼ぶ（Secret Service の `CreateCollection` は、PC の画面にパスワードを聞く窓を出す）
  - 項目の値は、g-r-d と同じく GVariant の `a{sv}`（`username` と `password`）を `print_(True)`（`g_variant_print` と同じ）で文字にしたもの。ラベル・`xdg:schema` の属性も `grdctl` と同じにする
  - VM では、入れた項目を `grdctl status --show-credentials` がユーザー名で読み、RDP の認証も通った
  - `CreateItem` の `replace` を真にするので、貼り直すと同じキーリングの項目を上書きする（資格情報の変更）
- 標準入力はヒアドキュメント（スクリプトそのもの）なので、ユーザー名は `/dev/tty` を開き直して `input()` で読み、パスワードは `getpass`（`/dev/tty` を使う）で読む。パスワードは画面に出ず、シェルの履歴にも残らない
  - `open('/dev/tty', 'r+')` は、テキストの読み書きのモードでは `io.UnsupportedOperation: File or stream is not seekable.` で失敗した（検証で直した）
- パスワードの無いキーリングも、gnome-keyring を起こした直後は閉じている。開くように頼まれると、パスワードを聞かずに開く（コンテナでの模擬と、VM の再起動の後の最初の RDP の認証）
- 作ったコレクションの実際の D-Bus パスは `~/.local/state/gnome-desktop-sharing-setup/autologin-keyring` に記録する。名前が `rdp` でも、記録と一致しない既存コレクションは再利用しない

**[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 5: grdctl rdp enable**

- `grdctl rdp enable` は、`/usr/libexec/gnome-remote-desktop-enable-service` を通して、セッションの systemd にユーザーの unit `gnome-remote-desktop.service` の StartUnit と EnableUnitFiles を頼む。`systemctl --user enable --now` は要らない
- unit は `WantedBy=gnome-session.target` なので、PC の画面のセッションが始まるたびに起動する
- PC の画面のセッションが無い（SSH だけの）ときに貼っても、エラーにならずに unit が起動し、待ち受けはしなかった（VM）。再起動の後の自動ログインで、待ち受けを始めた
- `grdctl rdp disable` は、unit を止めて無効にする

**[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 6**

- `success` が 2 行出て、最後に `<RDP_PORT>/tcp` を含む行が出ればよい

**[GNOME のデスクトップ共有: 自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 1**

- このユーザーで設定してあれば、`このユーザーの自動ログインは設定済み` の後に同じ 3 行が出る

**[GNOME のデスクトップ共有: 自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 2: 起動画面（plymouth）を止める理由**

- GDM 47.0 は、自動ログインのセッションを始めると、20 秒後に `plymouth quit --retain-splash` を呼ぶ（`daemon/gdm-manager.c` の `on_user_session_started`）
- GDM は、VT1（`GDM_INITIAL_VT`）に切り替わったときに VT1 にログイン画面が無ければ、ログイン画面を作る（`daemon/gdm-local-display-factory.c` の `on_vt_changed`）
- VirtualBox の VM では、自動ログインのセッションは VT2 で動き、約 22 秒後に plymouth が終わった直後に、GDM が VT1 にログイン画面を作って、VT1 が前に出た（起動の引数を `rhgb quiet` 付きの一般的な形にしても同じだった）
- その結果、PC の画面にはログイン画面が出て、自動ログインのセッションは裏（`Active=no`）に回る。裏のセッションは画面を描かないので、RDP でつなぐと、認証は通るのに画面が真っ黒になる
- VirtualBox の VM で、起動の引数に `rd.plymouth=0 plymouth.enable=0` を足すと、plymouth が動かず、VT の切り替えが起きないので、ログイン画面は出なかった（検証記録: `docs/verification/gnome-desktop-sharing.md` の「付録: VirtualBox の VM での本実行（2026-10-07）」）
- 起動の引数で止めると、次の起動から、起動画面の代わりに文字のメッセージが出る
- 裏に回ったセッションは、`sudo loginctl activate <SESSION_ID>` で前に戻せる（[GNOME のデスクトップ共有: つながらなくなったとき](#gnome-のデスクトップ共有-つながらなくなったとき)の手順 2）。`sudo` が無いと `Interactive authentication required.` で断られる

**[GNOME のデスクトップ共有: 自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 3**


- `sudo` は付けない。`==== AUTHENTICATING FOR org.freedesktop.login1.…` と出てパスワードを聞かれるので、このユーザーの OS のパスワードを入れる

**[GNOME のデスクトップ共有: 自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 3: 再起動のコマンド**

- systemd 257 の `systemctl reboot` は、端末から呼ばれると、抑止（inhibitor）を確かめ、強い抑止があれば断る（`src/systemctl/systemctl-logind.c` の `logind_check_inhibitors`）
  - v257 から、root でも抑止を確かめる。root は、抑止が無ければ、ほかのユーザーのセッションを確かめない（同じ関数の「root respects inhibitors since v257 but keeps ignoring sessions by default」）
  - 自分と同じ uid のセッション（SSH のログインなど）は、root でなくても数えない
  - gnome-session が `shutdown` の強い抑止（`user session inhibited`）を取るのは、アプリが終了を止めているときだけ（テキスト エディターに保存していない文書があるときなど）。アプリが止めていなければ取らない
- `-i` は、gnome-session の抑止とログイン中のユーザーを無視する。付けないと、PC の画面のアプリが終了を止めているときは `Operation inhibited by …` で断られる
- `-i`（`--check-inhibitors=no`）で抑止を無視させても、logind は、強い抑止を無視するときは root にも polkit の認可を求める（`src/login/logind-dbus.c` の「We want to always ask here, even for root」）
  - `sudo` を付けると root の `systemctl` は polkit の認証を聞く窓口（`pkttyagent`）を起こさない（`src/shared/polkit-agent.c` の「Clients that run as root don't need to activate/query polkit」）ので、`Interactive authentication required.` で断られる
  - 強い抑止が無ければ、`sudo systemctl reboot -i` は認証を聞かれずに再起動した
  - `sudo` を付けない `systemctl` は、端末で `pkttyagent` を起こし、このユーザーのパスワードを聞く（`wheel` のユーザーは管理者として認証できる）。抑止の有無にかかわらず通る
  - VM で聞かれた操作は、`org.freedesktop.login1.reboot-ignore-inhibit`（保存していない文書があり、強い抑止があったとき）か `org.freedesktop.login1.reboot`（無かったとき）だった。PC の画面にセッションが無いとき（ログイン画面だけ）も `org.freedesktop.login1.reboot` だった

**[GNOME のデスクトップ共有: 再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 1**

- 最後に値を読み戻して確かめる

**[GNOME のデスクトップ共有: 再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 2**

- `ss` が `LISTEN … *:<RDP_PORT> … users:(("gnome-remote-de",…))` の 1 行を出せばよい

**[GNOME のデスクトップ共有: 再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 2: 待ち受けの確かめ方**

- `grdctl status` の `Port:` は dconf の値で、実際に待ち受けたポートではない（上流 #255）
- `loginctl show-session` の `Active=yes` は、PC の画面に出ているのがこのセッションであること
- 実際のポートは、`ss` か、D-Bus の `org.gnome.RemoteDesktop.User` の `/org/gnome/RemoteDesktop/Rdp/Server` の `Port` プロパティ（待ち受けていなければ -1）で見る
- unit の起動完了と待ち受け開始には時間差があるので、[GNOME のデスクトップ共有: 再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 2 は自分のデーモンのソケットを最大 30 秒待つ
- 待ち受けに失敗しても、デーモンは動き続け、unit は `active` のまま。ポートのネゴシエーションを切っているので、ほかのポートも試さず、ポートが空いても待ち受け直さない（この折りたたみの「GNOME のデスクトップ共有: RDP を設定するの手順 3: grdctl（オプション無し）」）
  - 原因を直した後は、[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 3 を貼り直す。[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 3 は、起動中のデーモンを再起動する
  - 理由は、デーモンのログの `Failed to start RDP server: Error binding to address [::]:<RDP_PORT>: Address already in use` で分かる（ログの見方は[GNOME のデスクトップ共有: 再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 4 の補足）
- `ss -p` は、自分のプロセスなら root でなくても名前を出す。システムのデーモン（リモートログイン）は `gnome-remote-desktop` ユーザーのプロセスなので、ここには名前が出ない
- [GNOME のデスクトップ共有: 再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 2 は資格情報を読まない。読み出しが先に起きないので、停電などで再起動したときと同じく、最初の RDP の認証が資格情報を読む流れも確かめられる（検証では、再起動の後にこの手順だけを貼ってから、クライアントから直接つないだ）

**[GNOME のデスクトップ共有: 再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 3**

- 確認が済んだら `rm ~/rdp_tls_probe.py` で消してよい

**[GNOME のデスクトップ共有: 再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 3: TLS プローブ**

- スクリプトは [GNOME のリモートログイン](#gnome-のリモートログイン)の手順 10 と同じもの。第 2 引数でポートを渡す
- `/usr/bin/python3` で動かすのは、Homebrew が PATH の先頭にあるときも、同じ Python にするため
- `grdctl status` は資格情報を読み出す（`Username: (hidden)` と出るのは、読めたとき）。[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4 のキーリングはパスワードが無いので、PC の画面に窓は出ない
- プローブは、TLS のハンドシェイクで証明書を受け取ると、NLA の認証をせずに接続を閉じる。デーモンは、この接続をエラーの行としてログに残す
  - 2026-10-11 の Hyper-V の VM では、プローブを貼った時刻に `BIO_read returned a system error 104: Connection reset by peer`・`[transport_accept_nla]: client authentication failure`・`[RDP] Network or intentional disconnect, stopping session` などの 7 行が残った。待ち受けと、その後の接続には響かなかった
  - 2026-10-07 の VirtualBox の VM でも、`client authentication failure` と `Network or intentional disconnect` が残った（検証記録: `docs/verification/gnome-desktop-sharing.md` の「実施手順（81012d3 と f3450e6 で 1 回ずつ）」）
- 最後の `openssl x509 … -fingerprint -sha1` は、Windows のクライアントで比べるための値
  - `grdctl status` の `TLS fingerprint` と、FreeRDP の `Thumbprint:` は SHA-256（コロン区切りの小文字）
  - Windows の「リモート デスクトップ接続」の警告の窓は、証明書の名前とエラーだけを出し、拇印を出さない。「証明書の表示」→「詳細」の「拇印」は SHA-1 で、コロンの無い小文字（例: `de7964917c…`）。openssl は同じ値をコロン区切りの大文字（`DE:79:64:91:7C:…`）で出す

**[GNOME のデスクトップ共有: 再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 4: クライアントに写るもの**

- 既定の `screen-share-mode='mirror-primary'` は、PC の主モニターをそのままの解像度で送る。クライアントの窓の大きさに合わせるための Display Control のチャネルは `extend` のときしか作られない
- デスクトップ共有で写せるモニターは 1 枚だけ
- 認証は NLA だけ（TLS だけ・RDP のセキュリティは受け付けない）。ユーザー名とパスワードは[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4 の RDP の資格情報で、OS のアカウントではない
- FreeRDP 3.10.3 は、保存した証明書（`~/.config/freerdp/server/<SERVER_IP>_<RDP_PORT>.pem`）が無い初めての接続でも、`REMOTE HOST IDENTIFICATION HAS CHANGED!` の警告を出してから、新しい証明書としての確認（`Do you trust the above certificate? (Y/T/N)`）を出す。`Y` で保存した後は聞かない
  - 証明書を作り直した後は、`!!!Certificate for … has changed!!!` と新旧の `Thumbprint:` を並べて聞く
- FreeRDP 3.10.3 は、`Password:` の後に `[ERROR][com.winpr.sspi.Kerberos] - [kerberos_AcquireCredentialsHandleA]: krb5_parse_name (Configuration file does not specify default realm [-1765328160])` を 2 行出してから、つながった（2026-10-11 の Hyper-V の VM）
  - 同じ VM では、違うパスワードの `/auth-only` でも同じ 2 行が出て、その後に `ERRCONNECT_AUTHENTICATION_FAILED` で断られた
  - 2026-10-07 の VirtualBox の VM の記録にも、`krb5_parse_name (Configuration file does not specify default realm)` の後に NTLM でつながった、とある
  - Kerberos を先に試し、クライアントに既定の realm が無いので次の方式に移る動き、とみる（今回は確かめていない）
- 画面で一度もログインしていないユーザーの最初の自動ログインでは、`gnome-tour` の「AlmaLinux 10.2 (Lavender Lion) へようこそ」の窓が出た（gnome-initial-setup の窓は出なかった）。RDP の画面で「スキップ」を押して閉じた
- ログの見方: AlmaLinux 10 の既定は `/var/log/journal` が無く、journal は揮発（`/run/log/journal`）。揮発のときはユーザーごとの journal のファイルが分かれないので、`journalctl --user` は `No journal files were found.` になる
  - `journalctl -b _SYSTEMD_USER_UNIT=gnome-remote-desktop.service` は、システムの journal から、このユーザーの unit の行を読む（`wheel` と `adm` のグループは ACL で読める）。ヘッドレスの手順書と同じ形
  - [AlmaLinux 10 の初期設定の「システムの設定」](almalinux-setup.md#システムの設定)の手順 5 で journal をディスクに書くようにした PC では、`journalctl --user` でもデーモンの行が読めた（2026-10-11 の Hyper-V の VM。`/var/log/journal` の下に `user-<UID>.journal` がある）。同じ日の、初期設定を通していない VM は `No journal files were found.` だった

**[GNOME のデスクトップ共有: 接続元を LAN に絞る](#gnome-のデスクトップ共有-接続元を-lan-に絞る)のリード**

- [GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 6 は、public ゾーンに属するすべての NIC で `RDP_PORT` の TCP を開く

**[GNOME のデスクトップ共有: 接続元を LAN に絞る](#gnome-のデスクトップ共有-接続元を-lan-に絞る)の手順 1**

- 最後に値を読み戻して確かめる

**[GNOME のデスクトップ共有: 接続元を LAN に絞る](#gnome-のデスクトップ共有-接続元を-lan-に絞る)の手順 2**

- `success` が 3 行出て、`--list-ports` に `<RDP_PORT>/tcp` が無く、rich rule に `<LAN_SUBNET>` と `<RDP_PORT>` が入っていればよい

**[GNOME のデスクトップ共有: 接続元を LAN に絞る](#gnome-のデスクトップ共有-接続元を-lan-に絞る)の手順 2: 引用符**

- rich rule は**二重引用符**で囲む。単一引用符だと変数が展開されない（[GNOME のリモートログイン: 接続元を LAN に絞る](#gnome-のリモートログイン-接続元を-lan-に絞る)）

**[GNOME のデスクトップ共有: リモートログインと併用する](#gnome-のデスクトップ共有-リモートログインと併用する)のリード**

- リモートログインの手順 4（`sudo grdctl --system rdp …`）を貼っている間に、システムのデーモンが起動して 3389 で待ち受けた
  - VM では 2 回とも、同じ秒に共有のデーモンが `RDP server stopped` を出した
  - 約 3 秒後に `Failed to start RDP server: Error binding to address [::]:3389: Address already in use` を出して、待ち受けをやめた。ユーザーの unit は `active` のまま
  - 共有のデーモンが待ち受けをいったん止める仕組みは確かめていない
- firewalld は、ポート（`--add-port`）とサービス（`--add-service`）を別々に持つ。この手順書が[GNOME のデスクトップ共有: RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 6 で開けた `3389/tcp` は、リモートログインが開けた `rdp` のサービスとは別に残る
  - リモートログインの「接続元を LAN に絞る」は、`rdp` のサービスを外して、LAN だけを通す rich rule にする。ゾーンに `3389/tcp` が残っていると、LAN の外からも 3389 に届く
- そのため、[GNOME のデスクトップ共有: リモートログインと併用する](#gnome-のデスクトップ共有-リモートログインと併用する)では、古いポートの開放を閉じてから、3390 へ移す。閉じても、リモートログインは `rdp` のサービスか、同書の rich rule で届く

**[GNOME のデスクトップ共有: リモートログインと併用する](#gnome-のデスクトップ共有-リモートログインと併用する)の手順 2**

- `success` が 2 行出て、`--list-ports` に `<RDP_PORT>/tcp` が無ければよい

**[GNOME のデスクトップ共有: リモートログインと併用する](#gnome-のデスクトップ共有-リモートログインと併用する)の手順 3**

- `success` が 2 行出て、その rich rule が消えていればよい

**[GNOME のデスクトップ共有: つながらなくなったとき](#gnome-のデスクトップ共有-つながらなくなったとき)のリード**

- [GNOME のデスクトップ共有: つながらなくなったとき](#gnome-のデスクトップ共有-つながらなくなったとき)の手順 1: ロック画面の間は、新しい接続も認証の後に `Session creation inhibited` で断られる。`loginctl unlock-session` は、logind からセッションへ `Unlock` を送る。VM では、GNOME のロック画面が解け（`org.gnome.ScreenSaver.GetActive` が `b true` から `b false`）、つなぎ直せた
  - 自分のセッションなので、`sudo` は要らなかった
- [GNOME のデスクトップ共有: つながらなくなったとき](#gnome-のデスクトップ共有-つながらなくなったとき)の手順 2: VM で `sudo chvt 1` で VT1 に切り替えると、GDM が VT1 にログイン画面を作り、自動ログインのセッションが `Active=no` になった。`sudo loginctl activate` で `Active=yes` に戻り、つないだままの FreeRDP にも画面が戻って、入力も届いた
- [GNOME のデスクトップ共有: つながらなくなったとき](#gnome-のデスクトップ共有-つながらなくなったとき)の手順 3: VM で、RDP の画面からログアウトすると、PC の画面はログイン画面のままになり（自動ログインし直さない）、`RDP_PORT` は閉じた（ユーザーの unit も止まる）。再起動すると、自動ログインで戻った
  - ログアウトの確認の窓は、「キャンセル」を押さないと 60 秒で自動でログアウトする
  - aarch64 の実機の検証では、OS の再起動の代わりに GDM とユーザーマネージャーを起動し直して、自動ログインさせた（検証記録: `docs/verification/gnome-desktop-sharing.md` の「付録: このホストでの検証（2026-10-07）」）。リモートログインのデーモンとの順序の問題（[GNOME のリモートログイン](#gnome-のリモートログイン)）があるので、手順には再起動を採った

- 理由が分からないときは、`journalctl -b _SYSTEMD_USER_UNIT=gnome-remote-desktop.service` を見る

**選択した方針**

- **デスクトップ共有にする**（RHEL 10 の文書の 1.1 の方式）
  - PC の画面に出ているデスクトップを、そのまま共有する。PC の前にいる人と、同じ画面を見て操作できる
  - モニターの無い PC なら[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)、ログイン画面から入るなら[GNOME のリモートログイン](#gnome-のリモートログイン)
- **PC の画面を触らない前提にする**（利用者の依頼）— 遠隔の PC で、PC の画面・キーボード・マウスを使えなくても、SSH のシェルと RDP のクライアントだけで、設定・確認・復旧ができるようにした
- **自動ログインでデスクトップを作る** — SSH から GDM のログイン画面でログインする手段は無いので、PC の画面のセッションは自動ログインで作る。PC の前にいる人がこのデスクトップを使える危険は、手順書のリードの `[!WARNING]` に書いた
- **資格情報は、パスワードの無いキーリングに直接入れる** — 自動ログインではログインのキーリングが開かないので、`grdctl rdp set-credentials` は PC の画面に窓を出して止まる。ログインのキーリングのほかの秘密は、暗号化したまま残す
  - SSH から毎回ログインのキーリングを OS のパスワードで開く案は、停電などで再起動したときに、SSH で入り直すまで RDP が使えないので、利用者の選択で採らなかった
- **再起動の前に、戻ってこられるかを確かめる** — 遠隔では、SSH・GNOME の自動起動・ディスクの暗号化のどれかで止まると直せない
- **つながらなくなったときの直し方も SSH からにする** — ロックは `loginctl unlock-session`、ログイン画面が前に出たときは `loginctl activate`、ログアウトしたときは再起動
- **CLI だけで設定する** — RHEL 10 の文書の 1.1 は設定アプリでの操作だけを書いている。CLI では、上流の README の「From command line」と同じ `grdctl`（オプション無し）を使う
- **証明書は openssl で作る** — SAN に IP を入れる理由は gnome-remote-desktop.md と同じ
- **ポートを固定し、ポートのネゴシエーションを切る** — ファイアウォールで開けたポートと食い違わないように（ヘッドレスの手順書と同じ）
- **クライアントからの操作を許す**（`disable-view-only`）— 既定の見るだけは、「見るだけにする」の項で戻せる
- **起動画面（plymouth）を止める** — 止めないと、GDM が自動ログインの 20 秒後に plymouth を終わらせ、そのときに VT1 にログイン画面を作って前に出すので、共有するデスクトップが裏に回る。起動ごとに `loginctl activate` で戻す方法より、起動の引数で止める方を採った（PC の前にいなくても、再起動の後にそのままつながる）
- **再起動は `sudo` 無しの `systemctl reboot -i` にする** — PC の画面のアプリが終了を止めていると、その抑止を無視するのに polkit の認証が要り、`sudo` では聞かれずに断られるため。`sudo` 無しの形は、止められていてもいなくても通る

**参照**

- [Chapter 1. Remotely accessing the desktop — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/remotely-accessing-the-desktop)（1.1 Enabling desktop sharing on the server by using GNOME、1.3 の前提「For desktop sharing, a user is logged in to the GNOME graphical session on the server」）
- [GNOME/gnome-remote-desktop 49.3 README.md](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/blob/49.3/README.md)（Remote assistance の節。「From command line」）
- 上流のソース（49.3）: `src/grd-ctl.c`・`src/grd-settings-user.c`・`src/grd-credentials-libsecret.c`・`src/org.gnome.desktop.remote-desktop.gschema.xml.in`・`data/gnome-remote-desktop.service.in`・`data/gnome-remote-desktop-headless.service.in`
- 上流の issue: [#27](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/27)（キーリングが閉じていると認証できない。自動ログイン）・[#166](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/166)（SSH から資格情報を設定できない）・[#172](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/172)（ロックで切れる）・[#255](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/255)（`grdctl status` のポート）・[#338](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/338)（自動ログインの後の資格情報）
- [gnome-control-center #3547](https://gitlab.gnome.org/GNOME/gnome-control-center/-/issues/3547)（キーリングが閉じているときに「リモート デスクトップ」を開くと、パスワードが乱数に書き換わる。GNOME 50 で修正）
- GDM 47.0 のソース: [`daemon/gdm-manager.c`](https://gitlab.gnome.org/GNOME/gdm/-/blob/47.0/daemon/gdm-manager.c)（`on_user_session_started` の 20 秒後の `plymouth quit --retain-splash`）・[`daemon/gdm-local-display-factory.c`](https://gitlab.gnome.org/GNOME/gdm/-/blob/47.0/daemon/gdm-local-display-factory.c)（`on_vt_changed`）
- gdm のパッケージの履歴（AlmaLinux の git）: [actually quit plymouth at startup](https://git.almalinux.org/rpms/gdm/commit/ad6daf364e3156d2ed7950b08a9a977d3df68a0b)（2015 年の gdm 3.16 の変更。自動ログインでログイン画面が出ないときは、20 秒後に plymouth を終わらせる）
- systemd 257 のソース: [`src/systemctl/systemctl-logind.c`](https://github.com/systemd/systemd/blob/v257/src/systemctl/systemctl-logind.c)（`logind_check_inhibitors`）・[`src/login/logind-dbus.c`](https://github.com/systemd/systemd/blob/v257/src/login/logind-dbus.c)（`verify_shutdown_creds`）・[`src/shared/polkit-agent.c`](https://github.com/systemd/systemd/blob/v257/src/shared/polkit-agent.c)（`polkit_agent_open`）
- gnome-keyring 42.1 の D-Bus の内部のインターフェース `org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface`（`CreateWithMasterPassword`・`UnlockWithMasterPassword`）。VM の gnome-keyring で呼んで確かめた

- 検証記録（`docs/verification/gnome-desktop-sharing.md`）

</details>

---

### GNOME のヘッドレスセッション

- モニターの無い PC でも、自分の GNOME のデスクトップをヘッドレスのセッションで常駐させ、RDP でつなぐ
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)と、[画面オフ・画面ロック・自動サスペンドを止める](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)の手順 1・2 を通してある。サスペンドできる PC は、同じ項の手順 3・4 も通してある
- 実行場所: セッションを使うユーザー本人のシェル（bash。SSH でよい）。この項の手順 10 は、LAN 内の別のマシンで行う
- [リモートログイン](#gnome-のリモートログイン)と同じ PC でも使える

> [!IMPORTANT]
> - **セッションを使うユーザー本人のシェルで貼る**。`sudo -i` / `su -` したシェルでは貼らない
> - この項の手順 10（クライアントからの接続）だけ別のマシンで行う

1. 変数を設定する（`SERVER_IP` は必ず値を入れる）。

   ```bash
   SERVER_IP=192.0.2.100               # ← 自分の値に書き換える。クライアントが接続に使う IP。<SERVER_IP>
   ```

   ```bash
   SERVER_NAME=$(hostname)             # 証明書の CN と SAN に入る（自動）。<HOSTNAME>
   SERVER_FQDN=$(hostname -f)          # 同上。<HOSTNAME>.<DOMAIN>
   RDP_PORT=$(if [ "$(systemctl is-enabled gnome-remote-desktop.service 2>/dev/null)" = enabled ]; then echo 3390; else echo 3389; fi)   # 待ち受けるポート（自動）。<RDP_PORT>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in USER SERVER_IP SERVER_NAME SERVER_FQDN RDP_PORT; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須なのは `SERVER_IP` の 1 行だけ**
   - `USER` が `root` なら、ここで止めて、セッションを使うユーザーのシェルで貼り直す
   - **新しいシェルを開いたら**、この項の手順 1 の 2 つのブロックを貼り直してから先へ進む

1. ヘッドレスのセッションを有効にして起動し、セッションができたかを確かめる。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。セッションを使うユーザーのシェルで貼り直す' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     sudo systemctl enable --now "gnome-headless-session@${USER}.service"
     for i in $(seq 1 30); do
       busctl --user status org.gnome.Mutter.ScreenCast >/dev/null 2>&1 &&
         [ -n "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"')" ] && break
       sleep 1
     done
     loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"'
     pgrep -a -u "${USER}" -x gnome-shell
   fi
   ```

   - 自分の `headless` セッションと、`/usr/bin/gnome-shell` が出ればよい
   - 何も出ないときは、`systemctl status "gnome-headless-session@${USER}.service"` と `systemctl --user status org.gnome.Shell@wayland.service` を見る

1. 共用する TLS 設定を退避し、証明書と鍵を作る（既にあれば作らない）。

   ```bash
   # 変更前の共用 TLS 設定を退避する
   if [ -z "${SERVER_IP}" ] || [ -z "${SERVER_NAME}" ] || [ -z "${SERVER_FQDN}" ]; then
     echo '中断: 手順 1 の変数が空のまま。手順 1 を貼り直す' >&2
   else
     (
       set -e
       trap 'echo "中断: 手順 3 が失敗した。手順 4 へ進まない" >&2' ERR
       if [ -e ~/.local/state/gnome-headless-session-setup ] || [ -L ~/.local/state/gnome-headless-session-setup ]; then
         if [ -L ~/.local/state/gnome-headless-session-setup ] ||
            [ ! -f ~/.local/state/gnome-headless-session-setup/backup-complete ] ||
            [ ! -f ~/.local/state/gnome-headless-session-setup/tls-cert ] ||
            [ ! -f ~/.local/state/gnome-headless-session-setup/tls-key ]; then
           echo '中断: TLS 設定の退避が不完全。退避内容を確認し、先へ進まない' >&2
           exit 1
         fi
       else
         umask 077
         mkdir -p ~/.local/state
         mkdir ~/.local/state/gnome-headless-session-setup
         dconf read /org/gnome/desktop/remote-desktop/rdp/tls-cert > ~/.local/state/gnome-headless-session-setup/tls-cert
         dconf read /org/gnome/desktop/remote-desktop/rdp/tls-key > ~/.local/state/gnome-headless-session-setup/tls-key
         touch ~/.local/state/gnome-headless-session-setup/backup-complete
       fi
       # 証明書と鍵を用意し、生成物を記録する
       rm -f ~/.local/state/gnome-headless-session-setup/ready ~/.local/state/gnome-headless-session-setup/restored
       if [ -e ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] || [ -L ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] ||
          [ -e ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ] || [ -L ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ]; then
         if [ ! -s ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] ||
            [ ! -s ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ]; then
           echo '中断: 証明書と鍵の両方が必要。既存ファイルは上書きしていない' >&2
           exit 1
         fi
       else
         mkdir -p ~/.local/share/gnome-remote-desktop/certificates
         touch ~/.local/state/gnome-headless-session-setup/created-certificate
         openssl req -x509 -newkey rsa:2048 -noenc -days 3650 \
           -subj "/CN=${SERVER_NAME}" \
           -addext "subjectAltName=DNS:${SERVER_NAME},DNS:${SERVER_FQDN},DNS:${SERVER_IP},IP:${SERVER_IP}" \
           -addext "extendedKeyUsage=serverAuth" \
           -keyout ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key \
           -out    ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
         chmod 644 ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
         sha256sum ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt \
           ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key > ~/.local/state/gnome-headless-session-setup/created.sha256
       fi
       # 証明書と鍵を読み、準備完了を記録する
       openssl x509 -in ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt -noout
       openssl pkey -in ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key -passin pass: -noout
       touch ~/.local/state/gnome-headless-session-setup/ready
       printf '\n\033[7m 確認 \033[0m\n'
       ls -l ~/.local/share/gnome-remote-desktop/certificates
       echo 'TLS の退避と証明書の準備が完了'
     )
   fi
   ```

   - 最後に `TLS の退避と証明書の準備が完了` と出れば、この項の手順 4 へ進む
   - 既存の鍵も、パスフレーズなしで読める必要がある
   - `中断:` が出たら、この項の手順 4 以降へ進まない。[証明書の準備に失敗したとき](#gnome-のヘッドレスセッション-証明書の準備に失敗したとき)を通す

1. `grdctl --headless` で、証明書と鍵・ポートを設定する。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: 手順 1 の RDP_PORT が空のまま。手順 1 を貼り直す' >&2
   elif [ ! -f ~/.local/state/gnome-headless-session-setup/ready ]; then
     echo '中断: 手順 3 が完了していない。TLS 設定は変更しない' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     rm -f ~/.local/state/gnome-headless-session-setup/restored &&
     grdctl --headless rdp set-tls-cert ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt &&
     grdctl --headless rdp set-tls-key ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key &&
     grdctl --headless rdp set-port "${RDP_PORT}" &&
     grdctl --headless rdp disable-port-negotiation
   fi
   ```

   - TPM の無い PC の `Init TPM credentials failed … using GKeyFile as fallback.` は正常
   - 初回の `BIO_new failed for certificate` と `RDP server certificate is invalid.` は正常

1. RDP のユーザー名とパスワードを、引数なしで対話入力する。

   ```bash
   grdctl --headless rdp set-credentials
   ```

   - クライアント用の RDP のユーザー名とパスワードを入力する（OS のアカウントと違ってよい）
   - **次の手順は、ユーザー名とパスワードを入力し終えてから貼る**（続けて貼ると、資格情報を設定できなかったときも RDP を有効にするコマンドが動く）

1. RDP を有効にする。

   ```bash
   # ヘッドレス用の RDP サービスを有効にする
   grdctl --headless rdp enable
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user is-enabled gnome-remote-desktop-headless.service
   ```

   - `enabled` と出ればよい

1. ファイアウォールで、`RDP_PORT` の TCP を開ける。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: 手順 1 の RDP_PORT が空のまま。手順 1 を貼り直す' >&2; else
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --permanent --add-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   fi
   ```

   - `success` が出て、最後に設定した `RDP_PORT` の TCP があればよい

1. デーモンが待ち受けているかを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # RDP の設定と稼働状態を確認する
   grdctl --headless status
   # RDP の待ち受けを確認する
   ss -Hlnt "sport = :${RDP_PORT:?手順 1 の RDP_PORT が空のまま}"
   ```

   - `grdctl --headless status` で、`Unit status: active`・`Status: enabled`・`Port: <RDP_PORT>`・`Negotiate port: no`・`Username: (hidden)` を確かめる
   - `TLS fingerprint` の値を控えておく（この項の手順 9 と手順 10 で使う）
   - `ss` に `RDP_PORT` の `LISTEN` があればよい

1. TLS のハンドシェイクと、提示される証明書を確かめる。

   ```bash
   # TLS 確認用のスクリプトを作成する
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
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/python3 ~/rdp_tls_probe.py "${SERVER_IP}" "${RDP_PORT}"
   grdctl --headless status 2>/dev/null | grep 'TLS fingerprint'
   ```

   - 次の 3 つがそろえばよい
     - `selectedProtocol=0x2` でネゴシエーションが成立する
     - `fingerprint:` の行が、最後の `TLS fingerprint:` の行と**完全一致**する
     - SAN に、接続に使う名前が `DNS:` エントリとして含まれている

1. LAN 内の別のマシンから、RDP クライアントでつなぐ。

   - AlmaLinux 10 は `freerdp` の `xfreerdp /v:<SERVER_IP>:<RDP_PORT> /u:<RDP のユーザー名>` でつなぐ
   - Windows は「リモート デスクトップ接続」で `<SERVER_IP>:<RDP_PORT>` につなぐ
   - `<SERVER_IP>`・`<RDP_PORT>`・`<RDP のユーザー名>` は、この項の手順 1 と手順 5 の値に読み替える
   - 証明書の確認を聞かれたら、表示された Thumbprint がこの項の手順 8 の `TLS fingerprint` と同じかを見てから受け入れる
     - FreeRDP は、`Thumbprint:` の後に `Do you trust the above certificate? (Y/T/N)` と聞く。同じなら `Y` で答える
     - FreeRDP は、初めてつなぐときも、その前に `REMOTE HOST IDENTIFICATION HAS CHANGED!` などの警告を出す。続く `Thumbprint:` で判断する
     - `Y` で答えた後は、同じクライアントからつなぎ直しても証明書の確認は出ず、`Domain:` から聞かれる
   - FreeRDP は `Domain:` も聞く。空のまま Enter を押す
   - パスワードはこの項の手順 5 のもの。通ると、このセッションの GNOME のデスクトップが、クライアントの窓の大きさで出る
     - FreeRDP は、パスワードの後に `[ERROR][com.winpr.sspi.Kerberos]` の `krb5_parse_name (Configuration file does not specify default realm …)` の行を出すことがある。デスクトップが出れば、害は無い
   - 切ってつなぎ直すと、同じデスクトップ（開いていたアプリもそのまま）に戻る
   - 問題があれば、PC の端末で `journalctl -b _SYSTEMD_USER_UNIT=gnome-remote-desktop-headless.service` を見る
     - この項の手順 9 を貼った時刻の `client authentication failure` と `Network or intentional disconnect, stopping session` などの行は、そのプローブが残したもの。害は無い

#### GNOME のヘッドレスセッション: 証明書の準備に失敗したとき

- 証明書の準備に失敗したときに、共用 TLS 設定を復旧し、今回生成したファイルだけを片付ける。[リモートログインだけにする](#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)の手順 5 からも使う
- 前提: [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 3 で失敗した、または[リモートログインだけにする](#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)の手順 4 までを通した
- 実行場所: セッションを使うユーザー本人で SSH でログインしたシェル（bash）
- 退避後にデスクトップ共有の TLS 設定を別に変えた場合は、先にその設定を控える
- 退避が無い場合は、共用 TLS 設定と証明書を保持する

> [!CAUTION]
> **この項の手順 2 で消す証明書の秘密鍵は取り戻せない**。今回生成したものと照合できた場合だけ消し、既存の証明書と鍵は残す。

1. RDP とヘッドレス用の資格情報・設定を解除し、共用 TLS 設定を戻す。

   ```bash
   # 退避を確認し、復旧処理を開始する
   (
     set -e
     trap 'echo "中断: 復元が失敗した。この項の手順 2 へ進まない" >&2' ERR
     if { [ -e ~/.local/state/gnome-headless-session-setup ] || [ -L ~/.local/state/gnome-headless-session-setup ]; } &&
        { [ -L ~/.local/state/gnome-headless-session-setup ] ||
          [ ! -f ~/.local/state/gnome-headless-session-setup/backup-complete ] ||
          [ ! -f ~/.local/state/gnome-headless-session-setup/tls-cert ] ||
          [ ! -f ~/.local/state/gnome-headless-session-setup/tls-key ]; }; then
       echo '中断: TLS 設定の退避が不完全。設定とファイルは変更しない' >&2
       exit 1
     fi
     # ヘッドレス用の RDP と資格情報を解除する
     rm -f ~/.local/state/gnome-headless-session-setup/restored
     grdctl --headless rdp disable
     grdctl --headless rdp clear-credentials
     dconf reset -f /org/gnome/desktop/remote-desktop/rdp/headless/
     # 退避した共用 TLS 設定を復元する
     if [ -f ~/.local/state/gnome-headless-session-setup/backup-complete ]; then
       for key in tls-cert tls-key; do
         if [ -s ~/.local/state/gnome-headless-session-setup/"${key}" ]; then
           dconf write "/org/gnome/desktop/remote-desktop/rdp/${key}" "$(cat ~/.local/state/gnome-headless-session-setup/"${key}")"
         else
           dconf reset "/org/gnome/desktop/remote-desktop/rdp/${key}"
         fi
       done
       touch ~/.local/state/gnome-headless-session-setup/restored
     else
       echo '退避なし: 共用 TLS 設定と証明書は保持する'
     fi
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl --user is-enabled gnome-remote-desktop-headless.service || true
   )
   ```

   - コマンドごとの TPM のメッセージ（`Init TPM credentials failed …`、TPM の無い PC では正常）の後に、`disabled` と出ればよい
   - `中断:` やエラーが出たら、この項の手順 2 へ進まない。共用 TLS 設定が戻る前は、証明書を削除できない

1. [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 3 で生成した証明書と鍵と、TLS 設定の退避を消す（取り戻せない）。

   ```bash
   # TLS 設定の復元記録を確認する
   if [ -L ~/.local/state/gnome-headless-session-setup ]; then
     echo '中断: TLS 設定の退避先がリンクになっている。ファイルは削除しない' >&2
   elif [ ! -e ~/.local/state/gnome-headless-session-setup ]; then
     echo '退避なし: 証明書と鍵は削除しない'
   elif [ ! -f ~/.local/state/gnome-headless-session-setup/restored ]; then
     echo '中断: 共用 TLS 設定を戻していない。この項の手順 1 を先に完了する' >&2
   else
     (
       set -e
       # 生成物を照合し、証明書と鍵を削除する
       if [ -f ~/.local/state/gnome-headless-session-setup/created-certificate ]; then
         if [ ! -f ~/.local/state/gnome-headless-session-setup/created.sha256 ] ||
            [ -L ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] ||
            [ -L ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ]; then
           echo '中断: 生成物を照合できないか、リンクへ置き換わっている。証明書と退避は削除しない' >&2
           exit 1
         fi
         if ! sha256sum --check ~/.local/state/gnome-headless-session-setup/created.sha256; then
           echo '中断: 生成後に証明書か鍵が変わっている。証明書と退避は削除しない' >&2
           exit 1
         fi
         rm -f ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
         rmdir --ignore-fail-on-non-empty ~/.local/share/gnome-remote-desktop/certificates
       fi
       # 設定の退避と確認用スクリプトを削除する
       rm -f ~/.local/state/gnome-headless-session-setup/tls-cert ~/.local/state/gnome-headless-session-setup/tls-key \
         ~/.local/state/gnome-headless-session-setup/backup-complete ~/.local/state/gnome-headless-session-setup/ready \
         ~/.local/state/gnome-headless-session-setup/restored ~/.local/state/gnome-headless-session-setup/created-certificate \
         ~/.local/state/gnome-headless-session-setup/created.sha256
       rmdir --ignore-fail-on-non-empty ~/.local/state/gnome-headless-session-setup
       rm -f ~/rdp_tls_probe.py
     )
   fi
   ```

   - `中断:` のときは、生成途中のファイルや後から差し替えたものを手で確認する。照合できないものは自動削除しない

#### GNOME のヘッドレスセッション: 接続元を LAN に絞る

- ヘッドレスのセッションの RDP のポートを、LAN の送信元サブネットからだけ受け付けるようにする
- 前提: [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)を通してある
- 実行場所: セッションを使うユーザー本人のシェル（bash。SSH でよい）
- **接続元を制限しないなら、この項は不要**

1. 変数を設定する。

   ```bash
   RDP_PORT=$(if [ "$(systemctl is-enabled gnome-remote-desktop.service 2>/dev/null)" = enabled ]; then echo 3390; else echo 3389; fi)   # 待ち受けるポート（自動）。<RDP_PORT>
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'RDP_PORT = %s\n' "${RDP_PORT}"
   ```

   - `RDP_PORT` が、[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 1 で設定した値と違えば、`RDP_PORT` の行をその値に書き換えて貼り直す
   - **新しいシェルを開いたら**、この項の手順 1 を貼り直してから先へ進む

1. LAN に絞るなら、送信元サブネットを入れ、ポートの開放を rich rule に置き換える。

   ```bash
   LAN_SUBNET=192.0.2.0/24              # ← 自分の値に書き換える。<LAN_SUBNET>
   ```

   ```bash
   if [ -z "${LAN_SUBNET}" ] || [ -z "${RDP_PORT}" ]; then echo '中断: LAN_SUBNET か、この項の手順 1 の RDP_PORT が空のまま。値を入れて貼り直す' >&2; else
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --permanent --remove-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=${RDP_PORT} protocol=tcp accept"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   sudo firewall-cmd --list-rich-rules        # source address と port に実際の値が入っていることを確認する
   fi
   ```

   - `success` が出て、ポート一覧から `RDP_PORT` の TCP が消え、rich rule に `LAN_SUBNET` と `RDP_PORT` があればよい

#### GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）

- [リモートログイン](#gnome-のリモートログイン)と[ヘッドレスのセッション](#gnome-のヘッドレスセッション)を併用している PC で、ヘッドレスのセッションをやめ、リモートログインだけにする
- 前提: [GNOME のリモートログイン](#gnome-のリモートログイン)と[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)を通して、併用している。ログインしていない間もユーザーのサービスを動かすなら、先に [ユーザーサービスの常駐](almalinux-setup.md#ユーザーサービスの常駐) を通す（linger が無いと、セッションが 1 つも無い間はユーザーの systemd が止まる）
- 実行場所: セッションを使うユーザー本人で SSH でログインしたシェル（bash）。この項の手順 7 は、クライアントの PC で行う
- ヘッドレスのセッションで動いていたアプリは閉じる

> [!IMPORTANT]
> - **セッションを使うユーザー本人のシェルに、SSH で入って貼る**。リモートログインのセッションの中の端末では貼らない
> - この項の手順 7（クライアントからの接続）だけ、クライアントの PC で行う

1. 今の状態を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 現在のセッションを確認する
   for s in $(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless" {print $1}'); do
     echo "${s} $(loginctl show-session "${s}" -p Service --value)"
   done
   # ヘッドレス用のサービスの起動設定を確認する
   systemctl is-enabled "gnome-headless-session@${USER}.service"
   systemctl --user is-enabled gnome-remote-desktop-headless.service
   # ファイアウォールの許可を確認する
   sudo firewall-cmd --list-ports
   sudo firewall-cmd --list-rich-rules
   ```

   - 2 つ目の `systemctl` が `enabled`、`--list-ports` に `3390/tcp`、rich rule に `port="3390"` のどれかがあれば、ヘッドレスのセッションの RDP を設定してある。どれも無ければ、この項の手順 2〜5 は飛ばす

1. ヘッドレスのセッションの RDP を設定してあるときだけ、変数を設定する。

   - [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 1 の 2 つのブロックを貼り、`RDP_PORT` が `3390` であることを確かめる
   - 接続元を LAN に絞ってあるときは、[接続元を LAN に絞る](#gnome-のヘッドレスセッション-接続元を-lan-に絞る)の手順 2 の 1 つ目のブロックを貼り、絞ったときと同じ `LAN_SUBNET` を入れる。その場合は、この項の手順 3 を飛ばして手順 4 へ進む

1. ヘッドレスのセッションの RDP を設定し、LAN に絞っていないときだけ、開けたポートを閉じる。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: この項の手順 2 の RDP_PORT が空のまま。この項の手順 2 を貼り直す' >&2; else
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --permanent --remove-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   fi
   ```

   - `success` が出て、ポート一覧から `RDP_PORT` の TCP が消えていればよい

1. ヘッドレスのセッションの RDP の接続元を LAN に絞ったときだけ、rich rule を消す（この項の手順 3 の代わりに）。

   ```bash
   if [ -z "${LAN_SUBNET}" ] || [ -z "${RDP_PORT}" ]; then echo '中断: LAN_SUBNET か、この項の手順 2 の RDP_PORT が空のまま。値を入れて貼り直す' >&2; else
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=${RDP_PORT} protocol=tcp accept"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-rich-rules
   fi
   ```

   - `LAN_SUBNET` は、[接続元を LAN に絞る](#gnome-のヘッドレスセッション-接続元を-lan-に絞る)の手順 2 の 1 つ目のブロックを貼り直して入れる
   - `success` が出て、その rich rule が消えていればよい

1. ヘッドレスのセッションの RDP を設定してあるときだけ、共用 TLS 設定を復旧して証明書を片付ける。

   - [証明書の準備に失敗したとき](#gnome-のヘッドレスセッション-証明書の準備に失敗したとき)の手順 1・2 を通す

1. ヘッドレスのセッションを止めて起動時に作らないようにし、終わったかを確かめる。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。セッションを使うユーザーのシェルで貼り直す' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     sudo systemctl disable --now "gnome-headless-session@${USER}.service"
     for i in $(seq 1 30); do
       [ "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless" {print $1}' |
         xargs -r -n 1 loginctl show-session -p Service --value 2>/dev/null | grep -cx gdm-autologin)" -eq 0 ] && break
       sleep 1
     done
     loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless" {print $1}' |
       xargs -r -n 1 loginctl show-session -p Service --value 2>/dev/null | grep -cx gdm-autologin
   fi
   ```

   - `0` が出ればよい

1. クライアントの PC から、リモートログインでつなぎ直してログインする。

   - Windows なら「リモート デスクトップ接続」で `<SERVER_IP>`（3389/tcp）につなぎ、GDM のログイン画面からログインする（[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 11 と同じ）
   - 上部バーのあるデスクトップが、クライアントの窓の大きさで出ればよい
   - 切断してつなぎ直すと、同じデスクトップに戻る
   - **次の手順は、ログインし終えてから貼る**

1. サーバーで、リモートログインのセッションだけになったかを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 残っているセッションと GNOME を確認する
   for s in $(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless" {print $1}'); do
     echo "${s} $(loginctl show-session "${s}" -p Service --value)"
   done
   pgrep -a -u "${USER}" -x gnome-shell
   # ヘッドレスの自動起動の設定を確認する
   systemctl is-enabled "gnome-headless-session@${USER}.service"
   # リモートログインの待ち受けを確認する
   ss -Hlnt 'sport = :3389'
   ```

   - `<SESSION_ID> gdm-password` の 1 行だけが出て、`gdm-autologin` の行が無ければよい
   - gnome-shell の行が出ればよい
   - 続いて `disabled` と、`LISTEN … *:3389 …` の 1 行が出ればよい

<details id="gnome-のヘッドレスセッション-の補足と注意点">
  <summary>GNOME のヘッドレスセッション の補足と注意点</summary>

**注意点**

- **Homebrew が PATH の先頭にあると、`gsettings`・`gdbus`・`gio`・`python3` が Homebrew のものになる**（[AlmaLinux 10 のセットアップの「Homebrew の補足と注意点」](almalinux-setup.md#homebrew-の補足と注意点)）。前提の[画面オフ・画面ロック・自動サスペンドを止める](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)の手順は `/usr/bin/gsettings` で書いてある（Homebrew の `gsettings` は GNOME に効かない）
- **同じユーザーの GNOME のセッションは 1 つにする**: PC の画面から同じユーザーで入るときは、先に `sudo systemctl stop gnome-headless-session@<USER>.service` でヘッドレスのセッションを止める
  - gnome-session のユーザーの unit（`gnome-session-manager@gnome.service` など）はユーザーに 1 組しか無いので、2 つ目のセッションは動かないはず
  - このセッションにつなげるのは 1 つだけ。3390 とリモートログインから同時につなぐと、後からつないだ方が残り、先の接続は切られた（どちらが先でも同じ）
  - PC の画面のセッションを共有する[GNOME のデスクトップ共有](#gnome-のデスクトップ共有)とは、同じユーザーでは併用できない（ヘッドレスの RDP のデーモンの unit に `Conflicts=gnome-remote-desktop.service` がある）
- **リモートログインのセッションも、`loginctl list-sessions` の `TTY` の列は `headless` になる**: ヘッドレスのセッションと見分けるときは、`loginctl show-session` の `Service` が `gdm-autologin`（ヘッドレス）か `gdm-password`（リモートログイン）かで見る
  - [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 2 の確かめの行は `TTY` の列だけで見るので、同じユーザーのリモートログインのセッションがあると、ヘッドレスのセッションができる前に抜けるはず（確かめていない）
- **起動し直すときは `stop` → 待つ → `start` を使う**。前のセッションの片付けを待ってから新しいセッションを始める
- **GDM を再起動すると、このセッションも止まって起動し直される**（`Requires=gdm.service`）
  - GDM を再起動したら `systemctl is-active gnome-headless-session@<USER>.service` を見て、`inactive` なら `sudo systemctl start gnome-headless-session@<USER>.service` で起動する
- **セッションを止めると、ユーザーの D-Bus が起動し直される**: GNOME のセッションが終わると、`gnome-session-restart-dbus.service` がユーザーのセッションバスを起動し直す
- **ログインのキーリングは開いていない**: パスワード無しで作るセッションなので、キーリング（`login`）はロックされたまま。パスワードを読もうとするアプリは、キーリングを開く窓を出す
- **サスペンドとロック**: ヘッドレスのセッションでも gsd-power は動き、既定では 15 分の無操作で PC をサスペンドしようとする。前提の[画面オフ・画面ロック・自動サスペンドを止める](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)の手順 1・2 で止める
  - seat0 には GDM のログイン画面が残り、Workstation で入れた PC ではそれも 15 分で PC を眠らせる。サスペンドできる PC では、[画面オフ・画面ロック・自動サスペンドを止める](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)の手順 3・4 も行う
- **リモートログインを有効にしている PC**: セッションの中で `gnome-remote-desktop-handover.service` も起動する（リモートログインの受け渡し役。TCP では待ち受けない）
  - リモートログインのデーモン（`gnome-remote-desktop.service`）を起動し直したら、この受け渡し役のデーモンも再起動する（[GNOME のリモートログイン: デーモンを起動し直す](#gnome-のリモートログイン-デーモンを起動し直す)の手順 2）。しないと、リモートログインからこのセッションへ渡せなくなるはず
- **自己署名証明書**: クライアントは初回に証明書の確認を出す。証明書を作り直したら、クライアントで保存済みの証明書を消すか、変更の警告を承認する（[GNOME のリモートログイン の補足と注意点](#gnome-のリモートログイン-の補足と注意点)の「注意点」と同じ）
- **資源**: セッションを起動すると、`free` の `available` が約 600 MB 減った（aarch64 の実機、アプリを開いていないとき）

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)のリード**

- **[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 5 は RDP のユーザー名とパスワードの対話入力がある**。入力し終えてから次の手順を貼る

- [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 1 で変数を設定したシェルに貼る

- [GNOME のリモートログイン](#gnome-のリモートログイン)（GDM で認証し、新しいセッションを作るか既存のセッションへ引き渡す方式）と同じ PC でも使える。そのときのポートは、[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 1 で自動で 3390 になる

- セッションと RDP の設定は、貼ったユーザーのものになる

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 1**

- **編集が必須なのは `SERVER_IP` の 1 行だけ**。残りは既定のままでよい

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 1: 変数について**

- `SERVER_IP`・`SERVER_NAME`・`SERVER_FQDN` は、[GNOME のリモートログイン](#gnome-のリモートログイン) の手順 1 と同じ。証明書の SAN に入れる（[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 3）
- `RDP_PORT` の判定に使う `systemctl is-enabled gnome-remote-desktop.service` は、`--user` を付けないのでシステムの unit を見る
- リモートログインのデーモンは 3389/tcp で待ち受けるので、同じ PC ではヘッドレスのセッションの RDP を 3390/tcp にする
- `RDP_PORT` は、リモートログインのシステムのデーモン（`gnome-remote-desktop.service`）が有効なら `3390`、そうでなければ `3389` になる
- 任意の変数のブロックは、最後に値を読み戻す
- 変数はそのシェルの中だけで有効なので、新しいシェルでは[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 1 の 2 つのブロックを貼り直す

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 2**

- `gnome-headless-session@<USER>.service` の `Created symlink` が出る

- 続いて `<SESSION_ID> <UID> <USER> - <PID> user headless no -` の形の行と、`<PID> /usr/bin/gnome-shell` が出ればよい

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 2: gnome-headless-session@.service と、セッションの見分け方**

**gnome-headless-session@.service**:

- gdm の unit。`gdm` ユーザーで `gdm-new-session <USER> --headless` を動かし、GDM に、モニターの無いセッションを作らせる（RHEL 10 の文書の「1.4 headless server for a single user」と同じ unit）
- できるセッションは、`loginctl` で `Class=user`・`Type=wayland`・`TTY=headless`・`Remote=yes`・`Service=gdm-autologin`・seat 無し
- PAM は `gdm-autologin` で、パスワードを使わない。ログインのキーリングは開かない（この折りたたみの「注意点」）
- `WantedBy=graphical.target` なので、`enable` で起動時にも作られる。`Requires=gdm.service`

**セッションの見分け方と、モニターが無い間**:

- `loginctl` の行の `awk` は、このユーザーのヘッドレスのセッションの行だけを出す。ほかのユーザーのヘッドレスのセッションも `TTY` が `headless` になる
- `for` の行で、gnome-shell のバス名と `loginctl` のセッションの両方が出るまで、30 秒まで待つ
- このセッションには、RDP のクライアントがつないでいない間、モニターが 1 枚も無い。アプリはそのまま動き続ける
- クライアントがつなぐと、そのクライアントの窓の大きさの仮想モニターができ、切ると消える

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 3**

- 新規生成した場合は `rdp-tls.crt`（`-rw-r--r--`）と `rdp-tls.key`（`-rw-------`）が出る

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 3: 証明書**

- 中身は [GNOME のリモートログイン](#gnome-のリモートログイン)の手順 2 と同じ（SAN に IP を `DNS:` でも入れる理由も同書の補足）。違うのは、自分のホームに自分の所有で作ること
- RHEL の文書は `winpr-makecert` で作るが、ここでは SAN を付けるために openssl で作る
- TLS のパスはデスクトップ共有と共用なので、最初に dconf の元値を `~/.local/state/gnome-headless-session-setup` に退避する。未設定だったキーは空ファイルになる
- 貼り直しても退避は上書きしない。`backup-complete` は退避完了、`ready` は証明書の準備完了、`created-certificate` はこの手順が新規生成したことの目印
- 新規生成したファイルの SHA-256 も `created.sha256` に保存する。[GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）](#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)では、中身が変わっていたりリンクへ置き換わっていたりすれば削除しない
- 既存の証明書を更新する手順ではない
- `set -e` は丸括弧の中だけに効かせ、退避・生成・読み取りのどれかが失敗したら、そのブロックを止める
- 既存の証明書と鍵は上書きしない
- `中断:` のとき、生成途中で照合用の記録も作れなかった場合は、ファイルは自動削除されず残る
- 置き場所は、RHEL 10 の文書の 1.4 と同じ

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 4**


- 初めて設定するときだけ、`[x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` が 1 回ずつ出る。害は無い

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 4: grdctl --headless**

- `--headless` を付けた `grdctl` は、ヘッドレスのセッションのデーモン（`gnome-remote-desktop-headless.service`）の設定を変える
- 書き先は dconf。ポートなどは `/org/gnome/desktop/remote-desktop/rdp/headless/`、証明書と鍵は、デスクトップ共有と同じ `/org/gnome/desktop/remote-desktop/rdp/` に入る
- 資格情報（[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 5）は、TPM があれば TPM に、無ければ `~/.local/share/gnome-remote-desktop/credentials.ini`（GKeyFile）に置く
- `disable-port-negotiation` は、指定したポートが使われていたときに、次のポートを順に試すのを止める。ポートが勝手に変わって、[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 7 で開けたポートと食い違うのを防ぐ
- 初めて設定するときだけ出る `[x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` は、設定する前の空の値を読んだもの

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 5**

- ユーザー名とパスワードを聞かれる。クライアントが接続するときに入れるもので、OS のアカウントと違ってよい

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 5: 資格情報の置き場所**

- TPM の無い PC では、`~/.local/share/gnome-remote-desktop/credentials.ini` に入る（0600。暗号化はされていない）
- パスワードを変えるときも、この手順を貼り直す
- 引数なしで打つのは、パスワードをシェルの履歴に残さないため

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 6**

- デーモンが待ち受けたかは、[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 8 で確かめる

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 6: grdctl --headless rdp enable**

- `grdctl --headless rdp enable` は、`/org/gnome/desktop/remote-desktop/rdp/headless/enable` を true にし、ユーザーの unit `gnome-remote-desktop-headless.service` を enable して起動する（`~/.config/systemd/user/gnome-session.target.wants/` にリンクができる）。
- unit は `WantedBy=gnome-session.target` なので、ヘッドレスのセッションと一緒に起動する

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 7**

- `success` が 2 行出て、最後に `<RDP_PORT>/tcp` を含む行が出ればよい

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 7: ファイアウォール**

- firewalld の定義済みサービス `rdp` は 3389/tcp だけなので、ポートで開ける
- public ゾーンで開けるので、public ゾーンに属するすべての NIC で開く（gnome-remote-desktop.md と同じ）
- リモートログインと併用している PC でも、ここで 3390/tcp を足す（3389/tcp はリモートログインの `rdp` サービスで開いている）

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 8**

- `ss` が `LISTEN … *:<RDP_PORT> …` の 1 行を出せばよい

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 9**

- 確認が済んだら `rm ~/rdp_tls_probe.py` で消してよい

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 9: TLS プローブ**

- スクリプトは [GNOME のリモートログイン](#gnome-のリモートログイン)の手順 10 と同じもの。第 2 引数でポートを渡す
- `/usr/bin/python3` で動かすのは、Homebrew が PATH の先頭にあるときも、同じ Python にするため（どちらでも動く）
- `~/rdp_tls_probe.py` は、この手順書が作る唯一の作業ファイル
- プローブは、TLS のハンドシェイクで証明書を受け取ると、認証をせずに接続を閉じる。デーモンは、この接続を `client authentication failure` などのエラーの行としてログに残す（2026-10-11 の Hyper-V の VM では 7 行。待ち受けと、その後の接続には響かなかった）
  - 同じスクリプトを使う [GNOME のリモートログイン の補足と注意点](#gnome-のリモートログイン-の補足と注意点)の「GNOME のリモートログインの手順 10: TLS プローブと、FreeRDP クライアントでの確かめ方」にも、この行が出て正常とある

**[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 10: FreeRDP の証明書の確認と、つなぐときの表示**

- FreeRDP 3.10.3 は、保存した証明書（`~/.config/freerdp/server/<SERVER_IP>_<RDP_PORT>.pem`）が無い初めての接続でも、`REMOTE HOST IDENTIFICATION HAS CHANGED!` の警告を出してから、証明書の確認（`Do you trust the above certificate? (Y/T/N)`）を出す。初めてでも警告が出る理由は、確かめていない
- `Y` で答えると、証明書がこのファイルに保存され、次からは聞かれない（検証記録: `docs/verification/gnome-headless-session.md` の「付録: Hyper-V の VM で通した記録（2026-10-11）」）。`T` と `N` で答えたときの動きは、確かめていない
- FreeRDP 3.10.3 は、`Password:` の後に `[ERROR][com.winpr.sspi.Kerberos] - [kerberos_AcquireCredentialsHandleA]: krb5_parse_name (Configuration file does not specify default realm [-1765328160])` を 2 行出してから、つながった（2026-10-11 の Hyper-V の VM。この行が出る理由は、確かめていない）
  - GNOME のリモートログイン の検証記録（`docs/verification/gnome-remote-desktop.md` の「常に出るが無害なログ」）には、近い行（`kerberos_AcquireCredentialsHandleA: krb5_init_context ...`）が、Kerberos を設定していない環境で NTLM に切り替わるときの出力として載っている

**[GNOME のヘッドレスセッション: 証明書の準備に失敗したとき](#gnome-のヘッドレスセッション-証明書の準備に失敗したとき)の手順 1**

- コマンドごとの TPM のメッセージの後に、`disabled` と出ればよい

**[GNOME のヘッドレスセッション: 証明書の準備に失敗したとき](#gnome-のヘッドレスセッション-証明書の準備に失敗したとき)の手順 2**

- 今回生成し、生成時の中身のままの証明書だけが消える。既存の証明書・ほかのファイルは残る

- `credentials.ini` 自体も残す。ヘッドレス用の資格情報は、[GNOME のヘッドレスセッション: 証明書の準備に失敗したとき](#gnome-のヘッドレスセッション-証明書の準備に失敗したとき)の手順 1 の `clear-credentials` で解除済み

- 退避の無い既存導入では何も削除しない。`~/rdp_tls_probe.py` が要らなければ手で消す

**[GNOME のヘッドレスセッション: 接続元を LAN に絞る](#gnome-のヘッドレスセッション-接続元を-lan-に絞る)のリード**

- [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 7 は、public ゾーンに属するすべての NIC で `RDP_PORT` の TCP を開く

**[GNOME のヘッドレスセッション: 接続元を LAN に絞る](#gnome-のヘッドレスセッション-接続元を-lan-に絞る)の手順 1**

- 最後に値を読み戻して確かめる

**[GNOME のヘッドレスセッション: 接続元を LAN に絞る](#gnome-のヘッドレスセッション-接続元を-lan-に絞る)の手順 2**

- `success` が 3 行出て、`--list-ports` に `<RDP_PORT>/tcp` が無く、rich rule に `<LAN_SUBNET>` と `<RDP_PORT>` が入っていればよい

**[GNOME のヘッドレスセッション: 接続元を LAN に絞る](#gnome-のヘッドレスセッション-接続元を-lan-に絞る)の手順 2: 引用符**

- rich rule は**二重引用符**で囲む。単一引用符だと変数が展開されない（[GNOME のリモートログイン: 接続元を LAN に絞る](#gnome-のリモートログイン-接続元を-lan-に絞る)）

**[GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）](#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)のリード**

- リモートログインの設定（システムのデーモン・証明書・資格情報・3389/tcp）は変えない

- やめた後は、リモートログインで使う。切断してもセッションは残り、次のログインでそこへ戻る

- [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 1 の変数は、[GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）](#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)の手順 2 を行うときだけ要る

**[GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）](#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)の手順 1**

- `grdctl --headless status` では確かめない

**[GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）](#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)の手順 1・6: セッションの見分け方**

- **`Service` で見分ける**: GDM がリモートログインで作るセッションも seat が無く、`loginctl list-sessions` の `TTY` の列は `headless` になる。ヘッドレスのセッションは PAM の `gdm-autologin`、リモートログインのセッションは `gdm-password` で作られるので、`loginctl show-session` の `Service` で分ける（検証記録: `docs/verification/gnome-headless-session.md` の「付録: 実機でリモートログインだけにした記録（2026-10-08）」）
- **`grdctl --headless status` で確かめない**: `~/.local/share/gnome-remote-desktop/credentials.ini` が無いと、空のまま作る（この折りたたみの「GNOME のヘッドレスセッションの手順 5: 資格情報の置き場所」）
- [GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）](#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)の手順 1 の `for` の行は、`<SESSION_ID> <Service>` を 1 セッション 1 行で出す
- [GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）](#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)の手順 6 の最後の数は、このユーザーの `gdm-autologin` のセッションだけを数え、リモートログインのセッションは数えない。`for` の行で、セッションが終わるまで、30 秒まで待つ

**[GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）](#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)の手順 3**

- `success` が 2 行出て、`--list-ports` に `<RDP_PORT>/tcp` が無ければよい

**[GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）](#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)の手順 4**

- `success` が 2 行出て、その rich rule が消えていればよい

**[GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）](#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)の手順 6**

- 有効だったときは `Removed '/etc/systemd/system/graphical.target.wants/gnome-headless-session@<USER>.service'.` と出る（既に `disabled` なら何も出ない）

- セッションで動いていたアプリも閉じる

- 続いて `0` が出ればよい

**選択した方針**

- **ヘッドレスのセッションにする**（RHEL 10 の文書の 1.4）
  - デスクトップ共有（設定アプリの「デスクトップ共有」。CLI で設定する手順は [GNOME のデスクトップ共有](#gnome-のデスクトップ共有)）は、PC の物理の画面を写す。モニターの無い PC には写す画面が無い
  - リモートログイン（[GNOME のリモートログイン](#gnome-のリモートログイン)）は、GDM で認証し、そのユーザーのセッションが無ければ作成する。切断後のセッションや、ここで常駐させたヘッドレスのセッションがあれば、そこへ引き渡す
  - ヘッドレスのセッションは RDP 接続より前から常駐し、[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 10 の接続では GDM のログイン画面を通らず、そのデスクトップへ入る
- **証明書は openssl で作る** — SAN に IP を入れる理由は gnome-remote-desktop.md と同じ
- **ポートを固定し、ポートのネゴシエーションを切る** — ファイアウォールで開けたポートと食い違わないように

**参照**

- [Chapter 1. Remotely accessing the desktop — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/remotely-accessing-the-desktop)（1.4 headless server for a single user）
- [GNOME/gnome-remote-desktop README.md](https://github.com/GNOME/gnome-remote-desktop/blob/master/README.md)（Headless の節）

- 検証記録（`docs/verification/gnome-headless-session.md`）
- 補足の実測（`docs/verification/gnome-headless-session.md` の「補足の実測」）

</details>

---

### GNOME のリモートログイン

- RDP のクライアントに GDM のログイン画面を出し、OS のアカウントでログインできるようにする
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)を通してある
- 実行場所: サーバーの、自分のユーザーのシェル（bash）。この項の手順 11 は、LAN 内の別のマシンで行う
- モニターの無い PC に自分のデスクトップを常駐させるなら、[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)を通す。同じ PC で併用できる
- PC の画面を触らず、デスクトップをそのまま RDP で共有する場合は[デスクトップ共有](#gnome-のデスクトップ共有)を通す
  - デスクトップ共有を 3389 で使っている PC では、この項の後に、[リモートログインと併用する](#gnome-のデスクトップ共有-リモートログインと併用する)を通して共有を 3390 へ移す

> [!IMPORTANT]
> - **すべてサーバー上で実行する**。この項の手順 11（クライアントからのログイン）だけ別マシン

1. 変数を設定する（`SERVER_IP` は必ず値を入れる）。

   ```bash
   SERVER_IP=192.0.2.100               # ← 自分の値に書き換える。クライアントが接続に使う IP。<SERVER_IP>
   ```

   ```bash
   SERVER_NAME=$(hostname)             # 証明書の CN と SAN に入る（自動）。<HOSTNAME>
   SERVER_FQDN=$(hostname -f)          # 同上。<HOSTNAME>.<DOMAIN>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in SERVER_IP SERVER_NAME SERVER_FQDN; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須なのは `SERVER_IP` の 1 行だけ**
   - `SERVER_IP` が空、または `SERVER_NAME` / `SERVER_FQDN` が意図した名前と違うなら、ここで止めて直す
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、この項の手順 1 の 2 つのブロックを貼り直してから先へ進む

1. `gnome-remote-desktop` ユーザーとして、TLS 証明書と鍵を openssl で生成する。

   ```bash
   if [ -z "${SERVER_IP}" ] || [ -z "${SERVER_NAME}" ] || [ -z "${SERVER_FQDN}" ]; then
     echo '中断: 手順 1 の変数が空のまま。手順 1 を貼り直す' >&2
   else
     # 保存先を作り、TLS 証明書と鍵を生成する
     sudo -u gnome-remote-desktop mkdir -p /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates
     sudo -u gnome-remote-desktop openssl req -x509 -newkey rsa:2048 -noenc -days 3650 \
       -subj "/CN=${SERVER_NAME}" \
       -addext "subjectAltName=DNS:${SERVER_NAME},DNS:${SERVER_FQDN},DNS:${SERVER_IP},IP:${SERVER_IP}" \
       -addext "extendedKeyUsage=serverAuth" \
       -keyout /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key \
       -out    /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
   fi
   ```

   - `中断:` と出たら、何も変更していない。この項の手順 1 を貼り直してから、この手順をやり直す

1. 証明書と鍵のパーミッションと、SELinux のコンテキストを整える。

   ```bash
   # 証明書と鍵の読み取り権限を設定する
   sudo chmod 600 /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
   sudo chmod 644 /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
   # SELinux のラベルを復元する
   sudo restorecon -Rv /var/lib/gnome-remote-desktop
   printf '\n\033[7m 確認 \033[0m\n'
   sudo ls -lZ /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates
   ```

   - `rdp-tls.key` が `-rw-------`、`rdp-tls.crt` が `-rw-r--r--` で、どちらも所有者が `gnome-remote-desktop`、コンテキストに `gnome_remote_desktop_var_lib_t` が出ればよい

1. grdctl で、システムデーモンに鍵と証明書を設定し、RDP を有効にする。

   ```bash
   # システムの RDP に証明書と鍵を登録する
   sudo grdctl --system rdp set-tls-key  /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
   sudo grdctl --system rdp set-tls-cert /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
   # システムの RDP を有効にする
   sudo grdctl --system rdp enable
   ```

   - `sudo grdctl --system status` に表示される **TLS fingerprint を控えておく**（この項の手順 10・11 で使う）
   - TPM の無い PC の `Init TPM credentials failed … using GKeyFile as fallback.` は正常

1. GDM の後に起動するようにしてサービスを有効にし、ファイアウォールで RDP を開ける。

   ```bash
   # サービスの起動順を設定する
   sudo mkdir -p /etc/systemd/system/gnome-remote-desktop.service.d
   sudo tee /etc/systemd/system/gnome-remote-desktop.service.d/10-after-gdm.conf >/dev/null <<'CONF'
   [Unit]
   After=gdm.service
   CONF
   # サービス定義を読み直し、起動を有効にする
   sudo systemctl daemon-reload
   sudo systemctl enable --now gnome-remote-desktop.service
   # RDP の受信を許可する
   sudo firewall-cmd --permanent --add-service=rdp
   sudo firewall-cmd --reload
   ```

1. 本物の端末で、システム共通の RDP 資格情報を引数なしで対話入力する。

   ```bash
   sudo grdctl --system rdp set-credentials
   ```

   - システム共通の RDP ユーザー名とパスワードを入力する
   - **対話入力は TTY 必須**。パイプなどでは未設定のまま exit 0 になる
   - **次の手順は、ユーザー名とパスワードを入力し終えてから貼る**（続けて進むと、資格情報を設定できなかったときもデーモンを起動し直すことになる）

1. 資格情報を反映させるため、デーモンを起動し直す。

   - 再起動しないと `[RDP] Credentials are not set, denying client` で拒否され続ける（落とし穴 2: `docs/verification/gnome-remote-desktop.md` の「落とし穴 2: 資格情報の変更にはデーモンの再起動が必要」）
   - [デーモンを起動し直す](#gnome-のリモートログイン-デーモンを起動し直す)の手順 1 を行う。ヘッドレスのセッションがある PC では、続けて同じ項の手順 2 も行う
   - **次の手順は、デーモンと必要な受け渡し役の起動し直しが終わってから貼る**

1. サーバー側の状態を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # RDP 設定とサービスの状態を確認する
   sudo grdctl --system status              # Status: enabled / Username: (hidden)
   systemctl status gnome-remote-desktop    # active (running)
   # RDP の待ち受けを確認する
   ss -lntp | grep 3389                     # *:3389 で LISTEN
   # ファイアウォールの許可を確認する
   sudo firewall-cmd --list-services        # rdp が含まれる
   # 2 つの grd.conf を確認する
   sudo cat /etc/gnome-remote-desktop/grd.conf
   sudo cat /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/grd.conf   # 通常は存在しない
   ```

   - `Status: enabled`・`active (running)`・3389 の `LISTEN` と、ファイアウォールの `rdp` を確かめる
   - ユーザーデータ側の `grd.conf` が存在しない場合は正常
   - `/etc` 側とユーザーデータ側の `enabled` が食い違う場合は、デーモン稼働中に `sudo grdctl --system rdp enable` を実行し、この項の手順 8 で設定と待ち受けを確かめ直す

1. 鍵と証明書が対応しているかを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   sudo openssl x509 -in /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt -noout -modulus | openssl sha256
   sudo openssl rsa  -in /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key -noout -modulus | openssl sha256
   ```

   - 2 つのハッシュが一致すれば、ペアとして正しい

1. TLS ハンドシェイクと、提示される証明書を確かめる。

   ```bash
   # TLS 確認用のスクリプトを作成する
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
   printf '\n\033[7m 確認 \033[0m\n'
   python3 ~/rdp_tls_probe.py "${SERVER_IP}"
   ```

   - 次の 3 つがそろえばよい
     - `selectedProtocol=0x2` でネゴシエーションが成立する
     - `fingerprint` が `grdctl --system status` の TLS fingerprint と**完全一致**する
     - SAN に、接続に使う名前が `DNS:` エントリとして含まれている
   - プローブによる `nla_recv() error` などのログは正常
   - 確認が済んだら `rm ~/rdp_tls_probe.py` で消してよい

1. LAN 内の別マシンから、RDP クライアントでログインする。

   - AlmaLinux 10 の FreeRDP（`freerdp` パッケージ）なら `xfreerdp /v:<SERVER_IP>:3389 /u:<システムRDPユーザー名>` の形で接続する
   - `<SERVER_IP>` と `<システムRDPユーザー名>` は値に読み替える
   - FreeRDP は、証明書の `Thumbprint:` を出して `Do you trust the above certificate? (Y/T/N)` と聞く。この項の手順 4 で控えた `TLS fingerprint` と同じなら `Y` で受け入れる
     - 初めてつなぐときも、その前に `REMOTE HOST IDENTIFICATION HAS CHANGED!` などの警告が出る。続く `Thumbprint:` で判断する
     - `Y` で答えた後は、同じクライアントからつなぎ直しても証明書の確認は出ず、`Domain:` から聞かれる
   - FreeRDP は `Domain:` も聞く。空のまま Enter を押す
   - FreeRDP の `Password:` には、この項の手順 6 のシステム共通パスワードを入れる
     - FreeRDP は、パスワードの後に `[ERROR][com.winpr.sspi.Kerberos]` の `krb5_parse_name (Configuration file does not specify default realm …)` の行を出すことがある。GDM のログイン画面が出れば、害は無い
   - システム共通パスワードで RDP 認証を通過すると GDM のログイン画面が出るので、OS アカウントでログインする
   - 問題があれば、[つながらないときに確かめる](#gnome-のリモートログイン-つながらないときに確かめる)を通す

#### GNOME のリモートログイン: 接続元を LAN に絞る

- リモートログインの RDP（3389/tcp）を、LAN の送信元サブネットからだけ受け付けるようにする
- 前提: [GNOME のリモートログイン](#gnome-のリモートログイン)を通してある
- 実行場所: サーバーの、自分のユーザーのシェル（bash）
- **接続元を制限しないなら、この項は不要**

1. LAN に絞るなら、送信元サブネットを入れ、`rdp` サービスの開放を rich rule に置き換える。

   ```bash
   LAN_SUBNET=192.0.2.0/24              # ← 自分の値に書き換える。<LAN_SUBNET>
   ```

   ```bash
   # 接続元を指定した RDP の許可に切り替える
   if [ -z "${LAN_SUBNET}" ]; then echo '中断: LAN_SUBNET が空のまま。値を入れて貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-service=rdp
   sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=3389 protocol=tcp accept"
   sudo firewall-cmd --reload
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --list-rich-rules        # source address に実際のサブネットが入っていることを確認する
   fi
   ```

#### GNOME のリモートログイン: デーモンを起動し直す

- 資格情報や証明書を変更した後に、リモートログインのデーモンと、必要な受け渡し役のデーモンを起動し直す
- 前提: [GNOME のリモートログイン](#gnome-のリモートログイン)でサービスを有効にしてある
- 実行場所: サーバーの、自分のユーザーのシェル（bash）。この項の手順 2 は、ヘッドレスのセッションを使うユーザーのシェルで行う
- **この項の手順 1・2 は、リモートログインでつないでいる利用者がいないときに行う**

1. デーモンを起動し直す必要があるときは、止めて待ってから起動する。

   ```bash
   # デーモンを停止し、待機してから起動する
   sudo systemctl stop gnome-remote-desktop.service
   sleep 5
   sudo systemctl start gnome-remote-desktop.service
   sleep 5
   printf '\n\033[7m 確認 \033[0m\n'
   sudo journalctl --no-pager _PID="$(systemctl show -p MainPID --value gnome-remote-desktop.service)" | grep -E 'GetManagedObjects|RDP server started'
   ```

   - `RDP server started` の 1 行だけが出ればよい
   - **注意**: `systemctl restart` にしない（[GNOME のリモートログイン の補足と注意点](#gnome-のリモートログイン-の補足と注意点)の「注意点」）

1. ヘッドレスのセッションがある PC では、そのユーザーのシェルで、受け渡し役のデーモンを再起動する。

   ```bash
   # 受け渡し役を再起動し、起動を待つ
   systemctl --user restart gnome-remote-desktop-handover.service
   sleep 3
   printf '\n\033[7m 確認 \033[0m\n'
   sudo journalctl --no-pager _PID="$(systemctl --user show -p MainPID --value gnome-remote-desktop-handover.service)" | grep 'RDP server started'
   ```

   - `RDP server started` と出ればよい
   - ヘッドレスのセッションが無い PC では、この手順は飛ばす

#### GNOME のリモートログイン: つながらないときに確かめる

- 接続できないときに、TLS・提示証明書とサーバーのログを確かめる
- 前提: [GNOME のリモートログイン](#gnome-のリモートログイン)を通してある。この項の手順 1・2 はサーバーに FreeRDP があるときだけ行い、先に[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 1 の変数を設定する
- 実行場所: サーバーの、自分のユーザーのシェル（bash）。この項の手順 3・4 は別々の SSH 端末で並行して行う

1. サーバーに FreeRDP があるときだけ、ループバックで TLS を確かめる。

   ```bash
   # ループバックで、存在しないユーザーの認証だけを試す
   timeout 20 xfreerdp /v:127.0.0.1:3389 /u:__probe__ /p:__probe__ /cert:ignore /auth-only >/dev/null 2>&1
   printf '\n\033[7m 確認 \033[0m\n'
   sudo journalctl -u gnome-remote-desktop --since "-1min" --no-pager \
     | grep -E "SAM database|BIO_do_handshake"
   ```

   - `Could not find user in SAM database` なら TLS は通っている
   - `BIO_do_handshake failed` なら証明書と鍵を確かめる

1. サーバーに FreeRDP があるときだけ、提示される証明書を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   echo "n" | timeout 20 xfreerdp /v:${SERVER_IP}:3389 /u:__probe__ /p:__probe__ /auth-only 2>&1 \
     | grep -iE "Common Name|Subject:|Issuer:|Thumbprint|MISMATCH"
   ```

   - `Thumbprint` が控えた TLS fingerprint と一致し、`CERTIFICATE NAME MISMATCH` が無ければよい

1. 別の SSH 端末で、リモートログインのログを追う。

   ```bash
   journalctl -u gnome-remote-desktop -f
   ```

   - 接続を試しながらログを確かめ、終わったら Ctrl+C で止める
   - **次の手順は、別の SSH 端末を開くか、このログを止めてから貼る**

1. 別の SSH 端末で、GDM のログを追う。

   ```bash
   journalctl -u gdm -f
   ```

   - 接続を試しながらログを確かめ、終わったら Ctrl+C で止める

#### GNOME のリモートログイン: winpr-makecert で証明書を作る

- openssl の代わりに、winpr-makecert でリモートログイン用の証明書と鍵を作る
- 前提: [GNOME のリモートログイン](#gnome-のリモートログイン)の手順 1 の変数を設定し、方式 2 では `/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates` を作ってある。ホストに freerdp を入れるなら方式 1、rootless Podman を使うなら方式 2 を選ぶ
- 実行場所: サーバーの、自分のユーザーのシェル（bash）
- 既存の `rdp-tls.crt` と `rdp-tls.key` は上書きされる。残す場合は先に別の場所へ退避する
- `-n "CN=..."` は使わない。方式 2 の `--hostname`・`:Z` と、所有者を付ける `install -o`、鍵を 0600 にする処理は省かない

1. 方式 1 を選んだときだけ、ホストに freerdp を入れる。

   ```bash
   sudo dnf install -y freerdp
   ```

1. 方式 1 を選んだときだけ、証明書と鍵を作り、鍵の権限と SELinux のコンテキストを整える。

   ```bash
   # winpr-makecert で証明書と鍵を作る
   sudo -u gnome-remote-desktop mkdir -p /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates
   sudo -u gnome-remote-desktop winpr-makecert -silent -rdp -path /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates rdp-tls
   # 鍵の権限と SELinux のコンテキストを整える
   sudo chmod 600 /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
   sudo restorecon -Rv /var/lib/gnome-remote-desktop
   ```

   - この後はこの項の手順 4 へ進む

1. 方式 2 を選んだときだけ、Podman のコンテナで証明書と鍵を作り、ホストへ置く。

   ```bash
   # コンテナの中で証明書と鍵を作る
   OUT=$(mktemp -d)
   podman run --rm --hostname "${SERVER_NAME}" -v "${OUT}:/out:Z" \
     docker.io/library/almalinux:10 \
     bash -c 'dnf install -y freerdp >/dev/null 2>&1 && winpr-makecert -silent -rdp -path /out rdp-tls'
   # 所有者と権限を付けてホストへ置き、コンテキストを整える
   sudo install -o gnome-remote-desktop -g gnome-remote-desktop -m 644 "${OUT}/rdp-tls.crt" /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/
   sudo install -o gnome-remote-desktop -g gnome-remote-desktop -m 600 "${OUT}/rdp-tls.key" /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/
   sudo restorecon -Rv /var/lib/gnome-remote-desktop
   rm -rf "${OUT}"
   ```

   - この後はこの項の手順 4 へ進む

1. 証明書と鍵の権限を確かめてから、リモートログインへ設定する。

   - [GNOME のリモートログイン](#gnome-のリモートログイン)の手順 3 で権限と所有者を確かめ、同じ項の手順 4〜7 を行う

<details id="gnome-のリモートログイン-の補足と注意点">
  <summary>GNOME のリモートログイン の補足と注意点</summary>

**注意点**

- **TPM 警告**: `grdctl --system` 実行時と service 起動時に毎回 `Init TPM credentials failed ... using GKeyFile as fallback` が出るが、TPM が使えない機体での正常なフォールバック
  - 資格情報は `/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/credentials.ini` に保存される
- **設定レイヤーの食い違い**
  - システムデーモンの設定は、`/usr/share/gnome-remote-desktop/grd.conf`（既定）→ `/etc/gnome-remote-desktop/grd.conf`（`grdctl` が書く）の順に読まれる
  - ただし、`~gnome-remote-desktop/.local/share/gnome-remote-desktop/grd.conf` が作られることがある
  - `/etc` 側の `enabled=true` と、このファイルの `enabled=false` が食い違うと、サービスを再起動しても有効にならないことがある。[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 8 で設定を読み戻す
  - 食い違う場合は、デーモン稼働中にもう一度 `sudo grdctl --system rdp enable` を実行し、設定と待ち受けを確認する

- **リモートログインのセッション**: そのユーザーのセッションが無ければ、ログインで新しいセッションができる
  - ローカルでログイン中のユーザーと同一ユーザーで接続すると、GDM が既存セッションの扱い（切替 or 拒否）を求める場合がある
  - PC の物理モニターに表示しているデスクトップを見る用途は「デスクトップ共有」方式（ユーザーのデーモン）。[GNOME のデスクトップ共有](#gnome-のデスクトップ共有)で扱う。aarch64 の実機（`docs/verification/gnome-desktop-sharing.md` の「付録: このホストでの検証（2026-10-07）」）とクリーン VM（`docs/verification/gnome-desktop-sharing.md` の「付録: 公式 ISO から新規インストールした aarch64 VM での検証（2026-10-07）」）、x86_64 VM（`docs/verification/gnome-desktop-sharing.md` の「付録: VirtualBox の VM での本実行（2026-10-07）」）で確かめた範囲を参照（物理 HDMI への表示は未確認）
- **ヘッドレスのセッションを常駐させている PC**（[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)）
  - そのユーザーのセッションの中で、リモートログインの受け渡し役のデーモン（`gnome-remote-desktop-handover.service`）が起動する（TCP では待ち受けない）
  - このデーモン（`gnome-remote-desktop.service`）を再起動したら、受け渡し役のデーモンも再起動する（[GNOME のリモートログイン: デーモンを起動し直す](#gnome-のリモートログイン-デーモンを起動し直す)の手順 2）。しないと、そのユーザーでログインしたときに、ログイン画面が名前とアイコンのまま進まない
    - RHEL の `gnome-remote-desktop` 49.3-3 からの機能（パッケージの changelog の「Support remote login to sessions from gnome-headless-session@.service」）
    - クライアントには、ヘッドレスのセッションに足された仮想モニターが写る
    - 切断すると足されたモニターは消え、ヘッドレスのセッションは残った
  - ヘッドレスのセッションの RDP（[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)、3390）と同時につなぐと、後からつないだ方が残り、先の接続は切られた（どちらが先でも同じ）
  - 起動のときと同じすれ違い（[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 5 の補足）は、タイミングによっては起きるはず（コードからの推定）。真っ暗なまま切れるようになったら、[GNOME のリモートログイン: デーモンを起動し直す](#gnome-のリモートログイン-デーモンを起動し直す)の手順 1 と、ヘッドレスのセッションがある場合は[GNOME のリモートログイン: デーモンを起動し直す](#gnome-のリモートログイン-デーモンを起動し直す)の手順 2 で直す
  - ヘッドレスのセッションは、GDM と一緒に止まって起動し直される。前のセッションの片付けとぶつかって、消えることがある（[GNOME のヘッドレスセッション の補足と注意点](#gnome-のヘッドレスセッション-の補足と注意点)の「注意点」）
  - ヘッドレスのセッションをやめてリモートログインだけにするときは、[GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）](#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)
- **自己署名証明書**: クライアント側で証明書警告が出る。信頼できる CA の証明書がある場合は、[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 2〜4 でそちらのパスを指定する
- **証明書を差し替えたとき**: 自己署名証明書が変わると、クライアントは保存済みの旧証明書と照合して警告を出す
  - **クライアント側で保存された証明書の信頼を一度削除する**か、変更の警告を承認する必要がある
  - 差し替え後は、[GNOME のリモートログイン: デーモンを起動し直す](#gnome-のリモートログイン-デーモンを起動し直す)の手順 1 と、ヘッドレスのセッションがある場合は[GNOME のリモートログイン: デーモンを起動し直す](#gnome-のリモートログイン-デーモンを起動し直す)の手順 2 で反映する（接続中の RDP セッションは切断されるので、利用者がいないときに行う）
- **public ゾーンでの開放**: public ゾーンに属するすべての NIC で 3389/tcp が開く。接続元を制限しない場合はそのままでよい
  - LAN 限定に絞る手順は[GNOME のリモートログイン: 接続元を LAN に絞る](#gnome-のリモートログイン-接続元を-lan-に絞る)
- **ログイン画面のまま置くと眠ることがある**: Workstation で入れた PC のログイン画面は、電源につないでいても 15 分でサスペンドする
  - 眠ると RDP でつなげない。止めるなら [AlmaLinux 10 の初期設定の「画面オフ・画面ロック・自動サスペンドを止める」](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)

**[GNOME のリモートログイン](#gnome-のリモートログイン)のリード**

- **[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 6 には対話入力がある**（ユーザー名とパスワード）。入力し終えてから[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 7 を貼る

- [GNOME のリモートログイン](#gnome-のリモートログイン)の手順 1 で変数を設定したシェルに貼る

- RDP のクライアントに GDM のログイン画面を出し、OS のアカウントでログインできるようにする（システムのデーモンで待ち受ける）

- PC の画面を触らず、デスクトップをそのまま RDP で共有する場合は[GNOME のデスクトップ共有](#gnome-のデスクトップ共有)を通す。環境・実施範囲は検証記録（`docs/verification/gnome-desktop-sharing.md`）を参照する

- モニターの無い PC に自分のデスクトップを常駐させて RDP でつなぐなら、[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)。この項と同じ PC で併用できる（ポートは 3390）

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 1**

- **編集が必須なのは `SERVER_IP` の 1 行だけ**。残りは既定のままでよい

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 1: 変数について**

- `LAN_SUBNET` は[GNOME のリモートログイン: 接続元を LAN に絞る](#gnome-のリモートログイン-接続元を-lan-に絞る)の rich rule でしか使わないので、[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 1 ではなくその節の冒頭で設定する
- 接続元を制限しない場合は、[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 5 で public ゾーンに `rdp` サービスを開放した状態が完成形
- `SERVER_IP` が空のまま進むと、[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 2 の `openssl` が SAN の空エントリで `invalid null value` のエラーになる
- 任意の変数のブロックは、最後に値を読み戻す
- 変数はそのシェルの中だけで有効なので、新しいシェルでは[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 1 の 2 つのブロックを貼り直す

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 2: 生成するユーザー**

- 所有権を最初から正しくするため、`gnome-remote-desktop` ユーザー自身として生成する

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 4**

- TPM の無い PC では、`grdctl --system` のコマンドごとに `Init TPM credentials failed because No TPM device found, using GKeyFile as fallback.` が出る（[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 6・8 でも出る）。害は無い（この折りたたみの「注意点」）

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 4: grdctl**

- `disable` 後は `inactive`、`enable` 後は `active` になる
- このため、この時点でデーモンが起動し、**後から設定する資格情報は再起動するまで反映されない**（[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 6・7）
  - 2026-10-11 の Hyper-V の VM では、[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 4 の直後の `sudo grdctl --system status` が `Unit status: active`・`Status: enabled`・`Username: (empty)` で、[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 5 の `sudo systemctl enable --now` は何も出さなかった（`Created symlink` の行が出ず、出力は `firewall-cmd` の `success` の 2 行だけ。[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 5 の後は `enabled`）
  - ユニットの有効化も `grdctl --system rdp enable` が済ませていた、とみる（[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 4 の直後の `systemctl is-enabled` は読んでいないので、確かめてはいない。検証記録: `docs/verification/gnome-remote-desktop.md` の「付録: Hyper-V の VM で通した記録（2026-10-11）」）
- `grdctl --system` は、TPM を使えないと、コマンドごとに `Init TPM credentials failed … using GKeyFile as fallback.` を 1 行出して、資格情報を GKeyFile（この折りたたみの「注意点」の `credentials.ini`）に置く
  - vTPM の無い Hyper-V の VM（2026-10-11）では、`because No TPM device found` の形で、[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 4 に 3 行、[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 6・8 に 1 行ずつ出た。デーモンも、起動のたびに同じ行をログに出した

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 5**

- ドロップイン（`10-after-gdm.conf`）は、起動のときにこのデーモンを GDM より後に立ち上げる

- 無いと、起動のたびに、リモートログインが真っ暗な画面のまま 30 秒で切れることがある（参考資料を参照）

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 5: 起動時のログ**

この節の検証記録: `docs/verification/gnome-remote-desktop.md` の「起動時に GDM の表示を取得できなかったログ」

- ログを読むときは、今のデーモンのプロセス（MainPID）を対象にする

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 5: 設定を反映する時点**

- ドロップインの設定は次の起動から効く。既に動いているデーモンはそのまま

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 6**

- ユーザー名とパスワードを聞かれる

- **対話入力は TTY 必須**。スクリプト・パイプなど、対話用の端末が無い実行では、設定されずに exit 0 で終わる（記録: `docs/verification/gnome-remote-desktop.md` の「落とし穴 1: grdctl の対話入力は TTY 必須」）

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 6: 資格情報**

この節の検証記録: `docs/verification/gnome-remote-desktop.md` の「実施手順 / 手順 6: 補足: 資格情報」

- 引数なしで打つのは、パスワードをシェル履歴・ログに残さないため

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 8: サーバー側の状態**

- `Unit status: active` なのに `Status: disabled` で 3389 が LISTEN していない場合は、後半の補足「注意点」の**設定レイヤーの食い違い**を疑う

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 9: 鍵と証明書**

この節の検証記録: `docs/verification/gnome-remote-desktop.md` の「実施手順 / 手順 9: 補足: 鍵と証明書」

- `openssl pkey` には `-modulus` が無い。鍵側は `openssl rsa` を使う
- [AlmaLinux 10 の初期設定](almalinux-setup.md)を通した PC では、対話のシェルの PATH の先頭が Homebrew なので、パイプの右側の `openssl sha256` と、[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 10 の `python3`・スクリプトの中の `openssl` は、Homebrew のものに解決される
  - `sudo` を付けた `openssl`（この手順のパイプの左側と、[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 2 の `sudo -u gnome-remote-desktop openssl`）は、sudo の `secure_path` で OS の `/bin/openssl` になる
  - 2026-10-11 の Hyper-V の VM では、対話のシェルの `openssl` が Homebrew の 4.0.3、`python3` が 3.15.0、`sudo` の `openssl` が OS の 3.5.8 という状態で、[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 2・9・10 が通った（検証記録: `docs/verification/gnome-remote-desktop.md` の「付録: Hyper-V の VM で通した記録（2026-10-11）」）。`/usr/bin/` を付けた形は、流していない

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 10**

- サーバー側には `nla_recv() error` などのログが出るが正常（この折りたたみの「GNOME のリモートログインの手順 10: TLS プローブと、FreeRDP クライアントでの確かめ方」）

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 10: TLS プローブと、FreeRDP クライアントでの確かめ方**

この節の検証記録: `docs/verification/gnome-remote-desktop.md` の「実施手順 / 手順 10: 補足: TLS プローブと、FreeRDP クライアントでの確かめ方」

- **TLS プローブ**

RDP の TLS は接続直後ではなく X.224 のネゴシエーション後に始まるため、`openssl s_client` では確認できない。

- [GNOME のリモートログイン](#gnome-のリモートログイン)の手順 10 の `rdp_tls_probe.py` は Python 標準ライブラリだけで書いてあり、X.224 のネゴシエーションを済ませてから TLS を張り、提示された証明書の fingerprint と SAN を表示する
- サーバーに FreeRDP クライアントが無くても使え、RDP のパスワードは不要
- [GNOME のリモートログイン](#gnome-のリモートログイン)の手順 10 のブロックは、`~/rdp_tls_probe.py` を書き出して、`${SERVER_IP}` に対して実行する
- `~/rdp_tls_probe.py` は、この手順書が作る唯一の作業ファイル

確認するポイント:

- `selectedProtocol=0x2`（HYBRID = NLA）でネゴシエーションが成立する
- TLS ハンドシェイクが完了し、**fingerprint が `grdctl --system status` の TLS fingerprint と完全一致**する
- SAN に接続に使う名前が DNS エントリとして含まれている

スクリプトは TLS 確立直後に切断するため、サーバー側には次のログが出るが正常（NLA の途中でクライアントが切断しただけ）:

```
[ERROR][com.freerdp.core.nla] - [nla_server_recv_stream]: nla_recv() error: -1
[ERROR][com.freerdp.core.transport] - [transport_accept_nla]: client authentication failure
[RDP] Network or intentional disconnect, stopping session
```

- 2026-10-11 の Hyper-V の VM では、プローブを貼った秒に、この 3 行を含む 9 行が出た。ほかの 6 行は、`[kerberos_AcquireCredentialsHandleA]: krb5_init_context (Included profile directory could not be read …)` が 2 行と、`BIO_read returned a system error 104: Connection reset by peer`・`ERRCONNECT_CONNECT_TRANSPORT_FAILED`・`rdp_server_accept_nego() fail`・`STATE_RUN_FAILED` の行。待ち受けと、その後の接続には響かなかった（検証記録: `docs/verification/gnome-remote-desktop.md` の「付録: Hyper-V の VM で通した記録（2026-10-11）」）

逆に、次が出る場合はプローブの前段で失敗している:

| ログ | 意味 |
|---|---|
| `[RDP] Credentials are not set, denying client` | 資格情報が未設定／未反映。ネゴシエーション前に切断される（スクリプトは `Connection reset by peer`） |
| `BIO_do_handshake failed` | TLS 失敗（証明書・鍵の不備） |
| `[x509_utils_from_pem]: BIO_new failed` | 証明書／鍵が PEM として読めない |

**[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 11: クライアントからのログイン**

1. システム共通パスワードで RDP 認証を通過
1. GDM ログイン画面が表示される
1. `<USER>` などの OS アカウントでログイン → そのユーザーのセッションが無ければ新規作成、既存のリモートセッションやヘッドレスのセッションがあればそこへ引き渡す（この折りたたみの「注意点」）

- 別マシンには[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 1 の変数が無いので、`<SERVER_IP>` と `<システムRDPユーザー名>` は値に読み替える
- AlmaLinux 10 の `freerdp` パッケージが入れる X11 のクライアントは `xfreerdp`。`xfreerdp3` という名前のコマンドは入らない
  - 2026-10-11 の Hyper-V の VM のクライアント（`freerdp-3.10.3-12.el10_2.14`）では、`xfreerdp3` は `コマンドが見つかりませんでした` で終わり、`dnf -q provides "*/xfreerdp3"` も一致が無かった（クライアントにあったのは、`/usr/bin/xfreerdp` と `/usr/bin/wlfreerdp`。検証記録: `docs/verification/gnome-remote-desktop.md` の「付録: Hyper-V の VM で通した記録（2026-10-11）」）
- FreeRDP 3.10.3 は、保存した証明書（`~/.config/freerdp/server/<SERVER_IP>_3389.pem`）が無い初めての接続でも、`REMOTE HOST IDENTIFICATION HAS CHANGED!` の警告を出してから、証明書の確認（`Do you trust the above certificate? (Y/T/N)`）を出す。初めてでも警告が出る理由は、確かめていない
  - `Y` で答えると、証明書がこのファイルに保存され、次からは聞かれない。`T` と `N` で答えたときの動きは、確かめていない
- FreeRDP 3.10.3 は、`Password:` の後に `[ERROR][com.winpr.sspi.Kerberos] - [kerberos_AcquireCredentialsHandleA]: krb5_parse_name (Configuration file does not specify default realm [-1765328160])` を 2 行出してから、認証を通った（2026-10-11 の Hyper-V の VM。3 回とも。この行が出る理由は、確かめていない）
- FreeRDP 3.10.3 のクライアントは、ログインまでに 2 回つなぎ直された（2026-10-11 の Hyper-V の VM。3 回のログインとも。どちらも、クライアントが自動で行う）
  - RDP の認証を通ると、システムのデーモンが `[RDP] Sending server redirection` を出し、クライアント（ログは `rdp_recv_server_redirection_pdu`）は、GDM のログイン画面のセッションへつなぎ直した
  - OS のパスワードの後、クライアントのログに `rdp_recv_server_redirection_pdu` がもう 1 度出て、ユーザーのセッションのデスクトップに切り替わった（新しいセッションのときは、そのユーザーの `gnome-remote-desktop-handover.service` が起動した）
  - RDP の認証から 1 回目のつなぎ直しまで 1〜3 秒（3 回）、OS のパスワードで新しいセッションができてから 2 回目のつなぎ直しまで 6〜7 秒（2 回）だった

**[GNOME のリモートログイン: 接続元を LAN に絞る](#gnome-のリモートログイン-接続元を-lan-に絞る)のリード**

- [GNOME のリモートログイン](#gnome-のリモートログイン)の手順 5 は、public ゾーンに属するすべての NIC で 3389/tcp を開く

**[GNOME のリモートログイン: 接続元を LAN に絞る](#gnome-のリモートログイン-接続元を-lan-に絞る)の手順 1: 先頭の if と引用符**

- 先頭の `if` は、`LAN_SUBNET` が空のままブロックを貼ったときに、`rdp` サービスだけ消えて rich rule が空アドレスで入るのを防ぐ
- rich rule は**二重引用符**で囲む。単一引用符だと `${LAN_SUBNET}` が展開されず、firewalld は `$LAN_SUBNET` という文字列のままの rule を `success` で受理してしまう

**[GNOME のリモートログイン: デーモンを起動し直す](#gnome-のリモートログイン-デーモンを起動し直す)のリード**

- ヘッドレスのセッションに入った RDP の接続は、受け渡し役のデーモンが持っている

**[GNOME のリモートログイン: デーモンを起動し直す](#gnome-のリモートログイン-デーモンを起動し直す)の手順 1: 閉じるセッション**

- 真っ暗なまま残っていたリモートログインのログイン画面のセッションは、止めたときに閉じる（`loginctl list-sessions` の `gdm` の `greeter` で、SEAT が `-` のもの）

**[GNOME のリモートログイン: デーモンを起動し直す](#gnome-のリモートログイン-デーモンを起動し直す)の手順 2**

- ヘッドレスのセッションは [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション) のもの。無い PC では飛ばす

**[GNOME のリモートログイン: デーモンを起動し直す](#gnome-のリモートログイン-デーモンを起動し直す)の手順 2: 受け渡し役のデーモン**

- [GNOME のリモートログイン: デーモンを起動し直す](#gnome-のリモートログイン-デーモンを起動し直す)の手順 1 の後、受け渡し役のデーモンは引き渡し口を取り直さないまま止まる。`[DaemonHandover] Could not get session id` が出ることも、何も出ないこともある

**[GNOME のリモートログイン: つながらないときに確かめる](#gnome-のリモートログイン-つながらないときに確かめる)の手順 1: TLS の確かめ方**

- **FreeRDP クライアントがある場合の検証**

TLS の可否: **存在しないユーザー名**でループバック接続する。TLS が正常なら NLA 段階まで到達して `Could not find user in SAM database` が出る。TLS が壊れていればその手前の `BIO_do_handshake failed` で止まる。

**[GNOME のリモートログイン: つながらないときに確かめる](#gnome-のリモートログイン-つながらないときに確かめる)の手順 2: 提示証明書の確かめ方**

クライアントに届く証明書: `/cert:ignore` を付けずに実行すると、実際に提示された証明書の詳細が表示される。Thumbprint が TLS fingerprint と一致し、`CERTIFICATE NAME MISMATCH` が出ないことを確認する。

**[GNOME のリモートログイン: winpr-makecert で証明書を作る](#gnome-のリモートログイン-winpr-makecert-で証明書を作る)のリード**

証明書生成時の表示の記録: `docs/verification/gnome-remote-desktop.md` の「参考資料の証明書生成で確認した表示」

この節の検証記録: `docs/verification/gnome-remote-desktop.md` の「付録: winpr-makecert で証明書を作る場合（RHEL 10 公式手順）」

RHEL 10 のドキュメントは `freerdp` パッケージの `winpr-makecert` で証明書を作る手順を載せている。これは Red Hat のドキュメントがそのツールを採用しているだけで、GRD の要件ではない。**GNOME 本家の README は openssl による生成を正規の手順として記載しており、機能的にも openssl の方が上位**（SAN・有効期間を指定できる）。本書のメイン手順が openssl を使うのはこのため。

`winpr-makecert --help` では `-eku` や `-b`/`-e` が "Unsupported" と明記されており、SAN を付けるオプションは存在しない。

**[GNOME のリモートログイン: winpr-makecert で証明書を作る](#gnome-のリモートログイン-winpr-makecert-で証明書を作る)の手順 2: ホストで作る場合**

[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 1 の変数を設定したうえで:

以降は [GNOME のリモートログイン](#gnome-のリモートログイン)の手順 4〜7 と同じ。

**[GNOME のリモートログイン: winpr-makecert で証明書を作る](#gnome-のリモートログイン-winpr-makecert-で証明書を作る)の手順 3: コンテナで作る場合**

ホストにパッケージを入れずに winpr-makecert 製の証明書が必要な場合。[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 1 の変数を設定したうえで:

- コンテナのホスト名が CN に使われ、ホスト名を指定しなければランダム ID が CN になる
- winpr-makecert の `-n` は解析が壊れており、subject が破損する
- `:Z` は SELinux ラベルを付け替える指定
- rootless podman ではコンテナ内 root がホストの呼び出しユーザーにマップされるため、生成物は呼び出しユーザー所有になる
- winpr-makecert が出力する鍵は **0644**（コンテナ内でもホスト側でも）
- イメージ pull のダウンロードが発生する

IP で接続したときに名前不一致になるのは、SAN が無いことが原因。openssl 製の証明書では SAN を付けられる。

**選択した方針**

- **リモートログイン方式**（システムデーモン）— ローカルログイン不要。GDM で認証し、そのユーザーのセッションが無ければ新規作成する。切断後のリモートセッションや常駐するヘッドレスのセッションがあれば、そこへ引き渡す
- **TLS 証明書は openssl で生成する** — GNOME 本家の README が記載している方法
  - 追加パッケージ不要で、SAN の付与や有効期間の指定もできる
  - RHEL 10 のドキュメントは `freerdp` の `winpr-makecert` を使うが、GRD 側の要件ではない（[GNOME のリモートログイン: winpr-makecert で証明書を作る](#gnome-のリモートログイン-winpr-makecert-で証明書を作る)参照）
- ファイアウォールは **public ゾーンで 3389/tcp を開放**
- 操作権限はフル操作（リモートログイン方式に `view-only` 設定は存在せず、常にフル操作）

- **認証は 2 段構え**

1. **システム共通の RDP 資格情報**（`grdctl --system rdp set-credentials`）— GDM ログイン画面へ到達するためのゲートウェイ認証。RDP クライアントの接続時に入力する。ユーザー名は OS アカウントと一致していなくてよい
1. **各ユーザーの OS 資格情報** — GDM のログイン画面で入力する

**参照**

- [Chapter 1. Remotely accessing the desktop — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/remotely-accessing-the-desktop)
- [GNOME/gnome-remote-desktop README.md](https://github.com/GNOME/gnome-remote-desktop/blob/master/README.md)

- 検証記録（`docs/verification/gnome-remote-desktop.md`）

</details>

---
