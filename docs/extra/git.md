# Git のセットアップ手順（AlmaLinux 10 は AppStream / Windows 11 は winget の Git for Windows）のロールバックと注意点

[手順書](../git.md)・[検証記録](../verification/git.md)・[参考資料](../reference/git.md)

- 「手順 N」は[手順書](../git.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- 本書で `global` に書いた設定を外す。`system` と `local` の設定は変えない
- AlmaLinux 10 の git 本体は消さない（gh などが依存している）。Windows 11 の Git for Windows は、外すときだけこの節の手順 6 で外す
- [手順 3](../git.md#実施手順) で控えた元の値・スコープと、今回変更したキーの記録を使う。変更しなかったキーはそのまま残す
- この節の手順 1〜5 は、Windows 11 では Git Bash に貼る。この節の手順 6 は、管理者の Windows PowerShell（5.1）に貼る
- この節の手順 6 で Git for Windows を外す PC で、[Windows の OpenSSH サーバーの既定のシェルを Git Bash にする（任意）](../windows-openssh-server.md#既定のシェルを-git-bash-にする任意)を行っていたら、先にその節の手順 3 で `DefaultShell` を消す

1. 手順 5・6・8 で今回追加・変更したキーだけ、元に戻す（`merge.conflictStyle` を除く）。

   - 手順 3 の記録で、元の `global` が未設定だったキーだけ、`git config --global --unset <キー>` の形で 1 行ずつ外す
   - 元の `global` に値があったキーは、この節の手順 4 で書き戻す。変更なしのキーと、手順 8 を飛ばした場合の `pull.ff` は触らない
   - 対象は `pull.rebase`・`rebase.autoStash`・`core.autocrlf`・`init.defaultBranch`・`core.quotepath`・`fetch.prune`・`push.autoSetupRemote`・`rerere.enabled`・`diff.algorithm`・`branch.sort`・`tag.sort`・`pull.ff`
   - 例: 今回初めて追加した `core.autocrlf` なら `git config --global --unset core.autocrlf`
   - 外すと何も出ない。最後のキーを外した `~/.gitconfig` の節も消える

1. git-delta を使っていないときだけ、今回変えた `merge.conflictStyle` も元に戻す。

   - [git-delta.md](../git-delta.md) を通したならそのまま残す（同じ設定を使う）
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
   - 元は `~/.gitconfig` が無かった場合も、空のファイルが残る（中身が無いので、git の動きは変わらない）

1. Windows 11 で Git for Windows も外すときだけ、Git Bash を閉じてから winget で外す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget uninstall --exact --id Git.Git --source winget
   winget list --exact --id Git.Git --source winget
   Test-Path 'C:\Program Files\Git\bin\bash.exe'
   ```

   - `正常にアンインストールされました`（英語の Windows では `Successfully uninstalled`）と出て、`winget list` が `入力条件に一致するインストール済みのパッケージが見つかりませんでした。` を出し、`False` が出ればよい
   - **注意**: Claude Code（Windows）の Bash のツールは Git Bash を使う。外すと、PowerShell のツールだけになる
   - **注意**: [Windows の OpenSSH サーバーの既定のシェルを Git Bash にする（任意）](../windows-openssh-server.md#既定のシェルを-git-bash-にする任意)の `DefaultShell` は `C:\Program Files\Git\bin\bash.exe` を指す。外すと、無いファイルを指したままになる（この節のリードのとおり、先に消す）
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
  - Git Bash の窓、既定のシェルを Git Bash にした SSH のセッション、Claude Code の Bash のツールなど。動いていると、winget で上げてもインストーラが入れ替えずに終わるはず（[更新](../git.md#更新)の[検証記録](../verification/git.md)・[参考資料](../reference/git.md)）
- **Git for Windows 2.56.0 から、内部のパスが `mingw64` から `ucrt64` に変わった**（上流のリリースノート）
  - `C:\Program Files\Git\mingw64\bin\git.exe` を直接指す設定は、上げた後に見直す
