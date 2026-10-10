# GitHub CLI（gh）インストール手順（AlmaLinux 10 は公式 dnf リポジトリ / Windows 11 は scoop）の参考資料

[手順書](../gh.md)・[ロールバックと注意点](../extra/gh.md)

## 補足

### 実施手順 / 手順 1: 補足: 生成される repo ファイルと、dnf4 と dnf5 の構文の違い

追加するのは公式が配っている repo ファイルで、生成される `/etc/yum.repos.d/gh-cli.repo` は次のとおり:

```
[gh-cli]
name=packages for the GitHub CLI
baseurl=https://cli.github.com/packages/rpm
enabled=1
gpgcheck=1
gpgkey=https://cli.github.com/packages/githubcli-archive-keyring.asc
```

AlmaLinux 10.2 の dnf は **4.20.0**（`dnf5` パッケージは未導入）なので `--add-repo` を使う。Fedora 41 以降の dnf5 では構文が変わり、`sudo dnf install dnf5-plugins` のうえで:

```
sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
```

になる。公式ドキュメントは両方を併記している。EL10 でも将来 dnf5 に移れば後者になる。

### 実施手順 / 手順 2: 補足: 署名鍵

- 鍵が 2 本あるので、初回は取り込みを 2 回聞かれる

### 実施手順 / 手順 4: 補足: 認証

トークンは OS の資格情報ストアに保存される。ストアを使えない場合は `~/.config/gh/hosts.yml` の平文保存に切り替わる。保存先は `gh auth status` で確認する。`gh auth token` の出力は**記録しない**。

### Windows 11 で使う / 手順 2: 補足: 確かめる値の意味

- `GitCred` の `credential.helper manager` は、Git for Windows のインストーラの既定の Git Credential Manager
- `GitCred` に `auth git-credential` で終わる行があれば、前に gh を Git の資格情報のヘルパーにしてある（`gh auth setup-git` など）。同じ節の手順 4 で Git の認証は聞かれない
- `GitCred` が空なのは、Git の資格情報のヘルパーが無いこと。同じ節の手順 4 で `Y` と答えると、gh が `~/.gitconfig` に自分をヘルパーとして書く
- `Gh` が空なら、gh は入っていない。`C:\Users\<WIN_USER>\scoop\shims\gh.exe` だけなら、もう scoop で入っている（同じ節の手順 3 の `scoop install` は何も変えない）
- ほかの方法で入れた gh を外すのは、混ざらないようにするため。外してもログインと設定は残り、scoop の gh も同じ場所を読む

### Windows 11 で使う / 手順 3: 補足: 版

- `'gh' (<版>) was installed successfully!` の版は、実行した日の最新

### Windows 11 で使う / 手順 4: 補足: Git の認証に n と答える理由

