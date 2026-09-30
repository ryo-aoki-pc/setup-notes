# GNOME Remote Desktop のデスクトップ共有の手順（ログインしている画面を RDP で使う）

## 実施手順

> [!IMPORTANT]
> - **共有するデスクトップに PC の画面でログインしたユーザー本人が、そのデスクトップの端末で貼る**。`sudo -i` / `su -` したシェルでは貼らない（`grdctl` は、実行したユーザーの設定とキーリングに書くため）
> - 画面がロックされると、共有は止まる。放置してもロックしないように、先に [gnome-power.md 手順 1・2](gnome-power.md#実施手順) を行う（[自動ログインで使う](#自動ログインで使う任意)なら必須）
> - **手順 4 と手順 6 には対話入力がある**（RDP のユーザー名とパスワード、`sudo` のパスワード）。入力し終えてから次の手順を貼る
> - 手順 9（クライアントからの接続）だけ別のマシンで行う
> - [リモートログイン](gnome-remote-desktop.md)（GDM で新しいセッションを作る方式）と同じ PC でも使える。そのときのポートは、手順 1 で自動で 3390 になる

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 再起動の後、PC の前で誰もログインしなくても使うなら[自動ログインで使う（任意）](#自動ログインで使う任意)、見せるだけにするなら[見るだけにする（任意）](#見るだけにする任意)、接続元を絞るなら[接続元を LAN に絞る（任意）](#接続元を-lan-に絞る任意)。戻すときは[ロールバック](#ロールバック)
- 後からリモートログインを有効にしたら、[後からリモートログインを有効にしたとき](#後からリモートログインを有効にしたとき)でポートを移す

> [!WARNING]
> **x86_64 のコンテナでのみ検証した手順書**で、実機では本実行していない。GNOME Shell はヘッドレスで動かし、クライアントは別のコンテナの FreeRDP にした。PC の画面・画面ロックで止まること・GDM の自動ログインそのものは確かめていない（[対象と検証環境](#対象と検証環境)）。

1. 変数を設定する（`SERVER_IP` は必ず値を入れる）。

   ```bash
   SERVER_IP=192.168.10.100            # ← 自分の値に書き換える。クライアントが接続に使う IP。<SERVER_IP>
   ```

   ```bash
   SERVER_NAME=$(hostname)             # 証明書の CN と SAN に入る（自動）。<HOSTNAME>
   SERVER_FQDN=$(hostname -f)          # 同上。<HOSTNAME>.<DOMAIN>
   RDP_PORT=$(if [ "$(systemctl is-enabled gnome-remote-desktop.service 2>/dev/null)" = enabled ]; then echo 3390; else echo 3389; fi)   # 待ち受けるポート（自動）。<RDP_PORT>
   for v in USER SERVER_IP SERVER_NAME SERVER_FQDN RDP_PORT; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須なのは `SERVER_IP` の 1 行だけ**。残りは既定のままでよい
   - `RDP_PORT` は、リモートログインのシステムのデーモン（`gnome-remote-desktop.service`）が有効なら `3390`、そうでなければ `3389` になる
   - 最後に値を読み戻して確かめる
   - `USER` が `root` なら、ここで止めて、共有するデスクトップの端末で貼り直す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**、手順 1 の 2 つのブロックを貼り直してから先へ進む

   <details>
   <summary>補足: 変数について</summary>

   - `SERVER_IP`・`SERVER_NAME`・`SERVER_FQDN` は、[gnome-remote-desktop.md](gnome-remote-desktop.md) の手順 1 と同じ。証明書の SAN に入れる（手順 2）
   - `RDP_PORT` の判定に使う `systemctl is-enabled gnome-remote-desktop.service` は、`--user` を付けないのでシステムの unit を見る。デスクトップ共有が使うのは、同じ名前のユーザーの unit（`systemctl --user`）
   - リモートログインのデーモンは 3389/tcp で待ち受けるので、同じ PC ではデスクトップ共有を 3390/tcp にする（RHEL 10 の文書と同じ番号）
   - 後からリモートログインを有効にしたときは、[後からリモートログインを有効にしたとき](#後からリモートログインを有効にしたとき)でポートを変える

   </details>

1. 証明書と鍵を openssl で作る（既にあれば作らない）。

   ```bash
   if [ -e ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] || [ -e ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ]; then
     echo '中断: 証明書か鍵が既にある。そのまま使うなら手順 3 へ進む。作り直すなら、この手順の補足のとおり別名に移してから貼り直す' >&2
   elif [ -z "${SERVER_IP}" ] || [ -z "${SERVER_NAME}" ] || [ -z "${SERVER_FQDN}" ]; then
     echo '中断: 手順 1 の変数が空のまま。手順 1 を貼り直す' >&2
   else
     mkdir -p ~/.local/share/gnome-remote-desktop/certificates
     openssl req -x509 -newkey rsa:2048 -noenc -days 3650 \
       -subj "/CN=${SERVER_NAME}" \
       -addext "subjectAltName=DNS:${SERVER_NAME},DNS:${SERVER_FQDN},DNS:${SERVER_IP},IP:${SERVER_IP}" \
       -addext "extendedKeyUsage=serverAuth" \
       -keyout ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key \
       -out    ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
   fi
   ls -l ~/.local/share/gnome-remote-desktop/certificates
   ```

   - `rdp-tls.crt`（`-rw-r--r--`）と `rdp-tls.key`（`-rw-------`）の 2 行が出ればよい
   - 置き場所は、設定アプリがデスクトップ共有をオンにしたときに証明書を作る場所と同じ
   - `中断: 証明書か鍵が既にある` と出たら、設定アプリで一度オンにしたことがある

   <details>
   <summary>補足: 証明書</summary>

   - 中身は [gnome-remote-desktop.md 手順 2](gnome-remote-desktop.md#実施手順) と同じ（SAN に IP を `DNS:` でも入れる理由も同書の補足）。違うのは、自分のホームに自分の所有で作ること
   - openssl 3.5.8 は、鍵を最初から 0600 で書いた（コンテナで確認）ので、`chmod` は要らない
   - デーモンは自分のユーザーで動き、自分のホームの証明書を読む。コンテナには SELinux が無かったので、SELinux が Enforcing の PC では確かめていない
   - gnome-control-center 47 は、GSettings の `tls-cert` と `tls-key` が空で、`~/.local/share/gnome-remote-desktop/certificates/rdp-tls.{crt,key}` も無いときにだけ証明書を作る（ソースから）。同じ場所に置けば、設定アプリで切り替えても作り直されない
   - 既にある証明書を作り直すときは、先に別名に移す（戻すときに使う）:
     - `mv ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt.old`
     - 鍵（`rdp-tls.key`）も同じように移し、この手順を貼り直す。手順 3 の後に `systemctl --user restart gnome-remote-desktop.service` で読み直させる

   </details>

1. grdctl で、証明書と鍵・ポート・操作の許可を設定する。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: 手順 1 の RDP_PORT が空のまま。手順 1 を貼り直す' >&2; else
   grdctl rdp set-tls-cert ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
   grdctl rdp set-tls-key  ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
   grdctl rdp set-port "${RDP_PORT}"
   grdctl rdp disable-port-negotiation
   grdctl rdp disable-view-only
   fi
   ```

   - 初めて設定するときだけ、`[x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` が 1 回ずつ出る。設定する前の空の値を読んだもので、害は無い
   - ほかに何も表示されなければよい
   - `disable-view-only` は、接続した側のマウスとキーボードを受け付ける設定。見せるだけにするなら[見るだけにする（任意）](#見るだけにする任意)

   <details>
   <summary>補足: grdctl（デスクトップ共有）</summary>

   - `--system` も `--headless` も付けない `grdctl` は、デスクトップ共有の設定を変える。書き先は自分の GSettings の `org.gnome.desktop.remote-desktop.rdp`（設定アプリと同じ）
   - `disable-port-negotiation` は、指定したポートが使われていたときに、次の 10 個のポートを順に試すのを止める。ポートが勝手に変わって、手順 6 で開けたポートと食い違うのを防ぐ
   - コンテナでの設定前と後の値:

   ```
   $ gsettings list-recursively org.gnome.desktop.remote-desktop.rdp     # 設定前（既定）
   org.gnome.desktop.remote-desktop.rdp enable false
   org.gnome.desktop.remote-desktop.rdp negotiate-port true
   org.gnome.desktop.remote-desktop.rdp port uint16 3389
   org.gnome.desktop.remote-desktop.rdp screen-share-mode 'mirror-primary'
   org.gnome.desktop.remote-desktop.rdp tls-cert ''
   org.gnome.desktop.remote-desktop.rdp tls-key ''
   org.gnome.desktop.remote-desktop.rdp view-only true
   ```

   - 既定の `view-only true` は「見るだけ」。設定アプリの「リモートコントロール」がオフの状態にあたる
   - `screen-share-mode 'mirror-primary'` は、PC のプライマリの画面をそのまま見せる（変えない）

   </details>

1. RDP のユーザー名とパスワードを、引数なしで対話入力する。

   ```bash
   grdctl rdp set-credentials
   ```

   - ユーザー名とパスワードを聞かれる。クライアントが接続するときに入れるもので、OS のアカウントと違ってよい
   - 引数なしで打つのは、パスワードをシェルの履歴に残さないため
   - 入れた値は、ログインのキーリング（GNOME Keyring）に保存される
   - **次の手順は、ユーザー名とパスワードを入力し終えてから貼る**（続けて貼ると入力として食われる）

   <details>
   <summary>補足: 資格情報の保存先</summary>

   - デスクトップ共有の資格情報は、libsecret でログインのキーリングに入る（スキーマ `org.gnome.RemoteDesktop.RdpCredentials`、ラベル `GNOME Remote Desktop RDP credentials`）。リモートログインの `/var/lib/gnome-remote-desktop/.../credentials.ini` とは別物
   - キーリングが開いていない（ロックされている）と、`grdctl status` の `Username` が `(empty)` になり、接続は `[RDP] Credentials are not set, denying client` で断られる（コンテナで確認。[自動ログインで使う](#自動ログインで使う任意)の理由）
   - パスワードを変えるときも、この手順を貼り直すだけでよい。**次の接続から新しいパスワードが効き、デーモンの再起動は要らない**（コンテナで確認。リモートログインとは違う）

   </details>

1. RDP を有効にする。

   ```bash
   grdctl rdp enable
   systemctl --user is-enabled gnome-remote-desktop.service
   ```

   - `enabled` と出ればよい
   - デーモンが待ち受けたかは、手順 7 で確かめる

   <details>
   <summary>補足: grdctl rdp enable</summary>

   - `grdctl rdp enable` は、GSettings の `enable` を true にするだけでなく、ユーザーの unit `gnome-remote-desktop.service` を enable して起動する（gnome-remote-desktop 49.3 のソースと、コンテナで確認）
   - unit の `WantedBy=gnome-session.target` なので、次にログインしたときも GNOME のセッションと一緒に起動するはず（`~/.config/systemd/user/gnome-session.target.wants/` にリンクができることまでを確かめた。ログインし直しては確かめていない）
   - 資格情報（手順 4）を enable より先に入れてあるので、再起動は要らない
   - 待ち受けの確認を手順 7 に分けたのは、起動の途中で確かめると外れるため。コンテナでは、`grdctl rdp enable` の直後の `grdctl status` が `Unit status: activating` で、`ss` は何も出さなかった。デーモンは起動して 1 秒ほどで `RDP server started` をジャーナルに出した

   </details>

1. ファイアウォールで、`RDP_PORT` の TCP を開ける。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: 手順 1 の RDP_PORT が空のまま。手順 1 を貼り直す' >&2; else
   sudo firewall-cmd --permanent --add-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   fi
   ```

   - `success` が 2 行出て、最後に `<RDP_PORT>/tcp` を含む行が出ればよい
   - リモートログインと併用している PC でも、ここで 3390/tcp を足す（3389/tcp はリモートログインの `rdp` サービスで開いている）
   - [リモートログインで接続元を LAN に絞って](gnome-remote-desktop.md#接続元を-lan-に絞る任意)いる PC は、この手順の後に[接続元を LAN に絞る（任意）](#接続元を-lan-に絞る任意)も行う
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: ファイアウォール</summary>

   - firewalld の定義済みサービス `rdp` は 3389/tcp だけなので、ポートで開ける
   - public ゾーンで開けるので、public ゾーンに属するすべての NIC で開く（gnome-remote-desktop.md と同じ）
   - コンテナで、開ける前は別のコンテナの FreeRDP が `ERRCONNECT_CONNECT_FAILED` で接続できず、開けた後につながった

   </details>

1. デーモンが待ち受けているかを確かめる。

   ```bash
   grdctl status
   ss -Hlnt "sport = :${RDP_PORT:?手順 1 の RDP_PORT が空のまま}"
   ```

   - `grdctl status` で、`Unit status: active`・`Status: enabled`・`Port: <RDP_PORT>`・`View-only: no`・`Negotiate port: no`・`Username: (hidden)` を確かめる
   - `TLS fingerprint` の値を控えておく（手順 8 と手順 9 で使う）
   - `ss` が `LISTEN … 0.0.0.0:<RDP_PORT> …` の 1 行を出せばよい
   - `ss` が何も出さないときは、`systemctl --user restart gnome-remote-desktop.service` の後にこの手順を貼り直す（この手順の補足）

   <details>
   <summary>補足: 待ち受けていないとき</summary>

   **コンテナでの実測**: `RDP_PORT` と同じポートでリモートログインのデーモンが待ち受け始めると、デスクトップ共有のデーモンは待ち受けを止め、`Failed to start RDP server: Error binding to address 0.0.0.0:3389: Address already in use` をジャーナルに出した。

   - このとき `grdctl status` は `Unit status: active`・`Status: enabled` のままで、見分けられない
   - ジャーナルは `journalctl --user -u gnome-remote-desktop.service -b` で見る
   - ポートを 3390 にして起動し直すと、両方が待ち受けた（[後からリモートログインを有効にしたとき](#後からリモートログインを有効にしたとき)）
   - `grdctl status` の `TLS fingerprint: (null)` と `RDP server certificate is invalid.` は、証明書が読めていない（手順 2 が `中断:` で終わったまま手順 3 を貼った、など）

   </details>

1. TLS のハンドシェイクと、提示される証明書を確かめる。

   ```bash
   cat > ~/rdp_tls_probe.py <<'PY'
   #!/usr/bin/env python3
   # usage: python3 rdp_tls_probe.py <host> [port]
   import socket, ssl, struct, sys, hashlib, subprocess
   host = sys.argv[1]; port = int(sys.argv[2]) if len(sys.argv) > 2 else 3389
   # X.224 Connection Request + RDP_NEG_REQ (PROTOCOL_SSL|PROTOCOL_HYBRID)
   neg = struct.pack('<BBHI', 0x01, 0x00, 8, 0x00000003)
   x224 = bytes([len(neg) + 6, 0xE0, 0, 0, 0, 0, 0]) + neg
   tpkt = struct.pack('>BBH', 3, 0, 4 + len(x224)) + x224
   s = socket.create_connection((host, port), timeout=10)
   s.sendall(tpkt)
   resp = s.recv(1024)
   t, flags, length, proto = struct.unpack('<BBHI', resp[11:19])
   print(f"negotiation: type=0x{t:02x} ({'RESPONSE' if t == 2 else 'FAILURE'}) selectedProtocol=0x{proto:x}")
   if t != 2: sys.exit(1)
   ctx = ssl.create_default_context(); ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE
   ts = ctx.wrap_socket(s, server_hostname=host)
   der = ts.getpeercert(binary_form=True)
   print("tls:", ts.version(), ts.cipher()[0])
   print("fingerprint:", ':'.join(f'{b:02x}' for b in hashlib.sha256(der).digest()))
   pem = ssl.DER_cert_to_PEM_cert(der)
   print(subprocess.run(['openssl', 'x509', '-noout', '-subject', '-ext', 'subjectAltName'], input=pem, capture_output=True, text=True).stdout, end='')
   ts.close()
   PY
   python3 ~/rdp_tls_probe.py "${SERVER_IP}" "${RDP_PORT}"
   grdctl status | grep 'TLS fingerprint'
   ```

   - `~/rdp_tls_probe.py` を書き出して、`${SERVER_IP}` の `${RDP_PORT}` に対して実行する（FreeRDP も RDP のパスワードも要らない）
   - 次の 3 つがそろえばよい
     - `selectedProtocol=0x2` でネゴシエーションが成立する
     - `fingerprint:` の行が、最後の `TLS fingerprint:` の行と**完全一致**する
     - SAN に、接続に使う名前が `DNS:` エントリとして含まれている
   - 確認が済んだら `rm ~/rdp_tls_probe.py` で消してよい（この手順書が作る唯一の作業ファイル）

   <details>
   <summary>補足: TLS プローブ</summary>

   - スクリプトは [gnome-remote-desktop.md 手順 10](gnome-remote-desktop.md#実施手順) と同じもの。第 2 引数でポートを渡す
   - プローブは TLS を張った直後に切るので、`journalctl --user -u gnome-remote-desktop.service` には `nla_recv() error: -1` や `client authentication failure` が出るが、正常（コンテナでも出た。同書の手順 10 の補足）
   - コンテナでの結果:

   ```
   $ python3 ~/rdp_tls_probe.py "${SERVER_IP}" "${RDP_PORT}"
   negotiation: type=0x02 (RESPONSE) selectedProtocol=0x2
   tls: TLSv1.3 TLS_AES_256_GCM_SHA384
   fingerprint: <FINGERPRINT>
   subject=CN=<HOSTNAME>
   X509v3 Subject Alternative Name:
       DNS:<HOSTNAME>, DNS:<HOSTNAME>, DNS:<SERVER_IP>, IP Address:<SERVER_IP>
   $ grdctl status | grep 'TLS fingerprint'
   	TLS fingerprint: <FINGERPRINT>
   ```

   </details>

1. LAN 内の別のマシンから、RDP クライアントでつなぐ。

   - AlmaLinux 10 の FreeRDP（`freerdp` パッケージ）なら `xfreerdp /v:<SERVER_IP>:<RDP_PORT> /u:<RDP のユーザー名>` の形でつなぐ。ほかのディストリビューションでは、コマンドの名前が `xfreerdp3` のことがある
   - `<SERVER_IP>`・`<RDP_PORT>`・`<RDP のユーザー名>` は、手順 1 と手順 4 の値に読み替える
   - 証明書の確認を聞かれたら、表示された Thumbprint が手順 7 の `TLS fingerprint` と同じかを見てから受け入れる
   - パスワードは手順 4 のもの。通ると、PC の画面がそのまま見え、マウスとキーボードで操作できる
   - 問題があれば、PC の端末で `journalctl --user -u gnome-remote-desktop.service -f` を見る

   <details>
   <summary>補足: クライアントからの接続</summary>

   - つながると、PC の上部バーの右に画面共有の表示が出る（RHEL 10 の文書から。画面では確かめていない）
   - コンテナでは、別のコンテナの FreeRDP 3.10.3 からつなぎ、次を確かめた
     - 正しいパスワードで、ヘッドレスの GNOME Shell の画面共有のセッション（Mutter の ScreenCast の Stream）ができた
     - 違うパスワードでは、PC 側のジャーナルに `AcceptSecurityContext status SEC_E_MESSAGE_ALTERED [0x8009030F]` が出て断られた（リモートログインのパスワード違いと同じ署名）
     - クライアントの上でポインタを動かすと、PC のポインタが動いた。`View-only: yes` のときは動かなかった。キーボードの入力は確かめていない
   - Windows のリモート デスクトップ接続・Android のクライアントでは確かめていない

   </details>

---

## 自動ログインで使う（任意）

- 再起動した後、PC の前で誰もログインしなくても共有できるようにする節。PC は電源を入れるとこのユーザーで自動でログインする
- 前提: 実施手順を終え、[gnome-power.md 手順 1・2](gnome-power.md#実施手順) で画面をロックしないようにしてあること（ロックされると共有が止まる）
- この節の手順 2 はパスワードの対話入力、手順 4 は再起動で止まる。手順 5 は別のマシンで行う
- ログインのキーリングは、GDM の自動ログインでは開かない。この節の手順 2 で、キーリングのパスワードを空にして、開けなくても読めるようにする
- 元に戻すのは、この節の手順 6・7

> [!WARNING]
> - **PC の前に座った人は、パスワード無しでこのユーザーのデスクトップを使える**（画面もロックしない）
> - この節の手順 2 の後、ログインのキーリングは**暗号化されずに**保存される。RDP のパスワードも、ブラウザやネットワークの設定がキーリングに入れたパスワードも、`~/.local/share/keyrings/login.keyring` に平文で残る

1. GDM の自動ログインを、このユーザーで有効にする。

   ```bash
   {
     if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。共有するデスクトップの端末で貼り直す' >&2
     elif grep -q '^AutomaticLogin' /etc/gdm/custom.conf; then echo '中断: /etc/gdm/custom.conf に AutomaticLogin の行が既にある。中身を確かめる' >&2
     else sudo sed -i "/^\[daemon\]$/a AutomaticLoginEnable=True\nAutomaticLogin=${USER}" /etc/gdm/custom.conf
     fi
     grep -A2 '^\[daemon\]' /etc/gdm/custom.conf
   }
   ```

   - `[daemon]` の次に `AutomaticLoginEnable=True` と `AutomaticLogin=<USER>` の 2 行が出ればよい
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: /etc/gdm/custom.conf</summary>

   - 設定アプリの「ユーザー」→「自動ログイン」をオンにしたときと同じ 2 つのキー（GNOME のシステム管理者ガイドの「Configure automatic login」）
   - コンテナの既定の `/etc/gdm/custom.conf`（gdm 47.0-24.el10_2）には `[daemon]` の節があり、中は注釈の行だけだった。`sed` はその直後に 2 行を足す
   - 既に `AutomaticLogin` の行がある（設定アプリで自動ログインを入れた・別のユーザーになっている）ときは、何も書かずに止める
   - `/etc/pam.d/gdm-autologin` にも `pam_gnome_keyring.so` があり、キーリングのデーモンは起動するが、パスワードが無いので開けられない

   </details>

1. ログインのキーリングのパスワードを空にする（今のパスワードを聞かれる）。

   ```bash
   python3 - <<'PY'
   import getpass
   from gi.repository import Gio, GLib
   bus = Gio.bus_get_sync(Gio.BusType.SESSION)
   def call(method, iface, args, rtype=None):
       return bus.call_sync('org.freedesktop.secrets', '/org/freedesktop/secrets', iface, method,
                            args, GLib.VariantType(rtype) if rtype else None,
                            Gio.DBusCallFlags.NONE, -1, None)
   session = call('OpenSession', 'org.freedesktop.Secret.Service',
                  GLib.Variant('(sv)', ('plain', GLib.Variant('s', ''))), '(vo)').unpack()[1]
   old = getpass.getpass('今のログインのパスワード: ')
   secret = lambda s: (session, b'', s.encode(), 'text/plain')
   call('ChangeWithMasterPassword', 'org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface',
        GLib.Variant('(o(oayays)(oayays))', ('/org/freedesktop/secrets/collection/login', secret(old), secret(''))))
   print('ログインのキーリングのパスワードを空にした')
   PY
   ```

   - `今のログインのパスワード:` には、この PC にログインするときのパスワード（ふつうはキーリングのパスワードと同じ）を入れる
   - `ログインのキーリングのパスワードを空にした` と出ればよい
   - `The password was invalid` で終わったら、キーリングのパスワードが違う。何も変わっていないので、この手順を貼り直す
   - 画面から行うなら、「パスワードと鍵」（seahorse。AppStream にある）で「ログイン」のキーリングのパスワードを空に変えても同じ（画面では確かめていない）
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼った行は、パスワードを聞く前に捨てられる）

   <details>
   <summary>補足: キーリングのパスワードを空にする仕組み</summary>

   - GNOME Keyring の D-Bus の `ChangeWithMasterPassword` を、今のパスワードと空のパスワードで呼ぶ。seahorse のパスワードの変更と同じ働き
   - `python3` の `gi`（`python3-gobject-base`）は、firewalld（`python3-firewall`）の依存で入っている
   - パスワードは `getpass` で端末から読むので、画面にも履歴にも残らない
   - コンテナで、パスワードを空にした後の `login.keyring` は、先頭が `GnomeKeyring` のバイナリから `[keyring]` で始まる平文に変わり、RDP のパスワードがそのまま読めた
   - キーリングのデーモンをパスワード無しで起こし直しても（自動ログインと同じ条件）、デスクトップ共有が資格情報を読めて、接続できた。空にする前は `[RDP] Credentials are not set, denying client` で断られた
   - 自動ログインで開かないキーリングを開ける方法には、ほかに「パスワードをファイルに置いて、ログインの後に開ける」があるが、平文で置くのは同じなので採らなかった

   </details>

1. キーリングが平文で保存されたことを確かめる。

   ```bash
   head -c 9 ~/.local/share/keyrings/login.keyring; echo
   ```

   - `[keyring]` と出ればよい
   - `GnomeKeyring` と出たら、まだ暗号化されている。この節の手順 2 を貼り直す

1. 再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - 起動すると、ログイン画面を出さずにこのユーザーでログインする。PC の前では何もしない

1. 別のマシンから、[手順 9](#実施手順) と同じようにつなぐ。

   - PC に触らずにつながれば、この節は終わり
   - 断られたら、PC に SSH で入って `journalctl --user -u gnome-remote-desktop.service -b` を見る（`Credentials are not set` なら、キーリングが開いていない）

1. 元に戻すときは、自動ログインの 2 行を消す。

   ```bash
   {
     sudo sed -i '/^AutomaticLoginEnable=True$/d; /^AutomaticLogin=/d' /etc/gdm/custom.conf
     grep -A2 '^\[daemon\]' /etc/gdm/custom.conf
   }
   ```

   - `[daemon]` の次が注釈の行に戻ればよい
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. 元に戻すときは、ログインのキーリングにパスワードを付け直す（新しいパスワードを 2 回聞かれる）。

   ```bash
   python3 - <<'PY'
   import getpass, sys
   from gi.repository import Gio, GLib
   bus = Gio.bus_get_sync(Gio.BusType.SESSION)
   def call(method, iface, args, rtype=None):
       return bus.call_sync('org.freedesktop.secrets', '/org/freedesktop/secrets', iface, method,
                            args, GLib.VariantType(rtype) if rtype else None,
                            Gio.DBusCallFlags.NONE, -1, None)
   session = call('OpenSession', 'org.freedesktop.Secret.Service',
                  GLib.Variant('(sv)', ('plain', GLib.Variant('s', ''))), '(vo)').unpack()[1]
   new = getpass.getpass('新しいパスワード（ログインのパスワードと同じにする）: ')
   if not new or new != getpass.getpass('もう一度: '):
       sys.exit('中断: 空か、2 回の入力が違う')
   secret = lambda s: (session, b'', s.encode(), 'text/plain')
   call('ChangeWithMasterPassword', 'org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface',
        GLib.Variant('(o(oayays)(oayays))', ('/org/freedesktop/secrets/collection/login', secret(''), secret(new))))
   print('ログインのキーリングにパスワードを付けた')
   PY
   ```

   - **ログインのパスワードと同じ**にする（違うと、ログインしたときにキーリングが開かない）
   - `ログインのキーリングにパスワードを付けた` と出ればよい
   - `head -c 12 ~/.local/share/keyrings/login.keyring; echo` で `GnomeKeyring` と出れば、暗号化に戻っている

---

## 見るだけにする（任意）

- 接続した側に画面を見せるだけにして、マウスとキーボードを受け付けないようにする節（GNOME の既定の状態）

1. 見るだけにする。

   ```bash
   grdctl rdp enable-view-only
   grdctl status | grep 'View-only'
   ```

   - `View-only: yes` と出ればよい
   - 次の接続から効く（デーモンを起動し直さなくてよい）

   <details>
   <summary>補足: 切り替えの効き目</summary>

   - コンテナでは、`enable-view-only` の後の接続で、クライアントの上でポインタを動かしても PC のポインタは動かなかった（8 回とも）
   - `disable-view-only` に戻した後は、起動し直さなくても、次の接続からポインタが届いた（3 回とも）
   - ただし、この試験の仕掛け（ヘッドレスの GNOME Shell の上の FreeRDP）は、`View-only: no` のまま設定を変えずに続けた接続でも、届かない回があった

   </details>

1. 元に戻すときは、操作も受け付けるようにする。

   ```bash
   grdctl rdp disable-view-only
   grdctl status | grep 'View-only'
   ```

   - `View-only: no` と出ればよい

---

## 接続元を LAN に絞る（任意）

- **接続元を制限しないなら、この節は不要**
- [手順 6](#実施手順) は、public ゾーンに属するすべての NIC で `RDP_PORT` の TCP を開く
- 手順 1 の変数を設定したシェルで貼る

1. LAN に絞るなら、送信元サブネットを入れ、ポートの開放を rich rule に置き換える。

   ```bash
   LAN_SUBNET=192.168.10.0/24           # ← 自分の値に書き換える。<LAN_SUBNET>
   ```

   ```bash
   if [ -z "${LAN_SUBNET}" ] || [ -z "${RDP_PORT}" ]; then echo '中断: LAN_SUBNET か、手順 1 の RDP_PORT が空のまま。値を入れて貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=${RDP_PORT} protocol=tcp accept"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   sudo firewall-cmd --list-rich-rules        # source address と port に実際の値が入っていることを確認する
   fi
   ```

   - `success` が 3 行出て、`--list-ports` に `<RDP_PORT>/tcp` が無く、rich rule に `<LAN_SUBNET>` と `<RDP_PORT>` が入っていればよい
   - rich rule は**二重引用符**で囲む。単一引用符だと変数が展開されない（[gnome-remote-desktop.md の同じ節](gnome-remote-desktop.md#接続元を-lan-に絞る任意)）

---

## 後からリモートログインを有効にしたとき

- デスクトップ共有を 3389/tcp で使っている PC で、後から[リモートログイン](gnome-remote-desktop.md)を有効にしたときの節
- リモートログインのデーモンが 3389/tcp で待ち受けると、デスクトップ共有は待ち受けを止める（[手順 7](#実施手順) の補足）。デスクトップ共有を 3390/tcp に移す
- [手順 1](#実施手順) の 2 つのブロックを貼り直したシェルで貼る（リモートログインのデーモンが有効なので、`RDP_PORT` が `3390` になる）
- 接続元を LAN に絞っている PC（[接続元を LAN に絞る](#接続元を-lan-に絞る任意)）では確かめていない

1. デスクトップ共有のポートを変え、デーモンを起動し直す。

   ```bash
   if [ "${RDP_PORT}" != 3390 ]; then echo '中断: RDP_PORT が 3390 ではない。リモートログインを有効にしてから、手順 1 の 2 つのブロックを貼り直す' >&2; else
   grdctl rdp set-port "${RDP_PORT}"
   systemctl --user restart gnome-remote-desktop.service
   fi
   ```

   - 何も表示されなければよい。起動し直すと、つながっているクライアントは切れる
   - `Warning: The unit file, source configuration file or drop-ins of gnome-remote-desktop.service changed on disk.` が出ても害は無い（この手順の補足）

   <details>
   <summary>補足: 起動し直す理由と警告</summary>

   - コンテナでは、待ち受けを止めた後のデーモンは、`set-port` でポートを変えただけでは待ち受けなかった。起動し直すと 3390/tcp で待ち受けた
   - 警告は、`grdctl rdp enable`（手順 5）が unit を enable した後に、ユーザーの systemd に読み直させていないため。`systemctl --user daemon-reload` を実行すれば消える

   </details>

1. ファイアウォールで 3390/tcp を開け、デスクトップ共有のために開けた 3389/tcp を閉じる。

   ```bash
   if [ "${RDP_PORT}" != 3390 ]; then echo '中断: RDP_PORT が 3390 ではない。手順 1 の 2 つのブロックを貼り直す' >&2; else
   sudo firewall-cmd --permanent --add-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --permanent --remove-port=3389/tcp
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   sudo firewall-cmd --list-services
   fi
   ```

   - `success` が 3 行出て、`--list-ports` が `3390/tcp`、`--list-services` に `rdp` があればよい（3389/tcp はリモートログインの `rdp` サービスで開いている）
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. 両方のデーモンが待ち受けているかを確かめる。

   ```bash
   grdctl status | grep 'Port:'
   ss -Hlnt '( sport = :3389 or sport = :3390 )'
   ```

   - `Port: 3390` と、`0.0.0.0:3389` と `0.0.0.0:3390` の `LISTEN` の 2 行が出ればよい
   - クライアントは、デスクトップ共有には `<SERVER_IP>:3390`、リモートログインには `<SERVER_IP>:3389` でつなぐ

---

## ロールバック

- 手順 1 の変数を設定したシェルで、上から順に貼る
- [自動ログインで使う](#自動ログインで使う任意)を行ったなら、先にその節の手順 6・7 で戻す
- 設定アプリも同じ GSettings を読むので、設定アプリのデスクトップ共有もオフに戻るはず（画面では確かめていない）

1. ファイアウォールで開けたポートを閉じる。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: 手順 1 の RDP_PORT が空のまま。手順 1 を貼り直す' >&2; else
   grdctl status | grep 'Port:'
   sudo firewall-cmd --permanent --remove-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   fi
   ```

   - `Port: <RDP_PORT>` と `success` が 2 行出て、`--list-ports` に `<RDP_PORT>/tcp` が無ければよい
   - `Port:` の値と `RDP_PORT` が違うなら、`RDP_PORT` を `Port:` の値にしてから貼り直す
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. [接続元を LAN に絞る](#接続元を-lan-に絞る任意)を行ったときは（この節の手順 1 の代わりに）、rich rule を消す。

   ```bash
   if [ -z "${LAN_SUBNET}" ] || [ -z "${RDP_PORT}" ]; then echo '中断: LAN_SUBNET か、手順 1 の RDP_PORT が空のまま。値を入れて貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=${RDP_PORT} protocol=tcp accept"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-rich-rules
   fi
   ```

   - `LAN_SUBNET` は、[接続元を LAN に絞る](#接続元を-lan-に絞る任意)の手順 1 の 1 つ目のブロックを貼り直して入れる
   - `success` が 2 行出て、その rich rule が消えていればよい
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. デスクトップ共有を止め、資格情報と設定を消す。

   ```bash
   grdctl rdp disable
   grdctl rdp clear-credentials
   gsettings reset-recursively org.gnome.desktop.remote-desktop.rdp
   systemctl --user is-enabled gnome-remote-desktop.service
   grdctl status
   ```

   - `disabled` と出て、`grdctl status` が `Unit status: inactive`・`Status: disabled`・`Username: (empty)` になればよい
   - `grdctl status` は、証明書を外したので `RDP server certificate is invalid.` も出す

1. 証明書と鍵を消す。

   ```bash
   rm -rf ~/.local/share/gnome-remote-desktop/certificates
   rmdir ~/.local/share/gnome-remote-desktop
   ```

   - `rmdir` が `Directory not empty` で失敗したら、ほかのファイル（ヘッドレスの設定など）があるので、そのまま残す
   - 手順 8 の `~/rdp_tls_probe.py` が残っていれば `rm ~/rdp_tls_probe.py` で消す

---

## 補足

### 対象と検証環境

- **方式**: デスクトップ共有（ユーザーのデーモン。`grdctl` に `--system` を付けない）。PC の画面でログインしているセッションをそのまま見せる
- **TLS 証明書**: openssl で生成（追加パッケージ不要）
- **状態**: x86_64 のコンテナのみで検証（2026-09-30）
  - 通したもの: 実施手順 1〜8 を文書のブロックのまま、ブラケットペースト無しで擬似端末に貼った。手順 9 は、別のコンテナの FreeRDP でつないで確かめた
  - リモートログインの無い PC（3389）と有る PC（3390）の両方で通した
  - 任意節（自動ログイン・見るだけ・LAN に絞る・後からリモートログインを有効にしたとき）とロールバックも、同じ形で通した。自動ログインの節の手順 4（再起動）は、キーリングのデーモンをパスワード無しで起こし直すことで代えた
  - 確かめていないこと: 実機・PC の画面（上部バーの表示）・画面ロックで止まること・GDM の自動ログインそのもの・設定アプリ・Windows や Android のクライアント・aarch64（[付録](#付録-コンテナでの検証記録2026-09-30)）

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-30 |
| 環境 | クラウドホスト上の Docker（`--privileged`、systemd を PID 1。ホストは cgroup v1） |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64 |
| `gnome-remote-desktop` | 49.3-4.el10_2 |
| `gnome-shell` / `mutter` | 49.4-9.el10_2.alma.1 / 49.4-4.el10_2（`gnome-shell --headless --virtual-monitor 1280x800`） |
| `gnome-keyring` | 42.1-20.el10 |
| `gdm` | 47.0-24.el10_2（`custom.conf` の書き換えと、リモートログインのデーモンの待ち受けにだけ使った） |
| `freerdp`（クライアント） | 3.10.3-12.el10_2.11（別のコンテナ。そちらもヘッドレスの GNOME Shell の Xwayland で動かした） |
| OpenSSL | 3.5.8 |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${SERVER_IP}` | クライアントが接続に使う PC の IP アドレス | `192.168.10.100` |
> | `${SERVER_NAME}` / `${SERVER_FQDN}` | PC のホスト名 / FQDN（`hostname` / `hostname -f` から自動で入る） | `my-pc` / `my-pc.lan` |
> | `${RDP_PORT}` | デスクトップ共有が待ち受けるポート（リモートログインのデーモンが有効なら 3390、無ければ 3389。自動で入る） | `3389` |
> | `${LAN_SUBNET}` | LAN のサブネット。[接続元を LAN に絞る](#接続元を-lan-に絞る任意)ときだけ、その節で設定する | `192.168.10.0/24` |
>
> 出力例・ログの中の値は `<HOSTNAME>` / `<HOSTNAME>.<DOMAIN>` / `<SERVER_IP>` / `<RDP_PORT>` / `<USER>`（OS のアカウント名）/ `<FINGERPRINT>`（証明書の TLS fingerprint）のプレースホルダで書いてある。`<...>` を含むコマンドは bash のコードブロックには置かない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

コンテナで、手順の前に確かめた状態（Workstation で入れた PC と同じものが入っている前提）:

| 項目 | 状態 |
|---|---|
| `gnome-remote-desktop` | インストール済み（`/usr/bin/grdctl` あり） |
| デスクトップ共有 | 無効（`grdctl status` が `Status: disabled`・`View-only: yes`・`Negotiate port: yes`・`Username: (empty)`） |
| ユーザーの `gnome-remote-desktop.service` | `disabled` / `inactive` |
| ログインのキーリング | パスワード付き（ログインで開いている） |
| firewalld | active、default zone = `public`、3389/tcp・3390/tcp 未開放 |
| `/etc/gdm/custom.conf` | `[daemon]` の中は注釈の行だけ（自動ログイン無し） |

### 選択した方針

- **デスクトップ共有**（ユーザーのデーモン）— PC の画面でログインしているセッションを、そのまま RDP で見せて操作させる
  - リモートログイン（[gnome-remote-desktop.md](gnome-remote-desktop.md)）は、GDM で**新しい**セッションを作る。画面の前の作業を続きから触りたいときは、こちらを使う
- **grdctl で設定する** — 設定アプリの「システム」→「リモートデスクトップ」→「デスクトップ共有」と同じ GSettings とキーリングに書く
  - 貼るだけで同じ状態になり、証明書に SAN を付けられる
- **証明書は openssl で作り、設定アプリと同じ場所に置く** — SAN に IP を入れる理由は gnome-remote-desktop.md と同じ。同じ場所なら、設定アプリで切り替えても作り直されない
- **ポートを固定し、ポートのネゴシエーションを切る** — 既定では、ポートが使われていると次の 10 個を順に試すので、ファイアウォールで開けたポートと食い違うことがある
- **操作も受け付ける**（`disable-view-only`）— 依頼に合わせた。見せるだけにする節を後ろに置いた
- **自動ログインで使うときは、キーリングのパスワードを空にする**（任意節）
  - デスクトップ共有の資格情報はキーリングにしか置けない（gnome-remote-desktop 49.3 の `grd-settings.c` の `create_credentials()` が、画面共有のモードでは libsecret だけを使う）
  - 自動ログインではキーリングを開けるパスワードが無いので、キーリングを暗号化しないしかない
  - 採らなかった案: パスワードをファイルに置いてログインの後に開ける（平文で置くのと同じ）
  - もう 1 つの案: ディスクを LUKS で暗号化している PC では、`/etc/pam.d/gdm-autologin` の先頭の `pam_gdm.so` が、起動のときに入れたディスクのパスワードでキーリングを開けようとする。ディスクのパスワード・ログインのパスワード・キーリングのパスワードが同じときだけ効き、起動のときに PC の前でディスクのパスワードを入れる必要がある（確かめていない）
- 自動ログインを使わずに、PC の前で誰もログインしていないときにも使うなら、リモートログインを使う

### 完了時点の状態

コンテナでの、実施手順の後の出力（リモートログインのデーモンが無い PC。`RDP_PORT` = 3389）:

```
$ grdctl status
Overall:
	Unit status: active
RDP:
	Status: enabled
	Port: 3389
	TLS certificate: /home/<USER>/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
	TLS fingerprint: <FINGERPRINT>
	TLS key: /home/<USER>/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
	View-only: no
	Negotiate port: no
	Username: (hidden)
	Password: (hidden)
$ systemctl --user is-enabled gnome-remote-desktop.service
enabled
$ ss -Hlnt "sport = :${RDP_PORT}"
LISTEN 0      5      0.0.0.0:3389 0.0.0.0:*
$ sudo firewall-cmd --list-ports
3389/tcp
```

journal（`journalctl --user -u gnome-remote-desktop.service`）:

```
gnome-remote-de[<PID>]: RDP server started
```

リモートログインのデーモンが有効な PC（`RDP_PORT` = 3390）では、`Port: 3390` になり、2 つのデーモンが待ち受ける:

```
$ ss -Hlntp '( sport = :3389 or sport = :3390 )'     # root で実行
LISTEN 0      5      0.0.0.0:3390 0.0.0.0:* users:(("gnome-remote-de",pid=<PID>,fd=10))
LISTEN 0      5      0.0.0.0:3389 0.0.0.0:* users:(("gnome-remote-de",pid=<PID>,fd=9))
$ sudo firewall-cmd --list-services; sudo firewall-cmd --list-ports
cockpit dhcpv6-client rdp ssh
3390/tcp
```

### 注意点

- **画面がロックされると、共有は止まる**
  - GNOME Shell は、ヘッドレスでないセッションがロック画面になると、リモートアクセスを止める（gnome-shell の `js/ui/main.js` の `_sessionUpdated()`。つながっているクライアントも切れるという報告がある）
  - 検証はヘッドレスの GNOME Shell で行ったので、この動きは確かめていない（ヘッドレスは対象外）
  - 放置でロックさせないのは [gnome-power.md 手順 1・2](gnome-power.md#実施手順)。手でロックしたときは、PC の前でロックを解くまで使えない
- **ログアウトすると、共有も終わるはず**。デーモンはそのユーザーのセッションと一緒に動く（unit の `WantedBy=gnome-session.target`）。ログアウトとログインし直しは確かめていない
- **PC が眠ると、つなげない**。自動サスペンドを止めるのも [gnome-power.md](gnome-power.md)
- **後からリモートログインを有効にしたとき**: リモートログインのデーモンが 3389/tcp を取り、デスクトップ共有は待ち受けを止める（手順 7 の補足）。`grdctl status` では見分けられないので、[後からリモートログインを有効にしたとき](#後からリモートログインを有効にしたとき)でポートを 3390 に移す
- **資格情報はログインのキーリングにある** — キーリングを消して作り直したときは、手順 4 を貼り直す
- **自己署名証明書**: クライアントは初回に証明書の確認を出す。証明書を作り直したら、クライアントで保存済みの証明書を消すか、変更の警告を承認する（gnome-remote-desktop.md の注意点と同じ）
- **自動ログイン**: RHEL 10 の STIG（RHEL-10-700720）は、GDM の自動ログインを無効にすることを求めている。STIG に従うホストでは、自動ログインの節は使えない

### 参照

- [Chapter 1. Remotely accessing the desktop — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/remotely-accessing-the-desktop)
- [GNOME/gnome-remote-desktop README.md](https://github.com/GNOME/gnome-remote-desktop/blob/master/README.md)（Desktop Sharing の節）
- [gnome-remote-desktop 49.3 の src/grd-settings.c](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/blob/49.3/src/grd-settings.c)（資格情報の置き場所）
- [gnome-shell の js/ui/main.js](https://gitlab.gnome.org/GNOME/gnome-shell/-/blob/main/js/ui/main.js)（ロック画面でリモートアクセスを止める）
- [GNOME System Administration Guide — Configure automatic login](https://help.gnome.org/admin/system-admin-guide/stable/login-automatic.html.en)

---

### 付録: コンテナでの検証記録（2026-09-30）

#### 環境の作り方

- クラウドホストの Docker で、`quay.io/almalinuxorg/10-init` に GNOME Shell・gnome-remote-desktop・gnome-keyring・PipeWire・FreeRDP・firewalld・gdm などを入れたイメージを作り、`--privileged` で systemd を PID 1 にして立てた（ホストは cgroup v1。systemd 257 は `Tainted: cgroupsv1` で動いた）
- イメージは `systemd-logind` を mask しているので外し、試験用のユーザー（`wheel` の一員、パスワード付き）に `loginctl enable-linger` を付けて、ユーザーの systemd とセッションバスを用意した（linger は検証の都合。手順書では要らない）
- 「PC の画面でログインしたセッション」の代わりに、そのユーザーで次を動かした
  - ログインと同じ形でキーリングを開ける: パスワードを標準入力に渡して `gnome-keyring-daemon --daemonize --login`、続けて `gnome-keyring-daemon --start --components=secrets,pkcs11`（`pam_gnome_keyring` がログインで行うのに近い形）
  - `systemctl --user start pipewire.service wireplumber.service`
  - `systemd-run --user` で `gnome-shell --headless --unsafe-mode --virtual-monitor 1280x800`（`--unsafe-mode` は、ポインタの位置を `org.gnome.Shell.Eval` で読むためだけに付けた）
- 手順書のブロックは、`bash -i` を擬似端末で動かし、`bind 'set enable-bracketed-paste off'` にしてから、ブロックの中身をそのまま書き込んだ（ブラケットペースト無し）。対話入力（`Username:`・`Password:`・`[sudo] password for <USER>:`・`getpass` のプロンプト）は、プロンプトが出てから答えた
- 手順 1 の `SERVER_IP` だけを、コンテナの IP に書き換えた
- クライアントは、同じイメージの別のコンテナ（同じ Docker のネットワーク）に同じ形でヘッドレスの GNOME Shell を立て、その Xwayland の上で `xfreerdp` を動かした
- リモートログインのデーモンは、[gnome-remote-desktop.md](gnome-remote-desktop.md) の手順 2〜5 と同じ設定を root で入れ、`systemctl start gdm` で GDM を起こした（GDM がいないと、システムのデーモンは待ち受けなかった）

#### 確かめたこと

- **手順 1〜8**: リモートログインの無い PC（`RDP_PORT` = 3389）と、リモートログインの有る PC（`RDP_PORT` = 3390）で 1 回ずつ通した。どちらも、プローブの fingerprint と `grdctl status` の `TLS fingerprint` が一致した
- **手順 2 の中断**: 証明書がある状態でもう一度貼ると `中断: 証明書か鍵が既にある。…` で止まり、ファイルは変わらなかった。`hostname` の無いイメージ（検証の初回）では `SERVER_NAME` が空になり、`中断: 手順 1 の変数が空のまま。…` で止まった
- **手順 5 と手順 7 を分けた理由**: 初めの版は、`grdctl rdp enable` の直後に `grdctl status` と `ss` を並べていた。`Unit status: activating` で、`ss` は何も出さなかった
- **手順 9**: 別のコンテナから、証明書の確認（`Thumbprint:` が `TLS fingerprint` と同じ）、違うパスワードでの拒否（`SEC_E_MESSAGE_ALTERED`）、正しいパスワードでの接続（Mutter の ScreenCast の Session と Stream ができる）、ポインタが PC に届くこと、を確かめた
- **ポインタの確かめ方**: クライアントのコンテナで、Mutter の RemoteDesktop の API でポインタを FreeRDP のウィンドウの上へ動かし、PC 側のポインタの位置を `global.get_pointer()` で読んだ。操作を受け付けると、PC のポインタが右下の隅から `500,315` 付近へ動いた
  - `View-only: yes` のときは 8 回とも動かなかった。`View-only: no` のときは、設定を変えずに続けた接続でも、動かない回があった（試験の仕掛けの不安定さ。原因は突き止めていない）
- **資格情報の変更**: デーモンが動いたまま `grdctl rdp set-credentials` で変えると、次の接続から新しいパスワードだけが通った
- **キーリングが開いていないとき**: キーリングのデーモンをパスワード無しで起こし直し、デスクトップ共有のデーモンも起こし直すと、`grdctl status` が `Username: (empty)` になり、接続は `[RDP] Credentials are not set, denying client` で断られた。GNOME Shell にキーリングのパスワードを聞くダイアログは出なかった
- **自動ログインの節**: その節の手順 1〜3・6・7 を貼った。手順 4（再起動）の代わりに、キーリングのデーモンをパスワード無しで起こし直し、デスクトップ共有のデーモンも起こし直してから、別のコンテナからつないで通った
  - 手順 2 に違うパスワードを入れると `The password was invalid` で終わり、キーリングは変わらなかった
  - 手順 7 は、2 回の入力が違う・空のときに `中断:` で止まった。パスワードが付いた後にもう一度貼ると `The password was invalid` で終わった
  - 手順 6 は、`sudo` のパスワードを聞かれている間に手順 7 のブロックを続けて貼った回があった。手順 7 の行は `sudo` のパスワードとして食われて `Sorry, try again.` になり、`{ }` の中の `sed` は、2 回目のパスワードで 1 度だけ実行された
- **後からリモートログインを有効にしたときの節**: デスクトップ共有が 3389/tcp で待ち受けている PC で GDM とシステムのデーモンを起こすと、デスクトップ共有のデーモンは `RDP server stopped` の後に `Failed to start RDP server: Error binding to address 0.0.0.0:3389: Address already in use` を出した。その節の手順 1〜3 で、3390/tcp と 3389/tcp の両方が待ち受け、それぞれの資格情報で通った
- **ロールバック**: 接続元を LAN に絞った PC（ロールバックの手順 2・3・4）と、絞っていない PC（ロールバックの手順 1・3・4）で通した。GSettings は既定値に戻り、キーリングの資格情報とユーザーの unit のリンクも消えた。リモートログインのデーモンと `rdp` サービスは残った

#### 未確認事項

- 実機・aarch64・PC の画面（上部バーの表示）
- 画面ロックで共有が止まること（ヘッドレスの GNOME Shell は対象外）
- GDM の自動ログインそのもの・`pam_gnome_keyring` がパスワード無しでキーリングのデーモンを起こすときの実際の動き
- 設定アプリの「リモートデスクトップ」の画面と、このコマンドの設定との食い違い
- Windows のリモート デスクトップ接続・Android のクライアント・WireGuard 越しの接続
