# Neovim 最新版インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew は root で動かない）
> - **手順 2 で TUI が開く**。`:q` で終了してから、ほかのコマンドを貼る

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 既定のエディタにするなら[既定のエディタにする（任意）](#既定のエディタにする任意)。設定を書く場所と、自分用の設定（`ryo-aoki-pc/LazyVimStarter`）への案内は[設定ファイル](#設定ファイル)、以後は[更新](#更新)・[ロールバック](#ロールバック)

1. brew で Neovim を入れる。

   ```bash
   brew install neovim
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - 依存（`libuv` / `lpeg` / `luajit` / `luv` / `tree-sitter` / `unibilium` / `utf8proc`）も一緒に入る

   <details>
   <summary>補足: ボトルが降りること</summary>

   ボトルが降りたことの確認（実測、コンテナ）:

   ```
   ==> Installing neovim dependency: luajit
   ==> Pouring luajit--2.1.1788856981.arm64_linux.bottle.tar.gz
   ==> Installing neovim dependency: tree-sitter
   ==> Pouring tree-sitter--0.27.0.arm64_linux.bottle.tar.gz
   ==> Installing neovim
   ==> Pouring neovim--0.12.5_1.arm64_linux.bottle.tar.gz
   ```

   `brew deps neovim` は `libuv` / `lpeg` / `luajit` / `luv` / `tree-sitter` を返す（実際の導入時は `unibilium` と `utf8proc` も入る）。

   </details>

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

   <details>
   <summary>補足: <code>:checkhealth</code> の読み方</summary>

   `:checkhealth` は「使っていない機能の WARNING」を大量に出す。素の状態で出るのは主に次の 3 種類:

   - `vim.provider`: node / perl / python3 / ruby のプロバイダが無い。それぞれの言語で書かれたプラグインを使わないなら無視してよい（`vim.g.loaded_node_provider = 0` などで黙らせられる）
   - `vim.deprecated`: プラグインが古い API を使っている
   - ツールの不足: `rg`（ripgrep）、`fd`、`git`、`tree-sitter` など。このホストでは `rg` / `fd` / `git` は入っている（[yazi.md](yazi.md) の依存ツール、および RPM の git）

   `ERROR` が出ていなければ、日常の編集には支障がない。

   </details>

---

## 既定のエディタにする（任意）

1. `EDITOR` を見るツール（git、lazygit、`crontab -e` など）で Neovim を開くようにする。

   ```bash
   cat >> ~/.bashrc <<'EOF'
   export EDITOR=nvim
   export VISUAL=nvim
   alias vi=nvim
   EOF
   . ~/.bashrc
   printf '%s / %s\n' "${EDITOR}" "${VISUAL}"
   ```

   - `sudo` 経由のエディタ（`sudoedit`、`visudo`）は root の PATH を使うので、Homebrew 版の `nvim` は見えない
   - 必要なら `sudo EDITOR=/home/linuxbrew/.linuxbrew/bin/nvim visudo` のようにフルパスを渡す
   - root のシェル（`su -`、root のログイン、`sudo -i`）で `nvim` を使うなら、[homebrew.md の root のシェルでも使う](homebrew.md#root-のシェルでも使う任意)の節を通す。root の Neovim は `/root/.config/nvim` を読む

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

---

## ロールバック

- 本書ではロールバックは**本実行していない**

1. brew で Neovim を消す。

   ```bash
   brew uninstall neovim
   ```

   - 依存（`luajit` / `tree-sitter` など）は他の formula も使うので、自動では消えない。まとめて掃除するなら `brew autoremove`
   - `~/.config/nvim`、`~/.local/share/nvim`（プラグイン）、`~/.local/state/nvim`（undo・swap）は残るので、要らなければ手で消す
   - 自分用の設定（LazyVimStarter）を入れていれば、その [docs/setup.md の「ロールバック」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#ロールバック)で、退避した設定に戻す

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [Neovim](https://neovim.io/) の最新版（0.12 系）を入れる。EPEL の `neovim` は 0.10.1 で 2 マイナーぶん古い
- **進め方**: Homebrew で入れる。**読者が書き換える値は実質無い**
- **状態**: **実機で本実行済み（2026-09-20）**
  - 下表のホストで `brew install neovim` を実行し、`neovim 0.12.5_1` が入って常用中
  - [Homebrew の導入](homebrew.md)と手順 1〜2、[既定のエディタにする](#既定のエディタにする任意)・[設定ファイル](#設定ファイル)の節は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - 確認したこと: ボトルが降りる、`nvim --version` が出る、`EDITOR` / `VISUAL` が `nvim` になる、`init.lua` を置いた状態で `has("nvim")` が `1` を返す
  - **コンテナでは TUI の起動と `:checkhealth` は確認していない**（端末が無いため、検証時はこの 1 行だけ除いた）
  - **実機には `~/.config/nvim` も `EDITOR` の設定も置いていない**

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| 入った Neovim | `neovim 0.12.5_1`（`arm64_linux` ボトル、LuaJIT 2.1.1788856981） | 同じ（`0.12.5_1`） |
| 一緒に入る依存 | `libuv` / `lpeg` / `luajit` / `luv` / `tree-sitter` / `unibilium` / `utf8proc` | 同左 |
| 追加で入れたもの | `tree-sitter-cli 0.27.0`（任意。パーサをソースからビルドする場合に使う） | 無し |

> [!NOTE]
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`0.12.5`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| Neovim / vim | `nvim` 未導入。`vim-minimal`（`vi`）のみ |
| Homebrew | この手順の直前に公式インストーラで導入（`brew install neovim` が最初の formula） |
| EPEL | 有効。`neovim 0.10.1-4.el10_0` が入手できる状態 |
| Node.js / Python プロバイダ | 未導入 |

### 選択した方針

AlmaLinux 10 aarch64 で Neovim の最新版を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `neovim 0.12.5_1` の `arm64_linux` ボトルがある。upstream の最新リリース（v0.12.5、2026-08-23）と一致。依存も同時に入る | **採用** |
| EPEL の `neovim` | `0.10.1-4.el10_0`。2 マイナーぶん古く、0.11 / 0.12 の機能（新しい LSP API など）が無い | 不採用（最新版ではない） |
| 公式 tarball（`nvim-linux-arm64.tar.gz`） | GitHub Releases に aarch64 向けがある。`/opt` に展開して PATH を通すだけ。EL10 の glibc 2.39 で動く見込みだが、更新は手作業 | 不採用（更新が手作業） |
| AppImage（`nvim-linux-arm64.appimage`） | 実行に FUSE が要る（EL10 には `fuse-libs` がある）。更新は手作業 | 不採用 |
| ソースビルド | `make CMAKE_BUILD_TYPE=Release`。依存を自分で揃える必要があり、Raspberry Pi では時間がかかる | 不採用 |

実測（EPEL 有効の状態）:

```
$ dnf -q list --available neovim
Available Packages
neovim.aarch64                       0.10.1-4.el10_0                        epel
```

### 完了時点の状態

```
$ brew list --versions neovim
neovim 0.12.5_1
$ nvim --version | head -3
NVIM v0.12.5
Build type: Release
LuaJIT 2.1.1788856981
$ command -v nvim
/home/linuxbrew/.linuxbrew/bin/nvim
$ brew deps neovim
libuv
lpeg
luajit
luv
tree-sitter
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/neovim/0.12.5_1/`。設定を置くまで `~/.config/nvim` は作られない。

### 注意点

- **EPEL の `neovim` と両方入れない**: PATH の先頭が Homebrew なので、Homebrew 版が勝つ（[homebrew.md の注意点](homebrew.md#注意点)）。どちらか一方にする
- **`sudo nvim` は動かない**: root の PATH に Homebrew が無い（[homebrew.md の注意点](homebrew.md#注意点)）
  - `sudoedit` や `visudo` で使うならフルパスを `EDITOR` に渡す
  - root のシェル（`su -`、root のログイン、`sudo -i`）で使うなら、[homebrew.md の root のシェルでも使う](homebrew.md#root-のシェルでも使う任意)の節を通す（`sudo nvim` は、その節を通しても動かない）
- **プロバイダは別途**: Python / Node.js のプラグインを使うなら、それぞれ `pynvim` / `neovim` パッケージを入れる。このホストには Node.js が無い
- **設定とプラグインは更新に追従しない**: `brew upgrade neovim` でメジャー版が上がると、古い API を使うプラグインが壊れることがある
- **`vi` は RPM の `vim-minimal`**: 別物が `/usr/bin/vi` として残っている。エイリアスを張らない限り `vi` は Neovim にならない

### 参照

- [Install Neovim](https://neovim.io/doc/install/) — 公式が案内する各経路（tarball / AppImage / パッケージマネージャ）
- [neovim/neovim — INSTALL.md](https://github.com/neovim/neovim/blob/master/INSTALL.md) — tarball の展開先と PATH の通し方、glibc の要件
- `:help nvim-defaults` / `:help checkhealth` — 既定値と健全性チェックの読み方
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作
- [ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter) — 自分用の設定（LazyVim ベース）。導入の手順は [docs/setup.md](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md)

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで、非 root ユーザーを作って[Homebrew の導入](homebrew.md)と手順 1〜2、[既定のエディタにする](#既定のエディタにする任意)・[設定ファイル](#設定ファイル)の節を通した。実機で加えた変更は `dnf install podman` だけ。 実行したのは**この文書のコードブロックをそのまま抜き出したスクリプト**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。 端末が要る `nvim -c 'checkhealth' -c 'only'` の 1 行だけ除いている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git sudo` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](homebrew.md)） |
| 1. Neovim | `lpeg` / `luajit` / `luv` / `tree-sitter` / `unibilium` / `utf8proc` / `neovim` の順に `arm64_linux` ボトルを `Pouring`。ソースビルドは発生しない |
| 2. 検証 | `nvim --version` → `NVIM v0.12.5` / `Build type: Release` / `LuaJIT 2.1.1788856981` |
| 既定のエディタ | `~/.bashrc` に追記して読み込み直し、`EDITOR` / `VISUAL` ともに `nvim` |
| 設定ファイル | `~/.config/nvim/init.lua` を置いて `nvim -c 'echo has("nvim")' -c 'q'` → `1` |
| EPEL との比較 | `dnf list --available neovim` → `0.10.1-4.el10_0`（EPEL）。Homebrew 版と 2 マイナーぶんの差 |

#### 未確認事項

- TUI の起動と `:checkhealth` の実出力（コンテナに端末が無いため。実機では常用している）
- [設定ファイル](#設定ファイル)と[既定のエディタにする](#既定のエディタにする任意)の節（実機では `~/.config/nvim` も `EDITOR` の設定も置いていない）
- LSP・プラグインマネージャ（lazy.nvim など）を入れた状態での動作
- 公式 tarball / AppImage 経路の実測
- ロールバック（`brew uninstall`、`brew autoremove`）の本実行
