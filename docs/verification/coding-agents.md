# Claude Code・Codex・Grok Build を 1 つのプロジェクトで共同作業させる（AlmaLinux 10・Windows 11）の検証記録

[手順書](../coding-agents.md)・[参考資料](../reference/coding-agents.md)

## 対象と検証環境

- **状態（2026-10-10 UTC）**: AlmaLinux 10.2 / aarch64 の Raspberry Pi 5 の実機で、ログイン済みの CLI と専用の一時リポジトリを使って検証した。PR #117 のマージコミット `814b590` を対象に、操作を個別に実施した。手順書のコードブロックを抽出して一括実行していない
  - 確認したこと: 3 つの CLI が担当ファイルだけを実装すること。各担当の受入テストと ShellCheck、Claude・Grok のコミット、Codex の sandbox の `git add` 拒否を人のコミットへ引き継ぐこと。人が main に取り込んだ後の 8 テストと各 worktree の同期
  - 確認したこと: 実際の Claude Code の対話画面での `/codex:setup`・`/grok-build:check`。Codex のプラグインの review が既知の欠陥 2 件を検出し、前後のファイルのハッシュと git の状態が変わらないこと。rescue が依頼した `ports.py` だけを修正し、担当テストが通ること
  - 確認したこと: 別の専用リポジトリで、競合・abort・競合の解消・3 ブランチの取り込み・各 worktree の fast-forward・変更が残る worktree と未取り込みのブランチの撤去拒否・片付け後の撤去の再実行・使い捨ての変更の強制撤去。コミットと競合の解消は人が作ったもので、AI の実分担の結果とは別
  - 失敗したこと: Grok の workspace sandbox は準備に失敗。プラグインの read-only review は `/run/podman/podman.sock` の拒否パスの解決で permission denied（errno 13）。bubblewrap が入っていても、レビューは起動しなかった
  - 追加の原因調査と準備: 空の `/run/podman` の検索権限不足と、カーネルの Landlock 無効を別々に確認し、試験後の権限は復元済み。対応する Image のビルドと静的検査 7 項目、検索だけを許す ACL の模擬検査 6 項目は成功。ユーザーの指示で調査・準備までで終了し、ホストへの適用・再起動・Grok の再検証は行っていない。レビュー失敗は未解消
  - 確認したこと: Grok の通常の auto 許可での実装と delegate、Claude・Codex の端末レビュー、tmux の detach と再接続、Codex の背景レビュー・結果取得・worker の取消。両 CLI の導入・更新・撤去は対応する検証記録に記載する。設定の復旧結果は今回の付録の末尾に分ける
  - 今回の対象外: スマートフォンからの Remote Control・SSH と、スマートフォンからのプラグインのコマンド。Windows 11。今回のホストの結果を、2026-10-09 のコンテナの結果や Windows の成功範囲へ広げない

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

## 付録: Raspberry Pi 5 の実機での検証（2026-10-10）

| 項目 | 値 |
|---|---|
| 対象 | setup-notes PR #117 のマージコミット `814b590badccdb7af4b471bac628f34e0f3cb7ec` |
| 実施日 | 2026-10-10 UTC |
| ホスト | Raspberry Pi 5 Model B Rev 1.0。AlmaLinux 10.2 (Lavender Lion)、aarch64、カーネル `6.12.96-20260724.v8.1.el10` |
| CLI | Claude Code 2.1.296（RPM）、Codex CLI 0.160.0、Grok Build 1.0.50。既存の利用者のログインを使った。Codex は前回の 0.162.0 とは別の版 |
| OS の条件 | SELinux は Disabled。ソケット本体の権限と OS の保護設定は永続変更していない。親ディレクトリの mode の一時試験と復元は後述 |
| 依存 | Node.js 22.23.2、npm 10.9.8、bubblewrap 0.10.0、tmux next-3.4 |
| プラグイン | `codex@openai-codex` 1.0.6、`grok-build@xai-grok-build` 0.2.1 |
| 実分担用のリポジトリ | `<VERIFY_DIR>/fixture` と、隣の `fixture.worktrees/claude`・`codex`・`grok`。`main` と `agent/claude`・`agent/codex`・`agent/grok` |
| 別の試験用リポジトリ | プラグインのレビューと委任のためのリポジトリ、git の競合と撤去を確かめる `fixture-lifecycle`。実分担用のリポジトリとは分けた |

