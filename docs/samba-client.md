# Samba の共有を AlmaLinux 10 から使う手順（cifs-utils + fstab の自動マウント / GNOME Files）

## 実施手順

- [検証記録](verification/samba-client.md)・[参考資料](reference/samba-client.md)

> [!IMPORTANT]
> - **クライアントの PC で、自分のユーザーのシェルで貼る**。`sudo -i` した root のシェルでは貼らない（`$(id -u)` が 0 になり、マウントしたファイルが root の所有に見えるため）
> - 前提: サーバーで [samba.md](samba.md) の手順を終えていること（Windows や NAS の共有でもよい）
> - **手順 3 には対話入力がある**（共有のパスワード）。入力し終えてから次の手順を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: GNOME Files でも開くなら、[GNOME Files で開く（任意）](#gnome-files-で開く任意)を行う。戻すときは[ロールバック](#ロールバック)

1. 変数を設定する（`SERVER` は必ず値を入れる）。

   ```bash
   SERVER=192.168.1.10                  # ← 自分の値に書き換える。サーバーの IP アドレスか DNS 名（samba.md の SERVER_IP）。<SERVER>
   ```

   ```bash
   SMB_USER=${USER}                     # サーバーの Samba ユーザー。samba.md のサーバーなら、サーバーの OS のユーザー名。<SMB_USER>
   SHARE=${SMB_USER}                    # 共有名。samba.md の [homes] では、ユーザー名と同じ名前の共有になる。<SHARE>
   MOUNT_POINT=/mnt/${SHARE}            # マウント先（無ければ手順 5 で作る）。<MOUNT_POINT>
   for v in SERVER USER SMB_USER SHARE MOUNT_POINT; do
     printf '%-11s = %s\n' "$v" "${!v}"
   done
   ```

   - 編集が必須なのは `SERVER` だけ
   - サーバーのユーザー名がこの PC と違うとき、NAS や Windows の共有のときは、`SMB_USER` と `SHARE` も書き換える
   - samba.md の[root のホーム](samba.md#root-のホームも公開する任意)につなぐときは、`SHARE` を `root` に書き換える（`SMB_USER` は自分のまま）
   - samba.md の[/home](samba.md#home-も公開する任意)につなぐときは、`SHARE` を `home` に書き換える（`SMB_USER` は自分のまま）
   - 最後に値を読み戻して確かめる
   - **既定値のままでもエラーにならない**ので、`SERVER` を書き換えたかをここで確かめる
   - `USER` が `root` なら、ここで止めて、自分のユーザーのシェルで貼り直す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**、手順 1 の 2 つのブロックを貼り直してから先へ進む

1. cifs-utils を入れ、カーネルのモジュールと、サーバーの 445/tcp に届くかを確かめる。

   ```bash
   {
     sudo dnf install -y cifs-utils
     rpm -q cifs-utils
     modinfo -n cifs
     timeout 5 bash -c "exec 3<>/dev/tcp/${SERVER:?手順 1 の SERVER が空のまま}/445" && echo '445/tcp に届く'
   }
   ```

   - Workstation で入れた PC には最初から入っている
   - 入っていれば、`Package cifs-utils-… is already installed.` と出る
   - `cifs-utils-7.7-…` と、`…/kernel/fs/smb/client/cifs.ko.xz` のパスが出る
   - 最後に `445/tcp に届く` と出ればよい
   - `Connection refused` が出る、または 5 秒たっても何も出ないときは、`SERVER` の値と、サーバーの firewalld と smbd（[samba.md 手順 5・8](samba.md#実施手順)）を確かめる
   - 外出先から使うなら、先に WireGuard のトンネルを張る（[注意点](#注意点)）

1. 資格情報ファイルを作るため、共有のパスワードを入力する。

   ```bash
   IFS= read -rsp "Samba password for ${SMB_USER}@${SERVER}: " PW; echo
   ```

   - samba.md のサーバーなら、[samba.md 手順 6](samba.md#実施手順) で `smbpasswd -a` に入れたパスワード
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. 資格情報ファイルを、root だけが読めるように置く。

   ```bash
   if [ -z "${SMB_USER}" ] || [ -z "${SERVER}" ]; then echo '中断: 手順 1 の SMB_USER か SERVER が空のまま。手順 1 と手順 3 を貼り直す' >&2
   elif [ -z "${PW}" ]; then echo '中断: PW が空のまま。手順 3 を貼り直す' >&2
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
   - `mount error(…)` が出たら、ここで止めて原因を直す（表示と原因は[検証記録](verification/samba-client.md)・[参考資料](reference/samba-client.md)）
   - `SHARE=home`（samba.md の `[home]`）では、`cifs-test.txt` の書き込みが `Permission denied` になる（共有の直下は `/home` で、サーバーの SELinux が作るのを断る）。`findmnt` の行が出ていればよい

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

   - 通常の共有では、`active`、`findmnt` の `autofs` と `cifs` の 2 行、`automount write` が出ればよい
   - `SHARE=home` では、手順 5 と同じく共有直下への書き込みが `Permission denied` になる。これはサーバーの SELinux による拒否で、`active` と `findmnt` の 2 行が出ればマウントの確認はできている
   - 最後の `ausearch` は `<no matches>`
   - 以後は `<MOUNT_POINT>` をふつうのディレクトリとして使う
   - 使わないまま 1 分ほどたつと外れ、次にアクセスしたときにまたマウントされる
   - 再起動した後も、アクセスしたときにマウントされる

---

## GNOME Files で開く（任意）

- fstab のマウントとは別の仕組み（gvfs）。ログインしたユーザーがつなぐので、root も資格情報ファイルも要らない
- 画面では「ファイル」（Nautilus）から開く。この節のコマンドは、同じ仕組みを端末から使う `gio`
- 手順 1 の変数を設定したシェルで貼る
- **この節の手順 3 には対話入力がある**（ドメインとパスワード）

1. gvfs-smb と gvfs-fuse が入っているか確かめる。

   ```bash
   rpm -q gvfs-smb gvfs-fuse
   ```

   - `package … is not installed` が出たら、この節の手順 2 で入れる
   - 2 つとも版が出たら、この節の手順 2 は飛ばす（GNOME を入れた PC には最初から入っている）

1. どちらかが未導入のときだけ、gvfs-smb と gvfs-fuse を入れる。

   ```bash
   sudo dnf install -y gvfs-smb gvfs-fuse
   ```

   - 入れた後、ログインし直さなくてよい（VM で、動いている gvfsd がそのまま SMB につないだ）

1. 端末から共有をマウントする。

   ```bash
   /usr/bin/gio mount "smb://${SMB_USER:?手順 1 の SMB_USER が空のまま}@${SERVER:?手順 1 の SERVER が空のまま}/${SHARE:?手順 1 の SHARE が空のまま}"
   ```

   - ドメインとパスワードを聞かれる（英語では `Domain [SAMBA]:` と `Password:`）
   - ドメインは、Enter で既定のままでよい
   - パスワードは、手順 3 と同じもの
   - 画面から開くときは、「ファイル」のサイドバーの「Network」を開き、「Server address」の欄に `smb://<SMB_USER>@<SERVER>/<SHARE>` を入れて「接続」を押す
   - 画面では、認証の画面で「期限なしで記憶する」を選ぶと、パスワードが GNOME のキーリングに保存される
   - `/usr/bin/gio mount` は、パスワードを保存しない
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. マウントされたことを確かめる。

   ```bash
   /usr/bin/gio mount -l | grep -F "${SERVER:?手順 1 の SERVER が空のまま}"
   ls "/run/user/$(id -u)/gvfs/"
   /usr/bin/gio list "smb://${SMB_USER}@${SERVER}/${SHARE}/"
   ```

   - `Mount(0): <SHARE> on <SERVER> -> smb://<SMB_USER>@<SERVER>/<SHARE>/` の 1 行が出ればよい
   - 続いて `smb-share:server=<SERVER>,share=<SHARE>,user=<SMB_USER>` と、共有の中の一覧（隠しファイルは出ない）が出る
   - GIO を使わないアプリからは、`/run/user/<UID>/gvfs/smb-share:…/` の下で読み書きできる
   - 画面では、サイドバーに共有が出る
   - サーバーで変えたものは、「ファイル」には自動では出ない。F5 で出る（[注意点](#注意点)）

1. 共有を外す。

   ```bash
   /usr/bin/gio mount -u "smb://${SMB_USER:?手順 1 の SMB_USER が空のまま}@${SERVER:?手順 1 の SERVER が空のまま}/${SHARE:?手順 1 の SHARE が空のまま}"
   ```

   - 何も出ずに終わればよい
   - 外した共有は、`/usr/bin/gio mount -l` からも `/run/user/<UID>/gvfs/` からも消える
   - 画面では、サイドバーの共有の横の取り出しのボタンで外す

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

1. [GNOME Files で開く（任意）](#gnome-files-で開く任意)の手順 2 で入れたときだけ、gvfs-smb と gvfs-fuse を消す。

   ```bash
   sudo dnf remove gvfs-smb gvfs-fuse
   ```

   - GNOME を入れた PC には最初から入っているので、消さない（消すと、「ファイル」から SMB につなげなくなる）
   - トランザクション表を見て `[y/N]` に答える

---

## 注意点

- **サーバーに届かないとき**（VM で測った値）
  - マウントしていない状態でアクセスすると、`ls: cannot open directory '<MOUNT_POINT>': No such device` で失敗する。接続を断られると 1 秒以内、応答が無いと約 11 秒
  - 接続に失敗すると、`systemctl --failed` に `mnt-<SHARE>.mount` が出て、`systemctl is-system-running` が `degraded` になる。サーバーに届くようになってからアクセスし直す
  - **マウントしている間に届かなくなると、ファイルを開くコマンドが長時間止まることがある**。サーバーへの接続を確認してからアクセスし直す
  - 使っていなければ、届かなくても 1 分の idle-timeout で外れた
- **外出先から WireGuard 越しに使うとき**: トンネルを張ってからアクセスする
  - `SERVER` を LAN 側の IP にしておくと、fstab の 1 行を LAN の中でも外でも使える。[wireguard-road-warrior.md](wireguard-road-warrior.md) の `AllowedIPs` に拠点の LAN が入っているため
- **サーバーで直接変えたもの**（サーバーのシェルや Syncthing などで、Samba を通さずに）
  - samba.md の今のサーバー（`smb3 directory leases = no`）なら、`ls` にすぐ出る。消したファイルを `stat` で引くと、約 1 秒はまだあるように見える（`actimeo=1`）
  - サーバーを変えられないときは、マウントのオプションに `nohandlecache` を足す
- **GNOME Files（`smb://`）は、サーバーで変えたものを自動では出さない**: F5 ですぐ出る。gvfs はディレクトリのリースを使わないので、サーバーの設定によらない（[検証記録](verification/samba-client.md)）
- **`sudo mount -a` はエラーを出す**: 自動マウントの行について、1 回目は `mount error(16): Device or resource busy`
  - パスをたどった時点で systemd がマウントし、そのあと mount.cifs が同じ場所にもう一度マウントしようとするため
- **資格情報ファイルは平文**: root なら読める。samba.md では Samba のパスワードは OS のパスワードと別なので、OS のパスワードと同じにしない
- **パスワードを変えたら**: サーバーで変え（samba.md では `sudo smbpasswd <SMB_USER>`）、この PC で手順 3・4 を貼り直す
- **空白を含むユーザー名・共有名・マウント先は扱わない**: 手順 6 で中断する（fstab の欄を空白で区切るため）
- **SELinux**: マウントしたファイルの型は `cifs_t`
  - ログインしたユーザーのプログラムは、そのまま読み書きできる
  - 制限のあるサービス（Apache など）から使うなら、そのサービスの boolean（`httpd_use_cifs` など）が要る
- **貼り方**: `sudo` の後ろに行が続くブロックは、どれも 1 つのコマンド（`if … fi` や `{ … }`）にしてある
  - ブラケットペーストが効かない端末で複数行を貼ると、途中の `sudo` が後ろの行を読み取って捨てるため、ブロックを `{ }` で囲む
