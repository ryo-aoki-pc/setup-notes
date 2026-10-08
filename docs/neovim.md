# Neovim 最新版インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- [検証記録](verification/neovim.md)・[参考資料](reference/neovim.md)

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **前提**: [AlmaLinux 10 の初期設定の手順 46〜48](almalinux-setup.md#実施手順) で Homebrew を入れてあること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。Homebrew の導入・管理と自分の設定は、`sudo -i` した root のシェルでは行わない
> - **手順 1 で Homebrew の確認が出る場合がある**。答えて導入が完了してから手順 2 を貼る
> - **手順 2 で TUI が開く**。`:q` で終了してから、ほかのコマンドを貼る

- 上から順にコードブロックを貼る
- 手順の後: 既定のエディタにするなら[既定のエディタにする（任意）](#既定のエディタにする任意)。設定を書く場所と、自分用の設定（`ryo-aoki-pc/LazyVimStarter`）への案内は[設定ファイル](#設定ファイル)、以後は[更新](#更新)・[ロールバック](#ロールバック)

1. brew で Neovim を入れる。

   ```bash
   brew install neovim
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - 依存（`libuv` / `lpeg` / `luajit` / `luv` / `tree-sitter` / `unibilium` / `utf8proc`）も一緒に入る
   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. Neovim が入ったか確かめ、起動して健全性を確認する。

   ```bash
   nvim --version | head -3
   brew list --versions neovim
   command -v nvim
   nvim -c 'checkhealth' -c 'only'
   ```

   - `NVIM v0.12.5` と `LuaJIT 2.1...` が出れば入っている
   - 最後の行で起動して、`:checkhealth` で健全性を確認する
   - `vim.provider` の node / perl / python / ruby が `WARNING` になるのは、それぞれの言語のプロバイダを入れていないため（[注意点](#注意点)）
   - 画面が出たら `:q` で終了する
   - **ほかのコマンドは、`:q` で終了してから貼る**（続けて貼ると Neovim への入力として食われる）

---

## 既定のエディタにする（任意）

- この節では、bash リポジトリが持つ既定のエディタ設定を確認する

1. 共通設定を読み直し、既定のエディタを確かめる。

   ```bash
   . ~/.bashrc
   printf '%s / %s\n' "$EDITOR" "$VISUAL"
   alias vi
   ```

   - `nvim / nvim` と `alias vi='nvim'` が出ればよい
   - この 3 項目は共通設定が持つ。元値の控えや `~/.bashrc` への追記は行わない

---

## 設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値（素の Vim に近い挙動）で動く
- 置き場所は `~/.config/nvim` で、読み込まれるのは `init.lua` か `init.vim` のどちらか一方
  - `XDG_CONFIG_HOME` を設定していれば `$XDG_CONFIG_HOME/nvim` になる。別の場所を使うなら `XDG_CONFIG_HOME` か `NVIM_APPNAME` を設定する
- **自分用の設定**は [ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter) にある（LazyVim をベースに、日本語の入力・検索と Markdown（GLFM）の執筆を強くした設定）
  - 入れ方は [docs/setup.md の「AlmaLinux 10 に導入する」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#almalinux-10-に導入する-1-度だけ)。外部コマンド・日本語入力（ibus-anthy）・フォントも入れる
  - Homebrew と Neovim の導入（本書の手順 1）も、その手順に含まれる（`brew install neovim lazygit`）
  - 何ができるか・どこを変えたかは [README の「主なカスタマイズ」](https://github.com/ryo-aoki-pc/LazyVimStarter#主なカスタマイズ)
  - この設定を入れるなら、この節の手順 1 は要らない（docs/setup.md が既存の `~/.config/nvim` を `.bak` に退避してから clone する）
- インターネットに出られないホストで、Mason が npm で入れるパッケージ（LSP サーバー・リンター）を入れるなら、[npm-offline.md](npm-offline.md) を通す

1. 最小の例として、`init.lua` を置く。

   ```bash
   mkdir -p ~/.config/nvim
   cat > ~/.config/nvim/init.lua <<'EOF'
   vim.opt.number = true
   vim.opt.expandtab = true
   vim.opt.shiftwidth = 2
   EOF
   nvim -c 'echo has("nvim")' -c 'q'
   ```

   - 設定の探索先は `nvim -c ':echo stdpath("config")' -c 'q'` で確認できる
   - LazyVim / NvChad などのディストリビューションを入れる場合も、同じ場所に置く

---

## 更新

1. brew で Neovim を更新する。

   ```bash
   brew upgrade neovim
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - **設定やプラグインは更新に追従しない**ので、メジャー更新のあとは `:checkhealth` で壊れていないか見る
   - **ほかのコマンドは、Homebrew の確認が出たら答え、更新が終わってから貼る**（続けて貼ると確認の答えとして食われる）

---

## ロールバック

- 自分用の bash 設定で Neovim を指定している場合は、先にそちらの `EDITOR`・`VISUAL`・`vi` を変更する

1. 既定のエディタの扱いを確認する。

   - 本書ではエディタ設定を `~/.bashrc` に書かないので、追記の削除は不要
   - この節の手順 2 の後に端末を開き直すと、Neovim が無ければ共通設定はエディタを変更しない
   - 別の場所にも `nvim` がある場合は引き続き使われる。個別の変更は共通設定側で行う

1. brew で Neovim を消す。

   ```bash
   brew uninstall neovim
   ```

   - 他の formula が使う依存は残る。不要になった依存は Homebrew が自動で削除する場合がある（[Homebrew の注意点](almalinux-setup.md#注意点)）。残った不要な依存を整理する操作は `brew autoremove`
   - `~/.config/nvim`、`~/.local/share/nvim`（プラグイン）、`~/.local/state/nvim`（undo・swap）は残るので、要らなければ手で消す
   - 自分用の設定（LazyVimStarter）を入れていれば、その [docs/setup.md の「ロールバック」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#ロールバック)で、退避した設定に戻す

---

## 注意点

- **EPEL の `neovim` と両方入れない**: PATH の先頭が Homebrew なので、Homebrew 版が勝つ（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）。どちらか一方にする
- **`sudo nvim` は、そのままでは動かない**: sudo の PATH に Homebrew が無い（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）
  - [AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通すと動く。root の Neovim は `/root/.config/nvim` を読む
  - root のファイルを自分の設定で編集するなら、`sudo nvim` ではなく `sudoedit` を使う（その節を通すか、`SUDO_EDITOR` にフルパスを渡す。[既定のエディタにする](#既定のエディタにする任意)）
  - root のシェル（`su -`、root のログイン、`sudo -i`）で使うなら、[AlmaLinux 10 の初期設定の Homebrew を root のシェルでも使う](almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節を通す（`sudo nvim` は、その節だけでは動かない）
- **プロバイダは別途**: Python / Node.js のプラグインを使うなら、それぞれ `pynvim` / `neovim` パッケージを入れる。このホストには Node.js が無い
- **設定とプラグインは更新に追従しない**: `brew upgrade neovim` でメジャー版が上がると、古い API を使うプラグインが壊れることがある
- **`vi` は RPM の `vim-minimal`**: 別物が `/usr/bin/vi` として残っている。エイリアスを張らない限り `vi` は Neovim にならない
