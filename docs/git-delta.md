# git-delta（delta）インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は scoop）

## 実施手順

- [検証記録](verification/git-delta.md)・[参考資料](reference/git-delta.md)・[ロールバックと注意点](extra/git-delta.md)

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（scoop で入れる。管理者ではない Windows PowerShell 5.1 に貼り、git の設定はその節から Git Bash で手順 1・3 を貼る）
> - **前提**: [AlmaLinux 10 の初期設定の手順 46〜48](almalinux-setup.md#実施手順) で Homebrew を入れてあること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。Homebrew の導入・管理は一般ユーザーで行い、設定も自分の `~/.gitconfig` に書く
> - **手順 2 で Homebrew の確認が出る場合がある**。答えて導入が完了してから手順 3 を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: lazygit を使っているなら[lazygit と組み合わせる（任意）](#lazygit-と組み合わせる任意)。設定項目の一覧は[設定ファイル](#設定ファイル)、以後は[更新](#更新)・[ロールバック](extra/git-delta.md#ロールバック)

1. 変数を設定する。

   ```bash
   DELTA_NAVIGATE=true       # ページャ内で n / N を「次の変更・前の変更」にする。<DELTA_NAVIGATE>
   DELTA_LINE_NUMBERS=true   # 差分の左に行番号を出す。<DELTA_LINE_NUMBERS>
   DELTA_SIDE_BY_SIDE=false  # true にすると左右 2 面に分けて表示する。<DELTA_SIDE_BY_SIDE>
   for v in DELTA_NAVIGATE DELTA_LINE_NUMBERS DELTA_SIDE_BY_SIDE; do printf '%-19s = %s\n' "$v" "${!v}"; done
   ```

   - **編集が必須の変数は無い**。3 つとも表示の好みなので、既定のままで進められる
   - 広い画面で左右に並べたいなら、`DELTA_SIDE_BY_SIDE=true` にする
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. brew で git-delta を入れる。

   ```bash
   brew install git-delta
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - **formula 名は `git-delta` だが、入るコマンドは `delta`**（`brew install delta` でも同じ formula に解決される）
   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. `git config --global` で git の設定を書き、読み戻す。

   ```bash
   if [ -z "${DELTA_NAVIGATE}" ] || [ -z "${DELTA_LINE_NUMBERS}" ] || [ -z "${DELTA_SIDE_BY_SIDE}" ]; then
     echo '中断: 手順 1 の変数が空。3 つとも設定してから貼り直す' >&2
   else
     git config --global core.pager delta &&
       git config --global interactive.diffFilter 'delta --color-only' &&
       git config --global delta.navigate "${DELTA_NAVIGATE}" &&
       git config --global delta.line-numbers "${DELTA_LINE_NUMBERS}" &&
       git config --global delta.side-by-side "${DELTA_SIDE_BY_SIDE}" &&
       git config --global merge.conflictstyle zdiff3 &&
       git config --global --get-regexp '^(core\.pager|interactive\.difffilter|delta\.(navigate|line-numbers|side-by-side)|merge\.conflictstyle)$'
   fi
   ```

   - `~/.gitconfig` を直接編集せず、`git config --global` で書く（既にある `[user]` や `[core]` を壊さない）
   - 最後の行で、書けたか読み戻す
   - 設定した 6 項目が出る。`中断:` が出た場合は、どの設定も書き換えていない
   - **`interactive.difffilter` と小文字で表示される**のが正しい（git がキー名を正規化するため。`~/.gitconfig` の中では `diffFilter` のまま）
   - `merge.conflictstyle zdiff3` は delta とは独立した設定だが、コンフリクト表示が読みやすくなるので一緒に入れている
   - `zdiff3` は git 2.35 以降で使える（AlmaLinux 10 の RPM は 2.52.0）
   - [git.md 手順 6](git.md#実施手順) でも同じ値を入れる。先に通していても、同じキーが書き直されるだけ

1. 変更のあるリポジトリに `cd` してから、delta の版と差分の表示を確かめる。

   ```bash
   delta --version
   brew list --versions git-delta
   command -v delta
   git diff | delta --paging=never | head -20
   ```

   - 版は `delta 0.19.2` / `git-delta 0.19.2` のように出る
   - 最後の行で、変更のあるリポジトリの差分を出す
   - ファイル名のヘッダと、行ごとに背景色の付いた差分が出る
   - **`git diff` を単体で打ったときは、端末に直接出る場合だけ delta を通る**。`git diff | head` のようにパイプに繋ぐと git はページャを呼ばないので、素の差分が出る

---

## lazygit と組み合わせる（任意）

- lazygit は自前のページャ設定を持っているので、`~/.gitconfig` の `core.pager` は見ない

- lazygit の設定には `git.diffRenderers` を使う
- 自分用の lazygit の設定（[ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit)）は、もう `git.diffRenderers` で delta を使う（`--no-gitconfig` を付けるので、この文書で書いた `~/.gitconfig` の `[delta]` は読まない）。その設定を使うなら、この節の手順 1 は要らない
- Windows 11 でも同じ設定でよい（delta は、[Windows 11 で使う](#windows-11-で使う)で入れたものを PATH から呼ぶ）。設定ファイルは `%LOCALAPPDATA%\lazygit\config.yml`（`lazygit --print-config-dir` で確かめる）

> [!WARNING]
> **この節の手順 1 で、`~/.config/lazygit/config.yml` に既に `git:` があるなら、`cat >>` で追記せずに手で中身を併合する。** 同じトップレベルキーを 2 回書くと YAML として壊れる。

1. [lazygit.md](lazygit.md#設定ファイル) の設定ファイルに、delta をページャにする設定を足す。

   ```yaml
   git:
     diffRenderers:
       - type: stdinFilter
         colorArg: always
         command: delta --dark --paging=never
   ```

   - 現在の中身は、`lazygit --print-config-dir` で場所を確かめてから開く

---

## 設定ファイル

設定の実体は `~/.gitconfig` の `[delta]` セクション（Windows 11 では `C:\Users\<WIN_USER>\.gitconfig`。Git Bash・PowerShell・cmd の git が同じファイルを読む）。手順 3 で書いた 3 つのほかによく使うもの:

| キー | 意味 |
|---|---|
| `features` | 名前付き設定のまとめ読み（`[delta "<名前>"]` を作って指定する） |
| `syntax-theme` | シンタックスハイライトの配色。一覧は `delta --list-syntax-themes` |
| `hyperlinks` | ファイル名を端末のハイパーリンクにする |
| `true-color` | 24 bit 色を使うか（既定は端末から自動判定） |
| `file-style` / `minus-style` / `plus-style` | ファイル名行・削除行・追加行の色 |

- 今の実効値は `delta --show-config` で全部出る
- `delta --help` にはオプションとして同じ名前が並んでおり、コマンドラインで一時的に上書きできる

---

## 更新

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 の更新](#windows-11-の更新)

1. brew で git-delta を更新する。

   ```bash
   brew upgrade git-delta
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - **ほかのコマンドは、Homebrew の確認が出たら答え、更新が終わってから貼る**（続けて貼ると確認の答えとして食われる）

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows のデスクトップで行う**。この節の手順 1 で**管理者ではない** Windows PowerShell（5.1）を開き、この節の手順 2・3 と、[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/git-delta.md#windows-11-のロールバック)のブロックをそこに貼る
> - SSH のセッションには貼らない（scoop は自分のユーザーに入れる。Administrators の一員の SSH のセッションは管理者の権限で動く）
> - 前提: [Windows 11 の初期設定の手順 16〜19 と手順 20・21](windows-setup.md#実施手順)（貼り付けの設定と scoop）。手順 16〜19 を通していなければ、ブロックは Ctrl+V で貼る
> - 前提: [git.md の Windows 11 で Git for Windows を入れる](git.md#windows-11-で-git-for-windows-を入れる)と、[README の共通の bash 設定を先に入れる](../README.md#共通の-bash-設定を先に入れる)（Git Bash で）、[wezterm-nightly.md の Windows 11 で使う](wezterm-nightly.md#windows-11-で使う)と自分用の WezTerm の設定（新しいタブが Git Bash で開く。[設定ファイル](wezterm-nightly.md#設定ファイル)）
> - 前提: VC++ ランタイム（`VCRUNTIME140.dll`。Windows の delta が使う）。この節の手順 2 で確かめ、無ければ [wezterm-nightly.md の Windows 11 で使う](wezterm-nightly.md#windows-11-で使う)の手順 3 を、管理者の Windows PowerShell で行う
> - **この節の手順 4・5 は、WezTerm の Git Bash のタブで行う**（この節の手順 4 で[実施手順](#実施手順)の手順 1・3 を貼る。PowerShell には貼らない）。この節の手順 5 で開く less は `q` で閉じる

- この節の手順 1 で開いた PowerShell に、上から順にコードブロックを貼る。PowerShell の変数は無い（[実施手順](#実施手順)の手順 1 の変数は、この節の手順 4 で Git Bash に貼る）
- 手順の後: lazygit でも delta で差分を出すなら[lazygit と組み合わせる（任意）](#lazygit-と組み合わせる任意)、設定項目は[設定ファイル](#設定ファイル)。以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/git-delta.md#windows-11-のロールバック)
- git の設定（`C:\Users\<WIN_USER>\.gitconfig`）は、Git Bash・PowerShell・cmd の git で同じファイル。`~/.bashrc` と PowerShell のプロファイルには何も足さない（[参考資料](reference/git-delta.md#windows-11-では-選択した方針)）
- WSL の AlmaLinux 10 の git は、WSL の中の `~/.gitconfig` を読む。WSL でも使うなら、その中で[実施手順](#実施手順)を通す
- SSH のセッションの Git Bash でも git を使うなら、この節の後に [windows-openssh-server.md の scoop のツールを SSH のセッションで使う（任意）](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の手順 1 を、管理者の Windows PowerShell で貼る（`core.pager` の delta は scoop の shim で起動する）
- この節のブロックは、Windows の実機で流していない（[検証記録](verification/git-delta.md#windows-11-で使う-検証状況の記録)）

1. Windows で、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない。「PowerShell 7」ではない）

1. 管理者ではないことと、scoop・git・VC++ ランタイム・ほかの delta を確かめる。

   ```powershell
   [pscustomobject]@{
     PowerShell = $PSVersionTable.PSVersion.ToString()
     Admin      = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop      = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git        = (Get-Command git -ErrorAction SilentlyContinue).Source
     VCRuntime  = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
     Delta      = (Get-Command delta -All -ErrorAction SilentlyContinue).Source -join ', '
   } | Format-List
   ```

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`Admin : True` なら、窓を閉じてこの節の手順 1 から
   - `Scoop` に `C:\Users\<WIN_USER>\scoop\shims\scoop.ps1` が出ればよい。空なら、先に [Windows 11 の初期設定の手順 20・21](windows-setup.md#実施手順) で入れる
   - `Git` が `C:\Program Files\Git\cmd\git.exe` でなければ、先に [git.md の Windows 11 で Git for Windows を入れる](git.md#windows-11-で-git-for-windows-を入れる)
   - `VCRuntime : True` ならよい。`False` なら、先に [wezterm-nightly.md の Windows 11 で使う](wezterm-nightly.md#windows-11-で使う)の手順 3 を管理者の Windows PowerShell で行い、この窓でこのブロックを貼り直す
   - `Delta` が空なら、delta は入っていない。`C:\Users\<WIN_USER>\scoop\shims\delta.exe` だけなら、もう scoop で入っている（この節の手順 3 の `scoop install` は何も変えない）
   - ほかの場所（winget の `…\WinGet\Links\delta.exe` など）が出たら、ほかの方法で入れた delta がある。混ざらないよう、外してから始める

1. scoop で delta を入れ、版と場所を確かめる。

   ```powershell
   scoop install delta
   delta --version
   (Get-Command delta -All).Source
   ```

   - `'delta' (0.20.1) was installed successfully!` の形の行が出ればよい（版は実行した日の最新）
   - もう入っていれば、`'delta' (<版>) is already installed.` と `Use 'scoop update delta' to install a new version.` の警告を出して何も変えない
   - scoop の名前は `delta`（Homebrew の formula の `git-delta` ではない）
   - `delta 0.20.1` の形で、入れた版が出ればよい。版が出なければ、この節の手順 2 の `VCRuntime` を確かめる
   - 最後のコマンドは、`C:\Users\<WIN_USER>\scoop\shims\delta.exe` の 1 行だけを出せばよい
   - scoop の delta は x64 版だけ。arm64 の Windows でも、その x64 版が入る（確かめていない）

1. WezTerm の新しいタブ（Git Bash）で、[実施手順](#実施手順)の手順 1・3 を貼る。

   - WezTerm を起動するか、新しいタブ（既定のキーは Ctrl+Shift+T）を開く（自分用の WezTerm の設定では Git Bash が開く）
   - 手順 1 の 3 つの変数は、AlmaLinux 10 と同じ既定のままでよい。変数はそのタブの中だけで有効なので、手順 3 も同じタブに貼る
   - 手順 3 は、AlmaLinux 10 と同じく、設定した 6 項目が出ればよい（`interactive.difffilter` は小文字）
   - 書く先は `C:\Users\<WIN_USER>\.gitconfig`（Git Bash の `~/.gitconfig`）。PowerShell と cmd の git も、同じファイルを読む
   - [実施手順](#実施手順)の手順 2・4 は行わない（`brew` の行があるため。版と場所は、この節の手順 3 で確かめた）

1. 同じ Git Bash のタブで `git diff` を打ち、delta の表示になることを確かめる。

   - 変更のあるリポジトリに `cd` してから打つ。変更のあるリポジトリが無ければ、代わりに `git -C ~/.config/bash show` を打つ（[共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)の clone の、最後のコミットの差分）
   - ファイル名のヘッダと、行番号・行ごとに背景色の付いた差分が出ればよい（[実施手順](#実施手順)の手順 4 と同じ見え方）
   - 1 画面に収まらないときは、less で止まる。`q` で閉じる
   - 素の差分（背景色の無い `+` / `-` の行）が出たら、この節の手順 4 で貼った[実施手順](#実施手順)の手順 3 の読み戻しに `core.pager delta` があるかを確かめる
   - `git diff | head` のようにパイプに繋ぐと、AlmaLinux 10 と同じく delta を通らない
   - PowerShell・cmd で打つ `git diff` も、同じ `~/.gitconfig` を読んで delta を通る（[注意点](extra/git-delta.md#注意点)）

---

## Windows 11 の更新

- この節の手順 1 は、[Windows 11 で使う](#windows-11-で使う)の手順 1 と同じ管理者ではない Windows PowerShell（5.1）に貼る
- [Windows 11 の初期設定の更新](windows-setup.md#更新)の手順 1・2（`scoop update *`）でも、ほかの scoop のツールと一緒に上がる
- git の設定（`~/.gitconfig`）は変わらない。上げた後に、Git Bash で貼り直すものは無い
- SSH のセッションの Git Bash でも git を使うなら、上げた後に [windows-openssh-server.md の scoop のツールを SSH のセッションで使う（任意）](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の手順 1 を、管理者の Windows PowerShell で貼り直す

1. 開いている delta の表示（less）を閉じてから、scoop で delta を上げる。

   ```powershell
   scoop update
   scoop update delta
   delta --version
   ```

   - `scoop update` は `Scoop was updated successfully!` を出す
   - 新しい版があれば、`'delta' (<版>) was installed successfully!` の形の行が出る。無ければ `delta: <版> (latest version)` と出て、何も変わらない
   - `Running process detected, skip updating.` が出たら、上がっていない。Git Bash などで開いている delta の表示（less）を `q` で閉じてから貼り直す
   - 最後のコマンドで、今の版が出る
