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

   - `fzf` は必須ではないが、入れておくと候補から選ぶ `zi` が使える（fzf 自身のキー操作と補完を bash に組み込むのは [fzf.md](fzf.md)）
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
   - 自分用の bash の設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）を入れたホストでは、このブロックは貼らない。代わりに `. ~/.bashrc` と `type -t z` を実行する（その設定が `--cmd z` の初期化を最後に読む）

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
   - `PROMPT_COMMAND` へのフック（プロンプトを出すたびに、今のディレクトリをデータベースに加算する）

   **`~/.bashrc` の最後に置く**のは、このフックが他の `PROMPT_COMMAND` 設定に上書きされないようにするため。

   `zi` は内部で `fzf` を呼ぶので、`fzf` が無いとそのサブコマンドだけ失敗する（`z` は動く）。

   </details>

1. zoxide が入ったか確かめ、記録を試すディレクトリへ移る。

   ```bash
   zoxide --version
   command -v zoxide
   cd /usr/share
   ```

   - `command -v zoxide` は `/home/linuxbrew/.linuxbrew/bin/zoxide`
   - **注意**: 対話シェル（端末に貼る）で実行する。スクリプトの中では記録されない（この手順の補足）
   - **次の手順は、プロンプトが戻ってから貼る**（zoxide はプロンプトを出すときに今のディレクトリを記録する。ブラケットペーストで続けて貼ると、プロンプトが出る前に手順 5 が走り、`/usr/share` がまだ無い）

   <details>
   <summary>補足: データベース / 記録されるタイミング</summary>

   学習結果は `~/.local/share/zoxide/db.zo`（バイナリ）に入る。中身は `zoxide query --list`（パスの一覧）や `zoxide query --list --score`（スコア付き）で読める。実機は 5 エントリ、287 バイト:

   ```
   $ ls -l ~/.local/share/zoxide/
   -rw-r--r--. 1 <USER> <USER> 287 Sep 22 18:31 db.zo
   $ zoxide query --list | wc -l
   5
   ```

   特定のパスを忘れさせるには `zoxide remove`（引数はパス）。

   **記録されるのは、対話シェルがプロンプトを出すときだけ**。`zoxide init` が仕込むのは `PROMPT_COMMAND` のフックで、プロンプトを出すときの今のディレクトリを 1 つ記録する。

   - 非対話シェル（スクリプトや `bash -c`）で `cd` しても、データベースは増えない
   - 2026-09-22 の検証コンテナで、当時の確認のブロック（`cd /tmp && cd /usr/share && cd ~` を含む）をスクリプトとして流したときは、`zoxide query --list` の出力が空になった
   - 対話シェルでも、プロンプトが出るまでの間の `cd` は最後の 1 つしか記録されない。ホーム（`$HOME`）は既定で記録しない（`_ZO_EXCLUDE_DIRS` の既定値）
   - ブラケットペーストで貼ると、複数行の貼り付けは 1 つの入力として実行され、プロンプトは最後に 1 回しか出ない
   - そのため、`cd ~` で終わる当時のブロックは、ブラケットペーストの有無にかかわらず何も残さなかった（2026-09-29 に、当時あった dnf の経路の検証コンテナで確認）。確認を手順 4 と手順 5 に分けたのはこのため

   </details>

1. データベースに記録されたか確かめ、ホームに戻る。

   ```bash
   zoxide query --list
   cd ~
   ```

   - `/usr/share` が出れば動いている
   - 以後は `z share` のように末尾の一部を書けば `/usr/share` に飛ぶ
   - `fzf` を入れた場合は、`zi` で候補を対話的に選べる

---

## 更新

- データベース（`~/.local/share/zoxide/db.zo`）は更新で消えない

1. brew で zoxide を更新する。

   ```bash
   brew upgrade zoxide
   ```

   - すべてまとめて上げるなら `brew upgrade`

---

## ロールバック

- この節の手順 1（`brew uninstall`）は**本実行していない**
- この節の手順 2・3 は、x86_64 のコンテナで通した（2026-09-29。当時あった dnf の経路の検証の中で）

1. brew で zoxide を消す。

   ```bash
   brew uninstall zoxide
   ```