> [!NOTE]
> 利用者名とホスト名は `<USER>`・`<HOSTNAME>` に置き換える。以下の `<VERIFY_DIR>` は今回だけの一時ディレクトリ。生の認証情報、デバイスコード、トークン、パスワードは記録しない。以下にある追加のフラグは今回の非対話の検証の条件で、手順書の対話起動と同じ実施範囲とは扱わない。

### 実施手順 / 手順 1〜8: 一時プロジェクトと共通規則

- `AGENTS.md` に手順書の「共同作業の規則」と担当ごとのテスト・リンターのコマンドを置き、`CLAUDE.md` に `@AGENTS.md` の 1 行を置いた。ローカルの git の作者は `Test Operator <test@example.invalid>` とし、グローバルの設定は変えていない
- 初期コミット `40eefed` から 3 つの worktree と `agent/*` のブランチを作り、4 つとも同じコミットから始まることを確かめた
- Claude と Codex に、ツールを使わずに読み込まれた規則だけから変更できる場所を答えるよう頼み、自分の worktree の中だけという答えを確認した
- 初期状態の 3 つのスクリプトは、終了コード 3 の未実装の stub。`python3 -m unittest discover -s tests -v` は 8 テスト・71 failures で失敗し、`shellcheck bin/*` は終了コード 0。実装前からテストが成功していたわけではない
- 1 つの担当のブランチにはほかの 2 つの stub が残るため、各担当は自分のテストと共通の ShellCheck をコミットの条件とした。統合テストは人が 3 ブランチを取り込んだ後の確認とした

### 実施手順 / 手順 9〜11: プラグインの準備と対話画面

- 2 つの公式のマーケットプレイスとプラグインを追加し、Codex 1.0.6 と Grok Build 0.2.1 が有効であることを確認した
- Claude Code の実際の対話画面で `/codex:setup` と `/grok-build:check` を実行した。Codex の準備とログイン、Node.js と Grok の検出を確認した。前回の、`node` でスクリプトだけを呼んだ検証とは別
- Grok の認証は `grok --no-auto-update models` の `You are logged in with grok.com.` で確認した。`/grok-build:check` の ready だけを認証成功の根拠にしていない
- `/codex:setup --enable-review-gate` は使っていない。検証中に既存の CLI を意図せず更新しないよう、自動更新を止める条件で起動した

### 分担して作業する / 手順 3〜7: 3 つの CLI の実装

- Claude は `bin/double`、Codex は `bin/is-port`、Grok は `bin/trim` を担当する形にした。固定の `tests/`・仕様書・指示書・ほかの担当のスクリプトを変えないよう依頼した
- Claude の起動は `-p --no-session-persistence --permission-mode acceptEdits`。Read・Edit・Write と、担当の unittest・ShellCheck・git のステージとコミット等に許可を限定した。モデルと reasoning effort は指定していない
  - `bin/double` だけを実装し、`agent/claude` に `72bc567` をコミットした。差分は 1 ファイル、worktree は clean
  - 符号と先頭の 0、不正な引数、64 bit を超える整数を含む担当の 3 テストと `shellcheck bin/*` が成功した。検証者が同じコマンドをもう一度実行しても成功した
  - 複数の操作をまとめた Bash の書き込みと spot check は許可に合わず、2 回拒否された。その後、許可されたファイルの編集とテストで完了した。全権を許す設定には切り替えていない
  - 実行時間 27.860 秒、CLI の終了コード 0、timeout 無し、9 turns
