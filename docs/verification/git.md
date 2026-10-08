# Git のセットアップ手順（AlmaLinux 10 は AppStream / Windows 11 は winget の Git for Windows）の検証記録

[手順書](../git.md)

## 最新の確認範囲（Windows 11）

- 通したこと（どれも Windows 11 Pro の同じクリーン VM。実機ではない）
  - 2026-10-06〜07: Windows 節の新規導入・PATH の手順 2・3・5、非対話 Bash と隔離した `global` での共通手順 3〜7・9〜11（[付録](#付録-windows-11-pro-の-vm-での新規導入の検証2026-10-06)）
  - 2026-10-08: スタートから開いた対話の Git Bash に右クリックのメニューで貼り、実ユーザーの `global` で実施手順 1・3〜11（`system` の `pull.ff=only` を一時的に置いて手順 8 の分岐も）、ロールバックの手順 1〜6、更新の手順 2（[付録](#付録-windows-11-pro-の-vm-での対話の-git-bash-による通し検証2026-10-08)）
- 確認していないこと
  - 本人の名前・メールアドレスと、外部のリモートへの認証・push・pull
  - 新しい版に上げる更新、arm64 の Windows
- 機能試験の初回ホスト側通信の終了コード 1 と、後に回収したゲストの成功は別々に記録した。以降の既存記録は、各実施日・対象版・範囲に従う履歴として保持した

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> - **AlmaLinux 10 は x86_64 のクリーン VM で実施手順を本実行済み（2026-10-06）で、コンテナでも検証した**。実機では本実行していない
> - **Windows 11 は、実機の Git Bash で `HOME` を使い捨てのディレクトリにして流した**（その PC の `~/.gitconfig` には書いていない）
> - **Git for Windows を winget で入れる・上げる・外すブロックは、Windows で流していない**（[Windows 11 で Git for Windows を入れる](../git.md#windows-11-で-git-for-windows-を入れる)・[更新](../git.md#更新)の手順 2・[ロールバック](../git.md#ロールバック)の手順 6）。詳しくは[対象と検証環境](#対象と検証環境)

### 実施手順 / 手順 3: 補足: 設定の 3 つの場所

- git は設定を `system`（全ユーザー）→ `global`（自分のユーザー）→ `local`（リポジトリ）の順に読み、後で読んだ値を使う
- AlmaLinux 10 の `system` は `/etc/gitconfig`（RPM は置かない）、`global` は `~/.gitconfig`、`local` は各リポジトリの `.git/config`
- Windows の `system` は、Git for Windows の `C:/Program Files/Git/etc/gitconfig`。インストーラの画面で選んだ改行の扱いや `git pull` の動作が、ここに書かれる
- インストーラの改行の既定の選択（Checkout Windows-style, commit Unix-style line endings）は、`core.autocrlf=true`
- 本書は `system` を変えず、`global` に書いて上書きする（管理者の権限が要らない）
- 検証コンテナでは、git を入れた直後の 2 つ目のコマンドは何も出さなかった
- Windows の模擬（`/etc/gitconfig` に `core.autocrlf=true` などの 4 つを置いた）では、次の 4 行が出た。キーの名前は小文字で出る:

```
system	file:/etc/gitconfig	core.autocrlf=true
system	file:/etc/gitconfig	pull.rebase=false
system	file:/etc/gitconfig	pull.ff=only
system	file:/etc/gitconfig	init.defaultbranch=master
```

- Windows 11 の PC（Git for Windows 2.55.0.windows.3）の Git Bash では、`system` の行が 13 行出た
  - その PC のインストーラの選択では、改行は `core.autocrlf=false`（Checkout as-is, commit as-is）、`git pull` は `pull.rebase=true` で、`pull.ff` は無かった
  - `global` の行は出ない（検証では `HOME` を使い捨てのディレクトリにした。[付録](#付録-windows-11-の-git-bash-での検証記録2026-09-30)）

```
system	file:C:/Program Files/Git/etc/gitconfig	diff.astextplain.textconv=astextplain
system	file:C:/Program Files/Git/etc/gitconfig	filter.lfs.clean=git-lfs clean -- %f
system	file:C:/Program Files/Git/etc/gitconfig	filter.lfs.smudge=git-lfs smudge -- %f
system	file:C:/Program Files/Git/etc/gitconfig	filter.lfs.process=git-lfs filter-process
system	file:C:/Program Files/Git/etc/gitconfig	filter.lfs.required=true
system	file:C:/Program Files/Git/etc/gitconfig	http.sslbackend=schannel
system	file:C:/Program Files/Git/etc/gitconfig	core.autocrlf=false
system	file:C:/Program Files/Git/etc/gitconfig	core.fscache=true
system	file:C:/Program Files/Git/etc/gitconfig	core.symlinks=true
system	file:C:/Program Files/Git/etc/gitconfig	pull.rebase=true
system	file:C:/Program Files/Git/etc/gitconfig	credential.helper=manager
system	file:C:/Program Files/Git/etc/gitconfig	credential.https://dev.azure.com.usehttppath=true
system	file:C:/Program Files/Git/etc/gitconfig	init.defaultbranch=master
```

### 実施手順 / 手順 5: 補足: 3 つの設定

**pull.rebase**

- 載せ直すのは、まだ push していない自分のコミットだけ。リモートの履歴は書き換えない
- `true` は、ローカルのマージコミットを平らにして載せ直す。マージコミットを残したいなら `merges` にする
- その回だけマージにするなら、`git pull --no-rebase`

**rebase.autoStash**

- `git pull` が rebase するときも、この設定で stash する（`git pull --autostash` と同じ）
- stash を戻すときに衝突したら、変更は stash に残る。検証コンテナで、自分のコミットは無く、同じ行を変えていたときの実測:

```
Updating <HASH>..<HASH>
Created autostash: <HASH>
Fast-forward
 f | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
Applying autostash resulted in conflicts.
Your changes are safe in the stash.
You can run "git stash pop" or "git stash drop" at any time.
```

- このとき `git status --short` は `UU f`、`git stash list` は `stash@{0}: autostash` だった。衝突を解いた後、`git stash drop` で消す

**core.autocrlf**

- `false` では、CRLF のファイルは CRLF のまま、LF のファイルは LF のまま、コミットもチェックアウトもされる（手順 9 で確かめる）
- リポジトリの中で改行を揃えたいときは、そのリポジトリの `.gitattributes` に書く（`* text=auto` など）。`.gitattributes` の `text` は `core.autocrlf` より優先される
- 検証コンテナで、`core.autocrlf=false` のまま `* text=auto` の `.gitattributes` を置き、CRLF のファイルを add すると、`i/lf` で入った

### Windows 11 で Git for Windows を入れる / 手順 3: 補足: winget の定義と、黙って入れたときの選択

**winget の定義**（`Git.Git` 2.55.0.5。2026-10-03 の winget-pkgs）

- インストーラは、上流の GitHub のリリースの `Git-2.55.0.5-64-bit.exe`（Inno Setup）。winget は、定義に書かれた sha256 を確かめてから動かす（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
- 定義のスコープは `user` と `machine` の 2 つだが、どちらも同じインストーラで、winget はスコープに合わせたスイッチを渡さない。渡すのは `/SP- /SILENT /SUPPRESSMSGBOXES /NORESTART` と `/LOG=…` だけ
- 入れる先は、インストーラが権限で決める。管理者の権限があれば `C:\Program Files\Git` に入れ、PC 全体の `PATH` とレジストリ（`HKLM`）に書く。Administrators の一員が管理者でない窓から動かすと、インストーラが UAC で昇格を求める（定義の `ElevationRequirement: elevatesSelf`）
- `--scope machine` は、PC 全体に入ることを winget にもそろえるため。付けないと、winget は `user` の項目を選ぶ（winget の設定の既定）
- arm64 の Windows では、同じ定義の `Git-2.55.0.5-arm64.exe` が選ばれる
- 上流は 2026-09-28 に 2.56.0 を出したが、2026-10-03 の winget-pkgs にはまだ無い。載ると、この手順でもそれが入る（2.56.0 から、内部のパスが `mingw64` から `ucrt64` に変わった。上流のリリースノート）

**黙って入れたときの選択**（画面のインストーラの既定と同じ。上流の `install.iss` を読んだ）

| 画面 | 既定の選択 | 書かれるもの |
|---|---|---|
| PATH | Git from the command line and also from 3rd-party software | PC 全体の `PATH` に `C:\Program Files\Git\cmd` |
| 既定のブランチ名 | Let Git decide | `system` に `init.defaultBranch=master` |
| エディタ | Use Vim (the ubiquitous text editor) as Git's default editor | `core.editor` は書かない |
| HTTPS | Use the native Windows Secure Channel library | `system` に `http.sslBackend=schannel` |
| 改行 | Checkout Windows-style, commit Unix-style line endings | `system` に `core.autocrlf=true` |
| 端末 | Use MinTTY | — |
| `git pull` | Merge | `system` に `pull.rebase=false` |
| 認証 | Git Credential Manager | `system` に `credential.helper=manager` |
| ほか | ファイルシステムのキャッシュは有効、シンボリックリンクは無効（開発者モードが無いとき） | `system` に `core.fscache=true`・`core.symlinks=false` |
| 部品 | エクスプローラーの「Open Git Bash here」「Open Git GUI here」・Git LFS・`.git*` と `.sh` の関連付け | — |

- 入れない部品: デスクトップのアイコン、Windows Terminal の Git Bash のプロファイル、毎日の更新の確認
- スタートメニューの「Git」フォルダーには、Git Bash・Git CMD・Git GUI が入る
- `system` の改行・`git pull`・ブランチ名は、[実施手順](../git.md#実施手順)の手順 5・6 で `global` に書いて上書きする
- 上げるとき・入れ直すときは、前に入れたときの選択を引き継ぐ（インストーラが前の選択を覚えている）
- 選択は `--custom '/o:CRLFOption=CRLFCommitAsIs'` のように渡して変えられるが、本書では渡さない（[選択した方針](../reference/git.md#選択した方針)）

### 改行を変換して clone したリポジトリを直す / 手順 3: 補足: 書き直し方

- `git rm -r --cached .` で追跡を外してから `git reset --hard` すると、追跡しているファイルがすべて今の設定で書き直される。追跡していないファイルには触れない
- 検証コンテナで、`git checkout-index --force --all` も試したが、ファイルは LF になったものの `git status` に `M` が残った
- Windows 11 の Git Bash でも、`git -c core.autocrlf=true clone` した 2 ファイルのリポジトリ（CRLF の 1 行を足した）で、この節の手順 1 が ` M y.txt` と `2`、手順 3 が `0` を出し、手順 4 の後は 2 つとも `w/lf` になった

### 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 の git を、同じ `global` の設定にする。pull は rebase で autostash を有効にし、改行は変換しない（`core.autocrlf=false`）。ほかに推奨の設定を入れる
- **進め方**: AlmaLinux 10 は AppStream の `git` を入れる。Windows 11 は、Git for Windows を winget の `Git.Git` で PC 全体（`C:\Program Files\Git`）に入れ（[Windows 11 で Git for Windows を入れる](../git.md#windows-11-で-git-for-windows-を入れる)）、Git Bash に同じブロックを貼る。どちらの OS でも `git config --global` で書く。**読者が書き換えるのは手順 1 の 2 つの変数だけ**
- **状態**: **AlmaLinux 10 は x86_64 のクリーン VM で実施手順を本実行済み（2026-10-06）、コンテナでも検証済み（2026-09-29）。Windows 11 は、実機の Git Bash で流した（2026-09-30。`global` は使い捨ての `HOME`）。Git for Windows を winget で入れる・上げる・外すブロックは、Windows で流していない（2026-10-03 に足した）**
  - 下表の検証コンテナで、**この文書のコードブロックを抜き出したもの**を、一般ユーザーで手順 1〜11 → [改行を変換して clone したリポジトリを直す](../git.md#改行を変換して-clone-したリポジトリを直す) → [ロールバック](../git.md#ロールバック)の順に流した
  - Windows の模擬として、`/etc/gitconfig` に Git for Windows のインストーラの選択で書かれうる値（`core.autocrlf=true` など 4 つ）を置いて、手順 1・3〜11 をもう 1 度流した
  - 確認したこと: 14 のキーが `global` で効く、`system` の値に勝つ、`pull.ff=only` が rebase を止め手順 8 で通る、CRLF のファイルが変換されずに入る、pull が rebase と autostash をする
  - 2026-09-30: 下表の Windows 11 の PC の Git Bash で、この文書のブロックを抜き出したものを流した（[付録](#付録-windows-11-の-git-bash-での検証記録2026-09-30)）
    - `HOME` を使い捨てのディレクトリにしたので、`global` はそこに書かれた。その PC の `~/.gitconfig` は変えていない（前後で md5 が同じ）。`system` はインストーラが書いた本物
    - 手順 1・3〜7・9〜11（手順 8 は `pull.ff` が空なので飛ばした）、[改行を変換して clone したリポジトリを直す](../git.md#改行を変換して-clone-したリポジトリを直す)の手順 1〜4、[ロールバック](../git.md#ロールバック)の手順 1〜3・5
    - 確認したこと: インストーラが書いた `system` の値（手順 3 の補足）、`global` の場所（Git Bash・PowerShell・cmd で同じ）、日本語のファイル名がそのまま出ること、CRLF のファイルが変換されずに入ること、pull の rebase と autostash、`rerere` が覚えた解き方を当てること
  - 2026-10-03: [Windows 11 で Git for Windows を入れる](../git.md#windows-11-で-git-for-windows-を入れる)と、[更新](../git.md#更新)の手順 2（winget で上げる）・[ロールバック](../git.md#ロールバック)の手順 6（winget で外す）を足した。**Windows の実機では流していない**（書いた環境のクラウドの Linux のコンテナでは、Windows を動かせない）
    - 確かめたこと: winget の定義（`Git.Git` 2.55.0.5 のスコープ・インストーラの種類・スイッチ・sha256）、インストーラの sha256 と Authenticode の署名者、上流の `install.iss`（入れる先・権限・黙って入れたときの選択・`system` に書く値・使われているときの動き）、winget のソース（Inno Setup のインストーラに渡すスイッチ・スコープの既定・削除のコマンド）（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査、偽の `winget` に渡る引数（[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
    - 確かめていないこと: Windows で貼ること（その節のすべての手順・更新・削除）、UAC が出ないこと、`system` に書かれる値、Git Bash が開くこと、公式のインストーラで入れた PC を winget で上げること、arm64 の Windows
  - 2026-10-05: 元値・スコープの記録とロールバック、および改行を直す節の未追跡ファイルの分岐を修正した。クラウドの Linux の Git 2.52.0 で、一時的な `global`・`system` の設定ファイルとリポジトリだけを使って確認した
    - `pull.ff` は、両スコープそれぞれの未設定・`only`・`true`・`false` の 16 通りで、変更する場合だけ戻し、元の値とスコープが復元されることを確認した
    - 未追跡ファイルだけの場合と追跡ファイルにも変更がある場合で、改行の修正後も未追跡ファイルと以前の stash が残り、今回の変更だけを戻せることを確認した。実機の設定は変更していない
  - **確認していないこと**: AlmaLinux 10 の実機、aarch64、利用中の既存の `~/.gitconfig` との組み合わせ
    - Git for Windows のインストーラの既定の選択で書かれる値（`core.autocrlf=true` など）。検証した PC は別の選択だった（[Windows 11 で Git for Windows を入れる](../git.md#windows-11-で-git-for-windows-を入れる)は、この既定で入る。上流のソースを読んだだけ）
    - Git Bash の端末（mintty）に貼る操作そのもの（検証では、ブロックを 1 つのシェルで順に読み込んだ）

| 項目 | 検証コンテナ | Windows 11 の PC（Git Bash） | 実機（参考。未実施） |
|---|---|---|---|
| 実施日 | 2026-09-29 | 2026-09-30 | — |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1） | Windows 11 Pro 25H2（ビルド 26200）/ x86_64 | AlmaLinux 10.2 / aarch64（Raspberry Pi 5） |
| git | `git-2.52.0-1.el10`（AppStream） | Git for Windows 2.55.0.windows.3（`C:\Program Files\Git`、GNU bash 5.3.15） | `git 2.52.0`（AppStream） |
| `system` | 無し（Windows の模擬では 4 行を置いた） | インストーラが書いた 13 行（[手順 3](../git.md#実施手順) の補足） | — |
| `~/.gitconfig` | 無し（手順 4〜6 で作った） | 使い捨ての `HOME` に作った（その PC の `~/.gitconfig` には書いていない） | `[core] autocrlf` と `[user]` だけ（[git-delta.md](git-delta.md#対象と検証環境) の記録） |

- 実機の列は、この手順を適用した結果ではなく、ほかの手順書に残っている現時点の状態

[Windows 11 で Git for Windows を入れる](../git.md#windows-11-で-git-for-windows-を入れる)の節（前提にしている環境。Windows では流していない）:

| 項目 | 値 |
|---|---|
| OS | Windows 11 / x64（ほかの Windows の手順書の実機の記録と同じ PC を想定） |
| PowerShell | 管理者の Windows PowerShell 5.1 |
| winget | Windows 11 の「アプリ インストーラー」に入っているもの |
| Git for Windows | 2.55.0.5（winget の `Git.Git` の 2026-10-03 の最新の定義）。`C:\Program Files\Git` |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../git.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${GIT_USER_NAME}` | `user.name`。コミットの作者の名前 | `Taro Yamada` |
> | `${GIT_USER_EMAIL}` | `user.email`。コミットの作者のメールアドレス | `taro@example.com`、GitHub の noreply のアドレス |
>
> 出力例の値は `<GIT_USER_NAME>` / `<HASH>` などのプレースホルダで書いてある。バージョン（`2.52.0`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 検証コンテナ | Windows 11 の PC |
|---|---|---|
| git | 未導入（手順 2 で入れた） | Git for Windows 2.55.0.windows.3 が入っていた |
| `system`（AlmaLinux 10 は `/etc/gitconfig`） | 無し（Windows の模擬では、2 回目の前に置いた） | `C:/Program Files/Git/etc/gitconfig` に、インストーラが書いた 13 行（[手順 3](../git.md#実施手順) の補足） |
| `~/.gitconfig` | 無し | その PC の `C:\Users\<WIN_USER>\.gitconfig` にはキーが 4 つあった（検証では使い捨ての `HOME` にしたので、読まれていない） |

- [Windows 11 で Git for Windows を入れる](../git.md#windows-11-で-git-for-windows-を入れる)は、Git for Windows が入っていない PC を前提にしている（Windows では流していない）

### 選択した方針

- **git は AppStream の RPM**
  - Homebrew の git は 2.55.0 で新しいが、git はシステムの道具（dnf で入れる gh などが依存する）なので、RPM の `/usr/bin/git` に揃える
  - 本書の設定で一番新しいのは `push.autoSetupRemote`（git 2.37）で、2.52.0 で足りる
- **`global` に書き、`system` は変えない**
  - 管理者の権限が要らず、AlmaLinux 10 と Windows で同じコマンドになる
  - Windows の `system` はインストーラが書く場所なので、そこを直さず `global` で上書きする
- **Windows は Git Bash に同じ bash のブロックを貼る**
  - PowerShell 向けに書き分けない。git のコマンドは同じで、変数の書き方だけが違うため
  - Git Bash のホームは `/c/Users/<WIN_USER>`（[windows-openssh-server.md](../windows-openssh-server.md) の実測）で、`global` は `C:/Users/<WIN_USER>/.gitconfig` だった
    - Windows 11 の PC で、`git config --global --list --show-origin` の場所を見て確かめた（値は読んでいない）
- **pull は `pull.rebase=true`**（依頼どおり）
  - `merges` はマージコミットを残すが、ふだんのブランチでマージコミットを作らないなら `true` で足りる
  - `pull.ff=only` は分岐したときに止まるだけで、rebase の方針と合わない
- **推奨の設定は、既定を変えても困りにくく、日常の操作が楽になるものだけ**
  - 選んだもの・入れなかったものは、手順 6 の補足にある
  - エディタ・署名・認証の設定は、人や PC によって違うので入れていない

Windows 11 で Git for Windows を入れる経路を比べた（2026-10-03 時点）:

### 完了時点の状態

**検証コンテナでの `~/.gitconfig`**（Windows 11 の Git Bash の使い捨ての `HOME` でも、同じ中身だった。AlmaLinux 10 の実機では本実行していない）:

```
[user]
	name = <GIT_USER_NAME>
	email = <GIT_USER_EMAIL>
[pull]
	rebase = true
[rebase]
	autoStash = true
[core]
	autocrlf = false
	quotepath = false
[init]
	defaultBranch = main
[fetch]
	prune = true
[push]
	autoSetupRemote = true
[rerere]
	enabled = true
[merge]
	conflictStyle = zdiff3
[diff]
	algorithm = histogram
[branch]
	sort = -committerdate
[tag]
	sort = version:refname
```

- Windows の模擬では、手順 8 の `[pull]` の `ff = true` が加わった

### 注意点 / 手順 0: 本文中の記録

  - その PC では環境変数 `HOME` が `C:\Users\<WIN_USER>` に設定されていた。`HOME` の無い PC は試していない

### 注意点 / 手順 0: 本文中の記録

  - 2026-10-03 の winget の定義はまだ 2.55.0.5 で、本書では 2.56.0 を試していない

### 付録: コンテナでの検証記録（2026-09-29）

x86_64 のクラウドホストで `dockerd` を動かし、`docker run -d --network host quay.io/almalinuxorg/almalinux:10 sleep infinity` で使い捨てのコンテナを立てた（`docker.io/library/almalinux:10` は `429 Too Many Requests` で取れなかった）。実機と Windows には何も加えていない。

- 検証環境だけの変更: dnf がホストのプロキシを通るように、`/etc/dnf/dnf.conf` に `proxy=` を足し、AlmaLinux のリポジトリを `mirrorlist` から `baseurl` に変え、プロキシの CA を取り込んだ
- 実行ごとに一般ユーザー（NOPASSWD の sudo）を作り直し、**この文書の bash のコードブロックを機械的に抜き出したもの**を、そのユーザーの `bash -s` に流した。書き換えたのは手順 1 の 2 つの値（`Test User` / `test@example.com`）だけ
- `bash -s` には端末が無いので、端末での出力は別に擬似端末（`script`）の中で流して取った
- Windows の模擬の `/etc/gitconfig` は、`core.autocrlf = true`・`pull.rebase = false`・`pull.ff = only`・`init.defaultBranch = master` の 4 行

| 実行 | `/etc/gitconfig` | 流した手順 | 結果 |
|---|---|---|---|
| 1 | 無し | 手順 1〜7・9〜11（手順 8 は `pull.ff` が空なので飛ばした）、[改行を変換して clone したリポジトリを直す](../git.md#改行を変換して-clone-したリポジトリを直す)の手順 1〜4、[更新](../git.md#更新)の手順 1、[ロールバック](../git.md#ロールバック)の手順 1〜3・5 | 手順 2 は `Package git-2.52.0-1.el10.x86_64 is already installed.`（実行 1 の前に、別のユーザーで同じ `sudo dnf install -y git` を流して入れた。そのときは依存を合わせて 74 パッケージが入った）。手順 7 は 14 行が `global`、`pull.ff` は空。手順 9 は `i/crlf  w/crlf`・`main`・`branch 'main' set up to track 'origin/main'.`。手順 10 は `Created autostash` → `Applied autostash.` → `Successfully rebased`、履歴は 1 本、` M crlf.txt` が残った。直す節は、`git -c core.autocrlf=true clone` した 2 ファイルのリポジトリに、CRLF の 1 行を足してから流し、手順 1 で ` M y.txt` と `2`、手順 3 で `0`、手順 4 の後は `w/lf` で差分は足した 1 行だけ。更新は `Nothing to do.`。ロールバックの手順 5 は何も出さなかった |
| 2 | Windows の模擬 | 手順 1・3〜11 | 手順 3 で `system` の 4 行が出た。手順 7 は 14 行が `global`、`pull.ff` だけ `system	only`。手順 8 で `global	true`。手順 9・10 は実行 1 と同じ結果。`~/.gitconfig` の `[pull]` に `ff = true` が加わった |
| 3 | Windows の模擬 | 手順 1・4〜7・9〜11（手順 8 を飛ばした） | 手順 10 の `git pull` が `fatal: Not possible to fast-forward, aborting.` で止まり、履歴は分かれたまま、` M crlf.txt` は残った |
| 4 | 無し | 擬似端末の中で、手順 1・4〜6・9〜11 | 手順 9 の `git push` と手順 10 の `git pull` の、端末での出力を取った（手順 9・10 の補足） |

個別に確かめたこと（同じコンテナの使い捨てのリポジトリ。設定は主に `git -c` で 1 回ずつ変えた）:

| 確かめたこと | 結果 |
|---|---|
| 設定が無いときの `git init` | `hint:` が 13 行出て、ブランチは `refs/heads/master` |
| `core.autocrlf=true` で CRLF のファイルを add | `i/lf    w/crlf` |
| `core.quotepath=true` の `git status --short` | `?? "\346\227\245\346\234\254\350\252\236.txt"` |
| `* text=auto` の `.gitattributes` と `core.autocrlf=false` で CRLF のファイルを add | `i/lf    w/crlf  attr/text=auto` |
| autostash を戻すときの衝突 | `Applying autostash resulted in conflicts.`、`UU f`、`stash@{0}: autostash` |
| `pull.ff=false` と `pull.rebase=true` | rebase された |
| `pull.rebase=false` | `Merge made by the 'ort' strategy.` でマージコミットができた。擬似端末では、その前に `GIT_EDITOR` のエディタが `MERGE_MSG` を開いた |
| `rebase.autoStash` 無しで、未コミットの変更がある pull | `error: cannot pull with rebase: You have unstaged changes.` |
| 直す節の代わりに `git checkout-index --force --all` | ファイルは `w/lf` になったが、`git update-index --refresh` の後も `git status` に `M` が残った |
| `git config --global --unset` で、最後のキーを外す | `~/.gitconfig` からその節も消えた。無いキーの `--unset` は何も出さない（終了コード 5） |
| `user.name`・`user.email` 無しの `git commit` | `Author identity unknown` と `fatal: unable to auto-detect email address` で止まった |

#### 未確認事項

- 実機（AlmaLinux 10）での本実行と、既存の `~/.gitconfig`（`[core] autocrlf` がある）との組み合わせ
- Windows 11 の Git Bash での実行（Git for Windows のインストーラが `system` に書く値、`global` の置き場所、日本語のファイル名の表示）
- Windows の PowerShell・cmd から呼ぶ git が、同じ `global` を読むこと
- aarch64 での実行
- `rerere` が覚えた解き方を当てるところ
- [更新](../git.md#更新)で新しい版に上がるところ（新しい版が無い状態で `sudo dnf upgrade git` を流しただけ）

---

### 付録: Windows 11 の Git Bash での検証記録（2026-09-30）

前の付録の未確認事項のうち、Windows 11 の Git Bash での実行、`global` の置き場所、PowerShell・cmd から呼ぶ git、`rerere` を、次の PC で確かめた。

**環境**:

- Windows 11 Pro 25H2（ビルド 26200、日本語）/ x86_64 のノート PC（AMD Ryzen AI MAX+ 395）。[windows-openssh-server.md](../windows-openssh-server.md) を通した PC と同じ
- Git for Windows 2.55.0.windows.3（`C:\Program Files\Git`、GNU bash 5.3.15、`MSYSTEM=MINGW64`）
- 流したのは Claude Code の Bash（Git for Windows の bash）。端末（mintty）ではなく、出力はパイプに出た

**流し方**:

- この文書の `bash` のブロックを機械的に抜き出し（リストの字下げだけ外す）、1 つのスクリプトから順に `.`（source）で読み込んだ。同じシェルに貼り続けたときと同じく、変数は残る
- スクリプトの先頭で `export HOME=$(mktemp -d /tmp/gitmd-home.XXXXXX)` とした
  - `global` はそこの `.gitconfig` に書かれ、その PC の `~/.gitconfig` は変わらなかった（前後の md5 が同じ）
  - `system` は、インストーラが書いた本物（`C:/Program Files/Git/etc/gitconfig`）を読んだ
- 書き換えたのは手順 1 の 2 つの値（`Test User` / `test@example.com`）だけ
- 手順 2 は Windows なので飛ばした。手順 8 は、手順 7 の `pull.ff` が空なので飛ばした
- 改行を直す節の前に、手順書の外で、LF の 2 ファイルのリポジトリを `git -c core.autocrlf=true clone` し、CRLF の 1 行を足した（前の付録と同じ作り方）

| 手順 | 結果 |
|---|---|
| 1 | `GIT_USER_NAME  = Test User`、`GIT_USER_EMAIL = test@example.com` |
| 3 | `git version 2.55.0.windows.3`。`system` の 13 行（[手順 3](../git.md#実施手順) の補足）。`global` の行は無い |
| 4 | `user.name Test User`、`user.email test@example.com` |
| 5・6 | 何も出ない |
| 7 | 14 行が `global`、`pull.ff` は空 |
| 9 | `?? a.txt`・`?? crlf.txt`・`?? 日本語.txt`、`i/crlf  w/crlf  attr/  crlf.txt`、`main`、`* [new branch]      main -> main` と `branch 'main' set up to track 'origin/main'.` |
| 10 | `Created autostash: <HASH>`、`Rebasing (1/1)Applied autostash.`（パイプでは同じ行に続く）、`Successfully rebased and updated refs/heads/main.`。`git log` は `b: b.txt` → `a: 2` → `first` の 1 本で、` M crlf.txt` が残った |
| 11 | 何も出ない |
| 改行を直す 1〜4 | 手順 1 は ` M y.txt` と `2`、手順 2 は `Saved working directory and index state WIP on main: <HASH> init`、手順 3 は `0` で `git status --short` は空、手順 4 は `modified:   y.txt` と `Dropped refs/stash@{0}`。2 つのファイルは `i/lf    w/lf` になり、差分は足した 1 行だけ（CR は付かない） |
| ロールバック 1〜3・5 | 何も出ない。使い捨ての `HOME` の `.gitconfig` は 0 バイトになった |

**手順書の外で確かめたこと**:

| 確認 | 結果 |
|---|---|
| `global` の場所 | Git Bash・PowerShell 7・cmd の `git config --global --list --show-origin` が、どれも `file:C:/Users/<WIN_USER>/.gitconfig` を示した（場所とキーの数だけを見て、値は読んでいない）。その PC では、PowerShell の `git` は `C:\Program Files\Git\mingw64\bin\git.exe`、環境変数 `HOME` は `C:\Users\<WIN_USER>` だった |
| `rerere` | 使い捨ての `HOME` で `rerere.enabled=true`・`merge.conflictStyle=zdiff3` にし、同じ衝突を 2 回起こした。1 回目は `Recorded preimage for 'f'`、解いてコミットすると `Recorded resolution for 'f'.`。2 回目は `Resolved 'f' using previous resolution.` で、ファイルは解いた中身になり、`git status --short` は `UU f` のまま（`git add` はされない） |
| `zdiff3` | 衝突の表示に、共通の祖先の段（`\|\|\|\|\|\|\| <HASH>` の後に元の行）が出た |

#### 未確認事項

- AlmaLinux 10 の実機での本実行と、既存の `~/.gitconfig`（`[core] autocrlf` がある）との組み合わせ
- Git for Windows のインストーラの既定の選択で書かれる値（`core.autocrlf=true` など）と、`git pull` の「Only ever fast-forward」で書かれる `pull.ff=only`
- Git Bash の端末（mintty）に貼る操作そのもの、環境変数 `HOME` の無い Windows の PC
- aarch64 での実行、[更新](../git.md#更新)で新しい版に上がるところ

---

### 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、winget の定義・インストーラ・上流と winget のソースを読んだ記録。[Windows 11 で Git for Windows を入れる](../git.md#windows-11-で-git-for-windows-を入れる)・[更新](../git.md#更新)の手順 2・[ロールバック](../git.md#ロールバック)の手順 6 は、これをもとに書いた。

**winget の定義**: winget-pkgs（2026-10-03 の `master`、コミット `c612893`）の `manifests/g/Git/Git` の一番新しい版は `2.55.0.5`（`2.56.0` のディレクトリは無い）。`Git.Git.installer.yaml` の抜粋（arm64 の 2 つは、`Git-2.55.0.5-arm64.exe` で同じ形）:

```
PackageIdentifier: Git.Git
PackageVersion: 2.55.0.5
InstallerType: inno
InstallerSwitches:
  Silent: /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
  SilentWithProgress: /SP- /SILENT /SUPPRESSMSGBOXES /NORESTART
UpgradeBehavior: install
ReleaseDate: 2026-08-20
ElevationRequirement: elevatesSelf
Installers:
- Architecture: x64
  Scope: user
  InstallerUrl: https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.5/Git-2.55.0.5-64-bit.exe
  InstallerSha256: D065A4E23C3D9A6B5073D609B5BE0830227EC3CA053C083BA385061DDFAF94C6
- Architecture: x64
  Scope: machine
  InstallerUrl: https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.5/Git-2.55.0.5-64-bit.exe
  InstallerSha256: D065A4E23C3D9A6B5073D609B5BE0830227EC3CA053C083BA385061DDFAF94C6
```

- `Git.Git.locale.en-US.yaml` は、`Publisher: The Git Development Community`・`PackageName: Git`・`Moniker: git`。`Agreements` は無い
- 上流のタグ（`git ls-remote --tags`）の一番新しい正式版は `v2.56.0.windows.1`。winget-pkgs にはまだ載っていなかった

**インストーラ**: 定義の URL から `Git-2.55.0.5-64-bit.exe` を取った:

```
$ sha256sum Git-2.55.0.5-64-bit.exe
d065a4e23c3d9a6b5073d609b5be0830227ec3ca053c083ba385061ddfaf94c6  Git-2.55.0.5-64-bit.exe
```

- 65,343,712 バイト。sha256 は定義の `InstallerSha256` と一致した
- `osslsigncode verify`: Authenticode の署名者は `CN=Johannes Schindelin`（`O=Johannes Schindelin`・`L=Bruehl`・`C=DE`）、ダイジェストは一致、タイムスタンプは `Microsoft Public RSA Timestamping CA 2020` の 2026-08-20 16:05:39 GMT
  - 証明書の連鎖は、Linux の CA の一覧に `Microsoft Identity Verification Root Certificate Authority 2020` が無く、検証できなかった
- `innoextract` 1.9 は、このインストーラ（Inno Setup 7）を読めなかった（`Could not determine setup data version!`）。そのため、既定の選択は上流のソースで確かめた

**インストーラのソース**（git-for-windows/build-extra の `installer/install.iss`。2.55.0(5) のリリースのコミット `f7c8964` と、2026-10-03 の `main` の `0ec0fba` で、下の既定は同じ）:

- `PrivilegesRequired=none`、`DefaultDirName={pf}\Git`（`main` では `{commonpf}\Git`）
  - Inno Setup のソース（jrsoftware/issrc の `Setup.MainFunc.pas`・`Setup.SpawnServer.pas`）では、`none` は管理者の権限を要求しないが、昇格できるユーザー（Administrators の一員で、UAC で分けられたトークン）なら UAC で昇格し直す。管理者の権限で動けば、管理者のモード（`HKLM`・PC 全体の `PATH`）で入れる
  - 入れる先が書き込めないとき（管理者でないとき）は、入れる先の画面で `{userpf}\Git`（`%LOCALAPPDATA%\Programs\Git`）に変える
- 選択（`ReplayChoice`）は、`/o:<キー>=<値>` → `/LOADINF` のファイル → 入っている Git の `system` から推した値 → 前に入れたときの選択 → 既定 の順に決まる
- 既定: `Editor Option=VIM`・`Default Branch Option`（空）・`Path Option=Cmd`・`SSH Option=OpenSSH`・`CURL Option=WinSSL`・`CRLF Option=CRLFAlways`・`Bash Terminal Option=MinTTY`・`Git Pull Behavior Option=Merge`・`Use Credential Manager=Enabled`・`Performance Tweaks FSCache=Enabled`・`Enable Symlinks=Auto`（開発者モードが無く、管理者で動いていれば無効）
- 部品の既定（`Types: default`）: `ext`・`ext\shellhere`・`ext\guihere`・`gitlfs`・`assoc`・`assoc_sh`。`icons`（デスクトップのアイコン）・`autoupdate`・`windowsterminal` は入っていない。スタートメニューの Git Bash・Git CMD・Git GUI は、部品によらず作る
- `system` に書く値: `core.autocrlf`、`pull.rebase`（Merge なら `false`、Rebase なら `true`）か `pull.ff=only`（Fast-forward only）、`credential.helper=manager`、`core.fscache=true`、`core.symlinks`、`http.sslBackend`、`init.defaultBranch`（「Let Git decide」でも `master` を書く）。`core.editor` は、Vim なら書かない
- `Path Option=Cmd` は `{app}\cmd` を `PATH` の最後に足し（管理者のモードでは PC 全体の `PATH`）、削除のときに外す
- Git のファイル（`usr\bin\msys-2.0.dll` など）を使っているプロセスがあると、黙って動かしたときも閉じるよう求める問いを出す。`/SUPPRESSMSGBOXES` では「キャンセル」と答えたことになり、中断する
  - Inno Setup の文書（`NextButtonClick`）: 黙って動かしたときに、入れ始める前に `NextButtonClick` が False を返すと、Setup は終わる

**winget のソース**（microsoft/winget-cli、2026-10-02 のコミット `3973956`）:

- `ManifestCommon.cpp`: Inno Setup の既定のスイッチは、`Silent`・`SilentWithProgress`（定義と同じ）・`Log`（`/LOG="<LOGPATH>"`）・`InstallLocation`（`/DIR="<INSTALLPATH>"`）
- `ShellExecuteInstallerHandler.cpp`: 渡すのは、黙って動かすスイッチ（`--silent` が無ければ `SilentWithProgress`）・`Log`・定義の `Custom`・`--custom`・更新のときの `Update`・`--location` のときの `InstallLocation`。スコープに合わせたスイッチは無い。`--override` があれば、その値だけを渡す
- `UserSettings.h`: スコープの既定（`installBehavior.preferences.scope`）は `user`
- `UninstallFlow.cpp`: Inno Setup のパッケージは、「アプリと機能」の静かな削除のコマンドを動かす。管理者の権限で動いているときは、自分のユーザーのスコープのパッケージの削除を断る（PC 全体に入れたものは当たらない）
  - Inno Setup が書く静かな削除のコマンドは、`"<unins000.exe>" /SILENT`（jrsoftware/issrc の `Setup.Install.pas`）
- 日本語の文言（`Localization/Resources/ja-JP/winget.resw`）: `インストールが完了しました`・`利用可能なアップグレードが見つかりませんでした。`・`正常にアンインストールされました`・`入力条件に一致するインストール済みのパッケージが見つかりませんでした。`

**ほか**:

- Git for Windows のリリースノート（build-extra の `ReleaseNotes.md`）: 2.56.0（2026-09-28）で Windows 8.1 のサポートを外し、`/mingw64/bin/git.exe` が `/ucrt64/bin/git.exe` に変わった
- scoop（ScoopInstaller/Scoop の `lib/core.ps1`）: `Get-HelperPath -Helper Git` は、scoop の git が無ければ `Get-Command git` の場所を返す
- Claude Code の setup の文書: Windows では Git for Windows は任意で、あれば Bash のツールに Git Bash を使い、無ければ PowerShell のツールを使う。Git Bash が見つからないときの `CLAUDE_CODE_GIT_BASH_PATH` の例は `C:\Program Files\Git\bin\bash.exe`

---

### 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-03）

Linux（クラウドのコンテナ）の PowerShell 7.6.6 と PSScriptAnalyzer 1.25.0 で確かめた。

**構文と Windows PowerShell 5.1 との互換**:

- `powershell` のブロック 5 個（[Windows 11 で Git for Windows を入れる](../git.md#windows-11-で-git-for-windows-を入れる)の手順 2・3・5、[更新](../git.md#更新)の手順 2、[ロールバック](../git.md#ロールバック)の手順 6）を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。指摘は 0

**偽の `winget` で流した**: 5 個のブロックを、受け取った引数を数えて表示するだけの関数 `winget` を置いた pwsh で、順に流した:

- `winget` には、どのブロックでも書いたとおりの引数が 1 つずつ渡った。手順 3 の `install` は 10 個（`install`・`--exact`・`--id`・`Git.Git`・`--source`・`winget`・`--scope`・`machine`・`--accept-source-agreements`・`--accept-package-agreements`）
- 2 つのパスを渡した `Test-Path` は、`False` を 2 行出した（Linux なので、どちらも無い）。`Get-Command git -All | Format-Table Source` は、Linux の `git` の場所を表にした
- winget そのものの動き（定義の選び方・インストーラの起動・表示）は、Windows でしか確かめられない

**残っている未確認事項**:

1. Windows で、[Windows 11 で Git for Windows を入れる](../git.md#windows-11-で-git-for-windows-を入れる)の手順 1〜6 を通すこと（管理者の窓から UAC が出ずに入ること、`C:\Program Files\Git` に入ること、`PATH`、Git Bash が開くこと）
1. 黙って入れたときに `system` に書かれる値が、その節の手順 3 の補足の表のとおりになること。その後に、[実施手順](../git.md#実施手順)の手順 1・3〜11 を Git Bash で通すこと
1. [更新](../git.md#更新)の手順 2 で新しい版に上がること（2.56.0 が winget に載った後）と、Git Bash を開いたまま上げたときの動き
1. [ロールバック](../git.md#ロールバック)の手順 6 で外れること（`PATH` から外れること、残るもの）
1. 公式のインストーラで入れた PC を、winget で上げること
1. arm64 の Windows

---

### 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜7・9〜11。

**結果**: Git 2.52.0。テスト用の名前・メールで global の 14 設定を読み戻した。CRLF の保持、日本語のファイル名、`main`、ローカル bare リポジトリへの初回 push の upstream 設定、pull の rebase・autostash と未コミット変更の保持、手順 11 の後片付けを確認した。手順 8 は `pull.ff` が未設定だったため条件外。外部リポジトリへは push していない。

**今回の未確認範囲**: 改行を変換した clone を直す節、更新・ロールバック・Windows の手順は今回流していない。

### 付録: 現行版の新規 VM での再検証（2026-10-06）

公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active）で、`5da3478` の本文を SSH 対話 PTY に渡した。試験専用のユーザー・鍵と設定値を使用し、利用者の実アカウントの資格情報は持ち込んでいない。

実施手順 1〜7 を通し、Git 2.52.0 と全体設定の値・global の設定元を確認した。名前とメールは検証専用の値に置き換えた。GitHub への認証・push、Windows の導入は行っていない。


### 分離前の検証状況の記録

> [!WARNING]
> - **Windows 11 は、実機の Git Bash で `HOME` を使い捨てのディレクトリにして流した**（その PC の `~/.gitconfig` には書いていない）
> - **Git for Windows を winget で入れる・上げる・外すブロックは、Windows で流していない**（[Windows 11 で Git for Windows を入れる](../git.md#windows-11-で-git-for-windows-を入れる)・[更新](../git.md#更新)の手順 2・[ロールバック](../git.md#ロールバック)の手順 6）。詳しくは[対象と検証環境](#対象と検証環境)


### 実施手順 / 手順 7: 補足: 出力と、Windows の模擬

- `git config --get` は、3 つの場所のうち優先される値を返す。`--show-scope` は、その値を書いた場所を前に付ける
- 1 行目の `cd ~` は、リポジトリの中の `local` の設定を拾わないため
- 検証コンテナで、`/etc/gitconfig` に Git for Windows のインストーラの選択で書かれうる値（`core.autocrlf=true`・`pull.rebase=false`・`init.defaultBranch=master`・`pull.ff=only`）を置いて通すと、14 行は `global` になり、`pull.ff` だけが `system	only` になった:

```
user.name             global	<GIT_USER_NAME>
user.email            global	<GIT_USER_EMAIL>
pull.rebase           global	true
rebase.autoStash      global	true
core.autocrlf         global	false
init.defaultBranch    global	main
core.quotepath        global	false
fetch.prune           global	true
push.autoSetupRemote  global	true
rerere.enabled        global	true
merge.conflictStyle   global	zdiff3
diff.algorithm        global	histogram
branch.sort           global	-committerdate
tag.sort              global	version:refname
pull.ff               system	only
```

- Windows 11 の Git Bash（使い捨ての `HOME`）でも、14 行が `global` になり、`pull.ff` は空だった（その PC の `system` に `pull.ff` が無いので、手順 8 は飛ばした）
  - `system` の `init.defaultbranch=master` は、`global` の `main` で上書きされた



### 実施手順 / 手順 9: 補足: 検証コンテナでの出力

擬似端末（`script`）の中で流したときの出力。進み具合の行は、最後の表示だけを載せた:

```
?? a.txt
?? crlf.txt
?? 日本語.txt
i/crlf  w/crlf  attr/                 	crlf.txt
main
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to <N> threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (5/5), <SIZE> | <SPEED>, done.
Total 5 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To ../remote.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

- `core.autocrlf=true`（Windows の既定）なら、`i/lf` で入る。`core.quotepath` が既定の `true` なら、`"\346\227\245\346\234\254\350\252\236.txt"` と出る
- Windows 11 の Git Bash でも、`?? 日本語.txt`・`i/crlf  w/crlf`・`main`・`branch 'main' set up to track 'origin/main'.` が出た（出力はパイプに出したので、進み具合の行は無い）



### 実施手順 / 手順 10: 補足: 検証コンテナでの出力

`a` で `a: 2` を push し、`b` では `b: b.txt` をコミットして `crlf.txt` を変えたまま pull した。擬似端末（`script`）の中で流したときの出力で、進み具合の行は最後の表示だけを載せた:

```
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (3/3), <SIZE> | <SPEED>, done.
From <GIT_TEST_DIR>/remote
   <HASH>..<HASH>  main       -> origin/main
Created autostash: <HASH>
Applied autostash.
Successfully rebased and updated refs/heads/main.
* <HASH> (HEAD -> main) b: b.txt
* <HASH> (origin/main, origin/HEAD) a: 2
* <HASH> first
 M crlf.txt
```

- `Created autostash` の後に `Rebasing (1/1)` が出て、`Applied autostash.` で上書きされる
- 比べるために、`pull.rebase=false` で pull すると、`Merge made by the 'ort' strategy.` でマージコミットができ、`git log` が枝分かれした（端末ではマージのメッセージを書くエディタが開く）
- `rebase.autoStash` が無いと、pull は `error: cannot pull with rebase: You have unstaged changes.` で止まった
- Windows 11 の Git Bash でも、`Created autostash` → `Applied autostash.` → `Successfully rebased and updated refs/heads/main.` の順に出て、履歴は 1 本、` M crlf.txt` が残った



### 実施手順 / 手順 2: 補足: 入るパッケージ

- `git`（AppStream）は、本体の `git-core`、`git-core-doc`、perl のモジュール（`perl-Git` など）、`openssh-clients` を依存で連れてくる
- 検証コンテナ（最小の構成）では、依存を合わせて 74 パッケージが入った。デスクトップで入れた PC では、多くが入っている
- [gh](../gh.md) も git に依存するので、gh を入れた PC には git も入っている



### 実施手順 / 手順 8: 補足: pull.ff=only と pull.rebase

- `pull.ff=only` があると、`pull.rebase=true` でも、分岐した pull は rebase されずに止まる。検証コンテナで `system` に `pull.ff=only` を置き、この手順を飛ばすと、手順 10 の `git pull` が次で終わった（未コミットの変更はそのまま残った）:

```
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint: 	git merge --no-ff
hint:
hint: or:
hint:
hint: 	git rebase
hint:
hint: Disable this message with "git config set advice.diverging false"
fatal: Not possible to fast-forward, aborting.
```

- Git for Windows のインストーラで、`git pull` の既定の動作に「Only ever fast-forward」を選ぶと、この値が `system` に書かれる（本書では確かめていない）
- `true` は git の既定の動作（fast-forward できるときはする）。`pull.ff=false` も、rebase を止めなかった



### 改行を変換して clone したリポジトリを直す / 手順 1: 補足: 前の設定で見る理由

- `-c core.autocrlf=true` は、そのコマンドだけ前の設定で見る。付けないと、改行だけが違うファイルもすべて `M` で出る
- 検証コンテナで、LF のリポジトリを `git -c core.autocrlf=true clone` で clone すると、ファイルは `i/lf    w/crlf` になり、手順 5 の設定の `git status --short` ではすべて `M` で出た



### 更新 / 手順 2: 補足: winget での更新

- 定義の `UpgradeBehavior: install` のとおり、新しい版のインストーラを今のものの上から動かす。入れる先（`C:\Program Files\Git`）と、前に入れたときの選択（改行の扱いなど）は引き継ぐ。そのため `--scope` は付けない
- インストーラは、Git のファイル（`msys-2.0.dll` など）を使っているプロセスがあると、閉じるよう求める画面を出す。黙って動かすときはその問いが「キャンセル」で答えられ、入れ替えずに終わる（上流の `install.iss` を読んだだけで、確かめていない）
- 公式のインストーラで入れた PC でも、winget が `Git.Git` と結び付けて表示すれば、同じ形で上がるはず（確かめていない）。`winget list --exact --id Git.Git` に出なければ、[Windows 11 で Git for Windows を入れる](../git.md#windows-11-で-git-for-windows-を入れる)の手順 3 を貼る（今のものの上から入れる）
- インストーラの部品の「毎日の更新の確認」は既定で入れないので、Git for Windows は自分では上がらない



### ロールバック / 手順 6: 補足: winget での削除

- winget は、インストーラが「アプリと機能」に書いた静かな削除のコマンド（`C:\Program Files\Git\unins000.exe /SILENT`）を動かす。Inno Setup の削除のプログラムは、`/SILENT` では確かめの問いを出さない
- Git for Windows の削除のプログラムは、`PATH` から `C:\Program Files\Git\cmd` を外す（上流の `install.iss`）
- 管理者でない窓から貼ると、削除のプログラムが UAC で昇格を求めるはず（確かめていない）

## 参考資料から分離した記録

### 参考資料: 実施手順 / 手順 6: 補足: 推奨の設定と、入れなかった設定

| キー | 値 | 変わること |
|---|---|---|
| `init.defaultBranch` | `main` | `git init` の最初のブランチを `main` にする。設定が無いと git 2.52 は `master` にし、`hint:` を 13 行出した |
| `core.quotepath` | `false` | 日本語のファイル名を、`"\346\227\245…"` と書かずにそのまま出す |
| `fetch.prune` | `true` | fetch・pull のたびに、リモートで消えたブランチの追跡ブランチ（`origin/…`）を消す。ローカルのブランチは消さない |
| `push.autoSetupRemote` | `true` | 新しいブランチの最初の `git push` で、`-u origin <ブランチ>` を付けなくても追跡を設定する |
| `rerere.enabled` | `true` | 一度解いた衝突の解き方を覚え、同じ衝突に当たったら自動で当てる。rebase で同じ衝突を何度も解かずに済む |
| `merge.conflictStyle` | `zdiff3` | 衝突の表示に、共通の祖先の内容も出す（git 2.35 以降） |
| `diff.algorithm` | `histogram` | 差分の取り方。既定の `myers` より、関数を動かしたときなどに読みやすい差分になりやすい |
| `branch.sort` | `-committerdate` | `git branch` を、最近コミットしたブランチから並べる |
| `tag.sort` | `version:refname` | `git tag` を版の順（`v1.9` の後に `v1.10`）に並べる |

入れなかったもの:

- `core.editor`: 好みで決める。未設定なら、環境変数 `VISUAL`・`EDITOR` のエディタ、どちらも無ければ `vi` が開く。Windows では、インストーラで選んだエディタが `system` に入る
- `rerere.autoUpdate`: 覚えた解き方を当てた後に、`git add` までする。当てた結果を `git diff` で見てから add したいので入れない
- `fetch.pruneTags`: リモートに無いタグを、ローカルからも消す
- `pull.ff only`: 分岐したときの pull が、rebase せずに止まる（手順 8）
- `push.default`: 既定の `simple`（今のブランチを、同じ名前の追跡ブランチにだけ push する）のままでよい

### 参考資料: Windows 11 で Git for Windows を入れる / 手順 5: 補足: PATH と、ほかの git

- `PATH` に足されるのは `C:\Program Files\Git\cmd`（`git.exe`・`git-gui.exe` など）だけ。`bash`・`ssh`・`ls` などは足されないので、PowerShell の `ssh` は Windows のものが使われる
  - 以前の検証の PC は Git の `usr\bin` も `PATH` にあり、`ssh`・`ssh-keygen` が Git のものになっていた（[windows-openssh-server.md 手順 7](../windows-openssh-server.md#実施手順) の補足）
- Windows の `PATH` は、PC 全体の値の後ろに自分のユーザーの値が続く。scoop の git（`…\scoop\shims\git.exe`。自分のユーザーの `PATH`）があっても、新しく開いた窓では Git for Windows の `git` が先に見つかる
- scoop は、scoop の git が入っていなければ `PATH` の `git` を使う（scoop のソースの `Get-HelperPath`）。そのため、`scoop update` と `scoop bucket add` は Git for Windows の `git` で動く。scoop の git が入っていると、scoop はそちらを使う
- Claude Code（Windows）は、Git for Windows があれば Bash のツールを Git Bash で動かし、無ければ PowerShell のツールだけを使う（公式の setup の文書）

### 参考資料: 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `Git.Git` を `--scope machine` で** | 上流のインストーラを、winget が sha256 を確かめてから黙って動かす。`C:\Program Files\Git` に入り、`winget upgrade` で上がる。管理者の権限が要る | **採用** |
| winget の `--scope user` | 同じインストーラで、winget はスコープのスイッチを渡さない。入る先はインストーラが権限で決める | 不採用（PC 全体に入れるので、winget にも `machine` を指定する） |
| 上流のインストーラを落として、画面で入れる | 選択を画面で選べる。版の確認と更新は手作業 | 不採用（以前の検証の PC はこの形で、もとの本書もこれを案内していた） |
| scoop の `main/git` | Git for Windows の持ち運び版（PortableGit）を `~\scoop\apps\git` に入れ、`git` などを `~\scoop\shims` に置く。`C:\Program Files\Git\bin\bash.exe` が無い | 不採用（[Windows の OpenSSH サーバー](../windows-openssh-server.md#既定のシェルを-git-bash-にする任意)が `C:\Program Files\Git` を前提にしている。[Windows 11 の初期設定](../windows-setup.md)も、scoop の git を入れなくなった） |

- **インストーラの選択は既定のまま**（winget の `--custom` や `--override` で `/o:` を渡さない）
  - 本書は `system` を変えず `global` で上書きするので、`system` の `core.autocrlf=true`・`pull.rebase=false`・`init.defaultBranch=master` は既定のままでよい（[実施手順](../git.md#実施手順)の手順 7 で確かめる）
  - 既定の PATH の選択（`cmd` だけを足す）で、PowerShell・scoop・Claude Code から `git` が見つかる。Unix の道具まで足す選択は、Windows の `find`・`sort` を隠す（インストーラの画面の警告）
  - `--override` は、winget が渡す黙って動かすスイッチ（`/SP- /SILENT …`）ごと置き換える（winget のソース）
- **Git for Windows は、scoop の `scoop update` が使う git も兼ねる**
  - scoop は、scoop の git が入っていなければ `PATH` の `git` を使う（[Windows 11 で Git for Windows を入れる](../git.md#windows-11-で-git-for-windows-を入れる)の手順 5 の補足）

---

### 付録: Windows 11 Pro の VM での新規導入の検証（2026-10-06）

[Windows 11 の初期設定](windows-setup.md#付録-windows-11-pro-の-vm-での導入検証2026-10-06)を検証中の専用 VM で、[Windows 11 で Git for Windows を入れる](../git.md#windows-11-で-git-for-windows-を入れる)の手順 2・3・5 のコードブロックを抜き出して、そのまま実行した。画面で端末を開いて貼る操作は試していない。

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro 26H2 / ビルド 26300.9457 / x64 |
| VM | VirtualBox 7.2.20。Rufus で作った媒体からクリーンインストールした専用 VM |
| PowerShell | Windows PowerShell 5.1.26100.9444 / Desktop / x64。手順 2・3 は管理者、手順 5 は新しい通常権限のプロセス。どちらも同じログオンユーザーの Session 1 |
| WinGet | 1.29.380。確認の `winget list` は `--source winget` 付き |
| 検証時の本文の SHA256 | `A14BFED2E1703FED0B083224F9012CBB631F002B8AC3E77151223F97BA73E57B`（この追記より前） |
| 抜き出したブロックの manifest の SHA256 | `AF11A0B15F103A89BD9A697601A68FD62A772CCFCB43A53FA659A27356B81B55` |

**確認したこと**:

- 手順 2・3（バッチ `20261006-105816Z-096906b0`、完了 10:59:22 UTC）:
  - 未導入時は `Get-Command git` に出力がなく、Git Bash のパスは `False`、一覧は `No installed package found matching input criteria.` だった。最後の winget の終了コード `-1978335212` は、この未導入の確認で期待する結果
  - インストーラーのハッシュ検証が成功し、`Successfully installed` が出た。続く一覧は `Git.Git 2.55.0.5` で、PowerShell のエラーは 0、最後の終了コードは 0
- 手順 5（バッチ `20261006-110243Z-62c3d475`、完了 11:02:43 UTC）:
  - 新しい通常権限のプロセスで、`Get-Command git` は `C:\Program Files\Git\cmd\git.exe`、版は `git version 2.55.0.windows.5` だった
  - `C:\Program Files\Git\bin\bash.exe` と `C:\Program Files\Git\git-bash.exe` の存在確認は、どちらも `True`。PowerShell のエラーは 0、最後の終了コードは 0
- 両バッチとも検証用タスクの終了コードは 0 で、要求したバッチと完了記録が対応した

**確認していないこと**:

- 手順 1・4 の端末を開く画面操作と、手順 6 の Git Bash の起動・表示。手順 4 は新しいプロセスを起動して `PATH` を確認することで代替した
- この VM の Git Bash での[実施手順](../git.md#実施手順)。`GIT_USER_NAME` と `GIT_USER_EMAIL` は設定しておらず、`global` の設定も書いていない
- インストーラーが書いた `system` の値、更新、削除、arm64 の Windows

---

### 付録: Windows 11 Pro の VM での非対話 Bash による設定の検証（2026-10-07）

前の新規導入と同じ VM で、共通の[実施手順](../git.md#実施手順)の 3・5・6・7 のコードブロックを抜き出して、そのまま実行した。2026-09-30 の実機で `HOME` を使い捨てにした検証とは別の記録で、今回は `HOME` と `CODEX_HOME` を変更していない。

| 項目 | 値 |
|---|---|
| 環境 | Windows 11 Pro の専用 VM、通常権限の r-aoki。PowerShell 7.6.6 が非対話の `C:\Program Files\Git\bin\bash.exe` を起動 |
| Git | `git version 2.55.0.windows.5`。`--noprofile --norc` で起動し、プロファイルは読み込まない |
| 実行範囲 | 共通手順 3・5・6・7。子 Bash プロセスだけの `GIT_CONFIG_GLOBAL` で専用 scratch の `global.gitconfig` を指定 |
| 実行時刻 | 2026-10-07 04:18:58〜04:19:20 UTC |
| 検証時の本文の SHA256 | `2541D4BE9E3CD490A2474567EC30635496610BBA507922DD25148837BF4ED6A3`（この追記より前） |
| 実行した source manifest の SHA256 | `87AFDF5F88FA15E43C9BB851FEE6E5586EB531741191C3FA4F29B3CD4A77D180` |

**確認したこと**:

- 手順 3 は実物の `C:/Program Files/Git/etc/gitconfig` を読み、`system` の `core.autocrlf=true` を確認した
- 手順 5 の 3 キーと手順 6 の 9 キー、計 12 キーはすべて指定値になった。独立した読み戻しのスコープは `global`、origin は専用 scratch のファイルで、手順 7 の出力とも一致した。本人設定を省いたため、手順 7 の 14 キーすべてを確認した結果とは扱わない
- 実ユーザーの `.gitconfig`・`.config/git/config`、Git の `etc/gitconfig`、`C:\ProgramData\Git\config` は、前後の存在状態と SHA256 が一致した。`pull.ff` は前後とも未設定で、取得の終了コード 1 と空の出力も一致した
- 4 ブロックの終了コードはすべて 0、補助検証は `passed=true` で CLI の終了コードも 0。作成した `C:\verify\git-config-probe-<GUID>` の scratch だけを削除し、削除成功を確認した
- 証跡は `evidence/remaining-git-20261007-041841-0ff6f533` の `guest-result.json` と `source-manifest-executed.json` に保存した

**確認していないこと**:

- 本人の `GIT_USER_NAME`・`GIT_USER_EMAIL` と共通手順 4。この検証では実ユーザーの `global` に設定を書いていない
- 対話 Git Bash の起動・表示・コピーと貼り付け。非対話 CLI の成功を画面操作の成功とは扱わない
- 共通手順 9〜11 の使い捨てリポジトリでの改行・push・pull と後片付け、更新、削除。古い実機・コンテナの検証結果は前の付録に残す

---

### 付録: Windows 11 Pro の VM での非対話 Bash による push・pull と後片付けの検証（2026-10-07）

前の設定検証と同じ VM で、共通の[実施手順](../git.md#実施手順)の 4・5・6・9・10・11 の Bash ブロックを変更せず実行した。Windows PowerShell 5.1 の接続用 launcher が、通常権限の PowerShell 7.6.6 の検証 helper を起動し、その helper が Git Bash を非対話で起動した。手順 9・10 は 1 つの Bash セッションで続けて実行した。

| 項目 | 値 |
|---|---|
| 実行環境 | 同じ専用 Windows 11 Pro VM、通常権限の r-aoki、PowerShell 7.6.6、Git 2.55.0.windows.5 |
| Bash | `C:\Program Files\Git\bin\bash.exe --noprofile --norc`。子プロセスの `LC_ALL=C` |
| 隔離 | 子 Bash だけの `GIT_CONFIG_GLOBAL` と `TMPDIR` を専用 scratch に指定。`HOME` と `CODEX_HOME` は変更しない |
| 名前・メール | `VM Verification`・`vm-verification@example.invalid`。合成値だけを scratch の設定へ書いた |
| ゲストでの実行時刻 | 2026-10-07 09:27:08〜09:28:01 UTC |
| 実行時の本文の SHA256 | `7EA606C3138280166C7F35A90AB20C7E0D14005C640D8681E87E76C209BFE736`（この追記より前） |
| 実行した manifest の SHA256 | `2B6B05CB73AA6BF9AB78ED1E542543BFA0B34805E9BB75991D3BCCA6FDF462AB` |

**確認したこと**:

- 14 フェーズすべての終了コードが 0、挙動検査 9 件が PASS、Bash 全体の終了コードも 0 で `ALL_PHASES_PASS` を出した。合成の名前・メールと、設定 12 キーの値・`global` のスコープ・scratch の origin を確認した
- 手順 9 の出力に `?? 日本語.txt` が引用や置換文字なしで出た。helper は stdout とフェーズのログを strict UTF-8 で読んだ。`main`、最初のローカル push と `origin/main` の upstream、index と作業ファイルの CRLF が一致した
- 手順 10 は、履歴が 3 コミットの直線で merge がなく、古いローカルコミットが別の ID へ書き換わり、書き換え後の親が remote のコミットになった。設定値の読み戻しだけでなく、実際の rebase を確認した
- autostash の作成出力と実オブジェクト、その親が古いローカルコミットであること、適用の出力と stash が残らないことを確認した。未コミットの CRLF の変更は復元され、HEAD と index の元の内容、日本語のパス、合成のコミット作者も保持された
- 手順 11 の前に `realpath` と `cygpath` で削除先が専用 scratch の配下であることを確認した。手順 11 が fixture だけを消し、外側の scratch と `HOME` を保持した後、helper が scratch を削除した。実ユーザーの設定ファイル 4 件の存在状態と SHA256 は前後一致し、`pull.ff` も未設定のままだった

**初回の接続と後の回収**:

- 初回のホスト側 GuestControl には 55 秒の上限を付けた。ホスト側の CLI 終了コードは 1、直後の結果コピーも 1 だった。この値を Git の実行結果の成功へ置き換えていない
- 後で完成したゲストの結果を回収し、2026-10-07 09:36:30 UTC のコピーは終了コード 0 だった。再実行はしていない。ゲスト自身の結果は終了コード 0・`passed=true`・cleanup 成功で、完了時刻は `guest-result.json` の値を使った
- 証跡は `.verification/evidence/remaining-git-behavior-20261007-092648-ddbf22f4` の `guest-result.json`・実行した manifest/helper・初回の `host-execution-result.json`・後の `host-recovery-result.json`・独立した `git-behavior-assessment.json` に保存した。元の証跡は変更していない

**確認していないこと**:

- 本人の名前・メールを実ユーザーの設定へ反映すること、対話 Git Bash の画面・コピーと貼り付け、外部リモートへの認証や network pull
- `pull.ff` を変更する手順 8、利用中の既存の設定との組み合わせ、更新・削除、arm64 の Windows。今回の隔離した機能テストを全手順の通し成功とは扱わない

---

### 付録: Windows 11 Pro の VM での対話の Git Bash による通し検証（2026-10-08）

上の付録と同じ VM（[windows-setup.md の検証記録の 2026-10-08 の付録](windows-setup.md#付録-pr-104-の未検証項目を同じ-vm-で確かめた記録2026-10-08)の環境）で、スタートメニューから開いた Git Bash（mintty）に、本文のブロックを右クリックのメニューの「Paste」で貼り、[実施手順](../git.md#実施手順)の手順 1・3〜11 とロールバックの手順 1〜5 を通した。ロールバックの手順 6 と更新の手順 2 は、管理者の Windows PowerShell に貼った。上の付録と違い、子プロセスの `GIT_CONFIG_GLOBAL` は使わず、実ユーザーの `global`（`C:\Users\<WIN_USER>\.gitconfig`）に書いた。

| 項目 | 値 |
|---|---|
| Git | `git version 2.55.0.windows.5`（上の付録で入れたもの） |
| 始める前 | `global` の設定ファイルは無かった。`system`（`C:/Program Files/Git/etc/gitconfig`）の SHA256 は `381C2FDA5A3B5ADF7102F5B05F68D7DC3281A44171F9B40556CA56CFDD8461C3` で、`pull.ff` は無かった |
| 名前とメールアドレス | 試験用の架空の値（`PR104 Verification`・`pr104-verification@example.invalid`） |
| 手順 8 の分岐 | 確かめるため、管理者の窓で一時的に `git config --system pull.ff only` を足した（終わった後に外した） |

**確認したこと**:

- Windows 11 で Git for Windows を入れるの手順 6: スタートメニューの「Git Bash」で、`<WIN_USER>@<HOSTNAME> MINGW64 ~` と `$` の窓が開いた
- 窓の中の右クリックで、`Copy`・`Paste`（`Shift+Ins`）などのメニューが出た。本文に「Paste」で貼る旨を足した
- 手順 1・3〜7: 手順 7 で、`global` の 14 キー（名前・メールアドレスと、手順 5・6 の 12 キー）が出て、`pull.ff` は `system  only` だった
- 手順 8: `global  true`
- 手順 9: `?? 日本語.txt`、`i/crlf  w/crlf`（CRLF のまま入った）、ブランチは `main`、`branch 'main' set up to track 'origin/main'.`
- 手順 10: `Created autostash`・`Applied autostash.`・`Successfully rebased and updated refs/heads/main.`、履歴は一直線、作業中の `M crlf.txt` が残った
- 手順 11: 使い捨てのリポジトリが消えた
- 手順 8 を行わない場合（`global` の `pull.ff` を外し、`system` の `only` だけにした場合）の分岐した pull は、`fatal: Not possible to fast-forward, aborting.`（終了コード 128）で止まった
- ロールバックの手順 1〜4: 今回足した 15 キー（手順 4・5・6・8 のもの）を `--unset` で外した。手順 5 の `git config --global --list` は何も出さなかった。ただし `~/.gitconfig` は 0 バイトのファイルとして残った（始める前は無かった）。本文に注意を足した
- 一時的な `system` の `pull.ff` を外し、`system` の SHA256 が始める前と同じに戻った
- 更新の手順 2（管理者の窓）: `No available upgrade found.`、`winget list` は `Git  Git.Git  2.55.0.5`
- ロールバックの手順 6（管理者の窓、Git Bash は閉じた状態）: `Found Git [Git.Git]`・`Starting package uninstall...`・`Successfully uninstalled`、`winget list` は `No installed package found matching input criteria.`、最後は `False`。途中で「Git Uninstall」の進捗の窓（「Uninstalling Git...」）が出て、何も押さずに閉じた

**検証の手順で起きたこと**:

- 最初の通しでは、検証の操作が窓を前に出すために Alt を 1 回だけ押したため、mintty がメニューの操作に入り、貼った後の Enter が食われた。手順 5・6・7 の 3 つのブロックが 1 行につながって実行され、`pull.rebase` が入らず `tag.sort` が `version:refnamecd` になった。操作を直し、手順 4〜7 を貼り直して（どれも何度貼ってもよい）、正しい値になったことを手順 7 で確かめた

**確認していないこと**:

- 本人の名前・メールアドレスと、外部のリモート（GitHub など）への認証・push・pull
- Ctrl+V・Shift+Insert のキーでの貼り付け（検証の操作では、Shift+Insert が正しいキーとして届かなかった）、arm64 の Windows、Windows の実機
