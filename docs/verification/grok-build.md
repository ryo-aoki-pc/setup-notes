# Grok Build（xAI の公式 CLI）を AlmaLinux 10・Windows 11 に入れるの検証記録

[手順書](../grok-build.md)・[参考資料](../reference/grok-build.md)

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
