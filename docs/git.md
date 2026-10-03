# Git のセットアップ手順（AlmaLinux 10 は AppStream / Windows 11 は winget の Git for Windows）

## 実施手順

> [!IMPORTANT]
> - **AlmaLinux 10 では、自分のユーザーのシェルで貼る**。`sudo -i` した root のシェルでは貼らない（設定が root の `~/.gitconfig` に書かれるため）
> - **Windows 11 では、Git for Windows の Git Bash に同じブロックを貼り、手順 2 は飛ばす**。PowerShell や cmd には貼らない（bash の構文のため）
> - Windows に Git for Windows が無ければ、先に[Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)を行う（管理者の Windows PowerShell 5.1 に貼る）。その節の最後で開く Git Bash に、手順 1 から貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 改行を変換する設定（`core.autocrlf=true`）のときに clone したリポジトリがあれば、[改行を変換して clone したリポジトリを直す](#改行を変換して-clone-したリポジトリを直す)を行う。以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> - **AlmaLinux 10 は x86_64 のコンテナでのみ検証した**。実機では本実行していない
> - **Windows 11 は、実機の Git Bash で `HOME` を使い捨てのディレクトリにして流した**（その PC の `~/.gitconfig` には書いていない）
> - **Git for Windows を winget で入れる・上げる・外すブロックは、Windows で流していない**（[Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)・[更新](#更新)の手順 2・[ロールバック](#ロールバック)の手順 6）。詳しくは[対象と検証環境](#対象と検証環境)

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

## Windows 11 で Git for Windows を入れる

> [!IMPORTANT]
> - **すべて Windows で行う**。この節の手順 1 で管理者の Windows PowerShell（5.1）を開き、この節の手順 2・3 と、[更新](#更新)の手順 2・[ロールバック](#ロールバック)の手順 6 のブロックをそこに貼る（PC 全体の `C:\Program Files\Git` に入れるので、管理者の権限が要る）
> - 前提: [Windows 11 の初期設定の手順 16〜19](windows-setup.md#実施手順)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - **この節の手順 4 で PowerShell を開き直し、手順 6 で Git Bash を開く**

- Git for Windows が無い Windows 11 の PC で、[実施手順](#実施手順)より先に行う。上から順にコードブロックを貼る。変数は無い
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: この節の手順 6 で開いた Git Bash に、[実施手順](#実施手順)の手順 1 から貼る（手順 2 は飛ばす）。以後は[更新](#更新)の手順 2・[ロールバック](#ロールバック)の手順 6
- この節のブロックは、Windows の実機で流していない（[対象と検証環境](#対象と検証環境)）

1. Windows で、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. Git for Windows がまだ入っていないことを確かめる。

   ```powershell
   Get-Command git -All -ErrorAction SilentlyContinue | Format-Table Source
   Test-Path 'C:\Program Files\Git\bin\bash.exe'
   winget list --exact --id Git.Git --accept-source-agreements
   ```

   - 1 行目は何も出さず、`False` と、`入力条件に一致するインストール済みのパッケージが見つかりませんでした。`（英語の Windows では `No installed package found matching input criteria.`）が出ればよい
   - `False` で、1 行目に `…\AppData\Local\Programs\Git\cmd\git.exe` が出たら、管理者の権限無しで入れた Git for Windows がある。それを外してから始める（ほかの手順書が `C:\Program Files\Git` を前提にしている）
   - 1 行目に scoop の `…\scoop\shims\git.exe` だけが出たら、そのまま進めてよい（この節の手順 5 の補足）
   - `winget` が見つからないというエラーになったら、Microsoft Store で「アプリ インストーラー」を更新してから始める
   - `True` なら、Git for Windows はもう `C:\Program Files\Git` に入っている。この節の手順 3・4 は飛ばす（新しい版にするなら[更新](#更新)の手順 2）

   <details>
   <summary>補足: 確かめていること</summary>

   - Git for Windows を PC 全体に入れると、`git` は `C:\Program Files\Git\cmd\git.exe`、Git Bash は `C:\Program Files\Git\git-bash.exe`（スタートメニューの Git Bash）と `C:\Program Files\Git\bin\bash.exe`（ほかのプログラムから bash を起動する入口）になる
   - `bin\bash.exe` は、[Windows の OpenSSH サーバーの既定のシェルを Git Bash にする（任意）](windows-openssh-server.md#既定のシェルを-git-bash-にする任意)が決め打ちにしている。Claude Code（Windows）の公式の文書も、Git Bash の場所の例にこのパスを挙げる
   - 管理者の権限が無いと、インストーラは入れる先の既定を `%LOCALAPPDATA%\Programs\Git` に変える（上流の `install.iss`。画面で入れるとき）。その形では、上の 2 つのパスが無い
   - `--accept-source-agreements` は、winget を初めて使う PC で出るソースの同意の問いに答えるため（続けて貼った行が答えとして食われないように）

   </details>

1. まだ入っていなければ、winget で Git for Windows を PC 全体（`C:\Program Files\Git`）に入れる。

   ```powershell
   winget install --exact --id Git.Git --source winget --scope machine --accept-source-agreements --accept-package-agreements
   winget list --exact --id Git.Git
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と出て、`winget list` に `Git.Git` の行が出ればよい
   - インストーラの画面は出ない（進み具合の小さな窓が出て、終わると消える）。管理者の窓から動かすので、UAC の確認も出ないはず
   - 改行の扱いや `git pull` の動作などは、インストーラの画面の既定の選択で入る（この手順の補足）

   <details>
   <summary>補足: winget の定義と、黙って入れたときの選択</summary>

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
   - `system` の改行・`git pull`・ブランチ名は、[実施手順](#実施手順)の手順 5・6 で `global` に書いて上書きする
   - 上げるとき・入れ直すときは、前に入れたときの選択を引き継ぐ（インストーラが前の選択を覚えている）
   - 選択は `--custom '/o:CRLFOption=CRLFCommitAsIs'` のように渡して変えられるが、本書では渡さない（[選択した方針](#選択した方針)）

   </details>

1. この節の手順 3 で入れたときは、Windows PowerShell を閉じて開き直す。

   - この節の手順 3 で PC 全体の `PATH` に足された `C:\Program Files\Git\cmd` は、開いていた PowerShell には入らない
   - 開き直す PowerShell は、管理者でなくてよい
   - **次の手順は、PowerShell を開き直してから貼る**（開いていた窓では `git` が見つからない）

1. git の場所と版と、Git Bash があることを確かめる。

   ```powershell
   Get-Command git -All | Format-Table Source
   git --version
   Test-Path 'C:\Program Files\Git\bin\bash.exe', 'C:\Program Files\Git\git-bash.exe'
   ```

   - 1 行目の一番上に `C:\Program Files\Git\cmd\git.exe` が出ればよい
   - `git version 2.55.0.windows.5` の形の行（版は実行した日の最新）と、`True` が 2 行出ればよい
   - インストーラは `system`（`C:/Program Files/Git/etc/gitconfig`）に `core.autocrlf=true`・`pull.rebase=false`・`init.defaultBranch=master` などを書く。[実施手順](#実施手順)の手順 5・6 の `global` で上書きし、手順 7 で確かめる（`pull.ff` が `only` なら手順 8 も）

   <details>
   <summary>補足: PATH と、ほかの git</summary>

   - `PATH` に足されるのは `C:\Program Files\Git\cmd`（`git.exe`・`git-gui.exe` など）だけ。`bash`・`ssh`・`ls` などは足されないので、PowerShell の `ssh` は Windows のものが使われる
     - 以前の検証の PC は Git の `usr\bin` も `PATH` にあり、`ssh`・`ssh-keygen` が Git のものになっていた（[windows-openssh-server.md 手順 7](windows-openssh-server.md#実施手順) の補足）
   - Windows の `PATH` は、PC 全体の値の後ろに自分のユーザーの値が続く。scoop の git（`…\scoop\shims\git.exe`。自分のユーザーの `PATH`）があっても、新しく開いた窓では Git for Windows の `git` が先に見つかる
   - scoop は、scoop の git が入っていなければ `PATH` の `git` を使う（scoop のソースの `Get-HelperPath`）。そのため、`scoop update` と `scoop bucket add` は Git for Windows の `git` で動く。scoop の git が入っていると、scoop はそちらを使う
   - Claude Code（Windows）は、Git for Windows があれば Bash のツールを Git Bash で動かし、無ければ PowerShell のツールだけを使う（公式の setup の文書）

   </details>

1. スタートメニューから Git Bash を開く。

   - スタートメニューで「Git Bash」を探して開く（管理者でなくてよい）
   - `<WIN_USER>@<HOSTNAME> MINGW64 ~` のような行と、`$` のプロンプトの窓が開く
   - **次は、この Git Bash に[実施手順](#実施手順)の手順 1 から貼る**（手順 2 は飛ばす）

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

- この節の手順 1 は AlmaLinux 10 の端末に、手順 2 は Windows 11 の管理者の Windows PowerShell（5.1）に貼る（[Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)と同じ前提）

1. AlmaLinux 10 で、git を更新する。

   ```bash
   sudo dnf upgrade git
   ```

   - 通常の `sudo dnf upgrade` にも含まれる
   - 新しい版が無ければ、`Nothing to do.` と出る

1. Windows 11 では、Git Bash を閉じてから、winget で Git for Windows を上げる。

   ```powershell
   winget upgrade --exact --id Git.Git --source winget --accept-source-agreements --accept-package-agreements
   winget list --exact --id Git.Git
   ```

   - 上がったら `インストールが完了しました` と出て、`winget list` の `Git.Git` の版が新しくなる
   - 新しい版が無ければ、`利用可能なアップグレードが見つかりませんでした。`（英語の Windows では `No available upgrade found.`）と出る
   - **注意**: Git Bash や、Git の bash を使う SSH のセッション・Claude Code が動いていると、インストーラは入れ替えずに終わるはず（この手順の補足）
   - 上げた後は、Git Bash を開き直し、[手順 7](#実施手順) を貼り直す（`pull.ff` が `only` なら手順 8 も）

   <details>
   <summary>補足: winget での更新</summary>

   - 定義の `UpgradeBehavior: install` のとおり、新しい版のインストーラを今のものの上から動かす。入れる先（`C:\Program Files\Git`）と、前に入れたときの選択（改行の扱いなど）は引き継ぐ。そのため `--scope` は付けない
   - インストーラは、Git のファイル（`msys-2.0.dll` など）を使っているプロセスがあると、閉じるよう求める画面を出す。黙って動かすときはその問いが「キャンセル」で答えられ、入れ替えずに終わる（上流の `install.iss` を読んだだけで、確かめていない）
   - 公式のインストーラで入れた PC でも、winget が `Git.Git` と結び付けて表示すれば、同じ形で上がるはず（確かめていない）。`winget list --exact --id Git.Git` に出なければ、[Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)の手順 3 を貼る（今のものの上から入れる）
   - インストーラの部品の「毎日の更新の確認」は既定で入れないので、Git for Windows は自分では上がらない

   </details>

---

## ロールバック

- 本書で `global` に書いた設定を外す。`system` と `local` の設定は変えない
- AlmaLinux 10 の git 本体は消さない（gh などが依存している）。Windows 11 の Git for Windows は、外すときだけこの節の手順 6 で外す
- [手順 3](#実施手順) で控えた元の値は、この節の手順 4 で書き戻す
- この節の手順 1〜5 は、Windows 11 では Git Bash に貼る。この節の手順 6 は、管理者の Windows PowerShell（5.1）に貼る
- この節の手順 6 で Git for Windows を外す PC で、[Windows の OpenSSH サーバーの既定のシェルを Git Bash にする（任意）](windows-openssh-server.md#既定のシェルを-git-bash-にする任意)を行っていたら、先にその節の手順 3 で `DefaultShell` を消す

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

1. Windows 11 で Git for Windows も外すときだけ、Git Bash を閉じてから winget で外す。

   ```powershell
   winget uninstall --exact --id Git.Git --source winget
   winget list --exact --id Git.Git
   Test-Path 'C:\Program Files\Git\bin\bash.exe'
   ```

   - `正常にアンインストールされました`（英語の Windows では `Successfully uninstalled`）と出て、`winget list` が `入力条件に一致するインストール済みのパッケージが見つかりませんでした。` を出し、`False` が出ればよい
   - **注意**: Claude Code（Windows）の Bash のツールは Git Bash を使う。外すと、PowerShell のツールだけになる
   - **注意**: [Windows の OpenSSH サーバーの既定のシェルを Git Bash にする（任意）](windows-openssh-server.md#既定のシェルを-git-bash-にする任意)の `DefaultShell` は `C:\Program Files\Git\bin\bash.exe` を指す。外すと、無いファイルを指したままになる（この節のリードのとおり、先に消す）
   - scoop の git が無い PC では、`scoop update` が git を求めて止まるようになる
   - `global`（`C:\Users\<WIN_USER>\.gitconfig`）は消えない（この節の手順 1〜5 で外す）

   <details>
   <summary>補足: winget での削除</summary>

   - winget は、インストーラが「アプリと機能」に書いた静かな削除のコマンド（`C:\Program Files\Git\unins000.exe /SILENT`）を動かす。Inno Setup の削除のプログラムは、`/SILENT` では確かめの問いを出さない
   - Git for Windows の削除のプログラムは、`PATH` から `C:\Program Files\Git\cmd` を外す（上流の `install.iss`）
   - 管理者でない窓から貼ると、削除のプログラムが UAC で昇格を求めるはず（確かめていない）

   </details>

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 の git を、同じ `global` の設定にする。pull は rebase で autostash を有効にし、改行は変換しない（`core.autocrlf=false`）。ほかに推奨の設定を入れる
- **進め方**: AlmaLinux 10 は AppStream の `git` を入れる。Windows 11 は、Git for Windows を winget の `Git.Git` で PC 全体（`C:\Program Files\Git`）に入れ（[Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)）、Git Bash に同じブロックを貼る。どちらの OS でも `git config --global` で書く。**読者が書き換えるのは手順 1 の 2 つの変数だけ**
- **状態**: **AlmaLinux 10 は x86_64 のコンテナでのみ検証済み（2026-09-29）。Windows 11 は、実機の Git Bash で流した（2026-09-30。`global` は使い捨ての `HOME`）。Git for Windows を winget で入れる・上げる・外すブロックは、Windows で流していない（2026-10-03 に足した）**
  - 下表の検証コンテナで、**この文書のコードブロックを抜き出したもの**を、一般ユーザーで手順 1〜11 → [改行を変換して clone したリポジトリを直す](#改行を変換して-clone-したリポジトリを直す) → [ロールバック](#ロールバック)の順に流した
  - Windows の模擬として、`/etc/gitconfig` に Git for Windows のインストーラの選択で書かれうる値（`core.autocrlf=true` など 4 つ）を置いて、手順 1・3〜11 をもう 1 度流した
  - 確認したこと: 14 のキーが `global` で効く、`system` の値に勝つ、`pull.ff=only` が rebase を止め手順 8 で通る、CRLF のファイルが変換されずに入る、pull が rebase と autostash をする
  - 2026-09-30: 下表の Windows 11 の PC の Git Bash で、この文書のブロックを抜き出したものを流した（[付録](#付録-windows-11-の-git-bash-での検証記録2026-09-30)）
    - `HOME` を使い捨てのディレクトリにしたので、`global` はそこに書かれた。その PC の `~/.gitconfig` は変えていない（前後で md5 が同じ）。`system` はインストーラが書いた本物
    - 手順 1・3〜7・9〜11（手順 8 は `pull.ff` が空なので飛ばした）、[改行を変換して clone したリポジトリを直す](#改行を変換して-clone-したリポジトリを直す)の手順 1〜4、[ロールバック](#ロールバック)の手順 1〜3・5
    - 確認したこと: インストーラが書いた `system` の値（手順 3 の補足）、`global` の場所（Git Bash・PowerShell・cmd で同じ）、日本語のファイル名がそのまま出ること、CRLF のファイルが変換されずに入ること、pull の rebase と autostash、`rerere` が覚えた解き方を当てること
  - 2026-10-03: [Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)と、[更新](#更新)の手順 2（winget で上げる）・[ロールバック](#ロールバック)の手順 6（winget で外す）を足した。**Windows の実機では流していない**（書いた環境のクラウドの Linux のコンテナでは、Windows を動かせない）
    - 確かめたこと: winget の定義（`Git.Git` 2.55.0.5 のスコープ・インストーラの種類・スイッチ・sha256）、インストーラの sha256 と Authenticode の署名者、上流の `install.iss`（入れる先・権限・黙って入れたときの選択・`system` に書く値・使われているときの動き）、winget のソース（Inno Setup のインストーラに渡すスイッチ・スコープの既定・削除のコマンド）（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査、偽の `winget` に渡る引数（[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
    - 確かめていないこと: Windows で貼ること（その節のすべての手順・更新・削除）、UAC が出ないこと、`system` に書かれる値、Git Bash が開くこと、公式のインストーラで入れた PC を winget で上げること、arm64 の Windows
  - **確認していないこと**: AlmaLinux 10 の実機、aarch64、既存の `~/.gitconfig` との組み合わせ
    - Git for Windows のインストーラの既定の選択で書かれる値（`core.autocrlf=true` など）。検証した PC は別の選択だった（[Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)は、この既定で入る。上流のソースを読んだだけ）
    - Git Bash の端末（mintty）に貼る操作そのもの（検証では、ブロックを 1 つのシェルで順に読み込んだ）

| 項目 | 検証コンテナ | Windows 11 の PC（Git Bash） | 実機（参考。未実施） |
|---|---|---|---|
| 実施日 | 2026-09-29 | 2026-09-30 | — |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1） | Windows 11 Pro 25H2（ビルド 26200）/ x86_64 | AlmaLinux 10.2 / aarch64（Raspberry Pi 5） |
| git | `git-2.52.0-1.el10`（AppStream） | Git for Windows 2.55.0.windows.3（`C:\Program Files\Git`、GNU bash 5.3.15） | `git 2.52.0`（AppStream） |
| `system` | 無し（Windows の模擬では 4 行を置いた） | インストーラが書いた 13 行（[手順 3](#実施手順) の補足） | — |
| `~/.gitconfig` | 無し（手順 4〜6 で作った） | 使い捨ての `HOME` に作った（その PC の `~/.gitconfig` には書いていない） | `[core] autocrlf` と `[user]` だけ（[git-delta.md](git-delta.md#対象と検証環境) の記録） |

- 実機の列は、この手順を適用した結果ではなく、ほかの手順書に残っている現時点の状態

[Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)の節（前提にしている環境。Windows では流していない）:

| 項目 | 値 |
|---|---|
| OS | Windows 11 / x64（ほかの Windows の手順書の実機の記録と同じ PC を想定） |
| PowerShell | 管理者の Windows PowerShell 5.1 |
| winget | Windows 11 の「アプリ インストーラー」に入っているもの |
| Git for Windows | 2.55.0.5（winget の `Git.Git` の 2026-10-03 の最新の定義）。`C:\Program Files\Git` |

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

- [Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)は、Git for Windows が入っていない PC を前提にしている（Windows では流していない）

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

Windows 11 で Git for Windows を入れる経路を比べた（2026-10-03 時点）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `Git.Git` を `--scope machine` で** | 上流のインストーラを、winget が sha256 を確かめてから黙って動かす。`C:\Program Files\Git` に入り、`winget upgrade` で上がる。管理者の権限が要る | **採用** |
| winget の `--scope user` | 同じインストーラで、winget はスコープのスイッチを渡さない。入る先はインストーラが権限で決める | 不採用（PC 全体に入れるので、winget にも `machine` を指定する） |
| 上流のインストーラを落として、画面で入れる | 選択を画面で選べる。版の確認と更新は手作業 | 不採用（以前の検証の PC はこの形で、もとの本書もこれを案内していた） |
| scoop の `main/git` | Git for Windows の持ち運び版（PortableGit）を `~\scoop\apps\git` に入れ、`git` などを `~\scoop\shims` に置く。`C:\Program Files\Git\bin\bash.exe` が無い | 不採用（[Windows の OpenSSH サーバー](windows-openssh-server.md#既定のシェルを-git-bash-にする任意)が `C:\Program Files\Git` を前提にしている。[Windows 11 の初期設定](windows-setup.md)も、scoop の git を入れなくなった） |

- **インストーラの選択は既定のまま**（winget の `--custom` や `--override` で `/o:` を渡さない）
  - 本書は `system` を変えず `global` で上書きするので、`system` の `core.autocrlf=true`・`pull.rebase=false`・`init.defaultBranch=master` は既定のままでよい（[実施手順](#実施手順)の手順 7 で確かめる）
  - 既定の PATH の選択（`cmd` だけを足す）で、PowerShell・scoop・Claude Code から `git` が見つかる。Unix の道具まで足す選択は、Windows の `find`・`sort` を隠す（インストーラの画面の警告）
  - `--override` は、winget が渡す黙って動かすスイッチ（`/SP- /SILENT …`）ごと置き換える（winget のソース）
- **Git for Windows は、scoop の `scoop update` が使う git も兼ねる**
  - scoop は、scoop の git が入っていなければ `PATH` の `git` を使う（[Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)の手順 5 の補足）

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
- **Git for Windows を上げるときは、Git の bash を使うものを閉じる**
  - Git Bash の窓、既定のシェルを Git Bash にした SSH のセッション、Claude Code の Bash のツールなど。動いていると、winget で上げてもインストーラが入れ替えずに終わるはず（[更新](#更新)の手順 2 の補足）
- **Git for Windows 2.56.0 から、内部のパスが `mingw64` から `ucrt64` に変わった**（上流のリリースノート）
  - `C:\Program Files\Git\mingw64\bin\git.exe` を直接指す設定は、上げた後に見直す
  - 2026-10-03 の winget の定義はまだ 2.55.0.5 で、本書では 2.56.0 を試していない

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

---

### 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、winget の定義・インストーラ・上流と winget のソースを読んだ記録。[Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)・[更新](#更新)の手順 2・[ロールバック](#ロールバック)の手順 6 は、これをもとに書いた。

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

- `powershell` のブロック 5 個（[Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)の手順 2・3・5、[更新](#更新)の手順 2、[ロールバック](#ロールバック)の手順 6）を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。指摘は 0

**偽の `winget` で流した**: 5 個のブロックを、受け取った引数を数えて表示するだけの関数 `winget` を置いた pwsh で、順に流した:

- `winget` には、どのブロックでも書いたとおりの引数が 1 つずつ渡った。手順 3 の `install` は 10 個（`install`・`--exact`・`--id`・`Git.Git`・`--source`・`winget`・`--scope`・`machine`・`--accept-source-agreements`・`--accept-package-agreements`）
- 2 つのパスを渡した `Test-Path` は、`False` を 2 行出した（Linux なので、どちらも無い）。`Get-Command git -All | Format-Table Source` は、Linux の `git` の場所を表にした
- winget そのものの動き（定義の選び方・インストーラの起動・表示）は、Windows でしか確かめられない

**残っている未確認事項**:

1. Windows で、[Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)の手順 1〜6 を通すこと（管理者の窓から UAC が出ずに入ること、`C:\Program Files\Git` に入ること、`PATH`、Git Bash が開くこと）
1. 黙って入れたときに `system` に書かれる値が、その節の手順 3 の補足の表のとおりになること。その後に、[実施手順](#実施手順)の手順 1・3〜11 を Git Bash で通すこと
1. [更新](#更新)の手順 2 で新しい版に上がること（2.56.0 が winget に載った後）と、Git Bash を開いたまま上げたときの動き
1. [ロールバック](#ロールバック)の手順 6 で外れること（`PATH` から外れること、残るもの）
1. 公式のインストーラで入れた PC を、winget で上げること
1. arm64 の Windows