- Codex の起動は `codex exec --ephemeral -s workspace-write --json`。モデルと reasoning effort は指定していない
  - `bin/is-port` だけを実装した。ASCII 数字・先頭の 0・1〜65535 の境界・巨大な整数の拒否を含む担当の 3 テストと `shellcheck bin/*` が成功した。検証者の再実行も成功した
  - `git add -- bin/is-port` は終了コード 128。`fatal: Unable to create '<VERIFY_DIR>/fixture/.git/worktrees/codex/index.lock': Read-only file system` で拒否された
  - Codex は sandbox の回避をせず、変更を未ステージで残し、人がこの worktree でステージとコミットを行うよう報告した。この時点では Codex 自身のコミットは無い
  - 実行時間 56.585 秒、CLI の終了コード 0、timeout 無し。CLI が正常終了したことと、git のコミットが成功したことは区別する
- Grok の `--sandbox workspace` による実装は sandbox の準備で失敗した。その結果を、後の通常の許可モードでの成功と分けた
  - `acceptEdits` と限定した Bash 許可の試行、および担当ファイルの Edit・Write 許可を指定した試行は、Bash の許可待ちで `stopReason: "cancelled"` になった。終了コードは 0 だが、変更とコミットは無かった
  - 前者の最後はシェルによる書き込み、後者は `stat`・`file` 等を含む連結コマンド。許可した Edit・Write や一部の Bash コマンドだけでは許可されなかった。今回のセッションの `permission_cancelled` で確認した
  - `grok --no-auto-update --trust --permission-mode auto --output-format json -p …` では `bin/trim` だけを実装し、`agent/grok` に `147bb88` をコミットした。通常の許可判定を使い、sandbox の成功として扱わない
  - ASCII の 6 種の空白、内部の空白、Unicode 空白、シェルの文字、不正な引数を含む担当の 2 テストと ShellCheck が成功した。検証者の再実行も成功した
  - 実行時間 175.605 秒、終了コード 0、`stopReason: "end_turn"`、12 turns。モデルと reasoning effort は指定していない
- Codex の変更は人が `e5c1422` にコミットした。3 担当の差分は `bin/double`・`bin/is-port`・`bin/trim` だけで、固定のテスト・仕様・指示書は変わらなかった

### 相互にレビューする / 手順 1: 2 つのプラグインのレビュー

- 別の試験用リポジトリに既知の欠陥 2 件を置き、Claude Code から Codex の review を実行した。2 件を検出し、前後のファイルのハッシュと git の状態は同じだった。読取レビューが勝手に修正したという結果ではない
- Grok の review は失敗した。このホストの `/run/podman/podman.sock` を扱う sandbox の準備で permission denied（errno 13）となり、モデルのレビューまで進まなかった
- 同じホストの Grok の workspace sandbox による実装も、`could not apply the 'workspace' sandbox profile` で失敗した。この出力だけでは read-only と同じ原因か断定しない。Podman のソケットの権限は変更していない

### 使い方の基本: rescue と delegate

- Codex の rescue は、Claude の試験用 worktree で、依頼した `ports.py` だけを修正した。担当テストは成功した。独立した Codex の worktree に修正したのではない
- Grok の delegate は、依頼した `text.py` だけを修正し、ASCII の 6 種の空白を除く処理へ戻した。担当テストが成功し、Codex の rescue と合わせた全 2 テストも成功した。tests と指示書は変わらなかった
- 2 つの委任は実際の Claude Code の対話画面から、プラグインのサブエージェントを通して実行した。実行先は Claude の worktree。別々の CLI の worktree で行った前節の実分担とは区別する
- 背景実行の検査は、インストールされたプラグインのスクリプトを `node` で呼んだ。実際の slash command の検証とは別の component の検査で、モデルと effort の上書きは無い

