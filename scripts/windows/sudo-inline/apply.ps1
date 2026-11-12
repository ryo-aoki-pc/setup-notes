$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\_lib\SetupItem.psm1') -Force -ErrorAction Stop
$item = Get-SetupItem -Directory $PSScriptRoot
$result = @{ State = 'failed'; Current = [ordered]@{}; Desired = [ordered]@{} }

try {
    $result = & (Join-Path $PSScriptRoot 'check.ps1') -PassThru
    if ($result.State -eq 'change-needed') {
        if (-not (Test-SetupAdministrator)) {
            $result.State = 'not-applicable'
            $result.Message = '管理者の PowerShell で実行する'
        } else {
            Write-SetupLine -Kind '今' -Text ('Enabled = {0}' -f (Format-SetupValue $result.Current.Enabled))
            Write-SetupLine -Kind '変える' -Text 'Enabled = 3（インラインの sudo）'
            $before = $result.Current
            $result.Keep = $before
            & $result.Current.SudoPath config --enable normal | Out-Host
            if ($LASTEXITCODE -ne 0) { throw ('sudo config が失敗した（終了コード {0}）' -f $LASTEXITCODE) }
            $result = & (Join-Path $PSScriptRoot 'check.ps1') -PassThru
            $result.Keep = $before
            if ($result.State -eq 'confirmed') { $result.Changed = [ordered]@{ Enabled = $result.Current.Enabled } } else {
                $result.State = 'failed'
                $result.Message = 'sudo を設定した後の読み戻しが一致しない'
            }
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
