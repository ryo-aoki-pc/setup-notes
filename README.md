# setup-notes

実機で検証した構築・設定手順と、失敗時の切り分けを記録するリポジトリ。
各文書は実施手順を先に、背景・実測・落とし穴を後半の「補足」に載せている。

## 手順書

| 手順書 | 用途 | 検証環境 |
|---|---|---|
| [GNOME Remote Desktop](docs/gnome-remote-desktop.md) | システムデーモン方式のリモートログインを有効化する | AlmaLinux 10.2 / x86_64・aarch64 |
| [WireGuard VPN](docs/wireguard.md) | 2 拠点の LAN と外出先クライアントを接続する | AlmaLinux 10.2 / aarch64 |
| [WireGuard Road Warrior](docs/wireguard-road-warrior.md) | AlmaLinux PC から拠点の WireGuard VPN へ接続する | AlmaLinux 10.2 / x86_64 |
| [Samba](docs/samba.md) | ホームディレクトリを LAN・WireGuard 越しに公開する | AlmaLinux 10.2 / aarch64 |
| [WezTerm Nightly](docs/wezterm-nightly.md) | 公式 COPR の EL9 ビルドを AlmaLinux 10 に導入する | AlmaLinux 10.2 / x86_64 |

## 記法

- タイトル直後に、変数設定、コマンド、動作確認、任意操作、ロールバックを並べる
- 環境固有値は冒頭の変数ブロック、または WireGuard の `site.env` で一度だけ設定する
- 変更が必須の変数は 1 変数ずつのコードブロック、変更が任意の変数は 1 つのブロックにまとめる
- 対象・検証環境、採用理由、実測、落とし穴は後半の「補足」にまとめる
- コマンドは実行済みのものを載せ、未検証事項は明記する
- パスワード、秘密鍵、トークンなどの秘密情報は残さない
