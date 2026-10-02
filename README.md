# setup-notes

実機で検証した構築・設定手順と、失敗時の切り分けを記録するリポジトリ。
各文書は実施手順を先に置き、手順ごとの理由・実測・落とし穴はその手順の末尾に折り畳み、全体に関わる背景は後半の「補足」に載せている。

## 手順書とツール

- 役割ごとに分けてある。同じ役割の手順書は、表の列で違いを比べられる
- 対象は AlmaLinux 10.2（[Windows の OpenSSH サーバー](docs/windows-openssh-server.md)と [Claude Code の Remote Control（Windows）](docs/windows-claude-remote-control.md)は Windows 11 だけ、[Git](docs/git.md) は Windows 11 の Git for Windows も）。検証範囲（実機か、コンテナのみか）は各手順書の補足の「状態」に書いてある
- 導入元（AppStream / EPEL / Homebrew / Flathub / ベンダーのリポジトリ）で選ぶなら、先に [CLI / GUI ツール導入元一覧](docs/tool-catalog.md) を見る
  - CLI・GUI の約 45 本について、推奨する導入元・版・aarch64 での提供の有無を比べた一覧で、手順書ではない（x86_64 はコンテナで導入まで確認、aarch64 はメタデータのみ）
  - 各節の「手順書の無いツール」の表は、この一覧のツールを役割で振り分けたもの。版・導入コマンド・ほかの経路は、名前のリンク先の一覧の行にある
- Neovim・WezTerm・lazygit・yazi の自分用の設定（カスタマイズ）は、ツールごとの別のリポジトリにある。各手順書の「設定ファイル」の節から案内している（[Neovim](docs/neovim.md#設定ファイル)・[WezTerm](docs/wezterm-nightly.md#設定ファイル)・[lazygit](docs/lazygit.md#設定ファイル)・[yazi](docs/yazi.md#設定ファイル)）
- 手順書が `~/.bashrc` に書く行（Homebrew・zoxide・starship・yazi の `y`・eza・gdu・bat・Neovim・podman・WezTerm のシェル統合）は、自分用の bash の設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)。非公開）にまとめてある。どのホストにも同じものを clone し、入っているツールの分だけ読む。入れたホストでは、各手順書の `~/.bashrc` に書くブロックは貼らない（その手順の箇条書きにある）

### 導入の基盤