1. `~/.bashrc` から初期化の行を消す。

   ```bash
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

- **目的**: AlmaLinux 10 に [zoxide](https://github.com/ajeetdsouza/zoxide)（よく行くディレクトリを覚えて短い入力で移動するツール）の最新版を入れる。**EPEL にも AppStream にも RPM が無い**（EL10 向けの RPM は COPR にしか無い）
- **進め方**: Homebrew（x86_64・aarch64）で入れ、`~/.bashrc` に初期化の 1 行を足す。**読者が書き換えるのは冒頭の変数ブロック（コマンド名）だけ**
- **状態**: **実機で本実行済み（2026-09-21）**
  - 下表のホストで `brew install zoxide` を実行し、`~/.bashrc` に `eval "$(zoxide init bash)"` を書いて常用中（データベースに 5 エントリ）
  - **実機の初期化は `--cmd` 無し（コマンド名 `z`）で入れてある**
  - [Homebrew の導入](homebrew.md)と手順 2・3、それに当時の確認のブロック（今の手順 4・5 の元。`brew list --versions zoxide` と `cd /tmp && cd /usr/share && cd ~` を含む 1 つのブロック）は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - 確認したこと: ボトルが降りる、`~/.bashrc` に書いた初期化で `z` 関数が定義される（`type -t z` → `function`）
  - ただし**非対話シェルでは `cd` が記録されない**ため、そのときの `zoxide query --list` は空だった（[手順 4 の補足](#実施手順)）
  - 2026-09-29〜10-02 の版には、x86_64 だけの dnf（COPR `kray74/cli-tools`）の経路があった（2026-10-03 に外した。[選択した方針](#選択した方針)）
    - 当時の手順 1・3〜8（3〜5 が dnf の手順で、6〜8 は今の手順 3〜5）、当時の[更新](#更新)の手順 2、当時の[ロールバック](#ロールバック)の手順 2〜5（4・5 は今の手順 2・3）を、x86_64 のコンテナで**その版のコードブロックのまま**、擬似端末の対話シェルに貼って通した（[付録](#付録-dnf-の経路のコンテナでの検証記録2026-09-29)）
    - 今の手順 3〜5 と同じブロックで、`type -t z` → `function`、手順 5 で `/usr/share` が出る、`zi share` で `/usr/share` に移る、を確かめた（zoxide は dnf の `/usr/bin/zoxide`）
  - **確認していないこと**: `ZOXIDE_CMD=cd` の形、Homebrew の zoxide での `zi`（fzf 連携）

| 項目 | 実機 | 検証コンテナ | dnf の検証コンテナ（外した経路） |
|---|---|---|---|
| 実施日 | 2026-09-21 | 2026-09-22 | 2026-09-29 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） | AlmaLinux 10.2 (Lavender Lion) / x86_64（`docker.io/library/almalinux:10`、クラウドホスト上の Docker 29.3.1） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） | 使わない |
| 入った zoxide | `zoxide 0.10.0`（`arm64_linux` ボトル） | 同じ（`0.10.0`） | `zoxide-0.10.0-1.el10.x86_64`（COPR `kray74/cli-tools`） |
| fzf | `fzf 0.74.4`（Homebrew） | 未導入 | `fzf-0.74.4-1.el10.x86_64`（同じ COPR） |
| シェル | bash（`~/.bashrc` に `eval "$(zoxide init bash)"`） | bash（初期化は未設定） | bash（`~/.bashrc` に `eval "$(zoxide init bash --cmd z)"`） |

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

dnf で入れる経路は、2026-09-29 に x86_64 も含めて探し直した（EPEL はミラーのディレクトリ一覧とコンテナの `dnf list`、COPR は API とリポジトリのメタデータ）:

| 経路 | x86_64 | aarch64 | 採否 |
|---|---|---|---|
| COPR `kray74/cli-tools` | `zoxide-0.10.0-1.el10`（`epel-10-x86_64`）。spec は GitHub で公開、上流の tarball から cargo でビルド。man と補完も入る。同じ COPR の fzf は 0.74.4 | chroot が無い | 不採用（2026-09-29 に dnf の経路として採り、2026-10-03 に外した。下の箇条書き） |
| COPR `shdwchn10/AllTheTools` | `zoxide-0.10.0-1.el10` | `zoxide-0.10.0-1.el10` | 不採用（RPM に補完が無い。同じ COPR の fzf は 0.74.3） |
| COPR `faramirza/epel10` | `zoxide-0.10.0-2.el10` | `zoxide-0.10.0-2.el10` | 不採用（説明が無く、71 本の中に vim・tmux・jq・nano など BaseOS / AppStream と同じ名前のパッケージがある） |
| COPR `ldivizio/tools` | EL10 向けのビルドが無い（`fedora-44-x86_64` だけ） | 無い | 使えない |
| EPEL 10（10.0〜10.4・10z、testing も） | 無い（コンテナで EPEL を有効にしても `No matching Packages to list`） | 無い | 使えない |
| EPEL 9 | `zoxide-0.9.8-2.el9` | 調べていない | 不採用（EL9 向けで、版も古い） |
| Terra（`terrael10`） | 無い | 無い | 使えない |

- **Homebrew だけにした**（2026-10-03）。2026-09-29〜10-02 の版は、x86_64 だけの dnf の経路として `kray74/cli-tools` を載せていたが、外した
  - 版は Homebrew と同じ（zoxide 0.10.0、fzf 0.74.4。2026-10-03 の Homebrew の API）
  - x86_64 にしか無く、実機（Raspberry Pi 5）は aarch64
  - dnf の利点だった「`/usr/bin` に入り、`sudo` や root のシェルからも見える」は、homebrew.md の[root のシェルでも使う](homebrew.md#root-のシェルでも使う任意)・[sudo でも使う](homebrew.md#sudo-でも使う任意)の節で足りる
  - COPR は個人のリポジトリで、Fedora は中身を審査しない（`dnf copr enable` の警告）。同じ COPR の chezmoi などが EPEL の同じ名前のパッケージを置き換えないよう、`includepkgs` で絞る手間も要った
- [tool-catalog.md の選び方](tool-catalog.md#選び方)（RPM が Homebrew と同版以上なら RPM）は COPR を RPM に数えないので、一覧の推奨も Homebrew

### 完了時点の状態

実機:

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
- **root のシェルでは効かない**: 手順 3 の初期化の行は自分の `~/.bashrc` だけにあり、root のシェルでは実行されない（root の `.bashrc` には書かない）。Homebrew の zoxide は、そのままでは `sudo` 経由では見えない（[homebrew.md の注意点](homebrew.md#注意点)。homebrew.md の[root のシェルでも使う](homebrew.md#root-のシェルでも使う任意)・[sudo でも使う](homebrew.md#sudo-でも使う任意)の節は、PATH を足すだけ）
- **学習はプロンプトを出すたびに走る**: `PROMPT_COMMAND` にフックが入り、そのときの今のディレクトリを記録する。プロンプトを自前で組んでいる場合は順序に注意する
- **アンインストール時に行を消し忘れると毎回エラーが出る**: [ロールバック](#ロールバック)の `sed` を忘れない
- **他のツールとの連携**: yazi の `z` キー、fzf の `zi` はこのデータベースを共有する

### 参照

- [ajeetdsouza/zoxide — README](https://github.com/ajeetdsouza/zoxide) — 各 OS のインストール方法、シェルごとの `zoxide init` の書き方、`--cmd` の説明
- [zoxide — Installation](https://github.com/ajeetdsouza/zoxide#installation) — 公式 install.sh と各ディストリビューションの状況
- `zoxide --help` / `zoxide query --help` — `query --list` / `--score`、`remove`
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作
- [kray74/cli-tools — Copr](https://copr.fedorainfracloud.org/coprs/kray74/cli-tools/) — chroot（`epel-10-x86_64` と `fedora-44-x86_64`）とビルドの履歴
- [kray74/cli-tools — GitHub](https://github.com/kray74/cli-tools) — COPR の spec（`zoxide/zoxide.spec`）

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで、非 root ユーザーを作って[Homebrew の導入](homebrew.md)と手順 2・3・4 を通した（手順 4 は当時の確認のブロックで、今の手順 4・5 の元）。実機で加えた変更は `dnf install podman` だけ。 実行したのは**この文書のコードブロックをそのまま抜き出したスクリプト**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。

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

### 付録: dnf の経路のコンテナでの検証記録（2026-09-29）

`docker.io/library/almalinux:10`（AlmaLinux 10.2、x86_64）のコンテナに NOPASSWD の sudo を与えた一般ユーザーを作り、**この文書のコードブロックをそのまま**、擬似端末（pty）で開いた対話の bash に貼って通した。

- 手順の番号は今の文書のものに付け替えた。「当時の」と付けたものは、2026-10-03 に外した dnf の経路の手順
- `[y/N]` には、プロンプトが出てから `y` を返した
- 通しは、ブロックを 1 行ずつ Enter で送る形（ブラケットペースト無し）で行った。手順 4・5 は、ブロックをブラケットペーストの開始と終了の制御文字で囲んで 1 回で送る形でも通した
- ブラケットペーストの有無の比較（この付録の最後）は、文書を書く前に同じコマンドで zoxide を入れた 1 つ目のコンテナで行った。ブラケットペースト有りは `TERM=xterm-256color`（`bind -v` が `enable-bracketed-paste on`）
- 検証環境だけの変更:
  - ホストの外向きの通信がプロキシ経由なので、dnf にプロキシ（`/etc/dnf/dnf.conf` の `proxy=`）とプロキシの CA を設定した
  - AlmaLinux の repo ファイルは `mirrorlist=` を止め、コメントにある `baseurl=`（`https://repo.almalinux.org/...`）を使った（ミラーリストが返す http のミラーを、プロキシが通さないため）
  - `sudo` と `procps-ng` は先に入れた（コンテナのイメージに無い）

