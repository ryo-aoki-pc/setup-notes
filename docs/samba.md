# Samba でホームディレクトリを公開する手順（`[homes]` 共有 / smbd + firewalld）

## 実施手順

- [検証記録](verification/samba.md)・[参考資料](reference/samba.md)

> [!IMPORTANT]
> - **すべてサーバー上で実行する**。手順 9（クライアントからの接続）だけ別マシン
> - **手順 6 には対話入力がある**（パスワード）。入力し終えてから次の手順を貼る
> - **手順を終えたサーバーでは、手順 3 を貼り直さない**（smb.conf が丸ごと置き換わり、`[root]`・`[home]` なども消える）。smb.conf に `smb3 directory leases` の行が無いサーバーには、[設定済みのサーバーでディレクトリのリースを切る](#設定済みのサーバーでディレクトリのリースを切る)で 1 行だけ足す

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後の節:
  - root のホーム（`/root`）も公開するなら、[root のホームも公開する（任意）](#root-のホームも公開する任意)を行う
  - `/home` の下のすべてのホーム（ほかのユーザーのホームも）を 1 つの共有で開くなら、[/home も公開する（任意）](#home-も公開する任意)を行う
  - サーバーの上で読み書きを確かめるとき（クライアントでつなげないときの切り分けにも）は、[サーバーの上で動作を確かめる](#サーバーの上で動作を確かめる)を行う
  - 接続元を絞る場合は、最後に[接続元を絞る（任意）](#接続元を絞る任意)を行う
  - 戻すときは[ロールバック](#ロールバック)

1. 公開するユーザー自身のシェルで、変数を設定する（`sudo -i` した root のシェルでは貼らない）。

   ```bash
   WORKGROUP=WORKGROUP                 # Windows 側のワークグループ名。既定のままでよいことが多い
   SERVER_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p')   # 検証と案内に使う（自動）。<SERVER_IP>
   for v in WORKGROUP USER SERVER_IP; do
     printf '%-10s = %s\n' "$v" "${!v}"
   done
   ```

   - 最後に値を読み戻して確かめる
   - `USER` が `root` になっている（root のホームを公開してしまう）、`SERVER_IP` が空、または意図した NIC の IP でないなら、ここで止めて直す
   - root のホームも公開したいときも、ここでは自分のユーザーで進める。root のホームは、手順の後の[root のホームも公開する（任意）](#root-のホームも公開する任意)で足す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**（SSH を張り直したあとも）、手順 1 のブロックを貼り直してから先へ進む

1. samba・samba-client・cifs-utils を入れる。

   ```bash
   {
     sudo dnf install -y samba samba-client cifs-utils
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
     testparm -s
   fi
   ```

   - `Loaded services file OK.` と `Server role: ROLE_STANDALONE` が出て、`[global]` に `smb3 directory leases = No` があればよい
   - `中断:` と出たら、何も書いていない

1. SELinux の boolean `samba_enable_home_dirs` を on にする。

   ```bash
   {
     sudo setsebool -P samba_enable_home_dirs on
     sudo getsebool samba_enable_home_dirs        # samba_enable_home_dirs --> on
   }
   ```

1. firewalld で 445/tcp を開ける。

   ```bash
   {
     sudo firewall-cmd --permanent --add-port=445/tcp && sudo firewall-cmd --reload
     sudo firewall-cmd --list-ports               # 445/tcp が含まれる
   }
   ```

1. OS のアカウントを確かめ、Samba ユーザーを登録する。

   ```bash
   id "${USER}"
   sudo smbpasswd -a "${USER}"
   ```

   - `id` で、OS のアカウントが存在することを確かめる
   - **端末で対話入力する**。新しいパスワードを 2 回聞かれる
   - Samba のパスワードは、OS のパスワードとは別に保存される
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
     systemctl is-active smb.service              # active
     ss -ltnp | grep -E ':(139|445) '             # 445 だけが LISTEN。139 は出ない
   }
   ```

1. 別のマシンから、クライアントで接続する。

   - `<SERVER_IP>` と `<USER>` は値に読み替える
   - Windows: エクスプローラーのアドレス欄に `\\<SERVER_IP>\<USER>`。資格情報は `<USER>` と手順 6 のパスワード
     - サーバーで変えたファイルやディレクトリは、F5 を押さなくても出る（手順 3 の `smb3 directory leases = no`）
   - macOS: Finder の「サーバへ接続」に `smb://<SERVER_IP>/<USER>`
   - Android / iOS: ファイルアプリの SMB 接続先に `<SERVER_IP>`、共有名 `<USER>`
   - Linux: AlmaLinux 10 の PC なら [samba-client.md](samba-client.md)（fstab の自動マウントと GNOME Files）。ほかは `smbclient "//<SERVER_IP>/<USER>" -U <USER>` または `mount -t cifs "//<SERVER_IP>/<USER>" <mountpoint> -o username=<USER>`
   - WireGuard 越しに接続するときは `<SERVER_IP>` を `<WG_IP>` に読み替える（クライアント側の `AllowedIPs` にトンネル網が入っていることが前提。[WireGuard の手順書](wireguard.md)）
   - つなげないときは、[サーバーの上で動作を確かめる](#サーバーの上で動作を確かめる)で、サーバーの上から読み書きを確かめる

---

## root のホームも公開する（任意）

- **root のホーム（`/root`）を公開しないなら、この節は不要**
- `\\<SERVER_IP>\root` で `/root` を読み書きできるようにする。つなぐのは手順 6 で登録した自分の Samba ユーザーのままで、root の Samba ユーザーは作らない
- smbd は、この共有の中を root として読み書きする（`force user = root`）。作ったファイルは root の所有になる
- 手順 1 の変数を設定した、公開したユーザー自身のシェルで貼る（`${USER}` を `valid users` に書く）
- `/root` の読み書きは、この節の手順 3 の後に、[サーバーの上で動作を確かめる](#サーバーの上で動作を確かめる)の手順 7・8 で確かめる
- 補足: [root のホームを公開するときの補足](reference/samba.md#root-のホームを公開するときの補足)

> [!WARNING]
> - `<USER>` の Samba のパスワードが、root のパスワードと同じ重みになる。`/root/.bashrc` や `/root/.ssh/authorized_keys` も書き換えられるので、root で任意のコマンドを動かせる。パスワードは長いものにし、[接続元を絞る](#接続元を絞る任意)も検討する

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
   - `/root` の一覧と書き込みは、[サーバーの上で動作を確かめる](#サーバーの上で動作を確かめる)の手順 7・8 で確かめる

1. 別のマシンから、共有名 `root` でつなぐ。

   - [手順 9](#実施手順) の `<USER>`（共有名）を `root` に読み替える。資格情報は `<USER>` と手順 6 のパスワードのまま
   - Windows: エクスプローラーのアドレス欄に `\\<SERVER_IP>\root`。`\\<SERVER_IP>\<USER>` と同じ資格情報なので、両方を同時に開けるはず（別のユーザー名で同じサーバーにつなぐと、Windows はエラー 1219 で断る）
   - AlmaLinux 10 の PC なら、[samba-client.md](samba-client.md) の手順 1 で `SHARE=root` にする（`SMB_USER` は自分のまま）

1. 元に戻すときは、`[root]` の節とモジュールを消し、smb.service を再起動する。

   ```bash
   {
     sudo sed -i '/^\[root\]$/,/^\[/{/^\[root\]$/d;/^\[/!d}' /etc/samba/smb.conf
     sudo semodule -r samba_root_home
     sudo systemctl restart smb.service
     testparm -s 2>/dev/null | grep -c '^\[root\]'   # 0
   }
   ```

   - 最後に `0` と出ればよい（`[root]` の節が残っていない）
   - `semodule -r` は約 50 秒（VM）かかり、`libsemanage.semanage_direct_remove_key: Removing last samba_root_home module …` と出る。エラーではない

---

## /home も公開する（任意）

- **`/home` を公開しないなら、この節は不要**
- `\\<SERVER_IP>\home` で `/home` を開き、その下のすべてのユーザーのホームを読み書きできるようにする。つなぐのは手順 6 で登録した自分の Samba ユーザーのままで、ほかのユーザーは Samba に登録しなくてよい
- smbd は、この共有の中を root として読み書きする（`force user = root`）
- 新しく作ったファイルとディレクトリの所有者は、親ディレクトリの所有者（`/home/<ユーザー>` の中なら、そのユーザー）になる（`inherit owner = yes`）。グループは `root` になる
- `/home` の直下には、ファイルもディレクトリも作れない（SELinux が断る）
- 手順 1 の変数を設定した、公開したユーザー自身のシェルで貼る（`${USER}` を `valid users` に書く）
- 読み書きは、この節の手順 2 の後に、[サーバーの上で動作を確かめる](#サーバーの上で動作を確かめる)の手順 9・10 で確かめる
- 補足: [/home を公開するときの補足](verification/samba.md#home-を公開するときの補足)

> [!WARNING]
> - `<USER>` の Samba のパスワードで、ほかのユーザーのホームのファイル（`~/.bashrc` や `~/.ssh/authorized_keys`）も読み書きできる。`sudo` を使えるユーザーのホームを書き換えれば、root で任意のコマンドを動かせる。パスワードは長いものにし、[接続元を絞る](#接続元を絞る任意)も検討する

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
   - `/home` の一覧と書き込みは、[サーバーの上で動作を確かめる](#サーバーの上で動作を確かめる)の手順 9・10 で確かめる

1. 別のマシンから、共有名 `home` でつなぐ。

   - [手順 9](#実施手順) の `<USER>`（共有名）を `home` に読み替える。資格情報は `<USER>` と手順 6 のパスワードのまま
   - Windows: エクスプローラーのアドレス欄に `\\<SERVER_IP>\home`。ユーザーごとのフォルダーが並ぶ。フォルダーの外（`/home` の直下）には作れない
   - AlmaLinux 10 の PC なら、[samba-client.md](samba-client.md) の手順 1 で `SHARE=home` にする（`SMB_USER` は自分のまま。同書の手順 5・7 の共有直下への書き込みは `Permission denied` になる）

1. 元に戻すときは、`[home]` の節を消し、smb.service を再起動する。

   ```bash
   {
     sudo sed -i '/^\[home\]$/,/^\[/{/^\[home\]$/d;/^\[/!d}' /etc/samba/smb.conf
     sudo systemctl restart smb.service
     testparm -s 2>/dev/null | grep -c '^\[home\]'   # 0
   }
   ```

   - 最後に `0` と出ればよい（`[home]` の節が残っていない）

---

## サーバーの上で動作を確かめる

- [実施手順](#実施手順)で設定は終わっている。この節は、サーバーの上の `smbclient` と `mount.cifs` で読み書きを確かめる（クライアントでつなげないときの切り分けにも使う）
- [手順 1](#実施手順) の変数を設定した、公開したユーザー自身のシェルで貼る。新しいシェルなら、手順 1 を貼り直してから貼る
- **この節の手順 1・7・9 には対話入力がある**（パスワード）
- この節の手順 7・8 は、[root のホームも公開した](#root-のホームも公開する任意)ときだけ行う
- この節の手順 9・10 は、[/home も公開した](#home-も公開する任意)ときだけ行う
- サーバー自身からの接続は firewalld を通らない（[検証記録](verification/samba.md)・[参考資料](reference/samba.md)）

1. 資格情報ファイルを作るため、[手順 6](#実施手順) で登録したパスワードを入力する。

   ```bash
   AUTHFILE=/run/user/$(id -u)/smb-auth
   read -rsp "Samba password for ${USER}: " PW; echo
   ```

   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. 資格情報ファイルを作る。

   ```bash
   ( umask 077; printf 'username=%s\npassword=%s\n' "${USER}" "${PW}" > "${AUTHFILE}" ); unset PW
   ls -l "${AUTHFILE}"                          # -rw------- で自分の所有
   ```

   - このファイルを、`smbclient` と `mount.cifs` の両方で使う
   - パスワードをコマンドラインに書かないのは、`ps` に見えるため

1. `smbclient` で、共有の一覧と読み書きを確かめる。

   ```bash
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
     mount | grep cifs                            # vers=3.1.1
     echo "cifs write" > /mnt/smbtest/cifs-test.txt && cat /mnt/smbtest/cifs-test.txt
     ls -lZ /mnt/smbtest/cifs-test.txt ~/cifs-test.txt
     sudo smbstatus                               # Protocol Version: SMB3_11、Signing: partial(AES-128-CMAC)
   }
   ```

   - `smbstatus` はセッションが生きている間しか見えない
   - **次の手順は、`smbstatus` の出力を確かめてから貼る**（この節の手順 5 でアンマウントすると見えなくなる）

1. アンマウントして、マウントポイントを消す。

   ```bash
   sudo umount /mnt/smbtest && sudo rmdir /mnt/smbtest
   ```

1. 後片付けとして、検証で作ったファイルと資格情報ファイルを消し、AVC を確かめる。

   ```bash
   rm -f ~/smb-test.txt ~/cifs-test.txt /tmp/smb-test.txt "${AUTHFILE}"
   sudo ausearch -m AVC -ts today               # <no matches>
   ```

   - root のホームを公開していないなら、この節の手順 7・8 は飛ばす
   - `/home` を公開していないなら、この節の手順 9・10 は飛ばす

1. root のホームも公開したときだけ、自分の Samba ユーザーで `/root` の一覧と書き込みを確かめる。

   ```bash
   smbclient //localhost/root -U "${USER}" -c 'ls; put /etc/hostname smb-root-test.txt; ls smb-root-test.txt'
   ```

   - パスワードは、[手順 6](#実施手順) で登録した `<USER>` の Samba のパスワード
   - `/root` の中身（`.bashrc` や `.ssh` など）の一覧に続いて、`putting file /etc/hostname as \smb-root-test.txt` と `smb-root-test.txt` の 1 行が出ればよい
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. root のホームも公開したときだけ、作ったファイルの所有者とラベルを確かめて消し、AVC を確かめる。

   ```bash
   {
     sudo ls -lZ /root/smb-root-test.txt          # -rw-r--r--. root root … admin_home_t
     sudo rm /root/smb-root-test.txt
     sudo ausearch -m AVC -ts recent              # <no matches>
   }
   ```

   - ファイルは `root root` の所有で、ラベルは `admin_home_t`
   - `ausearch` が `<no matches>` ならよい
   - `/home` を公開していないなら、この節の手順 9・10 は飛ばす

1. `/home` も公開したときだけ、`/home` の一覧と、自分のホームへの書き込みを確かめる。

   ```bash
   smbclient //localhost/home -U "${USER}" -c "ls; put /etc/hostname ${USER}/smb-home-test.txt; ls ${USER}/smb-home-test.txt"
   ```

   - パスワードは、[手順 6](#実施手順) で登録した `<USER>` の Samba のパスワード
   - `/home` の中のユーザーのディレクトリ（`<USER>` など）の一覧に続いて、`putting file /etc/hostname as \<USER>\smb-home-test.txt` と `smb-home-test.txt` の 1 行が出ればよい
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. `/home` も公開したときだけ、作ったファイルの所有者とラベルを確かめて消し、AVC を確かめる。

   ```bash
   ls -lZ ~/smb-home-test.txt                   # -rw-r--r--. <USER> root … user_home_t
   rm ~/smb-home-test.txt
   sudo ausearch -m AVC -ts recent              # <no matches>
   ```

   - ファイルの所有者は `<USER>`（root ではない）、グループは `root`、ラベルは `user_home_t`
   - `ausearch` が `<no matches>` ならよい

---

## 接続元を絞る（任意）

- **接続元を制限しないなら、この節は不要**
- 手順 5 は、public ゾーンに属するすべての NIC（この環境では `end0` と `wg0`）で 445/tcp を開く
- 補足: [接続元を絞るときの補足](verification/samba.md#接続元を絞るときの補足)

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
   sudo firewall-cmd --list-rich-rules        # source address に実際のサブネットが入っていることを確認する
   fi
   ```

   - 先頭の `if` は、`ALLOW_FROM` が空のままブロックを貼ったときに、445/tcp の開放だけ消えて rich rule が 1 本も入らないのを防ぐ
   - rich rule は**二重引用符**で囲む。単一引用符だと `${src}` が展開されず、firewalld は `$src` という文字列のままの rule を `success` で受理してしまう

1. 元に戻すときは、絞ったときと同じ `ALLOW_FROM` を入れてから、public ゾーン全体の 445/tcp に戻す。

   ```bash
   if [ -z "${ALLOW_FROM}" ]; then echo '中断: ALLOW_FROM が空のまま。絞ったときと同じ値を入れて貼り直す' >&2; else
   for src in ${ALLOW_FROM}; do
     sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=${src} port port=445 protocol=tcp accept"
   done
   sudo firewall-cmd --permanent --add-port=445/tcp && sudo firewall-cmd --reload
   fi
   ```

---

## 設定済みのサーバーでディレクトリのリースを切る

- **smb.conf に `smb3 directory leases` の行が無いサーバーだけ**。今の手順 3 には、この 1 行が入っている
- 手順 3 は貼り直さず、`[global]` に `smb3 directory leases = no` の 1 行だけを足す（理由は[検証記録](verification/samba.md)・[参考資料](reference/samba.md)）
- 変数を使わないので、どのユーザーのシェルで貼ってもよい
- **この節の手順 2 で smb.service を再起動すると、つないでいるクライアントの接続が一度切れる**

1. smb.conf の `[global]` に 1 行を足し、構文を検査する。

   ```bash
   if grep -qiE '^[[:space:]]*smb3[[:space:]]+directory[[:space:]]+leases' /etc/samba/smb.conf; then echo '中断: /etc/samba/smb.conf に smb3 directory leases の行が既にある' >&2
   elif ! grep -q '^\[global\]$' /etc/samba/smb.conf; then echo '中断: /etc/samba/smb.conf に [global] の行が無い' >&2
   else
     sudo sed -i '/^\[global\]$/a\    smb3 directory leases = no' /etc/samba/smb.conf
     testparm -s 2>/dev/null | grep 'smb3 directory leases'
   fi
   ```

   - `smb3 directory leases = No` の 1 行が出ればよい
   - `中断:` と出たら、何も書き換えていない
   - `… 既にある` で止まったら、その行が `smb3 directory leases = no` かを見る。`no` なら、この節の手順 2 へ進む

1. smb.service を再起動する。

   ```bash
   {
     sudo systemctl restart smb.service
     systemctl is-active smb.service              # active
   }
   ```

   - `active` と出ればよい
   - Windows のエクスプローラーは、次の F5 でつなぎ直す

1. 元に戻すときは、足した行を消して smb.service を再起動する。

   ```bash
   {
     sudo sed -i '/^[[:space:]]*smb3 directory leases = no$/d' /etc/samba/smb.conf
     sudo systemctl restart smb.service
     testparm -s 2>/dev/null | grep -c 'smb3 directory leases'   # 0
   }
   ```

   - 最後に `0` と出ればよい
   - 今の手順 3 で置いた smb.conf の行も消える
   - 再起動すると、つないでいるクライアントの接続が一度切れる

---

## ロールバック

- 上から順に実行する
- 接続元を絞る節を使った場合は 445/tcp ではなく rich rule が入っているので、先に[接続元を絞る（任意）](#接続元を絞る任意)の手順 2 を貼る

> [!CAUTION]
> `passdb.tdb` は Samba のパスワード DB（`smbpasswd` で登録したパスワードの保存先。[検証記録](verification/samba.md)・[参考資料](reference/samba.md)）。**この節の**手順 3 の「完全に消すなら」で消すと、中の登録は取り戻せない。

1. サービスを止め、ファイアウォール・Samba ユーザー・SELinux・smb.conf を元に戻す。

   ```bash
   {
     sudo umount /mnt/smbtest 2>/dev/null; sudo rmdir /mnt/smbtest 2>/dev/null   # 検証のマウントが残っていれば
     sudo systemctl disable --now smb.service
     sudo firewall-cmd --permanent --remove-port=445/tcp && sudo firewall-cmd --reload
     sudo smbpasswd -x "${USER}"
     sudo setsebool -P samba_enable_home_dirs off
     sudo cp -a /etc/samba/smb.conf.orig /etc/samba/smb.conf
   }
   ```

   - 公開したユーザー自身のシェルで貼る（`sudo -i` した root のシェルでは `${USER}` が `root` になる）
   - 並びは、`smbpasswd`（`samba-common-tools`）が消える前に Samba ユーザーを消すため
   - [root のホームも公開した](#root-のホームも公開する任意)ときの `[root]` の節と、[/home も公開した](#home-も公開する任意)ときの `[home]` の節も、最後の `smb.conf` の復元で消える

1. root のホームも公開していたときだけ、SELinux のモジュールを外す。

   ```bash
   sudo semodule -r samba_root_home
   ```

   - `libsemanage.semanage_direct_remove_key: Removing last samba_root_home module …` の 1 行が出て終わればよい

1. パッケージも消すときだけ、samba・samba-client・cifs-utils を消す。

   ```bash
   sudo dnf remove -y samba samba-client cifs-utils
   ```

   - `samba-common` は実施前から入っていたので残す
   - Workstation などで `cifs-utils` も実施前から入っていたなら、上のコマンドから `cifs-utils` を外す（ほかの共有のマウントにも使うため）
   - `dnf remove` 後も、`/var/lib/samba/private/passdb.tdb`（Samba のパスワード DB）と `/var/log/samba/` は残る
   - 完全に消すなら `sudo rm -rf /var/lib/samba/private/passdb.tdb /var/log/samba`（取り戻せない）

---

## 注意点

- **公開範囲は public ゾーンの全 NIC**: この環境では `wg0` も public にあるので、VPN 越しのクライアント（拠点 A の LAN や外出先の端末）からも 445 に届く。それを望まないなら[接続元を絞る](#接続元を絞る任意)
- **LAN 上の通信は暗号化されない**: 署名だけ（`smbstatus` の `Encryption` 欄が `-`）。VPN 越しは WireGuard が暗号化する
- **自ホストからの検証は firewalld を通らない**: 445 の開け忘れは、別ホストか network namespace から接続して初めて分かる
- **Samba のパスワードは OS と別**: OS のパスワードを変えても Samba 側は変わらない。変えるときは `sudo smbpasswd "${USER}"`
- **ユーザー名は OS アカウントと一致が必須**
  - 存在しないユーザー、間違ったパスワードは、どちらも `NT_STATUS_LOGON_FAILURE`
  - 他人のホーム（`//<SERVER_IP>/<別のユーザー>`。`[root]` を足していなければ `//<SERVER_IP>/root` も）は、認証が通っても `tree connect failed: NT_STATUS_ACCESS_DENIED`
- **root の共有は root と同じ重み**: [root のホームも公開した](#root-のホームも公開する任意)ら、`<USER>` の Samba のパスワードで `/root/.bashrc` や `/root/.ssh/authorized_keys` を書き換えられる
- **`/home` の共有は、ほかのユーザーのホームも書ける**: [/home も公開した](#home-も公開する任意)ら、`<USER>` の Samba のパスワードで、ほかのユーザーの `~/.bashrc` や `~/.ssh/authorized_keys` も書き換えられる。`sudo` を使えるユーザーがいれば、root と同じ重みになる
- **`create mask` を変えても既存ファイルのモードは変わらない**: 手順 3 の前にホームに置いていたファイルのモードはそのまま
- **`nmb` を起動しない構成なので、Windows のエクスプローラーで「ネットワーク」から見つけることはできない**: `\\<SERVER_IP>\<USER>` を直接入力する。一覧に出したいなら `wsdd`
- **クライアントにも、サーバーとは別の一覧のキャッシュがある**
  - GNOME Files（`smb://`）は、サーバーで変えたものを自動では出さない。F5 ですぐ出る（[samba-client.md の注意点](samba-client.md#注意点)）
  - Windows は、ディレクトリのリースが無いときも、一覧を最長 10 秒キャッシュする（Microsoft の文書の `DirectoryCacheLifetime`）
  - macOS は、SMB 2/3 の一覧を手元にキャッシュする（Apple の文書。止めるには `nsmb.conf` の `dir_cache_max_cnt=0`）
