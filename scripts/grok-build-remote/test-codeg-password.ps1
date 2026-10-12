#requires -Version 5.1
# Run: powershell.exe -NoProfile -File .\test-codeg-password.ps1
# Real files and ACLs use public fixtures. Process, task and HTTP operations are mocked.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'Run this test in Windows PowerShell 5.1.' }
$helper = Join-Path $PSScriptRoot 'set-codeg-password.ps1'
$tokens = $null
$errors = $null
$tree = [Management.Automation.Language.Parser]::ParseFile($helper, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'The helper has syntax errors.' }
# Import only the required functions, never the interactive script body.
foreach ($name in @('Test-CodegPassword', 'Set-PrivateFileAcl', 'Test-CodegIdentity', 'Get-VerifiedCodegHealth', 'Wait-CodegHealth', 'New-CodegPasswordResult', 'Get-CodegInputFailureResult', 'Format-CodegPasswordResult', 'Write-CodegPasswordResult', 'Invoke-CodegPasswordChange')) {
    $definitions = @($tree.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $name }, $false))
    if ($definitions.Count -ne 1) { throw ('Missing or ambiguous helper function: ' + $name) }
    . ([scriptblock]::Create($definitions[0].Extent.Text))
}
# These strings are public test data, not production credentials.
$oldValue = 'Public-Test-Old-Value-Only-12345678'
$newValue = 'Public-Test-New-Value-Only-87654321'
$caseRoot = Join-Path $PSScriptRoot ('password-tests-' + [Guid]::NewGuid().ToString('N'))
$script:fixture = $null
$script:pendingLock = $null

