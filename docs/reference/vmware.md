# VMware Workstation Pro のインストールと VM の作成（Windows 11）の参考資料

[手順書](../vmware.md)・[検証記録](../verification/vmware.md)・[ロールバックと注意点](../extra/vmware.md)

## 補足

### 実施手順 / インストーラーを取得して確かめる / 手順 1: 補足: 入手先

- VMware Workstation Pro は、商用・教育・個人の利用とも無償で、ライセンスキーは要らない（26H1u1 のリリースノート）
- インストーラーは Broadcom のサポート ポータルで配られ、取得にはアカウントでのログインが要る（同じリリースノート）
- winget の公開のカタログには無い（2026-10-11 に `winget search` で確かめた）

### 実施手順 / インストーラーを取得して確かめる / 手順 4: 補足: 署名と版

- `Status : Valid` は、ファイルが署名の後で変わっていないことと、署名の証明書がこの PC で信頼されていることを示す
- 26H1u1 のインストーラーの `ProductVersion` は `26.0.1`、入った後の `vmware.exe` は `26.0.1 build-25688693` だった。リリースの名前（26H1u1）とは書き方が違うので、ファイル名のビルド番号と照らす
- インストーラーは、`%TEMP%` に `vminst.log` と `vmmsi.log_<日時>.log` を残す

### 実施手順 / インストールする / 手順 1: 補足: インストーラーの引数

- `/s /v"/qn …"` は、Broadcom の文書にある画面無しのインストールの形。`/v` の後ろが、中の Windows Installer に渡る
- `EULAS_AGREED=1`: 使用許諾契約に同意する。画面無しでは、これが無いと進まない
- `AUTOSOFTWAREUPDATE=0`: 起動のたびに新しい版を確かめる動きを切る
- `DATACOLLECTION=0`: 利用状況の送信を切る
- `REBOOT=ReallySuppress`: Windows Installer のプロパティ。再起動が要るときも自動では再起動せず、終了コード `3010` で知らせる

### 実施手順 / インストールする / 手順 1: 補足: Hyper-V との同居

- インストーラーは、インストールの間に Hyper-V と Windows ハイパーバイザー プラットフォームの状態を調べる、と Broadcom の文書にある
- Windows のハイパーバイザーが動いている PC では、VM は Windows ハイパーバイザー プラットフォームを通して動く。このとき、ゲストに CPU の仮想化支援（入れ子の仮想化）は見えない
- 本書の検証では、Hyper-V と Windows ハイパーバイザー プラットフォームを有効にした直後（再起動待ち）にインストールし、その後に 1 回再起動した。再起動の後、VM は `Monitor Mode: ULM` で動いた（[検証記録](../verification/vmware.md)）
- 機能を有効にして再起動した後にインストールする順は、確かめていない

### 実施手順 / 入ったかを確かめる / 手順 2: 補足: コマンドの場所

- 26H1u1 は `C:\Program Files\VMware\VMware Workstation` に入った。古い版は `C:\Program Files (x86)` の側に入るので、両方を探す
- コマンドは PATH に入らない。フルパスで呼ぶ

| コマンド | すること |
|---|---|
| `vmrun.exe` | VM の起動・停止、スナップショット、クローン、削除、ゲストの IP |
| `vmcli.exe` | VM の作成と設定、画面の取得、文字の入力 |
| `vmware.exe` | VMware Workstation の画面 |

### 実施手順 / VM を作る / 手順 2: 補足: ディスクを作り直す理由

- `vmcli VM Create` は、設定ファイル（`.vmx`）と一緒に、既定の大きさのディスクを作る。大きさを決めるために、同じ名前で作り直す
- OS の種類は `-c`（`--custom-guesttype`。文字列）で渡している。`vmcli VM Create --help` では、`-g`（`--guesttype`）は番号の一覧から選ぶ引数で、文字列は `-c` で受ける。Broadcom の文書の例は `-g windows9-64` と書いている。`-c almalinux-64` で、`.vmx` に `guestOS = "almalinux-64"` が入ることを確かめた
- `-t 0` は、1 つのファイルで、使った分だけ大きくなるディスク
- `-a lsilogic` は、ディスクの記述に入るアダプターの種類。NVMe につなぐときも、この値で作る（`vmcli Disk Create --help` の説明）

### 実施手順 / VM を作る / 手順 3: 補足: 設定の意味

