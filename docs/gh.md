# GitHub CLI（gh）インストール手順（AlmaLinux 10 は公式 dnf リポジトリ / Windows 11 は scoop）

## 実施手順

- [検証記録](verification/gh.md)・[参考資料](reference/gh.md)

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（scoop で入れる。管理者ではない Windows PowerShell 5.1 に貼る）
> - **すべて対象ホスト上で実行する**。手順 4 の認証だけブラウザで行う
> - **手順 2 と手順 3 には対話入力がある**（手順 2 は署名鍵の取り込みの確認が 2 回、手順 3 は `gh auth login` の対話）。手順 3 は、手順 4 のブラウザでの認証を終えてから次の手順を貼る

- 上から順にコードブロックを貼る
- 手順の後: 以後は[更新](#更新)・[ロールバック](#ロールバック)

1. `dnf config-manager` を使えるようにし、リポジトリを追加する。

   ```bash
   {
     sudo dnf install -y 'dnf-command(config-manager)'
     sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
     cat /etc/yum.repos.d/gh-cli.repo
   }
   ```

   - AlmaLinux 10 の dnf は 4 系（dnf5 ではない）なので、この後の手順も dnf4 の構文を使う（参考資料を参照）
   - `Adding repo from: ...` と出て、`/etc/yum.repos.d/gh-cli.repo` ができる
   - `gpgcheck=1` になっていることを確認する

1. gh をインストールする。

   ```bash
   sudo dnf install gh
   ```

   - 初回は署名鍵の取り込みを **2 回**聞かれる（鍵が 2 本ある）
   - fingerprint が次の 2 つであることを目で確かめてから `y` と答える
     - `7F38 BBB5 9D06 4DBC B3D8 4D72 5612 B364 6231 3325`
     - `2C61 0620 1985 B60E 6C7A C873 23F3 D4EA 7571 6059`
   - どちらも Userid は `GitHub CLI <opensource+cli@github.com>`。違っていれば `N` で中断する
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

1. GitHub へのログインを始める。

   ```bash
   gh auth login
   ```

   - 対話で GitHub.com / HTTPS / ブラウザ認証を選ぶ
   - ワンタイムコードが表示されたら、手順 4 のブラウザで使う
   - **トークン（`gh auth token` の出力）や、認証中に表示されるワンタイムコードはこの文書に載せない**

1. ブラウザで、GitHub の認証を済ませる。

   - 手順 3 のワンタイムコードを、ブラウザの `https://github.com/login/device` に入れ、画面の案内に従う
   - SSH 越しの端末でこのホストのブラウザを開けないときは、手元のブラウザで開く
   - **次の手順は、`gh auth login` が終わってから貼る**（続けて貼ると対話の答えとして食われる）

1. 認証できたか確かめる。

   ```bash
   gh auth status
   gh --version
   ```

   - 認証前の `gh auth status` は `You are not logged into any GitHub hosts.` を返す

---

## 更新

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 の更新](#windows-11-の更新)
- 通常の `dnf upgrade` に含まれる

1. gh だけを上げるときは、パッケージを指定して更新する。

   ```bash
   sudo dnf upgrade gh
   ```

---

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

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows のデスクトップで行う**。この節の手順 1 で**管理者ではない** Windows PowerShell（5.1）を開き、この節の手順 2〜4・6 と、後ろの Windows 11 の 2 節（更新・ロールバック）のブロックをそこに貼る
> - SSH のセッションには貼らない（scoop は自分のユーザーに入れる。Administrators の一員の SSH のセッションは管理者の権限で動く）
> - 前提: [Windows 11 の初期設定の手順 16〜19 と手順 20・21](windows-setup.md#実施手順)（貼り付けの設定と scoop）。手順 16〜19 を通していなければ、ブロックは Ctrl+V で貼る
> - 前提: [git.md の Windows 11 で Git for Windows を入れる](git.md#windows-11-で-git-for-windows-を入れる)（gh は git を呼ぶ。git の HTTPS の認証は、Git for Windows の Git Credential Manager のまま使う）
> - **この節の手順 4 には対話入力があり、この節の手順 5 は既定のブラウザで行う**（`gh auth login` の問いと、ブラウザでの認証）。`gh auth login` が終わってから、この節の手順 6 を貼る

- この節の手順 1 で開いた PowerShell に、上から順にコードブロックを貼る。変数は無い
- 手順の後: 以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](#windows-11-のロールバック)
- Git Bash（WezTerm のタブ）・PowerShell 7・cmd の gh も、同じ設定（`%APPDATA%\GitHub CLI`）と同じログインを使う。`~/.bashrc` と PowerShell のプロファイルには何も足さない（gh の補完も入れない。[参考資料](reference/gh.md#windows-11-では-選択した方針)）
- WSL の AlmaLinux 10 の gh は、WSL の中で[実施手順](#実施手順)を通して別に入れる（ログインも別）
- SSH のセッションで gh を使うことは確かめていない（scoop の shim には、[windows-openssh-server.md の scoop のツールを SSH のセッションで使う（任意）](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)が要る）
- この節のブロックは、Windows の実機で流していない（[検証記録](verification/gh.md#windows-11-で使う-検証状況の記録)）

1. Windows で、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。「PowerShell 7」ではない）

1. 管理者ではないことと、scoop・git・Git の資格情報のヘルパー・ほかの gh を確かめる。

   ```powershell
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     GitCred    = if (Get-Command git -ErrorAction SilentlyContinue) { (git config --get-regexp '^credential\..*helper$') -join ', ' }
     Gh         = (Get-Command gh -All -ErrorAction SilentlyContinue).Source -join ', '
   } | Format-List
   ```

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`Admin : True` なら、窓を閉じてこの節の手順 1 から
   - `Scoop` に `C:\Users\<WIN_USER>\scoop\shims\scoop.ps1` が出ればよい。空なら、先に [Windows 11 の初期設定の手順 20・21](windows-setup.md#実施手順) で入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [git.md の Windows 11 で Git for Windows を入れる](git.md#windows-11-で-git-for-windows-を入れる)
   - `GitCred` が `credential.helper manager` ならよい（Git for Windows のインストーラの既定の Git Credential Manager）
   - `GitCred` に `auth git-credential` で終わる行があれば、前に gh を Git の資格情報のヘルパーにしてある（`gh auth setup-git` など）。この節の手順 4 で Git の認証は聞かれない
   - `GitCred` が空なら、Git の資格情報のヘルパーが無い。この節の手順 4 の Git の認証には `Y` と答えてよい（gh が `~/.gitconfig` に自分をヘルパーとして書く）
   - `Gh` が空なら、gh は入っていない。`C:\Users\<WIN_USER>\scoop\shims\gh.exe` だけなら、もう scoop で入っている（この節の手順 3 の `scoop install` は何も変えない）
   - ほかの場所（winget の MSI の `C:\Program Files\GitHub CLI\gh.exe` など）が出たら、ほかの方法で入れた gh がある。混ざらないよう、外してから始める（ログインと設定は残り、scoop の gh も同じ場所を読む）

1. scoop で gh を入れ、版と場所を確かめる。

   ```powershell
   scoop install gh
   gh --version
   (Get-Command gh -All).Source
   ```

   - `'gh' (2.102.0) was installed successfully!` の形の行が出ればよい（版は実行した日の最新）
   - もう入っていれば、`'gh' (<版>) is already installed.` と `Use 'scoop update gh' to install a new version.` の警告を出して何も変えない
   - `gh version <版> (<日付>)` の形で、入れた版が出ればよい
   - 最後のコマンドは、`C:\Users\<WIN_USER>\scoop\shims\gh.exe` の 1 行だけを出せばよい

1. GitHub へのログインを始める。

   ```powershell
   gh auth login
   ```

   - 問いには、矢印キーで選んで Enter で答える
     - `Where do you use GitHub?` は `GitHub.com`
     - `What is your preferred protocol for Git operations on this host?` は `HTTPS`
     - `Authenticate Git with your GitHub credentials?` は、**`n` と打って Enter**（既定は `Y`）。git の HTTPS の認証は、Git Credential Manager のままにする（[参考資料](reference/gh.md#windows-11-で使う--手順-4-補足-git-の認証に-n-と答える理由)）
     - `How would you like to authenticate GitHub CLI?` は `Login with a web browser`
   - Git の認証の問いが出なければ、gh がもう Git の資格情報のヘルパーになっている（この節の手順 2 の `GitCred`）
   - `One-time code (<コード>) copied to clipboard` の行のワンタイムコードを、この節の手順 5 のブラウザで使う（gh の既定では、クリップボードにも入る）
   - クリップボードに入れられなかったときは、`First copy your one-time code:` の後にコードが出る
   - `Press Enter to open https://github.com/login/device in your browser...` で Enter を押すと、既定のブラウザが開く
   - **トークン（`gh auth token` の出力）や、認証中に表示されるワンタイムコードはこの文書に載せない**

1. ブラウザで、GitHub の認証を済ませる。

   - 開いたページ（`https://github.com/login/device`）に、この節の手順 4 のワンタイムコードを入れ、画面の案内に従う（[実施手順](#実施手順)の手順 4 と同じ）
   - ブラウザが開かなければ（`Failed opening a web browser at …`）、`https://github.com/login/device` を自分でブラウザで開く
   - PowerShell に `Logged in as <GITHUB_USER>` が出れば、`gh auth login` は終わっている
   - `Authentication credentials saved in plain text` も出たら、トークンは資格情報マネージャーに置けず、`%APPDATA%\GitHub CLI\hosts.yml` に平文で入った（[注意点](#注意点)のトークンの置き場所）
   - **次の手順は、`gh auth login` が終わってから貼る**（続けて貼ると対話の答えとして食われる）

1. ログインできたことと、Git の資格情報のヘルパーが変わっていないことを確かめる。

   ```powershell
   gh auth status
   git config --get-regexp '^credential\..*helper$'
   ```

   - `Logged in to github.com account <GITHUB_USER> (keyring)` の行と、`Git operations protocol: https` の行が出ればよい（`keyring` は、トークンが資格情報マネージャーにあること）
   - `(keyring)` の代わりに `(C:\Users\<WIN_USER>\AppData\Roaming\GitHub CLI\hosts.yml)` が出たら、トークンは平文のファイルにある
   - `You are not logged into any GitHub hosts.` なら、ログインしていない。この節の手順 4 からやり直す
   - 最後のコマンドが、この節の手順 2 の `GitCred` と同じ行（ふつうは `credential.helper manager`）を出せばよい
   - `GitCred` が空で、Git の認証に `Y` と答えたときは、代わりに `auth git-credential` で終わる行が出る

---

## Windows 11 の更新

- この節の手順 1 は、[Windows 11 で使う](#windows-11-で使う)の手順 1 と同じ管理者ではない Windows PowerShell（5.1）に貼る
- [Windows 11 の初期設定の更新](windows-setup.md#更新)の手順 1・2（`scoop update *`）でも、ほかの scoop のツールと一緒に上がる
- gh のコマンドの後に `A new release of gh is available:` が出たら、新しい版がある
- 上げても、ログインと設定（資格情報マネージャーと `%APPDATA%\GitHub CLI`）は変わらない

1. scoop で gh を上げる。

   ```powershell
   scoop update
   scoop update gh
   gh --version
   ```

   - `scoop update` は `Scoop was updated successfully!` を出す
   - 新しい版があれば、`'gh' (<版>) was installed successfully!` の形の行が出る。無ければ `gh: <版> (latest version)` と出て、何も変わらない
   - `Running process detected, skip updating.` が出たら、上がっていない。ほかの窓で動いている gh を終えてから貼り直す
   - 最後のコマンドで、今の版が出る

---

## Windows 11 のロールバック

- この節のブロックは、管理者ではない Windows PowerShell（5.1）に、上から順に貼る
- **gh を消す前に、この節の手順 1 でログアウトする**。gh を消した後は、資格情報マネージャーに残った gh のトークンを `gh auth logout` で消せない
- [Windows 11 の初期設定のロールバック](windows-setup.md#ロールバック)の手順 13 で scoop ごと外すときも、先にこの節の手順 1〜4 を行う。そのときは、この節の手順 5 は要らない（gh も一緒に消える）。この節の手順 6 の設定は scoop の外にあるので、scoop を外しても残る

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
   - `Y` と答えると、gh は自分のトークンを Git Credential Manager にも入れる（[参考資料](reference/gh.md#windows-11-で使う--手順-4-補足-git-の認証に-n-と答える理由)）。この節の手順 1 では消えない
   - 次に git が GitHub に HTTPS でつなぐときは、Git Credential Manager のサインインになる

1. scoop で gh を消す。

   ```powershell
   scoop uninstall gh
   (Get-Command gh -All -ErrorAction SilentlyContinue).Source
   ```

   - `'gh' was uninstalled.` が出て、最後のコマンドが何も出さなければよい
   - `'gh' isn't installed.` なら、もう入っていない
   - `are still running` のエラーが出たら、消えていない。ほかの窓で動いている gh を終えてから貼り直す

1. 設定も消すときだけ、gh の設定と状態のフォルダーを消す。

   ```powershell
   Remove-Item -LiteralPath "$env:APPDATA\GitHub CLI", "$env:LOCALAPPDATA\GitHub CLI" -Recurse -Force -ErrorAction SilentlyContinue
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
  - [Windows 11 で使う](#windows-11-で使う)の手順 4 で、Git の認証に `n` と答えるため
  - `gh auth logout`・GitHub CLI の認可の取り消し・gh を消すことは、git の HTTPS の認証に影響しない
- **`gh` は git を呼ぶ**: `gh repo clone` などは git に依存する。最小構成のホストでは git 一式が付いてくる
- **全アーキ共通リポジトリ**: `dnf list gh` に `i386` / `armv6hl` の行が出るのは正常
