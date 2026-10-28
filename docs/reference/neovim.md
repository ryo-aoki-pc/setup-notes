# Neovim のセットアップ（AlmaLinux 10・Windows 11）の参考資料

[手順書](../neovim.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/neovim.md)・[注意点](../extra/neovim.md)

## 補足

### Neovim / 手順 1: 補足: ボトルと依存

[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md)

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
- 依存（`libuv` / `lpeg` / `luajit` / `luv` / `tree-sitter` / `unibilium` / `utf8proc`）も一緒に入る

### LazyVim の設定を導入する / 手順 10: 補足: treesitter のパーサーの導入を待つ理由

- 両 OS の「LazyVim の設定を導入する」「LazyVim の設定とプラグインの版を揃える」「LazyVim の本体・外部コマンド・プラグインを更新する」の計 6 手順に当てはまる
- `+qa` だけでは、LazyVim が非同期で始めたパーサーの導入・更新を待たずに Neovim が閉じる
- 待たずに閉じると、Windows 11 では組み立てが途中で終わって鍵が残り、次から `appears stale` で失敗する
- AlmaLinux 10 では、組み立ては続いて鍵を消すが、パーサーは入らない。組み立ての途中で `tree-sitter build` が殺されたときは、鍵が残る
- Mason が入れた tree-sitter の CLI は、headless の Neovim では Mason を読み込むまで PATH に無いので、最初に Mason を読み込む
- tree-sitter の CLI が無ければ、Mason が入れて CLI が使えるようになるまで最大 10 分待つ
- nvim-treesitter は、ほかで始まった同じ言語の導入を最大 60 秒しか待たないので、パーサーの更新と導入が両方とも成功するまで最大 20 回繰り返す
- [検証記録の付録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/neovim.md#付録-headless-の-neovim-が-treesitter-のパーサーの導入を途中で止めるのを直したとき2026-10-16)

### LazyVim の設定を導入する / 手順 13: 補足: GitLab プレビューの公式スタイル

- Windows 11 の「LazyVim の設定を導入する」の手順 11、両 OS の「LazyVim の設定とプラグインの版を揃える」の最後の手順も同じ取得処理を使う
- CSS・フォント・SVG は設定リポジトリに含めず、GitLab CE の公式資産イメージから取得する。初回の取得量は約 785 MB で、GitLab サーバーや Docker・Python は入れない
- Node.js で必要なファイルだけを取り出し、Neovim のデータ領域の `gitlab-preview/assets/` に保存する。ライセンス原文・著作権表示も保存する
- 指定した版・ハッシュと導入済みの資産が一致すれば取得を省く。設定だけを pull しても資産は自動更新せず、版を揃える手順で明示的に取得する
- 通常の Neovim の起動やプレビューの表示では公式スタイルの取得を始めない。資産が無いときは独自 CSS を使い、GitLab API の利用可否とは別に「公式スタイル未導入」と表示する
- API が返す HTML の解釈と、表示する CSS は別のもの。近似表示でも公式 CSS は使えるが、未対応の GLFM 記法が増えるわけではない
- 対象版・取得元・ライセンスの扱いは [LazyVimStarter の設計](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/dev/architecture.md#markdown--glfm)を参照する

### Windows 11 で Neovim を入れる / 手順 2: 補足: 確かめる値の意味

- `Nvim` が空なら、Neovim は入っていない。`C:\Users\<WIN_USER>\scoop\shims\nvim.exe` だけなら、もう scoop で入っている

### Windows 11 で Neovim を入れる / 手順 3・5: 補足: 版

- 同じ項の手順 3 の `'neovim' (<版>) was installed successfully!` と、手順 5 の `NVIM v…` の版は、実行した日の最新

### Neovim を既定のエディタにする / 手順 2: 補足: git commit のエディタ

- git の `core.editor` が無ければ、PowerShell から動かす `git commit` も Neovim で開く（Git for Windows の既定の Vim から変わる。`git config --get core.editor` で確かめられる）

### 更新のリード: 補足: :checkhealth の読み方

[この節の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/neovim.md#neovim-実施手順--手順-2-補足-checkhealth-の読み方)

`:checkhealth` は「使っていない機能の WARNING」を大量に出す。素の状態で出るのは主に次の 3 種類:

- `vim.provider`: node / perl / python3 / ruby のプロバイダが無い。それぞれの言語で書かれたプラグインを使わないなら無視してよい（`vim.g.loaded_node_provider = 0` などで黙らせられる）
- `vim.deprecated`: プラグインが古い API を使っている
- ツールの不足: `rg`（ripgrep）、`fd`、`git`、`tree-sitter` など。必要なものを各手順書で導入する（[yazi](../almalinux-setup.md#yazi) の依存ツール、および RPM の git）

`ERROR` が出ていなければ、日常の編集には支障がない。

### 選択した方針

#### Windows 11 で Neovim を入れる

[Windows 11 で使う](../neovim.md#windows-11-で-neovim-を入れる)・[既定のエディタにする](../neovim.md#neovim-を既定のエディタにする)の手順 2 の理由。**Windows 実機では未検証**（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/neovim.md#neovim-windows-11-で使う-検証状況の記録)）。

- **scoop の main の `neovim` で、自分のユーザーに入れる**（管理者の権限は要らない）
  - [Windows 11 の初期設定の「アプリを入れる」](../windows-setup.md#アプリを入れる)の手順 1・2 で入れた scoop に、CLI のツールをまとめる。自分用の設定（LazyVimStarter）の Windows の導入も scoop の `neovim` を使う
  - winget の `Neovim.Neovim` は PC 全体に入る MSI（`C:\Program Files\Neovim`）。PC 全体の `PATH` はユーザーの `PATH` より先に引かれるので、両方あると winget の方が使われる。Windows 11 で使うの手順 2 で見つけたら、外してから始める
- **VC++ のランタイムは、[Windows 11 で WezTerm を入れる](../shell-terminal.md#windows-11-で-wezterm-を入れる)の手順 3 を指す**（winget の `Microsoft.VCRedist.2015+.x64`。管理者の窓）
  - scoop の `neovim` はランタイムを入れず、`extras/vcredist2022` を勧めるだけ（`neovim.json` の `suggest`）。`nvim.exe` は `VCRUNTIME140.dll` を使う（リリースの zip のインポート表。[検証記録の付録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/neovim.md#neovim-付録-windows-11-の節の資料と-linux-での確認2026-10-08)）
  - 無いと、`nvim.exe` は何も出さずに終わる（LazyVimStarter の検証記録の 2026-10-06 のクリーンな Windows 11 の VM の記録。ブロックは自動で流したもの）
  - デスクトップで打つと、`VCRUNTIME140.dll` が見つからない旨のシステム エラーの窓が出ることもある（読み込みに失敗したときの Windows の通常の振る舞い。確かめていない）。そのため手順書は、窓が出る場合も書いた
  - Windows で入れる手順を 1 か所にするため、この文書には入れ方を書かない。scoop の `vcredist2022` は x64 と x86 の両方を入れ、UAC の確認が出る
- **`XDG_CONFIG_HOME` をユーザーの環境変数にしない**
  - Neovim と lazygit は追従するが、yazi は Windows では読まない（`%APPDATA%\yazi\config` のまま）
  - WezTerm は、`~/.wezterm.lua` が無ければ、`~/.config/wezterm` の代わりに `$XDG_CONFIG_HOME/wezterm` を読む（`~/.config` の側は探さない。[WezTerm の検証記録の実測](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shell-terminal.md#wezterm-設定ファイルの探索順序実測)）
  - git は `~/.gitconfig`（[Git](../almalinux-setup.md#git)が書く場所）を読み続け、`~/.config/git/config` の代わりに `$XDG_CONFIG_HOME/git/config` を読む
  - このように、追従するもの・読まないもの・一部だけ変わるものがあり、ツールごとに読む場所が割れる
  - LazyVimStarter の検証記録（2026-09-30）に、`XDG_CONFIG_HOME` を付けたまま Neovim が設定を見つけなかった記録がある
- **`EDITOR`・`VISUAL` は、任意のユーザーの環境変数にする**
  - WezTerm の Git Bash は、共通の bash 設定が `nvim` にするので要らない。Windows PowerShell・Windows Terminal から起動したツールにだけ効かせる
  - lazygit 0.66.0 は、`os.edit` などが無いと、git の `core.editor` → `GIT_EDITOR` → `VISUAL` → `EDITOR` の順に探し、最初の語のファイル名で既知のプリセットを選ぶ。どれも無いと `vim` のプリセットになる。Windows の lazygit はエディタを `cmd.exe` で動かすので、Git for Windows の `usr\bin\vim` は見つからない
  - 値を `nvim` だけにするのは、`nvim.exe` やフルパスでは `nvim` のプリセットに合わないため
  - Git for Windows のインストーラで Vim を選ぶと、`core.editor` は書かれず、git は `EDITOR` を使う。そのため PowerShell の `git commit` も Neovim になる
  - ほかの値があれば止める
- **健全性の確かめは `:checkhealth`**

### 参照

#### Neovim

- [Install Neovim](https://neovim.io/doc/install/) — 公式が案内する各経路（tarball / AppImage / パッケージマネージャ）
- [neovim/neovim — INSTALL.md](https://github.com/neovim/neovim/blob/master/INSTALL.md) — tarball の展開先と PATH の通し方、glibc の要件
- `:help nvim-defaults` / `:help checkhealth` — 既定値と健全性チェックの読み方
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 「Homebrew」の手順 1〜3 が Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は参考資料、`brew` の基本操作は同書の「Homebrew の使い方の基本」
- [ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter) — 自分用の設定（LazyVim ベース）。導入の手順は[LazyVim の設定を導入する](../neovim.md#lazyvim-の設定を導入する)、何ができるかはその README
- [ScoopInstaller/Main — neovim.json](https://github.com/ScoopInstaller/Main/blob/master/bucket/neovim.json) — Windows 11 の scoop の定義（版・`bin`・`suggest`）
- [neovim/neovim — runtime/doc/starting.txt（v0.12.5）](https://github.com/neovim/neovim/blob/v0.12.5/runtime/doc/starting.txt) — `base-directories`（Windows の設定・データ・キャッシュの場所）
- [lazygit — Config.md の Configuring File Editing](https://github.com/jesseduffield/lazygit/blob/v0.66.0/docs/Config.md#configuring-file-editing) — `e` キーのエディタの決まり方（`EDITOR` とプリセット）
- [Windows 11 で LazyVim の設定を導入する](../neovim.md#windows-11-で-lazyvim-の設定を導入する) — 自分用の設定の Windows の導入（scoop の Neovim と外部コマンドも入れる）
