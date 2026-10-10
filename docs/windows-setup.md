# Windows 11 の初期設定の手順（インストール直後の更新・貼り付けの設定・scoop・UniGet UI・表示・電源・リモート・WSL・OpenSSH・Git・Firefox・WezTerm・Neovim・AI エージェント）

## 実施手順

- [検証記録](verification/windows-setup.md)・[参考資料](reference/windows-setup.md)・[ロールバックと注意点](extra/windows-setup.md)

> [!IMPORTANT]
> - **すべて、この PC のデスクトップで行う**。SSH のセッションには貼らない（Administrators の一員の SSH のセッションは管理者の権限で動くので、[アプリを入れる](#アプリを入れる)の手順 1 の scoop のインストーラが止まる）
> - 窓の使い分け: [Windows Update](#windows-update)の手順 1 で**管理者の** Windows PowerShell（5.1）を開き、同じ項の手順 2〜8 で Windows Update を行う。[Microsoft Store の更新](#microsoft-store-の更新)の手順 1 で**管理者ではない** Windows PowerShell を開き、同じ項の手順 2〜7 と、[貼り付けの設定](#貼り付けの設定)から[HackGen Console NF](#hackgen-console-nf)までの手順をそこに貼る。[PC 全体の設定](#pc-全体の設定)の手順 1 で管理者の窓を開き、同じ項の手順 2〜8 と、[ネットワークとリモート](#ネットワークとリモート)から[WSL と再起動](#wsl-と再起動)までの手順（[OpenSSH サーバー](#openssh-サーバー)・[Git for Windows](#git-for-windows)・[Firefox](#firefox)・[WezTerm](#wezterm)も）を貼る。再起動の後は、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 で開く管理者ではない窓に、同じ項の手順 2〜5 と、それより後の項の PowerShell のブロックを貼る（[Claude Code](#claude-code)・[Codex CLI](#codex-cli)・[Grok Build](#grok-build)・[Codex・Grok のプラグイン](#codexgrok-のプラグイン)は、項の中で開き直した窓に貼る）
> - bash のブロックの貼り先: [SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 2〜4 はクライアント（この PC の WSL の AlmaLinux 10 など）のシェル、[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 3〜5 は Git Bash。それより後の bash のブロックは、WezTerm の新しいタブ（Git Bash）に貼る
> - ログインするユーザーは Administrators の一員（[Windows Update](#windows-update)の手順 2〜8 の Windows Update と、[PC 全体の設定](#pc-全体の設定)の手順 2〜8 から[WSL と再起動](#wsl-と再起動)までの PC 全体の設定に管理者の権限が要る。OpenSSH サーバー・Git for Windows・Firefox・WezTerm も PC 全体に入れる）
> - 前提: AI エージェントと GitHub のアカウント（[AlmaLinux 10 の初期設定](almalinux-setup.md#実施手順)のリードと同じ）
> - [Windows Update](#windows-update)の手順 2〜8 と[Microsoft Store の更新](#microsoft-store-の更新)の手順 2〜7 は、**Ctrl+V で貼る**。貼り付けの設定をまだ通していないため、conhost の窓に右クリックで貼ると行が逆順になる
> - [貼り付けの設定](#貼り付けの設定)の手順 1 は、**1 行なので、どの貼り方でもそのまま貼れる**。この 1 行を貼った窓には、それより後の複数行のブロックを、GitHub のコピーボタンでコピーして右クリックで貼れる。Windows の PowerShell のブロックを貼るほかの手順書も、[貼り付けの設定](#貼り付けの設定)の手順 1〜4 を前提にする
> - [WSL と再起動](#wsl-と再起動)の手順 2 で、**再起動する**（設定のための再起動はこの 1 回。HackGen Console NF のフォントと WezTerm の VC++ ランタイムも、この再起動で読み直す。Windows Update は、必要なときだけ[Windows Update](#windows-update)の手順 8 で手動で再起動し、更新が無くなるまで繰り返す）
> - **画面で行う手順**: [Windows Update](#windows-update)・[Microsoft Store の更新](#microsoft-store-の更新)・[PC 全体の設定](#pc-全体の設定)のそれぞれの手順 1、[Firefox](#firefox)の手順 3・4（起動して確かめる・既定のブラウザー）、[WezTerm](#wezterm)の手順 5、[再起動の後に確かめる](#再起動の後に確かめる)の手順 1〜5、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1、[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 2・5（Git Bash と WezTerm を開く）、[シェルのツールを入れる](#シェルのツールを入れる)の手順 7（キーを押して確かめる）、[yazi](#yazi)の手順 7（WezTerm のタブを開く）、[Claude Code](#claude-code)の手順 5・[Codex CLI](#codex-cli)の手順 4・[Grok Build](#grok-build)の手順 4・[Codex・Grok のプラグイン](#codexgrok-のプラグイン)の手順 2（PowerShell を開き直す）、[GitHub CLI](#github-cli)の手順 4・[Claude Code](#claude-code)の手順 7・[Codex CLI](#codex-cli)の手順 6・[Grok Build](#grok-build)の手順 6（ブラウザでのログイン）。[表示と入力](#表示と入力)の手順 7 は設定の画面を開いて変える。**対話入力のある手順**: [WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 3（WSL のユーザー名とパスワード）・同じ項の手順 5（自動サインインのパスワード）、[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 1（WSL のシェルに入る）・2（`sudo` のパスワード）・4（ホスト鍵の確認とパスワード）、[git-delta](#git-delta)の手順 4（less）、[GitHub CLI](#github-cli)の手順 3（`gh auth login`）、[Neovim](#neovim)の手順 3（Neovim の画面）、[lazygit](#lazygit)の手順 6・[yazi](#yazi)の手順 8・9（TUI の画面）、[Claude Code](#claude-code)の手順 7（最初の設定とログイン）、[Codex CLI](#codex-cli)の手順 2（`Start Codex now?`）・5・8、[Grok Build](#grok-build)の手順 5・8。**条件付きの手順**: [Windows Update](#windows-update)の手順 5・7・8 と[Microsoft Store の更新](#microsoft-store-の更新)の手順 3・4・6（更新の結果による分岐）、[PC 全体の設定](#pc-全体の設定)の手順 5（PC の名前を変えるとき）、[ネットワークとリモート](#ネットワークとリモート)の手順 2（Pro 以上）、[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 5（デュアル ブートで、AlmaLinux の時計を UTC にしたとき）・同じ項の手順 6（US 配列のキーボード）、[Git for Windows](#git-for-windows)の手順 2（入っていないとき）、[WezTerm](#wezterm)の手順 2（VC++ ランタイムが無いとき）、[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 2（`ssh` が無いとき）、[シェルのツールを入れる](#シェルのツールを入れる)の手順 2（zoxide が 0.9.9 でないとき）、[lazygit](#lazygit)の手順 2（extras のバケットが無いとき）、[Codex・Grok のプラグイン](#codexgrok-のプラグイン)の手順 2（同じ項の手順 1 で Node.js を入れたとき）

- 上から順にコードブロックを貼る。[PC 全体の設定](#pc-全体の設定)の手順 2 の変数は、管理者の PowerShell を開き直したら貼り直す（[OpenSSH サーバー](#openssh-サーバー)の手順 3・5 も使う）
  - [SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 3・[yazi](#yazi)の手順 1・[Claude Code](#claude-code)の手順 1 の変数も、その項の中で新しいシェルや窓を開いたら貼り直す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- 項目ごとの手順（要らない項目の手順は飛ばしてよい。[Microsoft Store の更新](#microsoft-store-の更新)の手順 1、[貼り付けの設定](#貼り付けの設定)の手順 1〜4、[PC 全体の設定](#pc-全体の設定)の手順 1〜3、[Git for Windows](#git-for-windows)の手順 1・2、[Firefox](#firefox)の手順 1〜4（ブラウザでのログインに使う）、[WezTerm](#wezterm)の手順 1〜5、[WSL と再起動](#wsl-と再起動)の手順 2、[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 1〜5、[シェルのツールを入れる](#シェルのツールを入れる)の手順 1・3・4 は飛ばさない）
  - 更新: Windows Update は[Windows Update](#windows-update)の手順 1〜8、Microsoft Store は[Microsoft Store の更新](#microsoft-store-の更新)の手順 1〜7。貼り付けの設定: [貼り付けの設定](#貼り付けの設定)の手順 1〜4 と[PC 全体の設定](#pc-全体の設定)の手順 3・4
  - 入れるもの: scoop は[アプリを入れる](#アプリを入れる)の手順 1・2、UniGet UI は同じ項の手順 3 と[再起動の後に確かめる](#再起動の後に確かめる)の手順 4、PowerToys は[アプリを入れる](#アプリを入れる)の手順 4、PowerShell 7 は同じ項の手順 5、WSL の AlmaLinux 10 は[WSL と再起動](#wsl-と再起動)の手順 1 と[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 3・4、自動サインイン（Autologon）は同じ項の手順 5
  - 表示: エクスプローラーは[表示と入力](#表示と入力)の手順 1、旧形式のコンテキストメニューは同じ項の手順 2、スタートと検索は同じ項の手順 3 と[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 2、タスクバーは[表示と入力](#表示と入力)の手順 4 と[再起動の後に確かめる](#再起動の後に確かめる)の手順 3、ダークモードは[表示と入力](#表示と入力)の手順 5、既定の端末は同じ項の手順 6
  - 入力: IME の Ctrl+Space は[表示と入力](#表示と入力)の手順 7、Caps Lock を Ctrl には[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 4、US 配列のキーボードは同じ項の手順 6。確かめるのは[再起動の後に確かめる](#再起動の後に確かめる)の手順 1
  - 整理: 自動で起動するアプリは[自動起動と標準アプリ](#自動起動と標準アプリ)の手順 1、標準アプリは同じ項の手順 2、ウィジェットは同じ項の手順 3、デスクトップのショートカットは[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 3
  - PC 全体: PC の名前は[PC 全体の設定](#pc-全体の設定)の手順 5、長いパス・開発者モード・sudo は同じ項の手順 6、電源とロックは同じ項の手順 7、LAN のアダプターの省電力は同じ項の手順 8、デュアル ブートの時計は[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 5
  - ネットワーク: LAN をプライベートには[ネットワークとリモート](#ネットワークとリモート)の手順 1、リモート デスクトップは同じ項の手順 2、リモート アシスタンスは同じ項の手順 3、ping は同じ項の手順 4、配信の最適化は同じ項の手順 5
  - サインイン: Windows Hello だけのサインインを切るのは[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 1、自動サインインは[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 5
  - フォント: HackGen Console NF は[HackGen Console NF](#hackgen-console-nf)の手順 1・2。確かめるのは[再起動の後に確かめる](#再起動の後に確かめる)の手順 5
  - リモート: OpenSSH サーバーは[OpenSSH サーバー](#openssh-サーバー)の手順 1〜5。確かめるのは[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 1〜4
  - Git: Git for Windows は[Git for Windows](#git-for-windows)の手順 1・2 と[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 1、`~/.gitconfig` は同じ項の手順 2・3、共通の bash 設定は同じ項の手順 4、git-delta は[git-delta](#git-delta)の手順 1〜4、GitHub CLI は[GitHub CLI](#github-cli)の手順 1〜5、lazygit は[lazygit](#lazygit)の手順 1〜6（自分用の設定は同じ項の手順 4）
  - ブラウザと端末: Firefox は[Firefox](#firefox)の手順 1〜4、WezTerm は[WezTerm](#wezterm)の手順 1〜5（自分用の設定は[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 5）、Git Bash の starship・zoxide・fzf・eza・bat は[シェルのツールを入れる](#シェルのツールを入れる)の手順 1〜7
  - エディタとファイル: Neovim は[Neovim](#neovim)の手順 1・2・4（自分用の設定は同じ項の手順 3）、yazi は[yazi](#yazi)の手順 1〜9（自分用の設定は同じ項の手順 5）
  - AI エージェント: Claude Code は[Claude Code](#claude-code)の手順 1〜8、Codex CLI は[Codex CLI](#codex-cli)の手順 1〜8、Grok Build は[Grok Build](#grok-build)の手順 1〜8、Claude Code に入れる Codex・Grok のプラグインは[Codex・Grok のプラグイン](#codexgrok-のプラグイン)の手順 1〜3（3 つを入れた後）
- Windows を AlmaLinux 10 とのデュアルブート向けに入れるときは、先に [Windows 11 のデュアルブート向けの導入](windows-dual-boot.md)を通してから、この文書を[Windows Update](#windows-update)の手順 1 から始める
- 手順の後に、この順に通す手順書（どれも Windows 11 の節がある）: [VirtualBox](virtualbox.md#windows-11-で使う) → [WireGuard](wireguard.md#windows-11-で使う)
  - 必要なら: [Syncthing の Windows 11 で使う](syncthing.md#windows-11-で使う)・[Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)・[RDP をロックせずに切断（Windows）](windows-rdp-disconnect.md)・[SSH クライアント（Windows）](windows-ssh-client.md)・[Samba の共有をネットワーク ドライブに](samba-client.md#windows-11-で使う)・[コーディングエージェントの共同作業](coding-agents.md#windows-11-で使う)
- 手順の後の節
  - Wake on LAN は[Wake on LAN を使う（任意）](#wake-on-lan-を使う任意)、リモートからの再起動を増やすなら[リモートから再起動する手段を増やす（任意）](#リモートから再起動する手段を増やす任意)
  - 広告 ID などのプライバシーと宣伝の表示は[プライバシーと広告の表示を切る（任意）](#プライバシーと広告の表示を切る任意)、誤って押しやすいキー・Alt+Tab・ギャラリーとホーム・タスクの終了・アニメーション・効果音・ストレージ センサーは[表示・入力・音・ストレージを変える（任意）](#表示入力音ストレージを変える任意)
  - Edge の常駐は[Edge の常駐をポリシーで止める（任意）](#edge-の常駐をポリシーで止める任意)（管理者の窓）、クリップボードの履歴は[CopyQ を使う（任意）](#copyq-を使う任意)
  - PowerToys は[PowerToys のユーティリティを絞る（任意）](#powertoys-のユーティリティを絞る任意)、PowerShell 7 の貼り付け・履歴の検索・starship と zoxide は[PowerShell 7 のプロファイルを設定する（任意）](#powershell-7-のプロファイルを設定する任意)
  - Windows Terminal のフォントは[Windows Terminal のフォントと貼り付けの警告を変える（任意）](#windows-terminal-のフォントと貼り付けの警告を変える任意)、WSL のネットワークは[WSL のネットワークをミラーにする（任意）](#wsl-のネットワークをミラーにする任意)
  - OpenSSH サーバーは、鍵でも入るなら[OpenSSH サーバーに公開鍵でもログインする（任意）](#openssh-サーバーに公開鍵でもログインする任意)、その後にパスワードを受け付けないなら[OpenSSH サーバーのパスワード認証を切る（任意）](#openssh-サーバーのパスワード認証を切る任意)、ログインのシェルを Git Bash にするなら[SSH の既定のシェルを Git Bash にする（任意）](#ssh-の既定のシェルを-git-bash-にする任意)、scoop のツールが SSH のセッションで起動しないなら[scoop のツールを SSH のセッションで使う（任意）](#scoop-のツールを-ssh-のセッションで使う任意)
  - PowerShell などから起動するツール（lazygit の `e` キーなど）にも Neovim を使わせるなら[Neovim を既定のエディタにする（任意）](#neovim-を既定のエディタにする任意)
  - Git for Windows の既定（`core.autocrlf=true`）のまま clone したリポジトリ（[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 3 より前に clone したもの）があれば、[AlmaLinux 10 の初期設定の「改行を変換して clone したリポジトリを直す」](almalinux-setup.md#改行を変換して-clone-したリポジトリを直す)を、Git Bash でそのリポジトリに行う
  - starship・fzf・eza・bat・WezTerm・git-delta・Neovim・lazygit・yazi・Codex CLI・Grok Build の使い方と設定ファイル、Claude Code の使い方は、[AlmaLinux 10 の初期設定](almalinux-setup.md)の後ろの節（両 OS で同じ）。Git Bash のタブに、同じブロックを貼る
    - [fzf で fd と bat を候補とプレビューに使う（任意）](almalinux-setup.md#fzf-で-fd-と-bat-を候補とプレビューに使う任意)の `brew install fd`・`brew uninstall fd` は、管理者ではない窓で `scoop install fd`・`scoop uninstall fd` にする（[yazi](#yazi)の手順 3 で入っていれば、入れなくてよい）
    - bat の設定ファイルは、[同書の節](almalinux-setup.md#bat-の設定ファイル)ではなく、[シェルのツールを入れる](#シェルのツールを入れる)の手順 5 で書く
  - SSH のセッションの Git Bash でも scoop のツールを使うなら、scoop で入れた後に[scoop のツールを SSH のセッションで使う（任意）](#scoop-のツールを-ssh-のセッションで使う任意)の手順 1 を管理者の窓で貼る（`scoop install`・`scoop update` の後も貼り直す）
  - 以後は[更新](#更新)・[ロールバック](extra/windows-setup.md#ロールバック)

> [!WARNING]
> - [PC 全体の設定](#pc-全体の設定)の手順 6 のインラインの sudo、同じ項の手順 7 の放置でロックしない設定、[ネットワークとリモート](#ネットワークとリモート)の手順 2 のリモート デスクトップ、[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 1 の Windows Hello 以外のサインイン、[OpenSSH サーバー](#openssh-サーバー)の手順 4 のパスワードでの SSH のログイン、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 5 の自動サインインを重ねると、**PC に触れる人と、このユーザーのパスワードを知る人は、このユーザー（管理者）として操作できる**（SSH なら LAN から）。人が触れる場所にある PC では、[PC 全体の設定](#pc-全体の設定)の手順 7 と[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 5 は行わない

### Windows Update

1. Windows のデスクトップで、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリック →「管理者として実行」。UAC の確認で「はい」
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする
   - この項の手順 2〜8 はこの窓に貼る

1. 管理者であることを確かめ、今の窓だけモジュールを使えるようにする。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {
       throw '中断: Windows PowerShell 5.1 で実行する'
     }
     if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
       throw '中断: 「Windows Update」の手順 1 で管理者の Windows PowerShell を開く'
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Module -ListAvailable -Name PSWindowsUpdate | Select-Object Name, Version, ModuleBase
     if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
       Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
     }
     if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
       throw '中断: 実行ポリシーによりモジュールを読み込めない'
     }
     [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
     'この窓の実行ポリシー: {0}' -f (Get-ExecutionPolicy)
   }
   ```

   - PSWindowsUpdate の一覧が出たら、版と場所を控える。何も並ばなければ、この項の手順 3 で初めて入れる
   - 最後に `RemoteSigned`・`Unrestricted`・`Bypass` のいずれかが出ればよい
   - エラーが出たら進まない

1. PSWindowsUpdate が無ければ自分のユーザーに入れ、読み込む。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
       $gallery = Get-PSRepository -Name PSGallery
       if ($gallery.SourceLocation.TrimEnd('/') -ne 'https://www.powershellgallery.com/api/v2') {
         throw '中断: PSGallery の取得先が PowerShell Gallery ではない'
       }
       $nuget = Get-PackageProvider -ListAvailable | Where-Object { $_.Name -eq 'NuGet' -and $_.Version -ge [version]'2.8.5.201' }
       if (-not $nuget) {
         Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
       }
       Install-Module -Name PSWindowsUpdate -Repository PSGallery -Scope CurrentUser -Force
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Import-Module -Name PSWindowsUpdate -Global -PassThru | Select-Object Name, Version, ModuleBase
   }
   ```

   - `PSWindowsUpdate` の版と場所が出ればよい
   - この項の手順 2 で入っていなかった場合は、そのことを控える（[ロールバックの「再起動と PSWindowsUpdate」](extra/windows-setup.md#再起動と-pswindowsupdate)の手順 4 で使う）
   - ダウンロードや読み込みのエラーが出たら進まない
   - **次の手順は、モジュールの読み込みが終わってから貼る**

1. 再起動待ちでないことを確かめ、通常の Windows Update を検索する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $rebootRequired = Get-WURebootStatus -Silent
     if ($rebootRequired -isnot [bool]) { throw '中断: 再起動待ちかを確認できない' }
     if ($rebootRequired) {
       throw '中断: 再起動が必要。「Windows Update」の手順 8 を行ってから検索し直す'
     }
     $updates = @(Get-WindowsUpdate -Criteria 'IsInstalled=0 and IsHidden=0 and IsAssigned=1 and BrowseOnly=0' | ForEach-Object { $_ })
     '対象の更新: {0} 件' -f $updates.Count
     $updates | Format-Table KB, Size, Title -AutoSize
   }
   ```

   - 更新の件数と一覧を確かめる
   - `対象の更新: 0 件` なら、この項の手順 5 は飛ばす（この項の手順 6・7 で最終確認する）
   - 再起動が必要と出たら、この項の手順 5〜7 は飛ばしてこの項の手順 8 へ。検索のエラーなら進まない
   - **次の手順は、検索が終わり、更新の一覧を確かめてから貼る**

1. 対象の更新があるときだけ、ダウンロードしてインストールする。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $rebootRequired = Get-WURebootStatus -Silent
     if ($rebootRequired -isnot [bool]) { throw '中断: 再起動待ちかを確認できない' }
     if ($rebootRequired) {
       throw '中断: 再起動が必要。「Windows Update」の手順 8 を行ってから検索し直す'
     }
     Install-WindowsUpdate -Criteria 'IsInstalled=0 and IsHidden=0 and IsAssigned=1 and BrowseOnly=0' -AcceptAll -IgnoreReboot |
       ForEach-Object {
         $_
         if ($_.Result -notin 'Accepted', 'Downloaded', 'Installed') {
           throw "中断: 更新が成功しなかった（$($_.Result)）: $($_.Title)"
         }
       }
   }
   ```

   - `Accepted`・`Downloaded` だけではインストール完了ではない
   - `Installed` になったことを確かめる。エラーや `中断:` が出たら、理由を解決するまで次へ進まない
   - **次の手順は、インストールが終わり、プロンプトが戻ってから貼る**

1. Windows Update が再起動を必要としているか確かめる。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $rebootRequired = Get-WURebootStatus -Silent -ErrorAction Stop
     if ($rebootRequired -isnot [bool]) { throw '中断: 再起動待ちかを確認できない' }
     $rebootRequired
   }
   ```

   - `True` なら、この項の手順 7 は飛ばしてこの項の手順 8 へ
   - `False` なら、この項の手順 7 へ。何も出ない場合やエラーの場合は、再起動不要とはみなさず進まない

1. 再起動が不要なときだけ、同じ条件で更新が残っていないか確かめる。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     $updates = @(Get-WindowsUpdate -Criteria 'IsInstalled=0 and IsHidden=0 and IsAssigned=1 and BrowseOnly=0' | ForEach-Object { $_ })
     $rebootRequired = Get-WURebootStatus -Silent
     if ($rebootRequired -isnot [bool]) { throw '中断: 再起動待ちかを確認できない' }
     if ($rebootRequired) {
       throw '中断: 再起動が必要。「Windows Update」の手順 8 を行ってから検索し直す'
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     '残っている対象の更新: {0} 件' -f $updates.Count
     $updates | Format-Table KB, Size, Title -AutoSize
     if ($updates.Count -gt 0) {
       Write-Warning '更新が残っている。「Windows Update」の手順 5 から繰り返す'
     } else {
       'Windows Update の確認完了（対象の更新なし・再起動待ちなし）'
     }
   }
   ```

   - 完了の行が出たら、この項の手順 8 は飛ばして[Microsoft Store の更新](#microsoft-store-の更新)の手順 1 へ
   - 更新が残っていたら、この項の手順 5〜7 を繰り返す。同じ更新が失敗し続ける場合は止め、エラーを調べる
   - **次の手順は、対象の更新が無くなり、再起動待ちも無くなってから行う**

1. 再起動が必要なときだけ、作業を保存して再起動する。

   ```powershell
   Restart-Computer
   ```

   - 自分で保存してから貼る。`-Force` は付けない
   - **次の手順は、起動してサインインし、この項の手順 1〜7 をもう一度通してから行う**（新しい窓ではこの項の手順 2・3 の準備と読み込みも必要）

### Microsoft Store の更新

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - [Windows Update](#windows-update)の手順 1 の管理者の窓を閉じる
   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする
   - Windows Terminal の中に開いた窓に複数行のブロックを貼ると、「複数の行を含むテキストを貼り付けようとしています」の警告が出る。「強制的に貼り付け」を押す

1. 管理者ではないことと、Store CLI・winget の有無を確かめる。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {
       throw '中断: Windows PowerShell 5.1 で実行する'
     }
     if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
       throw '中断: 「Microsoft Store の更新」の手順 1 で管理者ではない窓を開く'
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-AppxPackage -Name Microsoft.WindowsStore | Select-Object Name, Version
     foreach ($name in 'store.exe', 'winget.exe') {
       $command = Get-Command -Name $name -ErrorAction SilentlyContinue
       if ($command) { $command | Select-Object Name, Source } else { Write-Warning "見つからない: $name" }
     }
   }
   ```

   - `winget.exe` に場所が出れば、この項の手順 3 は飛ばす
   - `store.exe` があれば、この項の手順 4 はいったん飛ばしてこの項の手順 5 で一括更新に対応しているか確かめる
   - `store.exe` が無ければ、この項の手順 3（winget が無い場合だけ）・4 で準備する

1. winget が無いときだけ、このユーザーにアプリ インストーラーを登録する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Command -Name winget.exe | Select-Object Name, Source
     winget.exe --version
     if ($LASTEXITCODE -ne 0) { throw "中断: winget の確認に失敗（終了コード $LASTEXITCODE）" }
   }
   ```

   - `winget.exe` の場所と版が出ればよい
   - アプリ インストーラー自体が無い場合や、登録が失敗した場合は止める

1. Store CLI が無いか一括更新に非対応のときだけ、Store 本体を更新する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($id in '9NBLGGH4NNS1', '9WZDNCRFJBMP') {
       winget.exe upgrade --exact --id $id --source msstore --include-unknown --accept-source-agreements --accept-package-agreements --disable-interactivity
       if ($LASTEXITCODE -notin 0, -1978335189) {
         throw "中断: $id の更新に失敗（終了コード $LASTEXITCODE）"
       }
     }
   }
   ```

   - 更新が無い旨の表示なら、そのアプリは何も変えない
   - 終わったらこの項の手順 5 へ。まだ CLI が使えない場合は止める
   - **次の手順は、両方の更新が終わり、プロンプトが戻ってから貼る**

1. Store CLI が一括更新に対応していることを確かめ、更新を検索する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if (-not (Get-Command -Name store.exe -ErrorAction SilentlyContinue)) {
       throw '中断: Store CLI が無い。「Microsoft Store の更新」の手順 4 で準備してから再確認する'
     }
     $help = store.exe updates --help
     if ($LASTEXITCODE -ne 0 -or ($help -join "`n") -notmatch '--apply\b') {
       throw '中断: Store CLI の一括更新を確認できない。「Microsoft Store の更新」の手順 4 の後も同じなら進まない'
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     store.exe updates
     if ($LASTEXITCODE -ne 0) { throw "中断: Store の検索に失敗（終了コード $LASTEXITCODE）" }
   }
   ```

   - CLI が出す更新の一覧を確かめる。エラーが出たら進まない
   - 更新が無いと明示された場合だけ、この項の手順 6 は飛ばす
   - **次の手順は、検索が終わり、更新の一覧を確かめてから貼る**

1. Store の更新があるときだけ、すべての更新を適用する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     store.exe updates --apply
     if ($LASTEXITCODE -ne 0) { throw "中断: Store の更新に失敗（終了コード $LASTEXITCODE）" }
   }
   ```

   - エラーや適用できないアプリが出たら進まない。使用中のアプリが原因なら、作業を保存してそのアプリを閉じてから、この手順を貼り直す
   - **次の手順は、更新処理が終わり、プロンプトが戻ってから貼る**（コマンドの終了だけで更新完了とはみなさない）

1. Store の更新が残っていないかと、必要なアプリの状態を確かめる。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $ErrorActionPreference = 'Stop'
     store.exe updates
     if ($LASTEXITCODE -ne 0) { throw "中断: Store の再検索に失敗（終了コード $LASTEXITCODE）" }
     foreach ($name in 'Microsoft.DesktopAppInstaller', 'Microsoft.WindowsTerminal') {
       $package = Get-AppxPackage -Name $name
       if (-not $package) { throw "中断: 必要なアプリが無い: $name" }
       $package | Select-Object Name, Version, Status
       if ($package.Status -ne 'Ok') { throw "中断: アプリの状態を確認する: $name" }
     }
     winget.exe --version
     if ($LASTEXITCODE -ne 0) { throw "中断: winget の確認に失敗（終了コード $LASTEXITCODE）" }
   }
   ```

   - Store CLI が更新なしを明示し、2 つのアプリの `Status` が `Ok` で、winget の版が出ることを確かめる
   - 更新が残っていたらこの項の手順 6・7 を繰り返す。進行中・失敗の表示や、結果を判定できない場合は次へ進まない
   - 更新で窓が閉じた場合は、この項の手順 1 で通常の PowerShell を開き直してからこの項の手順 5〜7 で確認する
   - **次の手順は、Store の更新がすべて終わってから貼る**

### 貼り付けの設定

1. 今の窓だけ、Ctrl+Enter を「行を足す」にする。

   ```powershell
   Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine
   ```

   - 何も出なければよい
   - この窓を閉じるまで効く

1. 管理者ではないことと、今の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $sm = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' -ErrorAction SilentlyContinue).'Scancode Map'
   [pscustomobject]@{
     PowerShell    = $PSVersionTable.PSVersion.ToString()
     Admin         = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Winget        = (Get-Command winget -ErrorAction SilentlyContinue).Source
     Scoop         = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git           = (Get-Command git -ErrorAction SilentlyContinue).Source
     ClassicMenu   = Test-Path -LiteralPath 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
     ScancodeMap   = if ($sm) { ($sm | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' } else { '' }
     Profile       = $PROFILE
     ProfileExists = Test-Path -LiteralPath $PROFILE
   } | Format-List
   Get-ExecutionPolicy -List | Format-Table -AutoSize
   '実行ポリシー: {0}' -f (Get-ExecutionPolicy)
   ```

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`7.…` か `True` なら、窓を閉じて[Microsoft Store の更新](#microsoft-store-の更新)の手順 1 から
   - `Winget` に `…\WindowsApps\winget.exe` の場所が出ればよい。空なら、[Microsoft Store の更新](#microsoft-store-の更新)の手順 2〜7 でアプリ インストーラーの登録と更新を確かめてから
   - `ScancodeMap` が空でなければ、キーの割り当てがもうある。その値を控える（[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 4 は、違う値があれば止まる）
   - 最後の表の `CurrentUser` の値を控える（[ロールバックの「アプリと貼り付けの設定を外す」](extra/windows-setup.md#アプリと貼り付けの設定を外す)の手順 7 で使う。何も設定していなければ `Undefined`）
   - `Scoop` に場所が出たら、scoop はもう入っている。[アプリを入れる](#アプリを入れる)の手順 1・2 は飛ばす

1. スクリプトの実行ポリシーを RemoteSigned にする。

   ```powershell
   if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ExecutionPolicy
   ```

   - `RemoteSigned`（もとから `Unrestricted` か `Bypass` だった PC では、その値）が出ればよい
   - 「より限定的なスコープで定義されたポリシーによって上書きされます」の旨のエラーが出て、ほかの値が出たら、グループ ポリシー（`MachinePolicy` か `UserPolicy`）で決められている。その PC では、scoop もこの項の手順 4 のプロファイルも使えない（ほかの手順書のブロックは、conhost の窓でも Ctrl+V で貼る）

1. プロファイルに、この項の手順 1 と同じ 1 行を足す。

   ```powershell
   & {
     $line = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-setup.md'
     $old = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-powershell-paste.md'
     if (-not (Test-Path -LiteralPath $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
     $text = Get-Content -LiteralPath $PROFILE -Raw
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($text -and ($text.Contains($line) -or $text.Contains($old))) { "すでにある: $PROFILE" } else {
       if ($text -and -not $text.EndsWith("`n")) { $line = "`r`n" + $line }
       Add-Content -LiteralPath $PROFILE -Value $line
       "足した: $PROFILE"
     }
     Get-Content -LiteralPath $PROFILE
   }
   ```

   - `足した: C:\Users\<WIN_USER>\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` と、足した行が出ればよい（OneDrive でドキュメントをバックアップしていると、`OneDrive` の下のパスになる）
   - プロファイルにほかの行があれば、それも出る
   - 何度貼ってもよい（2 回目からは `すでにある:`）。前の版の手順書（`windows-powershell-paste.md`）で足した行があるときも `すでにある:` で、何も足さない

### アプリを入れる

1. scoop を入れる。

   ```powershell
   Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
   ```

   - 最後に `Scoop was installed successfully!` が出ればよい
   - `Running the installer as administrator is disabled by default` が出たら、管理者の PowerShell に貼っている。閉じて[Microsoft Store の更新](#microsoft-store-の更新)の手順 1 から
   - `Scoop is already installed` が出たら、もう入っている（何も変えずに終わる）。この項の手順 2 へ進む
   - `'C:\Users\<WIN_USER>\scoop' exists and is not empty` が出たら、前に入れた scoop の残り（`persist` など）がある。要らなければ[ロールバックの「アプリと貼り付けの設定を外す」](extra/windows-setup.md#アプリと貼り付けの設定を外す)の手順 5 で消してから貼り直す

1. scoop が入ったことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop --version
   scoop bucket list
   [Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ -like '*\scoop\shims' }
   ```

   - `Current Scoop version:` の次に版と公開日が出ればよい
   - `scoop bucket list` に `main` の行が出る
   - 最後に `C:\Users\<WIN_USER>\scoop\shims` が出る

1. UniGet UI（winget）と、その scoop の検索に使う scoop-search を入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop install scoop-search
   winget install --exact --id Devolutions.UniGetUI --source winget --scope user --accept-source-agreements --accept-package-agreements
   winget list --exact --id Devolutions.UniGetUI --source winget
   ```

   - `scoop install scoop-search` の最後に `'scoop-search' (2.1.0) was installed successfully!` の形の行が出る
   - 初回に Visual C++ ランタイムなどの依存関係を入れる際は、管理者の確認（UAC）が出ることがある。製品名と発行元を確かめて許可する（Visual C++ ランタイムの発行元は Microsoft Corporation）
   - 最後の表に `UniGetUI` と `Devolutions.UniGetUI` の行が出ればよい

1. PowerToys を、自分のユーザーに入れる。

   ```powershell
   winget install --exact --id Microsoft.PowerToys --source winget --scope user --accept-source-agreements --accept-package-agreements
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id Microsoft.PowerToys --source winget
   ```

   - 最後の表に `PowerToys` と `Microsoft.PowerToys` の行が出ればよい
   - 管理者の確認（UAC）は出ないはず

1. PowerShell 7 を、自分のユーザーに入れる。

   ```powershell
   winget install --exact --id Microsoft.PowerShell --source winget --accept-source-agreements --accept-package-agreements
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id Microsoft.PowerShell --source winget
   ```

   - 最後の表に `PowerShell` と `Microsoft.PowerShell` の行が出ればよい
   - 管理者の確認（UAC）は出ないはず
   - この文書とほかの手順書のブロックは、引き続き Windows PowerShell 5.1 に貼る

### 表示と入力

1. エクスプローラーで、拡張子と隠しファイルを表示し、「PC」で開き、最近使ったものを出さないようにする。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   $exp = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
   Set-ItemProperty -Path $adv -Name HideFileExt -Type DWord -Value 0
   Set-ItemProperty -Path $adv -Name Hidden -Type DWord -Value 1
   Set-ItemProperty -Path $adv -Name LaunchTo -Type DWord -Value 1
   Set-ItemProperty -Path $adv -Name Start_TrackDocs -Type DWord -Value 0
   Set-ItemProperty -Path $exp -Name ShowRecent -Type DWord -Value 0
   Set-ItemProperty -Path $exp -Name ShowFrequent -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $adv | Format-List HideFileExt, Hidden, LaunchTo, Start_TrackDocs
   Get-ItemProperty -Path $exp | Format-List ShowRecent, ShowFrequent
   ```

   - `HideFileExt : 0`・`Hidden : 1`・`LaunchTo : 1`・`Start_TrackDocs : 0`・`ShowRecent : 0`・`ShowFrequent : 0` が出ればよい
   - 開いているエクスプローラーの窓には、開き直すか[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後に効く

1. 自分のユーザーで、旧形式のコンテキストメニューを出すようにする。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   reg.exe add 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /f /ve
   reg.exe query 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /ve
   ```

   - `reg.exe add` が成功の 1 行を出し、`reg.exe query` に `(既定)`（英語の表示では `(Default)`）と `REG_SZ` の行が出ればよい（値は空）
   - エクスプローラーに効くのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後

1. スタートと設定の、おすすめ・提案・ヒントを切る。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
   $upe = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement'
   Set-ItemProperty -Path $adv -Name Start_IrisRecommendations -Type DWord -Value 0
   Set-ItemProperty -Path $adv -Name Start_AccountNotifications -Type DWord -Value 0
   foreach ($n in 'SubscribedContent-338393Enabled', 'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled', 'SubscribedContent-338389Enabled', 'SubscribedContent-310093Enabled', 'SubscribedContent-338388Enabled', 'SystemPaneSuggestionsEnabled', 'SilentInstalledAppsEnabled') { Set-ItemProperty -Path $cdm -Name $n -Type DWord -Value 0 }
   if (-not (Test-Path -LiteralPath $upe)) { New-Item -Path $upe | Out-Null }
   Set-ItemProperty -Path $upe -Name ScoobeSystemSettingEnabled -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $adv | Format-List Start_IrisRecommendations, Start_AccountNotifications
   Get-ItemProperty -Path $cdm | Format-List SubscribedContent-338393Enabled, SubscribedContent-353694Enabled, SubscribedContent-353696Enabled, SubscribedContent-338389Enabled, SubscribedContent-310093Enabled, SubscribedContent-338388Enabled, SystemPaneSuggestionsEnabled, SilentInstalledAppsEnabled
   Get-ItemProperty -Path $upe | Format-List ScoobeSystemSettingEnabled
   ```

   - 並んだ値がすべて `0` ならよい
   - [自動起動と標準アプリ](#自動起動と標準アプリ)の手順 2 より前に貼る

1. タスクバーを左に寄せ、タスク ビューと検索のボタンを消し、時計に秒を出す。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   Set-ItemProperty -Path $adv -Name TaskbarAl -Type DWord -Value 0
   Set-ItemProperty -Path $adv -Name ShowTaskViewButton -Type DWord -Value 0
   Set-ItemProperty -Path $adv -Name ShowSecondsInSystemClock -Type DWord -Value 1
   Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name SearchboxTaskbarMode -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $adv | Format-List TaskbarAl, ShowTaskViewButton, ShowSecondsInSystemClock
   Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' | Format-List SearchboxTaskbarMode
   ```

   - `TaskbarAl : 0`・`ShowTaskViewButton : 0`・`ShowSecondsInSystemClock : 1`・`SearchboxTaskbarMode : 0` が出ればよい
   - タスクバーには、すぐか、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後に効く

1. ダークモードにする。

   ```powershell
   $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
   Set-ItemProperty -Path $p -Name AppsUseLightTheme -Type DWord -Value 0
   Set-ItemProperty -Path $p -Name SystemUsesLightTheme -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $p | Format-List AppsUseLightTheme, SystemUsesLightTheme
   ```

   - `AppsUseLightTheme : 0` と `SystemUsesLightTheme : 0` が出ればよい
   - 動いているアプリとタスクバーには、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後に効く

1. 既定の端末を Windows Terminal にする。

   ```powershell
   $p = 'HKCU:\Console\%%Startup'
   if (-not (Test-Path -LiteralPath $p)) { New-Item -Path $p | Out-Null }
   Set-ItemProperty -LiteralPath $p -Name DelegationConsole -Type String -Value '{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}'
   Set-ItemProperty -LiteralPath $p -Name DelegationTerminal -Type String -Value '{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}'
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -LiteralPath $p | Format-List DelegationConsole, DelegationTerminal
   ```

   - `DelegationConsole : {2EACA947-…}` と `DelegationTerminal : {E12CFF52-…}` が出ればよい
   - 次に起動したコンソールのアプリから効く
   - **注意**: 管理者として開いた PowerShell は、この設定でも conhost の窓で開く（Windows Terminal の側の制限）。[PC 全体の設定](#pc-全体の設定)の手順 1 の管理者の窓に右クリックで貼れるのは、[貼り付けの設定](#貼り付けの設定)の手順 1〜4 の設定による

1. Microsoft IME の設定を開き、Ctrl+Space で IME をオン・オフするようにする。

   ```powershell
   Start-Process 'ms-settings:regionlanguage-jpnime'
   ```

   - 設定の Microsoft IME の画面が開く。「キーとタッチのカスタマイズ」を開き、「キーの割り当て」をオンにして、「Ctrl + Space」を「IME-オン/オフ」にする
   - 「以前のバージョンの Microsoft IME を使う」がオンだと、この項目は出ない
   - 効くのは、次に IME を使う窓から（確かめるのは[再起動の後に確かめる](#再起動の後に確かめる)の手順 1）
   - **次の手順は、設定を閉じてから PowerShell に貼る**

### 自動起動と標準アプリ

1. 自動で起動するアプリのうち、OneDrive・Edge・Teams を止める。

   ```powershell
   & {
     $run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
     $ok = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
     if (-not (Test-Path -LiteralPath $ok)) { New-Item -Path $ok -Force | Out-Null }
     $names = (Get-Item -LiteralPath $run).Property | Where-Object { $_ -eq 'OneDrive' -or $_ -eq 'OneDriveSetup' -or $_ -like 'MicrosoftEdgeAutoLaunch_*' }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($n in $names) {
       Set-ItemProperty -LiteralPath $ok -Name $n -Type Binary -Value ([byte[]](3, 0, 0, 0) + [BitConverter]::GetBytes((Get-Date).ToFileTime()))
       "止めた: $n"
     }
     $teams = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe\TeamsTfwStartupTask'
     if (Test-Path -LiteralPath $teams) { Set-ItemProperty -LiteralPath $teams -Name State -Type DWord -Value 1; '止めた: Teams' }
     (Get-Item -LiteralPath $run).Property | ForEach-Object { $b = (Get-ItemProperty -LiteralPath $ok -ErrorAction SilentlyContinue).$_; '{0}: {1}' -f $_, $(if ($b -and $b[0] -ne 2) { '止めている' } else { '起動する' }) }
   }
   ```

   - `止めた: OneDrive` などと、`Run` にあるアプリごとに `止めている` か `起動する` が出ればよい
   - 無いものは何もしない（Edge の行は、Edge の設定によっては無い）
   - `WingetUI: 起動する` は UniGet UI。止めるなら、タスク マネージャーの「スタートアップ アプリ」で無効にする
   - 効くのは、次のサインインから

1. 要らない標準アプリを、自分のユーザーから外す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($n in 'Clipchamp.Clipchamp', 'Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.Todos', 'Microsoft.WindowsFeedbackHub', 'Microsoft.GetHelp', 'Microsoft.OutlookForWindows', 'MSTeams', 'Microsoft.PowerAutomateDesktop') {
     $p = Get-AppxPackage -Name $n
     if ($p) { $p | Remove-AppxPackage; "外した: $n" } else { "無い: $n" }
   }
   ```

   - 11 個のアプリごとに `外した:` か `無い:` が出ればよい
   - 赤い字のエラーが出たアプリは、外せなかった（動いていれば閉じて貼り直す）
   - 機能の更新（Windows の大きな更新）の後に、戻ってくることがある。そのときはこの手順を貼り直す

1. ウィジェット（Windows Web Experience Pack）を外す。

   ```powershell
   $p = Get-AppxPackage -Name MicrosoftWindows.Client.WebExperience
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if ($p) { $p | Remove-AppxPackage; '外した: MicrosoftWindows.Client.WebExperience' } else { '無い: MicrosoftWindows.Client.WebExperience' }
   ```

   - `外した:` か `無い:` が出ればよい
   - タスクバーのウィジェットのボタンと、設定のウィジェットの切り替えが消える（[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後に確かめる）

### HackGen Console NF

1. HackGen がまだ入っていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Item -LiteralPath 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' -ErrorAction SilentlyContinue | ForEach-Object { $_.Property -like 'HackGen*' }
   Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts", "$env:WINDIR\Fonts" -Filter 'HackGen*' -ErrorAction SilentlyContinue | Format-Table Name, DirectoryName
   ```

   - どちらも何も出なければ、入っていない
   - `C:\Windows\Fonts` のファイルが出たら、PC 全体に入っている（ほかの方法で入れたもの）。この項は要らない

1. HackGen Console NF の zip を取り、sha256 を確かめて自分のユーザーのフォントに入れる。

   ```powershell
   & {
     $ver = '2.10.0'
     $sha256 = 'F8ABD483D5EDFAD88A78ED511978F43C83B43C48E364AA29EBE4A68217474428'
     $fonts = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
     $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
     $tmp = "$env:TEMP\hackgen-setup"
     $zip = "$tmp\HackGen_NF_v$ver.zip"
     Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & "$env:WINDIR\System32\curl.exe" -fsSL -o $zip "https://github.com/yuru7/HackGen/releases/download/v$ver/HackGen_NF_v$ver.zip"
     if ($LASTEXITCODE -ne 0) { Write-Error "中断: HackGen_NF_v$ver.zip を取れない"; return }
     if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $sha256) { Write-Error "中断: HackGen_NF_v$ver.zip の sha256 が一致しない"; return }
     Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
     $ttf = @(Get-ChildItem -LiteralPath "$tmp\HackGen_NF_v$ver" -Filter '*.ttf')
     if ($ttf.Count -ne 4) { Write-Error "中断: zip の中の ttf が 4 つではない（$($ttf.Count)）"; return }
     New-Item -ItemType Directory -Force -Path $fonts | Out-Null
     icacls.exe $fonts /grant '*S-1-15-2-1:(OI)(CI)(RX)' '*S-1-15-2-2:(OI)(CI)(RX)' | Out-Null
     if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key | Out-Null }
     foreach ($f in $ttf) {
       $dst = Join-Path $fonts $f.Name
       if (-not (Test-Path -LiteralPath $dst) -or (Get-FileHash -LiteralPath $dst).Hash -ne (Get-FileHash -LiteralPath $f.FullName).Hash) {
         try { Copy-Item -LiteralPath $f.FullName -Destination $dst -Force -ErrorAction Stop } catch { Write-Error "中断: $($f.Name) を置けない（$($_.Exception.Message)）"; return }
       }
       New-ItemProperty -Path $key -Name "$($f.BaseName) (TrueType)" -Value $dst -PropertyType String -Force | Out-Null
     }
     Remove-Item -LiteralPath $tmp -Recurse -Force
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ItemProperty -LiteralPath $key | Select-Object -Property 'HackGen*' | Format-List
   }
   ```

   - `HackGen35ConsoleNF-Bold (TrueType) : C:\Users\<WIN_USER>\AppData\Local\Microsoft\Windows\Fonts\HackGen35ConsoleNF-Bold.ttf` の形の行が 4 つ出ればよい
   - `中断:` で始まるエラーが出たら、そこで止まっている
   - 何度貼ってもよい
   - アプリで使えるのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後（確かめるのは[再起動の後に確かめる](#再起動の後に確かめる)の手順 5）

### PC 全体の設定

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く。UAC の確認が出たら「はい」
   - [Microsoft Store の更新](#microsoft-store-の更新)の手順 1 の PowerShell は閉じてよい（再起動の後は、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 で開き直す）
   - 開いたときに、プロファイルを読めないという赤い字のエラーが出たら、実行ポリシーが `Restricted` のまま。[貼り付けの設定](#貼り付けの設定)の手順 3 を、この窓で貼り直す

1. 変数を設定する（PC の名前を変えるなら、`PC_NAME` に値を入れる）。

   ```powershell
   $PC_NAME = ''   # この PC の新しい名前（15 文字まで。英字・数字・ハイフン）。<HOSTNAME>
   ```

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # ほかの PC とつながる LAN の接続（自動）。<LAN_IF>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'PC_NAME = {0}' -f $PC_NAME
   'LAN_IF  = {0}' -f $LAN_IF
   ```

   - 最後に値を読み戻して確かめる
   - 名前を変えないなら、空のままにしてこの項の手順 5 を飛ばす
   - `LAN_IF` は、インターネットにつながっている接続の名前（`イーサネット`、`Wi-Fi` など）。ほかの PC とつながる接続と違えば、`$LAN_IF = 'Wi-Fi'` のように直す
   - 変数はその PowerShell の中だけで有効。**新しい PowerShell を開いたら**、この項の手順 2 のブロックを貼り直してから先へ進む

1. 管理者であることと、プロファイルの行が効いていることと、今の値を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $cv = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
   [pscustomobject]@{
     Admin            = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     CtrlEnter        = (Get-PSReadLineKeyHandler -Bound | Where-Object Key -eq 'Ctrl+Enter').Function
     Edition          = $cv.EditionID
     Version          = '{0}（{1}.{2}）' -f $cv.DisplayVersion, $cv.CurrentBuild, $cv.UBR
     ComputerName     = $env:COMPUTERNAME
     LanCategory      = if ($LAN_IF) { (Get-NetConnectionProfile -InterfaceAlias $LAN_IF).NetworkCategory } else { '' }
     RemoteDesktop    = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
     RemoteAssistance = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' -ErrorAction SilentlyContinue).fAllowToGetHelp
     HelloOnly        = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' -ErrorAction SilentlyContinue).DevicePasswordLessBuildVersion
     Keyboard         = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters' -ErrorAction SilentlyContinue).'LayerDriver JPN'
     Sudo             = (Get-Command sudo -ErrorAction SilentlyContinue).Source
     Hypervisor       = (Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
   } | Format-List
   Get-DODownloadMode
   ```

   - `Admin : True` と `CtrlEnter : AddLine` が出ればよい
   - `Admin` が `False` なら、管理者ではない窓に貼っている。この項の手順 1 から
   - `CtrlEnter` が `InsertLineAbove` なら、この窓はプロファイルを読んでいない。[貼り付けの設定](#貼り付けの設定)の手順 1・3・4 をこの窓で貼り直してから（同じ項の手順 1 を先に貼ると、同じ項の手順 3・4 を右クリックで貼れる）、窓を開き直してこの項の手順 2 から
   - 次の値を控える（[ロールバック](extra/windows-setup.md#ロールバック)で、元に戻すかを決めるのに使う）
     - `ComputerName`（PC の名前。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 9）と `LanCategory`（LAN の種類。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 5）
     - `RemoteDesktop`（1 なら無効、0 ならもう有効。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 4）と `RemoteAssistance`（1 なら有効、0 なら無効。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 3）
     - `HelloOnly`（2 ならオン、0 ならオフ。ロールバックの「サインイン・検索・キーボードを戻す」の手順 5）と `Keyboard`（`kbd106.dll` なら JIS 配列。ロールバックの「サインイン・検索・キーボードを戻す」の手順 9）
     - 最後の行の配信の最適化のモード（`Lan` が Windows の既定。ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 1）
   - `Edition` が `Core` で始まる（Home）なら、[ネットワークとリモート](#ネットワークとリモート)の手順 2 は飛ばす

1. 複数行のブロックをコピーボタンでコピーして右クリックで貼り、元の順に動くことを確かめる。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     '1 行目'
     '2 行目'
     '3 行目'
   }
   ```

   - このブロックを GitHub のコピーボタンでコピーし、この項の手順 1 の窓の中で右クリックして貼る
   - 最後の `}` の行で止まるので、Enter を押す
   - `1 行目`・`2 行目`・`3 行目` の順に出ればよい

1. PC の名前を変えるときだけ、名前を変える（効くのは再起動の後）。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $PC_NAME) {
     Write-Error '中断: 「PC 全体の設定」の手順 2 の $PC_NAME が空'
   } elseif ($PC_NAME -notmatch '^[A-Za-z0-9]([A-Za-z0-9-]{0,13}[A-Za-z0-9])?$' -or $PC_NAME -match '^[0-9]+$') {
     Write-Error "中断: 使えない名前（15 文字まで。英字・数字・ハイフンで、先頭と末尾は英数字。数字だけは不可）: $PC_NAME"
   } elseif ($PC_NAME -eq $env:COMPUTERNAME) {
     "すでにこの名前: $PC_NAME"
   } else {
     Rename-Computer -NewName $PC_NAME
     "再起動の後に $PC_NAME になる"
   }
   ```

   - 再起動を求める旨の警告と、`再起動の後に <HOSTNAME> になる` が出ればよい
   - 何度貼ってもよい（2 回目からは `すでにこの名前:`。再起動の前は、まだ古い名前と比べる）
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後
   - 名前を変えないなら（この項の手順 2 の `PC_NAME` が空なら）、この手順は飛ばす

1. 長いパス・開発者モード・sudo（今の窓で動く形）を有効にする。

   ```powershell
   $dev = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -Type DWord -Value 1
   if (-not (Test-Path -LiteralPath $dev)) { New-Item -Path $dev | Out-Null }
   Set-ItemProperty -Path $dev -Name AllowDevelopmentWithoutDevLicense -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (Get-Command sudo -ErrorAction SilentlyContinue) { sudo config --enable normal } else { 'sudo が無い（24H2 より前の Windows）' }
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' | Format-List LongPathsEnabled
   Get-ItemProperty -Path $dev | Format-List AllowDevelopmentWithoutDevLicense
   ```

   - `LongPathsEnabled : 1` と `AllowDevelopmentWithoutDevLicense : 1` が出ればよい
   - sudo は、今の窓で動く形（インライン）になった旨を表示する（表示言語は環境による）
   - **注意**: インラインの sudo は、同じ窓のほかの（管理者でない）プロセスから、管理者のコマンドに入力を送れる形（Microsoft の文書。[検証記録](verification/windows-setup.md)・[参考資料](reference/windows-setup.md)）

1. 電源接続中の眠りと蓋の動作を止め、電源に関係なく休止状態と放置後のロックを切る。

   ```powershell
   powercfg /change standby-timeout-ac 0
   powercfg /hibernate off
   powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
   powercfg /setacvalueindex SCHEME_CURRENT SUB_NONE CONSOLELOCK 0
   powercfg /setactive SCHEME_CURRENT
   Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name DelayLockInterval -Type DWord -Value 0xFFFFFFFF
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($s in 'SUB_SLEEP STANDBYIDLE', 'SUB_BUTTONS LIDACTION', 'SUB_NONE CONSOLELOCK') { '{0}: {1}' -f $s, ((powercfg /qh SCHEME_CURRENT $s.Split(' ')) | Select-String -Pattern 'AC' | Select-Object -Last 1) }
   'HibernateEnabled: {0}' -f (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power').HibernateEnabled
   ```

   - 3 つの行の AC の値が `0x00000000` で、`HibernateEnabled: 0` が出ればよい（`powercfg` の表示は日本語）
   - **注意**: PC の前にいる人は、このユーザーとしてそのまま使える（リードの `[!WARNING]`）

1. LAN のアダプターを、電力の節約のために止めないようにする。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '「PC 全体の設定」の手順 2 の $LAN_IF が空'
   } else {
     $pm = Get-NetAdapterPowerManagement -Name $LAN_IF
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($pm.AllowComputerToTurnOffDevice -eq 'Unsupported') { "このアダプターは対象外: $LAN_IF" } else {
       $pm.AllowComputerToTurnOffDevice = 'Disabled'
       $pm | Set-NetAdapterPowerManagement -NoRestart
     }
     Get-NetAdapterPowerManagement -Name $LAN_IF | Format-List Name, AllowComputerToTurnOffDevice, WakeOnMagicPacket
   }
   ```

   - `AllowComputerToTurnOffDevice : Disabled` が出ればよい
   - `このアダプターは対象外:` なら、このアダプターには設定が無い（何もしない）
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後

### ネットワークとリモート

1. LAN の接続をプライベートにする。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '「PC 全体の設定」の手順 2 の $LAN_IF が空'
   } else {
     Set-NetConnectionProfile -InterfaceAlias $LAN_IF -NetworkCategory Private
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
   }
   ```

   - `<LAN_IF>  Private` が出ればよい
   - **注意**: プライベート向けのほかの許可の規則（ネットワーク探索など）も、この LAN で効くようになる

1. Pro 以上のときだけ、リモート デスクトップを有効にし、受け付けるのをプライベートの LAN に絞る。

   ```powershell
   $ed = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
   if ($ed -like 'Core*') { Write-Error "中断: Home（$ed）は、リモート デスクトップでつながれる側になれない" } else {
     Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Type DWord -Value 0
     Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Type DWord -Value 1
     Set-NetFirewallRule -Group '@FirewallAPI.dll,-28752' -Enabled True -Profile Private
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetFirewallRule -Group '@FirewallAPI.dll,-28752' | Format-Table Name, Enabled, Profile, Direction, Action
   }
   ```

   - `RemoteDesktop-UserMode-In-TCP` などの行が `True  Private  Inbound  Allow` で出ればよい
   - [PC 全体の設定](#pc-全体の設定)の手順 3 の `Edition` が `Core` で始まる（Home）なら、この手順は飛ばす（貼っても `中断:` で止まる）

1. リモート アシスタンスを切る。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' -Name fAllowToGetHelp -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Set-NetFirewallRule -Group '@FirewallAPI.dll,-33002' -Enabled False
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' | Format-List fAllowToGetHelp
   Get-NetFirewallRule -Group '@FirewallAPI.dll,-33002' | Format-Table Name, Enabled, Profile
   ```

   - `fAllowToGetHelp : 0` と、リモート アシスタンスの規則が `False` で並べばよい
   - `Set-NetFirewallRule` が規則が見つからない旨のエラーを出したら、グループの ID が違う

1. プライベートの LAN からの ping（ICMP のエコー要求）に応える規則を作る。

   ```powershell
   $g = 'Ping (setup-notes)'
   Remove-NetFirewallRule -Group $g -ErrorAction SilentlyContinue
   New-NetFirewallRule -Name 'Ping-ICMPv4-In-setup-notes' -DisplayName 'Ping (ICMPv4 エコー要求)' -Group $g -Direction Inbound -Action Allow -Profile Private -Protocol ICMPv4 -IcmpType 8 | Out-Null
   New-NetFirewallRule -Name 'Ping-ICMPv6-In-setup-notes' -DisplayName 'Ping (ICMPv6 エコー要求)' -Group $g -Direction Inbound -Action Allow -Profile Private -Protocol ICMPv6 -IcmpType 128 | Out-Null
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Group $g | Format-Table Name, Enabled, Profile, Direction, Action
   ```

   - 2 つの規則が `True  Private  Inbound  Allow` で出ればよい
   - 何度貼ってもよい
   - LAN の別の PC から、この PC の IP アドレスへ ping が通るようになる

1. 配信の最適化を、LAN の PC とだけ共有するようにする。

   ```powershell
   Set-DODownloadMode -DownloadMode Lan
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-DODownloadMode
   ```

   - `Lan` が出ればよい

### OpenSSH サーバー

1. OpenSSH サーバーの機能を入れる。

   ```powershell
   if ($PSVersionTable.PSEdition -ne 'Desktop') {
     Write-Error 'Windows PowerShell（5.1）で貼る。PowerShell 7 では Add-WindowsCapability が失敗する'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
     Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Format-List Name, State
   }
   ```

   - 数分かかる
   - `RestartNeeded : False` と `State : Installed` が出ればよい
   - 既に入っていれば、すぐに `State : Installed` が出る

1. sshd を自動で起動するようにして起動し、待ち受けを確かめる。

   ```powershell
   Set-Service -Name sshd -StartupType Automatic
   Start-Service -Name sshd
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Service -Name sshd | Format-Table Name, Status, StartType
   Get-NetTCPConnection -State Listen -LocalPort 22 | Format-Table LocalAddress, LocalPort, OwningProcess
   ```

   - `sshd  Running  Automatic` が出る
   - 22 番で `0.0.0.0` と `::` の 2 行が出ればよい

1. LAN の接続がプライベートなことと、sshd の受信の規則を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $LAN_IF) {
     Write-Error '「PC 全体の設定」の手順 2 の $LAN_IF が空'
   } elseif ((Get-NetConnectionProfile -InterfaceAlias $LAN_IF).NetworkCategory -ne 'Private') {
     Write-Error '中断: LAN の接続がプライベートではない（「ネットワークとリモート」の手順 1 でプライベートにする）'
   } else {
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
     Get-NetFirewallRule -Name OpenSSH-Server-In-TCP | Format-Table Name, Enabled, Profile, Direction, Action
   }
   ```

   - `<LAN_IF>  Private` と、`OpenSSH-Server-In-TCP  True  Private  Inbound  Allow` が出ればよい
   - `中断:` が出たら、[ネットワークとリモート](#ネットワークとリモート)の手順 1 でプライベートにしてから、この手順を貼り直す（[PC 全体の設定](#pc-全体の設定)の手順 2 の変数はそのまま使える）
   - **注意**: プライベートの LAN では、プライベート向けのほかの許可の規則（ネットワーク探索など）も効く（[選択した方針](verification/windows-setup.md#openssh-サーバー-選択した方針)）

1. パスワード認証を有効にし、設定を検査してから sshd を再起動する。

   ```powershell
   $c = "$env:ProgramData\ssh\sshd_config"
   (Get-Content $c) -replace '^#?PasswordAuthentication .*', 'PasswordAuthentication yes' | Set-Content $c -Encoding ascii
   & "$env:WINDIR\System32\OpenSSH\sshd.exe" -t
   if ($LASTEXITCODE -eq 0) { Restart-Service -Name sshd } else { Write-Error 'sshd_config に誤りがある（sshd は再起動していない）' }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Select-String -Path $c -Pattern '^PasswordAuthentication', '^Match'
   ```

   - `…sshd_config:51:PasswordAuthentication yes` と `…sshd_config:87:Match Group administrators` が出ればよい

1. 接続先と、ホスト鍵の指紋を表示する。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   '{0}@{1}' -f $env:USERNAME, (Get-NetIPAddress -InterfaceAlias $LAN_IF -AddressFamily IPv4).IPAddress
   & "$env:WINDIR\System32\OpenSSH\ssh-keygen.exe" -lf "$env:ProgramData\ssh\ssh_host_ed25519_key.pub"
   ```

   - 1 行目の `<WIN_USER>@<WIN_HOST>` を控える（再起動の後の[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 3 で使う）
   - 2 行目の `256 SHA256:<指紋> system@<HOSTNAME> (ED25519)` も控え、[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 4 の初回の接続で照合する

### サインイン・検索・キーボード

1. 「Windows Hello サインインのみを許可する」を切る。

   ```powershell
   $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -Path $k -Name DevicePasswordLessBuildVersion -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k | Format-List DevicePasswordLessBuildVersion
   ```

   - `DevicePasswordLessBuildVersion : 0` が出ればよい
   - サインインの画面で、PIN のほかにパスワードも選べるようになる

1. スタートの検索で、Web（Bing）の結果を出さないようにする。

   ```powershell
   $k = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -Path $k -Name DisableSearchBoxSuggestions -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k | Format-List DisableSearchBoxSuggestions
   ```

   - `DisableSearchBoxSuggestions : 1` が出ればよい
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後

1. デスクトップの Edge と UniGet UI のショートカットを消し、Edge が作り直したら消すようにする。

   ```powershell
   $k = 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -Path $k -Name RemoveDesktopShortcutDefault -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($f in (Join-Path ([Environment]::GetFolderPath('CommonDesktopDirectory')) 'Microsoft Edge.lnk'), (Join-Path ([Environment]::GetFolderPath('Desktop')) 'UniGetUI.lnk')) {
     if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f; "消した: $f" } else { "無い: $f" }
   }
   Get-ItemProperty -Path $k | Format-List RemoveDesktopShortcutDefault
   ```

   - 2 つのファイルについて `消した:` か `無い:` と、`RemoveDesktopShortcutDefault : 1` が出ればよい
   - ほかのショートカットは消さない。要らなければ手で消す

1. Caps Lock を左 Ctrl にする Scancode Map を書く。

   ```powershell
   & {
     $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
     $want = '00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00'
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない（「PC 全体の設定」の手順 1 から）'; return }
     $now = (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue).'Scancode Map'
     $nowHex = if ($now) { ($now | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' } else { '' }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($nowHex -and $nowHex -ne $want) { Write-Error "中断: 別の Scancode Map がある（$nowHex）"; return }
     if (-not $nowHex) { New-ItemProperty -Path $key -Name 'Scancode Map' -PropertyType Binary -Value ([byte[]]($want -split ' ' | ForEach-Object { [Convert]::ToByte($_, 16) })) | Out-Null }
     'Scancode Map = {0}' -f ((((Get-ItemProperty -Path $key).'Scancode Map') | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')
   }
   ```

   - `Scancode Map = 00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00` が出ればよい
   - 同じ値がもうあれば、何も書かずに同じ行を出す（何度貼ってもよい）
   - `中断: 別の Scancode Map がある` が出たら、ほかのキーの割り当てがある（両方を使うなら、その値を手で直す。数を 1 つ増やし、終わりの印の前に `1D 00 3A 00` を足す）
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後

1. AlmaLinux とデュアル ブートし、AlmaLinux の時計を UTC にしているときだけ、Windows も UTC にする。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name RealTimeIsUniversal -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' | Format-List RealTimeIsUniversal
   ```

   - `RealTimeIsUniversal : 1` が出ればよい
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後。時刻がずれていたら、設定の「時刻と言語」→「日付と時刻」の「今すぐ同期」で合わせ直す
   - AlmaLinux の `timedatectl` の `RTC in local TZ:` が `yes`（`/etc/adjtime` の 3 行目が `LOCAL`）なら、この手順は飛ばす
   - デュアル ブートしない PC でも、この手順は飛ばす

1. US 配列（101/102 キー）のキーボードを使うときだけ、キーボードの種類を変える。

   ```powershell
   $k = 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters'
   Set-ItemProperty -Path $k -Name 'LayerDriver JPN' -Type String -Value 'kbd101.dll'
   Set-ItemProperty -Path $k -Name OverrideKeyboardIdentifier -Type String -Value 'PCAT_101KEY'
   Set-ItemProperty -Path $k -Name OverrideKeyboardType -Type DWord -Value 7
   Set-ItemProperty -Path $k -Name OverrideKeyboardSubtype -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k | Format-List 'LayerDriver JPN', OverrideKeyboardIdentifier, OverrideKeyboardType, OverrideKeyboardSubtype
   ```

   - `LayerDriver JPN : kbd101.dll`・`OverrideKeyboardIdentifier : PCAT_101KEY`・`OverrideKeyboardType : 7`・`OverrideKeyboardSubtype : 0` が出ればよい
   - JIS 配列（日本語の 106/109 キー）のキーボードなら、この手順は飛ばす
   - 効くのは、[WSL と再起動](#wsl-と再起動)の手順 2 の再起動の後。日本語の入力の切り替えは、[表示と入力](#表示と入力)の手順 7 の Ctrl+Space（または Alt+`）で行う

### Git for Windows

1. Git for Windows がまだ入っていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Command git -All -ErrorAction SilentlyContinue | Format-Table Source
   Test-Path 'C:\Program Files\Git\bin\bash.exe'
   winget list --exact --id Git.Git --accept-source-agreements --source winget
   ```

   - 1 行目は何も出さず、`False` と、`入力条件に一致するインストール済みのパッケージが見つかりませんでした。`（英語の Windows では `No installed package found matching input criteria.`）が出ればよい
   - `False` で、1 行目に `…\AppData\Local\Programs\Git\cmd\git.exe` が出たら、管理者の権限無しで入れた Git for Windows がある。それを外してから始める
   - 1 行目に scoop の `…\scoop\shims\git.exe` だけが出たら、そのまま進めてよい
   - `winget` が見つからないというエラーになったら、Microsoft Store で「アプリ インストーラー」を更新してから始める
   - `True` なら、Git for Windows はもう `C:\Program Files\Git` に入っている。この項の手順 2 は飛ばす（新しい版にするなら[Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)の手順 2）

1. まだ入っていなければ、winget で Git for Windows を PC 全体（`C:\Program Files\Git`）に入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget install --exact --id Git.Git --source winget --scope machine --accept-source-agreements --accept-package-agreements
   winget list --exact --id Git.Git --source winget
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と出て、`winget list` に `Git.Git` の行が出ればよい
   - インストーラの画面は出ない（進み具合の小さな窓が出て、終わると消える）
   - この窓では `git` は見つからない（PATH は、[WSL と再起動](#wsl-と再起動)の再起動の後に開く窓から効く。確かめるのは[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 1）

### Firefox

1. Firefox がまだ入っていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $arp = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
   Get-ItemProperty -Path $arp -ErrorAction SilentlyContinue | Where-Object DisplayName -like 'Mozilla Firefox*' | Format-Table DisplayName, DisplayVersion, InstallLocation
   Get-AppxPackage -Name 'Mozilla.MozillaFirefox' | Format-Table Name, Version
   ```

   - どちらも何も出なければ、入っていない
   - `Mozilla Firefox (x64 ja)` が `C:\Program Files\Mozilla Firefox` で出たら、この項の手順で入れたもの（か同じもの）。この項の手順 2 はそのまま貼ってよい
   - ほかのもの（`(x64 en-US)` などのほかの言語・`(x86 ja)`・ESR・`%LOCALAPPDATA%` の下・Microsoft Store 版の `Mozilla.MozillaFirefox`）が出たら、設定 →「アプリ」→「インストールされているアプリ」で外してから始める（プロファイルは残る）

1. winget で日本語版の Firefox を PC 全体に入れ、入ったか確かめる。

   ```powershell
   winget install --exact --id Mozilla.Firefox.ja --source winget --scope machine --accept-source-agreements --accept-package-agreements
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id Mozilla.Firefox.ja --source winget
   (Get-Item -LiteralPath "$env:ProgramFiles\Mozilla Firefox\firefox.exe").VersionInfo | Format-List FileName, ProductVersion
   Get-Service -Name MozillaMaintenance | Format-Table Name, Status, StartType
   Get-ScheduledTask -TaskPath '\Mozilla\' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   ```

   - `winget list` に `Mozilla Firefox (x64 ja)  Mozilla.Firefox.ja  157.0` の形の行が出ればよい
   - `FileName` が `C:\Program Files\Mozilla Firefox\firefox.exe` で、`ProductVersion` が同じ版
   - `MozillaMaintenance`（Mozilla Maintenance Service）の行が出る。ふだんは止まっていて、更新のときだけ動く
   - タスクの一覧に `Firefox Default Browser Agent <番号>` が出る
   - `winget` が見つからないと出たら、Microsoft Store で「アプリ インストーラー」を更新してから貼り直す

1. スタートメニューから Firefox を起動し、`about:support` で日本語版の公式のビルドかを確かめる。

   - スタートメニューの「Firefox」から起動する（管理者の PowerShell からは起動しない。Firefox が管理者の権限で動いてしまう）
   - 最初の起動で、Firefox を既定のブラウザーにするかを聞かれることがある。選ぶと Windows の設定が開くので、この項の手順 4 の操作をそこで行ってよい
   - アドレスバーに `about:support` を入れ、「アプリケーション基本情報」を見る
     - 「更新チャンネル」が `release`
     - 「プログラムの実行ファイル」が `C:\Program Files\Mozilla Firefox\firefox.exe`
   - 同じページの「コーデックサポート情報」で、`H264` と `AAC` の「ソフトウェアデコーディング」が「対応」になる
     - 情報が利用できないと出たら、動画を 1 本再生してから開き直す
   - メニューやボタンが日本語で出る

1. Windows の設定で、Firefox を既定のブラウザーにする。

   - 設定（Win+I）→「アプリ」→「既定のアプリ」を開き、「アプリケーションの既定値を設定する」の一覧で「Firefox」を選ぶ（2 つ並んだときは上のもの）
   - 「Firefox を既定のブラウザーに設定する」の横の「既定値に設定」を押す（押すと横にチェックの印が出る）
   - 押した後は、同じ画面の `.htm`・`.html`・`HTTP`・`HTTPS` などの既定が Firefox になる
   - Win+R の「ファイル名を指定して実行」に `https://www.mozilla.org/ja/` を入れて Enter を押し、Firefox で開けばよい
   - Firefox の設定（`about:preferences`）の「既定のブラウザー」の「既定のブラウザーにする」からでもよい（Firefox が自分で既定にできなければ、同じ Windows の設定の画面が開く）
   - 画面の名前が異なる場合は、Windows の既定のアプリの設定から Firefox を選ぶ

### WezTerm

1. 管理者であることと、今の WezTerm と `VCRUNTIME140.dll` があるかを確かめる。

   ```powershell
   $u = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1' -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     Admin     = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Version   = $u.DisplayVersion
     Location  = $u.InstallLocation
     OnPath    = (Get-Command wezterm.exe -All -ErrorAction SilentlyContinue).Source -join ' '
     Running   = (Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue).ProcessName -join ' '
     VCRuntime = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
   } | Format-List
   ```

   - `Admin : True` であること（`False` なら、[PC 全体の設定](#pc-全体の設定)の手順 1 で管理者の窓を開き直し、同じ項の手順 2 を貼り直してから、このブロックを貼る）
   - 初めて入れる PC では、`Version`・`Location`・`OnPath`・`Running` が空
   - `Version` に版が出たら、もう入っている（`20260905-153129-092dcf70` など）。この項の手順 3 で今の nightly に上書きする
     - `Location` は `C:\Program Files\WezTerm\` のはず。違う場所なら、インストーラはそこに上書きするので、先に[ロールバックの「OpenSSH・Git for Windows・Firefox・WezTerm を外す」](extra/windows-setup.md#opensshgit-for-windowsfirefoxwezterm-を外す)の手順 8 で外す
   - `OnPath` に `C:\Program Files\WezTerm\wezterm.exe` 以外（scoop の `shims` など）が出たら、ほかの方法で入れた WezTerm がある。外してから始める
   - `Running` に名前が出たら、その WezTerm の窓を閉じる（[Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)のタスクは、同書の[止める・もう一度始める](windows-claude-remote-control.md#止めるもう一度始める)の手順 1 で止める）
   - `VCRuntime : True` なら、この項の手順 2 は飛ばす。`False` なら、この項の手順 2 で入れる

1. `VCRUNTIME140.dll` が無いときだけ、Visual C++ の再頒布可能パッケージを入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget install --exact --id Microsoft.VCRedist.2015+.x64 --source winget --scope machine --accept-source-agreements --accept-package-agreements
   Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と、`True` が出ればよい
   - winget が再起動を求めても、ここでは再起動しない。最後の行が `True` なら、続けてこの項の手順 3 を貼る（[WSL と再起動](#wsl-と再起動)の手順 2 でまとめて再起動する）
   - 最後の行が `False` なら、この項の残りは、再起動の後（[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)より前）に管理者の窓（[PC 全体の設定](#pc-全体の設定)の手順 1 と同じ）を開いて、この項の手順 1 から行う
   - `winget` が見つからないというエラーになったら、Microsoft Store で「アプリ インストーラー」を更新してから始める

1. nightly のインストーラを取り、sha256 を確かめて、黙って入れる。

   ```powershell
   & {
     $dir = 'C:\Program Files\WezTerm'
     $curl = "$env:WINDIR\System32\curl.exe"
     $url = 'https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-nightly-setup.exe'
     $tmp = "$env:TEMP\wezterm-setup"
     $setup = "$tmp\WezTerm-nightly-setup.exe"
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない'; return }
     if (-not (Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll")) { Write-Error '中断: VCRUNTIME140.dll が無い（「WezTerm」の手順 2）'; return }
     if (Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue) { Write-Error '中断: WezTerm が動いている（窓をすべて閉じる）'; return }
     Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & $curl -fsSL -o "$setup.sha256" "$url.sha256"
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: WezTerm-nightly-setup.exe.sha256 を取れない'; return }
     & $curl -fsSL -o $setup $url
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: WezTerm-nightly-setup.exe を取れない'; return }
     $m = Select-String -LiteralPath "$setup.sha256" -Pattern '^([0-9a-f]{64})  WezTerm-nightly-setup\.exe$' | Select-Object -First 1
     if (-not $m) { Write-Error '中断: WezTerm-nightly-setup.exe.sha256 に sha256 の行が無い'; return }
     if ((Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash -ne $m.Matches[0].Groups[1].Value) { Write-Error '中断: WezTerm-nightly-setup.exe の sha256 が一致しない'; return }
     $p = Start-Process -FilePath $setup -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCLOSEAPPLICATIONS /LOG=`"$tmp\setup.log`"" -Wait -PassThru
     if ($p.ExitCode -ne 0) { Write-Error "中断: インストーラが終了コード $($p.ExitCode) で終わった（ログは $tmp\setup.log）"; return }
     Remove-Item -LiteralPath $tmp -Recurse -Force
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0'
     & "$dir\wezterm.exe" --version
   }
   ```

   - `WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0` と、`wezterm 20260929-043349-cab25161` の形の 1 行が出ればよい
   - インストーラの画面は出ない。終わるまでプロンプトが戻らない
   - `中断:` で始まるエラーが出たら、そこで止まっている
   - `取れない` と `sha256 が一致しない` は、nightly が入れ替わる最中に取ったときにも出る。少し待って貼り直す
   - 何度貼ってもよい

1. 入ったものと、`PATH`・スタートメニューを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1' | Format-List DisplayName, DisplayVersion, InstallLocation, UninstallString
   & 'C:\Program Files\WezTerm\wezterm.exe' --version
   [Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';' | Where-Object { $_ -like '*\WezTerm*' }
   Test-Path -LiteralPath "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\WezTerm.lnk"
   Get-ChildItem -LiteralPath 'C:\Program Files\WezTerm' -Name
   ```

   - `DisplayVersion` と `wezterm --version` の版が同じ（`20260929-043349-cab25161` の形）
   - `UninstallString` は `"C:\Program Files\WezTerm\unins000.exe"`
   - PC 全体の `PATH` に `C:\Program Files\WezTerm` が 1 行と、スタートメニューの `True` が出る
   - 最後に `wezterm.exe`・`wezterm-gui.exe`・`unins000.exe` などのファイルの名前が並ぶ
   - 開いていた PowerShell の `PATH` には入らない。新しく開いた窓（WezTerm の中も）では、`wezterm` を名前で呼べる

1. スタートメニューから WezTerm を起動し、窓が開くことを確かめる。

   - スタートメニューで「WezTerm」を探し、クリックして開く
   - 窓が開き、中でシェルが動けばよい。設定ファイルが無ければ `cmd.exe` が開く（自分用の設定では Git Bash。[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 5 で入れる）
   - 窓の中で `wezterm --version` を打つと、この項の手順 4 と同じ版が出る
   - 窓が開かずに終わったら、`%USERPROFILE%\.local\share\wezterm\wezterm-gui.exe-log-<番号>.txt` を見る
     - `The OpenGL implementation is too old to work with glium` なら、3D の描画の無い VM などで OpenGL が使えない
     - その場で開くなら、Win+R の「ファイル名を指定して実行」に `"C:\Program Files\WezTerm\wezterm-gui.exe" --config prefer_egl=true` を入れて開く（管理者の窓からは起動しない）
     - いつも開くようにするなら、設定の `config` に `config.prefer_egl = true` を足す。設定ファイルが無ければ、`%USERPROFILE%\.wezterm.lua` に `local wezterm = require 'wezterm'`・`local config = wezterm.config_builder()`・`config.prefer_egl = true`・`return config` の 4 行を書く
     - 自分用の設定（`~/.config/wezterm`）を使うなら、`~/.wezterm.lua` は作らない（[AlmaLinux 10 の初期設定の「WezTerm の設定ファイル」](almalinux-setup.md#wezterm-の設定ファイル)のとおり、clone した設定が読まれなくなる）
   - **注意**: 管理者の PowerShell から `wezterm-gui.exe` を起動しない（WezTerm と中のシェルが管理者で動く）

### WSL と再起動

1. WSL を使えるように、Windows の機能を入れる（ディストリビューションは再起動の後に入れる）。

   ```powershell
   wsl.exe --install --no-distribution
   ```

   - 必要な機能（仮想マシン プラットフォーム）を入れた旨と、再起動を求める旨の行が出ればよい
   - もう入っていれば、何もしない
   - **注意**: この後は Hyper-V が動くので、[VirtualBox](virtualbox.md#windows-11-で使う) の VM は Hyper-V の上で動く。処理が遅くなる場合は、[VirtualBox の注意点](extra/virtualbox.md#注意点)を確認する

1. 再起動する。

   ```powershell
   Restart-Computer
   ```

   - 保存していない作業があれば、先に保存する（すぐに再起動が始まる）
   - ほかのユーザーがサインインしていると、エラーで止まる。そのときは、スタートメニューの電源から再起動する
   - **次の手順は、起動してサインインしてから行う**

### 再起動の後に確かめる

1. キーボードで、Caps Lock・Ctrl+Space・配列を確かめる。

   - メモ帳を開いて何か打ち、Caps Lock を押したまま A を押すと、全部が選ばれる（Ctrl+A）
   - Caps Lock だけを押しても、Caps Lock のランプは点かず、大文字にもならない
   - 日本語の配列（JIS）のキーボードでは、「英数」（Caps Lock）のキーが Ctrl になる
   - Ctrl+Space を押すたびに、IME のオンとオフが入れ替わる（タスクバーの「あ」と「A」）
   - [サインイン・検索・キーボード](#サインイン検索キーボード)の手順 6 を行ったなら、記号が US 配列の位置で出る（Shift+2 で `@`）

1. エクスプローラー・タスクバー・スタートが変わったことを確かめる。

   - ファイルかデスクトップを右クリックすると、「その他のオプションを確認」を選ばなくても、「送る」「プロパティ」などの並ぶ旧形式のメニューが出る
   - エクスプローラーを開くと「PC」が出て、ファイル名に拡張子が付き、隠しファイルも見える
   - タスクバーのアイコンが左に寄り、タスク ビュー・検索・ウィジェットのボタンが無く、時計に秒が出る。全体が濃い色になっている
   - スタートを開いて文字を打っても、Web（Bing）の結果が出ない（[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 2）
   - デスクトップに Edge と UniGet UI のショートカットが無い

1. タスクバーとスタートの、要らないピン留めを外す。

   - タスクバーのアイコン（Microsoft Edge・Microsoft Store など）を右クリックし、「タスクバーからピン留めを外す」
   - スタートを開き、ピン留めされたアプリを右クリックし、「スタートからピン留めを外す」
   - Copilot は外さない。使うアプリは残す

1. スタートメニューから UniGet UI を起動し、WinGet と Scoop が使えることを確かめる。

   - スタートメニューで「UniGetUI」を探して開く
   - 初回は、使い方の案内や設定の問いが出ることがある。読んで進める
   - 左の「パッケージマネージャー」で、WinGet と Scoop が有効で「利用可能」になっていることを確かめる（版は、それぞれの「バージョンを表示」で出る）
   - 「インストール済みのパッケージ」に、[アプリを入れる](#アプリを入れる)の手順 3 で scoop で入れた `scoop-search` と、winget の `UniGetUI` などが出る

1. 設定のフォントの一覧で、HackGen Console NF が出ることを確かめる。

   - 設定 → 個人用設定 → フォント を開き、「HackGen」で探すと、`HackGen Console NF` と `HackGen35 Console NF` が出る（どちらも「2 フォント フェイス」）
   - ライセンス認証していない Windows では、フォントの画面の検索欄が使えないことがある。そのときは一覧をスクロールして探す
   - メモ帳のフォントの一覧に出ても同じ
   - 端末のフォントにするなら、アプリの設定にファミリー名 `HackGen Console NF` を書く（WezTerm は `config.font = wezterm.font 'HackGen Console NF'`。自分用の設定（`ryo-aoki-pc/wezterm`）は、もうこのフォントを使う）

### WSL の AlmaLinux 10 と自動サインイン

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - 複数行のブロックを貼ると出る警告では、「強制的に貼り付け」を押す

1. 再起動の後の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $sm = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' -ErrorAction SilentlyContinue).'Scancode Map'
   [pscustomobject]@{
     ComputerName  = $env:COMPUTERNAME
     CtrlEnter     = (Get-PSReadLineKeyHandler -Bound | Where-Object Key -eq 'Ctrl+Enter').Function
     ScancodeMap   = if ($sm) { ($sm | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' } else { '' }
     Keyboard      = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters' -ErrorAction SilentlyContinue).'LayerDriver JPN'
     LongPaths     = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem').LongPathsEnabled
     DeveloperMode = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
     Sudo          = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo' -ErrorAction SilentlyContinue).Enabled
     Hibernate     = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power').HibernateEnabled
     RemoteDesktop = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
     LanCategory   = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).NetworkCategory
     Hypervisor    = (Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
   } | Format-List
   ```

   - 次の値が出ればよい（行わなかった手順の値は、元のまま）
     - `ComputerName` が[PC 全体の設定](#pc-全体の設定)の手順 2 の `PC_NAME`（大文字）、`CtrlEnter : AddLine`、`ScancodeMap : 00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00`
     - `Keyboard` は、[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 6 を行ったなら `kbd101.dll`
     - `LongPaths : 1`・`DeveloperMode : 1`・`Sudo : 3`・`Hibernate : 0`
     - `RemoteDesktop : 0`（[ネットワークとリモート](#ネットワークとリモート)の手順 2 を行ったとき）・`LanCategory : Private`
     - `Hypervisor : True`

1. WSL に AlmaLinux 10 を入れ、ユーザーを作る。

   ```powershell
   $env:WSL_UTF8 = '1'
   [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
   wsl.exe --install AlmaLinux-10
   ```

   - ダウンロードの後に `Enter new UNIX username:` と聞かれるので、Linux のユーザー名を入れる。続けてパスワードを 2 回入れる
   - AlmaLinux 10 のシェル（`[<ユーザー>@<HOSTNAME> ~]$`）になったら、`exit` で PowerShell に戻る
   - **次の手順は、`exit` で PowerShell に戻ってから貼る**（続けて貼ると、AlmaLinux 10 のシェルへの入力として食われる）

1. AlmaLinux 10 が WSL 2 で動くことを確かめる。

   ```powershell
   $env:WSL_UTF8 = '1'
   [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   wsl.exe --list --verbose
   wsl.exe --distribution AlmaLinux-10 -- head -n 2 /etc/os-release
   ```

   - `AlmaLinux-10` の行の `VERSION` が `2` で、`NAME="AlmaLinux"` と `VERSION="10.2 …"` の形の行が出ればよい

1. 自動サインイン（Sysinternals の Autologon）を入れて起動し、パスワードを入れて有効にする。

   ```powershell
   winget install --exact --id Microsoft.Sysinternals.Autologon --source winget --scope user --accept-source-agreements --accept-package-agreements
   $exe = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter Autologon64.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
   if (-not $exe) { Write-Error '中断: Autologon64.exe が見つからない' } else { Start-Process -FilePath $exe -ArgumentList '-accepteula' }
   ```

   - UAC の確認が出たら「はい」。Autologon の窓が開く
   - `Username` にこの PC のユーザー名、`Domain` に PC の名前（入っている値のまま）、`Password` にこのユーザーのパスワードを入れ、`Enable` を押す
   - 効くのは、次に起動したときから（起動のときに Shift を押していると、その回は飛ばす）
   - 人が触れる場所にある PC では、この手順は行わない（リードの `[!WARNING]`）

### SSH でログインを確かめる

1. クライアントのシェルを開く（この PC の WSL の AlmaLinux 10 を使うなら、そのシェルに入る）。

   ```powershell
   wsl.exe --distribution AlmaLinux-10 --cd ~
   ```

   - [WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 の PowerShell に貼る。`[<ユーザー>@<HOSTNAME> ~]$` のプロンプトになればよい
   - ほかの PC（AlmaLinux 10 など）をクライアントにするなら、その PC の自分のユーザーの端末を開き、このブロックは貼らない
   - WSL のネットワークが既定（NAT）なら、この PC の LAN の IP（`<WIN_HOST>`）あてにつなぐ（[注意点](extra/windows-setup.md#注意点)の WSL からつなぐとき）
   - **次の手順は、クライアントのシェルに貼る**

1. クライアントに `ssh` が無いときだけ、入れる。

   ```bash
   command -v ssh || sudo dnf install -y openssh-clients
   ```

   - `/usr/bin/ssh` が出れば、入っている（何も入れない）
   - 入れるときは、`sudo` のパスワード（WSL では[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 3 で決めたもの）を聞かれる
   - **次の手順は、`Complete!` が出てプロンプトに戻ってから貼る**（続けて貼るとパスワードとして食われる）

1. クライアントのシェルで、変数を設定する（`WIN_HOST` は必ず値を入れる）。

   ```bash
   WIN_HOST=                             # ← 「OpenSSH サーバー」の手順 5 で控えた @ の後ろ（Windows の IP アドレス）を書く。<WIN_HOST>
   ```

   ```bash
   WIN_USER=${USER}                      # Windows のユーザー名。「OpenSSH サーバー」の手順 5 の @ の前と違えば直す。<WIN_USER>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in WIN_HOST WIN_USER; do
     printf '%-8s = %s\n' "$v" "${!v}"
   done
   ```

   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**、この項の手順 3 の 2 つのブロックを貼り直してから先へ進む（任意節の[OpenSSH サーバーに公開鍵でもログインする（任意）](#openssh-サーバーに公開鍵でもログインする任意)などでも使う）

1. クライアントのシェルで、ホスト鍵を照合し、パスワードでログインする。

   ```bash
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 「SSH でログインを確かめる」の手順 3 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh -o PubkeyAuthentication=no "${WIN_USER}@${WIN_HOST}"
   fi
   ```

   - 初回は `ED25519 key fingerprint is SHA256:…` と `Are you sure you want to continue connecting (yes/no/[fingerprint])?` が出る。[OpenSSH サーバー](#openssh-サーバー)の手順 5 で控えた指紋と同じなら `yes`
   - `<WIN_USER>@<WIN_HOST>'s password:` で、Windows のユーザーのパスワードを入れる（Microsoft アカウントなら、そのアカウントのパスワード。PIN ではない）
   - `<WIN_USER>@<HOSTNAME> C:\Users\<WIN_USER>>` の cmd のプロンプトが出ればよい。`whoami` で `<hostname>\<win_user>`（小文字）が出る
     - [SSH の既定のシェルを Git Bash にする（任意）](#ssh-の既定のシェルを-git-bash-にする任意)の後は、`<WIN_USER>@<HOSTNAME> MINGW64 ~` のプロンプトになり、`whoami`（Git のもの）は `<WIN_USER>` だけを出す
   - `exit` でクライアントのシェルに戻る
   - **注意**: パスワードを続けて間違えると、Windows のロックアウトのポリシーでアカウントがロックされる（[注意点](extra/windows-setup.md#注意点)）
   - WSL の AlmaLinux 10 をクライアントにしたときは、続けてもう一度 `exit` を打ち、PowerShell に戻る
   - **次の手順は、`exit` で PowerShell に戻ってから貼る**（続けて貼ると Windows の cmd への入力として食われる）

### Git Bash と WezTerm の設定

1. Git for Windows の git の場所と版と、Git Bash があることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Command git -All | Format-Table Source
   git --version
   Test-Path 'C:\Program Files\Git\bin\bash.exe', 'C:\Program Files\Git\git-bash.exe'
   ```

   - 1 行目の一番上に `C:\Program Files\Git\cmd\git.exe` が出ればよい
   - `git version 2.55.0.windows.5` の形の行と、`True` が 2 行出ればよい

1. スタートメニューから Git Bash を開く。

   - スタートメニューで「Git Bash」を探して開く（管理者でなくてよい）
   - `<WIN_USER>@<HOSTNAME> MINGW64 ~` のような行と、`$` のプロンプトの窓が開く
   - Git Bash の窓に貼るときは、窓の中を右クリックして出るメニューの「Paste」を選ぶ。最後の行は、貼った後に Enter を押す
   - **次の手順は、この Git Bash に貼る**

1. Git Bash に、[AlmaLinux 10 の初期設定の「Git」](almalinux-setup.md#git)の手順 1〜10 を上から順に貼る。

   - `~/.gitconfig`（`C:\Users\<WIN_USER>\.gitconfig`）に、AlmaLinux 10 と同じ基本の設定を書く。成功の条件は、同書のそれぞれの手順と同じ
   - 同書の「Git」の手順 2 では、インストーラが書いた `system` の行（`core.autocrlf=true` など）も出る
   - **この手順は、この項の手順 4・5 の clone より前に行う**（`global` の `core.autocrlf=false` が無いと、clone したファイルの改行が `system` の `core.autocrlf=true` で CRLF になる）
   - Git Bash・PowerShell・cmd の git は、同じ `~/.gitconfig` を読む
   - 戻すときは、[ロールバックの「Git Bash の設定を戻す」](extra/windows-setup.md#git-bash-の設定を戻す)で行う（同書の「Git」の手順 2 の箇条書きが案内する AlmaLinux 10 のロールバックと同じ内容を、Git Bash で行う）

1. 同じ Git Bash で、共通の bash 設定を入れる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git clone https://github.com/ryo-aoki-pc/bash.git ~/.config/bash &&
     bash ~/.config/bash/install.sh
   ```

   - [README の「共通の bash 設定を先に入れる」](../README.md#共通の-bash-設定を先に入れる)と、[AlmaLinux 10 の初期設定の「共通の bash 設定」](almalinux-setup.md#共通の-bash-設定)の手順 1 と同じブロック
   - `~/.bashrc: 設定済み（元の内容: ~/.bashrc.before-bash）` と `完了: 端末を開き直す。…` が出ればよい
   - すでに clone してあるなら `fatal: destination path … already exists` で止まる。そのときは `git -C ~/.config/bash pull --ff-only` で更新し、`bash ~/.config/bash/install.sh` を貼る

1. 自分用の WezTerm の設定（[ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)）を入れ、WezTerm を起動し直す。

   - [その docs/install.md の実施手順](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#実施手順)の手順 1〜4 を、この Git Bash に貼る（`~/.config/wezterm` に clone する）
   - その手順 5〜7（`~/.bashrc` への直接の追記）は飛ばす。シェル統合は、この項の手順 4 の共通の bash 設定が読む
   - その手順 8 で、スタートメニューの「WezTerm」から起動し、手順 9 を WezTerm のタブに貼って確かめる（新しいタブは Git Bash で開く）
   - Git Bash の窓は閉じてよい。この後の bash のブロックは、WezTerm のタブに貼る
   - **次の手順は、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1で開いた PowerShell に貼る**

### シェルのツールを入れる

1. 管理者ではないことと、前提と、ほかの方法で入れた同じツールが無いかを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     BashConfig = Test-Path -LiteralPath "$env:USERPROFILE\.config\bash\bashrc"
     VCRuntime  = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
     Tools      = (Get-Command fzf, zoxide, starship, eza, bat -All -ErrorAction SilentlyContinue).Source -join ', '
     Zoxide     = if (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue) { zoxide --version } else { '' }
   } | Format-List
   ```

   - `PowerShell : 5.1.…`・`Admin : False`・`BashConfig : True`・`VCRuntime : True` ならよい。`Admin : True` なら、窓を閉じて、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 のとおりに開き直す
   - `Scoop` が空なら、先に[アプリを入れる](#アプリを入れる)の手順 1・2 を通す
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [Git for Windows](#git-for-windows)を通す
   - `BashConfig : False` なら、先に[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 4 を通す
   - `VCRuntime : False` なら、[WezTerm](#wezterm)の手順 2 を管理者の窓で行ってから、このブロックを貼り直す
   - `C:\Users\<WIN_USER>\scoop\` の下の `shims\<名前>.exe` と `apps\starship\current\starship.exe` だけなら、scoop で入れたもの（この項の手順 3 は、入っているものを飛ばす）
   - ほかの場所（winget の `…\WinGet\Links\` など）が出たら、ほかの方法で入れたものがある。その方法で外してから始める
   - `Zoxide` が空か `zoxide 0.9.9` なら、この項の手順 2 は飛ばす

1. scoop の zoxide が 0.9.9 でないときだけ、外す。

   ```powershell
   scoop uninstall zoxide
   ```

   - `'zoxide' was uninstalled.` が出ればよい

1. scoop を上げてから 5 つを入れ、zoxide を 0.9.9 に止める。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop update
   scoop install fzf starship eza bat
   scoop install zoxide@0.9.9
   scoop hold zoxide
   ```

   - `scoop update` は `Scoop was updated successfully!` を出す（Git for Windows より前に scoop を入れた PC では、初めてのときに `Converting 'main' bucket to git repo...` も出る）
   - それぞれ `'<名前>' (<版>) was installed successfully!` の形の行が出て、最後に `zoxide is now held and can not be updated anymore.` が出ればよい（zoxide は `0.9.9`）
   - zoxide の 0.9.9 は、scoop が main のバケットの git の履歴から定義を取り出して入れる（`Resolving historical manifest for 'zoxide' (0.9.9)` の行が出る）
   - 2 行目は、もう入っているものを、何も出さずに飛ばす
   - zoxide の 0.9.9 がもう入っていれば、3 行目は `'zoxide' (0.9.9) is already installed.` の警告だけを出す
   - もう止めてあれば、`'zoxide' is already held.` が出る
   - starship は shim を作らず、`Adding ~\scoop\apps\starship\current to your path.` で自分のユーザーの `Path` に足す（この窓にも入る）
   - bat は `Setting user environment variable: BAT_CONFIG_DIR = …` で環境変数を足す（この窓にも入る）
   - `Notes` の、PowerShell の `$PROFILE` に starship の行を足す案内は行わない。`suggests installing` の行（VC++ ランタイム・less）も、入れなくてよい
   - **zoxide は 0.9.9 に止めて入れる**（今の 0.10.0 は、Git Bash で移ったディレクトリを記録しない。[参考資料](reference/windows-setup.md)）。直った版が出たら、[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 6・7 で上げる。ほかの 4 つは同じ項の手順 1・2 で上がる

1. 版と場所と、zoxide を止めたことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   fzf --version
   zoxide --version
   starship --version
   eza --version
   bat --version
   (Get-Command fzf, zoxide, starship, eza, bat -All).Source
   scoop list zoxide
   ```

   - それぞれの版が出ればよい（`zoxide 0.9.9`・`starship 1.26.0`・`v0.23.5 [+git]`・`bat 0.26.1` の形）
   - `bat --version` が何も出さないか、DLL が見つからない旨のエラーになったら、VC++ ランタイムが無い（この項の手順 1 の `VCRuntime`）
   - 場所は、`C:\Users\<WIN_USER>\scoop\shims\` の下の `fzf.exe`・`zoxide.exe`・`eza.exe`・`bat.exe` と、`C:\Users\<WIN_USER>\scoop\apps\starship\current\starship.exe` の 5 行だけ
   - `scoop list` の `zoxide` の行は、`Version` が `0.9.9`、`Source` が `<auto-generated>`（前から main のバケットで入れた 0.9.9 なら `main`）、`Info` が `Held package`

1. bat の設定ファイル（`BAT_CONFIG_DIR` の下の `config`）に、3 行の設定を書く（中身があれば書き換えない）。

   ```powershell
   $BAT_THEME_NAME = 'ansi'   # 使うテーマ。ansi は端末の 16 色にそのまま従う（一覧は bat --list-themes）。<BAT_THEME_NAME>
   ```

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not $BAT_THEME_NAME) { Write-Error '中断: BAT_THEME_NAME が空のまま。値を入れて貼り直す'; return }
     $f = if ($env:BAT_CONFIG_PATH) { $env:BAT_CONFIG_PATH } elseif ($env:BAT_CONFIG_DIR) { Join-Path $env:BAT_CONFIG_DIR 'config' } else { '' }
     if (-not $f) { Write-Error '中断: BAT_CONFIG_DIR が無い。「シェルのツールを入れる」の手順 3 で bat を入れたかを確かめる'; return }
     if ((Test-Path -LiteralPath $f) -and [IO.File]::ReadAllText($f).Trim()) { "中身がある（書き換えない）: $f" } else {
       Set-Content -LiteralPath $f -Encoding ASCII -Value "--theme=`"$BAT_THEME_NAME`"", '--style="numbers,changes,header"', '--paging=never' -ErrorAction Stop
       "書いた: $f"
     }
     Get-Content -LiteralPath $f
   }
   ```

   - `書いた: C:\Users\<WIN_USER>\scoop\apps\bat\current\config` と、`--theme="ansi"`・`--style="numbers,changes,header"`・`--paging=never` の 3 行が出ればよい
   - 書いた中身は、scoop の控え（`~\scoop\persist\bat\config`）に残り、bat を上げても消えない
   - `中身がある（書き換えない）:` が出たら、前からの設定（`%APPDATA%\bat\config` から scoop が写したものなど）がある。何も変えていない
   - `中断:` が出たら、何も書いていない

1. WezTerm の新しいタブ（Git Bash）で、[AlmaLinux 10 の初期設定の「シェルのツール」の手順 4〜7・9・10](almalinux-setup.md#シェルのツール)のブロックを貼る。

   - WezTerm を起動するか、新しいタブ（Ctrl+Shift+T）を開く。前から開いているタブで `. ~/.bashrc` を読み直さない（[同書の「シェルのツール」の手順 2](almalinux-setup.md#シェルのツール)の補足と同じ）
   - 新しいタブのプロンプトが starship の形にならなければ、WezTerm の窓をすべて閉じて起動し直す
   - 成功の条件は、同書のそれぞれの手順と同じ。違うのは次のところ
     - `command -v` は `/c/Users/<WIN_USER>/scoop/shims/<名前>`（starship は `/c/Users/<WIN_USER>/scoop/apps/starship/current/starship`）。版は、この項の手順 4 と同じ
     - 同書の「シェルのツール」の手順 5 の `bind -X` は、`"\C-r" "__fzf_history__"` のようにコロンの無い形で出る（Git Bash の bash 5.3）。WezTerm のシェル統合を読んでいれば、マウス報告よけの行も出る（そのままでよい）
     - 同書の「シェルのツール」の手順 6 の見出しは、`Permissions` が `Mode` になり、`User` の列が無い。`Git` の列が出ればよい。`ll` は、Git for Windows の `ls -l` ではなく eza になる
     - 同書の「シェルのツール」の手順 7 で `/etc/os-release` が無い旨のエラーが出たら、そのコマンドを `~/.bashrc` に変えて打つ。`MANPAGER` は `bat -plman` と出るが、Git Bash に `man` は無い
     - 同書の「シェルのツール」の手順 9 の `cd /usr/share` は、Git for Windows の `C:\Program Files\Git\usr\share` に移る。同書の「シェルのツール」の手順 10 の一覧には、その形（`C:\…`）で出る
   - 同書の「シェルのツール」の手順 8（tmux）は行わない
   - Git Bash では、共通の bash 設定が、入っているツールを見つけて読む。`~/.bashrc` には書かない。Windows PowerShell 5.1 には読み込まない

1. 同じタブで、[同書の「キー操作を試す」の手順 2〜5](almalinux-setup.md#キー操作を試す)のキーを押して、fzf を確かめる。

   - 同書の「キー操作を試す」の手順 2 の `fzf --version` は、この項の手順 6 で Git Bash の履歴に入っている
   - 同書の「キー操作を試す」の手順 3 をホーム（`C:\Users\<WIN_USER>`）で行うと、`AppData` の下のファイルも一覧に入る
   - 同書の「キー操作を試す」の手順 4 の `doc/bash` が一覧に無ければ、一覧にある別の語で絞る（`/usr/share` は Git for Windows のもの）
   - 日本語など ASCII 以外の文字では、絞り込めないことがある（Windows の fzf は、画面の一部に開いた一覧では ASCII 以外の文字を読めない）
   - **次の手順は、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1で開いた PowerShell に貼る**

### git-delta

1. 管理者ではないことと、scoop・git・VC++ ランタイム・ほかの delta を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     VCRuntime  = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
     Delta      = (Get-Command delta -All -ErrorAction SilentlyContinue).Source -join ', '
   } | Format-List
   ```

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`Admin : True` なら、窓を閉じて、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 のとおりに開き直す
   - `Scoop` に `C:\Users\<WIN_USER>\scoop\shims\scoop.ps1` が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 1・2 で入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [Git for Windows](#git-for-windows)
   - `VCRuntime : True` ならよい。`False` なら、先に [WezTerm](#wezterm)の手順 2 を管理者の Windows PowerShell で行い、この窓でこのブロックを貼り直す
   - ほかの場所（winget の `…\WinGet\Links\delta.exe` など）が出たら、ほかの方法で入れた delta がある。外してから始める

1. scoop で delta を入れ、版と場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop install delta
   delta --version
   (Get-Command delta -All).Source
   ```

   - `'delta' (0.20.1) was installed successfully!` の形の行が出ればよい
   - もう入っていれば、`'delta' (<版>) is already installed.` と `Use 'scoop update delta' to install a new version.` の警告を出して何も変えない
   - `delta 0.20.1` の形で、入れた版が出ればよい。版が出なければ、この項の手順 1 の `VCRuntime` を確かめる
   - 最後のコマンドは、`C:\Users\<WIN_USER>\scoop\shims\delta.exe` の 1 行だけを出せばよい

1. WezTerm の新しいタブ（Git Bash）で、[AlmaLinux 10 の初期設定の「git-delta」](almalinux-setup.md#git-delta)の手順 1・3 を貼る。

   - WezTerm を起動するか、新しいタブ（既定のキーは Ctrl+Shift+T）を開く（自分用の WezTerm の設定では Git Bash が開く）
   - 同書の「git-delta」の手順 1 の 3 つの変数は、AlmaLinux 10 と同じ既定のままでよい。同じ項の手順 3 も同じタブに貼る
   - 同書の「git-delta」の手順 3 は、AlmaLinux 10 と同じく、設定した 6 項目が出ればよい（`interactive.difffilter` は小文字）
   - 同書の「git-delta」の手順 2・4 は行わない

1. 同じ Git Bash のタブで `git diff` を打ち、delta の表示になることを確かめる。

   - 変更のあるリポジトリに `cd` してから打つ。変更のあるリポジトリが無ければ、代わりに `git -C ~/.config/bash show` を打つ
   - ファイル名のヘッダと、行番号・行ごとに背景色の付いた差分が出ればよい（同書の「git-delta」の手順 4 と同じ見え方）
   - 1 画面に収まらないときは、less で止まる。`q` で閉じる
   - 素の差分（背景色の無い `+` / `-` の行）が出たら、この項の手順 3 で貼った同書の「git-delta」の手順 3 の読み戻しに `core.pager delta` があるかを確かめる
   - `git diff | head` のようにパイプに繋ぐと、AlmaLinux 10 と同じく delta を通らない
   - **次の手順は、less を `q` で閉じ、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1で開いた PowerShell に貼る**

### GitHub CLI

1. 管理者ではないことと、scoop・git・Git の資格情報のヘルパー・ほかの gh を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     GitCred    = if (Get-Command git -ErrorAction SilentlyContinue) { (git config --get-regexp '^credential\..*helper$') -join ', ' }
     Gh         = (Get-Command gh -All -ErrorAction SilentlyContinue).Source -join ', '
   } | Format-List
   ```

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`Admin : True` なら、窓を閉じて、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 のとおりに開き直す
   - `Scoop` に `C:\Users\<WIN_USER>\scoop\shims\scoop.ps1` が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 1・2 で入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [Git for Windows](#git-for-windows)
   - `GitCred` が `credential.helper manager` ならよい
   - `GitCred` が空なら、この項の手順 3 の Git の認証には `Y` と答えてよい
   - ほかの場所（winget の MSI の `C:\Program Files\GitHub CLI\gh.exe` など）が出たら、ほかの方法で入れた gh がある。外してから始める

1. scoop で gh を入れ、版と場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop install gh
   gh --version
   (Get-Command gh -All).Source
   ```

   - `'gh' (2.102.0) was installed successfully!` の形の行が出ればよい
   - もう入っていれば、`'gh' (<版>) is already installed.` と `Use 'scoop update gh' to install a new version.` の警告を出して何も変えない
   - `gh version <版> (<日付>)` の形で、入れた版が出ればよい
   - 最後のコマンドは、`C:\Users\<WIN_USER>\scoop\shims\gh.exe` の 1 行だけを出せばよい

1. GitHub へのログインを始める。

   ```powershell
   gh auth login
   ```

   - 問いには、矢印キーで選んで Enter で答える
     - `Where do you use GitHub?` は `GitHub.com`
     - `What is your preferred protocol for Git operations on this host?` は `HTTPS`
     - `Authenticate Git with your GitHub credentials?` は、**`n` と打って Enter**（既定は `Y`）
     - `How would you like to authenticate GitHub CLI?` は `Login with a web browser`
   - Git の認証の問いが出なければ、gh がもう Git の資格情報のヘルパーになっている（この項の手順 1 の `GitCred`）
   - `One-time code (<コード>) copied to clipboard` の行のワンタイムコードを、この項の手順 4 のブラウザで使う
   - クリップボードに入れられなかったときは、`First copy your one-time code:` の後にコードが出る
   - `Press Enter to open https://github.com/login/device in your browser...` で Enter を押すと、既定のブラウザが開く
   - **トークン（`gh auth token` の出力）や、認証中に表示されるワンタイムコードはこの文書に載せない**

1. ブラウザで、GitHub の認証を済ませる。

   - 開いたページ（`https://github.com/login/device`）に、この項の手順 3 のワンタイムコードを入れ、画面の案内に従う（[AlmaLinux 10 の初期設定の「GitHub CLI」](almalinux-setup.md#github-cli)の手順 4 と同じ）
   - ブラウザが開かなければ（`Failed opening a web browser at …`）、`https://github.com/login/device` を自分でブラウザで開く
   - PowerShell に `Logged in as <GITHUB_USER>` が出れば、`gh auth login` は終わっている
   - `Authentication credentials saved in plain text` も出たら、トークンは資格情報マネージャーに置けず、`%APPDATA%\GitHub CLI\hosts.yml` に平文で入った（[注意点](extra/windows-setup.md#注意点)の GitHub CLI のトークンの置き場所）
   - **次の手順は、`gh auth login` が終わってから貼る**（続けて貼ると対話の答えとして食われる）

1. ログインできたことと、Git の資格情報のヘルパーが変わっていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   gh auth status
   git config --get-regexp '^credential\..*helper$'
   ```

   - `Logged in to github.com account <GITHUB_USER> (keyring)` の行と、`Git operations protocol: https` の行が出ればよい
   - `(keyring)` の代わりに `(C:\Users\<WIN_USER>\AppData\Roaming\GitHub CLI\hosts.yml)` が出たら、トークンは平文のファイルにある
   - `You are not logged into any GitHub hosts.` なら、ログインしていない。この項の手順 3 からやり直す
   - 最後のコマンドが、この項の手順 1 の `GitCred` と同じ行（ふつうは `credential.helper manager`）を出せばよい
   - `GitCred` が空で、Git の認証に `Y` と答えたときは、代わりに `auth git-credential` で終わる行が出る

### Neovim

1. 管理者ではないことと、scoop・git・VC++ のランタイム・ほかの Neovim を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     VCRuntime  = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
     Nvim       = (Get-Command nvim -All -ErrorAction SilentlyContinue).Source -join ', '
   } | Format-List
   ```

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`True` なら、窓を閉じて、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 のとおりに開き直す
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 1・2 で入れる
   - `Git` は `C:\Program Files\Git\cmd\git.exe` ならよい。空か違う場所なら、先に [Git for Windows](#git-for-windows)
   - `VCRuntime : False` なら、[WezTerm](#wezterm)の手順 2 を管理者の Windows PowerShell で行ってから、この手順を貼り直す
   - `C:\Program Files\Neovim\bin\nvim.exe` など、ほかの場所が出たら、winget などで入れた Neovim がある。外してから始める

1. scoop で Neovim を入れる。

   ```powershell
   scoop install neovim
   ```

   - `'neovim' (0.12.5) was installed successfully!` の形の行が出ればよい
   - `'neovim' suggests installing 'extras/vcredist2022'.` も出るが、この項の手順 1 が `VCRuntime : True` なら入れなくてよい
   - `'neovim' (0.12.5) is already installed.` の形なら、もう入っている（何も変えない）
   - まだ `nvim` は起動しない（この項の手順 3 の退避より前に起動すると、`nvim-data` などができて、それも退避される）

1. 自分用の設定（[ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter)）を入れる。

   - [その docs/setup.md の「Windows 11 に導入する」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#windows-11-に導入する-1-度だけ)の手順 1・3〜11 を、この窓に上から順に貼る
   - 飛ばす手順: 2（scoop。[アプリを入れる](#アプリを入れる)の手順 1・2 で入れた）と、手順 7 のフォント（[HackGen Console NF](#hackgen-console-nf)で入れた。手順 7 の確かめは行う）
   - その手順 3 で `extras` のバケットを足し、手順 6 で ripgrep・fd・gcc・nodejs・zenhan・lazygit も scoop で入れる（Neovim は、この項の手順 2 で入っている）
   - その手順 9・11 で Neovim の画面が開く（その手順 10 は画面を開かない）。手順 9 は `:qa`、手順 11 は `:qa!` で閉じてから次を貼る

1. 版と場所と、設定・データの置き場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   nvim --version | Select-Object -First 3
   (Get-Command nvim -All).Source
   nvim --clean --headless "+lua io.stdout:write(vim.fn.stdpath('config'), '\n', vim.fn.stdpath('data'), '\n')" +qa
   ```

   - `NVIM v0.12.5`・`Build type: Release`・`LuaJIT 2.1.…` の 3 行が出ればよい
   - 何も出さずに終わるか、`VCRUNTIME140.dll` が見つからない旨のシステム エラーの窓が出たら、VC++ のランタイムが無い（この項の手順 1 の `VCRuntime`）
     - 窓が出たら、OK で閉じる
   - 2 つ目は `C:\Users\<WIN_USER>\scoop\shims\nvim.exe` の 1 行だけならよい
   - 最後に、設定の置き場所（`C:\Users\<WIN_USER>\AppData\Local\nvim`）とデータの置き場所（`…\AppData\Local\nvim-data`）の 2 行が出る（[AlmaLinux 10 の初期設定の「Neovim の設定ファイル」](almalinux-setup.md#neovim-の設定ファイル)）

### lazygit

1. 管理者ではないことと、scoop・git・extras のバケット・ほかの lazygit を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     Extras     = if (Get-Command scoop -ErrorAction SilentlyContinue) { [bool](scoop bucket list | Where-Object Name -eq 'extras') } else { $false }
     Lazygit    = (Get-Command lazygit -All -ErrorAction SilentlyContinue).Source -join ', '
   } | Format-List
   ```

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`True` なら、窓を閉じて、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 のとおりに開き直す
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 1・2 で入れる
   - `Git` は `C:\Program Files\Git\cmd\git.exe` ならよい。空か違う場所なら、先に [Git for Windows](#git-for-windows)
   - ほかの場所（winget の `JesseDuffield.lazygit` など）が出たら、外してから始める
   - `Extras : True` なら、extras のバケットはもうある（[Neovim](#neovim)の手順 3 で足した）。この項の手順 2 は飛ばす

1. extras のバケットが無いときだけ、scoop に足す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop bucket add extras
   scoop bucket list
   ```

   - `The extras bucket was added successfully.` が出て、一覧に `main` と `extras` の行が出ればよい

1. scoop で lazygit を入れる。

   ```powershell
   scoop install lazygit
   ```

   - `'lazygit' (0.66.0) was installed successfully!` の形の行が出ればよい
   - `'lazygit' (0.66.0) is already installed.` の形なら、もう入っている（[Neovim](#neovim)の手順 3 で入る。何も変えない）

1. 自分用の設定（[ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit)）を入れる。

   - [その README の「導入方法」](https://github.com/ryo-aoki-pc/lazygit#導入方法)の Windows の例のブロックを、この窓に貼る（`%LOCALAPPDATA%\lazygit` に直接 clone する。シンボリックリンクにはしない）
   - `custom` と `C:\Users\<WIN_USER>\AppData\Local\lazygit` が出れば、入っている
   - lazygit を起動する（この項の手順 6）前に入れる。先に起動すると、できた状態ファイルごと `lazygit.bak` に退避される

1. 版と、設定の置き場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   lazygit --version
   lazygit --print-config-dir
   (Get-Command lazygit -All).Source
   ```

   - 1 行目に `version=0.66.0, os=windows, arch=amd64` を含む行が出ればよい
   - 2 行目は `C:\Users\<WIN_USER>\AppData\Local\lazygit`（[AlmaLinux 10 の初期設定の「lazygit の設定ファイル」](almalinux-setup.md#lazygit-の設定ファイル)）
   - 最後は `C:\Users\<WIN_USER>\scoop\shims\lazygit.exe` の 1 行だけならよい

1. 確かめ用の git のリポジトリで、lazygit を起動して確かめる。

   ```powershell
   git init --quiet "$env:TEMP\lazygit-check"
   if (-not (Test-Path -LiteralPath "$env:TEMP\lazygit-check\.git")) { Write-Error '中断: 確かめ用のリポジトリ（%TEMP%\lazygit-check）を作れない' } else {
     Set-Location -LiteralPath "$env:TEMP\lazygit-check"
     lazygit
   }
   ```

   - `中断:` と出たら、lazygit は起動していない（git が呼べるかを、この項の手順 1 で確かめ直す）
   - 初回に `Thanks for using lazygit...` の案内が出たら Enter で閉じる
   - Status・Files・Branches・Commits などの欄が出ればよい（空のリポジトリなので、一覧は空）
   - ほかのリポジトリで確かめるなら、そのフォルダーに `Set-Location` してから `lazygit` を打つ（git 管理外のフォルダーで起動すると、リポジトリを作るか聞かれる）
   - **注意**: Windows PowerShell から起動した lazygit の `e` キーは、git の `core.editor` と環境変数 `VISUAL`・`EDITOR` などが無いと `vim` で開こうとして失敗する
     - [Neovim を既定のエディタにする（任意）](#neovim-を既定のエディタにする任意)で `nvim` にし、新しい窓で lazygit を起動し直す
     - Git Bash から起動したときは、共通の bash 設定が `nvim` にしてある
   - `q` で閉じる
   - `%TEMP%\lazygit-check` は、要らなければ手で消す
     - 消す前に `Set-Location ~` で出る
   - **ほかのブロックは、`q` で閉じてから貼る**（続けて貼ると lazygit への操作として食われる）

### yazi

1. 変数を設定する。

   ```powershell
   $YAZI_EXTRAS = @('ffmpeg', '7zip', 'jq', 'poppler', 'fd', 'ripgrep', 'fzf', 'resvg', 'imagemagick')   # プレビューと検索に使う。@() にすると yazi 本体だけ
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'YAZI_EXTRAS = {0}' -f ($YAZI_EXTRAS -join ' ')
   ```

   - **編集が必須の変数は無い**
   - 最小構成にするなら、`$YAZI_EXTRAS = @()` にする
   - 減らして 1 つだけにするときも、`@('fd')` の形のままにする
   - 最後の行で値を読み戻して確かめる
   - **新しい PowerShell を開いたら**、先にこのブロックを貼り直す

1. 管理者ではないことと、scoop・`file.exe`・VC++ のランタイム・ほかの yazi・設定を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell  = $PSVersionTable.PSVersion.ToString()
     Admin       = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop       = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git         = (Get-Command git -ErrorAction SilentlyContinue).Source
     FileExe     = Test-Path -LiteralPath 'C:\Program Files\Git\usr\bin\file.exe'
     VCRuntime   = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
     Yazi        = (Get-Command yazi -All -ErrorAction SilentlyContinue).Source -join ', '
     YaziFileOne = [Environment]::GetEnvironmentVariable('YAZI_FILE_ONE', 'User')
     Config      = Test-Path -LiteralPath "$env:APPDATA\yazi\config"
   } | Format-List
   ```

   - `PowerShell : 5.1.…`・`Admin : False`・`FileExe : True` が出ればよい。`Admin : True` なら、窓を閉じて、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 のとおりに開き直す（この項の手順 1 も貼り直す）
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に[アプリを入れる](#アプリを入れる)の手順 1・2 で入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でないか、`FileExe : False` なら、先に [Git for Windows](#git-for-windows)
   - `VCRuntime : False` なら、[WezTerm](#wezterm)の手順 2 を管理者の Windows PowerShell で行ってから、この手順を貼り直す
   - `Yazi` が空なら、yazi は入っていない。`C:\Users\<WIN_USER>\scoop\shims\yazi.exe` だけなら、もう scoop で入っている。ほかの場所が出たら、外してから始める
   - `YaziFileOne` が空なら、この項の手順 4 で入れる。別の値なら、この項の手順 4 で Git for Windows の `file.exe` に上書きされる（元の値は控えておく。ロールバックで戻す）

1. scoop で yazi と、プレビュー・検索に使うツールを入れる。

   ```powershell
   if ($null -eq $YAZI_EXTRAS) { Write-Error '中断: 「yazi」の手順 1 の $YAZI_EXTRAS が無い。手順 1 を貼り直す' } else { scoop install yazi @YAZI_EXTRAS }
   ```

   - アプリごとに `'yazi' (26.9.1) was installed successfully!` の形の行が出ればよい。入っていたものは `is already installed.` の形の行を出して飛ばす
   - `'ripgrep' suggests installing 'extras/vcredist2022'.` などの `suggests installing` の行は、入れなくてよい
   - `中断:` と出たら、何も入れていない（新しい窓では、この項の手順 1 を貼り直す。yazi 本体だけにするなら `$YAZI_EXTRAS = @()`）
   - scoop の `file` は入れない

1. ユーザーの環境変数 `YAZI_FILE_ONE` を Git for Windows の `file.exe` にする。

   ```powershell
   if (-not (Test-Path -LiteralPath 'C:\Program Files\Git\usr\bin\file.exe')) { Write-Error '中断: C:\Program Files\Git\usr\bin\file.exe が無い（「Git for Windows」で入れる）' } else {
     [Environment]::SetEnvironmentVariable('YAZI_FILE_ONE', 'C:\Program Files\Git\usr\bin\file.exe', 'User')
     $env:YAZI_FILE_ONE = [Environment]::GetEnvironmentVariable('YAZI_FILE_ONE', 'User')
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'YAZI_FILE_ONE = {0}' -f $env:YAZI_FILE_ONE
   }
   ```

   - `YAZI_FILE_ONE = C:\Program Files\Git\usr\bin\file.exe` が出ればよい（何度貼ってもよい）
   - 今の窓にも入れる。ほかの窓は開き直してから効く（WezTerm は新しいタブから）
   - `中断:` と出たら、何も変えていない

1. 自分用の設定（[ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi)）を入れる。

   - [その README の「インストール」](https://github.com/ryo-aoki-pc/yazi#インストール)の Windows のブロックを、この窓に貼る（`custom` ブランチを `%APPDATA%\yazi\config` に clone する）
   - `custom` が出れば、入っている
   - 同じところにある `YAZI_FILE_ONE` と VC++ のランタイムは、この項の手順 2・4 で済んでいる

1. 版と、yazi から見た環境を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   yazi --version
   ya --version
   ya env
   ```

   - `yazi --version` は `Version: 26.9.1 (…)` と、括弧の中が `windows-x86_64` の `Triple` の行、`ya --version` は `Version: 26.9.1 (…)` の行が出ればよい
   - 何も出さずに終わるか、`VCRUNTIME140.dll` が見つからない旨のシステム エラーの窓が出たら、VC++ のランタイムが無い（この項の手順 2 の `VCRuntime`）
     - 窓が出たら、OK で閉じる
   - `ya env` の `Config` の各行に `C:\Users\<WIN_USER>\AppData\Roaming\yazi\config\…` が出る
     - 設定のフォルダーが無ければ、パスが見つからない旨と `os error 3` が出る
     - フォルダーはあってファイルが無い行は、ファイルが見つからない旨と `os error 2`
   - `Variables` の `YAZI_FILE_ONE` が `Some("C:\\Program Files\\Git\\usr\\bin\\file.exe")` ならよい
   - `Dependencies` の `file` に版が出て、最後の `Routine` の `` `file -bL --mime-type` `` が `text/plain` ならよい
   - `Dependencies` に、`$YAZI_EXTRAS` で入れたもの（ffmpeg・pdftoppm・magick・fzf・fd・rg・7z・resvg・jq）の版が出る

1. WezTerm で新しいタブを開く。

   - 自分用の WezTerm の設定では、新しいタブで Git Bash が開く
   - **次の手順は、開いた Git Bash のタブに貼る**（bash の構文なので、PowerShell には貼らない）

1. そのタブで `y` を確かめ、yazi を開く。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   type -t y
   y
   ```

   - `function` が出ればよい（[AlmaLinux 10 の初期設定の「yazi」](almalinux-setup.md#yazi)の手順 4 と同じ）
   - 最後の `y` で yazi が開く。別のフォルダーへ移って `q` で閉じると、Git Bash もそのフォルダーへ移る（`Q` なら移らない）
   - **次の手順は、yazi を閉じて、この項の手順 1 の PowerShell に戻ってから貼る**（続けて貼ると yazi への操作として食われる）

1. yazi を起動して確かめる。

   ```powershell
   yazi
   ```

   - プレビューを確かめるには、PDF・動画・画像・書庫のあるフォルダーで右のペインを見る
   - 画像のプレビューは、WezTerm（nightly）か Windows Terminal（1.22.10352.0 以降）の中で出る。conhost の窓では出ない
   - [表示と入力](#表示と入力)の手順 6 で既定の端末を Windows Terminal にした PC では、この窓も Windows Terminal で開く
   - `q` で閉じる
   - **ほかのブロックは、`q` で閉じてから貼る**（続けて貼ると yazi への操作として食われる）

### Claude Code

1. 変数を設定する。

   ```powershell
   $CC_CHANNEL = 'latest'                # 追従するチャンネル。latest（出た版をすぐ配る）か stable（約 1 週間遅れ）。<CC_CHANNEL>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'CC_CHANNEL = {0}' -f $CC_CHANNEL
   ```

   - **編集が必須の変数は無い**。既定の `latest`（最新版）でよければ、そのまま貼る
   - 大きな不具合のある版を避けたいなら `stable` にする（[AlmaLinux 10 の初期設定の「Claude Code」](almalinux-setup.md#claude-code)の手順 1 の `CC_CHANNEL` と同じ意味）
   - 最後に値を読み戻して確かめる
   - 変数はその PowerShell の中だけで有効。使うのはこの項の手順 3 だけ

1. Claude Code と Git for Windows があるか、64 ビットの PowerShell かを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [Environment]::Is64BitProcess
   Get-Command claude -All -ErrorAction SilentlyContinue | Format-Table Source
   Test-Path "$env:USERPROFILE\.local\bin\claude.exe"
   Get-Command git -ErrorAction SilentlyContinue | Format-Table Source
   Test-Path 'C:\Program Files\Git\bin\bash.exe'
   ```

   - `True`、（claude は何も出ずに）`False`、`C:\Program Files\Git\cmd\git.exe`、`True` の順に出ればよい
   - 最初が `False` なら、32 ビットの PowerShell（x86）を開いている。窓を閉じて、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 のとおりに開き直す（「Windows PowerShell (x86)」は開かない）
   - claude の行が `C:\Users\<WIN_USER>\.local\bin\claude.exe` だけで、3 つ目が `True` なら、もう native installer で入っている。この項の手順 3 は入れ直しになる（設定とログインは残る）
   - claude の行にほかの場所（WinGet・npm・scoop で入れたものなど）が出たら、そちらを先に外す（[注意点](extra/windows-setup.md#注意点)）
   - `WindowsApps` の `Claude.exe` が出たら、古い Claude Desktop が `claude` の名前を取っている。Claude Desktop を最新にする（公式の Troubleshoot installation）
   - git が出ず、最後が `False` なら、Git for Windows が無い。先に [Git for Windows](#git-for-windows)を通す

1. Claude Code を公式の native installer で入れる。

   ```powershell
   if (-not $CC_CHANNEL) {
     Write-Error '「Claude Code」の手順 1 の $CC_CHANNEL が空'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     & ([scriptblock]::Create((Invoke-RestMethod -Uri https://claude.ai/install.ps1))) $CC_CHANNEL
   }
   ```

   - `Claude Code successfully installed!` と版（`Version: 2.1.288` など）の後に、最後に `Installation complete!`（前に絵文字の ✅ が付く）が出ればよい
   - `Setup notes:` に `Native installation exists but C:\Users\<WIN_USER>\.local\bin is not in your PATH.` と出ても、この項の手順 4 で足すので、ここでは何もしない
   - 赤いエラー（`Checksum verification failed`、`Failed to download binary` など）が出たら、そこで止まっている。[注意点](extra/windows-setup.md#注意点)と公式の [Troubleshoot installation](https://code.claude.com/docs/en/troubleshoot-install) を見る

1. 自分のユーザーの PATH に `%USERPROFILE%\.local\bin` が無ければ足す。

   ```powershell
   & {
     $bin = "$env:USERPROFILE\.local\bin"
     $entries = @([Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ })
     if (-not (Test-Path -LiteralPath "$bin\claude.exe")) { Write-Error "中断: $bin\claude.exe が無い（「Claude Code」の手順 3 で入っていない）"; return }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($entries | Where-Object { $_.TrimEnd('\') -eq $bin }) {
       "PATH に $bin はもうある"
     } else {
       [Environment]::SetEnvironmentVariable('Path', (($entries + $bin) -join ';'), 'User')
       "PATH に $bin を足した"
     }
     [Environment]::GetEnvironmentVariable('Path', 'User') -split ';'
   }
   ```

   - `PATH に C:\Users\<WIN_USER>\.local\bin を足した`（か `はもうある`）の後に、自分のユーザーの PATH が 1 行ずつ出て、その中に `C:\Users\<WIN_USER>\.local\bin` があればよい
   - 何度貼ってもよい（あれば足さない）

1. 開いている Windows PowerShell を閉じ、新しく開き直す。

   - ウィンドウを閉じ（`exit` と打ってもよい）、[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1 と同じように、管理者ではない Windows PowerShell を開く（「Windows PowerShell (x86)」は開かない）
   - この項の手順 1 の変数は、この後は使わない
   - **次の手順は、開き直した PowerShell に貼る**（前の PowerShell の `PATH` には、`.local\bin` が無いことがある）

1. Claude Code の場所・版・署名と、導入の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Command claude -All | Format-Table Source
   claude --version
   $sig = Get-AuthenticodeSignature -LiteralPath "$env:USERPROFILE\.local\bin\claude.exe"
   '{0}  {1}' -f $sig.Status, $sig.SignerCertificate.Subject
   claude doctor
   ```

   - `claude` の場所は `C:\Users\<WIN_USER>\.local\bin\claude.exe` の 1 行だけ
   - `2.1.288 (Claude Code)` のように版が出る（`stable` を選んだら、`latest` より古い版）
   - 署名の行が `Valid  CN="Anthropic, PBC", O="Anthropic, PBC", ...` で始まればよい。`Valid` でなければ使わずに、ロールバックの Claude Code の手順で消す
   - `claude doctor` に `Running: native (...)`・`Auto-updates: enabled`・`Auto-update channel: latest`（`stable` を選んだら `stable`）・`No installation issues found.` が出ればよい

1. `claude` を起動し、最初の設定とブラウザでのログインを行う。

   ```powershell
   claude
   ```

   - 文字の色の組み合わせ（`Choose the text style that looks best with your terminal`）を選んで Enter
   - `Select login method:` で `Claude account with subscription`（Pro / Max / Team / Enterprise）を選ぶ。Console のアカウントなら `Anthropic Console account`
   - 既定のブラウザ（Firefox）が開くので、claude.ai にログインして承認する。ブラウザが開かなければ、`c` で URL をコピーしてブラウザに貼る
   - ブラウザにコードが出たら、端末の `Paste code here if prompted >` に貼る
   - 端末に `Login successful` が出たら Enter。続く案内とフォルダーの信頼の確認（↓ で `Yes, I trust this folder`）に答えると、セッションが始まる
   - 前にログインしたことがある（`%USERPROFILE%\.claude` が残っている）なら、ログインは聞かれない。別のアカウントにするときは、セッションの中で `/login`
   - `/exit` で終える
   - **認証情報（トークン・コード）はこの文書に載せない**
   - **次の手順は、`/exit` で Claude Code を終えてから貼る**（続けて貼ると Claude Code への入力として食われる）

1. ログインしたかを確かめる。

   ```powershell
   claude auth status --text
   ```

   - `Login method: Claude Max account` のように、プランの行が出ればよい（ほかにメールアドレスと組織の行も出る）
   - `Not logged in. Run claude auth login to authenticate.` なら、ログインしていない。この項の手順 7 をやり直す
   - このコマンドの後ろに、別のコマンドを続けて貼らない

### Codex CLI

1. 既存の Codex が入っていないか確かめる。

   ```powershell
   Get-Command codex -All -ErrorAction SilentlyContinue
   ```

   - 新規の PC なら何も出ない
   - パスが出たら、元の導入方法を確認してから進める
   - `CODEX_HOME`・`CODEX_INSTALL_DIR`・`CODEX_RELEASE` は変えない（この項は、既定の場所への新規の standalone インストールを前提にする。ロールバックもその場所を消す）

1. 公式の standalone インストーラーで Codex CLI を入れる。

   ```powershell
   & ([scriptblock]::Create((Invoke-RestMethod -Uri 'https://chatgpt.com/codex/install.ps1')))
   ```

   - `Codex CLI … installed successfully.` を確認する
   - `Start Codex now?` と聞かれたら `n` で答える
   - **次の手順は、インストーラーが終わり、PowerShell のプロンプトに戻ってから貼る**

1. 実行ファイルと版を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Command codex -All
   codex --version
   ```

   - `Source` がこの項の手順 2 の場所で、`codex-cli …` が出ることを確認する

1. 開いている Windows PowerShell を閉じ、新しく開き直す。

   - [WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1と同じように、管理者ではない Windows PowerShell（5.1）を開く
   - 新しい窓でも `codex --version` が通ることを確認する
   - 見つからない場合は、Windows Terminal など親のアプリも閉じて開き直す

1. ChatGPT でのログインを始める。

   ```powershell
   codex login
   ```

   - ブラウザが開く。自動で開かなければ、端末に出た URL を同じ PC のブラウザで開く
   - ブラウザの無いホストでは、この項の手順 5・6 の代わりに[AlmaLinux 10 の初期設定の「Codex CLI をブラウザの無いホストでログインする」](almalinux-setup.md#codex-cli-をブラウザの無いホストでログインする)を通す（同じコマンドを PowerShell に貼る）

1. ブラウザで ChatGPT にログインし、Codex との接続を承認する。

   - 利用するアカウント・ワークスペースを選ぶ
   - **次の手順は、端末でログインの成功を確認し、PowerShell のプロンプトに戻ってから貼る**

1. ログイン状態を確かめる。

   ```powershell
   codex login status
   ```

   - ChatGPT でログイン済みであることを確認する

1. 確認用のディレクトリで Codex を起動する。

   ```powershell
   New-Item -ItemType Directory -Path "$env:USERPROFILE\codex-sandbox" -Force | Out-Null
   Set-Location "$env:USERPROFILE\codex-sandbox"
   git init
   codex
   ```

   - 作業場所の確認が出たら、`codex-sandbox` であることを確認する
   - Windows sandbox の設定を求められたら案内に従う。推奨の `elevated` sandbox の初回設定には管理者の承認が必要（普段の Codex は通常のユーザーで動かす）
   - 入力欄に「このディレクトリの状態を説明してください。ファイルは変更しないでください」と入力し、応答を確認する
   - 終了するときは `/quit` を入力する
   - **次の手順は、Codex を終了して PowerShell のプロンプトに戻ってから貼る**

### Grok Build

1. 既存の Grok が入っていないか確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Command grok, agent -All -ErrorAction SilentlyContinue
   Test-Path "$env:USERPROFILE\.grok"
   ```

   - 新規の PC なら、`False` だけが出る
   - パスか `True` が出たら、元の導入方法を確かめてから進める（WinGet の `xAI.GrokBuild` で入れた Grok なら、WinGet で更新する）

1. 公式のインストーラーで Grok Build を入れる。

   ```powershell
   & ([scriptblock]::Create((Invoke-RestMethod -Uri 'https://x.ai/cli/install.ps1')))
   ```

   - `Grok … installed to C:\Users\<WIN_USER>\.grok\bin\grok.exe` を確かめる
   - 初回は `Added C:\Users\<WIN_USER>\.grok\bin to your User PATH.` も出る
   - **次の手順は、インストーラーが終わり、PowerShell のプロンプトに戻ってから貼る**

1. 実行ファイルと版を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Command grok -All
   grok --version
   ```

   - `Source` がこの項の手順 2 の場所で、`grok …` の版が出ることを確かめる

1. 開いている Windows PowerShell を閉じ、新しく開き直す。

   - [WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 1と同じように、管理者ではない Windows PowerShell（5.1）を開く
   - 新しい窓でも `grok --version` が通ることを確かめる
   - 見つからない場合は、Windows Terminal など親のアプリも閉じて開き直す

1. ブラウザでのログインを始める。

   ```powershell
   grok login
   ```

   - ブラウザが開く。開かなければ、端末に出た URL を同じ PC のブラウザで開く
   - ブラウザの無いホストでは、この項の手順 5・6 の代わりに[AlmaLinux 10 の初期設定の「Grok Build をブラウザの無いホストでログインする」](almalinux-setup.md#grok-build-をブラウザの無いホストでログインする)を通す（同じコマンドを PowerShell に貼る）

1. ブラウザで grok.com のアカウントにログインし、Grok Build との接続を承認する。

   - ブラウザに出たコードが、端末のコードと同じであることを確かめてから承認する
   - **次の手順は、端末でログインの成功を確かめ、PowerShell のプロンプトに戻ってから貼る**

1. ログインを確かめる。

   ```powershell
   grok models
   ```

   - `You are not authenticated.` が出なければ、ログインできている（[AlmaLinux 10 の初期設定の「Grok Build」](almalinux-setup.md#grok-build)の手順 6 と同じ）

1. 確認用のディレクトリで Grok を起動する。

   ```powershell
   New-Item -ItemType Directory -Path "$env:USERPROFILE\grok-sandbox" -Force | Out-Null
   Set-Location "$env:USERPROFILE\grok-sandbox"
   git init
   grok
   ```

   - フォルダーを信頼するか聞かれたら、`grok-sandbox` であることを確かめて信頼する
   - 入力欄に「このディレクトリの状態を説明してください。ファイルは変更しないでください」と入力し、応答を確かめる
   - 終了するときは `/quit` を入力する
   - **次の手順は、Grok を終了して PowerShell のプロンプトに戻ってから貼る**

### Codex・Grok のプラグイン

1. Node.js 18.18 以上があるか確かめ、無いときだけ scoop で入れる（プラグインが使う）。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $node = Get-Command node -ErrorAction SilentlyContinue
     if ($node -and [version]((node --version) -replace '^v', '') -ge [version]'18.18') {
       'Node.js がある: {0}（{1}）' -f (node --version), $node.Source
     } else {
       scoop install nodejs-lts
     }
   }
   ```

   - `Node.js がある:` と版と場所が出たら、何も入れていない（[Neovim](#neovim)の手順 3 で入った scoop の `nodejs` などを使う）。この項の手順 2 は飛ばす
   - 入れたときは、`'nodejs-lts' (…) was installed successfully!` が出ればよい

1. この項の手順 1 で nodejs-lts を入れたときだけ、PowerShell を閉じ、スタートメニューから開き直す。

   - 開き直した窓で `node --version` が通ることを確かめる
   - **次の手順は、開き直した PowerShell に貼る**

1. Claude Code に、OpenAI の Codex のプラグインと xAI の Grok Build のプラグインを入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   claude plugin marketplace add openai/codex-plugin-cc
   claude plugin marketplace add xai-org/grok-build-plugin-cc
   claude plugin install codex@openai-codex
   claude plugin install grok-build@xai-grok-build
   claude plugin list
   ```

   - 見方は、[AlmaLinux 10 の初期設定の「Codex・Grok のプラグイン」](almalinux-setup.md#codexgrok-のプラグイン)の手順 2 と同じ

---

## Wake on LAN を使う（任意）

- 電源を切った（シャットダウンした）この PC を、LAN の別の PC から起こせるようにする。有線 LAN だけ（Wi-Fi では使えない）
- 前提: [PC 全体の設定](#pc-全体の設定)の手順 7（休止状態を切ると、高速スタートアップも切れる）と同じ項の手順 8（アダプターの省電力）。この節の手順 2〜4・8 は、この節の手順 1 で開く管理者の Windows PowerShell（5.1）に貼る
- **この節の手順 4 で再起動して UEFI の画面に入り、この節の手順 5 は UEFI の画面、この節の手順 6 はこの PC、この節の手順 7 は LAN の別の PC で行う**
- Windows の側の値は Microsoft の文書の標準の名前（`*WakeOnMagicPacket`）だけを変える。アダプターに独自の項目があれば、この節の手順 3 の表で確かめる

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. 変数を設定する。

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # 有線 LAN の接続（自動）。<LAN_IF>
   'LAN_IF = {0}' -f $LAN_IF
   ```

   - Wi-Fi の名前が出たら、`$LAN_IF = 'イーサネット'` のように有線 LAN の名前に直す

1. アダプターのマジック パケットでの起動を有効にし、MAC アドレスを表示する。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error 'この節の手順 2 の $LAN_IF が空'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Set-NetAdapterAdvancedProperty -Name $LAN_IF -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 1 -NoRestart
     Get-NetAdapterAdvancedProperty -Name $LAN_IF | Where-Object { $_.RegistryKeyword -like '*Wake*' -or $_.DisplayName -like '*Wake*' } | Format-Table DisplayName, DisplayValue, RegistryKeyword
     Get-NetAdapter -Name $LAN_IF | Format-List Name, InterfaceDescription, MacAddress
   }
   ```

   - 表に `*WakeOnMagicPacket` の行があり、`DisplayValue` が有効の旨（`Enabled` か「有効」）になればよい
   - `MacAddress` の値を控える（この節の手順 7 で使う）
   - `*WakeOnMagicPacket` が無い旨のエラーが出たら、このアダプターは標準の名前を持たない。表のほかの `Wake` の項目（「Shutdown Wake-On-Lan」など）を、デバイス マネージャーのアダプターの「詳細設定」で有効にする

1. 再起動して、UEFI の設定の画面に入る。

   ```powershell
   shutdown.exe /r /fw /t 0
   ```

   - すぐに再起動し、UEFI（BIOS）の設定の画面が開く
   - `入力された環境オプションが見つかりませんでした。(203)` が出て再起動しないときは、スタートメニューの電源から再起動し、起動の直後に機種のキー（F2・Del など）を押して UEFI の設定の画面に入る
   - **次の手順は、UEFI の設定の画面が開いてから行う**

1. UEFI の設定の画面で、Wake on LAN を有効にして保存し、Windows を起動する。

   - 項目の名前と場所は機種ごとに違う（「Wake on LAN」「Power On By PCI-E」「Resume by LAN」など）。機種の説明書で確かめる
   - 保存して終える（Save & Exit）と、Windows が起動する
   - 「ErP」「Deep Sleep」などの、電源を切ったときの消費を減らす項目が有効だと、Wake on LAN が効かないことがある

1. この PC を、スタートメニューの電源の「シャットダウン」で切る。

   - 有線 LAN のケーブルはつないだままにする

1. LAN の別の PC から、この PC の MAC アドレスあてにマジック パケットを送り、この PC が起動することを確かめる。

   - AlmaLinux 10 などの Python があるマシンでは、`python3 -c "import socket; m = bytes.fromhex('<MAC>'.replace('-', '').replace(':', '')); s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1); s.sendto(b'\xff' * 6 + m * 16, ('255.255.255.255', 9))"` で送れる（`<MAC>` はこの節の手順 3 の値）
   - 起動しなければ、この節の手順 3 の表の項目と、UEFI の設定を見直す
   - 元に戻すときは、この節の手順 8

1. 元に戻すときは、管理者の PowerShell で、マジック パケットでの起動を切る。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error 'この節の手順 2 の $LAN_IF が空'
   } else {
     Set-NetAdapterAdvancedProperty -Name $LAN_IF -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 0 -NoRestart
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetAdapterAdvancedProperty -Name $LAN_IF -RegistryKeyword '*WakeOnMagicPacket' | Format-Table DisplayName, DisplayValue
   }
   ```

   - 新しい PowerShell なら、先にこの節の手順 2 を貼る
   - UEFI の Wake on LAN も、この節の手順 4・5 と同じように入って切る

---

## リモートから再起動する手段を増やす（任意）

> [!IMPORTANT]
> - この節は[実施手順](#実施手順)を通した後に行う。少なくとも[ネットワークとリモート](#ネットワークとリモート)の手順 1（LAN をプライベート）が要る。確実に戻すには[PC 全体の設定](#pc-全体の設定)の手順 7（放置で眠らない）・同じ項の手順 8（アダプターの省電力を切る）・[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 5（自動サインイン）
> - 手段は独立しているので、要るものだけ行う（「〜したいときだけ」の手順は飛ばしてよい）。この節の手順 2〜7・撤去の手順は、この節の手順 1 で開く管理者の Windows PowerShell（5.1）に貼る
> - **別の PC で動かすトリガーのコマンドは、その PC で実行する**（AlmaLinux のシェルか、別の Windows の PowerShell）

- リモートの操作ができなくなったときに備えて、再起動の経路を増やす。1 つが死んでも別の経路で立ち直せるようにする
- 既にある接続からの再起動（この節の手順にはしない）
  - SSH でつながるなら、ログインして `Restart-Computer`（Administrators の一員の SSH のセッションは昇格済みで、UAC は要らない。[OpenSSH サーバー](#openssh-サーバー)）。sshd は再起動の後に自動で起動する
  - RDP でつながるなら、スタートメニューの電源の「再起動」か `Restart-Computer`（[ネットワークとリモート](#ネットワークとリモート)の手順 2 で有効。再起動の後はロック画面に戻るが、また入れる）
  - [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md) のセッションからも再起動できるが、そのタスクはトリガーが無いので再起動の後は戻らない。戻すにはこの節の手順 7
- この節で足す手段: クラッシュ時の自動再起動（この節の手順 3）・別の PC からのネットワーク再起動（この節の手順 4・5）・ネットワークが切れたときの自動再起動（この節の手順 6）
- 戻すときは、この節の手順 8〜12（入れた手段のものだけ）

> [!WARNING]
> - この節の手順 4・5 は、LAN の別の PC から、このユーザー（管理者）の資格情報で再起動できる口を開ける。`LocalAccountTokenFilterPolicy` を 1 にして、ローカル・Microsoft アカウントのネットワークログオンに完全な管理者の権限を与える（UAC のリモート制限が緩む）。人が触れる場所や、信用できない LAN にある PC では行わない
> - この節の手順 6 の見張りタスクは、相手（ルーターなど）がずっと落ちていると再起動を繰り返す（稼働 60 分未満は再起動しない歯止めがある）

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. 変数を設定する（どちらも自動。見張りタスクを使わないなら `WATCHDOG_HOST` は要らない）。

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # ほかの PC とつながる LAN の接続（自動）。<LAN_IF>
   $WATCHDOG_HOST = if ($LAN_IF) { (Get-NetIPConfiguration -InterfaceAlias $LAN_IF).IPv4DefaultGateway.NextHop | Select-Object -First 1 } else { '' }   # 見張りタスクが生死を見る相手（自動で既定ゲートウェイ）。<WATCHDOG_HOST>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'LAN_IF = {0}' -f $LAN_IF
   'WATCHDOG_HOST = {0}' -f $WATCHDOG_HOST
   ```

   - `LAN_IF` に Wi-Fi の名前が出たら、`$LAN_IF = 'イーサネット'` のように有線 LAN の名前に直す
   - `WATCHDOG_HOST` は、LAN の中でいつも応答する相手に変えてもよい（既定ゲートウェイ以外にするとき）

1. クラッシュ（ブルースクリーン）で止まったときに自動で再起動する設定を確かめる（既定で有効）。

   ```powershell
   $k = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'
   if ((Get-ItemProperty -Path $k -ErrorAction SilentlyContinue).AutoReboot -ne 1) { Set-ItemProperty -Path $k -Name AutoReboot -Type DWord -Value 1 }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k | Format-List AutoReboot
   ```

   - `AutoReboot : 1` が出ればよい

1. 別の PC から OS 越しに再起動したいときだけ、SMB のリモートシャットダウンを開ける。

   ```powershell
   Set-NetFirewallRule -Name FPS-SMB-In-TCP -Enabled True -Profile Private
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name LocalAccountTokenFilterPolicy -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Name FPS-SMB-In-TCP | Format-Table Name, Enabled, Profile, Direction, Action
   Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' | Format-List LocalAccountTokenFilterPolicy
   ```

   - `FPS-SMB-In-TCP … True  Private  Inbound  Allow` と `LocalAccountTokenFilterPolicy : 1` が出ればよい
   - 別の PC で動かすトリガー（`<WIN_IP>`・`<WIN_HOST>` はこの PC、`<WIN_USER>` は管理者）
     - AlmaLinux 10 から: `net rpc shutdown -r -f -t 0 -I <WIN_IP> -U '<WIN_USER>%<PASS>'`（`net` が無ければ `sudo dnf install -y samba-common-tools`）
     - 別の Windows から: `net use \\<WIN_HOST>\IPC$ /user:<WIN_HOST>\<WIN_USER>`（パスワードを聞かれる）でこの PC の資格情報を渡してから、`shutdown /r /f /t 0 /m \\<WIN_HOST>` を打つ
     - 別の Windows から送り終わったら、`net use \\<WIN_HOST>\IPC$ /delete` を打つ
   - `net use` は、パスワードを聞く前に `\\<WIN_HOST>\IPC$ のパスワードまたはユーザー名が無効です。` を出すが、そのまま入れてよい（`コマンドは正常に終了しました。` になればよい）
   - `net use` をせずに `shutdown /m` を打つと、送る側のユーザーの資格情報で送られ、`アクセスが拒否されました。(5)` で止まる（この PC に無いユーザーや、Microsoft アカウントでサインインした PC から送ったとき）
   - **注意**: この手順は、節のリードの `[!WARNING]` のとおり管理の口を LAN に開ける

1. 別の Windows から PowerShell で再起動したいときだけ、WinRM（PowerShell リモート処理）を有効にする。

   ```powershell
   Set-NetFirewallRule -Name WINRM-HTTP-In-TCP -Profile Public
   Enable-PSRemoting -Force -SkipNetworkProfileCheck
   Set-NetFirewallRule -Name WINRM-HTTP-In-TCP -Enabled True -Profile Private
   Disable-NetFirewallRule -Name WINRM-HTTP-In-TCP-NoScope -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Group '@FirewallAPI.dll,-30267' | Format-Table Name, Enabled, Profile, Direction, Action
   ```

   - `WINRM-HTTP-In-TCP` が `True  Private` で、`WINRM-HTTP-In-TCP-NoScope` が `False` になればよい
   - 別の Windows から送る前に、送る側の管理者の PowerShell で、この PC を `TrustedHosts` に足す（ドメインに入っていない PC は、足していないと `TrustedHosts 構成設定に追加されている必要があります` の旨のエラーで止まる）
     - `WSMan:\localhost` は WinRM のサービスが動いていないと使えないので、止まっていれば先に `Start-Service WinRM` を行う
     - 足す前の値を `(Get-Item WSMan:\localhost\Client\TrustedHosts).Value` で控えてから、`Set-Item WSMan:\localhost\Client\TrustedHosts -Value <WIN_HOST> -Concatenate -Force` を行う
     - 戻し方は、この節の手順 9 の箇条書き
   - 別の Windows で動かすトリガー: `Invoke-Command -ComputerName <WIN_HOST> -Credential <WIN_USER> -ScriptBlock { Restart-Computer -Force }`
     - 管理者ではない PowerShell でよい
     - `<WIN_USER>` には、コンピューター名を付けなくてよい
     - `-ComputerName` には、`TrustedHosts` に足したのと同じ名前を書く
     - エラー無しに数秒で戻り、この PC が再起動すればよい

1. ネットワークが切れたときに自分で再起動させたいときだけ、見張りのタスクを登録する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない（この節の手順 1 から）'; return }
     if (-not $WATCHDOG_HOST) { Write-Error '中断: この節の手順 2 の $WATCHDOG_HOST が空'; return }
     $dir = 'C:\ProgramData\setup-notes'
     New-Item -ItemType Directory -Path $dir -Force | Out-Null
     $body = @'
   $ErrorActionPreference = 'SilentlyContinue'
   $target = '__WATCHDOG_HOST__'
   $key = 'HKLM:\SOFTWARE\setup-notes\net-watchdog'
   $limit = 6
   if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
   if (((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalMinutes -lt 60) {
     Set-ItemProperty -Path $key -Name Fails -Value 0 -Type DWord
     return
   }
   if (Test-Connection -ComputerName $target -Count 3 -Quiet) {
     Set-ItemProperty -Path $key -Name Fails -Value 0 -Type DWord
     return
   }
   $fails = [int](Get-ItemProperty -Path $key -Name Fails -ErrorAction SilentlyContinue).Fails + 1
   if ($fails -ge $limit) {
     Set-ItemProperty -Path $key -Name Fails -Value 0 -Type DWord
     Restart-Computer -Force
   } else {
     Set-ItemProperty -Path $key -Name Fails -Value $fails -Type DWord
   }
   '@
     Set-Content -LiteralPath "$dir\net-watchdog.ps1" -Value ($body.Replace('__WATCHDOG_HOST__', $WATCHDOG_HOST)) -Encoding ASCII
     $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$dir\net-watchdog.ps1`""
     $trigger = New-ScheduledTaskTrigger -AtStartup
     $trigger.Repetition = (New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650)).Repetition
     $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
     $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
     Register-ScheduledTask -TaskName 'net-watchdog' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ScheduledTask -TaskName 'net-watchdog' | Format-List TaskName, State
   }
   ```

   - `net-watchdog  Ready` が出ればよい
   - 登録しただけでは動かない。次に起動したときから動く
   - **注意**: 相手がずっと落ちていると再起動を繰り返す（節のリードの `[!WARNING]`）。`$limit` を増やすと、再起動までの猶予が延びる

1. Remote Control を再起動の後も使いたいときだけ、タスクをログオン時に自動で始まるようにする。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if (-not (Get-ScheduledTask -TaskName 'claude-remote-control' -ErrorAction SilentlyContinue)) { Write-Error '中断: claude-remote-control のタスクが無い（先に Claude Code の Remote Control（Windows）を設定する）'; return }
     $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
     Set-ScheduledTask -TaskName 'claude-remote-control' -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $me) | Out-Null
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     (Get-ScheduledTask -TaskName 'claude-remote-control').Triggers | Format-Table -AutoSize
   }
   ```

   - 前提: [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md) を設定済みで、この PC のデスクトップに同じユーザーでサインインする（[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 5 の自動サインイン）
   - ログオンのトリガーが 1 つ表示されればよい。次にそのユーザーでサインインしたときから、タスクが自動で始まる

1. 元に戻すときは（この節の手順 4 を行ったとき）、SMB のリモートシャットダウンを閉じる。

   ```powershell
   Set-NetFirewallRule -Name FPS-SMB-In-TCP -Enabled False
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Name FPS-SMB-In-TCP | Format-Table Name, Enabled, Profile
   ```

   - `FPS-SMB-In-TCP … False` になればよい
   - `LocalAccountTokenFilterPolicy` は、この節の手順 5 の WinRM と共有している。戻すのはこの節の手順 10

1. 元に戻すときは（この節の手順 5 を行ったとき）、WinRM を無効にする。

   ```powershell
   Disable-PSRemoting -Force
   Stop-Service -Name WinRM -ErrorAction SilentlyContinue
   Set-Service -Name WinRM -StartupType Manual
   Get-NetFirewallRule -Group '@FirewallAPI.dll,-30267' | Disable-NetFirewallRule
   Set-NetFirewallRule -Name WINRM-HTTP-In-TCP -Profile Public
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Group '@FirewallAPI.dll,-30267' | Format-Table Name, Enabled, Profile
   ```

   - 最後の表の規則が、すべて `False` になればよい（WinRM のサービスも止まる）
   - `WINRM-HTTP-In-TCP` の `Profile` が、既定の `Public` に戻ればよい
   - `Disable-PSRemoting` はセッションの構成を無効にするだけなので、サービスの停止・規則の無効化はこの手順で行う
   - `Enable-PSRemoting` が作ったリスナーの設定は残る。サービスが止まり、規則も無効なので、待ち受けない
   - この節の手順 5 の注意で、送る側の `TrustedHosts` に足したときは、送る側の管理者の PowerShell で控えた値に戻す
     - 送る側の WinRM のサービスが止まっていれば（送る側を再起動した後など）、先に `Start-Service WinRM` を行う
     - `Set-Item WSMan:\localhost\Client\TrustedHosts -Value '<控えた値>' -Force` を行う（空だったなら `-Value ''`）
     - 足す前にサービスが止まっていたなら、続けて `Stop-Service WinRM` を行う
   - `LocalAccountTokenFilterPolicy` はこの手順では戻さない（この節の手順 10）

1. 元に戻すときは（この節の手順 4 もこの節の手順 5 も使わないとき）、UAC のリモート制限を元に戻す。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name LocalAccountTokenFilterPolicy -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' | Format-List LocalAccountTokenFilterPolicy
   ```

   - `LocalAccountTokenFilterPolicy : 0` になればよい（管理者のリモートログオンが、既定の制限に戻る）
   - この節の手順 4・5 のどちらかを使い続けるなら、この手順は行わない

1. 元に戻すときは（この節の手順 6 を行ったとき）、見張りのタスクと記録を消す。

   ```powershell
   Unregister-ScheduledTask -TaskName 'net-watchdog' -Confirm:$false
   Remove-Item -Path 'HKLM:\SOFTWARE\setup-notes\net-watchdog' -Recurse -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath 'C:\ProgramData\setup-notes\net-watchdog.ps1' -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ScheduledTask -TaskName 'net-watchdog' -ErrorAction SilentlyContinue
   ```

   - 何も出なければよい（タスクが消えた）
   - 空になったキー `HKLM:\SOFTWARE\setup-notes` とフォルダー `C:\ProgramData\setup-notes` は残る。ほかに使っていなければ、手で消してよい

1. 元に戻すときは（この節の手順 7 を行ったとき）、Remote Control のタスクのトリガーを外す。

   - [Claude Code の Remote Control（Windows）](extra/windows-claude-remote-control.md#ロールバック)のロールバックでタスクごと消す。トリガーの無い形で使い続けるなら、同書の[実施手順](windows-claude-remote-control.md#実施手順)の手順 5 で入れ直す

---

## プライバシーと広告の表示を切る（任意）

- 自分のユーザーの設定で、広告 ID・Web サイトに渡す言語リスト・診断データを使った提案・手書き入力と入力の改善・フィードバックの問い・オンライン音声認識・検索のクラウドと履歴・エクスプローラーの同期プロバイダーの通知を切る（[表示と入力](#表示と入力)の手順 3 と[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 2 の続き）
- 前提: [実施手順](#実施手順)を通した後に行う。この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る（管理者の権限は要らない）
- **この節の手順 3 でサインアウトしてサインインし直し、この節の手順 4・6 は設定の画面で行う**
- **ポリシー（`HKLM` や `HKCU\Software\Policies`）には書かない**。ポリシーを置くと、設定の画面の切り替えが灰色になり、「組織によって管理」の表示が出るため
- 値の多くは Microsoft の文書に無く、広く使われているもの（[参考資料](reference/windows-setup.md)・[検証記録](verification/windows-setup.md)）
- 戻すときは、この節の手順 5・6（行った手順のものだけ）

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）

1. 自分のユーザーで、プライバシーと広告の設定を切る（元の値はファイルに控える）。

   ```powershell
   & {
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\privacy-before.csv'
     $set = @(
       @('HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo', 'Enabled', 0),
       @('HKCU:\Control Panel\International\User Profile', 'HttpAcceptLanguageOptOut', 1),
       @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy', 'TailoredExperiencesWithDiagnosticDataEnabled', 0),
       @('HKCU:\Software\Microsoft\Input\TIPC', 'Enabled', 0),
       @('HKCU:\Software\Microsoft\Siuf\Rules', 'NumberOfSIUFInPeriod', 0),
       @('HKCU:\Software\Microsoft\Siuf\Rules', 'PeriodInNanoSeconds', 0),
       @('HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy', 'HasAccepted', 0),
       @('HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings', 'IsMSACloudSearchEnabled', 0),
       @('HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings', 'IsAADCloudSearchEnabled', 0),
       @('HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings', 'IsDeviceSearchHistoryEnabled', 0),
       @('HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced', 'ShowSyncProviderNotifications', 0)
     )
     $old = foreach ($s in $set) { $key = Get-Item -LiteralPath $s[0] -ErrorAction SilentlyContinue; [pscustomobject]@{ Path = $s[0]; Name = $s[1]; Value = [string](Get-ItemProperty -LiteralPath $s[0] -ErrorAction SilentlyContinue).($s[1]); Kind = $(if ($key -and ($key.GetValueNames() -contains $s[1])) { [string]$key.GetValueKind($s[1]) } else { '' }) } }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $rec) { "控えはもうある（書き換えない）: $rec" } else {
       New-Item -ItemType Directory -Path (Split-Path -Path $rec) -Force | Out-Null
       $old | Export-Csv -LiteralPath $rec -NoTypeInformation -Encoding UTF8
       "控えた: $rec"
     }
     for ($i = 0; $i -lt $set.Count; $i++) {
       $p, $n, $v = $set[$i]
       if (-not (Test-Path -LiteralPath $p)) { New-Item -Path $p -Force | Out-Null }
       Set-ItemProperty -LiteralPath $p -Name $n -Type DWord -Value $v
       '{0}\{1}: {2} -> {3}' -f (Split-Path -Path $p -Leaf), $n, $old[$i].Value, (Get-ItemProperty -LiteralPath $p).$n
     }
   }
   ```

   - `控えた:` か `控えはもうある` の行と、`AdvertisingInfo\Enabled: 1 -> 0` の形の 11 行が出て、`->` の右がすべて `0`（`HttpAcceptLanguageOptOut` だけ `1`）ならよい
   - `->` の左は元の値（空なら値が無かった）。初めて貼ったときに `%LOCALAPPDATA%\setup-notes\privacy-before.csv` に控え、2 回目からは書き換えない（この節の手順 5 で使う）
   - `IsDeviceSearchHistoryEnabled` は、0 と 1 のどちらがオフかで資料が食い違う。この節の手順 4 の画面で確かめる
   - 多くは、この節の手順 3 でサインインし直した後に効く

1. サインアウトして、同じユーザーでサインインし直す。

   - スタートメニューのユーザーのアイコンから「サインアウト」を選ぶ（スタートメニューの電源から再起動してもよい）
   - **次の手順は、サインインし、この節の手順 1 と同じ方法で管理者ではない窓を開いてから貼る**

1. 設定の「プライバシーとセキュリティ」を開き、切り替えを確かめ、残りを画面で切る。

   ```powershell
   Start-Process 'ms-settings:privacy'
   ```

   - 「全般」（新しいビルドでは「おすすめとオファー」）で、広告 ID と言語リストの切り替えがオフ。「設定アプリで通知を表示する」があれば、オフにする
   - 「音声認識」で、「オンライン音声認識」がオフ
   - 「手書き入力と入力の個人用設定」で、「カスタム手書き入力と入力の辞書」をオフにする（覚えた単語の一覧が消える）
   - 「診断とフィードバック」で、「オプションの診断データを送信する」がオンなら、オフにする。「手書き入力と入力の改善」と「カスタマイズされたエクスペリエンス」がオフ、「フィードバックの頻度」が「しない」
   - 新しいビルドでは、「カスタマイズされたエクスペリエンス」は「パーソナライズされたオファー」の名前で別のページにある
   - 「検索のアクセス許可」で、「クラウドのコンテンツ検索」の 2 つと「このデバイスの検索履歴」がオフ。「検索のハイライトを表示する」は、[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 2 の値で灰色になっている
   - この節の手順 2 で書いた項目がオンのまま出ていたら、その画面でオフにする
   - **次の手順は、設定を閉じてから貼る**

1. 元に戻すときは（この節の手順 2 を行ったとき）、控えた元の値に戻す。

   ```powershell
   & {
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\privacy-before.csv'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not (Test-Path -LiteralPath $rec)) { Write-Error "中断: 控えが無い: $rec"; return }
     foreach ($r in Import-Csv -LiteralPath $rec) {
       if ($r.Value -match '^-?[0-9]+$') { Set-ItemProperty -LiteralPath $r.Path -Name $r.Name -Type $(if ($r.Kind -eq 'QWord') { 'QWord' } else { 'DWord' }) -Value ([long]$r.Value) } else { Remove-ItemProperty -LiteralPath $r.Path -Name $r.Name -ErrorAction SilentlyContinue }
       '{0}\{1}: {2}' -f (Split-Path -Path $r.Path -Leaf), $r.Name, (Get-ItemProperty -LiteralPath $r.Path -ErrorAction SilentlyContinue).($r.Name)
     }
   }
   ```

   - 11 行が出て、`:` の右が控えた元の値（元が空なら空）ならよい。元の値が無かったものは消す
   - `中断: 控えが無い` が出たら、この節の手順 6 の画面で戻す
   - 控えのファイルは残る。要らなければ手で消す
   - 効くのは、サインインし直した後

1. 元に戻すときは（この節の手順 4 で切ったものを使うときか、この節の手順 5 で控えが無かったとき）、設定の画面でオンに戻す。

   ```powershell
   Start-Process 'ms-settings:privacy'
   ```

   - この節の手順 4 でオフにした「設定アプリで通知を表示する」・「カスタム手書き入力と入力の辞書」・「オプションの診断データを送信する」のうち、使うものをオンにする
   - この節の手順 5 で `中断: 控えが無い` が出たときは、この節の手順 2 で切った項目（「全般」の広告 ID と言語リスト・「オンライン音声認識」・「手書き入力と入力の改善」・「カスタマイズされたエクスペリエンス」・「フィードバックの頻度」・「検索のアクセス許可」の 3 つ）も、使うものを戻す
   - 同じときに、エクスプローラーの同期プロバイダーの通知も使うなら、フォルダー オプションの「表示」で戻す
   - 消えた辞書（覚えた単語の一覧）は戻らない

---

## 表示・入力・音・ストレージを変える（任意）

- 自分のユーザーの設定で、次のものを変える（[表示と入力](#表示と入力)の手順 1・4・7 の続き）
  - 誤って押しやすいキー: 固定キー・フィルター キー・切り替えキーのショートカット、入力言語とキー配列の切り替え（Alt+Shift・Ctrl+Shift）
  - 窓とエクスプローラー: Alt+Tab の Edge のタブ、タイトル バーのシェイク、左の一覧のギャラリーとホーム、タスクバーの「タスクの終了」
  - アニメーション効果、効果音と起動音、ストレージ センサー
- 前提: [実施手順](#実施手順)を通した後に行う。この節のブロックは、[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る（管理者の権限は要らない）
- 項目は独立しているので、要らない手順は飛ばしてよい（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 1・2・13・14 は飛ばさない）
- [表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 10・12・14 は**画面で行い**、同じ項の手順 13 で**サインアウトしてサインインし直す**
- [表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 11 の**ストレージ センサーは、ごみ箱に 30 日を超えて置いたファイルと一時ファイルを、毎月消す（取り戻せない）**。ごみ箱を置き場に使うなら、[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 11・12 は行わないか、同じ項の手順 12 でごみ箱を「許可しない」にする
- 入力言語の切り替えのキーを切っても、Win+Space で切り替えられる
- 戻すときは、[表示・入力・音・ストレージを元に戻す](#表示入力音ストレージを元に戻す)の手順 1〜9（行った手順のものだけ）。[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 2 で控えた値を使う

### 表示・入力・音・ストレージを控えて変える

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。「Windows PowerShell (x86)」は使わない）

1. 今の値を表示し、ファイルに控える。

   ```powershell
   & {
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\display-before.csv'
     $acc = 'HKCU:\Control Panel\Accessibility'
     $tog = 'HKCU:\Keyboard Layout\Toggle'
     $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
     $cls = 'HKCU:\Software\Classes\CLSID'
     $now = [ordered]@{
       'StickyKeys'                             = (Get-ItemProperty -LiteralPath "$acc\StickyKeys" -ErrorAction SilentlyContinue).Flags
       'Keyboard Response'                      = (Get-ItemProperty -LiteralPath "$acc\Keyboard Response" -ErrorAction SilentlyContinue).Flags
       'ToggleKeys'                             = (Get-ItemProperty -LiteralPath "$acc\ToggleKeys" -ErrorAction SilentlyContinue).Flags
       'Hotkey'                                 = (Get-ItemProperty -LiteralPath $tog -ErrorAction SilentlyContinue).'Hotkey'
       'Language Hotkey'                        = (Get-ItemProperty -LiteralPath $tog -ErrorAction SilentlyContinue).'Language Hotkey'
       'Layout Hotkey'                          = (Get-ItemProperty -LiteralPath $tog -ErrorAction SilentlyContinue).'Layout Hotkey'
       'MultiTaskingAltTabFilter'               = (Get-ItemProperty -LiteralPath $adv).MultiTaskingAltTabFilter
       'DisallowShaking'                        = (Get-ItemProperty -LiteralPath $adv).DisallowShaking
       '{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}' = Test-Path -LiteralPath "$cls\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
       '{f874310e-b6b7-47dc-bc84-b9e6b38f5903}' = Test-Path -LiteralPath "$cls\{f874310e-b6b7-47dc-bc84-b9e6b38f5903}"
       'TaskbarEndTask'                         = (Get-ItemProperty -LiteralPath "$adv\TaskbarDeveloperSettings" -ErrorAction SilentlyContinue).TaskbarEndTask
       'MinAnimate'                             = (Get-ItemProperty -LiteralPath 'HKCU:\Control Panel\Desktop\WindowMetrics' -ErrorAction SilentlyContinue).MinAnimate
       'SoundScheme'                            = (Get-ItemProperty -LiteralPath 'HKCU:\AppEvents\Schemes' -ErrorAction SilentlyContinue).'(default)'
     }
     $rows = foreach ($n in $now.Keys) { [pscustomobject]@{ Name = $n; Value = [string]$now[$n] } }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $rec) { "控えはもうある（書き換えない）: $rec" } else {
       New-Item -ItemType Directory -Path (Split-Path -Path $rec) -Force | Out-Null
       $rows | Export-Csv -LiteralPath $rec -NoTypeInformation -Encoding UTF8
       "控えた: $rec"
     }
     $rows | Format-Table -AutoSize
   }
   ```

   - `控えた:` か `控えはもうある` の行と、13 行の表（`Name` と `Value`）が出ればよい。値が無いものは空
   - 控えは `%LOCALAPPDATA%\setup-notes\display-before.csv`。初めて貼ったときだけ作り、2 回目からは書き換えない（[表示・入力・音・ストレージを元に戻す](#表示入力音ストレージを元に戻す)の手順 2〜5 で使う）

1. 固定キー・フィルター キー・切り替えキーのショートカットを切る。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($k in 'StickyKeys', 'Keyboard Response', 'ToggleKeys') {
     $p = "HKCU:\Control Panel\Accessibility\$k"
     $v = (Get-ItemProperty -LiteralPath $p -ErrorAction SilentlyContinue).Flags
     if ($null -eq $v -or $v -notmatch '^[0-9]+$') { "無い: $k" } else {
       Set-ItemProperty -LiteralPath $p -Name Flags -Type String -Value ([string]([int]$v -band (-bnot 4)))
       '{0}: {1} -> {2}' -f $k, $v, (Get-ItemProperty -LiteralPath $p).Flags
     }
   }
   ```

   - `StickyKeys: 510 -> 506`・`Keyboard Response: 126 -> 122`・`ToggleKeys: 62 -> 58` の形で出ればよい（左の数は PC で違うことがある）
   - `無い:` が出たキーには、何も書かない
   - 効くのは、この項の手順 13 でサインインし直した後
   - **注意**: サインインし直すまで、設定の「アクセシビリティ」→「キーボード」を開かない（今の値で書き戻されることがある）

1. 入力言語とキー配列を切り替えるキー（Alt+Shift・Ctrl+Shift）を切る。

   ```powershell
   & {
     $t = 'HKCU:\Keyboard Layout\Toggle'
     if (-not (Test-Path -LiteralPath $t)) { New-Item -Path $t -Force | Out-Null }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($n in 'Hotkey', 'Language Hotkey', 'Layout Hotkey') {
       $old = (Get-ItemProperty -LiteralPath $t).$n
       Set-ItemProperty -LiteralPath $t -Name $n -Type String -Value '3'
       '{0}: {1} -> {2}' -f $n, $old, (Get-ItemProperty -LiteralPath $t).$n
     }
   }
   ```

   - 3 行とも `->` の右が `3`（割り当てなし）ならよい
   - 効くのは、この項の手順 13 でサインインし直した後

1. Alt+Tab に Edge のタブを出さず、タイトル バーのシェイクを切る。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   Set-ItemProperty -Path $adv -Name MultiTaskingAltTabFilter -Type DWord -Value 3
   Set-ItemProperty -Path $adv -Name DisallowShaking -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $adv | Format-List MultiTaskingAltTabFilter, DisallowShaking
   ```

   - `MultiTaskingAltTabFilter : 3` と `DisallowShaking : 1` が出ればよい
   - 効くのは、この項の手順 13 でサインインし直した後

1. エクスプローラーの左の一覧から、ギャラリーとホームを消す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($g in '{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}', '{f874310e-b6b7-47dc-bc84-b9e6b38f5903}') {
     '既にあった {0}: {1}' -f $g, (Test-Path -LiteralPath "HKCU:\Software\Classes\CLSID\$g")
     reg.exe add "HKCU\Software\Classes\CLSID\$g" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 0 /f
     reg.exe query "HKCU\Software\Classes\CLSID\$g" /v System.IsPinnedToNameSpaceTree
   }
   ```

   - キーごと（`{e88865ea-…}` がギャラリー、`{f874310e-…}` がホーム）に、`既にあった` の行と、成功の 1 行と、`System.IsPinnedToNameSpaceTree    REG_DWORD    0x0` が出ればよい
   - 効くのは、エクスプローラーの窓をすべて閉じて開き直した後
   - 左の一覧を右クリックして「すべてのフォルダーを表示」をオンにすると、どちらも出る
   - 「Windows PowerShell (x86)」で貼ると、別の場所に書かれて効かない

1. タスクバーのアプリの右クリックに「タスクの終了」を出す。

   ```powershell
   $k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -LiteralPath $k -Name TaskbarEndTask -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -LiteralPath $k | Format-List TaskbarEndTask
   ```

   - `TaskbarEndTask : 1` が出ればよい
   - **注意**: 「タスクの終了」はアプリのプロセスを終わらせるので、保存していない内容は失われる

1. アニメーション効果（最小化・最大化のアニメーションも）を切る。

   ```powershell
   & {
     Add-Type -Namespace SetupNotes -Name Spi -MemberDefinition @'
   [StructLayout(LayoutKind.Sequential)] public struct ANIMATIONINFO { public uint cbSize; public int iMinAnimate; }
   [DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
   [DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref int pvParam, uint fWinIni);
   [DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref ANIMATIONINFO pvParam, uint fWinIni);
   '@
     $f = 3   # SPIF_UPDATEINIFILE (1) + SPIF_SENDCHANGE (2)
     [void][SetupNotes.Spi]::SystemParametersInfo(0x1043, 0, [IntPtr]::Zero, $f)   # SPI_SETCLIENTAREAANIMATION: FALSE
     $ai = New-Object 'SetupNotes.Spi+ANIMATIONINFO'
     $ai.cbSize = 8
     $ai.iMinAnimate = 0
     [void][SetupNotes.Spi]::SystemParametersInfo(0x0049, 8, [ref]$ai, $f)   # SPI_SETANIMATION
     $on = 1
     [void][SetupNotes.Spi]::SystemParametersInfo(0x1042, 0, [ref]$on, 0)   # SPI_GETCLIENTAREAANIMATION
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'ClientAreaAnimation : {0}' -f $on
     'MinAnimate          : {0}' -f (Get-ItemProperty -LiteralPath 'HKCU:\Control Panel\Desktop\WindowMetrics').MinAnimate
   }
   ```

   - `ClientAreaAnimation : 0` と `MinAnimate : 0` が出ればよい
   - すぐに効く（開いているアプリの一部は、起動し直した後）

1. 効果音を「サウンドなし」にする（今の設定はファイルに控える）。

   ```powershell
   & {
     $bak = Join-Path $env:LOCALAPPDATA 'setup-notes\appevents.reg'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $bak) { "控えはもうある（書き換えない）: $bak" } else {
       New-Item -ItemType Directory -Path (Split-Path -Path $bak) -Force | Out-Null
       reg.exe export 'HKCU\AppEvents' $bak /y
     }
     if (-not (Test-Path -LiteralPath $bak)) { Write-Error "中断: 控えを作れなかった: $bak"; return }
     $n = 0
     Get-ChildItem -Path 'HKCU:\AppEvents\Schemes\Apps\*\*' | ForEach-Object {
       $cur = Join-Path $_.PSPath '.Current'
       if (Test-Path -LiteralPath $cur) { Set-ItemProperty -LiteralPath $cur -Name '(default)' -Type String -Value ''; $n++ }
     }
     Set-ItemProperty -Path 'HKCU:\AppEvents\Schemes' -Name '(default)' -Type String -Value '.None'
     'Scheme : {0}' -f (Get-ItemProperty -Path 'HKCU:\AppEvents\Schemes').'(default)'
     '空にしたイベント : {0}' -f $n
   }
   ```

   - 控えを作った成功の 1 行（2 回目からは `控えはもうある`）と、`Scheme : .None` と、空にしたイベントの数（1 以上）が出ればよい
   - 控えは `%LOCALAPPDATA%\setup-notes\appevents.reg`。初めて貼ったときだけ作り、2 回目からは書き換えない（[表示・入力・音・ストレージを元に戻す](#表示入力音ストレージを元に戻す)の手順 7 で戻す）
   - 次に鳴る音から効く
   - 後から入れたアプリが足したイベントには、音が入る。気になれば、この手順を貼り直す

1. 起動音も消すときだけ、サウンドの画面を開き、起動音を切る。

   ```powershell
   control.exe 'mmsys.cpl,,2'
   ```

   - 「サウンド」のタブが開く。「Windows スタートアップのサウンドを再生する」のチェックを外し、「OK」を押す
   - 管理者の確認（UAC）が出ることがある
   - 同じタブの「サウンド設定」が「サウンドなし」になっていれば、この項の手順 9 が効いている
   - **次の手順は、サウンドの画面を閉じてから貼る**

1. ストレージ センサーをオンにし、一時ファイルと古いごみ箱を毎月消すようにする（取り戻せない）。

   ```powershell
   & {
     $k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
     $set = [ordered]@{ '01' = 1; '04' = 1; '08' = 1; '256' = 30; '32' = 0; '512' = 0; '2048' = 30 }
     if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($n in $set.Keys) {
       $old = (Get-ItemProperty -LiteralPath $k).$n
       Set-ItemProperty -LiteralPath $k -Name $n -Type DWord -Value $set[$n]
       '{0}: {1} -> {2}' -f $n, $old, (Get-ItemProperty -LiteralPath $k).$n
     }
   }
   ```

   - 7 行が出て、`->` の右が `01`・`04`・`08` は `1`、`256` と `2048` は `30`、`32` と `512` は `0` ならよい
   - `->` の左（元の値）を控える。空なら値が無かった。数があったなら、[表示・入力・音・ストレージを元に戻す](#表示入力音ストレージを元に戻す)の手順 9 で戻した後に、画面で同じにし直す
   - 毎月、一時ファイルと、ごみ箱に 30 日を超えて置いたファイルを消す。ダウンロード フォルダーは消さない
   - **注意**: OneDrive にサインインしているなら、30 日開かないファイルがオンラインだけになりうる。この項の手順 12 で外す

1. この項の手順 11 を行ったときだけ、ストレージ センサーの画面で値を確かめ、OneDrive を外す。

   ```powershell
   Start-Process 'ms-settings:storagepolicies'
   ```

   - 「ユーザー コンテンツの自動クリーンアップ」がオン、「ストレージ センサーを実行するタイミング」が「毎月」、ごみ箱が「30 日」、ダウンロード フォルダーが「許可しない」ならよい
   - 「ローカルで利用可能なクラウド コンテンツ」に OneDrive があれば、「許可しない」にする
   - ごみ箱を置き場に使っているなら、ごみ箱を「許可しない」にする
   - 値が出ていなければ、この項の手順 13 でサインインし直した後に、もう一度開いて確かめる
   - **次の手順は、設定を閉じてから行う**

1. サインアウトして、同じユーザーでサインインし直す。

   - スタートメニューのユーザーのアイコンから「サインアウト」を選ぶ（スタートメニューの電源から再起動してもよい）
   - **次の手順は、サインインし、この項の手順 1 と同じ方法で管理者ではない窓を開いてから貼る**

1. 設定の視覚効果の画面を開き、変わったことを確かめる。

   ```powershell
   Start-Process 'ms-settings:easeofaccess-visualeffects'
   ```

   - 「アニメーション効果」がオフ。オンと出たら、この画面でオフにする
   - Shift を 5 回押しても、固定キー機能をオンにするかを聞く窓が出ない
   - Alt+Shift・Ctrl+Shift を押して離しても、タスクバーの言語の表示が変わらない
   - Edge でタブを 2 つ以上開いて Alt+Tab を押すと、Edge は窓ごとに 1 つだけ並ぶ
   - エクスプローラーの左の一覧に「ギャラリー」と「ホーム」が無い（「すべてのフォルダーを表示」がオフのとき）
   - タスクバーのアプリを右クリックすると「タスクの終了」がある
   - エラーや通知の効果音が鳴らない
   - 行わなかった手順のものは、元のまま
   - **次の手順は、設定を閉じてから貼る**

### 表示・入力・音・ストレージを元に戻す

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 3 を行ったとき）、固定キーなどのショートカットを有効に戻す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($k in 'StickyKeys', 'Keyboard Response', 'ToggleKeys') {
     $p = "HKCU:\Control Panel\Accessibility\$k"
     $v = (Get-ItemProperty -LiteralPath $p -ErrorAction SilentlyContinue).Flags
     if ($null -eq $v -or $v -notmatch '^[0-9]+$') { "無い: $k" } else {
       Set-ItemProperty -LiteralPath $p -Name Flags -Type String -Value ([string]([int]$v -bor 4))
       '{0}: {1} -> {2}' -f $k, $v, (Get-ItemProperty -LiteralPath $p).Flags
     }
   }
   ```

   - `StickyKeys: 506 -> 510` の形で出ればよい
   - 効くのは、サインインし直した後

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 4 を行ったとき）、切り替えのキーを控えた値に戻す。

   ```powershell
   & {
     $t = 'HKCU:\Keyboard Layout\Toggle'
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\display-before.csv'
     $before = @{}
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $rec) { Import-Csv -LiteralPath $rec | ForEach-Object { $before[$_.Name] = $_.Value } } else { "控えが無い（既定の値にする）: $rec" }
     $def = [ordered]@{ 'Hotkey' = '1'; 'Language Hotkey' = '1'; 'Layout Hotkey' = '2' }
     if (-not (Test-Path -LiteralPath $t)) { New-Item -Path $t -Force | Out-Null }
     foreach ($n in $def.Keys) {
       $v = if ($before[$n] -match '^[1-4]$') { $before[$n] } else { $def[$n] }
       Set-ItemProperty -LiteralPath $t -Name $n -Type String -Value $v
       '{0}: {1}' -f $n, (Get-ItemProperty -LiteralPath $t).$n
     }
   }
   ```

   - 3 行に、[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 2 で控えた値が出ればよい（控えが無いか空なら、既定とされる `1`・`1`・`2`）
   - 効くのは、サインインし直した後
   - 画面で戻すなら、設定の「時刻と言語」→「入力」→「キーボードの詳細設定」の「入力言語のホットキー」

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 5 を行ったとき）、Alt+Tab とシェイクの値を控えた値に戻す。

   ```powershell
   & {
     $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\display-before.csv'
     $before = @{}
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $rec) { Import-Csv -LiteralPath $rec | ForEach-Object { $before[$_.Name] = $_.Value } } else { "控えが無い（値を消す）: $rec" }
     foreach ($n in 'MultiTaskingAltTabFilter', 'DisallowShaking') {
       if ($before[$n] -match '^[0-9]+$') { Set-ItemProperty -Path $adv -Name $n -Type DWord -Value ([int]$before[$n]) } else { Remove-ItemProperty -Path $adv -Name $n -ErrorAction SilentlyContinue }
     }
     Get-ItemProperty -Path $adv | Format-List MultiTaskingAltTabFilter, DisallowShaking
   }
   ```

   - 2 つに控えた値が出るか、控えで空だったものが空（既定）になればよい
   - 効くのは、サインインし直した後

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 6 を行ったとき）、ギャラリーとホームを戻す。

   ```powershell
   & {
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\display-before.csv'
     $before = @{}
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $rec) { Import-Csv -LiteralPath $rec | ForEach-Object { $before[$_.Name] = $_.Value } } else { "控えが無い（値だけ消す）: $rec" }
     foreach ($g in '{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}', '{f874310e-b6b7-47dc-bc84-b9e6b38f5903}') {
       if ($before[$g] -eq 'False') { reg.exe delete "HKCU\Software\Classes\CLSID\$g" /f } else { reg.exe delete "HKCU\Software\Classes\CLSID\$g" /v System.IsPinnedToNameSpaceTree /f }
       '残っている {0}: {1}' -f $g, (Test-Path -LiteralPath "HKCU:\Software\Classes\CLSID\$g")
     }
   }
   ```

   - キーごとに、成功の 1 行と `残っている` の行が出ればよい
   - 効くのは、エクスプローラーの窓をすべて閉じて開き直した後

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 7 を行ったとき）、「タスクの終了」の値を控えた値に戻す。

   ```powershell
   & {
     $k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\display-before.csv'
     $before = @{}
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $rec) { Import-Csv -LiteralPath $rec | ForEach-Object { $before[$_.Name] = $_.Value } } else { "控えが無い（値を消す）: $rec" }
     if ($before['TaskbarEndTask'] -match '^[0-9]+$') { Set-ItemProperty -LiteralPath $k -Name TaskbarEndTask -Type DWord -Value ([int]$before['TaskbarEndTask']) } else { Remove-ItemProperty -LiteralPath $k -Name TaskbarEndTask -ErrorAction SilentlyContinue }
     Get-ItemProperty -LiteralPath $k -ErrorAction SilentlyContinue | Format-List TaskbarEndTask
   }
   ```

   - 控えた値が出るか、控えで空なら何も出なければよい（値が無いとオフ）

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 8 を行ったとき）、アニメーション効果を戻す。

   ```powershell
   & {
     Add-Type -Namespace SetupNotes -Name Spi -MemberDefinition @'
   [StructLayout(LayoutKind.Sequential)] public struct ANIMATIONINFO { public uint cbSize; public int iMinAnimate; }
   [DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
   [DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref int pvParam, uint fWinIni);
   [DllImport("user32.dll", SetLastError = true)] public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref ANIMATIONINFO pvParam, uint fWinIni);
   '@
     $f = 3   # SPIF_UPDATEINIFILE (1) + SPIF_SENDCHANGE (2)
     [void][SetupNotes.Spi]::SystemParametersInfo(0x1043, 0, [IntPtr]1, $f)   # SPI_SETCLIENTAREAANIMATION: TRUE
     $ai = New-Object 'SetupNotes.Spi+ANIMATIONINFO'
     $ai.cbSize = 8
     $ai.iMinAnimate = 1
     [void][SetupNotes.Spi]::SystemParametersInfo(0x0049, 8, [ref]$ai, $f)   # SPI_SETANIMATION
     $on = 0
     [void][SetupNotes.Spi]::SystemParametersInfo(0x1042, 0, [ref]$on, 0)   # SPI_GETCLIENTAREAANIMATION
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'ClientAreaAnimation : {0}' -f $on
     'MinAnimate          : {0}' -f (Get-ItemProperty -LiteralPath 'HKCU:\Control Panel\Desktop\WindowMetrics').MinAnimate
   }
   ```

   - `ClientAreaAnimation : 1` と `MinAnimate : 1` が出ればよい（すぐに効く）
   - 設定の「アクセシビリティ」→「視覚効果」の「アニメーション効果」をオンにしてもよい

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 9 を行ったとき）、控えた効果音の設定を書き戻す。

   ```powershell
   & {
     $bak = Join-Path $env:LOCALAPPDATA 'setup-notes\appevents.reg'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not (Test-Path -LiteralPath $bak)) { Write-Error "中断: 控えが無い: $bak"; return }
     reg.exe import $bak
     'Scheme : {0}' -f (Get-ItemProperty -Path 'HKCU:\AppEvents\Schemes').'(default)'
   }
   ```

   - 成功の 1 行と、控えたときのスキーム（ふつうは `.Default`）が出ればよい
   - `中断: 控えが無い` が出たら、サウンドの画面（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 10 と同じ）の「サウンド設定」を「Windows 標準」にする
   - 控えのファイルは残る。要らなければ手で消す

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 10 を行ったとき）、サウンドの画面で起動音を戻す。

   ```powershell
   control.exe 'mmsys.cpl,,2'
   ```

   - 「Windows スタートアップのサウンドを再生する」にチェックを入れ、「OK」を押す
   - **次の手順は、サウンドの画面を閉じてから貼る**

1. 元に戻すときは（[表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 11 を行ったとき）、ストレージ センサーの値を消す。

   ```powershell
   $k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
   foreach ($n in '01', '04', '08', '256', '32', '512', '2048') { Remove-ItemProperty -LiteralPath $k -Name $n -ErrorAction SilentlyContinue }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -LiteralPath $k -ErrorAction SilentlyContinue | Format-List '01', '04', '08', '256', '32', '512', '2048'
   ```

   - 7 つが空ならよい。ストレージ センサーはオフに戻る
   - [表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 11 の `->` の左に数があったなら、設定の「ストレージ センサー」で同じにし直す
   - [表示・入力・音・ストレージを控えて変える](#表示入力音ストレージを控えて変える)の手順 12 で OneDrive やごみ箱を変えたなら、同じ画面で戻す

---

## Edge の常駐をポリシーで止める（任意）

- Edge のスタートアップ ブースト（サインインのときに Edge を裏で起動しておく）と、閉じた後も拡張機能とアプリを動かし続けるバックグラウンドの実行を、PC 全体のポリシーで切る
- 前提: [実施手順](#実施手順)を通した後に行う。この節のブロックは、この節の手順 1 で開く**管理者の** Windows PowerShell（5.1）に貼る（PC 全体のポリシーなので、すべてのユーザーにかかる）
- **この節の手順 2 のポリシーを置くと、Edge に「組織によって管理されている」旨が出て、Edge の設定の 2 つの切り替えが灰色になる**。出したくないなら、この節の手順 2 の代わりにこの節の手順 3（画面だけで切る）を行う
- [サインイン・検索・キーボード](#サインイン検索キーボード)の手順 3 の Edge Update のポリシー（`EdgeUpdate` のキー）とは別のキー（`Edge`）に書く
- **この節の手順 3・4 は Edge の画面で行う**
- 戻すときは、この節の手順 5・6（行った手順のものだけ）

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く。UAC の確認が出たら「はい」

1. Edge のスタートアップ ブーストとバックグラウンドの実行を、ポリシーで切る。

   ```powershell
   $k = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -Path $k -Name StartupBoostEnabled -Type DWord -Value 0
   Set-ItemProperty -Path $k -Name BackgroundModeEnabled -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k | Format-List StartupBoostEnabled, BackgroundModeEnabled
   ```

   - `StartupBoostEnabled : 0` と `BackgroundModeEnabled : 0` が出ればよい
   - 開いている Edge には、開き直すか、`edge://policy` の「ポリシーの再読み込み」で効く
   - [自動起動と標準アプリ](#自動起動と標準アプリ)の手順 1 で止めた `MicrosoftEdgeAutoLaunch_*` の行は、無くなることがある（同じ項の手順 1 と[ロールバックの「表示と入力を戻す」](extra/windows-setup.md#表示と入力を戻す)の手順 8 は、無いものを飛ばす）

1. （この節の手順 2 の代わりに）管理の表示を出したくないときは、Edge の設定の画面で 2 つを切る。

   - Edge のアドレス バーに `edge://settings/system` を入れて開く（「設定」→「システムとパフォーマンス」→「システム」）
   - 「スタートアップ ブースト」をオフにする
   - 「Microsoft Edge が終了してもバックグラウンドの拡張機能およびアプリの実行を続行する」をオフにする

1. Edge で、2 つが切れていることを確かめる。

   - `edge://settings/system` で、2 つがオフになっている（この節の手順 2 を行ったなら、灰色で変えられない）
   - この節の手順 2 を行ったなら、`edge://policy` に `StartupBoostEnabled` と `BackgroundModeEnabled` が、値 `false`・状態 `OK` で出る
   - Edge の窓をすべて閉じると、通知領域に Edge のアイコンが残らない
   - サインインし直した後も `msedge.exe` が見えることがある

1. 元に戻すときは（この節の手順 2 を行ったとき）、管理者の PowerShell で、2 つのポリシーを消す。

   ```powershell
   $k = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
   foreach ($n in 'StartupBoostEnabled', 'BackgroundModeEnabled') { Remove-ItemProperty -Path $k -Name $n -ErrorAction SilentlyContinue }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k -ErrorAction SilentlyContinue | Format-List StartupBoostEnabled, BackgroundModeEnabled
   ```

   - 2 つが空ならよい
   - Edge を開き直すと、2 つの切り替えをまた変えられる

1. 元に戻すときは（この節の手順 3 を行ったとき）、Edge の設定の画面で 2 つをオンに戻す。

   - `edge://settings/system` で、この節の手順 3 でオフにした 2 つをオンにする

---

## CopyQ を使う（任意）

- クリップボードの履歴は、Windows の履歴（Win+V）ではなく、CopyQ に持たせる
- 前提: [Microsoft Store の更新](#microsoft-store-の更新)の手順 1〜7（winget を使えること）。この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る
- **この節の手順 3 で CopyQ を起動し、この節の手順 5・6 は画面で行う**
- CopyQ は窓を持つアプリなので、`copyq.exe` のコマンドの結果は、`| Write-Output` を付けないと出ない
- **CopyQ の履歴は、暗号化されずにディスクに残る**。パスワードなどをコピーするときは、[注意点](extra/windows-setup.md#注意点)を読む
- 戻すときは、この節の手順 7・8

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）

1. CopyQ を、自分のユーザーに入れる。

   ```powershell
   winget install --exact --id hluk.CopyQ --source winget --scope user --accept-source-agreements --accept-package-agreements
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id hluk.CopyQ
   ```

   - 最後の表に `CopyQ` と `hluk.CopyQ` の行が出ればよい
   - 管理者の確認（UAC）は出ないはず。winget が、出るかもしれない旨の行を出すことはある

1. CopyQ を起動する。

   ```powershell
   Start-Process -FilePath "$env:LOCALAPPDATA\Programs\CopyQ\copyq.exe"
   ```

   - 窓を待たずに PowerShell に戻り、通知領域（「^」の中のことがある）に CopyQ のアイコンが出る
   - 見つからない旨のエラーが出たら、前に別の場所へ入れた CopyQ がある。この節の手順 7・8 で外してから始め直す
   - **次の手順は、アイコンが出てから貼る**（起動の前に貼ると、サーバーにつながらない旨が出る）

1. サインインのときに CopyQ が起動するようにし、Windows の履歴（Win+V）がオフかを確かめる。

   ```powershell
   & {
     $copyq = "$env:LOCALAPPDATA\Programs\CopyQ\copyq.exe"
     & $copyq config autostart false | Out-Null
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     & $copyq config autostart true | Write-Output
     Test-Path -LiteralPath (Join-Path ([Environment]::GetFolderPath('Startup')) 'copyq.lnk')
     'EnableClipboardHistory: {0}' -f (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Clipboard' -ErrorAction SilentlyContinue).EnableClipboardHistory
   }
   ```

   - `true`・`True`・`EnableClipboardHistory:` の 3 行が出て、最後の右が空か `0` ならよい
   - 最後の右が `1` なら、Windows の履歴もオン。この節の手順 5 で切る。空か `0` なら、この節の手順 5 は飛ばす

1. Windows の履歴がオンだったときだけ、設定の画面で切る。

   ```powershell
   Start-Process 'ms-settings:clipboard'
   ```

   - 「クリップボードの履歴」をオフにする
   - オフでも、Win+V は Windows のパネルを開く。そこで「有効にする」は押さない
   - **次の手順は、設定を閉じてから行う**

1. CopyQ の設定の画面で、窓を開くグローバル ショートカットを割り当てる。

   - 通知領域の CopyQ のアイコンをクリックして窓を開き、「ファイル」→「設定...」（Ctrl+P）→「ショートカット」→「グローバル」で、「メインウィンドウの表示切り替え」にキーを足して「OK」を押す
   - 次のキーは避ける
     - Win+V（Windows の履歴のパネル）
     - Win+Shift+V と Ctrl+Win+Alt+V（[アプリを入れる](#アプリを入れる)の手順 4 の PowerToys の高度な貼り付け）
     - Ctrl+Shift+V（多くのアプリの、書式なしの貼り付け）
     - Ctrl+Space（[表示と入力](#表示と入力)の手順 7 の IME）
   - Windows キーを含むキーは、OS が予約していて効かないことがある。効かなくても、画面には何も出ない
   - 管理者の窓には、CopyQ から自動では貼れない。クリップボードには入るので、右クリックで貼る

1. 元に戻すときは、サインインのときの起動を外し、CopyQ を止める。

   ```powershell
   & {
     $copyq = "$env:LOCALAPPDATA\Programs\CopyQ\copyq.exe"
     $lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'copyq.lnk'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     & $copyq config autostart false | Write-Output
     Remove-Item -LiteralPath $lnk -ErrorAction SilentlyContinue
     & $copyq exit | Write-Output
     Test-Path -LiteralPath $lnk
   }
   ```

   - `false` と、最後に `False` が出て、通知領域から CopyQ のアイコンが消えればよい
   - CopyQ が動いていなければ、サーバーにつながらない旨が出る。それでも `copyq.lnk` は消える

1. 元に戻すときは、CopyQ を外す。

   ```powershell
   winget uninstall --exact --id hluk.CopyQ --source winget
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id hluk.CopyQ
   ```

   - 最後に、入っているパッケージが見つからない旨が出ればよい
   - 設定と履歴は残る（`%APPDATA%\copyq`。17.0.0 からは `%LOCALAPPDATA%\copyq` も）。要らなければ手で消す（取り戻せない）
   - この節の手順 5 で Windows の履歴を切ったなら、使うときは設定の「システム」→「クリップボード」でオンに戻す

---

## PowerToys のユーティリティを絞る（任意）

- [アプリを入れる](#アプリを入れる)の手順 4 で入れた PowerToys の、既定で有効なユーティリティのうち、使わないものを設定ファイルで切る（同じ項の手順 4 の続き）
- 前提: [アプリを入れる](#アプリを入れる)の手順 4。この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る（管理者の権限は要らない）
- **この節の手順 4・7 は通知領域で PowerToys を終了し、この節の手順 6 は PowerToys の設定の画面で行う**
- PowerToys は起動のときにだけ設定ファイルを読むので、終了してから書き、起動し直す
- 切るユーティリティは好みで選ぶ。この節の手順 2 の `$PT_OFF` は案で、Always On Top・コマンド パレット・PowerRename・File Locksmith・Peek・エクスプローラーのプレビュー・Image Resizer は残す（[参考資料](reference/windows-setup.md)）
- 「起動時に実行」はオン、「常に管理者として実行」はオフのまま変えない。自動の更新の取得も変えない
- Keyboard Manager は使わない（既定でオフ。Caps Lock は[サインイン・検索・キーボード](#サインイン検索キーボード)の手順 4 で変える）
- 戻すときは、この節の手順 7・8

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）

1. 変数を設定する。

   ```powershell
   $PT_OFF = 'FindMyMouse', 'MouseHighlighter', 'FancyZones', 'ColorPicker', 'Measure Tool', 'Awake'   # 切るユーティリティ（設定ファイルの名前）
   $PT_EXE = @((Get-Process -Name PowerToys -ErrorAction SilentlyContinue).Path) + "$env:LOCALAPPDATA\PowerToys\PowerToys.exe", "$env:LOCALAPPDATA\Programs\PowerToys\PowerToys.exe" | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1   # PowerToys.exe の場所（自動）
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'PT_OFF = {0}' -f ($PT_OFF -join ', ')
   'PT_EXE = {0}' -f $PT_EXE
   ```

   - `PT_OFF = FindMyMouse, …` と、`PT_EXE = C:\Users\<WIN_USER>\AppData\Local\PowerToys\PowerToys.exe` の形の 2 行が出ればよい
   - `PT_EXE` が空なら、PowerToys が見つからない。[アプリを入れる](#アプリを入れる)の手順 4 を確かめる
   - `$PT_OFF` の名前は、設定ファイルの名前（空白を含むものがある）。変えるなら、この節の手順 3 の表の `Name` から選ぶ
   - 新しい窓を開いたら、このブロックを貼り直す

1. 今のユーティリティの有効・無効と、自動の起動を確かめる。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $path = Join-Path $env:LOCALAPPDATA 'Microsoft\PowerToys\settings.json'
     if (-not (Test-Path -LiteralPath $path)) { Write-Error "中断: 設定ファイルが無い: $path"; return }
     $s = [IO.File]::ReadAllText($path) | ConvertFrom-Json
     $s.enabled.PSObject.Properties | ForEach-Object { [pscustomobject]@{ Name = $_.Name; Enabled = $_.Value; Off = $PT_OFF -contains $_.Name } } | Format-Table -AutoSize
     foreach ($n in $PT_OFF) { if (-not $s.enabled.PSObject.Properties[$n]) { "無い名前: $n" } }
     'startup: {0} / run_elevated: {1}' -f $s.startup, $s.run_elevated
     Get-ScheduledTask -TaskPath '\PowerToys\' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   }
   ```

   - ユーティリティごとの `Name`・`Enabled`・`Off`（`$PT_OFF` にあるか）の表と、`startup: True / run_elevated: False` と、`Autorun for <WIN_USER>` の行が出ればよい
   - `無い名前:` が出たら、その名前は今の版の設定ファイルに無い（版で名前が変わる）。この節の手順 2 の `$PT_OFF` を表の名前に直して貼り直す
   - `startup` が `False` か、`Autorun for <WIN_USER>` が無いなら、サインインのときに起動しない。`run_elevated` が `True` なら、「常に管理者として実行」がオンになっている。どちらも PowerToys の設定の「全般」で戻す
   - `中断: 設定ファイルが無い` が出たら、PowerToys を 1 度起動してから貼り直す

1. 通知領域の PowerToys を右クリックし、「終了」で閉じる。

   - 通知領域（「^」の中のことがある）の PowerToys のアイコンを右クリックし、「終了」を選ぶ。PowerToys の設定の窓も閉じる
   - **次の手順は、アイコンが消えてから貼る**

1. 設定ファイルで `$PT_OFF` のユーティリティを切り、PowerToys を起動し直す。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Microsoft\PowerToys\settings.json'
     $bak = "$path.windows-setup.bak"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Get-Process -Name PowerToys, PowerToys.Settings -ErrorAction SilentlyContinue) { Write-Error '中断: PowerToys が動いている。この節の手順 4 で終了してから貼り直す'; return }
     if (-not $PT_EXE) { Write-Error '中断: $PT_EXE が空。スタートメニューから PowerToys を起動し、この節の手順 2 を貼り直してから、この節の手順 4 に戻る'; return }
     try { $s = [IO.File]::ReadAllText($path) | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 設定ファイルを読めない: $path"; return }
     if (-not $s.PSObject.Properties['enabled']) { Write-Error "中断: 設定ファイルに enabled が無い: $path"; return }
     $miss = @($PT_OFF | Where-Object { -not $s.enabled.PSObject.Properties[$_] })
     if ($miss.Count) { Write-Error "中断: 設定ファイルに無い名前: $($miss -join ', ')"; return }
     if (Test-Path -LiteralPath $bak) { "控えはもうある（書き換えない）: $bak" } else { Copy-Item -LiteralPath $path -Destination $bak -ErrorAction Stop; "控えた: $bak" }
     foreach ($n in $PT_OFF) { $s.enabled.PSObject.Properties[$n].Value = $false }
     [IO.File]::WriteAllText($path, ($s | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding $false))
     $r = [IO.File]::ReadAllText($path) | ConvertFrom-Json
     foreach ($n in $PT_OFF) { '{0}: {1}' -f $n, $r.enabled.$n }
     Start-Process -FilePath $PT_EXE
   }
   ```

   - `控えた:`（2 回目からは `控えはもうある`）の行と、`FindMyMouse: False` の形の行が `$PT_OFF` の数だけ出て、通知領域に PowerToys のアイコンが戻ればよい
   - 控えは `%LOCALAPPDATA%\Microsoft\PowerToys\settings.json.windows-setup.bak`。控えが無いときだけ作る（この節の手順 8 で使い、書き戻すと消える）
   - `中断: PowerToys が動いている` が出たら、この節の手順 4 に戻る（設定の窓が残っていても止まる）

1. PowerToys の設定の画面で、切ったユーティリティがオフになっていることを確かめる。

   - 通知領域の PowerToys のアイコンを右クリックし、「設定」で設定の窓を開く（ダブルクリックでも開く。1 回のクリックで開くのはクイック アクセス）
   - 「ダッシュボード」で、`$PT_OFF` のユーティリティがオフ、残したものがオンになっている
   - 同じことは、ユーティリティごとのスイッチでもできる（すぐに効く）
   - Peek は「Space で開く」をオンのままにする
   - Find My Mouse を使うなら、起動の方法を「マウスを振る」にする
   - Command Not Found の「インストール」を押すと、PowerShell 7 のプロファイルに行が足される（[PowerShell 7 のプロファイルを設定する（任意）](#powershell-7-のプロファイルを設定する任意)の印は付かない）
   - 見終わったら、設定の窓を閉じる

1. 元に戻すときは、通知領域の PowerToys を右クリックし、「終了」で閉じる。

   - PowerToys の設定の窓も閉じる
   - **次の手順は、アイコンが消えてから貼る**

1. 元に戻すときは、控えた設定ファイルを書き戻し、PowerToys を起動する。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Microsoft\PowerToys\settings.json'
     $bak = "$path.windows-setup.bak"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Get-Process -Name PowerToys, PowerToys.Settings -ErrorAction SilentlyContinue) { Write-Error '中断: PowerToys が動いている。この節の手順 7 で終了してから貼り直す'; return }
     if (-not (Test-Path -LiteralPath $bak)) { Write-Error "中断: 控えが無い: $bak"; return }
     if (-not $PT_EXE) { Write-Error '中断: $PT_EXE が空。スタートメニューから PowerToys を起動し、この節の手順 2 を貼り直してから、この節の手順 7 に戻る'; return }
     Copy-Item -LiteralPath $bak -Destination $path -Force -ErrorAction Stop
     Remove-Item -LiteralPath $bak
     $r = [IO.File]::ReadAllText($path) | ConvertFrom-Json
     foreach ($n in $PT_OFF) { '{0}: {1}' -f $n, $r.enabled.$n }
     Start-Process -FilePath $PT_EXE
   }
   ```

   - `FindMyMouse: True` の形の行（控えたときの値）が出て、通知領域に PowerToys のアイコンが戻ればよい
   - 新しい窓では、先にこの節の手順 2 を貼る
   - 控えた後に画面で変えた PowerToys の設定も、控えたときの値に戻る
   - `中断: 控えが無い` が出たら、スタートメニューから PowerToys を起動し、設定の画面で、切ったユーティリティのスイッチをオンにする
   - 控えのファイルは消える（もう一度この節を通すと、そのときの設定を控え直す）

---

## PowerShell 7 のプロファイルを設定する（任意）

- [アプリを入れる](#アプリを入れる)の手順 5 で入れた PowerShell 7 のプロファイルに、[貼り付けの設定](#貼り付けの設定)の手順 1〜4 と同じ貼り付けの設定と、↑/↓ の履歴の検索と、入っているときだけ zoxide・starship を読む行を足す（[アプリを入れる](#アプリを入れる)の手順 5 の続き）
- 前提: [貼り付けの設定](#貼り付けの設定)の手順 1〜4 と[アプリを入れる](#アプリを入れる)の手順 5。この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る（PowerShell 7 の窓には貼らない）
- 書くのは PowerShell 7 のプロファイル（`Documents\PowerShell\Microsoft.PowerShell_profile.ps1`）で、[貼り付けの設定](#貼り付けの設定)の手順 4 の Windows PowerShell 5.1 のプロファイルとは別のファイル
- 足す行は ASCII の文字だけで、行末に印 `# windows-setup.md` を付ける
- **この節の手順 6 は PowerShell 7 の窓で確かめる**
- zoxide と starship は、入れていなければ読まない。この節は、それらを入れる前に通してよい（入れた後に PowerShell 7 を開き直せば読む）
- Windows Terminal の既定のプロファイルは Windows PowerShell のまま変えない。この文書とほかの手順書のブロックは、引き続き Windows PowerShell 5.1 に貼る
- 戻すときは、この節の手順 7・8（行った手順のものだけ）

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. PowerShell 7 のプロファイルに、貼り付けと履歴の検索のキーと、zoxide・starship を読む行を足す。

   ```powershell
   & {
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     $lines = @(
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine }  # windows-setup.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward }  # windows-setup.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward }  # windows-setup.md'
       'if (Get-Command -Name zoxide -CommandType Application -ErrorAction Ignore) { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }  # windows-setup.md'
       'if (Get-Command -Name starship -CommandType Application -ErrorAction Ignore) { function global:Invoke-Starship-PreCommand { if (Test-Path -Path Function:\__zoxide_hook) { $null = __zoxide_hook } }; Invoke-Expression (& starship init powershell) }  # windows-setup.md'
     )
     if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType File -Path $p -Force -ErrorAction Stop | Out-Null }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($line in $lines) {
       $text = Get-Content -LiteralPath $p -Raw
       if ($text -and $text.Contains($line)) { "すでにある: $line" } else {
         $add = $line
         if ($text -and -not $text.EndsWith("`n")) { $add = "`r`n" + $line }
         Add-Content -LiteralPath $p -Value $add -ErrorAction Stop
         "足した: $line"
       }
     }
     "--- $p"
     Get-Content -LiteralPath $p
   }
   ```

   - 5 行それぞれに `足した:` か `すでにある:` が出て、最後にプロファイルの中身が出ればよい
   - プロファイルは `C:\Users\<WIN_USER>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`（OneDrive でドキュメントをバックアップしていると、`OneDrive` の下）
   - 何度貼ってもよい
   - 開いている PowerShell 7 の窓には、開き直すまで効かない

1. Tab で補完の候補の一覧を出すときだけ、Tab の行を足す。

   ```powershell
   & {
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     $line = 'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete }  # windows-setup.md'
     if (-not (Test-Path -LiteralPath $p)) { Write-Error "中断: プロファイルが無い。この節の手順 2 を先に貼る: $p"; return }
     $text = Get-Content -LiteralPath $p -Raw
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($text -and $text.Contains($line)) { "すでにある: $line" } else {
       $add = $line
       if ($text -and -not $text.EndsWith("`n")) { $add = "`r`n" + $line }
       Add-Content -LiteralPath $p -Value $add -ErrorAction Stop
       "足した: $line"
     }
   }
   ```

   - `足した:` か `すでにある:` が出ればよい
   - Tab で、候補が一覧で出る（矢印で選んで Enter、Esc で取り消す）

1. PowerShell 7 で、実行ポリシーとキーの割り当てを確かめる。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Get-ExecutionPolicy -List | Out-String -Width 120; Import-Module PSReadLine; . $PROFILE; Get-PSReadLineKeyHandler -Bound | Where-Object Key -in 'Ctrl+Enter', 'UpArrow', 'DownArrow', 'Tab' | Format-Table Key, Function -AutoSize | Out-String -Width 120 }
   ```

   - 次のとおりならよい
     - 実行ポリシーの表の `LocalMachine` か `CurrentUser` が `RemoteSigned`
     - キーの表の `Ctrl+Enter` が `AddLine`、`UpArrow` が `HistorySearchBackward`、`DownArrow` が `HistorySearchForward`（この節の手順 3 を行ったなら、`Tab` が `MenuComplete`）
   - `pwsh.exe` が見つからない旨が出たら、[アプリを入れる](#アプリを入れる)の手順 5 を確かめる
   - 実行ポリシーがどれも `Undefined` なら、プロファイルは読まれず、キーは既定のまま（`Ctrl+Enter` が `InsertLineAbove`）。そうでなければ、この節の手順 5 は飛ばす

1. 実行ポリシーがどれも `Undefined` のときだけ、PowerShell 7 の CurrentUser を RemoteSigned にする。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Get-ExecutionPolicy -List }
   ```

   - 表の `CurrentUser` が `RemoteSigned` になればよい
   - この節の手順 4 をもう一度貼って、キーの割り当てを確かめる

1. スタートメニューから PowerShell 7 を開き、キーとプロンプトを確かめる。

   - スタートメニューで「PowerShell」を探し、「Windows PowerShell」ではない「PowerShell」（PowerShell 7）をクリックして開く（一覧の名前に 7 は付かないことがある）
   - 何か打ってから ↑ を押すと、打った文字で始まる履歴だけが出る
   - 打っている途中に、履歴からの候補が薄い文字で出る（PowerShell 7 の既定の予測。→ で受け入れ、F2 で一覧の表示に切り替わる）
   - starship を入れていればプロンプトが starship の形になり、zoxide を入れていれば `z` が使える
   - Ctrl+Alt+? で、キーの割り当ての一覧が出る
   - **次の手順は、PowerShell 7 の窓を `exit` で閉じてから、この節の手順 1 の窓に貼る**

1. 元に戻すときは、PowerShell 7 のプロファイルから、この節で足した行を消す。

   ```powershell
   & {
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     if (-not (Test-Path -LiteralPath $p)) { "プロファイルが無い: $p"; return }
     $bytes = [System.IO.File]::ReadAllBytes($p)
     $enc = if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { [System.Text.Encoding]::Unicode } else { [System.Text.Encoding]::GetEncoding(28591) }
     $text = $enc.GetString($bytes)
     $rest = [regex]::Replace($text, '(?m)^(\uFEFF|\u00EF\u00BB\u00BF)?[^\r\n]*  # windows-setup\.md\r?(\n|$)', '$1')
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($rest -eq $text) { "その行は無い: $p" } elseif ($rest -match '^(\uFEFF|\u00EF\u00BB\u00BF)?\s*$') { Remove-Item -LiteralPath $p; "消した: $p" } else { [System.IO.File]::WriteAllBytes($p, $enc.GetBytes($rest)); "その行だけ消した: $p" }
   }
   ```

   - プロファイルにほかの行が無ければ `消した:`、あれば `その行だけ消した:` が出る
   - 開いている PowerShell 7 の窓には、閉じるまで設定が残る

1. 元に戻すときは（この節の手順 5 を行ったとき）、PowerShell 7 の CurrentUser の実行ポリシーを戻す。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser -Force; Get-ExecutionPolicy -List }
   ```

   - 表の `CurrentUser` が `Undefined` ならよい

---

## Windows Terminal のフォントと貼り付けの警告を変える（任意）

- Windows Terminal（[表示と入力](#表示と入力)の手順 6 で既定の端末にした）の全プロファイルのフォントを HackGen Console NF にし、複数行を貼るときの警告を、要らなければ切る
- 前提: [HackGen Console NF](#hackgen-console-nf)（入れた後にサインインし直すか、[WSL と再起動](#wsl-と再起動)の手順 2 で再起動した後）。この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る
- **この節の手順 5 は Windows Terminal の設定の画面で行う**
- 効くのは Windows Terminal で開く窓（管理者ではない窓と、Win+X の「ターミナル」・「ターミナル (管理者)」）だけ。スタートメニューから管理者として開いた PowerShell（conhost の窓）には効かない
- 管理者ではない窓に複数行のブロックを貼ると、「警告」の窓が出ることがある（Windows PowerShell 5.1 は、角かっこで囲む貼り付けを使わないため）。「強制的に貼り付け」を押す（出さないなら、この節の手順 4）
- コマンドで書くのは `settings.json` だけ。既定のプロファイル（Windows PowerShell）と、選んだらコピーする設定（`copyOnSelect`）は変えない
- 戻すときは、この節の手順 6

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（[表示と入力](#表示と入力)の手順 6 の設定で、Windows Terminal の窓で開く）

1. Windows Terminal の設定ファイルを控え、今のフォントと警告の値を確かめる。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     $bak = "$path.windows-setup.bak"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not (Test-Path -LiteralPath $path)) { Write-Error "中断: 設定ファイルが無い。Windows Terminal を 1 度開いてから貼り直す: $path"; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある。この節の手順 5 の画面で変える: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない。この節の手順 5 の画面で変える: $path"; return }
     if (-not $s.profiles -or $s.profiles -is [array]) { Write-Error '中断: profiles が無いか古い形式（配列）。この節の手順 5 の画面で変える'; return }
     if (Test-Path -LiteralPath $bak) { "控えはもうある（書き換えない）: $bak" } else { Copy-Item -LiteralPath $path -Destination $bak -ErrorAction Stop; "控えた: $bak" }
     [pscustomobject]@{
       Version          = (Get-AppxPackage -Name Microsoft.WindowsTerminal | Select-Object -First 1).Version
       DefaultsFontFace = $s.profiles.defaults.font.face
       MultiLinePaste   = $s.'warning.multiLinePaste'
       DefaultProfile   = $s.defaultProfile
       CopyOnSelect     = $s.copyOnSelect
     } | Format-List
     $s.profiles.list | Where-Object { $_.font.face } | Format-Table name, @{ Name = 'face'; Expression = { $_.font.face } }
   }
   ```

   - `控えた:`（2 回目からは `控えはもうある`）の行と、`Version : 1.25.…` の形の 5 行が出ればよい。`DefaultsFontFace` が空なら、既定のフォント（Cascadia Mono）
   - 控えは `…\LocalState\settings.json.windows-setup.bak`。控えが無いときだけ作る（この節の手順 6 で使い、書き戻すと消える）
   - 最後に表が出たら、そのプロファイルは自分のフォントを持つので、この節の手順 3 の値は効かない（この節の手順 5 の画面で、そのプロファイルを変える）
   - `中断:` が出たら、何も書いていない。この節の手順 5 の画面で変える
   - `Version` が 1.24 より前なら、この節の手順 4 は飛ばす

1. 全プロファイルのフォントを HackGen Console NF にする。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     if (-not (Test-Path -LiteralPath "$path.windows-setup.bak")) { Write-Error '中断: 控えが無い。この節の手順 2 を先に貼る'; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない: $path"; return }
     if (-not $s.profiles -or $s.profiles -is [array]) { Write-Error '中断: profiles が無いか古い形式（配列）'; return }
     if (-not $s.profiles.PSObject.Properties['defaults']) { $s.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) }
     if (-not $s.profiles.defaults.PSObject.Properties['font']) { $s.profiles.defaults | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{}) }
     $s.profiles.defaults.font | Add-Member -NotePropertyName face -NotePropertyValue 'HackGen Console NF' -Force
     [IO.File]::WriteAllText($path, ($s | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'face: {0}' -f ([IO.File]::ReadAllText($path) | ConvertFrom-Json).profiles.defaults.font.face
   }
   ```

   - `face: HackGen Console NF` が出ればよい
   - 保存した直後に、開いているタブにも効く
   - フォントが見つからないと、端末に、フォントが見つからない旨が出て、別のフォントで出る（この節の手順 5 で確かめる）

1. Windows Terminal が 1.24 以降で、複数行を貼るたびに出る警告を出さないときだけ、警告を切る。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     $ver = (Get-AppxPackage -Name Microsoft.WindowsTerminal | Select-Object -First 1).Version
     if (-not $ver -or [version]$ver -lt [version]'1.24') { Write-Error "中断: Windows Terminal の版が 1.24 より前: $ver"; return }
     if (-not (Test-Path -LiteralPath "$path.windows-setup.bak")) { Write-Error '中断: 控えが無い。この節の手順 2 を先に貼る'; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない: $path"; return }
     $s | Add-Member -NotePropertyName 'warning.multiLinePaste' -NotePropertyValue 'never' -Force
     [IO.File]::WriteAllText($path, ($s | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'warning.multiLinePaste: {0}' -f ([IO.File]::ReadAllText($path) | ConvertFrom-Json).'warning.multiLinePaste'
   }
   ```

   - `warning.multiLinePaste: never` が出ればよい
   - **注意**: 信用できない複数行の文字も、確かめずにそのまま貼られて動く
   - 5 KiB を超える文字を貼るときは、別の警告が出ることがある

1. Windows Terminal の設定の画面で、フォントが見つかっていることを確かめる。

   - Windows Terminal の窓で Ctrl+, を押し、「既定値」→「外観」の「フォント スタイル」が `HackGen Console NF` で、「見つからないフォント:」が出ていない
   - 新しいタブを開くと、文字が HackGen になっている
   - この節の手順 2〜4 が `中断:` で止まったときは、この画面でフォント スタイルを選んで「保存」を押す（一覧に無ければ「すべてのフォントの表示」をオン）。警告は「操作」の「改行を貼り付ける際に警告する」を「なし」にする
   - **次の手順は、設定の画面を閉じてから貼る**

1. 元に戻すときは、控えた設定ファイルを書き戻す。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     $bak = "$path.windows-setup.bak"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not (Test-Path -LiteralPath $bak)) { Write-Error "中断: 控えが無い: $bak"; return }
     Copy-Item -LiteralPath $bak -Destination $path -Force -ErrorAction Stop
     Remove-Item -LiteralPath $bak
     $s = [IO.File]::ReadAllText($path) | ConvertFrom-Json
     'face: {0} / warning.multiLinePaste: {1}' -f $s.profiles.defaults.font.face, $s.'warning.multiLinePaste'
   }
   ```

   - 控えたときの値（ふつうは 2 つとも空）が出ればよい。開いているタブにもすぐ効く
   - 控えた後に画面で変えた Windows Terminal の設定も、控えたときに戻る。残すなら、このブロックは貼らず、この節の手順 5 の画面でフォント スタイルと警告を戻す
   - `中断: 控えが無い` が出たら、この節の手順 5 の画面で戻す
   - 控えのファイルは消える（もう一度この節を通すと、そのときの設定を控え直す）

---

## WSL のネットワークをミラーにする（任意）

- WSL 2 のネットワークを、既定の NAT から、Windows と同じ IP を使うミラーに変える（[WSL と再起動](#wsl-と再起動)の手順 1 と[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 3 の続き）
- 前提: [WSL と再起動](#wsl-と再起動)の手順 1 と[WSL の AlmaLinux 10 と自動サインイン](#wsl-の-almalinux-10-と自動サインイン)の手順 3・4。この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る（自分のユーザーの `%USERPROFILE%\.wslconfig` に書く）
- **この節の手順 4・7 の `wsl.exe --shutdown` は、動いているディストリビューションをすべて止める**（WezTerm の WSL のタブも切れる）。WSL の中の作業を保存してから貼る
- ミラーにして変わること
  - WSL からこの PC の Windows のサーバー（[OpenSSH サーバー](#openssh-サーバー)など）には、`127.0.0.1` でつなぐ（`::1` は使えない。LAN の IP あてはつながらないはず）
  - Windows が使っているポートは、WSL の中では使えない。Windows の sshd が 22 番で待っていると、WSL の中の sshd は 22 番を使えない
  - Docker のポートの公開と、一部の VPN には、既知の問題がある（[参考資料](reference/windows-setup.md)）
- 書くのは `networkingMode` だけ。DNS・ファイアウォール・プロキシ・メモリの値は既定のまま。LAN から WSL の中のサーバーに入るための Hyper-V のファイアウォールの規則は、この節では作らない
- 画面で変えるなら、スタートメニューの「Linux 用 Windows サブシステム設定」→「ネットワーク」→「ネットワーク モード」（同じファイルに書く）
- 戻すときは、この節の手順 6・7

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）

1. 今の `.wslconfig` と、WSL の版と、動いているディストリビューションを確かめる。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $env:WSL_UTF8 = '1'
     $p = Join-Path $env:USERPROFILE '.wslconfig'
     if (Test-Path -LiteralPath $p) { "--- $p"; [IO.File]::ReadAllText($p) } else { "無い: $p" }
     wsl.exe --version
     wsl.exe --list --running
   }
   ```

   - `無い:` か、`.wslconfig` の中身が出る
   - `wsl.exe --version` が、WSL の版（`2.…` の形）を出せばよい
   - 最後に、動いているディストリビューションが出る（無ければ、無い旨の行）。この節の手順 4 で止まる
   - 中身の `[wsl2]` に `networkingMode=mirrored` があれば、もうミラー。この節の手順 3 は飛ばす

1. ミラーになっていないときだけ、`.wslconfig` に、ネットワークをミラーにする行を書く（ファイルがあれば控える）。

   ```powershell
   & {
     $path = Join-Path $env:USERPROFILE '.wslconfig'
     $bak = "$path.windows-setup.bak"
     $enc = New-Object System.Text.UTF8Encoding $false
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not (Test-Path -LiteralPath $path)) {
       [IO.File]::WriteAllText($path, "[wsl2]`r`nnetworkingMode=mirrored`r`n", $enc)
       "作った: $path"
     } else {
       $text = [IO.File]::ReadAllText($path)
       if ($text -match '(?im)^[ \t]*networkingMode[ \t]*=') { Write-Error "中断: networkingMode の行がもうある。手で直すか、設定の画面で変える: $path"; return }
       if (Test-Path -LiteralPath $bak) { "控えはもうある（書き換えない）: $bak" } else { Copy-Item -LiteralPath $path -Destination $bak -ErrorAction Stop; "控えた: $bak" }
       $nl = if ($text.Contains("`n") -and -not $text.Contains("`r`n")) { "`n" } else { "`r`n" }
       $re = [regex]'(?im)^([ \t]*\[wsl2\][ \t]*)(?=\r?$)'
       if ($re.IsMatch($text)) { $text = $re.Replace($text, '$1' + $nl + 'networkingMode=mirrored', 1) } else {
         if ($text -and -not $text.EndsWith("`n")) { $text += $nl }
         $text += '[wsl2]' + $nl + 'networkingMode=mirrored' + $nl
       }
       [IO.File]::WriteAllText($path, $text, $enc)
       "足した: $path"
     }
     [IO.File]::ReadAllText($path)
   }
   ```

   - `作った:` か `足した:` の行（ファイルがあったときは、その前に `控えた:`）と、`[wsl2]` の次の行が `networkingMode=mirrored` の中身が出ればよい
   - 控えは `%USERPROFILE%\.wslconfig.windows-setup.bak`。ファイルがあって、控えが無いときだけ作る（この節の手順 6 で使い、戻すと消える）
   - `中断: networkingMode の行がもうある` が出たら、何も書いていない。その行を手で `networkingMode=mirrored` にするか、設定の画面で変える
   - 効くのは、この節の手順 4 で WSL を止めた後

1. WSL を止めて、ミラーで動くことを確かめる。

   ```powershell
   wsl.exe --shutdown
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   wsl.exe --distribution AlmaLinux-10 -- wslinfo --networking-mode
   ```

   - `mirrored` が出ればよい
   - `ミラー化されたネットワーク モードはサポートされていません` の行が出て `nat` なら、この PC ではミラーを使えない（理由はその行に出る）。この節の手順 6・7 で戻す
   - その行が無く `nat` なら、`.wslconfig` が読まれていない（この節の手順 2 で中身を確かめる）
   - `wslinfo` が無い旨が出たら、`wsl.exe --distribution AlmaLinux-10 -- ip -4 -br addr` の IP が、Windows の LAN の IP（`ipconfig`）と同じならミラー
   - WezTerm の WSL のタブは切れているので、開き直す

1. Windows の OpenSSH サーバーを入れたときだけ、WSL から `127.0.0.1` の 22 番に届くことを確かめる。

   ```powershell
   wsl.exe --distribution AlmaLinux-10 -- bash -c 'exec 3<>/dev/tcp/127.0.0.1/22 && head -n 1 <&3'
   ```

   - `SSH-2.0-OpenSSH_for_Windows_` で始まる行が出ればよい
   - WSL から Windows に ssh でつなぐときは、`ssh <WIN_USER>@127.0.0.1` にする（[注意点](extra/windows-setup.md#注意点)の OpenSSH サーバー）
   - `Connection refused` が出たら、Windows の sshd が動いていない（[OpenSSH サーバー](#openssh-サーバー)の手順で確かめる）

1. 元に戻すときは、`.wslconfig` を元に戻す。

   ```powershell
   & {
     $path = Join-Path $env:USERPROFILE '.wslconfig'
     $bak = "$path.windows-setup.bak"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $bak) {
       Move-Item -LiteralPath $bak -Destination $path -Force -ErrorAction Stop
       "控えから戻した: $path"
     } elseif (-not (Test-Path -LiteralPath $path)) {
       "無い: $path"
     } elseif ([IO.File]::ReadAllText($path) -eq "[wsl2]`r`nnetworkingMode=mirrored`r`n") {
       Remove-Item -LiteralPath $path -ErrorAction Stop
       "消した: $path"
     } else {
       Write-Error "中断: この節で作った形ではない。networkingMode の行を手で消す: $path"
     }
   }
   ```

   - `控えから戻した:`（ファイルがあったとき）か `消した:`（この節で作ったとき）が出ればよい
   - 控えた後に設定の画面などで変えた値も、控えたときに戻る
   - `中断:` が出たら、`.wslconfig` をメモ帳で開き、`networkingMode=mirrored` の行を消して保存する
   - 効くのは、この節の手順 7 で WSL を止めた後

1. 元に戻すときは、WSL を止めて、NAT に戻ったことを確かめる。

   ```powershell
   wsl.exe --shutdown
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   wsl.exe --distribution AlmaLinux-10 -- wslinfo --networking-mode
   ```

   - `nat` が出ればよい
   - WSL から Windows のサーバーには、また LAN の IP あてにつなぐ

---

## OpenSSH サーバーに公開鍵でもログインする（任意）

- クライアントで作った鍵で、パスワードを入れずに入れるようにする。パスワード認証は有効のまま
- この節の手順 1・2・5 はクライアントの[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 3 のシェルに、手順 3・4 は Windows の管理者の Windows PowerShell に貼る
- 登録できるのは、Administrators の一員のユーザーの鍵だけ（この節の手順 4 で確かめる。標準ユーザーは[注意点](extra/windows-setup.md#注意点)）
- 登録した鍵を持つ人も、パスワードを知る人と同じく、この PC の管理者として操作できる（[注意点](extra/windows-setup.md#注意点)）

1. クライアントの PC で、鍵ペアが無ければ作る。

   ```bash
   ls ~/.ssh/id_ed25519.pub 2>/dev/null || ssh-keygen -t ed25519
   ```

   - 鍵があれば、`/home/<USER>/.ssh/id_ed25519.pub` と出て何もしない（その鍵を使う）
   - 無ければ、保存先（Enter で既定の `~/.ssh/id_ed25519`）とパスフレーズ（2 回）を聞かれる
   - **次の手順は、パスフレーズを入力し終えてから貼る**（続けて貼るとパスフレーズとして食われる）

1. クライアントの PC で、公開鍵を表示する。

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

   - `ssh-ed25519 AAAA… <USER>@<HOSTNAME>` の 1 行が出る。この 1 行をコピーし、この節の手順 3 で Windows に貼る
   - 公開鍵は秘密ではない。チャットやメールで Windows 側へ渡してもよい

1. Windows の管理者の PowerShell で、変数を設定する（`$PUBKEY` は必ず値を入れる）。

   ```powershell
   $PUBKEY = ''                          # ← この節の手順 2 の 1 行を '' の中に貼る。<PUBKEY>
   ```

   ```powershell
   'PUBKEY = {0}' -f $PUBKEY
   ```

   - 改行を入れずに 1 行のまま貼る
   - 最後に値を読み戻して確かめる
   - **新しい PowerShell を開いたら**、この手順の 2 つのブロックを貼り直してから先へ進む

1. 公開鍵を `administrators_authorized_keys` に登録する。

   ```powershell
   if ($PUBKEY -notmatch '^(ssh-|ecdsa-|sk-)') {
     Write-Error 'この節の手順 3 の $PUBKEY が空か、公開鍵の形でない'
   } elseif (-not (Get-LocalGroupMember -SID S-1-5-32-544 | Where-Object Name -like "*\$env:USERNAME")) {
     Write-Error "$env:USERNAME は Administrators の一員ではない（注意点を見る）"
   } else {
     $f = "$env:ProgramData\ssh\administrators_authorized_keys"
     Add-Content -Path $f -Value $PUBKEY -Encoding ascii
     icacls.exe $f /inheritance:r /grant '*S-1-5-32-544:F' /grant '*S-1-5-18:F'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     icacls.exe $f
   }
   ```

   - 最後の `icacls` に、`NT AUTHORITY\SYSTEM:(F)` と `BUILTIN\Administrators:(F)` の 2 行だけが出ればよい
   - クライアントを足すときは、そのクライアントでこの節の手順 1・2 を行い、この節の手順 3 の `$PUBKEY` を貼り直してから、この節の手順 4 を貼る

1. クライアントの PC で、鍵で入れることを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 「SSH でログインを確かめる」の手順 3 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh -o PasswordAuthentication=no "${WIN_USER}@${WIN_HOST}" whoami
   fi
   ```

   - パスワードを聞かれずに、`<hostname>\<win_user>` が出ればよい（パスフレーズを付けたなら、それを聞かれる）
   - 既定のシェルを Git Bash にした PC では、Git の `whoami` が動き、`<WIN_USER>` だけが出る

---

## OpenSSH サーバーのパスワード認証を切る（任意）

- 鍵を持たない相手からのパスワードを受け付けないようにする（パスワードの総当たりを受け付けない）
- 前提: [OpenSSH サーバーに公開鍵でもログインする（任意）](#openssh-サーバーに公開鍵でもログインする任意)を行い、使うクライアントが鍵で入れること。切った後は、鍵を登録していないクライアント（スマートフォンのアプリなど）からは入れない
- この節の手順 1 は Windows の管理者の Windows PowerShell に、手順 2 はクライアントの[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 3 のシェルに貼る
- パスワード認証に戻すときは、[OpenSSH サーバー](#openssh-サーバー)の手順 4 を貼り直す

1. Windows で、パスワード認証を切り、設定を検査してから sshd を再起動する。

   ```powershell
   $c = "$env:ProgramData\ssh\sshd_config"
   (Get-Content $c) -replace '^#?PasswordAuthentication .*', 'PasswordAuthentication no' | Set-Content $c -Encoding ascii
   & "$env:WINDIR\System32\OpenSSH\sshd.exe" -t
   if ($LASTEXITCODE -eq 0) { Restart-Service -Name sshd } else { Write-Error 'sshd_config に誤りがある（sshd は再起動していない）' }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Select-String -Path $c -Pattern '^PasswordAuthentication', '^Match', 'administrators_authorized_keys'
   ```

   - `…sshd_config:51:PasswordAuthentication no` と、`Match Group administrators` とその次の `AuthorizedKeysFile` の行が出ればよい

1. クライアントの PC で、鍵が無いと入れず、鍵ではコマンドが通ることを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 「SSH でログインを確かめる」の手順 3 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh -o PubkeyAuthentication=no "${WIN_USER}@${WIN_HOST}" true
     ssh "${WIN_USER}@${WIN_HOST}" whoami
   fi
   ```

   - 1 つ目は、パスワードを聞かずに `<WIN_USER>@<WIN_HOST>: Permission denied (publickey,keyboard-interactive).` で失敗すればよい
   - 2 つ目は、`<hostname>\<win_user>` が出ればよい（パスフレーズを付けたなら、それを聞かれる）
     - 既定のシェルを Git Bash にした PC では、Git の `whoami` が動き、`<WIN_USER>` だけが出る

---

## SSH の既定のシェルを Git Bash にする（任意）

- SSH でログインしたとき・コマンドを実行するときのシェルを、cmd.exe から Git for Windows の bash に変える
- 前提: Git for Windows が `C:\Program Files\Git` に入っていること（[Git for Windows](#git-for-windows)）
- この節の手順 1・3 は Windows の管理者の Windows PowerShell に、手順 2 はクライアントの[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 3 のシェルに貼る

1. Windows で、既定のシェルを Git Bash にする。

   ```powershell
   if (-not (Test-Path 'C:\Program Files\Git\bin\bash.exe')) {
     Write-Error 'C:\Program Files\Git\bin\bash.exe が無い（Git for Windows が入っていない）'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     New-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -Value 'C:\Program Files\Git\bin\bash.exe' -PropertyType String -Force | Format-List DefaultShell
   }
   ```

   - `DefaultShell : C:\Program Files\Git\bin\bash.exe` が出ればよい

1. クライアントの PC で、bash になったことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 「SSH でログインを確かめる」の手順 3 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh "${WIN_USER}@${WIN_HOST}" 'echo "$BASH_VERSION $MSYSTEM"; git --version'
     ssh "${WIN_USER}@${WIN_HOST}"
   fi
   ```

   - 鍵を登録していなければ、パスワードを 2 回聞かれる
   - 1 つ目で `5.3.15(1)-release MINGW64` と `git version 2.55.0.windows.3` のような 2 行が出ればよい
   - 2 つ目は、`<WIN_USER>@<HOSTNAME> MINGW64 ~` と `$` のプロンプトになる。`exit` で戻る
   - **注意**: コマンドを実行するときも、Windows 側の `~/.bashrc` が読まれる
   - `Shim: Could not create process …` が出るなら、[scoop のツールを SSH のセッションで使う（任意）](#scoop-のツールを-ssh-のセッションで使う任意)を行う

1. 元に戻すときは、`DefaultShell` を消す。

   ```powershell
   Remove-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell
   ```

   - 何も出ずに終わればよい

---

## scoop のツールを SSH のセッションで使う（任意）

- scoop で入れたツール（`zoxide`・`rg`・`nvim` など）が、SSH のセッションでだけ起動しないときに行う
  - 症状は、scoop の shim の `Could not create process with command …`、Git Bash の `Is a directory`、Windows のエラー 448（信頼されていないマウントポイント）
- 原因は、sshd の緩和策 RedirectionGuard。管理者以外が作ったジャンクションを、SSH のセッションのプロセスはたどれない
  - scoop の `current` と persist のジャンクションは、一般ユーザーの scoop が作るので、この制限に当たる
- この節は、それらのジャンクションを、管理者の PowerShell で同じ向き先のまま作り直す（中身は変えない）
- 前提: scoop が `C:\Users\<WIN_USER>\scoop` に入っていること（[アプリを入れる](#アプリを入れる)の手順 1・2 で入れた形）
- この節の手順 1 は Windows の管理者の Windows PowerShell に、手順 2 はクライアントの[SSH でログインを確かめる](#ssh-でログインを確かめる)の手順 3 のシェルに貼る
- `scoop install`・`scoop update` の後は、新しいジャンクションが一般ユーザーの作ったものになるので、この節の手順 1 を貼り直す

1. Windows で、scoop のジャンクションを管理者で作り直す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ChildItem "$env:USERPROFILE\scoop\apps" -Recurse -Depth 4 -Force -Attributes ReparsePoint -ErrorAction SilentlyContinue |
     Where-Object { $_.LinkType -eq 'Junction' -and (Get-Acl $_.FullName).Owner -notlike '*\Administrators' } |
     ForEach-Object {
       $link = $_.FullName; $target = @($_.Target)[0]; $ro = $_.Attributes -band [IO.FileAttributes]::ReadOnly
       if (Test-Path -LiteralPath $target) {
         attrib.exe -R "$link" /L
         cmd.exe /c rmdir "$link"
         New-Item -ItemType Junction -Path $link -Target $target | Out-Null
         if ($ro) { attrib.exe +R "$link" /L }
         '{0} -> {1}' -f $link, $target
       }
     }
   ```

   - 作り直したジャンクションごとに、`…\scoop\apps\<アプリ>\current -> …\scoop\apps\<アプリ>\<版>` の形の行が出る
   - 作り直すものが無ければ、何も出ない

1. クライアントの PC で、scoop のツールが動くことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 「SSH でログインを確かめる」の手順 3 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh "${WIN_USER}@${WIN_HOST}" 'zoxide --version'
   fi
   ```

   - 鍵を登録していなければ、パスワードを聞かれる
   - `zoxide 0.9.9` のような版が出て、`Shim:` で始まる行が出なければよい（`zoxide` の代わりに、scoop で入れたほかのツールでもよい）

---

## Neovim を既定のエディタにする（任意）

- Windows PowerShell や Windows Terminal から起動するツール（lazygit の `e` キーなど）にも Neovim を使わせるなら、この節の手順 1 でユーザーの環境変数にする
- Git Bash（WezTerm の新しいタブ）では、共通の bash 設定が `EDITOR`・`VISUAL` を `nvim` にする（この節は要らない）
  - 確かめるときは、WezTerm の新しいタブで、[AlmaLinux 10 の初期設定の「Neovim」](almalinux-setup.md#neovim)の手順 4 のブロックを貼る（`. ~/.bashrc` は読み直さない）
- この節のブロックは、[Neovim](#neovim)と同じ管理者ではない Windows PowerShell（5.1）に貼る

1. Windows の PowerShell でも使うように、`EDITOR`・`VISUAL` を `nvim` にする。

   ```powershell
   & {
     $other = @(foreach ($n in 'EDITOR', 'VISUAL') { [Environment]::GetEnvironmentVariable($n, 'User') }) | Where-Object { $_ -and $_ -ne 'nvim' }
     if ($other) { Write-Error "中断: ユーザーの環境変数 EDITOR か VISUAL に、nvim ではない値がある（$($other -join ', ')）" } else {
       foreach ($n in 'EDITOR', 'VISUAL') { [Environment]::SetEnvironmentVariable($n, 'nvim', 'User') }
       "`n$([char]27)[7m 確認 $([char]27)[0m"
       foreach ($n in 'EDITOR', 'VISUAL') { '{0} = {1}' -f $n, [Environment]::GetEnvironmentVariable($n, 'User') }
     }
   }
   ```

   - `EDITOR = nvim` と `VISUAL = nvim` が出ればよい（何度貼ってもよい）
   - `中断:` と出たら、何も変えていない。ほかのエディタを使っているなら、この手順は行わない
   - 効くのは、この後に開いた窓とアプリから（開いている窓には入らない。WezTerm は新しいタブから）

1. 元に戻すときは、ユーザーの環境変数 `EDITOR`・`VISUAL` を消す。

   ```powershell
   foreach ($n in 'EDITOR', 'VISUAL') { if ([Environment]::GetEnvironmentVariable($n, 'User') -eq 'nvim') { [Environment]::SetEnvironmentVariable($n, $null, 'User') } }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($n in 'EDITOR', 'VISUAL') { '{0} = {1}' -f $n, [Environment]::GetEnvironmentVariable($n, 'User') }
   ```

   - `EDITOR = ` と `VISUAL = `（どちらも値が空）が出ればよい
   - 値が `nvim` のときだけ消す（ほかの値は残る）

---

## 更新

- Windows Update は[Windows Update](#windows-update)の手順 1〜8（管理者の窓）、Microsoft Store は[Microsoft Store の更新](#microsoft-store-の更新)の手順 1〜7（通常の窓）を通す。再起動が必要な場合も、自動では再起動しない
- [scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)・[AI エージェントとプラグインを上げる](#ai-エージェントとプラグインを上げる)・[HackGen Console NF を上げる](#hackgen-console-nf-を上げる)は、[Microsoft Store の更新](#microsoft-store-の更新)の手順 1 と同じ、管理者ではない Windows PowerShell（5.1）に貼る。[Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)は、管理者の Windows PowerShell（5.1）に貼る（[PC 全体の設定](#pc-全体の設定)の手順 1 と同じ）
- scoop で入れたもの（シェルのツール・git-delta・GitHub CLI・Neovim・lazygit・yazi と、自分用の Neovim の設定が入れる外部コマンド）は scoop で、winget で入れたもの（UniGet UI・PowerToys・PowerShell 7・Autologon・任意節の CopyQ）は winget で上げる
  - [シェルのツールを入れる](#シェルのツールを入れる)の zoxide は 0.9.9 に止めてあるので、[scoop・winget・WSL を上げる](#scoopwingetwsl-を上げる)の手順 2 では上がらない。直った版が出たかは同じ項の手順 6 で確かめ、出ていれば同じ項の手順 7 で上げる
  - 上げても、git の設定（`~/.gitconfig`）と gh のログイン（資格情報マネージャーと `%APPDATA%\GitHub CLI`）は変わらない
- Firefox・Claude Code・Codex・Grok Build は、自分で新しい版に上がる。待たずに上げるときだけ、それぞれの手順を行う
  - Firefox は、起動している間に新しい版を取り、次に起動したときに入れ替える。閉じている間も、Firefox を起動すると作られるタスク（タスク スケジューラの `\Mozilla\` の `Firefox Background Update <番号>`。7 時間ごと）が上げる。`C:\Program Files` への書き込みは Mozilla Maintenance Service が行うので、管理者の確認（UAC）は出ない。日本語版なので、言語パックは使わない（足すと、閉じている間の更新が止まる。Mozilla の Background Updates の文書）
  - Claude Code（native installer）は、起動したときと動いている間に新しい版を確かめ、裏で入れて、次の起動から新しい版になる（公式の文書）。追う版は[Claude Code](#claude-code)の手順 1 で選んだチャンネルで、動いているセッションは終えるまで古い版のまま
  - Codex は、起動したときに `Update available!` と出たら、`1. Update now` のまま Enter を押すと上がる（Windows 用の公式インストーラーが動く）
  - Grok Build は、対話の画面（`grok`）を起動したときに新しい版を確かめ、自分で上がる
- WezTerm は自分では更新しない。nightly の新しい版が出ても知らせない（WezTerm の更新の確認が見るのは stable のリリースだけで、nightly の版の方が新しいので何も出ない）
  - 上げるのは[Git for Windows・Firefox・WezTerm を上げる](#git-for-windowsfirefoxwezterm-を上げる)の手順 1・5〜7（[WezTerm](#wezterm)の手順 3 を貼り直す。同じ場所の `C:\Program Files\WezTerm` に上書きし、設定ファイルはそのまま）
  - nightly は毎日ビルドし直される。版は main の最後のコミットで決まり、コミットの無い日は同じ版になる
- HackGen Console NF は、上流が sha256 を出していないので、この文書の版と sha256（[HackGen Console NF](#hackgen-console-nf)の手順 2）を確かめて直してから入れ直す（[HackGen Console NF を上げる](#hackgen-console-nf-を上げる)）
- 共通の bash 設定は、WezTerm のタブ（Git Bash）で[AlmaLinux 10 の初期設定の更新](almalinux-setup.md#更新)の手順 1 を貼って上げる
- 自分用の設定（WezTerm・Neovim・lazygit・yazi）は、それぞれのリポジトリの更新で上げる
  - yazi の自分用の設定は上流の版に合わせてある。yazi の版が上がったら、その [README の「上流の新しい版に追従する」](https://github.com/ryo-aoki-pc/yazi#上流の新しい版に追従する)で設定も追う
- SSH のセッションで scoop のツールを使っているなら、scoop で上げた後に[scoop のツールを SSH のセッションで使う（任意）](#scoop-のツールを-ssh-のセッションで使う任意)の手順 1 を、管理者の Windows PowerShell で貼り直す
- UniGet UI の画面からも、scoop と winget のパッケージをまとめて上げられる（UniGet UI と PowerToys は、自分でも新しい版を確かめる）
- CopyQ は、更新のインストーラが閉じた後に起動し直さないことがある。通知領域にアイコンが無ければ、スタートメニューの「CopyQ」から起動する
- Windows の大きな更新（機能の更新）の後は、外したアプリと切った提案が戻ることがある。[表示と入力](#表示と入力)の手順 3 と[自動起動と標準アプリ](#自動起動と標準アプリ)の手順 1〜3 を貼り直す
- 機能の更新の後は、任意節（[プライバシーと広告の表示を切る](#プライバシーと広告の表示を切る任意)・[表示・入力・音・ストレージを変える](#表示入力音ストレージを変える任意)・[Edge の常駐をポリシーで止める](#edge-の常駐をポリシーで止める任意)）の設定も戻ることがある。その節の「元に戻すときは、」より前の手順を貼り直す（控えのファイルは書き換えない）
- VirtualBox・WireGuard は、それぞれの手順書の「Windows 11 の更新」
  - [SSH クライアント（Windows）](windows-ssh-client.md#更新)は「更新」、[Samba の共有のネットワーク ドライブ](samba-client.md#windows-11-の更新)は「Windows 11 の更新」（どちらも、上げるものは無い）

### scoop・winget・WSL を上げる

1. scoop とバケットを上げ、古くなったものを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop update
   scoop status
   ```

   - `scoop update` は `Scoop was updated successfully!` を出す
   - git が無いと `Scoop uses Git to update itself. Run 'scoop install git' and try again.` で止まる。先に [Git for Windows](#git-for-windows)で Git for Windows を入れる
   - `scoop status` は、古いものがあれば名前と版を並べる。`Everything is ok!` なら、この項の手順 2 は飛ばす

1. 古いものがあるときだけ、scoop で入れたものを上げる。

   ```powershell
   scoop update *
   ```

   - アプリごとに `'<名前>' (<版>) was installed successfully!` の形の行が出る
   - 動いているアプリは `Running process detected, skip updating.` で飛ばされる。閉じてから貼り直す
   - SSH のセッションで scoop のツールを使っているなら、[scoop のツールを SSH のセッションで使う（任意）](#scoop-のツールを-ssh-のセッションで使う任意)の手順 1 を、管理者の PowerShell で貼り直す
   - **Neovim の設定やプラグインは更新に追従しない**ので、メジャー更新の後は `:checkhealth` で壊れていないか見る（自分用の設定のプラグインと外部コマンドは、[LazyVimStarter の docs/setup.md の「更新」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#更新)の手順 2・4）

1. winget で入れたものを上げる。

   ```powershell
   foreach ($id in 'Devolutions.UniGetUI', 'Microsoft.PowerToys', 'Microsoft.PowerShell', 'Microsoft.Sysinternals.Autologon', 'hluk.CopyQ') { winget upgrade --exact --id $id --source winget --accept-source-agreements --accept-package-agreements }
   ```

   - それぞれ、新しい版が無ければ更新が見つからない旨の行を出して何もしない
   - 動いている UniGet UI・PowerToys は、インストーラが閉じる
   - 入れていないものは、入っていない旨の行を出すだけ

1. WSL と AlmaLinux 10 を上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   wsl.exe --update
   wsl.exe --distribution AlmaLinux-10 --user root -- dnf -y upgrade
   ```

   - `wsl.exe --update` は、新しい版が無ければ、最新である旨を出す
   - `dnf -y upgrade` の最後に `Complete!` か `Nothing to do.` が出ればよい

1. この文書で PSWindowsUpdate を入れたときだけ、モジュールを更新する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
       Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
     }
     [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
     Update-Module -Name PSWindowsUpdate -Force
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-InstalledModule -Name PSWindowsUpdate | Select-Object Name, Version, InstalledLocation
   }
   ```

   - モジュールの版と場所が出ればよい
   - 次の Windows Update は[Windows Update](#windows-update)の手順 1 で新しく開いた管理者の窓で行う
   - この文書の前から入っていた PSWindowsUpdate は、元の導入方法で管理する

1. zoxide を上げるときは、ブラウザで、Git Bash の記録を直した版が出たかを確かめる。

   - `https://github.com/ajeetdsouza/zoxide/releases` を開く
   - 0.10.0 より新しい版の変更点に、「Bash/Zsh: fix `z` failing on Cygwin/MSYS2」で始まる行があれば、直った版が出ている
   - 無ければ、この項の手順 7 は飛ばす（0.9.9 のまま使う）
   - **次の手順は、管理者ではない Windows PowerShell（5.1）に貼る**

1. Git Bash の記録を直した版が出ているときだけ、zoxide を止めるのをやめて上げる。

   ```powershell
   & {
     scoop update
     $v = (Get-Content -LiteralPath "$env:USERPROFILE\scoop\buckets\main\bucket\zoxide.json" -Raw | ConvertFrom-Json).version
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($v -notmatch '^\d+\.\d+\.\d+$' -or [version]$v -le [version]'0.10.0') { Write-Error "中断: scoop の main のバケットの zoxide はまだ $v。日を置いて、「scoop・winget・WSL を上げる」の手順 6 から"; return }
     scoop unhold zoxide
     scoop update zoxide --force
     zoxide --version
   }
   ```

   - `zoxide is no longer held and can be updated again.` と、`'zoxide' (<版>) was installed successfully!` が出て、最後に新しい版が出ればよい
   - `中断:` が出たら、Releases に出た版が、まだ scoop の main のバケットに入っていない。zoxide は何も変えていない（0.9.9 に止めたまま）
   - `Running process detected, skip updating.` が出たら、上がっていない。Git Bash で開いている `zi` の一覧などを閉じてから、このブロックを貼り直す
   - WezTerm の新しいタブで、[AlmaLinux 10 の初期設定の「シェルのツール」](almalinux-setup.md#シェルのツール)の手順 9・10 を貼って確かめ直す（Windows との違いは、[シェルのツールを入れる](#シェルのツールを入れる)の手順 6 の箇条書き）

### AI エージェントとプラグインを上げる

1. Claude Code をすぐに上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   claude update
   claude --version
   ```

   - 新しい版があれば `Successfully updated from <古い版> to version <新しい版>`、無ければ `Claude Code is up to date (2.1.288)` のように出る
   - 更新の後に `claude` が見つからなくなったら、[注意点](extra/windows-setup.md#注意点)の `claude.exe.old.*` の項を見る

1. 起動中の Codex と Grok を終了する。

   - 端末の Codex と Grok は `/quit` で閉じる
   - 知らせを待たずに上げるときだけ、この項の手順 2〜4 を行う

1. 公式インストーラーをもう一度実行して、Codex CLI を上げる。

   ```powershell
   & ([scriptblock]::Create((Invoke-RestMethod -Uri 'https://chatgpt.com/codex/install.ps1')))
   ```

   - `Start Codex now?` は `n` で答える
   - **次の手順は、PowerShell のプロンプトに戻ってから貼る**
   - 上げた後の版は、`codex --version` で確かめる

1. Grok Build の新しい版を入れ、版を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   grok update
   grok --version
   ```

   - 新しい版が無ければ `Already up to date (…)` と出る

1. 2 つのプラグインのマーケットプレイスとプラグインを上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   claude plugin marketplace update openai-codex
   claude plugin marketplace update xai-grok-build
   claude plugin update codex@openai-codex
   claude plugin update grok-build@xai-grok-build
   claude plugin list
   ```

   - 見方は、[AlmaLinux 10 の初期設定の更新](almalinux-setup.md#更新)の手順 9 と同じ

### HackGen Console NF を上げる

1. HackGen の新しい版が出ているかを確かめる。

   ```powershell
   (Invoke-RestMethod -Uri https://api.github.com/repos/yuru7/HackGen/releases/latest).tag_name
   ```

   - `v2.10.0` なら、新しい版は無い。この項の手順 2 は行わない
   - 違う版なら、[HackGen Console NF](#hackgen-console-nf)の手順 2 の `$ver` と `$sha256` を、その版の zip と、その zip から計算して確認したハッシュ値に合わせて直してから貼る

1. 新しい版にするときだけ、今の版を外してから入れ直す。

   - [ロールバックの「HackGen Console NF を消す」](extra/windows-setup.md#hackgen-console-nf-を消す)の手順 1〜3（登録を消し、サインインし直してから、ファイルを消す）を行う
   - 続けて、直した[HackGen Console NF](#hackgen-console-nf)の手順 2 を貼り、サインアウトしてサインインし直してから、[再起動の後に確かめる](#再起動の後に確かめる)の手順 5 で確かめる

### Git for Windows・Firefox・WezTerm を上げる

1. Remote Control のタスクを動かしているときだけ、先にタスクを止める。

   - [windows-claude-remote-control.md の止める・もう一度始める](windows-claude-remote-control.md#止めるもう一度始める)の手順 1 を行う
   - タスクの Claude Code と WezTerm（中のシェルは Git Bash）は、Git for Windows と WezTerm を上げる間は止めておく。上げた後に、この項の手順 7 で始め直す

1. Git Bash と WezTerm を閉じてから、winget で Git for Windows を上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget upgrade --exact --id Git.Git --source winget --accept-source-agreements --accept-package-agreements
   winget list --exact --id Git.Git --source winget
   ```

   - 上がったら `インストールが完了しました` と出て、`winget list` の `Git.Git` の版が新しくなる
   - 新しい版が無ければ、`利用可能なアップグレードが見つかりませんでした。`（英語の Windows では `No available upgrade found.`）と出る
   - **注意**: Git Bash・WezTerm のタブ（自分用の設定では Git Bash）や、Git の bash を使う SSH のセッション・Claude Code が動いていると、インストーラは入れ替えずに終わるはず
   - 上げた後は、Git Bash を開き直し、[AlmaLinux 10 の初期設定の「Git」](almalinux-setup.md#git)の手順 6 を貼り直す（`pull.ff` が `only` なら同じ項の手順 7 も）

1. Firefox の今の版と、winget に新しい版があるかを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-Item -LiteralPath "$env:ProgramFiles\Mozilla Firefox\firefox.exe").VersionInfo.ProductVersion
   winget list --exact --id Mozilla.Firefox.ja --source winget --upgrade-available
   ```

   - 1 行目が今の版
   - winget に新しい版があれば、`Mozilla.Firefox.ja` の行に今の版と新しい版が並ぶ
   - 行が出ずに、見つからない旨が出たら、新しい版は無い。この項の手順 4 は飛ばす

1. Firefox の新しい版があるときだけ、Firefox をすべて閉じてから winget で上げる。

   ```powershell
   winget upgrade --exact --id Mozilla.Firefox.ja --source winget --accept-source-agreements --accept-package-agreements
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-Item -LiteralPath "$env:ProgramFiles\Mozilla Firefox\firefox.exe").VersionInfo.ProductVersion
   ```

   - 最後の行が新しい版になればよい
   - **注意**: Firefox を開いたままだと、入れ替えが途中で終わることがある（参考資料を参照）

1. WezTerm の今の版を確かめ、WezTerm が動いていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1').DisplayVersion
   Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue | Format-Table Id, ProcessName
   ```

   - 1 行目に今の版が出る
   - プロセスが出たら、その WezTerm の窓をすべて閉じる

1. [WezTerm](#wezterm)の手順 3 のブロックを貼る。

   - 最後に出る `wezterm <版>` が、この項の手順 5 の版より新しければ上がった
   - 同じ版なら、main に新しいコミットが無かった（同じ版を入れ直しただけ）

1. この項の手順 1 でタスクを止めたときだけ、タスクを始め直す。

   - [windows-claude-remote-control.md の止める・もう一度始める](windows-claude-remote-control.md#止めるもう一度始める)の手順 2 を行う
