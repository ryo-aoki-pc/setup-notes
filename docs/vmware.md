# VMware Workstation Pro のインストールと VM の作成（Windows 11）

## 実施手順

- [検証記録](verification/vmware.md)・[参考資料](reference/vmware.md)・[ロールバックと注意点](extra/vmware.md)

> [!IMPORTANT]
> - **Windows 11（x64）の PC のデスクトップで行う**（インストーラーはネットワークのドライバーを入れる。SSH やリモート デスクトップのセッションからは確かめていない）
> - [インストーラーを取得して確かめる](#インストーラーを取得して確かめる)の手順 2 で**管理者の** Windows PowerShell（5.1）を開き、[インストールする](#インストールする)までのブロックをそこに貼る。[入ったかを確かめる](#入ったかを確かめる)から後ろは、**管理者ではない** Windows PowerShell に貼る
> - ログインするユーザーは Administrators の一員（VMware Workstation は PC 全体に入り、ドライバーを入れる）
> - 前提: [Windows 11 の初期設定の「貼り付けの設定」の手順 1〜4](windows-setup.md#貼り付けの設定)。通していなければ、ブロックは Ctrl+V で貼る
> - **インストーラーの取得には Broadcom のアカウントが要る**（個人利用は無償。winget には無い）
> - **同じ PC で Hyper-V や WSL 2 を使うなら、先に Windows ハイパーバイザー プラットフォームを有効にする**（[Hyper-V の「Hyper-V を有効にして再起動する」の手順 2](hyper-v.md#hyper-v-を有効にして再起動する)）。有効にした直後で再起動待ちなら、[インストールする](#インストールする)の手順 2 で再起動する

- 上から順にコードブロックを貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 手順の後: ふだんの操作は[使い方の基本](#使い方の基本)、状態を残す・複製するなら[スナップショットとクローン](#スナップショットとクローン)、要らなくなった VM は[VM を消す](#vm-を消す)

### インストーラーを取得して確かめる

1. ブラウザで Broadcom のサポート ポータルにログインし、VMware Workstation Pro の Windows 用のインストーラーを「ダウンロード」フォルダーに保存する。

   - ファイル名は `VMware-Workstation-Full-<版>-<ビルド番号>.exe` の形
   - **次の手順は、ダウンロードが終わってから行う**

1. Windows のデスクトップで、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. 変数を設定する（取得したインストーラーのパスが自動で入る。違えば直す）。

   ```powershell
   $VMW_SETUP = (Get-ChildItem -LiteralPath "$env:USERPROFILE\Downloads" -Filter 'VMware-Workstation-Full-*.exe' | Sort-Object LastWriteTime | Select-Object -Last 1).FullName
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $VMW_SETUP
   ```

   - いま取得したファイルのパスが出ればよい
   - **ファイル名の版とビルド番号が、取得したものと同じことを確かめる**（古いインストーラーが同じフォルダーにあると、そちらが出ることがある）
   - 違うファイルが出たときと、何も出ないとき（別の場所に保存した）は、`$VMW_SETUP = '<インストーラーのパス>'` を打って入れ直す

1. インストーラーの署名と版を確かめる。

   ```powershell
   if (-not $VMW_SETUP) { Write-Error '中断: この項の手順 3 の $VMW_SETUP が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-AuthenticodeSignature -LiteralPath $VMW_SETUP | Format-List Status, @{ n = 'Signer'; e = { $_.SignerCertificate.Subject } }
     (Get-Item -LiteralPath $VMW_SETUP).VersionInfo | Format-List ProductName, ProductVersion
   }
   ```

   - `Status : Valid` と、`Signer` に `Broadcom Inc` が出ればよい
   - **`Status` が `Valid` でなければ中断する**（ファイルを消して取得し直す）
   - `ProductVersion` が取得した版と違えば中断し、この項の手順 3 から直す

### インストールする

1. 使用許諾契約に同意して、画面無しでインストールする。

   ```powershell
   if (-not $VMW_SETUP) { Write-Error '中断: インストーラーを取得して確かめるの手順 3 の $VMW_SETUP が空のまま。その手順から貼り直す' } else {
     $p = Start-Process -FilePath $VMW_SETUP -ArgumentList '/s /v"/qn EULAS_AGREED=1 AUTOSOFTWAREUPDATE=0 DATACOLLECTION=0 REBOOT=ReallySuppress"' -Wait -PassThru
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     "ExitCode = $($p.ExitCode)"
   }
   ```

   - **注意**: `EULAS_AGREED=1` を付けて実行すると、VMware Workstation Pro の使用許諾契約に同意したことになる。契約を画面で読んでから進めるなら、このブロックは貼らずに、インストーラーをダブルクリックして画面で進める
   - `ExitCode = 0` なら入った。`ExitCode = 3010` は、入ったが再起動が要る
   - それ以外の値なら中断する（`%TEMP%` の `vminst.log` を見る）
   - `ExitCode = 0` で、Windows の機能の再起動待ちも無いなら、この項の手順 2 は飛ばす

1. `ExitCode = 3010` のときと、Windows の機能（Hyper-V など）が再起動待ちのときだけ、再起動する。

   ```powershell
   Restart-Computer
   ```

   - **開いている作業を保存し、動いている VM を止めてから貼る**（確認を聞かずに再起動が始まる）
   - Hyper-V の手順書の途中から来たなら、[Hyper-V の「Hyper-V を有効にして再起動する」の手順 4](hyper-v.md#hyper-v-を有効にして再起動する)の再起動がこれに当たる（再起動は 1 回でよい）
   - **次の手順は、起動してサインインしてから行う**

### 入ったかを確かめる

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 入った版と、コマンドの場所、仮想ネットワークを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $VMW_DIR = @("$env:ProgramFiles\VMware\VMware Workstation", "${env:ProgramFiles(x86)}\VMware\VMware Workstation") | Where-Object { Test-Path -LiteralPath "$_\vmrun.exe" } | Select-Object -First 1
   if (-not $VMW_DIR) { Write-Error 'vmrun.exe が見つからない。インストールできていない' } else {
     $VMW_DIR
     (Get-Item -LiteralPath "$VMW_DIR\vmware.exe").VersionInfo | Format-List ProductName, ProductVersion
     & "$VMW_DIR\vmrun.exe" -T ws list
     Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'VMware Network Adapter*' | Format-Table InterfaceAlias, IPAddress, PrefixLength
   }
   ```

   - インストール先のフォルダーと版が出て、`Total running VMs: 0` が出ればよい
   - `VMware Network Adapter VMnet1`（この PC と VM だけ）と `VMnet8`（NAT）の行が出る

### VM を作る

1. 変数を設定する（`VMW_ISO` は必ず値を入れる）。

   ```powershell
   $VMW_ISO = ''
   ```

   ```powershell
   $VMW_VM = 'alma10'
   $VMW_BASE = "$env:USERPROFILE\VMware"
   $VMW_GUEST = 'almalinux-64'
   $VMW_CPU = 2
   $VMW_MEM_MB = 4096
   $VMW_DISK = '64GB'
   $VMW_DIR = @("$env:ProgramFiles\VMware\VMware Workstation", "${env:ProgramFiles(x86)}\VMware\VMware Workstation") | Where-Object { Test-Path -LiteralPath "$_\vmrun.exe" } | Select-Object -First 1
   $VMW_VMX = "$VMW_BASE\$VMW_VM\$VMW_VM.vmx"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ VMW_ISO = $VMW_ISO; VMW_VM = $VMW_VM; VMW_VMX = $VMW_VMX; VMW_GUEST = $VMW_GUEST; VMW_CPU = $VMW_CPU; VMW_MEM_MB = $VMW_MEM_MB; VMW_DISK = $VMW_DISK; VMW_DIR = $VMW_DIR } | Format-List
   ```

   - `$VMW_ISO` は、入れる OS のインストール用の ISO のパス
   - `$VMW_VM` は VM の名前、`$VMW_BASE` は VM を置くフォルダー（その下に VM の名前のフォルダーができる）
   - `$VMW_GUEST` は入れる OS の種類（既定は AlmaLinux）。本書は、Windows 11 を入れる VM（仮想 TPM が要る）を扱わない
   - `VMW_DIR` が空なら、VMware Workstation が入っていない。[インストールする](#インストールする)から
   - 新しい窓を開いたら、この手順を貼り直す

1. VM の設定ファイルとディスクを作る。

   ```powershell
   if (-not $VMW_ISO) { Write-Error '中断: この項の手順 1 の $VMW_ISO が空のまま。値を入れて貼り直す' } elseif (-not (Test-Path -LiteralPath $VMW_ISO)) { Write-Error "中断: ISO が無い: $VMW_ISO" } elseif (Test-Path -LiteralPath "$VMW_BASE\$VMW_VM") { Write-Error "中断: 同じ名前のフォルダーがすでにある: $VMW_BASE\$VMW_VM" } else {
     & "$VMW_DIR\vmcli.exe" VM Create -n $VMW_VM -d "$VMW_BASE\$VMW_VM" -c $VMW_GUEST
     Remove-Item -LiteralPath "$VMW_BASE\$VMW_VM\$VMW_VM.vmdk"
     & "$VMW_DIR\vmcli.exe" $VMW_VMX Disk Create -f "$VMW_BASE\$VMW_VM\$VMW_VM.vmdk" -a lsilogic -s $VMW_DISK -t 0
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ChildItem -LiteralPath "$VMW_BASE\$VMW_VM" | Format-Table Name, Length
   }
   ```

   - `VMX file is created` と `Virtual disk file creation is successful` が出て、一覧に `.vmx` と `.vmdk` が並べばよい

1. ファームウェア・CPU・メモリ・ディスク・ISO・NIC を設定する。

   ```powershell
   $vmcli = "$VMW_DIR\vmcli.exe"
   & $vmcli $VMW_VMX ConfigParams SetEntry displayName $VMW_VM
   & $vmcli $VMW_VMX ConfigParams SetEntry firmware efi
   & $vmcli $VMW_VMX ConfigParams SetEntry cpuid.coresPerSocket $VMW_CPU
   & $vmcli $VMW_VMX Chipset SetVCpuCount $VMW_CPU
   & $vmcli $VMW_VMX Chipset SetMemSize $VMW_MEM_MB
   & $vmcli $VMW_VMX MKS SetAccel3d false
   & $vmcli $VMW_VMX Nvme SetPresent nvme0 1
   & $vmcli $VMW_VMX Disk SetBackingInfo nvme0:0 disk "$VMW_BASE\$VMW_VM\$VMW_VM.vmdk" 0
   & $vmcli $VMW_VMX Disk SetPresent nvme0:0 1
   & $vmcli $VMW_VMX Sata SetPresent sata0 1
   & $vmcli $VMW_VMX Disk SetBackingInfo sata0:0 cdrom_image $VMW_ISO 0
   & $vmcli $VMW_VMX Disk SetPresent sata0:0 1
   & $vmcli $VMW_VMX Ethernet SetVirtualDevice ethernet0 vmxnet3
   & $vmcli $VMW_VMX Ethernet SetConnectionType ethernet0 nat
   & $vmcli $VMW_VMX Ethernet SetPresent ethernet0 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Content -LiteralPath $VMW_VMX | Select-String -Pattern '^(displayName|guestOS|firmware|numvcpus|memsize|mks\.enable3d|nvme0|sata0|ethernet0)'
   ```

   - `firmware = "efi"`、`numvcpus`、`memsize`、`nvme0:0.fileName`、`sata0:0.fileName`（ISO）、`ethernet0.connectionType = "nat"` の行が出ればよい
   - `mks.enable3d` の行は出ない（3D を切った）

### VM を起動して OS を入れる

1. VM を起動する。

   ```powershell
   & "$VMW_DIR\vmrun.exe" -T ws start $VMW_VMX
   ```

   - `PID: <番号>, log output: <ログのパス>` の 1 行が出て、VMware Workstation のウィンドウが開き、VM が起動する

1. VM の画面で、OS のインストーラーを最後まで進める。

   - VM の画面をクリックすると、キーとマウスが VM に入る。Ctrl+Alt でこの PC に戻る
   - インストーラーが最後に再起動するか、電源を切るまで進める
   - **次の手順は、インストールが終わり、VM の電源を切ってから貼る**

1. ISO を外す。

   ```powershell
   & "$VMW_DIR\vmcli.exe" $VMW_VMX Disk SetPresent sata0:0 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   "sata0:0.present の行の数: $(@(Select-String -LiteralPath $VMW_VMX -Pattern '^sata0:0\.present').Count)"
   ```

   - `sata0:0.present の行の数: 0` が出ればよい

### 動作を確かめる

1. VM を画面無しで起動し、Hyper-V の上で動いているかと、ゲストの IP を確かめる。

   ```powershell
   & "$VMW_DIR\vmrun.exe" -T ws start $VMW_VMX nogui
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$VMW_DIR\vmrun.exe" -T ws list
   Select-String -LiteralPath "$VMW_BASE\$VMW_VM\vmware.log" -Pattern 'Monitor Mode:' | Select-Object -Last 1 | ForEach-Object { ($_.Line -split '\] ')[-1] }
   & "$VMW_DIR\vmrun.exe" -T ws readVariable $VMW_VMX guestVar ip
   ```

   - `Total running VMs: 1` と、VM の `.vmx` のパスが出ればよい
   - **`Monitor Mode: ULM` なら、VM は Windows のハイパーバイザー（Hyper-V）の上で動いている**（遅くなる）
   - 最後の行にゲストの IP が出る。空なら、ゲストがまだ起動の途中。少し待って、最後の行だけを打ち直す
   - ゲストに VMware Tools（Linux は `open-vm-tools`）が入っていないと、IP は出ない（AlmaLinux 10 の Workstation には入っている）

1. Linux のゲストなら、この PC から SSH で入れるかを確かめる。

   - この窓で `ssh <ゲストのユーザー>@<ゲストの IP>` を打つ（IP はこの項の手順 1 の最後の行）
   - ゲストのプロンプトが出ればよい。`exit` で戻る

---

## 使い方の基本

- 管理者ではない Windows PowerShell（5.1）で打つ。`<vmx>` は VM の `.vmx` のパス。コマンドは VMware Workstation のフォルダーにある（[VM を作る](#vm-を作る)の手順 1 の `$VMW_DIR`）

| すること | コマンド |
|---|---|
| 動いている VM の一覧 | `vmrun.exe -T ws list` |
| 起動する（ウィンドウを開く） | `vmrun.exe -T ws start <vmx>` |
| 起動する（画面無し） | `vmrun.exe -T ws start <vmx> nogui` |
| ゲストに電源を切らせる | `vmrun.exe -T ws stop <vmx> soft` |
| 電源を切る（ゲストに知らせない） | `vmrun.exe -T ws stop <vmx> hard` |
| ゲストの IP を見る | `vmrun.exe -T ws readVariable <vmx> guestVar ip` |
| 画面を PNG に撮る | `vmcli.exe <vmx> MKS captureScreenshot <PNG のパス>` |
| 画面に文字を打つ | `vmcli.exe <vmx> MKS sendKeySequence <文字列>` |
| CPU の数を変える（止めてから） | `vmcli.exe <vmx> Chipset SetVCpuCount 4` |
| メモリを変える（止めてから） | `vmcli.exe <vmx> Chipset SetMemSize 8192` |

---

## スナップショットとクローン

- スナップショットは、VM のその時点の状態。戻したり、そこから別の VM（リンククローン）を作ったりできる
- 管理者ではない Windows PowerShell（5.1）に貼る。[VM を作る](#vm-を作る)の手順 1 の変数を使う

> [!WARNING]
> **この節の手順 3 で作った VM があるあいだは、元の VM とそのスナップショットを消さない**。リンククローンは元の VM のディスクを読むので、消すと起動しなくなる。

1. VM を止めて、スナップショットを取る。

   ```powershell
   $VMW_SNAPSHOT = 'clean-install'
   & "$VMW_DIR\vmrun.exe" -T ws stop $VMW_VMX soft
   & "$VMW_DIR\vmrun.exe" -T ws snapshot $VMW_VMX $VMW_SNAPSHOT
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$VMW_DIR\vmrun.exe" -T ws listSnapshots $VMW_VMX
   ```

   - `Total snapshots: 1` と、付けた名前が出ればよい
   - VM がすでに止まっていれば、`stop` は `Error: The virtual machine is not powered on` を出す（そのまま進んでよい）

1. VM をスナップショットの時点に戻すときは、VM を止めてから戻す。

   ```powershell
   & "$VMW_DIR\vmrun.exe" -T ws stop $VMW_VMX hard
   & "$VMW_DIR\vmrun.exe" -T ws revertToSnapshot $VMW_VMX $VMW_SNAPSHOT
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$VMW_DIR\vmrun.exe" -T ws listSnapshots $VMW_VMX
   ```

   - **スナップショットより後の変更は消える**
   - VM がすでに止まっていれば、`stop` は `Error: The virtual machine is not powered on` を出す（そのまま進んでよい）

1. スナップショットの時点から、リンククローンで別の VM を作る。

   ```powershell
   $VMW_CLONE = "$VMW_VM-clone"
   if (Test-Path -LiteralPath "$VMW_BASE\$VMW_CLONE") { Write-Error "中断: 同じ名前のフォルダーがすでにある: $VMW_BASE\$VMW_CLONE" } else {
     & "$VMW_DIR\vmrun.exe" -T ws clone $VMW_VMX "$VMW_BASE\$VMW_CLONE\$VMW_CLONE.vmx" linked "-snapshot=$VMW_SNAPSHOT" "-cloneName=$VMW_CLONE"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ChildItem -LiteralPath "$VMW_BASE\$VMW_CLONE" | Format-Table Name, Length
     Get-Content -LiteralPath "$VMW_BASE\$VMW_CLONE\$VMW_CLONE.vmx" | Select-String -Pattern '^(displayName|nvme0:0\.fileName)'
   }
   ```

   - 新しいフォルダーに `.vmx` と、小さい `.vmdk`（差分）ができればよい
   - 新しい VM は、ホスト名もログインも元の VM と同じ。起動してから、ゲストの中でホスト名を変える
   - 新しい VM を起動するのは `& "$VMW_DIR\vmrun.exe" -T ws start "$VMW_BASE\$VMW_CLONE\$VMW_CLONE.vmx" nogui`、IP を読むのは `& "$VMW_DIR\vmrun.exe" -T ws readVariable "$VMW_BASE\$VMW_CLONE\$VMW_CLONE.vmx" guestVar ip`

---

## VM を消す

> [!CAUTION]
> **この節の手順 1 は、VM のディスクごと消す（取り戻せない）**。[スナップショットとクローン](#スナップショットとクローン)の手順 3 で、この VM から作った VM が残っているなら、先にそちらを消す。

- 管理者ではない Windows PowerShell（5.1）に貼る。[VM を作る](#vm-を作る)の手順 1 の変数（`$VMW_DIR`）を使う

1. VM を止めて、登録とファイルを消す（取り戻せない）。

   ```powershell
   $VMW_REMOVE = ''
   ```

   ```powershell
   if (-not $VMW_REMOVE) { Write-Error '中断: $VMW_REMOVE が空のまま。消す VM の .vmx のパスを入れて貼り直す' } elseif (-not (Test-Path -LiteralPath $VMW_REMOVE)) { Write-Error "中断: .vmx が無い: $VMW_REMOVE" } else {
     & "$VMW_DIR\vmrun.exe" -T ws stop $VMW_REMOVE hard
     & "$VMW_DIR\vmrun.exe" -T ws deleteVM $VMW_REMOVE
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     & "$VMW_DIR\vmrun.exe" -T ws list
     Test-Path -LiteralPath $VMW_REMOVE
   }
   ```

   - 最後に `False` が出ればよい
   - VM が止まっていれば、`stop` は `Error: The virtual machine is not powered on` を出す（そのまま進んでよい）

---
