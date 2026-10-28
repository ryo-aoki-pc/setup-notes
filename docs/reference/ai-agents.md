# AI コーディングエージェントのセットアップ（AlmaLinux 10・Windows 11）の参考資料

[手順書](../ai-agents.md)・[注意点](../extra/ai-agents.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md)

## 選択した方針

[AI コーディングエージェント](../ai-agents.md)は両 OS を 1 冊にし、`## AlmaLinux 10 で使う` が AlmaLinux 10、`## Windows 11 で使う` が Windows 11 の手順を扱う。AI エージェントの状態で分岐する手順は、[Windows 11 のセットアップ](../windows-setup.md)と[GNOME のリモート操作](../gnome-remote.md)で扱う。

### 長いコードブロックの折りたたみ

- ai-agents.md の長いコードブロックを `<details>` で包む。説明と確認の箇条書きが離れるのを避けるため
  - フェンスを除いて 20 行以上の 19 ブロック（bash 8、PowerShell 11）が対象
  - 20 行以上が全ブロックの上位 1 割ほどで、既存の唯一の前例（[WireGuard の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/wireguard.md)の 21 行）とも合うため、しきい値を 20 行にした
  - 変数のブロック、手で打つ `text` のブロック、1 行の説明に「（取り戻せない）」とある手順のブロックは折りたたまない
