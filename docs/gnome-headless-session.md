# GNOME のヘッドレスのセッションの手順（モニターの無い PC のデスクトップに RDP でつなぐ）

## 実施手順

- [検証記録](verification/gnome-headless-session.md)・[参考資料](reference/gnome-headless-session.md)・[ロールバックと注意点](extra/gnome-headless-session.md)

> [!IMPORTANT]
> - **セッションを使うユーザー本人のシェル（SSH でよい）で貼る**。`sudo -i` / `su -` したシェルでは貼らない（セッションと RDP の設定は、貼ったユーザーのものになるため）
> - 前提は [AlmaLinux 10 の初期設定の「画面オフ・画面ロック・自動サスペンドを止める（任意）」](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)の手順 1・2（サスペンドできる PC では、同じ節の手順 3・4 も）。ヘッドレスのセッションでも、既定のままでは 15 分の無操作で PC をサスペンドしようとする
> - **手順 5 は RDP のユーザー名とパスワードの対話入力がある**。入力し終えてから次の手順を貼る
> - 手順 10（クライアントからの接続）だけ別のマシンで行う
> - [リモートログイン](gnome-remote-desktop.md)（GDM で認証し、新しいセッションを作るか既存のセッションへ引き渡す方式）と同じ PC でも使える。そのときのポートは、手順 1 で自動で 3390 になる

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: 接続元を絞るなら[接続元を LAN に絞る（任意）](#接続元を-lan-に絞る任意)。リモートログインと併用していて、ヘッドレスのセッションだけをやめるなら[リモートログインだけにする（併用をやめる）](#リモートログインだけにする併用をやめる)。戻すときは[ロールバック](extra/gnome-headless-session.md#ロールバック)

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
   - `for` の行で、gnome-shell のバス名と `loginctl` のセッションの両方が出るまで、30 秒まで待つ
   - 何も出ないときは、`systemctl status "gnome-headless-session@${USER}.service"` と `systemctl --user status org.gnome.Shell@wayland.service` を見る

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
   - `中断:` が出たら、手順 4 以降へ進まない。[ロールバック](extra/gnome-headless-session.md#ロールバック)の手順 3・4 で戻す。生成途中で照合用の記録も作れなかった場合は、ファイルを自動削除せず残す
   - 置き場所は、RHEL 10 の文書の 1.4 と同じ

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

   - コマンドごとに `Init TPM credentials failed because No TPM device found, using GKeyFile as fallback.` が出る（TPM の無い PC。[検証記録](verification/gnome-headless-session.md)・[参考資料](reference/gnome-headless-session.md)）
   - 初めて設定するときだけ、`[x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` が 1 回ずつ出る。設定する前の空の値を読んだもので、害は無い

1. RDP のユーザー名とパスワードを、引数なしで対話入力する。

   ```bash
   grdctl --headless rdp set-credentials
   ```

   - ユーザー名とパスワードを聞かれる。クライアントが接続するときに入れるもので、OS のアカウントと違ってよい
   - 引数なしで打つのは、パスワードをシェルの履歴に残さないため
   - **次の手順は、ユーザー名とパスワードを入力し終えてから貼る**（続けて貼ると入力として食われる）

1. RDP を有効にする。

   ```bash
   grdctl --headless rdp enable
   systemctl --user is-enabled gnome-remote-desktop-headless.service
   ```

   - `enabled` と出ればよい
   - デーモンが待ち受けたかは、手順 8 で確かめる

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

## リモートログインだけにする（併用をやめる）

> [!IMPORTANT]
> - **セッションを使うユーザー本人のシェルに、SSH で入って貼る**。リモートログインのセッションの中の端末では貼らない（この節の手順 5 で、そのセッションを終わらせるため）
> - この節の手順 6（クライアントからの接続）だけ、クライアントの PC で行う

- [リモートログイン](gnome-remote-desktop.md)とこの手順書のヘッドレスのセッションを併用している PC で、ヘッドレスのセッションをやめ、リモートログインだけにする
- リモートログインの設定（システムのデーモン・証明書・資格情報・3389/tcp）は変えない
- ヘッドレスのセッションで動いていたアプリは閉じる
- [claude-code-gui.md](claude-code-gui.md) の仮想モニターのドロップインも外す。この PC では、Claude Code から GUI を撮って確かめられなくなる
- やめた後は、リモートログインで入ると新しいセッションができる。切断してもセッションは残り、次のログインでそこへ戻る
- ログインしていない間もユーザーのサービス（Syncthing など）を動かすなら、先に [linger.md](linger.md) を通す（linger が無いと、セッションが 1 つも無い間はユーザーの systemd が止まる）
- 実施手順 1 の変数は、この節の手順 2 を行うときだけ要る
- 元に戻すときは、[手順 2](#実施手順)（ヘッドレスのセッションの RDP も使うなら手順 3〜10）と、[claude-code-gui.md 手順 1〜3](claude-code-gui.md#実施手順)

1. 今の状態を確かめる。

   ```bash
   {
     for s in $(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless" {print $1}'); do
       echo "${s} $(loginctl show-session "${s}" -p Service --value)"
     done
     systemctl is-enabled "gnome-headless-session@${USER}.service"
     systemctl --user is-enabled gnome-remote-desktop-headless.service
     ls ~/.config/systemd/user/org.gnome.Shell@wayland.service.d
     pgrep -a -u "${USER}" -x gnome-shell
     sudo firewall-cmd --list-ports
     sudo firewall-cmd --list-rich-rules
   }
   ```

   - `for` の行は、`<SESSION_ID> <Service>` を 1 セッション 1 行で出す。`gdm-autologin` はヘッドレスのセッション、`gdm-password` はリモートログインで入ったセッション（どちらも `loginctl` の `TTY` の列は `headless`）
   - `grdctl --headless status` では確かめない（`credentials.ini` が無ければ作るため）
   - 2 つ目の `systemctl` が `enabled`、`--list-ports` に `3390/tcp`、rich rule に `port="3390"` のどれかがあれば、ヘッドレスのセッションの RDP を設定してある。どれも無ければ、この節の手順 2 は飛ばす
   - `ls` が `virtual-monitor.conf` を出せば、claude-code-gui.md のドロップインがある。`No such file or directory` なら、この節の手順 3 は飛ばす
   - `gdm-password` の行があり、gnome-shell の行に `--virtual-monitor` が付いていれば、この節の手順 5 を行う。そうでなければ、この節の手順 5 は飛ばす

1. ヘッドレスのセッションの RDP を設定してあるときだけ、その設定を外す。

   - [手順 1](#実施手順) の 2 つのブロックを貼ってから、[ロールバック](extra/gnome-headless-session.md#ロールバック)の手順 1（LAN に絞ったときは手順 2）・手順 3・手順 4 を順に貼る
   - ロールバックの手順 5 は貼らない（この節の手順 4 で行う）

1. claude-code-gui.md のドロップインがあるときだけ、外す。

   ```bash
   rm ~/.config/systemd/user/org.gnome.Shell@wayland.service.d/virtual-monitor.conf
   rmdir --ignore-fail-on-non-empty ~/.config/systemd/user/org.gnome.Shell@wayland.service.d
   systemctl --user daemon-reload
   systemctl --user cat org.gnome.Shell@wayland.service | grep '^ExecStart'
   ```

   - `ExecStart=/usr/bin/gnome-shell` の 1 行が出ればよい
   - 動いている gnome-shell には効かない。この節の手順 4・5 でセッションを終わらせ、手順 6 で入り直したときに効く
   - claude-code-gui.md の[ロールバック](extra/claude-code-gui.md#ロールバック)の手順 2 は行わない（ヘッドレスのセッションを起動し直すため）

1. ヘッドレスのセッションを止めて起動時に作らないようにし、終わったかを確かめる。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。セッションを使うユーザーのシェルで貼り直す' >&2
   else
     sudo systemctl disable --now "gnome-headless-session@${USER}.service"
     for i in $(seq 1 30); do
       [ "$(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless" {print $1}' |
         xargs -r -n 1 loginctl show-session -p Service --value 2>/dev/null | grep -cx gdm-autologin)" -eq 0 ] && break
       sleep 1
     done
     loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless" {print $1}' |
       xargs -r -n 1 loginctl show-session -p Service --value 2>/dev/null | grep -cx gdm-autologin
   fi
   ```

   - 有効だったときは `Removed '/etc/systemd/system/graphical.target.wants/gnome-headless-session@<USER>.service'.` と出る（既に `disabled` なら何も出ない）
   - セッションで動いていたアプリも閉じる
   - 続いて `0` が出ればよい（このユーザーの `gdm-autologin` のセッションだけを数え、リモートログインのセッションは数えない）
   - `for` の行で、セッションが終わるまで、30 秒まで待つ

1. ドロップインを外す前に入ったリモートログインのセッションが残っていれば、終わらせる。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: USER が空か root。セッションを使うユーザーのシェルで貼り直す' >&2
   else
     for s in $(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless" {print $1}'); do
       [ "$(loginctl show-session "${s}" -p Service --value 2>/dev/null)" = gdm-password ] && loginctl terminate-session "${s}"
     done
     for i in $(seq 1 30); do [ -z "$(pgrep -u "${USER}" -x gnome-shell)" ] && break; sleep 1; done
     loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless"' | wc -l
     pgrep -a -u "${USER}" -x gnome-shell
   fi
   ```

   - `0` が出て、gnome-shell の行が出なければよい
   - そのセッションで開いていたアプリは閉じる。つないでいたクライアントは切れる
   - `sudo` は要らない（自分のセッションは自分で終わらせられる）
   - ユーザーの D-Bus が起動し直される（[注意点](extra/gnome-headless-session.md#注意点)）

1. クライアントの PC から、リモートログインでつなぎ直してログインする。

   - Windows なら「リモート デスクトップ接続」で `<SERVER_IP>`（3389/tcp）につなぎ、GDM のログイン画面からログインする（[gnome-remote-desktop.md 手順 11](gnome-remote-desktop.md#実施手順) と同じ）
   - 上部バーのあるデスクトップが、クライアントの窓の大きさで出ればよい
   - 切断してつなぎ直すと、同じデスクトップに戻る
   - **次の手順は、ログインし終えてから貼る**

1. サーバーで、リモートログインのセッションだけになったかを確かめる。

   ```bash
   for s in $(loginctl list-sessions --no-legend | awk -v u="${USER}" '$3 == u && $7 == "headless" {print $1}'); do
     echo "${s} $(loginctl show-session "${s}" -p Service --value)"
   done
   pgrep -a -u "${USER}" -x gnome-shell
   systemctl is-enabled "gnome-headless-session@${USER}.service"
   ss -Hlnt 'sport = :3389'
   ```

   - `<SESSION_ID> gdm-password` の 1 行だけが出て、`gdm-autologin` の行が無ければよい
   - gnome-shell の行が `<PID> /usr/bin/gnome-shell`（`--virtual-monitor` の無い形）ならよい
   - 続いて `disabled` と、`LISTEN … *:3389 …` の 1 行が出ればよい
