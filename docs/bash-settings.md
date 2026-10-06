# bash の履歴・補完・キー操作の設定手順（AlmaLinux 10）

## 実施手順

- [検証記録](verification/bash-settings.md)・[参考資料](reference/bash-settings.md)

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **自分のユーザーのシェルで実行する**。`sudo -i` した root のシェルでは行わない（root の `~/.bashrc` と `~/.inputrc` は対象外）
> - **手順 1 だけ `sudo` を使う**（bash-completion の RPM。Workstation で入れた PC には最初から入っている）
> - **手順 4 は、[Homebrew](homebrew.md) を入れたホストだけ**で行う。共通設定が fzf より前に補完を読む
> - **手順 6 は、端末を開き直す操作**。手順 7 は開き直した端末で貼り、手順 8 はキーを押して確かめる

- 上から順にコードブロックを貼る。変数は無い
- 手順の後: 履歴を曖昧検索で探す Ctrl+R などは [fzf](fzf.md)。以後は[ロールバック](#ロールバック)（設定だけなので、更新の節は無い）

1. bash-completion が入っているか確かめ、無ければ入れる。

   ```bash
   if ! rpm -q bash-completion; then sudo dnf install -y bash-completion; fi
   ```

   - `bash-completion-2.11-…` と出れば入っている（Workstation で入れた PC は、グループ `Standard` の既定のパッケージとして最初から入っている）
   - `package bash-completion is not installed` のときは、続けて BaseOS から入る（依存の `pkgconf` 系 4 つも入る）

1. 今のシェルにも bash-completion を読み込み、読まれたことを確かめる。

   ```bash
   . /etc/profile.d/bash_completion.sh
   complete -p -D
   printf '%s\n' "${BASH_COMPLETION_VERSINFO[*]}"
   ```

   - `complete -F _completion_loader -D` と `2 11` が出る。Workstation では、既定の補完が `complete -F _python_argcomplete_global -D` になっている場合もある
   - 最初から入っていたホストでは、どちらも読み込む前から出る（2 回読んでも何も起きない）

1. 共通設定から履歴と shopt を読み込み、値を確かめる。

   ```bash
   . ~/.bashrc
   printf '%s\n' "$HISTSIZE" "$HISTFILESIZE" "$HISTCONTROL"
   shopt histappend autocd cdspell dirspell globstar
   ```

   - `100000`・`100000`・`ignoreboth`、5 つの `on` が出る
   - これらの設定は bash リポジトリにあり、`~/.bashrc` には追記しない

1. Homebrew を入れたホストでは、共通設定が補完を読んだことを確かめる。

   ```bash
   complete -p brew
   ```

   - `-F _brew brew` を含む定義が出る
   - 共通設定が Homebrew の補完を fzf より前に読む。読み込み行の追加や並べ替えは不要

1. `~/.inputrc` を書き、今のシェルにも読ませる。

   ```bash
   if [ -e ~/.inputrc ]; then
     echo '中断: ~/.inputrc がすでにある。中身を見て、この手順の set と矢印の行を手で足す' >&2
   else
     cat > ~/.inputrc <<'EOF'
   # OS の設定（Home / End / Delete、Ctrl+矢印の単語の移動など）を先に読む。この行が無いと読まれなくなる
   $include /etc/inputrc
   # 補完: 大文字小文字を区別しない、候補が複数なら 1 回の Tab で一覧を出す、種類と打った部分を色で示す
   set completion-ignore-case on
   set show-all-if-ambiguous on
   set colored-stats on
   set colored-completion-prefix on
   # ↑/↓: 打った文字で始まる履歴だけをさかのぼる（何も打っていなければ 1 つずつ）
   "\e[A": history-search-backward
   "\e[B": history-search-forward
   "\eOA": history-search-backward
   "\eOB": history-search-forward
   EOF
     bind -f ~/.inputrc
     bind -v | grep -E 'completion-ignore-case|show-all-if-ambiguous|colored-stats|colored-completion-prefix'
     bind -q history-search-backward
     bind -q beginning-of-line
   fi
   ```

   - `set … on` が 4 行、`history-search-backward can be invoked via "\eOA", "\e[5~", "\e[A".`、`beginning-of-line can be invoked via "\C-a", "\eOH", "\e[1~", "\e[H".` が出る
   - `beginning-of-line` に `"\e[1~"` が無ければ、`$include /etc/inputrc` の行が読まれていない
   - `中断:` が出たら、すでにある `~/.inputrc` に、`$include /etc/inputrc` が無ければ先頭に足し、`set` の 4 行と矢印の 4 行を手で足す。足したら `bind -f ~/.inputrc`

1. 開いている端末を閉じて、開き直す。

   - SSH なら、`exit` してログインし直す
   - 今のシェルでは手順 3〜5 を読み直してあるが、新しいシェルで効くことを次の手順で確かめる
   - **次の手順は、開き直した端末で貼る**

1. 開き直したシェルで、設定が効いていることを確かめる。

   ```bash
   printf '%s\n' "${HISTSIZE}" "${HISTFILESIZE}" "${HISTCONTROL}"
   shopt histappend autocd cdspell dirspell globstar
   complete -p -D
   bind -v | grep -E 'completion-ignore-case|show-all-if-ambiguous|colored-stats|colored-completion-prefix'
   bind -q history-search-backward
   ```

   - 手順 3 と同じ値、手順 2 と同じ既定の補完（`_completion_loader` または `_python_argcomplete_global`）、`set … on` が 4 行、`"\eOA", "\e[5~", "\e[A"` が出る
   - Homebrew のホストでは、続けて `complete -p brew` が `-F _brew brew` を含む補完定義を出す

1. キーを押して、補完と履歴の検索を確かめる。

   - `systemctl star` と打って Tab: `systemctl start ` になる（bash-completion）
   - `ls /usr/s` と打って Tab: 1 回で `sbin/ share/ src/` の一覧が色付きで出る（`show-all-if-ambiguous`・`colored-stats`）
   - `cd /usr/SH` と打って Tab: `cd /usr/share/` になる（`completion-ignore-case`）
   - `printf` と打って ↑: 手順 7 の `printf '%s\n' …` の行が出る（`history-search-backward`。カーソルは `printf` の後ろに残る）。Ctrl+C で捨てる
   - `/usr/share` と打って Enter: `cd -- /usr/share` と出て移る（`autocd`）。`cd /usr/shaer` と打って Enter: `/usr/share` と出て移る（`cdspell`）。`cd` で戻る
   - `ls /usr/share/doc/bash-completion/**/*.md` と打って Enter: サブディレクトリの `.md` も出る（`globstar`）
   - Homebrew のホストでは、`eza --gi` と打って Tab: `--git  --git-ignore  --git-repos  --git-repos-no-status` の一覧が出て、`eza --git` まで入る

---

## ロールバック

- `~/.inputrc` と、必要なら共通設定を戻す。bash-completion の RPM は、手順 1 で入れたホストだけ消す

> [!WARNING]
> **この節の手順 2 の後に閉じたシェルは、`~/.bash_history` を既定の 1,000 行に切り詰める**。残したい履歴があれば、この節の手順 1 で控える。

1. 履歴のファイルを控える。

   ```bash
   cp -p ~/.bash_history ~/.bash_history.bak
   wc -l ~/.bash_history.bak
   ```

   - 行数が出る。要らなくなったら `~/.bash_history.bak` は手で消す

1. 共通設定の履歴・補完も戻したい場合だけ、bash リポジトリの設定を戻す。

   - [bash のロールバック](https://github.com/ryo-aoki-pc/bash/blob/main/docs/quick-start.md#ロールバック)を参照する。ほかのツールの共通設定も外れる
   - `~/.inputrc` と bash-completion だけを戻すなら、この手順は飛ばす

1. 手順 5 で作った `~/.inputrc` を消す。

   ```bash
   rm -f ~/.inputrc
   ```

   - 手順 5 が `中断:` で、すでにあった `~/.inputrc` に手で足したホストでは、足した行だけを手で消す

1. 手順 1 で bash-completion を入れたホストだけ、RPM を消す。

   ```bash
   sudo dnf remove bash-completion
   ```

   - `Removing:` に `bash-completion`、`Removing unused dependencies:` に `pkgconf` 系の 4 つが出る。`Is this ok [y/N]:` に `y`
   - 最初から入っていたホスト（Workstation）では貼らない
   - **次の手順は、`y` と答えてプロンプトに戻ってから行う**

1. 開いている端末を閉じて、開き直す。

   - 今のシェルには `bind -f` した設定と `shopt` が残っている。新しいシェルは既定に戻る

---

## 注意点

- **`~/.inputrc` を作ったら `$include /etc/inputrc` を忘れない**: 無いと Home / End / Delete / Ctrl+矢印が効かなくなる
- **`globstar` は `rm` でも効く**: `rm **` はサブディレクトリの中まで消す。`**` を打つ前に `echo **` で見る
- **`autocd` は、ディレクトリと同じ名前のコマンドが無いときだけ**: コマンドの探索が先で、見つからなかったときにディレクトリとして試す
- **`show-all-if-ambiguous` は候補が多いと長い一覧になる**: `ls /usr/share/<Tab>` のような場所では、既定と同じく `Display all 123 possibilities? (y or n)` と聞かれる
- **ロールバックの後の最初の `exit` で履歴が 1,000 行に減る**（[ロールバック](#ロールバック)のリード）
- **Homebrew の補完の行は `brew shellenv` の行より後ろ、fzf の行より前**
