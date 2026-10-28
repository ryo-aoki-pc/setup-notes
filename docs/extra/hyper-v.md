# Hyper-V の注意点

[手順書](../virtual-machines.md#hyper-v)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/hyper-v.md)・[参考資料](../reference/hyper-v.md)

- 手順書の実施手順は項（###）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **Hyper-V を有効にすると、同じ PC の VirtualBox と VMware Workstation は Windows のハイパーバイザーの上で動く**
  - VirtualBox は VM のログに `fall back to NEM` と `Snail execution mode` を、VMware Workstation は `Monitor Mode: ULM` を出す
  - 各製品の文書は、CPU の仮想化支援を直接使うときより遅くなるとしている（本書では、Hyper-V を止めた状態と比べていない）
- **第 2 世代の VM は、既定のままでは Linux の ISO から起動しない**
  - 既定の Secure Boot のテンプレート（`MicrosoftWindows`）では、AlmaLinux 10.2 の ISO は起動せず、VM の画面に `Start PXE over IPv4` が出た
  - [VM を作る](../virtual-machines.md#hyper-v-vm-を作る)の手順 4 でテンプレートを変えると、Secure Boot が有効のまま起動し、インストール後のゲストでも `SecureBoot enabled` だった
- **`New-VM` の既定は、動的メモリと自動チェックポイントが有効**。[VM を作る](../virtual-machines.md#hyper-v-vm-を作る)の手順 3 で切っている。Hyper-V マネージャーなどで作った VM には残る
- **Windows PowerShell 5.1 では、`Get-VMDvdDrive … | Set-VMDvdDrive -Path $null` は ISO を外さない**（エラーも出ない）。PowerShell 7 では外れる。本書は、DVD ドライブごと外す形にしている
- **チェックポイントを消すと、そこから差分ディスクで作った VM は起動しなくなる**
  - 起動すると `仮想ハード ディスクのチェーンが壊れています。親仮想ハード ディスクと差分ディスクの識別子が一致しません。`（`0xC03A000E`）で止まった
  - 差分ディスクで作った VM を先に消してから、元の VM のチェックポイントを消す
- **差分ディスクで作った VM には、仮想 TPM が引き継がれない**。要るなら、新しい VM に[VM を作る](../virtual-machines.md#hyper-v-vm-を作る)の手順 5 を通す（元の VM の TPM の中身は移らない）
- **VM に ISO を付けると、その ISO のファイルのアクセス権に VM の ID が足される**（`NT VIRTUAL MACHINE\<VM の ID>`）。ほかの用途と共有している ISO は、写しを付ける
