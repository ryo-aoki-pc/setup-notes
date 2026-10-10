# Samba の共有を AlmaLinux 10 と Windows 11 から使う手順（cifs-utils + fstab の自動マウント / GNOME Files / Windows のネットワーク ドライブ）の参考資料

[手順書](../samba-client.md)・[ロールバックと注意点](../extra/samba-client.md)

[検証記録](../verification/samba-client.md#参考資料から分離した記録)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- `SMB_USER` を `USER`（この PC のユーザー名）と分けてあるのは、NAS や Windows ではサーバー側のアカウント名が違うことがあるため
- samba.md のサーバーは OS のアカウント名で Samba ユーザーを登録するので、この PC と同じ名前なら既定のままでよい
- samba.md の `[homes]` は、Samba ユーザーと同じ名前の共有を見せる。ほかの共有につなぐなら `SHARE` を書き換える
- samba.md の `[root]` は、自分の Samba ユーザーのまま入る共有。`SHARE=root` だけを変えれば、資格情報ファイル（手順 4）は自分の共有と同じものになり、マウント先は `/mnt/root` になる
- samba.md の `[home]` も同じで、`SHARE=home` だけを変える。マウント先は `/mnt/home` になり、その下にユーザーごとのディレクトリが並ぶ
- `SERVER` に NetBIOS 名は使えない。samba.md のサーバーは NetBIOS（nmbd）を動かさない。IP アドレスか、DNS（または `/etc/hosts`）で引ける名前にする
- `SMB_USER`・`SHARE`・`MOUNT_POINT` に空白を入れない。fstab の欄は空白で区切るので、手順 6 で中断する

### GNOME Files で開く（任意） / 手順 1: 補足: パッケージ

- `gvfs-smb` が gvfs の SMB のバックエンド（libsmbclient を使う）、`gvfs-fuse` が GIO を使わないアプリ向けの `/run/user/<UID>/gvfs/`
- どちらも GNOME のグループ（`gnome-desktop`）の必須パッケージなので、Workstation にも Server with GUI にも入っている

### ロールバック / 手順 1: 補足: 2 つのユニットを止める理由

- `.automount` と `.mount` を一緒に止めると、`cifs` と `autofs` の両方が外れる
- `.mount` だけを止めると、`Stopping 'mnt-<SHARE>.mount', but its triggering units are still active: mnt-<SHARE>.automount` と出て、次のアクセスでまたマウントされる
- `MOUNT_POINT` が空のまま `$(systemd-escape …)` を使うと、ユニットの名前が `-.mount`（ルートのファイルシステム）になる。先頭の `if` はこれを防ぐ

### ロールバック / 手順 2: 補足: 行の消し方

- 行は awk で、2 列目（マウント先）と 3 列目（`cifs`）を文字列として比べて消す。sed の正規表現だと、IP アドレスのドットなどが特別な意味を持つ
- `tee` で書き戻すので、`/etc/fstab` のモード（0644）とラベル（`etc_t`）は変わらない

### Windows 11 で使う / 手順 1: 補足: 管理者ではない窓で割り当てる理由

- UAC が有効な Windows では、Administrators の一員がサインインすると、昇格したものとしないものの 2 つのログオン セッションができる。ドライブの割り当ては、作った側のセッションにだけある（Microsoft の文書）
- エクスプローラーは昇格しない側で動くので、管理者の窓（`sudo` を含む）で割り当てたドライブは、エクスプローラーにも、管理者ではない窓にも出ない
- 管理者の窓からも見えるようにするレジストリの値（`EnableLinkedConnections`）は、PC 全体の設定を足すことになるので採らない。管理者の窓では UNC パスを使う（[注意点](../extra/samba-client.md#注意点)）

### Windows 11 で使う / 手順 2: 補足: 変数について

- `SMB_USER` は、AlmaLinux 10 の節と違って必須にした。Windows のユーザー名（Microsoft アカウントなら `C:\Users\` の下のフォルダーの名前）は、サーバーの OS のユーザー名と違うことが多いため
- `SHARE` の既定が `SMB_USER` なのは、samba.md の `[homes]` が Samba ユーザーと同じ名前の共有を見せるため（[実施手順の手順 1 の補足](#実施手順--手順-1-補足-変数について)と同じ）
- `SERVER` に NetBIOS 名は使えない（samba.md のサーバーは nmbd を動かさない）。IP アドレスか、DNS で引ける名前にする

### Windows 11 で使う / 手順 4: 補足: 資格情報マネージャーに置く

- `cmdkey /add:<SERVER> /user:<SMB_USER> /pass` は、`<SERVER>` を宛先にした Windows の資格情報（資格情報マネージャーの「Windows 資格情報」）を作る。`/pass` に値を書かなければ、`cmdkey` がパスワードを聞く（Microsoft の文書）
- パスワードをコマンドラインに書かないのは、ほかのプロセスから見え、PowerShell の履歴にも残るため（[samba.md のサーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の手順 2 と同じ考え）
- この節の手順 5 の `New-SmbMapping` に資格情報を渡さないと、Windows はこの資格情報でつなぐ（Microsoft の Azure Files の文書も、`cmdkey /add` の後に資格情報を渡さずに割り当てている）
- 資格情報はこのユーザーのものなので、ほかのユーザーには使われない。サインインし直しても残る

### Windows 11 で使う / 手順 5: 補足: New-SmbMapping と、エクスプローラーの表示

- `-Persistent $true` で、割り当てをこのユーザーのプロファイルに覚えさせ、サインインのたびにつなぎ直させる
- 成功は、`Get-SmbMapping` の `Status` が `OK` で判断する。Microsoft のコミュニティには、Windows 11 で `New-SmbMapping` のドライブがエクスプローラーを起動し直す（かサインインし直す）まで出ないという報告があるので、エクスプローラーでの確かめはこの節の手順 8 のサインインし直した後にした
- 前に割り当てて、切れたまま覚えているドライブ文字（`Status` が `Unavailable` など）には割り当てられない（`ERROR_DEVICE_ALREADY_REMEMBERED`）。この節の手順 3 は、そのドライブ文字も `Get-SmbMapping` で見つけて止める

### Windows 11 で使う / 手順 7: 補足: 署名と、サーバーの設定を変えない理由

- Windows 11 24H2 の Pro・Enterprise・Education は、SMB の署名を、送る側（クライアント）と受ける側（サーバー）の両方で必ず求める。Home は、どちらも求めない（Microsoft の文書）
- samba.md のサーバーは `server signing` を書いておらず、既定の `default` のまま。SMB2 以降では署名を止められず、クライアントが求めれば署名する（smb.conf(5)）。そのため Pro の PC からの接続は署名され、サーバーもクライアントも設定を変えずにつながる
- `smbstatus` の `Signing` の欄は、全体に署名した接続なら方式の名前（`AES-128-GMAC` など）だけ、一部だけなら `partial(<方式>)`、無ければ `-`（Samba 4.23.5 のソース）。署名を求めない AlmaLinux 10 の cifs の接続は `partial(AES-128-CMAC)` だった
- Pro は、ゲスト（認証しない接続）も既定で断る。samba.md のサーバーはユーザーとパスワードで認証し、`map to guest` は既定の `Never`（ゲストにしない）なので、当たらない

### Windows 11 のロールバック / 手順 1: 補足: 外すものと残るもの

- `-UpdateProfile` で、プロファイルに覚えた割り当ても消し、次のサインインでつなぎ直さないようにする（Microsoft の文書）。覚えた割り当ての置き場所の `HKCU:\Network\<ドライブ文字>` が消えたかで確かめる
- 資格情報は、この節の手順 2 で別に消す。同じサーバーのほかの割り当てが同じ資格情報でつなぐので、消すかどうかを分けた

### 選択した方針

- **`x-systemd.automount` で、アクセスしたときにマウントする**
  - 起動時にはマウントしないので、サーバーが止まっていても起動は待たない
  - `x-systemd.idle-timeout=1min` で、使わなくなった共有は約 1 分で外れる。PC を LAN の外へ持ち出したときに、届かないマウントが残りにくい
  - systemd のユニット（`.mount` / `.automount`）を自分で書く方法もあるが、fstab の 1 行から `systemd-fstab-generator` が同じ 2 つを作るので、fstab にした
- **資格情報は `/root/smb-<SMB_USER>@<SERVER>.cred`（root の 0600）に置く**
  - RHEL 10 の文書（`/root/smb.cred`）と同じ場所。名前にユーザーとサーバーを入れて、複数の共有を並べられるようにした
  - マウントするのは root（systemd か `sudo mount`）なので、root が読めればよい。自分のホームには置かない
  - fstab に `password=` を書かない。fstab は誰でも読める（0644）
  - SELinux: systemd から呼ばれた mount.cifs は `mount_t` で動く。EL10 のポリシーでは `mount_t` が制限の無いドメイン（`unconfined_domain_type`）なので、置き場所のファイルの型を選ばない
- **マウントのオプションは `credentials=`・`uid=`・`gid=`・`file_mode=0600`・`dir_mode=0700` だけにした**
  - `uid=` / `gid=`: 無いと、マウントした側のファイルが root の所有に見える（[samba.md のサーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の手順 4 の補足）
  - `file_mode=0600` / `dir_mode=0700`: 既定の 0755 のままだと、この PC のほかのユーザーからも読める。
  - このモードはこの PC での見え方だけで、サーバー側のファイルのモードはサーバーの `create mask`（0644）で決まる
  - `vers=` は書かない。既定でサーバーの最も新しい版を使う
- **`_netdev` と `nofail` は付けない**
  - `_netdev`: systemd は cifs をネットワークのファイルシステムとして扱い、生成した `.mount` に `After=network-online.target` などを付ける。mount.cifs も `_netdev` を無視する（cifs-utils 7.7 のソース）
  - `nofail`: 起動時に要るのは `.automount` だけで、これはサーバーに依存しない。`nofail` が無いので `remote-fs.target` が `.automount` を Requires にする
  - mount.cifs は `nofail` があると、サーバーに届かないときも終了コード 0 で終わる（cifs-utils 7.7 のソース）。手でマウントしたときの失敗が分かりにくくなる
- **クライアントの firewalld は変えない**
  - 出ていく 445/tcp だけなので、開けるものは無い
  - firewalld の `samba-client` サービス（137/138/udp。NetBIOS の名前引きと一覧）は要らない。samba.md のサーバーは NetBIOS を使わない
- **暗号化（`seal`）は使わない**: LAN 上の通信は署名だけ。samba.md の方針と同じ
- **GNOME Files（gvfs）は任意節にした**
  - fstab のマウントとは別の仕組みで、ログインしたユーザーの gvfsd が libsmbclient でつなぐ。root も資格情報ファイルも要らない
  - つながるのはログインしている間だけ。GIO を使わないアプリからは `/run/user/<UID>/gvfs/` の下に見える
- **Windows 11 では、資格情報マネージャー（`cmdkey`）と `New-SmbMapping -Persistent $true` で、ドライブ文字に割り当てる**
  - パスワードは、`cmdkey` が聞いて資格情報マネージャーに置く。コマンドラインにも、PowerShell の履歴にも残らない
  - 窓は管理者ではない Windows PowerShell 5.1（[Windows 11 で使うの手順 1 の補足](#windows-11-で使う--手順-1-補足-管理者ではない窓で割り当てる理由)）。PowerShell 7 でも `SmbShare` のモジュールは使えるはずだが、ほかの Windows の手順書に合わせて 5.1 にした
  - 採らなかった割り当て方
    - `net use <ドライブ>: \\<SERVER>\<SHARE> /savecred /persistent:yes`: `/savecred` は `/user` と一緒に使えない（Microsoft の Windows Server 2003 の文書）。今の Microsoft Learn の `net use` のページは 404 で、Windows Server 2012 R2 の版しか読めなかった
    - `New-SmbMapping -UserName <SMB_USER> -Password <パスワード>`: パスワードをコマンドラインに書くことになる。`-Credential` は windowsserver2025-ps の版の文書にだけあり、Windows 11 の SmbShare にあるかを確かめていない
    - `New-PSDrive -Persist -Scope Global`: Microsoft の Azure Files の文書は `cmdkey /add` の後にこれで割り当てている。コミュニティの報告では、エクスプローラーにすぐ出る。本書は、`Get-SmbMapping` の `Status` で成功を見られ、`Remove-SmbMapping -UpdateProfile` で外せる `New-SmbMapping` にした。エクスプローラーにすぐ出ないときの代わりの候補として、実機で比べる
  - 採らなかった設定
    - `EnableLinkedConnections`（管理者の窓にも割り当てたドライブを見せる。PC 全体の値で、再起動が要る）
    - `RestoreConnection`（サインインのときにつなぎ直さず、つなぎ直せなかった通知も出さない。Microsoft Learn に文書が無く、ほかの割り当てにも効く）
- **Windows 11 の SMB の署名とゲストのために、サーバー（samba.md）もクライアントも設定を変えない**
  - Pro・Enterprise・Education の 24H2 は署名を必ず求め、ゲストを断る。samba.md のサーバーは、既定のまま署名に応じ、ゲストにしないので、そのままつながる
  - クライアントの `RequireSecuritySignature` を `$false` に、`EnableInsecureGuestLogons` を `$true` にする回避策は使わない（Microsoft も勧めていない）
  - Home は署名を求めないので、Home からの接続は全体には署名されない。Home でも署名させるなら、サーバーの `[global]` に `server signing = mandatory` を足す方法がある（本書の範囲外。samba.md の手順 3 は貼り直さない）
  - Microsoft は、署名のために IP アドレスでつながないよう勧めている（Kerberos のため）。samba.md のサーバーは standalone で NTLMv2 だけなので、本書は IP アドレスでもよいとした
- **SMB の NTLM のブロックは、入れない前提**
  - Windows 11 24H2 から、SMB のクライアントで NTLM をブロックできる（`Set-SmbClientConfiguration -BlockNTLM $true` か、グループ ポリシーの「コンピューターの構成\管理用テンプレート\ネットワーク\Lanman ワークステーション」の「Block NTLM (LM, NTLM, NTLMv2)」）。既定では入っていない
  - samba.md のサーバーは Kerberos を使わないので、入れると割り当てられなくなる。入れるなら、同じ場所の「Block NTLM Server Exception List」に `<SERVER>` を足す（作るのに相当する PowerShell は無い。値は `HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation` の `BlockNTLMServerExceptionList`）
  - `New-SmbMapping` に `-BlockNTLM $true` を付けない

### 参照

- [Chapter 5. Mounting an SMB Share — Managing file systems (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/managing_file_systems/mounting-an-smb-share)（資格情報ファイル、fstab の例、よく使うオプション）
- [Chapter 10. Browsing files on a network share — Using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_the_gnome_desktop_environment/browsing-files-on-a-network-share)
- [Chapter 6. Managing storage volumes in GNOME — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/managing-storage-volumes-in-gnome)（GIO と、`gvfs-fuse` の `/run/user/UID/gvfs/`）
- `man mount.cifs`（`credentials=`、`uid=`、`file_mode=`、`soft`、`echo_interval`、`actimeo`、`nohandlecache`、`max_cached_dirs`）/ `modinfo cifs`（`dir_cache_timeout`）
- `man systemd.mount`（`x-systemd.automount`、`x-systemd.idle-timeout`、`nofail`、`_netdev`）/ `man systemd-fstab-generator`
- `man findmnt`（`--verify`）/ `man gio`
- cifs-utils 7.7 のソース（`mount.cifs.c` の `open_cred_file`・`parse_cred_line`・`set_password`・`parse_opt_token`）
- [Samba でホームディレクトリを公開する手順](../samba.md)（サーバー側）
- [Control SMB signing behavior — Windows Server (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/storage/file-server/smb-signing)（24H2 の版ごとの署名の要求、ゲストの禁止）
- [Block NTLM connections on SMB — Windows Server (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/storage/file-server/smb-ntlm-blocking)
- [cmdkey (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/cmdkey) / [New-SmbMapping](https://learn.microsoft.com/en-us/powershell/module/smbshare/new-smbmapping?view=windowsserver2025-ps) / [Remove-SmbMapping](https://learn.microsoft.com/en-us/powershell/module/smbshare/remove-smbmapping?view=windowsserver2025-ps)
- [Mapped drives aren't available from an elevated command prompt (Microsoft Learn)](https://learn.microsoft.com/en-us/troubleshoot/windows-client/networking/mapped-drives-not-available-from-elevated-command) / [Mapped network drive may fail to reconnect (Microsoft Learn)](https://learn.microsoft.com/en-us/troubleshoot/windows-client/networking/mapped-network-drive-fail-reconnect)
- [Mount SMB Azure file share on Windows (Microsoft Learn)](https://learn.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-windows)（`cmdkey /add` の後に資格情報を渡さずに割り当てる例）
- `man smb.conf`（`server signing`、`map to guest`、`ntlm auth`）/ Samba 4.23.5 の `source3/utils/status.c`（`smbstatus` の `Signing` の表示）

---
