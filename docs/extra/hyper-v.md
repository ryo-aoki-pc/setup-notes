# Hyper-V の有効化と VM の作成（Windows 11 Pro）のロールバックと注意点

[手順書](../windows-setup.md#hyper-v-実施手順)・[検証記録](../verification/hyper-v.md)・[参考資料](../reference/hyper-v.md)

- 手順書の実施手順は項（###）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- 管理者ではない Windows PowerShell（5.1）に貼る
- VM は、先に本書の[VM を消す](../windows-setup.md#hyper-v-vm-を消す)で消す
- **Hyper-V の機能を無効に戻す手順と、ユーザーを Hyper-V Administrators から外す手順は、まだ検証していないので載せていない**（[検証記録](../verification/hyper-v.md)）

1. [VM どうしだけがつながるスイッチを作る（任意）](../windows-setup.md#hyper-v-vm-どうしだけがつながるスイッチを作る任意)で作ったスイッチを消す。

   ```powershell
   $HV_SWITCH = 'lab-lan'
   if (Get-VMNetworkAdapter -VMName * | Where-Object SwitchName -eq $HV_SWITCH) { Write-Error "中断: まだ VM がつながっている: $HV_SWITCH" } else {
     Remove-VMSwitch -Name $HV_SWITCH -Force
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-VMSwitch | Format-Table Name, SwitchType
   }
   ```

   - 一覧から、消したスイッチが無くなればよい
   - `中断: まだ VM がつながっている` と出たら、その VM を消すか、VM から NIC を外してから貼り直す

---

## 注意点

- **Hyper-V を有効にすると、同じ PC の VirtualBox と VMware Workstation は Windows のハイパーバイザーの上で動く**
  - VirtualBox は VM のログに `fall back to NEM` と `Snail execution mode` を、VMware Workstation は `Monitor Mode: ULM` を出す
  - 各製品の文書は、CPU の仮想化支援を直接使うときより遅くなるとしている（本書では、Hyper-V を止めた状態と比べていない）
- **第 2 世代の VM は、既定のままでは Linux の ISO から起動しない**
  - 既定の Secure Boot のテンプレート（`MicrosoftWindows`）では、AlmaLinux 10.2 の ISO は起動せず、VM の画面に `Start PXE over IPv4` が出た
  - [VM を作る](../windows-setup.md#hyper-v-vm-を作る)の手順 3 でテンプレートを変えると、Secure Boot が有効のまま起動し、インストール後のゲストでも `SecureBoot enabled` だった
- **`New-VM` の既定は、動的メモリと自動チェックポイントが有効**。[VM を作る](../windows-setup.md#hyper-v-vm-を作る)の手順 2 で切っている。Hyper-V マネージャーなどで作った VM には残る
- **Windows PowerShell 5.1 では、`Get-VMDvdDrive … | Set-VMDvdDrive -Path $null` は ISO を外さない**（エラーも出ない）。PowerShell 7 では外れる。本書は、DVD ドライブごと外す形にしている
- **チェックポイントを消すと、そこから差分ディスクで作った VM は起動しなくなる**
  - 起動すると `仮想ハード ディスクのチェーンが壊れています。親仮想ハード ディスクと差分ディスクの識別子が一致しません。`（`0xC03A000E`）で止まった
  - 差分ディスクで作った VM を先に消してから、元の VM のチェックポイントを消す
- **差分ディスクで作った VM には、仮想 TPM が引き継がれない**。要るなら、新しい VM に[VM を作る](../windows-setup.md#hyper-v-vm-を作る)の手順 4 を通す（元の VM の TPM の中身は移らない）
- **VM に ISO を付けると、その ISO のファイルのアクセス権に VM の ID が足される**（`NT VIRTUAL MACHINE\<VM の ID>`）。ほかの用途と共有している ISO は、写しを付ける
