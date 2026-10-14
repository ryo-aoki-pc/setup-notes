# AI コーディングエージェントのセットアップのロールバックと注意点

[手順書](../ai-agents.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md)・[参考資料](../reference/ai-agents.md)

- 手順書の実施手順は項（###）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 任意の構成のロールバックと注意点は、それぞれの文書にある: [コーディングエージェントの共同作業](coding-agents.md)・[Grok Build のブラウザ操作](grok-build-remote.md)・[Claude Code の GNOME 操作](claude-code-gui.md)・[Claude Code の Remote Control](windows-claude-remote-control.md)

## ロールバック

- 対象: AlmaLinux 10。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)
- 残す項目の手順は飛ばす。[AI エージェントとプラグインを消す](#ai-エージェントとプラグインを消す)の手順で、Codex・Grok のプラグインは 1、Claude Code は 2〜4、Codex CLI は 5〜7、Grok Build は 8〜11
- 「Codex CLI」の手順 2 のパッケージは残す
- [Claude Code を tmux の中で動かす（任意）](../ai-agents.md#claude-code-を-tmux-の中で動かす任意)で Remote Control を動かしているなら、[AI エージェントとプラグインを消す](#ai-エージェントとプラグインを消す)の前に、その節の手順 8 で止める
- [コーディングエージェントの共同作業](coding-agents.md#ロールバック)など、任意の構成で入れたものは、それぞれのロールバックで先に戻す

> [!CAUTION]
> [AI エージェントとプラグインを消す](#ai-エージェントとプラグインを消す)の手順 11 は、**`~/.grok`（ログイン情報・会話の記録・設定・信頼したフォルダーの記録・Grok が作った worktree）を消す**（取り戻せない。入れ直すかもしれないなら、行わない）。Claude Code の設定・履歴（`~/.claude/`・`~/.claude.json`）は、この節では消さない。手で消すと、設定・許可済みツール・MCP サーバー定義・セッション履歴がすべて消える（消す前に中身を確認する）。

### AI エージェントとプラグインを消す

1. 2 つのプラグインとマーケットプレイスを外す。

   ```bash
   claude plugin uninstall codex@openai-codex
   claude plugin uninstall grok-build@xai-grok-build
   claude plugin marketplace remove openai-codex
   claude plugin marketplace remove xai-grok-build
   printf '\n\033[7m 確認 \033[0m\n'
   claude plugin list
   ```

   - 最後の一覧に、2 つのプラグインが出なければよい
   - プラグインのデータ（`~/.claude/plugins/data/` の下）も消える
   - Node.js は、ここでは外さない（[端末とエディタを消す](almalinux-setup.md#端末とエディタを消す)の手順 5）

1. Claude Code を消す。

   ```bash
   sudo dnf remove claude-code
   ```

   - 設定・履歴（`~/.claude/`、`~/.claude.json`、プロジェクト側の `.claude/`、`.mcp.json`）は残る
   - 確認用のディレクトリ `~/claude-sandbox`（[Claude Code](../ai-agents.md#claude-code)の手順 5）も残る。要らなければ手で消す
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. repo ファイルを消す。

   ```bash
   sudo rm -f /etc/yum.repos.d/claude-code.repo
   ```

1. 鍵も消すときだけ、署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-1a7ecace-69caef70          # 鍵も消す場合
   ```

1. 起動中の Codex を終了し、ログイン情報も外す場合はログアウトする。

   ```bash
   codex logout
   ```

   - ログイン情報を共有するエディタの拡張機能なども、次回ログインが必要になる

1. この手順で入れたリンクと配布物を消す。

   ```bash
   rm -f ~/.local/bin/codex ~/.local/bin/codex-code-mode-host
   rm -rf ~/.codex/packages/standalone
   hash -r
   printf '\n\033[7m 確認 \033[0m\n'
   command -v codex
   ```

   - 最後に何も出なければ、PATH 上に Codex は無い
   - パスが出る場合は、別の導入方法の Codex が残っている
   - `~/.codex` 全体は消さない（設定・会話履歴などが入っている）
   - 確認用のディレクトリ `~/codex-sandbox`（[Codex CLI](../ai-agents.md#codex-cli)の手順 8）も残る。要らなければ手で消す

1. インストーラーが PATH のブロックを足した場合だけ、シェルの設定を戻す。

   - `~/.bashrc` の `# >>> Codex installer >>>` から `# <<< Codex installer <<<` までをエディタで削除する
   - `~/.local/bin` 自体や、ほかのツールが書いた PATH の行は消さない
   - 新しい端末を開いて確認する

1. 起動中の Grok を終了し、ログイン情報も外すならログアウトする。

   ```bash
   grok logout
   ```

   - ログインしていなければ `No cached session to log out of.` と出る

1. この手順で入れたリンクと配布物を消す。

   ```bash
   for f in ~/.local/bin/grok ~/.local/bin/agent; do
     case "$(readlink "$f")" in
       "$HOME/.grok/"*) rm -f "$f" ;;
     esac
   done
   rm -f ~/.grok/bin/grok ~/.grok/bin/agent
   rm -rf ~/.grok/downloads ~/.grok/completions
   hash -r
   printf '\n\033[7m 確認 \033[0m\n'
   command -v grok agent
   ```

   - 最後に何も出なければ、PATH 上に Grok は無い
   - `~/.local/bin` の `grok`・`agent` は、`~/.grok` を指すリンクだけを消す（ほかのツールの `agent` は残る）
   - パスが出る場合は、別の導入方法の Grok か、別のツールの `agent` が残っている
   - 確認用のディレクトリ `~/grok-sandbox`（[Grok Build](../ai-agents.md#grok-build)の手順 7）も残る。要らなければ手で消す

1. インストーラーが `~/.bashrc` に足したブロックを消す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if grep -qx '# >>> grok installer >>>' ~/.bashrc && grep -qx '# <<< grok installer <<<' ~/.bashrc; then
     sed -i --follow-symlinks '/^# >>> grok installer >>>$/,/^# <<< grok installer <<<$/d' ~/.bashrc
     grep -c 'grok' ~/.bashrc
   else
     echo '中断: ~/.bashrc に grok installer の印が 2 つそろっていない。エディタで確かめる' >&2
   fi
   ```

   - 最後に `0` が出れば、`~/.bashrc` に Grok の行は無い（ほかに grok を含む行を自分で書いていれば、その数が出る）
   - ブロックの前の空行は残る。`~/.bashrc.bak.<数字>` も残るので、要らなければ手で消す
   - 新しい端末を開いて確かめる
   - この項の手順 8〜10 で、ログイン・CLI・PATH の設定を外す。ログイン情報・会話の記録・設定（`~/.grok` の残り）は残る

1. 完全に消すときだけ、`~/.grok` を消す（取り戻せない）。

   ```bash
   rm -rf ~/.grok
   printf '\n\033[7m 確認 \033[0m\n'
   ls -ld ~/.grok
   ```

   - `No such file or directory` になればよい
   - Grok が作った worktree（`~/.grok/worktrees` の下）も消える。中の作業が要るなら、先に取り込む

---

## Windows 11 のロールバック

- 対象: Windows 11
- [Windows 11 で AI エージェントとプラグインを消す](#windows-11-で-ai-エージェントとプラグインを消す)のすべての手順は、[Windows 11 のセットアップの「Microsoft Store の更新」](../windows-setup.md#microsoft-store-の更新)の手順 1 と同じ管理者ではない Windows PowerShell（5.1）に貼る
- 残す項目の手順は飛ばす。同じ項の手順で、Codex・Grok のプラグインは 1、Claude Code は 2〜5、Codex CLI は 6〜9、Grok Build は 10〜14
- [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md#ロールバック)は、Claude Code と WezTerm を使う。同じ項より前に戻す
- [コーディングエージェントの共同作業](coding-agents.md#windows-11-のロールバック)も、同じ項より前に戻す

> [!CAUTION]
> [Windows 11 で AI エージェントとプラグインを消す](#windows-11-で-ai-エージェントとプラグインを消す)の手順 5 は **Claude Code の設定・許可済みのツール・MCP サーバーの定義・セッションの履歴・ログインの情報・ディレクトリの信頼を**、同じ項の手順 14 は **Grok のログイン情報・会話の記録・設定・信頼したフォルダーの記録・Grok が作った worktree を消す**（取り戻せない）。入れ直すかもしれないなら、その手順は行わない。

### Windows 11 で AI エージェントとプラグインを消す

1. 2 つのプラグインとマーケットプレイスを外す。

   ```powershell
   claude plugin uninstall codex@openai-codex
   claude plugin uninstall grok-build@xai-grok-build
   claude plugin marketplace remove openai-codex
   claude plugin marketplace remove xai-grok-build
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   claude plugin list
   ```

   - 最後の一覧に、2 つのプラグインが出なければよい
   - Node.js は、ここでは外さない（[エディタとシェルのツールを消す](windows-setup.md#エディタとシェルのツールを消す)の手順 6）

1. 動いている Claude Code と、Remote Control のタスクが無いことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
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
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path "$env:USERPROFILE\.local\bin\claude.exe", "$env:USERPROFILE\.local\share\claude"
   Get-ChildItem -LiteralPath "$env:USERPROFILE\.local\bin" -Force -ErrorAction SilentlyContinue | Format-Table Name
   ```

   - `False` が 2 行出ればよい
   - `True` が出たら、`claude.exe` がまだ動いている。この項の手順 2 からやり直す
   - 最後の一覧が空なら、`.local\bin` にはほかのものが無い（この項の手順 4 で PATH から外せる）
   - 公式の文書（Uninstall Claude Code の Native installation と Remove configuration files）の手順に、本書で見つけた置き場所（更新の名残・キャッシュ・ロック）と `PATH` を足したもの

1. [Windows 11 で Claude Code を入れる](../ai-agents.md#windows-11-で-claude-code-を入れる)の手順 4 で足したときだけ、PATH から `.local\bin` を外す。

   ```powershell
   & {
     $bin = "$env:USERPROFILE\.local\bin"
     if (Get-ChildItem -LiteralPath $bin -Force -ErrorAction SilentlyContinue) { Write-Error "中断: $bin にほかのファイルがある（ほかのツールが使っている）"; return }
     $entries = @([Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ })
     $rest = @($entries | Where-Object { $_.TrimEnd('\') -ne $bin })
     if ($rest.Count -lt $entries.Count) { [Environment]::SetEnvironmentVariable('Path', ($rest -join ';'), 'User') }
     Remove-Item -LiteralPath $bin -ErrorAction SilentlyContinue
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     [Environment]::GetEnvironmentVariable('Path', 'User') -split ';'
   }
   ```

   - 自分のユーザーの PATH が 1 行ずつ出て、その中に `C:\Users\<WIN_USER>\.local\bin` が無ければよい
   - `中断:` が出たら、`.local\bin` をほかのツール（uv など）も使っている。PATH は外さない
   - この項の手順 2〜4 では、設定・履歴・ログインの情報（`%USERPROFILE%\.claude`、`%USERPROFILE%\.claude.json`）と、プロジェクトの `.claude` と `.mcp.json` は残る

1. 完全に消すときだけ、設定・履歴・ログインの情報を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\.claude" -Recurse -Force
   Remove-Item -LiteralPath "$env:USERPROFILE\.claude.json" -Force
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path "$env:USERPROFILE\.claude", "$env:USERPROFILE\.claude.json"
   ```

   - `False` が 2 行出ればよい
   - Claude Desktop・VS Code の拡張機能・JetBrains のプラグインが入っていると、次に動いたときに `%USERPROFILE%\.claude` がまた作られる（公式の文書。全部消すなら、先にそれらを外す）
   - プロジェクトの `.claude` と `.mcp.json` は、それぞれのプロジェクトのディレクトリで手で消す

1. 起動中の Codex を終了し、ログイン情報も外す場合はログアウトする。

   ```powershell
   codex logout
   ```

   - ログイン情報を共有するエディタの拡張機能なども、次回ログインが必要になる
   - 本書の既定の場所に入れた standalone 版が対象。設定・会話履歴と、Windows sandbox が作ったユーザー・ポリシーなどは残る。OS の sandbox 設定を元に戻す操作は、この項には含めない

1. Codex の入口と配布物をエクスプローラーで削除する。

   - `%LOCALAPPDATA%\Programs\OpenAI\Codex\bin` のジャンクションを削除する（リンク先の中へ入って削除しない）
   - `%USERPROFILE%\.codex\packages\standalone` を削除する
   - `%USERPROFILE%\.codex` 全体は削除しない（設定・会話履歴などが入っている）
   - 確認用のディレクトリ `%USERPROFILE%\codex-sandbox`（[Windows 11 で Codex CLI を入れる](../ai-agents.md#windows-11-で-codex-cli-を入れる)の手順 8）も、要らなければ削除する

1. ユーザー用 PATH から Codex の入口を外す。

   - スタートメニューで「環境変数」を検索し、自分のアカウントの環境変数を開く
   - ユーザー環境変数の `Path` から `%LOCALAPPDATA%\Programs\OpenAI\Codex\bin` に相当する行だけを削除する
   - PowerShell と、その親の Windows Terminal などを閉じて開き直す

1. PATH 上に Codex が残っていないか確かめる。

   ```powershell
   Get-Command codex -All -ErrorAction SilentlyContinue
   ```

   - 何も出なければ、この CLI の入口は外れている
   - パスが出る場合は、別の導入方法の Codex が残っている

1. 動いている Grok が無いことを確かめ、ログイン情報も外すならログアウトする。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Process -Name grok, agent -ErrorAction SilentlyContinue | Format-Table Id, Path
   grok logout
   ```

   - 1 行目で何も出なければよい。プロセスが出たら、その Grok を `/quit` で終えてから、このブロックを貼り直す
   - ログインしていなければ `No cached session to log out of.` と出る
   - 本書の既定の場所に入れた Grok が対象（WinGet で入れたものは WinGet で外す）

1. 実行ファイル・配布物・Grok が使う Git を消す。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\.grok\bin", "$env:USERPROFILE\.grok\downloads", "$env:USERPROFILE\.grok\completions", "$env:LOCALAPPDATA\grok\git" -Recurse -Force -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path "$env:USERPROFILE\.grok\bin", "$env:LOCALAPPDATA\grok\git"
   ```

   - `False` が 2 行出ればよい
   - `True` が出たら、`grok.exe` がまだ動いている。この項の手順 10 からやり直す
   - 確認用のディレクトリ `%USERPROFILE%\grok-sandbox`（[Windows 11 で Grok Build を入れる](../ai-agents.md#windows-11-で-grok-build-を入れる)の手順 8）も、要らなければ削除する

1. 自分のユーザーの PATH から `%USERPROFILE%\.grok\bin` を外す。

   ```powershell
   & {
     $bin = "$env:USERPROFILE\.grok\bin"
     $entries = @([Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ })
     $rest = @($entries | Where-Object { $_.TrimEnd('\') -ne $bin })
     if ($rest.Count -lt $entries.Count) { [Environment]::SetEnvironmentVariable('Path', ($rest -join ';'), 'User') }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     [Environment]::GetEnvironmentVariable('Path', 'User') -split ';'
   }
   ```

   - 自分のユーザーの PATH が 1 行ずつ出て、その中に `C:\Users\<WIN_USER>\.grok\bin` が無ければよい

1. PowerShell を閉じ、スタートメニューから開き直してから、PATH 上に Grok が残っていないか確かめる。

   ```powershell
   Get-Command grok, agent -All -ErrorAction SilentlyContinue
   ```

   - 何も出なければ、この CLI の入口は外れている
   - パスが出る場合は、別の導入方法の Grok か、別のツールの `agent` が残っている
   - この項の手順 10〜13 では、設定・会話の記録・ログイン情報（`%USERPROFILE%\.grok` の残り）は残る

1. 完全に消すときだけ、`%USERPROFILE%\.grok` を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\.grok" -Recurse -Force
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path "$env:USERPROFILE\.grok"
   ```

   - `False` が出ればよい

---

## 注意点

- **Claude Code の `Ctrl+B` は、tmux の中では 2 回押す**: `Ctrl+b` → `Ctrl+b` で中のアプリに `Ctrl+b` を送る
- **Remote Control の性質**（公式ドキュメント。[Windows 11 の Remote Control の注意点](windows-claude-remote-control.md#注意点)にも同じ内容）
  - このホストからは外向きの HTTPS だけで、受信のポートは開けない
  - つないでいる間、会話の転写（メッセージ・応答・ツールの動き）は Anthropic のサーバーに保存される
  - ネットワークが約 10 分切れると、`claude remote-control` は自分で終わる。tmux の中のシェルは残るので、[Claude Code を tmux の中で動かす（任意）](../ai-agents.md#claude-code-を-tmux-の中で動かす任意)の手順 8 で入り、その節の手順 4 のコマンドを打ち直す
  - 止めてから約 4 時間以内なら、`claude remote-control` で同じセッションが戻る
  - `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`・`DISABLE_GROWTHBOOK`・`ANTHROPIC_BASE_URL`（`api.anthropic.com` 以外）があると使えない
- **tmux でマウスを on にすると、Claude Code の画面でもホイールは tmux が受け取る**: コンテナの Claude Code（ログインしていない最初の画面）は、マウスの報告も代替画面も使っていなかった（`#{mouse_any_flag}` と `#{alternate_on}` が 0）。ホイールは tmux のコピーモードに入る
- **Claude Code: `latest` は不具合のある版もそのまま届く**: `stable` なら飛ばされる版も入る。困ったら [Claude Code を stable チャンネルに切り替える（任意）](../ai-agents.md#claude-code-を-stable-チャンネルに切り替える任意)
- **Claude Code: 自動更新しない**: ネイティブインストーラ版と違い、dnf 版は自分では更新しない
  - `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1` は Homebrew / WinGet 向けで、apt / dnf / apk は root 権限が要るため対象外
- **Claude Code: 更新の通知が先に来ることがある**: リポジトリに新しい版が届く前に「更新がある」と言われることがある。その場合は時間をおいて `sudo dnf upgrade claude-code`
- **Claude Code: `claude` が 2 つ入ると混乱する**: ネイティブインストーラや npm で入れたものが `~/.local/bin/claude` にあると、PATH の順序でそちらが勝つ。`command -v claude` と `claude doctor` で確認する
- **Claude Code: アカウントが要る**: 無料の claude.ai プランでは使えない
- **Claude Code: 設定ファイルは残る**: `dnf remove` しても `~/.claude` は消えない
- **Claude Code: `-p` は許可を聞けない**: 許可の要るツールは断られ、JSON の `permission_denials` に残る。要るものは `--allowedTools` で渡す（[Claude Code の使い方の基本](../ai-agents.md#claude-code-の使い方の基本)）
- **Claude Code: SSH を切ると止まる**: SSH のシェルで起動した `claude` は、切断で止まる。動かし続けるなら tmux の中で起動する（[Claude Code を tmux の中で動かす（任意）](../ai-agents.md#claude-code-を-tmux-の中で動かす任意)）
- **Grok Build: 非公式の grok-cli と名前がぶつかる**: npm の `grok-dev`（もとは `@vibe-kit/grok-cli`）も `grok` のコマンドと `~/.grok` を使う。両方は入れない
- **Grok Build: `agent` のコマンドも入る**: 中身は `grok` と同じ。インストーラーは、`~/.local/bin` に `agent` があっても `ln -sf` で置き換える（Cursor の CLI など、ほかの `agent` を使っているなら、入れた後に確かめる）
- **Grok Build: `XAI_API_KEY` を設定すると、ログインが無いときに API キーで動く**（API の従量課金になる）。サブスクリプションで使うなら設定しない
- **Grok Build: sandbox は既定で無効**: `--sandbox workspace`・`--sandbox read-only` などで、書ける場所を絞れる。Linux では Landlock が有効なカーネルと bubblewrap が要る（`sudo dnf install -y bubblewrap`。GNOME のデスクトップの PC には Flatpak と一緒に入っている）。Windows には sandbox が無い（公式の文書は Linux と macOS だけ）
  - `runtime-socket deny path` と `Permission denied (os error 13)` が出たら、ソケットの親ディレクトリの検索権限を確かめる。ソケット本体の権限を緩める必要は無い。このときの Grok のレビューは動いていないので、[コーディングエージェントの共同作業の「相互にレビューする」](../ai-agents.md#コーディングエージェントの共同作業-相互にレビューする)の代替へ進む
  - カーネルの保護を適用できないエラー（`could not apply the '<プロファイル>' sandbox profile`）が出たら、Landlock が有効なカーネルで OS を起動してから、同じ sandbox を再試行する。bubblewrap を入れただけで解決したとは扱わない（[起動できないときの補足](../reference/almalinux-setup.md#grok-build-注意点-linux-の-sandbox-を起動できないとき)）
- **Grok Build: Claude Code の指示書も読む**: AGENTS.md のほかに、CLAUDE.md・CLAUDE.local.md・`~/.claude/CLAUDE.md` も読む（読み込まれたものは `grok --trust inspect` の `Project Instructions`）。読むのは信頼したフォルダーだけ
- **Grok Build: 会話のデータの扱い**: 学習と保存に使うかは、Grok の中の `/privacy`（Coding data, retention, and training の Opt in / Opt out）で選ぶ（[参考資料](../reference/almalinux-setup.md#grok-build-注意点-会話のデータの扱い)）
- **Codex・Grok のプラグインはどのプロジェクトでも動く**: 自分のユーザーに入るので、どのディレクトリの Claude Code でも、起動と終了のたびに `node` で hook を動かす。外すときは、Node.js より先にプラグインを外す（[AI エージェントとプラグインを消す](#ai-エージェントとプラグインを消す)の手順 1 の後に、[端末とエディタを消す](almalinux-setup.md#端末とエディタを消す)の手順 5）
- **Claude Code: `PATH` は自分で足す**: インストーラも `claude install` も足さない（[「Windows 11 で Claude Code を入れる」の手順 4](../ai-agents.md#windows-11-で-claude-code-を入れる)）。足さないと、開き直した PowerShell でも `claude` が見つからない
- **Claude Code: Windows PowerShell (x86) では入らない**: `Claude Code does not support 32-bit Windows` で止まる。x86 の付かない「Windows PowerShell」で入れ直す
- **Claude Code: `claude` が 2 つ入ると混乱する**: WinGet・npm・scoop で入れたものが `PATH` の先にあると、そちらが動く。`Get-Command claude -All` で確かめ、`winget uninstall Anthropic.ClaudeCode` や `npm uninstall -g @anthropic-ai/claude-code` で外す。古い Claude Desktop は `WindowsApps` に `Claude.exe` を置き、`claude` で Desktop が開くので、最新にする（公式の Troubleshoot installation）
- **Claude Code: 更新の後に `claude` が見つからないとき**: Windows の更新は、`claude.exe` を `claude.exe.old.<数字>` に名前を変えてから新しい版を置く。置けず、名前も戻せなかったときは `claude.exe` が無くなる。公式の文書は、一番新しい `claude.exe.old.*` の名前を戻す（`Get-ChildItem "$env:USERPROFILE\.local\bin\claude.exe.old.*" | Sort-Object Name | Select-Object -Last 1 | Rename-Item -NewName claude.exe`）か、入れ直すとしている
- **Claude Code: `The process cannot access the file` で止まるとき**: 前のインストーラが動いているか、ウイルス対策が `%USERPROFILE%\.claude\downloads` のファイルを調べている。ほかの PowerShell を閉じ、そのフォルダーを消してから入れ直す（公式の Troubleshoot installation）
- **Claude Code: `irm … | iex` で入れた PowerShell には、インストーラの設定が残る**: `Set-StrictMode -Version Latest` などが残るので、その窓は閉じて開き直す（[「Windows 11 で Claude Code を入れる」の手順 3](../ai-agents.md#windows-11-で-claude-code-を入れる)の補足）
- **Claude Code: ログインの情報は `%USERPROFILE%\.claude\.credentials.json`**: パスワードと同じ重みで扱い、ログや issue に貼らない
- **Claude Code: Windows PowerShell 5.1 のパイプ**: `<コマンド> | claude -p` で日本語を渡すと化けるはず（[Claude Code の使い方の基本](../ai-agents.md#claude-code-の使い方の基本)の非対話の注意）
- **Grok Build: Windows には sandbox（`--sandbox`）が無い**: 公式の文書の sandbox は Linux と macOS だけ（[この節の「Grok Build: sandbox は既定で無効」](#注意点)）
