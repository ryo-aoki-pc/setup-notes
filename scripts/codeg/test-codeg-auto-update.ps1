#requires -Version 5.1
# 実行: powershell.exe -NoProfile -File .\test-codeg-auto-update.ps1
# 実ネットワーク・本物のタスク・本物の Codeg を使わない。
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'Windows PowerShell 5.1 で実行してください。' }
$tokens=$null; $errors=$null
$tree=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'codeg-auto-update.ps1'),[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw '自動更新スクリプトに構文エラーがあります。' }
# 本体を実行せず、関数だけを読む。
foreach ($definition in @($tree.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst]},$false))) { . ([scriptblock]::Create($definition.Extent.Text)) }
$realVersion=(Get-Item Function:Get-CodegBinaryVersion).ScriptBlock
# 偽 EXE だけを使う呼び出しの失敗時は、wrapper のエラーを診断に残す。
# 本番の関数では標準エラーを出さない。
$diagnosticBody=$realVersion.ToString().Replace("throw '版の確認が失敗しました。'", "throw ('公開 fixture の版確認 wrapper が失敗しました: ' + `$stderr.Result)")
$realVersion=[scriptblock]::Create($diagnosticBody)
$realHealth=(Get-Item Function:Wait-CodegUpdateHealth).ScriptBlock
$realHttp=(Get-Item Function:Get-CodegHttpStatus).ScriptBlock
$realListener=(Get-Item Function:Get-CodegUpdateListener).ScriptBlock
$realCopyDatabase=(Get-Item Function:Copy-CodegDatabase).ScriptBlock
$caseRoot=Join-Path $PSScriptRoot ('aut-'+[Guid]::NewGuid().ToString('N').Substring(0,8))
[IO.Directory]::CreateDirectory($caseRoot)|Out-Null
$script:fixture=$null; $script:passed=0
function Assert-Condition { param([bool]$Condition,[string]$Message) if (-not $Condition) { throw $Message } }
function Assert-Throws { param([scriptblock]$Action,[string]$Message) $thrown=$false; try { & $Action|Out-Null } catch { $thrown=$true }; Assert-Condition $thrown $Message }
function New-TestRelease {
    param([string]$Version='0.2.0',[bool]$Draft=$false,[bool]$Prerelease=$false,[bool]$Complete=$true)
    $assets=@([pscustomobject]@{name='codeg-server-windows-x64.zip';browser_download_url='https://fixture/archive';digest=$null})
    if ($Complete) { $assets += [pscustomobject]@{name='codeg-server-windows-x64.zip.sha256';browser_download_url='https://fixture/checksum'} }
    return [pscustomobject]@{tag_name=('v'+$Version);draft=$Draft;prerelease=$Prerelease;assets=$assets}
}
function New-TestZip {
    param([string]$Path,[string[]]$Names=@('codeg-server-windows-x64/codeg-server.exe','codeg-server-windows-x64/codeg-mcp.exe','codeg-server-windows-x64/web/index.html','codeg-server-windows-x64/codeg-computer-helper.exe'),[switch]$Link)
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip=[IO.Compression.ZipFile]::Open($Path,[IO.Compression.ZipArchiveMode]::Create)
    try { foreach ($name in $Names) { $entry=$zip.CreateEntry($name); if ($Link) { $entry.ExternalAttributes=-1577058304 }; $writer=New-Object IO.StreamWriter($entry.Open()); try { $writer.Write('0.2.0') } finally { $writer.Dispose() } } } finally { $zip.Dispose() }
}
function New-TestFixture {
    param([string]$Name)
    $root=Join-Path $caseRoot $Name
    $paths=[pscustomobject]@{Server=(Join-Path $root 'server');Data=(Join-Path $root 'data');State=(Join-Path $root 'state');Backups=(Join-Path $root 'state\backups');Task='fixture-codeg-server'}
    foreach ($dir in @($paths.Server,$paths.Data,$paths.State,$paths.Backups,(Join-Path $paths.Server 'web'))) { [IO.Directory]::CreateDirectory($dir)|Out-Null }
    [IO.File]::WriteAllText((Join-Path $paths.Server 'codeg-server.exe'),'0.1.0')
    [IO.File]::WriteAllText((Join-Path $paths.Server 'codeg-mcp.exe'),'old-mcp')
    [IO.File]::WriteAllText((Join-Path $paths.Server 'web\index.html'),'old-web')
    [IO.File]::WriteAllText((Join-Path $paths.Server 'start-codeg-server.ps1'),'$env:CODEG_HOST = ''127.0.0.1'''+[Environment]::NewLine+'$env:CODEG_PORT = ''3080'''+[Environment]::NewLine)
    foreach ($name in @('codeg-hidden-launcher.exe','HiddenLauncher.cs')) { [IO.File]::WriteAllText((Join-Path $paths.Server $name),'untouched') }
    [IO.File]::WriteAllText((Join-Path $paths.Data 'codeg.db'),'old-db')
    [IO.File]::WriteAllText((Join-Path $paths.Data 'codeg.db-shm'),'old-shm')
    $archive=Join-Path $root 'source.zip'; New-TestZip $archive
    $checksum=Join-Path $root 'source.sha256'; $hash=(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText($checksum,$hash+'  codeg-server-windows-x64.zip')
    $release=New-TestRelease; $release.assets[0].digest='sha256:'+$hash
    $script:fixture=@{Paths=$paths;Archive=$archive;Checksum=$checksum;Releases=@($release);Running=$true;Stops=0;Starts=0;Downloads=0;FailNew=$false;FailOld=$false;FailStop=$false;VersionTimeout=$false;Time=([DateTime]'2026-10-16T00:00:00Z').ToUniversalTime();Http=200;Identity=1;HealthRestarts=$false;Monotonic=0.0;VersionCalls=0;HttpThrows=0;HttpRestartOnce=$false;LockLogAfterStart=$false;LogLock=$null;ApiOutputPaths=@();ApiFailAfterWrite=$false;ApiInvalidJson=$false}
    return $paths
}
# これらの差し替えは、一時 fixture のファイルだけを操作する。
function Invoke-CodegCurl {
    param([string[]]$Arguments)
    $script:fixture.CurlArguments = $Arguments
    $url = $Arguments[-1]
    if ($url -like 'https://api.github.com/*') {
        $outputIndex = [Array]::IndexOf($Arguments,'--output')
        if ($outputIndex -lt 0) { throw 'API 用の偽 curl の保存先が無い' }
        $destination = $Arguments[$outputIndex+1]
        $fixtureState = [IO.Path]::GetFullPath($script:fixture.Paths.State).TrimEnd('\')
        $outputDirectory = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($destination))
        Assert-Condition ($outputDirectory -ieq $fixtureState -or $outputDirectory.StartsWith($fixtureState+'\',[StringComparison]::OrdinalIgnoreCase)) 'API の保存先が fixture の状態フォルダーの外にある'
        $script:fixture.ApiOutputPaths += $destination
        $json = ConvertTo-Json -InputObject @($script:fixture.Releases) -Depth 8
        if ($script:fixture.ApiInvalidJson) { $json = '{ invalid JSON 中文 😀' }
        [IO.File]::WriteAllBytes($destination,(New-Object Text.UTF8Encoding($false)).GetBytes($json))
        if ($script:fixture.ApiFailAfterWrite) { throw 'API の途中失敗を模擬' }
        return ''
    }
    if ($Arguments -contains '--write-out') { if ($url.EndsWith('/api/version')) { return '401' }; return '200' }
    $script:fixture.Downloads++
    $index = [Array]::IndexOf($Arguments,'--output')
    if ($index -lt 0) { throw '偽 curl の保存先が無い' }
    if ($url.EndsWith('/checksum')) { Copy-Item -LiteralPath $script:fixture.Checksum -Destination $Arguments[$index+1] }
    elseif ($url.EndsWith('/archive')) { Copy-Item -LiteralPath $script:fixture.Archive -Destination $Arguments[$index+1] }
    else { throw '予期しない偽 curl の URL' }
    return ''
}
function Get-CodegFreePort { return 54321 }
function Get-CodegBinaryVersion { param([string]$Binary,[string]$Work) $script:fixture.VersionCalls++; if ($script:fixture.VersionTimeout -and $Binary -like '*\new\*') { throw '版確認の時間切れ' }; return [IO.File]::ReadAllText($Binary) }
function Get-CodegListeners { param($Endpoint) if ($script:fixture.Running) { return @([pscustomobject]@{LocalAddress='127.0.0.1';OwningProcess=$script:fixture.Identity}) }; return @() }
function Get-CodegTaskState { param($Paths) if ($script:fixture.Running) { return 'Running' }; return 'Ready' }
function Get-CodegUpdateListener { param($Paths,$Endpoint,[DateTime]$NotBefore) if ($script:fixture.Running) { return [pscustomobject]@{ProcessId=$script:fixture.Identity;StartTime=([DateTime]'2026-10-16T00:00:00Z').ToUniversalTime();Path=(Join-Path $Paths.Server 'codeg-server.exe')} }; return $null }
function Stop-CodegUpdateServer { param($Paths,$Endpoint) $script:fixture.Stops++; if ($script:fixture.FailStop) { throw '停止に失敗' }; $script:fixture.Running=$false }
function Start-CodegUpdateServer {
    param($Paths)
    $script:fixture.Starts++; $script:fixture.Running=$true
    if ($script:fixture.LockLogAfterStart -and -not $script:fixture.LogLock) { $script:fixture.LogLock=[IO.File]::Open((Join-Path $Paths.State 'codeg-auto-update.log'),[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None) }
    if ([IO.File]::ReadAllText((Join-Path $Paths.Server 'codeg-server.exe')) -ceq '0.2.0') { [IO.File]::WriteAllText((Join-Path $Paths.Data 'codeg.db'),'new-db'); [IO.File]::WriteAllText((Join-Path $Paths.Data 'codeg.db-wal'),'new-wal') }
}
function Wait-CodegUpdateHealth { param($Paths,$Endpoint,[DateTime]$NotBefore,[string]$Version,[string]$Work) if (($Version -eq '0.2.0' -and $script:fixture.FailNew) -or ($Version -eq '0.1.0' -and $script:fixture.FailOld)) { throw '健康確認に失敗' }; Assert-Condition ((Get-CodegBinaryVersion (Join-Path $Paths.Server 'codeg-server.exe') $Work) -ceq $Version) '本体の版が異なる' }
function Test-CodegFreeSpace { param($Paths) }
function Get-CodegUtcNow { $script:fixture.Time=$script:fixture.Time.AddSeconds(1); return $script:fixture.Time }
function Get-CodegMonotonicTime { return [double]$script:fixture.Monotonic }
function Wait-CodegUpdate { param([int]$Milliseconds) $script:fixture.Time=$script:fixture.Time.AddSeconds(1); $script:fixture.Monotonic+=1.0 }
function Get-CodegHttpStatus { param($Endpoint,[string]$Path) if ($script:fixture.HttpThrows -gt 0) { $script:fixture.HttpThrows--; throw 'HTTP の未応答' }; if ($script:fixture.HttpRestartOnce) { $script:fixture.Identity++; $script:fixture.HttpRestartOnce=$false }; if ($script:fixture.HealthRestarts) { $script:fixture.Identity++ }; if ($Path -eq '/api/version') { return 401 }; return $script:fixture.Http }
function New-TestRestoreBackup {
    param($Paths, [string]$Name='20261015T043000000000Z-0.1.0')
    $backup=Join-Path $Paths.Backups $Name
    [IO.Directory]::CreateDirectory((Join-Path $backup 'bin'))|Out-Null
    foreach ($name in @('codeg-server.exe','codeg-mcp.exe','web')) { Copy-Item -LiteralPath (Join-Path $Paths.Server $name) -Destination (Join-Path (Join-Path $backup 'bin') $name) -Recurse }
    Copy-CodegDatabase $Paths (Join-Path $backup 'db')
    return $backup
}
function Set-TestNewVersion {
    param($Paths)
    [IO.File]::WriteAllText((Join-Path $Paths.Server 'codeg-server.exe'),'0.2.0')
    [IO.File]::WriteAllText((Join-Path $Paths.Data 'codeg.db'),'new-db')
    [IO.File]::WriteAllText((Join-Path $Paths.Data 'codeg.db-wal'),'new-wal')
}
function Test-Case { param([string]$Name,[scriptblock]$Action) & $Action; $script:passed++; Write-Host ('成功: '+$Name) }
try {
    Test-Case '安定版の数値順、draft、prerelease、rc、配布物欠け' {
        $releases=@((New-TestRelease '0.2.0'),(New-TestRelease '0.3.0-rc.2'),(New-TestRelease '0.8.0' $true),(New-TestRelease '0.9.0' $false $true),(New-TestRelease '0.7.0' $false $false $false),(New-TestRelease '0.1.99'))
        Assert-Condition ((Select-CodegRelease $releases).Version -eq '0.2.0') '安定版の選択が不正'
        $releases += New-TestRelease '0.10.0'
        Assert-Condition ((Select-CodegRelease $releases).Version -eq '0.10.0') '数値順になっていない'
        Assert-Throws { Select-CodegRelease @((New-TestRelease '1.0.0-rc.1')) } 'rc だけを受け入れた'
    }
    Test-Case '偽 curl で複数行 JSON とプロキシ無し HTTP を確認する' {
        $p=New-TestFixture 'curl'
        Assert-Condition ((Select-CodegRelease @(Get-CodegReleases $p.State)).Version -eq '0.2.0') '複数行の JSON を解釈できない'
        Assert-Condition ((& $realHttp (Get-CodegEndpoint $p) '/') -eq 200) '画面の応答が異なる'
        Assert-Condition ((& $realHttp (Get-CodegEndpoint $p) '/api/version') -eq 401) '未認証 API の応答が異なる'
        $args=$script:fixture.CurlArguments
        Assert-Condition ($args -contains '--noproxy' -and $args -contains '*') 'HTTP がプロキシを通る'
    }
    $jsonEncodingFixture=New-TestFixture 'json-encoding'
    $jsonEncodingSaved=[Console]::OutputEncoding; $jsonEncodingReady=$false
    try {
        try {
            [Console]::OutputEncoding=[Text.Encoding]::GetEncoding(932)
            if ([Console]::OutputEncoding.CodePage -ne 932) { throw '出力のコードページが切り替わりません。' }
            $jsonEncodingReady=$true
        } catch { Write-Host 'スキップ: UTF-8 JSON の試験で Console.OutputEncoding を cp932 へ切り替えられません。' }
        if ($jsonEncodingReady) {
            Test-Case 'cp932 の出力設定でも中国語と絵文字の UTF-8 JSON を読み、一時ファイルを消す' {
                $description=('修复中文：服务器更新 😀 引号 "内容"' + [Environment]::NewLine) * 50000
                $latest=New-TestRelease '0.10.0'; $latest | Add-Member -NotePropertyName body -NotePropertyValue $description
                $script:fixture.Releases += $latest
                $fetched=@(Get-CodegReleases $jsonEncodingFixture.State)
                Assert-Condition ((Select-CodegRelease $fetched).Version -ceq '0.10.0') 'cp932 の出力設定で正しい版を選べない'
                $latestFetched=@($fetched | Where-Object { $_.tag_name -ceq 'v0.10.0' })
                Assert-Condition ($latestFetched.Count -eq 1 -and $latestFetched[0].body -ceq $description) '中国語または絵文字の本文が変わった'
                $fetchedAgain=@(Get-CodegReleases $jsonEncodingFixture.State)
                Assert-Condition ((Select-CodegRelease $fetchedAgain).Version -ceq '0.10.0' -and $script:fixture.ApiOutputPaths.Count -eq 2 -and $script:fixture.ApiOutputPaths[0] -cne $script:fixture.ApiOutputPaths[1]) '一時 JSON の保存先を使い回した'
                foreach ($jsonFile in $script:fixture.ApiOutputPaths) { Assert-Condition (-not (Test-Path -LiteralPath $jsonFile)) '成功した一時 JSON が残った' }
                [Console]::OutputEncoding=$jsonEncodingSaved
            }
        }
    } finally { [Console]::OutputEncoding=$jsonEncodingSaved }
    Test-Case 'リリース JSON の取得と解析が失敗しても一時ファイルを消す' {
        foreach ($failure in @('curl','json')) {
            $p=New-TestFixture ('json-failure-'+$failure)
            if ($failure -eq 'curl') { $script:fixture.ApiFailAfterWrite=$true } else { $script:fixture.ApiInvalidJson=$true }
            Assert-Throws { Get-CodegReleases $p.State } 'API の取得または JSON 解析の失敗を無視した'
            Assert-Condition ($script:fixture.ApiOutputPaths.Count -eq 1 -and -not (Test-Path -LiteralPath $script:fixture.ApiOutputPaths[0])) '失敗した一時 JSON が残った'
        }
    }
    Test-Case '最新を使用中' {
        $p=New-TestFixture 'latest'; $script:fixture.Releases=@(New-TestRelease '0.1.0')
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 0) '最新で 0 にならない'
        Assert-Condition ($script:fixture.Stops -eq 0 -and $script:fixture.Downloads -eq 0) '最新なのに停止または取得した'
    }
    Test-Case '停止中には更新しない' {
        $p=New-TestFixture 'stopped'; $script:fixture.Running=$false
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 0) '停止中で 0 にならない'
        Assert-Condition ($script:fixture.Stops -eq 0 -and $script:fixture.Downloads -eq 0) '停止中に変更した'
    }
    Test-Case '保留、解除、古い保留の自動解除' {
        $p=New-TestFixture 'held'; $skip=Join-Path $p.State 'skip-version'; Write-CodegUpdateState $skip '0.2.0'
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 1) '保留で 1 にならない'; Assert-Condition ($script:fixture.Stops -eq 0) '保留中に止めた'
        Remove-Item -LiteralPath $skip
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 0) '保留解除で更新できない'
        Write-CodegUpdateState $skip '0.1.0'
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 0 -and -not (Test-Path -LiteralPath $skip)) '古い保留が残った'
    }
    Test-Case 'SHA-256 不一致では止めない' {
        $p=New-TestFixture 'bad-checksum'; [IO.File]::WriteAllText($script:fixture.Checksum,('0'*64)+'  codeg-server-windows-x64.zip')
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 1 -and $script:fixture.Stops -eq 0) 'SHA 不一致で停止した'
    }
    Test-Case 'digest 不一致では止めない' {
        $p=New-TestFixture 'bad-digest'; $script:fixture.Releases[0].assets[0].digest='sha256:'+('0'*64)
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 1 -and $script:fixture.Stops -eq 0) 'digest 不一致で停止した'
    }
    Test-Case 'digest が無いときは記録する' {
        $p=New-TestFixture 'no-digest'; $script:fixture.Releases[0].assets[0].digest=$null
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 0) 'digest 無しで更新できない'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.State 'codeg-auto-update.log')).Contains('digest が無い')) 'digest 無しを記録しない'
    }
    Test-Case 'ZIP の ..、絶対パス、ルート外、リンクを拒む' {
        $dir=Join-Path $caseRoot 'bad-zips'; [IO.Directory]::CreateDirectory($dir)|Out-Null; $i=0
        foreach ($name in @('codeg-server-windows-x64/../escape','/codeg-server-windows-x64/escape','C:/codeg-server-windows-x64/escape','other/escape','codeg-server-windows-x64/..\escape')) {
            $zip=Join-Path $dir ('bad'+$i+'.zip'); New-TestZip $zip @($name)
            Assert-Throws { Expand-CodegArchive $zip (Join-Path $dir ('out'+$i)) } ('不正な ZIP を許した: '+$name); $i++
        }
        $zip=Join-Path $dir 'link.zip'; New-TestZip $zip @('codeg-server-windows-x64/link') -Link
        Assert-Throws { Expand-CodegArchive $zip (Join-Path $dir 'out-link') } 'リンクを許した'
    }
    Test-Case '版確認の時間切れは停止前に保留する' {
        $p=New-TestFixture 'version-timeout'; $script:fixture.VersionTimeout=$true
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 1 -and $script:fixture.Stops -eq 0) '版確認失敗で停止した'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.State 'skip-version')).Trim() -eq '0.2.0') '時間切れで保留しない'
    }
    Test-Case '更新し、本体以外に触れず、トークンを開かない' {
        $p=New-TestFixture 'success'; $token=Join-Path $p.Server 'token.txt'; [IO.File]::WriteAllText($token,'public-fixture-only')
        $tokenLock=[IO.File]::Open($token,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        try { Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 0) '更新が失敗した' } finally { $tokenLock.Dispose() }
        foreach ($name in @('codeg-hidden-launcher.exe','HiddenLauncher.cs')) { Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Server $name)) -ceq 'untouched') '補助ファイルを変更した' }
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Server 'codeg-server.exe')) -ceq '0.2.0') '新版本体ではない'
        Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $p.State 'in-progress'))) 'マーカーが残った'
    }
    Test-Case '起動失敗から本体と DB を戻し、新しい WAL を退かす' {
        $p=New-TestFixture 'restore'; $script:fixture.FailNew=$true
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 2) '復元で 2 にならない'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Server 'codeg-server.exe')) -ceq '0.1.0') '旧本体に戻らない'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Data 'codeg.db')) -ceq 'old-db') '旧 DB に戻らない'
        Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $p.Data 'codeg.db-wal'))) '新しい WAL が旧 DB に残った'
        $failed=@(Get-ChildItem -LiteralPath $p.Backups -Directory -Filter 'failed-*')
        Assert-Condition ($failed.Count -eq 1 -and (Test-Path -LiteralPath (Join-Path $failed[0].FullName 'db\codeg.db-wal'))) '失敗した DB 一式を残していない'
        Assert-Condition (@(Get-ChildItem -LiteralPath $p.Backups -Directory | Where-Object {$_.Name -notlike 'failed-*'}).Count -eq 1) '復元用の完全な控えが残っていない'
    }
    Test-Case '戻した版の確認に失敗すれば 3' {
        $p=New-TestFixture 'restore-fails'; $script:fixture.FailNew=$true; $script:fixture.FailOld=$true
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 3) '復元失敗で 3 にならない'
        Assert-Condition (Test-Path -LiteralPath (Join-Path $p.State 'in-progress')) '復元失敗のマーカーが無い'
    }
    Test-Case '中断マーカーがあれば何も変えず 3' {
        $p=New-TestFixture 'in-progress'; Write-CodegProgress (Join-Path $p.State 'in-progress') 'checking' 'fixture' '0.1.0' '0.2.0'
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 3 -and $script:fixture.Stops -eq 0 -and $script:fixture.Downloads -eq 0) '途中の状態に触れた'
        $log=[IO.File]::ReadAllText((Join-Path $p.State 'codeg-auto-update.log'))
        Assert-Condition ($log.Contains('docs/extra/codeg.md の「Windows 11 で自動更新の控えから前の版と DB に戻す」')) '復旧先のパスと見出しが異なる'
    }
    Test-Case 'ロックが取れなければ 1' {
        $p=New-TestFixture 'locked'; $lock=[IO.File]::Open((Join-Path $p.State 'lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        try { Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 1 -and $script:fixture.Stops -eq 0) 'ロックを無視した' } finally { $lock.Dispose() }
    }
    Test-Case '自己更新の目印があれば止めない' {
        foreach ($name in @('.codeg-upgrade-staged','codeg-server.exe.bak')) { $p=New-TestFixture ('staged'+[Guid]::NewGuid().ToString('N')); [IO.File]::WriteAllText((Join-Path $p.Server $name),'fixture'); Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 1 -and $script:fixture.Stops -eq 0) '自己更新の状態を無視した' }
    }
    Test-Case '控えは新しい 2 世代で failed は残す' {
        $p=New-TestFixture 'retention'
        foreach ($name in @('20261010T010000000000Z-0.1.0','20261011T010000000000Z-0.1.0','20261012T010000000000Z-0.1.0','failed-20261009T010000000000Z','manual')) { [IO.Directory]::CreateDirectory((Join-Path $p.Backups $name))|Out-Null }
        Remove-CodegOldBackups $p
        Assert-Condition (@(Get-ChildItem -LiteralPath $p.Backups -Directory).Count -eq 4) '保持数が異なる'
        Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $p.Backups '20261010T010000000000Z-0.1.0'))) '最古の控えが残った'
    }
    Test-Case '30 秒の HTTP 安定確認と再起動の検出' {
        $p=New-TestFixture 'health'; $endpoint=Get-CodegEndpoint $p
        & $realHealth $p $endpoint ([DateTime]::MinValue) '0.1.0' $p.State
        $script:fixture.Http=500; Assert-Throws { & $realHealth $p $endpoint ([DateTime]::MinValue) '0.1.0' $p.State } 'HTTP 失敗を許した'
        $script:fixture.Http=200; $script:fixture.HealthRestarts=$true; Assert-Throws { & $realHealth $p $endpoint ([DateTime]::MinValue) '0.1.0' $p.State } '再起動中を許した'
    }
    Test-Case '待ち受けの実行パスと開始時刻を確認する' {
        $p=New-TestFixture 'listener'; $endpoint=Get-CodegEndpoint $p
        $script:fixture.ListenerPort=$endpoint.Port; $script:fixture.ListenerPath=Join-Path $p.Server 'codeg-server.exe'
        $script:fixture.ListenerTime=[DateTime]'2026-10-16T00:00:01Z'
        function Get-CodegListeners { param($Endpoint) return @([pscustomobject]@{LocalAddress='127.0.0.1';OwningProcess=700001}) }
        function Get-Process { [CmdletBinding()] param([int]$Id) Assert-Condition ($Id -eq 700001) '予期しない PID'; return [pscustomobject]@{Id=700001;Path=$script:fixture.ListenerPath;StartTime=$script:fixture.ListenerTime} }
        Assert-Condition ((& $realListener $p $endpoint ([DateTime]'2026-10-16T00:00:00Z').ToUniversalTime()).ProcessId -eq 700001) '正しい本体を認めない'
        $script:fixture.ListenerPath=Join-Path $p.Server 'other.exe'
        Assert-Throws { & $realListener $p $endpoint ([DateTime]'2026-10-16T00:00:00Z').ToUniversalTime() } '違う実行ファイルを認めた'
        $script:fixture.ListenerPath=Join-Path $p.Server 'codeg-server.exe'
        Assert-Throws { & $realListener $p $endpoint ([DateTime]'2026-10-16T00:00:02Z').ToUniversalTime() } '古い開始時刻を認めた'
    }
    Test-Case '停止に失敗したら旧版を始め直して 1' {
        $p=New-TestFixture 'stop-fails'; $script:fixture.FailStop=$true
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 1 -and $script:fixture.Starts -eq 1) '停止失敗から始め直さない'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Server 'codeg-server.exe')) -ceq '0.1.0') '停止失敗なのに本体を替えた'
    }
    Test-Case '更新後に控えの整理が失敗しても更新済み 0' {
        $p=New-TestFixture 'cleanup-backups'
        function Remove-CodegOldBackups { param($Paths) throw '控え整理の模擬失敗' }
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 0) '更新済みを中断とした'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Server 'codeg-server.exe')) -ceq '0.2.0') '更新済みではない'
    }
    Test-Case '更新後に marker を消せなければ 3、更新した本体を保つ' {
        $p=New-TestFixture 'cleanup-marker'
        function Remove-Item {
            [CmdletBinding()] param([string]$LiteralPath,[switch]$Force,[switch]$Recurse)
            if ($LiteralPath -eq (Join-Path $script:fixture.Paths.State 'in-progress')) { throw 'marker 削除の模擬失敗' }
            Microsoft.PowerShell.Management\Remove-Item -LiteralPath $LiteralPath -Force:$Force -Recurse:$Recurse
        }
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 3) 'marker があるのに中断 1 とした'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Server 'codeg-server.exe')) -ceq '0.2.0') '確認済みの新版を戻した'
    }
    Test-Case 'DB のフォルダーと各エントリの再解析ポイントを拒む' {
        $p=New-TestFixture 'db-reparse'
        $script:fixture.DataReparse=$false; $script:fixture.FileReparse=$false; $script:fixture.FileDirectory=$false
        function Get-Item {
            [CmdletBinding()] param([string]$LiteralPath,[switch]$Force)
            Assert-Condition ($LiteralPath -eq $script:fixture.Paths.Data) '予期しないフォルダー'
            $attrs=[IO.FileAttributes]::Directory
            if ($script:fixture.DataReparse) { $attrs=$attrs -bor [IO.FileAttributes]::ReparsePoint }
            return [pscustomobject]@{PSIsContainer=$true;Attributes=$attrs}
        }
        function Get-ChildItem {
            [CmdletBinding()] param([string]$LiteralPath,[string]$Filter,[switch]$Force)
            Assert-Condition ($LiteralPath -eq $script:fixture.Paths.Data -and $Filter -eq 'codeg.db*') '予期しない DB の列挙'
            $attrs=[IO.FileAttributes]::Normal
            if ($script:fixture.FileReparse) { $attrs=[IO.FileAttributes]::ReparsePoint }
            return [pscustomobject]@{PSIsContainer=$script:fixture.FileDirectory;Attributes=$attrs}
        }
        Assert-Condition (@(Get-CodegDatabaseFiles $p).Count -eq 1) '通常の DB を拒否した'
        $script:fixture.DataReparse=$true; Assert-Throws { Get-CodegDatabaseFiles $p } 'データのフォルダーのリンクを許した'
        $script:fixture.DataReparse=$false; $script:fixture.FileReparse=$true; Assert-Throws { Get-CodegDatabaseFiles $p } 'DB ファイルのリンクを許した'
        $script:fixture.FileReparse=$false; $script:fixture.FileDirectory=$true; Assert-Throws { Get-CodegDatabaseFiles $p } 'DB 名のフォルダーを許した'
    }
    Test-Case '通常の控えを自分で停止して復元し、現本体と DB 全件を退避する' {
        $p=New-TestFixture 'manual-normal'; $backup=New-TestRestoreBackup $p; Set-TestNewVersion $p
        $token=Join-Path $p.Server 'token.txt'; [IO.File]::WriteAllText($token,'public-fixture-only')
        $tokenLock=[IO.File]::Open($token,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        try { Assert-Condition ((Invoke-CodegRestore $p ([IO.Path]::GetFileName($backup)) '0.2.0') -eq 0) '通常の復元が失敗した' } finally { $tokenLock.Dispose() }
        Assert-Condition ($script:fixture.Stops -eq 1 -and $script:fixture.Starts -eq 1) '停止と開始を自分で行っていない'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Server 'codeg-server.exe')) -ceq '0.1.0') '旧版本体に戻らない'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Data 'codeg.db')) -ceq 'old-db') 'DB が戻らない'
        Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $p.Data 'codeg.db-wal'))) '新 WAL が残った'
        $failed=@(Get-ChildItem -LiteralPath $p.Backups -Directory -Filter 'failed-manual-*')
        Assert-Condition ($failed.Count -eq 1 -and [IO.File]::ReadAllText((Join-Path $failed[0].FullName 'bin\codeg-server.exe')) -ceq '0.2.0' -and (Test-Path -LiteralPath (Join-Path $failed[0].FullName 'db\codeg.db-wal'))) '現在の本体と DB を退避していない'
        Assert-Condition ((Test-Path -LiteralPath (Join-Path $backup 'bin\codeg-server.exe')) -and (Test-Path -LiteralPath (Join-Path $backup 'db\codeg.db'))) '元の完全な控えを消した'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.State 'skip-version')).Trim() -ceq '0.2.0') '問題版を保留していない'
        Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $p.State 'in-progress'))) '成功後の marker が残った'
    }
    Test-Case '止まっている Codeg も復元後に開始する' {
        $p=New-TestFixture 'manual-ready'; $backup=New-TestRestoreBackup $p; Set-TestNewVersion $p; $script:fixture.Running=$false
        Assert-Condition ((Invoke-CodegRestore $p ([IO.Path]::GetFileName($backup)) '0.2.0') -eq 0 -and $script:fixture.Starts -eq 1) '停止中の復元後に起動しない'
    }
    Test-Case 'backing-up の分かれた本体を揃え、元 DB を保持する' {
        $p=New-TestFixture 'manual-partial'; $name='20261015T043000000000Z-0.1.0'; $backup=Join-Path $p.Backups $name
        [IO.Directory]::CreateDirectory((Join-Path $backup 'bin'))|Out-Null; [IO.Directory]::CreateDirectory((Join-Path $backup 'db'))|Out-Null
        foreach ($item in @('codeg-server.exe','web')) { Move-Item -LiteralPath (Join-Path $p.Server $item) -Destination (Join-Path (Join-Path $backup 'bin') $item) }
        [IO.File]::WriteAllText((Join-Path $backup 'db\codeg.db'),'incomplete-db')
        [IO.File]::WriteAllText((Join-Path $p.Data 'codeg.db-wal'),'original-wal')
        Write-CodegProgress (Join-Path $p.State 'in-progress') 'backing-up' $backup '0.1.0' '0.2.0'
        $script:fixture.Running=$false
        Assert-Condition ((Invoke-CodegRestore $p $name '0.2.0') -eq 0) 'backing-up の復元が失敗した'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Data 'codeg.db')) -ceq 'old-db' -and [IO.File]::ReadAllText((Join-Path $p.Data 'codeg.db-wal')) -ceq 'original-wal') '元 DB 一式を変更した'
        Assert-Condition (-not (Test-Path -LiteralPath $backup)) '部分控えを退避していない'
        $failed=@(Get-ChildItem -LiteralPath $p.Backups -Directory -Filter 'failed-manual-*')
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $failed[0].FullName 'partial-backup\db\codeg.db')) -ceq 'incomplete-db') '部分 DB を保全していない'
    }
    Test-Case 'backing-up の起動失敗後も元 DB と段階を保ち再試行できる' {
        $p=New-TestFixture 'manual-partial-retry'; $name='20261015T043000000000Z-0.1.0'; $backup=Join-Path $p.Backups $name
        [IO.Directory]::CreateDirectory((Join-Path $backup 'bin'))|Out-Null
        Move-Item -LiteralPath (Join-Path $p.Server 'codeg-server.exe') -Destination (Join-Path $backup 'bin\codeg-server.exe')
        Write-CodegProgress (Join-Path $p.State 'in-progress') 'backing-up' $backup '0.1.0' '0.2.0'
        $script:fixture.Running=$false
        $script:fixture.FailOld=$true
        Assert-Condition ((Invoke-CodegRestore $p $name '0.2.0') -eq 3) '旧版の起動失敗で 3 にならない'
        $progress=[IO.File]::ReadAllText((Join-Path $p.State 'in-progress'))|ConvertFrom-Json
        Assert-Condition ($progress.stage -ceq 'backing-up' -and [IO.File]::ReadAllText((Join-Path $p.Data 'codeg.db')) -ceq 'old-db') '段階または元 DB を変えた'
        $script:fixture.FailOld=$false
        Assert-Condition ((Invoke-CodegRestore $p $name '0.2.0') -eq 0) 'backing-up の復元を再試行できない'
    }
    Test-Case '控え名と本体版が違えば停止せず 1' {
        $p=New-TestFixture 'manual-version'; $backup=New-TestRestoreBackup $p
        [IO.File]::WriteAllText((Join-Path $backup 'bin\codeg-server.exe'),'0.0.9')
        Assert-Condition ((Invoke-CodegRestore $p ([IO.Path]::GetFileName($backup)) '0.2.0') -eq 1 -and $script:fixture.Stops -eq 0) '控え名と版の不一致を無視した'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Server 'codeg-server.exe')) -ceq '0.1.0') '前提不一致で本体を替えた'
    }
    Test-Case '不正な引数と不完全な通常の控えは停止せず 1' {
        $p=New-TestFixture 'manual-input'; $backup=New-TestRestoreBackup $p
        foreach ($pair in @(@('../outside','0.2.0'),@([IO.Path]::GetFileName($backup),''),@('failed-manual-20261015T043000Z','0.2.0'))) { Assert-Condition ((Invoke-CodegRestore $p $pair[0] $pair[1]) -eq 1) '不正な引数を許した' }
        Remove-Item -LiteralPath (Join-Path $backup 'db\codeg.db')
        Assert-Condition ((Invoke-CodegRestore $p ([IO.Path]::GetFileName($backup)) '0.2.0') -eq 1 -and $script:fixture.Stops -eq 0) '不完全な DB の控えを許した'
    }
    Test-Case '復元でも自己更新の目印とロックを尊重する' {
        $p=New-TestFixture 'manual-lock'; $backup=New-TestRestoreBackup $p
        $lock=[IO.File]::Open((Join-Path $p.State 'lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        try { Assert-Condition ((Invoke-CodegRestore $p ([IO.Path]::GetFileName($backup)) '0.2.0') -eq 1) 'ロックを無視した' } finally { $lock.Dispose() }
        [IO.File]::WriteAllText((Join-Path $p.Server '.codeg-upgrade-staged'),'fixture')
        Assert-Condition ((Invoke-CodegRestore $p ([IO.Path]::GetFileName($backup)) '0.2.0') -eq 1 -and $script:fixture.Stops -eq 0) '自己更新の目印を無視した'
    }
    Test-Case '復元の marker は既知の段階、同じ控え、old/new を必須にする' {
        foreach ($difference in @('stage','backup','old','new')) {
            $p=New-TestFixture ('manual-marker-'+$difference); $backup=New-TestRestoreBackup $p
            $progress=@{stage='checking';backup=$backup;old='0.1.0';new='0.2.0'}
            $progress[$difference]=@{stage='unknown';backup=(Join-Path $p.Backups 'other');old='0.0.9';new='0.3.0'}[$difference]
            Write-CodegUpdateState (Join-Path $p.State 'in-progress') ($progress|ConvertTo-Json -Compress)
            Assert-Condition ((Invoke-CodegRestore $p ([IO.Path]::GetFileName($backup)) '0.2.0') -eq 1 -and $script:fixture.Stops -eq 0) ('marker 不一致を許した: '+$difference)
        }
    }
    Test-Case '退避が済んだ各段階の完成した控えから復元する' {
        foreach ($stage in @('installing','checking','rolling-back')) {
            $p=New-TestFixture ('manual-stage-'+$stage); $backup=New-TestRestoreBackup $p; Set-TestNewVersion $p
            Write-CodegProgress (Join-Path $p.State 'in-progress') $stage $backup '0.1.0' '0.2.0'
            Assert-Condition ((Invoke-CodegRestore $p ([IO.Path]::GetFileName($backup)) '0.2.0') -eq 0) ('既知の段階から復元できない: '+$stage)
        }
    }
    Test-Case '通常の復元の健康確認失敗は控えと現行の退避を保全し 3' {
        $p=New-TestFixture 'manual-health'; $backup=New-TestRestoreBackup $p; Set-TestNewVersion $p; $script:fixture.FailOld=$true
        Assert-Condition ((Invoke-CodegRestore $p ([IO.Path]::GetFileName($backup)) '0.2.0') -eq 3) '復元の健康確認失敗で 3 にならない'
        Assert-Condition ((Test-Path -LiteralPath (Join-Path $backup 'bin\codeg-server.exe')) -and (Test-Path -LiteralPath (Join-Path $backup 'db\codeg.db')) -and (Test-Path -LiteralPath (Join-Path $p.State 'in-progress'))) '失敗時の控えまたは marker が無い'
        Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $p.State 'skip-version'))) '確認に失敗したのに保留を書いた'
        $failed=@(Get-ChildItem -LiteralPath $p.Backups -Directory -Filter 'failed-manual-*')
        Assert-Condition ($failed.Count -eq 1 -and (Test-Path -LiteralPath (Join-Path $failed[0].FullName 'db\codeg.db-wal'))) '現行の退避が無い'
    }
    Test-Case 'backing-up の要素を戻す途中で失敗しても片方だけを保ち再試行できる' {
        $p=New-TestFixture 'manual-move-retry'; $name='20261015T043000000000Z-0.1.0'; $backup=Join-Path $p.Backups $name
        [IO.Directory]::CreateDirectory((Join-Path $backup 'bin'))|Out-Null
        Move-CodegBinaries $p.Server (Join-Path $backup 'bin')
        Write-CodegProgress (Join-Path $p.State 'in-progress') 'backing-up' $backup '0.1.0' '0.2.0'
        $script:fixture.Running=$false
        $script:fixture.FailRestoreMove=$true
        function Move-Item {
            [CmdletBinding()] param([string]$LiteralPath,[string]$Destination)
            if ($LiteralPath.EndsWith('\bin\codeg-mcp.exe') -and $script:fixture.FailRestoreMove) { $script:fixture.FailRestoreMove=$false; throw '不足要素を戻す途中の模擬失敗' }
            Microsoft.PowerShell.Management\Move-Item -LiteralPath $LiteralPath -Destination $Destination
        }
        Assert-Condition ((Invoke-CodegRestore $p $name '0.2.0') -eq 3) '要素の復元失敗で 3 にならない'
        foreach ($item in @('codeg-server.exe','codeg-mcp.exe','web')) {
            $count=@(@((Join-Path $p.Server $item),(Join-Path (Join-Path $backup 'bin') $item)) | Where-Object { Test-Path -LiteralPath $_ }).Count
            Assert-Condition ($count -eq 1) '同じ要素が両方に残ったか両方から消えた'
        }
        Assert-Condition ((Invoke-CodegRestore $p $name '0.2.0') -eq 0) '部分 Move の失敗後に再試行できない'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Data 'codeg.db')) -ceq 'old-db') '元 DB を変えた'
    }
    Test-Case '自動退避の DB コピーと旧版確認が失敗しても backing-up から復旧できる' {
        $p=New-TestFixture 'auto-copy-retry'; $script:fixture.FailOld=$true
        function Copy-CodegDatabase {
            param($Paths,[string]$Destination)
            [IO.Directory]::CreateDirectory($Destination)|Out-Null
            [IO.File]::WriteAllText((Join-Path $Destination 'codeg.db'),'incomplete-db')
            throw 'DB の退避コピー途中の模擬失敗'
        }
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 3) '旧版確認失敗で 3 にならない'
        $progress=[IO.File]::ReadAllText((Join-Path $p.State 'in-progress'))|ConvertFrom-Json
        Assert-Condition ($progress.stage -ceq 'backing-up') 'コピー途中の DB を完成済みとして扱った'
        $script:fixture.FailOld=$false
        Assert-Condition ((Invoke-CodegRestore $p ([IO.Path]::GetFileName($progress.backup)) '0.2.0') -eq 0) '自動退避の失敗から復元できない'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Data 'codeg.db')) -ceq 'old-db') '不完全な控えを元 DB へ戻した'
    }
    Test-Case '停止失敗と旧版確認失敗の restart-failed でも元 DB を保持して復元する' {
        $p=New-TestFixture 'auto-stop-retry'; $script:fixture.FailStop=$true; $script:fixture.FailOld=$true
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 3) '停止と旧版確認の失敗で 3 にならない'
        $progress=[IO.File]::ReadAllText((Join-Path $p.State 'in-progress'))|ConvertFrom-Json
        Assert-Condition ($progress.stage -ceq 'restart-failed' -and [IO.Path]::IsPathRooted($progress.backup)) '元 DB を保持する段階と控え名を記録しない'
        Assert-Condition (-not (Test-Path -LiteralPath $progress.backup)) 'コピーしていない DB を控えとして作った'
        $script:fixture.FailStop=$false; $script:fixture.FailOld=$false
        Assert-Condition ((Invoke-CodegRestore $p ([IO.Path]::GetFileName($progress.backup)) '0.2.0') -eq 0) 'restart-failed から復元できない'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Data 'codeg.db')) -ceq 'old-db') '元 DB を変えた'
    }
    Test-Case '安定版は draft/prerelease の明示 false と ASCII のタグだけを選ぶ' {
        $missingDraft=New-TestRelease '0.9.0'; $missingDraft.PSObject.Properties.Remove('draft')
        $missingPrerelease=New-TestRelease '0.8.0'; $missingPrerelease.PSObject.Properties.Remove('prerelease')
        $nullDraft=New-TestRelease '0.7.0'; $nullDraft.draft=$null
        $unicode=New-TestRelease '０.６.０'
        Assert-Condition ((Select-CodegRelease @($missingDraft,$missingPrerelease,$nullDraft,$unicode,(New-TestRelease '0.2.0'))).Version -ceq '0.2.0') '未確認の安定属性か Unicode 数字を許した'
        Assert-Throws { Select-CodegRelease @($missingDraft,$missingPrerelease,$nullDraft,$unicode) } '不完全な安定情報を使った'
    }
    Test-Case '一度だけ起動し直されても健康確認を即失敗にする' {
        $p=New-TestFixture 'one-restart'; $script:fixture.HttpRestartOnce=$true
        Assert-Throws { & $realHealth $p (Get-CodegEndpoint $p) ([DateTime]::MinValue) '0.1.0' $p.State } '1 回だけの再起動を見逃した'
        Assert-Condition ($script:fixture.Monotonic -lt 30 -and $script:fixture.VersionCalls -eq 0) '再起動後も安定待ちを続けた'
    }
    Test-Case 'HTTP 中にタスクが止まったら猶予を待たず失敗する' {
        $p=New-TestFixture 'task-stops'; $script:fixture.TaskQueries=0
        function Get-CodegTaskState { param($Paths) $script:fixture.TaskQueries++; if ($script:fixture.TaskQueries -gt 1) { return 'Ready' }; return 'Running' }
        Assert-Throws { & $realHealth $p (Get-CodegEndpoint $p) ([DateTime]::MinValue) '0.1.0' $p.State } 'タスクの停止を見逃した'
        Assert-Condition ($script:fixture.Monotonic -eq 0) '停止後も待ち続けた'
    }
    Test-Case '版が違えば一度の版確認で失敗する' {
        $p=New-TestFixture 'health-version'
        Assert-Throws { & $realHealth $p (Get-CodegEndpoint $p) ([DateTime]::MinValue) '0.9.0' $p.State } '版の不一致を許した'
        Assert-Condition ($script:fixture.VersionCalls -eq 1 -and $script:fixture.Monotonic -lt 120) '版の不一致から確認をやり直した'
    }
    Test-Case 'HTTP 未応答は再試行し、壁時計が戻っても単調時計で 30 秒を確かめる' {
        $p=New-TestFixture 'health-monotonic'; $script:fixture.HttpThrows=3
        function Wait-CodegUpdate { param([int]$Milliseconds) $script:fixture.Time=$script:fixture.Time.AddDays(-1); $script:fixture.Monotonic+=1.0 }
        & $realHealth $p (Get-CodegEndpoint $p) ([DateTime]::MinValue) '0.1.0' $p.State
        Assert-Condition ($script:fixture.Monotonic -ge 33 -and $script:fixture.Monotonic -lt 120 -and $script:fixture.VersionCalls -eq 1) '未応答の猶予または単調時計が正しくない'
    }
    Test-Case 'HTTP の完了が 120 秒以上なら成功せず版確認も始めない' {
        foreach ($finishedAt in @(120.0,121.0)) {
            $p=New-TestFixture ('late-http-'+$finishedAt); $script:fixture.FinishedAt=$finishedAt
            function Get-CodegHttpStatus {
                param($Endpoint,[string]$Path)
                if ($script:fixture.Monotonic -ge 30) { $script:fixture.Monotonic=$script:fixture.FinishedAt }
                if ($Path -eq '/api/version') { return 401 }; return 200
            }
            Assert-Throws { & $realHealth $p (Get-CodegEndpoint $p) ([DateTime]::MinValue) '0.1.0' $p.State } '期限後の HTTP 完了を成功とした'
            Assert-Condition ($script:fixture.VersionCalls -eq 0 -and $script:fixture.Monotonic -ge 120) '期限後に版の確認を始めた'
        }
    }
    Test-Case '版確認の完了が 120 秒以上なら成功しない' {
        foreach ($finishedAt in @(120.0,121.0)) {
            $p=New-TestFixture ('late-version-'+$finishedAt); $script:fixture.FinishedAt=$finishedAt
            function Get-CodegBinaryVersion {
                param([string]$Binary,[string]$Work)
                $script:fixture.VersionCalls++; $script:fixture.Monotonic=$script:fixture.FinishedAt
                return [IO.File]::ReadAllText($Binary)
            }
            Assert-Throws { & $realHealth $p (Get-CodegEndpoint $p) ([DateTime]::MinValue) '0.1.0' $p.State } '期限後の版確認完了を成功とした'
            Assert-Condition ($script:fixture.VersionCalls -eq 1 -and $script:fixture.Monotonic -ge 120) '版確認後の期限を正しく検査しない'
        }
    }
    Test-Case '復元の停止が失敗したら復元先ではなく現行版の再開を確認して 1' {
        $p=New-TestFixture 'manual-stop-resume'; $backup=New-TestRestoreBackup $p; Set-TestNewVersion $p; $script:fixture.FailStop=$true
        Assert-Condition ((Invoke-CodegRestore $p ([IO.Path]::GetFileName($backup)) '0.2.0') -eq 1) '現行版を再開して 1 にならない'
        Assert-Condition ($script:fixture.Starts -eq 1 -and [IO.File]::ReadAllText((Join-Path $p.Server 'codeg-server.exe')) -ceq '0.2.0') '現行版を再開せず、復元先へ替えた'
        Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $p.State 'in-progress')) -and -not @(Get-ChildItem -LiteralPath $p.Backups -Filter 'failed-manual-*' -Directory).Count) '未移動なのに marker または退避を残した'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Data 'codeg.db')) -ceq 'new-db') '停止失敗で DB を戻した'
    }
    Test-Case '復元の停止も現行版の再開も失敗すれば marker を保ち 3' {
        $p=New-TestFixture 'manual-stop-resume-fails'; $backup=New-TestRestoreBackup $p; Set-TestNewVersion $p; $script:fixture.FailStop=$true; $script:fixture.FailNew=$true
        Assert-Condition ((Invoke-CodegRestore $p ([IO.Path]::GetFileName($backup)) '0.2.0') -eq 3) '再開失敗で 3 にならない'
        Assert-Condition ((Test-Path -LiteralPath (Join-Path $p.State 'in-progress')) -and [IO.File]::ReadAllText((Join-Path $p.Server 'codeg-server.exe')) -ceq '0.2.0') '再開失敗の marker または現行を失った'
    }
    Test-Case '自動巻き戻しも fsync する DB コピー関数を使う' {
        $p=New-TestFixture 'rollback-fsync'; $script:fixture.FailNew=$true; $script:fixture.Copies=0
        function Copy-CodegDatabase { param($Paths,[string]$Destination) $script:fixture.Copies++; & $realCopyDatabase $Paths $Destination }
        Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 2 -and $script:fixture.Copies -eq 2) 'DB の戻しに同期するコピーを使っていない'
        Assert-Condition ([IO.File]::ReadAllText((Join-Path $p.Data 'codeg.db')) -ceq 'old-db') 'DB の内容が戻らない'
    }
    Test-Case 'log と log.1 の再解析ポイントは追記もローテーションもしない' {
        foreach ($suffix in @('','.1')) {
            $p=New-TestFixture ('log-reparse-'+[Guid]::NewGuid().ToString('N').Substring(0,4)); $log=Join-Path $p.State 'codeg-auto-update.log'
            [IO.File]::WriteAllText($log,('x'*(1MB+1))); [IO.File]::WriteAllText(($log+'.1'),'previous')
            $script:fixture.UnsafeLog=$log+$suffix
            function Get-Item {
                [CmdletBinding()] param([string]$LiteralPath,[switch]$Force)
                if ($LiteralPath -eq $script:fixture.UnsafeLog) { return [pscustomobject]@{PSIsContainer=$false;Attributes=[IO.FileAttributes]::ReparsePoint;Length=10} }
                Microsoft.PowerShell.Management\Get-Item -LiteralPath $LiteralPath -Force:$Force -ErrorAction Stop
            }
            Assert-Throws { Initialize-CodegUpdateLog $p } '再解析ポイントのログを初期化した'
            $savedOut=[Console]::Out; $captured=New-Object IO.StringWriter
            try { [Console]::SetOut($captured); Write-CodegUpdateLog $p 'リンクへ書かない' } finally { [Console]::SetOut($savedOut) }
            Assert-Condition ($captured.ToString().Contains('警告:') -and (Get-Content -LiteralPath $log -Raw).Length -eq (1MB+1) -and [IO.File]::ReadAllText(($log+'.1')) -ceq 'previous') '不正なログを変更したか警告が無い'
        }
    }
    Test-Case 'ログを最初に開けなければ更新と復元を始めず 1' {
        $p=New-TestFixture 'log-init'; $backup=New-TestRestoreBackup $p; $log=Join-Path $p.State 'codeg-auto-update.log'; [IO.File]::WriteAllText($log,'fixture')
        $held=[IO.File]::Open($log,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        $savedOut=[Console]::Out; $captured=New-Object IO.StringWriter
        try {
            [Console]::SetOut($captured)
            Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq 1 -and (Invoke-CodegRestore $p ([IO.Path]::GetFileName($backup)) '0.2.0') -eq 1) 'ログを用意できずに処理した'
        } finally { [Console]::SetOut($savedOut); $held.Dispose() }
        Assert-Condition ($script:fixture.Stops -eq 0 -and $script:fixture.Starts -eq 0 -and $captured.ToString().Contains('ログを安全に用意できません')) '初期ログの失敗後に停止したか警告が無い'
    }
    Test-Case '開始後のログ追記失敗は更新済み 0 と巻き戻し済み 2 を変えない' {
        foreach ($rollback in @($false,$true)) {
            $p=New-TestFixture ('log-after-'+$rollback); $script:fixture.LockLogAfterStart=$true; $script:fixture.FailNew=$rollback
            $savedOut=[Console]::Out; $captured=New-Object IO.StringWriter
            try {
                [Console]::SetOut($captured)
                $expected=0; if ($rollback) { $expected=2 }
                Assert-Condition ((Invoke-CodegAutoUpdate $p) -eq $expected) 'ログの失敗で結果が変わった'
            } finally { [Console]::SetOut($savedOut); if ($script:fixture.LogLock) { $script:fixture.LogLock.Dispose() } }
            Assert-Condition ($captured.ToString().Contains('警告:')) 'ログの失敗を標準出力へ警告していない'
        }
    }
    Test-Case 'ログは UTF-8 で 2 世代' {
        $p=New-TestFixture 'log'; $log=Join-Path $p.State 'codeg-auto-update.log'; [IO.File]::WriteAllText($log,('x'*(1MB+1))); Write-CodegUpdateLog $p '日本語の記録'
        Assert-Condition (Test-Path -LiteralPath ($log+'.1')) 'ログを回していない'; Assert-Condition ([IO.File]::ReadAllText($log).Contains('日本語の記録')) 'UTF-8 の記録が無い'
    }
    Test-Case '版確認は --version のみ、使い捨て環境、10 秒で木を停止' {
        $p=New-TestFixture 'native-version'; $fake=Join-Path $caseRoot ('fv-'+[Guid]::NewGuid().ToString('N').Substring(0,8)+'.exe')
        $record=Join-Path $p.State 'arguments.txt'; $env:UPDATE_FIXTURE_CHILD_PID=Join-Path $p.State 'child.txt'; $env:UPDATE_FIXTURE_RECORD=$record; $env:UPDATE_FIXTURE_SLEEP=''; $env:CODEG_TOKEN='public-parent-fixture-only'
        $source=@'
using System;
using System.IO;
using System.Threading;
using System.Diagnostics;
public static class FixtureVersion {
    public static int Main(string[] args) {
        if(args.Length==1 && args[0]=="--fixture-child") { File.WriteAllText(Environment.GetEnvironmentVariable("UPDATE_FIXTURE_CHILD_PID"),Process.GetCurrentProcess().Id.ToString()); Thread.Sleep(60000); return 0; }
        string record = Environment.GetEnvironmentVariable("UPDATE_FIXTURE_RECORD");
        string[] keys = {"CODEG_DATA_DIR","CODEG_HOME","HOME","USERPROFILE","APPDATA","LOCALAPPDATA","TEMP","TMP","TMPDIR","XDG_CONFIG_HOME","XDG_DATA_HOME","XDG_STATE_HOME","XDG_CACHE_HOME","XDG_RUNTIME_DIR","CODEG_HOST","CODEG_PORT","CODEG_TOKEN","CODEG_BRIDGE_PORTS","CODEG_BROWSER_TUNNEL"};
        using(var output = new StreamWriter(record)) { output.WriteLine(String.Join(" ",args)); foreach(var key in keys) output.WriteLine(key+"="+Environment.GetEnvironmentVariable(key)); }
        if(Environment.GetEnvironmentVariable("UPDATE_FIXTURE_SLEEP")=="yes") { Process.Start(Process.GetCurrentProcess().MainModule.FileName,"--fixture-child"); Thread.Sleep(60000); }
        Console.Error.WriteLine("public-error-that-must-be-discarded");
        Console.WriteLine("0.8.0"); return 0;
    }
}
'@
        Add-Type -TypeDefinition $source -OutputAssembly $fake -OutputType ConsoleApplication
        try {
            Assert-Condition ((& $realVersion $fake $caseRoot) -eq '0.8.0') '偽本体の版を取れない'
            $savedInputEncoding=[Console]::InputEncoding
            try {
                foreach ($setting in @(@('UTF-8 BOM 有り',(New-Object Text.UTF8Encoding($true))),@('UTF-8 BOM 無し',(New-Object Text.UTF8Encoding($false))),@('cp932',[Text.Encoding]::GetEncoding(932)))) {
                    try {
                        [Console]::InputEncoding=$setting[1]
                        $actualEncoding=[Console]::InputEncoding
                        if ($actualEncoding.CodePage -ne $setting[1].CodePage -or $actualEncoding.GetPreamble().Length -ne $setting[1].GetPreamble().Length) { throw '指定した入力形式へ切り替わっていません。' }
                    } catch { Write-Host ('スキップ: InputEncoding '+$setting[0]+' を指定した BOM とコードページへ切り替えられません。'); continue }
                    Assert-Condition ((& $realVersion $fake $caseRoot) -eq '0.8.0') ('InputEncoding '+$setting[0]+' で版確認が失敗した')
                    $script:passed++; Write-Host ('成功: InputEncoding '+$setting[0]+' でも BOM に依らず版を確認する')
                }
            } finally { [Console]::InputEncoding=$savedInputEncoding }
            $lines=[IO.File]::ReadAllLines($record); Assert-Condition ($lines[0] -ceq '--version') '--version 以外の引数を渡した'
            foreach ($line in $lines|Select-Object -Skip 1 -First 14) { Assert-Condition ($line.Split('=',2)[1].StartsWith($caseRoot+'\version-')) '使い捨て環境ではない' }
            Assert-Condition (($lines -contains 'CODEG_HOST=127.0.0.1') -and ($lines -contains 'CODEG_BRIDGE_PORTS=off') -and ($lines -contains 'CODEG_BROWSER_TUNNEL=off')) '接続の設定が安全ではない'
            Assert-Condition (-not ($lines -contains 'CODEG_TOKEN=public-parent-fixture-only')) '親のトークンを引き継いだ'
            $env:UPDATE_FIXTURE_SLEEP='yes'; $timeoutFailed=$false; try { & $realVersion $fake $caseRoot | Out-Null } catch { $timeoutFailed=$true; Write-Host ('時間切れ確認: '+$_.Exception.Message) }; Assert-Condition $timeoutFailed '時間切れを無視した'
            Assert-Condition (Test-Path -LiteralPath $env:UPDATE_FIXTURE_CHILD_PID) '偽の子プロセスが始まっていない'
            Assert-Condition (@(Get-Process -Name ([IO.Path]::GetFileNameWithoutExtension($fake)) -ErrorAction SilentlyContinue).Count -eq 0) '時間切れの偽本体が残った'
        } finally { foreach ($leftover in @(Get-Process -Name ([IO.Path]::GetFileNameWithoutExtension($fake)) -ErrorAction SilentlyContinue)) { if ($leftover.Path -ieq $fake) { $leftover.Kill(); $leftover.WaitForExit() } }; Remove-Item Env:UPDATE_FIXTURE_RECORD,Env:UPDATE_FIXTURE_SLEEP,Env:UPDATE_FIXTURE_CHILD_PID,Env:CODEG_TOKEN -ErrorAction SilentlyContinue }
    }
    Write-Host ('全 '+$script:passed+' 件が成功しました。')
} finally {
    # caseRoot はこのテストが作った、スクリプト直下の一意なパスだけ。
    $resolved=[IO.Path]::GetFullPath($caseRoot)
    if (-not $resolved.StartsWith([IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')+'\aut-',[StringComparison]::OrdinalIgnoreCase)) { throw '一時フォルダーの削除先が不正です。' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
