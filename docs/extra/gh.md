# GitHub CLI（gh）インストール手順（AlmaLinux 10 は公式 dnf リポジトリ / Windows 11 は scoop）のロールバックと注意点

[手順書](../gh.md)・[検証記録](../verification/gh.md)・[参考資料](../reference/gh.md)

- 「手順 N」は[手順書](../gh.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)
- パッケージを消すだけでは、設定と保存された認証情報は残る。認証も外すなら、gh を消す前にこの節の手順 1 を行う
- GitHub 側でトークンも無効にする場合だけ、この節の手順 2 を行う

> [!WARNING]
> **この節の手順 2 は、ほかの端末を含め、GitHub CLI が生成した認証トークンをすべて失効させる。** このホストから認証情報を消すだけなら、手順 1 だけでよい。

1. このホストの認証情報も外すときだけ、ローカルからログアウトする。

   ```bash
   gh auth logout
   ```

   - 対話でホストとアカウントを選び、確認に答える
   - OS の資格情報ストアまたは gh の設定から、このアカウントの保存された認証情報を外す。GitHub 側のトークンは失効しない
   - `~/.config/gh` に残る設定も不要なら、ログアウト後に手で消す。ディレクトリを消すだけでは、資格情報ストアのトークンは消せない
   - **次の手順は、`gh auth logout` が終わってから行う**（続けて貼ると対話の答えとして食われる）

1. 全端末の GitHub CLI のトークンも失効させるときだけ、ブラウザで GitHub の認可を取り消す。

   - `https://github.com/settings/applications` を開き、「Authorized OAuth Apps」の「GitHub CLI」→「Revoke Access」→「I understand, revoke access」で取り消す
   - 本書のブラウザ認証で作ったトークンが対象。ほかの端末も、次に使うときに認証し直す
   - 本書の手順とは別に作った PAT を使っている場合は、その PAT の設定から取り消す

1. gh を消す。

   ```bash
   sudo dnf remove gh
   ```

   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. repo ファイルを消す。

   ```bash
   sudo rm -f /etc/yum.repos.d/gh-cli.repo
   ```

1. 鍵も消すときだけ、署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-62313325-69d4e1f8 gpg-pubkey-75716059-63172e8a   # 鍵も消す場合
   ```

---

## Windows 11 のロールバック

- この節のブロックは、管理者ではない Windows PowerShell（5.1）に、上から順に貼る
- **gh を消す前に、この節の手順 1 でログアウトする**。gh を消した後は、資格情報マネージャーに残った gh のトークンを `gh auth logout` で消せない
- [Windows 11 の初期設定のロールバックの「アプリと貼り付けの設定を外す」](windows-setup.md#アプリと貼り付けの設定を外す)の手順 4 で scoop ごと外すときも、先にこの節の手順 1〜4 を行う。そのときは、この節の手順 5 は要らない（gh も一緒に消える）。この節の手順 6 の設定は scoop の外にあるので、scoop を外しても残る

> [!WARNING]
> **この節の手順 2 は、AlmaLinux 10 のホストを含め、ほかの端末の GitHub CLI のトークンもすべて失効させる。** この PC からログインの情報を消すだけなら、この節の手順 1 だけでよい。

1. この PC のログインを外す。

   ```powershell
   gh auth logout
   ```

   - アカウントが 1 つなら、問わずに `Logged out of github.com account <GITHUB_USER>` を出す。複数あれば、ログアウトするアカウントを選ぶ
   - 資格情報マネージャー（か `hosts.yml`）から、このアカウントのトークンを外す。GitHub 側のトークンは失効しない
   - `not logged in to any hosts` が出たら、もうログアウトしている
   - **次の手順は、`gh auth logout` が終わってから行う**（続けて貼ると対話の答えとして食われる）

1. 全端末の GitHub CLI のトークンも失効させるときだけ、ブラウザで GitHub の認可を取り消す。

   - 操作は[ロールバック](#ロールバック)の手順 2 と同じ（OS に依らない）

1. Git の資格情報のヘルパーから gh を外す。

   ```powershell
   foreach ($k in 'credential.https://github.com.helper', 'credential.https://gist.github.com.helper') {
     if ((git config --global --get-all $k) -match 'auth git-credential') { git config --global --unset-all $k }
   }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git config --get-regexp '^credential\..*helper$'
   ```

   - 最後のコマンドの出力に `credential.helper manager` の行（Git for Windows の既定）があり、`auth git-credential` の行が無ければよい
   - gh を書いていなければ、何も変えない。gh の行が無いキーは残す
   - gh が `~/.gitconfig` に書くのは、ログインで Git の認証に `Y` と答え、Git の資格情報のヘルパーが無かったときと、`gh auth setup-git` を使ったとき

1. ログインで Git の認証に `Y` と答えたときだけ、Git Credential Manager の資格情報を消す。

   ```powershell
   'protocol=https', 'host=github.com' | git credential reject
   ```

   - エラーが出ずにプロンプトに戻ればよい
   - `Y` と答えると、gh は自分のトークンを Git Credential Manager にも入れる（[参考資料](../reference/gh.md#windows-11-で使う--手順-4-補足-git-の認証に-n-と答える理由)）。この節の手順 1 では消えない
   - 次に git が GitHub に HTTPS でつなぐときは、Git Credential Manager のサインインになる

1. scoop で gh を消す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop uninstall gh
   (Get-Command gh -All -ErrorAction SilentlyContinue).Source
   ```

   - `'gh' was uninstalled.` が出て、最後のコマンドが何も出さなければよい
   - `'gh' isn't installed.` なら、もう入っていない
   - `are still running` のエラーが出たら、消えていない。ほかの窓で動いている gh を終えてから貼り直す

