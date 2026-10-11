# Hyper-V の有効化と VM の作成（Windows 11 Pro）の検証記録

[手順書](../hyper-v.md)・[参考資料](../reference/hyper-v.md)・[ロールバックと注意点](../extra/hyper-v.md)

## 対象と検証環境

- **目的**: Windows 11 Pro の PC で Hyper-V を有効にし、管理者ではない窓から VM を作る・入れる・チェックポイントを取る・複製する・消すまでを、手順書のブロックで確かめる
- **状態**: **Windows 11 Pro の実機で、有効化から VM の削除までを通した（2026-10-11、JST）**
  - 利用者が実施したこと
    - [この PC で使えるかを確かめる](../hyper-v.md#この-pc-で使えるかを確かめる)の手順 1・2 と、[Hyper-V を有効にして再起動する](../hyper-v.md#hyper-v-を有効にして再起動する)の手順 1〜4 を、管理者の Windows PowerShell に貼って実行し、再起動した
    - エージェントは、そのときの出力を見ていない。再起動の後に、状態を読み戻して確かめた
  - エージェントが、管理者ではない Windows PowerShell 5.1 で、手順書のブロックを 1 つずつ実行したこと
    - [再起動の後に確かめる](../hyper-v.md#再起動の後に確かめる)の手順 2
    - [VM を作る](../hyper-v.md#vm-を作る)の手順 1〜4（変数は検証用の値に置き換えた）
    - [VM を起動して OS を入れる](../hyper-v.md#vm-を起動して-os-を入れる)の手順 1 と、手順 3
    - [動作を確かめる](../hyper-v.md#動作を確かめる)の手順 1
    - [チェックポイントとクローン](../hyper-v.md#チェックポイントとクローン)の手順 1〜3、[VM どうしだけがつながるスイッチを作る（任意）](../hyper-v.md#vm-どうしだけがつながるスイッチを作る任意)の手順 1、[VM を消す](../hyper-v.md#vm-を消す)の手順 1
    - [ロールバック](../extra/hyper-v.md#ロールバック)の手順 1
  - 確認したこと
    - 管理者ではない窓から、VM の作成・起動・停止・チェックポイント・差分ディスクでの複製・削除、Private のスイッチの作成と削除、仮想 TPM の追加ができた
    - AlmaLinux 10.2 が、Secure Boot を切った VM と、Secure Boot を有効にした VM（Linux 用のテンプレート）の両方に入り、起動した
    - 掲載した PowerShell のブロックは、Windows PowerShell 5.1 と PowerShell 7 の構文解析でエラー 0
  - **確認していないこと**
    - [VM を起動して OS を入れる](../hyper-v.md#vm-を起動して-os-を入れる)の手順 2（画面でのインストーラーの操作）。OS は、応答ファイルを載せた 2 枚目の ISO で、画面を操作せずに入れた
    - 手順 1 の `vmconnect.exe` は、ウィンドウが開くことだけを確かめた。ウィンドウの中の表示と、キーとマウスの操作は確かめていない
    - [動作を確かめる](../hyper-v.md#動作を確かめる)の手順 2 の、手で打つ `ssh`（エージェントは、鍵を指定した `ssh` で入った）
    - Windows 11 をゲストに入れること、入れ子の仮想化、Internal と External のスイッチ
    - Hyper-V の機能を無効に戻すことと、Hyper-V Administrators から外すこと
    - Home エディションでの表示、Intel の CPU
- **今回の確認方法**: 手順書からコードブロックを取り出し、変数だけを検証用の値にして、Windows PowerShell 5.1 の新しいプロセスで 1 手順ずつ実行した。出力を手順書の箇条書きと照らした

| 項目 | 実測した値 |
|---|---|
| 検証日 | 2026-10-11、JST |
| ホスト | Windows 11 Pro 26H2、build `26300.9457`、x64 |
| CPU・メモリ | AMD Ryzen 9 5900X（12 コア・24 スレッド）、32 GB |
| 実行シェル | Windows PowerShell `5.1.26100.9444`（管理者ではない窓。ユーザーは Hyper-V Administrators の一員） |
| Hyper-V | `vmms.exe` `10.0.26100.8875`、PowerShell のモジュール `2.0.0.0`、VM の構成バージョンの既定 `12.0` |
| 同じ PC のほかの仮想化 | VirtualBox 7.2.20、VMware Workstation Pro 26H1u1（Hyper-V の機能を有効にした直後、再起動の前に導入）、WSL 2 |
| ゲスト | AlmaLinux 10.2（`AlmaLinux-10-latest-x86_64-boot.iso`、SHA256 `b3f865468075bcada8f208d830289302c67529789d668041d24e8d6fc697ba6a`）、kernel `6.12.0-211.64.1.el10_2.x86_64` |
| VM | 第 2 世代、2 vCPU、4 GiB（固定）、64 GiB の可変の VHDX、Default Switch |

> [!NOTE]
> VM の名前・フォルダー・スイッチの名前は、検証用の値（`vmv-hv-doc` など）に置き換えて実行した。ゲストの IP とホスト名は載せていない。ゲストのユーザーは検証用に作ったもので、パスワードと鍵は記録していない。

## 実施前の状態

- 機能は `VirtualMachinePlatform` だけが有効で、`Microsoft-Hyper-V-All` とその下の機能、`HypervisorPlatform` は無効だった
- `HypervisorPresent` は `True` だった（WSL 2 の仮想マシン プラットフォームで、Windows のハイパーバイザーが動いていた）
- Hyper-V Administrators のグループはあり、一員はいなかった
- `Get-VM` などのコマンドレットと、`vmms` のサービスは無かった

## 完了時点の状態

- `Microsoft-Hyper-V-All`・`Microsoft-Hyper-V`・`Microsoft-Hyper-V-Hypervisor`・`Microsoft-Hyper-V-Services`・`Microsoft-Hyper-V-Management-PowerShell`・`Microsoft-Hyper-V-Management-Clients`・`HypervisorPlatform` が有効
- ユーザーのトークンに `BUILTIN\Hyper-V Administrators`（`S-1-5-32-578`）が入っている
- `vmms` は `Running`。スイッチは `Default Switch`（`Get-VMSwitch` の種類は `Internal`）
- 手順書の検証に作った VM とスイッチは、手順書のブロックで消した

## 付録: 有効化の読み戻しと、管理者ではない窓でできること（2026-10-11）

### 実施手順 / Hyper-V を有効にして再起動する / 手順 1〜4: 再起動の後の読み戻し

- 利用者が手順 1〜4 を実行して再起動した後、エージェントが管理者ではない窓で読んだ
- Setup のイベント ログでは、`Microsoft-Hyper-V-All` を有効にする変更が 14:31:41、`HypervisorPlatform` が 14:32:01 に始まり、どちらも「再起動が要る」と記録された（ID 7・13）。再起動（14:35:49 に起動）の後、14:35:58 に 2 つとも有効になった（ID 9）
- 手順 3 と手順 4 のあいだに、利用者は VMware Workstation Pro をインストールした（[VMware Workstation Pro の検証記録](vmware.md)）

| 確認 | 結果 |
|---|---|
| `Win32_OptionalFeature` の `InstallState` | 上の「完了時点の状態」の 7 つと `VirtualMachinePlatform` が `1`（有効） |
| `whoami /groups` | `BUILTIN\Hyper-V Administrators`、`S-1-5-32-578`、`Enabled group` |
| `Get-Service vmms, vmcompute` | どちらも `Running` |
| `Get-VMHost`・`Get-VMSwitch` | 権限のエラー無し。`Default Switch` が出た |

### 実施手順 / Hyper-V を有効にして再起動する / 手順 3: 補足: 管理者ではない窓で通った操作

- 使い捨ての VM で、次の操作を 1 つずつ試した。どれも、管理者ではない窓で通った

| 操作 | 結果 |
|---|---|
| `New-VMSwitch -SwitchType Private`、`Remove-VMSwitch` | 通った |
| `New-VM`・`Set-VM`・`Set-VMFirmware`・`Set-VMProcessor -ExposeVirtualizationExtensions $true` | 通った |
| `Set-VMKeyProtector -NewLocalKeyProtector`・`Enable-VMTPM` | 通った（`TpmEnabled : True`） |
| `New-VHD`（可変と `-Differencing`）、`Add-VMHardDiskDrive`・`Add-VMDvdDrive` | 通った |
| `Checkpoint-VM`・`Restore-VMSnapshot`・`Start-VM`・`Stop-VM -TurnOff`・`Remove-VM` | 通った |
| WMI の `GetVirtualSystemThumbnailImage`（画面の取得）、`Msvm_Keyboard`（キーの送信） | 通った |

- 作りたての VM の既定は、`DynamicMemoryEnabled : True`、`AutomaticCheckpointsEnabled : True`、`CheckpointType : Standard`、構成バージョン `12.0` だった

## 付録: VM の作成から削除まで（2026-10-11）

### 実施手順 / VM を作る / 手順 2〜4

| 確認 | 結果 |
|---|---|
| 手順 2 の出力 | `State : Off`、`Generation : 2`、`Version : 12.0`、`ProcessorCount : 2`、`DynamicMemoryEnabled : False`、`AutomaticCheckpointsEnabled : False`、`SecureBoot : On`、`SecureBootTemplate : MicrosoftWindows` |
| 手順 2 をもう一度貼る | `中断: 同じ名前の VM がすでにある` で止まり、何も変わらなかった |
| 既定のテンプレートのまま起動 | AlmaLinux 10.2 の ISO は起動せず、VM の画面に `Start PXE over IPv4` が出た |
| 手順 3 の後に起動 | `SecureBootTemplate : MicrosoftUEFICertificateAuthority`。GRUB の画面（`Install AlmaLinux 10.2` など）が出た |
| 手順 4 | `TpmEnabled : True` |

### 実施手順 / VM を起動して OS を入れる / 手順 1〜3

- 手順 1 は、最初は `Start-VM` だけを実行した。`vmconnect.exe` は、後から、起動している別の VM（AlmaLinux 10.2 を入れたもの）に対して、同じ書き方で実行した
  - `localhost 上の <VM 名> - 仮想マシン接続` という題のウィンドウが開いた（プロセスのウィンドウの題を読んだ）。コマンドは、ウィンドウを閉じるのを待たずに戻った
  - ウィンドウの中の表示は撮っていない。ウィンドウを閉じても、VM は `Running` のままだった
- 手順 2 の代わりに、応答ファイル（Kickstart）を載せた 2 枚目の ISO を VM に付け、画面を操作せずに AlmaLinux 10.2 の Workstation を入れた。インストーラーは最後に VM の電源を切る
  - Secure Boot を切った VM では、起動から電源が切れるまで 432 秒だった
- **手順 3 は、最初の版では ISO が外れなかった**
  - 最初の版は `Get-VMDvdDrive -VMName $HV_VM | Set-VMDvdDrive -Path $null` だった。Windows PowerShell 5.1 では、エラーを出さずに `Path` がそのまま残った。PowerShell 7 では外れた
  - `Set-VMDvdDrive` に VM の名前とコントローラーの場所を指定する形と、`Remove-VMDvdDrive` は、5.1 でも効いた
  - 手順書を `Get-VMDvdDrive -VMName $HV_VM | Remove-VMDvdDrive` に直し、5.1 で `DVD ドライブの数: 0` を確かめた

### 実施手順 / 動作を確かめる / 手順 1・2

| 確認 | 結果 |
|---|---|
| 手順 1 の出力 | `State : Running`。`IPAddresses` に IPv4 と IPv6 が 1 つずつ出た（起動から 26 秒の時点） |
| ゲストの `hyperv-daemons` | Workstation の環境に最初から入っていた（`hyperv-daemons-0-0.50.20220731git.el10`） |
| ゲストに `ssh` で入る | 鍵を指定して入れた。`systemd-detect-virt` は `microsoft` |
| Secure Boot を有効にした VM のゲスト | `mokutil --sb-state` が `SecureBoot enabled`。`/sys/class/tpm/tpm0` があり、`tpm_version_major` は `2` |

- 別に作った VM（Secure Boot を切ったもの）では、差分ディスクの VM が、起動の要求から 9.5 秒で SSH に応えた

### チェックポイントとクローン / 手順 1〜3

| 確認 | 結果 |
|---|---|
| 手順 1 | 付けた名前のチェックポイントが、`SnapshotType : Standard` で出た |
| 手順 2 | `ParentCheckpointName` に戻した先の名前。VM が止まっていたので、`Stop-VM` は `The virtual machine is already in the specified state.` の警告を出した |
| 手順 3 | `VhdType : Differencing`、`ParentPath` は元の VM の `.vhdx`。新しい VM は `State : Off`、CPU 2、メモリ 4 GiB |
| 新しい VM を起動 | 15 秒で SSH に応えた。`SecureBoot enabled`。ホスト名は元の VM と同じ。`/sys/class/tpm` は空（仮想 TPM は引き継がれない） |

### チェックポイントとクローン: 補足: チェックポイントを消した後の起動

- 使い捨ての VM で、節のリードの警告を確かめた
  1. VM のチェックポイントを取り、手順 3 と同じ形で差分ディスクの VM を作った
  1. 元の VM を起動して 64 MiB 書き、止めた
  1. この時点では、差分ディスクの VM は起動した
  1. 元の VM のチェックポイントを消した（元の VM のディスクは `.avhdx` から `.vhdx` に戻った）
  1. 差分ディスクの VM は、`仮想ハード ディスクのチェーンが壊れています。親仮想ハード ディスクと差分ディスクの識別子が一致しません。`（`0xC03A000E`）で起動しなかった
- チェックポイントを取った直後に、同じ名前で引いた `Get-VMSnapshot` が「見つからない」を返したことが 1 回あった。少し後には見えた

### VM どうしだけがつながるスイッチを作る（任意） / 手順 1、ロールバック / 手順 1

| 確認 | 結果 |
|---|---|
| スイッチの作成と NIC の追加 | `SwitchType : Private` のスイッチと、VM の 2 枚の NIC が出た。足した NIC の `MacAddress` は、VM を起動するまで `000000000000` |
| 同じ名前で Private ではないスイッチ（`Default Switch`）を指定 | `中断: 同じ名前で、Private ではないスイッチがある` で止まり、NIC は足されなかった |
| ロールバックの手順 1 | 一覧からスイッチが消えた |
| VM がつながっているスイッチを指定 | `中断: まだ VM がつながっている` で止まり、何も消えなかった |

- つないだ VM どうしの通信は、この記録では確かめていない

### VM を消す / 手順 1

- **最初の版は、消すフォルダーの範囲を検査していなかった**（Codex のレビューの指摘）
  - 最初の版は、`(Get-VM).Path` をそのまま `Remove-Item -Recurse` していた。Hyper-V の既定の場所に作った VM の `Path` は、VM 専用ではない `C:\ProgramData\Microsoft\Windows\Hyper-V` になる（実測）。その VM を指定すると、ほかの VM のファイルごと消すところだった
  - フォルダーの名前が VM の名前と同じことと、ほかの VM がそのフォルダーのファイル（ディスクと、差分ディスクの親）を使っていないことを確かめてから消す形に直した。`Remove-VM` が失敗したら、ファイルの削除へ進まない
- 直した版で確かめたこと

| 指定した VM | 結果 |
|---|---|
| 差分ディスクの VM が残っている元の VM | `中断: ほかの VM が、このフォルダーのファイルを使っている` で止まり、VM もフォルダーも残った |
| 既定の場所に作った VM（`Path` が `C:\ProgramData\Microsoft\Windows\Hyper-V`） | `中断: VM のフォルダーが、VM の名前のフォルダーではない` で止まり、VM は残った |
| 差分ディスクの VM、元の VM の順 | どちらも一覧から消えて、フォルダーの確認が `False` になった |
| 空の名前、無い名前 | それぞれ `中断: $HV_REMOVE が空のまま`、`中断: VM が無い` で止まった |

### 注意点: 補足: ISO のアクセス権

- VM に付けた ISO のアクセス権を `Get-Acl` で読むと、`NT VIRTUAL MACHINE\<VM の ID>` が足されていた

## 未確認の範囲

- `vmconnect.exe` のウィンドウの中の表示と操作、画面でのインストーラーの操作
- Windows 11 のゲスト（Secure Boot と仮想 TPM を付けた VM へのインストール）
- 入れ子の仮想化（`ExposeVirtualizationExtensions` を設定できることだけを確かめた）
- Private のスイッチでの VM どうしの通信、Internal と External のスイッチ
- 機能の無効化、Hyper-V Administrators からの削除、再起動をまたいだ Default Switch の IP の変化
- 管理者の窓での VM の操作、Home エディション、Intel の CPU
