#requires -Version 5.1
[CmdletBinding()]
param([switch]$CheckOnly)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-CodegPassword {
    param([string]$Value)
    return ($Value.Length -ge 32 -and $Value.Length -le 512 -and $Value -cmatch '\A[\x21-\x7e]+\z')
}

function Set-PrivateFileAcl {
    param([string]$Path)
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
    $existing = [IO.File]::GetAccessControl($Path, [Security.AccessControl.AccessControlSections]::Owner)
    if ($existing.GetOwner([Security.Principal.SecurityIdentifier]).Value -ne $sid.Value) {
        throw '自分が所有していないファイルの権限は変更しません。'
    }
    $acl = New-Object Security.AccessControl.FileSecurity
    $acl.SetAccessRuleProtection($true, $false)
    $rule = New-Object Security.AccessControl.FileSystemAccessRule($sid, 'Modify', 'Allow')
    $acl.AddAccessRule($rule)
    [IO.File]::SetAccessControl($Path, $acl)
}

function Get-CodegHealth {
    param([string]$Credential)
    $request = [Net.HttpWebRequest]::Create('http://127.0.0.1:3080/api/health')
    $request.Proxy = $null
    $request.Method = 'POST'
    $request.ContentType = 'application/json'
    $request.Timeout = 3000
    $request.AllowAutoRedirect = $false
    if ($Credential) { $request.Headers['Authorization'] = 'Bearer ' + $Credential }
    $bytes = [Text.Encoding]::UTF8.GetBytes('{}')
    $request.ContentLength = $bytes.Length
    $stream = $null
    $response = $null
    try {
        $stream = $request.GetRequestStream()
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Dispose()
        $stream = $null
        $response = $request.GetResponse()
        $reader = New-Object IO.StreamReader($response.GetResponseStream())
        try { $body = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
        return [pscustomobject]@{ StatusCode = [int]$response.StatusCode; Healthy = ($body.status -eq 'ok') }
    } catch [Net.WebException] {
        if ($_.Exception.Response) {
            $response = $_.Exception.Response
            return [pscustomobject]@{ StatusCode = [int]$response.StatusCode; Healthy = $false }
        }
        return [pscustomobject]@{ StatusCode = 0; Healthy = $false }
    } finally {
        if ($stream) { $stream.Dispose() }
        if ($response) { $response.Dispose() }
    }
}

function Assert-CodegPrerequisites {
    param([string]$ServerDir)
    foreach ($name in @('codeg-server.exe', 'start-codeg-server.ps1', 'token.txt')) {
        if (-not (Test-Path -LiteralPath (Join-Path $ServerDir $name) -PathType Leaf)) {
            throw 'Codeg の既存構成が見つかりません。'
        }
    }
    $task = Get-ScheduledTask -TaskName 'codeg-server'
    if ($task.State -ne 'Running') { throw 'codeg-server タスクが稼働していません。' }
    $expectedLauncher = Join-Path $ServerDir 'codeg-hidden-launcher.exe'
    $actions = @($task.Actions)
    if ($actions.Count -ne 1 -or $actions[0].Execute -ine $expectedLauncher -or
        $actions[0].Arguments -ine ('"' + (Join-Path $ServerDir 'start-codeg-server.ps1') + '"')) {
        throw 'タスクの起動先が手順書の専用構成と異なります。'
    }
    $minimum = @(Select-String -LiteralPath (Join-Path $ServerDir 'start-codeg-server.ps1') -Pattern '^\s*if \(\$token\.Length -lt 32\)')
    if ($minimum.Count -ne 1) { throw '起動スクリプトの文字数条件が手順書と異なります。' }
    $tokenAcl = Get-Acl -LiteralPath (Join-Path $ServerDir 'token.txt')
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
    if (-not $tokenAcl.AreAccessRulesProtected -or $tokenAcl.GetOwner([Security.Principal.SecurityIdentifier]).Value -ne $sid.Value) {
        throw '認証ファイルの所有者または継承設定を先に確認してください。'
    }
    $rules = @($tokenAcl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]))
    if ($rules.Count -eq 0 -or @($rules | Where-Object { $_.IdentityReference.Value -ne $sid.Value }).Count -ne 0) {
        throw '認証ファイルが自分だけの権限ではありません。'
    }
    $listeners = @(Get-NetTCPConnection -LocalPort 3080 -State Listen -ErrorAction SilentlyContinue)
    if ($listeners.Count -ne 1 -or $listeners[0].LocalAddress -ne '127.0.0.1') {
        throw 'Codeg の待ち受けが手順書の構成と異なります。'
    }
    $server = Get-Process -Id $listeners[0].OwningProcess
    if ($server.Path -ine (Join-Path $ServerDir 'codeg-server.exe')) {
        throw '3080 番を待ち受けるプロセスが Codeg の専用実行ファイルではありません。'
    }
    $snapshot = [pscustomobject]@{ ProcessId = $server.Id; StartTime = $server.StartTime; ExecutablePath = $server.Path }
    if ((Get-VerifiedCodegHealth -ServerDir $ServerDir -ExpectedIdentity $snapshot -AllowExisting).StatusCode -ne 401) { throw '未認証の要求が拒否されていません。' }
    return $snapshot
}

