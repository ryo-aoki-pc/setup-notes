# AGENTS.md

このリポジトリで作業するコーディングエージェント（Claude Code・Codex・Grok Build・Antigravity CLI）への指示。Claude Code は CLAUDE.md の `@AGENTS.md` で、Codex・Grok Build・Antigravity CLI はこのファイルを直接読む。

利用者への回答・質問・報告は、常に日本語で書く（コードのコメントなどの言語は、このファイルのほかの決まりに従う）。

## このリポジトリは何か

実機で検証した構築・設定手順の記録（日本語）。正本は `docs/windows-setup.md`・`docs/almalinux-setup.md`・`docs/shell-terminal.md`・`docs/neovim.md`・`docs/virtual-machines.md`・`docs/samba.md`・`docs/gnome-remote.md`・`docs/containers.md`・`docs/tool-catalog.md` の 9 冊。手順書には操作・前提・成功条件と、操作を変える短い注意だけを書く。実施日・対象版・環境・結果・失敗の記録は `docs/verification/<手順書名>.md`、背景・採用理由・比較・参照資料は `docs/reference/<手順書名>.md`、注意点は `docs/extra/<手順書名>.md` に分ける。ロールバック（取り消し・全部消す）の手順は書かない。手順書の本体には、ふだん見る項（導入・設定・使い方・更新）を残す。どの項も単独で通せるようにする。検証記録は非公開の `ryo-aoki-pc/setup-notes-verification` の同じパスにある。検証していないことを「動く」と書かず、状態と検証範囲は検証記録で管理する。

ビルド・テストフレームワークは無い。ドキュメントとコミットメッセージは日本語で書く。

共通の bash 設定は、`docs/shell-terminal.md` の「共通の bash 設定」、Windows では同じ文書の「Git Bash と WezTerm の設定」で導入する。`~/.bashrc` への標準の追記は bash リポジトリで扱う。各ツールの実施手順では共通設定を前提にし、直接追記・削除のブロックは置かない。読み込みと確認のコマンドだけを書く。共通設定の変更時は bash の `docs/reference/readme.md` の「読むもの」の表も合わせる。ツールの導入・ソケットの有効化・`~/.inputrc`・別形式の設定ファイルは各手順書で扱う。

検証の状態と範囲（実施済みと扱わない範囲を含む）は、非公開側の各検証記録と、その要約の `docs/verification-status.md` にある。状態や検証範囲の記述を変える前に読む。

AI エージェントの手順と、職場で使わない手順は、Forgejo の非公開リポジトリ `setup-notes-private` にある。この公開リポジトリには、それらへのリンク・案内と、環境が分かる値（ホスト名・アドレス・機材）を書かない。

## 手順を集約する正本

- 既存・新規の Windows 11・AlmaLinux 10 の操作は、2冊のカテゴリの該当する用途の項へ集約する（骨格は writing-rules.md の「2 冊の骨格（カテゴリ別）」）
- 仮想マシン（AlmaLinux 10 の VirtualBox・VirtualBox の bootc ゲスト・kvm-container、Windows 11 の Hyper-V・VirtualBox・VMware Workstation Pro・Windows Sandbox）は両 OS とも `docs/virtual-machines.md` へ集約する。2冊には項を置かず、冒頭と `## 更新` のリードから案内する
- 大きな項のうち、GNOME のリモート操作（デスクトップ共有・ヘッドレスセッション・リモートログイン）は `docs/gnome-remote.md`、Neovim・Samba（クライアント・サーバー）は両 OS とも `docs/neovim.md`・`docs/samba.md` へ集約する。2冊には項を置かず、冒頭・カテゴリ・`## 更新` のリードから案内する
- シェルと端末（共通の bash 設定・シェルのツール・HackGen Console NF・WezTerm・Windows Terminal・Git Bash の設定・PowerShell 7 のプロファイル・PowerShell の開発の設定）は、両 OS とも `docs/shell-terminal.md` へ集約する。Homebrew・btop・gdu・Git for Windows・貼り付けの設定・SSH の項は2冊に残す。2冊には項を置かず、冒頭・カテゴリ・`## 更新` のリードから案内する
- コンテナ（Podman・podman-compose・podman-tui・lazydocker・Distrobox）は、AlmaLinux 10 の `docs/containers.md` へ集約する。almalinux-setup.md には項を置かず、冒頭と `## 更新` のリードから案内する
- 正本を増やす・減らすのは、利用者の決定があるときだけにする。以下の「正本」は、この 9 冊を指す
- 個別ツール・VM・リモート操作も対象。導入前、ホスト・ゲスト、Workstation・bootc の条件を明記する
- 設定・実装・開発用検査は各リポジトリに残す。導入の変更時は正本と元リポジトリの案内を合わせる
- 冒頭で対話・GUI・条件付き操作の全番号を列挙しない。各手順には成功条件・中断・分岐・停止・危険を短く残す
- 文書を移す・分ける・まとめるときは、移した経緯と、旧ファイル名・旧見出しとの対応を文書に書かない（経緯は git の履歴と Pull Request の本文に残す）。リンクを今の場所へ直す。中身が新しい場所への案内だけになったファイルは消す
- 残す検証記録の実施日・対象版・環境・出力・成功と失敗・未実施の範囲・記録したときの手順番号は書き換えない。再検証せずに検証範囲を広げない。記録の手順番号が今の手順と違い、本文を読むのに要るときだけ「記録の手順 | 今の手順」の表で結ぶ