gh 2.102.0 のソースを読んで決めた（[検証記録の付録](../verification/gh.md#付録-windows-11-の節の資料と-linux-での確認2026-10-08)）。**Windows では確かめていない**。

- **問いが出る条件**: `gh auth login` で HTTPS を選ぶと、github.com の Git の資格情報のヘルパーが gh でなければ、`Authenticate Git with your GitHub credentials?`（既定は Yes）を聞く
  - ヘルパーは `credential.https://github.com.helper`、無ければ `credential.helper` を、スコープを問わずに読む
  - Git for Windows は、インストーラの既定の選択で `system`（`C:\Program Files\Git\etc\gitconfig`）に `credential.helper=manager`（Git Credential Manager）を書く（[git.md の検証記録](../verification/git.md#実施手順--手順-3-補足-設定の-3-つの場所)）。そのため、[Windows 11 の初期設定](../windows-setup.md)の順に通した PC では、この問いが出る
- **Yes と答えたとき**（ソースからの推論）
  - ヘルパーがある（Git for Windows の既定）: `~/.gitconfig` は変えない。`git credential reject` で github.com の資格情報を消してから、`git credential approve` で gh のトークンを Git Credential Manager に入れる。以後、git の HTTPS も gh のトークン（GitHub CLI の OAuth アプリ。`workflow` の権限も付く）で GitHub につなぐ
  - ヘルパーが無い: `~/.gitconfig` の `credential.https://github.com.helper` と `credential.https://gist.github.com.helper` に、空の値（ほかのヘルパーを切る）と `!<gh の場所> auth git-credential` を書く。`gh auth setup-git` と同じ
- **No を選んだ理由**
  - git の HTTPS の認証は、Git for Windows の Git Credential Manager が自分のサインイン（Git Credential Manager の OAuth アプリ）で行う。gh と git のトークンが別になるので、`gh auth logout`・GitHub CLI の認可の取り消し・gh を消すことが、git の push に効かない
  - Yes にすると、gh のトークンが Git Credential Manager にも残る。`gh auth logout` は gh 自身の置き場所しか消さないので、ロールバックに 1 手順増える（[Windows 11 のロールバック](../extra/gh.md#windows-11-のロールバック)の手順 4）
  - `~/.gitconfig` に gh の場所を書かない。書くと、scoop を外した後も git がその場所の gh を呼ぶ
- **Git の資格情報のヘルパーが無い PC**（[Windows 11 で使う](../gh.md#windows-11-で使う)の手順 2 の `GitCred` が空）では、Yes でよい。git の HTTPS の認証を gh に任せることになる（外すのは[Windows 11 のロールバック](../extra/gh.md#windows-11-のロールバック)の手順 3）
- **gh が書く自分の場所**: 環境変数 `GH_PATH` が無ければ、`PATH` の上の同じ名前のファイルが自分自身（かそのシンボリックリンク）ならそれ、違えば自分の実行ファイルの場所を書く（`internal/ghcmd/cmd.go`）
  - scoop の shim（`~\scoop\shims\gh.exe`）は別の実行ファイルなので、`C:\Users\<WIN_USER>\scoop\apps\gh\current\bin\gh.exe` になるはず（推論）。`current` は scoop の更新の後も同じ場所を指す
  - SSH のセッションの git からその場所を呼ぶと、scoop の `current` のジャンクションが [windows-openssh-server.md の任意節](../windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の制限に当たるはず（確かめていない）

### Windows 11 で使う / 手順 4: 補足: ワンタイムコード

- gh の既定では、ワンタイムコードはクリップボードにも入る

### Windows 11 で使う / 手順 6: 補足: トークンと設定の置き場所

ソースから（gh 2.102.0、go-gh 2.16.1、go-keyring 0.2.8）。**Windows では確かめていない**。

| もの | Windows 11 の場所 | AlmaLinux 10 の場所 |
|---|---|---|
| トークン | 資格情報マネージャーの汎用資格情報 `gh:github.com:<GITHUB_USER>` と、今のアカウントの写しの `gh:github.com:`（名前はソースからの推論） | OS の資格情報ストア |
| トークン（ストアを使えないとき） | `%APPDATA%\GitHub CLI\hosts.yml`（平文） | `~/.config/gh/hosts.yml`（平文） |
| 設定（`config.yml`・`hosts.yml`） | `%APPDATA%\GitHub CLI` | `~/.config/gh` |
| 状態・拡張機能・キャッシュ | `%LOCALAPPDATA%\GitHub CLI` | `~/.local/state/gh`・`~/.local/share/gh`・`~/.cache/gh` |

- 設定の場所は、環境変数 `GH_CONFIG_DIR`、次に `XDG_CONFIG_HOME`（`%XDG_CONFIG_HOME%\gh`）があれば、そちらが先になる（go-gh の `ConfigDir`）
- `gh auth status` の `(keyring)` は、トークンが資格情報マネージャーにあること。平文のときは `hosts.yml` の場所が出る
- Git Credential Manager が git のために置く資格情報（`git:https://github.com` の名前になるはず）は、gh の項目とは別

### 選択した方針

- 両方が有効なら、dnf はバージョンの高い `gh-cli` 側を選ぶ
- `armv6hl` や `i386` の行が見えるのは、このリポジトリが `baseurl` にアーキテクチャを含まない**全アーキテクチャ共通**の作りだから（Mozilla のリポジトリと同じ）

### Windows 11 では: 選択した方針

[Windows 11 で使う](../gh.md#windows-11-で使う)の理由。**Windows の実機では未検証**（[検証記録](../verification/gh.md#windows-11-で使う-検証状況の記録)）。

- **scoop の main のバケットの `gh`**: [README の導入の基盤](../../README.md#導入の基盤)の「CLI ツールは scoop」に合わせた
  - 管理者の権限が要らない。[Windows 11 の初期設定の更新](../windows-setup.md#更新)の `scoop update *` でほかのツールとまとめて上がり、UniGet UI にも出る
  - winget の `GitHub.cli` は、先に並ぶのが MSI（`Scope: machine`。`C:\Program Files\GitHub CLI` に入り、UAC が出る）。同じ zip の portable もあるが、採らない
  - 上流の MSI や zip を手で入れる形は、更新が手作業になる
  - scoop は、定義の sha256（上流の `gh_<版>_checksums.txt` と同じ値）で zip を確かめる。`gh.exe` には `GitHub, Inc.` の Authenticode の署名があるが、手順では確かめない
  - 版は固定しない（`scoop hold` しない）。scoop で止めるのは、Git Bash で移動先を記録しない 0.10.0 を避ける zoxide だけ（[Windows 11 の初期設定のシェルのツールを入れる（任意）](../windows-setup.md#シェルのツールを入れる任意)）
- **`XDG_CONFIG_HOME` は設定しない**: 設定すると、gh の設定の場所が `%XDG_CONFIG_HOME%\gh` に変わり、設定した窓と設定していない窓で、gh が別のログインの一覧を読む
  - Git for Windows の起動スクリプト、自分用の bash 設定、WezTerm の設定は、どれも `XDG_CONFIG_HOME` を設定しない。そのため、Git Bash・PowerShell・cmd の gh は、同じ `%APPDATA%\GitHub CLI` を読む（ソースと設定を読んだだけ）
  - トークンは資格情報マネージャー（ユーザーごと）にあるので、どのシェルからも同じ
- **git の HTTPS の認証は Git Credential Manager のまま**: [Windows 11 で使う / 手順 4 の補足](#windows-11-で使う--手順-4-補足-git-の認証に-n-と答える理由)
- **シェルとの組み込み方**
  - gh はシェルの初期化が要らない。scoop の shims（ユーザーの `PATH`）にあるので、Git Bash・PowerShell・cmd のどれからでも動く
  - **Git Bash が主**: WezTerm の自分用の設定の `default_prog` は Git Bash（`bash.exe -i -l`）。共通の bash 設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）は gh を扱わない。bash の補完も入れない（足すなら bash リポジトリの変更になる）
  - **PowerShell 7 のプロファイルには何も足さない**: [Windows 11 の初期設定の任意節](../windows-setup.md#powershell-7-のプロファイルを設定する任意)が読むのは starship と zoxide だけ。gh の PowerShell の補完（`gh completion -s powershell`）は、pwsh を開くたびに gh を 1 回動かすので入れない
  - **Windows PowerShell 5.1 のプロファイルにも足さない**: 手順書を貼る窓のプロファイルは、Windows 11 の初期設定の「貼り付けの設定」の手順 4 の 1 行のまま
  - **WSL の AlmaLinux 10 は Linux のホストとして扱う**: WSL の中で[実施手順](../gh.md#実施手順)を通す。設定とトークンは WSL の中にあり、Windows の gh とは別
- **Visual C++ のランタイムは要らない**: `gh.exe`（Go）のインポートは `kernel32.dll` だけ。bat・delta と違い、[wezterm-nightly.md の Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の手順 3 を前提にしない
- **ロールバックは、ログアウトを先にする**: `gh auth logout` が資格情報マネージャーの gh の項目を消す。gh を先に消すと（[Windows 11 の初期設定のロールバックの「アプリと貼り付けの設定を外す」](../extra/windows-setup.md#アプリと貼り付けの設定を外す)の手順 4 で scoop ごと外したときも）、その項目が残る
- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた

### 参照

- [ScoopInstaller/Main — gh.json](https://github.com/ScoopInstaller/Main/blob/master/bucket/gh.json) — Windows 11 の scoop の定義（版・zip と sha256・`bin\gh.exe`）
- [winget-pkgs — GitHub.cli 2.102.0](https://github.com/microsoft/winget-pkgs/blob/master/manifests/g/GitHub/cli/2.102.0/GitHub.cli.installer.yaml) — MSI（machine）と portable（採らなかった経路）
- [gh 2.102.0 の login_flow.go](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/shared/login_flow.go)・[git_credential.go](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/shared/git_credential.go)・[gitcredentials](https://github.com/cli/cli/tree/v2.102.0/pkg/cmd/auth/shared/gitcredentials) — ログインの問いと、Git の認証に Yes と答えたときの動き
- [gh 2.102.0 の internal/config/config.go](https://github.com/cli/cli/blob/v2.102.0/internal/config/config.go)・[status.go](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/status/status.go)・[logout.go（v2.102.0）](https://github.com/cli/cli/blob/v2.102.0/pkg/cmd/auth/logout/logout.go) — トークンの置き場所、状態の表示、ログアウト
- [gh 2.102.0 の internal/ghcmd/cmd.go](https://github.com/cli/cli/blob/v2.102.0/internal/ghcmd/cmd.go) — `GH_PATH` と自分の場所、新しい版の知らせ
- [cli/go-gh v2.16.1 — pkg/config/config.go](https://github.com/cli/go-gh/blob/v2.16.1/pkg/config/config.go) — 設定・状態・データ・キャッシュの場所
- [zalando/go-keyring v0.2.8 — keyring_windows.go](https://github.com/zalando/go-keyring/blob/v0.2.8/keyring_windows.go) — 資格情報マネージャーの項目の名前
- [GitHub CLI manual — gh help environment](https://cli.github.com/manual/gh_help_environment) — `GH_CONFIG_DIR`・`GH_PATH` など
- [Windows 11 の初期設定](../windows-setup.md) — 貼り付けの設定（「貼り付けの設定」の手順 1〜4）、scoop（「アプリを入れる」の手順 1・2）、PowerShell 7 のプロファイルの任意節。[Git](../git.md) — Git for Windows と、その Git Credential Manager

---