function Stop-CodegService {
    param($Snapshot)
    $current = Get-Process -Id $Snapshot.ProcessId -ErrorAction SilentlyContinue
    if (-not $current -or $current.Path -ine $Snapshot.ExecutablePath -or $current.StartTime -ne $Snapshot.StartTime) {
        throw '確認後に Codeg のプロセスが変わりました。最初からやり直してください。'
    }
    $listeners = @(Get-NetTCPConnection -LocalPort 3080 -State Listen -ErrorAction SilentlyContinue)
    if ($listeners.Count -gt 1 -or ($listeners.Count -eq 1 -and $listeners[0].OwningProcess -ne $Snapshot.ProcessId)) {
        throw '待ち受けの所有者が変わったため、停止しません。'
    }
    Stop-Process -Id $Snapshot.ProcessId
    $current.WaitForExit(10000) | Out-Null
    if (@(Get-NetTCPConnection -LocalPort 3080 -State Listen -ErrorAction SilentlyContinue).Count -ne 0) {
        throw '3080 番が解放されていません。'
    }
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    do {
        if ((Get-ScheduledTask -TaskName 'codeg-server').State -eq 'Ready') { return }
        Start-Sleep -Milliseconds 200
    } while ([DateTime]::UtcNow -lt $deadline)
    throw '旧タスクの自然終了を確認できません。'
}

function Start-CodegService {
    if ((Get-ScheduledTask -TaskName 'codeg-server').State -ne 'Ready') { throw '旧タスクが終了していません。' }
    $script:CodegLaunchNotBefore = [DateTime]::UtcNow
    Start-ScheduledTask -TaskName 'codeg-server'
}

function Test-CodegIdentity {
    param($Actual, $Expected)
    return ($Actual -and $Expected -and $Actual.ProcessId -eq $Expected.ProcessId -and
        $Actual.StartTime -eq $Expected.StartTime -and $Actual.ExecutablePath -ieq $Expected.ExecutablePath)
}

function Get-VerifiedCodegListener {
    param([string]$ServerDir, [switch]$AllowExisting)
    $listeners = @(Get-NetTCPConnection -LocalPort 3080 -State Listen -ErrorAction SilentlyContinue)
    if ($listeners.Count -eq 0) { return $null }
    if ($listeners.Count -ne 1 -or $listeners[0].LocalAddress -ne '127.0.0.1') { throw '待ち受けが専用構成と異なります。' }
    $process = Get-Process -Id $listeners[0].OwningProcess
    if ($process.Path -ine (Join-Path $ServerDir 'codeg-server.exe') -or
        (-not $AllowExisting -and $process.StartTime.ToUniversalTime() -lt $script:CodegLaunchNotBefore) -or
        (Get-ScheduledTask -TaskName 'codeg-server').State -ne 'Running') {
        throw '専用タスクから起動した Codeg を確認できません。パスワードは送信しません。'
    }
    $metadata = Get-CimInstance Win32_Process -Filter ('ProcessId={0}' -f $process.Id)
    $parent = Get-Process -Id $metadata.ParentProcessId
    $parentMetadata = Get-CimInstance Win32_Process -Filter ('ProcessId={0}' -f $parent.Id)
    $launcher = Get-Process -Id $parentMetadata.ParentProcessId
    if ($parent.Path -ine (Join-Path ([Environment]::GetFolderPath('System')) 'WindowsPowerShell\v1.0\powershell.exe') -or
        $launcher.Path -ine (Join-Path $ServerDir 'codeg-hidden-launcher.exe')) {
        throw '専用ランチャーから起動した Codeg ではありません。パスワードは送信しません。'
    }
    return [pscustomobject]@{ProcessId=$process.Id;StartTime=$process.StartTime;ExecutablePath=$process.Path}
}

