param([switch]$PassThru)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\_lib\SetupItem.psm1') -Force -ErrorAction Stop
$item = Get-SetupItem -Directory $PSScriptRoot
$result = @{ State = 'failed'; Current = [ordered]@{}; Desired = [ordered]@{} }

try {
    $build = [int](Get-SetupRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentBuildNumber')
    $sudo = Join-Path $env:SystemRoot 'System32\sudo.exe'
    $enabled = Get-SetupRegistryValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo' -Name 'Enabled'
    $result.Current = [ordered]@{ Build = $build; SudoPath = $sudo; Enabled = $enabled }
    $result.Desired = [ordered]@{ Enabled = 3 }
    if ($build -lt 26100 -or -not (Test-Path -LiteralPath $sudo)) {
        $result.State = 'not-applicable'
        $result.Message = 'Windows 11 24H2 以降の sudo.exe が必要'
    } else { $result.State = if ($enabled -eq 3) { 'confirmed' } else { 'change-needed' } }

} catch {
    $result.State = 'failed'
    $result.Message = $_.Exception.Message
}
# apply からは、同じ読み取りと判定の結果だけを返す
if ($PassThru) { return $result }
exit (Complete-SetupItem -Item $item @result)
