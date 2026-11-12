$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\_lib\SetupItem.psm1') -Force -ErrorAction Stop
$item = Get-SetupItem -Directory $PSScriptRoot
$result = @{ State = 'failed'; Current = [ordered]@{}; Desired = [ordered]@{} }

try {
    # 開くのは設定アプリの画面だけにする
    if ([string]$item.open -notmatch '^ms-settings:[A-Za-z0-9-]+$') { throw 'open は ms-settings: の URI にする' }
    Start-Process -FilePath $item.open -ErrorAction Stop | Out-Null
    $result.State = 'manual-pending'
    $result.Desired = [ordered]@{ 'Ctrl+Space' = 'IME-オン/オフ' }
    $result.Message = 'キーとタッチのカスタマイズで割り当て、画面とキー操作で確かめる'
} catch {
    $result.State = 'failed'
    $result.Message = $_.Exception.Message
}
exit (Complete-SetupItem -Item $item @result)
