# lazygit 最新版インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は scoop）

## 実施手順

- [検証記録](verification/lazygit.md)・[参考資料](reference/lazygit.md)

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（scoop で入れる。管理者ではない Windows PowerShell 5.1 に貼る）
> - **前提**: [AlmaLinux 10 の初期設定の手順 46〜48](almalinux-setup.md#実施手順) で Homebrew を入れてあること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。Homebrew の導入・管理は一般ユーザーで行い、設定も自分のホームに書く
> - **手順 2 で Homebrew の確認が出る場合がある**。答えて導入が完了してから手順 3 を貼る
> - **手順 3 で TUI が開く**。`q` で終了してから、ほかのコマンドを貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: 設定を書く場所と、自分用の設定（`ryo-aoki-pc/lazygit`）への案内は[設定ファイル](#設定ファイル)。以後は[更新](#更新)・[ロールバック](#ロールバック)

1. 変数を設定する。

   ```bash
   LG_EDITOR=nvim                  # lazygit の e キーで開くエディタ。vim / code など。<LG_EDITOR>
   printf 'LG_EDITOR = %s\n' "${LG_EDITOR}"
   ```

   - **編集が必須の変数は無い**。`e` キーで開くエディタを変えたいときだけ書き換える
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. brew で lazygit を入れる。

   ```bash
   brew install lazygit
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. lazygit が入ったか確かめ、git リポジトリで起動してみる。

   ```bash
   lazygit --version
   brew list --versions lazygit
   command -v lazygit
   ```

   - `build source=Homebrew, version=0.65.1, os=linux, arch=arm64` のように出る
   - 次に、git リポジトリのルートに `cd` してから `lazygit` を起動して確認する（`q` で終了）
   - 初回に `Thanks for using lazygit...` の案内が出たら Enter で閉じる。ファイル・変更差分・ブランチ・コミットの一覧が出ればよい
   - **注意**: git 管理下でないディレクトリで起動すると、リポジトリを作るか聞かれる
   - **ほかのコマンドは、`q` で終了してから貼る**（続けて貼ると lazygit への操作として食われる）

---

## 設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は `~/.config/lazygit/config.yml`（`lazygit --print-config-dir` で確認できる）
- Windows 11 の置き場所は `%LOCALAPPDATA%\lazygit\config.yml`（`%APPDATA%\lazygit\config.yml` があれば、そちらも見つける）。状態ファイル `state.yml` も同じフォルダーに入る（[Windows 11 で使う](#windows-11-で使う)の手順 5 で確かめる）
  - この節の手順 1 は AlmaLinux 10 のもの。Windows 11 の Git Bash に貼っても、lazygit は `~/.config/lazygit` を読まない
- **自分用の設定**は [ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit) にある（公式の既定の全項目に、あいまい検索・Nerd Fonts のアイコン・マウス無効などの変更を載せた `config.yml`）
  - 入れ方は [設定の導入方法](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/setup.md#導入方法)。clone した `config.yml` を `~/.config/lazygit/config.yml` にリンクする
  - Windows 11 の入れ方は、同じ [設定の導入方法](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/setup.md#導入方法)の Windows の例（シンボリックリンクではなく、`%LOCALAPPDATA%\lazygit` に直接 clone する。元に戻すブロックもそこにある）
  - 何を変えたかは [設定のリポジトリの参考資料の「主な設定内容」](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/reference/readme.md#主な設定内容)
  - アイコンに Nerd Fonts が要る（`gui.nerdFontsVersion: "3"`）。端末のフォントを HackGen Console NF（[hackgen.md](hackgen.md)）にする
    - Windows 11 で入れるのは [hackgen.md の Windows 11 で使う](hackgen.md#windows-11-で使う)。Windows Terminal のフォントにするのは [Windows 11 の初期設定の任意節](windows-setup.md#windows-terminal-のフォントと貼り付けの警告を変える任意)で、WezTerm は自分用の設定で変わる
  - 差分の表示に delta を使う。delta は [git-delta.md](git-delta.md) で入れる（lazygit 側の設定は、その[lazygit と組み合わせる（任意）](git-delta.md#lazygit-と組み合わせる任意)）
    - Windows 11 は [git-delta.md の Windows 11 で使う](git-delta.md#windows-11-で使う)の手順 2・3（VC++ のランタイムも、その手順 2 で確かめる）。Windows の設定例の引用符は [delta の Windows 向け設定](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/diff-renderers.md#windows-で使う場合)
  - `e` キーで開くエディタは、`EDITOR` などから自動で決まる（手順 1 の `LG_EDITOR` は使わない。[neovim.md の既定のエディタにする](neovim.md#既定のエディタにする任意)）
    - Windows 11 で Windows PowerShell から起動するなら、[neovim.md の既定のエディタにする（任意）](neovim.md#既定のエディタにする任意)の手順 2 で、ユーザーの環境変数 `EDITOR` を `nvim` にする
  - この設定を入れるなら、この節の手順 1 は貼らない（リンク先の clone したファイルを使う）
- この節の手順 1 は、設定が無いか空の通常ファイルの場合だけ作成する。既存の設定がある場合は、`os:` があればその中の `edit` を編集し、無ければ `os:` を 1 つだけ追加する
- `LG_EDITOR` に指定したエディタを先に入れる。既定の `nvim` は [Neovim](neovim.md) を通す

1. エディタだけを指定する、最小の `config.yml` を書く。

   ```bash
   if [ -z "${LG_EDITOR}" ]; then
     echo '中断: 手順 1 の LG_EDITOR が空のまま。値を入れて貼り直す' >&2
   elif ! command -v "${LG_EDITOR}" >/dev/null 2>&1; then
     echo '中断: LG_EDITOR のエディタが見つからない。導入するか値を直す' >&2
   elif [ -L ~/.config/lazygit/config.yml ] || [ -s ~/.config/lazygit/config.yml ]; then
     echo '中断: 設定がすでにある。既存の os 節へ edit を併合する' >&2
   else
     mkdir -p ~/.config/lazygit
     cat > ~/.config/lazygit/config.yml <<EOF
   os:
     edit: '${LG_EDITOR} {{filename}}'
   EOF
     lazygit --print-config-dir
   fi
   ```

   - 既定値の全体は `lazygit --config` で表示できる
   - アプリ内では `x` でキーバインド一覧が出る
   - `中断:` と出たら、何も書いていない

---

## 更新

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 の更新](#windows-11-の更新)

1. brew で lazygit を更新する。

   ```bash
   brew upgrade lazygit
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - **ほかのコマンドは、Homebrew の確認が出たら答え、更新が終わってから貼る**（続けて貼ると確認の答えとして食われる）

---

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)

1. brew で lazygit を消す。

   ```bash
   brew uninstall lazygit
   ```

   - `~/.config/lazygit/` と `~/.local/state/lazygit/` は残るので、要らなければ手で消す
   - 自分用の設定を clone していれば、その clone（README の例では `~/lazygit-config`）も残る

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows のデスクトップで行う**。この節の手順 1 で**管理者ではない** Windows PowerShell（5.1）を開き、この節の手順 2〜6 と、後ろの Windows 11 の 2 節（更新・ロールバック）のブロックをそこに貼る
>   - SSH のセッションには貼らない（Administrators の一員の SSH のセッションは管理者の権限で動き、scoop は自分のユーザーに入れるため）
> - 前提: [Windows 11 の初期設定の手順 16〜19 と手順 20・21](windows-setup.md#実施手順)（貼り付けの設定と scoop）。手順 16〜19 を通していなければ、ブロックは Ctrl+V で貼る
> - 前提: [git.md の Windows 11 で Git for Windows を入れる](git.md#windows-11-で-git-for-windows-を入れる)（`C:\Program Files\Git`）。lazygit は git を呼び、scoop の extras のバケットを足すのにも git が要る
> - **この節の手順 6 で lazygit の画面（TUI）が開く**。`q` で閉じてから、ほかのブロックを貼る

- 上から順にコードブロックを貼る。変数は無い（[実施手順](#実施手順)の手順 1 の `LG_EDITOR` は AlmaLinux 10 だけで使う）
- 先に [Neovim の Windows 11 で使う](neovim.md#windows-11-で使う)を通しておく（`e` キーで開くエディタ）
- 自分用の設定（`ryo-aoki-pc/lazygit`）を使うなら、差分の表示に使う delta も先に入れておく（[git-delta.md の Windows 11 で使う](git-delta.md#windows-11-で使う)の手順 2・3）
- 手順の後: 置き場所と自分用の設定は[設定ファイル](#設定ファイル)。PowerShell から起動した lazygit の `e` キーで Neovim を開くなら、[neovim.md の既定のエディタにする（任意）](neovim.md#既定のエディタにする任意)の手順 2。以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](#windows-11-のロールバック)
- SSH のセッションで scoop の lazygit を使うなら、[windows-openssh-server.md の scoop のツールを SSH のセッションで使う（任意）](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)
- この節のブロックは、Windows の実機で流していない（[検証記録](verification/lazygit.md#windows-11-で使う-検証状況の記録)）

1. Windows で、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）

1. 管理者ではないことと、scoop・git・extras のバケット・ほかの lazygit を確かめる。

   ```powershell
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     Extras     = if (Get-Command scoop -ErrorAction SilentlyContinue) { [bool](scoop bucket list | Where-Object Name -eq 'extras') } else { $false }
     Lazygit    = (Get-Command lazygit -All -ErrorAction SilentlyContinue).Source -join ', '
   } | Format-List
   ```

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`True` なら、窓を閉じてこの節の手順 1 から
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に [Windows 11 の初期設定の手順 20・21](windows-setup.md#実施手順) で入れる
   - `Git` は `C:\Program Files\Git\cmd\git.exe` ならよい。空か違う場所なら、先に [git.md の Windows 11 で Git for Windows を入れる](git.md#windows-11-で-git-for-windows-を入れる)
   - `Lazygit` が空なら、lazygit は入っていない。`C:\Users\<WIN_USER>\scoop\shims\lazygit.exe` だけなら、もう scoop で入っている（自分用の Neovim の設定の導入でも入る）
   - ほかの場所（winget の `JesseDuffield.lazygit` など）が出たら、混ざらないよう、外してから始める
   - `Extras : True` なら、extras のバケットはもうある。この節の手順 3 は飛ばす

1. extras のバケットが無いときだけ、scoop に足す。

   ```powershell
   scoop bucket add extras
   scoop bucket list
   ```

   - `The extras bucket was added successfully.` が出て、一覧に `main` と `extras` の行が出ればよい
   - extras は、ほかのアプリ（`vcredist2022`・`neovide` など）も使う

1. scoop で lazygit を入れる。

   ```powershell
   scoop install lazygit
   ```

   - `'lazygit' (0.66.0) was installed successfully!` の形の行が出ればよい（版は実行した日の最新）
   - `'lazygit' (0.66.0) is already installed.` の形なら、もう入っている（何も変えない）

1. 版と、設定の置き場所を確かめる。

   ```powershell
   lazygit --version
   lazygit --print-config-dir
   (Get-Command lazygit -All).Source
   ```

   - 1 行目に `version=0.66.0, os=windows, arch=amd64` を含む行が出ればよい（版は実行した日の最新）
   - 2 行目は `C:\Users\<WIN_USER>\AppData\Local\lazygit`（[設定ファイル](#設定ファイル)）
   - 最後は `C:\Users\<WIN_USER>\scoop\shims\lazygit.exe` の 1 行だけならよい

1. 確かめ用の git のリポジトリで、lazygit を起動して確かめる。

   ```powershell
   git init --quiet "$env:TEMP\lazygit-check"
   if (-not (Test-Path -LiteralPath "$env:TEMP\lazygit-check\.git")) { Write-Error '中断: 確かめ用のリポジトリ（%TEMP%\lazygit-check）を作れない' } else {
     Set-Location -LiteralPath "$env:TEMP\lazygit-check"
     lazygit
   }
   ```

   - `中断:` と出たら、lazygit は起動していない（git が呼べるかを、この節の手順 2 で確かめ直す）
   - 初回に `Thanks for using lazygit...` の案内が出たら Enter で閉じる
   - Status・Files・Branches・Commits などの欄が出ればよい（空のリポジトリなので、一覧は空）
   - ほかのリポジトリで確かめるなら、そのフォルダーに `Set-Location` してから `lazygit` を打つ（git 管理外のフォルダーで起動すると、リポジトリを作るか聞かれる）
   - **注意**: Windows PowerShell から起動した lazygit の `e` キーは、git の `core.editor` と環境変数 `VISUAL`・`EDITOR` などが無いと `vim` で開こうとして失敗する
     - [neovim.md の既定のエディタにする（任意）](neovim.md#既定のエディタにする任意)の手順 2 で `nvim` にし、新しい窓で lazygit を起動し直す（今の窓には入らない）
     - Git Bash から起動したときは、共通の bash 設定が `nvim` にしてある
   - `q` で閉じる
   - `%TEMP%\lazygit-check` は、要らなければ手で消す
     - この窓の今のフォルダーがそこにあるので、消す前に `Set-Location ~` で出る（今のフォルダーのままでは、使用中で消せない）
   - **ほかのブロックは、`q` で閉じてから貼る**（続けて貼ると lazygit への操作として食われる）

---

## Windows 11 の更新

- この節の手順 1 は、[Windows 11 で使う](#windows-11-で使う)の手順 1 と同じ管理者ではない Windows PowerShell（5.1）に貼る
- [Windows 11 の初期設定の更新](windows-setup.md#更新)の手順 1・2（`scoop update *`）でも上がる
- SSH のセッションで使っているなら、上げた後に [windows-openssh-server.md の scoop のツールを SSH のセッションで使う（任意）](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の手順 1 を、管理者の Windows PowerShell で貼り直す

1. lazygit をすべて閉じてから、scoop で上げる。

   ```powershell
   scoop update
   scoop update lazygit
   lazygit --version
   ```

   - `Scoop was updated successfully!` の後に、新しい版があれば `'lazygit' (<版>) was installed successfully!` が出る
   - 新しい版が無ければ、`lazygit: <版> (latest version)` と `Latest versions for all apps are installed!` が出る（何も変えない）
   - `Running process detected, skip updating.` が出たら、動いている lazygit（Neovim の中から開いたものも）を閉じてから貼り直す
   - 最後に今の版を含む行が出る

---

## Windows 11 のロールバック

- この節の手順 1 は、管理者ではない Windows PowerShell（5.1）に、lazygit をすべて閉じてから貼る
- `%LOCALAPPDATA%\lazygit`（設定と状態ファイル `state.yml`）は残るので、要らなければ手で消す。自分用の設定を clone していれば、その [設定の導入方法](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/setup.md#導入方法)の元に戻すブロックで、退避した設定に戻す
- extras のバケットは、ほかのアプリも使うので外さない（外すなら `scoop bucket rm extras`）
- 自分用の Neovim の設定（LazyVimStarter）は、`<leader>gg` で lazygit を使う。消すと、そのキーが使えなくなる

1. scoop で lazygit を消す。

   ```powershell
   scoop uninstall lazygit
   Get-Command lazygit -All -ErrorAction SilentlyContinue | Format-Table Source
   ```

   - `'lazygit' was uninstalled.` が出て、最後のコマンドが何も出さなければよい
   - `'lazygit' isn't installed.` なら、もう入っていない
   - 動いている lazygit があると、消さずに止まる（閉じてから貼り直す）

---

## 注意点

- **Homebrew 全般の注意は [AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)**: PATH の先頭が Homebrew になる、`sudo lazygit` はそのままでは使えない、など
  - RPM 版と両方入れると分かりにくくなるので、どちらか一方にする
- **COPR 経路は「有効化は成功するのに入らない」**: `dnf copr enable` が通っても、メタデータが取れなければ `dnf install` は `No match for argument` になるだけで、原因は警告行にしか出ない
  - COPR を使う前に `curl -sS -o /dev/null -w '%{http_code}\n' -L <chroot の repodata/repomd.xml>` で 200 が返るか確かめると早い
- **git が要る**: lazygit は git のラッパーなので、git の設定（`user.name` / `user.email`、認証）はそのまま効く
- **設定ファイルは自分で作る**: `lazygit --print-config-dir` が返すディレクトリは、初回起動時には空のことがある
- **Windows 11 では、winget の lazygit（`JesseDuffield.lazygit`）と両方入れない**: どちらが使われるかが `PATH` の順で決まり、分かりにくくなる。どちらか一方にする
- **Windows 11 の SSH のセッションでは、そのままでは scoop の lazygit が起動しないことがある**: [windows-openssh-server.md の scoop のツールを SSH のセッションで使う（任意）](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)を通す（`scoop install`・`scoop update` の後は貼り直す）
