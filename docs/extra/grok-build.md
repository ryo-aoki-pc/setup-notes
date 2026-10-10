# Grok Build（xAI の公式 CLI）を AlmaLinux 10・Windows 11 に入れるのロールバックと注意点

[手順書](../grok-build.md)・[検証記録](../verification/grok-build.md)・[参考資料](../reference/grok-build.md)

- 「手順 N」は[手順書](../grok-build.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

- Windows 11 は [Windows 11 のロールバック](#windows-11-のロールバック)へ進む
- この節の手順 1〜3 で、ログイン・CLI・PATH の設定を外す。ログイン情報・会話の記録・設定（`~/.grok` の残り）は残る

> [!CAUTION]
> **この節の手順 4 で `~/.grok` を消すと、ログイン情報・会話の記録（セッション）・設定・信頼したフォルダーの記録・Grok が作った worktree がすべて消える**（取り戻せない）。入れ直すかもしれないなら、手順 4 は行わない。

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
   command -v grok agent
   ```

   - 最後に何も出なければ、PATH 上に Grok は無い
   - `~/.local/bin` の `grok`・`agent` は、`~/.grok` を指すリンクだけを消す（ほかのツールの `agent` は残る）
   - パスが出る場合は、別の導入方法の Grok か、別のツールの `agent` が残っている

1. インストーラーが `~/.bashrc` に足したブロックを消す。

   ```bash
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

1. 完全に消すときだけ、`~/.grok` を消す（取り戻せない）。

   ```bash
   rm -rf ~/.grok
   ls -ld ~/.grok
   ```

   - `No such file or directory` になればよい
   - Grok が作った worktree（`~/.grok/worktrees` の下）も消える。中の作業が要るなら、先に取り込む

---

## Windows 11 のロールバック

- この節は本書の既定の場所に入れた Grok を対象にする（WinGet で入れたものは WinGet で外す）
- この節の手順 1〜4 では、設定・会話の記録・ログイン情報（`%USERPROFILE%\.grok` の残り）は残る

> [!CAUTION]
> **この節の手順 5 で `%USERPROFILE%\.grok` を消すと、ログイン情報・会話の記録・設定・信頼したフォルダーの記録・Grok が作った worktree がすべて消える**（取り戻せない）。入れ直すかもしれないなら、手順 5 は行わない。

1. 動いている Grok が無いことを確かめ、ログイン情報も外すならログアウトする。

   ```powershell
   Get-Process -Name grok, agent -ErrorAction SilentlyContinue | Format-Table Id, Path
   grok logout
   ```

   - 1 行目で何も出なければよい。プロセスが出たら、その Grok を `/quit` で終えてから、このブロックを貼り直す
   - ログインしていなければ `No cached session to log out of.` と出る

1. 実行ファイル・配布物・Grok が使う Git を消す。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\.grok\bin", "$env:USERPROFILE\.grok\downloads", "$env:USERPROFILE\.grok\completions", "$env:LOCALAPPDATA\grok\git" -Recurse -Force -ErrorAction SilentlyContinue
   Test-Path "$env:USERPROFILE\.grok\bin", "$env:LOCALAPPDATA\grok\git"
   ```

   - `False` が 2 行出ればよい
   - `True` が出たら、`grok.exe` がまだ動いている。この節の手順 1 からやり直す

1. 自分のユーザーの PATH から `%USERPROFILE%\.grok\bin` を外す。

   ```powershell
   & {
     $bin = "$env:USERPROFILE\.grok\bin"
     $entries = @([Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ })
     $rest = @($entries | Where-Object { $_.TrimEnd('\') -ne $bin })
     if ($rest.Count -lt $entries.Count) { [Environment]::SetEnvironmentVariable('Path', ($rest -join ';'), 'User') }
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

1. 完全に消すときだけ、`%USERPROFILE%\.grok` を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\.grok" -Recurse -Force
   Test-Path "$env:USERPROFILE\.grok"
   ```

   - `False` が出ればよい

---

## 注意点

- **非公式の grok-cli と名前がぶつかる**: npm の `grok-dev`（もとは `@vibe-kit/grok-cli`）も `grok` のコマンドと `~/.grok` を使う。両方は入れない
- **`agent` のコマンドも入る**: 中身は `grok` と同じ。インストーラーは、`~/.local/bin` に `agent` があっても `ln -sf` で置き換える（Cursor の CLI など、ほかの `agent` を使っているなら、入れた後に確かめる）
- **`XAI_API_KEY` を設定すると、ログインが無いときに API キーで動く**（API の従量課金になる）。サブスクリプションで使うなら設定しない
- **sandbox は既定で無効**: `--sandbox workspace`・`--sandbox read-only` などで、書ける場所を絞れる。Linux では Landlock が有効なカーネルと bubblewrap が要る（`sudo dnf install -y bubblewrap`。GNOME のデスクトップの PC には Flatpak と一緒に入っている）。Windows には sandbox が無い（公式の文書は Linux と macOS だけ）
  - `runtime-socket deny path` と `Permission denied (os error 13)` が出たら、ソケットの親ディレクトリの検索権限を確かめる。ソケット本体の権限を緩める必要は無い
  - カーネルの保護を適用できないエラー（`could not apply the '<プロファイル>' sandbox profile`）が出たら、Landlock が有効なカーネルで OS を起動してから、同じ sandbox を再試行する。bubblewrap を入れただけで解決したとは扱わない（[起動できないときの補足](../reference/grok-build.md#注意点-linux-の-sandbox-を起動できないとき)）
- **Claude Code の指示書も読む**: AGENTS.md のほかに、CLAUDE.md・CLAUDE.local.md・`~/.claude/CLAUDE.md` も読む（読み込まれたものは `grok --trust inspect` の `Project Instructions`）。読むのは信頼したフォルダーだけ
- **会話のデータの扱い**: 学習と保存に使うかは、Grok の中の `/privacy`（Coding data, retention, and training の Opt in / Opt out）で選ぶ（[参考資料](../reference/grok-build.md#注意点-会話のデータの扱い)）
