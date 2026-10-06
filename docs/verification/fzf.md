# fzf インストール手順（AlmaLinux 10 / Homebrew）の検証記録

[手順書](../fzf.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **現行版 `5da3478` を、共通 bash 設定を新規導入した別の x86_64 VM でも再検証した**（末尾の再検証記録）。既存ホストの手動移行は今回は実行していない。
>
> **x86_64 のクリーン VM で検証対象版の実施手順を本実行済み**（2026-10-06）。コンテナでも検証したが、実機では本書の手順を通していない（[対象と検証環境](#対象と検証環境)）。VM のキーは SSH の PTY に、以前のコンテナでは tmux のペインに送って確かめたもので、GNOME 端末や WezTerm で Alt+C が届くかは確かめていない。

### 使い方の基本 / 手順 0: 本文中の記録

- シェルのキーと環境変数、fzf の画面の中のキー、検索の書き方。どれもコンテナの fzf 0.74.4 で確かめた（[付録](#付録-コンテナでの検証記録2026-10-02)）



- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

### 対象と検証環境

- **目的**: AlmaLinux 10 の bash に [fzf](https://github.com/junegunn/fzf)（一覧から曖昧検索で選ぶコマンド）のキー操作と補完を組み込み、履歴・パス・ディレクトリを打ちかけの文字から選べるようにする
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **`0dbb522` の直接追記版の実施手順 1〜7・fd と bat の任意節を x86_64 のクリーン VM で本実行済み（2026-10-06）。コンテナでも検証済み（2026-10-02）**。現行版 `5da3478` の共通 bash 新規導入後の再検証も、末尾に記録した。既存ホストの手動移行は今回は実行していない。
  - 通したこと: SSH でログインした対話の bash に、この文書の bash のブロックをそのまま貼り、実施手順・任意節・[更新](../fzf.md#更新)・[ロールバック](../fzf.md#ロールバック)を、ブラケットペーストの無しと有りで 1 回ずつ通した（[付録](#付録-コンテナでの検証記録2026-10-02)）
  - 確認したこと
    - 手順 1〜3 の出力、手順 4〜7 のキー（tmux のペインに `C-r` / `C-t` / `M-c` / Tab を送って画面を読んだ）、[使い方の基本](../fzf.md#使い方の基本)の表、任意節のプレビュー、[ロールバック](../fzf.md#ロールバック)
    - `fzf --bash` が `PROMPT_COMMAND` などに触らないこと、非対話のシェルで何も出さないこと、2 回読んでも二重にならないこと
    - bash-completion の遅延読み込み（`git checko<Tab>`）と、[bash-settings.md 手順 4](../bash-settings.md#実施手順) の Homebrew の補完の行との並び
  - **確認していないこと**
    - 実機（aarch64 の Raspberry Pi 5、x86_64 の PC）、GNOME 端末・WezTerm から送る Alt+C
    - `kill -9 <Tab>` の fzf の一覧（コンテナでは fzf でなく通常の PID の一覧が出た。理由は追っていない）
    - Homebrew の版が上がる[更新](../fzf.md#更新)

| 項目 | 検証コンテナ |
|---|---|
| 実施日 | 2026-10-02 |
| OS | AlmaLinux 10.2 (Lavender Lion)（`quay.io/almalinuxorg/10-init`。パッケージは `x86_64_v2`） |
| コンテナ | クラウドのホストの Docker 29.6.2、`--privileged` と `--network host`。systemd を PID 1 にし、sshd と systemd-logind を動かした |
| bash | 5.2.26（BaseOS）。bash-completion 2.11-16（BaseOS）を入れた状態 |
| Homebrew | 7.0.7（`/home/linuxbrew/.linuxbrew`） |
| fzf | 0.74.4（Homebrew）。依存は `ncurses` |
| ほか | fd 10.5.0・bat 0.26.1・eza 0.23.5・zoxide 0.10.0・starship 1.26.0（Homebrew。任意節と補完の確認用） |
| 端末 | ホストの tmux 3.4 のペイン（160x45）から `docker exec -it` で `ssh -t` し、`TERM=xterm-256color` |

> [!NOTE]
> 出力例・ログの中の値は `<USER>` / `<HOSTNAME>` / `<PID>` のプレースホルダで書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| fzf | 未導入（検証では、先に入れた fzf を `brew uninstall fzf` と `brew autoremove` で `ncurses` ごと消してから始めた） |
| Homebrew | 7.0.7 導入済み。fd・bat・eza・zoxide・starship が入っている |
| `~/.bashrc` | `brew shellenv` の行と、[bash-settings.md](../bash-settings.md) の 5 行 |

### 選択した方針

- **Homebrew の 0.74.4 にした**（[導入元一覧](../tool-catalog.md)の規則。EPEL は 0.58.0）
  - `fzf --bash` は 0.48.0 からあるので EPEL の版でも同じ手順で動くはずだが、確かめていない。yazi・zoxide の依存ですでに Homebrew の fzf が入っているホストが多いので、揃える
- **`fzf --bash` で組み込む**: formula の caveat の案内で、fzf の `install` スクリプト（`~/.fzf.bash` と `~/.bashrc` への追記）は使わない。bash リポジトリの初期化がインストール済みの版に追従する
- **atuin は採らない**: 履歴を SQLite に持ち、別のホストと同期もできる履歴の検索ツール。Ctrl+R を取り合うので、どちらか 1 つにする。fzf は依存ですでに入っていて、履歴のほかにパスとディレクトリにも使えるので、こちらにした。atuin は[導入元一覧](../tool-catalog.md#cli-定番の置き換え)の行のまま（試していない）
- **ble.sh・mcfly も採らない**: ble.sh は行の編集そのものを置き換える大きなもの、mcfly は履歴だけ。どちらも RPM が無い。試していない
- **`kill` の補完は書かない**: コンテナでは fzf の一覧にならなかった（[対象と検証環境](#対象と検証環境)）

### 完了時点の状態

実施手順の後:

```
$ tail -n 1 ~/.bashrc
eval "$(fzf --bash)"
$ bind -X
"\C-r": "__fzf_history__"
"\C-t": "fzf-file-widget"
$ complete -p cd vi ssh
complete -o nospace -F _fzf_dir_completion cd
complete -o bashdefault -o default -F _fzf_path_completion vi
complete -o bashdefault -o default -F _fzf_complete_ssh ssh
```

- 入るファイルは `/home/linuxbrew/.linuxbrew/Cellar/fzf/0.74.4/` の実行ファイル・man・`shell/` のスクリプトと、依存の `ncurses`
- 任意節を通すと、`~/.bashrc` に `export FZF_…` の 4 行が付く

### 付録: コンテナでの検証記録（2026-10-02）

**環境**: [対象と検証環境](#対象と検証環境)の表のとおり。コンテナには NOPASSWD の sudo を持つ一般ユーザーを作り、root から `ssh -p 2222 <USER>@127.0.0.1` でログインした。準備（プロキシ・リポジトリ・Homebrew）は [bash-settings.md の付録](bash-settings.md#付録-コンテナでの検証記録2026-10-02)と同じ。

**先に調べたこと**（文書の内容を決めるため）:

- `fzf --bash` の出力（939 行）に `PROMPT_COMMAND` / `PS0` / `PS1` は無く、`if [[ $- =~ i ]]` が 2 か所。`bash -c 'eval "$(fzf --bash)"'` の出力は 0 バイト
- `brew deps fzf` は `ncurses`。`brew uses --installed fzf` は空（zoxide・yazi は formula の依存に fzf を持たない）
- `complete -p` は、読んだ直後に `cd` が `_fzf_dir_completion`、`cat` `vi` `git` が `_fzf_path_completion`、`ssh` が `_fzf_complete_ssh`、`kill` が `_fzf_proc_completion`。`git checko<Tab>` は `checkout` に補完され、その後の `complete -p git` に `-o nospace` が足されていた（bash-completion の遅延読み込みが `git` を読み、fzf がそれを包み直した）
- 検索の書き方の表は `printf '%s\n' apple banana cherry grape pineapple apple-pie | fzf -f '<書き方>'` の結果
- Homebrew の補完の行（bash-settings.md 手順 4）を fzf の後ろに読むと、`complete -p bat` が `_bat` に戻り `bat **<Tab>` が fzf にならなかった。前に読むと `_fzf_path_completion` のままで、`bat --the<Tab>` も `--theme` に補完された

**流し方**:

- ホストの tmux のペインで `docker exec -it … ssh -t` したログインシェルに、この文書の bash のブロック（折り畳みの外のもの）を抜き出して、手順ごとに `tmux paste-buffer` で書き込んだ（bash-settings.md を通した後の `~/.bashrc` から）
- 1 回目はブラケットペースト無しで、2 回目は `paste-buffer -p`（ブラケットペースト有り。貼った後に Enter を送った）で、実施手順から[ロールバック](../fzf.md#ロールバック)まで通した。2 回の間に `brew uninstall fzf` と `brew autoremove` で実施前に戻した
- キーは `tmux send-keys` で `C-r` / `C-t` / `M-c` / Tab / Escape を送り、`capture-pane` で画面を読んだ

| 手順 | 結果（2 回とも同じ） |
|---|---|
| 1 | `Would install 1 formula: fzf 0.74.4`、`Would install 1 dependency for fzf: ncurses`、`[y/n]`。`y` で `ncurses 6.6` と `fzf 0.74.4` のボトルが入り、caveat に `To set up shell integration, see: https://github.com/junegunn/fzf#setting-up-shell-integration` |
| 2 | `0.74.4 (Homebrew)`、`/home/linuxbrew/.linuxbrew/bin/fzf`、`fzf 0.74.4` |
| 3 | `bind -X` に `"\C-r": "__fzf_history__"` と `"\C-t": "fzf-file-widget"`。`complete -p` に `_fzf_dir_completion cd`・`_fzf_path_completion vi`・`_fzf_complete_ssh ssh` |
| 4 | Ctrl+R で履歴の一覧（右上に `68/68 (0) +S`）。`fzf --v` で 5 件に絞られ、Enter で `brew list --versions fzf` がプロンプトに入った（実行されない）。もう一度 Enter で `fzf 0.74.4` |
| 5 | `cat ` の後の Ctrl+T でホームの下の一覧（1,222 件。`.cache/Homebrew/` の中も）。`bashrc` で `.bashrc` だけになり、Enter で `cat .bashrc`。Enter で中身が出た |
| 6 | `ls /usr/share/**` + Tab で 6,943 件。`doc/bash` で 24 件、Enter で `ls /usr/share/doc/bash-completion/`。`ssh **<Tab>` は `known_hosts` の 4 件、`export **<Tab>` は 32 の変数名 |
| 7 | Alt+C で 272 のディレクトリ（行には `` `__fzf_cd__` `` と表示される）。`proj-b` で 1 件、Enter で `builtin cd -- /home/<USER>/work/proj-b` と出てプロンプトが `proj-b` に。`cd -` でホーム |
| 任意節 1・2 | 4 行が読み戻された。Ctrl+T の一覧が 917 件（`fd` の結果。`.git` の中は無い）になり、右側に `bat` の行番号付きの中身が出た。`bashrc` で `.bashrc` に絞ると、プレビューも `.bashrc` の中身になった |
| 更新 | `Warning: fzf 0.74.4 already installed` |
| ロールバック 1〜3 | `grep -c` はどちらも `0`。`brew uninstall fzf` は `Uninstalling …/Cellar/fzf/0.74.4... (19 files, 6.0MB)` に続けて `==> Autoremoving 1 unneeded formula: ncurses` と出し、`ncurses` も消した。新しいシェルの `zi` は `zoxide: could not find fzf, is it installed?`、`bind -X` は何も出さず、`complete -p vi` は `no completion specification` |

#### 未確認事項

- 実機（aarch64 の Raspberry Pi 5、x86_64 の PC）での本実行
- GNOME 端末・WezTerm から送る Alt+C、Shift+Tab
- COPR の fzf（dnf の zoxide の PC）での `fzf --bash`
- `kill -9 <Tab>` が fzf の一覧にならなかった理由
- Homebrew の版が上がる `brew upgrade fzf`
- `**<Tab>` の候補を fd に変える `_fzf_compgen_path()`

---

### 付録: クリーン VM での検証記録（2026-10-06）

**検証対象**: `0dbb522` の、各手順で `~/.bashrc` などへ設定を直接追記する版。以下の手順番号と「本文」はこの版を指す。検証後に共通 bash 設定へ統一された現行版（`0bc9970`）の設定リポジトリの新規導入・既存設定からの移行は、今回の VM では実行していない。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証対象版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順（`0dbb522`）**: 実施手順 1〜7、fd と bat を候補とプレビューに使う任意節の手順 1・2。

**結果**: zoxide の手順で入った fzf 0.74.4 は再導入不要だった。`~/.bashrc` に初期化を書き、`bind -X` と補完を読み戻した。Ctrl+R で `fzf --version` を選び、入力行への挿入と、再 Enter での実行を確認した。Ctrl+T で `.bashrc` を選び `cat`、`ls /usr/share/**` と Tab で `/usr/share/doc/bash/` を選んで `ls`、Alt+C で検証用ディレクトリへ移って `cd -` で戻った。任意節の 4 行も読み込み、Ctrl+T の候補が fd の一覧になって `.git` を除くことと、右側に bat の行番号付きプレビューが出ることを確認した。

**今回の未確認範囲**: GNOME 端末・WezTerm からのキー、更新・ロールバックは今回流していない。

### 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜3 と「fd と bat」の任意節を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で共通 bash `3d5323e` の導入後に実行した。fzf 0.74.4、fd 10.4.2、bat 0.26.1 を使った
- SSH 対話 PTY にキーを送り、Ctrl+R で履歴の `fzf --version` を選んで実行、Ctrl+T でファイル候補と bat の本文プレビューを表示して選択、Alt+C で空白を含む `sub directory` へ移動した。共通設定の `FZF_*`、バインドと SSH ホスト候補の補完も確認した
- 実施手順 6 の `ls /usr/share/**<Tab>` も実キーで候補を開き、`doc/bash` へ絞って選択した。Enter の後に `/usr/share/doc/bash/` が入力行へ入った
- GUI 端末の物理キー、既存ホストの設定移行、更新・削除は今回は実行していない

### 手順中の検証状況

- 端末が Alt を ESC の前置きとして送る設定のときに届く（tmux のペインでは `M-c` で届いた。GNOME 端末・WezTerm では確かめていない）

### 実施手順 / 手順 1: 補足: 依存と、入れてあるホストで貼る意味

- fzf の依存は `ncurses` だけ（`brew deps fzf`）。コンテナで `brew install fzf fd bat eza zoxide starship` をまとめて入れたときは、fzf のボトルの前に `ncurses` が入った

- 入れてあるホストの出力:

```
Warning: fzf 0.74.4 is already installed and up-to-date.
To reinstall 0.74.4, run:
  brew reinstall fzf
```

