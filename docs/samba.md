# Samba でホームディレクトリを公開する手順（`[homes]` 共有 / smbd + firewalld）

## 実施手順

> [!IMPORTANT]
> - **すべてサーバー上で実行する**。手順 15（クライアントからの接続）だけ別マシン
> - **手順 6 と手順 9 には対話入力がある**（パスワード）。入力し終えてから次の手順を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: root のホーム（`/root`）も公開するなら、[root のホームも公開する（任意）](#root-のホームも公開する任意)を行う。接続元を絞る場合は、最後に[接続元を絞る（任意）](#接続元を絞る任意)を行う。戻すときは[ロールバック](#ロールバック)

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

   <details>
   <summary>補足: 変数について</summary>

   - `SERVER_IP` を自動取得にしているのは、設定には使わず検証と案内にしか使わないため（GNOME Remote Desktop の手順書で手入力なのは、値が証明書の SAN に入るから）
   - `SERVER_IP` が間違っていても、手順 11 の `smbclient "//${SERVER_IP}/..."` が失敗するだけで、設定は壊れない
   - 公開するのは `${USER}`（このシェルのユーザー）のホーム。`sudo -i` した root のシェルでは `root` になり、手順 6 で root のホームを公開してしまうので、読み戻しで必ず確認する
   - root のシェルで進めると、root の Samba ユーザーができるうえ、`/root` のラベル（`admin_home_t`）は手順 4 の boolean の対象外なので、手順 11 の `ls` も通らない。root のホームは、自分のユーザーのまま入れる `[root]` 共有で足す（[root のホームも公開する（任意）](#root-のホームも公開する任意)）
   - `ALLOW_FROM` は[接続元を絞る](#接続元を絞る任意)でしか使わないので、手順 1 ではなくその節の冒頭で設定する

   </details>

1. samba・samba-client・cifs-utils を入れる。

   ```bash
   {
     sudo dnf install -y samba samba-client cifs-utils
     rpm -q samba samba-client cifs-utils
   }
   ```

   <details>
   <summary>補足: パッケージ</summary>

   - `samba`（baseos）が smbd 本体。依存で `samba-common-tools`（`smbpasswd` / `pdbedit` / `testparm` / `smbstatus`）、`samba-libs`、`samba-dcerpc` などが入る
   - `samba-client`（`smbclient`）と `cifs-utils`（`mount.cifs`）は手順 11・12 の検証にしか使わない。サーバー上で検証しないなら入れなくてよい
   - インストール直後は `smb.service` / `nmb.service` とも `disabled` / `inactive`

   </details>

1. 既定の smb.conf を退避して最小構成に置き換え、構文を検査する。

   ```bash
   {
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

   [homes]
       comment = Home Directories
       valid users = %S
       browseable = No
       read only = No
       create mask = 0644
   EOF
     testparm -s
   }
   ```

   - `Loaded services file OK.` と `Server role: ROLE_STANDALONE` が出ればよい

   <details>
   <summary>補足: smb.conf</summary>

   - `cp -an` の `-n` で、2 回目以降の実行で `.orig` を上書きしない（最小構成で上書きした `smb.conf` を原本として退避してしまうのを防ぐ）
   - heredoc は `${WORKGROUP}` を展開するため引用符なしの `<<EOF`。内容にほかの `$` は無い
   - 字下げは空白にしてある。TAB だと、ブラケットペーストが効かない端末で貼ったときに bash が補完として扱い、行頭が `.` に置き換わった（VM で確認）
   - そのときの testparm は、`Unknown parameter` と出しつつ `Loaded services file OK.` で終わった（壊れたことに気付きにくい）
   - `testparm -s` の出力に `Weak crypto is allowed by GnuTLS (e.g. NTLM as a compatibility fallback)` が出るが、crypto-policies が DEFAULT のときの通常の表示で、エラーではない
   - `testparm -s` は**既定と異なる値だけ**を表示する。`workgroup = WORKGROUP` や `read only = No` に対応する行が出なくても書き漏れではない。全パラメータを見るなら `testparm -sv`
   - 手順 15 の後で `smb.conf` を直したときは `sudo systemctl restart smb.service`（unit には `ExecReload`（`SIGHUP`）もあるが、本手順の検証では restart しか使っていない）

   </details>

1. SELinux の boolean `samba_enable_home_dirs` を on にする。

   ```bash
   {
     sudo setsebool -P samba_enable_home_dirs on
     sudo getsebool samba_enable_home_dirs        # samba_enable_home_dirs --> on
   }
   ```

   <details>
   <summary>補足: SELinux</summary>

   - boolean が off のままだと、認証は通り共有一覧にも出るのに、`ls` で `NT_STATUS_ACCESS_DENIED listing \*` になる
   - **このとき `ausearch -m AVC` には何も出ない**（dontaudit されている）ので、監査ログから原因にたどり着けない。[付録](#selinux-boolean-が-off-のときの失敗の署名)
   - `setsebool -P` は即時反映で、smbd の再起動は不要（実測: 起動中の smbd に対して on にした直後の `ls` が通った）

   </details>

1. firewalld で 445/tcp を開ける。

   ```bash
   {
     sudo firewall-cmd --permanent --add-port=445/tcp && sudo firewall-cmd --reload
     sudo firewall-cmd --list-ports               # 445/tcp が含まれる
   }
   ```

   <details>
   <summary>補足: firewalld</summary>

   - 445/tcp は public ゾーンの全 NIC で開く。この環境では `end0`（LAN）と `wg0`（VPN）
   - 自ホストからの `smbclient //localhost/...` や `//${SERVER_IP}/...` は `lo` を通るため、**firewalld の設定を通らない**（`filter_INPUT` の `iifname "lo" accept` で先に受理される）
   - 開け忘れはサーバー上の検証では見つからない。[付録](#network-namespace-から-firewalld-越しに到達する)

   </details>

1. OS のアカウントを確かめ、Samba ユーザーを登録する。

   ```bash
   id "${USER}"
   sudo smbpasswd -a "${USER}"
   ```

   - `id` で、OS のアカウントが存在することを確かめる
   - **端末で対話入力する**。新しいパスワードを 2 回聞かれる
   - Samba のパスワードは、OS のパスワードとは別に保存される
   - **次の手順は、2 回の入力を終えてから貼る**（続けて貼るとパスワードとして食われる）

   <details>
   <summary>補足: Samba ユーザー</summary>

   - Samba のパスワードは OS のパスワードとは別で、`/var/lib/samba/private/passdb.tdb` に保存される。OS のアカウントは存在が必須（`id` で確認）
   - `smbpasswd -a` は既定で `/dev/tty` から読む。**TTY が無いと `Unable to get new password.` で終了コード 1**（`grdctl set-credentials` のように exit 0 で黙って何もしない、ということはない）
   - パイプで渡すなら `-s`（stdin から新パスワード・確認の 2 行を読む）。[付録](#smbpasswd-を-tty-無しで実行したとき)
   - `-a` で作った直後から有効（`pdbedit -Lv` の `Account Flags: [U ]`）。`smbpasswd -e` は要らない
   - **smbd の再起動は不要**。起動中に `smbpasswd -x` → `-a` し直すと、その次の接続から効く（実測）。パスワード変更も同様

   </details>

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

   <details>
   <summary>補足: サービス</summary>

   - `smb.service` は `nmb.service` を `Requires` / `Wants` していない（`After=` に並ぶだけ）。nmb を起動しなくても単独で動く
   - 起動すると `/var/log/samba/` に `log.smbd` と `log.rpcd_*`（`samba-dcerpcd` が起動する RPC ヘルパーのログ）ができる。`cups` 無しでも、本手順の `smb.conf` なら CUPS 関連のエラーは出ない

   </details>

1. 資格情報ファイルを作るため、手順 6 で登録したパスワードを入力する。

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

   <details>
   <summary>補足: 資格情報ファイル</summary>

   - パスワードは `-U user%pass` で渡すと `ps` に見える
   - `smbclient -A` の資格情報ファイル（`username=` / `password=`）は `mount.cifs -o credentials=` と同じ形式なので、1 つ作って両方に使う
   - `/run/user/<uid>/` は tmpfs でユーザー専用（0700）

   </details>

1. `smbclient` で、共有の一覧と読み書きを確かめる。

   ```bash
   smbclient -L //localhost -A "${AUTHFILE}"    # IPC$ と <USER> の 2 つだけ出る
   smbclient "//localhost/${USER}" -A "${AUTHFILE}" -c 'ls'
   smbclient "//localhost/${USER}" -A "${AUTHFILE}" -c "put /etc/hostname smb-test.txt; get smb-test.txt /tmp/smb-test.txt; ls smb-test.txt"
   ls -lZ ~/smb-test.txt /tmp/smb-test.txt      # -rw-r--r-- / user_home_t
   cmp /etc/hostname /tmp/smb-test.txt && echo "content identical"
   smbclient "//${SERVER_IP}/${USER}" -A "${AUTHFILE}" -c 'ls smb-test.txt'
   ```

   <details>
   <summary>補足: 共有の一覧</summary>

   - `smbclient -L` に出るのは `IPC$` と `<USER>` の 2 つ。`homes` / `printers` / `print$` は出ない

   </details>

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
   - **次の手順は、`smbstatus` の出力を確かめてから貼る**（手順 13 でアンマウントすると見えなくなる）

   <details>
   <summary>補足: マウントと smbstatus</summary>

   - `mount.cifs` の既定は SMB 3.1.1（`vers=3.1.1`）。`uid=` / `gid=` を渡さないとマウント側のファイルが root 所有に見える
   - マウント側の `ls -Z` は `cifs_t`、サーバー側は `user_home_t`（`user_home_dir_t` 配下の type transition。`restorecon` していないのにこうなる）
   - `smbstatus` はサーバー側で「交渉されたプロトコル / 暗号化 / 署名」を表示する。クライアント側では見えにくい情報なので、暗号化の有無を確かめるならここ

   </details>

1. アンマウントして、マウントポイントを消す。

   ```bash
   sudo umount /mnt/smbtest && sudo rmdir /mnt/smbtest
   ```

1. 後片付けとして、検証で作ったファイルと資格情報ファイルを消し、AVC を確かめる。

   ```bash
   rm -f ~/smb-test.txt ~/cifs-test.txt /tmp/smb-test.txt "${AUTHFILE}"
   sudo ausearch -m AVC -ts today               # <no matches>
   ```

1. 別のマシンから、クライアントで接続する（未検証）。

   - `<SERVER_IP>` と `<USER>` は値に読み替える
   - Windows: エクスプローラーのアドレス欄に `\\<SERVER_IP>\<USER>`。資格情報は `<USER>` と手順 6 のパスワード
   - macOS: Finder の「サーバへ接続」に `smb://<SERVER_IP>/<USER>`
   - Android / iOS: ファイルアプリの SMB 接続先に `<SERVER_IP>`、共有名 `<USER>`
   - Linux: AlmaLinux 10 の PC なら [samba-client.md](samba-client.md)（fstab の自動マウントと GNOME Files）。ほかは `smbclient "//<SERVER_IP>/<USER>" -U <USER>` または `mount -t cifs "//<SERVER_IP>/<USER>" <mountpoint> -o username=<USER>`
   - WireGuard 越しに接続するときは `<SERVER_IP>` を `<WG_IP>` に読み替える（クライアント側の `AllowedIPs` にトンネル網が入っていることが前提。[WireGuard の手順書](wireguard.md)）

   <details>
   <summary>補足: クライアントからの接続</summary>

   - クライアントからの接続は未検証。IP アドレスで指定する（NetBIOS 名では見つからない）
   - [samba-client.md](samba-client.md) は、手順 3 の `smb.conf` を置いたコンテナに、AlmaLinux 10 の VM からつないで確かめた。この実機のサーバーへの接続は確かめていない

   </details>

---

## root のホームも公開する（任意）

- **root のホーム（`/root`）を公開しないなら、この節は不要**
- `\\<SERVER_IP>\root` で `/root` を読み書きできるようにする。つなぐのは手順 6 で登録した自分の Samba ユーザーのままで、root の Samba ユーザーは作らない
- smbd は、この共有の中を root として読み書きする（`force user = root`）。作ったファイルは root の所有になる
- 手順 1 の変数を設定した、公開したユーザー自身のシェルで貼る（`${USER}` を `valid users` に書く）
- **この節の手順 3 には対話入力がある**（`smbclient` のパスワード）
- 補足: [root のホームを公開するときの補足](#root-のホームを公開するときの補足)

> [!WARNING]
> - `<USER>` の Samba のパスワードが、root のパスワードと同じ重みになる。`/root/.bashrc` や `/root/.ssh/authorized_keys` も書き換えられるので、root で任意のコマンドを動かせる。パスワードは長いものにし、[接続元を絞る](#接続元を絞る任意)も検討する
> - この節は **x86_64 の VM でのみ検証した**。実機では本実行していない（[付録](#付録-root-のホームを公開する節の-vm-での検証2026-09-29)）

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

   <details>
   <summary>補足: [root] の各行</summary>

   - `path = /root`: `[homes]` と違い、共有の場所を書く普通の共有
   - `valid users = ${USER}`: 入れるのは `<USER>` だけ。ほかの Samba ユーザーは、認証が通っても `tree connect failed: NT_STATUS_ACCESS_DENIED`（VM で確認）
   - `force user = root`: つないだ後のファイル操作を root として行う。`/root` は `dr-xr-x---`（0550）だが、root として扱うので書ける（smbd の SELinux のドメイン `smbd_t` は `dac_override` を持つ）
   - `browseable = No`: 共有の一覧（`smbclient -L`）に出さない。つなぐときは共有名 `root` を直接指定する
   - `create mask = 0644`: `[homes]` と同じ理由（[smb.conf の各行の根拠](#smbconf-の各行の根拠)）
   - root は OS のユーザーなので、`[homes]` も `root` という名前の共有を出そうとする。同じ名前の節があれば、そちらが使われる（VM では、`[root]` を消すと `<USER>` の接続が `[homes]` の `valid users = %S` で断られた）
   - ヒアドキュメントは `${USER}` を展開するので、引用符なしの `<<EOF`。先頭の空行は、手順 3 の `[homes]` との区切り

   </details>

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
   - `semodule -i` は、終わるまでしばらく何も出さない（VM では約 50 秒）

   <details>
   <summary>補足: モジュールが要る理由</summary>

   - 手順 4 の `samba_enable_home_dirs` が smbd に許すのは、一般ユーザーのホームのラベル（属性 `user_home_type`）だけ。`/root` とその中のファイルは `admin_home_t` で、この属性に入っていない（`seinfo -t admin_home_t -x`）
   - そこで、boolean が `user_home_type` の dir / file / lnk_file に許すのと同じ許可を、`admin_home_t` に足す（VM の `sesearch -A -s smbd_t -t ssh_home_t` で見た許可の並び）
   - `/root/.ssh`（`ssh_home_t`）や `/root/.config`（`config_home_t`）は `user_home_type` なので、手順 4 の boolean で既に許されている
   - CIL は `semodule -i` がそのまま読むので、`checkpolicy`（`checkmodule`）などを入れなくてよい。入れたモジュールは優先度 400 に置かれる（`semodule -lfull` の `400 samba_root_home cil`）
   - モジュールを入れずに `[root]` へつないだときの表示（VM で確認）:
     - `ls` は `NT_STATUS_ACCESS_DENIED listing \*`。**AVC は出ない**（`admin_home_t` のディレクトリの読み取りは dontaudit されている）
     - ファイルの取得は `NT_STATUS_ACCESS_DENIED opening remote file \.bashrc` で、AVC は `denied { getattr } … tcontext=system_u:object_r:admin_home_t:s0 tclass=file`
     - 書き込みは `NT_STATUS_ACCESS_DENIED opening remote file \x.txt` で、AVC は `denied { write } … name="root" … tclass=dir`

   </details>

1. smb.service を再起動し、自分の Samba ユーザーで `/root` の一覧と書き込みを確かめる。

   ```bash
   {
     sudo systemctl restart smb.service
     smbclient //localhost/root -U "${USER}" -c 'ls; put /etc/hostname smb-root-test.txt; ls smb-root-test.txt'
   }
   ```

   - パスワードは、手順 6 で登録した `<USER>` の Samba のパスワード
   - `/root` の中身（`.bashrc` や `.ssh` など）の一覧に続いて、`putting file /etc/hostname as \smb-root-test.txt` と `smb-root-test.txt` の 1 行が出ればよい
   - 再起動すると、ほかのクライアントのつないでいる接続が切れる
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. 作ったファイルの所有者とラベルを確かめて消し、AVC を確かめる。

   ```bash
   {
     sudo ls -lZ /root/smb-root-test.txt          # -rw-r--r--. root root … admin_home_t
     sudo rm /root/smb-root-test.txt
     sudo ausearch -m AVC -ts recent              # <no matches>
   }
   ```

   - ファイルは `root root` の所有で、ラベルは `admin_home_t`
   - `ausearch` が `<no matches>` ならよい

   <details>
   <summary>補足: 作ったファイル</summary>

   - SMB から `/root` に作ったものは、名前にかかわらず `admin_home_t` になる。VM では、SMB で作った `/root/.config` も `admin_home_t` だった（ローカルで作れば `config_home_t`）
   - ほかのプログラムがラベルで困ったら、`sudo restorecon -Rv /root/.config` のように既定のラベルに戻す（VM では `config_home_t` に戻り、その後も SMB から読み書きできた）
   - 既にラベルの付いたディレクトリの中に作ったものは、そのディレクトリのラベルになる（VM では、`/root/.ssh` に作ったファイルは `ssh_home_t`）
   - `-ts recent` は直近 10 分。この節の手順 3 から時間がたったときは `-ts today` にする

   </details>

1. 別のマシンから、共有名 `root` でつなぐ（未検証）。

   - 手順 15 の `<USER>`（共有名）を `root` に読み替える。資格情報は `<USER>` と手順 6 のパスワードのまま
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

   <details>
   <summary>補足: 元に戻す</summary>

   - `sed` は、`[root]` の行から次の `[` で始まる行の手前までを消す。`[root]` の後ろに別の節を足していても、その節は残る
   - この節の手順 1 で足した先頭の空行は、ファイルの末尾に残る（`testparm` は気にしない）
   - 戻した後の `//<SERVER_IP>/root` は、`<USER>` では `tree connect failed: NT_STATUS_ACCESS_DENIED`（`[homes]` の `valid users = %S`）

   </details>

---

## 接続元を絞る（任意）

- **接続元を制限しないなら、この節は不要**
- 手順 5 は、public ゾーンに属するすべての NIC（この環境では `end0` と `wg0`）で 445/tcp を開く
- 補足: [接続元を絞るときの補足](#接続元を絞るときの補足)

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

## ロールバック

- 上から順に実行する
- 接続元を絞る節を使った場合は 445/tcp ではなく rich rule が入っているので、先に[接続元を絞る（任意）](#接続元を絞る任意)の手順 2 を貼る

> [!CAUTION]
> `passdb.tdb` は Samba のパスワード DB（`smbpasswd` で登録したパスワードの保存先。手順 6 の補足）。**この節の**手順 3 の「完全に消すなら」で消すと、中の登録は取り戻せない。

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
   - [root のホームも公開した](#root-のホームも公開する任意)ときの `[root]` の節も、最後の `smb.conf` の復元で消える

1. root のホームも公開していたときだけ、SELinux のモジュールを外す。

   ```bash
   sudo semodule -r samba_root_home
   ```

   - `libsemanage.semanage_direct_remove_key: Removing last samba_root_home module …` の 1 行が出て終わればよい（VM では約 50 秒）

1. パッケージも消すときだけ、samba・samba-client・cifs-utils を消す。

   ```bash
   sudo dnf remove -y samba samba-client cifs-utils
   ```

   - `samba-common` は実施前から入っていたので残す
   - `dnf remove` 後も、`/var/lib/samba/private/passdb.tdb`（Samba のパスワード DB）と `/var/log/samba/` は残る
   - 完全に消すなら `sudo rm -rf /var/lib/samba/private/passdb.tdb /var/log/samba`（取り戻せない）

---

## 補足

### 対象と検証環境

- **目的**: ローカルユーザーが**自分のホームディレクトリ**に、LAN と WireGuard 越し（`wg0`）の両方から SMB3 で読み書きできるようにする
  - 共有は Samba の `[homes]` 機構（ユーザー名と同じ名前の共有が自動で現れ、本人しか入れない）を使う
  - 任意で、root のホーム（`/root`）も `[root]` 共有で公開できる。入るのは自分の Samba ユーザーのままで、smbd は root として読み書きする（[root のホームも公開する（任意）](#root-のホームも公開する任意)）
  - 印刷・NetBIOS・ゲストアクセスは持たない
- **進め方**: **冒頭の変数ブロックに値を 1 度書き、以降のコマンドをそのまま貼る**
  - 読者が編集するのは `WORKGROUP` と、接続元を絞る場合の `ALLOW_FROM` だけ
  - `smb.conf` は既定ファイルを退避したうえで、最小構成に置き換える
- **状態**: **2026-09-21 に下表の実機で本実行し、そのまま公開を継続中**
  - 確認したこと: **サーバー自身からの `smbclient` と `mount.cifs` による読み書き**、および **network namespace から firewalld 越しに 445/tcp へ到達できること**（[付録](#付録-実機での検証記録2026-09-21)）
  - **確認していないこと**: Windows / macOS / Android の実クライアントからの接続
  - 2026-09-28: 手順 2〜5・8・12 と、[ロールバック](#ロールバック)の手順 1 のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../README.md#記法)）。中のコマンドは変えていない
    - 手順 3 の smb.conf の字下げを、TAB から空白に変えた。TAB は、ブラケットペースト無しで貼ると bash の補完で `.` に置き換わった（手順 3 の補足）
    - 直した後の手順 1〜14 とロールバックを、x86_64 の VM にブラケットペースト無しで貼って通した。VM は [samba-client.md の付録](samba-client.md#付録-vm-での検証記録2026-09-27)と同じもので、まっさらな状態から始めた
    - その VM には `samba-common` が入っていなかったので、手順 2 で一緒に入り、ロールバックの手順 3 で一緒に消えた
  - 2026-09-29: [root のホームも公開する（任意）](#root-のホームも公開する任意)と、[ロールバック](#ロールバック)の手順 2 を足した
    - **この 2 つは x86_64 の VM でのみ検証した**。実機では本実行していない
    - まっさらな VM で手順 1〜14 を通した後、root の節の手順 1〜4・6 とロールバックを、ブラケットペーストの有りと無しで 1 回ずつ貼って通した（[付録](#付録-root-のホームを公開する節の-vm-での検証2026-09-29)）
    - 確認したこと: `/root` の一覧・読み書き・改名・削除で AVC が出ないこと、作ったファイルが `root root` の `admin_home_t` になること、2 人目の Samba ユーザーが入れないこと、samba-client.md の手でのマウント（`SHARE=root`）、モジュールが無いときの失敗の表示
    - 確認していないこと: 実機、Windows などのクライアントからの接続（エラー 1219 を避けられることも）、WireGuard 越しの接続

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
| クライアント | 検証は Linux の `smbclient` 4.23.5 と `mount.cifs`（SMB 3.1.1）。Windows / macOS / Android は未確認 |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${WORKGROUP}` | `smb.conf` の `workgroup`。Windows 側のワークグループ名に合わせる（NetBIOS を使わないので実質ラベル） | `WORKGROUP` |
> | `${ALLOW_FROM}` | 送信元サブネットのリスト（空白区切り）。[接続元を絞る](#接続元を絞る任意)場合だけ、その節の冒頭で設定する | `192.168.1.0/24 10.99.0.0/30` |
> | `${SERVER_IP}` | クライアントが接続に使うサーバーの LAN 側 IP（デフォルト経路の送信元から自動で入る）。検証と案内にしか使わない | `192.168.1.10` |
>
> 出力例・ログ・表の中の値は `<HOSTNAME>` / `<SERVER_IP>` / `<WG_IP>`（`wg0` のアドレス）/ `<USER>`（OS アカウント名）のプレースホルダで書いてある。
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
- **接続元の制限は `smb.conf` の `hosts allow` ではなく firewalld で行う**
  - GNOME Remote Desktop の手順書と同じ方式にし、変数の扱いと二重引用符の落とし穴を共通にした
  - `hosts allow` で二重に絞ることもできるが、設定場所が 2 つになるのでやらない
- **SMB の暗号化は既定（`server smb encrypt = default`）のまま**
  - LAN 上の通信は署名（AES-128-CMAC）だけで、暗号化されない。WireGuard 越しはトンネルが暗号化する
  - LAN 上でも暗号化したいなら、`server smb encrypt = required` を `[global]` に足す（未検証）
- **Windows のエクスプローラー「ネットワーク」への一覧表示（WS-Discovery）は範囲外**
  - 本手順は `\\<SERVER_IP>\<USER>` を直接指定して接続する前提
  - 必要なら EPEL の `wsdd`（本機に導入済みだが無効）を起動し、5357/tcp と 3702/udp を開ける

#### smb.conf の各行の根拠

| 行 | 書く / 書かない | 根拠 |
|---|---|---|
| `workgroup = ${WORKGROUP}` | 書く | 既定値は `WORKGROUP`（Windows の既定と同じ）。既定値と同じときは `testparm -s` の出力に**出ない**（`testparm -s` は既定と異なる値だけを表示する） |
| `security = user` / `passdb backend = tdbsam` | 書く（既定と同じ） | 「認証はローカルの tdbsam」を明示するため。`testparm -s` の `Server role: ROLE_STANDALONE` で確認できる |
| `server smb transports = tcp` | 書く | 445/tcp だけを listen する。4.23 の正式名で、`smb ports` はその同義語（`man smb.conf`） |
| `load printers = no` / `printing = bsd` / `printcap name = /dev/null` / `disable spoolss = yes` | 書く | `cups` が無い環境で smbd が CUPS へ接続しに行くのと、spoolss RPC を止める定型 |
| `include = /etc/samba/usershares.conf` | 書かない | `samba-usershares` を入れていないので対象ファイルが無い。既定 `smb.conf` のままでも `testparm` は**警告を出さない**（実測）。無いファイルの `include` は黙って無視される |
| `[homes] valid users = %S` | 書く | 既定の `%S, %D%w%S` のうち `%D%w%S`（ワークグループ名 + 区切り + 共有名）はドメイン参加時に `DOMAIN\user` 形式を通すためのもの。standalone では `%S` だけでよい |
| `browseable = No` | 書く（既定と同じ） | `homes` という名前の共有を一覧から隠す。ユーザー名の共有は一覧に出る（実測: `smbclient -L` に `<USER>` は出て `homes` は出ない） |
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

### root のホームを公開するときの補足

- **公開されるのは `/root` の全体**
  - `/root` と、その中の `admin_home_t` のファイル・ディレクトリは、[root のホームも公開する](#root-のホームも公開する任意)の手順 2 のモジュールで許す
  - `.ssh`（`ssh_home_t`）・`.gnupg`（`gpg_secret_t`）・`.config`（`config_home_t`）などは、一般ユーザーのホームと同じ `user_home_type` のラベルなので、手順 4 の boolean で既に許されている
  - VM では、SMB から `/root/.ssh/authorized_keys` を取得でき、`/root/.ssh` へのファイルの書き込みと `/root/.bashrc` の書き換えも通った（AVC は出ない）
- **入るのは `<USER>`**: `pdbedit -L` は `<USER>` の 1 行のまま（root は出ない）。`smbstatus` では、Username が `<USER>`、Service が `root` になる
- **クライアントでの見え方**: [samba-client.md](samba-client.md) の `mount.cifs` は `uid=` / `gid=` で自分の所有に見せるが、サーバーでは `root root` で書かれる
- **以前に `smbpasswd -a root` で root を登録していたら**: VM では、`sudo smbpasswd -x root` は `Failed to delete entry for user root.` で消せず、`sudo pdbedit -x -u root` で消えた

### 接続元を絞るときの補足

- `ALLOW_FROM` の各サブネットについて、rich rule を 1 本ずつ足す
- LAN と VPN の両方から使うなら、LAN のサブネットとトンネル網（`site.env` の `WG_TUNNEL_NET`。外出先クライアントも受けるならクライアント帯も）を並べる
- 実測（[付録](#接続元を絞る節の検証)）: `192.168.1.0/24 10.99.0.0/30` で絞った状態では、どちらにも属さない network namespace（192.168.250.0/24）からの接続が `NT_STATUS_HOST_UNREACHABLE` で落ち、そのサブネットの rich rule を足すと通った
- 手順 5 の `--add-port=445/tcp` を残したままだと rich rule が無意味になるので、先に外す。戻すときは逆順
- 実機での検証は、先頭の `if` を付ける前の形（`[ -n "${ALLOW_FROM}" ] || ...`）で行った
- `if` 付きの形は、`sudo` をスタブに置き換えて「空のときは何も呼ばれず、値を入れると同じコマンドが呼ばれる」ことだけ確認している

### 注意点

- **公開範囲は public ゾーンの全 NIC**: この環境では `wg0` も public にあるので、VPN 越しのクライアント（拠点 A の LAN や外出先の端末）からも 445 に届く。それを望まないなら[接続元を絞る](#接続元を絞る任意)
- **LAN 上の通信は暗号化されない**: 署名だけ（`smbstatus` の `Encryption` 欄が `-`）。VPN 越しは WireGuard が暗号化する
- **自ホストからの検証は firewalld を通らない**: 445 の開け忘れは、別ホストか network namespace から接続して初めて分かる
- **Samba のパスワードは OS と別**: OS のパスワードを変えても Samba 側は変わらない。変えるときは `sudo smbpasswd "${USER}"`
- **ユーザー名は OS アカウントと一致が必須**
  - 存在しないユーザー、間違ったパスワードは、どちらも `NT_STATUS_LOGON_FAILURE`
  - 他人のホーム（`//<SERVER_IP>/<別のユーザー>`。`[root]` を足していなければ `//<SERVER_IP>/root` も）は、認証が通っても `tree connect failed: NT_STATUS_ACCESS_DENIED`
- **root の共有は root と同じ重み**: [root のホームも公開した](#root-のホームも公開する任意)ら、`<USER>` の Samba のパスワードで `/root/.bashrc` や `/root/.ssh/authorized_keys` を書き換えられる
- **`create mask` を変えても既存ファイルのモードは変わらない**: 手順 3 の前にホームに置いていたファイルのモードはそのまま
- **`nmb` を起動しない構成なので、Windows のエクスプローラーで「ネットワーク」から見つけることはできない**: `\\<SERVER_IP>\<USER>` を直接入力する。一覧に出したいなら `wsdd`

### 参照

- [Chapter 1. Using Samba as a server — Configuring and using network file services (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/configuring_and_using_network_file_services/using-samba-as-a-server)
- [Setting up Samba as a Standalone Server — SambaWiki](https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Standalone_Server)
- `man smb.conf`（`[homes]` 節、`server smb transports`、`valid users`、`map archive`）/ `man smbpasswd`（`-s`）/ `man smbclient`（`-A`）/ `man mount.cifs`（`credentials=`）

---

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

`ALLOW_FROM="192.168.1.0/24 10.99.0.0/30"` で[接続元を絞る](#接続元を絞る任意)のコマンドを実行し、上の network namespace（192.168.250.0/24、どちらにも属さない）から接続した:

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

[root のホームも公開する（任意）](#root-のホームも公開する任意)と、[ロールバック](#ロールバック)の手順 2 を足したときの記録。x86_64 のクラウドのホストの上の、使い捨ての VM で行った。実機で加えた変更は無い。

**環境**:

- ホストは Ubuntu 24.04 / x86_64 のクラウドの VM（`/dev/kvm` 無し）。QEMU 8.2.2 の TCG（`-accel tcg,thread=multi -cpu max -smp 4 -m 4096`）で、`AlmaLinux-10-GenericCloud-10.2-20260817.0.x86_64.qcow2`（`CHECKSUM` の SHA-256 と一致）を起動した
- 作り方は [samba-client.md の付録](samba-client.md#付録-vm-での検証記録2026-09-27)と同じ
  - cloud-init で、`<USER>`（uid 1000、`wheel`。`sudo` はパスワードを聞く）と、確かめ用の 2 人目（uid 1001、NOPASSWD の `sudo`）を作った
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
  - `sudo` のパスワード、`smbpasswd`・`read`・`smbclient` のパスワードは、問い合わせが出てから送った
- 1 つのシェルで、次の順に貼った
  - 手順 1〜14
  - `sudo -i` した root のシェルで、root の節の手順 1
  - root の節の手順 1〜4
  - samba-client.md の手順 1〜6（`SERVER=127.0.0.1`、`SHARE=root` に書き換えた）と、同書のロールバックの手順 3（マウント先と資格情報ファイルを消す）
  - 別の ssh のセッションから、2 人目を Samba に登録して `[root]` へつなぐ（手順書の外）
  - root の節の手順 1（2 回目）、手順 6、手順 1・2（入れ直し）
  - ロールバックの手順 1〜3
- ブラケットペーストの回では、2 人目の確認と同じところで、`.ssh` へのファイルの書き込み、`.bashrc` の書き換え（元の内容に戻した）、SMB で作った `.config` への `restorecon` も確かめた。どれも AVC は出なかった
- この 2 回の前に 2 回流し始めたが、貼る道具の不具合（プロンプトの待ち方と、送るパスワードの取り違え）で途中で止まったので捨てた

| 貼ったもの | 結果（2 回とも同じ） |
|---|---|
| 手順 1〜14 | 2026-09-28 の記録と同じ。手順 14 の `ausearch` は `<no matches>` |
| root のシェルで、root の節の手順 1 | `中断: USER が空か root。公開したユーザー自身のシェルで貼る`。smb.conf は変わらない |
| root の節の手順 1 | `testparm -s` の末尾に `[root]`（`force user = root`、`path = /root`、`valid users = <USER>`） |
| root の節の手順 2 | `samba_root_home` の 1 行 |
| root の節の手順 3 | `/root` の一覧（`.ssh`・`.bashrc` など）、`putting file /etc/hostname as \smb-root-test.txt`、`smb-root-test.txt` の 1 行 |
| root の節の手順 4 | `-rw-r--r--. 1 root root system_u:object_r:admin_home_t:s0 6 … /root/smb-root-test.txt` と `<no matches>` |
| samba-client.md の手順 5・6 | `/root/smb-<USER>@127.0.0.1.cred`、`//127.0.0.1/root` の `cifs`（`vers=3.1.1`）、`cifs write`、`drwx------. 2 <USER> <USER> system_u:object_r:cifs_t:s0 … /mnt/root` |
| 2 人目 | `tree connect failed: NT_STATUS_ACCESS_DENIED`。`smbclient -L` に `root` は出ない |
| root の節の手順 1（2 回目） | `中断: /etc/samba/smb.conf に [root] が既にある` |
| root の節の手順 6 | `libsemanage.semanage_direct_remove_key: Removing last samba_root_home module …` と `0`。smb.conf の末尾には空行が 1 つ残る |
| ロールバックの手順 1〜3 | `semodule -l` に `samba_root_home` が無く、パッケージも消えた。`ausearch -m AVC -ts today` は最後まで `<no matches>` |

- root の節の手順 3 の一覧には `.bash_history` も出た。直前に `sudo -i` で root のシェルを開いたため

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
- samba-client.md の自動マウント（手順 7・8）を `SHARE=root` で行うこと
