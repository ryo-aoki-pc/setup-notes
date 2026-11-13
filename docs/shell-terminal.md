# シェルと端末のセットアップ（AlmaLinux 10・Windows 11）

- 自分用の共通の bash 設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）と、シェルのツール（starship・zoxide・fzf・eza・bat・tmux）、端末のフォント（HackGen Console NF）、端末（WezTerm nightly と自分用の設定 [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)）を入れる。Windows 11 では Git Bash を主のシェルにし、Windows Terminal・PowerShell 7 のプロファイル・PowerShell の開発の設定も整える
- 検証記録・参考資料・注意点は、各用途の末尾の「補足と注意点」と、冒頭の「この文書の補足と注意点」から開く

> [!IMPORTANT]
> - AlmaLinux 10 の項は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)と同じく、**GNOME にログインした、インストール時の管理者ユーザー（`wheel`）の bash で行う**。`sudo -i`・`su -` のシェルでは行わない
> - AlmaLinux 10 の項は、パスワードを聞かない `sudo` を前提に書いてある。各項のリードの前提に無くても、その項を行うユーザーで[ログインと sudo](almalinux-setup.md#ログインと-sudo)を先に通す
> - Windows 11 の項は、[Windows 11 のセットアップ](windows-setup.md)と同じく、**この PC のデスクトップで、Administrators のユーザーが行う**。PowerShell のブロックは **PowerShell 7** に貼る（[公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)）。複数行は、[「Windows Terminal で複数行を 1 つの入力として貼る」](shell-terminal.md#windows-terminal-で複数行を-1-つの入力として貼る)を通した窓に貼る。Windows PowerShell 5.1 に貼る項は、その項のリードに書く。管理者・通常の窓と Git Bash は、各項のリードに従う
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
- Windows 11 のプロファイルは、PowerShell 7 の基本の設定に印 `# windows-setup.md`、7 と 5.1 のキー操作に `# shell-terminal.md`、開発の設定に `# shell-terminal.md:dev` を使う。Windows Terminal の設定の控えは `settings.json.windows-setup.bak`

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

- プロファイルの行の印は、7 の基本の設定が `# windows-setup.md`、任意のキー操作が `# shell-terminal.md`、5.1・7 の開発の設定が `# shell-terminal.md:dev`
- Windows Terminal の控えは `settings.json.windows-setup.bak`
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

- 手順書のブロックは、貼った全体が 1 つの入力になる窓に貼る前提で書く（2026-11-07、利用者の決定）。bash はブラケットペースト、PowerShell は「Windows Terminal で複数行を 1 つの入力として貼る」の Enter の割り当てで、そうなる
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

- Windows 11 では、同じブロックを Git for Windows の Git Bash に貼る（[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)）

- フォントは HackGen Console NF（[HackGen Console NF](#hackgen-console-nf)。Windows 11 は[Windows 11 で HackGen Console NF を入れる](#windows-11-で-hackgen-console-nf-を入れる)）

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

- HackGen Console NF・Windows Terminal・WezTerm・Git Bash と共通の bash 設定・シェルのツール・PowerShell 7 のプロファイル・PowerShell の開発の設定

### Windows 11 で HackGen Console NF を入れる

- HackGen Console NF を自分のユーザーのフォントに入れる
- 前提: 無し
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる
   - 窓の名前に「管理者:」が付いていないことを確かめる

1. HackGen がまだ入っていないことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # フォントの登録を調べる
   Get-Item -LiteralPath 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' -ErrorAction SilentlyContinue | ForEach-Object { $_.Property -like 'HackGen*' }
   # フォントのファイルを調べる
   Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts", "$env:WINDIR\Fonts" -Filter 'HackGen*' -ErrorAction SilentlyContinue | Format-Table Name, DirectoryName
   ```

   - どちらも何も出なければ、入っていない
   - `C:\Windows\Fonts` のファイルが出たら、PC 全体に入っている（ほかの方法で入れたもの）。この項は要らない

1. HackGen Console NF の zip を取り、sha256 を確かめて自分のユーザーのフォントに入れる。

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

   - `HackGen` のフォントの登録が 4 行出ればよい
   - `中断:` で始まるエラーが出たら、そこで止まっている
   - アプリで使えるのは、[再起動](windows-setup.md#再起動)の手順 2 の再起動の後（確かめるのは[再起動の後に確かめる](windows-setup.md#再起動の後に確かめる)の手順 4）

#### HackGen Console NF を上げる

- HackGen Console NF の新しい版を確かめ、必要なときに入れ直す
- 前提: [Windows 11 で HackGen Console NF を入れる](#windows-11-で-hackgen-console-nf-を入れる)を通してある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。削除・再導入・確認は、リンク先の項に指定した窓で行う

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. HackGen の新しい版が出ているかを確かめる。

   ```powershell
   (Invoke-RestMethod -Uri https://api.github.com/repos/yuru7/HackGen/releases/latest).tag_name
   ```

   - `v2.10.0` なら、新しい版は無い。この項の手順 3〜6 は行わない
   - 違う版なら、[Windows 11 で HackGen Console NF を入れる](#windows-11-で-hackgen-console-nf-を入れる)の手順 3 の `$ver` と `$sha256` を、その版の zip と、その zip から計算して確認したハッシュ値に合わせて直してから貼る

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
   - [Windows 11 で HackGen Console NF を入れる](#windows-11-で-hackgen-console-nf-を入れる)の手順 3 の `icacls` で足した読み取りの許可は残す（ほかのフォントにも要る）

1. 新しい版にするときだけ、直した導入の手順で入れ直し、版を確かめる。

   - 直した[Windows 11 で HackGen Console NF を入れる](#windows-11-で-hackgen-console-nf-を入れる)の手順 3 を貼る
   - サインアウトしてサインインし直してから、[再起動の後に確かめる](windows-setup.md#再起動の後に確かめる)の手順 4 で確かめる

<details id="windows-11-で-hackgen-console-nf-を入れる-の補足と注意点">
  <summary>Windows 11 で HackGen Console NF を入れる の補足と注意点</summary>

**注意点**

- **HackGen Console NF: Windows 11 では、自分のユーザーのフォントが見えないアプリがある**: ユーザーごとのフォントは Windows 10 1809 からで、古いアプリには見えないことがある。そのアプリだけ、PC 全体に入れ直す（本書では扱わない）

- **HackGen Console NF: Windows 11 では、読み込まれているフォントのファイルを置き換えられない**: [HackGen Console NF を上げる](#hackgen-console-nf-を上げる)では、登録を消してサインインし直してから入れ替える

**[Windows 11 で HackGen Console NF を入れる](#windows-11-で-hackgen-console-nf-を入れる)の手順 2: 出た結果の意味**

- 検証記録（`docs/verification/windows-setup.md`）

- 自分のユーザーの登録と `%LOCALAPPDATA%` のファイルが出たら、[Windows 11 で HackGen Console NF を入れる](#windows-11-で-hackgen-console-nf-を入れる)で入れたもの（同じ項の手順 3 は何度貼ってもよい）
- `C:\Windows\Fonts` のファイルが出たら、PC 全体に入っていて、そのまま使える

**[Windows 11 で HackGen Console NF を入れる](#windows-11-で-hackgen-console-nf-を入れる)の手順 3**

- 何度貼ってもよい

- `HackGen35ConsoleNF-Bold (TrueType) : C:\Users\<WIN_USER>\AppData\Local\Microsoft\Windows\Fonts\HackGen35ConsoleNF-Bold.ttf` の形の行が 4 つ出ればよい

**[Windows 11 で HackGen Console NF を入れる](#windows-11-で-hackgen-console-nf-を入れる)の手順 3: 中断したときと貼り直したとき**

- `中断:` で止まったとき、取ってきたものは `%TEMP%\hackgen-setup` に残る。次に貼ったときに消して作り直す
- 何度貼ってもよいのは、同じファイルは置き直さないため

**[HackGen Console NF を上げる](#hackgen-console-nf-を上げる)の手順 2: 版と sha256 を直す理由**

- `$ver` と `$sha256` を直さなければ、固定した旧版を再び入れるだけで更新にはならない

**[HackGen Console NF を上げる](#hackgen-console-nf-を上げる)の手順 3**

- フォントのファイルは読み込まれている間は消せないので、登録を消してからサインインし直し、その後でファイルを消す

**[HackGen Console NF を上げる](#hackgen-console-nf-を上げる)の手順 3〜5: 外してから入れ直す理由**

- 更新で登録を消してサインインし直してからファイルを消すのは、読み込まれているファイルは置き換えられないため

**選択した方針**

| 経路 | 状況 | 採否 |
|---|---|---|
| **上流の zip を版と sha256 を固定して、自分のユーザーに入れる** | 管理者の権限も scoop も要らず、Windows PowerShell 5.1 で動く。更新は手作業 | **採用** |
| scoop の個人のバケット mo-san の `font-hackgen-console-nf` | リリースの zip を使い、scoop と UniGet UI で上げられる。インストールのスクリプトが `Join-Path` に 3 つ以上の引数を渡していて、Windows PowerShell 5.1 の `Join-Path`（`-Path` と `-ChildPath` だけ）では失敗するはず。scoop はそのスクリプトを、`scoop` を打った PowerShell の中で動かす。手順書は 7 に貼るので、この制約には当たらない | 不採用（個人の保守） |
| scoop の nerd-fonts のバケット | HackGen は無い | — |
| winget | 既定のソース（winget-pkgs）に HackGen は無い。winget の一覧のサイトには `yuru7.HackGen`（第三者の `dfirr/winget-hackgen` が作り直したインストーラで、PC 全体に入れる）が載っている | 不採用 |
| Chocolatey | 上流の README が Windows 向けに案内している | 不採用（別のパッケージ マネージャーを足し、管理者が要る） |
| PC 全体（`C:\Windows\Fonts`）に入れる | 管理者が要る | 不採用（AlmaLinux 10 と同じく自分のユーザーだけ） |

**参照**

- [HackGen v2.10.0](https://github.com/yuru7/HackGen/releases/tag/v2.10.0) — Windows 11 の節で取る `HackGen_NF_v2.10.0.zip`
- [Join-Path（5.1）— Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/join-path?view=powershell-5.1) — `-Path` と `-ChildPath` だけ（scoop の個人のバケットを採らなかった理由）
- [matthewjberger/scoop-nerd-fonts](https://github.com/matthewjberger/scoop-nerd-fonts) — Windows で自分のユーザーにフォントを入れる定義（issue #198 のアクセス権）
- [mo-san/scoop-bucket](https://github.com/mo-san/scoop-bucket) — 採らなかった scoop の個人のバケット
- [Windows 11 の初期設定](windows-setup.md) — Windows のインストール直後にまとめて行う設定（scoop・UniGet UI・Caps Lock・表示・電源・リモート デスクトップなど）。この節は、そのリードから案内される

- 検証記録（`docs/verification/shell-terminal.md`）

</details>

---

### Windows Terminal のフォントと貼り付けの警告を変える

- Windows Terminal のフォントを HackGen にし、必要なら複数行の貼り付けの警告を切る
- 前提: [Windows 11 で HackGen Console NF を入れる](#windows-11-で-hackgen-console-nf-を入れる)を通し、サインインし直してある。Windows Terminal が入り、Microsoft Store のアプリの更新を済ませてある
- 実行場所: この PC のデスクトップの管理者ではない Windows Terminal の PowerShell 7 のタブ。この項の手順 1 で開く

- **この項の手順 5 は Windows Terminal の設定の画面で行う**
- 効くのは Windows Terminal で開く窓（管理者ではない窓と、Win+X の「ターミナル」・「ターミナル (管理者)」）だけ。スタートメニューから管理者として開いた PowerShell（conhost の窓）には効かない
- 管理者ではない窓に複数行のブロックを貼ると、「警告」の窓が出ることがある（PSReadLine は、5.1・7 とも角かっこで囲む貼り付けを使わないため）。「強制的に貼り付け」を押す（出さないなら、この項の手順 4）
- 選んだらコピーするときは、[Windows Terminal で選択した文字をコピーする](#windows-terminal-で選択した文字をコピーする)を通す
- 複数行を 1 つの入力として貼るため、先に[Windows Terminal で複数行を 1 つの入力として貼る](#windows-terminal-で複数行を-1-つの入力として貼る)を通す

> [!WARNING]
> - この項の手順 4 で警告を切ると、信用できない複数行の文字も、確かめずにそのまま貼られて動く

1. 管理者ではない Windows Terminal の PowerShell 7 のタブを開く。

   - スタートメニューで「Windows Terminal」を開き、タブのメニューから「PowerShell」を選ぶ（「Windows PowerShell」ではない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. Windows Terminal の設定ファイルを控え、今のフォントと警告の値を確かめる。

   ```powershell
   & {
     # 設定ファイルと控えの場所を指定する
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     $bak = "$path.windows-setup.bak"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     # 設定ファイルの形式を調べる
     if (-not (Test-Path -LiteralPath $path)) { Write-Error "中断: 設定ファイルが無い。Windows Terminal を 1 度開いてから貼り直す: $path"; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある。この項の手順 5 の画面で変える: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない。この項の手順 5 の画面で変える: $path"; return }
     if (-not $s.profiles -or $s.profiles -is [array]) { Write-Error '中断: profiles が無いか古い形式（配列）。この項の手順 5 の画面で変える'; return }
     # 設定ファイルの控えを保存する
     if (Test-Path -LiteralPath $bak) { "控えはもうある（書き換えない）: $bak" } else { Copy-Item -LiteralPath $path -Destination $bak -ErrorAction Stop; "控えた: $bak" }
     # 端末とプロファイルの設定を確かめる
     [pscustomobject]@{
       Version          = (Get-AppxPackage -Name Microsoft.WindowsTerminal | Select-Object -First 1).Version
       DefaultsFontFace = $s.profiles.defaults.font.face
       MultiLinePaste   = $s.'warning.multiLinePaste'
       DefaultProfile   = $s.defaultProfile
       CopyOnSelect     = $s.copyOnSelect
     } | Format-List
     $s.profiles.list | Where-Object { $_.font.face } | Format-Table name, @{ Name = 'face'; Expression = { $_.font.face } }
   }
   ```

   - `控えた:` か `控えはもうある` と、`Version`・フォント・警告の値が出ればよい
   - 最後に表が出たら、そのプロファイルは自分のフォントを持つので、この項の手順 3 の値は効かない（この項の手順 5 の画面で、そのプロファイルを変える）
   - `中断:` が出たら、何も書いていない。この項の手順 5 の画面で変える
   - `Version` が 1.24 より前なら、この項の手順 4 は飛ばす

1. 全プロファイルのフォントを HackGen Console NF にする。

   ```powershell
   & {
     # 設定ファイルと控えを調べる
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     if (-not (Test-Path -LiteralPath "$path.windows-setup.bak")) { Write-Error '中断: 控えが無い。この項の手順 2 を先に貼る'; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない: $path"; return }
     if (-not $s.profiles -or $s.profiles -is [array]) { Write-Error '中断: profiles が無いか古い形式（配列）'; return }
     # 全プロファイルのフォントを設定する
     if (-not $s.profiles.PSObject.Properties['defaults']) { $s.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) }
     if (-not $s.profiles.defaults.PSObject.Properties['font']) { $s.profiles.defaults | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{}) }
     $s.profiles.defaults.font | Add-Member -NotePropertyName face -NotePropertyValue 'HackGen Console NF' -Force
     [IO.File]::WriteAllText($path, ($s | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'face: {0}' -f ([IO.File]::ReadAllText($path) | ConvertFrom-Json).profiles.defaults.font.face
   }
   ```

   - `face: HackGen Console NF` が出ればよい
   - フォントが見つからないと、端末に、フォントが見つからない旨が出て、別のフォントで出る（この項の手順 5 で確かめる）

1. Windows Terminal が 1.24 以降で、複数行を貼るたびに出る警告を出さないときだけ、警告を切る。

   ```powershell
   & {
     # 端末の版と設定ファイルを調べる
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     $ver = (Get-AppxPackage -Name Microsoft.WindowsTerminal | Select-Object -First 1).Version
     if (-not $ver -or [version]$ver -lt [version]'1.24') { Write-Error "中断: Windows Terminal の版が 1.24 より前: $ver"; return }
     if (-not (Test-Path -LiteralPath "$path.windows-setup.bak")) { Write-Error '中断: 控えが無い。この項の手順 2 を先に貼る'; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない: $path"; return }
     # 複数行を貼るときの警告を設定する
     $s | Add-Member -NotePropertyName 'warning.multiLinePaste' -NotePropertyValue 'never' -Force
     [IO.File]::WriteAllText($path, ($s | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'warning.multiLinePaste: {0}' -f ([IO.File]::ReadAllText($path) | ConvertFrom-Json).'warning.multiLinePaste'
   }
   ```

   - `warning.multiLinePaste: never` が出ればよい
   - 5 KiB を超える文字を貼るときは、別の警告が出ることがある

1. Windows Terminal の設定の画面で、フォントが見つかっていることを確かめる。

   - Windows Terminal の窓で Ctrl+, を押し、「既定値」→「外観」の「フォント スタイル」が `HackGen Console NF` で、「見つからないフォント:」が出ていない
   - 新しいタブを開くと、文字が HackGen になっている
   - この項の手順 2〜4 が `中断:` で止まったときは、この画面でフォント スタイルを選んで「保存」を押す（一覧に無ければ「すべてのフォントの表示」をオン）。警告は「操作」の「改行を貼り付ける際に警告する」を「なし」にする

#### Windows Terminal で選択した文字をコピーする

- 任意で、Windows Terminal の選択した文字を自動でコピーする `copyOnSelect` を `true` にする
- 前提: [Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)の手順 1・2 を通し、`settings.json.windows-setup.bak` がある
- 実行場所: この PC のデスクトップの管理者ではない Windows Terminal の PowerShell 7 のタブ。この項の手順 1 で開く
- コメントや末尾のカンマがあるファイルには書かない。控えは上書きしない

> [!WARNING]
> - この項の手順 2 の後は、文字を選ぶだけでクリップボードが置き換わり、手順書からコピーしたブロックも消える。右クリックは貼り付けになる。
> - [Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)の手順 4 で複数行の警告を切っていると、管理者の窓でも複数行が確かめずに動く。

1. 管理者ではない Windows Terminal の PowerShell 7 のタブを開く。

   - スタートメニューで「Windows Terminal」を開き、タブのメニューから「PowerShell」を選ぶ（「Windows PowerShell」ではない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 設定ファイルの最上位の `copyOnSelect` を `true` にする。

   ```powershell
   & {
     # 設定ファイルと控えを調べる
     $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
     if (-not (Test-Path -LiteralPath $path)) { Write-Error "中断: 設定ファイルが無い: $path"; return }
     if (-not (Test-Path -LiteralPath "$path.windows-setup.bak")) { Write-Error '中断: 控えが無い。shell-terminal.md の「Windows Terminal のフォントと貼り付けの警告を変える」の手順 2 を先に通す'; return }
     $text = [IO.File]::ReadAllText($path)
     if (($text -replace '"(?:[^"\\]|\\.)*"', '""') -match '/[/*]|,\s*[}\]]') { Write-Error "中断: コメントか末尾のカンマがある: $path"; return }
     try { $s = $text | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error "中断: 読めない: $path"; return }
     if (-not $text.TrimStart().StartsWith('{')) { Write-Error '中断: 最上位がオブジェクトではない'; return }
     # 選択した文字のコピーを有効にする
     $s | Add-Member -NotePropertyName copyOnSelect -NotePropertyValue $true -Force
     [IO.File]::WriteAllText($path, ($s | ConvertTo-Json -Depth 100), (New-Object System.Text.UTF8Encoding $false))
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'copyOnSelect: {0}' -f ([IO.File]::ReadAllText($path) | ConvertFrom-Json).copyOnSelect
   }
   ```

   - `copyOnSelect: True` が出ればよい
   - `中断:` が出たら、何も書いていない。コメントや末尾のカンマを残すときは、Windows Terminal の設定の「操作」で「選択範囲をクリップボードに自動的にコピー」をオンにして保存する

#### Windows Terminal で複数行を 1 つの入力として貼る

- Windows Terminal に貼った複数行を 1 つの入力にするため、Enter の割り当てをプロファイルに足す。ほかの手順書の PowerShell のブロックは、この項を通した窓に貼る前提で書いてある
- 前提: 使う版のユーザープロファイルが存在して読み込め、PSReadLine の Ctrl+Enter が `AddLine` に割り当てられている。Windows Terminal が入り、Microsoft Store のアプリの更新を済ませてある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。この項の手順 3・4 は、Windows Terminal の新しいタブ
- 同じプロファイルを読む窓すべてに効く（管理者の窓も）。構文エラーがあれば全体が動かない

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 7 と、既にある 5.1 のプロファイルの末尾に Enter の割り当てを足す。

   ```powershell
   & {
     # Enter の割り当てと追記先を用意する
     $line = 'if ((Get-Module -Name PSReadLine) -and $ExecutionContext.SessionState.LanguageMode -eq ''FullLanguage'') { Set-PSReadLineKeyHandler -Chord Enter -BriefDescription PasteAwareEnter -Description ''Keep pasted lines in one input'' -ScriptBlock { $rl = [Microsoft.PowerShell.PSConsoleReadLine]; $queue = $null; try { $queue = $rl.GetField(''_queuedKeys'', [Reflection.BindingFlags]''NonPublic,Instance'').GetValue($rl.GetField(''_singleton'', [Reflection.BindingFlags]''NonPublic,Static'').GetValue($null)) } catch {}; $more = $false; $clock = [Diagnostics.Stopwatch]::StartNew(); do { if ((($null -ne $queue) -and ($queue.Count -gt 0)) -or [Console]::KeyAvailable) { $more = $true; break }; [Threading.Thread]::Sleep(2) } while ($clock.ElapsedMilliseconds -lt 30); if ($more) { $rl::AddLine() } else { $rl::AcceptLine() } } }  # shell-terminal.md:paste'
     $p51 = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
     $p7 = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     $paths = @($p7, $p51)
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($p in $paths) {
       if (-not (Test-Path -LiteralPath $p)) {
         if ($p -eq $p51) { "飛ばした: 5.1 のプロファイルが無い: $p"; continue }
         New-Item -ItemType File -Path $p -Force -ErrorAction Stop | Out-Null
       }
       $text = Get-Content -LiteralPath $p -Raw
       if ($text -and $text.Contains($line)) { "すでにある: $p" } else {
         $add = $line
         if ($text -and -not $text.EndsWith("`n")) { $add = "`r`n" + $line }
         Add-Content -LiteralPath $p -Value $add -ErrorAction Stop
         "足した: $p"
       }
     }
   }
   ```

   - プロファイルごとに `足した:` か `すでにある:` が出ればよい。5.1 のプロファイルが無ければ `飛ばした:` が出る
   - 開いているタブには効かない。次の手順は新しいタブで行う

1. Windows Terminal で PowerShell 7 の新しいタブを開き、Enter の割り当てを確かめる。

   ```powershell
   Get-PSReadLineKeyHandler -Bound | Where-Object Key -eq 'Enter' | Format-Table Key, Function -AutoSize
   ```

   - `Enter` の行に `PasteAwareEnter` が出ればよい
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる
   - 出なければ、この項の手順 2 と、7 の実行ポリシーがプロファイルを読み込める設定かを確かめる
   - 5.1 でも使うなら、新しい「Windows PowerShell」のタブでも同じ 1 行を貼る。出なければ、5.1 のプロファイルと、それを読み込める実行ポリシーかを確かめる

1. 同じタブに右クリックで貼って Enter を押し、1 つの入力として動くことを確かめる。

   ```powershell
   $pasteCheck = (Get-History).Count
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   '入力の数: {0}' -f ((Get-History).Count - $pasteCheck + 1)
   ```

   - `入力の数: 1` が出ればよい
   - `入力の数: 3` なら、行ごとに動いている。以降の手順を続けず、新しいタブで開いたかと、この項の手順 3 の割り当てを確かめる
   - 「警告」の窓が出たら「強制的に貼り付け」を押す。この項の設定では警告は変わらない（出さないなら、[Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)の手順 4）

<details id="windows-terminal-のフォントと貼り付けの警告を変える-の補足と注意点">
  <summary>Windows Terminal のフォントと貼り付けの警告を変える の補足と注意点</summary>

**注意点**

- **Windows Terminal で複数行を 1 つの入力にすると、全体を先に構文解析する**: [Windows Terminal で複数行を 1 つの入力として貼る](#windows-terminal-で複数行を-1-つの入力として貼る)では、1 か所の構文エラーで全体が動かない
  - 実行中に先打ちした複数のコマンドも、1 つの入力にまとまる
  - 末尾に改行がある文字を貼ると、Enter を押さなくても全体が動く
  - PSReadLine の非公開の内部を読むため、将来の版で読めなくなると複数行は行ごとに動く。その場合は手順を続けず、1 つの入力にする設定を直す。Enter 自体は動く

- **Windows Terminal に複数行を貼ると「警告」が出ることがある**: 管理者ではない窓（Windows Terminal）に複数行のブロックを貼ると出るはず（コードからの推測。確かめていない）。出たら「強制的に貼り付け」を押す
  - 出さないなら、[Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)の手順 4

**[Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)のリード**

- [Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)の手順 2〜5 は `settings.json` だけを読み書きし、既定のプロファイル（Windows PowerShell）と `copyOnSelect` は変えない

**[Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)の手順 2**

- 控えは `…\LocalState\settings.json.windows-setup.bak`。控えが無いときだけ作る

- `控えた:`（2 回目からは `控えはもうある`）の行と、`Version : 1.25.…` の形の 5 行が出ればよい。`DefaultsFontFace` が空なら、既定のフォント（Cascadia Mono）

**[Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)の手順 2: 設定ファイルの読み書き**

- 場所は、Store（MSIX）版の `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`（Microsoft の文書）
- Windows Terminal は、初めて起動したときにコメントの無い `settings.json` を書く。設定の画面でリセットすると、コメント入りの `userDefaults.json` をそのまま書く（`CascadiaSettingsSerialization.cpp`）。5.1・7 の `ConvertFrom-Json` はコメントと末尾のカンマを読めないので、文字列を除いた残りにコメントか末尾のカンマがあれば、書かずに止める
- Windows Terminal は BOM の無い UTF-8 で書き、ASCII 以外の文字（訳したプロファイルの名前）も入る。BOM の無い UTF-8 のファイルを PowerShell の版によらず同じに読むため、`[IO.File]::ReadAllText` で読む
- `ConvertTo-Json` は `-Depth 100`（既定の 2 では深い入れ子が潰れる）。字下げと、`<`・`>`・`&`・`'` の書き方（`\u003c` など）が変わるが、JSON の中身は同じで、Windows Terminal が次に保存するときに整える
- `profiles` が配列なのは古い形式で、この節のブロックは扱わない
- 保存すると、Windows Terminal がファイルの変化を見て読み直し、開いているタブにも効く
- fragment（`%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments`）に書けるのは、プロファイル・配色・アクション（キーを除く）だけで、全体の設定と `profiles.defaults` は読まれない（`_parseFragment`）
- 控えは、控えが無いときだけ作る（2 回目に貼っても、元の設定が残る）

**[Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)の手順 3**

- 保存した直後に、開いているタブにも効く

**[Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)の手順 3: フォント**

- `profiles.defaults.font.face`。既定は `Cascadia Mono`（見つからなければ Consolas）、大きさは 12（WezTerm の自分用の設定も 12）
- [Windows 11 のセットアップの「表示と入力」の手順 6](windows-setup.md#表示と入力)で既定の端末にしたので、スタートメニューから開いた管理者ではない窓は Windows Terminal に渡される。Windows Terminal は、コマンド ラインが一致するプロファイル（Windows PowerShell など）を使い、無ければ `profiles.defaults` を使う（`CascadiaSettings.cpp`）。新しく作る設定の Windows PowerShell とコマンド プロンプトのプロファイルは、自分のフォントを持たない（`userDefaults.json`）ので、`profiles.defaults` が効く
- 管理者として開いた窓（conhost）のフォントは、`HKCU\Console` などの別の設定で、この節では扱わない
- hackgen.md は自分のユーザーのフォントに入れ、パッケージのアプリ向けに読み取りの権限（`S-1-15-2-1`・`S-1-15-2-2`）を足す。MSIX の Windows Terminal から見えるかは確かめていない
- 見つからないと、設定の画面に「見つからないフォント:」、端末に「次のフォントが見つかりません: …」が出る（`Resources.resw` の日本語の訳）

**[Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)の手順 4: 複数行の貼り付けの警告**

- 値は版で変わった。1.22 以前は `multiLinePasteWarning`（真偽値）、1.23 は `warning.multiLinePaste`（真偽値）、1.24 から `warning.multiLinePaste` が `automatic`・`always`・`never`（既定は `automatic`。`true` は `automatic`、`false` は `never` として読む）。古い名前も読み、新しい名前に直して書き直す。Microsoft の文書（interaction のページ）は、まだ古い名前だけを書いている
- `automatic` は、シェルが角かっこで囲む貼り付け（bracketed paste）を有効にしていないときに、改行を含む文字を貼ると警告する（`TerminalPage.cpp`）。Windows PowerShell 5.1・PowerShell 7 とも、PSReadLine はこれを有効にしないため、複数行の警告の対象になる
- 画面では「操作」→「改行を貼り付ける際に警告する」（「"角かっこで囲まれた貼り付け" がオフの場合」・「常時」・「なし」）。ダイアログの題は「警告」で、ボタンは「強制的に貼り付け」と「キャンセル」
- 出るダイアログは 1 つだけ。複数行の警告が出ないときに、5 KiB（UTF-16 で 5,120 文字）を超えると `warning.largePaste`（既定 true）の警告が出る
- 手順書では、[Windows Terminal で複数行を 1 つの入力として貼る](#windows-terminal-で複数行を-1-つの入力として貼る)の Enter の割り当て後、貼った全体を 1 つの入力として実行する。割り当て前は、Windows Terminal が改行を Enter として送り、閉じた文が続くブロックは行ごとに動く。閉じていない文（`& {` など）は、PSReadLine が行を続きとして受ける
- `trimPaste`（既定 true）は、1 行の貼り付けの末尾の空白だけを削る。貼った後に Enter が要るのは、コピーボタンの中身に末尾の改行が無いため

**[Windows Terminal で選択した文字をコピーする](#windows-terminal-で選択した文字をコピーする)のリード**

- コメントや末尾のカンマがあるファイルには書かない。控えは上書きしない（この折りたたみの「Windows Terminal で選択した文字をコピーするの手順 2: copyOnSelect と貼り付け」）

**[Windows Terminal で選択した文字をコピーする](#windows-terminal-で選択した文字をコピーする)の手順 2**

- `copyOnSelect: True` が出ればよい。開いている Windows Terminal にも効くはず（文書とソースからの推測で、実機では確かめていない）

**[Windows Terminal で選択した文字をコピーする](#windows-terminal-で選択した文字をコピーする)の手順 2: copyOnSelect と貼り付け**

- `copyOnSelect` は `settings.json` の最上位の値（[Windows Terminal の文書](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/interaction#automatically-copy-selection-to-clipboard)）
- 読み書きは親の項と同じく、コメントと末尾のカンマがあれば止め、BOM の無い UTF-8 で書く。控えの `settings.json.windows-setup.bak` は、あれば上書きしない
- ソースと文書での確認で、実機では確かめていない

**[Windows Terminal で複数行を 1 つの入力として貼る](#windows-terminal-で複数行を-1-つの入力として貼る)のリード**

- 足す行は ASCII の文字だけで、行末の印は `# shell-terminal.md:paste`。プロファイルのほかの行は変えない

- 同じプロファイルを読む窓すべてに効く（管理者の窓も）。貼った全体を先に構文解析するので、1 か所の構文エラーで全体が動かない（[この文書の補足と注意点](#この文書の補足と注意点)の「注意点」・この折りたたみの「Windows Terminal で複数行を 1 つの入力として貼るの手順 2: Enter の割り当て」）

**[Windows Terminal で複数行を 1 つの入力として貼る](#windows-terminal-で複数行を-1-つの入力として貼る)の手順 2**

- 何度貼ってもよい

**[Windows Terminal で複数行を 1 つの入力として貼る](#windows-terminal-で複数行を-1-つの入力として貼る)の手順 2: Enter の割り当て**

- 貼る窓は 7 なので、`$PROFILE` は 7 のプロファイルを指す。5.1 と 7 のパスを明示し、7 が無ければ作り、5.1 が無ければ飛ばす。足す行は ASCII だけなので、BOM の無い 5.1 のプロファイルが ANSI でも、既存のバイトは変えない
- Enter の割り当て前は、Windows Terminal が改行を Enter として送り、PSReadLine の `AcceptLine` は閉じた文を実行するため、閉じた文が続くブロックは行ごとに動く
- 右クリックは Windows Terminal が処理する。Ctrl+V も `keybindings` が `Terminal.PasteFromClipboard` に割り当てていれば、プロファイルの `Paste` まで届かない。Ctrl+V の割り当てを外す方式は右クリックに効かず、ほかのタブの Ctrl+V の貼り付けも失うため、Enter を割り当てる
- PSReadLine は bracketed paste を有効にしない（[PSReadLine の issue #1471](https://github.com/PowerShell/PSReadLine/issues/1471)）。2.4.5 に上げてもこの問題は直らない。そのため、Enter の割り当てで貼った全体を 1 つの入力にする。Ctrl+Enter の `AddLine` は conhost の LF 向けで、Windows Terminal では効かない
- `ReadOneOrMoreKeys` が読めるキーを内部の `_queuedKeys` へ先に移すため、`KeyAvailable` だけでは足りない。static の `_singleton` から instance の `_queuedKeys` も読む。入力の切れ目で実行しないよう、約 30 ms まで待つ（Enter を打ったときも、この分だけ遅れる）
- 内部の名前は非公開で、版で変わることがある。読めなければ `KeyAvailable` だけの判定になり、貼り付けは行ごとの実行に戻る。Enter 自体は動くが、貼った全体が 1 つの入力になる前提を満たさないので、以降の手順を続けず、割り当てを直す
- 制限言語モード（Constrained Language）の窓では割り当てない。割り当てると、この行のメソッドの呼び出しが禁じられ、Enter でコマンドが動かなくなるため。この窓の貼り付けは行ごとのままで、貼った全体が 1 つの入力になる前提を満たさない
- 印を `# shell-terminal.md:paste` にして、Emacs モードと 5.1 のキー操作の再実行時の削除対象から外す。`EditMode` は前のキーの割り当てを既定に戻すため、末尾に足す。Emacs の手順は最初のキーの割り当てより前へ入れるので、後から通しても順序は保たれる
- 実機の動きと範囲は検証記録を参照する
- ほかの手順書の PowerShell のブロックは、この割り当てを前提に書く。割り当てがあると、`Read-Host`・`choice.exe` の問いの後ろの文は答えとして読まれず、答えた後に動く。子の PowerShell の後ろの文は、閉じた後に元の窓で動く。Ctrl+C で外部コマンドを止めると、同じ入力の後ろの文も動かない（検証記録の付録: `docs/verification/shell-terminal.md` の「付録: ブラケットペーストで貼ったときの対話と sudo（2026-11-07）」）

**選択した方針**

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| 書く場所 | `settings.json`（コメントがあれば止める） | fragment: 全体の設定と `profiles.defaults` を読まない |
| フォント | `profiles.defaults`（全プロファイル） | プロファイルごと（fragment の `updates`）: 一致するプロファイルの無い窓に効かない |
| 複数行の警告 | 既定（`automatic`）。切るのは条件付き（[Windows Terminal のフォントと貼り付けの警告を変える](#windows-terminal-のフォントと貼り付けの警告を変える)の手順 4） | 無条件に `never`: 信用できない複数行も、確かめずに動く |
| 既定のプロファイル | Windows PowerShell のまま | この項では変えない。手順書は各項で指定した窓やタブを開く（[PowerShell 7 のプロファイルを設定する の補足と注意点](#powershell-7-のプロファイルを設定する-の補足と注意点)の「選択した方針」） |
| `copyOnSelect` | 既定（false）のまま。任意の手順で true にできる | true: 選ぶとクリップボードが置き換わり、右クリックが貼り付けになる。複数行の警告を切っている窓では、意図しない貼り付け（実行）になりやすい |
| 起動の大きさ | 既定（120×30）のまま | 好みなので扱わない |
| 管理者の窓（conhost）のフォント | 扱わない | 別の設定（`HKCU\Console`・ショートカットごと） |

**参照**

- 検証記録（`docs/verification/shell-terminal.md`）

</details>

---

### Windows 11 で WezTerm を入れる

- WezTerm nightly と、必要な Visual C++ ランタイムを PC 全体に入れる
- 前提: [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/)が使え、Microsoft Store のアプリの更新を済ませてある
- 実行場所: この PC のデスクトップの管理者の PowerShell 7。この項の手順 1 で開く

1. 管理者の PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、右クリックして「管理者として実行」を選ぶ（「Windows PowerShell」ではない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる
   - ユーザーアカウント制御（UAC）の確認は「はい」

1. 管理者であることと、今の WezTerm と `VCRUNTIME140.dll` があるかを確かめる。

   ```powershell
   # WezTerm の登録情報を取得する
   $u = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1' -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     Admin     = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Version   = $u.DisplayVersion
     Location  = $u.InstallLocation
     OnPath    = (Get-Command wezterm.exe -All -ErrorAction SilentlyContinue).Source -join ' '
     Running   = (Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue).ProcessName -join ' '
     VCRuntime = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
   } | Format-List
   ```

   - `Admin : True` であること（`False` なら、この項の手順 1 で管理者の窓を開き直してから、このブロックを貼る）
   - `Version` に版が出ていても、この項の手順 4 で今の nightly に上書きする
     - `Location` が `C:\Program Files\WezTerm\` と違う場所なら中断し、既存の導入元と設定を確かめる
   - `OnPath` に `C:\Program Files\WezTerm\wezterm.exe` 以外（scoop の `shims` など）が出たら、ほかの方法で入れた WezTerm がある。中断し、既存の導入元と設定を確かめる
   - `Running` に名前が出たら、その WezTerm の窓を閉じる
   - `VCRuntime : True` なら、この項の手順 3 は飛ばす。`False` なら、この項の手順 3 で入れる
   - 初めて入れる PC では、`Version`・`Location`・`OnPath`・`Running` が空

1. `VCRUNTIME140.dll` が無いときだけ、Visual C++ の再頒布可能パッケージを入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget install --exact --id Microsoft.VCRedist.2015+.x64 --source winget --scope machine --accept-source-agreements --accept-package-agreements
   Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と、`True` が出ればよい
   - 最後が `True` ならこの項の手順 4へ進む
   - 最後の行が `False` なら、Windows を再起動してデスクトップにサインインし、この項の手順 1 から行う
   - `winget` が見つからないというエラーになったら、Microsoft Store で「アプリ インストーラー」を更新してから始める

1. nightly のインストーラを取り、sha256 を確かめて、黙って入れる。

   ```powershell
   & {
     # 導入先と取得先を設定し、実行条件を確かめる
     $dir = 'C:\Program Files\WezTerm'
     $curl = "$env:WINDIR\System32\curl.exe"
     $url = 'https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-nightly-setup.exe'
     $tmp = "$env:TEMP\wezterm-setup"
     $setup = "$tmp\WezTerm-nightly-setup.exe"
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない'; return }
     if (-not (Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll")) { Write-Error '中断: VCRUNTIME140.dll が無い（この項の手順 3）'; return }
     if (Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue) { Write-Error '中断: WezTerm が動いている（窓をすべて閉じる）'; return }
     # 配布物を取得し、ハッシュ値を照合する
     Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & $curl -fsSL -o "$setup.sha256" "$url.sha256"
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: WezTerm-nightly-setup.exe.sha256 を取れない'; return }
     & $curl -fsSL -o $setup $url
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: WezTerm-nightly-setup.exe を取れない'; return }
     $m = Select-String -LiteralPath "$setup.sha256" -Pattern '^([0-9a-f]{64})  WezTerm-nightly-setup\.exe$' | Select-Object -First 1
     if (-not $m) { Write-Error '中断: WezTerm-nightly-setup.exe.sha256 に sha256 の行が無い'; return }
     if ((Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash -ne $m.Matches[0].Groups[1].Value) { Write-Error '中断: WezTerm-nightly-setup.exe の sha256 が一致しない'; return }
     # WezTerm を導入し、一時ファイルを削除する
     $p = Start-Process -FilePath $setup -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCLOSEAPPLICATIONS /LOG=`"$tmp\setup.log`"" -Wait -PassThru
     if ($p.ExitCode -ne 0) { Write-Error "中断: インストーラが終了コード $($p.ExitCode) で終わった（ログは $tmp\setup.log）"; return }
     Remove-Item -LiteralPath $tmp -Recurse -Force
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0'
     & "$dir\wezterm.exe" --version
   }
   ```

   - `sha256 一致、インストーラの終了コード 0` と、wezterm の版が出ればよい
   - sha256 で分かるのは壊れていないことまでで、署名が無いため本物かどうかは確かめられない
   - 終わってプロンプトが戻るまで待つ
   - `中断:` で始まるエラーが出たら、そこで止まっている
   - `取れない` と `sha256 が一致しない` は、nightly が入れ替わる最中に取ったときにも出る。少し待って貼り直す
   - インストーラの画面は出ない。終わるまでプロンプトが戻らない

1. 入ったものと、`PATH`・スタートメニューを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # WezTerm の登録情報と版を確かめる
   Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1' | Format-List DisplayName, DisplayVersion, InstallLocation, UninstallString
   & 'C:\Program Files\WezTerm\wezterm.exe' --version
   # PATH とスタートメニューへの登録を確かめる
   [Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';' | Where-Object { $_ -like '*\WezTerm*' }
   Test-Path -LiteralPath "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\WezTerm.lnk"
   # 導入先のファイルを確かめる
   Get-ChildItem -LiteralPath 'C:\Program Files\WezTerm' -Name
   ```

   - `DisplayVersion` と `wezterm --version` の版が同じならよい
   - PC 全体の `PATH` に `C:\Program Files\WezTerm` が 1 行と、スタートメニューの `True` が出る
   - 開いていた PowerShell の `PATH` には入らない。新しく開いた窓（WezTerm の中も）では、`wezterm` を名前で呼べる
   - 最後に `wezterm.exe`・`wezterm-gui.exe`・`unins000.exe` などのファイルの名前が並ぶ

1. スタートメニューから WezTerm を起動し、窓が開くことを確かめる。

   - スタートメニューで「WezTerm」を探し、クリックして開く
   - 窓が開き、中でシェルが動けばよい。設定ファイルが無ければ `cmd.exe` が開く（自分用の設定では Git Bash。[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 7 で入れる）
   - 窓の中で `wezterm --version` を打つと、この項の手順 5 と同じ版が出る
   - キー操作だけ動かない場合は、[ホットキーを使用しているアプリの調査](windows-setup.md#windows-のホットキー競合)で対象キーを調べる
   - 窓が開かずに終わったら、`%USERPROFILE%\.local\share\wezterm\wezterm-gui.exe-log-<番号>.txt` を見る
     - `The OpenGL implementation is too old to work with glium` なら、3D の描画の無い VM などで OpenGL が使えない
     - その場で開くなら、Win+R の「ファイル名を指定して実行」に `"C:\Program Files\WezTerm\wezterm-gui.exe" --config prefer_egl=true` を入れて開く（管理者の窓からは起動しない）
     - いつも開くようにするなら、設定の `config` に `config.prefer_egl = true` を足す。設定ファイルが無ければ、`%USERPROFILE%\.wezterm.lua` に `local wezterm = require 'wezterm'`・`local config = wezterm.config_builder()`・`config.prefer_egl = true`・`return config` の 4 行を書く
     - 自分用の設定（`~/.config/wezterm`）を使うなら、`~/.wezterm.lua` は作らない（[WezTerm の設定ファイル](#wezterm-の設定ファイル)のとおり、clone した設定が読まれなくなる）
   - **注意**: 管理者の PowerShell から `wezterm-gui.exe` を起動しない（WezTerm と中のシェルが管理者で動く）

<details id="windows-11-で-wezterm-を入れる-の補足と注意点">
  <summary>Windows 11 で WezTerm を入れる の補足と注意点</summary>

**注意点**

- ブラウザで取得したファイルでは SmartScreen が警告することがある。本書では `curl.exe` で取得する

- **WezTerm: Windows 11 の WezTerm には `VCRUNTIME140.dll` が要る**: インストーラは入れない（[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 3）

- **WezTerm: Windows 11 の nightly は自分では上がらず、winget・scoop の管理にも乗らない**: 上げるのは[Git for Windows・Firefox・WezTerm を上げる](windows-setup.md#git-for-windowsfirefoxwezterm-を上げる)

- **WezTerm: Windows 11 では、stable と nightly が同じ登録を使う**: インストーラの `AppId` が同じなので、PC に入るのはどちらか 1 つ。後から入れた方が上書きするはず

**[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 1: WezTerm の中の PowerShell を使わない理由**

- 検証記録（`docs/verification/windows-setup.md`）

- WezTerm が動いていると、[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 4 が止まる

**[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 2**

- `Version` に版が出たら、もう入っている（`20260905-153129-092dcf70` など）。[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 4 で今の nightly に上書きする

**[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 2: 確かめる値の意味**

- `Version` が `20240203-110809-5046fc22` なら stable（winget の `wez.wezterm` など）。同じ登録なので、nightly で上書きされる
- ほかの方法で入れた WezTerm を外すのは、混ざらないようにするため

**[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 4**

- 何度貼ってもよい

- `WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0` と、`wezterm 20260929-043349-cab25161` の形の 1 行が出ればよい

**[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 4: 版と、中断・貼り直し**

- 最後に出る `wezterm <版>` の版は、実行した日の nightly
- `中断:` で止まったとき、取ってきたものとログは `%TEMP%\wezterm-setup` に残る。次に貼ったときに消して作り直す
- 何度貼ってもよいのは、同じ場所に上書きするため

**[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 4: 更新するときに窓を閉じる理由**

- [Git for Windows・Firefox・WezTerm を上げる](windows-setup.md#git-for-windowsfirefoxwezterm-を上げる)の手順 5 で WezTerm を閉じる。動いていると、同じ更新の手順 6（[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 4 のブロック）が止まる

**[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 5**

- `UninstallString` は `"C:\Program Files\WezTerm\unins000.exe"`

- `DisplayVersion` と `wezterm --version` の版が同じ（`20260929-043349-cab25161` の形）

**[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 6: 右クリックのメニュー**

- エクスプローラーでフォルダーを右クリックすると「Open WezTerm here」がある（Windows 11 の新しいメニューでは「その他のオプションを確認」の中）

**選択した方針**

- **Windows 11 では、インストーラを直接取って、`.sha256` と比べてから黙って動かす方式を採用した**
  - winget の定義の sha256 も、同じリリースのファイルから bot が取ったもの
  - winget の `wez.wezterm.nightly` は、入れられる日なら 1 行で済み `VCRUNTIME140.dll` の依存も入るが、入るかどうかが日によるので採らなかった。依存の再頒布可能パッケージだけは winget で入れる（[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 3）

**参照**

- 検証記録（`docs/verification/shell-terminal.md`）

</details>

---

### Git Bash と WezTerm の設定

- Git の共通設定・共通の bash 設定と、自分用の WezTerm の設定を入れる
- 前提: [Git for Windows](https://gitforwindows.org/)・[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)を通してある。導入後に Windows を再起動するか、サインアウトしてサインインし直し、PATH を読み直してある。GitHub のアカウントがある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。この項の手順 3 からは Git Bash の窓、最後は WezTerm の Git Bash のタブ

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. Git for Windows の git の場所と版と、Git Bash があることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # git の場所と版を確かめる
   Get-Command git -All | Format-Table Source
   git --version
   # Git Bash の実行ファイルを確かめる
   Test-Path 'C:\Program Files\Git\bin\bash.exe', 'C:\Program Files\Git\git-bash.exe'
   ```

   - 1 行目の一番上に `C:\Program Files\Git\cmd\git.exe` が出ればよい
   - git の版と、`True` が 2 行出ればよい

1. スタートメニューから Git Bash を開く。

   - スタートメニューで「Git Bash」を探して開く（管理者でなくてよい）
   - `<WIN_USER>@<HOSTNAME> UCRT64 ~` のような行と、`$` のプロンプトの窓が開く（Git for Windows 2.55 までは `MINGW64`）
   - Git Bash の窓に貼るときは、窓の中を右クリックして出るメニューの「Paste」を選ぶ。最後の行は、貼った後に Enter を押す
   - **次の手順は、この Git Bash に貼る**

1. Git Bash に、[AlmaLinux 10 の初期設定の「Git」](almalinux-setup.md#git)の手順 1〜10 を上から順に貼る。

   - `~/.gitconfig`（`C:\Users\<WIN_USER>\.gitconfig`）に、AlmaLinux 10 と同じ基本の設定を書く。成功の条件は、同書のそれぞれの手順と同じ
   - 同書の「Git」の手順 2 では、インストーラが書いた `system` の行（`core.autocrlf=true` など）も出る
   - **この手順は、この項の手順 6・7 の clone より前に行う**（`global` の `core.autocrlf=false` が無いと、clone したファイルの改行が `system` の `core.autocrlf=true` で CRLF になる）
   - Git Bash・PowerShell・cmd の git は、同じ `~/.gitconfig` を読む

1. 同じ Git Bash で、元の設定を表示し、Git for Windows の長いパス対応を有効にする。

   ```bash
   # 長いパス対応の現在の設定を表示する
   printf '変更前の core.longpaths（スコープ・ファイル・値）:\n'
   git config --show-scope --show-origin --get-all core.longpaths
   # 長いパスへの対応を有効にする
   if [ "$(git config --global --includes --type=bool --get core.longpaths)" != true ]; then
     git config --global core.longpaths true
   fi
   printf '\n\033[7m 確認 \033[0m\n'
   git config --global --includes --type=bool --get core.longpaths
   git config --type=bool --show-scope --show-origin --get core.longpaths
   ```

   - 「変更前」の値・スコープ・ファイルを控える。include 先も `global` の行に出る。`global` が無ければ「未設定」と控える
   - 最後の `global` の値が `true`（`yes`・`on`・`1` も同じ）なら「変更なし」、それ以外は今回変更したことも控える。変更しなかったキーは復元で触らない
   - 「確認」の後に `true` と、`global` の `true` の行が出ればよい。違う値やエラーが出たら、ここで止めて設定を確かめる
   - 対象のリポジトリで `git config --show-scope --show-origin --get core.longpaths` を確かめ、`local` の `false` が出たら、そのリポジトリの設定を見直す
   - **注意**: エクスプローラー・IDE・スクリプトなどで長いパスを扱えない場合は、リポジトリを短いパスに置く

1. 同じ Git Bash で、共通の bash 設定を入れる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   git clone https://github.com/ryo-aoki-pc/bash.git ~/.config/bash &&
     bash ~/.config/bash/install.sh
   ```

   - `~/.bashrc: 設定済み（元の内容: ~/.bashrc.before-bash）` と `完了: 端末を開き直す。…` が出ればよい
   - すでに clone してあるなら `fatal: destination path … already exists` で止まる。そのときは `git -C ~/.config/bash pull --ff-only` で更新し、`bash ~/.config/bash/install.sh` を貼る
   - Git for Windows が作る `~/.bash_profile` と、共通設定の導入時に既存ファイルを残す扱いは、[Git Bash と WezTerm の設定 の補足と注意点](#git-bash-と-wezterm-の設定-の補足と注意点)の「Git Bash と WezTerm の設定の手順 6: ログインシェルの読み込み」で確かめる

1. 自分用の WezTerm の設定（[ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)）を入れ、WezTerm を起動し直す。

   - [Windows 11 で WezTerm の設定を導入する](#windows-11-で-wezterm-の設定を導入する)を通す。前提の共通の bash 設定は、この項の手順 6 で導入済み
   - その項の手順 6 で WezTerm を起動し直し、同じ項の手順 7 を新しい Git Bash のタブに貼って確かめる
   - Git Bash の窓は閉じてよい
   - CRLF に変換して clone 済みのリポジトリは、WezTerm の Git Bash のタブで[改行を変換して clone したリポジトリを直す](almalinux-setup.md#改行を変換して-clone-したリポジトリを直す)を通す

#### Windows 11 で共通の bash 設定を更新する

- 共通の bash 設定のリポジトリを更新し、端末を開き直して反映する
- 前提: [Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある
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

#### Windows 11 で WezTerm の設定を導入する

- 自分用の WezTerm の設定を入れ、シェル統合を確かめる
- 前提: [Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)と[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 1〜6 を通し、Git と共通の bash 設定を入れてある。HackGen Console NF は任意
- 実行場所: この項の手順 1〜5 は、WezTerm の外の、自分のユーザーの Git Bash の窓。この項の手順 6・7 は、起動し直した WezTerm の Git Bash のタブ
- この項の手順 1 で WezTerm の窓をすべて閉じる。既存設定の確認と、この項の手順 3 の退避を省かない

1. WezTerm の窓をすべて閉じ、スタートメニューから Git Bash を開く。

   - スタートメニューで「Git Bash」を探して開く（管理者として実行しない）
   - `UCRT64` と `$` のプロンプトが出ればよい（Git for Windows 2.55 までは `MINGW64`）
   - **次の手順は、この Git Bash の窓に貼る**

1. 既存の WezTerm の設定があるか確かめる。

   ```bash
   ls -ld ~/.wezterm.lua ~/.config/wezterm
   ```

   - どちらかが出たら、この項の手順 3 で退避する
   - 2 行とも `No such file or directory` なら、設定は無い。この項の手順 3 は飛ばす
   - `~/.wezterm.lua` が残っていると、この設定は読まれない

1. 既存の設定があるときだけ、名前の後ろに `.bak` を付けて退避する。

   ```bash
   # 退避先に既存の控えがないか確かめる
   (
     for f in ~/.wezterm.lua ~/.config/wezterm; do
       if [ -e "$f.bak" ] || [ -L "$f.bak" ]; then
         echo "中断: $f.bak が既にある。何も退避していない" >&2
         exit 1
       fi
     done
     # 既存の WezTerm 設定を退避する
     for f in ~/.wezterm.lua ~/.config/wezterm; do
       if [ -e "$f" ] || [ -L "$f" ]; then mv -v "$f" "$f.bak" || exit 1; fi
     done
     ls -ld ~/.wezterm.lua ~/.config/wezterm
   )
   ```

   - 最後の `ls` が 2 行とも `No such file or directory` ならよい
   - `.bak` が 1 つでもあれば、どちらも動かさず `中断:` で止まる。この項の手順 4 へ進まず、中身を確かめて片付けてからこの項の手順 3 を貼り直す

1. この設定を `~/.config/wezterm` に clone する。

   ```bash
   # WezTerm の設定を取得する
   git clone https://github.com/ryo-aoki-pc/wezterm.git ~/.config/wezterm
   printf '\n\033[7m 確認 \033[0m\n'
   git -C ~/.config/wezterm log -1 --oneline
   ```

   - `fatal: destination path '/home/<USER>/.config/wezterm' already exists and is not an empty directory.` と出たら、この項の手順 2 から見直す
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
   - **次の手順は、起動し直した WezTerm のタブで貼る**（開いていたタブで貼ると、この項の手順 7 の確かめが外れる）

1. 起動し直した WezTerm のタブで、シェル統合が読まれたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   echo "$TERM_PROGRAM"
   echo "$WEZTERM_SHELL_INTEGRATION"
   declare -F __wezterm_set_user_var __wezterm_notify_done __wz_mouse_off
   ```

   - 1 行目は `WezTerm`、2 行目は `.config/wezterm/shell/wezterm.sh` で終わるパス
   - 3 つ目は、WezTerm のパッケージの公式のシェル統合があるかどうかで変わる
     - AlmaLinux 10（COPR の公式統合）: `__wezterm_set_user_var`・`__wezterm_notify_done`・`__wz_mouse_off` の 3 行
     - 公式の統合が無いとき（Windows の Git Bash など）: `__wezterm_notify_done` と `__wz_mouse_off` の 2 行
   - 1 行目が空なら、WezTerm の外で貼っている。2 行目が空なら、この項の手順 6 の前から開いていたタブで貼っている
   - `__wz_mouse_off` が出なければ、`~/.bashrc` の行が読まれていない。共通の bash 設定を見直す

#### WezTerm のシェル統合を WSL で使う

- WSL の bash で Windows 側の WezTerm のシェル統合を読む
- 前提: [Windows 11 で WezTerm の設定を導入する](#windows-11-で-wezterm-の設定を導入する)・[WSL の AlmaLinux 10](https://wiki.almalinux.org/documentation/wsl.html)と、WSL 側の[共通の bash 設定](#共通の-bash-設定)を通してある
- 実行場所: この PC のデスクトップの WezTerm の WSL の bash のタブ。この項の手順 1 で開く
- WSL の `~/.bashrc` の既存の変更を確かめ、Windows 側の統合を共通の bash 設定の読み込み行より後ろで読む

1. スタートメニューから WezTerm を開き、WSL のタブを用意する。

   - WezTerm の Ctrl+Shift+M の起動メニューで「AlmaLinux-10」を選ぶ
   - WSL の自分のユーザーの bash のプロンプトが出ればよい
   - **次の手順は、この WSL のタブに貼る**

1. WSL のシェルで、Windows のホームを調べ、シェル統合のスクリプトが見えるか確かめる。

   ```bash
   # Windows のホームディレクトリを取得する
   WIN_HOME=$(wslpath "$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' | tr -d '\r')")
   printf '\n\033[7m 確認 \033[0m\n'
   ls -l "$WIN_HOME/.config/wezterm/shell/wezterm.sh"
   ```

   - Windows 側の `wezterm/shell/wezterm.sh` のパスが出ればよい
   - `No such file or directory` なら、Windows 側の[Windows 11 で WezTerm の設定を導入する](#windows-11-で-wezterm-の設定を導入する)を先に済ませる

1. この項の手順 2 と同じシェルで、WSL の `~/.bashrc` に読み込む行を足す。

   ```bash
   # Windows のシェル統合を読む設定を追加する
   if [ -z "${WIN_HOME}" ]; then echo '中断: この項の手順 2 の WIN_HOME が空のまま' >&2; else
     echo "[ -r '$WIN_HOME/.config/wezterm/shell/wezterm.sh' ] && . '$WIN_HOME/.config/wezterm/shell/wezterm.sh'" >> ~/.bashrc
     printf '\n\033[7m 確認 \033[0m\n'
     tail -1 ~/.bashrc
   fi
   ```

   - Windows 側のシェル統合のパスを読む行が出ればよい

1. WezTerm の起動メニューから、WSL のタブを開き直す。

   - `Ctrl+Shift+M` の起動メニューで、WSL のディストリビューションを選ぶ
   - **次の手順は、開き直した WSL のタブで貼る**

1. 開き直した WSL のタブで、シェル統合が読まれたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   echo "$TERM_PROGRAM"
   declare -F __wezterm_set_user_var __wezterm_notify_done __wz_mouse_off
   ```

   - `TERM_PROGRAM` が `WezTerm`、`__wezterm_notify_done` と `__wz_mouse_off` が出ればよい。WSL に COPR の公式統合があれば `__wezterm_set_user_var` も出る

#### Windows 11 で WezTerm の設定を更新する

- WezTerm の設定のリポジトリを更新する
- 前提: [Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある
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

#### Windows 11 で bash のログイン時の読み込みを確かめる

- 任意で、Git Bash のログインシェルが読むファイルが `~/.bashrc` を読むことを確かめ、読む行が無いときだけ足す
- 前提: [Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通してある
- 実行場所: この PC のデスクトップの、自分のユーザーの WezTerm の Git Bash のタブ。この項の手順 1 で開く
- この項では、ログイン用のファイルを新しく作らない

1. スタートメニューから WezTerm を開き、Git Bash の新しいタブを用意する。

   - スタートメニューで「WezTerm」を探して開く（管理者として実行しない）。開いていれば Ctrl+Shift+T で新しいタブを開く
   - タブの起動メニューで Git Bash を選ぶ（自分用の設定では既定で開く）
   - **次の手順は、この Git Bash のタブに貼る**

1. ログインシェルが読むファイルの名前と構文と、`~/.bashrc` を読む行を確かめる。

   ```bash
   # ログイン用の設定ファイルを探す
   (
     f=
     for x in ~/.bash_profile ~/.bash_login ~/.profile; do
       if [ -f "$x" ]; then f=$x; break; fi
     done
     printf '\n\033[7m 確認 \033[0m\n'
     if [ -z "$f" ]; then echo '中断: ~/.bash_profile・~/.bash_login・~/.profile のどれも無い' >&2; exit 1; fi
     echo "$f"
     bash -n "$f" && grep -n '\.bashrc' "$f"
   )
   ```

   - ファイル名と、構文エラーが無くコメントでもない `~/.bashrc` の読み込み行が出ればよい。この項の手順 3 は飛ばす
   - 読む行が無いときだけ、この項の手順 3 を行う
   - `中断:` が出たら、[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 6 のブロックを貼り直す（共通の bash 設定の `install.sh` が、`~/.bashrc` を読む `~/.bash_profile` を作る）。構文エラーが出たら、この項の手順 3 へ進まない

1. この項の手順 2 で読む行が無かったときだけ、そのファイルの末尾に 1 行足す。

   ```bash
   # ログイン用の設定ファイルと構文を確かめる
   (
     f=
     for x in ~/.bash_profile ~/.bash_login ~/.profile; do
       if [ -f "$x" ]; then f=$x; break; fi
     done
     if [ -z "$f" ]; then echo '中断: ~/.bash_profile・~/.bash_login・~/.profile のどれも無い。ファイルは作らない' >&2; exit 1; fi
     bash -n "$f" || exit 1
     # bashrc を読み込む行を追加する
     line='test -f ~/.bashrc && . ~/.bashrc  # shell-terminal.md'
     if ! grep -Fqx "$line" "$f"; then
       if [ -s "$f" ] && [ -n "$(tail -c 1 "$f")" ]; then printf '\n' >> "$f" || exit 1; fi
       printf '%s\n' "$line" >> "$f" || exit 1
     fi
     printf '\n\033[7m 確認 \033[0m\n'
     echo "$f"
     grep -Fnx "$line" "$f"
   )
   ```

   - ファイル名と、追加した `~/.bashrc` の読み込み行が 1 つ出ればよい
   - 足したのが `~/.profile` なら、その行は sh のログインシェルにも読まれる（共通の bash 設定は bash 向け）。Git Bash のほかに sh でログインしないなら問題にならない
   - 新しい Git Bash のタブを開き、[Windows 11 で WezTerm の設定を導入する](#windows-11-で-wezterm-の設定を導入する)の手順 7 で読み込みを確かめる

<details id="git-bash-と-wezterm-の設定-の補足と注意点">
  <summary>Git Bash と WezTerm の設定 の補足と注意点</summary>

**[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 2**

- `git version 2.56.0.windows.4` の形の行と、`True` が 2 行出ればよい

**[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 2: PATH と、ほかの git**

- `PATH` に足されるのは `C:\Program Files\Git\cmd`（`git.exe`・`git-gui.exe` など）だけ。`bash`・`ssh`・`ls` などは足されないので、PowerShell の `ssh` は Windows のものが使われる
- Windows の `PATH` は、PC 全体の値の後ろに自分のユーザーの値が続く。scoop の git（`…\scoop\shims\git.exe`。自分のユーザーの `PATH`）があっても、新しく開いた窓では Git for Windows の `git` が先に見つかる
- scoop は、scoop の git が入っていなければ `PATH` の `git` を使う（scoop のソースの `Get-HelperPath`）。そのため、`scoop update` と `scoop bucket add` は Git for Windows の `git` で動く。scoop の git が入っていると、scoop はそちらを使う

**[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 2: 版**

- `git version` の版は、実行した日の最新

**[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 4: Windows の system の行**

- Windows で出る `system` の行（インストーラが書いたもの）より、[Git](almalinux-setup.md#git)の手順 4・5 で書く `global` の値が優先される

**[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 5: Git for Windows の長いパス対応**

- `core.longpaths=true` は Git for Windows の C で実装されたコマンドの長いパス対応を有効にする。初期設定の clone より前に、自分のユーザーの `global` に設定する
- Windows 側の `LongPathsEnabled=1` とは別の設定。Windows の一般的な長いパス対応には、OS 側の値に加えてアプリ側の対応も必要
- Git for Windows の公式資料は、スクリプトで実装された Git のコマンドや、エクスプローラー・IDE などには制限が残ると説明している。この設定だけで周辺ツールも長いパスを扱えるとは限らない
- リポジトリの `local` は `global` より優先される。ホームでの設定確認に加え、既存のリポジトリでは有効な値と出どころを確かめる
- `--global --includes` で、`global` のファイルが読み込む別の設定も含めて判定する。真偽値がすでに `true` なら書き換えず、元の表記と設定ファイルを保つ
- [Git for Windows: Git cannot create a file or directory with a long path](https://gitforwindows.org/git-cannot-create-a-file-or-directory-with-a-long-path.html)
- [Microsoft Learn: Maximum Path Length Limitation](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation)

**[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 6**

- [README の「共通の bash 設定を先に入れる」](../README.md#共通の-bash-設定を先に入れる)と、[共通の bash 設定](#共通の-bash-設定)の手順 1 と同じブロック

- 自分用の WezTerm は Git Bash を `-i -l`（ログインシェル）で開き、ログイン用のファイル（ふつうは `~/.bash_profile`）→ `~/.bashrc` → 共通の bash 設定の順に読む。読み込みを確かめるときは、[Windows 11 で bash のログイン時の読み込みを確かめる](#windows-11-で-bash-のログイン時の読み込みを確かめる)を通す

**[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 6: ログインシェルの読み込み**

- 自分用の WezTerm の設定は、Git Bash を `-i -l`（対話・ログインシェル）で開く。ログインシェルの bash は、`~/.bash_profile`・`~/.bash_login`・`~/.profile` のうち最初にあるものだけを読む（bash の man の INVOCATION）。そのファイルが `~/.bashrc` を読み、その `~/.bashrc` が共通の bash 設定を読む
- Git for Windows の [`bash_profile.sh`](https://github.com/git-for-windows/build-extra/blob/main/git-extra/bash_profile.sh) は、最初のログイン時に `~/.bash_profile` を作る
  - 条件は、`~/.bashrc` があり、`~/.bash_profile`・`~/.bash_login`・`~/.profile` がどれも無いこと
  - 生成する内容は `# generated by Git for Windows` と、`~/.profile`・`~/.bashrc` があれば読む行。`~/.bash_profile` が無いという条件だけでは生成されない
- 共通の bash 設定の `install.sh`（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）は、`~/.bash_profile`・`~/.bash_login`・`~/.profile` のどれも無ければ、`~/.bashrc` を読む `~/.bash_profile` を作る（`~/.bash_profile: 作成済み`）。どれかがあれば書き換えず、`~/<ファイル>: 既存の内容を維持。ログインシェルから ~/.bashrc を読むことを確認する` と出す（その確かめが、[Windows 11 で bash のログイン時の読み込みを確かめる](#windows-11-で-bash-のログイン時の読み込みを確かめる)）
- [Windows 11 で bash のログイン時の読み込みを確かめる](#windows-11-で-bash-のログイン時の読み込みを確かめる)は、既存のファイルを確かめ、読む行が無い場合だけ追記する。実機では確かめていない

**[Windows 11 で共通の bash 設定を更新する](#windows-11-で共通の-bash-設定を更新する)の手順 2**

- `set-url` は、HTTPS で clone したホストでは何も変えない。SSH で clone したホストを HTTPS にそろえる

**[Windows 11 で WezTerm の設定を導入する](#windows-11-で-wezterm-の設定を導入する)の手順 3**

- あったものだけ、`renamed '/home/<USER>/.config/wezterm' -> '/home/<USER>/.config/wezterm.bak'` のように出る

**[WezTerm のシェル統合を WSL で使う](#wezterm-のシェル統合を-wsl-で使う)の手順 2**

- `/mnt/c/Users/<WIN_USER>/.config/wezterm/shell/wezterm.sh` の 1 行が出ればよい

**[WezTerm のシェル統合を WSL で使う](#wezterm-のシェル統合を-wsl-で使う)の手順 3**

- WSL の `$HOME` は Linux 側なので、Windows 側の統合をこのパスで読む

- `/mnt/c/Users/<WIN_USER>/.config/wezterm/shell/wezterm.sh` を 2 回含む 1 行が出る

**[Windows 11 で bash のログイン時の読み込みを確かめる](#windows-11-で-bash-のログイン時の読み込みを確かめる)のリード**

- 自分用の WezTerm の設定は Git Bash を `-i -l`（ログインシェル）で開く。bash は `~/.bash_profile`・`~/.bash_login`・`~/.profile` のうち最初にあるものだけを読み、そこから `~/.bashrc` → 共通の bash 設定を読む（この折りたたみの「Git Bash と WezTerm の設定の手順 6: ログインシェルの読み込み」）

**[Windows 11 で bash のログイン時の読み込みを確かめる](#windows-11-で-bash-のログイン時の読み込みを確かめる)の手順 2**

- 1 行目にファイルの名前（ふつうは `/c/Users/<WIN_USER>/.bash_profile`）が出て、構文エラーが無く、コメントでない `test -f ~/.bashrc && . ~/.bashrc` などの読む行が出ればよい。[Windows 11 で bash のログイン時の読み込みを確かめる](#windows-11-で-bash-のログイン時の読み込みを確かめる)の手順 3 は飛ばす

**[Windows 11 で bash のログイン時の読み込みを確かめる](#windows-11-で-bash-のログイン時の読み込みを確かめる)の手順 3**

- ファイルの名前と、`test -f ~/.bashrc && . ~/.bashrc  # shell-terminal.md` の行が 1 つ出ればよい。ファイルは置き換えず、同じ行は増やさない

**[Windows 11 で bash のログイン時の読み込みを確かめる](#windows-11-で-bash-のログイン時の読み込みを確かめる)の手順 3: 既存のファイルを残す**

- ファイル全体は置き換えない。`~/.profile` を読む行など、Git for Windows が作った内容や利用者が足した内容を残す

**参照**

- 検証記録（`docs/verification/windows-setup.md`）

- 検証記録（`docs/verification/shell-terminal.md`）

- [背景説明](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/reference/install.md)・検証記録（`repos/wezterm/docs/verification/install.md`）

</details>

---

### シェルのツールを入れる

- scoop で fzf・zoxide・starship・eza・bat を入れ、Git Bash で確かめる
- 前提: [scoop の導入](https://scoop.sh/)と[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)を通し、scoop と Git・共通の bash 設定を入れてある。Visual C++ ランタイムも[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)で入れてある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。この項の手順 7・8 は WezTerm の新しい Git Bash のタブ

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 管理者ではないことと、前提と、ほかの方法で入れた同じツールが無いかを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     BashConfig = Test-Path -LiteralPath "$env:USERPROFILE\.config\bash\bashrc"
     VCRuntime  = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
     Tools      = (Get-Command fzf, zoxide, starship, eza, bat -All -ErrorAction SilentlyContinue).Source -join ', '
     Zoxide     = if (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue) { zoxide --version } else { '' }
   } | Format-List
   ```

   - `PowerShell : 7.…`・`Admin : False`・`BashConfig : True`・`VCRuntime : True` ならよい。`Admin : True` なら、窓を閉じて、この項の手順 1 のとおりに開き直す
   - `Scoop` が空なら、先に[scoop の公式の導入案内](https://scoop.sh/)に従って入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [Git for Windows](https://gitforwindows.org/)を通す
   - `BashConfig : False` なら、先に[Git Bash と WezTerm の設定](#git-bash-と-wezterm-の設定)の手順 6 を通す
   - `VCRuntime : False` なら、[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 3 を管理者の PowerShell 7 で行ってから、このブロックを貼り直す
   - `C:\Users\<WIN_USER>\scoop\` の下の `shims\<名前>.exe` と `apps\starship\current\starship.exe` だけなら、scoop で入れたもの（この項の手順 4 は、入っているものを飛ばす）
   - ほかの場所（winget の `…\WinGet\Links\` など）が出たら、ほかの方法で入れたものがある。中断し、既存の導入元と設定を確かめる
   - `Zoxide` が空か `zoxide 0.9.9` なら、この項の手順 3 は飛ばす

1. scoop の zoxide が 0.9.9 でないときだけ、外す。

   ```powershell
   scoop uninstall zoxide
   ```

   - `'zoxide' was uninstalled.` が出ればよい

1. scoop を上げてから 5 つを入れ、zoxide を 0.9.9 に止める。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # scoop の一覧を更新する
   scoop update
   # シェルのツールを導入する
   scoop install fzf starship eza bat
   # zoxide の版を指定して導入し、固定する
   scoop install zoxide@0.9.9
   scoop hold zoxide
   ```

   - `Scoop was updated successfully!` が出ればよい
   - 各ツールの `was installed successfully!` と、`zoxide is now held` が出ればよい（zoxide は `0.9.9`）
   - 入っているツールは、何も出さずに飛ばされる（`was installed successfully!` も `Skipping` も出ない）
   - `zoxide` の `is already installed.` は正常
   - `zoxide` の `is already held.` は正常
   - `Notes` の starship のプロファイル追記と、`suggests installing` の VC++ ランタイム・less の導入は行わない
   - **zoxide は 0.9.9 に固定する**。0.10.0 は Git Bash の移動を記録しない。修正版は[更新](windows-setup.md#scoopwingetwsl-を上げる)の手順 6・7、ほかのツールは同じ項の手順 2・3 で上げる
   - `scoop update` は `Scoop was updated successfully!` を出す（Git for Windows より前に scoop を入れた PC では、初めてのときに `Converting 'main' bucket to git repo...` も出る）

1. 版と場所と、zoxide を止めたことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # シェルのツールの版を確かめる
   fzf --version
   zoxide --version
   starship --version
   eza --version
   bat --version
   # 実行ファイルの場所を確かめる
   (Get-Command fzf, zoxide, starship, eza, bat -All).Source
   # zoxide の版の固定を確かめる
   scoop list zoxide
   ```

   - 各ツールの版が出ればよい（zoxide は `0.9.9`）
   - `bat --version` が何も出さないか、DLL が見つからない旨のエラーになったら、VC++ ランタイムが無い（この項の手順 2 の `VCRuntime`）
   - fzf・zoxide・eza・bat は scoop の `shims`、starship は `apps/starship/current` のパスだけが出ればよい
   - `scoop list` の zoxide が `0.9.9`、`Held package` ならよい

1. bat の設定ファイル（`BAT_CONFIG_DIR` の下の `config`）に、3 行の設定を書く（中身があれば書き換えない）。

   ```powershell
   $BAT_THEME_NAME = 'ansi'   # 使うテーマ。ansi は端末の 16 色にそのまま従う（一覧は bat --list-themes）。<BAT_THEME_NAME>
   ```

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not $BAT_THEME_NAME) { Write-Error '中断: BAT_THEME_NAME が空のまま。値を入れて貼り直す'; return }
     $f = if ($env:BAT_CONFIG_PATH) { $env:BAT_CONFIG_PATH } elseif ($env:BAT_CONFIG_DIR) { Join-Path $env:BAT_CONFIG_DIR 'config' } else { '' }
     if (-not $f) { Write-Error '中断: BAT_CONFIG_DIR が無い。この項の手順 4 で bat を入れたかを確かめる'; return }
     if ((Test-Path -LiteralPath $f) -and [IO.File]::ReadAllText($f).Trim()) { "中身がある（書き換えない）: $f" } else {
       Set-Content -LiteralPath $f -Encoding ASCII -Value "--theme=`"$BAT_THEME_NAME`"", '--style="numbers,changes,header"', '--paging=never' -ErrorAction Stop
       "書いた: $f"
     }
     Get-Content -LiteralPath $f
   }
   ```

   - `書いた:` と、指定したテーマ・表示・ページャの 3 行が出ればよい
   - `中身がある（書き換えない）:` が出たら、前からの設定（`%APPDATA%\bat\config` から scoop が写したものなど）がある。何も変えていない
   - `中断:` が出たら、何も書いていない

1. WezTerm の新しいタブ（Git Bash）で、[シェルのツール](#シェルのツール)の手順 4〜7・9・10 のブロックを貼る。

   - WezTerm を起動するか、新しいタブ（Ctrl+Shift+T）を開く。前から開いているタブで `. ~/.bashrc` を読み直さない（[シェルのツール の補足と注意点](#シェルのツール-の補足と注意点)の「シェルのツールの手順 2」と同じ）
   - 新しいタブのプロンプトが starship の形にならなければ、WezTerm の窓をすべて閉じて起動し直す
   - 成功の条件は、「シェルのツール」のそれぞれの手順と同じ。違うのは次のところ
     - `command -v` は `/c/Users/<WIN_USER>/scoop/shims/<名前>`（starship は `/c/Users/<WIN_USER>/scoop/apps/starship/current/starship`）。版は、この項の手順 5 と同じ
     - 「シェルのツール」の手順 5 の `bind -X` は、`"\C-r" "__fzf_history__"` のようにコロンの無い形で出る（Git Bash の bash 5.3）。WezTerm のシェル統合を読んでいれば、マウス報告よけの行も出る（そのままでよい）
     - 「シェルのツール」の手順 6 の見出しは、`Permissions` が `Mode` になり、`User` の列が無い。`Git` の列が出ればよい。`ll` は、Git for Windows の `ls -l` ではなく eza になる
     - 「シェルのツール」の手順 7 で `/etc/os-release` が無い旨のエラーが出たら、そのコマンドを `~/.bashrc` に変えて打つ。`MANPAGER` は `bat -plman` と出るが、Git Bash に `man` は無い
     - 「シェルのツール」の手順 9 の `cd /usr/share` は、Git for Windows の `C:\Program Files\Git\usr\share` に移る。「シェルのツール」の手順 10 の一覧には、その形（`C:\…`）で出る
   - 「シェルのツール」の手順 8（tmux）は行わない
   - `~/.bashrc` には追記しない。PowerShell には読み込まない

1. 同じタブで、[キー操作を試す](#キー操作を試す)の手順 2〜5 のキーを押して、fzf を確かめる。

   - 「キー操作を試す」の手順 2 の `fzf --version` は、この項の手順 7 で Git Bash の履歴に入っている
   - 「キー操作を試す」の手順 3 をホーム（`C:\Users\<WIN_USER>`）で行うと、`AppData` の下のファイルも一覧に入る
   - 「キー操作を試す」の手順 4 の `doc/bash` が一覧に無ければ、一覧にある別の語で絞る（`/usr/share` は Git for Windows のもの）
   - 日本語など ASCII 以外の文字では、絞り込めないことがある（Windows の fzf は、画面の一部に開いた一覧では ASCII 以外の文字を読めない）
   - [fzf で fd と bat を候補とプレビューに使う](#fzf-で-fd-と-bat-を候補とプレビューに使う)も通せる。そちらの `brew install fd` は、管理者ではない PowerShell 7 で `scoop install fd` にする。導入済みなら省く
   - bat の設定にはこの項の手順 6を使う

#### Windows 11 で starship の表示を変える

- 任意で、starship のプロンプト前の空行を省き、ディレクトリを 3 階層まで、ユーザー名とホスト名を常に表示する
- 前提: [シェルのツールを入れる](#シェルのツールを入れる)を通してある
- 実行場所: この PC のデスクトップの、自分のユーザーの WezTerm の Git Bash のタブ。この項の手順 1 で開く

> [!WARNING]
> この項の手順 2 は `starship.toml` の中身全体を、この項の 5 つの値に置き換える。既存のほかの設定は控えに残る。Git Bash と PowerShell 7 の両方のプロンプトに効き、ユーザー名・ホスト名が常に出るので画面の共有に注意する。

1. スタートメニューから WezTerm を開き、Git Bash の新しいタブを用意する。

   - スタートメニューで「WezTerm」を探して開く（管理者として実行しない）。開いていれば Ctrl+Shift+T で新しいタブを開く
   - タブの起動メニューで Git Bash を選ぶ（自分用の設定では既定で開く）
   - **次の手順は、この Git Bash のタブに貼る**

1. 既存ファイルがあれば控えを取り、Windows で共有する starship の設定を書く。

   ```bash
   # 設定ファイルと控えの状態を確かめる
   (
     if [ -n "${STARSHIP_CONFIG:-}" ]; then echo '中断: STARSHIP_CONFIG がある。標準の設定ファイルを使う状態にしてから始める' >&2; exit 1; fi
     mkdir -p ~/.config || exit 1
     for f in ~/.config/starship.toml ~/.config/starship.toml.shell-terminal.bak ~/.config/starship.toml.shell-terminal.new; do
       if [ -L "$f" ] || { [ -e "$f" ] && [ ! -f "$f" ]; }; then echo "中断: 通常のファイルではない: $f" >&2; exit 1; fi
     done
     if [ -e ~/.config/starship.toml.shell-terminal.bak ] && [ -e ~/.config/starship.toml.shell-terminal.new ]; then echo '中断: 控えと新規作成の印が両方ある' >&2; exit 1; fi
     # 既存の設定を控え、新規作成の印を残す
     if [ ! -e ~/.config/starship.toml.shell-terminal.bak ] && [ ! -e ~/.config/starship.toml.shell-terminal.new ]; then
       if [ -e ~/.config/starship.toml ]; then
         cp -p ~/.config/starship.toml ~/.config/starship.toml.shell-terminal.bak || exit 1
       else
         touch ~/.config/starship.toml.shell-terminal.new || exit 1
       fi
     fi
     # starship の表示設定を書き込む
     cat > ~/.config/starship.toml <<'EOF'
   add_newline = false

   [directory]
   truncation_length = 3
   truncate_to_repo = false

   [username]
   show_always = true

   [hostname]
   ssh_only = false
   EOF
     if [ "$?" -ne 0 ]; then echo '中断: 書き込めない。控えは残してある' >&2; exit 1; fi
     printf '\n\033[7m 確認 \033[0m\n'
     cat ~/.config/starship.toml
   )
   ```

   - `add_newline = false`・`truncation_length = 3`・`truncate_to_repo = false`・`show_always = true`・`ssh_only = false` が出ればよい
   - `中断:` やエラーが出たら、この項の手順 3 へ進まない

1. WezTerm で、Git Bash の新しいタブを開く。

   - Ctrl+Shift+T で開く。開いているタブで `. ~/.bashrc` を読み直さない
   - **次の手順は、新しく開いた Git Bash のタブに貼る**

1. 新しい Git Bash のタブで、設定とプロンプトを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # starship の設定内容を確かめる
   cat ~/.config/starship.toml
   # プロンプトの表示を確かめる
   starship prompt
   ```

   - この項の手順 2 の 5 つの値と、ユーザー名・ホスト名を含むプロンプトが出ればよい
   - PowerShell 7 のプロファイルを設定済みなら、新しい PowerShell 7 を開くと同じ表示設定になる
   - PowerShell 7 だけ違う表示なら、`STARSHIP_CONFIG` の環境変数などで別の設定ファイルを指定していないか確かめる

<details id="シェルのツールを入れる-の補足と注意点">
  <summary>シェルのツールを入れる の補足と注意点</summary>

**注意点**

- **Windows の starship.toml は Git Bash と PowerShell 7 で共有する**: 任意の[Windows 11 で starship の表示を変える](#windows-11-で-starship-の表示を変える)は、既存の配色・プリセットも置き換える。控えを書き戻すと、両方のシェルに効く
  - PowerShell 7 では、[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 2 の starship の行が必要。`STARSHIP_CONFIG` を別の場所に向けている場合、このファイルは読まれない

**[シェルのツールを入れる](#シェルのツールを入れる)の手順 2: 確かめる値**

- `Tools` が空なら、どれも入っていない
- ほかの方法で入れたものを外してから始めるのは、混ざらないようにするため

**[シェルのツールを入れる](#シェルのツールを入れる)の手順 4**

- zoxide の 0.9.9 は、scoop が main のバケットの git の履歴から定義を取り出して入れる（`Resolving historical manifest for 'zoxide' (0.9.9)` の行が出る）

- 2 行目は、もう入っているものを、何も出さずに飛ばす

- starship は shim を作らず、`Adding ~\scoop\apps\starship\current to your path.` で自分のユーザーの `Path` に足す（この窓にも入る）

- bat は `Setting user environment variable: BAT_CONFIG_DIR = …` で環境変数を足す（この窓にも入る）

- それぞれ `'<名前>' (<版>) was installed successfully!` の形の行が出て、最後に `zoxide is now held and can not be updated anymore.` が出ればよい（zoxide は `0.9.9`）

- zoxide の 0.9.9 がもう入っていれば、3 行目は `'zoxide' (0.9.9) is already installed.` の警告だけを出す

- もう止めてあれば、`'zoxide' is already held.` が出る

**[シェルのツールを入れる](#シェルのツールを入れる)の手順 4: scoop がすることと、zoxide を 0.9.9 に止める理由**

- 5 つとも scoop の main のバケットの定義で、上流の Windows の zip を、定義の sha256 で確かめて置く（2026-10-08 の定義は fzf 0.74.4・zoxide 0.10.0・starship 1.26.0・eza 0.23.5・bat 0.26.1）
  - `was installed successfully!` の行の版は、入れた日の最新（zoxide は `0.9.9`）
  - fzf・zoxide・eza・bat は、`~\scoop\shims` に shim を作る（eza は `exa` の名前の shim も）
  - starship は shim を作らず、定義の `env_add_path` で `~\scoop\apps\starship\current` を自分のユーザーの `Path` の先頭に足す。scoop は、今の窓の `$env:PATH` にも足す（Scoop の `lib/system.ps1` の `Add-Path`）
  - bat は、定義の `env_set` で、自分のユーザーの環境変数 `BAT_CONFIG_DIR` を `~\scoop\apps\bat\current` にし、今の窓にも入れる。`config`・`syntaxes`・`themes` は `~\scoop\persist\bat` に控える（ファイルはハードリンク、フォルダーはジャンクション）。控えに `config` が無い最初の導入では、`%APPDATA%\bat\config` があれば写し、無ければ空のファイルを作る（定義の `pre_install`）
- **zoxide を 0.9.9 に止める理由**
  - 0.10.0 の bash の初期化は、Windows では `__zoxide_pwd` が `\command cygpath -w "\builtin pwd -L"` になり、コマンド置換が無い（`templates/bash.txt`）。今のディレクトリではなく、`<ドライブ>:\builtin pwd -L` の形の文字列を返すので、プロンプトのフックが移動に気付かず、Git Bash からは何も記録しない（上流の issue #1259）
  - 直すコミット（`1f484a4`、PR #1260、2026-07-07）は `main` にあり、`CHANGELOG.md` の `[Unreleased]` に「Bash/Zsh: fix `z` failing on Cygwin/MSYS2 due to `cygpath` being passed a bad string.」とある。2026-10-08 の時点で、タグの最新は `v0.10.0` で、このコミットを含むタグは無い
  - 0.9.9 の初期化は `\command cygpath -w "$(\builtin pwd -P)"`（Windows の `zoxide.exe` の中の文字列でも確かめた）。共通の bash 設定の Git Bash での検証（ryo-aoki-pc/bash の 2026-10-01・2026-10-06 の付録）も、0.9.9 で通っている
  - PowerShell の初期化は、この不具合に当たらない。PowerShell 7 の zoxide も Git Bash と同じ実行ファイルなので、0.9.9 にそろう
  - データベースの形は、0.9.9 と 0.10.0 で同じ（版 3 の `db.zo`。`src/db/mod.rs`）。0.10.0 から 0.9.9 に戻しても、覚えた履歴はそのまま読む
  - `main` には、データベースを平文の `db.txt` に変え、`db.zo` があれば読んで移す変更もある（`c479cc8`、#1288、2026-10-03。版になっていない）。直った版に上げると、履歴はその形に移るはず。上げた後に 0.9.9 に戻すと、上げた後に覚えたものは読まないはず
- **版の指定と止め方**（Scoop v0.6.0 のソース）
  - `scoop install zoxide@0.9.9` は、バケットの今の定義と版が違うと、バケットの git の履歴から `0.9.9` の定義を探し（`git log --follow -n 1 -G …` で見つけたコミットと、その親）、`~\scoop\workspace\zoxide.json` に書いてから入れる（v0.6.0 の #6370）。見つからなければ `WARN` の行を出して、定義の `autoupdate` で作る
  - 履歴を探すのは、main のバケットが git のリポジトリのときだけ（`lib/manifest.ps1` の `Find-HistoricalManifestInGit`）。そうでなければ `WARN  Bucket 'main' is not a git repository. Cannot search historical versions.` を出して `autoupdate` に移り、hash はバケットの履歴の定義のものではなく、そのときに取ったものになる。`autoupdate` も失敗すると、`Could not install: zoxide@0.9.9` で止まる
  - Git for Windows を入れる前に scoop を導入した場合、main のバケットは zip で置かれる（ScoopInstaller/Install の `install.ps1`）。git の形になるのは、最初の `scoop update`（`scoop-update.ps1` の `Sync-Bucket` の `Converting 'main' bucket to git repo...`）。`scoop install` が自分で `scoop update` を動かすのは、前の更新から 3 時間たったとき（`is_scoop_outdated`）だけなので、[シェルのツールを入れる](#シェルのツールを入れる)の手順 4 の先頭で `scoop update` を貼る
  - main のバケットでは、`73b1eafab`（2026-01-31）で 0.9.9 に、`f8683b6ce`（2026-07-04）で 0.10.0 になった。`f8683b6ce` の親の定義が 0.9.9
  - こうして入れたものは、`install.json` に `bucket` が無く、`url` が `workspace` の定義を指す。`scoop status` と `scoop update` は、その定義の版（0.9.9）を最新とみなすので、それだけでも上がらない。`scoop list` の `Source` は `<auto-generated>`
  - そのうえで `scoop hold` を付けた（`install.json` に `hold` を書く）。`scoop list` の `Info` が `Held package` になり、止めてあることが見える。`scoop update * --force` でも、止めたものは上げない
  - 直った版に上げるときは、`scoop unhold` の後に `scoop update zoxide --force` にする。`--force` は、版を指定して入れたもの（`bucket` が無く、`url` が `workspace` の定義）を、バケットの今の定義で入れ直す（v0.6.0 の #6730）。`--force` が無ければ、`zoxide: 0.9.9 (latest version)` の形の行を出して何もしない
  - 先に `scoop update` を貼るのは、バケットを新しくするため（`scoop update <名前>` は、前の更新から 3 時間たっていなければバケットを新しくしない）
  - 版を指定したものは、`~\scoop\workspace\zoxide.json` の場所として扱われ、`prune_installed` は入っているとみなさない（`installed` が `zoxide.json` の名前で探す）。0.10.0 が入っていても 0.9.9 を並べて入れ、`current` を 0.9.9 に付け替え、0.10.0 のフォルダーを残す。そのため、[シェルのツールを入れる](#シェルのツールを入れる)の手順 3 で先に外す
  - 同じ 0.9.9 がもう入っていると、`'zoxide' (0.9.9) is already installed.` の警告の後の `continue`（`scoop-install.ps1` の `ForEach-Object` の中で、囲むループが無い）が `bin/scoop.ps1` の `switch` まで抜け、同じ行のほかの名前を入れずに終わる。そのため、[シェルのツールを入れる](#シェルのツールを入れる)の手順 4 では zoxide だけを別の `scoop install` にした
  - 版を指定しない名前を並べたとき（[シェルのツールを入れる](#シェルのツールを入れる)の手順 4 の `scoop install fzf starship eza bat`）は、もう入っているものを `prune_installed` で飛ばす。`'<名前>' (<版>) is already installed. Skipping.` の警告は出ない（`Get-Dependency` が名前を `main/<名前>` の形に変えるので、警告を出す前の、指定した名前との突き合わせに当たらない）
  - 名前を 1 つだけ渡したときは、もう入っていれば `'<名前>' (<版>) is already installed.` と `Use 'scoop update <名前>' to install a new version.` の警告を出して終わる（`$apps.length -eq 1` の分かれ）
  - [scoop・winget・WSL を上げる](windows-setup.md#scoopwingetwsl-を上げる)の手順 7 で、先に main のバケットの `bucket\zoxide.json` の版を見るのは、`scoop update zoxide --force` が Releases ではなく、main のバケットの今の定義を入れるため（`update` の `$pin_broken` から `Find-AppBucket`）。バケットの定義は、Releases に出てから自動の更新で上がるまで遅れる。0.10.0 のまま上げると、止めるのをやめた 0.10.0 になる
- **VC++ ランタイム**: 5 つの Windows の実行ファイル（x64）の DLL の読み込みの表（PE のインポート表）で、`VCRUNTIME140.dll` を使うのは bat だけだった
  - fzf（Go）は `kernel32.dll` だけ。zoxide と starship は MSVC のビルドだが、C のランタイムを静的にリンクする（zoxide の `.cargo/config.toml`、starship の `release.yml` の `+crt-static`）。eza は MinGW のビルドで、Windows に付いている `msvcrt.dll` を使う
  - bat の定義の `suggest` は、extras の `vcredist2022` と `less` を勧める表示だけで、入れはしない。本書では [Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 3（winget の `Microsoft.VCRedist.2015+.x64`、PC 全体）を前提にした。starship の定義の `suggest`（`vcredist2022`）は、入れなくてよい
- starship の定義の `notes` は、PowerShell の `$PROFILE` に `Invoke-Expression (&starship init powershell)` を足すよう案内するが、従わない。貼る窓は PowerShell 7 なので、`$PROFILE` は 7 のプロファイルを指す。[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)が、zoxide と starship の行を 1 回だけ置く。5.1 の `$PROFILE` は 5.1 の窓が読むプロファイルで、starship は足さない

**[シェルのツールを入れる](#シェルのツールを入れる)の手順 5**

- それぞれの版が出ればよい（`zoxide 0.9.9`・`starship 1.26.0`・`v0.23.5 [+git]`・`bat 0.26.1` の形）

- 場所は、`C:\Users\<WIN_USER>\scoop\shims\` の下の `fzf.exe`・`zoxide.exe`・`eza.exe`・`bat.exe` と、`C:\Users\<WIN_USER>\scoop\apps\starship\current\starship.exe` の 5 行だけ

- `scoop list` の `zoxide` の行は、`Version` が `0.9.9`、`Source` が `<auto-generated>`（前から main のバケットで入れた 0.9.9 なら `main`）、`Info` が `Held package`

**[シェルのツールを入れる](#シェルのツールを入れる)の手順 6**

- 書いた中身は、scoop の控え（`~\scoop\persist\bat\config`）に残り、bat を上げても消えない

- `書いた: C:\Users\<WIN_USER>\scoop\apps\bat\current\config` と、`--theme="ansi"`・`--style="numbers,changes,header"`・`--paging=never` の 3 行が出ればよい

**[シェルのツールを入れる](#シェルのツールを入れる)の手順 6: bat の設定ファイル**

- Windows の bat は、`BAT_CONFIG_PATH` が無ければ `BAT_CONFIG_DIR` の下の `config` を、それも無ければ `%APPDATA%\bat\config` を読む（bat 0.26.1 の `src/bin/bat/directories.rs`・`config.rs`。`XDG_CONFIG_HOME` も `~/.config` も見ない）。scoop で入れると `BAT_CONFIG_DIR` の下になる
  - そのため、AlmaLinux 10 の [bat の設定ファイル](#bat-の設定ファイル)の bash のブロックを Git Bash に貼っても効かない
  - `C:\ProgramData\bat\config`（PC 全体）があれば、bat はその後ろに自分の設定をつないで読む。本書では作らない
- 書く場所は、bat が探すのと同じ順（`BAT_CONFIG_PATH`、無ければ `BAT_CONFIG_DIR` の下の `config`）で決める。`BAT_CONFIG_PATH` を自分で決めていても、bat が読む場所に書ける。どちらも無ければ（scoop の bat が入っていない）、`%APPDATA%` には書かずに止める
- `bat --config-file` の出力は使わない。bat はパイプに UTF-8 で書く（bat 0.26.1 の `src/bin/bat/main.rs` の `println!`）が、Windows PowerShell 5.1 は外部コマンドの出力を `[Console]::OutputEncoding`（日本語の Windows では OEM のコードページ 932）で読む。ユーザーのフォルダー名に ASCII 以外の文字があると、場所の文字が化けて書けない（Windows では確かめていない）
- 「無いときだけ」ではなく「空のときだけ」書く。scoop は最初の導入で空の `config` を作る（定義の `pre_install`）。`%APPDATA%\bat\config` から写されたものや、手で書いたものは変えない
- `-Encoding ASCII` にしたのは、BOM を付けないため
  - Windows PowerShell 5.1 の `-Encoding UTF8` は BOM を付ける。bat は設定の各行の前後の空白を削ってから読むが、BOM は削らず、1 行目をファイルの名前として読んで失敗する（Linux の bat 0.26.1 で確かめた。検証記録: `docs/verification/windows-setup.md` の「付録: シェルのツールの任意節のブロックの確認（2026-10-08）」）
  - テーマの名前と 3 行の中身は ASCII だけ。改行は CRLF になるが、bat は行末の `\r` も削る（同じ記録）
- `current\config` に書いた中身は、ハードリンクのもう一方の控え（`persist`）にも入るはず（Linux のハードリンクと PowerShell 7.5.3 では、同じ中身になった。Windows の NTFS と 5.1 では確かめていない）

**[シェルのツールを入れる](#シェルのツールを入れる)の手順 7・8: Git Bash での確かめ方**

- AlmaLinux 10 の初期設定の[シェルのツール](#シェルのツール)の手順 4〜7・9・10 と[キー操作を試す](#キー操作を試す)の手順 2〜5 は、`brew` の行を含まず、共通の bash 設定が読んだ結果を確かめるだけなので、Git Bash でもそのまま使える。この節には bash のブロックを足さず、Windows で違うところだけを箇条書きにした（同じブロックを書き写すと、片方だけ直したときに食い違う）
  - [シェルのツール](#シェルのツール)の手順 8（tmux）は、Windows では入れない。[キー操作を試す](#キー操作を試す)の手順 1 は bash-completion と `~/.inputrc`（AlmaLinux 10 の[共通の bash 設定](#共通の-bash-設定)の手順 3・4）を確かめるもので、この節では入れていない
- WezTerm は Windows で新しいタブを開くたびに、レジストリのシステムとユーザーの環境変数を読み直す（WezTerm の `pty/src/cmdbuilder.rs` の `get_base_env`）。そのため、[シェルのツールを入れる](#シェルのツールを入れる)の手順 3 の後に開いた新しいタブには、WezTerm を起動し直さなくても、starship の `Path` と `BAT_CONFIG_DIR` が入るはず（確かめていない）。起動し直すのは、プロンプトが starship にならなかったときだけにした
- 違うところの出どころ
  - `bind -X` のコロンと、WezTerm のシェル統合のマウス報告よけの行: ryo-aoki-pc/bash の `docs/install.md`（Git Bash の bash 5.3 の記録）
  - eza の見出し: eza 0.23.5 の `src/output/table.rs`。Windows では `Permissions` の見出しが `Mode` になり、`User` の列は Unix のときだけ作る
  - Git for Windows の `ll`（`/etc/profile.d/aliases.sh`。ログインシェルだけ）は `~/.bashrc` より先に読まれるので、共通の bash 設定の `ll` が上書きする。`MANPAGER` は bat があれば入るが、Git Bash に `man` は無い（ryo-aoki-pc/bash の `docs/reference/readme.md`）
  - zoxide: Windows の zoxide は、Git Bash ではプロンプトのたびに `cygpath -w` を動かし、Windows の形のパスで記録する。データベースは `HOME` の下ではなく `%LOCALAPPDATA%\zoxide`（zoxide の README の `_ZO_DATA_DIR` の表と、scoop の定義の `notes`）
  - fzf の ASCII 以外の文字: fzf の `CHANGELOG.md` の 0.54.2 に、Windows では全画面（`--no-height`）で開いたときしか ASCII 以外の文字を読めず、必要なら `FZF_DEFAULT_OPTS` に `--no-height` を足すよう書いてある。キー操作と `**<Tab>` は画面の一部（`--height`）に開く
  - fzf は Windows でも `$SHELL` で外部のコマンド（プレビューの bat など）を動かし、`/` を含むパスは `cygpath -w` で直す（fzf 0.74.4 の `src/util/util_windows.go`）。Git Bash の `SHELL` は bash なので、プレビューは bash で動くはず
- スタートメニューの「Git Bash」（mintty）でも同じ共通の bash 設定を読むが、fzf は winpty の連携で動く（fzf の CHANGELOG の 0.53.0）ので、WezTerm（ConPTY）と動きが違いうる。確かめは WezTerm で行う
- 覚えたディレクトリは `%LOCALAPPDATA%\zoxide` に入る（PowerShell 7 の zoxide も同じものを使う）

**[Windows 11 で starship の表示を変える](#windows-11-で-starship-の表示を変える)のリード**

- `%USERPROFILE%\.config\starship.toml`（Git Bash の `~/.config/starship.toml`）は、Git Bash と PowerShell 7 で共有する。PowerShell 7 は、[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 2 の starship の行で読む

- 控えは `~/.config/starship.toml.shell-terminal.bak`。ファイルが無ければ、`~/.config/starship.toml.shell-terminal.new` に新規作成の印を残す。既存の控えと印は上書きしない（この折りたたみの「Windows 11 で starship の表示を変えるの手順 2: Git Bash と PowerShell 7 が読む場所」）

**[Windows 11 で starship の表示を変える](#windows-11-で-starship-の表示を変える)の手順 2**

- 再実行しても控えは最初のまま。設定ファイルは、この項の 5 つの値で書き直す

**[Windows 11 で starship の表示を変える](#windows-11-で-starship-の表示を変える)の手順 2: Git Bash と PowerShell 7 が読む場所**

- `%USERPROFILE%\.config\starship.toml` は、Git Bash の `~/.config/starship.toml` と同じファイル
- `STARSHIP_CONFIG` を指定していなければ、Windows の starship が既定で読む（starship の `src/context.rs`）
- Git Bash は共通の bash 設定の初期化、PowerShell 7 は[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 2 の starship の行で読む。設定ファイルだけを置いても、PowerShell 7 への初期化は増えない
- 書く 5 つの値は、AlmaLinux 10 の[starship の設定ファイル](#starship-の設定ファイル)と[starship でユーザー名とホスト名を常に表示する](#starship-でユーザー名とホスト名を常に表示する)と同じ。プロンプトの前の空行を省き、ディレクトリを最大 3 階層にし、リポジトリで切らず、ユーザー名とホスト名を常に表示する
- 既存のファイルは `~/.config/starship.toml.shell-terminal.bak` に控える。元が無い場合は `~/.config/starship.toml.shell-terminal.new` で記録する
- 既存の控えは上書きしない
- Windows の Git Bash と PowerShell 7 で共有される見た目は、実機では確かめていない

**選択した方針**

- **5 つのツールを 1 つの手順で入れる**: `scoop install` は、版を指定しない 4 つと zoxide の 2 回に分ける
  - git-delta と GitHub CLI は、Windows 11 のセットアップの項（[git-delta](windows-setup.md#git-delta)・[GitHub CLI](windows-setup.md#github-cli)）にある
- **導入元は scoop の main のバケット**（README の「導入の基盤」の、CLI ツールは scoop）
  - 管理者が要らず、[更新](windows-setup.md#更新)の `scoop update *` と UniGet UI で上がる
  - zoxide の README は、Windows では winget を勧めている。0.10.0 の不具合は zoxide の初期化（実行ファイルの中）にあるので、どちらで入れても避けられず、版を止められる scoop にそろえた
- **シェルとの組み込み方は、[PowerShell 7 のプロファイルを設定する の補足と注意点](#powershell-7-のプロファイルを設定する-の補足と注意点)の「選択した方針」と同じ**: Git Bash は共通の bash 設定を使い、PowerShell は用途ごとに設定する。WSL の AlmaLinux 10 は Linux のホストとして扱う
  - Git Bash では共通の bash 設定が読むので、この節は入れて確かめるだけにし、`~/.bashrc` には書かない
  - 7 の PSFzf と、5.1・7 の eza の `ll` は、[PowerShell を開発に使う](#powershell-を開発に使う)で設定する
- **`XDG_CONFIG_HOME` などの環境変数は足さない**: Windows の bat と eza は `XDG_CONFIG_HOME` を見ない（bat の設定は `BAT_CONFIG_DIR` か `%APPDATA%`、eza のテーマは `%APPDATA%\eza\theme.yml`。eza 0.23.5 の `src/options/theme.rs`）。starship は `STARSHIP_CONFIG` が無ければ `~\.config\starship.toml` を読む（starship 1.26.0 の `src/context.rs`。Git Bash と PowerShell 7 で 1 つ）。zoxide は `%LOCALAPPDATA%\zoxide`。足すと、gh などほかのツールの設定の置き場所まで変わる
- **bat の設定は AlmaLinux 10 と同じ 3 行**: テーマも同じ名前の変数（`BAT_THEME_NAME`）で決める。書く場所だけが違う
- **Windows の starship の表示は、任意の[Windows 11 で starship の表示を変える](#windows-11-で-starship-の表示を変える)で設定する**: Windows で動くコマンドだけを置き、Git Bash と PowerShell 7 が共有する `~/.config/starship.toml` に書く。実機では確かめていない
- **使い方と、そのほかの設定は AlmaLinux 10 の項を参照する**: fzf の候補の fd は共通の bash 設定が `command -v fd` で見つける（ryo-aoki-pc/bash の `bashrc`）。fd の入れ方と bat の設定ファイルは Windows で違うので、この項の手順を使う。Linux 専用のコマンドは Git Bash に貼らない

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| zoxide の版 | 0.9.9 に止める（`zoxide@0.9.9` と `scoop hold`）。上げるのは、main のバケットの定義が 0.10.0 より新しくなってから | 0.10.0: Git Bash で記録しない。共通の bash 設定で `__zoxide_pwd` を上書きする: 上流の初期化に合わせた上書きを持ち、直った版が出たら外す手間が要る |
| 入れる単位 | 1 つの手順で、版を指定しない 4 つを 1 回の `scoop install`、zoxide の 0.9.9 を別の 1 回 | ツールごとの節: 確かめる場所が同じ Git Bash のタブで、まとめたほうが短い。5 つを 1 回の `scoop install`: zoxide の 0.9.9 がもう入っていると、scoop がほかの 4 つを入れずに終わる |
| Git Bash での確かめ | AlmaLinux 10 の初期設定の手順を指す | 同じ bash のブロックを書き写す: 片方だけ直したときに食い違う |
| bat の設定 | `BAT_CONFIG_PATH` か `BAT_CONFIG_DIR` の下（scoop の中）に、空のときだけ書く | `BAT_CONFIG_PATH` で `~/.config/bat/config` を読ませる: scoop の定義が向ける場所と二重になる。`bat --config-file` の出力を使う: 5.1 では、ASCII 以外の文字のフォルダー名が化ける |
| VC++ ランタイム | 無ければ[Windows 11 で WezTerm を入れる](#windows-11-で-wezterm-を入れる)の手順 3（管理者の窓） | extras の `vcredist2022` を scoop で入れる: extras のバケットを足す手順が増える |
| fzf の ASCII 以外の文字 | 変えない（[シェルのツールを入れる](#シェルのツールを入れる)の手順 8 の補足だけ） | `FZF_DEFAULT_OPTS` に `--no-height`: 全画面で開き、AlmaLinux 10 と見た目が変わる。実機で確かめてから決める |

**参照**

シェルのツールを入れる項の資料。「コード」の区別は上と同じ。

- コード: [ScoopInstaller/Main](https://github.com/ScoopInstaller/Main)（`bucket/fzf.json`・`zoxide.json`・`starship.json`・`eza.json`・`bat.json`。zoxide の 0.9.9 の定義は `f8683b6ce` の親）
- コード: [ScoopInstaller/Scoop](https://github.com/ScoopInstaller/Scoop)（v0.6.0。`lib/manifest.ps1` の `Find-HistoricalManifestInGit`・`generate_user_manifest`、`lib/install.ps1` の `env_add_path`・`env_set`・`persist_data`・`show_suggestions`・`test_running_process`・`prune_installed`、`lib/core.ps1` の `installed`、`lib/depends.ps1` の `Get-Dependency`、`lib/system.ps1` の `Add-Path`、`bin/scoop.ps1`、`libexec/scoop-install.ps1`・`scoop-update.ps1`（`Sync-Bucket`・`update`）・`scoop-hold.ps1`・`scoop-unhold.ps1`・`scoop-list.ps1`・`scoop-uninstall.ps1`、`CHANGELOG.md` の #6370・#6730）と [ScoopInstaller/Install](https://github.com/ScoopInstaller/Install)（`install.ps1`。git が無いときは、本体と main のバケットを zip で置く）
- コード: [ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide)（`templates/bash.txt` の v0.9.9・v0.10.0・`main`、`CHANGELOG.md`（`main`）、`src/db/mod.rs`、`.cargo/config.toml`、README の Windows の導入と `_ZO_DATA_DIR`）と、[issue #1259](https://github.com/ajeetdsouza/zoxide/issues/1259)・[PR #1260](https://github.com/ajeetdsouza/zoxide/pull/1260)・[Releases](https://github.com/ajeetdsouza/zoxide/releases)
- コード: [sharkdp/bat](https://github.com/sharkdp/bat)（v0.26.1 の `src/bin/bat/directories.rs`・`config.rs`）・[eza-community/eza](https://github.com/eza-community/eza)（v0.23.5 の `src/options/theme.rs`・`src/output/table.rs`・`src/fs/feature/git.rs`）・[junegunn/fzf](https://github.com/junegunn/fzf)（v0.74.4 の `CHANGELOG.md`・`src/util/util_windows.go`）・[starship/starship](https://github.com/starship/starship)（v1.26.0 の `src/context.rs`・`src/init/starship.ps1`・`.github/workflows/release.yml`）
- コード: [wezterm/wezterm](https://github.com/wezterm/wezterm)（`pty/src/cmdbuilder.rs` の `get_base_env`）と、自分用の設定の [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)（`bashrc`・`docs/install.md`・`docs/reference/readme.md` の「Windows 11 の Git Bash での違い」）

- 検証記録（`docs/verification/shell-terminal.md`）

</details>

---

### PowerShell 7 のプロファイルを設定する

- PowerShell 7 に貼り付け・↑/↓ の履歴検索と、導入済みの zoxide・starship を読む設定を足す
- 前提: [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)を導入してあり、使う版のユーザープロファイルが存在して読み込め、PSReadLine の Ctrl+Enter が `AddLine` に割り当てられている
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。この項の手順 6 は PowerShell 7 の窓
- 対象は PowerShell 7 のプロファイル（Windows PowerShell 5.1 とは別）
- zoxide と starship は、入れていなければ読まない。入れた後に PowerShell 7 を開き直せば読む

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. PowerShell 7 のプロファイルに、貼り付けと履歴の検索のキーと、zoxide・starship を読む行を足す。

   ```powershell
   & {
     # プロファイルに足す基本設定を用意する
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     $lines = @(
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine }  # windows-setup.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward }  # windows-setup.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward }  # windows-setup.md'
       'if (Get-Command -Name zoxide -CommandType Application -ErrorAction Ignore) { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }  # windows-setup.md'
       'if (Get-Command -Name starship -CommandType Application -ErrorAction Ignore) { function global:Invoke-Starship-PreCommand { if (Test-Path -Path Function:\__zoxide_hook) { $null = __zoxide_hook } }; Invoke-Expression (& starship init powershell) }  # windows-setup.md'
     )
     if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType File -Path $p -Force -ErrorAction Stop | Out-Null }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($line in $lines) {
       $text = Get-Content -LiteralPath $p -Raw
       if ($text -and $text.Contains($line)) { "すでにある: $line" } else {
         $add = $line
         if ($text -and -not $text.EndsWith("`n")) { $add = "`r`n" + $line }
         Add-Content -LiteralPath $p -Value $add -ErrorAction Stop
         "足した: $line"
       }
     }
     "--- $p"
     Get-Content -LiteralPath $p
   }
   ```

   - 5 行それぞれに `足した:` か `すでにある:` が出て、最後にプロファイルの中身が出ればよい
   - 開いている PowerShell 7 の窓には、開き直すまで効かない

1. Tab で補完の候補の一覧を出すときだけ、Tab の行を足す。

   ```powershell
   & {
     # Tab の補完設定と対象ファイルを用意する
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     $line = 'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete }  # windows-setup.md'
     if (-not (Test-Path -LiteralPath $p)) { Write-Error "中断: プロファイルが無い。この項の手順 2 を先に貼る: $p"; return }
     $text = Get-Content -LiteralPath $p -Raw
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($text -and $text.Contains($line)) { "すでにある: $line" } else {
       $add = $line
       if ($text -and -not $text.EndsWith("`n")) { $add = "`r`n" + $line }
       Add-Content -LiteralPath $p -Value $add -ErrorAction Stop
       "足した: $line"
     }
   }
   ```

   - `足した:` か `すでにある:` が出ればよい
   - Tab で、候補が一覧で出る（矢印で選んで Enter、Esc で取り消す）

1. PowerShell 7 で、実行ポリシーとキーの割り当てを確かめる。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Get-ExecutionPolicy -List | Out-String -Width 120; Import-Module PSReadLine; . $PROFILE; Get-PSReadLineKeyHandler -Bound | Where-Object Key -in 'Ctrl+Enter', 'UpArrow', 'DownArrow', 'Tab' | Format-Table Key, Function -AutoSize | Out-String -Width 120 }
   ```

   - 次のとおりならよい
     - 実行ポリシーの表の `LocalMachine` か `CurrentUser` が `RemoteSigned`
     - キーの表の `Ctrl+Enter` が `AddLine`、`UpArrow` が `HistorySearchBackward`、`DownArrow` が `HistorySearchForward`（この項の手順 3 を行ったなら、`Tab` が `MenuComplete`）
   - `pwsh.exe` が見つからない旨が出たら、[PowerShell 7 の導入](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)と PATH を確かめる
   - 実行ポリシーがどれも `Undefined` なら、プロファイルは読まれず、キーは既定のまま（`Ctrl+Enter` が `InsertLineAbove`）。そうでなければ、この項の手順 5 は飛ばす

1. 実行ポリシーがどれも `Undefined` のときだけ、PowerShell 7 の CurrentUser を RemoteSigned にする。

   ```powershell
   pwsh.exe -NoLogo -NoProfile -Command { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Get-ExecutionPolicy -List }
   ```

   - 表の `CurrentUser` が `RemoteSigned` になればよい
   - この項の手順 4 をもう一度貼って、キーの割り当てを確かめる

1. スタートメニューから PowerShell 7 を開き、キーとプロンプトを確かめる。

   - スタートメニューで「PowerShell」を探し、「Windows PowerShell」ではない「PowerShell」（PowerShell 7）をクリックして開く（一覧の名前に 7 は付かないことがある）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる
   - 何か打ってから ↑ を押すと、打った文字で始まる履歴だけが出る
   - 打っている途中に、履歴からの候補が薄い文字で出る（PowerShell 7 の既定の予測。→ で受け入れ、F2 で一覧の表示に切り替わる）。[PowerShell 7 のプロファイルに開発の設定を足す](#powershell-7-のプロファイルに開発の設定を足す)を通してあれば一覧で出る
   - starship を入れていればプロンプトが starship の形になり、zoxide を入れていれば `z` が使える
   - Ctrl+Alt+? で、キーの割り当ての一覧が出る

#### PowerShell 7 で Emacs モードを使う

- 任意で、PowerShell 7 のキー操作を Emacs モードにし、Ctrl+V の貼り付けを割り当て直す
- 前提: [PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 2 を通してある
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。この項の手順 3・4 は、新しい PowerShell 7 の窓
- 足す 2 行は、キーの割り当てより前、先頭の `using`・`param`・`#Requires` などの宣言より後に入れる

> [!WARNING]
> この項の手順 2 はファイルだけを変える。今開いている窓で `Set-PSReadLineOption -EditMode` を実行すると、それまでのキーの割り当てが消えるので、貼り付けを続ける窓では実行しない。

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. PowerShell 7 のプロファイルに、モードとキーの 2 行を入れる。

   ```powershell
   & {
     # プロファイルに入れるキー設定を用意する
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     $lines = @(
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineOption -EditMode Emacs }  # shell-terminal.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Chord Ctrl+v -Function Paste }  # shell-terminal.md'
     )
     if (-not (Test-Path -LiteralPath $p)) { Write-Error "中断: プロファイルが無い。前提の手順を先に通す: $p"; return }
     # 既存のキー設定を除き、プロファイルを解析する
     $bytes = [IO.File]::ReadAllBytes($p)
     $wide = $bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE
     $enc = if ($wide) { [Text.Encoding]::Unicode } else { [Text.Encoding]::GetEncoding(28591) }
     $original = $enc.GetString($bytes)
     $text = [regex]::Replace($original, '(?m)^(\uFEFF|\u00EF\u00BB\u00BF)?[^\r\n]*  # shell-terminal\.md\r?(\n|$)', '$1')
     if ($wide) { $parseText = $text; $parseEnc = $enc } else {
       $parseEnc = New-Object Text.UTF8Encoding($false, $true)
       try { $parseText = $parseEnc.GetString($enc.GetBytes($text)) } catch { $parseEnc = [Text.Encoding]::GetEncoding([Globalization.CultureInfo]::CurrentCulture.TextInfo.ANSICodePage); $parseText = $parseEnc.GetString($enc.GetBytes($text)) }
     }
     $bomLength = 0
     if ($parseText.Length -gt 0 -and $parseText[0] -eq [char]0xFEFF) {
       $parseText = $parseText.Substring(1)
       $bomLength = if ($wide) { 1 } else { $parseEnc.GetByteCount([string][char]0xFEFF) }
     }
     $tokens = $null; $errors = $null
     $ast = [Management.Automation.Language.Parser]::ParseInput($parseText, [ref]$tokens, [ref]$errors)
     if ($errors.Count) { Write-Error '中断: プロファイルに構文エラーがある。何も書いていない'; return }
     # キー設定と宣言の位置を調べる
     $commands = @($ast.FindAll({ param($a) $a -is [Management.Automation.Language.CommandAst] }, $true))
     $modes = @($commands | Where-Object {
       $_.GetCommandName() -match '(^|\\)Set-PSReadLineOption$' -and
       @($_.CommandElements | Where-Object { $_ -is [Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'EditMode' }).Count
     })
     $keys = @($commands | Where-Object { $_.GetCommandName() -match '(^|\\)Set-PSReadLineKeyHandler$' } | Sort-Object { $_.Extent.StartOffset })
     if ($keys.Count) {
       $lateMode = @($commands | Where-Object {
         $_.GetCommandName() -match '(^|\\)Set-PSReadLineOption$' -and $_.Extent.StartOffset -gt $keys[0].Extent.StartOffset -and
         @($_.CommandElements | Where-Object { $_ -is [Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'EditMode' }).Count
       })
       if ($lateMode.Count) { Write-Error '中断: 印の無い EditMode の行がキーの割り当てより後にある。先にその行をキーの割り当てより前へ移す。何も書いていない'; return }
       $anchor = $ast.EndBlock.Statements | Where-Object {
         $_.FindAll({ param($a) $a -is [Management.Automation.Language.CommandAst] -and $a.GetCommandName() -match '(^|\\)Set-PSReadLineKeyHandler$' }, $true).Count
       } | Select-Object -First 1
       if (-not $anchor) { Write-Error '中断: キーの割り当ての位置を決められない。何も書いていない'; return }
       $pos = $parseText.LastIndexOf("`n", $anchor.Extent.StartOffset) + 1
       if ($parseText.Substring($pos, $anchor.Extent.StartOffset - $pos).Trim()) { Write-Error '中断: キーの割り当てと同じ行に別の文がある。何も書いていない'; return }
     } else { $pos = $parseText.Length }
     if (@($modes | Where-Object { $_.Extent.StartOffset -ge $pos }).Count) { Write-Error '中断: 挿入位置より後に印の無い EditMode がある。複合文からモードとキーの設定を別の行へ分け、モードを先に置く。何も書いていない'; return }
     $declarations = @($ast.UsingStatements) + @($ast.ParamBlock)
     if (@($declarations | Where-Object { $_ -and $_.Extent.EndOffset -gt $pos }).Count) { Write-Error '中断: 宣言より後の位置を決められない。何も書いていない'; return }
     # 設定を挿入した内容を組み立てる
     $offset = if ($wide) { $pos } else { $parseEnc.GetByteCount($parseText.Substring(0, $pos)) }
     $offset += $bomLength
     $nl = if ($text.Contains("`r`n") -or -not $text.Contains("`n")) { "`r`n" } else { "`n" }
     $add = ($lines -join $nl) + $nl
     if ($offset -gt 0 -and $text[$offset - 1] -ne "`n" -and $text.Substring(0, $offset) -notmatch '^(\uFEFF|\u00EF\u00BB\u00BF)?$') { $add = $nl + $add }
     $result = $text.Insert($offset, $add)
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($result -eq $original) { "設定済み: $p" } else { [IO.File]::WriteAllBytes($p, $enc.GetBytes($result)); "設定した: $p" }
     $lines
   }
   ```

   - `設定した:` か `設定済み:` と、印の付いた 2 行が出ればよい。再実行しても同じ行は増えない
   - `中断:` が出たら、この項の手順 3 へ進まない。印の無い `EditMode` の行がキーの割り当てより後なら、先にその行をキーの割り当てより前へ移してから貼り直す
   - 印の無い `EditMode` の行がキーの割り当てより前なら、そのまま残してよい

1. スタートメニューから、新しい PowerShell 7 を開く。

   - 「PowerShell」を探し、「Windows PowerShell」ではない「PowerShell」（PowerShell 7）をクリックして開く
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる
   - **次の手順は、新しく開いた PowerShell 7 の窓に貼る**

1. 新しい PowerShell 7 で、モードとキーを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # キー操作のモードを確かめる
   (Get-PSReadLineOption).EditMode
   # キーの割り当てを確かめる
   Get-PSReadLineKeyHandler -Chord Ctrl+v,Ctrl+Enter,UpArrow | Format-Table Key, Function -AutoSize
   ```

   - `Emacs` と、`Ctrl+v` の `Paste`・`Ctrl+Enter` の `AddLine`・`UpArrow` の `HistorySearchBackward` が出ればよい
   - 出なければ、[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 4・5 と、この項の手順 2 を確かめる

<details id="powershell-7-のプロファイルを設定する-の補足と注意点">
  <summary>PowerShell 7 のプロファイルを設定する の補足と注意点</summary>

**[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)のリード**

- 足す行は ASCII の文字だけで、行末に印 `# windows-setup.md` を付ける

- Windows Terminal の既定のプロファイルは Windows PowerShell のまま変えない

- 対象は `Documents\PowerShell\Microsoft.PowerShell_profile.ps1`。Windows PowerShell 5.1 のプロファイルとは別

**[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 2**

- プロファイルは `C:\Users\<WIN_USER>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`（OneDrive でドキュメントをバックアップしていると、`OneDrive` の下）

- 何度貼ってもよい

**[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 2: 足す行**

- プロファイルは PowerShell 7 の `$PROFILE`（CurrentUserCurrentHost）で、ドキュメントの既知のフォルダーの下の `PowerShell\Microsoft.PowerShell_profile.ps1`（`CorePsPlatform.cs`・about_Profiles）。書き先を明示するため、`[Environment]::GetFolderPath('MyDocuments')` で求める。PowerShell はプロファイルを自分では作らない。MSIX の PowerShell 7 は、全ユーザーのプロファイル（`$PSHOME`）を使えない
- Ctrl+Enter: PowerShell 7.5 の PSReadLine 2.3.6 と、7.6 の 2.4.5 も、Windows モードの Ctrl+Enter は `InsertLineAbove`（`KeyBindings.cs`）
  - スタートメニューから管理者として開いた PowerShell 7 は conhost の窓になり（[Windows 11 のセットアップの「表示と入力」の手順 6](windows-setup.md#表示と入力)の補足）、Ctrl+Enter が `AddLine` に割り当てられていなければ、右クリックで貼ると 5.1 と同じく行が逆順になるはず
  - Windows Terminal は、貼るときに LF を CR に直す（`ControlCore::PasteText`）ので起きない。WezTerm（Windows では、貼るときに改行を CRLF に直す）は確かめていない
- ↑/↓: `HistorySearchBackward`・`HistorySearchForward`（既定は F8・Shift+F8 に割り当て）。[共通の bash 設定](#共通の-bash-設定)の `~/.inputrc` の `history-search-backward` と同じく、打った文字で始まる履歴だけを出す
  - `-HistorySearchCursorMovesToEnd` は付けない（既定の False で、カーソルは打った文字の後ろに残る。bash と同じ）。Microsoft の `SamplePSReadLineProfile.ps1` は付けている
  - 予測の一覧（ListView）が出ているときは、候補を選ぶ。複数行の入力の中では、ほかの行へ移る
  - 履歴のファイル（`%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`）は 5.1 と共有する
- 各行を `if (Get-Module -Name PSReadLine) { … }` で囲むのは、`pwsh -Command`・`-File` では PSReadLine が読み込まれず（`ConsoleHost.cs` の `LoadPSReadline`）、囲まないと `Set-PSReadLineKeyHandler` が PSReadLine を自動で読み込むため。`-NoExit` 付きの起動（WezTerm の起動メニューの PowerShell 7）では読み込まれる
- 行は ASCII の文字だけにする。7 の `Add-Content` は新しいファイルを BOM の無い UTF-8 で書く。5.1 の `Add-Content` は新しいファイルを ANSI で書き、PowerShell 7 は BOM の無いファイルを UTF-8 として読むので、5.1 から日本語を書くと化ける
- 基本の設定では予測（Predictive IntelliSense）は書かない。PSReadLine 2.2.6 から既定で有効で、7 では `HistoryAndPlugin`・`InlineView`（`Cmdlets.cs`）。F2 で一覧へ切り替わる
  - [PowerShell 7 のプロファイルに開発の設定を足す](#powershell-7-のプロファイルに開発の設定を足す)では `ListView` にし、CompletionPredictor を読む。プラグインが無ければ候補は履歴だけ
- EditMode は Windows（既定）のまま。[PowerShell 7 で Emacs モードを使う](#powershell-7-で-emacs-モードを使う)を選ぶときだけ変える
  - `EditMode` を変えると、それより前に `Set-PSReadLineKeyHandler` で付けたキーは既定に戻る。このため、EditMode の行をキーの割り当てより前に置く
  - Emacs の既定のキーには Ctrl+V の `Paste` が無いので、割り当て直す。Ctrl+Enter は、[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 2 の `AddLine` の行を後から読む
- プロファイルが無ければ作る。同じ行は足さない。プロファイルにほかの行があれば、そのまま残る

**[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 2: zoxide と starship の順**

- zoxide の初期化は、その時点の `prompt` を `$__zoxide_prompt_old` に入れて包み、プロンプトのたびに `__zoxide_hook` を呼ぶ。既定の `--hook pwd` では、ディレクトリが変わったときだけ `zoxide add` する（zoxide の `templates/powershell.txt`。0.9.9 と 0.10.0 で同じ）
- starship の初期化は `prompt` を定義し直すので、zoxide の後に読むと zoxide の包みを捨てる。starship の `prompt` は、最初に `$?` を控えた後に、`Invoke-Starship-PreCommand` があれば呼ぶ（starship 1.26.0 の `starship.ps1`）。この節の行は、そこで `__zoxide_hook` を呼ぶ
- 両方の README の形（starship → zoxide）では、zoxide の包みが starship の `prompt` を呼ぶ前に `if` を評価して `$?` を真に戻し、失敗したコマンドの後もプロンプトが成功の印になるおそれがある（コードからの推測。確かめていない）。WezTerm の自分用の設定の `shell/wezterm.ps1` は、元の `prompt` を呼ぶ直前に `$?` を戻している
- 初期化の行は、ツールが無ければ（`Get-Command -CommandType Application`）読まない。scoop の zoxide は shim、starship は `PATH` に足したフォルダーから見つかる
- `Invoke-Starship-PreCommand` はプロンプトのたびに呼ばれるので、`__zoxide_hook` があるかは `Test-Path -Path Function:\__zoxide_hook` で見る（starship の `starship.ps1` も `Test-Path` の形）
  - `Get-Command` は、無い名前のときに `PATH` とモジュールを探すので、zoxide を入れていない PC で、プロンプトのたびに遅くなる
- zoxide と starship の行を、それぞれの手順書から 1 行ずつ足す形にしないのは、通す順で行の順が変わるため（bash の共通設定が順を管理するのと同じ考え）

**[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 3: Tab の一覧**

- 既定の Tab は、候補を 1 つずつ入れ替える
- IME に Ctrl+Space を割り当てている場合、一覧を出す既定のキーを IME が受け取るので、Tab がその代わりになる

**[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 4: 子のプロセスで確かめる形と実行ポリシー**

- 7 から `pwsh.exe -NoProfile -Command { … }` を直接起動し、子のプロセスでプロファイルを 1 度だけ読む。貼る窓のプロファイルは読み直さない
- 5.1 から `pwsh.exe -Command { … }` にスクリプト ブロックを渡した場合は、5.1 が `-EncodedCommand` に変えて渡し、結果をオブジェクトで受け取る（5.1 の `NativeCommandProcessor.cs` の minishell）。Windows では確かめていない
- 結果は、子の pwsh で `Out-String` にして文字列で受け取る。5.1 でオブジェクトのまま受け取ると、最初に届いた実行ポリシーの列で表を作るので、キーの行が空になる
  - `-Width 120` を付けるのは、子が端末の幅を取れないと、`Out-String` が空の行だけを返すため
- `-NoProfile` でも `$PROFILE` は設定される（`ConsoleHost.cs`）ので、`. $PROFILE` で読む
- Windows 版の PowerShell 7 は、`$PSHOME\powershell.config.json` に `RemoteSigned` を持って配られ、これが `LocalMachine` の値になる（`build.psm1`。MSIX の `$PSHOME` にもあるかは推測）。Windows PowerShell 5.1 の実行ポリシーの値（レジストリ）は効かない
- すべてが `Undefined` なら `Restricted` になり、プロファイルが読まれない。そのときだけ、[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 5 で `CurrentUser` を `RemoteSigned` にする（`Documents\PowerShell\powershell.config.json` に書かれる）。MSIX では `LocalMachine` に書けない
- `Set-ExecutionPolicy` に `-Force` を付けるのは、確認の問いで止まらないようにするため
- UniGet UI は scoop を `-NoProfile -ExecutionPolicy Bypass` で動かすので、このプロファイルと実行ポリシーに依らない

**[PowerShell 7 で Emacs モードを使う](#powershell-7-で-emacs-モードを使う)のリード**

- 足す行は ASCII の文字だけで、行末の印は `# shell-terminal.md`。キーの割り当てより前、先頭の `using`・`param`・`#Requires` などの宣言より後に入れる

**[PowerShell 7 で Emacs モードを使う](#powershell-7-で-emacs-モードを使う)の手順 2: 設定する行と挿入位置**

- [Set-PSReadLineOption の `EditMode`](https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlineoption?view=powershell-7.6#-editmode)は、それより前に付けたキーを既定に戻す。任意の行は、最初の `Set-PSReadLineKeyHandler` を含む文より前、`using`・`param`・`#Requires` などの先頭の宣言より後に入れる
- Emacs の既定のキーには Ctrl+V の `Paste` が無い（[PSReadLine の Paste](https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline_functions?view=powershell-7.6#paste)）。2 行目で Ctrl+V を割り当て直し、その後に親の項の Ctrl+Enter と ↑↓ の行を読む
- 印の無い EditMode の行がキーの割り当てより後にあれば、後から割り当てを消すので、書かずに止める。前にある行は残す。任意の 2 行を再実行で増やさず、既存の文字コードと、ほかの行のバイトを保つ
- 複合文の中の EditMode が挿入位置より後になる場合も、書かずに止める。モードとキーの設定を別の行へ分け、モードを先に置いてからやり直す
- バイトを保つための文字列と、構文解析する文字列を分ける。解析時だけ先頭の BOM を除き、挿入位置にはその長さを足して書き戻す
- BOM の無いファイルを UTF-8 として読めなければ、現在のカルチャの ANSI コード ページで構文解析する。`[Text.Encoding]::Default` は 5.1 では ANSI、7 では UTF-8 なので使わない
- 開いている窓では EditMode を変えない。貼り付けに使うキーの割り当てまで変わるため、プロファイルに書くだけにして、新しい窓で確かめる。実機では確かめていない

**選択した方針**

- **Windows で CLI ツールを組み込むシェルは、Git Bash を主にする**
  - WezTerm の自分用の設定の Windows の `default_prog` は Git Bash（`C:/Program Files/Git/bin/bash.exe -i -l`。`lua/shells.lua`）。PowerShell 7・Windows PowerShell・WSL は、起動メニュー（Ctrl+Shift+M）から開く
  - 共通の bash 設定（README の「共通の bash 設定を先に入れる」）が、fzf・starship・zoxide・eza・bat・fd を `command -v` で見つけたときだけ読むので、Git Bash では、各ツールを入れるだけで効く。`~/.bashrc` には書かない
- **PowerShell 7 は用途に合わせて設定する**: この項では starship と zoxide を、入っているときだけ読む。[PowerShell を開発に使う](#powershell-を開発に使う)では、補完・予測・PSFzf・eza の `ll` などを足す。yazi の `y` は足さない
- **Windows PowerShell 5.1 は、Ctrl+Enter を `AddLine` に割り当てた状態を土台にする**: 任意の[Windows PowerShell 5.1 のキー操作を変える](#windows-powershell-51-のキー操作を変える)で Emacs と ↑↓ の履歴検索、[Windows PowerShell 5.1 のプロファイルに開発の設定を足す](#windows-powershell-51-のプロファイルに開発の設定を足す)で UTF-8 の関数・winget の補完・`ll` を足せる
  - プロファイルは、5.1 に貼る項で使う管理者の conhost の窓でも読まれ、キーや補完にも効く
  - starship と zoxide は 5.1 に足さない。見た目と起動の時間が変わる
- **WSL の AlmaLinux 10 は Linux のホストとして扱う**: 各手順書の AlmaLinux 10 の実施手順と共通の bash 設定を、WSL の中で通す
- **Windows Terminal の既定のプロファイルは変えない**: 手順書は、各項でスタートメニューから指定の窓を開き、Windows Terminal の項ではタブを選ぶ。貼る窓は既定のプロファイルに頼らないので、この設定は変えない。PowerShell 7 は実行ポリシーとプロファイルも別に持つ。

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| Tab の補完 | 条件付きの手順（[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 3） | 既定で入れる: 好みが分かれる。bash に近い動き（共通する部分まで補完し、もう 1 回で一覧）が好みなら、`MenuComplete` の代わりに `Complete` |
| 予測 | 基本の設定では既定のまま。開発の設定で `ListView` と CompletionPredictor を使う | 基本の設定へ一緒に追加: 開発用のモジュールと設定を別に通せるようにする |
| EditMode | 既定は Windows のまま。任意の手順で Emacs にできる | 先に付けたキーが既定に戻るので、EditMode の行をキーの割り当てより前に置く。Emacs に Ctrl+V の `Paste` が無いので割り当て直す |
| 履歴の件数 | 既定（4096） | `-MaximumHistoryCount 100000`（bash の `HISTSIZE` に合わせる）: 窓を開くたびに読む量が増える |
| 起動の更新の通知・テレメトリ | 開発の設定でユーザーの環境変数に置く | プロファイルへの記述: 起動のときに使う設定で、読み込みが間に合わない |

**参照**

- 検証記録（`docs/verification/shell-terminal.md`）

</details>

---

### Windows PowerShell 5.1 のキー操作を変える

- 任意で、Windows PowerShell 5.1 を Emacs モードにし、Ctrl+V と ↑/↓ の履歴検索を割り当てる
- 前提: 使う版のユーザープロファイルが存在して読み込め、PSReadLine の Ctrl+Enter が `AddLine` に割り当てられている
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 3・4 は新しい Windows PowerShell（5.1）の窓
- 対象は Windows PowerShell 5.1 の自分のユーザーのプロファイル
- 足す 4 行は、Ctrl+Enter などのキーの割り当てより前、先頭の宣言より後に入れる
- Ctrl+V は `Paste` を割り当て直す。複数行を作る Ctrl+Enter は、既存の `AddLine` のまま
- conhost の右クリックの貼り付けは、PSReadLine の `Paste` を呼ばず、文字をキーとして送る。LF は Ctrl+Enter として届くので、Ctrl+Enter を `AddLine` にする既存の行が、この項の EditMode の行より後に残っている必要がある（この項の手順 2 は、その順に入れる）。Emacs モードの窓に右クリックで貼ることは、実機では確かめていない（[Windows PowerShell 5.1 のキー操作を変える の補足と注意点](#windows-powershell-51-のキー操作を変える-の補足と注意点)の「Windows PowerShell 5.1 のキー操作を変えるの手順 2: 適用範囲と貼り付け」）

> [!WARNING]
> - この項の手順 2 で変えるプロファイルは、5.1 に貼る項で使う管理者の conhost の窓や、プロファイルを読む 5.1 の SSH のセッションにも効く。
> - 全ユーザーの `$PSHOME\profile.ps1` などは先に読まれる。そこで付けたキーも `EditMode` で消えるので、必要な割り当てはこの項の行より後で付け直す。
> - この項の手順 2 はファイルだけを変える。今開いている窓で `Set-PSReadLineOption -EditMode` を実行しない。

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Windows PowerShell（5.1） のプロファイルに、モードとキーの 4 行を入れる。

   ```powershell
   & {
     # プロファイルに入れるキー設定を用意する
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
     $lines = @(
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineOption -EditMode Emacs }  # shell-terminal.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Chord Ctrl+v -Function Paste }  # shell-terminal.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward }  # shell-terminal.md'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward }  # shell-terminal.md'
     )
     if (-not (Test-Path -LiteralPath $p)) { Write-Error "中断: プロファイルが無い。前提の手順を先に通す: $p"; return }
     # 既存のキー設定を除き、プロファイルを解析する
     $bytes = [IO.File]::ReadAllBytes($p)
     $wide = $bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE
     $enc = if ($wide) { [Text.Encoding]::Unicode } else { [Text.Encoding]::GetEncoding(28591) }
     $original = $enc.GetString($bytes)
     $text = [regex]::Replace($original, '(?m)^(\uFEFF|\u00EF\u00BB\u00BF)?[^\r\n]*  # shell-terminal\.md\r?(\n|$)', '$1')
     if ($wide) { $parseText = $text; $parseEnc = $enc } else {
       $parseEnc = New-Object Text.UTF8Encoding($false, $true)
       try { $parseText = $parseEnc.GetString($enc.GetBytes($text)) } catch { $parseEnc = [Text.Encoding]::Default; $parseText = $parseEnc.GetString($enc.GetBytes($text)) }
     }
     $bomLength = 0
     if ($parseText.Length -gt 0 -and $parseText[0] -eq [char]0xFEFF) {
       $parseText = $parseText.Substring(1)
       $bomLength = if ($wide) { 1 } else { $parseEnc.GetByteCount([string][char]0xFEFF) }
     }
     $tokens = $null; $errors = $null
     $ast = [Management.Automation.Language.Parser]::ParseInput($parseText, [ref]$tokens, [ref]$errors)
     if ($errors.Count) { Write-Error '中断: プロファイルに構文エラーがある。何も書いていない'; return }
     # キー設定と宣言の位置を調べる
     $commands = @($ast.FindAll({ param($a) $a -is [Management.Automation.Language.CommandAst] }, $true))
     $modes = @($commands | Where-Object {
       $_.GetCommandName() -match '(^|\\)Set-PSReadLineOption$' -and
       @($_.CommandElements | Where-Object { $_ -is [Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'EditMode' }).Count
     })
     $keys = @($commands | Where-Object { $_.GetCommandName() -match '(^|\\)Set-PSReadLineKeyHandler$' } | Sort-Object { $_.Extent.StartOffset })
     if ($keys.Count) {
       $lateMode = @($commands | Where-Object {
         $_.GetCommandName() -match '(^|\\)Set-PSReadLineOption$' -and $_.Extent.StartOffset -gt $keys[0].Extent.StartOffset -and
         @($_.CommandElements | Where-Object { $_ -is [Management.Automation.Language.CommandParameterAst] -and $_.ParameterName -eq 'EditMode' }).Count
       })
       if ($lateMode.Count) { Write-Error '中断: 印の無い EditMode の行がキーの割り当てより後にある。先にその行をキーの割り当てより前へ移す。何も書いていない'; return }
       $anchor = $ast.EndBlock.Statements | Where-Object {
         $_.FindAll({ param($a) $a -is [Management.Automation.Language.CommandAst] -and $a.GetCommandName() -match '(^|\\)Set-PSReadLineKeyHandler$' }, $true).Count
       } | Select-Object -First 1
       if (-not $anchor) { Write-Error '中断: キーの割り当ての位置を決められない。何も書いていない'; return }
       $pos = $parseText.LastIndexOf("`n", $anchor.Extent.StartOffset) + 1
       if ($parseText.Substring($pos, $anchor.Extent.StartOffset - $pos).Trim()) { Write-Error '中断: キーの割り当てと同じ行に別の文がある。何も書いていない'; return }
     } else { $pos = $parseText.Length }
     if (@($modes | Where-Object { $_.Extent.StartOffset -ge $pos }).Count) { Write-Error '中断: 挿入位置より後に印の無い EditMode がある。複合文からモードとキーの設定を別の行へ分け、モードを先に置く。何も書いていない'; return }
     $declarations = @($ast.UsingStatements) + @($ast.ParamBlock)
     if (@($declarations | Where-Object { $_ -and $_.Extent.EndOffset -gt $pos }).Count) { Write-Error '中断: 宣言より後の位置を決められない。何も書いていない'; return }
     # 設定を挿入した内容を組み立てる
     $offset = if ($wide) { $pos } else { $parseEnc.GetByteCount($parseText.Substring(0, $pos)) }
     $offset += $bomLength
     $nl = if ($text.Contains("`r`n") -or -not $text.Contains("`n")) { "`r`n" } else { "`n" }
     $add = ($lines -join $nl) + $nl
     if ($offset -gt 0 -and $text[$offset - 1] -ne "`n" -and $text.Substring(0, $offset) -notmatch '^(\uFEFF|\u00EF\u00BB\u00BF)?$') { $add = $nl + $add }
     $result = $text.Insert($offset, $add)
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($result -eq $original) { "設定済み: $p" } else { [IO.File]::WriteAllBytes($p, $enc.GetBytes($result)); "設定した: $p" }
     $lines
   }
   ```

   - `設定した:` か `設定済み:` と、印の付いた 4 行が出ればよい。再実行しても同じ行は増えない
   - `中断:` が出たら、この項の手順 3 へ進まない。印の無い `EditMode` の行がキーの割り当てより後なら、先にその行をキーの割り当てより前へ移してから貼り直す
   - 印の無い `EditMode` の行がキーの割り当てより前なら、そのまま残してよい

1. スタートメニューから、新しい Windows PowerShell（5.1） を開く。

   - 「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - **次の手順は、新しく開いた Windows PowerShell（5.1） の窓に貼る**

1. 新しい Windows PowerShell（5.1） で、モードとキーを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # キー操作のモードを確かめる
   (Get-PSReadLineOption).EditMode
   # キーの割り当てを確かめる
   Get-PSReadLineKeyHandler -Bound | Where-Object { $_.Key -in 'Ctrl+v', 'Ctrl+Enter', 'UpArrow', 'DownArrow' } | Format-Table Key, Function -AutoSize
   ```

   - `Emacs` と、`Ctrl+v` の `Paste`・`Ctrl+Enter` の `AddLine`・`UpArrow` の `HistorySearchBackward`・`DownArrow` の `HistorySearchForward` が出ればよい
   - 出なければ、この項の手順 2 と、プロファイルを読み込める実行ポリシーか、Ctrl+Enter の `AddLine` の行がモードの変更より後にあるかを確かめる

<details id="windows-powershell-51-のキー操作を変える-の補足と注意点">
  <summary>Windows PowerShell 5.1 のキー操作を変える の補足と注意点</summary>

**注意点**

- **Windows PowerShell 5.1 のキーは、5.1 に貼る項で使う管理者の conhost の窓にも効く**: 任意の[Windows PowerShell 5.1 のキー操作を変える](#windows-powershell-51-のキー操作を変える)で変える。先に全ユーザーのプロファイルが付けたキーも EditMode で既定に戻る
  - Ctrl+V は `Paste`、Ctrl+Enter は既存の `AddLine` を使う
  - conhost の右クリックの貼り付けは、LF を Ctrl+Enter として送る。既存の Ctrl+Enter の `AddLine` の行が、EditMode の行より後に残っている必要がある（任意の項の手順 2 は、その順に入れる）。Emacs モードでの右クリックと複数行の貼り付けは、実機では確かめていない

**[Windows PowerShell 5.1 のキー操作を変える](#windows-powershell-51-のキー操作を変える)のリード**

- 対象は `[Environment]::GetFolderPath('MyDocuments')` の下の `WindowsPowerShell\Microsoft.PowerShell_profile.ps1`（Windows PowerShell 5.1 の `$PROFILE`）

- 足す 4 行は ASCII の文字だけで、行末の印は `# shell-terminal.md`。Ctrl+Enter などのキーの割り当てより前、先頭の宣言より後に入れる

**[Windows PowerShell 5.1 のキー操作を変える](#windows-powershell-51-のキー操作を変える)の手順 1: 5.1 にする理由**

- 主題が 5.1 自身のキー操作で、`$PROFILE` と PSReadLine の確認も 5.1 を対象にするため、Windows PowerShell 5.1 に貼る

**[Windows PowerShell 5.1 のキー操作を変える](#windows-powershell-51-のキー操作を変える)の手順 2: 適用範囲と貼り付け**

- 5.1 の CurrentUserCurrentHost は、ドキュメントの既知のフォルダーの下の `WindowsPowerShell\Microsoft.PowerShell_profile.ps1`。通常の窓と、同じユーザーで開いた管理者の conhost の窓の両方で読まれる
- プロファイルは、全ユーザー・全ホスト → 全ユーザー・現在のホスト → 現在のユーザー・全ホスト → 現在のユーザー・現在のホストの順に読まれる（[about_Profiles](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-5.1#profile-types-and-locations)）。先に読まれた `$PSHOME\profile.ps1` などが付けたキーも、EditMode を変えると既定に戻る
- 書く順は Emacs → Ctrl+V の `Paste` → ↑↓ の履歴検索 → 既存のキーの行。既存の Ctrl+Enter の `AddLine` の行は、後から読むので残る
- 挿入する位置、印の無い EditMode が後ろにあるときの中断、バイトを保った書き込みは、[PowerShell 7 で Emacs モードを使う](#powershell-7-で-emacs-モードを使う)の手順 2 と同じ考え方
- `if (Get-Module -Name PSReadLine)` で囲み、PSReadLine が読み込まれていない起動では何もしない
- conhost の右クリックの貼り付けは、PSReadLine の `Paste` を呼ばず、クリップボードの文字をキー入力へ変えて入力バッファへ書く
  - [Clipboard.cpp](https://github.com/microsoft/terminal/blob/main/src/interactivity/win32/Clipboard.cpp)の `Clipboard::Paste` → `StringPaste` → `TextToKeyEvents` → `pInputBuffer->Write`
  - キーとして届くので、Ctrl+Enter の割り当てには依る。コピーボタンの中身の LF は Ctrl+Enter として届き、Windows モードの既定の `InsertLineAbove` では行が逆順になる。EditMode を変えると、それより前に付けた `AddLine` は消えるので、この項の行は、既存の Ctrl+Enter の `AddLine` の行より前に入れる
  - Emacs モードの管理者の conhost で、右クリックと複数行の貼り付けは実機では確かめていない

**[Windows PowerShell 5.1 のキー操作を変える](#windows-powershell-51-のキー操作を変える)の手順 4**

- 5.1 の PSReadLine（2.0.0）の `Get-PSReadLineKeyHandler` には `-Chord` が無いので、割り当ての一覧から絞る

**参照**

- 検証記録（`docs/verification/shell-terminal.md`）

</details>

---

### PowerShell を開発に使う

- PowerShell 7 と Windows PowerShell 5.1 に開発用の検査・テストのモジュールを入れ、7 のテレメトリと更新の通知を止める
- 前提: [PowerShell 7](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)を導入してあり、使う版のユーザープロファイルが存在して読み込め、PSReadLine の Ctrl+Enter が `AddLine` に割り当てられている。外部コマンドは[シェルのツールを入れる](#シェルのツールを入れる)（fzf・eza・bat・starship）・[git-delta](windows-setup.md#git-delta)・[GitHub CLI](windows-setup.md#github-cli)で入れる
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。7 の操作は `pwsh.exe -NoLogo -NoProfile -Command { … }` で行う。この項の手順 8・9 の確認は新しい Windows PowerShell（5.1）の窓
- 無い外部コマンドの補完と関数は飛ばす。rg・fd は、[Windows 11 で LazyVim の設定を導入する](neovim.md#windows-11-で-lazyvim-の設定を導入する)で入れてあれば対象にする
- エディターは [Neovim を既定のエディタにする](neovim.md#neovim-を既定のエディタにする)で設定する

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 版・モジュール・環境変数と、補完の控えの有無を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # Windows PowerShell の版とモジュールを確かめる
   powershell.exe -NoProfile -Command { $PSVersionTable.PSVersion; Get-Module -ListAvailable -Name PSScriptAnalyzer,Pester,PSReadLine | Select-Object Name,Version,ModuleBase | Out-String -Width 160 }
   # PowerShell 7 と外部コマンドの場所を確かめる
   Get-Command pwsh.exe -ErrorAction SilentlyContinue | Select-Object Source | Format-Table -AutoSize
   Get-Command winget,git,fzf,eza,gh,rg,fd,delta,bat,starship -CommandType Application -ErrorAction SilentlyContinue | Select-Object Name,Source | Format-Table -AutoSize
   # PowerShell 7 の版とモジュールを確かめる
   pwsh.exe -NoLogo -NoProfile -Command {
     $PSVersionTable.PSVersion
     Get-Command Install-PSResource,Save-PSResource,Get-PSResource | Select-Object Name,Source | Out-String -Width 120
     Get-Module -ListAvailable -Name PSScriptAnalyzer,Pester,CompletionPredictor,PSFzf | Select-Object Name,Version,ModuleBase | Out-String -Width 160
   }
   # PowerShell の環境変数を確かめる
   foreach ($n in 'POWERSHELL_TELEMETRY_OPTOUT','POWERSHELL_UPDATECHECK') { '{0} = {1}' -f $n,[Environment]::GetEnvironmentVariable($n,'User') }
   # 保存済みの補完ファイルを確かめる
   Get-ChildItem -Path "$env:LOCALAPPDATA\PowerShell\completions\*.ps1" -ErrorAction SilentlyContinue | Select-Object Name,Length,FullName | Format-Table -AutoSize
   ```

   - 5.1 と 7 の版、`pwsh.exe` の場所、PSResourceGet の 3 つのコマンドが出ればよい。`pwsh.exe` が無いときは、[PowerShell 7 の導入](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)と PATH を確かめる
   - モジュールの名前・版・`ModuleBase` と、2 つの環境変数の値を控える
   - 補完の控えがあれば、名前と大きさが出る。[PowerShell 7 のプロファイルに開発の設定を足す](#powershell-7-のプロファイルに開発の設定を足す)の手順 2 は、同じ名前の控えを作り直す（上書きする）
   - モジュールや控えが無いときは、その一覧には何も出ない

1. PowerShell 7 に、検査・テスト・予測・fzf のモジュールを入れる。

   ```powershell
   # PowerShell 7 用の開発モジュールを導入する
   pwsh.exe -NoLogo -NoProfile -Command {
     Install-PSResource -Name PSScriptAnalyzer,Pester,CompletionPredictor,PSFzf -Repository PSGallery -Scope CurrentUser -TrustRepository -ErrorAction Stop
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-PSResource -Name PSScriptAnalyzer,Pester,CompletionPredictor,PSFzf -Scope CurrentUser | Select-Object Name,Version,InstalledLocation | Out-String -Width 160
   }
   ```

   - 4 つの名前と版・保存先が出ればよい。`already installed` の警告だけなら、その版を使う
   - この項の手順 2 に無かった版と保存先を控える
   - エラーが出たら、この項の手順 4 へ進まない

1. PowerShell 7 から、5.1 用の検査・テストのモジュールを保存する。

   ```powershell
   # 5.1 用のモジュールの保存先を用意する
   pwsh.exe -NoLogo -NoProfile -Command {
     $dir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'
     New-Item -ItemType Directory -Force -Path $dir | Out-Null
     # PSScriptAnalyzer と Pester を保存する
     Save-PSResource -Name PSScriptAnalyzer,Pester -Repository PSGallery -TrustRepository -IncludeXml -Path $dir -ErrorAction Stop
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-PSResource -Name PSScriptAnalyzer,Pester -Path $dir | Select-Object Name,Version,InstalledLocation | Out-String -Width 160
   }
   ```

   - 2 つの名前と版・保存先が出ればよい。この項の手順 2 に無かった版と保存先を控える
   - エラーが出たら、この項の手順 5 へ進まない

1. ユーザーの環境変数で、PowerShell 7 のテレメトリと更新の通知を止める。

   ```powershell
   & {
     # 環境変数の設定値と既存の値を照合する
     $wanted = [ordered]@{ POWERSHELL_TELEMETRY_OPTOUT = '1'; POWERSHELL_UPDATECHECK = 'Off' }
     $other = @(foreach ($n in $wanted.Keys) {
       $v = [Environment]::GetEnvironmentVariable($n,'User')
       if ($v -and $v -cne $wanted[$n]) { $n }
     })
     if ($other.Count) { Write-Error "中断: 別の値がある: $($other -join ', ')。何も変えていない"; return }
     # PowerShell の環境変数を設定する
     foreach ($n in $wanted.Keys) { [Environment]::SetEnvironmentVariable($n,$wanted[$n],'User') }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($n in $wanted.Keys) { '{0} = {1}' -f $n,[Environment]::GetEnvironmentVariable($n,'User') }
   }
   ```

   - `POWERSHELL_TELEMETRY_OPTOUT = 1` と `POWERSHELL_UPDATECHECK = Off` が出ればよい
   - `中断:` が出たら、既存の値を使うならこの手順は行わない
   - この項の手順 2 で空だった変数だけを、この項で追加したものとして控える

1. スタートメニューから、新しい PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、「Windows PowerShell」ではない「PowerShell」（PowerShell 7）をクリックして開く
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる
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
   - 環境変数は `1`・`Off` ならよい。空なら、Windows Terminal など端末アプリの窓をすべて閉じて開き直し、この項の手順 6・7 をやり直す
   - 確かめたら、PowerShell 7 の窓を `exit` で閉じる

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

   - この項の手順 4 で保存した版と 2 つのコマンド、`PSAvoidUsingCmdletAliases`・`PSUseDeclaredVarsMoreThanAssignments` が出ればよい
   - これでモジュールの導入は終わり。プロファイルは子の項を選んで通す

#### PowerShell 7 のプロファイルに開発の設定を足す

- PowerShell 7 に UTF-8・補完・予測の一覧・PSFzf・短縮の関数を設定する
- 前提: [PowerShell を開発に使う](#powershell-を開発に使う)と[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)を通してある。Tab の一覧は同じ項の手順 3
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。この項の手順 4・5 は新しい PowerShell 7 の窓
- `$PROFILE` の読み直しはせず、新しい窓で確かめる
- 補完の控えは `%LOCALAPPDATA%\PowerShell\completions`。無い道具は飛ばす。道具を上げた後は[PowerShell の開発の設定を更新する](#powershell-の開発の設定を更新する)を通す

> [!WARNING]
> - この項の手順 3 の UTF-8 の行を読む 7 の窓では、`ipconfig`・`whoami` などの出力が英語になる。
> - この項の手順 3 の PSFzf の行は、Emacs モードの Ctrl+T（文字の入れ替え）・Ctrl+R（履歴の検索）を置き換える。

1. 管理者ではない PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、クリックして開く（「Windows PowerShell」ではない。「管理者として実行」にはしない）
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる

1. 入っている道具の補完を生成し、UTF-8 の控えのファイルに保存する。

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

   - 入っている道具に `wrote <名前>`、無い道具に `skip <名前>` と、保存したファイルの名前・大きさが出ればよい
   - `failed` が出たら、この項の手順 3 へ進まず、その道具の場所と版を確かめる

1. PowerShell 7 のプロファイルに、開発の設定の 9 行を足す。

   ```powershell
   & {
     # プロファイルに足す開発設定を用意する
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
     $lines = @(
       'if ($Host.Name -eq ''ConsoleHost'') { $global:DevConsoleEncoding = @([Console]::InputEncoding, [Console]::OutputEncoding); $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { [Console]::InputEncoding = $global:DevConsoleEncoding[0]; [Console]::OutputEncoding = $global:DevConsoleEncoding[1] }; [Console]::InputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false) }  # shell-terminal.md:dev'
       'function Invoke-Utf8Native { param([Parameter(Mandatory)][scriptblock]$ScriptBlock) $u8in = [Console]::InputEncoding; $u8out = [Console]::OutputEncoding; try { $OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false); & $ScriptBlock } finally { [Console]::InputEncoding = $u8in; [Console]::OutputEncoding = $u8out } }  # shell-terminal.md:dev'
       'if (Get-Command -Name winget -CommandType Application -ErrorAction Ignore) { Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock { param($wordToComplete, $commandAst, $cursorPosition) $w = $wordToComplete; $a = $commandAst.ToString(); Invoke-Utf8Native { winget complete --word="$w" --commandline "$a" --position $cursorPosition } | ForEach-Object { [Management.Automation.CompletionResult]::new($_, $_, ''ParameterValue'', $_) } } }  # shell-terminal.md:dev'
       'if (Get-Module -Name PSReadLine) { foreach ($devCompletion in Get-ChildItem -Path "$env:LOCALAPPDATA\PowerShell\completions\*.ps1" -ErrorAction Ignore) { . $devCompletion.FullName } }  # shell-terminal.md:dev'
       'if (Get-Module -Name PSReadLine) { Set-PSReadLineOption -PredictionViewStyle ListView }  # shell-terminal.md:dev'
       'if (Get-Module -Name PSReadLine) { Import-Module -Name CompletionPredictor -ErrorAction Ignore }  # shell-terminal.md:dev'
       'if ((Get-Module -Name PSReadLine) -and (Get-Command -Name fzf -CommandType Application -ErrorAction Ignore)) { Set-PSReadLineKeyHandler -Chord Ctrl+t -BriefDescription FzfProvider -Description ''PSFzf: insert paths selected with fzf'' -ScriptBlock { if ((Get-Module -Name PSFzf) -or (Import-Module -Name PSFzf -Global -PassThru -ErrorAction Ignore)) { Invoke-FzfPsReadlineHandlerProvider } }; Set-PSReadLineKeyHandler -Chord Ctrl+r -BriefDescription FzfHistory -Description ''PSFzf: search history with fzf'' -ScriptBlock { if ((Get-Module -Name PSFzf) -or (Import-Module -Name PSFzf -Global -PassThru -ErrorAction Ignore)) { Invoke-FzfPsReadlineHandlerHistory } else { [Microsoft.PowerShell.PSConsoleReadLine]::ReverseSearchHistory() } } }  # shell-terminal.md:dev'
       'if (Get-Command -Name eza -CommandType Application -ErrorAction Ignore) { function ll { eza --long --group-directories-first @args } }  # shell-terminal.md:dev'
       'function err { Get-Error -Newest 1 }  # shell-terminal.md:dev'
     )
     $oldWinget = 'if (Get-Command -Name winget -CommandType Application -ErrorAction Ignore) { Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock { param($wordToComplete, $commandAst, $cursorPosition) $w = $wordToComplete.Replace(''"'', ''""''); $a = $commandAst.ToString().Replace(''"'', ''""''); Invoke-Utf8Native { winget complete --word="$w" --commandline "$a" --position $cursorPosition } | ForEach-Object { [Management.Automation.CompletionResult]::new($_, $_, ''ParameterValue'', $_) } } }  # shell-terminal.md:dev'
     if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType File -Path $p -Force -ErrorAction Stop | Out-Null }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     # winget の古い補完設定を置き換える
     $latin1 = [Text.Encoding]::GetEncoding(28591)
     $raw = $latin1.GetString([IO.File]::ReadAllBytes($p))
     $updated = ($raw -split '(?<=\n)' | ForEach-Object {
       if ($_.TrimEnd("`r", "`n") -ceq $oldWinget) { $_.Replace($oldWinget, $lines[2]) } else { $_ }
     }) -join ''
     if ($updated -cne $raw) {
       [IO.File]::WriteAllBytes($p, $latin1.GetBytes($updated))
       "置き換えた: $($lines[2])"
     }
     # 開発の設定をプロファイルに足し、読み戻す
     foreach ($line in $lines) {
       $text = Get-Content -LiteralPath $p -Raw
       if ($text -and $text.Contains($line)) { "すでにある: $line" } else {
         $add = $line
         if ($text -and -not $text.EndsWith("`n")) { $add = "`r`n" + $line }
         Add-Content -LiteralPath $p -Value $add -ErrorAction Stop
         "足した: $line"
       }
     }
     "--- $p"
     Get-Content -LiteralPath $p
   }
   ```

   - 9 行それぞれに `足した:` か `すでにある:` が出て、最後にプロファイルの中身が出ればよい
   - 開いている窓ではプロファイルを読み直さず、この項の手順 4 で新しい窓を開く
   - 前の版の winget の行があれば、`置き換えた: <新しい行>` も出る

1. スタートメニューから、新しい PowerShell 7 を開く。

   - スタートメニューで「PowerShell」を探し、「Windows PowerShell」ではない「PowerShell」（PowerShell 7）をクリックして開く
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる
   - 日本語のコミットがあるローカルの Git リポジトリへ `Set-Location` で移る
   - **次の手順は、新しく開いた PowerShell 7 の窓に貼る**

1. 新しい PowerShell 7 で、文字コード・補完・予測・関数とキーを確かめる。

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

#### Windows PowerShell 5.1 のプロファイルに開発の設定を足す

- Windows PowerShell 5.1 に、必要なときだけ UTF-8 にする関数・winget の補完・`ll` を設定する
- 前提: [PowerShell を開発に使う](#powershell-を開発に使う)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。この項の手順 3・4 は新しい 5.1 の窓
- 5.1 のコード ページは常には変えない。starship・zoxide と、6 つの道具の補完の控えは読まない

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. Windows PowerShell（5.1）のプロファイルに、開発の設定の 3 行を足す。

   ```powershell
   & {
     # プロファイルに足す開発設定を用意する
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
     $lines = @(
       'function Invoke-Utf8Native { param([Parameter(Mandatory)][scriptblock]$ScriptBlock) $u8in = [Console]::InputEncoding; $u8out = [Console]::OutputEncoding; try { $OutputEncoding = [Console]::InputEncoding = [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false); & $ScriptBlock } finally { [Console]::InputEncoding = $u8in; [Console]::OutputEncoding = $u8out } }  # shell-terminal.md:dev'
       'if (Get-Command -Name winget -CommandType Application -ErrorAction Ignore) { Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock { param($wordToComplete, $commandAst, $cursorPosition) $w = $wordToComplete.Replace(''"'', ''""''); $a = $commandAst.ToString().Replace(''"'', ''""''); Invoke-Utf8Native { winget complete --word="$w" --commandline "$a" --position $cursorPosition } | ForEach-Object { New-Object Management.Automation.CompletionResult($_, $_, ''ParameterValue'', $_) } } }  # shell-terminal.md:dev'
       'if (Get-Command -Name eza -CommandType Application -ErrorAction Ignore) { function ll { eza --long --group-directories-first @args } }  # shell-terminal.md:dev'
     )
     if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType File -Path $p -Force -ErrorAction Stop | Out-Null }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($line in $lines) {
       $text = Get-Content -LiteralPath $p -Raw
       if ($text -and $text.Contains($line)) { "すでにある: $line" } else {
         $add = $line
         if ($text -and -not $text.EndsWith("`n")) { $add = "`r`n" + $line }
         Add-Content -LiteralPath $p -Value $add -ErrorAction Stop
         "足した: $line"
       }
     }
     "--- $p"
     Get-Content -LiteralPath $p
   }
   ```

   - 3 行それぞれに `足した:` か `すでにある:` が出て、最後にプロファイルの中身が出ればよい
   - 今開いている窓では読み直さず、新しい窓で確かめる

1. スタートメニューから、新しい Windows PowerShell（5.1）を開く。

   - 「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - 日本語のコミットがあるローカルの Git リポジトリへ `Set-Location` で移る
   - **次の手順は、新しく開いた Windows PowerShell（5.1）の窓に貼る**

1. 新しい Windows PowerShell（5.1）で、文字コード・関数と補完を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   # 実行前の文字コードを確かめる
   [Console]::InputEncoding.CodePage
   [Console]::OutputEncoding.CodePage
   # UTF-8 の関数で Git の日本語出力を確かめる
   $s = Invoke-Utf8Native { git log -10 --format=%s }
   $s
   # 実行後の文字コードを確かめる
   [Console]::InputEncoding.CodePage
   [Console]::OutputEncoding.CodePage
   # 開発用の関数を確かめる
   Get-Command Invoke-Utf8Native,ll -ErrorAction SilentlyContinue | Select-Object Name,CommandType
   ```

   - 4 つのコード ページが `932` で、`$s` の日本語が化けていなければよい。日本語の件名が無ければ、そのコミットを含む範囲で確かめる
   - winget があれば、`winget ins` と打って Tab を押すと `install` になる。Ctrl+C で取り消した後、`[Console]::InputEncoding.CodePage`・`[Console]::OutputEncoding.CodePage` が `932` のままであることを確かめる
   - eza があれば `ll` で長い一覧が出る。`ipconfig` の表示も日本語のままならよい

#### Windows PowerShell 5.1 の PSReadLine を上げる

- Windows PowerShell 5.1 の PSReadLine を、自分のユーザーのモジュールとして 2.4.5 に上げる
- 前提: [PowerShell を開発に使う](#powershell-を開発に使う)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く。保存は `pwsh.exe -NoLogo -NoProfile -Command { … }` で行う。この項の手順 4・5 は新しい 5.1 の窓、この項の手順 7 は 5.1 の窓をすべて閉じた後の新しい PowerShell 7 の窓
- 元から `Documents\WindowsPowerShell\Modules\PSReadLine\2.4.5` がある場合は、この項の手順 3・6・7 は行わない

> [!WARNING]
> - この項の手順 3 で保存すると、5.1 に貼る項で使う管理者の窓と 5.1 の SSH のセッションも、次に開いた窓から 2.4.5 を読む。
> - 予測の候補として、共有の履歴が入力と同じ行に出る。起動は 0.2 秒ほど延びる目安で、環境により異なる。
> - この項の手順 6・7 で戻す前に、[PowerShell の開発の設定を更新する](#powershell-の開発の設定を更新する)で保存した PSReadLine の新版も消す。同じ項の手順 6 の要領で、この手順書で追加した版だけを対象にする。

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。PowerShell 7 の「PowerShell」ではない）

1. 読み込んでいる版と、ユーザーの保存先の版を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Module PSReadLine | Select-Object Name,Version,ModuleBase
   Get-Module -ListAvailable PSReadLine | Select-Object Name,Version,ModuleBase
   Get-ChildItem -LiteralPath (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules\PSReadLine') -ErrorAction SilentlyContinue | Select-Object Name,FullName
   ```

   - 同梱の版が `2.0.0` で、ユーザーの保存先にほかの版が無いことを確かめ、版と場所を控える
   - `2.4.5` が既に保存されていれば、この項の手順 3・6・7 は飛ばす
   - ほかの版があれば、この項は中断して既存の導入元と設定を確かめる

1. PowerShell 7 から、5.1 用の PSReadLine 2.4.5 を保存する。

   ```powershell
   # 5.1 用のモジュールの保存先を用意する
   pwsh.exe -NoLogo -NoProfile -Command {
     $dir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules'
     New-Item -ItemType Directory -Force -Path $dir | Out-Null
     # PSReadLine 2.4.5 を保存する
     $saved = Test-Path -LiteralPath (Join-Path $dir 'PSReadLine\2.4.5')
     if (-not $saved) { Save-PSResource -Name PSReadLine -Version 2.4.5 -Repository PSGallery -TrustRepository -IncludeXml -Path $dir -ErrorAction Stop }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($saved) { 'すでにある: PSReadLine 2.4.5' } else { '保存した: PSReadLine 2.4.5' }
     Get-PSResource -Name PSReadLine -Path $dir | Select-Object Name,Version,InstalledLocation | Out-String -Width 160
   }
   ```

   - `保存した:`（貼り直したときは `すでにある:`）と、`PSReadLine` の版 `2.4.5`・保存先 `Documents\WindowsPowerShell\Modules` が出ればよい
   - 今開いている 5.1 の窓では `Import-Module PSReadLine -Force` を実行せず、新しい窓で確かめる

1. スタートメニューから、新しい Windows PowerShell（5.1）を開く。

   - 「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）
   - **次の手順は、新しく開いた Windows PowerShell（5.1）の窓に貼る**

1. 新しい Windows PowerShell（5.1）で、版・キーと複数行の貼り付けを確かめる。

   ```powershell
   & {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     # 複数行と入れ子の出力を確かめる
     '1 行目'
     '2 行目'
     '3 行目'
     if ($true) { '入れ子の行' }
     # PSReadLine の版を確かめる
     Get-Module PSReadLine | Select-Object Name,Version,ModuleBase
     # キーの割り当てと予測の設定を確かめる
     Get-PSReadLineKeyHandler -Bound | Where-Object { $_.Key -in 'Ctrl+Enter','Ctrl+v','UpArrow','DownArrow' } | Format-Table Key,Function -AutoSize
     (Get-PSReadLineOption).PredictionSource
   }
   ```

   - GitHub のコピーボタンでコピーし、右クリックで貼る。最後の `}` で Enter を押す
   - `1 行目`・`2 行目`・`3 行目`・`入れ子の行` の順に出て、版が `2.4.5`、`Ctrl+Enter` が `AddLine`、予測の元が `History` ならよい
   - [Windows PowerShell 5.1 のキー操作を変える](#windows-powershell-51-のキー操作を変える)を通してあれば、`Ctrl+v` が `Paste`、↑/↓ が `HistorySearchBackward`・`HistorySearchForward` のままであることも確かめる
   - 5.1 に貼る項で使う管理者の窓と 5.1 の SSH を使う場合は、それぞれ新しい窓・セッションでも版と貼り付けを確かめる。うまく貼れなければ、この項の手順 6・7 で戻す

1. この項の手順 5 でうまく貼れなかったときだけ、Windows PowerShell（5.1）の窓をすべて閉じ、新しい PowerShell 7 を開く。

   - この項の手順 1 の窓、管理者の窓、5.1 の SSH のセッションも閉じる。5.1 の窓は、開いている間 2.4.5 の DLL を使い続けるので、その版のフォルダーを消せない
   - スタートメニューで「PowerShell」を探し、「Windows PowerShell」ではない「PowerShell」（PowerShell 7）をクリックして開く
   - 「PowerShell」が無ければ、[PowerShell 7 の公式の導入案内](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows)に従って入れる
   - **次の手順は、新しく開いた PowerShell 7 の窓に貼る**

1. この項の手順 6 を行ったときだけ、新しい PowerShell 7 で、この項で保存した PSReadLine 2.4.5 の版のフォルダーだけを、名前を変えてから消す。

   ```powershell
   & {
     # 削除する版と作業用のパスを設定する
     $p = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Modules\PSReadLine\2.4.5'
     $q = "$p.remove"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (Test-Path -LiteralPath $q) { Remove-Item -LiteralPath $q -Recurse -Force -ErrorAction Stop }
     if (-not (Test-Path -LiteralPath $p)) { "保存した版は無い: $p"; return }
     try { Rename-Item -LiteralPath $p -NewName (Split-Path -Leaf $q) -ErrorAction Stop } catch { Write-Error '中断: 2.4.5 を使っている Windows PowerShell（5.1）がある。窓とセッションをすべて閉じてから貼り直す。何も消していない'; return }
     Remove-Item -LiteralPath $q -Recurse -Force -ErrorAction Stop
     "消した: $p"
     Test-Path -LiteralPath $p
   }
   ```

   - `消した:` と `False` が出ればよい。すでに消してあれば `保存した版は無い:` が出る。`PSReadLine` の親フォルダーや同梱のモジュールは消さない
   - `中断:` が出たら、何も消していない。残っている 5.1 の窓・SSH のセッションを閉じてから、この手順を貼り直す
   - 新しい Windows PowerShell（5.1）を開き、`Get-Module PSReadLine` の版が `2.0.0`、`Ctrl+Enter` が `AddLine` で、複数行が元の順に貼れることを、この項の手順 5 の形で確かめる

#### PowerShell の開発の設定を更新する

- 外部コマンドの補完の控えと、7・5.1 の開発用モジュールを上げる
- 前提: [PowerShell を開発に使う](#powershell-を開発に使う)を通してある。補完は [PowerShell 7 のプロファイルに開発の設定を足す](#powershell-7-のプロファイルに開発の設定を足す)を通してあるときだけ
- 実行場所: この PC のデスクトップの管理者ではない PowerShell 7。この項の手順 1 で開く。モジュールの操作は `pwsh.exe -NoLogo -NoProfile -Command { … }` で行う
- 外部コマンドは、先に [scoop・winget・WSL を上げる](windows-setup.md#scoopwingetwsl-を上げる)で上げる
- PSReadLine は [Windows PowerShell 5.1 の PSReadLine を上げる](#windows-powershell-51-の-psreadline-を上げる)を通したときだけ、この項の手順 5 で対象にする

> [!WARNING]
> この項の手順 5 で保存する PSReadLine の最新版は、2.4.5 と同じ動作とは限らない。新しい管理者の窓・SSH のセッションにも効くので、保存した後は [Windows PowerShell 5.1 の PSReadLine を上げる](#windows-powershell-51-の-psreadline-を上げる)の手順 5 で版・キー・貼り付けを確かめる。

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
   - 新しい PowerShell 7 を開き、[PowerShell 7 のプロファイルに開発の設定を足す](#powershell-7-のプロファイルに開発の設定を足す)の手順 5 の補完を確かめて閉じる

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
   - 新しい 7 の窓で、[PowerShell を開発に使う](#powershell-を開発に使う)の手順 7 と、プロファイルを設定したときは [PowerShell 7 のプロファイルに開発の設定を足す](#powershell-7-のプロファイルに開発の設定を足す)の手順 5 を確かめ、閉じる

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
   - 追加した版と保存先を控える。新しい 5.1 の窓で [PowerShell を開発に使う](#powershell-を開発に使う)の手順 9 を確かめ、閉じる
   - [Windows PowerShell 5.1 の PSReadLine を上げる](#windows-powershell-51-の-psreadline-を上げる)を通していなければ、この項の手順 5 は飛ばす

1. 5.1 の PSReadLine を上げる項を通したときだけ、公開されている版と比べて保存する。

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
   - 追加した版と保存先を控え、新しい 5.1 の窓で [Windows PowerShell 5.1 の PSReadLine を上げる](#windows-powershell-51-の-psreadline-を上げる)の手順 5 を通す。版は、この手順で保存した版と比べる
   - キーや貼り付けが合わなければ、新しい窓・セッションを閉じ、保存先からこの手順で追加した版のフォルダーだけを消す。以前の版の窓で貼り付けを確かめ直す

1. 新しい版で確かめ終え、古い版が要らなければ、その版のフォルダーだけを消す。

   - 7 と 5.1 の窓・SSH のセッションをすべて閉じ、エクスプローラーで、この項の手順 3〜5 で控えた保存先を開く。更新の前から開いている 5.1 の窓も、古い版の PSReadLine を使っている
   - この項で扱ったモジュールの名前の下で、使わない古い版のフォルダーだけを消す。新しい版と、元に戻すために残す版は消さない
   - `Documents\WindowsPowerShell\Modules` の `PSWindowsUpdate` など、ほかのモジュールには触れない
   - PSReadLine の `2.4.5` を残すかは、戻す版として使うかで決める。同梱の `$PSHOME\Modules` は変えない
   - 新しい 7 と 5.1 の窓で `Get-Module -ListAvailable` を使い、残した版が見えることを確かめる

<details id="powershell-を開発に使う-の補足と注意点">
  <summary>PowerShell を開発に使う の補足と注意点</summary>

**注意点**

- **PowerShell 7 の開発の設定は、外部コマンドの表示の言語も変える**: コンソールを UTF-8 にすると、`ipconfig`・`whoami` などが英語になる。5.1 は常には変えず、[Windows PowerShell 5.1 のプロファイルに開発の設定を足す](#windows-powershell-51-のプロファイルに開発の設定を足す)の `Invoke-Utf8Native` の間だけ変える

- PSFzf で選んだ内容は入力の行に入り、その場では実行しない

- **道具を上げても、PowerShell 7 の補完の控えは変わらない**: scoop で gh・rg・fd・delta・bat・starship を上げた後は、[PowerShell の開発の設定を更新する](#powershell-の開発の設定を更新する)で控えを作り直す

- **Windows PowerShell 5.1 の PSReadLine 2.4.5 は同じユーザーの窓で使う**: [Windows PowerShell 5.1 の PSReadLine を上げる](#windows-powershell-51-の-psreadline-を上げる)と、次に開く管理者の窓にも効く

- **PowerShell の開発の設定は起動の時間にも影響する**: 7 の追加の行は合わせて約 0.1 秒、5.1 の PSReadLine 2.4.5 は約 0.2 秒の目安。PSFzf は最初に Ctrl+T・Ctrl+R を押したときに読み、モジュールの読み込みには約 0.23 秒掛かる

**[PowerShell を開発に使う](#powershell-を開発に使う)のリード**

- プロファイルは子の項で設定する

**[PowerShell を開発に使う](#powershell-を開発に使う)の手順 2: 5.1 の版とモジュールの確認**

- 貼る窓は 7 なので、5.1 の版とモジュールの一覧は `powershell.exe -NoProfile -Command { … }` で直接起動した 5.1 に出させる。`cmd` や `Start-Process` で中継しない

**[PowerShell を開発に使う](#powershell-を開発に使う)の手順 3: モジュールの導入元**

- PSScriptAnalyzer は PowerShell の静的検査、Pester はテストに使う。7 には PSResourceGet の `Install-PSResource -Scope CurrentUser` で入れる
- `-TrustRepository` は、この呼び出しで PSGallery の信頼を確かめる問いを出さない指定。PSGallery の `Trusted` は変えない
- CompletionPredictor と PSFzf は 7 にだけ入れる。プロファイルの行を足すまでは、入れただけで予測やキーは変わらない

**[PowerShell を開発に使う](#powershell-を開発に使う)の手順 4: 5.1 に保存する形**

- 7 の `Save-PSResource -IncludeXml` で、ドキュメントの既知のフォルダーの下の `WindowsPowerShell\Modules` に保存する。5.1 の古い PowerShellGet や NuGet の提供者を上げずに済む
- `Documents\WindowsPowerShell\Modules` がまだ無い PC がある。`-Path` の保存先が無いと止まるので、先に作る
- 保存先は名前・版ごとのフォルダーになる。`Get-PSResource -Path` で版と場所を見る。5.1 の `Get-InstalledModule` には出ない
- 同じ版の `Save-PSResource` は上書きする。新しい版を保存しても古い版は残る。5.1 に同梱の Pester は消さず、追加した版を先に読む形にする
- 導入前後の名前・版・保存先を控える

**[PowerShell を開発に使う](#powershell-を開発に使う)の手順 5: 起動前に読む環境変数**

- `POWERSHELL_TELEMETRY_OPTOUT=1` と `POWERSHELL_UPDATECHECK=Off` は、ユーザーの環境変数に置く。PowerShell の起動時に使うので、プロファイルには書かない
- ほかの値があれば止める形は、[Neovim を既定のエディタにする](neovim.md#neovim-を既定のエディタにする)と同じ
- 設定アプリの「詳細設定」→「PowerShell」のスイッチは実行ポリシーを RemoteSigned にするもの。5.1 ではプロファイルを読み込める実行ポリシーが必要で、7 では[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 5 で扱う

**[PowerShell を開発に使う](#powershell-を開発に使う)の手順 8: 5.1 にする理由**

- [PowerShell を開発に使う](#powershell-を開発に使う)の手順 8・9 は、5.1 用の保存先に置いたモジュールを、新しく開いた 5.1 で読み込めるか確かめる。確認の対象が 5.1 自身なので、Windows PowerShell 5.1 に貼る

**[PowerShell 7 のプロファイルに開発の設定を足す](#powershell-7-のプロファイルに開発の設定を足す)のリード**

- プロファイルに足す 9 行は ASCII だけで、印は `# shell-terminal.md:dev`。`$PROFILE` の読み直しはせず、新しい窓で確かめる

**[PowerShell 7 のプロファイルに開発の設定を足す](#powershell-7-のプロファイルに開発の設定を足す)の手順 2**

- 控えは `gh.ps1`・`rg.ps1`・`fd.ps1`・`delta.ps1`・`bat.ps1`・`starship.ps1` のうち、生成したものだけ

**[PowerShell 7 のプロファイルに開発の設定を足す](#powershell-7-のプロファイルに開発の設定を足す)の手順 2: 補完の控え**

- gh・rg・fd・delta・bat・starship の補完は、7 から生成し、`%LOCALAPPDATA%\PowerShell\completions\<名前>.ps1` に置く。MSIX の 7 も同じ場所を読む
- 6 つの生成は合わせて約 0.3 秒掛かるので、起動のたびには生成しない。プロファイルでは控えを読み、scoop で道具を上げた後に作り直す
- 生成中だけコンソールの入出力を UTF-8 にし、`finally` で戻す。ファイルは UTF-8（BOM 付き）で書く。fd の補完には ASCII 以外の文字が含まれる
- 無い道具は飛ばす。生成に失敗した道具の控えは上書きしないので、失敗したままなら、前に生成した内容が残る

**[PowerShell 7 のプロファイルに開発の設定を足す](#powershell-7-のプロファイルに開発の設定を足す)の手順 3: UTF-8 と終了時の復元**

- `ConsoleHost` のときだけ、コンソールの入出力を UTF-8 にする。元の 2 つの値を `$global:DevConsoleEncoding` に控え、先に `PowerShell.Exiting` のイベントを登録する
- コンソールの文字コードは親子のプロセスで共有する。5.1 から 7 を開いて終わるときも、終了のイベントで元の値へ戻す。元の値を 932 と決め打ちしない
- `Invoke-Utf8Native` は、渡したスクリプト ブロックの間だけ、関数内の `$OutputEncoding` とコンソールの入出力を UTF-8 にする。`finally` でコンソールの 2 つの値を戻す
- `$OutputEncoding` は外部コマンドへ渡す文字の変換に使う。ファイルの `Out-File`・`>`・`Set-Content` の文字コードをそろえる設定ではない（[about_Character_Encoding](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding?view=powershell-7.6)）

**[PowerShell 7 のプロファイルに開発の設定を足す](#powershell-7-のプロファイルに開発の設定を足す)の手順 3: 補完と予測**

- winget の行は、Microsoft の補完の例を基に `Invoke-Utf8Native` で包む。補完のときにだけ `winget complete` を呼び、その間の文字コードを確実に戻す
- 7.3 以降の `$PSNativeCommandArgumentPassing` が `Windows` のときは、引数内の `"` を PowerShell がエスケープして渡すので、二重にしない。5.1 では `"` を二重にする
- 2026-11-07 の PowerShell 7.6.9 では、`winget show --id "Microsoft.PowerShell" --version ` の補完は、二重にするとオプション 31 個、二重にしないと版 112 個を返した。引用符の無い入力では同じ結果だった
- 前の版の winget の行の置き換えは、プロファイルを Latin-1（28591。1 バイトを 1 文字にする）で読み書きし、ほかの行のバイトを変えない。プロファイルは BOM の無い cp932 のこともあり、7 の既定の UTF-8 で読み書きすると、その日本語が壊れた（2026-11-07、Hyper-V の VM）
- 6 つの控えは、PSReadLine があるときだけ読み込む。`-Command`・`-File` など、対話用の PSReadLine が無い起動では読み込まない
- 予測の表示は `ListView` にする。7 の予測の元は既定の `HistoryAndPlugin` のまま、CompletionPredictor を読み、履歴と補完から候補を出す
- Tab の補完と、打っている間に出る予測は別の設定。Tab は、[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の `MenuComplete` を使う
- 履歴の連続した重複を除く `HistoryNoDuplicates` は、5.1・7 とも既定で有効なので、プロファイルには足さない

**[PowerShell 7 のプロファイルに開発の設定を足す](#powershell-7-のプロファイルに開発の設定を足す)の手順 3: PSFzf と短縮の関数**

- PSFzf の読み込みは約 0.23 秒掛かる。Ctrl+T・Ctrl+R のスクリプト ブロックから読み、対応するハンドラーを呼ぶ。起動のときには読み込まない
- キーから読むモジュールを `-Global` にするのは、その後のキーでも同じモジュールを使うため。PSFzf が無ければ、Ctrl+R は PSReadLine の `ReverseSearchHistory` を呼ぶ
- `ll` は eza があるときだけ定義し、`--long --group-directories-first` と引数を渡す。`err` は 7 の `Get-Error -Newest 1` を呼ぶ。既存の `ls`・`cat` は置き換えない
- 追加する行は合わせて約 0.1 秒の目安。負荷で起動の時間がばらつくので、個々の行の内訳と計り方は検証記録に置く

**[Windows PowerShell 5.1 のプロファイルに開発の設定を足す](#windows-powershell-51-のプロファイルに開発の設定を足す)のリード**

- 対象は `Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`。足すのは ASCII の 3 行で、印は `# shell-terminal.md:dev`

**[Windows PowerShell 5.1 のプロファイルに開発の設定を足す](#windows-powershell-51-のプロファイルに開発の設定を足す)の手順 1: 5.1 にする理由**

- 主題が 5.1 自身のプロファイルで、`$PROFILE` の書き先と文字コード・補完の確認も 5.1 を対象にするため、Windows PowerShell 5.1 に貼る

**[Windows PowerShell 5.1 のプロファイルに開発の設定を足す](#windows-powershell-51-のプロファイルに開発の設定を足す)の手順 2: 必要なときだけ UTF-8 にする**

- 5.1 のコンソールの文字コードは変えず、`Invoke-Utf8Native`・winget の補完・`ll` の 3 行だけを足す。管理者の窓に貼る手順の出力を変えないため
- `Invoke-Utf8Native` の UTF-8 は `New-Object Text.UTF8Encoding($false)` で作る。winget の補完からもこの関数を呼び、補完した後に元の文字コードへ戻す
- 5.1 を常に UTF-8 にすると、`ipconfig`・`whoami` などが英語になる。UTF-8 の外部コマンドの出力を取り込むときだけ、関数へスクリプト ブロックを渡す

**[Windows PowerShell 5.1 の PSReadLine を上げる](#windows-powershell-51-の-psreadline-を上げる)の手順 1: 5.1 にする理由**

- 主題が 5.1 自身の PSReadLine で、導入前後の版・キー・貼り付けも 5.1 で確かめるため、Windows PowerShell 5.1 に貼る。モジュールの保存だけは 7 の `Save-PSResource` を使う

**[Windows PowerShell 5.1 の PSReadLine を上げる](#windows-powershell-51-の-psreadline-を上げる)の手順 3**

- 保存した版は上書きしない。2.4.5 を使っている 5.1 の窓があると、上書きできずに失敗するため

**[Windows PowerShell 5.1 の PSReadLine を上げる](#windows-powershell-51-の-psreadline-を上げる)の手順 3: 版を指定して保存する理由**

- 7 の `Save-PSResource -Version 2.4.5` で、5.1 のユーザーのモジュールの場所へ保存する。プロファイルへ `Import-Module PSReadLine` の行は足さない
- 次に開く 5.1 は、ユーザーのモジュールの場所にある新しい版を先に読む。同じユーザーの管理者の窓も対象になる
- 5.1 の予測の元は `History` だけで、候補は同じ行に出る。7 の CompletionPredictor と `ListView` の設定は 5.1 に足さない
- 同梱の 2.0.0 は残す。うまく貼れなかった場合の復旧では、この項で保存した 2.4.5 の版のフォルダーだけを消す
- 5.1 の起動は約 0.2 秒延びる目安。計り方と貼り付けの確認の範囲は検証記録に置く

**[Windows PowerShell 5.1 の PSReadLine を上げる](#windows-powershell-51-の-psreadline-を上げる)の手順 7: 名前を変えてから消す理由**

- 5.1 の窓は、開いている間ずっと PSReadLine の DLL を使う。手順書を貼っている 5.1 の窓からは、読み込んでいる 2.4.5 を消せない（`アクセスが拒否されました`）。このため、5.1 の窓をすべて閉じて、PowerShell 7 の窓で消す。7 は自分の PSReadLine を読み、5.1 のユーザーのモジュールの場所は読まない
- `Remove-Item -Recurse` は、使っているファイルに当たると、それより前のファイルを消したところで止まる。途中まで消えた版が残ると、次の 5.1 がその版を読もうとする
- フォルダーの名前の変更は、中に使っているファイルがあると、何も変えずに失敗する。先に名前を変えて確かめ、変えられたときだけ消す。名前を変えたフォルダー（`2.4.5.remove`）は版の名前ではないので、5.1 は読まない
- `powershell.exe` が動いているかでは決めない。ほかのアプリが `-NoProfile -NonInteractive` で動かす 5.1 は、PSReadLine を読まない

**[PowerShell の開発の設定を更新する](#powershell-の開発の設定を更新する)の手順 2: 道具と補完の版をそろえる**

- 補完の控えは、生成したときの実行ファイルの内容。scoop で gh・rg・fd・delta・bat・starship を上げた後は、同じ生成のブロックで作り直す

**[PowerShell の開発の設定を更新する](#powershell-の開発の設定を更新する)の手順 3: 7 のモジュールを上げる**

- 7 のモジュールは `Update-PSResource` で上げる。`-TrustRepository` は、この呼び出しにだけ効く。新しい版が無ければ何も出ない

**[PowerShell の開発の設定を更新する](#powershell-の開発の設定を更新する)の手順 4: 5.1 のモジュールを上げる**

- 5.1 のモジュールは、PSGallery の `Find-PSResource` と、保存先を指定した `Get-PSResource` の版を比べ、新しい版があれば保存する。同じ版を毎回上書きしないため

**[PowerShell の開発の設定を更新する](#powershell-の開発の設定を更新する)の手順 5: PSReadLine を上げる条件**

- PSReadLine は、[Windows PowerShell 5.1 の PSReadLine を上げる](#windows-powershell-51-の-psreadline-を上げる)を通した場合だけ、5.1 の更新の対象にする

**[PowerShell の開発の設定を更新する](#powershell-の開発の設定を更新する)の手順 6: 古い版を残す理由**

- 5.1 の保存で新しい版を足しても、古い版は消えない。追加前後の版と場所を控え、使用中の窓を閉じてから、不要になった版のフォルダーだけを消す

**選択した方針**

- 7 には開発用のモジュールと、補完・予測・PSFzf・短縮の関数を足す。5.1 は必要なときだけ UTF-8 にする関数、winget の補完、`ll` と開発用のモジュールにする
- プロファイルは ASCII の行だけを、`  # shell-terminal.md:dev` の印付きで足す。ほかの設定と別に戻せるようにする
- エディターは[Neovim を既定のエディタにする](neovim.md#neovim-を既定のエディタにする)を使い、同じ設定の手順を書き写さない

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| 7 の外部コマンドの文字コード | ConsoleHost の入出力を UTF-8 にし、元の値を終了のイベントで戻す | 変更したまま終了する: 同じコンソールの親の 5.1 にも残る |
| 5.1 の外部コマンドの文字コード | `Invoke-Utf8Native` の間だけ UTF-8 にし、`finally` で戻す | 常に UTF-8: `ipconfig`・`whoami` などが英語になり、手順書を貼る窓の出力が変わる |
| winget の補完 | 5.1・7 とも `Invoke-Utf8Native` で包み、引数内の `"` は 5.1 だけ二重にする。7 は PowerShell がエスケープする | 7 でも `"` を二重にする: 2026-11-07、PowerShell 7.6.9 では引用符を含む版の補完がオプションになった。Microsoft の例のまま文字コードを変える: 5.1 の窓にも変化が残る |
| 6 つの道具の補完 | 7 で控えを生成し、7 のプロファイルで読む | 起動のたびに生成: 6 つで約 0.3 秒掛かる |
| PSScriptAnalyzer・Pester | 7 に `Install-PSResource`、5.1 の場所へ 7 から `Save-PSResource -IncludeXml` | 5.1 の PowerShellGet と NuGet の提供者を先に更新する: 導入の手順が増える |
| 7 の予測 | `ListView` と CompletionPredictor。元は既定の `HistoryAndPlugin` | 既定の `InlineView` のまま: 履歴と補完の候補を一覧で見たいという選択 |
| PSFzf | 7 の Ctrl+T・Ctrl+R を押したときに読む | 起動のときに読む: 約 0.23 秒掛かる |
| 5.1 の PSReadLine | 2.4.5 を 7 から保存する。元の 2.0.0 は残す | 版を指定せずに導入: 貼り付けとキーの確認をした版にそろえられない |
| 短縮の関数 | 5.1・7 に eza の `ll`、7 に `err` | `ls`・`cat` を置き換える: 引数や出力の違いに気づきにくい |
| 更新の通知・テレメトリ | ユーザーの環境変数に `POWERSHELL_UPDATECHECK=Off`・`POWERSHELL_TELEMETRY_OPTOUT=1` | プロファイルに書く: 起動時の設定に間に合わない |
| 5.1 の starship・zoxide | 足さない | 起動とプロンプトのたびに外部コマンドが動く。SSH では scoop の shim が起動できないことがある |
| Microsoft.WinGet.CommandNotFound | 入れない | 打ち間違えのたびに winget の検索が走る。PowerToys の Command Not Found と同じもの |
| posh-git | 入れない | 利用者が選ばなかった。読み込みに時間が掛かり、プロンプトを starship と合わせる必要がある |
| 履歴の連続した重複の除去 | 既定の `HistoryNoDuplicates` を使う | 同じ設定を追加: 5.1・7 とも既定で有効 |
| 設定アプリの「詳細設定」→「PowerShell」 | この項では扱わない | 実行ポリシーを RemoteSigned にするスイッチ。5.1 ではプロファイルを読み込める実行ポリシーが必要で、7 では[PowerShell 7 のプロファイルを設定する](#powershell-7-のプロファイルを設定する)の手順 5 で扱う |

**参照**

- [winget の補完 — Microsoft Learn](https://learn.microsoft.com/en-us/windows/package-manager/winget/tab-completion) — `Register-ArgumentCompleter -Native` と `winget complete` の引数
- [about_Character_Encoding — Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding?view=powershell-7.6) — 5.1・7 のファイルの文字コードと、外部コマンドへ渡す `$OutputEncoding`
- [Save-PSResource — Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.psresourceget/save-psresource?view=powershellget-3.x) — 保存先・版・`-IncludeXml`・`-TrustRepository`
- [Get-InstalledPSResource — Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.psresourceget/get-installedpsresource?view=powershellget-3.x) — `Get-PSResource` の別名・保存先・範囲の指定
- [Update-PSResource — Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.psresourceget/update-psresource?view=powershellget-3.x) — 最新版の保存・古い版の保持
- [Set-PSReadLineOption の PredictionViewStyle — Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlineoption?view=powershell-7.6#-predictionviewstyle) — `InlineView` と `ListView`
- [about_Environment_Variables — Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables?view=powershell-7.6#powershell-environment-variables) — テレメトリ・更新の通知を止める値と、PowerShell の起動前の設定
- [kelleyma49/PSFzf](https://github.com/kelleyma49/PSFzf) — PSReadLine のパスの選択と履歴の選択、キーの割り当て
- [PowerShell/CompletionPredictor](https://github.com/PowerShell/CompletionPredictor) — PSReadLine の補完の予測のプラグイン。PowerShell 7.2 以降・PSReadLine 2.2.2 以降が対象
- [pester/Pester](https://github.com/pester/Pester) — PowerShell のテストとモック
- [PowerShell/PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) — PowerShell の静的検査

- 検証記録（`docs/verification/shell-terminal.md`）

</details>

---
