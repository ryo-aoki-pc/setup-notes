# AGENTS.md

このリポジトリで作業するコーディングエージェント（Claude Code・Codex・Grok Build・Antigravity CLI）への指示。Claude Code は CLAUDE.md の `@AGENTS.md` で、Codex・Grok Build・Antigravity CLI はこのファイルを直接読む。

利用者への回答・質問・報告は、常に日本語で書く（コードのコメントなどの言語は、このファイルのほかの決まりに従う）。

## このリポジトリは何か

実機で検証した構築・設定手順の記録（日本語）。Windows・AlmaLinux の実施手順の正本は `docs/windows-setup.md`・`docs/almalinux-setup.md`、AI コーディングエージェントの実施手順の正本は両 OS とも `docs/ai-agents.md`、仮想マシンは両 OS とも `docs/virtual-machines.md`、Forgejo のサーバーは `docs/forgejo.md`、GNOME のリモート操作（AlmaLinux 10）は `docs/gnome-remote.md`、WireGuard・Neovim・Samba・Syncthing は両 OS とも `docs/wireguard.md`・`docs/neovim.md`・`docs/samba.md`・`docs/syncthing.md`、シェルと端末（共通の bash 設定・シェルのツール・HackGen Console NF・WezTerm・Windows Terminal・Git Bash の設定・PowerShell 7 のプロファイル）は両 OS とも `docs/shell-terminal.md` で、`scripts/` はその手順書を実行可能にしたもの。手順書には操作・前提・成功条件と、操作を変える短い注意だけを書く。実施日・対象版・環境・結果・失敗の記録は `docs/verification/<手順書名>.md`、背景・採用理由・比較・参照資料は `docs/reference/<手順書名>.md`、ロールバック（「全部消す」などを含む）と注意点は `docs/extra/<手順書名>.md` に分ける。手順書の本体には、ふだん見る項（導入・設定・使い方・更新）を残す。どの項も単独で通せるようにする。検証記録は非公開の `ryo-aoki-pc/setup-notes-verification` の同じパスにある。検証していないことを「動く」と書かず、状態と検証範囲は検証記録で管理する。

ビルド・テストフレームワークは無い。ドキュメントとコミットメッセージは日本語で書く。

共通の bash 設定は、`docs/shell-terminal.md` の「共通の bash 設定」、Windows では同じ文書の「Git Bash と WezTerm の設定」で導入する。`~/.bashrc` への標準の追記は bash リポジトリで扱う。各ツールの実施手順では共通設定を前提にし、直接追記・削除のブロックは置かない。読み込みと確認のコマンドだけを書く。共通設定の変更時は bash の `docs/reference/readme.md` の「読むもの」の表も合わせる。ツールの導入・ソケットの有効化・`~/.inputrc`・別形式の設定ファイルは各手順書で扱う。

検証範囲と、実施済みと扱わない範囲は、非公開側の各検証記録にある。`docs/dev/structure.md` の状態や検証範囲の記述を変える前に読む。

## よく使うコマンド

```bash
# シェルスクリプトの静的検査（導入は docs/almalinux-setup.md の「ShellCheck と shfmt」。最新の実測は非公開側の docs/verification/shellcheck.md）
bash -n scripts/wireguard/wg-vpn.sh
shellcheck -x scripts/wireguard/wg-vpn.sh

# wg-vpn.sh を変更せずに実行予定を見る（root 不要なサブコマンドもある）
sudo scripts/wireguard/wg-vpn.sh -e scripts/wireguard/site.env --dry-run apply A
scripts/wireguard/wg-vpn.sh --help

# 図の再生成（docs/diagrams/*.diag → *.svg）。nwdiag / seqdiag を直接呼ばない
sudo dnf install -y google-noto-sans-cjk-vf-fonts
python3 -m pip install --user nwdiag seqdiag
python3 scripts/render-diagrams.py          # 別フォントは WG_DIAG_FONT=... で指定

# GUI の動作を確かめる（docs/ai-agents.md の「Claude Code の GNOME 操作: AlmaLinux 10 で使う」を通したホストで。撮った PNG を開いて見る）
scripts/gnome-gui.py shot /tmp/gnome-gui.png
scripts/gnome-gui.py key Escape                 # セッションを始めた直後に開いているアクティビティ画面を閉じる
scripts/gnome-gui.py launch org.gnome.TextEditor
scripts/gnome-gui.py type 'hello'
scripts/gnome-gui.py click 70 15                # 座標は shot の PNG の画素
scripts/gnome-gui.py windows
```