| 検査 | 結果 |
|---|---|
| Codex `review`・`adversarial-review` | 背景実行が completed になり、状態と結果を取得した。既知のポート上限の欠陥を指摘。前後の全ファイルのハッシュ・HEAD・git の状態は同じ |
| Codex `cancel` 初回 | turnId の取得を待つ間にレビューが完了し、実行中の取消は未検証 |
| Codex `cancel` 再試験 | threadId と生存中の worker PID を確認して取消。終了コード 0、running → cancelled、worker PID 消滅。`turnInterruptAttempted: false`・`turnInterrupted: false` のため、サーバー側の推論停止までは証明していない |
| Codex 専用 broker の終了 | shutdown が終了コード 0。登録した broker と子プロセスが残っていない |
| Grok `critique` | read-only sandbox の同じ errno 13 で failed。状態と失敗結果を取得でき、全ファイル・HEAD・git の状態は同じ |
| Grok `stop` | 先に sandbox 起動が failed になったため、実行中の停止は未検証。停止機能の不具合とは判定しない |

### main に取り込む / 手順 2〜7・ロールバック / 手順 2〜4: 別のリポジトリでの git 操作

- `fixture-lifecycle` に人が作った 3 ブランチを使い、以下の 9 項目を実際の git で確認した。これらのコミットは、Claude・Codex・Grok の実装の代わりに人が作ったもの
  - 同じ `app.py` の変更による merge conflict
  - `git merge --abort` で取り込み前の HEAD と clean な状態へ戻ること
  - 担当のブランチで main を取り込み、人が競合を解消してコミットすること
  - 3 ブランチの main への取り込み
  - 3 つの worktree の `git merge --ff-only main`
  - 未追跡ファイルの残る worktree の通常の撤去が拒否され、ファイルが残ること
  - worktree を消せても、未取り込みのブランチの `branch -d` が拒否されること
  - 未追跡ファイルを片付け、残るブランチを取り込んでから通常の撤去を再実行できること
  - 強制撤去用に別に作った使い捨てのファイルとコミットの `--force`・`branch -D` による撤去。main の HEAD は変わらないこと
- 最後は `main` だけ、worktree は 1 つで clean。この結果を、実分担用の 3 つの実装が統合済みであるという記録にはしていない

### main に取り込む / 手順 1〜7: 実分担の統合と同期

- 3 担当のテストが成功した後、人が `main` で Claude → Codex → Grok の順に `git merge --no-ff --no-edit agent/<担当>` を実行した
- 統合後の `python3 -m unittest discover -s tests -v` は全 8 テスト成功、`shellcheck bin/*` は終了コード 0
- 各 worktree で `git merge --ff-only main` を実行し、4 つとも `673357286b1b90e817c3a895196a4087fb03f966` で clean になった。エージェントに main を変えさせていない

### 分担して作業する / 手順 1: tmux と対話起動

- 既存の tmux へ触れないよう、今回だけの名前のサーバーに `agents` を作った。`0:main`・`1:claude`・`2:codex`・`3:grok` の 4 ウィンドウと、それぞれの作業ディレクトリを確認した
- 実際の PTY から attach し、`Ctrl+b` → `d` で detach。セッションが残ることを確認し、もう一度 attach と detach を通した。最後に今回のサーバーだけを終了した
- ログイン済みの Codex 0.160.0 と Grok 1.0.50 を実際の PTY で起動した。Codex は更新確認を起動時だけ無効にし、規則だけから自分の担当範囲を答えた。Grok は自動更新を起動時だけ無効にし、読むだけの依頼でプロジェクトの構成を説明した

### 相互にレビューする / 手順 2・3: 端末の CLI

- 別の試験用リポジトリにポート番号 65536 を許す欠陥をコミットし、`codex review --base main` と `claude -p --permission-mode plan …` を実行した。どちらも欠陥を指摘し、終了コード 0。レビュー対象の追跡ファイルと HEAD は変わらなかった
- Claude の検査コマンドで未追跡の Python bytecode と、Claude の計画ファイルが生成された。どちらも今回のファイルとして撤去した。端末レビューの全ファイル・git 状態が不変だったとは記録しない
- 手順書の `grok --trust -p … --sandbox read-only --always-approve` も実行した。同じ sandbox 準備エラーで終了コード 1。Grok のレビューは、端末からもプラグインからも成功していない

