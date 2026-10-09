# Claude Code・Codex・Grok Build を 1 つのプロジェクトで共同作業させる（AlmaLinux 10・Windows 11）の検証記録

[手順書](../coding-agents.md)・[参考資料](../reference/coding-agents.md)

## 対象と検証環境

- **状態（2026-10-09 UTC）**: AlmaLinux 10.2 / x86_64 のコンテナで、3 つの CLI のログイン無しでできる範囲を、手順書のコードブロックのまま本実行した。ログインの要る Claude Code の確かめは、クラウドのホストのログイン済みの Claude Code で行った。実機・VM ではない
  - 通したもの（コンテナ）: 実施手順の手順 1〜7・9・10、手順 8 の Grok の行、手順 11 の変数が空のときの中断
  - 通したもの（コンテナ）: 分担して作業するの手順 1（tmux。疑似端末で流し、デタッチと貼り直しも）と手順 7、main に取り込むの手順 2〜7（エージェントのコミットは手で作り、わざと競合させて `--abort` と直し方も通した）、更新の手順 1・2、ロールバックの手順 1〜6（手順 6 は `N` と答えてトランザクション表まで）
  - 確かめたこと（コンテナ）: 手順 4・5・7 を貼り直したときの止まり方、既にある CLAUDE.md（末尾に改行が無い）への追記、ロールバックの手順 3 が変更の残る worktree と取り込んでいないブランチを断ること、片付けてから貼り直すと消えること
  - 確かめたこと（ホスト）: Claude Code 2.1.295 が AGENTS.md を読む・読まない条件（4 通り）、実施手順の手順 1〜7 の後の手順 8 の Claude の行（ツールを使わずに規則を答えた）、使い方の基本の `claude -p --permission-mode plan` のレビュー（ファイルを変えない）
  - 確かめたこと: 2 つのプラグインの導入・一覧・更新・削除（ログイン無し）、`/codex:setup` と `/grok-build:check` が動かすスクリプトの結果（`node` で直接動かした）、Codex の sandbox の中の `git add`（別の特権のコンテナ）
  - 確かめたこと: Grok の `--sandbox read-only` は、bubblewrap が無いと起動しない。入れると、別の特権のコンテナでログインの確認まで進んだ（手順 9 に bubblewrap を足した）
  - 確かめたこと: bash の 33 ブロックの `bash -n` と ShellCheck 0.9.0（ブロックをまたぐ変数の SC2154・SC2034 を除き指摘 0）。PowerShell の 20 ブロックの構文（PowerShell 7.6.6、エラー 0）と PSScriptAnalyzer 1.25.0 の 5.1 互換の検査、AGENTS.md と CLAUDE.md を書く 2 ブロックの模擬（BOM と CR が無いこと）
  - **確認していないこと**: Codex と Grok のログイン後のすべて（手順 8 の Codex の答え、`codex review`・`grok -p` のレビュー、プラグインの review・rescue・delegate・status、手順 11 の画面）。3 つのエージェントが実際に分担して作業し、コミットすること
  - **確認していないこと**: スマートフォンから指示するの全部（Remote Control は、既存の [almalinux-setup.md の tmux の任意節](../almalinux-setup.md#claude-code-を-tmux-の中で動かす任意)と [windows-claude-remote-control.md](../windows-claude-remote-control.md) の範囲）。プラグインのコマンドがスマートフォンから動くか
  - **確認していないこと**: Windows 11 での実行すべて。aarch64。実機・VM。Homebrew の tmux（今回は BaseOS の 3.3a）

| 項目 | 値 |
|---|---|
| 実施日 | 2026-10-09 UTC |
| コンテナ | クラウドの Linux の Docker 29.8.2 の上の `almalinux:10`（AlmaLinux 10.2 (Lavender Lion)、x86_64、digest `sha256:838c2fafefb1a8a0d7f8cdbc3b0551c2a2b1eb0cd87aad6d62aecadb18311f1b`）。一般ユーザー（`SHELL=/bin/bash`、umask 0022）、git の設定は [git.md](../git.md) の手順 2〜5 と同じ値 |
| CLI | Claude Code 2.1.295（公式 dnf リポジトリの `latest`）、Codex CLI 0.162.0（standalone のインストーラー）、Grok Build 1.0.50。どれもログインしていない |
| ほかのもの | git 2.52.0-1.el10、tmux 3.3a（BaseOS）、Node.js 22.23.2-3.el10_2 と nodejs-npm 10.9.8（AppStream） |
| プラグイン | `codex@openai-codex` 1.0.6、`grok-build@xai-grok-build` 0.2.1 |
| ホスト | Ubuntu 24.04 のクラウドのホストの、ログイン済みの Claude Code 2.1.295（`env -i` で、このセッションの環境変数を渡さずに起動した） |
| PowerShell の検査 | Ubuntu 22.04 のコンテナの PowerShell 7.6.6、PSScriptAnalyzer 1.25.0 |

> [!NOTE]
> 出力の中の利用者名は `<USER>` に置き換えた。試験用のプロジェクトは、`app.py` と CLAUDE.md だけの使い捨てのリポジトリ。

### 実施前の状態

- 3 つの CLI を入れた一般ユーザー（ログインしていない）
- 試験用のプロジェクト `~/src/myproject`: `main` に 1 コミット（`app.py` と、末尾に改行の無い CLAUDE.md）。AGENTS.md と `~/src/myproject.worktrees` は無い

### 完了時点の状態

- 以下は読者が手順を終えたときの確認点。今回の検証で Codex と Grok のログイン・AI への依頼まで通したという意味ではない
- `main` に AGENTS.md（「## 共同作業の規則」の節）と、`@AGENTS.md` の行のある CLAUDE.md がコミットされている
- `git worktree list` に `[main]`・`[agent/claude]`・`[agent/codex]`・`[agent/grok]` の 4 行
- `claude plugin list` に、2 つのプラグインが `✔ enabled` で出る
- 3 つが、それぞれの worktree で AGENTS.md の規則を読む（Claude はホストで確かめた。Grok は `grok --trust inspect` で確かめた。Codex は未確認）

## 付録: コンテナとホストでの検証（2026-10-09）

### 実施手順 / 手順 1〜7

- 手順 2: 3 つの版（`2.1.295 (Claude Code)`・`codex-cli 0.162.0`・`grok 1.0.50 (c58f321264ba)`）。ログインしていないので、`codex login status` は `Not logged in`、`grok models` は `You are not authenticated.`、`claude auth status --text` は `Not logged in. Run claude auth login to authenticate.`
- 手順 3: `/home/<USER>/src/myproject`・`## main`・`CLAUDE.md`、最後に `ls: cannot access '…/myproject.worktrees': No such file or directory`
- 手順 4: AGENTS.md を作り、規則の節だけが出た（12 行）
- 手順 5: 末尾に改行の無い CLAUDE.md に、改行を補ってから `@AGENTS.md` を足した。`tail -n 3` は空行・`- Claude だけのメモ`・`@AGENTS.md`
- 手順 6: `[main b30f85d] Claude Code・Codex・Grok Build の共同作業の規則を足す`、`2 files changed, 14 insertions(+), 1 deletion(-)`（1 deletion は、CLAUDE.md の最後の行に改行が足されたため）
- 手順 7: `Preparing worktree (new branch 'agent/claude')` と `HEAD is now at …` が 3 組、一覧に 4 行
- 貼り直したとき: 手順 4 は `中断: AGENTS.md に「## 共同作業の規則」がもうある。…`、手順 5 は `CLAUDE.md に @AGENTS.md はもうある`、手順 7 は `fatal: a branch named 'agent/claude' already exists` が 3 つと一覧（何も変わらない）
- 手順 11 を `PROJECT_DIR` が空のまま貼ると、`中断: …` が出て、今のディレクトリは変わらなかった
- 手順 3 は、ShellCheck の SC2010（`ls | grep`）を受けて、`for` と `[ -e ]` の形に直し、直した後のブロックをもう一度流した（`AGENTS.md`・`CLAUDE.md` の 2 行が出た）

### 実施手順 / 手順 8

- コンテナ（ログイン無し）
  - Claude の行: `Not logged in · Please run /login`
  - Codex の行: 設定の見出し（`model: gpt-6.1-sol`・`approval: never`・`sandbox: read-only`）の後に、`401 Unauthorized` で 5 回つなぎ直して終わった。`Codex could not find bubblewrap on PATH. … Codex will use the bundled bubblewrap in the meantime.` の警告も出た（AlmaLinux 10 の BaseOS に `bubblewrap` 0.10.0 がある）
  - Grok の行（`grok --trust inspect`。AI には聞かない）: `Project trusted: yes`、`…/myproject.worktrees/grok/CLAUDE.md (project, ~11 tokens)`、`…/grok/AGENTS.md (project, ~323 tokens)`
- ホスト（ログイン済みの Claude Code 2.1.295。CLAUDE.md の無い使い捨てのプロジェクトで手順 1〜7 を流した後）
  - Claude の行: `起動された worktree（作業ディレクトリ）の中だけで、しかも頼まれた範囲のファイルだけを変えてよい。ほかの worktree は変えない。`
  - 同じ問いを `--output-format json` で流すと `num_turns=1`（ツールを使わず、読み込まれた指示から答えた）

### 実施手順 / 手順 4〜6: Claude Code が AGENTS.md を読む条件

- ホストの Claude Code 2.1.295 で、AGENTS.md に合言葉を書いた使い捨てのリポジトリを 4 つ作り、「ファイルやツールは使わずに、読み込まれている指示だけから答えて」と聞いた（どれも `num_turns=1`）

| 置いたもの | 答え |
|---|---|
| AGENTS.md だけ | 合言葉を答えた（読む） |
| AGENTS.md と、`@AGENTS.md` の 1 行の CLAUDE.md | 合言葉を答えた（取り込みで読む） |
| AGENTS.md と CLAUDE.local.md（取り込みの行は無い） | 「不明」（読まない） |
| AGENTS.md と CLAUDE.md（取り込みの行は無い） | 「不明」（読まない） |

### 実施手順 / 手順 9〜11: Node.js とプラグイン

- 手順 9: 初回は `nodejs-22.23.2-3.el10_2` と `nodejs-npm-10.9.8-1.22.23.2.3.el10_2` が入り、`v22.23.2`。bubblewrap を足した後のブロックは、Node.js が入っていたので `bubblewrap-0.10.0-3.el10` だけが入り、`v22.23.2` と `bubblewrap 0.10.0`（コンテナの最小構成には bubblewrap が無かった。GNOME のデスクトップでは Flatpak と `gnome-desktop3` が bubblewrap を必要とするので、入っているはず）
- 手順 10: `✔ Successfully added marketplace: openai-codex (declared in user settings)` と `xai-grok-build`、`✔ Successfully installed plugin: codex@openai-codex (scope: user)` と `grok-build@xai-grok-build`。一覧は `Version: 1.0.6` と `0.2.1`、どちらも `Status: ✔ enabled`。ログインしていなくても動いた
  - `~/.claude/settings.json` に `enabledPlugins` の 2 つと、`extraKnownMarketplaces` の 2 つが書かれた
- 手順 11 の `/codex:setup` と `/grok-build:check` は、Claude Code にログインしていないので打っていない。2 つが動かすスクリプトを `node` で直接動かした
  - `codex-companion.mjs setup --json`: `"ready": false`、Node `v22.23.2`、npm `10.9.8`、Codex `codex-cli 0.162.0; advanced runtime available`、`"loggedIn": false`、次の手順に `Run !codex login.`。Codex が見つかるので、npm で入れる提案の分岐には入らない
  - `grok-bridge.mjs check --json`: `"ready": true`、`"loggedIn": true`、`"detail": "You are not authenticated."`、`"source": "models-probe"`（ログインしていないのに ready と出た。プラグインは `grok models` の終了コード 0 だけで判定している）
- プラグインの中身（GitHub の `openai/codex-plugin-cc` の `db52e28`、`xai-org/grok-build-plugin-cc` の `92b76a6`）
  - `review` の 2 つのコマンドは `disable-model-invocation: true`。`rescue` と `delegate` は Claude が呼べるサブエージェント（`codex-rescue`・`grok-delegate`）を通る
  - hooks: Codex は `SessionStart`・`SessionEnd`・`Stop`（レビューの関門。既定で無効）、Grok は `SessionStart`・`SessionEnd`。どれも `node` で動く
  - Grok の review は `--agent explore`・`--sandbox read-only`・`--always-approve` で `grok -p` を動かす

### 分担して作業する / 手順 1・7

- 手順 1 を `script` の疑似端末で流した。ウィンドウは `0:main`（プロジェクト）・`1:claude`・`2:codex`・`3:grok`（それぞれの worktree）から始まった
- 別の端末から `tmux detach-client` で離すと `[detached (from session agents)]` で、セッションは残った（`agents: 4 windows`）。もう一度貼ると、作らずにそのセッションに入った
- 手順 7: 3 つの worktree で手で作ったコミットが 1 つずつ出て、`git status --short` は何も出さなかった

### main に取り込む / 手順 2〜7

- Claude と Codex の worktree で同じ `app.py` を別々に変え、Grok の worktree では別のファイルを足してコミットした（エージェントの作業の代わり）
- 手順 2: `## main` と、各ブランチのコミット（`cd92c2e (agent/claude) …` のように、ブランチの名前が付く）
- 手順 3: `Merge made by the 'ort' strategy.`
- 手順 4: `CONFLICT (content): Merge conflict in app.py`（rerere が `Recorded preimage for 'app.py'`）
- 手順 6: `git merge --abort` の後、`## main` だけ
- Codex の worktree で `git merge main` と競合の修正・コミットをした後（担当のエージェントの作業の代わり）、手順 2 から: 手順 3 は `Already up to date.`、手順 4・5 は `Merge made by the 'ort' strategy.`
- 手順 7: 3 つの worktree で `Fast-forward`。一覧の 4 行が同じコミットになった

### 相互にレビューする: Claude のレビュー

- ホストで、`main` から作った worktree のブランチ（`add` を引き算にする 1 行の変更）を、`claude -p --permission-mode plan` で「main との差分（git diff main...HEAD）をレビューして。ファイルは変えない。…」と頼んだ
- `num_turns=4`（`git diff` などを読んだ）、`permission_denials` は 0。重大度・場所（`calc.py:2`）・理由・直し方の形で指摘が返り、`git status --short` は空（ファイルは変わらない）

### 更新 / 手順 1・2

- 手順 1: `Nothing to do.` と `v22.23.2`
- 手順 2: `✔ Successfully updated marketplace: openai-codex`・`xai-grok-build`、`✔ codex is already at the latest version (1.0.6).`・`✔ grok-build is already at the latest version (0.2.1).`

### ロールバック / 手順 1〜6

- Codex の worktree に追跡していないファイルを置き、Grok のブランチに取り込んでいないコミットを足してから流した
- 手順 2: `== codex` の下に `?? scratch.txt`、`== grok` の下にそのコミット
- 手順 3（1 回目）: `Deleted branch agent/claude`。Codex は `contains modified or untracked files, use --force to delete it` と `cannot delete branch 'agent/codex' used by worktree`、Grok は worktree は消えて `the branch 'agent/grok' is not fully merged`。`rmdir` は `Directory not empty`、一覧は `[main]` と `[agent/codex]`
- 手順 3（追跡していないファイルを消し、Grok のブランチを取り込んでから 2 回目）: `branch 'agent/claude' not found`、`Deleted branch agent/codex`・`agent/grok`、一覧は `[main]` だけ
  - 最初の版は `worktree remove … && branch -d …` で、worktree だけ消えてブランチが残ったとき、貼り直してもブランチが消えなかった。worktree があるときだけ消し、ブランチは毎回消す形に直して、上の 2 回を流した
- 手順 4（別の回。強制）: 消えたものは `is not a working tree`・`branch 'agent/claude' not found`、残りは `Deleted branch …`。一覧は `[main]` だけ
- 手順 5: `✔ Successfully uninstalled plugin: codex (scope: user)`・`grok-build`、`✔ Successfully removed marketplace: …` が 2 つ、`No plugins installed.`
- 手順 6（`N` と答えた）: `Removing:` に `nodejs`・`nodejs-npm`、`Removing unused dependencies:` に `c-ares`・`libbrotli`・`libuv`・`nodejs-docs`・`nodejs-full-i18n`・`nodejs-libs`・`openssl`（コンテナの最小構成では `openssl` も Node.js と一緒に入っていたため）

### Codex の sandbox と git

- `codex sandbox`（Codex 0.162.0 が自分の sandbox の中でコマンドを動かす機能）で確かめた。最初のコンテナでは、bubblewrap が user namespace を作れず動かなかったので、`--privileged` の別の AlmaLinux 10.2 のコンテナで流した
- `-P :workspace`（書き込みのできる sandbox）で、worktree の中にファイルは作れたが、`git add` は `fatal: Unable to create '…/.git/worktrees/codex/index.lock': Read-only file system` で失敗した
- ふつうのチェックアウト（`main`）でも、`fatal: Unable to create '…/.git/index.lock': Read-only file system` で同じだった
- `-c sandbox_workspace_write.writable_roots=["<プロジェクト>/.git"]` を足しても変わらなかった
- `-P :read-only` では、ファイルも作れなかった（`Read-only file system`）

### Grok の sandbox と bubblewrap

- 使い方の基本の表の Grok のレビュー（`grok --trust -p "…" --sandbox read-only --always-approve`）を、ログインしていないコンテナで流した（ログインの前に、引数と sandbox が受け付けられるかを見た）
- bubblewrap が無いとき: `Error: this sandbox could not enforce its deny list on Linux: bwrap exec failed: No such file or directory (os error 2).` に続けて、bubblewrap を入れるよう案内し、`Refusing to start with denied paths unprotected.` で終わった（終了コード 1）（Grok の同梱の文書 18-sandbox にも、Linux で読むことを禁じる場所がある sandbox には bubblewrap が要り、無いと起動しないとある）
- bubblewrap 0.10.0 を入れた `--privileged` のコンテナ: sandbox の準備を過ぎて `Not signed in. To authenticate without a browser, run: grok login --device-code` で終わった（ログインしていないため）
- bubblewrap を入れた、特権の無いコンテナ: `bwrap: No permissions to creating new namespace …`（コンテナが user namespace を許さないため。実機の AlmaLinux 10 では、一般ユーザーの user namespace が使える）
- `/grok-build:review` も同じ `--sandbox read-only` を付けるので、AlmaLinux 10 では bubblewrap が要るはず（プラグインのコマンドとしては確かめていない）

### Windows 11 の節: 構文の検査と模擬

- Windows 11 で使う・Windows 11 の更新・Windows 11 のロールバックと、分担して作業するの手順 2 の PowerShell の 20 ブロックを、PowerShell 7.6.6 の構文解析器で解析した（エラー 0）
- PSScriptAnalyzer 1.25.0 の 5.1 互換の検査（`PSUseCompatibleSyntax`・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`、プロファイル `win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework`）の指摘は 1 つ。Windows 11 の更新の手順 1 の `node` が 5.1 に無いコマンドだというもので、scoop で入れる外のコマンドなので当たらない
- AGENTS.md と CLAUDE.md を書く 2 ブロック（Windows 11 で使うの手順 4・5）を、Linux の PowerShell 7.6.6 で、`PROJECT_DIR` だけ Linux のパスに変えて流した
  - ファイルが無いとき: AGENTS.md 1,295 バイト・CLAUDE.md 11 バイト。どちらも BOM 無し・CR 無し・LF で終わる
  - 既にあるとき（AGENTS.md は末尾に改行無し、CLAUDE.md は CRLF の行と末尾に改行無し）: 空行を挟んで規則の節を足し、`@AGENTS.md` の行を足した。足した部分に CR は無い（もとの CLAUDE.md の CRLF は 1 つ残る）
  - 貼り直したとき: `中断: AGENTS.md に「## 共同作業の規則」がもうある。…` と `CLAUDE.md に @AGENTS.md はもうある`。規則の節は 1 つのまま
  - `$PROJECT_DIR` が空のとき: 手順 4・5・8 とも `中断: 手順 1 の $PROJECT_DIR が空のまま。…`
- worktree を作る・消すブロックは、パスに `\` を使うので Linux では流していない