function Assert-Condition {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}
function Assert-PrivateAcl {
    param([string]$Path)
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $acl = Get-Acl -LiteralPath $Path
    $rules = @($acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]))
    Assert-Condition ($acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -eq $sid) 'Fixture owner changed.'
    Assert-Condition $acl.AreAccessRulesProtected 'Fixture ACL still inherits permissions.'
    Assert-Condition ($rules.Count -eq 1) 'Fixture ACL has unexpected rules.'
    $rule = $rules[0]
    Assert-Condition ($rule.IdentityReference.Value -eq $sid -and -not $rule.IsInherited -and
        $rule.AccessControlType -eq [Security.AccessControl.AccessControlType]::Allow) 'Fixture ACL is not an explicit owner allow rule.'
    $required = [int][Security.AccessControl.FileSystemRights]::Modify
    $allowed = $required -bor [int][Security.AccessControl.FileSystemRights]::Synchronize
    $actual = [int]$rule.FileSystemRights
    Assert-Condition (($actual -band $required) -eq $required -and ($actual -band (-bnot $allowed)) -eq 0) 'Fixture ACL does not grant only Modify rights.'
}
function New-FixtureCase {
    param([string]$Name)
    $dir = Join-Path $caseRoot $Name
    New-Item -ItemType Directory -Path $dir | Out-Null
    $tokenFile = Join-Path $dir 'token.txt'
    [IO.File]::WriteAllText($tokenFile, $oldValue)
    Set-PrivateFileAcl -Path $tokenFile
    $script:fixture = @{
        ServerDir = $dir; Running = $true; StopCount = 0; StartCount = 0
        FailStop = $false; FailStartOnce = $false; FailNewHealth = $false
        FailRestoreHealth = $false; LockPendingOnStop = $false
        LoadedCredential = $oldValue; LastHealthKind = ''; ProbeAfterHealth = 0
        ChangeDuringKind = ''; ChangeBetweenAfterKind = ''; IdentityChanged = $false
        ServiceDisappearsOnNewHealthFailure = $false; ForcedTaskState = ''; PortOccupied = $false
        Process = [pscustomobject]@{ Id = 700001; StartTime = [DateTime]'2026-01-01T00:00:00Z'; Path = (Join-Path $dir 'codeg-server.exe') }
    }
    return $dir
}
function Get-FixtureSnapshot {
    return [pscustomobject]@{ ProcessId = $script:fixture.Process.Id; StartTime = $script:fixture.Process.StartTime; ExecutablePath = $script:fixture.Process.Path }
}
# These mocked dependencies change fixture state only.
function Stop-CodegService {
    param($Snapshot)
    Assert-Condition ($Snapshot.ProcessId -eq $script:fixture.Process.Id -and
        $Snapshot.StartTime -eq $script:fixture.Process.StartTime -and
        $Snapshot.ExecutablePath -ceq $script:fixture.Process.Path) 'Unexpected fixture process selected.'
    $script:fixture.StopCount++
    if ($script:fixture.LockPendingOnStop) {
        $pending = @(Get-ChildItem -LiteralPath $script:fixture.ServerDir -Filter 'token.pending-*')
        Assert-Condition ($pending.Count -eq 1) 'Pending fixture is missing.'
        Assert-PrivateAcl -Path $pending[0].FullName
        $script:pendingLock = [IO.File]::Open($pending[0].FullName, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::None)
    }
    if ($script:fixture.FailStop) { throw 'Simulated stop failure.' }
    $script:fixture.Running = $false
}
function Start-CodegService {
    $script:fixture.StartCount++
    if ($script:fixture.FailStartOnce -and $script:fixture.StartCount -eq 1) { throw 'Simulated start request failure.' }
    $script:fixture.Running = $true
    $script:fixture.LoadedCredential = [IO.File]::ReadAllText((Join-Path $script:fixture.ServerDir 'token.txt'))
    $script:fixture.LastHealthKind = ''
    $script:fixture.ProbeAfterHealth = 0
    $script:fixture.Process = [pscustomobject]@{
        Id = 700001 + $script:fixture.StartCount
        StartTime = ([DateTime]'2026-01-01T00:00:00Z').AddSeconds($script:fixture.StartCount)
        Path = (Join-Path $script:fixture.ServerDir 'codeg-server.exe')
    }
}
function Change-FixtureIdentity {
    $script:fixture.IdentityChanged=$true
    $script:fixture.Process=[pscustomobject]@{
        Id=$script:fixture.Process.Id+1000
        StartTime=$script:fixture.Process.StartTime.AddSeconds(1000)
        Path=$script:fixture.Process.Path
    }
}
function Get-VerifiedCodegListener {
    param([string]$ServerDir,[switch]$AllowExisting)
    Assert-Condition ($ServerDir -ceq $script:fixture.ServerDir) 'Unexpected fixture listener target.'
    if (-not $script:fixture.Running) { return $null }
    if ($script:fixture.LastHealthKind) {
        $script:fixture.ProbeAfterHealth++
        if (-not $script:fixture.IdentityChanged -and $script:fixture.ProbeAfterHealth -eq 2 -and
            $script:fixture.ChangeBetweenAfterKind -eq $script:fixture.LastHealthKind) { Change-FixtureIdentity }
    }
    return Get-FixtureSnapshot
}
function Get-CodegHealth {
    param([string]$Credential)
    Assert-Condition $script:fixture.Running 'HTTP was called without a fixture service.'
    $kind='wrong'
    if (-not $Credential) { $kind='anonymous' }
    elseif ($Credential -ceq $newValue) {
        $kind='new'
        if ($script:fixture.LoadedCredential -ceq $oldValue) { $kind='newRejected' }
    }
    $script:fixture.LastHealthKind=$kind
    $script:fixture.ProbeAfterHealth=0
    if (-not $script:fixture.IdentityChanged -and $script:fixture.ChangeDuringKind -eq $kind) { Change-FixtureIdentity }
    if ($kind -eq 'new' -and $script:fixture.FailNewHealth) {
        if ($script:fixture.ServiceDisappearsOnNewHealthFailure) { $script:fixture.Running=$false }
        throw 'Simulated new service health failure.'
    }
    if ($script:fixture.LoadedCredential -ceq $oldValue -and $script:fixture.FailRestoreHealth) { throw 'Simulated restored service verification failure.' }
    if ($Credential -and $Credential -ceq $script:fixture.LoadedCredential) {
        return [pscustomobject]@{StatusCode=200;Healthy=$true}
    }
    return [pscustomobject]@{StatusCode=401;Healthy=$false}
}
function Get-Process {
    [CmdletBinding()]
    param([string]$Name, [int]$Id)
    if (-not $script:fixture.Running) { return }
    if ($Name -eq 'codeg-server' -or $Id -eq $script:fixture.Process.Id) { return $script:fixture.Process }
    throw 'Unexpected process lookup in fixture.'
}
function Get-ScheduledTask {
    param([string]$TaskName)
    Assert-Condition ($TaskName -eq 'codeg-server') 'Unexpected task lookup in fixture.'
    $state = 'Ready'
    if ($script:fixture.Running) { $state = 'Running' }
    if ($script:fixture.ForcedTaskState) { $state=$script:fixture.ForcedTaskState }
    return [pscustomobject]@{ State = $state }
}
function Get-NetTCPConnection {
    [CmdletBinding()]
    param($LocalPort,$State)
    Assert-Condition ($LocalPort -eq 3080 -and $State -eq 'Listen') 'Unexpected fixture port lookup.'
    if ($script:fixture.PortOccupied) { return [pscustomobject]@{LocalAddress='127.0.0.1';LocalPort=3080;OwningProcess=799999} }
    if ($script:fixture.Running) { return [pscustomobject]@{LocalAddress='127.0.0.1';LocalPort=3080;OwningProcess=$script:fixture.Process.Id} }
}