- `firmware efi`: UEFI で起動する
- `cpuid.coresPerSocket`: CPU を 1 つのソケットのコアとしてゲストに見せる
- `MKS SetAccel3d false`: 3D のアクセラレーションを切る。25H2 のリリースノートに、有効だと RHEL 10 のインストールが灰色の画面で止まる、という既知の問題がある
- `nvme0`・`nvme0:0`: NVMe のコントローラーと、そこにつなぐディスク
- `sata0:0` の `cdrom_image`: ISO を光学ドライブとしてつなぐ。最後の `0` は、ISO がこの PC にあること
- `ethernet0` の `vmxnet3` と `nat`: 準仮想化の NIC を、NAT のネットワーク（VMnet8）につなぐ。VM に IP が配られ、この PC からも届く

### 実施手順 / 動作を確かめる / 手順 1: 補足: Monitor Mode

- `vmware.log` は、VM のフォルダーにできる。VM を起動するたびに新しくなる
- `Monitor Mode: ULM` は、Windows ハイパーバイザー プラットフォームを通して動いている印。同じログに `Hyper-V detected by CPUID` の行も出た
- `readVariable … guestVar ip` は、ゲストの VMware Tools が VM に知らせた IP を読む。ゲストが起動の途中だと空が返る（実測では、起動の要求から 46 秒で値が入った）
- `vmrun` には `getGuestIPAddress` もあるが、リンククローンの VM では失敗した（[注意点](../extra/vmware.md#注意点)）

### 使い方の基本: 補足: 画面に打てる文字

- `vmcli MKS sendKeySequence` は、渡した文字列をそのまま打つ。文字列の中の改行が Enter になる
- `sendKeySequence` の Enter は、「押す」と「離す」が同じ時刻でゲストに届く（起動した AlmaLinux 10.2 のキーボードのデバイスで確かめた）
- `vmcli` で矢印・Esc・Tab・ファンクション キーを送る方法は、確かめられていない（`vmcli MKS sendKeyEvent` に HID のコードを渡しても、GRUB の画面にも、起動した AlmaLinux 10.2 にも届かなかった）

### スナップショットとクローン / 手順 3: 補足: リンククローン

- リンククローンは、元の VM のスナップショットの時点のディスクを読み、違いだけを自分のフォルダーに書く
- 元の VM のフォルダーを動かしたり消したりすると、リンククローンは起動しなくなる

### 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **Broadcom のインストーラーを画面無しで実行する** | 引数が文書にある。貼って実行できる | **採用** |
| インストーラーを画面で進める | 使用許諾契約を画面で読める | 併記（手順 1 の箇条書き） |
| winget | 公開のカタログに無い | 不採用 |
| **`vmcli` と `vmrun` で VM を扱う** | 手順をそのまま貼れる。管理者ではない窓で動く | **採用** |
| VMware Workstation の画面で VM を作る | 同じことを画面で行う | 不採用（貼れない） |
| AlmaLinux 10 のホストに入れる | 本書では扱わない | 対象外（検証していない） |

### 参照

- [VMware Workstation Pro 26H1u1 Release Notes](https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/workstation-pro/26H1/release-notes/vmware-workstation-pro-26h1u1-release-notes.html)（Broadcom。2026-10-11 に確認。ビルド 25688693、2026-09-03）
- [VMware Workstation Pro 25H2u1 Release Notes](https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/workstation-pro/25H2/release-notes/vmware-workstation-pro-25h2u1-release-notes.html)（Broadcom。2026-10-11 に確認。Hyper-V を有効にした Windows のホストで VM が予期せず終了する問題の修正）
- [Running Workstation on a Hyper-V Enabled Host](https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/workstation-pro/26H1/using-vmware-workstation-pro/running-workstation-on-a-hyper-v-enabled-host.html)（Broadcom。2026-10-11 に確認。インストールの間に Hyper-V と Windows ハイパーバイザー プラットフォームの状態を調べること）
- [Using vmcli to Control Virtual Machines](https://techdocs.broadcom.com/us/en/vmware-cis/desktop-hypervisors/workstation-pro/26H1/using-vmware-workstation-pro/using-vmcli-to-control-virtual-machines.html)（Broadcom。2026-10-11 に確認。モジュールの一覧と、ISO を付けた VM を作る例）
