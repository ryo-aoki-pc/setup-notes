param([switch]$PassThru)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\_lib\SetupItem.psm1') -Force -ErrorAction Stop
$item = Get-SetupItem -Directory $PSScriptRoot
$result = @{ State = 'failed'; Current = [ordered]@{}; Desired = [ordered]@{} }

try {
    if ($PSVersionTable.PSVersion.Major -ne 5 -or $Host.Name -ne 'ConsoleHost') {
        $result.State = 'not-applicable'
        $result.Message = 'Windows PowerShell 5.1 のコンソールで実行する'
    } else {
        # 一時的な Process の許可に隠されず、次の窓で使うポリシーを読む
        $policy = 'Restricted'
        $policies = [ordered]@{}
        foreach ($scope in 'MachinePolicy', 'UserPolicy', 'CurrentUser', 'LocalMachine') { $policies[$scope] = [string](Get-ExecutionPolicy -Scope $scope) }
        foreach ($scope in $policies.Keys) {
            if ($policies[$scope] -ne 'Undefined') { $policy = $policies[$scope]; break }
        }
        $profilePath = [string]$PROFILE.CurrentUserCurrentHost
        $line = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-setup.md'
        $text = if (Test-Path -LiteralPath $profilePath) { Get-Content -LiteralPath $profilePath -Raw -ErrorAction Stop } else { '' }
        $hasLine = [bool]($text -and $text.Contains($line))
        $result.Current = [ordered]@{ ExecutionPolicy = $policy; CurrentUser = $policies['CurrentUser']; Profile = $profilePath; PasteLine = $hasLine }
        $result.Desired = [ordered]@{ ExecutionPolicy = 'RemoteSigned（Unrestricted・Bypass も可）'; PasteLine = $line }
        if (($policy -in 'RemoteSigned', 'Unrestricted', 'Bypass') -and $hasLine) { $result.State = 'confirmed' } elseif (
            $policies['MachinePolicy'] -notin 'Undefined', 'RemoteSigned', 'Unrestricted', 'Bypass' -or
            ($policies['MachinePolicy'] -eq 'Undefined' -and $policies['UserPolicy'] -notin 'Undefined', 'RemoteSigned', 'Unrestricted', 'Bypass')) {
            $result.State = 'not-applicable'
            $result.Message = 'グループ ポリシーでスクリプトが制限されている。ほかの手順書は Ctrl+V で貼る'
        } else { $result.State = 'change-needed' }
    }

} catch {
    $result.State = 'failed'
    $result.Message = $_.Exception.Message
}
# apply からは、同じ読み取りと判定の結果だけを返す
if ($PassThru) { return $result }
exit (Complete-SetupItem -Item $item @result)
