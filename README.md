# setup-notes

実機で検証した構築・設定手順の記録。

「動いた手順」だけでなく、**なぜ失敗したか・どう切り分けたか**も残すことを重視している。同じ作業を別の環境でやり直すとき、あるいは同じ症状に再び出くわしたときに、調査をやり直さずに済むようにするのが目的。

## 手順書一覧

| ドキュメント | 対象 | 概要 |
|---|---|---|
| [GNOME Remote Desktop 有効化手順](docs/gnome-remote-desktop.md) | AlmaLinux 10.2 (x86_64 / aarch64) / gnome-remote-desktop 49.3 | リモートログイン方式（システムデーモン）の CLI 設定。openssl による TLS 証明書生成（SAN 付き）、FreeRDP 無しでの TLS 検証、ログイン失敗の原因調査、winpr-makecert との比較を含む |

## 記法の約束

- **環境固有の値はプレースホルダで書く。** `<HOSTNAME>` / `<HOSTNAME>.<DOMAIN>` / `<SERVER_IP>` / `<LAN_SUBNET>` / `<USER>` など。各ドキュメントの冒頭に対応表を置く
- **検証した環境のバージョンを明記する。** ディストリビューション、対象パッケージ、関連ツールのバージョンを冒頭に書く
- **コマンドは実際に実行したものを載せる。** 出力やログも、切り分けの根拠になるものは引用する
- **秘密情報は書かない。** パスワード・鍵・トークンの類は、たとえ private リポジトリでも残さない

## 収録内容から: 再利用価値の高い知見

現在収録している [GNOME Remote Desktop の手順書](docs/gnome-remote-desktop.md) から、他の作業でも効いてきそうなものを抜粋する。

- **`grdctl` の対話入力は TTY 必須** — 引数なしの `set-credentials` は stdin ではなく制御端末から読む。スクリプトやパイプ経由では**何も設定されないまま exit 0 で終わる**ため、失敗に気づきにくい
- **資格情報の変更にはデーモンの再起動が必要** — 設定ファイルには書けているのに拒否され続ける。`grdctl status` 側は設定済みに見えるため紛らわしい
- **ログの署名で失敗原因が切り分けられる** — `Credentials are not set`（未設定/未再起動）/ `Could not find user in SAM database`（ユーザー名不一致）/ `SEC_E_MESSAGE_ALTERED`（パスワード不一致）/ `Sending server redirection`（成功）。ユーザー名とパスワードで別のエラーが出るのが決め手
- **openssl は「代替」ではなく upstream 公式の証明書生成方法** — `winpr-makecert` は Red Hat のドキュメントが採用しているだけで、GRD 側の要件ではない。要件は PEM 形式・所有者・SELinux コンテキストの 3 点のみ。追加パッケージ不要なのでメイン手順に採用している
- **`grdctl --system rdp enable` はサービスも起動する** — その後に設定した資格情報は再起動まで反映されない。また `disable` → `enable` の後に `~gnome-remote-desktop/.local/share/gnome-remote-desktop/grd.conf` に `enabled=false` が残り、再起動しても無効のままになったことがある
- **FreeRDP は SAN の `IP:` エントリを照合しない** — DNS エントリしか見ない。IP で接続する運用なら、IP を `DNS:` としても併記する必要がある
- **TLS の可否だけをパスワード無しで検証できる** — 存在しないユーザー名で接続し、認証段階のエラーまで到達するか、その手前の TLS ハンドシェイクで落ちるかを見る。FreeRDP が無くても、X.224 ネゴシエーション後に TLS を張る Python スクリプト（標準ライブラリのみ）で提示証明書の fingerprint と SAN を確認できる
