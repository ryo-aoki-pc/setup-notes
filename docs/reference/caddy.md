# Caddy（AlmaLinux 10 / ホストで共通に使う HTTPS）の参考資料

[AlmaLinux 10 の「Caddy」](../almalinux-setup.md#caddy)・[ロールバックと注意点](../extra/caddy.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/caddy.md)

## 選択した方針

- AlmaLinux 10 では、本体・認証局・ユーザーサービスをホストで 1 つにする。Forgejo と Codeg はサイトのファイルだけを足す。端末で信頼するルート証明書はホストごとに 1 つで済む（2026-10-15、利用者の決定）
- 同じ一般ユーザーで `caddy.service` を動かし、各アプリの HTTP を localhost に閉じる。LAN・VPN の口は Caddy の HTTPS と、アプリごとに明示した SSH などだけにする
- Windows 11 の Codeg 専用の Caddy は、[AI エージェントの手順書](../ai-agents.md#grok-build-のブラウザ操作-windows-11-で使う)に残す

## 補足

### Caddy: 入れて起動する / 手順 3: 配布物の入手

- GitHub の配布物を版を決めて取得し、ホームの固定パスに置く。チェックサム一覧（`caddy_<版>_checksums.txt`）は SHA-512。`aarch64` は `linux_arm64`、`x86_64` は `linux_amd64` を使う
- EPEL・Homebrew・scoop の Caddy は使わない。Codeg の旧手順も同じ配置だったので、移行では本体を入れ直さない。Windows の scoop は版ごとにパスが変わり、受信規則のプログラム指定と合わなくなる
- Caddy の配布物は、追加の共有ライブラリを必要としない 1 つの実行ファイル。旧 Codeg 専用の構成で GitHub の配布物の SHA-256 digest とも照合した記録は、[Codeg の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/grok-build-remote.md)に保持する
- 配布物と一覧を同じ配布元から取得する照合は、取得中の破損を見つける。配布元そのものの差し替えを検出する署名検証とは異なる

### Caddy: 入れて起動する / 手順 4: 共通の Caddyfile

- `import sites/*.caddy` は、共通の Caddyfile からの相対パスで各サイトを読み込む。glob に一致するファイルが無いことはエラーではない（[import](https://caddyserver.com/docs/caddyfile/directives/import)）
- `(root-crt)` は公開用ルート証明書を配るスニペット。各サイトの `import root-crt` で、同じ `root.crt` を配る
- `{$HOME}` は Caddyfile を解析する前に環境変数で置き換える。ヒアドキュメントでは `$` を逃がして残し、パス全体は引用符で囲む。旧 Windows の `{$APPDATA}` も同じ仕組み
- `admin off` は管理用 API（既定 `localhost:2019`）を開けない。`caddy reload` はこの API を使うため、変更は設定を検査してサービスを起動し直す。共通の全サイトが数秒切れる
- `auto_https disable_redirects` は HTTP から HTTPS へ送るための 80 番の待ち受けを作らない。`skip_install_trust` はホストの信頼ストアへ認証局を自動で入れさせない（[全体の設定](https://caddyserver.com/docs/caddyfile/options)）
- `Restart=on-failure`・`RestartSec=5` は異常終了時に待って起動し直す。起動時にサイトの `SERVER_IP` がまだ付いていない場合も再試行する

### サイトの bind と tls internal

- `bind <SERVER_IP>` は待ち受けを指定した IPv4 に限定する。Forgejo は同じ番号の `127.0.0.1` を Podman が使うので必須。省略すると Caddy が全アドレスの同じ番号を取りに行き、ぶつかる（[bind](https://caddyserver.com/docs/caddyfile/directives/bind)）
- `tls internal` は Caddy の内部認証局でそのサイトの証明書を作る。IP アドレスをサイトのアドレスにすると、その IP 用の証明書になる（[tls](https://caddyserver.com/docs/caddyfile/directives/tls)・[ローカル HTTPS](https://caddyserver.com/docs/automatic-https#local-https)）
- `reverse_proxy` は残りの通信を同じホストのアプリへ渡す。WebSocket も扱う。`handle /caddy-root.crt` はその経路だけを配布用ファイルへ分ける

### 認証局の名前と Codeg 専用からの切り替え

- 新規の `pki` の `name` は `Caddy <ホスト名>`。ルート証明書の名前は `<名前> - <年> ECC Root` になり、端末の一覧でホストを見分けるために使う
- 名前は認証局を生成するときに使う。保存済みの認証局を読み込む場合、設定の名前を変えるだけでルート証明書を作り直す形にはならない（[PKI の設定](https://caddyserver.com/docs/caddyfile/options#pki-options)・[認証局の実装](https://github.com/caddyserver/caddy/blob/v2.11.7/modules/caddypki/ca.go)）
- 移行手順では、名前を変えず旧 Caddyfile から写し、`~/.local/share/caddy` に手を触れない。移したホストの名前は `Codeg <ホスト名>` のままになる。切り替え前後の `root.crt` の指紋が同じことを確かめる
- 2026-10-15 に実機で確かめた: サイトが 1 つも無い状態で起動でき（`import` の glob の警告だけ）、初回の起動でルート証明書ができた。移行では、ルート証明書の名前・指紋と、中間証明書の名前（`Codeg <ホスト名> - ECC Intermediate`）が変わらなかった（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/caddy.md)）
- 空白で字下げした Caddyfile では、`caddy validate` と起動のたびに `Caddyfile input is not formatted` の警告が出る。Caddy の標準の字下げ（タブ）と違うことを知らせるだけで、動作は変わらない。貼り付けでタブが崩れないよう、手順書は空白で書く

### Caddy: 端末にルート証明書を入れる / 指紋の照合

- ルート証明書は公開してよい。Forgejo でも Codeg でも、同じホストの `/caddy-root.crt` は同じファイルを配る。`root.key` は配らない
- 初回の取得はまだ信頼していない相手から行う（Android は警告を進み、Windows は `curl -k`）。途中で差し替わっていないことを、ホストの SHA-256 指紋と比べて確かめる
- Android は取り込み後に「信頼できる認証情報」で指紋を照合し、違えば削除する。PC で照合したファイルを USB で渡す方法もあるが、手順は利用者の指定でブラウザから取得する形にしている
- Windows の取り込み先は `Cert:\CurrentUser\Root`。このユーザーの Edge・Chrome が使う。Firefox の信頼ストアとの連動は設定に依存し、端末ごとに確認する
- `curl` の終了コード 60 は証明書の検証失敗。既定の信頼ストアに入れていないサーバーでは `--cacert` 付きだけが通ることを確かめる。ホスト自身で信頼させた後は既定の curl も通る

## 参照

- [Caddy のリリース](https://github.com/caddyserver/caddy/releases)
- [Caddyfile の全体の設定](https://caddyserver.com/docs/caddyfile/options)
- [Caddyfile の import](https://caddyserver.com/docs/caddyfile/directives/import)
- [Caddyfile の bind](https://caddyserver.com/docs/caddyfile/directives/bind)
- [Caddyfile の tls](https://caddyserver.com/docs/caddyfile/directives/tls)
- [Caddyfile の reverse_proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy)
- [Caddyfile の環境変数と引用](https://caddyserver.com/docs/caddyfile/concepts#environment-variables)
- [自動 HTTPS とローカル HTTPS](https://caddyserver.com/docs/automatic-https)
- [Caddy のコマンド](https://caddyserver.com/docs/command-line)
