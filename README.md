# setup-notes

実機で検証した構築・設定手順と、失敗時の切り分けを記録するリポジトリ。
各文書は実施手順を先に置き、手順ごとの理由・実測・落とし穴はその手順の末尾に折り畳み、全体に関わる背景は後半の「補足」に載せている。

## 手順書とツール

- 役割ごとに分けてある。同じ役割の手順書は、表の列で違いを比べられる
- 対象はどれも AlmaLinux 10.2。検証範囲（実機か、コンテナのみか）は各手順書の補足の「状態」に書いてある
- 導入元（AppStream / EPEL / Homebrew / Flathub / ベンダーのリポジトリ）で選ぶなら、先に [CLI / GUI ツール導入元一覧](docs/tool-catalog.md) を見る
  - CLI・GUI の約 40 本について、推奨する導入元・版・aarch64 での提供の有無を比べた一覧で、手順書ではない（x86_64 はコンテナで導入まで確認、aarch64 はメタデータのみ）
  - 各節の「手順書の無いツール」の表は、この一覧のツールを役割で振り分けたもの。版・導入コマンド・ほかの経路は、名前のリンク先の一覧の行にある

### 導入の基盤

- RPM に無いか古いツールの入れ先。CLI とフォントは Homebrew、GUI アプリは Flathub
- Firefox と VS Code は Flathub を使わず、ベンダーの RPM で入れている
- EPEL の有効化は [btop.md 手順 1〜3](docs/btop.md#実施手順) にある（手順書の無いツールの EPEL の行は、これが前提）
- RPM Fusion（free）の有効化は [firefox.md 手順 8〜11](docs/firefox.md#実施手順) にある（EPEL も一緒に入る）
- ほかの導入元（AppStream / EPEL / COPR / AppImage など）との比較は、導入元一覧の[導入経路と EL10 での注意](docs/tool-catalog.md#導入経路と-el10-での注意)にある

| 手順書 | 入れるもの | 入る場所 | 権限 | 更新 | これを前提にするもの |
|---|---|---|---|---|---|
| [Homebrew](docs/homebrew.md) | CLI ツール、フォント（cask） | `/home/linuxbrew/.linuxbrew` | 一般ユーザーで使う（root では動かない） | `brew upgrade` | 導入元が Homebrew の手順書 13 本と、手順書の無いツールの Homebrew の行 |
| [Flatpak / Flathub](docs/flatpak.md) | GUI アプリ | `/var/lib/flatpak`（システム全体） | `sudo flatpak` で入れる | `sudo flatpak update`（`dnf upgrade` では上がらない） | 手順書の無いツールの Flathub の行 |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [Flatseal](docs/tool-catalog.md#gnomeシステム) | Flatpak アプリの権限を変える（GUI） | Flathub（[flatpak.md 手順 7](docs/flatpak.md#実施手順) の確認用に入る） |

### デスクトップ（GNOME）の設定

- どちらの手順書も GNOME のデスクトップが前提。自分のセッションは、設定アプリと同じキーを `gsettings` で変える
- 常時動かしておく PC（WireGuard・Samba・Syncthing・Dropbox のホスト、GNOME Remote Desktop で待ち受ける PC）は、ログイン画面と OS のサスペンドも止める

| 手順書 | 変えるもの | 変える範囲 | 仕組み | 導入するもの |
|---|---|---|---|---|
| [画面オフ・画面ロック・自動サスペンド](docs/gnome-power.md) | 画面を消す・暗くする・ロックする、放置でのサスペンド、電源ボタン、蓋 | 自分のセッション、ログイン画面、OS 全体 | `gsettings`、dconf の `/etc/dconf/db/gdm.d`、`systemctl mask`、logind のドロップイン | 無し |
| [日本語入力（IBus + Anthy）](docs/japanese-input.md) | 入力ソース（キーボードの配列と Anthy を Super+Space で切り替える） | 自分のセッション | `gsettings` の `org.gnome.desktop.input-sources` と IBus | `ibus-anthy` と日本語のフォント（Workstation には最初から入っている） |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [GNOME Tweaks](docs/tool-catalog.md#gnomeシステム) | GNOME の細かい設定（GUI） | EPEL |
| [Extension Manager](docs/tool-catalog.md#gnomeシステム) | GNOME 拡張の検索と導入（GUI） | Flathub |

### リモート接続・VPN

- WireGuard VPN は拠点に建てる側、Road Warrior は外出先の AlmaLinux PC からそこへつなぐ側。PC で作った鍵をホストの `client add --pubkey` で登録し、`client show` の conf を PC に取り込む
- GNOME Remote Desktop は VPN ではなく、RDP で PC にログインして画面を使う

| 手順書 | つなぐもの | 実行する場所 | 仕組み | 開けるポート |
|---|---|---|---|---|
| [WireGuard VPN](docs/wireguard.md) | 2 拠点の LAN 同士と、外出先のクライアント | 各拠点の WG ホスト（ルーターの配下） | `wg-vpn.sh`（値は `site.env` 1 ファイル）と `wg-quick@wg0` | `${WG_PORT}/udp`（例 51820） |
| [WireGuard Road Warrior](docs/wireguard-road-warrior.md) | 外出先の PC と両拠点の LAN | 外出先の PC（一部の手順は WG ホスト） | NetworkManager（`nmcli connection import`）。張る・切るは `nmcli connection up` / `down` | 無し（PC の firewalld は変えない） |
| [GNOME Remote Desktop](docs/gnome-remote-desktop.md) | RDP クライアントと PC のログイン画面 | 接続される PC | `grdctl --system`（システムデーモン。GDM で新しいセッションを作る） | 3389/tcp |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [Remmina](docs/tool-catalog.md#gnomeシステム) | リモートデスクトップのクライアント（GUI） | EPEL |
| [mosh](docs/tool-catalog.md#cli-定番の置き換え) | 回線が切れても続く SSH | EPEL |

### ファイル共有・同期

- Samba は、サーバーにある自分のホームを LAN・WireGuard 越しに SMB3 で読み書きする。Syncthing は、指定したフォルダを端末同士で同期する
- Samba クライアントは、その共有を AlmaLinux 10 の PC の `/mnt/<共有名>` に、アクセスしたときにマウントする。GNOME Files（`smb://`）で開く方法も同書にある
- 同じホストで両方使うときは、Syncthing の同期対象にホームを丸ごと入れない（Samba と同じ領域を二重に扱うことになる）
- Syncthing の鍵と設定は、[syncthing.md の任意節](docs/syncthing.md#設定を自動でバックアップする任意)で自動でバックアップし、送信専用フォルダで別の端末へ複製できる。戻し方も同書にある（この 2 節はコンテナのみで検証）
- Dropbox は、どちらの手順書も `~/Dropbox` をクラウドと同期する。公式クライアントは x86_64 にしか無いので、Raspberry Pi 5（aarch64）では rclone を使う
- `~/Dropbox` を Syncthing の同期フォルダに入れない（2 つの同期が同じファイルを書き合う）

| 手順書 | 方式 | 導入元 | 常駐 | 開けるポート |
|---|---|---|---|---|
| [Samba](docs/samba.md) | ホームディレクトリを SMB3 で公開（`[homes]` だけ） | BaseOS / AppStream | `smb.service`（システムのサービス） | 445/tcp だけ（NetBIOS は使わない） |
| [Samba クライアント](docs/samba-client.md) | Samba の共有を PC から SMB3 でマウント（`/etc/fstab` の `x-systemd.automount`）。GNOME Files でも開ける | BaseOS（`cifs-utils`）。GNOME Files は AppStream（`gvfs-smb`） | 無し（アクセスしたときに systemd がマウントし、1 分使わなければ外す） | 無し（サーバーの 445/tcp へ出るだけ） |
| [Syncthing](docs/syncthing.md) | フォルダを端末同士で同期。操作は Web GUI | Homebrew（EPEL 版は最新でなく、公式の RPM リポジトリは無い） | `brew services` のユーザーサービスと `loginctl enable-linger` | firewalld の `syncthing`（22000/tcp・udp、21027/udp）と `syncthing-gui`（8384/tcp） |
| [Dropbox（公式クライアント）](docs/dropbox.md) | `~/Dropbox` を Dropbox と常時同期する（x86_64 だけ）。操作は `dropbox` コマンド | Dropbox 公式の tarball（署名を確かめて `~/.dropbox-dist` に展開。公式 RPM は EL10 に入らない） | 自分で書く systemd ユーザーサービスと `loginctl enable-linger` | 無し（LAN 同期の `dropbox-lansync` は開けない） |
| [Dropbox（rclone）](docs/dropbox-rclone.md) | `rclone bisync` で `~/Dropbox` と Dropbox を 15 分ごとに双方向同期する（Raspberry Pi 5 向け） | Homebrew（EPEL 版は古い） | systemd ユーザータイマーと `loginctl enable-linger` | 無し |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [restic](docs/tool-catalog.md#cli-開発運用) | バックアップ | EPEL |
| [LocalSend](docs/tool-catalog.md#gnomeシステム) | LAN 内の端末とファイルを送り合う（GUI） | Flathub |

### 端末とシェル

- 変えるものがそれぞれ違うので、併用できる
- `~/.bashrc` に足す行は、starship を zoxide と WezTerm のシェル統合より後ろに置く
- eza のアイコンや starship の Nerd Font 前提のプリセットは、端末のフォントに Nerd Fonts のグリフ（HackGen Console NF など）が要る

| 手順書 | 変えるもの | 導入元 | 設定の置き場所 |
|---|---|---|---|
| [WezTerm Nightly](docs/wezterm-nightly.md) | 端末アプリ（GUI） | 公式 COPR の EL9 ビルド（chroot を明示） | `~/.wezterm.lua` か `~/.config/wezterm/wezterm.lua`（両方あると前者だけ読む） |
| [HackGen Console NF](docs/hackgen.md) | 端末のフォント（日本語と Nerd Fonts のアイコン） | Homebrew の cask | `~/.local/share/fonts` に入る（自分のユーザーだけ） |
| [starship](docs/starship.md) | シェルのプロンプト（`PS1`） | Homebrew（RPM 無し） | `~/.bashrc` に 1 行。`~/.config/starship.toml` は任意 |
| [zoxide](docs/zoxide.md) | ディレクトリの移動（`z`。`--cmd cd` なら `cd` も） | Homebrew（RPM 無し） | `~/.bashrc` に 1 行 |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [tmux](docs/tool-catalog.md#cli-定番の置き換え) | 端末の多重化 | Homebrew |
| [zellij](docs/tool-catalog.md#cli-定番の置き換え) | 端末の多重化（キー操作が画面に出る） | Homebrew |
| [atuin](docs/tool-catalog.md#cli-定番の置き換え) | シェル履歴の検索 | Homebrew |
| [fzf](docs/tool-catalog.md#cli-定番の置き換え) | 一覧から曖昧検索で選ぶ | Homebrew |
| [tealdeer](docs/tool-catalog.md#cli-定番の置き換え) | コマンドの使用例を引く（`tldr`） | Homebrew |

### ファイル・ディスク・リソースを見る

- 標準のコマンドは置き換えず、別の名前で使う（bat・eza の手順書は `alias cat=bat` / `alias ls=eza` を勧めない）
- 手順書では btop だけ EPEL の RPM で入れている（Homebrew と同じ版のため。duf・fastfetch も同じ理由で EPEL）。RPM なので `sudo btop` がそのまま動く
- Homebrew のもの（`gdu-go` など）は `sudo` の PATH に無いので、root で使うならフルパスで呼ぶ

| 手順書 | 見るもの | 近い標準のコマンド | 打つコマンド | 形 | 導入元 |
|---|---|---|---|---|---|
| [bat](docs/bat.md) | ファイルの中身（シンタックスハイライト、git 連携） | `cat` | `bat` | CLI | Homebrew（EPEL は 0.24 系） |
| [eza](docs/eza.md) | ディレクトリの一覧（git の状態、ツリー表示） | `ls` | `eza`、足したエイリアスの `ll` / `la` / `lt` | CLI | Homebrew（RPM 無し） |
| [yazi](docs/yazi.md) | ファイルの閲覧と操作（プレビュー、検索） | — | `y`（終了した場所へ移るシェル関数）、`yazi` | TUI | Homebrew（EPEL・AppStream に無い） |
| [gdu](docs/gdu.md) | ディスク使用量 | `du` | `gdu-go`（`gdu` ではない） | TUI | Homebrew（EPEL は 5.32 系で、コマンド名は `gdu`） |
| [btop](docs/btop.md) | CPU・メモリ・ディスク・ネットワーク・プロセス | `top` | `btop` | TUI | EPEL（Homebrew と同じ 1.4.7） |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [ncdu](docs/tool-catalog.md#cli-定番の置き換え) | ディスク使用量の TUI（gdu と同類） | Homebrew |
| [dust](docs/tool-catalog.md#cli-定番の置き換え) | `du` の見やすい版 | Homebrew |
| [duf](docs/tool-catalog.md#cli-定番の置き換え) | `df` の見やすい版 | EPEL |
| [htop](docs/tool-catalog.md#cli-定番の置き換え) | プロセスビューア | Homebrew |
| [fastfetch](docs/tool-catalog.md#cli-定番の置き換え) | システム情報の表示（neofetch の後継） | EPEL |
| [glow](docs/tool-catalog.md#cli-定番の置き換え) | Markdown を端末で読む | Homebrew |
| [Mission Center](docs/tool-catalog.md#gnomeシステム) | リソースモニタ（GUI） | Flathub |

### 検索・テキスト処理

- 手順書は無い。どれも Homebrew で入れる CLI
- `fd` は EPEL の `fd-find` と実行ファイルの名前が同じなので、両方は入れない（PATH の先頭にある Homebrew 版が勝つ）

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [ripgrep](docs/tool-catalog.md#cli-定番の置き換え) | 高速な grep（`rg`） | Homebrew |
| [fd](docs/tool-catalog.md#cli-定番の置き換え) | 使いやすい find | Homebrew |
| [jq](docs/tool-catalog.md#cli-定番の置き換え) | JSON の加工 | Homebrew |
| [yq](docs/tool-catalog.md#cli-定番の置き換え) | YAML / JSON / XML の加工（mikefarah 版） | Homebrew |

### エディタ

- 端末の中で使うなら Neovim、GUI なら VS Code
- lazygit の `e` キーで開くエディタは、lazygit.md の既定では `nvim`（`code` にもできる）
- Homebrew の nvim は `sudo` の PATH に無い。`sudoedit` / `visudo` で使うなら、`EDITOR` にフルパスを渡す

| 手順書 | 形 | 導入元 | 設定の置き場所 | 更新 |
|---|---|---|---|---|
| [Neovim](docs/neovim.md) | 端末の中（TUI）。`vi` は RPM の `vim-minimal` のまま | Homebrew（EPEL は 0.10 系） | `~/.config/nvim`（`init.lua` か `init.vim`） | `brew upgrade neovim` |
| [VS Code](docs/vscode.md) | GUI（Electron） | Microsoft 公式 dnf リポジトリ（EL 共通の rpm） | `~/.config/Code`、`~/.vscode`（`~/.config/code-flags.conf` は読まれない） | `sudo dnf upgrade code`（内蔵のアップデータは使わない） |

### git と GitHub

- 役割が違うので、併用できる
- lazygit は git の `core.pager` を読まない。lazygit でも delta で差分を出すなら、[git-delta.md の任意節](docs/git-delta.md#lazygit-と組み合わせる任意)で `git.paging` を足す

| 手順書 | 役割 | 打つコマンド | 導入元 | 設定の置き場所 |
|---|---|---|---|---|
| [lazygit](docs/lazygit.md) | git の TUI クライアント | `lazygit` | Homebrew（EPEL・AppStream に無い） | `~/.config/lazygit/config.yml` |
| [git-delta](docs/git-delta.md) | `git diff` / `show` / `log -p` の表示（ページャ） | `delta`（formula 名は `git-delta`。ふだんは git が呼ぶ） | Homebrew（RPM 無し） | `~/.gitconfig`（`git config --global` で書く） |
| [GitHub CLI](docs/gh.md) | GitHub の操作（`gh auth login` で認証） | `gh` | GitHub 公式 dnf リポジトリ（EPEL 版は古い） | `~/.config/gh/hosts.yml`（トークンが平文） |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [difftastic](docs/tool-catalog.md#cli-定番の置き換え) | 構文を理解する diff（`difft`。delta と併用できる） | Homebrew |
| [Meld](docs/tool-catalog.md#開発) | 差分・マージ（GUI） | EPEL |

### 開発の補助

- 言語処理系は AppStream / BaseOS にある（Node.js・Python・Go・Rust）。別の版が要るときに mise を使う

| 手順書 | 用途 | 導入元 | 更新 |
|---|---|---|---|
| [ShellCheck / shfmt](docs/shellcheck.md) | シェルスクリプトの静的検査と整形（`wg-vpn.sh` の検査にも使う） | Homebrew（shfmt に RPM が無いので、2 つとも揃えた） | `brew upgrade` |
| [Claude Code](docs/claude-code.md) | Claude Code の CLI（Node.js 不要） | Anthropic 公式 dnf リポジトリの `latest` チャンネル（`stable` も選べる） | `sudo dnf upgrade claude-code`（自動更新しない） |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [direnv](docs/tool-catalog.md#cli-開発運用) | ディレクトリごとの環境変数 | Homebrew |
| [mise](docs/tool-catalog.md#cli-開発運用) | 言語処理系の版の切り替え | [公式 dnf リポジトリ](docs/tool-catalog.md#ベンダーの-dnf-リポジトリ) |
| [uv](docs/tool-catalog.md#cli-開発運用) | Python のパッケージと仮想環境 | Homebrew |
| [chezmoi](docs/tool-catalog.md#cli-開発運用) | dotfiles の管理 | Homebrew |
| [just](docs/tool-catalog.md#cli-開発運用) | コマンドランナー（make の代わり） | Homebrew |
| [hyperfine](docs/tool-catalog.md#cli-開発運用) | コマンドのベンチマーク | Homebrew |

### 仮想化・コンテナ

- VirtualBox は x86_64 だけ。EPEL・モジュールのビルドの道具・（Secure Boot が有効なら）MOK の登録を先に用意する。EL10 のカーネルでは KVM と同時に動かない
- システムの podman と組んで使うもの（podman-compose・podman-tui・distrobox）は EPEL の RPM にしている（Homebrew 版の podman-compose は別の podman を連れてきて、システムの podman を隠した）
- lazydocker と dive は Docker の API を使う。podman の API ソケットで使えるかは試していない

| 手順書 | 用途 | 導入元 | ほかの経路 | アーキ |
|---|---|---|---|---|
| [VirtualBox](docs/virtualbox.md) | 仮想マシン | Oracle 公式 dnf リポジトリ（7.2 系） | RPM Fusion（EL10）・Flathub には無い | x86_64 だけ |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [podman-compose](docs/tool-catalog.md#cli-開発運用) | compose ファイルを podman で動かす | EPEL |
| [podman-tui](docs/tool-catalog.md#cli-開発運用) | podman の TUI | EPEL |
| [distrobox](docs/tool-catalog.md#cli-開発運用) | 別のディストリのユーザーランドをコンテナで使う | EPEL |
| [lazydocker](docs/tool-catalog.md#cli-開発運用) | コンテナの TUI | Homebrew |
| [dive](docs/tool-catalog.md#cli-開発運用) | コンテナイメージの層を調べる | Homebrew |
| [Podman Desktop](docs/tool-catalog.md#開発) | podman の GUI | Flathub |

### ブラウザ

- Firefox と Google Chrome は、ベンダーの公式 dnf リポジトリから入れる。`sudo dnf upgrade` で上がる
- Mozilla の Linux 版 Firefox は AAC と H.264 を自前で復号できないので、RPM Fusion（free）の FFmpeg（`ffmpeg-libs`）で補う（[firefox.md 手順 8〜14](docs/firefox.md#実施手順)）。入れないと、音声が AAC だけの動画が再生できない
- Microsoft Edge は x86_64 にしか無く、導入元一覧では導入元を決めていない（[aarch64 で使えないもの](docs/tool-catalog.md#aarch64-で使えないもの)に提供元だけ載せてある）

| 手順書 | 導入元 | ほかの経路 | アーキ |
|---|---|---|---|
| [Firefox](docs/firefox.md) | Mozilla 公式 dnf リポジトリ（最新版。4 週間ごとの Rapid Release）。AAC・H.264 の FFmpeg は RPM Fusion（free） | AppStream は ESR 140（年 1 回のメジャー更新） | x86_64・aarch64 |

| 手順書の無いツール | 導入元 | アーキ |
|---|---|---|
| [Google Chrome](docs/tool-catalog.md#ブラウザ) | [公式 dnf リポジトリ](docs/tool-catalog.md#ベンダーの-dnf-リポジトリ) | x86_64・aarch64 |
| [Chromium](docs/tool-catalog.md#ブラウザ) | EPEL（Flathub 版は新しいが、公開元が未検証） | x86_64・aarch64 |
| [Microsoft Edge](docs/tool-catalog.md#aarch64-で使えないもの) | 決めていない（公式 dnf リポジトリと Flathub にあるが、入れていない） | x86_64 だけ |

### パスワード管理

- 手順書は無い

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [KeePassXC](docs/tool-catalog.md#パスワード管理) | パスワード管理（ローカルのファイル） | EPEL |

## 記法

- タイトル直後の `## 実施手順` に、変数設定、コマンド、動作確認を番号付きリストで並べる。任意操作・更新・ロールバックはその後ろの見出しに置き、中の手順も番号付きリストにする（節ごとに 1 から）
- 手順番号は見出しではなくリストで振る。マーカーはすべて `1.`（自動で採番される）で、変数があれば手順 1 が変数設定
- 各手順は「1 行の説明（太字にしない 1 文）→ コマンドのブロック → 確認点の箇条書き → 折り畳んだ補足」の順に書く。対話入力や完了待ちで止めるところで手順を分け、止める手順の最後に「次の手順は〜してから貼る」と書く
- 環境固有値は冒頭の変数ブロック、または WireGuard の `site.env` で一度だけ設定する
- 変更が必須の変数は 1 変数ずつのコードブロック、変更が任意の変数は 1 つのブロックにまとめる
- 変える必要の無い値（固定の URL・パス・パッケージ名、ツールが既定の場所から読むパスなど）は変数にせず、コマンドに直接書く
- 手順ごとの理由・実測・落とし穴・出力例は、その手順の末尾に折り畳んだ（`<details>`）「補足」に置く。対象・検証環境、採用理由など全体に関わるものは後半の「補足」にまとめる
- 実行の前提（実行するユーザー、前提の手順書、対話入力のある手順）は `## 実施手順` の冒頭に `> [!IMPORTANT]` で示す。コンテナのみで検証した手順書は、検証範囲を `> [!WARNING]` で示す
- アラートは本文の最上位にだけ置く（GitHub は番号付きリストや折り畳みの中のアラートを描画しない）。手順の中の注意は太字の箇条書きにし、取り戻せない削除をする手順のある節では、そのリードに `> [!CAUTION]` を置いて手順を名指しする
- コマンドは実行済みのものを載せ、未検証事項は明記する
- 複数の手順書が共有する前提（Homebrew など）は独立した手順書にし、各手順書の冒頭から参照する
- [導入元一覧](docs/tool-catalog.md)は手順書ではないので、この骨格に従わない。冒頭に状態と調査日を `> [!WARNING]` で置き、表の各行に確認の深さ（起動 / 導入 / メタデータ）を書く
- 図は `docs/diagrams/*.diag`（構成図は nwdiag、パケットの流れは seqdiag）を原本にし、`python3 scripts/render-diagrams.py` で `*.svg` を生成する。SVG は直接編集しない（前提は [WireGuard の付録](docs/wireguard.md#付録-構成図の再生成)）
- パスワード、秘密鍵、トークンなどの秘密情報は残さない
