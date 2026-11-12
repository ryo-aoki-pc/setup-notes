param([AllowEmptyString()][string]$PcName = '', [switch]$PassThru)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\_lib\SetupItem.psm1') -Force -ErrorAction Stop
$item = Get-SetupItem -Directory $PSScriptRoot
$result = @{ State = 'failed'; Current = [ordered]@{}; Desired = [ordered]@{} }

try {
    $active = Get-SetupRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' -Name 'ComputerName'
    $pending = Get-SetupRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' -Name 'ComputerName'
    if (-not $active -or -not $pending) { throw 'PC の名前を読み取れなかった' }
    $result.Current = [ordered]@{ ComputerName = $active; NextComputerName = $pending }
    if (-not (Test-SetupInput -Item $item -Values @{ PcName = $PcName } -AllowMissing)) {
        $result.State = 'invalid-input'
        $result.Message = 'PcName の形式を確かめる'
    } elseif ([string]::IsNullOrWhiteSpace($PcName)) {
        $result.State = 'current-only'
    } else {
        $result.Desired = [ordered]@{ ComputerName = $PcName }
        if ($active -eq $PcName -and $pending -eq $PcName) { $result.State = 'confirmed' } elseif ($pending -eq $PcName) {
            $result.State = 'reboot-pending'
        } else { $result.State = 'change-needed' }
    }

} catch {
    $result.State = 'failed'
    $result.Message = $_.Exception.Message
}
# apply からは、同じ読み取りと判定の結果だけを返す
if ($PassThru) { return $result }
exit (Complete-SetupItem -Item $item @result)
