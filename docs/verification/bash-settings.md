# bash の履歴・補完・キー操作の設定手順（AlmaLinux 10）の検証記録

[手順書](../bash-settings.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **現行版 `5da3478` を、共通 bash を新規導入した別の x86_64 VM で再検証した**（末尾の再検証記録）。既存ホストの手動移行は実行していない。
>
> **x86_64 のクリーン VM で検証対象版の実施手順を本実行済み**（2026-10-06）で、実機では本書の手順を通していない（[対象と検証環境](#対象と検証環境)）。GNOME 端末や WezTerm の画面での色と、Home / End / Ctrl+矢印のキーは確かめていない。

### 実施手順 / 手順 1: 補足: bash-completion が無いとどうなるか

- bash 自身の補完は、コマンド名・ファイル名・変数名だけ。`systemctl star<Tab>` や `git checko<Tab>` のような、コマンドごとのサブコマンドやオプションの補完は bash-completion（と、各パッケージが `/usr/share/bash-completion/completions/` に置く定義）が行う
- AlmaLinux 10.2 の BaseOS の版は 2.11（2026-10-02）。コンテナの最小のイメージには入っていなかった
- 入れると `/etc/profile.d/bash_completion.sh` が置かれ、対話のシェルを開くときに `/etc/profile`（ログインシェル）か `/etc/bashrc`（それ以外）から読まれる

### 実施手順 / 手順 2: 補足: . ~/.bashrc では読まれない理由

- `/etc/bashrc` は `/etc/profile.d/*.sh` を**ログインシェルでないとき**だけ読む（`if ! shopt -q login_shell`）。SSH でログインしたシェルで `. ~/.bashrc` を実行しても、`/etc/bashrc` 経由では `bash_completion.sh` に届かない
- `bash_completion.sh` 自身は、対話の bash で、まだ読んでいないとき（`BASH_COMPLETION_VERSINFO` が空）だけ本体を読む。2 回目は何もしない
- `complete -p -D` の `_completion_loader` は、コマンドの補完を最初の Tab のときに `/usr/share/bash-completion/completions/<コマンド>` から読む仕組み（遅延読み込み）。読む前の `complete -p git` は `bash: complete: git: no completion specification` になる
- AlmaLinux 10.2 Workstation のクリーン VM（2026-10-06）では、既存の `python3-argcomplete-3.2.2-4.el10` が既定の補完を `_python_argcomplete_global` にしていた。この関数は argcomplete の対象でなければ `_completion_loader` を呼ぶ。`systemctl star<Tab>` などの補完も通ったので、関数名だけで未読込とは判断しない



- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

### 対象と検証環境

- **目的**: AlmaLinux 10 の bash で、履歴を多く残し、Tab の補完を広く・楽にし、↑ で打ちかけの行から履歴を探せるようにする。ツールを足すのではなく、bash と readline の設定と、bash-completion の RPM だけで行う
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **`0dbb522` の直接追記版の実施手順 1〜8 を x86_64 のクリーン VM で本実行済み（2026-10-06）。コンテナでも検証済み（2026-10-02）**。現行版 `5da3478` は、共通 bash 新規導入後の別の VM でも再検証した（末尾の再検証記録）。既存ホストの手動移行は行っていない。
  - 通したこと: SSH でログインした対話の bash に、この文書の bash のブロックをそのまま貼り、実施手順と[ロールバック](../bash-settings.md#ロールバック)を、ブラケットペーストの無しと有りで 1 回ずつ通した（[付録](#付録-コンテナでの検証記録2026-10-02)）
  - 確認したこと
    - 手順 1〜7 の出力、手順 8 のキー操作（tmux のペインにキーを送って画面を読んだ）、[ロールバック](../bash-settings.md#ロールバック)
    - `~/.inputrc` に `$include /etc/inputrc` が無いと `/etc/inputrc` の割り当てが消えること、`~/.bashrc` の行を消した後に閉じたシェルが履歴を 1,000 行に切り詰めること
    - [fzf.md](../fzf.md) の行との並び（手順 4 の補足）
  - **確認していないこと**
    - 実機（aarch64 の Raspberry Pi 5、x86_64 の PC）、GNOME 端末・WezTerm の画面での色と Home / End / Ctrl+矢印
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
| `~/.bashrc` | `/etc/skel` のもの（`/etc/bashrc` を読み、`~/.bashrc.d/` があれば読む）に、[homebrew.md 手順 3](../homebrew.md#実施手順) の `brew shellenv` の 1 行 |
| `~/.inputrc` | 無し（`/etc/inputrc` が読まれている） |
| 履歴 | `HISTSIZE=1000`・`HISTFILESIZE=1000`・`HISTCONTROL=ignoredups`、`histappend` は on |

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
- [fzf.md 手順 3](../fzf.md#実施手順) を通すと、`fzf --bash` の行が `bash_completion.d` の行の後ろに付く

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
- 1 回目はブラケットペースト無しで、2 回目は `paste-buffer -p`（ブラケットペースト有り。貼った後に Enter を送った）で、実施手順から[ロールバック](../bash-settings.md#ロールバック)まで通した。2 回の間に bash-completion を消し、`~/.bashrc` と `~/.inputrc` を実施前に戻した
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
- `python3` など bash 以外の readline のコマンドでの `~/.inputrc`
- 日本語入力との組み合わせ

---

### 付録: クリーン VM での検証記録（2026-10-06）

**検証対象**: `0dbb522` の、各手順で `~/.bashrc` などへ設定を直接追記する版。以下の手順番号と「本文」はこの版を指す。検証後に共通 bash 設定へ統一された現行版（`0bc9970`）の設定リポジトリの新規導入・既存設定からの移行は、今回の VM では実行していない。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証対象版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順（`0dbb522`）**: 実施手順 1〜8。

**結果**: Workstation に既存の bash-completion 2.11 を使い、OS 既定の `~/.bashrc` に本文の履歴・shopt・Homebrew 補完を足し、`~/.inputrc` を作った。SSH を切ってログインし直した後も値が残った。手順 8 の systemctl・パス・大小文字・eza の Tab、printf の履歴検索、autocd・cdspell・globstar を全て実操作で確認した。Workstation の `python3-argcomplete-3.2.2-4.el10` は既定の補完を `_python_argcomplete_global` にする。この関数の内容で `_completion_loader` へ戻す分岐を確認し、通常の Tab も成功したため、これを失敗とは扱わず期待出力の説明を直した。

**今回の未確認範囲**: GNOME 端末・WezTerm の色と物理キー、Home/End/Ctrl+矢印の実操作、ロールバックは今回確認していない。

### 付録: 現行の共通 bash 設定での再検証（2026-10-06）

- `5da3478` の実施手順 1〜5・7 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（SELinux Enforcing）で実行した。先に公開 URL から共通 bash `3d5323e` を clone して `install.sh` を実行し、既存の OS 設定へ読み込み行を 1 個設定した
- bash-completion 2.11 は OS に導入済みだった。`complete -p` でシステムの補完を、Homebrew 7.0.8 の導入後には `_brew` の補完を確認した。対話 SSH を張り直しても同じ設定が読み込まれた
- 履歴は `100000` / `100000` / `ignoreboth`、`histappend` / `autocd` / `cdspell` / `dirspell` / `globstar` はすべて on。Readline の設定 4 個と、上矢印・下矢印への履歴検索の割り当てを `bind` の出力で確認した
- 後の SSH 対話 PTY で手順 8 の Tab・大小文字・曖昧候補の一覧・上矢印の履歴検索・autocd・cdspell・globstar・eza の補完を実キーで確認した。Home / End / Ctrl+矢印の実操作と GUI 端末の色・物理キーはこの CLI 検証には含まない


### 操作上の注意と併記されていた記録

> **この節の手順 2 の後に閉じたシェルは、`~/.bash_history` を既定の 1,000 行に切り詰める**（コンテナで、2,000 行の履歴ファイルが `exit` の後に 1,000 行になった）。残したい履歴があれば、この節の手順 1 で控える。


### 実施手順 / 手順 5: 補足: ~/.inputrc に書く理由と、各行の意味

- readline は `~/.inputrc` があるとそれを読み、無いときだけ `/etc/inputrc` を読む。`$include` を書かずに `~/.inputrc` を置くと、`/etc/inputrc` の Home / End（`\e[1~` / `\e[4~`）、Delete（`\e[3~`）、Ctrl+←→（`\e[5C` / `\e[1;5C`）、PageUp / PageDown の履歴の検索（`\e[5~` / `\e[6~`）が消える（コンテナで、`bind -q beginning-of-line` から `"\e[1~"` が消え、`$include` を足すと戻った）
- `~/.bashrc` に `bind` で書かない理由: `bind` は対話のシェル以外では `line editing not enabled` の警告になる。`~/.inputrc` は bash のほか、readline を使うコマンド（`python3`・`psql`・`gdb` など）にも効く。`INPUTRC` の環境変数も使わない（それらすべてに別のファイルを押し付けることになる）
- `completion-ignore-case`: `cd /ET<Tab>` が `/etc/` に、`cd /usr/SH<Tab>` が `/usr/share/` になる（打った大文字も直る）
- `show-all-if-ambiguous`: 候補が複数のとき、既定では 1 回目の Tab はベルだけで 2 回目で一覧が出る。1 回で出す
- `colored-stats` / `colored-completion-prefix`: 一覧のディレクトリや実行ファイルを `LS_COLORS` の色で、打った部分を別の色で出す（コンテナでは `ls /usr/s<Tab>` の `s` が紫、残りが青の太字で出た）
- `history-search-backward` は、カーソルより前の文字で始まる履歴を探す。`ec` と打って ↑ で `echo …` の行だけが出る。何も打っていなければ既定の ↑ と同じ。カーソルは打った文字の後ろに残る（行末へは End か Ctrl+E）。`/etc/inputrc` は同じ機能を PageUp / PageDown に付けている
- `\e[A` は端末の通常のモード、`\eOA` はアプリケーションモード（`tput smkx` の後）の ↑。bash の既定は両方を `previous-history` にしているので、両方を置き換える
- `bind -f` は今のシェルだけ。新しいシェルは起動のときに `~/.inputrc` を読む

## 参考資料から分離した記録

### 参考資料: 選択した方針

- **bash-completion はシステムの RPM にした**: BaseOS の 2.11 で足りる。Homebrew にも `bash-completion@2`（2.16 系）があるが、RPM の各パッケージが置く `/usr/share/bash-completion/completions/` を読むのはシステムのものの方が素直で、`sudo` のシェルでも同じものが効く
- **Homebrew の補完は bash リポジトリから全部読む**: 遅延読み込みの対象のディレクトリに無いため（手順 4 の補足）。`~/.local/share/bash-completion/completions/` にシンボリックリンクを置けば遅延読み込みにできるが、入れるたびに足す手間があるので採らない
- **`~/.inputrc` を使い、`~/.bashrc` の `bind` にはしない**（手順 5 の補足）
- **採らなかった設定**
  - `HISTTIMEFORMAT`（`history` に時刻を出す）: 履歴ファイルに `#<epoch>` の行が増える。bash 5.2 では、変数を外した後もその行はコマンドとして出なかった（コンテナで確認）が、本書は履歴の見え方を変えない範囲にとどめた。欲しければ `HISTTIMEFORMAT='%F %T '` を手順 3 の行に足せばよい
  - `HISTCONTROL=…:erasedups`（同じ行を全部消して 1 つにする）: 覚えている一覧の中だけを直し、ファイルの古い重複は残る。効き目が分かりにくいので入れない
  - `PROMPT_COMMAND` に `history -a`（コマンドごとにファイルへ書き、別の端末ですぐ使う）: AlmaLinux 10 の `PROMPT_COMMAND` は配列で、starship・WezTerm のシェル統合・zoxide が順番に意味を持って触っている（[starship.md 手順 3](../starship.md#実施手順) の補足）。そこへ足す形は本書では扱わない
  - `set bell-style none`（ベルを消す）、`menu-complete`（Tab で候補を順に入れる）: 好みの幅が大きいので入れない
  - `shopt -s histappend`: `/etc/bashrc` が対話のシェルで入れている（手順 3 の補足）
- **atuin（履歴を SQLite に持ち、同期もする）は使わない**: 履歴の検索は [fzf](../fzf.md) の Ctrl+R で足りる。[導入元一覧](../tool-catalog.md#cli-定番の置き換え)の行のまま