- RPM に無いか古いツールの入れ先。CLI とフォントは Homebrew、GUI アプリは Flathub
- インターネットに出られないホストでも、そこへ ssh でログインできるホストを経由すれば Homebrew を使える（[homebrew-offline.md](docs/homebrew-offline.md)。トンネルは[ssh の SOCKS トンネル](docs/ssh-socks-tunnel.md)）。経由するのは入れる・上げるときだけで、入れたコマンドは ssh を閉じた後も動く
- 同じトンネルで、Neovim の Mason が npm で入れる LSP サーバー・リンターも入れられる（[npm-offline.md](docs/npm-offline.md)。npm は `ALL_PROXY` を読まないので、`https_proxy` を足す）
- Firefox と VS Code は Flathub を使わず、ベンダーの RPM で入れている
- AppStream / BaseOS に無い RPM は EPEL から入れる。Firefox の AAC・H.264 に使う FFmpeg だけは RPM Fusion（free）から入れ、RPM Fusion は EPEL を前提にする
- ほかの導入元（AppStream / EPEL / COPR / AppImage など）との比較は、導入元一覧の[導入経路と EL10 での注意](docs/tool-catalog.md#導入経路と-el10-での注意)にある

| 手順書 | 入れるもの | 入る場所 | 権限 | 更新 | これを前提にするもの |
|---|---|---|---|---|---|
| [Homebrew](docs/homebrew.md) | CLI ツール、フォント（cask） | `/home/linuxbrew/.linuxbrew` | 一般ユーザーで使う（`brew` は root では動かない。入れたコマンドは、任意の節で root のシェルや `sudo` からも使える） | `brew upgrade` | 導入元が Homebrew の手順書 16 本と、手順書の無いツールの Homebrew の行 |
| [Homebrew（インターネットに出られないホスト）](docs/homebrew-offline.md) | Homebrew と、Homebrew で入れるもの（出られるホストから [ssh の SOCKS トンネル](docs/ssh-socks-tunnel.md)を張り、そのプロキシを通して入れる） | `/home/linuxbrew/.linuxbrew`（Homebrew と同じ） | 一般ユーザーで使う（出られるホストから ssh でログインする） | トンネルを張ってから `brew upgrade` | インターネットに出られないホストで通す、導入元が Homebrew の手順書とツール、[npm（インターネットに出られないホスト）](docs/npm-offline.md) |
| [npm（インターネットに出られないホスト）](docs/npm-offline.md) | Node.js と npm（AppStream の 22 系）と、Neovim の Mason が npm で入れる LSP サーバー・リンター（[ssh の SOCKS トンネル](docs/ssh-socks-tunnel.md)を、`https_proxy` で npm に使わせる） | Node.js と npm は `/usr/bin`（システム全体）。Mason が入れるものは `~/.local/share/nvim/mason` | Node.js と npm は `sudo dnf` で入れる。Mason は一般ユーザーの Neovim から動く | トンネルを張り `https_proxy` を入れてから、`sudo dnf upgrade` と Mason の画面の `U` | インターネットに出られないホストで使う、Mason を使う Neovim の設定（LazyVimStarter など） |
| [Flatpak / Flathub](docs/flatpak.md) | GUI アプリ | `/var/lib/flatpak`（システム全体） | `sudo flatpak` で入れる | `sudo flatpak update`（`dnf upgrade` では上がらない） | 手順書の無いツールの Flathub の行 |
| [EPEL](docs/epel.md) | AppStream / BaseOS に無い RPM（Fedora のプロジェクトが EL 向けに作る） | システム全体。repo ファイルは `/etc/yum.repos.d/epel.repo`（extras の `epel-release` が置く） | `sudo dnf` で入れる | `sudo dnf upgrade`（`epel-release` 自身も上がる） | btop・distrobox・podman-compose・podman-tui・VirtualBox（依存の `liblzf`）・RPM Fusion と、手順書の無いツールの EPEL の行 |
| [RPM Fusion（free）](docs/rpmfusion.md) | Fedora・EL の標準のリポジトリに無い RPM（FFmpeg など） | システム全体。repo ファイルは `/etc/yum.repos.d/rpmfusion-free-updates.repo` | `sudo dnf` で入れる | `sudo dnf upgrade` | [Firefox](docs/firefox.md) の AAC・H.264（手順 8〜11） |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [Flatseal](docs/tool-catalog.md#gnomeシステム) | Flatpak アプリの権限を変える（GUI） | Flathub（[flatpak.md 手順 6](docs/flatpak.md#実施手順) の確認用に入る） |

### ほかの手順書が使う仕組み

- 複数の手順書が同じ設定を前提にするので、独立させてある。使う側の手順書は、冒頭の `> [!IMPORTANT]`（任意節の前提なら、その節の冒頭）から案内している
- 設定はユーザーやホストに 1 つなので、どれか 1 本の手順書のために通してあれば、ほかの手順書では確かめるだけでよい。元に戻すのは、使う手順書がどれも無くなったとき

| 手順書 | すること | 変わるもの | これを前提にするもの |
|---|---|---|---|
| [linger](docs/linger.md) | ログアウトしている間も、自分のユーザーの systemd（ユーザーのサービス・タイマー・Quadlet のコンテナ）を動かす | `/var/lib/systemd/linger/<USER>`（`sudo loginctl enable-linger`） | Syncthing・Dropbox・Dropbox（rclone）・Podman の Quadlet（任意節） |
| [ssh の SOCKS トンネル](docs/ssh-socks-tunnel.md) | インターネットに出られないホストから、そこへ ssh でログインしてくるホストを経由して外に出る（`ssh -R 1080`） | 無し（ssh の間だけ。任意で `/etc/dnf/dnf.conf` の `proxy=`） | Homebrew（インターネットに出られないホスト）・npm（インターネットに出られないホスト） |
| [Secure Boot の MOK 登録](docs/secure-boot-mok.md) | Secure Boot のまま、自分でビルドしたカーネルモジュールを読み込めるようにする（署名鍵を作り、起動の途中の MokManager で登録する） | `/var/lib/shim-signed/mok/MOK.{der,priv}` と UEFI の MOK | VirtualBox・VirtualBox Guest Additions（bootc のゲスト）。どちらも Secure Boot が有効なときだけ |

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
- ヘッドレスのセッションは、モニターの無い PC に常駐させた自分の GNOME のデスクトップに、RDP でつなぐ（リモートログインと違い、つなぎ直しても同じデスクトップに戻る。同じ PC で併用できる）。前提は画面オフ・画面ロック・自動サスペンドの手順 1・2（サスペンドできる PC では手順 3・4 も）
- Windows の OpenSSH サーバーは、Windows 11 の PC に AlmaLinux などの `ssh` で入る側。Windows のユーザーのパスワードで入る（公開鍵での認証と、パスワード認証を切るのは任意節）
- Claude Code の Remote Control（Windows）は VPN でも SSH でもなく、Anthropic の API 経由でスマートフォンやブラウザから Windows 11 の PC の Claude Code を操作する。SSH で入ってタスク スケジューラのタスクを登録・開始し、タスクが WezTerm で起動した Claude Code は SSH を切った後も動く（Windows の OpenSSH サーバーが前提）
- AlmaLinux 10 のホストでは、SSH で入って tmux の中で `claude remote-control` を動かす（[tmux の任意節](docs/tmux.md#claude-code-を-tmux-の中で動かす任意)。接続は未検証）

| 手順書 | つなぐもの | 実行する場所 | 仕組み | 開けるポート |
|---|---|---|---|---|
| [WireGuard VPN](docs/wireguard.md) | 2 拠点の LAN 同士と、外出先のクライアント | 各拠点の WG ホスト（ルーターの配下） | `wg-vpn.sh`（値は `site.env` 1 ファイル）と `wg-quick@wg0` | `${WG_PORT}/udp`（例 51820） |
| [WireGuard Road Warrior](docs/wireguard-road-warrior.md) | 外出先の PC と両拠点の LAN | 外出先の PC（一部の手順は WG ホスト） | NetworkManager（`nmcli connection import`）。張る・切るは `nmcli connection up` / `down` | 無し（PC の firewalld は変えない） |
| [GNOME Remote Desktop](docs/gnome-remote-desktop.md) | RDP クライアントと PC のログイン画面 | 接続される PC | `grdctl --system`（システムデーモン。GDM で新しいセッションを作る） | 3389/tcp |
| [GNOME のヘッドレスのセッション](docs/gnome-headless-session.md) | RDP クライアントと、モニターの無い PC に常駐させた GNOME のデスクトップ | 接続される PC（セッションを使うユーザーのシェル） | GDM の `gnome-headless-session@<USER>.service` と `grdctl --headless`（ユーザーのデーモン） | 3389/tcp（リモートログインと併用なら 3390/tcp） |
| [Windows の OpenSSH サーバー](docs/windows-openssh-server.md) | SSH クライアントと Windows 11 の PC | 接続される PC（Windows。接続はクライアント） | Windows のオプション機能 `OpenSSH.Server`（サービス `sshd`）とパスワード認証（公開鍵は任意） | 22/tcp（プライベートのネットワークだけ） |
| [Claude Code の Remote Control（Windows）](docs/windows-claude-remote-control.md) | スマートフォン・ブラウザの Claude アプリと、Windows 11 の PC で動く Claude Code | 接続される PC（Windows。SSH でログインした PowerShell に貼る。確認はスマートフォンかブラウザ） | タスク スケジューラのタスクで WezTerm を起動し、その中で `claude remote-control` を動かす（SSH の子プロセスにしない） | 無し（外向きの HTTPS だけ） |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [Remmina](docs/tool-catalog.md#gnomeシステム) | リモートデスクトップのクライアント（GUI） | EPEL |
| [mosh](docs/tool-catalog.md#cli-定番の置き換え) | 回線が切れても続く SSH | EPEL |

### ファイル共有・同期

- Samba は、サーバーにある自分のホームを LAN・WireGuard 越しに SMB3 で読み書きする（任意で root のホームも、自分のユーザーのまま）。Syncthing は、指定したフォルダを端末同士で同期する
- Samba クライアントは、その共有を AlmaLinux 10 の PC の `/mnt/<共有名>` に、アクセスしたときにマウントする。GNOME Files（`smb://`）で開く方法も同書にある
- 同じホストで両方使うときは、Syncthing の同期対象にホームを丸ごと入れない（Samba と同じ領域を二重に扱うことになる）
- Syncthing の鍵と設定は、[syncthing.md の任意節](docs/syncthing.md#設定を自動でバックアップする任意)で自動でバックアップし、送信専用フォルダで別の端末へ複製できる。戻し方も同書にある（この 2 節はコンテナのみで検証）
- Dropbox は、どちらの手順書も `~/Dropbox` をクラウドと同期する。公式クライアントは x86_64 にしか無いので、Raspberry Pi 5（aarch64）では rclone を使う
- `~/Dropbox` を Syncthing の同期フォルダに入れない（2 つの同期が同じファイルを書き合う）

| 手順書 | 方式 | 導入元 | 常駐 | 開けるポート |
|---|---|---|---|---|
| [Samba](docs/samba.md) | ホームディレクトリを SMB3 で公開（`[homes]`。任意で root のホームを `[root]` 共有で） | BaseOS / AppStream | `smb.service`（システムのサービス） | 445/tcp だけ（NetBIOS は使わない） |
| [Samba クライアント](docs/samba-client.md) | Samba の共有を PC から SMB3 でマウント（`/etc/fstab` の `x-systemd.automount`）。GNOME Files でも開ける | BaseOS（`cifs-utils`）。GNOME Files は AppStream（`gvfs-smb`） | 無し（アクセスしたときに systemd がマウントし、1 分使わなければ外す） | 無し（サーバーの 445/tcp へ出るだけ） |
| [Syncthing](docs/syncthing.md) | フォルダを端末同士で同期。操作は Web GUI | Homebrew（EPEL 版は最新でなく、公式の RPM リポジトリは無い） | `brew services` のユーザーサービスと [linger](docs/linger.md) | firewalld の `syncthing`（22000/tcp・udp、21027/udp）と `syncthing-gui`（8384/tcp） |
| [Dropbox（公式クライアント）](docs/dropbox.md) | `~/Dropbox` を Dropbox と常時同期する（x86_64 だけ）。操作は `dropbox` コマンド | Dropbox 公式の tarball（署名を確かめて `~/.dropbox-dist` に展開。公式 RPM は EL10 に入らない） | 自分で書く systemd ユーザーサービスと [linger](docs/linger.md) | 無し（LAN 同期の `dropbox-lansync` は開けない） |
| [Dropbox（rclone）](docs/dropbox-rclone.md) | `rclone bisync` で `~/Dropbox` と Dropbox を 15 分ごとに双方向同期する（Raspberry Pi 5 向け） | Homebrew（EPEL 版は古い） | systemd ユーザータイマーと [linger](docs/linger.md) | 無し |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [restic](docs/tool-catalog.md#cli-開発運用) | バックアップ | EPEL |
| [LocalSend](docs/tool-catalog.md#gnomeシステム) | LAN 内の端末とファイルを送り合う（GUI） | Flathub |

### 端末とシェル

- 変えるものがそれぞれ違うので、併用できる
- `~/.bashrc` に足す行は、Homebrew の `brew shellenv` → starship → WezTerm のシェル統合 → zoxide の順に置く（starship が WezTerm のシェル統合より後ろにあると、この設定のシェル統合が働くとき〔COPR の公式の統合が無いとき〕は、OSC 133 の終了コードがいつも 0 になる。[starship.md 手順 3](docs/starship.md#実施手順) の補足。自分用の bash の設定を入れたホストでは、その設定の読む順番に任せる）
- eza のアイコンや starship の Nerd Font 前提のプリセットは、端末のフォントに Nerd Fonts のグリフ（HackGen Console NF など）が要る

| 手順書 | 変えるもの | 導入元 | 設定の置き場所 |
|---|---|---|---|
| [WezTerm Nightly](docs/wezterm-nightly.md) | 端末アプリ（GUI） | 公式 COPR の EL9 ビルド（chroot を明示） | `~/.wezterm.lua` か `~/.config/wezterm/wezterm.lua`（両方あると前者だけ読む） |
| [HackGen Console NF](docs/hackgen.md) | 端末のフォント（日本語と Nerd Fonts のアイコン） | Homebrew の cask | `~/.local/share/fonts` に入る（自分のユーザーだけ） |
| [starship](docs/starship.md) | シェルのプロンプト（`PS1`） | Homebrew（RPM 無し） | `~/.bashrc` に 1 行。`~/.config/starship.toml` は任意 |
| [zoxide](docs/zoxide.md) | ディレクトリの移動（`z`。`--cmd cd` なら `cd` も） | Homebrew。x86_64 は COPR（`kray74/cli-tools`）の dnf でも入る（EPEL・AppStream に無い） | `~/.bashrc` に 1 行 |
| [tmux](docs/tmux.md) | 端末の多重化（SSH を切ってもシェルとコマンドが残る。Claude Code を動かし続けるのにも使う） | Homebrew（BaseOS は 3.3a） | `~/.config/tmux/tmux.conf`（任意） |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [zellij](docs/tool-catalog.md#cli-定番の置き換え) | 端末の多重化（キー操作が画面に出る） | Homebrew |
| [atuin](docs/tool-catalog.md#cli-定番の置き換え) | シェル履歴の検索 | Homebrew |
| [fzf](docs/tool-catalog.md#cli-定番の置き換え) | 一覧から曖昧検索で選ぶ | Homebrew |
| [tealdeer](docs/tool-catalog.md#cli-定番の置き換え) | コマンドの使用例を引く（`tldr`） | Homebrew |

### ファイル・ディスク・リソースを見る

- 標準のコマンドは置き換えず、別の名前で使う（bat・eza の手順書は `alias cat=bat` / `alias ls=eza` を勧めない）
- この節の手順書では btop だけ EPEL の RPM で入れている（Homebrew と同じ版のため。duf・fastfetch も同じ理由で EPEL）。RPM なので `sudo btop` がそのまま動く
- Homebrew のもの（`gdu-go` など）は、そのままでは `sudo` の PATH に無い。`sudo gdu-go` のように使うなら [homebrew.md の sudo でも使う](docs/homebrew.md#sudo-でも使う任意)の節を通す（通さないならフルパスで呼ぶ）

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
- Homebrew の nvim は、そのままでは `sudo` の PATH に無く、`EDITOR=nvim` でも `sudoedit` は黙って `vi` で開く。[homebrew.md の sudo でも使う](docs/homebrew.md#sudo-でも使う任意)の節を通すと、`sudoedit` が自分の設定の nvim で開く（通さないなら `SUDO_EDITOR` にフルパスを渡す）
- インターネットに出られないホストでは、Neovim は [homebrew-offline.md](docs/homebrew-offline.md) のトンネルで入れ、Mason の npm のパッケージは [npm-offline.md](docs/npm-offline.md) で入れる

| 手順書 | 形 | 導入元 | 設定の置き場所 | 更新 |
|---|---|---|---|---|
| [Neovim](docs/neovim.md) | 端末の中（TUI）。`vi` は RPM の `vim-minimal` のまま | Homebrew（EPEL は 0.10 系） | `~/.config/nvim`（`init.lua` か `init.vim`） | `brew upgrade neovim` |
| [VS Code](docs/vscode.md) | GUI（Electron） | Microsoft 公式 dnf リポジトリ（EL 共通の rpm） | `~/.config/Code`、`~/.vscode`（`~/.config/code-flags.conf` は読まれない） | `sudo dnf upgrade code`（内蔵のアップデータは使わない） |

### git と GitHub

- 役割が違うので、併用できる
- [Git](docs/git.md) は git 本体と `~/.gitconfig` の基本の設定（pull は rebase と autostash、改行を変換しない、推奨の設定）。AlmaLinux 10 と Windows 11 の Git for Windows で同じ設定にする
- `merge.conflictStyle zdiff3` は、Git と git-delta の両方の手順書で入れる（同じ値なので、どちらを先に通してもよい）
- lazygit は git の `core.pager` を読まない。lazygit でも delta で差分を出すなら、[git-delta.md の任意節](docs/git-delta.md#lazygit-と組み合わせる任意)で `git.paging` を足す

| 手順書 | 役割 | 打つコマンド | 導入元 | 設定の置き場所 |
|---|---|---|---|---|
| [Git](docs/git.md) | git 本体と基本の設定（pull は rebase・autostash、`core.autocrlf=false`、推奨の設定） | `git` | AppStream（Windows 11 は Git for Windows） | `~/.gitconfig`（`git config --global` で書く） |
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
| [Claude Code](docs/claude-code.md) | Claude Code の CLI（Node.js 不要）と、`claude` のコマンドラインの使い方（起動と再開・`-p`・MCP） | Anthropic 公式 dnf リポジトリの `latest` チャンネル（`stable` も選べる） | `sudo dnf upgrade claude-code`（自動更新しない） |
| [Claude Code で GUI を確かめる](docs/claude-code-gui.md) | Claude Code が、ヘッドレスのセッションの画面を撮り、キーボードとポインタで操作して GUI の動作を確かめる（前提は GNOME のヘッドレスのセッション） | このリポジトリの [`scripts/gnome-gui.py`](scripts/gnome-gui.py)（Mutter の ScreenCast / RemoteDesktop）と、gnome-shell の `--virtual-monitor` | このリポジトリの `git pull` |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [direnv](docs/tool-catalog.md#cli-開発運用) | ディレクトリごとの環境変数 | Homebrew |
| [mise](docs/tool-catalog.md#cli-開発運用) | 言語処理系の版の切り替え | [公式 dnf リポジトリ](docs/tool-catalog.md#ベンダーの-dnf-リポジトリ) |
| [uv](docs/tool-catalog.md#cli-開発運用) | Python のパッケージと仮想環境 | Homebrew |
| [chezmoi](docs/tool-catalog.md#cli-開発運用) | dotfiles の管理 | Homebrew |
| [just](docs/tool-catalog.md#cli-開発運用) | コマンドランナー（make の代わり） | Homebrew |
| [hyperfine](docs/tool-catalog.md#cli-開発運用) | コマンドのベンチマーク | Homebrew |

### コンテナ

- 土台は [Podman](docs/podman.md)（AppStream）で、コンテナを自分のユーザー（rootless）で動かす。ほかの 5 本と手順書の無いツールは、これを前提にしている
- podman 本体と、システムの podman と組んで使うもの（podman-compose・podman-tui・distrobox・toolbox・buildah・skopeo）は RPM にしている
  - Homebrew 版の podman-compose は別の podman を連れてきて、システムの podman を隠した
  - Homebrew の podman・skopeo は、`/etc/containers` の設定を読まない
  - Homebrew の podman-tui は 2.x で、podman 6 向け（AlmaLinux 10 の podman は 5）
- podman の API ソケット（[podman.md 手順 7](docs/podman.md#実施手順)）を、Trivy・podman-tui・Pods・Podman Desktop が使う
  - lazydocker など Docker の API を使うツールは、`DOCKER_HOST` で同じソケットに向ける
  - dive は podman のコマンドでイメージを読むので、ソケットは要らない
- PC の起動時に動かしておくコンテナは、podman.md の任意節（Quadlet）で動かす（[linger](docs/linger.md) が前提）

| 手順書 | 用途 | 打つコマンド | 導入元 | 前提 |
|---|---|---|---|---|
| [Podman](docs/podman.md) | コンテナを自分のユーザーで動かす。API ソケット、Quadlet での自動起動（任意） | `podman` | AppStream（Homebrew 版はシステムの podman を隠すので使わない） | — |
| [distrobox](docs/distrobox.md) | 別のディストリ（既定は Ubuntu 24.04）の端末とパッケージを使う。入れたコマンドはホストから呼べる | `distrobox create` / `enter` | EPEL | Podman、EPEL |
| [podman-compose](docs/podman-compose.md) | compose ファイルで、複数のコンテナをまとめて動かす | `podman-compose`（`podman compose` からも呼ばれる） | EPEL | Podman、EPEL |
| [hadolint / dive / Trivy](docs/image-tools.md) | イメージを作るときの検査（Containerfile の書き方、層の無駄、脆弱性） | `hadolint` / `dive` / `trivy`（作るのは `podman build`） | Homebrew と Trivy の公式 dnf リポジトリ | Podman、Homebrew |
| [podman-tui](docs/podman-tui.md) | podman のコンテナ・pod・イメージ・ボリューム・ネットワーク・シークレットを、端末の画面（TUI）で見て操作する | `podman-tui`（終了は `Ctrl+C`） | EPEL（Homebrew の 2.x は podman 6 向け） | Podman、EPEL |
| [lazydocker](docs/lazydocker.md) | コンテナの TUI。ログと CPU の使用率が見やすい。compose のサービスも見られる（任意節） | `lazydocker` | Homebrew（RPM 無し） | Podman（Docker 向けの節まで）、Homebrew |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [toolbox](docs/tool-catalog.md#cli-コンテナ) | 別のディストリの端末をコンテナで使う（distrobox と同類。RHEL の公式） | AppStream |
| [podman-docker](docs/tool-catalog.md#cli-コンテナ) | `docker` コマンドを podman に読み替える | AppStream |
| [buildah](docs/tool-catalog.md#cli-コンテナ) | Containerfile を使わずにイメージを作る | AppStream |
| [skopeo](docs/tool-catalog.md#cli-コンテナ) | レジストリのイメージを取得せずに調べる・コピーする | AppStream |
| [podlet](docs/tool-catalog.md#cli-コンテナ) | podman のコマンドや compose ファイルから Quadlet の定義を作る | Homebrew |
| [cosign](docs/tool-catalog.md#cli-コンテナ) | イメージの署名と検証 | Homebrew |
| [Podman Desktop](docs/tool-catalog.md#コンテナ) | podman の GUI | Flathub |
| [Pods](docs/tool-catalog.md#コンテナ) | podman の GUI（GNOME のアプリ） | Flathub |
| [BoxBuddy](docs/tool-catalog.md#コンテナ) | distrobox の GUI | Flathub |
| [Cockpit の podman の画面](docs/tool-catalog.md#コンテナ) | ブラウザからコンテナを操作する | AppStream / BaseOS |

### 仮想化

- VirtualBox は x86_64 だけ。[EPEL](docs/epel.md)・モジュールのビルドの道具・（Secure Boot が有効なら）[MOK の登録](docs/secure-boot-mok.md)を先に用意する。EL10 のカーネルでは KVM と同時に動かない
- ゲスト側の Guest Additions は、VM が bootc（AlmaLinux Atomic Desktop）なら dnf では入らない。派生イメージを VM でビルドし、`bootc switch` で切り替える（`/usr`・`/opt` は読み取り専用で、`/var` はイメージから更新されない）
  - Secure Boot が有効な VM では、ゲストでも同じ [MOK の登録](docs/secure-boot-mok.md)を先に行う（鍵はホストとは別）
  - ホストが Windows 11 の VirtualBox でも、同じ手順で入る。Hyper-V（WSL 2 など）が動いている Windows では、重い処理の途中で VM が数分ずつ止まることがある（VM のウィンドウでキーを押すと動き出す）
  - VM がホストオンリーアダプターだけでインターネットに出られないときは、ホスト（Windows では WSL の AlmaLinux 10）の rootless の podman で同じ Containerfile をビルドし、`podman save` のファイルを ssh で VM に運んで `podman load` する。ベースの署名は VM の `policy.json` と公開鍵をホストに写して確かめ、Secure Boot の鍵はホストで作る

| 手順書 | 用途 | 導入元 | ほかの経路 | アーキ |
|---|---|---|---|---|
| [VirtualBox](docs/virtualbox.md) | 仮想マシン | Oracle 公式 dnf リポジトリ（7.2 系） | RPM Fusion（EL10）・Flathub には無い | x86_64 だけ |
| [VirtualBox Guest Additions（bootc のゲスト）](docs/virtualbox-guest-bootc.md) | VM の中のクリップボードの共有・画面サイズの自動変更・共有フォルダー | ホストの Guest Additions の CD を、VM でビルドする派生イメージに焼き込む | AppStream・EPEL 10・ELRepo に無く、EL10 のカーネルにもドライバが無い | x86_64 だけ |

### ブラウザ

- Firefox と Google Chrome は、ベンダーの公式 dnf リポジトリから入れる。`sudo dnf upgrade` で上がる
- Mozilla の Linux 版 Firefox は AAC と H.264 を自前で復号できないので、RPM Fusion（free）の FFmpeg（`ffmpeg-libs`）で補う（[rpmfusion.md](docs/rpmfusion.md) で有効にし、[firefox.md 手順 8〜11](docs/firefox.md#実施手順) で入れる）。入れないと、音声が AAC だけの動画が再生できず、YouTube で 720p 以上が H.264 だけの動画は 360p までしか選べないことがある
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
- コマンドの無い操作（GUI・ブラウザ・起動途中の画面・別のマシンや機器・ログインし直す）も、コマンドのブロックを置かない 1 つの手順にする。手順のコマンドが開いたエディタや TUI への入力は、その手順の箇条書きに書く
- `sudo` はパスワードを聞かない設定（NOPASSWD）を前提にしている
- `sudo` の後ろに別のコマンドが続くブロックは、全体を `{` と `}` の行で囲む。ブラケットペーストが効かないとき（bash の `enable-bracketed-paste` が off など）に貼ると、`sudo` が後ろの行を読んで捨てるため（[実測](docs/samba-client.md#付録-sudo-の後ろの行が失われる条件2026-09-28)）
- Windows で実行する手順（[Windows の OpenSSH サーバー](docs/windows-openssh-server.md)・[Claude Code の Remote Control（Windows）](docs/windows-claude-remote-control.md)）のブロックは `powershell` で、管理者の Windows PowerShell 5.1 に貼る（後者は SSH でログインした昇格済みの PowerShell）。`sudo` と `{ }` の規則はかからず、変数の空は `if … else` で弾く。[Git](docs/git.md) の Windows だけは、Git for Windows の Git Bash に AlmaLinux 10 と同じ bash のブロックを貼る
- 環境固有値は冒頭の変数ブロック、または WireGuard の `site.env` で一度だけ設定する
- 変更が必須の変数は 1 変数ずつのコードブロック、変更が任意の変数は 1 つのブロックにまとめる
- 変える必要の無い値（固定の URL・パス・パッケージ名、ツールが既定の場所から読むパスなど）は変数にせず、コマンドに直接書く
- 手順ごとの理由・実測・落とし穴・出力例は、その手順の末尾に折り畳んだ（`<details>`）「補足」に置く。対象・検証環境、採用理由など全体に関わるものは後半の「補足」にまとめる
- 実行の前提（実行するユーザー、前提の手順書、対話入力のある手順）は `## 実施手順` の冒頭に `> [!IMPORTANT]` で示す。コンテナのみで検証した手順書は、検証範囲を `> [!WARNING]` で示す
- アラートは本文の最上位にだけ置く（GitHub は番号付きリストや折り畳みの中のアラートを描画しない）。手順の中の注意は太字の箇条書きにし、取り戻せない削除をする手順のある節では、そのリードに `> [!CAUTION]` を置いて手順を名指しする
- コマンドは実行済みのものを載せ、未検証事項は明記する
- 複数の手順書が共有する前提（Homebrew・Podman・EPEL・linger・Secure Boot の MOK・ssh の SOCKS トンネルなど）は独立した手順書にし、各手順書の冒頭から参照する
- [導入元一覧](docs/tool-catalog.md)は手順書ではないので、この骨格に従わない。冒頭に状態と調査日を `> [!WARNING]` で置き、表の各行に確認の深さ（起動 / 導入 / メタデータ）を書く
- 図は `docs/diagrams/*.diag`（構成図は nwdiag、パケットの流れは seqdiag）を原本にし、`python3 scripts/render-diagrams.py` で `*.svg` を生成する。SVG は直接編集しない（前提は [WireGuard の付録](docs/wireguard.md#付録-構成図の再生成)）
- パスワード、秘密鍵、トークンなどの秘密情報は残さない
