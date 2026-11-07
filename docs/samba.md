# Samba のセットアップ（AlmaLinux 10・Windows 11）

- AlmaLinux 10 の PC のホームを Samba で共有し（サーバー）、AlmaLinux 10・Windows 11 の PC からつなぐ（クライアント）
- 検証記録・参考資料・注意点は、各用途の末尾の「補足と注意点」の折りたたみから開く

> [!IMPORTANT]
> - **前提と実行場所（サーバーかクライアントか・どの窓か）は、各項のリードに従う**。AlmaLinux 10 の項は自分のユーザーの bash で行い、`sudo -i`・`su -` のシェルでは行わない
> - AlmaLinux 10 の項は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)と同じく、パスワードを聞かない `sudo` を前提に書いてある。各項のリードの前提に無くても、その項を行うユーザーで[ログインと sudo](almalinux-setup.md#ログインと-sudo)を先に通す
> - Windows 11 の項は、[Windows 11 のセットアップ](windows-setup.md)と同じく、**この PC のデスクトップで、Administrators のユーザーが行う**。PowerShell のブロックは **PowerShell 7** に貼る（7 と貼り付けの設定は、[Windows 11 のセットアップの「アプリを入れる」](windows-setup.md#アプリを入れる)の手順 6〜9）。複数行は、[「Windows Terminal で複数行を 1 つの入力として貼る」](shell-terminal.md#windows-terminal-で複数行を-1-つの入力として貼る)を通した窓に貼る。Windows PowerShell 5.1 に貼る項は、その項のリードに書く。管理者・通常の窓は、各項のリードに従う
> - Windows 11 で[貼り付けの設定](windows-setup.md#貼り付けの設定)より前は **Ctrl+V で貼る**。設定後は GitHub のコピーボタンでコピーし、右クリックで貼れる

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- bash のブロックは、ブラケットペーストの効く端末（GNOME の端末・WezTerm・SSH の先）に貼り、貼った後に Enter を押す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- Windows 11 で GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- AlmaLinux 10 で入れたパッケージ（`samba`・`cifs-utils` など）は、[AlmaLinux 10 のセットアップの「更新」](almalinux-setup.md#更新)の OS の更新で上がる。Windows 11 は[Samba クライアント: Windows 11 の更新](#samba-クライアント-windows-11-の更新)を見る（上げるものは無い）

## AlmaLinux 10 で使う

- Samba のクライアントとサーバー

### Samba クライアント

- クライアントの PC で、Samba の共有を cifs でマウントし、アクセスしたときに自動でマウントされるようにする（fstab と systemd の automount）
- 前提: サーバーで[Samba サーバー](#samba-サーバー)を通してある（Windows や NAS の共有でもよい）
- 実行場所: クライアントの PC の、自分のユーザーの bash（デスクトップの端末か SSH）
- AlmaLinux 10 用の手順。Windows 11 は[Windows の手順](#windows-11-で-samba-クライアントを使う)を、管理者ではない PowerShell 7 で通す
- この項の手順 1 で変数を設定したシェルに貼る

> [!IMPORTANT]
> - **`sudo -i` した root のシェルでは貼らない**（`$(id -u)` が 0 になり、マウントしたファイルが root の所有に見えるため）

1. 変数を設定する（`SERVER` は必ず値を入れる）。

   ```bash
   SERVER=192.0.2.10                    # ← 自分の値に書き換える。サーバーの IP アドレスか DNS 名（Samba サーバーの SERVER_IP）。<SERVER>
   ```

   ```bash
   SMB_USER=${USER}                     # サーバーの Samba ユーザー。AlmaLinux の「Samba サーバー」の設定なら、サーバーの OS のユーザー名。<SMB_USER>
   SHARE=${SMB_USER}                    # 共有名。Samba サーバーの [homes] では、ユーザー名と同じ名前の共有になる。<SHARE>
   MOUNT_POINT=/mnt/${SHARE}            # マウント先（無ければ手順 4 で作る）。<MOUNT_POINT>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in SERVER USER SMB_USER SHARE MOUNT_POINT; do
     printf '%-11s = %s\n' "$v" "${!v}"
   done
   ```

   - 編集が必須なのは `SERVER` だけ
   - サーバーのユーザー名がこの PC と違うとき、NAS や Windows の共有のときは、`SMB_USER` と `SHARE` も書き換える
   - Samba サーバーの[root のホーム](#samba-サーバー-root-のホームも公開する)につなぐときは、`SHARE` を `root` に書き換える（`SMB_USER` は自分のまま）
   - Samba サーバーの[/home](#samba-サーバー-home-も公開する)につなぐときは、`SHARE` を `home` に書き換える（`SMB_USER` は自分のまま）
   - `SERVER` を書き換えたかをここで確かめる
   - `USER` が `root` なら、ここで止めて、自分のユーザーのシェルで貼り直す
   - **新しいシェルを開いたら**、手順 1 の 2 つのブロックを貼り直してから先へ進む

1. cifs-utils を入れ、カーネルのモジュールと、サーバーの 445/tcp に届くかを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # cifs-utils を導入し、モジュールを確かめる
   sudo dnf install -y cifs-utils
   rpm -q cifs-utils
   modinfo -n cifs
   # サーバーの共有用ポートへの接続を確かめる
   timeout 5 bash -c "exec 3<>/dev/tcp/${SERVER:?手順 1 の SERVER が空のまま}/445" && echo '445/tcp に届く'
   ```

   - 入っていれば、`パッケージ cifs-utils-… は既にインストールされています。`（英語の環境では `Package cifs-utils-… is already installed.`）と出る
   - 最後に `445/tcp に届く` と出ればよい
   - `Connection refused` が出る、または 5 秒たっても何も出ないときは、`SERVER` の値と、サーバーの firewalld と smbd（[Samba サーバー](#samba-サーバー)の手順 5・7）を確かめる

1. 共有のパスワードを入力し、資格情報ファイルを作成する。

   ```bash
   # 共有のパスワードを受け取り、入力値を検査する
   IFS= read -rsp "Samba password for ${SMB_USER}@${SERVER}: " PW; echo
   if [ -z "${SMB_USER}" ] || [ -z "${SERVER}" ]; then echo '中断: 手順 1 の SMB_USER か SERVER が空のまま。手順 1 と手順 3 を貼り直す' >&2
   elif [ -z "${PW}" ]; then echo '中断: PW が空のまま。手順 3 を貼り直す' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     printf 'username=%s\npassword=%s\n' "${SMB_USER}" "${PW}" |
       sudo install -m 600 -o root -g root /dev/stdin "/root/smb-${SMB_USER}@${SERVER}.cred" &&
     sudo ls -lZ "/root/smb-${SMB_USER}@${SERVER}.cred"
   fi; unset PW
   ```

   - AlmaLinux の「Samba サーバー」の設定なら、[Samba サーバー](#samba-サーバー)の手順 6 で `smbpasswd -a` に入れたパスワード
   - 資格情報ファイルが root 所有の `0600` ならよい
   - **注意**: 資格情報ファイルの中身は平文で、root なら読める。Samba のパスワードを OS のパスワードと同じにしない

1. 1 度だけ手でマウントして読み書きを確かめ、外す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 共有をマウントし、接続先を確かめる
   sudo mkdir -p "${MOUNT_POINT:?手順 1 の MOUNT_POINT が空のまま}" &&
   sudo mount -t cifs "//${SERVER:?手順 1 の SERVER が空のまま}/${SHARE:?手順 1 の SHARE が空のまま}" "${MOUNT_POINT}" \
     -o "credentials=/root/smb-${SMB_USER:?手順 1 の SMB_USER が空のまま}@${SERVER}.cred,uid=$(id -u),gid=$(id -g),file_mode=0600,dir_mode=0700" && {
     findmnt "${MOUNT_POINT}"
     # テストファイルを書き、読み戻す
     echo "cifs write" > "${MOUNT_POINT}/cifs-test.txt" && cat "${MOUNT_POINT}/cifs-test.txt" && rm "${MOUNT_POINT}/cifs-test.txt"
     # マウント先の属性を確かめる
     ls -ldZ "${MOUNT_POINT}"
     # 共有をアンマウントする
     sudo umount "${MOUNT_POINT}"
   }
   ```

   - `findmnt` に接続先の `cifs` が出て、`cifs write` が出ればよい
   - マウント先が自分の所有で `0700` ならよい
   - `mount error(…)` が出たら、ここで止めて原因を直す（表示と原因は検証記録（`docs/verification/samba-client.md`）と [Samba クライアント の補足と注意点](#samba-クライアント-の補足と注意点)の「注意点」で確かめる）
   - `SHARE=home`（Samba サーバーの `[home]`）では、`cifs-test.txt` の書き込みが `Permission denied` になる。`findmnt` の行が出ていればよい

1. `/etc/fstab` に自動マウントの行を足し、systemd に読み直させる。

   ```bash
   # マウント設定に使う値と既存行を検査する
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

   - `Success, no errors or warnings detected` と出ればよい
   - `中断: …` と出たときは、表示の理由を直してから貼り直す
   - 同じマウント先の行が既にあるときは、その行を確かめる（前にこの手順で足した行なら、この手順は済んでいる）

1. 自動マウントを始め、アクセスしたときにマウントされることを確かめる。

   ```bash
   # マウント先の指定を検査する
   if [ -z "${MOUNT_POINT}" ]; then echo '中断: 手順 1 の MOUNT_POINT が空のまま。手順 1 を貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     # 自動マウントと共有の読み書きを確かめる
     sudo systemctl start "$(systemd-escape -p --suffix=automount "${MOUNT_POINT}")" &&
     systemctl is-active "$(systemd-escape -p --suffix=automount "${MOUNT_POINT}")" &&
     ls "${MOUNT_POINT}" > /dev/null && findmnt -R "${MOUNT_POINT}" &&
     echo "automount write" > "${MOUNT_POINT}/automount-test.txt" && cat "${MOUNT_POINT}/automount-test.txt" &&
     rm "${MOUNT_POINT}/automount-test.txt"
     # SELinux の拒否を調べる
     sudo ausearch -m AVC -ts recent
   fi
   ```

   - `active` と `autofs`・`cifs`、`automount write` が出ればよい
   - `SHARE=home` で書き込みが `Permission denied` でも、`active` と `findmnt` の表示があればよい
   - 最後の `ausearch` は `<no matches>`

#### Samba クライアント: GNOME Files で開く

- クライアントの PC で、Samba の共有を GNOME Files（gvfs）でつなぎ、端末の `gio` で確かめて外す
- 前提: サーバーで[Samba サーバー](#samba-サーバー)を通してある（Windows や NAS の共有でもよい）。[Samba クライアント](#samba-クライアント)の cifs のマウントは要らない
- 実行場所: クライアントの PC の、GNOME にログインした自分のユーザーの端末（bash）
- この項の手順 1 で変数を設定したシェルで貼る

1. 変数を設定する（`SERVER` は必ず値を入れる）。

   ```bash
   SERVER=192.0.2.10                    # ← 自分の値に書き換える。サーバーの IP アドレスか DNS 名（Samba サーバーの SERVER_IP）。<SERVER>
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

1. 共有をマウントし、接続先と共有内の一覧を確認する。

   ```bash
   # GNOME Files の共有に接続する
   /usr/bin/gio mount "smb://${SMB_USER:?この項の手順 1 の SMB_USER が空のまま}@${SERVER:?この項の手順 1 の SERVER が空のまま}/${SHARE:?この項の手順 1 の SHARE が空のまま}"
   if [ -z "${SERVER}" ] || [ -z "${SMB_USER}" ] || [ -z "${SHARE}" ]; then echo '中断: この項の手順 1 の SERVER・SMB_USER・SHARE を設定してから貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     # 接続先とマウント先を確かめる
     /usr/bin/gio mount -l | grep -F "${SERVER}"
     ls "/run/user/$(id -u)/gvfs/"
     # 共有内の一覧を表示する
     /usr/bin/gio list "smb://${SMB_USER}@${SERVER}/${SHARE}/"
   fi
   ```

   - ドメインは、Enter で既定のままでよい
   - パスワードは、共有のパスワード（AlmaLinux の「Samba サーバー」の設定なら、[Samba サーバー](#samba-サーバー)の手順 6 で `smbpasswd -a` に入れたもの）
   - 画面から開くときは、「ファイル」のサイドバーの「Network」を開き、「Server address」の欄に `smb://<SMB_USER>@<SERVER>/<SHARE>` を入れて「接続」を押す
   - 画面では、認証の画面で「期限なしで記憶する」を選ぶと、パスワードが GNOME のキーリングに保存される
   - `Mount(0):` に指定した共有が出ればよい
   - `smb-share:` と共有の中の一覧が出ればよい

1. 共有を外す。

   ```bash
   /usr/bin/gio mount -u "smb://${SMB_USER:?この項の手順 1 の SMB_USER が空のまま}@${SERVER:?この項の手順 1 の SERVER が空のまま}/${SHARE:?この項の手順 1 の SHARE が空のまま}"
   ```

   - 何も出ずに終わればよい
   - 画面では、サイドバーの共有の横の取り出しのボタンで外す

<details id="samba-クライアント-の補足と注意点">
  <summary>Samba クライアント の補足と注意点</summary>

**注意点**

- **サーバーに届かないとき**（VM で測った値）
  - マウントしていない状態でアクセスすると、`ls: cannot open directory '<MOUNT_POINT>': No such device` で失敗する。接続を断られると 1 秒以内、応答が無いと約 11 秒
  - 接続に失敗すると、`systemctl --failed` に `mnt-<SHARE>.mount` が出て、`systemctl is-system-running` が `degraded` になる。サーバーに届くようになってからアクセスし直す
  - **マウントしている間に届かなくなると、ファイルを開くコマンドが長時間止まることがある**。サーバーへの接続を確認してからアクセスし直す
  - 使っていなければ、届かなくても 1 分の idle-timeout で外れた
- **サーバーで直接変えたもの**（サーバーのシェルや同期の道具などで、Samba を通さずに）
  - samba.md の今のサーバー（`smb3 directory leases = no`）なら、`ls` にすぐ出る。消したファイルを `stat` で引くと、約 1 秒はまだあるように見える（`actimeo=1`）
  - サーバーを変えられないときは、マウントのオプションに `nohandlecache` を足す
- **GNOME Files（`smb://`）は、サーバーで変えたものを自動では出さない**: F5 ですぐ出る。gvfs はディレクトリのリースを使わないので、サーバーの設定によらない（検証記録）
- **`sudo mount -a` はエラーを出す**: 自動マウントの行について、1 回目は `mount error(16): Device or resource busy`
  - パスをたどった時点で systemd がマウントし、そのあと mount.cifs が同じ場所にもう一度マウントしようとするため
- **パスワードを変えたら**: サーバーで変え（samba.md では `sudo smbpasswd <SMB_USER>`）、この PC で手順 3 を貼り直す
- **空白を含むユーザー名・共有名・マウント先は扱わない**: 手順 5 で中断する（fstab の欄を空白で区切るため）
- **SELinux**: マウントしたファイルの型は `cifs_t`
  - ログインしたユーザーのプログラムは、そのまま読み書きできる
  - 制限のあるサービス（Apache など）から使うなら、そのサービスの boolean（`httpd_use_cifs` など）が要る
- **貼り方**: bash 5.1 以降でブラケットペーストが有効なら、貼った全体を実行前に読み取るため、`sudo` の後ろの行を守る囲みは要らない
  - ブロックの先頭の `if … fi` は、変数が空なら中断するために残す
- この項の手順 3 の資格情報ファイルは平文で、root なら読める。Samba のパスワードを OS のパスワードと同じにしない
- LAN 上の通信は暗号化されない。マウント中にサーバーへ届かなくなると、ファイルを開くコマンドが長時間止まることがある

**[Samba クライアント](#samba-クライアント)のリード**

- **手順 3 には対話入力がある**（共有のパスワード）

**[Samba クライアント](#samba-クライアント)の手順 1**

- 最後に値を読み戻して確かめる

**[Samba クライアント](#samba-クライアント)の手順 1: 変数について**

- `SMB_USER` を `USER`（この PC のユーザー名）と分けてあるのは、NAS や Windows ではサーバー側のアカウント名が違うことがあるため
- samba.md のサーバーは OS のアカウント名で Samba ユーザーを登録するので、この PC と同じ名前なら既定のままでよい
- samba.md の `[homes]` は、Samba ユーザーと同じ名前の共有を見せる。ほかの共有につなぐなら `SHARE` を書き換える
- samba.md の `[root]` は、自分の Samba ユーザーのまま入る共有。`SHARE=root` だけを変えれば、資格情報ファイル（手順 3）は自分の共有と同じものになり、マウント先は `/mnt/root` になる
- samba.md の `[home]` も同じで、`SHARE=home` だけを変える。マウント先は `/mnt/home` になり、その下にユーザーごとのディレクトリが並ぶ
- `SERVER` に NetBIOS 名は使えない。samba.md のサーバーは NetBIOS（nmbd）を動かさない。IP アドレスか、DNS（または `/etc/hosts`）で引ける名前にする
- `SMB_USER`・`SHARE`・`MOUNT_POINT` に空白を入れない。fstab の欄は空白で区切るので、手順 5 で中断する
- `SERVER` は既定値のままでもエラーにならないので、書き換えたかを手順 1 で確かめる
- 変数はそのシェルの中だけで有効

**[Samba クライアント](#samba-クライアント)の手順 2**

- `cifs-utils-7.7-…` と、`…/kernel/fs/smb/client/cifs.ko.xz` のパスが出る

**[Samba クライアント](#samba-クライアント)の手順 2: cifs-utils**

- Workstation で入れた PC には、cifs-utils が最初から入っている

**[Samba クライアント](#samba-クライアント)の手順 3**

- `-rw------- … root root … admin_home_t … /root/smb-<SMB_USER>@<SERVER>.cred` の 1 行が出ればよい

**[Samba クライアント](#samba-クライアント)の手順 3: パスワードの扱い**

- パスワードは、コマンドラインにもシェルの履歴にも残らない
- 最後の `unset PW` で、シェルの変数からもパスワードを消す

**[Samba クライアント](#samba-クライアント)の手順 4**

- `findmnt` に `//<SERVER>/<SHARE>` の `cifs` の行（`vers=3.1.1` を含む）、続いて `cifs write` が出ればよい
- `ls -ldZ` は `drwx------ … <USER> <USER> … cifs_t …`

**[Samba クライアント](#samba-クライアント)の手順 4: 出力の意味**

- `ls -ldZ` の `drwx------ … <USER> <USER>` は、自分の所有で、ほかのユーザーは入れないこと
- `SHARE=home` で `cifs-test.txt` の書き込みが `Permission denied` になるのは、共有の直下が `/home` で、サーバーの SELinux が作るのを断るため

**[Samba クライアント](#samba-クライアント)の手順 5**

- 足した 1 行が表示され、最後に `Success, no errors or warnings detected` と出ればよい

**[Samba クライアント](#samba-クライアント)の手順 6**

- 通常の共有では、`active`、`findmnt` の `autofs` と `cifs` の 2 行、`automount write` が出ればよい
- `SHARE=home` では、手順 4 と同じく共有直下への書き込みが `Permission denied` になる。`active` と `findmnt` の 2 行が出ればマウントの確認はできている

**[Samba クライアント](#samba-クライアント)の手順 6: 自動マウントの動き**

- `SHARE=home` の `Permission denied` は、サーバーの SELinux による拒否
- 以後は `<MOUNT_POINT>` をふつうのディレクトリとして使う
- 使わないまま 1 分ほどたつと外れ、次にアクセスしたときにまたマウントされる
- 再起動した後も、アクセスしたときにマウントされる

**[Samba クライアント: GNOME Files で開く](#samba-クライアント-gnome-files-で開く)のリード**

- fstab のマウントとは別の仕組み（gvfs）。ログインしたユーザーがつなぐので、root も資格情報ファイルも要らない
- 画面では「ファイル」（Nautilus）から開く。この項のコマンドは、同じ仕組みを端末から使う `gio`
- **この項の手順 4 には対話入力がある**（ドメインとパスワード）

**[Samba クライアント: GNOME Files で開く](#samba-クライアント-gnome-files-で開く)の手順 1**

- 最後に値を読み戻して確かめる

**[Samba クライアント: GNOME Files で開く](#samba-クライアント-gnome-files-で開く)の手順 2: パッケージ**

- `gvfs-smb` が gvfs の SMB のバックエンド（libsmbclient を使う）、`gvfs-fuse` が GIO を使わないアプリ向けの `/run/user/<UID>/gvfs/`
- どちらも GNOME のグループ（`gnome-desktop`）の必須パッケージなので、Workstation にも Server with GUI にも入っている

**[Samba クライアント: GNOME Files で開く](#samba-クライアント-gnome-files-で開く)の手順 3**

- 入れた後、ログインし直さなくてよい

**[Samba クライアント: GNOME Files で開く](#samba-クライアント-gnome-files-で開く)の手順 3: ログインし直さなくてよい理由**

- VM で、動いている gvfsd がそのまま SMB につないだ

**[Samba クライアント: GNOME Files で開く](#samba-クライアント-gnome-files-で開く)の手順 4**

- ドメインとパスワードを聞かれる（`Domain [SAMBA]:` と `Password:`。その前に、`認証が必要です`（英語の環境では `Authentication Required`）と、パスワードの入力を求める 1 行が出る）
- `Mount(0): <SERVER> 上の <SHARE> -> smb://<SMB_USER>@<SERVER>/<SHARE>/` の 1 行が出ればよい（英語の環境では `<SHARE> on <SERVER>`）
- 続いて `smb-share:server=<SERVER>,share=<SHARE>,user=<SMB_USER>`（端末では、`'` で囲まれて出る）と、共有の中の一覧（隠しファイルは出ない）が出る
- 画面では、サイドバーに共有が出る

**[Samba クライアント: GNOME Files で開く](#samba-クライアント-gnome-files-で開く)の手順 4: パスワードの保存**

- `/usr/bin/gio mount` は、パスワードを保存しない

**[Samba クライアント: GNOME Files で開く](#samba-クライアント-gnome-files-で開く)の手順 4: 使い方**

- GIO を使わないアプリからは、`/run/user/<UID>/gvfs/smb-share:…/` の下で読み書きできる
- サーバーで変えたものは、「ファイル」には自動では出ない。F5 で出る（この折りたたみの「注意点」）

**[Samba クライアント: GNOME Files で開く](#samba-クライアント-gnome-files-で開く)の手順 5: 外した後**

- 外した共有は、`/usr/bin/gio mount -l` からも `/run/user/<UID>/gvfs/` からも消える

**選択した方針**

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
  - `uid=` / `gid=`: 無いと、マウントした側のファイルが root の所有に見える（[Samba サーバー: サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 5 の補足）
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
- **GNOME Files（gvfs）は別の項にした**
  - fstab のマウントとは別の仕組みで、ログインしたユーザーの gvfsd が libsmbclient でつなぐ。root も資格情報ファイルも要らない
  - つながるのはログインしている間だけ。GIO を使わないアプリからは `/run/user/<UID>/gvfs/` の下に見える

**参照**

- 検証記録（`docs/verification/samba-client.md`）
- 補足の実測は検証記録（`docs/verification/samba-client.md` の「補足の実測」）
- [Chapter 5. Mounting an SMB Share — Managing file systems (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/managing_file_systems/mounting-an-smb-share)（資格情報ファイル、fstab の例、よく使うオプション）
- [Chapter 10. Browsing files on a network share — Using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_the_gnome_desktop_environment/browsing-files-on-a-network-share)
- [Chapter 6. Managing storage volumes in GNOME — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/managing-storage-volumes-in-gnome)（GIO と、`gvfs-fuse` の `/run/user/UID/gvfs/`）
- `man mount.cifs`（`credentials=`、`uid=`、`file_mode=`、`soft`、`echo_interval`、`actimeo`、`nohandlecache`、`max_cached_dirs`）/ `modinfo cifs`（`dir_cache_timeout`）
- `man systemd.mount`（`x-systemd.automount`、`x-systemd.idle-timeout`、`nofail`、`_netdev`）/ `man systemd-fstab-generator`
- `man findmnt`（`--verify`）/ `man gio`
- cifs-utils 7.7 のソース（`mount.cifs.c` の `open_cred_file`・`parse_cred_line`・`set_password`・`parse_opt_token`）
- [Samba でホームディレクトリを公開する手順](#samba-サーバー)（サーバー側）

</details>

---

### Samba サーバー

- サーバーで、自分のユーザーのホームを Samba（SMB3）で公開する
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)を通してある
- 実行場所: サーバーの、公開するユーザー自身の bash（デスクトップの端末か SSH）。手順 8 だけは、つなぐ側の別のマシン
- この項の手順 1 で変数を設定したシェルに貼る
- この項の後に行う項:
  - root のホーム（`/root`）も公開するなら、[root のホームも公開する](#samba-サーバー-root-のホームも公開する)を行う
  - `/home` の下のすべてのホーム（ほかのユーザーのホームも）を 1 つの共有で開くなら、[/home も公開する](#samba-サーバー-home-も公開する)を行う
  - サーバーの上で読み書きを確かめるとき（クライアントでつなげないときの切り分けにも）は、[サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)を行う
  - 接続元を絞る場合は、最後に[接続元を絞る](#samba-サーバー-接続元を絞る)を行う

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
   # Samba と接続用ツールを導入する
   sudo dnf install -y samba samba-client cifs-utils
   printf '\n\033[7m 確認 \033[0m\n'
   rpm -q samba samba-client cifs-utils
   ```

1. 既定の smb.conf を退避して最小構成に置き換え、構文を検査する。

   ```bash
   if [ -z "${WORKGROUP}" ]; then echo '中断: 手順 1 の WORKGROUP が空のまま。値を入れて貼り直す' >&2; else
     # 既存の設定ファイルの控えを作成する
     sudo cp -an /etc/samba/smb.conf /etc/samba/smb.conf.orig
     # 共有の設定を書き込む
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

   - `Loaded services file OK.` と `ROLE_STANDALONE`、`smb3 directory leases = No` が出ればよい
   - `中断:` と出たら、何も書いていない

1. SELinux の boolean `samba_enable_home_dirs` を on にする。

   ```bash
   # ホームの公開を SELinux で許可する
   sudo setsebool -P samba_enable_home_dirs on
   printf '\n\033[7m 確認 \033[0m\n'
   sudo getsebool samba_enable_home_dirs        # samba_enable_home_dirs --> on
   ```

1. firewalld で 445/tcp を開ける。

   ```bash
   # 共有用のポートを開放し、設定を反映する
   sudo firewall-cmd --permanent --add-port=445/tcp && sudo firewall-cmd --reload
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --list-ports               # 445/tcp が含まれる
   ```

1. Samba ユーザーを登録し、登録結果を確認する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # アカウントの存在を照会する
   id "${USER}"
   # Samba の認証用ユーザーを追加する
   sudo smbpasswd -a "${USER}"
   sudo pdbedit -L                              # <USER>:1000: の 1 行が出る
   ```

   - **端末で対話入力する**。新しいパスワードを 2 回聞かれる
   - `id` で、OS のアカウントが存在することを確かめる
   - 端末で新しいパスワードを入力する
   - 自分のユーザー名が登録結果に出ればよい

1. smb.service を有効にして起動する。

   ```bash
   # Samba サービスを常駐させる
   sudo systemctl enable --now smb.service
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl is-active smb.service              # active
   ss -ltnp | grep -E ':(139|445) '             # 445 だけが LISTEN。139 は出ない
   ```

1. 別のマシンから、クライアントで接続する。

   - `<SERVER_IP>` と `<USER>` は値に読み替える
   - Windows: エクスプローラーのアドレス欄に `\\<SERVER_IP>\<USER>`。資格情報は `<USER>` と手順 6 のパスワード
     - ドライブ文字に割り当てて、サインインのたびにつなぐなら、[Samba クライアントの Windows 11 で使う](#windows-11-で-samba-クライアントを使う)
   - macOS: Finder の「サーバへ接続」に `smb://<SERVER_IP>/<USER>`
   - Linux: AlmaLinux 10 なら[Samba クライアント](#samba-クライアント)を通す（自動マウント・GNOME Files）
   - ほかは `smbclient "//<SERVER_IP>/<USER>" -U <USER>` または `mount -t cifs "//<SERVER_IP>/<USER>" <mountpoint> -o username=<USER>`
   - 共有のファイルが見えればよい
   - つなげないときは、[サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)で、サーバーの上から読み書きを確かめる

#### Samba サーバー: root のホームも公開する

- サーバーで、`\\<SERVER_IP>\root` で `/root` を読み書きできるようにする。つなぐのは[Samba サーバー](#samba-サーバー)の手順 6 で登録した自分の Samba ユーザーのままで、root の Samba ユーザーは作らない
- 前提: [Samba サーバー](#samba-サーバー)を通してある
- 実行場所: サーバーの、公開したユーザー自身の bash（デスクトップの端末か SSH）。`${USER}` を `valid users` に書く。この項の手順 4 だけは、つなぐ側の別のマシン
- **root のホーム（`/root`）を公開しないなら、この項は不要**

> [!WARNING]
> - Samba のパスワードは root のパスワードと同じ重みになる。`/root/.bashrc`・`/root/.ssh/authorized_keys` の書き換えで root の任意コマンドを動かせる
> - パスワードを長くし、[接続元の制限](#samba-サーバー-接続元を絞る)も検討する

1. smb.conf の末尾に `[root]` 共有を足し、構文を検査する。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。公開したユーザー自身のシェルで貼る' >&2
   elif grep -q '^\[root\]' /etc/samba/smb.conf; then echo '中断: /etc/samba/smb.conf に [root] が既にある' >&2
   else
     # root の共有設定を追記する
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
   # SELinux の許可ルールをファイルに保存する
   cat > /tmp/samba_root_home.cil <<'EOF'
   (allow smbd_t admin_home_t (dir (add_name create getattr ioctl link lock open read remove_name rename reparent rmdir search setattr unlink watch watch_reads write)))
   (allow smbd_t admin_home_t (file (append create getattr ioctl link lock open read rename setattr unlink watch watch_reads write)))
   (allow smbd_t admin_home_t (lnk_file (append create getattr ioctl link lock read rename setattr unlink watch watch_reads write)))
   EOF
   # SELinux のモジュールを登録し、作業ファイルを消す
   sudo semodule -i /tmp/samba_root_home.cil
   rm /tmp/samba_root_home.cil
   printf '\n\033[7m 確認 \033[0m\n'
   sudo semodule -l | grep -x samba_root_home   # samba_root_home
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

   - [Samba サーバー](#samba-サーバー)の手順 8 の `<USER>`（共有名）を `root` に読み替える。資格情報は `<USER>` と[Samba サーバー](#samba-サーバー)の手順 6 のパスワードのまま
   - Windows: エクスプローラーのアドレス欄に `\\<SERVER_IP>\root`
   - AlmaLinux 10 の PC なら、[Samba クライアント](#samba-クライアント)の手順 1 で `SHARE=root` にする（`SMB_USER` は自分のまま）

#### Samba サーバー: /home も公開する

- サーバーで、`\\<SERVER_IP>\home` で `/home` を開き、その下のすべてのユーザーのホームを読み書きできるようにする。つなぐのは[Samba サーバー](#samba-サーバー)の手順 6 で登録した自分の Samba ユーザーのままで、ほかのユーザーは Samba に登録しなくてよい
- 前提: [Samba サーバー](#samba-サーバー)を通してある
- 実行場所: サーバーの、公開したユーザー自身の bash（デスクトップの端末か SSH）。`${USER}` を `valid users` に書く。この項の手順 3 だけは、つなぐ側の別のマシン
- **`/home` を公開しないなら、この項は不要**

> [!WARNING]
> - Samba のパスワードで、ほかのユーザーの `~/.bashrc`・`~/.ssh/authorized_keys` も読み書きできる
> - `sudo` が使えるユーザーのホームを書き換えると、root で任意のコマンドを動かせる。長いパスワードと[接続元の制限](#samba-サーバー-接続元を絞る)を検討する

1. smb.conf の末尾に `[home]` 共有を足し、構文を検査する。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。公開したユーザー自身のシェルで貼る' >&2
   elif grep -q '^\[home\]' /etc/samba/smb.conf; then echo '中断: /etc/samba/smb.conf に [home] が既にある' >&2
   else
     # /home の共有設定を追記する
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

   - [Samba サーバー](#samba-サーバー)の手順 8 の `<USER>`（共有名）を `home` に読み替える。資格情報は `<USER>` と[Samba サーバー](#samba-サーバー)の手順 6 のパスワードのまま
   - Windows: エクスプローラーのアドレス欄に `\\<SERVER_IP>\home`。ユーザーごとのフォルダーが並ぶ。フォルダーの外（`/home` の直下）には作れない
   - AlmaLinux 10 は[Samba クライアント](#samba-クライアント)の手順 1 で `SHARE=home` にし、`SMB_USER` は自分のままにする
   - [Samba クライアント](#samba-クライアント)の手順 4・6 の共有直下への書き込みは `Permission denied` になる

#### Samba サーバー: サーバーの上で動作を確かめる

- サーバーの上の `smbclient` と `mount.cifs` で、共有の読み書きを確かめる（クライアントでつなげないときの切り分けにも使う）
- 前提: [Samba サーバー](#samba-サーバー)を通してある
- 実行場所: サーバーの、公開したユーザー自身の bash（デスクトップの端末か SSH）
- この項の手順 8・9 は、[root のホームも公開した](#samba-サーバー-root-のホームも公開する)ときだけ行う
- この項の手順 10・11 は、[/home も公開した](#samba-サーバー-home-も公開する)ときだけ行う
- サーバー自身からの接続は firewalld を通らない。445/tcp の開放は、別のホストからつないで確かめる

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
   # 資格情報の保存先を決め、パスワードを受け取る
   AUTHFILE=/run/user/$(id -u)/smb-auth
   read -rsp "Samba password for ${USER}: " PW; echo
   ```

   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼ると、入力を終えられなかったときも後ろの資格情報ファイル作成が動く）

1. 資格情報ファイルを作る。

   ```bash
   # 資格情報をファイルに保存し、変数から消去する
   ( umask 077; printf 'username=%s\npassword=%s\n' "${USER}" "${PW}" > "${AUTHFILE}" ); unset PW
   printf '\n\033[7m 確認 \033[0m\n'
   ls -l "${AUTHFILE}"                          # -rw------- で自分の所有
   ```

1. `smbclient` で、共有の一覧と読み書きを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 公開されている共有とファイルの一覧を取得する
   smbclient -L //localhost -A "${AUTHFILE}"    # IPC$ と <USER> の 2 つだけ出る
   smbclient "//localhost/${USER}" -A "${AUTHFILE}" -c 'ls'
   # ファイルを送受信し、属性と内容を照合する
   smbclient "//localhost/${USER}" -A "${AUTHFILE}" -c "put /etc/hostname smb-test.txt; get smb-test.txt /tmp/smb-test.txt; ls smb-test.txt"
   ls -lZ ~/smb-test.txt /tmp/smb-test.txt      # -rw-r--r--。ホーム側は user_home_t、/tmp 側は user_tmp_t
   cmp /etc/hostname /tmp/smb-test.txt && echo "content identical"
   # サーバーの IP アドレス経由で共有を確かめる
   smbclient "//${SERVER_IP}/${USER}" -A "${AUTHFILE}" -c 'ls smb-test.txt'
   ```

1. `mount.cifs` でマウントして書き込み、`smbstatus` でセッションを確かめる。

   ```bash
   # 共有をテスト用のディレクトリにマウントする
   sudo mkdir -p /mnt/smbtest
   sudo mount -t cifs "//127.0.0.1/${USER}" /mnt/smbtest -o "credentials=${AUTHFILE},uid=$(id -u),gid=$(id -g)"
   printf '\n\033[7m 確認 \033[0m\n'
   # マウントの状態を確かめる
   mount | grep cifs                            # vers=3.1.1
   # ファイルを書き、内容と属性を確かめる
   echo "cifs write" > /mnt/smbtest/cifs-test.txt && cat /mnt/smbtest/cifs-test.txt
   ls -lZ /mnt/smbtest/cifs-test.txt ~/cifs-test.txt
   # SMB の接続方式と署名を確かめる
   sudo smbstatus                               # Protocol Version: SMB3_11、Signing: partial(AES-128-CMAC)
   ```

   - **次の手順は、`smbstatus` の出力を確かめてから貼る**（この項の手順 6 でアンマウントすると見えなくなる）

1. アンマウントして、マウントポイントを消す。

   ```bash
   sudo umount /mnt/smbtest && sudo rmdir /mnt/smbtest
   ```

1. 後片付けとして、検証で作ったファイルと資格情報ファイルを消し、AVC を確かめる。

   ```bash
   # 確認に使ったファイルと資格情報を消去する
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
   - `/root` の一覧と、書き込んだ `smb-root-test.txt` が出ればよい
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼ると、認証や書き込みに失敗しても後ろのテスト用ファイルの削除が動く）

1. root のホームも公開したときだけ、作ったファイルの所有者とラベルを確かめて消し、AVC を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 作成したファイルの属性を確かめ、削除する
   sudo ls -lZ /root/smb-root-test.txt          # -rw-r--r--. root root … admin_home_t
   sudo rm /root/smb-root-test.txt
   # SELinux の拒否を調べる
   sudo ausearch -m AVC -ts recent              # <no matches>
   ```

   - ファイルは `root root` の所有で、ラベルは `admin_home_t`
   - `ausearch` が `<no matches>` ならよい
   - `/home` を公開していないなら、この項の手順 10・11 は飛ばす

1. `/home` も公開したときだけ、`/home` の一覧と、自分のホームへの書き込みを確かめる。

   ```bash
   smbclient //localhost/home -U "${USER}" -c "ls; put /etc/hostname ${USER}/smb-home-test.txt; ls ${USER}/smb-home-test.txt"
   ```

   - パスワードは、[Samba サーバー](#samba-サーバー)の手順 6 で登録した `<USER>` の Samba のパスワード
   - ユーザーのディレクトリの一覧と、書き込んだ `smb-home-test.txt` が出ればよい
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼ると、認証や書き込みに失敗しても後ろのテスト用ファイルの削除が動く）

1. `/home` も公開したときだけ、作ったファイルの所有者とラベルを確かめて消し、AVC を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 作成したファイルの属性を確かめ、削除する
   ls -lZ ~/smb-home-test.txt                   # -rw-r--r--. <USER> root … user_home_t
   rm ~/smb-home-test.txt
   # SELinux の拒否を調べる
   sudo ausearch -m AVC -ts recent              # <no matches>
   ```

   - ファイルの所有者は `<USER>`（root ではない）、グループは `root`、ラベルは `user_home_t`
   - `ausearch` が `<no matches>` ならよい

#### Samba サーバー: 接続元を絞る

- サーバーで、445/tcp に届く送信元を、指定したサブネットだけに絞る
- 前提: [Samba サーバー](#samba-サーバー)を通してある
- 実行場所: サーバーの、自分のユーザーの bash（デスクトップの端末か SSH）
- **接続元を制限しないなら、この項は不要**

1. 送信元サブネットを空白区切りで入れ、445/tcp の開放を rich rule に置き換える。

   ```bash
   ALLOW_FROM="192.0.2.0/24 198.51.100.0/24"   # ← 自分の値に書き換える。<ALLOW_FROM>
   ```

   ```bash
   if [ -z "${ALLOW_FROM}" ]; then echo '中断: ALLOW_FROM が空のまま。値を入れて貼り直す' >&2; else
   # ポート全体への接続許可を解除する
   sudo firewall-cmd --permanent --remove-port=445/tcp
   # 指定したサブネットからの接続を許可する
   for src in ${ALLOW_FROM}; do
     sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=${src} port port=445 protocol=tcp accept"
   done
   # firewalld の設定を反映する
   sudo firewall-cmd --reload
   printf '\n\033[7m 確認 \033[0m\n'
   sudo firewall-cmd --list-rich-rules        # source address に実際のサブネットが入っていることを確認する
   fi
   ```

<details id="samba-サーバー-の補足と注意点">
  <summary>Samba サーバー の補足と注意点</summary>

**注意点**

- **自ホストからの検証は firewalld を通らない**: 445 の開け忘れは、別ホストか network namespace から接続して初めて分かる
- **Samba のパスワードは OS と別**: OS のパスワードを変えても Samba 側は変わらない。変えるときは `sudo smbpasswd "${USER}"`
- **ユーザー名は OS アカウントと一致が必須**
  - 存在しないユーザー、間違ったパスワードは、どちらも `NT_STATUS_LOGON_FAILURE`
  - 他人のホーム（`//<SERVER_IP>/<別のユーザー>`。`[root]` を足していなければ `//<SERVER_IP>/root` も）は、認証が通っても `tree connect failed: NT_STATUS_ACCESS_DENIED`
- **`create mask` を変えても既存ファイルのモードは変わらない**: 手順 3 の前にホームに置いていたファイルのモードはそのまま
- **`nmb` を起動しない構成なので、Windows のエクスプローラーで「ネットワーク」から見つけることはできない**: `\\<SERVER_IP>\<USER>` を直接入力する。一覧に出したいなら `wsdd`
- **クライアントにも、サーバーとは別の一覧のキャッシュがある**
  - GNOME Files（`smb://`）は、サーバーで変えたものを自動では出さない。F5 ですぐ出る（[Samba クライアント の補足と注意点](#samba-クライアント-の補足と注意点)の「注意点」）
  - Windows は、ディレクトリのリースが無いときも、一覧を最長 10 秒キャッシュする（Microsoft の文書の `DirectoryCacheLifetime`）
  - macOS は、SMB 2/3 の一覧を手元にキャッシュする（Apple の文書。止めるには `nsmb.conf` の `dir_cache_max_cnt=0`）
- この項の手順 5 は、public ゾーンの全 NIC で 445/tcp を開く。public ゾーンに VPN のインターフェースがあれば、VPN 越しにも届く。望まない場合は [接続元を絞る](#samba-サーバー-接続元を絞る)を行う
- LAN 上の通信は暗号化されない。署名だけで通信する（`smbstatus` の `Encryption` 欄が `-`）

**[Samba サーバー](#samba-サーバー)のリード**

- **手順 6 には対話入力がある**（パスワード）

**[Samba サーバー](#samba-サーバー)の手順 1: 変数について**

- `SERVER_IP` を自動取得にしているのは、設定には使わず検証と案内にしか使わないため（GNOME Remote Desktop の手順書で手入力なのは、値が証明書の SAN に入るから）
- `SERVER_IP` が間違っていても、[サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 4 の `smbclient "//${SERVER_IP}/..."` が失敗するだけで、設定は壊れない
- 公開するのは `${USER}`（このシェルのユーザー）のホーム。`sudo -i` した root のシェルでは `root` になり、手順 6 で root のホームを公開してしまうので、読み戻しで必ず確認する
- root のシェルで進めると、root の Samba ユーザーができるうえ、`/root` のラベル（`admin_home_t`）は手順 4 の boolean の対象外なので、[サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 4 の `ls` も通らない。root のホームは、自分のユーザーのまま入れる `[root]` 共有で足す（[root のホームも公開する](#samba-サーバー-root-のホームも公開する)）
- `ALLOW_FROM` は[接続元を絞る](#samba-サーバー-接続元を絞る)でしか使わないので、手順 1 ではなくその節の冒頭で設定する
- 変数はそのシェルの中だけで有効

**[Samba サーバー](#samba-サーバー)の手順 2: パッケージ**

- `samba`（baseos）が smbd 本体。依存で `samba-common-tools`（`smbpasswd` / `pdbedit` / `testparm` / `smbstatus`）、`samba-libs`、`samba-dcerpc` などが入る
- `samba-client`（`smbclient`）と `cifs-utils`（`mount.cifs`）は、[サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の検証にしか使わない。サーバー上で検証しないなら入れなくてよい

**[Samba サーバー](#samba-サーバー)の手順 3**

- `Loaded services file OK.` と `Server role: ROLE_STANDALONE` が出て、`[global]` に `smb3 directory leases = No` があればよい

**[Samba サーバー](#samba-サーバー)の手順 5: firewalld**

- 445/tcp は public ゾーンの全 NIC で開く
- 自ホストからの `smbclient //localhost/...` や `//${SERVER_IP}/...` は `lo` を通るため、**firewalld の設定を通らない**（`filter_INPUT` の `iifname "lo" accept` で先に受理される）
- 開け忘れはサーバー上の検証では見つからない。検証記録の付録（`docs/verification/samba.md` の「network namespace から firewalld 越しに到達する」）

**[Samba サーバー](#samba-サーバー)の手順 6**

- `<USER>:1000:` の 1 行が出ればよい

**[Samba サーバー](#samba-サーバー)の手順 6: Samba のパスワード**

- Samba のパスワードは、OS のパスワードとは別に保存される

**[Samba サーバー](#samba-サーバー)の手順 7: サービス**

- `smb.service` は `nmb.service` を `Requires` / `Wants` していない（`After=` に並ぶだけ）。nmb を起動しなくても単独で動く
- 起動すると `/var/log/samba/` に `log.smbd` と `log.rpcd_*`（`samba-dcerpcd` が起動する RPC ヘルパーのログ）ができる。`cups` 無しでも、本手順の `smb.conf` なら CUPS 関連のエラーは出ない

**[Samba サーバー](#samba-サーバー)の手順 8: ディレクトリのリース**

- Windows では、サーバーで変えたファイルやディレクトリは、F5 を押さなくても出る（手順 3 の `smb3 directory leases = no`）

**[Samba サーバー: root のホームも公開する](#samba-サーバー-root-のホームも公開する)のリード**

- smbd は、この共有の中を root として読み書きする（`force user = root`）。作ったファイルは root の所有になる
- `/root` の読み書きは、この項の手順 3 の後に、[サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 8・9 で確かめる
- この項の手順 3 で smb.service を再起動すると、ほかのクライアントの接続が切れる
- **公開されるのは `/root` の全体**
  - `/root` と、その中の `admin_home_t` のファイル・ディレクトリは、[root のホームも公開する](#samba-サーバー-root-のホームも公開する)の手順 2 のモジュールで許す
  - `.ssh`（`ssh_home_t`）・`.gnupg`（`gpg_secret_t`）・`.config`（`config_home_t`）などは、一般ユーザーのホームと同じ `user_home_type` のラベルなので、手順 4 の boolean で既に許されている
- **入るのは `<USER>`**: root の Samba ユーザーは登録しない
- **クライアントでの見え方**: [Samba クライアント](#samba-クライアント) の `mount.cifs` は `uid=` / `gid=` で自分の所有に見せるが、サーバーでは `root root` で書かれる

**[Samba サーバー: root のホームも公開する](#samba-サーバー-root-のホームも公開する)の手順 1: [root] の各行**

- `path = /root`: `[homes]` と違い、共有の場所を書く普通の共有
- `valid users = ${USER}`: 入れるのは `<USER>` だけ。ほかの Samba ユーザーは、認証が通っても共有には入れない
- `force user = root`: つないだ後のファイル操作を root として行う。`/root` は `dr-xr-x---`（0550）だが、root として扱うので書ける（smbd の SELinux のドメイン `smbd_t` は `dac_override` を持つ）
- `browseable = No`: 共有の一覧（`smbclient -L`）に出さない。つなぐときは共有名 `root` を直接指定する
- `create mask = 0644`: `[homes]` と同じ理由（検証記録（`docs/verification/samba.md` の「補足の実測」））
- root は OS のユーザーなので、`[homes]` も `root` という名前の共有を出そうとする。同じ名前の節があれば、そちらが使われる
- ヒアドキュメントは `${USER}` を展開するので、引用符なしの `<<EOF`。先頭の空行は、手順 3 の `[homes]` との区切り

**[Samba サーバー: root のホームも公開する](#samba-サーバー-root-のホームも公開する)の手順 2**

**[Samba サーバー: root のホームも公開する](#samba-サーバー-root-のホームも公開する)の手順 2: モジュールが要る理由**

- 手順 4 の `samba_enable_home_dirs` が smbd に許すのは、一般ユーザーのホームのラベル（属性 `user_home_type`）だけ。`/root` とその中のファイルは `admin_home_t` で、この属性に入っていない（`seinfo -t admin_home_t -x`）
- そこで、boolean が `user_home_type` の dir / file / lnk_file に許すのと同じ許可を、`admin_home_t` に足す
- `/root/.ssh`（`ssh_home_t`）や `/root/.config`（`config_home_t`）は `user_home_type` なので、手順 4 の boolean で既に許されている
- CIL は `semodule -i` がそのまま読むので、`checkpolicy`（`checkmodule`）などを入れなくてよい。入れたモジュールは優先度 400 に置かれる

**[Samba サーバー: root のホームも公開する](#samba-サーバー-root-のホームも公開する)の手順 4: 同じ資格情報**

- `\\<SERVER_IP>\root` は `\\<SERVER_IP>\<USER>` と同じ資格情報なので、両方を同時に開けるはず（別のユーザー名で同じサーバーにつなぐと、Windows はエラー 1219 で断る）

**[Samba サーバー: /home も公開する](#samba-サーバー-home-も公開する)のリード**

- smbd は、この共有の中を root として読み書きする（`force user = root`）
- 新しく作ったファイルとディレクトリの所有者は、親ディレクトリの所有者（`/home/<ユーザー>` の中なら、そのユーザー）になる（`inherit owner = yes`）。グループは `root` になる
- `/home` の直下には、ファイルもディレクトリも作れない（SELinux が断る）
- 読み書きは、この項の手順 2 の後に、[サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 10・11 で確かめる
- 補足は検証記録（`docs/verification/samba.md` の「/home を公開するときの補足」）
- この項の手順 2 で smb.service を再起動すると、ほかのクライアントの接続が切れる

**[Samba サーバー: サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)のリード**

- **この項の手順 2・8・10 には対話入力がある**（パスワード）

**[Samba サーバー: サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 3: 資格情報ファイル**

- パスワードは `-U user%pass` で渡すと `ps` に見える
- `smbclient -A` の資格情報ファイル（`username=` / `password=`）は `mount.cifs -o credentials=` と同じ形式なので、1 つ作って両方に使う
- `/run/user/<uid>/` は tmpfs でユーザー専用（0700）

**[Samba サーバー: サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 4: 共有の一覧**

検証記録（`docs/verification/samba.md` の「補足の実測」）

**[Samba サーバー: サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 5: マウントと smbstatus**

- `mount.cifs` の既定は SMB 3.1.1（`vers=3.1.1`）。`uid=` / `gid=` を渡さないとマウント側のファイルが root 所有に見える
- `smbstatus` はサーバー側で「交渉されたプロトコル / 暗号化 / 署名」を表示する。クライアント側では見えにくい情報なので、暗号化の有無を確かめるならここ
- `smbstatus` はセッションが生きている間しか見えない

**[Samba サーバー: サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 8**

- `/root` の中身（`.bashrc` や `.ssh` など）の一覧に続いて、`putting file /etc/hostname as \smb-root-test.txt` と `smb-root-test.txt` の 1 行が出ればよい

**[Samba サーバー: サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 10**

- `/home` の中のユーザーのディレクトリ（`<USER>` など）の一覧に続いて、`putting file /etc/hostname as \<USER>\smb-home-test.txt` と `smb-home-test.txt` の 1 行が出ればよい

**[Samba サーバー: サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 11: 作ったファイル**

- `[home]` の `inherit owner = yes` で、作るファイルの所有者は親ディレクトリの所有者になる。ほかのユーザーのホームに作ったものは、そのユーザーの所有になる
- smbd が root として作るファイルのグループは `root`（`inherit owner` はグループを変えない）。持ち主はそのまま読み書きできる
- `-ts recent` は直近 10 分。この節の手順 9 から時間がたったときは `-ts today` にする

**[Samba サーバー: 接続元を絞る](#samba-サーバー-接続元を絞る)のリード**

- 補足: `docs/verification/samba.md` の「接続元を絞るときの補足」
- [Samba サーバー](#samba-サーバー)の手順 5 は、public ゾーンに属するすべての NICで 445/tcp を開く

**[Samba サーバー: 接続元を絞る](#samba-サーバー-接続元を絞る)の手順 1: ブロックの書き方**

- 先頭の `if` は、`ALLOW_FROM` が空のままブロックを貼ったときに、445/tcp の開放だけ消えて rich rule が 1 本も入らないのを防ぐ
- rich rule は**二重引用符**で囲む。単一引用符だと `${src}` が展開されず、firewalld は `$src` という文字列のままの rule を `success` で受理してしまう

**参照**

- 検証記録
- 補足の実測は検証記録（`docs/verification/samba.md` の「補足の実測」）
- [Chapter 1. Using Samba as a server — Configuring and using network file services (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/configuring_and_using_network_file_services/using-samba-as-a-server)
- [Setting up Samba as a Standalone Server — SambaWiki](https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Standalone_Server)
- `man smb.conf`（`[homes]` 節、`server smb transports`、`valid users`、`force user`、`inherit owner`、`map archive`、`smb3 directory leases`、`kernel change notify`）/ `man smbpasswd`（`-s`）/ `man smbclient`（`-A`）/ `man mount.cifs`（`credentials=`、`nohandlecache`、`max_cached_dirs`）/ `modinfo cifs`（`dir_cache_timeout`）
- [Samba 4.22.0 — Release Notes](https://www.samba.org/samba/history/samba-4.22.0.html)（SMB3 Directory Leases が入り、クラスタでなければ既定で有効）
- [A "Mapped network drive" on Windows 10 pointing to a SAMBA share on Fedora 42 does not reflect updates done on Linux — Fedora Discussion](https://discussion.fedoraproject.org/t/a-mapped-network-drive-on-windows-10-pointing-to-a-samba-share-on-fedora-42-does-not-reflect-updates-done-on-linux/162207)（同じ症状の報告。`smb3 directory leases = no` で以前の振る舞いに戻せる、という書き込みで終わっている）
- [Performance tuning for file servers — Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/performance-tuning/role/file-server)（`DirectoryCacheLifetime`）
- [Disable local SMB directory enumeration caching — Apple Support](https://support.apple.com/en-us/101918)

</details>

---

## Windows 11 で使う

- Samba のクライアント

### Windows 11 で Samba クライアントを使う

- Samba の共有をドライブ文字に割り当て、サインインのたびにつなぎ直す
- 前提: サーバーで [Samba サーバー](#samba-サーバー)を通し、サーバーにつながる LAN に接続してある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。手順 7 はサーバーの bash、手順 8 はこの PC のデスクトップ
- Samba サーバーの `[root]`・`[home]` も割り当てるなら、この項を通した後に、この項の手順 2 の 3 つ目のブロックの `SHARE` と `DRIVE` を書き換えて貼り、この項の手順 3・5・6 を貼り直す（資格情報は同じなので、手順 4 は要らない）

> [!IMPORTANT]
> **管理者の窓で割り当てたドライブは、エクスプローラーに出ない**。管理者ではない窓で行う。

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[アプリを入れる](windows-setup.md#アプリを入れる)の手順 6〜9 を通す
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
   # 変数・権限・接続先・ドライブ文字を検査する
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
     # 保存済みの資格情報を照会する
     cmdkey "/list:$SERVER"
   }
   ```

   - `<SERVER> の 445/tcp に届く。<DRIVE> は空いている` と、`<SERVER>` の資格情報の一覧が出ればよい
   - `445/tcp に届かない` ときは、`SERVER` の値と、サーバーの firewalld と smbd（[Samba サーバー](#samba-サーバー)の手順 5・7）を確かめる
   - `もう使われている` ときは、`DRIVE` を別の文字にして、この項の手順 2 の 3 つ目のブロックを貼り直す。前にこの項で同じ共有を割り当てたなら、この項は済んでいる

1. 資格情報マネージャーに、共有のユーザー名とパスワードを登録する。

   ```powershell
   # 資格情報の登録に使う値を検査する
   if (-not $SERVER -or -not $SMB_USER) {
     Write-Error '中断: この項の手順 2 の SERVER か SMB_USER が空のまま。値を入れて貼り直す'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     cmdkey "/add:$SERVER" "/user:$SMB_USER" /pass
   }
   ```

   - パスワードを聞かれる。AlmaLinux の「Samba サーバー」の設定なら、[Samba サーバー](#samba-サーバー)の手順 6 で `smbpasswd -a` に入れたパスワード
   - 資格情報を追加した旨の 1 行が出ればよい
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼ると、資格情報の登録に失敗しても永続的なドライブの割り当てが動く）

1. 共有をドライブ文字に割り当て、サインインのたびにつなぎ直すようにする。

   ```powershell
   # ドライブの割り当てに使う値を検査する
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
   - エラー 1219 が出たら、[Windows 11 で Samba クライアントを使う の補足と注意点](#windows-11-で-samba-クライアントを使う-の補足と注意点)の「注意点」の Windows 11 のエラー 1219 を見る

1. 割り当てたドライブで読み書きできることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $DRIVE) {
     Write-Error '中断: この項の手順 2 の DRIVE が空のまま。値を入れて貼り直す'
   } else {
     # 共有内のファイル名を一覧にする
     Get-ChildItem -LiteralPath "$DRIVE\" | Select-Object -First 5 -ExpandProperty Name
     # テストファイルを書き、読み戻す
     Set-Content -LiteralPath "$DRIVE\smb-win-test.txt" -Value 'smb write' -Encoding ascii
     Get-Content -LiteralPath "$DRIVE\smb-win-test.txt"
     # テストファイルを消し、残っていないか確かめる
     Remove-Item -LiteralPath "$DRIVE\smb-win-test.txt"
     Test-Path -LiteralPath "$DRIVE\smb-win-test.txt"
   }
   ```

   - 共有の一覧、`smb write`、`False` が出ればよい
   - `SHARE=home`（Samba サーバーの `[home]`）では、書き込みが拒否される。名前の一覧が出ていればよい

1. サーバーで、署名付きの SMB3_11 でつながっていることを確かめる。

   ```bash
   sudo smbstatus
   ```

   - この PC の接続が `SMB3_11` で、`Signing` が方式名だけ（`partial(…)` や `-` ではない）ならよい
   - Windows 11 Home の PC では、`Signing` が `partial(…)` か `-` になりうる（[Windows 11 で Samba クライアントを使う の補足と注意点](#windows-11-で-samba-クライアントを使う-の補足と注意点)の「注意点」）
   - この PC の行が無ければ、エクスプローラーかこの PC の PowerShell で `<DRIVE>` を開いてから、貼り直す

1. サインアウトしてサインインし直し、ドライブがパスワード無しで開くことを確かめる。

   - スタートメニューの自分のアイコンから「サインアウト」を選び、もう一度サインインする
   - エクスプローラーの「PC」の「ネットワークの場所」に、`<SHARE> (\\<SERVER>) (<DRIVE>)` のような名前でドライブが出ればよい
   - 開いたときにパスワードを聞かれなければよい
   - 赤い × が付いているときは、サインインのときにサーバーに届かなかった（[Windows 11 で Samba クライアントを使う の補足と注意点](#windows-11-で-samba-クライアントを使う-の補足と注意点)の「注意点」）

#### Samba クライアント: Windows 11 の更新

- Samba サーバーで変えたパスワードを、Windows の資格情報マネージャーにも入れ直す
- 前提: [Samba クライアント](#windows-11-で-samba-クライアントを使う)を通し、サーバーで Samba のパスワードを変えてある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。手順 4 はこの PC のデスクトップ

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[アプリを入れる](windows-setup.md#アプリを入れる)の手順 6〜9 を通す

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
   # 資格情報の登録に使う値を検査する
   if (-not $SERVER -or -not $SMB_USER) {
     Write-Error '中断: この項の手順 2 の SERVER か SMB_USER が空のまま。値を入れて貼り直す'
   } else {
     # 新しいパスワードを資格情報に登録する
     cmdkey "/add:$SERVER" "/user:$SMB_USER" /pass
   }
   ```

   - サーバーで変えた後の新しいパスワードを入れる
   - パスワードを入力し終えてから、この項の手順 4 を行う

1. サインアウトしてサインインし直し、ドライブがパスワード無しで開くことを確かめる。

   - [Windows 11 で Samba クライアントを使う](#windows-11-で-samba-クライアントを使う)の手順 8 と同じ

<details id="windows-11-で-samba-クライアントを使う-の補足と注意点">
  <summary>Windows 11 で Samba クライアントを使う の補足と注意点</summary>

**注意点**

- **Windows 11 Home の PC からの接続は、全体には署名されない**
  - 24H2 の Pro・Enterprise・Education は SMB の署名を必ず求めるが、Home は求めない
  - samba.md のサーバーも署名を求めない（`server signing` の既定）ので、Home からはどちらも求めない接続になる
- **クライアントの署名とゲストの設定は変えない**: Pro の既定（署名が必須・ゲストの接続は禁止）のままつながる
  - samba.md のサーバーはユーザーとパスワードで認証し（ゲストにしない）、SMB3 の署名にも応じるため
  - `Set-SmbClientConfiguration` の `RequireSecuritySignature` と `EnableInsecureGuestLogons` は変えない
- **エラー 1219**: 同じサーバーに別のユーザー名でつないでいると、割り当てが断られる（エクスプローラーで別の資格情報で開いた接続など）
  - その接続を閉じるか、サインアウトしてサインインし直してから、[Windows 11 で Samba クライアントを使う](#windows-11-で-samba-クライアントを使う)の手順 5 を貼り直す
  - samba.md の `[root]`・`[home]` は同じユーザーでつなぐので、`[homes]` と並べて割り当てられる
- **サインインのときにサーバーに届かないと、ドライブに赤い × が付く**: すべてのネットワーク ドライブを再接続できなかった旨の通知も出る。サーバーに届くようになってから、エクスプローラーでドライブを開き直す
- **管理者の窓からは、割り当てたドライブが見えない**: 管理者の PowerShell・Windows Terminal の管理者のタブ・`sudo` では、ドライブ文字ではなく `\\<SERVER>\<SHARE>` を使う
- **SMB の NTLM のブロックを入れると、割り当てられなくなる**
  - 24H2 から選べる設定（`Set-SmbClientConfiguration -BlockNTLM $true` か、グループ ポリシーの「Block NTLM (LM, NTLM, NTLMv2)」）で、既定では入っていない
  - samba.md のサーバーは Kerberos を使わず、NTLMv2 で認証するため
  - 入れるなら、グループ ポリシーの「Block NTLM Server Exception List」に `<SERVER>` を足す（この折りたたみの「選択した方針」）
- **パスワードを変えたら**: サーバーで変え、[Windows 11 の更新](#samba-クライアント-windows-11-の更新)を行う
- LAN 上の通信は暗号化されない。Windows 11 Home からの接続は全体には署名されない

**[Windows 11 で Samba クライアントを使う](#windows-11-で-samba-クライアントを使う)のリード**

- パスワードは Windows の資格情報マネージャーに置く

**[Windows 11 で Samba クライアントを使う](#windows-11-で-samba-クライアントを使う)の手順 1: 管理者ではない窓で割り当てる理由**

- UAC が有効な Windows では、Administrators の一員がサインインすると、昇格したものとしないものの 2 つのログオン セッションができる。ドライブの割り当ては、作った側のセッションにだけある（Microsoft の文書）
- エクスプローラーは昇格しない側で動くので、管理者の窓（`sudo` を含む）で割り当てたドライブは、エクスプローラーにも、管理者ではない窓にも出ない
- 管理者の窓からも見えるようにするレジストリの値（`EnableLinkedConnections`）は、PC 全体の設定を足すことになるので採らない。管理者の窓では UNC パスを使う（この折りたたみの「注意点」）

**[Windows 11 で Samba クライアントを使う](#windows-11-で-samba-クライアントを使う)の手順 2: 変数について**

- `SMB_USER` は、AlmaLinux 10 の節と違って必須にした。Windows のユーザー名（Microsoft アカウントなら `C:\Users\` の下のフォルダーの名前）は、サーバーの OS のユーザー名と違うことが多いため
- `SHARE` の既定が `SMB_USER` なのは、samba.md の `[homes]` が Samba ユーザーと同じ名前の共有を見せるため（[Samba クライアント の補足と注意点](#samba-クライアント-の補足と注意点)の「Samba クライアントの手順 1: 変数について」と同じ）
- `SERVER` に NetBIOS 名は使えない（samba.md のサーバーは nmbd を動かさない）。IP アドレスか、DNS で引ける名前にする
- `SERVER` をエクスプローラーで `\\<SERVER>\…` を開くときと同じ書き方にするのは、資格情報をこの名前に結び付けて置くため
- 変数はその PowerShell の中だけで有効

**[Windows 11 で Samba クライアントを使う](#windows-11-で-samba-クライアントを使う)の手順 3**

- 一覧にある `<SERVER>` の保存済み資格情報は、この項の手順 4 で置き換わる

**[Windows 11 で Samba クライアントを使う](#windows-11-で-samba-クライアントを使う)の手順 4: 資格情報マネージャーに置く**

- `cmdkey /add:<SERVER> /user:<SMB_USER> /pass` は、`<SERVER>` を宛先にした Windows の資格情報（資格情報マネージャーの「Windows 資格情報」）を作る。`/pass` に値を書かなければ、`cmdkey` がパスワードを聞く（Microsoft の文書）
- パスワードをコマンドラインに書かないのは、ほかのプロセスから見え、PowerShell の履歴にも残るため（[Samba サーバー: サーバーの上で動作を確かめる](#samba-サーバー-サーバーの上で動作を確かめる)の手順 3 と同じ考え）
- この節の手順 5 の `New-SmbMapping` に資格情報を渡さないと、Windows はこの資格情報でつなぐ（Microsoft の Azure Files の文書も、`cmdkey /add` の後に資格情報を渡さずに割り当てている）
- 資格情報はこのユーザーのものなので、ほかのユーザーには使われない。サインインし直しても残る

**[Windows 11 で Samba クライアントを使う](#windows-11-で-samba-クライアントを使う)の手順 5**

- エクスプローラーには、この項の手順 8 でサインインし直すまで出ないことがある

**[Windows 11 で Samba クライアントを使う](#windows-11-で-samba-クライアントを使う)の手順 5: New-SmbMapping と、エクスプローラーの表示**

- `-Persistent $true` で、割り当てをこのユーザーのプロファイルに覚えさせ、サインインのたびにつなぎ直させる
- 成功は、`Get-SmbMapping` の `Status` が `OK` で判断する。Microsoft のコミュニティには、Windows 11 で `New-SmbMapping` のドライブがエクスプローラーを起動し直す（かサインインし直す）まで出ないという報告があるので、エクスプローラーでの確かめはこの節の手順 8 のサインインし直した後にした
- 前に割り当てて、切れたまま覚えているドライブ文字（`Status` が `Unavailable` など）には割り当てられない（`ERROR_DEVICE_ALREADY_REMEMBERED`）。この節の手順 3 は、そのドライブ文字も `Get-SmbMapping` で見つけて止める

**[Windows 11 で Samba クライアントを使う](#windows-11-で-samba-クライアントを使う)の手順 6**

- 共有の中の名前（5 つまで。隠しファイルは出ない）、`smb write`、`False` の順に出ればよい

**[Windows 11 で Samba クライアントを使う](#windows-11-で-samba-クライアントを使う)の手順 6: [home] の書き込み**

- `SHARE=home` で書き込みが拒否されるのは、共有の直下が `/home` で、サーバーの SELinux が作るのを断るため（[Samba クライアント](#samba-クライアント)の手順 4 と同じ）

**[Windows 11 で Samba クライアントを使う](#windows-11-で-samba-クライアントを使う)の手順 7**

- サーバーのシェルに貼る
- この PC の IP アドレスの行の `Protocol Version` が `SMB3_11` で、`Signing` が `AES-128-GMAC` などの方式の名前だけ（`partial(…)` でも `-` でもない）ならよい
- `Encryption` は `-`（LAN の上の通信は暗号化されない。[Samba サーバー の補足と注意点](#samba-サーバー-の補足と注意点)の「注意点」）

**[Windows 11 で Samba クライアントを使う](#windows-11-で-samba-クライアントを使う)の手順 7: 署名と、サーバーの設定を変えない理由**

- Windows 11 24H2 の Pro・Enterprise・Education は、SMB の署名を、送る側（クライアント）と受ける側（サーバー）の両方で必ず求める。Home は、どちらも求めない（Microsoft の文書）
- samba.md のサーバーは `server signing` を書いておらず、既定の `default` のまま。SMB2 以降では署名を止められず、クライアントが求めれば署名する（smb.conf(5)）。そのため Pro の PC からの接続は署名され、サーバーもクライアントも設定を変えずにつながる
- `smbstatus` の `Signing` の欄は、全体に署名した接続なら方式の名前（`AES-128-GMAC` など）だけ、一部だけなら `partial(<方式>)`、無ければ `-`（Samba 4.23.5 のソース）。署名を求めない AlmaLinux 10 の cifs の接続は `partial(AES-128-CMAC)` だった
- Pro は、ゲスト（認証しない接続）も既定で断る。samba.md のサーバーはユーザーとパスワードで認証し、`map to guest` は既定の `Never`（ゲストにしない）なので、当たらない
- `smbstatus` にこの PC の行が無いことがあるのは、使っていない接続が閉じられることがあるため

**[Samba クライアント: Windows 11 の更新](#samba-クライアント-windows-11-の更新)のリード**

- SMB のクライアントは Windows Update で上がる。この項で上げるものは無い

**[Samba クライアント: Windows 11 の更新](#samba-クライアント-windows-11-の更新)の手順 3: 置き換わる資格情報**

- 登録し直すと、同じ `<SERVER>` の資格情報が置き換わる

**選択した方針**

- **Windows 11 では、資格情報マネージャー（`cmdkey`）と `New-SmbMapping -Persistent $true` で、ドライブ文字に割り当てる**
  - パスワードは、`cmdkey` が聞いて資格情報マネージャーに置く。コマンドラインにも、PowerShell の履歴にも残らない
  - 窓は管理者ではない PowerShell 7（この折りたたみの「Windows 11 で Samba クライアントを使うの手順 1: 管理者ではない窓で割り当てる理由」）。貼る窓は、ほかの Windows の手順書と同じ PowerShell 7 にする
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

**参照**

- 検証記録（`docs/verification/samba-client.md`）
- 補足の実測は検証記録（`docs/verification/samba-client.md` の「補足の実測」）
- [Control SMB signing behavior — Windows Server (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/storage/file-server/smb-signing)（24H2 の版ごとの署名の要求、ゲストの禁止）
- [Block NTLM connections on SMB — Windows Server (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/storage/file-server/smb-ntlm-blocking)
- [cmdkey (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/cmdkey) / [New-SmbMapping](https://learn.microsoft.com/en-us/powershell/module/smbshare/new-smbmapping?view=windowsserver2025-ps) / [Remove-SmbMapping](https://learn.microsoft.com/en-us/powershell/module/smbshare/remove-smbmapping?view=windowsserver2025-ps)
- [Mapped drives aren't available from an elevated command prompt (Microsoft Learn)](https://learn.microsoft.com/en-us/troubleshoot/windows-client/networking/mapped-drives-not-available-from-elevated-command) / [Mapped network drive may fail to reconnect (Microsoft Learn)](https://learn.microsoft.com/en-us/troubleshoot/windows-client/networking/mapped-network-drive-fail-reconnect)
- [Mount SMB Azure file share on Windows (Microsoft Learn)](https://learn.microsoft.com/en-us/azure/storage/files/storage-how-to-use-files-windows)（`cmdkey /add` の後に資格情報を渡さずに割り当てる例）
- `man smb.conf`（`server signing`、`map to guest`、`ntlm auth`）/ Samba 4.23.5 の `source3/utils/status.c`（`smbstatus` の `Signing` の表示）

</details>

---
