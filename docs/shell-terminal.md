# シェルと端末のセットアップ（AlmaLinux 10・Windows 11）

- 自分用の共通の bash 設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）と、シェルのツール（starship・zoxide・fzf・eza・bat・tmux）、端末のフォント（HackGen Console NF）、端末（WezTerm nightly と自分用の設定 [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)）を入れる。Windows 11 では Git Bash を主のシェルにし、Windows Terminal と PowerShell 7 のプロファイルも整える
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shell-terminal.md)・[参考資料](reference/shell-terminal.md)・[注意点](extra/shell-terminal.md)。ロールバックは、ほかの道具と一緒に、2 冊のロールバック（[AlmaLinux 10](extra/almalinux-setup.md#ロールバック)・[Windows 11](extra/windows-setup.md#ロールバック)）で行う。Windows Terminal・PowerShell 7 と 5.1 のプロファイル・任意の項の設定は、この文書のそれぞれの項の「元に戻すときは」で戻す

> [!IMPORTANT]
> - AlmaLinux 10 の項は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)と同じく、**GNOME にログインした、インストール時の管理者ユーザー（`wheel`）の bash で行う**。`sudo -i`・`su -` のシェルでは行わない
> - AlmaLinux 10 の項は、パスワードを聞かない `sudo` を前提に書いてある。各項のリードの前提に無くても、その項を行うユーザーで[ログインと sudo](almalinux-setup.md#ログインと-sudo)を先に通す
> - Windows 11 の項は、[Windows 11 のセットアップ](windows-setup.md)と同じく、**この PC のデスクトップで、Administrators のユーザーが行う**。PowerShell のブロックは **Windows PowerShell 5.1** に貼る。管理者・通常の窓と Git Bash は、各項のリードに従う
> - Windows 11 で[貼り付けの設定](windows-setup.md#貼り付けの設定)より前は **Ctrl+V で貼る**。設定後は GitHub のコピーボタンでコピーし、右クリックで貼れる

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- ほかの手順書の項を前提にする項がある（各項のリードの前提からリンクで開く）。AlmaLinux 10 は[Homebrew](almalinux-setup.md#homebrew)（オフラインのホストは[Homebrew のオフライン導入](almalinux-setup.md#homebrew-のオフライン導入)）、Windows 11 は[Microsoft Store の更新](windows-setup.md#microsoft-store-の更新)・[アプリを入れる](windows-setup.md#アプリを入れる)（scoop・PowerShell 7）・[Git for Windows](windows-setup.md#git-for-windows)
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- Windows 11 で GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- 入れたものを上げるとき
  - 共通の bash 設定は、[共通の bash 設定を更新する](#共通の-bash-設定を更新する)・[Windows 11 で共通の bash 設定を更新する](#windows-11-で共通の-bash-設定を更新する)で上げる。AlmaLinux 10 で Homebrew・Flatpak とまとめて上げるなら、[AlmaLinux 10 のセットアップの「共通の bash 設定・Homebrew・Flatpak を上げる」](almalinux-setup.md#共通の-bash-設定homebrewflatpak-を上げる)
  - AlmaLinux 10 のシェルのツールと HackGen Console NF は、同じ「共通の bash 設定・Homebrew・Flatpak を上げる」の手順 3（Homebrew）で上がる。Windows 11 のシェルのツールは[Windows 11 のセットアップの「scoop・winget・WSL を上げる」](windows-setup.md#scoopwingetwsl-を上げる)、HackGen Console NF は[HackGen Console NF を上げる](#hackgen-console-nf-を上げる)で上げる
  - WezTerm は、AlmaLinux 10 は OS の更新（[AlmaLinux 10 のセットアップの「更新」](almalinux-setup.md#更新)）で上がる。Windows 11 は[Windows 11 のセットアップの「Git for Windows・Firefox・WezTerm を上げる」](windows-setup.md#git-for-windowsfirefoxwezterm-を上げる)で上げる。自分用の WezTerm の設定は、[WezTerm の設定を更新する](#wezterm-の設定を更新する)・[Windows 11 で WezTerm の設定を更新する](#windows-11-で-wezterm-の設定を更新する)で上げる
- Windows 11 の PowerShell 7 のプロファイルの行の印 `# windows-setup.md` と、Windows Terminal の設定の控え `settings.json.windows-setup.bak` は、項がこの文書へ移る前の名前のまま（すでに通した PC の戻す手順と合わせるため）

## AlmaLinux 10 で使う

- 共通の bash 設定・シェルのツール・HackGen Console NF・WezTerm

### 共通の bash 設定

- 自分のユーザーに共通の bash 設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）を入れ、bash-completion と `~/.inputrc` で補完と履歴の検索を整える
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）

1. 共通の bash 設定を入れる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git clone https://github.com/ryo-aoki-pc/bash.git ~/.config/bash &&
     bash ~/.config/bash/install.sh
   ```

   - `~/.bashrc: 設定済み（元の内容: ~/.bashrc.before-bash）` と `完了: 端末を開き直す。…` が出ればよい
   - clone 済みで `fatal: destination path … already exists` と出たら、`git -C ~/.config/bash pull --ff-only` と `bash ~/.config/bash/install.sh` を貼る

1. 共通の bash 設定を今の端末に読み込み、履歴と shopt の値を確かめる。

   ```bash
   . ~/.bashrc
   printf '\n\033[7m 確認 \033[0m\n'
   echo "${__bash_config_loaded-読まれていない}"
   printf '%s\n' "$HISTSIZE" "$HISTFILESIZE" "$HISTCONTROL"
   shopt histappend autocd cdspell dirspell globstar
   ```

   - `1`、`100000`・`100000`・`ignoreboth`、5 つの `on` が出ればよい

1. bash-completion が入っているか確かめ、無ければ入れる。

   ```bash
   if ! rpm -q bash-completion; then sudo dnf install -y bash-completion; fi
   ```

   - `bash-completion-2.11-…` と出れば入っている
   - `package bash-completion is not installed` のときは、続けて BaseOS から入る

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
     printf '\n\033[7m 確認 \033[0m\n'
     bind -v | grep -E 'completion-ignore-case|show-all-if-ambiguous|colored-stats|colored-completion-prefix'
     bind -q history-search-backward
     bind -q beginning-of-line
   fi
   ```

   - `set … on` が 4 行出る。`history-search-backward` は `\eOA`・`\e[5~`・`\e[A`、`beginning-of-line` は `\C-a`・`\eOH`・`\e[1~`・`\e[H` の割り当てが出る
   - `beginning-of-line` に `"\e[1~"` が無ければ、`$include /etc/inputrc` の行が読まれていない
   - `中断:` が出たら、既存の `~/.inputrc` の先頭に `$include /etc/inputrc` が無ければ足し、`set` と矢印の各 4 行を足して `bind -f ~/.inputrc` を貼る

#### 共通の bash 設定を手動で移行する

通常は[共通の bash 設定](#共通の-bash-設定)の `install.sh` を使う。この項は、`install.sh` を使わずに、手で確認しながら移行するときだけ行う。

- 前提: 無し（Git は AlmaLinux 10 Workstation に初めから入っている）
- 実行場所: 自分のユーザーの端末（bash）。Windows 11 も、Git Bash でこの項の手順をすべて行える。WSL は Linux 側で別に行う
- この項の手順 3 の控えと、手順 4 の既存の行の確認を省かない

[背景説明](https://github.com/ryo-aoki-pc/bash/blob/main/docs/reference/install.md)・[検証記録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md)

1. この設定が既に入っているか確かめる。

   ```bash
   ls -ld ~/.config/bash
   grep -n 'config/bash/bashrc' ~/.bashrc
   ```

   - `ls` が `No such file or directory` で、`grep` が何も出さなければ、まだ入っていない。手順 2 へ進む
   - `ls` がディレクトリ、`grep` が `if [ -r ~/.config/bash/bashrc ]; then . ~/.config/bash/bashrc; fi` を出せば導入済み
   - 導入済みなら手順 2〜10 を飛ばし、[更新](#共通の-bash-設定を更新する)を行う
   - Git Bash で `~/.bashrc` がまだ無ければ、`grep` は `No such file or directory` と出す（手順 3 で作られる）

1. この設定を `~/.config/bash` に clone する。

   ```bash
   git clone https://github.com/ryo-aoki-pc/bash.git ~/.config/bash
   ```

   - `Cloning into '/home/<USER>/.config/bash'...` と出る（Git Bash では `Cloning into 'C:/Users/<WIN_USER>/.config/bash'...`）
   - 問いは出ない（公開のリポジトリなので、認証は要らない）
   - インターネットに出られないホストでは、[SSH の SOCKS トンネル](almalinux-setup.md#ssh-の-socks-トンネル)を張ったシェルで貼る
   - 止まったときは `~/.config/bash` は残らないので、そのまま貼り直せる

1. `~/.bashrc` を控えてから、元の手順書が書いた行を消す。

   ```bash
   if [ ! -r ~/.config/bash/migrate/remove-old-lines.awk ]; then echo '中断: 手順 2 の clone ができていない' >&2
   elif [ -e ~/.bashrc.before-bash ]; then echo '中断: ~/.bashrc.before-bash が既にある' >&2
   else
     touch ~/.bashrc &&
       cp -p ~/.bashrc ~/.bashrc.before-bash &&
       awk -f ~/.config/bash/migrate/remove-old-lines.awk ~/.config/bash/migrate/old-lines.txt ~/.config/bash/migrate/old-y.txt ~/.bashrc.before-bash > ~/.bashrc &&
       bash -n ~/.bashrc && echo 'bash -n: OK'
   fi
   ```

   - `bash -n: OK` と出ればよい
   - `中断:` と出たら、何も書き換えていない。`~/.bashrc.before-bash` が前の実行の控えなら、手順 4 から続ける
   - `bash -n` が `syntax error` を出したら、`cp -p ~/.bashrc.before-bash ~/.bashrc` で戻し、手順 4 の `grep` の行をエディタで消す形に切り替える
   - **行全体が[移行で消す行](https://github.com/ryo-aoki-pc/bash/blob/main/docs/reference/readme.md#移行で消す行)と同じ行だけを消す**

1. 手順 3 で消した行と、残った関係の行を見る。

   ```bash
   git --no-pager diff --no-index ~/.bashrc.before-bash ~/.bashrc
   grep -n -i -E 'brew|zoxide|starship|yazi|eza|gdu-go|MANPAGER|nvim|DOCKER_HOST|wezterm|HIST|shopt|bash_completion|fzf|FZF_' ~/.bashrc
   ```

   - `git diff` の `-` で始まる行が、手順 3 で消した行
   - `grep` が何も出さなければ、手順 6・7 は飛ばす
   - `grep` が行を出したら、手順 6 でエディタで見る（行の番号が左に出る）

1. `~/.bashrc` の末尾に、この設定を読む 1 行を足す。

   ```bash
   if ! grep -qxF 'if [ -r ~/.config/bash/bashrc ]; then . ~/.config/bash/bashrc; fi' ~/.bashrc; then
     [ -z "$(tail -c 1 ~/.bashrc)" ] || echo >> ~/.bashrc
     echo 'if [ -r ~/.config/bash/bashrc ]; then . ~/.config/bash/bashrc; fi' >> ~/.bashrc
   fi
   tail -n 1 ~/.bashrc
   bash -n ~/.bashrc && echo 'bash -n: OK'
   ```

   - `if [ -r ~/.config/bash/bashrc ]; then . ~/.config/bash/bashrc; fi` と `bash -n: OK` が出ればよい
   - 既にその 1 行があれば、足さない（2 度貼っても 1 行のまま）
   - このホストだけの設定を足すときは、この 1 行より後ろに書く

1. 手順 4 で行が出たときだけ、`~/.bashrc` をエディタで開き、この設定と重なる行を消して、残す行を末尾の 1 行より後ろへ移す。

   - [共通設定が読むもの](https://github.com/ryo-aoki-pc/bash/blob/main/docs/reference/readme.md#読むもの)と同じ処理の行を消す
   - `if … fi` は `fi` まで、`y()` は `function y() {` から `}` まで消す
   - この設定と違う形で使いたい行（`--cmd cd` の zoxide、手で直した `alias ll` など）は、消さずに、手順 5 で足した末尾の 1 行より後ろへ移す
   - zoxide の行を残すときは、`--hook none` を足す（例: `eval "$(zoxide init bash --cmd cd --hook none)"`）
   - Homebrew のコマンドを使う行も、手順 5 の 1 行より後ろへ移す（Homebrew の PATH は、その 1 行で足される）
   - WSL の WezTerm の行は残す。starship を使うなら手順 5 の 1 行より後ろへ移す（[読む順番](https://github.com/ryo-aoki-pc/bash/blob/main/docs/reference/readme.md#読む順番)）
   - トークンなど、ホストだけの行は残す（前でも後ろでもよい）
   - **次の手順は、エディタを閉じてから貼る**

1. 手順 6 でエディタで直したときだけ、構文と並びを確かめる。

   ```bash
   bash -n ~/.bashrc && echo 'bash -n: OK'
   grep -n -i -E 'config/bash/bashrc|brew|zoxide|starship|yazi|eza|gdu-go|MANPAGER|nvim|DOCKER_HOST|wezterm' ~/.bashrc
   ```

   - `bash -n: OK` と出ればよい。`syntax error` と出たら、手順 6 に戻って直す
   - 手順 6 で残した行の番号が、`config/bash/bashrc` の行（手順 5 の 1 行）の番号より大きければよい

1. ログインシェルの設定ファイルが無いときだけ（新しい Git Bash など）、`~/.bashrc` を読む `~/.bash_profile` を作る。

   ```bash
   if [ -e ~/.bash_profile ] || [ -e ~/.bash_login ] || [ -e ~/.profile ]; then
     grep -n 'bashrc' ~/.bash_profile ~/.bash_login ~/.profile 2>/dev/null
   else
     printf '%s\n' '# ログインシェルでも ~/.bashrc を読む' 'if [ -f ~/.bashrc ]; then . ~/.bashrc; fi' > ~/.bash_profile
     cat ~/.bash_profile
   fi
   ```

   - AlmaLinux 10 では既存の `~/.bash_profile` の `if [ -f ~/.bashrc ]; then` と `. ~/.bashrc` の 2 行が出る。ファイルは作らない
   - Git for Windows が作った `~/.bash_profile` のある Git Bash では、`/c/Users/<WIN_USER>/.bash_profile:3:test -f ~/.bashrc && . ~/.bashrc` の 1 行が出る（何も作らない）
   - ログインシェルの設定ファイルが 1 つも無いホスト（新しい Git Bash）では、作った 2 行が出る
   - 既にあるファイルが何も出さなければ、そのファイルは `~/.bashrc` を読んでいない。エディタで `if [ -f ~/.bashrc ]; then . ~/.bashrc; fi` を足す

1. 開いている端末をすべて閉じて、開き直す。

   - WezTerm などの端末アプリは、ウィンドウをすべて閉じて起動し直す。ssh で入っているなら、ログアウトして入り直す
   - 開いたままのシェルには効かない（手順 3 で消した行の関数やフックも、そのシェルには残っている）
   - **次の手順は、開き直した端末で貼る**

1. 開き直した端末で、この設定が読まれたか確かめる。

   ```bash
   echo "${__bash_config_loaded-読まれていない}"
   alias | grep -E "^alias (ll|la|lt|vi|gdu)="
   type -t y z
   echo "EDITOR=${EDITOR-} DOCKER_HOST=${DOCKER_HOST-}"
   echo "HISTSIZE=${HISTSIZE} $(shopt -p autocd globstar | tr '\n' ' ')"
   bind -X
   complete -p brew bat 2>/dev/null
   bash -c '. ~/.bashrc' 2>&1 | wc -c
   ```

   - 1 行目が `1` なら、対話のシェルでこの設定が最後まで読まれている
   - `HISTSIZE=100000 shopt -s autocd shopt -s globstar` は、どのホストでも出る（履歴と `shopt`）
   - fzf があれば `bind -X` に Ctrl+R の `__fzf_history__` と Ctrl+T の `fzf-file-widget` が出る。Git Bash 5.3 ではコロン無しでよい
   - WezTerm の統合を読む場合はマウス報告よけの行も出る
   - Homebrew の bat があれば `complete -p` に `complete -F _fzf_path_completion bat`（fzf 無しなら `_bat`）と `brew` の行が出る
   - 2〜4 行目は導入済みのツールだけ出る。eza は `ll`・`la`・`lt`、yazi は `function`（`y`）、zoxide は `function`（`z`）
   - Git Bash では eza 無しでも `alias ll='ls -l'` が出てよい。`alias gdu` は出ない
   - AlmaLinux 10 でも、eza が無いと `alias ll='ls -l --color=auto'` が出る（coreutils-common の `/etc/profile.d/colorls.sh` のもので、この設定のものではない）
   - 最後が `0` なら、非対話のシェル（`ssh <HOST> <コマンド>`・scp・rsync）で何も出力しない
   - 1 行目が `読まれていない` なら、手順 5・8 を見直す

#### 共通の bash 設定を root に入れる

root のシェルにも、共通の bash 設定を入れる。一般ユーザーを信用できる自分専用のホストだけで行う。root が一般ユーザーの書き換えられる Homebrew のコマンド・補完を実行し、Homebrew が PATH の先頭になる。

- 前提: [共通の bash 設定](#共通の-bash-設定)を通してある（一般ユーザーの共通 bash 設定を先に入れる）
- 実行場所: この項の手順 1 は自分のユーザーの端末（bash）。手順 2 からは、その端末から `sudo -i` で入った root のシェル（手順 3 で入り直す）
- `sudo -i` は `ALL_PROXY` を渡さない

1. 自分のユーザーのシェルから root に入る。

   ```bash
   sudo -i
   ```

   - **次の手順は、root のシェルで貼る**

1. root 自身の clone を作り、読み込み口を設定する。

   ```bash
   git clone https://github.com/ryo-aoki-pc/bash.git ~/.config/bash &&
     bash ~/.config/bash/install.sh
   ```

   - `~` は `/root`。clone 済みなら更新し、`bash ~/.config/bash/install.sh` を実行する
   - 控えは `/root/.bashrc.before-bash`。既知の Homebrew・DOCKER_HOST の追記も移行する
   - 控えが既にある状態で変更が必要なら中断する。手動で確認する場合は[共通 bash の手動移行](#共通の-bash-設定を手動で移行する)の手順をすべて root のシェルで行う
   - 独自設定は共通設定の読み込み行より後ろに置く。構文エラーなら変更せず中断する

1. `exit` で抜け、自分のユーザーから `sudo -i` で入り直す。

   - **次の手順は、入り直した root のシェルで貼る**

1. 読み込みと非対話時の無出力を確かめる。

   ```bash
   echo "${__bash_config_loaded-読まれていない}"
   echo "DOCKER_HOST=${DOCKER_HOST-}"
   bash -c '. ~/.bashrc' 2>&1 | wc -c
   ```

   - 最初が `1`、最後が `0` ならよい
   - システムの `podman.socket` があれば `DOCKER_HOST=unix:///run/podman/podman.sock`、無ければ空
   - 確認後は `exit` で抜ける。戻すときは[共通 bash のロールバック](https://github.com/ryo-aoki-pc/bash/blob/main/docs/extra/quick-start.md)を root のシェルで行う

#### 共通の bash 設定を更新する

共通の bash 設定のリポジトリを pull で上げる。更新後は端末を開き直す。

- 前提: [共通の bash 設定](#共通の-bash-設定)か[共通の bash 設定を手動で移行する](#共通の-bash-設定を手動で移行する)を通してある
- 実行場所: 自分のユーザーの端末（bash。Windows 11 は Git Bash）。この項の手順 2 は、`sudo -i` で入った root のシェル

1. origin を HTTPS にそろえて、設定のリポジトリを pull する。

   ```bash
   git -C ~/.config/bash remote set-url origin https://github.com/ryo-aoki-pc/bash.git
   git -C ~/.config/bash pull --ff-only
   git -C ~/.config/bash log -1 --oneline
   ```

   - 新しいコミットが無ければ `Already up to date.` と出て、最後にいちばん新しいコミットが 1 行出る
   - `set-url` は、HTTPS で clone したホストでは何も変えない。SSH で clone したホストを HTTPS にそろえる
   - インターネットに出られないホストは、[SSH の SOCKS トンネル](almalinux-setup.md#ssh-の-socks-トンネル)を張ったシェルで貼る
   - 手元で変えたファイルがあって pull が止まったら、`git -C ~/.config/bash status` で見る
   - 開いている端末には効かない。端末を開き直す

1. root のシェルにも入れたときだけ、`sudo -i` の root のシェルで、この項の手順 1 を貼る。

   - `/root/.config/bash` が新しくなる。出力は、この項の手順 1 と同じ
   - 開いている root のシェルには効かない。`exit` で抜けて入り直す

---

### シェルのツール

- starship・zoxide・fzf・eza・bat・tmux を Homebrew で入れ、共通の bash 設定が読み込んだことを確かめる
- 前提: [共通の bash 設定](#共通の-bash-設定)と[Homebrew](almalinux-setup.md#homebrew)の手順 1〜3 を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）。この項の手順 2 で端末を開き直し、手順 3 からは開き直した端末で貼る

1. brew で starship・zoxide・fzf・eza・bat・tmux を入れる。

   ```bash
   brew install starship zoxide fzf eza bat tmux
   ```

   - 入れるものの一覧の後に `Do you want to proceed with the installation? [y/n]` と聞かれる。`y`（Enter は要らない）
   - `Warning: Landlock ABI 10 or later is required to deny all network access; found ABI 6.` の行は、気にしなくてよい
   - 要らないツールは、名前を外してから貼る
   - **次の手順は、`y` と答えて、プロンプトに戻ってから行う**（続けて貼ると、後ろの行の文字が答えとして読まれる）

1. 開いている端末を閉じて、開き直す。

   - Ctrl+Alt+T（[GNOME の表示と入力](almalinux-setup.md#gnome-の表示と入力)の手順 13）でも開ける
   - 開き直した端末から、プロンプトが starship に変わり、zoxide・fzf・eza のエイリアス・bat の `MANPAGER` も効く
   - 今の端末で `. ~/.bashrc` を読み直さず、端末を開き直す
   - **次の手順は、開き直した端末で貼る**

1. bash の履歴・補完・キー操作の設定が効いていることを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%s\n' "${HISTSIZE}" "${HISTFILESIZE}" "${HISTCONTROL}"
   shopt histappend autocd cdspell dirspell globstar
   complete -p -D
   complete -p brew
   bind -v | grep -E 'completion-ignore-case|show-all-if-ambiguous|colored-stats|colored-completion-prefix'
   bind -q history-search-backward
   ```

   - `100000`・`100000`・`ignoreboth`、5 つの `on` が出る
   - `complete -F _completion_loader -D`（Workstation では `complete -F _python_argcomplete_global -D` のこともある）と、`-F _brew brew` を含む行が出る
   - `set … on` が 4 行と、`history-search-backward` の `\eOA`・`\e[5~`・`\e[A` の割り当てが出る

1. starship が入り、プロンプトの文字列が作られるか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   grep -n -e 'starship init' -e 'WEZTERM_SHELL_INTEGRATION' -e 'zoxide init' ~/.config/bash/bashrc
   starship --version
   command -v starship
   starship module directory
   starship explain
   ```

   - 最初の行で、starship → WezTerm → zoxide の順に出る
   - `starship 1.26.0` のような版と、`/home/linuxbrew/.linuxbrew/bin/starship` が出る

1. fzf が入り、キー操作と補完が組み込まれたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   fzf --version
   command -v fzf
   bind -X
   bind -s | grep -F '"\ec"'
   complete -p cd vi ssh
   ```

   - `0.74.4 (Homebrew)` のような版と `/home/linuxbrew/.linuxbrew/bin/fzf` が出る
   - Ctrl+R・Ctrl+T の割り当て（`"\C-r": "__fzf_history__"`・`"\C-t": "fzf-file-widget"`）と、Alt+C のマクロ（`` "\ec": " \C-b\C-k \C-u`__fzf_cd__`… ``）が出る
   - `cd`・`vi`・`ssh` の補完の定義（`_fzf_dir_completion`・`_fzf_path_completion`・`_fzf_complete_ssh`）が出る

1. eza の版と Git の列、`ll`・`la`・`lt` を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   eza --version
   command -v eza
   eza -l --git --header ~/.config/bash
   alias ll la lt
   ```

   - `eza --version` は `v0.23.5 [+git]` のような行を含む
   - `Permissions Size User Date Modified Git Name` の見出しの一覧が出る
   - `ll` は `eza -l --git --group-directories-first`、`la` は `-la`、`lt` は `eza --tree --level=2`

1. bat の版と、色と行番号、man のページャを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   bat --version
   command -v bat
   bat --color=always --style=numbers /etc/os-release | head -5
   printf '%s\n' "$MANPAGER"
   ```

   - `bat 0.26.1` のような版と、`/home/linuxbrew/.linuxbrew/bin/bat` が出る
   - 行番号付きで `NAME="AlmaLinux"` から 5 行が色付きで出る
   - 最後に `bat -plman` が出ればよい

1. tmux が入ったことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   tmux -V
   command -v tmux
   rpm -q tmux
   ```

   - `tmux 3.7c` のような版と `/home/linuxbrew/.linuxbrew/bin/tmux` が出る
   - 最後の行は `パッケージ tmux はインストールされていません`（英語の環境では `package tmux is not installed`）でよい
   - **BaseOS の tmux（`tmux-3.3a-…`）が出て、そちらで始めたセッションが動いているなら**、そのセッションには `/usr/bin/tmux attach` で入る

1. zoxide の `z` と `zi` を確かめ、記録を試すディレクトリへ移る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   type -t z zi
   zoxide --version
   command -v zoxide
   cd /usr/share
   ```

   - `function` が 2 行と、`zoxide 0.10.0` のような版、`/home/linuxbrew/.linuxbrew/bin/zoxide` が出る
   - **注意**: 対話のシェル（端末に貼る）で行う。スクリプトの中では記録されない
   - **次の手順は、プロンプトが戻ってから貼る**。戻る前は `/usr/share` が zoxide に記録されない

1. zoxide のデータベースに記録されたか確かめ、ホームに戻る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   zoxide query --list
   cd ~
   ```

   - `/usr/share` が出れば動いている

#### キー操作を試す

- 共通の bash 設定とシェルのツールのキー操作（補完・履歴の検索・fzf のキー）を、端末で押して試す
- 前提: [シェルのツール](#シェルのツール)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。[シェルのツール](#シェルのツール)でツールを入れた後に開いた端末）

1. キーを押して、補完と履歴の検索を確かめる。

   - `systemctl star` と打って Tab: `systemctl start ` になる（bash-completion）
   - `ls /usr/s` → Tab: 色付きの `sbin/ share/ src/` が 1 回で出る
   - `cd /usr/SH` と打って Tab: `cd /usr/share/` になる（`completion-ignore-case`）
   - `printf` と打って ↑: `printf` で始まる履歴の行が、新しい順に出る（`history-search-backward`。カーソルは `printf` の後ろに残る）。Ctrl+C で捨てる
     - [シェルのツール](#シェルのツール)の手順 7 を貼った端末なら、1 回目は「確認」の見出しの `printf '\n\033[7m 確認 \033[0m\n'`、もう 1 回 ↑ で、その手順の `printf '%s\n' "$MANPAGER"`
   - `/usr/share` と打って Enter: `cd -- /usr/share` と出て移る（`autocd`）。`cd /usr/shaer` と打って Enter: `/usr/share` と出て移る（`cdspell`）。`cd` で戻る
   - `ls /usr/share/doc/bash-completion/**/*.md` と打って Enter: `CONTRIBUTING.md` と `README.md` が出る（`globstar`。効いていないと、`そのようなファイルやディレクトリはありません` になる）
   - `eza --gi` と打って Tab: `--git  --git-ignore  --git-repos  --git-repos-no-status` の一覧が出て、`eza --git` まで入る（Homebrew のコマンドの補完）

1. Ctrl+R を押し、履歴から[シェルのツール](#シェルのツール)の手順 5 の `fzf --version` を選んで実行する。

   - 画面の下から fzf の一覧が開き、最下行の `>` の右に打った文字で絞り込める。`fzf --v` と打ち、上下キーで `fzf --version` の行を選ぶ
   - Enter でその行がプロンプトに入る（**実行はされない**）。もう一度 Enter で実行する
   - Esc か Ctrl+C で、何も選ばずに閉じる
   - 履歴に `fzf --version` が無ければ、Esc で閉じ、`fzf --version` を打って Enter で実行してから、この手順をやり直す

1. `cat ` と打ってから Ctrl+T を押し、ファイルを選ぶ。

   - ホームのファイル一覧で `.bashrc` と打つと先頭になり、Enter でカーソル位置に入る。`bashrc` だけでは `.config/bash/bashrc` が先頭になる
   - 右側に、選んでいるファイルの中身が bat の行番号と色付きで出る
   - そのまま Enter で `cat .bashrc` が動く

1. `ls /usr/share/**` と打って Tab を押し、候補から選ぶ。

   - `**` → Tab: `/usr/share/` のパス一覧が開く。`doc/bash` → Enter: `ls /usr/share/doc/bash/` が入る。再度 Enter で実行する

1. Alt+C を押してディレクトリを選んで移り、`cd -` で戻る。

   - 今のディレクトリの下のディレクトリの一覧が開く。選んで Enter で、`builtin cd -- <ディレクトリ>` と表示して移る
   - 端末が Alt を ESC の前置きとして送る設定のときに届く（届かなければ、`ESC` を押してから `c`）
   - `cd -` で元のディレクトリに戻る

#### starship のプリセットを当てる

- 公式が配っている設定一式を `~/.config/starship.toml` に書き出す
- 前提: [シェルのツール](#シェルのツール)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。[シェルのツール](#シェルのツール)でツールを入れた後に開いた、starship を読み込んだ端末）
- **この項の手順 2 で、既存の設定は上書きされる**。自分で書いたものがあれば、先に退避する

1. 当てられるプリセットの一覧を見る。

   ```bash
   starship preset --list
   ```

   - `plain-text-symbols` と `no-nerd-font` は**Nerd Font が無い端末向け**で、記号を ASCII に置き換える
   - `nerd-font-symbols` / `pastel-powerline` / `gruvbox-rainbow` などは Nerd Font が要る（[HackGen Console NF](#hackgen-console-nf) など）
   - **次の手順は、使うプリセットを決めてから貼る**

1. 選んだプリセットを `~/.config/starship.toml` に書き出す（`STARSHIP_PRESET` は、この項の手順 1 で選んだ名前にする）。

   ```bash
   STARSHIP_PRESET=plain-text-symbols   # 当てるプリセット（この項の手順 1 の一覧から）。<STARSHIP_PRESET>
   ```

   ```bash
   if [ -z "${STARSHIP_PRESET}" ]; then echo '中断: STARSHIP_PRESET が空のまま。値を入れて貼り直す' >&2; else
     mkdir -p ~/.config
     starship preset "${STARSHIP_PRESET}" -o ~/.config/starship.toml --force &&
       wc -l ~/.config/starship.toml &&
       starship prompt
   fi
   ```

   - 設定ファイルの変更だけなら `~/.bashrc` を読み直す必要はない。次のプロンプトから変わる

#### starship の設定ファイル

- starship の設定ファイル `~/.config/starship.toml` を、手で書く
- 前提: [シェルのツール](#シェルのツール)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。[シェルのツール](#シェルのツール)でツールを入れた後に開いた、starship を読み込んだ端末）
- `~/.config/starship.toml` は**既定では存在しない**（無ければ組み込みの既定値で動く）

> [!WARNING]
> この項の手順 1 は、`~/.config/starship.toml` が既にあれば、まるごと置き換える（[starship のプリセットを当てる](#starship-のプリセットを当てる)の設定も消える）。残すなら、先に別の名前で控える

1. `~/.config/starship.toml` に、設定を手で書く。

   ```bash
   mkdir -p ~/.config
   cat > ~/.config/starship.toml <<'EOF'
   add_newline = false

   [directory]
   truncation_length = 3
   truncate_to_repo = false
   EOF
   starship prompt
   ```

   - `~/.config/starship.toml` が既にあれば、まるごと置き換える（[starship のプリセットを当てる](#starship-のプリセットを当てる)の設定も消える）

#### starship でユーザー名とホスト名を常に表示する

- ユーザーを切り替えても名前を出す（starship の既定は、SSH のときと、ログインしたユーザーと違うときだけ出す）
- 前提: [シェルのツール](#シェルのツール)を通してある。[starship のプリセットを当てる](#starship-のプリセットを当てる)や[starship の設定ファイル](#starship-の設定ファイル)の例を使う場合は、それを先に通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。[シェルのツール](#シェルのツール)でツールを入れた後に開いた、starship を読み込んだ端末）。root の設定は別のファイルになる

1. ユーザー名とホスト名を常に表示する設定を入れる。

   ```bash
   mkdir -p ~/.config
   starship config username.show_always true
   starship config hostname.ssh_only false
   printf '\n\033[7m 確認 \033[0m\n'
   starship module username
   starship module hostname
   ```

   - ユーザー名とホスト名が出ることを確かめる
   - 次のプロンプトから反映される。端末の開き直しや `~/.bashrc` の読み直しは不要
   - 設定後にプリセットや設定ファイルを上書きした場合は、この項の手順をもう一度実行する

#### fzf の使い方の基本

- 全部のキーと変数は `man fzf`（Homebrew のものが読める）と [README](https://github.com/junegunn/fzf#readme)

| シェルのキー | すること | 動きを変える変数 |
|---|---|---|
| Ctrl+R | 履歴を曖昧検索で選び、プロンプトに入れる（実行はしない） | `FZF_CTRL_R_OPTS` |
| Ctrl+T | 今のディレクトリの下のファイル・ディレクトリを選び、カーソルの位置に入れる（Tab で複数） | `FZF_CTRL_T_COMMAND`・`FZF_CTRL_T_OPTS` |
| Alt+C | 今のディレクトリの下のディレクトリを選んで `cd` する | `FZF_ALT_C_COMMAND`・`FZF_ALT_C_OPTS` |
| `<コマンド> **` + Tab | パス（`cd` などはディレクトリ、`ssh` はホスト、`export` は変数）を選んで入れる | `FZF_COMPLETION_TRIGGER`（既定 `**`）・`FZF_COMPLETION_OPTS` |

| fzf の画面のキー | すること |
|---|---|
| 文字 | 打つたびに絞り込む |
| ↑ / ↓、Ctrl+K / Ctrl+J、Ctrl+P / Ctrl+N | 候補を上下に動く |
| Enter | 選んで閉じる |
| Esc、Ctrl+C、Ctrl+G | 選ばずに閉じる |
| Tab / Shift+Tab | 複数を選ぶ・外す（Ctrl+T と `**<Tab>` のパスのとき） |
| Ctrl+R（履歴の中で） | 並びを「新しい順」と「一致の良い順」で切り替える（右上の `+S`） |

| 検索の書き方 | 意味 | 例（`apple banana cherry grape pineapple apple-pie` から） |
|---|---|---|
| `ap` | 文字が順に含まれる（曖昧一致） | `apple` `apple-pie` `grape` `pineapple` |
| `'ap` | その文字列をそのまま含む（完全一致） | 同上（`'apple` なら `apple` `apple-pie` `pineapple`） |
| `^ap` | その文字列で始まる | `apple` `apple-pie` |
| `le$` | その文字列で終わる | `apple` `pineapple` |
| `!ap` | 含まない | `banana` `cherry` |
| `ap le`（空白） | 両方に一致（AND） | `apple` `apple-pie` `pineapple` |
| `ap \| ch` | どちらかに一致（OR） | `apple` `cherry` `apple-pie` `grape` `pineapple` |

- 共通の見た目や動き（`--height`・`--layout`・`--border` など）は `FZF_DEFAULT_OPTS` に書く。本書では変えていない

#### fzf で fd と bat を候補とプレビューに使う

- Ctrl+T と Alt+C の候補を、fd の一覧に変える（`.git` の中を除き、隠しファイルは含める。`.gitignore` の対象は fd が既定で除く）
- 前提: [シェルのツール](#シェルのツール)を通してある（bat は、その項の手順 1 で入る）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）。この項の手順 2 で端末を開き直し、手順 3 からは開き直した端末で貼る
- 共通の bash 設定が、fd があるときに候補の `FZF_*` の 3 つの変数を入れる。Ctrl+T の右側の bat のプレビュー（`FZF_CTRL_T_OPTS`）は、bat があれば入るので、[シェルのツール](#シェルのツール)の手順 1 の後から出ている。`~/.bashrc` への追記は要らない
- `**<Tab>` の候補は変わらない（`find` のまま）
- fd は[Neovim](neovim.md#neovim)の手順 3（自分用の Neovim の設定の導入）と[yazi](almalinux-setup.md#yazi)の手順 2 でも入る。fd が入っていれば、この項の手順 1・2 は飛ばす
- 戻すときは、この項の手順 5

1. brew で fd を入れる。

   ```bash
   brew install fd
   ```

   - 確認が出たら `y`（Enter は要らない）
   - EPEL の `fd-find` と二重に入れない
   - **次の手順は、プロンプトに戻ってから行う**

1. 開いている端末を閉じて、開き直す。

   - **次の手順は、開き直した端末で貼る**

1. fd と bat があり、変数が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   command -v fd bat
   printf '%s\n' "${FZF_DEFAULT_COMMAND-}" "${FZF_CTRL_T_COMMAND-}" "${FZF_ALT_C_COMMAND-}" "${FZF_CTRL_T_OPTS-}"
   ```

   - 2 つのパスと、`fd` を使う候補の 3 変数・`bat` を使うプレビューの変数が出ればよい

1. `cat ` と打ってから Ctrl+T を押し、候補が fd の一覧になったことを確かめる。

   - `.git` の中のファイルと、`.gitignore` に書かれたファイルは一覧に出ない
   - 一覧の右側に、選んでいるファイルの中身が行番号と色付きで出る。Esc で閉じる

1. 元に戻すときは、fd を消す。

   ```bash
   brew uninstall fd
   ```

   - `Uninstalling /home/linuxbrew/.linuxbrew/Cellar/fd/…` と出ればよい
   - [Neovim](neovim.md#neovim)の手順 3 か[yazi](almalinux-setup.md#yazi)の手順 2 で fd を入れてあれば、消さない（自分用の Neovim の設定のファイルピッカーと yazi も使う）

#### eza の表示を調整する

設定ファイルは無く、すべてコマンドラインオプションと環境変数で決める。よく使うもの:

| やりたいこと | オプション |
|---|---|
| 列の見出しを出す | `--header`（`-h`） |
| 時刻の書式を変える | `--time-style=long-iso` / `iso` / `relative` / `+%Y-%m-%d` |
| 8 進数のパーミッション | `--octal-permissions`（`-o`） |
| アイコンを出す | `--icons=always`（**Nerd Font が要る**） |
| ディレクトリを先に並べる | `--group-directories-first` |
| `.gitignore` のファイルを隠す | `--git-ignore` |
| git 連携を切る | `--no-git` |

- 色は `LS_COLORS` と `EZA_COLORS` を見る
- 全オプションは `eza --help`（86 行）と `man eza`

#### bat の設定ファイル

- bat の設定ファイルを置き、テーマ・表示の飾り・ページャを決める
- 前提: [シェルのツール](#シェルのツール)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）
- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は `~/.config/bat/config`（`bat --config-file` で確認できる）
  - 既定の場所に置く限り bat は自分で見つける。別の場所に置きたいときだけ `BAT_CONFIG_PATH` を `~/.bashrc` に `export` する

1. よく変える 3 つだけを書いた、最小の設定ファイルを置く。

   ```bash
   BAT_THEME_NAME=ansi   # 使うテーマ。ansi は端末の 16 色にそのまま従う（一覧は bat --list-themes）。<BAT_THEME_NAME>
   ```

   ```bash
   if [ -z "${BAT_THEME_NAME}" ]; then echo '中断: BAT_THEME_NAME が空のまま。値を入れて貼り直す' >&2; else
     mkdir -p ~/.config/bat
     cat > ~/.config/bat/config <<EOF
   --theme="${BAT_THEME_NAME}"
   --style="numbers,changes,header"
   --paging=never
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     cat ~/.config/bat/config
     bat --config-file
   fi
   ```

   - 書いた 3 行と、`/home/<USER>/.config/bat/config` が出ればよい
   - `中断:` と出たら、何も書いていない

#### tmux を試す

- tmux のセッションを作り、抜けて（デタッチ）、入り直して（アタッチ）、終わらせる
- 前提: [シェルのツール](#シェルのツール)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）

1. tmux のセッションを作って入る。

   ```bash
   tmux new-session -s work
   ```

   - 画面の下に緑の帯（ステータス行）が出て、左端に `[work]` が出る
   - **`Ctrl+b` を押して離してから `d`** で抜ける（デタッチ）。シェルに戻って `[detached (from session work)]` と出る
   - **次の手順は、デタッチしてシェルに戻ってから貼る**（続けて貼ると、tmux の中のシェルへの入力になる）

1. セッションの一覧を見て、もう一度入る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   tmux ls
   tmux attach -t work
   ```

   - `tmux ls` の `work: 1 windows (created …)` は、tmux の画面を出た後のシェルに見える
   - `tmux attach -t work` で、この項の手順 1 の画面に戻る
   - 中で `exit` と打つと、シェルが終わってセッションも終わる。`[exited]` と出てシェルに戻る
   - **次の手順は、`exit` でシェルに戻ってから貼る**（続けて貼ると、tmux の中のシェルへの入力になる）

1. tmux のセッションが残っていないことを確かめる。

   ```bash
   tmux ls
   ```

   - `no server running on /tmp/tmux-<UID>/default` と出る

#### tmux の使い方の基本

- tmux のキーは、**`Ctrl+b`（プレフィックス）を押して離してから**次のキーを押す
- 全部のキーは `Ctrl+b` → `?` で出る（`q` で閉じる）。`man tmux` も Homebrew の tmux のものが読める

| キー（`Ctrl+b` の後） | すること |
|---|---|
| `d` | デタッチ（セッションを残して抜ける） |
| `c` | 新しいウィンドウを作る |
| `n` / `p` | 次 / 前のウィンドウへ |
| `0`〜`9` | その番号のウィンドウへ |
| `w` | セッションとウィンドウの一覧から選ぶ（`q` で閉じる） |
| `s` | セッションの一覧から選ぶ |
| `%` | ペインを左右に分ける |
| `"` | ペインを上下に分ける |
| `o` / 矢印 | 次のペイン / その向きのペインへ |
| `z` | 今のペインを全画面にする（もう一度で戻る） |
| `x` | 今のペインを閉じる（`kill-pane …? (y/n)` に `y`） |
| `[` | さかのぼって読む（コピーモード。矢印・PageUp・PageDown で動き、`q` で戻る） |
| `$` / `,` | セッション / ウィンドウの名前を変える |
| `:` | tmux のコマンドを打つ |
| `Ctrl+b` | `Ctrl+b` を中のアプリに送る |

| コマンド | すること |
|---|---|
| `tmux new-session -s <名前>` | 名前を付けてセッションを作り、入る |
| `tmux new-session -A -s <名前>` | 同じ名前のセッションがあれば入り、無ければ作って入る |
| `tmux new-session -d -s <名前> <コマンド>` | 入らずに、コマンドを動かすセッションを作る（コマンドが終わるとセッションも終わる） |
| `tmux ls` | セッションの一覧（どこかで入っているものには `(attached)`） |
| `tmux attach -t <名前>` | セッションに入る |
| `tmux attach -d -t <名前>` | ほかの端末から入っていれば、そちらを外してから入る |
| `tmux kill-session -t <名前>` | セッションを終わらせる（中のコマンドも止まる） |
| `tmux kill-server` | すべてのセッションを終わらせる |

#### tmux の設定ファイル

- マウスのホイールでさかのぼれるようにし、さかのぼれる行数を 2000 から 50000 に増やす。Claude Code のように出力が長く続くものを、tmux の中で読み返すときに効く
- 前提: [シェルのツール](#シェルのツール)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）
- tmux は、サーバーが起動するときに `~/.tmux.conf` と `~/.config/tmux/tmux.conf` の**両方**を読む（あるものだけ）。新規作成は後者、既存設定がある場合はそのファイルに書く
- マウスを on にすると、マウスでの文字の選択は tmux が受け取る。端末の選択を使うときは、端末の決まりに従う（WezTerm などは Shift を押しながら）

1. 設定ファイルを書く。

   ```bash
   if [ -e ~/.tmux.conf ] || [ -e ~/.config/tmux/tmux.conf ]; then
     echo '中断: tmux の設定ファイルがすでにある。中身を見て、この項の set の 2 行を手で足す' >&2
   else
     mkdir -p ~/.config/tmux
     cat > ~/.config/tmux/tmux.conf <<'EOF'
   # マウス: ホイールでさかのぼる・クリックでペインを選ぶ・境界のドラッグで大きさを変える
   set -g mouse on
   # さかのぼれる行数（既定は 2000）
   set -g history-limit 50000
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     cat ~/.config/tmux/tmux.conf
   fi
   ```

   - 書いた 4 行が出る
   - `中断:` が出たら、既存ファイルの `mouse`・`history-limit` を編集する。両方あるなら `~/.config/tmux/tmux.conf` に異なる値が無いことも確かめる

1. 動いている tmux にも読ませて、効いたか確かめる。

   ```bash
   if TMUX_CHECK_ID=$(tmux new-session -d -P -F '#{session_id}' -s "conf-check-$$"); then
     for conf in ~/.tmux.conf ~/.config/tmux/tmux.conf; do
       if [ -f "${conf}" ]; then tmux source-file "${conf}"; fi
     done
     printf '\n\033[7m 確認 \033[0m\n'
     tmux show -g mouse
     tmux show -g history-limit
     tmux kill-session -t "${TMUX_CHECK_ID}"
   else
     echo '中断: 確認用のセッションを作れなかった。既存セッションは終了しない' >&2
   fi
   ```

   - `mouse on` と `history-limit 50000` が出る

---

### HackGen Console NF

- 日本語と Nerd Fonts のアイコンを含む等幅のフォント HackGen Console NF を、Homebrew の cask で入れる
- 前提: [Homebrew](almalinux-setup.md#homebrew)の手順 1〜3 を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）

1. 変数を設定する。

   ```bash
   HACKGEN_FAMILY='HackGen Console NF'   # 確認と設定に使うファミリー名。<HACKGEN_FAMILY>
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%-15s = %s\n' HACKGEN_FAMILY "${HACKGEN_FAMILY}"
   ```

   - **編集が必須の変数は無い**。この項の手順 5 の確認に使うファミリー名で、既定のまま進められる
   - 文字幅が半角 3:全角 5 の版を使いたいときだけ、`HackGen35 Console NF` に変える
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. `unzip` が入っているか確かめる。

   ```bash
   command -v unzip || echo 'unzip は未導入'
   ```

   - パスが出れば、この項の手順 3 は飛ばす
   - `unzip は未導入` と出たら、この項の手順 3 で入れる

1. `unzip` が未導入のときだけ、`unzip` を入れる。

   ```bash
   sudo dnf install -y unzip
   ```

1. HackGen を Homebrew の cask で入れる。

   ```bash
   brew install --cask font-hackgen-nerd
   ```

   - `==> Moving Font ...` が 4 行出る
   - `font-hackgen-nerd was successfully installed!` で終わる

1. HackGen が入ったか確かめ、かな・漢字・記号・アイコンが入っているかも見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   brew list --cask --versions font-hackgen-nerd
   ls ~/.local/share/fonts/
   fc-list : family style file | grep HackGen
   fc-match "${HACKGEN_FAMILY:?「HackGen Console NF」の手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}"
   for cp in 3042 6f22 e0b0 f09b; do printf 'U+%s: ' "${cp}"; fc-list ":charset=${cp}" family | grep -c -x -F "${HACKGEN_FAMILY:?「HackGen Console NF」の手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}"; done
   ```

   - `font-hackgen-nerd 2.10.0`、4 つの `.ttf`、`HackGen Console NF` と `HackGen35 Console NF` の Regular / Bold の 4 行が出る
   - `fc-match` が `HackGenConsoleNF-Regular.ttf: "HackGen Console NF" "Regular"` を返せばよい
   - **ファイル名が HackGen であることを確かめる**
   - 4 行とも `1` なら入っている（`あ` / `漢` / Powerline の三角 / GitHub のアイコン）

---

### WezTerm

- 端末のアプリ WezTerm（nightly）を COPR から入れ、自分用の設定を入れて起動し直す
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)と[共通の bash 設定](#共通の-bash-設定)を通してある。[HackGen Console NF](#hackgen-console-nf)は任意（通してあれば、自分用の設定がそのフォントで描く）
- 実行場所: GNOME にログインした自分のユーザーの、WezTerm の外の端末（bash。Ptyxis など）。この項の手順 5 の中で、起動し直した WezTerm のタブへ移る

1. chroot を明示して、COPR を有効化する。

   ```bash
   sudo dnf copr enable wezfurlong/wezterm-nightly "rhel-9-$(uname -m)"
   ```

   - 有効化してよいか `[y/N]` で聞かれる
   - **次の手順は、`[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. できた repo ファイルを確かめる。

   ```bash
   cat /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly.repo
   ```

   - `baseurl` が `.../wezterm-nightly/rhel-9-$basearch/`、`gpgcheck=1` になっていればよい

1. WezTerm を入れる。

   ```bash
   sudo dnf install wezterm
   ```

   - 途中で COPR の GPG 鍵の取り込みを聞かれる
   - fingerprint は `FD90 9B62 88A8 4250 AD58 020F A698 91C5 CEA2 757D`（`wezfurlong_wezterm-nightly`）
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. WezTerm が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   rpm -q wezterm wezterm-common wezterm-gui wezterm-mux-server
   dnf -q repoquery --installed --qf '%{name} %{from_repo}\n' 'wezterm*'
   wezterm --version
   ldd /usr/bin/wezterm-gui /usr/bin/wezterm /usr/bin/wezterm-mux-server | grep -c 'not found'   # 0 なら OK
   wezterm ls-fonts | sed -n '1,5p'
   ```

   - GUI は、**GNOME にログイン済みの実セッションの端末から** `wezterm` を起動すれば開く
   - アプリ一覧には「WezTerm」が出る

1. 自分用の設定（[ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)）を入れ、起動し直した WezTerm に移る。

   - [WezTerm の設定を導入する](#wezterm-の設定を導入する)の手順をすべて、その項の実行場所のとおりに通す
   - 参照先の手順 5 で WezTerm を起動し、手順 6 を WezTerm のタブに貼って確かめる

#### WezTerm と HackGen Console NF をデスクトップで使う

- GNOME の等幅のフォントを HackGen Console NF にし、Ctrl+Alt+T と Dash のお気に入りの端末を WezTerm にする
- 前提: [GNOME の表示と入力](almalinux-setup.md#gnome-の表示と入力)（Ctrl+Alt+T のショートカットと Dash のお気に入り）、[HackGen Console NF](#hackgen-console-nf)、[WezTerm](#wezterm)を通してある
- 実行場所: GNOME にログインした自分のユーザーの WezTerm のタブ（bash）

1. GNOME の等幅のフォントを HackGen Console NF にする。

   ```bash
   MONO_FONT='HackGen Console NF 11'   # 等幅のフォントの名前と大きさ。<MONO_FONT>
   ```

   ```bash
   if [ -z "${MONO_FONT}" ]; then echo '中断: MONO_FONT が空のまま。値を入れて貼り直す' >&2; else
     /usr/bin/gsettings get org.gnome.desktop.interface monospace-font-name
     /usr/bin/gsettings set org.gnome.desktop.interface monospace-font-name "${MONO_FONT}"
     printf '\n\033[7m 確認 \033[0m\n'
     /usr/bin/gsettings get org.gnome.desktop.interface monospace-font-name
   fi
   ```

   - 2 つ目の `get` が `'HackGen Console NF 11'` になればよい

1. Ctrl+Alt+T と Dash のお気に入りの端末を WezTerm にする。

   ```bash
   kb=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/
   /usr/bin/gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command 'wezterm start'
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command
   fav=$(/usr/bin/gsettings get org.gnome.shell favorite-apps)
   /usr/bin/gsettings set org.gnome.shell favorite-apps "${fav//org.gnome.Ptyxis.desktop/org.wezfurlong.wezterm.desktop}"
   /usr/bin/gsettings get org.gnome.shell favorite-apps
   ```

   - `'wezterm start'` と、端末のところが `'org.wezfurlong.wezterm.desktop'` になったお気に入りが出ればよい
   - お気に入りに Ptyxis が無かったときは、お気に入りは変わらない

1. Ctrl+Alt+T と Dash から WezTerm が開き、等幅のフォントが変わったことを確かめる。

   - Ctrl+Alt+T と、Dash の WezTerm のアイコンで、WezTerm の窓が開く
   - Ptyxis（アクティビティの画面で `terminal`）の文字が HackGen Console NF になっている

#### WezTerm の設定ファイル

- パッケージ（Windows 11 ではインストーラ）は設定ファイルを置かない。無ければ組み込みの既定値で動く
- [WezTerm](#wezterm)の手順 5 で入れた自分用の設定は、`~/.config/wezterm/wezterm.lua`（下の表の 5）

| 優先 | 場所 | 用途 |
|---|---|---|
| 1 | `wezterm --config-file <path>` | 一時的に別の設定で起動する |
| 2 | 環境変数 `WEZTERM_CONFIG_FILE` | 同上（環境ごとに切り替える） |
| 3 | `~/.wezterm.lua` | **1 ファイルで済む設定はここ**（公式の推奨） |
| 4 | `${XDG_CONFIG_HOME}/wezterm/wezterm.lua`（`XDG_CONFIG_HOME` を設定している場合のみ） | 複数ファイルに分ける設定 |
| 5 | `~/.config/wezterm/wezterm.lua`（`XDG_CONFIG_HOME` 未設定のとき） | 同上 |

- **Windows 11 では**、`~` は `%USERPROFILE%`（`C:\Users\<WIN_USER>`）。置くのは `%USERPROFILE%\.wezterm.lua` か `%USERPROFILE%\.config\wezterm\wezterm.lua`
  - 表の 2 と 3 の間に、`wezterm.exe` と同じフォルダーの `wezterm.lua`（`C:\Program Files\WezTerm\wezterm.lua`）が入る。USB メモリで持ち運ぶとき用で、公式は勧めていない
- **自分用の設定**は [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm) にある（Tokyo Night 系の配色・ピル型タブ・ステータスバー・シェル統合の設定）
  - 導入は[WezTerm](#wezterm)の手順 5。[設定を導入する](#wezterm-の設定を導入する)の手順 5 で端末を開き直す
  - Windows 11 では、同じブロックを Git for Windows の Git Bash に貼る（[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)）
  - どこを変えればよいかは [README の「カスタマイズの勘所」](https://github.com/ryo-aoki-pc/wezterm#カスタマイズの勘所)
  - nightly が前提（stable では未知のオプションで設定エラーになる）。本書で入れるのは、AlmaLinux 10 も Windows 11 も nightly
  - フォントは HackGen Console NF（[HackGen Console NF](#hackgen-console-nf)。Windows 11 は[Windows 11 で HackGen Console NF を入れる](#windows-11-で-hackgen-console-nf-を入れる)）
  - AlmaLinux 10 の公式 Bash 統合との併用は[導入手順の注意点](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#注意点)を参照する
  - Windows 11 は Git Bash を既定にし、Git Bash・PowerShell の統合を設定から読む（[シェル統合](https://github.com/ryo-aoki-pc/wezterm#シェル統合)）
  - `~/.wezterm.lua` があると、clone した設定は読まれない

#### WezTerm の設定を導入する

自分用の WezTerm の設定（[ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)）を `~/.config/wezterm` に clone し、WezTerm を起動し直して読ませる。シェル統合は共通 bash 設定が読む。

- 前提: [WezTerm](#wezterm)の手順 1〜4（WezTerm nightly）と[共通の bash 設定](#共通の-bash-設定)を通してある。[HackGen Console NF](#hackgen-console-nf)は任意
- 実行場所: GNOME にログインした自分のユーザーの bash（Windows 11 は Git Bash）。この項の手順 1〜4 は WezTerm の外の端末、手順 6 は手順 5 で起動し直した WezTerm のタブ
- この項の手順 2 の退避の前に、WezTerm のウィンドウをすべて閉じる
- 既存の設定の確認（この項の手順 1）と退避（手順 2）を省かない

[背景説明](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/reference/install.md)・[検証記録](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/verification/install.md)

1. 既存の WezTerm の設定があるか確かめる。

   ```bash
   ls -ld ~/.wezterm.lua ~/.config/wezterm
   ```

   - どちらかが出たら、手順 2 で退避する
   - 2 行とも `No such file or directory` なら、設定は無い。手順 2 は飛ばす
   - `~/.wezterm.lua` が残っていると、この設定は読まれない

1. 既存の設定があるときだけ、名前の後ろに `.bak` を付けて退避する。

   ```bash
   (
     for f in ~/.wezterm.lua ~/.config/wezterm; do
       if [ -e "$f.bak" ] || [ -L "$f.bak" ]; then
         echo "中断: $f.bak が既にある。何も退避していない" >&2
         exit 1
       fi
     done
     for f in ~/.wezterm.lua ~/.config/wezterm; do
       if [ -e "$f" ] || [ -L "$f" ]; then mv -v "$f" "$f.bak" || exit 1; fi
     done
     ls -ld ~/.wezterm.lua ~/.config/wezterm
   )
   ```

   - あったものだけ、`renamed '/home/<USER>/.config/wezterm' -> '/home/<USER>/.config/wezterm.bak'` のように出る
   - 最後の `ls` が 2 行とも `No such file or directory` ならよい
   - `.bak` が 1 つでもあれば、どちらも動かさず `中断:` で止まる。中身を確かめて片付けてから、この項の手順 2 を貼り直す
   - `中断:` や `mv` のエラーが出たら、手順 3 へ進まない。原因を直して手順 2 を貼り直す
   - 退避したものは、[WezTerm 設定のロールバック](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/extra/install.md#ロールバック)の手順 4 で戻せる

1. この設定を `~/.config/wezterm` に clone する。

   ```bash
   git clone https://github.com/ryo-aoki-pc/wezterm.git ~/.config/wezterm
   git -C ~/.config/wezterm log -1 --oneline
   ```

   - `Cloning into '/home/<USER>/.config/wezterm'...` の後に、最新のコミットが 1 行出る
   - `fatal: destination path '/home/<USER>/.config/wezterm' already exists and is not an empty directory.` と出たら、手順 1 から見直す

1. WezTerm がこの設定を読めるか確かめる。

   ```bash
   wezterm ls-fonts --text 'aあ'
   ```

   - `ERROR  wezterm_gui >` が無ければ設定を読めている。終了コードは誤りがあっても `0` なので使わない
   - `show-keys` は読み込み確認に使わず、`| head` も付けない
   - HackGen Console NF があればそのフォントで描く。無ければフォント警告が出て代替フォントを使う。画面なしでは通知の dbus エラーが出る場合もある
   - Windows でコマンドが無ければ `"/c/Program Files/WezTerm/wezterm.exe" ls-fonts --text 'aあ'` を使う

1. WezTerm のウィンドウをすべて閉じてから、起動し直す。

   - WezTerm を開いていなければ、起動するだけでよい
   - AlmaLinux 10 はアプリ一覧の「WezTerm」から、Windows 11 はスタートメニューの「WezTerm」から起動する
   - シェル統合とウィンドウ装飾は起動し直して反映する
   - **次の手順は、起動し直した WezTerm のタブで貼る**（開いていたタブで貼ると、手順 6 の確かめが外れる）

1. 起動し直した WezTerm のタブで、シェル統合が読まれたか確かめる。

   ```bash
   echo "$TERM_PROGRAM"
   echo "$WEZTERM_SHELL_INTEGRATION"
   declare -F __wezterm_set_user_var __wezterm_notify_done __wz_mouse_off
   ```

   - 1 行目は `WezTerm`、2 行目は `.config/wezterm/shell/wezterm.sh` で終わるパス
   - 3 つ目は、WezTerm のパッケージの公式のシェル統合があるかどうかで変わる
     - AlmaLinux 10 の公式 Bash 統合: `__wezterm_set_user_var`・`__wezterm_notify_done`・`__wz_mouse_off` の 3 行
     - 公式統合との併用は[注意点](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/extra/install.md#注意点)を参照する
     - 公式の統合が無いとき（Windows の Git Bash など）: `__wezterm_notify_done` と `__wz_mouse_off` の 2 行
   - 1 行目が空なら、WezTerm の外で貼っている。2 行目が空なら、手順 5 の前から開いていたタブで貼っている
   - `__wz_mouse_off` が出なければ、`~/.bashrc` の行が読まれていない。共通の bash 設定を見直す

#### WezTerm のシェル統合を SSH 先で使う

手元の WezTerm から ssh でつないだ先でも、WezTerm のシェル統合を使う。手元の WezTerm から `TERM_PROGRAM` を送り、SSH 先の sshd で受け取る。公式 Bash 統合が既に有効なら、変数が未設定でも補完処理が動く。

- 前提: 手元で[WezTerm](#wezterm)を通してある。SSH 先は自分で管理する AlmaLinux 10 で、手元から `ssh <HOST>` でログインできる
- 実行場所: この項の手順 1・4 は手元（WezTerm を使う PC）、手順 2・3・5 は SSH 先の自分のユーザーのシェル（bash）

1. 手元の `~/.ssh/config` で、使う `Host` に `SendEnv TERM_PROGRAM` を足す。

   - エディタで `~/.ssh/config` を開く（Windows は `%USERPROFILE%\.ssh\config`。Git Bash では `~/.ssh/config`）
   - 使う `Host <HOST>` の行の下に、字下げして `SendEnv TERM_PROGRAM` の行を足す
   - WezTerm から ssh したときだけ、`WezTerm` が送られる。公式統合が無い場合、この値が `WezTerm` のときだけ独自統合が動く

1. ssh 先で、sshd が `TERM_PROGRAM` を受け取るようにする。

   ```bash
   {
     echo 'AcceptEnv TERM_PROGRAM' | sudo tee /etc/ssh/sshd_config.d/50-wezterm.conf
     sudo sshd -t && sudo systemctl reload sshd
     sudo sshd -T | grep -i '^acceptenv'
   }
   ```

   - 最後に `acceptenv TERM_PROGRAM` と出ればよい
   - `sshd -t` が設定の誤りを出したら、`reload` はされない
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. SSH 先に共通 bash 設定と WezTerm のシェル統合を置く。

   ```bash
   git clone https://github.com/ryo-aoki-pc/bash.git ~/.config/bash &&
     bash ~/.config/bash/install.sh
   git clone https://github.com/ryo-aoki-pc/wezterm.git ~/.config/wezterm
   ```

   - clone 済みなら、そのリポジトリの更新を行う
   - WezTerm 本体は SSH 先のシェル統合には要らない
   - 同期済みの設定は再 clone しない
   - **次の手順は、clone が成功してから行う**

1. 手元の WezTerm の新しいタブから、ssh し直す。

   - `ssh <HOST>` を打つか、起動メニュー（`Ctrl+Shift+M`）の「ssh <HOST>」を選ぶ
   - **次の手順は、ssh 先のシェルで貼る**

1. ssh 先のシェルで、`TERM_PROGRAM` が届き、シェル統合が読まれたか確かめる。

   ```bash
   echo "$TERM_PROGRAM"
   declare -F __wezterm_set_user_var __wezterm_notify_done __wz_mouse_off
   ```

   - 1 行目が `WezTerm` ならよい。公式 Bash 統合が有効なら、空でも補完処理は動く。公式統合が無ければ、この項の手順 1・2 を見直す
   - 2 つ目の見方は`__wezterm_notify_done` と `__wz_mouse_off` が出ればよい。COPR の公式統合が有効なら `__wezterm_set_user_var` も出る
   - tmux の中では `TERM_PROGRAM` が `tmux` になり、マウス報告よけのほかは動かない

#### WezTerm: Windows の SSH 先で PowerShell に貼り付ける

手元の WezTerm から Windows の SSH 先に入り、その PowerShell の PSReadLine の入力欄へ複数行を貼る。接続元は Linux または Windows の WezTerm、接続先は Windows OpenSSH と Git Bash。両側にこの版の設定を置く（この項の手順 1）。

- 前提: 接続元で[WezTerm](#wezterm)（Windows の接続元は[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)）を通してある。Windows 接続先で [OpenSSH サーバー](windows-setup.md#openssh-サーバー)・[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)・[SSH の既定シェル](windows-setup.md#ssh-の既定のシェルを-git-bash-にする)を通してある
- 実行場所: 接続元の WezTerm のタブ（Linux では GUI セッションから起動した WezTerm）。この項の手順 4・9 は接続先の Git Bash、手順 5〜8 は接続先の PowerShell
- 通常の PowerShell プロファイルには追記しない
- 管理者・同じユーザーの非管理者 PowerShell の切り替えは [Windows の SSH 操作手順](windows-setup.md#ssh-で管理者非管理者の-powershell-を使う)を使う
- **この項の手順 3 の `surface` は検証環境の SSH 接続名。貼る前に、自分の設定済み接続名へ置き換える**

[参照情報](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/reference/install.md)・[検証記録](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/verification/install.md)

1. 接続元と Windows 接続先の設定を、[WezTerm の設定を更新する](#wezterm-の設定を更新する)の手順 1 で更新する。

   - Windows 接続先では Git Bash で、[Windows の設定更新](#windows-11-で-wezterm-の設定を更新する)の手順 2 を通す
   - 接続元は `Ctrl+Shift+R` で設定を読み直す
   - 通常の PowerShell プロファイルには追記しない

1. Linux の接続元では、セッションに対応するクリップボード取得コマンドがあるか確かめる。

   ```bash
   if [ -n "${WAYLAND_DISPLAY-}" ]; then
     command -v wl-paste
   elif [ -n "${DISPLAY-}" ]; then
     command -v xclip
   else
     echo 'GUI セッションから WezTerm を起動してください'
   fi
   ```

   - Wayland は `wl-paste`、X11 は `xclip` のパスが出ればよい
   - 無ければ接続元の dnf で `wl-clipboard`（Wayland）か `xclip`（X11）を導入し、この項の手順 2 をやり直す。GUI セッションが無い場合も先へ進まない
   - Windows 接続元ではこの手順を飛ばす。標準の Windows PowerShell を `-NoProfile` で使う

1. 接続元の WezTerm の新しいペインで Windows に接続する。

   ```bash
   ssh surface
   ```

   - `surface` はこの環境の SSH エイリアス。別の接続先では自分のホスト名を使う
   - Windows OpenSSH の既定シェルは Git Bash とする
   - **次の手順は、接続先の Git Bash のプロンプトが出てから貼る**

1. 接続先の Git Bash で統合を読み、Windows PowerShell 5.1 を起動する。

   ```bash
   export TERM_PROGRAM=WezTerm
   . ~/.config/wezterm/shell/wezterm.sh
   powershell.exe -NoLogo -NoExit -Command '. "$env:USERPROFILE\.config\wezterm\shell\wezterm.ps1"'
   ```

   - PowerShell 7 を使う場合は、最後の行の `powershell.exe` を `pwsh.exe` に替える
   - **次の手順は、PowerShell のプロンプトが出てから貼る**

1. 接続先 PowerShell で、専用受信キーが登録されたか確かめる。

   ```powershell
   Get-Module PSReadLine | Select-Object Name, Version; Get-PSReadLineKeyHandler -Bound | Where-Object Function -eq WezTermSshPaste
   ```

   - `Ctrl+Shift+F12` の `WezTermSshPaste` が出ればよい。このキーは配送用で、手動では押さない
   - キーが無ければ PSReadLine を読み込み、統合を読み直してから確認する

1. 接続元で無害な複数行をコピーし、右クリックまたは `Ctrl+Shift+V` で貼る。

   ```powershell
   & {
     '一行目'

     '二行目'
   }
   ```

   - このブロックは入力欄に残り、Enter を押すまで実行しない
   - 空行・日本語・末尾改行を保持する。PSReadLine の Paste と同じく CR を除き、タブを空白 4 個にする
   - 準備応答・取得・検証が失敗すると通知し、本文を挿入しない。自動で通常貼り付けに切り替えない
   - 本文は UTF-8 で 64 KiB まで。途中で `Ctrl+C` を押すと終端まで受信して捨てる。配送が止まった場合は受信待機が続くため、本文を追加で貼らず、接続元でその SSH ペインを閉じて接続し直す

1. 入力欄を確認し、Enter を押して実行する。

   - `一行目`・`二行目` が一度ずつ出ればよい
   - **次の手順は、PowerShell のプロンプトが戻ってから行う**

1. PowerShell を終了して Git Bash に戻る。

   ```powershell
   exit
   ```

   - **次の手順は、Git Bash のプロンプトに戻ってから貼る**

1. 接続先の Git Bash で接続を閉じる。

   ```bash
   exit
   ```

   - 接続元のプロンプトに戻ればよい

#### WezTerm の設定を更新する

自分用の WezTerm の設定のリポジトリを pull で上げる。WezTerm 本体の更新は[更新](almalinux-setup.md#更新)で行う。

- 前提: [WezTerm](#wezterm)を通してある
- 実行場所: 自分のユーザーの bash（Windows 11 は Git Bash）

1. 設定のリポジトリを pull する。

   ```bash
   git -C ~/.config/wezterm pull
   git -C ~/.config/wezterm log -1 --oneline
   ```

   - 新しいコミットが無ければ、`Already up to date.` と出る
   - 起動中の WezTerm は、ファイルが変わると設定を読み直す（効かなければ `Ctrl+Shift+R`）
   - シェル統合（`shell/`）とウィンドウの装飾の変更は、WezTerm を起動し直すまで効かない
   - 手元で変えたファイルがあって pull が止まったら、`git -C ~/.config/wezterm status` で見る

---

## Windows 11 で使う

- HackGen Console NF・Windows Terminal・WezTerm・Git Bash と共通の bash 設定・シェルのツール・PowerShell 7 のプロファイル

### Windows 11 で HackGen Console NF を入れる

- HackGen Console NF を自分のユーザーのフォントに入れる
- 前提: 無し
- 実行場所: 管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - 窓の名前に「管理者:」が付いていないことを確かめる

1. HackGen がまだ入っていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Item -LiteralPath 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' -ErrorAction SilentlyContinue | ForEach-Object { $_.Property -like 'HackGen*' }
   Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts", "$env:WINDIR\Fonts" -Filter 'HackGen*' -ErrorAction SilentlyContinue | Format-Table Name, DirectoryName
   ```

   - どちらも何も出なければ、入っていない
   - `C:\Windows\Fonts` のファイルが出たら、PC 全体に入っている（ほかの方法で入れたもの）。この項は要らない

1. HackGen Console NF の zip を取り、sha256 を確かめて自分のユーザーのフォントに入れる。

   ```powershell
   & {
     $ver = '2.10.0'
     $sha256 = 'F8ABD483D5EDFAD88A78ED511978F43C83B43C48E364AA29EBE4A68217474428'
     $fonts = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
     $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
     $tmp = "$env:TEMP\hackgen-setup"
     $zip = "$tmp\HackGen_NF_v$ver.zip"
     Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & "$env:WINDIR\System32\curl.exe" -fsSL -o $zip "https://github.com/yuru7/HackGen/releases/download/v$ver/HackGen_NF_v$ver.zip"
     if ($LASTEXITCODE -ne 0) { Write-Error "中断: HackGen_NF_v$ver.zip を取れない"; return }
     if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $sha256) { Write-Error "中断: HackGen_NF_v$ver.zip の sha256 が一致しない"; return }
     Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
     $ttf = @(Get-ChildItem -LiteralPath "$tmp\HackGen_NF_v$ver" -Filter '*.ttf')
     if ($ttf.Count -ne 4) { Write-Error "中断: zip の中の ttf が 4 つではない（$($ttf.Count)）"; return }
     New-Item -ItemType Directory -Force -Path $fonts | Out-Null
     icacls.exe $fonts /grant '*S-1-15-2-1:(OI)(CI)(RX)' '*S-1-15-2-2:(OI)(CI)(RX)' | Out-Null
     if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key | Out-Null }
     foreach ($f in $ttf) {
       $dst = Join-Path $fonts $f.Name
       if (-not (Test-Path -LiteralPath $dst) -or (Get-FileHash -LiteralPath $dst).Hash -ne (Get-FileHash -LiteralPath $f.FullName).Hash) {
         try { Copy-Item -LiteralPath $f.FullName -Destination $dst -Force -ErrorAction Stop } catch { Write-Error "中断: $($f.Name) を置けない（$($_.Exception.Message)）"; return }
       }
       New-ItemProperty -Path $key -Name "$($f.BaseName) (TrueType)" -Value $dst -PropertyType String -Force | Out-Null
     }
     Remove-Item -LiteralPath $tmp -Recurse -Force
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ItemProperty -LiteralPath $key | Select-Object -Property 'HackGen*' | Format-List
   }
   ```

   - `HackGen35ConsoleNF-Bold (TrueType) : C:\Users\<WIN_USER>\AppData\Local\Microsoft\Windows\Fonts\HackGen35ConsoleNF-Bold.ttf` の形の行が 4 つ出ればよい
   - `中断:` で始まるエラーが出たら、そこで止まっている
   - 何度貼ってもよい
   - アプリで使えるのは、[WSL と再起動](windows-setup.md#wsl-と再起動)の手順 3 の再起動の後（確かめるのは[再起動の後に確かめる](windows-setup.md#再起動の後に確かめる)の手順 5）

#### HackGen Console NF を上げる

- HackGen Console NF の新しい版を確かめ、必要なときに入れ直す
- 前提: [HackGen Console NF](#windows-11-で-hackgen-console-nf-を入れる)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。削除・再導入・確認は、リンク先の項に指定した窓で行う

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. HackGen の新しい版が出ているかを確かめる。

   ```powershell
   (Invoke-RestMethod -Uri https://api.github.com/repos/yuru7/HackGen/releases/latest).tag_name
   ```

   - `v2.10.0` なら、新しい版は無い。この項の手順 3 は行わない
   - 違う版なら、[HackGen Console NF](#windows-11-で-hackgen-console-nf-を入れる)の手順 3 の `$ver` と `$sha256` を、その版の zip と、その zip から計算して確認したハッシュ値に合わせて直してから貼る

1. 新しい版にするときだけ、今の版を外してから入れ直す。

   - [ロールバックの「HackGen Console NF を消す」](extra/windows-setup.md#hackgen-console-nf-を消す)の手順 1〜3（登録を消し、サインインし直してから、ファイルを消す）を行う
   - 続けて、直した[HackGen Console NF](#windows-11-で-hackgen-console-nf-を入れる)の手順 3 を貼り、サインアウトしてサインインし直してから、[再起動の後に確かめる](windows-setup.md#再起動の後に確かめる)の手順 5 で確かめる

---

### Windows Terminal のフォントと貼り付けの警告を変える

- Windows Terminal のフォントを HackGen にし、必要なら複数行の貼り付けの警告を切る
- 前提: [HackGen Console NF](#windows-11-で-hackgen-console-nf-を入れる)を通し、サインインし直してある。Windows Terminal が入っている（[Microsoft Store の更新](windows-setup.md#microsoft-store-の更新)で更新する）
- 実行場所: 管理者ではない Windows Terminal の Windows PowerShell（5.1）のタブ。この項の手順 1 で開く

- **この項の手順 5 は Windows Terminal の設定の画面で行う**
- 効くのは Windows Terminal で開く窓（管理者ではない窓と、Win+X の「ターミナル」・「ターミナル (管理者)」）だけ。スタートメニューから管理者として開いた PowerShell（conhost の窓）には効かない
- 管理者ではない窓に複数行のブロックを貼ると、「警告」の窓が出ることがある（Windows PowerShell 5.1 は、角かっこで囲む貼り付けを使わないため）。「強制的に貼り付け」を押す（出さないなら、この項の手順 4）
- この項の手順 2〜5 は `settings.json` だけを読み書きし、既定のプロファイル（Windows PowerShell）と `copyOnSelect` は変えない
- 選んだらコピーするときは、[Windows Terminal で選択した文字をコピーする](#windows-terminal-で選択した文字をコピーする)を通す。この項の手順 6 は、その設定も含めて控えを書き戻す
- 戻すときは、この項の手順 6

> [!WARNING]
> - この項の手順 4 で警告を切ると、信用できない複数行の文字も、確かめずにそのまま貼られて動く
> - この項の手順 6 は、控えた後に画面で変えた Windows Terminal の設定も、控えたときに戻す。残すなら手順 6 は貼らず、この項の手順 5 の画面でフォント スタイルと警告を戻す

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows Terminal」を開き、タブのメニューから「Windows PowerShell」を選ぶ（Windows PowerShell 5.1 のタブ）

1. Windows Terminal の設定ファイルを控え、今のフォントと警告の値を確かめる。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     $bak = "$path.windows-setup.bak"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not (Test-Path -LiteralPath $path)) { Write-Error "中断: 設定ファイルが無い。Windows Terminal を 1 度開いてから貼り直す: $path"; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある。この項の手順 5 の画面で変える: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない。この項の手順 5 の画面で変える: $path"; return }
     if (-not $s.profiles -or $s.profiles -is [array]) { Write-Error '中断: profiles が無いか古い形式（配列）。この項の手順 5 の画面で変える'; return }
     if (Test-Path -LiteralPath $bak) { "控えはもうある（書き換えない）: $bak" } else { Copy-Item -LiteralPath $path -Destination $bak -ErrorAction Stop; "控えた: $bak" }
     [pscustomobject]@{
       Version          = (Get-AppxPackage -Name Microsoft.WindowsTerminal | Select-Object -First 1).Version
       DefaultsFontFace = $s.profiles.defaults.font.face
       MultiLinePaste   = $s.'warning.multiLinePaste'
       DefaultProfile   = $s.defaultProfile
       CopyOnSelect     = $s.copyOnSelect
     } | Format-List
     $s.profiles.list | Where-Object { $_.font.face } | Format-Table name, @{ Name = 'face'; Expression = { $_.font.face } }
   }
   ```

   - `控えた:`（2 回目からは `控えはもうある`）の行と、`Version : 1.25.…` の形の 5 行が出ればよい。`DefaultsFontFace` が空なら、既定のフォント（Cascadia Mono）
   - 控えは `…\LocalState\settings.json.windows-setup.bak`。控えが無いときだけ作る（この項の手順 6 で使い、書き戻すと消える）
   - 最後に表が出たら、そのプロファイルは自分のフォントを持つので、この項の手順 3 の値は効かない（この項の手順 5 の画面で、そのプロファイルを変える）
   - `中断:` が出たら、何も書いていない。この項の手順 5 の画面で変える
   - `Version` が 1.24 より前なら、この項の手順 4 は飛ばす

1. 全プロファイルのフォントを HackGen Console NF にする。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     if (-not (Test-Path -LiteralPath "$path.windows-setup.bak")) { Write-Error '中断: 控えが無い。この項の手順 2 を先に貼る'; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない: $path"; return }
     if (-not $s.profiles -or $s.profiles -is [array]) { Write-Error '中断: profiles が無いか古い形式（配列）'; return }
     if (-not $s.profiles.PSObject.Properties['defaults']) { $s.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) }
     if (-not $s.profiles.defaults.PSObject.Properties['font']) { $s.profiles.defaults | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{}) }
     $s.profiles.defaults.font | Add-Member -NotePropertyName face -NotePropertyValue 'HackGen Console NF' -Force
     [IO.File]::WriteAllText($path, ($s | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'face: {0}' -f ([IO.File]::ReadAllText($path) | ConvertFrom-Json).profiles.defaults.font.face
   }
   ```

   - `face: HackGen Console NF` が出ればよい
   - 保存した直後に、開いているタブにも効く
   - フォントが見つからないと、端末に、フォントが見つからない旨が出て、別のフォントで出る（この項の手順 5 で確かめる）

1. Windows Terminal が 1.24 以降で、複数行を貼るたびに出る警告を出さないときだけ、警告を切る。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     $ver = (Get-AppxPackage -Name Microsoft.WindowsTerminal | Select-Object -First 1).Version
     if (-not $ver -or [version]$ver -lt [version]'1.24') { Write-Error "中断: Windows Terminal の版が 1.24 より前: $ver"; return }
     if (-not (Test-Path -LiteralPath "$path.windows-setup.bak")) { Write-Error '中断: 控えが無い。この項の手順 2 を先に貼る'; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない: $path"; return }
     $s | Add-Member -NotePropertyName 'warning.multiLinePaste' -NotePropertyValue 'never' -Force
     [IO.File]::WriteAllText($path, ($s | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'warning.multiLinePaste: {0}' -f ([IO.File]::ReadAllText($path) | ConvertFrom-Json).'warning.multiLinePaste'
   }
   ```

   - `warning.multiLinePaste: never` が出ればよい
   - **注意**: 信用できない複数行の文字も、確かめずにそのまま貼られて動く
   - 5 KiB を超える文字を貼るときは、別の警告が出ることがある

1. Windows Terminal の設定の画面で、フォントが見つかっていることを確かめる。

   - Windows Terminal の窓で Ctrl+, を押し、「既定値」→「外観」の「フォント スタイル」が `HackGen Console NF` で、「見つからないフォント:」が出ていない
   - 新しいタブを開くと、文字が HackGen になっている
   - この項の手順 2〜4 が `中断:` で止まったときは、この画面でフォント スタイルを選んで「保存」を押す（一覧に無ければ「すべてのフォントの表示」をオン）。警告は「操作」の「改行を貼り付ける際に警告する」を「なし」にする
   - **次の手順は、設定の画面を閉じてから貼る**

1. 元に戻すときは、控えた設定ファイルを書き戻す。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     $bak = "$path.windows-setup.bak"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not (Test-Path -LiteralPath $bak)) { Write-Error "中断: 控えが無い: $bak"; return }
     Copy-Item -LiteralPath $bak -Destination $path -Force -ErrorAction Stop
     Remove-Item -LiteralPath $bak
     $s = [IO.File]::ReadAllText($path) | ConvertFrom-Json
     'face: {0} / warning.multiLinePaste: {1}' -f $s.profiles.defaults.font.face, $s.'warning.multiLinePaste'
   }
   ```

   - 控えたときの値（ふつうは 2 つとも空）が出ればよい。開いているタブにもすぐ効く
   - 控えた後に画面で変えた Windows Terminal の設定も、控えたときに戻る。残すなら、このブロックは貼らず、この項の手順 5 の画面でフォント スタイルと警告を戻す
   - `中断: 控えが無い` が出たら、この項の手順 5 の画面で戻す
   - 控えのファイルは消える（もう一度この項を通すと、そのときの設定を控え直す）

#### Windows Terminal で選択した文字をコピーする

- 任意で、Windows Terminal の選択した文字を自動でコピーする `copyOnSelect` を `true` にする
- 前提: [Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)の手順 1・2 を通し、`settings.json.windows-setup.bak` がある
- 実行場所: この PC のデスクトップの管理者ではない Windows Terminal の Windows PowerShell（5.1）のタブ。この項の手順 1 で開く
- コメントや末尾のカンマがあるファイルには書かない。控えは上書きしない（[補足](reference/shell-terminal.md#windows-terminal-で選択した文字をコピーする--手順-2-補足-copyonselect-と貼り付け)）

> [!WARNING]
> - この項の手順 2 の後は、文字を選ぶだけでクリップボードが置き換わり、手順書からコピーしたブロックも消える。右クリックは貼り付けになる。
> - [Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)の手順 4 で複数行の警告を切っていると、管理者の窓でも複数行が確かめずに動く。

1. 管理者ではない Windows Terminal の Windows PowerShell（5.1）のタブを開く。

   - スタートメニューで「Windows Terminal」を開き、タブのメニューから「Windows PowerShell」を選ぶ

1. 設定ファイルの最上位の `copyOnSelect` を `true` にする。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     if (-not (Test-Path -LiteralPath $path)) { Write-Error "中断: 設定ファイルが無い: $path"; return }
     if (-not (Test-Path -LiteralPath "$path.windows-setup.bak")) { Write-Error '中断: 控えが無い。shell-terminal.md の「Windows Terminal のフォントと貼り付けの警告を変える」の手順 2 を先に通す'; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない: $path"; return }
     if (-not $text.TrimStart().StartsWith('{')) { Write-Error '中断: 最上位がオブジェクトではない'; return }
     $s | Add-Member -NotePropertyName copyOnSelect -NotePropertyValue $true -Force
     [IO.File]::WriteAllText($path, ($s | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'copyOnSelect: {0}' -f ([IO.File]::ReadAllText($path) | ConvertFrom-Json).copyOnSelect
   }
   ```

   - `copyOnSelect: True` が出ればよい。開いている Windows Terminal にも効くはず（文書とソースからの推測で、実機では確かめていない）
   - `中断:` が出たら、何も書いていない。コメントや末尾のカンマを残すときは、Windows Terminal の設定の「操作」で「選択範囲をクリップボードに自動的にコピー」をオンにして保存する

1. 元に戻すときは、`copyOnSelect` だけを `false` に戻す。

   ```powershell
   & {
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     if (-not (Test-Path -LiteralPath $path)) { Write-Error "中断: 設定ファイルが無い: $path"; return }
     if (-not (Test-Path -LiteralPath "$path.windows-setup.bak")) { Write-Error '中断: 控えが無い。shell-terminal.md の「Windows Terminal のフォントと貼り付けの警告を変える」の手順 2 を先に通す'; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない: $path"; return }
     if (-not $text.TrimStart().StartsWith('{')) { Write-Error '中断: 最上位がオブジェクトではない'; return }
     $s | Add-Member -NotePropertyName copyOnSelect -NotePropertyValue $false -Force
     [IO.File]::WriteAllText($path, ($s | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'copyOnSelect: {0}' -f ([IO.File]::ReadAllText($path) | ConvertFrom-Json).copyOnSelect
   }
   ```

   - `copyOnSelect: False` が出ればよい。ほかのキーの値は残る
   - コメントや末尾のカンマで止まったら、この項の手順 2 の設定画面で「選択範囲をクリップボードに自動的にコピー」をオフにして保存する
   - [Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)の手順 6 で後から控えを書き戻すと、この設定も控えたときの値に戻る

---

### Windows 11 で WezTerm を入れる

- WezTerm nightly と、必要な Visual C++ ランタイムを PC 全体に入れる
- 前提: [Microsoft Store の更新](windows-setup.md#microsoft-store-の更新)を通し、winget が使える
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリックして「管理者として実行」を選ぶ（PowerShell 7 の「PowerShell」ではない）
   - ユーザーアカウント制御（UAC）の確認は「はい」

1. 管理者であることと、今の WezTerm と `VCRUNTIME140.dll` があるかを確かめる。

   ```powershell
   $u = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1' -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     Admin     = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Version   = $u.DisplayVersion
     Location  = $u.InstallLocation
     OnPath    = (Get-Command wezterm.exe -All -ErrorAction SilentlyContinue).Source -join ' '
     Running   = (Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue).ProcessName -join ' '
     VCRuntime = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
   } | Format-List
   ```

   - `Admin : True` であること（`False` なら、この項の手順 1 で管理者の窓を開き直してから、このブロックを貼る）
   - 初めて入れる PC では、`Version`・`Location`・`OnPath`・`Running` が空
   - `Version` に版が出たら、もう入っている（`20260905-153129-092dcf70` など）。この項の手順 4 で今の nightly に上書きする
     - `Location` は `C:\Program Files\WezTerm\` のはず。違う場所なら、インストーラはそこに上書きするので、先に[ロールバックの「OpenSSH・Git for Windows・Firefox・WezTerm を外す」](extra/windows-setup.md#opensshgit-for-windowsfirefoxwezterm-を外す)の手順 8 で外す
   - `OnPath` に `C:\Program Files\WezTerm\wezterm.exe` 以外（scoop の `shims` など）が出たら、ほかの方法で入れた WezTerm がある。外してから始める
   - `Running` に名前が出たら、その WezTerm の窓を閉じる（[Claude Code の Remote Control（Windows）](ai-agents.md#claude-code-の-remote-control-実施手順)のタスクは、AI エージェントの手順書の[Claude Code の Remote Control: 止める・もう一度始める](ai-agents.md#claude-code-の-remote-control-止めるもう一度始める)の手順 1 で止める）
   - `VCRuntime : True` なら、この項の手順 3 は飛ばす。`False` なら、この項の手順 3 で入れる

1. `VCRUNTIME140.dll` が無いときだけ、Visual C++ の再頒布可能パッケージを入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget install --exact --id Microsoft.VCRedist.2015+.x64 --source winget --scope machine --accept-source-agreements --accept-package-agreements
   Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と、`True` が出ればよい
   - 最後が `True` ならこの項の手順 4へ進む
   - 最後の行が `False` なら、Windows を再起動してデスクトップにサインインし、この項の手順 1 から行う
   - `winget` が見つからないというエラーになったら、Microsoft Store で「アプリ インストーラー」を更新してから始める

1. nightly のインストーラを取り、sha256 を確かめて、黙って入れる。

   ```powershell
   & {
     $dir = 'C:\Program Files\WezTerm'
     $curl = "$env:WINDIR\System32\curl.exe"
     $url = 'https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-nightly-setup.exe'
     $tmp = "$env:TEMP\wezterm-setup"
     $setup = "$tmp\WezTerm-nightly-setup.exe"
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない'; return }
     if (-not (Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll")) { Write-Error '中断: VCRUNTIME140.dll が無い（この項の手順 3）'; return }
     if (Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue) { Write-Error '中断: WezTerm が動いている（窓をすべて閉じる）'; return }
     Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & $curl -fsSL -o "$setup.sha256" "$url.sha256"
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: WezTerm-nightly-setup.exe.sha256 を取れない'; return }
     & $curl -fsSL -o $setup $url
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: WezTerm-nightly-setup.exe を取れない'; return }
     $m = Select-String -LiteralPath "$setup.sha256" -Pattern '^([0-9a-f]{64})  WezTerm-nightly-setup\.exe$' | Select-Object -First 1
     if (-not $m) { Write-Error '中断: WezTerm-nightly-setup.exe.sha256 に sha256 の行が無い'; return }
     if ((Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash -ne $m.Matches[0].Groups[1].Value) { Write-Error '中断: WezTerm-nightly-setup.exe の sha256 が一致しない'; return }
     $p = Start-Process -FilePath $setup -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCLOSEAPPLICATIONS /LOG=`"$tmp\setup.log`"" -Wait -PassThru
     if ($p.ExitCode -ne 0) { Write-Error "中断: インストーラが終了コード $($p.ExitCode) で終わった（ログは $tmp\setup.log）"; return }
     Remove-Item -LiteralPath $tmp -Recurse -Force
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0'
     & "$dir\wezterm.exe" --version
   }
   ```

   - `WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0` と、`wezterm 20260929-043349-cab25161` の形の 1 行が出ればよい
   - インストーラの画面は出ない。終わるまでプロンプトが戻らない
   - `中断:` で始まるエラーが出たら、そこで止まっている
   - `取れない` と `sha256 が一致しない` は、nightly が入れ替わる最中に取ったときにも出る。少し待って貼り直す
   - 何度貼ってもよい

1. 入ったものと、`PATH`・スタートメニューを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1' | Format-List DisplayName, DisplayVersion, InstallLocation, UninstallString
   & 'C:\Program Files\WezTerm\wezterm.exe' --version
   [Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';' | Where-Object { $_ -like '*\WezTerm*' }
   Test-Path -LiteralPath "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\WezTerm.lnk"
   Get-ChildItem -LiteralPath 'C:\Program Files\WezTerm' -Name
   ```

   - `DisplayVersion` と `wezterm --version` の版が同じ（`20260929-043349-cab25161` の形）
   - `UninstallString` は `"C:\Program Files\WezTerm\unins000.exe"`
   - PC 全体の `PATH` に `C:\Program Files\WezTerm` が 1 行と、スタートメニューの `True` が出る
   - 最後に `wezterm.exe`・`wezterm-gui.exe`・`unins000.exe` などのファイルの名前が並ぶ
   - 開いていた PowerShell の `PATH` には入らない。新しく開いた窓（WezTerm の中も）では、`wezterm` を名前で呼べる

1. スタートメニューから WezTerm を起動し、窓が開くことを確かめる。

   - スタートメニューで「WezTerm」を探し、クリックして開く
   - 窓が開き、中でシェルが動けばよい。設定ファイルが無ければ `cmd.exe` が開く（自分用の設定では Git Bash。[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 7 で入れる）
   - 窓の中で `wezterm --version` を打つと、この項の手順 5 と同じ版が出る
   - キー操作だけ動かない場合は、[ホットキーを使用しているアプリの調査](windows-setup.md#windows-のホットキー競合)で対象キーを調べる
   - 窓が開かずに終わったら、`%USERPROFILE%\.local\share\wezterm\wezterm-gui.exe-log-<番号>.txt` を見る
     - `The OpenGL implementation is too old to work with glium` なら、3D の描画の無い VM などで OpenGL が使えない
     - その場で開くなら、Win+R の「ファイル名を指定して実行」に `"C:\Program Files\WezTerm\wezterm-gui.exe" --config prefer_egl=true` を入れて開く（管理者の窓からは起動しない）
     - いつも開くようにするなら、設定の `config` に `config.prefer_egl = true` を足す。設定ファイルが無ければ、`%USERPROFILE%\.wezterm.lua` に `local wezterm = require 'wezterm'`・`local config = wezterm.config_builder()`・`config.prefer_egl = true`・`return config` の 4 行を書く
     - 自分用の設定（`~/.config/wezterm`）を使うなら、`~/.wezterm.lua` は作らない（[WezTerm の設定ファイル](#wezterm-の設定ファイル)のとおり、clone した設定が読まれなくなる）
   - **注意**: 管理者の PowerShell から `wezterm-gui.exe` を起動しない（WezTerm と中のシェルが管理者で動く）

---

### Git Bash と WezTerm の設定

- Git の共通設定・共通の bash 設定と、自分用の WezTerm の設定を入れる
- 前提: [Git for Windows](windows-setup.md#git-for-windows)・[WezTerm](#windows-11-で-wezterm-を入れる)を通してある。導入後に Windows を再起動するか、サインアウトしてサインインし直し、PATH を読み直してある。GitHub のアカウントがある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 3 からは Git Bash の窓、最後は WezTerm の Git Bash のタブ

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Git for Windows の git の場所と版と、Git Bash があることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Command git -All | Format-Table Source
   git --version
   Test-Path 'C:\Program Files\Git\bin\bash.exe', 'C:\Program Files\Git\git-bash.exe'
   ```

   - 1 行目の一番上に `C:\Program Files\Git\cmd\git.exe` が出ればよい
   - `git version 2.55.0.windows.5` の形の行と、`True` が 2 行出ればよい

1. スタートメニューから Git Bash を開く。

   - スタートメニューで「Git Bash」を探して開く（管理者でなくてよい）
   - `<WIN_USER>@<HOSTNAME> MINGW64 ~` のような行と、`$` のプロンプトの窓が開く
   - Git Bash の窓に貼るときは、窓の中を右クリックして出るメニューの「Paste」を選ぶ。最後の行は、貼った後に Enter を押す
   - **次の手順は、この Git Bash に貼る**

1. Git Bash に、[AlmaLinux 10 の初期設定の「Git」](almalinux-setup.md#git)の手順 1〜10 を上から順に貼る。

   - `~/.gitconfig`（`C:\Users\<WIN_USER>\.gitconfig`）に、AlmaLinux 10 と同じ基本の設定を書く。成功の条件は、同書のそれぞれの手順と同じ
   - 同書の「Git」の手順 2 では、インストーラが書いた `system` の行（`core.autocrlf=true` など）も出る
   - **この手順は、この項の手順 6・7 の clone より前に行う**（`global` の `core.autocrlf=false` が無いと、clone したファイルの改行が `system` の `core.autocrlf=true` で CRLF になる）
   - Git Bash・PowerShell・cmd の git は、同じ `~/.gitconfig` を読む
   - 戻すときは、[Git Bash の設定を戻す](extra/windows-setup.md#git-bash-の設定を戻す)で行う。共通設定に加え、この項の手順 5 で変更した Windows 専用 `core.longpaths` も記録に合わせて戻す

1. 同じ Git Bash で、元の設定を表示し、Git for Windows の長いパス対応を有効にする。

   ```bash
   printf '変更前の core.longpaths（スコープ・ファイル・値）:\n'
   git config --show-scope --show-origin --get-all core.longpaths
   if [ "$(git config --global --includes --type=bool --get core.longpaths)" != true ]; then
     git config --global core.longpaths true
   fi
   printf '\n\033[7m 確認 \033[0m\n'
   git config --global --includes --type=bool --get core.longpaths
   git config --type=bool --show-scope --show-origin --get core.longpaths
   ```

   - 「変更前」の値・スコープ・ファイルを控える。include 先も `global` の行に出る。`global` が無ければ「未設定」と控える
   - 最後の `global` の値が `true`（`yes`・`on`・`1` も同じ）なら「変更なし」、それ以外は今回変更したことも控える。変更しなかったキーは復元で触らない
   - 「確認」の後に `true` と、`global` の `true` の行が出ればよい。違う値やエラーが出たら、ここで止めて設定を確かめる
   - 対象のリポジトリで `git config --show-scope --show-origin --get core.longpaths` を確かめ、`local` の `false` が出たら、そのリポジトリの設定を見直す
   - **注意**: エクスプローラー・IDE・スクリプトなどで長いパスを扱えない場合は、リポジトリを短いパスに置く
   - 戻すときは、[ロールバックの「Git Bash の設定を戻す」](extra/windows-setup.md#git-bash-の設定を戻す)の手順 2・5・6 で行う

1. 同じ Git Bash で、共通の bash 設定を入れる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git clone https://github.com/ryo-aoki-pc/bash.git ~/.config/bash &&
     bash ~/.config/bash/install.sh
   ```

   - [README の「共通の bash 設定を先に入れる」](../README.md#共通の-bash-設定を先に入れる)と、[共通の bash 設定](#共通の-bash-設定)の手順 1 と同じブロック
   - `~/.bashrc: 設定済み（元の内容: ~/.bashrc.before-bash）` と `完了: 端末を開き直す。…` が出ればよい
   - すでに clone してあるなら `fatal: destination path … already exists` で止まる。そのときは `git -C ~/.config/bash pull --ff-only` で更新し、`bash ~/.config/bash/install.sh` を貼る
   - 自分用の WezTerm は Git Bash を `-i -l`（ログインシェル）で開き、ログイン用のファイル（ふつうは `~/.bash_profile`）→ `~/.bashrc` → 共通の bash 設定の順に読む。読み込みを確かめるときは、[Windows 11 で bash のログイン時の読み込みを確かめる](#windows-11-で-bash-のログイン時の読み込みを確かめる)を通す
   - Git for Windows が作る `~/.bash_profile` と、共通設定の導入時に既存ファイルを残す扱いは、[この手順の補足](reference/shell-terminal.md#git-bash-と-wezterm-の設定--手順-6-補足-ログインシェルの読み込み)で確かめる

1. 自分用の WezTerm の設定（[ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)）を入れ、WezTerm を起動し直す。

   - [WezTerm の設定を導入する](#windows-11-で-wezterm-の設定を導入する)を通す。前提の共通の bash 設定は、この項の手順 6 で導入済み
   - その項の手順 5 で WezTerm を起動し、同じ項の手順 6 を新しい Git Bash のタブに貼って確かめる
   - Git Bash の窓は閉じてよい
   - CRLF に変換して clone 済みのリポジトリは、WezTerm の Git Bash のタブで[改行を変換して clone したリポジトリを直す](almalinux-setup.md#改行を変換して-clone-したリポジトリを直す)を通す

#### Windows 11 で共通の bash 設定を更新する

- 共通の bash 設定のリポジトリを更新し、端末を開き直して反映する
- 前提: [Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある
- 実行場所: この PC のデスクトップの、自分のユーザーの WezTerm の Git Bash のタブ。この項の手順 1 で開く
- 手元の変更は `git -C ~/.config/bash status` で確認してから進む

1. スタートメニューから WezTerm を開き、Git Bash の新しいタブを用意する。

   - スタートメニューで「WezTerm」を探して開く（管理者として実行しない）。開いていれば Ctrl+Shift+T で新しいタブを開く
   - `MINGW64` と `$` のプロンプトが出ればよい
   - **次の手順は、この Git Bash のタブに貼る**

1. origin を HTTPS にそろえて、設定のリポジトリを pull する。

   ```bash
   git -C ~/.config/bash remote set-url origin https://github.com/ryo-aoki-pc/bash.git
   git -C ~/.config/bash pull --ff-only
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/bash log -1 --oneline
   ```

   - 新しいコミットが無ければ `Already up to date.` と出て、最後にいちばん新しいコミットが 1 行出る
   - `set-url` は、HTTPS で clone したホストでは何も変えない。SSH で clone したホストを HTTPS にそろえる
   - インターネットに出られないホストは、[SSH の SOCKS トンネル](almalinux-setup.md#ssh-の-socks-トンネル)を張ったシェルで貼る
   - 手元で変えたファイルがあって pull が止まったら、`git -C ~/.config/bash status` で見る
   - 開いている端末には効かない。端末を開き直す

#### Windows 11 で共通の bash 設定を手動で移行する

- 通常の共通 bash 設定の導入が中断したときに、設定を手動で移行する
- 前提: [Git for Windows](windows-setup.md#git-for-windows)を通してある
- 実行場所: この PC のデスクトップの、自分のユーザーの Git Bash の窓
- [AlmaLinux 10 の共通の bash 設定を手動で移行する](#共通の-bash-設定を手動で移行する)の全手順を Git Bash で行う。WSL は WSL 側で別に行う

#### Windows 11 で WezTerm の設定を導入する

- 自分用の WezTerm の設定を入れ、シェル統合を確かめる
- 前提: [WezTerm](#windows-11-で-wezterm-を入れる)と[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 1〜6 を通し、Git と共通の bash 設定を入れてある。HackGen Console NF は任意
- 実行場所: この項の手順 1〜5 は、WezTerm の外の、自分のユーザーの Git Bash の窓。この項の手順 6・7 は、起動し直した WezTerm の Git Bash のタブ
- この項の手順 1 で WezTerm の窓をすべて閉じる。既存設定の確認と、この項の手順 3 の退避を省かない
- [背景説明](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/reference/install.md)・[検証記録](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/verification/install.md)

1. WezTerm の窓をすべて閉じ、スタートメニューから Git Bash を開く。

   - スタートメニューで「Git Bash」を探して開く（管理者として実行しない）
   - `MINGW64` と `$` のプロンプトが出ればよい
   - **次の手順は、この Git Bash の窓に貼る**

1. 既存の WezTerm の設定があるか確かめる。

   ```bash
   ls -ld ~/.wezterm.lua ~/.config/wezterm
   ```

   - どちらかが出たら、この項の手順 3 で退避する
   - 2 行とも `No such file or directory` なら、設定は無い。この項の手順 3 は飛ばす
   - `~/.wezterm.lua` が残っていると、この設定は読まれない

1. 既存の設定があるときだけ、名前の後ろに `.bak` を付けて退避する。

   ```bash
   (
     for f in ~/.wezterm.lua ~/.config/wezterm; do
       if [ -e "$f.bak" ] || [ -L "$f.bak" ]; then
         echo "中断: $f.bak が既にある。何も退避していない" >&2
         exit 1
       fi
     done
     for f in ~/.wezterm.lua ~/.config/wezterm; do
       if [ -e "$f" ] || [ -L "$f" ]; then mv -v "$f" "$f.bak" || exit 1; fi
     done
     ls -ld ~/.wezterm.lua ~/.config/wezterm
   )
   ```

   - あったものだけ、`renamed '/home/<USER>/.config/wezterm' -> '/home/<USER>/.config/wezterm.bak'` のように出る
   - 最後の `ls` が 2 行とも `No such file or directory` ならよい
   - `.bak` が 1 つでもあれば、どちらも動かさず `中断:` で止まる。この項の手順 4 へ進まず、中身を確かめて片付けてからこの項の手順 3 を貼り直す
   - 退避したものは、[WezTerm 設定のロールバック](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/extra/install.md#ロールバック)の手順 4 で戻せる

1. この設定を `~/.config/wezterm` に clone する。

   ```bash
   git clone https://github.com/ryo-aoki-pc/wezterm.git ~/.config/wezterm
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/wezterm log -1 --oneline
   ```

   - `Cloning into '/home/<USER>/.config/wezterm'...` の後に、最新のコミットが 1 行出る
   - `fatal: destination path '/home/<USER>/.config/wezterm' already exists and is not an empty directory.` と出たら、この項の手順 2 から見直す

1. WezTerm がこの設定を読めるか確かめる。

   ```bash
   wezterm ls-fonts --text 'aあ'
   ```

   - `ERROR  wezterm_gui >` が無ければ設定を読めている。終了コードは誤りがあっても `0` なので使わない
   - `show-keys` は読み込み確認に使わず、`| head` も付けない
   - HackGen Console NF があればそのフォントで描く。無ければフォント警告が出て代替フォントを使う。画面なしでは通知の dbus エラーが出る場合もある
   - Windows でコマンドが無ければ `"/c/Program Files/WezTerm/wezterm.exe" ls-fonts --text 'aあ'` を使う

1. WezTerm のウィンドウをすべて閉じてから、起動し直す。

   - WezTerm を開いていなければ、起動するだけでよい
   - AlmaLinux 10 はアプリ一覧の「WezTerm」から、Windows 11 はスタートメニューの「WezTerm」から起動する
   - シェル統合とウィンドウ装飾は起動し直して反映する
   - **次の手順は、起動し直した WezTerm のタブで貼る**（開いていたタブで貼ると、この項の手順 7 の確かめが外れる）

1. 起動し直した WezTerm のタブで、シェル統合が読まれたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   echo "$TERM_PROGRAM"
   echo "$WEZTERM_SHELL_INTEGRATION"
   declare -F __wezterm_set_user_var __wezterm_notify_done __wz_mouse_off
   ```

   - 1 行目は `WezTerm`、2 行目は `.config/wezterm/shell/wezterm.sh` で終わるパス
   - 3 つ目は、WezTerm のパッケージの公式のシェル統合があるかどうかで変わる
     - AlmaLinux 10（COPR の公式統合）: `__wezterm_set_user_var`・`__wezterm_notify_done`・`__wz_mouse_off` の 3 行
     - 公式の統合が無いとき（Windows の Git Bash など）: `__wezterm_notify_done` と `__wz_mouse_off` の 2 行
   - 1 行目が空なら、WezTerm の外で貼っている。2 行目が空なら、この項の手順 6 の前から開いていたタブで貼っている
   - `__wz_mouse_off` が出なければ、`~/.bashrc` の行が読まれていない。共通の bash 設定を見直す

#### WezTerm のシェル統合を WSL で使う

- WSL の bash で Windows 側の WezTerm のシェル統合を読む
- 前提: [WezTerm の設定を導入する](#windows-11-で-wezterm-の設定を導入する)・[WSL の AlmaLinux 10 と自動サインイン](windows-setup.md#wsl-の-almalinux-10-と自動サインイン)と、WSL 側の[共通の bash 設定](#共通の-bash-設定)を通してある
- 実行場所: この PC のデスクトップの WezTerm の WSL の bash のタブ。この項の手順 1 で開く
- WSL の `~/.bashrc` の既存の変更を確かめ、Windows 側の統合を共通の bash 設定の読み込み行より後ろで読む

1. スタートメニューから WezTerm を開き、WSL のタブを用意する。

   - WezTerm の Ctrl+Shift+M の起動メニューで「AlmaLinux-10」を選ぶ
   - WSL の自分のユーザーの bash のプロンプトが出ればよい
   - **次の手順は、この WSL のタブに貼る**

1. WSL のシェルで、Windows のホームを調べ、シェル統合のスクリプトが見えるか確かめる。

   ```bash
   WIN_HOME=$(wslpath "$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' | tr -d '\r')")
   printf '\n\033[7m 確認 \033[0m\n'
   ls -l "$WIN_HOME/.config/wezterm/shell/wezterm.sh"
   ```

   - `/mnt/c/Users/<WIN_USER>/.config/wezterm/shell/wezterm.sh` の 1 行が出ればよい
   - `No such file or directory` なら、Windows 側の[WezTerm 設定の導入](#windows-11-で-wezterm-の設定を導入する)を先に済ませる

1. この項の手順 2 と同じシェルで、WSL の `~/.bashrc` に読み込む行を足す。

   ```bash
   if [ -z "${WIN_HOME}" ]; then echo '中断: この項の手順 2 の WIN_HOME が空のまま' >&2; else
     echo "[ -r '$WIN_HOME/.config/wezterm/shell/wezterm.sh' ] && . '$WIN_HOME/.config/wezterm/shell/wezterm.sh'" >> ~/.bashrc
     printf '\n\033[7m 確認 \033[0m\n'
     tail -1 ~/.bashrc
   fi
   ```

   - `/mnt/c/Users/<WIN_USER>/.config/wezterm/shell/wezterm.sh` を 2 回含む 1 行が出る
   - WSL の `$HOME` は Linux 側なので、Windows 側の統合をこのパスで読む

1. WezTerm の起動メニューから、WSL のタブを開き直す。

   - `Ctrl+Shift+M` の起動メニューで、WSL のディストリビューションを選ぶ
   - **次の手順は、開き直した WSL のタブで貼る**

1. 開き直した WSL のタブで、シェル統合が読まれたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   echo "$TERM_PROGRAM"
   declare -F __wezterm_set_user_var __wezterm_notify_done __wz_mouse_off
   ```

   - `TERM_PROGRAM` が `WezTerm`、`__wezterm_notify_done` と `__wz_mouse_off` が出ればよい。WSL に COPR の公式統合があれば `__wezterm_set_user_var` も出る

#### Windows 11 で WezTerm の設定を更新する

- WezTerm の設定のリポジトリを更新する
- 前提: [Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある
- 実行場所: この PC のデスクトップの、自分のユーザーの WezTerm の Git Bash のタブ。この項の手順 1 で開く
- 手元の変更は `git -C ~/.config/wezterm status` で確認してから進む
- WezTerm 本体は[Git for Windows・Firefox・WezTerm を上げる](windows-setup.md#git-for-windowsfirefoxwezterm-を上げる)で更新する

1. スタートメニューから WezTerm を開き、Git Bash の新しいタブを用意する。

   - スタートメニューで「WezTerm」を探して開く（管理者として実行しない）。開いていれば Ctrl+Shift+T で新しいタブを開く
   - `MINGW64` と `$` のプロンプトが出ればよい
   - **次の手順は、この Git Bash のタブに貼る**

1. 設定のリポジトリを pull する。

   ```bash
   git -C ~/.config/wezterm pull
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/wezterm log -1 --oneline
   ```

   - 新しいコミットが無ければ、`Already up to date.` と出る
   - 起動中の WezTerm は、ファイルが変わると設定を読み直す（効かなければ `Ctrl+Shift+R`）
   - シェル統合（`shell/`）とウィンドウの装飾の変更は、WezTerm を起動し直すまで効かない
   - 手元で変えたファイルがあって pull が止まったら、`git -C ~/.config/wezterm status` で見る

#### Windows 11 で bash のログイン時の読み込みを確かめる

- 任意で、Git Bash のログインシェルが読むファイルが `~/.bashrc` を読むことを確かめ、読む行が無いときだけ足す
- 前提: [Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある
- 実行場所: この PC のデスクトップの、自分のユーザーの WezTerm の Git Bash のタブ。この項の手順 1 で開く
- 自分用の WezTerm の設定は Git Bash を `-i -l`（ログインシェル）で開く。bash は `~/.bash_profile`・`~/.bash_login`・`~/.profile` のうち最初にあるものだけを読み、そこから `~/.bashrc` → 共通の bash 設定を読む（[補足](reference/shell-terminal.md#git-bash-と-wezterm-の設定--手順-6-補足-ログインシェルの読み込み)）
- この項では、ログイン用のファイルを新しく作らない

1. スタートメニューから WezTerm を開き、Git Bash の新しいタブを用意する。

   - スタートメニューで「WezTerm」を探して開く（管理者として実行しない）。開いていれば Ctrl+Shift+T で新しいタブを開く
   - タブの起動メニューで Git Bash を選ぶ（自分用の設定では既定で開く）
   - **次の手順は、この Git Bash のタブに貼る**

1. ログインシェルが読むファイルの名前と構文と、`~/.bashrc` を読む行を確かめる。

   ```bash
   (
     f=
     for x in ~/.bash_profile ~/.bash_login ~/.profile; do
       if [ -f "$x" ]; then f=$x; break; fi
     done
     printf '\n\033[7m 確認 \033[0m\n'
     if [ -z "$f" ]; then echo '中断: ~/.bash_profile・~/.bash_login・~/.profile のどれも無い' >&2; exit 1; fi
     echo "$f"
     bash -n "$f" && grep -n '\.bashrc' "$f"
   )
   ```

   - 1 行目にファイルの名前（ふつうは `/c/Users/<WIN_USER>/.bash_profile`）が出て、構文エラーが無く、コメントでない `test -f ~/.bashrc && . ~/.bashrc` などの読む行が出ればよい。この項の手順 3 は飛ばす
   - 読む行が無いときだけ、この項の手順 3 を行う
   - `中断:` が出たら、[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 6 のブロックを貼り直す（共通の bash 設定の `install.sh` が、`~/.bashrc` を読む `~/.bash_profile` を作る）。構文エラーが出たら、この項の手順 3 へ進まない

1. この項の手順 2 で読む行が無かったときだけ、そのファイルの末尾に 1 行足す。

   ```bash
   (
     f=
     for x in ~/.bash_profile ~/.bash_login ~/.profile; do
       if [ -f "$x" ]; then f=$x; break; fi
     done
     if [ -z "$f" ]; then echo '中断: ~/.bash_profile・~/.bash_login・~/.profile のどれも無い。ファイルは作らない' >&2; exit 1; fi
     bash -n "$f" || exit 1
     line='test -f ~/.bashrc && . ~/.bashrc  # shell-terminal.md'
     if ! grep -Fqx "$line" "$f"; then
       if [ -s "$f" ] && [ -n "$(tail -c 1 "$f")" ]; then printf '\n' >> "$f" || exit 1; fi
       printf '%s\n' "$line" >> "$f" || exit 1
     fi
     printf '\n\033[7m 確認 \033[0m\n'
     echo "$f"
     grep -Fnx "$line" "$f"
   )
   ```

   - ファイルの名前と、`test -f ~/.bashrc && . ~/.bashrc  # shell-terminal.md` の行が 1 つ出ればよい。ファイルは置き換えず、同じ行は増やさない
   - 足したのが `~/.profile` なら、その行は sh のログインシェルにも読まれる（共通の bash 設定は bash 向け）。Git Bash のほかに sh でログインしないなら問題にならない
   - 新しい Git Bash のタブを開き、[WezTerm の設定を導入する](#windows-11-で-wezterm-の設定を導入する)の手順 7 で読み込みを確かめる

1. 元に戻すときは、この項の手順 3 で足した印の行だけを消す。

   ```bash
   for f in ~/.bash_profile ~/.bash_login ~/.profile; do
     if [ -f "$f" ]; then sed -i '/^test -f ~\/\.bashrc && \. ~\/\.bashrc  # shell-terminal\.md$/d' "$f"; fi
   done
   printf '\n\033[7m 確認 \033[0m\n'
   grep -n '  # shell-terminal\.md$' ~/.bash_profile ~/.bash_login ~/.profile 2>/dev/null
   ```

   - 「確認」の後に何も出なければよい。Git for Windows や共通の bash 設定が作った、印の無い行は残る
   - 次に開く Git Bash のタブから、残した行だけを読む

---

### シェルのツールを入れる

- scoop で fzf・zoxide・starship・eza・bat を入れ、Git Bash で確かめる
- 前提: [アプリを入れる](windows-setup.md#アプリを入れる)の手順 2・3 と[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通し、scoop と Git・共通の bash 設定を入れてある。Visual C++ ランタイムも[WezTerm](#windows-11-で-wezterm-を入れる)で入れてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 7・8 は WezTerm の新しい Git Bash のタブ

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. 管理者ではないことと、前提と、ほかの方法で入れた同じツールが無いかを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     BashConfig = Test-Path -LiteralPath "$env:USERPROFILE\.config\bash\bashrc"
     VCRuntime  = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
     Tools      = (Get-Command fzf, zoxide, starship, eza, bat -All -ErrorAction SilentlyContinue).Source -join ', '
     Zoxide     = if (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue) { zoxide --version } else { '' }
   } | Format-List
   ```

   - `PowerShell : 5.1.…`・`Admin : False`・`BashConfig : True`・`VCRuntime : True` ならよい。`Admin : True` なら、窓を閉じて、この項の手順 1 のとおりに開き直す
   - `Scoop` が空なら、先に[アプリを入れる](windows-setup.md#アプリを入れる)の手順 2・3 を通す
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [Git for Windows](windows-setup.md#git-for-windows)を通す
   - `BashConfig : False` なら、先に[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 6 を通す
   - `VCRuntime : False` なら、[WezTerm](#windows-11-で-wezterm-を入れる)の手順 3 を管理者の窓で行ってから、このブロックを貼り直す
   - `C:\Users\<WIN_USER>\scoop\` の下の `shims\<名前>.exe` と `apps\starship\current\starship.exe` だけなら、scoop で入れたもの（この項の手順 4 は、入っているものを飛ばす）
   - ほかの場所（winget の `…\WinGet\Links\` など）が出たら、ほかの方法で入れたものがある。その方法で外してから始める
   - `Zoxide` が空か `zoxide 0.9.9` なら、この項の手順 3 は飛ばす

1. scoop の zoxide が 0.9.9 でないときだけ、外す。

   ```powershell
   scoop uninstall zoxide
   ```

   - `'zoxide' was uninstalled.` が出ればよい

1. scoop を上げてから 5 つを入れ、zoxide を 0.9.9 に止める。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop update
   scoop install fzf starship eza bat
   scoop install zoxide@0.9.9
   scoop hold zoxide
   ```

   - `scoop update` は `Scoop was updated successfully!` を出す（Git for Windows より前に scoop を入れた PC では、初めてのときに `Converting 'main' bucket to git repo...` も出る）
   - それぞれ `'<名前>' (<版>) was installed successfully!` の形の行が出て、最後に `zoxide is now held and can not be updated anymore.` が出ればよい（zoxide は `0.9.9`）
   - zoxide の 0.9.9 は、scoop が main のバケットの git の履歴から定義を取り出して入れる（`Resolving historical manifest for 'zoxide' (0.9.9)` の行が出る）
   - 2 行目は、もう入っているものを、何も出さずに飛ばす
   - zoxide の 0.9.9 がもう入っていれば、3 行目は `'zoxide' (0.9.9) is already installed.` の警告だけを出す
   - もう止めてあれば、`'zoxide' is already held.` が出る
   - starship は shim を作らず、`Adding ~\scoop\apps\starship\current to your path.` で自分のユーザーの `Path` に足す（この窓にも入る）
   - bat は `Setting user environment variable: BAT_CONFIG_DIR = …` で環境変数を足す（この窓にも入る）
   - `Notes` の starship のプロファイル追記と、`suggests installing` の VC++ ランタイム・less の導入は行わない
   - **zoxide は 0.9.9 に固定する**。0.10.0 は Git Bash の移動を記録しない。修正版は[更新](windows-setup.md#scoopwingetwsl-を上げる)の手順 7・8、ほかのツールは同じ項の手順 2・3 で上げる

1. 版と場所と、zoxide を止めたことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   fzf --version
   zoxide --version
   starship --version
   eza --version
   bat --version
   (Get-Command fzf, zoxide, starship, eza, bat -All).Source
   scoop list zoxide
   ```

   - それぞれの版が出ればよい（`zoxide 0.9.9`・`starship 1.26.0`・`v0.23.5 [+git]`・`bat 0.26.1` の形）
   - `bat --version` が何も出さないか、DLL が見つからない旨のエラーになったら、VC++ ランタイムが無い（この項の手順 2 の `VCRuntime`）
   - 場所は、`C:\Users\<WIN_USER>\scoop\shims\` の下の `fzf.exe`・`zoxide.exe`・`eza.exe`・`bat.exe` と、`C:\Users\<WIN_USER>\scoop\apps\starship\current\starship.exe` の 5 行だけ
   - `scoop list` の `zoxide` の行は、`Version` が `0.9.9`、`Source` が `<auto-generated>`（前から main のバケットで入れた 0.9.9 なら `main`）、`Info` が `Held package`

1. bat の設定ファイル（`BAT_CONFIG_DIR` の下の `config`）に、3 行の設定を書く（中身があれば書き換えない）。

   ```powershell
   $BAT_THEME_NAME = 'ansi'   # 使うテーマ。ansi は端末の 16 色にそのまま従う（一覧は bat --list-themes）。<BAT_THEME_NAME>
   ```

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not $BAT_THEME_NAME) { Write-Error '中断: BAT_THEME_NAME が空のまま。値を入れて貼り直す'; return }
     $f = if ($env:BAT_CONFIG_PATH) { $env:BAT_CONFIG_PATH } elseif ($env:BAT_CONFIG_DIR) { Join-Path $env:BAT_CONFIG_DIR 'config' } else { '' }
     if (-not $f) { Write-Error '中断: BAT_CONFIG_DIR が無い。この項の手順 4 で bat を入れたかを確かめる'; return }
     if ((Test-Path -LiteralPath $f) -and [IO.File]::ReadAllText($f).Trim()) { "中身がある（書き換えない）: $f" } else {
       Set-Content -LiteralPath $f -Encoding ASCII -Value "--theme=`"$BAT_THEME_NAME`"", '--style="numbers,changes,header"', '--paging=never' -ErrorAction Stop
       "書いた: $f"
     }
     Get-Content -LiteralPath $f
   }
   ```

   - `書いた: C:\Users\<WIN_USER>\scoop\apps\bat\current\config` と、`--theme="ansi"`・`--style="numbers,changes,header"`・`--paging=never` の 3 行が出ればよい
   - 書いた中身は、scoop の控え（`~\scoop\persist\bat\config`）に残り、bat を上げても消えない
   - `中身がある（書き換えない）:` が出たら、前からの設定（`%APPDATA%\bat\config` から scoop が写したものなど）がある。何も変えていない
   - `中断:` が出たら、何も書いていない

1. WezTerm の新しいタブ（Git Bash）で、[シェルのツール](#シェルのツール)の手順 4〜7・9・10 のブロックを貼る。

   - WezTerm を起動するか、新しいタブ（Ctrl+Shift+T）を開く。前から開いているタブで `. ~/.bashrc` を読み直さない（[シェルのツール](#シェルのツール)の手順 2 の補足と同じ）
   - 新しいタブのプロンプトが starship の形にならなければ、WezTerm の窓をすべて閉じて起動し直す
   - 成功の条件は、「シェルのツール」のそれぞれの手順と同じ。違うのは次のところ
     - `command -v` は `/c/Users/<WIN_USER>/scoop/shims/<名前>`（starship は `/c/Users/<WIN_USER>/scoop/apps/starship/current/starship`）。版は、この項の手順 5 と同じ
     - 「シェルのツール」の手順 5 の `bind -X` は、`"\C-r" "__fzf_history__"` のようにコロンの無い形で出る（Git Bash の bash 5.3）。WezTerm のシェル統合を読んでいれば、マウス報告よけの行も出る（そのままでよい）
     - 「シェルのツール」の手順 6 の見出しは、`Permissions` が `Mode` になり、`User` の列が無い。`Git` の列が出ればよい。`ll` は、Git for Windows の `ls -l` ではなく eza になる
     - 「シェルのツール」の手順 7 で `/etc/os-release` が無い旨のエラーが出たら、そのコマンドを `~/.bashrc` に変えて打つ。`MANPAGER` は `bat -plman` と出るが、Git Bash に `man` は無い
     - 「シェルのツール」の手順 9 の `cd /usr/share` は、Git for Windows の `C:\Program Files\Git\usr\share` に移る。「シェルのツール」の手順 10 の一覧には、その形（`C:\…`）で出る
   - 「シェルのツール」の手順 8（tmux）は行わない
   - `~/.bashrc` には追記しない。Windows PowerShell 5.1 には読み込まない

1. 同じタブで、[キー操作を試す](#キー操作を試す)の手順 2〜5 のキーを押して、fzf を確かめる。

   - 「キー操作を試す」の手順 2 の `fzf --version` は、この項の手順 7 で Git Bash の履歴に入っている
   - 「キー操作を試す」の手順 3 をホーム（`C:\Users\<WIN_USER>`）で行うと、`AppData` の下のファイルも一覧に入る
   - 「キー操作を試す」の手順 4 の `doc/bash` が一覧に無ければ、一覧にある別の語で絞る（`/usr/share` は Git for Windows のもの）
   - 日本語など ASCII 以外の文字では、絞り込めないことがある（Windows の fzf は、画面の一部に開いた一覧では ASCII 以外の文字を読めない）
   - [fzf で fd と bat を候補とプレビューに使う](#fzf-で-fd-と-bat-を候補とプレビューに使う)も通せる。そちらの `brew install fd`・`brew uninstall fd` は、通常の PowerShell で `scoop install fd`・`scoop uninstall fd` にする。導入済みなら省く
   - bat の設定にはこの項の手順 6を使う

#### Windows 11 で starship の表示を変える

- 任意で、starship のプロンプト前の空行を省き、ディレクトリを 3 階層まで、ユーザー名とホスト名を常に表示する
- 前提: [シェルのツールを入れる](#シェルのツールを入れる)を通してある
- 実行場所: この PC のデスクトップの、自分のユーザーの WezTerm の Git Bash のタブ。この項の手順 1 で開く
- `%USERPROFILE%\.config\starship.toml`（Git Bash の `~/.config/starship.toml`）は、Git Bash と PowerShell 7 で共有する。PowerShell 7 は、[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 2 の starship の行で読む
- 控えは `~/.config/starship.toml.shell-terminal.bak`。ファイルが無ければ、`~/.config/starship.toml.shell-terminal.new` に新規作成の印を残す。既存の控えと印は上書きしない（[補足](reference/shell-terminal.md#windows-11-で-starship-の表示を変える--手順-2-補足-git-bash-と-powershell-7-が読む場所)）

> [!WARNING]
> この項の手順 2 は `starship.toml` の中身全体を、この項の 5 つの値に置き換える。既存のほかの設定は控えに残る。Git Bash と PowerShell 7 の両方のプロンプトに効き、ユーザー名・ホスト名が常に出るので画面の共有に注意する。

1. スタートメニューから WezTerm を開き、Git Bash の新しいタブを用意する。

   - スタートメニューで「WezTerm」を探して開く（管理者として実行しない）。開いていれば Ctrl+Shift+T で新しいタブを開く
   - タブの起動メニューで Git Bash を選ぶ（自分用の設定では既定で開く）
   - **次の手順は、この Git Bash のタブに貼る**

1. 既存ファイルがあれば控えを取り、Windows で共有する starship の設定を書く。

   ```bash
   (
     if [ -n "${STARSHIP_CONFIG:-}" ]; then echo '中断: STARSHIP_CONFIG がある。標準の設定ファイルを使う状態にしてから始める' >&2; exit 1; fi
     mkdir -p ~/.config || exit 1
     for f in ~/.config/starship.toml ~/.config/starship.toml.shell-terminal.bak ~/.config/starship.toml.shell-terminal.new; do
       if [ -L "$f" ] || { [ -e "$f" ] && [ ! -f "$f" ]; }; then echo "中断: 通常のファイルではない: $f" >&2; exit 1; fi
     done
     if [ -e ~/.config/starship.toml.shell-terminal.bak ] && [ -e ~/.config/starship.toml.shell-terminal.new ]; then echo '中断: 控えと新規作成の印が両方ある' >&2; exit 1; fi
     if [ ! -e ~/.config/starship.toml.shell-terminal.bak ] && [ ! -e ~/.config/starship.toml.shell-terminal.new ]; then
       if [ -e ~/.config/starship.toml ]; then
         cp -p ~/.config/starship.toml ~/.config/starship.toml.shell-terminal.bak || exit 1
       else
         touch ~/.config/starship.toml.shell-terminal.new || exit 1
       fi
     fi
     cat > ~/.config/starship.toml <<'EOF'
   add_newline = false

   [directory]
   truncation_length = 3
   truncate_to_repo = false

   [username]
   show_always = true

   [hostname]
   ssh_only = false
   EOF
     if [ "$?" -ne 0 ]; then echo '中断: 書き込めない。控えは残してある' >&2; exit 1; fi
     printf '\n\033[7m 確認 \033[0m\n'
     cat ~/.config/starship.toml
   )
   ```

   - `add_newline = false`・`truncation_length = 3`・`truncate_to_repo = false`・`show_always = true`・`ssh_only = false` が出ればよい
   - `中断:` やエラーが出たら、この項の手順 3 へ進まない
   - 再実行しても控えは最初のまま。設定ファイルは、この項の 5 つの値で書き直す

1. WezTerm で、Git Bash の新しいタブを開く。

   - Ctrl+Shift+T で開く。開いているタブで `. ~/.bashrc` を読み直さない
   - **次の手順は、新しく開いた Git Bash のタブに貼る**

1. 新しい Git Bash のタブで、設定とプロンプトを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   cat ~/.config/starship.toml
   starship prompt
   ```

   - この項の手順 2 の 5 つの値と、ユーザー名・ホスト名を含むプロンプトが出ればよい
   - PowerShell 7 のプロファイルを設定済みなら、新しい PowerShell 7 を開くと同じ表示設定になる
   - PowerShell 7 だけ違う表示なら、`STARSHIP_CONFIG` の環境変数などで別の設定ファイルを指定していないか確かめる

1. 元に戻すときは、控えを書き戻すか、この項で新しく作った設定ファイルを消す。

   ```bash
   (
     if [ -L ~/.config/starship.toml ] || [ -L ~/.config/starship.toml.shell-terminal.bak ] || [ -L ~/.config/starship.toml.shell-terminal.new ]; then echo '中断: シンボリックリンクがある' >&2; exit 1; fi
     if [ -e ~/.config/starship.toml.shell-terminal.bak ] && [ -e ~/.config/starship.toml.shell-terminal.new ]; then echo '中断: 控えと新規作成の印が両方ある' >&2; exit 1; fi
     if [ -f ~/.config/starship.toml.shell-terminal.bak ]; then
       cp -p ~/.config/starship.toml.shell-terminal.bak ~/.config/starship.toml &&
         rm ~/.config/starship.toml.shell-terminal.bak || exit 1
       printf '\n\033[7m 確認 \033[0m\n'
       echo '控えを書き戻した'
     elif [ -f ~/.config/starship.toml.shell-terminal.new ]; then
       rm -f ~/.config/starship.toml && rm ~/.config/starship.toml.shell-terminal.new || exit 1
       printf '\n\033[7m 確認 \033[0m\n'
       echo '作った設定ファイルを消した'
     else
       echo '中断: 控えも新規作成の印も無い。推測で戻さない' >&2
       exit 1
     fi
   )
   ```

   - `控えを書き戻した` か `作った設定ファイルを消した` が出ればよい
   - この項の手順 2 の後で変えた設定も戻る。残す変更があれば、書き戻す前に別に控える
   - Git Bash の新しいタブを開き直す。PowerShell 7 でも、次の窓から戻した設定を読む

---

### PowerShell 7 のプロファイルを設定する

- PowerShell 7 に貼り付け・↑/↓ の履歴検索と、導入済みの zoxide・starship を読む設定を足す
- 前提: [貼り付けの設定](windows-setup.md#貼り付けの設定)の手順 1〜5 と[アプリを入れる](windows-setup.md#アプリを入れる)の手順 6 を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 6 は PowerShell 7 の窓
- 対象は `Documents\PowerShell\Microsoft.PowerShell_profile.ps1`。Windows PowerShell 5.1 のプロファイルとは別
- 足す行は ASCII の文字だけで、行末に印 `# windows-setup.md` を付ける
- zoxide と starship は、入れていなければ読まない。入れた後に PowerShell 7 を開き直せば読む
- Windows Terminal の既定のプロファイルは Windows PowerShell のまま変えない
- 戻すときは、この項の手順 7・8（行った手順のものだけ）

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. PowerShell 7 のプロファイルに、貼り付けと履歴の検索のキーと、zoxide・starship を読む行を足す。

   ```powershell
   & {
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     $lines = @(
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine }  # windows-setup.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward }  # windows-setup.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward }  # windows-setup.md'
       'if (Get-Command -Name zoxide -CommandType Application -ErrorAction Ignore) { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }  # windows-setup.md'
       'if (Get-Command -Name starship -CommandType Application -ErrorAction Ignore) { function global:Invoke-Starship-PreCommand { if (Test-Path -Path Function:\__zoxide_hook) { $null = __zoxide_hook } }; Invoke-Expression (& starship init powershell) }  # windows-setup.md'
     )
     if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType File -Path $p -Force -ErrorAction Stop | Out-Null }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($line in $lines) {
       $text = Get-Content -LiteralPath $p -Raw
       if ($text -and $text.Contains($line)) { "すでにある: $line" } else {
         $add = $line
         if ($text -and -not $text.EndsWith("`n")) { $add = "`r`n" + $line }
         Add-Content -LiteralPath $p -Value $add -ErrorAction Stop
         "足した: $line"
       }
     }
     "--- $p"
     Get-Content -LiteralPath $p
   }
   ```

   - 5 行それぞれに `足した:` か `すでにある:` が出て、最後にプロファイルの中身が出ればよい
   - プロファイルは `C:\Users\<WIN_USER>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`（OneDrive でドキュメントをバックアップしていると、`OneDrive` の下）
   - 何度貼ってもよい
   - 開いている PowerShell 7 の窓には、開き直すまで効かない

1. Tab で補完の候補の一覧を出すときだけ、Tab の行を足す。

   ```powershell
   & {
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     $line = 'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete }  # windows-setup.md'
     if (-not (Test-Path -LiteralPath $p)) { Write-Error "中断: プロファイルが無い。この項の手順 2 を先に貼る: $p"; return }
     $text = Get-Content -LiteralPath $p -Raw
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($text -and $text.Contains($line)) { "すでにある: $line" } else {
       $add = $line
       if ($text -and -not $text.EndsWith("`n")) { $add = "`r`n" + $line }
       Add-Content -LiteralPath $p -Value $add -ErrorAction Stop
       "足した: $line"
     }
   }
   ```

   - `足した:` か `すでにある:` が出ればよい
   - Tab で、候補が一覧で出る（矢印で選んで Enter、Esc で取り消す）

1. PowerShell 7 で、実行ポリシーとキーの割り当てを確かめる。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Get-ExecutionPolicy -List | Out-String -Width 120; Import-Module PSReadLine; . $PROFILE; Get-PSReadLineKeyHandler -Bound | Where-Object Key -in 'Ctrl+Enter', 'UpArrow', 'DownArrow', 'Tab' | Format-Table Key, Function -AutoSize | Out-String -Width 120 }
   ```

   - 次のとおりならよい
     - 実行ポリシーの表の `LocalMachine` か `CurrentUser` が `RemoteSigned`
     - キーの表の `Ctrl+Enter` が `AddLine`、`UpArrow` が `HistorySearchBackward`、`DownArrow` が `HistorySearchForward`（この項の手順 3 を行ったなら、`Tab` が `MenuComplete`）
   - `pwsh.exe` が見つからない旨が出たら、[アプリを入れる](windows-setup.md#アプリを入れる)の手順 6 を確かめる
   - 実行ポリシーがどれも `Undefined` なら、プロファイルは読まれず、キーは既定のまま（`Ctrl+Enter` が `InsertLineAbove`）。そうでなければ、この項の手順 5 は飛ばす

1. 実行ポリシーがどれも `Undefined` のときだけ、PowerShell 7 の CurrentUser を RemoteSigned にする。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Get-ExecutionPolicy -List }
   ```

   - 表の `CurrentUser` が `RemoteSigned` になればよい
   - この項の手順 4 をもう一度貼って、キーの割り当てを確かめる

1. スタートメニューから PowerShell 7 を開き、キーとプロンプトを確かめる。

   - スタートメニューで「PowerShell」を探し、「Windows PowerShell」ではない「PowerShell」（PowerShell 7）をクリックして開く（一覧の名前に 7 は付かないことがある）
   - 何か打ってから ↑ を押すと、打った文字で始まる履歴だけが出る
   - 打っている途中に、履歴からの候補が薄い文字で出る（PowerShell 7 の既定の予測。→ で受け入れ、F2 で一覧の表示に切り替わる）
   - starship を入れていればプロンプトが starship の形になり、zoxide を入れていれば `z` が使える
   - Ctrl+Alt+? で、キーの割り当ての一覧が出る
   - **次の手順は、PowerShell 7 の窓を `exit` で閉じてから、この項の手順 1 の窓に貼る**

1. 元に戻すときは、PowerShell 7 のプロファイルから、この項と Emacs モードの項の印の行を消す。

   ```powershell
   & {
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     if (-not (Test-Path -LiteralPath $p)) { "プロファイルが無い: $p"; return }
     $bytes = [System.IO.File]::ReadAllBytes($p)
     $enc = if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { [System.Text.Encoding]::Unicode } else { [System.Text.Encoding]::GetEncoding(28591) }
     $text = $enc.GetString($bytes)
     $rest = [regex]::Replace($text, '(?m)^(\uFEFF|\u00EF\u00BB\u00BF)?[^\r\n]*  # (windows-setup|shell-terminal)\.md\r?(\n|$)', '$1')
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($rest -eq $text) { "その行は無い: $p" } elseif ($rest -match '^(\uFEFF|\u00EF\u00BB\u00BF)?\s*$') { Remove-Item -LiteralPath $p; "消した: $p" } else { [System.IO.File]::WriteAllBytes($p, $enc.GetBytes($rest)); "その行だけ消した: $p" }
   }
   ```

   - プロファイルにほかの行が無ければ `消した:`、あれば `その行だけ消した:` が出る
   - 開いている PowerShell 7 の窓には、閉じるまで設定が残る

1. 元に戻すときは（この項の手順 5 を行ったとき）、PowerShell 7 の CurrentUser の実行ポリシーを戻す。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser -Force; Get-ExecutionPolicy -List }
   ```

   - 表の `CurrentUser` が `Undefined` ならよい

#### PowerShell 7 で Emacs モードを使う

- 任意で、PowerShell 7 のキー操作を Emacs モードにし、Ctrl+V の貼り付けを割り当て直す
- 前提: [PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 2 を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 3・4 は、新しい PowerShell 7 の窓
- 足す行は ASCII の文字だけで、行末の印は `# shell-terminal.md`。キーの割り当てより前、先頭の `using`・`param`・`#Requires` などの宣言より後に入れる
- [設定する行と挿入位置の補足](reference/shell-terminal.md#powershell-7-で-emacs-モードを使う--手順-2-補足-設定する行と挿入位置)

> [!WARNING]
> この項の手順 2 はファイルだけを変える。今開いている窓で `Set-PSReadLineOption -EditMode` を実行すると、それまでのキーの割り当てが消えるので、貼り付けを続ける窓では実行しない。

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. PowerShell 7 のプロファイルに、モードとキーの 2 行を入れる。

   ```powershell
   & {
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     $lines = @(
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineOption -EditMode Emacs }  # shell-terminal.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Chord Ctrl+v -Function Paste }  # shell-terminal.md'
     )
     if (-not (Test-Path -LiteralPath $p)) { Write-Error "中断: プロファイルが無い。前提の手順を先に通す: $p"; return }
     $bytes = [IO.File]::ReadAllBytes($p)
     $wide = $bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE
     $enc = if ($wide) { [Text.Encoding]::Unicode } else { [Text.Encoding]::GetEncoding(28591) }
     $original = $enc.GetString($bytes)
     $text = [regex]::Replace($original, '(?m)^(\uFEFF|\u00EF\u00BB\u00BF)?[^\r\n]*  # shell-terminal\.md\r?(\n|$)', '$1')
     if ($wide) { $parseText = $text; $parseEnc = $enc } else {
       $parseEnc = New-Object Text.UTF8Encoding($false, $true)
       try { $parseText = $parseEnc.GetString($enc.GetBytes($text)) } catch { $parseEnc = [Text.Encoding]::Default; $parseText = $parseEnc.GetString($enc.GetBytes($text)) }
     }
     $bomLength = 0
     if ($parseText.Length -gt 0 -and $parseText[0] -eq [char]0xFEFF) {
       $parseText = $parseText.Substring(1)
       $bomLength = if ($wide) { 1 } else { $parseEnc.GetByteCount([string][char]0xFEFF) }
     }
     $tokens = $null; $errors = $null
     $ast = [Management.Automation.Language.Parser]::ParseInput($parseText, [ref]$tokens, [ref]$errors)
     if ($errors.Count) { Write-Error '中断: プロファイルに構文エラーがある。何も書いていない'; return }
     $commands = @($ast.FindAll({ param($a) $a -is [Management.Automation.Language.CommandAst] }, $true))
     $modes = @($commands | Where-Object {
       $_.GetCommandName() -match '(^|\\)Set-PSReadLineOption$' -and
       @($_.CommandElements | Where-Object { $_ -is [Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'EditMode' }).Count
     })
     $keys = @($commands | Where-Object { $_.GetCommandName() -match '(^|\\)Set-PSReadLineKeyHandler$' } | Sort-Object { $_.Extent.StartOffset })
     if ($keys.Count) {
       $lateMode = @($commands | Where-Object {
         $_.GetCommandName() -match '(^|\\)Set-PSReadLineOption$' -and $_.Extent.StartOffset -gt $keys[0].Extent.StartOffset -and
         @($_.CommandElements | Where-Object { $_ -is [Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'EditMode' }).Count
       })
       if ($lateMode.Count) { Write-Error '中断: 印の無い EditMode の行がキーの割り当てより後にある。先にその行をキーの割り当てより前へ移す。何も書いていない'; return }
       $anchor = $ast.EndBlock.Statements | Where-Object {
         $_.FindAll({ param($a) $a -is [Management.Automation.Language.CommandAst] -and $a.GetCommandName() -match '(^|\\)Set-PSReadLineKeyHandler$' }, $true).Count
       } | Select-Object -First 1
       if (-not $anchor) { Write-Error '中断: キーの割り当ての位置を決められない。何も書いていない'; return }
       $pos = $parseText.LastIndexOf("`n", $anchor.Extent.StartOffset) + 1
       if ($parseText.Substring($pos, $anchor.Extent.StartOffset - $pos).Trim()) { Write-Error '中断: キーの割り当てと同じ行に別の文がある。何も書いていない'; return }
     } else { $pos = $parseText.Length }
     if (@($modes | Where-Object { $_.Extent.StartOffset -ge $pos }).Count) { Write-Error '中断: 挿入位置より後に印の無い EditMode がある。複合文からモードとキーの設定を別の行へ分け、モードを先に置く。何も書いていない'; return }
     $declarations = @($ast.UsingStatements) + @($ast.ParamBlock)
     if (@($declarations | Where-Object { $_ -and $_.Extent.EndOffset -gt $pos }).Count) { Write-Error '中断: 宣言より後の位置を決められない。何も書いていない'; return }
     $offset = if ($wide) { $pos } else { $parseEnc.GetByteCount($parseText.Substring(0, $pos)) }
     $offset += $bomLength
     $nl = if ($text.Contains("`r`n") -or -not $text.Contains("`n")) { "`r`n" } else { "`n" }
     $add = ($lines -join $nl) + $nl
     if ($offset -gt 0 -and $text[$offset - 1] -ne "`n" -and $text.Substring(0, $offset) -notmatch '^(\uFEFF|\u00EF\u00BB\u00BF)?$') { $add = $nl + $add }
     $result = $text.Insert($offset, $add)
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($result -eq $original) { "設定済み: $p" } else { [IO.File]::WriteAllBytes($p, $enc.GetBytes($result)); "設定した: $p" }
     $lines
   }
   ```

   - `設定した:` か `設定済み:` と、印の付いた 2 行が出ればよい。再実行しても同じ行は増えない
   - `中断:` が出たら、この項の手順 3 へ進まない。印の無い `EditMode` の行がキーの割り当てより後なら、先にその行をキーの割り当てより前へ移してから貼り直す
   - 印の無い `EditMode` の行がキーの割り当てより前なら、そのまま残してよい

1. スタートメニューから、新しい PowerShell 7 を開く。

   - 「PowerShell」を探し、「Windows PowerShell」ではない「PowerShell」（PowerShell 7）をクリックして開く
   - **次の手順は、新しく開いた PowerShell 7 の窓に貼る**

1. 新しい PowerShell 7 で、モードとキーを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-PSReadLineOption).EditMode
   Get-PSReadLineKeyHandler -Chord Ctrl+v,Ctrl+Enter,UpArrow | Format-Table Key, Function -AutoSize
   ```

   - `Emacs` と、`Ctrl+v` の `Paste`・`Ctrl+Enter` の `AddLine`・`UpArrow` の `HistorySearchBackward` が出ればよい
   - 出なければ、[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 4・5 と、この項の手順 2 を確かめる
   - 元に戻すときのこの項の手順 5 は、この項の手順 1 で開いた Windows PowerShell（5.1）に貼る

1. 元に戻すときは、PowerShell 7 のプロファイルから、この項の印の行だけを消す。

   ```powershell
   & {
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     if (-not (Test-Path -LiteralPath $p)) { "プロファイルが無い: $p"; return }
     $bytes = [IO.File]::ReadAllBytes($p)
     $enc = if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { [Text.Encoding]::Unicode } else { [Text.Encoding]::GetEncoding(28591) }
     $text = $enc.GetString($bytes)
     $rest = [regex]::Replace($text, '(?m)^(\uFEFF|\u00EF\u00BB\u00BF)?[^\r\n]*  # shell-terminal\.md\r?(\n|$)', '$1')
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($rest -eq $text) { "その行は無い: $p" } elseif ($rest -match '^(\uFEFF|\u00EF\u00BB\u00BF)?\s*$') { Remove-Item -LiteralPath $p; "消した: $p" } else { [IO.File]::WriteAllBytes($p, $enc.GetBytes($rest)); "その行だけ消した: $p" }
   }
   ```

   - `その行だけ消した:`（ほかの行が無ければ `消した:`、すでに消してあれば `その行は無い:`）が出ればよい
   - 印の無い行と `# windows-setup.md` の行は残る。モードを変える印の無い行があれば、その設定も残る
   - 開いている窓には閉じるまで設定が残る。次に開いた窓で、残したプロファイルの設定を読む
   - [PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 7 は、この項の行も含めて消す

---

### Windows PowerShell 5.1 のキー操作を変える

- 任意で、Windows PowerShell 5.1 を Emacs モードにし、Ctrl+V と ↑/↓ の履歴検索を割り当てる
- 前提: [貼り付けの設定](windows-setup.md#貼り付けの設定)の手順 1〜5 を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 3・4 は新しい Windows PowerShell（5.1）の窓
- 対象は `[Environment]::GetFolderPath('MyDocuments')` の下の `WindowsPowerShell\Microsoft.PowerShell_profile.ps1`（Windows PowerShell 5.1 の `$PROFILE`）
- 足す 4 行は ASCII の文字だけで、行末の印は `# shell-terminal.md`。Ctrl+Enter などのキーの割り当てより前、先頭の宣言より後に入れる
- Ctrl+V は `Paste` を割り当て直す。複数行を作る Ctrl+Enter は、貼り付けの設定の `AddLine` のまま
- conhost の右クリックの貼り付けは、PSReadLine の `Paste` を呼ばず、文字をキーとして送る。LF は Ctrl+Enter として届くので、[貼り付けの設定](windows-setup.md#貼り付けの設定)の Ctrl+Enter の `AddLine` の行が、この項の EditMode の行より後に残っている必要がある（この項の手順 2 は、その順に入れる）。Emacs モードの窓に右クリックで貼ることは、実機では確かめていない（[補足](reference/shell-terminal.md#windows-powershell-51-のキー操作を変える--手順-2-補足-適用範囲と貼り付け)）

> [!WARNING]
> - この項の手順 2 で変えるプロファイルは、手順書を貼る管理者の conhost の窓や、プロファイルを読む SSH のセッションにも効く。
> - 全ユーザーの `$PSHOME\profile.ps1` などは先に読まれる。そこで付けたキーも `EditMode` で消えるので、必要な割り当てはこの項の行より後で付け直す。
> - この項の手順 2 はファイルだけを変える。今開いている窓で `Set-PSReadLineOption -EditMode` を実行しない。

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Windows PowerShell（5.1） のプロファイルに、モードとキーの 4 行を入れる。

   ```powershell
   & {
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
     $lines = @(
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineOption -EditMode Emacs }  # shell-terminal.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Chord Ctrl+v -Function Paste }  # shell-terminal.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward }  # shell-terminal.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward }  # shell-terminal.md'
     )
     if (-not (Test-Path -LiteralPath $p)) { Write-Error "中断: プロファイルが無い。前提の手順を先に通す: $p"; return }
     $bytes = [IO.File]::ReadAllBytes($p)
     $wide = $bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE
     $enc = if ($wide) { [Text.Encoding]::Unicode } else { [Text.Encoding]::GetEncoding(28591) }
     $original = $enc.GetString($bytes)
     $text = [regex]::Replace($original, '(?m)^(\uFEFF|\u00EF\u00BB\u00BF)?[^\r\n]*  # shell-terminal\.md\r?(\n|$)', '$1')
     if ($wide) { $parseText = $text; $parseEnc = $enc } else {
       $parseEnc = New-Object Text.UTF8Encoding($false, $true)
       try { $parseText = $parseEnc.GetString($enc.GetBytes($text)) } catch { $parseEnc = [Text.Encoding]::Default; $parseText = $parseEnc.GetString($enc.GetBytes($text)) }
     }
     $bomLength = 0
     if ($parseText.Length -gt 0 -and $parseText[0] -eq [char]0xFEFF) {
       $parseText = $parseText.Substring(1)
       $bomLength = if ($wide) { 1 } else { $parseEnc.GetByteCount([string][char]0xFEFF) }
     }
     $tokens = $null; $errors = $null
     $ast = [Management.Automation.Language.Parser]::ParseInput($parseText, [ref]$tokens, [ref]$errors)
     if ($errors.Count) { Write-Error '中断: プロファイルに構文エラーがある。何も書いていない'; return }
     $commands = @($ast.FindAll({ param($a) $a -is [Management.Automation.Language.CommandAst] }, $true))
     $modes = @($commands | Where-Object {
       $_.GetCommandName() -match '(^|\\)Set-PSReadLineOption$' -and
       @($_.CommandElements | Where-Object { $_ -is [Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'EditMode' }).Count
     })
     $keys = @($commands | Where-Object { $_.GetCommandName() -match '(^|\\)Set-PSReadLineKeyHandler$' } | Sort-Object { $_.Extent.StartOffset })
     if ($keys.Count) {
       $lateMode = @($commands | Where-Object {
         $_.GetCommandName() -match '(^|\\)Set-PSReadLineOption$' -and $_.Extent.StartOffset -gt $keys[0].Extent.StartOffset -and
         @($_.CommandElements | Where-Object { $_ -is [Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'EditMode' }).Count
       })
       if ($lateMode.Count) { Write-Error '中断: 印の無い EditMode の行がキーの割り当てより後にある。先にその行をキーの割り当てより前へ移す。何も書いていない'; return }
       $anchor = $ast.EndBlock.Statements | Where-Object {
         $_.FindAll({ param($a) $a -is [Management.Automation.Language.CommandAst] -and $a.GetCommandName() -match '(^|\\)Set-PSReadLineKeyHandler$' }, $true).Count
       } | Select-Object -First 1
       if (-not $anchor) { Write-Error '中断: キーの割り当ての位置を決められない。何も書いていない'; return }
       $pos = $parseText.LastIndexOf("`n", $anchor.Extent.StartOffset) + 1
       if ($parseText.Substring($pos, $anchor.Extent.StartOffset - $pos).Trim()) { Write-Error '中断: キーの割り当てと同じ行に別の文がある。何も書いていない'; return }
     } else { $pos = $parseText.Length }
     if (@($modes | Where-Object { $_.Extent.StartOffset -ge $pos }).Count) { Write-Error '中断: 挿入位置より後に印の無い EditMode がある。複合文からモードとキーの設定を別の行へ分け、モードを先に置く。何も書いていない'; return }
     $declarations = @($ast.UsingStatements) + @($ast.ParamBlock)
     if (@($declarations | Where-Object { $_ -and $_.Extent.EndOffset -gt $pos }).Count) { Write-Error '中断: 宣言より後の位置を決められない。何も書いていない'; return }
     $offset = if ($wide) { $pos } else { $parseEnc.GetByteCount($parseText.Substring(0, $pos)) }
     $offset += $bomLength
     $nl = if ($text.Contains("`r`n") -or -not $text.Contains("`n")) { "`r`n" } else { "`n" }
     $add = ($lines -join $nl) + $nl
     if ($offset -gt 0 -and $text[$offset - 1] -ne "`n" -and $text.Substring(0, $offset) -notmatch '^(\uFEFF|\u00EF\u00BB\u00BF)?$') { $add = $nl + $add }
     $result = $text.Insert($offset, $add)
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($result -eq $original) { "設定済み: $p" } else { [IO.File]::WriteAllBytes($p, $enc.GetBytes($result)); "設定した: $p" }
     $lines
   }
   ```

   - `設定した:` か `設定済み:` と、印の付いた 4 行が出ればよい。再実行しても同じ行は増えない
   - `中断:` が出たら、この項の手順 3 へ進まない。印の無い `EditMode` の行がキーの割り当てより後なら、先にその行をキーの割り当てより前へ移してから貼り直す
   - 印の無い `EditMode` の行がキーの割り当てより前なら、そのまま残してよい

1. スタートメニューから、新しい Windows PowerShell（5.1） を開く。

   - 「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - **次の手順は、新しく開いた Windows PowerShell（5.1） の窓に貼る**

1. 新しい Windows PowerShell（5.1） で、モードとキーを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-PSReadLineOption).EditMode
   Get-PSReadLineKeyHandler -Bound | Where-Object { $_.Key -in 'Ctrl+v', 'Ctrl+Enter', 'UpArrow', 'DownArrow' } | Format-Table Key, Function -AutoSize
   ```

   - `Emacs` と、`Ctrl+v` の `Paste`・`Ctrl+Enter` の `AddLine`・`UpArrow` の `HistorySearchBackward`・`DownArrow` の `HistorySearchForward` が出ればよい
   - 5.1 の PSReadLine（2.0.0）の `Get-PSReadLineKeyHandler` には `-Chord` が無いので、割り当ての一覧から絞る
   - 出なければ、この項の手順 2 と[貼り付けの設定](windows-setup.md#貼り付けの設定)の手順 3〜5 を確かめる
   - 元に戻すときのこの項の手順 5 は、この項の手順 1 で開いた Windows PowerShell（5.1）に貼る

1. 元に戻すときは、Windows PowerShell（5.1） のプロファイルから、この項の印の行だけを消す。

   ```powershell
   & {
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
     if (-not (Test-Path -LiteralPath $p)) { "プロファイルが無い: $p"; return }
     $bytes = [IO.File]::ReadAllBytes($p)
     $enc = if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { [Text.Encoding]::Unicode } else { [Text.Encoding]::GetEncoding(28591) }
     $text = $enc.GetString($bytes)
     $rest = [regex]::Replace($text, '(?m)^(\uFEFF|\u00EF\u00BB\u00BF)?[^\r\n]*  # shell-terminal\.md\r?(\n|$)', '$1')
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($rest -eq $text) { "その行は無い: $p" } elseif ($rest -match '^(\uFEFF|\u00EF\u00BB\u00BF)?\s*$') { Remove-Item -LiteralPath $p; "消した: $p" } else { [IO.File]::WriteAllBytes($p, $enc.GetBytes($rest)); "その行だけ消した: $p" }
   }
   ```

   - `その行だけ消した:`（ほかの行が無ければ `消した:`、すでに消してあれば `その行は無い:`）が出ればよい
   - 印の無い行と `# windows-setup.md` の行は残る。モードを変える印の無い行があれば、その設定も残る
   - 開いている窓には閉じるまで設定が残る。次に開いた窓で、残したプロファイルの設定を読む
   - [アプリと貼り付けの設定を外す](extra/windows-setup.md#アプリと貼り付けの設定を外す)の手順 6 は、この項の行も含めて消す

---
