# Codex CLI を AlmaLinux 10・Windows 11 に入れる

## 実施手順

- [検証記録](verification/codex.md)・[参考資料](reference/codex.md)

> [!IMPORTANT]
> - **Windows 11 は、[Windows 11 で使う](#windows-11-で使う)から始める**
> - この節は AlmaLinux 10 の bash に、自分のユーザーで貼る（Codex とインストーラーを `sudo` で動かさない）
> - Git は [git.md](git.md)、ブラウザが必要なら [firefox.md](firefox.md)で先に入れる
> - Codex を利用できる ChatGPT アカウントとインターネット接続が必要。API キーで使う場合は API 側の従量課金になる
> - 本書は `CODEX_HOME`・`CODEX_INSTALL_DIR`・`CODEX_RELEASE` を変更していない、新規の standalone インストールを対象にする

- 上から順に貼る。操作に使うコードブロックだけを上から順に貼る
- 対象は端末で使う **Codex CLI**。デスクトップアプリとエディタの拡張機能は別途導入する
- SSH 先などブラウザの無いホストでは、手順 5・6 の代わりに[ブラウザの無いホストでログインする](#ブラウザの無いホストでログインする)を通す

1. 既存の Codex が入っていないか確かめる。

   ```bash
   command -v codex
   ```

   - 新規の PC なら何も出ず、終了コードは 1 になる
   - パスが出たら、元の導入方法を確認してから進める。npm・Homebrew・standalone を重ねて入れない

1. インストーラーが使う道具を入れる。

   ```bash
   sudo dnf install -y curl-minimal ca-certificates tar gzip
   ```

   - `curl` が既に入っていて `curl-minimal` と競合するときは、`curl-minimal` を外して実行する

1. 公式の standalone インストーラーで Codex CLI を入れる。

   ```bash
   curl -fsSL https://chatgpt.com/codex/install.sh | sh
   ```

   - `Codex CLI … installed successfully.` を確認する
   - `Start Codex now?` と聞かれたら `n` で答える（手順 8 で起動する）
   - **次の手順は、インストーラーが終わり、シェルのプロンプトに戻ってから貼る**

1. 今の端末の PATH を通し、実行ファイルと版を確かめる。

   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   hash -r
   command -v codex
   codex --version
   ```

   - 自分のホームの `.local/bin/codex` と `codex-cli …` が出る（検証時は `0.160.0`）
   - 新しく開いた端末でも `codex --version` が通ることを確認する

1. ChatGPT でのログインを始める。

   ```bash
   codex login
   ```

   - ブラウザが開く。自動で開かなければ、端末に出た URL を同じ PC のブラウザで開く
   - コマンドはログインが完了するまで待つ

1. ブラウザで ChatGPT にログインし、Codex との接続を承認する。

   - 利用するアカウント・ワークスペースを選ぶ
   - **次の手順は、端末でログインの成功を確認し、シェルのプロンプトに戻ってから貼る**

1. ログイン状態を確かめる。

   ```bash
   codex login status
   ```

   - ChatGPT でログイン済みであることを確認する
   - ログイン情報のファイルの中身を表示・共有する必要は無い

1. 確認用のディレクトリで Codex を起動する。

   ```bash
   mkdir -p ~/codex-sandbox
   cd ~/codex-sandbox
   git init
   codex
   ```

   - 作業場所の確認が出たら、`codex-sandbox` であることを確認する
   - 入力欄に「このディレクトリの状態を説明してください。ファイルは変更しないでください」と入力し、応答を確認する
   - 終了するときは `/quit` を入力する
   - **後ろの節のコマンドは、Codex を終了してシェルのプロンプトに戻ってから貼る**

---

## 更新

- Windows 11 は [Windows 11 の更新](#windows-11-の更新)へ進む

1. 起動中の Codex を終了する。

   - 端末の Codex は `/quit` で閉じる

1. 公式インストーラーをもう一度実行する。

   ```bash
   curl -fsSL https://chatgpt.com/codex/install.sh | sh
   ```

   - 新しい配布物を導入する。`Start Codex now?` は `n` で答える
   - **次の手順は、シェルのプロンプトに戻ってから貼る**

1. 更新後の版を確かめる。

   ```bash
   codex --version
   ```

---

## ロールバック

- Windows 11 は [Windows 11 のロールバック](#windows-11-のロールバック)へ進む
- ここでは CLI の配布物だけを消し、設定と会話履歴は残す

1. 起動中の Codex を終了し、ログイン情報も外す場合はログアウトする。

   ```bash
   codex logout
   ```

   - ログイン情報を共有するエディタの拡張機能なども、次回ログインが必要になる

1. この手順で入れたリンクと配布物を消す。

   ```bash
   rm -f ~/.local/bin/codex ~/.local/bin/codex-code-mode-host
   rm -rf ~/.codex/packages/standalone
   hash -r
   command -v codex
   ```

   - 最後に何も出なければ、PATH 上に Codex は無い
   - パスが出る場合は、別の導入方法の Codex が残っている
   - `~/.codex` 全体は消さない（設定・会話履歴などが入っている）

1. インストーラーが PATH のブロックを足した場合だけ、シェルの設定を戻す。

   - `~/.bashrc` の `# >>> Codex installer >>>` から `# <<< Codex installer <<<` までをエディタで削除する
   - `~/.local/bin` 自体や、ほかのツールが書いた PATH の行は消さない
   - 新しい端末を開いて確認する

---

## Windows 11 で使う

> [!IMPORTANT]
> - 自分のユーザーの **管理者ではない Windows PowerShell 5.1** で行う（64 ビットの Windows 11、x64 または ARM64）
> - [Windows 11 の初期設定](windows-setup.md#実施手順)の手順 16〜19（貼り付けの設定）を先に通す。未設定なら Ctrl+V で貼る
> - Git は [git.md の Windows 11 の節](git.md#windows-11-で-git-for-windows-を入れる)で先に入れる
> - Codex を利用できる ChatGPT アカウントとインターネット接続が必要。`CODEX_HOME`・`CODEX_INSTALL_DIR`・`CODEX_RELEASE` を変更していない新規導入を対象にする

- 上から順に貼る。WSL・Node.js・npm は、この方法では不要
- 操作に使うコードブロックだけを上から順に貼る

1. 既存の Codex が入っていないか確かめる。

   ```powershell
   Get-Command codex -All -ErrorAction SilentlyContinue
   ```

   - 新規の PC なら何も出ない
   - パスが出たら、元の導入方法を確認してから進める

1. 公式の standalone インストーラーで Codex CLI を入れる。

   ```powershell
   & ([scriptblock]::Create((Invoke-RestMethod -Uri 'https://chatgpt.com/codex/install.ps1')))
   ```

   - `Codex CLI … installed successfully.` を確認する
   - `Start Codex now?` と聞かれたら `n` で答える
   - **次の手順は、インストーラーが終わり、PowerShell のプロンプトに戻ってから貼る**

1. 実行ファイルと版を確かめる。

   ```powershell
   Get-Command codex -All
   codex --version
   ```

   - `Source` がこの節の手順 2 の場所で、`codex-cli …` が出ることを確認する

1. PowerShell を閉じ、スタートメニューから開き直す。

   - 新しい窓でも `codex --version` が通ることを確認する
   - 見つからない場合は、Windows Terminal など親のアプリも閉じて開き直す

1. ChatGPT でのログインを始める。

   ```powershell
   codex login
   ```

   - ブラウザが開く。自動で開かなければ、端末に出た URL を同じ PC のブラウザで開く

1. ブラウザで ChatGPT にログインし、Codex との接続を承認する。

   - 利用するアカウント・ワークスペースを選ぶ
   - **次の手順は、端末でログインの成功を確認し、PowerShell のプロンプトに戻ってから貼る**

1. ログイン状態を確かめる。

   ```powershell
   codex login status
   ```

   - ChatGPT でログイン済みであることを確認する

1. 確認用のディレクトリで Codex を起動する。

   ```powershell
   New-Item -ItemType Directory -Path "$env:USERPROFILE\codex-sandbox" -Force | Out-Null
   Set-Location "$env:USERPROFILE\codex-sandbox"
   git init
   codex
   ```

   - 作業場所の確認が出たら、`codex-sandbox` であることを確認する
   - Windows sandbox の設定を求められたら案内に従う。推奨の `elevated` sandbox の初回設定には管理者の承認が必要（普段の Codex は通常のユーザーで動かす）
   - 入力欄に「このディレクトリの状態を説明してください。ファイルは変更しないでください」と入力し、応答を確認する
   - 終了するときは `/quit` を入力する
   - **後ろの節のコマンドは、Codex を終了して PowerShell のプロンプトに戻ってから貼る**

---

## Windows 11 の更新

1. 起動中の Codex を終了する。

   - 端末の Codex は `/quit` で閉じる

1. 公式インストーラーをもう一度実行する。

   ```powershell
   & ([scriptblock]::Create((Invoke-RestMethod -Uri 'https://chatgpt.com/codex/install.ps1')))
   ```

   - `Start Codex now?` は `n` で答える
   - **次の手順は、PowerShell のプロンプトに戻ってから貼る**

1. 更新後の版を確かめる。

   ```powershell
   codex --version
   ```

---

## Windows 11 のロールバック

- この節は本書の既定の場所に入れた standalone 版を対象にする
- 設定・会話履歴と、Windows sandbox が作ったユーザー・ポリシーなどは残る。OS の sandbox 設定を元に戻す操作は、この手順には含めない

1. 起動中の Codex を終了し、ログイン情報も外す場合はログアウトする。

   ```powershell
   codex logout
   ```

   - ログイン情報を共有するエディタの拡張機能なども、次回ログインが必要になる

1. Codex の入口と配布物をエクスプローラーで削除する。

   - `%LOCALAPPDATA%\Programs\OpenAI\Codex\bin` のジャンクションを削除する（リンク先の中へ入って削除しない）
   - `%USERPROFILE%\.codex\packages\standalone` を削除する
   - `%USERPROFILE%\.codex` 全体は削除しない（設定・会話履歴などが入っている）

1. ユーザー用 PATH から Codex の入口を外す。

   - スタートメニューで「環境変数」を検索し、自分のアカウントの環境変数を開く
   - ユーザー環境変数の `Path` から `%LOCALAPPDATA%\Programs\OpenAI\Codex\bin` に相当する行だけを削除する
   - PowerShell と、その親の Windows Terminal などを閉じて開き直す

1. PATH 上に Codex が残っていないか確かめる。

   ```powershell
   Get-Command codex -All -ErrorAction SilentlyContinue
   ```

   - 何も出なければ、この CLI の入口は外れている
   - パスが出る場合は、別の導入方法の Codex が残っている

---

## ブラウザの無いホストでログインする

- 通常の `codex login` の代わりに行う。ここにある 2 つのコマンドは bash と PowerShell で共通なので、Windows ではそのまま PowerShell に貼る

1. 手元のブラウザで、デバイスコードによるログインを有効にする。

   - 個人アカウントは ChatGPT のセキュリティ設定、管理されたワークスペースは管理者の権限設定で許可する

1. Codex を入れたホストでデバイスコード認証を始める。

   ```bash
   codex login --device-auth
   ```

   - 端末に URL とワンタイムコードが出る

1. 手元のブラウザで表示された URL を開き、コードを入力する。

   - 自分で始めたログインのコードだけを入力する
   - **次の手順は、Codex を入れたホストでログインの成功を確認してから貼る**

1. Codex を入れたホストでログイン状態を確かめる。

   ```bash
   codex login status
   ```

   - 成功したら、元の節の起動する手順へ進む

---

## 設定ファイル

| 用途 | AlmaLinux 10 | Windows 11 |
|---|---|---|
| ユーザー設定 | `~/.codex/config.toml` | `%USERPROFILE%\.codex\config.toml` |
| standalone の配布物 | `~/.codex/packages/standalone/` | `%USERPROFILE%\.codex\packages\standalone\` |
| ファイル保存の場合の認証情報 | `~/.codex/auth.json` | `%USERPROFILE%\.codex\auth.json` |

- 認証情報は OS の資格情報ストアに保存される場合もある。`auth.json` が無いだけで未ログインとは判断しない
- `auth.json` はパスワードと同じ扱いにし、Git・共有フォルダー・チャットへ載せない
- 初回導入のために `config.toml` を作る必要は無い

---
