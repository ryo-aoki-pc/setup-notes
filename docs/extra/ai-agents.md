# AI コーディングエージェントのセットアップ（AlmaLinux 10・Windows 11）の注意点

[手順書](../ai-agents.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md)・[参考資料](../reference/ai-agents.md)

- 手順書の実施手順は項（###）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 任意の構成の注意点は、それぞれの文書にある: [コーディングエージェントの共同作業](coding-agents.md)・[Codeg](codeg.md)・[Claude Code の GNOME 操作](claude-code-gui.md)・[Claude Code の Remote Control](windows-claude-remote-control.md)

## 注意点

- **Claude Code の `Ctrl+B` は、tmux の中では 2 回押す**: `Ctrl+b` → `Ctrl+b` で中のアプリに `Ctrl+b` を送る
- **Remote Control の性質**（公式ドキュメント。[Windows 11 の Remote Control の注意点](windows-claude-remote-control.md#注意点)にも同じ内容）
  - このホストからは外向きの HTTPS だけで、受信のポートは開けない
  - つないでいる間、会話の転写（メッセージ・応答・ツールの動き）は Anthropic のサーバーに保存される
  - ネットワークが約 10 分切れると、`claude remote-control` は自分で終わる。tmux の中のシェルは残るので、[AlmaLinux 10 で Claude Code を tmux の中で動かす（任意）](../ai-agents.md#almalinux-10-で-claude-code-を-tmux-の中で動かす任意)の手順 8 で入り、その節の手順 4 のコマンドを打ち直す
  - 止めてから約 4 時間以内なら、`claude remote-control` で同じセッションが戻る
  - `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`・`DISABLE_GROWTHBOOK`・`ANTHROPIC_BASE_URL`（`api.anthropic.com` 以外）があると使えない
- **tmux でマウスを on にすると、Claude Code の画面でもホイールは tmux が受け取る**: コンテナの Claude Code（ログインしていない最初の画面）は、マウスの報告も代替画面も使っていなかった（`#{mouse_any_flag}` と `#{alternate_on}` が 0）。ホイールは tmux のコピーモードに入る
- **Claude Code: `latest` は不具合のある版もそのまま届く**: `stable` なら飛ばされる版も入る。困ったら [AlmaLinux 10 で Claude Code を stable チャンネルに切り替える（任意）](../ai-agents.md#almalinux-10-で-claude-code-を-stable-チャンネルに切り替える任意)
- **Claude Code: 自動更新しない**: ネイティブインストーラ版と違い、dnf 版は自分では更新しない
  - `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1` は Homebrew / WinGet 向けで、apt / dnf / apk は root 権限が要るため対象外
- **Claude Code: 更新の通知が先に来ることがある**: リポジトリに新しい版が届く前に「更新がある」と言われることがある。その場合は時間をおいて `sudo dnf upgrade claude-code`
- **Claude Code: `claude` が 2 つ入ると混乱する**: ネイティブインストーラや npm で入れたものが `~/.local/bin/claude` にあると、PATH の順序でそちらが勝つ。`command -v claude` と `claude doctor` で確認する
- **Claude Code: アカウントが要る**: 無料の claude.ai プランでは使えない
- **Claude Code: 設定ファイルは残る**: `dnf remove` しても `~/.claude` は消えない
- **Claude Code: `-p` は許可を聞けない**: 許可の要るツールは断られ、JSON の `permission_denials` に残る。要るものは `--allowedTools` で渡す（[Claude Code の使い方の基本](../ai-agents.md#claude-code-の使い方の基本)）
- **Claude Code: SSH を切ると止まる**: SSH のシェルで起動した `claude` は、切断で止まる。動かし続けるなら tmux の中で起動する（[AlmaLinux 10 で Claude Code を tmux の中で動かす（任意）](../ai-agents.md#almalinux-10-で-claude-code-を-tmux-の中で動かす任意)）
- **Grok Build: 非公式の grok-cli と名前がぶつかる**: npm の `grok-dev`（もとは `@vibe-kit/grok-cli`）も `grok` のコマンドと `~/.grok` を使う。両方は入れない
- **Grok Build: `agent` のコマンドも入る**: 中身は `grok` と同じ。インストーラーは、`~/.local/bin` に `agent` があっても `ln -sf` で置き換える（Cursor の CLI など、ほかの `agent` を使っているなら、入れた後に確かめる）
- **Grok Build: `XAI_API_KEY` を設定すると、ログインが無いときに API キーで動く**（API の従量課金になる）。サブスクリプションで使うなら設定しない
- **Grok Build: sandbox は既定で無効**: `--sandbox workspace`・`--sandbox read-only` などで、書ける場所を絞れる。Linux では Landlock が有効なカーネルと bubblewrap が要る（`sudo dnf install -y bubblewrap`。GNOME のデスクトップの PC には Flatpak と一緒に入っている）。Windows には sandbox が無い（公式の文書は Linux と macOS だけ）
  - `runtime-socket deny path` と `Permission denied (os error 13)` が出たら、ソケットの親ディレクトリの検索権限を確かめる。ソケット本体の権限を緩める必要は無い。このときの Grok のレビューは動いていないので、[コーディングエージェントの共同作業の「相互にレビューする」](../ai-agents.md#コーディングエージェントの共同作業-相互にレビューする)の代替へ進む
  - カーネルの保護を適用できないエラー（`could not apply the '<プロファイル>' sandbox profile`）が出たら、Landlock が有効なカーネルで OS を起動してから、同じ sandbox を再試行する。bubblewrap を入れただけで解決したとは扱わない（[起動できないときの補足](../reference/almalinux-setup.md#grok-build--手順-7-補足-linux-の-sandbox-を起動できないとき)）
- **Grok Build: Claude Code の指示書も読む**: AGENTS.md のほかに、CLAUDE.md・CLAUDE.local.md・`~/.claude/CLAUDE.md` も読む（読み込まれたものは `grok --trust inspect` の `Project Instructions`）。読むのは信頼したフォルダーだけ
- **Grok Build: 会話のデータの扱い**: 学習と保存に使うかは、Grok の中の `/privacy`（Coding data, retention, and training の Opt in / Opt out）で選ぶ（[参考資料](../reference/almalinux-setup.md#grok-build--手順-7-補足-会話のデータの扱い)）
- **Codex・Grok のプラグインはどのプロジェクトでも動く**: 自分のユーザーに入るので、どのディレクトリの Claude Code でも、起動と終了のたびに `node` で hook を動かす
- **Claude Code: `PATH` は自分で足す**: インストーラも `claude install` も足さない（[「Windows 11 で Claude Code を入れる」の手順 4](../ai-agents.md#windows-11-で-claude-code-を入れる)）。足さないと、開き直した PowerShell でも `claude` が見つからない
- **Claude Code: Windows PowerShell (x86) では入らない**: `Claude Code does not support 32-bit Windows` で止まる。x86 の付かない「Windows PowerShell」で入れ直す
- **Claude Code: `claude` が 2 つ入ると混乱する**: WinGet・npm・scoop で入れたものが `PATH` の先にあると、そちらが動く。`Get-Command claude -All` で確かめ、`winget uninstall Anthropic.ClaudeCode` や `npm uninstall -g @anthropic-ai/claude-code` で外す。古い Claude Desktop は `WindowsApps` に `Claude.exe` を置き、`claude` で Desktop が開くので、最新にする（公式の Troubleshoot installation）
- **Claude Code: 更新の後に `claude` が見つからないとき**: Windows の更新は、`claude.exe` を `claude.exe.old.<数字>` に名前を変えてから新しい版を置く。置けず、名前も戻せなかったときは `claude.exe` が無くなる。公式の文書は、一番新しい `claude.exe.old.*` の名前を戻す（`Get-ChildItem "$env:USERPROFILE\.local\bin\claude.exe.old.*" | Sort-Object Name | Select-Object -Last 1 | Rename-Item -NewName claude.exe`）か、入れ直すとしている
- **Claude Code: `The process cannot access the file` で止まるとき**: 前のインストーラが動いているか、ウイルス対策が `%USERPROFILE%\.claude\downloads` のファイルを調べている。ほかの PowerShell を閉じ、そのフォルダーを消してから入れ直す（公式の Troubleshoot installation）
- **Claude Code: `irm … | iex` で入れた PowerShell には、インストーラの設定が残る**: `Set-StrictMode -Version Latest` などが残るので、その窓は閉じて開き直す（[「Windows 11 で Claude Code を入れる」の手順 3](../ai-agents.md#windows-11-で-claude-code-を入れる)の補足）
- **Claude Code: ログインの情報は `%USERPROFILE%\.claude\.credentials.json`**: パスワードと同じ重みで扱い、ログや issue に貼らない
- **Claude Code: Windows PowerShell 5.1 のパイプ**: `<コマンド> | claude -p` で日本語を渡すと化けるはず（[Claude Code の使い方の基本](../ai-agents.md#claude-code-の使い方の基本)の非対話の注意）
- **Grok Build: Windows には sandbox（`--sandbox`）が無い**: 公式の文書の sandbox は Linux と macOS だけ（[この節の「Grok Build: sandbox は既定で無効」](#注意点)）
- **Antigravity CLI: `ERROR: logging before google.Init: I…` は情報の行**: `ERROR` で始まっても、後ろの `I` は情報の行を示す
- **Antigravity CLI: headless は操作を拒んでも終了コード 0**: JSON の `status` も `SUCCESS` になる。拒否は `denied_actions` と標準エラーの `jetski: no output produced` で見分ける
- **Antigravity CLI: AlmaLinux 10 の `agy install` は、実行するたびに PATH の行を足す**: インストーラーが初回に呼ぶほか、手で実行しても足す
  - `~/.local/bin` が既に PATH にあっても、`~/.bashrc` と `~/.bash_profile` の末尾に足す。何度も実行すると重なる
  - 足された行は、[Antigravity CLI](../ai-agents.md#antigravity-cli)の手順 4・5 で外す。`agy` が既にあれば、インストーラーは `agy install` を呼ばずに終わる
- **Codeg の Antigravity: サインイン中の「サインアウト」は資格情報も消す**: 待ち手を止め、保存済みの資格情報も消す
- **Antigravity アプリの Remote Control**
  - アプリが動いていないと使えない。Keep In Menu Bar がオンなら、窓を閉じても動く。タスクトレイから終了すると、ブラウザの一覧は `Offline` になる
  - スリープ・休止状態からの復帰、ノート PC の蓋を閉じたときの動き、Prevent Sleep が実際にスリープを防ぐことは未検証
  - スタートアップのショートカットは置いたが、サインアウト・再起動の後に自動で起動して `Online` になることは未検証
  - ブラウザ側の Settings → Application → General の Prevent Sleep と Keep In Menu Bar は、PC の値を映していないとみられる。ブラウザ側では変えない
  - Settings → Application の Remote Control は、ブラウザからは変えられない。PC のアプリで変更する
  - 同じ Google アカウントで入れる人は、ブラウザから PC のフォルダーを辿ってプロジェクトにできる。プロジェクトの中のファイルは確認なしで書き換わる
  - コマンドの承認で「常に許可」を選ぶと、その会話・プロジェクト・全体のうち選んだ範囲で許可が残り、以後は聞かれない
  - スマートフォンでのアクセス、ホーム画面への追加とプッシュ通知は未検証
  - アプリの更新と、更新の後の動きは未検証
  - CLI には別の方法として常駐デーモンがある（公式文書）。この PC では登録しておらず、使っていない
