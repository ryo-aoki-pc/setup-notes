# GNOME のヘッドレスのセッションの手順（モニターの無い PC のデスクトップに RDP でつなぐ）

## 実施手順

> [!IMPORTANT]
> - **セッションを使うユーザー本人のシェル（SSH でよい）で貼る**。`sudo -i` / `su -` したシェルでは貼らない（セッションと RDP の設定は、貼ったユーザーのものになるため）
> - 前提は [gnome-power.md 手順 1・2](gnome-power.md#実施手順)（サスペンドできる PC では、同書の手順 3・4 も）。ヘッドレスのセッションでも、既定のままでは 15 分の無操作で PC をサスペンドしようとする
> - **手順 5 は RDP のユーザー名とパスワードの対話入力がある**。入力し終えてから次の手順を貼る
> - 手順 10（クライアントからの接続）だけ別のマシンで行う
> - [リモートログイン](gnome-remote-desktop.md)（GDM で認証し、新しいセッションを作るか既存のセッションへ引き渡す方式）と同じ PC でも使える。そのときのポートは、手順 1 で自動で 3390 になる

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 接続元を絞るなら[接続元を LAN に絞る（任意）](#接続元を-lan-に絞る任意)。戻すときは[ロールバック](#ロールバック)

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
   - `USER` が `root` なら、ここで止めて、セッションを使うユーザーのシェルで貼り直す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**、手順 1 の 2 つのブロックを貼り直してから先へ進む

   <details>
   <summary>補足: 変数について</summary>

   - `SERVER_IP`・`SERVER_NAME`・`SERVER_FQDN` は、[gnome-remote-desktop.md](gnome-remote-desktop.md) の手順 1 と同じ。証明書の SAN に入れる（手順 3）
   - `RDP_PORT` の判定に使う `systemctl is-enabled gnome-remote-desktop.service` は、`--user` を付けないのでシステムの unit を見る
   - リモートログインのデーモンは 3389/tcp で待ち受けるので、同じ PC ではヘッドレスのセッションの RDP を 3390/tcp にする

   </details>

1. ヘッドレスのセッションを有効にして起動し、セッションができたかを確かめる。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。セッションを使うユーザーのシェルで貼り直す' >&2
   else
     sudo systemctl enable --now "gnome-headless-session@${USER}.service"
     for i in $(seq 1 30); do
       busctl --user status org.gnome.Mutter.ScreenCast >/dev/null 2>&1 &&
         [ -n "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"')" ] && break
       sleep 1
     done
     loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"'
     pgrep -a -u "${USER}" -x gnome-shell
   fi
   ```

   - `Created symlink '/etc/systemd/system/graphical.target.wants/gnome-headless-session@<USER>.service' → '/usr/lib/systemd/system/gnome-headless-session@.service'.` と出る
   - PC を起動するたびに、このセッションも起動する
   - 続いて `<SESSION_ID> <UID> <USER> - <PID> user headless no -` の形の行と、`<PID> /usr/bin/gnome-shell` が出ればよい
   - `for` の行で、gnome-shell のバス名と `loginctl` のセッションの両方が出るまで、30 秒まで待つ。バス名だけ先に出ることがあった（クリーンインストールした VM で確認）
   - 何も出ないときは、`systemctl status "gnome-headless-session@${USER}.service"` と `systemctl --user status org.gnome.Shell@wayland.service` を見る

   <details>
   <summary>補足: gnome-headless-session@.service と、セッションの見分け方</summary>

   **gnome-headless-session@.service**:

   - gdm の unit。`gdm` ユーザーで `gdm-new-session <USER> --headless` を動かし、GDM に、モニターの無いセッションを作らせる（RHEL 10 の文書の「1.4 headless server for a single user」と同じ unit）
   - できるセッションは、`loginctl` で `Class=user`・`Type=wayland`・`TTY=headless`・`Remote=yes`・`Service=gdm-autologin`・seat 無し
   - PAM は `gdm-autologin` で、パスワードを使わない。ログインのキーリングは開かない（[注意点](#注意点)）
   - `WantedBy=graphical.target` なので、`enable` で起動時にも作られる。`Requires=gdm.service`
   - 起動して 3 秒ほどで gnome-shell が動き、描画には GPU（Raspberry Pi 5 では `/dev/dri/renderD128` の v3d）を使った

   **セッションの見分け方と、モニターが無い間**:

   - `loginctl` の行の `awk` は、このユーザーのヘッドレスのセッションの行だけを出す。ほかのユーザーのヘッドレスのセッションも `TTY` が `headless` になる（検証では、`grep headless` にしていた版が、試験用のユーザーのセッションも数えた）
   - このセッションには、RDP のクライアントがつないでいない間、モニターが 1 枚も無い。アプリはそのまま動き続ける
   - クライアントがつなぐと、そのクライアントの窓の大きさの仮想モニターができ、切ると消える

   </details>

1. 共用する TLS 設定を退避し、証明書と鍵を作る（既にあれば作らない）。

   ```bash
   if [ -z "${SERVER_IP}" ] || [ -z "${SERVER_NAME}" ] || [ -z "${SERVER_FQDN}" ]; then
     echo '中断: 手順 1 の変数が空のまま。手順 1 を貼り直す' >&2
   else
     (
       set -e
       trap 'echo "中断: 手順 3 が失敗した。手順 4 へ進まない" >&2' ERR
       if [ -e ~/.local/state/gnome-headless-session-setup ] || [ -L ~/.local/state/gnome-headless-session-setup ]; then
         if [ -L ~/.local/state/gnome-headless-session-setup ] ||
            [ ! -f ~/.local/state/gnome-headless-session-setup/backup-complete ] ||
            [ ! -f ~/.local/state/gnome-headless-session-setup/tls-cert ] ||
            [ ! -f ~/.local/state/gnome-headless-session-setup/tls-key ]; then
           echo '中断: TLS 設定の退避が不完全。退避内容を確認し、先へ進まない' >&2
           exit 1
         fi
       else
         umask 077
         mkdir -p ~/.local/state
         mkdir ~/.local/state/gnome-headless-session-setup
         dconf read /org/gnome/desktop/remote-desktop/rdp/tls-cert > ~/.local/state/gnome-headless-session-setup/tls-cert
         dconf read /org/gnome/desktop/remote-desktop/rdp/tls-key > ~/.local/state/gnome-headless-session-setup/tls-key
         touch ~/.local/state/gnome-headless-session-setup/backup-complete
       fi
       rm -f ~/.local/state/gnome-headless-session-setup/ready ~/.local/state/gnome-headless-session-setup/restored
       if [ -e ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] || [ -L ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] ||
          [ -e ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ] || [ -L ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ]; then
         if [ ! -s ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] ||
            [ ! -s ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ]; then
           echo '中断: 証明書と鍵の両方が必要。既存ファイルは上書きしていない' >&2
           exit 1
         fi
       else
         mkdir -p ~/.local/share/gnome-remote-desktop/certificates
         touch ~/.local/state/gnome-headless-session-setup/created-certificate
         openssl req -x509 -newkey rsa:2048 -noenc -days 3650 \
           -subj "/CN=${SERVER_NAME}" \
           -addext "subjectAltName=DNS:${SERVER_NAME},DNS:${SERVER_FQDN},DNS:${SERVER_IP},IP:${SERVER_IP}" \
           -addext "extendedKeyUsage=serverAuth" \
           -keyout ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key \
           -out    ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
         chmod 644 ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
         sha256sum ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt \
           ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key > ~/.local/state/gnome-headless-session-setup/created.sha256
       fi
       openssl x509 -in ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt -noout
       openssl pkey -in ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key -passin pass: -noout
       touch ~/.local/state/gnome-headless-session-setup/ready
       ls -l ~/.local/share/gnome-remote-desktop/certificates
       echo 'TLS の退避と証明書の準備が完了'
     )
   fi
   ```

   - 最後に `TLS の退避と証明書の準備が完了` と出れば、手順 4 へ進む
   - 新規生成した場合は `rdp-tls.crt`（`-rw-r--r--`）と `rdp-tls.key`（`-rw-------`）が出る。既存の証明書と鍵は上書きしない
   - 既存の鍵も、この手順で生成するものと同じく、パスフレーズなしで読める必要がある
   - `中断:` が出たら、手順 4 以降へ進まない。[ロールバック](#ロールバック)の手順 3・4 で戻す。生成途中で照合用の記録も作れなかった場合は、ファイルを自動削除せず残す
   - 置き場所は、RHEL 10 の文書の 1.4 と同じ

   <details>
   <summary>補足: 証明書</summary>

   - 中身は [gnome-remote-desktop.md 手順 2](gnome-remote-desktop.md#実施手順) と同じ（SAN に IP を `DNS:` でも入れる理由も同書の補足）。違うのは、自分のホームに自分の所有で作ること
   - RHEL の文書は `winpr-makecert` で作るが、ここでは SAN を付けるために openssl で作る
   - `certificates` のディレクトリは、SELinux のラベルが `home_cert_t` になった。gnome-remote-desktop のユーザーのデーモンは `unconfined_t` で動き、Enforcing のまま読めた
   - TLS のパスはデスクトップ共有と共用なので、最初に dconf の元値を `~/.local/state/gnome-headless-session-setup` に退避する。未設定だったキーは空ファイルになり、ロールバックでは `reset` で戻す
   - 貼り直しても退避は上書きしない。`backup-complete` は退避完了、`ready` は証明書の準備完了、`created-certificate` はこの手順が新規生成したことの目印
   - 新規生成したファイルの SHA-256 も `created.sha256` に保存する。ロールバックでは、中身が変わっていたりリンクへ置き換わっていたりすれば削除しない
   - 既存の証明書を更新する手順ではない。以前の手順で残した `.old` なども、この手順とロールバックでは消さない
   - `set -e` は丸括弧の中だけに効かせ、退避・生成・読み取りのどれかが失敗したら、そのブロックを止める

   </details>

1. `grdctl --headless` で、証明書と鍵・ポートを設定する。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: 手順 1 の RDP_PORT が空のまま。手順 1 を貼り直す' >&2
   elif [ ! -f ~/.local/state/gnome-headless-session-setup/ready ]; then
     echo '中断: 手順 3 が完了していない。TLS 設定は変更しない' >&2
   else
     rm -f ~/.local/state/gnome-headless-session-setup/restored &&
     grdctl --headless rdp set-tls-cert ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt &&
     grdctl --headless rdp set-tls-key ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key &&
     grdctl --headless rdp set-port "${RDP_PORT}" &&
     grdctl --headless rdp disable-port-negotiation
   fi
   ```

   - コマンドごとに `Init TPM credentials failed because No TPM device found, using GKeyFile as fallback.` が出る（TPM の無い PC。この手順の補足）
   - 初めて設定するときだけ、`[x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` が 1 回ずつ出る。設定する前の空の値を読んだもので、害は無い

   <details>
   <summary>補足: grdctl --headless</summary>

   - `--headless` を付けた `grdctl` は、ヘッドレスのセッションのデーモン（`gnome-remote-desktop-headless.service`）の設定を変える
   - 書き先は dconf。ポートなどは `/org/gnome/desktop/remote-desktop/rdp/headless/`、証明書と鍵は、デスクトップ共有と同じ `/org/gnome/desktop/remote-desktop/rdp/` に入った
   - 資格情報（手順 5）は、TPM があれば TPM に、無ければ `~/.local/share/gnome-remote-desktop/credentials.ini`（GKeyFile）に置く。TPM の無い Raspberry Pi 5 では、`grdctl --headless` のどのコマンドも TPM のメッセージを出した
   - `disable-port-negotiation` は、指定したポートが使われていたときに、次のポートを順に試すのを止める。ポートが勝手に変わって、手順 7 で開けたポートと食い違うのを防ぐ

   </details>

1. RDP のユーザー名とパスワードを、引数なしで対話入力する。

   ```bash
   grdctl --headless rdp set-credentials
   ```

   - ユーザー名とパスワードを聞かれる。クライアントが接続するときに入れるもので、OS のアカウントと違ってよい
   - 引数なしで打つのは、パスワードをシェルの履歴に残さないため
   - **次の手順は、ユーザー名とパスワードを入力し終えてから貼る**（続けて貼ると入力として食われる）

   <details>
   <summary>補足: 資格情報の置き場所</summary>

   - TPM の無い PC では、`~/.local/share/gnome-remote-desktop/credentials.ini` に入る（0600。暗号化はされていない）
   - このファイルは、`grdctl --headless status` を 1 度実行しただけでも、空のまま 0644 でできた。資格情報を書くと 0600 になった
   - パスワードを変えるときも、この手順を貼り直す

   </details>

1. RDP を有効にする。

   ```bash
   grdctl --headless rdp enable
   systemctl --user is-enabled gnome-remote-desktop-headless.service
   ```

   - `enabled` と出ればよい
   - デーモンが待ち受けたかは、手順 8 で確かめる

   <details>
   <summary>補足: grdctl --headless rdp enable</summary>

   - `grdctl --headless rdp enable` は、`/org/gnome/desktop/remote-desktop/rdp/headless/enable` を true にし、ユーザーの unit `gnome-remote-desktop-headless.service` を enable して起動する（`~/.config/systemd/user/gnome-session.target.wants/` にリンクができる）。RHEL の文書の `systemctl --user enable --now gnome-remote-desktop-headless.service` は要らなかった
   - unit は `WantedBy=gnome-session.target` なので、ヘッドレスのセッションと一緒に起動する

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

   <details>
   <summary>補足: ファイアウォール</summary>

   - firewalld の定義済みサービス `rdp` は 3389/tcp だけなので、ポートで開ける
   - public ゾーンで開けるので、public ゾーンに属するすべての NIC で開く（gnome-remote-desktop.md と同じ）

   </details>

1. デーモンが待ち受けているかを確かめる。

   ```bash
   grdctl --headless status
   ss -Hlnt "sport = :${RDP_PORT:?手順 1 の RDP_PORT が空のまま}"
   ```

   - `grdctl --headless status` で、`Unit status: active`・`Status: enabled`・`Port: <RDP_PORT>`・`Negotiate port: no`・`Username: (hidden)` を確かめる
   - `TLS fingerprint` の値を控えておく（手順 9 と手順 10 で使う）
   - `ss` が `LISTEN … *:<RDP_PORT> …` の 1 行を出せばよい

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
   /usr/bin/python3 ~/rdp_tls_probe.py "${SERVER_IP}" "${RDP_PORT}"
   grdctl --headless status 2>/dev/null | grep 'TLS fingerprint'
   ```

   - 次の 3 つがそろえばよい
     - `selectedProtocol=0x2` でネゴシエーションが成立する
     - `fingerprint:` の行が、最後の `TLS fingerprint:` の行と**完全一致**する
     - SAN に、接続に使う名前が `DNS:` エントリとして含まれている
   - 確認が済んだら `rm ~/rdp_tls_probe.py` で消してよい（この手順書が作る唯一の作業ファイル）

   <details>
   <summary>補足: TLS プローブ</summary>

   - スクリプトは [gnome-remote-desktop.md 手順 10](gnome-remote-desktop.md#実施手順) と同じもの。第 2 引数でポートを渡す
   - `/usr/bin/python3` で動かすのは、Homebrew が PATH の先頭にあるときも、同じ Python にするため（どちらでも動く）

   </details>

1. LAN 内の別のマシンから、RDP クライアントでつなぐ。

   - AlmaLinux 10 の FreeRDP（`freerdp` パッケージ）なら `xfreerdp /v:<SERVER_IP>:<RDP_PORT> /u:<RDP のユーザー名>` の形でつなぐ。Windows なら「リモート デスクトップ接続」で `<SERVER_IP>:<RDP_PORT>` につなぐ
   - `<SERVER_IP>`・`<RDP_PORT>`・`<RDP のユーザー名>` は、手順 1 と手順 5 の値に読み替える
   - 証明書の確認を聞かれたら、表示された Thumbprint が手順 8 の `TLS fingerprint` と同じかを見てから受け入れる
   - FreeRDP は `Domain:` も聞く。空のまま Enter を押す
   - パスワードは手順 5 のもの。通ると、このセッションの GNOME のデスクトップが、クライアントの窓の大きさで出る
   - 切ってつなぎ直すと、同じデスクトップ（開いていたアプリもそのまま）に戻る
   - 問題があれば、PC の端末で `journalctl -b _SYSTEMD_USER_UNIT=gnome-remote-desktop-headless.service` を見る

---

## 接続元を LAN に絞る（任意）

- **接続元を制限しないなら、この節は不要**
- [手順 7](#実施手順) は、public ゾーンに属するすべての NIC で `RDP_PORT` の TCP を開く
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

## ロールバック

- 手順 1 の変数を設定したシェルで、上から順に貼る
- [gnome-power.md](gnome-power.md) で変えた値は残る。戻すなら同書の[ロールバック](gnome-power.md#ロールバック)
- [claude-code-gui.md](claude-code-gui.md) を行ったなら、先に同書の[ロールバック](claude-code-gui.md#ロールバック)で戻す
- この節の手順 3 は共用 TLS 設定を退避時の値に戻し、手順 4 は今回生成した証明書だけを消す。退避後にデスクトップ共有の TLS 設定を別に変えた場合は、先にその設定を控える
- 2026-10-05 より前の手順などで退避が無い場合は、共用 TLS 設定と証明書を保持する。導入前の値に戻すには、別に残した記録が要る

> [!CAUTION]
> **この節の手順 4 で消す証明書の秘密鍵は取り戻せない**。今回生成したものと照合できた場合だけ消し、既存の証明書と鍵は残す。

1. ファイアウォールで開けたポートを閉じる。

   ```bash
   if [ -z "${RDP_PORT}" ]; then echo '中断: 手順 1 の RDP_PORT が空のまま。手順 1 を貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-port="${RDP_PORT}/tcp"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-ports
   fi
   ```

   - `success` が 2 行出て、`--list-ports` に `<RDP_PORT>/tcp` が無ければよい

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

1. RDP とヘッドレス用の資格情報・設定を解除し、共用 TLS 設定を戻す。

   ```bash
   (
     set -e
     trap 'echo "中断: 復元が失敗した。この節の手順 4 へ進まない" >&2' ERR
     if { [ -e ~/.local/state/gnome-headless-session-setup ] || [ -L ~/.local/state/gnome-headless-session-setup ]; } &&
        { [ -L ~/.local/state/gnome-headless-session-setup ] ||
          [ ! -f ~/.local/state/gnome-headless-session-setup/backup-complete ] ||
          [ ! -f ~/.local/state/gnome-headless-session-setup/tls-cert ] ||
          [ ! -f ~/.local/state/gnome-headless-session-setup/tls-key ]; }; then
       echo '中断: TLS 設定の退避が不完全。設定とファイルは変更しない' >&2
       exit 1
     fi
     rm -f ~/.local/state/gnome-headless-session-setup/restored
     grdctl --headless rdp disable
     grdctl --headless rdp clear-credentials
     dconf reset -f /org/gnome/desktop/remote-desktop/rdp/headless/
     if [ -f ~/.local/state/gnome-headless-session-setup/backup-complete ]; then
       for key in tls-cert tls-key; do
         if [ -s ~/.local/state/gnome-headless-session-setup/"${key}" ]; then
           dconf write "/org/gnome/desktop/remote-desktop/rdp/${key}" "$(cat ~/.local/state/gnome-headless-session-setup/"${key}")"
         else
           dconf reset "/org/gnome/desktop/remote-desktop/rdp/${key}"
         fi
       done
       touch ~/.local/state/gnome-headless-session-setup/restored
     else
       echo '退避なし: 共用 TLS 設定と証明書は保持する'
     fi
     systemctl --user is-enabled gnome-remote-desktop-headless.service || true
   )
   ```

   - コマンドごとの TPM のメッセージの後に、`disabled` と出ればよい
   - `中断:` やエラーが出たら、この節の手順 4 へ進まない。共用 TLS 設定が戻る前は、証明書を削除できない

1. この手順で生成した証明書と鍵、TLS 設定の退避を消す（取り戻せない）。

   ```bash
   if [ -L ~/.local/state/gnome-headless-session-setup ]; then
     echo '中断: TLS 設定の退避先がリンクになっている。ファイルは削除しない' >&2
   elif [ ! -e ~/.local/state/gnome-headless-session-setup ]; then
     echo '退避なし: 証明書と鍵は削除しない'
   elif [ ! -f ~/.local/state/gnome-headless-session-setup/restored ]; then
     echo '中断: 共用 TLS 設定を戻していない。この節の手順 3 を先に完了する' >&2
   else
     (
       set -e
       if [ -f ~/.local/state/gnome-headless-session-setup/created-certificate ]; then
         if [ ! -f ~/.local/state/gnome-headless-session-setup/created.sha256 ] ||
            [ -L ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ] ||
            [ -L ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key ]; then
           echo '中断: 生成物を照合できないか、リンクへ置き換わっている。証明書と退避は削除しない' >&2
           exit 1
         fi
         if ! sha256sum --check ~/.local/state/gnome-headless-session-setup/created.sha256; then
           echo '中断: 生成後に証明書か鍵が変わっている。証明書と退避は削除しない' >&2
           exit 1
         fi
         rm -f ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt ~/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
         rmdir --ignore-fail-on-non-empty ~/.local/share/gnome-remote-desktop/certificates
       fi
       rm -f ~/.local/state/gnome-headless-session-setup/tls-cert ~/.local/state/gnome-headless-session-setup/tls-key \
         ~/.local/state/gnome-headless-session-setup/backup-complete ~/.local/state/gnome-headless-session-setup/ready \
         ~/.local/state/gnome-headless-session-setup/restored ~/.local/state/gnome-headless-session-setup/created-certificate \
         ~/.local/state/gnome-headless-session-setup/created.sha256
       rmdir --ignore-fail-on-non-empty ~/.local/state/gnome-headless-session-setup
       rm -f ~/rdp_tls_probe.py
     )
   fi
   ```

   - 今回生成し、生成時の中身のままの証明書だけが消える。既存の証明書・`.old`・ほかのファイルは残る
   - `中断:` のときは、生成途中のファイルや後から差し替えたものを手で確認する。照合できないものは自動削除しない
   - `credentials.ini` 自体も残す。ヘッドレス用の資格情報は、この節の手順 3 の `clear-credentials` で解除済み
   - 退避の無い既存導入では何も削除しない。`~/rdp_tls_probe.py` が要らなければ手で消す

1. ヘッドレスのセッションを止めて起動時に作らないようにし、終わったかを確かめる。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。セッションを使うユーザーのシェルで貼り直す' >&2
   else
     sudo systemctl disable --now "gnome-headless-session@${USER}.service"
     for i in $(seq 1 30); do [ -z "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"')" ] && break; sleep 1; done
     loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"' | wc -l
   fi
   ```

   - `Removed '/etc/systemd/system/graphical.target.wants/gnome-headless-session@<USER>.service'.` と出る
   - セッションで動いていたアプリも閉じる
   - 続いて `0` が出ればよい（このユーザーのヘッドレスのセッションだけを数える。[手順 2](#実施手順) の補足）
   - `for` の行で、セッションが終わるまで、30 秒まで待つ

---

## 補足

### 対象と検証環境

- **目的**: モニターの無い PC で GNOME のデスクトップを常駐させ、別のマシンの RDP クライアントから、そのデスクトップにつなぐ
- **方式**: GDM のヘッドレスのセッション（`gnome-headless-session@<USER>.service`）と、そのセッションの gnome-remote-desktop（`grdctl --headless`、`gnome-remote-desktop-headless.service`）。RHEL 10 の文書の「1.4 headless server for a single user」と同じ
- **状態**: **aarch64 の実機（Raspberry Pi 5）で本実行済み（2026-10-01）。クリーンインストールした x86_64 の VM でも実施手順 1〜10・LAN 限定・ロールバック 2〜5 を本実行し、再起動後の自動起動と RDP の画面操作を確認した（2026-10-06。[今回の付録](#付録-クリーンインストールした-vm-での検証2026-10-06)）**
  - 通したもの: この文書のブロックを、SSH でログインしたユーザーの `bash -i`（擬似端末、ブラケットペースト無し）にそのまま貼った。書き換えたのは手順 1 の `SERVER_IP` と、任意節の `LAN_SUBNET` だけ
    - 実施手順 1〜9 → 手順 10（別のセッションの FreeRDP で接続）→ [接続元を LAN に絞る（任意）](#接続元を-lan-に絞る任意) → [ロールバック](#ロールバック)の手順 2〜5
    - `grep headless` を直した後の版で、実施手順 1・2 → ロールバックの手順 5 → 実施手順 1・2 をもう一度通した（ほかのユーザーのヘッドレスのセッションがある状態で）
  - 確認したこと
    - リモートログイン（3389）が有効な PC で、`RDP_PORT` が 3390 になり、このセッションの RDP が 3390/tcp で待ち受ける
    - FreeRDP 3.10.3 で、証明書の Thumbprint が `TLS fingerprint` と一致し、正しいパスワードでつながり、違うパスワードで断られる
    - クライアントには、このセッションのデスクトップが、クライアントの大きさ（1600x900）で出る。クライアントからのクリックとキーで、アクティビティ画面から電卓が起動した
    - 切ってつなぎ直すと、同じデスクトップ（電卓が開いたまま）に戻る
    - 手順 7 の前は、別の network namespace からの接続が `No route to host` で断られ、後はつながる。LAN に絞ると、`LAN_SUBNET` の外からは断られる
    - ロールバックの後、firewalld・dconf・ホームは実施前と同じになる
    - SELinux が Enforcing のまま、AVC は出なかった
  - 確認していないこと
    - 再起動の後の自動起動（この Pi では WireGuard・Samba・Syncthing も動いているので、再起動しなかった）
    - 手順 10 のポートへ直接つなぐ場合の、Windows のリモート デスクトップ接続・Android のクライアント・LAN の別のマシン（実物）からの接続。Windows 11 から 3389 のリモートログインを経由する引き渡しは、下の 2026-10-02 の記録で確認済み
    - x86_64 の PC、サスペンドできる PC（ログイン画面が眠らせないこと）
    - 同じユーザーのローカルのログインとの重なり、後からリモートログインを有効にしたとき
  - 2026-10-02: リモートログインのログイン画面から同じユーザーで入ると、このセッションに引き渡された（Windows 11 の「リモートデスクトップ接続」で。[gnome-remote-desktop.md の付録](gnome-remote-desktop.md#付録-真っ暗な画面のまま切れた原因の調査記録環境-22026-10-02)）
    - 同じ日に、試験用のユーザーとコンテナの FreeRDP 3.10.3 で、3390 と 3389 の同時の接続と GDM の再起動を確かめた（[同書の付録の追加の確認](gnome-remote-desktop.md#追加の確認)。[注意点](#注意点)）
  - 2026-10-02: もとの手順 2・3 と、[ロールバック](#ロールバック)のもとの手順 5・6 をつなぎ、確かめの行を `if … fi` の `else` に入れた（つないだ形は貼っていない。`bash -n` だけ）
  - 2026-10-05: 手順 3・4 とロールバックの手順 3・4 に、共用 TLS 設定の退避・復元と、新規生成した証明書だけの削除を追加した。構文検査と一時ディレクトリ・スタブでの確認だけで、実機の RDP では流していない

| 項目 | 値 |
|---|---|
| 実施日 | 2026-10-01 |
| 機械 | Raspberry Pi 5 Model B（aarch64、メモリ 8 GB）。HDMI は 2 つとも `disconnected`（モニター無し） |
| OS | AlmaLinux 10.2 (Lavender Lion)、カーネル `6.12.96-20260724.v8.1.el10`、SELinux Enforcing |
| GNOME | `gdm-47.0-24.el10_2`、`gnome-shell-49.4-9.el10_2.alma.1`、`mutter-49.4-4.el10_2`、`gnome-session-46.0-11.el10`、`gnome-remote-desktop-49.3-4.el10_2` |
| そのほか | `firewalld-2.4.3-4.el10_2`、`openssl-3.5.8-1.el10_2.alma.1`、`sudo-1.9.17-10.p2.el10_2.6`（このユーザーは NOPASSWD）。リモートログイン（システムのデーモン）が有効 |
| クライアント | `freerdp-3.10.3-12.el10_2.11`（AlmaLinux 10 のコンテナ。同じ Pi の、試験用のユーザーのヘッドレスのセッションに描いた。[付録](#付録-実機での検証記録2026-10-01)） |


> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${SERVER_IP}` | クライアントが接続に使う PC の IP アドレス | `192.168.10.100` |
> | `${SERVER_NAME}` / `${SERVER_FQDN}` | PC のホスト名 / FQDN（`hostname` / `hostname -f` から自動で入る） | `my-pc` / `my-pc.lan` |
> | `${RDP_PORT}` | RDP で待ち受けるポート（リモートログインのデーモンが有効なら 3390、無ければ 3389。自動で入る） | `3390` |
> | `${LAN_SUBNET}` | LAN のサブネット。[接続元を LAN に絞る](#接続元を-lan-に絞る任意)ときだけ、その節で設定する | `192.168.10.0/24` |
>
> 出力例・ログの中の値は `<HOSTNAME>` / `<SERVER_IP>` / `<RDP_PORT>` / `<USER>` / `<UID>` / `<SESSION_ID>` / `<PID>` / `<FINGERPRINT>`（証明書の TLS fingerprint）のプレースホルダで書いてある。`<...>` を含むコマンドは bash のコードブロックには置かない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| seat0 | GDM のログイン画面だけ（モニターがつながっていない） |
| ヘッドレスのセッション | 無し（`gnome-headless-session@<USER>.service` は `disabled`） |
| `~/.local/share/gnome-remote-desktop` | 無し。dconf の `/org/gnome/desktop/remote-desktop/` も空 |
| リモートログイン | システムの gnome-remote-desktop が 3389/tcp で待ち受けている |
| firewalld | public ゾーン。サービスに `rdp`、ポートは `22/tcp 51820/udp 445/tcp`（3390/tcp は無し） |
| gnome-power.md | 手順 1・2 を済ませてあった（前提） |

### 選択した方針

- **ヘッドレスのセッションにする**（RHEL 10 の文書の 1.4）
  - デスクトップ共有（設定アプリの「デスクトップ共有」）は、PC の物理の画面を写す。モニターの無い PC には写す画面が無い
  - リモートログイン（[gnome-remote-desktop.md](gnome-remote-desktop.md)）は、GDM で認証し、そのユーザーのセッションが無ければ作成する。切断後のセッションや、ここで常駐させたヘッドレスのセッションがあれば、そこへ引き渡す
  - ヘッドレスのセッションは RDP 接続より前から常駐し、手順 10 の接続では GDM のログイン画面を通らず、そのデスクトップへ入る
- **証明書は openssl で作る** — SAN に IP を入れる理由は gnome-remote-desktop.md と同じ
- **ポートを固定し、ポートのネゴシエーションを切る** — ファイアウォールで開けたポートと食い違わないように

### 完了時点の状態

実施手順の後の出力:

```
$ grdctl --headless status
Init TPM credentials failed because No TPM device found, using GKeyFile as fallback.
Overall:
	Unit status: active
RDP:
	Status: enabled
	Port: 3390
	TLS certificate: /home/<USER>/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
	TLS fingerprint: <FINGERPRINT>
	TLS key: /home/<USER>/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
	Negotiate port: no
	Username: (hidden)
	Password: (hidden)
$ ss -Hlnt "sport = :${RDP_PORT}"
LISTEN 0      5      *:3390 *:*
$ sudo firewall-cmd --list-ports
22/tcp 445/tcp 3390/tcp 51820/udp
```

- クライアントがつないでいる間は、`org.gnome.Mutter.DisplayConfig` の `GetCurrentState` に `Virtual remote monitor`（クライアントの大きさ）が 1 枚だけある。切ると消え、ジャーナルに `Removed virtual monitor` が出る

### 注意点

- **Homebrew が PATH の先頭にあると、`gsettings`・`gdbus`・`gio`・`python3` が Homebrew のものになる**（[homebrew.md の注意点](homebrew.md#注意点)）。前提の [gnome-power.md](gnome-power.md) の手順は `/usr/bin/gsettings` で書いてある（Homebrew の `gsettings` は GNOME に効かない）
- **同じユーザーの GNOME のセッションは 1 つにする**: PC の画面から同じユーザーで入るときは、先に `sudo systemctl stop gnome-headless-session@<USER>.service` でヘッドレスのセッションを止める
  - gnome-session のユーザーの unit（`gnome-session-manager@gnome.service` など）はユーザーに 1 組しか無いので、2 つ目のセッションは動かないはず（重なったときの動きは確かめていない）
  - リモートログイン（[gnome-remote-desktop.md](gnome-remote-desktop.md)）のログイン画面から同じユーザーで入ると、新しいセッションは作られず、このセッションに引き渡された（2026-10-02。同書の[注意点](gnome-remote-desktop.md#注意点)）
  - このセッションにつなげるのは 1 つだけ。3390 とリモートログインから同時につなぐと、後からつないだ方が残り、先の接続は切られた（どちらが先でも同じ）
- **起動し直すのは `restart` ではなく、`stop` → 待つ → `start`**: `sudo systemctl restart gnome-headless-session@<USER>.service` では、新しいセッションができなかった（[付録](#付録-実機での検証記録2026-10-01)）
- **GDM を再起動すると、このセッションも止まって起動し直される**（`Requires=gdm.service`）
  - 起動し直しが前のセッションの片付けとぶつかると、新しいセッションはすぐ終わる（2026-10-02 に、2 つのうち 1 つで起きた）
  - GDM を再起動したら `systemctl is-active gnome-headless-session@<USER>.service` を見て、`inactive` なら `sudo systemctl start gnome-headless-session@<USER>.service` で起動する
- **セッションを止めると、ユーザーの D-Bus が起動し直される**: GNOME のセッションが終わると、`gnome-session-restart-dbus.service` がユーザーのセッションバスを起動し直す
- **ログインのキーリングは開いていない**: パスワード無しで作るセッションなので、キーリング（`login`）はロックされたまま。パスワードを読もうとするアプリは、キーリングを開く窓を出す
- **サスペンドとロック**: ヘッドレスのセッションでも gsd-power は動き、既定では 15 分の無操作で PC をサスペンドしようとする。前提の [gnome-power.md 手順 1・2](gnome-power.md#実施手順) で止める
  - seat0 には GDM のログイン画面が残り、Workstation で入れた PC ではそれも 15 分で PC を眠らせる（[gnome-power.md 手順 3](gnome-power.md#実施手順) の補足）。サスペンドできる PC では、同書の手順 3・4 も行う（この Pi はサスペンドできないので、確かめていない）
- **リモートログインを有効にしている PC**: セッションの中で `gnome-remote-desktop-handover.service` も起動する（リモートログインの受け渡し役。TCP では待ち受けない）
  - リモートログインのデーモン（`gnome-remote-desktop.service`）を起動し直したら、この受け渡し役のデーモンも再起動する（[gnome-remote-desktop.md の「設定済みのサーバーで GDM の後に起動させる」](gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる)の手順 4）。しないと、リモートログインからこのセッションへ渡せなくなるはず
- **自己署名証明書**: クライアントは初回に証明書の確認を出す。証明書を作り直したら、クライアントで保存済みの証明書を消すか、変更の警告を承認する（gnome-remote-desktop.md の注意点と同じ）
- **資源**: セッションを起動すると、`free` の `available` が約 600 MB 減った（Raspberry Pi 5、アプリを開いていないとき）

### 参照

- [Chapter 1. Remotely accessing the desktop — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/remotely-accessing-the-desktop)（1.4 headless server for a single user）
- [GNOME/gnome-remote-desktop README.md](https://github.com/GNOME/gnome-remote-desktop/blob/master/README.md)（Headless の節）

---

### 付録: 実機での検証記録（2026-10-01）

**環境**: [対象と検証環境](#対象と検証環境)の表の Raspberry Pi 5。前提の gnome-power.md 手順 1・2 は済ませてあった。

**クライアントの作り方**（検証の都合。手順書では要らない）:

- 同じ Pi に試験用のユーザーを作り、そのユーザーにもヘッドレスのセッションを起動した。そのセッションには、[claude-code-gui.md](claude-code-gui.md) と同じドロップインで 1600x900 の仮想モニターを付けた
- root の podman で、AlmaLinux 10 に `freerdp` を入れたコンテナを作り、そのセッションの Xwayland（`DISPLAY`・`XAUTHORITY`）に `xfreerdp /v:192.168.1.10:3390 /u:<RDP のユーザー名> /f` を描かせた（ネットワークは `--network host`）
- クライアントの画面は、試験用のユーザーのセッションで `scripts/gnome-gui.py shot` で撮り、入力も同じスクリプトで送った（クライアントの FreeRDP の窓へ）
- ファイアウォールの確かめには、veth でつないだ network namespace（`192.168.252.0/24` と `192.168.253.0/24`。[samba.md の付録](samba.md#network-namespace-から-firewalld-越しに到達する)と同じ手法）から、手順 9 のプローブを 192.168.1.10:3390 へ当てた
- 確かめた後に、試験用のユーザー（`userdel -r`）・コンテナとイメージ・network namespace を消した

**流し方**: この文書のブロックを Python のスクリプトで抜き出し、擬似端末で動かした `bash -i` に書き込んだ（ブラケットペースト無し。手順 5 と FreeRDP の問い合わせには、問い合わせが出てから答えた）。

| 手順 | 結果 |
|---|---|
| 1 | `RDP_PORT = 3390`（リモートログインのデーモンが enabled） |
| 2 | `Created symlink …`。`<SESSION_ID> <UID> <USER> - <PID> user headless no -` と `<PID> /usr/bin/gnome-shell` |
| 3 | `rdp-tls.crt`（`-rw-r--r--`）と `rdp-tls.key`（`-rw-------`）。最初は、検証の仕掛けのシェルの `umask 077` を引き継いで `rdp-tls.crt` も 0600 になったので、`umask 022` のシェルで貼り直した |
| 4 | `BIO_new failed for certificate`・`RDP server certificate is invalid.` が 1 回ずつと、TPM のメッセージが 4 回。貼り直したときは TPM のメッセージだけ |
| 5 | `Username:` と `Password:` を聞かれた |
| 6 | `enabled` |
| 7 の前 | network namespace から `No route to host`（`ss` では `*:3390` で待ち受けていた） |
| 7 | `success` が 2 行、`22/tcp 445/tcp 3390/tcp 51820/udp`。network namespace からつながった |
| 8・9 | [完了時点の状態](#完了時点の状態)のとおり。プローブは `selectedProtocol=0x2`・`TLSv1.3`・`fingerprint:` が `TLS fingerprint` と一致 |
| 10 | 下の「クライアントからの接続」 |
| LAN に絞る | `success` が 3 行、rich rule に `192.168.252.0/24` と `3390`。`192.168.252.2` からはつながり、`192.168.253.2` からは `No route to host` |
| ロールバック 2〜5 | `success` が 2 行（rich rule が消えた）、`disabled`、`Removed …`。firewalld の `--list-all` は runtime・permanent とも実施前と同じ。dconf の `/org/gnome/desktop/remote-desktop/` は空 |

**クライアントからの接続**（手順 10）:

- FreeRDP は、証明書の `Subject`・`Issuer`・`Thumbprint` を出して `Do you trust the above certificate? (Y/T/N)` と聞いた。`Thumbprint` は手順 8 の `TLS fingerprint` と同じだった
  - 新しいコンテナ（保存済みの証明書が無い）でも、`The host key for 192.168.1.10:3390 has changed` の警告を出した（理由は確かめていない）
- 続けて `Domain:`（空のまま Enter）と `Password:` を聞いた。正しいパスワードで、サーバーのジャーナルに `Added virtual monitor Meta-0` が出た
- クライアントの画面と、サーバー側で撮ったこのセッションの画面は、ほぼ同じだった（縮めて比べた画素の差の平均が 0.39/255）
- クライアントから、左上のアクティビティのボタンをクリックし、`calc` と打って Enter を押すと、このセッションで電卓が起動した（サーバー側の `windows` に `gnome-calculator` が出た）
- クライアントを止めると、サーバーのジャーナルに `[RDP] Network or intentional disconnect, stopping session` と `Removed virtual monitor Meta-0` が出た。電卓は動き続け、つなぎ直すと、電卓が開いたままのデスクトップが出た
- 違うパスワードでは、クライアントが `ERRCONNECT_AUTHENTICATION_FAILED`、サーバーが `AcceptSecurityContext status SEC_E_MESSAGE_ALTERED` と `client authentication failure` を出した

**手順書を直したこと**:

- 手順 2 とロールバックの手順 5 の確かめの行（もとの手順 3 とロールバックの手順 6）は、最初は `grep headless` で数えていた。試験用のユーザーのヘッドレスのセッションも数えられ、ロールバックの手順 5 の確かめの行が `1` を出した（30 秒待った後）。このユーザーの行だけを数える `awk` にして、ほかのユーザーのセッションがある状態で通し直した

**分ける前の版の検証で見つけたこと**（[claude-code-gui.md の付録](claude-code-gui.md#付録-実機での検証記録2026-10-01)）:

- ヘッドレスのセッションでも gsd-power が動き、既定のままでは、無操作の 15 分で `Error calling suspend action: … SleepVerbNotSupported …` を出した（サスペンドしようとした。この Pi はサスペンドできない）
- `sudo systemctl restart gnome-headless-session@<USER>.service` では、前のセッションの片付けと新しいセッションの起動が重なり、新しいセッションの gnome-session が `Transaction … is destructive` で起動をあきらめ、GDM が `Session never registered, failing` で終わらせた。`stop` → 前のセッションが `loginctl` から消えるのを待つ → 3 秒待つ → `start` では起動した
- GNOME のセッションが終わると、`gnome-session-restart-dbus.service` がユーザーの D-Bus を起動し直した
- リモートログインが有効な PC では、このセッションの中で `gnome-remote-desktop-handover.service` も起動した（TCP では待ち受けない）
- claude-code-gui.md のドロップインで仮想モニターを付けたセッションに RDP でつなぐと、クライアントには、その仮想モニターの右に足された別のモニター（`Virtual remote monitor`）が写った。`screen-share-mode` を `'mirror-primary'` と明示しても同じだった

#### 未確認事項

- 2026-10-01 の実機では、再起動の後にヘッドレスのセッションと RDP の待ち受けが自動で起動することは未確認。2026-10-06 の x86_64 の VM では確認した（末尾の付録）
- Windows のリモート デスクトップ接続・Android のクライアント・LAN の別のマシン（実物）からの接続
- x86_64 の PC と、サスペンドできる PC（ログイン画面が眠らせないこと）
- 同じユーザーでリモートログインやローカルのログインをしたときの動き
- 後からリモートログインを有効にしたとき（このセッションの RDP を 3389/tcp で使っていた場合）
- キーリングを開く窓が出たときの動き（RDP のクライアントからパスワードを入れて開けるか）

### 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を ISO から新規に入れた VirtualBox の VM（x86_64、1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で、検証用ユーザーの SSH PTY に現行のブロックを個別に貼った。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、GNOME Shell は `49.4-9.el10_2.alma.1`、Mutter は `49.4-4.el10_2`、GDM は `47.0-24.el10_2`、GNOME Remote Desktop は `49.3-4.el10_2`。利用者のアカウントは使っていない。

実施手順 1〜10、接続元を LAN に絞る任意節、ロールバック 2〜5 を本実行した。システムのリモートログインが有効な状態から、手順 1 の判定で `RDP_PORT=3390` になった。手順 2 は、Mutter のバス名が現れても loginctl の行がまだ無い場合があったので、両方を待つ形に直して再検証した。

手順 3 は、未設定だった共用 TLS の値を退避して新しい証明書・鍵を生成し、ハッシュを控えた。手順 4〜9 で 3390 番・ポート交渉なし・ヘッドレス資格情報を設定して有効化し、TLS 1.3、fingerprint、待ち受けを確認した。最初の `set-tls-cert` は鍵のパスが未設定のため `RDP server certificate is invalid` も出したが、続く `set-tls-key` の後は設定が揃い、実際の TLS と画面接続は通った。証明書・鍵を既に持つ環境や、既存の非空の TLS 設定を復元する分岐は、この VM では流していない。

クライアントは、LAN の別の AlmaLinux VM の FreeRDP 3.10.3（Xvfb 1600x900 上。準備と資格情報の扱いは [リモートログインの今回の記録](gnome-remote-desktop.md#付録-クリーンインストールした-vm-での検証2026-10-06)）。3390 番でデスクトップが表示され、キー入力による電卓の `12×34=408` を実画面で確認した。切断後も同じヘッドレスセッションが残り、再接続すると電卓の 408 に戻った。接続時には RDP 用の仮想モニターができ、切断後の DisplayConfig はモニター 0 枚だった。

LAN 限定の rich rule に替えてから VM を再起動した。ヘッドレスセッションと RDP の unit は自動起動し、3390 番の `RDP server started` は起動後に記録された。1 vCPU では unit が active になってからこのログまで約 25 秒かかった。続いて 3389 番の GDM からこのユーザーへ入ると、自動起動した `Service=gdm-autologin` の同じセッションに渡された。そこで計算した `9×9=81` は、3389 を切って 3390 に直接つなぎ直しても残った。LAN 制限後・再起動後も LAN の別 VM から接続でき、今回の AVC は無かった。

ロールバック 2〜5 は rich rule と資格情報を解除し、共用 TLS の cert / key を退避した未設定の値へ戻した。生成時の SHA-256 と 2 ファイルが一致してから、新規生成した証明書・鍵・退避を削除した。ヘッドレスの unit は disabled / inactive、loginctl の対象行は 0、3389 / 3390 番の待ち受けは消えた。GUI 検証を続けるため、その後は手順 1・2 だけを入れ直した。

今回の RDP は、GUI 検証用の固定 `--virtual-monitor` を外して測った。Windows / Android の直接接続、物理 PC、指定 LAN 外からの拒否、同じユーザーの物理画面への同時ログインは今回も確認していない。2026-10-01 の付録の未確認事項のうち、再起動後の自動起動は今回の x86_64 の VM で確認した。

実行ログは `.verification/desktop/` の `rdp-headless-plan-session`、`rdp-credentials-plan-session`、`rdp-probes-plan-session`、`rdp-lan-plan-session`、`rdp-rollback-plan-session`、`rdp-headless-boot-debug.log`、`rdp-rollback-state.log`。実画面は `rdp-headless-calc-result.png`、`rdp-headless-reconnected.png`、`rdp-direct-after-reboot.png` に保存した。
