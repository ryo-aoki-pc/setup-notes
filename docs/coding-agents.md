# Claude Code・Codex・Grok Build を 1 つのプロジェクトで共同作業させる（AlmaLinux 10・Windows 11）

## 実施手順

- [検証記録](verification/coding-agents.md)・[参考資料](reference/coding-agents.md)（方法の比較と、この形を選んだ理由）

> [!IMPORTANT]
> - **Windows 11 は、[Windows 11 で使う](#windows-11-で使う)から始める**
> - この節は AlmaLinux 10 の bash に、自分のユーザーで貼る
> - 前提: [Claude Code](claude-code.md)・[Codex CLI](codex.md)・[Grok Build](grok-build.md) を入れて、それぞれログインしてある。Git は [git.md](git.md) で設定してある（`init.defaultBranch` が `main`）
> - 前提: 共同作業させるプロジェクトが git のリポジトリで、基準のブランチが `main`（ほかの名前のときの読み替えは[参考資料](reference/coding-agents.md#main-でないブランチを基準にするとき)）
> - **手順 11 には対話入力がある**（Claude Code の画面でのフォルダーの信頼と、2 つのプラグインの確かめ）

- 上から順に貼る。手順 1 で変数を設定したシェルに貼る
- できあがる形: 人は `main`、Claude Code・Codex・Grok Build はそれぞれの worktree とブランチで作業し、3 つが同じ規則（AGENTS.md）を読む。Claude Code からは、OpenAI と xAI の公式のプラグインで、Codex と Grok にレビューや作業を頼める
- 手順の後: 役割と打つコマンドは[使い方の基本](#使い方の基本)。作業の流れは[分担して作業する](#分担して作業する) → [相互にレビューする](#相互にレビューする) → [main に取り込む](#main-に取り込む)。スマートフォンから指示するなら[スマートフォンから指示する](#スマートフォンから指示する)。以後は[更新](#更新)・[ロールバック](#ロールバック)

1. 変数を設定する（`PROJECT_DIR` は必ず値を入れる）。

   ```bash
   PROJECT_DIR=''                  # ← 共同作業させるリポジトリ（git のルート）の絶対パスを書く。<PROJECT_DIR>
   ```

   ```bash
   WT_ROOT="${PROJECT_DIR%/}.worktrees"   # 3 つの worktree を置くディレクトリ（プロジェクトの隣）。<WT_ROOT>
   printf 'PROJECT_DIR = %s\nWT_ROOT     = %s\n' "${PROJECT_DIR}" "${WT_ROOT}"
   ```

   - 最後に値を読み戻して確かめる
   - `PROJECT_DIR` は、`/home/<USER>/src/myproject` のような、git のリポジトリのルートの絶対パス
   - `WT_ROOT` の既定は、プロジェクトと同じ階層の `<プロジェクト名>.worktrees`。プロジェクトの中には置かない（[参考資料](reference/coding-agents.md#worktree-の置き場所とブランチ)）
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこの 2 つのブロックを貼り直す

1. 3 つの CLI の版とログインを確かめる。

   ```bash
   claude --version
   codex --version
   grok --version
   codex login status
   grok models
   claude auth status --text
   ```

   - 3 つの版が出る（検証時は `2.1.295 (Claude Code)`・`codex-cli 0.162.0`・`grok 1.0.50 (…)`）
   - `codex login status` が ChatGPT でログイン済みを示す（`Not logged in` なら [codex.md 手順 5](codex.md#実施手順) から）
   - `grok models` に `You are not authenticated.` が出ない（出たら [grok-build.md 手順 4](grok-build.md#実施手順) から）
   - `claude auth status --text` に `Login method: …` の行が出る（`Not logged in.` なら [claude-code.md 手順 5](claude-code.md#実施手順)）
   - `claude auth status` は後ろに貼った行を読んで捨てるので、最後に置いてある

1. プロジェクトの状態と、すでにある指示書を確かめる。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
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
   - 指示書のファイルの名前が出たら、それがすでにある（この後の手順 4・5 は、そのファイルへの追記になる）
   - `AGENTS.override.md` が出たら、Codex はそのディレクトリでは AGENTS.md の代わりにそれを読む。中身を AGENTS.md に移して消してから進む
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
     cat "${PROJECT_DIR}/AGENTS.md"
   fi
   ```

   - AGENTS.md の中身が出て、最後に「## 共同作業の規則」の節がある
   - `中断:` が出たら、何も書いていない
   - テストとリンターのコマンドが AGENTS.md に無ければ、後でエディタで足す（3 つともそれを見て通す）

1. CLAUDE.md に `@AGENTS.md` の 1 行を足す（無ければ作る）。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2
   elif grep -qx '@AGENTS.md' "${PROJECT_DIR}/CLAUDE.md" 2>/dev/null; then echo 'CLAUDE.md に @AGENTS.md はもうある'
   else
     if [ -s "${PROJECT_DIR}/CLAUDE.md" ] && [ -n "$(tail -c 1 "${PROJECT_DIR}/CLAUDE.md")" ]; then echo >> "${PROJECT_DIR}/CLAUDE.md"; fi
     echo '@AGENTS.md' >> "${PROJECT_DIR}/CLAUDE.md"
     tail -n 3 "${PROJECT_DIR}/CLAUDE.md"
   fi
   ```

   - 最後の行に `@AGENTS.md` が出る
   - Claude Code は、CLAUDE.md（か CLAUDE.local.md）があると AGENTS.md を自分では読まない。この 1 行で取り込ませる
   - Grok Build は CLAUDE.md も読む。Claude Code だけに伝えたいことを CLAUDE.md に書くと、Grok にも伝わる

1. 2 つのファイルを `main` にコミットする。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
     git -C "${PROJECT_DIR}" add AGENTS.md CLAUDE.md
     git -C "${PROJECT_DIR}" commit -m 'Claude Code・Codex・Grok Build の共同作業の規則を足す'
     git -C "${PROJECT_DIR}" log --oneline -1
   fi
   ```

   - 最後に、今のコミットが出る
   - `The following paths are ignored by one of your .gitignore files` と出たら、`.gitignore` で除いている。worktree に届かないので、`.gitignore` から外してから貼り直す

1. 3 つの worktree とブランチを作る。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
     for a in claude codex grok; do
       git -C "${PROJECT_DIR}" worktree add -b "agent/${a}" "${WT_ROOT}/${a}" main
     done
     git -C "${PROJECT_DIR}" worktree list
   fi
   ```

   - `Preparing worktree (new branch 'agent/claude')` などが 3 回出て、最後の一覧に 4 行（`[main]`・`[agent/claude]`・`[agent/codex]`・`[agent/grok]`）が出る
   - `already exists` と出たら、前に作ったブランチか worktree が残っている。[ロールバック](#ロールバック)の手順 2・3 で片付けてから貼り直す

1. 3 つが規則を読むことを確かめる。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
     (cd "${WT_ROOT}/claude" && claude -p --permission-mode plan 'ファイルやツールを使わずに、読み込まれている指示だけから答えて: 共同作業の規則で、ファイルを変えてよい場所はどこか。1 行で')
     codex exec -C "${WT_ROOT}/codex" 'ファイルやツールを使わずに、読み込まれている指示だけから答えて: 共同作業の規則で、ファイルを変えてよい場所はどこか。1 行で'
     (cd "${WT_ROOT}/grok" && grok --trust inspect | grep -e 'Project trusted' -e 'AGENTS.md' -e 'CLAUDE.md')
   fi
   ```

   - Claude と Codex が、「起動された worktree の中だけ」という趣旨の 1 行を答える。「分からない」と答えたら、手順 4・5 のファイルと手順 6 のコミットを確かめる
   - Grok は `Project trusted: yes` と、`AGENTS.md (project, …)`・`CLAUDE.md (project, …)` の行が出る（AI には聞かないので、使用量は減らない）
   - `grok --trust` は、この worktree を信頼したことを `~/.grok/trusted_folders.toml` に残す（Grok の画面で信頼するのと同じ）
   - Claude と Codex への 2 つの問いは、それぞれのプランの使用量を少し使う
   - Codex が `could not find bubblewrap on PATH` と警告しても、同梱のものを使って動く（手順 9 で bubblewrap を入れると出なくなる）

1. Node.js と bubblewrap を入れる（プラグインと sandbox が使う）。

   ```bash
   {
     sudo dnf install -y nodejs bubblewrap
     node --version
     bwrap --version
   }
   ```

   - `v22.…` と `bubblewrap 0.…` が出ればよい（プラグインは Node.js 18.18 以上が要る。検証時は AppStream の 22.23.2 と BaseOS の 0.10.0）
   - npm（`nodejs-npm`）も一緒に入る。この手順書では使わない
   - bubblewrap は、Grok の読むだけの sandbox（`/grok-build:review` と、この手順書の端末からの Grok のレビュー）と Codex の sandbox が使う。無いと、Grok は `this sandbox could not enforce its deny list on Linux` と出して起動しない
   - GNOME のデスクトップの PC には、Flatpak の依存として bubblewrap がもう入っている（`Package bubblewrap-… is already installed.`）

1. Claude Code に、OpenAI の Codex のプラグインと xAI の Grok Build のプラグインを入れる。

   ```bash
   claude plugin marketplace add openai/codex-plugin-cc
   claude plugin marketplace add xai-org/grok-build-plugin-cc
   claude plugin install codex@openai-codex
   claude plugin install grok-build@xai-grok-build
   claude plugin list
   ```

   - `✔ Successfully added marketplace: openai-codex` と `xai-grok-build`、`✔ Successfully installed plugin: …（scope: user）` が 2 つ出る
   - 最後の一覧に、`codex@openai-codex` と `grok-build@xai-grok-build` が `Status: ✔ enabled` で出る（検証時は 1.0.6 と 0.2.1）
   - 自分のユーザーの、どのプロジェクトの Claude Code でも使える（`~/.claude/settings.json` の `enabledPlugins`）
   - 動いている Claude Code には、起動し直すまで効かない

1. Claude の worktree で Claude Code を起動し、2 つのプラグインの準備を確かめる。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else cd "${WT_ROOT}/claude" && claude; fi
   ```

   - 信頼のダイアログが出たら、`claude` の worktree であることを確かめて信頼する
   - `/codex:setup` と入力する。Codex の版と、`loggedIn` が `true` であることを確かめる。npm で Codex を入れるかを聞かれたら `Skip for now` を選ぶ（[codex.md](codex.md) で入れた Codex が PATH に無い。Claude Code を終えて手順 2 から確かめる）
   - `/codex:setup --enable-review-gate`（終わるたびに Codex のレビューを待つ設定）は使わない（[注意点](#注意点)）
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
| `grok --trust -p "main との差分（git diff main...HEAD）をレビューして。ファイルは変えない" --sandbox read-only --always-approve` | Grok がレビューする（AlmaLinux 10 だけ。読むだけの sandbox の中で、確認を聞かずに動く。bubblewrap が要る） |

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
> **Grok Build は既定で sandbox が無く、許可すれば worktree の外のファイルも変えられる**（AGENTS.md の規則で止めるだけ）。この節の手順 6 で、確認の画面には中身を読んでから答える。AlmaLinux 10 では `grok --sandbox workspace` で起動すると、書ける場所を worktree・`~/.grok`・一時ディレクトリに絞れる（bubblewrap が要る。その場合、コミットは人が行う）。

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

   - 3 つに同じファイルを触らせない（モジュールやディレクトリで分ける）。重なると、取り込みのときに競合する
   - 頼む文には、終わりの条件（通すテスト）と、終わったら自分のブランチにコミットすることを書く
   - 振り方の目安は、[使い方の基本](#使い方の基本)の役割の表

1. `claude` の worktree の窓で Claude Code を起動し、担当の作業を頼む。

   ```bash
   claude
   ```

   - 初めての worktree では信頼のダイアログが出る（実施手順の手順 11 で信頼してあれば出ない）
   - 頼んだら、その窓は Claude Code に任せる。Claude Code の確認の画面（ファイルの変更・コマンドの実行）には、中身を読んでから答える

1. `codex` の worktree の窓で Codex を起動し、担当の作業を頼む。

   ```bash
   codex
   ```

   - 初めての worktree では作業場所の確認が出る。`codex` の worktree であることを確かめて進む
   - **Codex は sandbox の中では `git add` も `git commit` もできない**（`.git` は読むだけ）。sandbox の外での実行の承認を求められたら、コマンドを確かめて許可する。許可しないなら、終わった後に人がその窓でコミットする

1. `grok` の worktree の窓で Grok を起動し、担当の作業を頼む。

   ```bash
   grok
   ```

   - 実施手順の手順 8 の `--trust` で信頼してあるので、信頼は聞かれない
   - 確認の画面（ファイルの変更・コマンドの実行）には、中身を読んでから答える（この節のリードの `[!WARNING]`）

1. 3 つが終わったら、それぞれの worktree の窓で、コミットと残りの変更を確かめる。

   ```bash
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
   - Windows 11 では、2 行目を貼らずに `grok` を起動し、同じ文で頼む（Windows には Grok の sandbox が無いため。[使い方の基本](#使い方の基本)の表の下）
   - `grok --trust` は、この worktree も信頼したことを残す

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
- Claude Code・Codex・Grok Build 自身は、それぞれの手順書の「更新」（[claude-code.md](claude-code.md#更新)・[codex.md](codex.md#更新)・[grok-build.md](grok-build.md#更新)）

1. Node.js を上げる。

   ```bash
   {
     sudo dnf upgrade -y nodejs
     node --version
   }
   ```

   - 上げるものが無ければ `Nothing to do.` と出る

1. 2 つのプラグインのマーケットプレイスとプラグインを上げる。

   ```bash
   claude plugin marketplace update openai-codex
   claude plugin marketplace update xai-grok-build
   claude plugin update codex@openai-codex
   claude plugin update grok-build@xai-grok-build
   claude plugin list
   ```

   - `✔ Successfully updated marketplace: …` が 2 つと、`✔ … updated …` か `✔ … is already at the latest version (…)` が 2 つ出る
   - 上がったプラグインは、Claude Code を起動し直すまで効かない（Remote Control も止めてから始め直す）

---

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
   - Remote Control を動かしているなら、[その任意節](almalinux-setup.md#claude-code-を-tmux-の中で動かす任意)の手順 8 で止める
   - tmux を使っていなければ `can't find session: agents` と出る（そのままでよい）

1. 消す前に、コミットしていない変更と、取り込んでいないコミットを確かめる。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 実施手順の手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
     for a in claude codex grok; do
       echo "== ${a}"
       git -C "${WT_ROOT}/${a}" status --short
       git -C "${PROJECT_DIR}" log --oneline "main..agent/${a}"
     done
   fi
   ```

   - `== claude` などの見出しの下に何も出なければ、消して失うものは無い
   - 出たら、要るものを[main に取り込む](#main-に取り込む)で取り込んでから進む

1. 3 つの worktree とブランチを消す。

   ```bash
   if [ -z "${PROJECT_DIR}" ]; then echo '中断: 実施手順の手順 1 の PROJECT_DIR が空のまま。値を入れて貼り直す' >&2; else
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
   claude plugin list
   ```

   - 最後の一覧に、2 つのプラグインが出なければよい
   - プラグインのデータ（`~/.claude/plugins/data/` の下）も消える

1. ほかに使うものが無いときだけ、Node.js を外す。

   ```bash
   sudo dnf remove nodejs nodejs-npm
   ```

   - [npm-offline.md](npm-offline.md) や Neovim の Mason で Node.js を使っているなら、外さない
   - bubblewrap は外さない（Flatpak と GNOME のデスクトップも使う）
   - トランザクション表の `Removing:` に `nodejs` と `nodejs-npm`、`Removing unused dependencies:` に一緒に入った `nodejs-libs`・`libuv` などが出る。ほかに使っているパッケージが出たら `N` で止める。よければ `y` と答える
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

1. 要るときだけ、AGENTS.md の規則と CLAUDE.md の取り込みの行を消す。

   - エディタで、AGENTS.md の「## 共同作業の規則」の節と、CLAUDE.md の `@AGENTS.md` の行を消し、`main` にコミットする
   - CLAUDE.md が `@AGENTS.md` の 1 行だけなら、ファイルごと消してよい

---

## Windows 11 で使う

> [!IMPORTANT]
> - 自分のユーザーの **管理者ではない Windows PowerShell 5.1** で行う
> - 前提: [Claude Code](claude-code.md#windows-11-で使う)・[Codex CLI](codex.md#windows-11-で使う)・[Grok Build](grok-build.md#windows-11-で使う) の Windows 11 の節で入れて、それぞれログインしてある。Git は [git.md の Windows 11 の節](git.md#windows-11-で-git-for-windows-を入れる)
> - 前提: [Windows 11 の初期設定](windows-setup.md#実施手順)の手順 16〜19（貼り付けの設定）と、手順 20・21（scoop）
> - **この節の手順 12 には対話入力がある**（Claude Code の画面でのフォルダーの信頼と、2 つのプラグインの確かめ）

- 上から順に貼る。手順 1 で変数を設定した PowerShell に貼る
- 手順の後は、両 OS に共通の[使い方の基本](#使い方の基本)・[分担して作業する](#分担して作業する)・[相互にレビューする](#相互にレビューする)・[main に取り込む](#main-に取り込む)・[スマートフォンから指示する](#スマートフォンから指示する)へ進む
- 書くファイル（AGENTS.md・CLAUDE.md）は、BOM の無い UTF-8 と LF の改行にする（AlmaLinux 10 で書いたものと同じ形）

1. 変数を設定する（`PROJECT_DIR` は必ず値を入れる）。

   ```powershell
   $PROJECT_DIR = ''                     # ← 共同作業させるリポジトリ（git のルート）の絶対パスを書く。<PROJECT_DIR>
   ```

   ```powershell
   $WT_ROOT = if ($PROJECT_DIR) { $PROJECT_DIR.TrimEnd('\') + '.worktrees' }   # 3 つの worktree を置くディレクトリ（プロジェクトの隣）。<WT_ROOT>
   'PROJECT_DIR = {0}' -f $PROJECT_DIR
   'WT_ROOT     = {0}' -f $WT_ROOT
   ```

   - 最後に値を読み戻して確かめる
   - `PROJECT_DIR` は、`C:\Users\<WIN_USER>\src\myproject` のような、git のリポジトリのルートの絶対パス
   - 変数はその PowerShell の中だけで有効。**新しい PowerShell を開いたら**、この 2 つのブロックを貼り直してから先へ進む

1. 3 つの CLI の版とログインを確かめる。

   ```powershell
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
     Get-Content -LiteralPath $path -Encoding UTF8 | Select-Object -Last 3
   }
   ```

   - 最後の行に `@AGENTS.md` が出る
   - 理由は、[実施手順](#実施手順)の手順 5 と同じ

1. 2 つのファイルを `main` にコミットする。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     git -C $PROJECT_DIR add AGENTS.md CLAUDE.md
     git -C $PROJECT_DIR commit -m 'Claude Code・Codex・Grok Build の共同作業の規則を足す'
     git -C $PROJECT_DIR log --oneline -1
   }
   ```

   - 見方は、[実施手順](#実施手順)の手順 6 と同じ

1. 3 つの worktree とブランチを作る。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     foreach ($a in 'claude', 'codex', 'grok') { git -C $PROJECT_DIR worktree add -b "agent/$a" "$WT_ROOT\$a" main }
     git -C $PROJECT_DIR worktree list
   }
   ```

   - 見方は、[実施手順](#実施手順)の手順 7 と同じ

1. 3 つが規則を読むことを確かめる。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     Push-Location -LiteralPath "$WT_ROOT\claude"; claude -p --permission-mode plan 'ファイルやツールを使わずに、読み込まれている指示だけから答えて: 共同作業の規則で、ファイルを変えてよい場所はどこか。1 行で'; Pop-Location
     codex exec -C "$WT_ROOT\codex" 'ファイルやツールを使わずに、読み込まれている指示だけから答えて: 共同作業の規則で、ファイルを変えてよい場所はどこか。1 行で'
     Push-Location -LiteralPath "$WT_ROOT\grok"; grok --trust inspect | Select-String -SimpleMatch -Pattern 'Project trusted', 'AGENTS.md', 'CLAUDE.md'; Pop-Location
   }
   ```

   - 見方は、[実施手順](#実施手順)の手順 8 と同じ
   - 日本語の答えが化けて読めなければ、`[Console]::OutputEncoding = [Text.Encoding]::UTF8` を貼ってから、このブロックを貼り直す

1. Node.js 18.18 以上が無いときだけ、scoop で入れる。

   ```powershell
   Get-Command node -All -ErrorAction SilentlyContinue
   scoop install nodejs-lts
   ```

   - 1 行目にパスが出て、`node --version` が `v18.18` 以上なら、2 行目は貼らない
   - `'nodejs-lts' (…) was installed successfully!` が出ればよい（検証時の scoop の定義は 24.21.0）

1. PowerShell を閉じ、スタートメニューから開き直す。

   - 開き直した窓で `node --version` が通ることを確かめる（Claude Code が起動するプラグインのスクリプトも、この PATH の `node` を使う）
   - **次の手順は、この節の手順 1 の 2 つのブロックを貼り直してから貼る**

1. Claude Code に、OpenAI の Codex のプラグインと xAI の Grok Build のプラグインを入れる。

   ```powershell
   claude plugin marketplace add openai/codex-plugin-cc
   claude plugin marketplace add xai-org/grok-build-plugin-cc
   claude plugin install codex@openai-codex
   claude plugin install grok-build@xai-grok-build
   claude plugin list
   ```

   - 見方は、[実施手順](#実施手順)の手順 10 と同じ（`%USERPROFILE%\.claude\settings.json` の `enabledPlugins`）

1. Claude の worktree で Claude Code を起動し、2 つのプラグインの準備を確かめる。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: 手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else { Set-Location -LiteralPath "$WT_ROOT\claude"; claude }
   ```

   - 確かめることは、[実施手順](#実施手順)の手順 11 と同じ
   - プラグインのスクリプトは、Claude Code が Git Bash で動かす。`/codex:setup` が `node` を見つけられなければ、Git for Windows の入れ直しか、この節の手順 10 を確かめる
   - **後ろの節のコマンドは、Claude Code を終えて PowerShell のプロンプトに戻ってから貼る**

---

## Windows 11 の更新

- Claude Code・Codex・Grok Build 自身は、それぞれの手順書の Windows 11 の更新

1. Node.js を上げる。

   ```powershell
   scoop update nodejs-lts
   node --version
   ```

   - 上げるものが無ければ `Latest versions for all apps are installed!`（か `… is already installed`）と出る
   - Node.js をほかの方法で入れていたら、その方法で上げる

1. 2 つのプラグインのマーケットプレイスとプラグインを上げる。

   ```powershell
   claude plugin marketplace update openai-codex
   claude plugin marketplace update xai-grok-build
   claude plugin update codex@openai-codex
   claude plugin update grok-build@xai-grok-build
   claude plugin list
   ```

   - 見方は、[更新](#更新)の手順 2 と同じ

---

## Windows 11 のロールバック

- この節では、worktree・ブランチ・プラグイン・Node.js を外す。AGENTS.md と CLAUDE.md の規則は残る（要らなければ、[ロールバック](#ロールバック)の手順 7 と同じ）
- [Windows 11 で使う](#windows-11-で使う)の手順 1 の変数を設定した PowerShell で行う

> [!CAUTION]
> **この節の手順 4 は、取り込んでいない作業ごと、3 つの worktree とブランチを消す**（取り戻せない）。この節の手順 3 で断られたときに、捨ててよいと確かめてからだけ行う。

1. 動いているエージェントと Remote Control を終える。

   - 開いている窓のエージェントを終え（Claude Code は `/exit`、Codex と Grok は `/quit`）、その窓を閉じる
   - Remote Control のタスクを使っているなら、[windows-claude-remote-control.md のロールバック](windows-claude-remote-control.md#ロールバック)を先に行う

1. 消す前に、コミットしていない変更と、取り込んでいないコミットを確かめる。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: Windows 11 で使うの手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
     foreach ($a in 'claude', 'codex', 'grok') { "== $a"; git -C "$WT_ROOT\$a" status --short; git -C $PROJECT_DIR log --oneline "main..agent/$a" }
   }
   ```

   - 見方は、[ロールバック](#ロールバック)の手順 2 と同じ

1. 3 つの worktree とブランチを消す。

   ```powershell
   if (-not $PROJECT_DIR) { Write-Error '中断: Windows 11 で使うの手順 1 の $PROJECT_DIR が空のまま。値を入れて貼り直す' } else {
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
- **Codex は sandbox の中でコミットできない**: Codex の sandbox は `.git` を読むだけにする（worktree でも、ふつうのチェックアウトでも同じ。[検証記録](verification/coding-agents.md#codex-の-sandbox-と-git)）。コミットは承認するか、人が行う
- **Grok Build は既定で sandbox が無い**: [分担して作業する](#分担して作業する)のリードの `[!WARNING]`。Windows には sandbox が無い
- **Grok の読むだけの sandbox には bubblewrap が要る**: AlmaLinux 10 で bubblewrap が無いと、`--sandbox read-only` の Grok（`/grok-build:review` も）は起動しない（実施手順の手順 9 で入れる。[検証記録](verification/coding-agents.md#grok-の-sandbox-と-bubblewrap)）
- **Grok は Claude の指示書も読む**: CLAUDE.md・CLAUDE.local.md・`~/.claude/CLAUDE.md` も読む（信頼したフォルダーだけ）。3 つに共通の規則は AGENTS.md に書く
- **`/grok-build:check` は、ログインしていなくても ready と出る**（grok-build のプラグイン 0.2.1 と Grok Build 1.0.50。`grok models` の終了コードで判定するため）。ログインは `grok models` の表示で確かめる
- **Codex のレビューの関門は使わない**: `/codex:setup --enable-review-gate` にすると、Claude Code が終わるたびに Codex のレビューを待つ（Stop の hook）。使用量が増え、指摘が続くと止まらない
- **プラグインはどのプロジェクトでも動く**: 自分のユーザーに入るので、どのディレクトリの Claude Code でも、起動と終了のたびに `node` で hook を動かす。外すときは、Node.js より先にプラグインを外す
- **規則を変えるのは `main` で**: AGENTS.md を変えたら `main` にコミットし、各 worktree を[main に取り込む](#main-に取り込む)の手順 7 でそろえる（エージェントは起動したときの worktree の AGENTS.md を読む）
