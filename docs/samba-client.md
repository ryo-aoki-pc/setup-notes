# Samba の共有を AlmaLinux 10 から使う手順（cifs-utils + fstab の自動マウント / GNOME Files）

## 実施手順

> [!IMPORTANT]
> - **クライアントの PC で、自分のユーザーのシェルで貼る**。`sudo -i` した root のシェルでは貼らない（`$(id -u)` が 0 になり、マウントしたファイルが root の所有に見えるため）
> - 前提: サーバーで [samba.md](samba.md) の手順を終えていること（Windows や NAS の共有でもよい）
> - **手順 2 と手順 4 には対話入力がある**（`sudo` のパスワードと、共有のパスワード）。入力し終えてから次の手順を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: GNOME Files でも開くなら、[GNOME Files で開く（任意）](#gnome-files-で開く任意)を行う。戻すときは[ロールバック](#ロールバック)

> [!WARNING]
> **x86_64 の仮想マシン（QEMU）でのみ検証した手順書**で、実機では本実行していない。サーバーは samba.md 手順 3 の `smb.conf` を置いたコンテナ。GNOME Files の画面とキーリングは確かめていない（[対象と検証環境](#対象と検証環境)）。

1. 変数を設定する（`SERVER` は必ず値を入れる）。

   ```bash
   SERVER=192.168.1.10                  # ← 自分の値に書き換える。サーバーの IP アドレスか DNS 名（samba.md の SERVER_IP）。<SERVER>
   ```

   ```bash
   SMB_USER=${USER}                     # サーバーの Samba ユーザー。samba.md のサーバーなら、サーバーの OS のユーザー名。<SMB_USER>
   SHARE=${SMB_USER}                    # 共有名。samba.md の [homes] では、ユーザー名と同じ名前の共有になる。<SHARE>
   MOUNT_POINT=/mnt/${SHARE}            # マウント先（無ければ手順 6 で作る）。<MOUNT_POINT>
   for v in SERVER USER SMB_USER SHARE MOUNT_POINT; do
     printf '%-11s = %s\n' "$v" "${!v}"
   done
   ```

   - 編集が必須なのは `SERVER` だけ
   - サーバーのユーザー名がこの PC と違うとき、NAS や Windows の共有のときは、`SMB_USER` と `SHARE` も書き換える
   - 最後に値を読み戻して確かめる
   - **既定値のままでもエラーにならない**ので、`SERVER` を書き換えたかをここで確かめる
   - `USER` が `root` なら、ここで止めて、自分のユーザーのシェルで貼り直す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**、手順 1 の 2 つのブロックを貼り直してから先へ進む

   <details>
   <summary>補足: 変数について</summary>

   - `SMB_USER` を `USER`（この PC のユーザー名）と分けてあるのは、NAS や Windows ではサーバー側のアカウント名が違うことがあるため
   - samba.md のサーバーは OS のアカウント名で Samba ユーザーを登録するので、この PC と同じ名前なら既定のままでよい
   - samba.md の `[homes]` は、Samba ユーザーと同じ名前の共有を見せる。ほかの共有につなぐなら `SHARE` を書き換える
   - `SERVER` に NetBIOS 名は使えない。samba.md のサーバーは NetBIOS（nmbd）を動かさない。IP アドレスか、DNS（または `/etc/hosts`）で引ける名前にする
   - `SMB_USER`・`SHARE`・`MOUNT_POINT` に空白を入れない。fstab の欄は空白で区切るので、手順 7 で中断する

   </details>

1. cifs-utils を入れる。

   ```bash
   sudo dnf install -y cifs-utils
   ```

   - Workstation で入れた PC には最初から入っている
   - 入っていれば、`Package cifs-utils-… is already installed.` と出る
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: パッケージ</summary>

   - `cifs-utils`（BaseOS）がマウントの道具 `mount.cifs` を入れる。カーネルの側（`cifs.ko`）は `kernel-modules` に入っている
   - VM（GNOME の無い最小の構成）では、依存を合わせて 7 パッケージ（ダウンロード 16 MB、導入後 57 MB）が入った: `cifs-utils-7.7-1.el10_2`、`samba-client-libs`・`samba-common`・`samba-common-libs`・`libwbclient`（いずれも `4.23.5-110.el10_2`）、`libicu`、`avahi-libs`
   - `cifs-utils` は、Workstation では `workstation-product` グループの必須パッケージ、Server with GUI では `standard` グループの任意パッケージ（`dnf group info` で確認）
   - `samba-client`（`smbclient`）は入れない。マウントには要らない

   </details>

1. cifs-utils とカーネルのモジュールを確かめ、サーバーの 445/tcp に届くかを見る。

   ```bash
   rpm -q cifs-utils
   modinfo -n cifs
   timeout 5 bash -c "exec 3<>/dev/tcp/${SERVER:?手順 1 の SERVER が空のまま}/445" && echo '445/tcp に届く'
   ```

   - `cifs-utils-7.7-…` と、`…/kernel/fs/smb/client/cifs.ko.xz` のパスが出る
   - 最後に `445/tcp に届く` と出ればよい
   - `Connection refused` が出る、または 5 秒たっても何も出ないときは、`SERVER` の値と、サーバーの firewalld と smbd（[samba.md 手順 5・8](samba.md#実施手順)）を確かめる
   - 外出先から使うなら、先に WireGuard のトンネルを張る（[注意点](#注意点)）

   <details>
   <summary>補足: 確かめていること</summary>

   - `modinfo -n` は、モジュールのファイルがあるかだけを見る。読み込むのは、手順 6 で最初にマウントするとき
   - `/dev/tcp/<SERVER>/445` は bash の機能で、445/tcp に TCP でつなぐだけ（SMB のやり取りはしない）。つながると何も出さずに閉じる
   - VM での失敗の表示:
     - smbd が止まっている（接続を断られる）: 0.2 秒で `bash: connect: Connection refused` と `bash: line 1: /dev/tcp/<SERVER>/445: Connection refused`
     - パケットが捨てられる（firewalld で閉じている、経路が無いなど）: 5 秒後に何も出さずに終わる（`timeout` の終了コード 124）

   </details>

1. 資格情報ファイルを作るため、共有のパスワードを入力する。

   ```bash
   IFS= read -rsp "Samba password for ${SMB_USER}@${SERVER}: " PW; echo
   ```

   - samba.md のサーバーなら、[samba.md 手順 6](samba.md#実施手順) で `smbpasswd -a` に入れたパスワード
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. 資格情報ファイルを、root だけが読めるように置く。

   ```bash
   if [ -z "${SMB_USER}" ] || [ -z "${SERVER}" ]; then echo '中断: 手順 1 の SMB_USER か SERVER が空のまま。手順 1 と手順 4 を貼り直す' >&2
   elif [ -z "${PW}" ]; then echo '中断: PW が空のまま。手順 4 を貼り直す' >&2
   else
     printf 'username=%s\npassword=%s\n' "${SMB_USER}" "${PW}" |
       sudo install -m 600 -o root -g root /dev/stdin "/root/smb-${SMB_USER}@${SERVER}.cred" &&
     sudo ls -lZ "/root/smb-${SMB_USER}@${SERVER}.cred"
   fi; unset PW
   ```

   - `-rw------- … root root … admin_home_t … /root/smb-<SMB_USER>@<SERVER>.cred` の 1 行が出ればよい
   - パスワードは、コマンドラインにもシェルの履歴にも残らない
   - 最後の `unset PW` で、シェルの変数からもパスワードを消す
   - 資格情報ファイルの中身は平文（[注意点](#注意点)）

   <details>
   <summary>補足: 資格情報ファイル</summary>

   - 形式は `mount.cifs` の `credentials=` のもの（`username=` と `password=` の 2 行）。Windows のドメインのアカウントなら `domain=` の行を足す
   - `printf` はシェルの組み込みなので、パスワードはどのプロセスのコマンドラインにも出ない。`sudo install` が標準入力から受け取り、`root:root` の 0600 で書く
   - 置き場所は RHEL 10 の文書の `/root/smb.cred` にならい、名前にユーザーとサーバーを入れて、複数の共有を並べられるようにした
   - VM では、ラベルは `system_u:object_r:admin_home_t:s0` になった（`install` が既定のラベルを付ける）
   - mount.cifs は、行頭の空白だけを読み飛ばし、`=` の後ろは改行の手前までをそのまま値にする（cifs-utils 7.7 のソース）。`IFS= read -r` で読んだので、パスワードの前後の空白も残る
   - VM では、カンマ・空白・`$` を含むパスワードでマウントできた。カンマは、mount.cifs がカーネルへ渡すときに逃がしている
   - パスワードを変えたら、手順 4・5 を貼り直す。`install` がファイルを置き換え、次にマウントするときから効く
   - VM では、サーバーでパスワードを変えた後、古いファイルのままだと次のマウントが `mount error(13)` で失敗し、手順 4・5 を貼り直すと通った
   - 変数が空かどうかは、ブロックの先頭の `if` で確かめる。パイプの中の `${VAR:?…}` は、そのパイプの 1 つのコマンドしか止めない
   - 例えば `SMB_USER` が空のまま `${SMB_USER:?…}` だけで確かめると、`/root/smb-@<SERVER>.cred` という空のファイルができる
   - `fi; unset PW` を 1 行にしてあるのは、ブロックの全体を 1 つのコマンドにするため。途中の `sudo` が後ろの行を読み取って捨てても、`unset PW` が消えない（[付録](#付録-vm-での検証記録2026-09-27)）

   </details>

1. 1 度だけ手でマウントして読み書きを確かめ、外す。

   ```bash
   sudo mkdir -p "${MOUNT_POINT:?手順 1 の MOUNT_POINT が空のまま}" &&
   sudo mount -t cifs "//${SERVER:?手順 1 の SERVER が空のまま}/${SHARE:?手順 1 の SHARE が空のまま}" "${MOUNT_POINT}" \
     -o "credentials=/root/smb-${SMB_USER:?手順 1 の SMB_USER が空のまま}@${SERVER}.cred,uid=$(id -u),gid=$(id -g),file_mode=0600,dir_mode=0700" && {
     findmnt "${MOUNT_POINT}"
     echo "cifs write" > "${MOUNT_POINT}/cifs-test.txt" && cat "${MOUNT_POINT}/cifs-test.txt" && rm "${MOUNT_POINT}/cifs-test.txt"
     ls -ldZ "${MOUNT_POINT}"
     sudo umount "${MOUNT_POINT}"
   }
   ```

   - `findmnt` に `//<SERVER>/<SHARE>` の `cifs` の行（`vers=3.1.1` を含む）、続いて `cifs write` が出ればよい
   - `ls -ldZ` は `drwx------ … <USER> <USER> … cifs_t …`（自分の所有で、ほかのユーザーは入れない）
   - `mount error(…)` が出たら、ここで止めて原因を直す（表示と原因はこの手順の補足）

   <details>
   <summary>補足: 手でマウントする理由と、失敗の表示</summary>

   **理由**: 手順 8 の自動マウントでは、失敗は `ls` の `No such device` としてしか出ない。手で 1 度マウントすると、原因が表示で分かる。

   - マウントの後を `{ … }` のひとまとまりにしてあるのは、途中で失敗しても必ず外すため
   - マウントが残っていると、手順 8 の自動マウントが始まらない。VM では `Path <MOUNT_POINT> is already a mount point, refusing start.` で失敗した
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

   </details>

1. `/etc/fstab` に自動マウントの行を足し、systemd に読み直させる。

   ```bash
   if [ -z "${SERVER}" ] || [ -z "${SMB_USER}" ] || [ -z "${SHARE}" ] || [ -z "${MOUNT_POINT}" ]; then
     echo '中断: 手順 1 の変数が空のまま。手順 1 を貼り直す' >&2
   elif grep -q '[[:space:]]' <<< "${SERVER}${SMB_USER}${SHARE}${MOUNT_POINT}"; then
     echo '中断: SERVER / SMB_USER / SHARE / MOUNT_POINT に空白がある（fstab に書けない）' >&2
   elif awk -v mp="${MOUNT_POINT}" '$1 !~ /^#/ && $2 == mp { f = 1 } END { exit !f }' /etc/fstab; then
     echo "中断: /etc/fstab に ${MOUNT_POINT} の行が既にある" >&2
   else
     echo "//${SERVER}/${SHARE} ${MOUNT_POINT} cifs credentials=/root/smb-${SMB_USER}@${SERVER}.cred,uid=$(id -u),gid=$(id -g),file_mode=0600,dir_mode=0700,x-systemd.automount,x-systemd.idle-timeout=1min 0 0" | sudo tee -a /etc/fstab &&
     sudo systemctl daemon-reload &&
     sudo findmnt --verify
   fi
   ```

   - 足した 1 行が表示され、最後に `Success, no errors or warnings detected` と出ればよい
   - `中断: …` と出たときは、表示の理由を直してから貼り直す
   - 同じマウント先の行が既にあるときは、その行を確かめる（前にこの手順で足した行なら、この手順は済んでいる）

   <details>
   <summary>補足: fstab の行</summary>

   足す行（VM での例）:

   ```
   //<SERVER>/<SHARE> <MOUNT_POINT> cifs credentials=/root/smb-<SMB_USER>@<SERVER>.cred,uid=1000,gid=1000,file_mode=0600,dir_mode=0700,x-systemd.automount,x-systemd.idle-timeout=1min 0 0
   ```

   - `x-systemd.automount`: 起動時にはマウントせず、`<MOUNT_POINT>` にアクセスしたときに systemd がマウントする
   - `x-systemd.idle-timeout=1min`: 使わないまま 1 分たつと外す
   - ほかのオプションは手順 6 と同じ。付けなかったもの（`_netdev`・`nofail`・`vers=`）の理由は[選択した方針](#選択した方針)
   - `daemon-reload` で、`systemd-fstab-generator` が `/run/systemd/generator/` に `mnt-<SHARE>.automount` と `mnt-<SHARE>.mount` を作る（名前は `systemd-escape -p` の結果。`/mnt/` の下なら `mnt-` + 共有名）
   - `findmnt --verify` は `sudo` を付ける。付けないと、ほかの行について `cannot detect on-disk filesystem type (Permission denied)` の警告が出る（VM で 3 件）
   - 中断の条件は、変数が空のとき、変数に空白があるとき、同じマウント先の行（コメント行は数えない）があるとき。VM で 2 回貼っても、行は増えなかった
   - 変数が空かどうかを先頭の `if` で確かめるのは、パイプの中の `${VAR:?…}` がブロックを止めないため
   - 直す前の版は、`SMB_USER` が空でも何も足さずに `Success` と出た（レビューのエージェントが `sudo` をスタブにした bash で確かめた）

   </details>

1. 自動マウントを始め、アクセスしたときにマウントされることを確かめる。

   ```bash
   if [ -z "${MOUNT_POINT}" ]; then echo '中断: 手順 1 の MOUNT_POINT が空のまま。手順 1 を貼り直す' >&2; else
     sudo systemctl start "$(systemd-escape -p --suffix=automount "${MOUNT_POINT}")" &&
     systemctl is-active "$(systemd-escape -p --suffix=automount "${MOUNT_POINT}")" &&
     ls "${MOUNT_POINT}" > /dev/null && findmnt -R "${MOUNT_POINT}" &&
     echo "automount write" > "${MOUNT_POINT}/automount-test.txt" && cat "${MOUNT_POINT}/automount-test.txt" &&
     rm "${MOUNT_POINT}/automount-test.txt"
     sudo ausearch -m AVC -ts recent
   fi
   ```

   - `active`、`findmnt` の `autofs` と `cifs` の 2 行、`automount write` が出ればよい
   - 最後の `ausearch` は `<no matches>`
   - 以後は `<MOUNT_POINT>` をふつうのディレクトリとして使う
   - 使わないまま 1 分ほどたつと外れ、次にアクセスしたときにまたマウントされる
   - 再起動した後も、アクセスしたときにマウントされる（VM で確認）

   <details>
   <summary>補足: 自動マウントの様子</summary>

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

   </details>

---

## GNOME Files で開く（任意）

- fstab のマウントとは別の仕組み（gvfs）。ログインしたユーザーがつなぐので、root も資格情報ファイルも要らない
- 画面では「ファイル」（Nautilus）から開く。この節のコマンドは、同じ仕組みを端末から使う `gio` で、VM で確かめたのはこちら
- 手順 1 の変数を設定したシェルで貼る
- **この節の手順 2 と手順 3 には対話入力がある**（`sudo` のパスワードと、ドメインとパスワード）

1. gvfs-smb と gvfs-fuse が入っているか確かめる。

   ```bash
   rpm -q gvfs-smb gvfs-fuse
   ```

   - `package … is not installed` が出たら、この節の手順 2 で入れる
   - 2 つとも版が出たら、この節の手順 2 は飛ばす（GNOME を入れた PC には最初から入っている）

   <details>
   <summary>補足: パッケージ</summary>

   - `gvfs-smb` が gvfs の SMB のバックエンド（libsmbclient を使う）、`gvfs-fuse` が GIO を使わないアプリ向けの `/run/user/<UID>/gvfs/`
   - どちらも GNOME のグループ（`gnome-desktop`）の必須パッケージなので、Workstation にも Server with GUI にも入っている（`dnf group info` で確認）

   </details>

1. どちらかが未導入のときだけ、gvfs-smb と gvfs-fuse を入れる。

   ```bash
   sudo dnf install -y gvfs-smb gvfs-fuse
   ```

   - 入れた後、ログインし直さなくてよい（VM で、動いている gvfsd がそのまま SMB につないだ）
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 入るもの</summary>

   - GNOME の無い VM では、gvfs 本体・udisks2・libsmbclient・wsdd など、依存を合わせて 42 パッケージ（ダウンロード 14 MB、導入後 53 MB）が入った
   - gvfs を入れて gvfsd を動かしたまま gvfs-smb だけを消して入れ直しても、同じ gvfsd（PID が変わらない）で `gio mount` が通った

   </details>

1. 端末から共有をマウントする。

   ```bash
   gio mount "smb://${SMB_USER:?手順 1 の SMB_USER が空のまま}@${SERVER:?手順 1 の SERVER が空のまま}/${SHARE:?手順 1 の SHARE が空のまま}"
   ```

   - `Domain [SAMBA]:` と `Password:` を聞かれる
   - ドメインは、Enter で既定のままでよい
   - パスワードは、手順 4 と同じもの
   - 画面から開くときは、「ファイル」のサイドバーの「Network」を開き、「Server address」の欄に `smb://<SMB_USER>@<SERVER>/<SHARE>` を入れて「接続」を押す（画面では未確認）
   - 画面では、認証の画面で「期限なしで記憶する」を選ぶと、パスワードが GNOME のキーリングに保存される（未確認）
   - `gio mount` は、パスワードを保存しない
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

   <details>
   <summary>補足: 問い合わせと、画面の文言</summary>

   `gio mount` の問い合わせ（VM）:

   ```
   Authentication Required
   Enter password for share “<SHARE>” on “<SERVER>”:
   Domain [SAMBA]:
   Password:
   ```

   - URI に `<SMB_USER>@` を入れたので、ユーザー名は聞かれない
   - ドメインの既定の `SAMBA` は、この PC の `/etc/samba/smb.conf`（依存で入る samba-common が置く）の `workgroup` の既定値と同じ
   - samba.md のサーバーは standalone（`workgroup = WORKGROUP`）だが、ドメインを `SAMBA` のままにしても通った

   画面の文言は、EL10 の nautilus 47.6 と GTK 4.16 の UI の定義と日本語の翻訳から取った（画面では確かめていない）:

   - サイドバーの項目は「Network」、アドレスの欄は「Server address」、ボタンは「接続」
   - 「Network」と「Server address」は nautilus 47.6 の日本語の翻訳に無いので、英語のまま出るはず
   - RHEL 10 の文書は「Other Locations」→「Enter server address」と書いているが、nautilus 47.6 の UI の定義はそうなっていない
   - 認証の画面（GTK）は「登録ユーザー」「ユーザー名」「ドメイン」「パスワード」、記憶のしかたが「今すぐパスワードを破棄する」「ログアウトするまでパスワードを記憶する」「期限なしで記憶する」、ボタンが「接続する」

   </details>

1. マウントされたことを確かめる。

   ```bash
   gio mount -l | grep -F "${SERVER:?手順 1 の SERVER が空のまま}"
   ls "/run/user/$(id -u)/gvfs/"
   gio list "smb://${SMB_USER}@${SERVER}/${SHARE}/"
   ```

   - `Mount(0): <SHARE> on <SERVER> -> smb://<SMB_USER>@<SERVER>/<SHARE>/` の 1 行が出ればよい
   - 続いて `smb-share:server=<SERVER>,share=<SHARE>,user=<SMB_USER>` と、共有の中の一覧（隠しファイルは出ない）が出る
   - GIO を使わないアプリからは、`/run/user/<UID>/gvfs/smb-share:…/` の下で読み書きできる
   - 画面では、サイドバーに共有が出るはず（未確認）

1. 共有を外す。

   ```bash
   gio mount -u "smb://${SMB_USER:?手順 1 の SMB_USER が空のまま}@${SERVER:?手順 1 の SERVER が空のまま}/${SHARE:?手順 1 の SHARE が空のまま}"
   ```

   - 何も出ずに終わればよい
   - 外した共有は、`gio mount -l` からも `/run/user/<UID>/gvfs/` からも消える
   - 画面では、サイドバーの共有の横の取り出しのボタンで外す（未確認）

---

## ロールバック

- 手順 1 の変数を設定したシェルで、上から順に貼る（新しいシェルなら、手順 1 の 2 つのブロックを貼り直してから）
- GNOME Files でつないだままなら、先に [GNOME Files で開く（任意）](#gnome-files-で開く任意)の手順 5 を貼る
- この節は、`MOUNT_POINT` の行だけを fstab から消す。ほかの共有の行は残る

1. 自動マウントを止め、マウントを外す。

   ```bash
   if [ -z "${MOUNT_POINT}" ]; then echo '中断: 手順 1 の MOUNT_POINT が空のまま。手順 1 を貼り直す' >&2; else
     sudo systemctl stop "$(systemd-escape -p --suffix=automount "${MOUNT_POINT}")" "$(systemd-escape -p --suffix=mount "${MOUNT_POINT}")"
   fi
   ```

   - 何も出ずに終わればよい
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 2 つのユニットを止める理由</summary>

   - `.automount` と `.mount` を一緒に止めると、`cifs` と `autofs` の両方が外れる（VM で確認）
   - `.mount` だけを止めると、`Stopping 'mnt-<SHARE>.mount', but its triggering units are still active: mnt-<SHARE>.automount` と出て、次のアクセスでまたマウントされる
   - `MOUNT_POINT` が空のまま `$(systemd-escape …)` を使うと、ユニットの名前が `-.mount`（ルートのファイルシステム）になる。先頭の `if` はこれを防ぐ

   </details>

1. `/etc/fstab` からその行を消し、systemd に読み直させる。

   ```bash
   if [ -z "${MOUNT_POINT}" ]; then
     echo '中断: 手順 1 の MOUNT_POINT が空のまま。手順 1 を貼り直す' >&2
   elif findmnt "${MOUNT_POINT}" > /dev/null; then
     echo "中断: ${MOUNT_POINT} がまだマウントされている（この節の手順 1 を貼り直す）" >&2
   elif ! awk -v mp="${MOUNT_POINT}" '$1 !~ /^#/ && $2 == mp && $3 == "cifs" { f = 1 } END { exit !f }' /etc/fstab; then
     echo "中断: /etc/fstab に ${MOUNT_POINT} の cifs の行が無い" >&2
   else
     sudo cp -a /etc/fstab /etc/fstab.bak-samba-client &&
     awk -v mp="${MOUNT_POINT}" '!($1 !~ /^#/ && $2 == mp && $3 == "cifs")' /etc/fstab.bak-samba-client | sudo tee /etc/fstab > /dev/null &&
     sudo systemctl daemon-reload &&
     sudo findmnt --verify
     diff /etc/fstab.bak-samba-client /etc/fstab
   fi
   ```

   - `Success, no errors or warnings detected` が出ればよい
   - `diff` は、`15d14` のような行と、消した 1 行（`< //<SERVER>/<SHARE> <MOUNT_POINT> cifs …`）だけを出す
   - 消す前の fstab は、`/etc/fstab.bak-samba-client` に残る
   - `/etc/fstab.bak-samba-client` が要らなければ消す

   <details>
   <summary>補足: 行の消し方</summary>

   - 行は awk で、2 列目（マウント先）と 3 列目（`cifs`）を文字列として比べて消す。sed の正規表現だと、IP アドレスのドットなどが特別な意味を持つ
   - `tee` で書き戻すので、`/etc/fstab` のモード（0644）とラベル（`etc_t`）は変わらない（VM で確認）
   - VM では、`mnt-<SHARE>.*` のユニットと `/run/systemd/generator/` の中のものも、`daemon-reload` で消えた

   </details>

1. マウント先と資格情報ファイルを消す。

   ```bash
   if [ -z "${MOUNT_POINT}" ] || [ -z "${SMB_USER}" ] || [ -z "${SERVER}" ]; then
     echo '中断: 手順 1 の変数が空のまま。手順 1 を貼り直す' >&2
   else
     sudo rmdir "${MOUNT_POINT}"
     if grep -qF "credentials=/root/smb-${SMB_USER}@${SERVER}.cred," /etc/fstab; then
       echo '資格情報ファイルは、/etc/fstab のほかの行が使っているので残す'
     else
       sudo rm -f "/root/smb-${SMB_USER}@${SERVER}.cred"
     fi
   fi
   ```

   - 何も出ずに終わればよい
   - 同じサーバーの別の共有が同じ資格情報ファイルを使っていれば、その旨を表示して残す

1. 手順 2 で cifs-utils を新しく入れたときだけ、cifs-utils を消す。

   ```bash
   sudo dnf remove cifs-utils
   ```

   - Workstation で入れた PC には最初から入っているので、消さない
   - 手順 2 で依存として入ったもの（`samba-client-libs` など）も、ほかに使うものが無ければ一緒に消える
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 消えるもの</summary>

   - VM では、GNOME Files の節の前なら、手順 2 で入った 7 パッケージ（57 MB）が消える表だった（`dnf remove --assumeno` で確認）
   - GNOME Files の節の後では、cifs-utils だけが消えた。依存は、その節で入った libsmbclient が使っている
   - 手順 2 で入れていない PC で消すと、`mount.cifs` が無くなり、ほかの CIFS のマウントもできなくなる

   </details>

1. [GNOME Files で開く（任意）](#gnome-files-で開く任意)の手順 2 で入れたときだけ、gvfs-smb と gvfs-fuse を消す。

   ```bash
   sudo dnf remove gvfs-smb gvfs-fuse
   ```

   - GNOME を入れた PC には最初から入っているので、消さない（消すと、「ファイル」から SMB につなげなくなる）
   - トランザクション表を見て `[y/N]` に答える

   <details>
   <summary>補足: 消えるもの</summary>

   - VM では、使われなくなった依存を合わせて 21 パッケージ（72 MB）が消えた

   </details>

---

## 補足

### 対象と検証環境

- **目的**: [samba.md](samba.md) で公開したホームディレクトリ（`[homes]` 共有）を、AlmaLinux 10 の PC から、ふだんのディレクトリのように読み書きする
  - `/etc/fstab` に 1 行を足し、`/mnt/<SHARE>` にアクセスしたときに systemd がマウントする（`x-systemd.automount`）。起動時にはマウントしない
  - パスワードは、root だけが読める資格情報ファイルに置く。fstab には書かない
  - GNOME Files（gvfs）でつなぐ方法は、任意節にした
- **進め方**: **冒頭の変数ブロックに値を 1 度書き、以降のコマンドをそのまま貼る**
  - 読者が編集するのは `SERVER` だけ（NAS や Windows の共有なら `SMB_USER` と `SHARE` も）
- **状態**: **x86_64 の仮想マシン（QEMU）でのみ検証済み（2026-09-27）。実機では本実行していない**
  - このクラウドのホストのカーネルには CIFS が無く、コンテナでは `mount -t cifs` を試せない。そこで QEMU の VM（KVM 無しの TCG）で、AlmaLinux 10.2 の GenericCloud イメージを動かした
  - VM の SELinux は Enforcing、firewalld は active
  - サーバーは、samba.md 手順 3 の `smb.conf` をそのまま置いたコンテナ（同じホストの Docker）
  - **この文書のコードブロックをそのまま貼って**、手順 1〜8、GNOME Files の節、ロールバックを通した
  - 貼り方は、ブラケットペーストとブラケットペースト無しの 2 通りで、それぞれまっさらな VM で通した
  - 確認したこと:
    - 手でのマウントと、アクセスしたときの自動マウント（SMB 3.1.1、`cifs_t`、AVC 無し）
    - 使わないまま 1 分で外れること、再起動した後もアクセスでマウントされること
    - サーバーが止まっていても起動が止まらないこと、届かないときの待ち時間と表示
    - ほかのローカルユーザーが読めないこと、日本語のファイル名
    - `gio mount` での接続と、FUSE のパス
    - ロールバックの後に、fstab の行・ユニット・資格情報ファイル・マウント先が残らないこと
    - 手順 1 の変数が空のとき、変数を使うブロックが何も変えずに中断すること
  - **確認していないこと**: 実機（x86_64 PC・Raspberry Pi 5）での実行、GNOME Files の画面の操作とキーリングへの保存、Wi-Fi の切り替えとサスペンドからの復帰、WireGuard 越しのマウント、Windows や NAS の共有
  - 実測の記録は[付録](#付録-vm-での検証記録2026-09-27)

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

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
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
> Samba のパスワードはこの文書に載せない。検証で使ったものは `openssl rand` で作った使い捨てで、記録していない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

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
| ローカルユーザー | `<USER>`（uid 1000、`wheel`。`sudo` はパスワードを聞く）と、確かめ用の 2 人目（uid 1001） |

### 選択した方針

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
  - `uid=` / `gid=`: 無いと、マウントした側のファイルが root の所有に見える（[samba.md 手順 12](samba.md#実施手順) の補足）
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

### 完了時点の状態

VM で、手順 8 の後に確かめた状態:

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

### 注意点

- **サーバーに届かないとき**（VM で測った値）
  - マウントしていない状態でアクセスすると、`ls: cannot open directory '<MOUNT_POINT>': No such device` で失敗する。接続を断られると 1 秒以内、応答が無いと約 11 秒
  - 失敗した後は `systemctl --failed` に `mnt-<SHARE>.mount` が出て、`systemctl is-system-running` が `degraded` になる。サーバーに届くようになってからアクセスすれば、マウントされて元に戻った
  - **マウントしている間に届かなくなると、ファイルを開くコマンドが約 3 分止まる**。そのあと `Resource temporarily unavailable` で失敗した（`soft` の既定。`dmesg` に `has not responded in 180 seconds. Reconnecting...`）
  - 使っていなければ、届かなくても 1 分の idle-timeout で外れた
- **外出先から WireGuard 越しに使うとき**: トンネルを張ってからアクセスする（本書では未検証）
  - `SERVER` を LAN 側の IP にしておくと、fstab の 1 行を LAN の中でも外でも使える。[wireguard-road-warrior.md](wireguard-road-warrior.md) の `AllowedIPs` に拠点の LAN が入っているため
  - トンネル越しに 445/tcp へ届くことは [wireguard-road-warrior.md の付録](wireguard-road-warrior.md#付録-実機での検証記録)で確かめてあるが、マウントは確かめていない
- **`sudo mount -a` はエラーを出す**: 自動マウントの行について、1 回目は `mount error(16): Device or resource busy`
  - パスをたどった時点で systemd がマウントし、そのあと mount.cifs が同じ場所にもう一度マウントしようとするため
  - VM では、共有は 1 つだけマウントされていて、2 回目の `mount -a` は何も出さなかった
- **資格情報ファイルは平文**: root なら読める。samba.md では Samba のパスワードは OS のパスワードと別なので、OS のパスワードと同じにしない
- **パスワードを変えたら**: サーバーで変え（samba.md では `sudo smbpasswd <SMB_USER>`）、この PC で手順 4・5 を貼り直す
- **空白を含むユーザー名・共有名・マウント先は扱わない**: 手順 7 で中断する（fstab の欄を空白で区切るため）
- **SELinux**: マウントしたファイルの型は `cifs_t`
  - ログインしたユーザーのプログラムは、そのまま読み書きできる
  - 制限のあるサービス（Apache など）から使うなら、そのサービスの boolean（`httpd_use_cifs` など）が要る（本書では試していない）
- **貼り方**: `sudo` の後ろに行が続くブロックは、どれも 1 つのコマンド（`if … fi` や `{ … }`）にしてある
  - ブラケットペーストが効かない端末で複数行を貼ると、途中の `sudo` が後ろの行を読み取って捨てるため（[付録](#付録-vm-での検証記録2026-09-27)）
  - VM では、ブラケットペーストで貼った回と、ブラケットペースト無しで貼った回の両方で通した

### 参照

- [Chapter 5. Mounting an SMB Share — Managing file systems (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/managing_file_systems/mounting-an-smb-share)（資格情報ファイル、fstab の例、よく使うオプション）
- [Chapter 10. Browsing files on a network share — Using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_the_gnome_desktop_environment/browsing-files-on-a-network-share)
- [Chapter 6. Managing storage volumes in GNOME — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/managing-storage-volumes-in-gnome)（GIO と、`gvfs-fuse` の `/run/user/UID/gvfs/`）
- `man mount.cifs`（`credentials=`、`uid=`、`file_mode=`、`soft`、`echo_interval`）
- `man systemd.mount`（`x-systemd.automount`、`x-systemd.idle-timeout`、`nofail`、`_netdev`）/ `man systemd-fstab-generator`
- `man findmnt`（`--verify`）/ `man gio`
- cifs-utils 7.7 のソース（`mount.cifs.c` の `open_cred_file`・`parse_cred_line`・`set_password`・`parse_opt_token`）
- [Samba でホームディレクトリを公開する手順](samba.md)（サーバー側）

---

### 付録: VM での検証記録（2026-09-27）

x86_64 のクラウドホストの上で、使い捨ての VM とコンテナを使った。実機で加えた変更は無い。

**環境**:

- ホストは Ubuntu 24.04 / x86_64 のクラウドの VM。カーネル 6.18 に CIFS が無く（`CONFIG_CIFS` 無し、モジュールも読めない）、`/dev/kvm` も無い
- クライアントは `AlmaLinux-10-GenericCloud-10.2-20260817.0.x86_64.qcow2`（`CHECKSUM` の SHA-256 と一致）。QEMU 8.2.2 の TCG（`-accel tcg,thread=multi -cpu max -smp 4 -m 4096`）で起動した
- cloud-init（NoCloud）で次を入れた
  - `<USER>`（uid 1000、`wheel`。`sudo` はパスワードを聞く）と、確かめ用の 2 人目（uid 1001、NOPASSWD の `sudo`）
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
- 次のものは、画面に問い合わせが出てから入力した: `sudo` のパスワード、手順 4 のパスワード、`gio mount` の問い合わせ、`[y/N]`
- 書き上げた後に、独立したレビューの指摘でブロックを直した（下の「レビューで見つけたこと」）
- 直した版を、まっさらな overlay で 2 回通した（ブラケットペースト無しの回と、ブラケットペーストの回）。対象は手順 1〜8・GNOME Files の節・ロールバック。下の表はその 2 回の結果で、2 回とも同じだった

**最初の回で見つけたこと**: 最初の回はブラケットペースト無しで貼った。すると、手順 6 の最後の行（当時は `&&` の連鎖の後ろに独立した `sudo umount`）が実行されず、共有がマウントされたまま残った。

- 原因は sudo 1.9.17 の `use_pty`（既定で有効）。`sudo` が、端末に先に入っていた入力（貼った残りの行）を読み取ってコマンドの疑似端末へ渡し、コマンドが読まないまま捨てる
- `sudo true` と `echo` の 2 行で確かめた。ブラケットペースト無しでは `echo` が実行されず、ブラケットペーストでは Enter の後に 2 行とも実行された
- 手順 6 は、マウントの後の確かめと `umount` を `{ … }` のひとまとまりにして、どちらの貼り方でも外れるようにした
- マウントが残ったまま自動マウントを始めると、`Path <MOUNT_POINT> is already a mount point, refusing start.` で失敗する（手順の外で確かめた）

**レビューで見つけたこと**: 書き上げた後に、独立したエージェントに CLAUDE.md の規則との突き合わせを頼んだ。ブロックにかかわる指摘が 2 つあった。

- **空の変数でブロックが止まらない**
  - パイプや `$(…)` の中の `${VAR:?…}` は、そのサブシェルしか止めない
  - 直す前の手順 5 は、`SMB_USER` が空だと、空の `/root/smb-@<SERVER>.cred` を作った（VM で再現した）
  - 直す前の手順 7 は、何も足さずに `Success` と出た。ロールバックの手順 1 は、`-.mount` を止めに行った（どちらも、レビューのエージェントが `sudo` をスタブにした bash で確かめた。VM では試していない）
  - 変数を使うブロックの先頭で、`if [ -z … ]` で中断するようにした
- **吸われる行が残っていた**: 手順 5 の `unset PW`、手順 8 の `ausearch`、ロールバックの手順 3 の `if … fi`
  - どれも、ブロックの全体を 1 つのコマンドにした（`fi; unset PW` を 1 行にする、`if … fi` の中に入れる）

直した版で確かめたこと:

- 手順 1 を貼っていない新しいシェルで、次のブロックを貼った。どれも、中断のメッセージか `:?` のエラーだけで終わった
  - 手順 3・5・6・7・8
  - GNOME Files の節の手順 3・5
  - ロールバックの手順 1〜3
- その後も、`/root` の資格情報ファイル・fstab・`mnt-*` のユニット・`/mnt` は変わらず、`-.mount` も active のままだった
- `SMB_USER` だけが空のシェルで貼ると、手順 5 と手順 7 は中断した。手順 5 の後は `PW` も消えていた
- ブラケットペースト無しの回で、次のことを確かめた
  - 手順 5 の後に `PW` が消えていた
  - 手順 8 の `ausearch` が `<no matches>` を出した
  - ロールバックの手順 3 で、資格情報ファイルが消えた

| 手順 | 結果（直した版を 2 通りの貼り方で通した回。同じだった） |
|---|---|
| 1 | 読み戻しは `SERVER = <SERVER>`、`USER`・`SMB_USER`・`SHARE` が `<USER>`、`MOUNT_POINT = <MOUNT_POINT>` |
| 2 | 7 パッケージ（16 MB）。`sudo` のパスワードを 1 回聞かれた。もう一度貼ると `Package cifs-utils-7.7-1.el10_2.x86_64 is already installed.` と `Nothing to do.`（直す前の版で確認） |
| 3 | `cifs-utils-7.7-1.el10_2.x86_64`、`/lib/modules/6.12.0-211.56.1.el10_2.x86_64/kernel/fs/smb/client/cifs.ko.xz`、`445/tcp に届く` |
| 4 | `Samba password for <SMB_USER>@<SERVER>:` の後に入力した |
| 5 | `-rw-------. 1 root root system_u:object_r:admin_home_t:s0 … /root/smb-<SMB_USER>@<SERVER>.cred`。この後、`PW` は空 |
| 6 | `findmnt` に `cifs` の行（`vers=3.1.1`）、`cifs write`、`drwx------. 2 <USER> <USER> system_u:object_r:cifs_t:s0`。この後の `findmnt` には何も出ない（外れた） |
| 7 | 足した 1 行と `Success, no errors or warnings detected`。もう一度貼ると `中断: /etc/fstab に <MOUNT_POINT> の行が既にある` で、行は増えない |
| 8 | `active`、`autofs` と `cifs` の 2 行、`automount write`、`<no matches>` |
| GNOME Files 1〜2 | 2 つとも `is not installed`。GNOME Files の節の手順 2 で 42 パッケージ（14 MB）。直前の `sudo` の認証が切れていなかったので、パスワードは聞かれなかった |
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
| パスワードの変更 | サーバーで変えた後、古い資格情報ファイルでは `mount error(13)`。手順 4・5 を貼り直すと通った |
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
