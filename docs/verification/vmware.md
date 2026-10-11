# VMware Workstation Pro のインストールと VM の作成（Windows 11）の検証記録

[手順書](../vmware.md)・[参考資料](../reference/vmware.md)・[ロールバックと注意点](../extra/vmware.md)

## 対象と検証環境

- **目的**: Windows 11 の PC に VMware Workstation Pro を入れ、管理者ではない窓から、`vmcli` と `vmrun` で VM を作る・入れる・スナップショットを取る・複製する・消すまでを、手順書のブロックで確かめる
- **状態**: **Hyper-V を有効にした Windows 11 Pro の実機で、26H1u1 のインストールから VM の削除までを通した（2026-10-11、JST）**
  - 利用者が実施したこと
    - インストーラーを Broadcom のサポート ポータルから取得した
    - [インストーラーを取得して確かめる](../vmware.md#インストーラーを取得して確かめる)の手順 3・4 と、[インストールする](../vmware.md#インストールする)の手順 1 に当たるブロックを、管理者の Windows PowerShell に貼って実行し、`ExitCode = 0` を報告した
    - Hyper-V と Windows ハイパーバイザー プラットフォームを有効にした直後（再起動待ち）にインストールし、その後に 1 回再起動した（[インストールする](../vmware.md#インストールする)の手順 2 の「機能が再起動待ち」の分岐）
    - エージェントは、そのときの出力を見ていない。順序と時刻は、再起動の後にイベント ログから読んだ
  - エージェントが、管理者ではない Windows PowerShell 5.1 で、手順書のブロックを 1 つずつ実行したこと
    - [入ったかを確かめる](../vmware.md#入ったかを確かめる)の手順 2
    - [VM を作る](../vmware.md#vm-を作る)の手順 1〜3（変数は検証用の値に置き換えた）
    - [VM を起動して OS を入れる](../vmware.md#vm-を起動して-os-を入れる)の手順 1 と、手順 3
    - [動作を確かめる](../vmware.md#動作を確かめる)の手順 1
    - [スナップショットとクローン](../vmware.md#スナップショットとクローン)の手順 1〜3、[VM を消す](../vmware.md#vm-を消す)の手順 1
  - 確認したこと
    - 管理者ではない窓から、VM の作成・起動・停止・スナップショット・リンククローン・削除ができた
    - VM は Windows のハイパーバイザーの上で動いた（`Monitor Mode: ULM`）。AlmaLinux 10.2 が入り、起動した
    - 掲載した PowerShell のブロックは、Windows PowerShell 5.1 と PowerShell 7 の構文解析でエラー 0
  - **確認していないこと**
    - [VM を起動して OS を入れる](../vmware.md#vm-を起動して-os-を入れる)の手順 2（画面でのインストーラーの操作）。OS は、応答ファイルを載せた 2 枚目の ISO を付け、画面無し（`nogui`）で入れた
    - 手順 1 は、ウィンドウが開いて VM が起動することだけを確かめた。ウィンドウの中での、キーとマウスの操作は確かめていない
    - [動作を確かめる](../vmware.md#動作を確かめる)の手順 2 の、手で打つ `ssh`（エージェントは、鍵を指定した `ssh` で入った）
    - インストーラーを画面で進める形、`ExitCode = 3010` の分岐、機能を有効にして再起動した後にインストールする順
    - Windows 11 をゲストに入れること（仮想 TPM）、Secure Boot を有効にした VM、3D のアクセラレーションを有効にした場合
    - アンインストール、版を上げる更新
    - Hyper-V を止めた PC（`Monitor Mode: CPL0`）、AlmaLinux 10 のホスト
- **今回の確認方法**: 手順書からコードブロックを取り出し、変数だけを検証用の値にして、Windows PowerShell 5.1 の新しいプロセスで 1 手順ずつ実行した。出力を手順書の箇条書きと照らした

| 項目 | 実測した値 |
|---|---|
| 検証日 | 2026-10-11、JST |
| ホスト | Windows 11 Pro 26H2、build `26300.9457`、x64。Hyper-V・Windows ハイパーバイザー プラットフォーム・仮想マシン プラットフォームが有効 |
| CPU・メモリ | AMD Ryzen 9 5900X（12 コア・24 スレッド）、32 GB |
| 実行シェル | Windows PowerShell `5.1.26100.9444`（管理者ではない窓） |
| インストーラー | `VMware-Workstation-Full-26H1u1-25688693.exe`、280,609,368 バイト、SHA256 `3D775C3C2153600EEF4642F95D519A514BA7E861400BDA2598352BFF792DB473`、署名 `Valid`（`CN=Broadcom Inc`）、`ProductVersion` `26.0.1` |
| 入った版 | `vmware.exe` の `ProductVersion` `26.0.1 build-25688693`、`C:\Program Files\VMware\VMware Workstation` |
| ゲスト | AlmaLinux 10.2（`AlmaLinux-10-latest-x86_64-boot.iso`、SHA256 `b3f865468075bcada8f208d830289302c67529789d668041d24e8d6fc697ba6a`）、kernel `6.12.0-211.64.1.el10_2.x86_64`、`open-vm-tools` `13.0.10-1.el10` |
| VM | UEFI（Secure Boot 無効）、2 vCPU、4 GiB、NVMe に 64 GiB の可変の `.vmdk`、`vmxnet3` を NAT に、3D 無効、ハードウェアのバージョン 22 |

> [!NOTE]
> VM の名前とフォルダーは、検証用の値（`vmv-vw-doc` など）に置き換えて実行した。ゲストの IP とホスト名は載せていない。ゲストのユーザーは検証用に作ったもので、パスワードと鍵は記録していない。

## 実施前の状態

- VMware Workstation は入っていなかった（レジストリのアンインストール情報・`C:\Program Files*\VMware*`・VMware のサービスとドライバーが無い）
- ダウンロードのフォルダーに、古い 25H2（`VMware-Workstation-Full-25H2-24995812.exe`）があった
- Hyper-V と Windows ハイパーバイザー プラットフォームは、有効にした直後で、再起動待ちだった

## 完了時点の状態

- サービス `VMAuthdService`・`VMnetDHCP`・`VMware NAT Service`・`VMUSBArbService` が `Running`、ドライバー `vmx86`・`vmci`・`vsock`・`hcmon`・`VMnetAdapter`・`VMnetBridge`・`VMnetuserif` が `Running`
- ネットワーク アダプター `VMware Network Adapter VMnet1` と `VMnet8` があり、どちらも `/24` の IPv4 を持つ
- 手順書の検証に作った VM は、手順書のブロックで消した

## 付録: インストールの読み戻し（2026-10-11）

### 実施手順 / インストールする / 手順 1: インストールの後の読み戻し

| 確認 | 結果 |
|---|---|
| 利用者の報告 | `ExitCode = 0` |
| [入ったかを確かめる](../vmware.md#入ったかを確かめる)の手順 2 | インストール先、`ProductVersion : 26.0.1 build-25688693`、`Total running VMs: 0`、`VMnet8` と `VMnet1` の 2 行 |
| インストーラーの署名（エージェントが後から読んだ） | `Status : Valid`、`Signer` は `CN=Broadcom Inc, O=Broadcom Inc, …` |
| インストーラーのログ | `%TEMP%` に `vminst.log` と `vmmsi.log_<日時>.log` |
| インストール中のネットワーク（イベント ログ） | ドライバー `VMnetBridge`・`VMnetuserif`・`VMnetAdapter`・`vmx86` が 14:34:05〜14:34:17 に始まった。ネットワークの状態の変更（NetworkProfile の ID 4004）が 2 回記録されたが、接続のレベルは変わっていない。切断は記録されていない |

- 利用者の作業の順序と時刻（イベント ログから。JST）

  | 時刻 | 出来事 | 出どころ |
  |---|---|---|
  | 14:31:41 | `Microsoft-Hyper-V-All` を有効にする変更が始まり、再起動が要ると記録された | Setup のログ（ID 7・13） |
  | 14:32:01 | `HypervisorPlatform` も同じ | Setup のログ（ID 7・13） |
  | 14:33:56〜14:34:19 | VMware Workstation 26.0.1 のインストールが正常に終わった（状態 0） | Application のログ（MsiInstaller の ID 1040・11707・1033・1042） |
  | 14:35:11 | 利用者が再起動を始めた | System のログ（ID 1074） |
  | 14:35:49 | 起動 | System のログ（Kernel-General の ID 12） |
  | 14:35:58 | 2 つの機能が有効になった | Setup のログ（ID 9） |

- Broadcom の文書には、インストーラーはインストールの間に Hyper-V と Windows ハイパーバイザー プラットフォームの状態を調べる、とある。今回は、2 つの機能が再起動待ちの状態でインストールし、再起動の後、VM は Windows のハイパーバイザーの上で動いた（`Monitor Mode: ULM`）
- この PC では、機能を有効にする前から、WSL 2 の仮想マシン プラットフォームで Windows のハイパーバイザーが動いていた。ハイパーバイザーがまったく動いていない PC で同じ順にした場合は、確かめていない
- エージェントは途中で、機能を有効にして再起動した後に入れる順を利用者に案内したが、利用者の作業は上の順で終わっていた。再起動した後に入れる順は、確かめていない

## 付録: VM の作成から削除まで（2026-10-11）

### 実施手順 / VM を作る / 手順 2・3

| 確認 | 結果 |
|---|---|
| 手順 2 の出力 | `VMX file is created`、`Virtual disk file creation is successful`（2 回。`VM Create` と `Disk Create`）。一覧に `.vmx` と `.vmdk` |
| 手順 3 の出力 | `guestOS = "almalinux-64"`、`numvcpus = "2"`、`memsize = "4096"`、`firmware = "efi"`、`nvme0:0.fileName`、`sata0:0.fileName`（ISO）、`ethernet0.virtualDev = "vmxnet3"`、`ethernet0.connectionType = "nat"`。`mks.enable3d` の行は無い |
| `vmcli VM Create` の直後の `.vmx` | `virtualHW.version = "22"`、`numvcpus = "2"`、`memsize = "512"`、`mks.enable3d = "TRUE"`。ディスクと NIC の行は無い |

### 実施手順 / VM を起動して OS を入れる / 手順 1〜3

- 手順 1 は、OS を入れるときは `nogui` を付けて画面無しで起動した。ウィンドウを開く形（手順書のブロックのまま）は、後から、AlmaLinux 10.2 を入れた別の VM（リンククローン）で実行した
  - `PID: <番号>, log output: <ログのパス>` の 1 行が出て、6.4 秒で戻った（終了コード 0）
  - `<VM 名> - VMware Workstation` という題のウィンドウが開き（プロセスのウィンドウの題を読んだ）、実行から 7 秒の時点で `vmrun list` は `Total running VMs: 1` だった
  - エージェントは途中で、「ウィンドウは開くが電源が入らない」という結果を 4 回得たが、これは試し方の誤りだった（`Start-Process` に渡した引用符が外れて、`vmrun` が動かず、`.vmx` が関連付けで開かれていた）。手順書のブロックをファイルから実行し直して、上の結果を得た
- 手順 2 の代わりに、応答ファイル（Kickstart）を載せた 2 枚目の ISO を `sata0:1` に付け、画面を操作せずに AlmaLinux 10.2 の Workstation を入れた。インストーラーは最後に VM の電源を切る
  - 別に作った同じ構成の VM では、起動から電源が切れるまで 556 秒だった
  - 起動の直後の画面を `vmcli MKS captureScreenshot` で撮り、GRUB のメニュー（`Install AlmaLinux 10.2` など）を確かめた
- **手順 3 の成功条件を直した**
  - 最初の版は「`sata0:0.present = "FALSE"` が出ればよい」だった。実際には、`Disk SetPresent sata0:0 0` は `.vmx` から `sata0:0.present` の行を消す（`deviceType` と `fileName` の行は残る）
  - 確認を、`sata0:0.present` の行の数を出す形に直し、`0` を確かめた

### 実施手順 / 動作を確かめる / 手順 1・2

| 確認 | 結果 |
|---|---|
| 手順 1 の出力 | `Total running VMs: 1` と `.vmx` のパス、`Monitor Mode: ULM`。最後の行（IP）は、起動の直後は空だった |
| 最後の行を打ち直す | 起動の要求から 46 秒で IP が出た |
| ゲストに `ssh` で入る | 鍵を指定して入れた。`systemd-detect-virt` は `vmware`、`vmtoolsd` は `active`、`mokutil --sb-state` は `SecureBoot disabled` |
| `vmware.log` | `IOPL_Init: Hyper-V detected by CPUID`、`Monitor Mode: ULM`、`Syncing WHP TSCs took … us.` |
| ゲストから見えるデバイス | ディスク `nvme0n1`、NIC `ens160`。`systemd-analyze time` は 30.0 秒（kernel 3.7 + initrd 3.5 + userspace 22.9。リンククローンの 1 回） |

### スナップショットとクローン / 手順 1〜3

| 確認 | 結果 |
|---|---|
| 手順 1 | `Total snapshots: 1` と、付けた名前 |
| 手順 2 | VM が止まっていたので、`stop` は `Error: The virtual machine is not powered on` を出した。`revertToSnapshot` の後も `Total snapshots: 1` |
| 手順 3 | 新しいフォルダーに `.vmx`・`.vmdk`（約 8 MB）・`.nvram`・`.vmsd`・`.vmxf`。`displayName` は新しい名前 |
| リンククローンのディスク | `createType="monolithicSparse"`、`parentFileNameHint` は元の VM の `.vmdk` のパス |
| リンククローンを起動 | 46 秒で IP が出て、SSH で入れた。ホスト名は元の VM と同じ |

### スナップショットとクローン / 手順 3: 補足: リンククローンでの `getGuestIPAddress`

| VM | `vmrun getGuestIPAddress` | `vmrun readVariable … guestVar ip` | `vmrun checkToolsState` |
|---|---|---|---|
| 元の VM | IP を返した | IP を返した | — |
| リンククローン（2 台で確かめた） | `Error: The VMware Tools are not running in the virtual machine` | IP を返した | `installed` |

- リンククローンのゲストの中では、`vmtoolsd` は `active`、`vmware-rpctool "info-get guestinfo.ip"` は IP を返した。`vmware-toolbox-cmd stat sessionid` は `VMware Guest API is not enabled on the host` を返した
- `vmcli Tools query` は、`running: true`・`runningStatus: running`・`versionStatus: unmanaged`・`vmSupportStatus: not_running` だった
- リンククローンでも、`vmrun stop … soft` は 3.4 秒で VM を止めた
- 原因は切り分けていない。手順書は `readVariable` を使う

### VM を消す / 手順 1

- リンククローン、元の VM の順に消した。どちらも `Total running VMs: 0` と `False` が出て、VM のフォルダーごと無くなった
- `$VMW_REMOVE` が空のときと、無いパスのときの中断は、実行していない

### 使い方の基本: 補足: 画面とキー

| 確認 | 結果 |
|---|---|
| `vmcli MKS captureScreenshot` | PNG ができた（GRUB のメニューと、インストーラーの画面で確かめた） |
| `vmcli MKS sendKeySequence c`、`… ls` | GRUB のコマンド行に `ls` が打たれた |
| 文字列に改行を入れた `sendKeySequence` | 行が実行された（Enter として届いた） |
| `sendKeySequence` に `\n`・`<Enter>` の文字 | そのままの文字が打たれた |
| `vmcli MKS sendKeyEvent` に HID のコード（`0x51`・`81`・`0x70028` など）と修飾 `0` | 終了コードは 0 だが、GRUB の画面は変わらなかった |
| 起動した AlmaLinux 10.2 で、改行だけの `sendKeySequence` | ゲストのキーボードのデバイスに、Enter（キーコード 28）の「押す」と「離す」が同じ時刻で届いた。キーボードの割り込みは 2 回増えた |
| 同じゲストで、`sendKeyEvent` に Enter の HID のコード（`40`・`0x28`・`458792`・`0x00070028`） | 終了コードは 0 だが、キーボードの割り込みは増えなかった |
| `vmware.exe --help` | 説明は出ず、VMware Workstation のウィンドウが開いた |

- GNOME のログイン画面（GDM の利用者の一覧）は、この VM では、Enter だけでは利用者が選ばれなかった。Tab の後に Enter を送ると選ばれた
  - Tab は `sendKeySequence` では送れない。検証の道具では、`.vmx` に `RemoteDisplay.vnc.enabled`・`RemoteDisplay.vnc.ip`（`127.0.0.1`）・`RemoteDisplay.vnc.port` を足し、VNC のキー イベントで送った。`vmware-vmx` は `127.0.0.1` だけで待ち受けた
  - この VNC の設定は、手順書には載せていない

## 未確認の範囲

- VMware Workstation のウィンドウの中での操作（キーとマウス、インストーラー、スナップショットの画面）
- Windows 11 のゲスト、仮想 TPM と暗号化、Secure Boot を有効にした VM
- 閉じたネットワーク（LAN セグメント）、ホストオンリー（VMnet1）の VM
- アンインストール、更新、`ExitCode = 3010` の分岐
- Hyper-V を止めた PC での動作と速さ、入れ子の仮想化
- `vmcli` で矢印・Esc・Tab・ファンクション キーを送る方法（VNC を有効にした VM には、VNC のキー イベントで Tab・Esc・Enter が届いた）
