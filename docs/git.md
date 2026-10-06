# Git のセットアップ手順（AlmaLinux 10 は AppStream / Windows 11 は winget の Git for Windows）

## 実施手順

- [検証記録](verification/git.md)・[参考資料](reference/git.md)

> [!IMPORTANT]
> - **AlmaLinux 10 では、自分のユーザーのシェルで貼る**。`sudo -i` した root のシェルでは貼らない（設定が root の `~/.gitconfig` に書かれるため）
> - **Windows 11 では、Git for Windows の Git Bash に同じブロックを貼り、手順 2 は飛ばす**。PowerShell や cmd には貼らない（bash の構文のため）
> - Windows に Git for Windows が無ければ、先に[Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)を行う（管理者の Windows PowerShell 5.1 に貼る）。その節の最後で開く Git Bash に、手順 1 から貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: 改行を変換する設定（`core.autocrlf=true`）のときに clone したリポジトリがあれば、[改行を変換して clone したリポジトリを直す](#改行を変換して-clone-したリポジトリを直す)を行う。以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> - **Git for Windows を winget で入れる・上げる・外すブロックは、Windows で流していない**（[Windows 11 で Git for Windows を入れる](#windows-11-で-git-for-windows-を入れる)・[更新](#更新)の手順 2・[ロールバック](#ロールバック)の手順 6）。詳しくは[対象と検証環境](verification/git.md#対象と検証環境)

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

1. AlmaLinux 10 のときだけ、git を入れる。

   ```bash
   sudo dnf install -y git
   ```

   - 入っていれば、`Package git-2.52.0-1.el10.x86_64 is already installed.` と出る（aarch64 では末尾が `.aarch64`）

1. git の版と、今の設定を確かめる。

   ```bash
   git --version
   git config --list --show-scope --show-origin
   ```

   - AlmaLinux 10.2 では `git version 2.52.0` と出る
   - 2 つ目は、設定を `<場所>	file:<ファイル>	<キー>=<値>` の形で 1 行ずつ出す。何も設定していなければ、何も出ない
   - **手順 4〜6 のキー（`user.name`・`core.autocrlf` など）と `pull.ff` は、元の値・スコープ・ファイルを控える**。`global` に無いキーは「global は未設定」と控える（[ロールバック](#ロールバック)で戻す）
   - 実際に追加・変更したキーも控える。既存の値が同じなら「変更なし」、手順 8 を飛ばしたら「`pull.ff` は変更なし」とする
   - Windows では、インストーラが書いた `system` の行（`core.autocrlf=true` など）も出る。手順 5・6 で書く `global` の値が優先される

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
   - 要らないものは、[ロールバック](#ロールバック)の手順 1・4 に従い、そのキーだけ元の設定に戻せる
   - `merge.conflictStyle zdiff3` は [git-delta.md 手順 3](git-delta.md#実施手順) と同じ設定で、どちらを先に通してもよい

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
   - `only` なら、その値とスコープを手順 3 の記録と照合してから手順 8 へ進む

1. 手順 7 で `pull.ff` が `only` だったときだけ、`true` で上書きする。

   ```bash
   git config --global pull.ff true
   git config --show-scope --get pull.ff
   ```

   - `global	true` と出る

   - `pull.ff` を今回変更したことを、手順 3 の元値の記録に書き足す

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
- 手順の後: この節の手順 6 で開いた Git Bash に、[実施手順](#実施手順)の手順 1 から貼る（手順 2 は飛ばす）。以後は[更新](#更新)の手順 2・[ロールバック](#ロールバック)の手順 6
- この節のブロックは、Windows の実機で流していない（[対象と検証環境](verification/git.md#対象と検証環境)）

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
   - 1 行目に scoop の `…\scoop\shims\git.exe` だけが出たら、そのまま進めてよい（この節の[検証記録](verification/git.md)・[参考資料](reference/git.md)）
   - `winget` が見つからないというエラーになったら、Microsoft Store で「アプリ インストーラー」を更新してから始める
   - `True` なら、Git for Windows はもう `C:\Program Files\Git` に入っている。この節の手順 3・4 は飛ばす（新しい版にするなら[更新](#更新)の手順 2）

1. まだ入っていなければ、winget で Git for Windows を PC 全体（`C:\Program Files\Git`）に入れる。

   ```powershell
   winget install --exact --id Git.Git --source winget --scope machine --accept-source-agreements --accept-package-agreements
   winget list --exact --id Git.Git
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と出て、`winget list` に `Git.Git` の行が出ればよい
   - インストーラの画面は出ない（進み具合の小さな窓が出て、終わると消える）。管理者の窓から動かすので、UAC の確認も出ないはず
   - 改行の扱いや `git pull` の動作などは、インストーラの画面の既定の選択で入る

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
   - 1 つ目が何も出ないか、`??`（未追跡）の行だけなら、追跡しているファイルの変更は無い。この節の手順 2 と 4 は飛ばす
   - `??` 以外の行があれば、この節の手順 2 で追跡しているファイルの変更を退避する。未追跡ファイルはそのまま残す

1. この節の手順 1 で `??` 以外の変更が出たときだけ、前の設定のまま stash する。

   ```bash
   git -c core.autocrlf=true stash
   ```

   - `Saved working directory and index state WIP on …` と出る
   - `No local changes to save` なら今回は保存していないので、この節の手順 4 は飛ばす。エラーなら、ここで止めて原因を直す

1. 作業ツリーのファイルを、今の設定で書き直す。

   ```bash
   git rm -r -q --cached .
   git reset -q --hard
   git ls-files --eol | grep -c 'i/lf *w/crlf'
   git status --short
   ```

   - 数は `0` になる
   - `git status --short` は、もともとあった `??` の行以外は出さない

1. この節の手順 2 で保存成功の表示が出たときだけ、今回の変更を戻す。

   ```bash
   git stash pop
   git ls-files --eol
   ```

   - `git status` の形で、元の変更だけが出る
   - 戻したファイルも `w/lf` になる
   - この節の手順 2 からここまでは、別の stash を作らない。`pop` は先頭の stash を戻すため

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
   - **注意**: Git Bash や、Git の bash を使う SSH のセッション・Claude Code が動いていると、インストーラは入れ替えずに終わるはず
   - 上げた後は、Git Bash を開き直し、[手順 7](#実施手順) を貼り直す（`pull.ff` が `only` なら手順 8 も）

---

## ロールバック

- 本書で `global` に書いた設定を外す。`system` と `local` の設定は変えない
- AlmaLinux 10 の git 本体は消さない（gh などが依存している）。Windows 11 の Git for Windows は、外すときだけこの節の手順 6 で外す
- [手順 3](#実施手順) で控えた元の値・スコープと、今回変更したキーの記録を使う。変更しなかったキーはそのまま残す
- この節の手順 1〜5 は、Windows 11 では Git Bash に貼る。この節の手順 6 は、管理者の Windows PowerShell（5.1）に貼る
- この節の手順 6 で Git for Windows を外す PC で、[Windows の OpenSSH サーバーの既定のシェルを Git Bash にする（任意）](windows-openssh-server.md#既定のシェルを-git-bash-にする任意)を行っていたら、先にその節の手順 3 で `DefaultShell` を消す

1. 手順 5・6・8 で今回追加・変更したキーだけ、元に戻す（`merge.conflictStyle` を除く）。

   - 手順 3 の記録で、元の `global` が未設定だったキーだけ、`git config --global --unset <キー>` の形で 1 行ずつ外す
   - 元の `global` に値があったキーは、この節の手順 4 で書き戻す。変更なしのキーと、手順 8 を飛ばした場合の `pull.ff` は触らない
   - 対象は `pull.rebase`・`rebase.autoStash`・`core.autocrlf`・`init.defaultBranch`・`core.quotepath`・`fetch.prune`・`push.autoSetupRemote`・`rerere.enabled`・`diff.algorithm`・`branch.sort`・`tag.sort`・`pull.ff`
   - 例: 今回初めて追加した `core.autocrlf` なら `git config --global --unset core.autocrlf`
   - 外すと何も出ない。最後のキーを外した `~/.gitconfig` の節も消える

1. git-delta を使っていないときだけ、今回変えた `merge.conflictStyle` も元に戻す。

   - [git-delta.md](git-delta.md) を通したならそのまま残す（同じ設定を使う）
   - 今回追加し、元の `global` が未設定なら `git config --global --unset merge.conflictStyle` で外す
   - 元の `global` に値があったなら、この節の手順 4 で書き戻す。変更なしなら触らない

1. 名前とメールアドレスも戻すときだけ、今回変えた値を元に戻す。

   - 今回追加し、元の `global` が未設定だったものだけ、`git config --global --unset user.name` または `git config --global --unset user.email` で外す
   - 元の `global` に値があったものは、この節の手順 4 で書き戻す。変更なしのものは触らない
   - 外すと、`git commit` が `Author identity unknown` で止まることがある（検証コンテナでは止まった）

1. この節の手順 1〜3 で戻すと決めたキーのうち、元の `global` に値があったものは、実施手順 3 の値で書き戻す。

   - `git config --global <キー> <元の値>` の形で、キーごとに 1 行ずつ貼る
   - 例: 元の `core.autocrlf` を戻すなら `git config --global core.autocrlf <元の値>`
   - 空白を含む値は引用符で囲む。元の値が `system` や `local` だけにあった場合は、それを `global` に写さない（今回追加した `global` を外せば、元のスコープの値がまた効く）
   - 残すと決めた `merge.conflictStyle`・名前・メールアドレスと、今回変更しなかったキーは書き戻さない

1. 外れたか確かめる。

   ```bash
   git config --global --list
   ```

   - 今回戻すキーが、手順 3 で記録した元の `global` と一致すればよい（元が未設定なら出ない、元の値があればその値が出る）
   - 残すと決めたキーと、本書で変更しなかったキーはそのまま。元の設定が空で、今回の設定をすべて外した場合だけ、何も出ない

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

---

## 注意点

- **リポジトリの `local` の設定は `global` に勝つ**
  - リポジトリの中で `git config --show-scope --get pull.rebase` と打つと、効いている値と場所が出る
  - `.gitattributes` の `text`・`eol` も、`core.autocrlf` より優先される
- **`core.autocrlf=false` は、CRLF を LF に直さない**
  - Windows のエディタが CRLF で保存したファイルは、CRLF のままコミットされる
  - 改行を揃えたいリポジトリには `.gitattributes` を置く
- **`sudo git` や root には効かない**: root は root の `~/.gitconfig` を読む
- **`rerere` は、覚えた解き方を黙って当てる**
  - 当てた後も `git add` はしないので、`git diff` で確かめてから add する
  - 間違った解き方を覚えたら、`git rerere forget <ファイル>` で忘れさせる
- **Windows の PowerShell や cmd から呼ぶ git** も、同じ `global`（`C:/Users/<WIN_USER>/.gitconfig`）を読む
  - Windows 11 の PC で、Git Bash・PowerShell・cmd の `git config --global --list --show-origin` が同じファイルを示した
- **Git for Windows を上げるときは、Git の bash を使うものを閉じる**
  - Git Bash の窓、既定のシェルを Git Bash にした SSH のセッション、Claude Code の Bash のツールなど。動いていると、winget で上げてもインストーラが入れ替えずに終わるはず（[更新](#更新)の[検証記録](verification/git.md)・[参考資料](reference/git.md)）
- **Git for Windows 2.56.0 から、内部のパスが `mingw64` から `ucrt64` に変わった**（上流のリリースノート）
  - `C:\Program Files\Git\mingw64\bin\git.exe` を直接指す設定は、上げた後に見直す
