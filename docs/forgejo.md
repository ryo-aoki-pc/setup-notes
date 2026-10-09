# Forgejo 構築手順（AlmaLinux 10 / rootless Podman + Quadlet / LAN・VPN 内で使う）

## 実施手順

> [!IMPORTANT]
> - **サーバーを動かす一般ユーザー自身の bash（デスクトップの端末か SSH）で実行する**。`sudo -i` や `sudo -iu` で切り替えたシェルは使わない
> - 先に [AlmaLinux 10 の初期設定の手順 3](almalinux-setup.md#実施手順)（NOPASSWD の sudo）、[Podman](podman.md)・[linger](linger.md) を通す。常時動かす PC は、初期設定の[画面オフ・画面ロック・自動サスペンドを止める任意節](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)も通す
> - 別の PC からホストの SSH にログインでき、サーバーの IPv4 が固定されていることを前提にする。firewalld と SELinux は有効なまま使う
> - 手順 6・7・11・12・14〜16・18〜20 は別の PC やブラウザで行う。Git の確認に使う PC は、先に [Git](git.md) を通す
> - 手順 21 でサーバーを再起動する。ログインし直した後は、手順 1 の変数だけを貼り直す

- 上から順にコードブロックを貼る
- [検証記録](verification/forgejo.md)・[参考資料](reference/forgejo.md)
- 手順の後: [設定ファイル](#設定ファイル)・[バックアップ](#バックアップ)・[バックアップから復元する](#バックアップから復元する)・[更新](#更新)・[ロールバック](#ロールバック)
- Web は HTTP、Git は SSH で使う。HTTP の内容は暗号化されない。VPN 経由で開く場合は VPN の区間が暗号化される
- 初期設定用の SSH トンネルは、LAN の待ち受けへ切り替えた後には使えない。インターネット向けのポート転送は設定しない

1. 変数を設定する（`SERVER_IP` と `LAN_SUBNET` は必ず値を入れる）。

   ```bash
   SERVER_IP=''                       # サーバーの待ち受け IPv4（例: 192.168.1.10）
   ```

   ```bash
   LAN_SUBNET=''                      # 許可する送信元 IPv4 の CIDR（例: 192.168.1.0/24）
   ```

   ```bash
   {
     FORGEJO_HTTP_PORT=3000            # ホスト側の Web ポート（1024〜65535）
     FORGEJO_SSH_PORT=2222             # ホスト側の Git 用 SSH ポート（1024〜65535）
     FW_ZONE=$(sudo firewall-cmd --get-default-zone)
     printf '待ち受け: %s\n許可する送信元: %s\nWeb: %s / SSH: %s\nfirewalld: %s\n' \
       "${SERVER_IP}" "${LAN_SUBNET}" "${FORGEJO_HTTP_PORT}" "${FORGEJO_SSH_PORT}" "${FW_ZONE}"
   }
   ```

   - `SERVER_IP` は、Forgejo の Web・Git の接続先にも使う。ホストの SSH のポート 22 は変えない
   - `LAN_SUBNET` は、サーバーから見えるクライアントの送信元に合わせる。VPN の相手だけに許可するときは、その VPN の CIDR にする
   - `FW_ZONE` は自動で入る。待ち受ける NIC が別の zone に属しているなら、任意変数のブロックの `FW_ZONE=` をその名前に変える
   - ポートを変えたら、別の PC で打つ手順 6・14・16 の番号も同じにする
   - 空のままなら先へ進まない

1. 値と前提を確かめ、公式の rootless イメージを取得する。

   ```bash
   if [ -z "${SERVER_IP}" ] || [ -z "${LAN_SUBNET}" ] || [ -z "${FORGEJO_HTTP_PORT}" ] || [ -z "${FORGEJO_SSH_PORT}" ] || [ -z "${FW_ZONE}" ]; then
     echo '中断: 手順 1 の変数を設定する' >&2
   elif /usr/bin/python3 - "${SERVER_IP}" "${LAN_SUBNET}" "${FORGEJO_HTTP_PORT}" "${FORGEJO_SSH_PORT}" <<'PY'
   import ipaddress
   import json
   import subprocess
   import sys

   address = ipaddress.IPv4Address(sys.argv[1])
   network = ipaddress.IPv4Network(sys.argv[2], strict=True)
   ports = [int(value) for value in sys.argv[3:]]
   if address.is_loopback or address.is_unspecified or address.is_multicast:
       raise SystemExit('中断: SERVER_IP は LAN または VPN の待ち受け IPv4 にする')
   if network.prefixlen == 0:
       raise SystemExit('中断: LAN_SUBNET に全 IPv4 の許可は指定しない')
   if any(not 1024 <= port <= 65535 for port in ports) or ports[0] == ports[1]:
       raise SystemExit('中断: 2 つのポートは異なる 1024〜65535 の番号にする')
   links = json.loads(subprocess.check_output(['ip', '-j', '-4', 'addr', 'show']))
   if not any(item.get('local') == str(address) for link in links for item in link['addr_info']):
       raise SystemExit('中断: SERVER_IP がこのサーバーに付いていない')
   print('IPv4・CIDR・ポートの確認: OK')
   PY
   then
     if [ "$(podman info --format '{{.Host.Security.Rootless}}')" != true ]; then
       echo '中断: 自分のユーザーの rootless Podman を使う' >&2
     elif [ "$(loginctl show-user "$(id -u)" -p Linger --value)" != yes ]; then
       echo '中断: 先に linger を有効にする' >&2
     else
       sudo firewall-cmd --state &&
       sudo firewall-cmd --get-active-zones &&
       sudo firewall-cmd --zone="${FW_ZONE}" --list-all &&
       sudo firewall-cmd --permanent --zone="${FW_ZONE}" --list-all &&
       podman pull codeberg.org/forgejo/forgejo:15.0.9-rootless &&
       podman run --rm --entrypoint /usr/local/bin/gitea codeberg.org/forgejo/forgejo:15.0.9-rootless --version
     fi
   else
     echo '中断: 手順 1 の値を直す' >&2
   fi
   ```

   - 値の確認が `OK` で、firewalld が `running`、Forgejo の版が表示されればよい
   - `--get-active-zones` で待ち受ける NIC の zone が `FW_ZONE` と異なっていたら、手順 1 の値を直す
   - zone の `target` が `ACCEPT`、zone が `trusted`、または Web・Git 用 SSH ポートへの広い許可があれば、公開前に管理者へ確認する
   - **`sudo podman` は使わない**。固定した版の更新は後ろの[更新](#更新)で行う

1. 既存の設定やデータが無いことを確かめ、localhost 用の Quadlet を置く。

   ```bash
   if [ -z "${FORGEJO_HTTP_PORT}" ] || [ -z "${FORGEJO_SSH_PORT}" ]; then
     echo '中断: 手順 1 の変数を設定する' >&2
   elif [ -e ~/.config/containers/systemd/forgejo.container ] || [ -L ~/.config/containers/systemd/forgejo.container ] ||
        [ -e ~/.config/containers/systemd/forgejo.container.d ] || [ -L ~/.config/containers/systemd/forgejo.container.d ] ||
        [ -e ~/.config/systemd/user/forgejo.service ] || [ -L ~/.config/systemd/user/forgejo.service ] ||
        [ -e ~/.config/systemd/user/forgejo.service.d ] || [ -L ~/.config/systemd/user/forgejo.service.d ] ||
        [ -e ~/.local/share/forgejo ] || [ -L ~/.local/share/forgejo ] || podman container exists forgejo ||
        systemctl --user cat forgejo.service >/dev/null 2>&1; then
     echo '中断: 既存の Forgejo の設定・コンテナ・データがあるので上書きしない' >&2
   else
     install -d -m 700 ~/.config/containers/systemd ~/.local/share/forgejo &&
     (umask 077; cat > ~/.config/containers/systemd/forgejo.container <<EOF
   # setup-notes: forgejo
   [Unit]
   Description=Forgejo

   [Container]
   Image=codeberg.org/forgejo/forgejo:15.0.9-rootless
   ContainerName=forgejo
   UserNS=keep-id:uid=1000,gid=1000
   User=1000
   Group=1000
   Volume=%h/.local/share/forgejo:/var/lib/gitea:Z
   PublishPort=127.0.0.1:${FORGEJO_HTTP_PORT}:3000
   PublishPort=127.0.0.1:${FORGEJO_SSH_PORT}:2222
   Environment=FORGEJO__database__DB_TYPE=sqlite3
   Environment=FORGEJO__database__PATH=/var/lib/gitea/data/forgejo.db
   Environment=FORGEJO__server__HTTP_ADDR=0.0.0.0
   Environment=FORGEJO__server__HTTP_PORT=3000
   Environment=FORGEJO__server__DOMAIN=localhost
   Environment=FORGEJO__server__ROOT_URL=http://localhost:${FORGEJO_HTTP_PORT}/
   Environment=FORGEJO__server__SSH_DOMAIN=localhost
   Environment=FORGEJO__server__SSH_PORT=${FORGEJO_SSH_PORT}
   Environment=FORGEJO__server__START_SSH_SERVER=true
   Environment=FORGEJO__server__SSH_LISTEN_PORT=2222
   Environment=FORGEJO__service__DISABLE_REGISTRATION=true
   Environment=FORGEJO__service__REQUIRE_SIGNIN_VIEW=true
   Environment=FORGEJO__openid__ENABLE_OPENID_SIGNIN=false
   Environment=FORGEJO__openid__ENABLE_OPENID_SIGNUP=false
   Environment=FORGEJO__security__REVERSE_PROXY_TRUSTED_PROXIES=127.0.0.1/32,::1/128

   [Service]
   Restart=on-failure
   TimeoutStartSec=300

   [Install]
   WantedBy=default.target
   EOF
     ) &&
     chmod 600 ~/.config/containers/systemd/forgejo.container
   fi
   ```

   - データのディレクトリは自分のユーザーが所有する。`:Z` はこの専用ディレクトリにだけ付ける
   - **中断したときは手順 4 へ進まない**。既存の構築を使うか、必要なデータを退避してからやり直す
   - `INSTALL_LOCK` と `AutoUpdate` は定義に追加しない

1. 定義を読み直し、localhost でサービスを起動する。

   ```bash
   systemctl --user daemon-reload &&
   systemctl --user start forgejo.service &&
   systemctl --user is-active forgejo.service &&
   systemctl --user is-enabled forgejo.service &&
   podman exec forgejo id
   ```

   - `active`・`generated` が出て、コンテナ内の UID・GID が 1000 ならよい
   - **`systemctl --user enable` は使わない**。自動起動は Quadlet の `[Install]` と linger で設定済み
   - 起動に失敗したら `journalctl --user -u forgejo.service -n 100 --no-pager` と `podman logs forgejo` を見る。SELinux の拒否は `sudo ausearch -m AVC -ts recent` で確かめ、SELinux を無効にしない

1. 初期設定のページと localhost の待ち受けを確かめる。

   ```bash
   if [ -z "${FORGEJO_HTTP_PORT}" ] || [ -z "${FORGEJO_SSH_PORT}" ]; then
     echo '中断: 手順 1 の変数を設定する' >&2
   else
     curl -fsS --retry 10 --retry-delay 1 --retry-all-errors -o /dev/null -w '%{http_code}\n' \
       "http://127.0.0.1:${FORGEJO_HTTP_PORT}/"
     podman port forgejo
     ss -ltn "( sport = :${FORGEJO_HTTP_PORT} or sport = :${FORGEJO_SSH_PORT} )"
   fi
   ```

   - 初期設定のページが HTTP 200 を返し、2 つの公開ポートが `127.0.0.1` に限定されていればよい
   - この時点では LAN に公開しない

1. 別の PC で、初期設定用の SSH トンネルを開く。

   - クライアントの端末で `ssh -N -o ExitOnForwardFailure=yes -L 127.0.0.1:3000:127.0.0.1:3000 <OSユーザー>@<SERVER_IP>` を実行する。`<OSユーザー>` はサーバーを動かす一般ユーザー、`<SERVER_IP>` は手順 1 の IPv4 に置き換える
   - Web ポートを変えたら、`-L` の最初と最後の `3000` を両方ともその番号にする
   - クライアントのローカルポートが使用中なら、そのサービスを止めるか、同じ番号のポートが空いている別の PC で行う
   - トンネルの端末は開いたままにする

1. 別の PC のブラウザで初期設定を開き、管理者を作成する。

   - `http://localhost:3000/` を開く。Web ポートを変えたらその番号にする
   - DB は SQLite3、DB のパスは `/var/lib/gitea/data/forgejo.db`、ドメインは `localhost`、ベース URL は `http://localhost:3000/`（ホストの Web ポートに合わせる）を確かめる
   - HTTP ポートはコンテナ内部の `3000`、SSH ポートは手順 1 のホスト側の番号にする。リポジトリとアプリケーションのデータの場所は自動で入った値を使う
   - 自己登録を無効にする項目を有効にし、「管理者アカウントの設定」を開いてユーザー名・メールアドレス・パスワードを入力する。OS のアカウントとは別のアカウントになる
   - 「Forgejo をインストール」を押し、作った管理者でログインできることを確かめる
   - **次の手順は、管理者でログインできてから貼る**

1. 初期設定のロックと自己登録の無効化をサーバーで確かめる。

   ```bash
   if /usr/bin/python3 - <<'PY'
   import configparser
   from pathlib import Path

   data = Path.home() / '.local/share/forgejo'
   config = configparser.ConfigParser(interpolation=None)
   path = data / 'custom/conf/app.ini'
   if not path.is_file():
       raise SystemExit('中断: app.ini が見つからない')
   config.read_string('[DEFAULT]\n' + path.read_text())
   for section, key in [('security', 'INSTALL_LOCK'), ('service', 'DISABLE_REGISTRATION')]:
       if not config.getboolean(section, key, fallback=False):
           raise SystemExit(f'中断: {section}.{key} が true ではない')
       print(f'{section}.{key}=true')
   if not (data / 'data/forgejo.db').is_file():
       raise SystemExit('中断: SQLite の DB が見つからない')
   print('SQLite の DB: OK')
   PY
   then
     podman exec forgejo /usr/local/bin/gitea --config /var/lib/gitea/custom/conf/app.ini admin user list
   else
     echo '中断: 手順 7 の初期設定を完了する' >&2
   fi
   ```

   - ロックと自己登録無効が `true` で、ユーザーの一覧に作成した管理者があり、管理者の列が有効ならよい
   - **`app.ini` を `cat` しない**。トークンの署名鍵などの秘密が入る

1. 送信元と宛先を限定した、この手順専用の firewalld の規則を追加する。

   ```bash
   if [ -z "${SERVER_IP}" ] || [ -z "${LAN_SUBNET}" ] || [ -z "${FORGEJO_HTTP_PORT}" ] || [ -z "${FORGEJO_SSH_PORT}" ] || [ -z "${FW_ZONE}" ]; then
     echo '中断: 手順 1 の変数を設定する' >&2
   else
     FORGEJO_RULES=(
       "rule family=\"ipv4\" priority=\"100\" source address=\"${LAN_SUBNET}\" destination address=\"${SERVER_IP}\" port port=\"${FORGEJO_HTTP_PORT}\" protocol=\"tcp\" accept"
       "rule family=\"ipv4\" priority=\"100\" source address=\"${LAN_SUBNET}\" destination address=\"${SERVER_IP}\" port port=\"${FORGEJO_SSH_PORT}\" protocol=\"tcp\" accept"
     )
     FORGEJO_RULE_EXISTS=no
     for rule in "${FORGEJO_RULES[@]}"; do
       if sudo firewall-cmd --zone="${FW_ZONE}" --query-rich-rule="${rule}" >/dev/null ||
          sudo firewall-cmd --permanent --zone="${FW_ZONE}" --query-rich-rule="${rule}" >/dev/null; then
         FORGEJO_RULE_EXISTS=yes
       fi
     done
     if [ "${FORGEJO_RULE_EXISTS}" = yes ]; then
       echo '中断: 同じ規則が既にあるので、既存の構築と重ねない' >&2
     else
       for rule in "${FORGEJO_RULES[@]}"; do
         sudo firewall-cmd --permanent --zone="${FW_ZONE}" --add-rich-rule="${rule}" &&
         sudo firewall-cmd --zone="${FW_ZONE}" --add-rich-rule="${rule}" || break
       done
       sudo firewall-cmd --permanent --zone="${FW_ZONE}" --list-rich-rules
       sudo firewall-cmd --zone="${FW_ZONE}" --list-rich-rules
     fi
   fi
   ```

   - runtime と permanent に、指定した送信元・宛先・Web と Git 用 SSH の 2 規則があればよい
   - **既存の zone が `trusted`・`ACCEPT`、または同じポートへの広い許可があると、この規則だけでは送信元を絞れない**。公開前に管理者へ既存の許可を確認する
   - **中断や失敗が出たら手順 10 へ進まない**。追加できた規則を外す場合は[ロールバック](#ロールバック)の手順 3 を使う

1. 初期設定済みの Quadlet を LAN 用に変え、サービスを再起動する。

   ```bash
   if [ -z "${SERVER_IP}" ] || [ -z "${FORGEJO_HTTP_PORT}" ] || [ -z "${FORGEJO_SSH_PORT}" ]; then
     echo '中断: 手順 1 の変数を設定する' >&2
   elif /usr/bin/python3 - "${SERVER_IP}" "${FORGEJO_HTTP_PORT}" "${FORGEJO_SSH_PORT}" <<'PY'
   import configparser
   import ipaddress
   import os
   from pathlib import Path
   import sys

   address = str(ipaddress.IPv4Address(sys.argv[1]))
   http_port, ssh_port = sys.argv[2:]
   config = configparser.ConfigParser(interpolation=None)
   config.read_string('[DEFAULT]\n' + (Path.home() / '.local/share/forgejo/custom/conf/app.ini').read_text())
   if not config.getboolean('security', 'INSTALL_LOCK', fallback=False):
       raise SystemExit('中断: 初期設定が終わっていない')
   if not config.getboolean('service', 'DISABLE_REGISTRATION', fallback=False):
       raise SystemExit('中断: 自己登録が無効ではない')
   path = Path.home() / '.config/containers/systemd/forgejo.container'
   text = path.read_text()
   if not text.startswith('# setup-notes: forgejo\n'):
       raise SystemExit('中断: この手順が作った Quadlet ではない')
   replacements = {
       f'PublishPort=127.0.0.1:{http_port}:3000': f'PublishPort={address}:{http_port}:3000',
       f'PublishPort=127.0.0.1:{ssh_port}:2222': f'PublishPort={address}:{ssh_port}:2222',
       'Environment=FORGEJO__server__DOMAIN=localhost': f'Environment=FORGEJO__server__DOMAIN={address}',
       f'Environment=FORGEJO__server__ROOT_URL=http://localhost:{http_port}/': f'Environment=FORGEJO__server__ROOT_URL=http://{address}:{http_port}/',
       'Environment=FORGEJO__server__SSH_DOMAIN=localhost': f'Environment=FORGEJO__server__SSH_DOMAIN={address}',
   }
   lines = text.splitlines()
   for old, new in replacements.items():
       if lines.count(old) != 1:
           raise SystemExit(f'中断: 変更前の行が一致しない: {old}')
       lines[lines.index(old)] = new
   temporary = path.with_suffix('.container.tmp')
   with temporary.open('x') as stream:
       stream.write('\n'.join(lines) + '\n')
   temporary.chmod(0o600)
   os.replace(temporary, path)
   print('LAN 用の待ち受けと URL: 設定済み')
   PY
   then
     systemctl --user daemon-reload &&
     systemctl --user restart forgejo.service &&
     systemctl --user is-active forgejo.service &&
     podman port forgejo
   else
     echo '中断: 初期設定または Quadlet の内容を確認する' >&2
   fi
   ```

   - `active` が出て、Web と Git 用 SSH が `SERVER_IP` にだけ公開されていればよい
   - `0.0.0.0` や `[::]` には公開しない。ほかの NIC や IPv6 から使う設定は含めない

1. 別の PC でトンネルを閉じ、LAN の URL で管理者のログインを確かめる。

   - 手順 6 の端末で `Ctrl+C` を押してトンネルを閉じる
   - 許可した LAN または VPN の PC で `http://<SERVER_IP>:3000/` を開き、管理者でログインする。Web ポートを変えたらその番号にする
   - 登録のボタンが無いことと、`http://<SERVER_IP>:3000/user/sign_up` から通常の登録も OpenID の登録もできないことを確かめる
   - サーバーへ届く別の許可外の送信元からは、Web と Git 用 SSH の両方へ接続できないことを確かめる。ルーターのポート転送は作らない
   - 接続できないときは、サーバーの IP・FW_ZONE・クライアントの送信元と VPN の経路を確かめる

1. 別の PC のブラウザで、Git に使う公開鍵を Forgejo に登録する。

   - 管理者の設定から「SSH / GPG キー」を開き、Git を使う PC の SSH 公開鍵（`.pub`）を追加する
   - 公開鍵を持っていなければ、その PC で `ssh-keygen -t ed25519` を実行し、保存先とパスフレーズに答える。既存の鍵には上書きしない
   - **秘密鍵は登録しない**。公開鍵の末尾までを貼り、登録した鍵が一覧に出ることを確かめる

1. サーバーで、Git 用 SSH のホスト鍵の指紋を表示する。

   ```bash
   for public_key in ~/.local/share/forgejo/ssh/*.pub; do
     if [ -f "${public_key}" ]; then
       ssh-keygen -lf "${public_key}"
     fi
   done
   ```

   - `SHA256:` で始まる指紋を控え、次の手順で表示されるホスト鍵と照合する
   - 指紋が 1 つも出ないときは、`podman logs forgejo` で Git 用 SSH が起動しているか確かめる
   - ホストの OpenSSH（ポート 22）の指紋とは別になる

1. 別の PC で、ホスト鍵を照合して Git 用 SSH へ接続する。

   - `ssh -T -p 2222 git@<SERVER_IP>` を実行する。`<SERVER_IP>` は手順 1 の IPv4、`2222` はホスト側の Git 用 SSH ポートに置き換える
   - 初回に表示される指紋を手順 13 と照合し、一致したときだけ `yes` と答える
   - 公開鍵で認証され、Forgejo のユーザー名を含む案内が表示されればよい。シェルは開かない
   - パスワードを聞かれるときは、ホストのポート 22 へ接続していないか、登録した公開鍵に対応する秘密鍵をクライアントが使っているか確かめる
   - `REMOTE HOST IDENTIFICATION HAS CHANGED` が出たら、鍵を消して進めず、サーバーの指紋と再構築の有無を照合する

1. 別の PC のブラウザで、確認用のプライベートなリポジトリを作成する。

   - 新しいリポジトリを開き、名前を `forgejo-test` にする
   - プライベートを選び、README で初期化して作成する
   - Git 用 SSH の clone URL が `SERVER_IP` とホスト側の Git 用 SSH ポートを指していることを確かめる

1. 別の PC で clone と push を行い、ブラウザでコミットを確かめる。

   - 空の作業場所で `git clone ssh://git@<SERVER_IP>:2222/<Forgejoユーザー>/forgejo-test.git` を実行する。URL は手順 15 の画面からコピーしてもよい
   - `cd forgejo-test`、`printf 'Forgejo の接続確認\n' > connection-check.txt`、`git add connection-check.txt`、`git commit -m 'Forgejo の接続確認'`、`git push` の順に実行する
   - ブラウザで `connection-check.txt` と作成したコミットが見えればよい
   - `forgejo-test` が既に作業場所にあるときは、別の空の場所を使い、既存の作業を上書きしない
   - **次の手順は、clone と push の両方を確かめてから貼る**

1. サーバーでサービスを再起動し、設定とデータが残ることを確かめる。

   ```bash
   systemctl --user restart forgejo.service &&
   systemctl --user is-active forgejo.service &&
   podman port forgejo
   ```

   - `active` と LAN 向けのポートが出ればよい
   - 起動し直した直後は、Web と Git 用 SSH の待ち受けが始まるまで数秒待つ

1. 別の PC で、再起動後のログインと Git の接続を確かめる。

   - ブラウザで LAN の URL を開き、作成した管理者でログインする
   - `forgejo-test` と手順 16 のコミットが残ることを確かめる
   - clone した作業場所で `git fetch` を実行する。再起動のたびに SSH のホスト鍵の確認を求められないことを確かめる

1. サーバーを動かすユーザーをログアウトし、別の PC から接続する。

   - サーバーの同じユーザーの端末・デスクトップ・SSH セッションをすべて閉じる
   - 別の PC から、Web のログインと `git fetch` が引き続き使えることを確かめる
   - サーバーが眠ると接続できなくなる。自動サスペンドを止める前提を確かめる

1. サーバーを動かすユーザーで、ホストの SSH にログインし直す。

   - ポート 22 の通常の SSH で、サーバーを動かす OS のユーザーにログインする。`git` や Forgejo の管理者名ではログインしない
   - 手順 1 の変数を貼り直す
   - **次の手順は、再起動してよい時間に貼る**

1. サーバーを再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - Web と Git の接続がいったん切れる
   - **次の手順は、再起動後に同じ OS のユーザーでログインし直し、手順 1 の変数を貼り直してから貼る**

1. 再起動後の自動起動と待ち受けを確かめる。

   ```bash
   {
     if [ -z "${FW_ZONE}" ]; then
       echo '中断: 手順 1 の変数を貼り直す' >&2
     else
       systemctl --user is-active forgejo.service
       systemctl --user is-enabled forgejo.service
       systemctl --user show forgejo.service -p ActiveEnterTimestamp
       loginctl show-session "${XDG_SESSION_ID}" -p Timestamp
       loginctl show-user "$(id -u)" -p Linger
       podman port forgejo
       sudo firewall-cmd --zone="${FW_ZONE}" --list-rich-rules
     fi
   }
   ```

   - `active`・`generated`・`Linger=yes` が出て、サービスが起動した時刻がログインした時刻より前ならよい
   - LAN 向けの 2 つのポートと、手順 9 の 2 規則が残っていればよい

1. 別の PC で、OS の再起動後の Web と Git を確かめる。

   - LAN または VPN の URL で管理者がログインでき、リポジトリとコミットが残っていることを確かめる
   - 作業場所で `git fetch` を実行する。許可外の送信元からは、Web と Git 用 SSH の両方へ接続できないことも確かめる

---

## 設定ファイル

| 場所 | 内容 |
|---|---|
| `~/.config/containers/systemd/forgejo.container` | イメージ、ポート、URL、設定の環境変数、自動起動 |
| `~/.local/share/forgejo/custom/conf/app.ini` | 初期設定の結果と秘密を含む Forgejo の設定 |
| `~/.local/share/forgejo/data/forgejo.db` | SQLite の DB |
| `~/.local/share/forgejo/` の残り | リポジトリ、添付、SSH のホスト鍵などの永続データ |
| `~/.local/state/forgejo-backups/` | この手順で作る停止中のバックアップと復元前の退避 |

- コンテナでは `~/.local/share/forgejo` が `/var/lib/gitea` に見える
- Quadlet の `FORGEJO__...` で指定した項目は、再起動時に `app.ini` へ反映される。同じ項目は Quadlet 側を変更する
- `app.ini`・バックアップは秘密を含むので、内容を端末へ一覧表示したり、Git に登録したりしない

---

## バックアップ

- サーバーを動かすユーザーのシェルで行う。データと Quadlet を一緒に取る
- この節の手順 1 から 3 まで、Web と Git の操作が止まる
- バックアップにはリポジトリ・アカウント・SSH のホスト秘密鍵などが入る。保管先のディレクトリは 0700、アーカイブは 0600 にする

1. サービスを停止し、コンテナが止まったことを確かめる。

   ```bash
   systemctl --user stop forgejo.service &&
   systemctl --user show forgejo.service -p ActiveState -p SubState
   podman ps --filter name='^forgejo$'
   ```

   - `ActiveState=inactive` で、動いている `forgejo` の行が無ければよい
   - **次の手順は、サービスが止まってから貼る**

1. 停止中のデータと Quadlet を新しいアーカイブに保存する。

   ```bash
   unset FORGEJO_BACKUP FORGEJO_BACKUP_CANDIDATE
   if systemctl --user is-active --quiet forgejo.service || podman container exists forgejo; then
     echo '中断: 先にサービスを停止する' >&2
   elif [ ! -d ~/.local/share/forgejo ] || [ ! -f ~/.config/containers/systemd/forgejo.container ]; then
     echo '中断: データまたは Quadlet が無い' >&2
   elif ! install -d -m 700 ~/.local/state/forgejo-backups; then
     echo '中断: バックアップの保管ディレクトリを用意できない' >&2
   else
     FORGEJO_BACKUP_CANDIDATE="$HOME/.local/state/forgejo-backups/forgejo-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
     if [ -e "${FORGEJO_BACKUP_CANDIDATE}" ] || [ -L "${FORGEJO_BACKUP_CANDIDATE}" ]; then
       echo '中断: 同じ名前のバックアップがある' >&2
     elif (umask 077; tar --create --gzip --file="${FORGEJO_BACKUP_CANDIDATE}" --directory="$HOME" \
             .local/share/forgejo .config/containers/systemd/forgejo.container); then
       chmod 600 "${FORGEJO_BACKUP_CANDIDATE}" &&
       FORGEJO_BACKUP="${FORGEJO_BACKUP_CANDIDATE}" &&
       stat -c '%a %n' ~/.local/state/forgejo-backups "${FORGEJO_BACKUP}" &&
       printf 'バックアップ: %s\n' "${FORGEJO_BACKUP}"
     else
       echo '中断: バックアップに失敗した。アーカイブを復元には使わない' >&2
     fi
   fi
   ```

   - 保管ディレクトリが 700、アーカイブが 600 で、バックアップの場所が表示されればよい
   - DB だけ、リポジトリだけのコピーではなく、ディレクトリ全体を保存する
   - **次の手順は、バックアップが完了してから貼る**

1. サービスを起動し直す。

   ```bash
   systemctl --user start forgejo.service &&
   systemctl --user is-active forgejo.service
   ```

   - `active` が出ればよい。別の PC から Web のログインと `git fetch` を確かめる

1. バックアップを、アクセスを制限した別の保管先にも保存する。

   - バックアップのアーカイブを、別のディスクまたは別のサーバーへ暗号化した通信でコピーする
   - コピー先でも、ほかのユーザーに読ませない権限にする。外部の共有先に置くなら、アーカイブを暗号化してから送る
   - サーバーのディスクを失っても残る保管先を使う

---

## バックアップから復元する

> [!IMPORTANT]
> - 自分がこの文書の[バックアップ](#バックアップ)で作ったアーカイブを使う。バックアップと同じイメージの版・Quadlet・データを組にして戻す
> - 同じサーバー・同じユーザー・同じ IP とポートの復元を扱う。IP や許可 CIDR を変える移設では、Quadlet の URL・待ち受けと firewalld も合わせ直す

- 先に現在の状態を[バックアップ](#バックアップ)する。復元前のデータは消さず、別のディレクトリへ退避する
- この節の手順 3 から 5 まで Web と Git の操作が止まる

1. 復元するバックアップを指定する（`FORGEJO_RESTORE` は必ず値を入れる）。

   ```bash
   FORGEJO_RESTORE=''                 # 復元する .tar.gz の絶対パス
   ```

   - [バックアップ](#バックアップ)の手順 2 で表示された場所を入れる。作成途中や失敗したアーカイブは使わない

1. バックアップの構成とイメージを確かめ、空の作業場所に展開する。

   ```bash
   unset FORGEJO_RESTORE_WORK FORGEJO_RESTORE_READY
   if [ -z "${FORGEJO_RESTORE}" ] || [ ! -f "${FORGEJO_RESTORE}" ]; then
     echo '中断: 復元するバックアップの絶対パスを指定する' >&2
   elif install -d -m 700 ~/.local/state/forgejo-backups &&
     FORGEJO_RESTORE_WORK=$(mktemp -d "$HOME/.local/state/forgejo-backups/restore-XXXXXXXX") &&
     tar --extract --gzip --file="${FORGEJO_RESTORE}" --directory="${FORGEJO_RESTORE_WORK}" \
       --no-same-owner .local/share/forgejo .config/containers/systemd/forgejo.container &&
     /usr/bin/python3 - "${FORGEJO_RESTORE_WORK}" <<'PY'
   import configparser
   from pathlib import Path
   import re
   import subprocess
   import sys

   work = Path(sys.argv[1])
   quadlet = work / '.config/containers/systemd/forgejo.container'
   text = quadlet.read_text()
   if not text.startswith('# setup-notes: forgejo\n'):
       raise SystemExit('中断: この手順の Quadlet が入っていない')
   images = re.findall(r'^Image=(codeberg\.org/forgejo/forgejo:\d+\.\d+\.\d+-rootless)$', text, re.M)
   if len(images) != 1:
       raise SystemExit('中断: 固定した rootless イメージの行が一意ではない')
   config = configparser.ConfigParser(interpolation=None)
   data = work / '.local/share/forgejo'
   config.read_string('[DEFAULT]\n' + (data / 'custom/conf/app.ini').read_text())
   if not config.getboolean('security', 'INSTALL_LOCK', fallback=False) or not (data / 'data/forgejo.db').is_file():
       raise SystemExit('中断: 初期設定済みのデータが入っていない')
   print('復元するイメージ: ' + images[0])
   subprocess.run(['podman', 'pull', images[0]], check=True)
   print('復元前の構成確認: OK')
   PY
   then
     FORGEJO_RESTORE_READY="${FORGEJO_RESTORE_WORK}"
   else
     echo '中断: バックアップの展開または構成確認に失敗した' >&2
   fi
   ```

   - `復元前の構成確認: OK` が出て、バックアップ当時のイメージが取得できればよい
   - 元のデータへはまだ書き込まない。内容は空の専用作業場所に展開する
   - **次の手順は、復元する版が正しく、構成確認が完了してから貼る**

1. サービスを停止する。

   ```bash
   systemctl --user stop forgejo.service &&
   systemctl --user show forgejo.service -p ActiveState -p SubState
   podman ps --filter name='^forgejo$'
   ```

   - `inactive` で、動いている `forgejo` の行が無ければよい
   - **次の手順は、サービスが止まってから貼る**

1. 現在のデータを退避し、復元したデータと定義へ入れ替える。

   ```bash
   if [ -z "${FORGEJO_RESTORE_WORK}" ] || [ "${FORGEJO_RESTORE_READY}" != "${FORGEJO_RESTORE_WORK}" ] ||
        [ ! -d "${FORGEJO_RESTORE_WORK}/.local/share/forgejo" ] ||
        [ ! -f "${FORGEJO_RESTORE_WORK}/.config/containers/systemd/forgejo.container" ]; then
     echo '中断: この節の手順 2 の展開が終わっていない' >&2
   elif systemctl --user is-active --quiet forgejo.service || podman container exists forgejo; then
     echo '中断: 先にサービスを停止する' >&2
   elif [ ! -d ~/.local/share/forgejo ] || [ -L ~/.local/share/forgejo ] ||
        [ ! -f ~/.config/containers/systemd/forgejo.container ]; then
     echo '中断: 現在のデータまたは Quadlet の状態を確認する' >&2
   else
     FORGEJO_RESTORE_SAVED=$(mktemp -d "$HOME/.local/state/forgejo-backups/before-restore-XXXXXXXX") &&
     cp -p ~/.config/containers/systemd/forgejo.container "${FORGEJO_RESTORE_SAVED}/forgejo.container" &&
     mv ~/.local/share/forgejo "${FORGEJO_RESTORE_SAVED}/data" &&
     mv "${FORGEJO_RESTORE_WORK}/.local/share/forgejo" ~/.local/share/forgejo &&
     install -m 600 "${FORGEJO_RESTORE_WORK}/.config/containers/systemd/forgejo.container" ~/.config/containers/systemd/forgejo.container &&
     chmod 700 ~/.local/share/forgejo &&
     printf '復元前の退避: %s\n' "${FORGEJO_RESTORE_SAVED}"
   fi
   ```

   - 既存の DB へ追記せず、停止中にデータ全体を入れ替える。復元前のデータと定義は表示された場所に残る
   - **失敗したら起動せず、退避と復元先の両方がどこにあるか確認する**
   - **次の手順は、入れ替えがすべて完了してから貼る**

1. 定義を読み直し、復元した版で起動する。

   ```bash
   systemctl --user daemon-reload &&
   systemctl --user start forgejo.service &&
   systemctl --user is-active forgejo.service &&
   podman exec forgejo /usr/local/bin/gitea --version
   ```

   - `active` とバックアップ当時の版が出ればよい。SELinux のラベルは専用 bind mount の `:Z` で反映される

1. 別の PC で、復元したアカウント・リポジトリ・SSH を確かめる。

   - Web にログインし、バックアップ時点のリポジトリとコミットが見えることを確かめる
   - `git fetch` を実行し、確認用の新しいコミットを push する。SSH のホスト鍵の指紋もバックアップ当時と一致することを確かめる
   - 自己登録が無効なことと、許可外の送信元から接続できないことを確かめる
   - 退避した現在のデータと展開用の作業場所は、復元を確認するまで消さない

---

## 更新

- 自動更新は使わず、公式のリリースノートとサポート期限を確認して固定した版を指定する
- メジャー番号を変える更新では、その間の各メジャー版の破壊的変更も読む
- 更新後に DB の移行が始まったら、旧イメージだけへ戻さない。[バックアップから復元する](#バックアップから復元する)で旧イメージ・旧データ・旧定義を一緒に戻す

1. 更新する版を設定する（`FORGEJO_VERSION` は必ず値を入れる）。

   ```bash
   FORGEJO_VERSION=''                 # 公式の安定版の番号（例: 15.0.9、先頭の v は付けない）
   ```

   - 公式の[リリース一覧](https://forgejo.org/releases/)で、対象版の変更とサポート期限を確認する
   - `latest`・メジャー番号だけのタグ・テスト版は指定しない

1. 指定した公式イメージを取得する。

   ```bash
   if [[ ! ${FORGEJO_VERSION} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
     echo '中断: 安定版の番号を x.y.z の形式で指定する' >&2
   else
     podman pull "codeberg.org/forgejo/forgejo:${FORGEJO_VERSION}-rootless" &&
     podman run --rm --entrypoint /usr/local/bin/gitea "codeberg.org/forgejo/forgejo:${FORGEJO_VERSION}-rootless" --version
   fi
   ```

   - 指定した版が表示されればよい。この時点では既存のサービスを変えない

1. サービスを停止し、更新直前のバックアップを取る。

   - [バックアップ](#バックアップ)の手順 1・2 を行い、完了を確認する。手順 3 の起動は飛ばす
   - アーカイブの場所を控える。旧イメージは復元の確認まで削除しない
   - **次の手順は、サービスが停止し、バックアップが完了してから貼る**

1. 固定したイメージの行だけを更新する。

   ```bash
   if [[ ! ${FORGEJO_VERSION} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
     echo '中断: この節の手順 1 の版を設定する' >&2
   elif systemctl --user is-active --quiet forgejo.service || podman container exists forgejo; then
     echo '中断: この節の手順 3 の停止とバックアップを先に行う' >&2
   elif [ -z "${FORGEJO_BACKUP}" ] || [ ! -s "${FORGEJO_BACKUP}" ]; then
     echo '中断: 更新直前のバックアップが無い' >&2
   else
     /usr/bin/python3 - "${FORGEJO_VERSION}" <<'PY'
   import os
   from pathlib import Path
   import re
   import sys

   path = Path.home() / '.config/containers/systemd/forgejo.container'
   text = path.read_text()
   if not text.startswith('# setup-notes: forgejo\n'):
       raise SystemExit('中断: この手順が作った Quadlet ではない')
   pattern = r'^Image=codeberg\.org/forgejo/forgejo:\d+\.\d+\.\d+-rootless$'
   text, count = re.subn(pattern, f'Image=codeberg.org/forgejo/forgejo:{sys.argv[1]}-rootless', text, flags=re.M)
   if count != 1:
       raise SystemExit('中断: 固定したイメージの行が一意ではない')
   temporary = path.with_suffix('.container.tmp')
   with temporary.open('x') as stream:
       stream.write(text)
   temporary.chmod(0o600)
   os.replace(temporary, path)
   print('イメージの行: 更新済み')
   PY
   fi
   ```

   - イメージの行だけが更新され、URL・ポート・データの場所は引き継ぐ
   - **次の手順は、イメージの行の更新が完了してから貼る**

1. 新しい版で起動し、ログと診断を確かめる。

   ```bash
   systemctl --user daemon-reload &&
   systemctl --user start forgejo.service &&
   systemctl --user is-active forgejo.service &&
   podman exec forgejo /usr/local/bin/gitea --version &&
   podman exec forgejo /usr/local/bin/gitea --config /var/lib/gitea/custom/conf/app.ini doctor check --all
   ```

   - `active` と指定した版が出て、診断で問題が報告されなければよい
   - DB の移行がある場合は、完了まで待つ。失敗したらログを確認し、旧イメージだけに戻さない

1. 別の PC で、更新後の Web と Git を確かめる。

   - 管理者のログイン、リポジトリの一覧・既存のコミット、`git fetch`、新しいコミットの push を確かめる
   - 自己登録が無効で、許可外の送信元から接続できないことを確かめる
   - 問題があれば[バックアップから復元する](#バックアップから復元する)で更新直前のアーカイブを戻す。更新後に受け付けた変更は、そのバックアップへ戻すと失われる

---

## ロールバック

- Forgejo の起動と、この文書が追加した firewalld の 2 規則を解除する。データとバックアップは既定で残す
- サーバーを動かすユーザーのシェルで行う。手順 1 の `SERVER_IP`・`LAN_SUBNET`・ポート・`FW_ZONE` は、追加したときと同じ値を貼り直す
- Podman と linger はほかのサービスも使うので、この節では削除・無効化しない

1. 必要なデータをバックアップする。

   - 保持するデータがあれば[バックアップ](#バックアップ)を通す
   - 保存したアーカイブの場所を控える

1. Forgejo を停止し、定義を退避して自動起動を解除する。

   ```bash
   if [ ! -f ~/.config/containers/systemd/forgejo.container ]; then
     echo '中断: この手順の Quadlet が見つからない' >&2
   elif ! grep -qx '# setup-notes: forgejo' ~/.config/containers/systemd/forgejo.container; then
     echo '中断: この手順が作った Quadlet ではない' >&2
   else
     install -d -m 700 ~/.local/state/forgejo-backups &&
     FORGEJO_REMOVED=$(mktemp -d "$HOME/.local/state/forgejo-backups/removed-XXXXXXXX") &&
     systemctl --user stop forgejo.service &&
     mv ~/.config/containers/systemd/forgejo.container "${FORGEJO_REMOVED}/forgejo.container" &&
     systemctl --user daemon-reload &&
     printf '退避した定義: %s/forgejo.container\n' "${FORGEJO_REMOVED}"
   fi
   ```

   - 定義は `~/.config/containers/systemd` から外れ、サービスが次回のログイン・起動で戻らなくなる
   - 永続データと SSH のホスト鍵は残る

1. この文書が追加した 2 規則だけを runtime と permanent から外す。

   ```bash
   if [ -z "${SERVER_IP}" ] || [ -z "${LAN_SUBNET}" ] || [ -z "${FORGEJO_HTTP_PORT}" ] || [ -z "${FORGEJO_SSH_PORT}" ] || [ -z "${FW_ZONE}" ]; then
     echo '中断: 追加したときの手順 1 の変数を設定する' >&2
   else
     for port in "${FORGEJO_HTTP_PORT}" "${FORGEJO_SSH_PORT}"; do
       rule="rule family=\"ipv4\" priority=\"100\" source address=\"${LAN_SUBNET}\" destination address=\"${SERVER_IP}\" port port=\"${port}\" protocol=\"tcp\" accept"
       if sudo firewall-cmd --zone="${FW_ZONE}" --query-rich-rule="${rule}" >/dev/null; then
         sudo firewall-cmd --zone="${FW_ZONE}" --remove-rich-rule="${rule}"
       fi
       if sudo firewall-cmd --permanent --zone="${FW_ZONE}" --query-rich-rule="${rule}" >/dev/null; then
         sudo firewall-cmd --permanent --zone="${FW_ZONE}" --remove-rich-rule="${rule}"
       fi
     done
     sudo firewall-cmd --zone="${FW_ZONE}" --list-rich-rules
     sudo firewall-cmd --permanent --zone="${FW_ZONE}" --list-rich-rules
   fi
   ```

   - 指定した送信元・宛先・ポート・priority の規則が無くなればよい。他のサービスや、同じポートでも別の規則は外さない

1. 自動起動と待ち受けが解除されたことを確かめる。

   ```bash
   if [ -z "${FORGEJO_HTTP_PORT}" ] || [ -z "${FORGEJO_SSH_PORT}" ]; then
     echo '中断: 手順 1 のポートを設定する' >&2
   else
     systemctl --user status forgejo.service --no-pager
     podman ps --filter name='^forgejo$'
     ss -ltn "( sport = :${FORGEJO_HTTP_PORT} or sport = :${FORGEJO_SSH_PORT} )"
   fi
   ```

   - `forgejo.service` が見つからず、動いている `forgejo` と 2 ポートの待ち受けが無ければよい
   - イメージとデータを残すだけなら、ここで終わる
   - ほかに常駐するユーザーサービスが無く、linger も切るときだけ [linger のロールバック](linger.md#ロールバック)を行う

---

## 保持したデータも削除する（任意）

> [!CAUTION]
> **この節の手順 2** は、DB・リポジトリ・アカウント・添付・SSH のホスト鍵を取り戻せなくする。バックアップと復元前の退避は残る。

- 先に[ロールバック](#ロールバック)を最後まで行う。バックアップから戻す必要が無いと確かめたときだけ行う

1. 削除する専用ディレクトリを確かめる。

   ```bash
   ls -ld ~/.local/share/forgejo
   du -sh ~/.local/share/forgejo
   ```

   - **次の手順は、このデータを消してよいと確かめてから貼る**

1. 停止した Forgejo の専用データだけを削除する（取り戻せない）。

   ```bash
   if [ -e ~/.config/containers/systemd/forgejo.container ] || podman container exists forgejo ||
        systemctl --user is-active --quiet forgejo.service; then
     echo '中断: 先にロールバックで停止と自動起動の解除を行う' >&2
   elif [ -L ~/.local/share/forgejo ] || [ ! -d ~/.local/share/forgejo ]; then
     echo '中断: データの場所が専用ディレクトリではない' >&2
   else
     rm -r -- ~/.local/share/forgejo
   fi
   ```

   - `~/.local/share/forgejo` だけを消す。`podman system reset` や Podman 全体の削除は行わない
   - `~/.local/state/forgejo-backups` のアーカイブ・退避にも秘密は残る。不要になったものは、その保管先の運用に合わせて個別に消す

---
