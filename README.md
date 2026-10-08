# setup-notes

実機で検証した構築・設定手順と、失敗時の切り分けを記録するリポジトリ。
操作・前提・注意・成功条件は手順書、採用理由や背景は [参考資料](docs/reference/README.md)、実施日・環境・結果・失敗例は [検証記録](docs/verification/README.md)に分けてある。

## 最初に読む

| 始める環境 | 開く手順書 |
|---|---|
| AlmaLinux 10 をインストールした直後 | [AlmaLinux 10 の初期設定](docs/almalinux-setup.md) |
| Windows 11 をインストールした直後 | [Windows 11 の初期設定](docs/windows-setup.md) |
| Windows 11 と AlmaLinux 10 のデュアルブート | [Windows 11 のデュアルブート向けの導入](docs/windows-dual-boot.md) → 各 OS の初期設定 |
| 基本設定の後にツールやサービスを入れる | [OS ごとの導入順](docs/getting-started.md) → [目的別の手順書一覧](docs/README.md) |

対象は AlmaLinux 10.2 と Windows 11。対応する OS・実行するユーザー・前提は各手順書の冒頭で、検証済みの範囲は対応する検証記録の「状態」で確認する。

## 手順書とツール

[目的別の手順書一覧](docs/README.md)から、各手順書・参考資料・検証記録を開ける。
導入元や設定場所を比較するときは [手順書とツールの比較](docs/catalog.md)、版や aarch64 の提供を確認するときは [CLI / GUI ツール導入元一覧](docs/tool-catalog.md)を使う。

| 目的 | 手順書の入口 |
|---|---|
| OS と共通の前提を整える | [初期設定と共通の前提](docs/README.md#初期設定と共通の前提) |
| SSH・RDP・VPN でつなぐ | [リモート接続と VPN](docs/README.md#リモート接続と-vpn) |
| ファイルを共有・同期する | [ファイル共有と同期](docs/README.md#ファイル共有と同期) |
| 端末・フォント・ファイル操作を整える | [端末とファイル操作](docs/README.md#端末とファイル操作) |
| エディタ・Git・GitHub を使う | [エディタと Git](docs/README.md#エディタと-git) |
| AI・開発ツールを使う | [AI と開発ツール](docs/README.md#ai-と開発ツール) |
| コンテナ・仮想マシンを使う | [コンテナと仮想化](docs/README.md#コンテナと仮想化) |
| ブラウザや通信制約のある環境を整える | [ブラウザと通信制約](docs/README.md#ブラウザと通信制約) |

シェルの設定は [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash) で管理する。ツールごとに同じ設定を `~/.bashrc` に追記せず、先に次の導入を行う。

### 共通の bash 設定を先に入れる

Git を入れたら、自分のユーザーの bash（Windows 11 は Git Bash、WSL は WSL 側）で初回だけ実行する。

```bash
git clone https://github.com/ryo-aoki-pc/bash.git ~/.config/bash &&
  bash ~/.config/bash/install.sh
```

端末を開き直せば、インストール済みのツールの設定が効く。既に clone 済みなら `git -C ~/.config/bash pull --ff-only` で更新し、`install.sh` を実行する。既知の追記は控えを取って移行し、同じ状態での再実行では重複を増やさない。手で変えた行は残るので、[導入手順](https://github.com/ryo-aoki-pc/bash/blob/main/docs/quick-start.md)に従って確認する。

- **各ツールの `~/.bashrc` への追記は不要**。Homebrew、Neovim、bat、eza、gdu、yazi、fzf、starship、zoxide、Podman の `DOCKER_HOST`、履歴・`shopt`・Homebrew の補完を含む。[追記箇所の照合結果](https://github.com/ryo-aoki-pc/bash/blob/main/docs/reference/quick-start.md#setup-notes-の追記との対応)を参照
- ツール本体のインストール、Podman のソケットの有効化、`bash-completion` の導入、`~/.inputrc`、Git などの別ファイルの設定は各手順書で行う（AlmaLinux 10 の `bash-completion` と `~/.inputrc` は、[AlmaLinux 10 の初期設定の手順 44・45](docs/almalinux-setup.md#実施手順)）
- root 用は root 自身の clone と読み込み設定が必要。[root の導入条件](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#root-のシェルでも読む任意)を先に確認する

## 設定のリポジトリ

ツール本体の導入はこのリポジトリ、個人用の設定の導入・変更・更新は次のリポジトリで管理する。各手順書の「設定ファイル」からも案内している。

| 設定 | リポジトリ | このリポジトリの手順書 |
|---|---|---|
| bash の共通設定 | [bash](https://github.com/ryo-aoki-pc/bash) | [共通の bash 設定](#共通の-bash-設定を先に入れる) |
| Neovim / LazyVim | [LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter) | [Neovim の設定ファイル](docs/neovim.md#設定ファイル) |
| WezTerm | [wezterm](https://github.com/ryo-aoki-pc/wezterm) | [WezTerm の設定ファイル](docs/wezterm-nightly.md#設定ファイル) |
| lazygit | [lazygit](https://github.com/ryo-aoki-pc/lazygit) | [lazygit の設定ファイル](docs/lazygit.md#設定ファイル) |
| yazi | [yazi](https://github.com/ryo-aoki-pc/yazi) | [yazi の設定ファイル](docs/yazi.md#設定ファイル) |

## 検証の記録

[検証記録の一覧](docs/verification/README.md)から各文書の実施範囲を確認する。[AlmaLinux 10 の VM 検証総括](docs/verification/almalinux-vm.md)と [Windows 11 の検証記録](docs/verification/windows-setup.md)から、環境構築を通した結果を読める。

## 導入の基盤

Homebrew・EPEL・Flathub・scoop などの違いは [比較表](docs/catalog.md#導入の基盤)、先に行う設定は [導入順](docs/getting-started.md)を参照する。

## 記法

手順書の読み方・書き方は [記法](docs/writing-guide.md#記法)、編集時の詳細な約束は [CLAUDE.md](CLAUDE.md#手順書の構造)を参照する。
