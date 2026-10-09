# Forgejo 構築手順の検証記録

[手順書](../forgejo.md)・[参考資料](../reference/forgejo.md)

## 対象と検証環境

- **状態（2026-10-09 UTC）**: AlmaLinux 10.2 の systemd コンテナで検証した。実機・VM での本実行ではない
  - 通したもの: 一般ユーザーの rootless Podman、公式イメージの取得と Quadlet の起動、SSH トンネルからのブラウザ初期設定、指定 IPv4 への切り替え、Git の SSH 認証・clone・push、サービス再起動、停止バックアップ・復元、同じ版の再適用、撤去、専用データの削除
  - 確認したこと: 管理者のログイン、SQLite、自己登録と OpenID の無効化、匿名閲覧の制限、プライベートなリポジトリ、SSH 鍵とデータの保持、ログアウト後の稼働、検証コンテナ再起動後の最初の SSH ログイン前の自動起動
  - 確認したこと: 復元でバックアップ時点のコミットへ戻り、その後に追加したファイルが消え、復元後もログインと push が使えること。同じ 15.0.9 を再適用する更新手順と `doctor check --all` の 28 項目
  - 確認したこと: Bash 31 ブロックと埋め込み Python 5 本の構文、Quadlet の生成、既存構成・空の復元先・空の更新版・全 IPv4 の許可を弾くガード、firewalld の保存済み規則の追加・削除と構文
  - **確認していないこと**: SELinux Enforcing での `:Z`、firewalld の runtime 規則と許可外の接続拒否、実際の LAN・VPN の経路、実機・VM の OS 再起動、aarch64、ホスト UID が 1000 以外の構成
  - **確認していないこと**: 異なる版への更新・DB の移行・移行後の旧版への復旧、別サーバーへの移設、外部の保管先へのコピー。本書の更新確認は同じ版の再適用で、版を上げた検証ではない

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
