# Git のセットアップ手順（AlmaLinux 10 / Windows 11 の Git for Windows）

## 実施手順

> [!IMPORTANT]
> - **AlmaLinux 10 では、自分のユーザーのシェルで貼る**。`sudo -i` した root のシェルでは貼らない（設定が root の `~/.gitconfig` に書かれるため）
> - **Windows 11 では、Git for Windows の Git Bash に同じブロックを貼り、手順 2 は飛ばす**。PowerShell や cmd には貼らない（bash の構文のため）
> - Windows に Git for Windows が無ければ、先に [Git for Windows](https://gitforwindows.org/) のインストーラで入れる

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 改行を変換する設定（`core.autocrlf=true`）のときに clone したリポジトリがあれば、[改行を変換して clone したリポジトリを直す](#改行を変換して-clone-したリポジトリを直す)を行う。以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **AlmaLinux 10 は x86_64 のコンテナでのみ検証した**。実機では本実行していない。**Windows 11 は、実機の Git Bash で `HOME` を使い捨てのディレクトリにして流した**（その PC の `~/.gitconfig` には書いていない）。詳しくは[対象と検証環境](#対象と検証環境)。

1. 変数を設定する（`GIT_USER_NAME` と `GIT_USER_EMAIL` は必ず値を入れる）。

   ```bash
   GIT_USER_NAME=''                     # ← コミットに載せる名前を引用符の中に書く（例: 'Taro Yamada'）。<GIT_USER_NAME>
   ```

   ```bash
   GIT_USER_EMAIL=''                    # ← コミットに載せるメールアドレスを引用符の中に書く。<GIT_USER_EMAIL>
   ```

   ```bash
   for v in GIT_USER_NAME GIT_USER_EMAIL; do
     printf '%-14s = %s\n' "$v" "${!v}"
   done
   ```

   - 2 つとも `git log` に出る。push したリポジトリでは公開される
   - 最後に値を読み戻して確かめる。空のままなら、手順 4 で中断する
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**、手順 1 の 3 つのブロックを貼り直してから先へ進む
   - Windows の Git Bash なら、手順 2 は飛ばす

   <details>
   <summary>補足: 変数について</summary>

   - GitHub に push するなら、メールアドレスに GitHub の noreply のアドレス（`<ID>+<GITHUB_USER>@users.noreply.github.com`）を使うと、私用のアドレスをコミットに載せずに済む。アドレスは GitHub の Settings の Emails で確かめる
   - 名前に空白を入れるときは、引用符の中に書く（引用符が無いと、空白の後ろがコマンドとして実行される）
   - 使うのは手順 4 だけ。後から変えるときは、手順 1 と手順 4 を貼り直す（`git config --global` は同じキーを上書きする）

   </details>

1. AlmaLinux 10 のときだけ、git を入れる。

   ```bash
   sudo dnf install -y git
   ```

   - 入っていれば、`Package git-2.52.0-1.el10.x86_64 is already installed.` と出る（aarch64 では末尾が `.aarch64`）

   <details>
   <summary>補足: 入るパッケージ</summary>

   - `git`（AppStream）は、本体の `git-core`、`git-core-doc`、perl のモジュール（`perl-Git` など）、`openssh-clients` を依存で連れてくる
   - 検証コンテナ（最小の構成）では、依存を合わせて 74 パッケージが入った。デスクトップで入れた PC では、多くが入っている
   - [gh](gh.md) も git に依存するので、gh を入れた PC には git も入っている

   </details>

1. git の版と、今の設定を確かめる。

   ```bash
   git --version
   git config --list --show-scope --show-origin
   ```

   - AlmaLinux 10.2 では `git version 2.52.0` と出る
   - 2 つ目は、設定を `<場所>	file:<ファイル>	<キー>=<値>` の形で 1 行ずつ出す。何も設定していなければ、何も出ない
   - **手順 4〜6 で変えるキー（`user.name`・`core.autocrlf` など）に元の値があれば、控えておく**（[ロールバック](#ロールバック)で書き戻す）
   - Windows では、インストーラが書いた `system` の行（`core.autocrlf=true` など）も出る。手順 5・6 で書く `global` の値が優先される

   <details>
   <summary>補足: 設定の 3 つの場所</summary>

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

   </details>

1. 名前とメールアドレスを設定する。

   ```bash
   if [ -z "${GIT_USER_NAME}" ] || [ -z "${GIT_USER_EMAIL}" ]; then echo '中断: 手順 1 の GIT_USER_NAME か GIT_USER_EMAIL が空のまま' >&2; else
     git config --global user.name "${GIT_USER_NAME}"
     git config --global user.email "${GIT_USER_EMAIL}"
     git config --global --get-regexp '^user\.'
   fi
   ```

   - `user.name <GIT_USER_NAME>` と `user.email <GIT_USER_EMAIL>` の 2 行が出る
   - `中断:` と出たら、手順 1 で値を入れて貼り直す

1. pull を rebase にし、autostash を有効にし、改行を変換しないようにする。

   ```bash
   git config --global pull.rebase true
   git config --global rebase.autoStash true
   git config --global core.autocrlf false
   ```

   - 何も出ない。値は手順 7 でまとめて確かめる
   - `pull.rebase true`: `git pull` が、取ってきた履歴の上に自分のコミットを載せ直す（マージコミットを作らない）
   - `rebase.autoStash true`: 未コミットの変更があっても pull できる（pull の前に stash し、後で戻す）
   - `core.autocrlf false`: チェックアウトでもコミットでも、改行を変換しない

   <details>
   <summary>補足: 3 つの設定</summary>

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

   </details>

1. 推奨の設定を入れる。

   ```bash
   git config --global init.defaultBranch main
   git config --global core.quotepath false
   git config --global fetch.prune true
   git config --global push.autoSetupRemote true
   git config --global rerere.enabled true
   git config --global merge.conflictStyle zdiff3
   git config --global diff.algorithm histogram
   git config --global branch.sort -committerdate
   git config --global tag.sort version:refname
   ```

   - 何も出ない。値は手順 7 でまとめて確かめる
   - 要らないものは、[ロールバック](#ロールバック)の手順 1 のその行だけを貼って外せる
   - `merge.conflictStyle zdiff3` は [git-delta.md 手順 3](git-delta.md#実施手順) と同じ設定で、どちらを先に通してもよい

   <details>
   <summary>補足: 推奨の設定と、入れなかった設定</summary>

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

   </details>

1. 効いている値と、その値を書いた場所を確かめる。

   ```bash
   cd ~
   for k in user.name user.email pull.rebase rebase.autoStash core.autocrlf \
            init.defaultBranch core.quotepath fetch.prune push.autoSetupRemote rerere.enabled \
            merge.conflictStyle diff.algorithm branch.sort tag.sort pull.ff; do
     printf '%-21s %s\n' "$k" "$(git config --show-scope --get "$k")"
   done
   ```

   - `pull.ff` を除く 14 行が、`global` と手順 4〜6 の値になる（`pull.rebase           global	true` など）
   - `pull.ff` 以外に `system` の行があれば、`global` に書けていない。手順 4〜6 を貼り直す
   - 最後の `pull.ff` は、何も出ない（設定が無い）のが普通
   - `pull.ff` が空か、`only` 以外なら、手順 8 は飛ばす

   <details>
   <summary>補足: 出力と、Windows の模擬</summary>

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

   </details>

1. 手順 7 で `pull.ff` が `only` だったときだけ、`true` で上書きする。

   ```bash
   git config --global pull.ff true
   git config --show-scope --get pull.ff
   ```

   - `global	true` と出る

   <details>
   <summary>補足: pull.ff=only と pull.rebase</summary>

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

   </details>

1. 使い捨てのリポジトリで、改行・ブランチ名・日本語のファイル名・最初の push を確かめる。

   ```bash
   GIT_TEST_DIR=$(mktemp -d)
   cd "$GIT_TEST_DIR"
   git init -q --bare remote.git
   git init -q a
   cd a
   printf 'line 1\r\n' > crlf.txt
   printf '1\n' > a.txt
   touch 日本語.txt
   git status --short
   git add .
   git commit -q -m first
   git ls-files --eol crlf.txt
   git branch --show-current
   git remote add origin ../remote.git
   git push
   ```

   - `git status --short` に `?? 日本語.txt` がそのまま出る（`core.quotepath`）
   - `git ls-files --eol` は `i/crlf  w/crlf` で始まる。CRLF のまま入った（`core.autocrlf`）
   - ブランチは `main`（`init.defaultBranch`）
   - `git push` の最後に `branch 'main' set up to track 'origin/main'.` と出る（`push.autoSetupRemote`）

   <details>
   <summary>補足: 検証コンテナでの出力</summary>

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

   </details>

1. 手順 9 と同じシェルで、別の clone から pull し、rebase と autostash を確かめる。

   ```bash
   cd "$GIT_TEST_DIR"
   git clone -q remote.git b
   cd a
   printf '2\n' >> a.txt
   git commit -q -a -m 'a: 2'
   git push -q
   cd ../b
   printf 'b\n' > b.txt
   git add b.txt
   git commit -q -m 'b: b.txt'
   printf 'line 2\r\n' >> crlf.txt
   git pull
   git log --oneline --graph
   git status --short
   ```

   - `git pull` が `Created autostash: …`・`Applied autostash.`・`Successfully rebased and updated refs/heads/main.` を出す
   - `git log` は枝分かれせず、`b: b.txt` → `a: 2` → `first` の 1 本になる
   - `git status --short` に `M crlf.txt` が残る（pull の前の、未コミットの変更）

   <details>
   <summary>補足: 検証コンテナでの出力</summary>

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

   </details>

1. 使い捨てのリポジトリを消す。

   ```bash
   cd ~
   rm -rf "${GIT_TEST_DIR:?手順 9 と同じシェルで貼る}"
   ```

   - 何も出ない

---

## 改行を変換して clone したリポジトリを直す

- 改行を変換する設定（`core.autocrlf=true`）のときに clone したリポジトリは、作業ツリーのファイルが CRLF のまま残る
- 手順 5 の後は、それらが変更ありと出る。編集してコミットすると、CRLF で入る
- Windows で、Git for Windows の既定の設定のまま clone したリポジトリが当たる
- リポジトリごとに、そのリポジトリのトップのディレクトリで、この節の手順 1 から貼る

> [!WARNING]
> **この節の手順 3 は、作業ツリーの追跡しているファイルをすべて書き直し、未コミットの変更を消す**。この節の手順 1 で変更が出たら、手順 2 で退避してから貼る。

1. 直すリポジトリのトップで、未コミットの変更と、CRLF で書かれたファイルの数を見る。

   ```bash
   git -c core.autocrlf=true status --short
   git ls-files --eol | grep -c 'i/lf *w/crlf'
   ```

   - 2 つ目の数が、直すファイルの数。`0` なら、この節は要らない
   - 1 つ目が何も出さなければ、未コミットの変更は無い。この節の手順 2 と 4 は飛ばす

   <details>
   <summary>補足: 前の設定で見る理由</summary>

   - `-c core.autocrlf=true` は、そのコマンドだけ前の設定で見る。付けないと、改行だけが違うファイルもすべて `M` で出る
   - 検証コンテナで、LF のリポジトリを `git -c core.autocrlf=true clone` で clone すると、ファイルは `i/lf    w/crlf` になり、手順 5 の設定の `git status --short` ではすべて `M` で出た

   </details>

1. この節の手順 1 で変更が出たときだけ、前の設定のまま stash する。

   ```bash
   git -c core.autocrlf=true stash
   ```

   - `Saved working directory and index state WIP on …` と出る

1. 作業ツリーのファイルを、今の設定で書き直す。

   ```bash
   git rm -r -q --cached .
   git reset -q --hard
   git ls-files --eol | grep -c 'i/lf *w/crlf'
   git status --short
   ```

   - 数は `0` になる
   - `git status --short` は何も出さない

   <details>
   <summary>補足: 書き直し方</summary>

   - `git rm -r --cached .` で追跡を外してから `git reset --hard` すると、追跡しているファイルがすべて今の設定で書き直される。追跡していないファイルには触れない
   - 検証コンテナで、`git checkout-index --force --all` も試したが、ファイルは LF になったものの `git status` に `M` が残った
   - Windows 11 の Git Bash でも、`git -c core.autocrlf=true clone` した 2 ファイルのリポジトリ（CRLF の 1 行を足した）で、この節の手順 1 が ` M y.txt` と `2`、手順 3 が `0` を出し、手順 4 の後は 2 つとも `w/lf` になった

   </details>

1. この節の手順 2 で stash したときだけ、変更を戻す。

   ```bash
   git stash pop
   git ls-files --eol
   ```

   - `git status` の形で、元の変更だけが出る
   - 戻したファイルも `w/lf` になる

---

## 更新

1. AlmaLinux 10 で、git を更新する。

   ```bash
   sudo dnf upgrade git
   ```

   - 通常の `sudo dnf upgrade` にも含まれる
   - 新しい版が無ければ、`Nothing to do.` と出る

1. Windows 11 では、Git for Windows を新しいインストーラで入れ直す。

   - [Git for Windows](https://gitforwindows.org/) から落としたインストーラを実行する
   - 入れ直した後は、Git Bash を開き直し、[手順 7](#実施手順) を貼り直す（`pull.ff` が `only` なら手順 8 も）

---

## ロールバック

- 本書で `global` に書いた設定を外す。`system` と `local` の設定は変えない
- git 本体は消さない（gh などが依存している）
- [手順 3](#実施手順) で控えた元の値は、この節の手順 4 で書き戻す

1. 手順 5・6・8 の設定を外す（`merge.conflictStyle` を除く）。

   ```bash
   git config --global --unset pull.rebase
   git config --global --unset rebase.autoStash
   git config --global --unset core.autocrlf
   git config --global --unset init.defaultBranch
   git config --global --unset core.quotepath
   git config --global --unset fetch.prune
   git config --global --unset push.autoSetupRemote
   git config --global --unset rerere.enabled
   git config --global --unset diff.algorithm
   git config --global --unset branch.sort
   git config --global --unset tag.sort
   git config --global --unset pull.ff
   ```

   - 何も出ない（設定していないキーも、何も出さずに飛ばされる）
   - 最後のキーを外すと、`~/.gitconfig` の `[pull]` などの節も消える

   <details>
   <summary>補足: 残るもの</summary>

   - `rerere.enabled` で覚えた解き方は、各リポジトリの `.git/rr-cache` に残る。要らなければ手で消す
   - `git init` 済みのリポジトリのブランチ名（`main`）は変わらない

   </details>

1. git-delta を使っていないときだけ、`merge.conflictStyle` も外す。

   ```bash
   git config --global --unset merge.conflictStyle
   ```

   - [git-delta.md](git-delta.md) を通したなら外さない（同じ設定を使う）

1. 名前とメールアドレスも外すときだけ、外す。

   ```bash
   git config --global --unset user.name
   git config --global --unset user.email
   ```

   - 外すと、`git commit` が `Author identity unknown` で止まることがある（検証コンテナでは止まった）

1. 手順 3 で控えた元の値があるキーは、その値で書き戻す。

   - `git config --global <キー> <元の値>` の形で、キーごとに 1 行ずつ貼る
   - 例: 元の `core.autocrlf` を戻すなら `git config --global core.autocrlf <元の値>`

1. 外れたか確かめる。

   ```bash
   git config --global --list
   ```

   - 手順 5・6・8 のキー（外さなかったものを除く）が出なければよい
   - すべて外していれば、何も出ない

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 の git を、同じ `global` の設定にする。pull は rebase で autostash を有効にし、改行は変換しない（`core.autocrlf=false`）。ほかに推奨の設定を入れる
- **進め方**: AlmaLinux 10 は AppStream の `git` を入れる。どちらの OS でも `git config --global` で書く。**読者が書き換えるのは手順 1 の 2 つの変数だけ**
- **状態**: **AlmaLinux 10 は x86_64 のコンテナでのみ検証済み（2026-09-29）。Windows 11 は、実機の Git Bash で流した（2026-09-30。`global` は使い捨ての `HOME`）**
  - 下表の検証コンテナで、**この文書のコードブロックを抜き出したもの**を、一般ユーザーで手順 1〜11 → [改行を変換して clone したリポジトリを直す](#改行を変換して-clone-したリポジトリを直す) → [ロールバック](#ロールバック)の順に流した
  - Windows の模擬として、`/etc/gitconfig` に Git for Windows のインストーラの選択で書かれうる値（`core.autocrlf=true` など 4 つ）を置いて、手順 1・3〜11 をもう 1 度流した
  - 確認したこと: 14 のキーが `global` で効く、`system` の値に勝つ、`pull.ff=only` が rebase を止め手順 8 で通る、CRLF のファイルが変換されずに入る、pull が rebase と autostash をする
  - 2026-09-30: 下表の Windows 11 の PC の Git Bash で、この文書のブロックを抜き出したものを流した（[付録](#付録-windows-11-の-git-bash-での検証記録2026-09-30)）
    - `HOME` を使い捨てのディレクトリにしたので、`global` はそこに書かれた。その PC の `~/.gitconfig` は変えていない（前後で md5 が同じ）。`system` はインストーラが書いた本物
    - 手順 1・3〜7・9〜11（手順 8 は `pull.ff` が空なので飛ばした）、[改行を変換して clone したリポジトリを直す](#改行を変換して-clone-したリポジトリを直す)の手順 1〜4、[ロールバック](#ロールバック)の手順 1〜3・5
    - 確認したこと: インストーラが書いた `system` の値（手順 3 の補足）、`global` の場所（Git Bash・PowerShell・cmd で同じ）、日本語のファイル名がそのまま出ること、CRLF のファイルが変換されずに入ること、pull の rebase と autostash、`rerere` が覚えた解き方を当てること
  - **確認していないこと**: AlmaLinux 10 の実機、aarch64、既存の `~/.gitconfig` との組み合わせ
    - Git for Windows のインストーラの既定の選択で書かれる値（`core.autocrlf=true` など）。検証した PC は別の選択だった
    - Git Bash の端末（mintty）に貼る操作そのもの（検証では、ブロックを 1 つのシェルで順に読み込んだ）

| 項目 | 検証コンテナ | Windows 11 の PC（Git Bash） | 実機（参考。未実施） |
|---|---|---|---|
| 実施日 | 2026-09-29 | 2026-09-30 | — |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1） | Windows 11 Pro 25H2（ビルド 26200）/ x86_64 | AlmaLinux 10.2 / aarch64（Raspberry Pi 5） |
| git | `git-2.52.0-1.el10`（AppStream） | Git for Windows 2.55.0.windows.3（`C:\Program Files\Git`、GNU bash 5.3.15） | `git 2.52.0`（AppStream） |
| `system` | 無し（Windows の模擬では 4 行を置いた） | インストーラが書いた 13 行（[手順 3](#実施手順) の補足） | — |
| `~/.gitconfig` | 無し（手順 4〜6 で作った） | 使い捨ての `HOME` に作った（その PC の `~/.gitconfig` には書いていない） | `[core] autocrlf` と `[user]` だけ（[git-delta.md](git-delta.md#対象と検証環境) の記録） |

- 実機の列は、この手順を適用した結果ではなく、ほかの手順書に残っている現時点の状態

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
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
| `system`（AlmaLinux 10 は `/etc/gitconfig`） | 無し（Windows の模擬では、2 回目の前に置いた） | `C:/Program Files/Git/etc/gitconfig` に、インストーラが書いた 13 行（[手順 3](#実施手順) の補足） |
| `~/.gitconfig` | 無し | その PC の `C:\Users\<WIN_USER>\.gitconfig` にはキーが 4 つあった（検証では使い捨ての `HOME` にしたので、読まれていない） |

### 選択した方針

- **git は AppStream の RPM**
  - Homebrew の git は 2.55.0 で新しいが、git はシステムの道具（dnf で入れる gh などが依存する）なので、RPM の `/usr/bin/git` に揃える
  - 本書の設定で一番新しいのは `push.autoSetupRemote`（git 2.37）で、2.52.0 で足りる
- **`global` に書き、`system` は変えない**
  - 管理者の権限が要らず、AlmaLinux 10 と Windows で同じコマンドになる
  - Windows の `system` はインストーラが書く場所なので、そこを直さず `global` で上書きする
- **Windows は Git Bash に同じ bash のブロックを貼る**
  - PowerShell 向けに書き分けない。git のコマンドは同じで、変数の書き方だけが違うため
  - Git Bash のホームは `/c/Users/<WIN_USER>`（[windows-openssh-server.md](windows-openssh-server.md) の実測）で、`global` は `C:/Users/<WIN_USER>/.gitconfig` だった
    - Windows 11 の PC で、`git config --global --list --show-origin` の場所を見て確かめた（値は読んでいない）
- **pull は `pull.rebase=true`**（依頼どおり）
  - `merges` はマージコミットを残すが、ふだんのブランチでマージコミットを作らないなら `true` で足りる
  - `pull.ff=only` は分岐したときに止まるだけで、rebase の方針と合わない
- **推奨の設定は、既定を変えても困りにくく、日常の操作が楽になるものだけ**
  - 選んだもの・入れなかったものは、手順 6 の補足にある
  - エディタ・署名・認証の設定は、人や PC によって違うので入れていない

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

### 注意点

- **リポジトリの `local` の設定は `global` に勝つ**
  - リポジトリの中で `git config --show-scope --get pull.rebase` と打つと、効いている値と場所が出る
  - `.gitattributes` の `text`・`eol` も、`core.autocrlf` より優先される
- **`core.autocrlf=false` は、CRLF を LF に直さない**
  - Windows のエディタが CRLF で保存したファイルは、CRLF のままコミットされる
  - 改行を揃えたいリポジトリには `.gitattributes` を置く（手順 5 の補足）
- **`sudo git` や root には効かない**: root は root の `~/.gitconfig` を読む
- **`rerere` は、覚えた解き方を黙って当てる**
  - 当てた後も `git add` はしないので、`git diff` で確かめてから add する
  - 間違った解き方を覚えたら、`git rerere forget <ファイル>` で忘れさせる
- **Windows の PowerShell や cmd から呼ぶ git** も、同じ `global`（`C:/Users/<WIN_USER>/.gitconfig`）を読む
  - Windows 11 の PC で、Git Bash・PowerShell・cmd の `git config --global --list --show-origin` が同じファイルを示した
  - その PC では環境変数 `HOME` が `C:\Users\<WIN_USER>` に設定されていた。`HOME` の無い PC は試していない

### 参照

- `git help config` — 各キーの意味と既定値、設定の場所の順（`system` / `global` / `local`）
- `git help pull` — `--rebase`、`--autostash`、`pull.ff`
- `git help gitattributes` — `text`・`eol` と `core.autocrlf` の関係
- `git help rerere` — 解き方の記録と `forget`
- [Git for Windows](https://gitforwindows.org/) — インストーラ
- [Pro Git 8.1 Git の設定](https://git-scm.com/book/ja/v2/Git-%E3%81%AE%E3%82%AB%E3%82%B9%E3%82%BF%E3%83%9E%E3%82%A4%E3%82%BA-Git-%E3%81%AE%E8%A8%AD%E5%AE%9A) — `core.autocrlf` の説明

---

### 付録: コンテナでの検証記録（2026-09-29）

x86_64 のクラウドホストで `dockerd` を動かし、`docker run -d --network host quay.io/almalinuxorg/almalinux:10 sleep infinity` で使い捨てのコンテナを立てた（`docker.io/library/almalinux:10` は `429 Too Many Requests` で取れなかった）。実機と Windows には何も加えていない。

- 検証環境だけの変更: dnf がホストのプロキシを通るように、`/etc/dnf/dnf.conf` に `proxy=` を足し、AlmaLinux のリポジトリを `mirrorlist` から `baseurl` に変え、プロキシの CA を取り込んだ
- 実行ごとに一般ユーザー（NOPASSWD の sudo）を作り直し、**この文書の bash のコードブロックを機械的に抜き出したもの**を、そのユーザーの `bash -s` に流した。書き換えたのは手順 1 の 2 つの値（`Test User` / `test@example.com`）だけ
- `bash -s` には端末が無いので、端末での出力は別に擬似端末（`script`）の中で流して取った
- Windows の模擬の `/etc/gitconfig` は、`core.autocrlf = true`・`pull.rebase = false`・`pull.ff = only`・`init.defaultBranch = master` の 4 行

| 実行 | `/etc/gitconfig` | 流した手順 | 結果 |
|---|---|---|---|
| 1 | 無し | 手順 1〜7・9〜11（手順 8 は `pull.ff` が空なので飛ばした）、[改行を変換して clone したリポジトリを直す](#改行を変換して-clone-したリポジトリを直す)の手順 1〜4、[更新](#更新)の手順 1、[ロールバック](#ロールバック)の手順 1〜3・5 | 手順 2 は `Package git-2.52.0-1.el10.x86_64 is already installed.`（実行 1 の前に、別のユーザーで同じ `sudo dnf install -y git` を流して入れた。そのときは依存を合わせて 74 パッケージが入った）。手順 7 は 14 行が `global`、`pull.ff` は空。手順 9 は `i/crlf  w/crlf`・`main`・`branch 'main' set up to track 'origin/main'.`。手順 10 は `Created autostash` → `Applied autostash.` → `Successfully rebased`、履歴は 1 本、` M crlf.txt` が残った。直す節は、`git -c core.autocrlf=true clone` した 2 ファイルのリポジトリに、CRLF の 1 行を足してから流し、手順 1 で ` M y.txt` と `2`、手順 3 で `0`、手順 4 の後は `w/lf` で差分は足した 1 行だけ。更新は `Nothing to do.`。ロールバックの手順 5 は何も出さなかった |
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
- [更新](#更新)で新しい版に上がるところ（新しい版が無い状態で `sudo dnf upgrade git` を流しただけ）

---

### 付録: Windows 11 の Git Bash での検証記録（2026-09-30）

前の付録の未確認事項のうち、Windows 11 の Git Bash での実行、`global` の置き場所、PowerShell・cmd から呼ぶ git、`rerere` を、次の PC で確かめた。

**環境**:

- Windows 11 Pro 25H2（ビルド 26200、日本語）/ x86_64 のノート PC（AMD Ryzen AI MAX+ 395）。[windows-openssh-server.md](windows-openssh-server.md) を通した PC と同じ
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
| 3 | `git version 2.55.0.windows.3`。`system` の 13 行（[手順 3](#実施手順) の補足）。`global` の行は無い |
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
- aarch64 での実行、[更新](#更新)で新しい版に上がるところ
