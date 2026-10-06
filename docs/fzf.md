# fzf インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- [検証記録](verification/fzf.md)・[参考資料](reference/fzf.md)

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わない）
> - **手順 1 には対話入力があることがある**（依存の `ncurses` がまだ無いときの `[y/n]`）
> - **手順 4〜7 はキーを押す操作**（コマンドのブロックは無い）
> - [bash の履歴・補完・キー操作](bash-settings.md)を先に通してあると、Homebrew のコマンドの補完と fzf の `**<Tab>` が両方効く。後から通しても、同書の手順 4 が fzf の行の前に差し込む

- 上から順にコードブロックを貼る。変数は無い
- 手順の後: キーと検索の書き方は[使い方の基本](#使い方の基本)。候補を fd に、プレビューを bat にするなら [fd と bat を候補とプレビューに使う（任意）](#fd-と-bat-を候補とプレビューに使う任意)。以後は[更新](#更新)・[ロールバック](#ロールバック)

1. brew で fzf を入れる。

   ```bash
   brew install fzf
   ```

   - [yazi.md 手順 2](yazi.md#実施手順) か [zoxide.md 手順 2](zoxide.md#実施手順) で入れてあるホストでは `Warning: fzf 0.74.4 is already installed and up-to-date.` と出る。それでよい（参考資料を参照）
   - 依存の `ncurses` がまだ無いときは、`Do you want to proceed with the installation? [y/n]` と聞かれる。`y`（Enter は要らない）
   - **次の手順は、`y` と答えてプロンプトに戻ってから貼る**（続けて貼ると、後ろの行の文字が答えとして読まれる）

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
   - 端末が Alt を ESC の前置きとして送る設定のときに届く
   - `cd -` で元のディレクトリに戻る

---

## 使い方の基本

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

## 注意点

- **Homebrew 系に共通の注意**（PATH の先頭が Homebrew、`sudo fzf` はそのままでは見つからない）は [homebrew.md の注意点](homebrew.md#注意点)
- **readline の Ctrl+R と Ctrl+T は使えなくなる**: `reverse-search-history` と `transpose-chars`。Ctrl+S（前方の検索）は残る
- **Ctrl+R は実行しない**: 選んだ行がプロンプトに入るだけ。確かめてから Enter
- **Alt+C は端末しだい**: Alt を ESC の前置きで送らない端末では届かない。`ESC` を押してから `c` でも同じ
- **Homebrew の補完の行は fzf の行より前**（[bash-settings.md 手順 4](bash-settings.md#実施手順) の補足）
- **`**` の補完は、fzf が知っているコマンドだけ**: 一覧は手順 3 の補足。ほかのコマンドに付けるには `_fzf_setup_completion path <コマンド>`（README）
- **tmux の中でも同じキーで動く**: `M-c` は tmux のプレフィックスとぶつからない（`Ctrl+b` が既定）
