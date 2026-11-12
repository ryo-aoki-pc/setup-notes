param([switch]$PassThru)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\_lib\SetupItem.psm1') -Force -ErrorAction Stop
$item = Get-SetupItem -Directory $PSScriptRoot
$result = @{ State = 'failed'; Current = [ordered]@{}; Desired = [ordered]@{} }

try {
    $result.Current['AllowDevelopmentWithoutDevLicense'] = Get-SetupRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name 'AllowDevelopmentWithoutDevLicense'
    $result.Desired = [ordered]@{ AllowDevelopmentWithoutDevLicense = 1 }
    $result.State = if (($result.Current['AllowDevelopmentWithoutDevLicense'] -eq 1)) { 'confirmed' } else { 'change-needed' }

} catch {
    $result.State = 'failed'
    $result.Message = $_.Exception.Message
}
# apply からは、同じ読み取りと判定の結果だけを返す
if ($PassThru) { return $result }
exit (Complete-SetupItem -Item $item @result)
