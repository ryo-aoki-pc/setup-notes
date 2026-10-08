# yazi 最新版インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は scoop）の参考資料

[手順書](../yazi.md)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- `YAZI_EXTRAS` に並べているのは、yazi が外部コマンドとして呼ぶツール。役割は手順 2 の補足にまとめた
- `ffmpeg-full` と `imagemagick-full` は、Homebrew の `ffmpeg` / `imagemagick` に対してコーデック・フォーマットを広く有効にしたビルド（どちらも `homebrew/core` の formula）

### Windows 11 では: 選択した方針

[Windows 11 で使う](../yazi.md#windows-11-で使う)の理由。**Windows 実機では未検証**（[検証記録](../verification/yazi.md#windows-11-で使う-検証状況の記録)）。

- **scoop の main の `yazi`**: yazi の公式の文書が Windows で案内する経路の 1 つ。依存のツールも main にある
- **`$YAZI_EXTRAS` は、AlmaLinux 10 の `YAZI_EXTRAS` に合わせた**
  - 公式の文書の scoop の一覧（ffmpeg・7zip・jq・poppler・fd・ripgrep・fzf・zoxide・resvg・imagemagick）から zoxide を外した。AlmaLinux 10 の一覧にも無く、AlmaLinux 10 は [AlmaLinux 10 の初期設定の手順 49](../almalinux-setup.md#実施手順)、Windows 11 は [Windows 11 の初期設定のシェルのツールを入れる（任意）](../windows-setup.md#シェルのツールを入れる任意)で入れる（Windows の zoxide は、Git Bash での記録の問題があるので、その節で 0.9.9 に止めてある）
  - Homebrew の `font-symbols-only-nerd-font` の代わりは、[hackgen.md の Windows 11 で使う](../hackgen.md#windows-11-で使う)の HackGen Console NF
  - 変数が無いまま `scoop install yazi @YAZI_EXTRAS` を流すと、空の引数が 1 つ scoop に渡った（Linux の PowerShell 7.5.3 での模擬。[検証記録の付録](../verification/yazi.md#付録-windows-11-の節の資料と-linux-での確認2026-10-08)）
    - そのため、Windows 11 で使うの手順 4 は、同じ節の手順 2 を貼っていない窓では止める
- **`file` は、Git for Windows の `usr\bin\file.exe` を `YAZI_FILE_ONE` で渡す**
  - yazi の文書が勧める唯一の形。scoop・Chocolatey の `file` は Unicode のファイル名を扱えない
  - yazi は `YAZI_FILE_ONE` をシェルを通さずに起動するので、`Program Files` の空白は問題にならない
    - yazi 26.9.1 の `yazi-plugin/preset/plugins/mime-local.lua`・`file.lua` は、`Command(<YAZI_FILE_ONE の値>)` で起動する
    - Lua の `Command` は、`yazi-binding/src/process/command.rs` の `tokio::process::Command::new`（シェルを挟まない）。`ya env` も `Command::new` で動かす（`yazi-cli/src/env/env.rs`）
  - PowerShell の `PATH` には `file` が無い。Git Bash には `/usr/bin/file` があるが、PowerShell や Windows Terminal から起動したときにも同じに動くよう、ユーザーの環境変数にする
  - Windows 11 で使うの手順 5 は、前の値を確かめずに上書きする。元の値は同じ節の手順 3 で控え、Windows 11 のロールバックの手順 2 の後に手で戻す
  - そのロールバックの手順 2 は、値が Git for Windows の `file.exe` のときだけ消す（neovim.md の `EDITOR`・`VISUAL` と同じく、後から変えた値は残す）
- **VC++ のランタイムは、neovim.md と同じく wezterm-nightly.md の手順 3 を指す**: yazi 26.9.1 の Windows 版（msvc）の `yazi.exe`・`ya.exe` は `VCRUNTIME140.dll` を使い、scoop の `yazi` はランタイムを入れない（リリースの zip のインポート表。[検証記録の付録](../verification/yazi.md#付録-windows-11-の節の資料と-linux-での確認2026-10-08)）
- **設定は `%APPDATA%\yazi\config`**: Windows の yazi は `XDG_CONFIG_HOME` を見ない（yazi 26.9.1 の `yazi-fs/src/xdg.rs`）。状態は `%APPDATA%\yazi\state`、キャッシュは `%LOCALAPPDATA%\yazi`。自分用の設定の Windows の clone は、設定のリポジトリの README の例へリンクする
- **`y` は Git Bash の共通の設定だけで使う**: Windows PowerShell 5.1 は手順書を貼る窓なので、ツールの初期化（PowerShell 版の `y`）は足さない。WezTerm の自分用の設定は、Windows の新しいタブで Git Bash を開く
  - PowerShell 7 のプロファイル（[Windows 11 の初期設定の任意節](../windows-setup.md#powershell-7-のプロファイルを設定する任意)）にも、`y` は足していない。その節が足すのは貼り付け・履歴の検索と zoxide・starship の行だけで、PowerShell 版の `y` はこの文書の範囲の外にした
- **ファイルを開くエディタは、自分用の設定の Neovim を前提にした**（Windows 11 で使うのリードで、先に neovim.md を通すよう案内する）
  - 上流の既定（yazi 26.9.1 の `yazi-config/preset/yazi-default.toml`）の `[opener]` の `edit` は、Windows では `code %s` と `code -w %s`（VS Code）
  - `${EDITOR:-vi}` は `for = "unix"` の行だけで、Windows の yazi は `EDITOR` を見ない
  - テキスト（`text/*`）は `edit` が最初の候補なので、自分用の設定が無いと、Git Bash の `y` から開いても Enter で `code` が動く
  - 自分用の設定（`ryo-aoki-pc/yazi` の `yazi.toml`）は、Windows の `edit` を `nvim %s`（`block = true`）にしてある
- **確かめは `ya env`**: 26.9.1 には `yazi --debug` が無く、`ya env` が設定の場所・変数・依存の版・`file -bL --mime-type` の結果を出す
- **TUI の手順を節の最後にした**: Git Bash の `y` の確かめを先にし、PowerShell の `yazi` の起動を最後に置いた
  - Git Bash のタブを開くところ（コマンドの無い手順 7）と、そこに貼る `type -t y` と `y`（`bash` のブロックの手順 8。git.md と同じく、Git Bash には bash の構文で貼る）を分けた
  - 手順 8 の `y` も TUI を開くので、手順 8 の最後で閉じてから PowerShell に戻る

### 参照

- [Installation — Yazi](https://yazi-rs.github.io/docs/installation/) — 経路一覧と依存ツール（ffmpeg / 7-Zip / jq / poppler / fd / ripgrep / fzf / zoxide / ImageMagick）
- [Quick Start — Yazi](https://yazi-rs.github.io/docs/quick-start/) — `y` シェル関数（`--cwd-file`）の原典
- [Configuration — Yazi](https://yazi-rs.github.io/docs/configuration/overview/) — `yazi.toml` / `keymap.toml` / `theme.toml`
- [ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi) — 自分用の設定。入れ方・独自のキー・上流との差分の管理は README にある
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 手順 46〜48 が Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は参考資料、`brew` の基本操作は同書の「Homebrew の使い方の基本」
- [Installation — Yazi の Windows](https://yazi-rs.github.io/docs/installation/#windows) — scoop の経路と依存、`YAZI_FILE_ONE`（Git for Windows の `file.exe`）
- [Image Preview — Yazi](https://yazi-rs.github.io/docs/image-preview/) — Windows で画像を出せる端末（WezTerm の nightly、Windows Terminal 1.22.10352.0 以降）と ConPTY の制約
- [ScoopInstaller/Main — yazi.json](https://github.com/ScoopInstaller/Main/blob/master/bucket/yazi.json) — Windows 11 の scoop の定義
- [sxyazi/yazi — yazi-fs/src/xdg.rs（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-fs/src/xdg.rs) — Windows の設定・状態・キャッシュの場所
- [sxyazi/yazi — yazi-cli/src/env/env.rs（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-cli/src/env/env.rs) — `ya env` の出力
- [sxyazi/yazi — yazi-config/preset/yazi-default.toml（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-config/preset/yazi-default.toml) — 上流の既定の `[opener]`（Windows の `edit` は `code`）
- [sxyazi/yazi — yazi-plugin/preset/plugins/mime-local.lua（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-plugin/preset/plugins/mime-local.lua)・[yazi-binding/src/process/command.rs（v26.9.1）](https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-binding/src/process/command.rs) — `YAZI_FILE_ONE` の起動（シェルを挟まない）

---
