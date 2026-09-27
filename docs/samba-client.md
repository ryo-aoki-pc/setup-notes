# Samba の共有を AlmaLinux 10 から使う手順（cifs-utils + fstab の自動マウント / GNOME Files）

## 実施手順

> [!IMPORTANT]
> - **クライアントの PC で、自分のユーザーのシェルで貼る**。`sudo -i` した root のシェルでは貼らない（`$(id -u)` が 0 になり、マウントしたファイルが root の所有に見えるため）
> - 前提: サーバーで [samba.md](samba.md) の手順を終えていること（Windows や NAS の共有でもよい）
> - **手順 2 と手順 4 には対話入力がある**（`sudo` のパスワードと、共有のパスワード）。入力し終えてから次の手順を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: GNOME Files でも開くなら[GNOME Files で開く（任意）](#gnome-files-で開く任意)。戻すときは[ロールバック](#ロールバック)

> [!WARNING]
> **x86_64 の仮想マシン（QEMU）でのみ検証した手順書**で、実機では本実行していない。サーバーは samba.md のとおりに設定したコンテナ。GNOME Files の画面とキーリングは確かめていない（[対象と検証環境](#対象と検証環境)）。

1. 変数を設定する（`SERVER` は必ず値を入れる）。

   ```bash
   SERVER=192.168.1.10                  # ← 自分の値に書き換える。サーバーの IP アドレスか DNS 名（samba.md の SERVER_IP）。<SERVER>
   ```

   ```bash
   SMB_USER=${USER}                     # サーバーの Samba ユーザー。samba.md のサーバーなら、この PC のユーザー名と同じ。<SMB_USER>
   SHARE=${SMB_USER}                    # 共有名。samba.md の [homes] では、ユーザー名と同じ名前の共有になる。<SHARE>
   MOUNT_POINT=/mnt/${SHARE}            # マウント先（無ければ手順 6 で作る）。<MOUNT_POINT>
   for v in SERVER USER SMB_USER SHARE MOUNT_POINT; do
     printf '%-11s = %s\n' "$v" "${!v}"
   done
   ```

   - 編集が必須なのは `SERVER` だけ。NAS や Windows の共有なら、`SMB_USER` と `SHARE` も確かめる
   - 最後に値を読み戻して確かめる
   - `USER` が `root` なら、ここで止めて、自分のユーザーのシェルで貼り直す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**、手順 1 の 2 つのブロックを貼り直してから先へ進む

1. cifs-utils を入れる。

   ```bash
   sudo dnf install -y cifs-utils
   ```

   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. cifs-utils とカーネルのモジュールを確かめ、サーバーの 445/tcp に届くかを見る。

   ```bash
   rpm -q cifs-utils
   modinfo -n cifs
   timeout 5 bash -c "exec 3<>/dev/tcp/${SERVER:?手順 1 の SERVER が空のまま}/445" && echo '445/tcp に届く'
   ```

   - 最後に `445/tcp に届く` と出ればよい

1. 資格情報ファイルを作るため、共有のパスワードを入力する。

   ```bash
   IFS= read -rsp "Samba password for ${SMB_USER}@${SERVER}: " PW; echo
   ```

   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. 資格情報ファイルを、root だけが読めるように置く。

   ```bash
   if [ -z "${PW}" ]; then echo '中断: PW が空のまま。手順 4 を貼り直す' >&2; else
     printf 'username=%s\npassword=%s\n' "${SMB_USER:?手順 1 の SMB_USER が空のまま}" "${PW}" |
       sudo install -m 600 -o root -g root /dev/stdin "/root/smb-${SMB_USER}@${SERVER:?手順 1 の SERVER が空のまま}.cred" &&
     sudo ls -lZ "/root/smb-${SMB_USER}@${SERVER}.cred"
   fi
   unset PW
   ```

1. 1 度だけ手でマウントして読み書きを確かめ、外す。

   ```bash
   sudo mkdir -p "${MOUNT_POINT:?手順 1 の MOUNT_POINT が空のまま}" &&
   sudo mount -t cifs "//${SERVER:?手順 1 の SERVER が空のまま}/${SHARE:?手順 1 の SHARE が空のまま}" "${MOUNT_POINT}" \
     -o "credentials=/root/smb-${SMB_USER:?手順 1 の SMB_USER が空のまま}@${SERVER}.cred,uid=$(id -u),gid=$(id -g),file_mode=0600,dir_mode=0700" &&
   findmnt "${MOUNT_POINT}" &&
   echo "cifs write" > "${MOUNT_POINT}/cifs-test.txt" && cat "${MOUNT_POINT}/cifs-test.txt" &&
   rm "${MOUNT_POINT}/cifs-test.txt" && ls -ldZ "${MOUNT_POINT}"
   sudo umount "${MOUNT_POINT}"
   ```

1. `/etc/fstab` に自動マウントの行を足し、systemd に読み直させる。

   ```bash
   if grep -q '[[:space:]]' <<< "${SERVER:?手順 1 の SERVER が空のまま}${SHARE:?手順 1 の SHARE が空のまま}${MOUNT_POINT:?手順 1 の MOUNT_POINT が空のまま}"; then
     echo '中断: SERVER / SHARE / MOUNT_POINT に空白がある（fstab に書けない）' >&2
   elif awk -v mp="${MOUNT_POINT}" '$1 !~ /^#/ && $2 == mp { f = 1 } END { exit !f }' /etc/fstab; then
     echo "中断: /etc/fstab に ${MOUNT_POINT} の行が既にある" >&2
   else
     echo "//${SERVER}/${SHARE} ${MOUNT_POINT} cifs credentials=/root/smb-${SMB_USER:?手順 1 の SMB_USER が空のまま}@${SERVER}.cred,uid=$(id -u),gid=$(id -g),file_mode=0600,dir_mode=0700,x-systemd.automount,x-systemd.idle-timeout=1min 0 0" | sudo tee -a /etc/fstab &&
     sudo systemctl daemon-reload &&
     sudo findmnt --verify
   fi
   ```

1. 自動マウントを始め、アクセスしたときにマウントされることを確かめる。

   ```bash
   sudo systemctl start "$(systemd-escape -p --suffix=automount "${MOUNT_POINT:?手順 1 の MOUNT_POINT が空のまま}")" &&
   systemctl is-active "$(systemd-escape -p --suffix=automount "${MOUNT_POINT}")" &&
   ls "${MOUNT_POINT}" > /dev/null && findmnt -R "${MOUNT_POINT}" &&
   echo "automount write" > "${MOUNT_POINT}/automount-test.txt" && cat "${MOUNT_POINT}/automount-test.txt" &&
   rm "${MOUNT_POINT}/automount-test.txt"
   sudo ausearch -m AVC -ts recent
   ```

---

## GNOME Files で開く（任意）

1. gvfs-smb と gvfs-fuse が入っているか確かめる。

   ```bash
   rpm -q gvfs-smb gvfs-fuse
   ```

1. どちらかが未導入のときだけ、gvfs-smb と gvfs-fuse を入れる。

   ```bash
   sudo dnf install -y gvfs-smb gvfs-fuse
   ```

1. 端末から共有をマウントする。

   ```bash
   gio mount "smb://${SMB_USER:?手順 1 の SMB_USER が空のまま}@${SERVER:?手順 1 の SERVER が空のまま}/${SHARE:?手順 1 の SHARE が空のまま}"
   ```

1. マウントされたことを確かめる。

   ```bash
   gio mount -l | grep -F "${SERVER:?手順 1 の SERVER が空のまま}"
   ls "/run/user/$(id -u)/gvfs/"
   gio list "smb://${SMB_USER}@${SERVER}/${SHARE}/"
   ```

1. 外す。

   ```bash
   gio mount -u "smb://${SMB_USER:?手順 1 の SMB_USER が空のまま}@${SERVER:?手順 1 の SERVER が空のまま}/${SHARE:?手順 1 の SHARE が空のまま}"
   ```

---

## ロールバック

1. 自動マウントを止め、マウントを外す。

   ```bash
   sudo systemctl stop "$(systemd-escape -p --suffix=automount "${MOUNT_POINT:?手順 1 の MOUNT_POINT が空のまま}")" "$(systemd-escape -p --suffix=mount "${MOUNT_POINT}")"
   ```

1. `/etc/fstab` からその行を消し、systemd に読み直させる。

   ```bash
   if findmnt "${MOUNT_POINT:?手順 1 の MOUNT_POINT が空のまま}" > /dev/null; then
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

1. マウント先と資格情報ファイルを消す。

   ```bash
   sudo rmdir "${MOUNT_POINT:?手順 1 の MOUNT_POINT が空のまま}"
   if grep -qF "credentials=/root/smb-${SMB_USER:?手順 1 の SMB_USER が空のまま}@${SERVER:?手順 1 の SERVER が空のまま}.cred," /etc/fstab; then
     echo '資格情報ファイルは、/etc/fstab のほかの行が使っているので残す'
   else
     sudo rm -f "/root/smb-${SMB_USER}@${SERVER}.cred"
   fi
   ```

1. パッケージも消すときだけ、cifs-utils を消す。

   ```bash
   sudo dnf remove cifs-utils
   ```

1. GNOME Files の節の手順 2 で入れたときだけ、gvfs-smb と gvfs-fuse を消す。

   ```bash
   sudo dnf remove gvfs-smb gvfs-fuse
   ```

---

## 補足

(検証の後に書く)
