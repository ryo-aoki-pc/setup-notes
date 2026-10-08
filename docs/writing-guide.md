# 手順書の記法

[目的別の手順書一覧](README.md)・[リポジトリの入口](../README.md)

手順書を読むとき・編集するときの共通の約束。詳細な編集規則は [CLAUDE.md](../CLAUDE.md#手順書の構造)を参照する。

## 記法

- タイトル直後の `## 実施手順` に、変数設定、コマンド、動作確認を番号付きリストで並べる。任意操作・更新・ロールバックはその後ろの見出しに置き、中の手順も番号付きリストにする（節ごとに 1 から）
- 手順番号は見出しではなくリストで振る。マーカーはすべて `1.`（自動で採番される）で、変数があれば手順 1 が変数設定
- 各手順は「1 行の説明（太字にしない 1 文）→ コマンドのブロック → 確認点・分岐・注意の箇条書き」の順に書く。対話入力や完了待ちで止めるところで手順を分け、止める手順の最後に「次の手順は〜してから貼る」と書く
- コマンドの無い操作（GUI・ブラウザ・起動途中の画面・別のマシンや機器・ログインし直す）も、コマンドのブロックを置かない 1 つの手順にする。手順のコマンドが開いたエディタや TUI への入力は、その手順の箇条書きに書く
- `sudo` はパスワードを聞かない設定（NOPASSWD）を前提にしている（AlmaLinux 10 は [AlmaLinux 10 の初期設定の手順 3](almalinux-setup.md#実施手順) で設定する）
- `sudo` の後ろに別のコマンドが続くブロックは、全体を `{` と `}` の行で囲む。ブラケットペーストが効かないとき（bash の `enable-bracketed-paste` が off など）に貼ると、`sudo` が後ろの行を読んで捨てるため（[実測](verification/samba-client.md#付録-sudo-の後ろの行が失われる条件2026-09-28)）
- Windows で実行する手順（[Windows の OpenSSH サーバー](windows-openssh-server.md)・[Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)・[RDP をロックせずに切断（Windows）](windows-rdp-disconnect.md)・[Windows 11 の初期設定](windows-setup.md)・[Windows 11 のデュアルブート向けの導入](windows-dual-boot.md)・[SSH クライアント（Windows）](windows-ssh-client.md)と、Git・Samba クライアント・Syncthing・HackGen Console NF・WezTerm・Claude Code・Codex CLI・Firefox・VirtualBox・WireGuard Road Warrior・git-delta・GitHub CLI・Neovim・lazygit・yazi の Windows 11 の節。Neovim は任意節「既定のエディタにする」の手順 2・3 も）のブロックは `powershell` で、管理者の Windows PowerShell 5.1 に貼る
  - Remote Control は SSH でログインした昇格済みの PowerShell、RDP の切断は RDP のセッションの中の PowerShell
  - Windows 11 の初期設定は、Windows Update の手順 2〜8 と PC 全体の設定の手順 36〜55 が管理者。Store・scoop などは通常の窓。貼り付け設定前の手順 2〜15 は Ctrl+V で貼る。任意節は節のリードのとおり（Wake on LAN・リモートからの再起動・Edge の常駐は管理者。シェルのツールなど、ほかは通常の窓）
  - HackGen・Claude Code・Codex CLI は管理者でなくてよい（Codex の Windows sandbox の初回設定は管理者の承認が必要）。git-delta・GitHub CLI は scoop で自分のユーザーに入れるので、管理者ではない窓に貼る
  - SSH クライアント（Windows）と Samba クライアントの Windows 11 の節は、管理者ではない窓に貼る（Samba のドライブは、管理者の窓で割り当てるとエクスプローラーに出ない）
  - Neovim・lazygit・yazi は、管理者ではない窓に貼る（scoop は自分のユーザーに入れる。VC++ のランタイムが無いときだけ、WezTerm の手順書の Windows 11 の手順 3 を管理者の窓で）。Neovim の任意節「既定のエディタにする」の手順 2・3 も、管理者ではない窓に貼る
  - yazi の Windows 11 で使うの手順 8（`y` の確かめ）だけは、WezTerm の Git Bash のタブに貼る `bash` のブロック
  - デュアルブート向けの導入の diskpart は、セットアップのコマンド プロンプトに手で打つので、値を直接書いた `text` のブロックにしてある
  - `sudo` と `{ }` の規則はかからず、変数の空は `if … else` で弾く
  - [Git](git.md) の設定は、Windows でも Git for Windows の Git Bash に AlmaLinux 10 と同じ bash のブロックを貼る（Git for Windows を入れる節だけ PowerShell）
  - git-delta の git の設定と、Windows 11 の初期設定の任意節「シェルのツールを入れる」の確かめも、Git Bash で AlmaLinux 10 の手順を名指しする（PowerShell 向けに書き分けない）
- 環境固有値は冒頭の変数ブロック、または WireGuard の `site.env` で一度だけ設定する
- 変更が必須の変数は 1 変数ずつのコードブロック、変更が任意の変数は 1 つのブロックにまとめる
- 変える必要の無い値（固定の URL・パス・パッケージ名、ツールが既定の場所から読むパスなど）は変数にせず、コマンドに直接書く
- 実測・出力・検証した環境・失敗の記録は `docs/verification/<文書名>.md` に置く。理由・比較・背景・資料の参照は `docs/reference/<文書名>.md` に置く。手順書には操作に必要な前提・注意・成功条件を残す
- 実行の前提（実行するユーザー、前提の手順書、対話入力のある手順）は `## 実施手順` の冒頭に `> [!IMPORTANT]` で示す。検証範囲は対応する検証記録に記載する
- アラートは本文の最上位にだけ置く（GitHub は番号付きリストの中のアラートを描画しない）。手順の中の注意は太字の箇条書きにし、取り戻せない削除をする手順のある節では、そのリードに `> [!CAUTION]` を置いて手順を名指しする
- コマンドは実行済みのものを載せ、未検証事項は明記する
- 複数の手順書が共有する前提（Podman・linger・Secure Boot の MOK・ssh の SOCKS トンネルなど）は独立した手順書にし、各手順書の冒頭から参照する。インストール直後に通す前提（AlmaLinux 10 の Homebrew・EPEL・RPM Fusion・Flathub、Windows 11 の貼り付けの設定など）は、初期設定の手順書の手順を名指しする
- [導入元一覧](tool-catalog.md)は手順書ではないので、この骨格に従わない。表の各行に確認の深さ（起動 / 導入 / メタデータ）を書き、調査日と検証の範囲は[検証記録](verification/tool-catalog.md)に置く
- 図は `docs/diagrams/*.diag`（構成図は nwdiag、パケットの流れは seqdiag）を原本にし、`python3 scripts/render-diagrams.py` で `*.svg` を生成する。SVG は直接編集しない（前提は [WireGuard の付録](reference/wireguard.md#付録-構成図の再生成)）
- パスワード、秘密鍵、トークンなどの秘密情報は残さない
