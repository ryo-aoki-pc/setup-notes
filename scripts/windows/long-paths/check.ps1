param([switch]$PassThru)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\_lib\SetupItem.psm1') -Force -ErrorAction Stop
$item = Get-SetupItem -Directory $PSScriptRoot
$result = @{ State = 'failed'; Current = [ordered]@{}; Desired = [ordered]@{} }

try {
    $result.Current['LongPathsEnabled'] = Get-SetupRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled'
    $result.Desired = [ordered]@{ LongPathsEnabled = 1 }
    $result.State = if (($result.Current['LongPathsEnabled'] -eq 1)) { 'confirmed' } else { 'change-needed' }

} catch {
    $result.State = 'failed'
    $result.Message = $_.Exception.Message
}
# apply からは、同じ読み取りと判定の結果だけを返す
if ($PassThru) { return $result }
exit (Complete-SetupItem -Item $item @result)
