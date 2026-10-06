# Codex CLI を AlmaLinux 10・Windows 11 に入れる

## 実施手順

> [!IMPORTANT]
> - **Windows 11 は、[Windows 11 で使う](#windows-11-で使う)から始める**
> - この節は AlmaLinux 10 の bash に、自分のユーザーで貼る（Codex とインストーラーを `sudo` で動かさない）
> - Git は [git.md](git.md)、ブラウザが必要なら [firefox.md](firefox.md)で先に入れる
> - Codex を利用できる ChatGPT アカウントとインターネット接続が必要。API キーで使う場合は API 側の従量課金になる
> - 本書は `CODEX_HOME`・`CODEX_INSTALL_DIR`・`CODEX_RELEASE` を変更していない、新規の standalone インストールを対象にする

- 上から順に貼る。折り畳みの中は補足なので、貼らなくてよい
- 対象は端末で使う **Codex CLI**。デスクトップアプリとエディタの拡張機能は別途導入する
- SSH 先などブラウザの無いホストでは、手順 5・6 の代わりに[ブラウザの無いホストでログインする](#ブラウザの無いホストでログインする)を通す

> [!WARNING]
> AlmaLinux 10.2 / x86_64 のクリーン VM で導入・版の確認・0.160.0 から 0.160.1 への更新を本実行した（2026-10-06、認証前まで）。以前のコンテナでは再導入・配布物の削除も検証した。実機、ログイン、AI への依頼は未検証（[検証範囲](#対象と検証環境)）。

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

   <details>
   <summary>補足: インストーラーが置くもの</summary>

   - Node.js・npm・Homebrew は不要。CPU に合う公式の配布物を取り、SHA-256 と導入後の版を確認する
   - `~/.local/bin/codex` と `~/.local/bin/codex-code-mode-host` にリンクを置き、配布物は `~/.codex/packages/standalone/` に保存する
   - `~/.local/bin` が PATH に無い場合、bash では `~/.bashrc` に `# >>> Codex installer >>>` から `# <<< Codex installer <<<` までのブロックを足す
   - 自分用の [bash の設定](https://github.com/ryo-aoki-pc/bash)を入れたホストでも、追加の設定を手書きする必要は無い

   </details>

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
- 折り畳みの中は補足なので、貼らなくてよい

> [!WARNING]
> Windows 11 の実機では未検証。公式資料・インストーラーの内容と構文を確認した範囲は[補足](#対象と検証環境)に記載する。

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

   <details>
   <summary>補足: 置き場所と PowerShell の設定</summary>

   - 実行ファイルの入口は `%LOCALAPPDATA%\Programs\OpenAI\Codex\bin\codex.exe`。`bin` は `%USERPROFILE%\.codex\packages\standalone\` 内の配布物を指すジャンクションになる
   - インストーラーがユーザー用 PATH と、今の PowerShell の PATH の両方を設定する
   - `&` でスクリプトブロックとして呼び、インストーラーの StrictMode・エラー処理の設定を呼び出し元に残さない
   - PowerShell 全体の ExecutionPolicy を変更する手順は不要

   </details>

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
- 設定・会話履歴と、Windows sandbox が作ったユーザー・ポリシーなどは残る。OS の sandbox 設定を元に戻す手順は未検証

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

## 補足

### 対象と検証環境

- **目的**: Codex CLI を AlmaLinux 10 と Windows 11 に入れ、ログインと最初の起動まで進める
- **調査日**: 2026-10-05
- **状態**:
  - AlmaLinux 10: **10.2 / x86_64 のクリーン VM で実施手順 1〜4 と 0.160.1 への更新を本実行済み（2026-10-06、認証前まで）**。以前のコンテナでも検証。一般ユーザーで 0.160.0 の導入・`--version`・ヘルプ・未ログインの表示・同じ版の再導入・配布物の削除を確認
  - AlmaLinux の実機・aarch64・対話画面・sandbox 内のコマンド実行は未検証
  - Windows 11: 公式資料と `install.ps1` の読み取り、文書の PowerShell ブロック 10 個を Linux の PowerShell 7.6.6 で構文検査（エラー 0）。Windows PowerShell 5.1 での実行は未検証
  - Windows の実機でのインストール・PATH・認証・sandbox・更新・削除、ARM64 は未検証
  - 共通: ChatGPT へのログイン、デバイスコード認証、AI への依頼は未検証

### 選択した方針

- 公式 CLI のページが案内する standalone インストーラーを採る。Node.js やパッケージマネージャーの導入を増やさず、両 OS で同じ配布元を使える
- Windows は native の PowerShell で使う。Linux 用の開発環境が必要な場合の WSL は、本書の対象外
- AlmaLinux 専用の公式対応表を確認したわけではない。Linux 用配布物を AlmaLinux 10 で確認した範囲だけを検証済みとする
- 更新は公式 CLI ページと同じ、インストーラーの再実行で説明する

### 完了時点の状態

- 以下は読者が手順を終えたときの確認点。今回の検証でログイン・AI 応答まで通したという意味ではない
- 自分のユーザーで `codex --version` と `codex login status` を実行できる
- `codex-sandbox` で Codex を起動して応答を確認できる
- 実際のプロジェクトでは、そのディレクトリへ移って `codex` を起動する

### 参照

- [OpenAI: Codex CLI](https://learn.chatgpt.com/docs/codex/cli) — 導入・起動・更新
- [公式 Linux/macOS インストーラー](https://chatgpt.com/codex/install.sh)
- [公式 Windows インストーラー](https://chatgpt.com/codex/install.ps1)
- [OpenAI: Authentication](https://learn.chatgpt.com/docs/auth) — ChatGPT・API キー・デバイスコード・資格情報の保存
- [OpenAI: Windows sandbox](https://learn.chatgpt.com/docs/windows/windows-sandbox) — Windows 11、初回の管理者承認
- [OpenAI: Config basics](https://developers.openai.com/codex/config-basic) — ユーザー設定


### 付録: コンテナと構文の検証記録（2026-10-05）

- 検証環境はクラウドの Linux 上の Docker。`almalinux:10` は AlmaLinux 10.2 (Lavender Lion) / x86_64 だった
- Docker イメージの digest は `sha256:838c2fafefb1a8a0d7f8cdbc3b0551c2a2b1eb0cd87aad6d62aecadb18311f1b`
- 検証用の一般ユーザーを作り、そのログインシェルで実行した。ホストの Codex・設定・認証情報には触れていない
- 検証環境だけで、プロキシと CA バンドルを渡した。dnf のミラー選択が遅かったため、BaseOS / AppStream は `repo.almalinux.org` を指定した（署名検証は有効）
- インストーラーの質問を出さないため、検証時だけ `CODEX_NON_INTERACTIVE=1` を渡した。初回は取得した `install.sh` を `sh` で実行し、再導入は本文と同じ `curl … | sh` で実行した

| 確認 | 結果 |
|---|---|
| 初回導入 | `0.160.0-x86_64-unknown-linux-musl` を取得し、成功の表示まで進んだ |
| PATH と版 | ログインシェルには最初から `~/.local/bin` があり、`codex --version` は `codex-cli 0.160.0` |
| `codex --help`・`codex login --help` | 正常終了。`login status` と `--device-auth` の存在を確認 |
| `codex login status` | `Not logged in`、終了コード 1（ログインは行っていない） |
| インストーラーの再実行 | `Updating Codex CLI` と出て、同じ 0.160.0 を再選択して正常終了 |
| 確認用の作業場所 | ディレクトリ作成と `git init` が正常終了。対話の `codex` は起動していない |
| `codex logout` | 未ログインのため `Not logged in`。認証済みの資格情報を消す動作は未検証 |
| Linux のロールバック | リンク 2 本と `packages/standalone` を削除後、`command -v codex` が終了コード 1。`.codex` 自体は残った |
| bash のブロック 13 個 | `bash -n` で構文の誤り 0 |
| PowerShell のブロック 10 個 | Linux の PowerShell 7.6.6 の構文解析器で誤り 0。Windows の API・レジストリ・ジャンクションの動作や 5.1 との互換を保証する検査ではない |

読み取った公式インストーラーの SHA-256:

| ファイル | SHA-256 |
|---|---|
| `install.sh` | `150e3cf675682efeaac115aa3747add3f27887896d04ce6d0b56478d8b428bf6` |
| `install.ps1` | `3522b77d4485eac014e70fa946787c95fad3874a4e9047557c1e044eb268d13e` |

- インストーラーが PATH に行を足す分岐、別の方法で導入済みの場合の移行、Windows の処理はソースを読んだだけ
- 上のハッシュは調査対象を識別するための記録で、将来のインストーラーにそのまま適用する固定値ではない

---

### 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜4、更新の手順 2・3に相当するインストーラーの再実行と版の確認。

**結果**: 公式 standalone インストーラーで Codex CLI 0.160.0 を導入した。Workstation に curl があったため、本文の案内どおり手順 2 の `curl-minimal` は外した。同じインストーラーを再実行すると、検証中に最新が変わっており 0.160.0 から 0.160.1 へ更新された。`Start Codex now?` は `n` と答え、最終の `codex --version` は `codex-cli 0.160.1`、`codex login status` は `Not logged in`。`~/.local/bin/codex` で見つかることを確認した。

**今回の未確認範囲**: 認証・AI への依頼・対話画面・sandbox での実行、Windows の手順、ロールバックは今回確認していない。

### 付録: 現行版の新規 VM での再検証（2026-10-06）

公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active）で、`5da3478` の本文を SSH 対話 PTY に渡した。試験専用のユーザー・鍵と設定値を使用し、利用者の実アカウントの資格情報は持ち込んでいない。

実施手順 1〜4 を通した。事前の command -v は終了 1、standalone の Codex CLI 0.160.1 が入り、実行場所は自分の ~/.local/bin/codex だった。依存の curl-minimal の指定は、導入済み curl へ解決して成功し、競合は起きなかった。~/.local/bin は OS 既定の PATH にあり、インストーラも既存 PATH と表示した。起動の質問には n と答え、`codex login status` は Not logged in（終了 1）。実アカウントの認証・AI への依頼・更新・ロールバックは行っていない。
