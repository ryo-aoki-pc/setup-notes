# Forgejo 構築手順の検証記録

[手順書](../almalinux-setup.md#forgejo-実施手順)・[ロールバック](../extra/forgejo.md)・[参考資料](../reference/forgejo.md)

## 対象と検証環境

- **Hyper-V の VM での検証状態（2026-10-11 UTC）**: Hyper-V の VM（AlmaLinux 10.2 / x86_64 / SELinux Enforcing。Kickstart で入れた Workstation のクローンに、[初期設定](../almalinux-setup.md)・[linger](https://github.com/ryo-aoki-pc/setup-notes/blob/114c2b2bfd14b51f9e1925b150cbf72e1954f311/docs/linger.md)・[Podman](https://github.com/ryo-aoki-pc/setup-notes/blob/114c2b2bfd14b51f9e1925b150cbf72e1954f311/docs/podman.md) を通した後の状態）で、`114c2b2` の実施手順（6 項・26 手順）→ 使い方の基本（13 手順）→ バックアップ（4 手順）→ バックアップから復元する（7 手順）を、公式 16.0.5-rootless で上から通した。別の PC の役は、同じ仮想スイッチの別の VM。詳細は末尾の [Hyper-V の VM の付録](#付録-hyper-v-の-vm-で通した記録2026-10-11)
  - 結果: 50 手順のうち、通した 47、通らなかった 0、条件に当たらず飛ばした 3（「使い方の基本」の手順 2・3、「バックアップから復元する」の手順 7）、未実施 0
  - 通し方: サーバーのブロックは、SSH の対話の bash に貼った。ブラウザで行う操作は、人の手ではなく、クライアントの VM のヘッドレスの Firefox をスクリプトで操作した
  - 手順書の書く形と違えた所: サーバーの IPv4 は固定していない（仮想スイッチの DHCP）。「バックアップ」の手順 4 は、クライアントの VM への `scp` で代えた（同じ PC の上なので、サーバーのディスクを失っても残る保管先ではない）。許可外の送信元には、VM を動かしている Windows の PC を使った
  - 確認したこと: 最新の安定版の判定と取得（16.0.5）、SELinux Enforcing のままの `:Z`（サーバーの VM の監査ログに、拒否は 0 件。通しの後に、ログのファイルを数え直した。クライアントの VM は確かめていない）、実際の firewalld の runtime と permanent の 2 規則、SSH トンネルからの初期設定と管理者の作成、指定 IPv4 への切り替え、許可した CIDR の中の VM からの Web と Git（公開鍵の登録・指紋の照合・clone・push）、許可外の送信元から 3000 と 2222 へつながらないこと
  - 確認したこと: サービスの再起動、サーバーのユーザーの全ログアウト（23 秒）、**ゲストの OS の再起動**の後の自動起動（サービスの起動は、最初のログインの 1 秒前）と、データ・Git 用 SSH のホスト鍵・2 規則の保持。自動更新のタイマーの有効化と、最新版での `Result=success`・`ExecMainStatus=0`
  - 確認したこと: 「使い方の基本」の Issue → 作業ブランチ → Pull Request → マージ → main の更新。停止バックアップと、同じ版（16.0.5）の復元（バックアップの後に足したコミットが無くなり、復元の後もログインと push が使え、指紋は同じ）
  - 直した所: 7 つの指摘のうち、4 つを直した（どれも箇条書きの文言だけで、コードブロックは変えていない）。「初期設定と管理者の作成」の手順 2、「LAN に公開する」の手順 3、「使い方の基本」の手順 10、「バックアップから復元する」の手順 6
  - **確認していないこと**: 人の手でのブラウザの操作と窓のあるブラウザ、Windows のクライアント、固定の IPv4 と IP が変わったときの動き、VPN、別のディスクや別の PC への保管、「更新」の節、自動更新が版を上げる側と戻す側、異なる版の復元と「バックアップから復元する」の手順 7、ロールバック、`中断:` の分岐、`LAN_SUBNET='0.0.0.0/0'`、実機

- **実機での検証状態（2026-10-11 JST）**: Raspberry Pi 5 の AlmaLinux 10.2 / aarch64 に公式 16.0.5-rootless を構築し、ホスト側の導入・公開・サービス再起動・停止バックアップ・隔離コピーの復元・最新版での自動更新の確認を通した。詳細は末尾の実機検証の付録
  - 確認したこと: rootless Podman と Quadlet、コンテナ UID / GID 1000、SELinux Enforcing の専用データ保存、実 firewalld の runtime / permanent 規則、指定 IPv4 の Web と Git 用 SSH 待ち受け
  - 確認したこと: 利用者が管理者作成とログインを完了。ホスト側では初期画面の閉鎖・通常登録と OpenID 入口の拒否・匿名閲覧の制限・有効な管理者・ヘルスチェックを確認した。秘密入り INI は直接読んでいない
  - 確認したこと: サービス再起動後の管理者と SSH ホスト鍵の保持。停止バックアップの隔離コピーで管理者・Web・SSH 指紋・doctor の診断が通り、本番は再開した
  - 確認したこと: 自動更新タイマーの有効化と、最新版での `Result=success`・`ExecMainStatus=0`・コンテナ ID の不変。実機で版を上げた検証ではない
  - 利用者が確認したこと: LAN と VPN の両方で Web と Git の clone / commit / push / fetch が使えた。エージェントによる別端末の直接操作ではなく、利用者の報告として記録する
  - 追加で確認したこと: Git 試験後のリポジトリ 1 個・参照 1 本がサービス再起動後と再取得したバックアップの隔離コピーで一致し、復元側の `git fsck --full` が成功した。復元側へのログインと Git の通信は未検証
  - **今回実施しないこと**: ホスト OS の再起動と全ログアウト後の稼働。送信元 `0.0.0.0/0` の構成のため、許可外送信元の拒否試験も対象外

- **最新版の自動判定と自動更新の検証状態（2026-10-10 UTC）**: 「イメージを取得して localhost で起動する」の手順 2・3 の最新版の自動判定と、「自動更新を有効にする」の手順 1〜3 の自動更新を、AlmaLinux 10.2 の systemd コンテナで通した。詳細は末尾の 2026-10-10 の付録
  - 通したもの: 「イメージを取得して localhost で起動する」の手順 1〜5、「初期設定と管理者の作成」の手順 2・3、「LAN に公開する」の手順 1・2（「初期設定と管理者の作成」の手順 2 は実ブラウザ。「初期設定と管理者の作成」の手順 1 のトンネルは、外側とネットワークを共有する検証環境なので使わなかった。「LAN に公開する」の手順 1 はスタブ）、「自動更新を有効にする」の手順 1〜3、タイマーの発火による 15.0.9 → 16.0.5 の自動更新、復元の手順 1〜5・7、更新の節の手順 1・2・4、ロールバックの手順 2〜4、保持したデータの削除の節の手順 1・2。バックアップの節の手順 1 は、自動更新の実行中に止まることだけを確かめた
  - 確認したこと: 最新版 16.0.5 の判定と取得、メジャー版の自動更新（DB の移行を含む）と、データ・SSH のホスト鍵・ログインの保持
  - 確認したこと: 確認の失敗で前の版とデータへ自動で戻すことと、その版の保留。Forgejo が止まっているとき・保留中・最新版を調べられないときに何も変えないこと
  - 確認したこと: 自動更新の実行中の 3 か所のガードとロック。コンテナの再起動後に、タイマーがログイン前から有効で、起動直後には動かないこと
  - 確認したこと: 「自動更新を有効にする」の手順 1 の大きなブロックを、ブラケットペーストの有りと無しで実際の端末に貼り、同じバイト列のプログラムが置かれること
  - **確認していないこと**: 新しい版（17.x など）が実際に出たときの更新、本物の壊れたリリースでの失敗（doctor だけを失敗させる包みで代えた）、4 時台の発火そのもの（試験用のドロップインで時刻を変えた）
  - **確認していないこと**: 「LAN に公開する」の手順 3 から「再起動しても残ることを確かめる」の手順 7 までの再実行（「Git の接続を確かめる」の手順 1・4 の代わりに、公開鍵・リポジトリ・Issue・PR を API で作り、clone・push は SSH で行った）、OS の再起動後の Forgejo の自動起動（コンテナの再起動では、検証環境の TUN の権限を直してから起動した）
    - これは 2026-10-10 の時点の状態。「LAN に公開する」の手順 3 から「再起動しても残ることを確かめる」の手順 7 までと、OS の再起動の後の自動起動は、2026-10-11 に Hyper-V の VM で通した（上の Hyper-V の VM の行）
  - **確認していないこと**: SELinux Enforcing の `:Z`、firewalld（スタブ）と許可外の接続拒否、実際の LAN・VPN、実機・VM、aarch64
    - これは 2026-10-10 の時点の状態。SELinux Enforcing の `:Z`、実際の firewalld と許可外の送信元からつながらないこと、VM は、2026-10-11 に Hyper-V の VM で通した（上の Hyper-V の VM の行。実機の分は、上の実機の行）。実際の LAN（別々の機器のあいだ）と VPN は、Hyper-V の VM では通していない（クライアントは、同じ仮想スイッチの VM）

- **16.0.5 の検証状態（2026-10-09 UTC）**: 通常系列の最新安定版として公式の `16.0.5-rootless` を新規導入した。以下の 2 つの専用環境で確認し、詳細は末尾の 16.0.5 の付録へ記録した
  - AlmaLinux 10.2 の systemd コンテナ: 一般ユーザーの rootless Podman による公式イメージ取得・Quadlet の生成と起動、実ブラウザでの初期管理者作成・ログイン、SQLite と設定の保存先、自己登録・OpenID・匿名閲覧の制限を確認した
  - 同じ AlmaLinux の環境: サービスの stop / start 後に、設定・SSH ホスト公開鍵・登録済みの公開鍵・プライベートなリポジトリ・管理者ログインが保持された。OS 再起動の確認ではない
  - 別の Docker コンテナ: 英語 UI のログイン・SSH 公開鍵・プライベートなリポジトリ・Issue・Pull Request・差分・マージ、SSH の clone・作業ブランチ・commit / push・main の pull・Issue の自動クローズを確認し、英語画面 8 枚を保存した
  - 現行の Bash 35 ブロックと埋め込み Python 5 本は構文検査済み
  - **確認していないこと**: 16.0.5 の構築手順全体の通し実行、バックアップ・復元・更新・doctor、ログアウト後や OS 再起動後の稼働、旧版からの DB の移行・旧版への復旧。15.0.9 の成功結果を今回の結果へ広げない
    - これは 2026-10-09 の時点の状態。16.0.5 の実施手順の通し、バックアップと同じ版の復元、ログアウトの後と OS の再起動の後の稼働は、2026-10-11 に Hyper-V の VM で通した（上の Hyper-V の VM の行）。更新・doctor・旧版からの DB の移行・旧版への復旧は、Hyper-V の VM でも通していない
  - **確認していないこと**: SELinux Enforcing の `:Z`、firewalld の runtime 規則と許可外の接続拒否、実際の LAN・VPN、実機・VM、aarch64、ホスト UID が 1000 以外の構成、別サーバーへの移設。複数ユーザーのレビュー・必須承認・CI・競合解消・Windows の Git Bash での利用操作も未確認
    - これは 2026-10-09 の時点の状態。SELinux Enforcing の `:Z`、firewalld の runtime の規則と許可外の送信元からつながらないこと、VM は、2026-10-11 に Hyper-V の VM で通した（上の Hyper-V の VM の行。実機の分は、上の実機の行）。実際の LAN（別々の機器のあいだ。クライアントは、同じ仮想スイッチの VM）、VPN、ホスト UID が 1000 以外の構成、別サーバーへの移設、複数ユーザーのレビュー・必須承認・CI・競合解消、Windows の Git Bash は、Hyper-V の VM でも通していない

- **15.0.9 の検証状態（2026-10-09 UTC）**: AlmaLinux 10.2 の systemd コンテナで検証した。実機・VM での本実行ではない
  - 通したもの: 一般ユーザーの rootless Podman、公式イメージの取得と Quadlet の起動、SSH トンネルからのブラウザ初期設定、指定 IPv4 への切り替え、Git の SSH 認証・clone・push、サービス再起動、停止バックアップ・復元、同じ版の再適用、撤去、専用データの削除
  - 確認したこと: 管理者のログイン、SQLite、自己登録と OpenID の無効化、匿名閲覧の制限、プライベートなリポジトリ、SSH 鍵とデータの保持、ログアウト後の稼働、検証コンテナ再起動後の最初の SSH ログイン前の自動起動
  - 確認したこと: 復元でバックアップ時点のコミットへ戻り、その後に追加したファイルが消え、復元後もログインと push が使えること。同じ 15.0.9 を再適用する更新手順と `doctor check --all` の 28 項目
  - 確認したこと: Bash 31 ブロックと埋め込み Python 5 本の構文、Quadlet の生成、既存構成・空の復元先・空の更新版・全 IPv4 の許可を弾くガード、firewalld の保存済み規則の追加・削除と構文
  - **確認していないこと**: SELinux Enforcing での `:Z`、firewalld の runtime 規則と許可外の接続拒否、実際の LAN・VPN の経路、実機・VM の OS 再起動、aarch64、ホスト UID が 1000 以外の構成
  - **確認していないこと**: 異なる版への更新・DB の移行・移行後の旧版への復旧、別サーバーへの移設、外部の保管先へのコピー。本書の更新確認は同じ版の再適用で、版を上げた検証ではない

- **15.0.9 の利用操作の追加確認（2026-10-09 UTC）**: 別の専用 Docker コンテナで、公式の 15.0.9-rootless の日本語 UI を検証した
  - 確認したこと: サインイン、SSH 公開鍵の登録、プライベートなリポジトリの作成、SSH の clone・作業ブランチ・commit / push、Issue、Pull Request の作成・差分・マージ、main の pull、Issue の自動クローズ。画面 8 枚を保存した
  - **確認していないこと**: 複数ユーザーでのレビュー・必須承認、CI の実行、競合の解消、Windows の Git Bash での操作。今回の結果で、構築とネットワーク制限の検証範囲を広げない

- **15.0.9 の英語 UI の再確認（2026-10-09 UTC）**: 別の専用 Docker コンテナで同じ利用フローを通し、ガイド用の英語画面 8 枚を撮影した
  - 確認したこと: 英語 UI のログイン・SSH 公開鍵・リポジトリ・Issue・Pull Request・差分・マージ、Git の clone・作業ブランチ・commit / push・main の pull、Issue の自動クローズ
  - PR 本文に変更の目的・確認結果と `Closes #1` を記載した。UI 言語の切り替えで、構築やネットワーク制限の検証範囲を広げない

### 15.0.9 の構築検証環境

| 項目 | 値 |
|---|---|
| 実施日 | 2026-10-09 UTC |
| サーバー | `almalinux/10-init:latest`、AlmaLinux 10.2 (Lavender Lion)、x86_64 |
| 外側の Docker | 28.4.0、ストレージ vfs。専用コンテナを `--privileged`・`--cgroupns=private` で起動 |
| systemd / cgroup | systemd が PID 1、cgroup v2、cpuset・cpu・io・memory・hugetlb・pids がある |
| Podman | 5.8.2-9.el10_2.alma.1、rootless、検証専用の vfs、netavark、pasta |
| Forgejo | 15.0.9、公式の `codeberg.org/forgejo/forgejo:15.0.9-rootless` |
| DB とデータ | SQLite、`/var/lib/gitea/data/forgejo.db`。ホームの専用ディレクトリを `/var/lib/gitea` へ bind mount |
| 実行ユーザー | ホスト・コンテナとも UID / GID 1000。`keep-id:uid=1000,gid=1000`、linger 有効 |
| firewalld | 2.4.3-4.el10_2。カーネル側の nftables 機能不足で起動できず、offline の保存と構文だけ確認 |
| SELinux | Podman の `selinuxEnabled=false`。Enforcing の確認には使えない環境 |
| Git | サーバーは 2.52.0-1.el10、外側のクライアントから SSH で操作 |
| ブラウザ | Chromium 151.0.7922.173、Playwright 1.62.0。外側のクライアントで実ブラウザを操作 |

- サーバーイメージの digest: `sha256:c8a5eee8dbb215f6cb9103bc8686ab02f7eb5f495d32333220147b2a899d28e1`
- Forgejo イメージの取得時 digest: `sha256:caf1bca332f95cdcf124227a4bfa3b49bbbfbbc8a5e4a97406921cb581165413`

> [!NOTE]
> 出力・接続先は `<USER>`・`<SERVER_IP>`・`<LAN_SUBNET>`・`<FORGEJO_USER>`・`<FINGERPRINT>`・`<BACKUP>` などで表す。テスト用のパスワード・秘密鍵・設定内の秘密は記録していない。

### 実施前の状態

- 新しい検証コンテナと一般ユーザーを作り、Podman・OpenSSH・sudo・firewalld・Git を入れた
- 自分のユーザーで SSH にログインし、linger とユーザーの systemd が動くことを確認した
- Forgejo の Quadlet・専用データ・アカウントは無かった
- ネットワークの proxy と CA は検証環境にだけ設定した。手順書の構築先へ同じ設定を追加するものではない

### 完了時点の状態

- Web と Git、復元、同版の再適用、ログアウト後と再起動後の稼働を確認した
- ロールバックでサービスと Quadlet を撤去し、2 ポートの待ち受けが無くなった
- 専用データの任意削除も通した。バックアップと復元前の退避は、その操作では残った
- offline で追加した 2 規則も外し、設定の構文確認を通した。runtime の追加・削除は未実施
- 検証終了後に専用コンテナを撤去した。実機やほかのサービスを変更していない

## 付録: コンテナでの導入と運用の検証（2026-10-09）

### 検証環境にだけ加えた調整

- 入れ子の overlay ストレージでは `overlay is not supported over overlayfs` になった。新しい検証ユーザーの保管場所だけを作り直し、vfs にした。製品の手順に vfs の設定は追加していない
- 最初の起動では `/dev/net/tun` が無く、pasta が起動できなかった。検証コンテナ内に TUN デバイスを作成した
- 最初のコンテナ再起動でも TUN デバイスが失われた。検証環境にだけ起動前のデバイス作成を設定し、もう一度再起動して自動起動を確認した
- firewalld は `python-nftables` が `Could not process rule: No such file or directory` を返して終了した。SELinux と firewall の制限をこの環境の成功範囲へ含めていない
- イメージの最初の取得は外側の Docker で行い、save / load で Podman に渡した。その後、検証ユーザーから公式レジストリへの `podman pull` も成功した
- ブラウザではホームのポーリングが続くため、テスト側の `networkidle` 待機だけが timeout になった。画面を確認する待機へ変えて続行した。製品の手順を変更する理由にはしていない

### 実施手順 / イメージを取得して localhost で起動する / 手順 2〜5、初期設定と管理者の作成 / 手順 1〜3: イメージ・初期設定・ロック

| 確認 | 結果 |
|---|---|
| 一般ユーザーでの起動 | rootless=true、コンテナ内 UID / GID 1000。自分が所有する 0700 のデータディレクトリへ書き込めた |
| Quadlet | dry-run 成功、サービスは `active`・`generated` |
| 初期の待ち受け | Web 3000 と Git 用 SSH 2222 は `127.0.0.1` に限定 |
| 初期ページ | `/` は HTTP 200、`/install` は 404。本文の確認先を `/` に修正 |
| 初期設定 | SSH トンネルから実ブラウザで SQLite と管理者を設定した |
| 保存先 | `custom/conf/app.ini`、SQLite は `data/forgejo.db`、リポジトリは `git/repositories`、ログは `data/log` |
| 設定の確認 | `security.INSTALL_LOCK=true`、`service.DISABLE_REGISTRATION=true`、ユーザー一覧の管理者列が true |
| 管理者の認証 | 初期設定後とは別のブラウザセッションでパスワードログイン成功 |

- `app.ini` にはセクションより前に root のキーがある。確認用の読み取りでは `[DEFAULT]` を補い、設定全体を表示しない形にした
- 起動直後は HTTP が connection reset を返すこともあった。`--retry-all-errors` を付け、待ち受け開始後の成功を確認する形にした

### 実施手順 / LAN に公開する / 手順 1〜3: IPv4 と登録制限

- Quadlet の待ち受け・DOMAIN・ROOT_URL・SSH_DOMAIN をサーバーの IPv4 にそろえた
- Web と Git 用 SSH が指定 IPv4 へ公開され、`0.0.0.0`・IPv6 向けの公開になっていないことを `podman port` で確認した
- 切り替え後も新しいブラウザセッションでログインでき、管理者画面を開けた
- 通常登録のページには登録無効の説明が表示され、登録フォームが無かった
- 通常登録の無効化だけでは OpenID のリンクが残った。OpenID のログイン・登録も無効にして再起動し、リンクが消えることを確認した
- 匿名のリポジトリ閲覧はログイン画面へ転送され、`REQUIRE_SIGNIN_VIEW=true` が効いた

firewalld は、IPv4・送信元 CIDR・宛先 IPv4・priority 100・TCP ポートの 2 規則を `firewall-offline-cmd` で保存・一覧・削除し、`--check-config` が成功した。runtime の規則、許可外の送信元からの拒否、VPN の経路は確認していない。

### 実施手順 / Git の接続を確かめる / 手順 1〜5、再起動しても残ることを確かめる / 手順 1・2: Git とサービス再起動

- ブラウザで公開鍵を登録し、README で初期化したプライベートな `forgejo-test` を作った。main ブランチと SSH の clone URL を確認した
- ホスト公開鍵の生成場所は `~/.local/share/forgejo/ssh/*.pub` だった。本文の指紋表示をこの場所へ修正した
- サーバーの公開鍵とクライアントで取得した鍵を照合し、StrictHostKeyChecking を有効にしたまま `ssh -T` が認証できた
- SSH で clone し、`connection-check.txt` を commit / push できた。サービス再起動後も fetch と Web のログインが使えた

### バックアップ / 手順 1〜3、バックアップから復元する / 手順 2〜6

- サービスを停止してコンテナが無いことを確認し、全データと Quadlet を tar.gz へ保存した。保管ディレクトリ 0700・アーカイブ 0600 を確認した
- サービス再起動直後に停止した最初の確認では、コンテナは消えたが unit の表示が `failed` になった。後続の停止では `inactive`・`dead` を確認した。停止状態が違う場合にそのまま次へ進める根拠にはしていない
- 保存後に `after-backup.txt` を commit / push し、復元前後を比較できる状態にした
- 空の作業場所へ展開して構成と同じイメージ版を確認し、サービス停止後に現在のデータを退避して全体を入れ替えた
- 新しく clone した HEAD は保存時点と一致し、`connection-check.txt` が残り、`after-backup.txt` が消えた
- 同じホスト鍵で接続でき、復元後に `restore-check.txt` を commit / push できた
- 新しいブラウザで管理者のログイン、管理者画面、リポジトリ、SSH 鍵と 2 つのファイルを確認した
- 別ディスクや別サーバーへのアーカイブのコピーは未実施

### 更新 / 手順 2〜6

- 15.0.9 を再指定し、公式イメージの取得、停止バックアップ、イメージの行だけの置き換え、起動を通した
- `doctor check --all` は 28 項目で完了した。Web の新しいログインと Git 接続も使えた
- 異なる版へ上げる DB の移行と、旧版への復旧は未検証

### 実施手順 / 再起動しても残ることを確かめる / 手順 3〜7: ログアウト・コンテナ再起動

- OS のユーザーの SSH セッションを閉じ、logind に manager のセッションだけが残る状態で Web 200 と Git fetch を確認した
- `sudo systemctl reboot` で検証コンテナが終了した後、外側から Docker で起動した。ホストのカーネルを再起動した検証ではない
- TUN デバイスの検証専用の調整後、Forgejo が 11:21:01 UTC に自動起動し、最初の SSH ログインは 11:21:31 UTC だった
- ログイン前に Web 200 と Git fetch、ログイン後に `active`・`generated`・`Linger=yes` を確認した
- 新しいブラウザの管理者ログイン・リポジトリ・SSH 鍵・clone URL も残った。物理ホストと VM の再起動は未確認

### ガード・ロールバック・保持したデータも削除する

- 全 IPv4 を許可する CIDR、既存の Forgejo、空の復元先、空の更新版を指定すると中断した。Quadlet の内容が変わらないことを確認した
- ロールバックの停止・定義退避・再読込を通し、サービスが見つからず、動いているコンテナと 2 ポートの待ち受けが無いことを確認した
- 専用データの任意削除も通し、バックアップ・定義と復元前の退避が残ることを確認した
- firewalld の削除は offline の保存設定だけ。本文の runtime / permanent 両方の削除を本実行した扱いにはしていない

---

## 付録: スクリーンショット付きの基本操作の検証（2026-10-09）

「使い方の基本」の利用フローを、専用の試験リポジトリで実ブラウザと Git から通した。前の付録の AlmaLinux 10・rootless Podman・Quadlet の検証とは別の環境で、今回の結果を構築・ネットワーク制限・再起動の再検証として扱わない。

### 今回の環境と対象

| 項目 | 値 |
|---|---|
| 実施日 | 2026-10-09 UTC |
| サーバー | 公式の `codeberg.org/forgejo/forgejo:15.0.9-rootless` を専用 Docker コンテナで直接実行。イメージ内は Alpine Linux 3.23.5 |
| Docker | 28.4.0、vfs。daemon は rootful、Forgejo のプロセスは UID / GID 1000 (`git`)。rootless Podman での実行ではない |
| データ | 検証専用の bind ディレクトリ、SQLite。実際のアカウント・リポジトリは使っていない |
| 公開先 | Web は `127.0.0.1:13000`、Git 用 SSH は `127.0.0.1:12222` に限定。画像の `localhost` とポートは撮影用の値 |
| ブラウザ | Chromium 151.0.7922.173、Playwright 1.62.0、日本語 UI。実際のページを撮影し、画像を加工していない |
| Git クライアント | 2.52.0。サーバーとは別のクライアントから SSH で clone / push / pull |
| 試験値 | ユーザー `forgejotest`、メール `forgejotest@example.invalid`、リポジトリ `forgejo-demo`、SSH キー名 `usage-test-key` |

- イメージの digest は `sha256:caf1bca332f95cdcf124227a4bfa3b49bbbfbbc8a5e4a97406921cb581165413`
- パスワードはランダムに生成し、試験用の秘密鍵とともにリポジトリ外の 0600 のファイルへ保存した。端末出力・画像・Git へ載せていない
- サインイン画像ではパスワードを入力する前に撮影した。SSH キーの画像は登録済みの一覧で、公開鍵の全文や秘密鍵を表示していない
- AlmaLinux 10 の構築、rootless Podman、Quadlet、SELinux、firewalld、LAN / VPN、更新・バックアップ・再起動は今回の対象外。前の付録にある確認済み・未確認の範囲を変えない

### 使い方の基本 / 手順 1〜13: 実施内容と結果

| 操作 | 結果 |
|---|---|
| サインイン | 日本語 UI の「サインイン」から、新しいブラウザセッションで試験アカウントのパスワード認証が成功 |
| SSH 公開鍵の登録 | 「SSH / GPG キー」→「キーを追加」で登録し、一覧に `usage-test-key` が表示された |
| リポジトリ作成 | 「リポジトリをプライベートにする」と「リポジトリの初期設定」をオンにし、「詳細設定」で `main` を確認。作成後に「プライベート」、README、初回コミットが表示された |
| SSH 接続 | サーバーの公開ホスト鍵と取得した鍵を照合し、`StrictHostKeyChecking=yes` で試験ユーザーの認証と clone が成功。IPv4 の localhost に限定した試験接続には `-4` を使用 |
| イシュー作成 | 「イシューを作成」で `README に使い方を追加する` を作成し、Issue #1 が「オープン」になった |
| Git の変更 | `docs/readme-guide` を作り、README の末尾へ `## 使い方` と `Git で clone して作業用ブランチを作成します。` を追加。`README に使い方を追加` の commit と push が成功 |
| PR 作成 | 「新しいプルリクエスト」から、マージ先 `main`、プル元 `docs/readme-guide`、タイトル `README に使い方を追加`、本文 `Closes #1` で PR #2 を作成 |
| 差分確認 | 「変更されたファイル」に README だけの差分と追加した見出し・本文が表示された |
| マージ | 「会話」で「マージコミットを作成」を押し、確認フォームの同名ボタンで確定。「マージ済み」と「プルリクエストは正常にマージ、クローズされました」が表示された |
| main の反映 | ブラウザの `main` に追加した README が表示された。クライアントの `git switch main`、`git pull --ff-only`、`git log -1 --oneline` が成功し、同じ追加内容と作業ツリーが clean であることを確認 |
| Issue の閉鎖 | マージ後に Issue #1 が「クローズ」になり、`Closes #1` の関連付けが機能した |

- 試験の作業コミットは `a75949df3a`、main のマージコミットは `231e199761`。コミット ID は試験値で、利用者の実行結果と一致する必要はない
- PR の本文は `Closes #1` だけで通した。手順書にある目的・確認結果を加えた説明文の作成は、今回の撮影では実行していない
- 複数ユーザーでのレビュー・必須承認、CI の実行、競合の解消、Windows の Git Bash での操作は未検証
- イシュー作成直後に、テストが非同期の画面遷移より先に URL を判定し、一度失敗扱いにした。実画面で Issue #1 の作成済みを確認し、遷移の完了を待つようにテスト側を修正して、同じ Issue で続行した

### 保存した画像

8 枚とも実際の日本語 UI の PNG。最初の 2 枚は、同じページの必要な範囲をブラウザの撮影時に指定して再撮影した。

| 画像 | 判定に使った表示 |
|---|---|
| [usage-login.png](../images/forgejo/usage-login.png) | 「サインイン」、試験ユーザー名、空のパスワード欄 |
| [usage-ssh-keys.png](../images/forgejo/usage-ssh-keys.png) | 「SSHキーの管理」、登録済みの `usage-test-key` |
| [usage-repo-create.png](../images/forgejo/usage-repo-create.png) | `forgejo-demo`、プライベートと初期設定のチェック、デフォルトブランチ `main` |
| [usage-repo-clone.png](../images/forgejo/usage-repo-clone.png) | 「プライベート」、README、SSH を選択した clone URL |
| [usage-issue.png](../images/forgejo/usage-issue.png) | `README に使い方を追加する #1`、「オープン」 |
| [usage-pr-create.png](../images/forgejo/usage-pr-create.png) | マージ先 `main`、プル元 `docs/readme-guide`、PR のタイトルと `Closes #1` |
| [usage-pr-diff.png](../images/forgejo/usage-pr-diff.png) | 「変更されたファイル」、README の追加内容 |
| [usage-pr-merged.png](../images/forgejo/usage-pr-merged.png) | 「マージ済み」、main へマージした記録、正常にマージされた説明 |

### 完了時点の状態

- 専用コンテナ `forgejo-usage-screenshots` を停止・削除した。2 つの撮影用ポートが閉じ、同名コンテナが存在しないことを確認した
- 今回のパスワード、クライアントの秘密鍵、専用のサーバーデータ（`app.ini`、DB、内部の SSH 秘密鍵を含む）を削除した
- 公開画像と秘密を除いた試験結果・Git のログは保持した。実機・既存サービス・前の付録の記録を変更していない

---

## 付録: 基本操作の英語画面での再確認（2026-10-09）

利用ガイドの画面を English の UI で実ブラウザから撮り直した。前の付録の日本語画像・記録は保持し、英語画像は `*-en.png` の別名で保存した。Issue・PR・README の日本語の作業内容はそのままにした。

- 環境は専用の rootful Docker 28.4.0 / vfs で、公式 `15.0.9-rootless` を直接実行。イメージ内は Alpine Linux 3.23.5、Forgejo は UID / GID 1000。Web は `127.0.0.1:13000`、SSH は `127.0.0.1:12222` だけに公開した
- Chromium 151.0.7922.173 / Playwright 1.62.0 と Git 2.52.0 を使用。画面下部の言語メニューを開いて `English` を選び、英語の表示になることも実操作で確認した
- 今回は英語 UI の利用フローの確認。AlmaLinux 10・rootless Podman・Quadlet・SELinux・firewalld・LAN / VPN・運用手順の再検証として扱わない
- 試験値は `forgejotest` / `forgejo-demo` / `usage-test-key`。秘密を含まない実画面の PNG 8 枚で、サインインはパスワード入力前、キーは登録済みの一覧を撮った。最初の 2 枚はブラウザの撮影時に必要な範囲を指定した

| 画像 | 実際の英語ラベル・確認した表示 |
|---|---|
| [usage-login-en.png](../images/forgejo/usage-login-en.png) | `Sign in`、試験ユーザー名、空の `Password` |
| [usage-ssh-keys-en.png](../images/forgejo/usage-ssh-keys-en.png) | `SSH / GPG keys`、`Manage SSH keys`、登録済みの `usage-test-key` |
| [usage-repo-create-en.png](../images/forgejo/usage-repo-create-en.png) | `Make repository private`、`Initialize repository`、`Advanced settings`、`main`、`Create repository` |
| [usage-repo-clone-en.png](../images/forgejo/usage-repo-clone-en.png) | `Private`、README、`SSH` を選択した clone URL |
| [usage-issue-en.png](../images/forgejo/usage-issue-en.png) | `README に使い方を追加する #1`、`Open`。作成ボタンは `Create issue` |
| [usage-pr-create-en.png](../images/forgejo/usage-pr-create-en.png) | `merge into: forgejotest:main`、`pull from: forgejotest:docs/readme-guide`、タイトル・目的・確認結果・`Closes #1`、`Create pull request` |
| [usage-pr-diff-en.png](../images/forgejo/usage-pr-diff-en.png) | `Files changed`、README の追加内容 |
| [usage-pr-merged-en.png](../images/forgejo/usage-pr-merged-en.png) | `Merged`、`Pull request successfully merged and closed` |

- サインイン・公開鍵登録・プライベートな README 初期化済みリポジトリの作成、サーバーの公開ホスト鍵との照合と厳密なホスト鍵確認付き SSH 認証・clone を通した
- `docs/readme-guide` で前と同じ README の追記を commit / push し、Issue #1 を参照する PR #2 を作成。今回の PR 本文には目的・確認結果と `Closes #1` を入れた
- `Files changed` で README の差分を確認し、`Conversation` の `Create merge commit` と確認フォームの同名ボタンでマージ。`Merged` と成功メッセージ、Issue #1 の `Closed` を確認した
- ブラウザの `main` とクライアントの `git switch main` → `git pull --ff-only` → `git log -1 --oneline` で README の追加内容を確認し、作業ツリーは clean だった。作業コミットは `bccf177c0c`、マージコミットは `cde84ae555`（どちらも試験値）
- テスト側ではサインイン画面の表示とログイン後の遷移を明示的に待つように補正して続行した。製品のログイン失敗として扱わない
- 完了後に専用コンテナ `forgejo-usage-screenshots-en`、パスワード・秘密鍵、`app.ini`・DB・内部の SSH 秘密鍵を含む専用データを削除した。同名コンテナが存在せず、2 ポートが閉じていることを確認。公開画像と秘密を除いた試験結果・Git のログは保持した

---

## 付録: 最新版16.0.5での英語利用操作検証（2026-10-09）

最新通常版として指定された公式 `codeberg.org/forgejo/forgejo:16.0.5-rootless` を新規に起動し、「使い方の基本」を英語 UI と Git で通した。15.0.9 の日本語・英語画像 16 枚と前の付録は保持し、今回の画像は `*-en-v16.png` の別名で保存した。Issue・PR・README の日本語の作業内容は同じ例を使用した。

### 今回の環境と範囲

- rootful Docker 28.4.0 / vfs で公式イメージを直接実行。イメージ内は Alpine Linux 3.23.5、Forgejo の UID / GID は 1000 (`git`)
- 取得したイメージの digest は `sha256:5effb7305584aca479b29fde6f9631a6dbe86ae798ae02eeea33a3666f0c0bf8`。バイナリと実画面の両方で 16.0.5 を確認した
- 保存先 `custom/conf/app.ini`、DB `data/forgejo.db`、リポジトリ `git/repositories`、LFS `git/lfs`、ログ `data/log` は、`/var/lib/gitea` の下で 15.0.9 と同じ。`/usr/local/bin/gitea` と `/usr/local/bin/forgejo` の双方があった
- 検証専用の bind データと SQLite を使用。Web は `127.0.0.1:13000`、Git 用 SSH は `127.0.0.1:12222` だけに公開した。画像内の localhost とポートは撮影用の値
- Chromium 151.0.7922.173 / Playwright 1.62.0、Git クライアント 2.52.0。画面下部の言語メニューから `English` を選ぶ操作も成功した
- この付録は新規の 16.0.5 における利用フローの確認。AlmaLinux 10、rootless Podman、Quadlet、SELinux、firewalld、LAN / VPN、旧版からの移行、バックアップ・再起動の再検証として扱わない

### 使い方の基本 / 手順 1〜13: 実施内容と結果

- `Sign in` で試験ユーザー `forgejotest` がログインし、`Add key` で `usage-test-key` を登録。`Make repository private` と `Initialize repository` をオンにし、`Advanced settings` の `main` を確認して `forgejo-demo` を作った
- サーバーの公開ホスト鍵と取得した鍵を照合し、`StrictHostKeyChecking=yes` で SSH 認証と clone が成功。README 初期化済みのプライベートなリポジトリと SSH の clone URL を確認した
- Issue #1「README に使い方を追加する」を作り、`docs/readme-guide` で README の「使い方」と指定文を追加。commit「README に使い方を追加」と push が成功した
- マージ先 `main`、プル元 `docs/readme-guide`、タイトル「README に使い方を追加」で PR #2 を作成。本文は目的・差分を確認したこと・`Closes #1` を含む説明にした
- `Files changed` で README の差分を確認し、`Conversation` の `Create merge commit` と確認フォームの同名ボタンで確定。`Merged` と `Pull request successfully merged and closed` を表示し、Issue #1 は `Closed` になった
- ブラウザの `main` とクライアントの `git switch main` → `git pull --ff-only` → `git log -1 --oneline` で README の追加内容を確認。作業ツリーは clean だった。作業コミットは `d6848f28bb`、マージコミットは `ffb6ffe979`（どちらも試験値）
- 利用ガイドで使う主要な操作名は 15.0.9 と同じ。比較バーの `merge into:` / `pull from:` も確認した

### 保存した英語画像

パスワードを入力する前の画面と登録済みの公開鍵一覧を使用し、秘密を含まない 8 枚を実ブラウザから撮影した。PNG の形式と旧版の画像 16 枚の SHA-256 が変わっていないことを確認した。

| 画像 | 確認した表示 |
|---|---|
| [usage-login-en-v16.png](../images/forgejo/usage-login-en-v16.png) | `Sign in`、試験ユーザー名、空の `Password` |
| [usage-ssh-keys-en-v16.png](../images/forgejo/usage-ssh-keys-en-v16.png) | `Manage SSH keys`、登録済みの `usage-test-key` |
| [usage-repo-create-en-v16.png](../images/forgejo/usage-repo-create-en-v16.png) | プライベート・初期設定のチェック、デフォルトブランチ `main` |
| [usage-repo-clone-en-v16.png](../images/forgejo/usage-repo-clone-en-v16.png) | `Private`、README、`SSH` を選択した clone URL |
| [usage-issue-en-v16.png](../images/forgejo/usage-issue-en-v16.png) | Issue #1 と `Open` |
| [usage-pr-create-en-v16.png](../images/forgejo/usage-pr-create-en-v16.png) | `merge into:`、`pull from:`、PR のタイトル・目的・確認結果・`Closes #1` |
| [usage-pr-diff-en-v16.png](../images/forgejo/usage-pr-diff-en-v16.png) | `Files changed`、README の追加内容 |
| [usage-pr-merged-en-v16.png](../images/forgejo/usage-pr-merged-en-v16.png) | `Merged`、main へのマージ記録と成功メッセージ |

- 完了後に専用コンテナ `forgejo-usage-screenshots-v16`、パスワード・秘密鍵、`app.ini`・DB・内部の SSH 秘密鍵を含む専用データを削除した。同名コンテナの不在と撮影用の 2 ポートが閉じたことを確認し、公開画像と秘密を除いた試験結果・Git のログを保持した

---

## 付録: 最新通常安定版16.0.5のAlmaLinux 10での新規導入確認（2026-10-09）

公式 `codeberg.org/forgejo/forgejo:16.0.5-rootless` を、新しい AlmaLinux 10.2 の systemd コンテナに rootless Podman と Quadlet で導入した。今回の範囲は新規起動・初期設定・サービスの停止と起動後の保持の確認。前の 15.0.9 の運用検証を、16.0.5 の結果へ広げるものではない。

### 今回の環境と検証用の調整

- 専用コンテナは `forgejo-alma10-latest-verify`。外側の Docker 28.4.0 / vfs で `almalinux/10-init:latest` を `--privileged`・`--cgroupns=private` で起動し、AlmaLinux 10.2 / x86_64 の RPM を導入した
- Podman は `5.8.2-9.el10_2.alma.1`。新しい一般ユーザーへ SSH で直接ログインし、rootless=true、vfs、netavark、pasta、cgroup v2、`XDG_RUNTIME_DIR=/run/user/1000`、linger を確認した
- `10-init` が mask している systemd-logind を、この専用コンテナでだけ有効にした。入れ子の overlay は使えず、専用ユーザーの空のストアを vfs に作り直した。これらは検証環境の調整で、構築手順に追加する設定ではない
- TUN デバイスを専用コンテナ内に用意した。session proxy と CA は検証環境にだけ設定し、TLS の検証は有効なまま使用した
- 外側の Docker が取得済みの公式イメージを save / load で渡して起動し、その後に一般ユーザーの Podman 自身で公式レジストリへの `podman pull` も成功した
- 取得後の rootless Podman の `image inspect` が表示した digest は `sha256:bda6d9357909df2f315b921fb5b6da88fbfc1ca622698225e5a4b0a7a3b7b42c`。バイナリと Web の表示で 16.0.5 を確認した
- Forgejo はホスト・コンテナとも UID / GID 1000。`keep-id:uid=1000,gid=1000` と専用 bind mount を使用し、Web 3000・Git 用 SSH 2222 はサーバーの localhost に限定した
- 外側のブラウザと SSH からは、検証専用の SSH トンネルの Web 13403・Git 用 SSH 12224 を使用した。ホストの SSH は localhost 12223。ROOT_URL の localhost とポートも、この検証用トンネルに合わせた
- Chromium 151.0.7922.173 / Playwright 1.62.0 の実ブラウザで確認した。パスワードは専用の 0600 のファイルにだけ保存し、ログと画像へ出さなかった

### 実施手順 / イメージを取得して localhost で起動する / 手順 2〜5、初期設定と管理者の作成 / 手順 1〜3、Git の接続を確かめる / 手順 1・4、再起動しても残ることを確かめる / 手順 1・2 の一部: 実施内容と結果

| 確認 | 結果 |
|---|---|
| Quadlet の生成と起動 | dry-run 成功、`active`・`generated`。初期 HTTP は、起動直後の connection reset を再試行して 200 |
| rootless と bind の所有者 | コンテナ内は `1000:1000` (`git`)、ホストの専用データは一般ユーザーの `1000:1000`・0700 |
| 版とバイナリ | `/usr/local/bin/gitea --version` は 16.0.5。`/usr/local/bin/forgejo` も存在した |
| 内蔵 SSH | コンテナの待ち受け TCP 2222 と Web 3000 を確認。`podman port` は localhost の 2222 と 3000 |
| 初期管理者と保存先 | ブラウザで SQLite と管理者を設定し、別のログイン操作も成功。`custom/conf/app.ini` と `data/forgejo.db` は `/var/lib/gitea` の下。SQLite の署名、`quick_check=ok`、管理者の DB 行を確認 |
| 初期設定と閲覧制限 | `INSTALL_LOCK=true`、`DISABLE_REGISTRATION=true`、`REQUIRE_SIGNIN_VIEW=true`。匿名のリポジトリ閲覧はログイン画面へ転送された |
| OpenID と登録画面 | `ENABLE_OPENID_SIGNIN=false`・`ENABLE_OPENID_SIGNUP=false`。登録画面は `Registration is disabled` を表示し、登録フォームと OpenID のリンクが無かった |
| 初期設定後のデータ | ブラウザで SSH 公開鍵と、README で初期化したプライベートな `latest-restart-check` を作成できた |
| サービス停止と再起動 | stop の後は `inactive`・`dead` でコンテナが無くなり、start の後は `active` と HTTP 200。設定と SSH ホスト公開鍵の SHA-256、bind 上の確認用ファイル、リポジトリの保持を確認 |
| サービス再起動後のブラウザ | 新しいブラウザセッションで管理者がログインし、管理者画面・確認用リポジトリ・登録済み SSH 公開鍵を引き続き利用できた |

### 今回の制限と未確認範囲

- Podman の `selinuxEnabled=false`。SELinux Enforcing における `:Z` の適用と拒否の有無は確認していない
- firewalld は今回もカーネルの nftables 機能不足で起動に失敗し、最終状態は `inactive`・`dead`。runtime の規則、許可外の送信元からの拒否、実際の LAN・VPN 接続は確認していない。前の付録の offline 規則の検証を今回の再実行とは扱わない
- 今回の再起動は Forgejo のサービスの stop / start。OS のログアウト、検証コンテナの再起動、実機・VM の OS 再起動は、この 16.0.5 の確認では実行していない
- バックアップ・復元・更新・doctor・構築手順全体の通し実行、15.0.9 から 16.0.5 への DB の移行、旧版への復旧は再検証していない。旧 15.0.9 の結果は前の付録の範囲に従う
- aarch64、ホスト UID が 1000 以外の構成、別サーバーへの移設は未確認。今回の SSH 鍵はブラウザへの登録と保持を確認したもので、Git の clone・push と利用フローは直前の Docker による 16.0.5 の付録の結果に従う

### 完了時点の状態

- 専用コンテナと SSH トンネルを撤去し、同名コンテナが存在せず、localhost の 13403・12223・12224 に待ち受けが残っていないことを確認した
- 今回のパスワード、SSH の秘密鍵、サーバーの専用データ、プロキシ用の設定、試験用の画像と作業ファイルを削除した。イメージの転送はストリームを使い、大きな tar ファイルは残していない
- 既存の画像・前の検証記録・ほかのサービスは変更していない

---

## 付録: 最新版の自動判定と自動更新の検証（2026-10-10）

手順書から `16.0.5` の直書きをなくし、「イメージを取得して localhost で起動する」の手順 2 で最新の安定版を調べて入れ、「自動更新を有効にする」の手順 1〜3 のユーザータイマーで毎日自動で更新する形に変えた。新しい AlmaLinux 10.2 の systemd コンテナに一般ユーザーの rootless Podman で導入し、手順書のブロックを tmux から実際の端末へブラケットペーストで貼って通した。前の付録の 15.0.9・16.0.5 の結果を、この付録の範囲へ広げない。

### 今回の環境と検証用の調整

| 項目 | 値 |
|---|---|
| 実施日 | 2026-10-10 UTC |
| 外側 | Docker 29.8.2、vfs。`quay.io/almalinuxorg/10-init:latest`（digest `sha256:c8a5eee8dbb215f6cb9103bc8686ab02f7eb5f495d32333220147b2a899d28e1`、AlmaLinux 10.2、x86_64）を `--privileged`・`--cgroupns=private`・`--network host` で起動 |
| systemd / cgroup | systemd 257-23.el10_2.2.alma.1 が PID 1、cgroup v2（コントローラは cpuset・io・hugetlb だけ） |
| Podman | 5.8.2-9.el10_2.alma.1、rootless、vfs、netavark、pasta（passt 0^20251210） |
| Forgejo | 公式の `15.0.9-rootless`（digest `sha256:caf1bca332f95cdcf124227a4bfa3b49bbbfbbc8a5e4a97406921cb581165413`）と `16.0.5-rootless`（`sha256:5effb7305584aca479b29fde6f9631a6dbe86ae798ae02eeea33a3666f0c0bf8`） |
| その他 | Python 3.12.15、Git 2.52.0、OpenSSH 9.9p1。ブラウザは外側の Chromium 141.0.7390.37 / Playwright 1.56.1 |
| 利用者 | サーバーを動かす UID 1000 の一般ユーザー（NOPASSWD の sudo・linger）と、別の PC の代わりの UID 1001 の一般ユーザー |
| 待ち受け | `SERVER_IP` は外側と共有する `<SERVER_IP>`、`LAN_SUBNET` はその /24。Web 3000、Git 用 SSH 2222 |

- Docker Hub は取得回数の制限に当たったので、同じ digest のイメージを quay.io から取った
- 外側のホストが cgroup v1 だったので、外側で cgroup v2 をマウントし直してから dockerd を起動した
- dnf の mirrorlist が平文の HTTP の候補を返し、検証環境のプロキシを通らなかった。リポジトリの定義を `repo.almalinux.org` の HTTPS の baseurl に変えた
- プロキシと CA は検証環境にだけ設定した（ユーザーの `~/.config/environment.d/` と `~/.bashrc`、`NO_PROXY` に `<SERVER_IP>`）。手順書の構築先へ同じ設定を追加するものではない
- `10-init` が mask している systemd-logind を有効にし、Podman の保管場所を vfs、PID 数の制限を 0 にした。`/` を shared に変えた
- firewalld はこのコンテナで動かないので、rich rule をファイルに保存する `firewall-cmd` のスタブを置いた
- journal が揮発で一般ユーザーが `journalctl --user` を読めなかったので、`/var/log/journal` を作って永続にした（AlmaLinux の通常の導入と同じ形）
- コンテナの再起動後は `/dev/net/tun` が 0600 になり、pasta が開けずに forgejo.service が `failed` になった。検証環境だけ 0666 に戻して起動し直した

### 実施手順 / イメージを取得して localhost で起動する / 手順 1〜5、初期設定と管理者の作成 / 手順 1〜3、LAN に公開する / 手順 1・2: 最新版の自動判定と導入

- 「イメージを取得して localhost で起動する」の手順 2 は `導入する版: 16.0.5` を表示し、`16.0.5-rootless` を取得して `forgejo version 16.0.5+gitea-1.22.0` を表示した
- メジャー版の自動更新を試すため、1 回目は「イメージを取得して localhost で起動する」の手順 2 の後に同じシェルで `FORGEJO_VERSION=15.0.9` を代入し（試験だけの変更）、同じ項の手順 3 の Quadlet に `15.0.9-rootless` を書かせた。「イメージを取得して localhost で起動する」の手順 4・5、「初期設定と管理者の作成」の手順 3、「LAN に公開する」の手順 1・2 は前の付録と同じ結果（`active`・`generated`、localhost の 200、ロックと自己登録無効、指定 IPv4 への切り替え）
- 「初期設定と管理者の作成」の手順 2 は、外側の実ブラウザから `http://localhost:3000/` を開いて初期設定し（ネットワークを共有するので同じ項の手順 1 のトンネルは使わなかった）、新しいブラウザのセッションで管理者のログインを確かめた
- 試験データ（公開鍵の登録、README で初期化したプライベートな `forgejo-test`、Issue #1、PR #2）は API で作り、別の PC の代わりのユーザーから SSH で clone・push した（3 コミット）。ホスト鍵の指紋はサーバーの公開鍵と一致した
- `REQUIRE_SIGNIN_VIEW=true` のまま、`/api/healthz` はログイン無しで 200 と `"status":"pass"` を返した。リポジトリの匿名の閲覧はログイン画面へ転送された
- 2 回目（全部消した後）は、新しいシェルで「イメージを取得して localhost で起動する」の手順 3 だけを貼ると `中断: 同じシェルで手順 2 を通す` で止まった。「イメージを取得して localhost で起動する」の手順 2 → 3 では Quadlet が `Image=codeberg.org/forgejo/forgejo:16.0.5-rootless` になった
- 最新版を調べられないとき（検証のシェルでプロキシを接続できない番地にした）は、「イメージを取得して localhost で起動する」の手順 2 が `urllib.error.URLError` で止まり、取得へ進まず `FORGEJO_VERSION` は空のままだった

### 実施手順 / 自動更新を有効にする / 手順 1〜3: 自動更新

- 「自動更新を有効にする」の手順 1 で置いたプログラムは、元のファイルとバイト列が一致した（`-rwx------`）。ブラケットペースト無しで貼った 2 回目も一致し、`event not found` は出なかった。貼り直すとプログラムだけが置き換わった
- 「自動更新を有効にする」の手順 2 の後、試験用のドロップインで `OnCalendar` を 3 分後・`RandomizedDelaySec=0` に変え、同じ項の手順 3 の 1 行目と同じ `enable --now` でタイマーを有効にした
- タイマーは 03:28:02 UTC に発火し、15.0.9 → 16.0.5 を 16 秒で終えた（`Result=success`・`ExecMainStatus=0`）
  - journal: `更新を始める: 15.0.9 → 16.0.5`、`バックアップ: …/forgejo-auto-20261010T032809Z-15.0.9.tar.gz`、doctor の 27 項目がすべて OK、`更新: 15.0.9 → 16.0.5`
  - forgejo.service の journal に、v16 の DB の移行（`v16a_…`・`v16b_…`）が出た
  - 1 秒おきの確認で、Web と Git 用 SSH が止まったのは 03:28:08〜03:28:11 の約 3 秒
  - アーカイブは 0700 のディレクトリに 0600 で置かれた。中身は手動のバックアップと同じ 2 つの場所
  - 検証で先に取得していた `16.0.4-rootless` は消え、`15.0.9`（直前の版）と `16.0.5` が残った
- 更新後も、Issue #1・PR #2（マージ可能）・3 コミット・SSH のホスト鍵の指紋が残った。新しいコミットの push、`/api/v1/version` の `16.0.5+gitea-1.22.0`、実ブラウザでの管理者のログイン（フッターの版 16.0.5）を確かめた
- 試験用のドロップインを外して「自動更新を有効にする」の手順 3 をそのまま貼ると、`最新版 16.0.5 を使用中` で終わった。Quadlet の sha256、forgejo.service の起動時刻、アーカイブの数は変わらなかった。`list-timers` の `NEXT` は 04:06:56 UTC
- 最初の版では、journal の末尾が doctor の出力と Podman のイベントで埋まった。doctor の出力は失敗したときだけ出すようにプログラムを直し、手順書の `journalctl` に `-t forgejo-auto-update` を足した

### 失敗と保留・止まっているとき・ガード

- 復元の手順 1〜5 で、自動更新のアーカイブから 15.0.9 とデータに戻した（バックアップの後に push したコミットは無くなった）。手順 7 は `保留: 16.0.5（15.0.9 を使用中）` を出した
- 保留中に更新の節の手順 2 を貼ると、`保留中: 16.0.5 へは更新しない（15.0.9 を使用中）…` で終了 1 になり、何も変わらなかった
- 失敗の再現は、出荷するプログラムを変えず、サービスの試験用ドロップインで `PATH` の先頭に podman の包みを置いた。包みは、目印のファイルがあるときだけ `doctor` の呼び出しを失敗させる
- 更新の節の手順 4（保留を解いて動かす）では、16.0.5 で起動して DB の移行が走った後に doctor が 3 回失敗し、自動で戻した（終了コード 2）
  - journal: `更新に失敗した: doctor check --all が 3 回とも失敗した`、`更新に失敗したデータと定義の退避: …/failed-update-20261010T033310Z`、`15.0.9 に戻し、16.0.5 を保留した`
  - 戻した後は Quadlet が 15.0.9、`gitea --version` が 15.0.9、`skip-version` が `16.0.5`。`failed-update-*` に更新後のデータと 16.0.5 の定義が残った。clone した main は更新前のコミットのままだった
  - Web と Git 用 SSH が止まったのは、更新と戻しでそれぞれ約 3 秒
- 保留を解き、forgejo.service を止めてから動かすと、`forgejo.service が止まっているので更新しない…` で終了 0。サービスは止まったまま、版も変わらなかった
- 包みで pull を 90 秒遅らせ、自動更新の実行中（`activating`）に、バックアップの手順 1・復元の手順 3・ロールバックの手順 2 を貼ると、3 つとも `中断: 自動更新の実行中。終わってから貼り直す` で止まった。プログラムを直接動かすと `中断: 別の自動更新が動いている`（終了 1）
- 遅らせた実行は、doctor を失敗させずに 15.0.9 → 16.0.5 を終えた（`doctor check --all: All done (checks: 27).`）。その後の push も成功した
- 最新版を調べられないとき（接続できないプロキシ）は、`中断: 公式の最新安定版を調べられない: <urlopen error [Errno 111] Connection refused>` で終了 1、Quadlet は変わらなかった
- 単体の確認: 版を選ぶ関数（LTS が後に公開される順・プレリリース・下書き・形式外のタグ）、`16.0.50` を `16.0.5` と取り違えないこと、root では動かないこと、自動更新のアーカイブを新しい 3 つだけ残して手動のバックアップに触れないこと、イメージは今と直前の版と系列のタグを残すこと

### 再起動・ロールバック・保持したデータも削除する

- `docker restart` の後、ログイン前に `forgejo-auto-update.timer` が `active` で、`NEXT` は 04:06:56 UTC、起動直後の実行は無かった。forgejo.service は検証環境の TUN の権限で `failed` になり、権限を直して起動した（上の調整）
- ロールバックの手順 2 は、タイマーを無効にして、タイマー・サービス・プログラム・Quadlet を `removed-*` へ移した。手順 4 は `0 timers listed.`、2 ポートの待ち受け無し
- 自動更新の無い構成（「自動更新を有効にする」の手順 1〜3 を通していない 2 回目）でも、ロールバックの手順 2 は Quadlet だけを移して通った
- 保持したデータの削除の手順 2 は、実際の端末では `rm -r` が git のオブジェクト（書き込み禁止）ごとに確認を求めて止まった。前の付録の確認は端末の無い実行だった。`rm -r -f` に直し、確認無しで消えることを確かめた。バックアップと退避は残った

### 完了時点の状態

- 検証用のコンテナ・プロキシの設定・試験用のパスワード・秘密鍵・データは、記録の後に撤去した。実機やほかのサービスを変更していない

## 付録: Raspberry Pi 5 の実機構築（2026-10-11 JST）

### 対象と実施前の状態

| 項目 | 値 |
|---|---|
| 対象手順 | `b8c74c7` をもとにした「イメージを取得して localhost で起動する」からの手順 |
| ホスト | Raspberry Pi 5 Model B Rev 1.0、AlmaLinux 10.2、aarch64 |
| Podman | 5.8.2、rootless、cgroup v2、netavark |
| ユーザー | ホスト・コンテナとも UID / GID 1000、`Linger=yes` |
| Forgejo | 16.0.5、公式 `codeberg.org/forgejo/forgejo:16.0.5-rootless` |
| イメージ digest | `sha256:e3b6d9fa352fee1b5ec3cb8bed4ff19984987ff74a77e4d33bbea359059757c8` |
| SELinux / firewalld | Enforcing / active、LAN NIC と WireGuard の NIC は `public` |
| IPv4 | DHCP 取得。現在の IPv4 はルーターの固定割り当て済みとの利用者申告 |
| 公開先 | `<SERVER_IP>:3000` と `<SERVER_IP>:2222` |
| 送信元 | 利用者の指定で `0.0.0.0/0`。送信元を制限しない |

- 実施前に Forgejo の定義・データ・コンテナは無く、3000 / 2222 の待ち受けも無かった
- Podman・linger・NOPASSWD sudo・firewalld・SELinux は導入済みだった
- 実機を再起動せず、既存の WireGuard 設定やほかのサービスの設定は変更していない
- 出力中の IP・ユーザー名・SSH 指紋はプレースホルダで表す。パスワード・秘密鍵・`app.ini` の内容は直接読み取り・掲載していない

### イメージを取得して localhost で起動する / 手順 1〜5

- Codeberg のリリース一覧から最大の安定版を判定し、16.0.5 を取得した。イメージの architecture は `arm64`
- `/usr/local/bin/gitea --version` は `forgejo version 16.0.5+gitea-1.22.0`。ホストの一般ユーザーが rootless で実行した
- Quadlet の初回起動後に `active`・`generated`、コンテナ内の `uid=1000(git) gid=1000(git)` を確認した
- `podman port forgejo` と `ss` で、初回は 3000 / 2222 の両方が `127.0.0.1` に限定されることを確認した
- データディレクトリのラベルは `system_u:object_r:container_file_t:s0:<MCS>`、権限は 0700。Quadlet は 0600
- 起動直後の curl で一度 connection reset が出たが、再試行で HTTP 200 となった。初期設定フォームの DB は SQLite3、保存先は `/var/lib/gitea/data/forgejo.db`

### LAN に公開する / 手順 1・2 と今回の変更点

- 当初は手順書どおり localhost へ起動したが、利用者から「最初から任意のホストからアクセスできるように」と指定されたため、管理者作成前に LAN IPv4 の待ち受けへ切り替えた
- 手順書の標準順序は管理者作成後の LAN 公開。今回の前倒しを、標準順序の通し検証として扱わない
- `public` の runtime と permanent に、送信元 `0.0.0.0/0`・宛先 `<SERVER_IP>`・3000/tcp と 2222/tcp の rich rule を各 1 本追加した
- LAN 公開後の `podman port forgejo` と `ss` は、両ポートの待ち受けが `<SERVER_IP>` だけであることを示した
- ホスト自身から `http://<SERVER_IP>:3000/` は HTTP 200。初期画面のドメイン・ベース URL・SSH ポートも公開先の値になった
- これは別端末からの LAN・VPN 接続を確認した結果ではない
- Codex の実行経路では途中から `systemctl --user` が `Connection refused` になった。`systemctl --user --machine=<USER>@.host` では `active`・`generated`・`Result=success`・`ExecMainStatus=0` を確認でき、Web も応答した

### 初期設定と管理者の作成 / 手順 2・3

- 利用者が公開先のブラウザで初期管理者を作成し、ログインできたと回答した。パスワードはエージェントへ渡していない
- `/install` は HTTP 303 で `/user/login` へ移り、初期設定画面が再表示されなかった
- `/user/sign_up?lang=en-US` は HTTP 200 だが、`Registration is disabled` が表示され、OpenID の入口も無かった。`/api/healthz` は HTTP 200、`status=pass`
- 匿名の `/explore/repos` は HTTP 303、`/api/v1/repos/search` は HTTP 403。ホームが HTTP 200 というだけで匿名閲覧を許可したと判断していない
- `admin user list --admin` は終了コード 0、有効な管理者 1 人。`app.ini` と SQLite は存在を確認し、内容を直接読んでいない
- 新しい確認コードの試行で、`--admin` を付けた一覧は `IsAdmin` 列を省略することが分かった。末尾の `IsActive=true` だけを判定するよう 3 か所を修正した

### 再起動しても残ることを確かめる / 手順 1

- Forgejo のサービスを再起動した。ホスト OS の再起動や全ログアウトはしていない
- 再起動後のヘルスチェック、有効な管理者 1 人、SSH ホスト公開鍵の指紋の一致を確認した
- この時点で試験用リポジトリはまだ無く、コミットの保持や別端末でのログイン・fetch は未確認

### バックアップ / 手順 1〜3 と隔離コピーでの復元

- タイマーを一時停止し、自動更新が実行中でないことを確かめてから Forgejo を停止した。コンテナが無くなってからデータと Quadlet を tar.gz へ保存した
- アーカイブは 0600、57,662 バイト。gzip の検査を通した。取得後は Forgejo とタイマーを再開し、ヘルスチェックが HTTP 200 になった
- アーカイブを 0700 の別ディレクトリへ展開し、本番のデータをマウントせずに rootless の一時コンテナで確認した
- `--network=none` の CLI で、有効な管理者 1 人と `doctor check --all` の終了コード 0、`OK` 27 行を確認した。本番の診断も同じ結果で、修復オプションは付けていない
- Web の復元確認の最初の起動では、専用 internal ネットワークの aardvark-dns がユーザー D-Bus へ接続できず失敗した。検証用のコンテナとネットワークを撤去し、`--internal --disable-dns` で作り直した
- 復元コピーだけを `:Z` でマウントし、Web 13300 / SSH 12222 を `127.0.0.1` に限定した。専用ネットワークの `internal=true`・`dns_enabled=false` を確認した
- 復元側の `/install` は 303、登録画面は 200 で登録無効、匿名の `/explore/repos` は 303、ヘルスチェックは 200 / pass。有効な管理者と SSH 指紋も本番の取得前と一致した
- バックアップ取得時点のリポジトリは 0 個だった。これは管理者・構成・SSH の復元確認で、コミットの復元や復元後のログイン・Git 操作の確認ではない
- 検証用コンテナ・ネットワーク・コピーは成功確認後に撤去した。本番と停止バックアップは保持した

### LAN・VPN の接続確認とコミットを含む追加バックアップ

- 利用者が LAN と VPN のそれぞれで Web と Git の clone / commit / push / fetch を確認できたと回答した。接続元や実行結果はエージェントが別端末で直接取得したものではない
- ホストではリポジトリ 1 個・Git 参照 1 本を確認し、参照名とオブジェクト ID のメタデータを保持確認に使った。コミット本文や設定内の秘密を表示していない
- Git 試験後にもう一度停止バックアップを取得した。追加アーカイブは 0600、62,267 バイト。最初のバックアップも保持した
- サービス再開後と隔離コピーの Git 参照は取得前と一致した。SSH 指紋も、本番と復元側の両方で最初の取得時と一致した
- コミットを含む復元側で Web の制限・有効な管理者・healthz・doctor を確認し、`git fsck --full` は終了コード 0 だった
- 復元側へのログイン・SSH 認証・clone / push は実施していない。今回は Git オブジェクトの整合性と参照の保持までを確認した
- 追加の復元用コンテナ・ネットワーク・コピーも撤去し、本番サービスとタイマーを再開した

### 自動更新を有効にする / 手順 1〜3

- 手順書の自動更新プログラムを配置して Python の構文検査を通した。プログラムは 0700、状態とバックアップのディレクトリも 0700
- ユーザーのサービスとタイマーを配置し、unit の検査を通して有効化した。毎日 4:00〜4:30 のサーバー時刻で動く
- 初回の手動実行は `最新版 16.0.5 を使用中`、`Result=success`、`ExecMainStatus=0`。前後のコンテナ ID は同じで、最新版の確認ではサービスを再起動していない
- 初回に表示された次回実行時刻は 2026-10-11 04:02:31 JST。日ごとの時刻はランダム遅延で変わる
- ユーザー unit 内でも、通常の `systemctl --user is-active forgejo.service` は user scope bus への接続拒否で失敗した。同じユーザーの `--machine=<USER>@.host` では成功したため、接続拒否の場合だけこの経路で再試行する処理を自動更新へ加えた
- 修正後の確認関数を一時的なユーザー unit 内で実行し、`is-active` と `ActiveState` がともに `active` になった。最新版確認の再実行も `Result=success`・`ExecMainStatus=0` で、コンテナ ID は変わらなかった。共有の D-Bus サービスは変更していない
- 今回は新しい版への更新や失敗時の自動ロールバックを実機で試していない。過去の systemd コンテナの結果とは区別する

### 文書の静的検査と確認コード

- 手順書の Bash 33 ブロック・extra の Bash 5 ブロックは `bash -n` と ShellCheck 0.11.0 を通した。埋め込み Python 7 本は構文検査と Ruff 0.17.0 の `E4,E7,E9,F` を通した
- 初期設定完了の確認関数は 3 か所それぞれ 9 ケース、計 27 ケースのスタブ試験を通した。初期画面が開く・healthz の失敗・登録拒否無し・OpenID 入口・無効または不在の管理者・CLI の失敗で中断することも確かめた
- 自動更新の systemctl 呼び出しは 9 ケースのスタブ試験を通した。通常成功・bus 接続失敗後の再試行・unit 自体の失敗・再試行の失敗・`check=False`・タイムアウトの扱いを確認した
- 管理者一覧の実ヘッダと HTTP の実応答を確認条件へ反映した。相対リンク先と `git diff --check` も通した
- 手順書のコードブロック全体を実機で機械的に実行していない。対象のコマンドを確認して個別に実施し、標準順序との差は今回の付録に記録した

### 完了時点と残る確認

- 実機の Forgejo・自動更新タイマーは稼働中。LAN IPv4 の 3000 / 2222 と送信元制限なしの 2 規則を runtime / permanent に保持している
- 管理者の作成と最初のログイン、LAN と VPN のそれぞれでの Web・Git 操作は利用者が確認済み
- ホスト OS の再起動と全ログアウト後の検証は別途調整する。実機での新しい版への更新と自動ロールバック、復元側へのログイン・SSH 認証・Git の通信は未検証

---

## 付録: Hyper-V の VM で通した記録（2026-10-11）

- **何を**: [手順書](https://github.com/ryo-aoki-pc/setup-notes/blob/114c2b2bfd14b51f9e1925b150cbf72e1954f311/docs/forgejo.md)の実施手順（6 項・26 手順）→「使い方の基本」（13 手順）→「バックアップ」（4 手順）→「バックアップから復元する」（7 手順）を、コミット `114c2b2` の本文で、上から通した
  - 「更新」の節・「設定ファイル」の表・[ロールバック](../extra/forgejo.md)は、この通しの範囲の外（流していない）
  - 入った版は、「イメージを取得して localhost で起動する」の手順 2 がその場で調べた 16.0.5
- **結果**: 50 手順のうち、通した 47、通らなかった 0、条件に当たらず飛ばした 3、未実施 0
  - 飛ばした 3 つ: 「使い方の基本」の手順 2・3（同じ PC の鍵を登録済み・同じサーバーへ照合済み）、「バックアップから復元する」の手順 7（新しい版の不具合で戻したのではない）
  - 「通した」に数えた中に、手順書の書く形と違えたものがある: ブラウザで行う操作の全部（人の手ではなく、スクリプトで操作した）、「バックアップ」の手順 4（別の VM への `scp` で代えた）、許可外の送信元（VM を動かしている Windows の PC を使った）。サーバーの IPv4 も固定していない（[通らなかった手順と、手順書の前提と違えた所](#通らなかった手順と手順書の前提と違えた所hyper-v2026-10-11)）
- **どの状態から**: Hyper-V の列の VM のスナップショット `after-CL1` のクローン
  - Kickstart で入れた AlmaLinux 10.2 の Workstation に、[初期設定](../almalinux-setup.md)の実施手順（[記録](almalinux-setup.md#付録-hyper-vvmwarevirtualbox-の-vm-で今の順番で通した記録2026-10-11)）、同書の任意節「画面オフ・画面ロック・自動サスペンドを止める」、[linger](https://github.com/ryo-aoki-pc/setup-notes/blob/114c2b2bfd14b51f9e1925b150cbf72e1954f311/docs/linger.md)、[Podman](https://github.com/ryo-aoki-pc/setup-notes/blob/114c2b2bfd14b51f9e1925b150cbf72e1954f311/docs/podman.md) を通した後の状態
  - 始めの状態: `Linger=yes`、rootless の Podman 5.8.2、podman.md の Quadlet の `hello-web`（`127.0.0.1:8080`）が動いている、`~/.local/share/forgejo` は無い、firewalld は `public`（`eth0`）、sudo は NOPASSWD（`guest-facts-start.txt`）。`public` のサービスは `cockpit dhcpv6-client ssh` で、rich rule は無い（「イメージを取得して localhost で起動する」の手順 2 の出力。`session/after-confirm/0004-…-2.txt`）
- **どう通したか**
  - サーバー（主の VM）: 手順書から抜き出したブロックを、SSH の対話の bash にブラケットペーストで 1 つずつ貼った（手順書のリードの「デスクトップの端末か SSH」のうち、SSH の側）
    - 変数の 1 行（`SERVER_IP`・`LAN_SUBNET`・`FORGEJO_RESTORE`）に値を入れたほかは、1 文字も変えていない（`session/steps.jsonl` の `sha256` と `pastedSha256` が同じ）
    - コンソールでは、GNOME にログインしていない（始めも終わりも、`loginctl` の seat0 は GDM のログイン画面だけ。`guest-facts-start.txt`・`guest-facts-end.txt`）
    - sudo は、1 度もパスワードを聞かなかった
  - 「別の PC で」の端末の操作: 同じ仮想スイッチにつないだ別の VM（以下「クライアント」）で行った。手順書の箇条書きのコマンド（`<SERVER_IP>` などを置き換える形）に値を入れて 1 つの文書（`peer/peer-steps.md`）に包み、クライアントの SSH の対話の bash に貼った。「使い方の基本」の手順 7・8・9・13 は、手順書のブロックをそのまま貼った
  - 「別の PC のブラウザで」の操作: **人が画面を操作したのではない**。クライアントのヘッドレスの Firefox 140.17.0esr を、Marionette（Firefox に入っている遠隔操作の口。クライアントの `127.0.0.1:2828`）へ、標準ライブラリだけの Python のクライアント（`tools/guest/mar.py`）でつないで操作した。入れたパッケージは無い
    - 操作ごとの短いスクリプト（`peer/browser/*.py`）が、リンクやボタンを文字で探して押し、欄に文字を入れる
    - ページの移動には、リンクを押した所と、URL を直接開いた所がある。URL で開いたのは、最初のページ、`/user/login`、リポジトリ・Issue・Pull Request のページ、確かめのためのページ（`/user/sign_up`・`/install`・`/admin`・コミットの一覧など）
    - 判定は、スクリプトがページの DOM から読んだ文字（`peer/browser/*.txt`）と、ページを撮った PNG（`screens/`。44 枚）で行った
    - 担当が目で見た PNG は 6 枚（ページ 5 枚とコンソール 1 枚）と、報告にある。この付録を書いた担当が開いた PNG は 7 枚（`b03-after-install.png`・`b05-lan-home-signed-out.png`・`u10-pr-form.png`・`u12-pr-merge-confirm.png`・`x-pr-form-before-click.png`・`x-pr-form-after-click.png`・`main-console-end.png`）。この付録を点検した別の担当は、その 7 枚と、`b04-signed-out.png`・`b05-sign-up.png`・`u09-branches.png`・`u10-pr-created.png` の 4 枚を開いた。ほかは、保存されているだけ
  - パスワードを入れた所と道具（値は、どこにも載せていない）
    - OS のユーザーのパスワード（検証用の VM のもの）: クライアントの `ssh -N …` と `scp` の `password:` に、ドライバの `rb.mjs send --text-file … --mask` で、SSH の端末への文字として 2 回送った（クライアントの seq 11・51）
    - Forgejo の管理者のパスワード（この通しのために作った検証用の 20 文字）: クライアントの 0600 のファイルに写し、ブラウザのスクリプトがそこから読んで、パスワードの欄に入れた（初期設定の 2 欄と、サインインのたび）。欄の値を出す所は、長さ（`<20 chars>`）だけにしてある
    - VM のコンソールへのキー送信は、1 度も使っていない（担当の報告による）
    - 実アカウントでのログインは無い
- **誰が**: 通したのは、検証の担当のエージェント（Claude Code のサブエージェント）。この付録は、その報告（`result.md`）と証跡のファイルを、VM に触れない別の担当が照らし合わせて書いた。書いた後に、もう 1 人の別の担当が、付録と手順書の直しを証跡に当てて点検し、違う所を直した（どちらも、VM では何も実行していない）
- **証跡**: 追跡していない `.verification/campaign/hv/R5/`（このリポジトリには入っていない）。下のファイルの名前は、ここからの相対パス
  - `seq` は、主の VM が `session/steps.jsonl`、クライアントが `peer/session/steps.jsonl` の番号。`after-confirm/` は、それぞれの `session/after-confirm/`。ブラウザの操作は `peer/browser/<名前>.py`（操作）と `<名前>.txt`（出力）で、下では `b01` のように名前だけを書く
- 出力の中の VM の値は、`<USER>`・`<HOSTNAME>`・`<SERVER_IP>`・`<LAN_SUBNET>`・`<FORGEJO_USER>`・`<FINGERPRINT>`・`<PID>` で書いた。コミットの ID は試験の値で、利用者の実行結果と一致する必要はない。パスワードと鍵は載せていない

### 環境（Hyper-V、2026-10-11）

| 項目 | 内容 |
|---|---|
| ホスト | Windows 11 Pro 10.0.26300 |
| ハイパーバイザ | Hyper-V（担当の報告では `vmms.exe` 10.0.26100.8875）。層の `Get-VmvBackend` は `Generation=2`・`Version=12.0`・`HypervisorPresent=True`（`meta.json`） |
| 主の VM（サーバー） | 第 2 世代（UEFI）、Secure Boot オフ、2 vCPU、3072 MB（ゲストから見えるのは 2900 MB）、ディスク 64 GB、NIC 1 枚（`eth0`）。ディスクが SCSI の差分であること、NIC が Default Switch であることは、担当の報告による |
| クライアント（別の PC の役） | 同じ構成で 2048 MB（ゲストから見えるのは 1639 MB）。Kickstart で入れたベースのスナップショット `clean-install` のクローンで、初期設定は通していない（プロンプトは素の bash）。担当の報告では、同じ日の gnome-headless-session.md と gnome-remote-desktop.md の通しで相手の役に使った VM を、そのまま起動した。始めの状態は、`freerdp` が入っていて、`~/.ssh` に鍵は無く、`~/.gitconfig` も無い（`peer/guest-facts-start.txt`） |
| ゲスト | 2 台とも AlmaLinux 10.2 (Lavender Lion)、kernel `6.12.0-211.64.1.el10_2.x86_64`、x86_64、SELinux Enforcing（`meta.json`・`peer/meta.json`・`guest-facts-start.txt`・`peer/guest-facts-start.txt`）。主の VM は firewalld 有効（`public`、`eth0`）。出力は 2 台とも日本語 |
| 主の VM に入っていた版 | `podman-5.8.2-9.el10_2.alma.1`・`passt-0^20251210.gd04c480-7.el10_2`・`crun-1.27-2.el10_2`・`aardvark-dns-1.17.1-1.el10_2`・`netavark-1.17.2-1.el10`・`container-selinux-2.248.0-1.el10_2`・`firewalld-2.4.3-4.el10_2`・`systemd-257-23.el10_2.2.alma.1`・`python3-3.12.15-1.el10_2`・`openssh-server-9.9p1-28.el10_2.alma.1`（`guest-facts-start.txt`・`guest-facts-end.txt`） |
| 主の VM の PATH | 対話のシェルでは、`python3` と `curl` は Homebrew のものが先に見つかる（初期設定を通した後なので。`guest-facts-start.txt` の `type -a`）。手順書のブロックは `/usr/bin/python3` と書いているので、Python は OS の 3.12.15 が動く。`curl` は「イメージを取得して localhost で起動する」の手順 5 だけで、Homebrew のものに解決される |
| Forgejo | `codeberg.org/forgejo/forgejo:16.0.5-rootless`（イメージ ID `87fb96a25b00…`、188 MB）。`forgejo version 16.0.5+gitea-1.22.0 (release name 16.0.5) built with GNU Make 4.4.1, go1.26.8 : bindata, timetzdata, sqlite, sqlite_unlock_notify` |
| クライアントの版 | `firefox-140.17.0-1.el10_2`（`Mozilla Firefox 140.17.0esr`。ヘッドレス、専用のプロファイル）、`git-2.52.0-1.el10`、`openssh-clients-9.9p1-28.el10_2.alma.1`、`python3-3.12.15-1.el10_2`（`peer/guest-facts-start.txt`） |
| クライアントの Git | リードの前提「Git の確認に使う PC は、先に Git を通す」として、[初期設定の「Git」](../almalinux-setup.md#git)の手順 1〜6 を、この通しの初めに貼った（`pull.rebase=true` など 14 個が `global`、`pull.ff` は空。クライアントの seq 1〜8、`peer/session/after-confirm/0008-実施手順-Git-6.txt`）。手順 7 は条件に当たらず、手順 8〜10 は貼っていない |
| 手順書 | `docs/forgejo.md`、コミット `114c2b2`（`114c2b2bfd14b51f9e1925b150cbf72e1954f311`。`steps.jsonl` の `docCommit`） |
| 実施の日時 | 2026-10-11 12:03:38〜12:21:57 UTC（ゲストの時計で 21:03〜21:21 JST。`steps.jsonl`）。担当の報告では、VM の用意からスナップショットまでが 12:00〜12:23 UTC |
| 貼り方 | ドライバ（`rb.mjs paste`）で、SSH の対話の bash にブラケットペーストで 1 ブロックずつ（主の VM に 34 回、クライアントに 39 回） |
| 検証用の値 | `SERVER_IP` は主の VM の IP（Default Switch の DHCP が配ったもの。**固定ではない**）。`LAN_SUBNET` は、クライアントの IP を含み、Windows のホストの IP と主の VM 自身を含まない `/24`（許可外の送信元を作るため）。ポートは既定（3000・2222）、`FW_ZONE` は自動で入った `public`。Forgejo の管理者と、Git の名前・メールアドレスは、検証用の値（メールアドレスは `example.invalid`） |

### 手順ごとの結果（Hyper-V、2026-10-11）

- 判定の「ブラウザはスクリプトで操作」は、手順書の「ブラウザで」の操作を、上の Marionette のスクリプトで行ったもの。押したボタンとリンクの名前は、下の表に書いた
- 時間は、`steps.jsonl` の `durationMs`（出力が止まってからドライバが待つ 1.7〜1.8 秒を含む）

**実施手順（26 手順。通した 26）**:

| 項 | 手順 | 判定 | 出力と、確かめたこと | 根拠 |
|---|---|---|---|---|
| イメージを取得して localhost で起動する | 1 | 通した | `待ち受け: <SERVER_IP>`・`許可する送信元: <LAN_SUBNET>`・`Web: 3000 / SSH: 2222`・`firewalld: public` | 主の seq 1〜3、`after-confirm/0003-実施手順-イメージを取得して_localhost_で起動する-1.txt` |
| 〃 | 2 | 通した | `IPv4・CIDR・ポートの確認: OK`、`running`、`public (default)` に `eth0`（`FW_ZONE` と同じ）、`target: default`、`導入する版: 16.0.5`、取得の行、`forgejo version 16.0.5+gitea-1.22.0 …`。15.7 秒（プロンプトの表示は `took 13s`） | 主の seq 4、`after-confirm/0004-…-2.txt` |
| 〃 | 3 | 通した | 何も出ない。別の SSH で見ると、`forgejo.container` は 600（1198 バイト）、`~/.local/share/forgejo` は 700。定義は本文のとおり（`Image=codeberg.org/forgejo/forgejo:16.0.5-rootless`、`PublishPort=127.0.0.1:3000:3000`・`127.0.0.1:2222:2222`） | 主の seq 5、`facts-after-step3.txt` |
| 〃 | 4 | 通した | `active`・`generated`・`uid=1000(git) gid=1000(git) groups=1000(git)`。`Failed to connect to user scope bus` は出ていない | 主の seq 6、`after-confirm/0006-…-4.txt` |
| 〃 | 5 | 通した | `200`、`2222/tcp -> 127.0.0.1:2222`・`3000/tcp -> 127.0.0.1:3000`、`ss` も `127.0.0.1` の 2 行だけ | 主の seq 7、`after-confirm/0007-…-5.txt` |
| 初期設定と管理者の作成 | 1 | 通した | クライアントの端末で `ssh -N -o ExitOnForwardFailure=yes -L 127.0.0.1:3000:127.0.0.1:3000 <USER>@<SERVER_IP>`。初めての接続なので、ホストの SSH の ED25519 の指紋を聞かれ（`yes`）、続けて OS のパスワードを聞かれた。その後は、何も出さずに開いたままになった | クライアントの seq 9〜11、`peer/session/session-001.raw`、主の seq 8（メモ） |
| 〃 | 2 | 通した（ブラウザはスクリプトで操作） | 下の「初期設定の画面」 | `b01`〜`b04`、`screens/b01-…`〜`b04-…`、主の seq 9（メモ） |
| 〃 | 3 | 通した | `初期設定画面の閉鎖・自己登録拒否・OpenID 入口なし・healthz・有効な管理者: OK`、見出しの行（`ID`・`Username`・`Email`・`IsActive`）と、作った管理者の 1 行（`IsActive` は `true`） | 主の seq 10、`after-confirm/0010-実施手順-初期設定と管理者の作成-3.txt` |
| LAN に公開する | 1 | 通した | `success` が 4 行。permanent と runtime のどちらにも、`rule priority="100" family="ipv4" source address="<LAN_SUBNET>" destination address="<SERVER_IP>" port port="2222" protocol="tcp" accept` と、`port="3000"` の行の 2 規則。3.5 秒 | 主の seq 11、`after-confirm/0011-実施手順-LAN_に公開する-1.txt` |
| 〃 | 2 | 通した | `初期設定画面の閉鎖・…: OK`、`LAN 用の待ち受けと URL: 設定済み`、`active`、`2222/tcp -> <SERVER_IP>:2222`・`3000/tcp -> <SERVER_IP>:3000`。別の SSH で見ると、`ss` は `<SERVER_IP>` の 2 行だけ（`0.0.0.0`・`[::]` は無い）、定義は 600 のまま、`127.0.0.1:3000` はつながらない | 主の seq 12、`after-confirm/0012-…-2.txt`、`facts-after-lan-step2.txt` |
| 〃 | 3 | 通した（ブラウザはスクリプトで操作。許可外の送信元は Windows のホスト） | 下の「LAN の URL での確かめ」 | クライアントの seq 12、`b05`・`b05b`、`screens/b05-…`、`outside-source-check-lan-step3.txt`、主の seq 13（メモ） |
| Git の接続を確かめる | 1 | 通した（ブラウザはスクリプトで操作） | クライアントで `ssh-keygen -t ed25519`（保存先は既定、パスフレーズは空で、Enter を 3 回）。アカウントメニューの「Settings」→「SSH / GPG keys」→「Manage SSH keys」の「Add key」→ 名前と `.pub` の中身 →「Add key」。`The SSH key "<鍵の名前>" has been added.` と出て、一覧に名前と指紋（クライアントの `ssh-keygen` が出した指紋と同じ） | クライアントの seq 13〜16、`b06`、`screens/b06-…`、主の seq 14（メモ） |
| 〃 | 2 | 通した | `4096 SHA256:<FINGERPRINT> no comment (RSA)` の 1 行 | 主の seq 15、`after-confirm/0015-実施手順-Git_の接続を確かめる-2.txt` |
| 〃 | 3 | 通した | `RSA key fingerprint is SHA256:<FINGERPRINT>.`（同じ項の手順 2 と同じ値）→ `yes` → `Hi there, <FORGEJO_USER>! You've successfully authenticated with the key named <鍵の名前>, but Forgejo does not provide shell access.`。パスワードは聞かれない | クライアントの seq 17・18、`peer/session/session-001.raw`、主の seq 16（メモ） |
| 〃 | 4 | 通した（ブラウザはスクリプトで操作） | 右上の `+` →「New repository」→ `forgejo-test`、「Make repository private」と「Initialize repository」をオン →「Create repository」。`Private`・`main`・`README.md`。「SSH」の clone URL は `ssh://git@<SERVER_IP>:2222/<FORGEJO_USER>/forgejo-test.git` | `b07`、`screens/b07-…`、主の seq 17（メモ） |
| 〃 | 5 | 通した | 空の作業場所で clone → `connection-check.txt` → add → commit（`ad313f5`）→ push（`54e55ea..ad313f5  main -> main`）。ブラウザのファイルの一覧に `README.md`・`connection-check.txt`、コミットの一覧に `ad313f5930 Forgejo の接続確認` と `54e55eaf29 Initial commit` | クライアントの seq 19〜25、`b08`、`screens/b08-…`、主の seq 18（メモ） |
| 再起動しても残ることを確かめる | 1 | 通した | `active`、`2222/tcp -> <SERVER_IP>:2222`・`3000/tcp -> <SERVER_IP>:3000` | 主の seq 19、`after-confirm/0019-実施手順-再起動しても残ることを確かめる-1.txt` |
| 〃 | 2 | 通した（ブラウザはスクリプトで操作） | サービスの再起動（`ActiveEnterTimestamp` は 21:11:59 JST）の 2 秒後（21:12:01）から、サインアウト → サインイン。`forgejo-test` と `ad313f5` が残っていた。`git fetch` は、ホスト鍵の確認を求めずに戻った | `b09`、クライアントの seq 26、`facts-logout-step3.txt`（`ActiveEnterTimestamp`）、主の seq 23（メモ） |
| 〃 | 3 | 通した（ブラウザはスクリプトで操作） | 主の VM の `<USER>` の SSH を全部閉じた（コンソールは GDM のログイン画面のまま）。logind の記録では、`Removed session 6.` が 21:12:21.674、次の `New session 28 of user <USER>.` が 21:12:44.990 JST で、その 23 秒のあいだ、このユーザーに残るのは linger の `manager` のセッションだけ。そのあいだの 21:12:22〜21:12:30 に、クライアントから Web のサインインと `git fetch` が通った。`sleep.target` と `suspend.target` が `masked` であることは、担当の報告による | `facts-logout-step3.txt`、`b10`、クライアントの seq 27・28、主の seq 24（メモ） |
| 〃 | 4 | 通した | ポート 22 の SSH で `<USER>` にログインし直し、「イメージを取得して localhost で起動する」の手順 1 の 3 つのブロックを貼り直した | 主の seq 20〜22、`after-confirm/0022-…-1.txt`、主の seq 25（メモ） |
| 〃 | 5 | 通した | `sudo systemctl reboot`。パスワードは聞かれず、`The system will reboot now!` の後に SSH が切れた。再起動したことは、`systemd-analyze` の行と、起動から 5.47 秒の `ActiveEnterTimestampMonotonic` で読める | 主の seq 26・27、`session/session-002.raw`、`facts-after-reboot.txt` |
| 〃 | 6 | 通した | 変数を貼り直してから貼った。`active`・`generated`・`ActiveEnterTimestamp=Sun 2026-10-11 21:13:19 JST`・`Timestamp=Sun 2026-10-11 21:13:20 JST`・`Linger=yes`、LAN 向けの 2 つのポート、2 規則。サービスの起動が、ログインの 1 秒前 | 主の seq 28〜31、`after-confirm/0031-実施手順-再起動しても残ることを確かめる-6.txt`、`facts-after-reboot.txt` |
| 〃 | 7 | 通した（ブラウザはスクリプトで操作。許可外の送信元は Windows のホスト） | サインアウト → サインイン。`forgejo-test` と `ad313f5` が残っていた。`git fetch` は、何も聞かずに戻った。許可外の送信元からは、3000・2222 とも 5 秒でつながらず、22 はつながった。IP は `<SERVER_IP>` のまま | `b11`、クライアントの seq 29、`outside-source-check-after-reboot.txt`、主の seq 32（メモ） |
| 自動更新を有効にする | 1 | 通した | `-rwx------. 1 <USER> <USER> 13149 … /home/<USER>/.local/bin/forgejo-auto-update`。置かれたファイルの sha256 と行数（318 行）は、本文のヒアドキュメントの中身と同じ（この付録を書くときに、`114c2b2` の本文から計算して比べた） | 主の seq 33、`after-confirm/0033-実施手順-自動更新を有効にする-1.txt`、`facts-after-autoupdate.txt` |
| 〃 | 2 | 通した | 何も表示されない | 主の seq 34、`after-confirm/0034-…-2.txt` |
| 〃 | 3 | 通した | `Result=success`・`ExecMainStatus=0`、`forgejo-auto-update[<PID>]: 最新版 16.0.5 を使用中`、`NEXT` は `Mon 2026-10-12 04:16:23 JST`、最後の行は `forgejo version 16.0.5+…`。4.2 秒。タイマーは `enabled`・`active` | 主の seq 35、`after-confirm/0035-…-3.txt`、`facts-after-autoupdate.txt` |

- **初期設定の画面**（「初期設定と管理者の作成」の手順 2）
  - `http://localhost:3000/` は、ブラウザの言語（日本語。`<html lang="ja-JP">`、題は「インストール - Forgejo: Beyond coding. We forge.」）で開いた
  - 画面下部の言語メニューを開いて「English」を押すと、英語になった（`Installation - …`、`en-US`）
  - 欄の値は、箇条書きのとおり: Database type は SQLite3、Path は `/var/lib/gitea/data/forgejo.db`、Server domain は `localhost`、SSH server port は `2222`、HTTP listen port は `3000`、Base URL は `http://localhost:3000/`
  - 自己登録を無効にする項目は、最初からオンだった。OpenID のサインインと登録の項目は最初からオフ、閲覧にサインインを求める項目は最初からオン（`b02-install-english.txt` の `disable_registration`・`enable_open_id_sign_in`・`enable_open_id_sign_up`・`require_sign_in_view`）
  - 「Administrator account settings」を開いて、ユーザー名・メールアドレス・パスワード（2 欄）を入れ、「Install Forgejo」を押すと、5 秒後に `http://localhost:3000/` が `<FORGEJO_USER> - Dashboard` になった。**パスワードを聞かれずに、作った管理者でログインした状態になる**（`b03-install-submit.txt`、`screens/b03-after-install.png`）
  - 「ログインできること」は、アカウントメニューの「Sign out」→ `/user/login` でユーザー名とパスワード →「Sign in」で確かめた（ダッシュボードと `/admin` が開いた。`b04-relogin-tunnel.txt`）
- **LAN の URL での確かめ**（「LAN に公開する」の手順 3）
  - 同じ項の手順 2 を貼った（12:07:50 UTC）2 秒後から、開いたままのトンネルの端末に `channel 1: open failed: connect failed: Connection refused` が出始め、`Ctrl+C`（12:08:09）までの 16 秒に 71 行出た（`peer/session/session-001.raw`）。`Ctrl+C` でプロンプトに戻った
    - 71 行のうち 70 行は、2〜3 秒おきに 10 行ずつの 7 回。残りの 1 行は、12:08:08.9 に単独で出た（何の接続かは、証跡からは分からない）
    - このあいだ、クライアントのブラウザは `http://localhost:3000/admin` を開いたままだった（ブラウザの直前の操作は、`b04` の最後の `/admin`。次の `b05` は、トンネルを閉じた後。証跡の `b05-lan-login.txt` が書かれた時刻は 12:08:12 UTC）
  - LAN の URL は、サインインの前は日本語で出た（`ja-JP`）。上部は「エクスプローラー・ヘルプ・サインイン」だけで、登録のボタンは無い（`screens/b05-lan-home-signed-out.png`）
  - `/user/sign_up` は「登録は無効になっています。 サイト管理者にお問い合わせください。」で、入力欄が無く、OpenID へのリンクも無い。`/user/login/openid` は `Forbidden`。`/install` と、匿名でのプロフィールの閲覧は、`/user/login` へ移った
  - 管理者でサインインでき（サインインの後は `en-US`）、`/admin` が開いた
  - 許可外の送信元（Windows のホスト。`LAN_SUBNET` の外の IP）からは、3000・2222 とも 5 秒でつながらなかった（時間切れ）。同じ時に、22 は 10 ミリ秒でつながった。クライアント（`LAN_SUBNET` の中）からは、3000・2222 ともつながった
- 通していない分岐: 各手順の `中断:` の側（変数が空・既存の構築がある・同じ規則がある・Quadlet が違う、など）、`Failed to connect to user scope bus` のときの `--machine=`、`LAN_SUBNET='0.0.0.0/0'`、ポートを変えた場合、`FW_ZONE` が既定と違う場合、自動更新が版を上げる側（`更新:`）
- 「自動更新を有効にする」の手順 3 の `NEXT` は、終わりに読むと `Mon 2026-10-12 04:18:56 JST` に変わっていた（`guest-facts-end.txt`。あいだに「バックアップから復元する」の手順 5 の `daemon-reload` がある。ランダムな遅れが引き直されたとみるが、確かめていない）

**使い方の基本（13 手順。通した 11、条件に当たらず飛ばした 2）**: 全部、クライアント（利用する PC の役）で行った。端末のブロックは `~/forgejo-work/forgejo-demo` の中で貼った。

| 手順 | 判定 | 出力と、確かめたこと | 根拠 |
|---|---|---|---|
| 1 | 通した（ブラウザはスクリプトで操作） | Cookie を消した状態（初めて開くブラウザと同じ）で `http://<SERVER_IP>:3000/` を開くと、日本語（`ja-JP`）で出た。画面下部の言語メニューで「English」→ 上部の「Sign in」→「Username or email address」と「Password」→「Sign in」→ ダッシュボード | `u01`、`screens/u01-…`、クライアントの seq 38（メモ） |
| 2 | 条件に当たらず飛ばした | 「Git の接続を確かめる」の手順 1 で、同じ Forgejo アカウントに同じ PC の鍵を登録済み | `b06`、クライアントの seq 39（メモ） |
| 3 | 条件に当たらず飛ばした | 同じサーバーへ照合済み（「Git の接続を確かめる」の手順 3） | クライアントの seq 17・18・40（メモ） |
| 4 | 通した（ブラウザはスクリプトで操作） | `+` →「New repository」→ Owner は管理者、`forgejo-demo`、「Make repository private」と「Initialize repository」をオン。「Advanced settings」は畳まれたまま（「Click to expand」）で、「Default branch」の値は最初から `main`。「Create repository」→ `Private`・`main`・`README.md` | `u04`、`screens/u04-…`、クライアントの seq 41（メモ） |
| 5 | 通した | 画面の「SSH」の URL は `ssh://git@<SERVER_IP>:2222/<FORGEJO_USER>/forgejo-demo.git`。clone → `cd forgejo-demo` → `git status` は `On branch main`・`nothing to commit, working tree clean`。指紋は聞かれない（照合済み） | クライアントの seq 30〜33、`peer/session/session-001.raw` |
| 6 | 通した（ブラウザはスクリプトで操作） | 「Issues」→「New issue」→ タイトル「README に使い方を追加する」と本文 →「Create issue」。`#1`・`Open` | `u06`、`screens/u06-…`、クライアントの seq 43（メモ） |
| 7 | 通した | `Already on 'main'`・`Already up to date.`・`Switched to a new branch 'docs/readme-guide'`。クライアントの Git は `pull.rebase=true`（初期設定の「Git」）で、`git pull --ff-only` は通った | クライアントの seq 34、`peer/session/session-001.raw` |
| 8 | 通した | 差分は `README.md` の 4 行の追加だけ（空行・`## 使い方`・空行・`Git で clone して作業用ブランチを作成します。`） | クライアントの seq 35、`peer/session/after-confirm/0035-使い方の基本-8.txt` |
| 9 | 通した | `[docs/readme-guide b6145e0] README に使い方を追加`、`* [new branch]      docs/readme-guide -> docs/readme-guide`。push の出力に、`remote: Create a new pull request for 'docs/readme-guide':` と、比較の画面の URL が出た。ブラウザのブランチの一覧に `docs/readme-guide` | クライアントの seq 36、`peer/session/session-001.raw`、`u10-pr-open.txt`、`screens/u09-branches.png` |
| 10 | 通した（ブラウザはスクリプトで操作。箇条書きに無い操作が 1 つ要った） | 下の「Pull Request を作る画面」 | `u10-pr-open`・`u10-pr-create`・`x-pr-form-visible`、`screens/u10-…`・`x-pr-form-…`、クライアントの seq 44（メモ） |
| 11 | 通した（ブラウザはスクリプトで操作） | 「Files changed」: `README.md` だけ、`1 changed files with 4 additions and 0 deletions`、追加は手順 8 の 4 行。直して push し直す・レビュー・CI は行っていない | `u11-pr-files-merge.txt`、`screens/u11-pr-files-changed.png` |
| 12 | 通した（ブラウザはスクリプトで操作） | 「Conversation」の「Create merge commit」→ 確認フォーム（ボタンは「Create merge commit」と「Cancel」）→「Create merge commit」。`Merged`、`Pull request successfully merged and closed`、`merged commit 41d1e72074 into main`。Issue #1 は `Closed`。main の README に「使い方」 | `u11-pr-files-merge.txt`、`screens/u12-…` |
| 13 | 通した | `Updating 248c775..41d1e72`・`Fast-forward`、`41d1e72 (HEAD -> main, origin/main, origin/HEAD) Merge pull request 'README に使い方を追加' (#2) from docs/readme-guide into main` | クライアントの seq 37、`peer/session/after-confirm/0037-使い方の基本-13.txt` |

- **Pull Request を作る画面**（手順 10）
  - 「Pull requests」→「New pull request」で、比較の画面（`compare/main...main`。`merge into` も `pull from` も `main`）が開いた
  - 「pull from」のメニューで `docs/readme-guide` を選ぶと、URL が `compare/main...docs/readme-guide` になり、下にコミットの一覧と差分が出た。**この時点では、タイトルと本文の欄は出ていない**（その上に「New pull request」のボタンがある）
  - その「New pull request」を押すと、タイトルと本文の欄と「Create pull request」が出た。タイトルには、コミットの件名「README に使い方を追加」が最初から入っていた
  - 本文に目的・内容・確認結果と `Closes #1` を入れて「Create pull request」→ `#2`・`Open`・`wants to merge 1 commit from docs/readme-guide into main`（`screens/u10-pr-form.png`・`u10-pr-created.png`）
  - 欄が出る前と後は、マージの後に、別のブランチ（`docs/form-check`。手順書の外）で確かめ直してある。ブランチを選んだ直後は、タイトルの欄が見えず、ボタンは「New pull request」だけ。押した後は見えて、ボタンは「Create pull request」（`x-pr-form-visible.txt`、`screens/x-pr-form-before-click.png`・`x-pr-form-after-click.png`）

**バックアップ（4 手順。通した 4。手順 4 は代わりの形）**:

| 手順 | 判定 | 出力と、確かめたこと | 根拠 |
|---|---|---|---|
| 1 | 通した | `ActiveState=inactive`・`SubState=dead`、`podman ps` は見出しだけ | 主の seq 36、`after-confirm/0036-バックアップ-1.txt` |
| 2 | 通した | `700 /home/<USER>/.local/state/forgejo-backups`・`600 …/forgejo-20261011T121808Z.tar.gz`・`バックアップ: /home/<USER>/.local/state/forgejo-backups/forgejo-20261011T121808Z.tar.gz`。98148 バイト、157 項目（名前の一覧だけを読んだ）。止めているあいだ、Web は応答しない | 主の seq 37、`after-confirm/0037-バックアップ-2.txt`、`facts-backup1.txt` |
| 3 | 通した | `active`。クライアントから、サインインと 2 つのリポジトリ（`forgejo-test` の `ad313f5`、`forgejo-demo` の `41d1e72`）、`git fetch` | 主の seq 38、`after-confirm/0038-バックアップ-3.txt`、`k03-after-backup-start.txt`、クライアントの seq 47・48 |
| 4 | 通した（代わりの形） | コードブロックの無い手順。クライアントに 700 のディレクトリを作り、`scp -p` でアーカイブをコピーした（OS のパスワードを聞かれた）。コピー先は `700`・`600`。**同じ PC の上の VM なので、「サーバーのディスクを失っても残る保管先」ではない**。アーカイブを暗号化しての保管は行っていない | クライアントの seq 49〜52、`peer/session/session-001.raw`、主の seq 39（メモ） |

- 止めていたのは 6 秒ほど（手順 1 を貼った 12:18:05 UTC から、手順 3 の `active` が出た 12:18:11 まで。`session/session-003.raw`）
- 手順 4 のコピーの sha256 が元のファイルと同じであることと、写しを終わりに消したことは、担当の報告による（証跡にあるのは、コピー先の sha256 だけ）

**バックアップから復元する（7 手順。通した 6、条件に当たらず飛ばした 1）**: 復元で戻ることが分かるように、バックアップの後に `forgejo-test` へコミットを 1 つ足して push した（`4da4bea`。手順書の外。クライアントの seq 53）。リードの「先に現在の状態をバックアップする」は、「バックアップ」の手順 1〜3 をもう 1 回貼って行った（主の seq 40〜42。`forgejo-20261011T121929Z.tar.gz`、100467 バイト）。

| 手順 | 判定 | 出力と、確かめたこと | 根拠 |
|---|---|---|---|
| 1 | 通した | `FORGEJO_RESTORE` に、1 つ目のバックアップの絶対パスを入れた | 主の seq 43 |
| 2 | 通した | `復元するイメージ: codeberg.org/forgejo/forgejo:16.0.5-rootless`、取得の行（どの層も `skipped: already exists`）、`forgejo version 16.0.5+…`、`初期設定画面の閉鎖・…: OK`、`復元前のファイル・版・隔離環境での実効確認: OK`。8.2 秒。別の SSH で見ると、検証用のコンテナとネットワークは残っていない（`podman network ls` は `podman` だけ）。動いている Forgejo は `active` のまま | 主の seq 44、`after-confirm/0044-バックアップから復元する-2.txt`、`facts-restore-after-step2.txt` |
| 3 | 通した | `ActiveState=inactive`・`SubState=dead`、`podman ps` は見出しだけ | 主の seq 45、`after-confirm/0045-…-3.txt` |
| 4 | 通した | `復元前の退避: /home/<USER>/.local/state/forgejo-backups/before-restore-<8 文字>`（中に `data` と `forgejo.container`）。`~/.local/share/forgejo` は 700、`forgejo.container` は 600 | 主の seq 46、`after-confirm/0046-…-4.txt`、`facts-restore-after-step5.txt` |
| 5 | 通した | `active`、`forgejo version 16.0.5+…`。別の SSH で見ると、データのラベルは `container_file_t:s0:c206,c273`、`healthz` は 200、Git 用 SSH のホスト鍵の指紋は「Git の接続を確かめる」の手順 2 と同じ | 主の seq 47、`after-confirm/0047-…-5.txt`、`facts-restore-after-step5.txt` |
| 6 | 通した（ブラウザはスクリプトで操作。許可外の送信元は Windows のホスト） | 下の「復元の後の確かめ」 | `r06-after-restore.txt`、`screens/r06-…`、クライアントの seq 54〜57、`outside-source-check-after-restore.txt`、主の seq 48（メモ） |
| 7 | 条件に当たらず飛ばした | 新しい版の不具合で戻したのではない。退避した定義と、復元した定義の `Image=` は、どちらも `16.0.5-rootless`（貼っていない） | `facts-restore-after-step5.txt`、主の seq 49（メモ） |

- **復元の後の確かめ**（手順 6）
  - Web: サインインできた。`forgejo-test` は `ad313f5`（バックアップの後に足した `4da4bea` は無い）、`forgejo-demo` は `41d1e72` で PR #2 は `Merged` のまま、登録した SSH の鍵も残っていた
  - `/install` は、サインインの前は `/user/login` へ移り、サインインの後は `Page not found`。`/user/sign_up`（`?openid` を付けても）は `Registration is disabled. Please contact your site administrator.` で、入力欄が無い。`/user/login/openid` は `Forbidden`
  - 端末（バックアップの後のコミットを持つ、もとの clone）: `git fetch` は `+ 4da4bea...ad313f5 main       -> origin/main  (forced update)`、`git status -sb` は `## main...origin/main [ahead 1]`。この clone からは push していない
  - 端末（新しい場所へ clone し直した）: `ad313f5`、`README.md  connection-check.txt`。`restore-check.txt` を commit して push した（`ad313f5..5c2f1db  main -> main`）
  - Git 用 SSH の指紋は、取り寄せ直したもの（`ssh-keyscan`）も、クライアントの `known_hosts` のものも、バックアップの前と同じ値。ホスト鍵の確認は求められなかった
  - 許可外の送信元からは、3000・2222 とも 5 秒でつながらなかった（22 はつながった）
  - 退避と、展開用の作業場所は、消していない
- 止めていたのは 6 秒ほど（手順 3 を貼った 12:20:02 UTC から、手順 5 の `active` が出た 12:20:08 まで。`session/session-003.raw`）
- 通していない分岐: 異なる版のバックアップを戻す側（DB の移行の後の復元）、手順 7 の `保留:` と `中断:` の側、自動更新のアーカイブ（`forgejo-auto-*`）を戻す側、`中断: 自動更新の実行中`

### 通らなかった手順と、手順書の前提と違えた所（Hyper-V、2026-10-11）

通らなかった手順は無い。手順書の前提や書く形と違えた所と、見立ては、次のとおり。

- **手順書の前提と違えた所**
  - リードの「サーバーの IPv4 が固定されていること」: 満たしていない。主の VM の IP は、Default Switch の DHCP が配ったものを、そのまま `SERVER_IP` に使った。通しのあいだは、ゲストを再起動しても変わらなかった
  - 「別の PC のブラウザで」: 人の手ではなく、クライアントのヘッドレスの Firefox をスクリプトで操作した。窓のあるブラウザ、マウスとキーボード、クリップボードへのコピーは、通していない
  - 「バックアップ」の手順 4: 同じ PC の上の別の VM へ `scp` でコピーした。別のディスク・別の PC・暗号化しての保管は、通していない
  - 許可外の送信元: VM を動かしている Windows の PC（同じ仮想スイッチの、`LAN_SUBNET` の外の IP）から、TCP の接続だけを試した（何も送っていない。PowerShell の `System.Net.Sockets.TcpClient` を使った、と担当の報告にある）
- **SSH から貼ったせい**: 無い。手順書は「デスクトップの端末か SSH」と書いている。「再起動しても残ることを確かめる」の手順 6 の `XDG_SESSION_ID` は、SSH のセッションでも入っていた（`Timestamp=` が出た）
- **Hyper-V のせい**: 確認の出力が変わった所は無い。値として変わるのは、`/20` の IP と、許可外の送信元からの接続が「拒否」ではなく「時間切れ」に見えたこと（[下の表](#hyper-v-に左右されたと思われる値2026-10-11)）
- **手順書のせい**: 通らなかった所は無い。箇条書きに無い操作が 1 つ（「使い方の基本」の手順 10）、箇条書きから読み取れない動きが 3 つ（「初期設定と管理者の作成」の手順 2、「LAN に公開する」の手順 3、「バックアップから復元する」の手順 6）。どれも[指摘と状態](#指摘と状態hyper-v2026-10-11)
- **道具のせい**（手順書ではない）
  - ブラウザのスクリプトが、途中で止まったことがある。`b05` は、サインインのボタンを英語の文字で探して、日本語の画面で見つけられずに止まった（パスワードの欄に入れた後、送信する前）。`u10-pr-open` は、比較の画面を開いた後に、スクリプトの誤り（JavaScript の `TypeError`）で止まった。どちらも、直したスクリプトで続けた（`b05b`・`u10-pr-create`）。担当の報告では、`b07` も、最初の回は、欄の名前の誤りで何も入れる前に止まった（その回の出力は、証跡に無い）
  - 「再起動しても残ることを確かめる」の手順 6 の 2 つの時刻が 1 秒しか違わないのは、ドライバが再起動の直後につなぎ直したため

### 手順書の外で行ったこと（Hyper-V、2026-10-11）

- クライアントの準備: 初期設定の「Git」の手順 1〜6（上の表）と、空の作業場所 `~/forgejo-work`
- ブラウザの道具: クライアントに、Marionette のクライアント（`tools/guest/mar.py`）と操作ごとのスクリプトを `scp` で送り、別の SSH から動かした。「使い方の基本」の手順 1 の前に、ブラウザの Cookie を全部消した（初めて開く状態にして、言語メニューの案内を確かめるため）
- `ssh-keygen`: 保存先は既定、パスフレーズは空
- 復元を見分けるための操作: バックアップの後のコミット（`4da4bea`）、復元の前の 2 つ目のバックアップ、新しい場所への clone、`ssh-keyscan` での指紋の取り寄せ。箇条書きのコマンドに `mkdir`・`cd`・`git status -sb`・`git log`・`ls`・`sha256sum`・`stat` を足した所は、`peer/peer-steps.md` に「手順書の外」と書いてある
- 範囲の外の確かめ: 比較の画面で入力欄が出るかを見るために、`forgejo-demo` にブランチ `docs/form-check`（コミット 1 つ）を push した。Pull Request は作っていない。担当の報告では、このブランチは、通しの終わりのスナップショットに残っている
- 別の SSH（鍵で、パスワードなし）で、状態を読んだ（`facts-*.txt`・`guest-facts-*.txt`）。`app.ini` とアーカイブの中身は読んでいない（`forgejo.container` と、アーカイブの名前の一覧だけ）
- 終わりの片付け（担当の報告による。証跡の `peer/guest-facts-end.txt` は、片付けの前の状態）: クライアントの Firefox を止め、ブラウザの道具・プロファイル・検証用のパスワードの写しと、バックアップの写しを消した。クライアントに残したのは、`~/.gitconfig`、パスフレーズ無しの鍵の組（この通しの Forgejo にだけ登録した）、`known_hosts` の行、`~/forgejo-work`
- 画面の PNG を撮った（主の VM とクライアントのコンソールを 1 枚ずつ、終わりに）

### Hyper-V に左右されたと思われる値（2026-10-11）

担当の報告が挙げた値を、証跡と照らして、値のまま並べた。ほかのハイパーバイザや実機と比べて確かめたものではない。時間は、静かなホストで測ったものではない（担当の報告では、同じ時刻に、ほかの単位の VM が同じホストで動いていた）。性能の比べには使わない。

| 項目 | 値 |
|---|---|
| `systemd-detect-virt` | `microsoft`。`hostnamectl` は `Chassis: vm`・`Hardware Vendor: Microsoft Corporation`・`Hardware Model: Virtual Machine`・`Firmware Version: Hyper-V UEFI Release v4.1`（`guest-facts-end.txt`） |
| NIC と IP | 2 台とも `eth0` で、アドレスは `/20`。主の VM は `<SERVER_IP>/20`（DHCP。ゲストを再起動した後も同じ。`facts-after-reboot.txt`）。この通しの後、止めてあった VM を 12:45 UTC に起動し直したときも、同じ IP だった（`.verification/campaign/hv/AVC-recheck/` の、この VM の `meta.json`）。既定の経路は Windows のホスト。2 台のあいだは、この IP で直接届いた（ping は 0.3〜0.7 ミリ秒。`peer/guest-facts-start.txt`） |
| ホスト名と FQDN | `hostname -f` は `<HOSTNAME>.mshome.net`（ホスト名は、クローンの元と同じ）。手順書は IP だけを使うので、確認の出力には出ない |
| firewalld | 既定のゾーンは `public`、`--get-active-zones` は `public (default)` に `eth0`、`target: default` |
| 許可外の送信元からの見え方 | Windows のホストから主の VM の 3000・2222 への TCP は、3 回とも、拒否の応答ではなく 5 秒の時間切れになった。同じ時に、22 は 9〜10 ミリ秒でつながった（`outside-source-check-*.txt`）。Linux の許可外の送信元からどう見えるかは、確かめていない |
| 再起動 | 「再起動しても残ることを確かめる」の手順 5 を貼って（12:13:09.8 UTC）から、SSH のログインの表示が出るまで 10.5 秒、ドライバの bash が開くまで 14.1 秒（`session/session-003.raw`、主の seq 27）。`systemd-analyze` は `648ms (kernel) + 1.815s (initrd) + 14.429s (userspace) = 16.894s`。`forgejo.service` が active になったのは、起動から 5.47 秒（`ActiveEnterTimestampMonotonic=5468694`。`facts-after-reboot.txt`） |
| イメージの取得 | 「イメージを取得して localhost で起動する」の手順 2 のブロックは 15.7 秒（プロンプトの表示は `took 13s`。イメージは 188 MB） |
| メモリとディスク | 主の VM の終わりの `free -m` は、合計 2900・使用 1056・available 1843（Forgejo と `hello-web` が動いている状態）。`/` は 39G のうち 8.1G（始めも終わりも）。データは 6.1M、バックアップの置き場所は 5.2M。クライアントの終わりは、合計 1639・使用 1162・available 476（ヘッドレスの Firefox と GDM のログイン画面が動いている状態） |
| コンソールの PNG | 終わり（21:22 JST）に撮った主の VM のコンソールの PNG には、ログイン画面と 21:18 の時計が写っていた（`screens/main-console-end.png`）。同じころ（21:22:26）の `loginctl` では、ログイン画面は約 4 分前から無操作（`guest-facts-end.txt`）。無操作で画面が消えていて、消える直前の絵が撮れたとみる（画面が消えたこと自体は、見ていない）。Hyper-V の VM は、画面が消えているあいだに撮った PNG が、消える直前の絵のままになる（[初期設定の通しの記録](almalinux-setup.md#ハイパーバイザに左右された出力hyper-v)）。この付録の「GNOME にログインしていない」は、PNG ではなく `loginctl` で書いた |
| 失敗しているユニット | `mcelog.service`（主の VM。起動のたびに failed。初期設定の通しのときから同じ。手順には影響しない。Hyper-V によるかは確かめていない） |

- **SELinux の拒否**: 主の VM は 0 件。根拠は、この通しの後の数え直し
  - 2026-10-11 12:45 UTC に、止めてあった主の VM を司令塔が起動し直して、監査ログのファイル（`/var/log/audit/audit.log` と `audit.log.1`）を直接数えた。`type=AVC`・`type=USER_AVC`・`type=SELINUX_ERR` で始まる行は、どれも 0 行（`grep -c`）。`ausearch --input-logs -m AVC,USER_AVC,SELINUX_ERR` も `<no matches>`。ログの記録は 07:23:58〜12:45:32 UTC で、この通しの時間（12:03〜12:22 UTC）を含む（`.verification/campaign/hv/AVC-recheck/` の、この VM の `avc.txt`）
  - 担当の報告の `<no matches>`（`facts-after-reboot.txt`・`facts-restore-after-step5.txt`・`guest-facts-end.txt`）は、根拠にしていない。端末の無い別の SSH から、`--input-logs` を付けない `ausearch` で読んだもので、その形の `ausearch` は、監査ログではなく標準入力を読み、ログを見ないまま `<no matches>` を返す
  - クライアントの VM は、数え直していない（確かめていない）

### 過去の記録と違った所（Hyper-V、2026-10-11）

どれも、手順の判定は変えない。

| 所 | 今回（Hyper-V の VM） | 過去の記録 |
|---|---|---|
| `systemctl --user` | どのブロックでも、`Failed to connect to user scope bus` は出なかった（SSH の対話の bash） | 2026-10-11 の実機は、Codex の実行経路で途中から `Connection refused` になり、`--machine=<USER>@.host` で読んだ |
| 「バックアップ」の手順 1 と「バックアップから復元する」の手順 3 の停止 | 3 回とも `ActiveState=inactive`・`SubState=dead` | 2026-10-09 のコンテナは、サービスの再起動の直後に止めた最初の 1 回だけ、unit の表示が `failed` になった |
| OS の再起動の後の、サービスの起動とログインの差 | 1 秒（ドライバが、すぐにつなぎ直した） | 2026-10-09 のコンテナ（検証コンテナの再起動）は 30 秒 |
| 「バックアップから復元する」の手順 2 の隔離確認 | 今の形（`--internal --disable-dns` の専用ネットワーク）が、1 回で通った（8.2 秒） | 2026-10-11 の実機の隔離コピーの確認は、最初の起動で、専用ネットワークの aardvark-dns がユーザー D-Bus へ接続できずに失敗し、`--internal --disable-dns` で作り直した |
| 復元の確かめ | 復元した本番に、別の VM からログインし、clone と push を通した | 2026-10-11 の実機は、隔離コピーの確認までで、復元側へのログインと Git の通信は未検証 |

### 指摘と状態（Hyper-V、2026-10-11）

- 行番号は、コミット `114c2b2` の `docs/forgejo.md` のもの。直した後の手順書では、行がずれている
- 7 つとも、担当の報告が挙げたもの（重大度も、報告のまま）。報告の直し方の案のうち、採った形は「状態」に書いた
- 「状態」は、2026-10-11 に手順書を直した後のもの。「直した」は、箇条書きの文言だけを直したもので、コードブロックは変えておらず、VM では流し直していない
- 手順書の指摘は 7（どれも低）。直した 4、未対応 3

| 連番 | 重大度 | 場所 | 何が起きたか | 見立て | 状態 |
|---|---|---|---|---|---|
| 1 | 低 | 「使い方の基本」の手順 10（`:1054`〜`:1056`） | 「New pull request」で開く比較の画面で、`merge into` と `pull from` を選んでも、タイトルと本文の欄は出ない。コミットの一覧と差分の上に出る「New pull request」をもう 1 度押すと出る。箇条書きに、この操作が無かった | 手順書の書き落とし。Forgejo 16.0.5 の英語の画面の動きで、SSH にも Hyper-V にもよらないとみる（見立て）。2026-10-09 の 16.0.5 の付録は、同じ画面を Playwright で通しているが、この操作を記録していない。手順書の画像（`usage-pr-create-en-v16.png`）は、押した後の画面 | 直した（箇条書きを 1 つ足した） |
| 2 | 低 | 「初期設定と管理者の作成」の手順 2（`:231`） | 「「Install Forgejo」を押し、作った管理者でログインできることを確かめる」とあるが、押すと 5 秒でダッシュボードになり、パスワードを聞かれずに、作った管理者でログインした状態になる。「ログインできること」は、サインアウトしないと確かめられない | 手順書の書き方。Forgejo の動きで、SSH にも Hyper-V にもよらないとみる（見立て）。過去の付録（2026-10-09・2026-10-10）は、別のブラウザのセッションでログインを確かめたと書いていて、押した直後の状態は記録していない | 直した（押した後に開く画面と、サインアウトしてからの確かめの 2 つに分けた。参考資料にも補足） |
| 3 | 低 | 「LAN に公開する」の手順 3（`:449`） | 同じ項の手順 2 で LAN 用に切り替えると、開いたままのトンネルの端末に `channel 1: open failed: connect failed: Connection refused` が出続けた（16 秒に 71 行）。エラーに見えるが、箇条書きに無い | 手順書の書き落とし。切り替えで、サーバーの `127.0.0.1:3000` の待ち受けが無くなった所へ、トンネルの入口に接続が来たため。接続しに行ったのは、`http://localhost:3000/admin` を開いたままのブラウザのページとみる（見立て。切り分けていない。2026-10-09 のコンテナの付録に、ホームのポーリングが続くとある）。リードの「初期設定用の SSH トンネルは、LAN の待ち受けへ切り替えた後には使えない」と合う。窓のあるブラウザで同じだけ出るかは、確かめていない | 直した（入れ子の箇条書きを 1 つ足した。「出続けることがある」と書いた。参考資料にも補足） |
| 4 | 低 | 「バックアップから復元する」の手順 6（`:1381`） | バックアップより後に push したコミットを持つ clone で `git fetch` すると、`(forced update)` と出て、ローカルが `[ahead 1]` になった。箇条書きは「`git fetch` を実行し、確認用の新しいコミットを push する」で、その clone からそのまま push する形に読める | 手順書の書き落とし。その clone から push すると、復元で無くなったコミットがサーバーへ戻るとみる（見立て。今回は push していない）。今回は、clone し直した場所から push した。2026-10-09 のコンテナの付録も、新しく clone した場所で確かめている | 直した（入れ子の箇条書きを 1 つ足した。参考資料にも補足） |
| 5 | 低 | 「LAN に公開する」の手順 3（`:450`） | LAN の URL を初めて開くと、言語は、またブラウザの言語（日本語）になった（`localhost:3000` で English を選んだ後でも）。サインインすると英語になった。言語メニューの案内は、「初期設定と管理者の作成」の手順 2 と「使い方の基本」の手順 1 にだけある | 操作には困らなかった（登録のボタンが無いことは、日本語の画面でも確かめられた）。サインインの後に英語になった理由は、確かめていない | 未対応（手順書は変えていない） |
| 6 | 低 | 「再起動しても残ることを確かめる」の手順 6（`:561`） | 「サービスが起動した時刻がログインした時刻より前ならよい」。2 つの時刻は秒までで、今回は 1 秒の差だった。再起動の直後にログインすると、同じ秒になりうる | 今回は、条件を満たした（サービスは起動から 5.47 秒、SSH のログインはその後。再起動の後の `loginctl` でも、ユーザーの `manager` のセッションの LEADER の PID は、ドライバの SSH のセッションの LEADER の PID より小さい。`facts-after-reboot.txt`）。ドライバがすぐにつなぎ直したための差。同じ秒になったことは、見ていない | 未対応（手順書は変えていない） |
| 7 | 低 | 「使い方の基本」の手順 4（`:996`） | 「「Advanced settings」の「Default branch」は `main` にする」とあるが、「Advanced settings」は畳まれていて、「Default branch」は最初から `main` だった。開かなくても `main` で作られた | 箇条書きのとおりにしても困らない。Forgejo 16.0.5 の画面の、最初の値 | 未対応（手順書は変えていない） |

環境と道具の指摘（手順書の外。このリポジトリでは直さない）:

- **主の VM の IP**: Default Switch の DHCP で、手順書の前提（固定の IPv4）と違う。Quadlet の `PublishPort`・`DOMAIN`・`ROOT_URL`・`SSH_DOMAIN` と、firewalld の 2 規則に、この IP が入っている。次に起動したときに IP が変わっていれば、`forgejo.service` は待ち受けられないはず、というのが担当の見立て（確かめていない。12:45 UTC に起動し直したときは、同じ IP だった）
- **ドライバ**: 再起動のブロックを貼ったとき、`accepted: false`・`state: disconnected` を返した（`session/requests.jsonl`）。コマンドは動いている（出力に `The system will reboot now!`）。失敗と読まない
- **クライアントのメモリ**: 2048 MB の VM でヘッドレスの Firefox を動かすと、available が 500 MB を切った（終わりは 476 MB。担当の報告では、途中で 384 MB）。落ちてはいない
- **Windows のホストから見た拒否**: 許可外の送信元からの 3000・2222 は、拒否の応答ではなく、時間切れになった。firewalld の `public` が返す拒否を、Windows の TCP が接続の失敗として返さないため、というのが担当の見立て（確かめていない）。「つながらない」ことは確かめられた
- **ゲスト**: `mcelog.service` が、起動のたびに failed になる
- 報告の重大度は、主の VM の IP が中、ほかの 4 つは低。報告は、このほかに 2 つ挙げている（どちらも低）: 検証の道具の文書（単位の定義）に、ブラウザの手順をどう操作するかが書かれていないことと、画面が消えているあいだに撮った PNG（上の表の「コンソールの PNG」）

### 手順書を直した所（Hyper-V、2026-10-11）

通した後（`114c2b2` より後）に直した。どれも箇条書きの文言だけで、コードブロックは変えていない（4 つとも、コマンドの無い手順）。VM で貼り直すものは無い。

- [手順書](https://github.com/ryo-aoki-pc/setup-notes/blob/114c2b2bfd14b51f9e1925b150cbf72e1954f311/docs/forgejo.md)の「初期設定と管理者の作成」の手順 2: 「「Install Forgejo」を押し、作った管理者でログインできることを確かめる」を、2 つの箇条書きに分けた（指摘 2）
  - 「Install Forgejo」を押すと、作った管理者でログインした状態のダッシュボードが開く
  - パスワードでログインできることは、右上のアカウントメニューの「Sign out」の後、「Sign in」で確かめる
- 「LAN に公開する」の手順 3: トンネルを閉じる箇条書きの下に、同じ項の手順 2 の後に `channel 1: open failed: connect failed: Connection refused` のような行が出続けることがあり、正常なのでそのまま閉じる、という 1 行を足した（指摘 3）
- 「使い方の基本」の手順 10: `merge into` と `pull from` を選ぶ箇条書きの次に、コミットの一覧と差分の上に出る「New pull request」をもう 1 度押して、タイトルと本文の欄を開く、という 1 行を足した（指摘 1）
- 「バックアップから復元する」の手順 6: `git fetch` と push の箇条書きの下に、`git fetch` が `(forced update)` を出したら、その clone には復元で無くなったコミットが残っていて、そのまま push するとサーバーに戻ること、戻したくなければ空の場所へ clone し直してから push すること、の 1 行を足した（指摘 4。その clone からの push は、この通しでは試していない。git の動きからの説明）
- 足した文の元になった出力と画面は、どれも、この通しの記録にある（`b03-install-submit.txt`・`b04-relogin-tunnel.txt`、`peer/session/session-001.raw`、`x-pr-form-visible.txt` と 2 枚の PNG、クライアントの seq 54〜56）
- [参考資料](../reference/forgejo.md)に、補足を 3 つ足した
  - 「実施手順 / 初期設定と管理者の作成 / 手順 2: 補足: 「Install Forgejo」の後のログイン」
  - 「実施手順 / LAN に公開する / 手順 3: 補足: トンネルの端末に出る Connection refused」（何が接続しに行ったかは、切り分けていないと書いた）
  - 「バックアップから復元する / 手順 6: 補足: `(forced update)` が出た clone から push しない理由」（その clone からの push は試していないと書いた）
- [ロールバック](../extra/forgejo.md)は、変えていない（この通しの範囲の外）

### 報告と証跡の照合（Hyper-V、2026-10-11）

- 50 手順の判定と、「確認」の後ろの出力は、担当の報告（`result.md`）と証跡で食い違わない
- **SELinux の拒否**: 報告は「拒否は無い（`ausearch -m avc -ts boot`・`-ts today` とも `<no matches>`）」と書く。この読み方は当てにならないので、この付録は、司令塔の数え直しで書いた（[上の表の下](#hyper-v-に左右されたと思われる値2026-10-11)）。結果は、どちらも 0 件
- **スクリプトが止まった回数**: 報告は 2 回（`b05`・`b07`）と書く。証跡では、`u10-pr-open.txt` も、比較の画面を開いた後に、スクリプトの誤りで止まっている。`b07` の止まった回の出力は、証跡に無い（同じ名前のファイルに、通った回の出力だけがある）
- **URL を直接開いた所**: 報告は、URL を直接開いたのは、最初のページ・確かめのためのページ・`/user/login` だけと書く。スクリプトでは、リポジトリのページ（`u06-issue.py`・`u10-pr-open.py`）と、Pull Request と Issue のページ（`u11-pr-files-merge.py`）も、URL で開いている（手順書が、その画面にいる前提で書いている所）
- **トンネルの端末の行**: 報告は「17 秒ほどで 71 行」と書く。証跡では、最初の行が 12:07:52.57、最後の行が 12:08:08.91 UTC で、16 秒に 71 行
- **クライアントの `known_hosts`**: 報告は、残したのは 2 行（主の VM の 22 と 2222）と書く。証跡では、2222 の行は 4 行目にあった（`ssh-keygen -F` の `found: line 4`。クライアントの seq 57）。ほかの行が何かは、証跡からは読めない
- **再起動の後のつなぎ直し**: 報告の「14.1 秒後につながった」は、ドライバの bash が開くまでの時間。SSH のログインの表示は、貼ってから 10.5 秒後に出ている
- **止めていた時間**: 報告は、バックアップが 7 秒、復元が 8 秒と書く。証跡の時刻（止めるブロックを貼ってから、起動のブロックの `active` が出るまで）では、どちらも 6 秒ほど
- 報告だけにあって、証跡のファイルでは確かめられないもの
  - `vmms.exe` の版、ディスクが SCSI の差分であること、NIC が Default Switch であること
  - トンネルの初めての接続で出た ED25519 の指紋を、サーバーの `/etc/ssh/ssh_host_ed25519_key.pub` と比べたこと（比べた記録は無い。点検のときに、証跡の `known_hosts` と `session/known_hosts`〔Windows のホストの SSH が控えた、主の VM のホスト鍵〕から指紋を計算すると、トンネルの端末に出た指紋と同じだった）。パスワードを送る前に、端末のエコーが切れていることを確かめたこと
  - 「バックアップ」の手順 4 の、元のアーカイブの sha256
  - 再起動の前後の boot ID、`sleep.target`・`suspend.target` が `masked` であること
  - 終わりに 2 台を止めて、主の VM のスナップショットを取ったこと、クライアントの片付け、記録に OS のパスワードと鍵が無いことの点検（`tools/scan-secrets.mjs`）

### 確かめていないこと（Hyper-V、2026-10-11）

- 人の手でのブラウザの操作（マウス・キーボード・クリップボードへのコピー）、窓のあるブラウザでの表示、手順書の画像（`docs/images/forgejo/usage-*-en-v16.png`）との見比べ（開いて見たのは、指摘 1 の `usage-pr-create-en-v16.png` の 1 枚だけ）
- Windows のクライアント（Git Bash）、実物の別のマシンからの接続（クライアントは、同じ仮想スイッチの AlmaLinux の VM だけ）
- 固定の IPv4、IP が変わったときの動き、VPN 経由、LAN と VPN の両方、Linux の許可外の送信元からの見え方
- 「バックアップ」の手順 4 の、別のディスク・別の PC・暗号化しての保管
- 「更新」の節（手順 1〜4）、自動更新が版を上げる側・失敗して戻す側・保留、タイマーが 4 時台に動くこと
- 異なる版のあいだの復元と DB の移行、「バックアップから復元する」の手順 7、別のサーバーへの移設
- [ロールバック](../extra/forgejo.md)と「保持したデータも削除する（任意）」、「設定ファイル」の表の読み合わせ
- 各手順の `中断:` の側、`Failed to connect to user scope bus` のときの `--machine=`、`LAN_SUBNET='0.0.0.0/0'`、ポートを変えた場合、`FW_ZONE` が既定と違う場合
- 複数のユーザー（管理者ではないアカウント）、レビュー・必須の承認・CI・競合の解消、Pull Request を直して push し直す流れ
- バックアップより後のコミットを持つ clone から、そのまま push したときの動き（指摘 4）
- 直した後の箇条書きを見ながらの通し（文言だけの直し。足した文の元になった出力は、この通しの記録にある）
- クライアントの VM の SELinux の拒否
- デスクトップの端末にブロックを貼る形、ホスト UID が 1000 以外の構成、実機、aarch64（実機の aarch64 の構築は、[上の付録](#付録-raspberry-pi-5-の実機構築2026-10-11-jst)）