### 更新・撤去と今回の対象外

- 2 つの追加した marketplace と user scope のプラグインは、名前を指定して更新した。4 コマンドは終了コード 0。同じ版の確認で、無関係な marketplace は更新していない
- CLI の新規導入、更新、PATH と撤去は今回だけの native ユーザーで実施した。[Grok Build の今回の付録](grok-build.md#付録-raspberry-pi-5--aarch64-実機での検証2026-10-10)と [Codex の今回の付録](codex.md#付録-raspberry-pi-5--aarch64-実機での検証2026-10-10)に、実端末の更新と検証補助の失敗を分けて記録する
- スマートフォンの Remote Control・SSH と、スマートフォンからのプラグインのコマンド、Windows 11 は今回の対象外
- 各プランの使用量を使った。使用量は元に戻せない。初回のログイン手続き・サーバー側の推論停止・Grok の実行中ジョブの停止は今回の成功範囲に含めない

### 実施前の設定への復旧

- 既存の Claude Code は 2.1.296、Codex は 0.160.0、Grok は 1.0.50 のまま。終了後に 3 つの版とログイン済みの状態を確認した。認証ファイルのコピー・差し替え・ログアウトは行っていない
- 今回追加したプラグインと marketplace を名前を指定して削除した。4 コマンドは終了コード 0。対象の設定項目と設定ファイルの有無は実施前と一致し、もとの marketplace を保持した
- 今回だけの broker は所有する PID と起動時刻を確かめて shutdown した。残存した検証用のプロセスは 0。専用データと配布キャッシュも撤去した
- 復旧補助が終了済みジョブへ取消を再要求した 6 回は、対象状態を見つけられず終了コード 1。これを実行中の停止成功とは扱わない。専用 broker の終了と登録済み worker の消滅は別に確認した
- アンインストールが作った `.orphaned_at` だけがキャッシュに残ったため、内容を確認して 2 個の marker と空の専用ディレクトリを撤去した
- Claude の今回の project の信頼項目 2 件・セッションディレクトリ 5 個、Codex の今回の project trust table 2 件、Grok の今回の trust table 2 件・セッションディレクトリ 2 個、今回生成された計画ファイル 1 個を撤去した。他の設定値は保持した
- Codex と Grok の共有データベース、モデルのキャッシュ等の CLI が通常生成する共通状態は巻き戻していない。今回作成した worktree・プロジェクトは撤去し、非公開の試験ログと再確認用の fixture のアーカイブ、文書を修正した checkout を一時ディレクトリに残した
- native の専用ユーザー・グループ・ホームは無く、OS の RPM 一覧のハッシュは実施前後で一致。既存の checkout と親リポジトリは clean のまま。動作検証の終了時点では、文書の修正は今回の独立した checkout のローカル差分だけで、push はしていなかった（公開・マージは後続作業）

### 文書の確認

- 今回追加した相対リンク 12 件のファイルと見出しを確認し、参照先の不在は 0。`git diff --check` も成功した
- 手順書 3 本の bash の 59 ブロック（共同作業 33、Grok 13、Codex 13）を `bash -n` で確認し、構文エラーは 0。ブロックをホスト上で一括実行した検査ではない
- 過去の検証付録は保持し、今回の実機の結果を先頭の状態と付録に追加した。実ユーザー名・認証情報を文書へ転載していない

### 追加原因調査と対処の準備（2026-10-10）

- 先の errno 13 の失敗を受け、host の `/run/podman` を管理者権限で確認した。root 所有・mode `0700` の空ディレクトリで、`podman.sock` は存在せず、`podman.socket` と `podman.service` は inactive だった。ソケットへの接続権限ではなく、親ディレクトリを検索できないため、Grok の拒否パスの解決が失敗した
- 親の mode を一時的に `0711` にすると errno 13 は解消した。その後の `--sandbox read-only` は、必要な保護が適用されていないとして起動を拒否した。試験後は `0700` に復元した。ソケットを作成したり、ソケット自体のアクセス権を緩めたりしていない
- 稼働カーネルは `6.12.96-20260724.v8.1.el10`。build 設定は `CONFIG_SECURITY_LANDLOCK` が無効、実行中の LSM は `capability,selinux`。`landlock_create_ruleset` の ABI 問合せは `ENOSYS` だった。bubblewrap `0.10.0` の user namespace は動くが、これだけで read-only の保護が成立するとは扱わない
- このホスト向けの公式リポジトリの最新カーネルも同じ版で、対応する `raspberrypi2-6.12.96-20260724.v8.1.el10.src.rpm` を取得し、digest と署名の検証が成功した。SHA256 は `c13055e3878d5ccec4875ee3bd60de791912d75dc8258b23d89d577997a50aa3`
- 同じ source・release を使い、設定差分を `CONFIG_SECURITY_LANDLOCK=y` だけにした Image のビルドが完了した。実行時間は 1,245 秒、`Image.gz` は 9,597,976 bytes。SHA256 は `1a4a44d11d4be66f3c3db82d0bc6e3b8fabe99e92adafde8c4d40c13de683b49`。独立した静的検査の 7 項目はすべて成功した

| 静的検査 | 結果 |
|---|---|
| 完了記録と実 Image の照合 | release・SHA256 が一致 |
| 設定差分 | `CONFIG_SECURITY_LANDLOCK` の `n` → `y` だけ |
| カーネル release | `6.12.96-20260724.v8.1.el10` と完全一致 |
| 組み込みカーネルの公開 symbol | 11,289 件の集合・CRC・公開種別・namespace がすべて一致 |
| vmlinux の形式 | little-endian の ELF64 / AArch64 |
| Landlock の syscall 3 個 | create_ruleset・add_rule・restrict_self がすべて強い text symbol（`T`） |
| gzip と Image header | gzip の展開と AArch64 の header が有効 |

- この CRC の照合は静的な互換性検査で、実動作の保証ではない。新 Image での起動、既存 modules のロード、Landlock の初期化と ABI はまだ確認していない。同 release なので `uname -r` だけでは起動 Image を区別できない。また `CONFIG_IKCONFIG=m` の既存 `configs.ko` は元の設定を内包するため、`/proc/config.gz` の表示を新 Image の設定の証拠にしない。今後カーネルを更新する場合は、その版に合わせた再構築と検査が必要
- 別の使い捨てのディレクトリで、対象のユーザーだけに検索（`--x`）を許し、default ACL を付けない案を模擬した。root 所有・mode `0660` のソケットに対し、パス解決ができること、ディレクトリ一覧・書き込み・ソケット接続が拒否されること、ソケットの mode が変わらないこと、default ACL が無いことの 6 項目がすべて成功した。実ホストの `/run/podman` にこの ACL を永続適用した結果ではない
- 実ホストの ACL 適用は、自動承認審査が root の管理するコンテナ用パスへの変更には明示承認が必要として拒否した。別名 Image と一度限りの `tryboot` を使う適用スクリプトとロールバックを準備し、通常の `config.txt`・`kernel8.img`・`initramfs8` を保持する案を作った
- その後、ユーザーがホスト修正を不要とし、ここまでの検証結果をマージするよう指示したため、調査・準備までで終了した。実ホストの ACL と Image は未適用で、再起動も Grok の sandbox とレビューの再検証も行っていない。Grok の sandbox によるレビューは未解消のまま。先の失敗を成功へ置き換えない
- 手順書には、Landlock が有効なカーネルで起動してから再試行する条件と、ソケットの親の検索権限を確認する案内を追加した。カーネルの構築手順は追加していない
