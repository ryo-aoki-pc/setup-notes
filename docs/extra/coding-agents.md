# コーディングエージェントの共同作業のロールバックと注意点

[手順書](../ai-agents.md#コーディングエージェントの共同作業-almalinux-10-で使う)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/coding-agents.md)・[参考資料](../reference/coding-agents.md)

- 「手順 N」は[手順書](../ai-agents.md#コーディングエージェントの共同作業-almalinux-10-で使う)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## AlmaLinux 10 のロールバック

- Windows 11 は [Windows 11 のロールバック](#windows-11-のロールバック)へ進む
- この節では、worktree とブランチを外す。AGENTS.md と CLAUDE.md の規則は残る（要らなければ、この節の手順 5）
- 2 つのプラグインと Node.js は、PC ごとに入れるもの。外すなら、この節の後に[AI エージェントのロールバックの「AI エージェントとプラグインを消す」](ai-agents.md#ai-エージェントとプラグインを消す)の手順 1 と、AlmaLinux 10 の初期設定のロールバックの「端末とエディタを消す」の手順 5
- 手順書の「コーディングエージェントの共同作業: AlmaLinux 10 で使う」の手順 1 の変数を設定したシェルで行う

> [!CAUTION]
> **この節の手順 4 は、取り込んでいない作業ごと、4 つの worktree とブランチを消す**（取り戻せない）。この節の手順 3 で断られたときに、捨ててよいと確かめてからだけ行う。

1. 動いているエージェントと Remote Control を終え、tmux のセッションを閉じる。

   ```bash
   tmux kill-session -t agents
   ```

   - 先に、各ウィンドウのエージェントを終える（Claude Code は `/exit`、Codex と Grok は `/quit`）
   - Remote Control を動かしているなら、[その任意節](../ai-agents.md#claude-code-を-tmux-の中で動かす任意)の手順 8 で止める
   - tmux を使っていなければ `can't find session: agents` と出る（そのままでよい）

1. 消す前に、コミットしていない変更と、取り込んでいないコミットを確かめる。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順書の「コーディングエージェントの共同作業: AlmaLinux 10 で使う」の手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     for a in claude codex grok antigravity; do
       echo "== ${a}"
       git -C "${WT_ROOT}/${a}" status --short
       git -C "${PROJECT_DIR}" log --oneline "main..agent/${a}"
     done
   fi
   ```

   - `== claude` などの見出しの下に何も出なければ、消して失うものは無い
   - Antigravity を足す前に作ったプロジェクト（worktree が 3 つ）では、`== antigravity` の下に `fatal: cannot change to '…/antigravity'` と `fatal: ambiguous argument 'main..agent/antigravity'` が出る（そのままでよい）
   - 出たら、要るものを[main に取り込む](../ai-agents.md#コーディングエージェントの共同作業-main-に取り込む)で取り込んでから進む

1. 4 つの worktree とブランチを消す。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順書の「コーディングエージェントの共同作業: AlmaLinux 10 で使う」の手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     for a in claude codex grok antigravity; do
       if [ -d "${WT_ROOT}/${a}" ]; then git -C "${PROJECT_DIR}" worktree remove "${WT_ROOT}/${a}"; fi
       git -C "${PROJECT_DIR}" branch -d "agent/${a}"
     done
     rmdir "${WT_ROOT}"
     git -C "${PROJECT_DIR}" worktree list
   fi
   ```

   - `Deleted branch agent/claude (was …)` などが 4 つ出て、最後の一覧が `[main]` の 1 行だけになればよい
   - `contains modified or untracked files`（worktree に変更が残っている。続けて `used by worktree` でブランチも残る）や `not fully merged`（取り込んでいない）で断られたら、この節の手順 2 に戻り、片付けてからこのブロックを貼り直す。捨ててよいなら、この節の手順 4
   - 貼り直したときと、worktree が 3 つのプロジェクトの `agent/antigravity` は、`branch 'agent/…' not found` と出る（そのままでよい）。`rmdir` の `Directory not empty` は、worktree が残っているあいだ出る

1. 取り込んでいない作業も捨てるときだけ、強制で消す（取り戻せない）。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順書の「コーディングエージェントの共同作業: AlmaLinux 10 で使う」の手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     for a in claude codex grok antigravity; do
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

1. 要るときだけ、AGENTS.md の規則と CLAUDE.md の取り込みの行を消す。

   - エディタで、AGENTS.md の「## 共同作業の規則」の節と、CLAUDE.md の `@AGENTS.md` の行を消し、`main` にコミットする
   - CLAUDE.md が `@AGENTS.md` の 1 行だけなら、ファイルごと消してよい

---

## Windows 11 のロールバック

- この節では、worktree とブランチを外す。AGENTS.md と CLAUDE.md の規則は残る（要らなければ、[AlmaLinux 10 のロールバック](#almalinux-10-のロールバック)の手順 5 と同じ）
- 2 つのプラグインと Node.js は、PC ごとに入れるもの。外すなら、この節の後に[AI エージェントのロールバックの「Windows 11 で AI エージェントとプラグインを消す」](ai-agents.md#windows-11-で-ai-エージェントとプラグインを消す)の手順 1 と、Windows 11 の初期設定のロールバックの「エディタとシェルのツールを消す」の手順 6
- [Windows 11 で使う](../ai-agents.md#コーディングエージェントの共同作業-windows-11-で使う)の手順 1 の変数を設定した PowerShell で行う

> [!CAUTION]
> **この節の手順 4 は、取り込んでいない作業ごと、4 つの worktree とブランチを消す**（取り戻せない）。この節の手順 3 で断られたときに、捨ててよいと確かめてからだけ行う。

1. 動いているエージェントと Remote Control を終える。

   - 開いている窓のエージェントを終え（Claude Code は `/exit`、Codex と Grok は `/quit`）、その窓を閉じる
   - Remote Control のタスクを使っているなら、[Windows 11 で Claude Code の Remote Control を使う のロールバック](windows-claude-remote-control.md#ロールバック)を先に行う

1. 消す前に、コミットしていない変更と、取り込んでいないコミットを確かめる。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: Windows 11 で使うの手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($a in 'claude', 'codex', 'grok', 'antigravity') { "== $a"; git -C "$WT_ROOT\$a" status --short; git -C $PROJECT_DIR log --oneline "main..agent/$a" }
   }
   ```

   - 見方は、[AlmaLinux 10 のロールバック](#almalinux-10-のロールバック)の手順 2 と同じ

1. 4 つの worktree とブランチを消す。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: Windows 11 で使うの手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($a in 'claude', 'codex', 'grok', 'antigravity') {
       if (Test-Path -LiteralPath "$WT_ROOT\$a") { git -C $PROJECT_DIR worktree remove "$WT_ROOT\$a" }
       git -C $PROJECT_DIR branch -d "agent/$a"
     }
     if ((Test-Path -LiteralPath $WT_ROOT) -and -not (Get-ChildItem -LiteralPath $WT_ROOT -Force)) { Remove-Item -LiteralPath $WT_ROOT }
     git -C $PROJECT_DIR worktree list
   }
   ```

   - 見方と、断られたときの分かれ方は、[AlmaLinux 10 のロールバック](#almalinux-10-のロールバック)の手順 3 と同じ（捨ててよいなら、この節の手順 4）

1. 取り込んでいない作業も捨てるときだけ、強制で消す（取り戻せない）。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: Windows 11 で使うの手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($a in 'claude', 'codex', 'grok', 'antigravity') {
       git -C $PROJECT_DIR worktree remove --force "$WT_ROOT\$a"
       git -C $PROJECT_DIR branch -D "agent/$a"
     }
     git -C $PROJECT_DIR worktree prune
     if ((Test-Path -LiteralPath $WT_ROOT) -and -not (Get-ChildItem -LiteralPath $WT_ROOT -Force)) { Remove-Item -LiteralPath $WT_ROOT }
     git -C $PROJECT_DIR worktree list
   }
   ```

   - （この節の手順 3 の代わりに）最後の一覧が `[main]` の 1 行だけになればよい

---

## Windows 11 で既定の分担をやめる

- [既定で分担する](../ai-agents.md#コーディングエージェントの共同作業-既定で分担する)で足した AGENTS.md の `## 既定の分担` を外し、`main` にコミットして 4 つの worktree をそろえる。節の文を替えるときも、ここで外してから、その項の手順 1 からやり直す
- 前提: [既定で分担する](../ai-agents.md#コーディングエージェントの共同作業-既定で分担する)を通してある
- 実行場所: 自分のユーザーの、管理者ではない Windows PowerShell 5.1
- 始める前に、4 つのエージェントの作業を終え、4 つの `agent/<名前>` のブランチのコミットを `main` に取り込み、変更とステージしたものが無い状態にする

1. 変数を設定する（`PROJECT_DIR` は必ず値を入れる）。

   ```powershell
   $PROJECT_DIR = ''                     # ← 共同作業させるリポジトリ（git のルート）の絶対パスを書く。<PROJECT_DIR>
   ```

   ```powershell
   $WT_ROOT = if ($PROJECT_DIR) { $PROJECT_DIR.TrimEnd('\') + '.worktrees' }   # 4 つの worktree を置くディレクトリ（プロジェクトの隣）。<WT_ROOT>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'PROJECT_DIR = {0}' -f $PROJECT_DIR
   'WT_ROOT     = {0}' -f $WT_ROOT
   ```

   - 最後に値を読み戻して確かめる
   - [既定で分担する](../ai-agents.md#コーディングエージェントの共同作業-既定で分担する)の手順 1 と同じ値にする
   - **新しい PowerShell を開いたら**、この 2 つのブロックを貼り直してから先へ進む

1. AGENTS.md から `## 既定の分担` の節を外す。

   ```powershell
   & {
     if (-not $PROJECT_DIR) { Write-Error '中断: この節の手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す'; return }
     if ((git -C $PROJECT_DIR branch --show-current) -ne 'main') { Write-Error '中断: PROJECT_DIR のブランチが main ではない。main に切り替えてから貼り直す'; return }
     $path = Join-Path $PROJECT_DIR 'AGENTS.md'
     $old = [IO.File]::ReadAllText($path)
     $m = [regex]::Match($old, '(?ms)^## 既定の分担\r?\n.*?(?=^## |\z)')
     if (-not $m.Success) { Write-Error '中断: AGENTS.md に「## 既定の分担」が無い'; return }
     [IO.File]::WriteAllText($path, $old.Remove($m.Index, $m.Length).TrimEnd("`r", "`n") + "`n", (New-Object Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     git -C $PROJECT_DIR diff --stat
     Select-String -LiteralPath $path -Pattern '^## ' | ForEach-Object { $_.Line }
   }
   ```

   - `AGENTS.md | … -` の 1 行（消した行の数）が出て、`##` の見出しの一覧に `## 既定の分担` が無い
   - `中断:` が出たら、何も変えていない。変数・ブランチ・AGENTS.md の中身を確かめる

1. AGENTS.md を `main` にコミットする。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: この節の手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } elseif ((git -C $PROJECT_DIR branch --show-current) -ne 'main') { Write-Error '中断: PROJECT_DIR のブランチが main ではない。main に切り替えてから貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     git -C $PROJECT_DIR add AGENTS.md
     git -C $PROJECT_DIR commit -m '既定の分担を外す'
     git -C $PROJECT_DIR log --oneline -1
   }
   ```

   - 最後に、コミットメッセージが「既定の分担を外す」のコミットが出る
   - コミットに失敗したら、この節の手順 4 へ進まない

1. 4 つの worktree を `main` にそろえる。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: この節の手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($a in 'claude', 'codex', 'grok', 'antigravity') { "[$a]"; git -C "$WT_ROOT\$a" merge --ff-only main }
   }
   ```

   - 4 つの worktree で動いているエージェントを終えてから貼る
   - 見方は、[既定で分担する](../ai-agents.md#コーディングエージェントの共同作業-既定で分担する)の手順 4 と同じ

---

## 注意点

- **3 つの契約の使用量を使う**: レビュー・委任・確かめの問いのたびに、Claude（claude.ai）・Codex（ChatGPT）・Grok（grok.com）それぞれのプランの使用量が減る
- **Antigravity の使用量はモデルの組ごとにある**: Gemini 4 Argon には別の週の上限がある。残りは `agy -p /quota`（使用量を使わない）で見る。手順書では版がいちばん新しい Gemini の Flash（High）を使う（モデルの選び方は [AlmaLinux 10](../reference/coding-agents.md#almalinux-10-で-antigravity-に読み取り専用で頼む--手順-3-補足-モデルの選び方)・[Windows 11](../reference/coding-agents.md#windows-11-で-antigravity-に読み取り専用で頼む--手順-3-補足-モデルの選び方)）
- **`/codex:rescue` と `/grok-build:delegate` は、Claude の worktree で動く**: Codex と Grok が Claude の worktree のファイルを変える。Claude 自身の作業と同じファイルを頼まない
- **Codex は sandbox の中でコミットできない**: Codex の sandbox は `.git` を読むだけにする（worktree でも、ふつうのチェックアウトでも同じ。[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/coding-agents.md#codex-の-sandbox-と-git)）。コミットは承認するか、人が行う
- **`/codex:cancel` の後も、Codex が始めたコマンドは動き続けることがある**: cancel はターンを中断するが、その中で始めたコマンドは裏に残ることがある。残ったコマンドは、Claude Code のセッションを終えてプラグインが Codex の共有のプロセスを止めると消える（プラグイン 1.0.6 と Codex 0.160.0。スクリプトを直接呼んだ確認。[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/coding-agents.md#codex-の実行中のターンの中断を伴う-cancel)）
- **Grok Build は既定で sandbox が無い**: [分担して作業する](../ai-agents.md#コーディングエージェントの共同作業-分担して作業する)のリードの `[!WARNING]`。Windows には sandbox が無い
- **Grok の読むだけの sandbox には Landlock と bubblewrap が要る**: Landlock が有効なカーネルで起動し、bubblewrap を[AI エージェントの手順書の「Codex・Grok のプラグイン」](../ai-agents.md#codexgrok-のプラグイン)の手順 1 で入れる。ソケットの親を検索できない場合も起動しない。ソケット自体のアクセス権は緩めない（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/coding-agents.md#追加原因調査と対処の準備2026-10-10)）
- **Grok は Claude の指示書も読む**: CLAUDE.md・CLAUDE.local.md・`~/.claude/CLAUDE.md` も読む（信頼したフォルダーだけ）。3 つに共通の規則は AGENTS.md に書く
- **`/grok-build:check` は、ログインしていなくても ready と出る**（grok-build のプラグイン 0.2.1 と Grok Build 1.0.50。`grok models` の終了コードで判定するため）。ログインは `grok models` の表示で確かめる
- **Codex のレビューの関門は使わない**: `/codex:setup --enable-review-gate` にすると、Claude Code が終わるたびに Codex のレビューを待つ（Stop の hook）。使用量が増え、指摘が続くと止まらない
- **プラグインはどのプロジェクトでも動く**: 自分のユーザーに入るので、どのディレクトリの Claude Code でも、起動と終了のたびに `node` で hook を動かす。外すときは、Node.js より先にプラグインを外す（[AI エージェントのロールバック](ai-agents.md#ai-エージェントとプラグインを消す)）
- **エージェントの push と Pull Request には、そのホストの認証が要る**: エージェントは、動いているユーザーの git の認証で push し、Pull Request は gh で作る。GitHub は、[AlmaLinux 10 の初期設定の「GitHub CLI」](../almalinux-setup.md#github-cli)・[Windows 11 の初期設定の「GitHub CLI」](../windows-setup.md#github-cli)でログインしておく（git の HTTPS の認証は、AlmaLinux 10 は gh の `Authenticate Git with your GitHub credentials?`、Windows 11 は Git Credential Manager）。Codex は、push と Pull Request の作成にも sandbox の外での実行の承認が要る
- **Forgejo では、Pull Request は人が作る**: この手順書では、Forgejo の Pull Request を作る道具を入れていない（トークンは秘密情報なので、エージェントに API を使わせない）。エージェントは push までにし、Pull Request は人がブラウザで作る（[Forgejo: 使い方の基本](../forgejo.md#forgejo-使い方の基本)）
- **画面で取り込むときは merge commit で**: squash と rebase で取り込むと、各 worktree の `git merge --ff-only main` が通らなくなる（[参考資料](../reference/coding-agents.md#main-に取り込む-画面で取り込むとき)）
- **規則を変えるのは `main` で**: AGENTS.md を変えたら `main` にコミットし、各 worktree を[main に取り込む](../ai-agents.md#コーディングエージェントの共同作業-main-に取り込む)の手順 7 でそろえる（エージェントは起動したときの worktree の AGENTS.md を読む）
