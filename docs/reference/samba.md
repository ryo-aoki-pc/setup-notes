# Samba でホームディレクトリを公開する手順（`[homes]` 共有 / smbd + firewalld）の参考資料

[手順書](../samba.md)・[ロールバックと注意点](../extra/samba.md)

[検証記録](../verification/samba.md#参考資料から分離した記録)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- `SERVER_IP` を自動取得にしているのは、設定には使わず検証と案内にしか使わないため（GNOME Remote Desktop の手順書で手入力なのは、値が証明書の SAN に入るから）
- `SERVER_IP` が間違っていても、[サーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の手順 3 の `smbclient "//${SERVER_IP}/..."` が失敗するだけで、設定は壊れない
- 公開するのは `${USER}`（このシェルのユーザー）のホーム。`sudo -i` した root のシェルでは `root` になり、手順 6 で root のホームを公開してしまうので、読み戻しで必ず確認する
- root のシェルで進めると、root の Samba ユーザーができるうえ、`/root` のラベル（`admin_home_t`）は手順 4 の boolean の対象外なので、[サーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の手順 3 の `ls` も通らない。root のホームは、自分のユーザーのまま入れる `[root]` 共有で足す（[root のホームも公開する（任意）](../samba.md#root-のホームも公開する任意)）
- `ALLOW_FROM` は[接続元を絞る](../samba.md#接続元を絞る任意)でしか使わないので、手順 1 ではなくその節の冒頭で設定する

### 実施手順 / 手順 2: 補足: パッケージ

- `samba`（baseos）が smbd 本体。依存で `samba-common-tools`（`smbpasswd` / `pdbedit` / `testparm` / `smbstatus`）、`samba-libs`、`samba-dcerpc` などが入る
- `samba-client`（`smbclient`）と `cifs-utils`（`mount.cifs`）は、[サーバーの上で動作を確かめる](../samba.md#サーバーの上で動作を確かめる)の検証にしか使わない。サーバー上で検証しないなら入れなくてよい

### 実施手順 / 手順 5: 補足: firewalld

- 445/tcp は public ゾーンの全 NIC で開く
- 自ホストからの `smbclient //localhost/...` や `//${SERVER_IP}/...` は `lo` を通るため、**firewalld の設定を通らない**（`filter_INPUT` の `iifname "lo" accept` で先に受理される）
- 開け忘れはサーバー上の検証では見つからない。[付録](../verification/samba.md#network-namespace-から-firewalld-越しに到達する)

### 実施手順 / 手順 8: 補足: サービス

- `smb.service` は `nmb.service` を `Requires` / `Wants` していない（`After=` に並ぶだけ）。nmb を起動しなくても単独で動く
- 起動すると `/var/log/samba/` に `log.smbd` と `log.rpcd_*`（`samba-dcerpcd` が起動する RPC ヘルパーのログ）ができる。`cups` 無しでも、本手順の `smb.conf` なら CUPS 関連のエラーは出ない

### root のホームも公開する（任意） / 手順 1: 補足: [root] の各行

- `path = /root`: `[homes]` と違い、共有の場所を書く普通の共有
- `valid users = ${USER}`: 入れるのは `<USER>` だけ。ほかの Samba ユーザーは、認証が通っても共有には入れない
- `force user = root`: つないだ後のファイル操作を root として行う。`/root` は `dr-xr-x---`（0550）だが、root として扱うので書ける（smbd の SELinux のドメイン `smbd_t` は `dac_override` を持つ）
- `browseable = No`: 共有の一覧（`smbclient -L`）に出さない。つなぐときは共有名 `root` を直接指定する
- `create mask = 0644`: `[homes]` と同じ理由（[smb.conf の各行の根拠](#smbconf-の各行の根拠)）
- root は OS のユーザーなので、`[homes]` も `root` という名前の共有を出そうとする。同じ名前の節があれば、そちらが使われる
- ヒアドキュメントは `${USER}` を展開するので、引用符なしの `<<EOF`。先頭の空行は、手順 3 の `[homes]` との区切り

### root のホームも公開する（任意） / 手順 2: 補足: モジュールが要る理由

- 手順 4 の `samba_enable_home_dirs` が smbd に許すのは、一般ユーザーのホームのラベル（属性 `user_home_type`）だけ。`/root` とその中のファイルは `admin_home_t` で、この属性に入っていない（`seinfo -t admin_home_t -x`）
- そこで、boolean が `user_home_type` の dir / file / lnk_file に許すのと同じ許可を、`admin_home_t` に足す
- `/root/.ssh`（`ssh_home_t`）や `/root/.config`（`config_home_t`）は `user_home_type` なので、手順 4 の boolean で既に許されている
- CIL は `semodule -i` がそのまま読むので、`checkpolicy`（`checkmodule`）などを入れなくてよい。入れたモジュールは優先度 400 に置かれる

### root のホームも公開する（任意） / 手順 5: 補足: 元に戻す

- `sed` は、`[root]` の行から次の `[` で始まる行の手前までを消す。`[root]` の後ろに別の節を足していても、その節は残る
- この節の手順 1 で足した先頭の空行は、ファイルの末尾に残る（`testparm` は気にしない）

### サーバーの上で動作を確かめる / 手順 2: 補足: 資格情報ファイル

- パスワードは `-U user%pass` で渡すと `ps` に見える
- `smbclient -A` の資格情報ファイル（`username=` / `password=`）は `mount.cifs -o credentials=` と同じ形式なので、1 つ作って両方に使う
- `/run/user/<uid>/` は tmpfs でユーザー専用（0700）

### サーバーの上で動作を確かめる / 手順 3: 補足: 共有の一覧

[検証記録](../verification/samba.md#参考資料から分離した記録)

### サーバーの上で動作を確かめる / 手順 4: 補足: マウントと smbstatus

- `mount.cifs` の既定は SMB 3.1.1（`vers=3.1.1`）。`uid=` / `gid=` を渡さないとマウント側のファイルが root 所有に見える
- `smbstatus` はサーバー側で「交渉されたプロトコル / 暗号化 / 署名」を表示する。クライアント側では見えにくい情報なので、暗号化の有無を確かめるならここ

### サーバーの上で動作を確かめる / 手順 10: 補足: 作ったファイル

- `[home]` の `inherit owner = yes` で、作るファイルの所有者は親ディレクトリの所有者になる。ほかのユーザーのホームに作ったものは、そのユーザーの所有になる
- smbd が root として作るファイルのグループは `root`（`inherit owner` はグループを変えない）。持ち主はそのまま読み書きできる
- `-ts recent` は直近 10 分。この節の手順 9 から時間がたったときは `-ts today` にする

### 選択した方針

#### smb.conf の各行の根拠

[検証記録](../verification/samba.md#参考資料から分離した記録)

### root のホームを公開するときの補足

- **公開されるのは `/root` の全体**
  - `/root` と、その中の `admin_home_t` のファイル・ディレクトリは、[root のホームも公開する](../samba.md#root-のホームも公開する任意)の手順 2 のモジュールで許す
  - `.ssh`（`ssh_home_t`）・`.gnupg`（`gpg_secret_t`）・`.config`（`config_home_t`）などは、一般ユーザーのホームと同じ `user_home_type` のラベルなので、手順 4 の boolean で既に許されている
- **入るのは `<USER>`**: root の Samba ユーザーは登録しない
- **クライアントでの見え方**: [samba-client.md](../samba-client.md) の `mount.cifs` は `uid=` / `gid=` で自分の所有に見せるが、サーバーでは `root root` で書かれる
- **以前に `smbpasswd -a root` で root を登録していたら**: `sudo pdbedit -x -u root` で登録を削除する

### 参照

- [Chapter 1. Using Samba as a server — Configuring and using network file services (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/configuring_and_using_network_file_services/using-samba-as-a-server)
- [Setting up Samba as a Standalone Server — SambaWiki](https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Standalone_Server)
- `man smb.conf`（`[homes]` 節、`server smb transports`、`valid users`、`force user`、`inherit owner`、`map archive`、`smb3 directory leases`、`kernel change notify`）/ `man smbpasswd`（`-s`）/ `man smbclient`（`-A`）/ `man mount.cifs`（`credentials=`、`nohandlecache`、`max_cached_dirs`）/ `modinfo cifs`（`dir_cache_timeout`）
- [Samba 4.22.0 — Release Notes](https://www.samba.org/samba/history/samba-4.22.0.html)（SMB3 Directory Leases が入り、クラスタでなければ既定で有効）
- [A "Mapped network drive" on Windows 10 pointing to a SAMBA share on Fedora 42 does not reflect updates done on Linux — Fedora Discussion](https://discussion.fedoraproject.org/t/a-mapped-network-drive-on-windows-10-pointing-to-a-samba-share-on-fedora-42-does-not-reflect-updates-done-on-linux/162207)（同じ症状の報告。`smb3 directory leases = no` で以前の振る舞いに戻せる、という書き込みで終わっている）
- [Performance tuning for file servers — Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/performance-tuning/role/file-server)（`DirectoryCacheLifetime`）
- [Disable local SMB directory enumeration caching — Apple Support](https://support.apple.com/en-us/101918)

---
