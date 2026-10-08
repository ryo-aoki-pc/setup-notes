# Windows 11 の初期設定の手順（インストール直後の更新・貼り付けの設定・scoop・UniGet UI・表示・電源・リモート・WSL）

## 実施手順

- [検証記録](verification/windows-setup.md)・[参考資料](reference/windows-setup.md)

> [!IMPORTANT]
> - **すべて、この PC のデスクトップで行う**。SSH のセッションには貼らない（Administrators の一員の SSH のセッションは管理者の権限で動くので、手順 20 の scoop のインストーラが止まる）
> - 窓の使い分け: 手順 1 で**管理者の** Windows PowerShell（5.1）を開き、手順 2〜8 で Windows Update を行う。手順 9 で**管理者ではない** Windows PowerShell を開き、手順 10〜34 をそこに貼る。手順 35 で管理者の窓を開き、手順 36〜55 を貼る。再起動の後は、手順 60 で開く管理者ではない窓に手順 61〜64 を貼る
> - ログインするユーザーは Administrators の一員（手順 2〜8 の Windows Update と、手順 36〜55 の PC 全体の設定に管理者の権限が要る）
> - **手順 2〜15 は Ctrl+V で貼る**。貼り付けの設定をまだ通していないため、conhost の窓に右クリックで貼ると行が逆順になる
> - **手順 16 は 1 行なので、どの貼り方でもそのまま貼れる**。手順 16 を貼った窓には、それより後の複数行のブロックを、GitHub のコピーボタンでコピーして右クリックで貼れる。Windows の PowerShell のブロックを貼るほかの手順書も、手順 16〜19 を前提にする
> - **手順 55 で再起動する**（設定のための再起動はこの 1 回。Windows Update は、必要なときだけ手順 8 で手動で再起動し、更新が無くなるまで繰り返す）
> - **画面で行う手順**: 1・9・35・56〜60。手順 31 は設定の画面を開いて変える。**対話入力のある手順**: 62（WSL のユーザー名とパスワード）・64（自動サインインのパスワード）。**条件付きの手順**: 5・7・8・11・12・14（更新の結果による分岐）・39（PC の名前を変えるとき）・44（Pro 以上）・52（デュアル ブートで、AlmaLinux の時計を UTC にしたとき）・53（US 配列のキーボード）

- 上から順にコードブロックを貼る。手順 36 の変数は、管理者の PowerShell を開き直したら貼り直す
- GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- 項目ごとの手順（要らない項目の手順は飛ばしてよい。手順 9・16〜19・35〜37・55 は飛ばさない）
  - 更新: Windows Update は 1〜8、Microsoft Store は 9〜15。貼り付けの設定: 16〜19・37・38
  - 入れるもの: scoop は 20・21、UniGet UI は 22・59、PowerToys は 23、PowerShell 7 は 24、WSL の AlmaLinux 10 は 54・62・63、自動サインイン（Autologon）は 64
  - 表示: エクスプローラーは 25、旧形式のコンテキストメニューは 26、スタートと検索は 27・49、タスクバーは 28・58、ダークモードは 29、既定の端末は 30
  - 入力: IME の Ctrl+Space は 31、Caps Lock を Ctrl には 51、US 配列のキーボードは 53。確かめるのは 56
  - 整理: 自動で起動するアプリは 32、標準アプリは 33、ウィジェットは 34、デスクトップのショートカットは 50
  - PC 全体: PC の名前は 39、長いパス・開発者モード・sudo は 40、電源とロックは 41、LAN のアダプターの省電力は 42、デュアル ブートの時計は 52
  - ネットワーク: LAN をプライベートには 43、リモート デスクトップは 44、リモート アシスタンスは 45、ping は 46、配信の最適化は 47
  - サインイン: Windows Hello だけのサインインを切るのは 48、自動サインインは 64
