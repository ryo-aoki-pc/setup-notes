# bat 最新版インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew は root で動かず、設定も自分の `~/.config` に書くため）

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: `man` や `fzf` のプレビューに使うなら[ページャに使う（任意）](#ページャに使う任意)。設定は[設定ファイル](#設定ファイル)、以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **コンテナでのみ検証した手順書**で、実機では本実行していない（[対象と検証環境](#対象と検証環境)）。

1. 変数を設定する。

   ```bash
   BAT_THEME_NAME=ansi               # 使うテーマ。ansi は端末の 16 色にそのまま従う。<BAT_THEME_NAME>
   printf 'BAT_THEME_NAME = %s\n' "${BAT_THEME_NAME}"
   ```

   - **編集が必須の変数は無い**。既定のまま進められる
   - 端末の配色に合わせたいときだけ `BAT_THEME_NAME` を変える（候補は[設定ファイル](#設定ファイル)の `bat --list-themes` で出る）
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

   <details>
   <summary>補足: 変数について</summary>

   - `ansi` は「端末が設定している 16 色をそのまま使う」テーマで、端末の配色を変えたときに追従する。固定の配色にしたいなら `bat --list-themes` から選ぶ

   </details>

1. brew で bat を入れる。

   ```bash
   brew install bat
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - 依存の `libgit2` と `oniguruma`、その先の `openssl@3` などもまとめて入る

   <details>
   <summary>補足: ボトルと、一緒に入る依存</summary>

   aarch64 で降ってくるボトルは `bat--0.26.1.arm64_linux.bottle.tar.gz`。

   bat が直接要求するのは `libgit2`（変更行の `changes` 表示に使う）と `oniguruma`（正規表現）の 2 つだが、`libgit2` がさらに 6 つを引く。コンテナでの `brew deps --tree bat`:

   ```
   bat
   ├── libgit2
   │   ├── libssh2
   │   │   ├── openssl@3
   │   │   │   └── ca-certificates
   │   │   └── zlib-ng-compat
   │   ├── llhttp
   │   ├── openssl@3
   │   │   └── ca-certificates
   │   ├── pcre2
   │   │   ├── zlib-ng-compat
   │   │   └── bzip2
   │   └── zlib-ng-compat
   └── oniguruma
   ```

   この依存は [eza](eza.md)（`libgit2`）と [git-delta](git-delta.md)（`libgit2` / `oniguruma`）と共通なので、3 つとも入れる場合は 2 本目以降の取得がほとんど無くなる。

   </details>

1. bat が入ったことと、色と行番号が付くことを確かめる。

   ```bash
   bat --version
   brew list --versions bat
   command -v bat
   bat --color=always --style=numbers /etc/os-release | head -5
   ```

   - 版は `bat 0.26.1` のように出る
   - 最後の行で、色と行番号が付くことを確かめる
   - 行番号付きで `NAME="AlmaLinux"` から 5 行出る
   - **`--color=always` を外してパイプに繋ぐと、装飾の無い `cat` と同じ出力になる**。この確認で明示的に付けているのはそのため

   <details>
   <summary>補足: TTY かどうかで出力が変わる</summary>

   bat は出力先が端末かどうかで既定の挙動を変える。**パイプやリダイレクトに繋ぐと、色も行番号もページャも自動的に切れて素の `cat` と同じになる**。コンテナ（端末なし）での実測:

   ```
   $ bat /etc/os-release | head -3
   NAME="AlmaLinux"
   VERSION="10.2 (Lavender Lion)"
   RELEASE_TYPE=stable
   $ bat --color=always --style=numbers /etc/os-release | head -2
      1 NAME="AlmaLinux"
      2 VERSION="10.2 (Lavender Lion)"
   ```

   - この切り替えのおかげで、`bat` をスクリプトの中で `cat` の代わりに使っても壊れにくい
   - 強制したいときは `--color=always` と `--paging=never`（または `-p`）を明示する

   </details>

---

## ページャに使う（任意）

- `MANPAGER` も `fzf` のプレビューも**端末が要る**ので、この文書では実行結果を確認していない（[未確認事項](#未確認事項)）

1. `man` の表示を色付きにするため、`~/.bashrc` に `MANPAGER` を足す。

   ```bash
   cat >> ~/.bashrc <<'EOF'
   export MANPAGER="sh -c 'col -bx | bat -l man -p'"
   EOF
   . ~/.bashrc
   printf '%s\n' "${MANPAGER}"
   ```

   - 自分用の bash の設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）を入れたホストでは、このブロックは貼らない。代わりに `. ~/.bashrc` を実行する（その設定が同じ `MANPAGER` を読む）

1. `fzf` を入れてあるときだけ、ファイル選択のプレビューにも bat を使う。

   ```bash
   fzf --preview 'bat --color=always --style=numbers {}'
   ```

   - `fzf` の導入は [yazi.md 手順 2](yazi.md#実施手順) 参照

---

## 設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は `~/.config/bat/config`（`bat --config-file` で確認できる）
  - 既定の場所に置く限り bat は自分で見つける。別の場所に置きたいときだけ `BAT_CONFIG_PATH` を `~/.bashrc` に `export` する

1. よく変える 3 つだけを書いた、最小の設定ファイルを置く。

   ```bash
   mkdir -p ~/.config/bat
   cat > ~/.config/bat/config <<EOF
   --theme="${BAT_THEME_NAME:?手順 1 の BAT_THEME_NAME が空のまま。値を入れて貼り直す}"
   --style="numbers,changes,header"
   --paging=never
   EOF
   cat ~/.config/bat/config
   bat --config-file
   ```

   - テーマの一覧は `bat --list-themes`、認識する言語の一覧は `bat --list-languages`
   - 自前のシンタックス定義やテーマを足したときだけ `bat cache --build` が要る（キャッシュの場所は `bat --cache-dir`）

---

## 更新

1. brew で bat を更新する。

   ```bash
   brew upgrade bat
   ```

   - すべてまとめて上げるなら `brew upgrade`

---

## ロールバック

- 本書ではロールバックは**本実行していない**

1. brew で bat を消す。

   ```bash
   brew uninstall bat
   ```

   - 依存として入った `libgit2` / `oniguruma` は、他の formula（[eza](eza.md) / [git-delta](git-delta.md)）も使う。まとめて整理するなら `brew autoremove` で、不要になったものだけ消える

1. 設定とキャッシュも消すときだけ、`~/.config/bat` と `~/.cache/bat` を消す。

   ```bash
   rm -rf ~/.config/bat ~/.cache/bat        # 設定とキャッシュも消す場合
   ```

1. ページャの行を足していたときだけ、`~/.bashrc` からその行を消す。

   ```bash
   sed -i '/MANPAGER=.*bat/d' ~/.bashrc     # ページャの行を足していた場合
   ```

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [bat](https://github.com/sharkdp/bat)（シンタックスハイライトと git 連携が付いた `cat`）の最新版を入れる。**EPEL には 0.24.0 があるが 2 マイナー古い**
- **進め方**: Homebrew で入れ、必要なら `~/.config/bat/config` を置く。**読者が書き換えるのは冒頭の変数ブロックだけ**
- **状態**: **コンテナでのみ検証済み（2026-09-22）。実機には入れていない**
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**[Homebrew の導入](homebrew.md)と手順 2〜3、[設定ファイル](#設定ファイル)の節を通した
  - 確認したこと: `arm64_linux` のボトルが降りる、`bat 0.26.1` が入る、`--color=always --style=numbers` で行番号と色が付く
  - **確認していないこと**: ページャとしての表示（`man` / `fzf --preview`）。コンテナには端末が無いため
  - **実機（Raspberry Pi 5）では本実行していない**ので、下表の実機列は「この手順を適用した結果」ではなく**現時点の状態**を書いてある

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| bat | **未導入**（EPEL の `bat 0.24.0-13.el10_2` も入れていない） | `bat 0.26.1`（`arm64_linux` ボトル） |
| 一緒に入る依存 | — | `libgit2` / `oniguruma` とその先 7 つ |
| 端末 | WezTerm nightly（[wezterm-nightly.md](wezterm-nightly.md)） | 無し（pty を与えずに実行） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${BAT_THEME_NAME}` | 設定ファイルに書く `--theme` の値 | `ansi`（既定）/ `Nord` / `Dracula` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`0.26.1`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| bat | 未導入（Homebrew・EPEL とも） |
| Homebrew | 7.0.6 導入済み |
| EPEL | 有効（`epel-release 10-8.el10_2`）。`bat 0.24.0-13.el10_2` が入手できる状態 |
| 関連ツール | `fzf 0.74.4` / `ripgrep 15.2.0` / `fd 10.5.0` が Homebrew で導入済み（[yazi.md](yazi.md)） |

### 選択した方針

AlmaLinux 10 aarch64 で bat を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `bat 0.26.1` の `arm64_linux` ボトルがある。upstream の最新と一致 | **採用** |
| EPEL | `bat.aarch64 0.24.0-13.el10_2`。実行ファイルは `/usr/bin/bat`（Debian 系と違って `batcat` にはならない）。root でも使え `dnf upgrade` に乗るが、**2 マイナー古い** | 不採用（[neovim.md](neovim.md) と同じ判断） |
| 公式のバイナリ配布 | GitHub Releases に `aarch64-unknown-linux-gnu` / `musl` のビルドがある。展開して PATH に置くだけだが、更新は手作業 | 不採用（Homebrew に揃える） |
| `cargo install bat` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

コンテナで取った EPEL 側の実測:

```
$ dnf -q list --showduplicates bat
Available Packages
bat.aarch64                        0.24.0-13.el10_2                         epel
$ dnf -q repoquery -l bat | grep bin/
/usr/bin/bat
```

**名前が `bat` で衝突するので、EPEL 版と Homebrew 版を両方入れてはいけない。**

- 両方入っていると、PATH の先頭にある Homebrew 版が勝つ
- `dnf upgrade` で上がるのは、使われないほうになる

### 完了時点の状態

**検証コンテナでの出力**（実機では本実行していない）:

```
$ bat --version
bat 0.26.1
$ brew list --versions bat
bat 0.26.1
$ command -v bat
/home/linuxbrew/.linuxbrew/bin/bat
$ bat --config-file
/home/<USER>/.config/bat/config
$ bat --config-dir
/home/<USER>/.config/bat
$ bat --cache-dir
/home/<USER>/.cache/bat
$ cat ~/.config/bat/config
--theme="ansi"
--style="numbers,changes,header"
--paging=never
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/bat/0.26.1/`（15 ファイル、5.4 MB）。

### 注意点

- **`alias cat=bat` は勧めない**。`bat` と打つ運用を勧める
  - bat は既定でページャ（`less`）を開くので、`cat` のつもりで打つと画面が切り替わる
  - `-A` / `-v` / `-e` などフラグの意味も GNU `cat` と違う
  - エイリアスは対話シェルにしか効かないのでスクリプトは壊れないが、**壊れないぶん挙動の違いに気づきにくい**
- **EPEL 版と二重に入れない**: どちらも `bat` という名前で、PATH の先頭にある Homebrew 版が勝つ。[選択した方針](#選択した方針)を参照
- **Homebrew 全般の注意は [homebrew.md の注意点](homebrew.md#注意点)**: PATH の先頭が Homebrew になる、`sudo bat` は使えない、など
- **root で読むなら `sudo cat`**: bat で読むなら、フルパスで `sudo /home/linuxbrew/.linuxbrew/bin/bat`
- **テーマの見え方は端末に依存する**: `ansi` 以外を選ぶと端末の配色とぶつかることがある。true color が出るかは端末側の設定次第

### 参照

- [sharkdp/bat — README](https://github.com/sharkdp/bat) — 使い方、テーマ、`MANPAGER` や `fzf` との組み合わせ、他ツールとの連携例
- [bat — Customization](https://github.com/sharkdp/bat#customization) — 設定ファイルの書式、テーマとシンタックスの追加手順
- `bat --help` / `bat --list-themes` / `bat --list-languages` — フラグとテーマ・言語の一覧
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](homebrew.md)と手順 2〜3、[設定ファイル](#設定ファイル)の節を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。同じコンテナで [eza](eza.md) / [git-delta](git-delta.md) / [gdu](gdu.md) / [starship](starship.md) も続けて入れている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](homebrew.md)） |
| 2. bat | `Pouring bat--0.26.1.arm64_linux.bottle.tar.gz` → `15 files, 5.4MB`。依存 9 つ（`ca-certificates` / `openssl@3` / `zlib-ng-compat` / `libssh2` / `llhttp` / `bzip2` / `pcre2` / `libgit2` / `oniguruma`）もすべてボトル。ソースビルドは発生しない |
| 3. 検証 | `bat --version` → `bat 0.26.1`。`bat --color=always --style=numbers /etc/os-release` は行番号と ANSI エスケープ付きで出た。`--color` を外してパイプに繋ぐと素の出力になることも確認 |
| 設定ファイル | `~/.config/bat/config` を置いて `bat --config-file` が同じパスを返し、`--style=numbers` が効くことを確認 |
| `MANPAGER` | **確認できず**。コンテナに `man ls` のページが無く（`coreutils-common` 未導入）、`man-db` を入れて `man man` を試しても**パイプ越しでは man 自体がページャを呼ばない**ため、色が付くかは判定できなかった |
| RPM 経路 | `dnf -q list --showduplicates bat` → `0.24.0-13.el10_2 epel`。`dnf -q repoquery -l bat \| grep bin/` → `/usr/bin/bat` |

#### 未確認事項

- 実機での本実行（本書は実機に適用していない。検証はコンテナのみ）
- 端末での実際の見え方（テーマ、true color、ページャ `less` の起動）
- `MANPAGER` を設定した `man` の表示
- `fzf --preview` との組み合わせ
- `bat cache --build`（自前のシンタックス・テーマの追加）
- EPEL 版（0.24.0）と併用した場合の挙動
- ロールバック（`brew uninstall` と `~/.config/bat` の削除）の本実行
