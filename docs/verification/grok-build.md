# Grok Build（xAI の公式 CLI）を AlmaLinux 10・Windows 11 に入れるの検証記録

[手順書](../grok-build.md)・[ロールバックと注意点](../extra/grok-build.md)・[参考資料](../reference/grok-build.md)

## 現在の検証状態（2026-10-10）

- Raspberry Pi 5 / AlmaLinux 10.2 / aarch64 の実機で、専用の一般ユーザー `<TEST_USER>` に公式インストーラーで導入し、Grok 1.0.49 → 1.0.50 の自動更新・更新停止・手動更新・再導入・新しいシェルと CLI の撤去を確認した（[今回の付録](#付録-raspberry-pi-5--aarch64-実機での検証2026-10-10)）。
- 既存ユーザー `<USER>` の Grok 1.0.50 と Codex 0.160.0 は更新せず、既存認証を利用する確認を分けて実施した。初回ログイン・ブラウザでの承認・デバイスコード認証の操作そのものを通した記録ではない。
- 検証後は専用ユーザーの CLI 状態・ユーザー・ホームを撤去し、OS の RPM 一覧が実施前と同じことを確認した。Windows 11 の実行、X Premium（Plus でない）での利用、認証済みユーザーのログアウトは今回も未確認。
- sandbox の追加調査では、Podman のソケット親ディレクトリの検索権限と、カーネルで Landlock が未有効であることを別々の原因として確認した。Landlock を有効にする Image のビルドと 7 項目の静的検査、検索権限だけを与える ACL の模擬試験は成功した。ユーザーの指示により実機への適用・再起動・再検証は行わず、調査と準備までで終了した。Grok の sandbox レビューの失敗は未解消（[対処の準備結果](#sandbox-の追加原因調査と対処の準備)）。
- 同日の再起動なしの追加検証では、実ホストの `/run/podman` に検索だけの ACL を約 2 分適用し、errno 13 の解消と、一覧・作成の拒否、元の状態への復元を確認した。起動時のシステムコールの追跡で、`read-only` は Podman のソケットの確認（`EACCES`）、`workspace` は `landlock_create_ruleset` の `ENOSYS` で止まることを特定した。Landlock が有効なカーネルでの起動は今回も行っておらず、sandbox が起動した状態は未確認のまま（[再起動なしの追加検証](#sandbox-の再起動なしの追加検証)）。

以下の「対象と検証環境」と 2026-10-09 の付録は過去の記録を保持したものです。その中の「実機・aarch64 未確認」は当時の状態を表します。

## 対象と検証環境

- **状態（2026-10-09 UTC）**: AlmaLinux 10.2 / x86_64 のコンテナで、ログインの前までを、手順書のコードブロックのまま本実行した。実機・VM ではない
  - 通したもの: 実施手順の手順 1〜3、手順 4（URL とコードを出して待つところまで）、手順 6（ログインしていないときの表示）、手順 7 のディレクトリの準備（`grok` の画面は起動していない）、更新の手順 2、ロールバックの手順 1〜4
  - 確かめたこと: インストーラーが置くもの、`~/.bashrc` のブロックと控え、`~/.local/bin` のリンク（Codex を先に入れたユーザーでは置かれ、入れていないユーザーでは置かれない）、2 回目のインストーラーの動き、`grok update` が `~/.bashrc` を変えないこと、ロールバックの後に Codex のリンクが残ること
  - 確かめたこと（追加の検証）: 1.0.49 から 1.0.50 への自動の更新（対話の画面の起動のとき）、`[cli] auto_update = false` で止まること、Homebrew の cask との違い（[付録](#付録-自動の更新とパッケージマネージャー2026-10-09)）
  - 確かめたこと: `grok --trust inspect` が、ログイン無しで、読み込む指示書（AGENTS.md・CLAUDE.md・CLAUDE.local.md・`~/.claude/CLAUDE.md`）を一覧すること
  - 確かめたこと: bash の 13 ブロックの `bash -n`（エラー 0）と ShellCheck 0.9.0（指摘は手順 7 の `cd ~/grok-sandbox` の SC2164 だけ。直前の `mkdir -p` で作るので、codex.md の手順 8 と同じ形のままにした）
  - 確かめたこと: Windows 11 の節の PowerShell の 12 ブロックの構文（Linux の PowerShell 7.6.6 の構文解析器でエラー 0。PSScriptAnalyzer 1.25.0 の 5.1 互換の検査で指摘 0）
  - **確認していないこと**: grok.com でのログインと、その後（手順 5 の承認、手順 6 のログイン済みの表示、手順 7 の画面・フォルダーの信頼・AI への依頼）。X Premium（Plus でない）での利用。aarch64。実機・VM
  - **確認していないこと**: Windows 11 での実行すべて（インストーラー、PATH、ログイン、更新と自動の更新、ロールバック）

| 項目 | 値 |
|---|---|
| 実施日 | 2026-10-09 UTC |
| 環境 | クラウドの Linux の Docker 29.8.2 の上の `almalinux:10`（AlmaLinux 10.2 (Lavender Lion)、x86_64、digest `sha256:838c2fafefb1a8a0d7f8cdbc3b0551c2a2b1eb0cd87aad6d62aecadb18311f1b`） |
| Grok Build | 1.0.50（`c58f321264ba`）、stable のチャンネル |
| インストーラー | `install.sh` の SHA-256 `7fd6fdc75d9418b2e58356726fcbf1ae849416f773925da07d0ccc7a60d3e791`、`install.ps1` の SHA-256 `c83dac29885215c79137e48cbc034d3d7c8c11afba3082ff1df0e0769aa902a4`（どちらも 2026-10-09 に取得） |
| ほかに入れたもの | git 2.52.0-1.el10、curl 8.12.1（イメージにあったもの）、Codex CLI 0.162.0（[codex.md](../codex.md) の手順 3 と同じインストーラー。`~/.local/bin` があるときの確認用） |
| 実行ユーザー | 新規の一般ユーザー（`/etc/skel` の `.bashrc`）。`SHELL=/bin/bash`、umask 0022 |
| PowerShell の検査 | Ubuntu 22.04 のコンテナの PowerShell 7.6.6、PSScriptAnalyzer 1.25.0 |

> [!NOTE]
> 出力の中の利用者名は `<USER>`、ログインの確認用のコードは `<CODE>` に置き換えた。ログイン情報・トークンは作っていない。

### 実施前の状態

- `grok`・`agent` のコマンドと `~/.grok` は無い
- `~/.bashrc` は `/etc/skel` のもの（`~/.local/bin` と `~/bin` を PATH の先頭に足す行がある）
- Codex を先に入れたユーザーでは、`~/.local/bin/codex`（`~/.codex/packages/standalone/current/bin/codex` へのリンク）がある

### 完了時点の状態

- 以下は読者が手順を終えたときの確認点。今回の検証でログイン・AI への依頼まで通したという意味ではない
- `grok --version` が新しい端末でも通り、`grok models` に `You are not authenticated.` が出ない
- `~/.bashrc` の末尾に `# >>> grok installer >>>` のブロックがある
- ロールバックの手順 1〜4 の後は、`grok`・`agent` のコマンドと `~/.grok` が無く、`~/.bashrc` は空行を除いて `~/.bashrc.bak.<数字>` と同じになる

## 付録: コンテナでの検証（2026-10-09）

### 検証環境にだけ加えた調整

- コンテナの中から外へ出るために、プロキシの環境変数と CA を渡した（`--network host`、CA は `update-ca-trust` で取り込んだ）
- `docker exec` は `SHELL` を設定しないので、`SHELL=/bin/bash` を渡した（インストーラーは `SHELL` で書くファイルを決め、空なら何も書かない）
- umask をログインのシェルと同じ 0022 にした（`docker exec` の既定は 0000 で、最初の 1 回だけはその値で動かした）
- ログインはしないので、手順 4 と、ブラウザの無いホストでログインするの手順 1 は、8〜10 秒で `timeout` で止めた

### 実施手順 / 手順 1〜3

- 手順 1: `/usr/bin/curl` だけが出て、`ls: cannot access '/home/<USER>/.grok': No such file or directory`
- 手順 2（Codex を先に入れたユーザー）:

  ```text
  Fetching latest stable version...
  Installing Grok 1.0.50 (linux-x86_64)...
    Downloading grok 1.0.50...
    Binary linked to /home/<USER>/.grok/bin/grok and /home/<USER>/.grok/bin/agent.
  Grok 1.0.50 installed to /home/<USER>/.grok/bin/grok
    Symlinked /home/<USER>/.local/bin/grok -> /home/<USER>/.grok/bin/grok
    Symlinked /home/<USER>/.local/bin/agent -> /home/<USER>/.grok/bin/agent
    Updated /home/<USER>/.grok/bin in PATH in /home/<USER>/.bashrc.

  Run 'grok' or 'agent' to get started!
  ```

- 手順 2（Codex を入れていないユーザー。`~/.local/bin` が無い）: `Symlinked …` の 2 行が無く、最後が `Restart your terminal, then run 'grok' or 'agent' to get started!` になった
- 置かれたもの: `~/.grok/{bin,completions,docs,downloads}` と `~/.grok/config.toml`（`[cli]`・`installer = "internal"`）。配布物は `~/.grok/downloads/grok-linux-x86_64`（183,493,408 バイト）、`bin/grok` と `bin/agent` は `../downloads/grok-linux-x86_64` へのリンク。文書は `~/.grok/docs/user-guide/` に 27 本
- `~/.bashrc` に足されたもの（元のファイルとの差分）:

  ```text
  
  # >>> grok installer >>>
  export PATH="$HOME/.grok/bin:$PATH"
  [[ -r "$HOME/.grok/completions/bash/grok.bash" ]] && source "$HOME/.grok/completions/bash/grok.bash"
  # <<< grok installer <<<
  ```

  - 元のファイルは `~/.bashrc.bak.<UNIX 時刻>` に控えられた
- 手順 3: `/home/<USER>/.grok/bin/grok` と `grok 1.0.50 (c58f321264ba)`。新しいログインのシェルでも同じ
- インストーラーの 2 回目（同じユーザーで再実行）: `~/.grok/bin` がすでに PATH にあるので `Symlinked …` は出ず、`~/.bashrc` のブロックは消して末尾に足し直された（差分は空行 1 つ）。控えは増えない

### 実施手順 / 手順 4・6、ブラウザの無いホストでログインする / 手順 1

- 手順 4（ブラウザの無いコンテナ）:

  ```text
  To sign in, open this URL in your browser:

    https://accounts.x.ai/oauth2/device?user_code=<CODE>

    (Could not open browser automatically — open the URL above manually.)

  Confirm this code in your browser:

    <CODE>

  Only continue with a code you requested. Don't share it with anyone.

  Waiting for authorization...
  ```

- ブラウザの無いホストでログインするの手順 1（`grok login --device-auth`）も、同じ表示で待った
- 手順 6（ログインしていない）: 終了コード 0

  ```text
  You are not authenticated.

  Default model: grok-4.6

  Available models:
    * grok-4.6 (default)
    - grok-4.5
  ```

- `grok logout`（ログインしていない）: `No cached session to log out of.`、終了コード 0
- `grok login --help`: `--oauth`（既定）と `--device-auth`（別名 `--device-code`）がある

### 実施手順 / 手順 7

- `mkdir`・`cd`・`git init` だけを流した。`grok` の画面はログインしていないので起動していない（フォルダーの信頼を聞く画面・`/quit` は、同梱の文書 01-getting-started・04-slash-commands による）

### 更新 / 手順 2

- `grok update --check`: `Grok Build - v1.0.50 (latest: 1.0.50) [stable]`、終了コード 0
- `grok update`: `Already up to date (1.0.50).`、`grok --version` は `grok 1.0.50 (c58f321264ba) [stable]`
- `grok update --force-reinstall`: `~/.grok/downloads/grok-1.0.50-linux-x86_64` を新しく取ってきてリンクを付け替え、前の `grok-linux-x86_64` も残った（2 つで約 350 MB）
- どれも `~/.bashrc` を変えなかった

### ロールバック / 手順 1〜4

- 手順 1: `No cached session to log out of.`
- 手順 2: `~/.local/bin/grok`・`agent` が消え、`~/.local/bin/codex` は残った。最後の `command -v grok agent` は何も出さず、終了コード 1
- 手順 3: 最後に `0`。`~/.bashrc` は、空行を除いて `~/.bashrc.bak.<数字>` と同じになった（末尾に空行が 1 つ残る）
- 手順 4: `ls: cannot access '/home/<USER>/.grok': No such file or directory`
- 新しいログインのシェルで、`grok`・`agent` は見つからず、`codex` は `~/.local/bin/codex` で見つかった

### grok inspect とフォルダーの信頼

- AGENTS.md と、`@AGENTS.md` の 1 行だけの CLAUDE.md を置いた使い捨てのリポジトリで確かめた（ログイン無し）
- `grok inspect`（信頼していない）: `Project trusted: no`、`Project Instructions (0)`
- `grok --trust inspect`: `Project trusted: yes`、`Project Instructions (2)` に `CLAUDE.md (project, ~2 tokens)` と `AGENTS.md (project, ~6 tokens)`。`~/.grok/trusted_folders.toml` に、そのディレクトリが `trusted = true` で書かれ、その後の `grok inspect` も `Project trusted: yes` になった
- CLAUDE.local.md と `~/.claude/CLAUDE.md` を足すと、`Project Instructions (4)` に `~/.claude/CLAUDE.md (global, …) [claude]` と `CLAUDE.local.md (project, …)` が加わった
- `--trust` は `grok --help` に載っていないが、`grok --trust inspect` の形で受け付けた（`grok inspect --trust` は `unexpected argument`）

### sandbox と bubblewrap

- `grok -p "x" --sandbox read-only --always-approve` は、bubblewrap が無いコンテナでは `Error: this sandbox could not enforce its deny list on Linux: bwrap exec failed: …` で起動しなかった（終了コード 1）
- bubblewrap 0.10.0（BaseOS）を入れた `--privileged` のコンテナでは、sandbox の準備を過ぎて、ログインしていないことのエラーで終わった
- AlmaLinux 10 の Flatpak と `gnome-desktop3` は bubblewrap を必要とする（`dnf repoquery --whatrequires bubblewrap`）。GNOME のデスクトップの PC には入っているはず

### Windows 11 の節: 構文の検査

- Windows 11 で使う・Windows 11 の更新・Windows 11 のロールバックの PowerShell の 12 ブロックを、PowerShell 7.6.6 の `[System.Management.Automation.Language.Parser]::ParseInput` で解析した（エラー 0）
- PSScriptAnalyzer 1.25.0 の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（プロファイル `win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework`）で指摘 0
- `install.ps1` は読んで確かめただけで、実行していない（置く場所・MinGit の SHA-256 の確認・ユーザーの PATH の先頭に足すこと・`$ErrorActionPreference = 'Stop'`・失敗のときの `exit 1`）
- Windows のロールバックの手順 3 は、[claude-code.md](../claude-code.md) の Windows 11 のロールバックの手順 3 と同じ書き方（その手順は Windows 11 の VM で通っている）だが、この手順書のブロックとしては Windows で流していない

## 付録: 自動の更新とパッケージマネージャー（2026-10-09）

利用者の依頼（パッケージマネージャーで入れられるならその手順にする。自動で最新になるなら公式の方法でよい）を受けて、公式のインストーラーで入れた Grok の自動の更新と、Homebrew の cask を比べた。

| 項目 | 値 |
|---|---|
| 環境 | 上の付録と同じ `almalinux:10`（別のコンテナ）。プロキシの環境変数と CA を渡した |
| 版 | Grok Build 1.0.49（古い版として `bash -s 1.0.49` で入れた）と 1.0.50（調査時の最新） |
| 公式のインストーラーの確認 | 新規の一般ユーザー（`/etc/skel` の `.bashrc`）。端末の代わりに `script` の PTY（150×40）で `grok` を 40 秒動かし、`timeout` で止めた。ログインはしていない |
| Homebrew の確認 | 別のコンテナの一般ユーザー。[共通の bash 設定](https://github.com/ryo-aoki-pc/bash)と Homebrew 7.0.9 |

### 自動の更新

| 試したこと | 結果 |
|---|---|
| 1.0.49 を入れた直後に `grok`（対話の画面）を起動 | 起動した後に `~/.grok/downloads/grok-1.0.50-linux-x86_64` が入り、`~/.grok/bin/grok`・`agent` のリンクが付け替わった。`grok --version` は `grok 1.0.50 (c58f321264ba) [stable]`。`~/.grok/version.json` に `"version": "1.0.50"` と `checked_at` が書かれた |
| 入れ直した 1.0.49 で、`grok --version` を 3 回・`grok models`・`grok -p`（ログインしていないので終了コード 1） | どれも上がらなかった |
| `checked_at` が 3 分前のまま `grok` を起動 | 確かめず、上がらなかった |
| `checked_at` を 2 日前にし、`[cli]` に `auto_update = false` を書いて起動 | 確かめず（`checked_at` も変わらず）、上がらなかった |
| `checked_at` を 2 日前にし、`auto_update` の行を消して起動 | 1.0.50 に上がり、`checked_at` が起動の時刻になった |
| 自動の更新の前後の `~/.bashrc` | 変更時刻が変わらなかった（書き換えていない） |
| 上がった後の `grok update`・`grok update --check` | `Already up to date (1.0.50).`・`Grok Build - v1.0.50 (latest: 1.0.50) [stable]` |

- ログインしていない画面は、すぐにログインの案内（`Waiting for approval...`）になり、更新の知らせは画面に出なかった
- 前の配布物（`grok-linux-x86_64`）は残り、2 つで約 350 MB になった
- 確認していないこと: ログイン後の画面での知らせ、`checked_at` から確かめるまでの間隔、Windows 11 での自動の更新

### Homebrew の cask

- `brew info --cask grok-build`: 1.0.50。`grok-1.0.50-linux-x86_64` を `grok` と `agent` の名前でリンクし、補完を作る
- `brew install --cask grok-build`: `/home/linuxbrew/.linuxbrew/bin/grok`・`agent` に入り、`~/.bashrc` は変わらなかった。`~/.grok` は、最初に `grok` を動かしたときにできた（`config.toml` に `[cli]` の行は無かった）
- `grok update --check`: `Grok Build - v1.0.50 (latest: 1.0.50) [stable]`。`grok update`: `Already up to date (1.0.50).`
- `grok update --force-reinstall`: `✓ grok v1.0.50 installed successfully!` と出て、Homebrew の外の `~/.grok/bin`・`~/.grok/downloads` に別の Grok が入った（`config.toml` に `installer = "internal"`）
- そのとき、Homebrew の Caskroom の配布物はハッシュも時刻も変わらず、PATH で先の Homebrew の `grok` が動き続けた
- `brew outdated --cask` と `brew upgrade --cask grok-build` は動いた（最新なので上げるものは無かった）
- `brew uninstall --cask grok-build` はリンクと補完を消し、`~/.grok` は残った。`--zap` も、`~/.grok` は空のときだけ消す
- Homebrew の formula の `grok` は `DRY and RAD for regular expressions and then some`（Grok Build ではない）

### ほかの配布

- WinGet の `xAI.GrokBuild` は 1.0.50（portable）。npm の `@xai-official/grok` は 1.0.50（`latest`）
- scoop の main と extras には無い

## 付録: Raspberry Pi 5 / aarch64 実機での検証（2026-10-10）

| 項目 | 値 |
|---|---|
| 環境 | Raspberry Pi 5、AlmaLinux 10.2 (Lavender Lion)、aarch64、kernel `6.12.96-20260724.v8.1.el10` |
| 対象 | setup-notes #117、取得時の commit `814b590` |
| 実行ユーザー | 新規の一般ユーザー `<TEST_USER>` を作り、そのログインシェルで実行。既存ユーザー `<USER>` の CLI・設定・認証と OS の RPM は変更対象にしていない |
| 版 | 公式インストーラーの最新 1.0.50（`c58f321264ba`）と、指定して導入した 1.0.49（`8e66fdf1fd8e`） |
| インストーラー | `https://x.ai/cli/install.sh` を取得して `bash` で実行。SHA-256 `7fd6fdc75d9418b2e58356726fcbf1ae849416f773925da07d0ccc7a60d3e791`（2026-10-10 取得） |
| 検証補助 | 実ユーザーの HOME を使い、HOME・CODEX_HOME の変更や既存認証のコピーはしていない。実際の対話 PTY を用い、ログインコマンド・認証承認の入力は行っていない |

### 導入・更新・再導入

| 確認 | 実測結果 |
|---|---|
| 最新版の導入 | `bash install.sh` が `Installing Grok 1.0.50 (linux-aarch64)` と成功を表示。終了コード 0 |
| 新しいシェル | `bash -lic` で自分のホームの Grok が見つかり、1.0.50 を表示。元の `.bashrc` に加えた無関係の確認用行も残った |
| 最新確認・手動更新 | `grok update --check` は `(latest: 1.0.50)`、`grok update` は `Already up to date (1.0.50).`。いずれも終了コード 0 |
| 強制再導入 | `grok update --force-reinstall` は終了コード 0。`downloads/grok-1.0.50-linux-aarch64` を置き、`bin/grok` と `bin/agent` を付け替えた |
| 古い版の導入 | `bash install.sh 1.0.49` は終了コード 0。版を 1.0.49 と確認 |
| 自動更新の停止 | この試験ユーザーの更新キャッシュを外し、`[cli] auto_update = false` で `grok` を PTY で 60 秒起動。起動後も 1.0.49、`version.json` は生成されなかった |
| 自動更新の有効化 | `auto_update = false` の行を外し、PTY で 90 秒起動。起動後は 1.0.50、`version.json` に `version = 1.0.50` と実際の確認時刻が入り、両リンクが版付き配布物へ切り替わった。キャッシュの最新版・確認時刻を手で書いていない |
| 更新中の `.bashrc` | 手動更新・強制再導入の前後と、自動更新の前後の `cmp` は終了コード 0。インストーラーの再実行による空行増加とは分けて確認した |
| 公式インストーラーの再実行 | 最新の 1.0.50 を再導入し、終了コード 0 と版を確認 |

初回の実行シェルでは `~/.local/bin` が PATH にあったため、インストーラーは `~/.local/bin/grok`・`agent` を作った。あらかじめ置いた使い捨ての `agent` リンクは上書きされた。既存リンクを保持する動作とは扱わず、検証後は控えに従って元の確認用リンクを復元した。

### CLI の撤去と認証の範囲

- 起動した CLI を終了し、今回の `.grok` 配下を指す `~/.local/bin` のリンク、`~/.grok/bin/{grok,agent}`、配布物・補完を撤去した。新しいログインシェルの `command -v grok` は終了コード 1。無関係の `.bashrc` の行を保持した。
- 初回の撤去補助では `rg` が試験ユーザーの PATH に無く、installer ブロックを消す条件が実行されなかった。`grep` に置き換え、ブロックが無いことの検査を足して再試験し、終了コード 0 でブロックの撤去・新しいシェルでの CLI 不在・無関係の行とリンクの保持を確認した。CLI が見つからない結果だけでブロック撤去まで成功と判断していない。
- CLI 撤去後は試験結果を調べるため `.grok` の設定・文書・ログ・キャッシュを一旦残した。その後、手順書の手順 4 に相当する `~/.grok` 全体の削除を専用ユーザーで実行し、不在・新しいシェルでの CLI 不在・無関係の確認用行とリンクの保持をすべて終了コード 0 で確認した。
- 最後に、今回作成した専用ユーザー・同名グループ・ホームを削除した。OS の `rpm -qa` をソートした一覧の SHA-256 は実施前後で一致。既存ユーザーの CLI・設定・認証を更新や削除の対象にしていない。
- 専用ユーザーは未認証で実行した。既存ユーザーの初回ログイン・ログアウトやブラウザでの承認を検証済みとはしていない。

### sandbox の追加原因調査と対処の準備

- 同じ実機の Grok 1.0.50 で、`runtime-socket deny path /run/podman/podman.sock` の `Permission denied (os error 13)` を追加調査した。`/run/podman` は root 所有の空ディレクトリで、権限は `0700`。API ソケットは存在せず、rootful の `podman.socket` と `podman.service` は inactive だった。親ディレクトリを検索できないため、ソケットの不存在を通常ユーザーから確認できなかった。
- 原因を切り分ける試験だけで親ディレクトリを一時的に `0711` にすると、errno 13 は解消した。続いて Grok の `read-only` は、必要なカーネルの保護を適用できないため起動を拒否した。試験後は親ディレクトリを元の `0700` に戻した。ソケット本体の権限は変更していない。
- 現行カーネル `6.12.96-20260724.v8.1.el10` の設定は `CONFIG_SECURITY_LANDLOCK` が未設定。Landlock ABI を問い合わせる syscall は `ENOSYS` で失敗した。bubblewrap 0.10.0 があることと、Landlock による制限が有効であることは分けて判定した。
- 現行と同じ 6.12.96 の公式 SRPM を取得し、digest と署名の検証が成功した。`CONFIG_SECURITY_LANDLOCK=y` だけを変更した Image のビルドが完了し、カーネルの release は `6.12.96-20260724.v8.1.el10` のまま。ビルドは 1245 秒、`Image.gz` は 9,597,976 bytes、SHA-256 は `1a4a44d11d4be66f3c3db82d0bc6e3b8fabe99e92adafde8c4d40c13de683b49`。
- ビルドとは別の検証器で、次の 7 項目がすべて成功した。

| 静的検査 | 結果 |
|---|---|
| 完了したビルド記録と Image の一致 | release と Image の SHA-256 が一致 |
| 設定の差分 | `CONFIG_SECURITY_LANDLOCK` の `n` → `y` だけ |
| カーネルの release | `kernel.release` と `UTS_RELEASE` が現行と同じ |
| 組み込みカーネルの公開シンボル | 11,289 件の集合・CRC・export 種別・namespace がすべて一致。追加・削除・変更は無い |
| vmlinux の形式 | AArch64 の ELF64、little endian |
| Landlock の syscall | `create_ruleset`・`add_rule`・`restrict_self` の 3 つが `T`（strong text）のシンボルとして存在 |
| Image.gz の形式 | gzip と AArch64 Image の header が有効で、展開後はビルドした Image と一致 |

- 公開シンボルの一致は静的な ABI 検査で、既存 modules のロードや実際の動作を保証する結果ではない。`CONFIG_IKCONFIG=m` の既存 `configs.ko` を再利用すると、`/proc/config.gz` は元の設定を表示する。`uname -r` も変わらないため、この Image を将来使う場合は、起動後に Landlock ABI の問い合わせと LSM の初期化を確かめる必要がある。別版の公式カーネルへ更新するときは、対処用 Image もその版から再構築して検証する必要がある。
- ACL は専用の模擬ディレクトリとソケットで検証した。指定したユーザー UID に、親ディレクトリへの検索権限 `--x` だけを access ACL で与えた。パスの解決は成功し、ディレクトリの一覧・書き込みと root 所有のソケットへの接続は拒否された。ソケットの `0660` は変わらず、default ACL も無い。これら 6 項目がすべて成功した。
- 実ホストの `/run/podman` への ACL の永続適用は、自動承認レビューが、root が管理するコンテナ用パスへの変更には明示的な承認が必要として拒否した。実ホストへは適用していない。模擬試験の成功を、実機の Grok の起動成功とは扱わない。
- 通常起動の設定・`kernel8.img`・`initramfs8` を保持し、別名の Image と 1 回限りの `tryboot` を使う適用・復旧スクリプトを準備した。ユーザーの指示により、今回の対処は実ホストに適用せず、調査と準備までで終了した。ACL の永続適用・Image の適用・再起動・レビューの再検証は実施していない。Landlock が有効なカーネルでの起動、sandbox の再試行、プロジェクトへの書き込み拒否と Grok のレビュー成功は未確認で、Grok の sandbox レビューの失敗は未解消のまま。

### sandbox の再起動なしの追加検証

- setup-notes #119 のマージ後（`cf8774d`）、同じ実機・同じ稼働カーネル・Grok 1.0.50 のまま、ユーザーの指示で再起動を伴わない範囲だけを確かめた（2026-10-10 05:35〜06:10 UTC）。Landlock を有効にした Image の適用と再起動、ACL の永続化は今回も行っていない。
- どの実行も `--no-auto-update` を付けた。sandbox の準備で終了コード 1 になり、モデルへの依頼まで進んでいない。
- SELinux は Enforcing で、起動以降の監査ログに Grok・bubblewrap に関する拒否は無かった（[共同作業の検証記録](coding-agents.md#selinux-の記録の訂正)）。
- 起動時のシステムコールを `strace -f` で追い、Landlock の 3 つのシステムコール・パスを調べるシステムコール・`execve` だけを記録した。

| プロファイル | `/run/podman` | `/run/docker.sock` | `/run/podman/podman.sock` | `landlock_create_ruleset` | 標準エラー |
|---|---|---|---|---|---|
| `read-only` | 元のまま（root 所有の `0700`） | `ENOENT` | `EACCES` | 呼ばれない | `could not resolve runtime-socket deny path /run/podman/podman.sock: Permission denied (os error 13)` |
| `workspace` | 元のまま | 調べない | 調べない | `ENOSYS`（6 回） | `could not apply the 'workspace' sandbox profile; see the warning above for the cause. Refusing to start with its protections missing.` |
| `read-only` | 検索の ACL を適用中 | `ENOENT` | `ENOENT` | `ENOSYS`（6 回） | `could not apply the 'read-only' sandbox profile; …`（上と同じ形） |
| `workspace` | 検索の ACL を適用中 | 調べない | 調べない | `ENOSYS`（6 回） | 適用前と同じ |

- `read-only` は、Docker と Podman の rootful のソケットを起動時に調べる。`/run/podman` を検索できないと、Landlock の適用より前に止まる。
- `workspace` は、この 2 つのソケットを調べない。先の付録で「`read-only` と同じ原因か断定しない」とした `workspace` の失敗は、errno 13 ではなく、Landlock が無いこと（`ENOSYS`）による。
- 検索の ACL を適用した後は、どちらのプロファイルも `/usr/bin/bwrap` の起動まで進み、その後の `landlock_create_ruleset` の `ENOSYS` で止まった。`landlock_add_rule` と `landlock_restrict_self` は 4 回の実行のどれでも呼ばれていない。
- エラーの文は `see the warning above` と案内するが、`workspace` の実行では、標準エラー・`--debug`・`RUST_LOG=warn`・`~/.grok/logs/unified.jsonl` のどこにもその警告は無かった。原因は上の追跡で確かめた。
- Landlock のエラーで起動を拒否した実行は、`~/.grok/` に空で mode `000` の `sandbox-blocked.<PID>` を 1 個ずつ残した（9 回の実行で 9 個）。errno 13 で止まった 3 回の実行は残さなかった。

### 検索の ACL の実ホストへの一時適用

- `acl` のパッケージはこのホストに入っていない。先の調査で取得していた公式の `acl-2.4.0-1.el10_2.aarch64.rpm` は `rpm -K` が `digests signatures OK`、展開済みの `getfacl`・`setfacl` の SHA-256 は RPM の記録と一致したので、このコマンドを使った。OS の RPM は増やしていない。
- 適用の前に、`/run/podman` が root 所有・`0700`・空で、拡張の ACL が無く、`podman.socket`・`podman.service` が inactive であることを確かめた。
- `setfacl -m u:<UID>:--x,m::--x /run/podman` を適用した。`getfacl` は `user:<UID>:--x`・`group::---`・`mask::--x`・`other::---` で、default ACL は無い。`stat` の mode は `0710`（`drwx--x---+`）と表示された（グループの欄は mask を表す）。
- 実ディレクトリに対して、`<USER>` で次を確かめた。ソケットは作っていない。

| 確認 | 結果 |
|---|---|
| `/run/podman/podman.sock` のパスの解決 | `ENOENT`（`EACCES` ではなくなった） |
| ディレクトリの一覧 | `EACCES` |
| ファイルの作成 | `EACCES` |
| ディレクトリの作成 | `EACCES` |
| ソケットへの接続 | `ENOENT`（ソケットが無い） |

- root から見て、ディレクトリは空のまま。ソケットがあるときの接続の拒否と、ソケットの mode が変わらないことは、実ホストでは確かめていない（先の模擬試験の範囲）。
- 適用していたのは約 2 分（06:02:09〜06:03:57 UTC）。`setfacl -b` で外した後、mode・ACL・一覧（mtime を含む）・2 つの unit の状態は適用前の控えと一致し、`read-only` の errno 13 も元どおり再現した。tmpfiles などでの永続化はしていない。

### 再起動なしの追加検証の片付けと残る未確認

- 片付け: `--trust` が `~/.grok/trusted_folders.toml` に足した試験用フォルダー 1 件と、今回の実行が残した `sandbox-blocked.<PID>` 9 個を消した（先の検証の 1 個は残した）。`config.toml` と `trusted_folders.toml` のハッシュ、版（1.0.50）、ログインの状態は実施前と同じ。
- 未確認のまま: Landlock が有効なカーネルでの起動、sandbox が起動した状態でのレビュー・プロジェクトへの書き込みの拒否・`workspace` でのコミット、検索の ACL の永続化。Grok の sandbox レビューの失敗は未解消のまま。
