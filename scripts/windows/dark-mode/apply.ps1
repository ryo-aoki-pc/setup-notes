$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\_lib\SetupItem.psm1') -Force -ErrorAction Stop
$item = Get-SetupItem -Directory $PSScriptRoot
$result = @{ State = 'failed'; Current = [ordered]@{}; Desired = [ordered]@{} }

try {
    $result = & (Join-Path $PSScriptRoot 'check.ps1') -PassThru
    if ($result.State -eq 'change-needed') {
        foreach ($name in $result.Current.Keys) { Write-SetupLine -Kind '今' -Text ('{0} = {1}' -f $name, (Format-SetupValue $result.Current[$name])) }
        foreach ($name in $result.Desired.Keys) { Write-SetupLine -Kind '変える' -Text ('{0} = {1}' -f $name, (Format-SetupValue $result.Desired[$name])) }
        $before = $result.Current
        $result.Keep = $before
        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        Set-ItemProperty -Path $path -Name 'AppsUseLightTheme' -Type DWord -Value 0 -ErrorAction Stop
        Set-ItemProperty -Path $path -Name 'SystemUsesLightTheme' -Type DWord -Value 0 -ErrorAction Stop
        $result = & (Join-Path $PSScriptRoot 'check.ps1') -PassThru
        $result.Keep = $before
        if ($result.State -eq 'confirmed') {
            $result.Changed = [ordered]@{}
            $result.Unchanged = [ordered]@{}
            foreach ($name in $result.Desired.Keys) {
                if ($before[$name] -ne (Format-SetupValue $result.Current[$name])) { $result.Changed[$name] = $result.Current[$name] } else { $result.Unchanged[$name] = $result.Current[$name] }
            }
        } else {
            $result.State = 'failed'
            $result.Message = '変更した後の読み戻しが一致しない'
        }
    } elseif ($result.State -eq 'confirmed') { $result.Unchanged = $result.Current }
} catch {
    $failureMessage = $_.Exception.Message
    # 途中で失敗した場合も、読み取れる今の値を残す
    try {
        $readback = & (Join-Path $PSScriptRoot 'check.ps1') -PassThru
        $result.Current = $readback.Current
    } catch { }
    $result.State = 'failed'
    $result.Message = $failureMessage
}
exit (Complete-SetupItem -Item $item @result)
