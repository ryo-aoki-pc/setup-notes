# Grok Build のブラウザ操作のロールバックと注意点

[AlmaLinux 10 の手順](../ai-agents.md#grok-build-のブラウザ操作-almalinux-10-で使う)・[Windows 11 の手順](../ai-agents.md#grok-build-のブラウザ操作-windows-11-で使う)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/grok-build-remote.md)・[参考資料](../reference/grok-build-remote.md)

- 本書の「<項>の手順 N」は、各正本の「Grok Build のブラウザ操作」の該当項を指す
- Codeg の撤去の既存部分は、2026-10-14 に Windows 11 の実機で通した（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/grok-build-remote.md#付録-windows-11-の入れ直しと共通パスワード3-エージェントの接続の検証2026-10-14-jst)）。自動更新に関する撤去・復旧と、パスを残す分岐は実機で未確認

## AlmaLinux 10 で自動更新の控えから前の版と DB に戻す

- 対象: AlmaLinux 10。Windows 11 は [Windows 11 で自動更新の控えから前の版と DB に戻す](#windows-11-で自動更新の控えから前の版と-db-に戻す)
- 前提: Codeg と自動更新を入れてある。本人の bash で、この節の手順を同じシェルに貼る。トークンのファイルは開かない
- 終了コード 3 または `in-progress` が残ったときも使う。通常は完成した `bin/` と `db/` の組を選ぶ。`in-progress` があれば目印の `backup` と `new` を指定する。`backing-up`・`restart-failed` は元の DB を保持して旧本体を揃える
- 復元プログラムが排他・控え・段階を確認してから Codeg を止め、本体と DB を戻して旧版の起動を確認する。前提が一致しなければ、変更せず終了コード 1 で止まる
- ファイルを移す前に停止に失敗した場合は、元の本体を再開して同じ起動確認を行う。再開できれば目印を解除して終了コード 1。再開できない場合や、復元開始後の失敗は控えを保全して終了コード 3 にする

> [!WARNING]
> **この節の手順 3 で通常の控えを戻すと、更新後の会話と設定は、控えを取った時点へ戻る。** 現在の本体と DB は `failed-manual-<UTC日時>` に退避する。`backing-up`・`restart-failed` の復旧では元の DB を保持する。復旧が済むまで、控えを消さない。

1. 自動更新を止めて、途中の段階と控えの名前を確かめる。

   ```bash
   systemctl --user disable --now codeg-auto-update.timer
   systemctl --user stop codeg-auto-update.service
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user is-active codeg-auto-update.timer codeg-auto-update.service
   if [ -f ~/.local/state/codeg-auto-update/in-progress ]; then
     cat ~/.local/state/codeg-auto-update/in-progress
   fi
   find ~/.local/state/codeg-auto-update/backups -mindepth 1 -maxdepth 2 -type d -print
   tail -n 20 ~/.local/state/codeg-auto-update/codeg-auto-update.log
   ```

   - タイマーとサービスが両方 `inactive` ならよい。止まらなければ先へ進まない
   - `in-progress` があれば `stage`・`backup`・`old`・`new` を確かめる
   - 控えの名前と問題の起きた版を控える。目印があれば `backup` の末尾の名前と `new` を使う
   - `backing-up`・`restart-failed` は控えの実体がまだ無くても、目印の予定名を使う
   - `failed-*` は復元元に選ばない

1. 復元元の名前と保留する版を設定する（両方とも必ず値を入れる）。

   ```bash
   CODEG_BACKUP_NAME=''               # backups の直下の名前（日時-旧版）
   ```

   ```bash
   CODEG_SKIP_VERSION=''              # 問題の起きた版（先頭の v は付けない）
   ```

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   printf '復元元: %s\n保留: %s\n' "${CODEG_BACKUP_NAME}" "${CODEG_SKIP_VERSION}"
   ```

   - 復元元はこの節の手順 1 で確認した控えにする。保留するのは戻す旧版ではなく、問題の起きた新しい版にする

1. 復元プログラムを実行し、結果と旧版を確かめる。

   ```bash
   if [ -z "${CODEG_BACKUP_NAME}" ] || [ -z "${CODEG_SKIP_VERSION}" ]; then
     echo '中断: この節の手順 2 の変数を設定する' >&2
   else
     printf '\n\033[7m 確認 \033[0m\n'
     ~/.local/bin/codeg-auto-update --restore "${CODEG_BACKUP_NAME}" --hold "${CODEG_SKIP_VERSION}"
     CODEG_RESTORE_RESULT=$?
     printf '終了コード: %s\n' "${CODEG_RESTORE_RESULT}"
     tail -n 20 ~/.local/state/codeg-auto-update/codeg-auto-update.log
     if [ "${CODEG_RESTORE_RESULT}" -eq 0 ]; then
       ~/.local/opt/codeg-server/codeg-server --version
     fi
   fi
   ```

   - 終了コード 0 で、表示された版が選んだ旧版ならよい。問題の版は保留され、`in-progress` は解除される
   - 終了コード 1 は、前提不一致で未変更、または停止失敗後に元の本体を再開できた状態。復元は未完了。この節の手順 4・5 へ進まず、ログの原因に対処して手順 1 からやり直す
   - 終了コード 3 は、元の本体の再開または復元の完了を確認できない状態。この節の手順 4・5 へ進まず、ログと控えを保持して復旧を依頼する

1. ブラウザで、復元した会話の一覧と再開を確かめる。

   - HTTPS の Codeg で、必要な会話が見つかり再開できればよい。問題があれば手順 5 へ進まない

1. 復旧を確認できた場合だけ、自動更新を再開する。

   ```bash
   systemctl --user enable --now codeg-auto-update.timer
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user list-timers codeg-auto-update.timer
   ```

   - 次回の時刻が出ればよい。保留は残す。試し直すときは[AlmaLinux 10 の更新](../ai-agents.md#grok-build-のブラウザ操作-almalinux-10-の更新)の保留を解く手順を通す

---

## AlmaLinux 10 のロールバック

- AlmaLinux 10 の手順。Windows 11 は [Windows 11 のロールバック](#windows-11-のロールバック)
- Grok Build と、そのセッション（`~/.grok`）は消さない。端末の `grok` は、そのまま使える
- linger を、ほかに使うものが無くて戻すときは、[linger のロールバック](linger.md#ロールバック)
- 手順 3 を貼る前に、Codeg のデスクトップアプリを使っているホストでは `~/.codeg` を `rm` から外す
- 共通の Caddy と認証局は残す。撤去は、すべてのサイトを外してから [Caddy のロールバック](caddy.md#共通の-caddy-を撤去する)で行う

> [!CAUTION]
> **この節の手順 3 は、Codeg の会話の履歴と設定（`~/.local/share/codeg`）、アクセストークンを消す。取り戻せない。**

1. 自動更新と Codeg を止め、Codeg のサイトだけを共通の Caddy から外す。

   ```bash
   systemctl --user disable --now codeg-auto-update.timer
   systemctl --user stop codeg-auto-update.service
   if [ -e ~/.config/caddy/sites/codeg.caddy ] && ! grep -qx '# setup-notes: grok-build-remote' ~/.config/caddy/sites/codeg.caddy; then
     echo '中断: この手順の Codeg サイトではない' >&2
   else
     systemctl --user disable --now codeg-server.service &&
     { [ ! -e ~/.config/caddy/sites/codeg.caddy ] || mv ~/.config/caddy/sites/codeg.caddy ~/.config/caddy/codeg.caddy.removed; }
     printf '\n\033[7m 確認 \033[0m\n'
     systemctl --user is-active codeg-server.service codeg-auto-update.timer codeg-auto-update.service
   fi
   ```

   - 3 つとも `inactive` ならよい。自動更新を入れていなければ、そのユニットの `not found` は無視してよい
   - 止まらないユニットがあれば、この節の手順 2・3 へ進まない
   - サイトを外した場合は [Caddy: 設定を検査して起動し直す](../almalinux-setup.md#caddy-設定を検査して起動し直す)を通す
   - 検査や起動に失敗したら、`mv ~/.config/caddy/codeg.caddy.removed ~/.config/caddy/sites/codeg.caddy` で戻し、同じ項を通し直す
   - Caddy を起動し直した後に、`ss -ltn '( sport = :3080 or sport = :3443 )'` で両ポートの待ち受けが無いことを確かめる。ほかのサイトの Caddy は動かしたままにする

1. firewalld の規則を外す。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     if [ -z "${SERVER_IP}" ] || [ -z "${FW_ZONE}" ]; then
       echo '中断: 「Codeg のサーバーを入れて localhost で起動する」の手順 1 の変数を設定する' >&2
     else
       CODEG_DST_RULE="rule priority=\"100\" family=\"ipv4\" destination address=\"${SERVER_IP}\" port port=\"3443\" protocol=\"tcp\" accept"
       CODEG_DST_OK=1
       for CODEG_SCOPE in permanent runtime; do
         CODEG_FW_ARGS=(--zone="${FW_ZONE}")
         if [ "${CODEG_SCOPE}" = permanent ]; then
           CODEG_FW_ARGS+=(--permanent)
         fi
         if sudo firewall-cmd "${CODEG_FW_ARGS[@]}" --query-rich-rule="${CODEG_DST_RULE}" >/dev/null; then
           if ! sudo firewall-cmd "${CODEG_FW_ARGS[@]}" --remove-rich-rule="${CODEG_DST_RULE}"; then
             CODEG_DST_OK=0
           fi
         else
           CODEG_QUERY_STATUS=$?
           if [ "${CODEG_QUERY_STATUS}" -ne 1 ]; then
             CODEG_DST_OK=0
           fi
         fi
       done
       if [ "${CODEG_DST_OK}" -ne 1 ]; then
         echo '中断: 送信元指定の無い規則の確認または削除に失敗した' >&2
       else
         if [ -n "${ALLOW_FROM:-}" ]; then
           read -r -a CODEG_SRCS <<<"${ALLOW_FROM}"
           for src in "${CODEG_SRCS[@]}"; do
             CODEG_RULE="rule family=\"ipv4\" priority=\"100\" source address=\"${src}\" destination address=\"${SERVER_IP}\" port port=\"3443\" protocol=\"tcp\" accept"
             sudo firewall-cmd --permanent --zone="${FW_ZONE}" --remove-rich-rule="${CODEG_RULE}"
             sudo firewall-cmd --zone="${FW_ZONE}" --remove-rich-rule="${CODEG_RULE}"
           done
         fi
         sudo firewall-cmd --permanent --zone="${FW_ZONE}" --list-rich-rules
         sudo firewall-cmd --zone="${FW_ZONE}" --list-rich-rules
       fi
     fi
   }
   ```

   - 「HTTPS で LAN・VPN に公開する」の手順 4 を通していなければ、この手順は飛ばす
   - 送信元指定の無い任意構成の規則は、存在する場合だけ runtime と permanent から削除する。`ALLOW_FROM` が空でも、この規則の削除は行う
   - 削除した規則に `success` が出た後、3443/tcp の規則が runtime と permanent のどちらにも無ければよい
   - 規則の確認・削除で中断した場合や、`ALLOW_FROM` が不明で送信元付きの規則が残る場合は、この節の手順 3 へ進まない
   - 変数の値を控えていなければ、`sudo firewall-cmd --zone="$(sudo firewall-cmd --get-default-zone)" --list-rich-rules` で規則を見て、「Codeg のサーバーを入れて localhost で起動する」の手順 1 の変数に同じ値を入れる

1. ユニット・本体・トークン・会話の履歴を消す（取り戻せない）。

   ```bash
   rm -f ~/.config/systemd/user/codeg-server.service ~/.config/systemd/user/codeg-auto-update.service ~/.config/systemd/user/codeg-auto-update.timer ~/.local/bin/codeg-auto-update ~/.config/caddy/codeg.caddy.removed
   systemctl --user daemon-reload
   rm -rf ~/.local/opt/codeg-server ~/.local/opt/.codeg-server.new ~/.config/codeg-server ~/.local/share/codeg ~/.local/state/codeg-auto-update ~/.codeg ~/.cache/codeg-server-dl
   printf '\n\033[7m 確認 \033[0m\n'
   ls -d ~/.local/opt/codeg-server ~/.local/share/codeg ~/.config/codeg-server ~/.config/systemd/user/codeg-server.service ~/.local/state/codeg-auto-update ~/.local/bin/codeg-auto-update ~/.config/systemd/user/codeg-auto-update.service ~/.config/systemd/user/codeg-auto-update.timer
   ```

   - `ls` に残したパスが、すべて `No such file or directory` になればよい（外したパスが無ければ 8 つ）
   - 端末のルート証明書は残す。共通の Caddy を撤去するときだけ [端末からルート証明書を消す](caddy.md#端末からルート証明書を消す)を通す
   - ブラウザとスマートフォンに残るトークンは、もう使えない

---

## Windows 11 で自動更新の控えから前の版と DB に戻す

- 対象: Windows 11。管理者ではない Windows PowerShell 5.1 の同じ窓に貼る。Codeg と自動更新を入れてあること
- 終了コード 3 または `in-progress` が残ったときも使う。通常は完成した `bin\` と `db\` の組を選ぶ。`in-progress` があれば目印の `backup` と `new` を指定する。`backing-up`・`restart-failed` は元の DB を保持して旧本体 3 つを揃える
- 復元プログラムが排他・控え・段階を確認してから Codeg を止め、旧版を起動して待ち受けと HTTP を確認する。前提が一致しなければ変更せず終了コード 1 で止まる。`token.txt` は開かない
- ファイルを移す前に停止に失敗した場合は、元の本体を再開して同じ起動確認を行う。再開できれば目印を解除して終了コード 1。再開できない場合や、復元開始後の失敗は控えを保全して終了コード 3 にする

> [!WARNING]
> **この節の手順 3 で通常の控えを戻すと、更新後の会話と設定は、控えを取った時点へ戻る。** 現在の本体 3 つと DB は `failed-manual-<UTC日時>` へ退避する。`backing-up`・`restart-failed` の復旧では元の DB を保持する。復旧が済むまで、控えを消さない。

1. 自動更新を止めて、途中の段階と控えの名前を確かめる。

   ```powershell
   Disable-ScheduledTask -TaskName 'codeg-auto-update' | Out-Null
   Stop-ScheduledTask -TaskName 'codeg-auto-update'
   $CodegState = Join-Path $env:LOCALAPPDATA 'codeg-auto-update'
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ScheduledTask -TaskName 'codeg-auto-update' | Format-Table TaskName, State
   $CodegMarker = Join-Path $CodegState 'in-progress'
   if (Test-Path -LiteralPath $CodegMarker) { Get-Content -LiteralPath $CodegMarker -Encoding UTF8 }
   Get-ChildItem -LiteralPath (Join-Path $CodegState 'backups') -Directory | Select-Object Name
   Get-Content -LiteralPath (Join-Path $CodegState 'codeg-auto-update.log') -Encoding UTF8 -Tail 20
   ```

   - 自動更新のタスクが `Disabled` で `Running` でなければよい
   - `in-progress` があれば `stage`・`backup`・`old`・`new` を確かめる
   - 控えの名前と問題の起きた版を控える。目印があれば `backup` の末尾の名前と `new` を使う
   - `backing-up`・`restart-failed` は控えの実体がまだ無くても、目印の予定名を使う
   - `failed-*` は復元元に選ばない

1. 復元元の名前と保留する版を設定する（両方とも必ず値を入れる）。

   ```powershell
   $CodegBackupName = ''              # backups の直下の名前（日時-旧版）
   ```

   ```powershell
   $CodegSkipVersion = ''             # 問題の起きた版（先頭の v は付けない）
   ```

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   "復元元: $CodegBackupName"
   "保留: $CodegSkipVersion"
   ```

   - 復元元はこの節の手順 1 で確認した控えにする。保留するのは戻す旧版ではなく、問題の起きた新しい版にする

1. 復元プログラムを実行し、結果と旧版を確かめる。

   ```powershell
   & {
     if ([string]::IsNullOrWhiteSpace($CodegBackupName) -or [string]::IsNullOrWhiteSpace($CodegSkipVersion)) { throw '中断: この節の手順 2 の変数を設定する' }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     powershell.exe -NoProfile -File "$env:LOCALAPPDATA\codeg-auto-update\codeg-auto-update.ps1" -Restore $CodegBackupName -Hold $CodegSkipVersion
     $CodegRestoreResult = $LASTEXITCODE
     "終了コード: $CodegRestoreResult"
     Get-Content -LiteralPath "$env:LOCALAPPDATA\codeg-auto-update\codeg-auto-update.log" -Encoding UTF8 -Tail 20
     if ($CodegRestoreResult -eq 0) { & "$env:LOCALAPPDATA\codeg-server\codeg-server.exe" --version }
   }
   ```

   - 終了コード 0 で、表示された版が選んだ旧版ならよい。問題の版は保留され、`in-progress` は解除される
   - 終了コード 1 は、前提不一致で未変更、または停止失敗後に元の本体を再開できた状態。復元は未完了。この節の手順 4・5 へ進まず、ログの原因に対処して手順 1 からやり直す
   - 終了コード 3 は、元の本体の再開または復元の完了を確認できない状態。この節の手順 4・5 へ進まず、ログと控えを保持して復旧を依頼する

1. ブラウザで、復元した会話の一覧と再開を確かめる。

   - HTTPS の Codeg で、必要な会話が見つかり再開できればよい。問題があれば手順 5 へ進まない

1. 復旧を確認できた場合だけ、自動更新を再開する。

   ```powershell
   Enable-ScheduledTask -TaskName 'codeg-auto-update' | Out-Null
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ScheduledTaskInfo -TaskName 'codeg-auto-update' | Format-List NextRunTime
   ```

   - 次回の時刻が出ればよい。保留は残す。試し直すときは[Windows 11 の更新](../ai-agents.md#grok-build-のブラウザ操作-windows-11-の更新)の保留を解く手順を通す

---

## Windows 11 のロールバック

- 手順 1・3 は管理者ではない PowerShell に、手順 2 は管理者の PowerShell に貼る
- Grok Build と、そのセッション（`%USERPROFILE%\.grok`）は消さない
- 端末に入れたルート証明書は、[Caddy の「端末からルート証明書を消す」](caddy.md#端末からルート証明書を消す)と同じ操作で消す
- 手順 1 を貼る前に、ほかの用途の Caddy をこの PC で動かしているなら、`Get-Process -Name caddy` の行を外し、確認の `Get-Process` の名前からも `caddy` を外す
- 手順 3 を貼る前に、消してはいけないパスをブロックから外す。ほかの用途と共有している `%LOCALAPPDATA%\codeg-caddy`（本体・設定）・`%APPDATA%\Caddy`（認証局データ）は `Remove-Item` と `Test-Path` の両方から、Codeg のデスクトップアプリをこの PC で使っているときの `%USERPROFILE%\.codeg`（Codeg が置いたスキル）は `Remove-Item` から外す

> [!CAUTION]
> **この節の手順 3 は、Codeg の会話の履歴と設定（`%APPDATA%\codeg`）、アクセストークン、Caddy の認証局の鍵（`%APPDATA%\Caddy`）を消す。取り戻せない。**

1. 自動更新が終わっていることを確かめ、Caddy・Codeg を止めてタスクを消す。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     $updateTask = Get-ScheduledTask -TaskName 'codeg-auto-update' -ErrorAction SilentlyContinue
     if ($updateTask -and $updateTask.State -eq 'Running') { throw '中断: 自動更新が終わってから、この節の手順 1 をやり直す' }
     $state = Join-Path $env:LOCALAPPDATA 'codeg-auto-update'
     $updateLock = $null
     if (Test-Path -LiteralPath $state) {
       try { $updateLock = [IO.File]::Open((Join-Path $state 'lock'), 'OpenOrCreate', 'ReadWrite', 'None') }
       catch { throw '中断: 自動更新のロックを取れない。更新が終わってから、この節の手順 1 をやり直す' }
     } elseif ($updateTask) { throw '中断: 自動更新の状態フォルダーを確認できない' }
     try {
       if ($updateTask) {
         Stop-ScheduledTask -TaskName 'codeg-auto-update'
         Unregister-ScheduledTask -TaskName 'codeg-auto-update' -Confirm:$false
       }
     } finally { if ($updateLock) { $updateLock.Dispose() } }
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
     Get-ScheduledTask -TaskName 'codeg-server', 'codeg-caddy', 'codeg-auto-update' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   }
   ```

   - 何も出なければよい
   - `中断` やエラーが出たら、この節の手順 2・3 へ進まない。自動更新が `Running` の間は完了を待ってから、この節の手順 1 をやり直す

1. 管理者の Windows PowerShell で、受信の規則を消す。

   ```powershell
   $exe = Join-Path $env:LOCALAPPDATA 'codeg-caddy\caddy.exe'
   Get-NetFirewallRule -Name 'codeg-caddy-in', 'codeg-caddy-block-public' -ErrorAction SilentlyContinue |
     Where-Object { ($_ | Get-NetFirewallApplicationFilter).Program -eq $exe } |
     Remove-NetFirewallRule
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Name 'codeg-caddy-in', 'codeg-caddy-block-public' -ErrorAction SilentlyContinue | Format-Table Name, Enabled
   ```

   - 「Windows 11 で HTTPS で LAN・VPN に公開する」の手順 3 を通していなければ、この手順は飛ばす
   - この手順で作る 2 本だけを消す。ほかのプログラムの規則は変更しない
   - 何も出なければよい

1. 本体・トークン・会話の履歴・認証局を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\codeg-server", "$env:LOCALAPPDATA\codeg-auto-update", "$env:APPDATA\codeg", "$env:USERPROFILE\.codeg", "$env:LOCALAPPDATA\codeg-caddy", "$env:APPDATA\Caddy" -Recurse -Force -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path "$env:LOCALAPPDATA\codeg-server", "$env:LOCALAPPDATA\codeg-auto-update", "$env:APPDATA\codeg", "$env:LOCALAPPDATA\codeg-caddy", "$env:APPDATA\Caddy"
   ```

   - `Test-Path` に残したパスが、すべて `False` になればよい（外したパスが無ければ 5 行）
   - Caddy の認証局をほかの用途のために残したときは、端末からのルート証明書の削除も飛ばす

---

## Windows 11 の共通パスワードの復元

- [共通パスワードの変更](../ai-agents.md#grok-build-のブラウザ操作-windows-11-で-codeg-の共通パスワードを設定変更する)で失敗したときに使う。Codeg の削除や Caddy の停止は行わない
- 控えと認証ファイルの本文は、表示・共有しない。`password-change-result.json` は変更スクリプトと同じディレクトリにあり、秘密の値を含まない

1. 変更スクリプトの今回の結果を見て、復元の状態を確かめる。

   - `StartedAtUtc` が今回の開始時刻であることを確かめる。JSON を保存できなかった場合は、今回のコンソール出力を使う。`-CheckOnly` は結果ファイルを更新しない
   - 前提確認・入力で未変更のまま終わった場合は、[共通パスワードの変更](../ai-agents.md#grok-build-のブラウザ操作-windows-11-で-codeg-の共通パスワードを設定変更する)の手順 1 へ戻る。復元へ進まない。古い実行の結果を今回の結果として使わない
   - 変更処理後の `Outcome=failed` では、`FailureStage`・`CredentialReplaced`・`FileUnchanged`・`FileRestored`・`ServiceRestored`・`BackupFile` を確かめる
   - `CredentialReplaced`・`FileUnchanged` が `null` なら、変更の有無が未確認。未変更として再実行せず、控えを保持して認証ファイルと専用サービスの状態の確認を依頼する
   - ファイルが未変更か復元済みで、`ServiceRestored=true` なら手順 3 へ進む。`OldPasswordVerified` は `false` のままで、旧認証でのログイン成功は未確認
   - `CredentialReplaced=false`・`FileUnchanged=true`・`BackupFile=null` なら、認証ファイルの置き換え前に失敗している。`token.txt` を戻さず、サービスが未復帰なら手順 2 のサービスだけを復旧する
   - `BackupFile` に今回の控えの名前があり、復元が未完了なら、控えを保持して手順 2 へ進む。控えの実ファイルが無いときは、別の実行の控えを代用せずに中断する
   - `CleanupFailed` が `true` なら、`CleanupFile` の一時ファイルも秘密を含む。復旧が終わるまで本人だけの権限で保持し、本文を出さない

1. 自動復元が完了していなければ、ファイルまたは専用サービスの復旧を依頼する。

   - ファイル未変更の分岐では、既存の `token.txt` の存在・本人の所有・継承無し・本人だけの ACL を確かめる。ファイルは変更せず、タスクと待ち受けを確認してサービスだけを復旧する
   - 控えから戻す場合は、本人が今回の `BackupFile` を選ぶ。保存先は `%LOCALAPPDATA%\codeg-server`。`Join-Path` と `GetFullPath` で同じ専用ディレクトリ内に収まること、実ファイルがあることを確認する
   - 控えの所有者が本人で、ACL の継承が無効・本人だけの権限であることを確かめる。欠ける条件があれば、控えを読み出したりコピーしたりせず中断する
   - 停止するのは、専用の `codeg-server.exe` と一致する PID だけ。停止直前に実行パス・開始時刻・3080 番の所有者を照合し、子プロセスを止める `/T` は使わない
   - `codeg-server` タスクが `Ready` になり、3080 番が解放されたことを確かめる。控えから戻す場合だけ、控えを `token.txt` へ戻す。秘密の本文を読まず、本人だけの ACL を確かめる
   - ファイルの未変更または復元後に専用タスクを起動し、`Running`・専用実行パス・`127.0.0.1:3080`・未認証 401 を確かめる。ファイルとサービスのどちらかが未確認なら、ログインへ進まない

1. 本人が、変更前の認証値で HTTPS の Codeg にログインする。

   - ログイン後の画面が表示されれば、旧認証でのログインも確認できた。入力値をエージェントや復旧担当へ渡さない
   - 入れなければ中断し、控えを保持したまま、ファイルとサービスの復元結果を確認する

---

## 接続元の制限を戻す

- AlmaLinux 10 で送信元制限を外した任意構成を戻す。元の `SERVER_IP`・`ALLOW_FROM`・`FW_ZONE` を設定した同じ端末で、旧規則の追加を確認してから送信元指定の無い規則を削除する
- この 2 ブロックは構文・公開スタブの検査だけで、実機での復帰は未実施。規則の確認や追加で失敗したら、送信元指定の無い規則の削除へ進まない

1. 元の送信元の規則を runtime と permanent に戻す。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     CODEG_SOURCES_READY=0
     if [ -z "${SERVER_IP}" ] || [ -z "${ALLOW_FROM}" ] || [ -z "${FW_ZONE}" ]; then
       echo '中断: 元の SERVER_IP・ALLOW_FROM・FW_ZONE を設定する' >&2
     else
       CODEG_SOURCES_READY=1
       read -r -a CODEG_SRCS <<<"${ALLOW_FROM}"
       if [ "${#CODEG_SRCS[@]}" -eq 0 ]; then
         CODEG_SOURCES_READY=0
       fi
       for src in "${CODEG_SRCS[@]}"; do
         CODEG_RULE="rule family=\"ipv4\" priority=\"100\" source address=\"${src}\" destination address=\"${SERVER_IP}\" port port=\"3443\" protocol=\"tcp\" accept"
         for CODEG_SCOPE in permanent runtime; do
           CODEG_FW_ARGS=(--zone="${FW_ZONE}")
           if [ "${CODEG_SCOPE}" = permanent ]; then
             CODEG_FW_ARGS+=(--permanent)
           fi
           if ! sudo firewall-cmd "${CODEG_FW_ARGS[@]}" --add-rich-rule="${CODEG_RULE}" ||
             ! sudo firewall-cmd "${CODEG_FW_ARGS[@]}" --query-rich-rule="${CODEG_RULE}"; then
             CODEG_SOURCES_READY=0
           fi
         done
       done
       if [ "${CODEG_SOURCES_READY}" -ne 1 ]; then
         echo '中断: 元の送信元の規則を確認できない。送信元指定の無い規則は残す' >&2
       fi
       sudo firewall-cmd --permanent --zone="${FW_ZONE}" --list-rich-rules
       sudo firewall-cmd --zone="${FW_ZONE}" --list-rich-rules
     fi
   }
   ```

   - 元の送信元ごとの規則が runtime と permanent の両方にあり、各照会が `yes` ならよい
   - `中断` が出たら、この節の手順 2 へ進まない

1. 元の規則を再確認してから、送信元指定の無い規則を削除する。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     if [ -z "${SERVER_IP}" ] || [ -z "${ALLOW_FROM}" ] || [ -z "${FW_ZONE}" ] || [ "${CODEG_SOURCES_READY:-0}" -ne 1 ]; then
       echo '中断: 同じ端末でこの節の手順 1 の成功を確認する' >&2
     else
       read -r -a CODEG_SRCS <<<"${ALLOW_FROM}"
       if [ "${#CODEG_SRCS[@]}" -eq 0 ]; then
         CODEG_SOURCES_READY=0
       fi
       for src in "${CODEG_SRCS[@]}"; do
         CODEG_RULE="rule family=\"ipv4\" priority=\"100\" source address=\"${src}\" destination address=\"${SERVER_IP}\" port port=\"3443\" protocol=\"tcp\" accept"
         if ! sudo firewall-cmd --permanent --zone="${FW_ZONE}" --query-rich-rule="${CODEG_RULE}" ||
           ! sudo firewall-cmd --zone="${FW_ZONE}" --query-rich-rule="${CODEG_RULE}"; then
           CODEG_SOURCES_READY=0
         fi
       done
       if [ "${CODEG_SOURCES_READY}" -ne 1 ]; then
         echo '中断: 元の送信元の規則を確認できない。送信元指定の無い規則は残す' >&2
       else
         CODEG_DST_RULE="rule priority=\"100\" family=\"ipv4\" destination address=\"${SERVER_IP}\" port port=\"3443\" protocol=\"tcp\" accept"
         for CODEG_SCOPE in permanent runtime; do
           CODEG_FW_ARGS=(--zone="${FW_ZONE}")
           if [ "${CODEG_SCOPE}" = permanent ]; then
             CODEG_FW_ARGS+=(--permanent)
           fi
           if sudo firewall-cmd "${CODEG_FW_ARGS[@]}" --query-rich-rule="${CODEG_DST_RULE}" >/dev/null; then
             if ! sudo firewall-cmd "${CODEG_FW_ARGS[@]}" --remove-rich-rule="${CODEG_DST_RULE}"; then
               echo '中断: 送信元指定の無い規則の削除に失敗した' >&2
             fi
           else
             CODEG_QUERY_STATUS=$?
             if [ "${CODEG_QUERY_STATUS}" -ne 1 ]; then
               echo '中断: 送信元指定の無い規則を確認できない' >&2
             fi
           fi
         done
         sudo firewall-cmd --permanent --zone="${FW_ZONE}" --list-rich-rules
         sudo firewall-cmd --zone="${FW_ZONE}" --list-rich-rules
       fi
     fi
   }
   ```

   - 元の送信元付きの規則だけが runtime と permanent にあり、送信元指定の無い 3443/tcp の規則が残っていなければよい
   - `中断` が出たら、規則の読み戻しを確認するまで復帰完了と扱わない

---

## AlmaLinux 10 の共通パスワード変更で失敗したとき

- [共通パスワードの設定・変更](../ai-agents.md#grok-build-のブラウザ操作-codeg-の共通パスワードを設定変更する)の補助スクリプトを実行した本人が確認する。Codeg の削除や Caddy の停止は行わない
- 旧設定の退避はファイル名だけを表示する。認証ファイルや退避の本文を開かず、パスワードをエージェントや復旧担当へ渡さない
- 失敗時の復帰は公開 fixture で検証した。実ホストでの失敗からの復帰と、旧認証によるログインは未確認（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/grok-build-remote.md#付録-almalinux-102-の3エージェント接続と共通パスワードの検証2026-10-13-jst)）

1. 本人の端末で、今回の終了コードと表示された結果を確認する。

   - 終了コード 0 は設定成功。新認証 200・未認証 401・誤入力 401 を同じ Codeg の worker で確認した場合だけ成功になる。旧設定の退避は保持される
   - 終了コード 1 と「旧設定へ戻しました」は、旧ファイル・サービス・未認証 401 の復帰を確認した失敗。変更は完了していない。前提確認・入力の失敗で 1 になった場合は、変更へ進んでいない
   - 終了コード 2 の「結果: 不明」は、ファイルまたはサービスの復帰を確認できていない。再実行を止め、表示された退避を保全する。この節の手順 2 へ進まない

1. 復帰を確認できた場合だけ、本人が変更前の値で HTTPS にログインする。

   - 終了コード 1 の「旧設定へ戻しました」を確認した場合に行う。未認証 401 の成功だけでは、旧認証によるログイン成功とは扱わない
   - ログイン後の画面が表示されれば、旧認証も確認できた。入力値は本人だけが扱う
   - 入れなければ中断し、退避を保持したまま、ファイルとサービスの復帰結果を確認する

---

## 注意点

#### アクセストークンの重み

- トークンを知っている人は、ブラウザから、そのホストでそのユーザーとして有効なエージェントを動かせる（Grok Build・Claude Code・Codex によるファイルの読み書きとコマンドの実行）
- AlmaLinux 10 の初期設定は NOPASSWD の sudo を入れる。そのホストでは、トークンが root と同じ重みになる
- Codeg の画面には、端末のパネルを開くボタンがある（開いての確認はしていない）
- トークンは 1 つで、利用者ごとの区別や、有効期限は無い
- ブラウザは、入れたトークンを覚える。共用の端末のブラウザでは開かない

#### スマートフォンを失くしたとき

- トークンのファイルを消して作り直し（AlmaLinux 10 は「Codeg のサーバーを入れて localhost で起動する」の手順 5、Windows 11 は「Windows 11 で Codeg のサーバーを入れて起動する」の手順 5）、サービス（Windows 11 はタスク）を起動し直す
- 新しいトークンで起動し直すと、前のトークンは使えなくなる（使い捨てのインスタンスで確かめた。検証記録）
- WireGuard のクライアントの登録も消す（[WireGuard VPN の「クライアントを削除する」](../wireguard.md#wireguard-クライアントを削除する)）

#### 権限モードと承認の確認

- Codeg の「権限モード」は、Grok Build の `config.toml` の `permission_mode` を書き換える。端末の `grok` と同じ設定になる
- 承認を減らして使う本書の用途では「スマート自動承認」（`auto`）を選ぶ。Grok の自動審査が許可しない操作は、確認が出るか拒否される。設定の保存と、新しい会話での応答が未確認なら、その部分は未完了として扱う
- 「常に許可」のとき、Codeg は Grok Build を `--permission-mode bypassPermissions` で起動する。承認の確認は出ない
- 「毎回確認」のとき、ファイルの変更と `rm` は確認が出た。**`mkdir` は確認なしで実行された**（Grok Build が確認を求めなかった）。確認が出ることを、安全の境界にしない
- 承認の選択肢の「Yes, allow all edits during this session」「Yes, and don't ask again for bash commands」は、その会話の以後の確認を省く
- Windows の Grok Build には sandbox が無い。AlmaLinux 10 でも、Codeg は sandbox を足さない

#### Claude Code・Codex の共有設定と履歴

- 任意節（[AlmaLinux 10](../ai-agents.md#grok-build-のブラウザ操作-claude-code-と-codex-cli-も操作する)・[Windows 11](../ai-agents.md#grok-build-のブラウザ操作-windows-11-で-claude-code-と-codex-cli-も操作する)）の手順 3 で設定を保存すると、Claude の `~/.claude/settings.json` や Codex の `~/.codex/config.toml` など、端末の CLI と共有する設定も変わる。Windows 11 では同じユーザーの `%USERPROFILE%` 配下
- 認証方法を変える前に、本人が既存の方式と必要な設定を確かめる。既に「公式サブスクリプション」なら保存し直さない。別のアカウントへのログインも、端末の CLI に影響する
- 既存の API 用の項目がある場合は、認証方法の保存で削除・変更されることがある。エージェントへ設定ファイルの全文やログイン情報を渡さない
- 接続アダプターには別のランタイムが入る。CLI と同じホームの設定・MCP・フックなどを使い得るので、Codeg に追加しただけで既存設定から隔離されたとは扱わない
- `Auto`・`Auto review` では、自動審査が許可した操作は確認無しで進む。Claude の `Auto` が使えない状態では、手動運用を選ぶ場合に `Manual` へ変える。既存の Grok の承認の結果を、両エージェントの結果として扱わない
- 履歴を取り込む前に元の CLI・アプリで同じ会話を閉じ、同時に書き込まない。中断しても実行済みの変更は戻らないため、再開前に差分を確かめる
- Codeg を止める・撤去するだけでは、各 CLI の認証・設定・履歴は元に戻らない。元に戻す場合は本人が変更した設定を確かめ、各 CLI の設定手順で戻す。履歴やログイン情報をまとめて削除する操作は行わない

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
- AlmaLinux 10 の認証局は、同じホストの Forgejo などと共通で使う。作り直すと全サイトに影響する。Windows 11 は Codeg 専用の認証局を使う。ルート証明書の期限は 10 年、サーバーの証明書の期限は 12 時間だった。Caddy の文書では、動いている間に自動で作り直す（期限をまたいだ後の動きは、確かめていない）
- AlmaLinux 10 のサーバーの証明書は、ホストの IP 宛てに作られる。別の名前や IP で開くと、警告が出る
- Windows 11 の PC の証明書は、接続された IP アドレスごとに、その場で作られる
- **認証局の鍵（`root.key`）を、読まない・写さない・人に渡さない**。ルート証明書を入れた端末は、その認証局が署名した証明書を、どのサイトのものでも信じる
- 鍵が漏れた疑いがあるときは、端末からルート証明書を消し、AlmaLinux 10 は [Caddy の注意点](caddy.md#注意点)に従って全サイトへの影響を確認する。Windows 11 はホストの Caddy のデータ（`%APPDATA%\Caddy`）を消して起動し直し、新しいルート証明書を入れ直す
- ルート証明書（`root.crt`）は公開してよい。`https://<ホストの IP>:3443/caddy-root.crt` は、AlmaLinux 10 の標準構成では許可した送信元 CIDR 内、送信元制限を外した任意構成では宛先の LAN IPv4 に届く全送信元から、トークンなしで取得できる。Windows 11 は Private の受信インターフェースへ届く全送信元が対象
- ルート証明書を入れずに、ブラウザの警告を進んで使うこともできるが、相手が本物かを確かめられない
- Codeg は、どのオリジンからのリクエストも受ける応答（`Access-Control-Allow-Origin: *`）を返す。AlmaLinux 10 の標準構成は待ち受ける IP と送信元を絞り、任意構成では宛先を残して送信元制限を外す。Windows 11 は受信側の Private という条件だけで、全送信元・全接続種別を許可する。接続後の認証はトークンで行う
- インターネットへ公開しない

#### AlmaLinux 10 の送信元に LAN の帯を入れるとき

- この項は AlmaLinux 10 の `ALLOW_FROM` に対する注意。Windows 11 は送信元 CIDR の指定が不要で、受信インターフェースが Private なら全送信元を許可する
- その LAN につながる端末はすべて、ログインの画面まで届く。守りはトークンだけになる
- ルート証明書を入れていない端末からは、警告が出る

#### systemd-analyze --user verify を使わない

- AlmaLinux 10 で `systemd-analyze --user verify` を実行すると、ユーザーの systemd の専用ソケットが作り直され、`systemctl --user` が `Failed to connect to user scope bus … Connection refused` になった
- ユーザーの systemd は動き続ける。`systemctl --user --machine="$(id -un)@.host" daemon-reexec` で専用ソケットが作り直され、元に戻った

#### Windows 11

- SSH でログインしたシェルから Codeg を始めない。Administrators の一員の SSH のセッションは管理者の権限を持つ
- ランチャーのソース・実行ファイルは、`%LOCALAPPDATA%\codeg-server` の中にある。[Windows 11 のロールバック](#windows-11-のロールバック)の手順 3 で、このフォルダーとともに消す
- Caddy の起動用 `start-caddy-hidden.ps1` は、`%LOCALAPPDATA%\codeg-caddy` の中にある
- 非表示起動のランチャーを使った OS 再起動・サインアウト後の動作は未確認
- タスクは、サインインしている間だけ動く設定（`-LogonType Interactive`）。再起動した後も、本人のサインインが必要。再起動・サインアウト後の実測は、検証記録の対象・実施日ごとの範囲を参照する
- Caddy は、待ち受ける IP を決めずに、この PC のすべてのアドレスで待ち受ける。受信インターフェースが Private なら、IPv4・IPv6 の全送信元・全接続種別で 3443/tcp に届く。有線 LAN・Wi-Fi・VPN を区別しない
- LAN には有線 LAN と Wi-Fi が含まれる。VPN からの通信も、ホスト側で実際に受信するインターフェースが Private であることが必要
- 信頼する接続だけを Private にする。公衆 Wi-Fi などほかの接続は Public のままにし、Codeg に届かせるために Private へ変えない
- Public・Domain の受信インターフェースは遮断する。Private にした接続に到達できる端末はすべて、ログインの画面と公開のルート証明書まで届く。Edge Traversal は許可しない
- PC の IP が変わると、つなぐ URL が変わる。ブラウザは別のサイトとして扱うので、トークンを入れ直す
- 接続できる端末は、Caddy に、任意の名前の証明書を作らせられる（`on_demand`。Caddy は起動のときに警告を出す）。Windows は送信元を制限しないので、Private にした接続へ届く端末はすべてこの機能を利用できる
- 受信の規則より先に Caddy を起動しない。Windows が許可を尋ねる画面を出す
- タスク スケジューラの「失敗時の再起動」は使っていない。終了コードが 0 でないだけのタスクは、再起動されなかった

#### そのほか

- Codeg は Grok Build を `--no-auto-update` で起動する。Grok Build は、端末で `grok update` を実行して上げる
- Codeg の画面の「エージェント」の設定にある「アップグレード」（Codeg が勧める版の Grok Build への入れ替え）は使っていない
- 「ファイルとコマンドをエージェント自身に処理させる」は、既定の無効のまま使う。有効にしても、`mkdir` が確認なしで実行される結果は変わらなかった
- 取り込みの画面は、そのホストのほかのエージェントとプロジェクトのセッションの題名も一覧に出す
- Codeg の子プロセス（`codeg-mcp`）の引数に、内部用の値（`--token <UUID>`）が出る。アクセストークンとは別のもの
- Claude Code・Codex も使う場合は、任意節（[AlmaLinux 10](../ai-agents.md#grok-build-のブラウザ操作-claude-code-と-codex-cli-も操作する)・[Windows 11](../ai-agents.md#grok-build-のブラウザ操作-windows-11-で-claude-code-と-codex-cli-も操作する)）を通す。エージェントごとの実測と未確認の範囲は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/grok-build-remote.md#付録-claude-codecodex-の操作手順の追加2026-10-12-jst)で区別する
