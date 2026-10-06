# bat 最新版インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- [検証記録](verification/bat.md)・[参考資料](reference/bat.md)

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、設定も自分の `~/.config` に書くため）

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: `man` や `fzf` のプレビューに使うなら[ページャに使う（任意）](#ページャに使う任意)。設定は[設定ファイル](#設定ファイル)、以後は[更新](#更新)・[ロールバック](#ロールバック)

1. 変数を設定する。

   ```bash
   BAT_THEME_NAME=ansi               # 使うテーマ。ansi は端末の 16 色にそのまま従う。<BAT_THEME_NAME>
   printf 'BAT_THEME_NAME = %s\n' "${BAT_THEME_NAME}"
   ```

   - **編集が必須の変数は無い**。既定のまま進められる
   - 端末の配色に合わせたいときだけ `BAT_THEME_NAME` を変える（候補は[設定ファイル](#設定ファイル)の `bat --list-themes` で出る）
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. brew で bat を入れる。

   ```bash
   brew install bat
   ```

   - 確認が出たら表示された導入予定を確かめて `y` と答え、処理が終わってプロンプトに戻ってから次の手順を貼る（[Homebrew の注意点](homebrew.md#注意点)）
   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - 依存の `libgit2` と `oniguruma`、その先の `openssl@3` などもまとめて入る

1. bat が入ったことと、色と行番号が付くことを確かめる。

   ```bash
   bat --version
   brew list --versions bat
   command -v bat
   bat --color=always --style=numbers /etc/os-release | head -5
   ```

   - 版は `bat 0.26.1` のように出る
   - 最後の行で、色と行番号が付くことを確かめる
   - 行番号付きで `NAME="AlmaLinux"` から 5 行出る
   - **`--color=always` を外してパイプに繋ぐと、装飾の無い `cat` と同じ出力になる**。この確認で明示的に付けているのはそのため

---

## ページャに使う（任意）

- `MANPAGER` は端末が要る

1. 共通設定を読み直し、man のページャを確かめる。

   ```bash
   . ~/.bashrc
   printf '%s\n' "$MANPAGER"
   ```

   - `bat -plman` が出ればよい。[bat の公式 README](https://github.com/sharkdp/bat#man) と同じ形で、man の SGR を直接 bat へ渡す。従来の `col -bx` を挟む形は、AlmaLinux 10.2 の `man bash` で `1mNAME0m` などの断片が出た
   - `MANPAGER` は共通設定が持つので `~/.bashrc` には追記しない

1. `fzf` を入れてあるときだけ、ファイル選択のプレビューにも bat を使う。

   ```bash
   fzf --preview 'bat --color=always --style=numbers {}'
   ```

   - `fzf` の導入と bash への組み込みは [fzf.md](fzf.md)。Ctrl+T で選ぶときに同じプレビューを出すのは、同書の[任意節](fzf.md#fd-と-bat-を候補とプレビューに使う任意)

---

## 設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は `~/.config/bat/config`（`bat --config-file` で確認できる）
  - 既定の場所に置く限り bat は自分で見つける。別の場所に置きたいときだけ `BAT_CONFIG_PATH` を `~/.bashrc` に `export` する

1. よく変える 3 つだけを書いた、最小の設定ファイルを置く。

   ```bash
   if [ -z "${BAT_THEME_NAME}" ]; then echo '中断: 手順 1 の BAT_THEME_NAME が空のまま。値を入れて貼り直す' >&2; else
     mkdir -p ~/.config/bat
     cat > ~/.config/bat/config <<EOF
   --theme="${BAT_THEME_NAME:?手順 1 の BAT_THEME_NAME が空のまま。値を入れて貼り直す}"
   --style="numbers,changes,header"
   --paging=never
   EOF
     cat ~/.config/bat/config
     bat --config-file
   fi
   ```

   - テーマの一覧は `bat --list-themes`、認識する言語の一覧は `bat --list-languages`
   - 自前のシンタックス定義やテーマを足したときだけ `bat cache --build` が要る（キャッシュの場所は `bat --cache-dir`）
   - `中断:` と出たら、何も書いていない

---

## 更新

1. brew で bat を更新する。

   ```bash
   brew upgrade bat
   ```

   - すべてまとめて上げるなら `brew upgrade`

---

## ロールバック

1. brew で bat を消す。

   ```bash
   brew uninstall bat
   ```

   - 依存として入った `libgit2` / `oniguruma` は、他の formula（[eza](eza.md) / [git-delta](git-delta.md)）が必要とする間は残る。Homebrew 7 では、不要になった依存は `brew uninstall` の後に自動で削除される。自動削除を無効にしていた場合は、`brew autoremove --dry-run` で対象を確認してから `brew autoremove` を使う

1. 設定とキャッシュも消すときだけ、`~/.config/bat` と `~/.cache/bat` を消す。

   ```bash
   rm -rf ~/.config/bat ~/.cache/bat        # 設定とキャッシュも消す場合
   ```

1. 端末を閉じて開き直す。

   - 削除したツールの設定は、次のシェルでは共通設定から読み込まれない
   - `~/.bashrc` にツール別の行は書いていないので、削除も不要

---

## 注意点

- **`alias cat=bat` は勧めない**。`bat` と打つ運用を勧める
  - bat は既定でページャ（`less`）を開くので、`cat` のつもりで打つと画面が切り替わる
  - `-A` / `-v` / `-e` などフラグの意味も GNU `cat` と違う
  - エイリアスは対話シェルにしか効かないのでスクリプトは壊れないが、**壊れないぶん挙動の違いに気づきにくい**
- **EPEL 版と二重に入れない**: どちらも `bat` という名前で、PATH の先頭にある Homebrew 版が勝つ。[選択した方針](verification/bat.md#選択した方針)を参照
- **Homebrew 全般の注意は [homebrew.md の注意点](homebrew.md#注意点)**: PATH の先頭が Homebrew になる、`sudo bat` はそのままでは使えない、など
- **root で読むなら `sudo cat`**: bat で読むなら、[homebrew.md の sudo でも使う](homebrew.md#sudo-でも使う任意)の節を通すか、フルパスで `sudo /home/linuxbrew/.linuxbrew/bin/bat`
- **テーマの見え方は端末に依存する**: `ansi` 以外を選ぶと端末の配色とぶつかることがある。true color が出るかは端末側の設定次第
