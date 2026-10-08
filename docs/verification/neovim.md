# Neovim 最新版インストール手順（AlmaLinux 10 / Homebrew）の検証記録

[手順書](../neovim.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順 / 手順 1: 補足: ボトルが降りること

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

### ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**



- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

### 対象と検証環境

- **目的**: AlmaLinux 10 に [Neovim](https://neovim.io/) の最新版（0.12 系）を入れる。EPEL の `neovim` は 0.10.1 で 2 マイナーぶん古い
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **実機で本実行済み（2026-09-20）。`0dbb522` の直接追記版の実施手順 1・2 を x86_64 のクリーン VM でも本実行済み（2026-10-06）**。現行版 `5da3478` は、共通 bash 新規導入後の別の VM でも再検証した（末尾の再検証記録）。既存ホストの手動移行は行っていない。
  - 下表のホストで `brew install neovim` を実行し、`neovim 0.12.5_1` が入って常用中
  - [Homebrew の導入](../almalinux-setup.md)と手順 1〜2、[既定のエディタにする](../neovim.md#既定のエディタにする任意)・[設定ファイル](../neovim.md#設定ファイル)の節は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - 確認したこと: ボトルが降りる、`nvim --version` が出る、`EDITOR` / `VISUAL` が `nvim` になる、`init.lua` を置いた状態で `has("nvim")` が `1` を返す
  - **コンテナでは TUI の起動と `:checkhealth` は確認していない**（端末が無いため、検証時はこの 1 行だけ除いた）
  - **実機には `~/.config/nvim` も `EDITOR` の設定も置いていない**
  - `sudo nvim`・`sudoedit`・`visudo` で開くエディタは、2026-10-02 に x86_64 のコンテナで確かめた（[homebrew.md の付録](almalinux-setup.md#homebrew-付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)）
  - 2026-10-05: 既定のエディタの設定に元値の控えと追記の目印を付け、ロールバックの手順 1 を追加した。一時ファイルで、元値なし・既存値あり・`.bashrc` がリンクの 3 通りを確認し、元値・元の本文・リンクを復元できた（パッケージの導入・削除は未実行）

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

### 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで、非 root ユーザーを作って[Homebrew の導入](../almalinux-setup.md)と手順 1〜2、[既定のエディタにする](../neovim.md#既定のエディタにする任意)・[設定ファイル](../neovim.md#設定ファイル)の節を通した。実機で加えた変更は `dnf install podman` だけ。 実行したのは**この文書のコードブロックをそのまま抜き出したスクリプト**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。 端末が要る `nvim -c 'checkhealth' -c 'only'` の 1 行だけ除いている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git sudo` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](../almalinux-setup.md)） |
| 1. Neovim | `lpeg` / `luajit` / `luv` / `tree-sitter` / `unibilium` / `utf8proc` / `neovim` の順に `arm64_linux` ボトルを `Pouring`。ソースビルドは発生しない |
| 2. 検証 | `nvim --version` → `NVIM v0.12.5` / `Build type: Release` / `LuaJIT 2.1.1788856981` |
| 既定のエディタ | `~/.bashrc` に追記して読み込み直し、`EDITOR` / `VISUAL` ともに `nvim` |
| 設定ファイル | `~/.config/nvim/init.lua` を置いて `nvim -c 'echo has("nvim")' -c 'q'` → `1` |
| EPEL との比較 | `dnf list --available neovim` → `0.10.1-4.el10_0`（EPEL）。Homebrew 版と 2 マイナーぶんの差 |

#### 未確認事項

- TUI の起動と `:checkhealth` の実出力（コンテナに端末が無いため。実機では常用している）
- [設定ファイル](../neovim.md#設定ファイル)と[既定のエディタにする](../neovim.md#既定のエディタにする任意)の節（実機では `~/.config/nvim` も `EDITOR` の設定も置いていない）
- LSP・プラグインマネージャ（lazy.nvim など）を入れた状態での動作
- 公式 tarball / AppImage 経路の実測
- ロールバック（`brew uninstall`、`brew autoremove`）の本実行

---

### 付録: クリーン VM での検証記録（2026-10-06）

**検証対象**: `0dbb522` の、各手順で `~/.bashrc` などへ設定を直接追記する版。以下の手順番号と「本文」はこの版を指す。検証後に共通 bash 設定へ統一された現行版（`0bc9970`）の設定リポジトリの新規導入・既存設定からの移行は、今回の VM では実行していない。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証対象版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順（`0dbb522`）**: 実施手順 1・2。

**結果**: Homebrew の neovim 0.12.5_1（`NVIM v0.12.5`）を導入し、実際の TUI で `checkhealth` を完了した。エラーは無かった。クリーン状態の `init.lua` 不在、SSH のクリップボード用コマンド不在、Node.js・Perl・Python・Ruby の任意 provider の不足で合計 8 件の警告が出た。診断の内容を取得してから `:q!` で終了した。

**今回の未確認範囲**: 任意のエディタ環境変数・設定ファイル、LazyVim・Mason・LSP・プラグイン、デスクトップのクリップボード、更新・ロールバックはこの VM では確認していない。

### 付録: 現行の共通 bash 設定での再検証（2026-10-06）

- `5da3478` の 実施手順 1 と「既定のエディタにする」手順 1を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で実行した。先に共通 bash `3d5323e` を新規導入した
- Neovim 0.12.5（formula 0.12.5_1）を bottle で導入した。7 個の依存も bottle だった。`EDITOR` / `VISUAL` は nvim、`vi` は nvim のエイリアスになった
- `nvim --clean` の実 TUI でテキストを開き、`:qa` で終了した。個人設定・Mason・検索・整形の検証は [LazyVimStarter の新規 CLI VM 記録](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/verification/setup.md#付録-新規-almalinux-102-vm-での-cli-導入整形の再検証2026-10-06) へ分ける
- 本体の単独 checkhealth の全項目、更新、削除、最小 init.lua の任意節は、この再検証では実行していない

### 選択した方針

```
$ dnf -q list --available neovim
Available Packages
neovim.aarch64                       0.10.1-4.el10_0                        epel
```

### 実施手順 / 手順 2: 補足: :checkhealth の読み方

- ツールの不足: `rg`（ripgrep）、`fd`、`git`、`tree-sitter` など。このホストでは `rg` / `fd` / `git` は入っている（[yazi.md](../yazi.md) の依存ツール、および RPM の git）
