# yazi 最新版インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は scoop）

## 実施手順

- [検証記録](verification/yazi.md)・[参考資料](reference/yazi.md)・[ロールバックと注意点](extra/yazi.md)

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（scoop で入れる。管理者ではない Windows PowerShell 5.1 に貼る）
> - **前提**: [AlmaLinux 10 の初期設定の手順 46〜48](almalinux-setup.md#実施手順) で Homebrew を入れてあること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わない）
> - **手順 4 で TUI が開く**。`q` で終了してから、ほかのコマンドを貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 手順の後: 設定を書く場所と、自分用の設定（`ryo-aoki-pc/yazi`）への案内は[設定ファイル](#設定ファイル)。以後は[更新](#更新)・[ロールバック](extra/yazi.md#ロールバック)

1. 変数を設定する。

   ```bash
   YAZI_EXTRAS="ffmpeg-full sevenzip jq poppler fd ripgrep fzf resvg imagemagick-full font-symbols-only-nerd-font"   # プレビューと検索に使う。空にすると yazi 本体だけ
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'YAZI_EXTRAS = %s\n' "${YAZI_EXTRAS}"
   ```

   - **編集が必須の変数は無い**
   - 最小構成にするなら、`YAZI_EXTRAS` を空にする
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. brew で yazi と、プレビュー・検索に使うツールを入れる。

   ```bash
   brew install yazi ${YAZI_EXTRAS}
   ```

   - 確認が出たら表示された導入予定を確かめて `y` と答え、処理が終わってプロンプトに戻ってから次の手順を貼る（[Homebrew の注意点](extra/almalinux-setup.md#注意点)）

1. 共通設定を読み直し、y 関数を確かめる。

   ```bash
   . ~/.bashrc
   printf '\n\033[7m 確認 \033[0m\n'
   type -t y
   ```

   - `function` が出ればよい。`~/.bashrc` への関数の追記は不要

1. yazi が入ったか確かめ、`y` で起動する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   yazi --version
   ya --version
   brew list --versions yazi
   y
   ```

   - `Version: 26.9.1 (Homebrew ...)`、`Triple: aarch64-unknown-linux-gnu` のように出る
   - プレビューを確かめるには、PDF・動画・画像・書庫のあるディレクトリで右ペインを見る
   - 画像プレビューは端末側の対応が要る（[注意点](extra/yazi.md#注意点)）
   - 画面が出たら `q` で終了する
   - **ほかのコマンドは、`q` で終了してから貼る**（続けて貼ると yazi への操作として食われる）

---

## 設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は `~/.config/yazi/` で、ファイル名は `yazi.toml`（全般）/ `keymap.toml`（キー割り当て）/ `theme.toml`（配色）
- Windows 11 の置き場所は `%APPDATA%\yazi\config\`（Windows の yazi は `XDG_CONFIG_HOME` を見ない。別の場所にするなら `YAZI_CONFIG_HOME` に絶対パスを入れる）
  - 状態は `%APPDATA%\yazi\state`、キャッシュは `%LOCALAPPDATA%\yazi`
  - yazi が読む場所は `ya env` の `Config` の行で確かめられる（[Windows 11 で使う](#windows-11-で使う)の手順 6）
  - この節の手順 1 は AlmaLinux 10 のもの。Windows 11 の Git Bash に貼っても、yazi は `~/.config/yazi` を読まない
- **既定値のファイルは配布物に入っていない**。変更する項目だけを設定ファイルに書く
- 既定値は[公式ドキュメントの Configuration](https://yazi-rs.github.io/docs/configuration/overview/) か、リポジトリの `yazi-config/preset/` を見る
- **自分用の設定**は [ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi) にある（上流の既定の設定を丸ごと置き、3 ペインの比率・行表示・独自のキー割り当てなどを変えた設定）
  - 入れ方は [README の「インストール」](https://github.com/ryo-aoki-pc/yazi#インストール)。`custom` ブランチを `~/.config/yazi` に clone する
  - Windows 11 の入れ方は、同じ [README の「インストール」](https://github.com/ryo-aoki-pc/yazi#インストール)の Windows の例（`custom` ブランチを `%APPDATA%\yazi\config` に clone する）。そこにある `YAZI_FILE_ONE` と VC++ のランタイムは、[Windows 11 で使う](#windows-11-で使う)の手順 3・5 で済んでいる
  - 足したキーは [設定のリポジトリの参考資料の「独自キーバインド」](https://github.com/ryo-aoki-pc/yazi/blob/custom/docs/reference/readme.md#独自キーバインド抜粋)、使う外部コマンドは [README の「依存コマンド」](https://github.com/ryo-aoki-pc/yazi#依存コマンド)
  - 外部コマンドのうち fd・ripgrep・fzf は手順 2 の `YAZI_EXTRAS` で入る（Windows 11 は[Windows 11 で使う](#windows-11-で使う)の手順 4。fzf の bash のキー操作は [AlmaLinux 10 の初期設定の手順 42〜53](almalinux-setup.md#実施手順) で入る）。エディタの nvim は [neovim.md](neovim.md)、zoxide は [AlmaLinux 10 の初期設定の手順 49](almalinux-setup.md#実施手順) で入れる
    - Windows 11 の Git Bash の fzf のキー操作と zoxide は、[Windows 11 の初期設定のシェルのツールを入れる（任意）](windows-setup.md#シェルのツールを入れる任意)で入る（zoxide は 0.9.9 に止める）
  - Windows 11 では、`O`（対話的に開く）の候補に Neovide も出る。選んで使うなら、Neovide（scoop の extras の `neovide`）を入れておく
  - この設定を入れるなら、この節の手順 1 は要らない（clone が `~/.config/yazi` を作る）

1. 設定を書くときは、空のディレクトリを作って変更したい項目だけを書く。

   ```bash
   mkdir -p ~/.config/yazi
   ```

---

## 更新

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 の更新](#windows-11-の更新)

1. brew で yazi を更新する。

   ```bash
   brew upgrade yazi
   ```

   - すべてまとめて上げるなら `brew upgrade`

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows のデスクトップで行う**。この節の手順 1 で**管理者ではない** Windows PowerShell（5.1）を開き、この節の手順 2〜6・9 と、[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/yazi.md#windows-11-のロールバック)のブロックをそこに貼る
>   - SSH のセッションには貼らない（Administrators の一員の SSH のセッションは管理者の権限で動き、scoop は自分のユーザーに入れるため）
> - 前提: [Windows 11 の初期設定の手順 16〜19 と手順 20・21](windows-setup.md#実施手順)（貼り付けの設定と scoop）。手順 16〜19 を通していなければ、ブロックは Ctrl+V で貼る
> - 前提: [git.md の Windows 11 で Git for Windows を入れる](git.md#windows-11-で-git-for-windows-を入れる)（`C:\Program Files\Git`）。yazi はファイルの種類の判定に、同梱の `C:\Program Files\Git\usr\bin\file.exe` を使う
> - 前提: Visual C++ のランタイム（`VCRUNTIME140.dll`。`yazi.exe` と `ya.exe` が使い、scoop は入れない）。この節の手順 3 で確かめ、無ければ [wezterm-nightly.md の Windows 11 で使う](wezterm-nightly.md#windows-11-で使う)の手順 3 を管理者の Windows PowerShell で行う
> - **この節の手順 7 で WezTerm の Git Bash のタブを開き、手順 8 の `bash` のブロックはそこに貼る**。手順 8 と手順 9 で yazi の画面（TUI）が開く。`q` で閉じてから、ほかのブロックを貼る

- この節の手順 2 で変数を設定した PowerShell に、上から順にコードブロックを貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 自分用の設定（`ryo-aoki-pc/yazi`）はファイルを Neovim で開くので、先に [Neovim の Windows 11 で使う](neovim.md#windows-11-で使う)を通しておく
  - 上流の既定の設定では、Windows でファイルを開くエディタは VS Code の `code`（Windows の yazi は `EDITOR` を見ない。[参考資料](reference/yazi.md#windows-11-では-選択した方針)）
- zoxide（`Z` キー）を使うなら [Windows 11 の初期設定のシェルのツールを入れる（任意）](windows-setup.md#シェルのツールを入れる任意)で入れる（zoxide は 0.9.9 に止める。この節の `$YAZI_EXTRAS` には入れていない）
- アイコンは、端末のフォントを HackGen Console NF にする（入れるのは [hackgen.md の Windows 11 で使う](hackgen.md#windows-11-で使う)）
  - Windows Terminal のフォントにするのは [Windows 11 の初期設定の任意節](windows-setup.md#windows-terminal-のフォントと貼り付けの警告を変える任意)で、WezTerm は自分用の設定で変わる
- 手順の後: 置き場所と自分用の設定は[設定ファイル](#設定ファイル)。以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/yazi.md#windows-11-のロールバック)
- SSH のセッションで scoop の yazi を使うなら、[windows-openssh-server.md の scoop のツールを SSH のセッションで使う（任意）](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)
- この節のブロックは、Windows の実機で流していない（[検証記録](verification/yazi.md#windows-11-で使う-検証状況の記録)）

1. Windows で、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）

1. 変数を設定する。

   ```powershell
   $YAZI_EXTRAS = @('ffmpeg', '7zip', 'jq', 'poppler', 'fd', 'ripgrep', 'fzf', 'resvg', 'imagemagick')   # プレビューと検索に使う。@() にすると yazi 本体だけ
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'YAZI_EXTRAS = {0}' -f ($YAZI_EXTRAS -join ' ')
   ```

   - **編集が必須の変数は無い**
   - 最小構成にするなら、`$YAZI_EXTRAS = @()` にする
   - 減らして 1 つだけにするときも、`@('fd')` の形のままにする
   - 最後の行で値を読み戻して確かめる
   - **新しい PowerShell を開いたら**、先にこのブロックを貼り直す

1. 管理者ではないことと、scoop・`file.exe`・VC++ のランタイム・ほかの yazi・設定を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     PowerShell  = $PSVersionTable.PSVersion.ToString()
     Admin       = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop       = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git         = (Get-Command git -ErrorAction SilentlyContinue).Source
     FileExe     = Test-Path -LiteralPath 'C:\Program Files\Git\usr\bin\file.exe'
     VCRuntime   = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
     Yazi        = (Get-Command yazi -All -ErrorAction SilentlyContinue).Source -join ', '
     YaziFileOne = [Environment]::GetEnvironmentVariable('YAZI_FILE_ONE', 'User')
     Config      = Test-Path -LiteralPath "$env:APPDATA\yazi\config"
   } | Format-List
   ```

   - `PowerShell : 5.1.…`・`Admin : False`・`FileExe : True` が出ればよい。`Admin : True` なら、窓を閉じてこの節の手順 1 から
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に [Windows 11 の初期設定の手順 20・21](windows-setup.md#実施手順) で入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でないか、`FileExe : False` なら、先に [git.md の Windows 11 で Git for Windows を入れる](git.md#windows-11-で-git-for-windows-を入れる)
   - `VCRuntime : False` なら、[wezterm-nightly.md の Windows 11 で使う](wezterm-nightly.md#windows-11-で使う)の手順 3 を管理者の Windows PowerShell で行ってから、この手順を貼り直す
   - `Yazi` が空なら、yazi は入っていない。`C:\Users\<WIN_USER>\scoop\shims\yazi.exe` だけなら、もう scoop で入っている。ほかの場所が出たら、外してから始める
   - `YaziFileOne` が空なら、この節の手順 5 で入れる。別の値なら、この節の手順 5 で Git for Windows の `file.exe` に上書きされる（元の値は控えておく。[Windows 11 のロールバック](extra/yazi.md#windows-11-のロールバック)の手順 2 で戻す）

1. scoop で yazi と、プレビュー・検索に使うツールを入れる。

   ```powershell
   if ($null -eq $YAZI_EXTRAS) { Write-Error '中断: この節の手順 2 の $YAZI_EXTRAS が無い。手順 2 を貼り直す' } else { scoop install yazi @YAZI_EXTRAS }
   ```

   - アプリごとに `'yazi' (26.9.1) was installed successfully!` の形の行が出ればよい。入っていたものは `is already installed.` の形の行を出して飛ばす
   - `'ripgrep' suggests installing 'extras/vcredist2022'.` などの `suggests installing` の行は、入れなくてよい
   - `中断:` と出たら、何も入れていない（新しい窓では、この節の手順 2 を貼り直す。yazi 本体だけにするなら `$YAZI_EXTRAS = @()`）
   - scoop の `file` は入れない

1. ユーザーの環境変数 `YAZI_FILE_ONE` を Git for Windows の `file.exe` にする。

   ```powershell
   if (-not (Test-Path -LiteralPath 'C:\Program Files\Git\usr\bin\file.exe')) { Write-Error '中断: C:\Program Files\Git\usr\bin\file.exe が無い（git.md の Windows 11 で Git for Windows を入れる）' } else {
     [Environment]::SetEnvironmentVariable('YAZI_FILE_ONE', 'C:\Program Files\Git\usr\bin\file.exe', 'User')
     $env:YAZI_FILE_ONE = [Environment]::GetEnvironmentVariable('YAZI_FILE_ONE', 'User')
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'YAZI_FILE_ONE = {0}' -f $env:YAZI_FILE_ONE
   }
   ```

   - `YAZI_FILE_ONE = C:\Program Files\Git\usr\bin\file.exe` が出ればよい（何度貼ってもよい）
   - 今の窓にも入れる。ほかの窓は開き直してから効く（WezTerm は新しいタブから）
   - `中断:` と出たら、何も変えていない

1. 版と、yazi から見た環境を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   yazi --version
   ya --version
   ya env
   ```

   - `yazi --version` は `Version: 26.9.1 (…)` と、括弧の中が `windows-x86_64` の `Triple` の行、`ya --version` は `Version: 26.9.1 (…)` の行が出ればよい
   - 何も出さずに終わるか、`VCRUNTIME140.dll` が見つからない旨のシステム エラーの窓が出たら、VC++ のランタイムが無い（この節の手順 3 の `VCRuntime`）
     - 窓が出たら、OK で閉じる
   - `ya env` の `Config` の各行に `C:\Users\<WIN_USER>\AppData\Roaming\yazi\config\…` が出る
     - 設定のフォルダーが無ければ、パスが見つからない旨と `os error 3` が出る
     - フォルダーはあってファイルが無い行は、ファイルが見つからない旨と `os error 2`
   - `Variables` の `YAZI_FILE_ONE` が `Some("C:\\Program Files\\Git\\usr\\bin\\file.exe")` ならよい
   - `Dependencies` の `file` に版が出て、最後の `Routine` の `` `file -bL --mime-type` `` が `text/plain` ならよい
   - `Dependencies` に、`$YAZI_EXTRAS` で入れたもの（ffmpeg・pdftoppm・magick・fzf・fd・rg・7z・resvg・jq）の版が出る

1. WezTerm（自分用の設定）と Git Bash の共通の bash 設定を入れたときだけ、WezTerm で新しいタブを開く。

   - 自分用の WezTerm の設定では、新しいタブで Git Bash が開く
   - 前提は、[wezterm-nightly.md の Windows 11 で使う](wezterm-nightly.md#windows-11-で使う)と自分用の WezTerm の設定（[設定ファイル](wezterm-nightly.md#設定ファイル)）、[README の共通の bash 設定を先に入れる](../README.md#共通の-bash-設定を先に入れる)（Git Bash で）を通してあること
   - どちらかを通していなければ、この節の手順 7・8 は飛ばす
   - **次の手順は、開いた Git Bash のタブに貼る**（bash の構文なので、PowerShell には貼らない）

1. WezTerm（自分用の設定）と Git Bash の共通の bash 設定を入れたときだけ、そのタブで `y` を確かめ、yazi を開く。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   type -t y
   y
   ```

   - `function` が出ればよい（[実施手順](#実施手順)の手順 3 と同じ）
   - 最後の `y` で yazi が開く。別のフォルダーへ移って `q` で閉じると、Git Bash もそのフォルダーへ移る（`Q` なら移らない）
   - **次の手順は、yazi を閉じて、この節の手順 1 の PowerShell に戻ってから貼る**（続けて貼ると yazi への操作として食われる）

1. yazi を起動して確かめる。

   ```powershell
   yazi
   ```

   - プレビューを確かめるには、PDF・動画・画像・書庫のあるフォルダーで右のペインを見る
   - 画像のプレビューは、WezTerm（nightly）か Windows Terminal（1.22.10352.0 以降）の中で出る。conhost の窓では出ない
   - [Windows 11 の初期設定の手順 30](windows-setup.md#実施手順)で既定の端末を Windows Terminal にした PC では、この節の手順 1 の窓も Windows Terminal で開く
   - `q` で閉じる
   - **ほかのブロックは、`q` で閉じてから貼る**（続けて貼ると yazi への操作として食われる）

---

## Windows 11 の更新

- この節の手順 1 は、[Windows 11 で使う](#windows-11-で使う)の手順 1 と同じ管理者ではない Windows PowerShell（5.1）に貼る
- [Windows 11 の初期設定の更新](windows-setup.md#更新)の手順 1・2（`scoop update *`）でも上がる。`$YAZI_EXTRAS` で入れたツールも、そこで上がる
- 自分用の設定（`ryo-aoki-pc/yazi`）は上流の版に合わせてある。yazi の版が上がったら、その [README の「上流の新しい版に追従する」](https://github.com/ryo-aoki-pc/yazi#上流の新しい版に追従する)で設定も追う
- SSH のセッションで使っているなら、上げた後に [windows-openssh-server.md の scoop のツールを SSH のセッションで使う（任意）](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の手順 1 を、管理者の Windows PowerShell で貼り直す

1. yazi をすべて閉じてから、scoop で上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop update
   scoop update yazi
   yazi --version
   ```

   - `Scoop was updated successfully!` の後に、新しい版があれば `'yazi' (<版>) was installed successfully!` が出る
   - 新しい版が無ければ、`yazi: <版> (latest version)` と `Latest versions for all apps are installed!` が出る（何も変えない）
   - `Running process detected, skip updating.` が出たら、動いている yazi を閉じてから貼り直す
   - 最後に今の版を含む行が出る
