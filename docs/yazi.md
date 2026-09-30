# yazi 最新版インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew は root で動かない）
> - **手順 4 で TUI が開く**。`q` で終了してから、ほかのコマンドを貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 設定を書く場所と、自分用の設定（`ryo-aoki-pc/yazi`）への案内は[設定ファイル](#設定ファイル)。以後は[更新](#更新)・[ロールバック](#ロールバック)

1. 変数を設定する。

   ```bash
   YAZI_EXTRAS="ffmpeg-full sevenzip jq poppler fd ripgrep fzf resvg imagemagick-full font-symbols-only-nerd-font"   # プレビューと検索に使う。空にすると yazi 本体だけ
   printf 'YAZI_EXTRAS = %s\n' "${YAZI_EXTRAS}"
   ```

   - **編集が必須の変数は無い**。プレビュー・検索用のツールを一緒に入れる想定になっている
   - 最小構成にするなら、`YAZI_EXTRAS` を空にする
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

   <details>
   <summary>補足: 変数について</summary>

   - `YAZI_EXTRAS` に並べているのは、yazi が外部コマンドとして呼ぶツール。役割は手順 2 の補足にまとめた
   - `ffmpeg-full` と `imagemagick-full` は、Homebrew の `ffmpeg` / `imagemagick` に対してコーデック・フォーマットを広く有効にしたビルド（どちらも `homebrew/core` の formula）

   </details>

1. brew で yazi と、プレビュー・検索に使うツールを入れる。

   ```bash
   brew install yazi ${YAZI_EXTRAS}
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない

   <details>
   <summary>補足: ボトルと、依存ツールの役割</summary>

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

   `zoxide` も yazi から使える（`z` キーでのジャンプ）。本書では[別手順](zoxide.md)で入れている。

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

   </details>

1. 終了した場所へ移動するシェル関数 `y` を、`~/.bashrc` に書く。

   ```bash
   cat >> ~/.bashrc <<'EOF'
   function y() {
   	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
   	command yazi "$@" --cwd-file="$tmp"
   	IFS= read -r -d '' cwd < "$tmp"
   	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
   	command rm -f -- "$tmp"
   }
   EOF
   . ~/.bashrc
   ```

   - yazi をそのまま終了しても、シェルのディレクトリは動かない
   - 公式が案内しているこの関数を入れると、`q` で終了したときに移動先へ `cd` する
   - 元の場所で終わりたいときは `Q`

   <details>
   <summary>補足: <code>y</code> 関数</summary>

   yazi は終了時に `--cwd-file` で指定したファイルへ最後のディレクトリを書き出す。シェル側の関数がそれを読んで `cd` する、という作り（プロセスは親シェルのディレクトリを変えられないため）。

   - 関数名を `y` にしているのは、公式の例に合わせたもの
   - `command yazi` と書いているのは、関数と実体を取り違えないため

   </details>

1. yazi が入ったか確かめ、`y` で起動する。

   ```bash
   yazi --version
   ya --version
   brew list --versions yazi
   y
   ```

   - `Version: 26.9.1 (Homebrew ...)`、`Triple: aarch64-unknown-linux-gnu` のように出る
   - `ya` は付属のプラグイン管理コマンド
   - 最後の `y` で起動して確認する
   - `y` で起動したときは、終了時にそのディレクトリへ移動する
   - プレビューを確かめるには、PDF・動画・画像・書庫のあるディレクトリで右ペインを見る
   - 画像プレビューは端末側の対応が要る（[注意点](#注意点)）
   - 画面が出たら `q` で終了する
   - **ほかのコマンドは、`q` で終了してから貼る**（続けて貼ると yazi への操作として食われる）

---

## 設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は `~/.config/yazi/` で、ファイル名は `yazi.toml`（全般）/ `keymap.toml`（キー割り当て）/ `theme.toml`（配色）
- **既定値のファイルは配布物に入っていない**（実測: `brew list yazi` に含まれる `.toml` は `.crates.toml` だけ）
- 既定値は[公式ドキュメントの Configuration](https://yazi-rs.github.io/docs/configuration/overview/) か、リポジトリの `yazi-config/preset/` を見る
- **自分用の設定**は [ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi) にある（上流の既定の設定を丸ごと置き、3 ペインの比率・行表示・独自のキー割り当てなどを変えた設定）
  - 入れ方は [README の「インストール」](https://github.com/ryo-aoki-pc/yazi#インストール)。`custom` ブランチを `~/.config/yazi` に clone する
  - 足したキーは [README の「独自キーバインド」](https://github.com/ryo-aoki-pc/yazi#独自キーバインド抜粋)、使う外部コマンドは[「依存コマンド」](https://github.com/ryo-aoki-pc/yazi#依存コマンド)
  - 外部コマンドのうち fd・ripgrep・fzf は手順 2 の `YAZI_EXTRAS` で入る。エディタの nvim は [neovim.md](neovim.md)、zoxide は [zoxide.md](zoxide.md) で入れる
  - この設定を入れるなら、この節の手順 1 は要らない（clone が `~/.config/yazi` を作る）

1. 設定を書くときは、空のディレクトリを作って変更したい項目だけを書く。

   ```bash
   mkdir -p ~/.config/yazi
   ```

   - プラグインとテーマは `ya pkg add`（引数はリポジトリ名）で入れる。`~/.config/yazi/package.toml` に記録される
   - 本書ではプラグインは扱っていない

---

## 更新

1. brew で yazi を更新する。

   ```bash
   brew upgrade yazi
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - `brew outdated` で先に確認できる

---

## ロールバック

- 本書ではロールバックは**本実行していない**

1. brew で yazi を消す。

   ```bash
   brew uninstall yazi
   ```

   - 依存ツール（`YAZI_EXTRAS` で入れたもの）は他でも使うので、消すなら個別に指定する
   - `~/.bashrc` に書いた `y()` 関数と `~/.config/yazi/` は残るので、要らなければ手で消す

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 にターミナルファイルマネージャ [yazi](https://yazi-rs.github.io/) の最新版を入れ、プレビューと検索が効く状態にする
- **進め方**: Homebrew で本体と依存ツールをまとめて入れる
  - **読者が書き換えるのは冒頭の変数ブロック（依存ツールの一覧）だけ**
  - RPM（COPR）経路も試したうえで採らなかった（[選択した方針](#選択した方針)）
- **状態**: **実機で本実行済み（2026-09-21）**
  - 下表のホストで `brew install yazi ...` を実行し、`yazi 26.9.1` が入って常用中。`~/.bashrc` の `y()` 関数も同じ形で入っている
  - [Homebrew の導入](homebrew.md)と手順 2・4 は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した（`YAZI_EXTRAS` は空）
  - 確認したこと: ボトルが降りる、`yazi --version` / `ya --version` が出る
  - **コンテナでは TUI の起動とプレビューは確認していない**（端末が無いため）
  - **画像プレビュー（端末側の対応）とプラグインは未検証**

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-21 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| 入った yazi | `yazi 26.9.1`（`arm64_linux` ボトル、Rustc 1.98.0 ビルド） | 同じ（`26.9.1`） |
| 依存ツール | `ffmpeg-full 9.0.2` / `sevenzip 26.03` / `jq 1.8.2` / `poppler 26.09.0` / `fd 10.5.0` / `ripgrep 15.2.0` / `fzf 0.74.4` / `resvg 0.48.1` / `imagemagick-full 7.1.2-31` / `font-symbols-only-nerd-font 3.5.1` | 本体のみ（formula の存在確認だけ実施） |
| 端末 | WezTerm nightly（[wezterm-nightly.md](wezterm-nightly.md)） | 無し |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
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

**COPR 版を外した理由**（実機の記録）:

- 2026-09-20 18:56 に `dnf copr enable lihaohong/yazi` → `dnf install yazi` で `yazi-26.9.1-1.el10.aarch64` を導入
  - 同時に入ったのは `resvg-0.47.0-1.el10` と `poppler-utils-24.02.0-7.el10_2.2` の 2 つだけ
- 翌朝 09:29 に `dnf remove yazi-26.9.1-1.el10.aarch64` で 3 パッケージとも削除し、Homebrew 版に入れ替えている
- RPM 側ではプレビュー用のツールを別々に集める必要があり、`ffmpeg` に至っては EL10 の標準リポジトリにも EPEL にも無い（`ffmpeg-free` のみ）

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

### 注意点

- **PATH の先頭が Homebrew になる**: `brew shellenv` が `/home/linuxbrew/.linuxbrew/bin` を PATH の先頭に置くので、同名のコマンドは RPM 版より Homebrew 版が勝つ
  - RPM 版と両方入れると分かりにくくなるので、どちらか一方にする
- **画像プレビューは端末に依存する**: Kitty / WezTerm / foot などのグラフィックプロトコル、または Überzug++ が要る。GNOME 端末では文字ベースの表示になる
- **`q` と `Q`**: `y` 関数経由なら `q` で終了時にそのディレクトリへ移動し、`Q` なら移動しない
- **Homebrew の更新は自分の責任で**: `brew upgrade` は指定しなければ全 formula を上げる。yazi だけ上げるなら `brew upgrade yazi`
- **sudo 環境では使えない**: `sudo yazi` は root の PATH に Homebrew が無いので動かない。root で使いたいならフルパスで呼ぶ

### 参照

- [Installation — Yazi](https://yazi-rs.github.io/docs/installation/) — 経路一覧と依存ツール（ffmpeg / 7-Zip / jq / poppler / fd / ripgrep / fzf / zoxide / ImageMagick）
- [Quick Start — Yazi](https://yazi-rs.github.io/docs/quick-start/) — `y` シェル関数（`--cwd-file`）の原典
- [Configuration — Yazi](https://yazi-rs.github.io/docs/configuration/overview/) — `yazi.toml` / `keymap.toml` / `theme.toml`
- [ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi) — 自分用の設定。入れ方・独自のキー・上流との差分の管理は README にある
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで、非 root ユーザーを作って[Homebrew の導入](homebrew.md)と手順 2・4 を通した。実機で加えた変更は `dnf install podman` だけ。 実行したのは**この文書のコードブロックをそのまま抜き出したスクリプト**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。 端末が要る `y` の 1 行と、`YAZI_EXTRAS` の中身（空にした）だけ除いている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git sudo` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6` が `/home/linuxbrew/.linuxbrew` に入った（[homebrew.md](homebrew.md)） |
| 2. yazi | `brew install yazi` → `Pouring yazi--26.9.1.arm64_linux.bottle.tar.gz`（17 files, 32.5MB）。ソースビルドは発生しない |
| 4. 検証 | `yazi --version` / `ya --version` ともに `26.9.1 (Homebrew 2026-09-01)`、`Triple: aarch64-unknown-linux-gnu` |
| 依存ツール | `ffmpeg` / `sevenzip` / `jq` / `poppler` / `fd` / `ripgrep` / `fzf` / `resvg` / `imagemagick` / `font-symbols-only-nerd-font` の formula がすべて存在することを `brew info` で確認（インストールはしていない。実機には `-full` 版が入っている） |
| 設定ファイル | 配布物に既定の `*.toml` は含まれない（`brew list yazi` の `.toml` は `.crates.toml` のみ） |
| RPM 経路 | COPR `lihaohong/yazi` を有効化して `dnf install --assumeno yazi` → 115 パッケージ・63 MB に解決。EPEL の `ffmpeg-free 7.1.2` / `fd-find 10.4.2` / `ripgrep 14.1.1` / `fzf 0.58.0` はいずれも Homebrew 版より古い |

#### 未確認事項

- TUI の起動・キー操作・プレビュー（コンテナに端末が無いため。実機では常用している）
- 画像プレビュー（WezTerm 側のグラフィックプロトコル対応）
- `ya pkg` で入れるプラグイン・テーマ
- `YAZI_EXTRAS` を空にした最小構成での動作
- ロールバック（`brew uninstall`）の本実行
