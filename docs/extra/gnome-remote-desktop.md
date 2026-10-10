# GNOME Remote Desktop 有効化手順（リモートログイン方式）のロールバックと注意点

[手順書](../gnome-remote-desktop.md)・[検証記録](../verification/gnome-remote-desktop.md)・[参考資料](../reference/gnome-remote-desktop.md)

- 「手順 N」は[手順書](../gnome-remote-desktop.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- 利用を止めるときは、この節の手順 1 と、LAN に絞っていた場合は手順 2 を行う
- 証明書だけを戻すときは、この節の手順 1・2 を飛ばし、手順 3・4 を行う

> [!WARNING]
> **この節の**手順 3 で証明書を差し替え前に戻すには、旧ファイルが要る。差し替えのときに旧ファイルを消していると、証明書は戻せない。[手順 2](../gnome-remote-desktop.md#実施手順) は同じ名前で上書きするので、残すなら先にコピーしておく。

1. サービスと RDP を止め、資格情報とファイアウォールの開放と、手順 5 のドロップインを消す。

   ```bash
   {
     sudo systemctl disable --now gnome-remote-desktop.service
     sudo grdctl --system rdp disable
     sudo grdctl --system rdp clear-credentials
     sudo firewall-cmd --permanent --remove-service=rdp && sudo firewall-cmd --reload
     sudo rm -f /etc/systemd/system/gnome-remote-desktop.service.d/10-after-gdm.conf
     sudo rmdir --ignore-fail-on-non-empty /etc/systemd/system/gnome-remote-desktop.service.d
     sudo systemctl daemon-reload
     printf '\n\033[7m 確認 \033[0m\n'
     sudo firewall-cmd --list-services
     sudo firewall-cmd --permanent --list-services
   }
   ```

   - runtime・permanent のどちらのサービス一覧にも `rdp` が無ければよい

1. [接続元を LAN に絞る](../gnome-remote-desktop.md#接続元を-lan-に絞る任意)を行ったときは、追加した rich rule も消す。

   ```bash
   if [ -z "${LAN_SUBNET}" ]; then echo '中断: LAN_SUBNET が空のまま。LAN に絞る節の変数ブロックを貼り直す' >&2; else
     sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=3389 protocol=tcp accept"
     sudo firewall-cmd --reload
     printf '\n\033[7m 確認 \033[0m\n'
     sudo firewall-cmd --list-rich-rules
     sudo firewall-cmd --permanent --list-rich-rules
   fi
   ```

   - `LAN_SUBNET` は、[接続元を LAN に絞る](../gnome-remote-desktop.md#接続元を-lan-に絞る任意)の手順 1 の変数ブロックで、設定時と同じ値を入れる
   - runtime・permanent のどちらにも、その送信元と 3389/tcp の rich rule が無ければよい

1. 証明書だけを差し替え前に戻すときは（この節の手順 1・2 の代わりに）、旧ファイル名を入れてパスを戻す。

   ```bash
   OLD_BASENAME=                        # ← 差し替え前の証明書・鍵のファイル名（拡張子なし）
   ```

   ```bash
   if [ -z "${OLD_BASENAME}" ]; then echo '中断: OLD_BASENAME を設定してから貼り直す' >&2; else
   sudo grdctl --system rdp set-tls-key  "/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/${OLD_BASENAME}.key"
   sudo grdctl --system rdp set-tls-cert "/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/${OLD_BASENAME}.crt"
   fi
   ```

   - `OLD_BASENAME` には、差し替え前の証明書・鍵のファイル名（拡張子なし）を入れる
   - `OLD_BASENAME` が空のまま貼ると、先頭の `if` で中断し、`grdctl` は実行されない

1. この節の手順 3 で証明書を戻したときは、デーモンを起動し直して反映する。

   - [設定済みのサーバーで GDM の後に起動させる](../gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる)の手順 3 と、ヘッドレスのセッションがある場合は手順 4 を行う
   - その節の手順 1・2・5 は行わない

---

## 注意点

- **TPM 警告**: `grdctl --system` 実行時と service 起動時に毎回 `Init TPM credentials failed ... using GKeyFile as fallback` が出るが、TPM が使えない機体での正常なフォールバック
  - 資格情報は `/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/credentials.ini` に保存される
- **設定レイヤーの食い違い**
  - システムデーモンの設定は、`/usr/share/gnome-remote-desktop/grd.conf`（既定）→ `/etc/gnome-remote-desktop/grd.conf`（`grdctl` が書く）の順に読まれる
  - ただし、`~gnome-remote-desktop/.local/share/gnome-remote-desktop/grd.conf` が作られることがある
  - `/etc` 側の `enabled=true` と、このファイルの `enabled=false` が食い違うと、サービスを再起動しても有効にならないことがある。次の確認方法で設定を読み戻す
  - 食い違う場合は、デーモン稼働中にもう一度 `sudo grdctl --system rdp enable` を実行し、設定と待ち受けを確認する

  確認方法:

  ```bash
  {
    printf '\n\033[7m 確認 \033[0m\n'
    sudo cat /etc/gnome-remote-desktop/grd.conf
    sudo cat /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/grd.conf   # 通常は存在しない
  }
  ```

- **リモートログインのセッション**: そのユーザーのセッションが無ければ、ログインで新しいセッションができる
  - ローカルでログイン中のユーザーと同一ユーザーで接続すると、GDM が既存セッションの扱い（切替 or 拒否）を求める場合がある
  - PC の物理モニターに表示しているデスクトップを見る用途は「デスクトップ共有」方式（ユーザーのデーモン）。本書では扱わず、[gnome-desktop-sharing.md](../gnome-desktop-sharing.md) に分けた。aarch64 の[実機](../verification/gnome-desktop-sharing.md#付録-このホストでの検証2026-10-07)と[クリーン VM](../verification/gnome-desktop-sharing.md#付録-公式-iso-から新規インストールした-aarch64-vm-での検証2026-10-07)、[x86_64 VM](../verification/gnome-desktop-sharing.md#付録-virtualbox-の-vm-での本実行2026-10-07)で確かめた範囲を参照（物理 HDMI への表示は未確認）
- **ヘッドレスのセッションを常駐させている PC**（[gnome-headless-session.md](../gnome-headless-session.md)）
  - そのユーザーのセッションの中で、リモートログインの受け渡し役のデーモン（`gnome-remote-desktop-handover.service`）が起動する（TCP では待ち受けない）
  - このデーモン（`gnome-remote-desktop.service`）を再起動したら、受け渡し役のデーモンも再起動する（[設定済みのサーバーで GDM の後に起動させる](../gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる)の手順 4）。しないと、そのユーザーでログインしたときに、ログイン画面が名前とアイコンのまま進まない
    - RHEL の `gnome-remote-desktop` 49.3-3 からの機能（パッケージの changelog の「Support remote login to sessions from gnome-headless-session@.service」）
    - クライアントには、ヘッドレスのセッションに足された仮想モニターが写る。[claude-code-gui.md](../claude-code-gui.md) のドロップインがある PC では、`Meta-0` の右に足された `Meta-1` になり、壁紙だけが写る（上部バーもウィンドウも無い）
    - 切断すると足されたモニターは消え、ヘッドレスのセッションは残った
  - ヘッドレスのセッションの RDP（gnome-headless-session.md、3390）と同時につなぐと、後からつないだ方が残り、先の接続は切られた（どちらが先でも同じ）
  - 起動のときと同じすれ違い（[手順 5](../gnome-remote-desktop.md#実施手順) の補足）は、タイミングによっては起きるはず（コードからの推定）。真っ暗なまま切れるようになったら、[設定済みのサーバーで GDM の後に起動させる](../gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる)の手順 2〜4 で直す
  - ヘッドレスのセッションは、GDM と一緒に止まって起動し直される。前のセッションの片付けとぶつかって、消えることがある（[gnome-headless-session.md の注意点](gnome-headless-session.md#注意点)）
  - ヘッドレスのセッションをやめてリモートログインだけにするときは、[gnome-headless-session.md の「リモートログインだけにする（併用をやめる）」](../gnome-headless-session.md#リモートログインだけにする併用をやめる)。claude-code-gui.md のドロップインも外し、外す前に入ったリモートログインのセッションは終わらせる
- **自己署名証明書**: クライアント側で証明書警告が出る。信頼できる CA の証明書がある場合は、手順 2〜4 でそちらのパスを指定する
- **証明書を差し替えたとき**: 自己署名証明書が変わると、クライアントは保存済みの旧証明書と照合して警告を出す
  - **クライアント側で保存された証明書の信頼を一度削除する**か、変更の警告を承認する必要がある
  - 差し替え後は、[設定済みのサーバーで GDM の後に起動させる](../gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる)の手順 3 と、ヘッドレスのセッションがある場合は手順 4 で反映する（接続中の RDP セッションは切断されるので、利用者がいないときに行う）
- **public ゾーンでの開放**: public ゾーンに属するすべての NIC で 3389/tcp が開く。接続元を制限しない場合はそのままでよい
  - LAN 限定に絞る手順は[接続元を LAN に絞る](../gnome-remote-desktop.md#接続元を-lan-に絞る任意)
- **ログイン画面のまま置くと眠ることがある**: Workstation で入れた PC のログイン画面は、電源につないでいても 15 分でサスペンドする
  - 眠ると RDP でつなげない。止めるなら [AlmaLinux 10 の初期設定の「画面オフ・画面ロック・自動サスペンドを止める（任意）」](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)
