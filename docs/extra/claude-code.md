# Claude Code 最新版インストール手順（AlmaLinux 10 は公式 dnf リポジトリ / Windows 11 は公式の native installer）のロールバックと注意点

[手順書](../claude-code.md)・[検証記録](../verification/claude-code.md)・[参考資料](../reference/claude-code.md)

- 「手順 N」は[手順書](../claude-code.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)
- 設定・履歴（`~/.claude/`、`~/.claude.json`、プロジェクト側の `.claude/`、`.mcp.json`）は残る

> [!CAUTION]
> 設定・履歴のファイルを消すと、設定・許可済みツール・MCP サーバー定義・セッション履歴がすべて消える。消す前に中身を確認する。

1. Claude Code を消す。

   ```bash
   sudo dnf remove claude-code
   ```

   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. repo ファイルを消す。

   ```bash
   sudo rm -f /etc/yum.repos.d/claude-code.repo
   ```

1. 鍵も消すときだけ、署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-1a7ecace-69caef70          # 鍵も消す場合
   ```

---

## Windows 11 のロールバック

- 上から順に、Windows PowerShell（5.1）に貼る（変数は使わない）
- 公式の文書（Uninstall Claude Code の Native installation と Remove configuration files）の手順に、本書で見つけた置き場所（更新の名残・キャッシュ・ロック）と `PATH` を足したもの
- [windows-claude-remote-control.md](../windows-claude-remote-control.md) のタスクがあれば、先にそのロールバックを行う
- この節の手順 1〜3 では、設定・履歴・ログインの情報（`%USERPROFILE%\.claude`、`%USERPROFILE%\.claude.json`）と、プロジェクトの `.claude` と `.mcp.json` は残る

> [!CAUTION]
> **この節の手順 4 で `%USERPROFILE%\.claude` と `%USERPROFILE%\.claude.json` を消すと、設定・許可済みのツール・MCP サーバーの定義・セッションの履歴・ログインの情報・ディレクトリの信頼がすべて消える**。入れ直すかもしれないなら、手順 4 は行わない。

1. 動いている Claude Code と、Remote Control のタスクが無いことを確かめる。

   ```powershell
   Get-Process -Name claude -ErrorAction SilentlyContinue | Where-Object Path -like "$env:USERPROFILE\.local\*" | Format-Table Id, Path
   Get-ScheduledTask -TaskName 'claude-remote-control' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   ```

   - どちらも何も出なければよい
   - プロセスが出たら、その Claude Code を `/exit` で終える（動いている `claude.exe` は消せない）
   - タスクが出たら、[windows-claude-remote-control.md のロールバック](windows-claude-remote-control.md#ロールバック)を先に行う

1. Claude Code の実行ファイルと、版・キャッシュ・ロックのフォルダーを消す。

   ```powershell
   Remove-Item -Path "$env:USERPROFILE\.local\bin\claude.exe", "$env:USERPROFILE\.local\bin\claude.exe.old.*" -Force -ErrorAction SilentlyContinue
   Remove-Item -LiteralPath "$env:USERPROFILE\.local\share\claude", "$env:USERPROFILE\.local\state\claude", "$env:USERPROFILE\.cache\claude" -Recurse -Force -ErrorAction SilentlyContinue
   Test-Path "$env:USERPROFILE\.local\bin\claude.exe", "$env:USERPROFILE\.local\share\claude"
   Get-ChildItem -LiteralPath "$env:USERPROFILE\.local\bin" -Force -ErrorAction SilentlyContinue | Format-Table Name
   ```

   - `False` が 2 行出ればよい
   - `True` が出たら、`claude.exe` がまだ動いている。この節の手順 1 からやり直す
   - 最後の一覧が空なら、`.local\bin` にはほかのものが無い（この節の手順 3 で PATH から外せる）

1. [Windows 11 で使う](../claude-code.md#windows-11-で使う)の手順 5 で足したときだけ、PATH から `.local\bin` を外す。

   ```powershell
   & {
     $bin = "$env:USERPROFILE\.local\bin"
     if (Get-ChildItem -LiteralPath $bin -Force -ErrorAction SilentlyContinue) { Write-Error "中断: $bin にほかのファイルがある（ほかのツールが使っている）"; return }
     $entries = @([Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ })
     $rest = @($entries | Where-Object { $_.TrimEnd('\') -ne $bin })
     if ($rest.Count -lt $entries.Count) { [Environment]::SetEnvironmentVariable('Path', ($rest -join ';'), 'User') }
     Remove-Item -LiteralPath $bin -ErrorAction SilentlyContinue
     [Environment]::GetEnvironmentVariable('Path', 'User') -split ';'
   }
   ```

   - 自分のユーザーの PATH が 1 行ずつ出て、その中に `C:\Users\<WIN_USER>\.local\bin` が無ければよい
   - `中断:` が出たら、`.local\bin` をほかのツール（uv など）も使っている。PATH は外さない

1. 完全に消すときだけ、設定・履歴・ログインの情報を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\.claude" -Recurse -Force
   Remove-Item -LiteralPath "$env:USERPROFILE\.claude.json" -Force
   Test-Path "$env:USERPROFILE\.claude", "$env:USERPROFILE\.claude.json"
   ```

   - `False` が 2 行出ればよい
   - Claude Desktop・VS Code の拡張機能・JetBrains のプラグインが入っていると、次に動いたときに `%USERPROFILE%\.claude` がまた作られる（公式の文書。全部消すなら、先にそれらを外す）
   - プロジェクトの `.claude` と `.mcp.json` は、それぞれのプロジェクトのディレクトリで手で消す

---

## 注意点

- **`latest` は不具合のある版もそのまま届く**: `stable` なら飛ばされる版も入る。困ったら [stable チャンネルに切り替える（任意）](../claude-code.md#stable-チャンネルに切り替える任意)
- **自動更新しない**: ネイティブインストーラ版と違い、dnf 版は自分では更新しない
  - `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1` は Homebrew / WinGet 向けで、apt / dnf / apk は root 権限が要るため対象外
- **更新の通知が先に来ることがある**: リポジトリに新しい版が届く前に「更新がある」と言われることがある。その場合は時間をおいて `sudo dnf upgrade claude-code`
- **`claude` が 2 つ入ると混乱する**: ネイティブインストーラや npm で入れたものが `~/.local/bin/claude` にあると、PATH の順序でそちらが勝つ。`command -v claude` と `claude doctor` で確認する
- **アカウントが要る**: 無料の claude.ai プランでは使えない
- **設定ファイルは残る**: `dnf remove` しても `~/.claude` は消えない
- **`-p` は許可を聞けない**: 許可の要るツールは断られ、JSON の `permission_denials` に残る。要るものは `--allowedTools` で渡す（[使い方の基本](../claude-code.md#使い方の基本)）
- **SSH を切ると止まる**: SSH のシェルで起動した `claude` は、切断で止まる。動かし続けるなら tmux の中で起動する（[AlmaLinux 10 の初期設定の tmux の任意節](../almalinux-setup.md#claude-code-を-tmux-の中で動かす任意)）
- **Windows 11 の注意点**
  - **`PATH` は自分で足す**: インストーラも `claude install` も足さない（[Windows 11 で使う](../claude-code.md#windows-11-で使う)の手順 5）。足さないと、開き直した PowerShell でも `claude` が見つからない
  - **Windows PowerShell (x86) では入らない**: `Claude Code does not support 32-bit Windows` で止まる。x86 の付かない「Windows PowerShell」で入れ直す
  - **`claude` が 2 つ入ると混乱する**: WinGet・npm・scoop で入れたものが `PATH` の先にあると、そちらが動く。`Get-Command claude -All` で確かめ、`winget uninstall Anthropic.ClaudeCode` や `npm uninstall -g @anthropic-ai/claude-code` で外す。古い Claude Desktop は `WindowsApps` に `Claude.exe` を置き、`claude` で Desktop が開くので、最新にする（公式の Troubleshoot installation）
  - **更新の後に `claude` が見つからないとき**: Windows の更新は、`claude.exe` を `claude.exe.old.<数字>` に名前を変えてから新しい版を置く。置けず、名前も戻せなかったときは `claude.exe` が無くなる。公式の文書は、一番新しい `claude.exe.old.*` の名前を戻す（`Get-ChildItem "$env:USERPROFILE\.local\bin\claude.exe.old.*" | Sort-Object Name | Select-Object -Last 1 | Rename-Item -NewName claude.exe`）か、入れ直すとしている
  - **`The process cannot access the file` で止まるとき**: 前のインストーラが動いているか、ウイルス対策が `%USERPROFILE%\.claude\downloads` のファイルを調べている。ほかの PowerShell を閉じ、そのフォルダーを消してから入れ直す（公式の Troubleshoot installation）
  - **`irm … | iex` で入れた PowerShell には、インストーラの設定が残る**: `Set-StrictMode -Version Latest` などが残るので、その窓は閉じて開き直す（[Windows 11 で使う](../claude-code.md#windows-11-で使う)の手順 4 の補足）
  - **ログインの情報は `%USERPROFILE%\.claude\.credentials.json`**: パスワードと同じ重みで扱い、ログや issue に貼らない
  - **Windows PowerShell 5.1 のパイプ**: `<コマンド> | claude -p` で日本語を渡すと化けるはず（[使い方の基本](../claude-code.md#使い方の基本)の非対話の注意）
