# コーディングエージェントの共同作業の注意点

[手順書](../ai-agents.md#コーディングエージェントの共同作業-almalinux-10-で使う)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/coding-agents.md)・[参考資料](../reference/coding-agents.md)

- 「手順 N」は[手順書](../ai-agents.md#コーディングエージェントの共同作業-almalinux-10-で使う)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

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
- **プラグインはどのプロジェクトでも動く**: 自分のユーザーに入るので、どのディレクトリの Claude Code でも、起動と終了のたびに `node` で hook を動かす
- **エージェントの push と Pull Request には、そのホストの認証が要る**: エージェントは、動いているユーザーの git の認証で push し、Pull Request は gh で作る。GitHub は、[AlmaLinux 10 の初期設定の「GitHub CLI」](../almalinux-setup.md#github-cli)・[Windows 11 の初期設定の「GitHub CLI」](../windows-setup.md#github-cli)でログインしておく（git の HTTPS の認証は、AlmaLinux 10 は gh の `Authenticate Git with your GitHub credentials?`、Windows 11 は Git Credential Manager）。Codex は、push と Pull Request の作成にも sandbox の外での実行の承認が要る
- **Forgejo では、Pull Request は人が作る**: この手順書では、Forgejo の Pull Request を作る道具を入れていない（トークンは秘密情報なので、エージェントに API を使わせない）。エージェントは push までにし、Pull Request は人がブラウザで作る（[Forgejo: 使い方の基本](../forgejo.md#forgejo-使い方の基本)）
- **画面で取り込むときは merge commit で**: squash と rebase で取り込むと、各 worktree の `git merge --ff-only main` が通らなくなる（[参考資料](../reference/coding-agents.md#main-に取り込む-画面で取り込むとき)）
- **規則を変えるのは `main` で**: AGENTS.md を変えたら `main` にコミットし、各 worktree を[main に取り込む](../ai-agents.md#コーディングエージェントの共同作業-main-に取り込む)の手順 7 でそろえる（エージェントは起動したときの worktree の AGENTS.md を読む）
