# Forgejo 構築手順の検証記録

[手順書](../forgejo.md)・[参考資料](../reference/forgejo.md)

## 対象と検証環境

- **16.0.5 の検証状態（2026-10-09 UTC）**: 通常系列の最新安定版として公式の `16.0.5-rootless` を新規導入した。以下の 2 つの専用環境で確認し、詳細は末尾の 16.0.5 の付録へ記録した
  - AlmaLinux 10.2 の systemd コンテナ: 一般ユーザーの rootless Podman による公式イメージ取得・Quadlet の生成と起動、実ブラウザでの初期管理者作成・ログイン、SQLite と設定の保存先、自己登録・OpenID・匿名閲覧の制限を確認した
  - 同じ AlmaLinux の環境: サービスの stop / start 後に、設定・SSH ホスト公開鍵・登録済みの公開鍵・プライベートなリポジトリ・管理者ログインが保持された。OS 再起動の確認ではない
  - 別の Docker コンテナ: 英語 UI のログイン・SSH 公開鍵・プライベートなリポジトリ・Issue・Pull Request・差分・マージ、SSH の clone・作業ブランチ・commit / push・main の pull・Issue の自動クローズを確認し、英語画面 8 枚を保存した
  - 現行の Bash 35 ブロックと埋め込み Python 5 本は構文検査済み
  - **確認していないこと**: 16.0.5 の構築手順全体の通し実行、バックアップ・復元・更新・doctor、ログアウト後や OS 再起動後の稼働、旧版からの DB の移行・旧版への復旧。15.0.9 の成功結果を今回の結果へ広げない
  - **確認していないこと**: SELinux Enforcing の `:Z`、firewalld の runtime 規則と許可外の接続拒否、実際の LAN・VPN、実機・VM、aarch64、ホスト UID が 1000 以外の構成、別サーバーへの移設。複数ユーザーのレビュー・必須承認・CI・競合解消・Windows の Git Bash での利用操作も未確認

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

### 実施手順 / 手順 2〜8: イメージ・初期設定・ロック

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

### 実施手順 / 手順 9〜11: IPv4 と登録制限

- Quadlet の待ち受け・DOMAIN・ROOT_URL・SSH_DOMAIN をサーバーの IPv4 にそろえた
- Web と Git 用 SSH が指定 IPv4 へ公開され、`0.0.0.0`・IPv6 向けの公開になっていないことを `podman port` で確認した
- 切り替え後も新しいブラウザセッションでログインでき、管理者画面を開けた
- 通常登録のページには登録無効の説明が表示され、登録フォームが無かった
- 通常登録の無効化だけでは OpenID のリンクが残った。OpenID のログイン・登録も無効にして再起動し、リンクが消えることを確認した
- 匿名のリポジトリ閲覧はログイン画面へ転送され、`REQUIRE_SIGNIN_VIEW=true` が効いた

firewalld は、IPv4・送信元 CIDR・宛先 IPv4・priority 100・TCP ポートの 2 規則を `firewall-offline-cmd` で保存・一覧・削除し、`--check-config` が成功した。runtime の規則、許可外の送信元からの拒否、VPN の経路は確認していない。

### 実施手順 / 手順 12〜18: Git とサービス再起動

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

### 実施手順 / 手順 19〜23: ログアウト・コンテナ再起動

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

### 実施手順 / 手順 2〜8・12・15・17・18 の一部: 実施内容と結果

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
