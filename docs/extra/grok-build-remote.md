# Grok Build をブラウザから操作する手順（Codeg と Caddy / AlmaLinux 10 は systemd のユーザーサービス / Windows 11 はタスク スケジューラ / LAN・VPN 内で HTTPS で使う）のロールバックと注意点

[手順書](../grok-build-remote.md)・[検証記録](../verification/grok-build-remote.md)・[参考資料](../reference/grok-build-remote.md)

- 本書の「<項>の手順 N」は、手順書の `## 実施手順` と `## Windows 11 で使う` の項の手順を指す
- この文書のロールバックは、実機では流していない（[検証記録](../verification/grok-build-remote.md)）

## ロールバック

- AlmaLinux 10 の手順。Windows 11 は [Windows 11 のロールバック](#windows-11-のロールバック)
- Grok Build と、そのセッション（`~/.grok`）は消さない。端末の `grok` は、そのまま使える
- linger を、ほかに使うものが無くて戻すときは、[linger のロールバック](linger.md#ロールバック)

> [!CAUTION]
> **この節の手順 3 は、Codeg の会話の履歴と設定（`~/.local/share/codeg`）、アクセストークン、Caddy の認証局の鍵（`~/.local/share/caddy`）を消す。取り戻せない。** 認証局を消すと、端末に入れたルート証明書は役に立たなくなる。

1. 2 つのサービスを止めて、自動起動を外す。

   ```bash
   systemctl --user disable --now codeg-caddy.service codeg-server.service
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user is-active codeg-caddy.service codeg-server.service
   ss -ltn '( sport = :3080 or sport = :3443 )'
   ```

   - `inactive` が 2 行と、`ss` の見出しの 1 行だけが出ればよい

1. firewalld の規則を外す。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     if [ -z "${SERVER_IP}" ] || [ -z "${ALLOW_FROM}" ] || [ -z "${FW_ZONE}" ]; then
       echo '中断: 「Codeg のサーバーを入れて localhost で起動する」の手順 1 の変数を設定する' >&2
     else
       read -r -a CODEG_SRCS <<<"${ALLOW_FROM}"
       for src in "${CODEG_SRCS[@]}"; do
         CODEG_RULE="rule family=\"ipv4\" priority=\"100\" source address=\"${src}\" destination address=\"${SERVER_IP}\" port port=\"3443\" protocol=\"tcp\" accept"
         sudo firewall-cmd --permanent --zone="${FW_ZONE}" --remove-rich-rule="${CODEG_RULE}"
         sudo firewall-cmd --zone="${FW_ZONE}" --remove-rich-rule="${CODEG_RULE}"
       done
       sudo firewall-cmd --permanent --zone="${FW_ZONE}" --list-rich-rules
       sudo firewall-cmd --zone="${FW_ZONE}" --list-rich-rules
     fi
   }
   ```

   - 「HTTPS で LAN・VPN に公開する」の手順 4 を通していなければ、この手順は飛ばす
   - 送信元ごとに `success` が 2 回ずつ出た後、3443/tcp の規則が runtime と permanent のどちらにも無ければよい
   - 変数の値を控えていなければ、`sudo firewall-cmd --zone="$(sudo firewall-cmd --get-default-zone)" --list-rich-rules` で規則を見て、「Codeg のサーバーを入れて localhost で起動する」の手順 1 の変数に同じ値を入れる

1. ユニット・本体・トークン・会話の履歴・認証局を消す（取り戻せない）。

   - **貼る前に**、ほかの用途と共有している Caddy のパスを確かめる。共有している `~/.local/opt/caddy`（本体）・`~/.config/caddy`（設定）・`~/.local/share/caddy`（認証局データ）は、下の `rm` と `ls` の両方から外す
   - `~/.codeg` は、Codeg が置いたスキル。Codeg のデスクトップアプリをこのホストで使っているなら、`rm` の行から外す

   ```bash
   rm -f ~/.config/systemd/user/codeg-server.service ~/.config/systemd/user/codeg-caddy.service
   systemctl --user daemon-reload
   rm -rf ~/.local/opt/codeg-server ~/.local/opt/codeg-server.prev ~/.config/codeg-server ~/.local/share/codeg ~/.codeg ~/.cache/codeg-server-dl
   rm -rf ~/.local/opt/caddy ~/.config/caddy ~/.local/share/caddy ~/.cache/caddy-dl
   printf '\n\033[7m 確認 \033[0m\n'
   ls -d ~/.local/opt/codeg-server ~/.local/share/codeg ~/.config/codeg-server ~/.config/systemd/user/codeg-server.service ~/.local/opt/caddy ~/.config/caddy ~/.local/share/caddy
   ```

   - `ls` に残したパスが、すべて `No such file or directory` になればよい（外したパスが無ければ 7 つ）
   - Caddy の認証局をほかの用途のために残したときは、手順 4 の端末からのルート証明書の削除も飛ばす
   - ブラウザとスマートフォンに残るトークンは、もう使えない

1. つないでいた端末から、このホストのルート証明書を消す。

   - Android は、設定の「信頼できる認証情報」→「ユーザー」で、`Codeg <ホスト名>` の証明書を開いて削除する
   - Windows の PC は、管理者ではない PowerShell で `Get-ChildItem Cert:\CurrentUser\Root | Where-Object Subject -like 'CN=Codeg *'` で一覧を見て、消すものの `Thumbprint` を確かめてから、「ユーザー証明書の管理」（`certmgr.msc`）の「信頼されたルート証明機関」で削除する

---

## Windows 11 のロールバック

- 手順 1・3 は管理者ではない PowerShell に、手順 2 は管理者の PowerShell に貼る
- Grok Build と、そのセッション（`%USERPROFILE%\.grok`）は消さない
- 端末に入れたルート証明書は、[ロールバック](#ロールバック)の手順 4 と同じ操作で消す

> [!CAUTION]
> **この節の手順 3 は、Codeg の会話の履歴と設定（`%APPDATA%\codeg`）、アクセストークン、Caddy の認証局の鍵（`%APPDATA%\Caddy`）を消す。取り戻せない。**

1. Caddy と Codeg を止めて、タスクを消す。

   - ほかの用途の Caddy をこの PC で動かしているなら、下の 2 行目は貼らず、確認の `Get-Process` の名前からも `caddy` を外す

   ```powershell
   Stop-ScheduledTask -TaskName 'codeg-caddy' -ErrorAction SilentlyContinue
   Get-Process -Name caddy -ErrorAction SilentlyContinue | Stop-Process -Force
   Get-CimInstance Win32_Process -Filter "Name='codeg-server.exe'" |
     Where-Object { $_.ExecutablePath -eq (Join-Path $env:LOCALAPPDATA 'codeg-server\codeg-server.exe') } |
     ForEach-Object { & "$env:WINDIR\System32\taskkill.exe" /PID $_.ProcessId /T /F | Out-Null }
   Stop-ScheduledTask -TaskName 'codeg-server' -ErrorAction SilentlyContinue
   Unregister-ScheduledTask -TaskName 'codeg-caddy' -Confirm:$false -ErrorAction SilentlyContinue
   Unregister-ScheduledTask -TaskName 'codeg-server' -Confirm:$false
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Process -Name codeg-server, codeg-mcp, caddy -ErrorAction SilentlyContinue | Format-Table Id, ProcessName
   Get-ScheduledTask -TaskName 'codeg-server', 'codeg-caddy' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   ```

   - 何も出なければよい

1. 管理者の Windows PowerShell で、受信の規則を消す。

   ```powershell
   Remove-NetFirewallRule -Name 'codeg-caddy-in'
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Name 'codeg-caddy-in' -ErrorAction SilentlyContinue | Format-Table Name, Enabled
   ```

   - 「Windows 11 で HTTPS で LAN・VPN に公開する」の手順 3 を通していなければ、この手順は飛ばす
   - 何も出なければよい

1. 本体・トークン・会話の履歴・認証局を消す（取り戻せない）。

   - **貼る前に**、ほかの用途と共有している Caddy のパスを確かめる。共有している `%LOCALAPPDATA%\codeg-caddy`（本体・設定）・`%APPDATA%\Caddy`（認証局データ）は、下の `Remove-Item` と `Test-Path` の両方から外す
   - `%USERPROFILE%\.codeg` は、Codeg が置いたスキル。Codeg のデスクトップアプリをこの PC で使っているなら、`Remove-Item` の行から外す

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\codeg-server", "$env:LOCALAPPDATA\codeg-server.prev", "$env:APPDATA\codeg", "$env:USERPROFILE\.codeg", "$env:LOCALAPPDATA\codeg-caddy", "$env:APPDATA\Caddy" -Recurse -Force -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path "$env:LOCALAPPDATA\codeg-server", "$env:APPDATA\codeg", "$env:LOCALAPPDATA\codeg-caddy", "$env:APPDATA\Caddy"
   ```

   - `Test-Path` に残したパスが、すべて `False` になればよい（外したパスが無ければ 4 行）
   - Caddy の認証局をほかの用途のために残したときは、端末からのルート証明書の削除も飛ばす

---

## 注意点

#### アクセストークンの重み

- トークンを知っている人は、ブラウザから、そのホストでそのユーザーとして Grok Build を動かせる（ファイルの読み書きとコマンドの実行）
- AlmaLinux 10 の初期設定は NOPASSWD の sudo を入れる。そのホストでは、トークンが root と同じ重みになる
- Codeg の画面には、端末のパネルを開くボタンがある（開いての確認はしていない）
- トークンは 1 つで、利用者ごとの区別や、有効期限は無い
- ブラウザは、入れたトークンを覚える。共用の端末のブラウザでは開かない

#### スマートフォンを失くしたとき

- トークンのファイルを消して作り直し（AlmaLinux 10 は「Codeg のサーバーを入れて localhost で起動する」の手順 5、Windows 11 は「Windows 11 で Codeg のサーバーを入れて起動する」の手順 5）、サービス（Windows 11 はタスク）を起動し直す
- 新しいトークンで起動し直すと、前のトークンは使えなくなる（使い捨てのインスタンスで確かめた。検証記録）
- WireGuard のクライアントの登録も消す（[WireGuard VPN の「クライアントを削除する」](../wireguard.md#クライアントを削除する)）

#### 権限モードと承認の確認

- Codeg の「権限モード」は、Grok Build の `config.toml` の `permission_mode` を書き換える。端末の `grok` と同じ設定になる
- 「常に許可」のとき、Codeg は Grok Build を `--permission-mode bypassPermissions` で起動する。承認の確認は出ない
- 「毎回確認」のとき、ファイルの変更と `rm` は確認が出た。**`mkdir` は確認なしで実行された**（Grok Build が確認を求めなかった）。確認が出ることを、安全の境界にしない
- 承認の選択肢の「Yes, allow all edits during this session」「Yes, and don't ask again for bash commands」は、その会話の以後の確認を省く
- Windows の Grok Build には sandbox が無い。AlmaLinux 10 でも、Codeg は sandbox を足さない

#### 最初の会話のモデル

- Codeg を起動して最初の Grok の会話は、Grok Build の既定と違うモデルで動いた（検証時は、既定が Grok 4.7 のところ Grok 4.6。両 OS）
- 2 つ目以降の会話は、既定のモデルになった。大事な作業の前に、モデルの欄を確かめる

#### トークンが出る場所

- Codeg は、`CODEG_TOKEN` を指定していても、起動のたびに標準エラーへ `[SERVER] Token: …` を出す。AlmaLinux 10 のユニットは `StandardError=null` で捨てる
- Windows 11 のタスクは、見えない窓で動くので残らない。起動用のスクリプトを手で実行すると、その窓に出る
- Codeg 自身のログ（`logs`）と DB には、トークンは入らなかった
- 確認のコマンドでも、トークンを引数に書かない。`curl -H`・`grep` の引数は、実行中のプロセスの一覧に出る

#### 通信と証明書

- 外から届くのは、Caddy が待ち受ける 3443/tcp の HTTPS だけ。Codeg の 3080 番は `127.0.0.1` だけで待ち受け、ファイアウォールでも開けない
- ホストごとに、Caddy が自分の認証局を作る。ルート証明書の期限は 10 年、サーバーの証明書の期限は 12 時間だった。Caddy の文書では、動いている間に自動で作り直す（期限をまたいだ後の動きは、確かめていない）
- サーバーの証明書は、ホストの IP 宛てに作られる。別の名前や IP で開くと、警告が出る
- **認証局の鍵（`root.key`）を、読まない・写さない・人に渡さない**。ルート証明書を入れた端末は、その認証局が署名した証明書を、どのサイトのものでも信じる
- 鍵が漏れた疑いがあるときは、端末からルート証明書を消し、ホストの Caddy のデータ（`~/.local/share/caddy`・`%APPDATA%\Caddy`）を消して起動し直し、新しいルート証明書を入れ直す
- ルート証明書（`root.crt`）は公開してよい。`https://<ホストの IP>:3443/caddy-root.crt` は、許可した送信元なら誰でも取れる
- ルート証明書を入れずに、ブラウザの警告を進んで使うこともできるが、相手が本物かを確かめられない
- Codeg は、どのオリジンからのリクエストも受ける応答（`Access-Control-Allow-Origin: *`）を返す。守りは、トークンと、待ち受ける IP と、送信元の制限
- インターネットへ公開しない

#### 送信元に LAN の帯を入れるとき

- その LAN につながる端末はすべて、ログインの画面まで届く。守りはトークンだけになる
- ルート証明書を入れていない端末からは、警告が出る

#### systemd-analyze --user verify を使わない

- AlmaLinux 10 で `systemd-analyze --user verify` を実行すると、ユーザーの systemd の専用ソケットが作り直され、`systemctl --user` が `Failed to connect to user scope bus … Connection refused` になった
- ユーザーの systemd は動き続ける。`systemctl --user --machine="$(id -un)@.host" daemon-reexec` で専用ソケットが作り直され、元に戻った

#### Windows 11

- SSH でログインしたシェルから Codeg を始めない。Administrators の一員の SSH のセッションは管理者の権限を持つ
- タスクは、サインインしている間だけ動く設定（`-LogonType Interactive`）。サインアウトと再起動の後の動きは、確かめていない
- PC の IPv4 が変わると、Caddy の待ち受け・証明書の宛先・受信の規則が合わなくなる。ルーターで固定の割り当てにする
- 受信の規則より先に Caddy を起動しない。Windows が許可を尋ねる画面を出す

#### そのほか

- Codeg は Grok Build を `--no-auto-update` で起動する。Grok Build は、端末で `grok update` を実行して上げる
- Codeg の画面の「エージェント」の設定にある「アップグレード」（Codeg が勧める版の Grok Build への入れ替え）は使っていない
- 「ファイルとコマンドをエージェント自身に処理させる」は、既定の無効のまま使う。有効にしても、`mkdir` が確認なしで実行される結果は変わらなかった
- 取り込みの画面は、そのホストのほかのエージェントとプロジェクトのセッションの題名も一覧に出す
- Codeg の子プロセス（`codeg-mcp`）の引数に、内部用の値（`--token <UUID>`）が出る。アクセストークンとは別のもの
- Codeg は Grok Build 以外のエージェント（Claude Code・Codex など）も扱える。本書は Grok Build だけを扱う
