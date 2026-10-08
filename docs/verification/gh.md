# GitHub CLI（gh）インストール手順（AlmaLinux 10 は公式 dnf リポジトリ / Windows 11 は scoop）の検証記録

[手順書](../gh.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順 / 手順 2: 補足: 鍵は 2 本

`githubcli-archive-keyring.asc` には鍵が 2 本入っていて、取り込みも 2 回聞かれる。実測（コンテナ、`-y` 付きで流したときの表示）:

```
Importing GPG key 0x62313325:
 Userid     : "GitHub CLI <opensource+cli@github.com>"
 Fingerprint: 7F38 BBB5 9D06 4DBC B3D8 4D72 5612 B364 6231 3325
 From       : https://cli.github.com/packages/githubcli-archive-keyring.asc
Key imported successfully
Importing GPG key 0x75716059:
 Userid     : "GitHub CLI <opensource+cli@github.com>"
 Fingerprint: 2C61 0620 1985 B60E 6C7A C873 23F3 D4EA 7571 6059
 From       : https://cli.github.com/packages/githubcli-archive-keyring.asc
Key imported successfully
```

実機にも同じ 2 本が `gpg-pubkey-62313325-69d4e1f8` と `gpg-pubkey-75716059-63172e8a` として入っている。

gh 本体は依存の少ないパッケージだが、**git が入っていないホストでは git 一式（`git` / `git-core` / `git-core-doc` / `groff-base` など 13 パッケージ）が付いてくる**。実機は git 導入済みだったので追加は無かった。

### ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**

### Windows 11 で使う: 検証状況の記録

- **[Windows 11 で使う](../gh.md#windows-11-で使う)・[Windows 11 の更新](../gh.md#windows-11-の更新)・[Windows 11 のロールバック](../gh.md#windows-11-のロールバック)は、Windows の実機では未検証**（2026-10-08 に書いた。Windows を動かせないクラウドの Linux のコンテナで書き、どのブロックも Windows では貼っていない）
- 確かめた範囲は[対象と検証環境](#対象と検証環境)の「状態（Windows 11）」と[付録](#付録-windows-11-の節の資料と-linux-での確認2026-10-08)

### 対象と検証環境

- **目的**: AlmaLinux 10 に [GitHub CLI](https://cli.github.com/) の最新版を **dnf 管理で**入れる。EPEL にも `gh` はあるが版が古い
- **進め方**: GitHub が配っている repo ファイルを `dnf config-manager --add-repo` で取り込み、`dnf install gh` する。**読者が書き換える値は無い**
  - Windows 11（[Windows 11 で使う](../gh.md#windows-11-で使う)）では、scoop の main のバケットの gh を、管理者ではない Windows PowerShell 5.1 で入れる。トークンは資格情報マネージャーに置き、git の HTTPS の認証は Git for Windows の Git Credential Manager のままにする
- **状態（AlmaLinux 10）**: **実機で本実行済み（2026-09-20）。x86_64 のクリーン VM でも実施手順を本実行済み（2026-10-06、下の付録の範囲）**
  - 下表のホストで `dnf config-manager --add-repo` → `dnf install -y gh` を実行し、`gh-2.101.0-1.aarch64` が入って認証済み、そのまま常用中
  - 本書の手順 1・2 は 2026-09-22 に同じ OS のコンテナで通し直し、鍵 2 本の fingerprint・同じ版の導入・`gh --version` まで確認した
  - **コンテナでは認証（手順 3・4）とロールバックは実行していない**
  - 2026-09-28: もとの手順 2 のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../writing-guide.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-02: もとの手順 1・2 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）
  - 2026-10-05: 2.101.0 の公式ソースのヘルプ本文で、トークン保存先と `auth logout` の範囲を確認し、ロールバックの手順 1・2 を追加した。認証・ログアウト・失効は実行していない
- **状態（Windows 11）**: **Windows の実機では未検証（2026-10-08 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](#付録-windows-11-の節の資料と-linux-での確認2026-10-08)）:
    - 配布物の定義: scoop の main のバケットの `gh.json`（2026-10-08 に取得。2.102.0）、64bit の zip の sha256（定義と、上流の `gh_2.102.0_checksums.txt` の両方と一致）、`gh.exe` のインポート表と Authenticode の署名者の証明書（Linux で PE を読んだだけ）
    - ソース: gh 2.102.0（ログインの問いと Git の認証の扱い・トークンの置き場所・ログアウト・状態の表示・新しい版の知らせ）、go-gh 2.16.1（設定と状態の場所）、go-keyring 0.2.8（資格情報マネージャーの項目の名前）、Git for Windows の起動スクリプト（`XDG_CONFIG_HOME` を設定しない）、scoop 本体のメッセージ
    - PowerShell のブロック 10 個: Linux の PowerShell 7.5.3 の構文解析器（誤り 0）と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査と既定の規則（指摘 0）
    - 偽物の scoop・gh・Git Credential Manager と、本物の git（使い捨ての `HOME` と `system` の設定）での模擬（Windows 11 で使うの手順 2・3・6、Windows 11 の更新の手順 1、Windows 11 のロールバックの手順 1・3〜6）
  - 関連する確認（Windows 11 の実機の Git Bash。この文書の手順ではない）:
    - 自分用の bash の設定の検証（ryo-aoki-pc/bash の[2026-10-01 の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-11-の-git-bash-での検証記録2026-10-01)）で、利用者の PC の Git Bash の HTTPS の clone に、gh の資格情報を `!gh auth git-credential` の形でそのペインにだけ渡して通した。そのとき、その PC の Git Credential Manager には GitHub の資格情報が無かった（`Found 0 accounts`）
    - 共通の bash 設定は gh を扱わない
  - **確かめていないこと**
    - Windows で貼ること（すべての手順）、scoop での導入・更新・削除
    - `gh auth login` の問いの出方とキー操作、ワンタイムコードのクリップボードへのコピー、ブラウザでの認証、資格情報マネージャーへの保存（`(keyring)` の表示）と、そこに出る項目の名前
    - Git の認証に `Y` と答えたときの動き（ソースからの推論）と、そのときの[Windows 11 のロールバック](../gh.md#windows-11-のロールバック)の手順 4 で Git Credential Manager の資格情報が消えること
    - Git Bash・PowerShell 7・cmd の gh が同じ設定とログインを使うこと
    - SSH のセッション（scoop の shim と、資格情報マネージャーを読めるか）、arm64 の Windows、winget の gh が入った PC

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| dnf / dnf-plugins-core | 4.20.0 / 4.7.0-10.el10 | 同左 |
| 入った gh | `gh-2.101.0-1.aarch64`（gh-cli リポジトリ） | 同じ（`2.101.0-1`） |
| 依存で入ったもの | 無し（git 2.52.0 は導入済みだった） | `git` / `git-core` など 13 パッケージ |
| 認証 | 済み（常用中） | 未実施 |

> [!NOTE]
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。Windows 11 の値は `<WIN_USER>`（Windows のユーザー名）と `<GITHUB_USER>`（GitHub のアカウント名）。バージョン（`2.101.0`）は実行日によって変わる。
>
> **トークンは書かない。** 鍵の fingerprint は公開情報なので本文に書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

AlmaLinux 10 の実機（2026-09-20）。Windows 11 の PC は、[Windows 11 で使う](../gh.md#windows-11-で使う)の手順 2 で確かめる。

| 項目 | 状態 |
|---|---|
| gh | 未導入 |
| `dnf-plugins-core` | 未導入（`dnf config-manager` が使えない） |
| git | `git-2.52.0-1.el10.aarch64` 導入済み |
| 有効な追加リポジトリ | epel、crb、raspberrypi |

### 選択した方針

AlmaLinux 10 で gh を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **公式 dnf リポジトリ（`cli.github.com/packages/rpm`）** | `gh 2.101.0-1`。upstream の最新リリース（v2.101.0、2026-09-15）と一致。dnf 管理で更新できる | **採用** |
| EPEL の `gh` | `gh 2.97.0-2.el10_2`。4 リリースぶん古い | 不採用（最新版ではない） |
| GitHub Releases の `.rpm` を直接 `dnf install` | 同じバイナリだが、更新のたびに手で落とすことになる | 不採用 |
| Homebrew | 入るが、gh は dnf で入る最新版があるのでわざわざ二重にしない | 不採用 |

実測（EPEL と公式リポジトリを両方有効にした状態）:

### 完了時点の状態

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' gh
gh 2.101.0-1 gh-cli
$ gh --version
gh version 2.101.0 (2026-09-15)
https://github.com/cli/cli/releases/tag/v2.101.0
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i github
gpg-pubkey-62313325-69d4e1f8 GitHub CLI <opensource+cli@github.com> public key
gpg-pubkey-75716059-63172e8a GitHub CLI <opensource+cli@github.com> public key
```

`gh` の実体は `/usr/bin/gh`、bash 補完は `/usr/share/bash-completion/completions/gh`。

### 参照

- [Installing gh on Linux and BSD — cli/cli](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) — dnf4 / dnf5 それぞれの手順と repo ファイルの URL
- [GitHub CLI manual](https://cli.github.com/manual/) — `gh auth login` などのコマンド
- [gh 2.101.0 の login](https://github.com/cli/cli/blob/v2.101.0/pkg/cmd/auth/login/login.go)・[logout](https://github.com/cli/cli/blob/v2.101.0/pkg/cmd/auth/logout/logout.go) — 対象版のヘルプ本文。資格情報ストアと平文保存、ローカル削除とサーバー側の失効を区別する（2026-10-05 にソースを確認。認証の操作は未実行）
- `man dnf.conf`（`gpgcheck`）

### 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで手順 1・2 を通した（手順 3 の `gh auth login` は対話なので除外）。実機で加えた変更は `dnf install podman` だけ。 最後にもう 1 つ新しいコンテナを立て、**この文書のコードブロックをそのまま抜き出したスクリプト**（`sudo` を外し、`dnf install` / `dnf upgrade` に `-y` を付けただけ）を流して、上から順に貼れば通ることを確かめている。

| 手順 | 結果 |
|---|---|
| 1. プラグイン | `dnf-plugins-core-4.7.0-10.el10` が入る |
| 1. repo | `Adding repo from: https://cli.github.com/packages/rpm/gh-cli.repo` → `/etc/yum.repos.d/gh-cli.repo` 作成 |
| 2. install | `Installing: gh aarch64 2.101.0-1 gh-cli 14 M` + 依存 13 パッケージ（`git` / `git-core` / `git-core-doc` / `groff-base` / `authselect` など）。鍵 2 本を取り込んで成功 |
| 検証 | `gh --version` → `gh version 2.101.0 (2026-09-15)`。`gh auth status` → `You are not logged into any GitHub hosts.` |
| EPEL との比較 | `epel-release` を追加して `dnf list --showduplicates gh` → EPEL 2.97.0 と gh-cli 2.101.0 の 2 系統 |

#### 未確認事項

- 手順 3・4 の認証（コンテナでは未実施。実機では 2026-09-20 に実行して以後常用）
- `gh auth login` の SSH 鍵方式、`gh auth login --with-token`、GitHub Enterprise Server への接続
- `gh extension install` で入れた拡張の扱い
- ロールバック（`dnf remove` と鍵の削除）の本実行
- dnf5 に移行した場合の `config-manager addrepo` 構文（EL10 では dnf5 が入らないため未検証）

---

### 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1・2。

**結果**: GitHub 公式 RPM リポジトリを追加し、表示された 2 本の署名鍵の fingerprint を本文と比べて取り込んだ。gh 2.102.0 が入り、版と `/usr/bin/gh` を確認した。追加の `gh auth status` は未ログインを示した。

**今回の未確認範囲**: 手順 3・4 のアカウント認証と、更新・ロールバックは今回流していない。

### 付録: 現行版の新規 VM での再検証（2026-10-06）

公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active）で、`5da3478` の本文を SSH 対話 PTY に渡した。試験専用のユーザー・鍵と設定値を使用し、利用者の実アカウントの資格情報は持ち込んでいない。

実施手順 1・2 を通し、公式 repo と文書に載せた 2 本の署名鍵を確認して導入した。gh 2.102.0、`gh auth status` は未ログイン（終了 1）だった。実アカウントの認証、更新・削除はこの再検証で行っていない。端末捕捉補助が問い合わせの処理で待ったため、生ログで版・未ログイン・コマンドの終了を確認し、以後の補助は生出力主体に切り替えた。手順の失敗とは扱わない。

### 付録: Windows 11 の節の資料と Linux での確認（2026-10-08）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物の定義とソースを読み、手順書の PowerShell のブロックを Linux の PowerShell で確かめた記録。**Windows の実機では未検証**。

**資料**（2026-10-08 に取得）:

- scoop の `ScoopInstaller/Main` の `bucket/gh.json`: `version` は `2.102.0`。64bit は `gh_2.102.0_windows_amd64.zip`（32bit と arm64 の zip もある）。`bin` は `bin\gh.exe` だけで、`persist`・`env_set`・`env_add_path`・`depends`・`suggest` は無い。`autoupdate` の hash は上流の `gh_<版>_checksums.txt` から取る
- 上流の版: `cli/cli` のタグの最新（プレリリースを除く）は `v2.102.0`（`git ls-remote` で見た）
- 64bit の zip: sha256 は `ae64e556ecc240b200f7eba60d550e4bb60d78e860e69dd88c449405b86067f4` で、定義の `hash` と、上流の `gh_2.102.0_checksums.txt` の行の両方と一致した。中身は `LICENSE` と `bin/gh.exe` の 2 つ
  - `gh.exe` は `PE32+ executable (console) x86-64`。PE のインポート表は `kernel32.dll` だけ（Visual C++ のランタイムを使わない。`objdump -p` で読んだ）
  - Authenticode の署名があり、署名者の証明書は `O = "GitHub, Inc.", CN = "GitHub, Inc."`、発行者は `Microsoft ID Verified CS AOC CA 03`（PE のセキュリティのディレクトリから取り出し、`openssl pkcs7 -print_certs` で証明書を並べただけ。Windows の `Get-AuthenticodeSignature` は通していない）
- winget の `GitHub.cli` 2.102.0 の定義: x86・x64・arm64 のそれぞれで、先に MSI（`InstallerType: wix`、`Scope: machine`、x64 は `DefaultInstallLocation: '%ProgramFiles%/GitHub CLI'`）、次に同じ zip の portable（x64 の `InstallerSha256` は scoop と同じ値）が並ぶ
- gh 2.102.0 のソース
  - `pkg/cmd/auth/login/login.go`・`pkg/cmd/auth/shared/login_flow.go`: 対話の問いは `Where do you use GitHub?` → `What is your preferred protocol for Git operations on this host?`（`HTTPS` / `SSH`）→（HTTPS のときだけ）Git の認証の問い → `How would you like to authenticate GitHub CLI?` の順。終わると `Logged in as <GITHUB_USER>` を出す。資格情報ストアに置けなければ `Authentication credentials saved in plain text` を出す
  - `internal/authflow/flow.go` と `internal/config/config.go`: 設定の `clipboard` の既定は `enabled` で、ワンタイムコードをクリップボードに入れて `One-time code (<コード>) copied to clipboard` を出す。入れられなければ `Failed to copy one-time code to clipboard` の後に `First copy your one-time code: <コード>` を出す（クリップボードを使わない設定でも、この行を出す）。続けて `Press Enter to open <URL> in your browser...` を出す。ブラウザを開けなければ `Failed opening a web browser at …`
  - `pkg/cmd/auth/shared/git_credential.go`: Git の認証の問いは `Authenticate Git with your GitHub credentials?`（既定は Yes）。github.com の Git の資格情報のヘルパーが gh なら聞かない。Yes のときは、トークンに `workflow` の権限も求める。`Setup` は、ヘルパーが無ければ gh を書き、あれば `Updater` で資格情報を入れ替える
  - `pkg/cmd/auth/shared/gitcredentials/helper_config.go`: ヘルパーは `git config credential.https://github.com.helper`、空なら `git config credential.helper` で読む（どちらもスコープを指定しないので、Git for Windows の `system` の `manager` も入る）。gh かどうかは、`!` の後の最初の語の名前が `gh`（`.exe` を除く）かで見る。gh を書くときは、`--global --replace-all` で空の値を置いてから、`--global --add` で `!<gh の場所> auth git-credential` を足す（gist のホストも同じ）
  - `pkg/cmd/auth/shared/gitcredentials/updater.go`: `git credential reject`（`protocol=https`・`host=<ホスト>`）の後に `git credential approve`（アカウント名と gh のトークン）を流す
  - `internal/config/config.go`: トークンは、資格情報ストアのサービス名 `gh:<ホスト>`（`keyringServiceName`）に置く。`Logout` は、アカウントが 1 つならホストごと消し、ストアの空の名前とアカウント名の 2 つも消す
  - `pkg/cmd/auth/logout/logout.go`: 候補のアカウントが 1 つなら問わない。複数なら `What account do you want to log out of?` で選ばせる。ログインが無ければ `not logged in to any hosts`。終わると `Logged out of <ホスト> account <名前>`
  - `pkg/cmd/auth/status/status.go`: `Logged in to <ホスト> account <名前> (<置き場所>)` と `Git operations protocol: <値>`。置き場所は、ストアなら `keyring`、平文なら設定の場所の `hosts.yml`（`oauth_token` を置き換える）。ログインが無ければ `You are not logged into any GitHub hosts.`
  - `internal/ghcmd/cmd.go`: 新しい版があると、`A new release of gh is available:` と今の版と新しい版を出す。Git の資格情報のヘルパーに書く自分の場所は、`GH_PATH` が無ければ、`executable` で決める
- go-gh 2.16.1（gh 2.102.0 の `go.mod`）の `pkg/config/config.go`: 設定の場所は `GH_CONFIG_DIR` → `XDG_CONFIG_HOME` → Windows では AppData の `GitHub CLI`。状態・データ・キャッシュは、`XDG_STATE_HOME` などが無ければ LocalAppData の `GitHub CLI`
- go-keyring 0.2.8（同じ `go.mod`）の `keyring_windows.go`: 資格情報マネージャーの汎用資格情報に、`<サービス名>:<アカウント名>` の名前で置く（`credName`。gh では `gh:github.com:<GITHUB_USER>` と `gh:github.com:` になるはず）
- Git for Windows の起動スクリプト（`git-for-windows/MSYS2-packages` の `filesystem/profile`・`filesystem/bash.bashrc` と、`git-for-windows/build-extra` の `git-extra/env.sh`・`aliases.sh`・`git-prompt.sh`・`bash_profile.sh`）は、`XDG_CONFIG_HOME` を含まない（`grep` で見た）。自分用の bash 設定の `bashrc`（`ryo-aoki-pc/bash` の `54af594`）と WezTerm の設定（`lua/shells.lua` の `set_environment_variables` は `WEZTERM_SHELL_INTEGRATION` だけ）も設定しない
- Git for Windows の `system` の `credential.helper=manager` は、[Windows 11 の Git Bash での検証](git.md#実施手順--手順-3-補足-設定の-3-つの場所)で見た値
- scoop 本体（`ScoopInstaller/Scoop` の `master`、2026-09-30 のコミット `e6aa3b3`）のメッセージ: 導入は `'<名前>' (<版>) was installed successfully!`、入っているときは、名前を 1 つだけ渡せば `'<名前>' (<版>) is already installed.` と `Use 'scoop update <名前>' to install a new version.`（`libexec/scoop-install.ps1` の `$apps.length -eq 1` の分かれ。`… Skipping.` は名前を並べたときの分かれのもので、main のアプリには出ない。[windows-setup.md の付録](windows-setup.md#付録-シェルのツールの任意節のブロックの確認2026-10-08)）。更新は `Scoop was updated successfully!`、新しい版が無ければ `<名前>: <版> (latest version)`、動いているときは `Running process detected, skip updating.`。削除は `'<名前>' was uninstalled.`、入っていなければ `'<名前>' isn't installed.`、動いているときは `The following instances of "<名前>" are still running. Close them and try again.`

**構文と Windows PowerShell 5.1 との互換**（Linux の PowerShell 7.5.3 と PSScriptAnalyzer 1.25.0）:

- 手順書の `powershell` のブロック 10 個（Windows 11 で使うの手順 2〜4・6、Windows 11 の更新の手順 1、Windows 11 のロールバックの手順 1・3〜6）を取り出し、PowerShell 7.5.3 の構文解析器に通した（構文の誤り 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）と、既定の規則の Error・Warning を当てた（指摘 0）。同じ設定で、`??` を書いたファイル・`Get-Content -AsByteStream` を書いたファイル・`}` の足りないファイルは、それぞれ指摘された
- 最後に（2026-10-08、手順書の今のブロックを取り出し直して）、10 個を構文解析器にもう一度通し（誤り 0）、互換の規則を `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows PowerShell 5.1 のプロファイル 3 つ。Windows Server 2016・Windows Server 2019・Windows 10 Pro）・`PSUseCompatibleCmdlets`（`desktop-5.1.14393.206-windows`）にして当てた。互換の指摘も既定の規則の指摘も 0 個（[windows-setup.md の付録](windows-setup.md#付録-シェルのツールの任意節のブロックの確認2026-10-08)と同じ回）

**模擬**（Linux の PowerShell 7.5.3 と git 2.43.0）:

- 管理者の判定（`WindowsPrincipal`。Linux では使えない）を `$false` に置き換え、出力は `Out-String -Width 200` で受けた。渡った引数を記録して Scoop のソースと同じ形の行を返す偽物の `scoop`（`install` で偽物の `gh` を shims に置き、`uninstall` で消す）と、`--version`・`auth status`・`auth login`・`auth logout` に答える偽物の `gh` を `PATH` の先頭に置いた。git は本物で、`HOME` を使い捨てのフォルダーにし、`GIT_CONFIG_SYSTEM` で `credential.helper = manager` の `system` の設定を読ませ、`manager` には受け取った操作と入力を記録するだけの偽物の `git-credential-manager` を置いた
- Windows 11 で使うの手順 2: 入れる前は `GitCred : credential.helper manager`・`Gh` は空、入れた後は `Gh` が偽物の shim の場所。`gh auth setup-git` と同じ形の行（`--replace-all` の空の値と、`--add` の `!'C:\Users\u\scoop\apps\gh\current\bin\gh.exe' auth git-credential`。gist のホストも）を `--global` に置くと、`GitCred` にその行が並んだ。git を `PATH` から外すと、`Git` と `GitCred` が空になり、エラーは出なかった
- Windows 11 で使うの手順 3: 1 回目は偽物の導入の行・版の 2 行・shim の場所。2 回目は偽物の `is already installed. Skipping.` の後に同じ行
  - 偽物の警告を、名前 1 つのときの形（`WARN  'gh' (2.102.0) is already installed.` と `Use 'scoop update gh' to install a new version.`）に直して流し直した（2026-10-08 の 2 回目）。2 回目はその 2 行の後に、版の 2 行と shim の場所が出た
- Windows 11 で使うの手順 6: ログインの前は偽物の gh の `You are not logged into any GitHub hosts.` と `credential.helper manager`、偽物の `gh auth login` の後は `(keyring)` の行と `Git operations protocol: https` と `credential.helper manager`
- Windows 11 の更新の手順 1: 偽物の `Scoop was updated successfully!` と `gh: 2.102.0 (latest version)` の後に版の 2 行。偽物の scoop に `update` と `update gh` が渡った
- Windows 11 のロールバックの手順 1: 偽物の gh に `auth logout` が渡った（2 回目は `not logged in to any hosts`）
- Windows 11 のロールバックの手順 3: github.com と gist.github.com の gh の行（空の値を含む）だけが `--global` から消え、`credential.https://example.com.helper store` は残った。最後のコマンドは `credential.helper manager` と、その `example.com` の行を出した。2 回目は何も変えなかった。`credential.https://github.com.helper` が gh でない値（`store`）のときも残した
- Windows 11 のロールバックの手順 4: 偽物の `git-credential-manager` に `erase` と、`protocol=https`・`host=github.com` の 2 行が渡った。bash から CR LF の 2 行を `git credential reject` に渡したときも、ヘルパーには CR の無い 2 行が渡った（Windows PowerShell 5.1 のパイプは CR LF で送る。5.1 では確かめていない）
- Windows 11 のロールバックの手順 5: 偽物の `'gh' was uninstalled.` の後、`Get-Command` の行は何も出さなかった（2 回目は偽物の `'gh' isn't installed.`）
- Windows 11 のロールバックの手順 6: `$env:APPDATA` と `$env:LOCALAPPDATA` を使い捨てのフォルダーにし、`GitHub CLI` のフォルダー（`hosts.yml` と `extensions`）を作ってから貼ると、`False` が 2 行出た。2 回目もエラー無しで `False` が 2 行
- 最後に（2026-10-08、手順書の今のブロックを取り出し直して）、偽物を作り直して全部を流し直した（偽物の `scoop` の警告は、名前 1 つのときの形）。上の各項目と同じ結果だった（手順 2 の git が無いときにエラーが出ないこと、ロールバックの手順 3 で gh の行だけが消え、`store` の行が残ること、手順 4 でヘルパーに `erase` と 2 行が渡ること、手順 5・6 の 2 回目を含む）
- 本物の scoop と gh の表示、Windows の `Get-Command` が返す shim のパス、資格情報マネージャー、Git Credential Manager は、Windows で動かしていないので確かめていない

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（scoop での導入・更新・削除）
1. `gh auth login` の問いを Windows PowerShell 5.1 の conhost の窓で答えること、ワンタイムコードがクリップボードに入ること、既定のブラウザが開くこと、資格情報マネージャーに置かれること
1. Git の認証に `Y` と答えたときに、Git Credential Manager に gh のトークンが入ることと、ロールバックの手順 4 で消えること
1. Git Bash・PowerShell 7・cmd の gh が、同じ設定（`%APPDATA%\GitHub CLI`）とログインを使うこと
1. SSH のセッション（scoop の shim と、資格情報マネージャーを読めるか）、arm64 の Windows、winget の gh があるとき

### 実施手順 / 手順 4: 補足: 認証

`gh auth login` は対話で進む。SSH 越しの端末でブラウザを開けない場合は、表示されるワンタイムコードを手元のブラウザの `https://github.com/login/device` に入れる形になる。**この手順はコンテナでは実行していない**（実機では認証済みで常用している）。

### 選択した方針

```
$ dnf -q list --showduplicates gh | tail -5
gh.aarch64                        2.97.0-2.el10_2                        epel
gh.aarch64                        2.101.0-1                              gh-cli
gh.armv6hl                        2.101.0-1                              gh-cli
gh.i386                           2.101.0-1                              gh-cli
gh.x86_64                         2.101.0-1                              gh-cli
```
