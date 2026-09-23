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
| [Firefox](docs/firefox.md) | Mozilla 公式 RPM リポジトリから最新版を入れる（標準は ESR 140） | AlmaLinux 10.2 / aarch64 |
| [Claude Code](docs/claude-code.md) | 公式 dnf リポジトリから CLI を入れる | AlmaLinux 10.2 / aarch64 |
| [GitHub CLI](docs/gh.md) | 公式 dnf リポジトリから gh を入れる（EPEL 版より新しい） | AlmaLinux 10.2 / aarch64 |
| [Homebrew](docs/homebrew.md) | パッケージマネージャを入れる（以降 10 本の前提） | AlmaLinux 10.2 / aarch64 |
| [yazi](docs/yazi.md) | ターミナルファイルマネージャを Homebrew で入れる | AlmaLinux 10.2 / aarch64 |
| [lazygit](docs/lazygit.md) | git の TUI クライアントを Homebrew で入れる | AlmaLinux 10.2 / aarch64 |
| [Neovim](docs/neovim.md) | 最新版を Homebrew で入れる（EPEL 版は 0.10 系） | AlmaLinux 10.2 / aarch64 |
| [zoxide](docs/zoxide.md) | ディレクトリ移動を学習するツールを Homebrew で入れる | AlmaLinux 10.2 / aarch64 |
| [bat](docs/bat.md) | 色付きの `cat` を Homebrew で入れる（EPEL 版は 0.24 系） | AlmaLinux 10.2 / aarch64（コンテナのみ） |
| [eza](docs/eza.md) | `ls` の代わりになる一覧表示を Homebrew で入れる（RPM が無い） | AlmaLinux 10.2 / aarch64（コンテナのみ） |
| [git-delta](docs/git-delta.md) | git の差分表示を delta に置き換える（設定は `~/.gitconfig`） | AlmaLinux 10.2 / aarch64（コンテナのみ） |
| [gdu](docs/gdu.md) | ディスク使用量を見る TUI を Homebrew で入れる（コマンド名は `gdu-go`） | AlmaLinux 10.2 / aarch64（コンテナのみ） |
| [btop](docs/btop.md) | リソースモニタを EPEL の dnf で入れる（Homebrew と同じ 1.4.7） | AlmaLinux 10.2 / aarch64（コンテナのみ） |
| [starship](docs/starship.md) | シェルプロンプトを Homebrew で入れる（`~/.bashrc` に 1 行） | AlmaLinux 10.2 / aarch64（コンテナのみ） |
| [ShellCheck / shfmt](docs/shellcheck.md) | シェルスクリプトの静的検査と整形を Homebrew で入れる | AlmaLinux 10.2 / aarch64 |
| [VS Code](docs/vscode.md) | Microsoft 公式 dnf リポジトリからエディタを入れる（GUI） | AlmaLinux 10.2 / aarch64 |

## 記法

- タイトル直後に、変数設定、コマンド、動作確認、任意操作、ロールバックを並べる
- 環境固有値は冒頭の変数ブロック、または WireGuard の `site.env` で一度だけ設定する
- 変更が必須の変数は 1 変数ずつのコードブロック、変更が任意の変数は 1 つのブロックにまとめる
- 対象・検証環境、採用理由、実測、落とし穴は後半の「補足」にまとめる
- コマンドは実行済みのものを載せ、未検証事項は明記する
- 実機で本実行していない手順書は、一覧の検証環境に「コンテナのみ」と書く
- 複数の手順書が共有する前提（Homebrew など）は独立した手順書にし、各手順書の冒頭から参照する
- パスワード、秘密鍵、トークンなどの秘密情報は残さない
