param([switch]$PassThru)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\_lib\SetupItem.psm1') -Force -ErrorAction Stop
$item = Get-SetupItem -Directory $PSScriptRoot
$result = @{ State = 'failed'; Current = [ordered]@{}; Desired = [ordered]@{} }

try {
    $result.Current['AppsUseLightTheme'] = Get-SetupRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme'
    $result.Current['SystemUsesLightTheme'] = Get-SetupRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'SystemUsesLightTheme'
    $result.Desired = [ordered]@{ AppsUseLightTheme = 0; SystemUsesLightTheme = 0 }
    $result.State = if (($result.Current['AppsUseLightTheme'] -eq 0) -and ($result.Current['SystemUsesLightTheme'] -eq 0)) { 'confirmed' } else { 'change-needed' }

} catch {
    $result.State = 'failed'
    $result.Message = $_.Exception.Message
}
# apply からは、同じ読み取りと判定の結果だけを返す
if ($PassThru) { return $result }
exit (Complete-SetupItem -Item $item @result)
