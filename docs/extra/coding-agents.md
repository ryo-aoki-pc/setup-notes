# Claude Code・Codex・Grok Build を 1 つのプロジェクトで共同作業させる（AlmaLinux 10・Windows 11）のロールバックと注意点

[手順書](../coding-agents.md)・[検証記録](../verification/coding-agents.md)・[参考資料](../reference/coding-agents.md)

- 「手順 N」は[手順書](../coding-agents.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- Windows 11 は [Windows 11 のロールバック](#windows-11-のロールバック)へ進む
- この節では、worktree・ブランチ・プラグイン・Node.js を外す。AGENTS.md と CLAUDE.md の規則は残る（要らなければ、この節の手順 7）
- 実施手順の手順 1 の変数を設定したシェルで行う

> [!CAUTION]
> **この節の手順 4 は、取り込んでいない作業ごと、3 つの worktree とブランチを消す**（取り戻せない）。この節の手順 3 で断られたときに、捨ててよいと確かめてからだけ行う。

1. 動いているエージェントと Remote Control を終え、tmux のセッションを閉じる。

   ```bash
   tmux kill-session -t agents
   ```

   - 先に、各ウィンドウのエージェントを終える（Claude Code は `/exit`、Codex と Grok は `/quit`）
   - Remote Control を動かしているなら、[その任意節](../almalinux-setup.md#claude-code-を-tmux-の中で動かす任意)の手順 8 で止める
   - tmux を使っていなければ `can't find session: agents` と出る（そのままでよい）

1. 消す前に、コミットしていない変更と、取り込んでいないコミットを確かめる。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 実施手順の手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     for a in claude codex grok; do
       echo "== ${a}"
       git -C "${WT_ROOT}/${a}" status --short
       git -C "${PROJECT_DIR}" log --oneline "main..agent/${a}"
     done
   fi
   ```

   - `== claude` などの見出しの下に何も出なければ、消して失うものは無い
   - 出たら、要るものを[main に取り込む](../coding-agents.md#main-に取り込む)で取り込んでから進む

1. 3 つの worktree とブランチを消す。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 実施手順の手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     for a in claude codex grok; do
       if [ -d "${WT_ROOT}/${a}" ]; then git -C "${PROJECT_DIR}" worktree remove "${WT_ROOT}/${a}"; fi
       git -C "${PROJECT_DIR}" branch -d "agent/${a}"
     done
     rmdir "${WT_ROOT}"
     git -C "${PROJECT_DIR}" worktree list
   fi
   ```

   - `Deleted branch agent/claude (was …)` などが 3 つ出て、最後の一覧が `[main]` の 1 行だけになればよい
   - `contains modified or untracked files`（worktree に変更が残っている。続けて `used by worktree` でブランチも残る）や `not fully merged`（取り込んでいない）で断られたら、この節の手順 2 に戻り、片付けてからこのブロックを貼り直す。捨ててよいなら、この節の手順 4
   - 貼り直したときは、もう消えたものに `branch 'agent/…' not found` と出る（そのままでよい）。`rmdir` の `Directory not empty` は、worktree が残っているあいだ出る

1. 取り込んでいない作業も捨てるときだけ、強制で消す（取り戻せない）。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 実施手順の手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     for a in claude codex grok; do
       git -C "${PROJECT_DIR}" worktree remove --force "${WT_ROOT}/${a}"
       git -C "${PROJECT_DIR}" branch -D "agent/${a}"
     done
     git -C "${PROJECT_DIR}" worktree prune
     rmdir "${WT_ROOT}"
     git -C "${PROJECT_DIR}" worktree list
   fi
   ```

   - （この節の手順 3 の代わりに）最後の一覧が `[main]` の 1 行だけになればよい
   - この節の手順 3 で消えたものは `is not a working tree`・`not found` と出る（そのままでよい）

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

1. ほかに使うものが無いときだけ、Node.js を外す。

   ```bash
   sudo dnf remove nodejs nodejs-npm
   ```

   - [npm-offline.md](../npm-offline.md) や Neovim の Mason で Node.js を使っているなら、外さない
   - bubblewrap は外さない（Flatpak と GNOME のデスクトップも使う）
   - トランザクション表の `Removing:` に `nodejs` と `nodejs-npm`、`Removing unused dependencies:` に一緒に入った `nodejs-libs`・`libuv` などが出る。ほかに使っているパッケージが出たら `N` で止める。よければ `y` と答える
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

1. 要るときだけ、AGENTS.md の規則と CLAUDE.md の取り込みの行を消す。

   - エディタで、AGENTS.md の「## 共同作業の規則」の節と、CLAUDE.md の `@AGENTS.md` の行を消し、`main` にコミットする
   - CLAUDE.md が `@AGENTS.md` の 1 行だけなら、ファイルごと消してよい

---

## Windows 11 のロールバック

- この節では、worktree・ブランチ・プラグイン・Node.js を外す。AGENTS.md と CLAUDE.md の規則は残る（要らなければ、[ロールバック](#ロールバック)の手順 7 と同じ）
- [Windows 11 で使う](../coding-agents.md#windows-11-で使う)の手順 1 の変数を設定した PowerShell で行う

> [!CAUTION]
> **この節の手順 4 は、取り込んでいない作業ごと、3 つの worktree とブランチを消す**（取り戻せない）。この節の手順 3 で断られたときに、捨ててよいと確かめてからだけ行う。

1. 動いているエージェントと Remote Control を終える。

   - 開いている窓のエージェントを終え（Claude Code は `/exit`、Codex と Grok は `/quit`）、その窓を閉じる
   - Remote Control のタスクを使っているなら、[windows-claude-remote-control.md のロールバック](windows-claude-remote-control.md#ロールバック)を先に行う

1. 消す前に、コミットしていない変更と、取り込んでいないコミットを確かめる。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: Windows 11 で使うの手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($a in 'claude', 'codex', 'grok') { "== $a"; git -C "$WT_ROOT\$a" status --short; git -C $PROJECT_DIR log --oneline "main..agent/$a" }
   }
   ```

   - 見方は、[ロールバック](#ロールバック)の手順 2 と同じ

1. 3 つの worktree とブランチを消す。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: Windows 11 で使うの手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($a in 'claude', 'codex', 'grok') {
       if (Test-Path -LiteralPath "$WT_ROOT\$a") { git -C $PROJECT_DIR worktree remove "$WT_ROOT\$a" }
       git -C $PROJECT_DIR branch -d "agent/$a"
     }
     if ((Test-Path -LiteralPath $WT_ROOT) -and -not (Get-ChildItem -LiteralPath $WT_ROOT -Force)) { Remove-Item -LiteralPath $WT_ROOT }
     git -C $PROJECT_DIR worktree list
   }
   ```

   - 見方と、断られたときの分かれ方は、[ロールバック](#ロールバック)の手順 3 と同じ（捨ててよいなら、この節の手順 4）

1. 取り込んでいない作業も捨てるときだけ、強制で消す（取り戻せない）。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: Windows 11 で使うの手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($a in 'claude', 'codex', 'grok') {
       git -C $PROJECT_DIR worktree remove --force "$WT_ROOT\$a"
       git -C $PROJECT_DIR branch -D "agent/$a"
     }
     git -C $PROJECT_DIR worktree prune
     if ((Test-Path -LiteralPath $WT_ROOT) -and -not (Get-ChildItem -LiteralPath $WT_ROOT -Force)) { Remove-Item -LiteralPath $WT_ROOT }
     git -C $PROJECT_DIR worktree list
   }
   ```

   - （この節の手順 3 の代わりに）最後の一覧が `[main]` の 1 行だけになればよい

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

1. ほかに使うものが無いときだけ、scoop で入れた Node.js を外す。

   ```powershell
   scoop uninstall nodejs-lts
   ```

   - この節の手順 5 でプラグインを外してから行う（プラグインは Claude Code の起動と終了のたびに `node` を動かす）

---

## 注意点

- **3 つの契約の使用量を使う**: レビュー・委任・確かめの問いのたびに、Claude（claude.ai）・Codex（ChatGPT）・Grok（grok.com）それぞれのプランの使用量が減る
- **`/codex:rescue` と `/grok-build:delegate` は、Claude の worktree で動く**: Codex と Grok が Claude の worktree のファイルを変える。Claude 自身の作業と同じファイルを頼まない
- **Codex は sandbox の中でコミットできない**: Codex の sandbox は `.git` を読むだけにする（worktree でも、ふつうのチェックアウトでも同じ。[検証記録](../verification/coding-agents.md#codex-の-sandbox-と-git)）。コミットは承認するか、人が行う
- **`/codex:cancel` の後も、Codex が始めたコマンドは動き続けることがある**: cancel はターンを中断するが、その中で始めたコマンドは裏に残ることがある。残ったコマンドは、Claude Code のセッションを終えてプラグインが Codex の共有のプロセスを止めると消える（プラグイン 1.0.6 と Codex 0.160.0。スクリプトを直接呼んだ確認。[検証記録](../verification/coding-agents.md#codex-の実行中のターンの中断を伴う-cancel)）
- **Grok Build は既定で sandbox が無い**: [分担して作業する](../coding-agents.md#分担して作業する)のリードの `[!WARNING]`。Windows には sandbox が無い
- **Grok の読むだけの sandbox には Landlock と bubblewrap が要る**: Landlock が有効なカーネルで起動し、bubblewrap を実施手順の手順 9 で入れる。ソケットの親を検索できない場合も起動しない。ソケット自体のアクセス権は緩めない（[検証記録](../verification/coding-agents.md#追加原因調査と対処の準備2026-10-10)）
- **Grok は Claude の指示書も読む**: CLAUDE.md・CLAUDE.local.md・`~/.claude/CLAUDE.md` も読む（信頼したフォルダーだけ）。3 つに共通の規則は AGENTS.md に書く
- **`/grok-build:check` は、ログインしていなくても ready と出る**（grok-build のプラグイン 0.2.1 と Grok Build 1.0.50。`grok models` の終了コードで判定するため）。ログインは `grok models` の表示で確かめる
- **Codex のレビューの関門は使わない**: `/codex:setup --enable-review-gate` にすると、Claude Code が終わるたびに Codex のレビューを待つ（Stop の hook）。使用量が増え、指摘が続くと止まらない
- **プラグインはどのプロジェクトでも動く**: 自分のユーザーに入るので、どのディレクトリの Claude Code でも、起動と終了のたびに `node` で hook を動かす。外すときは、Node.js より先にプラグインを外す
- **規則を変えるのは `main` で**: AGENTS.md を変えたら `main` にコミットし、各 worktree を[main に取り込む](../coding-agents.md#main-に取り込む)の手順 7 でそろえる（エージェントは起動したときの worktree の AGENTS.md を読む）
