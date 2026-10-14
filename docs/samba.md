# Samba のセットアップ（AlmaLinux 10・Windows 11）

## AlmaLinux 10 で使う

- Samba のクライアントとサーバー

### Samba クライアント

- クライアントの PC で、Samba の共有を cifs でマウントし、アクセスしたときに自動でマウントされるようにする（fstab と systemd の automount）
- 前提: サーバーで[Samba サーバー](#samba-サーバー)を通してある（Windows や NAS の共有でもよい）
- 実行場所: クライアントの PC の、自分のユーザーの bash（デスクトップの端末か SSH）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/samba-client.md)・[参考資料](reference/samba-client.md)・[ロールバックと注意点](extra/samba-client.md)
- AlmaLinux 10 用の手順。Windows 11 は[Windows の手順](#windows-11-で-samba-クライアントを使う)を、管理者ではない Windows PowerShell 5.1 で通す
- **手順 3 には対話入力がある**（共有のパスワード）。入力し終えてから次の手順を貼る
- この項の手順 1 で変数を設定したシェルに貼る

> [!IMPORTANT]
> - **`sudo -i` した root のシェルでは貼らない**（`$(id -u)` が 0 になり、マウントしたファイルが root の所有に見えるため）

1. 変数を設定する（`SERVER` は必ず値を入れる）。

   ```bash
   SERVER=192.168.1.10                  # ← 自分の値に書き換える。サーバーの IP アドレスか DNS 名（Samba サーバーの SERVER_IP）。<SERVER>
   ```

   ```bash
   SMB_USER=${USER}                     # サーバーの Samba ユーザー。AlmaLinux の「Samba サーバー」の設定なら、サーバーの OS のユーザー名。<SMB_USER>
   SHARE=${SMB_USER}                    # 共有名。Samba サーバーの [homes] では、ユーザー名と同じ名前の共有になる。<SHARE>
   MOUNT_POINT=/mnt/${SHARE}            # マウント先（無ければ手順 5 で作る）。<MOUNT_POINT>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in SERVER USER SMB_USER SHARE MOUNT_POINT; do
     printf '%-11s = %s\n' "$v" "${!v}"
   done
   ```

   - 編集が必須なのは `SERVER` だけ
   - サーバーのユーザー名がこの PC と違うとき、NAS や Windows の共有のときは、`SMB_USER` と `SHARE` も書き換える
   - Samba サーバーの[root のホーム](#samba-サーバー-root-のホームも公開する)につなぐときは、`SHARE` を `root` に書き換える（`SMB_USER` は自分のまま）
   - Samba サーバーの[/home](#samba-サーバー-home-も公開する)につなぐときは、`SHARE` を `home` に書き換える（`SMB_USER` は自分のまま）
   - 最後に値を読み戻して確かめる
   - `SERVER` を書き換えたかをここで確かめる
   - `USER` が `root` なら、ここで止めて、自分のユーザーのシェルで貼り直す
   - **新しいシェルを開いたら**、手順 1 の 2 つのブロックを貼り直してから先へ進む

1. cifs-utils を入れ、カーネルのモジュールと、サーバーの 445/tcp に届くかを確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo dnf install -y cifs-utils
     rpm -q cifs-utils
     modinfo -n cifs
     timeout 5 bash -c "exec 3<>/dev/tcp/${SERVER:?手順 1 の SERVER が空のまま}/445" && echo '445/tcp に届く'
   }
   ```

   - 入っていれば、`パッケージ cifs-utils-… は既にインストールされています。`（英語の環境では `Package cifs-utils-… is already installed.`）と出る
   - `cifs-utils-7.7-…` と、`…/kernel/fs/smb/client/cifs.ko.xz` のパスが出る
   - 最後に `445/tcp に届く` と出ればよい
   - `Connection refused` が出る、または 5 秒たっても何も出ないときは、`SERVER` の値と、サーバーの firewalld と smbd（[Samba サーバー](#samba-サーバー)の手順 5・8）を確かめる
   - 外出先から使うなら、先に WireGuard のトンネルを張る（[注意点](extra/samba-client.md#注意点)）

1. 資格情報ファイルを作るため、共有のパスワードを入力する。

   ```bash
   IFS= read -rsp "Samba password for ${SMB_USER}@${SERVER}: " PW; echo
   ```

   - AlmaLinux の「Samba サーバー」の設定なら、[Samba サーバー](#samba-サーバー)の手順 6 で `smbpasswd -a` に入れたパスワード
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. 資格情報ファイルを、root だけが読めるように置く。

   ```bash
   if [ -z "${SMB_USER}" ] || [ -z "${SERVER}" ]; then echo '中断: 手順 1 の SMB_USER か SERVER が空のまま。手順 1 と手順 3 を貼り直す' >&2
   elif [ -z "${PW}" ]; then echo '中断: PW が空のまま。手順 3 を貼り直す' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     printf 'username=%s\npassword=%s\n' "${SMB_USER}" "${PW}" |
       sudo install -m 600 -o root -g root /dev/stdin "/root/smb-${SMB_USER}@${SERVER}.cred" &&
     sudo ls -lZ "/root/smb-${SMB_USER}@${SERVER}.cred"
   fi; unset PW
   ```

   - `-rw------- … root root … admin_home_t … /root/smb-<SMB_USER>@<SERVER>.cred` の 1 行が出ればよい
   - 資格情報ファイルの中身は平文（[注意点](extra/samba-client.md#注意点)）

1. 1 度だけ手でマウントして読み書きを確かめ、外す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
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
   - `ls -ldZ` は `drwx------ … <USER> <USER> … cifs_t …`
   - `mount error(…)` が出たら、ここで止めて原因を直す（表示と原因は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/samba-client.md)・[参考資料](reference/samba-client.md)）
   - `SHARE=home`（Samba サーバーの `[home]`）では、`cifs-test.txt` の書き込みが `Permission denied` になる。`findmnt` の行が出ていればよい

1. `/etc/fstab` に自動マウントの行を足し、systemd に読み直させる。

   ```bash
   if [ -z "${SERVER}" ] || [ -z "${SMB_USER}" ] || [ -z "${SHARE}" ] || [ -z "${MOUNT_POINT}" ]; then
     echo '中断: 手順 1 の変数が空のまま。手順 1 を貼り直す' >&2
   elif grep -q '[[:space:]]' <<< "${SERVER}${SMB_USER}${SHARE}${MOUNT_POINT}"; then
     echo '中断: SERVER / SMB_USER / SHARE / MOUNT_POINT に空白がある（fstab に書けない）' >&2
   elif awk -v mp="${MOUNT_POINT}" '$1 !~ /^#/ && $2 == mp { f = 1 } END { exit !f }' /etc/fstab; then
     echo "中断: /etc/fstab に ${MOUNT_POINT} の行が既にある" >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
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
     printf '\n\033[7m 確認 \033[0m\n'
     sudo systemctl start "$(systemd-escape -p --suffix=automount "${MOUNT_POINT}")" &&
     systemctl is-active "$(systemd-escape -p --suffix=automount "${MOUNT_POINT}")" &&
     ls "${MOUNT_POINT}" > /dev/null && findmnt -R "${MOUNT_POINT}" &&
     echo "automount write" > "${MOUNT_POINT}/automount-test.txt" && cat "${MOUNT_POINT}/automount-test.txt" &&
     rm "${MOUNT_POINT}/automount-test.txt"
     sudo ausearch -m AVC -ts recent
   fi
   ```

   - 通常の共有では、`active`、`findmnt` の `autofs` と `cifs` の 2 行、`automount write` が出ればよい
   - `SHARE=home` では、手順 5 と同じく共有直下への書き込みが `Permission denied` になる。`active` と `findmnt` の 2 行が出ればマウントの確認はできている
   - 最後の `ausearch` は `<no matches>`

#### Samba クライアント: GNOME Files で開く

- クライアントの PC で、Samba の共有を GNOME Files（gvfs）でつなぎ、端末の `gio` で確かめて外す
- 前提: サーバーで[Samba サーバー](#samba-サーバー)を通してある（Windows や NAS の共有でもよい）。[Samba クライアント](#samba-クライアント)の cifs のマウントは要らない
- 実行場所: クライアントの PC の、GNOME にログインした自分のユーザーの端末（bash）
- fstab のマウントとは別の仕組み（gvfs）。ログインしたユーザーがつなぐので、root も資格情報ファイルも要らない
- 画面では「ファイル」（Nautilus）から開く。この項のコマンドは、同じ仕組みを端末から使う `gio`
- この項の手順 1 で変数を設定したシェルで貼る
- **この項の手順 4 には対話入力がある**（ドメインとパスワード）

1. 変数を設定する（`SERVER` は必ず値を入れる）。

   ```bash
   SERVER=192.168.1.10                  # ← 自分の値に書き換える。サーバーの IP アドレスか DNS 名（Samba サーバーの SERVER_IP）。<SERVER>
   ```

   ```bash
   SMB_USER=${USER}                     # サーバーの Samba ユーザー。AlmaLinux の「Samba サーバー」の設定なら、サーバーの OS のユーザー名。<SMB_USER>
   SHARE=${SMB_USER}                    # 共有名。Samba サーバーの [homes] では、ユーザー名と同じ名前の共有になる。<SHARE>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in SERVER USER SMB_USER SHARE; do
     printf '%-11s = %s\n' "$v" "${!v}"
   done
   ```

   - 編集が必須なのは `SERVER` だけ。[Samba クライアント](#samba-クライアント)を通した PC では、その手順 1 と同じ値を入れる
   - サーバーのユーザー名がこの PC と違うとき、NAS や Windows の共有のときは、`SMB_USER` と `SHARE` も書き換える
   - Samba サーバーの[root のホーム](#samba-サーバー-root-のホームも公開する)につなぐときは `SHARE` を `root`、[/home](#samba-サーバー-home-も公開する)につなぐときは `SHARE` を `home` に書き換える（`SMB_USER` は自分のまま）
   - 最後に値を読み戻して確かめる
   - `SERVER` を書き換えたかをここで確かめる
   - `USER` が `root` なら、ここで止めて、自分のユーザーの端末で貼り直す
   - **新しいシェルを開いたら**、この項の手順 1 の 2 つのブロックを貼り直してから先へ進む

1. gvfs-smb と gvfs-fuse が入っているか確かめる。

   ```bash
   rpm -q gvfs-smb gvfs-fuse
   ```

   - `パッケージ … はインストールされていません`（英語の環境では `package … is not installed`）が出たら、この項の手順 3 で入れる
   - 2 つとも版が出たら、この項の手順 3 は飛ばす

1. どちらかが未導入のときだけ、gvfs-smb と gvfs-fuse を入れる。

   ```bash
   sudo dnf install -y gvfs-smb gvfs-fuse
   ```

   - 入れた後、ログインし直さなくてよい

1. 端末から共有をマウントする。

   ```bash
   /usr/bin/gio mount "smb://${SMB_USER:?この項の手順 1 の SMB_USER が空のまま}@${SERVER:?この項の手順 1 の SERVER が空のまま}/${SHARE:?この項の手順 1 の SHARE が空のまま}"
   ```

   - ドメインとパスワードを聞かれる（`Domain [SAMBA]:` と `Password:`。その前に、`認証が必要です`（英語の環境では `Authentication Required`）と、パスワードの入力を求める 1 行が出る）
   - ドメインは、Enter で既定のままでよい
   - パスワードは、共有のパスワード（AlmaLinux の「Samba サーバー」の設定なら、[Samba サーバー](#samba-サーバー)の手順 6 で `smbpasswd -a` に入れたもの）
   - 画面から開くときは、「ファイル」のサイドバーの「Network」を開き、「Server address」の欄に `smb://<SMB_USER>@<SERVER>/<SHARE>` を入れて「接続」を押す
   - 画面では、認証の画面で「期限なしで記憶する」を選ぶと、パスワードが GNOME のキーリングに保存される
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. マウントされたことを確かめる。

   ```bash
   if [ -z "${SERVER}" ] || [ -z "${SMB_USER}" ] || [ -z "${SHARE}" ]; then echo '中断: この項の手順 1 の SERVER・SMB_USER・SHARE を設定してから貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     /usr/bin/gio mount -l | grep -F "${SERVER}"
     ls "/run/user/$(id -u)/gvfs/"
     /usr/bin/gio list "smb://${SMB_USER}@${SERVER}/${SHARE}/"
   fi
   ```

   - `Mount(0): <SERVER> 上の <SHARE> -> smb://<SMB_USER>@<SERVER>/<SHARE>/` の 1 行が出ればよい（英語の環境では `<SHARE> on <SERVER>`）
   - 続いて `smb-share:server=<SERVER>,share=<SHARE>,user=<SMB_USER>`（端末では、`'` で囲まれて出る）と、共有の中の一覧（隠しファイルは出ない）が出る
   - 画面では、サイドバーに共有が出る

1. 共有を外す。

   ```bash
   /usr/bin/gio mount -u "smb://${SMB_USER:?この項の手順 1 の SMB_USER が空のまま}@${SERVER:?この項の手順 1 の SERVER が空のまま}/${SHARE:?この項の手順 1 の SHARE が空のまま}"
   ```

   - 何も出ずに終わればよい
   - 画面では、サイドバーの共有の横の取り出しのボタンで外す

---

### Samba サーバー

- サーバーで、自分のユーザーのホームを Samba（SMB3）で公開する
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)を通してある
- 実行場所: サーバーの、公開するユーザー自身の bash（デスクトップの端末か SSH）。手順 9 だけは、つなぐ側の別のマシン
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/samba.md)・[参考資料](reference/samba.md)・[ロールバックと注意点](extra/samba.md)
- **手順 6 には対話入力がある**（パスワード）。入力し終えてから次の手順を貼る
- `smb3 directory leases` が無い設定済みのサーバーは、[リースを切る手順](#samba-サーバー-設定済みのサーバーでディレクトリのリースを切る)で 1 行だけ足す
- この項の手順 1 で変数を設定したシェルに貼る
- この項の後に行う項:
  - root のホーム（`/root`）も公開するなら、[root のホームも公開する](#samba-サーバー-root-のホームも公開する)を行う
  - `/home` の下のすべてのホーム（ほかのユーザーのホームも）を 1 つの共有で開くなら、[/home も公開する](#samba-サーバー-home-も公開する)を行う
  - サーバーの上で読み書きを確かめるとき（クライアントでつなげないときの切り分けにも）は、[サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)を行う
  - 接続元を絞る場合は、最後に[接続元を絞る](#samba-サーバー-接続元を絞る)を行う
  - 戻すときは[ロールバック](extra/samba.md#ロールバック)

> [!IMPORTANT]
> - **設定済みのサーバーで手順 3 を貼り直さない**。smb.conf 全体が置き換わり、`[root]`・`[home]` も消える

1. 公開するユーザー自身のシェルで、変数を設定する（`sudo -i` した root のシェルでは貼らない）。

   ```bash
   WORKGROUP=WORKGROUP                 # Windows 側のワークグループ名。既定のままでよいことが多い
   SERVER_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p')   # 検証と案内に使う（自動）。<SERVER_IP>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in WORKGROUP USER SERVER_IP; do
     printf '%-10s = %s\n' "$v" "${!v}"
   done
   ```

   - 最後に値を読み戻して確かめる
   - `USER` が `root` になっている、`SERVER_IP` が空、または意図した NIC の IP でないなら、ここで止めて直す
   - root のホームも公開したいときも、ここでは自分のユーザーで進める。root のホームは、この項の後に[root のホームも公開する](#samba-サーバー-root-のホームも公開する)で足す
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、手順 1 のブロックを貼り直してから先へ進む

1. samba・samba-client・cifs-utils を入れる。

   ```bash
   {
     sudo dnf install -y samba samba-client cifs-utils
     printf '\n\033[7m 確認 \033[0m\n'
     rpm -q samba samba-client cifs-utils
   }
   ```

1. 既定の smb.conf を退避して最小構成に置き換え、構文を検査する。

   ```bash
   if [ -z "${WORKGROUP}" ]; then echo '中断: 手順 1 の WORKGROUP が空のまま。値を入れて貼り直す' >&2; else
     sudo cp -an /etc/samba/smb.conf /etc/samba/smb.conf.orig
     sudo tee /etc/samba/smb.conf >/dev/null <<EOF
   [global]
       workgroup = ${WORKGROUP:?手順 1 の WORKGROUP が空のまま。値を入れて貼り直す}
       security = user
       passdb backend = tdbsam
       server smb transports = tcp
       load printers = no
       printing = bsd
       printcap name = /dev/null
       disable spoolss = yes
       smb3 directory leases = no

   [homes]
       comment = Home Directories
       valid users = %S
       browseable = No
       read only = No
       create mask = 0644
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     testparm -s
   fi
   ```

   - `Loaded services file OK.` と `Server role: ROLE_STANDALONE` が出て、`[global]` に `smb3 directory leases = No` があればよい
   - `中断:` と出たら、何も書いていない

1. SELinux の boolean `samba_enable_home_dirs` を on にする。

   ```bash
   {
     sudo setsebool -P samba_enable_home_dirs on
     printf '\n\033[7m 確認 \033[0m\n'
     sudo getsebool samba_enable_home_dirs        # samba_enable_home_dirs --> on
   }
   ```

1. firewalld で 445/tcp を開ける。

   ```bash
   {
     sudo firewall-cmd --permanent --add-port=445/tcp && sudo firewall-cmd --reload
     printf '\n\033[7m 確認 \033[0m\n'
     sudo firewall-cmd --list-ports               # 445/tcp が含まれる
   }
   ```

1. OS のアカウントを確かめ、Samba ユーザーを登録する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   id "${USER}"
   sudo smbpasswd -a "${USER}"
   ```

   - `id` で、OS のアカウントが存在することを確かめる
   - **端末で対話入力する**。新しいパスワードを 2 回聞かれる
   - **次の手順は、2 回の入力を終えてから貼る**（続けて貼るとパスワードとして食われる）

1. Samba ユーザーが登録されたか確かめる。

   ```bash
   sudo pdbedit -L                              # <USER>:1000: の 1 行が出る
   ```

   - `<USER>:1000:` の 1 行が出ればよい

1. smb.service を有効にして起動する。

   ```bash
   {
     sudo systemctl enable --now smb.service
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl is-active smb.service              # active
     ss -ltnp | grep -E ':(139|445) '             # 445 だけが LISTEN。139 は出ない
   }
   ```

1. 別のマシンから、クライアントで接続する。

   - `<SERVER_IP>` と `<USER>` は値に読み替える
   - Windows: エクスプローラーのアドレス欄に `\\<SERVER_IP>\<USER>`。資格情報は `<USER>` と手順 6 のパスワード
     - ドライブ文字に割り当てて、サインインのたびにつなぐなら、[Samba クライアントの Windows 11 で使う](#windows-11-で-samba-クライアントを使う)
   - macOS: Finder の「サーバへ接続」に `smb://<SERVER_IP>/<USER>`
   - Android / iOS: ファイルアプリの SMB 接続先に `<SERVER_IP>`、共有名 `<USER>`
   - Linux: AlmaLinux 10 なら[Samba クライアント](#samba-クライアント)を通す（自動マウント・GNOME Files）
   - ほかは `smbclient "//<SERVER_IP>/<USER>" -U <USER>` または `mount -t cifs "//<SERVER_IP>/<USER>" <mountpoint> -o username=<USER>`
   - WireGuard 越しに接続するときは `<SERVER_IP>` を `<WG_IP>` に読み替える（クライアント側の `AllowedIPs` にトンネル網が入っていることが前提。[WireGuard の手順書](wireguard.md#wireguard)）
   - つなげないときは、[サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)で、サーバーの上から読み書きを確かめる

#### Samba サーバー: root のホームも公開する

- サーバーで、`\\<SERVER_IP>\root` で `/root` を読み書きできるようにする。つなぐのは[Samba サーバー](#samba-サーバー)の手順 6 で登録した自分の Samba ユーザーのままで、root の Samba ユーザーは作らない
- 前提: [Samba サーバー](#samba-サーバー)を通してある
- 実行場所: サーバーの、公開したユーザー自身の bash（デスクトップの端末か SSH）。`${USER}` を `valid users` に書く。この項の手順 4 だけは、つなぐ側の別のマシン
- **root のホーム（`/root`）を公開しないなら、この項は不要**
- smbd は、この共有の中を root として読み書きする（`force user = root`）。作ったファイルは root の所有になる
- `/root` の読み書きは、この項の手順 3 の後に、[サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 8・9 で確かめる
- 補足: [root のホームを公開するときの補足](reference/samba.md#root-のホームを公開するときの補足)

> [!WARNING]
> - Samba のパスワードは root のパスワードと同じ重みになる。`/root/.bashrc`・`/root/.ssh/authorized_keys` の書き換えで root の任意コマンドを動かせる
> - パスワードを長くし、[接続元の制限](#samba-サーバー-接続元を絞る)も検討する

1. smb.conf の末尾に `[root]` 共有を足し、構文を検査する。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。公開したユーザー自身のシェルで貼る' >&2
   elif grep -q '^\[root\]' /etc/samba/smb.conf; then echo '中断: /etc/samba/smb.conf に [root] が既にある' >&2
   else
     sudo tee -a /etc/samba/smb.conf >/dev/null <<EOF

   [root]
       comment = Home of root
       path = /root
       valid users = ${USER}
       force user = root
       browseable = No
       read only = No
       create mask = 0644
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     testparm -s
   fi
   ```

   - `testparm -s` の末尾に `[root]` の節が出て、`force user = root` と `valid users = <USER>` があればよい
   - `中断:` と出たら、何も書き換えていない

1. SELinux で、smbd に `/root`（`admin_home_t`）の読み書きを許すモジュールを入れる。

   ```bash
   {
     cat > /tmp/samba_root_home.cil <<'EOF'
   (allow smbd_t admin_home_t (dir (add_name create getattr ioctl link lock open read remove_name rename reparent rmdir search setattr unlink watch watch_reads write)))
   (allow smbd_t admin_home_t (file (append create getattr ioctl link lock open read rename setattr unlink watch watch_reads write)))
   (allow smbd_t admin_home_t (lnk_file (append create getattr ioctl link lock read rename setattr unlink watch watch_reads write)))
   EOF
     sudo semodule -i /tmp/samba_root_home.cil
     rm /tmp/samba_root_home.cil
     printf '\n\033[7m 確認 \033[0m\n'
     sudo semodule -l | grep -x samba_root_home   # samba_root_home
   }
   ```

   - 最後に `samba_root_home` の 1 行が出ればよい
   - `semodule -i` は、終わるまでしばらく何も出さない

1. smb.service を再起動する。

   ```bash
   sudo systemctl restart smb.service
   ```

   - 再起動すると、ほかのクライアントのつないでいる接続が切れる
   - `/root` の一覧と書き込みは、[サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 8・9 で確かめる

1. 別のマシンから、共有名 `root` でつなぐ。

   - [Samba サーバー](#samba-サーバー)の手順 9 の `<USER>`（共有名）を `root` に読み替える。資格情報は `<USER>` と[Samba サーバー](#samba-サーバー)の手順 6 のパスワードのまま
   - Windows: エクスプローラーのアドレス欄に `\\<SERVER_IP>\root`
   - AlmaLinux 10 の PC なら、[Samba クライアント](#samba-クライアント)の手順 1 で `SHARE=root` にする（`SMB_USER` は自分のまま）

1. 元に戻すときは、`[root]` の節とモジュールを消し、smb.service を再起動する。

   ```bash
   {
     sudo sed -i '/^\[root\]$/,/^\[/{/^\[root\]$/d;/^\[/!d}' /etc/samba/smb.conf
     printf '\n\033[7m 確認 \033[0m\n'
     sudo semodule -r samba_root_home
     sudo systemctl restart smb.service
     testparm -s 2>/dev/null | grep -c '^\[root\]'   # 0
   }
   ```

   - 最後に `0` と出ればよい
   - `semodule -r` は約 50 秒（VM）かかり、`libsemanage.semanage_direct_remove_key: Removing last samba_root_home module …` と出る。エラーではない

#### Samba サーバー: /home も公開する

- サーバーで、`\\<SERVER_IP>\home` で `/home` を開き、その下のすべてのユーザーのホームを読み書きできるようにする。つなぐのは[Samba サーバー](#samba-サーバー)の手順 6 で登録した自分の Samba ユーザーのままで、ほかのユーザーは Samba に登録しなくてよい
- 前提: [Samba サーバー](#samba-サーバー)を通してある
- 実行場所: サーバーの、公開したユーザー自身の bash（デスクトップの端末か SSH）。`${USER}` を `valid users` に書く。この項の手順 3 だけは、つなぐ側の別のマシン
- **`/home` を公開しないなら、この項は不要**
- smbd は、この共有の中を root として読み書きする（`force user = root`）
- 新しく作ったファイルとディレクトリの所有者は、親ディレクトリの所有者（`/home/<ユーザー>` の中なら、そのユーザー）になる（`inherit owner = yes`）。グループは `root` になる
- `/home` の直下には、ファイルもディレクトリも作れない（SELinux が断る）
- 読み書きは、この項の手順 2 の後に、[サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 10・11 で確かめる
- 補足: [/home を公開するときの補足](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/samba.md#home-を公開するときの補足)

> [!WARNING]
> - Samba のパスワードで、ほかのユーザーの `~/.bashrc`・`~/.ssh/authorized_keys` も読み書きできる
> - `sudo` が使えるユーザーのホームを書き換えると、root で任意のコマンドを動かせる。長いパスワードと[接続元の制限](#samba-サーバー-接続元を絞る)を検討する

1. smb.conf の末尾に `[home]` 共有を足し、構文を検査する。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。公開したユーザー自身のシェルで貼る' >&2
   elif grep -q '^\[home\]' /etc/samba/smb.conf; then echo '中断: /etc/samba/smb.conf に [home] が既にある' >&2
   else
     sudo tee -a /etc/samba/smb.conf >/dev/null <<EOF

   [home]
       comment = /home
       path = /home
       valid users = ${USER}
       force user = root
       inherit owner = yes
       browseable = No
       read only = No
       create mask = 0644
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     testparm -s
   fi
   ```

   - `testparm -s` の末尾に `[home]` の節が出て、`force user = root`・`inherit owner = windows and unix`・`valid users = <USER>` があればよい
   - `中断:` と出たら、何も書き換えていない

1. smb.service を再起動する。

   ```bash
   sudo systemctl restart smb.service
   ```

   - 再起動すると、ほかのクライアントのつないでいる接続が切れる
   - `/home` の一覧と書き込みは、[サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 10・11 で確かめる

1. 別のマシンから、共有名 `home` でつなぐ。

   - [Samba サーバー](#samba-サーバー)の手順 9 の `<USER>`（共有名）を `home` に読み替える。資格情報は `<USER>` と[Samba サーバー](#samba-サーバー)の手順 6 のパスワードのまま
   - Windows: エクスプローラーのアドレス欄に `\\<SERVER_IP>\home`。ユーザーごとのフォルダーが並ぶ。フォルダーの外（`/home` の直下）には作れない
   - AlmaLinux 10 は[Samba クライアント](#samba-クライアント)の手順 1 で `SHARE=home` にし、`SMB_USER` は自分のままにする
   - [Samba クライアント](#samba-クライアント)の手順 5・7 の共有直下への書き込みは `Permission denied` になる

1. 元に戻すときは、`[home]` の節を消し、smb.service を再起動する。

   ```bash
   {
     sudo sed -i '/^\[home\]$/,/^\[/{/^\[home\]$/d;/^\[/!d}' /etc/samba/smb.conf
     sudo systemctl restart smb.service
     printf '\n\033[7m 確認 \033[0m\n'
     testparm -s 2>/dev/null | grep -c '^\[home\]'   # 0
   }
   ```

   - 最後に `0` と出ればよい

#### Samba サーバー: サーバーの上で動作を確かめる

- サーバーの上の `smbclient` と `mount.cifs` で、共有の読み書きを確かめる（クライアントでつなげないときの切り分けにも使う）
- 前提: [Samba サーバー](#samba-サーバー)を通してある
- 実行場所: サーバーの、公開したユーザー自身の bash（デスクトップの端末か SSH）
- **この項の手順 2・8・10 には対話入力がある**（パスワード）
- この項の手順 8・9 は、[root のホームも公開した](#samba-サーバー-root-のホームも公開する)ときだけ行う
- この項の手順 10・11 は、[/home も公開した](#samba-サーバー-home-も公開する)ときだけ行う
- サーバー自身からの接続は firewalld を通らない（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/samba.md)・[参考資料](reference/samba.md)）

1. 変数を設定する。

   ```bash
   SERVER_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p')   # 検証に使う（自動）。<SERVER_IP>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in USER SERVER_IP; do
     printf '%-10s = %s\n' "$v" "${!v}"
   done
   ```

   - 最後に値を読み戻して確かめる
   - `USER` が `root` なら、ここで止めて、公開したユーザー自身のシェルで貼り直す
   - `SERVER_IP` が空か、意図した NIC の IP でないなら、[Samba サーバー](#samba-サーバー)の手順 1 と同じ値に直す
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、この項の手順 1 を貼り直してから先へ進む

1. 資格情報ファイルを作るため、[Samba サーバー](#samba-サーバー)の手順 6 で登録したパスワードを入力する。

   ```bash
   AUTHFILE=/run/user/$(id -u)/smb-auth
   read -rsp "Samba password for ${USER}: " PW; echo
   ```

   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. 資格情報ファイルを作る。

   ```bash
   ( umask 077; printf 'username=%s\npassword=%s\n' "${USER}" "${PW}" > "${AUTHFILE}" ); unset PW
   printf '\n\033[7m 確認 \033[0m\n'
   ls -l "${AUTHFILE}"                          # -rw------- で自分の所有
   ```

1. `smbclient` で、共有の一覧と読み書きを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   smbclient -L //localhost -A "${AUTHFILE}"    # IPC$ と <USER> の 2 つだけ出る
   smbclient "//localhost/${USER}" -A "${AUTHFILE}" -c 'ls'
   smbclient "//localhost/${USER}" -A "${AUTHFILE}" -c "put /etc/hostname smb-test.txt; get smb-test.txt /tmp/smb-test.txt; ls smb-test.txt"
   ls -lZ ~/smb-test.txt /tmp/smb-test.txt      # -rw-r--r--。ホーム側は user_home_t、/tmp 側は user_tmp_t
   cmp /etc/hostname /tmp/smb-test.txt && echo "content identical"
   smbclient "//${SERVER_IP}/${USER}" -A "${AUTHFILE}" -c 'ls smb-test.txt'
   ```

1. `mount.cifs` でマウントして書き込み、`smbstatus` でセッションを確かめる。

   ```bash
   {
     sudo mkdir -p /mnt/smbtest
     sudo mount -t cifs "//127.0.0.1/${USER}" /mnt/smbtest -o "credentials=${AUTHFILE},uid=$(id -u),gid=$(id -g)"
     printf '\n\033[7m 確認 \033[0m\n'
     mount | grep cifs                            # vers=3.1.1
     echo "cifs write" > /mnt/smbtest/cifs-test.txt && cat /mnt/smbtest/cifs-test.txt
     ls -lZ /mnt/smbtest/cifs-test.txt ~/cifs-test.txt
     sudo smbstatus                               # Protocol Version: SMB3_11、Signing: partial(AES-128-CMAC)
   }
   ```

   - **次の手順は、`smbstatus` の出力を確かめてから貼る**（この項の手順 6 でアンマウントすると見えなくなる）

1. アンマウントして、マウントポイントを消す。

   ```bash
   sudo umount /mnt/smbtest && sudo rmdir /mnt/smbtest
   ```

1. 後片付けとして、検証で作ったファイルと資格情報ファイルを消し、AVC を確かめる。

   ```bash
   rm -f ~/smb-test.txt ~/cifs-test.txt /tmp/smb-test.txt "${AUTHFILE}"
   printf '\n\033[7m 確認 \033[0m\n'
   sudo ausearch -m AVC -ts today               # <no matches>
   ```

   - root のホームを公開していないなら、この項の手順 8・9 は飛ばす
   - `/home` を公開していないなら、この項の手順 10・11 は飛ばす

1. root のホームも公開したときだけ、自分の Samba ユーザーで `/root` の一覧と書き込みを確かめる。

   ```bash
   smbclient //localhost/root -U "${USER}" -c 'ls; put /etc/hostname smb-root-test.txt; ls smb-root-test.txt'
   ```

   - パスワードは、[Samba サーバー](#samba-サーバー)の手順 6 で登録した `<USER>` の Samba のパスワード
   - `/root` の中身（`.bashrc` や `.ssh` など）の一覧に続いて、`putting file /etc/hostname as \smb-root-test.txt` と `smb-root-test.txt` の 1 行が出ればよい
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. root のホームも公開したときだけ、作ったファイルの所有者とラベルを確かめて消し、AVC を確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo ls -lZ /root/smb-root-test.txt          # -rw-r--r--. root root … admin_home_t
     sudo rm /root/smb-root-test.txt
     sudo ausearch -m AVC -ts recent              # <no matches>
   }
   ```

   - ファイルは `root root` の所有で、ラベルは `admin_home_t`
   - `ausearch` が `<no matches>` ならよい
   - `/home` を公開していないなら、この項の手順 10・11 は飛ばす

1. `/home` も公開したときだけ、`/home` の一覧と、自分のホームへの書き込みを確かめる。

   ```bash
   smbclient //localhost/home -U "${USER}" -c "ls; put /etc/hostname ${USER}/smb-home-test.txt; ls ${USER}/smb-home-test.txt"
   ```

   - パスワードは、[Samba サーバー](#samba-サーバー)の手順 6 で登録した `<USER>` の Samba のパスワード
   - `/home` の中のユーザーのディレクトリ（`<USER>` など）の一覧に続いて、`putting file /etc/hostname as \<USER>\smb-home-test.txt` と `smb-home-test.txt` の 1 行が出ればよい
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. `/home` も公開したときだけ、作ったファイルの所有者とラベルを確かめて消し、AVC を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   ls -lZ ~/smb-home-test.txt                   # -rw-r--r--. <USER> root … user_home_t
   rm ~/smb-home-test.txt
   sudo ausearch -m AVC -ts recent              # <no matches>
   ```

   - ファイルの所有者は `<USER>`（root ではない）、グループは `root`、ラベルは `user_home_t`
   - `ausearch` が `<no matches>` ならよい

#### Samba サーバー: 接続元を絞る

- サーバーで、445/tcp に届く送信元を、指定したサブネットだけに絞る
- 前提: [Samba サーバー](#samba-サーバー)を通してある
- 実行場所: サーバーの、自分のユーザーの bash（デスクトップの端末か SSH）
- **接続元を制限しないなら、この項は不要**
- [Samba サーバー](#samba-サーバー)の手順 5 は、public ゾーンに属するすべての NIC（この環境では `end0` と `wg0`）で 445/tcp を開く
- 補足: [接続元を絞るときの補足](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/samba.md#接続元を絞るときの補足)

1. 送信元サブネットを空白区切りで入れ、445/tcp の開放を rich rule に置き換える。

   ```bash
   ALLOW_FROM="192.168.1.0/24 10.99.0.0/30"     # ← 自分の値に書き換える。<ALLOW_FROM>
   ```

   ```bash
   if [ -z "${ALLOW_FROM}" ]; then echo '中断: ALLOW_FROM が空のまま。値を入れて貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-port=445/tcp
   for src in ${ALLOW_FROM}; do
     sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=${src} port port=445 protocol=tcp accept"
   done
   sudo firewall-cmd --reload
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --list-rich-rules        # source address に実際のサブネットが入っていることを確認する
   fi
   ```

1. 元に戻すときは、絞ったときと同じ `ALLOW_FROM` を入れてから、public ゾーン全体の 445/tcp に戻す。

   ```bash
   if [ -z "${ALLOW_FROM}" ]; then echo '中断: ALLOW_FROM が空のまま。絞ったときと同じ値を入れて貼り直す' >&2; else
   for src in ${ALLOW_FROM}; do
     sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=${src} port port=445 protocol=tcp accept"
   done
   sudo firewall-cmd --permanent --add-port=445/tcp && sudo firewall-cmd --reload
   fi
   ```

#### Samba サーバー: 設定済みのサーバーでディレクトリのリースを切る

- サーバーで、設定済みの smb.conf の `[global]` に `smb3 directory leases = no` の 1 行だけを足す（理由は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/samba.md)・[参考資料](reference/samba.md)）
- 前提: [Samba サーバー](#samba-サーバー)を、この 1 行が入る前の手順で通してある
- 実行場所: サーバーの bash（デスクトップの端末か SSH）。変数を使わないので、どのユーザーのシェルで貼ってもよい
- **smb.conf に `smb3 directory leases` の行が無いサーバーだけ**。今の[Samba サーバー](#samba-サーバー)の手順 3 には、この 1 行が入っている
- [Samba サーバー](#samba-サーバー)の手順 3 は貼り直さない
- **この項の手順 2 で smb.service を再起動すると、つないでいるクライアントの接続が一度切れる**

1. smb.conf の `[global]` に 1 行を足し、構文を検査する。

   ```bash
   if grep -qiE '^[[:space:]]*smb3[[:space:]]+directory[[:space:]]+leases' /etc/samba/smb.conf; then echo '中断: /etc/samba/smb.conf に smb3 directory leases の行が既にある' >&2
   elif ! grep -q '^\[global\]$' /etc/samba/smb.conf; then echo '中断: /etc/samba/smb.conf に [global] の行が無い' >&2
   else
     sudo sed -i '/^\[global\]$/a\    smb3 directory leases = no' /etc/samba/smb.conf
     printf '\n\033[7m 確認 \033[0m\n'
     testparm -s 2>/dev/null | grep 'smb3 directory leases'
   fi
   ```

   - `smb3 directory leases = No` の 1 行が出ればよい
   - `中断:` と出たら、何も書き換えていない
   - `… 既にある` で止まったら、その行が `smb3 directory leases = no` かを見る。`no` なら、この項の手順 2 へ進む

1. smb.service を再起動する。

   ```bash
   {
     sudo systemctl restart smb.service
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl is-active smb.service              # active
   }
   ```

   - `active` と出ればよい

1. 元に戻すときは、足した行を消して smb.service を再起動する。

   ```bash
   {
     sudo sed -i '/^[[:space:]]*smb3 directory leases = no$/d' /etc/samba/smb.conf
     sudo systemctl restart smb.service
     printf '\n\033[7m 確認 \033[0m\n'
     testparm -s 2>/dev/null | grep -c 'smb3 directory leases'   # 0
   }
   ```

   - 最後に `0` と出ればよい
   - 今の[Samba サーバー](#samba-サーバー)の手順 3 で置いた smb.conf の行も消える
   - 再起動すると、つないでいるクライアントの接続が一度切れる

---

## Windows 11 で使う

- Samba のクライアント

### Windows 11 で Samba クライアントを使う

- Samba の共有をドライブ文字に割り当て、サインインのたびにつなぎ直す
- 前提: サーバーで [Samba サーバー](#samba-サーバー)を通してある。外出先では、[WireGuard: Windows 11 でトンネルを確かめる](wireguard.md#wireguard-windows-11-でトンネルを確かめる)に従ってトンネルを張り、サーバーにつながる状態にしてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。手順 7 はサーバーの bash、手順 8 はこの PC のデスクトップ
- パスワードは Windows の資格情報マネージャーに置く
- Samba サーバーの `[root]`・`[home]` も割り当てるなら、この項を通した後に、この項の手順 2 の 3 つ目のブロックの `SHARE` と `DRIVE` を書き換えて貼り、この項の手順 3・5・6 を貼り直す（資格情報は同じなので、手順 4 は要らない）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/samba-client.md)・[参考資料](reference/samba-client.md)・[ロールバックと注意点](extra/samba-client.md)

> [!IMPORTANT]
> **管理者の窓で割り当てたドライブは、エクスプローラーに出ない**。管理者ではない窓で行う。

1. Windows で、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にしない）
   - Windows Terminal の管理者のタブや、`sudo` で開いた窓も使わない

1. 変数を設定する（`SERVER` と `SMB_USER` は必ず値を入れる）。

   ```powershell
   $SERVER = ''                          # ← サーバーの IP アドレスか DNS 名（Samba サーバーの SERVER_IP）。<SERVER>
   ```

   ```powershell
   $SMB_USER = ''                        # ← サーバーの Samba ユーザー（AlmaLinux の「Samba サーバー」の設定なら、サーバーの OS のユーザー名）。<SMB_USER>
   ```

   ```powershell
   $SHARE = $SMB_USER                    # 共有名。Samba サーバーの [homes] では、ユーザー名と同じ名前の共有になる。<SHARE>
   $DRIVE = 'Z:'                         # 割り当てるドライブ文字（コロンまで書く）。<DRIVE>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'SERVER   = {0}' -f $SERVER
   'SMB_USER = {0}' -f $SMB_USER
   'SHARE    = {0}' -f $SHARE
   'DRIVE    = {0}' -f $DRIVE
   ```

   - 最後に値を読み戻して確かめる
   - `SMB_USER` は、Windows のユーザー名ではなく、サーバーの Samba ユーザーにする
   - [root のホーム](#samba-サーバー-root-のホームも公開する)なら `SHARE=root`、[/home](#samba-サーバー-home-も公開する)なら `SHARE=home` にする
   - `SMB_USER` は自分のまま。`DRIVE` はほかの割り当てと違う文字にする
   - `SERVER` は、エクスプローラーで `\\<SERVER>\…` を開くときと同じ書き方にする
   - **新しい PowerShell を開いたら**、この項の手順 2 の 3 つのブロックを貼り直してから先へ進む

1. 管理者ではないことと、サーバーの 445 番・ドライブ文字・保存済みの資格情報を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $SERVER -or -not $SMB_USER -or -not $SHARE -or -not $DRIVE) {
     Write-Error '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す'
   } elseif (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
     Write-Error '中断: 管理者の窓で開いている。この項の手順 1 で、管理者ではない窓を開き直す'
   } elseif ($DRIVE -notmatch '^[A-Za-z]:$') {
     Write-Error '中断: この項の手順 2 の DRIVE は、Z: のようにドライブ文字とコロンにする'
   } elseif (-not (Test-NetConnection -ComputerName $SERVER -Port 445 -WarningAction SilentlyContinue).TcpTestSucceeded) {
     Write-Error "中断: $SERVER の 445/tcp に届かない"
   } elseif ((Test-Path -LiteralPath "$DRIVE\") -or (Get-SmbMapping -LocalPath $DRIVE -ErrorAction SilentlyContinue)) {
     Write-Error "中断: $DRIVE はもう使われている（切れたまま覚えている割り当ても含む）"
   } else {
     "$SERVER の 445/tcp に届く。$DRIVE は空いている"
     cmdkey "/list:$SERVER"
   }
   ```

   - `<SERVER> の 445/tcp に届く。<DRIVE> は空いている` と、`<SERVER>` の資格情報の一覧が出ればよい
   - 一覧にある `<SERVER>` の保存済み資格情報は、この項の手順 4 で置き換わり、[ロールバック](extra/samba-client.md#windows-11-のロールバック)の手順 2 で消える
   - `445/tcp に届かない` ときは、`SERVER` の値と、サーバーの firewalld と smbd（[Samba サーバー 手順 5・8](#samba-サーバー)）を確かめる。外出先なら、先に WireGuard のトンネルを張る
   - `もう使われている` ときは、`DRIVE` を別の文字にして、この項の手順 2 の 3 つ目のブロックを貼り直す。前にこの項で同じ共有を割り当てたなら、この項は済んでいる

1. 資格情報マネージャーに、共有のユーザー名とパスワードを登録する。

   ```powershell
   if (-not $SERVER -or -not $SMB_USER) {
     Write-Error '中断: この項の手順 2 の SERVER か SMB_USER が空のまま。値を入れて貼り直す'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     cmdkey "/add:$SERVER" "/user:$SMB_USER" /pass
   }
   ```

   - パスワードを聞かれる。AlmaLinux の「Samba サーバー」の設定なら、[Samba サーバー 手順 6](#samba-サーバー) で `smbpasswd -a` に入れたパスワード
   - 資格情報を追加した旨の 1 行が出ればよい
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. 共有をドライブ文字に割り当て、サインインのたびにつなぎ直すようにする。

   ```powershell
   if (-not $SERVER -or -not $SHARE -or -not $DRIVE) {
     Write-Error '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     New-SmbMapping -LocalPath $DRIVE -RemotePath "\\$SERVER\$SHARE" -Persistent $true | Out-Null
     Get-SmbMapping -LocalPath $DRIVE | Format-Table Status, LocalPath, RemotePath
   }
   ```

   - `OK`・`<DRIVE>`・`\\<SERVER>\<SHARE>` の 1 行が出ればよい
   - ユーザー名かパスワードが違うと断られたら、この項の手順 4 を貼り直してから、この手順を貼り直す
   - エラー 1219 が出たら、[注意点](extra/samba-client.md#注意点)の Windows 11 のエラー 1219 を見る
   - エクスプローラーには、この項の手順 8 でサインインし直すまで出ないことがある

1. 割り当てたドライブで読み書きできることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $DRIVE) {
     Write-Error '中断: この項の手順 2 の DRIVE が空のまま。値を入れて貼り直す'
   } else {
     Get-ChildItem -LiteralPath "$DRIVE\" | Select-Object -First 5 -ExpandProperty Name
     Set-Content -LiteralPath "$DRIVE\smb-win-test.txt" -Value 'smb write' -Encoding ascii
     Get-Content -LiteralPath "$DRIVE\smb-win-test.txt"
     Remove-Item -LiteralPath "$DRIVE\smb-win-test.txt"
     Test-Path -LiteralPath "$DRIVE\smb-win-test.txt"
   }
   ```

   - 共有の中の名前（5 つまで。隠しファイルは出ない）、`smb write`、`False` の順に出ればよい
   - `SHARE=home`（Samba サーバーの `[home]`）では、書き込みが拒否される。名前の一覧が出ていればよい

1. サーバーで、署名付きの SMB3_11 でつながっていることを確かめる。

   ```bash
   sudo smbstatus
   ```

   - サーバーのシェルに貼る
   - この PC の IP アドレスの行の `Protocol Version` が `SMB3_11` で、`Signing` が `AES-128-GMAC` などの方式の名前だけ（`partial(…)` でも `-` でもない）ならよい
   - `Encryption` は `-`（LAN の上の通信は暗号化されない。[Samba サーバーの注意点](extra/samba.md#注意点)）
   - Windows 11 Home の PC では、`Signing` が `partial(…)` か `-` になりうる（[注意点](extra/samba-client.md#注意点)）
   - この PC の行が無ければ、エクスプローラーかこの PC の PowerShell で `<DRIVE>` を開いてから、貼り直す

1. サインアウトしてサインインし直し、ドライブがパスワード無しで開くことを確かめる。

   - スタートメニューの自分のアイコンから「サインアウト」を選び、もう一度サインインする
   - エクスプローラーの「PC」の「ネットワークの場所」に、`<SHARE> (\\<SERVER>) (<DRIVE>)` のような名前でドライブが出ればよい
   - 開いたときにパスワードを聞かれなければよい
   - 赤い × が付いているときは、サインインのときにサーバーに届かなかった（[注意点](extra/samba-client.md#注意点)）

#### Samba クライアント: Windows 11 の更新

- Samba サーバーで変えたパスワードを、Windows の資格情報マネージャーにも入れ直す
- 前提: [Samba クライアント](#windows-11-で-samba-クライアントを使う)を通し、サーバーで Samba のパスワードを変えてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。手順 4 はこの PC のデスクトップ
- SMB のクライアントは Windows Update で上がる。この項で上げるものは無い

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`SERVER`・`SMB_USER` は必ず値を入れる）。

   ```powershell
   $SERVER = ''
   ```

   ```powershell
   $SMB_USER = ''
   ```

   ```powershell

   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ SERVER = $SERVER; SMB_USER = $SMB_USER } | Format-List
   ```

   - `SERVER` と `SMB_USER` は、[Samba クライアント](#windows-11-で-samba-クライアントを使う)の手順 2 と同じ値を入れる
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. Samba のパスワードを変えたときだけ、資格情報を登録し直す。

   ```powershell
   if (-not $SERVER -or -not $SMB_USER) {
     Write-Error '中断: この項の手順 2 の SERVER か SMB_USER が空のまま。値を入れて貼り直す'
   } else {
     cmdkey "/add:$SERVER" "/user:$SMB_USER" /pass
   }
   ```

   - サーバーで変えた後の新しいパスワードを入れる
   - パスワードを入力し終えてから、この項の手順 4 を行う

1. サインアウトしてサインインし直し、ドライブがパスワード無しで開くことを確かめる。

   - [Windows 11 で使う](#windows-11-で-samba-クライアントを使う)の手順 8 と同じ

---
