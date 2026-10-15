# Neovim のセットアップ（AlmaLinux 10・Windows 11）

- Neovim を入れ、自分用の設定（[LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter)。LazyVim をもとにした設定）を導入する。AlmaLinux 10 は Homebrew、Windows 11 は scoop で入れる
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/neovim.md)・[参考資料](reference/neovim.md)・[注意点](extra/neovim.md)。ロールバックは、ほかの道具と一緒に、2 冊のロールバック（[AlmaLinux 10](extra/almalinux-setup.md#端末とエディタを消す)・[Windows 11](extra/windows-setup.md#エディタとシェルのツールを消す)）で行う

> [!IMPORTANT]
> - AlmaLinux 10 の項は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)と同じく、**GNOME にログインした、インストール時の管理者ユーザー（`wheel`）の bash で行う**。`sudo -i`・`su -` のシェルでは行わない
> - Windows 11 の項は、[Windows 11 のセットアップ](windows-setup.md)と同じく、**この PC のデスクトップで、Administrators のユーザーが行う**。PowerShell のブロックは **Windows PowerShell 5.1** に貼る。管理者・通常の窓は、各項のリードに従う
> - Windows 11 で[貼り付けの設定](windows-setup.md#貼り付けの設定)より前は **Ctrl+V で貼る**。設定後は GitHub のコピーボタンでコピーし、右クリックで貼れる

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- Windows 11 で GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- Neovim は、AlmaLinux 10 は[AlmaLinux 10 のセットアップの「共通の bash 設定・Homebrew・Flatpak を上げる」](almalinux-setup.md#共通の-bash-設定homebrewflatpak-を上げる)の手順 3、Windows 11 は[Windows 11 のセットアップの「scoop・winget・WSL を上げる」](windows-setup.md#scoopwingetwsl-を上げる)で上がる。**設定やプラグインは更新に追従しない**。メジャー更新の後は `:checkhealth` で壊れていないか見る
- 自分用の設定のプラグインと外部コマンドは、[LazyVim の本体・外部コマンド・プラグインを更新する](#lazyvim-の本体外部コマンドプラグインを更新する)・[Windows 11 で LazyVim の本体・外部コマンド・プラグインを更新する](#windows-11-で-lazyvim-の本体外部コマンドプラグインを更新する)で上げる

## AlmaLinux 10 で使う

- Neovim と、自分用の LazyVim の設定

### Neovim

- Neovim を Homebrew で入れ、自分用の設定（LazyVim をもとにした設定）を入れて、既定のエディタになったことを確かめる
- 前提: [共通の bash 設定](shell-terminal.md#共通の-bash-設定)・[Homebrew](almalinux-setup.md#homebrew)・[WezTerm](shell-terminal.md#wezterm)を通し、PATH に Homebrew が入った端末（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2 で開き直した端末）を開いてある
  - この項の手順 3 は、[LazyVim の設定を導入する](#lazyvim-の設定を導入する)の前提も要る
  - インターネットに出られないホストは、[Homebrew](almalinux-setup.md#homebrew)の代わりに[Homebrew のオフライン導入](almalinux-setup.md#homebrew-のオフライン導入)を通し、そのトンネルのシェルで行う
- 実行場所: WezTerm のタブ（前提の、PATH に Homebrew が入った端末。GNOME にログインした自分のユーザーの bash）。この項の手順 4 で新しいタブを開く

1. brew で Neovim を入れる。

   ```bash
   brew install neovim
   ```

   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. Neovim が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   nvim --version | head -3
   brew list --versions neovim
   command -v nvim
   ```

   - `NVIM v0.12.…` と `LuaJIT 2.1...` が出れば入っている
   - ここでは `nvim` を起動しない（この項の手順 3 の退避より前に起動すると、`~/.local/state/nvim` などができて、それも退避される）
     - この手順の `nvim --version` だけでも、空の `~/.local/state/nvim/nvim.log` ができる。この項の手順 3 で、`~/.local/state/nvim.bak` に退避される

1. オフラインでは npm の経路を先に設定し、[自分用の設定](https://github.com/ryo-aoki-pc/LazyVimStarter)を入れる。

   - オフラインのホストでは、先に [npm のオフライン導入](almalinux-setup.md#npm-のオフライン導入)の手順 1・2 を同じトンネルのシェルで通す。参照先の「LazyVim の設定を導入する」の手順 10 の初回起動より前に行う
   - [LazyVim の設定を導入する](#lazyvim-の設定を導入する)の全項を、この項で指定した端末で通す
   - 参照先の手順 1 で Node.js・ibus-anthy・wl-clipboard、手順 5 で lazygit・ripgrep・fd を入れる
   - 参照先の手順 7〜9 で入力ソースを「英語 (US)」と Anthy にし、Ctrl+Space・Ctrl+J を Anthy の切り替えから外す。JIS 配列でも US にする
   - 参照先の手順 9 の後はログインし直さず、[再起動と確認](almalinux-setup.md#再起動と確認)の手順 1 の再起動で読み直す
   - 参照先の手順 11 で Neovim が開く。Mason の導入を待ち、`:qa` で閉じてから次を貼る（参照先の手順 12 は画面を開かない）
   - [日本語検索・整形・IME 連携の確認](#lazyvim-の日本語検索整形ime-連携を確かめる)は、[再起動と確認](almalinux-setup.md#再起動と確認)の手順 8 で行う

1. WezTerm で新しいタブを開き、既定のエディタを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%s / %s\n' "$EDITOR" "$VISUAL"
   alias vi
   ```

   - `nvim / nvim` と `alias vi='nvim'` が出ればよい
   - この 3 項目は共通の bash 設定が持つ（`nvim` があれば、開いたシェルで設定する）。元値の控えや `~/.bashrc` への追記は行わない
   - 開いていたタブは、`nvim` を入れる前の値のまま。`. ~/.bashrc` で読み直さない（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2）

#### Neovim の設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値（素の Vim に近い挙動）で動く
- 置き場所は `~/.config/nvim` で、読み込まれるのは `init.lua` か `init.vim` のどちらか一方
  - `XDG_CONFIG_HOME` を設定していれば `$XDG_CONFIG_HOME/nvim` になる。別の場所を使うなら `XDG_CONFIG_HOME` か `NVIM_APPNAME` を設定する
- Windows 11 の設定は `%LOCALAPPDATA%\nvim`（`init.lua`）、プラグイン・undo・ログは `%LOCALAPPDATA%\nvim-data`、キャッシュは `%TEMP%\nvim-data`
- Windows 11 の場所は[Windows 11 で Neovim を入れる](#windows-11-で-neovim-を入れる)の手順 5 で確かめる
  - Windows 11 では `XDG_CONFIG_HOME` を設定しない（[理由](reference/neovim.md#neovim-windows-11-では-選択した方針)）
- **自分用の設定**は [ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter) にある（LazyVim をベースに、日本語の入力・検索と Markdown（GLFM）の執筆を強くした設定）
  - 導入は[Neovim](#neovim)の手順 3
  - Windows 11 では既存の設定とデータを `.bak` に退避し、外部コマンドと設定を入れる
  - Windows 11 は、[Windows 11 で Neovim を入れる](#windows-11-で-neovim-を入れる)の手順 4 で通す
  - 何ができるか・どこを変えたかは [README の「主なカスタマイズ」](https://github.com/ryo-aoki-pc/LazyVimStarter#主なカスタマイズ)
- インターネットに出られないホストで、Mason が npm で入れるパッケージ（LSP サーバー・リンター）を入れるなら、[npm のオフライン導入](almalinux-setup.md#npm-のオフライン導入) を通す

#### LazyVim の設定を導入する

- 自分用の Neovim の設定（[ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter)）を `~/.config/nvim` に入れる。外部コマンドと日本語入力の設定を全部入れてから、Neovim を初回起動する
- 前提: [EPEL と RPM Fusion](almalinux-setup.md#epel-と-rpm-fusion)・[共通の bash 設定](shell-terminal.md#共通の-bash-設定)・[Homebrew](almalinux-setup.md#homebrew)・[HackGen Console NF](shell-terminal.md#hackgen-console-nf)を通し、[Neovim](#neovim)の手順 1・2 で Neovim を入れてある。PATH に Homebrew が入った端末（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2 で開き直した端末）を開いてある
- 実行場所: 前提の端末（GNOME にログインした自分のユーザーの bash）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ。`sudo` は、この項の手順 1 だけで使う。この項の手順 3 の既存の設定の退避を省かない
- [背景説明](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/reference/setup.md)・[検証記録](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/verification/setup.md)

1. 外部コマンドと日本語入力 (ibus-anthy) を dnf で入れる。

   ```bash
   sudo dnf install git gcc curl tar gzip unzip nodejs nodejs-npm file procps-ng ibus-anthy wl-clipboard
   ```

   - 何に使うかは[必要なもの一覧](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#必要なもの一覧)
   - ripgrep と fd は、この項の手順 5 で Homebrew から入れる (EPEL の `ripgrep` / `fd-find` は入れない)
   - EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる
   - 鍵の fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158` (`Fedora (epel10)`) であることを確かめてから `y` と答える
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る** (続けて貼ると答えとして食われる)

1. dnf で入ったか確かめる。

   ```bash
   rpm -q git gcc curl tar gzip unzip nodejs nodejs-npm file procps-ng ibus-anthy wl-clipboard
   node --version
   command -v gdbus busctl wl-paste
   ```

   - どの行も `package … is not installed` にならなければよい
   - `node --version` が `v22.…` と出る
   - `gdbus` / `busctl` / `wl-paste` の 3 つの場所が出る (`gdbus` と `busctl` は IME 連携が ibus と話すのに使う)

1. 既存の Neovim の設定とデータがあれば、`.bak` を付けて退避する。

   ```bash
   for d in ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim; do
     [ ! -e "${d}" ] || mv -vT "${d}" "${d}.bak"
   done
   ```

   - 退避したものは `renamed '…/nvim' -> '…/nvim.bak'` と出る。何も出なければ、退避するものは無かった
   - **注意**: `.bak` がすでにあると `mv` が `cannot overwrite` で止まる。古い `.bak` を片付けてから、この手順を貼り直す
   - 戻し方は[ロールバック](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#ロールバック)

1. この設定を `~/.config/nvim` に clone する。

   ```bash
   [ -e ~/.config/nvim/init.lua ] || git clone https://github.com/ryo-aoki-pc/LazyVimStarter.git ~/.config/nvim
   git -C ~/.config/nvim branch --show-current
   ```

   - `custom` と出ればよい (実運用の設定のブランチで、このリポジトリの既定のブランチ)
   - すでに clone してあれば、`git clone` は飛ばされる

1. lazygit・ripgrep・fd を Homebrew で入れる。

   ```bash
   brew install lazygit ripgrep fd
   ```

   - `Do you want to proceed with the installation? [y/n]` と聞かれたら、入るものの一覧 (依存を含む) を見て `y` と答える
   - lazygit は任意 (無ければ `<leader>gg` が定義されないだけ)
   - ripgrep (`rg`) と fd は、ピッカーと Migemo の候補が使う。EPEL の `ripgrep` / `fd-find` と二重に入れない (実行ファイルの名前が同じで、PATH の先頭の Homebrew 版が使われる)
   - **次の手順は、確認が出たら答え、インストールが成功してプロンプトに戻ってから貼る** (確認に答える前に続けて貼ると、答えとして食われる)

1. Neovim・lazygit・ripgrep・fd が入ったか確かめる。

   ```bash
   nvim --version | head -1
   command -v nvim lazygit rg fd
   ```

   - `NVIM v0.12.…` と出ればよい (0.12 以上が要る)
   - 4 つとも `/home/linuxbrew/.linuxbrew/bin/…` と出る

1. 入力ソースを「英語 (US)」と Anthy の 2 つにする。

   ```bash
   export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
   /usr/bin/gsettings get org.gnome.desktop.input-sources sources
   /usr/bin/gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'anthy')]"
   /usr/bin/gsettings get org.gnome.desktop.input-sources sources
   ```

   - 最後の行が `[('xkb', 'us'), ('ibus', 'anthy')]` になればよい
   - 最初の行は変える前の値。ほかの入力ソースは消える
   - 日本語と英数の切り替えは Super+Space になる
   - **注意**: JIS 配列のキーボードでも `us` にする。IME 連携が英数を `xkb:us::eng` に固定しているため
   - `gsettings` は `/usr/bin/gsettings` と場所まで書く。Homebrew の `gsettings` は GNOME の設定 (dconf) に書かない

1. Anthy の `on_off` のキーから `Ctrl+J` と `Ctrl+space` を外した値を作る。

   ```bash
   ANTHY_SHORTCUT=$(/usr/bin/gsettings get org.freedesktop.ibus.engine.anthy.shortcut default | sed "s/'on_off': <\['Zenkaku_Hankaku', 'Ctrl+space', 'Ctrl+J'\]>/'on_off': <['Zenkaku_Hankaku']>/")
   printf '%s\n' "${ANTHY_SHORTCUT}" | grep -o "'on_off': <\[[^]]*\]>"
   ```

   - `'on_off': <['Zenkaku_Hankaku']>` と出ればよい
   - `Ctrl+J` が残っている・何も出ないときは、この項の手順 9 は飛ばす。代わりに `ibus-setup-anthy` の「キー割り当て」で `on_off` から `Ctrl+J` と `Ctrl+space` を消す
   - **次の手順は、出た行を目で確かめてから貼る**

1. 作った値を Anthy の設定に書き戻す。

   ```bash
   /usr/bin/gsettings set org.freedesktop.ibus.engine.anthy.shortcut default "${ANTHY_SHORTCUT:?この項の手順 8 の ANTHY_SHORTCUT が空のまま。この項の手順 8 を貼り直す}"
   /usr/bin/gsettings get org.freedesktop.ibus.engine.anthy.shortcut default | grep -o "'on_off': <\[[^]]*\]>"
   ```

   - `'on_off': <['Zenkaku_Hankaku']>` と出ればよい
   - 以後、日本語と英数の切り替えは Super+Space と、Neovim の中の `<C-j>` になる
   - 導入後の[再起動と確認](almalinux-setup.md#再起動と確認)で Anthy と入力ソースを読み直す。日本語検索・IME 連携は[LazyVim の日本語検索・整形・IME 連携を確かめる](#lazyvim-の日本語検索整形ime-連携を確かめる)で行う

1. プラグインを入れ、`lazy-lock.json` の版に揃える。

   ```bash
   nvim --headless +qa
   git -C ~/.config/nvim checkout -- lazy-lock.json
   nvim --headless "+Lazy! restore" +qa
   git -C ~/.config/nvim status --short
   ```

   - 1 行目で lazy.nvim が自分を clone し、プラグイン 38 個を入れる。数分かかる
   - `Neovim is exiting while packages are still installing.`・`Unmet requirements for **nvim-treesitter**`・`Error in command line` は出ても進んでよい
   - 未完了の導入は、この項の手順 11 で補完する
   - 最後の `git status --short` が何も出さなければ、`lazy-lock.json` の版に揃っている
   - **次の手順は、プロンプトが戻ってから貼る** (最後のメッセージの行末に続けて出ることがある)

1. 試験用の Markdown を開いて、treesitter と Mason の導入を待つ。

   ```bash
   printf '%s\n' '#  動作確認' '' '日本語の検索を試す。' > /tmp/lazyvim-check.md
   nvim /tmp/lazyvim-check.md
   ```

   - 画面の下に `Downloading tree-sitter-…` などの通知が流れる
   - `Error running markdownlint-cli2: ENOENT` が 1 回出てもよい (Mason が入れ終わる前に lint が走っただけ)
   - `:Mason` を開き、Installed が 11 個になり、導入中のものが無くなるまで待つ (`q` で閉じる。tree-sitter の CLI を別に入れてあれば 10 個)
   - 待ったら `:qa` で閉じる
   - **次の手順は、`:qa` で閉じてから貼る** (続けて貼ると Neovim への入力として食われる)

1. 外部コマンドと Mason のツールが揃ったかを、`checkhealth` で確かめる。

   ```bash
   ls ~/.local/share/nvim/mason/bin
   nvim --headless "+Lazy! load mason.nvim luamigemo" "+checkhealth lazyvim luamigemo" "+w! /tmp/lazyvim-health.txt" +qa
   grep -E 'ERROR|WARNING' /tmp/lazyvim-health.txt
   ```

   - `mason/bin` に `markdownlint-cli2` / `marksman` / `stylua` / `tree-sitter` などが並ぶ
   - `grep` が何も出さないか、`` WARNING `fzf` is not installed `` の 1 行だけならよい (無視してよい。fzf が入っていれば出ない)
   - `ERROR` が出たら[注意点](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#注意点)

#### LazyVim の日本語検索・整形・IME 連携を確かめる

- 試験用の Markdown で、LazyVim の日本語検索・保存のときの整形・IME 連携・アイコンの表示を確かめる
- 前提: [WezTerm](shell-terminal.md#wezterm)・[LazyVim の設定を導入する](#lazyvim-の設定を導入する)・[LazyVim の安全な Markdown 整形を導入する](#lazyvim-の安全な-markdown-整形を導入する)を通し、その後に再起動してある（[再起動と確認](almalinux-setup.md#再起動と確認)の手順 1）
- 実行場所: 再起動の後に開いた WezTerm の新しいタブ（GNOME にログインした自分のユーザーの bash。`sudo` は使わない）

1. 試験用の Markdown を作って開き、日本語検索・整形・IME 連携を確かめる。

   ```bash
   printf '%s\n' '#  動作確認' '' '日本語の検索を試す。' > /tmp/lazyvim-check.md
   nvim /tmp/lazyvim-check.md
   ```

   - `/kensaku` と打って Enter を押す。3 行目の「検索」にカーソルが移り、`[1/1]` と出る
   - `/kensaku` と打って `<Tab>` を押す。入力が「検索」に置き換わる (候補が 1 つなので、すぐ確定する)。`<Esc>` で抜ける
   - `:w` で保存する。1 行目の `#` の後の 2 つの空白が 1 つになり、`# 動作確認` になる (glfm_markdownlint の整形)
   - 遅い VM では整形に数秒掛かる。Markdown / MDX の待ち時間の上限は 10 秒で、処理が終わればすぐ戻る
   - `o` で行を開き、`<C-j>` を押す。下の表示が `A` から `あ` に変わる。`<Esc>` で `A` に戻る
   - `<C-j>` を押したときは、カーソルのすぐ下にも `あ` / `A` が約 1 秒出る
   - `/` を押す。最下段の検索欄の右端に `A` が出る。`<C-j>` で `あ` に変わり、検索欄のカーソルのすぐ上にも `あ` が約 1 秒出て、カーソルが橙になる
   - `<Esc>` で抜ける。下の表示が `A` に戻り、次の `/` は `あ` で始まる (検索の sticky)。`<C-j>` で `A` にしてから `<Esc>` で抜ける
   - Space を 2 回押してファイルピッカーを開き、アイコンが豆腐でないことを見る (`<Esc>` で閉じる)
   - `:qa!` で閉じる (`o` で足した行は保存しない)
   - これで導入は終わり

#### LazyVim の設定とプラグインの版を揃える

- 設定と `lazy-lock.json` を取り込み、プラグインをその版に揃える
- 前提: [LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ。この項の手順 1 で `pull` が止まったときの、手元の変更の確認を省かない
- 初回と整形用 lock の変更後は、[LazyVim の安全な Markdown 整形を導入する](#lazyvim-の安全な-markdown-整形を導入する)を通し直す
- 外したプラグインは `:Lazy clean`、外した Mason ツールは `:MasonUninstall <名前>` で消す

1. AlmaLinux 10 では、設定を最新にしてプラグインを揃える。

   ```bash
   git -C ~/.config/nvim pull --ff-only && nvim --headless "+Lazy! restore" +qa
   git -C ~/.config/nvim status --short
   ```

   - `git status --short` が何も出さなければ、`lazy-lock.json` の版に揃っている
   - 起動時に `lazy-lock.json` が書き換わり、`git status --short` に `M lazy-lock.json` が出たら、`git -C ~/.config/nvim checkout -- lazy-lock.json` で戻す
   - 続けて `nvim --headless "+Lazy! restore" +qa` をもう一度貼る
   - `pull` が `Not possible to fast-forward` で止まったら、このマシンに push していないコミットがある。先に push するか、`git -C ~/.config/nvim log --oneline '@{u}..'` で中身を見る
   - `pull` が `Your local changes to the following files would be overwritten by merge:` と `lazy-lock.json` を出して止まったら、lock の変更を確認する
   - `:Lazy update` の結果として残すのでなければ、`git -C ~/.config/nvim checkout -- lazy-lock.json` で戻して、この手順を貼り直す

#### LazyVim の安全な Markdown 整形を導入する

- Markdown を保存のときに整形する依存（lock ファイルで固定した markdownlint-cli2・Comrak・js-beautify）を Neovim から入れ、整形を確かめる。AlmaLinux 10 / Windows 11 共通
- 前提: [LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通してある（Node.js 22 以上と npm が要る）
- 実行場所: 自分のユーザーの端末（bash。`sudo` は使わない）で開いた Neovim の中。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブで開く
- 初回と `tools/glfm-format/package-lock.json` の変更後に行う
- 整形用依存は Neovim のデータディレクトリの `glfm-format` に入る。Mason のツールとは別に管理する

1. Neovim で整形用の依存を導入する。

   ```vim
   :GlfmFormatInstall
   ```

   - 完了の通知が出るまで待つ
   - 取得するのは lock ファイルで固定した markdownlint-cli2・Comrak (WASM 版)・js-beautify (HTML の整形用)。整形時は通信しない
   - 失敗したら Node.js と npm が PATH にあるか確かめ、同じコマンドを入力し直す
   - lint の診断用は `:MasonInstall markdownlint-cli2` で導入する

1. Markdown ファイルで保存と手動整形を確かめる。

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
   - 説明の対応や本文を変える修正は除外するため、一部の lint 診断は残ることがある
   - `:ConformInfo` に `glfm_markdownlint` が出る。依存不足・設定不正・時間切れのときは原文を保持し、エラーを知らせる

#### LazyVim のカーソル色を tmux で使う

- 挿入モードのカーソル色も IME の状態で変わる。ただし tmux 越しでは既定では効かないので、tmux の設定に 1 行足す
- 前提: [LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通し、[シェルのツール](shell-terminal.md#シェルのツール)の手順 1 で tmux を入れてある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。この項の手順 2 は tmux の中のシェル。既存の `~/.tmux.conf` の確認（この項の手順 1）を省かない
- AlmaLinux 10 で tmux を使うときだけ行う。無くても害は無い
- `tmux-256color` には `Cs` / `Cr` が無く、Neovim がカーソル色の OSC 12 を出さないため

1. tmux の設定ファイルに `terminal-overrides` を 1 行足す。

   ```bash
   mkdir -p ~/.config/tmux
   grep -qF 'Cs=\E]12' ~/.config/tmux/tmux.conf 2>/dev/null || cat >> ~/.config/tmux/tmux.conf <<'EOF'
   set -ga terminal-overrides ',*:Cs=\E]12;%p1%s\007:Cr=\E]112\007'
   EOF
   ```

   - すでに書いてあれば足さない
   - **注意**: `~/.tmux.conf` があると、tmux は `~/.config/tmux/tmux.conf` を読まない。そのときは、この 1 行を `~/.tmux.conf` に書く

1. tmux の中で、設定を読み直して確かめる。

   ```bash
   tmux source-file ~/.config/tmux/tmux.conf
   tmux show-options -g terminal-overrides | grep -F 'Cs='
   ```

   - `terminal-overrides[0] "*:Cs=\\E]12;%p1%s\\007:Cr=\\E]112\\007"` のような行が出ればよい
   - `-ga` は足すたびに同じ値を増やすので、起動時と読み直しの分で 2 行出ることがある。害は無い
   - Neovim を起動し直すと、挿入モードで `<C-j>` を押したときにカーソルの色が変わる

#### LazyVim の IME 連携に GNOME の上部バーを合わせる

- Neovim がモードに合わせて IME を切り替えても、GNOME の上部バーの表示と Super+Space の順番がずれないようにする
- GNOME Shell は ibus の engine が外から変わっても、上部バーと Super+Space が基準にする「今の入力ソース」を更新しない。そのため、この項を行わないと Neovim を開いた時点で上部バーがずれ、最初の Super+Space が空振りする
- この設定のリポジトリにある GNOME Shell の拡張 (`gnome-shell/ibus-engine-follow@ryo-aoki-pc.github.com`) を有効にする。engine が変わったときに「今の入力ソース」を合わせるだけで、engine やキー配列は変えない
- 前提: [LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通してある（拡張は `~/.config/nvim` の中にある）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。この項の手順 3 からは、ログインし直した後に開いた端末
- AlmaLinux 10 + GNOME 49 のときだけ行う。拡張は GNOME Shell の内部の関数を使うので、GNOME を上げたらこの項の手順 4 で確かめる
- **この項の手順 2 で、ログアウトしてログインし直す**

1. 拡張を、GNOME Shell が拡張を探す場所につなぐ。

   ```bash
   mkdir -p ~/.local/share/gnome-shell/extensions
   ln -sfn ~/.config/nvim/gnome-shell/ibus-engine-follow@ryo-aoki-pc.github.com ~/.local/share/gnome-shell/extensions/
   ls -l ~/.local/share/gnome-shell/extensions/
   ```

   - `ibus-engine-follow@ryo-aoki-pc.github.com -> …/.config/nvim/gnome-shell/ibus-engine-follow@ryo-aoki-pc.github.com` と出ればよい
   - つないでおくので、[取り込み](#lazyvim-の設定とプラグインの版を揃える)で拡張が変わると、次のログインから新しい方が使われる

1. ログアウトしてログインし直す。

   - GNOME Shell (Wayland) は、新しい拡張をログインのときにしか探さない
   - **次の手順は、ログインし直した後の端末で貼る**

1. 拡張を有効にする。

   ```bash
   gnome-extensions enable ibus-engine-follow@ryo-aoki-pc.github.com
   gnome-extensions info ibus-engine-follow@ryo-aoki-pc.github.com | grep -E 'Enabled|State'
   ```

   - `Enabled: Yes` と `State: ACTIVE` が出ればよい
   - `doesn't exist` と出たら、この項の手順 1 のつなぎ先が無い (設定を取り込んでいない) か、ログインし直していない
   - `State: OUT OF DATE` と出たら、GNOME Shell の版が拡張の `metadata.json` の `shell-version` に無い

1. Neovim を開き、上部バーが Neovim の IME の状態に付いてくることを確かめる。

   ```bash
   printf '%s\n' '#  動作確認' '' '日本語の検索を試す。' > /tmp/lazyvim-check.md
   nvim /tmp/lazyvim-check.md
   ```

   - 開いた時点で、上部バーの入力ソースが英語 (US) になる (Neovim がノーマルモードで英数にするため)
   - `o` → `<C-j>` で、上部バーが Anthy (`あ`) になる。`<Esc>` で英語 (US) に戻る
   - ノーマルモードで Super+Space を 1 回押すと、上部バーと lualine の `あ` / `A` が一緒に変わる (空振りしない)
   - `:qa!` で閉じる

#### LazyVim のヤンクを SSH 越しに手元へ送る

- 手元の端末から AlmaLinux 10 に ssh して Neovim を使うとき、`y` `d` `x` などでレジスタに入れたものを、手元のクリップボードにも入れる
- 仕組みは端末の OSC 52 で、この設定が SSH のシェル (`SSH_CONNECTION` がある) で起動したときだけ使う。手元にも AlmaLinux 10 にも、足すソフトは無い
- 向きは Neovim → 手元だけ。手元でコピーしたものは、端末の貼り付け (WezTerm は Ctrl+Shift+V) で Neovim に入れる
- 前提: AlmaLinux 10 で、[LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通し、[LazyVim の設定とプラグインの版を揃える](#lazyvim-の設定とプラグインの版を揃える)の手順 1 で設定を最新にしてある。[システムの設定](almalinux-setup.md#システムの設定)の手順 3・4 で、SSH を待ち受けている
  - 手元は WezTerm nightly を使う（AlmaLinux 10 は[WezTerm](shell-terminal.md#wezterm)、Windows 11 は[シェルと端末のセットアップの「Windows 11 で WezTerm を入れる」](shell-terminal.md#windows-11-で-wezterm-を入れる)）。安定版 20240203 は設定があると OSC 52 を捨てる（[注意点](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#注意点)）
- 実行場所: **GNOME の端末ではなく、手元の WezTerm から AlmaLinux 10 に ssh したシェル**（ssh でログインした自分のユーザーの bash。`sudo` は使わない）。tmux の中の Neovim は扱わない

1. SSH のシェルで、この設定が OSC 52 を使うことを確かめる。

   ```bash
   printf 'SSH_CONNECTION=%s\n' "${SSH_CONNECTION:-(無い)}"
   nvim --headless "+lua io.stdout:write((vim.g.clipboard or {}).name or '(無い)', '\n')" +qa
   ```

   - 1 行目が `SSH_CONNECTION=` に続けて、接続元と接続先のアドレスとポートを 4 つ出せばよい
   - 2 行目が `OSC 52 (copy only)` と出ればよい
   - `SSH_CONNECTION=(無い)` と出たら、SSH のシェルではない (`sudo -i` や `su -` のシェルでは消える)。ssh でログインしたユーザーのシェルで貼り直す
   - 2 行目が `(無い)` と出たら、設定が古い。[LazyVim の設定とプラグインの版を揃える](#lazyvim-の設定とプラグインの版を揃える)の手順 1 を貼ってから、この手順を貼り直す

1. 試験用のテキストを開き、ヤンクした行が手元のクリップボードに入ることを確かめる。

   ```bash
   printf '%s\n' 'SSH 越しのヤンクを試す。' > /tmp/lazyvim-ssh.txt
   nvim /tmp/lazyvim-ssh.txt
   ```

   - `yy` を押す。手元のアプリ (メモ帳など) に貼り付けると、`SSH 越しのヤンクを試す。` が入る
   - `p` を押す。待たされずに、同じ行がすぐ下に入る
   - `:set clipboard?` が `clipboard=unnamedplus` と出る
   - `:qa!` で閉じる

#### LazyVim の GitLab プレビューを設定する

- LazyVim の Markdown のプレビュー（`<leader>cp`）を GitLab で描けるように、GitLab のトークンと URL を `~/.bashrc` に書く。設定しなくても近似プレビューは使える
- 前提: [LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通し、GitLab でスコープ `read_api` の個人アクセストークンを用意してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。`sudo` は使わない）。この項の手順 3 は、この項の手順 1・2 の後に開いた新しい端末
- 編集中の内容とトークンは設定した GitLab（空なら gitlab.com）に送る
- 削除は [LazyVim のロールバック](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#gitlab-プレビューの設定を消す)で行う

1. AlmaLinux 10 では、トークンを入力して `~/.bashrc` に書く。

   ```bash
   read -rsp 'GitLab のトークン: ' t && echo && sed -i '/^export GITLAB_TOKEN=/d' ~/.bashrc && printf 'export GITLAB_TOKEN=%q\n' "$t" >> ~/.bashrc; unset t
   ```

   - `GitLab のトークン: ` と出るので、トークンを貼って Enter を押す (画面には出ない)
   - 前に書いた `GITLAB_TOKEN` の行があれば、書き直す
   - **次の手順は、トークンを入力してから貼る**

1. AlmaLinux 10 で、gitlab.com 以外の GitLab (社内の GitLab など) を使うときは、その URL を入力して `~/.bashrc` に書く。

   ```bash
   read -rp 'GitLab の URL (gitlab.com なら空のまま Enter): ' h && sed -i '/^export GITLAB_HOST=/d' ~/.bashrc && { [ -z "$h" ] || printf 'export GITLAB_HOST=%q\n' "$h" >> ~/.bashrc; }; unset h
   ```

   - `https://gitlab.example.com` のように入力する (ホスト名だけでもよい)
   - 空のまま Enter を押すと、`GITLAB_HOST` を書かない (前に書いた行も消す)。送り先は gitlab.com になる
   - **次の手順は、URL を入力してから貼る**

1. AlmaLinux 10 では、新しい端末でこの設定の README を開き、プレビューで確かめる。

   ```bash
   nvim ~/.config/nvim/README.md
   ```

   - `<leader>cp` を押すとブラウザが開き、右上に `GitLab: gitlab.com` (設定した GitLab のホスト名) と出ればよい
   - `近似表示` と出たら、上のバナーに理由が出る ([注意点](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#注意点))
   - `<leader>cp` をもう一度押すと止まる。`:qa` で閉じる

#### LazyVim の本体・外部コマンド・プラグインを更新する

- Homebrew で入れた Neovim・lazygit・ripgrep・fd・HackGen と、LazyVim のプラグインを上げる
- 前提: [Homebrew](almalinux-setup.md#homebrew)と[LazyVim の設定を導入する](#lazyvim-の設定を導入する)を通し、PATH に Homebrew が入った端末（[シェルのツール](shell-terminal.md#シェルのツール)の手順 2 で開き直した端末）を開いてある
  - `lazy-lock.json` を push するには、[GitHub CLI](almalinux-setup.md#github-cli)でログインしてある
- 実行場所: 前提の端末（GNOME にログインした自分のユーザーの bash。`sudo` は使わない）。[WezTerm](shell-terminal.md#wezterm)を通したなら、WezTerm のタブ。この項の手順 2 の `lazy-lock.json` の差分の確認を省かない
- 設定の取り込みは[LazyVim の設定とプラグインの版を揃える](#lazyvim-の設定とプラグインの版を揃える)で行う
- プラグイン更新後は動作を確認し、`lazy-lock.json` の差分をコミット・push する

1. AlmaLinux 10 では、Homebrew で入れたものを上げる。

   ```bash
   brew upgrade neovim lazygit ripgrep fd
   brew upgrade --cask font-hackgen-nerd
   nvim --version | head -1
   ```

   - 最新なら `Warning: neovim 0.12.5_1 already installed` のように出て、何も上げない
   - dnf で入れたもの (git・node など) は、OS の更新 (`sudo dnf upgrade`) で上がる

1. AlmaLinux 10 では、プラグインを上げて `lazy-lock.json` の差分を見る。

   ```bash
   nvim --headless "+Lazy! update" +qa
   git -C ~/.config/nvim diff --stat
   ```

   - `lazy-lock.json` だけが変わっていればよい
   - 上げた後は、Neovim を起動して使えることを確かめてから、`lazy-lock.json` をコミットして push する

---

## Windows 11 で使う

- Neovim と、自分用の LazyVim の設定

### Windows 11 で Neovim を入れる

- scoop で Neovim を入れ、自分用の LazyVim の設定を導入する
- 前提: [アプリを入れる](windows-setup.md#アプリを入れる)の手順 2・3・[Git Bash と WezTerm の設定](shell-terminal.md#git-bash-と-wezterm-の設定)・[HackGen Console NF](shell-terminal.md#windows-11-で-hackgen-console-nf-を入れる)を通してある。Visual C++ ランタイムも[WezTerm](shell-terminal.md#windows-11-で-wezterm-を入れる)で入れてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. 管理者ではないことと、scoop・git・VC++ のランタイム・ほかの Neovim を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     VCRuntime  = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
     Nvim       = (Get-Command nvim -All -ErrorAction SilentlyContinue).Source -join ', '
   } | Format-List
   ```

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`True` なら、窓を閉じて、この項の手順 1 のとおりに開き直す
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に[アプリを入れる](windows-setup.md#アプリを入れる)の手順 2・3 で入れる
   - `Git` は `C:\Program Files\Git\cmd\git.exe` ならよい。空か違う場所なら、先に [Git for Windows](windows-setup.md#git-for-windows)
   - `VCRuntime : False` なら、[WezTerm](shell-terminal.md#windows-11-で-wezterm-を入れる)の手順 3 を管理者の Windows PowerShell で行ってから、この手順を貼り直す
   - `C:\Program Files\Neovim\bin\nvim.exe` など、ほかの場所が出たら、winget などで入れた Neovim がある。外してから始める

1. scoop で Neovim を入れる。

   ```powershell
   scoop install neovim
   ```

   - `'neovim' (0.12.5) was installed successfully!` の形の行が出ればよい
   - `'neovim' suggests installing 'extras/vcredist2022'.` も出るが、この項の手順 2 が `VCRuntime : True` なら入れなくてよい
   - `'neovim' (0.12.5) is already installed.` の形なら、もう入っている（何も変えない）
   - まだ `nvim` は起動しない（この項の手順 4 の退避より前に起動すると、`nvim-data` などができて、それも退避される）

1. 自分用の LazyVim の設定を導入する。

   - [LazyVim の設定を導入する](#windows-11-で-lazyvim-の設定を導入する)を通す。scoop・Git for Windows・Neovim 本体とフォントは、この項の前提と本体導入で用意済み
   - 参照先の既存設定の確認と退避を省かない
   - Neovim の画面を開く手順では、指定された `:qa` または `:qa!` で閉じてから先へ進む

1. 版と場所と、設定・データの置き場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   nvim --version | Select-Object -First 3
   (Get-Command nvim -All).Source
   nvim --clean --headless "+lua io.stdout:write(vim.fn.stdpath('config'), '\n', vim.fn.stdpath('data'), '\n')" +qa
   ```

   - `NVIM v0.12.5`・`Build type: Release`・`LuaJIT 2.1.…` の 3 行が出ればよい
   - 無出力で終わるか `VCRUNTIME140.dll` のエラーなら、VC++ ランタイムをこの項の手順 2 で確かめる
     - 窓が出たら、OK で閉じる
   - 2 つ目は `C:\Users\<WIN_USER>\scoop\shims\nvim.exe` の 1 行だけならよい
   - 最後に、設定の置き場所（`C:\Users\<WIN_USER>\AppData\Local\nvim`）とデータの置き場所（`…\AppData\Local\nvim-data`）の 2 行が出る（[AlmaLinux 10 の「Neovim の設定ファイル」](#neovim-の設定ファイル)）

#### Neovim を既定のエディタにする

- Windows PowerShell や Windows Terminal から起動するツールにも Neovim を使わせる
- 前提: [Neovim](#windows-11-で-neovim-を入れる)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- Git Bash では、[Git Bash と WezTerm の設定](shell-terminal.md#git-bash-と-wezterm-の設定)で入れた共通の bash 設定が `EDITOR`・`VISUAL` を `nvim` にするので、この項は要らない
- Git Bash の値は WezTerm の新しいタブで、[AlmaLinux 10 の「Neovim」](#neovim)の手順 4 のブロックを貼って確かめる（`. ~/.bashrc` は読み直さない）

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Windows の PowerShell でも使うように、`EDITOR`・`VISUAL` を `nvim` にする。

   ```powershell
   & {
     $other = @(foreach ($n in 'EDITOR', 'VISUAL') { [Environment]::GetEnvironmentVariable($n, 'User') }) | Where-Object { $_ -and $_ -ne 'nvim' }
     if ($other) { Write-Error "中断: ユーザーの環境変数 EDITOR か VISUAL に、nvim ではない値がある（$($other -join ', ')）" } else {
       foreach ($n in 'EDITOR', 'VISUAL') { [Environment]::SetEnvironmentVariable($n, 'nvim', 'User') }
       "`n$([char]27)[7m 確認 $([char]27)[0m"
       foreach ($n in 'EDITOR', 'VISUAL') { '{0} = {1}' -f $n, [Environment]::GetEnvironmentVariable($n, 'User') }
     }
   }
   ```

   - `EDITOR = nvim` と `VISUAL = nvim` が出ればよい（何度貼ってもよい）
   - `中断:` と出たら、何も変えていない。ほかのエディタを使っているなら、この手順は行わない
   - 効くのは、この後に開いた窓とアプリから（開いている窓には入らない。WezTerm は新しいタブから）

1. 元に戻すときは、ユーザーの環境変数 `EDITOR`・`VISUAL` を消す。

   ```powershell
   foreach ($n in 'EDITOR', 'VISUAL') { if ([Environment]::GetEnvironmentVariable($n, 'User') -eq 'nvim') { [Environment]::SetEnvironmentVariable($n, $null, 'User') } }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($n in 'EDITOR', 'VISUAL') { '{0} = {1}' -f $n, [Environment]::GetEnvironmentVariable($n, 'User') }
   ```

   - `EDITOR = ` と `VISUAL = `（どちらも値が空）が出ればよい
   - 値が `nvim` のときだけ消す（ほかの値は残る）

#### Windows 11 で LazyVim の設定を導入する

- Windows の Neovim に自分用の LazyVim の設定と外部コマンド・プラグインを入れる
- 前提: [Git for Windows](windows-setup.md#git-for-windows)・[アプリを入れる](windows-setup.md#アプリを入れる)の手順 2・3・[HackGen Console NF](shell-terminal.md#windows-11-で-hackgen-console-nf-を入れる)と、[Neovim](#windows-11-で-neovim-を入れる)で本体を先に入れてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- この項の手順 3 の退避前に Neovim をすべて閉じる。既存設定とデータの確認・退避を省かない
- Visual C++ ランタイムの導入時だけインストーラーの UAC を許可する
- [背景説明](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/reference/setup.md)・[検証記録](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/verification/setup.md)

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. git が無ければ入れ、scoop に `extras` のバケットを足す。

   ```powershell
   if (-not (Get-Command git -ErrorAction SilentlyContinue)) { scoop install git }
   scoop bucket add extras
   ```

   - Git for Windows などで git がすでにあれば、`scoop install git` は飛ばされる
   - バケットの追加に git が要る。lazygit は `extras` にある

1. 既存の Neovim の設定とデータがあれば、`.bak` を付けて退避する。

   ```powershell
   & {
     $nvimPaths = @("$env:LOCALAPPDATA\nvim", "$env:LOCALAPPDATA\nvim-data")
     foreach ($d in $nvimPaths) {
       if (Test-Path -LiteralPath "${d}.bak") { throw "中断: ${d}.bak がすでにある。何も退避していない" }
     }
     foreach ($d in $nvimPaths) {
       if (Test-Path -LiteralPath $d) {
         Move-Item -LiteralPath $d -Destination "${d}.bak" -ErrorAction Stop
         "moved: $d"
       }
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     $nvimPaths | ForEach-Object { '{0}: {1}' -f $_, (Test-Path -LiteralPath $_) }
   }
   ```

   - 退避したものは `moved: …` と出る。最後の 2 行がどちらも `False` なら、元の設定とデータは残っていない
   - `.bak` が 1 つでもあれば、どちらも動かさず `中断:` で止まる。中身を確かめて片付けてから、この項の手順 3 を貼り直す
   - `nvim` は設定、`nvim-data` はプラグイン・Mason のツール・undo など

1. この設定を `%LOCALAPPDATA%\nvim` に clone する。

   ```powershell
   if (-not (Test-Path "$env:LOCALAPPDATA\nvim\init.lua")) { git clone https://github.com/ryo-aoki-pc/LazyVimStarter.git "$env:LOCALAPPDATA\nvim" }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:LOCALAPPDATA\nvim" branch --show-current
   ```

   - `custom` と出ればよい
   - すでに clone してあれば、`git clone` は飛ばされる

1. Visual C++ のランタイムが無いときだけ入れ、外部コマンド・zenhan・lazygit を scoop で入れる。

   ```powershell
   if (-not (Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll")) { scoop install vcredist2022 }
   scoop install ripgrep fd gcc nodejs zenhan lazygit
   ```

   - 1 行目は、ランタイム (`System32\vcruntime140.dll`) がすでにあれば何もしない (ほかのアプリや winget で入れてある PC では、UAC も出ない)
   - ランタイムが無ければ `vcredist2022` を入れる。PowerShell は非管理者のまま、Visual C++ のインストーラーの UAC を許可する (x64・x86 の両方を入れる。標準ユーザーなら管理者の認証情報が要る)
   - `zenhan` は IME 連携に使う。無ければ IME 連携だけが静かに無効になる
   - `lazygit` は任意 (無ければ `<leader>gg` が定義されないだけ)
   - 2 行目のパッケージは、導入済みなら何も出さずに飛ばされる (scoop は複数を並べると `already installed` を出さない)

1. 入ったか確かめ、フォントを入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   nvim --version | Select-Object -First 1
   Get-Command rg, fd, gcc, node, npm, zenhan, lazygit | Format-Table Name, Source
   ```

   - `NVIM v0.12.…` と出ればよい (0.12 以上が要る)
   - 7 つのコマンドの場所が並ぶ
   - 端末のフォントは[HackGen Console NF](shell-terminal.md#windows-11-で-hackgen-console-nf-を入れる)にする

1. プラグインを入れ、`lazy-lock.json` の版に揃える。

   ```powershell
   nvim --headless +qa
   git -C "$env:LOCALAPPDATA\nvim" checkout -- lazy-lock.json
   nvim --headless "+Lazy! restore" +qa
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:LOCALAPPDATA\nvim" status --short
   ```

   - 数分かかる。Mason と treesitter の中断のメッセージは出てよい
   - 最後の `git status --short` が何も出さなければ、`lazy-lock.json` の版に揃っている
   - 理由は [lock 復元の説明](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/reference/setup.md#lazy-lockjson-を戻してから-restore-する理由)を参照する
   - **次の手順は、プロンプトが戻ってから貼る**

1. 試験用の Markdown を開いて、treesitter と Mason の導入を待つ。

   ```powershell
   Set-Content -Path "$env:TEMP\lazyvim-check.md" -Value '#  動作確認', '', '日本語の検索を試す。' -Encoding UTF8
   nvim "$env:TEMP\lazyvim-check.md"
   ```

   - `:Mason` を開き、Installed が 11 個になり、導入中のものが無くなるまで待つ (`q` で閉じる)
   - 待ったら `:qa` で閉じる
   - **次の手順は、`:qa` で閉じてから貼る** (続けて貼ると Neovim への入力として食われる)

1. 外部コマンドと Mason のツールが揃ったかを、`checkhealth` で確かめる。

   ```powershell
   nvim --headless "+Lazy! load mason.nvim luamigemo" "+checkhealth lazyvim luamigemo" "+w! $env:TEMP\lazyvim-health.txt" +qa
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Select-String -Path "$env:TEMP\lazyvim-health.txt" -Pattern 'ERROR|WARNING'
   ```

   - `` WARNING `fzf` is not installed `` の 1 行だけならよい (無視してよい)
   - `ERROR` が出たら[注意点](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#注意点)

1. 試験用の Markdown を開き、日本語検索・整形・IME 連携を確かめる。

   ```powershell
   nvim "$env:TEMP\lazyvim-check.md"
   ```

   - `/kensaku` で「検索」に移り、検索欄の `<Tab>` で「検索」に置き換わることを確かめる。`:w` で見出しの `#` の後の空白が 1 つになり (`# 動作確認`)、`<C-j>` で `A` / `あ` が切り替わり、ファイルピッカーのアイコンが表示されればよい
   - 初めてなら [安全な整形の導入](#windows-11-で-lazyvim-の安全な-markdown-整形を導入する) を済ませる
   - `:lua =vim.fn.executable("zenhan")` が `1` なら IME 連携が有効 (`0` でもほかは動く)
   - OS 側で IME を切り替えると、lualine の `あ` / `A` がずれることがある（[README](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/README.md#日本語入力検索)）
   - `:qa!` で閉じる。これで導入は終わり

#### Windows 11 で LazyVim の設定とプラグインの版を揃える

- 設定と lazy-lock.json を取り込み、プラグインをその版に揃える
- 前提: [LazyVim の設定を導入する](#windows-11-で-lazyvim-の設定を導入する)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- 手元の変更は `git -C "$env:LOCALAPPDATA\nvim" status` で確認してから進む
- 初回と整形用 lock の変更後は[LazyVim の安全な Markdown 整形を導入する](#windows-11-で-lazyvim-の安全な-markdown-整形を導入する)を通す
- 外したプラグインは `:Lazy clean`、外した Mason ツールは `:MasonUninstall <名前>` で消す

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Windows 11 では、設定を最新にしてプラグインを揃える。

   ```powershell
   git -C "$env:LOCALAPPDATA\nvim" pull --ff-only; if ($?) { nvim --headless "+Lazy! restore" +qa }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:LOCALAPPDATA\nvim" status --short
   ```

   - `git status --short` が何も出さなければ、`lazy-lock.json` の版に揃っている
   - `M lazy-lock.json` なら、導入時に lock が古い版で書き直されている。`git -C "$env:LOCALAPPDATA\nvim" checkout -- lazy-lock.json` で戻す
   - 続いて `nvim --headless "+Lazy! restore" +qa` をもう一度貼る。2 回目は導入も lock の書き直しも無い
   - `Not possible to fast-forward` なら、`restore` も状態表示も走らない。push していないコミットを先に push するか、`git -C "$env:LOCALAPPDATA\nvim" log --oneline '@{u}..'` で見る
   - `Your local changes to the following files would be overwritten by merge:` が `lazy-lock.json` を挙げたら、手元で lock が変わっている
   - `:Lazy update` の結果として残すのでなければ、`git -C "$env:LOCALAPPDATA\nvim" checkout -- lazy-lock.json` で戻してから、この手順を貼り直す

#### Windows 11 で LazyVim の安全な Markdown 整形を導入する

- Neovim に安全な Markdown 整形の依存を入れ、保存と手動整形を確かめる
- 前提: [LazyVim の設定を導入する](#windows-11-で-lazyvim-の設定を導入する)を通し、Node.js 22 以上と npm が使える
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 2 からは、その窓で起動する Neovim
- 初回と `tools/glfm-format/package-lock.json` の変更後に行う
- 整形用依存は Neovim のデータディレクトリの `glfm-format` に入る

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. 試験用の Markdown を Neovim で開く。

   ```powershell
   nvim "$env:TEMP\lazyvim-format-check.md"
   ```

   - Neovim の編集画面が開けばよい
   - **次の手順は、Esc を押し、Neovim の `:` のコマンドラインに入力する**（PowerShell には貼らない）

1. Neovim で整形用の依存を導入する。

   ```vim
   :GlfmFormatInstall
   ```

   - 完了の通知が出るまで待つ
   - 取得するのは lock ファイルで固定した markdownlint-cli2・Comrak (WASM 版)・js-beautify (HTML の整形用)。整形時は通信しない
   - 失敗したら Node.js と npm が PATH にあるか確かめ、同じコマンドを入力し直す
   - lint の診断用は `:MasonInstall markdownlint-cli2` で導入する
   - **次の手順は、完了の通知が出てから `i` を押し、挿入モードの本文に貼る**

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

   - 貼り終えたら Esc を押し、ノーマルモードに戻る
   - `:w` または `<leader>cf` で `#  動作確認` の `#` の後の空白が 1 つになる (`# 動作確認`)
   - `内部の項目` の行頭の 2 スペースが保たれる
   - `<summary>` の行が 2 スペース字下げになる。空行と `本文` はそのまま
   - `<table>` の行が `<tr>`・`<td>` ごとの 6 行に分かれ、入れ子に合わせて 2 スペースずつ字下げされる
   - `<leader>cf` はビジュアル選択した範囲にも使える
   - 説明の対応や本文を変える修正は除外するため、一部の lint 診断は残ることがある
   - `:ConformInfo` に `glfm_markdownlint` が出る。依存不足・設定不正・時間切れのときは原文を保持し、エラーを知らせる
   - 確かめ終えたら `:qa!` で閉じる。試験用の `%TEMP%\lazyvim-format-check.md` は、要らなければ手で消す
   - **ほかのブロックは、Neovim を閉じてから貼る**（続けて貼ると Neovim への入力として食われる）

#### Windows 11 で LazyVim の GitLab プレビューを設定する

- GitLab プレビュー用のトークンと、送り先の GitLab を自分のユーザーの環境変数に設定する
- 前提: [LazyVim の設定を導入する](#windows-11-で-lazyvim-の設定を導入する)を通してある。GitLab でスコープ `read_api` の個人アクセストークンを用意してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 4 で通常の窓を開き直し、手順 5 で Neovim を起動する
- 編集中の内容とトークンは設定した GitLab（空なら gitlab.com）に送る
- 設定しなくても近似プレビューは使える
- 削除は[LazyVim のロールバック](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#gitlab-プレビューの設定を消す)で行う

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Windows 11 では、トークンを入力して、ユーザーの環境変数にする。

   ```powershell
   [Environment]::SetEnvironmentVariable('GITLAB_TOKEN', [pscredential]::new('gitlab', (Read-Host -AsSecureString 'GitLab のトークン')).GetNetworkCredential().Password, 'User')
   ```

   - `GitLab のトークン: ` と出るので、トークンを貼って Enter を押す (画面には `*` で出る)
   - Enter の後、プロンプトが戻るまで 2 秒ほどかかる
   - 前に設定した値があれば、置き換わる
   - **次の手順は、トークンを入力し、プロンプトが戻ってから貼る**

1. Windows 11 で、gitlab.com 以外の GitLab を使うときは、その URL を入力して、ユーザーの環境変数にする。

   ```powershell
   $h = Read-Host 'GitLab の URL (gitlab.com なら空のまま Enter)'; if ($h) { [Environment]::SetEnvironmentVariable('GITLAB_HOST', $h, 'User') } else { [Environment]::SetEnvironmentVariable('GITLAB_HOST', $null, 'User') }
   ```

   - `https://gitlab.example.com` のように入力する (ホスト名だけでもよい)
   - 空のまま Enter を押すと、`GITLAB_HOST` を消す。送り先は gitlab.com になる
   - Enter の後、プロンプトが戻るまで 2 秒ほどかかる
   - **次の手順は、URL を入力し、プロンプトが戻ってから貼る**

1. 管理者ではない Windows PowerShell（5.1）を開き直す。

   - この項の手順 1 の窓を閉じ、スタートメニューで「Windows PowerShell」をクリックして開く（管理者として実行しない）
   - **次の手順は、開き直した PowerShell に貼る**

1. Windows 11 では、新しい端末でこの設定の README を開き、プレビューで確かめる。

   ```powershell
   nvim "$env:LOCALAPPDATA\nvim\README.md"
   ```

   - `<leader>cp` の右上に `GitLab: <ホスト名>` が出ればよい。近似表示ならバナーの理由を確認する。もう一度 `<leader>cp` で止め、`:qa` で閉じる
   - Neovide で使うなら、Neovide も起動し直す

#### Windows 11 で LazyVim の本体・外部コマンド・プラグインを更新する

- scoop で入れた本体と外部コマンド・LazyVim のプラグインを更新する
- 前提: [LazyVim の設定を導入する](#windows-11-で-lazyvim-の設定を導入する)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- 手元の変更は `git -C "$env:LOCALAPPDATA\nvim" status` で確認してから進む
- 設定の取り込みは[LazyVim の設定とプラグインの版を揃える](#windows-11-で-lazyvim-の設定とプラグインの版を揃える)で行う
- 更新後は動作を確認し、`lazy-lock.json` の差分をコミット・push する

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Windows 11 では、scoop で入れたものを上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop update
   scoop update neovim ripgrep fd gcc nodejs zenhan lazygit
   nvim --version | Select-Object -First 1
   ```

   - 最新なら `latest version` と出る

1. Windows 11 では、プラグインを上げて差分を見る。

   ```powershell
   nvim --headless "+Lazy! update" +qa
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git -C "$env:LOCALAPPDATA\nvim" diff --stat
   ```

   - `lazy-lock.json` だけが変わっていればよい

---
