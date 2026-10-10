# lazygit 最新版インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は scoop）の参考資料

[手順書](../lazygit.md)・[ロールバックと注意点](../extra/lazygit.md)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- `LG_EDITOR` を使うのは[設定ファイル](../lazygit.md#設定ファイル)の節だけ
- lazygit は設定が無ければ `EDITOR` 環境変数を見るので、`~/.bashrc` に `export EDITOR=nvim` があれば設定ファイルは要らない

### 実施手順 / 手順 2: 補足: ボトル

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない

### 実施手順 / 手順 3: 補足: 起動時の注意

[この節の検証記録](../verification/lazygit.md#実施手順--手順-3-補足-起動時の注意)

`lazygit --version` の `git version` 欄には、lazygit が呼ぶ git のバージョンが出る。

**git が入っていないと lazygit は起動しない。**

- Homebrew 版は git を依存に持たないので、RPM の git か `brew install git` のどちらかが要る

git 管理下でないディレクトリで起動すると `Would you like to create a new repository?` と聞かれる。意図せず `.git` を作らないよう、リポジトリのルートで起動する。

### 設定ファイル / 手順 1: 補足: 既定値とキーバインド

- 既定値の全体は `lazygit --config` で表示できる
- アプリ内では `x` でキーバインド一覧が出る

### Windows 11 で使う / 手順 2: 補足: 確かめる値の意味

- `Lazygit` が空なら、lazygit は入っていない。`C:\Users\<WIN_USER>\scoop\shims\lazygit.exe` だけなら、もう scoop で入っている（自分用の Neovim の設定の導入でも入る）

### Windows 11 で使う / 手順 4・5: 補足: 版

- 同じ節の手順 4 の `'lazygit' (<版>) was installed successfully!` と、手順 5 の `version=` の版は、実行した日の最新

### Windows 11 で使う / 手順 6: 補足: 新しい窓と確かめ用のリポジトリ

- `EDITOR` を `nvim` にした後、新しい窓で lazygit を起動し直すのは、今の窓には入らないため
- `%TEMP%\lazygit-check` を消す前に `Set-Location ~` で出るのは、この窓の今のフォルダーがそこにあり、今のフォルダーのままでは使用中で消せないため

### 選択した方針

- `atim/lazygit` でも同じ 403
- dnf を介さず `curl -L` で `repomd.xml` を取っても同じ。COPR の配信元（`download.copr.fedorainfracloud.org`）が S3 の署名付き URL にリダイレクトし、その署名が期限切れになっている
- 一方で COPR 全体が落ちているわけではない。同じ日に `lihaohong/yazi` の `epel-10-aarch64` はメタデータを取得できている（[yazi.md](../yazi.md)）
- **プロジェクトごとの問題で、いずれ直る可能性がある**

### Windows 11 では: 選択した方針

[Windows 11 で使う](../lazygit.md#windows-11-で使う)の理由。**Windows 実機では未検証**（[検証記録](../verification/lazygit.md#windows-11-で使う-検証状況の記録)）。

- **scoop の extras の `lazygit`**（main のバケットには無い）
  - extras のバケットを足すのに git が要る（Git for Windows）。extras は、ほかのアプリ（`vcredist2022`・`neovide` など）も使うので、ロールバックでも外さない
  - lazygit は Go の 1 つの実行ファイルなので、VC++ のランタイムは要らない（自分用の設定が使う delta は要る。[git-delta.md の Windows 11 で使う](../git-delta.md#windows-11-で使う)の手順 2 で確かめる）
  - winget の `JesseDuffield.lazygit` と両方あると、`PATH` の順でどちらかが使われ、分かりにくい。Windows 11 で使うの手順 2 で見つけたら、外してから始める
- **設定の置き場所は `%LOCALAPPDATA%\lazygit`**
  - lazygit 0.66.0 の Config.md の Windows の既定の場所。`%APPDATA%\lazygit\config.yml` も探す（adrg/xdg の Windows の `XDG_CONFIG_DIRS` は `%ProgramData%` と `%APPDATA%`）
  - `XDG_CONFIG_HOME` は設定しない（[neovim.md の参考資料](neovim.md#windows-11-では-選択した方針)）
- **自分用の設定は、設定のリポジトリの README の Windows の例へリンクする**（clone のコマンドはこの文書に載せない）。その例は `%LOCALAPPDATA%\lazygit` に直接 clone する（シンボリックリンクには、開発者モードか管理者の権限が要るため）。状態ファイル `state.yml` は、そのリポジトリの `.gitignore` で除いてある
- **確かめの起動は `%TEMP%\lazygit-check` の空のリポジトリで行う**
  - 読者のリポジトリの場所を決め打ちできないため。git 管理外で起動すると、リポジトリを作るか聞かれる
  - `git init` が失敗したまま起動すると、元のフォルダーでリポジトリを作るか聞かれるので、`.git` ができたことを確かめてから起動する
- **`e` キーのエディタ**: Windows PowerShell から起動したときは、ユーザーの環境変数 `EDITOR` で決まる（[neovim.md の参考資料](neovim.md#windows-11-では-選択した方針)）。自分用の設定は `os.editInTerminal` を `true` にした（`false` を明示すると、lazygit 0.66.0 ではプリセットより優先され、端末のエディタに端末が渡らない。ryo-aoki-pc/lazygit#10）

### 参照

- [jesseduffield/lazygit — README](https://github.com/jesseduffield/lazygit) — 各 OS のインストール方法と機能一覧
- [lazygit Config Docs](https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md) — `config.yml` の項目（`os.edit` など）
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 「Homebrew」の手順 1〜3 が Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は参考資料、`brew` の基本操作は同書の「Homebrew の使い方の基本」
- [atim/lazygit — Copr](https://copr.fedorainfracloud.org/coprs/atim/lazygit/) / [dejan/lazygit — Copr](https://copr.fedorainfracloud.org/coprs/dejan/lazygit/) — chroot の一覧（`epel-10-aarch64` はある）
- [ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit) — 自分用の設定（`config.yml`）。導入方法と変えた項目は README にある
- [ScoopInstaller/Extras — lazygit.json](https://github.com/ScoopInstaller/Extras/blob/master/bucket/lazygit.json) — Windows 11 の scoop の定義
- [lazygit Config Docs（v0.66.0）](https://github.com/jesseduffield/lazygit/blob/v0.66.0/docs/Config.md) — Windows の設定の場所（`%LOCALAPPDATA%\lazygit\config.yml`）と `LG_CONFIG_FILE`
- [ryo-aoki-pc/lazygit — README の導入方法](https://github.com/ryo-aoki-pc/lazygit#導入方法) — 自分用の設定の Windows の clone の例と元に戻し方

---