function Get-VerifiedCodegHealth {
    param([string]$Credential, [string]$ServerDir, $ExpectedIdentity, [switch]$AllowExisting)
    $before = Get-VerifiedCodegListener -ServerDir $ServerDir -AllowExisting:$AllowExisting
    if (-not (Test-CodegIdentity -Actual $before -Expected $ExpectedIdentity)) { throw '接続確認前に Codeg が変わりました。' }
    $health = Get-CodegHealth -Credential $Credential
    $after = Get-VerifiedCodegListener -ServerDir $ServerDir -AllowExisting:$AllowExisting
    if (-not (Test-CodegIdentity -Actual $after -Expected $ExpectedIdentity)) { throw '接続確認中に Codeg が変わりました。' }
    return [pscustomobject]@{StatusCode=$health.StatusCode;Healthy=$health.Healthy;Identity=$before}
}

function Wait-CodegHealth {
    param([string]$Credential, [string]$ServerDir, [switch]$ExpectRejected, $ExpectedIdentity, [switch]$AllowExisting)
    $deadline = [DateTime]::UtcNow.AddSeconds(60)
    do {
        $identity = Get-VerifiedCodegListener -ServerDir $ServerDir -AllowExisting:$AllowExisting
        if ($identity) {
            if (-not $ExpectedIdentity) { $ExpectedIdentity = $identity }
            $health = Get-VerifiedCodegHealth -Credential $Credential -ServerDir $ServerDir -ExpectedIdentity $ExpectedIdentity -AllowExisting:$AllowExisting
            if ($ExpectRejected -and $health.StatusCode -eq 401) { return $health }
            if (-not $ExpectRejected -and $health.StatusCode -eq 200 -and $health.Healthy) { return $health }
        }
        Start-Sleep -Milliseconds 500
    } while ([DateTime]::UtcNow -lt $deadline)
    throw 'Codeg の接続確認を完了できません。'
}

function New-CodegPasswordResult {
    param([string]$FailureStage, [switch]$UnknownFileState)
    return [pscustomobject]@{
        StartedAtUtc=[DateTime]::UtcNow.ToString('o'); Outcome='failed'; FailureStage=$FailureStage
        CredentialReplaced=$(if ($UnknownFileState) { $null } else { $false })
        FileUnchanged=$(if ($UnknownFileState) { $null } else { $true })
        NewPasswordHealth=$null; AnonymousHealth=$null; WrongPasswordHealth=$null
        BackupFile=$null; Restored=$false; FileRestored=$false; ServiceRestored=$false
        OldPasswordVerified=$false; CleanupFailed=$false; CleanupFile=$null
    }
}

function Get-CodegInputFailureResult {
    param([string]$Password, [string]$Confirmation)
    if (-not [string]::Equals($Password,$Confirmation,[StringComparison]::Ordinal)) {
        return New-CodegPasswordResult -FailureStage '入力不一致'
    }
    if (-not (Test-CodegPassword $Password)) { return New-CodegPasswordResult -FailureStage '入力条件' }
    return $null
}

function Format-CodegPasswordResult {
    param($Result)
    $backup='<なし>'; $cleanup='<なし>'
    if ($Result.BackupFile) { $backup=$Result.BackupFile }
    if ($Result.CleanupFile) { $cleanup=$Result.CleanupFile }
    return ('今回の結果: StartedAtUtc={0}; Outcome={1}; FailureStage={2}; CredentialReplaced={3}; FileUnchanged={4}; FileRestored={5}; ServiceRestored={6}; OldPasswordVerified={7}; BackupFile={8}; CleanupFailed={9}; CleanupFile={10}' -f
        $Result.StartedAtUtc,$Result.Outcome,$Result.FailureStage,$Result.CredentialReplaced,$Result.FileUnchanged,
        $Result.FileRestored,$Result.ServiceRestored,$Result.OldPasswordVerified,$backup,$Result.CleanupFailed,$cleanup)
}

function Write-CodegPasswordResult {
    param($Result,[string]$ResultFile)
    $saved=$false
    try {
        $Result | Select-Object StartedAtUtc,Outcome,FailureStage,CredentialReplaced,FileUnchanged,
            NewPasswordHealth,AnonymousHealth,WrongPasswordHealth,BackupFile,Restored,FileRestored,
            ServiceRestored,OldPasswordVerified,CleanupFailed,CleanupFile |
            ConvertTo-Json | Set-Content -LiteralPath $ResultFile -Encoding UTF8
        $saved=$true
    } catch { Write-Host '今回の結果 JSON を保存できませんでした。次の表示を復旧の判断に使ってください。' }
    Write-Host (Format-CodegPasswordResult -Result $Result)
    return $saved
}

