# Samba の共有を AlmaLinux 10 と Windows 11 から使う手順（cifs-utils + fstab の自動マウント / GNOME Files / Windows のネットワーク ドライブ）の検証記録

[手順書](../samba-client.md)・[ロールバックと注意点](../extra/samba-client.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 操作上の注意と併記されていた記録

- 画面では「ファイル」（Nautilus）から開く。この節のコマンドは、同じ仕組みを端末から使う `gio` で、VM で確かめたのはこちら

### 操作上の注意と併記されていた記録

   - 画面から開くときは、「ファイル」のサイドバーの「Network」を開き、「Server address」の欄に `smb://<SMB_USER>@<SERVER>/<SHARE>` を入れて「接続」を押す（2026-10-06 に VM の画面で確認）

### 操作上の注意と併記されていた記録

   - 画面では、サイドバーに共有が出る（2026-10-01 に aarch64 の実機、2026-10-06 に x86_64 の VM で確認）

### 操作上の注意と併記されていた記録

   - 画面では、サイドバーの共有の横の取り出しのボタンで外す（2026-10-06 に VM で確認）

### 実施手順: 検証状況の記録

> [!WARNING]
> - **手順は x86_64 の VM で検証した**（2026-09-27 は QEMU、2026-10-06 はクリーンインストールした VirtualBox）。実機では本実行していない。後者のサーバーは、別 VM で samba.md を通したもの
> - GNOME Files の接続・認証・コピー・F5・切断はクリーンインストールした x86_64 の VM で画面を操作した。キーリングへの保存は確かめていない（[今回の記録](#付録-クリーンインストールした-vm-同士での検証2026-10-06)）

### 実施手順 / 手順 4: 補足: 資格情報ファイル

- 形式は `mount.cifs` の `credentials=` のもの（`username=` と `password=` の 2 行）。Windows のドメインのアカウントなら `domain=` の行を足す
- `printf` はシェルの組み込みなので、パスワードはどのプロセスのコマンドラインにも出ない。`sudo install` が標準入力から受け取り、`root:root` の 0600 で書く
- 置き場所は RHEL 10 の文書の `/root/smb.cred` にならい、名前にユーザーとサーバーを入れて、複数の共有を並べられるようにした
- VM では、ラベルは `system_u:object_r:admin_home_t:s0` になった（`install` が既定のラベルを付ける）
- mount.cifs は、行頭の空白だけを読み飛ばし、`=` の後ろは改行の手前までをそのまま値にする（cifs-utils 7.7 のソース）。`IFS= read -r` で読んだので、パスワードの前後の空白も残る
- VM では、カンマ・空白・`$` を含むパスワードでマウントできた。カンマは、mount.cifs がカーネルへ渡すときに逃がしている
- パスワードを変えたら、手順 3・4 を貼り直す。`install` がファイルを置き換え、次にマウントするときから効く
- VM では、サーバーでパスワードを変えた後、古いファイルのままだと次のマウントが `mount error(13)` で失敗し、手順 3・4 を貼り直すと通った
- 変数が空かどうかは、ブロックの先頭の `if` で確かめる。パイプの中の `${VAR:?…}` は、そのパイプの 1 つのコマンドしか止めない
- 例えば `SMB_USER` が空のまま `${SMB_USER:?…}` だけで確かめると、`/root/smb-@<SERVER>.cred` という空のファイルができる
- `fi; unset PW` を 1 行にしてあるのは、ブロックの全体を 1 つのコマンドにするため。途中の `sudo` が後ろの行を読み取って捨てても、`unset PW` が消えない（[付録](#付録-vm-での検証記録2026-09-27)）

### 実施手順 / 手順 5: 補足: 手でマウントする理由と、失敗の表示

**理由**: 手順 7 の自動マウントでは、失敗は `ls` の `No such device` としてしか出ない。手で 1 度マウントすると、原因が表示で分かる。

- マウントの後を `{ … }` のひとまとまりにしてあるのは、途中で失敗しても必ず外すため
- マウントが残っていると、手順 7 の自動マウントが始まらない。VM では `Path <MOUNT_POINT> is already a mount point, refusing start.` で失敗した
- `$(id -u)` と `$(id -g)` は、`sudo` の前に自分のシェルで展開される

**失敗の表示**（VM での実測。どれも終了コード 32）:

| 原因 | 表示 | `sudo dmesg` |
|---|---|---|
| パスワードが違う | `mount error(13): Permission denied` | `STATUS_LOGON_FAILURE` |
| 共有名が違う | `mount error(2): No such file or directory` | `BAD_NETWORK_NAME` |
| 他人のホーム（samba.md の `valid users = %S`） | `mount error(13): Permission denied` | `cifs_mount failed w/return code = -13` |
| smbd が止まっている | `mount error(111): could not connect to <SERVER>Unable to find suitable address.`（1 秒以内） | — |
| パケットが捨てられる | `mount error(115): could not connect to <SERVER>Unable to find suitable address.`（約 11 秒） | — |

- 資格情報ファイルが無いときは、`error 2 (No such file or directory) opening credential file /root/…` で終了コード 2
- `could not connect to <SERVER>` と `Unable to find suitable address.` の間に改行が無いのは、mount.cifs の表示のまま
- パケットが捨てられるときは、445/tcp と 139/tcp に 5 秒ずつ試してから失敗する

**マウントのオプション**（VM の `findmnt -n -o OPTIONS`）:

```
rw,relatime,vers=3.1.1,cache=strict,upcall_target=app,username=<SMB_USER>,uid=1000,forceuid,gid=1000,forcegid,addr=<SERVER>,file_mode=0600,dir_mode=0700,soft,nounix,serverino,mapposix,reparse=nfs,nativesocket,symlink=native,rsize=4194304,wsize=4194304,bsize=1048576,echo_interval=60,actimeo=1,closetimeo=1
```

### 実施手順 / 手順 6: 補足: fstab の行

足す行（VM での例）:

```
//<SERVER>/<SHARE> <MOUNT_POINT> cifs credentials=/root/smb-<SMB_USER>@<SERVER>.cred,uid=1000,gid=1000,file_mode=0600,dir_mode=0700,x-systemd.automount,x-systemd.idle-timeout=1min 0 0
```

- `x-systemd.automount`: 起動時にはマウントせず、`<MOUNT_POINT>` にアクセスしたときに systemd がマウントする
- `x-systemd.idle-timeout=1min`: 使わないまま 1 分たつと外す
- ほかのオプションは手順 5 と同じ。付けなかったもの（`_netdev`・`nofail`・`vers=`）の理由は[選択した方針](../reference/samba-client.md#選択した方針)
- `daemon-reload` で、`systemd-fstab-generator` が `/run/systemd/generator/` に `mnt-<SHARE>.automount` と `mnt-<SHARE>.mount` を作る（名前は `systemd-escape -p` の結果。`/mnt/` の下なら `mnt-` + 共有名）
- `findmnt --verify` は `sudo` を付ける。付けないと、ほかの行について `cannot detect on-disk filesystem type (Permission denied)` の警告が出る（VM で 3 件）
- 中断の条件は、変数が空のとき、変数に空白があるとき、同じマウント先の行（コメント行は数えない）があるとき。VM で 2 回貼っても、行は増えなかった
- 変数が空かどうかを先頭の `if` で確かめるのは、パイプの中の `${VAR:?…}` がブロックを止めないため
- 直す前の版は、`SMB_USER` が空でも何も足さずに `Success` と出た（レビューのエージェントが `sudo` をスタブにした bash で確かめた）

### GNOME Files で開く（任意） / 手順 3: 補足: 問い合わせと、画面の文言

`/usr/bin/gio mount` の問い合わせ（VM）:

```
Authentication Required
Enter password for share “<SHARE>” on “<SERVER>”:
Domain [SAMBA]:
Password:
```

- URI に `<SMB_USER>@` を入れたので、ユーザー名は聞かれない
- ドメインの既定の `SAMBA` は、この PC の `/etc/samba/smb.conf`（依存で入る samba-common が置く）の `workgroup` の既定値と同じ
- samba.md のサーバーは standalone（`workgroup = WORKGROUP`）だが、ドメインを `SAMBA` のままにしても通った

画面の文言は、EL10 の nautilus 47.6 と GTK 4.16 の UI の定義と日本語の翻訳を調べ、2026-10-06 にクリーン VM の画面でも確認した（キーリングへの保存は未確認）:

- サイドバーの項目は「Network」、アドレスの欄は「Server address」、ボタンは「接続」
- 「Network」と「Server address」は nautilus 47.6 の日本語の翻訳に無いので、英語のまま表示された
- RHEL 10 の文書は「Other Locations」→「Enter server address」と書いているが、nautilus 47.6 の UI の定義はそうなっていない
- 認証の画面（GTK）は「認証が必要です」「ドメイン」「パスワード」。URI にユーザー名を入れた今回の接続ではユーザー名の欄は出なかった。記憶のしかたが「今すぐパスワードを破棄する」「ログアウトするまでパスワードを記憶する」「期限なしで記憶する」、ボタンが「接続する」

### Windows 11 で使う: 検証状況の記録

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、Microsoft と Samba の資料・ソース、Linux の PowerShell 7 での構文と模擬の実行だけ（[対象と検証環境](#対象と検証環境)）。

### 対象と検証環境

- **目的**: [samba.md](../samba.md) で公開したホームディレクトリ（`[homes]` 共有）を、AlmaLinux 10 の PC から、ふだんのディレクトリのように読み書きする
  - `/etc/fstab` に 1 行を足し、`/mnt/<SHARE>` にアクセスしたときに systemd がマウントする（`x-systemd.automount`）。起動時にはマウントしない
  - パスワードは、root だけが読める資格情報ファイルに置く。fstab には書かない
  - GNOME Files（gvfs）でつなぐ方法は、任意節にした
  - Windows 11 の PC では、同じ共有をドライブ文字（既定は `Z:`）に割り当て、サインインのたびにつなぎ直す。パスワードは Windows の資格情報マネージャーに置く（[Windows 11 で使う](../samba-client.md#windows-11-で使う)）
- **進め方**: **冒頭の変数ブロックに値を 1 度書き、以降のコマンドをそのまま貼る**
  - 読者が編集するのは `SERVER` だけ（NAS や Windows の共有なら `SMB_USER` と `SHARE` も）
  - Windows 11 は、管理者ではない Windows PowerShell 5.1 に貼る。読者が編集するのは `SERVER` と `SMB_USER`
- **状態（AlmaLinux 10）**: **x86_64 の VM で検証済み（QEMU: 2026-09-27 / クリーンインストールした VirtualBox: 2026-10-06）。実機では本実行していない**
  - 2026-10-06: 先行検証とは別の新規 VM で現行本文を再検証した（[今回の記録](#付録-新規-vm-での現行手順の再検証2026-10-06)）。検証専用のアカウント・鍵・隔離 LAN を使った
  - このクラウドのホストのカーネルには CIFS が無く、コンテナでは `mount -t cifs` を試せない。そこで QEMU の VM（KVM 無しの TCG）で、AlmaLinux 10.2 の GenericCloud イメージを動かした
  - VM の SELinux は Enforcing、firewalld は active
  - サーバーは、samba.md 手順 3 の `smb.conf` をそのまま置いたコンテナ（同じホストの Docker）
  - **この文書のコードブロックをそのまま貼って**、手順 1〜7、GNOME Files の節、ロールバックを通した
  - 貼り方は、ブラケットペーストとブラケットペースト無しの 2 通りで、それぞれまっさらな VM で通した
  - 確認したこと:
    - 手でのマウントと、アクセスしたときの自動マウント（SMB 3.1.1、`cifs_t`、AVC 無し）
    - 使わないまま 1 分で外れること、再起動した後もアクセスでマウントされること
    - サーバーが止まっていても起動が止まらないこと、届かないときの待ち時間と表示
    - ほかのローカルユーザーが読めないこと、日本語のファイル名
    - `gio mount` での接続と、FUSE のパス
    - ロールバックの後に、fstab の行・ユニット・資格情報ファイル・マウント先が残らないこと
    - 手順 1 の変数が空のとき、変数を使うブロックが何も変えずに中断すること
  - **確認していないこと**: 実機（x86_64 PC・Raspberry Pi 5）での実行、GNOME のキーリングへの保存、Wi-Fi の切り替えとサスペンドからの復帰、WireGuard 越しの fstab 自動マウント、Windows や NAS の共有。WireGuard 越しの手動マウントは新規 VM で確認済み（[今回の記録](#付録-新規-vm-での現行手順の再検証2026-10-06)）
  - 実測の記録は[付録](#付録-vm-での検証記録2026-09-27)
  - 2026-09-29: 手順 1 に、samba.md の `[root]`（root のホーム）へ `SHARE=root` でつなぐ案内を足した
    - samba.md の VM（サーバーと同じ VM から `127.0.0.1` あて）で、手順 1〜5 とロールバックの手順 3 を `SHARE=root` で貼って通した（ブラケットペーストの有りと無しで 1 回ずつ。[samba.md の付録](samba.md#付録-root-のホームを公開する節の-vm-での検証2026-09-29)）
    - `SHARE=root` での自動マウント（手順 6・7）は試していない
  - 2026-10-05: 手順 1 に、samba.md の `[home]`（`/home`）へ `SHARE=home` でつなぐ案内を、手順 5 に、そのときの書き込みの失敗を足した
    - samba.md の VM（サーバーと同じ VM から `127.0.0.1` あて）で、手順 1〜5 とロールバックの手順 3 を `SHARE=home` で貼って通した（ブラケットペーストの有りと無しで 1 回ずつ。[samba.md の付録](samba.md#付録-home-を公開する節の-vm-での検証2026-10-05)）
    - 手順 5 は、`cifs-test.txt` の書き込みが `Permission denied` になり、マウントの確かめと外すところは通った
    - `SHARE=home` での自動マウント（手順 6・7）は試していない
  - 2026-10-01: [注意点](../extra/samba-client.md#注意点)に、サーバーで直接変えたものが見えるまでと、GNOME Files の再読み込みを足した。GNOME Files の節の手順 4 の、サイドバーの表示も確かめた
    - aarch64 の実機（Raspberry Pi 5、カーネル 6.12.96）の cifs と、同じ実機のヘッドレスの GNOME のセッションの Nautilus（[claude-code-gui.md](../claude-code-gui.md) で撮った）で、実機の上のコンテナの Samba（samba.md 手順 3 の smb.conf）につないで測った（[samba.md の付録](samba.md#付録-サーバーで変えたものがクライアントに見えるまで2026-10-01)）
    - この文書のブロックは貼っていない。マウントは、手順 5 と同じオプションに `port=4450` を足して手で行い、GNOME Files は `/usr/bin/gio mount` でつないでから Nautilus で開いた
  - 2026-10-02: もとの手順 2・3 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-08 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](#付録-windows-11-の資料の調査と-powershell-のブロックの-linux-での確認2026-10-08)）:
    - 資料: Microsoft の SMB の署名（24H2 の Pro・Enterprise・Education は必須、Home は求めない）・`cmdkey`・`New-SmbMapping`・`Remove-SmbMapping`・管理者の窓とドライブ文字・サインインのときのつなぎ直し・SMB の NTLM のブロックの文書
    - サーバーの設定: samba.md 手順 3 の smb.conf は `server signing` と `map to guest` を書かず、既定のまま。その既定（smb.conf(5) と、samba.md の前の `testparm -sv` の記録）は、Windows 11 Pro の署名の必須とゲストの禁止に合う
    - `smbstatus` の `Signing` の表示: Samba 4.23.5 のソース（`source3/utils/status.c`）で、全体に署名した接続は方式の名前だけ、一部だけなら `partial(…)`、無ければ `-`
    - PowerShell のブロック: Linux の PowerShell 7.5.3 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。Windows 11 の 3 節のブロックを、偽物の `Test-NetConnection`・`Get-SmbMapping`・`New-SmbMapping`・`Remove-SmbMapping`・`cmdkey` で流した
  - **確かめていないこと**: Windows で貼ること（すべての手順）、`cmdkey /pass` の問い方と同じ宛先の上書き、資格情報を渡さない `New-SmbMapping` が資格情報マネージャーの資格情報でつなぐこと、エクスプローラーへの表示、サインインのときのつなぎ直しとサーバーに届かないときの表示、`smbstatus` の `SMB3_11` と署名、`Remove-SmbMapping -UpdateProfile` の後に残るもの、エラー 1219、Home の Windows、`[root]`・`[home]` の割り当て、WireGuard 越しの割り当て
  - 2026-10-01 に、利用者の Windows の PC のエクスプローラーから samba.md の実機のサーバーにつないだときの `smbstatus` は `SMB3_11`・署名 `AES-128-GMAC` だった（[samba.md の付録](samba.md#付録-サーバーで変えたものがクライアントに見えるまで2026-10-01)。その PC は、同じ日の [windows-claude-remote-control.md の記録](windows-claude-remote-control.md)では Windows 11 Pro 26H2）。ドライブ文字への割り当てではない

AlmaLinux 10:

| 項目 | 実機 | VM |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64 PC・aarch64（Raspberry Pi 5） | AlmaLinux 10.2 (Lavender Lion) / x86_64（GenericCloud の `10.2-20260817.0` を `dnf upgrade` した） |
| 仮想化 | — | QEMU 8.2.2 の TCG（`-cpu max`、4 vCPU、4 GiB）。ホストは Ubuntu 24.04 / x86_64 のクラウドの VM |
| カーネル | 未確認 | `6.12.0-211.56.1.el10_2`（`cifs.ko` は `kernel-modules` に入っている） |
| `cifs-utils` | 未確認 | `7.7-1.el10_2`（BaseOS） |
| `gvfs-smb` / `gvfs-fuse` | 未確認 | `1.54.4-3.el10`（AppStream） |
| systemd / util-linux / sudo | 未確認 | `257-23.el10_2.2.alma.1` / `2.40.2-18.el10` / `1.9.17-10.p2.el10_2.6` |
| SELinux / firewalld | 未確認 | Enforcing（`selinux-policy-targeted-42.1.18-4.el10_2.3`）/ `2.4.3-4.el10_2`、active（既定ゾーン `public`。本書では変えない） |
| サーバー | — | `quay.io/almalinuxorg/almalinux:10.2` のコンテナ、`samba-4.23.5-110.el10_2`、samba.md 手順 3 の `smb.conf`。VM からは QEMU の user ネットワークのホスト側（`10.0.2.2`）で届く |

Windows 11（前提にしている環境。ほかの Windows の手順書の実機の記録と同じ PC を想定）:

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro（24H2 以降。利用者の PC は 26H2）。Home は署名を求めない（[注意点](../extra/samba-client.md#注意点)） |
| PowerShell | Windows PowerShell 5.1（管理者ではない窓） |
| サーバー | samba.md 手順 3 の smb.conf の Samba（`samba-4.23.5-110.el10_2`） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../samba-client.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${SERVER}` | Samba サーバーの IP アドレスか DNS 名（samba.md の `SERVER_IP`） | `192.168.1.10` |
> | `${SMB_USER}` | サーバーの Samba ユーザー（既定はこの PC のユーザー名。違えば直す） | `${USER}` |
> | `${SHARE}` | 共有名（既定は `SMB_USER`。samba.md の `[homes]` ではユーザー名と同じ） | `${SMB_USER}` |
> | `${MOUNT_POINT}` | マウント先（既定は `/mnt/` の下の共有名） | `/mnt/${SHARE}` |
>
> 出力例・ログ・表の中の値は `<SERVER>` / `<SMB_USER>` / `<SHARE>` / `<MOUNT_POINT>` / `<USER>`（この PC のユーザー名）/ `<UID>`（その uid）/ `<PORT>` のプレースホルダで書いてある。ただし、VM の出力の `uid=1000` / `gid=1000` は、そのままにしてある。
>
> Windows 11 の節の変数は、PowerShell の `$SERVER`・`$SMB_USER`・`$SHARE`・`$DRIVE`（割り当てるドライブ文字。既定は `Z:`。出力例では `<DRIVE>`）。
>
> Samba のパスワードはこの文書に載せない。検証で使ったものは `openssl rand` で作った使い捨てで、記録していない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

Windows 11 の節は流していない（記録は無い）。

VM で、手順 1 の前に確かめた状態:

| 項目 | 状態 |
|---|---|
| `cifs-utils` / `samba-client` / `samba-common` | 未導入 |
| `gvfs` / `gvfs-smb` / `gvfs-fuse` | 未導入（GenericCloud には GNOME が無い） |
| `cifs.ko` | `kernel-modules` に入っていて、読み込まれていない |
| `/etc/fstab` | `/`・`/boot`・`/boot/efi` の 3 行。`sudo findmnt --verify` は `Success, no errors or warnings detected` |
| SELinux | Enforcing。`mount_anyfile` は on、`use_samba_home_dirs` は off |
| firewalld | active。`public (default)` に `eth0`、services は `cockpit dhcpv6-client ssh` |
| `/mnt` | 空 |
| ローカルユーザー | `<USER>`（uid 1000、`wheel`）と、確かめ用の 2 人目（uid 1001） |

### 完了時点の状態

Windows 11 の節は流していない（記録は無い）。

VM で、手順 7 の後に確かめた状態:

```
$ tail -1 /etc/fstab
//<SERVER>/<SHARE> <MOUNT_POINT> cifs credentials=/root/smb-<SMB_USER>@<SERVER>.cred,uid=1000,gid=1000,file_mode=0600,dir_mode=0700,x-systemd.automount,x-systemd.idle-timeout=1min 0 0
$ systemctl cat mnt-<SHARE>.automount
# /run/systemd/generator/mnt-<SHARE>.automount
# Automatically generated by systemd-fstab-generator

[Unit]
SourcePath=/etc/fstab
Documentation=man:fstab(5) man:systemd-fstab-generator(8)

[Automount]
Where=<MOUNT_POINT>
TimeoutIdleSec=1min
$ systemctl show mnt-<SHARE>.mount -p Wants -p After
Wants=network-online.target
After=-.mount system.slice remote-fs-pre.target systemd-journald.socket network.target mnt-<SHARE>.automount network-online.target
$ systemctl show remote-fs.target -p Requires
Requires=mnt-<SHARE>.automount
$ sudo ls -lZ /root/smb-<SMB_USER>@<SERVER>.cred
-rw-------. 1 root root system_u:object_r:admin_home_t:s0 44 Sep 27 19:53 /root/smb-<SMB_USER>@<SERVER>.cred
```

サーバー側の `smbstatus`（マウント中）:

```
PID     Username     Group        Machine                                   Protocol Version  Encryption           Signing
----------------------------------------------------------------------------------------------------------------------------------------
1467    <SMB_USER>   <SMB_USER>   127.0.0.1 (ipv4:127.0.0.1:<PORT>)         SMB3_11           -                    partial(AES-128-CMAC)
```

`Machine` が `127.0.0.1` なのは、QEMU の user ネットワークがホストのループバックへつなぐため。

### 操作上の注意と併記されていた記録

  - 制限のあるサービス（Apache など）から使うなら、そのサービスの boolean（`httpd_use_cifs` など）が要る（本書では試していない）

### 操作上の注意と併記されていた記録

  - ブラケットペーストが効かない端末で複数行を貼ると、途中の `sudo` が後ろの行を読み取って捨てるため（[付録](#付録-vm-での検証記録2026-09-27)）

### 注意点 / 手順 0: 本文中の記録

  - トンネル越しに 445/tcp へ届くことは [wireguard-road-warrior.md の付録](wireguard-road-warrior.md#付録-実機での検証記録)で確かめてあるが、マウントは確かめていない

### 注意点 / 手順 0: 本文中の記録

  - ディレクトリのリースを渡すサーバー（Samba 4.22 以降の既定。2026-10-01 より前の samba.md のサーバーも）では、一覧をキャッシュしてから 30〜60 秒、`ls` に古い一覧が出た（cifs の `dir_cache_timeout` の既定 30 秒）

### 注意点 / 手順 0: 本文中の記録

  - どれも、aarch64 の Raspberry Pi 5 のカーネル（6.12.96）の cifs と、コンテナの Samba で測った（[samba.md の付録](samba.md#付録-サーバーで変えたものがクライアントに見えるまで2026-10-01)）

### 注意点 / 手順 0: 本文中の記録

  - どの形の `sudo` で失われるかは、[もう 1 つの付録](#付録-sudo-の後ろの行が失われる条件2026-09-28)にまとめた

### 付録: VM での検証記録（2026-09-27）

x86_64 のクラウドホストの上で、使い捨ての VM とコンテナを使った。実機で加えた変更は無い。

**環境**:

- ホストは Ubuntu 24.04 / x86_64 のクラウドの VM。カーネル 6.18 に CIFS が無く（`CONFIG_CIFS` 無し、モジュールも読めない）、`/dev/kvm` も無い
- クライアントは `AlmaLinux-10-GenericCloud-10.2-20260817.0.x86_64.qcow2`（`CHECKSUM` の SHA-256 と一致）。QEMU 8.2.2 の TCG（`-accel tcg,thread=multi -cpu max -smp 4 -m 4096`）で起動した
- cloud-init（NoCloud）で次を入れた
  - `<USER>`（uid 1000、`wheel`）と、確かめ用の 2 人目（uid 1001、NOPASSWD の `sudo`）
  - このホストのプロキシの CA と、dnf の `proxy=`（HTTPS の CONNECT しか通さないプロキシの内側）
- サーバーは `quay.io/almalinuxorg/almalinux:10.2`（`sha256:8322019…`）のコンテナ。Docker 29.3.1 で `--network host` で立てた
  - `samba` を入れ、samba.md 手順 3 の `smb.conf`（`WORKGROUP=WORKGROUP`）をそのまま置いた
  - `useradd -u 1000 <USER>` と `smbpasswd -s -a` の後、`smbd --foreground` で動かした
  - samba.md 手順 4・5（SELinux と firewalld）は、コンテナなので行っていない
  - VM からは、QEMU の user ネットワークのホスト側 `10.0.2.2` で、ホストの 445/tcp に届く

**検証の準備（手順書の外）**:

- AlmaLinux の mirrorlist が `http://` のミラーを返し、プロキシが CONNECT 以外の要求を断った
  - そこで VM とサーバーのコンテナの `almalinux-*.repo` の `mirrorlist=` を止め、コメントになっていた `baseurl=https://repo.almalinux.org/...` を有効にした（claude-code.md の付録と同じ手当て）
- VM を `dnf upgrade` した（54 パッケージ。カーネルは 6.12.0-211.47.1 から 211.56.1 へ）
- 確かめ用に `setools-console`・`firewalld`（有効にした）・`glibc-langpack-ja`・`policycoreutils-python-utils` を入れた
- この状態のディスクを残し、検証の回ごとに、その上の overlay で起動した
- 途中でホストのコンテナが再起動し、プロキシのポートが変わった。その後の回は、起動した VM の dnf の `proxy=` のポートを直してから流した
  - 直す前に流し始めた 1 回は、手順 2 のダウンロードが `Curl error (7)` で失敗したので捨てた

**流し方**:

- ホストの tmux の中から `ssh -t` で VM にログインし、この文書から抜き出したコードブロックを 1 手順ずつ貼った
  - 手順 1 の `SERVER` だけは `10.0.2.2` に書き換えた
- 貼り方は 2 通り
  - bash 5.2 の既定のブラケットペーストで貼ってから Enter（GNOME の端末や WezTerm と同じ）
  - ブラケットペースト無し（行を先に打ち込むのと同じ。途中のコマンドが後ろの行を読めてしまう）
- 次のものは、画面に問い合わせが出てから入力した: 手順 3 のパスワード、`gio mount` の問い合わせ、`[y/N]`
- 書き上げた後に、独立したレビューの指摘でブロックを直した（下の「レビューで見つけたこと」）
- 直した版を、まっさらな overlay で 2 回通した（ブラケットペースト無しの回と、ブラケットペーストの回）。対象は手順 1〜7・GNOME Files の節・ロールバック。下の表はその 2 回の結果で、2 回とも同じだった

**最初の回で見つけたこと**: 最初の回はブラケットペースト無しで貼った。すると、手順 5 の最後の行（当時は `&&` の連鎖の後ろに独立した `sudo umount`）が実行されず、共有がマウントされたまま残った。

- 原因は sudo 1.9.17 の `use_pty`（既定で有効）。`sudo` が、端末に先に入っていた入力（貼った残りの行）を読み取ってコマンドの疑似端末へ渡し、コマンドが読まないまま捨てる
- `sudo true` と `echo` の 2 行で確かめた。ブラケットペースト無しでは `echo` が実行されず、ブラケットペーストでは Enter の後に 2 行とも実行された
- 手順 5 は、マウントの後の確かめと `umount` を `{ … }` のひとまとまりにして、どちらの貼り方でも外れるようにした
- マウントが残ったまま自動マウントを始めると、`Path <MOUNT_POINT> is already a mount point, refusing start.` で失敗する（手順の外で確かめた）

**レビューで見つけたこと**: 書き上げた後に、独立したエージェントに CLAUDE.md の規則との突き合わせを頼んだ。ブロックにかかわる指摘が 2 つあった。

- **空の変数でブロックが止まらない**
  - パイプや `$(…)` の中の `${VAR:?…}` は、そのサブシェルしか止めない
  - 直す前の手順 4 は、`SMB_USER` が空だと、空の `/root/smb-@<SERVER>.cred` を作った（VM で再現した）
  - 直す前の手順 6 は、何も足さずに `Success` と出た。ロールバックの手順 1 は、`-.mount` を止めに行った（どちらも、レビューのエージェントが `sudo` をスタブにした bash で確かめた。VM では試していない）
  - 変数を使うブロックの先頭で、`if [ -z … ]` で中断するようにした
- **吸われる行が残っていた**: 手順 4 の `unset PW`、手順 7 の `ausearch`、ロールバックの手順 3 の `if … fi`
  - どれも、ブロックの全体を 1 つのコマンドにした（`fi; unset PW` を 1 行にする、`if … fi` の中に入れる）

直した版で確かめたこと:

- 手順 1 を貼っていない新しいシェルで、次のブロックを貼った。どれも、中断のメッセージか `:?` のエラーだけで終わった
  - 手順 2 の確かめの行（もとの手順 3）、手順 4・5・6・7
  - GNOME Files の節の手順 3・5
  - ロールバックの手順 1〜3
- その後も、`/root` の資格情報ファイル・fstab・`mnt-*` のユニット・`/mnt` は変わらず、`-.mount` も active のままだった
- `SMB_USER` だけが空のシェルで貼ると、手順 4 と手順 6 は中断した。手順 4 の後は `PW` も消えていた
- ブラケットペースト無しの回で、次のことを確かめた
  - 手順 4 の後に `PW` が消えていた
  - 手順 7 の `ausearch` が `<no matches>` を出した
  - ロールバックの手順 3 で、資格情報ファイルが消えた

| 手順 | 結果（直した版を 2 通りの貼り方で通した回。同じだった） |
|---|---|
| 1 | 読み戻しは `SERVER = <SERVER>`、`USER`・`SMB_USER`・`SHARE` が `<USER>`、`MOUNT_POINT = <MOUNT_POINT>` |
| 2 | 7 パッケージ（16 MB）。もとの手順 2 をもう一度貼ると `Package cifs-utils-7.7-1.el10_2.x86_64 is already installed.` と `Nothing to do.`（直す前の版で確認）。確かめの行（もとの手順 3）は `cifs-utils-7.7-1.el10_2.x86_64`、`/lib/modules/6.12.0-211.56.1.el10_2.x86_64/kernel/fs/smb/client/cifs.ko.xz`、`445/tcp に届く` |
| 3 | `Samba password for <SMB_USER>@<SERVER>:` の後に入力した |
| 4 | `-rw-------. 1 root root system_u:object_r:admin_home_t:s0 … /root/smb-<SMB_USER>@<SERVER>.cred`。この後、`PW` は空 |
| 5 | `findmnt` に `cifs` の行（`vers=3.1.1`）、`cifs write`、`drwx------. 2 <USER> <USER> system_u:object_r:cifs_t:s0`。この後の `findmnt` には何も出ない（外れた） |
| 6 | 足した 1 行と `Success, no errors or warnings detected`。もう一度貼ると `中断: /etc/fstab に <MOUNT_POINT> の行が既にある` で、行は増えない |
| 7 | `active`、`autofs` と `cifs` の 2 行、`automount write`、`<no matches>` |
| GNOME Files 1〜2 | 2 つとも `is not installed`。GNOME Files の節の手順 2 で 42 パッケージ（14 MB） |
| GNOME Files 3 | `Authentication Required` と `Enter password for share “<SHARE>” on “<SERVER>”:` の後に、`Domain [SAMBA]:`（Enter）と `Password:` |
| GNOME Files 4〜5 | `Mount(0): <SHARE> on <SERVER> -> smb://<SMB_USER>@<SERVER>/<SHARE>/` と `smb-share:server=<SERVER>,share=<SHARE>,user=<SMB_USER>`。GNOME Files の節の手順 5 は、何も出ずに外れた |
| ロールバック 1〜3 | マウントしていた共有が外れた。`findmnt --verify` は成功で、`diff` は `15d14` と消した 1 行。マウント先・資格情報ファイル・`mnt-*` のユニットが消えた |
| ロールバック 4〜5 | 手順 4 は cifs-utils だけを消した（依存は、GNOME Files の節で入った libsmbclient が使う）。手順 5 は 21 パッケージ（72 MB） |
| 再起動 | `running` で failed は 0 件。`mnt-*` のユニット、`/mnt` の下、fstab の cifs の行、資格情報ファイルは無い。`/etc/fstab.bak-samba-client` は残る。起動してからの AVC も無い |

**手順の外で確かめたこと**:

| 確かめたこと | 結果 |
|---|---|
| idle-timeout | 最後に使ってから約 60 秒で外れた。共有の中をカレントディレクトリにしたシェルがある間は外れず、抜けてから約 55 秒で外れた |
| 再起動（サーバーが動いている） | `running`。`.automount` が active で、最初のアクセスでマウントした（3.1 秒） |
| 再起動（smbd を止めたまま） | `running` で起動した（failed は 0 件）。アクセスは 2.7 秒で `No such device`、その後は `degraded`。smbd を戻してアクセスすると、マウントされて `running` に戻った |
| 届かないとき（マウントしていない） | 断られると、`ls` が 0.6 秒で `No such device`。パケットが捨てられると 10.8 秒 |
| 届かないとき（マウント中） | `ls` はキャッシュから返った。`cat` は 2 分 59 秒待って `Resource temporarily unavailable`。その後、1 分の idle-timeout で外れた（外すのに 0.3 秒） |
| 2 人目のローカルユーザー | `ls: cannot open directory '<MOUNT_POINT>': Permission denied`。root は読めた |
| 日本語のファイル名 | この PC で作った `日本語のファイル.txt` と `日本語のフォルダ`、サーバーで作った `サーバー側で作った.txt` が、両側で同じ名前に見えた。サーバー側のモードは 0644 と 0755 |
| `sudo mount -a` | 1 回目は `mount error(16): Device or resource busy`（終了コード 32）。共有は 1 つだけマウントされ、2 回目は何も出さない。カーネルのログに `x-systemd.*` を拒んだ跡は無い |
| パスワードの変更 | サーバーで変えた後、古い資格情報ファイルでは `mount error(13)`。手順 3・4 を貼り直すと通った |
| ロールバック手順 3 の分岐 | 同じ資格情報ファイルを使う行を fstab に足した状態で貼ると、`資格情報ファイルは、/etc/fstab のほかの行が使っているので残す` と出て、ファイルを残した |
| SELinux | 通常のポリシーでも、`semodule -DB` で dontaudit を外しても、自動マウントと手でのマウントで AVC は出なかった |
| gvfsd が動いたまま gvfs-smb を入れる | gvfs-smb だけを消して入れ直しても、同じ gvfsd（PID が同じ）で `gio mount` が通った |

#### 未確認事項

- 実機（x86_64 PC・Raspberry Pi 5）での実行。aarch64 では通していない
- GNOME Files の画面の操作（「Network」「Server address」「接続」）、認証の画面、キーリングへの保存、サイドバーの表示
- Wi-Fi の切り替えや、サスペンドからの復帰の後の振る舞い
- WireGuard 越しのマウント（445/tcp に届くことだけは、wireguard-road-warrior.md の付録で確認済み）
- Windows や NAS の共有、`domain=` を使うドメインのアカウント
- `SERVER` を DNS 名にしたときに、サーバーの IP アドレスが変わった後の再接続
- 同じ共有を、fstab のマウントと GNOME Files の両方でつないだときの振る舞い

### 付録: sudo の後ろの行が失われる条件（2026-09-28）

ほかの手順書のブロックを直す前に、どの形の `sudo` が後ろの行を捨てるかを確かめた。

- 環境: 上の付録と同じ VM を、まっさらな overlay で起動した（AlmaLinux 10.2、`sudo-1.9.17-10.p2.el10_2.6`、`bash-5.2.26-6.el10`。`use_pty` は既定のまま）
- 貼り方: 上の付録と同じ tmux の harness で、ブラケットペースト無しで貼った
- 確かめ方: 各ブロックの最後の行を `echo T1-L2-$((1+1))` のようにした。実行されたときだけ `T1-L2-2` が出る
- `sudo` の資格情報がキャッシュされている回で試した（NOPASSWD と同じく、パスワードを聞かない）

| 1 行目の形 | 結果 |
|---|---|
| `sudo true`（標準入力が端末） | 失われた |
| `sudo -u <USER> true` | 失われた |
| `sudo true </dev/null` | 失われた |
| `sudo tee /tmp/t2 >/dev/null <<'EOF'`（ヒアドキュメント） | 実行された |
| `echo x \| sudo tee /tmp/t3 >/dev/null`（パイプ） | 実行された |
| `h=$(sudo cat /etc/hostname)` | 実行された |
| 行末の `&&` で次の行へつなぐ（`sudo true &&`） | 実行された |
| 全体を `{` と `}` の行で囲む | 実行された（中が `sudo true`・ヒアドキュメント・パイプ・行末のコメントの 4 通り） |

- ブラケットペーストで貼ると、`sudo true` の後ろの 2 行は実行された。`{ … }` で囲んだ形も実行された
- 失われた行は、画面に表示されたが、実行されなかった
- このため、ほかの手順書では `sudo` の形によらず、後ろに行が続くブロックを `{ … }` で囲んだ（[README の記法](../../README.md#記法)）
- 囲んだ samba.md を同じ貼り方で流したとき、ヒアドキュメントの行頭の TAB が bash の補完で `.` に置き換わることも分かった（[samba.md 手順 3](../samba.md#実施手順) の補足）

### 付録: クリーンインストールした VM 同士での検証（2026-10-06）

AlmaLinux 10.2 Workstation を ISO から入れた VirtualBox の VM（x86_64、カーネル `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing）から、別 VM で samba.md を通したサーバーへつないだ。一般ユーザーの SSH PTY に、現行の手順 1〜7 をブラケットペースト無しで貼った。`SERVER` と検証専用パスワードだけを入れた。

- `cifs-utils 7.7`・`gvfs-smb`・`gvfs-fuse` は Workstation に初めから入っていた。手順 2 は追加導入なしで通り、カーネル同梱の `cifs.ko.xz` を使った
- root の 0600 の資格情報、SMB 3.1.1 の手でのマウント、読み書き・削除・アンマウントが通った。`cifs_t`、ファイル 0600・ディレクトリ 0700、AVC は無かった
- fstab の行の追加と `findmnt --verify` が通り、automount は active、アクセスで autofs と cifs の 2 行が出た
- `SHARE=root` でも自分の資格情報のまま手でのマウント・書き込みが通った。`SHARE=home` はマウントと一覧が通り、共有直下の書き込みは文書の説明どおり拒否された

再起動後は automount が SSH ログイン前に active になり、アクセスで CIFS がマウントされ、読み書きできた。未使用で待つと CIFS が外れて autofs だけになり、再アクセスでまた CIFS が付いた。確認途中の `findmnt -R /mnt/<SHARE>` はパスを参照して idle の計測を妨げる可能性があるため、取り直しでは `/proc/self/mountinfo` を読むだけにした。

ロールバック 1〜3 を通し、fstab の対象の 1 行・マウントと生成ユニット・マウント先・root の資格情報が消え、`findmnt --verify` は成功した。手順 2 の `diff` の終了 1 は、対象行だけが消えた通常の差分。初めから入っていた cifs-utils と gvfs は削除しなかった。

GNOME Files の任意節は、さらに別の Workstation VM のヘッドレスの GNOME セッションで画面を操作した。Network → Server address に URI を入れ、認証の既定「ログアウトするまでパスワードを記憶する」を「今すぐパスワードを破棄する」に変えて接続した。サイドバーの共有、GIO の一覧と GVFS の実体、ファイルの作成・コピーが一致した。サーバーで直接作った 2 個目のファイルが更新前の PNG には無く、Files にフォーカスを合わせて F5 を送ると現れ、内容も一致した。取り出しボタンでサイドバー・GIO・GVFS から消えた。マウント名は日本語では「<SERVER> 上の <SHARE>」だった。

実機の CIFS マウントは今回も検証していない。WireGuard 越しの CIFS、別のローカルユーザーのアクセス、キーリングは今回の確認には含めていない。

### 付録: 新規 VM での現行手順の再検証（2026-10-06）

同日の先行検証に使った VM と分け、ISO 導入直後の AlmaLinux 10.2 Workstation から新しい x86_64 VM を用意して、`5da3478` の現行本文を再検証した。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active。一般ユーザーの SSH PTY にブラケットペースト無しで貼り、手順ごとに結果を確認した。

新しい相手 VM から、別の新規 VM で samba.md を通したサーバーへ接続し、手順 1〜7 を実行した。cifs-utils 7.7 と gvfs-smb/gvfs-fuse 1.54.4 は Workstation の初期状態に入っていた。資格情報は root の 0600、手動マウントは SMB 3.1.1・cifs_t、作成・読み戻し・削除・unmount が成功した。

fstab は findmnt --verify で成功し、アクセスで autofs と CIFS が重なってマウントされた。70 秒間マウント先に触れず、/proc/self/mountinfo だけを読んだ時点では CIFS が消えて autofs が残り、再アクセスで CIFS が戻った。OS 再起動後も automount は active、読み書きが成功した。root の手動マウントも成功し、home の共有直下への書き込みは Permission denied だった。

Road Warrior の新規 VM でも、SERVER を WG ホストのトンネル IP にして手順 1〜5 を通した。SMB 3.1.1 の手動マウントで作成・読み戻し・削除が成功し、ip route get は wg0 を示した。WireGuard 越しの fstab 自動マウントは、この確認に含めていない。

GNOME Files の任意節は別の新規 Workstation VM の画面で接続・認証した。ドメインは SAMBA の既定、記憶の選択は「今すぐパスワードを破棄する」。ローカルのファイルを Ctrl+C/Ctrl+V で共有へ写し、GVFS とサーバーの実体が一致した。サーバーで作成した別ファイルは F5 前は無く、F5 後に出現し、GVFS で内容が一致した。取り出し後はサイドバー・GIO・GVFS に残らなかった。gvfs-smb/gvfs-fuse は既設なので追加導入・削除は行っていない。

ロールバック 1〜3 で mount/automount・fstab の該当行・資格情報・マウント先が消え、findmnt --verify も成功した。diff が変更を表示して返す終了 1 は想定どおり。既設の cifs-utils/gvfs は残した。実機、キーリング保存、Wi-Fi 切り替え、サスペンド復帰、Windows/NAS の共有はこの再検証で確認していない。


### 付録: Windows 11 の資料の調査と PowerShell のブロックの Linux での確認（2026-10-08）

Windows を動かせない環境（クラウドの Linux のコンテナ）で確かめた記録。Windows では、どのブロックも貼っていない。

**資料**（2026-10-08 に取得。括弧の日付は各ページの `ms.date`）:

- Microsoft の「Control SMB signing behavior」（2025-08-13）: 「Windows 11, version 24H2 Enterprise, Pro, and Education require both outbound and inbound SMB signing.」「Windows 11, version 24H2 Home edition doesn't require outbound or inbound SMB signing.」
  - 署名を求めると、ゲストでの接続もできなくなる。署名を許さないサーバーには `STATUS_INVALID_SIGNATURE`（`0xc000a000`）で断られる
  - 署名を確かめるコマンドは `Get-SmbClientConfiguration | FL RequireSecuritySignature`。変える例（`Set-SmbClientConfiguration -RequireSecuritySignature $false`）は、昇格した窓で行うもので、勧めないと書いてある
  - Kerberos を使うことと、IP アドレスでつながないことを勧めている。standalone の Samba は NTLMv2 で認証するので、この勧めは当たらない
- smb.conf(5)（samba.org の current）
  - `server signing` の既定は `default`（AD の DC でなければ、SMB1 の署名を求めない）。「For the SMB2 protocol, by design, signing cannot be disabled.」「Setting it to mandatory will still require SMB2 clients to use signing.」
  - `map to guest` の既定は `Never`（パスワードが違うログインは断る）。`ntlm auth` の既定は `ntlmv2-only`
- [samba.md の付録](samba.md#付録-実機での検証記録2026-09-21)の `testparm -sv`: `map to guest = Never`・`server signing = default`・`server smb3 signing algorithms = AES-128-GMAC, AES-128-CMAC, HMAC-SHA256`・`server smb encrypt = default`。samba.md 手順 3 の smb.conf は、どれも書いていない
- Samba 4.23.5 の `source3/utils/status.c`（GitHub の samba-team/samba の `samba-4.23.5` タグ）: `Signing` の欄は、全体に署名した接続（`CRYPTO_DEGREE_FULL`）なら方式の名前だけ、一部だけ（`CRYPTO_DEGREE_PARTIAL`）なら `partial(<方式>)`、無ければ `-`
  - この文書の Linux の cifs（署名を求めない）の接続は `partial(AES-128-CMAC)` だった（[完了時点の状態](#完了時点の状態)）
- Microsoft の `cmdkey`（2017-10-16）: 「/pass:<password> ... If <password> isn't supplied, it will be requested.」「/delete:<targetname>」。`/user` だけを付けた例は、つなぐたびにパスワードを聞く形として載っている
- `New-SmbMapping`（windowsserver2025-ps の版、2024-02-22）: `-Persistent <Boolean>`。例の出力は `Status OK`。`-Credential` と `-BlockNTLM` もある（Windows 11 の SmbShare に `-Credential` があるかは確かめていない。本書では使わない）
- `Remove-SmbMapping`（同じ版、2024-02-22）: `-UpdateProfile` は、割り当てを恒久的に外し、起動し直してもつなぎ直さない
- 「Mapped drives aren't available from an elevated command prompt」（2026-02-12）: UAC が有効なら、サインインのときにつながった 2 つのログオン セッション（昇格したものと、そうでないもの）ができる。ドライブの割り当ては、作ったセッションの側にだけある
- 「Mapped network drive may fail to reconnect」（2026-02-12。Windows 10 1809 の記事）: エクスプローラーのドライブに赤い ×、`net use` で `Unavailable`、通知に「Could not reconnect all network drives.」。割り当てのスクリプトは、エクスプローラーと同じ権限（昇格しない）で動かすよう書いてある
- 「Block NTLM connections on SMB」（2024-10-25）: Windows 11 24H2 と Windows Server 2025 から、SMB のクライアントで NTLM をブロックするよう設定できる。除外は、グループ ポリシーの「Block NTLM Server Exception List」に IP アドレス・NetBIOS 名・FQDN を書く（作るのに相当する PowerShell は無い）
- 採らなかった割り当て方の資料（`net use /savecred`、`New-PSDrive -Persist`）は、[参考資料の選択した方針](../reference/samba-client.md#選択した方針)にまとめた

**PowerShell のブロック**:

- Windows 11 の 3 節の `powershell` のブロック 10 個を、Linux の PowerShell 7.5.3 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer 1.25.0 の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0
- 既定の規則の指摘は、ASCII でない文字を含むファイルの BOM（10 件）と、必須の変数の 1 変数だけのブロックの「代入して使っていない」（2 件）だけ
- 見直しの後（Windows 11 で使うの手順 7 を `bash` のブロックにした後）にもう一度通し、3 つの数は同じだった
- Windows 11 で使うの手順 7 の `bash` のブロック（`sudo smbstatus`）は、`bash -n` だけ（このコンテナに Samba は無い）

**模擬**: Linux の pwsh で、`Test-NetConnection`・`Get-SmbMapping`・`New-SmbMapping`・`Remove-SmbMapping` を引数を表示して覚えておくだけの関数に、`cmdkey` を引数を表示する関数に置き換え、ブロックを上から順に同じセッションに流した。

- 管理者かどうかの式（`IsInRole`）は Linux では使えないので、真偽の変数に置き換えた
- `New-SmbMapping` の偽物は、一時ディレクトリを根にした `Z:` のドライブ（`New-PSDrive`）を作る
- 見直しの後にもう一度流し、下の結果は同じだった

結果:

- 変数が空のまま: Windows 11 で使うの手順 3〜5、Windows 11 の更新の手順 1、Windows 11 のロールバックの手順 2 は `中断:` で止まった
  - Windows 11 で使うの手順 6 と、Windows 11 のロールバックの手順 1 は、`DRIVE` に既定の `Z:` が入っているので流れた（前者は `Z:` が無いエラー、後者は偽物の `Remove-SmbMapping` を呼んだ）
- Windows 11 で使うの手順 3: 管理者の窓・`DRIVE` が `Z`（コロン無し）・445/tcp に届かない・覚えている割り当てがある（`Status` が `Unavailable`）の 4 つで、それぞれの `中断:` が出た。そろったときは `<SERVER> の 445/tcp に届く。Z: は空いている` が出て、`cmdkey` に `/list:<SERVER>` の 1 つの引数が渡った
- Windows 11 で使うの手順 4 と、Windows 11 の更新の手順 1: `cmdkey` に `/add:<SERVER>`・`/user:<SMB_USER>`・`/pass` の 3 つの引数が渡った
- Windows 11 で使うの手順 5: `New-SmbMapping` に `-LocalPath Z:`・`-RemotePath \\<SERVER>\<SHARE>`・`-Persistent True` が渡り、`Status`・`LocalPath`・`RemotePath` の表に `OK`・`Z:`・`\\<SERVER>\<SHARE>` の 1 行が出た。この後に同じ節の手順 3 を流すと、`Z: はもう使われている` で止まった
- Windows 11 で使うの手順 6: `smb write` と `False` が出て、共有に見立てたディレクトリにファイルは残らなかった
- Windows 11 のロールバックの手順 1・2: `Remove-SmbMapping` に `-LocalPath Z: -UpdateProfile -Force` が、`cmdkey` に `/delete:<SERVER>` と `/list:<SERVER>` が渡った。`HKCU:\Network\Z` の確かめは `False`（Linux にはレジストリが無いので、いつも `False`）

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. `cmdkey /pass` の問い方と日本語の表示。同じ宛先にもう一度 `/add` したときに置き換わること
1. 資格情報を渡さない `New-SmbMapping` が、資格情報マネージャーの資格情報でつなぐこと
1. エクスプローラーにドライブが出る時期（Microsoft のコミュニティには、Windows 11 で `New-SmbMapping` のドライブがエクスプローラーを起動し直すまで出ないという報告がある）と、サインインし直した後のつなぎ直し
1. サーバーに届かないときにサインインしたときの表示と、届くようになった後のつなぎ直し
1. `smbstatus` で、Pro の PC の割り当てが `SMB3_11` で全体に署名されること。Home の PC の `Signing` の表示
1. 使っていない SMB の接続を Windows が閉じるまでの時間（Windows 11 で使うの手順 7 で、この PC の行が無くなるか）
1. `Remove-SmbMapping -UpdateProfile` で `HKCU:\Network\<文字>` が消えること。外した後のエクスプローラーの表示
1. エラー 1219 の出方と、`[root]`・`[home]` を `[homes]` と並べて割り当てること
1. WireGuard 越しの割り当て

### 操作上の注意と併記されていた記録

   - ドメインとパスワードを聞かれる（英語では `Domain [SAMBA]:` と `Password:`、日本語の VM では日本語で表示された）


### 操作上の注意と併記されていた記録

  - 失敗した後は `systemctl --failed` に `mnt-<SHARE>.mount` が出て、`systemctl is-system-running` が `degraded` になる。サーバーに届くようになってからアクセスすれば、マウントされて元に戻った


### 操作上の注意と併記されていた記録

  - **マウントしている間に届かなくなると、ファイルを開くコマンドが約 3 分止まる**。そのあと `Resource temporarily unavailable` で失敗した（`soft` の既定。`dmesg` に `has not responded in 180 seconds. Reconnecting...`）


### 操作上の注意と併記されていた記録

  - サーバーを変えられないときは、マウントのオプションに `nohandlecache` を足すと、すぐに出た


### 操作上の注意と併記されていた記録

  - VM では、共有は 1 つだけマウントされていて、2 回目の `mount -a` は何も出さなかった


### 操作上の注意と併記されていた記録

  - VM では、ブラケットペーストで貼った回と、ブラケットペースト無しで貼った回の両方で通した


### 実施手順 / 手順 2: 補足: パッケージと、確かめていること

**パッケージ**:

- `cifs-utils`（BaseOS）がマウントの道具 `mount.cifs` を入れる。カーネルの側（`cifs.ko`）は `kernel-modules` に入っている
- VM（GNOME の無い最小の構成）では、依存を合わせて 7 パッケージ（ダウンロード 16 MB、導入後 57 MB）が入った: `cifs-utils-7.7-1.el10_2`、`samba-client-libs`・`samba-common`・`samba-common-libs`・`libwbclient`（いずれも `4.23.5-110.el10_2`）、`libicu`、`avahi-libs`
- `cifs-utils` は、Workstation では `workstation-product` グループの必須パッケージ、Server with GUI では `standard` グループの任意パッケージ（`dnf group info` で確認）
- `samba-client`（`smbclient`）は入れない。マウントには要らない

**確かめていること**:

- `modinfo -n` は、モジュールのファイルがあるかだけを見る。読み込むのは、手順 5 で最初にマウントするとき
- `/dev/tcp/<SERVER>/445` は bash の機能で、445/tcp に TCP でつなぐだけ（SMB のやり取りはしない）。つながると何も出さずに閉じる
- VM での失敗の表示:
  - smbd が止まっている（接続を断られる）: 0.2 秒で `bash: connect: Connection refused` と `bash: line 1: /dev/tcp/<SERVER>/445: Connection refused`
  - パケットが捨てられる（firewalld で閉じている、経路が無いなど）: 5 秒後に何も出さずに終わる（`timeout` の終了コード 124）



### 実施手順 / 手順 7: 補足: 自動マウントの様子

`findmnt -R` の出力（VM）:

```
TARGET          SOURCE              FSTYPE OPTIONS
<MOUNT_POINT>   systemd-1           autofs rw,relatime,fd=80,pgrp=1,timeout=60,minproto=5,maxproto=5,direct,pipe_ino=14812
└─<MOUNT_POINT> //<SERVER>/<SHARE>  cifs   rw,relatime,vers=3.1.1,cache=strict,…
```

VM で測ったこと:

- アクセスしてからマウントまで 0.5 秒ほど。再起動した直後の最初のアクセスは、`cifs.ko` の読み込みも入って 3 秒ほど
- 最後に使ってから約 60 秒で外れた（`journalctl -u mnt-<SHARE>.mount` の `Unmounting …`）
- 共有の中をカレントディレクトリにしたシェルがある間は外れず、そのシェルが抜けてから 1 分ほどで外れた
- 再起動した後は `mnt-<SHARE>.automount` が active で、`autofs` の行だけがある。アクセスすると `cifs` の行が増える
- サーバー側の `sudo smbstatus` では、`Protocol Version` が `SMB3_11`、`Signing` が `partial(AES-128-CMAC)`、`Encryption` が `-`（samba.md と同じ）
- `ausearch -ts recent` は直近の 10 分を見る。VM では、起動してからの AVC も無かった（`-ts boot`）



### GNOME Files で開く（任意） / 手順 2: 補足: 入るもの

- GNOME の無い VM では、gvfs 本体・udisks2・libsmbclient・wsdd など、依存を合わせて 42 パッケージ（ダウンロード 14 MB、導入後 53 MB）が入った
- gvfs を入れて gvfsd を動かしたまま gvfs-smb だけを消して入れ直しても、同じ gvfsd（PID が変わらない）で `/usr/bin/gio mount` が通った



### ロールバック / 手順 4: 補足: 消えるもの

- VM では、GNOME Files の節の前なら、手順 2 で入った 7 パッケージ（57 MB）が消える表だった（`dnf remove --assumeno` で確認）
- GNOME Files の節の後では、cifs-utils だけが消えた。依存は、その節で入った libsmbclient が使っている
- 手順 2 で入れていない PC で消すと、`mount.cifs` が無くなり、ほかの CIFS のマウントもできなくなる



### ロールバック / 手順 5: 補足: 消えるもの

- VM では、使われなくなった依存を合わせて 21 パッケージ（72 MB）が消えた

## 参考資料から分離した記録

### 参考資料: GNOME Files で開く（任意） / 手順 1: 補足: パッケージ

- `gvfs-smb` が gvfs の SMB のバックエンド（libsmbclient を使う）、`gvfs-fuse` が GIO を使わないアプリ向けの `/run/user/<UID>/gvfs/`
- どちらも GNOME のグループ（`gnome-desktop`）の必須パッケージなので、Workstation にも Server with GUI にも入っている（`dnf group info` で確認）

### 参考資料: ロールバック / 手順 1: 補足: 2 つのユニットを止める理由

- `.automount` と `.mount` を一緒に止めると、`cifs` と `autofs` の両方が外れる（VM で確認）
- `.mount` だけを止めると、`Stopping 'mnt-<SHARE>.mount', but its triggering units are still active: mnt-<SHARE>.automount` と出て、次のアクセスでまたマウントされる
- `MOUNT_POINT` が空のまま `$(systemd-escape …)` を使うと、ユニットの名前が `-.mount`（ルートのファイルシステム）になる。先頭の `if` はこれを防ぐ

### 参考資料: ロールバック / 手順 2: 補足: 行の消し方

- 行は awk で、2 列目（マウント先）と 3 列目（`cifs`）を文字列として比べて消す。sed の正規表現だと、IP アドレスのドットなどが特別な意味を持つ
- `tee` で書き戻すので、`/etc/fstab` のモード（0644）とラベル（`etc_t`）は変わらない（VM で確認）
- VM では、`mnt-<SHARE>.*` のユニットと `/run/systemd/generator/` の中のものも、`daemon-reload` で消えた

### 参考資料: 選択した方針

- **`x-systemd.automount` で、アクセスしたときにマウントする**
  - 起動時にはマウントしないので、サーバーが止まっていても起動は待たない（VM で、smbd を止めたまま再起動しても `running` で終わった）
  - `x-systemd.idle-timeout=1min` で、使わなくなった共有は約 1 分で外れる。PC を LAN の外へ持ち出したときに、届かないマウントが残りにくい
  - systemd のユニット（`.mount` / `.automount`）を自分で書く方法もあるが、fstab の 1 行から `systemd-fstab-generator` が同じ 2 つを作るので、fstab にした
- **資格情報は `/root/smb-<SMB_USER>@<SERVER>.cred`（root の 0600）に置く**
  - RHEL 10 の文書（`/root/smb.cred`）と同じ場所。名前にユーザーとサーバーを入れて、複数の共有を並べられるようにした
  - マウントするのは root（systemd か `sudo mount`）なので、root が読めればよい。自分のホームには置かない
  - fstab に `password=` を書かない。fstab は誰でも読める（0644）
  - SELinux: systemd から呼ばれた mount.cifs は `mount_t` で動く。EL10 のポリシーでは `mount_t` が制限の無いドメイン（`unconfined_domain_type`）なので、置き場所のファイルの型を選ばない
  - VM では、dontaudit の規則を外して（`semodule -DB`）自動マウントと手でのマウントをしても、AVC は出なかった
- **マウントのオプションは `credentials=`・`uid=`・`gid=`・`file_mode=0600`・`dir_mode=0700` だけにした**
  - `uid=` / `gid=`: 無いと、マウントした側のファイルが root の所有に見える（[samba.md のサーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の手順 4 の補足）
  - `file_mode=0600` / `dir_mode=0700`: 既定の 0755 のままだと、この PC のほかのユーザーからも読める。VM では、ほかのユーザーは `Permission denied`、root は読めた
  - このモードはこの PC での見え方だけで、サーバー側のファイルのモードはサーバーの `create mask`（0644）で決まる（VM で確認）
  - `vers=` は書かない。既定でサーバーの最も新しい版を使い、samba.md のサーバーとは SMB 3.1.1 になった
- **`_netdev` と `nofail` は付けない**
  - `_netdev`: systemd は cifs をネットワークのファイルシステムとして扱い、生成した `.mount` に `After=network-online.target` などを付ける（VM で確認）。mount.cifs も `_netdev` を無視する（cifs-utils 7.7 のソース）
  - `nofail`: 起動時に要るのは `.automount` だけで、これはサーバーに依存しない。`nofail` が無いので `remote-fs.target` が `.automount` を Requires にするが、サーバーを止めて再起動しても起動は止まらなかった
  - mount.cifs は `nofail` があると、サーバーに届かないときも終了コード 0 で終わる（cifs-utils 7.7 のソース）。手でマウントしたときの失敗が分かりにくくなる
- **クライアントの firewalld は変えない**
  - 出ていく 445/tcp だけなので、開けるものは無い（VM で、firewalld が active のまま接続できた）
  - firewalld の `samba-client` サービス（137/138/udp。NetBIOS の名前引きと一覧）は要らない。samba.md のサーバーは NetBIOS を使わない
- **暗号化（`seal`）は使わない**: LAN 上の通信は署名だけ（`smbstatus` の `Signing` が `partial(AES-128-CMAC)`、`Encryption` が `-`）。samba.md の方針と同じ
- **GNOME Files（gvfs）は任意節にした**
  - fstab のマウントとは別の仕組みで、ログインしたユーザーの gvfsd が libsmbclient でつなぐ。root も資格情報ファイルも要らない
  - つながるのはログインしている間だけ。GIO を使わないアプリからは `/run/user/<UID>/gvfs/` の下に見える

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 実施手順 / 手順 7

   - 再起動した後も、アクセスしたときにマウントされる（VM で確認）

### GNOME Files で開く（任意） / 手順 3

   - 画面では、認証の画面で「期限なしで記憶する」を選ぶと、パスワードが GNOME のキーリングに保存される（未確認）

### 補足

- **外出先から WireGuard 越しに使うとき**: トンネルを張ってからアクセスする（本書では未検証）
