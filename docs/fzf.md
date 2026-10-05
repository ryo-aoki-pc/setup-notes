# fzf インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わない）
> - **手順 1 には対話入力があることがある**（依存の `ncurses` がまだ無いときの `[y/n]`）
> - **手順 4〜7 はキーを押す操作**（コマンドのブロックは無い）
> - [bash の履歴・補完・キー操作](bash-settings.md)を先に通してあると、Homebrew のコマンドの補完と fzf の `**<Tab>` が両方効く。後から通しても、同書の手順 4 が fzf の行の前に差し込む

- 上から順にコードブロックを貼る。変数は無い
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: キーと検索の書き方は[使い方の基本](#使い方の基本)。候補を fd に、プレビューを bat にするなら [fd と bat を候補とプレビューに使う（任意）](#fd-と-bat-を候補とプレビューに使う任意)。以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **今回の VM 検証対象は `0dbb522` の直接追記版。共通 bash 設定へ統一した現行版の新規導入・移行は今回未実施**。
>
> **x86_64 のクリーン VM で検証対象版の実施手順を本実行済み**（2026-10-06）。コンテナでも検証したが、実機では本書の手順を通していない（[対象と検証環境](#対象と検証環境)）。VM のキーは SSH の PTY に、以前のコンテナでは tmux のペインに送って確かめたもので、GNOME 端末や WezTerm で Alt+C が届くかは確かめていない。

1. brew で fzf を入れる。

   ```bash
   brew install fzf
   ```

   - [yazi.md 手順 2](yazi.md#実施手順) か [zoxide.md 手順 2](zoxide.md#実施手順) で入れてあるホストでは `Warning: fzf 0.74.4 is already installed and up-to-date.` と出る。それでよい（この手順の補足）
   - 依存の `ncurses` がまだ無いときは、`Do you want to proceed with the installation? [y/n]` と聞かれる。`y`（Enter は要らない）
   - **次の手順は、`y` と答えてプロンプトに戻ってから貼る**（続けて貼ると、後ろの行の文字が答えとして読まれる）

   <details>
   <summary>補足: 依存と、入れてあるホストで貼る意味</summary>

   - fzf の依存は `ncurses` だけ（`brew deps fzf`）。コンテナで `brew install fzf fd bat eza zoxide starship` をまとめて入れたときは、fzf のボトルの前に `ncurses` が入った
   - yazi.md や zoxide.md で入れた fzf は、`brew install zoxide fzf` のように名前を挙げて入れているので、Homebrew の「頼まれて入れた」印（`installed_on_request`）が付いている。`brew install fzf` を貼り直しても害は無く、印が無かったホストでは付く（印が無いと、zoxide や yazi を `brew uninstall` した際の自動削除や、明示的な `brew autoremove` で fzf も消えうる）
   - 入れてあるホストの出力:

   ```
   Warning: fzf 0.74.4 is already installed and up-to-date.
   To reinstall 0.74.4, run:
     brew reinstall fzf
   ```

   </details>

1. fzf が入ったことを確かめる。

   ```bash
   fzf --version
   command -v fzf
   brew list --versions fzf
   ```

   - `0.74.4 (Homebrew)` と `/home/linuxbrew/.linuxbrew/bin/fzf` が出る

1. 共通設定を読み直し、キー操作と補完を確かめる。

   ```bash
   . ~/.bashrc
   bind -X
   complete -p cd vi ssh
   ```

   - 共通設定が Homebrew の補完の後で `fzf --bash` を読む。`~/.bashrc` への追記は不要
   - Ctrl+R / Ctrl+T / Alt+C の割り当てと補完が出る

1. Ctrl+R を押し、履歴から手順 2 の `fzf --version` を選んで実行する。

   - 画面の下から fzf の一覧が開き、最下行の `>` の右に打った文字で絞り込める。`fzf --v` では `brew list --versions fzf` なども候補になるので、上下キーで `fzf --version` の行を選ぶ
   - Enter でその行がプロンプトに入る（**実行はされない**）。もう一度 Enter で実行する
   - Esc か Ctrl+C で、何も選ばずに閉じる

1. `cat ` と打ってから Ctrl+T を押し、ファイルを選ぶ。

   - 今のディレクトリの下のファイルの一覧が開く。`bashrc` と打って `.bashrc` に絞り、Enter でカーソルの位置に入る
   - Tab で複数を選べる（選んだ行に印が付き、Enter で全部入る）
   - そのまま Enter で `cat .bashrc` が動く

1. `ls /usr/share/**` と打って Tab を押し、候補から選ぶ。

   - `**` の後の Tab で、`/usr/share/` の下のパスの一覧が開く。`doc/bash` と打って絞り、Enter で `ls /usr/share/doc/bash-completion/` のように入る
   - `**` を付けなければ、今までどおりの補完
   - `ssh **<Tab>` は `~/.ssh/config` と `known_hosts` のホスト名、`export **<Tab>` は変数名の一覧になる

1. Alt+C を押してディレクトリを選んで移り、`cd -` で戻る。

   - 今のディレクトリの下のディレクトリの一覧が開く（開いている間、入力行には `` `__fzf_cd__` `` と出る）。選んで Enter で、`builtin cd -- <ディレクトリ>` と表示して移る
   - 端末が Alt を ESC の前置きとして送る設定のときに届く（tmux のペインでは `M-c` で届いた。GNOME 端末・WezTerm では確かめていない）
   - `cd -` で元のディレクトリに戻る

---

## 使い方の基本

- シェルのキーと環境変数、fzf の画面の中のキー、検索の書き方。どれもコンテナの fzf 0.74.4 で確かめた（[付録](#付録-コンテナでの検証記録2026-10-02)）
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

---

## fd と bat を候補とプレビューに使う（任意）

- Ctrl+T と Alt+C の候補を、既定の `find` から fd に変える（`.git` の中を除き、隠しファイルは含める。`.gitignore` の対象は fd が既定で除く）。Ctrl+T の右側に bat のプレビューを出す
- 前提: fd と bat が入っていること（[yazi.md 手順 2](yazi.md#実施手順) の `YAZI_EXTRAS` か `brew install fd`、[bat](bat.md)）。`command -v fd bat` で 2 行出ればよい
- `**<Tab>` の候補は変わらない（`find` のまま。この節の手順 1 の補足）

1. fd と bat が入っていることを確認し、共通設定を読み直す。

   ```bash
   command -v fd bat
   . ~/.bashrc
   printf '%s\n' "${FZF_DEFAULT_COMMAND-}" "${FZF_CTRL_T_COMMAND-}" "${FZF_ALT_C_COMMAND-}" "${FZF_CTRL_T_OPTS-}"
   ```

   - fd があれば候補の 3 変数、bat があればプレビューの変数が入る。追加の export は不要
   - 無いツールは [fd の導入元](tool-catalog.md)・[bat](bat.md)から入れて端末を開き直す

1. `cat ` と打ってから Ctrl+T を押し、プレビューが出ることを確かめる。

   - 一覧の右側に、選んでいるファイルの中身が行番号と色付きで出る
   - `.git` の中のファイルは一覧に出ない。Esc で閉じる

---

## 更新

1. brew で fzf を更新する。

   ```bash
   brew upgrade fzf
   ```

   - 開いているシェルには前の版の `fzf --bash` が読まれたまま。新しい端末から新しい版になる

---

## ロールバック

- fzf の実行ファイルは zoxide の `zi` と yazi の絞り込みにも使う。それらを使うならアンインストールしない
- キー操作だけ無効にする場合は bash リポジトリ側を変更する。`~/.bashrc` に重ねて設定しない

1. fzf を使うツールがほかに無いときだけ、アンインストールする。

   ```bash
   brew uninstall fzf
   ```

   - 依存の ncurses も、ほかに使うものが無ければ消える

1. 端末を閉じて開き直す。

   - 削除したツールの設定は、次のシェルでは共通設定から読み込まれない
   - `~/.bashrc` にツール別の行は書いていないので、削除も不要

---

## 補足

- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

### 対象と検証環境

- **目的**: AlmaLinux 10 の bash に [fzf](https://github.com/junegunn/fzf)（一覧から曖昧検索で選ぶコマンド）のキー操作と補完を組み込み、履歴・パス・ディレクトリを打ちかけの文字から選べるようにする
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **`0dbb522` の直接追記版の実施手順 1〜7・fd と bat の任意節を x86_64 のクリーン VM で本実行済み（2026-10-06）。コンテナでも検証済み（2026-10-02）**。共通 bash 設定へ統一した現行版の設定リポジトリの新規導入・既存設定からの移行は、今回の VM では実行していない。
  - 通したこと: SSH でログインした対話の bash に、この文書の bash のブロックをそのまま貼り、実施手順・任意節・[更新](#更新)・[ロールバック](#ロールバック)を、ブラケットペーストの無しと有りで 1 回ずつ通した（[付録](#付録-コンテナでの検証記録2026-10-02)）
  - 確認したこと
    - 手順 1〜3 の出力、手順 4〜7 のキー（tmux のペインに `C-r` / `C-t` / `M-c` / Tab を送って画面を読んだ）、[使い方の基本](#使い方の基本)の表、任意節のプレビュー、[ロールバック](#ロールバック)
    - `fzf --bash` が `PROMPT_COMMAND` などに触らないこと、非対話のシェルで何も出さないこと、2 回読んでも二重にならないこと
    - bash-completion の遅延読み込み（`git checko<Tab>`）と、[bash-settings.md 手順 4](bash-settings.md#実施手順) の Homebrew の補完の行との並び
  - **確認していないこと**
    - 実機（aarch64 の Raspberry Pi 5、x86_64 の PC）、GNOME 端末・WezTerm から送る Alt+C
    - `kill -9 <Tab>` の fzf の一覧（コンテナでは fzf でなく通常の PID の一覧が出た。理由は追っていない）
    - Homebrew の版が上がる[更新](#更新)

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
| `~/.bashrc` | `brew shellenv` の行と、[bash-settings.md](bash-settings.md) の 5 行 |

### 選択した方針

- **Homebrew の 0.74.4 にした**（[導入元一覧](tool-catalog.md)の規則。EPEL は 0.58.0）
  - `fzf --bash` は 0.48.0 からあるので EPEL の版でも同じ手順で動くはずだが、確かめていない。yazi・zoxide の依存ですでに Homebrew の fzf が入っているホストが多いので、揃える
- **`fzf --bash` で組み込む**: formula の caveat の案内で、fzf の `install` スクリプト（`~/.fzf.bash` と `~/.bashrc` への追記）は使わない。bash リポジトリの初期化がインストール済みの版に追従する
- **atuin は採らない**: 履歴を SQLite に持ち、別のホストと同期もできる履歴の検索ツール。Ctrl+R を取り合うので、どちらか 1 つにする。fzf は依存ですでに入っていて、履歴のほかにパスとディレクトリにも使えるので、こちらにした。atuin は[導入元一覧](tool-catalog.md#cli-定番の置き換え)の行のまま（試していない）
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

### 注意点

- **Homebrew 系に共通の注意**（PATH の先頭が Homebrew、`sudo fzf` はそのままでは見つからない）は [homebrew.md の注意点](homebrew.md#注意点)
- **readline の Ctrl+R と Ctrl+T は使えなくなる**: `reverse-search-history` と `transpose-chars`。Ctrl+S（前方の検索）は残る
- **Ctrl+R は実行しない**: 選んだ行がプロンプトに入るだけ。確かめてから Enter
- **Alt+C は端末しだい**: Alt を ESC の前置きで送らない端末では届かない。`ESC` を押してから `c` でも同じ
- **Homebrew の補完の行は fzf の行より前**（[bash-settings.md 手順 4](bash-settings.md#実施手順) の補足）
- **`**` の補完は、fzf が知っているコマンドだけ**: 一覧は手順 3 の補足。ほかのコマンドに付けるには `_fzf_setup_completion path <コマンド>`（README）
- **tmux の中でも同じキーで動く**: `M-c` は tmux のプレフィックスとぶつからない（`Ctrl+b` が既定）

### 参照

- [fzf — README](https://github.com/junegunn/fzf#readme)（Key bindings for command-line、Fuzzy completion for bash、Search syntax、Environment variables）
- [fzf — ADVANCED.md](https://github.com/junegunn/fzf/blob/master/ADVANCED.md)（プレビューの例）
- `man fzf`（`--preview`・`--line-range` は bat 側）
- [Homebrew の fzf の formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/f/fzf.rb)（caveat の `fzf --bash`）
- [bash の履歴・補完・キー操作](bash-settings.md) — bash-completion と Homebrew の補完、`~/.inputrc`。fzf の行との並び
- [zoxide](zoxide.md) — `zi` が fzf を使う。[yazi](yazi.md) — `z` / `Z` キーが fzf を使う
- [bat](bat.md) — プレビューに使う。[Homebrew](homebrew.md) — Homebrew 本体の導入と、Homebrew 系に共通の注意

---

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
- 1 回目はブラケットペースト無しで、2 回目は `paste-buffer -p`（ブラケットペースト有り。貼った後に Enter を送った）で、実施手順から[ロールバック](#ロールバック)まで通した。2 回の間に `brew uninstall fzf` と `brew autoremove` で実施前に戻した
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
