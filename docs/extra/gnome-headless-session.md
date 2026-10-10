# GNOME のヘッドレスのセッションの手順（モニターの無い PC のデスクトップに RDP でつなぐ）のロールバックと注意点

[手順書](../gnome-headless-session.md)・[検証記録](../verification/gnome-headless-session.md)・[参考資料](../reference/gnome-headless-session.md)

- 「手順 N」は[手順書](../gnome-headless-session.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

- 手順 1 の変数を設定したシェルで、上から順に貼る
- [画面オフ・画面ロック・自動サスペンドを止める（任意）](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)で変えた値は残る。戻すなら同じ節の手順 6〜9
- [claude-code-gui.md](../claude-code-gui.md) を行ったなら、先に同書の[ロールバック](claude-code-gui.md#ロールバック)で戻す
- この節の手順 3 は共用 TLS 設定を退避時の値に戻し、手順 4 は今回生成した証明書だけを消す。退避後にデスクトップ共有（[gnome-desktop-sharing.md](../gnome-desktop-sharing.md)、設定アプリの「デスクトップ共有」）の TLS 設定を別に変えた場合は、先にその設定を控える
- 退避が無い場合は、共用 TLS 設定と証明書を保持する。導入前の値に戻すには、別に残した記録が要る

> [!CAUTION]
> **この節の手順 4 で消す証明書の秘密鍵は取り戻せない**。今回生成したものと照合できた場合だけ消し、既存の証明書と鍵は残す。

1. ファイアウォールで開けたポートを閉じる。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: 手順 1 の RDP_PORT が空のまま。手順 1 を貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   fi
   ```

   - `success` が 2 行出て、`--list-ports` に `<RDP_PORT>/tcp` が無ければよい

1. [接続元を LAN に絞る](../gnome-headless-session.md#接続元を-lan-に絞る任意)を行ったときは（この節の手順 1 の代わりに）、rich rule を消す。

   ```bash
   if [ -z "${LAN_SUBNET}" ] || [ -z "${RDP_PORT}" ]; then echo '中断: LAN_SUBNET か、手順 1 の RDP_PORT が空のまま。値を入れて貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=${RDP_PORT} protocol=tcp accept"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-rich-rules
   fi
   ```

   - `LAN_SUBNET` は、[接続元を LAN に絞る](../gnome-headless-session.md#接続元を-lan-に絞る任意)の手順 1 の 1 つ目のブロックを貼り直して入れる
   - `success` が 2 行出て、その rich rule が消えていればよい

1. RDP とヘッドレス用の資格情報・設定を解除し、共用 TLS 設定を戻す。

   ```bash
   (
     set -e
     trap 'echo "中断: 復元が失敗した。この節の手順 4 へ進まない" >&2' ERR
     if { [ -e ~/.local/state/gnome-headless-session-setup ] || [ -L ~/.local/state/gnome-headless-session-setup ]; } &&
        { [ -L ~/.local/state/gnome-headless-session-setup ] ||
          [ ! -f ~/.local/state/gnome-headless-session-setup/backup-complete ] ||
          [ ! -f ~/.local/state/gnome-headless-session-setup/tls-cert ] ||
          [ ! -f ~/.local/state/gnome-headless-session-setup/tls-key ]; }; then
       echo '中断: TLS 設定の退避が不完全。設定とファイルは変更しない' >&2
       exit 1
     fi
     rm -f ~/.local/state/gnome-headless-session-setup/restored
     grdctl --headless rdp disable
     grdctl --headless rdp clear-credentials
     dconf reset -f /org/gnome/desktop/remote-desktop/rdp/headless/
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
     systemctl --user is-enabled gnome-remote-desktop-headless.service || true
   )
   ```

   - コマンドごとの TPM のメッセージの後に、`disabled` と出ればよい
   - `中断:` やエラーが出たら、この節の手順 4 へ進まない。共用 TLS 設定が戻る前は、証明書を削除できない

1. この手順で生成した証明書と鍵、TLS 設定の退避を消す（取り戻せない）。

   ```bash
   if [ -L ~/.local/state/gnome-headless-session-setup ]; then
     echo '中断: TLS 設定の退避先がリンクになっている。ファイルは削除しない' >&2
   elif [ ! -e ~/.local/state/gnome-headless-session-setup ]; then
     echo '退避なし: 証明書と鍵は削除しない'
   elif [ ! -f ~/.local/state/gnome-headless-session-setup/restored ]; then
     echo '中断: 共用 TLS 設定を戻していない。この節の手順 3 を先に完了する' >&2
   else
     (
       set -e
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
       rm -f ~/.local/state/gnome-headless-session-setup/tls-cert ~/.local/state/gnome-headless-session-setup/tls-key \
         ~/.local/state/gnome-headless-session-setup/backup-complete ~/.local/state/gnome-headless-session-setup/ready \
         ~/.local/state/gnome-headless-session-setup/restored ~/.local/state/gnome-headless-session-setup/created-certificate \
         ~/.local/state/gnome-headless-session-setup/created.sha256
       rmdir --ignore-fail-on-non-empty ~/.local/state/gnome-headless-session-setup
       rm -f ~/rdp_tls_probe.py
     )
   fi
   ```

   - 今回生成し、生成時の中身のままの証明書だけが消える。既存の証明書・`.old`・ほかのファイルは残る
   - `中断:` のときは、生成途中のファイルや後から差し替えたものを手で確認する。照合できないものは自動削除しない
   - `credentials.ini` 自体も残す。ヘッドレス用の資格情報は、この節の手順 3 の `clear-credentials` で解除済み
   - 退避の無い既存導入では何も削除しない。`~/rdp_tls_probe.py` が要らなければ手で消す

1. ヘッドレスのセッションを止めて起動時に作らないようにし、終わったかを確かめる。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。セッションを使うユーザーのシェルで貼り直す' >&2
   else
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

   - `Removed '/etc/systemd/system/graphical.target.wants/gnome-headless-session@<USER>.service'.` と出る
   - セッションで動いていたアプリも閉じる
   - 続いて `0` が出ればよい（このユーザーのヘッドレスのセッション〔`Service=gdm-autologin`〕だけを数え、リモートログインのセッションは数えない。[検証記録](../verification/gnome-headless-session.md)・[参考資料](../reference/gnome-headless-session.md)）
   - `for` の行で、セッションが終わるまで、30 秒まで待つ

---

## 注意点

- **Homebrew が PATH の先頭にあると、`gsettings`・`gdbus`・`gio`・`python3` が Homebrew のものになる**（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）。前提の[画面オフ・画面ロック・自動サスペンドを止める（任意）](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)の手順は `/usr/bin/gsettings` で書いてある（Homebrew の `gsettings` は GNOME に効かない）
- **同じユーザーの GNOME のセッションは 1 つにする**: PC の画面から同じユーザーで入るときは、先に `sudo systemctl stop gnome-headless-session@<USER>.service` でヘッドレスのセッションを止める
  - gnome-session のユーザーの unit（`gnome-session-manager@gnome.service` など）はユーザーに 1 組しか無いので、2 つ目のセッションは動かないはず
  - このセッションにつなげるのは 1 つだけ。3390 とリモートログインから同時につなぐと、後からつないだ方が残り、先の接続は切られた（どちらが先でも同じ）
  - PC の画面のセッションを共有する[デスクトップ共有](../gnome-desktop-sharing.md)とは、同じユーザーでは併用できない（ヘッドレスの RDP のデーモンの unit に `Conflicts=gnome-remote-desktop.service` がある）
- **リモートログインのセッションも、`loginctl list-sessions` の `TTY` の列は `headless` になる**: ヘッドレスのセッションと見分けるときは、`loginctl show-session` の `Service` が `gdm-autologin`（ヘッドレス）か `gdm-password`（リモートログイン）かで見る
  - [手順 2](../gnome-headless-session.md#実施手順) の確かめの行は `TTY` の列だけで見るので、同じユーザーのリモートログインのセッションがあると、ヘッドレスのセッションができる前に抜けるはず（確かめていない）
- **起動し直すときは `stop` → 待つ → `start` を使う**。前のセッションの片付けを待ってから新しいセッションを始める
- **GDM を再起動すると、このセッションも止まって起動し直される**（`Requires=gdm.service`）
  - GDM を再起動したら `systemctl is-active gnome-headless-session@<USER>.service` を見て、`inactive` なら `sudo systemctl start gnome-headless-session@<USER>.service` で起動する
- **セッションを止めると、ユーザーの D-Bus が起動し直される**: GNOME のセッションが終わると、`gnome-session-restart-dbus.service` がユーザーのセッションバスを起動し直す
- **ログインのキーリングは開いていない**: パスワード無しで作るセッションなので、キーリング（`login`）はロックされたまま。パスワードを読もうとするアプリは、キーリングを開く窓を出す
- **サスペンドとロック**: ヘッドレスのセッションでも gsd-power は動き、既定では 15 分の無操作で PC をサスペンドしようとする。前提の[画面オフ・画面ロック・自動サスペンドを止める（任意）](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)の手順 1・2 で止める
  - seat0 には GDM のログイン画面が残り、Workstation で入れた PC ではそれも 15 分で PC を眠らせる。サスペンドできる PC では、[画面オフ・画面ロック・自動サスペンドを止める（任意）](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)の手順 3・4 も行う
- **リモートログインを有効にしている PC**: セッションの中で `gnome-remote-desktop-handover.service` も起動する（リモートログインの受け渡し役。TCP では待ち受けない）
  - リモートログインのデーモン（`gnome-remote-desktop.service`）を起動し直したら、この受け渡し役のデーモンも再起動する（[gnome-remote-desktop.md の「設定済みのサーバーで GDM の後に起動させる」](../gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる)の手順 4）。しないと、リモートログインからこのセッションへ渡せなくなるはず
- **自己署名証明書**: クライアントは初回に証明書の確認を出す。証明書を作り直したら、クライアントで保存済みの証明書を消すか、変更の警告を承認する（gnome-remote-desktop.md の注意点と同じ）
- **資源**: セッションを起動すると、`free` の `available` が約 600 MB 減った（Raspberry Pi 5、アプリを開いていないとき）
