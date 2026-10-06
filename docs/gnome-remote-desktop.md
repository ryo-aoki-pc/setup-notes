# GNOME Remote Desktop 有効化手順（リモートログイン方式）

## 実施手順

- [検証記録](verification/gnome-remote-desktop.md)・[参考資料](reference/gnome-remote-desktop.md)

> [!IMPORTANT]
> - **すべてサーバー上で実行する**。手順 11（クライアントからのログイン）だけ別マシン
> - **手順 6 には対話入力がある**（ユーザー名とパスワード）。入力し終えてから手順 7 を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: 接続元を LAN に絞る場合は、最後に[接続元を LAN に絞る（任意）](#接続元を-lan-に絞る任意)を行う。戻すときは[ロールバック](#ロールバック)
- モニターの無い PC に自分のデスクトップを常駐させて RDP でつなぐなら、[gnome-headless-session.md](gnome-headless-session.md)。この手順書と同じ PC で併用できる（ポートは 3390）
- PC の画面でログインしているデスクトップを、そのまま RDP で共有するなら、[gnome-desktop-sharing.md](gnome-desktop-sharing.md)（VM のみで検証）

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

---

## ロールバック

- 利用を止めるときは、この節の手順 1 と、LAN に絞っていた場合は手順 2 を行う
- 証明書だけを戻すときは、この節の手順 1・2 を飛ばし、手順 3・4 を行う

> [!WARNING]
> **この節の**手順 3 で証明書を差し替え前に戻すには、旧ファイルが要る。差し替えのときに旧ファイルを消していると、証明書は戻せない。[手順 2](#実施手順) は同じ名前で上書きするので、残すなら先にコピーしておく。

1. サービスと RDP を止め、資格情報とファイアウォールの開放と、手順 5 のドロップインを消す。

   ```bash
   {
     sudo systemctl disable --now gnome-remote-desktop.service
     sudo grdctl --system rdp disable
     sudo grdctl --system rdp clear-credentials
     sudo firewall-cmd --permanent --remove-service=rdp && sudo firewall-cmd --reload
     sudo rm -f /etc/systemd/system/gnome-remote-desktop.service.d/10-after-gdm.conf
     sudo rmdir --ignore-fail-on-non-empty /etc/systemd/system/gnome-remote-desktop.service.d
     sudo systemctl daemon-reload
     sudo firewall-cmd --list-services
     sudo firewall-cmd --permanent --list-services
   }
   ```

   - runtime・permanent のどちらのサービス一覧にも `rdp` が無ければよい

1. [接続元を LAN に絞る](#接続元を-lan-に絞る任意)を行ったときは、追加した rich rule も消す。

   ```bash
   if [ -z "${LAN_SUBNET}" ]; then echo '中断: LAN_SUBNET が空のまま。LAN に絞る節の変数ブロックを貼り直す' >&2; else
     sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=${LAN_SUBNET} port port=3389 protocol=tcp accept"
     sudo firewall-cmd --reload
     sudo firewall-cmd --list-rich-rules
     sudo firewall-cmd --permanent --list-rich-rules
   fi
   ```

   - `LAN_SUBNET` は、[接続元を LAN に絞る](#接続元を-lan-に絞る任意)の手順 1 の変数ブロックで、設定時と同じ値を入れる
   - runtime・permanent のどちらにも、その送信元と 3389/tcp の rich rule が無ければよい

1. 証明書だけを差し替え前に戻すときは（この節の手順 1・2 の代わりに）、旧ファイル名を入れてパスを戻す。

   ```bash
   OLD_BASENAME=                        # ← 差し替え前の証明書・鍵のファイル名（拡張子なし）
   ```

   ```bash
   if [ -z "${OLD_BASENAME}" ]; then echo '中断: OLD_BASENAME を設定してから貼り直す' >&2; else
   sudo grdctl --system rdp set-tls-key  "/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/${OLD_BASENAME}.key"
   sudo grdctl --system rdp set-tls-cert "/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/${OLD_BASENAME}.crt"
   fi
   ```

   - `OLD_BASENAME` には、差し替え前の証明書・鍵のファイル名（拡張子なし）を入れる
   - `OLD_BASENAME` が空のまま貼ると、先頭の `if` で中断し、`grdctl` は実行されない

1. この節の手順 3 で証明書を戻したときは、デーモンを起動し直して反映する。

   - [設定済みのサーバーで GDM の後に起動させる](#設定済みのサーバーで-gdm-の後に起動させる)の手順 3 と、ヘッドレスのセッションがある場合は手順 4 を行う
   - その節の手順 1・2・5 は行わない

---

## 注意点

- **TPM 警告**: `grdctl --system` 実行時と service 起動時に毎回 `Init TPM credentials failed ... using GKeyFile as fallback` が出るが、TPM が使えない機体での正常なフォールバック
  - 資格情報は `/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/credentials.ini` に保存される
- **設定レイヤーの食い違い**
  - システムデーモンの設定は、`/usr/share/gnome-remote-desktop/grd.conf`（既定）→ `/etc/gnome-remote-desktop/grd.conf`（`grdctl` が書く）の順に読まれる
  - ただし、`~gnome-remote-desktop/.local/share/gnome-remote-desktop/grd.conf` が作られることがある
  - `/etc` 側の `enabled=true` と、このファイルの `enabled=false` が食い違うと、サービスを再起動しても有効にならないことがある。次の確認方法で設定を読み戻す
  - 食い違う場合は、デーモン稼働中にもう一度 `sudo grdctl --system rdp enable` を実行し、設定と待ち受けを確認する

  確認方法:

  ```bash
  {
    sudo cat /etc/gnome-remote-desktop/grd.conf
    sudo cat /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/grd.conf   # 通常は存在しない
  }
  ```

- **リモートログインのセッション**: そのユーザーのセッションが無ければ、ログインで新しいセッションができる
  - ローカルでログイン中のユーザーと同一ユーザーで接続すると、GDM が既存セッションの扱い（切替 or 拒否）を求める場合がある
  - PC の物理モニターに表示しているデスクトップを見る用途は「デスクトップ共有」方式（ユーザーのデーモン）。本書では扱わず、[gnome-desktop-sharing.md](gnome-desktop-sharing.md) に分けた（VM のみで検証）
- **ヘッドレスのセッションを常駐させている PC**（[gnome-headless-session.md](gnome-headless-session.md)）
  - そのユーザーのセッションの中で、リモートログインの受け渡し役のデーモン（`gnome-remote-desktop-handover.service`）が起動する（TCP では待ち受けない）
  - このデーモン（`gnome-remote-desktop.service`）を再起動したら、受け渡し役のデーモンも再起動する（[設定済みのサーバーで GDM の後に起動させる](#設定済みのサーバーで-gdm-の後に起動させる)の手順 4）。しないと、そのユーザーでログインしたときに、ログイン画面が名前とアイコンのまま進まない
    - RHEL の `gnome-remote-desktop` 49.3-3 からの機能（パッケージの changelog の「Support remote login to sessions from gnome-headless-session@.service」）
    - クライアントには、ヘッドレスのセッションに足された仮想モニターが写る。[claude-code-gui.md](claude-code-gui.md) のドロップインがある PC では、`Meta-0` の右に足された `Meta-1` になり、壁紙だけが写る（上部バーもウィンドウも無い）
    - 切断すると足されたモニターは消え、ヘッドレスのセッションは残った
  - ヘッドレスのセッションの RDP（gnome-headless-session.md、3390）と同時につなぐと、後からつないだ方が残り、先の接続は切られた（どちらが先でも同じ）
  - 起動のときと同じすれ違い（[手順 5](#実施手順) の補足）は、タイミングによっては起きるはず（コードからの推定）。真っ暗なまま切れるようになったら、[設定済みのサーバーで GDM の後に起動させる](#設定済みのサーバーで-gdm-の後に起動させる)の手順 2〜4 で直す
  - ヘッドレスのセッションは、GDM と一緒に止まって起動し直される。前のセッションの片付けとぶつかって、消えることがある（[gnome-headless-session.md の注意点](gnome-headless-session.md#注意点)）
- **自己署名証明書**: クライアント側で証明書警告が出る。信頼できる CA の証明書がある場合は、手順 2〜4 でそちらのパスを指定する
- **証明書を差し替えたとき**: 自己署名証明書が変わると、クライアントは保存済みの旧証明書と照合して警告を出す
  - **クライアント側で保存された証明書の信頼を一度削除する**か、変更の警告を承認する必要がある
  - 差し替え後は、[設定済みのサーバーで GDM の後に起動させる](#設定済みのサーバーで-gdm-の後に起動させる)の手順 3 と、ヘッドレスのセッションがある場合は手順 4 で反映する（接続中の RDP セッションは切断されるので、利用者がいないときに行う）
- **public ゾーンでの開放**: public ゾーンに属するすべての NIC で 3389/tcp が開く。接続元を制限しない場合はそのままでよい
  - LAN 限定に絞る手順は[接続元を LAN に絞る](#接続元を-lan-に絞る任意)
- **ログイン画面のまま置くと眠ることがある**: Workstation で入れた PC のログイン画面は、電源につないでいても 15 分でサスペンドする
  - 眠ると RDP でつなげない。止めるなら [gnome-power.md](gnome-power.md)
