# Git のセットアップ手順（AlmaLinux 10 は AppStream / Windows 11 は winget の Git for Windows）の参考資料

[手順書](../git.md)・[ロールバックと注意点](../extra/git.md)

[検証記録](../verification/git.md#参考資料から分離した記録)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- GitHub に push するなら、メールアドレスに GitHub の noreply のアドレス（`<ID>+<GITHUB_USER>@users.noreply.github.com`）を使うと、私用のアドレスをコミットに載せずに済む。アドレスは GitHub の Settings の Emails で確かめる
- 名前に空白を入れるときは、引用符の中に書く（引用符が無いと、空白の後ろがコマンドとして実行される）
- 使うのは手順 4 だけ。後から変えるときは、手順 1 と手順 4 を貼り直す（`git config --global` は同じキーを上書きする）
- 変数はそのシェルの中だけで有効

### 実施手順 / 手順 3: 補足: Windows の system の行

- Windows で出る `system` の行（インストーラが書いたもの）より、手順 5・6 で書く `global` の値が優先される

### 実施手順 / 手順 5: 補足: 設定の意味

- `pull.rebase true`: `git pull` が、取ってきた履歴の上に自分のコミットを載せ直す（マージコミットを作らない）
- `rebase.autoStash true`: 未コミットの変更があっても pull できる（pull の前に stash し、後で戻す）
- `core.autocrlf false`: チェックアウトでもコミットでも、改行を変換しない

### 実施手順 / 手順 6: 補足: 推奨の設定と、入れなかった設定

| キー | 値 | 変わること |
|---|---|---|
| `init.defaultBranch` | `main` | `git init` の最初のブランチを `main` にする |
| `core.quotepath` | `false` | 日本語のファイル名を、`"\346\227\245…"` と書かずにそのまま出す |
| `fetch.prune` | `true` | fetch・pull のたびに、リモートで消えたブランチの追跡ブランチ（`origin/…`）を消す。ローカルのブランチは消さない |
| `push.autoSetupRemote` | `true` | 新しいブランチの最初の `git push` で、`-u origin <ブランチ>` を付けなくても追跡を設定する |
| `rerere.enabled` | `true` | 一度解いた衝突の解き方を覚え、同じ衝突に当たったら自動で当てる。rebase で同じ衝突を何度も解かずに済む |
| `merge.conflictStyle` | `zdiff3` | 衝突の表示に、共通の祖先の内容も出す（git 2.35 以降） |
| `diff.algorithm` | `histogram` | 差分の取り方。既定の `myers` より、関数を動かしたときなどに読みやすい差分になりやすい |
| `branch.sort` | `-committerdate` | `git branch` を、最近コミットしたブランチから並べる |
| `tag.sort` | `version:refname` | `git tag` を版の順（`v1.9` の後に `v1.10`）に並べる |

- 要らないものは、[ロールバック](../extra/git.md#ロールバック)の手順 1・4 に従い、そのキーだけ元の設定に戻せる
- `merge.conflictStyle zdiff3` は [git-delta.md 手順 3](../git-delta.md#実施手順) と同じ設定で、どちらを先に通してもよい

入れなかったもの:

- `core.editor`: 好みで決める。未設定なら、環境変数 `VISUAL`・`EDITOR` のエディタ、どちらも無ければ `vi` が開く。Windows では、インストーラで選んだエディタが `system` に入る
- `rerere.autoUpdate`: 覚えた解き方を当てた後に、`git add` までする。当てた結果を `git diff` で見てから add したいので入れない
- `fetch.pruneTags`: リモートに無いタグを、ローカルからも消す
- `pull.ff only`: 分岐したときの pull が、rebase せずに止まる（手順 8）
- `push.default`: 既定の `simple`（今のブランチを、同じ名前の追跡ブランチにだけ push する）のままでよい

### 実施手順 / 手順 7: 補足: pull.ff

- 最後の `pull.ff` が何も出さないのは、設定が無いこと

### 実施手順 / 手順 9: 補足: 確かめている設定

- `?? 日本語.txt` がそのまま出るのは `core.quotepath`
- `i/crlf  w/crlf` は、CRLF のまま入ったこと（`core.autocrlf`）
- ブランチの `main` は `init.defaultBranch`
- `branch 'main' set up to track 'origin/main'.` は `push.autoSetupRemote`

### 実施手順 / 手順 10: 補足: 残る変更

- `M crlf.txt` は、pull の前の、未コミットの変更

### Windows 11 で Git for Windows を入れる / 手順 2: 補足: 確かめていること

- Git for Windows を PC 全体に入れると、`git` は `C:\Program Files\Git\cmd\git.exe`、Git Bash は `C:\Program Files\Git\git-bash.exe`（スタートメニューの Git Bash）と `C:\Program Files\Git\bin\bash.exe`（ほかのプログラムから bash を起動する入口）になる
- `bin\bash.exe` は、[Windows の OpenSSH サーバーの既定のシェルを Git Bash にする（任意）](../windows-openssh-server.md#既定のシェルを-git-bash-にする任意)が決め打ちにしている。Claude Code（Windows）の公式の文書も、Git Bash の場所の例にこのパスを挙げる
- 管理者の権限が無いと、インストーラは入れる先の既定を `%LOCALAPPDATA%\Programs\Git` に変える（上流の `install.iss`。画面で入れるとき）。その形では、上の 2 つのパスが無い
- `--source winget` を付けた `winget list` は、入っているアプリを winget のカタログと照合し、確認に要らない Microsoft Store のソースの初回同意を避ける
- `--accept-source-agreements` は、winget を初めて使う PC で出るソースの同意の問いに答えるため（続けて貼った行が答えとして食われないように）
- `…\AppData\Local\Programs\Git\cmd\git.exe` の Git for Windows を外してから始めるのは、ほかの手順書が `C:\Program Files\Git` を前提にしているため

### Windows 11 で Git for Windows を入れる / 手順 3: 補足: UAC

- 管理者の窓から動かすので、UAC の確認も出ないはず

### Windows 11 で Git for Windows を入れる / 手順 4: 補足: 開き直す理由

- 同じ節の手順 3 で PC 全体の `PATH` に足された `C:\Program Files\Git\cmd` は、開いていた PowerShell には入らない

### Windows 11 で Git for Windows を入れる / 手順 5: 補足: PATH と、ほかの git

- `PATH` に足されるのは `C:\Program Files\Git\cmd`（`git.exe`・`git-gui.exe` など）だけ。`bash`・`ssh`・`ls` などは足されないので、PowerShell の `ssh` は Windows のものが使われる
- Windows の `PATH` は、PC 全体の値の後ろに自分のユーザーの値が続く。scoop の git（`…\scoop\shims\git.exe`。自分のユーザーの `PATH`）があっても、新しく開いた窓では Git for Windows の `git` が先に見つかる
- scoop は、scoop の git が入っていなければ `PATH` の `git` を使う（scoop のソースの `Get-HelperPath`）。そのため、`scoop update` と `scoop bucket add` は Git for Windows の `git` で動く。scoop の git が入っていると、scoop はそちらを使う
- Claude Code（Windows）は、Git for Windows があれば Bash のツールを Git Bash で動かし、無ければ PowerShell のツールだけを使う（公式の setup の文書）

### Windows 11 で Git for Windows を入れる / 手順 5: 補足: 版

- `git version` の版は、実行した日の最新

### 改行を変換して clone したリポジトリを直す / 手順 2: 補足: 保存しなかったとき

- `No local changes to save` は、今回は保存していないこと

### 改行を変換して clone したリポジトリを直す / 手順 4: 補足: 別の stash を作らない理由

- `pop` は先頭の stash を戻すため

### 更新 / 手順 1: 補足: dnf upgrade

- 通常の `sudo dnf upgrade` にも含まれる

### ロールバック / 手順 1: 補足: 残るもの

- `rerere.enabled` で覚えた解き方は、各リポジトリの `.git/rr-cache` に残る。要らなければ手で消す
- `git init` 済みのリポジトリのブランチ名（`main`）は変わらない

### 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `Git.Git` を `--scope machine` で** | 上流のインストーラを、winget が sha256 を確かめてから黙って動かす。`C:\Program Files\Git` に入り、`winget upgrade` で上がる。管理者の権限が要る | **採用** |
| winget の `--scope user` | 同じインストーラで、winget はスコープのスイッチを渡さない。入る先はインストーラが権限で決める | 不採用（PC 全体に入れるので、winget にも `machine` を指定する） |
| 上流のインストーラを落として、画面で入れる | 選択を画面で選べる。版の確認と更新は手作業 | 不採用 |
| scoop の `main/git` | Git for Windows の持ち運び版（PortableGit）を `~\scoop\apps\git` に入れ、`git` などを `~\scoop\shims` に置く。`C:\Program Files\Git\bin\bash.exe` が無い | 不採用（[Windows の OpenSSH サーバー](../windows-openssh-server.md#既定のシェルを-git-bash-にする任意)が `C:\Program Files\Git` を前提にしている。[Windows 11 の初期設定](../windows-setup.md)も、scoop の git を入れなくなった） |

- **インストーラの選択は既定のまま**（winget の `--custom` や `--override` で `/o:` を渡さない）
  - 本書は `system` を変えず `global` で上書きするので、`system` の `core.autocrlf=true`・`pull.rebase=false`・`init.defaultBranch=master` は既定のままでよい（[実施手順](../git.md#実施手順)の手順 7 で確かめる）
  - 既定の PATH の選択（`cmd` だけを足す）で、PowerShell・scoop・Claude Code から `git` が見つかる。Unix の道具まで足す選択は、Windows の `find`・`sort` を隠す（インストーラの画面の警告）
  - `--override` は、winget が渡す黙って動かすスイッチ（`/SP- /SILENT …`）ごと置き換える（winget のソース）
- **Git for Windows は、scoop の `scoop update` が使う git も兼ねる**
  - scoop は、scoop の git が入っていなければ `PATH` の `git` を使う（[Windows 11 で Git for Windows を入れる](../git.md#windows-11-で-git-for-windows-を入れる)の手順 5 の補足）

### 参照

- `git help config` — 各キーの意味と既定値、設定の場所の順（`system` / `global` / `local`）
- `git help pull` — `--rebase`、`--autostash`、`pull.ff`
- `git help gitattributes` — `text`・`eol` と `core.autocrlf` の関係
- `git help rerere` — 解き方の記録と `forget`
- [Git for Windows](https://gitforwindows.org/) — 公式のサイト
- [winget-pkgs の `Git.Git`](https://github.com/microsoft/winget-pkgs/tree/master/manifests/g/Git/Git) — winget の定義（スコープ・インストーラの種類・スイッチ・sha256）
- [Silent or Unattended Installation](https://gitforwindows.org/silent-or-unattended-installation) — Git for Windows のインストーラを黙って動かすときのスイッチと、`/o:` で渡せる選択の一覧
- [git-for-windows/build-extra の `installer/install.iss`](https://github.com/git-for-windows/build-extra/blob/main/installer/install.iss) — インストーラの既定の選択、入れる先、`system` に書く値
- [Git for Windows のリリースノート](https://github.com/git-for-windows/build-extra/blob/main/ReleaseNotes.md) — 2.56.0 の `mingw64` から `ucrt64` への変更
- [microsoft/winget-cli](https://github.com/microsoft/winget-cli) — `ShellExecuteInstallerHandler.cpp`（インストーラに渡すスイッチ）、`ManifestCommon.cpp`（Inno Setup の既定のスイッチ）、`UninstallFlow.cpp`（削除のコマンド）、`doc/Settings.md`（スコープの既定）
- [Inno Setup の Uninstaller Command-Line Parameters](https://jrsoftware.org/ishelp/topic_uninstcmdline.htm) — 削除のプログラムの `/SILENT`
- [Claude Code の Set up Claude Code](https://code.claude.com/docs/en/setup) — Windows で Git for Windows があれば Bash のツールに Git Bash を使うこと、`CLAUDE_CODE_GIT_BASH_PATH`
- [Pro Git 8.1 Git の設定](https://git-scm.com/book/ja/v2/Git-%E3%81%AE%E3%82%AB%E3%82%B9%E3%82%BF%E3%83%9E%E3%82%A4%E3%82%BA-Git-%E3%81%AE%E8%A8%AD%E5%AE%9A) — `core.autocrlf` の説明

---