function Invoke-CodegPasswordChange {
    param([string]$ServerDir,[string]$Password,$Snapshot)
    if (-not (Test-CodegPassword $Password)) { throw 'パスワードの条件を満たしていません。' }
    $tokenFile=Join-Path $ServerDir 'token.txt'
    $stamp=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')+'-'+[Guid]::NewGuid().ToString('N').Substring(0,8)
    $pending=Join-Path $ServerDir ('token.pending-'+$stamp+'.txt')
    $backup=Join-Path $ServerDir ('token.before-password-'+$stamp+'.txt')
    $replaced=$false; $stopRequested=$false; $stage='準備'; $result=$null
    try {
        New-Item -ItemType File -Path $pending -ErrorAction Stop | Out-Null
        Set-PrivateFileAcl -Path $pending
        [IO.File]::WriteAllText($pending,$Password,(New-Object Text.UTF8Encoding($false)))
        $stage='停止'; $stopRequested=$true
        Stop-CodegService -Snapshot $Snapshot
        $stage='認証ファイルの置き換え'
        [IO.File]::Replace($pending,$tokenFile,$backup)
        $replaced=$true
        Set-PrivateFileAcl -Path $tokenFile
        Set-PrivateFileAcl -Path $backup
        $stage='起動'
        Start-CodegService
        $stage='接続確認'
        $newHealth=Wait-CodegHealth -Credential $Password -ServerDir $ServerDir
        $anonymous=Get-VerifiedCodegHealth -ServerDir $ServerDir -ExpectedIdentity $newHealth.Identity
        $wrong=Get-VerifiedCodegHealth -Credential ([Guid]::NewGuid().ToString('N')+[Guid]::NewGuid().ToString('N')) -ServerDir $ServerDir -ExpectedIdentity $newHealth.Identity
        if ($anonymous.StatusCode -ne 401 -or $wrong.StatusCode -ne 401) { throw '未認証または誤ったパスワードの拒否を確認できません。' }
        $result=New-CodegPasswordResult
        $result.Outcome='success'; $result.CredentialReplaced=$true; $result.FileUnchanged=$false
        $result.NewPasswordHealth=$newHealth.StatusCode; $result.AnonymousHealth=$anonymous.StatusCode; $result.WrongPasswordHealth=$wrong.StatusCode
        $result.BackupFile=[IO.Path]::GetFileName($backup)
        return $result
    } catch {
        $fileRestored=$false; $serviceRestored=$false
        if ($replaced) {
            try {
                $owned=@(Get-Process -Name 'codeg-server' -ErrorAction SilentlyContinue | Where-Object { $_.Path -ieq (Join-Path $ServerDir 'codeg-server.exe') })
                if ($owned.Count -eq 1) {
                    $running=$owned[0]
                    Stop-CodegService -Snapshot ([pscustomobject]@{ProcessId=$running.Id;StartTime=$running.StartTime;ExecutablePath=$running.Path})
                } elseif ($owned.Count -ne 0) { throw '復元時の専用プロセスを一意に確認できません。' }
                if ((Get-ScheduledTask -TaskName 'codeg-server').State -ne 'Ready' -or
                    @(Get-NetTCPConnection -LocalPort 3080 -State Listen -ErrorAction SilentlyContinue).Count -ne 0) {
                    throw '復元前に専用タスクの終了と 3080 番の解放を確認できません。'
                }
                [IO.File]::Copy($backup,$tokenFile,$true)
                Set-PrivateFileAcl -Path $tokenFile
                $fileRestored=$true
                Start-CodegService
                $rejected=Wait-CodegHealth -Credential $Password -ServerDir $ServerDir -ExpectRejected
                $anonymous=Get-VerifiedCodegHealth -ServerDir $ServerDir -ExpectedIdentity $rejected.Identity
                $serviceRestored=($rejected.StatusCode -eq 401 -and $anonymous.StatusCode -eq 401)
            } catch { $serviceRestored=$false }
        } elseif ($stopRequested) {
            try {
                if ((Get-ScheduledTask -TaskName 'codeg-server').State -eq 'Ready') {
                    Start-CodegService
                    $anonymous=Wait-CodegHealth -ServerDir $ServerDir -ExpectRejected
                } else {
                    $anonymous=Get-VerifiedCodegHealth -ServerDir $ServerDir -ExpectedIdentity $Snapshot -AllowExisting
                }
                $serviceRestored=($anonymous.StatusCode -eq 401)
            } catch { $serviceRestored=$false }
        }
        $result=New-CodegPasswordResult -FailureStage $stage
        $result.CredentialReplaced=$replaced; $result.FileUnchanged=-not $replaced
        $result.BackupFile=$(if ($replaced) { [IO.Path]::GetFileName($backup) } else { $null })
        $result.FileRestored=$fileRestored; $result.ServiceRestored=$serviceRestored
        $result.Restored=(($result.FileUnchanged -or $fileRestored) -and $serviceRestored)
        return $result
    } finally {
        try { if (Test-Path -LiteralPath $pending -PathType Leaf) { Remove-Item -LiteralPath $pending -Force } }
        catch { if ($result) { $result.CleanupFailed=$true; $result.CleanupFile=[IO.Path]::GetFileName($pending) } }
    }
}

