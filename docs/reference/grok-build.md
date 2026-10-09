# Grok Build（xAI の公式 CLI）を AlmaLinux 10・Windows 11 に入れるの参考資料

[手順書](../grok-build.md)・[検証記録](../verification/grok-build.md)

## 選択した方針

- xAI の公式のインストーラー（`https://x.ai/cli/install.sh`・`install.ps1`）を使う
  - 公式の配布はほかに npm（`@xai-official/grok`）と WinGet（`xAI.GrokBuild`）がある
  - Node.js を増やさず、両 OS で同じ配布元・同じ `grok update` で上げられる形にした（WinGet で入れた Grok では、`grok update` は WinGet のコマンドを出すだけで何も変えない）
- ログインは grok.com のアカウント（ブラウザ）で行う
  - API キー（`XAI_API_KEY`）は、ログインが無いときだけ使われ、API の従量課金になる
  - 利用者の契約がサブスクリプション（SuperGrok / X Premium）なので、API キーの手順は置かない
- 非公式の grok-cli（superagent-ai の `grok-dev`）は採らない。同じ `grok` の名前と `~/.grok` を使い、2026-05 から更新が止まっている（調査時）
- 確認用のディレクトリでの起動は [codex.md](../codex.md) と同じ形にした（`~/grok-sandbox`）

### 実施手順 / 手順 1: 名前がぶつかるもの

- インストーラーは `~/.grok/bin` に `grok` と `agent` の 2 つのリンクを置く（中身は同じ）
- `~/.local/bin` が PATH にあって `~/.grok/bin` が無いときは、`~/.local/bin/grok`・`~/.local/bin/agent` にもリンクを置く。`ln -sf` なので、同じ名前のファイルがあっても置き換える
- Cursor の CLI も `agent` の名前を使う。両方を使うなら、PATH の順でどちらが動くかを確かめる

### 実施手順 / 手順 2: インストーラーが置くものと `~/.bashrc`

- 置くもの（AlmaLinux 10、1.0.50）
  - 配布物: `~/.grok/downloads/grok-linux-x86_64`（約 175 MB の実行ファイル 1 つ）
  - リンク: `~/.grok/bin/grok`・`~/.grok/bin/agent`（どちらも `../downloads/…` を指す）
  - 補完: `~/.grok/completions/bash/grok.bash`・`zsh/_grok`
  - 文書: `~/.grok/docs/user-guide/*.md`（利用者向けの文書 27 本。Web の文書と同じ内容の手元の写し）
  - 設定: `~/.grok/config.toml`（`[cli]` と `installer = "internal"` の 2 行）
- `~/.bashrc` の末尾に足すブロック（`SHELL` が bash のとき。zsh は `~/.zshrc`、fish は `config.fish`）

  ```bash
  # >>> grok installer >>>
  export PATH="$HOME/.grok/bin:$PATH"
  [[ -r "$HOME/.grok/completions/bash/grok.bash" ]] && source "$HOME/.grok/completions/bash/grok.bash"
  # <<< grok installer <<<
  ```

  - 初回は元の `~/.bashrc` を `~/.bashrc.bak.<UNIX 時刻>` に控える。2 回目からは、前のブロックを消して末尾に足し直す（ブロックの前の空行が 1 つずつ増える）
  - 書かせない設定（環境変数など）はインストーラーに無い。`SHELL` が bash・zsh・fish 以外のときだけ書かない
  - `~/.bashrc` がリンクなら、リンク先のファイルを書き換える
