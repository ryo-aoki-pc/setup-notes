# Grok Build をブラウザから操作する手順（Codeg / AlmaLinux 10 は systemd のユーザーサービス / Windows 11 はタスク スケジューラ / LAN・VPN 内で使う）

## 実施手順

- [検証記録](verification/grok-build-remote.md)・[参考資料](reference/grok-build-remote.md)・[ロールバックと注意点](extra/grok-build-remote.md)

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のサーバーのもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す
> - **Grok Build を使う一般ユーザー自身の bash（SSH）で実行する**。`sudo -i` や `sudo -iu` で切り替えたシェルは使わない
> - 前提: [AlmaLinux 10 の初期設定の「Grok Build」](almalinux-setup.md#grok-build)で Grok Build を入れてログインしてあること（ブラウザの無いホストは [Grok Build をブラウザの無いホストでログインする](almalinux-setup.md#grok-build-をブラウザの無いホストでログインする)）。[「Codex・Grok のプラグイン」の手順 1](almalinux-setup.md#codexgrok-のプラグイン)の Node.js、[linger](linger.md)、[「ログインと sudo」の手順 3](almalinux-setup.md#ログインと-sudo)（NOPASSWD の sudo）も通す
> - 別の PC からサーバーの SSH にログインでき、サーバーの IPv4 が固定されていることを前提にする。firewalld と SELinux は有効なまま使う
> - スマートフォンから使うときは、スマートフォンを [WireGuard VPN の「クライアントを登録する」](wireguard.md#クライアントを登録する)でクライアントにしておく
> - [ブラウザで開いて Grok を動かす](#ブラウザで開いて-grok-を動かす)の手順 1・3〜6 は別の PC とそのブラウザで、[VPN に公開する](#vpn-に公開する)の手順 3 は LAN の別の端末で、手順 4・6 はスマートフォンで行う

- 上から順にコードブロックを貼る。[Codeg のサーバーを入れて localhost で起動する](#codeg-のサーバーを入れて-localhost-で起動する)の手順 1 で変数を設定したシェルに貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- Grok Build には、公式の遠隔操作の画面が無い。OSS の [Codeg](https://github.com/spacering-net/codeg)（Apache-2.0）のサーバーを Grok Build と同じホストに常駐させ、ブラウザのチャット形式の画面から Grok Build を動かす。外部のサーバーは通らない
- 通信は HTTP で、内容は暗号化されない。VPN 経由で開く場合は VPN の区間が暗号化される。インターネット向けのポート転送は設定しない
- 手順の後: [使い方の基本](#使い方の基本)・[端末の grok のセッションを取り込む](#端末の-grok-のセッションを取り込む)・[設定ファイル](#設定ファイル)・[更新](#更新)・[ロールバック](extra/grok-build-remote.md#ロールバック)

> [!WARNING]
> **アクセストークンを知っている人は、ブラウザからこのサーバーで、このユーザーとして Grok Build を動かせる**（ファイルの読み書きとコマンドの実行）。NOPASSWD の sudo があるホストでは、root と同じ重みになる。待ち受ける IP と送信元を絞り、トークンは人に見せない。**Grok の権限モードが「常に許可」だと、送った指示は確認なしで実行される**。「毎回確認」でも、`mkdir` は確認なしで実行された（[注意点](extra/grok-build-remote.md#注意点)）。

### Codeg のサーバーを入れて localhost で起動する

1. 変数を設定する（`SERVER_IP` と `ALLOW_FROM` は必ず値を入れる）。

   ```bash
   SERVER_IP=''                       # サーバーの待ち受け IPv4（例: 192.168.1.10）
   ```

   ```bash
   ALLOW_FROM=''                      # 許可する送信元 IPv4 の CIDR（例: VPN のクライアントの帯 10.0.2.0/24）
   ```

   ```bash
   {
     CODEG_VERSION=v0.35.1             # 入れる版（GitHub のリリースのタグ）
     FW_ZONE=$(sudo firewall-cmd --get-default-zone)
     printf '\n\033[7m 確認 \033[0m\n'
     printf '待ち受け: %s:3080\n許可する送信元: %s\n版: %s\nfirewalld: %s\n' \
       "${SERVER_IP}" "${ALLOW_FROM}" "${CODEG_VERSION}" "${FW_ZONE}"
   }
   ```

   - `SERVER_IP` は、スマートフォンや PC から届くサーバーの IPv4。`ip -4 -br addr` で確かめる
   - `ALLOW_FROM` は、サーバーから見えるクライアントの送信元に合わせる。VPN のクライアントだけに許可するときは、その VPN のクライアントの帯にする
   - LAN の端末にも許可すると、その区間の通信（トークンを含む）は暗号化されない
   - `CODEG_VERSION` は、[リリースの一覧](https://github.com/spacering-net/codeg/releases)で新しい版を確かめて変える
   - 待ち受ける NIC が別の zone に属しているなら、`FW_ZONE=` をその名前に変える
   - 空のままなら先へ進まない
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、この項の手順 1 を貼り直す

1. Grok Build・Node.js・linger・firewalld と、Codeg がまだ無いことを確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     if [ -z "${SERVER_IP}" ] || [ -z "${ALLOW_FROM}" ] || [ -z "${CODEG_VERSION}" ] || [ -z "${FW_ZONE}" ]; then
       echo '中断: この項の手順 1 の変数を設定する' >&2
     else
       uname -m
       grok --version
       node --version
       loginctl show-user "$(id -u)" -p Linger
       sudo firewall-cmd --state
       sudo firewall-cmd --get-active-zones
       ss -ltn '( sport >= :3080 and sport <= :3090 )'
       ls -d ~/.local/opt/codeg-server ~/.local/share/codeg ~/.config/codeg-server ~/.config/systemd/user/codeg-server.service
     fi
   }
   ```

   - `aarch64` か `x86_64`、`grok` と `node` の版、`Linger=yes`、`running` が出ればよい
   - `ss` は見出しの 1 行だけ、`ls` は 4 つとも `No such file or directory` になればよい
   - `Linger=no` なら、先に [linger](linger.md) を通す
   - 3080 番に待ち受けがあるか、`ls` が何かを出したら中断する。既存の構築を使うか、[ロールバック](extra/grok-build-remote.md#ロールバック)で消してからやり直す
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
       tar -tzf "${CODEG_ASSET}.tar.gz" | grep -cE '^/|(^|/)\.\.(/|$)'
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
   journalctl --user -u codeg-server.service --no-pager | grep -cFf <(sed -n 's/^CODEG_TOKEN=//p' ~/.config/codeg-server/token.env)
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

1. ブラウザで、Grok の権限モードを確かめる。

   - アドレス欄の `/workspace` を `/settings/agents` に変えて開き、「エージェント一覧」の `Grok` を選ぶ
   - 「権限モード」は「デフォルトを使用」「毎回確認」「編集を自動承認」「スマート自動承認」「常に許可」から選ぶ。変えたら「Grok 設定を保存」を押す
   - **「常に許可」のままだと、ブラウザから送った指示は確認なしで実行される**。離れた場所から使うなら「毎回確認」にする
   - **ここで保存すると、`~/.grok/config.toml` の `permission_mode` が書き換わり、端末の `grok` にも効く**
   - `permission_mode` の行が無い Grok Build（入れたままの状態）は、確認を出すモードで動く
   - 変えた設定は、新しく開いた会話から効く
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

### VPN に公開する

1. 指定した送信元・宛先・ポートで、この手順専用の firewalld の規則を追加する。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     if [ -z "${SERVER_IP}" ] || [ -z "${ALLOW_FROM}" ] || [ -z "${FW_ZONE}" ]; then
       echo '中断: 「Codeg のサーバーを入れて localhost で起動する」の手順 1 の変数を設定する' >&2
     else
       CODEG_RULE="rule family=\"ipv4\" priority=\"100\" source address=\"${ALLOW_FROM}\" destination address=\"${SERVER_IP}\" port port=\"3080\" protocol=\"tcp\" accept"
       sudo firewall-cmd --permanent --zone="${FW_ZONE}" --add-rich-rule="${CODEG_RULE}" &&
       sudo firewall-cmd --zone="${FW_ZONE}" --add-rich-rule="${CODEG_RULE}"
       sudo firewall-cmd --permanent --zone="${FW_ZONE}" --list-rich-rules
       sudo firewall-cmd --zone="${FW_ZONE}" --list-rich-rules
     fi
   }
   ```

   - `success` が 2 回出た後、runtime と permanent に、指定した送信元・宛先・3080/tcp の規則が 1 本ずつあればよい
   - **送信元を制限する場合**、既存の zone が `trusted`・`ACCEPT`、または同じポートへの広い許可があると、この規則だけでは絞れない
   - **中断や失敗が出たらこの項の手順 2 へ進まない**。追加できた規則を外す場合は[ロールバック](extra/grok-build-remote.md#ロールバック)の手順 2 を使う

1. 待ち受けをサーバーの IP に変え、自動起動を有効にして、サービスを起動し直す。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     if [ -z "${SERVER_IP}" ] || [ -z "${FW_ZONE}" ]; then
       echo '中断: 「Codeg のサーバーを入れて localhost で起動する」の手順 1 の変数を設定する' >&2
     elif [ "$(sudo firewall-cmd --zone="${FW_ZONE}" --list-rich-rules | grep -c 'port="3080"')" != 1 ]; then
       echo '中断: この項の手順 1 の規則が runtime に 1 本だけある状態にする' >&2
     else
       sed -i "s/^Environment=CODEG_HOST=.*$/Environment=CODEG_HOST=${SERVER_IP}/" ~/.config/systemd/user/codeg-server.service &&
       systemctl --user daemon-reload &&
       systemctl --user enable codeg-server.service &&
       systemctl --user restart codeg-server.service
       for i in $(seq 1 30); do ss -ltn '( sport = :3080 )' | grep -q LISTEN && break; sleep 1; done
       systemctl --user is-active codeg-server.service
       systemctl --user is-enabled codeg-server.service
       ss -ltn '( sport >= :3080 and sport <= :3090 )'
       curl -s -o /dev/null -w '%{http_code}\n' -X POST "http://${SERVER_IP}:3080/api/health"
     fi
   }
   ```

   - `Created symlink …`、`active`、`enabled`、待ち受けが `<SERVER_IP>:3080` の 1 行だけ、最後に `401` が出ればよい
   - [ブラウザで開いて Grok を動かす](#ブラウザで開いて-grok-を動かす)の手順 1 のトンネルは、ここから先は使えない（`127.0.0.1` では待ち受けなくなる）
   - 会話の履歴は残る

1. LAN の別の端末で、許可していない送信元から開けないことを確かめる。

   - `ALLOW_FROM` に入っていない端末で `curl -m 6 -s -o /dev/null -w '%{http_code}\n' http://<SERVER_IP>:3080/` を実行する
   - 6 秒待って `000` が出ればよい。`200` が出たら、[ロールバック](extra/grok-build-remote.md#ロールバック)の手順 1 でサービスを止めてから、この項の手順 1 の規則と zone を確かめる
   - `ALLOW_FROM` に LAN の帯も入れたときは、この手順は飛ばす

1. スマートフォンで、WireGuard を張ってブラウザで開く。

   - WireGuard のアプリでトンネルを有効にし、ブラウザで `http://<SERVER_IP>:3080` を開く
   - ログインの画面（「アクセストークン」と「接続」）が出ればよい
   - 開けないときは、スマートフォンの VPN のアドレスが `ALLOW_FROM` に入っているかを確かめる

1. サーバーで、トークンを QR コードで表示する。

   ```bash
   sed -n 's/^CODEG_TOKEN=//p' ~/.config/codeg-server/token.env | qrencode -t ansiutf8
   ```

   - 端末に QR コードが出る。スマートフォンのカメラで読み、出てきた 64 文字をコピーする
   - `qrencode` が無ければ `brew install qrencode` で入れる（[Homebrew](almalinux-setup.md#homebrew)）
   - **画面を人に見せない。読み終えたら `clear` で消す**

1. スマートフォンで、トークンを入れて、指示を送る。

   - 「アクセストークン」にコピーした 64 文字を貼り、「接続」を押す
   - [ブラウザで開いて Grok を動かす](#ブラウザで開いて-grok-を動かす)の手順 5・6 と同じ操作で、会話を開いて指示を送る
   - PC で開いた会話も、同じ一覧に出る

---

## 使い方の基本

| したいこと | 操作 |
|---|---|
| 会話を始める | 左の一覧のフォルダの行の「新しい会話」（どの画面でも `Ctrl+T`）。エージェントの一覧で `Grok` を選ぶ |
| 別のプロジェクトで使う | 左の「フォルダを開く」で、ホストの中のディレクトリを足す |
| 前の会話に戻る | 左の一覧の会話を押す。サービスを起動し直しても、会話は残る |
| 承認の確認に答える | 入力欄の上に出る選択肢から選ぶ（[ブラウザで開いて Grok を動かす](#ブラウザで開いて-grok-を動かす)の手順 6） |
| 変えたファイルを見る | 会話の中の「変更されたファイル」 |
| 確認の出方を変える | `/settings/agents` の `Grok` の「権限モード」（[ブラウザで開いて Grok を動かす](#ブラウザで開いて-grok-を動かす)の手順 4） |
| 端末の `grok` で始めた作業を、ブラウザで続ける | [端末の grok のセッションを取り込む](#端末の-grok-のセッションを取り込む) |
| ブラウザで始めた会話を、端末で確かめる | そのディレクトリで `grok sessions list`。Codeg で作った会話も一覧に出る |
| 止める・始める | `systemctl --user stop codeg-server.service`・`systemctl --user start codeg-server.service`（Windows 11 は [Windows 11 で止める・もう一度始める](#windows-11-で止めるもう一度始める)） |

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
| `~/.codeg/` | `%USERPROFILE%\.codeg\` | Codeg が置くスキル |
| `~/.grok/` | `%USERPROFILE%\.grok\` | Grok Build の設定・ログイン・セッション（[Grok Build の設定ファイル](almalinux-setup.md#grok-build-の設定ファイル)）。Codeg は、ここのセッションをそのまま使う |

- `CODEG_BRIDGE_PORTS=off` は、開発サーバー用の追加のポート（3081〜3090）を開けない設定。`CODEG_BROWSER_TUNNEL=off` は、Codeg のデスクトップアプリからの中継を止める設定
- トークンを替えるときは、トークンのファイルを作り直して、サービス（Windows 11 はタスク）を起動し直す。ブラウザは入り直しになる

---

## 更新

- AlmaLinux 10 の手順。Windows 11 は [Windows 11 の更新](#windows-11-の更新)
- 画面の右下に「新バージョン」と出たら、新しい版がある。画面からは入れ替えず、この節の手順で、SHA-256 を照合してから置き換える
- Grok Build は、Codeg からは上がらない（Codeg は `--no-auto-update` を付けて起動する）。端末で `grok update` を実行して上げる

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
     CODEG_X=$(mktemp -d ~/.cache/codeg-server-x.XXXXXX) &&
     tar -xzf ~/.cache/codeg-server-dl/"${CODEG_ASSET}.tar.gz" -C "${CODEG_X}" &&
     systemctl --user stop codeg-server.service &&
     mv ~/.local/opt/codeg-server ~/.local/opt/codeg-server.prev &&
     install -d -m 755 ~/.local/opt/codeg-server &&
     install -m 755 "${CODEG_X}/${CODEG_ASSET}/codeg-server" "${CODEG_X}/${CODEG_ASSET}/codeg-mcp" ~/.local/opt/codeg-server/ &&
     cp -r "${CODEG_X}/${CODEG_ASSET}/web" ~/.local/opt/codeg-server/web &&
     rm -r "${CODEG_X}" ~/.cache/codeg-server-dl &&
     systemctl --user start codeg-server.service
     for i in $(seq 1 30); do ss -ltn '( sport = :3080 )' | grep -q LISTEN && break; sleep 1; done
     printf '\n\033[7m 確認 \033[0m\n'
     ~/.local/opt/codeg-server/codeg-server --version
     systemctl --user is-active codeg-server.service
     ss -ltn '( sport >= :3080 and sport <= :3090 )'
   fi
   ```

   - 上げた版の番号、`active`、今までと同じ待ち受けの 1 行が出ればよい
   - 動いていた Grok Build のプロセスは、サービスと一緒に止まる。会話の履歴は残り、ブラウザは入り直さずに使える
   - 起動しないときは、`systemctl --user stop codeg-server.service` の後、`~/.local/opt/codeg-server` を消して `~/.local/opt/codeg-server.prev` を元の名前に戻し、`start` する

1. ブラウザで動くことを確かめてから、前の版を消す。

   ```bash
   rm -r ~/.local/opt/codeg-server.prev
   ```

   - 会話の一覧が残っていて、画面の右下の「新バージョン」が消えていればよい

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows の PC のデスクトップで行う**。[Windows 11 で Codeg のサーバーを入れて起動する](#windows-11-で-codeg-のサーバーを入れて起動する)の手順 1 で開いた、**管理者ではない** Windows PowerShell（5.1）に貼る。[Windows 11 で VPN に公開する](#windows-11-で-vpn-に公開する)の手順 1 だけは、管理者の Windows PowerShell に貼る
> - **SSH でログインしたシェルには貼らない**。Administrators の一員の SSH のセッションは管理者の権限を持つので、そこから始めると Codeg と Grok Build が管理者の権限で動く
> - 前提: [Windows 11 の初期設定の「貼り付けの設定」の手順 1〜4](windows-setup.md#貼り付けの設定)、[「Grok Build」](windows-setup.md#grok-build)（導入とログイン）、[「Codex・Grok のプラグイン」](windows-setup.md#codexgrok-のプラグイン)の Node.js、[「ネットワークとリモート」の手順 1](windows-setup.md#ネットワークとリモート)（LAN の接続をプライベートにする）
> - Codeg は、管理者ではない自分のユーザーとして、サインインしている間だけ動く（この節のタスク）。PC の IPv4 が固定されていることを前提にする
> - スマートフォンから使うときは、スマートフォンを [WireGuard VPN の「クライアントを登録する」](wireguard.md#クライアントを登録する)でクライアントにしておく
> - [Windows 11 で VPN に公開する](#windows-11-で-vpn-に公開する)の手順 3 は LAN の別の端末で、手順 4・6 はスマートフォンで行う

- 上から順にコードブロックを貼る。[Windows 11 で Codeg のサーバーを入れて起動する](#windows-11-で-codeg-のサーバーを入れて起動する)の手順 2 で変数を設定した PowerShell に貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 画面の操作は、[実施手順](#実施手順)の AlmaLinux 10 と同じ。手順の後は[使い方の基本](#使い方の基本)・[端末の grok のセッションを取り込む](#端末の-grok-のセッションを取り込む)・[Windows 11 で止める・もう一度始める](#windows-11-で止めるもう一度始める)・[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/grok-build-remote.md#windows-11-のロールバック)

> [!WARNING]
> **アクセストークンを知っている人は、ブラウザからこの PC で、このユーザーとして Grok Build を動かせる**（ファイルの読み書きとコマンドの実行）。Windows の Grok Build には sandbox が無い。待ち受ける IP と送信元を絞り、トークンは人に見せない。**Grok の権限モードが「常に許可」だと、送った指示は確認なしで実行される**（[注意点](extra/grok-build-remote.md#注意点)）。

### Windows 11 で Codeg のサーバーを入れて起動する

1. Windows で、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」をそのまま開く（「管理者として実行」にしない）
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする

1. 変数を設定する（`$PC_IP` と `$ALLOW_FROM` は必ず値を入れる）。

   ```powershell
   $PC_IP = ''                           # この PC の待ち受け IPv4（例: 192.168.1.20）。<PC_IP>
   ```

   ```powershell
   $ALLOW_FROM = ''                      # 許可する送信元 IPv4 の CIDR（例: VPN のクライアントの帯 10.0.2.0/24）。<ALLOW_FROM>
   ```

   ```powershell
   $CODEG_VERSION = 'v0.35.1'            # 入れる版（GitHub のリリースのタグ）
   $CODEG_DIR = "$env:LOCALAPPDATA\codeg-server"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'PC_IP         = {0}' -f $PC_IP
   'ALLOW_FROM    = {0}' -f $ALLOW_FROM
   'CODEG_VERSION = {0}' -f $CODEG_VERSION
   'CODEG_DIR     = {0}' -f $CODEG_DIR
   ```

   - `PC_IP` は、スマートフォンから届くこの PC の IPv4。`Get-NetIPAddress -AddressFamily IPv4` で確かめる
   - `ALLOW_FROM` は、この PC から見えるクライアントの送信元に合わせる。VPN のクライアントだけに許可するときは、その VPN のクライアントの帯にする
   - `CODEG_VERSION` は、[リリースの一覧](https://github.com/spacering-net/codeg/releases)で新しい版を確かめて変える
   - 空のままなら先へ進まない
   - **新しい PowerShell を開いたら**、この項の手順 2 のブロックを貼り直してから先へ進む

1. Grok Build・Node.js・LAN の接続と、Codeg がまだ無いことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   grok --version
   node --version
   ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
   Get-NetConnectionProfile | Format-Table InterfaceAlias, NetworkCategory -AutoSize
   Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -ge 3080 -and $_.LocalPort -le 3090 } | Format-Table LocalAddress, LocalPort, OwningProcess -AutoSize
   Test-Path $CODEG_DIR, "$env:APPDATA\codeg"
   Get-ScheduledTask -TaskName 'codeg-server' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   ```

   - `grok` と `node` の版、`False`（管理者ではない）、LAN の接続の `Private` が出ればよい
   - その後は、待ち受けの表が出ず、`False` が 2 行出て、タスクの表も出なければよい
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

1. タスクを登録して開始し、localhost の待ち受けを確かめる。

   ```powershell
   if (-not $CODEG_DIR) { Write-Error '中断: この項の手順 2 の変数を設定する' } elseif (Get-ScheduledTask -TaskName 'codeg-server' -ErrorAction SilentlyContinue) { Write-Error '中断: codeg-server のタスクが既にある' } else {
     $me = [Security.Principal.WindowsIdentity]::GetCurrent().Name
     $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ('-NoProfile -WindowStyle Hidden -File "{0}"' -f "$CODEG_DIR\start-codeg-server.ps1")
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

### Windows 11 で VPN に公開する

1. 管理者の Windows PowerShell で、指定した送信元・宛先・ポートの受信の規則を追加する。

   ```powershell
   $PC_IP = ''                           # この PC の待ち受け IPv4。<PC_IP>
   ```

   ```powershell
   $ALLOW_FROM = ''                      # 許可する送信元 IPv4 の CIDR。<ALLOW_FROM>
   ```

   ```powershell
   $exe = Join-Path $env:LOCALAPPDATA 'codeg-server\codeg-server.exe'
   if (-not $PC_IP -or -not $ALLOW_FROM) { Write-Error '中断: この手順の 2 つの変数を設定する' } elseif (-not (Test-Path -LiteralPath $exe)) { Write-Error '中断: codeg-server.exe が無い（Codeg を入れたユーザーの管理者の窓で開く）' } elseif (Get-NetFirewallRule -Name 'codeg-server-in' -ErrorAction SilentlyContinue) { Write-Error '中断: 同じ名前の規則が既にある' } else {
     New-NetFirewallRule -Name 'codeg-server-in' -DisplayName 'Codeg server (VPN)' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3080 -LocalAddress $PC_IP -RemoteAddress $ALLOW_FROM -Profile Private -Program $exe | Out-Null
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetFirewallRule -Name 'codeg-server-in' | Format-List Name, Enabled, Direction, Action, Profile
     Get-NetFirewallRule -Name 'codeg-server-in' | Get-NetFirewallAddressFilter | Format-List LocalAddress, RemoteAddress
     Get-NetFirewallRule -Name 'codeg-server-in' | Get-NetFirewallPortFilter | Format-List Protocol, LocalPort
   }
   ```

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開いた窓に貼る。2 つの変数には、[Windows 11 で Codeg のサーバーを入れて起動する](#windows-11-で-codeg-のサーバーを入れて起動する)の手順 2 と同じ値を入れる
   - `Enabled : True`・`Action : Allow`・`Profile : Private`、指定した `LocalAddress` と `RemoteAddress`、`LocalPort : 3080` が出ればよい
   - **規則は、この項の手順 2 より先に足す**。規則が無いまま待ち受けを変えると、Windows が許可を尋ねる画面を出し、そこで別の規則が作られる
   - 貼り終えたら、管理者の窓は閉じる
   - **次の手順は、管理者ではない窓（変数を設定した PowerShell）に貼る**

1. 待ち受けを PC の IP に変えて、タスクを起動し直す。

   ```powershell
   $w = "$CODEG_DIR\start-codeg-server.ps1"
   if (-not $PC_IP -or -not $CODEG_DIR) { Write-Error '中断: 「Windows 11 で Codeg のサーバーを入れて起動する」の手順 2 の変数を設定する' } elseif (-not (Get-NetFirewallRule -Name 'codeg-server-in' -ErrorAction SilentlyContinue)) { Write-Error '中断: この項の手順 1 の規則が無い' } else {
     $txt = [IO.File]::ReadAllText($w) -replace "(?m)^\`$env:CODEG_HOST = '.*'", "`$env:CODEG_HOST = '$PC_IP'"
     [IO.File]::WriteAllText($w, $txt, (New-Object Text.ASCIIEncoding))
     Stop-ScheduledTask -TaskName 'codeg-server'
     Get-Process -Name codeg-server -ErrorAction SilentlyContinue | Stop-Process -Force
     Get-CimInstance Win32_Process -Filter "Name='grok.exe' OR Name='codeg-mcp.exe'" | Where-Object { $_.CommandLine -like '*agent stdio*' -or $_.CommandLine -like '*codeg-delegation*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
     Start-Sleep -Seconds 2
     Start-ScheduledTask -TaskName 'codeg-server'
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Select-String -LiteralPath $w -Pattern 'CODEG_HOST' | ForEach-Object { $_.Line }
     Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort -AutoSize
     & "$env:WINDIR\System32\curl.exe" -s -o NUL -w "%{http_code}`n" -X POST "http://${PC_IP}:3080/api/health"
     Get-NetFirewallApplicationFilter -Program "$CODEG_DIR\codeg-server.exe" | Get-NetFirewallRule | Format-Table Name, Action, Profile -AutoSize
   }
   ```

   - `CODEG_HOST` の行が `<PC_IP>` になり、待ち受けが `<PC_IP>` の 3080 の 1 行だけ、`401`、規則が `codeg-server-in` の 1 本だけ出ればよい
   - この PC 自身のブラウザからも、ここから先は `http://<PC_IP>:3080/` で開く（`127.0.0.1` では待ち受けなくなる）。ブラウザは入り直しになる
   - 規則がほかにも出たら、Windows が自動で作った規則がある。名前を確かめて外す

1. LAN の別の端末で、許可していない送信元から開けないことを確かめる。

   - `ALLOW_FROM` に入っていない端末で `curl -m 6 -s -o /dev/null -w '%{http_code}\n' http://<PC_IP>:3080/` を実行する
   - 6 秒待って `000` が出ればよい。`200` が出たら、[Windows 11 で止める・もう一度始める](#windows-11-で止めるもう一度始める)の手順 1 で止めてから、この項の手順 1 の規則を確かめる

1. スマートフォンで、WireGuard を張ってブラウザで開く。

   - WireGuard のアプリでトンネルを有効にし、ブラウザで `http://<PC_IP>:3080` を開く
   - ログインの画面（「アクセストークン」と「接続」）が出ればよい

1. トークンをスマートフォンに渡す。

   - `qrencode` のある AlmaLinux 10 のホストに SSH で入れるなら、この PC の PowerShell で `Get-Content "$env:LOCALAPPDATA\codeg-server\token.txt" | ssh <ホスト> 'qrencode -t ansiutf8'` を実行すると、端末に QR コードが出る。スマートフォンのカメラで読み、出てきた 64 文字をコピーする
   - トークンは SSH の中を通って相手の `qrencode` に渡り、相手には保存されない
   - ほかの方法で渡すときは、`notepad "$env:LOCALAPPDATA\codeg-server\token.txt"` で開く
   - **画面を人に見せない。読み終えたら `Clear-Host` で消す**

1. スマートフォンで、トークンを入れて、指示を送る。

   - 「アクセストークン」にコピーした 64 文字を貼り、「接続」を押す
   - [ブラウザで開いて Grok を動かす](#ブラウザで開いて-grok-を動かす)の手順 5・6 と同じ操作で、会話を開いて指示を送る

---

## Windows 11 で止める・もう一度始める

- 管理者ではない PowerShell に貼る。変数は要らない
- タスクを終了しただけでは、Codeg の本体が残る。止めるのはこの節の手順 1

1. Codeg を止める。

   ```powershell
   Stop-ScheduledTask -TaskName 'codeg-server'
   Get-Process -Name codeg-server -ErrorAction SilentlyContinue | Stop-Process -Force
   Get-CimInstance Win32_Process -Filter "Name='grok.exe' OR Name='codeg-mcp.exe'" | Where-Object { $_.CommandLine -like '*agent stdio*' -or $_.CommandLine -like '*codeg-delegation*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
   Start-Sleep -Seconds 2
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Process -Name codeg-server, codeg-mcp -ErrorAction SilentlyContinue | Format-Table Id, ProcessName
   (Get-ScheduledTask -TaskName 'codeg-server').State
   Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort
   ```

   - プロセスと待ち受けの表は出ず、`Ready` だけが出ればよい
   - 端末で自分が動かしている `grok` は止めない（止めるのは、引数が `agent stdio` のものだけ）
   - 実行中の会話は中断される。会話の履歴は残る

1. もう一度始めるときは、タスクを開始する。

   ```powershell
   if (Get-Process -Name codeg-server -ErrorAction SilentlyContinue) {
     Write-Error 'Codeg はもう動いている'
   } else {
     Start-ScheduledTask -TaskName 'codeg-server'
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     (Get-ScheduledTask -TaskName 'codeg-server').State
     Get-NetTCPConnection -State Listen -LocalPort 3080 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess -AutoSize
   }
   ```

   - `Running` と、3080 の待ち受けが出ればよい

---

## Windows 11 の更新

- Windows 版の Codeg は、画面から自分を入れ替えない。この節の手順で、SHA-256 を照合してから置き換える
- 同じ場所（`%LOCALAPPDATA%\codeg-server`）に置き換えるので、タスクと受信の規則はそのまま使える
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
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $dir = "$env:LOCALAPPDATA\codeg-server"
     $prev = "$env:LOCALAPPDATA\codeg-server.prev"
     $curl = "$env:WINDIR\System32\curl.exe"
     $tmp = "$env:TEMP\codeg-server-setup"
     if (-not $CODEG_VERSION) { Write-Error '中断: この節の手順 1 の変数を設定する'; return }
     if (-not (Test-Path -LiteralPath "$dir\codeg-server.exe")) { Write-Error '中断: Codeg が入っていない'; return }
     if (Test-Path -LiteralPath $prev) { Write-Error "中断: $prev が既にある。前の更新の残りを確かめて消す"; return }
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
     Stop-ScheduledTask -TaskName 'codeg-server'
     Get-Process -Name codeg-server -ErrorAction SilentlyContinue | Stop-Process -Force
     Get-CimInstance Win32_Process -Filter "Name='grok.exe' OR Name='codeg-mcp.exe'" | Where-Object { $_.CommandLine -like '*agent stdio*' -or $_.CommandLine -like '*codeg-delegation*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
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
     Get-NetFirewallApplicationFilter -Program "$dir\codeg-server.exe" -ErrorAction SilentlyContinue | Get-NetFirewallRule | Format-Table Name, Action, Profile -AutoSize
   }
   ```

   - `sha256 一致`、上げた版の番号、`Running`、今までと同じ待ち受けの 1 行が出ればよい
   - [Windows 11 で VPN に公開する](#windows-11-で-vpn-に公開する)を通していれば、規則は `codeg-server-in` の 1 本のまま
   - 起動用のスクリプトとトークンは、そのまま残る
   - 起動しないときは、[Windows 11 で止める・もう一度始める](#windows-11-で止めるもう一度始める)の手順 1 で止め、`codeg-server.prev` の 3 つを `codeg-server` に戻してから、同じ節の手順 2 で始める

1. ブラウザで動くことを確かめてから、前の版を消す。

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\codeg-server.prev" -Recurse -Force
   ```

   - 会話の一覧が残っていて、画面の右下の「新バージョン」が消えていればよい
