$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\_lib\SetupItem.psm1') -Force -ErrorAction Stop
$item = Get-SetupItem -Directory $PSScriptRoot
$result = @{ State = 'failed'; Current = [ordered]@{}; Desired = [ordered]@{} }

try {
    $result = & (Join-Path $PSScriptRoot 'check.ps1') -PassThru
    if ($result.State -eq 'change-needed') {
        $before = $result.Current
        Write-SetupLine -Kind '今' -Text ('ExecutionPolicy = {0}; PasteLine = {1}' -f (Format-SetupValue $before.ExecutionPolicy), (Format-SetupValue $before.PasteLine))
        Write-SetupLine -Kind '変える' -Text '必要なら CurrentUser を RemoteSigned にし、印付きの貼り付けの行を足す'
        $result.Keep = $before
        if ($before.ExecutionPolicy -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
            try { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop } catch {
                # Process の一時的な許可で上書きされる通知だけは読み戻しで確かめる
                if ($_.FullyQualifiedErrorId -notlike 'ExecutionPolicyOverride,*') { throw }
                if ((Get-ExecutionPolicy -Scope CurrentUser) -ne 'RemoteSigned') { throw }
            }
        }
        $profilePath = $before.Profile
        $line = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-setup.md'
        if (-not (Test-Path -LiteralPath $profilePath)) { New-Item -ItemType File -Path $profilePath -Force -ErrorAction Stop | Out-Null }
        $text = Get-Content -LiteralPath $profilePath -Raw -ErrorAction Stop
        if (-not ($text -and $text.Contains($line))) {
            if ($text -and -not $text.EndsWith("`n")) { $line = "`r`n" + $line }
            Add-Content -LiteralPath $profilePath -Value $line -ErrorAction Stop
        }
        $result = & (Join-Path $PSScriptRoot 'check.ps1') -PassThru
        $result.Keep = $before
        if ($result.State -eq 'confirmed') {
            $result.Changed = [ordered]@{}
            $result.Unchanged = [ordered]@{}
            foreach ($name in $result.Current.Keys) {
                if ($before[$name] -ne (Format-SetupValue $result.Current[$name])) { $result.Changed[$name] = $result.Current[$name] } else { $result.Unchanged[$name] = $result.Current[$name] }
            }
        } else {
            $result.State = 'failed'
            $result.Message = '実行ポリシーとプロファイルの読み戻しが一致しない'
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
