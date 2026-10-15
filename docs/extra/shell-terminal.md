# シェルと端末のセットアップ（AlmaLinux 10・Windows 11）の注意点

[手順書](../shell-terminal.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shell-terminal.md)・[参考資料](../reference/shell-terminal.md)

- 手順書の手順は、番号付きリストを持つ見出し（項）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順を指す
- 2026-10-15 に、2 冊の注意点（`extra/almalinux-setup.md`・`extra/windows-setup.md`）から、移した項の箇条を移した。本文は変えていない
- ロールバックは、ほかの道具と一緒に「上から順に戻す」並びに入っているので、2 冊のロールバックに残した
  - AlmaLinux 10: シェルのツール・`~/.inputrc`・共通の bash 設定は[AlmaLinux 10 のセットアップのロールバックの「シェルのツールと bash の設定を戻す」](almalinux-setup.md#シェルのツールと-bash-の設定を戻す)、デスクトップの等幅のフォントと Ctrl+Alt+T・WezTerm・HackGen Console NF は[「端末とエディタを消す」](almalinux-setup.md#端末とエディタを消す)の手順 6〜10、bash-completion は[「Homebrew と bash-completion を消す」](almalinux-setup.md#homebrew-と-bash-completion-を消す)の手順 4
  - Windows 11: 自分用の WezTerm の設定と共通の bash 設定は[Windows 11 のセットアップのロールバックの「Git Bash の設定を戻す」](windows-setup.md#git-bash-の設定を戻す)の手順 7・8、starship・zoxide・fzf・eza・bat は[「エディタとシェルのツールを消す」](windows-setup.md#エディタとシェルのツールを消す)の手順 7〜9、WezTerm は[「OpenSSH・Git for Windows・Firefox・WezTerm を外す」](windows-setup.md#opensshgit-for-windowsfirefoxwezterm-を外す)の手順 8、HackGen Console NF は[「HackGen Console NF を消す」](windows-setup.md#hackgen-console-nf-を消す)の手順 1〜3
  - PowerShell 7 のプロファイルと Windows Terminal の設定は、手順書のそれぞれの項の戻す手順で戻す

## 注意点

- **`~/.inputrc` を作ったら `$include /etc/inputrc` を忘れない**: 無いと Home / End / Delete / Ctrl+矢印が効かなくなる
- **`globstar` は `rm` でも効く**: `rm **` はサブディレクトリの中まで消す。`**` を打つ前に `echo **` で見る
- **`autocd` は、ディレクトリと同じ名前のコマンドが無いときだけ**: コマンドの探索が先で、見つからなかったときにディレクトリとして試す
- **`show-all-if-ambiguous` は候補が多いと長い一覧になる**: `ls /usr/share/<Tab>` のような場所では、既定と同じく `Display all 123 possibilities? (y or n)` と聞かれる
- **starship・zoxide・fzf の初期化は、共通の bash 設定が読む**: `brew install` だけではプロンプトも `z` も変わらない。共通設定が starship → WezTerm → zoxide、Homebrew の補完 → fzf の順に読む。端末を開き直すと効く
  - WezTerm のシェル統合の `A` / `B` は失われる: `PS1` が毎回作り直されるため。並びによらない（[bash の参考資料の読む順番](https://github.com/ryo-aoki-pc/bash/blob/main/docs/reference/readme.md#読む順番)）
  - root は別に導入する: root 自身にも bash の共通設定を導入した場合にだけ、root のシェルで初期化される（[Homebrew を root のシェルでも使う](../almalinux-setup.md#homebrew-を-root-のシェルでも使う)）
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
- **eza のアイコンには Nerd Font が要る**: `--icons=always` はグリフを出すだけなので、フォントが無い端末では豆腐になる（[HackGen Console NF](../shell-terminal.md#hackgen-console-nf)）
- **eza の `--git` は大きなリポジトリで遅くなる**: 毎回 git の状態を引くため。気になるなら `--no-git`、リポジトリの一覧だけなら `--git-repos-no-status`
- **bat を EPEL 版と二重に入れない**: どちらも `bat` という名前で、PATH の先頭にある Homebrew 版が勝つ
- **bat のテーマの見え方は端末に依存する**: `ansi` 以外を選ぶと端末の配色とぶつかることがある。true color が出るかは端末側の設定次第
- **BaseOS の tmux と混ぜない**: 同じソケットを使うので、版の違うクライアントからはセッションにつなげない（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shell-terminal.md#tmux-実施手順--手順-2-補足-baseos-の-tmux-と並べたとき)）
- **tmux のセッションがログアウトしても残るのは、`KillUserProcesses=no` のとき**: AlmaLinux 10 の既定。`yes` にしたホストでは、ログアウトでセッションも止まるはず
- **PC を再起動すると、tmux のセッションも中のコマンドも消える**: 起動時に始め直す仕組みは、本書では作らない
- **HackGen Console NF: 自分のユーザーにしか入らない**: 置き場所が `~/.local/share/fonts` なので、別のユーザーや root で動くアプリからは見えない
- **HackGen Console NF: `unzip` が要る**: Homebrew の formula（ボトル）は `unzip` 無しで入るが、zip で配られる cask は展開に `unzip` を使う
- **HackGen Console NF: Console 版は記号が半角になる**: 矢印などが 1 セル幅で出る（`wezterm ls-fonts --text '→'` で `cells=1`）
  - Console ではない通常版（HackGen / HackGen35）は NF 版の zip に入っておらず、NF 無しの cask `font-hackgen` にある
- **HackGen Console NF: NF 版と NF 無しの版は別の cask**: `font-hackgen-nerd`（Console の 2 ファミリー × NF）と `font-hackgen`（4 ファミリー、アイコン無し）
  - ファミリー名は NF 版だけ末尾に ` NF` が付く
- **HackGen Console NF: ファミリー名は `HackGen Console NF`**（スペース入り）。ファイル名（`HackGenConsoleNF-Regular.ttf`）や PostScript 名（`HackGenConsoleNF-Regular`）とは違う。アプリの設定にはファミリー名を書く
- **HackGen Console NF: 等幅だけを一覧に出すアプリ**: fontconfig はこのフォントを `spacing=90`（`dual`）と見なす
- **HackGen Console NF: GNOME の端末や VS Code など WezTerm 以外のアプリ**: それぞれの設定でファミリー名 `HackGen Console NF` を指定する
- **HackGen Console NF: Powerline の記号**: WezTerm は `U+E0B0` などの一部の記号を既定で自分で描く（`custom_block_glyphs`）。ほかの端末ではフォントのグリフが使われる
- **WezTerm: EL9 向けバイナリを EL10 で使っている。** 作者はこの組み合わせを保証していない
  - いまは EL9/EL10 のライブラリ soname がすべて一致しているので動く
  - 将来 COPR 側のビルド環境（EL9）と EL10 の間で soname が食い違えば、`dnf upgrade` が依存関係で止まるか、入っても起動しなくなる
  - 止まったときは `dnf upgrade --exclude='wezterm*'` で他を先に上げ、COPR に `epel-10` chroot が追加されていないか[プロジェクトページ](https://copr.fedorainfracloud.org/coprs/wezfurlong/wezterm-nightly/)を見る
  - 追加されていたら、`sudo dnf copr remove wezfurlong/wezterm-nightly` → `sudo dnf copr enable wezfurlong/wezterm-nightly`（chroot 省略）で乗り換えられる
- **WezTerm: nightly は毎日変わる。** `dnf upgrade` のたびに WezTerm も更新される
  - 安定版に固定したければ、COPR ではなく GitHub Releases の安定版 rpm（`wezterm-<version>-1.centos9.rpm`、こちらも EL10 向けは無い）か Flathub を使う
- **WezTerm: `TERM` は既定の `xterm-256color` のまま**。EL10 の `ncurses-base` に `wezterm` の terminfo は無い（`infocmp wezterm` → rc=1、`ncurses-term` も未導入）

  設定で `term = "wezterm"` にするなら、先に公式ドキュメントの手順で terminfo を入れる:

  ```bash
  tempfile=$(mktemp) \
    && curl -o "$tempfile" https://raw.githubusercontent.com/wezterm/wezterm/main/termwiz/data/wezterm.terminfo \
    && tic -x -o ~/.terminfo "$tempfile" \
    && rm "$tempfile"
  ```

- **WezTerm: `/etc/profile.d/wezterm.sh` は全ユーザーの対話シェルに読み込まれる。** WezTerm 以外の端末でも OSC シーケンスを出す（大半の端末は無視する）
  - `bash-preexec` を内蔵しているので、`PROMPT_COMMAND` や `DEBUG` trap を自前で使っている環境では干渉に注意
  - 無効化は `WEZTERM_SHELL_SKIP_ALL=1`。自分用の WezTerm の設定（「WezTerm」の手順 5）を使うなら、止めない（その docs/install.md の注意点）
- **WezTerm: 既存の `_copr:...yazi.repo` など EL10 向け COPR と混在させても問題ない。** repo ごとに `baseurl` の chroot が違うだけ
- **PSReadLine の Emacs モードは、それより前に付けたキーを既定に戻す**: EditMode の行を、キーの割り当てより前に置く。Ctrl+V は `Paste` を割り当て直す。開いている窓では切り替えず、新しい窓で確かめる
  - [PowerShell 7 で Emacs モードを使う](../shell-terminal.md#powershell-7-で-emacs-モードを使う)を戻しても、印の無い EditMode の行は残る。その行が Emacs なら Windows モードへは戻らない
- **Windows PowerShell 5.1 のキーは、手順書を貼る管理者の conhost の窓にも効く**: 任意の[キー操作の設定](../shell-terminal.md#windows-powershell-51-のキー操作を変える)で変える。先に全ユーザーのプロファイルが付けたキーも EditMode で既定に戻る
  - Ctrl+V は `Paste`、Ctrl+Enter は[貼り付けの設定](../windows-setup.md#貼り付けの設定)の `AddLine` を使う
  - conhost の右クリックの貼り付けは、LF を Ctrl+Enter として送る。貼り付けの設定の `AddLine` の行が、EditMode の行より後に残っている必要がある（任意の項の手順 2 は、その順に入れる）。Emacs モードでの右クリックと複数行の貼り付けは、実機では確かめていない
- **Windows Terminal の copyOnSelect は、選んだだけでクリップボードを置き換える**: 手順書からコピーしたブロックも消え、右クリックが貼り付けになる。任意の[選択のコピー](../shell-terminal.md#windows-terminal-で選択した文字をコピーする)で true にできる
  - 複数行の警告を切っていると、管理者の Windows Terminal の窓でも複数行が確かめずに動くおそれがある
  - キー単位で false に戻しても、親の[設定の戻し](../shell-terminal.md#windows-terminal-のフォントと貼り付けの警告を変える)の手順 6 を後で行うと、控えの値が戻る
- **Windows の starship.toml は Git Bash と PowerShell 7 で共有する**: 任意の[表示の設定](../shell-terminal.md#windows-11-で-starship-の表示を変える)は、既存の配色・プリセットも置き換える。控えを書き戻すと、両方のシェルに効く
  - PowerShell 7 では、[プロファイルの設定](../shell-terminal.md#powershell-7-のプロファイルを設定する)の手順 2 の starship の行が必要。`STARSHIP_CONFIG` を別の場所に向けている場合、このファイルは読まれない
- **Windows Terminal に複数行を貼ると「警告」が出ることがある**: 管理者ではない窓（Windows Terminal）に複数行のブロックを貼ると出るはず（コードからの推測。確かめていない）。出たら「強制的に貼り付け」を押す
  - 出さないなら、[Windows Terminal のフォントと貼り付けの警告を変える](../shell-terminal.md#windows-terminal-のフォントと貼り付けの警告を変える)の手順 4
- **HackGen Console NF: Windows 11 では、自分のユーザーのフォントが見えないアプリがある**: ユーザーごとのフォントは Windows 10 1809 からで、古いアプリには見えないことがある。そのアプリだけ、PC 全体に入れ直す（本書では扱わない）
- **HackGen Console NF: Windows 11 では、読み込まれているフォントのファイルを置き換えられない**: 入れ替え（更新）と削除は、登録を消してサインインし直してから行う（[HackGen Console NF を消す](windows-setup.md#hackgen-console-nf-を消す)）
- **WezTerm: Windows 11 のインストーラと実行ファイルには署名が無い**: 本物かどうかは確かめられず、`.sha256` で分かるのは壊れていないことまで（[選択した方針](../reference/shell-terminal.md#wezterm-選択した方針)）
  - ブラウザで取得したファイルでは SmartScreen が警告することがある。本書では `curl.exe` で取得する
- **WezTerm: Windows 11 の WezTerm には `VCRUNTIME140.dll` が要る**: インストーラは入れない（[「WezTerm」の手順 3](../shell-terminal.md#windows-11-で-wezterm-を入れる)）
- **WezTerm: Windows 11 の nightly は自分では上がらず、winget・scoop の管理にも乗らない**: 上げるのは[Git for Windows・Firefox・WezTerm を上げる](../windows-setup.md#git-for-windowsfirefoxwezterm-を上げる)
- **WezTerm: Windows 11 では、stable と nightly が同じ登録を使う**: インストーラの `AppId` が同じなので、PC に入るのはどちらか 1 つ。後から入れた方が上書きするはず
- **WezTerm: Windows 11 で管理者の窓から起動すると、WezTerm も管理者で動く**: 起動はスタートメニューから行う