- タグは手順の本文と同じ 3 スペース字下げにし、`</summary>` の後と `</details>` の前後に空行を置く
  - 空行を崩すと GitHub がコードを地の文として出し、字下げを崩すと番号付きリストが切れることを、GitHub の Markdown API で確かめて決めた
  - `<summary>` は「貼るコマンド（PowerShell・50 行）」の形にし、言語とフェンスを除いた行数を示す
  - `<summary>` の行は 2 スペース深く（5 スペース）する。Neovim の Markdown の整形（[LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter) の `glfm_markdownlint`）が、埋め込んだ HTML をタグの入れ子に合わせて字下げするため、その結果に揃える
  - `<summary>` は `<details>` と同じ HTML のブロックの中の行なので、字下げを変えても GitHub の描画は変わらない（前後の描画を GitHub の Markdown API で比べた。[検証記録の付録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md#付録-summary-の字下げを変えたときの描画の比べ2026-10-15)）
- GitHub の Web での開閉とコードブロックは[公式の説明](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/organizing-information-with-collapsed-sections)を参照した
  - 描画の確認と、モバイルアプリなどの未確認範囲は[検証記録の付録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md#付録-構文描画と-web-の一次情報の確認2026-10-14)にある

### スクリーンショットと Windows 11 の Codeg

- 手順書には、操作する場所と成功条件を示すスクリーンショットを貼る
  - コマンドの無い手順の最後の箇条書き（「次の手順は、〜してから貼る」があれば、その直前）に 1 枚までとし、押す場所や成功の表示を示す
  - 本当のユーザー名・ホスト名・IP、入力済みの認証欄、証明書の画面は載せない
  - 撮影した環境と対象の版を節のリードに書き、画面内の値が試験用であることを断る
- Windows 11 の Codeg は、ランダムなトークンをブラウザへ入れずに、共通パスワードで使い始められるようにする
  - Codeg の標準の認証に、トークンと別のパスワード専用設定があるという意味ではない（[Grok Build の調査](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md#grok-build-の調査)）

### Codeg

- Codeg は、Grok Build・Claude Code・Codex CLI・Google Antigravity など、ACP に対応する複数のコーディングエージェントをブラウザやスマートフォンのチャットの画面から動かす OSS として扱う
- サーバーは使うエージェントと同じホストに置き、使うエージェントの項を選んで設定する（[Codeg の手順](../ai-agents.md#codeg)・[参考資料](codeg.md)）
- Raspberry Pi 5 の AlmaLinux 10 では、仮想アドレスが 39 ビットの arm64 のカーネルで Google Antigravity の ACP サーバーの 1.4.0 は使えない。起動時に TCMalloc で落ちた。推奨版がほかの版になったときの動作は確かめていない。端末の Antigravity CLI とは分けて扱う（[補足](codeg.md#codeg--almalinux-10-で-antigravity-を使う--手順-1-補足-仮想アドレスが-39-ビットの-arm64)）

### Windows 11 の Antigravity CLI

- Windows 11 では、Google 公式の [PowerShell のインストーラー](https://antigravity.google/cli/install.ps1)で Antigravity CLI（`agy`）を入れる
  - WinGet・npm には無いので、公式の配布物を公式のインストーラーで入れる形にした
- Gemini CLI は、2026-06-18 に個人アカウントへの提供を終え、Antigravity CLI が後継になった
- Windows 11 の [導入](../ai-agents.md#windows-11-で-antigravity-cli-を入れる)・[設定ファイル](../ai-agents.md#antigravity-cli-の設定ファイル)・更新を対象にする。AlmaLinux 10 でも使える（[AlmaLinux 10 の Antigravity CLI](#almalinux-10-の-antigravity-cli)）
- 更新はバックグラウンドの自動更新と `agy update` を使う。公式インストーラーは、既に入っていれば入れ直さず、自動更新を案内する
- Codeg の「Google Antigravity」は、CLI とは別の製品の ACP サーバーで、ログインも別になる。[Codeg の参考資料](codeg.md)で分けて扱う

### AlmaLinux 10 の Antigravity CLI

- AlmaLinux 10 でも [Antigravity CLI](../ai-agents.md#antigravity-cli)を使う
- Windows 11 と同じく、Google 公式の [シェルのインストーラー](https://antigravity.google/cli/install.sh)で入れる。更新は `agy update` を使う
  - インストーラーの案内では、バックグラウンドでも自分で上がる。AlmaLinux 10 では、新しい版が無いときの `agy update` を確かめた。2026-10-16 には、`agy` を何度か動かすうちに 1.3.5 から 1.4.0 に自分で上がった。新しい版への `agy update` は確かめていない
- インストーラーが `~/.bashrc` と `~/.bash_profile` に足す PATH の行は、入れた直後に外す（[理由](#almalinux-10-で使う--antigravity-cli--手順-4-補足-path-の行を外す理由)）
- AlmaLinux 10 の共同作業でも Antigravity CLI を 4 つ目にし、読み取り専用のレビューと調べものを頼む（[共同作業の参考資料の「AlmaLinux 10 の 4 つ目のエージェントと読み取り専用の境界」](coding-agents.md#almalinux-10-の-4-つ目のエージェントと読み取り専用の境界)）
- AlmaLinux 10 の CLI 1.3.5 の headless（`agy -p`）は、信頼したフォルダーでも作業フォルダーの中に書かず、`/tmp` の中には書いた。Windows 11 とは許す範囲が違う（[設定ファイル](../ai-agents.md#antigravity-cli-の設定ファイル)）
  - CLI 1.4.0 では、信頼していない作業フォルダーを `/tmp` の下に置くと中にも書けた。`~/.cache` の下では中への書き込みとシェルのコマンドは拒まれ、中の読み取りと AGENTS.md の読み込みは通った。拒まれると、その場で応答なしで終わった
  - Windows 11 の実測では、作業フォルダーが `%TEMP%` の下にあった。作業フォルダーの中に書けたのが、`%TEMP%` の下だったからかどうかは、分けて確かめていない

### Windows 11 の Antigravity アプリの Remote Control

- Windows 11 ではデスクトップアプリの [Remote Control](../ai-agents.md#windows-11-で-antigravity-アプリの-remote-control-を使う任意) を使う。Antigravity CLI は前提にしない
- 公式文書には、CLI の常駐デーモン（`agy remote-control start`）という別の方法もある。この PC では登録しておらず、使っていない
  - アプリは動いている間だけ接続できる。CLI のデーモンは、公式文書で説明されている常駐する別の入口
  - 共有の `%USERPROFILE%\.gemini\config\config.json` でも、アプリの名前は `userSettings.remoteControlHostname`、CLI のデーモンの名前は `cliRemoteControlHostname` と、別のキーを使う
- この PC ではアプリの導入後に自動起動が登録されなかったため、利用者の決定で、ログオン時の起動用にスタートアップのフォルダーへショートカットを置いた
  - ショートカットから手で起動できることは確かめた。サインアウト・再起動後の自動起動は確かめていない
- 窓を閉じても動かすため Keep In Menu Bar をオンにし、公式の説明に沿って Prevent Sleep もオンにする
  - Keep In Menu Bar がオンの状態では、窓を閉じた後も接続できた。Prevent Sleep が実際にスリープを防ぐことは確かめていない
- インストーラーを実行する前に、有効な署名と、署名者が Google LLC であることを確かめる。版を含む URL は固定し、新しい版の URL は公式のダウンロードのページで取り直す

## 補足

### AlmaLinux 10 で使う / Antigravity CLI / 手順 2: 補足: 公式インストーラーの動き

- インストーラーは、マニフェストにある URL から本体（アーキテクチャと libc で `linux_arm64` などを選ぶ）を取り、SHA-512 を照合して `~/.local/bin/agy` に置き、`agy install` を呼ぶ。sudo は使わない
- `agy install` は、`~/.bashrc` と `~/.bash_profile` の末尾に 4 行を足す。`~/.local/bin` が既に PATH にあっても、実行するたびに足す
  - 足すのは、空行 2 つ・`# Added by Antigravity CLI installer`・`export PATH="/home/<USER>/.local/bin:$PATH"`
- 一時ファイルは `~/.cache/antigravity/staging` に置き、終わると消す。空のフォルダーは残る
- インストーラーの中身では、`~/.local/bin/agy` があれば何もせずに `Notice: 'agy' is already installed at …` を出して終わる

### AlmaLinux 10 で使う / Antigravity CLI / 手順 3: 補足: 仮想アドレスが 39 ビットの arm64

- arm64 のカーネルには、ユーザーの仮想アドレスを 39 ビットにしたもの（`CONFIG_ARM64_VA_BITS=39`）がある。検証した Raspberry Pi 5 の AlmaLinux 10 のカーネルも、そうだった
- 1.0.4 より前の linux_arm64 版は、48 ビットを前提にした TCMalloc のため、そうしたカーネルで起動時に `MmapAligned() failed` で落ちたと報告されている（[issue #64](https://github.com/google-antigravity/antigravity-cli/issues/64)）
  - 開発者は、1.0.4 から linux_arm64 版は標準の malloc で作ると書いている。issue は 2026-10-15 の時点でまだ閉じていない
- 検証した PC では、1.3.5 が起動し、ログイン・応答・更新の確認まで動いた
- 落ちる版に当たったら、非公式のバイナリの書き換えはしない。消して、直った版を待つ

### AlmaLinux 10 で使う / Antigravity CLI / 手順 4: 補足: PATH の行を外す理由

- AlmaLinux 10 の既定の `~/.bashrc` は、`~/.local/bin` を PATH に足す。`~/.bash_profile` は `~/.bashrc` を読む。インストーラーが足した行は重なるだけなので外し、`~/.bashrc` を共通の設定の形のままにする
- 各ツールの手順には `~/.bashrc` を直接書き換えるブロックを置かない決まりなので、エディタで消し、消えたことだけを `grep` で確かめる形にした
- 足された 4 行を消すと、2 つのファイルは入れる前と同じになった。新しいログインシェルでも `agy` が見つかった
- 新しい版が無いときの `agy update` は、2 つのファイルを変えなかった。新しい版に上がるときに足すかは、確かめていない

### AlmaLinux 10 で使う / Antigravity CLI / 手順 6・8: 補足: 画面の文字と `/config` の既定

- 手順 6 の `You are currently not signed in.`・`Select login method:` と、手順 8 の `/config` の既定（`Tool Permission` が `request-review`、`Non-Workspace Access` が `off`）は、Windows 11 の同じ版で見たもの
- AlmaLinux 10 では、ログインと `/config` の確かめは利用者が端末で行い、Claude Code は画面を見ていない。`settings.json` には、信頼したフォルダーのほかに値が書かれなかった

### AlmaLinux 10 で使う / Antigravity CLI / 手順 7: 補足: ログインの保存先

- AlmaLinux 10 では、ログイン情報は `~/.gemini/antigravity-cli/antigravity-oauth-token`（権限 600）に保存された。GNOME のキーリングには入らなかった
- ログイン後の設定・ログ・会話・更新の情報などは `~/.gemini/antigravity-cli`、共通の設定は `~/.gemini/config` に作られる

### AlmaLinux 10 で使う / Claude Code のフックを入れる / 手順 1: 補足: NO_COLOR の引き継ぎと判定

- Claude Code の Bash・PowerShell ツールの環境には `NO_COLOR=1` がある。そこから開く端末の窓や TUI に引き継がれると、lazygit や delta の色が消える
- [フック本体](../../scripts/claude-code/no-color-guard.py)は、ツールの実行前（`PreToolUse`）にコマンドの文字列を調べる。Bash・PowerShell の両方に登録する
- 止めるのは、`wezterm-gui`、WezTerm の `start`・`cli spawn`・`connect`・`serial`、Windows Terminal の `wt`、`Start-Process` で開く新しいコンソール、lazygit、tmux の起動
  - `Start-Process` は、同じ文に `pwsh`・`powershell`・`cmd`・`conhost`・`bash`・`mintty`・`git-bash`・`wt` の名前があれば止める。引数の中の名前でも止まるが、止めすぎの側に倒している（理由を出して止めるだけで、`NO_COLOR` と書けば通る）
  - tmux は、`new-session`・`new`・`new-window`・`neww`・`split-window`・`splitw`・`respawn-pane` を対象にする。`-L`・`-f`・`-2` などの前置きの引数があっても止める
  - lazygit は、コマンドの先頭（`;`・`&`・`|` などの後ろを含む）で呼ぶときに止める。フルパスで呼ぶときも止める
- コマンドに `NO_COLOR` と書いてあれば通す。PowerShell の `$env:NO_COLOR = $null`、bash の `unset NO_COLOR`・`env -u NO_COLOR` で外す場合も、意図して無色のまま開く場合も通せる
- `ssh`・`wsl` のコマンドがある文字列も通す。通常、その先の環境にはツール側の `NO_COLOR` を引き継がない。WezTerm の `ssh` も同じ理由で通す
- WezTerm の `cli send-text`・`cli get-text`、版の表示、lazygit のヘルプや設定の表示は通す。Git のログやコミット文、`git log -- lazygit` のようなパスの引数、インストールのコマンドに lazygit の名前があるだけでも止めない
- シェルの構文は解析しない。コメントにある `tmux new-session` も判定するため、手順書では `echo check  # tmux new-session` を使い、端末や TUI を開かずに効き始めを確かめる
- 止めるときは、標準出力に `hookSpecificOutput.permissionDecision` が `deny` の JSON と日本語の理由を出し、終了コードは 0 にする
- [導入スクリプト](../../scripts/claude-code/setup-claude-code-hooks.py)は、`CLAUDE_CONFIG_DIR` があればそこ、無ければ `~/.claude` を使う
  - フック本体を `hooks/no-color-guard.py` に写し、`settings.json` に登録する
  - AlmaLinux 10 のフックの実行コマンドは `python3` を使う
- `--check` は、写した本体が同じ中身で、設定に今の形の項目が 1 つだけあることを確かめる。Claude Code が設定を読み直したことは、新しいセッションで別に確かめる
  - 2 本のフック（`no-color-guard.py` と `codex-reaper.py`）の両方を、同じように確かめる

### AlmaLinux 10 で使う / Claude Code のフックを入れる / 手順 4: 補足: 残った Codex の broker の片付け

- Codex のプラグイン（`codex@openai-codex`）は、使ったワークスペースごとに `app-server-broker.mjs serve` を detached で起動する。その下に `codex app-server` と、6〜16 個の sandbox のプロセスがぶら下がる
- 片付けはプラグインの `SessionEnd` のフックが行う。セッションが落ちたり、アプリでアーカイブしたりすると走らないので、broker が残る。2026-10-28 の Windows 11 の PC では、1 日で broker が 11 個、その下の `codex.exe` が約 100 個、`node`・`node_repl` が約 200 個残った
- [フック本体](../../scripts/claude-code/codex-reaper.py)は、セッションを始めるたび（`SessionStart`）に動く。次の 2 つを両方満たす broker だけを止める
  - 起動から 2 時間以上たっている（`--min-age-hours` で変えられる）
  - 同じワークスペースの `codex-companion.mjs` が動いていない。前景の `task` も、バックグラウンドの `task-worker` も数える。broker と companion の `--cwd` を `/` 区切りにそろえ（Windows では大文字と小文字も区別しない）、どちらかがもう片方と同じか、その下にあれば同じワークスペースとみなす
- broker の親プロセスが生きているかは見ない。detached で起動するので、使っている間でも親は終わっている
- 使っていない broker を止めても、次に Codex を呼んだときにプラグインが endpoint につながらないことを見て作り直す（プラグインの `lib/broker-lifecycle.mjs` の `ensureBrokerSession`）。そのため、2 時間は「作業の合間に止めて作り直させない」ための長さで、安全のための長さではない
- `--cwd` の無い broker や companion があるときは、どのワークスペースのものか分からないので止めない
- 止めたら、broker の `--pid-file` のディレクトリ（`cxc-` で始まるもの）の `broker.pid`・`broker.log` を消し、空になったディレクトリも消す。プラグインの `teardownBrokerSession` と同じ後始末
- Codex のデスクトップアプリ（ChatGPT.exe）とその下のプロセス、`codex-windows-sandbox-service.exe`、broker の外で動く `codex` は対象にしない。見るのは、コマンド ラインに `app-server-broker.mjs` と `serve` がある node だけ
- `SessionStart` のフックの標準出力は Claude の文脈に入るので、何も出さない。止めた broker は、設定のディレクトリの `hooks/codex-reaper.log` に 1 行ずつ書く（1 MiB を超えたら `codex-reaper.log.1` に回す）。失敗してもセッションの開始は止めず、終了コードは 0 にする
- 設定には `"async": true` で登録し、セッションの開始を待たせない（Windows ではプロセスの一覧に 2〜3 秒かかった）。`async` のフックには `timeout` が効かないので書かない
- AlmaLinux 10 では、`/proc` の `cmdline` と `stat` の開始時刻で一覧を作り、broker のプロセス グループに SIGTERM を送る（detached で起動した broker は自分のグループを持ち、`codex app-server` もそこに入る）。この経路は、WSL の AlmaLinux 10 で偽の broker（子を持つ `sh`）を止めて確かめただけで、実機の Codex の broker では流していない
- 止めたかどうかは、`taskkill` の終了コードではなく、broker の PID が残っていないかで決める。`taskkill /T` は、ツリーの一部が先に終わっていると全部止めても 0 以外を返した
- 手順 4 の `--dry-run` は、止める broker と残す broker を理由付きで出すだけで、何も変えない

### Windows 11 で使う / Windows 11 で Claude Code のフックを入れる / 手順 2: 補足: Python と Git Bash

- フックの目的と判定は、[AlmaLinux 10 の補足](#almalinux-10-で使う--claude-code-のフックを入れる--手順-1-補足-no_color-の引き継ぎと判定)と同じ。Windows でも `CLAUDE_CONFIG_DIR` があればそこ、無ければ `~/.claude` を使う
- Windows では、Claude Code はフックのコマンドを Git Bash で動かす。フックを導入する手順は Windows PowerShell 5.1 に貼り、登録されるコマンドには scoop の Python を呼ぶ `python` を使う
- スクリプトの場所は `/` 区切りのフルパスにし、空白があっても呼べるように二重引用符で囲む。`python "C:/Users/<WIN_USER>/.claude/hooks/no-color-guard.py"` の形になる
- シェルを通さない `args` の形は、この PC の Claude Code では効かなかったため使わない
- フックに渡される JSON は UTF-8。Windows の Python は標準入力のパイプを ANSI のコードページで読むため、`json.load(sys.stdin)` では日本語を含むコマンドで読み取りに失敗し、判定せずに通ってしまう
- フックは `sys.stdin.buffer` からバイト列を読み、UTF-8 として復号してから JSON を読む。止めた理由の JSON も、UTF-8 のバイト列で標準出力に書く

### Windows 11 で使う / Windows 11 で Claude Code のフックを入れる / 手順 5: 補足: プロセスの一覧と止め方

- Codex の片付けのフックの目的と判定は、[AlmaLinux 10 の補足](#almalinux-10-で使う--claude-code-のフックを入れる--手順-4-補足-残った-codex-の-broker-の片付け)と同じ
- Windows では、`powershell.exe -NoProfile` の `Get-CimInstance Win32_Process` で node のプロセスだけを取り、出力を UTF-8 の JSON にして読む。コマンド ラインに日本語のパスがあっても読める
- 止めるのは `taskkill /PID <PID> /T /F`。プラグイン自身の `terminateProcessTree` と同じで、broker の下の `cmd.exe`・`codex.exe app-server`・`node_repl.exe`・sandbox の `codex.exe` もまとめて止まる
- 子のプロセスは窓を開かない（`CREATE_NO_WINDOW`）

### Windows 11 で使う / Windows 11 で Antigravity CLI を入れる / 手順 2: 補足: 公式インストーラーの照合

- 公式インストーラーは、マニフェストにある URL から本体を取り、SHA-512 を照合して `%LOCALAPPDATA%\agy\bin\agy.exe` に置き、`agy.exe install` を呼ぶ
- ユーザーの PATH に `%LOCALAPPDATA%\agy\bin` を足す。既に開いている窓の PATH には反映されないため、[Windows 11 で Antigravity CLI を入れる](../ai-agents.md#windows-11-で-antigravity-cli-を入れる)の手順 4 で窓を開き直す

### Windows 11 で使う / Windows 11 で Antigravity CLI を入れる / 手順 3: 補足: staging の一時ファイル

- 今回、保存したインストーラーを scriptblock の形で実行したところ、`%LOCALAPPDATA%\antigravity\staging\agy.exe` が残った。本体と同じハッシュの一時ファイルだった
- 残る理由は、scriptblock で実行したとき、`finally` が見る `$stagingPayload` と、関数が書く `$script:stagingPayload` が別の変数になるためと推定した
- `irm | iex` の形では同じ変数になるはずだが、確認していない

### Windows 11 で使う / Windows 11 で Antigravity CLI を入れる / 手順 6: 補足: ログインの保存先

- 個人の Google アカウントでブラウザからログインする。CLI の資格情報は Windows の資格情報マネージャーの `gemini:antigravity` に保存される
- ログイン後の設定・ログ・会話・更新の情報などは `%USERPROFILE%\.gemini\antigravity-cli`、共通の設定は `%USERPROFILE%\.gemini\config` に作られる

### Antigravity アプリの Remote Control / Windows 11 で使う / 手順 2: 補足: 署名と版の確認

- ダウンロードの URL には版が入っている。新しい版へ変えるときは、公式のダウンロードのページから、その版の URL を取り直す
- 実行前に `Get-AuthenticodeSignature` の `Status` と `SignerCertificate.Subject` を見て、有効な Google LLC の署名を持つ配布物であることを確かめる。`VersionInfo` では製品名と版を確かめる

### Antigravity アプリの Remote Control / Windows 11 で使う / 手順 5: 補足: CLI とは別のログイン

- アプリの Google アカウントへのログインは、Antigravity CLI とは別になる。CLI にログイン済みでも、アプリでログインする
- アプリのログイン画面の細部と、ログイン情報の保存先は確かめていない

### Antigravity アプリの Remote Control / Windows 11 で使う / 手順 6: 補足: 設定画面と自動の名前

- 公式文書は設定の節を App と書くが、画面の名前は Application。PC のアプリの Remote Control の正確な項目名と Nickname の変え方は、Claude は画面で確かめていない
- 公式文書の Nickname を変えなかった場合、この PC では `<ホスト名>-<2 語>` の名前が自動で付いた。手順書では設定ファイルから名前を読み、ブラウザで接続先を選ぶときに使う
- Keep In Menu Bar は、すべての窓を閉じてもアプリを動かす設定。Prevent Sleep は、アプリが動いている間のスリープを防ぐ設定として説明されているが、実際に防ぐかは確かめていない

### Antigravity アプリの Remote Control / Windows 11 で使う / 手順 7: 補足: 設定の表示を絞る理由

- 設定ファイル全体には、ログインしたアカウントなども入る。手順書では Remote Control の有効・無効と名前、バックグラウンド動作とスリープ抑止の 4 つの値だけを表示する
- `%USERPROFILE%\.gemini\config\config.json` は CLI と共有する場所だが、アプリの Remote Control は `userSettings.remoteControlEnabled` と `remoteControlHostname` を使う

### Antigravity アプリの Remote Control / Windows 11 で使う / 手順 8: 補足: スタートアップのショートカット

- この PC では、アプリの導入後に HKCU の Run・スタートアップのフォルダー・タスク スケジューラのいずれにも自動起動が登録されなかった。利用者の決定でスタートアップのショートカットを使う
- ショートカットからの手動起動では窓が開く。ログオン後に自動で起動し、一覧が Online に戻ることまでは確かめていない

### Antigravity アプリの Remote Control / Windows 11 で使う / 手順 10: 補足: ブラウザとモバイル

- 公式文書では、ブラウザはアプリと同じ Google アカウントでサインインする。`Remote control is not enabled for your account.` は、アカウントや組織で機能が有効でないときの表示として説明されている
- モバイルでは Web アプリをホーム画面へ追加すると、エージェントの完了時と入力待ちにプッシュ通知を受け取れると公式文書にある。スマートフォンでのアクセス、ホーム画面への追加、プッシュ通知は実機で確かめていない

## 導入の参考資料

| 対象 | AlmaLinux 10 | Windows 11 |
| --- | --- | --- |
| Claude Code | [Claude Code](almalinux-setup.md#claude-code) | [Windows 11 で Claude Code を入れる](windows-setup.md#windows-11-で-claude-code-を入れる--手順-2-補足-確かめていることとgit-for-windows-の役割) |
| Codex CLI | [Codex CLI](almalinux-setup.md#codex-cli) | [Windows 11 で Codex CLI を入れる](windows-setup.md#windows-11-で-codex-cli-を入れる--手順-2-補足-置き場所と-powershell-の設定) |
| Grok Build | [Grok Build](almalinux-setup.md#grok-build) | [Windows 11 で Grok Build を入れる](windows-setup.md#windows-11-で-grok-build-を入れる--手順-2-補足-インストーラーの動き) |

## 参照

2026-10-14 の Grok Build の調査で参照した一次情報。調査結果は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md#grok-build-の調査)に記録する。

| 資料 | 参照した内容 |
| --- | --- |
| [Codeg v0.35.1](https://github.com/spacering-net/codeg/releases/tag/v0.35.1) | 公開日・配布物 |
| [Codeg Configuration](https://docs.codeg.app/getting-started/configuration) | `CODEG_*` の環境変数・トークンの設定 |
| [Codeg v0.35.1: src/app/login/page.tsx](https://github.com/spacering-net/codeg/blob/v0.35.1/src/app/login/page.tsx) | ログイン画面の保存先 `codeg_token` |
| [Codeg v0.35.1: src/lib/transport/web-auth.ts](https://github.com/spacering-net/codeg/blob/v0.35.1/src/lib/transport/web-auth.ts) | localStorage のキー `codeg_token` の読み書き |
| [Codeg v0.35.1: src-tauri/src/web/auth.rs](https://github.com/spacering-net/codeg/blob/v0.35.1/src-tauri/src/web/auth.rs) | 共有トークンの Bearer 照合 |
| [Codeg v0.35.1: src-tauri/src/acp/registry.rs](https://github.com/spacering-net/codeg/blob/v0.35.1/src-tauri/src/acp/registry.rs) | Claude Code・Codex CLI のアダプターの版 |
| [Caddy v2.11.7](https://github.com/caddyserver/caddy/releases/tag/v2.11.7) | 公開日 |
| [Caddyfile: Global options](https://caddyserver.com/docs/caddyfile/options) | HTTPS・信頼ストア・ローカル CA の設定 |
| [Caddyfile: tls](https://caddyserver.com/docs/caddyfile/directives/tls) | 内部 CA とオンデマンドの TLS |
| [GitHub: Organizing information with collapsed sections](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/organizing-information-with-collapsed-sections) | `<details>`・`<summary>` と内部のコードブロック |

AlmaLinux 10 の Antigravity CLI は、2026-10-15 に読んだ次の一次情報を参照した。実機で確かめた範囲は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md#付録-almalinux-10-の-antigravity-cli2026-10-15-jst)に記録する。

| 資料 | 参照した内容 |
| --- | --- |
| [install.sh](https://antigravity.google/cli/install.sh) | プラットフォームの選び方・マニフェスト・SHA-512 の照合・置き場所・`agy install` の呼び出し |
| [antigravity-cli#64](https://github.com/google-antigravity/antigravity-cli/issues/64) | 39 ビットの arm64 のカーネルで落ちる報告と、1.0.4 からの malloc の変更 |

Windows 11 の Antigravity アプリの Remote Control は、2026-10-15 に読んだ次の一次情報を参照した。実機で確かめた範囲は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md#付録-windows-11-の-antigravity-アプリの-remote-control2026-10-15-jst)に記録する。

| 資料 | 参照した内容 |
| --- | --- |
| [Antigravity: Remote Control](https://antigravity.google/docs/remote-control/) | アプリの設定・接続、CLI の別の入口、モバイルのホーム画面への追加とプッシュ通知 |
| [Antigravity: Download](https://antigravity.google/download) | Windows のアプリの配布物・要件、別製品の Antigravity IDE |
| [Remote Control for Antigravity（2026-08-21）](https://antigravity.google/blog/remote-control-for-antigravity/) | Remote Control の案内 |
| [Antigravity: Permissions](https://antigravity.google/docs/permissions) | Windows のアプリの権限、ターミナルのコマンドの承認、プロジェクトの中の読み書き |
