# Grok Build（xAI の公式 CLI）を AlmaLinux 10・Windows 11 に入れる

## 実施手順

- [検証記録](verification/grok-build.md)・[参考資料](reference/grok-build.md)・[ロールバックと注意点](extra/grok-build.md)

> [!IMPORTANT]
> - **Windows 11 は、[Windows 11 で使う](#windows-11-で使う)から始める**
> - この節は AlmaLinux 10 の bash に、自分のユーザーで貼る（インストーラーと `grok` を `sudo` で動かさない）
> - Git は [git.md](git.md)、ブラウザが必要なら [firefox.md](firefox.md) で先に入れる
> - Grok Build を使える grok.com のアカウントとインターネット接続が要る。発表時の対象は SuperGrok と X Premium+（X Premium は対象に書かれていない）。今の対象は xAI の案内で確かめる
> - **手順 2 のインストーラーは、`~/.bashrc` の末尾に PATH と補完のブロックを足す**（共通の bash 設定とは別。[参考資料](reference/grok-build.md#実施手順--手順-2-インストーラーが置くものと-bashrc)）

- 上から順に貼る。操作に使うコードブロックだけを上から順に貼る
- 対象は端末で使う Grok Build の CLI（`grok`）。名前の似た非公式の grok-cli（npm の `grok-dev` など）とは別物
- SSH 先などブラウザの無いホストでは、手順 4・5 の代わりに[ブラウザの無いホストでログインする](#ブラウザの無いホストでログインする)を通す
- 手順の後: Claude Code・Codex と同じプロジェクトで使うなら [coding-agents.md](coding-agents.md)。以後は[更新](#更新)・[ロールバック](extra/grok-build.md#ロールバック)

1. 既存の Grok と、同じ名前のコマンドが無いか確かめる。

   ```bash
   command -v grok agent curl
   ls -ld ~/.grok
   ```

   - 新規の PC なら `curl` のパスだけが出て、`ls` は `No such file or directory` になる
   - `curl` のパスが出なければ、`sudo dnf install -y curl-minimal` で入れてから進む
   - `grok` か `~/.grok` があれば、元の導入方法を確かめてから進める。非公式の grok-cli も同じ `grok` と `~/.grok` を使うので、先に外す
   - `agent` のパスが出たら、それが何かを確かめる。インストーラーは `~/.local/bin/agent` を Grok へのリンクで置き換えることがある（[注意点](extra/grok-build.md#注意点)）

1. 公式のインストーラーで Grok Build を入れる。

   ```bash
   curl -fsSL https://x.ai/cli/install.sh | bash
   ```

   - `Grok … installed to /home/<USER>/.grok/bin/grok` を確かめる
   - `Updated /home/<USER>/.grok/bin in PATH in /home/<USER>/.bashrc.` が出る。`~/.bashrc` の末尾に `# >>> grok installer >>>` から `# <<< grok installer <<<` までのブロックが足され、初回は元のファイルが `~/.bashrc.bak.<数字>` に控えられる
   - `~/.local/bin` が PATH にあるホスト（[codex.md](codex.md) で Codex を入れたホストなど）では、`Symlinked /home/<USER>/.local/bin/grok -> …` と `…/agent -> …` も出る
   - 質問は出ない

1. 今の端末の PATH を通し、実行ファイルと版を確かめる。

   ```bash
   export PATH="$HOME/.grok/bin:$PATH"
   hash -r
   command -v grok
   grok --version
   ```

   - 自分のホームの `.grok/bin/grok` と `grok 1.0.50 (…)` のような版が出る
   - 新しく開いた端末でも `grok --version` が通ることを確かめる

1. ブラウザでのログインを始める。

   ```bash
   grok login
   ```

   - ブラウザが開く。開かなければ、端末に出た `https://accounts.x.ai/oauth2/device?user_code=…` の URL を同じ PC のブラウザで開く
   - 端末に確認用のコード（`XXXX-XXXX` の形）が出て、`Waiting for authorization...` のまま待つ

1. ブラウザで grok.com のアカウントにログインし、Grok Build との接続を承認する。

   - ブラウザに出たコードが、端末のコードと同じであることを確かめてから承認する
   - **次の手順は、端末でログインの成功を確かめ、シェルのプロンプトに戻ってから貼る**

1. ログインを確かめる。

   ```bash
   grok models
   ```

   - `You are not authenticated.` が出なければ、ログインできている
   - ログインしていなくても終了コードは 0 で、モデルの一覧は出る。終了コードでは判定しない
   - ログインの情報は `~/.grok/auth.json` に入る。中身を表示・共有しない

1. 確認用のディレクトリで Grok を起動する。

   ```bash
   mkdir -p ~/grok-sandbox
   cd ~/grok-sandbox
   git init
   grok
   ```

   - フォルダーを信頼するか聞かれたら、`grok-sandbox` であることを確かめて信頼する
   - 入力欄に「このディレクトリの状態を説明してください。ファイルは変更しないでください」と入力し、応答を確かめる
   - 終了するときは `/quit` を入力する
   - **後ろの節のコマンドは、Grok を終了してシェルのプロンプトに戻ってから貼る**

---

## 更新

- Windows 11 は [Windows 11 の更新](#windows-11-の更新)へ進む
- 公式のインストーラーで入れた Grok は、自分で新しい版に上がる（設定の `[cli] auto_update` の既定）
- 新しい版を確かめるのは、対話の画面（`grok`）を起動したとき。前に確かめてから間もなければ確かめない
- 新しい版は裏で `~/.grok/downloads` に入り、次に起動したときから使われる
- 自動の更新も `grok update` も、`~/.bashrc` を変えない
- この節の手順は、すぐに上げたいときだけ行う

1. 起動中の Grok を終了する。

   - 端末の Grok は `/quit` で閉じる

1. 新しい版を入れ、版を確かめる。

   ```bash
   grok update
   grok --version
   ```

   - 新しい版が無ければ `Already up to date (…)` と出る
   - 確かめるだけなら `grok update --check`（`(latest: …)` に最新の版が出る）

---

## Windows 11 で使う

> [!IMPORTANT]
> - 自分のユーザーの **管理者ではない Windows PowerShell 5.1** で行う
> - [Windows 11 の初期設定](windows-setup.md#実施手順)の手順 16〜19（貼り付けの設定）を先に通す。未設定なら Ctrl+V で貼る
> - Git は [git.md の Windows 11 の節](git.md#windows-11-で-git-for-windows-を入れる)で先に入れる
> - Grok Build を使える grok.com のアカウントとインターネット接続が要る（[実施手順](#実施手順)のリードと同じ）

- 上から順に貼る。WSL・Node.js・npm は、この方法では要らない
- 操作に使うコードブロックだけを上から順に貼る
- Windows には Grok の sandbox（`--sandbox`）が無い（公式の文書は Linux と macOS だけ。[注意点](extra/grok-build.md#注意点)）

1. 既存の Grok が入っていないか確かめる。

   ```powershell
   Get-Command grok, agent -All -ErrorAction SilentlyContinue
   Test-Path "$env:USERPROFILE\.grok"
   ```

   - 新規の PC なら、`False` だけが出る
   - パスか `True` が出たら、元の導入方法を確かめてから進める（WinGet の `xAI.GrokBuild` で入れた Grok なら、WinGet で更新する）

1. 公式のインストーラーで Grok Build を入れる。

   ```powershell
   & ([scriptblock]::Create((Invoke-RestMethod -Uri 'https://x.ai/cli/install.ps1')))
   ```

   - `Grok … installed to C:\Users\<WIN_USER>\.grok\bin\grok.exe` を確かめる
   - 初回は `Added C:\Users\<WIN_USER>\.grok\bin to your User PATH.` も出る
   - **次の手順は、インストーラーが終わり、PowerShell のプロンプトに戻ってから貼る**

1. 実行ファイルと版を確かめる。

   ```powershell
   Get-Command grok -All
   grok --version
   ```

   - `Source` がこの節の手順 2 の場所で、`grok …` の版が出ることを確かめる

1. PowerShell を閉じ、スタートメニューから開き直す。

   - 新しい窓でも `grok --version` が通ることを確かめる
   - 見つからない場合は、Windows Terminal など親のアプリも閉じて開き直す

1. ブラウザでのログインを始める。

   ```powershell
   grok login
   ```

   - ブラウザが開く。開かなければ、端末に出た URL を同じ PC のブラウザで開く

1. ブラウザで grok.com のアカウントにログインし、Grok Build との接続を承認する。

   - ブラウザに出たコードが、端末のコードと同じであることを確かめてから承認する
   - **次の手順は、端末でログインの成功を確かめ、PowerShell のプロンプトに戻ってから貼る**

1. ログインを確かめる。

   ```powershell
   grok models
   ```

   - `You are not authenticated.` が出なければ、ログインできている（[実施手順](#実施手順)の手順 6 と同じ）

1. 確認用のディレクトリで Grok を起動する。

   ```powershell
   New-Item -ItemType Directory -Path "$env:USERPROFILE\grok-sandbox" -Force | Out-Null
   Set-Location "$env:USERPROFILE\grok-sandbox"
   git init
   grok
   ```

   - フォルダーを信頼するか聞かれたら、`grok-sandbox` であることを確かめて信頼する
   - 入力欄に「このディレクトリの状態を説明してください。ファイルは変更しないでください」と入力し、応答を確かめる
   - 終了するときは `/quit` を入力する
   - **後ろの節のコマンドは、Grok を終了して PowerShell のプロンプトに戻ってから貼る**

---

## Windows 11 の更新

- AlmaLinux 10 と同じく、対話の画面（`grok`）を起動したときに新しい版を確かめ、自分で上がる
- この節の手順は、すぐに上げたいときだけ行う

1. 起動中の Grok を終了する。

   - 端末の Grok は `/quit` で閉じる

1. 新しい版を入れ、版を確かめる。

   ```powershell
   grok update
   grok --version
   ```

   - 新しい版が無ければ `Already up to date (…)` と出る

---

## ブラウザの無いホストでログインする

- 通常の `grok login` の代わりに行う。ここにある 2 つのコマンドは bash と PowerShell で共通なので、Windows ではそのまま PowerShell に貼る

1. Grok を入れたホストで、デバイスコードでのログインを始める。

   ```bash
   grok login --device-auth
   ```

   - 端末に URL（`https://accounts.x.ai/oauth2/device?user_code=…`）と確認用のコードが出て、`Waiting for authorization...` のまま待つ

1. 手元のブラウザで表示された URL を開き、コードを確かめて承認する。

   - 自分で始めたログインのコードだけを承認する
   - **次の手順は、Grok を入れたホストでログインの成功を確かめてから貼る**

1. Grok を入れたホストでログインを確かめる。

   ```bash
   grok models
   ```

   - `You are not authenticated.` が出なければ、元の節の起動する手順へ進む

---

## 設定ファイル

| 用途 | AlmaLinux 10 | Windows 11 |
|---|---|---|
| ユーザー設定 | `~/.grok/config.toml` | `%USERPROFILE%\.grok\config.toml` |
| 実行ファイル | `~/.grok/bin/grok`（`~/.grok/downloads/` の配布物へのリンク） | `%USERPROFILE%\.grok\bin\grok.exe` |
| ログイン情報 | `~/.grok/auth.json` | `%USERPROFILE%\.grok\auth.json` |
| 会話の記録 | `~/.grok/sessions/` | `%USERPROFILE%\.grok\sessions\` |
| 信頼したフォルダー | `~/.grok/trusted_folders.toml` | `%USERPROFILE%\.grok\trusted_folders.toml` |
| プロジェクトの設定 | `<プロジェクト>/.grok/config.toml`（MCP サーバー・プラグイン・許可の規則） | 同じ |

- `auth.json` はパスワードと同じ扱いにし、Git・共有フォルダー・チャットへ載せない
- そのディレクトリで読まれる設定・指示書（AGENTS.md など）・MCP サーバーは、`grok inspect` で見られる（ログインしていなくても動く）
- 初回の導入のために `config.toml` を書く必要は無い（インストーラーが `[cli]` の 2 行を書く）
- 自動の更新を止めるときは、`config.toml` の `[cli]` の下に `auto_update = false` の行を足す。止めたら、[更新](#更新)の手順で上げる
