param([AllowEmptyString()][string]$PcName = '')

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\_lib\SetupItem.psm1') -Force -ErrorAction Stop
$item = Get-SetupItem -Directory $PSScriptRoot
$result = @{ State = 'failed'; Current = [ordered]@{}; Desired = [ordered]@{} }

try {
    if (-not (Test-SetupInput -Item $item -Values @{ PcName = $PcName })) {
        $result.State = 'invalid-input'
        $result.Message = 'PcName を、この項の手順 2 の決まりに合わせて指定する'
    } else {
        $result = & (Join-Path $PSScriptRoot 'check.ps1') -PcName $PcName -PassThru
        if ($result.State -eq 'change-needed') {
            if (-not (Test-SetupAdministrator)) {
                $result.State = 'not-applicable'
                $result.Message = '管理者の PowerShell で実行する'
            } elseif ($result.Current.ComputerName -eq $PcName) {
                $result.State = 'not-applicable'
                $result.Message = '別の名前への変更が再起動待ち。再起動してからやり直す'
            } else {
                Write-SetupLine -Kind '今' -Text ('ComputerName = {0}; NextComputerName = {1}' -f (Format-SetupValue $result.Current.ComputerName), (Format-SetupValue $result.Current.NextComputerName))
                Write-SetupLine -Kind '変える' -Text ('ComputerName = {0}' -f $PcName)
                $before = $result.Current
                $result.Keep = $before
                Rename-Computer -NewName $PcName -ErrorAction Stop | Out-Null
                $result = & (Join-Path $PSScriptRoot 'check.ps1') -PcName $PcName -PassThru
                $result.Keep = $before
                if ($result.State -in 'reboot-pending', 'confirmed') { $result.Changed = [ordered]@{ NextComputerName = $result.Current.NextComputerName } } else {
                    $result.State = 'failed'
                    $result.Message = '名前を変更した後の読み戻しが一致しない'
                }
            }
        } elseif ($result.State -in 'confirmed', 'reboot-pending') { $result.Unchanged = $result.Current }
    }
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
