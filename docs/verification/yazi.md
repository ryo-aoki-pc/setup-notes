# yazi 最新版インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は scoop）の検証記録

[手順書](../yazi.md)・[ロールバックと注意点](../extra/yazi.md)

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

`zoxide` も yazi から使える（`z` キーでのジャンプ）。本書では別の手順（[AlmaLinux 10 の初期設定の「シェルのツール」](../almalinux-setup.md#シェルのツール)の手順 1）で入れている。

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

### Windows 11 で使う: 検証状況の記録

- **[Windows 11 で使う](../yazi.md#windows-11-で使う)・[Windows 11 の更新](../yazi.md#windows-11-の更新)・[Windows 11 のロールバック](../extra/yazi.md#windows-11-のロールバック)は、Windows 実機では未検証**（2026-10-08 に書いた。Windows を動かせないクラウドの Linux のコンテナで書き、どのブロックも Windows では貼っていない）
- 確かめた範囲は[対象と検証環境](#対象と検証環境)の「状態（Windows 11）」と[付録](#付録-windows-11-の節の資料と-linux-での確認2026-10-08)

### 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に、ターミナルファイルマネージャ [yazi](https://yazi-rs.github.io/) の最新版を入れ、プレビューと検索が効く状態にする
- **進め方**
  - **AlmaLinux 10**（[実施手順](../yazi.md#実施手順)）: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
    - **読者が書き換えるのは冒頭の変数ブロック（依存ツールの一覧）だけ**
    - RPM（COPR）経路も試したうえで採らなかった（[選択した方針](../verification/yazi.md#選択した方針)）
  - **Windows 11**（[Windows 11 で使う](../yazi.md#windows-11-で使う)）: scoop の main の `yazi` と `$YAZI_EXTRAS` のツールを、管理者ではない Windows PowerShell 5.1 から自分のユーザーに入れる
    - **読者が書き換えるのは、この節の手順 2 の `$YAZI_EXTRAS` だけ**（既定のままでよい）
    - ユーザーの環境変数 `YAZI_FILE_ONE` を Git for Windows の `file.exe` にする。VC++ のランタイムが無ければ、wezterm-nightly.md の Windows 11 の手順 3 を管理者の窓で先に行う
    - `y` は、WezTerm の Git Bash の共通の bash 設定で使う（Git Bash のタブを開くコマンドの無い手順 7 と、そこに貼る `bash` のブロックの手順 8）
- **状態（AlmaLinux 10）**: **実機で本実行済み（2026-09-21）。`0dbb522` 版の手順 1〜4（2026-10-01 に比べ方を直した `y` 関数を含む）は、x86_64 のクリーン VM で本実行済み（2026-10-06）。WSL の擬似端末でも確認した（実機の関数は変更前の形）**。現行 `5da3478` の共通 bash 新規導入後の再検証も、別の新規 VM で行った（末尾の記録）。既存ホストの手動移行は今回は未実施
  - 下表のホストで `brew install yazi ...` を実行し、`yazi 26.9.1` が入って常用中。`~/.bashrc` の `y()` 関数は、比べ方を直す前の形で入っている
  - [Homebrew の導入](../almalinux-setup.md)と手順 2・4 は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した（`YAZI_EXTRAS` は空）
  - 確認したこと: ボトルが降りる、`yazi --version` / `ya --version` が出る
  - 2026-10-01: 比べ方を直した手順 3 のブロックを、WSL の AlmaLinux 10.2 の擬似端末の bash（使い捨ての `HOME`）に括弧付き貼り付けで貼り、GitHub の yazi 26.9.1 のバイナリを開いて `y` を確かめた。直す前の版と比べ、5 つの場合とも振る舞いは同じだった（[付録](#付録-y-関数の比べ方を直したときの検証2026-10-01)）
  - **コンテナでは TUI の起動とプレビューは確認していない**（端末が無いため）
  - **画像プレビュー（端末側の対応）とプラグインは未検証**
- **状態（Windows 11）**: **Windows 実機では未検証（2026-10-08 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**:
    - 配布物の定義とソース: scoop の main のバケットの `yazi.json`（2026-10-08 に取得。26.9.1）と、yazi 26.9.1 のソース（`ya env` の出力、`--version` の形、Windows の設定・状態・キャッシュの場所、既定の `[opener]`）、scoop 本体のメッセージ（[付録](#付録-windows-11-の節の資料と-linux-での確認2026-10-08)）
    - 配布物: `yazi-x86_64-pc-windows-msvc.zip`（sha256 が `yazi.json` の値と一致）の `yazi.exe`・`ya.exe` が `VCRUNTIME140.dll` を読み込むこと（`objdump -p` のインポート表）
    - PowerShell のブロック 9 個: Linux の PowerShell 7.5.3 の構文解析器（誤り 0）と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査（指摘 0）
    - 偽物の scoop・yazi・ya と、ユーザーの環境変数を記録する偽物での模擬（Windows 11 で使うの手順 2〜6・更新・ロールバック）。偽物の scoop のメッセージは scoop 本体のソースから写したもので、実際の scoop の出力ではない
    - 見直しの後に、ブロックを取り出し直して、構文・互換の検査と模擬をやり直した（[付録](#付録-windows-11-の節の資料と-linux-での確認2026-10-08)の「最後の確認」）
    - 2 回目の見直しの後にも、同じことをやり直した。分けて増えた手順 8 の `bash` のブロック（Git Bash に貼る）は、`bash -n` と、共通の bash 設定の `y` と偽物の yazi で、Linux の bash で流した（[付録](#付録-windows-11-の節の資料と-linux-での確認2026-10-08)の「2 回目の見直しの後の確認」）
    - ロールバックの手順 2 を、`YAZI_FILE_ONE` が Git for Windows の `file.exe` のときだけ消す形に直した後にも、構文・互換の検査と、その手順の模擬をやり直した（[付録](#付録-windows-11-の節の資料と-linux-での確認2026-10-08)の「ロールバックの手順 2 を直した後の確認」）
  - **確かめていないこと**:
    - Windows で貼ること（すべての手順）と、scoop での導入（`$YAZI_EXTRAS` の 9 個を含む）・更新・削除
    - `VCRUNTIME140.dll` が無いときの表示（何も出さずに終わるか、システム エラーの窓が出るか）
    - `ya env` の実際の表示（`Config` の行の `os error 3` と `os error 2`、`file -bL --mime-type` が `text/plain` になること）
    - ユーザーの環境変数 `YAZI_FILE_ONE` と、imagemagick が足す環境変数・`PATH` が、今の窓・新しい窓・WezTerm のタブに効くこと（scoop のソースでは、今の窓にも入れる）
    - TUI のプレビュー（PDF・動画・画像・書庫）と、WezTerm・Windows Terminal・conhost での画像の表示
    - この文書の手順としての、WezTerm の Git Bash の `y`（手順 7・8）
    - Enter でテキストを開いたときのエディタ（自分用の設定では `nvim`、上流の既定の設定では VS Code の `code`）
    - 自分用の設定（README の Windows の例）との組み合わせと、その元に戻し方（`config.bak`）
    - SSH のセッションと、arm64 の Windows
  - 参考: Windows 11 の Git Bash の `y`（共通の bash 設定の同じ関数）は、bash リポジトリの検証記録で、scoop の yazi 26.9.1 を開いて確かめてある（[2026-10-01 の Git Bash の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-11-の-git-bash-での検証記録2026-10-01)。[2026-10-06 の Windows ホストの付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-ホストでの設定の再検証2026-10-06)は、cwd-file を書くスタブで確かめた）。この文書の手順としては流していない

AlmaLinux 10:

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

AlmaLinux 10 の実機（2026-09-21）。Windows 11 の PC は、[Windows 11 で使う](../yazi.md#windows-11-で使う)の手順 3 で確かめる。

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

AlmaLinux 10 の実機（2026-09-21）。Windows 11 は流していないので、記録は無い（入るものは、[Windows 11 で使う](../yazi.md#windows-11-で使う)の手順 6 の箇条書き）。

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


### 付録: Windows 11 の節の資料と Linux での確認（2026-10-08）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物の定義とソースを読み、手順書の PowerShell のブロックを Linux の PowerShell で確かめた記録。**Windows 実機では未検証**。

**資料**（2026-10-08 に取得）:

- scoop の `ScoopInstaller/Main` の `bucket/yazi.json`: `version` は `26.9.1`。64bit は `yazi-x86_64-pc-windows-msvc.zip`、arm64 は `yazi-aarch64-pc-windows-msvc.zip`。`bin` は `ya.exe` と `yazi.exe`。`suggest`・`depends` は無い（VC++ のランタイムも `file` も入れない）
- yazi 26.9.1 の `yazi-cli/src/env/env.rs`（`ya env`）: `Config` の各行は設定のフォルダーのファイル（`yazi.toml` など）と文字数か読めない理由、`Variables` の `YAZI_FILE_ONE` は Rust の `Debug` の形（`Some("…")`。`\` は `\\` で出る）、`Dependencies` の `file` は `YAZI_FILE_ONE`（無ければ `file`）を `--version` で動かした版、最後の `Routine` は一時的なファイルに `Hello, World!` を書いて `file -bL --mime-type` を動かした結果の 1 行目
- yazi 26.9.1 の `yazi-version/src/lib.rs`: `--version` は `Version: <版> (<コミット> <日付>)` と `Triple : <ビルドしたホストの組> (<OS>-<アーキテクチャ>)` の行を出す
- yazi 26.9.1 の `yazi-boot/src/args.rs` と `yazi-cli/src/args.rs`: `yazi` の引数に `--debug` は無く（`--cwd-file`・`--version` など）、環境と設定を出すのは `ya env`（`Print environment and configuration information.`）
- yazi 26.9.1 の `yazi-fs/src/xdg.rs`: Windows の設定は `YAZI_CONFIG_HOME`（絶対パスのとき）か `%APPDATA%\yazi\config`、状態は `%APPDATA%\yazi\state`、キャッシュは `%LOCALAPPDATA%\yazi`。`XDG_CONFIG_HOME` を読むのは Linux などだけ
- yazi 26.9.1 の `yazi-cli/src/env/env.rs` の `config_state`（2 回目の見直しで読んだ）: 設定のフォルダーのファイルを `read_to_string` で読み、読めなければ `<パス> (<エラー>)` を出す
  - フォルダーを作るのは `ya pkg`（`yazi-cli/src/package/mod.rs`）と、yazi の状態のフォルダー（`yazi-dds/src/state.rs`）だけ。`yazi --version` と `ya env` は作らない
- yazi 26.9.1 の `yazi-config/preset/yazi-default.toml` の `[opener]`（2 回目の見直しで読んだ）
  - `edit` は `${EDITOR:-vi} %s`（`for = "unix"`）と、`code %s`（`for = "windows"`・`orphan`）・`code -w %s`（`for = "windows"`・`block`）。`text/*` などの規則は `edit` を最初に使う
  - 自分用の設定（`ryo-aoki-pc/yazi` の `custom`、`1e6b294`）の `yazi.toml` は、Windows の `edit` を `nvim %s`（`block`）と `neovide %s`（`orphan`）にしてある
- yazi 26.9.1 の `yazi-plugin/preset/plugins/mime-local.lua`・`file.lua`（2 回目の見直しで読んだ）: `YAZI_FILE_ONE`（無ければ `file`）を Lua の `Command` で起動する
  - `yazi-binding/src/process/command.rs` の `Command` は `tokio::process::Command::new` で、シェルを挟まない
- scoop 本体のメッセージの文字列（neovim.md の検証記録の付録と同じ）。複数のアプリを並べた `scoop install` は、入っていたものに `'<名前>' (<版>) is already installed. Skipping.` を出す（`libexec/scoop-install.ps1`）
- 同じ日の scoop の main の定義で、`$YAZI_EXTRAS` の 9 個はどれもある（ffmpeg 9.0.2・7zip 26.04・jq 1.8.2・poppler 26.09.0-0・fd 10.5.0・ripgrep 15.2.0・fzf 0.74.4・resvg 0.47.0・imagemagick 7.1.2-32）。`jq` は `jid`、`ripgrep` は `extras/vcredist2022` を `suggest` に持つ。`imagemagick` は `MAGICK_HOME` などのユーザーの環境変数を足す（`env_set`）
- GitHub のリリースの `yazi-x86_64-pc-windows-msvc.zip` の sha256 は `7c033e5f…8d21` で、`yazi.json` の `hash` と一致した。中の `yazi.exe`・`ya.exe` のインポート表（`objdump -p` の `DLL Name`）には `VCRUNTIME140.dll`（と `api-ms-win-crt-*`）がある。Windows の実行ファイルは動かしていない

**構文と Windows PowerShell 5.1 との互換**（Linux の PowerShell 7.5.3 と PSScriptAnalyzer 1.25.0）:

- 手順書の `powershell` のブロック 9 個を取り出し、PowerShell 7.5.3 の構文解析器に通した（構文の誤り 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0（ほかの規則の指摘は、ASCII でない文字を含むブロックの BOM だけ）

**模擬**（Linux の PowerShell 7.5.3）:

- ブロックの文字列のうち、管理者の判定（`WindowsPrincipal`。Linux では使えない）を `$false` に、`[Environment]` のユーザーの環境変数（Linux の .NET では読み書きされない）を、値をハッシュテーブルに記録する偽物のクラスに置き換えた。`$env:WINDIR`・`$env:APPDATA`・`$env:TEMP` と `C:\Program Files\Git\usr\bin\file.exe` は一時的な場所にした。scoop は、渡った引数を記録してメッセージだけを出す偽物の `scoop.ps1`
- Windows 11 で使うの手順 2・4: `$YAZI_EXTRAS` を設定すると、偽物の scoop に `install yazi ffmpeg 7zip jq poppler fd ripgrep fzf resvg imagemagick`（引数 11 個）が渡った。`$YAZI_EXTRAS = @()` では `install yazi`（引数 2 個）
  - 比べるために、変数を確かめない `scoop install yazi @YAZI_EXTRAS` だけを、`$YAZI_EXTRAS` が無い状態（この節の手順 2 を貼っていない新しい窓に当たる）で流すと、空の引数が 1 つ足されて scoop に渡った（引数 3 個）。手順書のブロックは、変数を消して流すと、`中断: この節の手順 2 の $YAZI_EXTRAS が無い。手順 2 を貼り直す` で止まり、scoop は呼ばれなかった
- Windows 11 で使うの手順 3: `FileExe`・`YaziFileOne`・`Config` が、偽物の `file.exe`・環境変数・`%APPDATA%\yazi\config` に当たるフォルダーの有無で変わった
- Windows 11 で使うの手順 5: `file.exe` に当たるファイルが無いときは `中断:` で止まり、環境変数は書かなかった。あるときは、ユーザーの環境変数と今の窓の `$env:YAZI_FILE_ONE` の両方に入り、`YAZI_FILE_ONE = <パス>` が出た
- Windows 11 で使うの手順 6・9: 偽物の yazi・ya で、3 つのコマンドと `yazi` がこの順に動いた（表示は偽物のもの。実際の `ya env` は流していない）
- ロールバックの手順 1: yazi と ya が PATH にあるときは `Source` の表に 2 行が出て、無いときは `Get-Command` の行は何も出さなかった
- ロールバックの手順 2: ユーザーの環境変数と今の窓の値が消え、`YAZI_FILE_ONE = ` が出た。無いときに貼り直しても、エラーにならなかった

**最後の確認**（見直しの後。レビューの指摘で手順書・検証記録・参考資料を直した後に、同じ Linux のコンテナで確かめ直した。**Windows 実機では未検証**）:

- 手順書の `powershell` のブロックを取り出し直した。yazi.md は 9 個で、中身は直す前と同じだった（直したのは箇条書きと 1 行の説明だけで、ブロックの位置だけが変わった）
- PowerShell 7.5.3 の構文解析器で、構文の誤りは 0。PSScriptAnalyzer 1.25.0 の 5.1 互換の 3 規則の指摘は 0。ほかの規則の指摘は、Windows 11 で使うの手順 2・4・5 の BOM の 3 件だけ（ASCII でない文字を含む）
- 偽物の scoop は、neovim.md の検証記録の付録の「最後の確認」と同じもの（メッセージは scoop 本体のソースから写した。実際の scoop の出力ではない）。前の模擬の偽物が、更新で新しい版が無いときに出していた `The latest version of …` は、手で書いたもので、scoop の振る舞いから取ったものではない
- imagemagick の環境変数が今の窓にも入ることは、scoop 本体のソースで読んだだけ（`lib/install.ps1` の `env_set` の `Set-Content env:\$name`、`lib/system.ps1` の `Add-Path` の「current session」の `$env:PATH`。scoop の `.ps1` は同じ PowerShell の中で動く）。模擬はしていない
- 模擬の結果（18 通り。表示は偽物のもの）:
  - Windows 11 で使うの手順 4: 手順 2 の `$YAZI_EXTRAS` で、偽物の scoop に `install yazi ffmpeg 7zip jq poppler fd ripgrep fzf resvg imagemagick`（引数 11 個）が渡った。7zip を入っている扱いにすると、`WARN  '7zip' (26.04) is already installed. Skipping.` の後に残りの 9 個が入った
  - 同じ手順 4: `@()` では `install yazi`、`@('fd')` では `install yazi fd`。`@()` を付けずに `$YAZI_EXTRAS = 'fd'` にすると、`install yazi f d`（引数 4 個）が渡った（文字列が 1 文字ずつに分かれる。手順 2 の箇条書きに足した）。変数が無いときは `中断:` で止まり、scoop は呼ばれなかった
  - 手順 3: `YAZI_FILE_ONE` に別の値（scoop の `file` の場所に当たる文字列）を入れておくと、`YaziFileOne` にその値が出た。続く手順 5 は確かめずに Git for Windows の `file.exe` に書き換え、ユーザーの値と今の窓の値の両方が変わった（手順 3 の箇条書きに、上書きされることを足した）
  - 手順 5: `file.exe` に当たるファイルが無いときは `中断:` で止まり、値は書かなかった（前の記録と同じ）
  - 更新の手順 1: 新しい版が無いときは `yazi: 26.9.1 (latest version)` と `Latest versions for all apps are installed! For more information try 'scoop status'`
  - ロールバックの手順 1・2: 前の記録と同じ（`Get-Command` の行は、yazi と ya が PATH に無ければ何も出さない。`YAZI_FILE_ONE` はユーザーと今の窓から消え、2 回目もエラーにならない）
- ロールバックのリードに足した 2 つの確認（`git -C "$env:APPDATA\yazi\config" status --short` と `… log --oneline '@{u}..'`）:
  - PowerShell 7.5.3 の構文解析器で誤り 0。`'@{u}..'` は 1 つの引数になった（引用符が無いと、`@{` がハッシュテーブルとして読まれる）
  - Linux の git 2.43.0 で、上流のある使い捨ての clone を `$env:APPDATA` の下に置いて流した（`\` は `/` にした）。push 済みのときは 2 つとも何も出さなかった。push していないコミットを 1 つ足すと、`status --short` は何も出さず、`log --oneline '@{u}..'` だけがそのコミットを出した

**2 回目の見直しの後の確認**（2026-10-08。2 回目のレビューの指摘で手順書・検証記録・参考資料を直した後に、同じ Linux のコンテナで確かめ直した。**Windows 実機では未検証**）:

- 手順書の変更: Windows 11 で使うの手順 7 は、コマンドの無い手順の箇条書きで `type -t y` と `y` を打たせていた
  - Git Bash のタブを開く手順 7（コマンドの無い手順）と、`type -t y`・`y` の `bash` のブロックの手順 8 に分けた。PowerShell の `yazi` は手順 9 になった
  - ほかの変更は、箇条書き・リード・1 行の説明だけ
- 手順書の `powershell` のブロックを取り出し直した。yazi.md は 9 個で、中身は前の確認と同じだった（位置と、TUI の手順の番号だけが変わった）。`bash` のブロックは、Windows 11 で使うの手順 8 の 1 個が増えた
- PowerShell 7.5.3 の構文解析器で、構文の誤りは 0。PSScriptAnalyzer 1.25.0 の 5.1 互換の 3 規則の指摘は 0。ほかの規則の指摘は、Windows 11 で使うの手順 2・4・5 の BOM の 3 件だけ
- 偽物の scoop・yazi・ya での模擬を、前の確認と同じ 18 通りで流し直した。結果は前の確認と同じだった（TUI の手順は手順 9 として流した。表示は偽物のもの）
  - `@()` を付けずに `$YAZI_EXTRAS = 'fd'` にすると、偽物の scoop に `install yazi f d`（引数 4 個）が渡り、`@('fd')` では `install yazi fd`（引数 3 個）だった。Linux の PowerShell 7.5.3 だけで流し、Windows PowerShell 5.1 では流していない
- Windows 11 で使うの手順 8 の `bash` のブロック: `bash -n` で誤り 0
  - Linux の bash 5.2.21 で、bash リポジトリ（`bdb64c2`）の `bashrc` の `y` を定義し、`--cwd-file` にフォルダーを書く偽物の yazi で、ブロックをそのまま流した
  - `type -t y` は `function` を出した。偽物の yazi が別のフォルダー（名前に空白と日本語を含む）を書くと、`y` の後にそのフォルダーへ移った。何も書かないとき（`Q` に当たる）と、同じフォルダーを書いたときは、移らなかった
  - Windows の Git Bash と WezTerm のタブでは流していない
- `ya env` の `Config` の行: Linux の `ya` 26.9.1（GitHub のリリースの `yazi-x86_64-unknown-linux-gnu.zip`）を擬似端末で動かした
  - `YAZI_CONFIG_HOME` を無いフォルダーにしても、空のフォルダーにしても、6 行とも `No such file or directory (os error 2)` だった。無いフォルダーは作られなかった
  - Linux は、フォルダーが無いときもファイルが無いときも ENOENT（2）を返す。最初に手順書に書いた `os error 2` は、この振る舞いに当たる
  - Windows では、フォルダーが無いと ERROR_PATH_NOT_FOUND（`os error 3`）、フォルダーがあってファイルが無いと ERROR_FILE_NOT_FOUND（`os error 2`）になるはずなので、手順書の箇条書きを両方に分けた。Windows では流していない

**ロールバックの手順 2 を直した後の確認**（2026-10-08。git-delta.md などの Windows 11 の節が入った版に載せ替えた後のレビューの指摘で直してから、同じ Linux のコンテナで確かめ直した。**Windows 実機では未検証**）:

- 手順書の変更: Windows 11 のロールバックの手順 2 は、`YAZI_FILE_ONE` を値に関係なく消していた
  - 値が `C:\Program Files\Git\usr\bin\file.exe` のときだけ消し、今の窓の値はユーザーの値に合わせる形にした。Windows 11 で使うの手順 3 で控えた元の値は、その箇条書きの 1 行で戻す
  - ほかの変更は、箇条書き・リード・1 行の説明だけ（Windows 11 で使うの手順 7・8 の条件に WezTerm の自分用の設定を足した、など）
- 手順書の `powershell` のブロックを取り出し直した。yazi.md は 9 個で、ロールバックの手順 2 のほかは前の確認と同じだった
- PowerShell 7.5.3 の構文解析器で、構文の誤りは 0。PSScriptAnalyzer 1.25.0 の 5.1 互換の 3 規則の指摘は 0。ほかの規則の指摘は、Windows 11 で使うの手順 2・4・5 の BOM の 3 件だけ
- 模擬（ユーザーの環境変数は、前の記録と同じく値をハッシュテーブルに記録する偽物）:
  - 値が Git for Windows の `file.exe` のときは、ユーザーの値と今の窓の値が消え、`YAZI_FILE_ONE = ` が出た。2 回目もエラーにならなかった。大文字と小文字だけが違う値（`c:\program files\git\usr\bin\FILE.EXE`）も消えた
  - ほかの値（scoop の `file` の場所に当たる文字列）は残り、`YAZI_FILE_ONE = <その値>` が出て、今の窓の値もその値になった
  - ほかの値を入れておき、Windows 11 で使うの手順 5（`file.exe` は一時的な場所の空のファイル）→ ロールバックの手順 2 → 箇条書きの 1 行（控えた値を入れたもの）の順に流すと、ユーザーの値は元の値に戻った（今の窓の値は空のまま）

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（scoop での導入・更新・削除）
1. `VCRUNTIME140.dll` が無い PC で、`yazi --version` が何も出さずに終わるか、システム エラーの窓が出るか
1. `ya env` の `Routine` が `text/plain` になり、`Dependencies` に `$YAZI_EXTRAS` のツールの版が出ること
1. `ya env` の `Config` の行が、設定のフォルダーが無いときに `os error 3`、フォルダーはあってファイルが無いときに `os error 2` になること
1. ユーザーの環境変数 `YAZI_FILE_ONE` が、新しい窓と WezTerm のタブに効くこと
1. TUI のプレビュー（PDF・動画・画像・書庫）と、WezTerm・Windows Terminal・conhost での画像の表示
1. WezTerm の Git Bash のタブ（手順 7）に手順 8 の `bash` のブロックを貼り、`y`（共通の bash 設定）で閉じたフォルダーへ移ること
1. Enter でテキストを開いたときのエディタ（自分用の設定では `nvim`、上流の既定の設定では `code`）
1. 自分用の設定（`%APPDATA%\yazi\config` への clone）との組み合わせ
1. SSH のセッションと、arm64 の Windows

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