1. 設定も消すときだけ、gh の設定と状態のフォルダーを消す。

   ```powershell
   Remove-Item -LiteralPath "$env:APPDATA\GitHub CLI", "$env:LOCALAPPDATA\GitHub CLI" -Recurse -Force -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path -LiteralPath "$env:APPDATA\GitHub CLI", "$env:LOCALAPPDATA\GitHub CLI"
   ```

   - `False` が 2 行出ればよい
   - 設定（`config.yml`・`hosts.yml`。平文で置いたトークンも）と、gh の拡張機能・状態が消える
   - フォルダーを消しても、資格情報マネージャーのトークンは消えない（この節の手順 1 で外す）

---

## 注意点

- **EPEL と公式リポジトリが両方有効だと、更新のたびに両者を比較する**: バージョンが高い公式側が選ばれるので、実害は無い
  - EPEL 側だけを使いたいなら、`exclude=gh` を `gh-cli` 側に書くか、リポジトリを無効にする
- **トークンの置き場所**: OS の資格情報ストアを優先し、使えない場合は `~/.config/gh/hosts.yml` に平文で保存する。保存先は `gh auth status` で確認し、平文ファイルをバックアップや共有に混ぜない
  - `gh auth logout` はローカルの認証情報を外す。GitHub 側のトークンの失効は別の操作（[ロールバック](#ロールバック)の手順 2）
  - Windows 11 では、資格情報マネージャー（Windows 資格情報の汎用資格情報）を優先し、使えない場合は `%APPDATA%\GitHub CLI\hosts.yml` に平文で保存する
- **Windows 11 では、gh と git が別々に GitHub にログインする**: git の HTTPS は、Git for Windows の Git Credential Manager が自分のサインインで行う
  - [Windows 11 で使う](../gh.md#windows-11-で使う)の手順 4 で、Git の認証に `n` と答えるため
  - `gh auth logout`・GitHub CLI の認可の取り消し・gh を消すことは、git の HTTPS の認証に影響しない
- **`gh` は git を呼ぶ**: `gh repo clone` などは git に依存する。最小構成のホストでは git 一式が付いてくる
- **全アーキ共通リポジトリ**: `dnf list gh` に `i386` / `armv6hl` の行が出るのは正常
