# Claude Code・Codex・Grok Build を 1 つのプロジェクトで共同作業させる（AlmaLinux 10・Windows 11）

## 実施手順

- [検証記録](verification/coding-agents.md)・[参考資料](reference/coding-agents.md)・[ロールバックと注意点](extra/coding-agents.md)（方法の比較と、この形を選んだ理由）

> [!IMPORTANT]
> - **Windows 11 は、[Windows 11 で使う](#windows-11-で使う)から始める**
> - この節は AlmaLinux 10 の bash に、自分のユーザーで貼る
> - 前提: [AlmaLinux 10 の初期設定](almalinux-setup.md)の[Git](almalinux-setup.md#git)と、[Claude Code](almalinux-setup.md#claude-code)から[Codex・Grok のプラグイン](almalinux-setup.md#codexgrok-のプラグイン)までを通し、3 つのエージェントにログインしてある（`init.defaultBranch` が `main`。2 つのプラグインと、それが使う Node.js・bubblewrap も入っている）
> - 前提: 共同作業させるプロジェクトが git のリポジトリで、基準のブランチが `main`（ほかの名前のときの読み替えは[参考資料](reference/coding-agents.md#main-でないブランチを基準にするとき)）
> - **手順 9 には対話入力がある**（Claude Code の画面でのフォルダーの信頼と、2 つのプラグインの確かめ）

- 上から順に貼る。手順 1 で変数を設定したシェルに貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- できあがる形: 人は `main`、Claude Code・Codex・Grok Build はそれぞれの worktree とブランチで作業し、3 つが同じ規則（AGENTS.md）を読む。Claude Code からは、OpenAI と xAI の公式のプラグインで、Codex と Grok にレビューや作業を頼める
- 手順の後: 役割と打つコマンドは[使い方の基本](#使い方の基本)。作業の流れは[分担して作業する](#分担して作業する) → [相互にレビューする](#相互にレビューする) → [main に取り込む](#main-に取り込む)。スマートフォンから指示するなら[スマートフォンから指示する](#スマートフォンから指示する)。以後は[更新](#更新)・[ロールバック](extra/coding-agents.md#ロールバック)

1. 変数を設定する（`PROJECT_DIR` は必ず値を入れる）。

   ```bash
   PROJECT_DIR=''                  # ← 共同作業させるリポジトリ（git のルート）の絶対パスを書く。<PROJECT_DIR>
   ```

   ```bash
   WT_ROOT="${PROJECT_DIR%/}.worktrees"   # 3 つの worktree を置くディレクトリ（プロジェクトの隣）。<WT_ROOT>
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'PROJECT_DIR = %s\nWT_ROOT     = %s\n' "${PROJECT_DIR}" "${WT_ROOT}"
   ```

   - 最後に値を読み戻して確かめる
   - `PROJECT_DIR` は、`/home/<USER>/src/myproject` のような、git のリポジトリのルートの絶対パス
   - `WT_ROOT` の既定は、プロジェクトと同じ階層の `<プロジェクト名>.worktrees`。プロジェクトの中には置かない
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこの 2 つのブロックを貼り直す

1. 3 つの CLI の版とログインを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   claude --version
   codex --version
   grok --version
   codex login status
   grok models
   claude auth status --text
   ```

   - 3 つの版が出る
   - `codex login status` が ChatGPT でログイン済みを示す（`Not logged in` なら [AlmaLinux 10 の初期設定の「Codex CLI」の手順 5](almalinux-setup.md#codex-cli) から）
   - `grok models` に `You are not authenticated.` が出ない（出たら [AlmaLinux 10 の初期設定の「Grok Build」の手順 4](almalinux-setup.md#grok-build) から）
   - `claude auth status --text` に `Login method: …` の行が出る（`Not logged in.` なら [AlmaLinux 10 の初期設定の「Claude Code」の手順 5](almalinux-setup.md#claude-code)）

1. プロジェクトの状態と、すでにある指示書を確かめる。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     git -C "${PROJECT_DIR}" rev-parse --show-toplevel
     git -C "${PROJECT_DIR}" status --short --branch
     for f in AGENTS.md AGENTS.override.md CLAUDE.md CLAUDE.local.md; do
       if [ -e "${PROJECT_DIR}/${f}" ]; then echo "${f}"; fi
     done
     ls -d "${WT_ROOT}"
   fi
   ```

   - 1 行目に `PROJECT_DIR` と同じパスが出る。違えば、`PROJECT_DIR` をリポジトリのルートに直して手順 1 から貼り直す
   - 2 行目が `## main`（追跡先があれば `## main...origin/main`）で、その後に何も出ない（変更が無い）。ほかのブランチなら `git switch main`、変更があればコミットしてから進む
   - `AGENTS.override.md` が出たら、中身を AGENTS.md に移して消してから進む
   - 最後に `No such file or directory` が出ればよい。`WT_ROOT` がすでにあれば、中身を確かめる（別の場所にするなら、手順 1 の `WT_ROOT` を変える）

1. AGENTS.md に共同作業の規則を足す（無ければ作る）。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2
   elif grep -qx '## 共同作業の規則' "${PROJECT_DIR}/AGENTS.md" 2>/dev/null; then echo '中断: AGENTS.md に「## 共同作業の規則」がもうある。中身を確かめる' >&2
   else
     if [ -s "${PROJECT_DIR}/AGENTS.md" ]; then
       if [ -n "$(tail -c 1 "${PROJECT_DIR}/AGENTS.md")" ]; then echo >> "${PROJECT_DIR}/AGENTS.md"; fi
       echo >> "${PROJECT_DIR}/AGENTS.md"
     fi
     cat >> "${PROJECT_DIR}/AGENTS.md" <<'EOF'
   ## 共同作業の規則

   このリポジトリでは、Claude Code・Codex・Grok Build が同じ規則で作業する。分担と `main` への取り込みは人が決める。

   - 起動された worktree（作業ディレクトリ）の中だけでファイルを変える。ほかの worktree のファイルは変えない
   - 今のブランチにだけコミットする。`main` にはコミットしない
   - `main` への取り込み・push・Pull Request の作成・ブランチの削除は人が行う。自分のブランチに `main` を取り込むのは、頼まれたときだけ
   - 頼まれた範囲のファイルだけを変える。範囲の外を変えるときは、変える前に理由を書いて確かめる
   - 終わったら、テストとリンターを通してから、目的ごとにコミットする。通らなければコミットせずに、結果を報告する
   - 秘密情報（`.env`・鍵・トークン・パスワード）を読まない・書かない・出力しない
   - レビューを頼まれたら、ファイルを変えずに、指摘を「重大度・場所（ファイル:行）・理由・直し方」で挙げる
   - ほかの担当の変更は、`git diff main...agent/codex` のように git で読む（ほかの worktree へ移らない）
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     cat "${PROJECT_DIR}/AGENTS.md"
   fi
   ```

   - AGENTS.md の中身が出て、最後に「## 共同作業の規則」の節がある
   - `中断:` が出たら、何も書いていない
   - テストとリンターのコマンドが AGENTS.md に無ければ、後でエディタで足す

1. CLAUDE.md に `@AGENTS.md` の 1 行を足す（無ければ作る）。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2
   elif grep -qx '@AGENTS.md' "${PROJECT_DIR}/CLAUDE.md" 2>/dev/null; then echo 'CLAUDE.md に @AGENTS.md はもうある'
   else
     if [ -s "${PROJECT_DIR}/CLAUDE.md" ] && [ -n "$(tail -c 1 "${PROJECT_DIR}/CLAUDE.md")" ]; then echo >> "${PROJECT_DIR}/CLAUDE.md"; fi
     echo '@AGENTS.md' >> "${PROJECT_DIR}/CLAUDE.md"
     printf '\n\033[7m 確認 \033[0m\n'
     tail -n 3 "${PROJECT_DIR}/CLAUDE.md"
   fi
   ```

   - 最後の行に `@AGENTS.md` が出る

1. 2 つのファイルを `main` にコミットする。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     git -C "${PROJECT_DIR}" add AGENTS.md CLAUDE.md
     git -C "${PROJECT_DIR}" commit -m 'Claude Code・Codex・Grok Build の共同作業の規則を足す'
     git -C "${PROJECT_DIR}" log --oneline -1
   fi
   ```

   - 最後に、今のコミットが出る
   - `The following paths are ignored by one of your .gitignore files` と出たら、`.gitignore` で除いている。`.gitignore` から外してから貼り直す

1. 3 つの worktree とブランチを作る。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     for a in claude codex grok; do
       git -C "${PROJECT_DIR}" worktree add -b "agent/${a}" "${WT_ROOT}/${a}" main
     done
     git -C "${PROJECT_DIR}" worktree list
   fi
   ```

   - `Preparing worktree (new branch 'agent/claude')` などが 3 回出て、最後の一覧に 4 行（`[main]`・`[agent/claude]`・`[agent/codex]`・`[agent/grok]`）が出る
   - `already exists` と出たら、前に作ったブランチか worktree が残っている。[ロールバック](extra/coding-agents.md#ロールバック)の手順 2・3 で片付けてから貼り直す

1. 3 つが規則を読むことを確かめる。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     (cd "${WT_ROOT}/claude" && claude -p --permission-mode plan 'ファイルやツールを使わずに、読み込まれている指示だけから答えて: 共同作業の規則で、ファイルを変えてよい場所はどこか。1 行で')
     codex exec -C "${WT_ROOT}/codex" 'ファイルやツールを使わずに、読み込まれている指示だけから答えて: 共同作業の規則で、ファイルを変えてよい場所はどこか。1 行で'
     (cd "${WT_ROOT}/grok" && grok --trust inspect | grep -e 'Project trusted' -e 'AGENTS.md' -e 'CLAUDE.md')
   fi
   ```

   - Claude と Codex が、「起動された worktree の中だけ」という趣旨の 1 行を答える。「分からない」と答えたら、手順 4・5 のファイルと手順 6 のコミットを確かめる
   - Grok は `Project trusted: yes` と、`AGENTS.md (project, …)`・`CLAUDE.md (project, …)` の行が出る
   - Codex が `could not find bubblewrap on PATH` と警告しても、同梱のものを使って動く（[AlmaLinux 10 の初期設定の「Codex・Grok のプラグイン」](almalinux-setup.md#codexgrok-のプラグイン)の手順 1 で bubblewrap を入れると出なくなる）

1. Claude の worktree で Claude Code を起動し、2 つのプラグインの準備を確かめる。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else cd "${WT_ROOT}/claude" && claude; fi
   ```

   - 信頼のダイアログが出たら、`claude` の worktree であることを確かめて信頼する
   - `/codex:setup` と入力する。Codex の版と、`loggedIn` が `true` であることを確かめる。npm で Codex を入れるかを聞かれたら `Skip for now` を選ぶ（[Codex CLI](almalinux-setup.md#codex-cli)で入れた Codex が PATH に無い。Claude Code を終えて手順 2 から確かめる）
   - `/codex:setup --enable-review-gate`（終わるたびに Codex のレビューを待つ設定）は使わない（[注意点](extra/coding-agents.md#注意点)）
   - `/grok-build:check` と入力する。Node と `grok` の版が出る。**ログインしていなくても ready と出る**ので、Grok のログインは手順 2 の `grok models` で確かめる
   - `/exit` で終える
   - **後ろの節のコマンドは、Claude Code を終えてシェルのプロンプトに戻ってから貼る**

---

## 使い方の基本

- 役割は、この手順書の既定。入れ替えてよい（AGENTS.md の規則は、どの役割でも同じ）

| だれ | 主な役割 | 作業する場所 | ブランチ |
|---|---|---|---|
| 人 | 分担を決める・テスト・`main` への取り込み・push | `<PROJECT_DIR>` | `main` |
| Claude Code | 実装の主担当。Codex と Grok にレビューと作業を頼む窓口（スマートフォンからの入口も） | `<WT_ROOT>/claude` | `agent/claude` |
| Codex | レビュー、別の実装 | `<WT_ROOT>/codex` | `agent/codex` |
| Grok Build | 調べもの（Web の検索）、別の目のレビュー、別の実装 | `<WT_ROOT>/grok` | `agent/grok` |

**Claude Code の画面（スマートフォンからも）で打つプラグインのコマンド**

| コマンド | すること |
|---|---|
| `/codex:review --base main --wait` | Codex が、今のブランチの `main` との差分をレビューする（ファイルは変えない） |
| `/codex:adversarial-review --base main <疑う観点>` | 設計の判断を疑う観点で、Codex がレビューする |
| `/codex:rescue <頼むこと>` | Codex に調査や修正を任せる（Claude の worktree のファイルを変える） |
| `/codex:status`・`/codex:result`・`/codex:cancel` | 裏で動く Codex の作業の状況・結果・取り消し |
| `/grok-build:review --base main --wait` | Grok が、今のブランチの `main` との差分をレビューする（ファイルは変えない） |
| `/grok-build:critique --base main <疑う観点>` | 設計の判断を疑う観点で、Grok がレビューする |
| `/grok-build:delegate <頼むこと>` | Grok に調査や修正を任せる（Claude の worktree のファイルを変える） |
| `/grok-build:runs`・`/grok-build:show`・`/grok-build:stop` | 裏で動く Grok の作業の一覧・結果・停止 |

- `--wait` の代わりに `--background` を付けると、裏で動かして待たない（終わったら状況と結果のコマンドで見る）
- 2 つの `review` は、Claude が自分からは呼ばない（打つ必要がある）。`rescue`・`delegate` は、「Codex に任せて」「Grok に調べさせて」と頼むと、Claude が呼ぶことがある
- `--model` は付けない（プラグインの README にある `spark`・`gpt-5.4-mini` などは、引退したモデル）

**端末で、そのブランチの worktree の中から 1 回だけ頼むレビュー**（どれもファイルを変えない）

| コマンド | すること |
|---|---|
| `codex review --base main` | Codex が、今のブランチの `main` との差分をレビューする |
| `claude -p --permission-mode plan "main との差分（git diff main...HEAD）をレビューして。ファイルは変えない"` | Claude がレビューする |
| `grok --trust -p "main との差分（git diff main...HEAD）をレビューして。ファイルは変えない" --sandbox read-only --always-approve` | Grok がレビューする（AlmaLinux 10 だけ。読むだけの sandbox の中で、確認を聞かずに動く。Landlock が有効なカーネルと bubblewrap が要る） |

- Windows には Grok の sandbox が無い（公式の文書は Linux と macOS だけ）ので、`--always-approve` を付けない。`grok` を起動して同じ文で頼み、確認には自分で答える

**スマートフォンから Claude に送る文の例**（[スマートフォンから指示する](#スマートフォンから指示する)）

| 送る文 | 起きること |
|---|---|
| 「ログインの画面の入力チェックを足して。テストを通して、コミットして」 | Claude が自分の worktree で実装し、`agent/claude` にコミットする |
| `/codex:review --base main --wait` | Codex が Claude の変更をレビューし、結果が会話に出る |
| `/grok-build:review --base main --wait` | Grok が同じ変更をレビューする |
| 「Codex の指摘のうち、重大なものだけ直してコミットして」 | Claude が指摘を直す |
| 「Grok に、このライブラリの最新の版と既知の不具合を調べさせて」 | Claude が Grok に調べものを任せる（`/grok-build:delegate`） |
| 「`codex review --base main` を実行して、結果をまとめて」 | Claude が端末のコマンドで Codex のレビューを動かす（プラグインのコマンドが使えないときの代わり） |

---

## 分担して作業する

- 人が分担を決め、3 つがそれぞれの worktree で並べて作業する
- 両 OS で同じ流れ。この節の手順 1 は AlmaLinux 10、手順 2 は Windows 11 だけ。手順 4 から後は、bash でも PowerShell でも同じコマンドを貼る

> [!WARNING]
> **Grok Build は既定で sandbox が無く、許可すれば worktree の外のファイルも変えられる**（AGENTS.md の規則で止めるだけ）。この節の手順 6 で、確認の画面には中身を読んでから答える。AlmaLinux 10 では `grok --sandbox workspace` で起動すると、書ける場所を worktree・`~/.grok`・一時ディレクトリに絞れる（Landlock が有効なカーネルと bubblewrap が要る。その場合、コミットは人が行う）。

1. AlmaLinux 10 のときだけ、tmux に 4 つのウィンドウを作って入る。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 実施手順の手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2
   elif tmux has-session -t agents 2>/dev/null; then tmux attach -t agents
   else
     tmux new-session -d -s agents -n main -c "${PROJECT_DIR}"
     for a in claude codex grok; do tmux new-window -t agents -n "${a}" -c "${WT_ROOT}/${a}"; done
     tmux attach -t agents
   fi
   ```

   - 下の行に `0:main`・`1:claude`・`2:codex`・`3:grok` のウィンドウが出る。`Ctrl+b` → 数字で切り替える（tmux のキーは [AlmaLinux 10 の初期設定の tmux の使い方の基本](almalinux-setup.md#tmux-の使い方の基本)）
   - 各ウィンドウのシェルは、それぞれの worktree（`main` はプロジェクト）から始まる
   - SSH を切っても残る。スマートフォンの SSH のアプリからも `tmux attach -t agents` で戻れる
   - **次の手順からは、tmux の中の、手順に書いたウィンドウに貼る**

1. Windows 11 のときだけ、4 つの PowerShell の窓を開く。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: Windows 11 で使うの手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     foreach ($d in $PROJECT_DIR, "$WT_ROOT\claude", "$WT_ROOT\codex", "$WT_ROOT\grok") { Start-Process powershell.exe -WorkingDirectory $d }
   }
   ```

   - 4 つの窓が開き、それぞれの場所（プロジェクトと 3 つの worktree）から始まる。どの窓かは `Get-Location` で確かめる
   - **次の手順からは、手順に書いた場所の窓に貼る**

1. 人が分担を決める。

   - 3 つに同じファイルを触らせない（モジュールやディレクトリで分ける）
   - 頼む文には、終わりの条件（通すテスト）と、終わったら自分のブランチにコミットすることを書く
   - 振り方の目安は、[使い方の基本](#使い方の基本)の役割の表

1. `claude` の worktree の窓で Claude Code を起動し、担当の作業を頼む。

   ```bash
   claude
   ```

   - 初めての worktree では信頼のダイアログが出る（実施手順の手順 9 で信頼してあれば出ない）
   - 頼んだら、その窓は Claude Code に任せる。Claude Code の確認の画面（ファイルの変更・コマンドの実行）には、中身を読んでから答える

1. `codex` の worktree の窓で Codex を起動し、担当の作業を頼む。

   ```bash
   codex
   ```

   - 初めての worktree では作業場所の確認が出る。`codex` の worktree であることを確かめて進む
   - **Codex は sandbox の中では `git add` も `git commit` もできない**。sandbox の外での実行の承認を求められたら、コマンドを確かめて許可する。許可しないなら、終わった後に人がその窓でコミットする

1. `grok` の worktree の窓で Grok を起動し、担当の作業を頼む。

   ```bash
   grok
   ```

   - 実施手順の手順 8 の `--trust` で信頼してあるので、信頼は聞かれない
   - 確認の画面（ファイルの変更・コマンドの実行）には、中身を読んでから答える（この節のリードの `[!WARNING]`）

1. 3 つが終わったら、それぞれの worktree の窓で、コミットと残りの変更を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git log --oneline main..HEAD
   git status --short
   ```

   - エージェントを終えてから貼る（Claude Code は `/exit`、Codex と Grok は `/quit`）
   - 1 つ目のコマンドに、この作業のコミットが出る。2 つ目は何も出ない
   - 2 つ目に何か出たら、コミットされていない変更が残っている。エージェントにコミットさせるか、人がコミットする

---

## 相互にレビューする

- 書いたものとは別のモデルに、新しい会話でレビューさせる（どれもファイルを変えない）
- 各ブランチを、ほかの 2 つがレビューする。指摘は人が選んで、担当に直させる
- 頼む前に、レビューされる側の変更が自分のブランチにコミットしてあること（[分担して作業する](#分担して作業する)の手順 7）
- Grok の sandbox が起動しないときは、Grok のレビューを未実行として残し、この節の Claude・Codex のレビューを使う。sandbox は外さず、ソケット自体のアクセス権は緩めない。Landlock と親ディレクトリの検索権限を確かめ、対応するカーネルで起動してから再試行する

1. `claude` の窓の Claude Code で、Claude のブランチを Codex と Grok にレビューさせる。

   - `claude` で Claude Code を起動し、`/codex:review --base main --wait` と入力する
   - 続けて `/grok-build:review --base main --wait` と入力する
   - 指摘は、重大度・場所・理由・直し方で会話に出る（AGENTS.md の規則）

1. `codex` の worktree の窓で、Codex のブランチを Claude と Grok にレビューさせる。

   ```bash
   claude -p --permission-mode plan "main との差分（git diff main...HEAD）をレビューして。ファイルは変えない"
   grok --trust -p "main との差分（git diff main...HEAD）をレビューして。ファイルは変えない" --sandbox read-only --always-approve
   ```

   - Codex を `/quit` で終えてから貼る
   - Windows 11 では、2 行目を貼らずに `grok` を起動し、同じ文で頼む

1. `grok` の worktree の窓で、Grok のブランチを Codex と Claude にレビューさせる。

   ```bash
   codex review --base main
   claude -p --permission-mode plan "main との差分（git diff main...HEAD）をレビューして。ファイルは変えない"
   ```

   - Grok を `/quit` で終えてから貼る

1. 人が指摘を選び、担当のエージェントに直させる。

   - 直させる指摘だけを、担当の窓のエージェントに渡す。Claude Code は `claude -c`、Codex は `codex resume --last`、Grok は `grok -c` で、同じ worktree の前の会話に戻れる
   - 直したら、この節の手順でもう一度レビューさせる

---

## main に取り込む

- 人が行う。エージェントには `main` を変えさせない（AGENTS.md の規則）
- 両 OS で同じコマンド。この節の手順 2〜6 は `main` の窓（プロジェクト）、手順 7 は各 worktree の窓に貼る

1. それぞれの worktree の窓で、プロジェクトのテストを通す。

   - エージェントを終えてから、そのプロジェクトのテストのコマンドを打つ
   - 通らないブランチは取り込まない。担当のエージェントに直させる

1. `main` の窓で、取り込む前の状態を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git status --short --branch
   git log --oneline --decorate main..agent/claude
   git log --oneline --decorate main..agent/codex
   git log --oneline --decorate main..agent/grok
   ```

   - 1 行目が `## main`（追跡先があれば `## main...origin/main`）で、その後に何も出ない
   - それぞれのブランチの、`main` に入っていないコミットが出る（一番新しいものに `(agent/…)` が付く）。何も出ないブランチは、取り込むものが無い

1. `main` の窓で、Claude のブランチを取り込む。

   ```bash
   git merge --no-ff --no-edit agent/claude
   ```

   - `Merge made by the 'ort' strategy.` か `Already up to date.` が出ればよい
   - `CONFLICT` と出たら、この節の手順 6 へ進む

1. `main` の窓で、Codex のブランチを取り込む。

   ```bash
   git merge --no-ff --no-edit agent/codex
   ```

   - 出るものと分かれ方は、この節の手順 3 と同じ

1. `main` の窓で、Grok のブランチを取り込む。

   ```bash
   git merge --no-ff --no-edit agent/grok
   ```

   - 出るものと分かれ方は、この節の手順 3 と同じ

1. 競合したときだけ、その取り込みをやめ、担当のエージェントに直させる。

   ```bash
   git merge --abort
   printf '\n\033[7m 確認 \033[0m\n'
   git status --short --branch
   ```

   - `## main` の後に何も出なければ、取り込む前に戻っている
   - 担当の窓のエージェントに「`git merge main` で main を取り込み、競合を直してテストを通し、コミットして」と頼む
   - 直したら、この節の手順 2 からやり直す（取り込み済みのブランチは `Already up to date.` になる）

1. それぞれの worktree の窓で、新しい `main` にそろえる。

   ```bash
   git merge --ff-only main
   ```

   - エージェントを終えてから貼る
   - `Fast-forward` か `Already up to date.` が出ればよい。次の分担はここから始める
   - `Not possible to fast-forward` と出たら、その worktree に、`main` に取り込んでいないコミットがある（この節の手順 3〜5 で取り込んでから、もう一度貼る）
   - リモートがあれば、`main` の窓で `git push` する（エージェントには push させない）

---

## スマートフォンから指示する

- 入口は Claude Code の Remote Control。Claude の worktree で動かしておき、スマートフォンの Claude のアプリから Claude に頼む。Codex と Grok には、Claude が 2 つのプラグインで頼む
- claude.ai のアカウント（Pro / Max / Team / Enterprise）のログインが要る。API キーでは使えない
- PC は動かしたままにする（スリープ・ネットワークの切断で止まる）
- 両 OS で同じ流れ。この節の手順 1 は AlmaLinux 10、手順 2 は Windows 11 だけ

> [!WARNING]
> **Remote Control をつなぐと、この claude.ai のアカウントで入れる人が、スマートフォンやブラウザから、この PC の Claude の worktree で Claude Code を動かせる**（ファイルの読み書きとコマンドの実行）。プラグインを通して Codex と Grok も動く。会話は Anthropic のサーバーに保存される。

1. AlmaLinux 10 のときだけ、Claude の worktree で Remote Control を tmux の中で始める。

   - [AlmaLinux 10 の初期設定の任意節「Claude Code を tmux の中で動かす（任意）」](almalinux-setup.md#claude-code-を-tmux-の中で動かす任意)の手順 1〜6 を通す
   - その節の手順 2 では、`cd <WT_ROOT>/claude` で Claude の worktree に移る
   - セッションの名前は worktree のディレクトリの名前（`claude`）になる。分かりにくければ、スマートフォンから `/rename <名前>` で変えられる

1. Windows 11 のときだけ、Claude の worktree で Remote Control をタスクで始める。

   - [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)の実施手順を通す
   - その手順 2 の `$PROJECT_DIR` は `<WT_ROOT>\claude`、`$RC_NAME` はプロジェクトの名前にする

1. スマートフォンの Claude のアプリで、そのセッションを開く。

   - **Code** の一覧に、この節の手順 1・2 のセッションが出る
   - 開いてメッセージを送ると、PC の Claude の worktree で Claude Code が動いて返事が来る

1. Claude に頼む。

   - 送る文の例は、[使い方の基本](#使い方の基本)の「スマートフォンから Claude に送る文の例」
   - レビューは `/codex:review --base main --wait`・`/grok-build:review --base main --wait` を送る
   - Claude Code の確認（ファイルの変更・コマンドの実行）は、スマートフォンに出る。中身を読んでから答える
   - 長くかかる作業は `--background` を付けて頼み、`/codex:status`・`/grok-build:runs` で状況を見る
   - プラグインのコマンドがスマートフォンから動かなければ、「`codex review --base main` を実行して、結果をまとめて」のように、Claude にシェルのコマンドで頼む

1. AlmaLinux 10 のときだけ、Codex と Grok に直接頼むなら、スマートフォンの SSH のアプリから tmux に入る。

   - SSH でログインし、`tmux attach -t agents` を打つ（[分担して作業する](#分担して作業する)の手順 1 で作ったセッション）
   - `Ctrl+b` → `2`（codex）・`3`（grok）で切り替え、それぞれのエージェントに頼む
   - 終わるときは `Ctrl+b` → `d` で離れる（エージェントは動き続ける）

1. 取り込みは、PC か SSH のアプリで行う。

   - [main に取り込む](#main-に取り込む)の手順を、`main` の窓で行う
   - 取り込んだら、Claude の worktree も同じ節の手順 7 で `main` にそろえる（Remote Control のセッションは動かしたままでよい）

---

## 更新

- Windows 11 は [Windows 11 の更新](#windows-11-の更新)へ進む
- Claude Code・Codex・Grok Build と 2 つのプラグインは、[AlmaLinux 10 の初期設定の更新](almalinux-setup.md#更新)で上げる（プラグインは、その手順 9）。Node.js は OS の更新で上がる
- この手順書で足した AGENTS.md・CLAUDE.md・worktree は、上げるものが無い。規則を変えたときは[main に取り込む](#main-に取り込む)の手順 7 で各 worktree をそろえる

---

## Windows 11 で使う

> [!IMPORTANT]
> - 自分のユーザーの **管理者ではない Windows PowerShell 5.1** で行う
> - 前提: [Windows 11 の初期設定](windows-setup.md)の[Git for Windows](windows-setup.md#git-for-windows)・[Git Bash と WezTerm の設定](windows-setup.md#git-bash-と-wezterm-の設定)と、[Claude Code](windows-setup.md#claude-code)から[Codex・Grok のプラグイン](windows-setup.md#codexgrok-のプラグイン)までを通し、3 つのエージェントにログインしてある
> - 前提: [Windows 11 の初期設定の「貼り付けの設定」](windows-setup.md#貼り付けの設定)の手順 1〜4（貼り付けの設定）と、「アプリを入れる」の手順 1・2（scoop）
> - **この節の手順 9 には対話入力がある**（Claude Code の画面でのフォルダーの信頼と、2 つのプラグインの確かめ）

- 上から順に貼る。手順 1 で変数を設定した PowerShell に貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 手順の後は、両 OS に共通の[使い方の基本](#使い方の基本)・[分担して作業する](#分担して作業する)・[相互にレビューする](#相互にレビューする)・[main に取り込む](#main-に取り込む)・[スマートフォンから指示する](#スマートフォンから指示する)へ進む
- 書くファイル（AGENTS.md・CLAUDE.md）は、BOM の無い UTF-8 と LF の改行にする（AlmaLinux 10 で書いたものと同じ形）

1. 変数を設定する（`PROJECT_DIR` は必ず値を入れる）。

   ```powershell
   $PROJECT_DIR = ''                     # ← 共同作業させるリポジトリ（git のルート）の絶対パスを書く。<PROJECT_DIR>
   ```

   ```powershell
   $WT_ROOT = if ($PROJECT_DIR) { $PROJECT_DIR.TrimEnd('\') + '.worktrees' }   # 3 つの worktree を置くディレクトリ（プロジェクトの隣）。<WT_ROOT>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'PROJECT_DIR = {0}' -f $PROJECT_DIR
   'WT_ROOT     = {0}' -f $WT_ROOT
   ```

   - 最後に値を読み戻して確かめる
   - `PROJECT_DIR` は、`C:\Users\<WIN_USER>\src\myproject` のような、git のリポジトリのルートの絶対パス
   - **新しい PowerShell を開いたら**、この 2 つのブロックを貼り直してから先へ進む

1. 3 つの CLI の版とログインを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   claude --version
   codex --version
   grok --version
   codex login status
   grok models
   claude auth status --text
   ```

   - 確かめることは、[実施手順](#実施手順)の手順 2 と同じ

1. プロジェクトの状態と、すでにある指示書を確かめる。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     git -C $PROJECT_DIR rev-parse --show-toplevel
     git -C $PROJECT_DIR status --short --branch
     Get-ChildItem -LiteralPath $PROJECT_DIR -Force -Name | Where-Object { $_ -in 'AGENTS.md', 'AGENTS.override.md', 'CLAUDE.md', 'CLAUDE.local.md' }
     Test-Path -LiteralPath $WT_ROOT
   }
   ```

   - 1 行目は `C:/Users/<WIN_USER>/src/myproject` のように `/` で出る（`PROJECT_DIR` と同じ場所ならよい）
   - 2 行目以降と指示書のファイルの名前の見方は、[実施手順](#実施手順)の手順 3 と同じ
   - 最後に `False` が出ればよい

1. AGENTS.md に共同作業の規則を足す（無ければ作る）。

   ```powershell
   & {
     if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す'; return }
     $path = Join-Path $PROJECT_DIR 'AGENTS.md'
     $old = if (Test-Path -LiteralPath $path) { [IO.File]::ReadAllText($path) } else { '' }
     if ($old -match '(?m)^## 共同作業の規則\r?$') { Write-Error '中断: AGENTS.md に「## 共同作業の規則」がもうある。中身を確かめる'; return }
     $text = @'
   ## 共同作業の規則

   このリポジトリでは、Claude Code・Codex・Grok Build が同じ規則で作業する。分担と `main` への取り込みは人が決める。

   - 起動された worktree（作業ディレクトリ）の中だけでファイルを変える。ほかの worktree のファイルは変えない
   - 今のブランチにだけコミットする。`main` にはコミットしない
   - `main` への取り込み・push・Pull Request の作成・ブランチの削除は人が行う。自分のブランチに `main` を取り込むのは、頼まれたときだけ
   - 頼まれた範囲のファイルだけを変える。範囲の外を変えるときは、変える前に理由を書いて確かめる
   - 終わったら、テストとリンターを通してから、目的ごとにコミットする。通らなければコミットせずに、結果を報告する
   - 秘密情報（`.env`・鍵・トークン・パスワード）を読まない・書かない・出力しない
   - レビューを頼まれたら、ファイルを変えずに、指摘を「重大度・場所（ファイル:行）・理由・直し方」で挙げる
   - ほかの担当の変更は、`git diff main...agent/codex` のように git で読む（ほかの worktree へ移らない）
   '@
     $prefix = if ($old.Length -eq 0) { '' } elseif ($old.EndsWith("`n")) { "`n" } else { "`n`n" }
     [IO.File]::AppendAllText($path, $prefix + ($text -replace "`r`n", "`n") + "`n", (New-Object Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Content -LiteralPath $path -Encoding UTF8
   }
   ```

   - AGENTS.md の中身が出て、最後に「## 共同作業の規則」の節がある
   - `中断:` が出たら、何も書いていない

1. CLAUDE.md に `@AGENTS.md` の 1 行を足す（無ければ作る）。

   ```powershell
   & {
     if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す'; return }
     $path = Join-Path $PROJECT_DIR 'CLAUDE.md'
     $old = if (Test-Path -LiteralPath $path) { [IO.File]::ReadAllText($path) } else { '' }
     if ($old -match '(?m)^@AGENTS\.md\r?$') { 'CLAUDE.md に @AGENTS.md はもうある'; return }
     $prefix = if ($old.Length -eq 0 -or $old.EndsWith("`n")) { '' } else { "`n" }
     [IO.File]::AppendAllText($path, $prefix + "@AGENTS.md`n", (New-Object Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Content -LiteralPath $path -Encoding UTF8 | Select-Object -Last 3
   }
   ```

   - 最後の行に `@AGENTS.md` が出る

1. 2 つのファイルを `main` にコミットする。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     git -C $PROJECT_DIR add AGENTS.md CLAUDE.md
     git -C $PROJECT_DIR commit -m 'Claude Code・Codex・Grok Build の共同作業の規則を足す'
     git -C $PROJECT_DIR log --oneline -1
   }
   ```

   - 見方は、[実施手順](#実施手順)の手順 6 と同じ

1. 3 つの worktree とブランチを作る。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($a in 'claude', 'codex', 'grok') { git -C $PROJECT_DIR worktree add -b "agent/$a" "$WT_ROOT\$a" main }
     git -C $PROJECT_DIR worktree list
   }
   ```

   - 見方は、[実施手順](#実施手順)の手順 7 と同じ

1. 3 つが規則を読むことを確かめる。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Push-Location -LiteralPath "$WT_ROOT\claude"; claude -p --permission-mode plan 'ファイルやツールを使わずに、読み込まれている指示だけから答えて: 共同作業の規則で、ファイルを変えてよい場所はどこか。1 行で'; Pop-Location
     codex exec -C "$WT_ROOT\codex" 'ファイルやツールを使わずに、読み込まれている指示だけから答えて: 共同作業の規則で、ファイルを変えてよい場所はどこか。1 行で'
     Push-Location -LiteralPath "$WT_ROOT\grok"; grok --trust inspect | Select-String -SimpleMatch -Pattern 'Project trusted', 'AGENTS.md', 'CLAUDE.md'; Pop-Location
   }
   ```

   - 見方は、[実施手順](#実施手順)の手順 8 と同じ
   - 日本語の答えが化けて読めなければ、`[Console]::OutputEncoding = [Text.Encoding]::UTF8` を貼ってから、このブロックを貼り直す

1. Claude の worktree で Claude Code を起動し、2 つのプラグインの準備を確かめる。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else { Set-Location -LiteralPath "$WT_ROOT\claude"; claude }
   ```

   - 確かめることは、[実施手順](#実施手順)の手順 9 と同じ
   - `/codex:setup` が `node` を見つけられなければ、Git for Windows の入れ直しか、[Windows 11 の初期設定の「Codex・Grok のプラグイン」](windows-setup.md#codexgrok-のプラグイン)の手順 1・2 を確かめる
   - **後ろの節のコマンドは、Claude Code を終えて PowerShell のプロンプトに戻ってから貼る**

---

## Windows 11 の更新

- Claude Code・Codex・Grok Build と 2 つのプラグインは、[Windows 11 の初期設定の「AI エージェントとプラグインを上げる」](windows-setup.md#ai-エージェントとプラグインを上げる)で上げる。Node.js（scoop）は、同書の[「scoop・winget・WSL を上げる」](windows-setup.md#scoopwingetwsl-を上げる)の手順 1・2 で上がる
- 規則を変えたときは、AlmaLinux 10 と同じく[main に取り込む](#main-に取り込む)の手順 7 で各 worktree をそろえる
