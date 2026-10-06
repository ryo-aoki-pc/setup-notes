# Samba の共有を AlmaLinux 10 から使う手順（cifs-utils + fstab の自動マウント / GNOME Files）の参考資料

[手順書](../samba-client.md)

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

### 参照

- [Chapter 5. Mounting an SMB Share — Managing file systems (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/managing_file_systems/mounting-an-smb-share)（資格情報ファイル、fstab の例、よく使うオプション）
- [Chapter 10. Browsing files on a network share — Using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_the_gnome_desktop_environment/browsing-files-on-a-network-share)
- [Chapter 6. Managing storage volumes in GNOME — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/managing-storage-volumes-in-gnome)（GIO と、`gvfs-fuse` の `/run/user/UID/gvfs/`）
- `man mount.cifs`（`credentials=`、`uid=`、`file_mode=`、`soft`、`echo_interval`、`actimeo`、`nohandlecache`、`max_cached_dirs`）/ `modinfo cifs`（`dir_cache_timeout`）
- `man systemd.mount`（`x-systemd.automount`、`x-systemd.idle-timeout`、`nofail`、`_netdev`）/ `man systemd-fstab-generator`
- `man findmnt`（`--verify`）/ `man gio`
- cifs-utils 7.7 のソース（`mount.cifs.c` の `open_cred_file`・`parse_cred_line`・`set_password`・`parse_opt_token`）
- [Samba でホームディレクトリを公開する手順](../samba.md)（サーバー側）

---
