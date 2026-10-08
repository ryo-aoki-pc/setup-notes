# yazi 最新版インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- [検証記録](verification/yazi.md)・[参考資料](reference/yazi.md)

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **前提**: [AlmaLinux 10 の初期設定の手順 46〜48](almalinux-setup.md#実施手順) で Homebrew を入れてあること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わない）
> - **手順 4 で TUI が開く**。`q` で終了してから、ほかのコマンドを貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: 設定を書く場所と、自分用の設定（`ryo-aoki-pc/yazi`）への案内は[設定ファイル](#設定ファイル)。以後は[更新](#更新)・[ロールバック](#ロールバック)

1. 変数を設定する。

   ```bash
   YAZI_EXTRAS="ffmpeg-full sevenzip jq poppler fd ripgrep fzf resvg imagemagick-full font-symbols-only-nerd-font"   # プレビューと検索に使う。空にすると yazi 本体だけ
   printf 'YAZI_EXTRAS = %s\n' "${YAZI_EXTRAS}"
   ```

   - **編集が必須の変数は無い**。プレビュー・検索用のツールを一緒に入れる想定になっている
   - 最小構成にするなら、`YAZI_EXTRAS` を空にする
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. brew で yazi と、プレビュー・検索に使うツールを入れる。

   ```bash
   brew install yazi ${YAZI_EXTRAS}
   ```

   - 確認が出たら表示された導入予定を確かめて `y` と答え、処理が終わってプロンプトに戻ってから次の手順を貼る（[Homebrew の注意点](almalinux-setup.md#注意点)）
   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない

1. 共通設定を読み直し、y 関数を確かめる。

   ```bash
   . ~/.bashrc
   type -t y
   ```

   - `function` が出ればよい。`~/.bashrc` への関数の追記は不要
   - `y` は yazi を閉じたディレクトリへ移る。空白や日本語を含むパスも扱い、同じ場所なら移動し直さない

1. yazi が入ったか確かめ、`y` で起動する。

   ```bash
   yazi --version
   ya --version
   brew list --versions yazi
   y
   ```

   - `Version: 26.9.1 (Homebrew ...)`、`Triple: aarch64-unknown-linux-gnu` のように出る
   - `ya` は付属のプラグイン管理コマンド
   - 最後の `y` で起動して確認する
   - `y` で起動したときは、終了時にそのディレクトリへ移動する
   - プレビューを確かめるには、PDF・動画・画像・書庫のあるディレクトリで右ペインを見る
   - 画像プレビューは端末側の対応が要る（[注意点](#注意点)）
   - 画面が出たら `q` で終了する
   - **ほかのコマンドは、`q` で終了してから貼る**（続けて貼ると yazi への操作として食われる）

---

## 設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は `~/.config/yazi/` で、ファイル名は `yazi.toml`（全般）/ `keymap.toml`（キー割り当て）/ `theme.toml`（配色）
- **既定値のファイルは配布物に入っていない**。変更する項目だけを設定ファイルに書く
- 既定値は[公式ドキュメントの Configuration](https://yazi-rs.github.io/docs/configuration/overview/) か、リポジトリの `yazi-config/preset/` を見る
- **自分用の設定**は [ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi) にある（上流の既定の設定を丸ごと置き、3 ペインの比率・行表示・独自のキー割り当てなどを変えた設定）
  - 入れ方は [README の「インストール」](https://github.com/ryo-aoki-pc/yazi#インストール)。`custom` ブランチを `~/.config/yazi` に clone する
  - 足したキーは [設定のリポジトリの参考資料の「独自キーバインド」](https://github.com/ryo-aoki-pc/yazi/blob/custom/docs/reference/readme.md#独自キーバインド抜粋)、使う外部コマンドは[「依存コマンド」](https://github.com/ryo-aoki-pc/yazi#依存コマンド)
  - 外部コマンドのうち fd・ripgrep・fzf は手順 2 の `YAZI_EXTRAS` で入る（fzf の bash のキー操作は [AlmaLinux 10 の初期設定の手順 42〜53](almalinux-setup.md#実施手順) で入る）。エディタの nvim は [neovim.md](neovim.md)、zoxide は [AlmaLinux 10 の初期設定の手順 49](almalinux-setup.md#実施手順) で入れる
  - この設定を入れるなら、この節の手順 1 は要らない（clone が `~/.config/yazi` を作る）

1. 設定を書くときは、空のディレクトリを作って変更したい項目だけを書く。

   ```bash
   mkdir -p ~/.config/yazi
   ```

   - プラグインとテーマは `ya pkg add`（引数はリポジトリ名）で入れる。`~/.config/yazi/package.toml` に記録される
   - 本書ではプラグインは扱っていない

---

## 更新

1. brew で yazi を更新する。

   ```bash
   brew upgrade yazi
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - `brew outdated` で先に確認できる

---

## ロールバック

1. brew で yazi を消す。

   ```bash
   brew uninstall yazi
   ```

   - 依存ツール（`YAZI_EXTRAS` で入れたもの）は他でも使うので、消すなら個別に指定する
   - 端末を開き直すと、yazi が無ければ共通設定は `y()` を定義しない。`~/.config/yazi/` は残るので、不要な場合だけ別に消す

---

## 注意点

- **Homebrew 全般の注意は [AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)**: PATH の先頭が Homebrew になる（同名のコマンドは RPM 版より Homebrew 版が勝つ）、`sudo yazi` はそのままでは使えない（root で使うなら、[AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通すか、フルパスで呼ぶ）、など
  - RPM 版と両方入れると分かりにくくなるので、どちらか一方にする
- **画像プレビューは端末に依存する**: Kitty / WezTerm / foot などのグラフィックプロトコル、または Überzug++ が要る。GNOME 端末では文字ベースの表示になる
- **`q` と `Q`**: `y` 関数経由なら `q` で終了時にそのディレクトリへ移動し、`Q` なら移動しない
- **Homebrew の更新は自分の責任で**: `brew upgrade` は指定しなければ全 formula を上げる。yazi だけ上げるなら `brew upgrade yazi`
