# GNOME のデスクトップ共有の手順（PC の画面のデスクトップに、遠隔から RDP でつなぐ。PC の画面を触らずに CLI だけで設定する）のロールバックと注意点

[手順書](../gnome-desktop-sharing.md)・[検証記録](../verification/gnome-desktop-sharing.md)・[参考資料](../reference/gnome-desktop-sharing.md)

- 「手順 N」は[手順書](../gnome-desktop-sharing.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

- 手順 1 の変数を設定したシェルで、上から順に貼る（SSH から。PC の画面は使わない）
- [画面オフ・画面ロック・自動サスペンドを止める（任意）](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)で変えた値は残る。戻すなら同じ節の手順 6〜9
- この節の手順 3 は、[手順 5](../gnome-desktop-sharing.md#実施手順) で退避した元値に戻す。[ヘッドレスのセッション](../gnome-headless-session.md)の RDP を有効にしているときは、共用の TLS 設定と証明書は残す
- デスクトップ共有は無効になり、[手順 7](../gnome-desktop-sharing.md#実施手順) で入れた RDP の資格情報は消える。自動ログインもやめ、最後の手順で PC の画面のセッションを終わらせる

> [!CAUTION]
> **この節の手順 5 で消す証明書の秘密鍵は取り戻せない**。この手順書が生成し、生成したときの中身のままのものだけを消し、既存の証明書と鍵は残す。

1. ファイアウォールで開けたポートを閉じる。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: 手順 1 の RDP_PORT が空のまま。手順 1 を貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   fi
   ```

   - `success` が 2 行出て、`--list-ports` に `<RDP_PORT>/tcp` が無ければよい

1. [接続元を LAN に絞る](../gnome-desktop-sharing.md#接続元を-lan-に絞る任意)を行ったときは（この節の手順 1 の代わりに）、rich rule を消す。

   ```bash
   if [ -z "${LAN_SUBNET}" ] || [ -z "${RDP_PORT}" ]; then echo '中断: LAN_SUBNET か、手順 1 の RDP_PORT が空のまま。値を入れて貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=${RDP_PORT} protocol=tcp accept"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-rich-rules
   fi
   ```

   - `LAN_SUBNET` は、[接続元を LAN に絞る](../gnome-desktop-sharing.md#接続元を-lan-に絞る任意)の手順 1 の 1 つ目のブロックを貼り直して入れる
   - `success` が 2 行出て、その rich rule が消えていればよい

1. デスクトップ共有を止め、変えた設定を元値に戻す。

   ```bash
   (
     set -e
     trap 'echo "中断: 復元が失敗した。この節の手順 5 へ進まない" >&2' ERR
     if { [ -e ~/.local/state/gnome-desktop-sharing-setup ] || [ -L ~/.local/state/gnome-desktop-sharing-setup ]; } &&
        { [ -L ~/.local/state/gnome-desktop-sharing-setup ] ||
          [ ! -f ~/.local/state/gnome-desktop-sharing-setup/backup-complete ]; }; then
       echo '中断: 設定の退避が不完全。設定とファイルは変更しない' >&2
       exit 1
     fi
     rm -f ~/.local/state/gnome-desktop-sharing-setup/restored ~/.local/state/gnome-desktop-sharing-setup/keep-tls
     grdctl rdp disable
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
   - `grdctl rdp disable` は、ユーザーの `gnome-remote-desktop.service` を止めて無効にする。つないでいるクライアントは切れる
   - `中断:` やエラーが出たら、この節の手順 5 へ進まない

1. 自動ログインの行と起動画面の設定を戻し、手順 7 の RDP の資格情報を消す。キーリングは空になったときだけ消す。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。共有するユーザーのシェルで貼り直す' >&2
   else
     sudo sed -i "/^AutomaticLoginEnable=True$/d; /^AutomaticLogin=${USER}$/d" /etc/gdm/custom.conf
     grep -c '^AutomaticLogin' /etc/gdm/custom.conf
     sudo grubby --update-kernel=ALL --remove-args="rd.plymouth=0 plymouth.enable=0"
     sudo grubby --info=DEFAULT | grep -c 'plymouth.enable=0'
     /usr/bin/python3 - <<'PY'
   from pathlib import Path
   from gi.repository import Gio, GLib
   state = Path.home() / '.local/state/gnome-desktop-sharing-setup'
   marker = state / 'autologin-keyring'
   if state.is_symlink() or marker.is_symlink() or not marker.is_file():
       raise SystemExit('中断: この手順で作ったキーリングの記録が無いか不正。キーリングは削除しない')
   col = marker.read_text().strip()
   bus = Gio.bus_get_sync(Gio.BusType.SESSION)
   svc = '/org/freedesktop/secrets'
   def call(path, iface, method, args, rtype):
       return bus.call_sync('org.freedesktop.secrets', path, iface, method, args,
                            GLib.VariantType(rtype), Gio.DBusCallFlags.NONE, -1, None).unpack()
   def prop(path, iface, name):
       return call(path, 'org.freedesktop.DBus.Properties', 'Get', GLib.Variant('(ss)', (iface, name)), '(v)')[0]
   if col not in prop(svc, 'org.freedesktop.Secret.Service', 'Collections'):
       raise SystemExit('中断: 記録したキーリングが見つからない。記録を確認する')
   _, prompt = call(svc, 'org.freedesktop.Secret.Service', 'Unlock', GLib.Variant('(ao)', ([col],)), '(aoo)')
   if prompt != '/' or prop(col, 'org.freedesktop.Secret.Collection', 'Locked'):
       raise SystemExit('中断: 記録したキーリングを開けない。資格情報は削除しない')
   attrs = {'xdg:schema': 'org.gnome.RemoteDesktop.RdpCredentials'}
   items, = call(col, 'org.freedesktop.Secret.Collection', 'SearchItems', GLib.Variant('(a{ss})', (attrs,)), '(ao)')
   for item in items:
       prompt, = call(item, 'org.freedesktop.Secret.Item', 'Delete', None, '(o)')
       if prompt != '/':
           raise SystemExit('中断: 項目の削除が未完了。キーリングと記録は残す')
   print('手順 7 の RDP の資格情報: 削除済み')
   if prop(col, 'org.freedesktop.Secret.Collection', 'Items'):
       print('ほかの項目があるため、キーリングと記録は保持:', col)
   else:
       prompt, = call(col, 'org.freedesktop.Secret.Collection', 'Delete', None, '(o)')
       if prompt != '/':
           raise SystemExit('中断: キーリングの削除が未完了。記録は残す')
       marker.unlink()
       print('空のキーリングと記録: 削除済み')
   PY
   fi
   ```

   - `0` が 2 行と `手順 7 の RDP の資格情報: 削除済み` が出ればよい。ほかの項目が無ければ `空のキーリングと記録: 削除済み` が出る
   - ほかの項目があれば、キーリングと `autologin-keyring` の記録を保持する。RDP と関係のない項目は消さない。記録が無いか不正なときは、キーリングを削除しない
   - `空のキーリングと記録: 削除済み` が出た後に貼り直すと、`0` が 2 行の後に `中断: この手順で作ったキーリングの記録が無いか不正。…` が出る。記録はもう消してあるので、それでよい
   - 次に起動したときから、PC はログイン画面で止まる（自動ログインしない）

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
          [ ! -f ~/.local/state/gnome-desktop-sharing-setup/created.sha256 ] &&
          ! { [ -e ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] || [ -L ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] ||
              [ -e ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ] || [ -L ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ]; }; then
         echo '生成の途中で止まっていた: 消す証明書と鍵は無い'
       elif [ -f ~/.local/state/gnome-desktop-sharing-setup/created-certificate ] &&
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

1. PC の画面の自動ログインのセッションを終わらせ、ログイン画面に戻す。

   ```bash
   if [ -z "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $4 == "seat0"')" ]; then
     echo 'PC の画面にこのユーザーのセッションは無い'
   else
     loginctl terminate-session "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $4 == "seat0" {print $1}')"
     sleep 5
     loginctl list-sessions --no-legend | awk '$4 == "seat0"'
   fi
   ```

   - ログイン画面の `gdm` の行（`greeter`）だけが出ればよい
   - PC の画面のアプリで保存していないものは失われる
   - 終わらせないと、次に再起動するまで、PC の前の人がパスワード無しでこのデスクトップを使える

---

## 注意点

- **画面が暗くなるかロックされると、RDP の接続が切れる**: GNOME は、ロック画面（無操作で暗くなるときを含む）の間、画面の共有を止める
  - ロックされている間は、新しい接続もできない。SSH から[つながらなくなったとき](../gnome-desktop-sharing.md#つながらなくなったとき)の手順 1 で解く
  - 前提の[画面オフ・画面ロック・自動サスペンドを止める（任意）](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)の手順 1・2 で、画面を消さず、ロックしないようにしておく。クライアントから Super+L などでロックしても切れる
- **クライアントから「ログアウト」「電源オフ」を選ばない**: 自動ログインは起動のときにしか行われないので、ログアウトすると、再起動するまでつながらない（[つながらなくなったとき](../gnome-desktop-sharing.md#つながらなくなったとき)の手順 3）
  - 誤って選んだら、確認の窓で「キャンセル」を押す。押さないと、60 秒で自動でログアウトする
  - 電源を切ると、遠隔では入れ直せない。「再起動」なら、自動ログインで戻る
- **PC の画面に、クライアントの操作がすべて見える**: PC の前の人も同じ画面を操作できる。PC の上部バーの共有中の印から、PC の側で共有を止められる
- **写るのは PC の主モニター 1 枚で、解像度は PC のまま**: クライアントの窓の大きさには合わせない
- **同じユーザーのヘッドレスのセッションとは併用できない**: ヘッドレスのデーモンの unit が、この unit と衝突する（`Conflicts=`）
- **後からリモートログインを有効にしたとき**: リモートログインのデーモンが 3389 で待ち受ける。この手順で 3389 にしてあれば、共有のデーモンは待ち受けられなくなる（`Address already in use`）。次の順で 3390 へ移す
  - まず `RDP_PORT=3389` を貼り、[ロールバック](#ロールバック)の手順 1（[接続元を LAN に絞る](../gnome-desktop-sharing.md#接続元を-lan-に絞る任意)を行ったなら手順 2）を貼って、この手順で開けた 3389 を閉じる
  - 閉じても、リモートログインは自分で開けた `rdp` のサービスで使える。残すと、[同書の「接続元を LAN に絞る」](../gnome-remote-desktop.md#接続元を-lan-に絞る任意)が効かず、両方のロールバックの後も 3389 が開いたままになる
  - 次に、手順 1 を貼り直して `RDP_PORT` が 3390 になったのを確かめ、手順 6・10・14・15 をやり直す。手順 6 で共有のデーモンも再起動し、3390 で待ち受け直す。LAN に絞っていたなら、手順 10 の後に同節もやり直す
  - ほかのユーザーの[ヘッドレスのセッション](../gnome-headless-session.md)が 3390 を使っているなら、手順 1 の `RDP_PORT` に空いている別のポートを入れる
- **RDP のユーザー名とパスワードを変えるとき**: [手順 7](../gnome-desktop-sharing.md#実施手順) を貼り直す（上書きする）。`grdctl rdp set-credentials` は使わない（閉じたログインのキーリングに書こうとして、PC の画面に「認証が必要です」の窓を出して止まる）
  - 誤って貼ったら、Ctrl+C で止める。PC の画面の窓は残るので、RDP の画面で「キャンセル」を押して閉じる
- **設定アプリの「リモート デスクトップ」を開かない**: 自動ログインでは、ログインのキーリングがいつも閉じている。閉じているときに開くと、RDP のパスワードが乱数に書き換えられることがある（設定アプリ 47.7 の既知の不具合）
- **Homebrew が PATH の先頭にあると、`gsettings`・`python3` が Homebrew のものになる**（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）。この手順書は `/usr/bin/` を付けて呼ぶ
- **自己署名証明書**: クライアントは初回に証明書の確認を出す。証明書を作り直したら、クライアントで保存済みの証明書を消すか、変更の警告を承認する（gnome-remote-desktop.md の注意点と同じ）
