# 手順書とツールの比較

[目的別の手順書一覧](README.md)・[導入順](getting-started.md)・[リポジトリの入口](../README.md)

用途が近い手順書と、手順書の無いツールを比較する。版と導入コマンドは [CLI / GUI ツール導入元一覧](tool-catalog.md)で確認する。

## 比較する役割

- [共通の bash 設定を先に入れる](#共通の-bash-設定を先に入れる)
- [OS のインストール](#os-のインストール)
- [導入の基盤](#導入の基盤)
- [ほかの手順書が使う仕組み](#ほかの手順書が使う仕組み)
- [デスクトップ（GNOME）の設定](#デスクトップgnomeの設定)
- [リモート接続・VPN](#リモート接続vpn)
- [ファイル共有・同期](#ファイル共有同期)
- [端末とシェル](#端末とシェル)
- [ファイル・ディスク・リソースを見る](#ファイルディスクリソースを見る)
- [検索・テキスト処理](#検索テキスト処理)
- [エディタ](#エディタ)
- [git と GitHub](#git-と-github)
- [開発の補助](#開発の補助)
- [コンテナ](#コンテナ)
- [仮想化](#仮想化)
- [ブラウザ](#ブラウザ)
- [パスワード管理](#パスワード管理)

## 手順書とツール

- 役割ごとに分けてある。同じ役割の手順書は、表の列で違いを比べられる
- 対象は AlmaLinux 10.2（[Windows の OpenSSH サーバー](windows-openssh-server.md)・[Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)・[RDP をロックせずに切断（Windows）](windows-rdp-disconnect.md)・[Windows 11 の初期設定](windows-setup.md)・[Windows 11 のデュアルブート向けの導入](windows-dual-boot.md)・[SSH クライアント（Windows）](windows-ssh-client.md)は Windows 11 だけ、[Git](git.md) は Windows 11 の Git for Windows も、[Samba クライアント](samba-client.md)・[Syncthing](syncthing.md)・[HackGen Console NF](hackgen.md)・[WezTerm](wezterm-nightly.md)・[Claude Code](claude-code.md)・[Codex CLI](codex.md)・[Firefox](firefox.md)・[VirtualBox](virtualbox.md)・[WireGuard Road Warrior](wireguard-road-warrior.md)・[git-delta](git-delta.md)・[GitHub CLI](gh.md)・[Neovim](neovim.md)・[lazygit](lazygit.md)・[yazi](yazi.md) は Windows 11 も）。検証範囲（実機・VM・コンテナなど）は各手順書から案内する検証記録の「状態」に書いてある
- インストールした直後に、AlmaLinux 10 は [AlmaLinux 10 の初期設定](almalinux-setup.md)、Windows 11 は [Windows 11 の初期設定](windows-setup.md)を通す。下の手順書の多くは、その手順で入れたもの（Homebrew・EPEL・NOPASSWD の sudo など）を前提にする
- 導入元（AppStream / EPEL / Homebrew / Flathub / ベンダーのリポジトリ）で選ぶなら、先に [CLI / GUI ツール導入元一覧](tool-catalog.md) を見る
  - CLI・GUI の約 45 本について、推奨する導入元・版・aarch64 での提供の有無を比べた一覧で、手順書ではない
  - 各節の「手順書の無いツール」の表は、この一覧のツールを役割で振り分けたもの。版・導入コマンド・ほかの経路は、名前のリンク先の一覧の行にある
- Neovim・WezTerm・lazygit・yazi の自分用の設定（カスタマイズ）は、ツールごとの別のリポジトリにある。各手順書の「設定ファイル」の節から案内している（[Neovim](neovim.md#設定ファイル)・[WezTerm](wezterm-nightly.md#設定ファイル)・[lazygit](lazygit.md#設定ファイル)・[yazi](yazi.md#設定ファイル)）。Windows 11 の入れ方も、それぞれのリポジトリにある（clone のコマンドは手順書に載せない）
- シェルの設定は [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash) で管理する。各手順書では同じ設定を `~/.bashrc` に追記しない。先に README の共通の bash 設定を導入する（AlmaLinux 10 は、[AlmaLinux 10 の初期設定の手順 42・43](almalinux-setup.md#実施手順)に同じブロックがある）

### 共通の bash 設定を先に入れる

共通設定の導入は、[README の同名の節](../README.md#共通の-bash-設定を先に入れる)を参照する。

### OS のインストール

デュアルブートの要点と手順書の比較は、[導入順の OS のインストール](getting-started.md#os-のインストール)を参照する。

### 導入の基盤

- RPM に無いか古いツールの入れ先。CLI とフォントは Homebrew、GUI アプリは Flathub
- インターネットに出られないホストでも、そこへ ssh でログインできるホストを経由すれば Homebrew を使える（[homebrew-offline.md](homebrew-offline.md)。トンネルは[ssh の SOCKS トンネル](ssh-socks-tunnel.md)）。経由するのは入れる・上げるときだけで、入れたコマンドは ssh を閉じた後も動く
- 同じトンネルで、Neovim の Mason が npm で入れる LSP サーバー・リンターも入れられる（[npm-offline.md](npm-offline.md)。npm は `ALL_PROXY` を読まないので、`https_proxy` を足す）
- Firefox と VS Code は Flathub を使わず、ベンダーの RPM で入れている
- AppStream / BaseOS に無い RPM は EPEL から入れる。Firefox の AAC・H.264 に使う FFmpeg だけは RPM Fusion（free）から入れ、RPM Fusion は EPEL を前提にする
- ほかの導入元（AppStream / EPEL / COPR / AppImage など）との比較は、導入元一覧の[導入経路と EL10 での注意](tool-catalog.md#導入経路と-el10-での注意)にある
初期設定で整えるものと、後から通す手順書は、[導入順](getting-started.md#初期設定で整えるもの)を参照する。


| 手順書 | 入れるもの | 入る場所 | 権限 | 更新 | これを前提にするもの |
|---|---|---|---|---|---|
| [Homebrew（AlmaLinux 10 の初期設定の手順 46〜48）](almalinux-setup.md#実施手順) | CLI ツール、フォント（cask） | `/home/linuxbrew/.linuxbrew` | 導入・更新は一般ユーザーで行う（入れたコマンドは、任意の節で root のシェルや `sudo` からも使える） | `brew upgrade` | 同書の手順 49 の 6 つ（starship・zoxide・fzf・eza・bat・tmux）、導入元が Homebrew の手順書 11 本、手順書の無いツールの Homebrew の行 |
| [Homebrew（インターネットに出られないホスト）](homebrew-offline.md) | Homebrew と、Homebrew で入れるもの（出られるホストから [ssh の SOCKS トンネル](ssh-socks-tunnel.md)を張り、そのプロキシを通して入れる） | `/home/linuxbrew/.linuxbrew`（Homebrew と同じ） | 一般ユーザーで使う（出られるホストから ssh でログインする） | トンネルを張ってから `brew upgrade` | インターネットに出られないホストで通す、導入元が Homebrew の手順書とツール、[npm（インターネットに出られないホスト）](npm-offline.md) |
| [npm（インターネットに出られないホスト）](npm-offline.md) | Node.js と npm（AppStream の 22 系）と、Neovim の Mason が npm で入れる LSP サーバー・リンター（[ssh の SOCKS トンネル](ssh-socks-tunnel.md)を、`https_proxy` で npm に使わせる） | Node.js と npm は `/usr/bin`（システム全体）。Mason が入れるものは `~/.local/share/nvim/mason` | Node.js と npm は `sudo dnf` で入れる。Mason は一般ユーザーの Neovim から動く | トンネルを張り `https_proxy` を入れてから、`sudo dnf upgrade` と Mason の画面の `U` | インターネットに出られないホストで使う、Mason を使う Neovim の設定（LazyVimStarter など） |
| [Flatpak / Flathub（AlmaLinux 10 の初期設定の手順 22〜24）](almalinux-setup.md#実施手順) | GUI アプリ | `/var/lib/flatpak`（システム全体） | `sudo flatpak` で入れる | `sudo flatpak update`（`dnf upgrade` では上がらない） | 手順書の無いツールの Flathub の行 |
| [EPEL（AlmaLinux 10 の初期設定の手順 17）](almalinux-setup.md#実施手順) | AppStream / BaseOS に無い RPM（Fedora のプロジェクトが EL 向けに作る） | システム全体。repo ファイルは `/etc/yum.repos.d/epel.repo`（extras の `epel-release` が置く） | `sudo dnf` で入れる | `sudo dnf upgrade`（`epel-release` 自身も上がる） | 同書の RPM Fusion とトレイアイコンの拡張（手順 38）、btop・distrobox・podman-compose・podman-tui・VirtualBox（依存の `liblzf`）、手順書の無いツールの EPEL の行 |
| [RPM Fusion（free。AlmaLinux 10 の初期設定の手順 18〜21）](almalinux-setup.md#実施手順) | Fedora・EL の標準のリポジトリに無い RPM（FFmpeg など） | システム全体。repo ファイルは `/etc/yum.repos.d/rpmfusion-free-updates.repo` | `sudo dnf` で入れる | `sudo dnf upgrade` | [Firefox](firefox.md) の AAC・H.264（手順 8〜11） |
| [Windows 11 の初期設定](windows-setup.md) | Windows 11 の scoop（CLI ツール）と UniGet UI（winget の自分のユーザーへの導入）。PSWindowsUpdate は PowerShell Gallery から。同じ文書で PowerToys・PowerShell 7・WSL の AlmaLinux 10・Autologon・CopyQ（任意節）と、表示・電源・リモートなどの設定も（PowerToys のユーティリティ・PowerShell 7 のプロファイル・Windows Terminal のフォント・WSL のミラーは任意節）。Git Bash の starship・zoxide・fzf・eza・bat も任意節で scoop から | scoop は `~\scoop`、UniGet UI は `%LOCALAPPDATA%\Programs\UniGetUI`、PSWindowsUpdate はドキュメントの `WindowsPowerShell\Modules`（自分のユーザー） | Windows Update（手順 2〜8）と PC 全体の設定（手順 36〜55）は管理者。それ以外は通常の Windows PowerShell（scoop のインストーラは管理者では止まる）。任意節は節のリードのとおり（Wake on LAN・リモートからの再起動・Edge の常駐は管理者） | Windows は PSWindowsUpdate、Store は `store updates --apply`。scoop は `scoop update`（git は Git for Windows。任意節の zoxide は 0.9.9 に止めてあり、上がらない）、ほかは `winget upgrade`。UniGet UI は自分でも上がる | [Windows の OpenSSH サーバー](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の、scoop のツールを SSH のセッションで使う任意節。[git-delta](git-delta.md#windows-11-で使う)・[GitHub CLI](gh.md#windows-11-で使う)・[Neovim](neovim.md#windows-11-で使う)・[lazygit](lazygit.md#windows-11-で使う)・[yazi](yazi.md#windows-11-で使う)の Windows 11 の節（scoop で入れる） |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [Flatseal](tool-catalog.md#gnomeシステム) | Flatpak アプリの権限を変える（GUI） | Flathub（[AlmaLinux 10 の初期設定の手順 25](almalinux-setup.md#実施手順) の確認用に入る） |

### ほかの手順書が使う仕組み

- 複数の手順書が同じ設定を前提にするので、独立させてある。使う側の手順書は、冒頭の `> [!IMPORTANT]`（任意節の前提なら、その節の冒頭）から案内している
- Windows 11 の貼り付けの設定と LAN をプライベートにする手順は、インストール直後に通す [Windows 11 の初期設定](windows-setup.md)の手順（16〜19・43）で、使う側の手順書はその手順を名指しする
- AlmaLinux 10 の EPEL・RPM Fusion・Flathub・Homebrew は、インストール直後に通す [AlmaLinux 10 の初期設定](almalinux-setup.md)の手順（17・18〜21・22〜24・46〜48）で、画面オフ・画面ロック・自動サスペンドを止めるのは同書の任意節。使う側の手順書はその手順と節を名指しする
- 設定はユーザーやホストに 1 つなので、どれか 1 本の手順書のために通してあれば、ほかの手順書では確かめるだけでよい。元に戻すのは、使う手順書がどれも無くなったとき

| 手順書 | すること | 変わるもの | これを前提にするもの |
|---|---|---|---|
| [linger](linger.md) | ログアウトしている間も、自分のユーザーの systemd（ユーザーのサービス・タイマー・Quadlet のコンテナ）を動かす | `/var/lib/systemd/linger/<USER>`（`sudo loginctl enable-linger`） | Syncthing・Dropbox・Dropbox（rclone）・Podman の Quadlet（任意節） |
| [ssh の SOCKS トンネル](ssh-socks-tunnel.md) | インターネットに出られないホストから、そこへ ssh でログインしてくるホストを経由して外に出る（`ssh -R 1080`） | 無し（ssh の間だけ。任意で `/etc/dnf/dnf.conf` の `proxy=`） | Homebrew（インターネットに出られないホスト）・npm（インターネットに出られないホスト） |
| [Secure Boot の MOK 登録](secure-boot-mok.md) | Secure Boot のまま、自分でビルドしたカーネルモジュールを読み込めるようにする（署名鍵を作り、起動の途中の MokManager で登録する） | `/var/lib/shim-signed/mok/MOK.{der,priv}` と UEFI の MOK | VirtualBox・VirtualBox Guest Additions（bootc のゲスト）。どちらも Secure Boot が有効なときだけ |
| [Windows PowerShell の貼り付けの設定（Windows 11 の初期設定の手順 16〜19）](windows-setup.md#実施手順) | GitHub のコピーボタンでコピーした複数行のブロックを、Windows PowerShell 5.1 の conhost の窓に右クリックで貼っても、行が逆順にならないようにする（PSReadLine の Ctrl+Enter を `AddLine` にする） | このユーザーの `$PROFILE`（`Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`）に 1 行。実行ポリシーが `Restricted` なら、このユーザーだけ `RemoteSigned` に | Windows の PowerShell のブロックを貼る手順書すべて（Windows の OpenSSH サーバー・Claude Code の Remote Control（Windows）・RDP をロックせずに切断（Windows）・SSH クライアント（Windows）と、Git・Samba クライアント・Syncthing・HackGen Console NF・WezTerm・Claude Code・Codex CLI・Firefox・VirtualBox・WireGuard Road Warrior・git-delta・GitHub CLI・Neovim・lazygit・yazi の Windows 11 の節） |
| [LAN をプライベートにする（Windows 11 の初期設定の手順 43）](windows-setup.md#実施手順) | Windows 11 の LAN の接続を、ネットワークの種類「プライベート」にする（プライベートだけで有効な受信の規則が、この LAN で効く） | LAN の接続のネットワークの種類（`Set-NetConnectionProfile`） | Windows の OpenSSH サーバー（手順 5 で確かめる）・Syncthing（Windows 11 の節の手順 7 で確かめる） |

### デスクトップ（GNOME）の設定

- どれも GNOME のデスクトップが前提で、[AlmaLinux 10 の初期設定](almalinux-setup.md)の手順と任意節にある。自分のセッションは、設定アプリと同じキーを `gsettings` で変える
- 常時動かしておく PC（WireGuard・Samba・Syncthing・Dropbox のホスト、GNOME Remote Desktop で待ち受ける PC）は、ログイン画面と OS のサスペンドも止める
- Windows 11 の表示と入力の設定は、[Windows 11 の初期設定](windows-setup.md)にある（Caps Lock を Ctrl に〔PC 全体の Scancode Map〕・旧形式のコンテキストメニュー・エクスプローラー・スタート・タスクバー・ダークモード・IME の Ctrl+Space・US 配列。電源とロックも同じ文書）
  - 固定キーなどのショートカット・入力言語の切り替えキー（Alt+Shift・Ctrl+Shift）・Alt+Tab・ギャラリーとホーム・タスクの終了・アニメーション・効果音・ストレージ センサーは、同じ文書の任意節「[表示・入力・音・ストレージを変える](windows-setup.md#表示入力音ストレージを変える任意)」。広告 ID などは「[プライバシーと広告の表示を切る](windows-setup.md#プライバシーと広告の表示を切る任意)」

| 手順書 | 変えるもの | 変える範囲 | 仕組み | 導入するもの |
|---|---|---|---|---|
| [画面オフ・画面ロック・自動サスペンド（AlmaLinux 10 の初期設定の任意節）](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意) | 画面を消す・暗くする・ロックする、放置でのサスペンド、電源ボタン、蓋 | 自分のセッション、ログイン画面、OS 全体 | `gsettings`、dconf の `/etc/dconf/db/gdm.d`、`systemctl mask`、logind のドロップイン | 無し |
| [日本語入力（IBus + Anthy。AlmaLinux 10 の初期設定の手順 27・28）](almalinux-setup.md#実施手順) | 入力ソース（キーボードの配列と Anthy を Super+Space で切り替える） | 自分のセッション | `gsettings` の `org.gnome.desktop.input-sources` と IBus | `ibus-anthy` と日本語のフォント（Workstation には最初から入っている） |
| [表示と入力（AlmaLinux 10 の初期設定の手順 29〜41）](almalinux-setup.md#実施手順) | ホームのフォルダーの名前（英語に）、ダークモード、Caps Lock を Ctrl に、ウィンドウのボタン、時計と電池、Files、Alt+Tab、ホットコーナー、拡大率、トレイアイコン、Ctrl+Alt+T、Dash のお気に入り | 自分のセッション | `gsettings`（拡大率は mutter の実験的な機能）、`xdg-user-dirs-update`、GNOME Shell の拡張 | トレイアイコンの拡張（EPEL の `gnome-shell-extension-appindicator`） |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [GNOME Tweaks](tool-catalog.md#gnomeシステム) | GNOME の細かい設定（GUI） | EPEL |
| [Extension Manager](tool-catalog.md#gnomeシステム) | GNOME 拡張の検索と導入（GUI） | Flathub |

### リモート接続・VPN

- WireGuard VPN は拠点に建てる側、Road Warrior は外出先の AlmaLinux PC からそこへつなぐ側。PC で作った鍵をホストの `client add --pubkey` で登録し、`client show` の conf を PC に取り込む
- GNOME Remote Desktop は VPN ではなく、RDP で PC にログインして画面を使う
- ヘッドレスのセッションは、モニターの無い PC に常駐させた自分の GNOME のデスクトップに、RDP でつなぐ。リモートログインも既存のセッションへ戻れるため、同じ PC で併用できる。前提は画面オフ・画面ロック・自動サスペンドの手順 1・2（サスペンドできる PC では手順 3・4 も）
- デスクトップ共有は、遠隔の PC の画面のデスクトップを、PC の画面を触らずに RDP で共有する（設定アプリの「デスクトップ共有」と同じ仕組みを、SSH から CLI だけで設定する。PC の画面のセッションは GDM の自動ログインで作り、RDP の資格情報はパスワードの無い専用のキーリングに置く。ロックやログアウトでつながらなくなったときも SSH から直す）。画面が暗くなるか眠ると使えないので、前提は画面オフ・画面ロック・自動サスペンドの手順 1〜4。今の版は、x86_64 の VirtualBox の Workstation の VM で、PC の画面を一度も操作せずに通した（[記録](verification/gnome-desktop-sharing.md#付録-pc-の画面を触らない版を-x86_64-の-vm-で通した記録2026-10-07)）。PC の前でパスワードでログインしていた以前の版は、aarch64 の実機・Server with GUI の新規 VM と、x86_64 の VirtualBox / Workstation の VM で検証した（[実機の記録](verification/gnome-desktop-sharing.md#付録-このホストでの検証2026-10-07)・[クリーン VM の記録](verification/gnome-desktop-sharing.md#付録-公式-iso-から新規インストールした-aarch64-vm-での検証2026-10-07)・[x86_64 VM の記録](verification/gnome-desktop-sharing.md#付録-virtualbox-の-vm-での本実行2026-10-07)・[統合後の x86_64 VM の記録](verification/gnome-desktop-sharing.md#付録-統合後の手順を-x86_64-の-vm-で通した記録2026-10-07)）
- Windows の OpenSSH サーバーは、Windows 11 の PC に AlmaLinux などの `ssh` で入る側。Windows のユーザーのパスワードで入る（公開鍵での認証と、パスワード認証を切るのは任意節）。LAN の接続をプライベートにするのは、[Windows 11 の初期設定の手順 43](windows-setup.md#実施手順)
  - 同じ PC の WSL をミラー（[Windows 11 の初期設定の任意節](windows-setup.md#wsl-のネットワークをミラーにする任意)）にしたら、WSL からは `127.0.0.1` でつなぐ
- SSH クライアント（Windows）は、その逆向き。Windows 11 の PC から AlmaLinux 10 のホストに、ed25519 の鍵で入る。鍵と `%USERPROFILE%\.ssh\config` の接続先は、Windows の ssh（PowerShell・WezTerm の起動メニュー）と Git の ssh（Git Bash・git）で共有する。ssh-agent は使わない（パスフレーズは毎回聞かれる）。**Windows の実機では流していない**（未検証）
- Claude Code の Remote Control（Windows）は VPN でも SSH でもなく、Anthropic の API 経由でスマートフォンやブラウザから Windows 11 の PC の Claude Code を操作する。SSH で入ってタスク スケジューラのタスクを登録・開始し、タスクが WezTerm で起動した Claude Code は SSH を切った後も動く（Windows の OpenSSH サーバーが前提）
- AlmaLinux 10 のホストでは、SSH で入って tmux の中で `claude remote-control` を動かす（[AlmaLinux 10 の初期設定の tmux の任意節](almalinux-setup.md#claude-code-を-tmux-の中で動かす任意)。接続は未検証）
- Windows 11 の PC でリモート デスクトップを受け付けるのは、[Windows 11 の初期設定](windows-setup.md)の手順 44（Pro 以上。受信の規則をプライベートの LAN に絞る）
- Windows 11 の PC に RDP でつないで使った後、ふつうに切断すると PC の画面がロックされる。RDP をロックせずに切断する手順書は、切るときに `tscon` でセッションを PC の画面（コンソール）へ戻し、デスクトップにサインインしたままにする（Claude Code の Remote Control（Windows）は、`console` が `Active` であることを前提にする）。**Windows の実機では流していない**（未検証）
- リモートの操作ができなくなったときに備えて再起動の経路を増やすのは、[Windows 11 の初期設定](windows-setup.md#リモートから再起動する手段を増やす任意)の任意節（既にある SSH・RDP・Remote Control からの再起動に加え、別の PC からの SMB〔`net rpc shutdown`・`shutdown /m`〕・WinRM、クラッシュ時の自動再起動、ネットワーク断で自分で再起動する見張りタスク）。SMB・WinRM は管理の口を LAN に開け UAC のリモート制限を緩めるので任意。**Windows の実機では未検証**

| 手順書 | つなぐもの | 実行する場所 | 仕組み | 開けるポート |
|---|---|---|---|---|
| [WireGuard VPN](wireguard.md) | 2 拠点の LAN 同士と、外出先のクライアント | 各拠点の WG ホスト（ルーターの配下） | `wg-vpn.sh`（値は `site.env` 1 ファイル）と `wg-quick@wg0` | `${WG_PORT}/udp`（例 51820） |
| [WireGuard Road Warrior](wireguard-road-warrior.md) | 外出先の PC と両拠点の LAN | 外出先の PC（一部の手順は WG ホスト） | NetworkManager（`nmcli connection import`）。張る・切るは `nmcli connection up` / `down`。Windows 11 は winget の `WireGuard.WireGuard`（公式の MSI）で、`/installtunnelservice` / `/uninstalltunnelservice` | 無し（PC の firewalld は変えない） |
| [GNOME Remote Desktop](gnome-remote-desktop.md) | RDP クライアントと PC のログイン画面 | 接続される PC | `grdctl --system`（GDM で認証し、既存セッションへ戻るか、無ければ作る） | 3389/tcp |
| [GNOME のヘッドレスのセッション](gnome-headless-session.md) | RDP クライアントと、モニターの無い PC に常駐させた GNOME のデスクトップ | 接続される PC（セッションを使うユーザーのシェル） | GDM の `gnome-headless-session@<USER>.service` と `grdctl --headless`（ユーザーのデーモン） | 3389/tcp（リモートログインと併用なら 3390/tcp） |
| [GNOME のデスクトップ共有](gnome-desktop-sharing.md) | RDP クライアントと、遠隔の PC の画面に自動ログインした GNOME のデスクトップ | 接続される PC（共有するユーザーの SSH のシェル。PC の画面は使わない） | `grdctl`（オプション無し）とユーザーの `gnome-remote-desktop.service`、GDM の自動ログイン。資格情報はパスワードの無いキーリング `rdp` | 3389/tcp（リモートログインと併用なら 3390/tcp） |
| [Windows の OpenSSH サーバー](windows-openssh-server.md) | SSH クライアントと Windows 11 の PC | 接続される PC（Windows。接続はクライアント） | Windows のオプション機能 `OpenSSH.Server`（サービス `sshd`）とパスワード認証（公開鍵は任意） | 22/tcp（プライベートのネットワークだけ） |
| [SSH クライアント（Windows）](windows-ssh-client.md) | Windows 11 の PC と AlmaLinux 10 のホスト（SSH の鍵と接続先） | 接続する PC（Windows。指紋を見るところだけホスト。公開鍵はホストの `authorized_keys` に Windows から足す） | Windows の OpenSSH クライアント（`System32\OpenSSH`）と Git for Windows の ssh。`%USERPROFILE%\.ssh` の ed25519 の鍵と config | 無し |
| [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md) | スマートフォン・ブラウザの Claude アプリと、Windows 11 の PC で動く Claude Code | 接続される PC（Windows。SSH でログインした PowerShell に貼る。確認はスマートフォンかブラウザ） | タスク スケジューラのタスクで WezTerm を起動し、その中で `claude remote-control` を動かす（SSH の子プロセスにしない） | 無し（外向きの HTTPS だけ） |
| [RDP をロックせずに切断（Windows）](windows-rdp-disconnect.md) | RDP のクライアントと Windows 11 の PC のデスクトップ（切るときに、セッションを PC の画面へ戻す） | 接続される PC（Windows。RDP でつないだセッションの中の管理者の PowerShell に貼る。確認は SSH か PC の前） | `tscon.exe <セッションの ID> /dest:console`（任意で、管理者として実行するデスクトップのショートカット） | 無し（RDP の 3389/tcp は、[Windows 11 の初期設定の手順 44](windows-setup.md#実施手順)か、Windows の設定のリモート デスクトップが開ける） |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [Remmina](tool-catalog.md#gnomeシステム) | リモートデスクトップのクライアント（GUI） | EPEL |
| [mosh](tool-catalog.md#cli-定番の置き換え) | 回線が切れても続く SSH | EPEL |

### ファイル共有・同期

- Samba は、サーバーにある自分のホームを LAN・WireGuard 越しに SMB3 で読み書きする（任意で root のホームも、自分のユーザーのまま）。Syncthing は、指定したフォルダを端末同士で同期する
- Samba クライアントは、その共有を AlmaLinux 10 の PC の `/mnt/<共有名>` に、アクセスしたときにマウントする。GNOME Files（`smb://`）で開く方法も同書にある
  - Windows 11 の PC では、同書の [Windows 11 の節](samba-client.md#windows-11-で使う)で、共有をドライブ文字に割り当て、サインインのたびにつなぎ直す（資格情報マネージャーと `New-SmbMapping`。管理者ではない窓で行う）。**Windows の実機では流していない**（未検証）
- 同じホストで両方使うときは、Syncthing の同期対象にホームを丸ごと入れない（Samba と同じ領域を二重に扱うことになる）
- Syncthing の鍵と設定は、[syncthing.md の任意節](syncthing.md#設定を自動でバックアップする任意)で自動でバックアップし、送信専用フォルダで別の端末へ複製できる。戻し方も同書にある（この 2 節はコンテナのみで検証）
- Syncthing は、Windows 11 の PC にも同書の [Windows 11 の節](syncthing.md#windows-11-で使う)で入れられる。公式の zip の `syncthing.exe` を置き、サインインしている間だけタスク スケジューラで動かす（AlmaLinux 10 の Syncthing の相手にもなる）。更新は Syncthing 自身の自動の更新。**Windows の実機では流していない**（未検証）
- Dropbox は、どちらの手順書も `~/Dropbox` をクラウドと同期する。公式クライアントは x86_64 にしか無いので、Raspberry Pi 5（aarch64）では rclone を使う
- `~/Dropbox` を Syncthing の同期フォルダに入れない（2 つの同期が同じファイルを書き合う）

| 手順書 | 方式 | 導入元 | 常駐 | 開けるポート |
|---|---|---|---|---|
| [Samba](samba.md) | ホームディレクトリを SMB3 で公開（`[homes]`。任意で root のホームを `[root]`、`/home` 全体を `[home]` 共有で） | BaseOS / AppStream | `smb.service`（システムのサービス） | 445/tcp だけ（NetBIOS は使わない） |
| [Samba クライアント](samba-client.md) | Samba の共有を PC から SMB3 でマウント（`/etc/fstab` の `x-systemd.automount`）。GNOME Files でも開ける。Windows 11 はネットワーク ドライブに割り当てる | BaseOS（`cifs-utils`）。GNOME Files は AppStream（`gvfs-smb`）。Windows 11 は Windows に入っている SMB のクライアント | 無し（アクセスしたときに systemd がマウントし、1 分使わなければ外す）。Windows 11 はサインインのたびにつなぎ直す | 無し（サーバーの 445/tcp へ出るだけ） |
| [Syncthing](syncthing.md) | フォルダを端末同士で同期。操作は Web GUI | Homebrew（EPEL 版は最新でなく、公式の RPM リポジトリは無い）。Windows 11 は GitHub の公式の zip（sha256 と Authenticode の署名を確かめて `%LOCALAPPDATA%\Programs\Syncthing` に置く。更新は Syncthing 自身の自動の更新） | `brew services` のユーザーサービスと [linger](linger.md)。Windows 11 はタスク スケジューラのサインインのタスク（サインインしている間だけ） | firewalld の `syncthing`（22000/tcp・udp、21027/udp）と `syncthing-gui`（8384/tcp）。Windows 11 は Windows ファイアウォールのプライベートだけに、`syncthing.exe` の同じポート |
| [Dropbox（公式クライアント）](dropbox.md) | `~/Dropbox` を Dropbox と常時同期する（x86_64 だけ）。操作は `dropbox` コマンド | Dropbox 公式の tarball（署名を確かめて `~/.dropbox-dist` に展開。公式 RPM は EL10 に入らない） | 自分で書く systemd ユーザーサービスと [linger](linger.md) | 無し（LAN 同期の `dropbox-lansync` は開けない） |
| [Dropbox（rclone）](dropbox-rclone.md) | `rclone bisync` で `~/Dropbox` と Dropbox を 15 分ごとに双方向同期する（Raspberry Pi 5 向け） | Homebrew（EPEL 版は古い） | systemd ユーザータイマーと [linger](linger.md) | 無し |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [restic](tool-catalog.md#cli-開発運用) | バックアップ | EPEL |
| [LocalSend](tool-catalog.md#gnomeシステム) | LAN 内の端末とファイルを送り合う（GUI） | Flathub |

### 端末とシェル

- 変えるものがそれぞれ違うので、併用できる
- starship・zoxide・fzf・eza・bat・tmux と bash の設定は、[AlmaLinux 10 の初期設定](almalinux-setup.md)の手順 42〜66 でまとめて入れて確かめる（使い方と設定は同書の後ろの節）
- 初期化の順番は bash の共通設定が管理する。Homebrew → starship → WezTerm → zoxide、Homebrew の補完 → fzf の順で読む。手順書ごとの追記や並べ替えは不要
- eza のアイコンや starship の Nerd Font 前提のプリセットは、端末のフォントに Nerd Fonts のグリフ（HackGen Console NF など）が要る
- HackGen Console NF は、Windows 11 の PC にも同書の [Windows 11 の節](hackgen.md#windows-11-で使う)で入れられる。上流の zip を、版と sha256 を確かめて自分のユーザーに入れる
  - Windows Terminal のフォントにするのは、[Windows 11 の初期設定の任意節](windows-setup.md#windows-terminal-のフォントと貼り付けの警告を変える任意)
- Windows 11 では、共通の bash 設定を Git Bash で使う（WezTerm の自分用の設定の既定のシェル）
  - Git Bash の starship・zoxide・fzf・eza・bat は、[Windows 11 の初期設定の任意節](windows-setup.md#シェルのツールを入れる任意)で scoop から入れる。共通の bash 設定が入っているものを読むので、`~/.bashrc` には足さない。確かめるのは、Git Bash で AlmaLinux 10 の初期設定の手順 52〜55・57・58・60〜63
  - PowerShell 7 は、[Windows 11 の初期設定の任意節](windows-setup.md#powershell-7-のプロファイルを設定する任意)で starship と zoxide だけを読む。手順書を貼る Windows PowerShell 5.1 には、貼り付けの設定（同書の手順 16〜19）のほかは足さない

| 手順書 | 変えるもの | 導入元 | 設定の置き場所 |
|---|---|---|---|
| [WezTerm Nightly](wezterm-nightly.md) | 端末アプリ（GUI） | 公式 COPR の EL9 ビルド（chroot を明示）。Windows 11 は GitHub の nightly の `WezTerm-nightly-setup.exe`（`C:\Program Files\WezTerm`） | `~/.wezterm.lua` か `~/.config/wezterm/wezterm.lua`（両方あると前者だけ読む。Windows は `%USERPROFILE%` の下） |
| [HackGen Console NF](hackgen.md) | 端末のフォント（日本語と Nerd Fonts のアイコン） | Homebrew の cask。Windows 11 は上流の zip（版と sha256 を固定） | `~/.local/share/fonts` に入る（自分のユーザーだけ）。Windows 11 は `%LOCALAPPDATA%\Microsoft\Windows\Fonts` と `HKCU` の登録 |
| [starship（AlmaLinux 10 の初期設定の手順 49）](almalinux-setup.md#実施手順) | シェルのプロンプト（`PS1`） | Homebrew（RPM 無し）。Windows 11 は scoop（[Windows 11 の初期設定の任意節](windows-setup.md#シェルのツールを入れる任意)） | bash の共通設定。`~/.config/starship.toml` は任意 |
| [zoxide（AlmaLinux 10 の初期設定の手順 49）](almalinux-setup.md#実施手順) | ディレクトリの移動（`z`・`zi`） | Homebrew（EPEL・AppStream に無い）。Windows 11 は scoop で、0.9.9 に止める（0.10.0 は Git Bash で記録しない。[Windows 11 の初期設定の任意節](windows-setup.md#シェルのツールを入れる任意)） | bash の共通設定 |
| [tmux（AlmaLinux 10 の初期設定の手順 49）](almalinux-setup.md#実施手順) | 端末の多重化（SSH を切ってもシェルとコマンドが残る。Claude Code を動かし続けるのにも使う） | Homebrew（BaseOS は 3.3a） | `~/.config/tmux/tmux.conf`（任意） |
| [bash の履歴・補完・キー操作（AlmaLinux 10 の初期設定の手順 44・45）](almalinux-setup.md#実施手順) | bash 自身（履歴の量、`autocd`・`globstar` などの `shopt`、bash-completion と Homebrew のコマンドの補完、readline の補完の大文字小文字と色、↑/↓ の履歴の検索） | BaseOS の `bash-completion`（bash は入っている） | bash の共通設定と `~/.inputrc` |
| [fzf（AlmaLinux 10 の初期設定の手順 49）](almalinux-setup.md#実施手順) | 履歴・パス・ディレクトリを曖昧検索で選ぶ（Ctrl+R / Ctrl+T / Alt+C、`**<Tab>`） | Homebrew（EPEL は 0.58 系。yazi・zoxide の依存で入っていることが多い）。Windows 11 は scoop（[Windows 11 の初期設定の任意節](windows-setup.md#シェルのツールを入れる任意)） | bash の共通設定（fd・bat があれば候補・プレビューも有効） |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [zellij](tool-catalog.md#cli-定番の置き換え) | 端末の多重化（キー操作が画面に出る） | Homebrew |
| [atuin](tool-catalog.md#cli-定番の置き換え) | シェル履歴の検索 | Homebrew |
| [tealdeer](tool-catalog.md#cli-定番の置き換え) | コマンドの使用例を引く（`tldr`） | Homebrew |

### ファイル・ディスク・リソースを見る

- 標準のコマンドは置き換えず、別の名前で使う（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)は `alias cat=bat` / `alias ls=eza` を勧めない）
- この節の手順書では btop だけ EPEL の RPM で入れている（Homebrew と同じ版のため。duf・fastfetch も同じ理由で EPEL）。RPM なので `sudo btop` がそのまま動く
- Homebrew のもの（`gdu-go` など）は、そのままでは `sudo` の PATH に無い。`sudo gdu-go` のように使うなら [AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通す（通さないならフルパスで呼ぶ）

| 手順書 | 見るもの | 近い標準のコマンド | 打つコマンド | 形 | 導入元 |
|---|---|---|---|---|---|
| [bat（AlmaLinux 10 の初期設定の手順 49）](almalinux-setup.md#実施手順) | ファイルの中身（シンタックスハイライト、git 連携） | `cat` | `bat` | CLI | Homebrew（EPEL は 0.24 系）。Windows 11 は scoop（[Windows 11 の初期設定の任意節](windows-setup.md#シェルのツールを入れる任意)） |
| [eza（AlmaLinux 10 の初期設定の手順 49）](almalinux-setup.md#実施手順) | ディレクトリの一覧（git の状態、ツリー表示） | `ls` | `eza`、共通の bash 設定のエイリアスの `ll` / `la` / `lt` | CLI | Homebrew（RPM 無し）。Windows 11 は scoop（[Windows 11 の初期設定の任意節](windows-setup.md#シェルのツールを入れる任意)） |
| [yazi](yazi.md) | ファイルの閲覧と操作（プレビュー、検索） | — | `y`（終了した場所へ移るシェル関数）、`yazi` | TUI | Homebrew（EPEL・AppStream に無い）。Windows 11 は scoop の main |
| [gdu](gdu.md) | ディスク使用量 | `du` | `gdu-go`（`gdu` ではない） | TUI | Homebrew（EPEL は 5.32 系で、コマンド名は `gdu`） |
| [btop](btop.md) | CPU・メモリ・ディスク・ネットワーク・プロセス | `top` | `btop` | TUI | EPEL（Homebrew と同じ 1.4.7） |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [ncdu](tool-catalog.md#cli-定番の置き換え) | ディスク使用量の TUI（gdu と同類） | Homebrew |
| [dust](tool-catalog.md#cli-定番の置き換え) | `du` の見やすい版 | Homebrew |
| [duf](tool-catalog.md#cli-定番の置き換え) | `df` の見やすい版 | EPEL |
| [htop](tool-catalog.md#cli-定番の置き換え) | プロセスビューア | Homebrew |
| [fastfetch](tool-catalog.md#cli-定番の置き換え) | システム情報の表示（neofetch の後継） | EPEL |
| [glow](tool-catalog.md#cli-定番の置き換え) | Markdown を端末で読む | Homebrew |
| [Mission Center](tool-catalog.md#gnomeシステム) | リソースモニタ（GUI） | Flathub |

### 検索・テキスト処理

- 手順書は無い。どれも Homebrew で入れる CLI
- `fd` は EPEL の `fd-find` と実行ファイルの名前が同じなので、両方は入れない（PATH の先頭にある Homebrew 版が勝つ）

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [ripgrep](tool-catalog.md#cli-定番の置き換え) | 高速な grep（`rg`） | Homebrew |
| [fd](tool-catalog.md#cli-定番の置き換え) | 使いやすい find | Homebrew |
| [jq](tool-catalog.md#cli-定番の置き換え) | JSON の加工 | Homebrew |
| [yq](tool-catalog.md#cli-定番の置き換え) | YAML / JSON / XML の加工（mikefarah 版） | Homebrew |

### エディタ

- 端末の中で使うなら Neovim、GUI なら VS Code
- lazygit の `e` キーで開くエディタは、lazygit.md の既定では `nvim`（`code` にもできる）
  - Windows 11 の PowerShell から起動するときは、[neovim.md の既定のエディタにする（任意）](neovim.md#既定のエディタにする任意)の手順 2 で、ユーザーの環境変数 `EDITOR` を `nvim` にする（Git Bash では、共通の bash 設定が `nvim` にする）
- Homebrew の nvim は、そのままでは `sudo` の PATH に無く、`EDITOR=nvim` でも `sudoedit` は黙って `vi` で開く。[AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通すと、`sudoedit` が自分の設定の nvim で開く（通さないなら `SUDO_EDITOR` にフルパスを渡す）
- インターネットに出られないホストでは、Neovim は [homebrew-offline.md](homebrew-offline.md) のトンネルで入れ、Mason の npm のパッケージは [npm-offline.md](npm-offline.md) で入れる

| 手順書 | 形 | 導入元 | 設定の置き場所 | 更新 |
|---|---|---|---|---|
| [Neovim](neovim.md) | 端末の中（TUI）。`vi` は RPM の `vim-minimal` のまま | Homebrew（EPEL は 0.10 系）。Windows 11 は scoop の main | `~/.config/nvim`（`init.lua` か `init.vim`）。Windows 11 は `%LOCALAPPDATA%\nvim` | `brew upgrade neovim`（Windows 11 は `scoop update neovim`） |
| [VS Code](vscode.md) | GUI（Electron） | Microsoft 公式 dnf リポジトリ（EL 共通の rpm） | `~/.config/Code`、`~/.vscode`（`~/.config/code-flags.conf` は読まれない） | `sudo dnf upgrade code`（内蔵のアップデータは使わない） |

### git と GitHub

- 役割が違うので、併用できる
- [Git](git.md) は git 本体と `~/.gitconfig` の基本の設定（pull は rebase と autostash、改行を変換しない、推奨の設定）。AlmaLinux 10 と Windows 11 の Git for Windows で同じ設定にする
- `merge.conflictStyle zdiff3` は、Git と git-delta の両方の手順書で入れる（同じ値なので、どちらを先に通してもよい）
- lazygit は git の `core.pager` を読まない。lazygit でも delta で差分を出すなら、[git-delta.md の任意節](git-delta.md#lazygit-と組み合わせる任意)で `git.diffRenderers` を足す

| 手順書 | 役割 | 打つコマンド | 導入元 | 設定の置き場所 |
|---|---|---|---|---|
| [Git](git.md) | git 本体と基本の設定（pull は rebase・autostash、`core.autocrlf=false`、推奨の設定） | `git` | AppStream（Windows 11 は winget の Git for Windows） | `~/.gitconfig`（`git config --global` で書く） |
| [lazygit](lazygit.md) | git の TUI クライアント | `lazygit` | Homebrew（EPEL・AppStream に無い）。Windows 11 は scoop の extras | `~/.config/lazygit/config.yml`。Windows 11 は `%LOCALAPPDATA%\lazygit\config.yml` |
| [git-delta](git-delta.md) | `git diff` / `show` / `log -p` の表示（ページャ） | `delta`（formula 名は `git-delta`。ふだんは git が呼ぶ） | Homebrew（RPM 無し）。Windows 11 は scoop の main（`delta`） | `~/.gitconfig`（`git config --global` で書く。Windows 11 は `C:\Users\<WIN_USER>\.gitconfig` で、Git Bash・PowerShell・cmd の git が同じものを読む） |
| [GitHub CLI](gh.md) | GitHub の操作（`gh auth login` で認証） | `gh` | GitHub 公式 dnf リポジトリ（EPEL 版は古い）。Windows 11 は scoop の main（`gh`） | `~/.config/gh/hosts.yml`（トークンは OS の資格情報ストアを優先し、使えない場合はファイルに平文保存）。Windows 11 は `%APPDATA%\GitHub CLI`（トークンは資格情報マネージャーを優先） |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [difftastic](tool-catalog.md#cli-定番の置き換え) | 構文を理解する diff（`difft`。delta と併用できる） | Homebrew |
| [Meld](tool-catalog.md#開発) | 差分・マージ（GUI） | EPEL |

### 開発の補助

- 言語処理系は AppStream / BaseOS にある（Node.js・Python・Go・Rust）。別の版が要るときに mise を使う

| 手順書 | 用途 | 導入元 | 更新 |
|---|---|---|---|
| [ShellCheck / shfmt](shellcheck.md) | シェルスクリプトの静的検査と整形（`wg-vpn.sh` の検査にも使う） | Homebrew（shfmt に RPM が無いので、2 つとも揃えた） | `brew upgrade` |
| [Claude Code](claude-code.md) | Claude Code の CLI（Node.js 不要）と、`claude` のコマンドラインの使い方（起動と再開・`-p`・MCP） | Anthropic 公式 dnf リポジトリの `latest` チャンネル（`stable` も選べる）。Windows 11 は公式の native installer（`%USERPROFILE%\.local\bin\claude.exe`。PATH は手順書で足す） | `sudo dnf upgrade claude-code`（自動更新しない）。Windows 11 は自動の更新（`claude update` で今すぐ） |
| [Codex CLI](codex.md) | OpenAI のコーディング用 CLI（Node.js 不要）。AlmaLinux 10 と Windows 11 の導入・認証・起動 | OpenAI 公式の standalone インストーラー（Linux は `~/.local/bin/codex`、Windows は `%LOCALAPPDATA%\Programs\OpenAI\Codex\bin\codex.exe`） | 公式インストーラーを再実行 |
| [Claude Code で GUI を確かめる](claude-code-gui.md) | Claude Code が、ヘッドレスのセッションの画面を撮り、キーボードとポインタで操作して GUI の動作を確かめる（前提は GNOME のヘッドレスのセッション） | このリポジトリの [`scripts/gnome-gui.py`](../scripts/gnome-gui.py)（Mutter の ScreenCast / RemoteDesktop）と、gnome-shell の `--virtual-monitor` | このリポジトリの `git pull` |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [direnv](tool-catalog.md#cli-開発運用) | ディレクトリごとの環境変数 | Homebrew |
| [mise](tool-catalog.md#cli-開発運用) | 言語処理系の版の切り替え | [公式 dnf リポジトリ](tool-catalog.md#ベンダーの-dnf-リポジトリ) |
| [uv](tool-catalog.md#cli-開発運用) | Python のパッケージと仮想環境 | Homebrew |
| [chezmoi](tool-catalog.md#cli-開発運用) | dotfiles の管理 | Homebrew |
| [just](tool-catalog.md#cli-開発運用) | コマンドランナー（make の代わり） | Homebrew |
| [hyperfine](tool-catalog.md#cli-開発運用) | コマンドのベンチマーク | Homebrew |

### コンテナ

- 土台は [Podman](podman.md)（AppStream）で、コンテナを自分のユーザー（rootless）で動かす。ほかの 5 本と手順書の無いツールは、これを前提にしている
- podman 本体と、システムの podman と組んで使うもの（podman-compose・podman-tui・distrobox・toolbox・buildah・skopeo）は RPM にしている
  - Homebrew 版の podman-compose は別の podman を連れてきて、システムの podman を隠した
  - Homebrew の podman・skopeo は、`/etc/containers` の設定を読まない
  - Homebrew の podman-tui は 2.x で、podman 6 向け（AlmaLinux 10 の podman は 5）
- podman の API ソケット（[podman.md 手順 7](podman.md#実施手順)）を、Trivy・podman-tui・Pods・Podman Desktop が使う
  - lazydocker など Docker の API を使うツールは、`DOCKER_HOST` で同じソケットに向ける
  - dive は podman のコマンドでイメージを読むので、ソケットは要らない
- PC の起動時に動かしておくコンテナは、podman.md の任意節（Quadlet）で動かす（[linger](linger.md) が前提）

| 手順書 | 用途 | 打つコマンド | 導入元 | 前提 |
|---|---|---|---|---|
| [Podman](podman.md) | コンテナを自分のユーザーで動かす。API ソケット、Quadlet での自動起動（任意） | `podman` | AppStream（Homebrew 版はシステムの podman を隠すので使わない） | — |
| [distrobox](distrobox.md) | 別のディストリ（既定は Ubuntu 24.04）の端末とパッケージを使う。入れたコマンドはホストから呼べる | `distrobox create` / `enter` | EPEL | Podman、EPEL |
| [podman-compose](podman-compose.md) | compose ファイルで、複数のコンテナをまとめて動かす | `podman-compose`（`podman compose` からも呼ばれる） | EPEL | Podman、EPEL |
| [hadolint / dive / Trivy](image-tools.md) | イメージを作るときの検査（Containerfile の書き方、層の無駄、脆弱性） | `hadolint` / `dive` / `trivy`（作るのは `podman build`） | Homebrew と Trivy の公式 dnf リポジトリ | Podman、Homebrew |
| [podman-tui](podman-tui.md) | podman のコンテナ・pod・イメージ・ボリューム・ネットワーク・シークレットを、端末の画面（TUI）で見て操作する | `podman-tui`（終了は `Ctrl+C`） | EPEL（Homebrew の 2.x は podman 6 向け） | Podman、EPEL |
| [lazydocker](lazydocker.md) | コンテナの TUI。ログと CPU の使用率が見やすい。compose のサービスと、root のコンテナも見られる（任意節） | `lazydocker`（root のコンテナは `sudo -i lazydocker`） | Homebrew（RPM 無し） | Podman（Docker 向けの節まで）、Homebrew |

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [toolbox](tool-catalog.md#cli-コンテナ) | 別のディストリの端末をコンテナで使う（distrobox と同類。RHEL の公式） | AppStream |
| [podman-docker](tool-catalog.md#cli-コンテナ) | `docker` コマンドを podman に読み替える | AppStream |
| [buildah](tool-catalog.md#cli-コンテナ) | Containerfile を使わずにイメージを作る | AppStream |
| [skopeo](tool-catalog.md#cli-コンテナ) | レジストリのイメージを取得せずに調べる・コピーする | AppStream |
| [podlet](tool-catalog.md#cli-コンテナ) | podman のコマンドや compose ファイルから Quadlet の定義を作る | Homebrew |
| [cosign](tool-catalog.md#cli-コンテナ) | イメージの署名と検証 | Homebrew |
| [Podman Desktop](tool-catalog.md#コンテナ) | podman の GUI | Flathub |
| [Pods](tool-catalog.md#コンテナ) | podman の GUI（GNOME のアプリ） | Flathub |
| [BoxBuddy](tool-catalog.md#コンテナ) | distrobox の GUI | Flathub |
| [Cockpit の podman の画面](tool-catalog.md#コンテナ) | ブラウザからコンテナを操作する | AppStream / BaseOS |

### 仮想化

- VirtualBox は x86_64 だけ。[EPEL（AlmaLinux 10 の初期設定の手順 17）](almalinux-setup.md#実施手順)・モジュールのビルドの道具・（Secure Boot が有効なら）[MOK の登録](secure-boot-mok.md)を先に用意する。EL10 のカーネルでは KVM と同時に動かない
- ゲスト側の Guest Additions は、VM が bootc（AlmaLinux Atomic Desktop）なら dnf では入らない。派生イメージを VM でビルドし、`bootc switch` で切り替える（`/usr`・`/opt` は読み取り専用で、`/var` はイメージから更新されない）
  - Secure Boot が有効な VM では、ゲストでも同じ [MOK の登録](secure-boot-mok.md)を先に行う（鍵はホストとは別）
  - ホストが Windows 11 の VirtualBox でも、同じ手順で入る。Hyper-V（WSL 2 など）が動いている Windows では、重い処理の途中で VM が数分ずつ止まることがある（VM のウィンドウでキーを押すと動き出す）
  - VM がホストオンリーアダプターだけでインターネットに出られないときは、ホスト（Windows では WSL の AlmaLinux 10）の rootless の podman で同じ Containerfile をビルドし、`podman save` のファイルを ssh で VM に運んで `podman load` する。ベースの署名は VM の `policy.json` と公開鍵をホストに写して確かめ、Secure Boot の鍵はホストで作る
- Windows 11 の PC に Android の Windows App からリモート デスクトップでつないで VM に打つときは、Windows App の「使用可能な場合にスキャンコード入力を使用する」をオンにする（[VirtualBox の任意節](virtualbox.md#windows-11-の-virtualbox-を-android-からリモート-デスクトップで使う任意)）
  - 既定の Unicode の入力では、打った文字が VM で別のキーになる（`1.,2` が `nczm`）
  - 画面のキーボード（Gboard）では Shift で打つ記号が出ないので、VirtualBox のソフトキーボードで打つ。物理キーボードは記号まで出る

| 手順書 | 用途 | 導入元 | ほかの経路 | アーキ |
|---|---|---|---|---|
| [VirtualBox](virtualbox.md) | 仮想マシン | Oracle 公式 dnf リポジトリ（7.2 系）。Windows 11 は winget の `Oracle.VirtualBox`（PC 全体） | RPM Fusion（EL10）・Flathub には無い | x86_64 だけ |
| [VirtualBox Guest Additions（bootc のゲスト）](virtualbox-guest-bootc.md) | VM の中のクリップボードの共有・画面サイズの自動変更・共有フォルダー | ホストの Guest Additions の CD を、VM でビルドする派生イメージに焼き込む | AppStream・EPEL 10・ELRepo に無く、EL10 のカーネルにもドライバが無い | x86_64 だけ |

### ブラウザ

- Firefox と Google Chrome は、ベンダーの公式 dnf リポジトリから入れる。`sudo dnf upgrade` で上がる
- Mozilla の Linux 版 Firefox は AAC と H.264 を自前で復号できないので、RPM Fusion（free）の FFmpeg（`ffmpeg-libs`）で補う（[AlmaLinux 10 の初期設定の手順 18〜21](almalinux-setup.md#実施手順) で有効にし、[firefox.md 手順 8〜11](firefox.md#実施手順) で入れる）。入れないと、音声が AAC だけの動画が再生できず、YouTube で 720p 以上が H.264 だけの動画は 360p までしか選べないことがある
- Microsoft Edge は x86_64 にしか無く、導入元一覧では導入元を決めていない（[aarch64 で使えないもの](tool-catalog.md#aarch64-で使えないもの)に提供元だけ載せてある）

| 手順書 | 導入元 | ほかの経路 | アーキ |
|---|---|---|---|
| [Firefox](firefox.md) | Mozilla 公式 dnf リポジトリ（最新版。4 週間ごとの Rapid Release）。AAC・H.264 の FFmpeg は RPM Fusion（free）。Windows 11 は winget の `Mozilla.Firefox.ja`（PC 全体。Firefox 自身が更新し、AAC・H.264 は Windows の Media Foundation で復号する） | AppStream は ESR 140（年 1 回のメジャー更新） | x86_64・aarch64 |

| 手順書の無いツール | 導入元 | アーキ |
|---|---|---|
| [Google Chrome](tool-catalog.md#ブラウザ) | [公式 dnf リポジトリ](tool-catalog.md#ベンダーの-dnf-リポジトリ) | x86_64・aarch64 |
| [Chromium](tool-catalog.md#ブラウザ) | EPEL（Flathub 版は新しいが、公開元が未検証） | x86_64・aarch64 |
| [Microsoft Edge](tool-catalog.md#aarch64-で使えないもの) | 決めていない（公式 dnf リポジトリと Flathub にあるが、入れていない） | x86_64 だけ |

### パスワード管理

- 手順書は無い

| 手順書の無いツール | 用途 | 導入元 |
|---|---|---|
| [KeePassXC](tool-catalog.md#パスワード管理) | パスワード管理（ローカルのファイル） | EPEL |
