# GNOME のリモート操作のセットアップ（AlmaLinux 10）

- AlmaLinux 10 の GNOME のデスクトップに、別の PC から RDP でつなぐ。今の画面を共有する（デスクトップ共有）、モニターの無い PC に自分のデスクトップを常駐させる（ヘッドレスセッション）、GDM のログイン画面からログインする（リモートログイン）の 3 つ
- 検証記録・参考資料・ロールバックと注意点は、各項のリードから開く

> [!IMPORTANT]
> - **前提と実行場所（ユーザー・端末・別のマシン）は、各項のリードに従う**。`sudo -i`・`su -` のシェルでは行わない
> - AlmaLinux 10 の基本の設定は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)で行う

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- 3 つの項には更新の項は無い。使う GNOME の部品は、[AlmaLinux 10 のセットアップの「更新」](almalinux-setup.md#更新)の OS の更新で上がる

## AlmaLinux 10 で使う

- GNOME のデスクトップ共有・ヘッドレスセッション・リモートログイン

### GNOME のデスクトップ共有

- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-desktop-sharing.md)・[参考資料](reference/gnome-desktop-sharing.md)・[ロールバックと注意点](extra/gnome-desktop-sharing.md)

> [!IMPORTANT]
> - **PC の画面・キーボード・マウスは使わない**。共有するユーザーで SSH でログインしたシェルに貼り、画面は[再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 4 で RDP のクライアントから確かめる
> - PC の画面のセッションは、GDM の自動ログインで作る（[自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 1〜3）。PC の前でログインしておく必要は無い
> - **そのユーザー本人のシェルで貼る**。`sudo -i` / `su -` したシェルでは貼らない（設定と資格情報は、貼ったユーザーのものになるため）
> - [前提確認](#gnome-のデスクトップ共有-前提を確かめる)の手順 4 と[RDP 設定](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4 は**対話入力を終えてから次を貼る**
> - [自動ログインと再起動](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 3 で**再起動する**。OS のパスワードを入力する
> - [再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)の手順 4（クライアントからの接続）だけ別のマシンで行う
> - 同じユーザーの[ヘッドレスセッション](#gnome-のヘッドレスセッション)とは併用できない
> - [リモートログイン](#gnome-のリモートログイン)を併用済みなら、[前提確認](#gnome-のデスクトップ共有-前提を確かめる)の手順 1 でポートが 3390 になる
> - 後からリモートログインを有効にする場合は[注意点](extra/gnome-desktop-sharing.md#注意点)を参照する

- 変数のある項は、その項の手順 1 で変数を設定したシェルに貼る
- 現行版と以前の版の環境・実施範囲は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-desktop-sharing.md)を参照する

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

   - **編集が必須の変数は無い**。既定のままでよい
   - `USER` が `root` なら、ここで止めて、共有するユーザーのシェルで貼り直す
   - **新しいシェルを開いたら**、この項の手順 1 を貼り直してから先へ進む

1. 再起動の後も SSH で入り直せて、GNOME が自動で起動するかを確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl is-enabled sshd.service
     sudo firewall-cmd --permanent --query-service=ssh
     systemctl get-default
     systemctl is-enabled gdm.service
     cat /sys/class/drm/card*-*/status 2>/dev/null | grep -cx connected
     lsblk -rno TYPE | grep -cx crypt
   }
   ```

   - `enabled`・`yes`・`graphical.target`・`enabled`・`1` 以上・`0` の 6 行が出ればよい
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
     /usr/bin/gsettings get org.gnome.desktop.session idle-delay
     /usr/bin/gsettings get org.gnome.desktop.screensaver lock-enabled
     systemctl is-enabled suspend.target
     /usr/bin/gsettings get org.gnome.desktop.remote-desktop.rdp enable
     systemctl --user is-enabled gnome-remote-desktop-headless.service
     systemctl --user is-active gnome-remote-desktop-headless.service
     if systemctl --user is-enabled --quiet gnome-remote-desktop-headless.service ||
        systemctl --user is-active --quiet gnome-remote-desktop-headless.service; then
       echo '中断: ヘッドレスの unit が有効か起動中。以降は貼らず、利用状況を確認する' >&2
     fi
     ss -Hlnt "sport = :${RDP_PORT}" | wc -l
     grep -c '^AutomaticLogin' /etc/gdm/custom.conf
     busctl --user call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service SearchItems 'a{ss}' 1 xdg:schema org.gnome.RemoteDesktop.RdpCredentials
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
   - `消した: <コレクションのパス>/<N>` の形の行が出ればよい。開いたキーリングは、消した後に閉じ直す（`閉じ直した:` の行）
   - [RDP 設定](#gnome-のデスクトップ共有-rdp-を設定する)の手順 4 で作るキーリングの項目は消さない
   - 対象は `~/.local/state/gnome-desktop-sharing-setup/autologin-keyring` に記録されている。ほかに無ければ `ほかのキーリングに RDP の資格情報は無い` と出る
   - キーリングを開けないときの `中断:`（`を開けない`）では、何も消していない。パスワードが違うときは、貼り直す
   - **次の手順は、パスワードを聞かれたなら、入力し終えてから貼る**（続けて貼ると入力として食われる）

#### GNOME のデスクトップ共有: RDP を設定する

- 共有するユーザーで、RDP の証明書と鍵・ポート・資格情報を設定し、デスクトップ共有を有効にして、ファイアウォールを開ける
- 前提: [前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)を通してある
- 実行場所: 共有するユーザーで SSH でログインしたシェル（bash）

1. 変数を設定する（`SERVER_IP` は必ず値を入れる）。

   ```bash
   SERVER_IP=192.168.10.100            # ← 自分の値に書き換える。クライアントが接続に使う IP。<SERVER_IP>
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

   - **編集が必須なのは `SERVER_IP` の 1 行だけ**。残りは既定のままでよい
   - [前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 1 の `RDP_PORT` を書き換えたとき（同じ項の手順 3 の分岐）は、2 つ目のブロックの `RDP_PORT` の行も同じ値に書き換える
   - 最後に値を読み戻して確かめる
   - `USER` が `root` なら、ここで止めて、共有するユーザーのシェルで貼り直す
   - **新しいシェルを開いたら**、この項の手順 1 の 2 つのブロックを貼り直してから先へ進む

1. 変える設定の元値と共用する TLS 設定を退避し、証明書と鍵を作る（既にあれば作らない）。

   ```bash
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
   - その前に `証明書と秘密鍵の公開鍵: 一致` と出る
   - 新規生成した場合は `rdp-tls.crt`（`-rw-r--r--`）と `rdp-tls.key`（`-rw-------`）が出る
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

   - 最後の行で読み戻す。`negotiate-port false`・`port uint16 <RDP_PORT>`・`tls-cert` と `tls-key` の証明書と鍵のパス・`view-only false` が出ればよい
     - ほかに `enable` と `screen-share-mode` の行も出る（`enable` は、この項の手順 6 で有効にするまで `false`）
   - 初めて設定するときだけ、`[x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` が 1 回ずつ出る。害は無い
   - `中断:` が出たら、この項の手順 4 以降へ進まない
   - 既にデーモンが起動していれば、再起動する。接続中の RDP クライアントは切れる
   - デーモンが起動した後に貼り直すと、再起動のときに `Warning: The unit file, … of gnome-remote-desktop.service changed on disk.` が出ることがある。再起動はされ、害は無い

1. RDP のユーザー名とパスワードを、パスワードの無いキーリングに入れる。

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
   ```

   - `RDP のユーザー名:`・`RDP のパスワード:`・`RDP のパスワード（もう一度）:` を聞かれる。クライアントが接続するときに入れるもので、OS のアカウントと違ってよい
   - `入れた先: <コレクションのパス>/<N>` と `キーリングの記録: …/autologin-keyring` の形の行が出ればよい。初めてなら、コレクションのパスは `/org/freedesktop/secrets/collection/rdp` になる
   - 貼り直すと、同じキーリングの資格情報を上書きする（ユーザー名とパスワードを変えるときも、この手順を貼り直す）
   - `中断:` やエラーが出たら、次へ進まない
   - **次の手順は、ユーザー名とパスワードを入力し終えてから貼る**（続けて貼ると入力として食われる）

1. RDP の資格情報が、この項の手順 4 のキーリングにだけあることを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   busctl --user call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service SearchItems 'a{ss}' 1 xdg:schema org.gnome.RemoteDesktop.RdpCredentials
   RDP_KEYRING=$(cat ~/.local/state/gnome-desktop-sharing-setup/autologin-keyring) &&
   printf '記録したキーリング: %s\n' "${RDP_KEYRING}" &&
   busctl --user get-property org.freedesktop.secrets "${RDP_KEYRING}" org.freedesktop.Secret.Collection Locked
   ```

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

   - `success` が 2 行出て、最後に `<RDP_PORT>/tcp` を含む行が出ればよい

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
   - このユーザーで設定してあれば、`このユーザーの自動ログインは設定済み` の後に同じ 3 行が出る
   - `中断:` なら、ほかのユーザーの自動ログインなどが書いてある。`/etc/gdm/custom.conf` を確かめ、要らない行を消してから貼り直す

1. 起動画面（plymouth）を止め、自動ログインの後にログイン画面が前に出ないようにする。

   ```bash
   {
     sudo grubby --update-kernel=ALL --args="rd.plymouth=0 plymouth.enable=0"
     printf '\n\033[7m 確認 \033[0m\n'
     sudo grubby --info=DEFAULT | grep '^args='
   }
   ```

   - `args=` の行に `rd.plymouth=0 plymouth.enable=0` が入っていればよい

1. PC を再起動する。

   ```bash
   systemctl reboot -i
   ```

   - `sudo` は付けない。`==== AUTHENTICATING FOR org.freedesktop.login1.…` と出てパスワードを聞かれるので、このユーザーの OS のパスワードを入れる
   - SSH の接続が切れる。PC が起動すると、GDM がこのユーザーで自動でログインする
   - 数分待っても SSH で入れないときは、PC の前での対処が要る（[前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 2 の確認を見直す）
   - **PC が起動したら SSH で入り直し、[再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)へ進む**

#### GNOME のデスクトップ共有: 再起動の後に確かめてつなぐ

- 再起動の後に、自動でログインしたセッションと、RDP の待ち受け・証明書を確かめ、別のマシンからつなぐ
- 前提: [自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)で再起動し、PC が起動している
- 実行場所: 共有するユーザーで SSH でログインし直したシェル（bash）。この項の手順 4 は、RDP のクライアントのある別のマシンで行う

1. 変数を設定する（`SERVER_IP` は必ず値を入れる）。

   ```bash
   SERVER_IP=192.168.10.100            # ← 自分の値に書き換える。クライアントが接続に使う IP。<SERVER_IP>
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
   - 最後に値を読み戻して確かめる
   - `USER` が `root` なら、ここで止めて、共有するユーザーのシェルで貼り直す
   - **新しいシェルを開いたら**、この項の手順 1 の 2 つのブロックを貼り直してから先へ進む

1. 自動でログインしたセッションと、デーモンの待ち受けを確かめる。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: この項の手順 1 の RDP_PORT が空のまま。この項の手順 1 を貼り直す' >&2
   elif [ -z "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $4 == "seat0"')" ]; then
     echo '中断: PC の画面にこのユーザーのセッションが無い（自動ログインしていない）' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     loginctl show-session "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $4 == "seat0" {print $1}')" -p Service -p Active
     busctl --user status org.gnome.Mutter.ScreenCast >/dev/null 2>&1 && echo 'ScreenCast: ok'
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
   - `ss` が `LISTEN … *:<RDP_PORT> … users:(("gnome-remote-de",…))` の 1 行を出せばよい
   - `Active=no` なら GDM のログイン画面が出ており、RDP は真っ黒になる
   - [自動ログイン](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 2 を `sudo grubby --info=DEFAULT` で確かめ、[復旧手順](#gnome-のデスクトップ共有-つながらなくなったとき)の手順 2 で戻す
   - セッションが無いと出たら、[自動ログインにして再起動する](#gnome-のデスクトップ共有-自動ログインにして再起動する)の手順 1 の `/etc/gdm/custom.conf` を確かめる
   - `中断:` が出たら、この項の手順 3 へ進まない。`journalctl -b _SYSTEMD_USER_UNIT=gnome-remote-desktop.service` で理由を見る
     - ほかのプロセスがポートを使っていると、`Error binding to address [::]:<RDP_PORT>: Address already in use` が出ている
     - 原因を直したら、[RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 3 を貼り直し（起動中のデーモンを再起動する）、この手順を貼り直す

1. 設定を読み戻し、TLS のハンドシェイクと、提示される証明書を確かめる。

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
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/python3 ~/rdp_tls_probe.py "${SERVER_IP}" "${RDP_PORT}" &&
   grdctl status &&
   openssl x509 -in ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt -noout -fingerprint -sha1
   ```

   - プローブで、`selectedProtocol=0x2` でネゴシエーションが成立し、SAN に接続に使う名前が `DNS:` エントリとして含まれていればよい
   - `grdctl status` で `Unit status: active`・`Status: enabled`・`Port: <RDP_PORT>` を確認する
   - `View-only: no`・`Negotiate port: no`・`Username: (hidden)`・`Password: (hidden)` も確認する
   - プローブの `fingerprint:` の行が、`grdctl status` の `TLS fingerprint:` の行と**完全一致**すればよい。この値をこの項の手順 4 で使う
   - 最後の `sha1 Fingerprint=` の行は、Windows のクライアントで証明書を確かめるときに使う（この項の手順 4）
   - **注意**: `grdctl status` の `Port:` は設定した値で、実際に待ち受けたポートではない。ポートはこの項の手順 2 の `ss` で見る
   - 確認が済んだら `rm ~/rdp_tls_probe.py` で消してよい

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
   grdctl rdp enable-view-only
   printf '\n\033[7m 確認 \033[0m\n'
   grdctl status | grep 'View-only'
   ```

   - `View-only: yes` と出ればよい

1. 元に戻すときは、クライアントからの操作を受け付ける。

   ```bash
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
- [RDP を設定する](#gnome-のデスクトップ共有-rdp-を設定する)の手順 7 は、public ゾーンに属するすべての NIC で `RDP_PORT` の TCP を開く
- WireGuard などで別の拠点からつなぐなら、`LAN_SUBNET` には、PC に届くときの接続元のサブネットを入れる（この項は 1 つのサブネットだけを通す）

1. 変数を設定する。

   ```bash
   RDP_PORT=$(if [ "$(systemctl is-enabled gnome-remote-desktop.service 2>/dev/null)" = enabled ]; then echo 3390; else echo 3389; fi)   # 待ち受けるポート（自動）。<RDP_PORT>
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'RDP_PORT = %s\n' "${RDP_PORT}"
   ```

   - [前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 1 の `RDP_PORT` を書き換えたとき（同じ項の手順 3 の分岐）は、`RDP_PORT` の行も同じ値に書き換える
   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**、この項の手順 1 を貼り直してから先へ進む

1. LAN に絞るなら、送信元サブネットを入れ、ポートの開放を rich rule に置き換える。

   ```bash
   LAN_SUBNET=192.168.10.0/24           # ← 自分の値に書き換える。<LAN_SUBNET>
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

   - `success` が 3 行出て、`--list-ports` に `<RDP_PORT>/tcp` が無く、rich rule に `<LAN_SUBNET>` と `<RDP_PORT>` が入っていればよい

#### GNOME のデスクトップ共有: つながらなくなったとき

- デスクトップ共有でつながらなくなったときに、**PC の画面を触らずに、SSH から直す**
- 前提: [再起動の後に確かめてつなぐ](#gnome-のデスクトップ共有-再起動の後に確かめてつなぐ)まで通してある
- 実行場所: 共有するユーザーで SSH でログインしたシェル（bash）
- 当てはまる手順だけを貼る。どれも[前提を確かめる](#gnome-のデスクトップ共有-前提を確かめる)の手順 1 の変数は要らない
- 理由が分からないときは、`journalctl -b _SYSTEMD_USER_UNIT=gnome-remote-desktop.service` を見る

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

---

### GNOME のヘッドレスセッション

- モニターの無い PC でも、自分の GNOME のデスクトップをヘッドレスのセッションで常駐させ、RDP でつなぐ
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)と、[画面オフ・画面ロック・自動サスペンドを止める](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)の手順 1・2 を通してある。サスペンドできる PC は、同じ項の手順 3・4 も通してある
- 実行場所: セッションを使うユーザー本人のシェル（bash。SSH でよい）。この項の手順 10 は、LAN 内の別のマシンで行う
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-headless-session.md)・[参考資料](reference/gnome-headless-session.md)・[ロールバックと注意点](extra/gnome-headless-session.md)
- **この項の手順 5 は RDP のユーザー名とパスワードの対話入力がある**。入力し終えてから次の手順を貼る
- [リモートログイン](#gnome-のリモートログイン)（GDM で認証し、新しいセッションを作るか既存のセッションへ引き渡す方式）と同じ PC でも使える。そのときのポートは、この項の手順 1 で自動で 3390 になる
- この項の手順 1 で変数を設定したシェルに貼る

> [!IMPORTANT]
> - **セッションを使うユーザー本人のシェル（SSH でよい）で貼る**。`sudo -i` / `su -` したシェルでは貼らない（セッションと RDP の設定は、貼ったユーザーのものになるため）
> - この項の手順 10（クライアントからの接続）だけ別のマシンで行う

1. 変数を設定する（`SERVER_IP` は必ず値を入れる）。

   ```bash
   SERVER_IP=192.168.10.100            # ← 自分の値に書き換える。クライアントが接続に使う IP。<SERVER_IP>
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

   - **編集が必須なのは `SERVER_IP` の 1 行だけ**。残りは既定のままでよい
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

   - `gnome-headless-session@<USER>.service` の `Created symlink` が出る
   - 続いて `<SESSION_ID> <UID> <USER> - <PID> user headless no -` の形の行と、`<PID> /usr/bin/gnome-shell` が出ればよい
   - 何も出ないときは、`systemctl status "gnome-headless-session@${USER}.service"` と `systemctl --user status org.gnome.Shell@wayland.service` を見る

1. 共用する TLS 設定を退避し、証明書と鍵を作る（既にあれば作らない）。

   ```bash
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
   - 新規生成した場合は `rdp-tls.crt`（`-rw-r--r--`）と `rdp-tls.key`（`-rw-------`）が出る
   - 既存の鍵も、この手順で生成するものと同じく、パスフレーズなしで読める必要がある
   - `中断:` が出たら、この項の手順 4 以降へ進まない。[ロールバック](extra/gnome-headless-session.md#ロールバック)の手順 3・4 で戻す

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

   - TPM の無い PC の `Init TPM credentials failed because No TPM device found, using GKeyFile as fallback.` は正常
   - 初めて設定するときだけ、`[x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` が 1 回ずつ出る。害は無い

1. RDP のユーザー名とパスワードを、引数なしで対話入力する。

   ```bash
   grdctl --headless rdp set-credentials
   ```

   - ユーザー名とパスワードを聞かれる。クライアントが接続するときに入れるもので、OS のアカウントと違ってよい
   - **次の手順は、ユーザー名とパスワードを入力し終えてから貼る**（続けて貼ると入力として食われる）

1. RDP を有効にする。

   ```bash
   grdctl --headless rdp enable
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user is-enabled gnome-remote-desktop-headless.service
   ```

   - `enabled` と出ればよい
   - デーモンが待ち受けたかは、この項の手順 8 で確かめる

1. ファイアウォールで、`RDP_PORT` の TCP を開ける。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: 手順 1 の RDP_PORT が空のまま。手順 1 を貼り直す' >&2; else
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --permanent --add-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   fi
   ```

   - `success` が 2 行出て、最後に `<RDP_PORT>/tcp` を含む行が出ればよい

1. デーモンが待ち受けているかを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   grdctl --headless status
   ss -Hlnt "sport = :${RDP_PORT:?手順 1 の RDP_PORT が空のまま}"
   ```

   - `grdctl --headless status` で、`Unit status: active`・`Status: enabled`・`Port: <RDP_PORT>`・`Negotiate port: no`・`Username: (hidden)` を確かめる
   - `TLS fingerprint` の値を控えておく（この項の手順 9 と手順 10 で使う）
   - `ss` が `LISTEN … *:<RDP_PORT> …` の 1 行を出せばよい

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
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/python3 ~/rdp_tls_probe.py "${SERVER_IP}" "${RDP_PORT}"
   grdctl --headless status 2>/dev/null | grep 'TLS fingerprint'
   ```

   - 次の 3 つがそろえばよい
     - `selectedProtocol=0x2` でネゴシエーションが成立する
     - `fingerprint:` の行が、最後の `TLS fingerprint:` の行と**完全一致**する
     - SAN に、接続に使う名前が `DNS:` エントリとして含まれている
   - 確認が済んだら `rm ~/rdp_tls_probe.py` で消してよい

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

#### GNOME のヘッドレスセッション: 接続元を LAN に絞る

- ヘッドレスのセッションの RDP のポートを、LAN の送信元サブネットからだけ受け付けるようにする
- 前提: [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)を通してある
- 実行場所: セッションを使うユーザー本人のシェル（bash。SSH でよい）
- **接続元を制限しないなら、この項は不要**
- [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 7 は、public ゾーンに属するすべての NIC で `RDP_PORT` の TCP を開く

1. 変数を設定する。

   ```bash
   RDP_PORT=$(if [ "$(systemctl is-enabled gnome-remote-desktop.service 2>/dev/null)" = enabled ]; then echo 3390; else echo 3389; fi)   # 待ち受けるポート（自動）。<RDP_PORT>
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'RDP_PORT = %s\n' "${RDP_PORT}"
   ```

   - 最後に値を読み戻して確かめる
   - `RDP_PORT` が、[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 1 で設定した値と違えば、`RDP_PORT` の行をその値に書き換えて貼り直す
   - **新しいシェルを開いたら**、この項の手順 1 を貼り直してから先へ進む

1. LAN に絞るなら、送信元サブネットを入れ、ポートの開放を rich rule に置き換える。

   ```bash
   LAN_SUBNET=192.168.10.0/24           # ← 自分の値に書き換える。<LAN_SUBNET>
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

   - `success` が 3 行出て、`--list-ports` に `<RDP_PORT>/tcp` が無く、rich rule に `<LAN_SUBNET>` と `<RDP_PORT>` が入っていればよい

#### GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）

- [リモートログイン](#gnome-のリモートログイン)と[ヘッドレスのセッション](#gnome-のヘッドレスセッション)を併用している PC で、ヘッドレスのセッションをやめ、リモートログインだけにする
- 前提: [GNOME のリモートログイン](#gnome-のリモートログイン)と[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)を通して、併用している。ログインしていない間もユーザーのサービス（Syncthing など）を動かすなら、先に [ユーザーサービスの常駐](almalinux-setup.md#ユーザーサービスの常駐) を通す（linger が無いと、セッションが 1 つも無い間はユーザーの systemd が止まる）
- 実行場所: セッションを使うユーザー本人で SSH でログインしたシェル（bash）。この項の手順 6 は、クライアントの PC で行う
- リモートログインの設定（システムのデーモン・証明書・資格情報・3389/tcp）は変えない
- ヘッドレスのセッションで動いていたアプリは閉じる
- [Claude Code の GNOME 操作](ai-agents.md#claude-code-の-gnome-操作-実施手順) の仮想モニターのドロップインも外す。この PC では、Claude Code から GUI を撮って確かめられなくなる
- やめた後は、リモートログインで入ると新しいセッションができる。切断してもセッションは残り、次のログインでそこへ戻る
- [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 1 の変数は、この項の手順 2 を行うときだけ要る
- 元に戻すときは、[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 2（ヘッドレスのセッションの RDP も使うなら、同じ項の手順 3〜10）と、[Claude Code の GNOME 操作 手順 1〜3](ai-agents.md#claude-code-の-gnome-操作-実施手順)

> [!IMPORTANT]
> - **セッションを使うユーザー本人のシェルに、SSH で入って貼る**。リモートログインのセッションの中の端末では貼らない（この項の手順 5 で、そのセッションを終わらせるため）
> - この項の手順 6（クライアントからの接続）だけ、クライアントの PC で行う

1. 今の状態を確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     for s in $(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless" {print $1}'); do
       echo "${s} $(loginctl show-session "${s}" -p Service --value)"
     done
     systemctl is-enabled "gnome-headless-session@${USER}.service"
     systemctl --user is-enabled gnome-remote-desktop-headless.service
     ls ~/.config/systemd/user/org.gnome.Shell@wayland.service.d
     pgrep -a -u "${USER}" -x gnome-shell
     sudo firewall-cmd --list-ports
     sudo firewall-cmd --list-rich-rules
   }
   ```

   - `grdctl --headless status` では確かめない
   - 2 つ目の `systemctl` が `enabled`、`--list-ports` に `3390/tcp`、rich rule に `port="3390"` のどれかがあれば、ヘッドレスのセッションの RDP を設定してある。どれも無ければ、この項の手順 2 は飛ばす
   - `ls` が `virtual-monitor.conf` を出せば、Claude Code の GNOME 操作のドロップインがある。`No such file or directory` なら、この項の手順 3 は飛ばす
   - `gdm-password` の行があり、gnome-shell の行に `--virtual-monitor` が付いていれば、この項の手順 5 を行う。そうでなければ、この項の手順 5 は飛ばす

1. ヘッドレスのセッションの RDP を設定してあるときだけ、その設定を外す。

   - [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)の手順 1 の 2 つのブロックを貼ってから、[ロールバック](extra/gnome-headless-session.md#ロールバック)の手順 1（LAN に絞ったときは手順 2）・手順 3・手順 4 を順に貼る
   - ロールバックの手順 5 は貼らない（この項の手順 4 で行う）

1. Claude Code の GNOME 操作のドロップインがあるときだけ、外す。

   ```bash
   rm ~/.config/systemd/user/org.gnome.Shell@wayland.service.d/virtual-monitor.conf
   rmdir --ignore-fail-on-non-empty ~/.config/systemd/user/org.gnome.Shell@wayland.service.d
   systemctl --user daemon-reload
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user cat org.gnome.Shell@wayland.service | grep '^ExecStart'
   ```

   - `ExecStart=/usr/bin/gnome-shell` の 1 行が出ればよい
   - Claude Code の GNOME 操作の[ロールバック](extra/claude-code-gui.md#ロールバック)の手順 2 は行わない

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

   - 有効だったときは `Removed '/etc/systemd/system/graphical.target.wants/gnome-headless-session@<USER>.service'.` と出る（既に `disabled` なら何も出ない）
   - セッションで動いていたアプリも閉じる
   - 続いて `0` が出ればよい

1. ドロップインを外す前に入ったリモートログインのセッションが残っていれば、終わらせる。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。セッションを使うユーザーのシェルで貼り直す' >&2
   else
     for s in $(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless" {print $1}'); do
       [ "$(loginctl show-session "${s}" -p Service --value 2>/dev/null)" = gdm-password ] && loginctl terminate-session "${s}"
     done
     for i in $(seq 1 30); do [ -z "$(pgrep -u "${USER}" -x gnome-shell)" ] && break; sleep 1; done
     printf '\n\033[7m 確認 \033[0m\n'
     loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"' | wc -l
     pgrep -a -u "${USER}" -x gnome-shell
   fi
   ```

   - `0` が出て、gnome-shell の行が出なければよい
   - そのセッションで開いていたアプリは閉じる。つないでいたクライアントは切れる

1. クライアントの PC から、リモートログインでつなぎ直してログインする。

   - Windows なら「リモート デスクトップ接続」で `<SERVER_IP>`（3389/tcp）につなぎ、GDM のログイン画面からログインする（[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 11 と同じ）
   - 上部バーのあるデスクトップが、クライアントの窓の大きさで出ればよい
   - 切断してつなぎ直すと、同じデスクトップに戻る
   - **次の手順は、ログインし終えてから貼る**

1. サーバーで、リモートログインのセッションだけになったかを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   for s in $(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless" {print $1}'); do
     echo "${s} $(loginctl show-session "${s}" -p Service --value)"
   done
   pgrep -a -u "${USER}" -x gnome-shell
   systemctl is-enabled "gnome-headless-session@${USER}.service"
   ss -Hlnt 'sport = :3389'
   ```

   - `<SESSION_ID> gdm-password` の 1 行だけが出て、`gdm-autologin` の行が無ければよい
   - gnome-shell の行が `<PID> /usr/bin/gnome-shell`（`--virtual-monitor` の無い形）ならよい
   - 続いて `disabled` と、`LISTEN … *:3389 …` の 1 行が出ればよい

---

### GNOME のリモートログイン

- RDP のクライアントに GDM のログイン画面を出し、OS のアカウントでログインできるようにする（システムのデーモンで待ち受ける）
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)を通してある
- 実行場所: サーバーの、自分のユーザーのシェル（bash）。この項の手順 11 は、LAN 内の別のマシンで行う
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-remote-desktop.md)・[参考資料](reference/gnome-remote-desktop.md)・[ロールバックと注意点](extra/gnome-remote-desktop.md)
- **この項の手順 6 には対話入力がある**（ユーザー名とパスワード）。入力し終えてから手順 7 を貼る
- この項の手順 1 で変数を設定したシェルに貼る
- モニターの無い PC に自分のデスクトップを常駐させて RDP でつなぐなら、[GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション)。この項と同じ PC で併用できる（ポートは 3390）
- PC の画面を触らず、デスクトップをそのまま RDP で共有する場合は[デスクトップ共有](#gnome-のデスクトップ共有)を通す。現行版・以前の版の実施範囲は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-desktop-sharing.md)を参照する
  - デスクトップ共有を 3389 で使っている PC では、この項の後に、デスクトップ共有の[注意点](extra/gnome-desktop-sharing.md#注意点)の「後からリモートログインを有効にしたとき」で共有を 3390 へ移す（共有は 3389 で待ち受けられなくなる）

> [!IMPORTANT]
> - **すべてサーバー上で実行する**。この項の手順 11（クライアントからのログイン）だけ別マシン

1. 変数を設定する（`SERVER_IP` は必ず値を入れる）。

   ```bash
   SERVER_IP=192.168.10.100            # ← 自分の値に書き換える。クライアントが接続に使う IP。<SERVER_IP>
   ```

   ```bash
   SERVER_NAME=$(hostname)             # 証明書の CN と SAN に入る（自動）。<HOSTNAME>
   SERVER_FQDN=$(hostname -f)          # 同上。<HOSTNAME>.<DOMAIN>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in SERVER_IP SERVER_NAME SERVER_FQDN; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須なのは `SERVER_IP` の 1 行だけ**。残りは既定のままでよい
   - `SERVER_IP` が空、または `SERVER_NAME` / `SERVER_FQDN` が意図した名前と違うなら、ここで止めて直す
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、この項の手順 1 の 2 つのブロックを貼り直してから先へ進む

1. `gnome-remote-desktop` ユーザーとして、TLS 証明書と鍵を openssl で生成する。

   ```bash
   if [ -z "${SERVER_IP}" ] || [ -z "${SERVER_NAME}" ] || [ -z "${SERVER_FQDN}" ]; then
     echo '中断: 手順 1 の変数が空のまま。手順 1 を貼り直す' >&2
   else
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
   {
     sudo chmod 600 /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
     sudo chmod 644 /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
     sudo restorecon -Rv /var/lib/gnome-remote-desktop
     printf '\n\033[7m 確認 \033[0m\n'
     sudo ls -lZ /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates
   }
   ```

   - `rdp-tls.key` が `-rw-------`、`rdp-tls.crt` が `-rw-r--r--` で、どちらも所有者が `gnome-remote-desktop`、コンテキストに `gnome_remote_desktop_var_lib_t` が出ればよい

1. grdctl で、システムデーモンに鍵と証明書を設定し、RDP を有効にする。

   ```bash
   {
     sudo grdctl --system rdp set-tls-key  /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
     sudo grdctl --system rdp set-tls-cert /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
     sudo grdctl --system rdp enable
   }
   ```

   - `sudo grdctl --system status` に表示される **TLS fingerprint を控えておく**（この項の手順 10・11 で使う）
   - TPM の無い PC では、`grdctl --system` のコマンドごとに `Init TPM credentials failed because No TPM device found, using GKeyFile as fallback.` が出る（この項の手順 6・8 でも出る）。害は無い（[注意点](extra/gnome-remote-desktop.md#注意点)）

1. GDM の後に起動するようにしてサービスを有効にし、ファイアウォールで RDP を開ける。

   ```bash
   {
     sudo mkdir -p /etc/systemd/system/gnome-remote-desktop.service.d
     sudo tee /etc/systemd/system/gnome-remote-desktop.service.d/10-after-gdm.conf >/dev/null <<'CONF'
   [Unit]
   After=gdm.service
   CONF
     sudo systemctl daemon-reload
     sudo systemctl enable --now gnome-remote-desktop.service
     sudo firewall-cmd --permanent --add-service=rdp
     sudo firewall-cmd --reload
   }
   ```

   - ドロップイン（`10-after-gdm.conf`）は、起動のときにこのデーモンを GDM より後に立ち上げる
   - 無いと、起動のたびに、リモートログインが真っ暗な画面のまま 30 秒で切れることがある（参考資料を参照）

1. 本物の端末で、システム共通の RDP 資格情報を引数なしで対話入力する。

   ```bash
   sudo grdctl --system rdp set-credentials
   ```

   - ユーザー名とパスワードを聞かれる
   - **対話入力は TTY 必須**。スクリプト・パイプ・Claude Code の `!` では、設定されずに exit 0 で終わる（[記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-remote-desktop.md#落とし穴-1-grdctl-の対話入力は-tty-必須)）
   - **次の手順は、ユーザー名とパスワードを入力し終えてから貼る**（続けて貼ると入力として食われる）

1. 資格情報を反映させるため、デーモンを起動し直す。

   - 再起動しないと `[RDP] Credentials are not set, denying client` で拒否され続ける（[落とし穴 2](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-remote-desktop.md#落とし穴-2-資格情報の変更にはデーモンの再起動が必要)）
   - [設定済みのサーバーで GDM の後に起動させる](#gnome-のリモートログイン-設定済みのサーバーで-gdm-の後に起動させる)の手順 3 を行う。ヘッドレスのセッションがある PC では、続けて同じ項の手順 4 も行う
   - その項の手順 1・2・5 は行わない
   - **次の手順は、デーモンと必要な受け渡し役の起動し直しが終わってから貼る**

1. サーバー側の状態を確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo grdctl --system status              # Status: enabled / Username: (hidden)
     systemctl status gnome-remote-desktop    # active (running)
     ss -lntp | grep 3389                     # *:3389 で LISTEN
     sudo firewall-cmd --list-services        # rdp が含まれる
   }
   ```

1. 鍵と証明書が対応しているかを確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo openssl x509 -in /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt -noout -modulus | openssl sha256
     sudo openssl rsa  -in /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key -noout -modulus | openssl sha256
   }
   ```

   - 2 つのハッシュが一致すれば、ペアとして正しい

1. TLS ハンドシェイクと、提示される証明書を確かめる。

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
   printf '\n\033[7m 確認 \033[0m\n'
   python3 ~/rdp_tls_probe.py "${SERVER_IP}"
   ```

   - 次の 3 つがそろえばよい
     - `selectedProtocol=0x2` でネゴシエーションが成立する
     - `fingerprint` が `grdctl --system status` の TLS fingerprint と**完全一致**する
     - SAN に、接続に使う名前が `DNS:` エントリとして含まれている
   - サーバー側には `nla_recv() error` などのログが出るが正常（この手順の補足の「TLS プローブ」）
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
   - 問題があれば、サーバー側で `journalctl -u gnome-remote-desktop -f` と `journalctl -u gdm -f` を並行して見る

#### GNOME のリモートログイン: 接続元を LAN に絞る

- リモートログインの RDP（3389/tcp）を、LAN の送信元サブネットからだけ受け付けるようにする
- 前提: [GNOME のリモートログイン](#gnome-のリモートログイン)を通してある
- 実行場所: サーバーの、自分のユーザーのシェル（bash）
- **接続元を制限しないなら、この項は不要**
- [GNOME のリモートログイン](#gnome-のリモートログイン)の手順 5 は、public ゾーンに属するすべての NIC で 3389/tcp を開く

1. LAN に絞るなら、送信元サブネットを入れ、`rdp` サービスの開放を rich rule に置き換える。

   ```bash
   LAN_SUBNET=192.168.10.0/24           # ← 自分の値に書き換える。<LAN_SUBNET>
   ```

   ```bash
   if [ -z "${LAN_SUBNET}" ]; then echo '中断: LAN_SUBNET が空のまま。値を入れて貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-service=rdp
   sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=3389 protocol=tcp accept"
   sudo firewall-cmd --reload
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --list-rich-rules        # source address に実際のサブネットが入っていることを確認する
   fi
   ```

#### GNOME のリモートログイン: 設定済みのサーバーで GDM の後に起動させる

- 設定済みのサーバーで、リモートログインのデーモンを GDM の後に起動させ、起動のときに GDM とすれ違ったデーモンを起動し直す
- 前提: [GNOME のリモートログイン](#gnome-のリモートログイン)で設定してある
- 実行場所: サーバーの、自分のユーザーのシェル（bash）。この項の手順 4 は、ヘッドレスのセッションを使うユーザーのシェルで行う
- ドロップインが効くのは次の起動から。今のデーモンが起動のときに GDM とすれ違っていたら、この項の手順 3 でデーモンを起動し直すと直る（理由は[GNOME のリモートログイン](#gnome-のリモートログイン)の手順 5 の補足）
- 資格情報や証明書を変更した後も、この項の手順 3 と、ヘッドレスのセッションがある場合は手順 4 を使う。その場合、この項の手順 1・2・5 は行わない
- **この項の手順 3・4 は、リモートログインでつないでいる利用者がいないときに行う**（ヘッドレスのセッションに入った RDP の接続は、手順 4 で再起動する受け渡し役のデーモンが持っている）

1. 起動の順番を GDM の後にするドロップインを置く。

   ```bash
   {
     sudo mkdir -p /etc/systemd/system/gnome-remote-desktop.service.d
     sudo tee /etc/systemd/system/gnome-remote-desktop.service.d/10-after-gdm.conf >/dev/null <<'CONF'
   [Unit]
   After=gdm.service
   CONF
     sudo systemctl daemon-reload
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl show gnome-remote-desktop.service -p After | grep -ow 'gdm\.service'
   }
   ```

   - `gdm.service` と出ればよい

1. 今のデーモンが、起動のときに GDM とすれ違ったかを確かめる。

   ```bash
   sudo journalctl --no-pager _PID="$(systemctl show -p MainPID --value gnome-remote-desktop.service)" | grep -c 'Error calling GetManagedObjects'
   ```

   - `1` なら、すれ違っている。この項の手順 3 へ進む
   - `0` なら、起動時のすれ違いを直すためのこの項の手順 3・4 は飛ばす（資格情報や証明書を変更した後は、`0` でも行う）

1. デーモンを起動し直す必要があるときは、止めて待ってから起動する。

   ```bash
   {
     sudo systemctl stop gnome-remote-desktop.service
     sleep 5
     sudo systemctl start gnome-remote-desktop.service
     sleep 5
     printf '\n\033[7m 確認 \033[0m\n'
     sudo journalctl --no-pager _PID="$(systemctl show -p MainPID --value gnome-remote-desktop.service)" | grep -E 'GetManagedObjects|RDP server started'
   }
   ```

   - `RDP server started` の 1 行だけが出ればよい
   - **注意**: `systemctl restart` にしない（参考資料を参照）

1. ヘッドレスのセッションがある PC では、そのユーザーのシェルで、受け渡し役のデーモンを再起動する。

   ```bash
   {
     systemctl --user restart gnome-remote-desktop-handover.service
     sleep 3
     printf '\n\033[7m 確認 \033[0m\n'
     sudo journalctl --no-pager _PID="$(systemctl --user show -p MainPID --value gnome-remote-desktop-handover.service)" | grep 'RDP server started'
   }
   ```

   - `RDP server started` と出ればよい
   - ヘッドレスのセッションは [GNOME のヘッドレスセッション](#gnome-のヘッドレスセッション) のもの。無い PC では、この手順は飛ばす

1. 元に戻すときは、ドロップインを消して読み込ませる。

   ```bash
   {
     sudo rm -f /etc/systemd/system/gnome-remote-desktop.service.d/10-after-gdm.conf
     sudo rmdir --ignore-fail-on-non-empty /etc/systemd/system/gnome-remote-desktop.service.d
     sudo systemctl daemon-reload
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl show gnome-remote-desktop.service -p After | grep -cw 'gdm\.service'   # 0
   }
   ```

   - 最後に `0` と出ればよい

---
