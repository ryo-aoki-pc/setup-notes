# Windows 11 の初期設定の手順（インストール直後の更新・貼り付けの設定・scoop・UniGet UI・表示・電源・リモート・WSL）のロールバックと注意点

[手順書](../windows-setup.md)・[検証記録](../verification/windows-setup.md)・[参考資料](../reference/windows-setup.md)

- 「手順 N」は[手順書](../windows-setup.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

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
  - この節の手順 13 で scoop ごと消すなら、先に [コーディングエージェントの共同作業の Windows 11 のロールバック](coding-agents.md#windows-11-のロールバック)の手順 5（Claude Code のプラグインを外す）を行う
    - プラグインは、Claude Code の起動と終了のたびに、scoop の `nodejs-lts` の `node` を動かす
- 任意節で変えたものは、この節では戻さない。それぞれの節の最後の「元に戻すときは、」の手順で戻す
  - 対象の任意節: Wake on LAN・リモートからの再起動・プライバシーと広告・表示と入力と音とストレージ・Edge の常駐・CopyQ・PowerToys・PowerShell 7 のプロファイル・Windows Terminal・WSL のネットワーク・シェルのツール
  - この節の手順 10 は PowerShell 7 のプロファイルと実行ポリシー（`Documents\PowerShell`）を残す。戻すなら、この節の手順 10 の前に（`pwsh.exe` が要る）、[PowerShell 7 のプロファイルを設定する（任意）](../windows-setup.md#powershell-7-のプロファイルを設定する任意)の手順 7・8
  - この節の手順 17・25 で WSL を外す前に `.wslconfig` を戻すなら、[WSL のネットワークをミラーにする（任意）](../windows-setup.md#wsl-のネットワークをミラーにする任意)の手順 6・7
  - この節の手順 13・14 で scoop ごと消すなら、[シェルのツールを入れる（任意）](../windows-setup.md#シェルのツールを入れる任意)の手順 11・12 は要らない
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
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $adv | Format-List HideFileExt, Hidden, LaunchTo, Start_TrackDocs
   ```

   - `HideFileExt : 1`・`Hidden : 2`・`Start_TrackDocs : 1` が出て、`LaunchTo` が空ならよい
   - エクスプローラーには、開き直すか再起動の後に効く

1. 旧形式のコンテキストメニューの設定を消す。

   ```powershell
   reg.exe delete 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' /f
   "`n$([char]27)[7m 確認 $([char]27)[0m"
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
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $cdm | Format-List SubscribedContent-338393Enabled, SubscribedContent-353694Enabled, SubscribedContent-353696Enabled, SubscribedContent-338389Enabled, SubscribedContent-310093Enabled, SubscribedContent-338388Enabled, SystemPaneSuggestionsEnabled, SilentInstalledAppsEnabled
   ```

   - 並んだ値がすべて `1` ならよい
   - スタートの検索の Web の結果は、この節の手順 23 で戻す

1. タスクバーを既定に戻す。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   foreach ($n in 'TaskbarAl', 'ShowTaskViewButton', 'ShowSecondsInSystemClock') { Remove-ItemProperty -Path $adv -Name $n -ErrorAction SilentlyContinue }
   Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name SearchboxTaskbarMode -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $adv | Format-List TaskbarAl, ShowTaskViewButton, ShowSecondsInSystemClock
   ```

   - 3 つの値が空ならよい（値が無いと既定の、中央・タスク ビューあり・秒なし・検索ボックス）
   - ウィジェットは、この節の手順 9 で入れ直す

1. 淡色（ライトモード）に戻す。

   ```powershell
   $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
   Set-ItemProperty -Path $p -Name AppsUseLightTheme -Type DWord -Value 1
   Set-ItemProperty -Path $p -Name SystemUsesLightTheme -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $p | Format-List AppsUseLightTheme, SystemUsesLightTheme
   ```

   - 2 つとも `1` が出ればよい

1. 既定の端末を「Windows に任せる」に戻す。

   ```powershell
   foreach ($n in 'DelegationConsole', 'DelegationTerminal') { Remove-ItemProperty -LiteralPath 'HKCU:\Console\%%Startup' -Name $n -ErrorAction SilentlyContinue }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
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
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($n in $props) { Set-ItemProperty -LiteralPath $ok -Name $n -Type Binary -Value ([byte[]](2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)); "戻した: $n" }
     $teams = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe\TeamsTfwStartupTask'
     if (Test-Path -LiteralPath $teams) { Set-ItemProperty -LiteralPath $teams -Name State -Type DWord -Value 2; '戻した: Teams' }
   }
   ```

   - 止めていたものごとに `戻した:` が出ればよい（無ければ何も出ない）
   - 効くのは、次のサインインから。タスク マネージャーの「スタートアップ アプリ」からでも戻せる

1. 外した標準アプリとウィジェットを戻すときだけ、ストアと winget から入れ直す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($id in '9P1J8S7CCWWT', '9WZDNCRFHVFW', '9WZDNCRFJ3Q2', '9WZDNCRFHWD2', '9WZDNCRD29V9', '9NBLGGH5R558', '9NBLGGH4R32N', '9PKDZBMV1H3T', '9NRX63209R7B', '9NFTCH6J7FHV', '9MSSGKG348SP') { winget install --exact --id $id --source msstore --accept-source-agreements --accept-package-agreements }
   winget install --exact --id Microsoft.Teams --source winget --accept-source-agreements --accept-package-agreements
   ```

   - アプリごとに、入れた旨か、もう入っている旨の行が出る
   - `No package found matching input criteria.`（ストアにその ID が無い）や `0x80073cfb` で入らないアプリは、PC に残っているものを `Add-AppxPackage -RegisterByFamilyName -MainPackage <パッケージ ファミリー名>` で登録し直す（例: `Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe`）
   - 要らないアプリは、その ID を消してから貼る（ID とアプリの対応は[検証記録](../verification/windows-setup.md)・[参考資料](../reference/windows-setup.md)の表。`9MSSGKG348SP` がウィジェット）

1. PowerShell 7 を外す。

   ```powershell
   winget uninstall --exact --id Microsoft.PowerShell --source winget
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id Microsoft.PowerShell
   ```

   - 最後のコマンドが、入っているパッケージが見つからない旨の行を出せばよい
   - PowerShell 7 のプロファイル（`Documents\PowerShell`）は残る

1. PowerToys を外す。

   ```powershell
   winget uninstall --exact --id Microsoft.PowerToys --source winget
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id Microsoft.PowerToys
   ```

   - 最後のコマンドが、入っているパッケージが見つからない旨の行を出せばよい
   - 動いている PowerToys は、アンインストーラが閉じる。設定（`%LOCALAPPDATA%\Microsoft\PowerToys`）は残る

1. UniGet UI を外す。

   ```powershell
   winget uninstall --exact --id Devolutions.UniGetUI --source winget
   "`n$([char]27)[7m 確認 $([char]27)[0m"
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
   "`n$([char]27)[7m 確認 $([char]27)[0m"
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
     "`n$([char]27)[7m 確認 $([char]27)[0m"
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
     "`n$([char]27)[7m 確認 $([char]27)[0m"
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
   "`n$([char]27)[7m 確認 $([char]27)[0m"
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
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget uninstall --exact --id Microsoft.Sysinternals.Autologon --source winget
   (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon').AutoAdminLogon
   ```

   - アンインストールの成功の行と、`0` が出ればよい（自動ログオンが無効）
   - 手順 64 で自分のユーザーに入れたので、管理者の窓では `The package installed for user scope cannot be uninstalled when running with administrator privileges.` で外れない
   - `1` が出たら、この節の手順 20 で `Disable` を押していない。外す前に戻って押す（外した後は、もう一度入れてから）

1. 手順 37 で `HelloOnly` が `2` だったときだけ、「Windows Hello サインインのみを許可する」をオンに戻す。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' -Name DevicePasswordLessBuildVersion -Type DWord -Value 2
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' | Format-List DevicePasswordLessBuildVersion
   ```

   - `DevicePasswordLessBuildVersion : 2` が出ればよい

1. スタートの検索の Web の結果を、出すように戻す。

   ```powershell
   Remove-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name DisableSearchBoxSuggestions -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -ErrorAction SilentlyContinue).DisableSearchBoxSuggestions
   ```

   - 何も出なければよい（値が無い）

1. Edge のショートカットを消すポリシーを外す。

   ```powershell
   Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate' -Name RemoveDesktopShortcutDefault -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate' -ErrorAction SilentlyContinue).RemoveDesktopShortcutDefault
   ```

   - 何も出なければよい
   - 消したショートカットは戻らない（要れば、スタートメニューの Edge を右クリックして作る）

1. WSL も外すときだけ、WSL のパッケージと仮想マシン プラットフォームを外す。

   ```powershell
   wsl.exe --uninstall
   "`n$([char]27)[7m 確認 $([char]27)[0m"
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
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k | Format-List 'LayerDriver JPN', OverrideKeyboardIdentifier, OverrideKeyboardType, OverrideKeyboardSubtype
   ```

   - `kbd106.dll`・`PCAT_106KEY`・`7`・`2` が出ればよい
   - 手順 37 の `Keyboard` が `kbd106.dll` でなかったなら、その値に直してから貼る

1. 手順 52 を行ったときだけ、時計の扱いを地方時に戻す。

   ```powershell
   Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name RealTimeIsUniversal -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
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
     "`n$([char]27)[7m 確認 $([char]27)[0m"
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
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-DODownloadMode
   }
   ```

   - 手順 37 で控えたモードが出ればよい
   - `Lan`（既定）だったなら、この手順は飛ばしてよい。`CdnOnly` なら、ほかの PC と共有しない設定に戻る
   - 元の値を控えていない場合や、上の 3 つ以外だった場合は、推測で値を選ばず、管理元の設定を確かめる

1. ping に応える規則を消す。

   ```powershell
   Remove-NetFirewallRule -Group 'Ping (setup-notes)' -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
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
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Group '@FirewallAPI.dll,-28752' | Format-Table Name, Enabled, Profile
   ```

   - 規則が `False  Any` で並べばよい
   - **注意**: リモート デスクトップでつないでいるときに貼ると、その場で切れる
   - [RDP をロックせずに切断（Windows）](../windows-rdp-disconnect.md)を使っているなら、この手順は飛ばす

1. LAN の接続をパブリックに戻すときだけ、パブリックにする。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error 'この節の手順 19 の $LAN_IF が空'
   } else {
     Set-NetConnectionProfile -InterfaceAlias $LAN_IF -NetworkCategory Public
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
   }
   ```

   - `<LAN_IF>  Public` が出ればよい
   - 手順 37 で `LanCategory` が `Private` だったなら（もとからプライベート）、この手順は飛ばす
   - [Windows の OpenSSH サーバー](../windows-openssh-server.md)・[Syncthing の Windows 11 で使う](../syncthing.md#windows-11-で使う)・リモート デスクトップをこの LAN で使っているなら、この手順は飛ばす（パブリックにすると届かなくなる）

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
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetAdapterPowerManagement -Name $LAN_IF | Format-List Name, AllowComputerToTurnOffDevice
   }
   ```

   - `AllowComputerToTurnOffDevice : Enabled` が出ればよい（このアダプターに設定が無ければ `Unsupported` のまま）
   - 効くのは、この節の手順 38 の再起動の後

1. 電源の設定を既定に戻し、休止状態を戻し、放置したときのロックを戻す。

   ```powershell
   powercfg /restoredefaultschemes
   "`n$([char]27)[7m 確認 $([char]27)[0m"
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
   "`n$([char]27)[7m 確認 $([char]27)[0m"
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
   "`n$([char]27)[7m 確認 $([char]27)[0m"
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
     "`n$([char]27)[7m 確認 $([char]27)[0m"
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
- **Ctrl+Space はアプリでは使えなくなる**: IME が受け取るので、PowerShell（PSReadLine の `MenuComplete`）・VS Code・Excel などの Ctrl+Space は効かなくなるはず（[検証記録](../verification/windows-setup.md)・[参考資料](../reference/windows-setup.md)）
  - PowerShell 7 では、`MenuComplete` を Tab に割り当てられる（[PowerShell 7 のプロファイルを設定する（任意）](../windows-setup.md#powershell-7-のプロファイルを設定する任意)の手順 3）
- **管理者の PowerShell は conhost の窓で開く**: 既定の端末を Windows Terminal にしても（手順 30）、管理者として開いた PowerShell は conhost の窓になる。右クリックで貼れるのは、手順 16〜19 のプロファイルの設定による
- **外したアプリと提案は、機能の更新で戻ることがある**: 自分のユーザーから外したアプリ（手順 33・34）は、PC に置かれた元が残るので、Windows の大きな更新の後に戻ってくることがある。手順 27・32〜34 を貼り直す
- **サポート外の設定**: 旧形式のコンテキストメニュー（手順 26）は Microsoft が説明していない設定で、Windows の更新で効かなくなることがある。そのときは、手順 17 の `ClassicMenu` と手順 26 の `reg.exe query` で、設定が残っているかを見る。手順 25・27・32 の値の多くも、Microsoft の文書には値が書かれておらず、広く使われているもの
- **SSH のセッションで scoop のツールを使うとき**: sshd の緩和策（RedirectionGuard）で、一般ユーザーの scoop が作るジャンクションをたどれない。[Windows の OpenSSH サーバー](../windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の任意節を、`scoop install`・`scoop update` の後に貼る
- **PowerShell 7 で scoop を使うとき**: 実行ポリシーは Windows PowerShell 5.1 とは別に持つ。UniGet UI は、PowerShell 7 があればそれで scoop を動かす（`-ExecutionPolicy Bypass` 付き）
- **PowerShell 7 のプロファイルは別**: 手順 19 の行は Windows PowerShell 5.1 のプロファイルにだけ書く。PowerShell 7（手順 24）は `Documents\PowerShell\Microsoft.PowerShell_profile.ps1` を読む。この文書の手順書群は、Windows PowerShell 5.1 に貼る
  - 同じ貼り付けの設定を PowerShell 7 にも足すなら、[PowerShell 7 のプロファイルを設定する（任意）](../windows-setup.md#powershell-7-のプロファイルを設定する任意)
- **scoop のアプリは自分のユーザーだけ**: `~\scoop` に入るので、ほかのユーザーには見えない。scoop の `--global` は管理者が要り、本書では使わない
- **貼ったブロックは、Enter を押すまで動かない**: コピーボタンの中身は末尾に改行が無いため。手順 16〜19 の後の conhost の窓では、ブロック全体が 1 つの入力になり、Enter で 1 回で動く
- **Ctrl+Enter で上に行を作る操作（`InsertLineAbove`）は使えなくなる**: 下に行を作る Shift+Ctrl+Enter（`InsertLineBelow`）と、Shift+Enter（`AddLine`）はそのまま
- **このユーザーの Windows PowerShell のコンソールの窓すべてに効く**: 管理者の窓も同じプロファイルを読む
- **任意節にもサポート外の設定がある**: ギャラリーとホームを消す値（[表示・入力・音・ストレージを変える（任意）](../windows-setup.md#表示入力音ストレージを変える任意)の手順 6）は、手順 26 と同じく Microsoft が説明していない方法で、更新で効かなくなることがある。任意節のほかの値の多くも、Microsoft の文書には無く、広く使われているもの
- **Edge に「組織によって管理」と出る**: [Edge の常駐をポリシーで止める（任意）](../windows-setup.md#edge-の常駐をポリシーで止める任意)の手順 2 のポリシーで出る。消すには、その節の手順 5 で 2 つの値を消す（ほかの Edge のポリシーが無ければ消えるはず。手順 50 の `EdgeUpdate` だけで出るかも含め、確かめていない）
- **ストレージ センサーはファイルを消す**: [表示・入力・音・ストレージを変える（任意）](../windows-setup.md#表示入力音ストレージを変える任意)の手順 11 は、ごみ箱に 30 日を超えて置いたファイルと一時ファイルを毎月消す（取り戻せない）。OneDrive のファイルは、その節の手順 12 で外さないと、オンラインだけにされうる
- **CopyQ の履歴は暗号化されない**: [CopyQ を使う（任意）](../windows-setup.md#copyq-を使う任意)の CopyQ は、コピーしたものを平文でディスク（`%APPDATA%\copyq` など）に残す。除外の印を付けないアプリでコピーしたパスワードも残る。要らない項目は CopyQ の窓で消す
- **Windows Terminal に複数行を貼ると「警告」が出ることがある**: 管理者ではない窓（Windows Terminal）に複数行のブロックを貼ると出るはず（コードからの推測。確かめていない）。出たら「強制的に貼り付け」を押す
  - 出さないなら、[Windows Terminal のフォントと貼り付けの警告を変える（任意）](../windows-setup.md#windows-terminal-のフォントと貼り付けの警告を変える任意)の手順 4
- **WSL をミラーにすると、WSL から Windows には `127.0.0.1` でつなぐ**: [WSL のネットワークをミラーにする（任意）](../windows-setup.md#wsl-のネットワークをミラーにする任意)の後は、WSL から Windows の sshd などに LAN の IP あてではつながらないはず
  - Windows が使っているポート（sshd の 22 番など）は、WSL の中のサーバーで使えない
