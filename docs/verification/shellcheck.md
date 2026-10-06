# ShellCheck / shfmt インストール手順（AlmaLinux 10 / Homebrew）の検証記録

[手順書](../shellcheck.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- `${SC_TARGET}` だけが環境固有で、それ以外は好みの値
- `${SC_SEVERITY}` の既定 `style` は**いちばん緩い設定で、error / warning / info / style のすべてが出る**（`-S` は「この重大度以上を出す」という意味）。実害のあるものだけ見たいなら `error`
- `${SHFMT_INDENT}` の既定を `2` にしてあるのは、`wg-vpn.sh` が**スペース 2 インデントで書かれている**のを実測したため（タブは 0 行）
- shfmt 自身の既定は**タブ**なので、`-i` を渡さないと全行が差分になる

### 実施手順 / 手順 2: 補足: ボトルと依存

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

### 実施手順 / 手順 4: 本文中の記録

   - 出たときは、この手順の補足に読み方と実測がある

### 実施手順 / 手順 4: 補足: wg-vpn.sh の検査結果（実測）

**最新の再検査（2026-10-06）**: AlmaLinux 10.2 Workstation のクリーンな x86_64 VM に、このリポジトリの `scripts/wireguard/wg-vpn.sh` を変更せずコピーして検査した。ShellCheck 0.11.0・shfmt 3.14.1 を使い、本文の手順 4 の `bash -n` と `shellcheck -x` は両方 `rc=0`、手順 5 の JSON 集計は 0 件だった。コピーしたファイルの SHA-256 は `d8b5ba4bca3326f2ed07b6b84c7713baf0c49c2753ba760f9b7ad872d1c23e6c`。スクリプトの本実行や `shfmt -w` はしていない。

以下は、実機で `scripts/wireguard/wg-vpn.sh` を検査したときの経緯。**この補足の行数と差分の数値は、下記の修正を入れる前のもの**（当時 1,300 行、修正後は 1,299 行）。

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

### 実施手順 / 手順 5: 本文中の記録

   - `wg-vpn.sh` を `-S` ごとに数えた実測は、手順 4 の補足にある

### ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**

### 対象と検証環境

- **目的**: AlmaLinux 10 に [ShellCheck](https://www.shellcheck.net/)（シェルスクリプトの静的検査）と [shfmt](https://github.com/mvdan/sh)（整形）を入れる。**このリポジトリの `CLAUDE.md` が「よく使うコマンド」として `shellcheck -x scripts/wireguard/wg-vpn.sh` を挙げているのに、実機に入っていなかった**のが動機
- **進め方**: Homebrew で 2 つ同時に入れ、`scripts/wireguard/wg-vpn.sh` を実際に検査する。**読者が書き換えるのは冒頭の変数ブロック（検査対象のパス）だけ**
- **状態**: **実機で本実行済み（2026-09-23）**。**x86_64 のクリーン VM でも現行の実施手順を本実行済み（2026-10-06）**
  - 下表のホストで `brew install shellcheck shfmt` を実行し、`shellcheck 0.11.0` と `shfmt 3.14.1` が入って常用中
  - **`wg-vpn.sh`（1,300 行）を 0.11.0 で検査して警告 1 件（SC2034）を見つけ、同じ変更でそれを直して 0 件にした**（[手順 4 の補足](../shellcheck.md#実施手順)）
  - 手順 2〜3 と[検査を調整する（任意）](../shellcheck.md#検査を調整する任意)・[shfmt と `.editorconfig` の優先順位](#shfmt-と-editorconfig-の優先順位実測)は、2026-09-23 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - コンテナで確認したこと: ボトルが降りる、スモークテストが同じ結果になる、EPEL 版の版と名前
  - **コンテナでは手順 4〜5（`wg-vpn.sh` の検査）は実行していない**（リポジトリを置いていないため）
  - 2026-10-05: `jq` の前提と空値の確認、`SC_TARGET` の親ディレクトリを調べる形に直した。スタブで、別パスへの変更・JSON の件数集計・`jq` が無い場合の中断を確認した
  - shfmt 3.14.1 の公式ソースと配布バイナリを確認し、一時ファイルで EditorConfig の優先順位を検証した。オプションなし・`-d`・`-l`・`-w` は設定の空白 2、`-i 4` は空白 4、`-s` は既定のタブになった。実機のスクリプトは変更していない

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
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../shellcheck.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
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

AlmaLinux 10 aarch64 で ShellCheck を入れる経路を比べた（2026-09-23 時点）:

### shfmt と `.editorconfig` の優先順位（実測）

shfmt は `.editorconfig` を読むが、**構文解析・整形のオプション**（`-i`・`-ln`・`-s` など）を指定すると、整形設定はコマンドライン側を使う。`-d`・`-w`・`-l` だけなら、この切り替えは起きない（3.14.1 のソースで確認）。次の表は一時ディレクトリでの実測:

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

### 注意点 / 手順 0: 本文中の記録

- **`docs/wireguard.md` の「`shellcheck -x` → 警告なし」は 2026-09-16 時点の記録**

### 注意点 / 手順 0: 本文中の記録

  - 同じ文書の 2026-09-19 / 2026-09-20 の付録には「`shellcheck` はこのマシンに無いため未実施」と書いてあり、**その後スクリプトは変更されている**

### 注意点 / 手順 0: 本文中の記録

  - 本書の[手順 4 の実測](../shellcheck.md#実施手順)が 0.11.0 での再検査で、そこで見つかった SC2034 を直した結果、**いまは再び 0 件**になっている

### 参照

- [ShellCheck](https://www.shellcheck.net/) — オンラインで試せる公式サイト
- [koalaman/shellcheck — README](https://github.com/koalaman/shellcheck) — ディレクティブ、`.shellcheckrc`、各エディタとの連携
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/) — `SCxxxx` ごとの解説（警告に出る URL の飛び先）
- [mvdan/sh — README](https://github.com/mvdan/sh) — shfmt のオプションと `.editorconfig` の対応キー
- [shfmt 3.14.1 のオプション処理](https://github.com/mvdan/sh/blob/v3.14.1/cmd/shfmt/main.go) — Parser / Printer のオプションを指定した場合の EditorConfig の扱い（2026-10-05 にソースを確認）
- `shellcheck --help` / `shfmt --help` — 全オプション
- [Homebrew](../homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

### 付録: コンテナでの検証記録（2026-09-23）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](../homebrew.md)と手順 2〜3、[検査を調整する（任意）](../shellcheck.md#検査を調整する任意)・[`.editorconfig` の優先順位](#shfmt-と-editorconfig-の優先順位実測)を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](../homebrew.md)） |
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
- エディタ連携（[VS Code](../vscode.md) の `timonwong.shellcheck` 拡張など）
- ロールバック（`brew uninstall shellcheck shfmt`）の本実行

---

### 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜5。

**結果**: ShellCheck 0.11.0 と shfmt 3.14.1 を導入した。手順 3 の意図的に不備を含むサンプルは指摘・整形差分が出て両方 `rc=1` になった。手順 4・5 は、このリポジトリの `wg-vpn.sh` を VM にコピーし、`SC_TARGET` をそのパスに変えて検査した。`bash -n` と `shellcheck -x` は両方 `rc=0`、JSON の件数は 0。元のスクリプトは変更していない。

**今回の未確認範囲**: スクリプト自体の本実行、`shfmt -w`、任意の検査設定や EditorConfig、更新・ロールバックは今回流していない。

### 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜4 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM の SSH 対話 PTY で実行した。ShellCheck 0.11.0 / shfmt 3.14.1 の bottle・版・PATH を確認した
- 本文の例で SC2086 と終了値 1、shfmt の変更差分と終了値 1 を確認した。現在の `wg-vpn.sh` と共通 bash の `install.sh` / `bashrc` は構文・ShellCheck を通した（bashrc は `-s bash` を付けた）
- 「shfmt で整形を確かめる」「検査を調整する」の任意節も実行した。読み取り可能な専用ディレクトリで差分 889 行・`-l` の対象一覧を確認し、一時複製への `-w` で 1302 行が 1451 行になった。SC1090 の directive と、一時 `.shellcheckrc` の検査の終了値 0 を確認した。元の公開スクリプトは変えなかった
- 最初の補助試験では対象を `/tmp` 直下へ置いたため、ディレクトリを巡る `shfmt -f` / `-l` は systemd の private 一時ディレクトリで権限不足になった。検査対象を専用ディレクトリへ移して再実行した。手順の不具合とは区別する
- Yazi の追加ツールとして jq 1.8.2 が入った後に手順 5 を同じ公開 `wg-vpn.sh` へ実行し、JSON 件数 0・終了値 0 を確認した。更新・削除は今回は実行していない


### 実施手順 / 手順 3: 補足: 終了コードの意味

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

## 参考資料から分離した記録

### 参考資料: 選択した方針

#### ShellCheck

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

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 検査を調整する（任意） / 手順 2

   - **本書ではリポジトリに `.shellcheckrc` を置いていない**（[未確認事項](shellcheck.md#未確認事項)）
