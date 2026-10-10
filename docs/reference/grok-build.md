# Grok Build（xAI の公式 CLI）を AlmaLinux 10・Windows 11 に入れるの参考資料

[手順書](../grok-build.md)・[ロールバックと注意点](../extra/grok-build.md)・[検証記録](../verification/grok-build.md)

## 選択した方針

- xAI の公式のインストーラー（`https://x.ai/cli/install.sh`・`install.ps1`）を使う
  - 公式のインストーラーで入れた Grok は、対話の画面の起動のときに、自分で新しい版に上がる（[更新: 自動の更新の仕組み](#更新-自動の更新の仕組み)）。利用者の希望（自動で最新になるなら公式の方法でよい）に合う
  - Node.js を増やさず、両 OS で同じ配布元・同じ `grok update` で上げられる
- パッケージマネージャーでは入れない
  - 配布はある: Homebrew の cask `grok-build`（Linux でも入る）、WinGet の `xAI.GrokBuild`（portable）、npm の `@xai-official/grok`。scoop の main と extras には無い（2026-10-09）
  - Homebrew と WinGet の版は、`brew upgrade --cask grok-build`・`winget upgrade` を打たないと上がらない
  - npm の版は Node.js が要る
  - Homebrew の cask で入れた Grok でも、`grok update` は Homebrew を使わずに Grok 自身で入れる
  - `grok update --force-reinstall` を打つと、Homebrew の外（`~/.grok/bin`・`~/.grok/downloads`）に別の Grok が入り、Homebrew の版はそのままだった（[検証記録](../verification/grok-build.md#homebrew-の-cask)）
  - Homebrew で使うなら、自動の更新を止め（`[cli] auto_update = false`）、`brew upgrade --cask grok-build` で上げる形になる
  - WinGet で入れた Grok では、`grok update` は WinGet のコマンドを出すだけで何も変えない
  - Homebrew の formula の `grok`（`brew install grok`）は Grok Build ではない（正規表現でログを読む別のツール）
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
- setup-notes では `~/.bashrc` への追記を [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash) に集めているが、このブロックはインストーラーが毎回書くので、手順書では消さずに残し、[ロールバック](../extra/grok-build.md#ロールバック)の手順 3 で消す（codex.md のインストーラーが足すブロックと同じ扱い）
  - 共通の bash 設定より後ろで読まれるので、`~/.grok/bin` が PATH の先頭に来る
- インストーラー（`install.sh`）は、配布物のハッシュや署名を確かめない（Windows の `install.ps1` が同梱の Git の zip の SHA-256 を確かめるだけ）

### 実施手順 / 手順 4〜6: ログインの流れ

- `grok login` は SpaceXAI の OAuth（`auth.x.ai`）でログインする。ブラウザが開けないときは、`https://accounts.x.ai/oauth2/device?user_code=…` の URL と確認用のコードを出して待つ（`--device-auth` と同じ画面）
- ログインの情報は `~/.grok/auth.json`（Unix では `0600`）に入り、自動で更新される。更新できなくなると、もう一度ログインを求められる（公式の文書 02-authentication）
- `grok models` は、ログインしていなくても終了コード 0 で、`You are not authenticated.` と既定のモデルの一覧を出す（1.0.50）。Claude Code のプラグインの `/grok-build:check` も、この終了コードだけで「ログイン済み」と判定する（[coding-agents.md の注意点](../extra/coding-agents.md#注意点)）

### 実施手順 / 手順 7: フォルダーの信頼

- Grok は、信頼したフォルダーでだけ、起動のときにプロジェクトの指示書（AGENTS.md・CLAUDE.md など）・skills・MCP サーバー・hooks を読む
- 信頼は `~/.grok/trusted_folders.toml` に残る。対話の画面で答えるか、`--trust` を付けて起動すると記録される
- 信頼はそのリポジトリの下のディレクトリにも効く。入れ子の別の git のチェックアウトや、別の場所の worktree は、別に信頼する

### 更新: 自動の更新の仕組み

- 設定の `[cli] auto_update`（既定は有効）で、対話の画面の起動のときに新しい版を確かめる。環境変数 `GROK_DISABLE_AUTOUPDATER` でも止められる（同梱の文書 05-configuration・26-config-reference）
- 確かめた時刻は `~/.grok/version.json` の `checked_at` に残り、間もないうちは確かめない
- 新しい版は `~/.grok/downloads/grok-<版>-<OS>-<CPU>` に入り、`~/.grok/bin` の `grok`・`agent` のリンクが付け替わる。前の配布物は残る
- 更新の入れ方は、設定の `[cli] installer`（公式のインストーラーは `internal` を書く）で選ばれる（同梱の文書 26-config-reference）
- 確かめた範囲は[検証記録](../verification/grok-build.md#付録-自動の更新とパッケージマネージャー2026-10-09)

### Windows 11 で使う / 手順 2: インストーラーの動き

- `%USERPROFILE%\.grok\downloads\grok-windows-<アーキ>.exe` を取ってきて、`%USERPROFILE%\.grok\bin\grok.exe` と `agent.exe` に写す（リンクではなくコピー）
- Grok が使う Git（MinGit）を `%LOCALAPPDATA%\grok\git\<版>` に置く。zip は SHA-256 を確かめてから展開する
- PowerShell の補完を `%USERPROFILE%\.grok\completions\powershell\grok.ps1` に書く（プロファイルには足さない）
- 自分のユーザーの PATH の先頭に `%USERPROFILE%\.grok\bin` を足し、今の窓の `$env:Path` にも足す（`[Environment]::SetEnvironmentVariable('Path', …, 'User')`。[claude-code.md の参考資料](claude-code.md#windows-11-で使う--手順-5-補足-path-の足し方)と同じ書き方で、`%USERPROFILE%` のような書き方は展開した形で書き戻される）
- スクリプトの先頭で `$ErrorActionPreference = 'Stop'` にするので、`irm … | iex` ではなく `&` でスクリプトブロックとして呼び、今の窓にその設定を残さない（codex.md と同じ）。失敗したときの `exit 1` は、どちらの呼び方でも窓を閉じることがある

### 注意点: Linux の sandbox を起動できないとき

- Linux のファイルアクセス制限には Landlock が要る。カーネルの版が 5.13 以降でも、`CONFIG_SECURITY_LANDLOCK=y` で組み込まれ、起動中のカーネルで有効になっている必要がある。`/sys/kernel/security/lsm` に `landlock` があることを確かめる
- bubblewrap は、拒否するパスの遮蔽などに使う。bubblewrap があることだけでは `read-only` の書き込み制限が効くと判断しない
- `runtime-socket deny path /run/podman/podman.sock` の `Permission denied (os error 13)` は、ソケット本体に限らず、親ディレクトリを検索できないときも出る。Podman が停止し、ソケットが存在しなくても、親の検索権限が無ければ失敗する。親ディレクトリの検索権限を確かめ、ソケット本体の権限は緩めない
- `read-only` は起動時に `/run/docker.sock` と `/run/podman/podman.sock` を調べるが、`workspace` は調べない。`workspace` が `could not apply the 'workspace' sandbox profile` で止まるときは、ソケットの親ではなく Landlock の側を確かめる（Grok 1.0.50 の起動時のシステムコールを実機で追った。[検証記録](../verification/grok-build.md#sandbox-の再起動なしの追加検証)）
- 親の検索権限を直した後も、カーネルの保護を適用できず起動を拒否する場合がある。Landlock が有効なカーネルで OS を起動してから、同じ sandbox を再試行する。Grok 1.0.50 の実機で確認した 2 つの原因と、対処の準備結果は[追加の調査記録](../verification/grok-build.md#sandbox-の追加原因調査と対処の準備)に分けた。今回の実機ではユーザーの指示により対処を適用せず、調査と準備までで終了した

### 注意点: 会話のデータの扱い

- `/privacy` は、設定の Coding data, retention, and training を開き、Opt in / Opt out を選ぶ（公式の文書 04-slash-commands）
- 2026-07 に、ベータ版の `grok` がディレクトリの中身を xAI のクラウドのストレージに送ることがあったと報告された（Simon Willison のブログ、2026-07-15。二次情報）
  - 同じ記事が引く xAI の発表は「2026-07-12 から、すべての Grok Build の利用者で既定の保存を止めた」「それまでに送られたデータは削除する」としている
  - その後、ソースコードが Apache-2.0 で公開された（github.com/xai-org/grok-build）
- 秘密情報のあるディレクトリで `grok` を起動しない。sandbox（`--sandbox read-only` など。Linux と macOS だけ。Linux では有効な Landlock と bubblewrap が要る）で書き込める場所を絞れる

## 参照

- [xAI: Grok Build CLI の発表](https://x.ai/news/grok-build-cli)（2026-05-25。対象は SuperGrok と X Premium+）
- [xAI: Grok Build の文書](https://docs.x.ai/build/overview) — 導入・ログイン・使い方
- 手元の文書 `~/.grok/docs/user-guide/`（1.0.50 に同梱）: 01-getting-started・02-authentication・05-configuration・12-project-rules・14-headless-mode・18-sandbox・22-permissions-and-safety・26-config-reference
- [公式の Linux / macOS のインストーラー](https://x.ai/cli/install.sh)・[公式の Windows のインストーラー](https://x.ai/cli/install.ps1)
- [xai-org/grok-build](https://github.com/xai-org/grok-build) — ソース（Apache-2.0）
- [Homebrew: grok-build](https://formulae.brew.sh/cask/grok-build) — Homebrew の cask（使わなかった経路）
- [xAI: Models](https://docs.x.ai/developers/models) — モデルと料金（API キーで使うとき）
- [Simon Willison: xai-org/grok-build, now open source](https://simonwillison.net/2026/Jul/15/grok-build/)（二次情報）