$resultFile=Join-Path $PSScriptRoot 'password-change-result.json'
$serverDir=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'codeg-server'
$first=$null; $second=$null; $password=$null; $confirmation=$null; $result=$null
$operationStarted=$false; $entryStage='前提確認'; $runStarted=[DateTime]::UtcNow.ToString('o')
try {
    $snapshot=Assert-CodegPrerequisites -ServerDir $serverDir
    if ($CheckOnly) {
        Write-Host '前提確認 PASS（秘密の値は読んでいません。変更はありません。）'
        exit 0
    }
    $entryStage='入力'
    Write-Host 'Codeg の共通パスワードを設定します。旧認証では入れなくなり、ブラウザの再ログインが必要です。'
    Write-Host '空白を含まない ASCII 文字で32〜512文字を指定してください。値は表示・引数・ログに出しません。'
    $first=Read-Host -AsSecureString '新しい共通パスワード'
    $second=Read-Host -AsSecureString '確認のため、もう一度'
    $password=(New-Object Management.Automation.PSCredential('codeg',$first)).GetNetworkCredential().Password
    $confirmation=(New-Object Management.Automation.PSCredential('codeg',$second)).GetNetworkCredential().Password
    $result=Get-CodegInputFailureResult -Password $password -Confirmation $confirmation
    if ($result) { throw '入力を完了できませんでした。変更していません。' }
    $entryStage='変更処理'; $operationStarted=$true
    $result=Invoke-CodegPasswordChange -ServerDir $serverDir -Password $password -Snapshot $snapshot
    $result.StartedAtUtc=$runStarted
    [void](Write-CodegPasswordResult -Result $result -ResultFile $resultFile)
    if ($result.CleanupFailed) { Write-Host ('一時ファイルの後始末が必要です: {0}' -f $result.CleanupFile) }
    if ($result.Outcome -ne 'success') {
        Write-Host '変更は完了していません。未変更・ファイル復元・サービス復元を今回の結果で確認してください。旧パスワードでのログインは未確認です。'
        exit 1
    }
    Write-Host '変更完了: 新しいパスワードの接続確認200、未認証401、誤ったパスワード401。'
    Write-Host ('元の認証ファイルの控え: {0}' -f $result.BackupFile)
    Write-Host 'いつもの HTTPS URL をブラウザで開き、標準のトークン欄に今回のパスワードを入力してください。'
    Write-Host '画面の「トークン」という表記と内部の Bearer 認証方式は変わりません。'
} catch {
    if ($CheckOnly) {
        Write-Host '前提確認 FAIL（変更はありません。結果ファイルも保存していません。）'
        exit 1
    }
    if (-not $result) { $result=New-CodegPasswordResult -FailureStage $entryStage -UnknownFileState:$operationStarted }
    $result.StartedAtUtc=$runStarted
    [void](Write-CodegPasswordResult -Result $result -ResultFile $resultFile)
    if (-not $operationStarted) { Write-Host '前提確認または入力を完了できませんでした。認証ファイルとサービスは変更していません。' }
    else { Write-Host '変更処理の結果を確認してください。秘密の値や例外の詳細は出力していません。' }
    exit 1
} finally {
    if ($first) { $first.Dispose() }
    if ($second) { $second.Dispose() }
    Remove-Variable password,confirmation -ErrorAction SilentlyContinue
}
