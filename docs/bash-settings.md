# bash の履歴・補完・キー操作の設定手順（AlmaLinux 10）

## 実施手順

> [!IMPORTANT]
> - **自分のユーザーのシェルで実行する**。`sudo -i` した root のシェルでは行わない（root の `~/.bashrc` と `~/.inputrc` は対象外）
> - **手順 1 だけ `sudo` を使う**（bash-completion の RPM。Workstation で入れた PC には最初から入っている）
> - **手順 4 は、[Homebrew](homebrew.md) を入れたホストだけ**で行う。[fzf](fzf.md) を先に通したホストでは、fzf の行の前に差し込む
> - **手順 6 は、端末を開き直す操作**。手順 7 は開き直した端末で貼り、手順 8 はキーを押して確かめる

- 上から順にコードブロックを貼る。変数は無い
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 履歴を曖昧検索で探す Ctrl+R などは [fzf](fzf.md)。以後は[ロールバック](#ロールバック)（設定だけなので、更新の節は無い）

> [!WARNING]
> **x86_64 のコンテナでのみ検証した手順書**で、実機では本書の手順を通していない（[対象と検証環境](#対象と検証環境)）。GNOME 端末や WezTerm の画面での色と、Home / End / Ctrl+矢印のキーは確かめていない。

1. bash-completion が入っているか確かめ、無ければ入れる。

   ```bash
   if ! rpm -q bash-completion; then sudo dnf install -y bash-completion; fi
   ```

   - `bash-completion-2.11-…` と出れば入っている（Workstation で入れた PC は、グループ `Standard` の既定のパッケージとして最初から入っている）
   - `package bash-completion is not installed` のときは、続けて BaseOS から入る（依存の `pkgconf` 系 4 つも入る）

   <details>
   <summary>補足: bash-completion が無いとどうなるか</summary>

   - bash 自身の補完は、コマンド名・ファイル名・変数名だけ。`systemctl star<Tab>` や `git checko<Tab>` のような、コマンドごとのサブコマンドやオプションの補完は bash-completion（と、各パッケージが `/usr/share/bash-completion/completions/` に置く定義）が行う
   - AlmaLinux 10.2 の BaseOS の版は 2.11（2026-10-02）。コンテナの最小のイメージには入っていなかった
   - 入れると `/etc/profile.d/bash_completion.sh` が置かれ、対話のシェルを開くときに `/etc/profile`（ログインシェル）か `/etc/bashrc`（それ以外）から読まれる

   </details>

1. 今のシェルにも bash-completion を読み込み、読まれたことを確かめる。

   ```bash
   . /etc/profile.d/bash_completion.sh
   complete -p -D
   printf '%s\n' "${BASH_COMPLETION_VERSINFO[*]}"
   ```

   - `complete -F _completion_loader -D` と `2 11` が出る
   - 最初から入っていたホストでは、どちらも読み込む前から出る（2 回読んでも何も起きない）

   <details>
   <summary>補足: <code>. ~/.bashrc</code> では読まれない理由</summary>

   - `/etc/bashrc` は `/etc/profile.d/*.sh` を**ログインシェルでないとき**だけ読む（`if ! shopt -q login_shell`）。SSH でログインしたシェルで `. ~/.bashrc` を実行しても、`/etc/bashrc` 経由では `bash_completion.sh` に届かない
   - `bash_completion.sh` 自身は、対話の bash で、まだ読んでいないとき（`BASH_COMPLETION_VERSINFO` が空）だけ本体を読む。2 回目は何もしない
   - `complete -p -D` の `_completion_loader` は、コマンドの補完を最初の Tab のときに `/usr/share/bash-completion/completions/<コマンド>` から読む仕組み（遅延読み込み）。読む前の `complete -p git` は `bash: complete: git: no completion specification` になる

   </details>

1. `~/.bashrc` に、履歴の量と `shopt` の設定を足す。

   ```bash
   cat >> ~/.bashrc <<'EOF'
   HISTSIZE=100000
   HISTFILESIZE=100000
   HISTCONTROL=ignoreboth
   shopt -s autocd cdspell dirspell globstar
   EOF
   . ~/.bashrc
   printf '%s\n' "${HISTSIZE}" "${HISTFILESIZE}" "${HISTCONTROL}"
   shopt histappend autocd cdspell dirspell globstar
   ```

   - `100000` が 2 行、`ignoreboth`、5 つの `on` が出る
   - 自分用の bash の設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）を入れたホストでは、このブロックは貼らない。代わりに `. ~/.bashrc` と `shopt autocd` を実行する（その設定が同じ 4 行を読む）
   - **注意**: `globstar` は、この `~/.bashrc` を読む非対話のシェル（`ssh <ホスト> <コマンド>`）でも効く。そこで打つ `**` は再帰になる

   <details>
   <summary>補足: 既定の値と、足した設定の効き目</summary>

   AlmaLinux 10.2 の既定（コンテナで、SSH でログインした bash 5.2.26）:

   | 項目 | 既定 | 決めている場所 | 本書の値 |
   |---|---|---|---|
   | `HISTSIZE`（シェルが覚える行数） | `1000` | `/etc/profile` | `100000` |
   | `HISTFILESIZE`（`~/.bash_history` に残す行数） | `1000`（`HISTSIZE` と同じ値になる） | bash の既定 | `100000` |
   | `HISTCONTROL` | `ignoredups`（直前と同じ行を残さない） | `/etc/profile` | `ignoreboth`（空白で始めた行も残さない） |
   | `histappend`（閉じるときに上書きでなく追記） | on | `/etc/bashrc`（対話のシェルで `shopt -s histappend`） | 変えない（既に on） |
   | `autocd` | off | — | on（ディレクトリ名だけで `cd`。`cd -- <ディレクトリ>` と表示して移る） |
   | `cdspell` / `dirspell` | off | — | on（`cd /usr/shaer` を `/usr/share` に直す。`dirspell` は補完のときの直し） |
   | `globstar` | off | — | on（`**` がサブディレクトリまで再帰） |

   - `HISTSIZE` を変えずに `HISTFILESIZE` だけ変えても、覚える行数は 1000 のまま。両方を書く
   - `histappend` は EL の `/etc/bashrc` が対話のシェルに入れている。複数の端末を開いていても、後から閉じた端末が前の端末の履歴を消さない。本書では書き足さない（Git Bash など、既定で off のシェルの設定は [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash) にある）
   - **採らなかった設定**は[選択した方針](#選択した方針)（`HISTTIMEFORMAT`・`erasedups`・プロンプトごとの `history -a`）
   - `autocd` は `cd` の**コマンド**を呼ぶ。zoxide を `--cmd cd` で入れたホスト（[zoxide.md 手順 1](zoxide.md#実施手順) の `ZOXIDE_CMD=cd`）では zoxide の `cd` 関数が呼ばれ、`cdspell` の直しは効かない（コンテナで、`cd /usr/shaer` が `zoxide: no match found` になった）
   - `. ~/.bashrc` で読み直すと、starship を WezTerm のシェル統合より前に置いたホストでは並びが入れ替わる（[starship.md 手順 6](starship.md#実施手順)）。手順 6 で端末を開き直せば元に戻る

   </details>

1. Homebrew を入れたホストでは、`~/.bashrc` に Homebrew のコマンドの補完を読む 1 行を足す。

   ```bash
   LINE='if [ -d "${HOMEBREW_PREFIX-}/etc/bash_completion.d" ]; then for __f in "${HOMEBREW_PREFIX}"/etc/bash_completion.d/*; do if [ -r "$__f" ]; then . "$__f"; fi; done; unset __f; fi'
   if grep -q 'fzf --bash' ~/.bashrc; then
     awk -v line="${LINE}" '!done && /fzf --bash/ { print line; done = 1 } { print }' ~/.bashrc > ~/.bashrc.tmp && cat ~/.bashrc.tmp > ~/.bashrc && rm ~/.bashrc.tmp
   else
     printf '%s\n' "${LINE}" >> ~/.bashrc
   fi
   grep -n -e 'bash_completion.d' -e 'fzf --bash' -e 'brew shellenv' ~/.bashrc
   eval "${LINE}"
   complete -p brew
   ```

   - `grep` に、`brew shellenv` の行 → 足した `bash_completion.d` の行（→ fzf の行があればその後ろ）の順で出る
   - `-F _brew brew` を含む補完定義が出る（検証時は `complete -o bashdefault -o default -F _brew brew`）。入れてある Homebrew のコマンド（eza・bat・zoxide・fd・starship など）の補完も読まれる
   - 自分用の bash の設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）を入れたホストでは、このブロックは貼らない。代わりに `. ~/.bashrc` と `complete -p brew` を実行する（その設定が同じ読み込みを行う）
   - [fzf.md 手順 3](fzf.md#実施手順) の行があるときは、その前に差し込まれる。今のシェルでは `**<Tab>`（fzf）が bat などで効かなくなるが、手順 6 で開き直せば直る

   <details>
   <summary>補足: Homebrew の補完が自動では読まれない理由と、fzf の行より前に置く理由</summary>

   - Homebrew の formula は bash の補完を `/home/linuxbrew/.linuxbrew/etc/bash_completion.d/<コマンド>` に置く（コンテナでは `bat` / `brew` / `eza` / `fd` / `starship` / `zoxide` の 6 つ）。`share/bash-completion/completions/` は無い
   - bash-completion 2.11 の遅延読み込みが探すのは、`$BASH_COMPLETION_USER_DIR`（既定 `~/.local/share/bash-completion`）と `$XDG_DATA_DIRS`（既定 `/usr/local/share:/usr/share`）の下の `bash-completion/completions/` だけ。Homebrew 7.0.7 の `brew shellenv` は `XDG_DATA_DIRS` を変えないので、この行を足さないと `eza --<Tab>` は何も出ない（コンテナで確認）
   - 公式の [Shell Completion](https://docs.brew.sh/Shell-Completion) が案内する `for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*` の形を、`HOMEBREW_PREFIX` が無いホストでも止まらない 1 行にした（`brew shellenv` の行が `HOMEBREW_PREFIX` を入れるので、その行より後ろに置く）
   - 6 つの定義（`brew` の 4,041 行を含む）を毎回読んでも、対話のシェルの起動は 38 ミリ秒から 44 ミリ秒になっただけ（`time bash -ic true`）
   - fzf の `fzf --bash` は、`bat` や `vi` など決まったコマンドの補完を、すでにある定義を包む形で `**<Tab>` 対応に置き換える。この行が fzf の行より後ろにあると、`bat` の補完が bat 自身の定義に戻り、`bat **<Tab>` が fzf にならない（コンテナで確認。`bat --the<Tab>` は、どちらの並びでも `--theme` に補完された）
   - `awk` は、`fzf --bash` を含む最初の行の前に 1 行を入れる。`cat ~/.bashrc.tmp > ~/.bashrc` は、`~/.bashrc` のファイル自体（パーミッション）を変えないため（[starship.md 手順 5](starship.md#実施手順) と同じ）
   - `bat` の補完は bash-completion の `_init_completion` を使うので、bash-completion が無いホストでは `bat --<Tab>` でエラーになる。手順 1 を飛ばさない

   </details>

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

   <details>
   <summary>補足: <code>~/.inputrc</code> に書く理由と、各行の意味</summary>

   - readline は `~/.inputrc` があるとそれを読み、無いときだけ `/etc/inputrc` を読む。`$include` を書かずに `~/.inputrc` を置くと、`/etc/inputrc` の Home / End（`\e[1~` / `\e[4~`）、Delete（`\e[3~`）、Ctrl+←→（`\e[5C` / `\e[1;5C`）、PageUp / PageDown の履歴の検索（`\e[5~` / `\e[6~`）が消える（コンテナで、`bind -q beginning-of-line` から `"\e[1~"` が消え、`$include` を足すと戻った）
   - `~/.bashrc` に `bind` で書かない理由: `bind` は対話のシェル以外では `line editing not enabled` の警告になる。`~/.inputrc` は bash のほか、readline を使うコマンド（`python3`・`psql`・`gdb` など）にも効く。`INPUTRC` の環境変数も使わない（それらすべてに別のファイルを押し付けることになる）
   - `completion-ignore-case`: `cd /ET<Tab>` が `/etc/` に、`cd /usr/SH<Tab>` が `/usr/share/` になる（打った大文字も直る）
   - `show-all-if-ambiguous`: 候補が複数のとき、既定では 1 回目の Tab はベルだけで 2 回目で一覧が出る。1 回で出す
   - `colored-stats` / `colored-completion-prefix`: 一覧のディレクトリや実行ファイルを `LS_COLORS` の色で、打った部分を別の色で出す（コンテナでは `ls /usr/s<Tab>` の `s` が紫、残りが青の太字で出た）
   - `history-search-backward` は、カーソルより前の文字で始まる履歴を探す。`ec` と打って ↑ で `echo …` の行だけが出る。何も打っていなければ既定の ↑ と同じ。カーソルは打った文字の後ろに残る（行末へは End か Ctrl+E）。`/etc/inputrc` は同じ機能を PageUp / PageDown に付けている
   - `\e[A` は端末の通常のモード、`\eOA` はアプリケーションモード（`tput smkx` の後）の ↑。bash の既定は両方を `previous-history` にしているので、両方を置き換える
   - `bind -f` は今のシェルだけ。新しいシェルは起動のときに `~/.inputrc` を読む

   </details>

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

   - 手順 3 と同じ値、`complete -F _completion_loader -D`、`set … on` が 4 行、`"\eOA", "\e[5~", "\e[A"` が出る
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

- 足した行を消すだけでよい。bash-completion の RPM は、手順 1 で入れたホストだけ消す

> [!WARNING]
> **この節の手順 2 の後に閉じたシェルは、`~/.bash_history` を既定の 1,000 行に切り詰める**（コンテナで、2,000 行の履歴ファイルが `exit` の後に 1,000 行になった）。残したい履歴があれば、この節の手順 1 で控える。

1. 履歴のファイルを控える。

   ```bash
   cp -p ~/.bash_history ~/.bash_history.bak
   wc -l ~/.bash_history.bak
   ```

   - 行数が出る。要らなくなったら `~/.bash_history.bak` は手で消す

1. `~/.bashrc` から、手順 3・4 で足した行を消す。

   ```bash
   sed -i -e '/^HISTSIZE=100000$/d' -e '/^HISTFILESIZE=100000$/d' -e '/^HISTCONTROL=ignoreboth$/d' -e '/^shopt -s autocd cdspell dirspell globstar$/d' -e '/HOMEBREW_PREFIX.*bash_completion\.d/d' ~/.bashrc
   grep -n -e 'HIST' -e 'shopt' -e 'bash_completion.d' ~/.bashrc
   ```

   - `grep` が何も出さなければ消えている（手で変えた行は残るので、出たら見て直す）

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

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 の bash で、履歴を多く残し、Tab の補完を広く・楽にし、↑ で打ちかけの行から履歴を探せるようにする。ツールを足すのではなく、bash と readline の設定と、bash-completion の RPM だけで行う
- **進め方**: `~/.bashrc` に 4 行（Homebrew のホストは 5 行）、`~/.inputrc` を 1 つ。**読者が書き換える変数は無い**
- **状態**: **x86_64 のコンテナでのみ検証した（2026-10-02）**
  - 通したこと: SSH でログインした対話の bash に、この文書の bash のブロックをそのまま貼り、実施手順と[ロールバック](#ロールバック)を、ブラケットペーストの無しと有りで 1 回ずつ通した（[付録](#付録-コンテナでの検証記録2026-10-02)）
  - 確認したこと
    - 手順 1〜7 の出力、手順 8 のキー操作（tmux のペインにキーを送って画面を読んだ）、[ロールバック](#ロールバック)
    - `~/.inputrc` に `$include /etc/inputrc` が無いと `/etc/inputrc` の割り当てが消えること、`~/.bashrc` の行を消した後に閉じたシェルが履歴を 1,000 行に切り詰めること
    - [fzf.md](fzf.md) の行との並び（手順 4 の補足）
  - **確認していないこと**
    - 実機（aarch64 の Raspberry Pi 5、x86_64 の PC）、GNOME 端末・WezTerm の画面での色と Home / End / Ctrl+矢印
    - Workstation で入れた PC に bash-completion が最初から入っていること（comps の `Standard` グループの既定のパッケージであることを `dnf group info` で見ただけ）
    - 日本語入力との組み合わせ、`python3` など bash 以外の readline のコマンドでの `~/.inputrc`

| 項目 | 検証コンテナ |
|---|---|
| 実施日 | 2026-10-02 |
| OS | AlmaLinux 10.2 (Lavender Lion)（`quay.io/almalinuxorg/10-init`。パッケージは `x86_64_v2`） |
| コンテナ | クラウドのホストの Docker 29.6.2、`--privileged` と `--network host`。systemd を PID 1 にし、sshd と systemd-logind を動かした |
| bash | 5.2.26（BaseOS）。bash-completion は 2.11-16（BaseOS。最初は入っていない） |
| Homebrew | 7.0.7（`/home/linuxbrew/.linuxbrew`）。bat 0.26.1・eza 0.23.5・fd 10.5.0・fzf 0.74.4・starship 1.26.0・zoxide 0.10.0 を入れて補完を確かめた |
| 端末 | ホストの tmux 3.4 のペイン（160x45）から `docker exec -it` で `ssh -t` し、`TERM=xterm-256color` |

> [!NOTE]
> 出力例・ログの中の値は `<USER>` / `<HOSTNAME>` / `<PID>` のプレースホルダで書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| bash-completion | 未導入（`rpm -q bash-completion` が `not installed`） |
| `~/.bashrc` | `/etc/skel` のもの（`/etc/bashrc` を読み、`~/.bashrc.d/` があれば読む）に、[homebrew.md 手順 3](homebrew.md#実施手順) の `brew shellenv` の 1 行 |
| `~/.inputrc` | 無し（`/etc/inputrc` が読まれている） |
| 履歴 | `HISTSIZE=1000`・`HISTFILESIZE=1000`・`HISTCONTROL=ignoredups`、`histappend` は on |

### 選択した方針

- **bash-completion はシステムの RPM にした**: BaseOS の 2.11 で足りる。Homebrew にも `bash-completion@2`（2.16 系）があるが、RPM の各パッケージが置く `/usr/share/bash-completion/completions/` を読むのはシステムのものの方が素直で、`sudo` のシェルでも同じものが効く
- **Homebrew の補完は `~/.bashrc` の 1 行で全部読む**: 遅延読み込みの対象のディレクトリに無いため（手順 4 の補足）。`~/.local/share/bash-completion/completions/` にシンボリックリンクを置けば遅延読み込みにできるが、入れるたびに足す手間があるので採らない
- **`~/.inputrc` を使い、`~/.bashrc` の `bind` にはしない**（手順 5 の補足）
- **採らなかった設定**
  - `HISTTIMEFORMAT`（`history` に時刻を出す）: 履歴ファイルに `#<epoch>` の行が増える。bash 5.2 では、変数を外した後もその行はコマンドとして出なかった（コンテナで確認）が、本書は履歴の見え方を変えない範囲にとどめた。欲しければ `HISTTIMEFORMAT='%F %T '` を手順 3 の行に足せばよい
  - `HISTCONTROL=…:erasedups`（同じ行を全部消して 1 つにする）: 覚えている一覧の中だけを直し、ファイルの古い重複は残る。効き目が分かりにくいので入れない
  - `PROMPT_COMMAND` に `history -a`（コマンドごとにファイルへ書き、別の端末ですぐ使う）: AlmaLinux 10 の `PROMPT_COMMAND` は配列で、starship・WezTerm のシェル統合・zoxide が順番に意味を持って触っている（[starship.md 手順 3](starship.md#実施手順) の補足）。そこへ足す形は本書では扱わない
  - `set bell-style none`（ベルを消す）、`menu-complete`（Tab で候補を順に入れる）: 好みの幅が大きいので入れない
  - `shopt -s histappend`: `/etc/bashrc` が対話のシェルで入れている（手順 3 の補足）
- **atuin（履歴を SQLite に持ち、同期もする）は使わない**: 履歴の検索は [fzf](fzf.md) の Ctrl+R で足りる。[導入元一覧](tool-catalog.md#cli-定番の置き換え)の行のまま

### 完了時点の状態

実施手順の後（Homebrew のホスト）:

```
$ tail -n 5 ~/.bashrc
HISTSIZE=100000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth
shopt -s autocd cdspell dirspell globstar
if [ -d "${HOMEBREW_PREFIX-}/etc/bash_completion.d" ]; then for __f in "${HOMEBREW_PREFIX}"/etc/bash_completion.d/*; do if [ -r "$__f" ]; then . "$__f"; fi; done; unset __f; fi
$ bind -q history-search-backward
history-search-backward can be invoked via "\eOA", "\e[5~", "\e[A".
$ complete -p -D brew
complete -F _completion_loader -D
complete -o bashdefault -o default -F _brew brew
```

- `~/.inputrc` は手順 5 の 13 行（コメント 3 行を含む）
- [fzf.md 手順 3](fzf.md#実施手順) を通すと、`fzf --bash` の行が `bash_completion.d` の行の後ろに付く

### 注意点

- **`~/.inputrc` を作ったら `$include /etc/inputrc` を忘れない**: 無いと Home / End / Delete / Ctrl+矢印が効かなくなる（手順 5 の補足）
- **`globstar` は `rm` でも効く**: `rm **` はサブディレクトリの中まで消す。`**` を打つ前に `echo **` で見る
- **`autocd` は、ディレクトリと同じ名前のコマンドが無いときだけ**: コマンドの探索が先で、見つからなかったときにディレクトリとして試す
- **`show-all-if-ambiguous` は候補が多いと長い一覧になる**: `ls /usr/share/<Tab>` のような場所では、既定と同じく `Display all 123 possibilities? (y or n)` と聞かれる
- **ロールバックの後の最初の `exit` で履歴が 1,000 行に減る**（[ロールバック](#ロールバック)のリード）
- **Homebrew の補完の行は `brew shellenv` の行より後ろ、fzf の行より前**（手順 4 の補足）

### 参照

- [Bash Reference Manual — Bash Variables](https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html)（`HISTSIZE`・`HISTFILESIZE`・`HISTCONTROL`・`HISTTIMEFORMAT`）
- [Bash Reference Manual — The Shopt Builtin](https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html)（`autocd`・`cdspell`・`dirspell`・`globstar`・`histappend`）
- [Bash Reference Manual — Readline Init File](https://www.gnu.org/software/bash/manual/html_node/Readline-Init-File.html)（`$include`、`completion-ignore-case`、`show-all-if-ambiguous`、`colored-stats`、`colored-completion-prefix`、`history-search-backward`）
- [bash-completion](https://github.com/scop/bash-completion)（`_completion_loader`、`BASH_COMPLETION_USER_DIR`、`XDG_DATA_DIRS`）
- [Homebrew — Shell Completion](https://docs.brew.sh/Shell-Completion)（`etc/bash_completion.d` を読む形）
- [fzf](fzf.md) — Ctrl+R の履歴の検索と `**<Tab>`。Homebrew の補完の行との並び
- [Homebrew](homebrew.md) — `brew shellenv` の行（手順 3）

---

### 付録: コンテナでの検証記録（2026-10-02）

**環境**: [対象と検証環境](#対象と検証環境)の表のとおり。コンテナには NOPASSWD の sudo を持つ一般ユーザーを作り、root から `ssh -p 2222 <USER>@127.0.0.1` でログインした。

**検証の準備**（本書の手順には含めない）:

- このホストの外向きの HTTPS はプロキシを通るので、プロキシの CA を `/etc/pki/ca-trust/source/anchors/` に置き、`/etc/dnf/dnf.conf` の `proxy=` と、ログインシェルの `HTTPS_PROXY` などを足した
- AlmaLinux の `mirrorlist=` を止めて、コメントの `baseurl=https://repo.almalinux.org/...` を有効にした
- Homebrew は `NONINTERACTIVE=1` 付きの公式インストーラで入れ、`brew install fzf fd bat eza zoxide starship` で補完の対象のコマンドを入れた

**先に調べたこと**（文書の内容を決めるため）:

- `/etc/profile` が `HISTSIZE=1000` と `HISTCONTROL=ignoredups` を、`/etc/bashrc` が `shopt -s histappend` を入れている。`/etc/bashrc` は `/etc/profile.d/*.sh` をログインシェルでないときだけ読む
- `dnf group info standard` の既定のパッケージに `bash-completion` がある。`workstation-product-environment` の必須のグループに `Standard` がある
- `brew shellenv bash` の出力は `HOMEBREW_PREFIX` / `HOMEBREW_CELLAR` / `HOMEBREW_REPOSITORY` / `PATH` / `MANPATH` / `INFOPATH` だけで、`XDG_DATA_DIRS` は無い
- `/home/linuxbrew/.linuxbrew/etc/bash_completion.d/` に `bat` `brew` `eza` `fd` `starship` `zoxide`。`bat` だけが bash-completion の `_init_completion` を使う
- `HISTTIMEFORMAT` を入れたシェルを閉じると履歴ファイルに `#1790939222` の行が付き、変数の無いシェルで `history` を見ても、その行はコマンドとして出なかった
- 2,000 行の履歴ファイルを持つシェルを既定の `HISTFILESIZE`（1000）で閉じると 1,000 行に、`100000` にして閉じると 2,001 行になった

**流し方**:

- ホストの tmux のペインで `docker exec -it … ssh -t` したログインシェルに、この文書の bash のブロック（折り畳みの外のもの）を抜き出して、手順ごとに `tmux paste-buffer` で書き込んだ
- 1 回目はブラケットペースト無しで、2 回目は `paste-buffer -p`（ブラケットペースト有り。貼った後に Enter を送った）で、実施手順から[ロールバック](#ロールバック)まで通した。2 回の間に bash-completion を消し、`~/.bashrc` と `~/.inputrc` を実施前に戻した
- 手順 8 のキーは `tmux send-keys` で送り、`capture-pane -e` で色の制御文字ごと読んだ

| 手順 | 結果（2 回とも同じ） |
|---|---|
| 1 | `package bash-completion is not installed` に続けて dnf が `bash-completion-1:2.11-16.el10` と `pkgconf` 系 4 つを入れ、`Complete!` |
| 2 | `complete -F _completion_loader -D`、`2 11` |
| 3 | `100000` `100000` `ignoreboth`、`histappend` `autocd` `cdspell` `dirspell` `globstar` が `on` |
| 4 | `grep` は `26:eval "$(…brew shellenv bash)"` と `31:if [ -d "${HOMEBREW_PREFIX-}/etc/bash_completion.d" ]…`（fzf の行はまだ無い）。`complete -o bashdefault -o default -F _brew brew` |
| 5 | `set colored-completion-prefix on` / `set colored-stats on` / `set completion-ignore-case on` / `set show-all-if-ambiguous on`、`history-search-backward can be invoked via "\eOA", "\e[5~", "\e[A".`、`beginning-of-line can be invoked via "\C-a", "\eOH", "\e[1~", "\e[H".` |
| 6・7 | `exit` してログインし直した新しいシェルで、手順 3・5 と同じ値と `complete -F _completion_loader -D`。`complete -p brew` も同じ |
| 8 | `systemctl star<Tab>` → `systemctl start `。`ls /usr/s<Tab>` → 1 回で `sbin/  share/ src/`（`s` が紫の太字、残りが青）。`cd /usr/SH<Tab>` → `cd /usr/share/`。`printf` + ↑ → 手順 7 の `printf` の行。`/usr/share` + Enter → `cd -- /usr/share` と出てプロンプトが `share` に。`cd /usr/shaer` → `/usr/share` と出て移った。`ls /usr/share/doc/bash-completion/**/*.md` → `CONTRIBUTING.md` と `README.md`。`eza --gi<Tab>` → `--git  --git-ignore  --git-repos  --git-repos-no-status` の一覧の後に `eza --git` |
| ロールバック 1〜3 | 控えの行数（1 回目 56、2 回目 120）。`grep` は何も出さず、`rm -f ~/.inputrc` は何も出さない |
| ロールバック 4 | `Removing: bash-completion`、`Removing unused dependencies:` に `pkgconf` 系 4 つ、`Freed space: 1.2 M`、`Is this ok [y/N]:` に `y` で `Complete!` |
| ロールバック 5 | 新しいシェルで `HISTSIZE` / `HISTFILESIZE` が `1000`、`HISTCONTROL=ignoredups`、`autocd` `globstar` が `off`、`history-search-backward` は `"\e[5~"` だけ、`~/.inputrc` は無く、`~/.bashrc` の末尾は `brew shellenv` の行 |

#### 未確認事項

- 実機（aarch64 の Raspberry Pi 5、x86_64 の PC）での本実行
- GNOME 端末・WezTerm での色、Home / End / Ctrl+矢印、`\eOA`（アプリケーションモード）の ↑
- Workstation で入れた PC に bash-completion が最初から入っていること（メタデータのみ）
- `python3` など bash 以外の readline のコマンドでの `~/.inputrc`
- 日本語入力との組み合わせ
