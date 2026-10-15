# Claude Code・Codex・Grok Build を 1 つのプロジェクトで共同作業させる（AlmaLinux 10・Windows 11）の参考資料

[手順書](../ai-agents.md#コーディングエージェントの共同作業-実施手順)・[ロールバックと注意点](../extra/coding-agents.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/coding-agents.md)

## 補足

- **2026-10-10 の変更**: 実施手順の手順 9・10（Node.js・bubblewrap とプラグイン）は[AlmaLinux 10 の初期設定の「Codex・Grok のプラグイン」](../ai-agents.md#codexgrok-のプラグイン)の手順 1・2 に、Windows 11 で使うの手順 9〜11 は[Windows 11 の初期設定の「Codex・Grok のプラグイン」](../ai-agents.md#windows-11-で-codexgrok-のプラグインを入れる)の手順 1〜3 に、更新の手順 1・2 と Windows 11 の更新の手順 1・2 は、それぞれの初期設定の更新に、ロールバックの手順 5・6 と Windows 11 のロールバックの手順 5・6 は、それぞれの初期設定のロールバックの「AI エージェントとプラグインを消す」などに移した。今の実施手順の手順 9 は当時の手順 11、Windows 11 で使うの手順 9 は当時の手順 12、ロールバックの手順 5 は当時の手順 7。この文書の見出しと本文の「手順 N」は、当時の番号のまま

### 実施手順 / 手順 2: 補足: 版と並べる順

- 検証時の版は `2.1.295 (Claude Code)`・`codex-cli 0.162.0`・`grok 1.0.50 (…)`
- `claude auth status` は後ろに貼った行を読んで捨てるので、最後に置いてある

### 実施手順 / 手順 3: 補足: 指示書がすでにあるとき

- 指示書のファイルの名前が出たら、それがすでにある（同じ節の手順 4・5 は、そのファイルへの追記になる）

### 実施手順 / 手順 6: 補足: .gitignore で除いたファイル

- `.gitignore` で除いたファイルは、worktree に届かない

### 実施手順 / 手順 8: 補足: 確かめの問いと信頼

- Grok の確かめは AI には聞かないので、使用量は減らない
- `grok --trust` は、この worktree を信頼したことを `~/.grok/trusted_folders.toml` に残す（Grok の画面で信頼するのと同じ）
- Claude と Codex への 2 つの問いは、それぞれのプランの使用量を少し使う

### 実施手順 / 手順 9: 補足: Node.js と bubblewrap

- 検証時は AppStream の 22.23.2 と BaseOS の 0.10.0
- npm（`nodejs-npm`）も一緒に入る。この手順書では使わない
- bubblewrap は、Grok の読むだけの sandbox（`/grok-build:review` と、この手順書の端末からの Grok のレビュー）と Codex の sandbox が使う。無いと、Grok は `this sandbox could not enforce its deny list on Linux` と出して起動しない

### 相互にレビューする / 手順 2: 補足: grok --trust

- `grok --trust` は、この worktree も信頼したことを残す

### Windows 11 で使う / 手順 1: 補足: 変数

- 変数はその PowerShell の中だけで有効

### Windows 11 で使う / 手順 9: 補足: 版

- 検証時の scoop の定義は 24.21.0

### Windows 11 で使う / 手順 10: 補足: node の PATH

- Claude Code が起動するプラグインのスクリプトも、この PATH の `node` を使う

### Windows 11 で使う / 手順 12: 補足: プラグインのスクリプト

- プラグインのスクリプトは、Claude Code が Git Bash で動かす

### 既定で分担する / 手順 5: 補足: 読み込まれた指示の確かめ

- Claude Code と Codex の問いは、実装と下書きの担当が Codex かどうかで判定する。Antigravity には自分の役割を問い、Grok は `--trust inspect` で AGENTS.md の読み込みを確かめる
- この項の手順 5 は指示の読み込みの確認で、実際に 4 つで分担する流れの確認にはならない
- `grok --trust inspect` は worktree の信頼を記録する。3 つの AI への問いは、それぞれの契約の使用量を使う

## 方法のまとめ

3 つのコーディング用の CLI（Claude Code・Codex・Grok Build）を、1 つのプロジェクトで一緒に使う方法を目的ごとに比べた（2026-10-09 時点）。「この手順書」の列が「採った」のものを、手順書で手順にした。

2026-10-15 に Windows 11 へ足した Antigravity CLI の方針は、[Windows 11 の 4 つ目のエージェントと読み取り専用の境界](#windows-11-の-4-つ目のエージェントと読み取り専用の境界)に分ける。下の比較表は、従来の 3 つを対象にしたもの。

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
| エージェントの変更を人に渡す | エージェントが自分のブランチを push し、`main` への Pull Request を作る。取り込みは人 | 採った（2026-10-10 から。AGENTS.md の規則） | リモートと、push の認証・Pull Request を作る道具（GitHub は gh）。リモートが無ければ、ブランチへのコミットまで |
| エージェントの変更を人に渡す | push も Pull Request も人が行い、エージェントはブランチへのコミットまで | 採らない（2026-10-09 の初版の形） | 人の手間が増える。リモートの無いプロジェクトでは、今の形でも同じになる |
| 役割を分けてレビューし合う | 書いたものとは別のモデルが、新しい会話でレビューし、人が指摘を選ぶ | 採った（分担して作業する・相互にレビューする・main に取り込む） | 3 つの契約の使用量を使う |
| スマートフォンから指示する | Claude Code の Remote Control（Claude のアプリ）で Claude に頼み、Claude がプラグインで Codex・Grok に頼む | 採った（スマートフォンから指示する） | claude.ai の Pro / Max / Team / Enterprise。PC を動かしたまま |
| スマートフォンから指示する | SSH のアプリから tmux に入り、3 つに直接頼む | 採った（AlmaLinux 10 だけ） | PC に SSH で入れること（LAN か VPN） |
| スマートフォンから指示する | Codex のリモート接続（ChatGPT のアプリ） | 採らない | ホストは macOS・Windows の ChatGPT のデスクトップアプリだけ（Linux は無い）。Codex CLI からは設定できない |
| スマートフォンから指示する | Grok Build に直接つなぐ | この手順書では扱わない（[Grok Build をブラウザから操作する手順書](../ai-agents.md#grok-build-のブラウザ操作-実施手順)） | 1.0.50 にスマートフォンからつなぐ公式の機能は無い（同梱の文書）。ACP で Grok Build を動かす OSS の Codeg を同じホストに置けば、ブラウザから動かせる（2026-10-11 に手順書にした） |
| スマートフォンから指示する | Codeg のブラウザ画面から Claude Code・Codex CLI に直接頼む | OS 別の手順書で扱う（[AlmaLinux 10](../ai-agents.md#grok-build-のブラウザ操作-claude-code-と-codex-cli-も操作する)・[Windows 11](../ai-agents.md#grok-build-のブラウザ操作-windows-11-で-claude-code-と-codex-cli-も操作する)） | AlmaLinux 10 と Windows 11。使う CLI の導入とログイン、同じホストで動く Codeg が要る |
| GitHub で分担する | GitHub の Agent HQ（Issue に Claude と Codex を割り当てる） | 採らない | Copilot の有料プラン。Grok はエージェントとしては無く、Copilot のモデルとしてだけ選べる |
| GitHub で分担する | Pull Request に `@codex review`、`anthropics/claude-code-action` | 採らない | GitHub の App・シークレットの設定。Grok の公式の Action は無い（`grok -p` を API キーで動かす例だけ） |
| 並べて動かす道具を使う | Zed の Parallel Agents（ACP） | 採らない | 3 つとも ACP のレジストリにある。エディタを Zed にすることになる |
| 並べて動かす道具を使う | Claude Squad（tmux と worktree） | 採らない | `grok` を動かせるかは書かれていない。tmux の 4 つのウィンドウで足りる |

## 選択した方針

- 規則は AGENTS.md 1 つにまとめ、同じものを読ませる（AlmaLinux 10 は 3 つ、Windows 11 は Antigravity CLI を含む 4 つ）。Claude Code には CLAUDE.md の `@AGENTS.md` で取り込ませる（どの版でも効き、2 回は読まれない）
- 作業場所は素の `git worktree` で分け、worktree の間の受け渡しはブランチへのコミットで行う。そのための push は要らない（worktree はオブジェクトを共有するので、あるブランチのコミットはほかの worktree からすぐ見える）
- Claude Code を窓口にする。スマートフォンから入れる公式の仕組み（Remote Control）があるのは Claude Code だけで、Codex と Grok の公式のプラグインもある
- 変更を担当するエージェントは、自分のブランチの push と、`main` への Pull Request の作成まで行う（リモートがあるとき）。`main` への取り込み・`main` の push・ブランチの削除は人が行う（AGENTS.md の規則）。エージェントの変更は、テストと別のモデルのレビューを通してから入れる
  - 2026-10-10 に、利用者の決定で変えた。それまでは、push と Pull Request の作成も人が行っていた
  - Pull Request は、人がホスティングの画面で取り込んでも、[main に取り込む](../ai-agents.md#コーディングエージェントの共同作業-main-に取り込む)の手順で手元で取り込んでもよい
- GitHub の機能には頼らない。setup-notes の手順は、自分の PC と自分のサーバー（[Forgejo](../forgejo.md#forgejo) など）でも同じに使えることを優先した

### 既定の分担

- 2026-10-15 の利用者の決定で、分担を指定しないファイル変更の依頼も Claude Code が取りまとめる
  - 適用範囲は docs リポジトリとその 10 個のサブモジュールに絞り、11 個のリポジトリの AGENTS.md の末尾に同じ `## 既定の分担` を置く。ほかのプロジェクトへは自動で適用しない
- ほかのプロジェクトでも同じ既定を入れるための手順を、[既定で分担する](../ai-agents.md#コーディングエージェントの共同作業-既定で分担する)に残す。手順の対象は Windows 11。質問への答え・ファイルを変えない調べもの・1 つのファイルの数行で振る舞いを変えない直しは Claude Code だけで行う
- Claude Code は計画・実機での確認・依頼・指摘の確認・統合・コミットと Pull Request を担当し、Codex は別の clone か worktree で実装と下書きを担当する
  - Codex の Windows の sandbox では `git add`・`git commit` ができないので、Codex はコミットもステージもせず、Claude Code が確かめてからコミットする
- Windows 11 の Grok には sandbox が無いので、差分の読み取り専用のレビューを担当させる。`--always-approve` は付けず、入力を専用のフォルダーへ写し、その外を読ませず、前後のハッシュを比べる
  - 読み取り専用の依頼文とハッシュ比較は、書き込みを禁じる sandbox の代わりにはならない
- Antigravity CLI は Windows 11 だけで、読み取り専用のレビューと調べものを担当する。headless は作業フォルダーと `%TEMP%` に書けるため、入力のコピーを置いた使い捨てのフォルダーで 1 回だけ実行する
  - 境界とハッシュで分かる範囲は[読み取り専用の境界](#windows-11-の-4-つ目のエージェントと読み取り専用の境界)のとおり
- 過去のレビューでは、指摘の約 3 分の 1 が誤りか直し済みだった経験がある。指摘は実物で確かめてから採り、採らなかった指摘は理由とともに報告する
- エージェントが入っていない・ログインが切れた場合や AlmaLinux 10 の Antigravity CLI は飛ばし、そのことを報告する
  - AlmaLinux 10 は、Antigravity CLI を足さない従来の 3 つの構成のまま。AGENTS.md の節は両 OS で同じ文にし、AlmaLinux 10 での頼み方（Grok の sandbox を使うかなど）は実機で通すまで手順にしない
- Claude Code だけで行う直しを「1 つのファイルの数行で振る舞いを変えない直し」にしたのは、レビューだけで 10〜25 分かかり、誤字やリンクの直しまで 4 つで回すと待ち時間が見合わないため
- この分担で頼まれた Codex は、「共同作業の規則」のコミット・push・Pull Request を行わない。規則と既定の分担がぶつからないよう、節の中に書いた。利用者がほかのエージェントに直接頼んだときは、この節を使わない

Claude Code が 3 つに頼む形は次のとおり（Windows 11 の実機で使ったもの。2026-10-15 の codex-cli 0.162.1・Codex のプラグイン 1.0.6、grok 1.0.52、Antigravity CLI 1.3.5）。

| 頼む相手 | 頼み方 |
|---|---|
| Codex | Codex の worktree（`<WT_ROOT>\codex`）か別の clone に、頼む文の Markdown（「コミットしない・ステージしない」と書く）を置き、PowerShell から `node "$env:USERPROFILE\.claude\plugins\cache\openai-codex\codex\<版>\scripts\codex-companion.mjs" task --fresh --write --cwd <その場所> --prompt-file <頼む文.md>` を前景で実行する（10〜20 分）。`<版>` は、そのフォルダーの下にあるフォルダーの名前（`1.0.6` など） |
| Codex の変更を移す | `git -C <Codex の場所> diff --binary --output=<ファイル>` で書き出し、`git -C <WT_ROOT>\claude apply <ファイル>` で Claude の worktree に移し、確かめてから `agent/claude` にコミットする。移した後、Codex の場所の変更は消す |
| Codex の後片付け | 終わった後も `app-server-broker.mjs serve` の node のプロセスが、その場所を使ったまま残る。その worktree か clone を消す前に、コマンドラインにその場所を含むプロセスだけを止める（ほかの場所のものは、ほかのセッションのもの） |
| Grok Build | 差分・変えたファイル・規則・頼む文（BRIEF.md）を専用のフォルダーへ写し、`grok -p "このフォルダーの BRIEF.md を読み、その指示どおりにレビューしてください。ファイルは変えず、シェルのコマンドは使わず、このフォルダーの外は読まないでください。" --cwd <フォルダー> --permission-mode default --output-format plain` を実行する（10〜25 分）。前後のフォルダーのハッシュを比べる。Grok は信頼していないフォルダーでは AGENTS.md を読まないので、役割は頼む文に書く |
| Antigravity CLI | [Antigravity に読み取り専用で頼む](../ai-agents.md#コーディングエージェントの共同作業-antigravity-に読み取り専用で頼む)の手順を使い、使い捨てのフォルダーで `agy -p` を 1 回だけ実行し、`status`・`denied_actions`・前後のハッシュを確かめる |

### Windows 11 の 4 つ目のエージェントと読み取り専用の境界

- Windows 11 では、レビューと調べものを分担する 4 つ目のエージェントとして Antigravity CLI（`agy`）を足す。AlmaLinux 10 は、従来の 3 つの構成のままにする
- CLI は作業フォルダーの AGENTS.md を読むので、共同作業の規則をほかの 3 つと共有できる。Codeg の ACP サーバーでは同じ条件にならない（[Codeg の参考資料](grok-build-remote.md)）
- Windows のコマンドの sandbox は 1.2.17 からある（[公式の変更履歴](https://github.com/google-antigravity/antigravity-cli/blob/main/CHANGELOG.md)）。実測では、既定の `request-review` のまま `--sandbox` を付けても、headless ではコマンドが拒まれた
- 実測で、headless は作業フォルダーの中の書き込みと、作業フォルダーの外でも `%TEMP%` の下への書き込みを、確認なしで許した。作業フォルダーと `%TEMP%` の外の読み書きと、シェルのコマンドは拒まれた。作業フォルダーの外の `%TEMP%` を読めるかは測っていない
- 作業フォルダーを信頼していなくても書けるので、読み取り専用という依頼文だけでは書き込みを防げない
- [Antigravity に読み取り専用で頼む](../ai-agents.md#コーディングエージェントの共同作業-antigravity-に読み取り専用で頼む)では、次の 3 つを境界にする
  - 入力だけをコピーした使い捨てのフォルダーを作業フォルダーにする
  - headless の既定で、シェルのコマンドと、作業フォルダー・`%TEMP%` の外の読み書きが拒まれることを使う
  - 使い捨てのフォルダーの前後のハッシュを比べる。`%TEMP%` のほかの場所への書き込みは、この比較に出ない
- `--mode plan` は、[公式の文書](https://antigravity.google/docs/cli/modes)で「`/plan` の指示を前に付ける」モードとされ、書き込みを禁じるとは書かれていない（実測はしていない）。読み取り専用の境界には使わない
- `--dangerously-skip-permissions`・`--mode accept-edits`・`--mode auto` は使わない
- 拒まれても JSON の `status` は `SUCCESS`、終了コードは 0 になる。`denied_actions` と stderr の `jetski: no output produced` を見て、拒否と応答の有無を判断する

### Windows 11 で Claude Code から Antigravity を呼ぶ方法

- Claude Code からは、PowerShell で `agy -p` を直接呼ぶ。公式のブリッジのプラグインが無いため、この用途だけのプラグインは作らない
- Antigravity への依頼は読み取り専用のレビューと調べものに限り、入力のコピーと前後のハッシュの比較を含む手順を使う

### 実施手順 / 手順 4〜6: 各 CLI が読む指示書

| CLI（検証時の版） | 読む指示書 | 注意 |
|---|---|---|
| Claude Code（2.1.295） | CLAUDE.md・CLAUDE.local.md（作業ディレクトリと親のディレクトリ）、`~/.claude/CLAUDE.md`。AGENTS.md は、CLAUDE.md・CLAUDE.local.md が無いときだけ（2.1.277 から） | CLAUDE.md の `@AGENTS.md` で取り込める。`AGENTS.override.md` は読まない |
| Codex（0.162.0） | Git のルートから作業ディレクトリまで、階層ごとに `AGENTS.override.md` か `AGENTS.md` を 1 つ（`~/.codex/AGENTS.md` も）。合計 32 KiB まで | `AGENTS.override.md` があると、その階層の AGENTS.md は読まない |
| Grok Build（1.0.50） | リポジトリのルートから作業ディレクトリまでの AGENTS.md・AGENT.md・CLAUDE.md・CLAUDE.local.md を全部、`.grok/rules/*.md`・`.claude/rules/*.md`、`~/.claude/CLAUDE.md` | 信頼したフォルダーでだけ読む。CLAUDE.md の `@AGENTS.md` は取り込みとしては扱わず、そのまま読む（AGENTS.md は別に読むので、規則は 1 回届く） |
| Antigravity CLI（1.3.5、Windows 11） | 作業フォルダーの AGENTS.md・GEMINI.md | 使い捨てのリポジトリで両方を読むことを確認した。Codeg の ACP サーバーとは別に扱う |

- skills を 3 つで共有するときは、置き場所が違う（Claude Code は `.claude/skills/`、Codex は `.agents/skills/`、Grok は 3 つとも読む）。この手順書では扱わない
- テストとリンターのコマンドは、AGENTS.md のほかの節に書いておく（規則の「テストとリンターを通してから」が、それを指す）
- Grok Build は CLAUDE.md も読む。Claude Code だけに伝えたいことを CLAUDE.md に書くと、Grok にも伝わる

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

- ブランチは `agent/claude`・`agent/codex`・`agent/grok` に固定した
  - Windows 11 では、4 つ目の `antigravity` の worktree と `agent/antigravity` のブランチを足す
  - 分担のたびに作り直さず、[main に取り込む](../ai-agents.md#コーディングエージェントの共同作業-main-に取り込む)の手順 7 で `main` にそろえてから次の作業を始める

### main でないブランチを基準にするとき

- この手順書は、基準のブランチを `main` に固定して、コマンドに直接書いた（[AlmaLinux 10 の初期設定の「Git」](../almalinux-setup.md#git)の `init.defaultBranch` が `main` のため）
- `master` などを基準にするなら、手順書のコマンドと AGENTS.md の規則の `main` を、すべてそのブランチの名前に読み替える
  - 実施手順の手順 3（`## main` の確かめ）・手順 7（`worktree add … main`）
  - 使い方の基本・相互にレビューするの `--base main`・`main...HEAD`
  - main に取り込むの `main..agent/…`・`git merge --ff-only main`
  - ロールバックの手順 2 の `main..agent/…`

### 実施手順 / 手順 9〜11: 公式のプラグイン

- **OpenAI の codex-plugin-cc**（`codex@openai-codex`、検証時は 1.0.6）
  - Codex の app server（`codex app-server`）を通して Codex を動かす。レビューは読むだけの sandbox、`rescue` は既定で書き込みのできる sandbox
  - `/codex:setup` は、Codex が見つからず npm があると、`npm install -g @openai/codex` を提案する（初期設定の「Codex CLI」の standalone のインストーラーと二重になるので断る）
  - hooks: `SessionStart`・`SessionEnd`（どのセッションでも `node` を動かす）と、`Stop`（レビューの関門。`--enable-review-gate` で有効にしたときだけ）
- **xAI の grok-build-plugin-cc**（`grok-build@xai-grok-build`、検証時は 0.2.1）
  - 本物の `grok` を `grok -p` で動かす。レビューは、読むだけのエージェント（`explore`）を `--sandbox read-only --always-approve` で動かす（承認する人がいない非対話では、plan のモードが止まるため）。Linux ではこの sandbox に Landlock が有効なカーネルと bubblewrap が要る
  - `review` と `critique` は `runHeadlessAgent` に `sandbox: "read-only"` を渡す。`--always-approve` は確認を自動承認するだけで、sandbox の起動失敗は直さない
  - `runtime-socket deny path` のエラーは、sandbox の拒否パスを解決する段階の失敗。bubblewrap 不足とは別に判定する（[対象版と実機の結果](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/coding-agents.md)）
  - ソケットが無くても、親ディレクトリを検索できないと拒否パスを解決できない。親の検索権限とソケット自体のアクセス権は別で、後者を緩める必要はない。検索権限を直しても、Landlock が無効なカーネルでは read-only の保護が成立しない（[追加の原因調査](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/coding-agents.md#追加原因調査と対処の準備2026-10-10)）
  - `/grok-build:check` のログインの判定は `grok models` の終了コードだけを見る。Grok Build 1.0.50 の `grok models` はログインしていなくても終了コード 0 なので、ready と出る（検証記録）
  - hooks: `SessionStart`・`SessionEnd`
- 2 つのプラグインは自分のユーザーに入り、どのプロジェクトの Claude Code でも使える（`~/.claude/settings.json` の `enabledPlugins`。Windows 11 では `%USERPROFILE%\.claude\settings.json`）
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
- 端末から頼む Grok のレビュー（`grok --trust -p … --sandbox read-only --always-approve`）は、プラグインと同じく、読むだけの sandbox を安全の境界にした。Linux では、この sandbox は Landlock と bubblewrap で張られる。Landlock が無効なカーネル、bubblewrap 不足、拒否パスの解決失敗を分けて確認する（検証記録）。Windows には sandbox が無い（公式の文書は Linux と macOS だけ）ので、`--always-approve` を付けない

### main に取り込む: 画面で取り込むとき

- Pull Request を GitHub などの画面で取り込むときは、merge commit で取り込む
  - merge commit は、エージェントのブランチのコミットをそのまま `main` の祖先に入れる。[main に取り込む](../ai-agents.md#コーディングエージェントの共同作業-main-に取り込む)の手順 7 の `git merge --ff-only main` で、各 worktree が `main` に追いつける
  - squash と rebase は、同じ変更の新しいコミットを `main` に作る。エージェントのブランチのコミットは `main` に入らないので、`--ff-only` は `Not possible to fast-forward` で止まる（検証記録）
- 手元で取り込んで `main` を push したときは、Pull Request が開いたまま残ることがある。そのときは閉じる（ホスティングがマージ済みと見なすかどうかは、確かめていない）

### スマートフォンから指示する

- Claude Code の Remote Control（公式の文書）
  - Pro / Max / Team / Enterprise のプランで使える（Team と Enterprise は管理者が有効にする）。API キーでは使えない
  - サーバーのモード（`claude remote-control`）の `--spawn same-dir` は、どのセッションも同じディレクトリで動く。`--spawn worktree` は、頼むたびに Claude Code の worktree（`.claude/worktrees/` の下）を作るので、この手順書の worktree の中に入れ子ができる。setup-notes の既存の手順（tmux の任意節・Windows のタスク）と同じ `same-dir` にした
  - Claude Code の確認と `AskUserQuestion` の問いは、答えるまでスマートフォンに出たまま残る
  - サーバーのモードは、ネットワークが約 10 分切れると終わる（tmux の中のシェルは残る）
  - 確認や完了をスマートフォンに知らせるには、Claude Code の `/config` で通知（Push when actions required など）を有効にする
- Codex のリモート接続は、ChatGPT のデスクトップアプリ（macOS・Windows）をホストにする。Linux はホストにできず、Codex CLI や IDE の拡張機能からは設定できない（公式の文書）。Codex CLI 0.162.0 には実験的な `codex remote-control` があるが、スマートフォンとのつなぎ方は公式の文書に無い
- Grok Build 1.0.50 の同梱の文書に、スマートフォンからつなぐ機能は無い（`cursor-worker` は Cursor のクラウドのエージェントにこの PC を貸す機能で、別のもの）
- 公式の機能ではないが、Grok Build は ACP のエージェントとして動かせる（`grok agent stdio`）。これを使う OSS の Codeg で、ブラウザから Grok Build を動かす手順は [Grok Build をブラウザから操作する手順書](../ai-agents.md#grok-build-のブラウザ操作-実施手順)（2026-10-11）
- 同じ Codeg で Claude Code と Codex CLI も選ぶ手順は、OS 別の「Claude Code と Codex CLI も操作する」（[AlmaLinux 10](../ai-agents.md#grok-build-のブラウザ操作-claude-code-と-codex-cli-も操作する)・[Windows 11](../ai-agents.md#grok-build-のブラウザ操作-windows-11-で-claude-code-と-codex-cli-も操作する)、2026-10-12）。各エージェントの worktree を使い分け、CLI の導入とログインは初期設定の手順書で行う。検証範囲は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/grok-build-remote.md)を参照する

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
