# yazi 最新版インストール手順（AlmaLinux 10 / Homebrew）の検証記録

[手順書](../yazi.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 操作上の注意と併記されていた記録

- **既定値のファイルは配布物に入っていない**（実測: `brew list yazi` に含まれる `.toml` は `.crates.toml` だけ）

### 実施手順 / 手順 2: 補足: ボトルと、依存ツールの役割

aarch64 で降ってくるボトルは `yazi--26.9.1.arm64_linux.bottle.tar.gz`。

| formula | yazi での役割 |
|---|---|
| `ffmpeg-full` | 動画のサムネイル |
| `sevenzip` | 書庫の中身の一覧・展開 |
| `jq` | JSON のプレビュー |
| `poppler` | PDF のプレビュー |
| `fd` | ファイル名検索（`s` キー） |
| `ripgrep` | 全文検索（`S` キー） |
| `fzf` | 絞り込み（`z` / `Z` キー） |
| `resvg` | SVG のプレビュー |
| `imagemagick-full` | 画像・フォントの変換 |
| `font-symbols-only-nerd-font` | アイコン表示用のフォント |

`zoxide` も yazi から使える（`z` キーでのジャンプ）。本書では別の手順（[AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順 49）で入れている。

ボトルが降りたことの確認（実測、コンテナ）:

```
==> Fetching downloads for: yazi
✔︎ Bottle yazi (26.9.1)
==> Pouring yazi--26.9.1.arm64_linux.bottle.tar.gz
🍺  /home/linuxbrew/.linuxbrew/Cellar/yazi/26.9.1: 17 files, 32.5MB
==> Caveats
Bash completion has been installed to:
  /home/linuxbrew/.linuxbrew/etc/bash_completion.d
```

### ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**



- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

### 対象と検証環境

- **目的**: AlmaLinux 10 にターミナルファイルマネージャ [yazi](https://yazi-rs.github.io/) の最新版を入れ、プレビューと検索が効く状態にする
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
  - **読者が書き換えるのは冒頭の変数ブロック（依存ツールの一覧）だけ**
  - RPM（COPR）経路も試したうえで採らなかった（[選択した方針](../verification/yazi.md#選択した方針)）
- **状態**: **実機で本実行済み（2026-09-21）。`0dbb522` 版の手順 1〜4（2026-10-01 に比べ方を直した `y` 関数を含む）は、x86_64 のクリーン VM で本実行済み（2026-10-06）。WSL の擬似端末でも確認した（実機の関数は変更前の形）**。現行 `5da3478` の共通 bash 新規導入後の再検証も、別の新規 VM で行った（末尾の記録）。既存ホストの手動移行は今回は未実施
  - 下表のホストで `brew install yazi ...` を実行し、`yazi 26.9.1` が入って常用中。`~/.bashrc` の `y()` 関数は、比べ方を直す前の形で入っている
  - [Homebrew の導入](../almalinux-setup.md)と手順 2・4 は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した（`YAZI_EXTRAS` は空）
  - 確認したこと: ボトルが降りる、`yazi --version` / `ya --version` が出る
  - 2026-10-01: 比べ方を直した手順 3 のブロックを、WSL の AlmaLinux 10.2 の擬似端末の bash（使い捨ての `HOME`）に括弧付き貼り付けで貼り、GitHub の yazi 26.9.1 のバイナリを開いて `y` を確かめた。直す前の版と比べ、5 つの場合とも振る舞いは同じだった（[付録](#付録-y-関数の比べ方を直したときの検証2026-10-01)）
  - **コンテナでは TUI の起動とプレビューは確認していない**（端末が無いため）
  - **画像プレビュー（端末側の対応）とプラグインは未検証**

| 項目 | 実機 | 検証コンテナ | WSL（`y` 関数の比べ方を直したとき） |
|---|---|---|---|
| 実施日 | 2026-09-21 | 2026-09-22 | 2026-10-01 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） | AlmaLinux 10.2 (Lavender Lion) / x86_64（Windows 11 の PC の WSL 2.7.13.0、bash 5.2.26） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） | 使っていない |
| 入った yazi | `yazi 26.9.1`（`arm64_linux` ボトル、Rustc 1.98.0 ビルド） | 同じ（`26.9.1`） | GitHub のリリースの `yazi-x86_64-unknown-linux-gnu.zip`（26.9.1。一時的な場所に展開） |
| 依存ツール | `ffmpeg-full 9.0.2` / `sevenzip 26.03` / `jq 1.8.2` / `poppler 26.09.0` / `fd 10.5.0` / `ripgrep 15.2.0` / `fzf 0.74.4` / `resvg 0.48.1` / `imagemagick-full 7.1.2-31` / `font-symbols-only-nerd-font 3.5.1` | 本体のみ（formula の存在確認だけ実施） | 無し |
| 端末 | WezTerm nightly（[wezterm-nightly.md](../wezterm-nightly.md)） | 無し | Python の `pty`（160 × 48） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../yazi.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${YAZI_EXTRAS}` | yazi 本体と一緒に入れる依存ツール（空白区切りの formula 名）。空なら本体だけ | `ffmpeg-full sevenzip jq poppler ...` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`26.9.1`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| yazi | COPR `lihaohong/yazi` の RPM 版 `yazi-26.9.1-1.el10.aarch64` が入っていた（2026-09-20 に導入）。本手順の前に `dnf remove` 済み |
| Homebrew | 7.0.6 導入済み（2026-09-20 に公式インストーラで導入） |
| プレビュー用ツール | `ffmpeg` / `7z` / `magick` はいずれも未導入。`poppler-utils` は COPR 版 yazi の依存で入っていたが、削除時に一緒に消えた |
| 有効な追加リポジトリ | epel、crb、raspberrypi、COPR（lihaohong/yazi）、mozilla、gh-cli、claude-code |

### 選択した方針

AlmaLinux 10 aarch64 で yazi の最新版を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `yazi 26.9.1` の `arm64_linux` ボトルがあり、ソースビルドにならない。upstream の最新リリース（v26.9.1、2026-09-01）と一致。依存ツールも同じ `brew install` で最新版が揃う | **採用** |
| COPR `lihaohong/yazi` | `epel-10-aarch64` chroot に成果物があり、`dnf install yazi` は通る（実機で一度導入した）。ただし EL10 側に揃っていないプレビュー依存があり、`ffmpeg` は EPEL の `ffmpeg-free` しか無い。`fd-find 10.4.2` / `ripgrep 14.1.1` / `fzf 0.58.0` も Homebrew 版より古い | 不採用（実機で導入後に削除） |
| `cargo install --force yazi-build` | Rust toolchain（appstream に `rust 1.92.0` あり）が要り、更新のたびにビルドする。Raspberry Pi では時間がかかる | 不採用 |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-gnu` / `musl` のビルドがある。展開して PATH に置くだけだが、更新は手作業 | 不採用 |
| EPEL / AppStream | `yazi` は無い（`dnf list yazi` → `No matching Packages to list`） | 使えない |

- 2026-09-20 18:56 に `dnf copr enable lihaohong/yazi` → `dnf install yazi` で `yazi-26.9.1-1.el10.aarch64` を導入
  - 同時に入ったのは `resvg-0.47.0-1.el10` と `poppler-utils-24.02.0-7.el10_2.2` の 2 つだけ
- 翌朝 09:29 に `dnf remove yazi-26.9.1-1.el10.aarch64` で 3 パッケージとも削除し、Homebrew 版に入れ替えている
- RPM 側ではプレビュー用のツールを別々に集める必要があり、`ffmpeg` に至っては EL10 の標準リポジトリにも EPEL にも無い（`ffmpeg-free` のみ）

### 完了時点の状態

```
$ brew list --versions yazi
yazi 26.9.1
$ yazi --version
Yazi
    Version: 26.9.1 (Homebrew 2026-09-01)
    Debug  : false
    Triple : aarch64-unknown-linux-gnu (linux-aarch64)
    Rustc  : 1.98.0 (88d9e12a 2026-08-18)
$ ya --version
Ya
    Version: 26.9.1 (Homebrew 2026-09-01)
$ command -v yazi
/home/linuxbrew/.linuxbrew/bin/yazi
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/yazi/26.9.1/`（17 ファイル、32.5 MB）。bash 補完は `/home/linuxbrew/.linuxbrew/etc/bash_completion.d` に入る。

### 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで、非 root ユーザーを作って[Homebrew の導入](../almalinux-setup.md)と手順 2・4 を通した。実機で加えた変更は `dnf install podman` だけ。 実行したのは**この文書のコードブロックをそのまま抜き出したスクリプト**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。 端末が要る `y` の 1 行と、`YAZI_EXTRAS` の中身（空にした）だけ除いている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git sudo` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6` が `/home/linuxbrew/.linuxbrew` に入った（[homebrew.md](../almalinux-setup.md)） |
| 2. yazi | `brew install yazi` → `Pouring yazi--26.9.1.arm64_linux.bottle.tar.gz`（17 files, 32.5MB）。ソースビルドは発生しない |
| 4. 検証 | `yazi --version` / `ya --version` ともに `26.9.1 (Homebrew 2026-09-01)`、`Triple: aarch64-unknown-linux-gnu` |
| 依存ツール | `ffmpeg` / `sevenzip` / `jq` / `poppler` / `fd` / `ripgrep` / `fzf` / `resvg` / `imagemagick` / `font-symbols-only-nerd-font` の formula がすべて存在することを `brew info` で確認（インストールはしていない。実機には `-full` 版が入っている） |
| 設定ファイル | 配布物に既定の `*.toml` は含まれない（`brew list yazi` の `.toml` は `.crates.toml` のみ） |
| RPM 経路 | COPR `lihaohong/yazi` を有効化して `dnf install --assumeno yazi` → 115 パッケージ・63 MB に解決。EPEL の `ffmpeg-free 7.1.2` / `fd-find 10.4.2` / `ripgrep 14.1.1` / `fzf 0.58.0` はいずれも Homebrew 版より古い |

#### 未確認事項

- TUI の追加操作（削除・外部アプリで開く操作など。クリーン VM では起動・ディレクトリ移動・終了とテキスト・ZIP のプレビューを確認）
- 画像プレビュー（WezTerm 側のグラフィックプロトコル対応）
- `ya pkg` で入れるプラグイン・テーマ
- `YAZI_EXTRAS` を空にした最小構成での動作
- ロールバック（`brew uninstall`）の本実行

---

### 付録: y 関数の比べ方を直したときの検証（2026-10-01）

手順 3 の `y` 関数の、移ったかの比べ方を `[ "$cwd" != "$PWD" ]` から `! [ "$cwd" -ef "$PWD" ]` に直した。きっかけは、この関数を同じ文字列で読む自分用の bash の設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）を、Windows 11 の Git Bash で確かめたときの次の振る舞い:

- yazi（scoop の 26.9.1）は cwd-file に `C:\Users\…\Desktop` の形で書き、Git Bash の `$PWD` は `/c/Users/…/Desktop` なので、文字列では一致しない
- 動かずに `q` で閉じても `cd` し直し、`OLDPWD` が今の場所に変わった（`cd -` で前の場所へ戻れない）。`Q` では変わらなかった
- bash の組み込みの `test` の `-ef`（同じデバイスと i ノードか）は、Git Bash で `C:\Users\…\Desktop` と `/c/Users/…/Desktop` を同じ、別のディレクトリを違うと判定した

**流し方（AlmaLinux 10）**:

- Windows 11 の PC の WSL の AlmaLinux 10.2 で、Python の `pty` で `bash --norc --noprofile -i` を動かした（`HOME` は `/tmp` の下の使い捨てのディレクトリ。WSL のユーザーのホームには書いていない）
- この文書の手順 3 のブロックを機械的に抜き出し（リストの字下げを外す）、括弧付き貼り付けで貼ってから Enter を送った。直す前の版（この直しの前の yazi.md）と直した版を、別々のホームで流した
- yazi は Homebrew で入れず、GitHub のリリースの `yazi-x86_64-unknown-linux-gnu.zip`（26.9.1。sha256 をリリースに載っている値と照合）を一時的な場所に展開して、`PATH` の先頭に置いた
- yazi の画面が開いた（代替画面に切り替わった）のを待ってからキーを送り、画面が閉じてプロンプトが戻ってから、`PWD` と `OLDPWD` を書き出した

| 確かめたこと | 直す前（`!=`） | 直した版（`-ef`） |
|---|---|---|
| 手順 3 のブロックを貼った後 | `~/.bashrc` は 7 行、`type -t y` は `function` | 同じ（比べ方の行だけが違う） |
| `d1` で `y` → `l` で `share` に入って `q` | `share` へ移り、`OLDPWD` は `d1` | 同じ |
| `d1` で `y` → 動かずに `q` | 動かず、`OLDPWD` も前のまま | 同じ |
| `d1` で `y` → 動かずに `Q` | 動かず、`OLDPWD` も前のまま | 同じ |
| シンボリックリンク（`link` → `real`）の中で `y` → 動かずに `q` | `PWD` は `link` のまま | 同じ |
| `y 'd1/with space'` → `q` | `d1/with space` へ移った | 同じ |
| `/tmp/yazi-cwd.*` | 残らない | 残らない |

- `y` を通さずに `yazi --cwd-file=<ファイル>` を開いて確かめると、動かずに `q` で閉じたとき、yazi は `$PWD` と同じ形（シンボリックリンクの中では `…/link` のリンクの形）を書いた。`Q` で閉じるとファイルを作らなかった
- AlmaLinux 10 では、yazi が `$PWD` と同じ形で書くので、2 つの比べ方で振る舞いが分かれなかった

**Windows 11 の Git Bash**（参考。この文書の対象外）:

- ryo-aoki-pc/bash の `bashrc` の同じ関数を、画面を出さない WezTerm の端末（`wezterm-mux-server` のペイン）で、scoop の yazi 26.9.1 を開いて確かめた
- 直す前は、動かずに `q` で閉じると `OLDPWD` が今の場所に変わった。直した版では変わらず、中へ入って `q`・`Q`・空白と日本語を含むディレクトリは、直す前と同じだった

#### 未確認事項（2026-10-01）

- 実機（Raspberry Pi 5・aarch64・Homebrew の yazi）で、直した `y` を使うこと（実機の `~/.bashrc` は直す前の形のまま）
- WezTerm の画面での操作（擬似端末にキーを送って代えた）

---

### 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜4。

**検証した版**: `0dbb522`。以下の手順番号と「本文」は、`y` 関数を直接追記していたこの版を指す。その後の共通 bash 設定の新規導入・移行は今回の VM では行っていない。

**結果**: Yazi/Ya 26.9.1。本文既定の `YAZI_EXTRAS` を全て指定し、この段階で新しい formula のボトル 175 個と Symbols Nerd Font の cask を導入した。ソースビルドは発生しなかった。1 vCPU の VM で手順 2 は 1,798.8 秒（約 30 分）かかった。その後の、他の CLI を含む `Cellar` は 2.6 GiB、Homebrew のダウンロードキャッシュは 838 MiB だった。この版の `y()` 関数を本文どおり書き、TUI で空白を含む `sub directory` に入り `q` で終了した。シェルの `pwd` もそのディレクトリになった。テキストと ZIP の内容一覧（`sample.txt`・29 B）のプレビューを確認した。Homebrew の sevenzip が置くコマンドは `7zz` で、`7z` は無かった。追加の確認で `7z` を呼んだ際の PackageKit の導入質問は中断し、RPM の `7zip` を追加せず、`7zz` と Yazi の ZIP プレビューで確かめ直した。初回の終了判定は、捕捉ライブラリが alternate screen を復元せず古い TUI を残したため誤判定した。生ログのプロンプト・Ctrl+L の再描画・`pwd` で切り分け、捕捉補助を直した。

**今回の未確認範囲**: 画像・動画・PDF の画面プレビュー、ファイルの削除や外部アプリを開く操作、自分用の設定、更新・ロールバックは今回確認していない。追加ツールは版の出力まで確認した。

### 付録: 現行版と個人設定の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜4 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で共通 bash `3d5323e` の導入後に実行した。既定の `YAZI_EXTRAS` 全体を選び、yazi / ya 26.9.1、ffmpeg-full、sevenzip、jq、poppler、fd、ripgrep、fzf、resvg、imagemagick-full、Nerd Font を導入した
- 本文手順 2 は 36 分 17 秒で終了 0。145 回の bottle 展開を観測し、ソースビルドへの fallback は無かった。最後は ImageMagick 7.1.2-32 と Nerd Font 3.5.1。追加ツールは xorg-server の検証補助が先に入った共有 prefix に導入したので、まったく同じ依存集合をすべての新規ホストで要するという意味ではない
- 個人設定の README の clone URL を具体的な公開 URL に直し、`custom` / `41c5124` を通常の `~/.config/yazi` に clone した。3 ペイン・隠しファイル・サイズと更新日時・テキストのプレビューが実 TUI に出た。`l` でディレクトリへ入り、Enter で sample.txt が Neovim に開き、`:qa` で戻った
- 共通設定の `y` で終了すると `/home/verifier/cli-yazi-check/空白 日本語` へ移り、`gT` で `/tmp` へ移った後も `q` でシェルの cwd が `/tmp` になった。そこで動かず終了しても cwd は同じだった
- 最初の TUI 補助では終了時のマーカーを取り逃し、復帰前の次の入力も届かなかった。TUI の起動・復帰とシェルのプロンプトを待つ補助へ直して同じ操作を再実行した。設定の不具合とは区別する
- PDF・動画・画像・書庫の実プレビューと GUI 端末の描画、検索・複数ファイルをまとめて開く任意設定、上流設定の更新・rebase・push、パッケージ更新・削除は今回は確認していない


### 選択した方針

**COPR 版を外した理由**（実機の記録）:

EPEL を有効にした状態で COPR 版の依存解決を採ると、EPEL 側のツールを巻き込んで 115 パッケージ・63 MB になる:

```
$ dnf install --assumeno yazi
 jq              aarch64  1.7.1-11.el10_2.2  baseos
 jxl-pixbuf-loader aarch64 1:0.10.4-1.el10_1 epel
 open-sans-fonts noarch   1.10-24.el10       appstream
 poppler-utils   aarch64  24.02.0-7.el10_2.2 appstream
 resvg           aarch64  0.47.0-1.el10      copr:copr.fedorainfracloud.org:lihaohong:yazi
 ripgrep         aarch64  14.1.1-1.el10_0    epel
Install  115 Packages
Total download size: 63 M
```

