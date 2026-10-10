# Neovim 最新版インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は scoop）

## 実施手順

- [検証記録](verification/neovim.md)・[参考資料](reference/neovim.md)・[ロールバックと注意点](extra/neovim.md)

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（scoop で入れる。管理者ではない Windows PowerShell 5.1 に貼る）
> - **前提**: [AlmaLinux 10 の初期設定の手順 46〜48](almalinux-setup.md#実施手順) で Homebrew を入れてあること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。Homebrew の導入・管理と自分の設定は、`sudo -i` した root のシェルでは行わない
> - **手順 1 で Homebrew の確認が出る場合がある**。答えて導入が完了してから手順 2 を貼る
> - **手順 2 で TUI が開く**。`:q` で終了してから、ほかのコマンドを貼る

- 上から順にコードブロックを貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 手順の後: 既定のエディタにするなら[既定のエディタにする（任意）](#既定のエディタにする任意)。設定を書く場所と、自分用の設定（`ryo-aoki-pc/LazyVimStarter`）への案内は[設定ファイル](#設定ファイル)、以後は[更新](#更新)・[ロールバック](extra/neovim.md#ロールバック)

1. brew で Neovim を入れる。

   ```bash
   brew install neovim
   ```

   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. Neovim が入ったか確かめ、起動して健全性を確認する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   nvim --version | head -3
   brew list --versions neovim
   command -v nvim
   nvim -c 'checkhealth' -c 'only'
   ```

   - `NVIM v0.12.5` と `LuaJIT 2.1...` が出れば入っている
   - `vim.provider` の node / perl / python / ruby が `WARNING` になるのは、それぞれの言語のプロバイダを入れていないため（[注意点](extra/neovim.md#注意点)）
   - 画面が出たら `:q` で終了する
   - **ほかのコマンドは、`:q` で終了してから貼る**（続けて貼ると Neovim への入力として食われる）

---

## 既定のエディタにする（任意）

- この節では、bash リポジトリが持つ既定のエディタ設定を確認する
- Windows 11 の Git Bash（WezTerm の自分用の設定の新しいタブ）も、同じ共通設定で `EDITOR`・`VISUAL` が `nvim` になる
  - 確かめるときは、WezTerm の新しいタブで、この節の手順 1 の `printf` と `alias vi` の 2 行を打つ（`. ~/.bashrc` は読み直さない。[AlmaLinux 10 の初期設定の手順 50](almalinux-setup.md#実施手順)の補足と同じ）
- Windows 11 で、Windows PowerShell や Windows Terminal から起動するツール（lazygit の `e` キーなど）にも Neovim を使わせるなら、この節の手順 2 でユーザーの環境変数にする
  - この節の手順 2・3 は、[Windows 11 で使う](#windows-11-で使う)の手順 1 と同じ管理者ではない Windows PowerShell（5.1）に貼る

1. 共通設定を読み直し、既定のエディタを確かめる。

   ```bash
   . ~/.bashrc
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%s / %s\n' "$EDITOR" "$VISUAL"
   alias vi
   ```

   - `nvim / nvim` と `alias vi='nvim'` が出ればよい
   - この 3 項目は共通設定が持つ。元値の控えや `~/.bashrc` への追記は行わない

1. Windows 11 の PowerShell でも使うときだけ、`EDITOR`・`VISUAL` を `nvim` にする。

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

1. 元に戻すときは、Windows 11 のユーザーの環境変数 `EDITOR`・`VISUAL` を消す。

   ```powershell
   foreach ($n in 'EDITOR', 'VISUAL') { if ([Environment]::GetEnvironmentVariable($n, 'User') -eq 'nvim') { [Environment]::SetEnvironmentVariable($n, $null, 'User') } }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($n in 'EDITOR', 'VISUAL') { '{0} = {1}' -f $n, [Environment]::GetEnvironmentVariable($n, 'User') }
   ```

   - `EDITOR = ` と `VISUAL = `（どちらも値が空）が出ればよい
   - 値が `nvim` のときだけ消す（ほかの値は残る）

---

## 設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値（素の Vim に近い挙動）で動く
- 置き場所は `~/.config/nvim` で、読み込まれるのは `init.lua` か `init.vim` のどちらか一方
  - `XDG_CONFIG_HOME` を設定していれば `$XDG_CONFIG_HOME/nvim` になる。別の場所を使うなら `XDG_CONFIG_HOME` か `NVIM_APPNAME` を設定する
- Windows 11 の置き場所は `%LOCALAPPDATA%\nvim`（`init.lua`）。プラグイン・undo・ログは `%LOCALAPPDATA%\nvim-data`、キャッシュは `%TEMP%\nvim-data`（設定とデータの場所は、[Windows 11 で使う](#windows-11-で使う)の手順 4 で確かめる）
  - Windows 11 では `XDG_CONFIG_HOME` を設定しない（yazi は読まず、WezTerm は `~/.config/wezterm` を読まなくなり、git は `~/.gitconfig` を読み続けるので、ツールごとに読む場所が割れる。[参考資料](reference/neovim.md#windows-11-では-選択した方針)）
  - この節の手順 1 は AlmaLinux 10 のもの。Windows 11 の Git Bash に貼っても、Neovim は `~/.config/nvim` を読まない
- **自分用の設定**は [ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter) にある（LazyVim をベースに、日本語の入力・検索と Markdown（GLFM）の執筆を強くした設定）
  - 入れ方は [docs/setup.md の「AlmaLinux 10 に導入する」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#almalinux-10-に導入する-1-度だけ)。外部コマンド・日本語入力（ibus-anthy）・フォントも入れる
  - Homebrew と Neovim の導入（本書の手順 1）も、その手順に含まれる（`brew install neovim lazygit`）
  - Windows 11 の入れ方は [docs/setup.md の「Windows 11 に導入する」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#windows-11-に導入する-1-度だけ)。既存の `%LOCALAPPDATA%\nvim` と `nvim-data` を `.bak` に退避してから clone し、Neovim・外部コマンド・lazygit も scoop で入れる
  - その手順を通すなら、[Windows 11 で使う](#windows-11-で使う)の手順 3 は要らない（同じ節の手順 2 の確認と手順 4・5 は、通した後でも使える）
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

---

## 更新

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 の更新](#windows-11-の更新)

1. brew で Neovim を更新する。

   ```bash
   brew upgrade neovim
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - **設定やプラグインは更新に追従しない**ので、メジャー更新のあとは `:checkhealth` で壊れていないか見る
   - **ほかのコマンドは、Homebrew の確認が出たら答え、更新が終わってから貼る**（続けて貼ると確認の答えとして食われる）

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows のデスクトップで行う**。この節の手順 1 で**管理者ではない** Windows PowerShell（5.1）を開き、この節の手順 2〜5 と、[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/neovim.md#windows-11-のロールバック)のブロックをそこに貼る
>   - SSH のセッションには貼らない（Administrators の一員の SSH のセッションは管理者の権限で動き、scoop は自分のユーザーに入れるため）
> - 前提: [Windows 11 の初期設定の手順 16〜19 と手順 20・21](windows-setup.md#実施手順)（貼り付けの設定と scoop）。手順 16〜19 を通していなければ、ブロックは Ctrl+V で貼る
> - 前提: [git.md の Windows 11 で Git for Windows を入れる](git.md#windows-11-で-git-for-windows-を入れる)（`C:\Program Files\Git`。scoop の更新に git が要る）
> - 前提: Visual C++ のランタイム（`VCRUNTIME140.dll`。Neovim が使い、scoop は入れない）。この節の手順 2 で確かめ、無ければ [wezterm-nightly.md の Windows 11 で使う](wezterm-nightly.md#windows-11-で使う)の手順 3 を管理者の Windows PowerShell で行う
> - **この節の手順 5 で Neovim の画面（TUI）が開く**。`:qa` で閉じてから、ほかのブロックを貼る

- 上から順にコードブロックを貼る。変数は無い
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 自分用の設定（`ryo-aoki-pc/LazyVimStarter`）を入れるなら、その導入の手順が Neovim も scoop で入れるので、この節の手順 3 は要らない（[設定ファイル](#設定ファイル)）
- 手順の後: 置き場所と自分用の設定は[設定ファイル](#設定ファイル)。PowerShell などから起動するツールにも Neovim を使わせるなら[既定のエディタにする（任意）](#既定のエディタにする任意)の手順 2。以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/neovim.md#windows-11-のロールバック)
- SSH のセッションで scoop の nvim を使うなら、[windows-openssh-server.md の scoop のツールを SSH のセッションで使う（任意）](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)
- この節のブロックは、Windows の実機で流していない（[検証記録](verification/neovim.md#windows-11-で使う-検証状況の記録)）

1. Windows で、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）

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

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`True` なら、窓を閉じてこの節の手順 1 から
   - `Scoop` に `…\scoop\shims\scoop.ps1` の場所が出ればよい。空なら、先に [Windows 11 の初期設定の手順 20・21](windows-setup.md#実施手順) で入れる
   - `Git` は `C:\Program Files\Git\cmd\git.exe` ならよい。空か違う場所なら、先に [git.md の Windows 11 で Git for Windows を入れる](git.md#windows-11-で-git-for-windows-を入れる)
   - `VCRuntime : False` なら、[wezterm-nightly.md の Windows 11 で使う](wezterm-nightly.md#windows-11-で使う)の手順 3 を管理者の Windows PowerShell で行ってから、この手順を貼り直す
   - `C:\Program Files\Neovim\bin\nvim.exe` など、ほかの場所が出たら、winget などで入れた Neovim がある。外してから始める

1. scoop で Neovim を入れる。

   ```powershell
   scoop install neovim
   ```

   - `'neovim' (0.12.5) was installed successfully!` の形の行が出ればよい
   - `'neovim' suggests installing 'extras/vcredist2022'.` も出るが、この節の手順 2 が `VCRuntime : True` なら入れなくてよい
   - `'neovim' (0.12.5) is already installed.` の形なら、もう入っている（何も変えない）

1. 版と場所と、設定・データの置き場所を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   nvim --version | Select-Object -First 3
   (Get-Command nvim -All).Source
   nvim --clean --headless "+lua io.stdout:write(vim.fn.stdpath('config'), '\n', vim.fn.stdpath('data'), '\n')" +qa
   ```

   - `NVIM v0.12.5`・`Build type: Release`・`LuaJIT 2.1.…` の 3 行が出ればよい
   - 何も出さずに終わるか、`VCRUNTIME140.dll` が見つからない旨のシステム エラーの窓が出たら、VC++ のランタイムが無い（この節の手順 2 の `VCRuntime`）
     - 窓が出たら、OK で閉じる
   - 2 つ目は `C:\Users\<WIN_USER>\scoop\shims\nvim.exe` の 1 行だけならよい
   - 最後に、設定の置き場所（`C:\Users\<WIN_USER>\AppData\Local\nvim`）とデータの置き場所（`…\AppData\Local\nvim-data`）の 2 行が出る（[設定ファイル](#設定ファイル)）

1. Neovim を起動し、健全性を確かめる。

   ```powershell
   nvim -c checkhealth -c only
   ```

   - `:checkhealth` の結果が全画面で出る。`ERROR` が無ければよい
   - `vim.provider` の node / perl / python / ruby が `WARNING` になるのは、それぞれの言語のプロバイダを入れていないため（[実施手順](#実施手順)の手順 2 と同じ）
   - `:qa` で閉じる
   - **ほかのブロックは、`:qa` で閉じてから貼る**（続けて貼ると Neovim への入力として食われる）

---

## Windows 11 の更新

- この節の手順 1 は、[Windows 11 で使う](#windows-11-で使う)の手順 1 と同じ管理者ではない Windows PowerShell（5.1）に貼る
- [Windows 11 の初期設定の更新](windows-setup.md#更新)の手順 1・2（`scoop update *`）でも上がる
- 自分用の設定（LazyVimStarter）のプラグインと外部コマンドは、その [docs/setup.md の「更新」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#更新)の手順 2・4 で上げる
- SSH のセッションで使っているなら、上げた後に [windows-openssh-server.md の scoop のツールを SSH のセッションで使う（任意）](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の手順 1 を、管理者の Windows PowerShell で貼り直す

1. Neovim をすべて閉じてから、scoop で上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop update
   scoop update neovim
   nvim --version | Select-Object -First 1
   ```

   - `Scoop was updated successfully!` の後に、新しい版があれば `'neovim' (<版>) was installed successfully!` が出る
   - 新しい版が無ければ、`neovim: <版> (latest version)` と `Latest versions for all apps are installed!` が出る（何も変えない）
   - `Running process detected, skip updating.` が出たら、動いている Neovim（ほかの窓の中のものも）を閉じてから貼り直す
   - 最後に今の版（`NVIM v0.12.…`）が出る
   - **設定やプラグインは更新に追従しない**ので、メジャー更新の後は `:checkhealth` で壊れていないか見る