function Assert-FixtureFiles {
    param([string]$ServerDir, $Result, [string]$ExpectedValue, [bool]$HasBackup)
    $tokenFile = Join-Path $ServerDir 'token.txt'
    Assert-Condition ([IO.File]::ReadAllText($tokenFile) -ceq $ExpectedValue) 'Fixture token content is incorrect.'
    Assert-PrivateAcl -Path $tokenFile
    if ($HasBackup) {
        Assert-Condition (-not [string]::IsNullOrEmpty($Result.BackupFile)) 'Fixture backup was not reported.'
        $backupFile = Join-Path $ServerDir $Result.BackupFile
        Assert-Condition ([IO.File]::ReadAllText($backupFile) -ceq $oldValue) 'Original fixture backup changed.'
        Assert-PrivateAcl -Path $backupFile
    } else {
        Assert-Condition (@(Get-ChildItem -LiteralPath $ServerDir -Filter 'token.before-*').Count -eq 0) 'Backup was made before replacement succeeded.'
    }
    Assert-Condition (@(Get-ChildItem -LiteralPath $ServerDir -Filter 'token.pending-*').Count -eq 0) 'Pending fixture remained.'
}

New-Item -ItemType Directory -Path $caseRoot | Out-Null
try {
    foreach ($length in @(32, 512)) { Assert-Condition (Test-CodegPassword ('x' * $length)) ('Valid length rejected: ' + $length) }
    foreach ($value in @('', ('x' * 31), ('x' * 513), (('x' * 31) + ' '), (' ' + ('x' * 31)),
        (('x' * 31) + [char]9), (('x' * 31) + [char]10), (('x' * 31) + [char]13),
        (('x' * 31) + [char]13 + [char]10), (('x' * 31) + [char]0x7f), (('x' * 31) + [char]0x3042))) {
        Assert-Condition (-not (Test-CodegPassword $value)) 'Invalid password boundary was accepted.'
    }
    Assert-Condition (Test-CodegPassword (('x' * 30) + '!~')) 'Printable ASCII endpoints were rejected.'
    Write-Host 'PASS: password boundaries, ASCII and whitespace rejection'

    $dir = New-FixtureCase 'success'
    $result = Invoke-CodegPasswordChange -ServerDir $dir -Password $newValue -Snapshot (Get-FixtureSnapshot)
    Assert-Condition ($result.Outcome -eq 'success' -and $result.CredentialReplaced -and -not $result.FileUnchanged -and $result.NewPasswordHealth -eq 200 -and
        $result.AnonymousHealth -eq 401 -and $result.WrongPasswordHealth -eq 401) 'Success verification failed.'
    Assert-Condition ($script:fixture.StopCount -eq 1 -and $script:fixture.StartCount -eq 1 -and -not $result.CleanupFailed) 'Success service transitions failed.'
    Assert-FixtureFiles -ServerDir $dir -Result $result -ExpectedValue $newValue -HasBackup $true
    Write-Host 'PASS: real replacement, preserved backup and private owner ACLs'

    foreach ($name in @('new-health-failure', 'start-request-failure')) {
        $dir = New-FixtureCase $name
        if ($name -eq 'new-health-failure') { $script:fixture.FailNewHealth = $true } else { $script:fixture.FailStartOnce = $true }
        $result = Invoke-CodegPasswordChange -ServerDir $dir -Password $newValue -Snapshot (Get-FixtureSnapshot)
        Assert-Condition ($result.Outcome -eq 'failed' -and $result.CredentialReplaced -and -not $result.FileUnchanged -and $result.Restored -and $result.FileRestored -and
            $result.ServiceRestored -and -not $result.OldPasswordVerified) 'Rollback result was incorrect.'
        Assert-Condition ($script:fixture.StartCount -eq 2) 'Restored service was not started.'
        Assert-FixtureFiles -ServerDir $dir -Result $result -ExpectedValue $oldValue -HasBackup $true
        Write-Host ('PASS: rollback after ' + $name)
    }

    $dir = New-FixtureCase 'restore-verification-failure'
    $script:fixture.FailNewHealth = $true
    $script:fixture.FailRestoreHealth = $true
    $result = Invoke-CodegPasswordChange -ServerDir $dir -Password $newValue -Snapshot (Get-FixtureSnapshot)
    Assert-Condition ($result.Outcome -eq 'failed' -and $result.FileRestored -and -not $result.ServiceRestored -and
        -not $result.Restored -and -not $result.OldPasswordVerified) 'Unverified restoration was reported as successful.'
    Assert-FixtureFiles -ServerDir $dir -Result $result -ExpectedValue $oldValue -HasBackup $true
    Write-Host 'PASS: restored file and unverified service are reported separately'

    $dir = New-FixtureCase 'stop-failure'
    $script:fixture.FailStop = $true
    $result = Invoke-CodegPasswordChange -ServerDir $dir -Password $newValue -Snapshot (Get-FixtureSnapshot)
    Assert-Condition ($result.Outcome -eq 'failed' -and $result.FailureStage -eq '停止' -and
        $script:fixture.StartCount -eq 0 -and $script:fixture.StopCount -eq 1) 'Stop failure was ignored.'
    Assert-FixtureFiles -ServerDir $dir -Result $result -ExpectedValue $oldValue -HasBackup $false
    Write-Host 'PASS: stop failure leaves the original file unchanged'

    $dir = New-FixtureCase 'replace-failure'
    $lock = [IO.File]::Open((Join-Path $dir 'token.txt'), [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try { $result = Invoke-CodegPasswordChange -ServerDir $dir -Password $newValue -Snapshot (Get-FixtureSnapshot) } finally { $lock.Dispose() }
    Assert-Condition ($result.Outcome -eq 'failed' -and $result.FailureStage -eq '認証ファイルの置き換え' -and $result.Restored) 'Real replacement failure was not recovered.'
    Assert-FixtureFiles -ServerDir $dir -Result $result -ExpectedValue $oldValue -HasBackup $false
    Write-Host 'PASS: locked destination prevents replacement and preserves the original'

    $dir = New-FixtureCase 'invalid-input'
    $rejected = $false
    try { [void](Invoke-CodegPasswordChange -ServerDir $dir -Password ('x' * 31) -Snapshot (Get-FixtureSnapshot)) } catch { $rejected = $true }
    Assert-Condition ($rejected -and $script:fixture.StopCount -eq 0 -and $script:fixture.StartCount -eq 0) 'Invalid input reached service operations.'
    Assert-FixtureFiles -ServerDir $dir -Result $null -ExpectedValue $oldValue -HasBackup $false
    Write-Host 'PASS: invalid input is rejected before file or service changes'

    $dir = New-FixtureCase 'cleanup-failure'
    $script:fixture.FailStop = $true
    $script:fixture.LockPendingOnStop = $true
    try { $result = Invoke-CodegPasswordChange -ServerDir $dir -Password $newValue -Snapshot (Get-FixtureSnapshot) } finally { $script:pendingLock.Dispose(); $script:pendingLock = $null }
    Assert-Condition ($result.Outcome -eq 'failed' -and $result.FailureStage -eq '停止' -and $result.CleanupFailed -and
        -not [string]::IsNullOrEmpty($result.CleanupFile)) 'Cleanup failure hid the primary result.'
    Remove-Item -LiteralPath (Join-Path $dir $result.CleanupFile) -Force
    Assert-FixtureFiles -ServerDir $dir -Result $result -ExpectedValue $oldValue -HasBackup $false
    Write-Host 'PASS: cleanup failure preserves the primary result and names the pending fixture'
    $dir = New-FixtureCase 'unchanged-service-return-failure'
    $script:fixture.FailStop=$true
    $script:fixture.FailRestoreHealth=$true
    $result=Invoke-CodegPasswordChange -ServerDir $dir -Password $newValue -Snapshot (Get-FixtureSnapshot)
    Assert-Condition ($result.Outcome -eq 'failed' -and -not $result.CredentialReplaced -and $result.FileUnchanged -and
        -not $result.FileRestored -and -not $result.ServiceRestored -and -not $result.Restored -and $null -eq $result.BackupFile) 'Unchanged file state was lost after service return failure.'
    Assert-FixtureFiles -ServerDir $dir -Result $result -ExpectedValue $oldValue -HasBackup $false
    Write-Host 'PASS: unchanged file and failed service return are reported independently'

    foreach ($mode in @('during-anonymous','during-wrong','between-new-and-anonymous','between-anonymous-and-wrong')) {
        $dir=New-FixtureCase $mode
        switch ($mode) {
            'during-anonymous' { $script:fixture.ChangeDuringKind='anonymous' }
            'during-wrong' { $script:fixture.ChangeDuringKind='wrong' }
            'between-new-and-anonymous' { $script:fixture.ChangeBetweenAfterKind='new' }
            'between-anonymous-and-wrong' { $script:fixture.ChangeBetweenAfterKind='anonymous' }
        }
        $result=Invoke-CodegPasswordChange -ServerDir $dir -Password $newValue -Snapshot (Get-FixtureSnapshot)
        Assert-Condition ($script:fixture.IdentityChanged -and $result.Outcome -eq 'failed' -and $result.FailureStage -eq '接続確認') 'Identity replacement was accepted as success.'
        Assert-FixtureFiles -ServerDir $dir -Result $result -ExpectedValue $oldValue -HasBackup $true
        Write-Host ('PASS: identity replacement rejected: '+$mode)
    }

    $dir=New-FixtureCase 'rollback-identity-between-checks'
    $script:fixture.FailNewHealth=$true
    $script:fixture.ChangeBetweenAfterKind='newRejected'
    $result=Invoke-CodegPasswordChange -ServerDir $dir -Password $newValue -Snapshot (Get-FixtureSnapshot)
    Assert-Condition ($script:fixture.IdentityChanged -and $result.FileRestored -and -not $result.ServiceRestored -and -not $result.Restored) 'Rollback accepted identity replacement between its checks.'
    Assert-FixtureFiles -ServerDir $dir -Result $result -ExpectedValue $oldValue -HasBackup $true
    Write-Host 'PASS: rollback keeps expected identity through rejected and anonymous checks'

    $dir=New-FixtureCase 'old-service-identity-during-check'
    $script:fixture.FailStop=$true
    $script:fixture.ChangeDuringKind='anonymous'
    $result=Invoke-CodegPasswordChange -ServerDir $dir -Password $newValue -Snapshot (Get-FixtureSnapshot)
    Assert-Condition ($script:fixture.IdentityChanged -and $result.FileUnchanged -and -not $result.ServiceRestored) 'Old-service HTTP identity replacement was accepted.'
    Assert-FixtureFiles -ServerDir $dir -Result $result -ExpectedValue $oldValue -HasBackup $false
    Write-Host 'PASS: unchanged old service also requires HTTP identity checks'

    $dir=New-FixtureCase 'input-result'
    $resultFile=Join-Path $dir 'fixture-result.json'
    $stale=New-CodegPasswordResult
    $stale.Outcome='success'; $stale.StartedAtUtc='2026-01-01T00:00:00Z'
    [void](Write-CodegPasswordResult -Result $stale -ResultFile $resultFile)
    foreach ($mode in @('mismatch','invalid','prerequisite')) {
        if ($mode -eq 'mismatch') { $result=Get-CodegInputFailureResult -Password $newValue -Confirmation $oldValue }
        elseif ($mode -eq 'invalid') { $result=Get-CodegInputFailureResult -Password ('x'*31) -Confirmation ('x'*31) }
        else { $result=New-CodegPasswordResult -FailureStage '前提確認' }
        Assert-Condition ($result.Outcome -eq 'failed' -and $result.FileUnchanged -and -not $result.CredentialReplaced -and -not $result.FileRestored) 'Input or prerequisite failure did not report unchanged state.'
        $report=@(Write-CodegPasswordResult -Result $result -ResultFile $resultFile 6>&1)
        $record=[IO.File]::ReadAllText($resultFile) | ConvertFrom-Json
        Assert-Condition ($record.Outcome -eq 'failed' -and $record.StartedAtUtc -ne $stale.StartedAtUtc -and $record.FileUnchanged) 'Old result JSON was not replaced with the current failure.'
        $output=($report | ForEach-Object {[string]$_}) -join [Environment]::NewLine
        Assert-Condition (-not $output.Contains($newValue) -and -not $output.Contains($oldValue)) 'Input values leaked into the report.'
    }
    Write-Host 'PASS: input mismatch, invalid input and prerequisite failure replace stale fixture results'

    $result=New-CodegPasswordResult -FailureStage '接続確認'
    $result.CredentialReplaced=$true; $result.FileUnchanged=$false
    $result.BackupFile='token.before-password-public-fixture.txt'
    $result.CleanupFailed=$true; $result.CleanupFile='token.pending-public-fixture.txt'
    $result | Add-Member -NotePropertyName SensitiveValue -NotePropertyValue $newValue
    $report=@(Write-CodegPasswordResult -Result $result -ResultFile $dir 6>&1)
    $output=($report | ForEach-Object {[string]$_}) -join [Environment]::NewLine
    Assert-Condition ($report[-1] -eq $false -and $output.Contains($result.StartedAtUtc) -and $output.Contains($result.BackupFile) -and
        $output.Contains($result.CleanupFile) -and $output.Contains('接続確認') -and -not $output.Contains($newValue)) 'JSON save failure lost recovery metadata or leaked values.'
    [void](Write-CodegPasswordResult -Result $result -ResultFile $resultFile)
    Assert-Condition (-not [IO.File]::ReadAllText($resultFile).Contains('SensitiveValue')) 'Result JSON did not whitelist non-secret fields.'
    Assert-FixtureFiles -ServerDir $dir -Result $null -ExpectedValue $oldValue -HasBackup $false
    Write-Host 'PASS: JSON save failure preserves backup, stage, cleanup and current timestamp without values'

    $result=New-CodegPasswordResult -FailureStage '変更処理' -UnknownFileState
    $report=@(Write-CodegPasswordResult -Result $result -ResultFile $dir 6>&1)
    $output=($report | ForEach-Object {[string]$_}) -join [Environment]::NewLine
    Assert-Condition ($report[-1] -eq $false -and $output.Contains('CredentialReplaced=null; FileUnchanged=null;') -and
        -not $output.Contains($oldValue) -and -not $output.Contains($newValue)) 'Unknown file state was ambiguous in the console after JSON save failure.'
    [void](Write-CodegPasswordResult -Result $result -ResultFile $resultFile)
    $record=[IO.File]::ReadAllText($resultFile) | ConvertFrom-Json
    Assert-Condition ($null -eq $record.CredentialReplaced -and $null -eq $record.FileUnchanged) 'Unknown file state was lost in JSON.'
    Write-Host 'PASS: unknown file state is explicit null in console fallback and JSON'

    foreach ($mode in @('rollback-task-still-running','rollback-port-occupied')) {
        $dir=New-FixtureCase $mode
        $script:fixture.FailNewHealth=$true
        $script:fixture.ServiceDisappearsOnNewHealthFailure=$true
        if ($mode -eq 'rollback-task-still-running') { $script:fixture.ForcedTaskState='Running' }
        else { $script:fixture.PortOccupied=$true }
        $result=Invoke-CodegPasswordChange -ServerDir $dir -Password $newValue -Snapshot (Get-FixtureSnapshot)
        Assert-Condition ($result.Outcome -eq 'failed' -and $result.CredentialReplaced -and -not $result.FileUnchanged -and
            -not $result.FileRestored -and -not $result.ServiceRestored -and -not $result.Restored) 'Rollback copied a file before the task and port were clear.'
        Assert-FixtureFiles -ServerDir $dir -Result $result -ExpectedValue $newValue -HasBackup $true
        Write-Host ('PASS: rollback copy is blocked: '+$mode)
    }

    Write-Host 'Fixture integration checks PASS (no production credentials, services or HTTP).'
} finally {
    if ($script:pendingLock) { $script:pendingLock.Dispose() }
    if (Test-Path -LiteralPath $caseRoot) {
        # Check the exact newly-created path before recursive deletion.
        $resolved = (Resolve-Path -LiteralPath $caseRoot).ProviderPath
        $expected = [IO.Path]::GetFullPath($caseRoot)
        $parentPrefix = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\') + '\'
        if ($resolved -ine $expected -or -not $expected.StartsWith($parentPrefix, [StringComparison]::OrdinalIgnoreCase) -or
            [IO.Path]::GetFileName($expected) -notmatch '\Apassword-tests-[0-9a-f]{32}\z') {
            throw 'Refusing fixture cleanup outside the expected test directory.'
        }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
