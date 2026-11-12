# Windows PowerShell 5.1 と PowerShell 7 に共通の入出力を扱う
function Get-SetupItem {
    param([Parameter(Mandatory = $true)][string]$Directory)
    Get-Content -LiteralPath (Join-Path $Directory 'item.json') -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
}

function Write-SetupLine {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('今', '変える', '変えた', 'そのまま', '控える', '状態', '中断')][string]$Kind,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Text
    )
    # 値に改行があっても表示の接頭辞を保つ
    foreach ($line in ($Text -split '\r?\n')) { Write-Host ('{0}: {1}' -f $Kind, $line) }
}

function Format-SetupValue {
    param([AllowNull()]$Value)
    # 値が無いことを「未設定」と表示する
    if ($null -eq $Value) { '未設定' } elseif ($Value -is [string]) { $Value } else { ConvertTo-Json -InputObject $Value -Compress -Depth 12 }
}

function Test-SetupInput {
    param(
        [Parameter(Mandatory = $true)]$Item,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Values,
        [switch]$AllowMissing
    )
    foreach ($inputSpec in $Item.inputs) {
        $value = $Values[$inputSpec.name]
        if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string]$value)) {
            if ($inputSpec.required -and -not $AllowMissing) {
                Write-SetupLine -Kind '中断' -Text ('{0} が空。名前付きの引数で指定する' -f $inputSpec.name)
                return $false
            }
            continue
        }
        if (($inputSpec.pattern -and [string]$value -cnotmatch $inputSpec.pattern) -or
            ($inputSpec.notPattern -and [string]$value -cmatch $inputSpec.notPattern)) {
            Write-SetupLine -Kind '中断' -Text ('{0} の形式が違う。item.json の入力の決まりを確かめる' -f $inputSpec.name)
            return $false
        }
    }
    return $true
}

function Test-SetupAdministrator {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-SetupRegistryValue {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)][string]$Name)
    if (Test-Path -LiteralPath $Path -ErrorAction Stop) {
        $key = Get-Item -LiteralPath $Path -ErrorAction Stop
        # 値が無い場合と、読み取りに失敗した場合を区別する
        $key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    }
}

function Complete-SetupItem {
    param(
        [Parameter(Mandatory = $true)]$Item,
        [Parameter(Mandatory = $true)][ValidateSet('confirmed', 'change-needed', 'reboot-pending', 'manual-pending', 'not-applicable', 'current-only', 'failed', 'invalid-input')][string]$State,
        $Current = [ordered]@{},
        $Desired = [ordered]@{},
        $Changed = [ordered]@{},
        $Unchanged = [ordered]@{},
        $Keep = [ordered]@{},
        [string]$Message = ''
    )
    $states = @{
        'confirmed' = @(0, '確認済み')
        'change-needed' = @(10, '変更が要る')
        'reboot-pending' = @(11, '再起動待ち')
        'manual-pending' = @(12, '手作業待ち')
        'not-applicable' = @(13, '前提が足りない・対象外')
        'current-only' = @(14, '今の値だけ（比べる値が無い）')
        'failed' = @(1, '失敗')
        'invalid-input' = @(2, '引数の誤り')
    }
    $result = [ordered]@{
        schemaVersion = 1
        id = $Item.id
        state = $State
        exitCode = [int]$states[$State][0]
        current = $Current
        desired = $Desired
        changed = $Changed
        unchanged = $Unchanged
        keep = $Keep
        message = $Message
    }
    if ($env:SETUP_ITEM_RESULT) {
        try {
            # 呼び出し元が用意した絶対パスだけに結果を書く
            if ($env:SETUP_ITEM_RESULT -notmatch '^(?:[A-Za-z]:[\\/]|\\\\[^\\]+\\[^\\]+\\)') { throw 'SETUP_ITEM_RESULT は絶対パスにする' }
            $resultPath = [IO.Path]::GetFullPath($env:SETUP_ITEM_RESULT)
            $scriptsRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..')).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
            if ($resultPath.StartsWith($scriptsRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'scripts の中に結果は書けない' }
            [IO.File]::WriteAllText($resultPath, (($result | ConvertTo-Json -Depth 16) + "`n"), (New-Object Text.UTF8Encoding($false)))
        } catch {
            $result.state = 'failed'
            $result.exitCode = 1
            $result.message = '結果の JSON を書けなかった: ' + $_.Exception.Message
        }
    }
    # apply が変える前に出した「今:」「変える:」を、終わりに重ねて出さない（JSON には残す）
    $skip = @()
    if (($Changed -and $Changed.Count -gt 0) -or ($Unchanged -and $Unchanged.Count -gt 0)) { $skip = @('current', 'desired') }
    foreach ($pair in @(@('今', 'current'), @('変える', 'desired'), @('変えた', 'changed'), @('そのまま', 'unchanged'), @('控える', 'keep'))) {
        if ($skip -contains $pair[1]) { continue }
        $values = $result[$pair[1]]
        if ($null -eq $values) { continue }
        foreach ($key in $values.Keys) {
            $value = $values[$key]
            Write-SetupLine -Kind $pair[0] -Text ('{0} = {1}' -f $key, (Format-SetupValue $value))
        }
    }
    if (($result.state -in 'failed', 'invalid-input', 'not-applicable') -and $result.message) { Write-SetupLine -Kind '中断' -Text $result.message }
    $label = $states[$result.state][1]
    if ($result.message) { $label += '（' + $result.message + '）' }
    Write-SetupLine -Kind '状態' -Text $label
    return [int]$result.exitCode
}

Export-ModuleMember -Function Get-SetupItem, Format-SetupValue, Test-SetupInput, Write-SetupLine, Complete-SetupItem, Test-SetupAdministrator, Get-SetupRegistryValue
