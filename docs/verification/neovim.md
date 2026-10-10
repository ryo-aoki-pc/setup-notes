# Neovim 最新版インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は scoop）の検証記録

[手順書](../neovim.md)・[ロールバックと注意点](../extra/neovim.md)

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

### Windows 11 で使う: 検証状況の記録

- **[Windows 11 で使う](../neovim.md#windows-11-で使う)・[Windows 11 の更新](../neovim.md#windows-11-の更新)・[Windows 11 のロールバック](../extra/neovim.md#windows-11-のロールバック)と、[既定のエディタにする（任意）](../neovim.md#既定のエディタにする任意)の手順 2・3 は、Windows 実機では未検証**（2026-10-08 に書いた。Windows を動かせないクラウドの Linux のコンテナで書き、どのブロックも Windows では貼っていない）
- 確かめた範囲は[対象と検証環境](#対象と検証環境)の「状態（Windows 11）」と[付録](#付録-windows-11-の節の資料と-linux-での確認2026-10-08)

### 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に [Neovim](https://neovim.io/) の最新版（0.12 系）を入れる
  - AlmaLinux 10 では、EPEL の `neovim` が 0.10.1 で 2 マイナーぶん古いので、Homebrew で入れる
  - Windows 11 では、scoop の main の `neovim` を自分のユーザーに入れる
- **進め方**
  - **AlmaLinux 10**（[実施手順](../neovim.md#実施手順)）: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
  - **Windows 11**（[Windows 11 で使う](../neovim.md#windows-11-で使う)）: 管理者ではない Windows PowerShell 5.1 に貼る。変数は無い。VC++ のランタイムが無ければ、wezterm-nightly.md の Windows 11 の手順 3 を管理者の窓で先に行う
    - PowerShell から起動するツール向けの `EDITOR`・`VISUAL` は、[既定のエディタにする（任意）](../neovim.md#既定のエディタにする任意)の手順 2・3 でユーザーの環境変数にする（Git Bash では共通の bash 設定が入れる）
- **状態（AlmaLinux 10）**: **実機で本実行済み（2026-09-20）。`0dbb522` の直接追記版の実施手順 1・2 を x86_64 のクリーン VM でも本実行済み（2026-10-06）**。現行版 `5da3478` は、共通 bash 新規導入後の別の VM でも再検証した（末尾の再検証記録）。既存ホストの手動移行は行っていない。
  - 下表のホストで `brew install neovim` を実行し、`neovim 0.12.5_1` が入って常用中
  - [Homebrew の導入](../almalinux-setup.md)と手順 1〜2、[既定のエディタにする](../neovim.md#既定のエディタにする任意)・[設定ファイル](../neovim.md#設定ファイル)の節は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - 確認したこと: ボトルが降りる、`nvim --version` が出る、`EDITOR` / `VISUAL` が `nvim` になる、`init.lua` を置いた状態で `has("nvim")` が `1` を返す
  - **コンテナでは TUI の起動と `:checkhealth` は確認していない**（端末が無いため、検証時はこの 1 行だけ除いた）
  - **実機には `~/.config/nvim` も `EDITOR` の設定も置いていない**
  - `sudo nvim`・`sudoedit`・`visudo` で開くエディタは、2026-10-02 に x86_64 のコンテナで確かめた（[homebrew.md の付録](almalinux-setup.md#homebrew-付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)）
  - 2026-10-05: 既定のエディタの設定に元値の控えと追記の目印を付け、ロールバックの手順 1 を追加した。一時ファイルで、元値なし・既存値あり・`.bashrc` がリンクの 3 通りを確認し、元値・元の本文・リンクを復元できた（パッケージの導入・削除は未実行）
- **状態（Windows 11）**: **Windows 実機では未検証（2026-10-08 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**:
    - 配布物の定義: scoop の main のバケットの `neovim.json`（2026-10-08 に取得。0.12.5）と、scoop 本体のソースが出すメッセージ（[付録](#付録-windows-11-の節の資料と-linux-での確認2026-10-08)）
    - 配布物: `nvim-win64.zip`（sha256 が `neovim.json` の値と一致）の中の `nvim.exe` などが `VCRUNTIME140.dll` を読み込むこと（`objdump -p` のインポート表）
    - PowerShell のブロック 8 個: Linux の PowerShell 7.5.3 の構文解析器（誤り 0）と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査（指摘 0）
    - 偽物の scoop と、ユーザーの環境変数を記録する偽物での模擬（Windows 11 で使うの手順 2〜4・更新・ロールバックの手順 1、既定のエディタにするの手順 2・3）。偽物の scoop のメッセージは scoop 本体のソースから写したもので、実際の scoop の出力ではない
    - 見直しの後に、ブロックを取り出し直して、構文・互換の検査と模擬をやり直した（[付録](#付録-windows-11-の節の資料と-linux-での確認2026-10-08)の「最後の確認」）
    - 2 回目の見直しの後にも、ブロックを取り出し直して、構文・互換の検査と模擬をやり直した（[付録](#付録-windows-11-の節の資料と-linux-での確認2026-10-08)の「2 回目の見直しの後の確認」）
    - Linux の Neovim 0.12.5（GitHub のリリースの `nvim-linux-x86_64.tar.gz`）で、`nvim --version` の先頭 3 行と、Windows 11 で使うの手順 4 の `stdpath` を書き出す行
  - **確かめていないこと**:
    - Windows で貼ること（すべての手順）と、scoop での導入・更新・削除
    - `VCRUNTIME140.dll` が無いときの表示（何も出さずに終わるか、システム エラーの窓が出るか）
    - Windows の `stdpath` の値と、Windows PowerShell 5.1 から `nvim` に渡る引数
    - `:checkhealth` の表示
    - ユーザーの環境変数 `EDITOR`・`VISUAL` が、新しい窓・WezTerm のタブ・lazygit の `e` キー・`git commit` に効くこと
    - winget の Neovim があるときの止め方、SSH のセッション、arm64 の Windows
    - 自分用の設定（LazyVimStarter）の Windows の導入との組み合わせ
  - 参考: Windows 11 の Git Bash で、共通の bash 設定が `EDITOR`・`VISUAL` を `nvim` にすることは、bash リポジトリの検証記録にある（[2026-10-01 の Git Bash の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-11-の-git-bash-での検証記録2026-10-01)・[2026-10-06 の Windows ホストの付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-ホストでの設定の再検証2026-10-06)）。この文書の手順としては流していない

AlmaLinux 10:

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

AlmaLinux 10 の実機（2026-09-20）。Windows 11 の PC は、[Windows 11 で使う](../neovim.md#windows-11-で使う)の手順 2 で確かめる。

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

AlmaLinux 10 の実機（2026-09-20）。Windows 11 は流していないので、記録は無い（入るものは、[Windows 11 で使う](../neovim.md#windows-11-で使う)の手順 4 の箇条書き）。

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

### 付録: Windows 11 の節の資料と Linux での確認（2026-10-08）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物の定義とソースを読み、手順書の PowerShell のブロックを Linux の PowerShell で確かめた記録。**Windows 実機では未検証**。

**資料**（2026-10-08 に取得）:

- scoop の `ScoopInstaller/Main` の `bucket/neovim.json`: `version` は `0.12.5`。64bit は `nvim-win64.zip`（`extract_dir` は `nvim-win64`）、arm64 は `nvim-win-arm64.zip`。`bin` は `bin\nvim.exe` と `bin\xxd.exe`。`suggest` は `{"vcredist": "extras/vcredist2022"}`（ランタイムは入れず、勧めるだけ）
- scoop 本体（`ScoopInstaller/Scoop` の `master`）の `lib/install.ps1`・`libexec/scoop-install.ps1`・`scoop-update.ps1`・`scoop-uninstall.ps1`: 手順書の箇条書きに書いた `'<名前>' (<版>) was installed successfully!`・`'<名前>' suggests installing '<候補>'.`・`'<名前>' (<版>) is already installed.`・`Scoop was updated successfully!`・`<名前>: <版> (latest version)`・`Latest versions for all apps are installed!`・`Running process detected, skip updating.`・`'<名前>' was uninstalled.`・`'<名前>' isn't installed.` の文字列。`scoop uninstall` は、そのアプリのフォルダーから動いているプロセスがあると、消さずに止まる
  - 更新で新しい版が無いときの表示は、最初は `The latest version of '<名前>' (<版>) is already installed.` と書いていた。この文字列は `scoop-update.ps1` の `update` の中にあるが、名前を指定した `scoop update <名前>` は、最新のアプリを `update` に渡さず、`<名前>: <版> (latest version)` と `Latest versions for all apps are installed! For more information try 'scoop status'` を出す（同じファイルの 440〜473 行目。見直しで読み直して、手順書を直した）
  - `Running process detected, skip updating.` も `update` の中にあり、新しい版があるときだけ出る

**配布物のインポート表**（`objdump -p` の `DLL Name`。Windows の実行ファイルは動かしていない）:

- GitHub のリリースの `nvim-win64.zip` の sha256 は `de8625ba…0de1` で、`neovim.json` の `hash` と一致した
- `bin\nvim.exe`・`bin\lua51.dll`・`bin\xxd.exe`・`bin\win32yank.exe` は、どれも `VCRUNTIME140.dll`（と `api-ms-win-crt-*`）を読み込む。`MSVCP140.dll` は読み込まない
- zip の `bin` には `DbgHelp.dll`・`lua51.dll`・`nvim.exe`・`tee.exe`・`win32yank.exe`・`xxd.exe` がある。scoop の `bin`（shim）は `nvim.exe` と `xxd.exe` だけ

**Linux の Neovim 0.12.5 で確かめたこと**（GitHub のリリースの `nvim-linux-x86_64.tar.gz`〔sha256 `bce0f56e…6875`〕を一時的な場所に展開し、`HOME` も一時的な場所にした）:

```
$ nvim --version | head -3
NVIM v0.12.5
Build type: Release
LuaJIT 2.1.1774638290
$ nvim --clean --headless "+lua io.stdout:write(vim.fn.stdpath('config'), '\n', vim.fn.stdpath('data'), '\n')" +qa
<一時的な HOME>/.config/nvim
<一時的な HOME>/.local/share/nvim
```

- `--version` の 3 行目が LuaJIT なので、Windows 11 で使うの手順 4 は `Select-Object -First 3` にした（`-First 2` では `Build type` までしか出ない）
- `stdpath` の行は、`--clean` でも置き場所を 2 行で書き出し、終了コード 0 で終わった。Windows では `%LOCALAPPDATA%\nvim` と `%LOCALAPPDATA%\nvim-data` になるはず（同じ配布物の `runtime/doc/starting.txt` の base-directories。キャッシュは `~/AppData/Local/Temp/nvim-data`、ログは `nvim-data` の `nvim.log`）だが、Windows では流していない

**構文と Windows PowerShell 5.1 との互換**（Linux の PowerShell 7.5.3 と PSScriptAnalyzer 1.25.0）:

- 手順書の `powershell` のブロック 8 個を取り出し、PowerShell 7.5.3 の構文解析器に通した（構文の誤り 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0（ほかの規則の指摘は、ASCII でない文字を含むブロックの BOM だけ）

**模擬**（Linux の PowerShell 7.5.3）:

- ブロックの文字列のうち、管理者の判定（`WindowsPrincipal`。Linux では使えない）を `$false` に、`[Environment]` のユーザーの環境変数（Linux の .NET では読み書きされない）を、値をハッシュテーブルに記録する偽物のクラスに置き換えた。`$env:WINDIR`・`$env:APPDATA`・`$env:TEMP` と `C:\Program Files\Git\usr\bin\file.exe` は一時的な場所にした。scoop は、渡った引数を記録してメッセージだけを出す偽物の `scoop.ps1`
- Windows 11 で使うの手順 2: `VCRuntime` は、偽物の `System32\vcruntime140.dll` の有無で `False` / `True` になった。PATH の先に別の `nvim` を置くと、`Nvim` に 2 つの場所が `, ` でつながって出た
- Windows 11 で使うの手順 4: Linux の Neovim で、上の 3 行・`(Get-Command nvim -All).Source` の 1 行・`stdpath` の 2 行が出た
- 既定のエディタにするの手順 2: 値が無いときは `EDITOR = nvim`・`VISUAL = nvim` を書いた。2 回目も同じ表示で、値は変わらなかった。`EDITOR` が `code` のときは `中断: ユーザーの環境変数 EDITOR か VISUAL に、nvim ではない値がある（code）` で止まり、値は変わらなかった
- 既定のエディタにするの手順 3: どちらも `nvim` のときは両方消えた。`EDITOR` が `code`・`VISUAL` が `nvim` のときは、`VISUAL` だけ消え、`EDITOR = code` が残った
- 更新とロールバックの手順 1: 偽物の scoop に `update`・`update neovim`・`uninstall neovim` が渡った。ロールバックの手順 1 の `Get-Command` の行は、PATH に `nvim` が無いときは何も出さなかった

**最後の確認**（見直しの後。レビューの指摘で手順書・検証記録・参考資料を直した後に、同じ Linux のコンテナで確かめ直した。**Windows 実機では未検証**）:

- 手順書の `powershell` のブロックを取り出し直した。neovim.md は 8 個で、中身は直す前と同じだった（直したのは箇条書きと 1 行の説明だけで、ブロックの位置だけが変わった）
- PowerShell 7.5.3 の構文解析器で、構文の誤りは 0。PSScriptAnalyzer 1.25.0 の 5.1 互換の 3 規則の指摘は 0。ほかの規則の指摘は、既定のエディタにするの手順 2 の BOM の 1 件だけ（ASCII でない文字を含む）
- 偽物の scoop を作り直した。メッセージは scoop 本体のソース（`master`。この日に取り直し、前の取得と同じだった）から写し、入っているアプリ・最新の版・動いているアプリを記録したファイルで出し分ける。実際の scoop の出力ではない
  - 前の模擬の偽物の scoop は、更新で新しい版が無いときに `The latest version of '<名前>' (1.0) is already installed.` を出していた。手順書の箇条書きに合わせて手で書いたもので、scoop の振る舞いから取ったものではない。そのため、前の模擬では手順書の誤りが見つからなかった
- 模擬の結果（16 通り。表示は偽物のもの）:
  - Windows 11 で使うの手順 2: `VCRuntime` は、偽物の `vcruntime140.dll` の有無で `False` / `True` になった。PATH の先に別の `nvim` を置くと、`Nvim` に 2 つの場所が `, ` でつながった
  - 手順 3: 入っていないときは `'neovim' (0.12.5) was installed successfully!`、入っているときは `WARN  'neovim' (0.12.5) is already installed.` と `Use 'scoop update neovim' to install a new version.`
  - 手順 4: Linux の Neovim で、3 行・場所の 1 行・`stdpath` の 2 行が出た（前の記録と同じ）
  - 更新の手順 1: 新しい版が無いときは `neovim: 0.12.5 (latest version)` と `Latest versions for all apps are installed! For more information try 'scoop status'`。新しい版（0.12.6 にした）があるときは `'neovim' (0.12.6) was installed successfully!`。neovim が動いている扱いにすると `Running process detected, skip updating.` で、版は変わらなかった
  - ロールバックの手順 1: `'neovim' was uninstalled.` の後の `Get-Command` の行は、何も出さなかった。もう一度貼ると `ERROR 'neovim' isn't installed.`
  - 既定のエディタにするの手順 2: 値が無いときと 2 回目は `EDITOR = nvim`・`VISUAL = nvim`。`EDITOR` が `code` のときと、`VISUAL` が `nvim.exe` のときは `中断:` で止まり、値は変わらなかった
  - 既定のエディタにするの手順 3: どちらも `nvim` なら両方消え、`EDITOR` が `code` なら `EDITOR = code` が残った
- 取り出したブロック・偽物・模擬のスクリプトと出力は、リポジトリの外の作業用の場所に置いた（リポジトリには入れていない）

**2 回目の見直しの後の確認**（2026-10-08。2 回目のレビューの指摘で手順書・検証記録・参考資料を直した後に、同じ Linux のコンテナで確かめ直した。**Windows 実機では未検証**）:

- 手順書の変更は、Windows 11 のロールバックのリードの箇条書きだけ（LazyVimStarter のロールバックの手順 6 が取り戻せないことを足した。手順 7 が lazygit と zenhan も消すことは、前の見直しで書いてあった）。ブロックは変えていない
  - LazyVimStarter の `custom`（`6c894ee`）の docs/setup.md の「ロールバック」を読み直した
  - その手順 6 は、`%LOCALAPPDATA%\nvim` と `nvim-data` を `Remove-Item -Recurse -Force` で消して `.bak` を戻す（その節の `[!CAUTION]` と、1 行の説明の「取り戻せない」）
  - その手順 7 は `scoop uninstall neovim zenhan lazygit`
- 手順書の `powershell` のブロックを取り出し直した。neovim.md は 8 個で、中身は前の確認と同じだった
- PowerShell 7.5.3 の構文解析器で、構文の誤りは 0。PSScriptAnalyzer 1.25.0 の 5.1 互換の 3 規則の指摘は 0。ほかの規則の指摘は、既定のエディタにするの手順 2 の BOM の 1 件だけ
- 偽物の scoop での模擬を、前の確認と同じ 16 通りで流し直した。結果は前の確認と同じだった（表示は偽物のもの）

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（scoop での導入・更新・削除）
1. `VCRUNTIME140.dll` が無い PC で、`nvim --version` が何も出さずに終わるか、システム エラーの窓が出るか（何も出さずに終わった記録は、LazyVimStarter の検証記録の 2026-10-06 のクリーンな VM で、自動で流したものだけ）と、x64 のランタイムだけで起動すること
1. Windows の `stdpath` の値と、Windows PowerShell 5.1 から `"+lua …"` の引数がそのまま渡ること
1. `:checkhealth` の表示と、`:qa` で閉じた後の窓
1. ユーザーの環境変数 `EDITOR`・`VISUAL` が、新しい Windows PowerShell・WezTerm のタブ・lazygit の `e` キー・PowerShell の `git commit` に効くこと
1. winget の Neovim（`C:\Program Files\Neovim`）があるときに、手順 2 で見つかること
1. SSH のセッションと、arm64 の Windows

### 選択した方針

```
$ dnf -q list --available neovim
Available Packages
neovim.aarch64                       0.10.1-4.el10_0                        epel
```

### 実施手順 / 手順 2: 補足: :checkhealth の読み方

- ツールの不足: `rg`（ripgrep）、`fd`、`git`、`tree-sitter` など。このホストでは `rg` / `fd` / `git` は入っている（[yazi.md](../yazi.md) の依存ツール、および RPM の git）
