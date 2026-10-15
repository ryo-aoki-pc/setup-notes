# setup-notes

Windows 11 と AlmaLinux 10 の構築・設定の手順をまとめる。実施日・環境・結果の記録（検証記録）は、非公開の [ryo-aoki-pc/setup-notes-verification](https://github.com/ryo-aoki-pc/setup-notes-verification) で管理する。

## 手順書

| 手順書 | 対象 | 内容 |
|---|---|---|
| [Windows 11 のセットアップ](docs/windows-setup.md) | Windows 11 | Windows の導入、基本の設定、デスクトップ、ネットワークとリモート操作、SSH、Git と開発の道具、アプリと更新 |
| [AlmaLinux 10 のセットアップ](docs/almalinux-setup.md) | AlmaLinux 10 | 基本の設定、GNOME のデスクトップ、Git と開発の道具、アプリ、ネットワークとリモート操作、コンテナ、ファイルの共有と同期、再起動の後の確認と更新 |
| [シェルと端末のセットアップ](docs/shell-terminal.md) | 両方 | 共通の bash 設定、シェルのツール、HackGen Console NF、WezTerm、Git Bash の設定、Windows Terminal、PowerShell 7 |
| [Neovim のセットアップ](docs/neovim.md) | 両方 | Neovim の導入と設定 |
| [AI コーディングエージェントのセットアップ](docs/ai-agents.md) | 両方 | Claude Code・Codex CLI・Grok Build・Antigravity CLI、プラグイン、共同作業、ブラウザ操作、Remote Control、GNOME 操作 |
| [仮想マシンのセットアップ](docs/virtual-machines.md) | 両方 | VirtualBox、bootc ゲスト、kvm-container、Hyper-V、VMware Workstation Pro、Windows Sandbox |
| [WireGuard のセットアップ](docs/wireguard.md) | 両方 | 拠点間の VPN と、外出先の PC からの接続 |
| [Samba のセットアップ](docs/samba.md) | 両方 | Samba サーバーと、両 OS のクライアント |
| [Syncthing のセットアップ](docs/syncthing.md) | 両方 | フォルダの同期と、設定のバックアップ・復元 |
| [GNOME のリモート操作のセットアップ](docs/gnome-remote.md) | AlmaLinux 10 | デスクトップ共有、ヘッドレスセッション、リモートログイン |
| [Forgejo のセットアップ](docs/forgejo.md) | AlmaLinux 10 | Git サーバーの導入、公開、使い方、バックアップと更新 |

- 新しく入れた PC では、OS の初期設定（[Windows 11](docs/windows-setup.md) / [AlmaLinux 10](docs/almalinux-setup.md)）→ [シェルと端末](docs/shell-terminal.md) → 要る手順書の順に通す
- どの項も単独で通せる。項のリードの前提と実行場所を先に確かめる
- 手順書の無いツールと、導入元・版の比べは [ツール導入元一覧](docs/tool-catalog.md) で確かめる

## 用途から探す

### 共通の bash 設定を先に入れる

- AlmaLinux 10 はシェルと端末の「[共通の bash 設定](docs/shell-terminal.md#共通の-bash-設定)」、Windows 11 は同じ文書の「[Git Bash と WezTerm の設定](docs/shell-terminal.md#git-bash-と-wezterm-の設定)」で入れる

### OS のインストール

- Windows 11 と AlmaLinux 10 を 1 台のディスクに入れるときは、Windows 11 を先に入れる。Windows 11 のセットアップの「[Windows と AlmaLinux のデュアルブート](docs/windows-setup.md#windows-と-almalinux-のデュアルブート)」を通す。入れた後の起動の指定は「[次回だけ AlmaLinux で起動する](docs/windows-setup.md#windows-と-almalinux-のデュアルブート-次回だけ-almalinux-で起動する)」で行う

### 導入の基盤

- AlmaLinux 10 は RPM に無いか古いものを、CLI とフォントは [Homebrew](docs/almalinux-setup.md#homebrew)、GUI アプリはベンダーの dnf リポジトリ（[Firefox](docs/almalinux-setup.md#firefox)・[VS Code](docs/almalinux-setup.md#vs-code)）が無ければ [Flathub](docs/almalinux-setup.md#flatpak-と-flathub) で入れる（AppStream / BaseOS に無い RPM は [EPEL、Firefox の FFmpeg だけ RPM Fusion](docs/almalinux-setup.md#epel-と-rpm-fusion)）。インターネットに出られないホストは [Homebrew](docs/almalinux-setup.md#homebrew-のオフライン導入)・[npm](docs/almalinux-setup.md#npm-のオフライン導入) の項を通す
- Windows 11 では、CLI ツールは scoop、GUI アプリは UniGet UI（winget と scoop を画面で扱う）で入れる（Windows 11 のセットアップの「[アプリを入れる](docs/windows-setup.md#アプリを入れる)」）

### ほかの手順書が使う仕組み

- ほかの手順書が前提にする設定は、AlmaLinux 10 の [Caddy](docs/almalinux-setup.md#caddy)・[linger（ユーザーサービスの常駐）](docs/almalinux-setup.md#ユーザーサービスの常駐)・[ssh の SOCKS トンネル](docs/almalinux-setup.md#ssh-の-socks-トンネル)・[Secure Boot の MOK](docs/almalinux-setup.md#secure-boot-の署名鍵)、Windows 11 の[貼り付けの設定](docs/windows-setup.md#貼り付けの設定)・[LAN をプライベートにする手順](docs/windows-setup.md#ネットワークとリモート)にまとめてある。使う側の手順書は、その項を名指しする
- 設定はユーザーやホストに 1 つなので、別の用途で設定済みなら確認だけでよい

### デスクトップ

- AlmaLinux 10 は[日本語入力](docs/almalinux-setup.md#日本語入力)・[GNOME の表示と入力](docs/almalinux-setup.md#gnome-の表示と入力)・[画面オフ・画面ロック・自動サスペンド](docs/almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)、Windows 11 は[表示と入力](docs/windows-setup.md#表示と入力)・[表示・入力・音・ストレージ](docs/windows-setup.md#表示入力音ストレージを変える)を設定する

### リモート接続・VPN

- VPN は WireGuard の [AlmaLinux 10](docs/wireguard.md#wireguard)・[Windows 11](docs/wireguard.md#windows-11-で-wireguard-を使う)、GNOME は[デスクトップ共有](docs/gnome-remote.md#gnome-のデスクトップ共有)・[ヘッドレスセッション](docs/gnome-remote.md#gnome-のヘッドレスセッション)・[リモートログイン](docs/gnome-remote.md#gnome-のリモートログイン)から選ぶ
- Windows 11 の [OpenSSH サーバー](docs/windows-setup.md#openssh-サーバー)・[SSH クライアント](docs/windows-setup.md#windows-の-openssh-クライアント)・[RDP](docs/windows-setup.md#ネットワークとリモート)、AI エージェントの [Claude Code の Remote Control](docs/ai-agents.md#claude-code-の-remote-control-実施手順)・[Antigravity アプリの Remote Control](docs/ai-agents.md#antigravity-アプリの-remote-control任意)・Codeg（[AlmaLinux 10](docs/ai-agents.md#grok-build-のブラウザ操作-実施手順) / [Windows 11](docs/ai-agents.md#grok-build-のブラウザ操作-windows-11-で使う)）の手順を通す

### ファイル共有・同期

- 共有は Samba の[サーバー](docs/samba.md#samba-サーバー)・クライアント（[AlmaLinux 10](docs/samba.md#samba-クライアント) / [Windows 11](docs/samba.md#windows-11-で-samba-クライアントを使う)）、同期は Syncthing（[AlmaLinux 10](docs/syncthing.md#syncthing) / [Windows 11](docs/syncthing.md#windows-11-で-syncthing-を使う)）の手順を通す
- Dropbox は AlmaLinux 10 の「[Dropbox](docs/almalinux-setup.md#dropbox)」か「[Dropbox と rclone](docs/almalinux-setup.md#dropbox-と-rclone)」で入れる

### 端末とシェル

- シェルと端末の手順書の「[AlmaLinux 10 で使う](docs/shell-terminal.md#almalinux-10-で使う)」・「[Windows 11 で使う](docs/shell-terminal.md#windows-11-で使う)」で、シェルのツール・HackGen Console NF・WezTerm を入れ、Windows Terminal と PowerShell 7 の設定も行う

### ファイル・ディスク・リソースを見る

- bat・eza はシェルと端末の「[シェルのツール](docs/shell-terminal.md#シェルのツール)」（Windows 11 は「[シェルのツールを入れる](docs/shell-terminal.md#シェルのツールを入れる)」）、yazi は [AlmaLinux 10](docs/almalinux-setup.md#yazi)・[Windows 11](docs/windows-setup.md#yazi)、ディスク使用量は [gdu](docs/almalinux-setup.md#gdu)、CPU・メモリなどは [btop](docs/almalinux-setup.md#btop) で見る

### エディタ

- 端末では Neovim（[AlmaLinux 10](docs/neovim.md#neovim) / [Windows 11](docs/neovim.md#windows-11-で-neovim-を入れる)）、GUI では AlmaLinux 10 の [VS Code](docs/almalinux-setup.md#vs-code) を入れる

### git と GitHub

- Git は AlmaLinux 10 の「[Git](docs/almalinux-setup.md#git)」・Windows 11 の「[Git for Windows](docs/windows-setup.md#git-for-windows)」、git-delta・lazygit・GitHub CLI は [AlmaLinux 10](docs/almalinux-setup.md#git-と開発の道具)・[Windows 11](docs/windows-setup.md#git-と開発の道具) の「Git と開発の道具」で入れる
- 自分の Git サーバーは Forgejo の「[Forgejo](docs/forgejo.md#forgejo)」で入れ、画面の操作は「[使い方の基本](docs/forgejo.md#forgejo-使い方の基本)」で確かめる

### 開発の補助と AI エージェント

- シェルの検査は [ShellCheck と shfmt](docs/almalinux-setup.md#shellcheck-と-shfmt)、Claude Code・Codex CLI・Grok Build・Antigravity CLI の導入は AI エージェントの手順書の [AlmaLinux 10](docs/ai-agents.md#実施手順)・[Windows 11](docs/ai-agents.md#windows-11-で使う) を通す
- [Claude Code の使い方](docs/ai-agents.md#claude-code-の使い方の基本)・[共同作業](docs/ai-agents.md#コーディングエージェントの共同作業-実施手順)・[既定の分担](docs/ai-agents.md#コーディングエージェントの共同作業-既定で分担する)・[GNOME 操作](docs/ai-agents.md#claude-code-の-gnome-操作-実施手順)も、同じ手順書で設定・確認する

### コンテナ

- AlmaLinux 10 の [Podman](docs/almalinux-setup.md#podman) を入れ、[Quadlet での自動起動](docs/almalinux-setup.md#podman-quadlet-で自動起動する)・[Distrobox](docs/almalinux-setup.md#distrobox)・[podman-compose](docs/almalinux-setup.md#podman-compose)・[イメージの検査](docs/almalinux-setup.md#画像の道具)を用途に合わせて通す
- 端末の画面からは [podman-tui](docs/almalinux-setup.md#podman-tui)・[lazydocker](docs/almalinux-setup.md#lazydocker) で操作する

### 仮想化

- AlmaLinux 10 は [VirtualBox](docs/virtual-machines.md#virtualbox)・[bootc ゲスト](docs/virtual-machines.md#virtualbox-の-bootc-ゲスト)・[kvm-container](docs/virtual-machines.md#kvm-container)、Windows 11 は [Hyper-V](docs/virtual-machines.md#hyper-v)・[VirtualBox](docs/virtual-machines.md#windows-11-で-virtualbox-を入れる)・[VMware Workstation Pro](docs/virtual-machines.md#vmware-workstation-pro)・[Windows Sandbox](docs/virtual-machines.md#windows-sandbox-で配布物を試す) の項を通す

### ブラウザ

- Firefox は [AlmaLinux 10](docs/almalinux-setup.md#firefox)・[Windows 11](docs/windows-setup.md#firefox) の「Firefox」で入れる

### Windows の入力の切り分け

- キーを使っているアプリと、見つからないときの調べ方は、Windows 11 の「[Windows のホットキー競合](docs/windows-setup.md#windows-のホットキー競合)」で確かめる

検索・テキスト処理・パスワード管理など、手順書の無い用途のツールは [ツール導入元一覧](docs/tool-catalog.md) から探す。

## 置き場所

| 置くもの | 場所 |
|---|---|
| 理由・比較・資料 | `docs/reference/<手順書名>.md` |
| ロールバックと注意点 | `docs/extra/<手順書名>.md` |
| 実施日・環境・結果 | 非公開の `setup-notes-verification` の `docs/verification/<手順書名>.md` |
| 手順書を動かすスクリプト | [scripts/](scripts/) |
| 書き方の規則 | [AGENTS.md](AGENTS.md) と [docs/dev/writing-rules.md](docs/dev/writing-rules.md) |

## 記法

- 手順は番号付きリストにし、各手順は「1 行の説明 → コマンドのブロック → 確認・分岐・注意の箇条書き」の順にする。ロールバックと注意点は `docs/extra/` で確かめる（全体は [手順書の書き方](docs/dev/writing-rules.md)）
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- `sudo` はパスワードを聞かない設定（NOPASSWD）を前提にする（[AlmaLinux 10 の「ログインと sudo」の手順 3](docs/almalinux-setup.md#ログインと-sudo)で設定する）
- `sudo` の後ろに別のコマンドが続くブロックは、全体を `{` と `}` の行で囲む。ブラケットペーストが効かないとき（bash の `enable-bracketed-paste` が off など）に貼ると、`sudo` が後ろの行を読んで捨てるため（[実測](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/samba-client.md#付録-sudo-の後ろの行が失われる条件2026-09-28)）
- Windows の `powershell` のブロックは Windows PowerShell 5.1 に貼る。管理者の窓か通常の窓かは、各項のリードの実行場所に従う
- 未検証のことは手順書に明記する。パスワード・秘密鍵・トークンなどの秘密情報は残さない
