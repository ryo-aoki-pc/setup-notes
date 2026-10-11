# Grok Build をブラウザから操作する手順（Codeg と Caddy / AlmaLinux 10 は systemd のユーザーサービス / Windows 11 はタスク スケジューラ / LAN・VPN 内で HTTPS で使う）

## 実施手順

- [検証記録](verification/grok-build-remote.md)・[参考資料](reference/grok-build-remote.md)・[ロールバックと注意点](extra/grok-build-remote.md)

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のサーバーのもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す
> - **Grok Build を使う一般ユーザー自身の bash（SSH）で実行する**。`sudo -i` や `sudo -iu` で切り替えたシェルは使わない
> - 前提: [AlmaLinux 10 の初期設定の「Grok Build」](almalinux-setup.md#grok-build)で Grok Build を入れてログインしてあること（ブラウザの無いホストは [Grok Build をブラウザの無いホストでログインする](almalinux-setup.md#grok-build-をブラウザの無いホストでログインする)）。[「Codex・Grok のプラグイン」の手順 1](almalinux-setup.md#codexgrok-のプラグイン)の Node.js、[linger](linger.md)、[「ログインと sudo」の手順 3](almalinux-setup.md#ログインと-sudo)（NOPASSWD の sudo）も通す
> - 別の PC からサーバーの SSH にログインでき、サーバーの IPv4 が固定されていることを前提にする。firewalld と SELinux は有効なまま使う
> - スマートフォンから使うときは、スマートフォンを [WireGuard VPN の「クライアントを登録する」](wireguard.md#クライアントを登録する)でクライアントにしておく
> - [ブラウザで開いて Grok を動かす](#ブラウザで開いて-grok-を動かす)の手順 1・3〜6 は別の PC とそのブラウザで、[HTTPS で LAN・VPN に公開する](#https-で-lanvpn-に公開する)の手順 5 は LAN の別の端末で、手順 6・8 はスマートフォンと PC で行う

- 上から順にコードブロックを貼る。[Codeg のサーバーを入れて localhost で起動する](#codeg-のサーバーを入れて-localhost-で起動する)の手順 1 で変数を設定したシェルに貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- Grok Build には、公式の遠隔操作の画面が無い。OSS の [Codeg](https://github.com/spacering-net/codeg)（Apache-2.0）のサーバーを Grok Build と同じホストに常駐させ、ブラウザのチャット形式の画面から Grok Build を動かす。外部のサーバーは通らない
- 通信は HTTPS。OSS の [Caddy](https://caddyserver.com/)（Apache-2.0）を同じホストに置き、Caddy が自分で作る認証局の証明書で受けて、Codeg へ渡す。つなぐ端末には、その認証局のルート証明書を入れる
- 開けるのは 3443/tcp だけで、送信元を指定した帯に絞る。インターネット向けのポート転送は設定しない
- 手順の後: [端末にルート証明書を入れる](#端末にルート証明書を入れる)・[使い方の基本](#使い方の基本)・[端末の grok のセッションを取り込む](#端末の-grok-のセッションを取り込む)・[設定ファイル](#設定ファイル)・[更新](#更新)・[ロールバック](extra/grok-build-remote.md#ロールバック)

> [!WARNING]
> **アクセストークンを知っている人は、ブラウザからこのサーバーで、このユーザーとして Grok Build を動かせる**（ファイルの読み書きとコマンドの実行）。NOPASSWD の sudo があるホストでは、root と同じ重みになる。待ち受ける IP と送信元を絞り、トークンは人に見せない。**Grok の権限モードが「常に許可」だと、送った指示は確認なしで実行される**。「毎回確認」でも、`mkdir` は確認なしで実行された（[注意点](extra/grok-build-remote.md#注意点)）。

### Codeg のサーバーを入れて localhost で起動する

1. 変数を設定する（`SERVER_IP` と `ALLOW_FROM` は必ず値を入れる）。

   ```bash
   SERVER_IP=''                       # サーバーの待ち受け IPv4（例: 192.168.1.10）
   ```

   ```bash
   ALLOW_FROM=''                      # 許可する送信元 IPv4 の CIDR。複数は空白で区切る（例: '10.0.2.0/24 192.168.1.0/24'）
   ```

   ```bash
   {
     CODEG_VERSION=v0.35.1             # 入れる Codeg の版（GitHub のリリースのタグ）
     CADDY_VERSION=2.11.7              # 入れる Caddy の版（v を付けない）
     FW_ZONE=$(sudo firewall-cmd --get-default-zone)
     printf '\n\033[7m 確認 \033[0m\n'
     printf '待ち受け: https://%s:3443\n許可する送信元: %s\n版: Codeg %s / Caddy %s\nfirewalld: %s\n' \
       "${SERVER_IP}" "${ALLOW_FROM}" "${CODEG_VERSION}" "${CADDY_VERSION}" "${FW_ZONE}"
   }
   ```

   - `SERVER_IP` は、スマートフォンや PC から届くサーバーの IPv4。`ip -4 -br addr` で確かめる
   - `ALLOW_FROM` は、サーバーから見えるクライアントの送信元に合わせる。VPN のクライアントの帯と LAN の帯を、空白で区切って並べられる
   - `CODEG_VERSION` と `CADDY_VERSION` は、[Codeg のリリースの一覧](https://github.com/spacering-net/codeg/releases)と [Caddy のリリースの一覧](https://github.com/caddyserver/caddy/releases)で新しい版を確かめて変える
   - 待ち受ける NIC が別の zone に属しているなら、`FW_ZONE=` をその名前に変える
   - 空のままなら先へ進まない
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、この項の手順 1 を貼り直す

1. Grok Build・Node.js・linger・firewalld と、Codeg がまだ無いことを確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     if [ -z "${SERVER_IP}" ] || [ -z "${ALLOW_FROM}" ] || [ -z "${CODEG_VERSION}" ] || [ -z "${CADDY_VERSION}" ] || [ -z "${FW_ZONE}" ]; then
       echo '中断: この項の手順 1 の変数を設定する' >&2
     else
       uname -m
       grok --version
       node --version
       loginctl show-user "$(id -u)" -p Linger
       sudo firewall-cmd --state
       sudo firewall-cmd --get-active-zones
       ss -ltn '( sport >= :3080 and sport <= :3090 ) or ( sport = :3443 )'
       ls -d ~/.local/opt/codeg-server ~/.local/share/codeg ~/.config/codeg-server ~/.config/systemd/user/codeg-server.service ~/.local/opt/caddy ~/.config/caddy
     fi
   }
   ```

   - `aarch64` か `x86_64`、`grok` と `node` の版、`Linger=yes`、`running` が出ればよい
   - `ss` は見出しの 1 行だけ、`ls` は 6 つとも `No such file or directory` になればよい
   - `Linger=no` なら、先に [linger](linger.md) を通す
   - 3080 番か 3443 番に待ち受けがあるか、`ls` が何かを出したら中断する。既存の構築を使うか、[ロールバック](extra/grok-build-remote.md#ロールバック)で消してからやり直す
   - `--get-active-zones` で待ち受ける NIC の zone が `FW_ZONE` と異なっていたら、この項の手順 1 の値を直す

1. 配布物を取得して、SHA-256 を照合する。

   ```bash
   if [ -z "${CODEG_VERSION}" ]; then
     echo '中断: この項の手順 1 の変数を設定する' >&2
   elif [ -e ~/.cache/codeg-server-dl ]; then
     echo '中断: ~/.cache/codeg-server-dl が既にある。中を確かめて消してから貼り直す' >&2
   else
     case "$(uname -m)" in
       aarch64) CODEG_ASSET=codeg-server-linux-arm64 ;;
       x86_64) CODEG_ASSET=codeg-server-linux-x64 ;;
       *) CODEG_ASSET='' ;;
     esac
     mkdir -p ~/.cache/codeg-server-dl &&
     (
       cd ~/.cache/codeg-server-dl &&
       curl -fsSL -O "https://github.com/spacering-net/codeg/releases/download/${CODEG_VERSION}/${CODEG_ASSET}.tar.gz" &&
       curl -fsSL -O "https://github.com/spacering-net/codeg/releases/download/${CODEG_VERSION}/${CODEG_ASSET}.tar.gz.sha256" &&
       printf '\n\033[7m 確認 \033[0m\n' &&
       sha256sum -c "${CODEG_ASSET}.tar.gz.sha256" &&
       if CODEG_LIST=$(tar -tzf "${CODEG_ASSET}.tar.gz"); then
         printf '%s\n' "${CODEG_LIST}" | awk '/^\/|(^|\/)\.\.(\/|$)/ { bad++ } END { print bad+0; exit (bad > 0) }'
       else
         echo '中断: 配布物の一覧を読めない' >&2
         false
       fi
     )
   fi
   ```

   - `codeg-server-linux-….tar.gz: OK` と、その次の行に `0` が出ればよい
   - `OK` が出ない、または `0` 以外が出たら中断する（壊れた配布物か、展開先を外れるパスを含む配布物）
   - `curl: (22)` で止まったら、`CODEG_VERSION` のタグがあるか、サーバーから `github.com` へ HTTPS で接続できるかを確かめる
   - **この項の手順 4 は、同じシェルに続けて貼る**

1. 展開して、自分のホームに置く。

   ```bash
   if [ -z "${CODEG_ASSET}" ]; then
     echo '中断: 同じシェルでこの項の手順 3 を通す' >&2
   elif [ -e ~/.local/opt/codeg-server ]; then
     echo '中断: ~/.local/opt/codeg-server が既にある。上書きしない' >&2
   else
     CODEG_X=$(mktemp -d ~/.cache/codeg-server-x.XXXXXX) &&
     tar -xzf ~/.cache/codeg-server-dl/"${CODEG_ASSET}.tar.gz" -C "${CODEG_X}" &&
     install -d -m 755 ~/.local/opt/codeg-server &&
     install -m 755 "${CODEG_X}/${CODEG_ASSET}/codeg-server" "${CODEG_X}/${CODEG_ASSET}/codeg-mcp" ~/.local/opt/codeg-server/ &&
     cp -r "${CODEG_X}/${CODEG_ASSET}/web" ~/.local/opt/codeg-server/web &&
     rm -r "${CODEG_X}" ~/.cache/codeg-server-dl &&
     printf '\n\033[7m 確認 \033[0m\n' &&
     ~/.local/opt/codeg-server/codeg-server --version &&
     ls ~/.local/opt/codeg-server
   fi
   ```

   - `CODEG_VERSION` と同じ番号（先頭の `v` は付かない）と、`codeg-mcp`・`codeg-server`・`web` が出ればよい
   - 配布物の `codeg-computer-helper` は置かない

1. アクセストークンを作る。

   ```bash
   if [ -e ~/.config/codeg-server/token.env ]; then
     echo '中断: token.env が既にある。作り直さない' >&2
   else
     (umask 077; mkdir -p ~/.config/codeg-server && printf 'CODEG_TOKEN=%s\n' "$(openssl rand -hex 32)" > ~/.config/codeg-server/token.env)
     printf '\n\033[7m 確認 \033[0m\n'
     stat -c '%a %s %n' ~/.config/codeg-server ~/.config/codeg-server/token.env
   fi
   ```

   - `700` で始まる行と、`600 77` で始まる行が出ればよい
   - **トークンの値は表示しない**。ファイルを `cat` しない

1. ユーザーサービスを置いて、localhost で起動する。

   ```bash
   if [ -e ~/.config/systemd/user/codeg-server.service ]; then
     echo '中断: codeg-server.service が既にある。上書きしない' >&2
   elif [ ! -x ~/.local/opt/codeg-server/codeg-server ] || [ ! -s ~/.config/codeg-server/token.env ]; then
     echo '中断: この項の手順 4・5 を通す' >&2
   else
     mkdir -p ~/.config/systemd/user &&
     cat > ~/.config/systemd/user/codeg-server.service <<'EOF'
   # setup-notes: grok-build-remote
   [Unit]
   Description=Codeg server

   [Service]
   Type=simple
   EnvironmentFile=%h/.config/codeg-server/token.env
   Environment=PATH=%h/.grok/bin:%h/.local/bin:/home/linuxbrew/.linuxbrew/bin:/usr/local/bin:/usr/bin
   Environment=CODEG_HOST=127.0.0.1
   Environment=CODEG_PORT=3080
   Environment=CODEG_STATIC_DIR=%h/.local/opt/codeg-server/web
   Environment=CODEG_BRIDGE_PORTS=off
   Environment=CODEG_BROWSER_TUNNEL=off
   ExecStart=%h/.local/opt/codeg-server/codeg-server --supervise
   StandardError=null
   Restart=on-failure
   RestartSec=5

   [Install]
   WantedBy=default.target
   EOF
     systemctl --user daemon-reload &&
     systemctl --user start codeg-server.service
     for i in $(seq 1 30); do ss -ltn '( sport = :3080 )' | grep -q LISTEN && break; sleep 1; done
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl --user is-active codeg-server.service
     ss -ltn '( sport >= :3080 and sport <= :3090 )'
   fi
   ```

   - `active` と、`127.0.0.1:3080` の 1 行だけが出ればよい
   - **`StandardError=null` を外さない**。Codeg は、トークンを指定していても、起動のたびに標準エラーへトークンを出す
   - **`systemd-analyze --user verify` は使わない**。`systemctl --user` がつながらなくなる（[注意点](extra/grok-build-remote.md#注意点)）
   - 本書の `systemctl --user` が `Failed to connect to user scope bus` で失敗したときは、`--machine="$(id -un)@.host"` を付け、同じ一般ユーザーでそのコマンドを実行し直す
   - 起動に失敗したら `~/.local/share/codeg/logs/` のログを見る。SELinux の拒否は `sudo ausearch -m AVC -ts recent` で確かめ、SELinux を無効にしない

1. トークン無しが拒まれることと、トークンがログに出ていないことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   curl -s -o /dev/null -w '%{http_code}\n' -X POST http://127.0.0.1:3080/api/health
   printf 'header = "Authorization: Bearer %s"\n' "$(sed -n 's/^CODEG_TOKEN=//p' ~/.config/codeg-server/token.env)" |
     curl -sS -K - -X POST -w ' %{http_code}\n' http://127.0.0.1:3080/api/health
   (
     if CODEG_JOURNAL=$(journalctl --user -u codeg-server.service --no-pager); then
       printf '%s\n' "${CODEG_JOURNAL}" | grep -cFf <(sed -n 's/^CODEG_TOKEN=//p' ~/.config/codeg-server/token.env)
     else
       echo '中断: journal を読めない' >&2
       false
     fi
   )
   ps -eo args | grep -cFf <(sed -n 's/^CODEG_TOKEN=//p' ~/.config/codeg-server/token.env)
   ```

   - 順に、`401`、`{"status":"ok","version":"…"} 200`、`0`、`0` が出ればよい
   - `0` 以外が出たら、トークンが journal かプロセスの一覧に出ている。中断して、この項の手順 6 のユニットを確かめる
   - **トークンを、コマンドの引数に書かない**（`curl -H "…$TOKEN"` や `grep "$TOKEN"` は、実行中のプロセスの一覧にトークンを出す）

### ブラウザで開いて Grok を動かす

1. 別の PC で、SSH のトンネルを開く。

   - クライアントの端末で `ssh -N -o ExitOnForwardFailure=yes -L 127.0.0.1:3080:127.0.0.1:3080 <OSユーザー>@<SERVER_IP>` を実行する。`<OSユーザー>` はサーバーで Grok Build を使う一般ユーザー、`<SERVER_IP>` は[Codeg のサーバーを入れて localhost で起動する](#codeg-のサーバーを入れて-localhost-で起動する)の手順 1 の IPv4 に置き換える
   - クライアントの 3080 番が使用中なら、`-L` の最初の `3080` を空いている番号（例: `3081`）にし、この項の手順 3 の URL も同じ番号にする
   - トンネルの端末は開いたままにする

1. サーバーで、トークンを表示する。

   ```bash
   sed -n 's/^CODEG_TOKEN=//p' ~/.config/codeg-server/token.env
   ```

   - 64 文字の 16 進が出る。この項の手順 3 でブラウザに貼る
   - **画面を人に見せない。貼り終えたら `clear` で消す**

1. 別の PC のブラウザで開き、トークンを入れる。

   - `http://localhost:3080/` を開く
   - 「アクセストークン」に、この項の手順 2 の 64 文字を貼り、「接続」を押す
   - 会話の画面（「今日は何をしましょうか？」）が出ればよい
   - ブラウザは、このトークンを覚える。共用の PC のブラウザでは開かない

1. ブラウザで、Grok の権限モードをスマート自動承認にする。

   - アドレス欄の `/workspace` を `/settings/agents` に変えて開き、「エージェント一覧」の `Grok` を選ぶ
   - 承認を減らして使うこの手順では、「権限モード」で「スマート自動承認」（`auto`）を選び、「Grok 設定を保存」を押す
   - 保存後に「スマート自動承認」が選ばれていればよい。選べない・保存できない場合は、権限モードの設定は未完了として先へ進まない
   - **ここで保存すると、`~/.grok/config.toml` の `permission_mode` が書き換わり、端末の `grok` にも効く**
   - `permission_mode` の行が無い Grok Build（入れたままの状態）は、確認を出すモードで動く
   - 変えた設定は、新しく開いた会話から効く。この項の手順 5・6 で、そのモードで会話を始め、応答を確かめるまでは利用の確認は未完了
   - 終わったら、アドレス欄を `/workspace` に戻す

1. ブラウザで、プロジェクトのフォルダを開き、Grok を選ぶ。

   - 左の「フォルダを開く」を押し、サーバーの中のプロジェクトのディレクトリを選んで「次へ」「完了」と進む
   - 左の一覧に出たフォルダの行の「新しい会話」を押す
   - 入力欄の上のエージェントの一覧で `Grok` を選ぶ。入力欄の下が「エージェント接続: 接続済み」になり、モデルの名前が出ればよい
   - **Codeg を起動して最初の会話は、Grok Build の既定と違うモデルで動いた**（検証時は、既定が Grok 4.7 のところ Grok 4.6）。モデルの欄を確かめ、違っていたら「新しい会話」を開き直す

1. ブラウザで、指示を送り、承認の確認に答える。

   - 入力欄に指示を書いて Enter で送る
   - 承認の確認は、入力欄の上に出る。ファイルの変更は「Edit `<パス>`」に差分が付き、「Yes, allow all edits during this session」「Yes」「No, and tell Grok what to do differently」から選ぶ
   - コマンドの実行は「Execute `<コマンド>`」と出て、「Yes, and don't ask again for bash commands」「Yes, proceed」「No, and tell Grok what to do differently」「No, and don't ask again for this command」から選ぶ
   - **中身を読んでから答える**。「Yes, allow all …」「Yes, and don't ask again …」は、以後の確認を省く
   - 「No, and tell Grok what to do differently」を選ぶと、その操作は実行されず、「1 件失敗」と出てターンが止まる
   - 終わると、変えたファイルが「変更されたファイル」にまとまって出る

1. サーバーで、Grok Build のプロセスを確かめる。

   ```bash
   pgrep -af 'grok .*agent stdio'
   ```

   - `…/.grok/bin/grok --no-auto-update agent stdio` の行が出ればよい。Codeg が、開いている会話ごとに Grok Build を起動する
   - `--permission-mode bypassPermissions` が付いていたら、「常に許可」で動いている

### HTTPS で LAN・VPN に公開する

1. Caddy の配布物を取得してチェックサムを照合し、自分のホームに置く。

   ```bash
   if [ -z "${CADDY_VERSION}" ]; then
     echo '中断: 「Codeg のサーバーを入れて localhost で起動する」の手順 1 の変数を設定する' >&2
   elif [ -e ~/.cache/caddy-dl ] || [ -e ~/.local/opt/caddy ]; then
     echo '中断: ~/.cache/caddy-dl か ~/.local/opt/caddy が既にある。上書きしない' >&2
   else
     case "$(uname -m)" in
       aarch64) CADDY_ASSET="caddy_${CADDY_VERSION}_linux_arm64.tar.gz" ;;
       x86_64) CADDY_ASSET="caddy_${CADDY_VERSION}_linux_amd64.tar.gz" ;;
       *) CADDY_ASSET='' ;;
     esac
     mkdir -p ~/.cache/caddy-dl &&
     (
       cd ~/.cache/caddy-dl &&
       curl -fsSL -O "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/${CADDY_ASSET}" &&
       curl -fsSL -O "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_checksums.txt" &&
       printf '\n\033[7m 確認 \033[0m\n' &&
       grep -E "  ${CADDY_ASSET}\$" "caddy_${CADDY_VERSION}_checksums.txt" | sha512sum -c - &&
       tar -xzf "${CADDY_ASSET}" &&
       install -d -m 755 ~/.local/opt/caddy &&
       install -m 755 caddy ~/.local/opt/caddy/caddy
     ) &&
     rm -r ~/.cache/caddy-dl &&
     ~/.local/opt/caddy/caddy version
   fi
   ```

   - `caddy_…_linux_….tar.gz: OK` と、`v` で始まる `CADDY_VERSION` と同じ番号が出ればよい
   - `OK` が出なければ中断する

1. Caddy の設定とユーザーサービスを書いて、設定を検査する。

   ```bash
   if [ -z "${SERVER_IP}" ]; then
     echo '中断: 「Codeg のサーバーを入れて localhost で起動する」の手順 1 の変数を設定する' >&2
   elif [ -e ~/.config/caddy/Caddyfile ] || [ -e ~/.config/systemd/user/codeg-caddy.service ]; then
     echo '中断: Caddyfile か codeg-caddy.service が既にある。上書きしない' >&2
   else
     mkdir -p ~/.config/caddy ~/.config/systemd/user &&
     cat > ~/.config/caddy/Caddyfile <<EOF
   # setup-notes: grok-build-remote
   {
       admin off
       auto_https disable_redirects
       skip_install_trust
       pki {
           ca local {
               name "Codeg $(hostname -s)"
           }
       }
   }

   https://${SERVER_IP}:3443 {
       bind ${SERVER_IP}
       tls internal
       handle /caddy-root.crt {
           root * "{\$HOME}/.local/share/caddy/pki/authorities/local"
           rewrite * /root.crt
           file_server
       }
       handle {
           reverse_proxy 127.0.0.1:3080
       }
   }
   EOF
     cat > ~/.config/systemd/user/codeg-caddy.service <<'EOF'
   # setup-notes: grok-build-remote
   [Unit]
   Description=Caddy (HTTPS for Codeg)

   [Service]
   Type=simple
   ExecStart=%h/.local/opt/caddy/caddy run --config %h/.config/caddy/Caddyfile --adapter caddyfile
   Restart=on-failure
   RestartSec=5

   [Install]
   WantedBy=default.target
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     ~/.local/opt/caddy/caddy validate --config ~/.config/caddy/Caddyfile --adapter caddyfile 2>&1 | tail -n 1
   fi
   ```

   - `Valid configuration` が出ればよい
   - Caddy は `https://<SERVER_IP>:3443` で受け、同じホストの Codeg（`127.0.0.1:3080`）へ渡す。Codeg の待ち受けは `127.0.0.1` のまま変えない
   - 認証局の名前は `Codeg <ホスト名>` になる。端末に入れたルート証明書を、ホストごとに見分けるための名前

1. Caddy を起動し、2 つのサービスの自動起動を有効にして、サーバー自身から HTTPS を確かめる。

   ```bash
   if [ -z "${SERVER_IP}" ]; then
     echo '中断: 「Codeg のサーバーを入れて localhost で起動する」の手順 1 の変数を設定する' >&2
   else
     systemctl --user daemon-reload &&
     systemctl --user enable codeg-server.service &&
     systemctl --user enable --now codeg-caddy.service
     for i in $(seq 1 30); do [ -s ~/.local/share/caddy/pki/authorities/local/root.crt ] && ss -ltn '( sport = :3443 )' | grep -q LISTEN && break; sleep 1; done
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl --user is-active codeg-server.service codeg-caddy.service
     ss -ltn '( sport = :3080 or sport = :3443 )'
     curl -s --cacert ~/.local/share/caddy/pki/authorities/local/root.crt -o /dev/null -w '%{http_code}\n' -X POST "https://${SERVER_IP}:3443/api/health"
     curl -s -o /dev/null "https://${SERVER_IP}:3443/"
     echo "curl の終了コード: $?"
   fi
   ```

   - `Created symlink …` が 2 回出た後、`active` が 2 行、待ち受けが `127.0.0.1:3080` と `<SERVER_IP>:3443` の 2 行、`401`、`curl の終了コード: 60` が出ればよい
   - `60` は、ルート証明書を信頼していない相手として、証明書の検証で止まったことを示す（正常）
   - 認証局の鍵と証明書は、Caddy が初回の起動で `~/.local/share/caddy/` に作る。**`root.key` を、読まない・写さない・人に渡さない**

1. 指定した送信元・宛先・ポートで、この手順専用の firewalld の規則を追加する。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     if [ -z "${SERVER_IP}" ] || [ -z "${ALLOW_FROM}" ] || [ -z "${FW_ZONE}" ]; then
       echo '中断: 「Codeg のサーバーを入れて localhost で起動する」の手順 1 の変数を設定する' >&2
     else
       read -r -a CODEG_SRCS <<<"${ALLOW_FROM}"
       for src in "${CODEG_SRCS[@]}"; do
         CODEG_RULE="rule family=\"ipv4\" priority=\"100\" source address=\"${src}\" destination address=\"${SERVER_IP}\" port port=\"3443\" protocol=\"tcp\" accept"
         sudo firewall-cmd --permanent --zone="${FW_ZONE}" --add-rich-rule="${CODEG_RULE}" &&
         sudo firewall-cmd --zone="${FW_ZONE}" --add-rich-rule="${CODEG_RULE}"
       done
       sudo firewall-cmd --permanent --zone="${FW_ZONE}" --list-rich-rules
       sudo firewall-cmd --zone="${FW_ZONE}" --list-rich-rules
     fi
   }
   ```

   - 送信元ごとに `success` が 2 回ずつ出た後、runtime と permanent に、送信元ごとの 3443/tcp の規則があればよい
   - 3080 番は開けない。Codeg へは、Caddy を通してだけ届く
   - **送信元を制限する場合**、既存の zone が `trusted`・`ACCEPT`、または同じポートへの広い許可があると、この規則だけでは絞れない
   - 追加できた規則を外す場合は[ロールバック](extra/grok-build-remote.md#ロールバック)の手順 2 を使う

1. LAN の別の端末で、HTTPS で届くことを確かめる。

   - `ALLOW_FROM` に入っている端末で `curl -sk -o /dev/null -w '%{http_code}\n' https://<SERVER_IP>:3443/` を実行し、`200` が出ればよい（`-k` は、ルート証明書を入れる前なので付ける）
   - `ALLOW_FROM` に入っていない端末があれば、同じコマンドに `-m 6` を足して実行し、6 秒待って `000` が出ることも確かめる
   - `http://<SERVER_IP>:3080/` は、どの端末からも開けない

1. スマートフォンと PC に、このサーバーのルート証明書を入れる。

   - [端末にルート証明書を入れる](#端末にルート証明書を入れる)の手順 1・3〜6 を通す
   - スマートフォンは、先に WireGuard のアプリでトンネルを有効にする（LAN の Wi-Fi にいて、LAN の帯を `ALLOW_FROM` に入れてあれば要らない）

1. サーバーで、トークンを QR コードで表示する。

   ```bash
   sed -n 's/^CODEG_TOKEN=//p' ~/.config/codeg-server/token.env | qrencode -t ansiutf8
   ```

   - 端末に QR コードが出る。スマートフォンのカメラで読み、出てきた 64 文字をコピーする
   - `qrencode` が無ければ `brew install qrencode` で入れる（[Homebrew](almalinux-setup.md#homebrew)）
   - **画面を人に見せない。読み終えたら `clear` で消す**

1. スマートフォンで、ブラウザで開いてトークンを入れ、指示を送る。

   - ブラウザで `https://<SERVER_IP>:3443` を開く。警告が出ずに、ログインの画面（「アクセストークン」と「接続」）が出ればよい
   - 「アクセストークン」にコピーした 64 文字を貼り、「接続」を押す
   - [ブラウザで開いて Grok を動かす](#ブラウザで開いて-grok-を動かす)の手順 5・6 と同じ操作で、会話を開いて指示を送る
   - PC のブラウザからも、同じ URL とトークンで開ける。PC で開いた会話も、同じ一覧に出る

---

## 端末にルート証明書を入れる

- 両 OS に共通の節。Codeg を置いたホストごとに、そのホストの Caddy が作った認証局のルート証明書を、つなぐ端末に 1 つずつ入れる
- 入れると、ブラウザが警告を出さなくなり、偽のサーバーを見分けられる
- ルート証明書（`root.crt`）は公開してよい。各ホストが `https://<ホストの IP>:3443/caddy-root.crt` で配る
- **入れる前か後に、必ず指紋を照合する**。この節の手順 1・2 でホストに出した指紋と、端末に出た指紋が同じであること

1. AlmaLinux 10 のホストのときだけ、ホストで、ルート証明書の名前と指紋を表示する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   openssl x509 -in ~/.local/share/caddy/pki/authorities/local/root.crt -noout -subject -enddate -fingerprint -sha256
   ```

   - `subject=CN=Codeg <ホスト名> - <年> ECC Root`、期限（10 年後）、`sha256 Fingerprint=` の 3 行が出る。指紋を控える

1. Windows 11 のホストのときだけ、ホストで、ルート証明書の名前と指紋を表示する。

   ```powershell
   $c = New-Object Security.Cryptography.X509Certificates.X509Certificate2("$env:APPDATA\Caddy\pki\authorities\local\root.crt")
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $c.Subject
   $c.NotAfter
   (([Security.Cryptography.SHA256]::Create().ComputeHash($c.RawData) | ForEach-Object { $_.ToString('X2') }) -join ':')
   ```

   - `CN=Codeg <PC の名前> - <年> ECC Root`、期限、`:` で区切った指紋が出る。指紋を控える

1. スマートフォン（Android）で、ルート証明書を取り込む。

   - ブラウザで `https://<ホストの IP>:3443/caddy-root.crt` を開く。警告が出たら「詳細設定」から進む（この 1 回だけ）。証明書のファイルがダウンロードされる
   - 設定の「セキュリティ」→「暗号化と認証情報」→「証明書のインストール」→「CA 証明書」で、ダウンロードしたファイルを選ぶ（メニューの名前は機種で少し違う）
   - 設定の「信頼できる認証情報」→「ユーザー」で、入れた証明書を開き、SHA-256 の指紋がこの節の手順 1・2 のものと同じことを確かめる
   - 違っていたら、その証明書を削除する

1. Windows の PC で、ルート証明書を取得して、名前と指紋を表示する。

   ```powershell
   $CODEG_URL = ''                       # ホストの URL（例: https://192.168.1.10:3443）。<CODEG_URL>
   ```

   ```powershell
   if (-not $CODEG_URL) { Write-Error '中断: $CODEG_URL が空のまま' } else {
     $crt = Join-Path $env:TEMP ('codeg-root-' + ([Uri]$CODEG_URL).Host + '.crt')
     & "$env:WINDIR\System32\curl.exe" -sk -o $crt "$CODEG_URL/caddy-root.crt"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $c = New-Object Security.Cryptography.X509Certificates.X509Certificate2($crt)
     $c.Subject
     (([Security.Cryptography.SHA256]::Create().ComputeHash($c.RawData) | ForEach-Object { $_.ToString('X2') }) -join ':')
   }
   ```

   - 管理者ではない Windows PowerShell に貼る。Codeg を置いた PC 自身にも、同じ手順で入れる
   - 名前と指紋が、この節の手順 1・2 でホストに出したものと同じなら、手順 5 へ進む
   - **違っていたら、取り込まない**（途中で差し替えられている）
   - ホストが 2 台あるときは、この節の手順 4・5 を、`$CODEG_URL` を変えて 2 回通す

1. Windows の PC で、指紋が同じだったルート証明書を取り込む。

   ```powershell
   Import-Certificate -FilePath $crt -CertStoreLocation Cert:\CurrentUser\Root
   ```

   - 「セキュリティ警告」の画面が出たら、拇印を確かめて「はい」を押す
   - 取り込んだ証明書の `Thumbprint` と `Subject` が出ればよい
   - 取り込む先は、このユーザーの「信頼されたルート証明機関」。PC のほかのユーザーには効かない

1. 端末のブラウザを開き直して、警告が出ずに開けることを確かめる。

   - `https://<ホストの IP>:3443` を開き、警告が出ずにログインの画面が出ればよい
   - 警告が出るときは、入れたルート証明書が、そのホストのものかを確かめる
   - AlmaLinux 10 のホストは、URL の IP が、ホストの待ち受けの IP と同じかも確かめる（証明書は、その IP 宛てに作られる）

---

## 使い方の基本

| したいこと | 操作 |
|---|---|
| 開く | ルート証明書を入れた端末のブラウザで `https://<ホストの IP>:3443` |
| 会話を始める | 左の一覧のフォルダの行の「新しい会話」（どの画面でも `Ctrl+T`）。エージェントの一覧で `Grok` を選ぶ |
| 別のプロジェクトで使う | 左の「フォルダを開く」で、ホストの中のディレクトリを足す |
| 前の会話に戻る | 左の一覧の会話を押す。サービスを起動し直しても、会話は残る |
| 承認の確認に答える | 入力欄の上に出る選択肢から選ぶ（[ブラウザで開いて Grok を動かす](#ブラウザで開いて-grok-を動かす)の手順 6） |
| 変えたファイルを見る | 会話の中の「変更されたファイル」 |
| 確認の出方を変える | `/settings/agents` の `Grok` の「権限モード」（[ブラウザで開いて Grok を動かす](#ブラウザで開いて-grok-を動かす)の手順 4） |
| 端末の `grok` で始めた作業を、ブラウザで続ける | [端末の grok のセッションを取り込む](#端末の-grok-のセッションを取り込む) |
| ブラウザで始めた会話を、端末で確かめる | そのディレクトリで `grok sessions list`。Codeg で作った会話も一覧に出る |
| 止める・始める | `systemctl --user stop codeg-caddy.service codeg-server.service`・`systemctl --user start codeg-server.service codeg-caddy.service`（Windows 11 は [Windows 11 で止める・もう一度始める](#windows-11-で止めるもう一度始める)） |

---

## 端末の grok のセッションを取り込む

- 端末の `grok` で始めた会話を、Codeg の画面に取り込んで続ける。両 OS で同じ操作
- 取り込みの一覧には、このホストのほかのエージェントとプロジェクトのセッションも出る

1. ブラウザで、取り込みの画面を開く。

   - アドレス欄の `/workspace` を `/import-sessions` に変えて開く
   - プロジェクトのディレクトリごとに、取り込めるセッションが並ぶ。Codeg で作った会話には「インポート済み」と出る

1. 取り込むセッションを選んで、取り込む。

   - 取り込むセッションの行の先頭を押して選び、右下の「選択項目をインポート」を押す
   - 「インポート完了」に、インポートした件数と「失敗 0」が出ればよい
   - 「すべて選択」は、ほかのプロジェクトのセッションもまとめて取り込む

1. 取り込んだ会話を開いて、続きを送る。

   - アドレス欄を `/workspace` に戻し、左の一覧から取り込んだ会話を押す
   - 端末での指示と応答が表示される。続きの指示を送ると、前の応答を踏まえて答える

---

## 設定ファイル

| 場所（AlmaLinux 10） | 場所（Windows 11） | 中身 |
|---|---|---|
| `~/.local/opt/codeg-server/` | `%LOCALAPPDATA%\codeg-server\` | `codeg-server`・`codeg-mcp` と、画面のファイル（`web`） |
| `~/.config/codeg-server/token.env` | `%LOCALAPPDATA%\codeg-server\token.txt` | アクセストークン。持ち主だけが読める |
| `~/.config/systemd/user/codeg-server.service` | `%LOCALAPPDATA%\codeg-server\start-codeg-server.ps1` と、タスク `codeg-server` | 待ち受ける IP（`CODEG_HOST`）などの設定と、起動のしかた |
| `~/.local/share/codeg/` | `%APPDATA%\codeg\` | 会話と設定の DB（`codeg.db`）と、ログ（`logs`） |
| `~/.local/opt/caddy/caddy` | `%LOCALAPPDATA%\codeg-caddy\caddy.exe` | Caddy の実行ファイル |
| `~/.config/caddy/Caddyfile` | `%LOCALAPPDATA%\codeg-caddy\Caddyfile` | HTTPS で待ち受ける IP とポート、Codeg への渡し先、認証局の名前 |
| `~/.config/systemd/user/codeg-caddy.service` | `%LOCALAPPDATA%\codeg-caddy\start-caddy-hidden.ps1` と、タスク `codeg-caddy` | Caddy の起動のしかた |
| — | `%LOCALAPPDATA%\codeg-server\HiddenLauncher.cs` と `codeg-hidden-launcher.exe` | 両タスクで使う、コンソールを作らないランチャー |
| — | `%LOCALAPPDATA%\codeg-server\startup-backup-*\` | 既存のタスクを切り替えるときの XML の控え |
| `~/.local/share/caddy/` | `%APPDATA%\Caddy\` | Caddy が作る認証局（`pki/authorities/local/` の `root.crt` と `root.key`）と、サーバーの証明書。`root.key` は外に出さない |
| `~/.codeg/` | `%USERPROFILE%\.codeg\` | Codeg が置くスキル |
| `~/.grok/` | `%USERPROFILE%\.grok\` | Grok Build の設定・ログイン・セッション（[Grok Build の設定ファイル](almalinux-setup.md#grok-build-の設定ファイル)）。Codeg は、ここのセッションをそのまま使う |

- `CODEG_BRIDGE_PORTS=off` は、開発サーバー用の追加のポート（3081〜3090）を開けない設定。`CODEG_BROWSER_TUNNEL=off` は、Codeg のデスクトップアプリからの中継を止める設定
- トークンを替えるときは、トークンのファイルを作り直して、Codeg のサービス（Windows 11 はタスク）を起動し直す。ブラウザは入り直しになる
- ホストの IP を変えたときは、`Caddyfile` の 2 か所の IP と、ファイアウォールの規則の宛先を直して、Caddy を起動し直す。サーバーの証明書は、その IP 宛てに作られる

---

## 更新

- AlmaLinux 10 の手順。Windows 11 は [Windows 11 の更新](#windows-11-の更新)
- 画面の右下に「新バージョン」と出たら、新しい版がある。画面からは入れ替えず、この節の手順で、SHA-256 を照合してから置き換える
- Grok Build は、Codeg からは上がらない（Codeg は `--no-auto-update` を付けて起動する）。端末で `grok update` を実行して上げる
- この節は Codeg の更新。Caddy の更新は、この手順書では確かめていない（配布物を取得して照合し、`codeg-caddy.service` を止めて `~/.local/opt/caddy/caddy` を置き換え、始める形になる）

1. 上げる版を設定する。

   ```bash
   CODEG_VERSION=''                   # 上げる版（GitHub のリリースのタグ。例: v0.35.1）
   ```

   - [リリースの一覧](https://github.com/spacering-net/codeg/releases)で確かめる

1. 配布物を取得して、SHA-256 を照合する。

   - [Codeg のサーバーを入れて localhost で起動する](#codeg-のサーバーを入れて-localhost-で起動する)の手順 3 のブロックを貼る
   - **この節の手順 3 は、同じシェルに続けて貼る**

1. サービスを止めて置き換え、起動し直す。

   ```bash
   if [ -z "${CODEG_ASSET}" ] || [ ! -s ~/.cache/codeg-server-dl/"${CODEG_ASSET}.tar.gz" ]; then
     echo '中断: 同じシェルでこの節の手順 2 を通す' >&2
   elif [ -e ~/.local/opt/codeg-server.prev ]; then
     echo '中断: ~/.local/opt/codeg-server.prev が既にある。前の更新の残りを確かめて消す' >&2
   else
     if CODEG_X=$(mktemp -d ~/.cache/codeg-server-x.XXXXXX) &&
     tar -xzf ~/.cache/codeg-server-dl/"${CODEG_ASSET}.tar.gz" -C "${CODEG_X}" &&
     systemctl --user stop codeg-server.service &&
     mv ~/.local/opt/codeg-server ~/.local/opt/codeg-server.prev &&
     install -d -m 755 ~/.local/opt/codeg-server &&
     install -m 755 "${CODEG_X}/${CODEG_ASSET}/codeg-server" "${CODEG_X}/${CODEG_ASSET}/codeg-mcp" ~/.local/opt/codeg-server/ &&
     cp -r "${CODEG_X}/${CODEG_ASSET}/web" ~/.local/opt/codeg-server/web &&
     rm -r "${CODEG_X}" ~/.cache/codeg-server-dl &&
     systemctl --user start codeg-server.service; then
       for i in $(seq 1 30); do ss -ltn '( sport = :3080 )' | grep -q LISTEN && break; sleep 1; done
       printf '\n\033[7m 確認 \033[0m\n'
       ~/.local/opt/codeg-server/codeg-server --version
       systemctl --user is-active codeg-server.service
       ss -ltn '( sport >= :3080 and sport <= :3090 )'
     else
       echo '中断: 更新が途中で止まった。前の版の退避先の有無と、直前のエラーを確かめる' >&2
       false
     fi
   fi
   ```

   - 上げた版の番号、`active`、今までと同じ待ち受けの 1 行が出ればよい
   - 動いていた Grok Build のプロセスは、サービスと一緒に止まる。会話の履歴は残り、ブラウザは入り直さずに使える
   - 起動しないときは、まず `~/.local/opt/codeg-server.prev/codeg-server` が残っていることを確かめる。残っていれば、`systemctl --user stop codeg-server.service` の後、`~/.local/opt/codeg-server` を消して `~/.local/opt/codeg-server.prev` を元の名前に戻し、`start` する
   - 退避先が無ければ、現行の `~/.local/opt/codeg-server` は消さない。直前のエラーの原因を直し、現行の本体が残っていることを確かめてから `systemctl --user start codeg-server.service` で再開する

1. ブラウザで動くことを確かめてから、前の版を消す。

   ```bash
   rm -r ~/.local/opt/codeg-server.prev
   ```

   - 会話の一覧が残っていて、画面の右下の「新バージョン」が消えていればよい

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows の PC のデスクトップで行う**。[Windows 11 で Codeg のサーバーを入れて起動する](#windows-11-で-codeg-のサーバーを入れて起動する)の手順 1 で開いた、**管理者ではない** Windows PowerShell（5.1）に貼る。[Windows 11 で HTTPS で LAN・VPN に公開する](#windows-11-で-https-で-lanvpn-に公開する)の手順 3 だけは、管理者の Windows PowerShell に貼る
> - **SSH でログインしたシェルには貼らない**。Administrators の一員の SSH のセッションは管理者の権限を持つので、そこから始めると Codeg と Grok Build が管理者の権限で動く
> - 前提: [Windows 11 の初期設定の「貼り付けの設定」の手順 1〜4](windows-setup.md#貼り付けの設定)、[「Grok Build」](windows-setup.md#grok-build)（導入とログイン）、[「Codex・Grok のプラグイン」](windows-setup.md#codexgrok-のプラグイン)の Node.js、[「ネットワークとリモート」の手順 1](windows-setup.md#ネットワークとリモート)（LAN の接続をプライベートにする。つなぐ拠点ごとに行う）
> - Codeg は、管理者ではない自分のユーザーとして、サインインしている間だけ動く（この節のタスク）
> - PC の IP は、固定でなくてよい。ホスト側の受信インターフェースがプライベートなら、有線 LAN・Wi-Fi・VPN を含む全接続種別で、全送信元の IPv4・IPv6 を許可する
> - スマートフォンから LAN の外で使うときは、スマートフォンを [WireGuard VPN の「クライアントを登録する」](wireguard.md#クライアントを登録する)でクライアントにしておく
> - [Windows 11 で HTTPS で LAN・VPN に公開する](#windows-11-で-https-で-lanvpn-に公開する)の手順 5 は LAN の別の端末で、手順 6・8 はスマートフォンと PC で行う

- 上から順にコードブロックを貼る。[Windows 11 で Codeg のサーバーを入れて起動する](#windows-11-で-codeg-のサーバーを入れて起動する)の手順 2 で変数を設定した PowerShell に貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 通信は HTTPS。AlmaLinux 10 と同じく、Caddy を同じ PC に置いて、Codeg へ渡す
- Windows 11 では、Caddy が待ち受ける IP を決めない。受信の規則は Private の全送信元を許可し、Public・Domain を遮断する
- 画面の操作は、[実施手順](#実施手順)の AlmaLinux 10 と同じ。手順の後は[端末にルート証明書を入れる](#端末にルート証明書を入れる)・[使い方の基本](#使い方の基本)・[端末の grok のセッションを取り込む](#端末の-grok-のセッションを取り込む)・[Windows 11 の既存の受信規則を Private の全送信元に切り替える](#windows-11-の既存の受信規則を-private-の全送信元に切り替える)・[Windows 11 の既存のタスクを非表示起動に切り替える](#windows-11-の既存のタスクを非表示起動に切り替える)・[Windows 11 で止める・もう一度始める](#windows-11-で止めるもう一度始める)・[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/grok-build-remote.md#windows-11-のロールバック)

> [!WARNING]
> **アクセストークンを知っている人は、ブラウザからこの PC で、このユーザーとして Grok Build を動かせる**（ファイルの読み書きとコマンドの実行）。Windows の Grok Build には sandbox が無い。Private の全送信元が接続画面へ届くので、トークンは人に見せない。**Grok の権限モードが「常に許可」だと、送った指示は確認なしで実行される**（[注意点](extra/grok-build-remote.md#注意点)）。

### Windows 11 で Codeg のサーバーを入れて起動する

1. Windows で、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」をそのまま開く（「管理者として実行」にしない）
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする

1. 変数を設定する。

   ```powershell
   $CODEG_VERSION = 'v0.35.1'            # 入れる Codeg の版（GitHub のリリースのタグ）
   $CADDY_VERSION = '2.11.7'             # 入れる Caddy の版（v を付けない）
   $CODEG_DIR = "$env:LOCALAPPDATA\codeg-server"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'CODEG_VERSION = {0}' -f $CODEG_VERSION
   'CADDY_VERSION = {0}' -f $CADDY_VERSION
   'CODEG_DIR     = {0}' -f $CODEG_DIR
   ```

   - `CODEG_VERSION` と `CADDY_VERSION` は、[Codeg のリリースの一覧](https://github.com/spacering-net/codeg/releases)と [Caddy のリリースの一覧](https://github.com/caddyserver/caddy/releases)で新しい版を確かめて変える
   - **新しい PowerShell を開いたら**、この項の手順 2 のブロックを貼り直してから先へ進む

1. Grok Build・Node.js・LAN の接続と、Codeg がまだ無いことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   grok --version
   node --version
   ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
   Get-NetConnectionProfile | Format-Table InterfaceAlias, NetworkCategory -AutoSize
   Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -eq 3443 -or ($_.LocalPort -ge 3080 -and $_.LocalPort -le 3090) } | Format-Table LocalAddress, LocalPort, OwningProcess -AutoSize
   Test-Path $CODEG_DIR, "$env:APPDATA\codeg", "$env:LOCALAPPDATA\codeg-caddy"
   Get-ScheduledTask -TaskName 'codeg-server', 'codeg-caddy' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   ```

   - `grok` と `node` の版、`False`（管理者ではない）、LAN の接続の `Private` が出ればよい
   - その後は、待ち受けの表が出ず、`False` が 3 行出て、タスクの表も出なければよい
   - 最初の `False` が `True` なら、管理者の窓で開いている。この項の手順 1 からやり直す
   - `Public` なら、[Windows 11 の初期設定の「ネットワークとリモート」の手順 1](windows-setup.md#ネットワークとリモート)を通す
   - 待ち受け・`True`・タスクのどれかが出たら、既存の構築がある。[Windows 11 のロールバック](extra/grok-build-remote.md#windows-11-のロールバック)で消してからやり直す

1. 配布物を取得して SHA-256 を照合し、自分のユーザーの場所に置く。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $curl = "$env:WINDIR\System32\curl.exe"
     $tmp = "$env:TEMP\codeg-server-setup"
     if (-not $CODEG_VERSION -or -not $CODEG_DIR) { Write-Error '中断: この項の手順 2 の変数を設定する'; return }
     if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { Write-Error "中断: この手順は $env:PROCESSOR_ARCHITECTURE の Windows を扱わない"; return }
     if (Test-Path -LiteralPath $CODEG_DIR) { Write-Error "中断: $CODEG_DIR が既にある。上書きしない"; return }
     if (Test-Path -LiteralPath $tmp) { Write-Error "中断: $tmp が既にある。中を確かめて消してから貼り直す"; return }
     New-Item -ItemType Directory -Path $tmp | Out-Null
     $url = "https://github.com/spacering-net/codeg/releases/download/$CODEG_VERSION/codeg-server-windows-x64.zip"
     & $curl -fsSL -o "$tmp\codeg-server-windows-x64.zip" $url
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: zip を取れない'; return }
     & $curl -fsSL -o "$tmp\codeg-server-windows-x64.zip.sha256" "$url.sha256"
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: .sha256 を取れない'; return }
     $want = ((Get-Content -LiteralPath "$tmp\codeg-server-windows-x64.zip.sha256" -Raw) -split '\s+')[0]
     if ((Get-FileHash -LiteralPath "$tmp\codeg-server-windows-x64.zip" -Algorithm SHA256).Hash -ne $want) { Write-Error '中断: sha256 が一致しない'; return }
     Expand-Archive -LiteralPath "$tmp\codeg-server-windows-x64.zip" -DestinationPath $tmp
     New-Item -ItemType Directory -Path $CODEG_DIR | Out-Null
     Copy-Item -LiteralPath "$tmp\codeg-server-windows-x64\codeg-server.exe", "$tmp\codeg-server-windows-x64\codeg-mcp.exe" -Destination $CODEG_DIR
     Copy-Item -LiteralPath "$tmp\codeg-server-windows-x64\web" -Destination $CODEG_DIR -Recurse
     Remove-Item -LiteralPath $tmp -Recurse -Force
     'sha256 一致'
     & "$CODEG_DIR\codeg-server.exe" --version
     Get-ChildItem $CODEG_DIR | Format-Table Mode, Name, Length -AutoSize
   }
   ```

   - `sha256 一致`、`CODEG_VERSION` と同じ番号（先頭の `v` は付かない）、`web`・`codeg-mcp.exe`・`codeg-server.exe` が出ればよい
   - 実行ファイルに Authenticode の署名は無い。SHA-256 の照合だけで確かめる
   - 配布物の `codeg-computer-helper.exe` は置かない。PATH は変えない

1. アクセストークンを作る。

   ```powershell
   $f = Join-Path $env:LOCALAPPDATA 'codeg-server\token.txt'
   if (Test-Path -LiteralPath $f) { Write-Error '中断: token.txt が既にある。作り直さない' } else {
     $b = New-Object byte[] 32
     [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b)
     [IO.File]::WriteAllText($f, (-join ($b | ForEach-Object { $_.ToString('x2') })))
     $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
     icacls $f /inheritance:r /grant:r "*${sid}:(M)" | Out-Null
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'token.txt: {0} 文字' -f (Get-Content -LiteralPath $f -Raw).Length
     icacls $f
   }
   ```

   - `token.txt: 64 文字` と、自分のユーザーだけの行（`(M)`）が出ればよい
   - **トークンの値は表示しない**

1. 起動用のスクリプトを書く。

   ```powershell
   if (-not $CODEG_DIR) { Write-Error '中断: この項の手順 2 の変数を設定する' } elseif (Test-Path -LiteralPath "$CODEG_DIR\start-codeg-server.ps1") { Write-Error '中断: start-codeg-server.ps1 が既にある。上書きしない' } else {
     [IO.File]::WriteAllText("$CODEG_DIR\start-codeg-server.ps1", @'
   # start-codeg-server.ps1 (setup-notes: grok-build-remote)
   # Starts codeg-server with the settings below. Refuses to start without a token file,
   # so that the server never generates a token by itself.
   $dir = Join-Path $env:LOCALAPPDATA 'codeg-server'
   $tokenFile = Join-Path $dir 'token.txt'
   if (-not (Test-Path -LiteralPath $tokenFile -PathType Leaf)) {
     [Console]::Error.WriteLine("abort: token file not found: $tokenFile"); exit 1
   }
   $token = (Get-Content -LiteralPath $tokenFile -Raw).Trim()
   if ($token.Length -lt 32) {
     [Console]::Error.WriteLine('abort: token is shorter than 32 characters'); exit 1
   }
   $env:CODEG_TOKEN = $token
   Remove-Variable token
   $env:CODEG_HOST = '127.0.0.1'
   $env:CODEG_PORT = '3080'
   $env:CODEG_STATIC_DIR = Join-Path $dir 'web'
   $env:CODEG_BRIDGE_PORTS = 'off'
   $env:CODEG_BROWSER_TUNNEL = 'off'
   & (Join-Path $dir 'codeg-server.exe')
   exit $LASTEXITCODE
   '@, (New-Object Text.ASCIIEncoding))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Select-String -LiteralPath "$CODEG_DIR\start-codeg-server.ps1" -Pattern 'CODEG_HOST' | ForEach-Object { $_.Line }
   }
   ```

   - `$env:CODEG_HOST = '127.0.0.1'` の行が出ればよい
   - スクリプトは、トークンのファイルが無いと起動しない。Codeg にトークンを作らせない

1. ウィンドウを作らないランチャーのソースを書き、コンパイルする。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     $dir = Join-Path $env:LOCALAPPDATA 'codeg-server'
     $cs = Join-Path $dir 'HiddenLauncher.cs'
     $exe = Join-Path $dir 'codeg-hidden-launcher.exe'
     $csc = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
     if (-not (Test-Path -LiteralPath "$dir\start-codeg-server.ps1")) { Write-Error '中断: 起動用のスクリプトが無い'; return }
     if ((Test-Path -LiteralPath $cs) -or (Test-Path -LiteralPath $exe)) { Write-Error '中断: ランチャーのソースか実行ファイルが既にある。上書きしない'; return }
     if (-not (Test-Path -LiteralPath $csc)) { Write-Error '中断: .NET Framework の csc.exe が無い'; return }
     [IO.File]::WriteAllText($cs, @'
   using System;
   using System.Diagnostics;
   using System.IO;

   internal static class HiddenLauncher
   {
       [STAThread]
       private static int Main(string[] args)
       {
           if (args.Length != 1 || !File.Exists(args[0])) return 2;
           try
           {
               var info = new ProcessStartInfo();
               info.FileName = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "WindowsPowerShell", "v1.0", "powershell.exe");
               info.Arguments = "-NoProfile -NonInteractive -WindowStyle Hidden -File \"" + args[0] + "\"";
               info.UseShellExecute = false;
               info.CreateNoWindow = true;
               info.RedirectStandardOutput = true;
               info.RedirectStandardError = true;
               using (var child = new Process())
               {
                   child.StartInfo = info;
                   child.OutputDataReceived += delegate(object sender, DataReceivedEventArgs e) { };
                   child.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs e) { };
                   child.Start();
                   child.BeginOutputReadLine();
                   child.BeginErrorReadLine();
                   child.WaitForExit();
                   return child.ExitCode;
               }
           }
           catch { return 1; }
       }
   }
   '@, (New-Object Text.UTF8Encoding($true)))
     & $csc /nologo /target:winexe ("/out:" + $exe) $cs
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: コンパイルに失敗した'; return }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Item -LiteralPath $cs, $exe | Select-Object Name, Length
   }
   ```

   - `HiddenLauncher.cs` と `codeg-hidden-launcher.exe` の 2 行が出ればよい
   - 失敗した場合は、この手順が作ったソースだけを消し、原因を直してから貼り直す

1. タスクを登録して開始し、localhost の待ち受けを確かめる。

   ```powershell
   if (-not $CODEG_DIR) { Write-Error '中断: この項の手順 2 の変数を設定する' } elseif (Get-ScheduledTask -TaskName 'codeg-server' -ErrorAction SilentlyContinue) { Write-Error '中断: codeg-server のタスクが既にある' } else {
     $me = [Security.Principal.WindowsIdentity]::GetCurrent().Name
     $launcher = Join-Path $CODEG_DIR 'codeg-hidden-launcher.exe'
     if (-not (Test-Path -LiteralPath $launcher)) { Write-Error '中断: この項の手順 7 のランチャーが無い'; return }
     $action = New-ScheduledTaskAction -Execute $launcher -Argument ('"{0}"' -f "$CODEG_DIR\start-codeg-server.ps1")
     $principal = New-ScheduledTaskPrincipal -UserId $me -LogonType Interactive -RunLevel Limited
     $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
     $trigger = New-ScheduledTaskTrigger -AtLogOn -User $me
     Register-ScheduledTask -TaskName 'codeg-server' -Action $action -Principal $principal -Settings $settings -Trigger $trigger | Out-Null
     Start-ScheduledTask -TaskName 'codeg-server'
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     (Get-ScheduledTask -TaskName 'codeg-server').State
     Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -ge 3080 -and $_.LocalPort -le 3090 } | Format-Table LocalAddress, LocalPort, OwningProcess -AutoSize
   }
   ```

   - `Running` と、`127.0.0.1` の 3080 の 1 行だけが出ればよい
   - タスクは、サインインのたびに自動で始まる
   - タスクが新しい Terminal のウィンドウを開かないことも確かめる
   - `Ready` のままで待ち受けが出ないときは、`powershell.exe -NoProfile -File "$CODEG_DIR\start-codeg-server.ps1"` をこの窓で実行して、表示されたエラーを見る（止めるときは Ctrl+C）
   - **その画面を人に見せない**。Codeg は、起動のたびに標準エラーへトークンを出す

1. トークン無しが拒まれることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$env:WINDIR\System32\curl.exe" -s -o NUL -w "%{http_code}`n" -X POST http://127.0.0.1:3080/api/health
   $t = (Get-Content -LiteralPath "$CODEG_DIR\token.txt" -Raw).Trim()
   (Invoke-WebRequest -Uri 'http://127.0.0.1:3080/api/health' -Method Post -Headers @{ Authorization = "Bearer $t" } -UseBasicParsing).Content
   ((Get-CimInstance Win32_Process | ForEach-Object { [string]$_.CommandLine }) -join "`n").Contains($t)
   Remove-Variable t
   ```

   - 順に、`401`、`{"status":"ok","version":"…"}`、`False`（どのプロセスのコマンドラインにもトークンが無い）が出ればよい

1. この PC のブラウザで開き、トークンを入れて、Grok を動かす。

   - `notepad "$env:LOCALAPPDATA\codeg-server\token.txt"` でトークンを開いてコピーし、保存せずに閉じる
   - ブラウザで `http://127.0.0.1:3080/` を開き、「アクセストークン」に貼って「接続」を押す
   - [ブラウザで開いて Grok を動かす](#ブラウザで開いて-grok-を動かす)の手順 4〜6 と同じ操作で、権限モードを確かめ、フォルダを開いて、指示を送る
   - Windows では、ファイルの変更の確認の見出しが「Write `<パス>`」になる
   - **次の手順は、ブラウザで Grok が応答してから貼る**

### Windows 11 で HTTPS で LAN・VPN に公開する

1. Caddy の配布物を取得してチェックサムを照合し、自分のユーザーの場所に置く。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $dir = "$env:LOCALAPPDATA\codeg-caddy"
     $curl = "$env:WINDIR\System32\curl.exe"
     $tmp = "$env:TEMP\codeg-caddy-setup"
     if (-not $CADDY_VERSION) { Write-Error '中断: 「Windows 11 で Codeg のサーバーを入れて起動する」の手順 2 の変数を設定する'; return }
     if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { Write-Error "中断: この手順は $env:PROCESSOR_ARCHITECTURE の Windows を扱わない"; return }
     if (Test-Path -LiteralPath $dir) { Write-Error "中断: $dir が既にある。上書きしない"; return }
     if (Test-Path -LiteralPath $tmp) { Write-Error "中断: $tmp が既にある。中を確かめて消してから貼り直す"; return }
     $zip = "caddy_${CADDY_VERSION}_windows_amd64.zip"
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & $curl -fsSL -o "$tmp\$zip" "https://github.com/caddyserver/caddy/releases/download/v$CADDY_VERSION/$zip"
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: zip を取れない'; return }
     & $curl -fsSL -o "$tmp\checksums.txt" "https://github.com/caddyserver/caddy/releases/download/v$CADDY_VERSION/caddy_${CADDY_VERSION}_checksums.txt"
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: チェックサムの一覧を取れない'; return }
     $m = Select-String -LiteralPath "$tmp\checksums.txt" -CaseSensitive -Pattern "^([0-9a-f]{128})  $([regex]::Escape($zip))$" | Select-Object -First 1
     if (-not $m) { Write-Error '中断: チェックサムの一覧に zip の行が無い'; return }
     if ((Get-FileHash -LiteralPath "$tmp\$zip" -Algorithm SHA512).Hash -ne $m.Matches[0].Groups[1].Value) { Write-Error '中断: sha512 が一致しない'; return }
     Expand-Archive -LiteralPath "$tmp\$zip" -DestinationPath "$tmp\x"
     New-Item -ItemType Directory -Path $dir | Out-Null
     Copy-Item -LiteralPath "$tmp\x\caddy.exe" -Destination $dir
     Remove-Item -LiteralPath $tmp -Recurse -Force
     'sha512 一致'
     & "$dir\caddy.exe" version
   }
   ```

   - `sha512 一致` と、`v` で始まる `CADDY_VERSION` と同じ番号が出ればよい
   - 実行ファイルに Authenticode の署名は無い。SHA-512 の照合だけで確かめる

1. Caddy の設定を書いて、検査する。

   ```powershell
   $cf = "$env:LOCALAPPDATA\codeg-caddy\Caddyfile"
   if (-not (Test-Path -LiteralPath "$env:LOCALAPPDATA\codeg-caddy\caddy.exe")) { Write-Error '中断: この項の手順 1 を通す' } elseif (Test-Path -LiteralPath $cf) { Write-Error '中断: Caddyfile が既にある。上書きしない' } else {
     [IO.File]::WriteAllText($cf, @"
   # setup-notes: grok-build-remote
   {
       admin off
       auto_https disable_redirects
       skip_install_trust
       pki {
           ca local {
               name "Codeg $env:COMPUTERNAME"
           }
       }
   }

   https://:3443 {
       tls internal {
           on_demand
       }
       handle /caddy-root.crt {
           root * "{`$APPDATA}/Caddy/pki/authorities/local"
           rewrite * /root.crt
           file_server
       }
       handle {
           reverse_proxy 127.0.0.1:3080
       }
   }
   "@, (New-Object Text.UTF8Encoding($false)))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     & "$env:LOCALAPPDATA\codeg-caddy\caddy.exe" validate --config $cf --adapter caddyfile 2>&1 | ForEach-Object { [string]$_ } | Select-Object -Last 1
   }
   ```

   - `Valid configuration` が出ればよい
   - Caddy は、この PC のすべてのアドレスの 3443 番で受け、同じ PC の Codeg（`127.0.0.1:3080`）へ渡す。Codeg の待ち受けは `127.0.0.1` のまま変えない
   - 待ち受ける IP は書かない。証明書は、接続された IP アドレスごとに、Caddy がその場で作る（`on_demand`）。PC の IP が変わっても、設定を変えずに使える
   - 届く範囲は、この項の手順 3 の受信の規則で絞る
   - 認証局の名前は `Codeg <PC の名前>` になる

1. 管理者の Windows PowerShell で、受信の規則を 2 本追加する。

   ```powershell
   $exe = Join-Path $env:LOCALAPPDATA 'codeg-caddy\caddy.exe'
   if (-not (Test-Path -LiteralPath $exe)) { Write-Error '中断: caddy.exe が無い（Codeg を入れたユーザーの管理者の窓で開く）' } elseif (Get-NetFirewallRule -Name 'codeg-caddy-in', 'codeg-caddy-block-public', 'codeg-caddy-block-wifi' -ErrorAction SilentlyContinue) { Write-Error '中断: 既存の規則がある。既存規則の切り替え節を通す' } else {
     New-NetFirewallRule -Name 'codeg-caddy-block-public' -DisplayName 'Codeg (HTTPS) block: public' -Direction Inbound -Action Block -Profile Public, Domain -Program $exe -ErrorAction Stop | Out-Null
     try {
       New-NetFirewallRule -Name 'codeg-caddy-in' -DisplayName 'Codeg (HTTPS)' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3443 -RemoteAddress Any -Profile Private -InterfaceType Any -Program $exe -EdgeTraversalPolicy Block -ErrorAction Stop | Out-Null
     } catch {
       Remove-NetFirewallRule -Name 'codeg-caddy-block-public' -ErrorAction Stop
       throw
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetFirewallRule -Name 'codeg-caddy-in', 'codeg-caddy-block-public' | Format-Table Name, Action, Profile, Enabled, EdgeTraversalPolicy -AutoSize
     Get-NetFirewallRule -Name 'codeg-caddy-in' | Get-NetFirewallAddressFilter | Format-List RemoteAddress
     Get-NetFirewallRule -Name 'codeg-caddy-in' | Get-NetFirewallInterfaceTypeFilter | Format-List InterfaceType
     Get-NetFirewallRule -Name 'codeg-caddy-in' | Get-NetFirewallPortFilter | Format-List Protocol, LocalPort
   }
   ```

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開いた窓に貼る。Codeg を入れたユーザーの窓にする
   - `Allow`・`Private` が 1 行と `Block`・`Domain, Public` が 1 行、`RemoteAddress : Any`、`InterfaceType : Any`、`LocalPort : 3443`、Allow の `EdgeTraversalPolicy : Block` が出ればよい
   - 通すのは、ホスト側の受信インターフェースが Private の 3443/tcp。IPv4・IPv6 の全送信元、有線 LAN・Wi-Fi・VPN を含む全接続種別を許可し、Public・Domain は遮断する
   - **規則は、この項の手順 4 より先に足す**。規則が無いまま Caddy が待ち受けると、Windows が許可を尋ねる画面を出し、そこで別の規則が作られる
   - 3080 番の規則は作らない。Codeg へは、Caddy を通してだけ届く
   - エラーが出たら中断する。Allow の追加に失敗した場合は、この手順で作った Block だけを消して止まる
   - 貼り終えたら、管理者の窓は閉じる
   - **次の手順は、管理者ではない窓（変数を設定した PowerShell）に貼る**

1. Caddy のタスクを登録して開始し、この PC 自身から HTTPS を確かめる。

   ```powershell
   $cdir = "$env:LOCALAPPDATA\codeg-caddy"
   $root = "$env:APPDATA\Caddy\pki\authorities\local\root.crt"
   if (-not (Get-NetFirewallRule -Name 'codeg-caddy-in' -ErrorAction SilentlyContinue)) { Write-Error '中断: この項の手順 3 の規則が無い' } elseif (Get-ScheduledTask -TaskName 'codeg-caddy' -ErrorAction SilentlyContinue) { Write-Error '中断: codeg-caddy のタスクが既にある' } else {
     $me = [Security.Principal.WindowsIdentity]::GetCurrent().Name
     $launcher = Join-Path $env:LOCALAPPDATA 'codeg-server\codeg-hidden-launcher.exe'
     if (-not (Test-Path -LiteralPath $launcher)) { Write-Error '中断: ランチャーが無い'; return }
     $script = Join-Path $cdir 'start-caddy-hidden.ps1'
     if (Test-Path -LiteralPath $script) { Write-Error '中断: start-caddy-hidden.ps1 が既にある。上書きしない'; return }
     [IO.File]::WriteAllText($script, @'
   $dir = Join-Path $env:LOCALAPPDATA 'codeg-caddy'
   & (Join-Path $dir 'caddy.exe') run --config (Join-Path $dir 'Caddyfile') --adapter caddyfile
   exit $LASTEXITCODE
   '@, (New-Object Text.UTF8Encoding($true)))
     $action = New-ScheduledTaskAction -Execute $launcher -Argument ('"{0}"' -f $script)
     $principal = New-ScheduledTaskPrincipal -UserId $me -LogonType Interactive -RunLevel Limited
     $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
     $trigger = New-ScheduledTaskTrigger -AtLogOn -User $me
     Register-ScheduledTask -TaskName 'codeg-caddy' -Action $action -Principal $principal -Settings $settings -Trigger $trigger | Out-Null
     Start-ScheduledTask -TaskName 'codeg-caddy'
     for ($i = 0; $i -lt 30 -and -not ((Test-Path -LiteralPath $root) -and (Get-NetTCPConnection -State Listen -LocalPort 3443 -ErrorAction SilentlyContinue)); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     (Get-ScheduledTask -TaskName 'codeg-caddy').State
     Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in 3080, 3443 } | Sort-Object LocalPort, LocalAddress | Format-Table LocalAddress, LocalPort -AutoSize
     & "$env:WINDIR\System32\curl.exe" -s --cacert $root --ssl-no-revoke -o NUL -w "%{http_code}`n" -X POST "https://127.0.0.1:3443/api/health"
     Get-NetFirewallApplicationFilter -Program "$cdir\caddy.exe" | Get-NetFirewallRule | Format-Table Name, Action, Profile -AutoSize
     Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq 'Private' -and $_.IPv4Connectivity -ne 'Disconnected' } | ForEach-Object {
       $profile = $_
       Get-NetIPAddress -InterfaceIndex $profile.InterfaceIndex -AddressFamily IPv4 -AddressState Preferred -ErrorAction SilentlyContinue |
         Where-Object { -not $_.SkipAsSource -and $_.IPAddress -notmatch '^(127\.|169\.254\.)' } |
         ForEach-Object { '{0}: https://{1}:3443' -f $profile.InterfaceAlias, $_.IPAddress }
     }
   }
   ```

   - `Running`、待ち受けが `127.0.0.1` の 3080 と `::` の 3443 の 2 行、`401`、規則が 2 本、最後に `<接続名>: https://<Private の IPv4>:3443` が出ればよい
   - `::` は、この PC のすべてのアドレス（IPv4 を含む）で待ち受けていることを示す
   - 最後の行が、ほかの端末からつなぐ URL。接続中の Private の IPv4 が無ければ出ない
   - タスクが新しい Terminal のウィンドウを開かないことも確かめる
   - 規則が 2 本より多く出たら、名前と目的を確かめる。この手順以外の規則は変更しない
   - 認証局の鍵と証明書は、Caddy が初回の起動で `%APPDATA%\Caddy\` に作る。**`root.key` を、読まない・写さない・人に渡さない**

1. LAN の別の端末で、HTTPS で届くことを確かめる。

   - ホストの Private の接続へ届く別の端末で `curl -sk -o /dev/null -w '%{http_code}\n' https://<PC の IP>:3443/` を実行し、`200` が出ればよい（`-k` は、ルート証明書を入れる前なので付ける）
   - `<PC の IP>` は、この項の手順 4 の最後に出た URL の IP
   - 有線 LAN と Wi-Fi を使う場合は、それぞれ Private の接続で確かめる。Public・Domain の接続を試せる場合は、別の端末から同じコマンドに `-m 6` を足して実行し、6 秒待って `000` が出ることを確かめる

1. スマートフォンと PC に、この PC のルート証明書を入れる。

   - [端末にルート証明書を入れる](#端末にルート証明書を入れる)の手順 2〜6 を通す。この PC 自身のブラウザで開くなら、この PC にも入れる

1. トークンをスマートフォンに渡す。

   - `qrencode` のある AlmaLinux 10 のホストに SSH で入れるなら、この PC の PowerShell で `Get-Content "$env:LOCALAPPDATA\codeg-server\token.txt" | ssh <ホスト> 'qrencode -t ansiutf8'` を実行すると、端末に QR コードが出る。スマートフォンのカメラで読み、出てきた 64 文字をコピーする
   - トークンは SSH の中を通って相手の `qrencode` に渡り、相手には保存されない
   - ほかの方法で渡すときは、`notepad "$env:LOCALAPPDATA\codeg-server\token.txt"` で開く
   - **画面を人に見せない。読み終えたら `Clear-Host` で消す**

1. スマートフォンで、ブラウザで開いてトークンを入れ、指示を送る。

   - ブラウザで、この項の手順 4 の最後に出た URL（`https://<PC の IP>:3443`）を開く。警告が出ずに、ログインの画面が出ればよい
   - 「アクセストークン」にコピーした 64 文字を貼り、「接続」を押す
   - [ブラウザで開いて Grok を動かす](#ブラウザで開いて-grok-を動かす)の手順 5・6 と同じ操作で、会話を開いて指示を送る
   - この PC 自身のブラウザからも、同じ URL で開ける

1. PC の IP が変わったときは、今の URL を表示して、その URL で開き直す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq 'Private' -and $_.IPv4Connectivity -ne 'Disconnected' } | ForEach-Object {
     $profile = $_
     Get-NetIPAddress -InterfaceIndex $profile.InterfaceIndex -AddressFamily IPv4 -AddressState Preferred -ErrorAction SilentlyContinue |
       Where-Object { -not $_.SkipAsSource -and $_.IPAddress -notmatch '^(127\.|169\.254\.)' } |
       ForEach-Object { '{0}: https://{1}:3443' -f $profile.InterfaceAlias, $_.IPAddress }
   }
   Get-NetConnectionProfile | Format-Table InterfaceAlias, NetworkCategory -AutoSize
   ```

   - 接続中の Private の IPv4 ごとに接続名と URL が 1 行、接続ごとのネットワークの種類が出る。URL が出なければ、Private の有効な IPv4 が無い
   - 接続が `Public`・`DomainAuthenticated` なら、別の端末から届かない。自分の LAN の接続を Private にする場合は、[Windows 11 の初期設定の「ネットワークとリモート」の手順 1](windows-setup.md#ネットワークとリモート)を通す
   - Caddy の設定・タスク・受信の規則・端末のルート証明書は、変えなくてよい。新しい IP 宛ての証明書は、Caddy がその場で作る
   - ブラウザは、IP が違う URL を別のサイトとして扱う。はじめて開く IP では、トークンを入れ直す

---

## Windows 11 の既存の受信規則を Private の全送信元に切り替える

- 以前の手順で `codeg-caddy-in` を作ったときだけ通す。Codeg を入れたユーザーの、管理者の Windows PowerShell（5.1）で行う
- この節の手順 1 は、Private の全送信元・全接続種別に公開する。XML の控えは `%LOCALAPPDATA%\codeg-caddy` に残す。名前とプログラムが一致する既知の規則だけを変え、ほかの規則は変更しない

1. 既存の規則を XML に控え、Private の全送信元へ切り替える。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     $dir = Join-Path $env:LOCALAPPDATA 'codeg-caddy'
     $exe = Join-Path $dir 'caddy.exe'
     $names = @('codeg-caddy-in', 'codeg-caddy-block-public', 'codeg-caddy-block-wifi')
     if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw '中断: caddy.exe が無い' }
     $oldRules = @(Get-NetFirewallRule -Name $names -ErrorAction SilentlyContinue)
     if (-not ($oldRules | Where-Object { $_.Name -eq 'codeg-caddy-in' })) { throw '中断: codeg-caddy-in が無い。新規導入の手順を通す' }
     $saved = foreach ($rule in $oldRules) {
       $application = $rule | Get-NetFirewallApplicationFilter
       if ($application.Program -ne $exe) { throw ('中断: プログラムが一致しない規則: ' + $rule.Name) }
       [pscustomobject]@{
         Rule = $rule
         Application = $application
         Address = $rule | Get-NetFirewallAddressFilter
         Port = $rule | Get-NetFirewallPortFilter
         InterfaceType = $rule | Get-NetFirewallInterfaceTypeFilter
         Interface = $rule | Get-NetFirewallInterfaceFilter
         Service = $rule | Get-NetFirewallServiceFilter
       }
     }
     $backup = Join-Path $dir ('firewall-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '.xml')
     if (Test-Path -LiteralPath $backup) { throw '中断: XML の控えが既にある' }
     $saved | Export-Clixml -LiteralPath $backup -Depth 6
     if ($oldRules | Where-Object { $_.Name -eq 'codeg-caddy-block-public' }) {
       Set-NetFirewallRule -Name 'codeg-caddy-block-public' -Direction Inbound -Action Block -Enabled True -Profile Public, Domain -Program $exe -Protocol Any -LocalPort Any -RemotePort Any -LocalAddress Any -RemoteAddress Any -InterfaceType Any -InterfaceAlias Any
     } else {
       New-NetFirewallRule -Name 'codeg-caddy-block-public' -DisplayName 'Codeg (HTTPS) block: public' -Direction Inbound -Action Block -Profile Public, Domain -Program $exe | Out-Null
     }
     Set-NetFirewallRule -Name 'codeg-caddy-in' -Direction Inbound -Action Allow -Enabled True -Profile Private -Program $exe -Protocol TCP -LocalPort 3443 -EdgeTraversalPolicy Block
     Set-NetFirewallRule -Name 'codeg-caddy-in' -LocalAddress Any -RemoteAddress Any -RemotePort Any -InterfaceType Any -InterfaceAlias Any
     Get-NetFirewallRule -Name 'codeg-caddy-block-wifi' -ErrorAction SilentlyContinue | Remove-NetFirewallRule
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $backup
     Get-NetFirewallRule -Name 'codeg-caddy-in', 'codeg-caddy-block-public' | Format-Table Name, Action, Profile, Enabled, EdgeTraversalPolicy -AutoSize
     Get-NetFirewallRule -Name 'codeg-caddy-in' | Get-NetFirewallAddressFilter | Format-List LocalAddress, RemoteAddress
     Get-NetFirewallRule -Name 'codeg-caddy-in' | Get-NetFirewallInterfaceTypeFilter | Format-List InterfaceType
     Get-NetFirewallRule -Name 'codeg-caddy-in' | Get-NetFirewallPortFilter | Format-List Protocol, LocalPort
     Get-NetFirewallRule -Name 'codeg-caddy-block-wifi' -ErrorAction SilentlyContinue | Format-Table Name
   }
   ```

   - XML の控えのパス、`Allow`・`Private` が 1 行と `Block`・`Domain, Public` が 1 行、両方の `Enabled : True` が出ればよい
   - Allow の `LocalAddress`・`RemoteAddress`・`InterfaceType` が `Any`、`LocalPort : 3443`、`EdgeTraversalPolicy : Block` が出て、最後の Wi-Fi 遮断規則の表が出なければよい
   - エラーが出たら中断する。XML の控えと既存の規則を残し、原因を確かめてからやり直す
   - 控えは規則と関連フィルターの読み戻し用。`Import-Clixml` だけではファイアウォールへ復元されない

1. 別の端末で、Private の接続へ HTTPS で届くことを確かめる。

   - [Windows 11 で HTTPS で LAN・VPN に公開する](#windows-11-で-https-で-lanvpn-に公開する)の手順 9 で URL を表示し、同じ項の手順 5 の接続確認を行う
   - Caddy の設定・タスク・認証局・端末に入れたルート証明書は変えない
   - 終わったら、管理者の窓を閉じる

---

## Windows 11 の既存のタスクを非表示起動に切り替える

- 以前の手順でタスクを作り、ログオン時に Terminal が開く場合に通す。管理者ではない Windows PowerShell（5.1）で行う
- この節の手順 3 で、Codeg と Caddy を短時間止める。実行中の会話は中断されるので、作業が終わってから通す

1. ランチャーを用意する。

   - `%LOCALAPPDATA%\codeg-server\codeg-hidden-launcher.exe` が無いときだけ、[Windows 11 で Codeg のサーバーを入れて起動する](#windows-11-で-codeg-のサーバーを入れて起動する)の手順 7 を通す
   - その項の手順 8 は通さない。既存のタスクは、この節の手順 3 で切り替える

1. Caddy のタスクがあるときだけ、Caddy の起動用スクリプトを用意する。

   ```powershell
   $script = Join-Path $env:LOCALAPPDATA 'codeg-caddy\start-caddy-hidden.ps1'
   if (Test-Path -LiteralPath $script) {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Item -LiteralPath $script | Select-Object Name, Length
   } else {
     [IO.File]::WriteAllText($script, @'
   $dir = Join-Path $env:LOCALAPPDATA 'codeg-caddy'
   & (Join-Path $dir 'caddy.exe') run --config (Join-Path $dir 'Caddyfile') --adapter caddyfile
   exit $LASTEXITCODE
   '@, (New-Object Text.UTF8Encoding($true)))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Item -LiteralPath $script | Select-Object Name, Length
   }
   ```

   - `start-caddy-hidden.ps1` の行が出ればよい
   - 既にファイルがある場合は、Caddy の起動用であることを確かめてから進む。上書きはしない

1. タスクの控えを取り、起動するプログラムだけを切り替えて再開する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     $dir = Join-Path $env:LOCALAPPDATA 'codeg-server'
     $launcher = Join-Path $dir 'codeg-hidden-launcher.exe'
     $names = @('codeg-server')
     if (Get-ScheduledTask -TaskName 'codeg-caddy' -ErrorAction SilentlyContinue) { $names += 'codeg-caddy' }
     $scripts = @{ 'codeg-server' = (Join-Path $dir 'start-codeg-server.ps1'); 'codeg-caddy' = (Join-Path $env:LOCALAPPDATA 'codeg-caddy\start-caddy-hidden.ps1') }
     if (-not (Test-Path -LiteralPath $launcher)) { Write-Error '中断: ランチャーが無い'; return }
     $oldActions = @{}
     foreach ($name in $names) {
       $oldActions[$name] = (Get-ScheduledTask -TaskName $name).Actions
       if (-not (Test-Path -LiteralPath $scripts[$name])) { Write-Error "中断: 起動用のスクリプトが無い: $name"; return }
     }
     $backup = Join-Path $dir ('startup-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
     New-Item -ItemType Directory -Path $backup | Out-Null
     foreach ($name in $names) { Export-ScheduledTask -TaskName $name | Set-Content -LiteralPath (Join-Path $backup ($name + '.xml')) -Encoding Unicode }
     try {
       $targets = @(Get-CimInstance Win32_Process | Where-Object {
         ($_.Name -eq 'codeg-server.exe' -and $_.ExecutablePath -eq (Join-Path $dir 'codeg-server.exe')) -or
         ($names -contains 'codeg-caddy' -and $_.Name -eq 'caddy.exe' -and $_.ExecutablePath -eq (Join-Path $env:LOCALAPPDATA 'codeg-caddy\caddy.exe'))
       })
       foreach ($target in $targets) {
         & "$env:WINDIR\System32\taskkill.exe" /PID $target.ProcessId /T /F | Out-Null
         if ($LASTEXITCODE -ne 0) { throw "停止に失敗: $($target.Name)" }
       }
       foreach ($name in $names) { Stop-ScheduledTask -TaskName $name }
       foreach ($name in $names) {
         $action = New-ScheduledTaskAction -Execute $launcher -Argument ('"{0}"' -f $scripts[$name])
         Set-ScheduledTask -TaskName $name -Action $action | Out-Null
       }
       foreach ($name in $names) { Start-ScheduledTask -TaskName $name }
     } catch {
       foreach ($name in $names) {
         Stop-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
         Set-ScheduledTask -TaskName $name -Action $oldActions[$name] | Out-Null
         Start-ScheduledTask -TaskName $name
       }
       Write-Error "中断: 以前の起動方法へ戻した。$($_.Exception.Message)"
       return
     }
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $backup
     Get-ScheduledTask -TaskName $names | Select-Object TaskName, State, @{ Name = 'Execute'; Expression = { $_.Actions.Execute } }
     Get-NetTCPConnection -State Listen -LocalPort 3080, 3443 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort
   }
   ```

   - 控えのフォルダー、`Running` とランチャーのパス、`127.0.0.1:3080` が出ればよい
   - Caddy のタスクもある場合は、`Running` が 2 行と `::` の 3443 の待ち受けも出ればよい
   - 新しい Terminal のウィンドウが開かないことを確かめ、いつもの URL でブラウザから開く
   - 控えの XML とランチャーは、ふだんの Codeg の更新では消さない

---

## Windows 11 で止める・もう一度始める

- 管理者ではない PowerShell に貼る。変数は要らない
- タスクを終了しただけでは、Codeg と Caddy の本体が残る。止めるのはこの節の手順 1

1. Caddy と Codeg を止める。

   ```powershell
   Stop-ScheduledTask -TaskName 'codeg-caddy' -ErrorAction SilentlyContinue
   Get-Process -Name caddy -ErrorAction SilentlyContinue | Stop-Process -Force
   Get-CimInstance Win32_Process -Filter "Name='codeg-server.exe'" |
     Where-Object { $_.ExecutablePath -eq (Join-Path $env:LOCALAPPDATA 'codeg-server\codeg-server.exe') } |
     ForEach-Object { & "$env:WINDIR\System32\taskkill.exe" /PID $_.ProcessId /T /F | Out-Null }
   Stop-ScheduledTask -TaskName 'codeg-server'
   Start-Sleep -Seconds 2
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Process -Name codeg-server, codeg-mcp, caddy -ErrorAction SilentlyContinue | Format-Table Id, ProcessName
   (Get-ScheduledTask -TaskName 'codeg-server', 'codeg-caddy' -ErrorAction SilentlyContinue).State
   Get-NetTCPConnection -State Listen -LocalPort 3080, 3443 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort
   ```

   - プロセスと待ち受けの表は出ず、`Ready` が 2 行出ればよい（公開の項を通していなければ 1 行）
   - ほかの用途の Caddy をこの PC で動かしているなら、2 行目は貼らない（名前が `caddy` のプロセスをすべて止める）
   - 止めるのは、この手順で置いた Codeg と、その子プロセスだけ。端末や、ほかの ACP クライアントで動かしている `grok` は止めない
   - 実行中の会話は中断される。会話の履歴は残る

1. もう一度始めるときは、タスクを開始する。

   ```powershell
   if (Get-Process -Name codeg-server -ErrorAction SilentlyContinue) {
     Write-Error 'Codeg はもう動いている'
   } else {
     Start-ScheduledTask -TaskName 'codeg-server'
     Start-ScheduledTask -TaskName 'codeg-caddy' -ErrorAction SilentlyContinue
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     Start-Sleep -Seconds 2
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     (Get-ScheduledTask -TaskName 'codeg-server', 'codeg-caddy' -ErrorAction SilentlyContinue).State
     Get-NetTCPConnection -State Listen -LocalPort 3080, 3443 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess -AutoSize
   }
   ```

   - HTTPS で公開しているときは、`Running` が 2 行と、`127.0.0.1` の 3080 と `::` の 3443 の待ち受けが出ればよい
   - localhost でだけ使っているときは、`Running` が 1 行と、`127.0.0.1:3080` の待ち受けだけでよい

---

## Windows 11 の更新

- Windows 版の Codeg は、画面から自分を入れ替えない。この節の手順で、SHA-256 を照合してから置き換える
- 同じ場所（`%LOCALAPPDATA%\codeg-server`）に置き換えるので、タスクはそのまま使える。Caddy と受信の規則には触れない
- この節は Codeg の更新。Caddy の更新は、この手順書では確かめていない
- 管理者ではない PowerShell に貼る
- Grok Build は、Codeg からは上がらない。[Windows 11 で止める・もう一度始める](#windows-11-で止めるもう一度始める)の手順 1 で Codeg を止めてから、端末で `grok update` を実行して上げる

1. 上げる版を設定する。

   ```powershell
   $CODEG_VERSION = ''                   # 上げる版（GitHub のリリースのタグ。例: v0.35.1）
   ```

   - [リリースの一覧](https://github.com/spacering-net/codeg/releases)で確かめる

1. 配布物を取得して SHA-256 を照合し、Codeg を止めて置き換え、タスクを開始する。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $dir = "$env:LOCALAPPDATA\codeg-server"
     $prev = "$env:LOCALAPPDATA\codeg-server.prev"
     $curl = "$env:WINDIR\System32\curl.exe"
     $tmp = "$env:TEMP\codeg-server-setup"
     if (-not $CODEG_VERSION) { Write-Error '中断: この節の手順 1 の変数を設定する'; return }
     if (-not (Test-Path -LiteralPath "$dir\codeg-server.exe")) { Write-Error '中断: Codeg が入っていない'; return }
     if (Test-Path -LiteralPath $prev) { Write-Error "中断: $prev が既にある。前の更新と復旧を終えるまで消さない"; return }
     if (Test-Path -LiteralPath $tmp) { Write-Error "中断: $tmp が既にある。中を確かめて消してから貼り直す"; return }
     New-Item -ItemType Directory -Path $tmp | Out-Null
     $url = "https://github.com/spacering-net/codeg/releases/download/$CODEG_VERSION/codeg-server-windows-x64.zip"
     & $curl -fsSL -o "$tmp\codeg-server-windows-x64.zip" $url
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: zip を取れない'; return }
     & $curl -fsSL -o "$tmp\codeg-server-windows-x64.zip.sha256" "$url.sha256"
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: .sha256 を取れない'; return }
     $want = ((Get-Content -LiteralPath "$tmp\codeg-server-windows-x64.zip.sha256" -Raw) -split '\s+')[0]
     if ((Get-FileHash -LiteralPath "$tmp\codeg-server-windows-x64.zip" -Algorithm SHA256).Hash -ne $want) { Write-Error '中断: sha256 が一致しない'; return }
     Expand-Archive -LiteralPath "$tmp\codeg-server-windows-x64.zip" -DestinationPath $tmp
     $payload = Join-Path $tmp 'codeg-server-windows-x64'
     if (-not (Test-Path -LiteralPath "$payload\codeg-server.exe" -PathType Leaf) -or -not (Test-Path -LiteralPath "$payload\codeg-mcp.exe" -PathType Leaf) -or -not (Test-Path -LiteralPath "$payload\web" -PathType Container)) { throw '中断: 配布物の本体と web が揃っていない' }
     Get-CimInstance Win32_Process -Filter "Name='codeg-server.exe'" |
       Where-Object { $_.ExecutablePath -eq (Join-Path $env:LOCALAPPDATA 'codeg-server\codeg-server.exe') } |
       ForEach-Object {
         & "$env:WINDIR\System32\taskkill.exe" /PID $_.ProcessId /T /F | Out-Null
         if ($LASTEXITCODE -ne 0) { throw '中断: Codeg と子プロセスを止められない' }
       }
     Stop-ScheduledTask -TaskName 'codeg-server'
     Start-Sleep -Seconds 2
     New-Item -ItemType Directory -Path $prev | Out-Null
     Move-Item -LiteralPath "$dir\codeg-server.exe", "$dir\codeg-mcp.exe", "$dir\web" -Destination $prev
     Copy-Item -LiteralPath "$tmp\codeg-server-windows-x64\codeg-server.exe", "$tmp\codeg-server-windows-x64\codeg-mcp.exe" -Destination $dir
     Copy-Item -LiteralPath "$tmp\codeg-server-windows-x64\web" -Destination $dir -Recurse
     Remove-Item -LiteralPath $tmp -Recurse -Force
     Start-ScheduledTask -TaskName 'codeg-server'
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     'sha256 一致'
     & "$dir\codeg-server.exe" --version
     (Get-ScheduledTask -TaskName 'codeg-server').State
     Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort -AutoSize
   }
   ```

   - `sha256 一致`、上げた版の番号、`Running`、今までと同じ待ち受けの 1 行が出ればよい
   - 起動用のスクリプトとトークンは、そのまま残る
   - 失敗したときは、現行の本体と `codeg-server.prev` を残す。`codeg-server.prev` の `codeg-server.exe`・`codeg-mcp.exe`・`web` が揃っていることを確かめてから、[Windows 11 で止める・もう一度始める](#windows-11-で止めるもう一度始める)の手順 1 で止める
   - 3 つが揃っていれば、現行の `codeg-server` のその 3 つだけを消し、`codeg-server.prev` から同じ場所に戻す。起動用のスクリプトとトークンは消さない。その後、同じ節の手順 2 で始める
   - 退避先が揃っていなければ、どちらのディレクトリも消さず、移動やコピーが止まった原因を確かめる。前の版は一部が現行の場所、一部が退避先に残っていることがある

1. ブラウザで動くことを確かめてから、前の版を消す。

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\codeg-server.prev" -Recurse -Force
   ```

   - 会話の一覧が残っていて、画面の右下の「新バージョン」が消えていればよい