GUI の動作を確かめるときは、[AI エージェントの手順書の「Claude Code の GNOME 操作: AlmaLinux 10 で使う」](docs/ai-agents.md#claude-code-の-gnome-操作-almalinux-10-で使う)（前提は [GNOME のリモート操作の「GNOME のヘッドレスセッション」](docs/gnome-remote.md#gnome-のヘッドレスセッション)の手順 1・2）で仮想モニターを付けたヘッドレスのセッションを `scripts/gnome-gui.py`（Mutter の ScreenCast / RemoteDesktop。GNOME Shell の unsafe mode は使わない）で撮って操作する。操作のたびに `shot` で確かめ、利用者に見せるときはその PNG を送る。アクティビティ画面が開いているときに `launch` した窓にはフォーカスが移らないので先に `key Escape`、画面が動くキーの後は `sleep 1` を挟む。キー配列に無い文字は打てない（日本語は IBus でローマ字を打つ形になるはずだが、確かめていない）。PATH の先頭が Homebrew だと `gsettings`・`gdbus`・`gio`・`python3` が Homebrew のものになるので、`/usr/bin/` を付ける（Homebrew の `gsettings` は GNOME の dconf に書かない）。実機の Raspberry Pi 5 はリモートログインだけで、ヘッドレスのセッションと仮想モニターのドロップインは無い。使うなら、利用者に確かめてから GNOME のリモート操作の「GNOME のヘッドレスセッション」の手順 1・2 と、AI エージェントの手順書の「Claude Code の GNOME 操作: AlmaLinux 10 で使う」の手順 1〜3 を通す（リモートログインのセッションにも仮想モニターが付く）。

`wg-vpn.sh` の本実行を実機の設定に触れずに試す方法は、非公開側の `docs/verification/wireguard.md` の「付録: スクリプトの検証」にある。`unshare -Urm` で uid 0 の user namespace を作り、`/etc/wireguard`・`/etc/sysctl.d`・`/etc/firewalld` に tmpfs を重ね、`firewall-cmd` / `systemctl` / `ip` などのスタブを `PATH` の先頭に置く。`wg genkey` / `wg pubkey` はカーネルモジュール無しで本物が使える。

## 手順を集約する正本

- 既存・新規の Windows 11・AlmaLinux 10 の操作は、2冊のカテゴリの該当する用途の項へ集約する（骨格は writing-rules.md の「2 冊の骨格（カテゴリ別）」）
- AI コーディングエージェント（導入・更新・共同作業・ブラウザ操作・Remote Control・GNOME 操作）は、両 OS とも `docs/ai-agents.md` へ集約する。2冊には AI エージェントの項・節を置かず、リードから案内する。AI エージェントの状態で分岐する手順だけは、その節の手順として残す（Remote Control のタスクは windows-setup.md、仮想モニターのドロップインは gnome-remote.md）
- 仮想マシン（AlmaLinux 10 の VirtualBox・VirtualBox の bootc ゲスト・kvm-container、Windows 11 の Hyper-V・VirtualBox・VMware Workstation Pro・Windows Sandbox）は両 OS とも `docs/virtual-machines.md`、Forgejo のサーバーは `docs/forgejo.md` へ集約する。2冊には項を置かず、冒頭と `## 更新` のリードから案内する
- 大きな項のうち、GNOME のリモート操作（デスクトップ共有・ヘッドレスセッション・リモートログイン）は `docs/gnome-remote.md`、WireGuard・Neovim・Samba（クライアント・サーバー）・Syncthing は両 OS とも `docs/wireguard.md`・`docs/neovim.md`・`docs/samba.md`・`docs/syncthing.md` へ集約する。2冊には項を置かず、冒頭・カテゴリ・`## 更新` のリードから案内する
- シェルと端末（共通の bash 設定・シェルのツール・HackGen Console NF・WezTerm・Windows Terminal・Git Bash の設定・PowerShell 7 のプロファイル）は、両 OS とも `docs/shell-terminal.md` へ集約する。Homebrew・btop・gdu・Git for Windows・貼り付けの設定・SSH の項は2冊に残す。2冊には項を置かず、冒頭・カテゴリ・`## 更新` のリードから案内する
- 正本を増やすのは、利用者の決定があるときだけにする。以下の「正本」は、この 11 冊を指す
- 個別ツール・VPN・VM・リモート操作も対象。導入前、ホスト・ゲスト、Workstation・bootc の条件を明記する
- 設定・実装・開発用検査は各リポジトリに残す。導入の変更時は正本と元リポジトリの案内を合わせる
- 冒頭で対話・GUI・条件付き操作の全番号を列挙しない。各手順には成功条件・中断・分岐・停止・危険を短く残す
- 文書を移す・分ける・まとめるときは、移した経緯と、旧ファイル名・旧見出しとの対応を文書に書かない（経緯は git の履歴と Pull Request の本文に残す）。リンクを今の場所へ直す。中身が新しい場所への案内だけになったファイルは消す
- 残す検証記録の実施日・対象版・環境・出力・成功と失敗・未実施の範囲・記録したときの手順番号は書き換えない。再検証せずに検証範囲を広げない。記録の手順番号が今の手順と違い、本文を読むのに要るときだけ「記録の手順 | 今の手順」の表で結ぶ

## 文書を書く・直すとき

書き方の規則と文書ごとのメモは大きい（合わせて約 245 KB）ので、`docs/dev/` に分けてある（Codex が読む AGENTS.md は合計 32 KiB まで）。次のときに読む。

- 手順書・検証記録・参考資料・extra を書いたり直したりする前に、[docs/dev/writing-rules.md](docs/dev/writing-rules.md)（手順書の構造・手順の形・表現の規則）を読む
- ある文書やスクリプトを直す前に、[docs/dev/structure.md](docs/dev/structure.md) で、そのファイルの項（`` - `docs/<名前>.md` — `` などで始まる行と、その下の入れ子の行）を読む
- 文書を足したときや、状態（検証範囲）を変えたときは、`docs/dev/structure.md` の項も直す

検証記録を書く・直すときは、非公開の `ryo-aoki-pc/setup-notes-verification` を `gh repo clone ryo-aoki-pc/setup-notes-verification` で clone し、そちらへ Pull Request を作る。手順の変更で検証範囲が変わるときは、両リポジトリへ Pull Request を作る。`docs` リポジトリでは、隣の `setup-notes-verification/` にサブモジュールとして取り出せる。

### 手順の並び順と完了前の点検

- 手順書の本体（2 冊はすべての項）・更新・extra のロールバックを含むすべての操作手順に、[writing-rules.md の「手順の形」](docs/dev/writing-rules.md#手順の形)を適用する
- コマンドのある手順は「1 行の説明 → コードブロック → 確認・分岐・注意の箇条書き」の順にする。箇条書きをコードブロックの前や、複数のコードブロックの間に置かない
- 削除などの実行前に読む必要がある警告は、対象の節のリードに置き、節・項の名前と手順番号を示す。順序を揃えるために警告を危険なコマンドの後ろへ移すだけの修正はしない
- 節のリードの箇条書きと、コマンドの無い GUI・スマートフォンなどの手順（「1 行の説明 → 箇条書き」）は、この順序違反として扱わない
- 完了報告・コミット・Pull Request の作成や更新の前に、変更した手順を説明から最後の箇条書きまで点検する。1 行だけの変更でも手順全体を確認し、順序違反があれば直してから進める
- レビューでも同じ点検を行い、違反を指摘する。完了報告と Pull Request の検証欄には、点検したファイルと結果を書く

## wg-vpn.sh の設計

- **入力は `site.env` 1 ファイル**。両拠点に同じファイルを置く。`select_site A|B` が `SITE_A_*` / `SITE_B_*` から `MY_*` / `PEER_*` を組み立てるので、以降の処理は拠点を意識しない。このホストの LAN 側 IP が `WG_x_LAN_IP` と一致しなければ何も変更せずに止まる
- **変更を伴うコマンドはすべて `run()` を通す**。`--dry-run` はこれで実現しているので、新しい副作用も必ず `run` 経由にする
- **各段階で検査してから変更する**。`validate_addresses` は Python の `ipaddress` で形式・重複・包含関係を検査する。入力や未知 peer の事前検査で止まれば設定は反映しないが、`apply` の後半で失敗すると、それ以前に行った設定変更は残りうる。すべての検査失敗で無変更になるとは案内しない
- `apply` は冪等。`clients.list` の登録簿から毎回 conf を組み立て直し、firewalld は存在確認してから追加し、最後は常に `systemctl restart`（reload では経路が変わらないため）
- `PrivateKey` は conf に直接書く。`PostUp` で読み込む方式は reload で鍵が消える

スクリプトの挙動を変えたら、[WireGuard の参考資料の「スクリプトの動作」](docs/reference/wireguard.md#スクリプトの動作)と `--help`（ファイル冒頭コメントを `usage()` がそのまま表示する）も合わせて直す。

## 共同作業の規則

このリポジトリでは、Claude Code・Codex・Grok Build・Antigravity CLI が同じ規則で作業する。分担は人が決める。

- 起動された worktree（作業ディレクトリ）の中だけでファイルを変える。ほかの worktree のファイルは変えない
- 今のブランチにだけコミットする。`main` にはコミットも push もしない
- 頼まれた範囲のファイルだけを変える。範囲の外を変えるときは、変える前に理由を書いて確かめる
- 終わったら、テストとリンターを通してから、目的ごとにコミットする。通らなければコミットせずに、結果を報告する
- コミットしたら、今のブランチを push し、`main` への Pull Request を作る（既にあれば足す）。今のブランチに `main` を取り込むのは、頼まれたときと、Pull Request が競合したときだけ
- `main` への取り込み（マージ）は、エージェントが行ってよい。テストとリンターが通り、Pull Request が競合していなければ、`gh pr merge --squash` で Pull Request を取り込む（手元の `main` にはコミットも push もしない）。利用者が取り込まないよう頼んだときは取り込まず、そのことを報告する。取り込んだブランチには、その後コミットも push もせず、次の作業は新しいブランチで始める
  - リモートのブランチ: 取り込んだ Pull Request のブランチは、GitHub が自動で消す（リポジトリの Automatically delete head branches）。取り込む前に `gh api 'repos/{owner}/{repo}' --jq .delete_branch_on_merge` で確かめ、`false` なら `gh api -X PATCH 'repos/{owner}/{repo}' -F delete_branch_on_merge=true` で有効にする。取り込んだ後もリモートに残った自分のブランチは、`git push origin --delete <ブランチ>` で消す
  - 手元のブランチ: 自分が作ったブランチは、Pull Request が取り込まれたこと（`gh pr view <番号> --json state` が `MERGED`）と、どの worktree でも使っていないこと（`git worktree list`）を確かめてから、`git branch -D <ブランチ>` で消す（squash で取り込むので `git branch -d` は通らない）。今いるブランチは、新しいブランチへ移ってから消す。ほかの担当のブランチは消さない
  - Claude Code の worktree: セッションの worktree は、Pull Request が閉じるとアプリがセッションをアーカイブして消す（Claude Code の設定の Auto-archive sessions when their pull request closes を有効にしておく。コミットしていない変更がある worktree は残る）。worktree が消えた後に残った `claude/` のブランチは、ほかの担当のブランチを消さない決まりの例外で、Claude Code は、ほかのセッションが作ったものも、Pull Request が取り込まれたこと（`gh pr list --head <ブランチ> --state merged`）と、どの worktree でも使っていないことを確かめてから消す
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
- 頼み方は、[setup-notes](https://github.com/ryo-aoki-pc/setup-notes) の `docs/ai-agents.md` の「コーディングエージェントの共同作業: Windows 11 で既定で分担する」と、`docs/reference/coding-agents.md` の「既定の分担」
