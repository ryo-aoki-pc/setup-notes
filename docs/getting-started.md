# 導入順

[目的別の手順書一覧](README.md)・[手順書とツールの比較](catalog.md)・[リポジトリの入口](../README.md)

OS のインストール後は、その OS の初期設定から始める。各手順書の冒頭で、実行するユーザー・前提・検証範囲を確かめる。

## AlmaLinux 10

1. [AlmaLinux 10 の初期設定](almalinux-setup.md)を通す。Workstation の GNOME に、インストール時に作った管理者のユーザーでログインして行う
1. [Git](git.md) → [Firefox](firefox.md) → [HackGen Console NF](hackgen.md) → [WezTerm](wezterm-nightly.md) → [Claude Code](claude-code.md) → [Codex CLI](codex.md)の順に進む
1. WezTerm と HackGen Console NF を入れたら、[デスクトップで使うための設定](almalinux-setup.md#wezterm-と-hackgen-console-nf-をデスクトップで使う任意)を行う
1. [目的別の一覧](README.md)から必要な手順書を選び、個人用の設定は [設定リポジトリの一覧](../README.md#設定のリポジトリ)から導入する

初期設定に共通の bash 設定と Homebrew、シェルのツールの導入も含む。後続の手順書から初期設定の手順を指定されたら、その項目を確認する。

## Windows 11

1. デュアルブートにする場合は、先に [Windows 11 のデュアルブート向けの導入](windows-dual-boot.md)を通す
1. [Windows 11 の初期設定](windows-setup.md)を通す。PC のデスクトップで行い、各手順に指定された管理者・通常の Windows PowerShell 5.1 の窓を使う
1. [Git for Windows](git.md#windows-11-で-git-for-windows-を入れる)を入れ、続けて Git Bash で [Git の実施手順](git.md#実施手順)と [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を通す
1. [Firefox](firefox.md#windows-11-で使う) → [WezTerm](wezterm-nightly.md#windows-11-で使う) → [Claude Code](claude-code.md#windows-11-で使う) → [VirtualBox](virtualbox.md#windows-11-で使う) → [WireGuard](wireguard-road-warrior.md#windows-11-で使う) → [HackGen Console NF](hackgen.md#windows-11-で使う)の順に、必要なものを入れる
1. 差分の表示と GitHub の操作も使うなら、Git for Windows と WezTerm の後に [git-delta](git-delta.md#windows-11-で使う) → [GitHub CLI](gh.md#windows-11-で使う)を通す。エディタと TUI も使うなら、続けて [Neovim](neovim.md#windows-11-で使う) → [lazygit](lazygit.md#windows-11-で使う) → [yazi](yazi.md#windows-11-で使う)を通す
1. 個人用の設定は [設定リポジトリの一覧](../README.md#設定のリポジトリ)から導入する。Git Bash のシェルのツールは、WezTerm の設定まで済ませてから [初期設定の任意節](windows-setup.md#シェルのツールを入れる任意)を通す

同じツールの AlmaLinux 10 と Windows 11 の手順は、同じ文書にある。Windows では「Windows 11 で使う」などの見出しから始める。

## 後から選ぶ設定と共通の前提

| 目的 | 次に読む手順書・節 |
|---|---|
| 常時動かす AlmaLinux の PC | [画面オフ・画面ロック・自動サスペンド](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)、[SSH を公開鍵だけにする](almalinux-setup.md#ssh-を公開鍵だけにする任意)、[自動更新](almalinux-setup.md#dnf-automatic-で自動で更新する任意) |
| Windows のリモート操作 | [リモート接続と VPN](README.md#リモート接続と-vpn)、[リモートから再起動する手段](windows-setup.md#リモートから再起動する手段を増やす任意) |
| Windows の表示とシェル | [表示・入力・音・ストレージ](windows-setup.md#表示入力音ストレージを変える任意)、[PowerShell 7](windows-setup.md#powershell-7-のプロファイルを設定する任意)、[Windows Terminal](windows-setup.md#windows-terminal-のフォントと貼り付けの警告を変える任意)、[WSL のネットワーク](windows-setup.md#wsl-のネットワークをミラーにする任意) |
| ログアウト中もユーザーサービスを動かす | [linger](linger.md)。Syncthing・Dropbox・Podman の Quadlet などの前提 |
| Secure Boot で外部カーネルモジュールを使う | [MOK 登録](secure-boot-mok.md)。VirtualBox と bootc ゲストの Guest Additions の前提 |
| インターネットに出られないホストに入れる | [ssh の SOCKS トンネル](ssh-socks-tunnel.md) → [Homebrew](homebrew-offline.md) → 必要なら [npm](npm-offline.md) |

前提を共有する手順書では、既に行った設定を確認してから進む。設定を戻す場合は、それを使うサービスやツールが残っていないことを確かめる。

## OS のインストール

- Windows 11 と AlmaLinux 10 を 1 台のディスクに入れるときは、Windows を先に入れる。Windows のセットアップで ESP（EFI システム パーティション）を 2 GiB で作り、後ろに AlmaLinux 用の未割り当て領域を残す
- AlmaLinux 10 のインストールの手順書は無い。入れるときの要点（ESP を `/boot/efi` に割り当て、フォーマットしない）は、下の手順書の注意点にある。入れた後は [AlmaLinux 10 の初期設定](almalinux-setup.md)を通す
- 両 OS の導入後、Windows から次回だけ AlmaLinux を起動する方法は、同書の [QEFI Entry Manager の任意節](windows-dual-boot.md#次回だけ-almalinux-で起動する任意)にある。通常の起動順は変えず、GUI で指定して CLI と BCDEdit で確かめる
- インストールと QEFI Entry Manager の実施範囲は、[検証記録](verification/windows-dual-boot.md)を参照する

| 手順書 | 入れる OS | メディア | ディスクの使い方 | 次にすること |
|---|---|---|---|---|
| [Windows 11（AlmaLinux 10 とのデュアルブート向け）](windows-dual-boot.md) | Windows 11（24H2 以降） | Rufus で作った USB（「インストーラーをカスタムしますか?」の 7 項目をオン、「サイレント」はオフ） | セットアップのコマンド プロンプトの diskpart で、ESP 2 GiB・MSR・Windows・回復を作り、残りを未割り当てにする | 未割り当て領域に AlmaLinux 10 を入れる。入れた後は、それぞれの OS で [Windows 11 の初期設定](windows-setup.md)・[AlmaLinux 10 の初期設定](almalinux-setup.md)を通す |

## 初期設定で整えるもの

- AlmaLinux 10 では、インストールした直後に [AlmaLinux 10 の初期設定](almalinux-setup.md)を通す（更新・NOPASSWD の sudo・ファームウェア・journal・kdump、EPEL・RPM Fusion・Flathub、日本語入力と GNOME の表示・入力、共通の bash 設定・Homebrew と starship・zoxide・fzf・eza・bat・tmux）
  - [比較表](catalog.md#導入の基盤)の EPEL・RPM Fusion・Flatpak / Flathub・Homebrew は、同書の手順 17・18〜21・22〜24・46〜48
  - Git・Firefox・HackGen Console NF・WezTerm・Claude Code・Codex CLI の手順書は、同書の後に、そのリードの順に通す
  - 常時動かしておく PC の画面オフ・画面ロック・自動サスペンド、SSH を公開鍵だけにする、dnf-automatic、Wake on LAN は、同書の任意節
- Windows 11 では、インストールした直後に [Windows 11 の初期設定](windows-setup.md)を通す（更新、貼り付けの設定、scoop・UniGet UI・PowerToys・PowerShell 7・WSL、表示・電源・リモートの設定）
  - Windows Update は PSWindowsUpdate で通常の更新だけを入れ、再起動は手動。Store は同梱の CLI で全アプリを更新する（Preview 版の CLI）
  - CLI ツールは scoop で、GUI アプリは UniGet UI（winget と scoop を画面で扱う）で入れる
  - AlmaLinux 10 と同じツール（Git for Windows・Firefox・WezTerm・Claude Code・VirtualBox・WireGuard・HackGen Console NF、続けて git-delta・GitHub CLI・Neovim・lazygit・yazi）は、それぞれの手順書の Windows 11 の節で入れ、Windows 11 の初期設定のリードから順に案内する
  - 任意節で、プライバシーと広告の表示・誤って押しやすいキーやアニメーション・効果音・ストレージ センサー、Edge の常駐、クリップボードの履歴（CopyQ）も変えられる
  - 同じく任意節で、PowerToys のユーティリティを絞り、PowerShell 7 のプロファイル（貼り付け・履歴の検索・starship と zoxide）を書き、Windows Terminal のフォントを HackGen Console NF にし、WSL のネットワークをミラーにできる
  - AlmaLinux 10 の初期設定の手順 49 で入れる starship・zoxide・fzf・eza・bat は、同じく任意節「[シェルのツールを入れる](windows-setup.md#シェルのツールを入れる任意)」で、Git Bash 用に scoop で入れる（zoxide は 0.9.9 に止める。tmux は入れない）
  - 各手順の実施範囲は、対応する検証記録を参照する
