# zoxide 最新版インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew は root で動かず、設定も自分の `~/.bashrc` に書くため）

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 以後は[更新](#更新)・[ロールバック](#ロールバック)

1. 変数を設定する。

   ```bash
   ZOXIDE_CMD=z                    # zoxide が定義するコマンド名。cd にすると cd を置き換える。<ZOXIDE_CMD>
   printf 'ZOXIDE_CMD = %s\n' "${ZOXIDE_CMD}"
   ```

   - **編集が必須の変数は無い**。既定では `z` コマンドが増えるだけで、`cd` はそのまま残る
   - `cd` 自体を置き換えたい場合だけ、`ZOXIDE_CMD=cd` にする
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

   <details>
   <summary>補足: 変数について</summary>

   `--cmd cd` を渡すと `cd` 自体が zoxide の関数に置き換わり、`cd foo` が「まず実在するディレクトリ、無ければ履歴から推測」という動きになる。

   - 便利な反面、**スクリプトやツールが呼ぶ `cd` の挙動まで変わる**ので、本書の既定は `z`（`cd` はそのまま）にしてある
   - 実機も `--cmd` 無し（＝ `z`）で入れてある

   </details>

1. brew で zoxide と fzf を入れる。

   ```bash
   brew install zoxide fzf
   ```

   - `fzf` は必須ではないが、入れておくと候補から選ぶ `zi` が使える
   - aarch64 でもビルド済みのボトルが降ってくる

1. `~/.bashrc` のいちばん最後に、zoxide の初期化の 1 行を書く。

   ```bash
   printf 'eval "$(zoxide init bash --cmd %s)"\n' "${ZOXIDE_CMD:?手順 1 の ZOXIDE_CMD が空のまま。値を入れて貼り直す}" >> ~/.bashrc
   . ~/.bashrc
   type -t "${ZOXIDE_CMD}"
   ```

   - いちばん最後に置く理由は、この手順の補足
   - **この 1 行を書かないと `z` は使えない**（zoxide 本体はシェル関数を出力するだけで、`zoxide` コマンド自体では移動できない）
   - `function` と出れば読み込めている

   <details>
   <summary>補足: init の中身</summary>

   `zoxide init bash` は**シェル関数の定義を標準出力に吐くだけ**のコマンドで、`eval` しなければ何も起こらない。実機での出力は 181 行あり、先頭は次のようになっている:

   ```
   $ zoxide init bash | head -12
   # shellcheck shell=bash

   # =============================================================================
   #
   # Utility functions for zoxide.
   #

   # pwd based on the value of _ZO_RESOLVE_SYMLINKS.
   function __zoxide_pwd() {
       \builtin pwd -L
   }
   ```

   定義されるのは次のもの:

   - `__zoxide_z` などの内部関数
   - `--cmd` で指定した名前（既定 `z`）と、その対話版（`zi`）
   - `PROMPT_COMMAND` へのフック（`cd` のたびに現在地をデータベースに加算する）

   **`~/.bashrc` の最後に置く**のは、このフックが他の `PROMPT_COMMAND` 設定に上書きされないようにするため。

   `zi` は内部で `fzf` を呼ぶので、`fzf` が無いとそのサブコマンドだけ失敗する（`z` は動く）。

   </details>

1. zoxide が入ったか確かめ、いくつか移動してからデータベースを見る。

   ```bash
   zoxide --version
   brew list --versions zoxide
   cd /tmp && cd /usr/share && cd ~
   zoxide query --list
   ```

   - `cd` でいくつかディレクトリを移動してから、`zoxide query --list` でデータベースに溜まっているか確認する
   - **注意**: 対話シェル（端末に貼る）で実行する。スクリプトの中では記録されない（この手順の補足）
   - 移動したディレクトリが並べば動いている
   - 以後は `z share` のように末尾の一部を書けば `/usr/share` に飛ぶ
   - `fzf` を入れた場合は、`zi` で候補を対話的に選べる

   <details>
   <summary>補足: データベース</summary>

   学習結果は `~/.local/share/zoxide/db.zo`（バイナリ）に入る。中身は `zoxide query --list`（パスの一覧）や `zoxide query --list --score`（スコア付き）で読める。実機は 5 エントリ、287 バイト:

   ```
   $ ls -l ~/.local/share/zoxide/
   -rw-r--r--. 1 <USER> <USER> 287 Sep 22 18:31 db.zo
   $ zoxide query --list | wc -l
   5
   ```

   特定のパスを忘れさせるには `zoxide remove`（引数はパス）。

   **記録されるのは対話シェルだけ**。`zoxide init` が仕込むのは `PROMPT_COMMAND` のフックで、これはプロンプトを出すときにしか走らない。

   - 非対話シェル（スクリプトや `bash -c`）で `cd` しても、データベースは増えない
   - 検証コンテナで手順 4 のブロックをスクリプトとして流したときは、`zoxide query --list` の出力が空になった

   </details>

---

## 更新

1. brew で zoxide を更新する。

   ```bash
   brew upgrade zoxide
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - データベース（`~/.local/share/zoxide/db.zo`）は更新で消えない

---

## ロールバック

- 本書ではロールバックは**本実行していない**

1. brew で zoxide を消し、`~/.bashrc` から初期化の行を消す。

   ```bash
   brew uninstall zoxide
   sed -i '/zoxide init/d' ~/.bashrc          # ~/.bashrc に書いた 1 行を消す
   ```

   - `~/.bashrc` から `zoxide init` の行を消し忘れると、新しいシェルを開くたびに `zoxide: command not found` が出る
     - `ZOXIDE_CMD=cd` にしていた場合は、`cd` が壊れたように見える

1. 学習したディレクトリの履歴も捨てるときだけ、`~/.local/share/zoxide` を消す。

   ```bash
   rm -rf ~/.local/share/zoxide
   ```

   - 履歴は `~/.local/share/zoxide/db.zo` に入っている
   - **残しておけば、入れ直したときにそのまま使える**

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [zoxide](https://github.com/ajeetdsouza/zoxide)（よく行くディレクトリを覚えて短い入力で移動するツール）の最新版を入れる。**EPEL にも AppStream にも RPM が無い**
- **進め方**: Homebrew で入れ、`~/.bashrc` に初期化の 1 行を足す。**読者が書き換えるのは冒頭の変数ブロック（コマンド名）だけ**
- **状態**: **実機で本実行済み（2026-09-21）**
  - 下表のホストで `brew install zoxide` を実行し、`~/.bashrc` に `eval "$(zoxide init bash)"` を書いて常用中（データベースに 5 エントリ）
  - **実機の初期化は `--cmd` 無し（コマンド名 `z`）で入れてある**
  - [Homebrew の導入](homebrew.md)と手順 2〜4 は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - 確認したこと: ボトルが降りる、`~/.bashrc` に書いた初期化で `z` 関数が定義される（`type -t z` → `function`）
  - ただし**非対話シェルでは `cd` が記録されない**ため、手順 4 の `zoxide query --list` は空だった（[手順 4 の補足](#実施手順)）
  - **確認していないこと**: `ZOXIDE_CMD=cd` の形と `zi`（fzf 連携）の実動作

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-21 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| 入った zoxide | `zoxide 0.10.0`（`arm64_linux` ボトル） | 同じ（`0.10.0`） |
| fzf | `fzf 0.74.4`（Homebrew） | 未導入 |
| シェル | bash（`~/.bashrc` に `eval "$(zoxide init bash)"`） | bash（初期化は未設定） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${ZOXIDE_CMD}` | `zoxide init` の `--cmd` に渡す名前。定義されるコマンドが決まる | `z`（既定）/ `cd` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`0.10.0`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| zoxide | 未導入 |
| Homebrew | 7.0.6 導入済み |
| fzf | `brew install yazi ...` の一部として同時に導入（[yazi.md](yazi.md)） |
| EPEL | 有効。ただし `zoxide` は無い |

### 選択した方針

AlmaLinux 10 aarch64 で zoxide を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `zoxide 0.10.0` の `arm64_linux` ボトルがある。upstream の最新リリース（v0.10.0、2026-07-04）と一致 | **採用** |
| EPEL / AppStream / CRB | **`zoxide` というパッケージが無い**（`dnf list --available zoxide` → `Error: No matching Packages to list`） | 使えない |
| 公式 install.sh | `~/.local/bin` にバイナリを 1 つ置く。root 不要で軽いが、更新は自分で再実行する | 不採用（Homebrew に揃える） |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-musl` のビルドがある。展開して PATH に置くだけだが、更新は手作業 | 不採用 |
| `cargo install zoxide` | Rust toolchain（appstream に `rust 1.92.0` あり）が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

### 完了時点の状態

```
$ brew list --versions zoxide
zoxide 0.10.0
$ zoxide --version
zoxide 0.10.0
$ command -v zoxide
/home/linuxbrew/.linuxbrew/bin/zoxide
$ type -t z
function
$ grep -n 'zoxide init' ~/.bashrc
34:eval "$(zoxide init bash)"
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/zoxide/0.10.0/`。データベースは `~/.local/share/zoxide/db.zo`。

### 注意点

- **初期化の 1 行が本体**: `brew install` だけでは `z` は増えない。`~/.bashrc` に `eval "$(zoxide init bash)"` を書き、シェルを開き直す
- **`--cmd cd` は影響範囲が広い**: `cd` を置き換えると、シェル関数やエイリアス経由の `cd` の挙動も変わる。既定の `z` から始めるのが無難
- **PATH の先頭が Homebrew になる**: `sudo` 経由や root のシェルでは `zoxide` が見えないので、`~/.bashrc` の行も実行されない（root の `.bashrc` には書かない）
- **学習は `cd` のたびに走る**: `PROMPT_COMMAND` にフックが入るので、プロンプトを自前で組んでいる場合は順序に注意する
- **アンインストール時に行を消し忘れると毎回エラーが出る**: [ロールバック](#ロールバック)の `sed` を忘れない
- **他のツールとの連携**: yazi の `z` キー、fzf の `zi` はこのデータベースを共有する

### 参照

- [ajeetdsouza/zoxide — README](https://github.com/ajeetdsouza/zoxide) — 各 OS のインストール方法、シェルごとの `zoxide init` の書き方、`--cmd` の説明
- [zoxide — Installation](https://github.com/ajeetdsouza/zoxide#installation) — 公式 install.sh と各ディストリビューションの状況
- `zoxide --help` / `zoxide query --help` — `query --list` / `--score`、`remove`
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで、非 root ユーザーを作って[Homebrew の導入](homebrew.md)と手順 2〜4 を通した。実機で加えた変更は `dnf install podman` だけ。 実行したのは**この文書のコードブロックをそのまま抜き出したスクリプト**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git sudo` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](homebrew.md)） |
| 2. zoxide | `Pouring zoxide--0.10.0.arm64_linux.bottle.tar.gz`。ソースビルドは発生しない |
| 3. 初期化 | `~/.bashrc` に `eval "$(zoxide init bash --cmd z)"` を追記して読み込み直し、`type -t z` → `function` |
| 4. 検証 | `zoxide --version` → `zoxide 0.10.0`。`cd` を 3 回してからの `zoxide query --list` は**空**（非対話シェルでは `PROMPT_COMMAND` のフックが走らないため） |
| fzf | `brew install zoxide fzf` で `fzf 0.74.4` と依存の `ncurses 6.6` も入った |
| RPM 経路 | EPEL を有効にしても `dnf list --available zoxide` は `Error: No matching Packages to list` |

実機側では `type -t z` が `function` を返し、`~/.bashrc` の 34 行目に `eval "$(zoxide init bash)"` があり、データベースに 5 エントリ溜まっていることを確認した（対話シェルでは記録される）。

#### 未確認事項

- `ZOXIDE_CMD=cd`（`--cmd cd`）での動作。実機は `--cmd` 無しで入れてある
- `zi`（fzf 連携）の実動作
- bash 以外のシェル（zsh / fish）での `zoxide init`
- `_ZO_DATA_DIR` などの環境変数による挙動の変更
- ロールバック（`brew uninstall` と `~/.bashrc` の行削除）の本実行
