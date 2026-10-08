# git-delta（delta）インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は scoop）の参考資料

[手順書](../git-delta.md)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- 3 つとも `~/.gitconfig` の `[delta]` に書かれる値で、後から `git config --global delta.side-by-side true` で変えられる
- `navigate` を `true` にすると、ページャ（`less`）の中で `n` が「次の変更へ」になる。delta が `less` に渡すオプションで実現しているので、`core.pager` 経由で起動したときだけ効く

### 実施手順 / 手順 2: 補足: 降ってくるボトル

aarch64 で降ってくるボトルは `git-delta--0.19.2.arm64_linux.bottle.tar.gz`。

### Windows 11 で使う / 手順 2: 補足: VC++ ランタイム

- scoop の delta は、上流の `x86_64-pc-windows-msvc` のビルドで、`delta.exe` のインポート表に `VCRUNTIME140.dll` がある（[検証記録の付録](../verification/git-delta.md#付録-windows-11-の配布物と資料の調査2026-10-08)）。無い PC では起動しない
- scoop の `delta.json` は VC++ ランタイムを入れない（`depends` も `suggest` も無い）。winget の `dandavison.delta` は、依存として `Microsoft.VCRedist.2015+.x64` を持つ
- 入れ方は新しく書かず、[wezterm-nightly.md の Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の手順 3（管理者の窓の winget。PC 全体）を指す。手順書の並びでは WezTerm を先に入れるので、ふつうはもう入っている
  - 設定の「インストールされているアプリ」では「Microsoft Visual C++ v14 Redistributable (x64)」と出る（前の版で入れた PC では「… 2015-2022 …」）
  - extras のバケットの `vcredist2022`（scoop）でも入るが、extras を足すことになり、入れるときに UAC の確認も出るので採らない
- 同じ前提は bat・Neovim・yazi にもある。eza（windows-gnu のビルド）と starship・zoxide・fd（CRT を静的にリンク）、gh（Go）には無い

### Windows 11 で使う / 手順 4: 補足: 実施手順の手順 1・3 を Git Bash で貼る

- 手順 1・3 のブロックは bash と git だけを使うので、Git Bash にそのまま貼れる。PowerShell 向けに書き分けない（[git.md](../git.md) と同じ考え方）
- `git config --global` が書くのは `C:\Users\<WIN_USER>\.gitconfig`（Git Bash の `HOME`）。Git Bash・PowerShell 7・cmd の `git config --global --list --show-origin` が同じファイルを示すことは、[git.md の検証記録](../verification/git.md#付録-windows-11-の-git-bash-での検証記録2026-09-30)で確かめてある
- 手順 2（`brew install`）と手順 4（`brew list` を含む）は指さない。入れることと版・場所は、Windows 11 の節の手順 3 で PowerShell から確かめる
- 手順 3 は `merge.conflictstyle zdiff3` も書く。[git.md](../git.md#実施手順) の手順 6 と同じ値なので、どちらを先に通してもよい（AlmaLinux 10 と同じ）

### Windows 11 で使う / 手順 5: 補足: ページャの less と PowerShell の git

- git は `core.pager` の `delta` を PATH から探して起動する（scoop の shim の `~\scoop\shims\delta.exe`）
- delta 0.20.1 のページャは、`delta.pager`（`--pager`）・`DELTA_PAGER`・`BAT_PAGER`・`PAGER` の順に決まり、どれも無ければ `less`。そのコマンドを PATH から探し、見つからなければ、ページャを使わずに標準出力へ書く（ソースの `src/utils/bat/output.rs` と `src/env.rs`）
- **Git Bash** では、PATH の先頭が Git の `/usr/bin` なので、delta は Git for Windows の `usr\bin\less.exe` を使う
- **PowerShell・cmd** の PATH には Git の `cmd` しか無い（Git for Windows の既定の `Path Option=Cmd`）。それでも、そこの `git.exe`（Git for Windows の git-wrapper）は、`mingw64\bin`・`usr\bin`・`%HOME%\bin` を PATH の先頭に足してから本体の `mingw64\bin\git.exe` を動かす（git-wrapper のソースの `setup_environment`。`cmd\git.exe` は `git.res` の版の情報だけを持ち、PATH を絞る `MINIMAL_PATH=1` の文字列のリソースが無い）。その PATH を受け継ぐ delta も、Git for Windows の less を使う
- 上流の文書は、Windows では新しい less が要り、古い `less.exe` を使うと色が崩れたり変な文字が出たりすると書いている。Git for Windows の less は MSYS2 の今の版なので、これに当たらないはず（版は確かめていない）
- **scoop の less は入れなかった**: 設計の段階では、PowerShell から git を使うときだけ scoop の less（main の `less.json`。上流の文書が勧める `jftuga/less-Windows` の配布物）を入れる任意の手順を考えた。上のとおり、git が起動する delta には、Git Bash でも PowerShell でも Git の `usr\bin` が scoop の shims より前に来るので、入れても使われない（`DELTA_PAGER` か `delta.pager` で場所を指したときと、PowerShell で delta を直に動かしたときだけ使われる）
- PowerShell で delta を直に動かす（`git diff | delta` など）と、PATH に less が無いので、delta はページャを使わずに出す（上の `output.rs` の動き）
- `delta.navigate`（手順 1 の `DELTA_NAVIGATE`）が `true` だと、delta は less の検索履歴の写しを `%LOCALAPPDATA%\delta\delta.lesshst` に作り、`LESSHISTFILE` で less に渡す（ソースの `src/features/navigate.rs`。Linux では `~/.local/share/delta/lesshst`）。Windows で `n` / `N` が効くかは確かめていない
- どれも、ソースを読んだだけで、Windows では確かめていない（[検証記録](../verification/git-delta.md#windows-11-で使う-検証状況の記録)）

### 選択した方針

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `git-delta 0.19.2` の `arm64_linux` ボトルがある。upstream の最新と一致。formula に `delta` という別名が付いているので `brew install delta` でも入る | **採用** |
| EPEL / AppStream / CRB | **`delta` も `git-delta` も無い**（`dnf list --available delta git-delta` → `Error: No matching Packages to list`）。※ `delta` という名前の無関係なパッケージも無い | 使えない |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-gnu` の tar と `.rpm` が置いてある。rpm を直接入れると dnf のリポジトリ管理外になり更新が手作業になる | 不採用（Homebrew に揃える） |
| `cargo install git-delta` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |
| diff-so-fancy / difftastic | 別物（difftastic は EPEL に `0.67.0` がある）。構文木で比較する difftastic とは用途が違うので、置き換えではなく併用できる | 対象外 |

### Windows 11 では: 選択した方針

[Windows 11 で使う](../git-delta.md#windows-11-で使う)の理由。**Windows の実機では未検証**（[検証記録](../verification/git-delta.md#windows-11-で使う-検証状況の記録)）。

- **scoop の main のバケットで入れた**（winget は採らない）
  - [README の導入の基盤](../getting-started.md#初期設定で整えるもの)の「CLI ツールは scoop」と同じ。管理者が要らず、[Windows 11 の初期設定の更新](../windows-setup.md#更新)の `scoop update *` と UniGet UI で上がる
  - winget の `dandavison.delta` 0.20.1 も、同じ上流の zip（portable）を同じ sha256 で入れる。違うのは入れ方と上げ方と、VC++ ランタイムを依存として入れるかだけ
  - 上流の zip を手で置く形や `cargo install git-delta`（Rust が要る）は、更新が手作業になる
  - scoop の定義は x64 だけ。arm64 の Windows 11 では、scoop はこの x64 の版を入れる（Scoop のソースの `Get-SupportedArchitecture`。確かめていない）
  - 版は固定しない（`scoop hold` しない）。scoop で止めるのは、Git Bash で移動先を記録しない 0.10.0 を避ける zoxide だけ（[Windows 11 の初期設定のシェルのツールを入れる（任意）](../windows-setup.md#シェルのツールを入れる任意)）
- **設定は git の `~/.gitconfig` だけ**: delta は自分の設定ファイルを持たず、`[delta]` セクションを読む。`XDG_CONFIG_HOME` は関係しないので設定しない。Git Bash・PowerShell・cmd の git が同じファイルを読む（[Windows 11 で使う / 手順 4 の補足](#windows-11-で使う--手順-4-補足-実施手順の手順-13-を-git-bash-で貼る)）
- **シェルとの組み込み方**
  - delta はどのシェルにも初期化の行が要らない。git が `core.pager` と `interactive.diffFilter` で呼ぶので、`~/.gitconfig` を書けば、どのシェルの git にも効く
  - **Git Bash が主**: WezTerm の自分用の設定の `default_prog` は Git Bash（`bash.exe -i -l`）。git の設定は Git Bash で[実施手順](../git-delta.md#実施手順)の手順 1・3 を貼って書く（AlmaLinux 10 と同じブロック）。共通の bash 設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）は delta を扱わず、`PAGER` なども設定しない
  - **PowerShell 7 のプロファイルには何も足さない**。[Windows 11 の初期設定の PowerShell 7 のプロファイルを設定する（任意）](../windows-setup.md#powershell-7-のプロファイルを設定する任意)が読むのは starship と zoxide だけ
  - **Windows PowerShell 5.1 のプロファイルにも足さない**。手順書を貼る窓のプロファイルは、Windows 11 の初期設定の手順 19 の 1 行のまま
  - **WSL の AlmaLinux 10 は Linux のホストとして扱う**。WSL の git は WSL の中の `~/.gitconfig` を読むので、[実施手順](../git-delta.md#実施手順)を WSL の中で通す
- **VC++ ランタイムは前提にした**: [Windows 11 で使う / 手順 2 の補足](#windows-11-で使う--手順-2-補足-vc-ランタイム)
- **scoop の less は入れない**: [Windows 11 で使う / 手順 5 の補足](#windows-11-で使う--手順-5-補足-ページャの-less-と-powershell-の-git)
- **lazygit**: 自分用の lazygit の設定（[ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit)）は、`git.diffRenderers` で `delta --no-gitconfig …` を呼ぶ。`~/.gitconfig` の `[delta]` を読まないので、この文書の変数は lazygit の表示に効かない。Windows の lazygit は描画のコマンドを cmd.exe で動かすので、単一引用符を使わない（その README の「Windows で使う場合」）。この文書の任意節の yaml は引用符を使わない
- **ロールバックは、git の設定を先に外す**: scoop の delta を先に消すと、`core.pager` が残って、git が delta を起動できなくなる。[Windows 11 の初期設定のロールバック](../windows-setup.md#ロールバック)の手順 13（scoop ごと外す）も `~/.gitconfig` は変えないので、その前に外す
- **Git Bash は WezTerm のタブで確かめる**: 自分用の設定で Git Bash が開く。スタートメニューの「Git Bash」（mintty）でも同じ `~/.gitconfig` を読むはずだが、確かめていない
- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた

### 参照

- [dandavison/delta — README](https://github.com/dandavison/delta) — 使い方、`~/.gitconfig` の書き方、side-by-side と navigate の説明
- [delta manual](https://dandavison.github.io/delta/) — 全設定項目、`features` による設定のまとめ方、他ツールとの連携
- [lazygit 0.65.1 の差分表示設定](https://github.com/jesseduffield/lazygit/blob/v0.65.1/docs/Custom_DiffRenderers.md) — `git.diffRenderers` の `stdinFilter` と delta の指定
- `delta --help` / `delta --show-config` / `delta --list-syntax-themes` — オプションと実効値、配色の一覧
- `git help config` の `core.pager` / `interactive.diffFilter` — git 側の仕様
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 手順 46〜48 が Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は参考資料、`brew` の基本操作は同書の「Homebrew の使い方の基本」
- [ScoopInstaller/Main — delta.json](https://github.com/ScoopInstaller/Main/blob/master/bucket/delta.json) — scoop の版、x64 の zip と hash、`delta.exe` の shim
- [winget-pkgs — dandavison.delta 0.20.1](https://github.com/microsoft/winget-pkgs/blob/master/manifests/d/dandavison/delta/0.20.1/dandavison.delta.installer.yaml) — 同じ zip の sha256 と、VC++ ランタイムの依存（採らなかった経路）
- [delta manual — Using Delta on Windows](https://dandavison.github.io/delta/tips-and-tricks/using-delta-on-windows.html) — Windows では新しい less が要るという案内
- [src/utils/bat/output.rs（0.20.1）](https://github.com/dandavison/delta/blob/0.20.1/src/utils/bat/output.rs)・[src/features/navigate.rs](https://github.com/dandavison/delta/blob/0.20.1/src/features/navigate.rs) — ページャの探し方と、Windows の less の検索履歴の写しの場所
- [git-for-windows/MINGW-packages — git-wrapper.c](https://github.com/git-for-windows/MINGW-packages/blob/main/mingw-w64-git/git-wrapper.c)・[mingw-w64-git.mak](https://github.com/git-for-windows/MINGW-packages/blob/main/mingw-w64-git/mingw-w64-git.mak) — `cmd\git.exe` が PATH の先頭に `usr\bin` を足すこと
- [ScoopInstaller/Scoop](https://github.com/ScoopInstaller/Scoop) — `install`・`update`・`uninstall` の表示と、arm64 の Windows 11 で x64 の定義を使うこと（`lib/manifest.ps1` の `Get-SupportedArchitecture`）
- [ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit) — 自分用の lazygit の設定。README の「前提ツール」と「Windows で使う場合」
- [Windows 11 の初期設定](../windows-setup.md) — 貼り付けの設定（手順 16〜19）、scoop（手順 20・21）、PowerShell 7 のプロファイルの任意節
- [WezTerm の Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う) — VC++ ランタイム（手順 3）と、Git Bash で開く自分用の設定

---
