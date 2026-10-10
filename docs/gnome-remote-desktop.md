# GNOME Remote Desktop 有効化手順（リモートログイン方式）

## 実施手順

- [検証記録](verification/gnome-remote-desktop.md)・[参考資料](reference/gnome-remote-desktop.md)・[ロールバックと注意点](extra/gnome-remote-desktop.md)

> [!IMPORTANT]
> - **すべてサーバー上で実行する**。手順 11（クライアントからのログイン）だけ別マシン
> - **手順 6 には対話入力がある**（ユーザー名とパスワード）。入力し終えてから手順 7 を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: 接続元を LAN に絞る場合は、最後に[接続元を LAN に絞る（任意）](#接続元を-lan-に絞る任意)を行う。戻すときは[ロールバック](extra/gnome-remote-desktop.md#ロールバック)
- モニターの無い PC に自分のデスクトップを常駐させて RDP でつなぐなら、[gnome-headless-session.md](gnome-headless-session.md)。この手順書と同じ PC で併用できる（ポートは 3390）
- PC の画面のデスクトップ（自動ログインで作る）を、PC の画面を触らずにそのまま RDP で共有するなら、[gnome-desktop-sharing.md](gnome-desktop-sharing.md)。今の版は [x86_64 VM](verification/gnome-desktop-sharing.md#付録-pc-の画面を触らない版を-x86_64-の-vm-で通した記録2026-10-07) で、以前の版は aarch64 の[実機](verification/gnome-desktop-sharing.md#付録-このホストでの検証2026-10-07)と[クリーン VM](verification/gnome-desktop-sharing.md#付録-公式-iso-から新規インストールした-aarch64-vm-での検証2026-10-07)、[x86_64 VM](verification/gnome-desktop-sharing.md#付録-virtualbox-の-vm-での本実行2026-10-07)で確かめた範囲を参照
  - デスクトップ共有を 3389 で使っている PC では、この手順書の後に、同書の[注意点](extra/gnome-desktop-sharing.md#注意点)の「後からリモートログインを有効にしたとき」で共有を 3390 へ移す（共有は 3389 で待ち受けられなくなる）

1. 変数を設定する（`SERVER_IP` は必ず値を入れる）。

   ```bash
   SERVER_IP=192.168.10.100            # ← 自分の値に書き換える。クライアントが接続に使う IP。<SERVER_IP>
   ```

   ```bash
   SERVER_NAME=$(hostname)             # 証明書の CN と SAN に入る（自動）。<HOSTNAME>
   SERVER_FQDN=$(hostname -f)          # 同上。<HOSTNAME>.<DOMAIN>
   for v in SERVER_IP SERVER_NAME SERVER_FQDN; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - **編集が必須なのは `SERVER_IP` の 1 行だけ**。残りは既定のままでよい
   - 最後に値を読み戻して確かめる
   - `SERVER_IP` が空、または `SERVER_NAME` / `SERVER_FQDN` が意図した名前と違うなら、ここで止めて直す
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**（SSH を張り直したあとも）、手順 1 の 2 つのブロックを貼り直してから先へ進む

1. `gnome-remote-desktop` ユーザーとして、TLS 証明書と鍵を openssl で生成する。

   ```bash
   if [ -z "${SERVER_IP}" ] || [ -z "${SERVER_NAME}" ] || [ -z "${SERVER_FQDN}" ]; then
     echo '中断: 手順 1 の変数が空のまま。手順 1 を貼り直す' >&2
   else
     sudo -u gnome-remote-desktop mkdir -p /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates
     sudo -u gnome-remote-desktop openssl req -x509 -newkey rsa:2048 -noenc -days 3650 \
       -subj "/CN=${SERVER_NAME}" \
       -addext "subjectAltName=DNS:${SERVER_NAME},DNS:${SERVER_FQDN},DNS:${SERVER_IP},IP:${SERVER_IP}" \
       -addext "extendedKeyUsage=serverAuth" \
       -keyout /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key \
       -out    /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
   fi
   ```

   - 所有権を最初から正しくするため、`gnome-remote-desktop` ユーザー自身として生成する
   - `中断:` と出たら、何も変更していない。手順 1 を貼り直してから、この手順をやり直す

1. 証明書と鍵のパーミッションと、SELinux のコンテキストを整える。

   ```bash
   {
     sudo chmod 600 /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
     sudo chmod 644 /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
     sudo restorecon -Rv /var/lib/gnome-remote-desktop
     sudo ls -lZ /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates
   }
   ```

1. grdctl で、システムデーモンに鍵と証明書を設定し、RDP を有効にする。

   ```bash
   {
     sudo grdctl --system rdp set-tls-key  /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
     sudo grdctl --system rdp set-tls-cert /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
     sudo grdctl --system rdp enable
   }
   ```

   - `sudo grdctl --system status` に表示される **TLS fingerprint を控えておく**（手順 10 で使う）
   - `rdp enable` はデーモンも起動する。このため、この後に設定する資格情報は再起動するまで反映されない（手順 7 で再起動する）

1. GDM の後に起動するようにしてサービスを有効にし、ファイアウォールで RDP を開ける。

   ```bash
   {
     sudo mkdir -p /etc/systemd/system/gnome-remote-desktop.service.d
     sudo tee /etc/systemd/system/gnome-remote-desktop.service.d/10-after-gdm.conf >/dev/null <<'CONF'
   [Unit]
   After=gdm.service
   CONF
     sudo systemctl daemon-reload
     sudo systemctl enable --now gnome-remote-desktop.service
     sudo firewall-cmd --permanent --add-service=rdp
     sudo firewall-cmd --reload
   }
   ```

   - ドロップイン（`10-after-gdm.conf`）は、起動のときにこのデーモンを GDM より後に立ち上げる
   - 無いと、起動のたびに、リモートログインが真っ暗な画面のまま 30 秒で切れることがある（参考資料を参照）

1. 本物の端末で、システム共通の RDP 資格情報を引数なしで対話入力する。

   ```bash
   sudo grdctl --system rdp set-credentials
   ```

   - ユーザー名とパスワードを聞かれる
   - 引数なしで打つのは、パスワードをシェル履歴・ログに残さないため
   - 対話入力は TTY 必須。スクリプトやパイプ、Claude Code の `!` 実行では**何も設定されないまま exit 0 で終わる**（[落とし穴 1](verification/gnome-remote-desktop.md#落とし穴-1-grdctl-の対話入力は-tty-必須)）
   - **次の手順は、ユーザー名とパスワードを入力し終えてから貼る**（続けて貼ると入力として食われる）

1. 資格情報を反映させるため、デーモンを起動し直す。

   - 再起動しないと `[RDP] Credentials are not set, denying client` で拒否され続ける（[落とし穴 2](verification/gnome-remote-desktop.md#落とし穴-2-資格情報の変更にはデーモンの再起動が必要)）
   - [設定済みのサーバーで GDM の後に起動させる](#設定済みのサーバーで-gdm-の後に起動させる)の手順 3 を行う。ヘッドレスのセッションがある PC では、続けて同節の手順 4 も行う
   - その節の手順 1・2・5 は行わない
   - **次の手順は、デーモンと必要な受け渡し役の起動し直しが終わってから貼る**

1. サーバー側の状態を確かめる。

   ```bash
   {
     sudo grdctl --system status              # Status: enabled / Username: (hidden)
     systemctl status gnome-remote-desktop    # active (running)
     ss -lntp | grep 3389                     # *:3389 で LISTEN
     sudo firewall-cmd --list-services        # rdp が含まれる
   }
   ```

1. 鍵と証明書が対応しているかを確かめる。

   ```bash
   {
     sudo openssl x509 -in /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt -noout -modulus | openssl sha256
     sudo openssl rsa  -in /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key -noout -modulus | openssl sha256
   }
   ```

   - 2 つのハッシュが一致すれば、ペアとして正しい

1. TLS ハンドシェイクと、提示される証明書を確かめる。

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
   python3 ~/rdp_tls_probe.py "${SERVER_IP}"
   ```

   - `~/rdp_tls_probe.py` を書き出して、`${SERVER_IP}` に対して実行する（FreeRDP も RDP のパスワードも要らない）
   - 次の 3 つがそろえばよい
     - `selectedProtocol=0x2` でネゴシエーションが成立する
     - `fingerprint` が `grdctl --system status` の TLS fingerprint と**完全一致**する
     - SAN に、接続に使う名前が `DNS:` エントリとして含まれている
   - サーバー側には `nla_recv() error` などのログが出るが、プローブが TLS 直後に切断しただけで正常（この手順の補足の「TLS プローブ」）
   - 確認が済んだら `rm ~/rdp_tls_probe.py` で消してよい（この手順書が作る唯一の作業ファイル）

1. LAN 内の別マシンから、RDP クライアントでログインする。

   - `xfreerdp3 /v:<SERVER_IP>:3389 /u:<システムRDPユーザー名>` の形で接続する
   - 手順 1 の変数は無いので、`<SERVER_IP>` と `<システムRDPユーザー名>` は値に読み替える
   - システム共通パスワードで RDP 認証を通過すると GDM のログイン画面が出るので、OS アカウントでログインする
   - 問題があれば、サーバー側で `journalctl -u gnome-remote-desktop -f` と `journalctl -u gdm -f` を並行して見る

---

## 接続元を LAN に絞る（任意）

- **接続元を制限しないなら、この節は不要**
- 手順 5 は、public ゾーンに属するすべての NIC で 3389/tcp を開く

1. LAN に絞るなら、送信元サブネットを入れ、`rdp` サービスの開放を rich rule に置き換える。

   ```bash
   LAN_SUBNET=192.168.10.0/24           # ← 自分の値に書き換える。<LAN_SUBNET>
   ```

   ```bash
   if [ -z "${LAN_SUBNET}" ]; then echo '中断: LAN_SUBNET が空のまま。値を入れて貼り直す' >&2; else
   sudo firewall-cmd --permanent --remove-service=rdp
   sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=3389 protocol=tcp accept"
   sudo firewall-cmd --reload
   sudo firewall-cmd --list-rich-rules        # source address に実際のサブネットが入っていることを確認する
   fi
   ```

   - 先頭の `if` は、`LAN_SUBNET` が空のままブロックを貼ったときに、`rdp` サービスだけ消えて rich rule が空アドレスで入るのを防ぐ
   - rich rule は**二重引用符**で囲む。単一引用符だと `${LAN_SUBNET}` が展開されず、firewalld は `$LAN_SUBNET` という文字列のままの rule を `success` で受理してしまう

---

## 設定済みのサーバーで GDM の後に起動させる

- ドロップインが効くのは次の起動から。今のデーモンが起動のときに GDM とすれ違っていたら、この節の手順 3 でデーモンを起動し直すと直る（理由は[手順 5](#実施手順) の補足）
- 資格情報や証明書を変更した後も、この節の手順 3 と、ヘッドレスのセッションがある場合は手順 4 を使う。その場合、この節の手順 1・2・5 は行わない
- **この節の手順 3・4 は、リモートログインでつないでいる利用者がいないときに行う**（ヘッドレスのセッションに入った RDP の接続は、手順 4 で再起動する受け渡し役のデーモンが持っている）

1. 起動の順番を GDM の後にするドロップインを置く。

   ```bash
   {
     sudo mkdir -p /etc/systemd/system/gnome-remote-desktop.service.d
     sudo tee /etc/systemd/system/gnome-remote-desktop.service.d/10-after-gdm.conf >/dev/null <<'CONF'
   [Unit]
   After=gdm.service
   CONF
     sudo systemctl daemon-reload
     systemctl show gnome-remote-desktop.service -p After | grep -ow 'gdm\.service'
   }
   ```

   - `gdm.service` と出ればよい

1. 今のデーモンが、起動のときに GDM とすれ違ったかを確かめる。

   ```bash
   sudo journalctl --no-pager _PID="$(systemctl show -p MainPID --value gnome-remote-desktop.service)" | grep -c 'Error calling GetManagedObjects'
   ```

   - `1` なら、すれ違っている。この節の手順 3 へ進む
   - `0` なら、起動時のすれ違いを直すための手順 3・4 は飛ばす（資格情報や証明書を変更した後は、`0` でも行う）

1. デーモンを起動し直す必要があるときは、止めて待ってから起動する。

   ```bash
   {
     sudo systemctl stop gnome-remote-desktop.service
     sleep 5
     sudo systemctl start gnome-remote-desktop.service
     sleep 5
     sudo journalctl --no-pager _PID="$(systemctl show -p MainPID --value gnome-remote-desktop.service)" | grep -E 'GetManagedObjects|RDP server started'
   }
   ```

   - `RDP server started` の 1 行だけが出ればよい
   - 真っ暗なまま残っていたリモートログインのログイン画面のセッションは、止めたときに閉じる（`loginctl list-sessions` の `gdm` の `greeter` で、SEAT が `-` のもの）
   - **注意**: `systemctl restart` にしない（参考資料を参照）

1. ヘッドレスのセッションがある PC では、そのユーザーのシェルで、受け渡し役のデーモンを再起動する。

   ```bash
   {
     systemctl --user restart gnome-remote-desktop-handover.service
     sleep 3
     sudo journalctl --no-pager _PID="$(systemctl --user show -p MainPID --value gnome-remote-desktop-handover.service)" | grep 'RDP server started'
   }
   ```

   - `RDP server started` と出ればよい
   - ヘッドレスのセッションは [gnome-headless-session.md](gnome-headless-session.md) のもの。無い PC では、この手順は飛ばす
   - この節の手順 3 の後、このデーモンは引き渡し口を取り直さないまま止まる。`[DaemonHandover] Could not get session id` が出ることも、何も出ないこともある（参考資料を参照）

1. 元に戻すときは、ドロップインを消して読み込ませる。

   ```bash
   {
     sudo rm -f /etc/systemd/system/gnome-remote-desktop.service.d/10-after-gdm.conf
     sudo rmdir --ignore-fail-on-non-empty /etc/systemd/system/gnome-remote-desktop.service.d
     sudo systemctl daemon-reload
     systemctl show gnome-remote-desktop.service -p After | grep -cw 'gdm\.service'   # 0
   }
   ```

   - 最後に `0` と出ればよい
   - 次の起動からの順番が戻るだけで、今動いているデーモンはそのまま
