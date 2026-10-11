# Hyper-V の有効化と VM の作成（Windows 11 Pro）

## 実施手順

- [検証記録](verification/hyper-v.md)・[参考資料](reference/hyper-v.md)・[ロールバックと注意点](extra/hyper-v.md)

> [!IMPORTANT]
> - **Windows 11 Pro（x64）の PC のデスクトップで行う**。Home には Hyper-V が無い。SSH やリモート デスクトップのセッションからは行わない（途中で再起動する）
> - [この PC で使えるかを確かめる](#この-pc-で使えるかを確かめる)の手順 1 で**管理者の** Windows PowerShell（5.1）を開き、[Hyper-V を有効にして再起動する](#hyper-v-を有効にして再起動する)までのブロックをそこに貼る。[再起動の後に確かめる](#再起動の後に確かめる)から後ろは、**管理者ではない** Windows PowerShell に貼る
> - ログインするユーザーは Administrators の一員
> - 前提: [Windows 11 の初期設定の「貼り付けの設定」の手順 1〜4](windows-setup.md#貼り付けの設定)。通していなければ、ブロックは Ctrl+V で貼る
> - **途中で再起動が 1 回入る**（[Hyper-V を有効にして再起動する](#hyper-v-を有効にして再起動する)の手順 4）。開いている作業を先に保存し、動いている VM を止める
> - **同じ PC の VirtualBox と VMware Workstation の VM は、再起動の後は Windows のハイパーバイザーの上で動く**。遅くなり、起動しない VM が出ることがある

- 上から順にコードブロックを貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 手順の後: ふだんの操作は[使い方の基本](#使い方の基本)、状態を残す・複製するなら[チェックポイントとクローン](#チェックポイントとクローン)、VM どうしをつなぐなら[VM どうしだけがつながるスイッチを作る（任意）](#vm-どうしだけがつながるスイッチを作る任意)、要らなくなった VM は[VM を消す](#vm-を消す)

### この PC で使えるかを確かめる

1. Windows のデスクトップで、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. エディション・CPU の仮想化支援・機能の今の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     Admin        = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     User         = "$env:USERDOMAIN\$env:USERNAME"
     Arch         = $env:PROCESSOR_ARCHITECTURE
     Edition      = (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
     Hypervisor   = (Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
     VirtFirmware = (Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1).VirtualizationFirmwareEnabled
   } | Format-List
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -like 'Microsoft-Hyper-V*' | Format-Table FeatureName, State
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -in 'HypervisorPlatform', 'VirtualMachinePlatform' | Format-Table FeatureName, State
   Get-LocalGroupMember -SID 'S-1-5-32-578' | Format-Table Name, ObjectClass
   ```

   - `Admin : True`、`Arch : AMD64`、`Edition` が `Professional`（か `Enterprise`・`Education`）ならよい
   - `Admin` が `False` なら、管理者ではない窓に貼っている。閉じて、この項の手順 1 から
   - `Edition` が `Core`（Home）なら、Hyper-V は入らない。ここで止める
   - `Hypervisor` が `False` で `VirtFirmware` も `False` なら、PC の UEFI（BIOS）の設定で Intel VT-x / AMD-V（SVM）を有効にしてから始める
   - `Microsoft-Hyper-V-All` が `Enabled` なら、もう有効。[Hyper-V を有効にして再起動する](#hyper-v-を有効にして再起動する)の手順 1 は飛ばす
   - 最後の表（Hyper-V Administrators の一員）は、空でよい

### Hyper-V を有効にして再起動する

1. Hyper-V を有効にする。

   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All -NoRestart
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -like 'Microsoft-Hyper-V*' | Format-Table FeatureName, State
   ```

   - `Microsoft-Hyper-V-All`・`Microsoft-Hyper-V-Hypervisor`・`Microsoft-Hyper-V-Services`・`Microsoft-Hyper-V-Management-PowerShell` が `Enabled` か `EnablePending` ならよい
   - **まだ再起動しない**（この項の手順 4 でまとめて行う）

1. VirtualBox か VMware Workstation も同じ PC で使うときだけ、Windows ハイパーバイザー プラットフォームも有効にする。

   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -in 'HypervisorPlatform', 'VirtualMachinePlatform' | Format-Table FeatureName, State
   ```

   - `HypervisorPlatform` が `Enabled` か `EnablePending` ならよい
   - **再起動の後、VirtualBox と VMware Workstation の VM は Windows のハイパーバイザーの上で動き、遅くなることがある**。再起動の後に、既存の VM が起動するかを確かめる

1. 自分のユーザーを Hyper-V Administrators に足す。

   ```powershell
   $HV_USER = "$env:USERDOMAIN\$env:USERNAME"
   if ((Get-LocalGroupMember -SID 'S-1-5-32-578' -ErrorAction SilentlyContinue).Name -contains $HV_USER) { "すでに一員: $HV_USER" } else { Add-LocalGroupMember -SID 'S-1-5-32-578' -Member $HV_USER }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-LocalGroupMember -SID 'S-1-5-32-578' | Format-Table Name, ObjectClass
   ```

   - 表に、ふだんログインするユーザーが出ればよい
   - 別の管理者のユーザーで昇格した窓では、`$HV_USER` がその管理者になる。表のユーザーが違ったら、`Add-LocalGroupMember -SID 'S-1-5-32-578' -Member '<PC 名>\<ふだんのユーザー>'` を打って足す

1. 再起動する。

   ```powershell
   Restart-Computer
   ```

   - **開いている作業を保存し、動いている VM（VirtualBox など）を止めてから貼る**（確認を聞かずに再起動が始まる）
   - VMware Workstation も続けて入れるなら、再起動の前に [VMware Workstation Pro の「インストールする」の手順 1](vmware.md#インストールする) まで済ませると、再起動は 1 回で済む（同じ項の手順 2 の再起動は、この手順が兼ねる）
   - **次の手順は、起動してサインインしてから行う**

### 再起動の後に確かめる

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. Hyper-V の管理のコマンドが、昇格せずに使えるかを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   whoami /groups | Select-String -Pattern 'S-1-5-32-578'
   Get-Service -Name vmms, vmcompute | Format-Table Name, Status, StartType
   Get-VMHost | Format-List LogicalProcessorCount, VirtualMachinePath, VirtualHardDiskPath
   Get-VMSwitch | Format-Table Name, SwitchType
   ```

   - `S-1-5-32-578` の行が出て、`vmms` が `Running` ならよい
   - `Get-VMSwitch` に `Default Switch` が出る
   - `Get-VMHost` が権限のエラーになったら、ログインし直していない。サインアウトしてサインインし直す

### VM を作る

1. 変数を設定する（`HV_ISO` は必ず値を入れる）。

   ```powershell
   $HV_ISO = ''
   ```

   ```powershell
   $HV_VM = 'alma10'
   $HV_DIR = "$env:USERPROFILE\Hyper-V"
   $HV_CPU = 2
   $HV_MEM = 4GB
   $HV_DISK = 64GB
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ HV_ISO = $HV_ISO; HV_VM = $HV_VM; HV_DIR = $HV_DIR; HV_CPU = $HV_CPU; HV_MEM_GB = $HV_MEM / 1GB; HV_DISK_GB = $HV_DISK / 1GB } | Format-List
   ```

   - `$HV_ISO` は、入れる OS のインストール用の ISO のパス
   - `$HV_VM` は VM の名前、`$HV_DIR` は VM を置くフォルダー（その下に VM の名前のフォルダーができる）
   - 新しい窓を開いたら、この手順を貼り直す

1. 第 2 世代の VM を作り、ISO を付ける。

   ```powershell
   if (-not $HV_ISO) { Write-Error '中断: この項の手順 1 の $HV_ISO が空のまま。値を入れて貼り直す' } elseif (-not (Test-Path -LiteralPath $HV_ISO)) { Write-Error "中断: ISO が無い: $HV_ISO" } elseif (Get-VM -Name $HV_VM -ErrorAction SilentlyContinue) { Write-Error "中断: 同じ名前の VM がすでにある: $HV_VM" } else {
     New-VM -Name $HV_VM -Generation 2 -MemoryStartupBytes $HV_MEM -Path $HV_DIR -NewVHDPath "$HV_DIR\$HV_VM\$HV_VM.vhdx" -NewVHDSizeBytes $HV_DISK -SwitchName 'Default Switch' | Out-Null
     Set-VM -Name $HV_VM -ProcessorCount $HV_CPU -StaticMemory -AutomaticCheckpointsEnabled $false -CheckpointType Standard
     Set-VMFirmware -VMName $HV_VM -FirstBootDevice (Add-VMDvdDrive -VMName $HV_VM -Path $HV_ISO -Passthru)
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-VM -Name $HV_VM | Format-List Name, State, Generation, Version, ProcessorCount, DynamicMemoryEnabled, AutomaticCheckpointsEnabled, Path
     Get-VMFirmware -VMName $HV_VM | Format-List SecureBoot, SecureBootTemplate
   }
   ```

   - `State : Off`、`Generation : 2`、`DynamicMemoryEnabled : False`、`AutomaticCheckpointsEnabled : False` が出ればよい
   - `SecureBoot : On`、`SecureBootTemplate : MicrosoftWindows` が出る

1. Linux を入れるときだけ、Secure Boot のテンプレートを Linux 用に変える。

   ```powershell
   Set-VMFirmware -VMName $HV_VM -SecureBootTemplate MicrosoftUEFICertificateAuthority
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VMFirmware -VMName $HV_VM | Format-List SecureBoot, SecureBootTemplate
   ```

   - `SecureBootTemplate : MicrosoftUEFICertificateAuthority` が出ればよい
   - **変えないままだと、Linux の ISO からは起動しない**（VM の画面に `Start PXE over IPv4` が出る）
   - Secure Boot を切って入れるなら、代わりに `Set-VMFirmware -VMName $HV_VM -EnableSecureBoot Off` を打つ

1. Windows 11 を入れるときだけ、仮想 TPM を付ける。

   ```powershell
   Set-VMKeyProtector -VMName $HV_VM -NewLocalKeyProtector
   Enable-VMTPM -VMName $HV_VM
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VMSecurity -VMName $HV_VM | Format-List TpmEnabled
   ```

   - `TpmEnabled : True` が出ればよい

### VM を起動して OS を入れる

1. VM を起動し、VM の画面を開く。

   ```powershell
   Start-VM -Name $HV_VM
   vmconnect.exe localhost $HV_VM
   ```

   - VM の画面のウィンドウが開く

1. VM の画面で、OS のインストーラーを最後まで進める。

   - Windows の ISO は、起動の直後に `Press any key to boot from CD or DVD` が出ているあいだに、VM の画面をクリックしてキーを押す
   - インストーラーが最後に再起動するか、電源を切るまで進める
   - **次の手順は、インストールが終わってから貼る**

1. ISO を付けた DVD ドライブを、VM から外す。

   ```powershell
   Get-VMDvdDrive -VMName $HV_VM | Remove-VMDvdDrive
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   "DVD ドライブの数: $(@(Get-VMDvdDrive -VMName $HV_VM).Count)"
   ```

   - `DVD ドライブの数: 0` が出ればよい

### 動作を確かめる

1. VM の状態と、ゲストの IP を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VM -Name $HV_VM | Format-List Name, State, Uptime, Status
   Get-VMNetworkAdapter -VMName $HV_VM | Format-Table Name, SwitchName, MacAddress, IPAddresses
   ```

   - `State : Running` で、`IPAddresses` にゲストの IP が出ればよい
   - VM が止まっていたら、先に `Start-VM -Name $HV_VM` を打つ
   - `IPAddresses` が空のまま変わらないなら、ゲストに Hyper-V のデーモンが入っていない。VM の画面でログインして IP を見る（AlmaLinux 10 の Workstation には `hyperv-daemons` が入っている）

1. Linux のゲストなら、この PC から SSH で入れるかを確かめる。

   - この窓で `ssh <ゲストのユーザー>@<ゲストの IP>` を打つ（IP はこの項の手順 1 の `IPAddresses`）
   - ゲストのプロンプトが出ればよい。`exit` で戻る
   - ゲストの IP は固定ではない。つなぐ前に、この項の手順 1 で引き直す

---

## 使い方の基本

- 管理者ではない Windows PowerShell（5.1）で打つ。`<VM 名>` は VM の名前

| すること | コマンド |
|---|---|
| VM の一覧 | `Get-VM` |
| 起動する | `Start-VM -Name <VM 名>` |
| ゲストに電源を切らせる | `Stop-VM -Name <VM 名>` |
| 電源を切る（ゲストに知らせない） | `Stop-VM -Name <VM 名> -TurnOff` |
| VM の画面を開く | `vmconnect.exe localhost <VM 名>` |
| ゲストの IP を見る | `(Get-VMNetworkAdapter -VMName <VM 名>).IPAddresses` |
| CPU の数を変える（止めてから） | `Set-VM -Name <VM 名> -ProcessorCount 4` |
| メモリを変える（止めてから） | `Set-VM -Name <VM 名> -MemoryStartupBytes 8GB` |

---

## チェックポイントとクローン

- チェックポイントは、VM のその時点の状態。戻したり、そこから別の VM を作ったりできる
- 管理者ではない Windows PowerShell（5.1）に貼る。[VM を作る](#vm-を作る)の手順 1 の変数を使う

> [!WARNING]
> **この節の手順 3 で作った VM があるあいだは、元の VM のチェックポイントを消さない**。消すと元のディスクが書き換わり、そこから作った VM がすべて起動しなくなる。

1. VM を止めて、チェックポイントを取る。

   ```powershell
   $HV_CHECKPOINT = 'clean-install'
   Stop-VM -Name $HV_VM
   Checkpoint-VM -Name $HV_VM -SnapshotName $HV_CHECKPOINT
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VMSnapshot -VMName $HV_VM | Format-Table VMName, Name, SnapshotType, CreationTime
   ```

   - 付けた名前のチェックポイントが出ればよい
   - VM がすでに止まっていれば、`Stop-VM` は警告を出して何もしない

1. VM をチェックポイントの時点に戻すときは、VM を止めてから戻す。

   ```powershell
   Stop-VM -Name $HV_VM -TurnOff
   Restore-VMSnapshot -VMName $HV_VM -Name $HV_CHECKPOINT -Confirm:$false
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VM -Name $HV_VM | Format-List Name, State, ParentCheckpointName
   ```

   - **チェックポイントより後の変更は消える**
   - `ParentCheckpointName` に、戻した先の名前が出ればよい
   - VM がすでに止まっていれば、`Stop-VM` は警告を出して何もしない

1. チェックポイントの時点から、差分ディスクで別の VM を作る。

   ```powershell
   $HV_CLONE = "$HV_VM-clone"
   if (Get-VM -Name $HV_CLONE -ErrorAction SilentlyContinue) { Write-Error "中断: 同じ名前の VM がすでにある: $HV_CLONE" } else {
     $parent = (Get-VMHardDiskDrive -VMSnapshot (Get-VMSnapshot -VMName $HV_VM -Name $HV_CHECKPOINT) | Select-Object -First 1).Path
     New-Item -ItemType Directory -Path "$HV_DIR\$HV_CLONE" | Out-Null
     New-VHD -Path "$HV_DIR\$HV_CLONE\$HV_CLONE.vhdx" -ParentPath $parent -Differencing | Out-Null
     New-VM -Name $HV_CLONE -Generation 2 -MemoryStartupBytes (Get-VM -Name $HV_VM).MemoryStartup -Path $HV_DIR -VHDPath "$HV_DIR\$HV_CLONE\$HV_CLONE.vhdx" -SwitchName 'Default Switch' | Out-Null
     Set-VM -Name $HV_CLONE -ProcessorCount (Get-VM -Name $HV_VM).ProcessorCount -StaticMemory -AutomaticCheckpointsEnabled $false -CheckpointType Standard
     $firmware = Get-VMFirmware -VMName $HV_VM
     if ($firmware.SecureBoot -eq 'On') { Set-VMFirmware -VMName $HV_CLONE -EnableSecureBoot On -SecureBootTemplate $firmware.SecureBootTemplate } else { Set-VMFirmware -VMName $HV_CLONE -EnableSecureBoot Off }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-VHD -Path "$HV_DIR\$HV_CLONE\$HV_CLONE.vhdx" | Format-List VhdType, ParentPath
     Get-VM -Name $HV_CLONE | Format-List Name, State, ProcessorCount, MemoryStartup
   }
   ```

   - `VhdType : Differencing` と、元の VM のディスクを指す `ParentPath` が出ればよい
   - 新しい VM は、ホスト名もログインも元の VM と同じ。起動してから、ゲストの中でホスト名を変える
   - 仮想 TPM と、ファームウェアに登録した鍵（MOK など）は引き継がれない

---

## VM どうしだけがつながるスイッチを作る（任意）

- Private のスイッチは、つないだ VM どうしだけが通信できる（この PC とも、インターネットともつながらない）
- 管理者ではない Windows PowerShell（5.1）に貼る。IP は配られないので、ゲストの中で固定の IP を付ける

1. スイッチを作り、止めてある VM に 2 枚目の NIC として付ける。

   ```powershell
   $HV_SWITCH = 'lab-lan'
   $switch = Get-VMSwitch -Name $HV_SWITCH -ErrorAction SilentlyContinue
   if ($switch -and $switch.SwitchType -ne 'Private') { Write-Error "中断: 同じ名前で、Private ではないスイッチがある: $HV_SWITCH" } else {
     if (-not $switch) { New-VMSwitch -Name $HV_SWITCH -SwitchType Private | Out-Null }
     Add-VMNetworkAdapter -VMName $HV_VM -SwitchName $HV_SWITCH
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-VMSwitch -Name $HV_SWITCH | Format-Table Name, SwitchType
     Get-VMNetworkAdapter -VMName $HV_VM | Format-Table Name, SwitchName, MacAddress
   }
   ```

   - `SwitchType` が `Private` のスイッチと、VM の 2 枚の NIC（`Default Switch` と、作ったスイッチ）が出ればよい
   - `中断: 同じ名前で、Private ではないスイッチがある` と出たら、`$HV_SWITCH` を別の名前にして貼り直す
   - つなぐ相手の VM にも、`$HV_VM` を相手の名前に変えて `Add-VMNetworkAdapter` の行を打つ

---

## VM を消す

> [!CAUTION]
> **この節の手順 1 は、VM のディスクごと消す（取り戻せない）**。[チェックポイントとクローン](#チェックポイントとクローン)の手順 3 で、この VM から作った VM が残っているなら、先にそちらを消す。

1. VM を止めて、登録とファイルを消す（取り戻せない）。

   ```powershell
   $HV_REMOVE = ''
   ```

   ```powershell
   if (-not $HV_REMOVE) { Write-Error '中断: $HV_REMOVE が空のまま。消す VM の名前を入れて貼り直す' } elseif (-not (Get-VM -Name $HV_REMOVE -ErrorAction SilentlyContinue)) { Write-Error "中断: VM が無い: $HV_REMOVE" } else {
     $dir = (Get-VM -Name $HV_REMOVE).Path.TrimEnd('\')
     $others = @(Get-VM | Where-Object Name -ne $HV_REMOVE)
     $disks = @($others | Get-VMHardDiskDrive | ForEach-Object { $_.Path; (Get-VHD -Path $_.Path).ParentPath })
     if ((Split-Path -Leaf $dir) -ne $HV_REMOVE) { Write-Error "中断: VM のフォルダーが、VM の名前のフォルダーではない: $dir" } elseif (($others | Where-Object { $_.Path.TrimEnd('\') -eq $dir }) -or ($disks | Where-Object { $_ -like "$dir\*" })) { Write-Error "中断: ほかの VM が、このフォルダーのファイルを使っている: $dir" } else {
       Stop-VM -Name $HV_REMOVE -TurnOff -Force -WarningAction SilentlyContinue
       Remove-VM -Name $HV_REMOVE -Force -ErrorAction Stop
       Remove-Item -LiteralPath $dir -Recurse -Force
       "`n$([char]27)[7m 確認 $([char]27)[0m"
       Get-VM | Format-Table Name, State
       Test-Path -LiteralPath $dir
     }
   }
   ```

   - 一覧から VM が消え、最後に `False` が出ればよい
   - `中断: VM のフォルダーが、VM の名前のフォルダーではない` と出たら、本書の[VM を作る](#vm-を作る)で作った VM ではない。このブロックでは消さない（Hyper-V マネージャーで消す）
   - `中断: ほかの VM が、このフォルダーのファイルを使っている` と出たら、この VM から作った VM を先に消す

---
