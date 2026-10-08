# Samba でホームディレクトリを公開する手順（`[homes]` 共有 / smbd + firewalld）の検証記録

[手順書](../samba.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 操作上の注意と併記されていた記録

- **smb.conf に `smb3 directory leases` の行が無いサーバーだけ**（2026-10-01 より前の手順 3 で置いたもの）。今の手順 3 には、この 1 行が入っている

### 実施手順 / 手順 3: 補足: smb.conf

- `cp -an` の `-n` で、2 回目以降の実行で `.orig` を上書きしない（最小構成で上書きした `smb.conf` を原本として退避してしまうのを防ぐ）
- heredoc は `${WORKGROUP}` を展開するため引用符なしの `<<EOF`。内容にほかの `$` は無い
- 字下げは空白にしてある。TAB だと、ブラケットペーストが効かない端末で貼ったときに bash が補完として扱い、行頭が `.` に置き換わった（VM で確認）
- そのときの testparm は、`Unknown parameter` と出しつつ `Loaded services file OK.` で終わった（壊れたことに気付きにくい）
- `testparm -s` の出力に `Weak crypto is allowed by GnuTLS (e.g. NTLM as a compatibility fallback)` が出るが、crypto-policies が DEFAULT のときの通常の表示で、エラーではない
- `testparm -s` は**既定と異なる値だけ**を表示する。`workgroup = WORKGROUP` の行が出なくても書き漏れではない。`read only = No` は組み込み既定の `Yes` と異なるので表示される。全パラメータを見るなら `testparm -sv`
- `smb3 directory leases = no` は、クライアントにディレクトリのリース（一覧を手元にキャッシュしてよいという許可）を渡さない。Samba 4.22 からの既定（`auto`）では渡す
- Samba は、自分を通さずにサーバーで変えたもの（サーバーのシェルや Syncthing など）では、このリースを破らない。既定のままだと、Windows のエクスプローラーは F5 を押しても古い一覧を出し続けた（[付録](#付録-サーバーで変えたものがクライアントに見えるまで2026-10-01)）
- 手順 9 の後で `smb.conf` を直したときは `sudo systemctl restart smb.service`（unit には `ExecReload`（`SIGHUP`）もあるが、本手順の検証では restart しか使っていない）

### 実施手順 / 手順 4: 補足: SELinux

- boolean が off のままだと、認証は通り共有一覧にも出るのに、`ls` で `NT_STATUS_ACCESS_DENIED listing \*` になる
- **このとき `ausearch -m AVC` には何も出ない**（dontaudit されている）ので、監査ログから原因にたどり着けない。[付録](#selinux-boolean-が-off-のときの失敗の署名)
- `setsebool -P` は即時反映で、smbd の再起動は不要（実測: 起動中の smbd に対して on にした直後の `ls` が通った）

### 実施手順 / 手順 6: 補足: Samba ユーザー

- Samba のパスワードは OS のパスワードとは別で、`/var/lib/samba/private/passdb.tdb` に保存される。OS のアカウントは存在が必須（`id` で確認）
- `smbpasswd -a` は既定で `/dev/tty` から読む。**TTY が無いと `Unable to get new password.` で終了コード 1**（`grdctl set-credentials` のように exit 0 で黙って何もしない、ということはない）
- パイプで渡すなら `-s`（stdin から新パスワード・確認の 2 行を読む）。[付録](#smbpasswd-を-tty-無しで実行したとき)
- `-a` で作った直後から有効（`pdbedit -Lv` の `Account Flags: [U ]`）。`smbpasswd -e` は要らない
- **smbd の再起動は不要**。起動中に `smbpasswd -x` → `-a` し直すと、その次の接続から効く（実測）。パスワード変更も同様

### 実施手順 / 手順 9: 補足: クライアントからの接続

- Windows のエクスプローラーからは、利用者の PC で実機の共有を開いて使えている。2026-10-01 に、サーバーで変えたものの見え方を確かめた（[付録](#付録-サーバーで変えたものがクライアントに見えるまで2026-10-01)）。資格情報を入れる最初の接続の画面は記録していない
- macOS / iOS / Android からの接続は未検証。IP アドレスで指定する（NetBIOS 名では見つからない）
- [samba-client.md](../samba-client.md) は、AlmaLinux 10 の VM 同士で LAN と WireGuard 越しの手動 CIFS マウントを確かめた。LAN の fstab 自動マウントも VM で確認済み。この実機のサーバーへの接続は確かめていない

### root のホームも公開する（任意）: 検証状況の記録

> [!WARNING]
> - `<USER>` の Samba のパスワードが、root のパスワードと同じ重みになる。`/root/.bashrc` や `/root/.ssh/authorized_keys` も書き換えられるので、root で任意のコマンドを動かせる。パスワードは長いものにし、[接続元を絞る](../samba.md#接続元を絞る任意)も検討する
> - この節は **x86_64 の VM でのみ検証した**。実機では本実行していない（[付録](#付録-root-のホームを公開する節の-vm-での検証2026-09-29)）

### /home も公開する（任意）: 検証状況の記録

> [!WARNING]
> - `<USER>` の Samba のパスワードで、ほかのユーザーのホームのファイル（`~/.bashrc` や `~/.ssh/authorized_keys`）も読み書きできる。`sudo` を使えるユーザーのホームを書き換えれば、root で任意のコマンドを動かせる。パスワードは長いものにし、[接続元を絞る](../samba.md#接続元を絞る任意)も検討する
> - この節は **x86_64 の VM でのみ検証した**。実機では本実行していない（[付録](#付録-home-を公開する節の-vm-での検証2026-10-05)）

### /home も公開する（任意） / 手順 1: 補足: [home] の各行

- `path = /home`: 共有の場所を書く普通の共有。ユーザーごとの共有を出す `[homes]` とは別のもの（`grep` の `^\[home\]` も `[homes]` の行には当たらない）
- `valid users = ${USER}`: 入れるのは `<USER>` だけ。ほかの Samba ユーザーは、認証が通っても `tree connect failed: NT_STATUS_ACCESS_DENIED`（VM で確認）
- `force user = root`: ほかのユーザーのホームは `drwx------`（0700）なので、`<USER>` のままでは開けない。root として扱うので開ける（`[root]` と同じく、smbd の SELinux のドメイン `smbd_t` は `dac_override` を持つ）
- `inherit owner = yes`: 新しく作ったファイルとディレクトリの所有者を、親ディレクトリの所有者に変える。`testparm` は `windows and unix` と表示する
  - 無いと、作ったものは `root root` の所有になり、持ち主のユーザーがサーバーで書き換えられない
  - 一時ファイルに書いてから元の名前に付け替えて保存するアプリでは、もとからあるファイルも `root root` に変わる（VM の `smbclient` の `rename -f` で確かめた。`inherit owner` があれば持ち主のまま）
  - 変わるのは所有者だけで、グループは `root` のまま。VM では `inherit owner = unix only` でも同じだった
- `browseable = No`: 共有の一覧（`smbclient -L`）に出さない。つなぐときは共有名 `home` を直接指定する
- `create mask = 0644`: `[homes]` と同じ理由（[smb.conf の各行の根拠](../reference/samba.md#smbconf-の各行の根拠)）。ディレクトリは既定の `directory mask`（0755）になる
- ヒアドキュメントは `${USER}` を展開するので、引用符なしの `<<EOF`。先頭の空行は、前の節との区切り

### /home も公開する（任意） / 手順 4: 補足: 元に戻す

- `sed` は、`[home]` の行から次の `[` で始まる行の手前までを消す。`[home]` の前や後ろの節（`[root]` など）は残る
  - VM では、`[root]` の後ろに足した `[home]` を消し、`[root]` が残った
  - `[home]` の後ろに節がある形は、`[home]` の後ろに `[root]` を置いた smb.conf の模型で、`sed` だけを確かめた
- この節の手順 1 で足した先頭の空行は残る（`testparm` は気にしない）
- 共有で作ったファイルとディレクトリは、消さずに残る（所有者もそのまま）
- 戻した後の `//<SERVER_IP>/home` は、`tree connect failed: NT_STATUS_BAD_NETWORK_NAME`（VM で確認）

### 設定済みのサーバーでディレクトリのリースを切る / 手順 1: 補足: 足し方

- `sed` は、`[global]` の行のすぐ下に足す。`[global]` の中なら、どこに書いても同じ
- 実機の smb.conf は、2026-09-28 より前の手順 3 で置いたもので、字下げが TAB だった。足した行は空白の字下げになるが、`testparm` は気にしない
- 実機では、`sed -i` の後もモードは `-rw-r--r--`、ラベルは `samba_etc_t` のままだった
- 2 回目に貼ると、`中断: /etc/samba/smb.conf に smb3 directory leases の行が既にある` で止まる（コンテナで確認）

### 対象と検証環境

- **目的**: ローカルユーザーが**自分のホームディレクトリ**に、LAN と WireGuard 越し（`wg0`）の両方から SMB3 で読み書きできるようにする
  - 共有は Samba の `[homes]` 機構（ユーザー名と同じ名前の共有が自動で現れ、本人しか入れない）を使う
  - 任意で、root のホーム（`/root`）も `[root]` 共有で公開できる。入るのは自分の Samba ユーザーのままで、smbd は root として読み書きする（[root のホームも公開する（任意）](../samba.md#root-のホームも公開する任意)）
  - 任意で、`/home` 全体（ほかのユーザーのホームも）を `[home]` 共有で公開できる。入るのは自分の Samba ユーザーのままで、smbd は root として読み書きし、作ったものは親ディレクトリの所有者のものにする（[/home も公開する（任意）](../samba.md#home-も公開する任意)）
  - 印刷・NetBIOS・ゲストアクセスは持たない
- **進め方**: **冒頭の変数ブロックに値を 1 度書き、以降のコマンドをそのまま貼る**
  - 読者が編集するのは `WORKGROUP` と、接続元を絞る場合の `ALLOW_FROM` だけ
  - `smb.conf` は既定ファイルを退避したうえで、最小構成に置き換える
- **状態**: **2026-09-21 に下表の実機で本実行し、公開を継続中。2026-10-06 にクリーンインストールした x86_64 の VM でも現行ブロックを本実行した**
  - 2026-10-06: 先行検証とは別の新規 VM で現行本文を再検証した（[今回の記録](#付録-新規-vm-での現行手順の再検証2026-10-06)）。検証専用のアカウント・鍵・隔離 LAN を使った
  - 確認したこと: **サーバー自身からの `smbclient` と `mount.cifs` による読み書き**、および **network namespace から firewalld 越しに 445/tcp へ到達できること**（[付録](#付録-実機での検証記録2026-09-21)）
  - **確認していないこと**: macOS / iOS / Android の実クライアントからの接続（Windows のエクスプローラーは、2026-10-01 に確かめた）
  - 2026-09-28: 手順 2〜5・8、[サーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の手順 4、[ロールバック](../samba.md#ロールバック)の手順 1 のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../../README.md#記法)）。中のコマンドは変えていない
    - 手順 3 の smb.conf の字下げを、TAB から空白に変えた。TAB は、ブラケットペースト無しで貼ると bash の補完で `.` に置き換わった（手順 3 の補足）
    - 直した後の手順 1〜8、動作を確かめる節の手順 1〜6、ロールバックを、x86_64 の VM にブラケットペースト無しで貼って通した。VM は [samba-client.md の付録](samba-client.md#付録-vm-での検証記録2026-09-27)と同じもので、まっさらな状態から始めた
    - その VM には `samba-common` が入っていなかったので、手順 2 で一緒に入り、ロールバックの手順 3 で一緒に消えた
  - 2026-09-29: [root のホームも公開する（任意）](../samba.md#root-のホームも公開する任意)と、[ロールバック](../samba.md#ロールバック)の手順 2 を足した
    - **この 2 つは x86_64 の VM でのみ検証した**。実機では本実行していない
    - まっさらな VM で手順 1〜8 と[サーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の手順 1〜6 を通した後、root の節の手順 1〜3・5、動作を確かめる節の手順 7・8、ロールバックを、ブラケットペーストの有りと無しで 1 回ずつ貼って通した（[付録](#付録-root-のホームを公開する節の-vm-での検証2026-09-29)）
    - 確認したこと: `/root` の一覧・読み書き・改名・削除で AVC が出ないこと、作ったファイルが `root root` の `admin_home_t` になること、2 人目の Samba ユーザーが入れないこと、samba-client.md の手でのマウント（`SHARE=root`）、モジュールが無いときの失敗の表示
    - 確認していないこと: 実機、Windows などのクライアントからの接続（エラー 1219 を避けられることも）、WireGuard 越しの接続
  - 2026-10-01: 手順 3 の smb.conf に `smb3 directory leases = no` を足し、[設定済みのサーバーでディレクトリのリースを切る](../samba.md#設定済みのサーバーでディレクトリのリースを切る)を足した
    - 足す前は、サーバーで直接作ったファイルが、利用者の Windows のエクスプローラーに F5 でも出なかった（[付録](#付録-サーバーで変えたものがクライアントに見えるまで2026-10-01)）
    - 実機では、その節の手順 1・2 を本実行した。その後は、サーバーで作ったもの・消したもの・サブフォルダーの中に作ったものが、エクスプローラーに自動で出た（利用者が確かめた）
    - 手順 3 のブロック（2026-10-02 に `if` を足す前の形）と、その節の手順 1〜3 は、実機の上の rootless の podman のコンテナ（aarch64）で貼って通した。コンテナには systemd が無いので、`systemctl` はスタブにした
    - 確認していないこと: 手順 1〜8 と[サーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の手順 1〜6 の通し、リースを切る節の手順 3 を実機で貼ること、macOS・iOS・Android のクライアント、WireGuard 越しの接続
    - 実機の smb.conf は、2026-09-28 より前の手順 3（字下げが TAB）に `[root]` を足したもの。`[root]` は `browseable = Yes` で、この文書と違う（今回は変えていない）
  - 2026-10-02: サーバーの上の動作確認を、`## 実施手順` から[サーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)へ移した（利用者の依頼）
    - その節の手順 1〜6 は、もとの手順 9〜14。もとの手順 15（クライアントからの接続）は手順 9 になった
    - その節の手順 7・8 は、もとの root の節の手順 3 の `smbclient` と手順 4。root の節の手順 3 は smb.service の再起動だけになり、もとの手順 5・6 は手順 4・5 になった
    - コマンドは変えていない（root の節の手順 3 の `{ … }` を外し、再起動と `smbclient` を別の手順に分けただけ）。移した後の文書は貼って通していない
  - 2026-10-02: 手順 3 の `{ … }` を、`WORKGROUP` が空なら何もせずに止める `if … fi` にした（中のコマンドは変えていない）
    - それまでは、ヒアドキュメントの中の `${WORKGROUP:?…}` が `sudo tee` しか止めず（[gnome-power.md 手順 3 の補足](almalinux-setup.md#画面オフロックサスペンド-実施手順--手順-3-補足-ログイン画面の設定の置き場所とgdm-ユーザーで読む理由)）、`cp -an` は動き、smb.conf は書き換わらずに、`testparm -s` が元の smb.conf を検査した
    - 直した形は、擬似端末の対話の bash にブラケットペースト無しで、変数を空にしたときと値を入れたときの 1 回ずつ貼って確かめた（`sudo` はそのまま実行するスタブ、`testparm` はスタブ、`/etc` は使い捨てのディレクトリに読み替えた）
  - 2026-10-05: [/home も公開する（任意）](../samba.md#home-も公開する任意)と、[サーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の手順 9・10 を足した（利用者の依頼）
    - **この 2 つは x86_64 の VM でのみ検証した**。実機では本実行していない
    - まっさらな VM で、手順 1〜8、動作を確かめる節の手順 1〜6、root の節の手順 1〜3、/home の節の手順 1・2、動作を確かめる節の手順 7〜10、/home の節の手順 4、ロールバックを、ブラケットペーストの有りと無しで 1 回ずつ貼って通した（[付録](#付録-home-を公開する節の-vm-での検証2026-10-05)）
    - 確認したこと: `/home` の一覧、自分とほかのユーザーのホームへの書き込みで所有者がそのユーザーになること（改名での上書きも）、`/home` の直下には作れないこと、2 人目の Samba ユーザーが入れないこと、`[root]` と並べて足して `[home]` だけを戻せること、samba-client.md の手でのマウント（`SHARE=home`）
    - 確認していないこと: 実機、Windows などのクライアントからの接続、WireGuard 越しの接続、samba-client.md の自動マウント（`SHARE=home`）

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-21 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi） |
| カーネル | 6.12.96 |
| `samba` / `samba-client` / `samba-common` | 4.23.5-110.el10_2（baseos / appstream） |
| `cifs-utils` | 7.7-1.el10_2（検証のマウントにだけ使う） |
| firewalld | 2.4.3 |
| SELinux | Enforcing |
| NIC | `end0` = <SERVER_IP>/24、`wg0` = <WG_IP>/30（ともに public ゾーン） |
| クライアント | 検証は Linux の `smbclient` 4.23.5 と `mount.cifs`（SMB 3.1.1）。2026-10-01 に、利用者の Windows のエクスプローラー（SMB 3.1.1）。macOS / iOS / Android は未確認 |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../samba.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${WORKGROUP}` | `smb.conf` の `workgroup`。Windows 側のワークグループ名に合わせる（NetBIOS を使わないので実質ラベル） | `WORKGROUP` |
> | `${ALLOW_FROM}` | 送信元サブネットのリスト（空白区切り）。[接続元を絞る](../samba.md#接続元を絞る任意)場合だけ、その節の冒頭で設定する | `192.168.1.0/24 10.99.0.0/30` |
> | `${SERVER_IP}` | クライアントが接続に使うサーバーの LAN 側 IP（デフォルト経路の送信元から自動で入る）。検証と案内にしか使わない | `192.168.1.10` |
>
> 出力例・ログ・表の中の値は `<HOSTNAME>` / `<SERVER_IP>` / `<WG_IP>`（`wg0` のアドレス）/ `<USER>`（OS アカウント名）/ `<CLIENT_IP>`（Windows の PC の IP）のプレースホルダで書いてある。
>
> Samba のパスワード（`smbpasswd` で登録する、OS とは別のパスワード）はこの文書に載せない。検証で使ったものは `openssl rand` で作った使い捨てで、記録していない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| `samba-common` | 4.23.5-110.el10_2 がインストール済み（`/etc/samba/smb.conf` は既定のまま、`smb.conf.example` あり） |
| `samba` / `samba-client` / `cifs-utils` | 未インストール |
| `smb.service` / `nmb.service` | 未インストール（`samba` を入れると `disabled` / `inactive` で入る） |
| 139 / 445 の LISTEN | 無し |
| SELinux | Enforcing。`samba_enable_home_dirs` / `samba_export_all_ro` / `samba_export_all_rw` / `use_samba_home_dirs` すべて off |
| ホームディレクトリ | `/home/<USER>` は `drwx------`、コンテキスト `unconfined_u:object_r:user_home_dir_t:s0`、ACL 無し |
| firewalld | active、default zone = `public`、`end0` と `wg0` が所属。ports: `22/tcp 51820/udp 8384/tcp`、services: `cockpit dhcpv6-client rdp ssh`、445 未開放 |
| `cups` / `acl` / `setools-console` | 未インストール |
| `wsdd` | 0.8-3.el10（EPEL）がインストール済みだが `disabled` / `inactive`。本手順では使わない |
| ローカルユーザー | `<USER>`（uid 1000）のみ |

既定の `smb.conf`（`samba-common` 由来）の内容:

```
[global]
	workgroup = SAMBA
	security = user
	passdb backend = tdbsam
	printing = cups
	printcap name = cups
	load printers = yes
	cups options = raw
	include = /etc/samba/usershares.conf
[homes]
	comment = Home Directories
	valid users = %S, %D%w%S
	browseable = No
	read only = No
	inherit acls = Yes
[printers]
	comment = All Printers
	path = /var/tmp
	printable = Yes
	create mask = 0600
	browseable = No
[print$]
	comment = Printer Drivers
	path = /var/lib/samba/drivers
	write list = printadmin root
	force group = printadmin
	create mask = 0664
	directory mask = 0775
```

### 選択した方針

- **`[homes]` 共有だけを公開する**
  - ユーザー名と同じ名前の共有が自動で現れ、`valid users = %S`（`%S` = 共有名）で本人以外は入れない
  - 共有ごとに `path` を書かないので、ユーザーを増やしても `smb.conf` は変わらない
- **既定の `smb.conf` は丸ごと置き換える**
  - `smb.conf` には drop-in ディレクトリが無く、印刷まわりを止めるには本体を編集するしかない
  - 差分方式は成立しないので、原本を `.orig` に退避して最小構成にした
  - `smb.conf` は `%config(noreplace)` なので、パッケージ更新で上書きされず、新しい既定は `smb.conf.rpmnew` に置かれる
- **NetBIOS（`nmb.service`、139/tcp、137/138/udp）は使わない**
  - SMB2 以降のクライアントは 445/tcp に直接つなぎ、IP アドレスか DNS 名で指定する
  - `server smb transports = tcp` で 139 を listen しなくなり、firewalld も 445/tcp だけで済む
  - RHEL のドキュメントは `--add-service=samba`（139/tcp + 445/tcp + `samba-client` の 137/138/udp）を開けるが、nmbd を動かさないなら 137〜139 は誰も受けない
- **ディレクトリのリース（SMB3 Directory Leases）は切る（`smb3 directory leases = no`）**
  - 公開するのはホームなので、サーバーにログインしたシェルや、同じホストの Syncthing もファイルを変える
  - Samba 4.22 からの既定（`auto`。クラスタでなければ有効）では、クライアントに一覧のキャッシュを許すリースを渡す。Samba を通さない変更では、そのリースを破らない
  - 実機では、リースを持った Windows が、サーバーで作ったファイルを F5 でもウィンドウを開き直しても出さなかった（[付録](#付録-サーバーで変えたものがクライアントに見えるまで2026-10-01)）
  - 代償は、クライアントが一覧を見るたびにサーバーへ聞きに来ること（WireGuard 越しでは往復の分だけ待つ。測っていない）
  - 振る舞いは Samba 4.21 以前と同じになる。リースが暗に有効にしていた `strict rename` も、既定の `no` に戻る
  - クライアントごとの設定（Linux の `nohandlecache` など）は、つなぐ端末ごとに要るので採らない
- **SELinux boolean は `samba_enable_home_dirs` の 1 つだけ** — smbd に `user_home_dir_t` / `user_home_t` のアクセスを許す boolean
  - ホームディレクトリのラベルは変えないので、`restorecon` は不要
  - `samba_export_all_rw` は全ファイルへの書き込みを許す粗い boolean なので使わない
  - `use_samba_home_dirs` は「ホームが CIFS マウントされているクライアント側」のための boolean で、サーバーには関係ない
- **root のホームは `[root]` 共有（`force user = root`）で公開し、root の Samba ユーザーは作らない**
  - `sudo smbpasswd -a root` だけでも、`[homes]` が `root` という共有を出す。ただし SELinux のモジュールが無いと、`ls` は `NT_STATUS_ACCESS_DENIED listing \*` で通らない（VM で確認）
  - root を登録しないのは、誰でも知っているユーザー名 root に、パスワードで入れる口を作らないため
  - Windows は、同じサーバーに別のユーザー名で同時につなげない（エラー 1219）。root で入る形にすると、`<USER>` の共有と root の共有を並べて開けない
  - `[root]` なら `<USER>` の資格情報のまま入れ、クライアントの資格情報ファイルも 1 つで済む
- **root のホームの SELinux は、`admin_home_t` だけを smbd に許す CIL のモジュールにする**
  - 手順 4 の `samba_enable_home_dirs` は、一般ユーザーのホームのラベル（`user_home_type`）だけが対象で、`/root`（`admin_home_t`）に効かない
  - `samba_export_all_rw` は全ファイルへの書き込みを許すので使わない（上の boolean と同じ方針）
  - `/root` の中身をまとめて `samba_share_t` に貼り替える方法も採らない。sshd などがラベルで読むファイル（`/root/.ssh` の `ssh_home_t` など）まで変わるため
  - CIL は `semodule -i` がそのまま読むので、`checkpolicy` などの道具を足さずに済む
- **`/home` は `[home]` 共有（`force user = root`・`inherit owner = yes`）で公開する**
  - ほかのユーザーのホームは `drwx------` なので、`force user` を付けずに `<USER>` のまま入ると、開けるのは自分のホームだけで、`[homes]` と変わらない
  - root の Samba ユーザーを作らないのは、`[root]` と同じ理由
  - `inherit owner` が無いと、作ったものが `root root` の所有になる。一時ファイルに書いてから元の名前に付け替えて保存するアプリでは、もとからあるファイルも `root root` に変わる（VM で確認）
  - `inherit owner` の値は `yes`（`windows and unix`）にした。VM では `unix only` でも結果は同じだった。man page は、`unix only` を `acl_xattr` のように NT ACL を別に持つ仕組みと組み合わせて使うものとしている
- **`[home]` の SELinux は、手順 4 の boolean のほかに足さない**
  - `smbd_t` は、`/home`（`home_root_t`）のディレクトリを読むことが、boolean と関係なく許されている（VM の `sesearch`）。ユーザーのホーム（`user_home_dir_t`）とその中（`user_home_type`）は、手順 4 の boolean で許される
  - `/home` の直下にファイルやディレクトリを作ることは許されていないが、許さないままにする。`/home` はホームを置く場所で、作れるようにするにはモジュールを足すことになるため
- **接続元の制限は `smb.conf` の `hosts allow` ではなく firewalld で行う**
  - GNOME Remote Desktop の手順書と同じ方式にし、変数の扱いと二重引用符の落とし穴を共通にした
  - `hosts allow` で二重に絞ることもできるが、設定場所が 2 つになるのでやらない
- **SMB の暗号化は既定（`server smb encrypt = default`）のまま**
  - LAN 上の通信は署名（AES-128-CMAC）だけで、暗号化されない。WireGuard 越しはトンネルが暗号化する
  - LAN 上でも暗号化したいなら、`server smb encrypt = required` を `[global]` に足す（未検証）
- **Windows のエクスプローラー「ネットワーク」への一覧表示（WS-Discovery）は範囲外**
  - 本手順は `\\<SERVER_IP>\<USER>` を直接指定して接続する前提
  - 必要なら EPEL の `wsdd`（本機に導入済みだが無効）を起動し、5357/tcp と 3702/udp を開ける

| 行 | 書く / 書かない | 根拠 |
|---|---|---|
| `workgroup = ${WORKGROUP}` | 書く | 既定値は `WORKGROUP`（Windows の既定と同じ）。既定値と同じときは `testparm -s` の出力に**出ない**（`testparm -s` は既定と異なる値だけを表示する） |
| `security = user` / `passdb backend = tdbsam` | 書く（既定と同じ） | 「認証はローカルの tdbsam」を明示するため。`testparm -s` の `Server role: ROLE_STANDALONE` で確認できる |
| `server smb transports = tcp` | 書く | 445/tcp だけを listen する。4.23 の正式名で、`smb ports` はその同義語（`man smb.conf`） |
| `load printers = no` / `printing = bsd` / `printcap name = /dev/null` / `disable spoolss = yes` | 書く | `cups` が無い環境で smbd が CUPS へ接続しに行くのと、spoolss RPC を止める定型 |
| `smb3 directory leases = no` | 書く | 既定は `auto`（クラスタでなければ有効）。有効のままだと、Samba を通さずにサーバーで変えたものが、Windows のエクスプローラーでは F5 でも出ず、Linux の cifs では 30〜60 秒遅れる（[付録](#付録-サーバーで変えたものがクライアントに見えるまで2026-10-01)） |
| `include = /etc/samba/usershares.conf` | 書かない | `samba-usershares` を入れていないので対象ファイルが無い。既定 `smb.conf` のままでも `testparm` は**警告を出さない**（実測）。無いファイルの `include` は黙って無視される |
| `[homes] valid users = %S` | 書く | 既定の `%S, %D%w%S` のうち `%D%w%S`（ワークグループ名 + 区切り + 共有名）はドメイン参加時に `DOMAIN\user` 形式を通すためのもの。standalone では `%S` だけでよい |
| `browseable = No` | 書く（配布済み `smb.conf` の `[homes]` と同じ。組み込み既定は `Yes`） | `homes` という名前の共有を一覧から隠す。ユーザー名の共有は一覧に出る（実測: `smbclient -L` に `<USER>` は出て `homes` は出ない） |
| `read only = No` | 書く | 書き込み可 |
| `create mask = 0644` | 書く | 無いと SMB 経由で作ったファイルが `-rwxr--r--` になる（実測。[付録](#create-mask-無しで作ったファイルに-x-ビットが付く)） |
| `inherit acls = Yes` | 書かない | 親ディレクトリに default ACL があるときだけ意味を持つ。ホームディレクトリに ACL は無い |
| `server min protocol` | 書かない | 既定 `SMB2_02`。SMB1 は既定で無効（`smbclient -L` の末尾に `SMB1 disabled -- no workgroup available` と出るのはそのため） |
| `map to guest` | 書かない | 既定 `Never`。`[homes]` にゲストを許すと全ホームが無認証で見える |
| `hosts allow` | 書かない | 上記のとおり firewalld で絞る |
| `log file` / `log level` | 書かない | EL のビルド既定（`/var/log/samba/log.smbd` ほか）に任せる |

### 完了時点の状態

```
$ testparm -s
Load smb config files from /etc/samba/smb.conf
Loaded services file OK.
Weak crypto is allowed by GnuTLS (e.g. NTLM as a compatibility fallback)

Server role: ROLE_STANDALONE

# Global parameters
[global]
	disable spoolss = Yes
	load printers = No
	printcap name = /dev/null
	security = USER
	server smb transports = tcp
	idmap config * : backend = tdb
	printing = bsd


[homes]
	browseable = No
	comment = Home Directories
	create mask = 0644
	read only = No
	valid users = %S
```

上の `testparm -s` は 2026-09-21 の実機の出力。2026-10-01 からは、`[global]` の `server smb transports = tcp` の次に `smb3 directory leases = No` が出る（手順 3）。

```
$ systemctl is-enabled smb nmb; systemctl is-active smb nmb
enabled
disabled
active
inactive
$ ss -ltnp | grep -E ':(139|445) '
LISTEN 0      50           0.0.0.0:445       0.0.0.0:*
LISTEN 0      50              [::]:445          [::]:*
$ sudo firewall-cmd --list-all
public (default, active)
  target: default
  ...
  interfaces: end0 wg0
  services: cockpit dhcpv6-client rdp ssh
  ports: 22/tcp 51820/udp 8384/tcp 445/tcp
  ...
$ sudo getsebool samba_enable_home_dirs
samba_enable_home_dirs --> on
$ sudo pdbedit -L
<USER>:1000:
$ smbclient -L //localhost -A "${AUTHFILE}"

	Sharename       Type      Comment
	---------       ----      -------
	IPC$            IPC       IPC Service (Samba 4.23.5)
	<USER>          Disk      Home Directories
SMB1 disabled -- no workgroup available
$ sudo ausearch -m AVC -ts today
<no matches>
```

`smbstatus`（`mount.cifs` でマウント中に実行）:

```
Samba version 4.23.5
PID     Username     Group        Machine                                   Protocol Version  Encryption           Signing
----------------------------------------------------------------------------------------------------------------------------------------
77781   <USER>       <USER>       127.0.0.1 (ipv4:127.0.0.1:47626)          SMB3_11           -                    partial(AES-128-CMAC)

Service      pid     Machine       Connected at                     Encryption   Signing
---------------------------------------------------------------------------------------------
IPC$         77781   127.0.0.1     Mon Sep 21 18:52:19 2026 UTC     -            -
<USER>       77781   127.0.0.1     Mon Sep 21 18:52:19 2026 UTC     -            -
```

### /home を公開するときの補足

- **公開されるのは `/home` の全体**
  - ユーザーのホームのほか、`/home` の下にあるユーザーのホームでないディレクトリ（Homebrew の `/home/linuxbrew` など）も見える
  - `/home/linuxbrew` は、既定のラベルが `user_home_dir_t`、その中が `user_home_t`（VM の `matchpathcon`）で、手順 4 の boolean の対象になる。読み書きは試していない
  - VM では、ほかのユーザーのホームの `.bashrc` を `[home]` から取得でき、ホームへの書き込みも通った（AVC は出ない）
- **作ったものの所有者・グループ・モード**（VM で確認）
  - 所有者は親ディレクトリの所有者（`/home/<ユーザー>` の中なら、そのユーザー）。グループは `root`
  - ファイルは `-rw-r--r--`（`create mask`）、ディレクトリは `drwxr-xr-x`（既定の `directory mask`）
  - ラベルは、ユーザーのホームの中なら `user_home_t`（`[homes]` と同じ）
- **`/home` の直下には作れない**
  - `smbclient` では、ファイルは `NT_STATUS_ACCESS_DENIED opening remote file \<名前>`、ディレクトリは `NT_STATUS_ACCESS_DENIED making remote directory \<名前>`
  - AVC は、ファイルが `denied { create } … tcontext=system_u:object_r:home_root_t:s0 tclass=file`、ディレクトリが `denied { create } … tcontext=system_u:object_r:user_home_dir_t:s0 tclass=dir`（`/home` に作るディレクトリは `user_home_dir_t` になるが、その作成は許されていない）
  - [samba-client.md](../samba-client.md) で `SHARE=home` にしてマウントしたときも、直下への書き込みは `Permission denied`
- **入るのは `<USER>`**: `pdbedit -L` に、ほかのユーザーは増えない。`smbstatus` では、Username が `<USER>`、Service が `home` になる

### 接続元を絞るときの補足

- `ALLOW_FROM` の各サブネットについて、rich rule を 1 本ずつ足す
- LAN と VPN の両方から使うなら、LAN のサブネットとトンネル網（`site.env` の `WG_TUNNEL_NET`。外出先クライアントも受けるならクライアント帯も）を並べる
- 実測（[付録](#接続元を絞る節の検証)）: `192.168.1.0/24 10.99.0.0/30` で絞った状態では、どちらにも属さない network namespace（192.168.250.0/24）からの接続が `NT_STATUS_HOST_UNREACHABLE` で落ち、そのサブネットの rich rule を足すと通った
- 手順 5 の `--add-port=445/tcp` を残したままだと rich rule が無意味になるので、先に外す。戻すときは逆順
- 実機での検証は、先頭の `if` を付ける前の形（`[ -n "${ALLOW_FROM}" ] || ...`）で行った
- `if` 付きの形は、`sudo` をスタブに置き換えて「空のときは何も呼ばれず、値を入れると同じコマンドが呼ばれる」ことだけ確認している

### 操作上の注意と併記されていた記録

  - macOS は、SMB 2/3 の一覧を手元にキャッシュする（Apple の文書。止めるには `nsmb.conf` の `dir_cache_max_cnt=0`）。本書では試していない

### 付録: 実機での検証記録（2026-09-21）

上記の手順を実機で本実行したときに取った記録。手順本文の根拠になった実測を残す。

#### 既定の smb.conf に対する testparm

`samba` を入れた直後、既定の `smb.conf` のまま `testparm -s` を実行した。`include = /etc/samba/usershares.conf` の対象ファイルは存在しないが、警告は出ない:

```
$ testparm -s
Load smb config files from /etc/samba/smb.conf
Loaded services file OK.
Weak crypto is allowed by GnuTLS (e.g. NTLM as a compatibility fallback)

Server role: ROLE_STANDALONE

# Global parameters
[global]
	printcap name = cups
	security = USER
	workgroup = SAMBA
	idmap config * : backend = tdb
	cups options = raw
	include = /etc/samba/usershares.conf
...
```

`testparm -sv` で見た、本手順で書かなかったパラメータの既定値:

```
	log file =
	logging =
	map to guest = Never
	server min protocol = SMB2_02
	server role = auto
	server signing = default
	server smb3 signing algorithms = AES-128-GMAC, AES-128-CMAC, HMAC-SHA256
	create mask = 0744
	directory mask = 0755
	hosts allow =
	map archive = Yes
	server smb encrypt = default
```

#### smbpasswd を TTY 無しで実行したとき

```
$ sudo smbpasswd -a "${SMB_USER}" < /dev/null
New SMB password:Unable to get new password.
exit=1
$ sudo pdbedit -L
(何も出ない)
```

失敗が終了コードに出るので、スクリプトから呼んでも気づける。パイプで 2 行渡すと `-s` が無くても登録できたが、正規の方法は `-s`:

```
$ printf '%s\n%s\n' "${PW}" "${PW}" | sudo smbpasswd -s -a "${SMB_USER}"
exit=0
$ sudo pdbedit -L
<USER>:1000:
$ sudo pdbedit -Lv "${SMB_USER}" | grep -E 'Unix username|Account Flags|Password last set'
Unix username:        <USER>
Account Flags:        [U          ]
Password last set:    Mon, 21 Sep 2026 18:50:45 UTC
```

#### SELinux boolean が off のときの失敗の署名

`samba_enable_home_dirs` が off のまま `smb.service` を起動し、登録済みのユーザーで接続した。認証は通り、共有一覧にも出るが、一覧の取得で拒否される。監査ログには何も残らない:

```
$ smbclient -L //localhost -A "${AUTHFILE}"

	Sharename       Type      Comment
	---------       ----      -------
	IPC$            IPC       IPC Service (Samba 4.23.5)
	<USER>          Disk      Home Directories
SMB1 disabled -- no workgroup available
$ smbclient "//localhost/${SMB_USER}" -A "${AUTHFILE}" -c 'ls'
NT_STATUS_ACCESS_DENIED listing \*
exit=1
$ sudo ausearch -m AVC -ts recent
<no matches>
$ sudo tail /var/log/samba/log.smbd
[2026/09/21 18:51:15.613243,  0] ../../source3/smbd/server.c:2119(main)
  smbd version 4.23.5 started.
  Copyright Andrew Tridgell and the Samba Team 1992-2025
```

smbd を再起動せずに boolean を on にすると、直後の `ls` が通った:

```
$ sudo setsebool -P samba_enable_home_dirs on
$ smbclient "//localhost/${SMB_USER}" -A "${AUTHFILE}" -c 'ls'
  .                                   D        0  Mon Sep 21 18:16:51 2026
  ..                                  D        0  Mon Sep 21 18:16:51 2026
  Downloads                           D        0  Tue May  5 00:01:53 2026
  ...
```

#### create mask 無しで作ったファイルに x ビットが付く

`create mask` を書かない状態（既定 `0744`、`map archive = Yes`）で、`smbclient` の `put` と `mount.cifs` 上の `touch` で作ったファイルは、いずれも owner に x ビットが付いた。DOS の archive 属性が owner の x に写るため:

```
$ ls -lZ ~/smb-test.txt
-rwxr--r--. 1 <USER> <USER> system_u:object_r:user_home_t:s0 12 Sep 21 18:52 /home/<USER>/smb-test.txt
$ ls -lZ /mnt/smbtest/cifs-test.txt ~/cifs-test.txt
-rwxr--r--. 1 <USER> <USER> system_u:object_r:user_home_t:s0 11 Sep 21 18:52 /home/<USER>/cifs-test.txt
-rwxr-xr-x. 1 <USER> <USER> system_u:object_r:cifs_t:s0      11 Sep 21 18:52 /mnt/smbtest/cifs-test.txt
$ ls -ldZ ~/cifs-test-dir
drwxr-xr-x. 2 <USER> <USER> system_u:object_r:user_home_t:s0 4096 Sep 21 18:52 /home/<USER>/cifs-test-dir
```

`[homes]` に `create mask = 0644` を足して `systemctl restart smb.service` したあとは `-rw-r--r--` になった（ディレクトリは既定の `directory mask = 0755` のまま `drwxr-xr-x`）:

```
$ ls -lZ ~/smb-test.txt ~/cifs-test.txt
-rw-r--r--. 1 <USER> <USER> system_u:object_r:user_home_t:s0 12 Sep 21 18:53 /home/<USER>/smb-test.txt
-rw-r--r--. 1 <USER> <USER> system_u:object_r:user_home_t:s0  0 Sep 21 18:53 /home/<USER>/cifs-test.txt
```

#### mount.cifs のマウントオプション（実測）

```
$ mount | grep cifs
//127.0.0.1/<USER> on /mnt/smbtest type cifs (rw,relatime,vers=3.1.1,cache=strict,upcall_target=app,username=<USER>,uid=1000,forceuid,gid=1000,forcegid,addr=127.0.0.1,file_mode=0755,dir_mode=0755,soft,nounix,serverino,mapposix,reparse=nfs,rsize=4194304,wsize=4194304,bsize=1048576,echo_interval=60,actimeo=1,closetimeo=1)
```

#### 起動中のユーザー削除・再登録

smbd を動かしたまま `smbpasswd -x` → `-s -a` した。削除直後は `NT_STATUS_LOGON_FAILURE`、再登録直後から再び通る。再起動は不要:

```
$ sudo smbpasswd -x "${SMB_USER}"
Deleted user <USER>.
$ smbclient "//localhost/${SMB_USER}" -A "${AUTHFILE}" -c 'ls Public'
session setup failed: NT_STATUS_LOGON_FAILURE
$ printf '%s\n%s\n' "${PW}" "${PW}" | sudo smbpasswd -s -a "${SMB_USER}"
Added user <USER>.
$ smbclient "//localhost/${SMB_USER}" -A "${AUTHFILE}" -c 'ls Public'
  Public                              D        0  Tue May  5 00:01:53 2026
```

#### 失敗の署名

```
$ smbclient "//localhost/${SMB_USER}" -U "${SMB_USER}%wrongpass" -c 'ls'     # パスワード違い
session setup failed: NT_STATUS_LOGON_FAILURE
$ smbclient "//localhost/nosuchuser" -U "nosuchuser%x" -c 'ls'               # 存在しないユーザー
session setup failed: NT_STATUS_LOGON_FAILURE
$ smbclient "//localhost/root" -A "${AUTHFILE}" -c 'ls'                      # 他人のホーム（valid users = %S）
tree connect failed: NT_STATUS_ACCESS_DENIED
```

`NT_STATUS_ACCESS_DENIED` は「認証は通ったが共有に入れない」で、他人のホームに入ろうとした場合は `tree connect failed:`、SELinux boolean が off の場合は `listing \*` と、出る段階が違う。

#### network namespace から firewalld 越しに到達する

自ホストからの接続は `lo` で受理されて firewalld を通らない:

```
$ sudo nft list chain inet firewalld filter_INPUT
table inet firewalld {
	chain filter_INPUT {
		type filter hook input priority filter + 10; policy accept;
		ct state { established, related } accept
		ct status dnat accept
		iifname "lo" accept
		ct state invalid drop
		jump filter_INPUT_POLICIES
		reject with icmpx admin-prohibited
	}
}
```

そこで veth で結んだ network namespace から接続した。ゾーン未割り当ての veth は既定ゾーン（public）の扱いになる（`--get-zone-of-interface` は `no zone` を返す）ので、public に開けたポートがそのまま効く:

```bash
sudo ip netns add smbtest
sudo ip link add veth-smb type veth peer name veth-ns
sudo ip link set veth-ns netns smbtest
sudo ip addr add 192.168.250.1/24 dev veth-smb && sudo ip link set veth-smb up
sudo ip netns exec smbtest ip addr add 192.168.250.2/24 dev veth-ns
sudo ip netns exec smbtest ip link set veth-ns up
```

```
$ sudo firewall-cmd --get-zone-of-interface=veth-smb
no zone
$ sudo ip netns exec smbtest smbclient "//192.168.250.1/${SMB_USER}" -A "${AUTHFILE}" -c 'ls Public'
  Public                              D        0  Tue May  5 00:01:53 2026
$ sudo ip netns exec smbtest timeout 5 bash -c 'exec 3<>/dev/tcp/192.168.250.1/139'
bash: connect: No route to host
$ sudo firewall-cmd --remove-port=445/tcp        # 一時的に閉じる（runtime のみ）
$ sudo ip netns exec smbtest smbclient "//192.168.250.1/${SMB_USER}" -A "${AUTHFILE}" -c 'ls Public'
do_connect: Connection to 192.168.250.1 failed (Error NT_STATUS_HOST_UNREACHABLE)
$ sudo firewall-cmd --add-port=445/tcp
```

445 を閉じると `NT_STATUS_HOST_UNREACHABLE`（firewalld の `reject with icmpx admin-prohibited`）になり、firewalld が経路上にあることが確認できた。139 は listen していないうえ firewalld でも開いていないので `No route to host`。後片付け:

```bash
sudo ip link del veth-smb
sudo ip netns del smbtest
```

#### 接続元を絞る節の検証

`ALLOW_FROM="192.168.1.0/24 10.99.0.0/30"` で[接続元を絞る](../samba.md#接続元を絞る任意)のコマンドを実行し、上の network namespace（192.168.250.0/24、どちらにも属さない）から接続した:

```
$ sudo firewall-cmd --list-rich-rules
rule family="ipv4" source address="10.99.0.0/30" port port="445" protocol="tcp" accept
rule family="ipv4" source address="192.168.1.0/24" port port="445" protocol="tcp" accept
$ sudo firewall-cmd --list-ports
22/tcp 8384/tcp 51820/udp
$ sudo ip netns exec smbtest smbclient "//192.168.250.1/${SMB_USER}" -A "${AUTHFILE}" -c 'ls Public'
do_connect: Connection to 192.168.250.1 failed (Error NT_STATUS_HOST_UNREACHABLE)
$ sudo firewall-cmd --add-rich-rule="rule family=ipv4 source address=192.168.250.0/24 port port=445 protocol=tcp accept"
$ sudo ip netns exec smbtest smbclient "//192.168.250.1/${SMB_USER}" -A "${AUTHFILE}" -c 'ls Public'
  Public                              D        0  Tue May  5 00:01:53 2026
```

確認後、同節の「戻す」コマンドで rich rule を外し、`445/tcp` の開放に戻した。実機はこの状態（public ゾーン全体で 445/tcp）で運用している。

#### 未確認事項

- Windows / macOS / Android / iOS の実クライアントからの接続
- 拠点 A の LAN や外出先クライアントから WireGuard 越しに `<WG_IP>` へ接続すること（firewalld の通過は network namespace で確認したが、実際のトンネル経由では未確認）
- `server smb encrypt = required` にしたときのクライアント互換性
- 2 人目以降のユーザー（`useradd` → `smbpasswd -a` の追加だけで済むはずだが未実施）

### 付録: root のホームを公開する節の VM での検証（2026-09-29）

[root のホームも公開する（任意）](../samba.md#root-のホームも公開する任意)と、[ロールバック](../samba.md#ロールバック)の手順 2 を足したときの記録。x86_64 のクラウドのホストの上の、使い捨ての VM で行った。実機で加えた変更は無い。

**環境**:

- ホストは Ubuntu 24.04 / x86_64 のクラウドの VM（`/dev/kvm` 無し）。QEMU 8.2.2 の TCG（`-accel tcg,thread=multi -cpu max -smp 4 -m 4096`）で、`AlmaLinux-10-GenericCloud-10.2-20260817.0.x86_64.qcow2`（`CHECKSUM` の SHA-256 と一致）を起動した
- 作り方は [samba-client.md の付録](samba-client.md#付録-vm-での検証記録2026-09-27)と同じ
  - cloud-init で、`<USER>`（uid 1000、`wheel`）と、確かめ用の 2 人目（uid 1001、NOPASSWD の `sudo`）を作った
  - プロキシの CA、dnf の `proxy=`、`almalinux-*.repo` の `baseurl=` を入れた
  - `dnf upgrade`（カーネルは 6.12.0-211.56.1）の後、確かめ用に `setools-console`・`policycoreutils-python-utils`・`firewalld`（有効にした）・`glibc-langpack-ja`・`tmux` を入れた。このディスクを残し、回ごとに overlay で起動した
- 版: `selinux-policy-targeted-42.1.18-4.el10_2.3`、`policycoreutils-3.10-2.el10_2`、`samba-4.23.5-110.el10_2`、`sudo-1.9.17-10.p2.el10_2.6`、firewalld 2.4.3。SELinux は Enforcing
- GenericCloud の `/root` は `dr-xr-x---`（`admin_home_t`）で、シェルの設定ファイル 5 つ（`admin_home_t`）と、cloud-init が作る `.ssh`（`ssh_home_t`）がある

**方針を決めた下調べ**（VM の `seinfo` と `sesearch`）:

- `samba_enable_home_dirs` が smbd に許すのは、属性 `user_home_type` のラベル。`ssh_home_t`・`config_home_t`・`cache_home_t`・`gpg_secret_t` などは入っているが、`admin_home_t` は入っていない
- `admin_home_t` のディレクトリは、どのドメインにも `getattr open search` だけが許され、デーモンの `read` は dontaudit。モジュールが無いときの `ls` で AVC が出ないのはこのため
- `smbd_t` のケーパビリティには `dac_override` がある

```
$ seinfo -t admin_home_t -x
   type admin_home_t, file_type, mountpoint, non_auth_file_type, non_security_file_type, polymember, polyparent;
$ seinfo -t ssh_home_t -x
   type ssh_home_t alias { … }, file_type, non_auth_file_type, non_security_file_type, polymember, polyparent, user_home_type;
$ sesearch -A -s smbd_t -t ssh_home_t
…
allow smbd_t user_home_type:dir { add_name create ioctl link lock read remove_name rename reparent rmdir setattr unlink watch watch_reads write }; [ samba_enable_home_dirs ]:True
allow smbd_t user_home_type:dir { getattr open search };
$ sesearch --dontaudit -s smbd_t -t admin_home_t
dontaudit daemon admin_home_t:dir { getattr ioctl lock open read search };
…
```

**root を `smbpasswd -a` で登録したとき**（`[homes]` のまま、モジュール無し）: `[homes]` は `root` の共有を出すが、`ls` は通らない。登録は `smbpasswd -x` では消せなかった:

```
$ sudo pdbedit -L
<USER>:1000:
root:0:Super User
<2 人目>:1001:
$ smbclient //localhost/root -A <root の資格情報ファイル> -c 'ls'
NT_STATUS_ACCESS_DENIED listing \*
$ smbclient //localhost/root -A <root の資格情報ファイル> -c 'get .bashrc /tmp/r.bashrc'
NT_STATUS_ACCESS_DENIED opening remote file \.bashrc
$ sudo smbpasswd -x root
Failed to delete entry for user root.
$ sudo pdbedit -x -u root
$ sudo pdbedit -L
<USER>:1000:
<2 人目>:1001:
```

**`[root]` を足し、モジュールを入れる前**:

```
$ smbclient //localhost/root -A <USER の資格情報ファイル> -c 'ls'
NT_STATUS_ACCESS_DENIED listing \*
$ smbclient //localhost/root -A <USER の資格情報ファイル> -c 'get .bashrc /tmp/t.bashrc'
NT_STATUS_ACCESS_DENIED opening remote file \.bashrc
$ smbclient //localhost/root -A <USER の資格情報ファイル> -c 'put /etc/hostname x.txt'
NT_STATUS_ACCESS_DENIED opening remote file \x.txt
$ sudo ausearch -m AVC -ts recent
avc:  denied  { getattr } for  pid=… comm="smbd[127.0.0.1]" path="/root/.bashrc" dev="vda4" ino=… scontext=system_u:system_r:smbd_t:s0 tcontext=system_u:object_r:admin_home_t:s0 tclass=file permissive=0
avc:  denied  { write } for  pid=… comm="smbd[127.0.0.1]" name="root" dev="vda4" ino=… scontext=system_u:system_r:smbd_t:s0 tcontext=system_u:object_r:admin_home_t:s0 tclass=dir permissive=0
```

**モジュールを入れた後**（下調べの VM で、手順書のブロックとは別に確かめたこと）:

- `semodule -i` は 53 秒、`semodule -r` は 50 秒（`time` の real）
- `put`・`get`・`mkdir`・`rename`・`allinfo`・`del`・`rmdir` が通り、`ausearch -m AVC` は何も出さなかった
- `.ssh/authorized_keys` を `get` で取得できた。SMB で作った `.config` とその中のファイルは `admin_home_t` だった
- 2 人目は `tree connect failed: NT_STATUS_ACCESS_DENIED`。`smbclient -L` の一覧は、どちらのユーザーでも自分の共有と `IPC$` だけ
- `mount.cifs` でマウントしている間の `smbstatus` では、Username は `<USER>`、Service は `root`
- 元に戻した後の `//localhost/root` は、`<USER>` では `tree connect failed: NT_STATUS_ACCESS_DENIED`
- `semodule -r` は、標準エラーに `libsemanage.semanage_direct_remove_key: Removing last samba_root_home module (no other samba_root_home module exists at another priority).` と出した（端末で貼った回も同じ）

```
$ sudo ls -laZ /root /root/d1
/root:
dr-xr-x---.  4 root root system_u:object_r:admin_home_t:s0 113 Sep 29 11:30 .
…
drwxr-xr-x.  2 root root system_u:object_r:admin_home_t:s0  23 Sep 29 11:30 d1
drwx------.  2 root root system_u:object_r:ssh_home_t:s0    29 Sep 29 10:42 .ssh
…
/root/d1:
-rw-r--r--. 1 root root system_u:object_r:admin_home_t:s0   6 Sep 29 11:30 moved.txt
$ sudo smbstatus
…
PID     Username     Group        Machine                                   Protocol Version  Encryption           Signing
…       <USER>       <USER>       127.0.0.1 (ipv4:127.0.0.1:…)              SMB3_11           -                    partial(AES-128-CMAC)

Service      pid     Machine       Connected at                     Encryption   Signing
root         …       127.0.0.1     Tue Sep 29 11:30:28 AM 2026 UTC  -            -
IPC$         …       127.0.0.1     Tue Sep 29 11:30:28 AM 2026 UTC  -            -
```

**手順書のブロックを貼った回**:

- ホストから `ssh -t` で `<USER>` としてログインし、この文書と samba-client.md から抜き出したコードブロックを、pexpect で端末に送った
  - 貼り方は 2 通りで、それぞれまっさらな overlay から通した: ブラケットペースト無し（行をそのまま打ち込む）と、ブラケットペースト（`ESC [200~` と `ESC [201~` で包んで送ってから Enter）
  - `smbpasswd`・`read`・`smbclient` のパスワードは、問い合わせが出てから送った
- 1 つのシェルで、次の順に貼った
  - 手順 1〜8 と、[サーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の手順 1〜6
  - `sudo -i` した root のシェルで、root の節の手順 1
  - root の節の手順 1〜3 と、動作を確かめる節の手順 7・8
  - samba-client.md の手順 1〜5（`SERVER=127.0.0.1`、`SHARE=root` に書き換えた）と、同書のロールバックの手順 3（マウント先と資格情報ファイルを消す）
  - 別の ssh のセッションから、2 人目を Samba に登録して `[root]` へつなぐ（手順書の外）
  - root の節の手順 1（2 回目）、手順 5、手順 1・2（入れ直し）
  - ロールバックの手順 1〜3
- ブラケットペーストの回では、2 人目の確認と同じところで、`.ssh` へのファイルの書き込み、`.bashrc` の書き換え（元の内容に戻した）、SMB で作った `.config` への `restorecon` も確かめた。どれも AVC は出なかった
- この 2 回の前に 2 回流し始めたが、貼る道具の不具合（プロンプトの待ち方と、送るパスワードの取り違え）で途中で止まったので捨てた

| 貼ったもの | 結果（2 回とも同じ） |
|---|---|
| 手順 1〜8 と、動作を確かめる節の手順 1〜6 | 2026-09-28 の記録と同じ。動作を確かめる節の手順 6 の `ausearch` は `<no matches>` |
| root のシェルで、root の節の手順 1 | `中断: USER が空か root。公開したユーザー自身のシェルで貼る`。smb.conf は変わらない |
| root の節の手順 1 | `testparm -s` の末尾に `[root]`（`force user = root`、`path = /root`、`valid users = <USER>`） |
| root の節の手順 2 | `samba_root_home` の 1 行 |
| root の節の手順 3 と、動作を確かめる節の手順 7 | `/root` の一覧（`.ssh`・`.bashrc` など）、`putting file /etc/hostname as \smb-root-test.txt`、`smb-root-test.txt` の 1 行 |
| 動作を確かめる節の手順 8 | `-rw-r--r--. 1 root root system_u:object_r:admin_home_t:s0 6 … /root/smb-root-test.txt` と `<no matches>` |
| samba-client.md の手順 4・5 | `/root/smb-<USER>@127.0.0.1.cred`、`//127.0.0.1/root` の `cifs`（`vers=3.1.1`）、`cifs write`、`drwx------. 2 <USER> <USER> system_u:object_r:cifs_t:s0 … /mnt/root` |
| 2 人目 | `tree connect failed: NT_STATUS_ACCESS_DENIED`。`smbclient -L` に `root` は出ない |
| root の節の手順 1（2 回目） | `中断: /etc/samba/smb.conf に [root] が既にある` |
| root の節の手順 5 | `libsemanage.semanage_direct_remove_key: Removing last samba_root_home module …` と `0`。smb.conf の末尾には空行が 1 つ残る |
| ロールバックの手順 1〜3 | `semodule -l` に `samba_root_home` が無く、パッケージも消えた。`ausearch -m AVC -ts today` は最後まで `<no matches>` |

- 動作を確かめる節の手順 7 の一覧には `.bash_history` も出た。直前に `sudo -i` で root のシェルを開いたため

ブラケットペーストの回の、書き込みとラベルの確認（手順書の外。`<USER>` の資格情報ファイルで `smbclient` を使った）:

```
$ smbclient //localhost/root -A <USER の資格情報ファイル> -c 'get .bashrc /tmp/bashrc.orig; put /etc/hostname .ssh/smb-write-test'
getting file \.bashrc of size 429 as /tmp/bashrc.orig (6.5 KiloBytes/sec) (average 6.5 KiloBytes/sec)
putting file /etc/hostname as \.ssh\smb-write-test (0.1 kB/s) (average 0.1 kB/s)
$ sudo ls -lZ /root/.ssh/
-rw-------. 1 root root system_u:object_r:ssh_home_t:s0 0 Sep 29 10:42 authorized_keys
-rw-r--r--. 1 root root system_u:object_r:ssh_home_t:s0 6 Sep 29 13:00 smb-write-test
$ smbclient //localhost/root -A <USER の資格情報ファイル> -c 'put /tmp/bashrc.new .bashrc'      # 末尾に 1 行足したもの
putting file /tmp/bashrc.new as \.bashrc (8.5 kB/s) (average 8.5 kB/s)
$ sudo tail -n 2 /root/.bashrc; sudo ls -lZ /root/.bashrc
alias mv='mv -i'
# smb write test
-rw-r--r--. 1 root root system_u:object_r:admin_home_t:s0 446 Sep 29 13:00 /root/.bashrc
$ smbclient //localhost/root -A <USER の資格情報ファイル> -c 'mkdir .config; put /etc/hostname .config/x'
$ sudo restorecon -Rv /root/.config
Relabeled /root/.config from system_u:object_r:admin_home_t:s0 to system_u:object_r:config_home_t:s0
Relabeled /root/.config/x from system_u:object_r:admin_home_t:s0 to system_u:object_r:config_home_t:s0
$ sudo ausearch --input-logs -m AVC -ts today         # 端末の無い ssh から流したので --input-logs
<no matches>
```

`.bashrc` は元の内容を `put` し直し、`.ssh/smb-write-test` と `.config` は SMB から消した。

#### 未確認事項（root の節）

- 実機（Raspberry Pi の拠点 B のホスト）での実行
- Windows・macOS などのクライアントから `root` の共有につなぐこと。Windows で `<USER>` の共有と同時に開けること（エラー 1219 が出ないこと）
- samba-client.md の自動マウント（手順 6・7）を `SHARE=root` で行うこと

### 付録: サーバーで変えたものがクライアントに見えるまで（2026-10-01）

サーバーで（Samba を通さずに）変えたファイルやディレクトリが、クライアントの再読み込みですぐに出るかを確かめ、手順 3 に `smb3 directory leases = no` を足したときの記録。実機に加えた変更は、[設定済みのサーバーでディレクトリのリースを切る](../samba.md#設定済みのサーバーでディレクトリのリースを切る)の手順 1・2 だけ（ほかに、ホーム直下にテスト用のファイルを作って消した）。

**環境**:

- 実機は上の表のホスト（カーネル `6.12.96-20260724.v8.1.el10`、`samba-4.23.5-110.el10_2`）。直す前の `testparm -sv` は `smb3 directory leases = Auto`
- Windows のクライアントは、利用者の PC のエクスプローラー（`<CLIENT_IP>`。`smbstatus` では `SMB3_11`、署名は `AES-128-GMAC`）。実機でファイルを作り、エクスプローラーでの見え方を利用者が確かめた
- Linux のクライアントは、実機の smbd に触らずに測った
  - サーバー: 実機の上の rootless の podman 5.8.2 で、`quay.io/almalinuxorg/almalinux:10.2`（aarch64）を `-p 127.0.0.1:4450:445` で立て、`samba-4.23.5-110.el10_2` を入れた
  - smb.conf は、手順 3 のブロック（直す前と後）をそのまま貼って置いた。試験用のユーザー `smbreload`（実機に無い名前）を `smbpasswd -s -a` で登録し、`smbd --foreground --no-process-group` で動かした
  - kernel の cifs: 実機のカーネル（`cifs.ko` の版 2.51、`dir_cache_timeout` は既定の 30）で、samba-client.md 手順 5 と同じオプションに `port=4450` を足してマウントした。EL10 の x86_64 のカーネル（6.12.0-211 系）では測っていない
  - GNOME Files: 実機のヘッドレスの GNOME のセッション（nautilus 47.6、`gvfs-smb-1.54.4-3.el10`）で、`/usr/bin/gio mount smb://smbreload@127.0.0.1:4450/smbreload` でつないだ。PATH で先に見つかる Homebrew の `gio` は、`Operation not supported` で使えなかった
  - 画面は、[claude-code-gui.md](../claude-code-gui.md) の `scripts/gnome-gui.py` で Nautilus を開き、F5 を送って撮った
  - サーバーでの変更は、`podman exec` でコンテナの中のファイルを直接変えた（Samba を通さない）

**直す前の Windows**（利用者がエクスプローラーで `\\<SERVER_IP>\<USER>` を開き、実機のホーム直下に `touch` でファイルを作った）:

- 作ってから 15 秒見ても出ず、F5 でも出なかった
- 約 1 分後の F5 でも、ウィンドウを閉じて開き直しても出なかった（作ってから約 3 分）
- その間の `smbstatus -L` では、`LEASE(RH)` の行（19:35:31 に開いたもの）が残り続けた。F5 のたびに開き直されたのは、リースの無い 2 行だけだった

```
$ sudo smbstatus -L        # 作ってから約 3 分後（ウィンドウを開き直した後）
Locked files:
Pid          User(ID)   DenyMode   Access      R/W        Oplock           SharePath   Name   Time
--------------------------------------------------------------------------------------------------
24240        1000       DENY_NONE  0x100081    RDONLY     NONE             /home/<USER>   .   Thu Oct  1 19:38:59 2026
24240        1000       DENY_NONE  0x100081    RDONLY     NONE             /home/<USER>   .   Thu Oct  1 19:38:59 2026
24240        1000       DENY_NONE  0x100081    RDONLY     LEASE(RH)        /home/<USER>   .   Thu Oct  1 19:35:31 2026
```

**実機に足したとき**（[設定済みのサーバーでディレクトリのリースを切る](../samba.md#設定済みのサーバーでディレクトリのリースを切る)の手順 1・2。つないでいたのは `<CLIENT_IP>` の 1 つだけ）:

```
$ （リースを切る節の手順 1）
	smb3 directory leases = No
$ ls -lZ /etc/samba/smb.conf
-rw-r--r--. 1 root root system_u:object_r:samba_etc_t:s0 493 Oct  1 19:40 /etc/samba/smb.conf
$ head -3 /etc/samba/smb.conf | cat -A
[global]$
    smb3 directory leases = no$
^Iworkgroup = WORKGROUP$
$ （リースを切る節の手順 2）
active
```

**直した後の Windows**:

- 再起動で切れたエクスプローラーは、F5 でつなぎ直した（資格情報は聞かれなかった）。直す前に作ったファイルも出た
- 実機で作ったファイル、消した 2 つのファイルと作ったディレクトリ、そのディレクトリを開いた状態で中に作ったファイルが、どれも F5 を押す前に出た（15 秒以内）

```
$ sudo smbstatus -L        # つなぎ直した後
Locked files:
Pid          User(ID)   DenyMode   Access      R/W        Oplock           SharePath   Name   Time
--------------------------------------------------------------------------------------------------
92245        1000       DENY_NONE  0x100081    RDONLY     NONE             /home/<USER>   .   Thu Oct  1 19:43:17 2026
92245        1000       DENY_NONE  0x100081    RDONLY     NONE             /home/<USER>   .   Thu Oct  1 19:43:17 2026
```

**kernel の cifs**（Linux）:

- 場面ごとにマウントし直し、`ls` で一覧を読んでから、サーバーで変え、0.5 秒ごとに `ls -1A`（名前を引く場面は `stat`）で、出るまでの秒数を測った
- `/proc/fs/cifs/DebugData` の `Server capabilities` は、直す前が `0x300067`、直した後が `0x300047`（`0x20` がディレクトリのリース）
- 直す前は、コンテナの `smbstatus -L` に、cifs のクライアントが共有の直下に持つ `LEASE(RH)` が出た。直した後は `No locked files`

| 場面 | 直す前 | 直した後 | 直す前＋クライアントに `nohandlecache` |
|---|---|---|---|
| 直下にファイルを作る（`ls`） | 31.5 秒 | 0.0 秒 | 0.0 秒 |
| 直下のファイルを消す（`ls`） | 31.0 秒 | 0.0 秒 | 0.0 秒 |
| 直下のファイルの名前を変える（`ls`） | 31.5 秒 | 0.0 秒 | 測っていない |
| 直下にディレクトリを作る（`ls`） | 32.0 秒 | 0.0 秒 | 測っていない |
| サブディレクトリの中に作る（`ls`） | 31.5 秒 | 0.0 秒 | 0.0 秒 |
| マウントの 10 秒後に初めて読んだサブディレクトリの中に作る（`ls`） | 52.1 秒 | 測っていない | 測っていない |
| 新しい名前を `stat` で引く | 0.0 秒（`ls` にはまだ出ない） | 0.0 秒 | 測っていない |
| 消したファイルを `stat` で引く | 30.5 秒（その間はあるように見える） | 1.0 秒 | 1.0 秒 |
| 追記したファイルの大きさ（`stat -c %s`） | 1.0 秒 | 1.0 秒 | 測っていない |
| Samba を通して作る（コンテナの `smbclient`。対照） | 0.0 秒 | 0.0 秒 | 測っていない |

- 直す前に古い一覧が出たのは、一覧をキャッシュしてから 30〜60 秒。`dir_cache_timeout`（既定 30 秒）の間隔で、古いキャッシュが捨てられるため。マウントの 10 秒後に読んだものは、マウントから 62 秒で出た
- 直す前でも、Samba を通した変更はすぐに出た（Samba がリースを破る）
- 直す前に、`ls` を繰り返さずに 65 秒待った回も、65 秒後には出ていた（読むたびに延びるわけではない）
- 直す前の、古い一覧が出ていた間は、`/proc/fs/cifs/Stats` の `QueryDirectories` が増えなかった（一覧はサーバーに聞かずに返っていた）
- 1.0 秒の場面は、属性のキャッシュ（`actimeo=1`）による

**GNOME Files（gvfs）**:

- `gio list` は、直す前も直した後も、サーバーで作る・消す・サブディレクトリの中に作るのを、すぐ（0.0 秒）出した。コンテナの `smbstatus -L` は `No locked files`（gvfs はリースを持たない）
- Nautilus に `smb://` の場所を開いてからサーバーでファイルを作ると、直す前も直した後も、15 秒たっても自動では出ず、F5 ですぐ出た（画面を撮って確かめた）
- `gio mount` の後に開いた Nautilus のサイドバーに、共有が出た（同じ画面の写しで確かめた）

**ブロックの確かめ**（コンテナ）:

- 直す前の手順 3 で置いた smb.conf と、実機の smb.conf の写し（字下げが TAB、`[root]` あり）の両方で、リースを切る節の手順 1 は `[global]` の次の行に空白の字下げで 1 行を足した
- 2 回目は `中断: /etc/samba/smb.conf に smb3 directory leases の行が既にある` で、何も変えなかった
- リースを切る節の手順 3 で、どちらも足す前と同じ内容に戻った（`diff` で比べた）
- コンテナには systemd が無いので、リースを切る節の手順 2・3 の `systemctl` は、smbd を起動し直すスタブにした
- 直した後の手順 3 のブロックは、`testparm -s` の `[global]` の `server smb transports = tcp` の次に `smb3 directory leases = No` を出した。上の表の「直した後」と同じ振る舞いだった（作る・サブディレクトリの中に作る・消したファイルの `stat` を測った）

#### 未確認事項（ディレクトリのリース）

- macOS・iOS・Android のクライアント（利用者は Android のファイルアプリも使う）
- WireGuard 越しの接続
- EL10 の x86_64 のカーネルの cifs
- [設定済みのサーバーでディレクトリのリースを切る](../samba.md#設定済みのサーバーでディレクトリのリースを切る)の手順 3 を、実機で貼ること
- 手順 1〜8 と、[サーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の手順 1〜6 を通しで貼ること（手順 3 のブロックは、コンテナで貼っただけ）
- 開いたままのファイルを、サーバーで直接書き換えたときの見え方（ファイルのリース。`smb2 leases` は有効のまま）

### 付録: /home を公開する節の VM での検証（2026-10-05）

[/home も公開する（任意）](../samba.md#home-も公開する任意)と、[サーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の手順 9・10 を足したときの記録。x86_64 のクラウドのホストの上の、使い捨ての VM で行った。実機で加えた変更は無い。

**環境**:

- 作り方は、[root の節の付録](#付録-root-のホームを公開する節の-vm-での検証2026-09-29)と同じ
  - ホストは Ubuntu 24.04 / x86_64 のクラウドの VM（`/dev/kvm` 無し）。QEMU 8.2.2 の TCG（`-accel tcg,thread=multi -cpu max -smp 4 -m 4096`）で、`AlmaLinux-10-GenericCloud-10.2-20260817.0.x86_64.qcow2`（`CHECKSUM` の SHA-256 と一致）を起動した
  - cloud-init で、`<USER>`（uid 1000、`wheel`）と、確かめ用の 2 人目（uid 1001）を作った。どちらも NOPASSWD の `sudo`
  - プロキシの CA、dnf の `proxy=`、`almalinux-*.repo` の `baseurl=` を入れた
  - `dnf upgrade`（カーネルは 6.12.0-211.56.1）の後、確かめ用に `setools-console`・`policycoreutils-python-utils`・`firewalld`（有効にした）・`glibc-langpack-ja`・`tmux` を入れた。このディスクを残し、回ごとに overlay で起動した
- 版: `selinux-policy-targeted-42.1.18-4.el10_2.3`、`policycoreutils-3.10-2.el10_2`、`samba-4.23.5-110.el10_2`、`sudo-1.9.17-10.p2.el10_2.6`。SELinux は Enforcing
- `/home` は `home_root_t`、`/home/<USER>` と `/home/<2 人目>` は `user_home_dir_t`

**方針を決めた下調べ**（下調べの VM で、手順書のブロックとは別に）:

- `smbd_t` は、`home_root_t` のディレクトリの `read` を boolean の条件なしで許されている。手順 4 の boolean だけで、`[home]` の一覧と、ユーザーのホームの読み書きが通った
- `/home` に作るディレクトリは `user_home_dir_t` に移る（`type_transition`）。`user_home_dir_t` は `user_home_type` に入っておらず、作ることは許されていない
- 2 人目のホームの中に `smbclient` で作ったものと、2 人目のファイルを `rename -f` で上書きしたときの所有者:

| `inherit owner` | 作ったファイル・ディレクトリ | 2 人目のファイルを改名で上書き |
|---|---|---|
| 無し | `root root` | `root root` に変わった |
| `yes`（`testparm` は `windows and unix`） | `<2 人目> root` | `<2 人目> root` |
| `unix only` | `<2 人目> root` | 試していない |

- `/home` の直下に作れないのは SELinux: `setenforce 0` にすると、ファイルが `root root` の `home_root_t` で作れた
- Homebrew の場所の既定のラベルは、`matchpathcon` で `/home/linuxbrew` が `user_home_dir_t`、`/home/linuxbrew/.linuxbrew/bin/brew` が `user_home_t`
- 端末の無い ssh から流した `sudo ausearch` は、`--input-logs` を付けないと AVC があっても `<no matches>` を出した（標準入力を読むため）。下調べの初めの 1 回はこれで AVC を見落とし、`/var/log/audit/audit.log` を直接読んで気付いた

```
$ sesearch -A -s smbd_t -t home_root_t
…
allow smbd_t home_root_t:dir { add_name ioctl lock read remove_name write };
…
$ sesearch -T -s smbd_t -t home_root_t
type_transition smbd_t home_root_t:dir user_home_dir_t;
$ seinfo -t user_home_dir_t -x
   type user_home_dir_t alias { … }, file_type, mountpoint, non_auth_file_type, non_security_file_type, polydir, polymember, polyparent;
```

**手順書のブロックを貼った回**:

- ホストから `ssh -t` で `<USER>` としてログインし、この文書と samba-client.md から抜き出したコードブロックを、pexpect で端末に送った
  - 貼り方は 2 通りで、それぞれまっさらな overlay から通した: ブラケットペースト無し（行をそのまま打ち込む）と、ブラケットペースト（`ESC [200~` と `ESC [201~` で包んで送ってから Enter）
  - `smbpasswd`・`read`・`smbclient` のパスワードは、問い合わせが出てから送った
- 1 つのシェルで、次の順に貼った
  - 手順 1〜8 と、[サーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の手順 1〜6
  - root の節の手順 1〜3
  - `sudo -i` した root のシェルで、/home の節の手順 1
  - /home の節の手順 1・2 と、動作を確かめる節の手順 7〜10
  - /home の節の手順 1（2 回目）
  - samba-client.md の手順 1〜5（`SERVER=127.0.0.1`、`SHARE=home` に書き換えた）と、同書のロールバックの手順 3（マウント先と資格情報ファイルを消す）
  - 手順書の外の確かめ（下）
  - /home の節の手順 4、手順書の外の確かめ（戻した後）
  - ロールバックの手順 1〜3

| 貼ったもの | 結果（2 回とも同じ） |
|---|---|
| 手順 1〜8 と、動作を確かめる節の手順 1〜6 | 2026-09-28 の記録と同じ。動作を確かめる節の手順 6 の `ausearch` は `<no matches>` |
| root の節の手順 1〜3 と、動作を確かめる節の手順 7・8 | 2026-09-29 の記録と同じ |
| root のシェルで、/home の節の手順 1 | `中断: USER が空か root。公開したユーザー自身のシェルで貼る`。smb.conf は変わらない |
| /home の節の手順 1 | `testparm -s` の末尾（`[root]` の後ろ）に `[home]`（`force user = root`、`inherit owner = windows and unix`、`path = /home`、`valid users = <USER>`） |
| 動作を確かめる節の手順 9 | `<USER>` と `<2 人目>` のディレクトリの一覧、`putting file /etc/hostname as \<USER>\smb-home-test.txt`、`smb-home-test.txt` の 1 行 |
| 動作を確かめる節の手順 10 | `-rw-r--r--. 1 <USER> root system_u:object_r:user_home_t:s0 6 … /home/<USER>/smb-home-test.txt` と `<no matches>` |
| /home の節の手順 1（2 回目） | `中断: /etc/samba/smb.conf に [home] が既にある` |
| samba-client.md の手順 4 | `-rw-------. 1 root root system_u:object_r:admin_home_t:s0 … /root/smb-<USER>@127.0.0.1.cred` |
| samba-client.md の手順 5 | `//127.0.0.1/home` の `cifs`（`vers=3.1.1`）の行の後に `-bash: /mnt/home/cifs-test.txt: Permission denied`、`drwx------. 2 <USER> <USER> system_u:object_r:cifs_t:s0 … /mnt/home`。外れた（同書のロールバックの手順 3 の `rmdir` が通った） |
| /home の節の手順 4 | `0`。`[homes]` と `[root]` は残り、smb.conf の末尾に空行が 1 つ残る |
| ロールバックの手順 1〜3 | `semodule -l` に `samba_root_home` が無く、パッケージも消えた |

- その日の AVC は、`/home` の直下に作ろうとした 7 件だけだった（samba-client.md の手順 5 の `cifs-test.txt` が 4 件、手順書の外の 3 件）

手順書の外の確かめ（`<USER>` と 2 人目の資格情報ファイルで `smbclient` を使った。2 人目は確かめの間だけ Samba に登録した）:

```
$ smbclient //localhost/home -A <USER の資格情報ファイル> -c 'put /etc/hostname <2 人目>/smb-x.txt; mkdir <2 人目>/smb-d; put /etc/hostname <2 人目>/smb-d/y.txt; put /tmp/new.txt <2 人目>/tmp.txt; rename <2 人目>/tmp.txt <2 人目>/keep.txt -f; get <2 人目>/.bashrc /tmp/<2 人目>.bashrc'
…
$ sudo ls -ldZ /home/<2 人目>/smb-x.txt /home/<2 人目>/smb-d /home/<2 人目>/smb-d/y.txt /home/<2 人目>/keep.txt
-rw-r--r--. 1 <2 人目> root system_u:object_r:user_home_t:s0  4 Oct  5 09:01 /home/<2 人目>/keep.txt
drwxr-xr-x. 2 <2 人目> root system_u:object_r:user_home_t:s0 19 Oct  5 09:01 /home/<2 人目>/smb-d
-rw-r--r--. 1 <2 人目> root system_u:object_r:user_home_t:s0  6 Oct  5 09:01 /home/<2 人目>/smb-d/y.txt
-rw-r--r--. 1 <2 人目> root system_u:object_r:user_home_t:s0  6 Oct  5 09:01 /home/<2 人目>/smb-x.txt
$ smbclient //localhost/home -A <USER の資格情報ファイル> -c 'put /etc/hostname top.txt; mkdir topdir'
NT_STATUS_ACCESS_DENIED opening remote file \top.txt
NT_STATUS_ACCESS_DENIED making remote directory \topdir
$ sudo ausearch -m AVC -ts recent
… avc:  denied  { create } for  pid=… comm="smbd[127.0.0.1]" name="top.txt" … scontext=system_u:system_r:smbd_t:s0 tcontext=system_u:object_r:home_root_t:s0 tclass=file permissive=0
… avc:  denied  { create } for  pid=… comm="smbd[127.0.0.1]" name=".::TMPNAME:D:…:topdir" … scontext=system_u:system_r:smbd_t:s0 tcontext=system_u:object_r:user_home_dir_t:s0 tclass=dir permissive=0
$ smbclient //localhost/home -A <2 人目の資格情報ファイル> -c 'ls'
tree connect failed: NT_STATUS_ACCESS_DENIED
$ sudo smbstatus                                     # mount.cifs で //127.0.0.1/home をマウントしている間
…
PID     Username     Group        Machine                                   Protocol Version  Encryption           Signing
…       <USER>       <USER>       127.0.0.1 (ipv4:127.0.0.1:…)              SMB3_11           -                    partial(AES-128-CMAC)

Service      pid     Machine       Connected at                     Encryption   Signing
IPC$         …       127.0.0.1     Mon Oct  5 09:01:43 AM 2026 UTC  -            -
home         …       127.0.0.1     Mon Oct  5 09:01:43 AM 2026 UTC  -            -
```

- `keep.txt` は、2 人目が `-rw-r--r--. 1 <2 人目> <2 人目>` で作ったもの。上書きの後は中身が `new` で、所有者は 2 人目のまま（グループは `root` に変わった）
- `smbclient -L` の一覧は、どちらのユーザーでも自分の共有と `IPC$` だけ（`home` は出ない）
- /home の節の手順 4 で戻した後の `smbclient //localhost/home` は、`tree connect failed: NT_STATUS_BAD_NETWORK_NAME`

#### 未確認事項（/home の節）

- 実機（Raspberry Pi の拠点 B のホスト）での実行
- Windows・macOS などのクライアントから `home` の共有につなぐこと（Windows のエクスプローラーで、`/home` の直下に作ろうとしたときの表示も）
- samba-client.md の自動マウント（手順 6・7）を `SHARE=home` で行うこと
- `/home/linuxbrew` のような、ユーザーのホームでないディレクトリの読み書き（ラベルを `matchpathcon` で見ただけ）

### 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation の ISO からインストールした VirtualBox の VM（x86_64、カーネル `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active、日本語ロケール）で、現行の手順 1〜8・root と /home の任意節・サーバーでの確認 1〜10 を、一般ユーザーの SSH PTY にブラケットペースト無しで貼った。共有するユーザーとパスワードは検証専用のもの。

- Samba は `4.23.5-110.el10_2`。Workstation には `samba-common` と `cifs-utils 7.7` が初めから入っていたが、サーバーと `smbclient` は手順 2 で入った
- VM に NAT と隔離 LAN の NIC があるため、案内用の `SERVER_IP` だけを隔離 LAN の IP に直した。自動検出では NAT の IP が入る
- `testparm` は `Loaded services file OK`、`smb3 directory leases = No`。445/tcp のみで待ち受け、ホームの boolean は on
- `smbclient` とカーネルの CIFS で、通常のホームと root の読み書き・取り出し・比較・削除・アンマウントが通った。SMB は 3.1.1、作成したホームのファイルは `user_home_t`、root のファイルは `root root` の `admin_home_t`
- /home のサーバー上の確認はユーザーのホームの下への書き込みが通り、所有者はそのユーザー、グループは root。共有直下への書き込みは許可しない設計のまま
- 別の AlmaLinux 10 Workstation VM から、同じ資格情報で `SHARE=root` と `SHARE=home` の手でのマウントも通った。home の共有直下への書き込みは予告どおり `Permission denied` になり、その下の自分のホームには読み書きできた
- 接続元を隔離 LAN の帯に絞り、別 VM から 445/tcp が通り、許可帯外の network namespace からは拒否されることを確認した
- テスト用の長いホスト名では `testparm` が NetBIOS 名の長さを警告した。IP アドレスでの接続には支障が見えなかった

サーバーを再起動し、smb.service は OS の起動時刻 04:15:10 の後、04:15:56 に active になった。SSH の再ログイン 04:16:18 より前で、相手 VM の再起動後も CIFS のアクセスと読み書きが通った。

接続元制限の解除、home の解除 4、root の解除 5、ディレクトリのリース設定の解除 3 → 再設定 1・2、ロールバック 1・3 を通した。共有の解除の `grep -c` は `0` と終了 1（該当なし）になった。Samba のサービス・445/tcp・Samba ユーザー・root の CIL モジュールが外れ、ホームの boolean は off、smb.conf は開始時の控えと一致した。Samba と smbclient を消し、開始時から入っていた samba-common と cifs-utils は残した。パスワード DB ファイルとログの「完全に消すなら」の追加削除は行っていない。

別の Workstation VM の GNOME Files から GUI でも接続・ファイル作成とコピー・F5・切断を通し、サーバーの実体と内容が一致した（[クライアント側の記録](samba-client.md#付録-クリーンインストールした-vm-同士での検証2026-10-06)）。

Windows の接続、キーリング、物理 NIC、実ルーター越しの動作は今回の検証に含めていない。

### 付録: 新規 VM での現行手順の再検証（2026-10-06）

同日の先行検証に使った VM と分け、ISO 導入直後の AlmaLinux 10.2 Workstation から新しい x86_64 VM を用意して、`5da3478` の現行本文を再検証した。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active。一般ユーザーの SSH PTY にブラケットペースト無しで貼り、手順ごとに結果を確認した。

新しいサーバー VM で手順 1〜8、root のホーム 1〜3、/home の公開 1・2、サーバー上の動作確認 1〜10 を通した。Samba は `4.23.5-110.el10_2`。サーバー自身の smbclient と CIFS、相手 VM の手動・自動 CIFS マウントで読み書きでき、SMB 3.1.1、SELinux Enforcing のまま AVC は無かった。共有 root のファイルは root/root の admin_home_t、home のホーム内のファイルは所有者の user_home_t だった。home の共有直下への書き込みは Permission denied になった。

別の新規 VM を Road Warrior にし、A のトンネル IP への手動 CIFS マウントでもファイルを作成・読み戻し・削除できた。WireGuard の経路を確認している。root/home 共有を WireGuard 越しに使うことと、WireGuard 越しの fstab 自動マウントは含めていない。

接続元制限 1 は検証用 LAN のみに絞り、LAN の相手から 445/tcp に到達し、許可帯外の WG クライアントは拒否された。解除 2 も成功した。OS 再起動後、smb.service は 14:00:54 JST、SSH セッションは 14:00:57 で、再ログイン前に active になった。相手の CIFS 自動マウントと読み書きも戻った。

新規のデスクトップ VM の GNOME Files で Network → Server address から認証し、Ctrl+C/Ctrl+V で共有へコピーした。サーバーの実体と内容が一致した。サーバーで別ファイルを作ると F5 前は見えず、F5 後に現れ、内容も一致した。取り出し後はサイドバー・GIO・GVFS から消えた。キーリング保存は選んでいない。

home の解除 4、root の解除 5、既存サーバーのディレクトリリース節 3・1・2、ロールバック 1・3 を通した。ゼロ件の grep が終了 1 を返す箇所は、表示 0 という確認の想定どおりだった。smb は停止・disabled、445 の開放無し、boolean は off、root のモジュール無し、smb.conf は orig と一致。パッケージ解除は本文の指示で既設 cifs-utils を除外し、新規 samba/samba-client を削除した。実機、macOS/iOS/Android、今回の VM で Windows のクライアントから使うことは確認していない。


### 操作上の注意と併記されていた記録

   - `semodule -i` は、終わるまでしばらく何も出さない（VM では約 50 秒）


### 操作上の注意と併記されていた記録

   - `libsemanage.semanage_direct_remove_key: Removing last samba_root_home module …` の 1 行が出て終わればよい（VM では約 50 秒）


### サーバーの上で動作を確かめる / 手順 8: 補足: 作ったファイル

- SMB から `/root` に作ったものは、名前にかかわらず `admin_home_t` になる。VM では、SMB で作った `/root/.config` も `admin_home_t` だった（ローカルで作れば `config_home_t`）
- ほかのプログラムがラベルで困ったら、`sudo restorecon -Rv /root/.config` のように既定のラベルに戻す（VM では `config_home_t` に戻り、その後も SMB から読み書きできた）
- 既にラベルの付いたディレクトリの中に作ったものは、そのディレクトリのラベルになる（VM では、`/root/.ssh` に作ったファイルは `ssh_home_t`）
- `-ts recent` は直近 10 分。この節の手順 7 から時間がたったときは `-ts today` にする


### 手順中の実測・検証範囲

- サーバーで変えたファイルやディレクトリは、F5 を押さなくても出る（手順 3 の `smb3 directory leases = no`。実機で確認）

### 手順中の実測・検証範囲

1. 別のマシンから、共有名 `root` でつなぐ（AlmaLinux 10 の VM で検証。Windows は未検証）。

### 手順中の実測・検証範囲

1. 別のマシンから、共有名 `home` でつなぐ（AlmaLinux 10 の VM で検証。Windows は未検証）。

### 手順中の実測・検証範囲

- Windows のエクスプローラーは、次の F5 でつなぎ直す（実機では資格情報を聞かれなかった）

### 手順中の実測・検証範囲

- Windows は、ディレクトリのリースが無いときも、一覧を最長 10 秒キャッシュする（Microsoft の文書の `DirectoryCacheLifetime`）。実機では、サーバーで変えたものはエクスプローラーに自動で出た

## 参考資料から分離した記録

### 参考資料: 実施手順 / 手順 2: 補足: パッケージ

- `samba`（baseos）が smbd 本体。依存で `samba-common-tools`（`smbpasswd` / `pdbedit` / `testparm` / `smbstatus`）、`samba-libs`、`samba-dcerpc` などが入る
- `samba-client`（`smbclient`）と `cifs-utils`（`mount.cifs`）は、[サーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の検証にしか使わない。サーバー上で検証しないなら入れなくてよい
- インストール直後は `smb.service` / `nmb.service` とも `disabled` / `inactive`

### 参考資料: 実施手順 / 手順 5: 補足: firewalld

- 445/tcp は public ゾーンの全 NIC で開く。この環境では `end0`（LAN）と `wg0`（VPN）
- 自ホストからの `smbclient //localhost/...` や `//${SERVER_IP}/...` は `lo` を通るため、**firewalld の設定を通らない**（`filter_INPUT` の `iifname "lo" accept` で先に受理される）
- 開け忘れはサーバー上の検証では見つからない。[付録](../verification/samba.md#network-namespace-から-firewalld-越しに到達する)

### 参考資料: root のホームも公開する（任意） / 手順 1: 補足: [root] の各行

- `path = /root`: `[homes]` と違い、共有の場所を書く普通の共有
- `valid users = ${USER}`: 入れるのは `<USER>` だけ。ほかの Samba ユーザーは、認証が通っても `tree connect failed: NT_STATUS_ACCESS_DENIED`（VM で確認）
- `force user = root`: つないだ後のファイル操作を root として行う。`/root` は `dr-xr-x---`（0550）だが、root として扱うので書ける（smbd の SELinux のドメイン `smbd_t` は `dac_override` を持つ）
- `browseable = No`: 共有の一覧（`smbclient -L`）に出さない。つなぐときは共有名 `root` を直接指定する
- `create mask = 0644`: `[homes]` と同じ理由（[smb.conf の各行の根拠](../reference/samba.md#smbconf-の各行の根拠)）
- root は OS のユーザーなので、`[homes]` も `root` という名前の共有を出そうとする。同じ名前の節があれば、そちらが使われる（VM では、`[root]` を消すと `<USER>` の接続が `[homes]` の `valid users = %S` で断られた）
- ヒアドキュメントは `${USER}` を展開するので、引用符なしの `<<EOF`。先頭の空行は、手順 3 の `[homes]` との区切り

### 参考資料: root のホームも公開する（任意） / 手順 2: 補足: モジュールが要る理由

- 手順 4 の `samba_enable_home_dirs` が smbd に許すのは、一般ユーザーのホームのラベル（属性 `user_home_type`）だけ。`/root` とその中のファイルは `admin_home_t` で、この属性に入っていない（`seinfo -t admin_home_t -x`）
- そこで、boolean が `user_home_type` の dir / file / lnk_file に許すのと同じ許可を、`admin_home_t` に足す（VM の `sesearch -A -s smbd_t -t ssh_home_t` で見た許可の並び）
- `/root/.ssh`（`ssh_home_t`）や `/root/.config`（`config_home_t`）は `user_home_type` なので、手順 4 の boolean で既に許されている
- CIL は `semodule -i` がそのまま読むので、`checkpolicy`（`checkmodule`）などを入れなくてよい。入れたモジュールは優先度 400 に置かれる（`semodule -lfull` の `400 samba_root_home cil`）
- モジュールを入れずに `[root]` へつないだときの表示（VM で確認）:
  - `ls` は `NT_STATUS_ACCESS_DENIED listing \*`。**AVC は出ない**（`admin_home_t` のディレクトリの読み取りは dontaudit されている）
  - ファイルの取得は `NT_STATUS_ACCESS_DENIED opening remote file \.bashrc` で、AVC は `denied { getattr } … tcontext=system_u:object_r:admin_home_t:s0 tclass=file`
  - 書き込みは `NT_STATUS_ACCESS_DENIED opening remote file \x.txt` で、AVC は `denied { write } … name="root" … tclass=dir`

### 参考資料: root のホームも公開する（任意） / 手順 5: 補足: 元に戻す

- `sed` は、`[root]` の行から次の `[` で始まる行の手前までを消す。`[root]` の後ろに別の節を足していても、その節は残る
- この節の手順 1 で足した先頭の空行は、ファイルの末尾に残る（`testparm` は気にしない）
- 戻した後の `//<SERVER_IP>/root` は、`<USER>` では `tree connect failed: NT_STATUS_ACCESS_DENIED`（`[homes]` の `valid users = %S`）

### 参考資料: サーバーの上で動作を確かめる / 手順 3: 補足: 共有の一覧

- `smbclient -L` に出るのは `IPC$` と `<USER>` の 2 つ。`homes` / `printers` / `print$` は出ない

### 参考資料: サーバーの上で動作を確かめる / 手順 4: 補足: マウントと smbstatus

- `mount.cifs` の既定は SMB 3.1.1（`vers=3.1.1`）。`uid=` / `gid=` を渡さないとマウント側のファイルが root 所有に見える
- マウント側の `ls -Z` は `cifs_t`、サーバー側は `user_home_t`（`user_home_dir_t` 配下の type transition。`restorecon` していないのにこうなる）
- `smbstatus` はサーバー側で「交渉されたプロトコル / 暗号化 / 署名」を表示する。クライアント側では見えにくい情報なので、暗号化の有無を確かめるならここ

### 参考資料: サーバーの上で動作を確かめる / 手順 10: 補足: 作ったファイル

- 所有者が `<USER>` なのは、`[home]` の `inherit owner = yes` で、親ディレクトリ（`/home/<USER>`）の所有者になったため。ほかのユーザーのホームに作ったものは、そのユーザーの所有になる（VM で確認）
- グループが `root` なのは、smbd が root として作るため（`inherit owner` はグループを変えない）。持ち主はそのまま読み書きできる
- `-ts recent` は直近 10 分。この節の手順 9 から時間がたったときは `-ts today` にする

### 参考資料: root のホームを公開するときの補足

- **公開されるのは `/root` の全体**
  - `/root` と、その中の `admin_home_t` のファイル・ディレクトリは、[root のホームも公開する](../samba.md#root-のホームも公開する任意)の手順 2 のモジュールで許す
  - `.ssh`（`ssh_home_t`）・`.gnupg`（`gpg_secret_t`）・`.config`（`config_home_t`）などは、一般ユーザーのホームと同じ `user_home_type` のラベルなので、手順 4 の boolean で既に許されている
  - VM では、SMB から `/root/.ssh/authorized_keys` を取得でき、`/root/.ssh` へのファイルの書き込みと `/root/.bashrc` の書き換えも通った（AVC は出ない）
- **入るのは `<USER>`**: `pdbedit -L` は `<USER>` の 1 行のまま（root は出ない）。`smbstatus` では、Username が `<USER>`、Service が `root` になる
- **クライアントでの見え方**: [samba-client.md](../samba-client.md) の `mount.cifs` は `uid=` / `gid=` で自分の所有に見せるが、サーバーでは `root root` で書かれる
- **以前に `smbpasswd -a root` で root を登録していたら**: VM では、`sudo smbpasswd -x root` は `Failed to delete entry for user root.` で消せず、`sudo pdbedit -x -u root` で消えた
