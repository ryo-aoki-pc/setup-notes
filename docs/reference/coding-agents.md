# Claude Code・Codex・Grok Build を 1 つのプロジェクトで共同作業させる（AlmaLinux 10・Windows 11）の参考資料

[手順書](../coding-agents.md)・[検証記録](../verification/coding-agents.md)

## 方法のまとめ

3 つのコーディング用の CLI（Claude Code・Codex・Grok Build）を、1 つのプロジェクトで一緒に使う方法を目的ごとに比べた（2026-10-09 時点）。「この手順書」の列が「採った」のものを、手順書で手順にした。

| 目的 | 方法 | この手順書 | 要るもの・制約 |
|---|---|---|---|
| 3 つを同じ規則で動かす | AGENTS.md を 1 つ置き、CLAUDE.md に `@AGENTS.md` の 1 行を書く | 採った（実施手順 4〜6） | Codex と Grok は AGENTS.md を読む。Claude Code は、CLAUDE.md か CLAUDE.local.md があると AGENTS.md を自分では読まない |
| 3 つを同じ規則で動かす | CLI ごとに指示書を書く（CLAUDE.md・AGENTS.md・`.grok/rules/`） | 採らない | 同じ規則を 3 か所で直すことになる |
| 作業場所を分ける | エージェントごとに git の worktree とブランチを 1 つずつ作る | 採った（実施手順 7） | 素の git だけ。3 つの CLI と 2 つの OS で同じ形 |
| 作業場所を分ける | 各 CLI の worktree の機能（`claude -w`・`codex --worktree`・`grok -w`） | 採らない | 置き場所とブランチの名前がそれぞれ違う（[worktree の置き場所とブランチ](#worktree-の置き場所とブランチ)） |
| 作業場所を分ける | 1 つのディレクトリで順番に使う | 採らない | 同時に動かすと、同じファイルを書き合う |
| Claude Code から Codex・Grok を呼ぶ | 公式のプラグイン（OpenAI の codex-plugin-cc、xAI の grok-build-plugin-cc） | 採った（実施手順 9〜11） | Node.js 18.18 以上 |
| Claude Code から Codex・Grok を呼ぶ | Claude Code にシェルで `codex review`・`grok -p` を動かさせる | 代わりの方法として載せた（使い方の基本の表） | 依存は増えない。裏で動かして状況を見る機能は無い |
| Claude Code から Codex・Grok を呼ぶ | MCP で Codex を呼ぶ（`codex mcp-server`） | 使えない | Codex 0.154.0 で削除された |
| Claude Code から Codex・Grok を呼ぶ | PAL MCP Server（旧 Zen MCP Server） | 採らない | 2025-12 から更新が無い。Grok は API キー（従量課金）が要る |
| 役割を分けてレビューし合う | 書いたものとは別のモデルが、新しい会話でレビューし、人が指摘を選ぶ | 採った（分担して作業する・相互にレビューする・main に取り込む） | 3 つの契約の使用量を使う |
| スマートフォンから指示する | Claude Code の Remote Control（Claude のアプリ）で Claude に頼み、Claude がプラグインで Codex・Grok に頼む | 採った（スマートフォンから指示する） | claude.ai の Pro / Max / Team / Enterprise。PC を動かしたまま |
| スマートフォンから指示する | SSH のアプリから tmux に入り、3 つに直接頼む | 採った（AlmaLinux 10 だけ） | PC に SSH で入れること（LAN か VPN） |
| スマートフォンから指示する | Codex のリモート接続（ChatGPT のアプリ） | 採らない | ホストは macOS・Windows の ChatGPT のデスクトップアプリだけ（Linux は無い）。Codex CLI からは設定できない |
| スマートフォンから指示する | Grok Build に直接つなぐ | 無い | 1.0.50 にスマートフォンからつなぐ機能は無い（同梱の文書） |
| GitHub で分担する | GitHub の Agent HQ（Issue に Claude と Codex を割り当てる） | 採らない | Copilot の有料プラン。Grok はエージェントとしては無く、Copilot のモデルとしてだけ選べる |
| GitHub で分担する | Pull Request に `@codex review`、`anthropics/claude-code-action` | 採らない | GitHub の App・シークレットの設定。Grok の公式の Action は無い（`grok -p` を API キーで動かす例だけ） |
| 並べて動かす道具を使う | Zed の Parallel Agents（ACP） | 採らない | 3 つとも ACP のレジストリにある。エディタを Zed にすることになる |
| 並べて動かす道具を使う | Claude Squad（tmux と worktree） | 採らない | `grok` を動かせるかは書かれていない。tmux の 4 つのウィンドウで足りる |

## 選択した方針

- 規則は AGENTS.md 1 つにまとめ、3 つに同じものを読ませる。Claude Code には CLAUDE.md の `@AGENTS.md` で取り込ませる（どの版でも効き、2 回は読まれない）
- 作業場所は素の `git worktree` で分け、受け渡しはブランチへのコミットで行う。push は要らない（worktree はオブジェクトを共有するので、あるブランチのコミットはほかの worktree からすぐ見える）
- Claude Code を窓口にする。スマートフォンから入れる公式の仕組み（Remote Control）があるのは Claude Code だけで、Codex と Grok の公式のプラグインもある
- `main` への取り込み・push は人だけが行う（AGENTS.md の規則）。エージェントの変更は、テストと別のモデルのレビューを通してから入れる
- GitHub の機能には頼らない。setup-notes の手順は、自分の PC と自分のサーバー（[Forgejo](../forgejo.md) など）でも同じに使えることを優先した

### 実施手順 / 手順 4〜6: 各 CLI が読む指示書

| CLI（検証時の版） | 読む指示書 | 注意 |
|---|---|---|
| Claude Code（2.1.295） | CLAUDE.md・CLAUDE.local.md（作業ディレクトリと親のディレクトリ）、`~/.claude/CLAUDE.md`。AGENTS.md は、CLAUDE.md・CLAUDE.local.md が無いときだけ（2.1.277 から） | CLAUDE.md の `@AGENTS.md` で取り込める。`AGENTS.override.md` は読まない |
| Codex（0.162.0） | Git のルートから作業ディレクトリまで、階層ごとに `AGENTS.override.md` か `AGENTS.md` を 1 つ（`~/.codex/AGENTS.md` も）。合計 32 KiB まで | `AGENTS.override.md` があると、その階層の AGENTS.md は読まない |
| Grok Build（1.0.50） | リポジトリのルートから作業ディレクトリまでの AGENTS.md・AGENT.md・CLAUDE.md・CLAUDE.local.md を全部、`.grok/rules/*.md`・`.claude/rules/*.md`、`~/.claude/CLAUDE.md` | 信頼したフォルダーでだけ読む。CLAUDE.md の `@AGENTS.md` は取り込みとしては扱わず、そのまま読む（AGENTS.md は別に読むので、規則は 1 回届く） |

- skills を 3 つで共有するときは、置き場所が違う（Claude Code は `.claude/skills/`、Codex は `.agents/skills/`、Grok は 3 つとも読む）。この手順書では扱わない
- テストとリンターのコマンドは、AGENTS.md のほかの節に書いておく（規則の「テストとリンターを通してから」が、それを指す）

### worktree の置き場所とブランチ

- worktree はプロジェクトの隣（`<プロジェクト名>.worktrees/<名前>`）に置き、プロジェクトの中には置かない
  - Claude Code は親のディレクトリの CLAUDE.md も読むので、中に置くと、`main` のチェックアウトの CLAUDE.md も重ねて読む
  - Grok の信頼は、入れ子の別のチェックアウトには効かない
  - プロジェクトの検索やテストが、worktree の中のファイルまで拾わない
- 各 CLI の worktree の機能を使わない理由（置き場所とブランチの名前がそろわない）

  | CLI | 作り方 | 置き場所 | ブランチ |
  |---|---|---|---|
  | Claude Code | `claude -w <名前>`（2.1.49 から） | `.claude/worktrees/<名前>`（プロジェクトの中） | `worktree-<名前>` |
  | Codex | `codex --worktree`（0.154.0 から。0.156.0 から既定で有効） | 文書に書かれていない | — |
  | Grok Build | `grok -w <名前>` | `~/.grok/worktrees/<リポジトリ>/<名前>` | — |

- ブランチは `agent/claude`・`agent/codex`・`agent/grok` に固定した。分担のたびに作り直さず、[main に取り込む](../coding-agents.md#main-に取り込む)の手順 7 で `main` にそろえてから次の作業を始める

### main でないブランチを基準にするとき

- この手順書は、基準のブランチを `main` に固定して、コマンドに直接書いた（[git.md](../git.md) の `init.defaultBranch` が `main` のため）
- `master` などを基準にするなら、手順書のコマンドと AGENTS.md の規則の `main` を、すべてそのブランチの名前に読み替える
  - 実施手順の手順 3（`## main` の確かめ）・手順 7（`worktree add … main`）
  - 使い方の基本・相互にレビューするの `--base main`・`main...HEAD`
  - main に取り込むの `main..agent/…`・`git merge --ff-only main`
  - ロールバックの手順 2 の `main..agent/…`

### 実施手順 / 手順 9〜11: 公式のプラグイン

- **OpenAI の codex-plugin-cc**（`codex@openai-codex`、検証時は 1.0.6）
  - Codex の app server（`codex app-server`）を通して Codex を動かす。レビューは読むだけの sandbox、`rescue` は既定で書き込みのできる sandbox
  - `/codex:setup` は、Codex が見つからず npm があると、`npm install -g @openai/codex` を提案する（codex.md の standalone のインストーラーと二重になるので断る）
  - hooks: `SessionStart`・`SessionEnd`（どのセッションでも `node` を動かす）と、`Stop`（レビューの関門。`--enable-review-gate` で有効にしたときだけ）
- **xAI の grok-build-plugin-cc**（`grok-build@xai-grok-build`、検証時は 0.2.1）
  - 本物の `grok` を `grok -p` で動かす。レビューは、読むだけのエージェント（`explore`）を `--sandbox read-only --always-approve` で動かす（承認する人がいない非対話では、plan のモードが止まるため）。Linux ではこの sandbox に bubblewrap が要る
  - `/grok-build:check` のログインの判定は `grok models` の終了コードだけを見る。Grok Build 1.0.50 の `grok models` はログインしていなくても終了コード 0 なので、ready と出る（検証記録）
  - hooks: `SessionStart`・`SessionEnd`
- 2 つの `review` は `disable-model-invocation: true` で、Claude は自分からは呼ばない。`rescue`（`codex-rescue` のサブエージェント）と `delegate`（`grok-delegate` のサブエージェント）は、Claude が自分で呼べる
- Claude Code の Remote Control では、`/plugin` などの端末だけのコマンドはスマートフォンから動かない（公式の文書）。プラグインの `/codex:review` などがスマートフォンから動くかは書かれておらず、確かめていない
- MCP を使わない理由
  - Codex を MCP のサーバーにする `codex mcp-server` は 0.154.0 で削除された（公式の文書。0.162.0 の `codex --help` にも無い）
  - `claude mcp serve` は、Claude Code のツール（ファイルの読み書きなど）を出すだけで、Claude にレビューを頼む口にはならない

### 分担して作業する・相互にレビューする

- 並べて動かすときは、エージェントごとに触るファイルを分ける（同じファイルを触ると、取り込みのときに競合する。GitHub と Anthropic の文書の勧め）
- レビューは、書いたものとは別のモデルに、新しい会話で頼む（書いた会話のままだと、自分の書いたものに甘くなる。Claude Code の Best practices の Writer/Reviewer）
- Codex は、sandbox の中では `.git` に書けない（`git add` で `index.lock` が作れない）。worktree でも、ふつうのチェックアウトでも同じ（検証記録）。コミットは承認して sandbox の外で動かすか、人が行う
- Grok Build は既定で sandbox が無い。`--sandbox workspace` で絞ると、worktree の `.git` は `main` のチェックアウトの `.git/worktrees/` にあるので、コミットはできなくなるはず（確かめていない）
- 端末から頼む Grok のレビュー（`grok --trust -p … --sandbox read-only --always-approve`）は、プラグインと同じく、読むだけの sandbox を安全の境界にした。Linux では、この sandbox は Landlock と bubblewrap で張られ、bubblewrap が無いと Grok は起動しない（検証記録）。Windows には sandbox が無い（公式の文書は Linux と macOS だけ）ので、`--always-approve` を付けない

### スマートフォンから指示する

- Claude Code の Remote Control（公式の文書）
  - Pro / Max / Team / Enterprise のプランで使える（Team と Enterprise は管理者が有効にする）。API キーでは使えない
  - サーバーのモード（`claude remote-control`）の `--spawn same-dir` は、どのセッションも同じディレクトリで動く。`--spawn worktree` は、頼むたびに Claude Code の worktree（`.claude/worktrees/` の下）を作るので、この手順書の worktree の中に入れ子ができる。setup-notes の既存の手順（tmux の任意節・Windows のタスク）と同じ `same-dir` にした
  - Claude Code の確認と `AskUserQuestion` の問いは、答えるまでスマートフォンに出たまま残る
  - サーバーのモードは、ネットワークが約 10 分切れると終わる（tmux の中のシェルは残る）
  - 確認や完了をスマートフォンに知らせるには、Claude Code の `/config` で通知（Push when actions required など）を有効にする
- Codex のリモート接続は、ChatGPT のデスクトップアプリ（macOS・Windows）をホストにする。Linux はホストにできず、Codex CLI や IDE の拡張機能からは設定できない（公式の文書）。Codex CLI 0.162.0 には実験的な `codex remote-control` があるが、スマートフォンとのつなぎ方は公式の文書に無い
- Grok Build 1.0.50 の同梱の文書に、スマートフォンからつなぐ機能は無い（`cursor-worker` は Cursor のクラウドのエージェントにこの PC を貸す機能で、別のもの）

### GitHub で分担する（この手順書では使わない）

- GitHub の Agent HQ では、Issue の担当に Claude と Codex を割り当て、それぞれが下書きの Pull Request を作る（2026-02 から公開プレビュー。Copilot の Pro / Pro+ / Max / Business / Enterprise）。xAI のエージェントは無く、Grok は Copilot のモデルとしてだけ選べる
- Codex は、Pull Request のコメントの `@codex review` でレビューする（ChatGPT の Codex の GitHub の連携）。Claude は `anthropics/claude-code-action@v1` の Action で動かせる
- Grok には公式の GitHub の Action が無い。xAI の文書は、CI/CD で `grok -p "Review changes for bugs" --output-format json --yolo` を動かす例と、CI/CD のログインには `XAI_API_KEY`（API の従量課金）を使うことを載せている（同梱の文書 01-getting-started・02-authentication）

## 参照

- [Claude Code: Manage Claude's memory（AGENTS.md）](https://code.claude.com/docs/en/memory)
- [Claude Code: Remote Control](https://code.claude.com/docs/en/remote-control)
- [Claude Code: Git worktrees](https://code.claude.com/docs/en/worktrees)
- [Claude Code: Best practices](https://code.claude.com/docs/en/best-practices)
- [OpenAI: AGENTS.md（Codex）](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
- [OpenAI: Codex MCP server（削除の告知）](https://learn.chatgpt.com/docs/mcp-server)
- [OpenAI: Remote connections（Codex）](https://learn.chatgpt.com/docs/remote-connections)
- [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) — Codex の Claude Code 用プラグイン
- [xai-org/grok-build-plugin-cc](https://github.com/xai-org/grok-build-plugin-cc) — Grok Build の Claude Code 用プラグイン
- [xAI: Grok Build](https://docs.x.ai/build/overview) と、同梱の文書 `~/.grok/docs/user-guide/`（12-project-rules・14-headless-mode・18-sandbox）
- [AGENTS.md](https://agents.md/) — 形式と、読むツールの一覧（Linux Foundation の Agentic AI Foundation が管理）
- [GitHub: About third-party coding agents](https://docs.github.com/en/copilot/concepts/agents/about-third-party-coding-agents)
- [Zed: Parallel Agents](https://zed.dev/docs/ai/parallel-agents)・[Claude Squad](https://github.com/smtg-ai/claude-squad)・[PAL MCP Server](https://github.com/BeehiveInnovations/pal-mcp-server)