| 手順 | 結果 |
|---|---|
| 前提 | `dnf-4.20.0-22.el10_2.alma.1` と `python3-dnf-plugins-core-4.7.0-10.el10`（`dnf copr` と `dnf config-manager` の本体）は最初から入っていた。`dnf-plugins-core` というパッケージは無いが、要らなかった |
| 当時の 3. COPR | 警告文の後の `[y/N]` に `y` → `Repository successfully enabled.`。repo ファイルの `baseurl` は `.../kray74/cli-tools/epel-10-$basearch/` |
| 当時の 4. 絞り込み | `11:includepkgs=zoxide,fzf`。COPR から見えるのは zoxide と fzf（と各 `.src`）だけ |
| 当時の 5. 導入 | `fzf-0.74.4-1.el10` と `zoxide-0.10.0-1.el10` の 2 つ（2.3 MB）。トランザクションの後に鍵 `0x405678BB` の取り込みを聞かれ、`Key imported successfully` |
| 3. 初期化 | `type -t z` → `function` |
| 4・5. 確認 | `zoxide 0.10.0`、`/usr/bin/zoxide`。手順 5 の `zoxide query --list` → `/usr/share`（ブラケットペーストの有りと無しの両方） |
| `zi` | 1 つ目のコンテナで、`zi share` で fzf が開き、Enter で `/usr/share` に移った |
| 当時の更新の手順 2 | `Nothing to do.`（COPR の最新が 0.10.0 のため） |
| ロールバックの当時の手順 2・3 と、手順 2・3（当時の 4・5） | `dnf remove` で消えたのは zoxide と fzf の 2 つだけ。`dnf copr remove` で repo ファイルが消え、鍵 `gpg-pubkey-405678bb-69063860` は残った。`sed` で `~/.bashrc` の行が消え、`~/.local/share/zoxide` も消えた |
| aarch64 | 別のコンテナで、`dnf --forcearch aarch64 copr enable kray74/cli-tools` は `Repository 'epel-10-aarch64' does not exist in project 'kray74/cli-tools'.` で止まり、repo ファイルは作られなかった |
| `includepkgs` | 別のコンテナで EPEL の fzf 0.58.0 と chezmoi 2.72.0 を入れてから COPR を有効にすると、`dnf upgrade --assumeno` の候補は、絞る前は chezmoi 2.72.2 と fzf 0.74.4（どちらも COPR）、絞った後は fzf 0.74.4 だけ |
| EPEL 10 | 別のコンテナで `epel-release` を入れても、`dnf list --available zoxide` は `Error: No matching Packages to list`（fzf 0.58.0・chezmoi 2.72.0 は EPEL にある）。検証環境だけ、EPEL の repo ファイルも `metalink=` を止めて `dl.fedoraproject.org` を直接指した |

**当時の確認のブロックが空になる理由**は、1 つ目のコンテナで確かめた。

- ブラケットペースト無し: `cd /tmp && cd /usr/share && cd ~` は 1 行なので、プロンプトは `~` に戻ってから 1 回だけ出る。ホームは既定で記録しないので、`zoxide query --list` は空
- `cd /tmp`・`cd /usr/share`・`cd ~` を別々の行で入れると、`/tmp` と `/usr/share` が記録された（行ごとにプロンプトが出る）
- ブラケットペースト有り: `cd` を別々の行に書いても、1 回の貼り付けは 1 つの入力として実行され、プロンプトは最後に 1 回しか出ないので空
- 手順 4 と手順 5 に分けて貼ると、手順 4 の後のプロンプトで `/usr/share` が記録された

#### 未確認事項（dnf の経路）

- 実機（x86_64 の PC）での本実行
- aarch64（COPR に chroot が無い）
- `ZOXIDE_CMD=cd` の形
- COPR が次の版を出したときの `dnf upgrade`（検証の時点では 0.10.0 が最新）