## 文書を書く・直すとき

書き方の規則と文書ごとのメモは大きい（合わせて約 180 KB）ので、`docs/dev/` に分けてある（Codex が読む AGENTS.md は合計 32 KiB まで）。次のときに読む。

- 手順書・検証記録・参考資料・extra を書いたり直したりする前に、[docs/dev/writing-rules.md](docs/dev/writing-rules.md)（手順書の構造・手順の形・表現の規則）を読む
- ある文書やスクリプトを直す前に、[docs/dev/structure.md](docs/dev/structure.md) で、そのファイルの項（`` - `docs/<名前>.md` — `` などで始まる行と、その下の入れ子の行）を読む。検証の状態を変えるときは、非公開側の `docs/verification-status.md` の同じ文書の項も読む
- 文書を足したときは、`docs/dev/structure.md` の項も直す。状態（検証範囲）を変えたときは、非公開側の `docs/verification-status.md` の同じ文書の項も直す

検証記録を書く・直すときは、非公開の `ryo-aoki-pc/setup-notes-verification` を `gh repo clone ryo-aoki-pc/setup-notes-verification` で clone し、そちらへ Pull Request を作る。手順の変更で検証範囲が変わるときは、両リポジトリへ Pull Request を作る。`docs` リポジトリでは、隣の `setup-notes-verification/` にサブモジュールとして取り出せる。

### 手順の並び順と完了前の点検

