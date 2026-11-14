# シェルと端末のセットアップ（AlmaLinux 10・Windows 11）

- AlmaLinux 10 では、自分用の共通の bash 設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）と、シェルのツール（starship・zoxide・fzf・eza・bat・tmux）、端末のフォント（HackGen Console NF）、端末（WezTerm nightly と自分用の設定 [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)）を入れる。Windows 11 では、導入済みのフォント・共通の bash 設定・WezTerm の設定・PowerShell の開発の設定を更新する
- 検証記録・参考資料・注意点は、各用途の末尾の「補足と注意点」と、冒頭の「この文書の補足と注意点」から開く

> [!IMPORTANT]
> - AlmaLinux 10 の項は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)と同じく、**GNOME にログインした、インストール時の管理者ユーザー（`wheel`）の bash で行う**。`sudo -i`・`su -` のシェルでは行わない
> - AlmaLinux 10 の項は、パスワードを聞かない `sudo` を前提に書いてある。各項のリードの前提に無くても、その項を行うユーザーで[ログインと sudo](almalinux-setup.md#ログインと-sudo)を先に通す
> - Windows 11 の項は、[Windows 11 のセットアップ](windows-setup.md)と同じく、**この PC のデスクトップで、Administrators のユーザーが行う**。PowerShell のブロックは **PowerShell 7** に貼る（[公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)）。複数行は、貼った全体が 1 つの入力になり、Enter で実行する設定の窓に貼る。Windows PowerShell 5.1 に貼る項は、その項のリードに書く。管理者・通常の窓と Git Bash は、各項のリードに従う
> - conhost の窓で複数行を右クリックで貼るときは、使う版の PSReadLine の Ctrl+Enter が `AddLine` に割り当てられ、貼った行が順番どおりに 1 つの入力になることを前提にする。未設定の窓では Ctrl+V で貼る

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- ほかの手順書の項を前提にする項がある（各項のリードの前提からリンクで開く）。AlmaLinux 10 は[Homebrew](almalinux-setup.md#homebrew)（オフラインのホストは[Homebrew のオフライン導入](almalinux-setup.md#homebrew-のオフライン導入)）、Windows 11 は[scoop](https://scoop.sh/)・[PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)・[Git for Windows](https://gitforwindows.org/)を導入し、Microsoft Store のアプリの更新を済ませてある
- bash のブロックは、ブラケットペーストの効く端末（GNOME の端末・WezTerm・SSH の先）に貼り、貼った後に Enter を押す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- Windows 11 で GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- 入れたものを上げるとき
  - 共通の bash 設定は、[共通の bash 設定を更新する](#共通の-bash-設定を更新する)・[Windows 11 で共通の bash 設定を更新する](#windows-11-で共通の-bash-設定を更新する)で上げる。AlmaLinux 10 で Homebrew・Flatpak とまとめて上げるなら、[AlmaLinux 10 のセットアップの「共通の bash 設定・Homebrew・Flatpak を上げる」](almalinux-setup.md#共通の-bash-設定homebrewflatpak-を上げる)
  - AlmaLinux 10 のシェルのツールと HackGen Console NF は、同じ「共通の bash 設定・Homebrew・Flatpak を上げる」の手順 3（Homebrew）で上がる。Windows 11 のシェルのツールは[Windows 11 のセットアップの「scoop・winget・WSL を上げる」](windows-setup.md#scoopwingetwsl-を上げる)、HackGen Console NF は[HackGen Console NF を上げる](#hackgen-console-nf-を上げる)で上げる
  - WezTerm は、AlmaLinux 10 は OS の更新（[AlmaLinux 10 のセットアップの「更新」](almalinux-setup.md#更新)）で上がる。Windows 11 は[Windows 11 のセットアップの「Git for Windows・Firefox・WezTerm を上げる」](windows-setup.md#git-for-windowsfirefoxwezterm-を上げる)で上げる。自分用の WezTerm の設定は、[WezTerm の設定を更新する](#wezterm-の設定を更新する)・[Windows 11 で WezTerm の設定を更新する](#windows-11-で-wezterm-の設定を更新する)で上げる
  - PowerShell の開発用モジュールと補完の控えは、[PowerShell の開発の設定を更新する](#powershell-の開発の設定を更新する)で上げる。scoop で道具を上げた後は、補完の控えも作り直す

<details id="この文書の補足と注意点">
  <summary>この文書の補足と注意点</summary>

**注意点**

- **HackGen Console NF: Console 版は記号が半角になる**: 矢印などが 1 セル幅で出る（`wezterm ls-fonts --text '→'` で `cells=1`）
  - Console ではない通常版（HackGen / HackGen35）は NF 版の zip に入っておらず、NF 無しの cask `font-hackgen` にある

- **HackGen Console NF: NF 版と NF 無しの版は別の cask**: `font-hackgen-nerd`（Console の 2 ファミリー × NF）と `font-hackgen`（4 ファミリー、アイコン無し）
  - ファミリー名は NF 版だけ末尾に ` NF` が付く

- **HackGen Console NF: ファミリー名は `HackGen Console NF`**（スペース入り）。ファイル名（`HackGenConsoleNF-Regular.ttf`）や PostScript 名（`HackGenConsoleNF-Regular`）とは違う。アプリの設定にはファミリー名を書く

- **HackGen Console NF: GNOME の端末や VS Code など WezTerm 以外のアプリ**: それぞれの設定でファミリー名 `HackGen Console NF` を指定する

- **HackGen Console NF: Powerline の記号**: WezTerm は `U+E0B0` などの一部の記号を既定で自分で描く（`custom_block_glyphs`）。ほかの端末ではフォントのグリフが使われる

- **PSReadLine の Emacs モードは、それより前に付けたキーを既定に戻す**: EditMode の行を、キーの割り当てより前に置く。Ctrl+V は `Paste` を割り当て直す。開いている窓では切り替えず、新しい窓で確かめる

- PSReadLine の履歴のファイルは、5.1 と 7 で共有する

- **文書全体の補足**

- PowerShell 7 のプロファイルと Windows Terminal の資料（文書・コード）は、Windows 11 のセットアップの[この文書の補足と注意点](windows-setup.md#この文書の補足と注意点)の「参照」にある

- **WezTerm の設定ファイルの場所**

- [WezTerm](#wezterm)の手順 3 で入れた自分用の設定は、`~/.config/wezterm/wezterm.lua`（下の表の 5）

| 優先 | 場所 | 用途 |
|---|---|---|
| 1 | `wezterm --config-file <path>` | 一時的に別の設定で起動する |
| 2 | 環境変数 `WEZTERM_CONFIG_FILE` | 同上（環境ごとに切り替える） |
| 3 | `~/.wezterm.lua` | **1 ファイルで済む設定はここ**（公式の推奨） |
| 4 | `${XDG_CONFIG_HOME}/wezterm/wezterm.lua`（`XDG_CONFIG_HOME` を設定している場合のみ） | 複数ファイルに分ける設定 |
| 5 | `~/.config/wezterm/wezterm.lua`（`XDG_CONFIG_HOME` 未設定のとき） | 同上 |

- **Windows 11 では**、`~` は `%USERPROFILE%`（`C:\Users\<WIN_USER>`）。置くのは `%USERPROFILE%\.wezterm.lua` か `%USERPROFILE%\.config\wezterm\wezterm.lua`
  - 表の 2 と 3 の間に、`wezterm.exe` と同じフォルダーの `wezterm.lua`（`C:\Program Files\WezTerm\wezterm.lua`）が入る。USB メモリで持ち運ぶとき用で、公式は勧めていない

**選択した方針**

- 手順書のブロックは、貼った全体が 1 つの入力になる窓に貼る前提で書く（2026-11-07、利用者の決定）。bash はブラケットペースト、PowerShell は Enter の割り当てで、そうなる
  - 対話（`[y/N]`・パスワード・`Read-Host`・`choice.exe`・エディタ・TUI）のコマンドの後ろの行は、答えとして読まれず、対話が終わってから動く。`sudo` の後ろの行も捨てられない。そのため、対話のコマンドの後ろでも手順を分けず、`sudo` の後ろの行を `{ }` で囲まない
  - 子のシェル（`ssh`・`tmux`・`distrobox enter`・子の PowerShell など）の後ろの行は、その中ではなく、閉じた後の元のシェルで動き、`exec` の後ろの行は消える。PowerShell では、Ctrl+C が同じ入力の後ろの文も止める。こうなる所では、今までどおり手順を分ける
  - 貼っただけでは動かず、Enter で動く（bash は、末尾に改行があっても Enter を待つ）
  - 実測は検証記録の付録（`docs/verification/shell-terminal.md` の「付録: ブラケットペーストで貼ったときの対話と sudo（2026-11-07）」）

**参照**

- [yuru7/HackGen](https://github.com/yuru7/HackGen) — フォントの特徴、ファミリーの種類、ライセンス、リリース
- [Nerd Fonts](https://www.nerdfonts.com/) — 追加されているアイコンの一覧（コードポイントの確認に使える）

- 検証記録（`docs/verification/shell-terminal.md`）

</details>

## AlmaLinux 10 で使う

- 共通の bash 設定・シェルのツール・HackGen Console NF・WezTerm

### 共通の bash 設定

- 自分のユーザーに共通の bash 設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）を入れ、bash-completion と `~/.inputrc` で補完と履歴の検索を整える
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash）

1. 共通の bash 設定を入れる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git clone https://github.com/ryo-aoki-pc/bash.git ~/.config/bash &&
     bash ~/.config/bash/install.sh
   ```

   - `~/.bashrc: 設定済み` と `完了: 端末を開き直す。` が出ればよい
   - clone 済みで `fatal: destination path … already exists` と出たら、`git -C ~/.config/bash pull --ff-only` と `bash ~/.config/bash/install.sh` を貼る

1. 共通の bash 設定を今の端末に読み込み、履歴と shopt の値を確かめる。

   ```bash
   # 共通の bash 設定を読み込む
   . ~/.bashrc
   printf '\n\033[7m 確認 \033[0m\n'
   # 共通設定の読み込みを確かめる
   echo "${__bash_config_loaded-読まれていない}"
   # 履歴とシェルの設定を確かめる
   printf '%s\n' "$HISTSIZE" "$HISTFILESIZE" "$HISTCONTROL"
   shopt histappend autocd cdspell dirspell globstar
   ```

   - `1`、`100000`・`100000`・`ignoreboth`、5 つの `on` が出ればよい

1. bash-completion が入っているか確かめ、無ければ入れる。

   ```bash
   if ! rpm -q bash-completion; then sudo dnf install -y bash-completion; fi
   ```

   - `bash-completion` の版が出れば入っている
   - `package bash-completion is not installed` のときは、続けて BaseOS から入る

1. `~/.inputrc` を書き、今のシェルにも読ませる。

   ```bash
   # readline の設定を用意する
   if [ -e ~/.inputrc ]; then
     echo '中断: ~/.inputrc がすでにある。中身を見て、この手順の set と矢印の行を手で足す' >&2
   else
     cat > ~/.inputrc <<'EOF'
   # OS の設定（Home / End / Delete、Ctrl+矢印の単語の移動など）を先に読む。この行が無いと読まれなくなる
   $include /etc/inputrc
   # 補完: 大文字小文字を区別しない、候補が複数なら 1 回の Tab で一覧を出す、種類と打った部分を色で示す
   set completion-ignore-case on
   set show-all-if-ambiguous on
   set colored-stats on
   set colored-completion-prefix on
   # ↑/↓: 打った文字で始まる履歴だけをさかのぼる（何も打っていなければ 1 つずつ）
   "\e[A": history-search-backward
   "\e[B": history-search-forward
   "\eOA": history-search-backward
   "\eOB": history-search-forward
   EOF
     bind -f ~/.inputrc
     printf '\n\033[7m 確認 \033[0m\n'
     # 補完の設定を確かめる
     bind -v | grep -E 'completion-ignore-case|show-all-if-ambiguous|colored-stats|colored-completion-prefix'
     # キーの割り当てを確かめる
     bind -q history-search-backward
     bind -q beginning-of-line
   fi
   ```

   - `set … on` が 4 行出る。`history-search-backward` は `\eOA`・`\e[5~`・`\e[A`、`beginning-of-line` は `\C-a`・`\eOH`・`\e[1~`・`\e[H` の割り当てが出る
   - `beginning-of-line` に `"\e[1~"` が無ければ、`$include /etc/inputrc` の行が読まれていない
   - `中断:` が出たら、既存の `~/.inputrc` の先頭に `$include /etc/inputrc` が無ければ足し、`set` と矢印の各 4 行を足して `bind -f ~/.inputrc` を貼る

#### 共通の bash 設定を root に入れる

root のシェルにも、共通の bash 設定を入れる。一般ユーザーを信用できる自分専用のホストだけで行う。root が一般ユーザーの書き換えられる Homebrew のコマンド・補完を実行し、Homebrew が PATH の先頭になる。

- 前提: [共通の bash 設定](#共通の-bash-設定)を通してある（一般ユーザーの共通 bash 設定を先に入れる）
- 実行場所: この項の手順 1 は自分のユーザーの端末（bash）。手順 2 からは、その端末から `sudo -i` で入った root のシェル（手順 3 で入り直す）
- `sudo -i` は `ALL_PROXY` を渡さない

1. 自分のユーザーのシェルから root に入る。

   ```bash
   sudo -i
   ```

   - **次の手順は、root のシェルで貼る**（続けて貼ると、root のシェルの中ではなく、root のシェルを閉じた後の元のシェルで動く）

1. root 自身の clone を作り、読み込み口を設定する。

   ```bash
   # root 用の共通 bash 設定を導入する
   git clone https://github.com/ryo-aoki-pc/bash.git ~/.config/bash &&
     bash ~/.config/bash/install.sh
   ```

   - 控えが既にある状態で変更が必要なら中断する
   - 独自設定は共通設定の読み込み行より後ろに置く。構文エラーなら変更せず中断する
   - `~` は `/root`。clone 済みなら更新し、`bash ~/.config/bash/install.sh` を実行する
   - 控えは `/root/.bashrc.before-bash`

1. `exit` で抜け、自分のユーザーから `sudo -i` で入り直す。

   - **次の手順は、入り直した root のシェルで貼る**（確認は、設定を読み込んだ新しい root のシェルで行う）

1. 読み込みと非対話時の無出力を確かめる。

   ```bash
   # 共通設定の読み込みと接続先を確かめる
   echo "${__bash_config_loaded-読まれていない}"
   echo "DOCKER_HOST=${DOCKER_HOST-}"
   # 非対話のシェルで出力がないか確かめる
   bash -c '. ~/.bashrc' 2>&1 | wc -c
   ```

   - 最初が `1`、最後が `0` ならよい
   - システムの `podman.socket` があれば `DOCKER_HOST=unix:///run/podman/podman.sock`、無ければ空
   - 確認後は `exit` で抜ける

#### 共通の bash 設定を更新する

共通の bash 設定のリポジトリを pull で上げる。更新後は端末を開き直す。

- 前提: [共通の bash 設定](#共通の-bash-設定)を通してある
- 実行場所: 自分のユーザーの端末（bash。Windows 11 は Git Bash）。この項の手順 2 は、`sudo -i` で入った root のシェル

1. origin を HTTPS にそろえて、設定のリポジトリを pull する。

   ```bash
   # 共通設定の取得元を HTTPS にする
   git -C ~/.config/bash remote set-url origin https://github.com/ryo-aoki-pc/bash.git
   # 共通設定を更新してコミットを確かめる
   git -C ~/.config/bash pull --ff-only
   git -C ~/.config/bash log -1 --oneline
   ```

   - 新しいコミットが無ければ `Already up to date.` と出て、最後にいちばん新しいコミットが 1 行出る
   - インターネットに出られないホストは、[SSH の SOCKS トンネル](almalinux-setup.md#ssh-の-socks-トンネル)を張ったシェルで貼る
   - 手元で変えたファイルがあって pull が止まったら、`git -C ~/.config/bash status` で見る
   - 開いている端末には効かない。端末を開き直す

1. root のシェルにも入れたときだけ、`sudo -i` の root のシェルで、この項の手順 1 を貼る。

   - `/root/.config/bash` が新しくなる。出力は、この項の手順 1 と同じ
   - 開いている root のシェルには効かない。`exit` で抜けて入り直す

<details id="共通の-bash-設定-の補足と注意点">
  <summary>共通の bash 設定 の補足と注意点</summary>

**注意点**

- **`~/.inputrc` を作ったら `$include /etc/inputrc` を忘れない**: 無いと Home / End / Delete / Ctrl+矢印が効かなくなる

- **`globstar` は `rm` でも効く**: `rm **` はサブディレクトリの中まで消す。`**` を打つ前に `echo **` で見る

- **`autocd` は、ディレクトリと同じ名前のコマンドが無いときだけ**: コマンドの探索が先で、見つからなかったときにディレクトリとして試す

- **`show-all-if-ambiguous` は候補が多いと長い一覧になる**: `ls /usr/share/<Tab>` のような場所では、既定と同じく `Display all 123 possibilities? (y or n)` と聞かれる

**[共通の bash 設定](#共通の-bash-設定)の手順 1**

- `~/.bashrc: 設定済み（元の内容: ~/.bashrc.before-bash）` と `完了: 端末を開き直す。…` が出ればよい

**[共通の bash 設定](#共通の-bash-設定)の手順 1: 共通の bash 設定**

- [README の共通の bash 設定を先に入れる](../README.md#共通の-bash-設定を先に入れる)と同じ（Workstation には git が最初から入っている）
- 元の `~/.bashrc` は `~/.bashrc.before-bash` に残る
- `~/.bashrc` の末尾に、`~/.config/bash/bashrc` を読む 1 行が足される。ツールごとの設定（Homebrew・starship・zoxide・fzf・eza・bat の `MANPAGER`・履歴と `shopt` など）は、この設定がまとめて読む。この文書では `~/.bashrc` に追記しない

**[共通の bash 設定](#共通の-bash-設定)の手順 3**

- `bash-completion-2.11-…` と出れば入っている

**[共通の bash 設定](#共通の-bash-設定)の手順 3: 入っているときと入れたとき**

- Workstation で入れた PC は、bash-completion が最初から入っている
- BaseOS から入れるときは、依存の `pkgconf` 系 4 つも入る

**[共通の bash 設定を更新する](#共通の-bash-設定を更新する)の手順 1**

- `set-url` は、HTTPS で clone したホストでは何も変えない。SSH で clone したホストを HTTPS にそろえる

**選択した方針**

- **bash-completion はシステムの RPM にした**: BaseOS の 2.11 で足りる。Homebrew にも `bash-completion@2`（2.16 系）があるが、RPM の各パッケージが置く `/usr/share/bash-completion/completions/` を読むのはシステムのものの方が素直で、`sudo` のシェルでも同じものが効く
- **Homebrew の補完は bash リポジトリから全部読む**: 遅延読み込みの対象のディレクトリに無いため（[シェルのツール](#シェルのツール)の手順 3 の補足）。`~/.local/share/bash-completion/completions/` にシンボリックリンクを置けば遅延読み込みにできるが、入れるたびに足す手間があるので採らない
- **`~/.inputrc` を使い、`~/.bashrc` の `bind` にはしない**
- **採らなかった設定**
  - `HISTTIMEFORMAT`（`history` に時刻を出す）: 履歴ファイルに `#<epoch>` の行が増える。本書は履歴の見え方を変えない範囲にとどめる
  - `HISTCONTROL=…:erasedups`（同じ行を全部消して 1 つにする）: 覚えている一覧の中だけを直し、ファイルの古い重複は残る。効き目が分かりにくいので入れない
  - `PROMPT_COMMAND` に `history -a`（コマンドごとにファイルへ書き、別の端末ですぐ使う）: AlmaLinux 10 の `PROMPT_COMMAND` は配列で、starship・WezTerm のシェル統合・zoxide が順番に意味を持って触っている（[シェルのツール](#シェルのツール)の手順 4 の補足）。そこへ足す形は本書では扱わない
  - `set bell-style none`（ベルを消す）、`menu-complete`（Tab で候補を順に入れる）: 好みの幅が大きいので入れない
  - `shopt -s histappend`: `/etc/bashrc` が対話のシェルで入れている（[共通の bash 設定](#共通の-bash-設定)の手順 2）
- **atuin（履歴を SQLite に持ち、同期もする）は使わない**: 履歴の検索は [fzf の使い方の基本](#fzf-の使い方の基本) の Ctrl+R で足りる。[導入元一覧](tool-catalog.md#cli-定番の置き換え)の行のまま

- 検証記録（`docs/verification/almalinux-setup.md`）

**参照**

- [README の共通の bash 設定を先に入れる](../README.md#共通の-bash-設定を先に入れる) と [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash) — [共通の bash 設定](#共通の-bash-設定)の手順 1〜4

- [Bash Reference Manual — Bash Variables](https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html)（`HISTSIZE`・`HISTFILESIZE`・`HISTCONTROL`・`HISTTIMEFORMAT`）
- [Bash Reference Manual — The Shopt Builtin](https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html)（`autocd`・`cdspell`・`dirspell`・`globstar`・`histappend`）
- [Bash Reference Manual — Readline Init File](https://www.gnu.org/software/bash/manual/html_node/Readline-Init-File.html)（`$include`、`completion-ignore-case`、`show-all-if-ambiguous`、`colored-stats`、`colored-completion-prefix`、`history-search-backward`）
- [bash-completion](https://github.com/scop/bash-completion)（`_completion_loader`、`BASH_COMPLETION_USER_DIR`、`XDG_DATA_DIRS`）
- [Homebrew — Shell Completion](https://docs.brew.sh/Shell-Completion)（`etc/bash_completion.d` を読む形）
- [fzf の使い方の基本](#fzf-の使い方の基本) — Ctrl+R の履歴の検索と `**<Tab>`。Homebrew の補完の行との並び
- [Homebrew](almalinux-setup.md#homebrew) — `brew shellenv` の行（[共通の bash 設定](#共通の-bash-設定)の手順 2）

- 検証記録（`docs/verification/shell-terminal.md`）

</details>

---

### シェルのツール

- starship・zoxide・fzf・eza・bat・tmux を Homebrew で入れ、共通の bash 設定が読み込んだことを確かめる
- 前提: [共通の bash 設定](#共通の-bash-設定)と[Homebrew](almalinux-setup.md#homebrew)の手順 1〜2 を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）。この項の手順 2 で端末を開き直し、手順 3 からは開き直した端末で貼る

1. brew で starship・zoxide・fzf・eza・bat・tmux を入れる。

   ```bash
   brew install starship zoxide fzf eza bat tmux
   ```

   - 入れるものの一覧の後に `Do you want to proceed with the installation? [y/n]` と聞かれる。`y`（Enter は要らない）
   - `Warning: Landlock ABI 10 or later is required … found ABI 6.` は正常
   - 要らないツールは、名前を外してから貼る

1. 開いている端末を閉じて、開き直す。

   - Ctrl+Alt+T（[GNOME の表示と入力](almalinux-setup.md#gnome-の表示と入力)の手順 13）でも開ける
   - 開き直した端末から、プロンプトが starship に変わり、zoxide・fzf・eza のエイリアス・bat の `MANPAGER` も効く
   - 今の端末で `. ~/.bashrc` を読み直さず、端末を開き直す
   - **次の手順は、開き直した端末で貼る**（この項の手順 3 以降は、ツールの設定を読んだ新しい端末で行う）

1. bash の履歴・補完・キー操作の設定が効いていることを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 履歴とシェルの設定を確かめる
   printf '%s\n' "${HISTSIZE}" "${HISTFILESIZE}" "${HISTCONTROL}"
   shopt histappend autocd cdspell dirspell globstar
   # 補完の登録を確かめる
   complete -p -D
   complete -p brew
   # 入力と履歴検索の設定を確かめる
   bind -v | grep -E 'completion-ignore-case|show-all-if-ambiguous|colored-stats|colored-completion-prefix'
   bind -q history-search-backward
   ```

   - `100000`・`100000`・`ignoreboth`、5 つの `on` が出る
   - `complete -F _completion_loader -D`（Workstation では `complete -F _python_argcomplete_global -D` のこともある）と、`-F _brew brew` を含む行が出る
   - `set … on` が 4 行と、`history-search-backward` の `\eOA`・`\e[5~`・`\e[A` の割り当てが出る

1. starship が入り、プロンプトの文字列が作られるか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # プロンプトの読み込み設定を確かめる
   grep -n -e 'starship init' -e 'WEZTERM_SHELL_INTEGRATION' -e 'zoxide init' ~/.config/bash/bashrc
   # starship の版と実行ファイルを確かめる
   starship --version
   command -v starship
   # プロンプトの表示を確かめる
   starship module directory
   starship explain
   ```

   - starship → WezTerm → zoxide の順に出ればよい
   - starship の版と Homebrew のパスが出ればよい

1. fzf が入り、キー操作と補完が組み込まれたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # fzf の版と実行ファイルを確かめる
   fzf --version
   command -v fzf
   # fzf のキー操作と補完を確かめる
   bind -X
   bind -s | grep -F '"\ec"'
   complete -p cd vi ssh
   ```

   - fzf の版と Homebrew のパスが出ればよい
   - Ctrl+R・Ctrl+T の割り当て（`"\C-r": "__fzf_history__"`・`"\C-t": "fzf-file-widget"`）と、Alt+C のマクロ（`` "\ec": " \C-b\C-k \C-u`__fzf_cd__`… ``）が出る
   - `cd`・`vi`・`ssh` の補完の定義（`_fzf_dir_completion`・`_fzf_path_completion`・`_fzf_complete_ssh`）が出る

1. eza の版と Git の列、`ll`・`la`・`lt` を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # eza の版と実行ファイルを確かめる
   eza --version
   command -v eza
   # Git の列と別名の設定を確かめる
   eza -l --git --header ~/.config/bash
   alias ll la lt
   ```

   - 一覧に `Git` の列が出ればよい
   - `ll` は `eza -l --git --group-directories-first`、`la` は `-la`、`lt` は `eza --tree --level=2`
   - `eza --version` は `v0.23.5 [+git]` のような行を含む

1. bat の版と、色と行番号、man のページャを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # bat の版と実行ファイルを確かめる
   bat --version
   command -v bat
   # 色と行番号の表示を確かめる
   bat --color=always --style=numbers /etc/os-release | head -5
   # man のページャの設定を確かめる
   printf '%s\n' "$MANPAGER"
   ```

   - bat の版と Homebrew のパスが出ればよい
   - 行番号付きで、色付きの内容が出ればよい
   - 最後に `bat -plman` が出ればよい

1. tmux が入ったことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   tmux -V
   command -v tmux
   rpm -q tmux
   ```

   - tmux の版と Homebrew のパスが出ればよい
   - 最後の行は `パッケージ tmux はインストールされていません`（英語の環境では `package tmux is not installed`）でよい
   - **BaseOS の tmux（`tmux-3.3a-…`）が出て、そちらで始めたセッションが動いているなら**、そのセッションには `/usr/bin/tmux attach` で入る

1. zoxide の `z` と `zi` を確かめ、記録を試すディレクトリへ移る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   type -t z zi
   zoxide --version
   command -v zoxide
   # 移動先を履歴に記録する
   cd /usr/share
   ```

   - `function` が 2 行と、zoxide の版・Homebrew のパスが出ればよい
   - **注意**: 対話のシェル（端末に貼る）で行う。スクリプトの中では記録されない
   - **次の手順は、プロンプトが戻ってから貼る**。戻る前は `/usr/share` が zoxide に記録されない

1. zoxide のデータベースに記録されたか確かめ、ホームに戻る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   zoxide query --list
   # ホームディレクトリに移動する
   cd ~
   ```

   - `/usr/share` が出れば動いている

#### キー操作を試す

- 共通の bash 設定とシェルのツールのキー操作（補完・履歴の検索・fzf のキー）を、端末で押して試す
- 前提: [シェルのツール](#シェルのツール)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。[シェルのツール](#シェルのツール)でツールを入れた後に開いた端末）

1. キーを押して、補完と履歴の検索を確かめる。

   - `systemctl star` と打って Tab: `systemctl start ` になる（bash-completion）
   - `ls /usr/s` → Tab: 色付きの `sbin/ share/ src/` が 1 回で出る
   - `cd /usr/SH` と打って Tab: `cd /usr/share/` になる（`completion-ignore-case`）
   - `printf` と打って ↑: `printf` で始まる履歴の行が、新しい順に出る（`history-search-backward`。カーソルは `printf` の後ろに残る）。Ctrl+C で捨てる
     - [シェルのツール](#シェルのツール)の手順 7 を貼った端末なら、1 回目は「確認」の見出しの `printf '\n\033[7m 確認 \033[0m\n'`、もう 1 回 ↑ で、その手順の `printf '%s\n' "$MANPAGER"`
   - `/usr/share` と打って Enter: `cd -- /usr/share` と出て移る（`autocd`）。`cd /usr/shaer` と打って Enter: `/usr/share` と出て移る（`cdspell`）。`cd` で戻る
   - `ls /usr/share/doc/bash-completion/**/*.md` と打って Enter: `CONTRIBUTING.md` と `README.md` が出る（`globstar`。効いていないと、`そのようなファイルやディレクトリはありません` になる）
   - `eza --gi` と打って Tab: `--git  --git-ignore  --git-repos  --git-repos-no-status` の一覧が出て、`eza --git` まで入る（Homebrew のコマンドの補完）

1. Ctrl+R を押し、履歴から[シェルのツール](#シェルのツール)の手順 5 の `fzf --version` を選んで実行する。

   - 画面の下から fzf の一覧が開き、最下行の `>` の右に打った文字で絞り込める。`fzf --v` と打ち、上下キーで `fzf --version` の行を選ぶ
   - Enter でその行がプロンプトに入る（**実行はされない**）。もう一度 Enter で実行する
   - Esc か Ctrl+C で、何も選ばずに閉じる
   - 履歴に `fzf --version` が無ければ、Esc で閉じ、`fzf --version` を打って Enter で実行してから、この手順をやり直す

1. `cat ` と打ってから Ctrl+T を押し、ファイルを選ぶ。

   - ホームのファイル一覧で `.bashrc` と打つと先頭になり、Enter でカーソル位置に入る。`bashrc` だけでは `.config/bash/bashrc` が先頭になる
   - 右側に、選んでいるファイルの中身が bat の行番号と色付きで出る
   - そのまま Enter で `cat .bashrc` が動く

1. `ls /usr/share/**` と打って Tab を押し、候補から選ぶ。

   - `**` → Tab: `/usr/share/` のパス一覧が開く。`doc/bash` → Enter: `ls /usr/share/doc/bash/` が入る。再度 Enter で実行する

1. Alt+C を押してディレクトリを選んで移り、`cd -` で戻る。

   - 今のディレクトリの下のディレクトリの一覧が開く。選んで Enter で、`builtin cd -- <ディレクトリ>` と表示して移る
   - 端末が Alt を ESC の前置きとして送る設定のときに届く（届かなければ、`ESC` を押してから `c`）
   - `cd -` で元のディレクトリに戻る

#### starship のプリセットを当てる

- 公式が配っている設定一式を `~/.config/starship.toml` に書き出す
- 前提: [シェルのツール](#シェルのツール)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。[シェルのツール](#シェルのツール)でツールを入れた後に開いた、starship を読み込んだ端末）
- **この項の手順 2 で、既存の設定は上書きされる**。自分で書いたものがあれば、先に退避する

1. 当てられるプリセットの一覧を見る。

   ```bash
   starship preset --list
   ```

   - `plain-text-symbols` と `no-nerd-font` は**Nerd Font が無い端末向け**で、記号を ASCII に置き換える
   - `nerd-font-symbols` / `pastel-powerline` / `gruvbox-rainbow` などは Nerd Font が要る（[HackGen Console NF](#hackgen-console-nf) など）
   - **次の手順は、使うプリセットを決めてから貼る**

1. 選んだプリセットを `~/.config/starship.toml` に書き出す（`STARSHIP_PRESET` は、この項の手順 1 で選んだ名前にする）。

   ```bash
   STARSHIP_PRESET=plain-text-symbols   # 当てるプリセット（この項の手順 1 の一覧から）。<STARSHIP_PRESET>
   ```

   ```bash
   # プリセットを設定ファイルに書き出す
   if [ -z "${STARSHIP_PRESET}" ]; then echo '中断: STARSHIP_PRESET が空のまま。値を入れて貼り直す' >&2; else
     mkdir -p ~/.config
     starship preset "${STARSHIP_PRESET}" -o ~/.config/starship.toml --force &&
       wc -l ~/.config/starship.toml &&
       starship prompt
   fi
   ```

#### starship の設定ファイル

- starship の設定ファイル `~/.config/starship.toml` を、手で書く
- 前提: [シェルのツール](#シェルのツール)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。[シェルのツール](#シェルのツール)でツールを入れた後に開いた、starship を読み込んだ端末）

> [!WARNING]
> この項の手順 1 は、`~/.config/starship.toml` が既にあれば、まるごと置き換える（[starship のプリセットを当てる](#starship-のプリセットを当てる)の設定も消える）。残すなら、先に別の名前で控える

1. `~/.config/starship.toml` に、設定を手で書く。

   ```bash
   # starship の設定ファイルを作成する
   mkdir -p ~/.config
   cat > ~/.config/starship.toml <<'EOF'
   add_newline = false

   [directory]
   truncation_length = 3
   truncate_to_repo = false
   EOF
   # 設定したプロンプトを表示する
   starship prompt
   ```

#### starship でユーザー名とホスト名を常に表示する

- ユーザーを切り替えても名前を出す（starship の既定は、SSH のときと、ログインしたユーザーと違うときだけ出す）
- 前提: [シェルのツール](#シェルのツール)を通してある。[starship のプリセットを当てる](#starship-のプリセットを当てる)や[starship の設定ファイル](#starship-の設定ファイル)の例を使う場合は、それを先に通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。[シェルのツール](#シェルのツール)でツールを入れた後に開いた、starship を読み込んだ端末）。root の設定は別のファイルになる

1. ユーザー名とホスト名を常に表示する設定を入れる。

   ```bash
   # ユーザー名とホスト名の表示を設定する
   mkdir -p ~/.config
   starship config username.show_always true
   starship config hostname.ssh_only false
   printf '\n\033[7m 確認 \033[0m\n'
   starship module username
   starship module hostname
   ```

   - ユーザー名とホスト名が出ることを確かめる
   - 設定後にプリセットや設定ファイルを上書きした場合は、この項の手順をもう一度実行する

#### fzf の使い方の基本

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

#### fzf で fd と bat を候補とプレビューに使う

- Ctrl+T と Alt+C の候補を、fd の一覧に変える（`.git` の中を除き、隠しファイルは含める。`.gitignore` の対象は fd が既定で除く）
- 前提: [シェルのツール](#シェルのツール)を通してある（bat は、その項の手順 1 で入る）
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）。この項の手順 2 で端末を開き直し、手順 3 からは開き直した端末で貼る
- `**<Tab>` の候補は変わらない（`find` のまま）
- fd は[Neovim](neovim.md#neovim)の手順 2（自分用の Neovim の設定の導入）と[yazi](almalinux-setup.md#yazi)の手順 2 でも入る。fd が入っていれば、この項の手順 1・2 は飛ばす

1. brew で fd を入れる。

   ```bash
   brew install fd
   ```

   - 確認が出たら `y`（Enter は要らない）
   - EPEL の `fd-find` と二重に入れない

1. 開いている端末を閉じて、開き直す。

   - **次の手順は、開き直した端末で貼る**（続きは、fd を検出して設定を読んだ新しい端末で行う）

1. fd と bat があり、変数が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 候補とプレビューのコマンドを確かめる
   command -v fd bat
   # fzf の候補とプレビューの設定を確かめる
   printf '%s\n' "${FZF_DEFAULT_COMMAND-}" "${FZF_CTRL_T_COMMAND-}" "${FZF_ALT_C_COMMAND-}" "${FZF_CTRL_T_OPTS-}"
   ```

   - 2 つのパスと、`fd` を使う候補の 3 変数・`bat` を使うプレビューの変数が出ればよい

1. `cat ` と打ってから Ctrl+T を押し、候補が fd の一覧になったことを確かめる。

   - `.git` の中のファイルと、`.gitignore` に書かれたファイルは一覧に出ない
   - 一覧の右側に、選んでいるファイルの中身が行番号と色付きで出る。Esc で閉じる

#### eza の表示を調整する

設定ファイルは無く、すべてコマンドラインオプションと環境変数で決める。よく使うもの:

| やりたいこと | オプション |
|---|---|
| 列の見出しを出す | `--header`（`-h`） |
| 時刻の書式を変える | `--time-style=long-iso` / `iso` / `relative` / `+%Y-%m-%d` |
| 8 進数のパーミッション | `--octal-permissions`（`-o`） |
| アイコンを出す | `--icons=always`（**Nerd Font が要る**） |
| ディレクトリを先に並べる | `--group-directories-first` |
| `.gitignore` のファイルを隠す | `--git-ignore` |
| git 連携を切る | `--no-git` |

#### bat の設定ファイル

- bat の設定ファイルを置き、テーマ・表示の飾り・ページャを決める
- 前提: [シェルのツール](#シェルのツール)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）

1. よく変える 3 つだけを書いた、最小の設定ファイルを置く。

   ```bash
   BAT_THEME_NAME=ansi   # 使うテーマ。ansi は端末の 16 色にそのまま従う（一覧は bat --list-themes）。<BAT_THEME_NAME>
   ```

   ```bash
   # bat の設定ファイルを作成する
   if [ -z "${BAT_THEME_NAME}" ]; then echo '中断: BAT_THEME_NAME が空のまま。値を入れて貼り直す' >&2; else
     mkdir -p ~/.config/bat
     cat > ~/.config/bat/config <<EOF
   --theme="${BAT_THEME_NAME}"
   --style="numbers,changes,header"
   --paging=never
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     # 書き込んだ設定を確かめる
     cat ~/.config/bat/config
     # bat が読む設定ファイルを確かめる
     bat --config-file
   fi
   ```

   - 書いた設定と `~/.config/bat/config` のパスが出ればよい
   - `中断:` と出たら、何も書いていない

#### tmux を試す

- tmux のセッションを作り、抜けて（デタッチ）、入り直して（アタッチ）、終わらせる
- 前提: [シェルのツール](#シェルのツール)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）

1. tmux のセッションを作って入り直し、終了を確認する。

   ```bash
   # 作業用の tmux セッションを作成する
   tmux new-session -s work
   printf '\n\033[7m 確認 \033[0m\n'
   # 切り離したセッションを確かめる
   tmux ls
   # セッションに入り直して終了を確かめる
   tmux attach -t work
   tmux ls
   ```

   - 画面の下に緑の帯（ステータス行）が出て、左端に `[work]` が出る
   - **`Ctrl+b` を押して離してから `d`** で抜ける（デタッチ）。シェルに戻って `[detached (from session work)]` と出る
   - `tmux attach -t work` で、この項の手順 1 の画面に戻る
   - 中で `exit` と打つと、シェルが終わってセッションも終わる。`[exited]` と出てシェルに戻る
   - 終了後の `no server running on …` は正常

#### tmux の使い方の基本

- tmux のキーは、**`Ctrl+b`（プレフィックス）を押して離してから**次のキーを押す
- 全部のキーは `Ctrl+b` → `?` で出る（`q` で閉じる）。`man tmux` も Homebrew の tmux のものが読める

| キー（`Ctrl+b` の後） | すること |
|---|---|
| `d` | デタッチ（セッションを残して抜ける） |
| `c` | 新しいウィンドウを作る |
| `n` / `p` | 次 / 前のウィンドウへ |
| `0`〜`9` | その番号のウィンドウへ |
| `w` | セッションとウィンドウの一覧から選ぶ（`q` で閉じる） |
| `s` | セッションの一覧から選ぶ |
| `%` | ペインを左右に分ける |
| `"` | ペインを上下に分ける |
| `o` / 矢印 | 次のペイン / その向きのペインへ |
| `z` | 今のペインを全画面にする（もう一度で戻る） |
| `x` | 今のペインを閉じる（`kill-pane …? (y/n)` に `y`） |
| `[` | さかのぼって読む（コピーモード。矢印・PageUp・PageDown で動き、`q` で戻る） |
| `$` / `,` | セッション / ウィンドウの名前を変える |
| `:` | tmux のコマンドを打つ |
| `Ctrl+b` | `Ctrl+b` を中のアプリに送る |

| コマンド | すること |
|---|---|
| `tmux new-session -s <名前>` | 名前を付けてセッションを作り、入る |
| `tmux new-session -A -s <名前>` | 同じ名前のセッションがあれば入り、無ければ作って入る |
| `tmux new-session -d -s <名前> <コマンド>` | 入らずに、コマンドを動かすセッションを作る（コマンドが終わるとセッションも終わる） |
| `tmux ls` | セッションの一覧（どこかで入っているものには `(attached)`） |
| `tmux attach -t <名前>` | セッションに入る |
| `tmux attach -d -t <名前>` | ほかの端末から入っていれば、そちらを外してから入る |
| `tmux kill-session -t <名前>` | セッションを終わらせる（中のコマンドも止まる） |
| `tmux kill-server` | すべてのセッションを終わらせる |

#### tmux の設定ファイル

- マウスのホイールでさかのぼれるようにし、さかのぼれる行数を 2000 から 50000 に増やす。出力が長く続くものを、tmux の中で読み返すときに効く
- 前提: [シェルのツール](#シェルのツール)を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）
- tmux は、サーバーが起動するときに `~/.tmux.conf` と `~/.config/tmux/tmux.conf` の**両方**を読む（あるものだけ）。新規作成は後者、既存設定がある場合はそのファイルに書く
- マウスを on にすると、マウスでの文字の選択は tmux が受け取る。端末の選択を使うときは、端末の決まりに従う（WezTerm などは Shift を押しながら）

1. 設定ファイルを書く。

   ```bash
   # tmux の設定ファイルを作成する
   if [ -e ~/.tmux.conf ] || [ -e ~/.config/tmux/tmux.conf ]; then
     echo '中断: tmux の設定ファイルがすでにある。中身を見て、この項の set の 2 行を手で足す' >&2
   else
     mkdir -p ~/.config/tmux
     cat > ~/.config/tmux/tmux.conf <<'EOF'
   # マウス: ホイールでさかのぼる・クリックでペインを選ぶ・境界のドラッグで大きさを変える
   set -g mouse on
   # さかのぼれる行数（既定は 2000）
   set -g history-limit 50000
   EOF
     printf '\n\033[7m 確認 \033[0m\n'
     cat ~/.config/tmux/tmux.conf
   fi
   ```

   - 書いた 4 行が出る
   - `中断:` が出たら、既存ファイルの `mouse`・`history-limit` を編集する。両方あるなら `~/.config/tmux/tmux.conf` に異なる値が無いことも確かめる

1. 動いている tmux にも読ませて、効いたか確かめる。

   ```bash
   # 確認用のセッションで設定を読み込む
   if TMUX_CHECK_ID=$(tmux new-session -d -P -F '#{session_id}' -s "conf-check-$$"); then
     for conf in ~/.tmux.conf ~/.config/tmux/tmux.conf; do
       if [ -f "${conf}" ]; then tmux source-file "${conf}"; fi
     done
     printf '\n\033[7m 確認 \033[0m\n'
     tmux show -g mouse
     tmux show -g history-limit
     # 確認用のセッションを終了する
     tmux kill-session -t "${TMUX_CHECK_ID}"
   else
     echo '中断: 確認用のセッションを作れなかった。既存セッションは終了しない' >&2
   fi
   ```

   - `mouse on` と `history-limit 50000` が出る

<details id="シェルのツール-の補足と注意点">
  <summary>シェルのツール の補足と注意点</summary>

**注意点**

- **starship・zoxide・fzf の初期化は、共通の bash 設定が読む**: `brew install` だけではプロンプトも `z` も変わらない。共通設定が starship → WezTerm → zoxide、Homebrew の補完 → fzf の順に読む。端末を開き直すと効く
  - WezTerm のシェル統合の `A` / `B` は失われる: `PS1` が毎回作り直されるため。並びによらない（[bash の参考資料の読む順番](https://github.com/ryo-aoki-pc/bash/blob/main/docs/reference/readme.md#読む順番)）
  - root は別に導入する: root 自身にも bash の共通設定を導入した場合にだけ、root のシェルで初期化される（[Homebrew を root のシェルでも使う](almalinux-setup.md#homebrew-を-root-のシェルでも使う)）

- **starship はプロンプトごとに外部プロセスが起動する**: git の状態を調べるので、大きなリポジトリや遅いストレージ（Raspberry Pi の microSD）では体感できるほど遅くなることがある。`starship timings` で犯人を探し、要らないモジュールは `disabled = true` で切る

- **starship の記号には Nerd Font が要るものがある**: 既定のプロンプト記号 `❯` は普通のフォントでも出るが、プリセットによっては Nerd Font 前提。無い端末では `plain-text-symbols` / `no-nerd-font` を当てる

- **zoxide の `--cmd cd` は影響範囲が広い**: `cd` を置き換えると、シェル関数やエイリアス経由の `cd` の挙動も変わる。既定の `z` から始めるのが無難

- **zoxide の学習はプロンプトを出すたびに走る**: `PROMPT_COMMAND` にフックが入り、そのときの今のディレクトリを記録する。yazi の `z` キーと、zoxide の対話関数 `zi`（fzf で候補を選ぶ）はこのデータベースを共有する

- **fzf を入れると、readline の Ctrl+R と Ctrl+T は使えなくなる**: `reverse-search-history` と `transpose-chars`。Ctrl+S（前方の検索）は残る
  - Ctrl+R は実行しない: 選んだ行がプロンプトに入るだけ。確かめてから Enter
  - Alt+C は端末しだい: Alt を ESC の前置きで送らない端末では届かない。`ESC` を押してから `c` でも同じ
  - `**` の補完は、fzf が知っているコマンドだけ。ほかのコマンドに付けるには `_fzf_setup_completion path <コマンド>`（README）
  - tmux の中でも同じキーで動く: `M-c` は tmux のプレフィックスとぶつからない（`Ctrl+b` が既定）

- **`alias ls=eza`・`alias cat=bat` は勧めない**: `ll` / `la` / `lt` と `bat` を打つ運用を勧める
  - eza は GNU `ls` の全オプションを実装していない（`-G` の意味が違い、`--time-style` に渡せる値も別物）
  - bat は既定でページャ（`less`）を開くので、`cat` のつもりで打つと画面が切り替わる。`-A` / `-v` / `-e` などフラグの意味も GNU `cat` と違う
  - エイリアスは対話シェルにしか効かないのでスクリプトは壊れないが、**壊れないぶん挙動の違いに気づきにくい**

- **エイリアスの確認に `type -t` は使えない**: bash は非対話シェルでエイリアスを展開しないため、`type -t ll` はエイリアスを見つけられない（`alias ll` なら確認できる）

- **eza のアイコンには Nerd Font が要る**: `--icons=always` はグリフを出すだけなので、フォントが無い端末では豆腐になる（[HackGen Console NF](#hackgen-console-nf)）

- **eza の `--git` は大きなリポジトリで遅くなる**: 毎回 git の状態を引くため。気になるなら `--no-git`、リポジトリの一覧だけなら `--git-repos-no-status`

- **bat を EPEL 版と二重に入れない**: どちらも `bat` という名前で、PATH の先頭にある Homebrew 版が勝つ

- **bat のテーマの見え方は端末に依存する**: `ansi` 以外を選ぶと端末の配色とぶつかることがある。true color が出るかは端末側の設定次第

- **BaseOS の tmux と混ぜない**: 同じソケットを使うので、版の違うクライアントからはセッションにつなげない（検証記録: `docs/verification/shell-terminal.md` の「tmux: 実施手順 / 手順 2: 補足: BaseOS の tmux と並べたとき」）

- **tmux のセッションがログアウトしても残るのは、`KillUserProcesses=no` のとき**: AlmaLinux 10 の既定。`yes` にしたホストでは、ログアウトでセッションも止まるはず

- **PC を再起動すると、tmux のセッションも中のコマンドも消える**: 起動時に始め直す仕組みは、本書では作らない

**[シェルのツール](#シェルのツール)の手順 1**

- `Warning: Landlock ABI 10 or later is required to deny all network access; found ABI 6.` の行は、気にしなくてよい

**[シェルのツール](#シェルのツール)の手順 1: 確認とボトル**

- 依存も入れる計画なので、`[y/n]` と聞かれる
- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
- 要らないツールの名前を外してよいのは、共通の bash 設定が、入っているものだけを読むため

**[シェルのツール](#シェルのツール)の手順 1: starship のボトル**

検証記録: `docs/verification/shell-terminal.md` の「starship: 補足の実測」

**[シェルのツール](#シェルのツール)の手順 1: fzf の依存と、入れてあるホストで貼る意味**

この節の検証記録: `docs/verification/shell-terminal.md` の「fzf: 実施手順 / 手順 1: 補足: 依存と、入れてあるホストで貼る意味」

- fzf の依存は `ncurses` だけ（`brew deps fzf`）
- [yazi](almalinux-setup.md#yazi)や[シェルのツール](#シェルのツール)で入れた fzf は、`brew install zoxide fzf` のように名前を挙げて入れているので、Homebrew の「頼まれて入れた」印（`installed_on_request`）が付いている。`brew install fzf` を貼り直しても害は無く、印が無かったホストでは付く（印が無いと、zoxide や yazi を `brew uninstall` した際の自動削除や、明示的な `brew autoremove` で fzf も消えうる）

**[シェルのツール](#シェルのツール)の手順 1: eza のボトル**

aarch64 で降ってくるボトルは `eza--0.23.5.arm64_linux.bottle.tar.gz`。

**[シェルのツール](#シェルのツール)の手順 2: 開き直した端末で効く理由**

- 開き直した端末で starship・zoxide・fzf・eza・bat が効くのは、共通の bash 設定が、入っているツールを読むため

**[シェルのツール](#シェルのツール)の手順 3: 補完の順**

- `-F _brew brew` が出るのは、共通の bash 設定が Homebrew の補完を fzf より前に読むため

**[シェルのツール](#シェルのツール)の手順 4**

- `starship 1.26.0` のような版と、`/home/linuxbrew/.linuxbrew/bin/starship` が出る

- 最初の行で、starship → WezTerm → zoxide の順に出る

**[シェルのツール](#シェルのツール)の手順 4: 初期化の順と starship explain**

- starship → WezTerm → zoxide の順は、共通の bash 設定が初期化の順番を持つ。`~/.bashrc` の編集は不要
- `starship explain` は、今のプロンプトに出ている各部分の意味を 1 行ずつ説明する
- 見た目を変えるなら[starship のプリセットを当てる](#starship-のプリセットを当てる)、細かい調整は[starship の設定ファイル](#starship-の設定ファイル)

**[シェルのツール](#シェルのツール)の手順 5**

- `0.74.4 (Homebrew)` のような版と `/home/linuxbrew/.linuxbrew/bin/fzf` が出る

**[シェルのツール](#シェルのツール)の手順 6**

- `Permissions Size User Date Modified Git Name` の見出しの一覧が出る

**[シェルのツール](#シェルのツール)の手順 6: 出力の意味**

- `[+git]` は git の連携込みのビルド
- `Git` の列が出るのは、`~/.config/bash` が git のリポジトリだから
- `ll`・`la`・`lt` は共通の bash 設定が足す。`ls` は置き換えない

**[シェルのツール](#シェルのツール)の手順 7**

- `bat 0.26.1` のような版と、`/home/linuxbrew/.linuxbrew/bin/bat` が出る

- 行番号付きで `NAME="AlmaLinux"` から 5 行が色付きで出る

**[シェルのツール](#シェルのツール)の手順 7: bat の出力と MANPAGER**

- `--color=always` を外してパイプに繋ぐと、装飾の無い `cat` と同じ出力になる
- `MANPAGER` の `bat -plman` は共通の bash 設定が持つ。`man bash` が bat の色で開く（`q` で閉じる）

**[シェルのツール](#シェルのツール)の手順 8**

- `tmux 3.7c` のような版と `/home/linuxbrew/.linuxbrew/bin/tmux` が出る

**[シェルのツール](#シェルのツール)の手順 8: BaseOS の tmux**

- BaseOS の tmux で始めたセッションに Homebrew の tmux からはつなげない（検証記録: `docs/verification/shell-terminal.md` の「tmux: 実施手順 / 手順 2: 補足: BaseOS の tmux と並べたとき」）

**[シェルのツール](#シェルのツール)の手順 9**

- `function` が 2 行と、`zoxide 0.10.0` のような版、`/home/linuxbrew/.linuxbrew/bin/zoxide` が出る

**[シェルのツール](#シェルのツール)の手順 10: z と zi の使い方**

- 以後は `z share` のように末尾の一部を書けば `/usr/share` に飛ぶ。`zi` で候補を fzf で選べる

**[キー操作を試す](#キー操作を試す)の手順 3: プレビューと複数の選択**

- 右側のプレビューは、共通の bash 設定が、bat があるときに入れる
- Tab で複数を選べる（選んだ行に印が付き、Enter で全部入る）

**[キー操作を試す](#キー操作を試す)の手順 4: `**` の補完**

- `**` を付けなければ、今までどおりの補完
- `ssh **<Tab>` は `~/.ssh/config` と `known_hosts` のホスト名、`export **<Tab>` は変数名の一覧になる

**[starship のプリセットを当てる](#starship-のプリセットを当てる)の手順 2**

- 設定ファイルの変更だけなら `~/.bashrc` を読み直す必要はない。次のプロンプトから変わる

**[starship のプリセットを当てる](#starship-のプリセットを当てる)の手順 2: --force と再初期化**

- starship は設定ファイルをプロンプトのたびに読む
- `--force` が無いと、既存のファイルがある場合に拒否される
- 共通設定は初期化済みの starship を再初期化しない。手で `eval "$(starship init bash)"` を重ねると `PS0` が重複するため、追加で実行しない

**[starship のプリセットを当てる](#starship-のプリセットを当てる)の手順 2: 変数について**

- `${STARSHIP_PRESET}` は[starship のプリセットを当てる](#starship-のプリセットを当てる)でしか使わない
- 既定を `plain-text-symbols` にしてあるのは、Nerd Font が無い環境でも文字化けしないため

**[starship の設定ファイル](#starship-の設定ファイル)のリード**

- `~/.config/starship.toml` は**既定では存在しない**（無ければ組み込みの既定値で動く）

**[starship の設定ファイル](#starship-の設定ファイル)の手順 1: 編集と置き場所**

- `starship config` で `$EDITOR` が開く
- 設定の場所を変えたいときは、starship 自身が読む環境変数 `STARSHIP_CONFIG` を `~/.bashrc` で `export` する

**[starship の設定ファイル](#starship-の設定ファイル)の手順 1: 調べるときに使うサブコマンド**

| コマンド | 用途 |
|---|---|
| `starship explain` | 今のプロンプトの各部分が何を表しているか |
| `starship timings` | モジュールごとの所要時間。プロンプトが遅いときの犯人探し |
| `starship module <名前>` | 1 モジュールだけ描画して確かめる |
| `starship print-config` | 実効設定を表示 |

**[starship でユーザー名とホスト名を常に表示する](#starship-でユーザー名とホスト名を常に表示する)の手順 1**

- 次のプロンプトから反映される。端末の開き直しや `~/.bashrc` の読み直しは不要

**[starship でユーザー名とホスト名を常に表示する](#starship-でユーザー名とホスト名を常に表示する)の手順 1: starship config**

- 既存の設定を保ち、常時表示に必要な 2 項目だけを更新する。設定ファイルが無ければ作られる

**[fzf の使い方の基本](#fzf-の使い方の基本)のリード**

- 共通の見た目や動き（`--height`・`--layout`・`--border` など）は `FZF_DEFAULT_OPTS` に書く。本書では変えていない

**[fzf で fd と bat を候補とプレビューに使う](#fzf-で-fd-と-bat-を候補とプレビューに使う)のリード**

- 共通の bash 設定が、fd があるときに候補の `FZF_*` の 3 つの変数を入れる。Ctrl+T の右側の bat のプレビュー（`FZF_CTRL_T_OPTS`）は、bat があれば入るので、[シェルのツール](#シェルのツール)の手順 1 の後から出ている。`~/.bashrc` への追記は要らない

**[fzf で fd と bat を候補とプレビューに使う](#fzf-で-fd-と-bat-を候補とプレビューに使う)の手順 1: fd-find と二重に入れない理由**

- EPEL の `fd-find` も Homebrew の fd も `fd` で、PATH の先頭の Homebrew 版が使われる

**[fzf で fd と bat を候補とプレビューに使う](#fzf-で-fd-と-bat-を候補とプレビューに使う)の手順 2: 変数を入れる時期**

- 共通の bash 設定は、端末を開くときに fd と bat を見つけて変数を入れる

**[fzf で fd と bat を候補とプレビューに使う](#fzf-で-fd-と-bat-を候補とプレビューに使う)の手順 4: コマンドの中のプレビュー**

- コマンドの中で同じプレビューを使うなら、`fzf --preview 'bat --color=always --style=numbers {}'`

**[eza の表示を調整する](#eza-の表示を調整する)のリード**

- 色は `LS_COLORS` と `EZA_COLORS` を見る

- 全オプションは `eza --help`（86 行）と `man eza`

**[bat の設定ファイル](#bat-の設定ファイル)のリード**

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く

- 置き場所は `~/.config/bat/config`（`bat --config-file` で確認できる）

- 既定の場所に置く限り bat は自分で見つける。別の場所に置きたいときだけ `BAT_CONFIG_PATH` を `~/.bashrc` に `export` する

**[bat の設定ファイル](#bat-の設定ファイル)の手順 1**

- 書いた 3 行と、`/home/<USER>/.config/bat/config` が出ればよい

**[bat の設定ファイル](#bat-の設定ファイル)の手順 1: テーマと言語とキャッシュ**

- テーマの一覧は `bat --list-themes`、認識する言語の一覧は `bat --list-languages`
- 自前のシンタックス定義やテーマを足したときだけ `bat cache --build` が要る（キャッシュの場所は `bat --cache-dir`）

**[bat の設定ファイル](#bat-の設定ファイル)の手順 1: 変数について**

- `ansi` は「端末が設定している 16 色をそのまま使う」テーマで、端末の配色を変えたときに追従する。固定の配色にしたいなら `bat --list-themes` から選ぶ

**[tmux を試す](#tmux-を試す)の手順 1**

- `tmux ls` の `work: 1 windows (created …)` は、tmux の画面を出た後のシェルに見える

- `no server running on /tmp/tmux-<UID>/default` と出る

**[tmux を試す](#tmux-を試す)の手順 1: デタッチ**

- デタッチしても、セッションの中のシェルと、そこで動かしているコマンドは動き続ける

**[tmux を試す](#tmux-を試す)の手順 1: tmux の使い方**

- キーとコマンドは[tmux の使い方の基本](#tmux-の使い方の基本)

**[tmux を試す](#tmux-を試す)の手順 1: tmux のサーバー**

- セッションが 1 つも無くなると、tmux のサーバーも終わる

**[tmux の設定ファイル](#tmux-の設定ファイル)の手順 1: 読み込む場所と、足さなかった行**

- Homebrew の tmux のシステムの設定ファイルは `/home/linuxbrew/.linuxbrew/etc/tmux.conf`（`man tmux`）。`/etc/tmux.conf` は読まない
- `escape-time`（Esc の後に待つ時間）は、3.7c の既定ですでに 10 ミリ秒なので足さない。Neovim などのために 0〜10 にする例は、古い版の既定の 500 ミリ秒を縮めるためのもの

**[tmux の設定ファイル](#tmux-の設定ファイル)の手順 2: 読み込みとホイール**

- 既存・新規のどちらの設定ファイルも、起動時と同じ順で読み込む。既存セッションのマウス設定にも反映する
- tmux の中でホイールを上へ回すと、さかのぼって読める（右上に `[5/258]` のような位置が出る）。下まで回すか `q` で戻る

**選択した方針**

- **シェルのツールは 1 回の `brew install` で入れる（[シェルのツール](#シェルのツール)の手順 1）**: 依存の確認（`[y/n]`）が 1 回で済む。初期化は共通の bash 設定が持つので、入れた後は端末を開き直すだけ

- **starship**

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `arm64_linux` ボトルを使える | **採用** |
| 公式 install.sh（`sh -c "$(curl -sS https://starship.rs/install.sh)"`） | `/usr/local/bin` にバイナリを 1 つ置く。`sudo` が要り、更新は自分で再実行する | 不採用（Homebrew に揃える） |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-musl` のビルドがある。更新は手作業 | 不採用 |
| `cargo install starship` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

- **eza**

この節の検証記録: `docs/verification/shell-terminal.md` の「eza: 選択した方針」

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `eza 0.23.5` の `arm64_linux` ボトルがある。upstream の最新と一致 | **採用** |
| EPEL / AppStream / CRB | **`eza` も、前身の `exa` も無い**（`dnf list --available eza exa` → `Error: No matching Packages to list`） | 使えない |
| 公式の deb リポジトリ | eza は Debian/Ubuntu 向けの apt リポジトリを配っているが、**RPM 版の配布は無い** | 使えない |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-gnu` / `musl` のビルドがある。展開して PATH に置くだけだが、更新は手作業 | 不採用（Homebrew に揃える） |
| `cargo install eza` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

**参照**

- **starship**

- [starship.rs](https://starship.rs/) — 公式サイト。インストールと各シェルでの `init` の書き方
- [starship — Configuration](https://starship.rs/config/) — `starship.toml` の全モジュールと項目
- [starship — Presets](https://starship.rs/presets/) — プリセット一覧とスクリーンショット、Nerd Font が要るかどうか
- `starship --help` / `starship init bash --print-full-init` — サブコマンドと、シェルに入る初期化の中身
- [Homebrew](almalinux-setup.md#homebrew) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

- **zoxide**

- [ajeetdsouza/zoxide — README](https://github.com/ajeetdsouza/zoxide) — 各 OS のインストール方法、シェルごとの `zoxide init` の書き方、`--cmd` の説明
- [zoxide — Installation](https://github.com/ajeetdsouza/zoxide#installation) — 公式 install.sh と各ディストリビューションの状況
- `zoxide --help` / `zoxide query --help` — `query --list` / `--score`、`remove`
- [Homebrew](almalinux-setup.md#homebrew) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作
- [kray74/cli-tools — Copr](https://copr.fedorainfracloud.org/coprs/kray74/cli-tools/) — chroot（`epel-10-x86_64` と `fedora-44-x86_64`）とビルドの履歴
- [kray74/cli-tools — GitHub](https://github.com/kray74/cli-tools) — COPR の spec（`zoxide/zoxide.spec`）

- **fzf**

- [fzf — README](https://github.com/junegunn/fzf#readme)（Key bindings for command-line、Fuzzy completion for bash、Search syntax、Environment variables）
- [fzf — ADVANCED.md](https://github.com/junegunn/fzf/blob/master/ADVANCED.md)（プレビューの例）
- `man fzf`（`--preview`・`--line-range` は bat 側）
- [Homebrew の fzf の formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/f/fzf.rb)（caveat の `fzf --bash`）
- [共通の bash 設定](#共通の-bash-設定) — bash-completion と Homebrew の補完、`~/.inputrc`。fzf の行との並び
- [シェルのツール](#シェルのツール)の手順 9・10 — `zi` が fzf を使う。[yazi](almalinux-setup.md#yazi) — `z` / `Z` キーが fzf を使う
- [bat の設定ファイル](#bat-の設定ファイル) — プレビューに使う。[Homebrew](almalinux-setup.md#homebrew) — Homebrew 本体の導入と、Homebrew 系に共通の注意

- **eza**

- [eza-community/eza — README](https://github.com/eza-community/eza) — 使い方、各ディストリビューションでの入手方法、`ls` との違い
- [eza.rocks](https://eza.rocks) — 公式サイト。スクリーンショットと機能一覧
- `eza --help` / `man eza` — 全オプション（`--help` は 86 行）
- [Homebrew](almalinux-setup.md#homebrew) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

- **bat**

- [sharkdp/bat — README](https://github.com/sharkdp/bat) — 使い方、テーマ、`MANPAGER` や `fzf` との組み合わせ、他ツールとの連携例
- [bat — Customization](https://github.com/sharkdp/bat#customization) — 設定ファイルの書式、テーマとシンタックスの追加手順
- `bat --help` / `bat --list-themes` / `bat --list-languages` — フラグとテーマ・言語の一覧
- [Homebrew](almalinux-setup.md#homebrew) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

- **tmux**

- [tmux — Getting Started](https://github.com/tmux/tmux/wiki/Getting-Started) — セッション・ウィンドウ・ペインとキーの説明
- `man tmux`（`new-session` の `-A` と `-d`、`attach-session` の `-d`、`history-limit`、`mouse`、設定ファイルを読む場所）
- [Homebrew の tmux の formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/t/tmux.rb)
- [Homebrew](almalinux-setup.md#homebrew) — Homebrew 本体の導入と、Homebrew 系に共通の注意

- 検証記録（`docs/verification/shell-terminal.md`）

</details>

---

### HackGen Console NF

- 日本語と Nerd Fonts のアイコンを含む等幅のフォント HackGen Console NF を、Homebrew の cask で入れる
- 前提: [Homebrew](almalinux-setup.md#homebrew)の手順 1〜2 を通してある
- 実行場所: GNOME にログインした自分のユーザーの端末（bash。PATH に Homebrew が入った端末）

1. 変数を設定する。

   ```bash
   HACKGEN_FAMILY='HackGen Console NF'   # 確認と設定に使うファミリー名。<HACKGEN_FAMILY>
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%-15s = %s\n' HACKGEN_FAMILY "${HACKGEN_FAMILY}"
   ```

   - **編集が必須の変数は無い**。既定のまま進められる
   - 文字幅が半角 3:全角 5 の版を使いたいときだけ、`HackGen35 Console NF` に変える
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. `unzip` が入っているか確かめる。

   ```bash
   command -v unzip || echo 'unzip は未導入'
   ```

   - パスが出れば、この項の手順 3 は飛ばす
   - `unzip は未導入` と出たら、この項の手順 3 で入れる

1. `unzip` が未導入のときだけ、`unzip` を入れる。

   ```bash
   sudo dnf install -y unzip
   ```

1. HackGen を Homebrew の cask で入れる。

   ```bash
   brew install --cask font-hackgen-nerd
   ```

   - `Moving Font` が出れば配置されている
   - `font-hackgen-nerd was successfully installed!` で終わる

1. HackGen が入ったか確かめ、かな・漢字・記号・アイコンが入っているかも見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # フォントの導入と配置を確かめる
   brew list --cask --versions font-hackgen-nerd
   ls ~/.local/share/fonts/
   fc-list : family style file | grep HackGen
   # フォントの選択と収録文字を確かめる
   fc-match "${HACKGEN_FAMILY:?「HackGen Console NF」の手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}"
   for cp in 3042 6f22 e0b0 f09b; do printf 'U+%s: ' "${cp}"; fc-list ":charset=${cp}" family | grep -c -x -F "${HACKGEN_FAMILY:?「HackGen Console NF」の手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}"; done
   ```

   - 4 つの `.ttf` と、2ファミリーの Regular / Bold の 4 行が出ればよい
   - `fc-match` が `HackGenConsoleNF-Regular.ttf: "HackGen Console NF" "Regular"` を返せばよい
   - **ファイル名が HackGen であることを確かめる**
   - 4 行とも `1` なら入っている（`あ` / `漢` / Powerline の三角 / GitHub のアイコン）

<details id="hackgen-console-nf-の補足と注意点">
  <summary>HackGen Console NF の補足と注意点</summary>

**注意点**

- **HackGen Console NF: 自分のユーザーにしか入らない**: 置き場所が `~/.local/share/fonts` なので、別のユーザーや root で動くアプリからは見えない

- **HackGen Console NF: `unzip` が要る**: Homebrew の formula（ボトル）は `unzip` 無しで入るが、zip で配られる cask は展開に `unzip` を使う

- **HackGen Console NF: 等幅だけを一覧に出すアプリ**: fontconfig はこのフォントを `spacing=90`（`dual`）と見なす

**[HackGen Console NF](#hackgen-console-nf)の手順 1**

- **編集が必須の変数は無い**。[HackGen Console NF](#hackgen-console-nf)の手順 5 の確認に使うファミリー名で、既定のまま進められる

**[HackGen Console NF](#hackgen-console-nf)の手順 1: HackGen35 Console NF**

検証記録: `docs/verification/shell-terminal.md` の「HackGen Console NF: 補足の実測」

- 文字幅が半角 3:全角 5 の版 `HackGen35 Console NF` も、同じ手順で一緒に入る（検証記録: `docs/verification/shell-terminal.md` の「HackGen Console NF の記録」）

**[HackGen Console NF](#hackgen-console-nf)の手順 2: unzip が要る理由**

- Homebrew は cask の zip を展開するのに `unzip` を使う

**[HackGen Console NF](#hackgen-console-nf)の手順 4**

- `==> Moving Font ...` が 4 行出る

**[HackGen Console NF](#hackgen-console-nf)の手順 5**

- `font-hackgen-nerd 2.10.0`、4 つの `.ttf`、`HackGen Console NF` と `HackGen35 Console NF` の Regular / Bold の 4 行が出る

**[HackGen Console NF](#hackgen-console-nf)の手順 5: fc-match と文字の確かめ方**

- `fc-match` は、名前が合わないときに別のフォントを黙って返すので、ファイル名が HackGen であることを確かめる
- 最後の `for` で、かな・漢字・Powerline 記号・Nerd Fonts のアイコンが、このフォントに入っていることを確かめる

**選択した方針**

| 経路 | 状況 | 採否 |
|---|---|---|
| **Homebrew の cask `font-hackgen-nerd`** | `brew upgrade` で上がり、`brew uninstall` で消せる。自分のユーザーにだけ入る | **採用**（Homebrew 系の手順書と揃える） |
| GitHub のリリースの zip を手で展開 | `~/.local/share/fonts` に置く。Homebrew が要らないが、**更新は手作業** | 不採用（Homebrew がある環境では cask で足りる） |
| 全ユーザー向け（`/usr/local/share/fonts` に置く） | root で置けば全ユーザーから見えるが、cask は自分のホームに置く。複数ユーザーで使う機会が無いので要らない | 不採用 |

- upstream の README は、Linux 向けの導入手順を書いていない（GitHub のリリースの ttf と、Mac の Homebrew、Windows の Chocolatey を案内している）
- Homebrew の cask は upstream の README では Mac 向けとして紹介されている

**参照**

- [Homebrew Formulae — font-hackgen-nerd](https://formulae.brew.sh/cask/font-hackgen-nerd) — cask の版と中身
- `man fc-list` / `man fc-match` / `man fc-cache` — fontconfig の照会と、キャッシュの作り直し
- [WezTerm](#wezterm) — WezTerm の導入と設定ファイルの置き場所
- [AlmaLinux 10 の初期設定](almalinux-setup.md) — 「Homebrew」の手順 1〜2 が Homebrew 本体の導入手順。`brew` の基本操作は同書の「Homebrew の使い方の基本」

- 検証記録（`docs/verification/shell-terminal.md`）

</details>

---

### WezTerm

- 端末のアプリ WezTerm（nightly）を COPR から入れ、自分用の設定を入れて起動し直す
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)と[共通の bash 設定](#共通の-bash-設定)を通してある。[HackGen Console NF](#hackgen-console-nf)は任意（通してあれば、自分用の設定がそのフォントで描く）
- 実行場所: GNOME にログインした自分のユーザーの、WezTerm の外の端末（bash。Ptyxis など）。この項の手順 3 の中で、起動し直した WezTerm のタブへ移る

1. chroot を明示して WezTerm の COPR を有効化し、repo ファイルを確認する。

   ```bash
   # WezTerm の COPR を登録する
   sudo dnf copr enable wezfurlong/wezterm-nightly "rhel-9-$(uname -m)"
   printf '\n\033[7m 確認 \033[0m\n'
   cat /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly.repo
   ```

   - 有効化してよいか `[y/N]` で聞かれるので答える
   - `baseurl` が `.../wezterm-nightly/rhel-9-$basearch/`、`gpgcheck=1` になっていればよい

1. WezTerm を導入し、版・依存ライブラリ・フォントを確認する。

   ```bash
   # WezTerm を導入する
   sudo dnf install wezterm
   printf '\n\033[7m 確認 \033[0m\n'
   # WezTerm のパッケージと版を確かめる
   rpm -q wezterm wezterm-common wezterm-gui wezterm-mux-server
   dnf -q repoquery --installed --qf '%{name} %{from_repo}\n' 'wezterm*'
   wezterm --version
   # 共有ライブラリの依存を確かめる
   ldd /usr/bin/wezterm-gui /usr/bin/wezterm /usr/bin/wezterm-mux-server | grep -c 'not found'   # 0 なら OK
   # WezTerm が選ぶフォントを確かめる
   wezterm ls-fonts | sed -n '1,5p'
   ```

   - fingerprint は `FD90 9B62 88A8 4250 AD58 020F A698 91C5 CEA2 757D`（`wezfurlong_wezterm-nightly`）
   - トランザクション表の `[y/N]` と鍵の確認に答える
   - アプリ一覧には「WezTerm」が出る

1. 自分用の設定（[ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)）を入れ、起動し直した WezTerm に移る。

   - [WezTerm の設定を導入する](#wezterm-の設定を導入する)の手順をすべて、その項の実行場所のとおりに通す
   - 参照先の手順 5 で WezTerm を起動し、手順 6 を WezTerm のタブに貼って確かめる

#### WezTerm と HackGen Console NF をデスクトップで使う

- GNOME の等幅のフォントを HackGen Console NF にし、Ctrl+Alt+T と Dash のお気に入りの端末を WezTerm にする
- 前提: [GNOME の表示と入力](almalinux-setup.md#gnome-の表示と入力)（Ctrl+Alt+T のショートカットと Dash のお気に入り）、[HackGen Console NF](#hackgen-console-nf)、[WezTerm](#wezterm)を通してある
- 実行場所: GNOME にログインした自分のユーザーの WezTerm のタブ（bash）

1. GNOME の等幅のフォントを HackGen Console NF にする。

   ```bash
   MONO_FONT='HackGen Console NF 11'   # 等幅のフォントの名前と大きさ。<MONO_FONT>
   ```

   ```bash
   # GNOME の等幅フォントを設定する
   if [ -z "${MONO_FONT}" ]; then echo '中断: MONO_FONT が空のまま。値を入れて貼り直す' >&2; else
     /usr/bin/gsettings get org.gnome.desktop.interface monospace-font-name
     /usr/bin/gsettings set org.gnome.desktop.interface monospace-font-name "${MONO_FONT}"
     printf '\n\033[7m 確認 \033[0m\n'
     /usr/bin/gsettings get org.gnome.desktop.interface monospace-font-name
   fi
   ```

   - 2 つ目の `get` が `'HackGen Console NF 11'` になればよい

1. Ctrl+Alt+T と Dash のお気に入りの端末を WezTerm にする。

   ```bash
   # 端末の起動コマンドを WezTerm にする
   kb=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/
   /usr/bin/gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command 'wezterm start'
   printf '\n\033[7m 確認 \033[0m\n'
   /usr/bin/gsettings get "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${kb}" command
   # お気に入りの端末を WezTerm にする
   fav=$(/usr/bin/gsettings get org.gnome.shell favorite-apps)
   /usr/bin/gsettings set org.gnome.shell favorite-apps "${fav//org.gnome.Ptyxis.desktop/org.wezfurlong.wezterm.desktop}"
   /usr/bin/gsettings get org.gnome.shell favorite-apps
   ```

   - `'wezterm start'` と、端末のところが `'org.wezfurlong.wezterm.desktop'` になったお気に入りが出ればよい
   - お気に入りに Ptyxis が無かったときは、お気に入りは変わらない

1. Ctrl+Alt+T と Dash から WezTerm が開き、等幅のフォントが変わったことを確かめる。

   - Ctrl+Alt+T と、Dash の WezTerm のアイコンで、WezTerm の窓が開く
   - Ptyxis（アクティビティの画面で `terminal`）の文字が HackGen Console NF になっている

#### WezTerm の設定ファイル

- パッケージ（Windows 11 ではインストーラ）は設定ファイルを置かない。無ければ組み込みの既定値で動く
- nightly が前提（stable では未知のオプションで設定エラーになる）。本書で入れるのは、AlmaLinux 10 も Windows 11 も nightly
- `~/.wezterm.lua` があると、clone した設定は読まれない

#### WezTerm の設定を導入する

自分用の WezTerm の設定（[ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)）を `~/.config/wezterm` に clone し、WezTerm を起動し直して読ませる。シェル統合は共通 bash 設定が読む。

- 前提: [WezTerm](#wezterm)の手順 1・2（WezTerm nightly）と[共通の bash 設定](#共通の-bash-設定)を通してある。[HackGen Console NF](#hackgen-console-nf)は任意
- 実行場所: GNOME にログインした自分のユーザーの bash（Windows 11 は Git Bash）。この項の手順 1〜4 は WezTerm の外の端末、手順 6 は手順 5 で起動し直した WezTerm のタブ
- この項の手順 2 の退避の前に、WezTerm のウィンドウをすべて閉じる
- 既存の設定の確認（この項の手順 1）と退避（手順 2）を省かない

1. 既存の WezTerm の設定があるか確かめる。

   ```bash
   ls -ld ~/.wezterm.lua ~/.config/wezterm
   ```

   - どちらかが出たら、手順 2 で退避する
   - 2 行とも `No such file or directory` なら、設定は無い。手順 2 は飛ばす
   - `~/.wezterm.lua` が残っていると、この設定は読まれない

1. 既存の設定があるときだけ、名前の後ろに `.bak` を付けて退避する。

   ```bash
   # 設定ファイルの退避先を調べる
   (
     for f in ~/.wezterm.lua ~/.config/wezterm; do
       if [ -e "$f.bak" ] || [ -L "$f.bak" ]; then
         echo "中断: $f.bak が既にある。何も退避していない" >&2
         exit 1
       fi
     done
     # 既存の設定ファイルを退避する
     for f in ~/.wezterm.lua ~/.config/wezterm; do
       if [ -e "$f" ] || [ -L "$f" ]; then mv -v "$f" "$f.bak" || exit 1; fi
     done
     # 退避後の配置を確かめる
     ls -ld ~/.wezterm.lua ~/.config/wezterm
   )
   ```

   - 最後の `ls` が 2 行とも `No such file or directory` ならよい
   - `.bak` が 1 つでもあれば、どちらも動かさず `中断:` で止まる。中身を確かめて片付けてから、この項の手順 2 を貼り直す
   - `中断:` や `mv` のエラーが出たら、手順 3 へ進まない。原因を直して手順 2 を貼り直す

1. この設定を `~/.config/wezterm` に clone する。

   ```bash
   # WezTerm の設定を取得して版を確かめる
   git clone https://github.com/ryo-aoki-pc/wezterm.git ~/.config/wezterm
   git -C ~/.config/wezterm log -1 --oneline
   ```

   - `fatal: destination path '/home/<USER>/.config/wezterm' already exists and is not an empty directory.` と出たら、手順 1 から見直す
   - `Cloning into '/home/<USER>/.config/wezterm'...` の後に、最新のコミットが 1 行出る

1. WezTerm がこの設定を読めるか確かめる。

   ```bash
   wezterm ls-fonts --text 'aあ'
   ```

   - `ERROR  wezterm_gui >` が無ければ設定を読めている。終了コードは誤りがあっても `0` なので使わない
   - `show-keys` は読み込み確認に使わず、`| head` も付けない
   - HackGen Console NF があればそのフォントで描く。無ければフォント警告が出て代替フォントを使う。画面なしでは通知の dbus エラーが出る場合もある
   - Windows でコマンドが無ければ `"/c/Program Files/WezTerm/wezterm.exe" ls-fonts --text 'aあ'` を使う

1. WezTerm のウィンドウをすべて閉じてから、起動し直す。

   - WezTerm を開いていなければ、起動するだけでよい
   - AlmaLinux 10 はアプリ一覧の「WezTerm」から、Windows 11 はスタートメニューの「WezTerm」から起動する
   - シェル統合とウィンドウ装飾は起動し直して反映する
   - **次の手順は、起動し直した WezTerm のタブで貼る**（開いていたタブで貼ると、手順 6 の確かめが外れる）

1. 起動し直した WezTerm のタブで、シェル統合が読まれたか確かめる。

   ```bash
   # WezTerm のシェル統合を確かめる
   echo "$TERM_PROGRAM"
   echo "$WEZTERM_SHELL_INTEGRATION"
   declare -F __wezterm_set_user_var __wezterm_notify_done __wz_mouse_off
   ```

   - 1 行目は `WezTerm`、2 行目は `.config/wezterm/shell/wezterm.sh` で終わるパス
   - 3 つ目は、WezTerm のパッケージの公式のシェル統合があるかどうかで変わる
     - AlmaLinux 10 の公式 Bash 統合: `__wezterm_set_user_var`・`__wezterm_notify_done`・`__wz_mouse_off` の 3 行
     - 公式の統合が無いとき（Windows の Git Bash など）: `__wezterm_notify_done` と `__wz_mouse_off` の 2 行
   - 1 行目が空なら、WezTerm の外で貼っている。2 行目が空なら、手順 5 の前から開いていたタブで貼っている
   - `__wz_mouse_off` が出なければ、`~/.bashrc` の行が読まれていない。共通の bash 設定を見直す

#### WezTerm のシェル統合を SSH 先で使う

手元の WezTerm から ssh でつないだ先でも、WezTerm のシェル統合を使う。手元の WezTerm から `TERM_PROGRAM` を送り、SSH 先の sshd で受け取る。公式 Bash 統合が既に有効なら、変数が未設定でも補完処理が動く。

- 前提: 手元で[WezTerm](#wezterm)を通してある。SSH 先は自分で管理する AlmaLinux 10 で、手元から `ssh <HOST>` でログインできる
- 実行場所: この項の手順 1・4 は手元（WezTerm を使う PC）、手順 2・3・5 は SSH 先の自分のユーザーのシェル（bash）

1. 手元の `~/.ssh/config` で、使う `Host` に `SendEnv TERM_PROGRAM` を足す。

   - エディタで `~/.ssh/config` を開く（Windows は `%USERPROFILE%\.ssh\config`。Git Bash では `~/.ssh/config`）
   - 使う `Host <HOST>` の行の下に、字下げして `SendEnv TERM_PROGRAM` の行を足す
   - WezTerm から ssh したときだけ、`WezTerm` が送られる。公式統合が無い場合、この値が `WezTerm` のときだけ独自統合が動く

1. ssh 先で、sshd が `TERM_PROGRAM` を受け取るようにする。

   ```bash
   # sshd の受け取る環境変数を設定する
   echo 'AcceptEnv TERM_PROGRAM' | sudo tee /etc/ssh/sshd_config.d/50-wezterm.conf
   # sshd の設定を検査して読み直す
   sudo sshd -t && sudo systemctl reload sshd
   # 環境変数の受け取り設定を確かめる
   sudo sshd -T | grep -i '^acceptenv'
   ```

   - 最後に `acceptenv TERM_PROGRAM` と出ればよい
   - `sshd -t` が設定の誤りを出したら、`reload` はされない
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると、sudo が失敗しても後ろの共通 bash 設定の導入と clone が動く）

1. SSH 先に共通 bash 設定と WezTerm のシェル統合を置く。

   ```bash
   # SSH 先に共通 bash 設定を導入する
   git clone https://github.com/ryo-aoki-pc/bash.git ~/.config/bash &&
     bash ~/.config/bash/install.sh
   # WezTerm のシェル統合を取得する
   git clone https://github.com/ryo-aoki-pc/wezterm.git ~/.config/wezterm
   ```

   - 同期済みの設定は再 clone しない
   - clone 済みなら、そのリポジトリの更新を行う
   - **次の手順は、clone が成功してから行う**

1. 手元の WezTerm の新しいタブから、ssh し直す。

   - `ssh <HOST>` を打つか、起動メニュー（`Ctrl+Shift+M`）の「ssh <HOST>」を選ぶ
   - **次の手順は、ssh 先のシェルで貼る**（続けて貼ると、ssh 先のシェルの中ではなく、ssh を閉じた後の手元のシェルで動く）

1. ssh 先のシェルで、`TERM_PROGRAM` が届き、シェル統合が読まれたか確かめる。

   ```bash
   # 環境変数とシェル統合の読み込みを確かめる
   echo "$TERM_PROGRAM"
   declare -F __wezterm_set_user_var __wezterm_notify_done __wz_mouse_off
   ```

   - 1 行目が `WezTerm` ならよい。公式 Bash 統合が有効なら、空でも補完処理は動く。公式統合が無ければ、この項の手順 1・2 を見直す
   - 2 つ目の見方は`__wezterm_notify_done` と `__wz_mouse_off` が出ればよい。COPR の公式統合が有効なら `__wezterm_set_user_var` も出る
   - tmux の中では `TERM_PROGRAM` が `tmux` になり、マウス報告よけのほかは動かない

#### WezTerm の設定を更新する

自分用の WezTerm の設定のリポジトリを pull で上げる。WezTerm 本体の更新は[更新](almalinux-setup.md#更新)で行う。

- 前提: [WezTerm](#wezterm)を通してある
- 実行場所: 自分のユーザーの bash（Windows 11 は Git Bash）

1. 設定のリポジトリを pull する。

   ```bash
   # WezTerm の設定を更新して版を確かめる
   git -C ~/.config/wezterm pull
   git -C ~/.config/wezterm log -1 --oneline
   ```

   - 新しいコミットが無ければ、`Already up to date.` と出る
   - 起動中の WezTerm は、ファイルが変わると設定を読み直す（効かなければ `Ctrl+Shift+R`）
   - シェル統合（`shell/`）とウィンドウの装飾の変更は、WezTerm を起動し直すまで効かない
   - 手元で変えたファイルがあって pull が止まったら、`git -C ~/.config/wezterm status` で見る

<details id="wezterm-の補足と注意点">
  <summary>WezTerm の補足と注意点</summary>

**注意点**

- **WezTerm: EL9 向けバイナリを EL10 で使っている。** 作者はこの組み合わせを保証していない
  - いまは EL9/EL10 のライブラリ soname がすべて一致しているので動く
  - 将来 COPR 側のビルド環境（EL9）と EL10 の間で soname が食い違えば、`dnf upgrade` が依存関係で止まるか、入っても起動しなくなる
  - 止まったときは `dnf upgrade --exclude='wezterm*'` で他を先に上げ、COPR に `epel-10` chroot が追加されていないか[プロジェクトページ](https://copr.fedorainfracloud.org/coprs/wezfurlong/wezterm-nightly/)を見る
  - 追加されていたら、`sudo dnf copr remove wezfurlong/wezterm-nightly` → `sudo dnf copr enable wezfurlong/wezterm-nightly`（chroot 省略）で乗り換えられる

- **WezTerm: nightly は毎日変わる。** `dnf upgrade` のたびに WezTerm も更新される
  - 安定版に固定したければ、COPR ではなく GitHub Releases の安定版 rpm（`wezterm-<version>-1.centos9.rpm`、こちらも EL10 向けは無い）か Flathub を使う

- **WezTerm: `TERM` は既定の `xterm-256color` のまま**。EL10 の `ncurses-base` に `wezterm` の terminfo は無い（`infocmp wezterm` → rc=1、`ncurses-term` も未導入）
  - 設定で `term = "wezterm"` にするなら、先に [WezTerm の公式ドキュメントの terminfo の手順](https://wezterm.org/config/lua/config/term.html)で入れる（ここでは試していない）

- **WezTerm: `/etc/profile.d/wezterm.sh` は全ユーザーの対話シェルに読み込まれる。** WezTerm 以外の端末でも OSC シーケンスを出す（大半の端末は無視する）
  - `bash-preexec` を内蔵しているので、`PROMPT_COMMAND` や `DEBUG` trap を自前で使っている環境では干渉に注意
  - 無効化は `WEZTERM_SHELL_SKIP_ALL=1`。自分用の WezTerm の設定（[WezTerm](#wezterm)の手順 3）を使うなら、止めない（その docs/install.md の注意点）

- **WezTerm: 既存の `_copr:...yazi.repo` など EL10 向け COPR と混在させても問題ない。** repo ごとに `baseurl` の chroot が違うだけ

**[WezTerm](#wezterm)の手順 1: chroot を明示する理由**

`dnf copr enable` は chroot を省略すると `/etc/os-release` から推定する。EL 系は `epel-<major>-<arch>` になる（`/usr/lib/python3.12/site-packages/dnf-plugins/copr.py` の `_guess_chroot`）。このプロジェクトに `epel-10-x86_64` は無いので失敗する:

エラーメッセージの言うとおり第 2 引数に chroot を渡せば通る。「repo ファイルの手直しが要るかも」とあるが、生成された repo ファイルは `baseurl` が `rhel-9-$basearch` を指すだけで、そのまま使えた:

```
[copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly]
name=Copr repo for wezterm-nightly owned by wezfurlong
baseurl=https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/rhel-9-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
```

公式ドキュメントの openSUSE 向け手順が同じ `dnf copr enable wezfurlong/wezterm-nightly <repository>` の形なので、想定内の使い方ではある。

- chroot は `uname -m` から `rhel-9-x86_64` か `rhel-9-aarch64` になる（COPR に EL10 向けが無いので EL9 向けを使う）

**[WezTerm](#wezterm)の手順 2**

- 途中で COPR の GPG 鍵の取り込みを聞かれる

- GUI は、**GNOME にログイン済みの実セッションの端末から** `wezterm` を起動すれば開く

**[WezTerm](#wezterm)の手順 2: wezterm はメタパッケージ / 取り込まれる鍵**

この節の検証記録: `docs/verification/shell-terminal.md` の「WezTerm: 実施手順 / 手順 3: 補足: wezterm はメタパッケージ / 取り込まれる鍵」

- `wezterm` 本体（6.4 KB、`rpm -ql wezterm` は空）は、`wezterm-common`（CLI の `wezterm`、シェル統合、補完）/ `wezterm-gui`（`wezterm-gui`、desktop ファイル、アイコン）/ `wezterm-mux-server` を Requires で束ねているだけ
- `dnf repoquery --requires wezterm` に `gcc` / `*-devel` / `make` が並んで見えるのは、同名の **SRPM の BuildRequires** が一緒に表示されているため。x86_64 パッケージには入っていない

GPG 鍵はインストール時に COPR の `pubkey.gpg` から取り込まれる:

```
Importing GPG key 0xCEA2757D:
 Userid     : "wezfurlong_wezterm-nightly (None) <wezfurlong#wezterm-nightly@copr.fedorahosted.org>"
 Fingerprint: FD90 9B62 88A8 4250 AD58 020F A698 91C5 CEA2 757D
 From       : https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/pubkey.gpg
```

**[WezTerm](#wezterm)の手順 2: wezterm ls-fonts と wezterm-gui --version**

- **`wezterm ls-fonts`** は GUI 無しでフォント解決を確認できる
  - 既定のフォントは組み込みの `JetBrains Mono` で、フォールバックに `Noto Color Emoji`（fontconfig 経由）と組み込みの `Symbols Nerd Font Mono` が並ぶ
  - `| head` で切ると `rc=101`（Rust の panic 終了コード）になるが、パイプが閉じたためで異常ではない。単体で実行すると `rc=0`
- **`wezterm-gui --version` は `wezterm-gui someone forgot to call assign_version_info` と出る**（rc=0）
  - COPR ビルドでは GUI バイナリにバージョン情報が埋め込まれていない。バージョンは `wezterm --version` で見る

**[WezTerm](#wezterm)の手順 2: アプリ一覧の項目**

- アプリ一覧の「WezTerm」は、`/usr/share/applications/org.wezfurlong.wezterm.desktop` から出る

**[WezTerm と HackGen Console NF をデスクトップで使う](#wezterm-と-hackgen-console-nf-をデスクトップで使う)の手順 1: 等幅のフォント**

- 等幅のフォントは、端末の Ptyxis などが使う
- 最初の `get` は変える前の値（AlmaLinux 10 の既定は `'Red Hat Mono Regular 10'`）
- Ptyxis は既定でこのフォントを使うので、開いている端末もすぐに変わる

**[WezTerm の設定ファイル](#wezterm-の設定ファイル)のリード**

- **自分用の設定**は [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm) にある（Tokyo Night 系の配色・ピル型タブ・ステータスバー・シェル統合の設定）

- どこを変えればよいかは [README の「カスタマイズの勘所」](https://github.com/ryo-aoki-pc/wezterm#カスタマイズの勘所)

- AlmaLinux 10 の公式 Bash 統合との併用は[設定の注意点](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/extra/install.md#注意点)を参照する

- Windows 11 は Git Bash を既定にし、Git Bash・PowerShell の統合を設定から読む（[シェル統合](https://github.com/ryo-aoki-pc/wezterm#シェル統合)）

- 導入は[WezTerm](#wezterm)の手順 3。[WezTerm の設定を導入する](#wezterm-の設定を導入する)の手順 5 で端末を開き直す


- フォントは HackGen Console NF（[HackGen Console NF](#hackgen-console-nf)）

**[WezTerm の設定を導入する](#wezterm-の設定を導入する)の手順 2**

- あったものだけ、`renamed '/home/<USER>/.config/wezterm' -> '/home/<USER>/.config/wezterm.bak'` のように出る

**[WezTerm の設定を導入する](#wezterm-の設定を導入する)の手順 6**

- 公式統合との併用は[注意点](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/extra/install.md#注意点)を参照する

**[WezTerm のシェル統合を SSH 先で使う](#wezterm-のシェル統合を-ssh-先で使う)の手順 3**

- WezTerm 本体は SSH 先のシェル統合には要らない

**選択した方針**

`wezterm-gui` が要求するのは次のもの（`dnf repoquery --requires wezterm-gui`）:

- `libc.so.6(GLIBC_2.34)`
- `libssl.so.3(OPENSSL_3.0.0)` / `libcrypto.so.3`
- `libwayland-client.so.0` / `libwayland-egl.so.1`
- `libxkbcommon.so.0(V_0.6.0)` / `libxkbcommon-x11.so.0`
- `libxcb.so.1` / `libxcb-image.so.0` / `libxcb-util.so.1`
- `libX11.so.6` / `libX11-xcb.so.1`
- `libfontconfig.so.1`、`mesa-libEGL`、`dbus`

EL10 は glibc 2.39 / OpenSSL 3.5（`libssl.so.3` の soname と `OPENSSL_3.0.0` シンボルバージョンを両方提供）なので、EL9 向けバイナリがそのまま動く。

**参照**

- 検証記録（`docs/verification/shell-terminal.md`）

- [背景説明](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/reference/install.md)・検証記録（`repos/wezterm/docs/verification/install.md`）

</details>

---

## Windows 11 で使う

- HackGen Console NF・共通の bash 設定・WezTerm の設定・PowerShell の開発の設定を更新する

### HackGen Console NF を上げる

- HackGen Console NF の新しい版を確かめ、必要なときに入れ直す
- 前提: HackGen Console NF が自分のユーザーのフォントに入っている
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。サインインし直した後も、管理者ではない PowerShell 7 を開く

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. HackGen の新しい版が出ているかを確かめる。

   ```powershell
   (Invoke-RestMethod -Uri https://api.github.com/repos/yuru7/HackGen/releases/latest).tag_name
   ```

   - `v2.10.0` なら、新しい版は無い。この項の手順 3〜8 は行わない
   - 違う版なら、この項の手順 6 の `$ver` と `$sha256` を、その版の zip と、その zip から計算して確認したハッシュ値に合わせて直してから貼る

1. 新しい版にするときだけ、HackGen の登録を消す。

   ```powershell
   # HackGen の登録を削除する
   $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
   (Get-Item -LiteralPath $key).Property -like 'HackGen*ConsoleNF-* (TrueType)' | ForEach-Object { Remove-ItemProperty -LiteralPath $key -Name $_ }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-Item -LiteralPath $key).Property -like 'HackGen*'
   ```

   - 最後のコマンドが何も出さなければよい

1. 新しい版にするときだけ、この PC でサインアウトし、サインインし直す。

   - 再起動でもよい
   - **次の手順は、サインインし直して PowerShell 7 を開いてから貼る**

1. 新しい版にするときだけ、フォントのファイルを消す。

   ```powershell
   # HackGen のフォントファイルを削除する
   Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\HackGen*ConsoleNF-*.ttf"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" -Filter 'HackGen*'
   ```

   - 最後のコマンドが何も出さなければよい
   - フォントの保存先の読み取りの許可は残す（ほかのフォントにも要る）

1. 新しい版にするときだけ、この項の手順 2 の版と sha256 をブロックに書き、フォントを入れ直す。

   ```powershell
   & {
     # フォントの取得先と登録先を用意する
     $ver = '2.10.0'
     $sha256 = 'F8ABD483D5EDFAD88A78ED511978F43C83B43C48E364AA29EBE4A68217474428'
     $fonts = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
     $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
     $tmp = "$env:TEMP\hackgen-setup"
     $zip = "$tmp\HackGen_NF_v$ver.zip"
     # 配布ファイルを取得して照合する
     Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & "$env:WINDIR\System32\curl.exe" -fsSL -o $zip "https://github.com/yuru7/HackGen/releases/download/v$ver/HackGen_NF_v$ver.zip"
     if ($LASTEXITCODE -ne 0) { Write-Error "中断: HackGen_NF_v$ver.zip を取れない"; return }
     if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $sha256) { Write-Error "中断: HackGen_NF_v$ver.zip の sha256 が一致しない"; return }
     # フォントのファイルを展開する
     Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
     $ttf = @(Get-ChildItem -LiteralPath "$tmp\HackGen_NF_v$ver" -Filter '*.ttf')
     if ($ttf.Count -ne 4) { Write-Error "中断: zip の中の ttf が 4 つではない（$($ttf.Count)）"; return }
     # フォントを配置して登録する
     New-Item -ItemType Directory -Force -Path $fonts | Out-Null
     icacls.exe $fonts /grant '*S-1-15-2-1:(OI)(CI)(RX)' '*S-1-15-2-2:(OI)(CI)(RX)' | Out-Null
     if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key | Out-Null }
     foreach ($f in $ttf) {
       $dst = Join-Path $fonts $f.Name
       if (-not (Test-Path -LiteralPath $dst) -or (Get-FileHash -LiteralPath $dst).Hash -ne (Get-FileHash -LiteralPath $f.FullName).Hash) {
         try { Copy-Item -LiteralPath $f.FullName -Destination $dst -Force -ErrorAction Stop } catch { Write-Error "中断: $($f.Name) を置けない（$($_.Exception.Message)）"; return }
       }
       New-ItemProperty -Path $key -Name "$($f.BaseName) (TrueType)" -Value $dst -PropertyType String -Force | Out-Null
     }
     # 作業用のファイルを消去する
     Remove-Item -LiteralPath $tmp -Recurse -Force
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ItemProperty -LiteralPath $key | Select-Object -Property 'HackGen*' | Format-List
   }
   ```

   - `HackGen` のフォントの登録が 4 行出ればよい。`中断:` が出たら先へ進まない

1. 入れ直したときだけ、この PC でサインアウトし、サインインし直す。

   - 再起動でもよい
   - **次の手順は、サインインし直してから行う**

1. 入れ直したときだけ、フォントの一覧を確かめる。

   - 設定 → 個人用設定 → フォント を開き、「HackGen」で探すと、`HackGen Console NF` と `HackGen35 Console NF` が出る（どちらも「2 フォント フェイス」）
   - 検索欄が使えなければ一覧をスクロールして探す。メモ帳のフォントの一覧に出てもよい

<details id="hackgen-console-nf-を上げる-の補足と注意点">
  <summary>HackGen Console NF を上げる の補足と注意点</summary>

**注意点**

- フォントのファイルは読み込まれている間は置き換えられない。登録を消し、サインインし直してからファイルを消す

**参照**

- [HackGen](https://github.com/yuru7/HackGen) — フォントの配布元とリリース
- 検証記録（`docs/verification/shell-terminal.md`）

</details>

---

### Windows 11 で共通の bash 設定を更新する

- 共通の bash 設定のリポジトリを更新し、端末を開き直して反映する
- 前提: 共通の bash 設定が `~/.config/bash` にあり、`~/.bashrc` から読み込まれる。WezTerm で Git Bash が開く
- 実行場所: この PC のデスクトップの、自分のユーザーの WezTerm の Git Bash のタブ。この項の手順 1 で開く
- 手元の変更は `git -C ~/.config/bash status` で確認してから進む

1. スタートメニューから WezTerm を開き、Git Bash の新しいタブを用意する。

   - スタートメニューで「WezTerm」を探して開く（管理者として実行しない）。開いていれば Ctrl+Shift+T で新しいタブを開く
   - `UCRT64` と `$` のプロンプトが出ればよい（Git for Windows 2.55 までは `MINGW64`）
   - **次の手順は、この Git Bash のタブに貼る**

1. origin を HTTPS にそろえて、設定のリポジトリを pull する。

   ```bash
   # 取得先を設定し、共通の bash 設定を更新する
   git -C ~/.config/bash remote set-url origin https://github.com/ryo-aoki-pc/bash.git
   git -C ~/.config/bash pull --ff-only
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/bash log -1 --oneline
   ```

   - 新しいコミットが無ければ `Already up to date.` と出て、最後にいちばん新しいコミットが 1 行出る
   - インターネットに出られないホストは、[SSH の SOCKS トンネル](almalinux-setup.md#ssh-の-socks-トンネル)を張ったシェルで貼る
   - 手元で変えたファイルがあって pull が止まったら、`git -C ~/.config/bash status` で見る
   - 開いている端末には効かない。端末を開き直す

<details id="windows-11-で共通の-bash-設定を更新する-の補足と注意点">
  <summary>Windows 11 で共通の bash 設定を更新する の補足と注意点</summary>

**参照**

- 検証記録（`docs/verification/shell-terminal.md`）

</details>

---

### Windows 11 で WezTerm の設定を更新する

- WezTerm の設定のリポジトリを更新する
- 前提: WezTerm 本体が入り、自分用の設定が `~/.config/wezterm` にある。WezTerm で Git Bash が開く
- 実行場所: この PC のデスクトップの、自分のユーザーの WezTerm の Git Bash のタブ。この項の手順 1 で開く
- WezTerm 本体は[Git for Windows・Firefox・WezTerm を上げる](windows-setup.md#git-for-windowsfirefoxwezterm-を上げる)で更新する
- 手元の変更は `git -C ~/.config/wezterm status` で確認してから進む

1. スタートメニューから WezTerm を開き、Git Bash の新しいタブを用意する。

   - スタートメニューで「WezTerm」を探して開く（管理者として実行しない）。開いていれば Ctrl+Shift+T で新しいタブを開く
   - `UCRT64` と `$` のプロンプトが出ればよい（Git for Windows 2.55 までは `MINGW64`）
   - **次の手順は、この Git Bash のタブに貼る**

1. 設定のリポジトリを pull する。

   ```bash
   # WezTerm の設定を更新する
   git -C ~/.config/wezterm pull
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/wezterm log -1 --oneline
   ```

   - 新しいコミットが無ければ、`Already up to date.` と出る
   - 起動中の WezTerm は、ファイルが変わると設定を読み直す（効かなければ `Ctrl+Shift+R`）
   - シェル統合（`shell/`）とウィンドウの装飾の変更は、WezTerm を起動し直すまで効かない
   - 手元で変えたファイルがあって pull が止まったら、`git -C ~/.config/wezterm status` で見る

<details id="windows-11-で-wezterm-の設定を更新する-の補足と注意点">
  <summary>Windows 11 で WezTerm の設定を更新する の補足と注意点</summary>

**参照**

- 検証記録（`docs/verification/shell-terminal.md`）

</details>

---

### PowerShell の開発の設定を更新する

- 外部コマンドの補完の控えと、7・5.1 の開発用モジュールを上げる
- 前提: 7 に PSScriptAnalyzer・Pester・CompletionPredictor・PSFzf、5.1 に PSScriptAnalyzer・Pester が入っている。補完は、7 のプロファイルが `%LOCALAPPDATA%\PowerShell\completions` の控えを読むときだけ
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。モジュールの操作は `pwsh.exe -NoLogo -NoProfile -Command { … }` で行う
- 外部コマンドは、先に [scoop・winget・WSL を上げる](windows-setup.md#scoopwingetwsl-を上げる)で上げる
- PSReadLine は 5.1 の自分のユーザーのモジュールの保存先に入っているときだけ、この項の手順 5 で対象にする

> [!WARNING]
> この項の手順 5 で保存する PSReadLine の最新版は、2.4.5 と同じ動作とは限らない。新しい管理者の窓・SSH のセッションにも効くので、保存した後は [PowerShell の開発の設定を確かめる](#powershell-の開発の設定を確かめる)の手順 5 で版・キー・貼り付けを確かめる。

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 補完の設定を行ったときは、入っている道具の補完の控えを作り直す。

   ```powershell
   & {
     # 保存先を用意し、入出力の設定を控える
     $dir = Join-Path $env:LOCALAPPDATA 'PowerShell\completions'
     New-Item -ItemType Directory -Path $dir -Force | Out-Null
     $u8in = [Console]::InputEncoding; $u8out = [Console]::OutputEncoding
     $log = @()
     # 各コマンドの補完ファイルを生成する
     try {
       [Console]::InputEncoding = [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
       foreach ($t in @(@('gh', 'completion', '-s', 'powershell'), @('rg', '--generate', 'complete-powershell'), @('fd', '--gen-completions', 'powershell'), @('delta', '--generate-completion', 'powershell'), @('bat', '--completion', 'ps1'), @('starship', 'completions', 'powershell'))) {
         $name = $t[0]; $args2 = $t[1..($t.Count - 1)]
         if (Get-Command -Name $name -CommandType Application -ErrorAction Ignore) {
           $text = (& $name @args2) -join "`r`n"
           if ($LASTEXITCODE -eq 0 -and $text) { [IO.File]::WriteAllText((Join-Path $dir "$name.ps1"), $text + "`r`n", (New-Object Text.UTF8Encoding($true))); $log += "wrote $name" } else { $log += "failed $name exit $LASTEXITCODE" }
         } else { $log += "skip $name" }
       }
     } finally { [Console]::InputEncoding = $u8in; [Console]::OutputEncoding = $u8out }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     # 補完ファイルの生成結果を確かめる
     $log
     # 保存したファイルの名前と大きさを確かめる
     $log = @()
     $log += (Get-ChildItem -LiteralPath $dir | ForEach-Object { '{0} {1}' -f $_.Name, $_.Length })
     $log
   }
   ```

   - 入っている道具に `wrote <名前>`、無い道具に `skip <名前>` と、ファイルの名前・大きさが出ればよい。`failed` が出たら、その道具の場所と版を確かめる
   - 新しい PowerShell 7 を開き、[PowerShell の開発の設定を確かめる](#powershell-の開発の設定を確かめる)の手順 3 の補完を確かめて閉じる

1. PowerShell 7 の開発用モジュールを上げる。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     # 更新前のモジュールの版を確かめる
     Get-PSResource -Name PSScriptAnalyzer,Pester,CompletionPredictor,PSFzf -Scope CurrentUser | Select-Object Name,Version,InstalledLocation | Out-String -Width 160
     # PowerShell 7 の開発モジュールを更新する
     Update-PSResource -Name PSScriptAnalyzer,Pester,CompletionPredictor,PSFzf -Repository PSGallery -Scope CurrentUser -TrustRepository -ErrorAction Stop
     # 更新後のモジュールの版を確かめる
     Get-PSResource -Name PSScriptAnalyzer,Pester,CompletionPredictor,PSFzf -Scope CurrentUser | Select-Object Name,Version,InstalledLocation | Out-String -Width 160
   }
   ```

   - 更新前後の版と保存先を控える。新しい版が無ければ、更新のコマンドは何も出さない
   - [PowerShell の開発の設定を確かめる](#powershell-の開発の設定を確かめる)の手順 1〜3 で確かめ、窓を閉じる

1. 5.1 用の 2 つのモジュールを、公開されている版と比べて保存する。

   ```powershell
   # 5.1 用のモジュールの保存先を用意する
   pwsh.exe -NoLogo -NoProfile -Command {
     $dir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'
     New-Item -ItemType Directory -Force -Path $dir | Out-Null
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($n in 'PSScriptAnalyzer','Pester') {
       $saved = @(Get-PSResource -Name $n -Path $dir -ErrorAction SilentlyContinue)
       $latest = Find-PSResource -Name $n -Repository PSGallery -ErrorAction Stop
       $current = $saved | Sort-Object { [version]$_.Version } -Descending | Select-Object -First 1
       '{0}: saved={1}, PSGallery={2}' -f $n,$current.Version,$latest.Version
       if (-not $current -or [version]$latest.Version -gt [version]$current.Version) {
         Save-PSResource -Name $n -Version $latest.Version -Repository PSGallery -TrustRepository -IncludeXml -Path $dir -ErrorAction Stop
       }
     }
     Get-PSResource -Name PSScriptAnalyzer,Pester -Path $dir | Select-Object Name,Version,InstalledLocation | Out-String -Width 160
   }
   ```

   - `saved` と `PSGallery` の比較と、保存した版が出ればよい。既に同じ版以上なら保存しない
   - 追加した版と保存先を控える。新しい 5.1 の窓で [PowerShell の開発の設定を確かめる](#powershell-の開発の設定を確かめる)の手順 4・5 を確かめ、閉じる
   - 5.1 のユーザーの保存先に PSReadLine が無ければ、この項の手順 5 は飛ばす

1. 5.1 のユーザーの保存先に PSReadLine があるときだけ、公開されている版と比べて保存する。

   ```powershell
   # 保存済みの版と公開版を取得する
   pwsh.exe -NoLogo -NoProfile -Command {
     $dir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'
     $saved = @(Get-PSResource -Name PSReadLine -Path $dir -ErrorAction SilentlyContinue)
     if (-not $saved.Count) { Write-Error '中断: この保存先に PSReadLine が無い'; exit 1 }
     $latest = Find-PSResource -Name PSReadLine -Repository PSGallery -ErrorAction Stop
     $current = $saved | Sort-Object { [version]$_.Version } -Descending | Select-Object -First 1
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'PSReadLine: saved={0}, PSGallery={1}' -f $current.Version,$latest.Version
     if ([version]$latest.Version -gt [version]$current.Version) {
       Save-PSResource -Name PSReadLine -Version $latest.Version -Repository PSGallery -TrustRepository -IncludeXml -Path $dir -ErrorAction Stop
     }
     Get-PSResource -Name PSReadLine -Path $dir | Select-Object Name,Version,InstalledLocation | Out-String -Width 160
   }
   ```

   - `saved` と `PSGallery` の比較と、保存した版が出ればよい。既に同じ版以上なら保存しない
   - 追加した版と保存先を控え、新しい 5.1 の窓で [PowerShell の開発の設定を確かめる](#powershell-の開発の設定を確かめる)の手順 5 を通す。版は、この手順で保存した版と比べる
   - キーや貼り付けが合わなければ、新しい窓・セッションを閉じ、保存先からこの手順で追加した版のフォルダーだけを消す。以前の版の窓で貼り付けを確かめ直す

1. 新しい版で確かめ終え、古い版が要らなければ、その版のフォルダーだけを消す。

   - 7 と 5.1 の窓・SSH のセッションをすべて閉じ、エクスプローラーで、この項の手順 3〜5 で控えた保存先を開く。更新の前から開いている 5.1 の窓も、古い版の PSReadLine を使っている
   - この項で扱ったモジュールの名前の下で、使わない古い版のフォルダーだけを消す。新しい版と、元に戻すために残す版は消さない
   - `Documents\WindowsPowerShell\Modules` の `PSWindowsUpdate` など、ほかのモジュールには触れない
   - PSReadLine の `2.4.5` を残すかは、戻す版として使うかで決める。同梱の `$PSHOME\Modules` は変えない
   - 新しい 7 と 5.1 の窓で `Get-Module -ListAvailable` を使い、残した版が見えることを確かめる

#### PowerShell の開発の設定を確かめる

- 更新したモジュールと、設定済みのプロファイルの文字コード・補完・キーを確かめる
- 前提: PowerShell の開発用モジュールが 7 と 5.1 に入り、ユーザーの環境変数 `POWERSHELL_TELEMETRY_OPTOUT=1`・`POWERSHELL_UPDATECHECK=Off` が設定されている。7 のプロファイルの確認は、開発の設定があるときだけ
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7 と Windows PowerShell（5.1）。この項の手順 1・4 で開く

1. スタートメニューから、新しい PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、「Windows PowerShell」ではない「PowerShell」（PowerShell 7）をクリックして開く
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる
   - 日本語のコミットがあるローカルの Git リポジトリへ `Set-Location` で移る
   - **次の手順は、新しく開いた PowerShell 7 の窓に貼る**

1. 新しい PowerShell 7 で、モジュールと環境変数を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # 開発モジュールとコマンドを読み込む
   Import-Module PSScriptAnalyzer,Pester -PassThru | Select-Object Name,Version,ModuleBase | Format-Table -AutoSize
   Get-Command Invoke-ScriptAnalyzer,Invoke-Pester | Select-Object Name,Source | Format-Table -AutoSize
   # 解析ツールの動作を確かめる
   Invoke-ScriptAnalyzer -ScriptDefinition 'gci; $x = 1' | Select-Object RuleName | Format-Table -AutoSize
   # PowerShell の環境変数を確かめる
   "POWERSHELL_TELEMETRY_OPTOUT = $env:POWERSHELL_TELEMETRY_OPTOUT"
   "POWERSHELL_UPDATECHECK = $env:POWERSHELL_UPDATECHECK"
   ```

   - 保存した版と 2 つのコマンド、`PSAvoidUsingCmdletAliases`・`PSUseDeclaredVarsMoreThanAssignments` が出ればよい
   - 環境変数は `1`・`Off` ならよい。空なら、Windows Terminal など端末アプリの窓をすべて閉じて開き直し、この項の手順 1・2 をやり直す

1. 7 のプロファイルに開発の設定があるときだけ、文字コード・補完・予測・関数とキーを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # 端末の文字コードと Git の日本語出力を確かめる
   [Console]::InputEncoding.CodePage
   [Console]::OutputEncoding.CodePage
   $s = git log -10 --format=%s
   $s
   # 予測の表示設定を確かめる
   Get-PSReadLineOption | Select-Object PredictionSource,PredictionViewStyle
   # fzf のキー割り当てを確かめる
   Get-PSReadLineKeyHandler -Chord Ctrl+t,Ctrl+r | Format-Table Key,Function,Description -AutoSize
   # 開発用の関数を確かめる
   Get-Command Invoke-Utf8Native,ll,err -ErrorAction SilentlyContinue | Select-Object Name,CommandType
   ```

   - コード ページが 2 つとも `65001` で、`$s` の日本語が化けていなければよい。日本語の件名が無ければ、そのコミットを含む範囲で確かめる
   - `PredictionSource` が `HistoryAndPlugin`、`PredictionViewStyle` が `ListView` ならよい。`Set-Lo` と打つと履歴の候補、`Get-Process -Na` と打つと補完の予測の一覧が出る。Enter を押さず Ctrl+C で取り消す
   - `winget ins` と打って Tab を押すと `install` になる。`gh pr ` と打って Tab を押すと候補の一覧が出る。試すたびに Ctrl+C で行を取り消す（一覧が出ているときは、先に Esc で一覧を閉じる。無い道具は飛ばす）
   - rg・fd・delta・bat・starship の補完も、入っているものだけ Tab で確かめる
   - fzf があれば、Ctrl+T でファイルの一覧が開き、Enter で選んだパスが行に入る。Ctrl+C で行を取り消し、Ctrl+R で履歴の一覧が開くことも確かめ、Esc で閉じる
   - eza があれば `ll` で長い一覧が出る。`Write-Error 'PowerShell dev check'` の後に `err` を打ち、そのエラーの中身が出ることを確かめる

1. スタートメニューから、新しい Windows PowerShell（5.1）を開く。

   - 「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - **次の手順は、新しく開いた Windows PowerShell（5.1）の窓に貼る**

1. 新しい Windows PowerShell（5.1）で、保存したモジュールを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # 開発モジュールとコマンドを読み込む
   Import-Module PSScriptAnalyzer,Pester -PassThru | Select-Object Name,Version,ModuleBase | Format-Table -AutoSize
   Get-Command Invoke-ScriptAnalyzer,Invoke-Pester | Select-Object Name,Source | Format-Table -AutoSize
   # 解析ツールの動作を確かめる
   Invoke-ScriptAnalyzer -ScriptDefinition 'gci; $x = 1' | Select-Object RuleName | Format-Table -AutoSize
   ```

   - 更新した版と 2 つのコマンド、`PSAvoidUsingCmdletAliases`・`PSUseDeclaredVarsMoreThanAssignments` が出ればよい
   - ユーザーの保存先に PSReadLine があるときは、保存した版と、新しい 5.1 の `Get-Module PSReadLine` の版を照合する
   - PSReadLine を更新したときは、`Get-PSReadLineKeyHandler -Bound` で `Ctrl+Enter` が `AddLine`、`(Get-PSReadLineOption).PredictionSource` が `History` であることを確かめる
   - 5.1 のキー操作を設定してあれば、`Ctrl+v` が `Paste`、↑/↓ が `HistorySearchBackward`・`HistorySearchForward` のままであることも確かめる
   - 右クリックで複数行を貼り、元の順に 1 つの入力になることを確かめる。管理者の窓や 5.1 の SSH を使う場合は、新しい窓・セッションでも確かめる

<details id="powershell-の開発の設定を更新する-の補足と注意点">
  <summary>PowerShell の開発の設定を更新する の補足と注意点</summary>

**参照**

- 検証記録（`docs/verification/shell-terminal.md`）

</details>

---
