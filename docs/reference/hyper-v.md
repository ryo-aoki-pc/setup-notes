# Hyper-V の有効化と VM の作成（Windows 11 Pro）の参考資料

[手順書](../windows-setup.md#hyper-v-実施手順)・[検証記録](../verification/hyper-v.md)・[ロールバックと注意点](../extra/hyper-v.md)

## 補足

### 実施手順 / この PC で使えるかを確かめる / 手順 2: 補足: 確かめる値の意味

- `Edition`: Hyper-V の役割は、Windows 11 の Pro・Enterprise・Education にある。Home には入らない
- `Hypervisor`: Windows のハイパーバイザーが動いているか。WSL 2（仮想マシン プラットフォーム）やメモリ整合性を使っている PC では、Hyper-V の役割を入れる前から `True` になる
- `VirtFirmware`: UEFI（BIOS）で CPU の仮想化支援が有効か
- 機能の表: `Microsoft-Hyper-V-All` が Hyper-V の全体、`HypervisorPlatform` が Windows ハイパーバイザー プラットフォーム、`VirtualMachinePlatform` が WSL 2 の使う仮想マシン プラットフォーム
- 最後の表: Hyper-V Administrators（SID `S-1-5-32-578`）の一員。Hyper-V の役割を入れる前から、グループだけはある

### 実施手順 / Hyper-V を有効にして再起動する / 手順 1: 補足: 機能の名前

- `Microsoft-Hyper-V-All` は、ハイパーバイザー・サービス・管理ツール（Hyper-V マネージャーと PowerShell のモジュール）をまとめた名前
- Microsoft の文書の例は `Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All`。本書は、管理ツールまで入ったことを機能の表で確かめるために、全体の名前を使う
- `-NoRestart` を付けると、再起動するかを聞かれない。再起動するまで、機能は `EnablePending` のままで、Hyper-V は使えない

### 実施手順 / Hyper-V を有効にして再起動する / 手順 2: 補足: Windows ハイパーバイザー プラットフォーム

- VirtualBox と VMware Workstation は、Windows のハイパーバイザーが動いている PC では、CPU の仮想化支援を直接は使えない。Windows ハイパーバイザー プラットフォームの API を通して VM を動かす
- VirtualBox は、VM のログに `fall back to NEM` と `Snail execution mode` を出す。VMware Workstation は、VM のログに `Monitor Mode: ULM` を出す
- Hyper-V だけを使う PC では要らない

### 実施手順 / Hyper-V を有効にして再起動する / 手順 3: 補足: Hyper-V Administrators

- 本書は、VM の操作を管理者ではない窓で行うために、ユーザーをこのグループに足す
- グループに足した後、サインインし直すまで（本書では再起動まで）は効かない
- 一員になると、管理者ではない窓から、VM の作成・起動・停止・チェックポイント・削除、Private のスイッチの作成、仮想 TPM の追加までできた（[検証記録](../verification/hyper-v.md)）

### 実施手順 / VM を作る / 手順 2: 補足: 既定を変えている設定

- `-Generation 2`: UEFI で起動する VM。Windows 11 と、今の Linux はこちらで入れる
- `-StaticMemory`: Windows 11 の `New-VM` は、動的メモリを有効にして VM を作る（実測で `DynamicMemoryEnabled : True`）。割り当てを固定にして、ゲストから見えるメモリの量が変わらないようにする
- `-AutomaticCheckpointsEnabled $false`: Windows 11 では、VM を起動するたびにチェックポイントを自動で取る設定が既定で有効（実測で `True`）。自分で取るチェックポイントと混ざらないように切る
- `-CheckpointType Standard`: 止めた VM のチェックポイントを取るので、種類はどちらでも同じ。名前を付けて取る形にそろえる
- `-SwitchName 'Default Switch'`: Hyper-V が最初から持つスイッチ。VM に IP を配り、インターネットへは NAT で出る。この PC からも VM に届く
- `-FirstBootDevice`: 起動の順番の先頭を DVD にする

### 実施手順 / VM を作る / 手順 3: 補足: Secure Boot のテンプレート

- 第 2 世代の VM は、Secure Boot が既定で有効。テンプレートは、起動を許す署名の組
- `MicrosoftWindows`（既定）は Windows 用、`MicrosoftUEFICertificateAuthority` は Linux のディストリビューション用
- AlmaLinux 10.2 の ISO は、既定のテンプレートでは起動せず、Linux 用に変えると GRUB の画面まで進んだ（[検証記録](../verification/hyper-v.md)）

### 実施手順 / VM を作る / 手順 4: 補足: 仮想 TPM

- Windows 11 は、Secure Boot と TPM 2.0 が要る
- `Set-VMKeyProtector -NewLocalKeyProtector` は、この PC だけで使う鍵の保護を VM に付ける。`Enable-VMTPM` は、その保護の下で仮想 TPM を有効にする
- 仮想 TPM を付けた VM を別の PC へ移すと、起動できないことがある

### 実施手順 / 動作を確かめる / 手順 1: 補足: IP の出どころ

- `IPAddresses` は、ゲストの中のデーモン（Linux は `hyperv-daemons` の KVP デーモン）が Hyper-V に知らせた値
- Default Switch は VM に IP を自動で配る。配る範囲を決める設定は無いので、IP は毎回引き直す

### チェックポイントとクローン / 手順 3: 補足: 差分ディスク

- 差分ディスクは、親のディスクとの違いだけを持つ。親は書き換えない
- チェックポイントを取ると、元の VM は新しい差分（`.avhdx`）に書き始め、チェックポイントの時点のディスクは変わらなくなる。そのディスクを親にする
- 元の VM のチェックポイントを消すと、差分が親に書き戻されて親が変わる。そこから作った VM のディスクは、親と合わなくなる
- 新しい VM は別の VM として作るので、ファームウェアの設定（NVRAM）と仮想 TPM は引き継がれない

### VM どうしだけがつながるスイッチを作る（任意） / 手順 1: 補足: スイッチの種類

| 種類 | つながる相手 |
|---|---|
| Default Switch | VM どうし、この PC、インターネット（NAT） |
| Private | VM どうしだけ |
| Internal | VM どうしと、この PC |
| External | この PC の物理の NIC がつながるネットワーク |

- 本書が作るのは Private だけ。Internal と External は、この PC のネットワークの設定を変える

### 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **PowerShell のコマンドレット** | 手順をそのまま貼れる。管理者ではない窓から VM を扱える | **採用** |
| Hyper-V マネージャー（GUI） | 同じことを画面で行う | 不採用（貼れない） |
| クイック作成 | 用意されたイメージから VM を作る。自動チェックポイントなどの既定のまま | 不採用 |
| 第 1 世代の VM | BIOS で起動する古い形。Windows 11 が入らない | 対象外 |

### 参照

- [Install Hyper-V in Windows and Windows Server](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/get-started/install-hyper-v)（Microsoft Learn。2026-10-11 に確認。有効化のコマンド、Home には入らないこと、VirtualBox や VMware Workstation と併用するときの注意）
- [Hyper-V Generation 2 Virtual Machine Security Features](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/generation-2-virtual-machine-security-features)（Microsoft Learn。2026-10-11 に確認。Secure Boot のテンプレートと仮想 TPM）