- setup-notes では `~/.bashrc` への追記を [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash) に集めているが、このブロックはインストーラーが毎回書くので、手順書では消さずに残し、[ロールバック](../grok-build.md#ロールバック)の手順 3 で消す（codex.md のインストーラーが足すブロックと同じ扱い）
  - 共通の bash 設定より後ろで読まれるので、`~/.grok/bin` が PATH の先頭に来る
- インストーラー（`install.sh`）は、配布物のハッシュや署名を確かめない（Windows の `install.ps1` が同梱の Git の zip の SHA-256 を確かめるだけ）

### 実施手順 / 手順 4〜6: ログインの流れ

- `grok login` は SpaceXAI の OAuth（`auth.x.ai`）でログインする。ブラウザが開けないときは、`https://accounts.x.ai/oauth2/device?user_code=…` の URL と確認用のコードを出して待つ（`--device-auth` と同じ画面）
- ログインの情報は `~/.grok/auth.json`（Unix では `0600`）に入り、自動で更新される。更新できなくなると、もう一度ログインを求められる（公式の文書 02-authentication）
- `grok models` は、ログインしていなくても終了コード 0 で、`You are not authenticated.` と既定のモデルの一覧を出す（1.0.50）。Claude Code のプラグインの `/grok-build:check` も、この終了コードだけで「ログイン済み」と判定する（[coding-agents.md の注意点](../coding-agents.md#注意点)）

### 実施手順 / 手順 7: フォルダーの信頼

- Grok は、信頼したフォルダーでだけ、起動のときにプロジェクトの指示書（AGENTS.md・CLAUDE.md など）・skills・MCP サーバー・hooks を読む
- 信頼は `~/.grok/trusted_folders.toml` に残る。対話の画面で答えるか、`--trust` を付けて起動すると記録される
- 信頼はそのリポジトリの下のディレクトリにも効く。入れ子の別の git のチェックアウトや、別の場所の worktree は、別に信頼する

### Windows 11 で使う / 手順 2: インストーラーの動き

- `%USERPROFILE%\.grok\downloads\grok-windows-<アーキ>.exe` を取ってきて、`%USERPROFILE%\.grok\bin\grok.exe` と `agent.exe` に写す（リンクではなくコピー）
- Grok が使う Git（MinGit）を `%LOCALAPPDATA%\grok\git\<版>` に置く。zip は SHA-256 を確かめてから展開する
- PowerShell の補完を `%USERPROFILE%\.grok\completions\powershell\grok.ps1` に書く（プロファイルには足さない）
- 自分のユーザーの PATH の先頭に `%USERPROFILE%\.grok\bin` を足し、今の窓の `$env:Path` にも足す（`[Environment]::SetEnvironmentVariable('Path', …, 'User')`。[claude-code.md の参考資料](claude-code.md#windows-11-で使う--手順-5-補足-path-の足し方)と同じ書き方で、`%USERPROFILE%` のような書き方は展開した形で書き戻される）
- スクリプトの先頭で `$ErrorActionPreference = 'Stop'` にするので、`irm … | iex` ではなく `&` でスクリプトブロックとして呼び、今の窓にその設定を残さない（codex.md と同じ）。失敗したときの `exit 1` は、どちらの呼び方でも窓を閉じることがある

### 注意点: 会話のデータの扱い

- `/privacy` は、設定の Coding data, retention, and training を開き、Opt in / Opt out を選ぶ（公式の文書 04-slash-commands）
- 2026-07 に、ベータ版の `grok` がディレクトリの中身を xAI のクラウドのストレージに送ることがあったと報告された（Simon Willison のブログ、2026-07-15。二次情報）
  - 同じ記事が引く xAI の発表は「2026-07-12 から、すべての Grok Build の利用者で既定の保存を止めた」「それまでに送られたデータは削除する」としている
  - その後、ソースコードが Apache-2.0 で公開された（github.com/xai-org/grok-build）
- 秘密情報のあるディレクトリで `grok` を起動しない。sandbox（`--sandbox read-only` など。Linux と macOS だけ。Linux では bubblewrap が要る）で書き込める場所を絞れる

## 参照

- [xAI: Grok Build CLI の発表](https://x.ai/news/grok-build-cli)（2026-05-25。対象は SuperGrok と X Premium+）
- [xAI: Grok Build の文書](https://docs.x.ai/build/overview) — 導入・ログイン・使い方
- 手元の文書 `~/.grok/docs/user-guide/`（1.0.50 に同梱）: 01-getting-started・02-authentication・05-configuration・12-project-rules・14-headless-mode・18-sandbox・22-permissions-and-safety
- [公式の Linux / macOS のインストーラー](https://x.ai/cli/install.sh)・[公式の Windows のインストーラー](https://x.ai/cli/install.ps1)
- [xai-org/grok-build](https://github.com/xai-org/grok-build) — ソース（Apache-2.0）
- [xAI: Models](https://docs.x.ai/developers/models) — モデルと料金（API キーで使うとき）
- [Simon Willison: xai-org/grok-build, now open source](https://simonwillison.net/2026/Jul/15/grok-build/)（二次情報）
