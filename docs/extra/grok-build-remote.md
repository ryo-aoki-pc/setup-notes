# Grok Build をブラウザから操作する手順（Codeg / AlmaLinux 10 は systemd のユーザーサービス / Windows 11 はタスク スケジューラ / LAN・VPN 内で使う）のロールバックと注意点

[手順書](../grok-build-remote.md)・[検証記録](../verification/grok-build-remote.md)・[参考資料](../reference/grok-build-remote.md)

- 本書の「<項>の手順 N」は、手順書の `## 実施手順` と `## Windows 11 で使う` の項の手順を指す
- この文書のロールバックは、実機では流していない（[検証記録](../verification/grok-build-remote.md)）

## ロールバック

- AlmaLinux 10 の手順。Windows 11 は [Windows 11 のロールバック](#windows-11-のロールバック)
- Grok Build と、そのセッション（`~/.grok`）は消さない。端末の `grok` は、そのまま使える
- linger を、ほかに使うものが無くて戻すときは、[linger のロールバック](linger.md#ロールバック)

> [!CAUTION]
> **この節の手順 3 は、Codeg の会話の履歴と設定（`~/.local/share/codeg`）と、アクセストークンを消す。取り戻せない。**

1. サービスを止めて、自動起動を外す。

   ```bash
   systemctl --user disable --now codeg-server.service
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user is-active codeg-server.service
   ss -ltn '( sport >= :3080 and sport <= :3090 )'
   ```

   - `inactive` と、`ss` の見出しの 1 行だけが出ればよい

1. firewalld の規則を外す。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     if [ -z "${SERVER_IP}" ] || [ -z "${ALLOW_FROM}" ] || [ -z "${FW_ZONE}" ]; then
       echo '中断: 「Codeg のサーバーを入れて localhost で起動する」の手順 1 の変数を設定する' >&2
     else
       CODEG_RULE="rule family=\"ipv4\" priority=\"100\" source address=\"${ALLOW_FROM}\" destination address=\"${SERVER_IP}\" port port=\"3080\" protocol=\"tcp\" accept"
       sudo firewall-cmd --permanent --zone="${FW_ZONE}" --remove-rich-rule="${CODEG_RULE}"
       sudo firewall-cmd --zone="${FW_ZONE}" --remove-rich-rule="${CODEG_RULE}"
       sudo firewall-cmd --permanent --zone="${FW_ZONE}" --list-rich-rules
       sudo firewall-cmd --zone="${FW_ZONE}" --list-rich-rules
     fi
   }
   ```

   - 「VPN に公開する」の手順 1 を通していなければ、この手順は飛ばす
   - `success` が 2 回出た後、3080/tcp の規則が runtime と permanent のどちらにも無ければよい
   - 変数の値を控えていなければ、`sudo firewall-cmd --zone="$(sudo firewall-cmd --get-default-zone)" --list-rich-rules` で規則を見て、「Codeg のサーバーを入れて localhost で起動する」の手順 1 の変数に同じ値を入れる

1. ユニット・本体・トークン・会話の履歴を消す（取り戻せない）。

   ```bash
   rm -f ~/.config/systemd/user/codeg-server.service
   systemctl --user daemon-reload
   rm -rf ~/.local/opt/codeg-server ~/.local/opt/codeg-server.prev ~/.config/codeg-server ~/.local/share/codeg ~/.codeg ~/.cache/codeg-server-dl
   printf '\n\033[7m 確認 \033[0m\n'
   ls -d ~/.local/opt/codeg-server ~/.local/share/codeg ~/.config/codeg-server ~/.config/systemd/user/codeg-server.service
   ```

   - `ls` が 4 つとも `No such file or directory` になればよい
   - `~/.codeg` は、Codeg が置いたスキル。Codeg のデスクトップアプリをこのホストで使っているなら、ブロックから外す
   - ブラウザとスマートフォンに残るトークンは、もう使えない

---

## Windows 11 のロールバック

- 手順 1・3 は管理者ではない PowerShell に、手順 2 は管理者の PowerShell に貼る
- Grok Build と、そのセッション（`%USERPROFILE%\.grok`）は消さない

> [!CAUTION]
> **この節の手順 3 は、Codeg の会話の履歴と設定（`%APPDATA%\codeg`）と、アクセストークンを消す。取り戻せない。**

1. Codeg を止めて、タスクを消す。

   ```powershell
   Stop-ScheduledTask -TaskName 'codeg-server' -ErrorAction SilentlyContinue
   Get-Process -Name codeg-server -ErrorAction SilentlyContinue | Stop-Process -Force
   Get-CimInstance Win32_Process -Filter "Name='grok.exe' OR Name='codeg-mcp.exe'" | Where-Object { $_.CommandLine -like '*agent stdio*' -or $_.CommandLine -like '*codeg-delegation*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
   Unregister-ScheduledTask -TaskName 'codeg-server' -Confirm:$false
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Process -Name codeg-server, codeg-mcp -ErrorAction SilentlyContinue | Format-Table Id, ProcessName
   Get-ScheduledTask -TaskName 'codeg-server' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   ```

   - 何も出なければよい

1. 管理者の Windows PowerShell で、受信の規則を消す。

   ```powershell
   Remove-NetFirewallRule -Name 'codeg-server-in'
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Name 'codeg-server-in' -ErrorAction SilentlyContinue | Format-Table Name, Enabled
   ```

   - 「Windows 11 で VPN に公開する」の手順 1 を通していなければ、この手順は飛ばす
   - 何も出なければよい

1. 本体・トークン・会話の履歴を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\codeg-server", "$env:LOCALAPPDATA\codeg-server.prev", "$env:APPDATA\codeg", "$env:USERPROFILE\.codeg" -Recurse -Force -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path "$env:LOCALAPPDATA\codeg-server", "$env:APPDATA\codeg"
   ```

   - `False` が 2 行出ればよい
   - `%USERPROFILE%\.codeg` は、Codeg が置いたスキル。Codeg のデスクトップアプリをこの PC で使っているなら、ブロックから外す

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

#### 通信

- HTTP のままで、内容は暗号化されない。VPN の区間だけが暗号化される。LAN の端末を `ALLOW_FROM` に入れると、その区間はトークンも平文で流れる
- Codeg は、どのオリジンからのリクエストも受ける応答（`Access-Control-Allow-Origin: *`）を返す。守りは、トークンと、待ち受ける IP と、送信元の制限
- インターネットへ公開しない。公開するなら、TLS を終端するリバースプロキシが要る（本書の範囲外）

#### systemd-analyze --user verify を使わない

- AlmaLinux 10 で `systemd-analyze --user verify` を実行すると、ユーザーの systemd の専用ソケットが作り直され、`systemctl --user` が `Failed to connect to user scope bus … Connection refused` になった
- ユーザーの systemd は動き続ける。`systemctl --user --machine="$(id -un)@.host" daemon-reexec` で専用ソケットが作り直され、元に戻った

#### Windows 11

- SSH でログインしたシェルから Codeg を始めない。Administrators の一員の SSH のセッションは管理者の権限を持つ
- タスクは、サインインしている間だけ動く設定（`-LogonType Interactive`）。サインアウトと再起動の後の動きは、確かめていない
- PC の IPv4 が変わると、待ち受けと受信の規則の両方が合わなくなる。ルーターで固定の割り当てにする
- 受信の規則より先に待ち受けを変えない。Windows が許可を尋ねる画面を出す

#### そのほか

- Codeg は Grok Build を `--no-auto-update` で起動する。Grok Build は、端末で `grok update` を実行して上げる
- Codeg の画面の「エージェント」の設定にある「アップグレード」（Codeg が勧める版の Grok Build への入れ替え）は使っていない
- 「ファイルとコマンドをエージェント自身に処理させる」は、既定の無効のまま使う。有効にしても、`mkdir` が確認なしで実行される結果は変わらなかった
- 取り込みの画面は、そのホストのほかのエージェントとプロジェクトのセッションの題名も一覧に出す
- Codeg の子プロセス（`codeg-mcp`）の引数に、内部用の値（`--token <UUID>`）が出る。アクセストークンとは別のもの
- Codeg は Grok Build 以外のエージェント（Claude Code・Codex など）も扱える。本書は Grok Build だけを扱う
