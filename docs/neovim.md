# Neovim のセットアップ（AlmaLinux 10・Windows 11）

- AlmaLinux 10 は Homebrew で Neovim と自分用の設定（[LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter)。LazyVim をもとにした設定）を導入する。Windows 11 は、導入済みの設定とプラグインを更新する

> [!IMPORTANT]
>
> - AlmaLinux 10 の項は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)と同じく、**GNOME にログインした、インストール時の管理者ユーザー（`wheel`）の bash で行う**。`sudo -i`・`su -` のシェルでは行わない
> - Windows 11 の項は、[Windows 11 のセットアップ](windows-setup.md)と同じく、**この PC のデスクトップで、Administrators のユーザーが行う**。PowerShell のブロックは **PowerShell 7** に貼る（[公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)）。複数行は、貼った全体が 1 つの入力になり、Enter で実行する設定の窓に貼る。Windows PowerShell 5.1 に貼る項は、その項のリードに書く。管理者・通常の窓は、各項のリードに従う
> - conhost の窓で複数行を右クリックで貼るときは、使う版の PSReadLine の Ctrl+Enter が `AddLine` に割り当てられ、貼った行が順番どおりに 1 つの入力になることを前提にする。未設定の窓では Ctrl+V で貼る

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- bash のブロックは、ブラケットペーストの効く端末（GNOME の端末・WezTerm・SSH の先）に貼り、貼った後に Enter を押す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- Windows 11 で GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- Neovim は、AlmaLinux 10 は[AlmaLinux 10 のセットアップの「共通の bash 設定・Homebrew・Flatpak を上げる」](almalinux-setup.md#共通の-bash-設定homebrewflatpak-を上げる)の手順 3、Windows 11 は[Windows 11 のセットアップの「scoop・winget・WSL を上げる」](windows-setup.md#scoopwingetwsl-を上げる)で上がる。**設定やプラグインは更新に追従しない**。メジャー更新の後は `:checkhealth` で壊れていないか見る
- 自分用の設定のプラグインと外部コマンドは、[LazyVim の本体・外部コマンド・プラグインを更新する](#lazyvim-の本体外部コマンドプラグインを更新する)・[Windows 11 で LazyVim の本体・外部コマンド・プラグインを更新する](#windows-11-で-lazyvim-の本体外部コマンドプラグインを更新する)で上げる

注意点や補足は、各用途の末尾と、この文書全体の折りたたみで確かめる。

<details id="この文書の補足と注意点">
  <summary>この文書の補足と注意点</summary>

**注意点**

- **Neovim: treesitter のパーサーが入らない**: `Lock file '…' appears stale` が出たら、次の順で鍵を消す
  - Neovim をすべて閉じ、tree-sitter が動いていないことを確かめる
    - AlmaLinux 10 は `pgrep -a tree-sitter`、Windows 11 は `Get-Process tree-sitter -ErrorAction SilentlyContinue` が何も出さなければよい
  - 鍵は、AlmaLinux 10 は `~/.cache/tree-sitter/lock/`、Windows 11 は `%LOCALAPPDATA%\tree-sitter\lock\` にある。表示された鍵のファイルを消す
  - 手順書の手順で出たときは、その手順のブロックを貼り直す。それ以外のときは、Neovim を開き、`Language installed` が出るまで閉じない
  - Windows 11 では、`Compiling parser` が出ている間に Neovim を閉じると、同じ鍵が残ることがある
- パーサーの導入・更新で残った鍵を消す前に、すべての Neovim を閉じ、tree-sitter が動いていないことを確かめる。動作中の鍵は消さない

**設定ファイルの場所**

- AlmaLinux 10 の置き場所は `~/.config/nvim` で、読み込まれるのは `init.lua` か `init.vim` のどちらか一方
  - `XDG_CONFIG_HOME` を設定していれば `$XDG_CONFIG_HOME/nvim` になる。別の場所を使うなら `XDG_CONFIG_HOME` か `NVIM_APPNAME` を設定する
- Windows 11 の設定は `%LOCALAPPDATA%\nvim`（`init.lua`）、プラグイン・undo・ログは `%LOCALAPPDATA%\nvim-data`、キャッシュは `%TEMP%\nvim-data`

**treesitter のパーサーの導入を待つ理由**

- 両 OS の「LazyVim の設定を導入する」「LazyVim の設定とプラグインの版を揃える」「LazyVim の本体・外部コマンド・プラグインを更新する」の計 6 手順に当てはまる
- `+qa` だけでは、LazyVim が非同期で始めたパーサーの導入・更新を待たずに Neovim が閉じる
- 待たずに閉じると、Windows 11 では組み立てが途中で終わって鍵が残り、次から `appears stale` で失敗する
- AlmaLinux 10 では、組み立ては続いて鍵を消すが、パーサーは入らない。組み立ての途中で `tree-sitter build` が殺されたときは、鍵が残る
- Mason が入れた tree-sitter の CLI は、headless の Neovim では Mason を読み込むまで PATH に無いので、最初に Mason を読み込む
- tree-sitter の CLI が無ければ、Mason が入れて CLI が使えるようになるまで最大 10 分待つ
- nvim-treesitter は、ほかで始まった同じ言語の導入を最大 60 秒しか待たないので、パーサーの更新と導入が両方とも成功するまで最大 20 回繰り返す
- 検証記録の付録（`docs/verification/neovim.md` の「付録: headless の Neovim が treesitter のパーサーの導入を途中で止めるのを直したとき（2026-10-16）」）

**GitLab プレビュー**

- [md-preview](https://github.com/ryo-aoki-pc/md-tools) が手元で描く。本文を GitLab に送らず、トークンは要らない
- 公式スタイルは任意で、取得は md-preview の手順（[AlmaLinux 10](https://github.com/ryo-aoki-pc/md-tools/blob/main/docs/install.md#md-preview-の公式スタイルを取得する)・[Windows 11](https://github.com/ryo-aoki-pc/md-tools/blob/main/docs/install.md#windows-11-で-md-preview-の公式スタイルを取得する)）に従う
- PlantUML の図も任意で、`plantuml` コマンドが PATH にあれば、手元のそのコマンドで描く。無ければ、図は原文のコードブロックで表示する。Windows 11 の導入は md-preview の [Windows 11 で PlantUML を入れる](https://github.com/ryo-aoki-pc/md-tools/blob/main/docs/install.md#windows-11-で-plantuml-を入れる)に従う
- 設計は [md-preview の参考資料](https://github.com/ryo-aoki-pc/md-tools/blob/main/docs/reference/readme.md)を参照する

**更新時の :checkhealth の読み方**

この節の検証記録（`docs/verification/neovim.md` の「Neovim: 実施手順 / 手順 2: 補足: :checkhealth の読み方」）

`:checkhealth` は「使っていない機能の WARNING」を大量に出す。素の状態で出るのは主に次の 3 種類:

- `vim.provider`: node / perl / python3 / ruby のプロバイダが無い。それぞれの言語で書かれたプラグインを使わないなら無視してよい（`vim.g.loaded_node_provider = 0` などで黙らせられる）
- `vim.deprecated`: プラグインが古い API を使っている
- ツールの不足: `rg`（ripgrep）、`fd`、`git`、`tree-sitter` など。必要なものを各手順書で導入する（[yazi](almalinux-setup.md#yazi) の依存ツール、および RPM の git）

`ERROR` が出ていなければ、日常の編集には支障がない。

**参照**

- 検証記録
- [Install Neovim](https://neovim.io/doc/install/) — 公式が案内する各経路（tarball / AppImage / パッケージマネージャ）
- [neovim/neovim — INSTALL.md](https://github.com/neovim/neovim/blob/master/INSTALL.md) — tarball の展開先と PATH の通し方、glibc の要件
- `:help nvim-defaults` / `:help checkhealth` — 既定値と健全性チェックの読み方
- [ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter) — 自分用の設定（LazyVim ベース）。導入の手順は[LazyVim の設定を導入する](#lazyvim-の設定を導入する)、何ができるかはその README

</details>

## AlmaLinux 10 で使う

- Neovim と、自分用の LazyVim の設定

### Neovim

- Neovim を Homebrew で入れ、自分用の設定（LazyVim をもとにした設定）を入れて、既定のエディタになったことを確かめる
- 前提: [共通の bash 設定](shell-terminal.md#共通の-bash-設定)・[Homebrew](almalinux-setup.md#homebrew)・[WezTerm](shell-terminal.md#wezterm)を通し、PATH に Homebrew が入った端末（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2 で開き直した端末）を開いてある
  - この項の手順 2 は、[LazyVim の設定を導入する](#lazyvim-の設定を導入する)の前提も要る
  - インターネットに出られないホストは、[Homebrew](almalinux-setup.md#homebrew)の代わりに[Homebrew のオフライン導入](almalinux-setup.md#homebrew-のオフライン導入)を通し、そのトンネルのシェルで行う
- 実行場所: WezTerm のタブ（前提の、PATH に Homebrew が入った端末。GNOME にログインした自分のユーザーの bash）。この項の手順 3 で新しいタブを開く
- Homebrew 版と EPEL 版の Neovim は片方だけにする

1. Neovim を導入し、版と実行ファイルの場所を確認する。

   ```bash
   # Neovim を Homebrew から入れる
   brew install neovim
   printf '\n\033[7m 確認 \033[0m\n'
   nvim --version | head -3
   brew list --versions neovim
   command -v nvim
   ```

   - Homebrew の確認が出たら答える
   - `NVIM` と版が出ればよい
   - この項の手順 2 の退避前には `nvim` を起動しない

1. オフラインでは npm の経路を先に設定し、[自分用の設定](https://github.com/ryo-aoki-pc/LazyVimStarter)を入れる。

   - オフラインのホストでは、先に [npm のオフライン導入](almalinux-setup.md#npm-のオフライン導入)の手順 1・2 を同じトンネルのシェルで通す。参照先の「LazyVim の設定を導入する」の手順 8 の初回起動より前に行う
   - [LazyVim の設定を導入する](#lazyvim-の設定を導入する)の全項を、この項で指定した端末で通す
   - 参照先の手順 1 で Node.js・ibus-anthy・wl-clipboard、手順 4 で lazygit・ripgrep・fd を入れる
   - 参照先の手順 5〜7 で入力ソースを「英語 (US)」と Anthy にし、Ctrl+Space・Ctrl+J を Anthy の切り替えから外す。JIS 配列でも US にする
   - 参照先の手順 7 の後はログインし直さず、[再起動と確認](almalinux-setup.md#再起動と確認)の手順 1 の再起動で読み直す
   - 参照先の手順 9 で Neovim が開く。Mason の導入を待ち、`:qa` で閉じると、同じブロックの `checkhealth` が動く
   - [日本語検索・整形・IME 連携の確認](#lazyvim-の日本語検索整形ime-連携を確かめる)は、[再起動と確認](almalinux-setup.md#再起動と確認)の手順 8 で行う

1. WezTerm で新しいタブを開き、既定のエディタを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%s / %s\n' "$EDITOR" "$VISUAL"
   alias vi
   ```

   - `nvim / nvim` と `alias vi='nvim'` が出ればよい
   - 元値の控えや `~/.bashrc` への追記は行わない
   - `. ~/.bashrc` で読み直さない

#### Neovim の設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値（素の Vim に近い挙動）で動く
  - Windows 11 は、`XDG_CONFIG_HOME` が未設定の状態を前提にする
  - 導入は[Neovim](#neovim)の手順 2
  - Windows 11 は、`%LOCALAPPDATA%\nvim` に自分用の設定が入っていることを前提にする
- インターネットに出られないホストで、Mason が npm で入れるパッケージ（LSP サーバー・リンター）を入れるなら、[npm のオフライン導入](almalinux-setup.md#npm-のオフライン導入) を通す

#### LazyVim の設定を導入する

- 自分用の Neovim の設定（[ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter)）を `~/.config/nvim` に入れる。外部コマンドと日本語入力の設定を全部入れてから、Neovim を初回起動する
- 前提: [EPEL と RPM Fusion](almalinux-setup.md#epel-と-rpm-fusion)・[共通の bash 設定](shell-terminal.md#共通の-bash-設定)・[Homebrew](almalinux-setup.md#homebrew)・[HackGen Console NF](shell-terminal.md#hackgen-console-nf)を通し、[Neovim](#neovim)の手順 1 で Neovim を入れてある。PATH に Homebrew が入った端末（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2 で開き直した端末）を開いてある
- 実行場所: 前提の端末（GNOME にログインした自分のユーザーの bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ。`sudo` は、この項の手順 1 だけで使う。この項の手順 2 の既存の設定の退避を省かない

1. 外部コマンドと日本語入力を導入し、導入結果を確認する。

   ```bash
   # 外部コマンドと日本語入力のパッケージを入れる
   sudo dnf install git gcc curl tar gzip unzip nodejs nodejs-npm file procps-ng ibus-anthy wl-clipboard
   printf '\n\033[7m 確認 \033[0m\n'
   rpm -q git gcc curl tar gzip unzip nodejs nodejs-npm file procps-ng ibus-anthy wl-clipboard
   node --version
   command -v gdbus busctl wl-paste
   ```

   - ripgrep と fd は、この項の手順 4 で Homebrew から入れる (EPEL の `ripgrep` / `fd-find` は入れない)
   - 鍵の fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158` (`Fedora (epel10)`) であることを確かめてから `y` と答える
   - トランザクション表の `[y/N]` に `y` と答える
   - どの行も `package … is not installed` にならなければよい
   - Node.js の版と `gdbus`・`busctl`・`wl-paste` の場所が出ればよい

1. 既存の Neovim の設定とデータがあれば、`.bak` を付けて退避する。

   ```bash
   # Neovim の既存のディレクトリを退避する
   for d in ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim; do
     [ ! -e "${d}" ] || mv -vT "${d}" "${d}.bak"
   done
   ```

   - 退避したものがあれば `renamed` と出る
   - **注意**: `.bak` がすでにあると `mv` が `cannot overwrite` で止まる。古い `.bak` を片付けてから、この手順を貼り直す

1. この設定を `~/.config/nvim` に clone する。

   ```bash
   # 設定リポジトリを取得し、ブランチを確かめる
   [ -e ~/.config/nvim/init.lua ] || git clone https://github.com/ryo-aoki-pc/LazyVimStarter.git ~/.config/nvim
   git -C ~/.config/nvim branch --show-current
   ```

   - `custom` と出ればよい

1. lazygit・ripgrep・fd を導入し、版と場所を確認する。

   ```bash
   # 検索と Git 操作に使う外部コマンドを入れる
   brew install lazygit ripgrep fd
   printf '\n\033[7m 確認 \033[0m\n'
   nvim --version | head -1
   command -v nvim lazygit rg fd
   ```

   - `Do you want to proceed with the installation? [y/n]` と聞かれたら、入るものの一覧 (依存を含む) を見て `y` と答える
   - Homebrew 版の ripgrep・fd と EPEL 版は二重に入れない
   - Neovim の版と、`/home/linuxbrew/.linuxbrew/bin/` の各コマンドが出ればよい
   - `NVIM v0.12.…` と出ればよい (0.12 以上が要る)

1. 入力ソースを「英語 (US)」と Anthy の 2 つにする。

   ```bash
   # 入力ソースの現在の値を取得する
   export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
   /usr/bin/gsettings get org.gnome.desktop.input-sources sources
   # 入力ソースを設定して読み戻す
   /usr/bin/gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'anthy')]"
   /usr/bin/gsettings get org.gnome.desktop.input-sources sources
   ```

   - 最後の行が `[('xkb', 'us'), ('ibus', 'anthy')]` になればよい
   - 最初の行は変える前の値。ほかの入力ソースは消える
   - JIS 配列でも `us` にする
   - 日本語と英数の切り替えは Super+Space になる

1. Anthy の `on_off` のキーから `Ctrl+J` と `Ctrl+space` を外した値を作る。

   ```bash
   # Anthy の切り替えキーを編集して表示する
   ANTHY_SHORTCUT=$(/usr/bin/gsettings get org.freedesktop.ibus.engine.anthy.shortcut default | sed "s/'on_off': <\['Zenkaku_Hankaku', 'Ctrl+space', 'Ctrl+J'\]>/'on_off': <['Zenkaku_Hankaku']>/")
   printf '%s\n' "${ANTHY_SHORTCUT}" | grep -o "'on_off': <\[[^]]*\]>"
   ```

   - `'on_off': <['Zenkaku_Hankaku']>` と出ればよい
   - `Ctrl+J` が残っている・何も出ないときは、この項の手順 7 は飛ばす。代わりに `ibus-setup-anthy` の「キー割り当て」で `on_off` から `Ctrl+J` と `Ctrl+space` を消す
   - **次の手順は、出た行を目で確かめてから貼る**

1. 作った値を Anthy の設定に書き戻す。

   ```bash
   # Anthy の切り替えキーを保存して読み戻す
   /usr/bin/gsettings set org.freedesktop.ibus.engine.anthy.shortcut default "${ANTHY_SHORTCUT:?この項の手順 6 の ANTHY_SHORTCUT が空のまま。この項の手順 6 を貼り直す}"
   /usr/bin/gsettings get org.freedesktop.ibus.engine.anthy.shortcut default | grep -o "'on_off': <\[[^]]*\]>"
   ```

   - `'on_off': <['Zenkaku_Hankaku']>` と出ればよい
   - 導入後の[再起動と確認](almalinux-setup.md#再起動と確認)で Anthy と入力ソースを読み直す。日本語検索・IME 連携は[LazyVim の日本語検索・整形・IME 連携を確かめる](#lazyvim-の日本語検索整形ime-連携を確かめる)で行う
   - 以後、日本語と英数の切り替えは Super+Space と、Neovim の中の `<C-j>` になる

1. プラグインを入れ、`lazy-lock.json` の版に揃える。

   ```bash
   # パーサーの導入を待ちながらプラグインを入れる
   ts_wait="lua pcall(require, 'mason'); local TS, want = require('nvim-treesitter'), LazyVim.opts('nvim-treesitter').ensure_installed; vim.wait(600000, function() return vim.fn.executable('tree-sitter') == 1 end, 1000); for _ = 1, 20 do if TS.update():wait(900000) and TS.install(want):wait(900000) then break end end"
   nvim --headless "+$ts_wait" +qa
   # lock ファイルを戻してプラグインの版を揃える
   git -C ~/.config/nvim checkout -- lazy-lock.json
   nvim --headless "+Lazy! restore" "+$ts_wait" +qa
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/nvim status --short
   ```

   - `Error in command line`（中身は ``Failed to run `config` for nvim-treesitter`` と `Package is already installing.`）は出ても進んでよい
   - 最後の `git status --short` が何も出さなければ、`lazy-lock.json` の版に揃っている
   - `Lock file '…' appears stale` が出たら、[この文書の補足と注意点](#この文書の補足と注意点)の「注意点」で鍵を消してから、この項の手順 8 のブロックを貼り直す
   - treesitter のパーサーを入れ終えて Neovim が閉じるまで待つ（数分かかる。途中で止めない）
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼ると、導入結果や lock ファイルの状態を確認する前に次の導入処理が動く）

1. Mason の導入を待ち、外部コマンドの健全性を確認する。

   ```bash
   # 確認用の Markdown を作って Neovim で開く
   printf '%s\n' '#  動作確認' '' '日本語の検索を試す。' > /tmp/lazyvim-check.md
   nvim /tmp/lazyvim-check.md
   printf '\n\033[7m 確認 \033[0m\n'
   # Mason が入れた外部コマンドを一覧にする
   ls ~/.local/share/nvim/mason/bin
   # 健全性の検査を実行し、警告とエラーを抽出する
   nvim --headless "+Lazy! load mason.nvim luamigemo" "+checkhealth lazyvim luamigemo" "+w! /tmp/lazyvim-health.txt" +qa
   grep -E 'ERROR|WARNING' /tmp/lazyvim-health.txt
   ```

   - 初回の `Error running markdownlint-cli2: ENOENT` は進んでよい
   - `:Mason` で導入中のものがなくなるまで待ち、`q` で閉じる
   - 待ったら `:qa` で閉じる
   - `grep` が何も出さないか、`` WARNING `fzf` is not installed `` の 1 行だけならよい (無視してよい。fzf が入っていれば出ない)
   - `ERROR` が出たら[注意点](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#注意点)
   - `:Mason` を開き、Installed が 11 個になり、導入中のものが無くなるまで待つ (`q` で閉じる。tree-sitter の CLI を別に入れてあれば 10 個)

#### LazyVim の日本語検索・整形・IME 連携を確かめる

- 試験用の Markdown で、LazyVim の日本語検索・保存のときの整形・IME 連携・アイコンの表示を確かめる
- 前提: [WezTerm](shell-terminal.md#wezterm)・[LazyVim の設定を導入する](#lazyvim-の設定を導入する)・[LazyVim の安全な Markdown 整形を導入する](#lazyvim-の安全な-markdown-整形を導入する)を通し、その後に再起動してある（[再起動と確認](almalinux-setup.md#再起動と確認)の手順 1）
- 実行場所: 再起動の後に開いた WezTerm の新しいタブ（GNOME にログインした自分のユーザーの bash。`sudo` は使わない）

1. 試験用の Markdown を作って開き、日本語検索・整形・IME 連携を確かめる。

   ```bash
   # 日本語の検索と整形を試すファイルを作って開く
   printf '%s\n' '#  動作確認' '' '日本語の検索を試す。' > /tmp/lazyvim-check.md
   nvim /tmp/lazyvim-check.md
   ```

   - `/kensaku` と打って Enter を押す。3 行目の「検索」にカーソルが移り、`[1/1]` と出る
   - `/kensaku` と打って `<Tab>` を押す。入力が「検索」に置き換わる (候補が 1 つなので、すぐ確定する)。`<Esc>` で抜ける
   - `:w` で保存する。1 行目の `#` の後の 2 つの空白が 1 つになり、`# 動作確認` になる (md-format の `mdfmt` の整形)
   - `o` で行を開き、`<C-j>` を押す。下の表示が `A` から `あ` に変わる。`<Esc>` で `A` に戻る
   - `<C-j>` を押したときは、カーソルのすぐ下にも `あ` / `A` が約 1 秒出る
   - `/` を押す。最下段の検索欄の右端に `A` が出る。`<C-j>` で `あ` に変わり、検索欄のカーソルのすぐ上にも `あ` が約 1 秒出て、カーソルが橙になる
   - `<Esc>` で抜ける。下の表示が `A` に戻り、次の `/` は `あ` で始まる (検索の sticky)。`<C-j>` で `A` にしてから `<Esc>` で抜ける
   - Space を 2 回押してファイルピッカーを開き、アイコンが豆腐でないことを見る (`<Esc>` で閉じる)
   - `:qa!` で閉じる (`o` で足した行は保存しない)

#### LazyVim の設定とプラグインの版を揃える

- 設定と `lazy-lock.json` を取り込み、プラグインをその版に揃える
- 前提: [LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ。この項の手順 1 で `pull` が止まったときの、手元の変更の確認を省かない
- Markdown の整形器 md-format は、この項では上がらない。[md-format を導入・更新する](https://github.com/ryo-aoki-pc/md-format/blob/main/docs/install.md#md-format-を導入更新する)の手順 2 で上げる
- GitLab プレビューのアプリ md-preview も、この項では上がらない。[md-preview を導入・更新する](https://github.com/ryo-aoki-pc/md-tools/blob/main/docs/install.md#md-preview-を導入更新する)を通して上げる

1. AlmaLinux 10 では、設定を最新にしてプラグインを揃える。

   ```bash
   # 設定を取り込み、プラグインの版を揃える
   ts_wait="lua pcall(require, 'mason'); local TS, want = require('nvim-treesitter'), LazyVim.opts('nvim-treesitter').ensure_installed; vim.wait(600000, function() return vim.fn.executable('tree-sitter') == 1 end, 1000); for _ = 1, 20 do if TS.update():wait(900000) and TS.install(want):wait(900000) then break end end"
   git -C ~/.config/nvim pull --ff-only && nvim --headless "+Lazy! restore" "+$ts_wait" +qa
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/nvim status --short
   ```

   - 途中で止めず、プロンプトが戻るまで待つ
   - `git status --short` が何も出さなければ、`lazy-lock.json` の版に揃っている
   - 起動時に `lazy-lock.json` が書き換わり、`git status --short` に `M lazy-lock.json` が出たら、`git -C ~/.config/nvim checkout -- lazy-lock.json` で戻す
   - 戻したら、この項の手順 1 のブロックを貼り直す
   - `pull` が `Not possible to fast-forward` で止まったら、このマシンに push していないコミットがある。先に push するか、`git -C ~/.config/nvim log --oneline '@{u}..'` で中身を見る
   - `pull` が `Your local changes to the following files would be overwritten by merge:` と `lazy-lock.json` を出して止まったら、lock の変更を確認する
   - `:Lazy update` の結果として残すのでなければ、`git -C ~/.config/nvim checkout -- lazy-lock.json` で戻して、この手順を貼り直す
   - `Lock file '…' appears stale` が出たら、[この文書の補足と注意点](#この文書の補足と注意点)の「注意点」で鍵を消してから、この項の手順 1 のブロックを貼り直す

#### LazyVim の安全な Markdown 整形を導入する

- 保存のときの Markdown の整形に使う md-format（`mdfmt`）を前提にし、Neovim で整形を確かめる
- 前提: [LazyVim の設定を導入する](#lazyvim-の設定を導入する)と、[md-format を導入・更新する](https://github.com/ryo-aoki-pc/md-format/blob/main/docs/install.md#md-format-を導入更新する)を通してある
- 実行場所: 自分のユーザーの端末（bash。`sudo` は使わない）。この項の手順 2 は、手順 1 で開く Neovim の中。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブで開く

1. 試験用の Markdown を Neovim で開く。

   ```bash
   nvim /tmp/lazyvim-format-check.md
   ```

   - **次の手順は、`i` を押し、挿入モードの本文に貼る**（端末のシェルには貼らない）

1. Neovim の試験用 Markdown に本文を貼り、保存と手動整形を確かめる。

   ```markdown
   #  動作確認

   用語
   : 説明

     - 内部の項目

   <details>
   <summary>概要</summary>

   本文

   </details>

   <table><tr><td>a</td><td>b</td></tr></table>
   ```

   - `:w` または `<leader>cf` で `#  動作確認` の `#` の後の空白が 1 つになる (`# 動作確認`)
   - `内部の項目` の行頭の 2 スペースが保たれる
   - `<summary>` の行が 2 スペース字下げになる。空行と `本文` はそのまま
   - `<table>` の行が `<tr>`・`<td>` ごとの 6 行に分かれ、入れ子に合わせて 2 スペースずつ字下げされる
   - `<leader>cf` はビジュアル選択した範囲にも使える
   - 一部の lint 診断は残ることがある
   - `:ConformInfo` に `mdfmt` が出る。設定不正・時間切れのときは原文を保持し、エラーを知らせる
   - 貼り終えたら Esc を押し、ノーマルモードに戻る
   - `md-format (mdfmt) が導入されていません` と出たら、[md-format を導入・更新する](https://github.com/ryo-aoki-pc/md-format/blob/main/docs/install.md#md-format-を導入更新する)を通してから、Neovim を開き直す
   - 確かめ終えたら `:qa!` で閉じる。試験用の `/tmp/lazyvim-format-check.md` は、要らなければ `rm /tmp/lazyvim-format-check.md` で消す

#### LazyVim のカーソル色を tmux で使う

- 挿入モードのカーソル色も IME の状態で変わる。ただし tmux 越しでは既定では効かないので、tmux の設定に 1 行足す
- 前提: [LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通し、[シェルのツール](shell-terminal.md#シェルのツール)の手順 1 で tmux を入れてある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。この項の手順 2 は tmux の中のシェル。既存の `~/.tmux.conf` の確認（この項の手順 1）を省かない
- AlmaLinux 10 で tmux を使うときだけ行う。無くても害は無い

1. tmux の設定ファイルに `terminal-overrides` を 1 行足す。

   ```bash
   # カーソル色の設定を tmux の設定ファイルに足す
   mkdir -p ~/.config/tmux
   grep -qF 'Cs=\E]12' ~/.config/tmux/tmux.conf 2>/dev/null || cat >> ~/.config/tmux/tmux.conf <<'EOF'
   set -ga terminal-overrides ',*:Cs=\E]12;%p1%s\007:Cr=\E]112\007'
   EOF
   ```

   - すでに書いてあれば足さない
   - **注意**: `~/.tmux.conf` があると、tmux は `~/.config/tmux/tmux.conf` を読まない。そのときは、この 1 行を `~/.tmux.conf` に書く

1. tmux の中で、設定を読み直して確かめる。

   ```bash
   # tmux の設定を読み込み、適用した値を確かめる
   tmux source-file ~/.config/tmux/tmux.conf
   tmux show-options -g terminal-overrides | grep -F 'Cs='
   ```

   - `terminal-overrides[0] "*:Cs=\\E]12;%p1%s\\007:Cr=\\E]112\\007"` のような行が出ればよい
   - Neovim を起動し直すと、挿入モードで `<C-j>` を押したときにカーソルの色が変わる
   - `-ga` は足すたびに同じ値を増やすので、起動時と読み直しの分で 2 行出ることがある。害は無い

#### LazyVim の IME 連携に GNOME の上部バーを合わせる

- Neovim がモードに合わせて IME を切り替えても、GNOME の上部バーの表示と Super+Space の順番がずれないようにする
- 前提: [LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通してある（拡張は `~/.config/nvim` の中にある）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。この項の手順 3 からは、ログインし直した後に開いた端末
- AlmaLinux 10 + GNOME 49 のときだけ行う。拡張は GNOME Shell の内部の関数を使うので、GNOME を上げたらこの項の手順 4 で確かめる
- **この項の手順 2 で、ログアウトしてログインし直す**

1. 拡張を、GNOME Shell が拡張を探す場所につなぐ。

   ```bash
   # GNOME Shell の拡張を配置して確かめる
   mkdir -p ~/.local/share/gnome-shell/extensions
   ln -sfn ~/.config/nvim/gnome-shell/ibus-engine-follow@ryo-aoki-pc.github.com ~/.local/share/gnome-shell/extensions/
   ls -l ~/.local/share/gnome-shell/extensions/
   ```

   - 拡張へのリンクが出ればよい

1. ログアウトしてログインし直す。

   - GNOME Shell (Wayland) は、新しい拡張をログインのときにしか探さない
   - **次の手順は、ログインし直した後の端末で貼る**

1. 拡張を有効にする。

   ```bash
   # GNOME Shell の拡張を有効にして状態を調べる
   gnome-extensions enable ibus-engine-follow@ryo-aoki-pc.github.com
   gnome-extensions info ibus-engine-follow@ryo-aoki-pc.github.com | grep -E 'Enabled|State'
   ```

   - `Enabled: Yes` と `State: ACTIVE` が出ればよい
   - `doesn't exist` と出たら、この項の手順 1 のつなぎ先が無い (設定を取り込んでいない) か、ログインし直していない
   - `State: OUT OF DATE` なら、拡張の対応する GNOME Shell の版を確かめる

1. Neovim を開き、上部バーが Neovim の IME の状態に付いてくることを確かめる。

   ```bash
   # IME の切り替えを試すファイルを作って開く
   printf '%s\n' '#  動作確認' '' '日本語の検索を試す。' > /tmp/lazyvim-check.md
   nvim /tmp/lazyvim-check.md
   ```

   - 開いた時点で、上部バーの入力ソースが英語 (US) になる (Neovim がノーマルモードで英数にするため)
   - `o` → `<C-j>` で、上部バーが Anthy (`あ`) になる。`<Esc>` で英語 (US) に戻る
   - ノーマルモードで Super+Space を 1 回押すと、上部バーと lualine の `あ` / `A` が一緒に変わる (空振りしない)
   - `:qa!` で閉じる

#### LazyVim のヤンクを SSH 越しに手元へ送る

- 手元の端末から AlmaLinux 10 に ssh して Neovim を使うとき、`y` `d` `x` などでレジスタに入れたものを、手元のクリップボードにも入れる
- 向きは Neovim → 手元だけ。手元でコピーしたものは、端末の貼り付け (WezTerm は Ctrl+Shift+V) で Neovim に入れる
- 前提: AlmaLinux 10 で、[LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通し、[LazyVim の設定とプラグインの版を揃える](#lazyvim-の設定とプラグインの版を揃える)の手順 1 で設定を最新にしてある。[システムの設定](almalinux-setup.md#システムの設定)の手順 3・4 で、SSH を待ち受けている
  - 手元は WezTerm nightly を使う（AlmaLinux 10 は[WezTerm](shell-terminal.md#wezterm)、Windows 11 は[WezTerm の公式の導入案内](https://wezterm.org/install/windows.html)）。安定版 20240203 は設定があると OSC 52 を捨てる（[注意点](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#注意点)）
- 実行場所: **GNOME の端末ではなく、手元の WezTerm から AlmaLinux 10 に ssh したシェル**（ssh でログインした自分のユーザーの bash。`sudo` は使わない）。tmux の中の Neovim は扱わない

1. SSH のシェルで、この設定が OSC 52 を使うことを確かめる。

   ```bash
   # SSH の接続情報を表示する
   printf 'SSH_CONNECTION=%s\n' "${SSH_CONNECTION:-(無い)}"
   # Neovim のクリップボード設定を確かめる
   nvim --headless "+lua io.stdout:write((vim.g.clipboard or {}).name or '(無い)', '\n')" +qa
   ```

   - `SSH_CONNECTION` に接続情報が出ればよい
   - 2 行目が `OSC 52 (copy only)` と出ればよい
   - `SSH_CONNECTION=(無い)` と出たら、SSH のシェルではない (`sudo -i` や `su -` のシェルでは消える)。ssh でログインしたユーザーのシェルで貼り直す
   - 2 行目が `(無い)` と出たら、設定が古い。[LazyVim の設定とプラグインの版を揃える](#lazyvim-の設定とプラグインの版を揃える)の手順 1 を貼ってから、この手順を貼り直す

1. 試験用のテキストを開き、ヤンクした行が手元のクリップボードに入ることを確かめる。

   ```bash
   # ヤンクを試すテキストファイルを作って開く
   printf '%s\n' 'SSH 越しのヤンクを試す。' > /tmp/lazyvim-ssh.txt
   nvim /tmp/lazyvim-ssh.txt
   ```

   - `yy` を押す。手元のアプリ (メモ帳など) に貼り付けると、`SSH 越しのヤンクを試す。` が入る
   - `p` を押す。待たされずに、同じ行がすぐ下に入る
   - `:set clipboard?` が `clipboard=unnamedplus` と出る
   - `:qa!` で閉じる

#### LazyVim の GitLab プレビューを導入する

- md-preview を使い、LazyVim の Markdown をブラウザでプレビューする
- 前提: [LazyVim の設定を導入する](#lazyvim-の設定を導入する)と、[md-preview を導入・更新する](https://github.com/ryo-aoki-pc/md-tools/blob/main/docs/install.md#md-preview-を導入更新する)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。この項の手順 1 で起動する Neovim
- 公式スタイルは任意。[md-preview の公式スタイルを取得する](https://github.com/ryo-aoki-pc/md-tools/blob/main/docs/install.md#md-preview-の公式スタイルを取得する)に従う（Neovim の `:GitLabPreviewInstall` でも取得できる）

1. AlmaLinux 10 では、この設定の README を開き、プレビューで確かめる。

   ```bash
   nvim ~/.config/nvim/README.md
   ```

   - `<leader>cp` を押す。ブラウザが開き、操作欄の左に `README.md`、右に「一覧」「見出し」「配色」「本文幅」が出ればよい（「GitLab との違い <件数>」は、知らせがあるときだけ出る）
   - `md-preview が導入されていません` か `取り決めの版が違います` と出たら、前提の md-preview の導入・更新を通してから、この手順をやり直す
   - もう一度 `<leader>cp` を押す。ページの上に「プレビューを止めた」と出ればよい
   - `:qa` で閉じる。プレビューのアプリも終わり、ページの上に「プレビューが終了した」と出る

#### LazyVim の本体・外部コマンド・プラグインを更新する

- Homebrew で入れた Neovim・lazygit・ripgrep・fd・HackGen と、LazyVim のプラグインを上げる
- 前提: [Homebrew](almalinux-setup.md#homebrew)と[LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通し、PATH に Homebrew が入った端末（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2 で開き直した端末）を開いてある
  - `lazy-lock.json` を push するには、[GitHub CLI](almalinux-setup.md#github-cli)でログインしてある
- 実行場所: 前提の端末（GNOME にログインした自分のユーザーの bash。`sudo` は使わない）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ。この項の手順 2 の `lazy-lock.json` の差分の確認を省かない
- 設定の取り込みは[LazyVim の設定とプラグインの版を揃える](#lazyvim-の設定とプラグインの版を揃える)で行う
- プラグイン更新後は動作を確認し、`lazy-lock.json` の差分をコミット・push する

1. AlmaLinux 10 では、Homebrew で入れたものを上げる。

   ```bash
   # Neovim・外部コマンド・フォントを更新する
   brew upgrade neovim lazygit ripgrep fd
   brew upgrade --cask font-hackgen-nerd
   # 更新後の Neovim の版を確かめる
   nvim --version | head -1
   ```

   - 最新なら `Warning: neovim 0.12.5_1 already installed` のように出て、何も上げない

1. AlmaLinux 10 では、プラグインを上げて `lazy-lock.json` の差分を見る。

   ```bash
   # パーサーの導入を待ちながらプラグインを更新する
   ts_wait="lua pcall(require, 'mason'); local TS, want = require('nvim-treesitter'), LazyVim.opts('nvim-treesitter').ensure_installed; vim.wait(600000, function() return vim.fn.executable('tree-sitter') == 1 end, 1000); for _ = 1, 20 do if TS.update():wait(900000) and TS.install(want):wait(900000) then break end end"
   nvim --headless "+Lazy! update" "+$ts_wait" +qa
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/nvim diff --stat
   ```

   - 途中で止めず、プロンプトが戻るまで待つ
   - `lazy-lock.json` だけが変わっていればよい
   - `Lock file '…' appears stale` が出たら、[この文書の補足と注意点](#この文書の補足と注意点)の「注意点」で鍵を消してから、この項の手順 2 のブロックを貼り直す
   - 上げた後は、Neovim を起動して使えることを確かめてから、`lazy-lock.json` をコミットして push する

<details id="neovim-の補足と注意点">
  <summary>Neovim の補足と注意点</summary>

**注意点**

- **Neovim: EPEL の `neovim` と両方入れない**: PATH の先頭が Homebrew なので、Homebrew 版が勝つ。どちらか一方にする
- **Neovim: `sudo nvim` は、そのままでは動かない**: sudo の PATH に Homebrew が無い
  - [Homebrew を sudo でも使う](almalinux-setup.md#homebrew-を-sudo-でも使う)の節を通すと動く。root の Neovim は `/root/.config/nvim` を読む
  - root のファイルを自分の設定で編集するなら、`sudo nvim` ではなく `sudoedit` を使う（その節を通すか、`SUDO_EDITOR` にフルパスを渡す。[「Neovim」の手順 3](#neovim)）
  - root のシェル（`su -`、root のログイン、`sudo -i`）で使うなら、[Homebrew を root のシェルでも使う](almalinux-setup.md#homebrew-を-root-のシェルでも使う)の節を通す（`sudo nvim` は、その節だけでは動かない）
- **Neovim: プロバイダは別途**: Python / Node.js のプラグインを使うなら、それぞれ `pynvim` / `neovim` パッケージを入れる。Node.js 本体は、[「Neovim」の手順 2](#neovim) の自分用の設定の導入で入る
- **Neovim: 設定とプラグインは更新に追従しない**: `brew upgrade neovim` でメジャー版が上がると、古い API を使うプラグインが壊れることがある
- **Neovim: `vi` は RPM の `vim-minimal`**: 別物が `/usr/bin/vi` として残っている。エイリアスを張らない限り `vi` は Neovim にならない

**[Neovim](#neovim)の手順 1**

- `NVIM v0.12.…` と `LuaJIT 2.1...` が出れば入っている
- ここでは `nvim` を起動しない（この項の手順 2 の退避より前に起動すると、`~/.local/state/nvim` などができて、それも退避される）
- この手順の `nvim --version` だけでも、空の `~/.local/state/nvim/nvim.log` ができる。この項の手順 2 で、`~/.local/state/nvim.bak` に退避される

**[Neovim](#neovim)の手順 1: ボトルと依存**

検証記録（`docs/verification/almalinux-setup.md`）

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
- 依存（`libuv` / `lpeg` / `luajit` / `luv` / `tree-sitter` / `unibilium` / `utf8proc`）も一緒に入る

**[Neovim](#neovim)の手順 3**

- この 3 項目は共通の bash 設定が持つ（`nvim` があれば、開いたシェルで設定する）。元値の控えや `~/.bashrc` への追記は行わない
- 開いていたタブは、`nvim` を入れる前の値のまま。`. ~/.bashrc` で読み直さない（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2）

**[Neovim の設定ファイル](#neovim-の設定ファイル)のリード**

- Windows 11 の設定は `%LOCALAPPDATA%\nvim`、データは `%LOCALAPPDATA%\nvim-data` にある
- **自分用の設定**は [ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter) にある（LazyVim をベースに、日本語の入力・検索と Markdown（GLFM）の執筆を強くした設定）
- 何ができるか・どこを変えたかは [README の「主なカスタマイズ」](https://github.com/ryo-aoki-pc/LazyVimStarter#主なカスタマイズ)

**[LazyVim の設定を導入する](#lazyvim-の設定を導入する)のリード**

- [背景説明](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/reference/setup.md)・検証記録（`repos/LazyVimStarter/docs/verification/setup.md`）

**[LazyVim の設定を導入する](#lazyvim-の設定を導入する)の手順 1**

- 何に使うかは[必要なもの一覧](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#必要なもの一覧)
- EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる
- `node --version` が `v22.…` と出る
- `gdbus` / `busctl` / `wl-paste` の 3 つの場所が出る (`gdbus` と `busctl` は IME 連携が ibus と話すのに使う)

**[LazyVim の設定を導入する](#lazyvim-の設定を導入する)の手順 2**

- 退避したものは `renamed '…/nvim' -> '…/nvim.bak'` と出る。何も出なければ、退避するものは無かった

**[LazyVim の設定を導入する](#lazyvim-の設定を導入する)の手順 3**

- `custom` と出ればよい (実運用の設定のブランチで、このリポジトリの既定のブランチ)
- すでに clone してあれば、`git clone` は飛ばされる

**[LazyVim の設定を導入する](#lazyvim-の設定を導入する)の手順 4**

- lazygit は任意 (無ければ `<leader>gg` が定義されないだけ)
- ripgrep (`rg`) と fd は、ピッカーと Migemo の候補が使う。EPEL の `ripgrep` / `fd-find` と二重に入れない (実行ファイルの名前が同じで、PATH の先頭の Homebrew 版が使われる)
- 4 つとも `/home/linuxbrew/.linuxbrew/bin/…` と出る

**[LazyVim の設定を導入する](#lazyvim-の設定を導入する)の手順 5**

- **注意**: JIS 配列のキーボードでも `us` にする。IME 連携が英数を `xkb:us::eng` に固定しているため
- `gsettings` は `/usr/bin/gsettings` と場所まで書く。Homebrew の `gsettings` は GNOME の設定 (dconf) に書かない

**[LazyVim の設定を導入する](#lazyvim-の設定を導入する)の手順 8**

- 2 行目で lazy.nvim が自分を clone し、プラグイン 38 個を入れる
- Mason の未完了の導入は、この項の手順 9 で補う
- tree-sitter の CLI が無ければ、先に Mason が入れる（``Installed `tree-sitter-cli` with `mason.nvim`.`` が出る）

**[LazyVim の設定を導入する](#lazyvim-の設定を導入する)の手順 9**

- `Error running markdownlint-cli2: ENOENT` が 1 回出てもよい (Mason が入れ終わる前に lint が走っただけ)
- `mason/bin` に `markdownlint-cli2` / `marksman` / `stylua` / `tree-sitter` などが並ぶ

**[LazyVim の日本語検索・整形・IME 連携を確かめる](#lazyvim-の日本語検索整形ime-連携を確かめる)の手順 1**

- 遅い VM では整形に数秒掛かる。Markdown / MDX の待ち時間の上限は 10 秒で、処理が終わればすぐ戻る
- これで導入は終わり

**[LazyVim の設定とプラグインの版を揃える](#lazyvim-の設定とプラグインの版を揃える)のリード**

- 外したプラグインは `:Lazy clean`、外した Mason ツールは `:MasonUninstall <名前>` で消す

**[LazyVim の設定とプラグインの版を揃える](#lazyvim-の設定とプラグインの版を揃える)の手順 1**

- Neovim が閉じてプロンプトが戻るまで待つ（パーサーを組み立てると時間がかかる。途中で止めない）

**[LazyVim の安全な Markdown 整形を導入する](#lazyvim-の安全な-markdown-整形を導入する)のリード**

- 整形器と依存は md-format の導入先（`~/.local/share/md-format`）にある。Neovim からは入れない。lint の診断用の markdownlint-cli2 は Mason で入る

**[LazyVim の安全な Markdown 整形を導入する](#lazyvim-の安全な-markdown-整形を導入する)の手順 1**

- Neovim の編集画面が開けばよい

**[LazyVim の安全な Markdown 整形を導入する](#lazyvim-の安全な-markdown-整形を導入する)の手順 2**

- 説明の対応や本文を変える修正は除外するため、一部の lint 診断は残ることがある

**[LazyVim のカーソル色を tmux で使う](#lazyvim-のカーソル色を-tmux-で使う)のリード**

- `tmux-256color` には `Cs` / `Cr` が無く、Neovim がカーソル色の OSC 12 を出さないため

**[LazyVim の IME 連携に GNOME の上部バーを合わせる](#lazyvim-の-ime-連携に-gnome-の上部バーを合わせる)のリード**

- GNOME Shell は ibus の engine が外から変わっても、上部バーと Super+Space が基準にする「今の入力ソース」を更新しない。そのため、この項を行わないと Neovim を開いた時点で上部バーがずれ、最初の Super+Space が空振りする
- この設定のリポジトリにある GNOME Shell の拡張 (`gnome-shell/ibus-engine-follow@ryo-aoki-pc.github.com`) を有効にする。engine が変わったときに「今の入力ソース」を合わせるだけで、engine やキー配列は変えない

**[LazyVim の IME 連携に GNOME の上部バーを合わせる](#lazyvim-の-ime-連携に-gnome-の上部バーを合わせる)の手順 1**

- `ibus-engine-follow@ryo-aoki-pc.github.com -> …/.config/nvim/gnome-shell/ibus-engine-follow@ryo-aoki-pc.github.com` と出ればよい
- つないでおくので、[取り込み](#lazyvim-の設定とプラグインの版を揃える)で拡張が変わると、次のログインから新しい方が使われる

**[LazyVim の IME 連携に GNOME の上部バーを合わせる](#lazyvim-の-ime-連携に-gnome-の上部バーを合わせる)の手順 3**

- `State: OUT OF DATE` と出たら、GNOME Shell の版が拡張の `metadata.json` の `shell-version` に無い

**[LazyVim のヤンクを SSH 越しに手元へ送る](#lazyvim-のヤンクを-ssh-越しに手元へ送る)のリード**

- 仕組みは端末の OSC 52 で、この設定が SSH のシェル (`SSH_CONNECTION` がある) で起動したときだけ使う。手元にも AlmaLinux 10 にも、足すソフトは無い

**[LazyVim のヤンクを SSH 越しに手元へ送る](#lazyvim-のヤンクを-ssh-越しに手元へ送る)の手順 1**

- 1 行目が `SSH_CONNECTION=` に続けて、接続元と接続先のアドレスとポートを 4 つ出せばよい

**[LazyVim の本体・外部コマンド・プラグインを更新する](#lazyvim-の本体外部コマンドプラグインを更新する)の手順 1**

- dnf で入れたもの (git・node など) は、OS の更新 (`sudo dnf upgrade`) で上がる

**[LazyVim の本体・外部コマンド・プラグインを更新する](#lazyvim-の本体外部コマンドプラグインを更新する)の手順 2**

- Neovim が閉じてプロンプトが戻るまで待つ（パーサーを組み立てると時間がかかる。途中で止めない）

**参照**

- 検証記録
- [AlmaLinux 10 の初期設定](almalinux-setup.md) — 「Homebrew」の手順 1〜2 が Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は参考資料、`brew` の基本操作は同書の「Homebrew の使い方の基本」

</details>

---

## Windows 11 で使う

- 導入済みの Neovim と自分用の設定・プラグインを更新する

### Windows 11 の LazyVim の更新

#### Windows 11 で LazyVim の設定とプラグインの版を揃える

- 設定と lazy-lock.json を取り込み、プラグインをその版に揃える
- 前提: scoop の Neovim と外部コマンドが入り、`%LOCALAPPDATA%\nvim` に自分用の設定の `custom` ブランチの clone がある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く
- 手元の変更は `git -C "$env:LOCALAPPDATA\nvim" status` で確認してから進む
- Markdown の整形器 md-format は、この項では上がらない。[Windows 11 で md-format を導入・更新する](https://github.com/ryo-aoki-pc/md-format/blob/main/docs/install.md#windows-11-で-md-format-を導入更新する)の手順 3 で上げる
- GitLab プレビューのアプリ md-preview も、この項では上がらない。[Windows 11 で md-preview を導入・更新する](https://github.com/ryo-aoki-pc/md-tools/blob/main/docs/install.md#windows-11-で-md-preview-を導入更新する)を通して上げる

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. Windows 11 では、設定を最新にしてプラグインを揃える。

   ```powershell
   # 設定を取り込み、プラグインの版を揃える
   $tsWait = "lua pcall(require, 'mason'); local TS, want = require('nvim-treesitter'), LazyVim.opts('nvim-treesitter').ensure_installed; vim.wait(600000, function() return vim.fn.executable('tree-sitter') == 1 end, 1000); for _ = 1, 20 do if TS.update():wait(900000) and TS.install(want):wait(900000) then break end end"
   git -C "$env:LOCALAPPDATA\nvim" pull --ff-only; if ($?) { nvim --headless "+Lazy! restore" "+$tsWait" +qa }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:LOCALAPPDATA\nvim" status --short
   ```

   - 途中で止めず、プロンプトが戻るまで待つ
   - `git status --short` が何も出さなければ、`lazy-lock.json` の版に揃っている
   - `M lazy-lock.json` を残すのでなければ、`git -C "$env:LOCALAPPDATA\nvim" checkout -- lazy-lock.json` で戻し、この手順を貼り直す
   - `Not possible to fast-forward` なら、`restore` も状態表示も走らない。push していないコミットを先に push するか、`git -C "$env:LOCALAPPDATA\nvim" log --oneline '@{u}..'` で見る
   - `Your local changes to the following files would be overwritten by merge:` が `lazy-lock.json` を挙げたら、手元で lock が変わっている
   - `:Lazy update` の結果として残すのでなければ、`git -C "$env:LOCALAPPDATA\nvim" checkout -- lazy-lock.json` で戻してから、この手順を貼り直す
   - `Lock file '…' appears stale` が出たら、[この文書の補足と注意点](#この文書の補足と注意点)の「注意点」で鍵を消してから、この項の手順 2 のブロックを貼り直す

#### Windows 11 で LazyVim の本体・外部コマンド・プラグインを更新する

- scoop で入れた本体と外部コマンド・LazyVim のプラグインを更新する
- 前提: scoop の Neovim と外部コマンドが入り、`%LOCALAPPDATA%\nvim` に自分用の設定の `custom` ブランチの clone がある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く
- 手元の変更は `git -C "$env:LOCALAPPDATA\nvim" status` で確認してから進む
- 設定の取り込みは[LazyVim の設定とプラグインの版を揃える](#windows-11-で-lazyvim-の設定とプラグインの版を揃える)で行う
- 更新後は動作を確認し、`lazy-lock.json` の差分をコミット・push する

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. Windows 11 では、scoop で入れたものを上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # scoop と Neovim・外部コマンドを更新する
   scoop update
   scoop update neovim ripgrep fd gcc nodejs zenhan lazygit
   # 更新後の Neovim の版を確かめる
   nvim --version | Select-Object -First 1
   ```

1. Windows 11 では、プラグインを上げて差分を見る。

   ```powershell
   # パーサーの導入を待ちながらプラグインを更新する
   $tsWait = "lua pcall(require, 'mason'); local TS, want = require('nvim-treesitter'), LazyVim.opts('nvim-treesitter').ensure_installed; vim.wait(600000, function() return vim.fn.executable('tree-sitter') == 1 end, 1000); for _ = 1, 20 do if TS.update():wait(900000) and TS.install(want):wait(900000) then break end end"
   nvim --headless "+Lazy! update" "+$tsWait" +qa
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:LOCALAPPDATA\nvim" diff --stat
   ```

   - 途中で止めず、プロンプトが戻るまで待つ
   - `lazy-lock.json` だけが変わっていればよい
   - `Lock file '…' appears stale` が出たら、[この文書の補足と注意点](#この文書の補足と注意点)の「注意点」で鍵を消してから、この項の手順 3 のブロックを貼り直す

<details id="windows-11-の-lazyvim-の更新-の補足と注意点">
  <summary>Windows 11 の LazyVim の更新 の補足と注意点</summary>

**[Windows 11 で LazyVim の設定とプラグインの版を揃える](#windows-11-で-lazyvim-の設定とプラグインの版を揃える)のリード**

- 外したプラグインは `:Lazy clean`、外した Mason ツールは `:MasonUninstall <名前>` で消す

**[Windows 11 で LazyVim の設定とプラグインの版を揃える](#windows-11-で-lazyvim-の設定とプラグインの版を揃える)の手順 2**

- `M lazy-lock.json` なら、導入時に lock が古い版で書き直されている。`git -C "$env:LOCALAPPDATA\nvim" checkout -- lazy-lock.json` で戻す
- 戻したら、この項の手順 2 のブロックを貼り直す
- Neovim が閉じてプロンプトが戻るまで待つ（パーサーを組み立てると時間がかかる。途中で止めない）

**[Windows 11 で LazyVim の本体・外部コマンド・プラグインを更新する](#windows-11-で-lazyvim-の本体外部コマンドプラグインを更新する)の手順 2**

- 最新なら `latest version` と出る

**[Windows 11 で LazyVim の本体・外部コマンド・プラグインを更新する](#windows-11-で-lazyvim-の本体外部コマンドプラグインを更新する)の手順 3**

- Neovim が閉じてプロンプトが戻るまで待つ（パーサーを組み立てると時間がかかる。途中で止めない）

**参照**

- 検証記録

</details>

---
