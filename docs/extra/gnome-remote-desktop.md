# GNOME のリモートログインの注意点

[手順書](../gnome-remote.md#gnome-のリモートログイン)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-remote-desktop.md)・[参考資料](../reference/gnome-remote-desktop.md)

- 「手順 N」は[手順書](../gnome-remote.md#gnome-のリモートログイン)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

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
  - PC の物理モニターに表示しているデスクトップを見る用途は「デスクトップ共有」方式（ユーザーのデーモン）。[GNOME のデスクトップ共有](../gnome-remote.md#gnome-のデスクトップ共有)で扱う。aarch64 の[実機](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-desktop-sharing.md#付録-このホストでの検証2026-10-07)と[クリーン VM](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-desktop-sharing.md#付録-公式-iso-から新規インストールした-aarch64-vm-での検証2026-10-07)、[x86_64 VM](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/gnome-desktop-sharing.md#付録-virtualbox-の-vm-での本実行2026-10-07)で確かめた範囲を参照（物理 HDMI への表示は未確認）
- **ヘッドレスのセッションを常駐させている PC**（[GNOME のヘッドレスセッション](../gnome-remote.md#gnome-のヘッドレスセッション)）
  - そのユーザーのセッションの中で、リモートログインの受け渡し役のデーモン（`gnome-remote-desktop-handover.service`）が起動する（TCP では待ち受けない）
  - このデーモン（`gnome-remote-desktop.service`）を再起動したら、受け渡し役のデーモンも再起動する（[デーモンを起動し直す](../gnome-remote.md#gnome-のリモートログイン-デーモンを起動し直す)の手順 2）。しないと、そのユーザーでログインしたときに、ログイン画面が名前とアイコンのまま進まない
    - RHEL の `gnome-remote-desktop` 49.3-3 からの機能（パッケージの changelog の「Support remote login to sessions from gnome-headless-session@.service」）
    - クライアントには、ヘッドレスのセッションに足された仮想モニターが写る。[Claude Code の GNOME 操作: AlmaLinux 10 で使う](../ai-agents.md#claude-code-の-gnome-操作-almalinux-10-で使う) のドロップインがある PC では、`Meta-0` の右に足された `Meta-1` になり、壁紙だけが写る（上部バーもウィンドウも無い）
    - 切断すると足されたモニターは消え、ヘッドレスのセッションは残った
  - ヘッドレスのセッションの RDP（gnome-headless-session.md、3390）と同時につなぐと、後からつないだ方が残り、先の接続は切られた（どちらが先でも同じ）
  - 起動のときと同じすれ違い（[手順 5](../gnome-remote.md#gnome-のリモートログイン) の補足）は、タイミングによっては起きるはず（コードからの推定）。真っ暗なまま切れるようになったら、[デーモンを起動し直す](../gnome-remote.md#gnome-のリモートログイン-デーモンを起動し直す)の手順 1 と、ヘッドレスのセッションがある場合は手順 2 で直す
  - ヘッドレスのセッションは、GDM と一緒に止まって起動し直される。前のセッションの片付けとぶつかって、消えることがある（[GNOME のヘッドレスセッション の注意点](gnome-headless-session.md#注意点)）
  - ヘッドレスのセッションをやめてリモートログインだけにするときは、[GNOME のヘッドレスセッションの「リモートログインだけにする（併用をやめる）」](../gnome-remote.md#gnome-のヘッドレスセッション-リモートログインだけにする併用をやめる)。claude-code-gui.md のドロップインも外し、外す前に入ったリモートログインのセッションは終わらせる
- **自己署名証明書**: クライアント側で証明書警告が出る。信頼できる CA の証明書がある場合は、手順 2〜4 でそちらのパスを指定する
- **証明書を差し替えたとき**: 自己署名証明書が変わると、クライアントは保存済みの旧証明書と照合して警告を出す
  - **クライアント側で保存された証明書の信頼を一度削除する**か、変更の警告を承認する必要がある
  - 差し替え後は、[デーモンを起動し直す](../gnome-remote.md#gnome-のリモートログイン-デーモンを起動し直す)の手順 1 と、ヘッドレスのセッションがある場合は手順 2 で反映する（接続中の RDP セッションは切断されるので、利用者がいないときに行う）
- **public ゾーンでの開放**: public ゾーンに属するすべての NIC で 3389/tcp が開く。接続元を制限しない場合はそのままでよい
  - LAN 限定に絞る手順は[接続元を LAN に絞る](../gnome-remote.md#gnome-のリモートログイン-接続元を-lan-に絞る)
- **ログイン画面のまま置くと眠ることがある**: Workstation で入れた PC のログイン画面は、電源につないでいても 15 分でサスペンドする
  - 眠ると RDP でつなげない。止めるなら [AlmaLinux 10 の初期設定の「画面オフ・画面ロック・自動サスペンドを止める」](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)
