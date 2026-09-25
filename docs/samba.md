# Samba でホームディレクトリを公開する手順（`[homes]` 共有 / smbd + firewalld）

## 実施手順

> [!IMPORTANT]
> - **すべてサーバー上で実行する**。手順 8 の最後の「クライアントからの接続」だけ別マシン
> - **手順 6 と手順 8 には対話入力がある**。そのブロックだけ続けて貼らない

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 接続元を絞る場合は、最後に[接続元を絞る（任意）](#接続元を絞る任意)を行う。戻すときは[ロールバック](#ロールバック)

1. **変数を設定する**

   **`sudo -i` した root のシェルではなく、公開するユーザー自身のシェルで貼る。**

   ```bash
   WORKGROUP=WORKGROUP                 # Windows 側のワークグループ名。既定のままでよいことが多い
   SMB_USER=${USER}                    # 公開するホームディレクトリの持ち主（自動）。<USER>
   SERVER_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p')   # 検証と案内に使う（自動）。<SERVER_IP>
   ```

   値を読み戻して確かめる。

   ```bash
   for v in WORKGROUP SMB_USER SERVER_IP; do
     printf '%-10s = %s\n' "$v" "${!v}"
   done
   ```

   - `SMB_USER` が `root` になっている（root のホームを公開してしまう）、`SERVER_IP` が空、または意図した NIC の IP でないなら、ここで止めて直す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**（SSH を張り直したあとも）、上の 2 つのブロックを貼り直してから先へ進む

   <details>
   <summary>補足: 変数について</summary>

   - `SERVER_IP` を自動取得にしているのは、設定には使わず検証と案内にしか使わないため（GNOME Remote Desktop の手順書で手入力なのは、値が証明書の SAN に入るから）
   - `SERVER_IP` が間違っていても、手順 8 の `smbclient "//${SERVER_IP}/..."` が失敗するだけで、設定は壊れない
   - `SMB_USER` は `$USER` から入るので、`sudo -i` した root のシェルで貼ると `root` になる。手順 6 で root のホームを公開してしまうので、読み戻しで必ず確認する
   - `ALLOW_FROM` は[接続元を絞る](#接続元を絞る任意)でしか使わないので、手順 1 ではなくその節の冒頭で設定する

   </details>

1. **パッケージのインストール**

   ```bash
   sudo dnf install -y samba samba-client cifs-utils
   rpm -q samba samba-client cifs-utils
   ```

   <details>
   <summary>補足: パッケージ</summary>

   - `samba`（baseos）が smbd 本体。依存で `samba-common-tools`（`smbpasswd` / `pdbedit` / `testparm` / `smbstatus`）、`samba-libs`、`samba-dcerpc` などが入る
   - `samba-client`（`smbclient`）と `cifs-utils`（`mount.cifs`）は手順 8 の検証にしか使わない。サーバー上で検証しないなら入れなくてよい
   - インストール直後は `smb.service` / `nmb.service` とも `disabled` / `inactive`

   </details>

1. **smb.conf を書く**

   既定の `/etc/samba/smb.conf` を退避して、最小構成で置き換える:

   ```bash
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
   ```

   構文を検査する:

   ```bash
   testparm -s
   ```

   - `Loaded services file OK.` と `Server role: ROLE_STANDALONE` が出ればよい

   <details>
   <summary>補足: smb.conf</summary>

   - `cp -an` の `-n` で、2 回目以降の実行で `.orig` を上書きしない（最小構成で上書きした `smb.conf` を原本として退避してしまうのを防ぐ）
   - heredoc は `${WORKGROUP}` を展開するため引用符なしの `<<EOF`。内容にほかの `$` は無い
   - `testparm -s` の出力に `Weak crypto is allowed by GnuTLS (e.g. NTLM as a compatibility fallback)` が出るが、crypto-policies が DEFAULT のときの通常の表示で、エラーではない
   - `testparm -s` は**既定と異なる値だけ**を表示する。`workgroup = WORKGROUP` や `read only = No` に対応する行が出なくても書き漏れではない。全パラメータを見るなら `testparm -sv`
   - 手順 8 の後で `smb.conf` を直したときは `sudo systemctl restart smb.service`（unit には `ExecReload`（`SIGHUP`）もあるが、本手順の検証では restart しか使っていない）

   </details>

1. **SELinux**

   ```bash
   sudo setsebool -P samba_enable_home_dirs on
   sudo getsebool samba_enable_home_dirs        # samba_enable_home_dirs --> on
   ```

   <details>
   <summary>補足: SELinux</summary>

   - boolean が off のままだと、認証は通り共有一覧にも出るのに、`ls` で `NT_STATUS_ACCESS_DENIED listing \*` になる
   - **このとき `ausearch -m AVC` には何も出ない**（dontaudit されている）ので、監査ログから原因にたどり着けない。[付録](#selinux-boolean-が-off-のときの失敗の署名)
   - `setsebool -P` は即時反映で、smbd の再起動は不要（実測: 起動中の smbd に対して on にした直後の `ls` が通った）

   </details>

1. **firewalld**

   ```bash
   sudo firewall-cmd --permanent --add-port=445/tcp && sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports               # 445/tcp が含まれる
   ```

   <details>
   <summary>補足: firewalld</summary>

   - 445/tcp は public ゾーンの全 NIC で開く。この環境では `end0`（LAN）と `wg0`（VPN）
   - 自ホストからの `smbclient //localhost/...` や `//${SERVER_IP}/...` は `lo` を通るため、**firewalld の設定を通らない**（`filter_INPUT` の `iifname "lo" accept` で先に受理される）
   - 開け忘れはサーバー上の検証では見つからない。[付録](#network-namespace-から-firewalld-越しに到達する)

   </details>

1. **Samba ユーザーの登録**

   OS のアカウントが存在することを確かめる:

   ```bash
   id "${SMB_USER}"
   ```

   **端末で対話入力する**（新しいパスワードを 2 回聞かれる。OS のパスワードとは別に保存される）:

   ```bash
   sudo smbpasswd -a "${SMB_USER}"
   ```

   **次のブロックは、2 回の入力を終えてから貼る**（続けて貼るとパスワードとして食われる）。

   ```bash
   sudo pdbedit -L                              # <USER>:1000: の 1 行が出る
   ```

   <details>
   <summary>補足: Samba ユーザー</summary>

   - Samba のパスワードは OS のパスワードとは別で、`/var/lib/samba/private/passdb.tdb` に保存される。OS のアカウントは存在が必須（`id` で確認）
   - `smbpasswd -a` は既定で `/dev/tty` から読む。**TTY が無いと `Unable to get new password.` で終了コード 1**（`grdctl set-credentials` のように exit 0 で黙って何もしない、ということはない）
   - パイプで渡すなら `-s`（stdin から新パスワード・確認の 2 行を読む）。[付録](#smbpasswd-を-tty-無しで実行したとき)
   - `-a` で作った直後から有効（`pdbedit -Lv` の `Account Flags: [U ]`）。`smbpasswd -e` は要らない
   - **smbd の再起動は不要**。起動中に `smbpasswd -x` → `-a` し直すと、その次の接続から効く（実測）。パスワード変更も同様

   </details>

1. **サービスの有効化**

   ```bash
   sudo systemctl enable --now smb.service
   systemctl is-active smb.service              # active
   ss -ltnp | grep -E ':(139|445) '             # 445 だけが LISTEN。139 は出ない
   ```

   <details>
   <summary>補足: サービス</summary>

   - `smb.service` は `nmb.service` を `Requires` / `Wants` していない（`After=` に並ぶだけ）。nmb を起動しなくても単独で動く
   - 起動すると `/var/log/samba/` に `log.smbd` と `log.rpcd_*`（`samba-dcerpcd` が起動する RPC ヘルパーのログ）ができる。`cups` 無しでも、本手順の `smb.conf` なら CUPS 関連のエラーは出ない

   </details>

1. **検証**

   **資格情報ファイルを作る。** 手順 6 で登録したパスワードを入力する:

   ```bash
   AUTHFILE=/run/user/$(id -u)/smb-auth
   read -rsp "Samba password for ${SMB_USER}: " PW; echo
   ```

   **次のブロックは、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）。

   ```bash
   ( umask 077; printf 'username=%s\npassword=%s\n' "${SMB_USER}" "${PW}" > "${AUTHFILE}" ); unset PW
   ls -l "${AUTHFILE}"                          # -rw------- で自分の所有
   ```

   - このファイルを、`smbclient` と `mount.cifs` の両方で使う
   - パスワードをコマンドラインに書かないのは、`ps` に見えるため

   **共有の一覧と読み書き**（`smbclient`）:

   ```bash
   smbclient -L //localhost -A "${AUTHFILE}"    # IPC$ と <USER> の 2 つだけ出る
   smbclient "//localhost/${SMB_USER}" -A "${AUTHFILE}" -c 'ls'
   smbclient "//localhost/${SMB_USER}" -A "${AUTHFILE}" -c "put /etc/hostname smb-test.txt; get smb-test.txt /tmp/smb-test.txt; ls smb-test.txt"
   ls -lZ ~/smb-test.txt /tmp/smb-test.txt      # -rw-r--r-- / user_home_t
   cmp /etc/hostname /tmp/smb-test.txt && echo "content identical"
   smbclient "//${SERVER_IP}/${SMB_USER}" -A "${AUTHFILE}" -c 'ls smb-test.txt'
   ```

   **マウントして書き込む**（`mount.cifs`）:

   ```bash
   sudo mkdir -p /mnt/smbtest
   sudo mount -t cifs "//127.0.0.1/${SMB_USER}" /mnt/smbtest -o "credentials=${AUTHFILE},uid=$(id -u),gid=$(id -g)"
   mount | grep cifs                            # vers=3.1.1
   echo "cifs write" > /mnt/smbtest/cifs-test.txt && cat /mnt/smbtest/cifs-test.txt
   ls -lZ /mnt/smbtest/cifs-test.txt ~/cifs-test.txt
   sudo smbstatus                               # Protocol Version: SMB3_11、Signing: partial(AES-128-CMAC)
   ```

   `smbstatus` はセッションが生きている間しか見えないので、出力を確かめてからアンマウントする:

   ```bash
   sudo umount /mnt/smbtest && sudo rmdir /mnt/smbtest
   ```

   **後片付け**:

   ```bash
   rm -f ~/smb-test.txt ~/cifs-test.txt /tmp/smb-test.txt "${AUTHFILE}"
   sudo ausearch -m AVC -ts today               # <no matches>
   ```

   **クライアントからの接続**（別マシン。**未検証**。値に読み替える）:

   - Windows: エクスプローラーのアドレス欄に `\\<SERVER_IP>\<USER>`。資格情報は `<USER>` と手順 6 のパスワード
   - macOS: Finder の「サーバへ接続」に `smb://<SERVER_IP>/<USER>`
   - Android / iOS: ファイルアプリの SMB 接続先に `<SERVER_IP>`、共有名 `<USER>`
   - Linux: `smbclient "//<SERVER_IP>/<USER>" -U <USER>` または `mount -t cifs "//<SERVER_IP>/<USER>" <mountpoint> -o username=<USER>`

   WireGuard 越しに接続するときは `<SERVER_IP>` を `<WG_IP>` に読み替える（クライアント側の `AllowedIPs` にトンネル網が入っていることが前提。[WireGuard の手順書](wireguard.md)）。

   <details>
   <summary>補足: 検証</summary>

   - パスワードは `-U user%pass` で渡すと `ps` に見える
   - `smbclient -A` の資格情報ファイル（`username=` / `password=`）は `mount.cifs -o credentials=` と同じ形式なので、1 つ作って両方に使う
   - `/run/user/<uid>/` は tmpfs でユーザー専用（0700）
   - `smbclient -L` に出るのは `IPC$` と `<USER>` の 2 つ。`homes` / `printers` / `print$` は出ない
   - `mount.cifs` の既定は SMB 3.1.1（`vers=3.1.1`）。`uid=` / `gid=` を渡さないとマウント側のファイルが root 所有に見える
   - マウント側の `ls -Z` は `cifs_t`、サーバー側は `user_home_t`（`user_home_dir_t` 配下の type transition。`restorecon` していないのにこうなる）
   - `smbstatus` はサーバー側で「交渉されたプロトコル / 暗号化 / 署名」を表示する。クライアント側では見えにくい情報なので、暗号化の有無を確かめるならここ
   - クライアントからの接続は未検証。IP アドレスで指定する（NetBIOS 名では見つからない）

   </details>

---

## 接続元を絞る（任意）

**接続元を制限しないなら、この節は不要。**

手順 5 は、public ゾーンに属するすべての NIC（この環境では `end0` と `wg0`）で 445/tcp を開く。絞るなら、まず送信元サブネットを空白区切りで入れる:

```bash
ALLOW_FROM="192.168.1.0/24 10.99.0.0/30"     # ← 自分の値に書き換える。<ALLOW_FROM>
```

続けて、445/tcp の開放を rich rule に置き換える:

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

元の「public ゾーン全体で 445/tcp」に戻すには、絞ったときと同じ `ALLOW_FROM` を入れてから:

```bash
if [ -z "${ALLOW_FROM}" ]; then echo '中断: ALLOW_FROM が空のまま。絞ったときと同じ値を入れて貼り直す' >&2; else
for src in ${ALLOW_FROM}; do
  sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=${src} port port=445 protocol=tcp accept"
done
sudo firewall-cmd --permanent --add-port=445/tcp && sudo firewall-cmd --reload
fi
```

→ [補足](#接続元を絞るときの補足)

---

## ロールバック

上から順に実行する。

```bash
sudo umount /mnt/smbtest 2>/dev/null; sudo rmdir /mnt/smbtest 2>/dev/null   # 検証のマウントが残っていれば
sudo systemctl disable --now smb.service
sudo firewall-cmd --permanent --remove-port=445/tcp && sudo firewall-cmd --reload
sudo smbpasswd -x "${SMB_USER:?手順 1 の SMB_USER を設定してから貼る}"
sudo setsebool -P samba_enable_home_dirs off
sudo cp -a /etc/samba/smb.conf.orig /etc/samba/smb.conf
```

- 後日このブロックだけ貼るときは、先に手順 1 の変数ブロックを貼る（`SMB_USER` が空だと `${SMB_USER:?…}` で止まる）
- 並びは、`smbpasswd`（`samba-common-tools`）が消える前に Samba ユーザーを消すため
- 接続元を絞る節を使った場合は 445/tcp ではなく rich rule が入っているので、先に[元に戻す](#接続元を絞る任意)ブロックを貼る

パッケージも消すなら（`samba-common` は実施前から入っていたので残す）:

```bash
sudo dnf remove -y samba samba-client cifs-utils
```

- `dnf remove` 後も、`/var/lib/samba/private/passdb.tdb`（Samba のパスワード DB）と `/var/log/samba/` は残る

> [!CAUTION]
> `passdb.tdb` は Samba のパスワード DB（`smbpasswd` で登録したパスワードの保存先。手順 6 の補足）。消すと、中の登録は取り戻せない。

完全に消すなら `sudo rm -rf /var/lib/samba/private/passdb.tdb /var/log/samba`。

---

## 補足

### 対象と検証環境

- **目的**: ローカルユーザーが**自分のホームディレクトリ**に、LAN と WireGuard 越し（`wg0`）の両方から SMB3 で読み書きできるようにする
  - 共有は Samba の `[homes]` 機構（ユーザー名と同じ名前の共有が自動で現れ、本人しか入れない）だけを使う
  - 印刷・NetBIOS・ゲストアクセスは持たない
- **進め方**: **冒頭の変数ブロックに値を 1 度書き、以降のコマンドをそのまま貼る**
  - 読者が編集するのは `WORKGROUP` と、接続元を絞る場合の `ALLOW_FROM` だけ
  - `smb.conf` は既定ファイルを退避したうえで、最小構成に置き換える
- **状態**: **2026-09-21 に下表の実機で本実行し、そのまま公開を継続中**
  - 確認したこと: **サーバー自身からの `smbclient` と `mount.cifs` による読み書き**、および **network namespace から firewalld 越しに 445/tcp へ到達できること**（[付録](#付録-実機での検証記録2026-09-21)）
  - **確認していないこと**: Windows / macOS / Android の実クライアントからの接続

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
> | `${SMB_USER}` | 公開するホームディレクトリの持ち主。OS のアカウント名（`$USER` から自動で入る） | `<USER>` |
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
- **Samba のパスワードは OS と別**: OS のパスワードを変えても Samba 側は変わらない。変えるときは `sudo smbpasswd "${SMB_USER}"`
- **ユーザー名は OS アカウントと一致が必須**
  - 存在しないユーザー、間違ったパスワードは、どちらも `NT_STATUS_LOGON_FAILURE`
  - 他人のホーム（`//<SERVER_IP>/root` など）は、認証が通っても `tree connect failed: NT_STATUS_ACCESS_DENIED`
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
