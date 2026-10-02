# ShellCheck / shfmt インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew は root で動かないため）

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 整形は[shfmt で整形を確かめる（任意）](#shfmt-で整形を確かめる任意)、警告の抑制は[検査を調整する（任意）](#検査を調整する任意)。以後は[更新](#更新)・[ロールバック](#ロールバック)

1. 変数を設定する（`SC_TARGET` は必ず値を入れる）。

   ```bash
   SC_TARGET=scripts/wireguard/wg-vpn.sh   # 検査するスクリプト。自分のパスに変える。<SC_TARGET>
   ```

   ```bash
   SC_SEVERITY=style        # -S に渡す最低重大度。style だと全部出る。error / warning / info / style。<SC_SEVERITY>
   SHFMT_INDENT=2           # shfmt -i のインデント幅。0 ならタブ。<SHFMT_INDENT>
   for v in SC_TARGET SC_SEVERITY SHFMT_INDENT; do printf '%-13s = %s\n' "$v" "${!v}"; done
   ```

   - **編集が必須なのは、検査対象のパス `SC_TARGET` だけ**。自分のリポジトリのスクリプトに変える
   - 残りは既定のままでよい
   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先に手順 1 の 2 つのブロックを貼り直す

   <details>
   <summary>補足: 変数について</summary>

   - `${SC_TARGET}` だけが環境固有で、それ以外は好みの値
   - `${SC_SEVERITY}` の既定 `style` は**いちばん緩い設定で、error / warning / info / style のすべてが出る**（`-S` は「この重大度以上を出す」という意味）。実害のあるものだけ見たいなら `error`
   - `${SHFMT_INDENT}` の既定を `2` にしてあるのは、`wg-vpn.sh` が**スペース 2 インデントで書かれている**のを実測したため（タブは 0 行）
   - shfmt 自身の既定は**タブ**なので、`-i` を渡さないと全行が差分になる

   </details>

1. ShellCheck と shfmt を入れる。

   ```bash
   brew install shellcheck shfmt
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - ShellCheck は `gmp` と `libffi` を要求する（Haskell 製のため）。shfmt に依存は無い

   <details>
   <summary>補足: ボトルと依存</summary>

   aarch64 で降ってくるボトルは `shellcheck--0.11.0.arm64_linux.bottle.1.tar.gz` / `shfmt--3.14.1.arm64_linux.bottle.tar.gz`。

   ShellCheck は Haskell 製で、`gmp`（多倍長整数）と `libffi` を要求する。実機はどちらも他の formula の依存で入っていたため、取得されたのは本体だけだった。実測:

   ```
   $ brew deps --tree shellcheck
   shellcheck
   ├── gmp
   └── libffi
   $ brew deps --tree shfmt
   shfmt
   ```

   導入にかかった時間は 8 秒（依存が揃っていたため）。実体のサイズは **ShellCheck が 47 MB、shfmt が 3.3 MB**。ShellCheck が大きいのは Haskell のランタイムを静的に抱えているため。

   </details>

1. 2 つが入ったか確かめ、わざと欠陥のあるコードで検出できるかを見る。

   ```bash
   shellcheck --version
   shfmt --version
   command -v shellcheck shfmt
   brew list --versions shellcheck shfmt
   printf '#!/bin/bash\nx=$(ls)\necho $x\n' | shellcheck -
   echo "rc=$?"
   printf '#!/bin/bash\nif true; then\necho a\nfi\n' | shfmt -i 2 -d -
   echo "rc=$?"
   ```

   - `version: 0.11.0` と `3.14.1` が出る
   - 次に、**わざと欠陥のあるコードを標準入力に流して**、本当に検出できることを確かめる（ファイルは作らない）。shfmt も同じように確かめる
   - ShellCheck は `SC2086 (info): Double quote to prevent globbing and word splitting.` が 1 件出て **`rc=1`** になる
   - shfmt は字下げを足す差分が出て `rc=1` になる
   - **どちらも「指摘があれば `rc=1`」** で、`rc=0` は「指摘なし」を意味する

   <details>
   <summary>補足: 終了コードの意味</summary>

   どちらも**指摘が 1 件でもあると `rc=1`** を返す。`set -e` を書いたスクリプトや CI に組み込むときの前提になる。

   ```
   $ printf '#!/bin/bash\nx=$(ls)\necho $x\n' | shellcheck -

   In - line 3:
   echo $x
        ^-- SC2086 (info): Double quote to prevent globbing and word splitting.

   Did you mean:
   echo "$x"

   For more information:
     https://www.shellcheck.net/wiki/SC2086 -- Double quote to prevent globbing ...
   rc=1
   ```

   **`x=1` のような単純な代入では SC2086 は出ない。** 0.11.0 は「その変数に空白や glob が入り得るか」を追跡していて、リテラルを代入しただけの変数は安全だと判断する。上の例で `$(ls)` を使っているのはこのため。

   `-f` で出力形式を変えられる:

   - `tty`（既定）
   - `gcc`（エディタや CI が読む 1 行 1 件の形式）
   - `json` / `json1` / `checkstyle`
   - `diff`（`git apply` できる修正パッチ）
   - `quiet`（何も出さず終了コードだけ）

   </details>

1. スクリプトを、bash の構文チェックと ShellCheck で検査する。

   ```bash
   bash -n "${SC_TARGET:?手順 1 の SC_TARGET が空のまま。値を入れて貼り直す}"
   echo "rc=$?"
   shellcheck -x "${SC_TARGET}"
   echo "rc=$?"
   ```

   - まず bash の構文チェック。1 つ目の `rc=0` なら構文としては通っている
   - 次に ShellCheck を掛ける。**警告が 0 件なら何も出ずに `rc=0` で終わる**
   - 出たときは、この手順の補足に読み方と実測がある

   <details>
   <summary>補足: <code>wg-vpn.sh</code> の検査結果（実測）</summary>

   実機で `scripts/wireguard/wg-vpn.sh` を検査した結果。**この補足の行数と差分の数値は、下記の修正を入れる前のもの**（当時 1,300 行、修正後は 1,299 行）。

   ```
   $ bash -n scripts/wireguard/wg-vpn.sh
   rc=0
   $ shellcheck -x scripts/wireguard/wg-vpn.sh

   In scripts/wireguard/wg-vpn.sh line 114:
     n=SITE_${L}_LAN;       MY_LAN=${!n}
                            ^----^ SC2034 (warning): MY_LAN appears unused. Verify use (or export if used externally).

   For more information:
     https://www.shellcheck.net/wiki/SC2034 -- MY_LAN appears unused. Verify use...
   rc=1
   ```

   **指摘は 1 件だけ。** 重大度で絞った件数:

   | `-S` | 件数 |
   |---|---|
   | `error` | 0 |
   | `warning` | 1 |
   | `info` | 1 |
   | `style` | 1 |

   **この SC2034 は誤検出ではなかった。**

   - `MY_LAN` は 114 行目で代入されるだけで、ほかのどこでも読まれていない（`grep -cw MY_LAN` が `1`）
   - `select_site` が組み立てる 13 個の `MY_*` / `PEER_*` のうち、読まれていないのは `MY_LAN` だけだった（対になる `PEER_LAN` は 3 か所で使われている）

   **使うはずだった場所は無い。**

   - 拠点の LAN を両方まとめて必要とする箇所（`validate_addresses` の Python、クライアント conf の `AllowedIPs`）は、`SITE_A_LAN` / `SITE_B_LAN` を直接読んでいて、`MY_LAN` を経由していない
   - `MY_LAN` を参照していた rich rule は、firewalld を「LAN 側ゾーン + forward」方式に変えたときに無くなっている（[wireguard.md](wireguard.md#付録-スクリプトの検証)の落とし穴の記録に当時の `$MY_LAN` が残っている）
   - **代入だけが取り残されていた**

   **直した。** この変更で 114 行目を削除し、警告は 0 件になった:

   ```
   $ shellcheck -x scripts/wireguard/wg-vpn.sh
   rc=0
   $ bash -n scripts/wireguard/wg-vpn.sh
   rc=0
   ```

   削除が無害であることは、変更前後のスクリプトを並べて確かめた。

   - `select_site` を通る **root が要らないサブコマンド**（`router A` / `router B` / `client list`）と `--help`、および異常系（`router C` / 引数なし / `client bogus`）の計 10 通りで、**標準出力・標準エラー・終了コードがすべて一致した**
   - `MY_LAN` を読む箇所が無い以上これは当然だが、`select_site` は `apply` / `remove` / `client add` など root が要る経路もすべて通るので、実際に値を組み立てる関数の出力が変わらないことを確認しておく意味がある

   **`-x` はこのスクリプトでは結果を変えない。** `-x` あり / なしの出力を比べると完全に同一だった:

   ```
   $ shellcheck -x scripts/wireguard/wg-vpn.sh > /tmp/a.txt 2>&1
   $ shellcheck    scripts/wireguard/wg-vpn.sh > /tmp/b.txt 2>&1
   $ diff /tmp/a.txt /tmp/b.txt && echo '差分なし'
   差分なし
   ```

   理由は 2 つ。

   - `source` しているのは 77 行目の `source "$ENV_FILE"` の 1 か所だけで、**パスが変数なので `-x` でも追跡先を決められない**
   - しかもその直前に `# shellcheck disable=SC1090` が置いてあり、追跡できないこと自体の警告は既に黙らせてある

   追跡させたいなら `# shellcheck source=...` で実ファイルを名指しするか、`.shellcheckrc` に `source-path=` を書く。

   **shfmt の差分は大きい。** `wg-vpn.sh` は shfmt の整形規則とは別の書き方（1 行関数、`(( DRY_RUN ))` の内側の空白など）をしているため:

   | 設定 | 差分の行数 |
   |---|---|
   | `-i 0`（タブ。shfmt の既定） | 2,057 |
   | `-i 2` | 892 |
   | `-i 4` | 2,049 |
   | `-i 2 -ci` | 872 |

   - `-i 2` がいちばん小さいことが、このスクリプトがスペース 2 インデントである裏付けになっている。それでも 892 行が差分に出る
   - 一時ディレクトリの複製に `shfmt -i 2 -w` を掛けると **1,300 行 → 1,450 行**（+150 行）になった

   主な変換はこの形:

   ```
   -die()  { echo "ERROR: $*" >&2; exit 1; }
   +die() {
   +  echo "ERROR: $*" >&2
   +  exit 1
   +}
   ```

   ```
   -  if (( DRY_RUN )); then
   -    printf '[dry-run] '; printf '%q ' "$@"; echo
   +  if ((DRY_RUN)); then
   +    printf '[dry-run] '
   +    printf '%q ' "$@"
   +    echo
   ```

   どちらも**書き方の好みの問題で、壊れているわけではない**。このリポジトリは 1 行関数と `(( ))` の内側の空白を意図して使っているので、**`wg-vpn.sh` に `-w` は掛けていない**（[未確認事項](#未確認事項)）。

   </details>

1. 件数だけ見たいときと、重大度で絞りたいときは、JSON で数えて `-S` で絞る。

   ```bash
   shellcheck -x -f json "${SC_TARGET}" | jq 'length'
   shellcheck -x -f json "${SC_TARGET}" | jq -r '.[] | "\(.level) \(.code)"' | sort | uniq -c | sort -rn
   shellcheck -x -S "${SC_SEVERITY:?手順 1 の SC_SEVERITY が空のまま。値を入れて貼り直す}" "${SC_TARGET}" | head -20
   ```

   - `wg-vpn.sh` を `-S` ごとに数えた実測は、手順 4 の補足にある

---

## shfmt で整形を確かめる（任意）

- **`-d` は差分を出すだけでファイルを変えない**

> [!WARNING]
> **`-w` は元のファイルを上書きする。** いきなり本番のスクリプトに掛けない。**この節の**手順 2 は、一時ディレクトリの複製に掛けて挙動を見る。

1. 今の書き方とどれだけ違うかを見て、整形対象になるファイルを一覧する。

   ```bash
   shfmt -i "${SHFMT_INDENT:?手順 1 の SHFMT_INDENT が空のまま。値を入れて貼り直す}" -d "${SC_TARGET}" | wc -l
   shfmt -i "${SHFMT_INDENT}" -d "${SC_TARGET}" | head -30
   shfmt -f scripts | head
   shfmt -l -i "${SHFMT_INDENT}" scripts
   ```

   - まず今の書き方とどれだけ違うかを見る
   - 次に、ディレクトリ配下で整形対象になるファイルを一覧する（`-l` は「整形すると変わるファイル」だけを出す）

1. 一時ディレクトリに複製して、`-w` の挙動を見る。

   ```bash
   SHFMT_TMP=$(mktemp -d)
   cp "${SC_TARGET}" "${SHFMT_TMP}/copy.sh"
   shfmt -i "${SHFMT_INDENT}" -w "${SHFMT_TMP}/copy.sh"
   diff <(wc -l < "${SC_TARGET}") <(wc -l < "${SHFMT_TMP}/copy.sh")
   rm -rf "${SHFMT_TMP}"
   ```

   - 行数がどれだけ増減するかが出る
   - **差分が大きいときは、そのスクリプトの書き方と shfmt の既定が合っていない**（[手順 4 の補足](#実施手順)の shfmt の項を見る）

   <details>
   <summary>補足: よく使うオプション</summary>

   | オプション | 意味 |
   |---|---|
   | `-i N` | インデント幅。`0` はタブ（既定） |
   | `-ci` | `case` の分岐を字下げする |
   | `-bn` | 二項演算子の前で改行する |
   | `-sr` | リダイレクトの後に空白を入れる |
   | `-s` | 冗長な書き方を簡略化する |
   | `-d` / `-l` / `-w` | 差分を出す / 対象を列挙する / 上書きする |
   | `-ln bash\|posix\|mksh` | 方言を明示する（既定はシェバンから判定） |

   </details>

---

## 検査を調整する（任意）

1. 1 行だけ黙らせるディレクティブの例を、検査対象の中から探す。

   ```bash
   grep -n 'shellcheck disable' "${SC_TARGET}"
   ```

   - **1 行だけ黙らせる**には、その行の直前にディレクティブを置く
   - スコープは**次の 1 コマンド**で、関数の前なら関数全体、シェバンの直後ならファイル全体になる
   - `# shellcheck disable=SC1090` のような行が出る
   - 複数まとめるならカンマ区切り（`disable=SC2086,SC2034`）

1. リポジトリ全体に効かせるときは、`.shellcheckrc` の挙動を一時ディレクトリで確かめる。

   ```bash
   SC_TMP=$(mktemp -d)
   cp "${SC_TARGET}" "${SC_TMP}/target.sh"
   printf 'disable=SC2034\nexternal-sources=true\nsource-path=SCRIPTDIR\n' > "${SC_TMP}/.shellcheckrc"
   (cd "${SC_TMP}" && shellcheck -x target.sh; echo "rc=$?")
   rm -rf "${SC_TMP}"
   ```

   - **リポジトリ全体に効かせる**なら `.shellcheckrc` を置く
   - 置くと**カレントディレクトリにファイルを作る**ことになるので、まず一時ディレクトリで挙動を確かめる
   - `disable` に挙げたコードが消えて `rc` が変わる
   - `--norc` を付けると、`.shellcheckrc` を読まずに実行できる
   - **本書ではリポジトリに `.shellcheckrc` を置いていない**（[未確認事項](#未確認事項)）

---

## 更新

1. ShellCheck と shfmt を上げる。

   ```bash
   brew upgrade shellcheck shfmt
   ```

   - すべてまとめて上げるなら `brew upgrade`

---

## ロールバック

- 本書ではロールバックは**本実行していない**

1. ShellCheck と shfmt を消す。

   ```bash
   brew uninstall shellcheck shfmt
   ```

   - 依存の `gmp` / `libffi` は他の formula も使うので残る。まとめて整理するなら `brew autoremove`
   - 設定ファイルは作っていないので、消すものは無い（`.shellcheckrc` や `.editorconfig` を自分で置いた場合はそれを消す）

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [ShellCheck](https://www.shellcheck.net/)（シェルスクリプトの静的検査）と [shfmt](https://github.com/mvdan/sh)（整形）を入れる。**このリポジトリの `CLAUDE.md` が「よく使うコマンド」として `shellcheck -x scripts/wireguard/wg-vpn.sh` を挙げているのに、実機に入っていなかった**のが動機
- **進め方**: Homebrew で 2 つ同時に入れ、`scripts/wireguard/wg-vpn.sh` を実際に検査する。**読者が書き換えるのは冒頭の変数ブロック（検査対象のパス）だけ**
- **状態**: **実機で本実行済み（2026-09-23）**
  - 下表のホストで `brew install shellcheck shfmt` を実行し、`shellcheck 0.11.0` と `shfmt 3.14.1` が入って常用中
  - **`wg-vpn.sh`（1,300 行）を 0.11.0 で検査して警告 1 件（SC2034）を見つけ、同じ変更でそれを直して 0 件にした**（[手順 4 の補足](#実施手順)）
  - 手順 2〜3 と[検査を調整する（任意）](#検査を調整する任意)・[shfmt と `.editorconfig` の優先順位](#shfmt-と-editorconfig-の優先順位実測)は、2026-09-23 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - コンテナで確認したこと: ボトルが降りる、スモークテストが同じ結果になる、EPEL 版の版と名前
  - **コンテナでは手順 4〜5（`wg-vpn.sh` の検査）は実行していない**（リポジトリを置いていないため）

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-23 | 2026-09-23 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| ShellCheck | `shellcheck 0.11.0`（`arm64_linux` ボトル） | 同じ（`0.11.0`） |
| shfmt | `shfmt 3.14.1`（同上） | 同じ（`3.14.1`） |
| 依存 | `gmp 6.3.0` / `libffi 3.8.0` は**導入済みだった**ので取得されなかった | 両方とも新規に取得 |
| 検査対象 | `scripts/wireguard/wg-vpn.sh`（検査時点で 1,300 行、スペース 2 インデント） | 無し |
| jq | `jq 1.7.1`（RPM。`--format json` の集計に使う） | 無し（集計はしていない） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${SC_TARGET}` | 検査するスクリプトのパス。**このリポジトリ以外では必ず書き換える** | `scripts/wireguard/wg-vpn.sh` |
> | `${SC_SEVERITY}` | `shellcheck -S` に渡す最低重大度 | `style`（既定・全部出る）/ `error` |
> | `${SHFMT_INDENT}` | `shfmt -i` のインデント幅 | `2`（既定）/ `0`（タブ）/ `4` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`0.11.0` / `3.14.1`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| ShellCheck | **未導入**（EPEL の `ShellCheck 0.10.0-3.el10_0` も入れていない） |
| shfmt | 未導入 |
| Homebrew | 7.0.6 導入済み、`brew leaves` が 15 件 |
| `gmp` / `libffi` | 導入済み（他の formula の依存として） |
| `bash -n` / `jq` | `bash 5.2` と `jq 1.7.1`（どちらも RPM） |
| `.shellcheckrc` / `.editorconfig` | リポジトリに**どちらも無い** |

### 選択した方針

#### ShellCheck

AlmaLinux 10 aarch64 で ShellCheck を入れる経路を比べた（2026-09-23 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `shellcheck 0.11.0` の `arm64_linux` ボトルがある。upstream の最新と一致 | **採用** |
| EPEL | `ShellCheck 0.10.0-3.el10_0`。**パッケージ名は大文字の `ShellCheck`**（コマンドは小文字 `shellcheck`）。dnf 管理で root でも使えるが **1 マイナー古い** | 不採用。**`sudo shellcheck` を使いたい / dnf 管理に揃えたいならこちら**（`sudo dnf install ShellCheck`） |
| 公式のバイナリ配布 | GitHub Releases に `linux.aarch64` の tar.xz がある。展開して PATH に置くだけだが、更新は手作業 | 不採用（Homebrew に揃える） |
| `cabal install` / Docker イメージ | Haskell の toolchain か podman が要る | 不採用 |

#### shfmt

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `shfmt 3.14.1` の `arm64_linux` ボトルがある | **採用**（ほかに選択肢が無い） |
| EPEL / AppStream / CRB | **どこにも無い**（`dnf list --available shfmt` → `Error: No matching Packages to list`） | 使えない |
| GitHub Releases のバイナリ | `shfmt_v3.x.x_linux_arm64` を落として `chmod +x` するだけ。更新は手作業 | 不採用（Homebrew に揃える） |
| `go install mvdan.cc/sh/v3/cmd/shfmt@latest` | Go toolchain が要る（このホストに `golang` は未導入） | 不採用 |

**2 つとも Homebrew に揃えたのは、shfmt に RPM が無いため。** ShellCheck だけ EPEL にすると 1 つの文書に dnf 経路と Homebrew 経路が同居し、更新も `dnf upgrade` と `brew upgrade` の 2 本立てになる。

### shfmt と `.editorconfig` の優先順位（実測）

shfmt は `.editorconfig` を読むが、**コマンドラインでフラグを 1 つでも渡すと `.editorconfig` は読まれなくなる**。一時ディレクトリで確かめた:

| `.editorconfig` | 渡したフラグ | 実際のインデント |
|---|---|---|
| 無し | 無し | **タブ**（shfmt の既定） |
| `indent_style = space` / `indent_size = 2` | 無し | スペース 2 |
| `indent_style = space` / `indent_size = 2` | `-i 4` | **スペース 4**（`.editorconfig` は無視） |

- 対応するキーは `indent_style` / `indent_size` / `switch_case_indent`（`-ci`）/ `binary_next_line`（`-bn`）/ `space_redirects`（`-sr`）/ `shell_variant`（`-ln`）
- `switch_case_indent = true` を書くと、`case` の分岐が字下げされることも確認した

**このリポジトリには `.editorconfig` を置いていない**ので、`-i 2` をコマンドラインで渡す前提で本書を書いてある（[未確認事項](#未確認事項)）。

### 完了時点の状態

**実機での出力**:

```
$ shellcheck --version
ShellCheck - shell script analysis tool
version: 0.11.0
license: GNU General Public License, version 3
website: https://www.shellcheck.net
$ shfmt --version
3.14.1
$ command -v shellcheck shfmt
/home/linuxbrew/.linuxbrew/bin/shellcheck
/home/linuxbrew/.linuxbrew/bin/shfmt
$ brew list --versions shellcheck shfmt
shellcheck 0.11.0
shfmt 3.14.1
$ brew leaves | wc -l
17
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/shellcheck/0.11.0/`（8 ファイル、49.1 MB）と `Cellar/shfmt/3.14.1/`（8 ファイル、3.4 MB）。`brew leaves` は導入前の 15 件から 17 件になった。

### 注意点

- **`docs/wireguard.md` の「`shellcheck -x` → 警告なし」は 2026-09-16 時点の記録**
  - 同じ文書の 2026-09-19 / 2026-09-20 の付録には「`shellcheck` はこのマシンに無いため未実施」と書いてあり、**その後スクリプトは変更されている**
  - 本書の[手順 4 の実測](#実施手順)が 0.11.0 での再検査で、そこで見つかった SC2034 を直した結果、**いまは再び 0 件**になっている
- **`shfmt -w` は元ファイルを上書きする**: git 管理下で、差分を確認できる状態でだけ使う。`-d` で先に差分を見る習慣にしておくと事故らない
- **shfmt の既定はタブ**: `-i` を渡さないと、スペース系のスクリプトは全行が差分になる
  - プロジェクトで揃えるなら `.editorconfig` を置き、コマンドラインでは `-i` を**渡さない**（渡すと `.editorconfig` が無視される）
- **EPEL 版と brew 版を両方入れない**: どちらもコマンド名は `shellcheck` で、PATH の先頭にある Homebrew 版が勝つ
  - EPEL のパッケージ名だけ大文字の `ShellCheck` なので、`rpm -q shellcheck` では見つからない
- **指摘があると `rc=1`**: CI に組むときはこれが期待どおりだが、`set -e` のスクリプトの途中で呼ぶと止まる。件数だけ欲しいなら `-f quiet` か `|| true`
- **`sudo shellcheck` は、そのままでは使えない**: sudo の PATH に Homebrew が無い（[homebrew.md の注意点](homebrew.md#注意点)）。root で走らせるなら、[homebrew.md の sudo でも使う](homebrew.md#sudo-でも使う任意)の節を通すか、フルパスか EPEL 版
- **コメントの中の `shellcheck` という語がディレクティブと誤認される**: 行末コメントを `# shellcheck -S に渡す…` のように書くと、**SC1126（error）**「Place shellcheck directives before commands, not after.」が出る
  - 本書の手順 1 の行末コメントは、これを踏んだので `shellcheck` を外した書き方に直してある
- **SC2034 は誤検出も出やすい**: 外部から `source` される変数や、`export` せずに使う設定ファイルの変数は「未使用」に見える。個別に潰すならディレクティブ、全体で切るなら `.shellcheckrc`

### 参照

- [ShellCheck](https://www.shellcheck.net/) — オンラインで試せる公式サイト
- [koalaman/shellcheck — README](https://github.com/koalaman/shellcheck) — ディレクティブ、`.shellcheckrc`、各エディタとの連携
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/) — `SCxxxx` ごとの解説（警告に出る URL の飛び先）
- [mvdan/sh — README](https://github.com/mvdan/sh) — shfmt のオプションと `.editorconfig` の対応キー
- `shellcheck --help` / `shfmt --help` — 全オプション
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

### 付録: コンテナでの検証記録（2026-09-23）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](homebrew.md)と手順 2〜3、[検査を調整する（任意）](#検査を調整する任意)・[`.editorconfig` の優先順位](#shfmt-と-editorconfig-の優先順位実測)を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](homebrew.md)） |
| 2. 導入 | `Pouring shellcheck--0.11.0.arm64_linux.bottle.1.tar.gz`（49.1 MB）と `shfmt--3.14.1.arm64_linux.bottle.tar.gz`（3.4 MB）。**依存の `gmp` / `libffi` はこちらでは新規に取得された**（実機は導入済みだった）。ソースビルドは発生しない |
| 3. 検証 | `version: 0.11.0` / `3.14.1`。スモークテストは実機と同じく SC2086 が 1 件・`rc=1`、shfmt も差分が出て `rc=1` |
| 検査を調整する | `mktemp -d` に `.shellcheckrc`（`disable=SC2034`）を置くと該当の指摘が消えて `rc` が `1` → `0` に変わることを確認 |
| `.editorconfig` | 既定=タブ / `indent_size=2` で 2 / `-i 4` を渡すと 4（`.editorconfig` は無視）の 3 通りを確認 |
| 4〜5. スクリプトの検査 | **実行していない**（コンテナにリポジトリを置いていない。`wg-vpn.sh` の結果は実機の記録） |
| RPM 経路 | `dnf -q list --showduplicates ShellCheck` → `0.10.0-3.el10_0 epel`。`dnf list --available shfmt` → `Error: No matching Packages to list` |

#### 未確認事項

- **修正後の `wg-vpn.sh` の実機での本実行**（`apply` / `remove` などは走らせていない。削除が無害であることは root 不要の経路 10 通りの出力一致で確かめただけ）
- `shfmt -w` を `wg-vpn.sh` に掛けること（一時ディレクトリの複製でしか試していない）
- リポジトリへの `.shellcheckrc` / `.editorconfig` の設置（どちらも一時ディレクトリでのみ確認）
- `# shellcheck source=` による `source` 先の明示（`-x` が効かない件の解決策として挙げただけ）
- `-f gcc` / `-f diff` / `-f checkstyle` の出力（`tty` と `json` だけ実測した）
- `--list-optional` で有効にできる追加の検査
- エディタ連携（[VS Code](vscode.md) の `timonwong.shellcheck` 拡張など）
- ロールバック（`brew uninstall shellcheck shfmt`）の本実行