- Windows を AlmaLinux 10 とのデュアルブート向けに入れるときは、先に [Windows 11 のデュアルブート向けの導入](windows-dual-boot.md)を通してから、この文書を手順 1 から始める
- 手順の後に、この順に通す手順書（どれも Windows 11 の節がある）
  - [Git for Windows](git.md#windows-11-で-git-for-windows-を入れる)（続けて、Git Bash で同じ文書の実施手順）→ [Firefox](firefox.md#windows-11-で使う)（既定のブラウザーにする）→ [WezTerm](wezterm-nightly.md#windows-11-で使う) → [Claude Code](claude-code.md#windows-11-で使う) → [VirtualBox](virtualbox.md#windows-11-で使う) → [WireGuard](wireguard-road-warrior.md#windows-11-で使う) → [HackGen Console NF](hackgen.md#windows-11-で使う)
  - HackGen Console NF を手順 55 の再起動より前に入れれば、そちらのサインインし直す手順は要らない
  - 必要なら: [Windows の OpenSSH サーバー](windows-openssh-server.md)・[Syncthing の Windows 11 で使う](syncthing.md#windows-11-で使う)・[Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)・[RDP をロックせずに切断（Windows）](windows-rdp-disconnect.md)・[SSH クライアント（Windows）](windows-ssh-client.md)・[Samba の共有をネットワーク ドライブに](samba-client.md#windows-11-で使う)
  - git の差分の表示と GitHub の操作も使うなら、Git for Windows と WezTerm の後に [git-delta](git-delta.md#windows-11-で使う) → [GitHub CLI](gh.md#windows-11-で使う)（どちらも scoop で入れる）
  - 端末のエディタと TUI も使うなら、続けて [Neovim](neovim.md#windows-11-で使う) → [lazygit](lazygit.md#windows-11-で使う) → [yazi](yazi.md#windows-11-で使う)（どれも scoop で入れる。管理者ではない窓。git-delta・GitHub CLI も使うなら、その後に）
- 手順の後の節
  - Wake on LAN は[Wake on LAN を使う（任意）](#wake-on-lan-を使う任意)、リモートからの再起動を増やすなら[リモートから再起動する手段を増やす（任意）](#リモートから再起動する手段を増やす任意)
  - 広告 ID などのプライバシーと宣伝の表示は[プライバシーと広告の表示を切る（任意）](#プライバシーと広告の表示を切る任意)、誤って押しやすいキー・Alt+Tab・ギャラリーとホーム・タスクの終了・アニメーション・効果音・ストレージ センサーは[表示・入力・音・ストレージを変える（任意）](#表示入力音ストレージを変える任意)
  - Edge の常駐は[Edge の常駐をポリシーで止める（任意）](#edge-の常駐をポリシーで止める任意)（管理者の窓）、クリップボードの履歴は[CopyQ を使う（任意）](#copyq-を使う任意)
  - PowerToys は[PowerToys のユーティリティを絞る（任意）](#powertoys-のユーティリティを絞る任意)、PowerShell 7 の貼り付け・履歴の検索・starship と zoxide は[PowerShell 7 のプロファイルを設定する（任意）](#powershell-7-のプロファイルを設定する任意)
  - Windows Terminal のフォントは、HackGen Console NF を入れた後に[Windows Terminal のフォントと貼り付けの警告を変える（任意）](#windows-terminal-のフォントと貼り付けの警告を変える任意)、WSL のネットワークは[WSL のネットワークをミラーにする（任意）](#wsl-のネットワークをミラーにする任意)
  - Git Bash の starship・zoxide・fzf・eza・bat は、Git for Windows・WezTerm と Git Bash の共通の bash 設定の後に[シェルのツールを入れる（任意）](#シェルのツールを入れる任意)（zoxide は 0.9.9 に止める）
  - 以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> - **手順 40 のインラインの sudo、手順 41 の放置でロックしない設定、手順 44 のリモート デスクトップ、手順 48 の Windows Hello 以外のサインイン、手順 64 の自動サインインを重ねると、PC に触れる人と、このユーザーのパスワードを知る人は、このユーザー（管理者）として操作できる**。人が触れる場所にある PC では、手順 41・64 は行わない

1. Windows のデスクトップで、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリック →「管理者として実行」。UAC の確認で「はい」
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする
   - 手順 2〜8 はこの窓に貼る。更新コマンドから自動では再起動しない

1. 管理者であることを確かめ、今の窓だけモジュールを使えるようにする。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {
       throw '中断: Windows PowerShell 5.1 で実行する'
     }
     if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
       throw '中断: 手順 1 で管理者の Windows PowerShell を開く'
     }
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

   - PSWindowsUpdate の一覧が出たら、版と場所を控える。何も並ばなければ、手順 3 で初めて入れる
   - 最後に `RemoteSigned`・`Unrestricted`・`Bypass` のいずれかが出ればよい
   - エラーが出たら進まない。グループ ポリシーによる制限は、この手順では変えない

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
     Import-Module -Name PSWindowsUpdate -Global -PassThru | Select-Object Name, Version, ModuleBase
   }
   ```

   - `PSWindowsUpdate` の版と場所が出ればよい
   - 手順 2 で入っていなかった場合は、そのことを控える（[ロールバック](#ロールバック)の手順 41 で使う）
   - ダウンロードや読み込みのエラーが出たら進まない
   - **次の手順は、モジュールの読み込みが終わってから貼る**

1. 再起動待ちでないことを確かめ、通常の Windows Update を検索する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     $rebootRequired = Get-WURebootStatus -Silent
     if ($rebootRequired -isnot [bool]) { throw '中断: 再起動待ちかを確認できない' }
     if ($rebootRequired) {
       throw '中断: 再起動が必要。手順 8 を行ってから検索し直す'
     }
     $updates = @(Get-WindowsUpdate -Criteria 'IsInstalled=0 and IsHidden=0 and IsAssigned=1 and BrowseOnly=0' | ForEach-Object { $_ })
     '対象の更新: {0} 件' -f $updates.Count
     $updates | Format-Table KB, Size, Title -AutoSize
   }
   ```

   - 更新の件数と一覧を確かめる。この手順はダウンロードとインストールを行わない
   - `対象の更新: 0 件` なら、手順 5 は飛ばす（手順 6・7 で最終確認する）
   - 再起動が必要と出たら、手順 5〜7 は飛ばして手順 8 へ。検索のエラーなら進まない
   - **次の手順は、検索が終わり、更新の一覧を確かめてから貼る**

1. 対象の更新があるときだけ、ダウンロードしてインストールする。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     $rebootRequired = Get-WURebootStatus -Silent
     if ($rebootRequired -isnot [bool]) { throw '中断: 再起動待ちかを確認できない' }
     if ($rebootRequired) {
       throw '中断: 再起動が必要。手順 8 を行ってから検索し直す'
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

   - `Result` は、受け付け・ダウンロード・インストールの段階ごとに出る。`Accepted`・`Downloaded` だけではインストール完了ではない
   - `Installed` になったことを確かめる。エラーや `中断:` が出たら、理由を解決するまで次へ進まない
   - このコマンドからは再起動しない
   - **次の手順は、インストールが終わり、プロンプトが戻ってから貼る**

1. Windows Update が再起動を必要としているか確かめる。

   ```powershell
   & {
     $rebootRequired = Get-WURebootStatus -Silent -ErrorAction Stop
     if ($rebootRequired -isnot [bool]) { throw '中断: 再起動待ちかを確認できない' }
     $rebootRequired
   }
   ```

   - `True` なら、手順 7 は飛ばして手順 8 へ
   - `False` なら、手順 7 へ。何も出ない場合やエラーの場合は、再起動不要とはみなさず進まない

1. 再起動が不要なときだけ、同じ条件で更新が残っていないか確かめる。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     $updates = @(Get-WindowsUpdate -Criteria 'IsInstalled=0 and IsHidden=0 and IsAssigned=1 and BrowseOnly=0' | ForEach-Object { $_ })
     $rebootRequired = Get-WURebootStatus -Silent
     if ($rebootRequired -isnot [bool]) { throw '中断: 再起動待ちかを確認できない' }
     if ($rebootRequired) {
       throw '中断: 再起動が必要。手順 8 を行ってから検索し直す'
     }
     '残っている対象の更新: {0} 件' -f $updates.Count
     $updates | Format-Table KB, Size, Title -AutoSize
     if ($updates.Count -gt 0) {
       Write-Warning '更新が残っている。手順 5 から繰り返す'
     } else {
       'Windows Update の確認完了（対象の更新なし・再起動待ちなし）'
     }
   }
   ```

   - 完了の行が出たら、手順 8 は飛ばして手順 9 へ
   - 更新が残っていたら、手順 5〜7 を繰り返す。同じ更新が失敗し続ける場合は止め、エラーを調べる
   - **次の手順は、対象の更新が無くなり、再起動待ちも無くなってから行う**

1. 再起動が必要なときだけ、作業を保存して再起動する。

   ```powershell
   Restart-Computer
   ```

   - 自分で保存してから貼る。`-Force` は付けない
   - **次の手順は、起動してサインインし、手順 1〜7 をもう一度通してから行う**（新しい窓では手順 2・3 の準備と読み込みも必要）

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - 手順 1 の管理者の窓を閉じる
   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする（実行ポリシーとプロファイルは、5.1 と 7 で別々に持つ）
   - Windows Terminal の中に開いた窓に複数行のブロックを貼ると、「複数の行を含むテキストを貼り付けようとしています」の警告が出る。「強制的に貼り付け」を押す

1. 管理者ではないことと、Store CLI・winget の有無を確かめる。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if ($PSVersionTable.PSVersion.Major -ne 5 -or $PSVersionTable.PSVersion.Minor -ne 1) {
       throw '中断: Windows PowerShell 5.1 で実行する'
     }
     if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
       throw '中断: 手順 9 で管理者ではない窓を開く'
     }
     Get-AppxPackage -Name Microsoft.WindowsStore | Select-Object Name, Version
     foreach ($name in 'store.exe', 'winget.exe') {
       $command = Get-Command -Name $name -ErrorAction SilentlyContinue
       if ($command) { $command | Select-Object Name, Source } else { Write-Warning "見つからない: $name" }
     }
   }
   ```

   - `winget.exe` に場所が出れば、手順 11 は飛ばす
   - `store.exe` があれば、手順 12 はいったん飛ばして手順 13 で一括更新に対応しているか確かめる
   - `store.exe` が無ければ、手順 11（winget が無い場合だけ）・12 で準備する

1. winget が無いときだけ、このユーザーにアプリ インストーラーを登録する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
     Get-Command -Name winget.exe | Select-Object Name, Source
     winget.exe --version
     if ($LASTEXITCODE -ne 0) { throw "中断: winget の確認に失敗（終了コード $LASTEXITCODE）" }
   }
   ```

   - `winget.exe` の場所と版が出ればよい
   - 初回サインイン後の登録を要求する操作。アプリ インストーラー自体が無い場合や、登録が失敗した場合は止める

1. Store CLI が無いか一括更新に非対応のときだけ、Store 本体を更新する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     foreach ($id in '9NBLGGH4NNS1', '9WZDNCRFJBMP') {
       winget.exe upgrade --exact --id $id --source msstore --include-unknown --accept-source-agreements --accept-package-agreements --disable-interactivity
       if ($LASTEXITCODE -notin 0, -1978335189) {
         throw "中断: $id の更新に失敗（終了コード $LASTEXITCODE）"
       }
     }
   }
   ```

   - アプリ インストーラー、Microsoft Store の順に更新する。更新が無い旨の表示なら、そのアプリは何も変えない
   - 終わったら手順 13 へ。まだ CLI が使えない場合は止める
   - **次の手順は、両方の更新が終わり、プロンプトが戻ってから貼る**

1. Store CLI が一括更新に対応していることを確かめ、更新を検索する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if (-not (Get-Command -Name store.exe -ErrorAction SilentlyContinue)) {
       throw '中断: Store CLI が無い。手順 12 で準備してから再確認する'
     }
     $help = store.exe updates --help
     if ($LASTEXITCODE -ne 0 -or ($help -join "`n") -notmatch '--apply\b') {
       throw '中断: Store CLI の一括更新を確認できない。手順 12 の後も同じなら進まない'
     }
     store.exe updates
     if ($LASTEXITCODE -ne 0) { throw "中断: Store の検索に失敗（終了コード $LASTEXITCODE）" }
   }
   ```

   - CLI が出す更新の一覧を確かめる。エラーが出たら進まない
   - 更新が無いと明示された場合だけ、手順 14 は飛ばす
   - **次の手順は、検索が終わり、更新の一覧を確かめてから貼る**

1. Store の更新があるときだけ、すべての更新を適用する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     store.exe updates --apply
     if ($LASTEXITCODE -ne 0) { throw "中断: Store の更新に失敗（終了コード $LASTEXITCODE）" }
   }
   ```

   - 名前や発行元のフィルターは付けず、すべての Store アプリを対象にする
   - エラーや適用できないアプリが出たら進まない。使用中のアプリが原因なら、作業を保存してそのアプリを閉じてから、この手順を貼り直す
   - **次の手順は、更新処理が終わり、プロンプトが戻ってから貼る**（コマンドの終了だけで更新完了とはみなさない）

1. Store の更新が残っていないかと、必要なアプリの状態を確かめる。

   ```powershell
   & {
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
   - 更新が残っていたら手順 14・15 を繰り返す。進行中・失敗の表示や、結果を判定できない場合は次へ進まない
   - 更新で窓が閉じた場合は、手順 9 で通常の PowerShell を開き直してから手順 13〜15 で確認する
   - **次の手順は、Store の更新がすべて終わってから貼る**

1. 今の窓だけ、Ctrl+Enter を「行を足す」にする。

   ```powershell
   Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine
   ```

   - 何も出なければよい
   - この窓を閉じるまで効く。手順 17 から後の複数行のブロックを、この窓に右クリックで貼れるようにするため

1. 管理者ではないことと、今の状態を確かめる。

   ```powershell
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

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`7.…` か `True` なら、窓を閉じて手順 9 から
   - `Winget` に `…\WindowsApps\winget.exe` の場所が出ればよい。空なら、手順 10〜15 でアプリ インストーラーの登録と更新を確かめてから
   - `Git` は、Git for Windows がもうあるか（無ければ空。この文書の後に [git.md](git.md#windows-11-で-git-for-windows-を入れる) で入れる）
   - `ClassicMenu` は旧形式のコンテキストメニューの設定があるか（無ければ `False`）
   - `ScancodeMap` が空でなければ、キーの割り当てがもうある。その値を控える（手順 51 は、違う値があれば止まる）
   - `Profile` は、このユーザーの Windows PowerShell が起動のときに読むファイル。`ProfileExists : False` なら、手順 19 で作る
   - 最後の表の `CurrentUser` の値を控える（[ロールバック](#ロールバック)の手順 16 で使う。何も設定していなければ `Undefined`）
   - `実行ポリシー:` が `RemoteSigned`・`Unrestricted`・`Bypass` のどれかなら、手順 18 は何も変えない。Windows 11 の既定は `Restricted`（一覧はどれも `Undefined`）で、このままではプロファイルも scoop も動かない
   - `Scoop` に場所が出たら、scoop はもう入っている。手順 20・21 は飛ばす

1. スクリプトの実行ポリシーを RemoteSigned にする。

   ```powershell
   if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force }
   Get-ExecutionPolicy
   ```

   - `RemoteSigned`（もとから `Unrestricted` か `Bypass` だった PC では、その値）が出ればよい
   - 今の値が `RemoteSigned`・`Unrestricted`・`Bypass` のどれかなら、何も書かない
   - 「より限定的なスコープで定義されたポリシーによって上書きされます」の旨のエラーが出て、ほかの値が出たら、グループ ポリシー（`MachinePolicy` か `UserPolicy`）で決められている。その PC では、scoop も手順 19 のプロファイルも使えない（ほかの手順書のブロックは、conhost の窓でも Ctrl+V で貼る）

1. プロファイルに、手順 16 と同じ 1 行を足す。

   ```powershell
   & {
     $line = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-setup.md'
     $old = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-powershell-paste.md'
     if (-not (Test-Path -LiteralPath $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
     $text = Get-Content -LiteralPath $PROFILE -Raw
     if ($text -and ($text.Contains($line) -or $text.Contains($old))) { "すでにある: $PROFILE" } else {
       if ($text -and -not $text.EndsWith("`n")) { $line = "`r`n" + $line }
       Add-Content -LiteralPath $PROFILE -Value $line
       "足した: $PROFILE"
     }
     Get-Content -LiteralPath $PROFILE
   }
   ```

   - `足した: C:\Users\<WIN_USER>\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` と、足した行が出ればよい（OneDrive でドキュメントをバックアップしていると、`OneDrive` の下のパスになる）
   - プロファイルにほかの行があれば、それも出る（そのまま残る）
   - 何度貼ってもよい（2 回目からは `すでにある:`）。前の版の手順書（`windows-powershell-paste.md`）で足した行があるときも `すでにある:` で、何も足さない
   - これより後に開く Windows PowerShell の窓（手順 35 の管理者の窓も）は、この行を読む

1. scoop を入れる。

   ```powershell
   Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
   ```

   - 最後に `Scoop was installed successfully!` が出ればよい
   - `Running the installer as administrator is disabled by default` が出たら、管理者の PowerShell に貼っている。閉じて手順 9 から
   - `Scoop is already installed` が出たら、もう入っている（何も変えずに終わる）。手順 21 へ進む
   - `'C:\Users\<WIN_USER>\scoop' exists and is not empty` が出たら、前に入れた scoop の残り（`persist` など）がある。要らなければ[ロールバック](#ロールバック)の手順 14 で消してから貼り直す

1. scoop が入ったことを確かめる。

   ```powershell
   scoop --version
   scoop bucket list
   [Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ -like '*\scoop\shims' }
   ```

   - `Current Scoop version:` の次に版と公開日が出ればよい（版は実行した日の最新）
   - `scoop bucket list` に `main` の行が出る
   - 最後に `C:\Users\<WIN_USER>\scoop\shims` が出る

1. UniGet UI（winget）と、その scoop の検索に使う scoop-search を入れる。

   ```powershell
   scoop install scoop-search
   winget install --exact --id Devolutions.UniGetUI --source winget --scope user --accept-source-agreements --accept-package-agreements
   winget list --exact --id Devolutions.UniGetUI --source winget
   ```

   - `scoop install scoop-search` の最後に `'scoop-search' (2.1.0) was installed successfully!` の形の行が出る
   - winget はインストーラのハッシュを確かめてから入れる。初回に Visual C++ ランタイムなどの依存関係を入れる際は、管理者の確認（UAC）が出ることがある。製品名と発行元を確かめて許可する（Visual C++ ランタイムの発行元は Microsoft Corporation）
   - 最後の表に `UniGetUI` と `Devolutions.UniGetUI` の行が出ればよい（版は実行した日の最新）
   - デスクトップに UniGetUI のショートカットができる（手順 50 で消す）

1. PowerToys を、自分のユーザーに入れる。

   ```powershell
   winget install --exact --id Microsoft.PowerToys --source winget --scope user --accept-source-agreements --accept-package-agreements
   winget list --exact --id Microsoft.PowerToys --source winget
   ```

   - 最後の表に `PowerToys` と `Microsoft.PowerToys` の行が出ればよい（版は実行した日の最新）
   - 管理者の確認（UAC）は出ないはず
   - Caps Lock は、PowerToys の Keyboard Manager ではなく、手順 51 の Scancode Map で変える（[選択した方針](verification/windows-setup.md#選択した方針)）

1. PowerShell 7 を、自分のユーザーに入れる。

   ```powershell
   winget install --exact --id Microsoft.PowerShell --source winget --accept-source-agreements --accept-package-agreements
   winget list --exact --id Microsoft.PowerShell --source winget
   ```

   - 最後の表に `PowerShell` と `Microsoft.PowerShell` の行が出ればよい（版は実行した日の最新）
   - 管理者の確認（UAC）は出ないはず（MSIX のパッケージで、自分のユーザーに入る）
   - スタートメニューに「PowerShell 7」ができる。この文書とほかの手順書のブロックは、引き続き Windows PowerShell 5.1 に貼る

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
   Get-ItemProperty -Path $adv | Format-List HideFileExt, Hidden, LaunchTo, Start_TrackDocs
   Get-ItemProperty -Path $exp | Format-List ShowRecent, ShowFrequent
   ```

   - `HideFileExt : 0`・`Hidden : 1`・`LaunchTo : 1`・`Start_TrackDocs : 0`・`ShowRecent : 0`・`ShowFrequent : 0` が出ればよい
   - 開いているエクスプローラーの窓には、開き直すか手順 55 の再起動の後に効く

1. 自分のユーザーで、旧形式のコンテキストメニューを出すようにする。

   ```powershell
   reg.exe add 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /f /ve
   reg.exe query 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /ve
   ```

   - `reg.exe add` が成功の 1 行を出し、`reg.exe query` に `(既定)`（英語の表示では `(Default)`）と `REG_SZ` の行が出ればよい（値は空）
   - エクスプローラーに効くのは、手順 55 の再起動の後

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
   Get-ItemProperty -Path $adv | Format-List Start_IrisRecommendations, Start_AccountNotifications
   Get-ItemProperty -Path $cdm | Format-List SubscribedContent-338393Enabled, SubscribedContent-353694Enabled, SubscribedContent-353696Enabled, SubscribedContent-338389Enabled, SubscribedContent-310093Enabled, SubscribedContent-338388Enabled, SystemPaneSuggestionsEnabled, SilentInstalledAppsEnabled
   Get-ItemProperty -Path $upe | Format-List ScoobeSystemSettingEnabled
   ```

   - 並んだ値がすべて `0` ならよい
   - 外したアプリが戻らないように、手順 33 より前に貼る（`SilentInstalledAppsEnabled`）
   - スタートの検索の Web（Bing）の結果は、管理者の権限が要るので、手順 49 で切る

1. タスクバーを左に寄せ、タスク ビューと検索のボタンを消し、時計に秒を出す。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   Set-ItemProperty -Path $adv -Name TaskbarAl -Type DWord -Value 0
   Set-ItemProperty -Path $adv -Name ShowTaskViewButton -Type DWord -Value 0
   Set-ItemProperty -Path $adv -Name ShowSecondsInSystemClock -Type DWord -Value 1
   Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name SearchboxTaskbarMode -Type DWord -Value 0
   Get-ItemProperty -Path $adv | Format-List TaskbarAl, ShowTaskViewButton, ShowSecondsInSystemClock
   Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' | Format-List SearchboxTaskbarMode
   ```

   - `TaskbarAl : 0`・`ShowTaskViewButton : 0`・`ShowSecondsInSystemClock : 1`・`SearchboxTaskbarMode : 0` が出ればよい
   - タスクバーには、すぐか、手順 55 の再起動の後に効く
   - ウィジェットのボタンは、手順 34 でウィジェットを外すと消える（この手順では書けない）

1. ダークモードにする。

   ```powershell
   $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
   Set-ItemProperty -Path $p -Name AppsUseLightTheme -Type DWord -Value 0
   Set-ItemProperty -Path $p -Name SystemUsesLightTheme -Type DWord -Value 0
   Get-ItemProperty -Path $p | Format-List AppsUseLightTheme, SystemUsesLightTheme
   ```

   - `AppsUseLightTheme : 0` と `SystemUsesLightTheme : 0` が出ればよい
   - 動いているアプリとタスクバーには、手順 55 の再起動の後に効く（設定の「個人用設定」→「色」から変えると、すぐに効く）

1. 既定の端末を Windows Terminal にする。

   ```powershell
   $p = 'HKCU:\Console\%%Startup'
   if (-not (Test-Path -LiteralPath $p)) { New-Item -Path $p | Out-Null }
   Set-ItemProperty -LiteralPath $p -Name DelegationConsole -Type String -Value '{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}'
   Set-ItemProperty -LiteralPath $p -Name DelegationTerminal -Type String -Value '{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}'
   Get-ItemProperty -LiteralPath $p | Format-List DelegationConsole, DelegationTerminal
   ```

   - `DelegationConsole : {2EACA947-…}` と `DelegationTerminal : {E12CFF52-…}` が出ればよい
   - 次に起動したコンソールのアプリから効く
   - **注意**: 管理者として開いた PowerShell は、この設定でも conhost の窓で開く（Windows Terminal の側の制限）。手順 35 の管理者の窓に右クリックで貼れるのは、手順 16〜19 の設定による

1. Microsoft IME の設定を開き、Ctrl+Space で IME をオン・オフするようにする。

   ```powershell
   Start-Process 'ms-settings:regionlanguage-jpnime'
   ```

   - 設定の Microsoft IME の画面が開く。「キーとタッチのカスタマイズ」を開き、「キーの割り当て」をオンにして、「Ctrl + Space」を「IME-オン/オフ」にする
   - 「以前のバージョンの Microsoft IME を使う」がオンだと、この項目は出ない
   - 効くのは、次に IME を使う窓から（確かめるのは手順 56）
   - **次の手順は、設定を閉じてから PowerShell に貼る**

1. 自動で起動するアプリのうち、OneDrive・Edge・Teams を止める。

   ```powershell
   & {
     $run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
     $ok = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
     if (-not (Test-Path -LiteralPath $ok)) { New-Item -Path $ok -Force | Out-Null }
     $names = (Get-Item -LiteralPath $run).Property | Where-Object { $_ -eq 'OneDrive' -or $_ -eq 'OneDriveSetup' -or $_ -like 'MicrosoftEdgeAutoLaunch_*' }
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
   - 初回導入用の `OneDriveSetup` の項目も、残っていれば止める。実行ファイルがある場合は初回インストールも延期される。必要ならタスク マネージャーの「スタートアップ アプリ」から有効に戻せる
   - `WingetUI: 起動する` は UniGet UI（更新を知らせるために起動する）。止めるなら、タスク マネージャーの「スタートアップ アプリ」で無効にする
   - 効くのは、次のサインインから

1. 要らない標準アプリを、自分のユーザーから外す。

   ```powershell
   foreach ($n in 'Clipchamp.Clipchamp', 'Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.Todos', 'Microsoft.WindowsFeedbackHub', 'Microsoft.GetHelp', 'Microsoft.OutlookForWindows', 'MSTeams', 'Microsoft.PowerAutomateDesktop') {
     $p = Get-AppxPackage -Name $n
     if ($p) { $p | Remove-AppxPackage; "外した: $n" } else { "無い: $n" }
   }
   ```

   - 11 個のアプリごとに `外した:` か `無い:` が出ればよい
   - 赤い字のエラーが出たアプリは、外せなかった（動いていれば閉じて貼り直す）
   - Copilot（`Microsoft.Copilot`）は外さない。`Microsoft.MicrosoftOfficeHub` はストアの名前が「Microsoft 365 Copilot」になった別のアプリ（Office の入口）
   - 機能の更新（Windows の大きな更新）の後に、戻ってくることがある。そのときはこの手順を貼り直す

1. ウィジェット（Windows Web Experience Pack）を外す。

   ```powershell
   $p = Get-AppxPackage -Name MicrosoftWindows.Client.WebExperience
   if ($p) { $p | Remove-AppxPackage; '外した: MicrosoftWindows.Client.WebExperience' } else { '無い: MicrosoftWindows.Client.WebExperience' }
   ```

   - `外した:` か `無い:` が出ればよい
   - タスクバーのウィジェットのボタンと、設定のウィジェットの切り替えが消える（手順 55 の再起動の後に確かめる）

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く。UAC の確認が出たら「はい」
   - 手順 9 の PowerShell は閉じてよい（再起動の後は、手順 60 で開き直す）
   - この窓は、手順 19 でプロファイルに書いた行を読む（手順 37 で確かめる）
   - 開いたときに、プロファイルを読めないという赤い字のエラーが出たら、実行ポリシーが `Restricted` のまま。手順 18 を、この窓で貼り直す

1. 変数を設定する（PC の名前を変えるなら、`PC_NAME` に値を入れる）。

   ```powershell
   $PC_NAME = ''   # この PC の新しい名前（15 文字まで。英字・数字・ハイフン）。<HOSTNAME>
   ```

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # ほかの PC とつながる LAN の接続（自動）。<LAN_IF>
   'PC_NAME = {0}' -f $PC_NAME
   'LAN_IF  = {0}' -f $LAN_IF
   ```

   - 最後に値を読み戻して確かめる
   - `PC_NAME` は、SSH・リモート デスクトップ・Syncthing などで、この PC を見分ける名前。名前を変えないなら、空のままにして手順 39 を飛ばす
   - `LAN_IF` は、インターネットにつながっている接続の名前（`イーサネット`、`Wi-Fi` など）。ほかの PC とつながる接続と違えば、`$LAN_IF = 'Wi-Fi'` のように直す
   - 変数はその PowerShell の中だけで有効。**新しい PowerShell を開いたら**、手順 36 のブロックを貼り直してから先へ進む

1. 管理者であることと、プロファイルの行が効いていることと、今の値を確かめる。

   ```powershell
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
   - `Admin` が `False` なら、管理者ではない窓に貼っている。手順 35 から
   - `CtrlEnter` が `InsertLineAbove` なら、この窓はプロファイルを読んでいない。手順 16・18・19 をこの窓で貼り直してから（手順 16 を先に貼ると、手順 18・19 を右クリックで貼れる）、窓を開き直して手順 36 から
   - `Version` が 24H2（ビルド 26100）より前で `Sudo` が空なら、手順 40 の sudo の行は何もしない
   - 次の値を控える（[ロールバック](#ロールバック)で、元に戻すかを決めるのに使う）
     - `ComputerName`（PC の名前。ロールバックの手順 37）と `LanCategory`（LAN の種類。ロールバックの手順 33）
     - `RemoteDesktop`（1 なら無効、0 ならもう有効。ロールバックの手順 32）と `RemoteAssistance`（1 なら有効、0 なら無効。ロールバックの手順 31）
     - `HelloOnly`（2 ならオン、0 ならオフ。ロールバックの手順 22）と `Keyboard`（`kbd106.dll` なら JIS 配列。ロールバックの手順 26）
     - 最後の行の配信の最適化のモード（`Lan` が Windows の既定。ロールバックの手順 29）
   - `Hypervisor : True` なら、Hyper-V がもう動いている（[VirtualBox の Windows 11 の節](virtualbox.md#windows-11-で使う)の VM は、その上で動く）
   - `Edition` が `Core` で始まる（Home）なら、手順 44 は飛ばす

1. 複数行のブロックをコピーボタンでコピーして右クリックで貼り、元の順に動くことを確かめる。

   ```powershell
   & {
     '1 行目'
     '2 行目'
     '3 行目'
   }
   ```

   - このブロックを GitHub のコピーボタンでコピーし、手順 35 の窓の中で右クリックして貼る
   - 最後の `}` の行で止まるので、Enter を押す
   - `1 行目`・`2 行目`・`3 行目` の順に出ればよい

1. PC の名前を変えるときだけ、名前を変える（効くのは再起動の後）。

   ```powershell
   if (-not $PC_NAME) {
     Write-Error '中断: 手順 36 の $PC_NAME が空'
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
   - 効くのは、手順 55 の再起動の後
   - 名前を変えないなら（手順 36 の `PC_NAME` が空なら）、この手順は飛ばす

1. 長いパス・開発者モード・sudo（今の窓で動く形）を有効にする。

   ```powershell
   $dev = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -Type DWord -Value 1
   if (-not (Test-Path -LiteralPath $dev)) { New-Item -Path $dev | Out-Null }
   Set-ItemProperty -Path $dev -Name AllowDevelopmentWithoutDevLicense -Type DWord -Value 1
   if (Get-Command sudo -ErrorAction SilentlyContinue) { sudo config --enable normal } else { 'sudo が無い（24H2 より前の Windows）' }
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' | Format-List LongPathsEnabled
   Get-ItemProperty -Path $dev | Format-List AllowDevelopmentWithoutDevLicense
   ```

   - `LongPathsEnabled : 1` と `AllowDevelopmentWithoutDevLicense : 1` が出ればよい
   - sudo は、今の窓で動く形（インライン）になった旨を表示する（表示言語は環境による）
   - 管理者ではない窓で `sudo <コマンド>` を打つと、UAC の確認の後に、同じ窓でそのコマンドが管理者の権限で動く
   - **注意**: インラインの sudo は、同じ窓のほかの（管理者でない）プロセスから、管理者のコマンドに入力を送れる形（Microsoft の文書。[検証記録](verification/windows-setup.md)・[参考資料](reference/windows-setup.md)）

1. 電源接続中の眠りと蓋の動作を止め、電源に関係なく休止状態と放置後のロックを切る。

   ```powershell
   powercfg /change standby-timeout-ac 0
   powercfg /hibernate off
   powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
   powercfg /setacvalueindex SCHEME_CURRENT SUB_NONE CONSOLELOCK 0
   powercfg /setactive SCHEME_CURRENT
   Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name DelayLockInterval -Type DWord -Value 0xFFFFFFFF
   foreach ($s in 'SUB_SLEEP STANDBYIDLE', 'SUB_BUTTONS LIDACTION', 'SUB_NONE CONSOLELOCK') { '{0}: {1}' -f $s, ((powercfg /qh SCHEME_CURRENT $s.Split(' ')) | Select-String -Pattern 'AC' | Select-Object -Last 1) }
   'HibernateEnabled: {0}' -f (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power').HibernateEnabled
   ```

   - 3 つの行の AC の値が `0x00000000` で、`HibernateEnabled: 0` が出ればよい（`powercfg` の表示は日本語）
   - 画面を消す時間は変えない
   - バッテリー用の電源プランの値（スリープ時間・蓋を閉じたときの動作・`CONSOLELOCK`）は変えない
   - 休止状態の無効化と `DelayLockInterval` は電源接続中だけに限定されない（バッテリーのときもかかる）
   - **注意**: PC の前にいる人は、このユーザーとしてそのまま使える（リードの `[!WARNING]`）

1. LAN のアダプターを、電力の節約のために止めないようにする。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '手順 36 の $LAN_IF が空'
   } else {
     $pm = Get-NetAdapterPowerManagement -Name $LAN_IF
     if ($pm.AllowComputerToTurnOffDevice -eq 'Unsupported') { "このアダプターは対象外: $LAN_IF" } else {
       $pm.AllowComputerToTurnOffDevice = 'Disabled'
       $pm | Set-NetAdapterPowerManagement -NoRestart
     }
     Get-NetAdapterPowerManagement -Name $LAN_IF | Format-List Name, AllowComputerToTurnOffDevice, WakeOnMagicPacket
   }
   ```

   - `AllowComputerToTurnOffDevice : Disabled` が出ればよい
   - `このアダプターは対象外:` なら、このアダプターには設定が無い（何もしない）
   - アダプターは起動し直さない（`-NoRestart`）。効くのは、手順 55 の再起動の後

1. LAN の接続をプライベートにする。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '手順 36 の $LAN_IF が空'
   } else {
     Set-NetConnectionProfile -InterfaceAlias $LAN_IF -NetworkCategory Private
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
   }
   ```

   - `<LAN_IF>  Private` が出ればよい
   - 既にプライベートなら、何も変わらない
   - **注意**: プライベート向けのほかの許可の規則（ネットワーク探索など）も、この LAN で効くようになる
   - [Windows の OpenSSH サーバー](windows-openssh-server.md)・[Syncthing の Windows 11 で使う](syncthing.md#windows-11-で使う)・手順 44〜46 は、この LAN がプライベートであることを前提にする

1. Pro 以上のときだけ、リモート デスクトップを有効にし、受け付けるのをプライベートの LAN に絞る。

   ```powershell
   $ed = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
   if ($ed -like 'Core*') { Write-Error "中断: Home（$ed）は、リモート デスクトップでつながれる側になれない" } else {
     Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Type DWord -Value 0
     Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Type DWord -Value 1
     Set-NetFirewallRule -Group '@FirewallAPI.dll,-28752' -Enabled True -Profile Private
     Get-NetFirewallRule -Group '@FirewallAPI.dll,-28752' | Format-Table Name, Enabled, Profile, Direction, Action
   }
   ```

   - `RemoteDesktop-UserMode-In-TCP` などの行が `True  Private  Inbound  Allow` で出ればよい
   - 手順 37 の `Edition` が `Core` で始まる（Home）なら、この手順は飛ばす（貼っても `中断:` で止まる）
   - つなぐのは、この PC にサインインするのと同じユーザーとパスワード（Microsoft アカウントなら、そのアカウントのパスワード。手順 48 も）
   - [RDP をロックせずに切断（Windows）](windows-rdp-disconnect.md)は、この手順を前提にする

1. リモート アシスタンスを切る。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' -Name fAllowToGetHelp -Type DWord -Value 0
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
   Get-NetFirewallRule -Group $g | Format-Table Name, Enabled, Profile, Direction, Action
   ```

   - 2 つの規則が `True  Private  Inbound  Allow` で出ればよい
   - 何度貼ってもよい（規則は消してから作り直す）
   - LAN の別の PC から、この PC の IP アドレスへ ping が通るようになる

1. 配信の最適化を、LAN の PC とだけ共有するようにする。

   ```powershell
   Set-DODownloadMode -DownloadMode Lan
   Get-DODownloadMode
   ```

   - `Lan` が出ればよい
   - Windows の既定も `Lan` なので、手順 37 で `Lan` だったなら何も変わらない

1. 「Windows Hello サインインのみを許可する」を切る。

   ```powershell
   $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -Path $k -Name DevicePasswordLessBuildVersion -Type DWord -Value 0
   Get-ItemProperty -Path $k | Format-List DevicePasswordLessBuildVersion
   ```

   - `DevicePasswordLessBuildVersion : 0` が出ればよい
   - サインインの画面で、PIN のほかにパスワードも選べるようになる

1. スタートの検索で、Web（Bing）の結果を出さないようにする。

   ```powershell
   $k = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -Path $k -Name DisableSearchBoxSuggestions -Type DWord -Value 1
   Get-ItemProperty -Path $k | Format-List DisableSearchBoxSuggestions
   ```

   - `DisableSearchBoxSuggestions : 1` が出ればよい
   - 効くのは、手順 55 の再起動の後

1. デスクトップの Edge と UniGet UI のショートカットを消し、Edge が作り直したら消すようにする。

   ```powershell
   $k = 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -Path $k -Name RemoveDesktopShortcutDefault -Type DWord -Value 1
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
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない（手順 35 から）'; return }
     $now = (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue).'Scancode Map'
     $nowHex = if ($now) { ($now | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' } else { '' }
     if ($nowHex -and $nowHex -ne $want) { Write-Error "中断: 別の Scancode Map がある（$nowHex）"; return }
     if (-not $nowHex) { New-ItemProperty -Path $key -Name 'Scancode Map' -PropertyType Binary -Value ([byte[]]($want -split ' ' | ForEach-Object { [Convert]::ToByte($_, 16) })) | Out-Null }
     'Scancode Map = {0}' -f ((((Get-ItemProperty -Path $key).'Scancode Map') | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')
   }
   ```

   - `Scancode Map = 00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00` が出ればよい
   - 同じ値がもうあれば、何も書かずに同じ行を出す（何度貼ってもよい）
   - `中断: 別の Scancode Map がある` が出たら、ほかのキーの割り当てがある。消さないように止めている（両方を使うなら、その値を手で直す。数を 1 つ増やし、終わりの印の前に `1D 00 3A 00` を足す）
   - 効くのは、手順 55 の再起動の後

1. AlmaLinux とデュアル ブートし、AlmaLinux の時計を UTC にしているときだけ、Windows も UTC にする。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name RealTimeIsUniversal -Type DWord -Value 1
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' | Format-List RealTimeIsUniversal
   ```

   - `RealTimeIsUniversal : 1` が出ればよい
   - 効くのは、手順 55 の再起動の後。時刻がずれていたら、設定の「時刻と言語」→「日付と時刻」の「今すぐ同期」で合わせ直す
   - AlmaLinux の `timedatectl` の `RTC in local TZ:` が `yes`（`/etc/adjtime` の 3 行目が `LOCAL`）なら、この手順は飛ばす。AlmaLinux のインストーラは、Windows を見つけると `LOCAL` にする（[windows-dual-boot.md の注意点](windows-dual-boot.md#注意点)）
   - デュアル ブートしない PC でも、この手順は飛ばす

1. US 配列（101/102 キー）のキーボードを使うときだけ、キーボードの種類を変える。

   ```powershell
   $k = 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters'
   Set-ItemProperty -Path $k -Name 'LayerDriver JPN' -Type String -Value 'kbd101.dll'
   Set-ItemProperty -Path $k -Name OverrideKeyboardIdentifier -Type String -Value 'PCAT_101KEY'
   Set-ItemProperty -Path $k -Name OverrideKeyboardType -Type DWord -Value 7
   Set-ItemProperty -Path $k -Name OverrideKeyboardSubtype -Type DWord -Value 0
   Get-ItemProperty -Path $k | Format-List 'LayerDriver JPN', OverrideKeyboardIdentifier, OverrideKeyboardType, OverrideKeyboardSubtype
   ```

   - `LayerDriver JPN : kbd101.dll`・`OverrideKeyboardIdentifier : PCAT_101KEY`・`OverrideKeyboardType : 7`・`OverrideKeyboardSubtype : 0` が出ればよい
   - JIS 配列（日本語の 106/109 キー）のキーボードなら、この手順は飛ばす
   - 効くのは、手順 55 の再起動の後。US 配列には半角/全角のキーが無いので、日本語の入力の切り替えは、手順 31 の Ctrl+Space（または Alt+`）で行う

1. WSL を使えるように、Windows の機能を入れる（ディストリビューションは再起動の後に入れる）。

   ```powershell
   wsl.exe --install --no-distribution
   ```

   - 必要な機能（仮想マシン プラットフォーム）を入れた旨と、再起動を求める旨の行が出ればよい
   - もう入っていれば、何もしない
   - **注意**: この後は Hyper-V が動くので、[VirtualBox](virtualbox.md#windows-11-で使う) の VM は Hyper-V の上で動く。処理が遅くなる場合は、[VirtualBox の注意点](virtualbox.md#注意点)を確認する

1. 再起動する。

   ```powershell
   Restart-Computer
   ```

   - 保存していない作業があれば、先に保存する（すぐに再起動が始まる）
   - ほかのユーザーがサインインしていると、エラーで止まる。そのときは、スタートメニューの電源から再起動する
   - **次の手順は、起動してサインインしてから行う**

1. キーボードで、Caps Lock・Ctrl+Space・配列を確かめる。

   - メモ帳を開いて何か打ち、Caps Lock を押したまま A を押すと、全部が選ばれる（Ctrl+A）
   - Caps Lock だけを押しても、Caps Lock のランプは点かず、大文字にもならない
   - 日本語の配列（JIS）のキーボードでは、「英数」（Caps Lock）のキーが Ctrl になる
   - Ctrl+Space を押すたびに、IME のオンとオフが入れ替わる（タスクバーの「あ」と「A」）
   - 手順 53 を行ったなら、記号が US 配列の位置で出る（Shift+2 で `@`）

1. エクスプローラー・タスクバー・スタートが変わったことを確かめる。

   - ファイルかデスクトップを右クリックすると、「その他のオプションを確認」を選ばなくても、「送る」「プロパティ」などの並ぶ旧形式のメニューが出る
   - エクスプローラーを開くと「PC」が出て、ファイル名に拡張子が付き、隠しファイルも見える
   - タスクバーのアイコンが左に寄り、タスク ビュー・検索・ウィジェットのボタンが無く、時計に秒が出る。全体が濃い色になっている
   - スタートを開いて文字を打っても、Web（Bing）の結果が出ない（手順 49。出たら、[検証記録](verification/windows-setup.md)・[参考資料](reference/windows-setup.md)）
   - デスクトップに Edge と UniGet UI のショートカットが無い

1. タスクバーとスタートの、要らないピン留めを外す。

   - タスクバーのアイコン（Microsoft Edge・Microsoft Store など）を右クリックし、「タスクバーからピン留めを外す」
   - スタートを開き、ピン留めされたアプリを右クリックし、「スタートからピン留めを外す」
   - Copilot は外さない（利用者の選択）。使うアプリは残す

1. スタートメニューから UniGet UI を起動し、WinGet と Scoop が使えることを確かめる。

   - スタートメニューで「UniGetUI」を探して開く
   - 初回は、使い方の案内や設定の問いが出ることがある。読んで進める
   - 左の「パッケージマネージャー」で、WinGet と Scoop が有効で「利用可能」になっていることを確かめる（版は、それぞれの「バージョンを表示」で出る）
   - 「インストール済みのパッケージ」に、手順 22 で scoop で入れた `scoop-search` と、winget の `UniGetUI` などが出る
   - git が無い旨の警告が出たら、この文書の後に [git.md](git.md#windows-11-で-git-for-windows-を入れる) で Git for Windows を入れる（scoop の `git` は入れない）

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - 手順 30 の後なので、Windows Terminal の中に開く。複数行のブロックを貼ると出る警告では、「強制的に貼り付け」を押す

1. 再起動の後の状態を確かめる。

   ```powershell
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
     - `ComputerName` が手順 36 の `PC_NAME`（大文字）、`CtrlEnter : AddLine`、`ScancodeMap : 00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00`
     - `Keyboard` は、手順 53 を行ったなら `kbd101.dll`
     - `LongPaths : 1`・`DeveloperMode : 1`・`Sudo : 3`・`Hibernate : 0`
     - `RemoteDesktop : 0`（手順 44 を行ったとき）・`LanCategory : Private`
     - `Hypervisor : True`（手順 54 で WSL の機能を入れたので）

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
   wsl.exe --list --verbose
   wsl.exe --distribution AlmaLinux-10 -- head -n 2 /etc/os-release
   ```

   - `AlmaLinux-10` の行の `VERSION` が `2` で、`NAME="AlmaLinux"` と `VERSION="10.2 …"` の形の行が出ればよい（版は入れた日のイメージ）
   - 冒頭の 2 行は、この PowerShell セッションで WSL の出力とコンソールの読み取りを UTF-8 にそろえる（手順 62 も同じ）

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

---

## Wake on LAN を使う（任意）

- 電源を切った（シャットダウンした）この PC を、LAN の別の PC から起こせるようにする。有線 LAN だけ（Wi-Fi では使えない）
- 前提: 手順 41（休止状態を切ると、高速スタートアップも切れる）と手順 42（アダプターの省電力）。この節の手順 2〜4・8 は、この節の手順 1 で開く管理者の Windows PowerShell（5.1）に貼る
- **この節の手順 4 で再起動して UEFI の画面に入り、この節の手順 5 は UEFI の画面、この節の手順 6 はこの PC、この節の手順 7 は LAN の別の PC で行う**
- Windows の側の値は Microsoft の文書の標準の名前（`*WakeOnMagicPacket`）だけを変える。アダプターに独自の項目があれば、この節の手順 3 の表で確かめる

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. 変数を設定する。

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # 有線 LAN の接続（自動）。<LAN_IF>
   'LAN_IF = {0}' -f $LAN_IF
   ```

   - 手順 36 の 2 つ目のブロックと同じ式。Wi-Fi の名前が出たら、`$LAN_IF = 'イーサネット'` のように有線 LAN の名前に直す

1. アダプターのマジック パケットでの起動を有効にし、MAC アドレスを表示する。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error 'この節の手順 2 の $LAN_IF が空'
   } else {
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
   - `入力された環境オプションが見つかりませんでした。(203)` が出て再起動しないときは、ファームウェアがこの指定に対応していないことがある。スタートメニューの電源から再起動し、起動の直後に機種のキー（F2・Del など）を押して UEFI の設定の画面に入る
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
     Get-NetAdapterAdvancedProperty -Name $LAN_IF -RegistryKeyword '*WakeOnMagicPacket' | Format-Table DisplayName, DisplayValue
   }
   ```

   - 新しい PowerShell なら、先にこの節の手順 2 を貼る
   - UEFI の Wake on LAN も、この節の手順 4・5 と同じように入って切る

---

## リモートから再起動する手段を増やす（任意）

> [!IMPORTANT]
> - この節は[実施手順](#実施手順)を通した後に行う。少なくとも[手順 43](#実施手順)（LAN をプライベート）が要る。確実に戻すには[手順 41](#実施手順)（放置で眠らない）・[手順 42](#実施手順)（アダプターの省電力を切る）・[手順 64](#実施手順)（自動サインイン）
> - 手段は独立しているので、要るものだけ行う（「〜したいときだけ」の手順は飛ばしてよい）。この節の手順 2〜7・撤去の手順は、この節の手順 1 で開く管理者の Windows PowerShell（5.1）に貼る
> - **別の PC で動かすトリガーのコマンドは、その PC で実行する**（AlmaLinux のシェルか、別の Windows の PowerShell）

- リモートの操作ができなくなったときに備えて、再起動の経路を増やす。1 つが死んでも別の経路で立ち直せるようにする
- 既にある接続からの再起動（この節の手順にはしない）
  - SSH でつながるなら、ログインして `Restart-Computer`（Administrators の一員の SSH のセッションは昇格済みで、UAC は要らない。[Windows の OpenSSH サーバー](windows-openssh-server.md)）。sshd は再起動の後に自動で起動する
  - RDP でつながるなら、スタートメニューの電源の「再起動」か `Restart-Computer`（[手順 44](#実施手順) で有効。再起動の後はロック画面に戻るが、また入れる）
  - [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md) のセッションからも再起動できるが、そのタスクはトリガーが無いので再起動の後は戻らない。戻すにはこの節の手順 7
- この節で足す手段: クラッシュ時の自動再起動（手順 3）・別の PC からのネットワーク再起動（手順 4・5）・ネットワークが切れたときの自動再起動（手順 6）
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
   'LAN_IF = {0}' -f $LAN_IF
   'WATCHDOG_HOST = {0}' -f $WATCHDOG_HOST
   ```

   - `LAN_IF` に Wi-Fi の名前が出たら、`$LAN_IF = 'イーサネット'` のように有線 LAN の名前に直す
   - `WATCHDOG_HOST` は、LAN の中でいつも応答する相手に変えてもよい（既定ゲートウェイ以外にするとき）

1. クラッシュ（ブルースクリーン）で止まったときに自動で再起動する設定を確かめる（既定で有効）。

   ```powershell
   $k = 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'
   if ((Get-ItemProperty -Path $k -ErrorAction SilentlyContinue).AutoReboot -ne 1) { Set-ItemProperty -Path $k -Name AutoReboot -Type DWord -Value 1 }
   Get-ItemProperty -Path $k | Format-List AutoReboot
   ```

   - `AutoReboot : 1` が出ればよい（既定で 1。0 だったときはこの手順で 1 にする）
   - これは OS が応答するときの再起動には関係せず、カーネルが止まったときだけ効く

1. 別の PC から OS 越しに再起動したいときだけ、SMB のリモートシャットダウンを開ける。

   ```powershell
   Set-NetFirewallRule -Name FPS-SMB-In-TCP -Enabled True -Profile Private
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name LocalAccountTokenFilterPolicy -Type DWord -Value 1
   Get-NetFirewallRule -Name FPS-SMB-In-TCP | Format-Table Name, Enabled, Profile, Direction, Action
   Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' | Format-List LocalAccountTokenFilterPolicy
   ```

   - `FPS-SMB-In-TCP … True  Private  Inbound  Allow` と `LocalAccountTokenFilterPolicy : 1` が出ればよい
   - 仕組み: `shutdown /m` も `net rpc shutdown` も、`\PIPE\InitShutdown` の名前付きパイプを SMB（TCP 445）で使う。再起動には Administrators が既定で持つ「リモート システムからの強制シャットダウン」（`SeRemoteShutdownPrivilege`）と、`LocalAccountTokenFilterPolicy = 1` が要る（[参考資料](reference/windows-setup.md)）
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
   Get-NetFirewallRule -Group '@FirewallAPI.dll,-30267' | Format-Table Name, Enabled, Profile, Direction, Action
   ```

   - `WINRM-HTTP-In-TCP` が `True  Private` で、`WINRM-HTTP-In-TCP-NoScope` が `False` になればよい（WinRM は TCP 5985 で待ち受ける）
   - Windows 11 では、`WINRM-HTTP-In-TCP` は接続元を同じサブネット（`LocalSubnet`）に絞った規則で、`Enable-PSRemoting` は接続元を絞らない `WINRM-HTTP-In-TCP-NoScope` を有効にする。後者は切る
   - 1 行目は、`WINRM-HTTP-In-TCP` を既定のパブリックに戻す（無効でプライベートのままだと、`Enable-PSRemoting` が `エラー:1 つ以上の更新手順を終了できませんでした。` で止まり、後ろの行が動かずに `-NoScope` が開いたまま残る。[参考資料](reference/windows-setup.md)）
   - `Enable-PSRemoting` も `LocalAccountTokenFilterPolicy` を 1 にする（この節の手順 4 と共有）
   - 別の Windows から送る前に、送る側の管理者の PowerShell で、この PC を `TrustedHosts` に足す（ドメインに入っていない PC は、足していないと `TrustedHosts 構成設定に追加されている必要があります` の旨のエラーで止まる）
     - `WSMan:\localhost` は WinRM のサービスが動いていないと使えないので、止まっていれば先に `Start-Service WinRM` を行う
     - 足す前の値を `(Get-Item WSMan:\localhost\Client\TrustedHosts).Value` で控えてから、`Set-Item WSMan:\localhost\Client\TrustedHosts -Value <WIN_HOST> -Concatenate -Force` を行う
     - 戻し方は、この節の手順 9 の箇条書き
   - 別の Windows で動かすトリガー: `Invoke-Command -ComputerName <WIN_HOST> -Credential <WIN_USER> -ScriptBlock { Restart-Computer -Force }`（WinRM を使うので、`Restart-Computer -ComputerName` の既定の WMI/DCOM より開けるポートが少ない）
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
     Get-ScheduledTask -TaskName 'net-watchdog' | Format-List TaskName, State
   }
   ```

   - `net-watchdog  Ready` が出ればよい。SYSTEM として、起動時と 5 分ごとに動く
   - 起動時のトリガーなので、登録しただけでは動かない。次に起動したときから動く
   - 歯止め: 稼働 60 分未満は何もしない（起動直後に人が直す余地を残す）。`WATCHDOG_HOST` に 3 回 ping して、届けば失敗の数（`HKLM:\SOFTWARE\setup-notes\net-watchdog` の `Fails`）を 0 に戻し、6 回続けて届かなければ（約 30 分）再起動する
   - **注意**: 相手がずっと落ちていると再起動を繰り返す（節のリードの `[!WARNING]`）。`$limit` を増やすと、再起動までの猶予が延びる

1. Remote Control を再起動の後も使いたいときだけ、タスクをログオン時に自動で始まるようにする。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if (-not (Get-ScheduledTask -TaskName 'claude-remote-control' -ErrorAction SilentlyContinue)) { Write-Error '中断: claude-remote-control のタスクが無い（先に Claude Code の Remote Control（Windows）を設定する）'; return }
     $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
     Set-ScheduledTask -TaskName 'claude-remote-control' -Trigger (New-ScheduledTaskTrigger -AtLogOn -User $me) | Out-Null
     (Get-ScheduledTask -TaskName 'claude-remote-control').Triggers | Format-Table -AutoSize
   }
   ```

   - 前提: [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md) を設定済みで、この PC のデスクトップに同じユーザーでサインインする（[手順 64](#実施手順) の自動サインイン）
   - ログオンのトリガーが 1 つ表示されればよい。次にそのユーザーでサインインしたときから、タスクが自動で始まる

1. 元に戻すときは（この節の手順 4 を行ったとき）、SMB のリモートシャットダウンを閉じる。

   ```powershell
   Set-NetFirewallRule -Name FPS-SMB-In-TCP -Enabled False
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

1. 元に戻すときは（この節の手順 4 も手順 5 も使わないとき）、UAC のリモート制限を元に戻す。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name LocalAccountTokenFilterPolicy -Type DWord -Value 0
   Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' | Format-List LocalAccountTokenFilterPolicy
   ```

   - `LocalAccountTokenFilterPolicy : 0` になればよい（管理者のリモートログオンが、既定の制限に戻る）
   - この節の手順 4・5 のどちらかを使い続けるなら、この手順は行わない

1. 元に戻すときは（この節の手順 6 を行ったとき）、見張りのタスクと記録を消す。

   ```powershell
   Unregister-ScheduledTask -TaskName 'net-watchdog' -Confirm:$false
   Remove-Item -Path 'HKLM:\SOFTWARE\setup-notes\net-watchdog' -Recurse -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath 'C:\ProgramData\setup-notes\net-watchdog.ps1' -ErrorAction SilentlyContinue
   Get-ScheduledTask -TaskName 'net-watchdog' -ErrorAction SilentlyContinue
   ```

   - 何も出なければよい（タスクが消えた）
   - 空になったキー `HKLM:\SOFTWARE\setup-notes` とフォルダー `C:\ProgramData\setup-notes` は残る。ほかに使っていなければ、手で消してよい

1. 元に戻すときは（この節の手順 7 を行ったとき）、Remote Control のタスクのトリガーを外す。

   - [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md#ロールバック)のロールバックでタスクごと消す。トリガーの無い形で使い続けるなら、同書の[実施手順](windows-claude-remote-control.md#実施手順)の手順 5 で入れ直す

---

## プライバシーと広告の表示を切る（任意）

- 自分のユーザーの設定で、広告 ID・Web サイトに渡す言語リスト・診断データを使った提案・手書き入力と入力の改善・フィードバックの問い・オンライン音声認識・検索のクラウドと履歴・エクスプローラーの同期プロバイダーの通知を切る（手順 27・49 の続き）
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
   - キーが無いときだけ作る（既にあるキーを `New-Item -Force` で作り直すと、中の値が消える）
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
   - 「検索のアクセス許可」で、「クラウドのコンテンツ検索」の 2 つと「このデバイスの検索履歴」がオフ。「検索のハイライトを表示する」は、手順 49 の値で灰色になっている
   - この節の手順 2 で書いた項目がオンのまま出ていたら、その画面でオフにする
   - **次の手順は、設定を閉じてから貼る**

1. 元に戻すときは（この節の手順 2 を行ったとき）、控えた元の値に戻す。

   ```powershell
   & {
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\privacy-before.csv'
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

- 自分のユーザーの設定で、次のものを変える（手順 25・28・31 の続き）
  - 誤って押しやすいキー: 固定キー・フィルター キー・切り替えキーのショートカット、入力言語とキー配列の切り替え（Alt+Shift・Ctrl+Shift）
  - 窓とエクスプローラー: Alt+Tab の Edge のタブ、タイトル バーのシェイク、左の一覧のギャラリーとホーム、タスクバーの「タスクの終了」
  - アニメーション効果、効果音と起動音、ストレージ センサー
- 前提: [実施手順](#実施手順)を通した後に行う。この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る（管理者の権限は要らない）
- 項目は独立しているので、要らない手順は飛ばしてよい（この節の手順 1・2・13・14 は飛ばさない）
- **この節の手順 10・12・14 は画面で行い、この節の手順 13 でサインアウトしてサインインし直す**
- **この節の手順 11 のストレージ センサーは、ごみ箱に 30 日を超えて置いたファイルと一時ファイルを、毎月消す（取り戻せない）**。ごみ箱を置き場に使うなら、この節の手順 11・12 は行わないか、この節の手順 12 でごみ箱を「許可しない」にする
- 入力言語の切り替えのキーを切っても、Win+Space で切り替えられる
- 戻すときは、この節の手順 15〜23（行った手順のものだけ）。この節の手順 2 で控えた値を使う

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
     if (Test-Path -LiteralPath $rec) { "控えはもうある（書き換えない）: $rec" } else {
       New-Item -ItemType Directory -Path (Split-Path -Path $rec) -Force | Out-Null
       $rows | Export-Csv -LiteralPath $rec -NoTypeInformation -Encoding UTF8
       "控えた: $rec"
     }
     $rows | Format-Table -AutoSize
   }
   ```

   - `控えた:` か `控えはもうある` の行と、13 行の表（`Name` と `Value`）が出ればよい。値が無いものは空
   - 控えは `%LOCALAPPDATA%\setup-notes\display-before.csv`。初めて貼ったときだけ作り、2 回目からは書き換えない（この節の手順 16〜19 で使う）
   - `{e88865ea-…}`（ギャラリー）と `{f874310e-…}`（ホーム）は、自分のユーザーにキーが既にあったか（ふつうは `False`）

1. 固定キー・フィルター キー・切り替えキーのショートカットを切る。

   ```powershell
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
   - 切るのは、Shift を 5 回・右 Shift の長押し・Num Lock の長押しで機能をオンにするショートカットだけ。機能そのものはオフのまま
   - `無い:` が出たキーには、何も書かない
   - 効くのは、この節の手順 13 でサインインし直した後
   - **注意**: サインインし直すまで、設定の「アクセシビリティ」→「キーボード」を開かない（今の値で書き戻されることがある）

1. 入力言語とキー配列を切り替えるキー（Alt+Shift・Ctrl+Shift）を切る。

   ```powershell
   & {
     $t = 'HKCU:\Keyboard Layout\Toggle'
     if (-not (Test-Path -LiteralPath $t)) { New-Item -Path $t -Force | Out-Null }
     foreach ($n in 'Hotkey', 'Language Hotkey', 'Layout Hotkey') {
       $old = (Get-ItemProperty -LiteralPath $t).$n
       Set-ItemProperty -LiteralPath $t -Name $n -Type String -Value '3'
       '{0}: {1} -> {2}' -f $n, $old, (Get-ItemProperty -LiteralPath $t).$n
     }
   }
   ```

   - 3 行とも `->` の右が `3`（割り当てなし）ならよい
   - 効くのは、この節の手順 13 でサインインし直した後
   - Win+Space の切り替えは残る。半角/全角と、手順 31 の Ctrl+Space（IME のオン・オフ）には関係しない
   - タスクバーに「英語 (米国)」のキーボードが勝手に出るのは、この設定では防げない（言語の一覧から消す）

1. Alt+Tab に Edge のタブを出さず、タイトル バーのシェイクを切る。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   Set-ItemProperty -Path $adv -Name MultiTaskingAltTabFilter -Type DWord -Value 3
   Set-ItemProperty -Path $adv -Name DisallowShaking -Type DWord -Value 1
   Get-ItemProperty -Path $adv | Format-List MultiTaskingAltTabFilter, DisallowShaking
   ```

   - `MultiTaskingAltTabFilter : 3` と `DisallowShaking : 1` が出ればよい
   - Alt+Tab とスナップの候補に、Edge のタブを出さず、窓だけを並べる（設定の「システム」→「マルチタスク」の「タブを表示しない」）
   - シェイク（タイトル バーをつかんで振ると、ほかの窓が最小化される）は、Windows 11 の既定でもオフ。明示的に切る
   - 効くのは、この節の手順 13 でサインインし直した後

1. エクスプローラーの左の一覧から、ギャラリーとホームを消す。

   ```powershell
   foreach ($g in '{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}', '{f874310e-b6b7-47dc-bc84-b9e6b38f5903}') {
     '既にあった {0}: {1}' -f $g, (Test-Path -LiteralPath "HKCU:\Software\Classes\CLSID\$g")
     reg.exe add "HKCU\Software\Classes\CLSID\$g" /v System.IsPinnedToNameSpaceTree /t REG_DWORD /d 0 /f
     reg.exe query "HKCU\Software\Classes\CLSID\$g" /v System.IsPinnedToNameSpaceTree
   }
   ```

   - キーごと（`{e88865ea-…}` がギャラリー、`{f874310e-…}` がホーム）に、`既にあった` の行と、成功の 1 行と、`System.IsPinnedToNameSpaceTree    REG_DWORD    0x0` が出ればよい
   - PC 全体の登録を、自分のユーザーで上書きする（手順 26 と同じ、サポート外の方法）
   - 効くのは、エクスプローラーの窓をすべて閉じて開き直した後
   - 左の一覧を右クリックして「すべてのフォルダーを表示」をオンにすると、どちらも出る
   - 「Windows PowerShell (x86)」で貼ると、別の場所に書かれて効かない

1. タスクバーのアプリの右クリックに「タスクの終了」を出す。

   ```powershell
   $k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -LiteralPath $k -Name TaskbarEndTask -Type DWord -Value 1
   Get-ItemProperty -LiteralPath $k | Format-List TaskbarEndTask
   ```

   - `TaskbarEndTask : 1` が出ればよい
   - 設定の画面では、24H2 は「システム」→「開発者向け」、25H2 以降は「システム」→「詳細設定」の「タスクの終了」
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
     'ClientAreaAnimation : {0}' -f $on
     'MinAnimate          : {0}' -f (Get-ItemProperty -LiteralPath 'HKCU:\Control Panel\Desktop\WindowMetrics').MinAnimate
   }
   ```

   - `ClientAreaAnimation : 0` と `MinAnimate : 0` が出ればよい
   - すぐに効く（開いているアプリの一部は、起動し直した後）
   - 設定の「アクセシビリティ」→「視覚効果」の「アニメーション効果」に当たる（この節の手順 14 で確かめる）。Firefox・Chromium の Web ページにも、動きを減らす設定（`prefers-reduced-motion`）として伝わる
   - メニューのフェードなどの細かいアニメーション（「パフォーマンス オプション」の項目）は変えない

1. 効果音を「サウンドなし」にする（今の設定はファイルに控える）。

   ```powershell
   & {
     $bak = Join-Path $env:LOCALAPPDATA 'setup-notes\appevents.reg'
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
   - 控えは `%LOCALAPPDATA%\setup-notes\appevents.reg`。初めて貼ったときだけ作り、2 回目からは書き換えない（この節の手順 21 で戻す）
   - サウンドの画面の「サウンド設定」を「サウンドなし」にするのと同じ。次に鳴る音から効く
   - 後から入れたアプリが足したイベントには、音が入る。気になれば、この手順を貼り直す
   - 設定の「システム」→「通知」の「通知で音を鳴らす」と、起動音（この節の手順 10）は別の設定

1. 起動音も消すときだけ、サウンドの画面を開き、起動音を切る。

   ```powershell
   control.exe 'mmsys.cpl,,2'
   ```

   - 「サウンド」のタブが開く。「Windows スタートアップのサウンドを再生する」のチェックを外し、「OK」を押す
   - 管理者の確認（UAC）が出ることがある（起動音は PC 全体の設定）
   - 同じタブの「サウンド設定」が「サウンドなし」になっていれば、この節の手順 9 が効いている
   - **次の手順は、サウンドの画面を閉じてから貼る**

1. ストレージ センサーをオンにし、一時ファイルと古いごみ箱を毎月消すようにする（取り戻せない）。

   ```powershell
   & {
     $k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
     $set = [ordered]@{ '01' = 1; '04' = 1; '08' = 1; '256' = 30; '32' = 0; '512' = 0; '2048' = 30 }
     if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
     foreach ($n in $set.Keys) {
       $old = (Get-ItemProperty -LiteralPath $k).$n
       Set-ItemProperty -LiteralPath $k -Name $n -Type DWord -Value $set[$n]
       '{0}: {1} -> {2}' -f $n, $old, (Get-ItemProperty -LiteralPath $k).$n
     }
   }
   ```

   - 7 行が出て、`->` の右が `01`・`04`・`08` は `1`、`256` と `2048` は `30`、`32` と `512` は `0` ならよい
   - `->` の左（元の値）を控える。空なら値が無かった。数があったなら、この節の手順 23 で戻した後に、画面で同じにし直す
   - 毎月、一時ファイルと、ごみ箱に 30 日を超えて置いたファイルを消す。ダウンロード フォルダーは消さない
   - 対象はシステムのドライブ（C:）だけ。サインインしてオンラインの状態が 10 分以上続かないと動かない
   - **注意**: OneDrive にサインインしているなら、30 日開かないファイルがオンラインだけになりうる。この節の手順 12 で外す

1. この節の手順 11 を行ったときだけ、ストレージ センサーの画面で値を確かめ、OneDrive を外す。

   ```powershell
   Start-Process 'ms-settings:storagepolicies'
   ```

   - 「ユーザー コンテンツの自動クリーンアップ」がオン、「ストレージ センサーを実行するタイミング」が「毎月」、ごみ箱が「30 日」、ダウンロード フォルダーが「許可しない」ならよい
   - 「ローカルで利用可能なクラウド コンテンツ」に OneDrive があれば、「許可しない」にする
   - ごみ箱を置き場に使っているなら、ごみ箱を「許可しない」にする
   - 値が出ていなければ、この節の手順 13 でサインインし直した後に、もう一度開いて確かめる
   - **次の手順は、設定を閉じてから行う**

1. サインアウトして、同じユーザーでサインインし直す。

   - スタートメニューのユーザーのアイコンから「サインアウト」を選ぶ（スタートメニューの電源から再起動してもよい）
   - **次の手順は、サインインし、この節の手順 1 と同じ方法で管理者ではない窓を開いてから貼る**

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

1. 元に戻すときは（この節の手順 3 を行ったとき）、固定キーなどのショートカットを有効に戻す。

   ```powershell
   foreach ($k in 'StickyKeys', 'Keyboard Response', 'ToggleKeys') {
     $p = "HKCU:\Control Panel\Accessibility\$k"
     $v = (Get-ItemProperty -LiteralPath $p -ErrorAction SilentlyContinue).Flags
     if ($null -eq $v -or $v -notmatch '^[0-9]+$') { "無い: $k" } else {
       Set-ItemProperty -LiteralPath $p -Name Flags -Type String -Value ([string]([int]$v -bor 4))
       '{0}: {1} -> {2}' -f $k, $v, (Get-ItemProperty -LiteralPath $p).Flags
     }
   }
   ```

   - `StickyKeys: 506 -> 510` の形で出ればよい（値は消さない）
   - 効くのは、サインインし直した後

1. 元に戻すときは（この節の手順 4 を行ったとき）、切り替えのキーを控えた値に戻す。

   ```powershell
   & {
     $t = 'HKCU:\Keyboard Layout\Toggle'
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\display-before.csv'
     $before = @{}
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

   - 3 行に、この節の手順 2 で控えた値が出ればよい（控えが無いか空なら、既定とされる `1`・`1`・`2`）
   - 効くのは、サインインし直した後
   - 画面で戻すなら、設定の「時刻と言語」→「入力」→「キーボードの詳細設定」の「入力言語のホットキー」

1. 元に戻すときは（この節の手順 5 を行ったとき）、Alt+Tab とシェイクの値を控えた値に戻す。

   ```powershell
   & {
     $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\display-before.csv'
     $before = @{}
     if (Test-Path -LiteralPath $rec) { Import-Csv -LiteralPath $rec | ForEach-Object { $before[$_.Name] = $_.Value } } else { "控えが無い（値を消す）: $rec" }
     foreach ($n in 'MultiTaskingAltTabFilter', 'DisallowShaking') {
       if ($before[$n] -match '^[0-9]+$') { Set-ItemProperty -Path $adv -Name $n -Type DWord -Value ([int]$before[$n]) } else { Remove-ItemProperty -Path $adv -Name $n -ErrorAction SilentlyContinue }
     }
     Get-ItemProperty -Path $adv | Format-List MultiTaskingAltTabFilter, DisallowShaking
   }
   ```

   - 2 つに控えた値が出るか、控えで空だったものが空（既定）になればよい
   - 効くのは、サインインし直した後

1. 元に戻すときは（この節の手順 6 を行ったとき）、ギャラリーとホームを戻す。

   ```powershell
   & {
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\display-before.csv'
     $before = @{}
     if (Test-Path -LiteralPath $rec) { Import-Csv -LiteralPath $rec | ForEach-Object { $before[$_.Name] = $_.Value } } else { "控えが無い（値だけ消す）: $rec" }
     foreach ($g in '{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}', '{f874310e-b6b7-47dc-bc84-b9e6b38f5903}') {
       if ($before[$g] -eq 'False') { reg.exe delete "HKCU\Software\Classes\CLSID\$g" /f } else { reg.exe delete "HKCU\Software\Classes\CLSID\$g" /v System.IsPinnedToNameSpaceTree /f }
       '残っている {0}: {1}' -f $g, (Test-Path -LiteralPath "HKCU:\Software\Classes\CLSID\$g")
     }
   }
   ```

   - キーごとに、成功の 1 行と `残っている` の行が出ればよい
   - この節の手順 2 で無かったキー（ふつう）はキーごと消し（`False`）、あったキーは値だけを消す（`True`）
   - 効くのは、エクスプローラーの窓をすべて閉じて開き直した後

1. 元に戻すときは（この節の手順 7 を行ったとき）、「タスクの終了」の値を控えた値に戻す。

   ```powershell
   & {
     $k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings'
     $rec = Join-Path $env:LOCALAPPDATA 'setup-notes\display-before.csv'
     $before = @{}
     if (Test-Path -LiteralPath $rec) { Import-Csv -LiteralPath $rec | ForEach-Object { $before[$_.Name] = $_.Value } } else { "控えが無い（値を消す）: $rec" }
     if ($before['TaskbarEndTask'] -match '^[0-9]+$') { Set-ItemProperty -LiteralPath $k -Name TaskbarEndTask -Type DWord -Value ([int]$before['TaskbarEndTask']) } else { Remove-ItemProperty -LiteralPath $k -Name TaskbarEndTask -ErrorAction SilentlyContinue }
     Get-ItemProperty -LiteralPath $k -ErrorAction SilentlyContinue | Format-List TaskbarEndTask
   }
   ```

   - 控えた値が出るか、控えで空なら何も出なければよい（値が無いとオフ）

1. 元に戻すときは（この節の手順 8 を行ったとき）、アニメーション効果を戻す。

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
     'ClientAreaAnimation : {0}' -f $on
     'MinAnimate          : {0}' -f (Get-ItemProperty -LiteralPath 'HKCU:\Control Panel\Desktop\WindowMetrics').MinAnimate
   }
   ```

   - `ClientAreaAnimation : 1` と `MinAnimate : 1` が出ればよい（すぐに効く）
   - 設定の「アクセシビリティ」→「視覚効果」の「アニメーション効果」をオンにしてもよい

1. 元に戻すときは（この節の手順 9 を行ったとき）、控えた効果音の設定を書き戻す。

   ```powershell
   & {
     $bak = Join-Path $env:LOCALAPPDATA 'setup-notes\appevents.reg'
     if (-not (Test-Path -LiteralPath $bak)) { Write-Error "中断: 控えが無い: $bak"; return }
     reg.exe import $bak
     'Scheme : {0}' -f (Get-ItemProperty -Path 'HKCU:\AppEvents\Schemes').'(default)'
   }
   ```

   - 成功の 1 行と、控えたときのスキーム（ふつうは `.Default`）が出ればよい
   - `中断: 控えが無い` が出たら、サウンドの画面（この節の手順 10 と同じ）の「サウンド設定」を「Windows 標準」にする
   - 控えのファイルは残る。要らなければ手で消す

1. 元に戻すときは（この節の手順 10 を行ったとき）、サウンドの画面で起動音を戻す。

   ```powershell
   control.exe 'mmsys.cpl,,2'
   ```

   - 「Windows スタートアップのサウンドを再生する」にチェックを入れ、「OK」を押す
   - **次の手順は、サウンドの画面を閉じてから貼る**

1. 元に戻すときは（この節の手順 11 を行ったとき）、ストレージ センサーの値を消す。

   ```powershell
   $k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'
   foreach ($n in '01', '04', '08', '256', '32', '512', '2048') { Remove-ItemProperty -LiteralPath $k -Name $n -ErrorAction SilentlyContinue }
   Get-ItemProperty -LiteralPath $k -ErrorAction SilentlyContinue | Format-List '01', '04', '08', '256', '32', '512', '2048'
   ```

   - 7 つが空ならよい。ストレージ センサーはオフに戻る（空きが少ないときに、Windows がオンにすることがある）
   - この節の手順 11 の `->` の左に数があったなら、設定の「ストレージ センサー」で同じにし直す
   - この節の手順 12 で OneDrive やごみ箱を変えたなら、同じ画面で戻す

---

## Edge の常駐をポリシーで止める（任意）

- Edge のスタートアップ ブースト（サインインのときに Edge を裏で起動しておく）と、閉じた後も拡張機能とアプリを動かし続けるバックグラウンドの実行を、PC 全体のポリシーで切る
- 前提: [実施手順](#実施手順)を通した後に行う。この節のブロックは、この節の手順 1 で開く**管理者の** Windows PowerShell（5.1）に貼る（PC 全体のポリシーなので、すべてのユーザーにかかる）
- **この節の手順 2 のポリシーを置くと、Edge に「組織によって管理されている」旨が出て、Edge の設定の 2 つの切り替えが灰色になる**。出したくないなら、この節の手順 2 の代わりにこの節の手順 3（画面だけで切る）を行う
- 手順 50 の Edge Update のポリシー（`EdgeUpdate` のキー）とは別のキー（`Edge`）に書く
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
   Get-ItemProperty -Path $k | Format-List StartupBoostEnabled, BackgroundModeEnabled
   ```

   - `StartupBoostEnabled : 0` と `BackgroundModeEnabled : 0` が出ればよい
   - キーが無いときだけ作る（既にあるキーを `New-Item -Force` で作り直すと、ほかの Edge のポリシーが消える）
   - 開いている Edge には、開き直すか、`edge://policy` の「ポリシーの再読み込み」で効く
   - 手順 32 で止めた `MicrosoftEdgeAutoLaunch_*` の行は、無くなることがある（手順 32 と[ロールバック](#ロールバック)の手順 8 は、無いものを飛ばす）

1. （この節の手順 2 の代わりに）管理の表示を出したくないときは、Edge の設定の画面で 2 つを切る。

   - Edge のアドレス バーに `edge://settings/system` を入れて開く（「設定」→「システムとパフォーマンス」→「システム」）
   - 「スタートアップ ブースト」をオフにする
   - 「Microsoft Edge が終了してもバックグラウンドの拡張機能およびアプリの実行を続行する」をオフにする

1. Edge で、2 つが切れていることを確かめる。

   - `edge://settings/system` で、2 つがオフになっている（この節の手順 2 を行ったなら、灰色で変えられない）
   - この節の手順 2 を行ったなら、`edge://policy` に `StartupBoostEnabled` と `BackgroundModeEnabled` が、値 `false`・状態 `OK` で出る
   - Edge の窓をすべて閉じると、通知領域に Edge のアイコンが残らない
   - サインインし直した後も `msedge.exe` が見えることがある（Edge Update のサインインのときのコマンドが起動すると広く言われる。[参考資料](reference/windows-setup.md)）

1. 元に戻すときは（この節の手順 2 を行ったとき）、管理者の PowerShell で、2 つのポリシーを消す。

   ```powershell
   $k = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
   foreach ($n in 'StartupBoostEnabled', 'BackgroundModeEnabled') { Remove-ItemProperty -Path $k -Name $n -ErrorAction SilentlyContinue }
   Get-ItemProperty -Path $k -ErrorAction SilentlyContinue | Format-List StartupBoostEnabled, BackgroundModeEnabled
   ```

   - 2 つが空ならよい
   - キーは消さない（ほかの Edge のポリシーがありうる）
   - Edge を開き直すと、2 つの切り替えをまた変えられる

1. 元に戻すときは（この節の手順 3 を行ったとき）、Edge の設定の画面で 2 つをオンに戻す。

   - `edge://settings/system` で、この節の手順 3 でオフにした 2 つをオンにする

---

## CopyQ を使う（任意）

- クリップボードの履歴は、Windows の履歴（Win+V）ではなく、CopyQ に持たせる
- 前提: 手順 9〜15（winget を使えること）。この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る
- **この節の手順 3 で CopyQ を起動し、この節の手順 5・6 は画面で行う**
- CopyQ は窓を持つアプリなので、`copyq.exe` のコマンドの結果は、`| Write-Output` を付けないと出ない
- **CopyQ の履歴は、暗号化されずにディスクに残る**。パスワードなどをコピーするときは、[注意点](#注意点)を読む
- 戻すときは、この節の手順 7・8

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）

1. CopyQ を、自分のユーザーに入れる。

   ```powershell
   winget install --exact --id hluk.CopyQ --source winget --scope user --accept-source-agreements --accept-package-agreements
   winget list --exact --id hluk.CopyQ
   ```

   - 最後の表に `CopyQ` と `hluk.CopyQ` の行が出ればよい（版は実行した日の最新）
   - 管理者の確認（UAC）は出ないはず。winget が、出るかもしれない旨の行を出すことはある
   - `%LOCALAPPDATA%\Programs\CopyQ` に入る。デスクトップのショートカットと、サインインのときの起動は作らない。入れた直後は起動しない

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
     & $copyq config autostart true | Write-Output
     Test-Path -LiteralPath (Join-Path ([Environment]::GetFolderPath('Startup')) 'copyq.lnk')
     'EnableClipboardHistory: {0}' -f (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Clipboard' -ErrorAction SilentlyContinue).EnableClipboardHistory
   }
   ```

   - `true`・`True`・`EnableClipboardHistory:` の 3 行が出て、最後の右が空か `0` ならよい
   - 先に `false` を送るのは、前の CopyQ の設定（`autostart=true`）が残っていても、起動のショートカットを作り直すため
   - 起動のショートカットは、スタートアップ フォルダーの `copyq.lnk`（手順 32 の `Run` の一覧には出ない）
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
     - Win+Shift+V と Ctrl+Win+Alt+V（手順 23 の PowerToys の高度な貼り付け）
     - Ctrl+Shift+V（多くのアプリの、書式なしの貼り付け）
     - Ctrl+Space（手順 31 の IME）
   - Windows キーを含むキーは、OS が予約していて効かないことがある。効かなくても、画面には何も出ない
   - 管理者の窓には、CopyQ から自動では貼れない。クリップボードには入るので、右クリックで貼る

1. 元に戻すときは、サインインのときの起動を外し、CopyQ を止める。

   ```powershell
   & {
     $copyq = "$env:LOCALAPPDATA\Programs\CopyQ\copyq.exe"
     $lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'copyq.lnk'
     & $copyq config autostart false | Write-Output
     Remove-Item -LiteralPath $lnk -ErrorAction SilentlyContinue
     & $copyq exit | Write-Output
     Test-Path -LiteralPath $lnk
   }
   ```

   - `false` と、最後に `False` が出て、通知領域から CopyQ のアイコンが消えればよい
   - CopyQ が動いていなければ、サーバーにつながらない旨が出る。それでも `copyq.lnk` は消える
   - アンインストーラは `copyq.lnk` を消さないので、先にこの手順で消す

1. 元に戻すときは、CopyQ を外す。

   ```powershell
   winget uninstall --exact --id hluk.CopyQ --source winget
   winget list --exact --id hluk.CopyQ
   ```

   - 最後に、入っているパッケージが見つからない旨が出ればよい
   - 設定と履歴は残る（`%APPDATA%\copyq`。17.0.0 からは `%LOCALAPPDATA%\copyq` も）。要らなければ手で消す（取り戻せない）
   - この節の手順 5 で Windows の履歴を切ったなら、使うときは設定の「システム」→「クリップボード」でオンに戻す

---

## PowerToys のユーティリティを絞る（任意）

- 手順 23 で入れた PowerToys の、既定で有効なユーティリティのうち、使わないものを設定ファイルで切る（手順 23 の続き）
- 前提: 手順 23。この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る（管理者の権限は要らない）
- **この節の手順 4・7 は通知領域で PowerToys を終了し、この節の手順 6 は PowerToys の設定の画面で行う**
- PowerToys は起動のときにだけ設定ファイルを読むので、終了してから書き、起動し直す
- 切るユーティリティは好みで選ぶ。この節の手順 2 の `$PT_OFF` は案で、Always On Top・コマンド パレット・PowerRename・File Locksmith・Peek・エクスプローラーのプレビュー・Image Resizer は残す（[参考資料](reference/windows-setup.md)）
- 「起動時に実行」はオン、「常に管理者として実行」はオフのまま変えない。自動の更新の取得も変えない
- Keyboard Manager は使わない（既定でオフ。Caps Lock は手順 51 で変える）
- 戻すときは、この節の手順 7・8

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）

1. 変数を設定する。

   ```powershell
   $PT_OFF = 'FindMyMouse', 'MouseHighlighter', 'FancyZones', 'ColorPicker', 'Measure Tool', 'Awake'   # 切るユーティリティ（設定ファイルの名前）
   $PT_EXE = @((Get-Process -Name PowerToys -ErrorAction SilentlyContinue).Path) + "$env:LOCALAPPDATA\PowerToys\PowerToys.exe", "$env:LOCALAPPDATA\Programs\PowerToys\PowerToys.exe" | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1   # PowerToys.exe の場所（自動）
   'PT_OFF = {0}' -f ($PT_OFF -join ', ')
   'PT_EXE = {0}' -f $PT_EXE
   ```

   - `PT_OFF = FindMyMouse, …` と、`PT_EXE = C:\Users\<WIN_USER>\AppData\Local\PowerToys\PowerToys.exe` の形の 2 行が出ればよい
   - `PT_EXE` が空なら、PowerToys が見つからない。手順 23 を確かめる
   - `$PT_OFF` の名前は、設定ファイルの名前（空白を含むものがある）。変えるなら、この節の手順 3 の表の `Name` から選ぶ
   - 入る場所は Microsoft の資料どうしで食い違うので、動いている PowerToys から取る
   - 新しい窓を開いたら、このブロックを貼り直す

1. 今のユーティリティの有効・無効と、自動の起動を確かめる。

   ```powershell
   & {
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
   - 書くのは `enabled` の値だけで、ほかの設定は変えない
   - `中断: PowerToys が動いている` が出たら、この節の手順 4 に戻る（設定の窓が残っていても止まる）

1. PowerToys の設定の画面で、切ったユーティリティがオフになっていることを確かめる。

   - 通知領域の PowerToys のアイコンを右クリックし、「設定」で設定の窓を開く（ダブルクリックでも開く。1 回のクリックで開くのはクイック アクセス）
   - 「ダッシュボード」で、`$PT_OFF` のユーティリティがオフ、残したものがオンになっている
   - 同じことは、ユーティリティごとのスイッチでもできる（すぐに効く）
   - Peek は「Space で開く」をオンのままにする（オフにすると、起動のキーが手順 31 の IME と同じ Ctrl+Space に戻る）
   - Find My Mouse を使うなら、起動の方法を「マウスを振る」にする（左 Ctrl を 2 回のままでは、手順 51 で Ctrl にした Caps Lock を 2 回押しても出る）
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

- 手順 24 で入れた PowerShell 7 のプロファイルに、手順 16〜19 と同じ貼り付けの設定と、↑/↓ の履歴の検索と、入っているときだけ zoxide・starship を読む行を足す（手順 24 の続き）
- 前提: 手順 16〜19・24。この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る（PowerShell 7 の窓には貼らない）
- 書くのは PowerShell 7 のプロファイル（`Documents\PowerShell\Microsoft.PowerShell_profile.ps1`）で、手順 19 の Windows PowerShell 5.1 のプロファイルとは別のファイル
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
   - プロファイルは `C:\Users\<WIN_USER>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`（OneDrive でドキュメントをバックアップしていると、`OneDrive` の下）。無ければ作る
   - 何度貼ってもよい（同じ行は足さない）。プロファイルにほかの行があれば、そのまま残る
   - zoxide の行は、starship の行より前に置く（starship のプロンプトから zoxide の記録を呼ぶ。順の理由は[参考資料](reference/windows-setup.md)）
   - 開いている PowerShell 7 の窓には、開き直すまで効かない

1. Tab で補完の候補の一覧を出すときだけ、Tab の行を足す。

   ```powershell
   & {
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     $line = 'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete }  # windows-setup.md'
     if (-not (Test-Path -LiteralPath $p)) { Write-Error "中断: プロファイルが無い。この節の手順 2 を先に貼る: $p"; return }
     $text = Get-Content -LiteralPath $p -Raw
     if ($text -and $text.Contains($line)) { "すでにある: $line" } else {
       $add = $line
       if ($text -and -not $text.EndsWith("`n")) { $add = "`r`n" + $line }
       Add-Content -LiteralPath $p -Value $add -ErrorAction Stop
       "足した: $line"
     }
   }
   ```

   - `足した:` か `すでにある:` が出ればよい
   - Tab で、候補が一覧で出る（矢印で選んで Enter、Esc で取り消す）。既定の Tab は、候補を 1 つずつ入れ替える
   - 一覧を出す既定のキーの Ctrl+Space は、手順 31 で IME が受け取るので、その代わりになる

1. PowerShell 7 で、実行ポリシーとキーの割り当てを確かめる。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Get-ExecutionPolicy -List | Out-String -Width 120; Import-Module PSReadLine; . $PROFILE; Get-PSReadLineKeyHandler -Bound | Where-Object Key -in 'Ctrl+Enter', 'UpArrow', 'DownArrow', 'Tab' | Format-Table Key, Function -AutoSize | Out-String -Width 120 }
   ```

   - 次のとおりならよい
     - 実行ポリシーの表の `LocalMachine` か `CurrentUser` が `RemoteSigned`
     - キーの表の `Ctrl+Enter` が `AddLine`、`UpArrow` が `HistorySearchBackward`、`DownArrow` が `HistorySearchForward`（この節の手順 3 を行ったなら、`Tab` が `MenuComplete`）
   - `pwsh.exe` が見つからない旨が出たら、手順 24 を確かめる
   - 実行ポリシーがどれも `Undefined` なら、プロファイルは読まれず、キーは既定のまま（`Ctrl+Enter` が `InsertLineAbove`）。そうでなければ、この節の手順 5 は飛ばす

1. 実行ポリシーがどれも `Undefined` のときだけ、PowerShell 7 の CurrentUser を RemoteSigned にする。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Get-ExecutionPolicy -List }
   ```

   - 表の `CurrentUser` が `RemoteSigned` になればよい
   - PowerShell 7 の実行ポリシーは、手順 18 の Windows PowerShell 5.1 の値とは別に持つ（`Documents\PowerShell\powershell.config.json` に書かれる）
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
     if ($rest -eq $text) { "その行は無い: $p" } elseif ($rest -match '^(\uFEFF|\u00EF\u00BB\u00BF)?\s*$') { Remove-Item -LiteralPath $p; "消した: $p" } else { [System.IO.File]::WriteAllBytes($p, $enc.GetBytes($rest)); "その行だけ消した: $p" }
   }
   ```

   - プロファイルにほかの行が無ければ `消した:`、あれば `その行だけ消した:` が出る
   - 消すのは、行末が `  # windows-setup.md` の行だけ（PowerToys の Command Not Found などが足した行は残る）。ほかの行の文字コードは変えない
   - `Documents\PowerShell` のフォルダーは消さない（モジュールや `powershell.config.json` が入ることがある）
   - 開いている PowerShell 7 の窓には、閉じるまで設定が残る

1. 元に戻すときは（この節の手順 5 を行ったとき）、PowerShell 7 の CurrentUser の実行ポリシーを戻す。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser -Force; Get-ExecutionPolicy -List }
   ```

   - 表の `CurrentUser` が `Undefined` ならよい

---

## Windows Terminal のフォントと貼り付けの警告を変える（任意）

- Windows Terminal（手順 30 で既定の端末にした）の全プロファイルのフォントを HackGen Console NF にし、複数行を貼るときの警告を、要らなければ切る
- 前提: [HackGen Console NF の Windows 11 で使う](hackgen.md#windows-11-で使う)（入れた後にサインインし直すか、手順 55 で再起動した後）。この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る
- **この節の手順 5 は Windows Terminal の設定の画面で行う**
- 効くのは Windows Terminal で開く窓（管理者ではない窓と、Win+X の「ターミナル」・「ターミナル (管理者)」）だけ。スタートメニューから管理者として開いた PowerShell（conhost の窓）には効かない
- 管理者ではない窓に複数行のブロックを貼ると、「警告」の窓が出ることがある（Windows PowerShell 5.1 は、角かっこで囲む貼り付けを使わないため）。「強制的に貼り付け」を押す（出さないなら、この節の手順 4）
- コマンドで書くのは `settings.json` だけ。既定のプロファイル（Windows PowerShell）と、選んだらコピーする設定（`copyOnSelect`）は変えない
- 戻すときは、この節の手順 6

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（手順 30 の設定で、Windows Terminal の窓で開く）

1. Windows Terminal の設定ファイルを控え、今のフォントと警告の値を確かめる。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     $bak = "$path.windows-setup.bak"
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
   - `中断:` が出たら、何も書いていない。この節の手順 5 の画面で変える（設定の画面でリセットした後は、コメントの入ったファイルになる）
   - `Version` が 1.24 より前なら、この節の手順 4 は飛ばす（警告の値の形が違う）

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
     'face: {0}' -f ([IO.File]::ReadAllText($path) | ConvertFrom-Json).profiles.defaults.font.face
   }
   ```

   - `face: HackGen Console NF` が出ればよい
   - 保存した直後に、開いているタブにも効く（Windows Terminal がファイルを読み直す）
   - ファイルの字下げと記号の書き方は変わるが、中身は同じ
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

- WSL 2 のネットワークを、既定の NAT から、Windows と同じ IP を使うミラーに変える（手順 54・62 の続き）
- 前提: 手順 54・62・63。この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る（自分のユーザーの `%USERPROFILE%\.wslconfig` に書く）
- **この節の手順 4・7 の `wsl.exe --shutdown` は、動いているディストリビューションをすべて止める**（WezTerm の WSL のタブも切れる）。WSL の中の作業を保存してから貼る
- ミラーにして変わること
  - WSL からこの PC の Windows のサーバー（[Windows の OpenSSH サーバー](windows-openssh-server.md)など）には、`127.0.0.1` でつなぐ（`::1` は使えない。LAN の IP あてはつながらないはず）
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
   - WSL から Windows に ssh でつなぐときは、`ssh <WIN_USER>@127.0.0.1` にする（[Windows の OpenSSH サーバーの注意点](windows-openssh-server.md#注意点)）
   - `Connection refused` が出たら、Windows の sshd が動いていない（[Windows の OpenSSH サーバー](windows-openssh-server.md)の手順で確かめる）

1. 元に戻すときは、`.wslconfig` を元に戻す。

   ```powershell
   & {
     $path = Join-Path $env:USERPROFILE '.wslconfig'
     $bak = "$path.windows-setup.bak"
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
   wsl.exe --distribution AlmaLinux-10 -- wslinfo --networking-mode
   ```

   - `nat` が出ればよい
   - WSL から Windows のサーバーには、また LAN の IP あてにつなぐ

---

## シェルのツールを入れる（任意）

- Git Bash で使う starship・zoxide・fzf・eza・bat を、scoop で入れる（手順 20・21 の続き。AlmaLinux 10 では [AlmaLinux 10 の初期設定の手順 49](almalinux-setup.md#実施手順)で入れるもの）
- 前提: 手順 16〜21、[Git for Windows](git.md#windows-11-で-git-for-windows-を入れる)、Git Bash で通した [README の共通の bash 設定を先に入れる](../README.md#共通の-bash-設定を先に入れる)、[WezTerm](wezterm-nightly.md#windows-11-で使う)と自分用の設定（[設定ファイル](wezterm-nightly.md#設定ファイル)。新しいタブが Git Bash で開く）
- この節のブロックは、この節の手順 1 で開く**管理者ではない** Windows PowerShell（5.1）に貼る（scoop は自分のユーザーに入れる）
- **この節の手順 7・8 は WezTerm の新しいタブ（Git Bash）で、この節の手順 9 はブラウザで行う**
- Git Bash では、共通の bash 設定が、入っているツールを見つけて読む。`~/.bashrc` には書かない。Windows PowerShell 5.1 には読み込まない
- **zoxide は 0.9.9 に止めて入れる**（今の 0.10.0 は、Git Bash で移ったディレクトリを記録しない。[参考資料](reference/windows-setup.md)）。直った版が出たら、この節の手順 9・10 で上げる。ほかの 4 つは[更新](#更新)の手順 1・2 で上がる
- bat は VC++ ランタイム（`VCRUNTIME140.dll`）を使う。無ければ、[WezTerm の Windows 11 で使う](wezterm-nightly.md#windows-11-で使う)の手順 3 を管理者の窓で行う（この節の手順 2 で確かめる）
- PowerShell 7 でも starship と zoxide を使うなら、[PowerShell 7 のプロファイルを設定する（任意）](#powershell-7-のプロファイルを設定する任意)を通す（入っているときだけ読む行を置く。確かめるのは、その節の手順 6）
- 使い方と設定は、[AlmaLinux 10 の初期設定](almalinux-setup.md)の後ろの節（starship・fzf・eza・bat）。Git Bash のタブに、同じブロックを貼る
  - [fzf で fd と bat を候補とプレビューに使う（任意）](almalinux-setup.md#fzf-で-fd-と-bat-を候補とプレビューに使う任意)の `brew install fd`・`brew uninstall fd` は、この節の手順 1 の窓で `scoop install fd`・`scoop uninstall fd` にする
  - bat の設定ファイルは、[同書の節](almalinux-setup.md#bat-の設定ファイル)ではなく、この節の手順 6 で書く
- SSH のセッションの Git Bash でも使うなら、この節の手順 4 の後に、[Windows の OpenSSH サーバーの任意節](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の手順 1 を管理者の窓で貼る（`scoop install`・`scoop update` の後も貼り直す）
- **この節の手順 13 は、zoxide が覚えたディレクトリの履歴を消す（取り戻せない）**
- 戻すときは、この節の手順 11〜13（行った手順のものだけ）

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. 管理者ではないことと、前提と、ほかの方法で入れた同じツールが無いかを確かめる。

   ```powershell
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

   - `PowerShell : 5.1.…`・`Admin : False`・`BashConfig : True`・`VCRuntime : True` ならよい。`Admin : True` なら、窓を閉じてこの節の手順 1 から
   - `Scoop` が空なら、先に手順 20・21 を通す
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [Git for Windows](git.md#windows-11-で-git-for-windows-を入れる)を通す
   - `BashConfig : False` なら、先に Git Bash で [README の共通の bash 設定を先に入れる](../README.md#共通の-bash-設定を先に入れる)を通す
   - `VCRuntime : False` なら、[WezTerm の Windows 11 で使う](wezterm-nightly.md#windows-11-で使う)の手順 3 を管理者の窓で行ってから、このブロックを貼り直す
   - `Tools` が空なら、どれも入っていない
   - `C:\Users\<WIN_USER>\scoop\` の下の `shims\<名前>.exe` と `apps\starship\current\starship.exe` だけなら、scoop で入れたもの（この節の手順 4 は、入っているものを飛ばす）
   - ほかの場所（winget の `…\WinGet\Links\` など）が出たら、ほかの方法で入れたものがある。混ざらないよう、その方法で外してから始める
   - `Zoxide` が空か `zoxide 0.9.9` なら、この節の手順 3 は飛ばす

1. scoop の zoxide が 0.9.9 でないときだけ、外す。

   ```powershell
   scoop uninstall zoxide
   ```

   - `'zoxide' was uninstalled.` が出ればよい
   - 外さなくても、この節の手順 4 は 0.9.9 を並べて入れて切り替えるが、0.10.0 のフォルダー（`~\scoop\apps\zoxide\0.10.0`）が残る
   - 覚えたディレクトリの履歴（`%LOCALAPPDATA%\zoxide`）は残る。0.9.9 も同じ形で読む

1. scoop を上げてから 5 つを入れ、zoxide を 0.9.9 に止める。

   ```powershell
   scoop update
   scoop install fzf starship eza bat
   scoop install zoxide@0.9.9
   scoop hold zoxide
   ```

   - `scoop update` は `Scoop was updated successfully!` を出す（Git for Windows より前に scoop を入れた PC では、初めてのときに `Converting 'main' bucket to git repo...` も出る）
   - それぞれ `'<名前>' (<版>) was installed successfully!` の形の行が出て、最後に `zoxide is now held and can not be updated anymore.` が出ればよい（版は入れた日の最新。zoxide は `0.9.9`）
   - zoxide の 0.9.9 は、scoop が main のバケットの git の履歴から定義を取り出して入れる（`Resolving historical manifest for 'zoxide' (0.9.9)` の行が出る）
   - 2 行目は、もう入っているものを、何も出さずに飛ばす
   - zoxide の 0.9.9 がもう入っていれば、3 行目は `'zoxide' (0.9.9) is already installed.` の警告だけを出す（zoxide を 2 行目に並べると、scoop はこの警告で止まり、ほかの名前を入れない）
   - もう止めてあれば、`'zoxide' is already held.` が出る
   - starship は shim を作らず、`Adding ~\scoop\apps\starship\current to your path.` で自分のユーザーの `Path` に足す（この窓にも入る）
   - bat は `Setting user environment variable: BAT_CONFIG_DIR = …` で環境変数を足す（この窓にも入る）
   - `Notes` の、PowerShell の `$PROFILE` に starship の行を足す案内は行わない。`suggests installing` の行（VC++ ランタイム・less）も、入れなくてよい

1. 版と場所と、zoxide を止めたことを確かめる。

   ```powershell
   fzf --version
   zoxide --version
   starship --version
   eza --version
   bat --version
   (Get-Command fzf, zoxide, starship, eza, bat -All).Source
   scoop list zoxide
   ```

   - それぞれの版が出ればよい（`zoxide 0.9.9`・`starship 1.26.0`・`v0.23.5 [+git]`・`bat 0.26.1` の形）
   - `bat --version` が何も出さないか、DLL が見つからない旨のエラーになったら、VC++ ランタイムが無い（この節の手順 2 の `VCRuntime`）
   - 場所は、`C:\Users\<WIN_USER>\scoop\shims\` の下の `fzf.exe`・`zoxide.exe`・`eza.exe`・`bat.exe` と、`C:\Users\<WIN_USER>\scoop\apps\starship\current\starship.exe` の 5 行だけ
   - `scoop list` の `zoxide` の行は、`Version` が `0.9.9`、`Source` が `<auto-generated>`（前から main のバケットで入れた 0.9.9 なら `main`）、`Info` が `Held package`

1. bat の設定ファイル（`BAT_CONFIG_DIR` の下の `config`）に、3 行の設定を書く（中身があれば書き換えない）。

   ```powershell
   $BAT_THEME_NAME = 'ansi'   # 使うテーマ。ansi は端末の 16 色にそのまま従う（一覧は bat --list-themes）。<BAT_THEME_NAME>
   ```

   ```powershell
   & {
     if (-not $BAT_THEME_NAME) { Write-Error '中断: BAT_THEME_NAME が空のまま。値を入れて貼り直す'; return }
     $f = if ($env:BAT_CONFIG_PATH) { $env:BAT_CONFIG_PATH } elseif ($env:BAT_CONFIG_DIR) { Join-Path $env:BAT_CONFIG_DIR 'config' } else { '' }
     if (-not $f) { Write-Error '中断: BAT_CONFIG_DIR が無い。この節の手順 4 で bat を入れたかを確かめる'; return }
     if ((Test-Path -LiteralPath $f) -and [IO.File]::ReadAllText($f).Trim()) { "中身がある（書き換えない）: $f" } else {
       Set-Content -LiteralPath $f -Encoding ASCII -Value "--theme=`"$BAT_THEME_NAME`"", '--style="numbers,changes,header"', '--paging=never' -ErrorAction Stop
       "書いた: $f"
     }
     Get-Content -LiteralPath $f
   }
   ```

   - `書いた: C:\Users\<WIN_USER>\scoop\apps\bat\current\config` と、`--theme="ansi"`・`--style="numbers,changes,header"`・`--paging=never` の 3 行が出ればよい
   - 中身は [AlmaLinux 10 の初期設定の bat の設定ファイル](almalinux-setup.md#bat-の設定ファイル)の 3 行と同じ。Windows の bat は `~/.config/bat/config` を読まず、scoop が足した `BAT_CONFIG_DIR` の下を読む
   - 書いた中身は、scoop の控え（`~\scoop\persist\bat\config`）に残り、bat を上げても消えない
   - `中身がある（書き換えない）:` が出たら、前からの設定（`%APPDATA%\bat\config` から scoop が写したものなど）がある。何も変えていない
   - `中断:` が出たら、何も書いていない

1. WezTerm の新しいタブ（Git Bash）で、[AlmaLinux 10 の初期設定の手順 52〜55・57・58](almalinux-setup.md#実施手順)のブロックを貼る。

   - WezTerm を起動するか、新しいタブ（Ctrl+Shift+T）を開く。前から開いているタブで `. ~/.bashrc` を読み直さない（[同書の手順 50](almalinux-setup.md#実施手順)の補足と同じ）
   - 新しいタブのプロンプトが starship の形にならなければ、WezTerm の窓をすべて閉じて起動し直す
   - 成功の条件は、同書のそれぞれの手順と同じ。違うのは次のところ
     - `command -v` は `/c/Users/<WIN_USER>/scoop/shims/<名前>`（starship は `/c/Users/<WIN_USER>/scoop/apps/starship/current/starship`）。版は、この節の手順 5 と同じ
     - 同書の手順 53 の `bind -X` は、`"\C-r" "__fzf_history__"` のようにコロンの無い形で出る（Git Bash の bash 5.3）。WezTerm のシェル統合を読んでいれば、マウス報告よけの行も出る（そのままでよい）
     - 同書の手順 54 の見出しは、`Permissions` が `Mode` になり、`User` の列が無い。`Git` の列が出ればよい。`ll` は、Git for Windows の `ls -l` ではなく eza になる
     - 同書の手順 55 で `/etc/os-release` が無い旨のエラーが出たら、そのコマンドを `~/.bashrc` に変えて打つ。`MANPAGER` は `bat -plman` と出るが、Git Bash に `man` は無い
     - 同書の手順 57 の `cd /usr/share` は、Git for Windows の `C:\Program Files\Git\usr\share` に移る。同書の手順 58 の一覧には、その形（`C:\…`）で出る
   - 同書の手順 56（tmux）は行わない
   - 覚えたディレクトリは `%LOCALAPPDATA%\zoxide` に入る（PowerShell 7 の zoxide も同じものを使う）

1. 同じタブで、[同書の手順 60〜63](almalinux-setup.md#実施手順)のキーを押して、fzf を確かめる。

   - 同書の手順 60 の `fzf --version` は、この節の手順 7 で Git Bash の履歴に入っている
   - 同書の手順 61 をホーム（`C:\Users\<WIN_USER>`）で行うと、`AppData` の下のファイルも一覧に入る
   - 同書の手順 62 の `doc/bash` が一覧に無ければ、一覧にある別の語で絞る（`/usr/share` は Git for Windows のもの）
   - 日本語など ASCII 以外の文字では、絞り込めないことがある（Windows の fzf は、画面の一部に開いた一覧では ASCII 以外の文字を読めない）

1. zoxide を上げるときは、ブラウザで、Git Bash の記録を直した版が出たかを確かめる。

   - `https://github.com/ajeetdsouza/zoxide/releases` を開く
   - 0.10.0 より新しい版の変更点に、「Bash/Zsh: fix `z` failing on Cygwin/MSYS2」で始まる行があれば、直った版が出ている
   - 無ければ、この節の手順 10 は飛ばす（0.9.9 のまま使う）
   - **次の手順は、この節の手順 1 の窓（Windows PowerShell 5.1）に貼る**

1. Git Bash の記録を直した版が出ているときだけ、zoxide を止めるのをやめて上げる。

   ```powershell
   & {
     scoop update
     $v = (Get-Content -LiteralPath "$env:USERPROFILE\scoop\buckets\main\bucket\zoxide.json" -Raw | ConvertFrom-Json).version
     if ($v -notmatch '^\d+\.\d+\.\d+$' -or [version]$v -le [version]'0.10.0') { Write-Error "中断: scoop の main のバケットの zoxide はまだ $v。日を置いて、この節の手順 9 から"; return }
     scoop unhold zoxide
     scoop update zoxide --force
     zoxide --version
   }
   ```

   - `zoxide is no longer held and can be updated again.` と、`'zoxide' (<版>) was installed successfully!` が出て、最後に新しい版が出ればよい
   - `中断:` が出たら、Releases に出た版が、まだ scoop の main のバケットに入っていない。zoxide は何も変えていない（0.9.9 に止めたまま）
   - `--force` は、版を指定して入れた zoxide を、main のバケットの定義に戻す（付けないと 0.9.9 のまま変わらない）
   - `Running process detected, skip updating.` が出たら、上がっていない。Git Bash で開いている `zi` の一覧などを閉じてから、このブロックを貼り直す
   - これより後は、[更新](#更新)の手順 1・2 で、ほかのツールと一緒に上がる
   - 新しいタブで、この節の手順 7 のうち同書の手順 57・58 を確かめ直す

1. 元に戻すときは、この節で入れた 5 つを scoop で消す。

   ```powershell
   scoop uninstall fzf zoxide starship eza bat
   (Get-Command fzf, zoxide, starship, eza, bat -All -ErrorAction SilentlyContinue).Source
   [Environment]::GetEnvironmentVariable('BAT_CONFIG_DIR', 'User')
   ```

   - それぞれ `'<名前>' was uninstalled.` が出て、後の 2 つが何も出さなければよい（止めた zoxide も、そのまま消える）
   - 残すものは、名前を外してから貼る（fzf は yazi も使う）
   - `are still running` の旨のエラーが出たら、そのツールは消えていない。Git Bash で開いている一覧などを閉じてから貼り直す
   - starship の `Path` と、bat の `BAT_CONFIG_DIR` も消える。bat の設定（`~\scoop\persist\bat`）は残る（この節の手順 12）
   - 開いている Git Bash のタブと PowerShell 7 の窓は、閉じて開き直す（共通の bash 設定と PowerShell 7 のプロファイルは、無いツールを読まない）
   - starship のログ（`~\.cache\starship`）は、要らなければ手で消す

1. 元に戻すときは（この節の手順 6 で書いたときだけ）、bat の設定ファイルの 3 行を消す。

   ```powershell
   & {
     $f = Join-Path $env:USERPROFILE 'scoop\persist\bat\config'
     if (-not (Test-Path -LiteralPath $f)) { "無い: $f"; return }
     $text = [IO.File]::ReadAllText($f)
     if (-not $text.Trim()) { "もう空: $f" } elseif ($text -match '\A--theme="[^"\r\n]*"\r?\n--style="numbers,changes,header"\r?\n--paging=never\r?\n?\z') {
       [IO.File]::WriteAllText($f, '')
       "空にした: $f"
     } else { "この節で書いた形ではない（変えない）: $f" }
   }
   ```

   - `空にした:` か `もう空:` が出ればよい（scoop が bat を初めて入れたときと同じ、空のファイルになる）
   - bat を残していれば、次に動かしたときから、組み込みの既定値に戻る
   - `この節で書いた形ではない` が出たら、手で書き換えた設定がある。要らない行は、手で消す

1. 元に戻すときは（履歴も捨てるときだけ）、zoxide が覚えたディレクトリの履歴を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\zoxide" -Recurse -Force -ErrorAction SilentlyContinue
   Test-Path -LiteralPath "$env:LOCALAPPDATA\zoxide"
   ```

   - `False` が出ればよい
   - 消した履歴は取り戻せない。残しておけば、zoxide を入れ直したときにそのまま使える
   - PowerShell 7 の zoxide と yazi も、同じ履歴を使う

---

## 更新

- Windows Update は[手順 1〜8](#実施手順)（管理者の窓）、Microsoft Store は[手順 9〜15](#実施手順)（通常の窓）を通す。再起動が必要な場合も、自動では再起動しない
- scoop で入れたものは scoop で、winget で入れたもの（UniGet UI・PowerToys・PowerShell 7・Autologon・任意節の CopyQ）は winget で上げる
  - [シェルのツールを入れる（任意）](#シェルのツールを入れる任意)の zoxide は 0.9.9 に止めてあるので、この節の手順 2 では上がらない。直った版が出たかは、その節の手順 9 で確かめ、出ていればその節の手順 10 で上げる
- UniGet UI の画面からも、scoop と winget のパッケージをまとめて上げられる（UniGet UI と PowerToys は、自分でも新しい版を確かめる）
- CopyQ は、更新のインストーラが閉じた後に起動し直さないことがある。通知領域にアイコンが無ければ、スタートメニューの「CopyQ」から起動する
- Windows の大きな更新（機能の更新）の後は、外したアプリと切った提案が戻ることがある。[手順 27](#実施手順)・[手順 32〜34](#実施手順) を貼り直す
- 機能の更新の後は、任意節（[プライバシーと広告の表示を切る](#プライバシーと広告の表示を切る任意)・[表示・入力・音・ストレージを変える](#表示入力音ストレージを変える任意)・[Edge の常駐をポリシーで止める](#edge-の常駐をポリシーで止める任意)）の設定も戻ることがある。その節の「元に戻すときは、」より前の手順を貼り直す（控えのファイルは書き換えない）
- Git for Windows・Firefox・WezTerm・Claude Code・VirtualBox・WireGuard・HackGen Console NF は、それぞれの手順書の「Windows 11 の更新」
  - [SSH クライアント（Windows）](windows-ssh-client.md#更新)は「更新」、[Samba の共有のネットワーク ドライブ](samba-client.md#windows-11-の更新)は「Windows 11 の更新」（どちらも、上げるものは無い）
  - git-delta・GitHub CLI は scoop で入れたので、この節の手順 2 でも上がる
  - Neovim・lazygit・yazi も scoop で入れたので、この節の手順 2 でも上がる（手順書の節は、[Neovim](neovim.md#windows-11-の更新)・[lazygit](lazygit.md#windows-11-の更新)・[yazi](yazi.md#windows-11-の更新)の「Windows 11 の更新」）
- この節の手順は、手順 9 と同じ、管理者ではない Windows PowerShell（5.1）に貼る

1. scoop とバケットを上げ、古くなったものを確かめる。

   ```powershell
   scoop update
   scoop status
   ```

   - `scoop update` は `Scoop was updated successfully!` を出す
   - git が無いと `Scoop uses Git to update itself. Run 'scoop install git' and try again.` で止まる。先に [git.md](git.md#windows-11-で-git-for-windows-を入れる) で Git for Windows を入れる（初めての `scoop update` は、scoop 本体と main のバケットを git の形に直す）
   - `scoop status` は、古いものがあれば名前と版を並べる。`Everything is ok!` なら、この節の手順 2 は飛ばす

1. 古いものがあるときだけ、scoop で入れたものを上げる。

   ```powershell
   scoop update *
   ```

   - アプリごとに `'<名前>' (<版>) was installed successfully!` の形の行が出る
   - 動いているアプリは `Running process detected, skip updating.` で飛ばされる。閉じてから貼り直す
   - SSH のセッションで scoop のツールを使っているなら、[Windows の OpenSSH サーバー](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の任意節の手順 1 を、管理者の PowerShell で貼り直す（新しいジャンクションができるため）

1. winget で入れたものを上げる。

   ```powershell
   foreach ($id in 'Devolutions.UniGetUI', 'Microsoft.PowerToys', 'Microsoft.PowerShell', 'Microsoft.Sysinternals.Autologon', 'hluk.CopyQ') { winget upgrade --exact --id $id --source winget --accept-source-agreements --accept-package-agreements }
   ```

   - それぞれ、新しい版が無ければ更新が見つからない旨の行を出して何もしない
   - 動いている UniGet UI・PowerToys は、インストーラが閉じる
   - 入れていないものは、入っていない旨の行を出すだけ

1. WSL と AlmaLinux 10 を上げる。

   ```powershell
   wsl.exe --update
   wsl.exe --distribution AlmaLinux-10 --user root -- dnf -y upgrade
   ```

   - `wsl.exe --update` は WSL のパッケージ（とカーネル）を上げる。新しい版が無ければ、最新である旨を出す
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
     Get-InstalledModule -Name PSWindowsUpdate | Select-Object Name, Version, InstalledLocation
   }
   ```

   - モジュールの版と場所が出ればよい。Windows の更新は、このコマンドでは行わない
   - 読み込み済みの窓では古いモジュールが残るため、次の Windows Update は[手順 1](#実施手順)で新しく開いた管理者の窓で行う
   - この文書の前から入っていた PSWindowsUpdate は、元の導入方法で管理する

---

## ロールバック

- この節の手順 1〜17・21 は手順 9 と同じ管理者ではない Windows PowerShell（5.1）に、この節の手順 19・20・22〜38 はこの節の手順 18 で開く管理者の Windows PowerShell に貼る（この節の手順 21 の分だけ、管理者ではない窓も開いたままにしておく）
- PSWindowsUpdate だけを外すなら、この節の手順 40・41 を行う（管理者ではない窓）。この文書で初めて入れた場合だけが対象
- Windows Update や Store の更新を一括で取り消す手順ではない。Store 本体と、ほかのモジュールも使う NuGet のプロバイダーは外さない
- 残す項目の手順は飛ばす。項目ごとのこの節の手順
  - 表示と入力: エクスプローラーは 1、コンテキストメニューは 2、スタートは 3・23、タスクバーは 4、ダークモードは 5、既定の端末は 6、IME は 7、キーボードは 26・28
  - 整理: 自動で起動するアプリは 8、標準アプリとウィジェットは 9、ショートカットのポリシーは 24
  - 入れたもの: PowerShell 7 は 10、PowerToys は 11、UniGet UI は 12、scoop は 13・14、WSL は 17・25、Autologon は 20・21
  - 貼り付けの設定: 15・16
  - PC 全体: PC の名前は 37、長いパス・開発者モード・sudo は 36、電源とロックは 35、アダプターは 34、時計は 27
  - ネットワークとサインイン: 配信の最適化は 29、ping は 30、リモート アシスタンスは 31、リモート デスクトップは 32、LAN の種類は 33、Windows Hello は 22
- 多くは、元に戻すかを手順 37 で控えた値で決める
- Git for Windows など、ほかの手順書で入れたものは、それぞれの手順書の「Windows 11 のロールバック」
  - [SSH クライアント（Windows）](windows-ssh-client.md#ロールバック)は「ロールバック」、[Samba の共有のネットワーク ドライブ](samba-client.md#windows-11-のロールバック)は「Windows 11 のロールバック」
  - この節の手順 13 で scoop ごと消すなら、先に [git-delta の Windows 11 のロールバック](git-delta.md#windows-11-のロールバック)の手順 1 と、[GitHub CLI の Windows 11 のロールバック](gh.md#windows-11-のロールバック)の手順 1〜4 を行う
    - `~/.gitconfig` の `core.pager` と、資格情報マネージャーの gh のトークンは、scoop を消しても残る
  - この節の手順 13 で scoop ごと消すなら、先に [Neovim の Windows 11 のロールバック](neovim.md#windows-11-のロールバック)の手順 2 と、[yazi の Windows 11 のロールバック](yazi.md#windows-11-のロールバック)の手順 2 を行う
    - ユーザーの環境変数 `EDITOR`・`VISUAL`（Neovim の任意節）と `YAZI_FILE_ONE` は、scoop を消しても残る。lazygit は scoop の外に残すものが無い
- 任意節で変えたものは、この節では戻さない。それぞれの節の最後の「元に戻すときは、」の手順で戻す
  - 対象の任意節: Wake on LAN・リモートからの再起動・プライバシーと広告・表示と入力と音とストレージ・Edge の常駐・CopyQ・PowerToys・PowerShell 7 のプロファイル・Windows Terminal・WSL のネットワーク・シェルのツール
  - この節の手順 10 は PowerShell 7 のプロファイルと実行ポリシー（`Documents\PowerShell`）を残す。戻すなら、この節の手順 10 の前に（`pwsh.exe` が要る）、[PowerShell 7 のプロファイルを設定する（任意）](#powershell-7-のプロファイルを設定する任意)の手順 7・8
  - この節の手順 17・25 で WSL を外す前に `.wslconfig` を戻すなら、[WSL のネットワークをミラーにする（任意）](#wsl-のネットワークをミラーにする任意)の手順 6・7
  - この節の手順 13・14 で scoop ごと消すなら、[シェルのツールを入れる（任意）](#シェルのツールを入れる任意)の手順 11・12 は要らない
    - 止めた zoxide もこの節の手順 13 で消え、bat の設定はこの節の手順 14 で `persist` ごと消える
    - zoxide の履歴（`%LOCALAPPDATA%\zoxide`）は scoop の外にあって残る。捨てるなら、その任意節の手順 13（scoop を消した後でもよい）

> [!CAUTION]
> **この節の手順 13 は、scoop で入れたすべてのアプリを消す**（本書の外で入れたものも）。**この節の手順 14 は、それらの設定（`~\scoop\persist`）を、この節の手順 17 は WSL の AlmaLinux 10 のファイルをすべて消す**（取り戻せない）。残すなら、その手順は行わない。

1. エクスプローラーの表示を既定に戻す。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   $exp = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
   Set-ItemProperty -Path $adv -Name HideFileExt -Type DWord -Value 1
   Set-ItemProperty -Path $adv -Name Hidden -Type DWord -Value 2
   Remove-ItemProperty -Path $adv -Name LaunchTo -ErrorAction SilentlyContinue
   Set-ItemProperty -Path $adv -Name Start_TrackDocs -Type DWord -Value 1
   Set-ItemProperty -Path $exp -Name ShowRecent -Type DWord -Value 1
   Set-ItemProperty -Path $exp -Name ShowFrequent -Type DWord -Value 1
   Get-ItemProperty -Path $adv | Format-List HideFileExt, Hidden, LaunchTo, Start_TrackDocs
   ```

   - `HideFileExt : 1`・`Hidden : 2`・`Start_TrackDocs : 1` が出て、`LaunchTo` が空ならよい
   - エクスプローラーには、開き直すか再起動の後に効く

1. 旧形式のコンテキストメニューの設定を消す。

   ```powershell
   reg.exe delete 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' /f
   Test-Path -LiteralPath 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
   ```

   - `False` が出ればよい
   - エクスプローラーに効くのは、サインインし直すか、この節の手順 38 の再起動の後

1. スタートと設定の、おすすめ・提案・ヒントを既定に戻す。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
   Set-ItemProperty -Path $adv -Name Start_IrisRecommendations -Type DWord -Value 1
   Set-ItemProperty -Path $adv -Name Start_AccountNotifications -Type DWord -Value 1
   foreach ($n in 'SubscribedContent-338393Enabled', 'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled', 'SubscribedContent-338389Enabled', 'SubscribedContent-310093Enabled', 'SubscribedContent-338388Enabled', 'SystemPaneSuggestionsEnabled', 'SilentInstalledAppsEnabled') { Set-ItemProperty -Path $cdm -Name $n -Type DWord -Value 1 }
   Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Name ScoobeSystemSettingEnabled -ErrorAction SilentlyContinue
   Get-ItemProperty -Path $cdm | Format-List SubscribedContent-338393Enabled, SubscribedContent-353694Enabled, SubscribedContent-353696Enabled, SubscribedContent-338389Enabled, SubscribedContent-310093Enabled, SubscribedContent-338388Enabled, SystemPaneSuggestionsEnabled, SilentInstalledAppsEnabled
   ```

   - 並んだ値がすべて `1` ならよい
   - スタートの検索の Web の結果は、この節の手順 23 で戻す

1. タスクバーを既定に戻す。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   foreach ($n in 'TaskbarAl', 'ShowTaskViewButton', 'ShowSecondsInSystemClock') { Remove-ItemProperty -Path $adv -Name $n -ErrorAction SilentlyContinue }
   Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name SearchboxTaskbarMode -ErrorAction SilentlyContinue
   Get-ItemProperty -Path $adv | Format-List TaskbarAl, ShowTaskViewButton, ShowSecondsInSystemClock
   ```

   - 3 つの値が空ならよい（値が無いと既定の、中央・タスク ビューあり・秒なし・検索ボックス）
   - ウィジェットは、この節の手順 9 で入れ直す

1. 淡色（ライトモード）に戻す。

   ```powershell
   $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
   Set-ItemProperty -Path $p -Name AppsUseLightTheme -Type DWord -Value 1
   Set-ItemProperty -Path $p -Name SystemUsesLightTheme -Type DWord -Value 1
   Get-ItemProperty -Path $p | Format-List AppsUseLightTheme, SystemUsesLightTheme
   ```

   - 2 つとも `1` が出ればよい

1. 既定の端末を「Windows に任せる」に戻す。

   ```powershell
   foreach ($n in 'DelegationConsole', 'DelegationTerminal') { Remove-ItemProperty -LiteralPath 'HKCU:\Console\%%Startup' -Name $n -ErrorAction SilentlyContinue }
   Get-ItemProperty -LiteralPath 'HKCU:\Console\%%Startup' -ErrorAction SilentlyContinue | Format-List DelegationConsole, DelegationTerminal
   ```

   - 2 つの値が空ならよい（Windows 11 22H2 以降は、Windows Terminal が入っていればそれを使う）

1. Microsoft IME の設定を開き、Ctrl+Space の割り当てを外す。

   ```powershell
   Start-Process 'ms-settings:regionlanguage-jpnime'
   ```

   - 「キーとタッチのカスタマイズ」で、「Ctrl + Space」を「なし」にするか、「キーの割り当て」をオフにする
   - **次の手順は、設定を閉じてから PowerShell に貼る**

1. 自動で起動するアプリ（OneDrive・Edge・Teams）を、起動するように戻す。

   ```powershell
   & {
     $ok = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
     $props = (Get-Item -LiteralPath $ok -ErrorAction SilentlyContinue).Property | Where-Object { $_ -eq 'OneDrive' -or $_ -eq 'OneDriveSetup' -or $_ -like 'MicrosoftEdgeAutoLaunch_*' }
     foreach ($n in $props) { Set-ItemProperty -LiteralPath $ok -Name $n -Type Binary -Value ([byte[]](2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)); "戻した: $n" }
     $teams = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe\TeamsTfwStartupTask'
     if (Test-Path -LiteralPath $teams) { Set-ItemProperty -LiteralPath $teams -Name State -Type DWord -Value 2; '戻した: Teams' }
   }
   ```

   - 止めていたものごとに `戻した:` が出ればよい（無ければ何も出ない）
   - 効くのは、次のサインインから。タスク マネージャーの「スタートアップ アプリ」からでも戻せる

1. 外した標準アプリとウィジェットを戻すときだけ、ストアと winget から入れ直す。

   ```powershell
   foreach ($id in '9P1J8S7CCWWT', '9WZDNCRFHVFW', '9WZDNCRFJ3Q2', '9WZDNCRFHWD2', '9WZDNCRD29V9', '9NBLGGH5R558', '9NBLGGH4R32N', '9PKDZBMV1H3T', '9NRX63209R7B', '9NFTCH6J7FHV', '9MSSGKG348SP') { winget install --exact --id $id --source msstore --accept-source-agreements --accept-package-agreements }
   winget install --exact --id Microsoft.Teams --source winget --accept-source-agreements --accept-package-agreements
   ```

   - アプリごとに、入れた旨か、もう入っている旨の行が出る
   - `No package found matching input criteria.`（ストアにその ID が無い）や `0x80073cfb` で入らないアプリは、PC に残っているものを `Add-AppxPackage -RegisterByFamilyName -MainPackage <パッケージ ファミリー名>` で登録し直す（例: `Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe`）
   - 要らないアプリは、その ID を消してから貼る（ID とアプリの対応は[検証記録](verification/windows-setup.md)・[参考資料](reference/windows-setup.md)の表。`9MSSGKG348SP` がウィジェット）

1. PowerShell 7 を外す。

   ```powershell
   winget uninstall --exact --id Microsoft.PowerShell --source winget
   winget list --exact --id Microsoft.PowerShell
   ```

   - 最後のコマンドが、入っているパッケージが見つからない旨の行を出せばよい
   - PowerShell 7 のプロファイル（`Documents\PowerShell`）は残る

1. PowerToys を外す。

   ```powershell
   winget uninstall --exact --id Microsoft.PowerToys --source winget
   winget list --exact --id Microsoft.PowerToys
   ```

   - 最後のコマンドが、入っているパッケージが見つからない旨の行を出せばよい
   - 動いている PowerToys は、アンインストーラが閉じる。設定（`%LOCALAPPDATA%\Microsoft\PowerToys`）は残る

1. UniGet UI を外す。

   ```powershell
   winget uninstall --exact --id Devolutions.UniGetUI --source winget
   winget list --exact --id Devolutions.UniGetUI
   ```

   - 最後のコマンドが、入っているパッケージが見つからない旨の行を出せばよい
   - 動いている UniGet UI は、アンインストーラが閉じる
   - 設定（`%LOCALAPPDATA%\UniGetUI`）は残る。要らなければ手で消す

1. scoop と、scoop で入れたすべてのアプリを外す。

   ```powershell
   Get-ChildItem -Path "$env:USERPROFILE\scoop\apps\*\current" -Force -ErrorAction SilentlyContinue | ForEach-Object { attrib.exe -R /L $_.FullName }
   scoop uninstall scoop
   ```

   - 1 行目は、scoop がアプリごとに作る `current`（ジャンクション）の読み取り専用を外す。外さないと `Couldn't remove ~\scoop\apps` で止まる
   - `Are you sure? (yN)` と聞かれるので、`y` を入れる
   - 最後に `Scoop has been uninstalled.` が出ればよい（`~\scoop\persist` は残る）
   - 消せないアプリがあると `Couldn't remove` の旨の行で止まる。そのアプリを閉じて、この手順を貼り直す
     - `scoop` が見つからない旨が出たら、scoop 本体が先に消えている。この節の手順 14 で残りを消す（`persist` も消える）
     - 途中で止まったときは、ユーザーの PATH に `~\scoop\shims` が残る。要らなければ手で外す
   - **次の手順は、`Scoop has been uninstalled.` が出てから貼る**（続けて貼ると `y` の答えとして食われる）

1. scoop の残りを消すときだけ、`persist` と設定を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\scoop", "$env:USERPROFILE\.config\scoop" -Recurse -Force -ErrorAction SilentlyContinue
   Test-Path "$env:USERPROFILE\scoop", "$env:USERPROFILE\.config\scoop"
   ```

   - `False` が 2 行出ればよい
   - この手順を行わないと、scoop を入れ直すときに手順 20 が `exists and is not empty` で止まる

1. プロファイルから、手順 19 で足した行を消す。

   ```powershell
   & {
     $line = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-setup.md'
     $old = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-powershell-paste.md'
     if (-not (Test-Path -LiteralPath $PROFILE)) { "プロファイルが無い: $PROFILE"; return }
     $bytes = [System.IO.File]::ReadAllBytes($PROFILE)
     $enc = if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { [System.Text.Encoding]::Unicode } else { [System.Text.Encoding]::GetEncoding(28591) }
     $text = $enc.GetString($bytes)
     $rest = [regex]::Replace($text, '(?m)^(\uFEFF|\u00EF\u00BB\u00BF)?(' + [regex]::Escape($line) + '|' + [regex]::Escape($old) + ')\r?\n?', '$1')
     if ($rest -eq $text) { "その行は無い: $PROFILE" } elseif ($rest -match '^(\uFEFF|\u00EF\u00BB\u00BF)?\s*$') { Remove-Item -LiteralPath $PROFILE; "消した: $PROFILE" } else { [System.IO.File]::WriteAllBytes($PROFILE, $enc.GetBytes($rest)); "その行だけ消した: $PROFILE" }
   }
   ```

   - プロファイルにほかの行が無ければ `消した:`、あれば `その行だけ消した:` が出る
   - 前の版の手順書（`windows-powershell-paste.md`）の印の行も消す
   - 開いている窓の設定（手順 16・19）は、窓を閉じるまで残る。戻した後は、Windows の PowerShell のブロックを、conhost の窓では Ctrl+V で貼る（右クリックで貼ると、行が逆順になる）

1. 実行ポリシーを戻すときだけ、元の値にする（`OLD_EXECUTION_POLICY` は必ず値を入れる）。

   ```powershell
   $OLD_EXECUTION_POLICY = ''   # 手順 17 で控えた CurrentUser の値（Undefined・Restricted・AllSigned・RemoteSigned・Unrestricted・Bypass）
   ```

   ```powershell
   if ($OLD_EXECUTION_POLICY -notin 'Undefined', 'Restricted', 'AllSigned', 'RemoteSigned', 'Unrestricted', 'Bypass') {
     Write-Error '中断: $OLD_EXECUTION_POLICY に手順 17 で控えた CurrentUser の値を入れる'
   } else {
     Set-ExecutionPolicy -ExecutionPolicy $OLD_EXECUTION_POLICY -Scope CurrentUser -Force -ErrorAction Stop
     Get-ExecutionPolicy -List | Format-Table -AutoSize
   }
   ```

   - 手順 18 で値を変えなかった場合は、この手順を飛ばす。元の値を控えていなければ、推測で戻さない
   - 表の `CurrentUser` が、手順 17 で控えた値に戻ればよい。`Undefined` は自分のユーザーの設定を消す値
   - **注意**: 戻した後の実効値が `Restricted` なら、scoop などのスクリプトやプロファイルは動かない。`AllSigned` なら署名が必要になる

1. WSL の AlmaLinux 10 を消すときだけ、登録を外す（取り戻せない）。

   ```powershell
   wsl.exe --unregister AlmaLinux-10
   $env:WSL_UTF8 = '1'
   wsl.exe --list --verbose
   ```

   - AlmaLinux 10 の中のファイルは、すべて消える
   - 最後の一覧に `AlmaLinux-10` が無ければよい（ほかのディストリビューションが無ければ、無い旨の行）

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. 変数を設定する。

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # ほかの PC とつながる LAN の接続（自動）。<LAN_IF>
   'LAN_IF = {0}' -f $LAN_IF
   ```

   - 手順 36 の 2 つ目のブロックと同じ（`LAN_IF` が違えば直す）
   - `LAN_IF` は、この節の手順 33・34 で使う

1. 自動サインインを止めるときは、Autologon を起動し、`Disable` を押す。

   ```powershell
   $exe = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter Autologon64.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
   if (-not $exe) { Write-Error '中断: Autologon64.exe が見つからない' } else { Start-Process -FilePath $exe -ArgumentList '-accepteula' }
   ```

   - Autologon の窓で `Disable` を押す。自動ログオンの設定と、置いてあったパスワード（LSA のシークレット）が消える
   - **次の手順は、Autologon の窓が閉じてから貼る**

1. この節の手順 1〜17 の管理者ではない窓で、Autologon を外す。

   ```powershell
   winget uninstall --exact --id Microsoft.Sysinternals.Autologon --source winget
   (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon').AutoAdminLogon
   ```

   - アンインストールの成功の行と、`0` が出ればよい（自動ログオンが無効）
   - 手順 64 で自分のユーザーに入れたので、管理者の窓では `The package installed for user scope cannot be uninstalled when running with administrator privileges.` で外れない
   - `1` が出たら、この節の手順 20 で `Disable` を押していない。外す前に戻って押す（外した後は、もう一度入れてから）

1. 手順 37 で `HelloOnly` が `2` だったときだけ、「Windows Hello サインインのみを許可する」をオンに戻す。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' -Name DevicePasswordLessBuildVersion -Type DWord -Value 2
   Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' | Format-List DevicePasswordLessBuildVersion
   ```

   - `DevicePasswordLessBuildVersion : 2` が出ればよい

1. スタートの検索の Web の結果を、出すように戻す。

   ```powershell
   Remove-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name DisableSearchBoxSuggestions -ErrorAction SilentlyContinue
   (Get-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -ErrorAction SilentlyContinue).DisableSearchBoxSuggestions
   ```

   - 何も出なければよい（値が無い）

1. Edge のショートカットを消すポリシーを外す。

   ```powershell
   Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate' -Name RemoveDesktopShortcutDefault -ErrorAction SilentlyContinue
   (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate' -ErrorAction SilentlyContinue).RemoveDesktopShortcutDefault
   ```

   - 何も出なければよい
   - 消したショートカットは戻らない（要れば、スタートメニューの Edge を右クリックして作る）

1. WSL も外すときだけ、WSL のパッケージと仮想マシン プラットフォームを外す。

   ```powershell
   wsl.exe --uninstall
   Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
   ```

   - `Disable-WindowsOptionalFeature` の結果に `RestartNeeded : True` が出る（この節の手順 38 で再起動する）
   - ほかのディストリビューションを使っているなら、この手順は行わない
   - メモリ整合性などで、Hyper-V は動き続けることがある（VirtualBox は Hyper-V の上のまま）

1. 手順 53 を行ったときだけ、キーボードの種類を JIS 配列に戻す。

   ```powershell
   $k = 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters'
   Set-ItemProperty -Path $k -Name 'LayerDriver JPN' -Type String -Value 'kbd106.dll'
   Set-ItemProperty -Path $k -Name OverrideKeyboardIdentifier -Type String -Value 'PCAT_106KEY'
   Set-ItemProperty -Path $k -Name OverrideKeyboardType -Type DWord -Value 7
   Set-ItemProperty -Path $k -Name OverrideKeyboardSubtype -Type DWord -Value 2
   Get-ItemProperty -Path $k | Format-List 'LayerDriver JPN', OverrideKeyboardIdentifier, OverrideKeyboardType, OverrideKeyboardSubtype
   ```

   - `kbd106.dll`・`PCAT_106KEY`・`7`・`2` が出ればよい
   - 手順 37 の `Keyboard` が `kbd106.dll` でなかったなら、その値に直してから貼る

1. 手順 52 を行ったときだけ、時計の扱いを地方時に戻す。

   ```powershell
   Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name RealTimeIsUniversal -ErrorAction SilentlyContinue
   (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation').RealTimeIsUniversal
   ```

   - 何も出なければよい。再起動の後に、時刻を同期し直す

1. Caps Lock を戻すときだけ、Scancode Map を消す。

   ```powershell
   & {
     $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
     $want = '00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00'
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない（この節の手順 18 から）'; return }
     $now = (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue).'Scancode Map'
     $nowHex = if ($now) { ($now | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' } else { '' }
     if (-not $nowHex) { 'Scancode Map は無い'; return }
     if ($nowHex -ne $want) { Write-Error "中断: 本書の値ではない Scancode Map がある（$nowHex）"; return }
     Remove-ItemProperty -Path $key -Name 'Scancode Map'
     'Scancode Map を消した'
   }
   ```

   - `Scancode Map を消した` が出ればよい
   - `中断:` が出たら、本書の後でほかの割り当てを足している。消さずに止めている

1. 配信の最適化を元に戻す（`OLD_DOWNLOAD_MODE` は必ず値を入れる）。

   ```powershell
   $OLD_DOWNLOAD_MODE = ''   # 手順 37 で控えたモード（Internet・Lan・CdnOnly）
   ```

   ```powershell
   if ($OLD_DOWNLOAD_MODE -notin 'Internet', 'Lan', 'CdnOnly') {
     Write-Error '中断: $OLD_DOWNLOAD_MODE に手順 37 で控えた Internet・Lan・CdnOnly のいずれかを入れる'
   } else {
     Set-DODownloadMode -DownloadMode $OLD_DOWNLOAD_MODE -ErrorAction Stop
     Get-DODownloadMode
   }
   ```

   - 手順 37 で控えたモードが出ればよい
   - `Lan`（既定）だったなら、この手順は飛ばしてよい。`CdnOnly` なら、ほかの PC と共有しない設定に戻る
   - 元の値を控えていない場合や、上の 3 つ以外だった場合は、推測で値を選ばず、管理元の設定を確かめる

1. ping に応える規則を消す。

   ```powershell
   Remove-NetFirewallRule -Group 'Ping (setup-notes)' -ErrorAction SilentlyContinue
   Get-NetFirewallRule -Group 'Ping (setup-notes)' -ErrorAction SilentlyContinue
   ```

   - 何も出なければよい

1. 手順 37 で `RemoteAssistance` が `1` だったときだけ、システムのプロパティでリモート アシスタンスを戻す。

   ```powershell
   SystemPropertiesRemote.exe
   ```

   - システムのプロパティの「リモート」タブが開く。「このコンピューターへのリモート アシスタンス接続を許可する」にチェックを入れて「OK」を押す
   - 「OK」を押すと窓が閉じ、`fAllowToGetHelp` が 1 になり、リモート アシスタンスの規則（パブリック向けも含む 15 個）がまとめて有効になる
   - **次の手順は、システムのプロパティを閉じてから貼る**

1. 手順 37 で `RemoteDesktop` が `1`（無効）だったときだけ、リモート デスクトップを無効に戻す。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Type DWord -Value 1
   Set-NetFirewallRule -Group '@FirewallAPI.dll,-28752' -Enabled False -Profile Any
   Get-NetFirewallRule -Group '@FirewallAPI.dll,-28752' | Format-Table Name, Enabled, Profile
   ```

   - 規則が `False  Any` で並べばよい
   - **注意**: リモート デスクトップでつないでいるときに貼ると、その場で切れる
   - [RDP をロックせずに切断（Windows）](windows-rdp-disconnect.md)を使っているなら、この手順は飛ばす

1. LAN の接続をパブリックに戻すときだけ、パブリックにする。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error 'この節の手順 19 の $LAN_IF が空'
   } else {
     Set-NetConnectionProfile -InterfaceAlias $LAN_IF -NetworkCategory Public
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
   }
   ```

   - `<LAN_IF>  Public` が出ればよい
   - 手順 37 で `LanCategory` が `Private` だったなら（もとからプライベート）、この手順は飛ばす
   - [Windows の OpenSSH サーバー](windows-openssh-server.md)・[Syncthing の Windows 11 で使う](syncthing.md#windows-11-で使う)・リモート デスクトップをこの LAN で使っているなら、この手順は飛ばす（パブリックにすると届かなくなる）

1. アダプターを、電力の節約のために止められるように戻す。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error 'この節の手順 19 の $LAN_IF が空'
   } else {
     $pm = Get-NetAdapterPowerManagement -Name $LAN_IF
     if ($pm.AllowComputerToTurnOffDevice -ne 'Unsupported') {
       $pm.AllowComputerToTurnOffDevice = 'Enabled'
       $pm | Set-NetAdapterPowerManagement -NoRestart
     }
     Get-NetAdapterPowerManagement -Name $LAN_IF | Format-List Name, AllowComputerToTurnOffDevice
   }
   ```

   - `AllowComputerToTurnOffDevice : Enabled` が出ればよい（このアダプターに設定が無ければ `Unsupported` のまま）
   - 効くのは、この節の手順 38 の再起動の後

1. 電源の設定を既定に戻し、休止状態を戻し、放置したときのロックを戻す。

   ```powershell
   powercfg /restoredefaultschemes
   powercfg /hibernate on
   Remove-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name DelayLockInterval -ErrorAction SilentlyContinue
   'HibernateEnabled: {0}' -f (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power').HibernateEnabled
   ```

   - `HibernateEnabled: 1` が出ればよい
   - ファームウェアが休止状態に対応しない PC（VM など）では、`システム ファームウェアは休止状態をサポートしていません。` の旨が出て `HibernateEnabled: 0` のまま（もとから休止状態は使えない）
   - **注意**: `/restoredefaultschemes` は、電源プランをすべて既定に戻す（本書の外で変えた電源の設定も消える）

1. 長いパス・開発者モード・sudo を切る。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -Type DWord -Value 0
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name AllowDevelopmentWithoutDevLicense -Type DWord -Value 0
   if (Get-Command sudo -ErrorAction SilentlyContinue) { sudo config --enable disable }
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' | Format-List LongPathsEnabled
   Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' | Format-List AllowDevelopmentWithoutDevLicense
   ```

   - `LongPathsEnabled : 0` と `AllowDevelopmentWithoutDevLicense : 0` が出ればよい
   - sudo は、無効になった旨の行を出す（日本語の Windows では `このコンピューターでは sudo が無効化されています。`）

1. PC の名前を戻すときだけ、元の名前にする（`OLD_PC_NAME` は必ず値を入れる）。

   ```powershell
   $OLD_PC_NAME = ''   # 手順 37 で控えた元の名前。<HOSTNAME>
   ```

   ```powershell
   if (-not $OLD_PC_NAME) {
     Write-Error '中断: $OLD_PC_NAME が空'
   } elseif ($OLD_PC_NAME -notmatch '^[A-Za-z0-9]([A-Za-z0-9-]{0,13}[A-Za-z0-9])?$' -or $OLD_PC_NAME -match '^[0-9]+$') {
     Write-Error "中断: 使えない名前（15 文字まで。英字・数字・ハイフンで、先頭と末尾は英数字。数字だけは不可）: $OLD_PC_NAME"
   } elseif ($OLD_PC_NAME -eq $env:COMPUTERNAME) {
     "すでにこの名前: $OLD_PC_NAME"
   } else {
     Rename-Computer -NewName $OLD_PC_NAME
     "再起動の後に $OLD_PC_NAME になる"
   }
   ```

   - `再起動の後に <HOSTNAME> になる` が出ればよい
   - 効くのは、この節の手順 38 の再起動の後

1. 再起動する。

   ```powershell
   Restart-Computer
   ```

   - この節の手順 20〜37 の多くは、再起動の後に効く（この節の手順 1〜9 だけなら、サインインし直すだけでよい）
   - **次の手順は、起動してサインインしてから行う**

1. 元に戻ったことを確かめる。

   - Caps Lock を押すとランプが点き、大文字になる（この節の手順 28 を行ったとき）
   - 右クリックで新しい形のメニューが出る（この節の手順 2 を行ったとき）
   - エクスプローラー・タスクバー・スタートが既定の見た目に戻る（この節の手順 1・3〜5 を行ったとき）

1. PSWindowsUpdate を外すときだけ、管理者ではない Windows PowerShell を開く。

   - PSWindowsUpdate を読み込んだ窓を閉じてから、手順 9 と同じ方法で新しい窓を開く
   - 手順 3 で初めて入れたモジュールが不要になった場合だけ、この節の手順 41 へ。もとから入っていた場合は消さない
   - この節の手順 15 で貼り付けの設定も外した場合は、Ctrl+V で貼る

1. この文書で初めて入れた PSWindowsUpdate が不要なときだけ、外す。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
       throw '中断: この節の手順 40 で管理者ではない窓を開く'
     }
     if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
       Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
     }
     Uninstall-Module -Name PSWindowsUpdate -AllVersions -Force
     if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
       throw '中断: PSWindowsUpdate が残っている。元からあった別の場所のものは消さない'
     }
     'PSWindowsUpdate を外した'
   }
   ```

   - `PSWindowsUpdate を外した` が出ればよい
   - 今の窓だけ実行ポリシーを変えた場合は、窓を閉じれば戻る
   - NuGet のプロバイダーと、既に適用した Windows の更新は残す

---

## 注意点

- **重ねると、触れる人がそのまま使える PC になる**: 放置でロックしない（手順 41）・自動サインイン（手順 64）は、PC の前にいる人をこのユーザー（Administrators の一員）として通す。インラインの sudo（手順 40）・リモート デスクトップ（手順 44）・Windows Hello 以外のサインイン（手順 48）は、このユーザーのパスワードを知る人の入口を増やす。人が触れる場所にある PC では、手順 41・64 は行わない
- **Caps Lock の働きは無くなる**: Caps Lock を左 Ctrl にするだけで、Caps Lock をほかのキーに割り当てない。大文字を続けて打つときは Shift を押す
- **Scancode Map は、すべてのユーザー・すべてのキーボードにかかる**: PC 全体の設定。この PC にサインインするほかのユーザーと、つないだ外付けのキーボードにもかかる
- **JIS 配列では「英数」のキーが Ctrl になる**: 日本語の配列のキーボードの Caps Lock は「英数」のキー（スキャン コード `0x3A`）なので、そのキーの IME の働き（英数への切り替え）も無くなるはず
- **リモート デスクトップと Scancode Map**: Microsoft の文書は、Scancode Map がターミナル サービスでは正しく働かないことがあると書いている
- **Ctrl+Space はアプリでは使えなくなる**: IME が受け取るので、PowerShell（PSReadLine の `MenuComplete`）・VS Code・Excel などの Ctrl+Space は効かなくなるはず（[検証記録](verification/windows-setup.md)・[参考資料](reference/windows-setup.md)）
  - PowerShell 7 では、`MenuComplete` を Tab に割り当てられる（[PowerShell 7 のプロファイルを設定する（任意）](#powershell-7-のプロファイルを設定する任意)の手順 3）
- **管理者の PowerShell は conhost の窓で開く**: 既定の端末を Windows Terminal にしても（手順 30）、管理者として開いた PowerShell は conhost の窓になる。右クリックで貼れるのは、手順 16〜19 のプロファイルの設定による
- **外したアプリと提案は、機能の更新で戻ることがある**: 自分のユーザーから外したアプリ（手順 33・34）は、PC に置かれた元が残るので、Windows の大きな更新の後に戻ってくることがある。手順 27・32〜34 を貼り直す
- **サポート外の設定**: 旧形式のコンテキストメニュー（手順 26）は Microsoft が説明していない設定で、Windows の更新で効かなくなることがある。そのときは、手順 17 の `ClassicMenu` と手順 26 の `reg.exe query` で、設定が残っているかを見る。手順 25・27・32 の値の多くも、Microsoft の文書には値が書かれておらず、広く使われているもの
- **SSH のセッションで scoop のツールを使うとき**: sshd の緩和策（RedirectionGuard）で、一般ユーザーの scoop が作るジャンクションをたどれない。[Windows の OpenSSH サーバー](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の任意節を、`scoop install`・`scoop update` の後に貼る
- **PowerShell 7 で scoop を使うとき**: 実行ポリシーは Windows PowerShell 5.1 とは別に持つ。UniGet UI は、PowerShell 7 があればそれで scoop を動かす（`-ExecutionPolicy Bypass` 付き）
- **PowerShell 7 のプロファイルは別**: 手順 19 の行は Windows PowerShell 5.1 のプロファイルにだけ書く。PowerShell 7（手順 24）は `Documents\PowerShell\Microsoft.PowerShell_profile.ps1` を読む。この文書の手順書群は、Windows PowerShell 5.1 に貼る
  - 同じ貼り付けの設定を PowerShell 7 にも足すなら、[PowerShell 7 のプロファイルを設定する（任意）](#powershell-7-のプロファイルを設定する任意)
- **scoop のアプリは自分のユーザーだけ**: `~\scoop` に入るので、ほかのユーザーには見えない。scoop の `--global` は管理者が要り、本書では使わない
- **貼ったブロックは、Enter を押すまで動かない**: コピーボタンの中身は末尾に改行が無いため。手順 16〜19 の後の conhost の窓では、ブロック全体が 1 つの入力になり、Enter で 1 回で動く
- **Ctrl+Enter で上に行を作る操作（`InsertLineAbove`）は使えなくなる**: 下に行を作る Shift+Ctrl+Enter（`InsertLineBelow`）と、Shift+Enter（`AddLine`）はそのまま
- **このユーザーの Windows PowerShell のコンソールの窓すべてに効く**: 管理者の窓も同じプロファイルを読む
- **任意節にもサポート外の設定がある**: ギャラリーとホームを消す値（[表示・入力・音・ストレージを変える（任意）](#表示入力音ストレージを変える任意)の手順 6）は、手順 26 と同じく Microsoft が説明していない方法で、更新で効かなくなることがある。任意節のほかの値の多くも、Microsoft の文書には無く、広く使われているもの
- **Edge に「組織によって管理」と出る**: [Edge の常駐をポリシーで止める（任意）](#edge-の常駐をポリシーで止める任意)の手順 2 のポリシーで出る。消すには、その節の手順 5 で 2 つの値を消す（ほかの Edge のポリシーが無ければ消えるはず。手順 50 の `EdgeUpdate` だけで出るかも含め、確かめていない）
- **ストレージ センサーはファイルを消す**: [表示・入力・音・ストレージを変える（任意）](#表示入力音ストレージを変える任意)の手順 11 は、ごみ箱に 30 日を超えて置いたファイルと一時ファイルを毎月消す（取り戻せない）。OneDrive のファイルは、その節の手順 12 で外さないと、オンラインだけにされうる
- **CopyQ の履歴は暗号化されない**: [CopyQ を使う（任意）](#copyq-を使う任意)の CopyQ は、コピーしたものを平文でディスク（`%APPDATA%\copyq` など）に残す。除外の印を付けないアプリでコピーしたパスワードも残る。要らない項目は CopyQ の窓で消す
- **Windows Terminal に複数行を貼ると「警告」が出ることがある**: 管理者ではない窓（Windows Terminal）に複数行のブロックを貼ると出るはず（コードからの推測。確かめていない）。出たら「強制的に貼り付け」を押す
  - 出さないなら、[Windows Terminal のフォントと貼り付けの警告を変える（任意）](#windows-terminal-のフォントと貼り付けの警告を変える任意)の手順 4
- **WSL をミラーにすると、WSL から Windows には `127.0.0.1` でつなぐ**: [WSL のネットワークをミラーにする（任意）](#wsl-のネットワークをミラーにする任意)の後は、WSL から Windows の sshd などに LAN の IP あてではつながらないはず
  - Windows が使っているポート（sshd の 22 番など）は、WSL の中のサーバーで使えない