- 手順書の本体（2 冊はすべての項）・更新・extra を含むすべての操作手順に、[writing-rules.md の「手順の形」](docs/dev/writing-rules.md#手順の形)を適用する
- コマンドのある手順は「1 行の説明 → コードブロック → 確認・分岐・注意の箇条書き」の順にする。箇条書きをコードブロックの前や、複数のコードブロックの間に置かない
- 削除などの実行前に読む必要がある警告は、対象の節のリードに置き、節・項の名前と手順番号を示す。順序を揃えるために警告を危険なコマンドの後ろへ移すだけの修正はしない
- 節のリードの箇条書きと、コマンドの無い GUI・スマートフォンなどの手順（「1 行の説明 → 箇条書き」）は、この順序違反として扱わない
- 完了報告・コミット・Pull Request の作成や更新の前に、変更した手順を説明から最後の箇条書きまで点検する。1 行だけの変更でも手順全体を確認し、順序違反があれば直してから進める
- レビューでも同じ点検を行い、違反を指摘する。完了報告と Pull Request の検証欄には、点検したファイルと結果を書く

## 共同作業の規則

このリポジトリでは、Claude Code・Codex・Grok Build・Antigravity CLI が同じ規則で作業する。分担は人が決める。

- 起動された worktree（作業ディレクトリ）の中だけでファイルを変える。ほかの worktree のファイルは変えない
- 今のブランチにだけコミットする。`main` にはコミットも push もしない
- 頼まれた範囲のファイルだけを変える。範囲の外を変えるときは、変える前に理由を書いて確かめる
- 終わったら、テストとリンターを通してから、目的ごとにコミットする。通らなければコミットせずに、結果を報告する
- コミットしたら、今のブランチを push し、`main` への Pull Request を作る（既にあれば足す）。今のブランチに `main` を取り込むのは、頼まれたときと、Pull Request が競合したときだけ
- `main` への取り込み（マージ）は、エージェントが行ってよい。テストとリンターが通り、Pull Request が競合していなければ、`gh pr merge --squash` で Pull Request を取り込む（手元の `main` にはコミットも push もしない）。利用者が取り込まないよう頼んだときは取り込まず、そのことを報告する。取り込んだブランチには、その後コミットも push もせず、次の作業は新しいブランチで始める
  - リモートのブランチ: 取り込んだ Pull Request のブランチは、GitHub が自動で消す（リポジトリの Automatically delete head branches）。取り込む前に `gh api 'repos/{owner}/{repo}' --jq .delete_branch_on_merge` で確かめ、`false` なら `gh api -X PATCH 'repos/{owner}/{repo}' -F delete_branch_on_merge=true` で有効にする（`{owner}/{repo}` は gh が今のリポジトリで埋めるので、そのまま打つ）。取り込んだ後もリモートに残った自分のブランチは、`git push origin --delete <ブランチ>` で消す
  - 手元のブランチ: 自分が作ったブランチは、Pull Request が取り込まれたこと（`gh pr view <番号> --json state` が `MERGED`）と、どの worktree でも使っていないこと（`git worktree list`）を確かめてから、`git branch -D <ブランチ>` で消す（squash で取り込むので `git branch -d` は通らない）。今いるブランチは、新しいブランチへ移ってから消す。ほかの担当のブランチは消さない
  - Claude Code の worktree とブランチ: セッションの worktree は、Pull Request が閉じるとアプリがセッションをアーカイブして消す（Claude Code の設定の Auto-archive sessions when their pull request closes を有効にしておく。消えることはアプリの設定の説明による。コミットしていない変更がある worktree は残る）。残った `claude/` のブランチは、ほかの担当のブランチを消さない決まりの例外とする。Claude Code は、ほかのセッションが作ったものも、Pull Request が取り込まれたこと（`gh pr list --head <ブランチ> --state merged` に出る）と、どの worktree でも使っていないこと（`git worktree list`）を確かめてから、手元は `git branch -D <ブランチ>`、リモートに残っていれば `git push origin --delete <ブランチ>` で消す
- 秘密情報（`.env`・鍵・トークン・パスワード）を読まない・書かない・出力しない
- レビューを頼まれたら、ファイルを変えずに、指摘を「重大度・場所（ファイル:行）・理由・直し方」で挙げる
- ほかの担当の変更は、`git diff main...agent/codex` のように git で読む（ほかの worktree へ移らない）

## 既定の分担

利用者が Claude Code に、分担を指定せずにファイルを変える作業を頼んだときは、Claude Code が取りまとめて次の 4 つで分担する。「共同作業の規則」の「分担は人が決める」で、人が分担を決めていないときの既定にする。利用者がほかのエージェントに直接頼んだときは、この節は使わず「共同作業の規則」に従う。

- Claude Code だけで行うもの: 利用者の質問への答え、ファイルを変えない調べもの、1 つのファイルの数行で振る舞いを変えない直し（誤字・リンク・値の直しなど）
- Claude Code: 計画・実機での確かめ・ほかの 3 つへの依頼・指摘の確かめ・統合・コミットと Pull Request・取り込み
- Codex: 実装と下書き。Claude Code が用意した別の clone か worktree の中だけで書く。この分担で頼まれたときは、「共同作業の規則」のコミット・push・Pull Request・取り込みを行わず、変更を残して報告する（Claude Code が確かめ、自分の worktree に移してからコミットする）
- Grok Build: 差分の読み取り専用のレビュー。ファイルを変えない（Windows 11 では、Claude Code は `--always-approve` を付けずに頼む）
- Antigravity CLI: 差分の読み取り専用のレビューと、その作業のための調べもの。ファイルを変えない（Claude Code は、入力を写した使い捨てのフォルダーで 1 回だけ実行し、`--dangerously-skip-permissions`・`--mode` を付けない）
- Claude Code から頼まれたエージェントは、上の自分の役割の範囲で作業する
- レビューの指摘は、実物で確かめてから採る。採らなかった指摘は、理由を付けて報告する
- 使えないエージェント（入っていない・ログインが切れた）は飛ばし、そのことを報告する
- 頼み方は、Forgejo の非公開リポジトリ `setup-notes-private` の `docs/ai-agents.md` の「コーディングエージェントの共同作業: Windows 11 で既定で分担する」と、`docs/reference/coding-agents.md` の「既定の分担」
