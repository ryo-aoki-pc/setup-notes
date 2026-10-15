#requires -Version 5.1
# Codeg の専用タスクを、毎日最新の安定版へ更新する。
# 終了: 0=最新/更新済み/停止中/手動復元済み、1=中断/保留、2=自動復元して保留、3=要手動復旧。
param([string]$Restore, [string]$Hold)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-CodegUpdatePaths {
    $state = Join-Path $env:LOCALAPPDATA 'codeg-auto-update'
    return [pscustomobject]@{
        Server = (Join-Path $env:LOCALAPPDATA 'codeg-server')
        Data = (Join-Path $env:APPDATA 'codeg'); State = $state
        Backups = (Join-Path $state 'backups'); Task = 'codeg-server'
    }
}
function Get-CodegUtcNow { return [DateTime]::UtcNow }
function Wait-CodegUpdate { param([int]$Milliseconds) Start-Sleep -Milliseconds $Milliseconds }
function Get-CodegMonotonicTime {
    return [Diagnostics.Stopwatch]::GetTimestamp() / [double][Diagnostics.Stopwatch]::Frequency
}
function Assert-CodegUpdateLogPaths {
    param($Paths)
    $state = Get-Item -LiteralPath $Paths.State -Force -ErrorAction Stop
    if (-not $state.PSIsContainer -or ($state.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'ログのフォルダーが通常のフォルダーではありません。' }
    $log = Join-Path $Paths.State 'codeg-auto-update.log'
    foreach ($file in @($log,($log+'.1'))) {
        $item = $null
        try { $item = Get-Item -LiteralPath $file -Force -ErrorAction Stop }
        catch { if ($_.CategoryInfo.Category -ne [Management.Automation.ErrorCategory]::ObjectNotFound) { throw } }
        if ($item -and ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint))) { throw 'ログまたは前のログが通常のファイルではありません。' }
    }
}
function Initialize-CodegUpdateLog {
    param($Paths)
    Assert-CodegUpdateLogPaths $Paths
    $stream = [IO.File]::Open((Join-Path $Paths.State 'codeg-auto-update.log'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    $stream.Dispose()
}
function Write-CodegUpdateLog {
    param($Paths, [string]$Message)
    try {
        Assert-CodegUpdateLogPaths $Paths
        $log = Join-Path $Paths.State 'codeg-auto-update.log'
        if ((Test-Path -LiteralPath $log) -and (Get-Item -LiteralPath $log).Length -gt 1MB) {
            $previous = $log + '.1'
            if (Test-Path -LiteralPath $previous) { Remove-Item -LiteralPath $previous -Force }
            Move-Item -LiteralPath $log -Destination $previous
        }
        $line = '{0} {1}{2}' -f (Get-CodegUtcNow).ToString('o'), ($Message -replace '[\r\n]+',' '), [Environment]::NewLine
        [IO.File]::AppendAllText($log, $line, (New-Object Text.UTF8Encoding($false)))
    } catch {
        # 処理を始めた後のログの失敗で、更新や復元の結果を上書きしない。
        try { [Console]::Out.WriteLine('警告: 自動更新のログへ記録できません。処理結果は変更しません。') } catch { }
    }
}
function Write-CodegUpdateState {
    param([string]$Path, [string]$Value)
    $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes($Value + [Environment]::NewLine)
    $stream = [IO.File]::Open($Path, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
}
function Write-CodegProgress {
    param([string]$Path, [string]$Stage, [string]$Backup, [string]$OldVersion, [string]$NewVersion)
    Write-CodegUpdateState $Path ([ordered]@{stage=$Stage; backup=$Backup; old=$OldVersion; new=$NewVersion} | ConvertTo-Json -Compress)
}
function Get-CodegProperty {
    param($Object, [string]$Name)
    if ($null -ne $Object -and $Object.PSObject.Properties[$Name]) { return $Object.$Name }
    return $null
}
function Invoke-CodegCurl {
    param([string[]]$Arguments)
    $output = & (Join-Path $env:WINDIR 'System32\curl.exe') @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) { throw '通信に失敗しました。' }
    return ($output | Out-String)
}
function Get-CodegReleases {
    param([string]$Work)
    if (-not $Work -or -not [IO.Directory]::Exists($Work)) { throw 'リリース情報の作業用フォルダーがありません。' }
    $jsonPath = Join-Path $Work ('releases-' + [Guid]::NewGuid().ToString('N') + '.json')
    try {
        # JSON の本文をコンソールのコードページで変換しない。
        Invoke-CodegCurl @('--fail','--silent','--show-error','--location','--connect-timeout','15','--max-time','120','--proto','=https','--proto-redir','=https','-H','Accept: application/vnd.github+json','-H','User-Agent: setup-notes-codeg-auto-update','--output',$jsonPath,'https://api.github.com/repos/spacering-net/codeg/releases?per_page=50') | Out-Null
        $json = [IO.File]::ReadAllText($jsonPath,[Text.Encoding]::UTF8)
        return ($json | ConvertFrom-Json)
    } finally {
        if (Test-Path -LiteralPath $jsonPath) { Remove-Item -LiteralPath $jsonPath -Force }
    }
}
function Select-CodegRelease {
    param([object[]]$Releases)
    $name = 'codeg-server-windows-x64.zip'
    $candidates = @(foreach ($release in $Releases) {
        $tag = [string](Get-CodegProperty $release 'tag_name')
        $draft = Get-CodegProperty $release 'draft'; $prerelease = Get-CodegProperty $release 'prerelease'
        if ($tag -cnotmatch '^v[0-9]+\.[0-9]+\.[0-9]+$' -or $draft -isnot [bool] -or $prerelease -isnot [bool] -or $draft -or $prerelease) { continue }
        $assets = @(Get-CodegProperty $release 'assets')
        $archive = @($assets | Where-Object { (Get-CodegProperty $_ 'name') -ceq $name })
        $checksum = @($assets | Where-Object { (Get-CodegProperty $_ 'name') -ceq ($name + '.sha256') })
        if ($archive.Count -ne 1 -or $checksum.Count -ne 1) { continue }
        [pscustomobject]@{ Version = $tag.Substring(1); Number = [version]$tag.Substring(1); Archive = $archive[0]; Checksum = $checksum[0] }
    })
    if (-not $candidates.Count) { throw '必要な配布物がそろった安定版がありません。' }
    return ($candidates | Sort-Object Number -Descending | Select-Object -First 1)
}
function Save-CodegDownload {
    param([string]$Url, [string]$Path)
    if (-not $Url.StartsWith('https://', [StringComparison]::OrdinalIgnoreCase)) { throw '配布物の URL が HTTPS ではありません。' }
    Invoke-CodegCurl @('--fail','--silent','--show-error','--location','--connect-timeout','15','--max-time','900','--proto','=https','--proto-redir','=https','--output',$Path,$Url) | Out-Null
}
function Test-CodegDownload {
    param($Paths, [string]$Archive, [string]$Checksum, $Release)
    $text = [IO.File]::ReadAllText($Checksum).Trim()
    if ($text -cnotmatch '^([0-9a-fA-F]{64})[ \t]+\*?codeg-server-windows-x64\.zip$') { throw 'SHA-256 のファイルの形式が不正です。' }
    $expected = $Matches[1].ToLowerInvariant()
    $actual = (Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($expected -cne $actual) { throw '配布物と SHA-256 が一致しません。' }
    $digest = [string](Get-CodegProperty $Release.Archive 'digest')
    if (-not $digest) { Write-CodegUpdateLog $Paths '配布元の digest が無いため、SHA-256 ファイルだけで照合しました。'; return }
    if ($digest -cnotmatch '^sha256:([0-9a-fA-F]{64})$' -or $Matches[1].ToLowerInvariant() -cne $actual) { throw '配布物と API の digest が一致しません。' }
}
function Expand-CodegArchive {
    param([string]$Archive, [string]$Destination)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $root = [IO.Path]::GetFullPath($Destination).TrimEnd('\') + '\'
    [IO.Directory]::CreateDirectory($root) | Out-Null
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        $seen = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName.Replace('\','/')
            $parts = $name.Split('/')
            $mode = (($entry.ExternalAttributes -shr 16) -band 0xF000)
            if ($name.StartsWith('/') -or $name -match '^[A-Za-z]:' -or $name.Contains(':') -or $parts -contains '..' -or $parts -contains '.' -or
                $parts[0] -cne 'codeg-server-windows-x64' -or ($parts.Length -eq 1) -or
                ($mode -ne 0 -and $mode -ne 0x8000 -and $mode -ne 0x4000) -or ($entry.ExternalAttributes -band 0x400)) {
                throw 'ZIP に安全でないパスまたはリンクがあります。'
            }
            $relative = ($parts | Select-Object -Skip 1) -join '\'
            if (-not $relative) { continue }
            $target = [IO.Path]::GetFullPath((Join-Path $root $relative))
            if (-not $target.StartsWith($root,[StringComparison]::OrdinalIgnoreCase) -or -not $seen.Add($target.TrimEnd('\'))) { throw 'ZIP の展開先が不正または重複しています。' }
            if ($name.EndsWith('/')) { [IO.Directory]::CreateDirectory($target) | Out-Null; continue }
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
            $source = $entry.Open()
            $dest = [IO.File]::Open($target,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
            try { $source.CopyTo($dest); $dest.Flush($true) } finally { $dest.Dispose(); $source.Dispose() }
        }
    } finally { $zip.Dispose() }
    foreach ($name in @('codeg-server.exe','codeg-mcp.exe','web')) {
        $item = Join-Path $Destination $name
        if (-not (Test-Path -LiteralPath $item) -or (($name -eq 'web') -ne (Test-Path -LiteralPath $item -PathType Container))) { throw '新しい本体の 3 つがそろっていません。' }
    }
}
function Get-CodegFreePort {
    $socket = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback, 0)
    $socket.Start()
    try { return $socket.LocalEndpoint.Port } finally { $socket.Stop() }
}
function Stop-CodegProcessTree {
    param([int]$ProcessId)
    $killer = New-Object Diagnostics.Process
    try {
        $info = New-Object Diagnostics.ProcessStartInfo
        $info.FileName = Join-Path $env:WINDIR 'System32\taskkill.exe'
        $info.Arguments = '/PID {0} /T /F' -f $ProcessId
        $info.UseShellExecute = $false; $info.CreateNoWindow = $true
        $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
        $killer.StartInfo = $info
        if (-not $killer.Start()) { throw 'プロセスの停止を開始できません。' }
        $stdout = $killer.StandardOutput.ReadToEndAsync(); $stderr = $killer.StandardError.ReadToEndAsync()
        if (-not $killer.WaitForExit(15000)) { $killer.Kill(); throw 'プロセスの停止が時間切れです。' }
        if ($killer.ExitCode -ne 0 -and (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)) { throw 'プロセスの停止を確認できません。' }
    } finally { $killer.Dispose() }
}
function Get-CodegBinaryVersion {
    param([string]$Binary, [string]$Work)
    $sandbox = Join-Path $Work ('version-' + [Guid]::NewGuid().ToString('N').Substring(0,24))
    [IO.Directory]::CreateDirectory($sandbox) | Out-Null
    $process = New-Object Diagnostics.Process
    $versionStarted = $false; $job = $null; $launcher = $null
    try {
        # 子が残っても一時環境を消さないよう、版確認を Job Object に収める。
        # taskkill が拒まれた場合も、ハンドルを閉じると子孫ごと終了する。
        if (-not ('CodegUpdateVersionJob' -as [type])) {
            Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public sealed class CodegUpdateVersionJob : IDisposable {
    [StructLayout(LayoutKind.Sequential)] struct BasicLimit {
        public long ProcessTime, JobTime;
        public uint Flags;
        public UIntPtr MinWorkingSet, MaxWorkingSet;
        public uint ActiveProcesses;
        public UIntPtr Affinity;
        public uint PriorityClass, SchedulingClass;
    }
    [StructLayout(LayoutKind.Sequential)] struct IoCounters {
        public ulong ReadOperations, WriteOperations, OtherOperations, ReadBytes, WriteBytes, OtherBytes;
    }
    [StructLayout(LayoutKind.Sequential)] struct ExtendedLimit {
        public BasicLimit Basic;
        public IoCounters Io;
        public UIntPtr ProcessMemory, JobMemory, PeakProcessMemory, PeakJobMemory;
    }
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] static extern IntPtr CreateJobObject(IntPtr attributes, string name);
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool SetInformationJobObject(IntPtr job, int informationClass, ref ExtendedLimit limits, uint size);
    [DllImport("kernel32.dll", SetLastError=true)] static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr handle);
    IntPtr handle;
    public CodegUpdateVersionJob() {
        handle=CreateJobObject(IntPtr.Zero,null);
        var limits=new ExtendedLimit(); limits.Basic.Flags=0x2000;
        if(handle==IntPtr.Zero || !SetInformationJobObject(handle,9,ref limits,(uint)Marshal.SizeOf(typeof(ExtendedLimit)))) {
            Dispose(); throw new InvalidOperationException("版確認のプロセスの隔離を用意できません。");
        }
    }
    public void Attach(IntPtr process) {
        if(!AssignProcessToJobObject(handle,process)) throw new InvalidOperationException("版確認のプロセスを隔離できません。");
    }
    public void Dispose() { if(handle!=IntPtr.Zero) { CloseHandle(handle); handle=IntPtr.Zero; } }
}
'@
        }
        $job = New-Object CodegUpdateVersionJob
        $info = New-Object Diagnostics.ProcessStartInfo
        # wrapper は標準入力で許可を受けるまで本体を起動しない。
        # Job に所属させてから許可するので、速い終了や子の生成と競合しない。
        $launcher = Join-Path $Work ('version-' + [Guid]::NewGuid().ToString('N').Substring(0,8) + '.ps1')
        $encodedBinary = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($Binary))
        $launcherText = @'
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$inputStream = [Console]::OpenStandardInput()
function Read-AsciiLine {
    $bytes = New-Object 'Collections.Generic.List[byte]'
    while (($next = $inputStream.ReadByte()) -ne -1) {
        if ($next -eq 10) { break }
        # .NET Framework は StandardInput の作成時点で BOM を送ることがある。
        # BaseStream の ASCII 本文に先行する UTF-8 BOM だけを取り除く。
        if ($bytes.Count -eq 0 -and $next -eq 239) {
            if ($inputStream.ReadByte() -ne 187 -or $inputStream.ReadByte() -ne 191) { throw '起動許可の形式が不正です。' }
            continue
        }
        if ($next -gt 127) { throw '起動許可の形式が不正です。' }
        if ($next -ne 13) { $bytes.Add([byte]$next) }
    }
    return [Text.Encoding]::ASCII.GetString($bytes.ToArray())
}
if ((Read-AsciiLine) -cne 'run') { exit 1 }
$info = New-Object Diagnostics.ProcessStartInfo
$info.FileName = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('__BINARY__'))
$info.Arguments = '--version'
$info.WorkingDirectory = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('__DIRECTORY__'))
foreach ($key in @($info.EnvironmentVariables.Keys)) { if ($key -match '^(CODEG_|XDG_)') { $info.EnvironmentVariables.Remove($key) } }
$settings = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String((Read-AsciiLine))) | ConvertFrom-Json
foreach ($property in $settings.PSObject.Properties) { $info.EnvironmentVariables[$property.Name] = [string]$property.Value }
$info.UseShellExecute = $false
$info.CreateNoWindow = $true
$info.RedirectStandardOutput = $true
$info.RedirectStandardError = $true
$child = New-Object Diagnostics.Process
$child.StartInfo = $info
try {
    if (-not $child.Start()) { exit 1 }
    $stdout = $child.StandardOutput.ReadToEndAsync()
    $stderr = $child.StandardError.ReadToEndAsync()
    $child.WaitForExit()
    [Console]::Out.Write($stdout.Result)
    exit $child.ExitCode
} finally { $child.Dispose() }
'@
        $info.FileName = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $info.WorkingDirectory = $Work
        $info.RedirectStandardInput = $true
        $info.UseShellExecute = $false; $info.CreateNoWindow = $true
        $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
        foreach ($key in @($info.EnvironmentVariables.Keys)) { if ($key -match '^(CODEG_|XDG_)') { $info.EnvironmentVariables.Remove($key) } }
        foreach ($key in @('CODEG_DATA_DIR','CODEG_HOME','TEMP','TMP','USERPROFILE','HOME','APPDATA','LOCALAPPDATA','TMPDIR','XDG_CONFIG_HOME','XDG_DATA_HOME','XDG_CACHE_HOME','XDG_STATE_HOME','XDG_RUNTIME_DIR')) {
            $dir = Join-Path $sandbox $key; [IO.Directory]::CreateDirectory($dir) | Out-Null; $info.EnvironmentVariables[$key] = $dir
        }
        $info.EnvironmentVariables['CODEG_HOST'] = '127.0.0.1'
        $info.EnvironmentVariables['CODEG_PORT'] = [string](Get-CodegFreePort)
        $info.EnvironmentVariables['CODEG_TOKEN'] = [Guid]::NewGuid().ToString('N') + [Guid]::NewGuid().ToString('N')
        $info.EnvironmentVariables['CODEG_STATIC_DIR'] = (Join-Path $sandbox 'web')
        $info.EnvironmentVariables['CODEG_BRIDGE_PORTS'] = 'off'; $info.EnvironmentVariables['CODEG_BROWSER_TUNNEL'] = 'off'
        $binaryEnvironment = @{}
        foreach ($key in @($info.EnvironmentVariables.Keys)) {
            if ($key -match '^(CODEG_|XDG_)' -or $key -in @('TEMP','TMP','USERPROFILE','HOME','APPDATA','LOCALAPPDATA','TMPDIR')) { $binaryEnvironment[$key] = $info.EnvironmentVariables[$key] }
        }
        # wrapper の PowerShell 自体は通常の Windows 環境で初期化する。
        # 本体に渡す環境は上の使い捨ての値だけで、起動直前に設定する。
        foreach ($key in @('TEMP','TMP','USERPROFILE','HOME','APPDATA','LOCALAPPDATA','TMPDIR')) {
            $value = [Environment]::GetEnvironmentVariable($key)
            if ($null -eq $value) { $info.EnvironmentVariables.Remove($key) } else { $info.EnvironmentVariables[$key] = $value }
        }
        $directoryText = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($sandbox))
        $command = $launcherText.Replace('__BINARY__',$encodedBinary).Replace('__DIRECTORY__',$directoryText)
        [IO.File]::WriteAllText($launcher,$command,(New-Object Text.UTF8Encoding($true)))
        $info.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $launcher + '"'
        $process.StartInfo = $info
        $elapsed = [Diagnostics.Stopwatch]::StartNew()
        if (-not $process.Start()) { throw '版の確認を開始できません。' }
        $versionStarted = $true
        $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
        $job.Attach($process.Handle)
        # StreamWriter の InputEncoding と BOM に依存しない ASCII の手順で渡す。
        $environmentBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($binaryEnvironment | ConvertTo-Json -Compress)))
        $payload = [Text.Encoding]::ASCII.GetBytes('run' + [char]10 + $environmentBase64 + [char]10)
        $inputWrite = $process.StandardInput.BaseStream.WriteAsync($payload,0,$payload.Length)
        if (-not $inputWrite.Wait([Math]::Max(1,10000-[int]$elapsed.ElapsedMilliseconds))) {
            Stop-CodegProcessTree $process.Id
            throw '版の確認が 10 秒で終わりませんでした。'
        }
        $process.StandardInput.BaseStream.Dispose()
        if (-not $process.WaitForExit([Math]::Max(1,10000-[int]$elapsed.ElapsedMilliseconds))) {
            Stop-CodegProcessTree $process.Id
            $process.WaitForExit(5000) | Out-Null
            throw '版の確認が 10 秒で終わりませんでした。'
        }
        if (-not $stdout.Wait(1000) -or -not $stderr.Wait(1000)) { Stop-CodegProcessTree $process.Id; throw '版の確認の出力が閉じていません。' }
        if ($process.ExitCode -ne 0) { throw '版の確認が失敗しました。' }
        $versions = @($stdout.Result -split '\r?\n' | Where-Object { $_ -cmatch '^\d+\.\d+\.\d+$' })
        if ($versions.Count -ne 1) { throw '本体の版を一意に確認できません。' }
        return $versions[0]
    } finally {
        if ($job) { $job.Dispose() }
        if ($versionStarted -and -not $process.HasExited) {
            try { Stop-CodegProcessTree $process.Id } catch { $process.Kill() }
            $process.WaitForExit(5000) | Out-Null
        }
        $process.Dispose()
        if ($launcher -and (Test-Path -LiteralPath $launcher)) { Remove-Item -LiteralPath $launcher -Force }
        if (Test-Path -LiteralPath $sandbox) { Remove-Item -LiteralPath $sandbox -Recurse -Force }
    }
}
function Get-CodegEndpoint {
    param($Paths)
    # この起動スクリプトには秘密の本文が無い。token.txt は開かない。
    $text = [IO.File]::ReadAllText((Join-Path $Paths.Server 'start-codeg-server.ps1'))
    $hosts = [regex]::Matches($text, '(?m)^\s*\$env:CODEG_HOST\s*=\s*''([^''\r\n]+)''\s*;?\s*$')
    $ports = [regex]::Matches($text, '(?m)^\s*\$env:CODEG_PORT\s*=\s*''(\d+)''\s*;?\s*$')
    if ($hosts.Count -ne 1 -or $ports.Count -ne 1) { throw '待ち受けの設定が 1 つずつではありません。' }
    $address = $null
    if (-not [Net.IPAddress]::TryParse($hosts[0].Groups[1].Value, [ref]$address) -or -not [Net.IPAddress]::IsLoopback($address)) { throw '待ち受けは localhost の専用構成にしてください。' }
    $portNumber = [int]$ports[0].Groups[1].Value
    if ($portNumber -lt 1 -or $portNumber -gt 65535) { throw '待ち受けのポートが不正です。' }
    return [pscustomobject]@{ Host = $address.ToString(); Port = $portNumber }
}
function Get-CodegTaskState { param($Paths) return [string](Get-ScheduledTask -TaskName $Paths.Task).State }
function Get-CodegListeners { param($Endpoint) return @(Get-NetTCPConnection -LocalPort $Endpoint.Port -State Listen -ErrorAction SilentlyContinue) }
function Get-CodegUpdateListener {
    param($Paths, $Endpoint, [DateTime]$NotBefore = [DateTime]::MinValue)
    $listeners = @(Get-CodegListeners $Endpoint)
    if (-not $listeners.Count) { return $null }
    if ($listeners.Count -ne 1 -or $listeners[0].LocalAddress -ne $Endpoint.Host) { throw '待ち受けが専用構成と異なります。' }
    $process = Get-Process -Id $listeners[0].OwningProcess
    if ($process.Path -ine (Join-Path $Paths.Server 'codeg-server.exe') -or $process.StartTime.ToUniversalTime() -lt $NotBefore -or (Get-CodegTaskState $Paths) -ne 'Running') { throw '専用タスクから起動した本体を確認できません。' }
    return [pscustomobject]@{ ProcessId = $process.Id; StartTime = $process.StartTime; Path = $process.Path }
}
function Get-CodegHttpStatus {
    param($Endpoint, [string]$Path)
    $hostText = $Endpoint.Host
    if ($hostText.Contains(':')) { $hostText = '[' + $hostText + ']' }
    $url = 'http://{0}:{1}{2}' -f $hostText,$Endpoint.Port,$Path
    $result = Invoke-CodegCurl @('--silent','--show-error','--noproxy','*','--connect-timeout','2','--max-time','5','--output','NUL','--write-out','%{http_code}',$url)
    if ($result.Trim() -notmatch '^\d{3}$') { throw 'HTTP の応答を確認できません。' }
    return [int]$result.Trim()
}
function Wait-CodegRunningListener {
    param($Paths, $Endpoint)
    $deadline = (Get-CodegUtcNow).AddSeconds(120)
    do {
        $listener = Get-CodegUpdateListener $Paths $Endpoint
        if ($listener) { return $listener }
        if ((Get-CodegTaskState $Paths) -ne 'Running') { throw 'Codeg のタスクが動いていません。' }
        Wait-CodegUpdate 500
    } while ((Get-CodegUtcNow) -lt $deadline)
    throw '待ち受けを 120 秒で確認できません。'
}
function Test-CodegDatabaseUnlocked {
    param($Paths)
    $file = Join-Path $Paths.Data 'codeg.db'
    if (-not (Test-Path -LiteralPath $file)) { return $true }
    try { $stream = [IO.File]::Open($file,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None); $stream.Dispose(); return $true } catch { return $false }
}
function Stop-CodegUpdateServer {
    param($Paths, $Endpoint)
    $expected = Join-Path $Paths.Server 'codeg-server.exe'
    foreach ($process in @(Get-Process -Name 'codeg-server' -ErrorAction SilentlyContinue)) {
        if ($process.Path -ieq $expected) { Stop-CodegProcessTree $process.Id }
    }
    Stop-ScheduledTask -TaskName $Paths.Task
    $deadline = (Get-CodegUtcNow).AddSeconds(120)
    do {
        if ((Get-CodegTaskState $Paths) -eq 'Ready' -and @(Get-CodegListeners $Endpoint).Count -eq 0 -and (Test-CodegDatabaseUnlocked $Paths)) { return }
        Wait-CodegUpdate 500
    } while ((Get-CodegUtcNow) -lt $deadline)
    throw 'タスクの停止、ポートの解放、DB の排他確認が終わりません。'
}
function Start-CodegUpdateServer { param($Paths) Start-ScheduledTask -TaskName $Paths.Task }
function Wait-CodegUpdateHealth {
    param($Paths, $Endpoint, [DateTime]$NotBefore, [string]$Version, [string]$Work)
    $startedAt = Get-CodegMonotonicTime
    $stableSince = $null; $identity = $null
    do {
        if ((Get-CodegTaskState $Paths) -ne 'Running') { throw '確認中に Codeg のタスクが止まりました。' }
        $current = Get-CodegUpdateListener $Paths $Endpoint $NotBefore
        if (-not $current) {
            if ($identity) { throw '一度確認した待ち受けが消えました。' }
            Wait-CodegUpdate 500
            continue
        }
        if ($identity -and ($identity.ProcessId -ne $current.ProcessId -or $identity.StartTime -ne $current.StartTime)) { throw '確認中に本体が起動し直されました。' }
        if (-not $identity) { $identity = $current }
        $httpReady = $true; $rootStatus = $null; $apiStatus = $null
        try { $rootStatus = Get-CodegHttpStatus $Endpoint '/'; $apiStatus = Get-CodegHttpStatus $Endpoint '/api/version' }
        catch { $httpReady = $false }
        if ((Get-CodegTaskState $Paths) -ne 'Running') { throw 'HTTP 確認中に Codeg のタスクが止まりました。' }
        $after = Get-CodegUpdateListener $Paths $Endpoint $NotBefore
        if (-not $after -or $after.ProcessId -ne $identity.ProcessId -or $after.StartTime -ne $identity.StartTime) { throw 'HTTP 確認中に本体が変わりました。' }
        if (((Get-CodegMonotonicTime) - $startedAt) -ge 120) { throw '本体と HTTP の安定した状態を 120 秒で確認できません。' }
        if ($httpReady) {
            if ($rootStatus -ne 200 -or $apiStatus -ne 401) { throw '未認証の HTTP 応答が異なります。' }
            if ($null -eq $stableSince) { $stableSince = Get-CodegMonotonicTime }
            if (((Get-CodegMonotonicTime) - $stableSince) -ge 30) {
                if ((Get-CodegBinaryVersion (Join-Path $Paths.Server 'codeg-server.exe') $Work) -cne $Version) { throw '入れた本体の版が一致しません。' }
                if ((Get-CodegTaskState $Paths) -ne 'Running') { throw '版の確認中に Codeg のタスクが止まりました。' }
                $final = Get-CodegUpdateListener $Paths $Endpoint $NotBefore
                if (-not $final -or $final.ProcessId -ne $identity.ProcessId -or $final.StartTime -ne $identity.StartTime) { throw '版の確認中に本体が変わりました。' }
                if (((Get-CodegMonotonicTime) - $startedAt) -ge 120) { throw '本体と HTTP の安定した状態を 120 秒で確認できません。' }
                return
            }
        } else { $stableSince = $null }
        Wait-CodegUpdate 500
    } while (((Get-CodegMonotonicTime) - $startedAt) -lt 120)
    throw '本体と HTTP の安定した状態を 120 秒で確認できません。'
}
function Get-CodegDatabaseFiles {
    param($Paths)
    if (Test-Path -LiteralPath $Paths.Data) {
        $data = Get-Item -LiteralPath $Paths.Data -Force
        if (-not $data.PSIsContainer -or ($data.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'データの場所が通常のフォルダーではありません。' }
        $files = @(Get-ChildItem -LiteralPath $Paths.Data -Filter 'codeg.db*' -Force)
        foreach ($file in $files) {
            if ($file.PSIsContainer -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'DB に通常のファイルでないものがあります。' }
        }
        return $files
    }
    return @()
}
function Copy-CodegDatabase {
    param($Paths, [string]$Destination)
    [IO.Directory]::CreateDirectory($Destination) | Out-Null
    foreach ($file in @(Get-CodegDatabaseFiles $Paths)) {
        $source = $null; $target = $null
        try {
            $source = [IO.File]::Open($file.FullName,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::None)
            $target = [IO.File]::Open((Join-Path $Destination $file.Name),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
            $source.CopyTo($target); $target.Flush($true)
        } finally { if ($target) { $target.Dispose() }; if ($source) { $source.Dispose() } }
    }
}
function Test-CodegFreeSpace {
    param($Paths)
    $size = [int64]0
    foreach ($file in @(Get-CodegDatabaseFiles $Paths)) { $size += $file.Length }
    $drive = New-Object IO.DriveInfo([IO.Path]::GetPathRoot($Paths.State))
    if ($drive.AvailableFreeSpace -lt (2 * $size + 1GB)) { throw 'DB の 2 倍と 1 GiB の空き容量がありません。' }
    if ([IO.Path]::GetPathRoot($Paths.State) -ine [IO.Path]::GetPathRoot($Paths.Server) -or [IO.Path]::GetPathRoot($Paths.State) -ine [IO.Path]::GetPathRoot($Paths.Data)) { throw '本体、データ、状態のフォルダーが同じボリュームではありません。' }
}
function Move-CodegBinaries {
    param([string]$From, [string]$To)
    [IO.Directory]::CreateDirectory($To) | Out-Null
    foreach ($name in @('codeg-server.exe','codeg-mcp.exe','web')) {
        $source = Join-Path $From $name
        if (Test-Path -LiteralPath $source) { Move-Item -LiteralPath $source -Destination (Join-Path $To $name) }
    }
}
function Remove-CodegOldBackups {
    param($Paths)
    $dirs = @(Get-ChildItem -LiteralPath $Paths.Backups -Directory | Where-Object { $_.Name -match '^\d{8}T\d{12}Z-\d+\.\d+\.\d+$' -and -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } | Sort-Object Name -Descending | Select-Object -Skip 2)
    foreach ($dir in $dirs) { Remove-Item -LiteralPath $dir.FullName -Recurse -Force }
}
function Assert-CodegInstall {
    param($Paths)
    foreach ($name in @('codeg-server.exe','codeg-mcp.exe','web')) {
        $item = Join-Path $Paths.Server $name
        if (-not (Test-Path -LiteralPath $item) -or (($name -eq 'web') -ne (Test-Path -LiteralPath $item -PathType Container))) { throw '本体の 3 つがそろっていません。' }
        if ((Get-Item -LiteralPath $item -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw '本体に再解析ポイントがあります。' }
    }
    if (Test-Path -LiteralPath (Join-Path $Paths.Server '.codeg-upgrade-staged')) { throw '画面からの自己更新の目印があります。extra の復旧を確かめてください。' }
    if (@(Get-ChildItem -LiteralPath $Paths.Server -Force | Where-Object { $_.Name.EndsWith('.bak',[StringComparison]::OrdinalIgnoreCase) }).Count) { throw '画面からの自己更新の控えがあります。extra の復旧を確かめてください。' }
}
function Assert-CodegRestoreDirectory {
    param([string]$Path, [switch]$AllowMissing)
    if (-not (Test-Path -LiteralPath $Path)) { if ($AllowMissing) { return }; throw '復元に必要なフォルダーがありません。' }
    $item = Get-Item -LiteralPath $Path -Force
    if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw '復元対象が通常のフォルダーではありません。' }
}
function Assert-CodegRestoreBinary {
    param([string]$Path, [string]$Name)
    if (-not (Test-Path -LiteralPath $Path)) { throw '復元する本体がそろっていません。' }
    $item = Get-Item -LiteralPath $Path -Force
    if (($item.PSIsContainer -ne ($Name -eq 'web')) -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw '本体の種類が異なるか、リンクになっています。' }
    if ($item.PSIsContainer) {
        $directories = New-Object 'Collections.Generic.Queue[string]'
        $directories.Enqueue($Path)
        while ($directories.Count) {
            foreach ($child in @(Get-ChildItem -LiteralPath $directories.Dequeue() -Force)) {
                if ($child.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw '本体の中にリンクがあります。' }
                if ($child.PSIsContainer) { $directories.Enqueue($child.FullName) }
            }
        }
    }
}
function Get-CodegRestorePlan {
    param($Paths, [string]$BackupName, [string]$HoldVersion)
    if ($BackupName -cnotmatch '^\d{8}T\d{6}(?:\d{6})?Z-\d+\.\d+\.\d+$' -or $HoldVersion -cnotmatch '^\d+\.\d+\.\d+$') { throw '控えの名前と保留する版を指定してください。' }
    $backupRoot = [IO.Path]::GetFullPath($Paths.Backups).TrimEnd('\')
    $backup = [IO.Path]::GetFullPath((Join-Path $backupRoot $BackupName))
    if ([IO.Path]::GetDirectoryName($backup) -ine $backupRoot) { throw '控えが専用のフォルダーの外を指しています。' }
    foreach ($directory in @($Paths.State,$Paths.Server,$backupRoot)) { Assert-CodegRestoreDirectory $directory }
    Assert-CodegRestoreDirectory $Paths.Data -AllowMissing
    if ((Test-Path -LiteralPath (Join-Path $Paths.Server '.codeg-upgrade-staged')) -or
        @(Get-ChildItem -LiteralPath $Paths.Server -Force | Where-Object { $_.Name.EndsWith('.bak',[StringComparison]::OrdinalIgnoreCase) }).Count) { throw '画面からの自己更新の目印があります。' }
    $expected = ($BackupName -split '-')[-1]
    $marker = Join-Path $Paths.State 'in-progress'; $progress = $null
    if (Test-Path -LiteralPath $marker) {
        $markerItem = Get-Item -LiteralPath $marker -Force
        if ($markerItem.PSIsContainer -or ($markerItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw '途中の目印が通常のファイルではありません。' }
        $progress = [IO.File]::ReadAllText($marker) | ConvertFrom-Json
        if ((Get-CodegProperty $progress 'stage') -notin @('backing-up','installing','checking','rolling-back','restart-failed')) { throw '途中の段階が不明です。' }
        $progressBackup = [string](Get-CodegProperty $progress 'backup')
        if (-not [IO.Path]::IsPathRooted($progressBackup) -or [IO.Path]::GetFullPath($progressBackup) -ine $backup -or
            (Get-CodegProperty $progress 'old') -cne $expected -or (Get-CodegProperty $progress 'new') -cne $HoldVersion) { throw '途中の控え・旧版・更新先が選択値と一致しません。' }
    }
    $keepDatabase = $progress -and (Get-CodegProperty $progress 'stage') -in @('backing-up','restart-failed')
    Assert-CodegRestoreDirectory $backup -AllowMissing:$keepDatabase
    Assert-CodegRestoreDirectory (Join-Path $backup 'bin') -AllowMissing:$keepDatabase
    $sources = @{}
    foreach ($name in @('codeg-server.exe','codeg-mcp.exe','web')) {
        if ($keepDatabase) {
            $candidates = @(@((Join-Path $Paths.Server $name),(Join-Path (Join-Path $backup 'bin') $name)) | Where-Object { Test-Path -LiteralPath $_ })
            if ($candidates.Count -ne 1) { throw '旧本体の各要素が片方だけに存在することを確認できません。' }
            $sources[$name] = $candidates[0]
        } else { $sources[$name] = Join-Path (Join-Path $backup 'bin') $name }
        Assert-CodegRestoreBinary $sources[$name] $name
    }
    $currentDatabase = @(Get-CodegDatabaseFiles $Paths)
    if ($keepDatabase) {
        if (-not @($currentDatabase | Where-Object { $_.Name -ceq 'codeg.db' }).Count) { throw '元の DB がありません。' }
    } else {
        $backupDatabase = @(Get-CodegDatabaseFiles ([pscustomobject]@{Data=(Join-Path $backup 'db')}))
        if (-not @($backupDatabase | Where-Object { $_.Name -ceq 'codeg.db' }).Count) { throw 'DB の控えがありません。' }
        foreach ($name in @('codeg-server.exe','codeg-mcp.exe','web')) {
            $current = Join-Path $Paths.Server $name
            if (Test-Path -LiteralPath $current) { Assert-CodegRestoreBinary $current $name }
        }
    }
    if ((Get-CodegBinaryVersion $sources['codeg-server.exe'] $Paths.State) -cne $expected) { throw '旧本体の版が控えの名前と一致しません。' }
    return [pscustomobject]@{Backup=$backup;Expected=$expected;Sources=$sources;KeepDatabase=$keepDatabase}
}
function Invoke-CodegRestore {
    param($Paths = (Get-CodegUpdatePaths), [string]$BackupName, [string]$HoldVersion)
    $lock = $null; $work = $null; $started = $false; $displaced = $null; $completed = $false; $logReady = $false; $stopComplete = $false; $originalVersion = $null; $originalIdentity = $null
    $marker = Join-Path $Paths.State 'in-progress'
    try {
        Assert-CodegRestoreDirectory $Paths.State
        Initialize-CodegUpdateLog $Paths; $logReady = $true
        try { $lock = [IO.File]::Open((Join-Path $Paths.State 'lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None) }
        catch { Write-CodegUpdateLog $Paths '別の更新または復元が動いているため中断しました。'; return 1 }
        $plan = Get-CodegRestorePlan $Paths $BackupName $HoldVersion
        $endpoint = Get-CodegEndpoint $Paths
        $taskState = Get-CodegTaskState $Paths
        if ($taskState -notin @('Ready','Running')) { throw 'Codeg のタスクが Ready または Running ではありません。' }
        if ($taskState -eq 'Running') { $originalIdentity = Wait-CodegRunningListener $Paths $endpoint }
        elseif (@(Get-CodegListeners $endpoint).Count -or -not (Test-CodegDatabaseUnlocked $Paths)) { throw '待ち受けまたは DB の使用が残っています。' }
        $originalBinary = Join-Path $Paths.Server 'codeg-server.exe'
        if (Test-Path -LiteralPath $originalBinary) { $originalVersion = Get-CodegBinaryVersion $originalBinary $Paths.State }
        elseif ($taskState -eq 'Running') { throw '元の本体の版を確認できません。' }
        Test-CodegFreeSpace $Paths
        $displaced = Join-Path $Paths.Backups ('failed-manual-' + (Get-CodegUtcNow).ToString('yyyyMMddTHHmmssffffffZ'))
        if (Test-Path -LiteralPath $displaced) { throw '同じ退避先が存在します。' }
        $work = Join-Path $Paths.State ('restore-' + [Guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($work) | Out-Null
        # すべての前提を検査してから、既存の停止処理を使う。
        $started = $true
        if (-not $plan.KeepDatabase) { Write-CodegProgress $marker 'rolling-back' $plan.Backup $plan.Expected $HoldVersion }
        Stop-CodegUpdateServer $Paths $endpoint
        $stopComplete = $true
        [IO.Directory]::CreateDirectory((Join-Path $displaced 'bin')) | Out-Null
        [IO.Directory]::CreateDirectory((Join-Path $displaced 'db')) | Out-Null
        if ($plan.KeepDatabase) {
            foreach ($name in @('codeg-server.exe','codeg-mcp.exe','web')) {
                $destination = Join-Path $Paths.Server $name
                if ($plan.Sources[$name] -ine $destination) { Move-Item -LiteralPath $plan.Sources[$name] -Destination $destination }
            }
            # コピー途中の DB は使わず、元 DB をそのまま使う。
            if (Test-Path -LiteralPath $plan.Backup) { Move-Item -LiteralPath $plan.Backup -Destination (Join-Path $displaced 'partial-backup') }
        } else {
            Move-CodegBinaries $Paths.Server (Join-Path $displaced 'bin')
            foreach ($file in @(Get-CodegDatabaseFiles $Paths)) { Move-Item -LiteralPath $file.FullName -Destination (Join-Path (Join-Path $displaced 'db') $file.Name) }
            foreach ($name in @('codeg-server.exe','codeg-mcp.exe','web')) { Copy-Item -LiteralPath $plan.Sources[$name] -Destination (Join-Path $Paths.Server $name) -Recurse }
            Copy-CodegDatabase ([pscustomobject]@{Data=(Join-Path $plan.Backup 'db')}) $Paths.Data
        }
        $notBefore = Get-CodegUtcNow
        Start-CodegUpdateServer $Paths
        Wait-CodegUpdateHealth $Paths $endpoint $notBefore $plan.Expected $work
        Write-CodegUpdateState (Join-Path $Paths.State 'skip-version') $HoldVersion
        if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker -Force }
        $completed = $true
        Write-CodegUpdateLog $Paths ('復元: ' + $plan.Expected + ' を確認し、' + $HoldVersion + ' を保留しました。')
        Write-CodegUpdateLog $Paths ('今回の退避: ' + $displaced)
        return 0
    } catch {
        if (-not $logReady) { try { [Console]::Out.WriteLine('中断: 自動更新のログを安全に用意できません。') } catch { }; return 1 }
        if ($completed) { return 0 }
        if ($started -and -not $stopComplete) {
            try {
                if (-not $originalVersion) { throw '元の版を確認できません。' }
                $resumeNotBefore = Get-CodegUtcNow
                if ($originalIdentity) { $resumeNotBefore = $originalIdentity.StartTime.ToUniversalTime() }
                Start-CodegUpdateServer $Paths
                Wait-CodegUpdateHealth $Paths $endpoint $resumeNotBefore $originalVersion $work
                if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker -Force }
                Write-CodegUpdateLog $Paths ('復元を始めず、元の版 ' + $originalVersion + ' の再開を確認しました。')
                return 1
            } catch {
                Write-CodegUpdateLog $Paths '終了 3: 復元前の停止と元の Codeg の再開を確認できません。in-progress と現在の本体・DB・控えを保持してください。'
                return 3
            }
        }
        if (-not $started) {
            if (Test-Path -LiteralPath $Paths.State -PathType Container) { Write-CodegUpdateLog $Paths '復元を始めずに中断しました。控え・途中の段階・保留する版・自己更新の目印を確かめてください。' }
            return 1
        }
        if (-not (Test-Path -LiteralPath $marker)) { Write-CodegProgress $marker 'rolling-back' $plan.Backup $plan.Expected $HoldVersion }
        Write-CodegUpdateLog $Paths '終了 3: 復元後の起動を確認できません。現行・控え・今回の退避と in-progress を保持して復旧を依頼してください。'
        if ($displaced) { Write-CodegUpdateLog $Paths ('今回の退避: ' + $displaced) }
        return 3
    } finally {
        if ($work -and (Test-Path -LiteralPath $work)) { try { Remove-Item -LiteralPath $work -Recurse -Force } catch { } }
        if ($lock) { $lock.Dispose() }
    }
}
function Invoke-CodegAutoUpdate {
    param($Paths = (Get-CodegUpdatePaths))
    $lock = $null; $work = $null; $stopped = $false; $backup = $null; $replacement = $false; $updated = $false; $logReady = $false; $stage = '事前確認'
    $marker = Join-Path $Paths.State 'in-progress'; $skip = Join-Path $Paths.State 'skip-version'
    [IO.Directory]::CreateDirectory($Paths.State) | Out-Null
    try {
        Initialize-CodegUpdateLog $Paths; $logReady = $true
        try { $lock = [IO.File]::Open((Join-Path $Paths.State 'lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None) }
        catch { Write-CodegUpdateLog $Paths '別の自動更新が動いているため中断しました。'; return 1 }
        if (Test-Path -LiteralPath $marker) { Write-CodegUpdateLog $Paths '前の入れ替えが途中です。終了 3: docs/extra/codeg.md の「Windows 11 で自動更新の控えから前の版と DB に戻す」で復旧してください。'; return 3 }
        [IO.Directory]::CreateDirectory($Paths.Backups) | Out-Null
        Assert-CodegInstall $Paths
        $endpoint = Get-CodegEndpoint $Paths
        $work = Join-Path $Paths.State ('work-' + [Guid]::NewGuid().ToString('N')); [IO.Directory]::CreateDirectory($work) | Out-Null
        $current = Get-CodegBinaryVersion (Join-Path $Paths.Server 'codeg-server.exe') $work
        $stage = '最新の安定版の取得'
        $release = Select-CodegRelease @(Get-CodegReleases $work)
        if (Test-Path -LiteralPath $skip) {
            $held = [IO.File]::ReadAllText($skip).Trim()
            if ($held -notmatch '^\d+\.\d+\.\d+$') { throw '保留の版の形式が不正です。' }
            if ([version]$held -le [version]$current) { Remove-Item -LiteralPath $skip -Force }
            elseif ($held -ceq $release.Version) { Write-CodegUpdateLog $Paths ('版 ' + $held + ' は保留中です。'); return 1 }
        }
        if ($release.Number -le [version]$current) { Write-CodegUpdateLog $Paths ('最新版 ' + $current + ' を使用中'); return 0 }
        $taskState = Get-CodegTaskState $Paths
        if ($taskState -eq 'Ready') { Write-CodegUpdateLog $Paths 'Codeg は止まっているので更新しない'; return 0 }
        if ($taskState -ne 'Running') { throw 'Codeg のタスクが Running または Ready ではありません。' }
        Wait-CodegRunningListener $Paths $endpoint | Out-Null
        $stage = '配布物の取得と照合'
        $archive = Join-Path $work 'codeg-server-windows-x64.zip'; $checksum = $archive + '.sha256'
        Save-CodegDownload ([string](Get-CodegProperty $release.Archive 'browser_download_url')) $archive
        Save-CodegDownload ([string](Get-CodegProperty $release.Checksum 'browser_download_url')) $checksum
        Test-CodegDownload $Paths $archive $checksum $release
        $stage = '展開と新しい本体の版の確認'
        $new = Join-Path $work 'new'; Expand-CodegArchive $archive $new
        try { if ((Get-CodegBinaryVersion (Join-Path $new 'codeg-server.exe') $work) -cne $release.Version) { throw '新しい本体の版が配布元と一致しません。' } }
        catch { Write-CodegUpdateState $skip $release.Version; throw }
        Test-CodegFreeSpace $Paths
        # ここまでサービスを止めない。停止が途中で失敗した場合も起動を試す。
        # 停止の失敗時にも、元 DB を保持する復旧先の名前を目印へ残せるよう予約する。
        $stamp = (Get-CodegUtcNow).ToString('yyyyMMddTHHmmssffffffZ')
        $backup = Join-Path $Paths.Backups ($stamp + '-' + $current)
        if (Test-Path -LiteralPath $backup) { throw '同じ控えの名前が存在します。' }
        $stage = 'サービスの停止'
        $stopped = $true
        Stop-CodegUpdateServer $Paths $endpoint
        $stage = '本体と DB の退避'
        Write-CodegProgress $marker 'backing-up' $backup $current $release.Version
        [IO.Directory]::CreateDirectory((Join-Path $backup 'bin')) | Out-Null
        Move-CodegBinaries $Paths.Server (Join-Path $backup 'bin')
        Copy-CodegDatabase $Paths (Join-Path $backup 'db')
        Write-CodegProgress $marker 'installing' $backup $current $release.Version
        $stage = '本体の入れ替えと起動の確認'
        $replacement = $true
        Move-CodegBinaries $new $Paths.Server
        $notBefore = Get-CodegUtcNow
        Start-CodegUpdateServer $Paths
        Write-CodegProgress $marker 'checking' $backup $current $release.Version
        Wait-CodegUpdateHealth $Paths $endpoint $notBefore $release.Version $work
        $stopped = $false; $updated = $true
        if (Test-Path -LiteralPath $skip) { Remove-Item -LiteralPath $skip -Force }
        Remove-Item -LiteralPath $marker -Force
        try { Remove-CodegOldBackups $Paths } catch { Write-CodegUpdateLog $Paths '更新は確認済みですが、古い控えを整理できませんでした。' }
        Write-CodegUpdateLog $Paths ('更新: ' + $current + ' → ' + $release.Version)
        return 0
    } catch {
        # 例外の本文に、外部プログラムや環境の値を出さない。
        if (-not $logReady) { try { [Console]::Out.WriteLine('中断: 自動更新のログを安全に用意できません。') } catch { }; return 1 }
        if ($updated) {
            if (Test-Path -LiteralPath $marker) { Write-CodegUpdateLog $Paths '更新は確認済みですが、状態を片付けられません。終了 3: extra の復旧で状態を確かめてください。'; return 3 }
            Write-CodegUpdateLog $Paths '更新は確認済みですが、後片付けを完了できませんでした。'; return 0
        }
        Write-CodegUpdateLog $Paths ('中断: ' + $stage + 'を完了できませんでした。')
        if (-not $stopped) { return 1 }
        if (-not $replacement) {
            try {
                if ($backup) { Move-CodegBinaries (Join-Path $backup 'bin') $Paths.Server }
                Start-CodegUpdateServer $Paths
                Wait-CodegUpdateHealth $Paths $endpoint (Get-CodegUtcNow).AddSeconds(-1) $current $work
                if (Test-Path -LiteralPath $marker) { Remove-Item -LiteralPath $marker -Force }
                if ($backup -and (Test-Path -LiteralPath $backup)) { try { Remove-Item -LiteralPath $backup -Recurse -Force } catch { Write-CodegUpdateLog $Paths '旧版は確認済みですが、不完全な控えを片付けられませんでした。' } }
                Write-CodegUpdateLog $Paths '旧版で起動し直し、変更前の状態を確認しました。'
                return 1
            } catch { if (-not $backup -or -not (Test-Path -LiteralPath $marker)) { Write-CodegProgress $marker 'restart-failed' $backup $current $release.Version }; Write-CodegUpdateLog $Paths '終了 3: 旧版を確認できません。docs/extra/codeg.md の「Windows 11 で自動更新の控えから前の版と DB に戻す」で復旧してください。'; return 3 }
        }
        try {
            Write-CodegUpdateState $skip $release.Version
            Write-CodegProgress $marker 'rolling-back' $backup $current $release.Version
            Stop-CodegUpdateServer $Paths $endpoint
            $failed = Join-Path $Paths.Backups ('failed-' + (Get-CodegUtcNow).ToString('yyyyMMddTHHmmssffffffZ'))
            Move-CodegBinaries $Paths.Server (Join-Path $failed 'bin')
            [IO.Directory]::CreateDirectory((Join-Path $failed 'db')) | Out-Null
            foreach ($file in @(Get-CodegDatabaseFiles $Paths)) { Move-Item -LiteralPath $file.FullName -Destination (Join-Path (Join-Path $failed 'db') $file.Name) }
            $restore = Join-Path $work 'restore'
            [IO.Directory]::CreateDirectory($restore) | Out-Null
            foreach ($name in @('codeg-server.exe','codeg-mcp.exe','web')) { Copy-Item -LiteralPath (Join-Path (Join-Path $backup 'bin') $name) -Destination (Join-Path $restore $name) -Recurse }
            Move-CodegBinaries $restore $Paths.Server
            [IO.Directory]::CreateDirectory($Paths.Data) | Out-Null
            Copy-CodegDatabase ([pscustomobject]@{Data=(Join-Path $backup 'db')}) $Paths.Data
            $notBefore = Get-CodegUtcNow
            Start-CodegUpdateServer $Paths
            Wait-CodegUpdateHealth $Paths $endpoint $notBefore $current $work
            Remove-Item -LiteralPath $marker -Force
            Write-CodegUpdateLog $Paths ('終了 2: ' + $current + ' に戻し、' + $release.Version + ' を保留しました。')
            return 2
        } catch { Write-CodegUpdateLog $Paths '終了 3: 戻せませんでした。docs/extra/codeg.md の「Windows 11 で自動更新の控えから前の版と DB に戻す」で復旧してください。'; return 3 }
    } finally {
        if ($work -and (Test-Path -LiteralPath $work)) { try { Remove-Item -LiteralPath $work -Recurse -Force } catch { Write-CodegUpdateLog $Paths '作業用の一時フォルダーを消せませんでした。' } }
        if ($lock) { $lock.Dispose() }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    if ($PSBoundParameters.ContainsKey('Restore') -or $PSBoundParameters.ContainsKey('Hold')) { exit (Invoke-CodegRestore -BackupName $Restore -HoldVersion $Hold) }
    exit (Invoke-CodegAutoUpdate)
}
