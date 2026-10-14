# Neovim のセットアップ（AlmaLinux 10・Windows 11）の参考資料

[手順書](../neovim.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/neovim.md)・[ロールバックと注意点](../extra/neovim.md)

## 統合前の参考資料: Neovim（もとは neovim.md）

もとの `neovim.md` の参考資料を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の参考資料](#統合前の参考資料-neovim-の-windows-11もとは-neovimmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「Neovim」の手順 1 |
| 実施手順 2 | 「Neovim」の手順 2（`checkhealth` の起動は外した） |
| 既定のエディタにする（任意）の 1 | 「Neovim」の手順 4 |
| 設定ファイルの 1（最小の例） | （外した。「Neovim」の手順 3 で自分用の設定を入れる。箇条書きは「Neovim の設定ファイル」） |
| 更新 1 | 更新の手順 2・3 |
| ロールバック 1・2 | ロールバックの「端末とエディタを消す」の手順 3・4 |

### Neovim: 補足

#### Neovim: 実施手順 / 手順 1: 補足: ボトルと依存

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
- 依存（`libuv` / `lpeg` / `luajit` / `luv` / `tree-sitter` / `unibilium` / `utf8proc`）も一緒に入る

#### Neovim: 実施手順 / 手順 2: 補足: :checkhealth の読み方

[この節の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#neovim-実施手順--手順-2-補足-checkhealth-の読み方)

`:checkhealth` は「使っていない機能の WARNING」を大量に出す。素の状態で出るのは主に次の 3 種類:

- `vim.provider`: node / perl / python3 / ruby のプロバイダが無い。それぞれの言語で書かれたプラグインを使わないなら無視してよい（`vim.g.loaded_node_provider = 0` などで黙らせられる）
- `vim.deprecated`: プラグインが古い API を使っている
- ツールの不足: `rg`（ripgrep）、`fd`、`git`、`tree-sitter` など。必要なものを各手順書で導入する（[yazi.md](../almalinux-setup.md#yazi) の依存ツール、および RPM の git）

`ERROR` が出ていなければ、日常の編集には支障がない。

- 手順 2 のブロックは、最後の行で起動して、`:checkhealth` で健全性を確認する

#### Neovim: 既定のエディタにする（任意） / 手順 2: 補足: git commit のエディタ

- git の `core.editor` が無ければ、PowerShell から動かす `git commit` も Neovim で開く（Git for Windows の既定の Vim から変わる。`git config --get core.editor` で確かめられる）

#### Neovim: 既定のエディタにする（任意） / 手順 3: 補足: Git Bash の共通設定

- Git Bash の共通設定の `EDITOR`・`VISUAL` は、この手順では変わらない

#### Neovim: 設定ファイル / 手順 1: 補足: 探索先とディストリビューション

- 設定の探索先は `nvim -c ':echo stdpath("config")' -c 'q'` で確認できる
- LazyVim / NvChad などのディストリビューションを入れる場合も、同じ場所に置く

#### Neovim: 参照

- [Install Neovim](https://neovim.io/doc/install/) — 公式が案内する各経路（tarball / AppImage / パッケージマネージャ）
- [neovim/neovim — INSTALL.md](https://github.com/neovim/neovim/blob/master/INSTALL.md) — tarball の展開先と PATH の通し方、glibc の要件
- `:help nvim-defaults` / `:help checkhealth` — 既定値と健全性チェックの読み方
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 「Homebrew」の手順 1〜3 が Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は参考資料、`brew` の基本操作は同書の「Homebrew の使い方の基本」
- [ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter) — 自分用の設定（LazyVim ベース）。導入の手順は [docs/setup.md](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md)
- [ScoopInstaller/Main — neovim.json](https://github.com/ScoopInstaller/Main/blob/master/bucket/neovim.json) — Windows 11 の scoop の定義（版・`bin`・`suggest`）
- [neovim/neovim — runtime/doc/starting.txt（v0.12.5）](https://github.com/neovim/neovim/blob/v0.12.5/runtime/doc/starting.txt) — `base-directories`（Windows の設定・データ・キャッシュの場所）
- [lazygit — Config.md の Configuring File Editing](https://github.com/jesseduffield/lazygit/blob/v0.66.0/docs/Config.md#configuring-file-editing) — `e` キーのエディタの決まり方（`EDITOR` とプリセット）
- [ryo-aoki-pc/LazyVimStarter — docs/setup.md の Windows 11 に導入する](../neovim.md#windows-11-で-lazyvim-の設定を導入する) — 自分用の設定の Windows の導入（scoop の Neovim と外部コマンドも入れる）

---

## 統合前の参考資料: Neovim の Windows 11（もとは neovim.md）

もとの `neovim.md` の参考資料のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の参考資料](#統合前の参考資料-neovimもとは-neovimmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-setup.md)の統合前の記録と同じ。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | 「Neovim」の手順 1 |
| Windows 11 で使う 2・3 | 「Neovim」の手順 2・3 |
| Windows 11 で使う 4 | 「Neovim」の手順 5 |
| Windows 11 で使う 5（`checkhealth`） | （外した。自分用の設定の導入（「Neovim」の手順 4）で確かめる） |
| 既定のエディタにする（任意）の 2・3 | 「Neovim を既定のエディタにする」の手順 2・3 |
| Windows 11 の更新 1 | 「scoop・winget・WSL を上げる」の手順 2・3 |
| Windows 11 のロールバック 1 | ロールバックの「エディタとシェルのツールを消す」の手順 5 |
| Windows 11 のロールバック 2 | 「Neovim を既定のエディタにする」の手順 3 |

### Neovim: Windows 11 の補足

#### Neovim: Windows 11 で使う / 手順 2: 補足: 確かめる値の意味

- `Nvim` が空なら、Neovim は入っていない。`C:\Users\<WIN_USER>\scoop\shims\nvim.exe` だけなら、もう scoop で入っている

#### Neovim: Windows 11 で使う / 手順 3・4: 補足: 版

- 同じ節の手順 3 の `'neovim' (<版>) was installed successfully!` と、手順 4 の `NVIM v…` の版は、実行した日の最新

#### Neovim: Windows 11 では: 選択した方針

[Windows 11 で使う](../neovim.md#windows-11-で-neovim-を入れる)・[既定のエディタにする](../neovim.md#neovim-を既定のエディタにする)の手順 2・3 の理由。**Windows 実機では未検証**（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-setup.md#neovim-windows-11-で使う-検証状況の記録)）。

- **scoop の main の `neovim` で、自分のユーザーに入れる**（管理者の権限は要らない）
  - [Windows 11 の初期設定の「アプリを入れる」](../windows-setup.md#アプリを入れる)の手順 1・2 で入れた scoop に、CLI のツールをまとめる。自分用の設定（LazyVimStarter）の Windows の導入も scoop の `neovim` を使う
  - winget の `Neovim.Neovim` は PC 全体に入る MSI（`C:\Program Files\Neovim`）。PC 全体の `PATH` はユーザーの `PATH` より先に引かれるので、両方あると winget の方が使われる。Windows 11 で使うの手順 2 で見つけたら、外してから始める
- **VC++ のランタイムは、wezterm-nightly.md の Windows 11 で使うの手順 3 を指す**（winget の `Microsoft.VCRedist.2015+.x64`。管理者の窓）
  - scoop の `neovim` はランタイムを入れず、`extras/vcredist2022` を勧めるだけ（`neovim.json` の `suggest`）。`nvim.exe` は `VCRUNTIME140.dll` を使う（リリースの zip のインポート表。[検証記録の付録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-setup.md#neovim-付録-windows-11-の節の資料と-linux-での確認2026-10-08)）
  - 無いと、`nvim.exe` は何も出さずに終わる（LazyVimStarter の検証記録の 2026-10-06 のクリーンな Windows 11 の VM の記録。ブロックは自動で流したもの）
  - デスクトップで打つと、`VCRUNTIME140.dll` が見つからない旨のシステム エラーの窓が出ることもある（読み込みに失敗したときの Windows の通常の振る舞い。確かめていない）。そのため手順書は、窓が出る場合も書いた
  - Windows で入れる手順を 1 か所にするため、この文書には入れ方を書かない。scoop の `vcredist2022` は x64 と x86 の両方を入れ、UAC の確認が出る
- **`XDG_CONFIG_HOME` をユーザーの環境変数にしない**
  - Neovim と lazygit は追従するが、yazi は Windows では読まない（`%APPDATA%\yazi\config` のまま）
  - WezTerm は、`~/.wezterm.lua` が無ければ、`~/.config/wezterm` の代わりに `$XDG_CONFIG_HOME/wezterm` を読む（`~/.config` の側は探さない。[wezterm-nightly.md の検証記録の実測](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#wezterm-設定ファイルの探索順序実測)）
  - git は `~/.gitconfig`（git.md が書く場所）を読み続け、`~/.config/git/config` の代わりに `$XDG_CONFIG_HOME/git/config` を読む
  - このように、追従するもの・読まないもの・一部だけ変わるものがあり、ツールごとに読む場所が割れる
  - LazyVimStarter の検証記録（2026-09-30）に、`XDG_CONFIG_HOME` を付けたまま Neovim が設定を見つけなかった記録がある
- **`EDITOR`・`VISUAL` は、任意のユーザーの環境変数にする**
  - WezTerm の Git Bash は、共通の bash 設定が `nvim` にするので要らない。Windows PowerShell・Windows Terminal から起動したツールにだけ効かせる
  - lazygit 0.66.0 は、`os.edit` などが無いと、git の `core.editor` → `GIT_EDITOR` → `VISUAL` → `EDITOR` の順に探し、最初の語のファイル名で既知のプリセットを選ぶ。どれも無いと `vim` のプリセットになる。Windows の lazygit はエディタを `cmd.exe` で動かすので、Git for Windows の `usr\bin\vim` は見つからない
  - 値を `nvim` だけにするのは、`nvim.exe` やフルパスでは `nvim` のプリセットに合わないため
  - Git for Windows のインストーラで Vim を選ぶと、`core.editor` は書かれず、git は `EDITOR` を使う。そのため PowerShell の `git commit` も Neovim になる
  - ほかの値があれば止め、元に戻す手順は値が `nvim` のときだけ消す（元の値を消さないため）
- **起動の確かめは `:checkhealth`**（AlmaLinux 10 の手順 2 と同じ）。TUI が開くので、節の最後の手順にした

---
