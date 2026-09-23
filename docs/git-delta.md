# git-delta（delta）インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

**すべて対象ホスト上で、自分のシェルで実行する**（`sudo -i` した root のシェルでは行わない。Homebrew は root で動かず、設定も自分の `~/.gitconfig` に書くため）。手順 0 で変数を設定したシェルで、上から順にコードブロックを貼る。理由・実測出力・落とし穴は[補足](#補足)にまとめてあり、実行するだけなら読まなくてよい。

**前提: Homebrew が入っていること。** `command -v brew` でバージョンが出なければ、先に [Homebrew](homebrew.md) を通す。

| 手順 | 内容 |
|---|---|
| [0. 変数を設定する](#0-変数を設定する) | 表示の好み（行番号・左右分割・移動キー）を決める |
| [1. git-delta を入れる](#1-git-delta-を入れる) | `brew install git-delta`（コマンド名は `delta`） |
| [2. git の設定を書く](#2-git-の設定を書く) | `git config --global` で `~/.gitconfig` に書く |
| [3. 検証する](#3-検証する) | 版の確認と、差分が色付きで出るか |

lazygit を使っているなら[lazygit と組み合わせる（任意）](#lazygit-と組み合わせる任意)。設定項目の一覧は[設定ファイル](#設定ファイル)。以後の更新は[更新](#更新)、戻すときは[ロールバック](#ロールバック)。

### 0. 変数を設定する

**このブロックは編集必須の変数が無い。** 3 つとも表示の好みなので、既定のままで進められる。広い画面で左右に並べたいなら `DELTA_SIDE_BY_SIDE=true` にする。**新しいシェルを開いたら（SSH を張り直したあとも）先にこのブロックを貼り直す。**

```bash
DELTA_NAVIGATE=true       # ページャ内で n / N を「次の変更・前の変更」にする。<DELTA_NAVIGATE>
DELTA_LINE_NUMBERS=true   # 差分の左に行番号を出す。<DELTA_LINE_NUMBERS>
DELTA_SIDE_BY_SIDE=false  # true にすると左右 2 面に分けて表示する。<DELTA_SIDE_BY_SIDE>
```

**値を読み戻して確かめる。**

```bash
for v in DELTA_NAVIGATE DELTA_LINE_NUMBERS DELTA_SIDE_BY_SIDE; do printf '%-19s = %s\n' "$v" "${!v}"; done
```

→ [補足](#手順-0-変数について)

### 1. git-delta を入れる

```bash
brew install git-delta
```

aarch64 でもビルド済みのボトル（`git-delta--0.19.2.arm64_linux.bottle.tar.gz`）が降ってくるので、ソースからのビルドにはならない。**formula 名は `git-delta` だが、入るコマンドは `delta`**（`brew install delta` でも同じ formula に解決される）。

### 2. git の設定を書く

`~/.gitconfig` を直接編集せず、`git config --global` で書く（既にある `[user]` や `[core]` を壊さない）。

```bash
git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global delta.navigate "${DELTA_NAVIGATE:?手順 0 の DELTA_NAVIGATE が空のまま。値を入れて貼り直す}"
git config --global delta.line-numbers "${DELTA_LINE_NUMBERS:?手順 0 の DELTA_LINE_NUMBERS が空のまま。値を入れて貼り直す}"
git config --global delta.side-by-side "${DELTA_SIDE_BY_SIDE:?手順 0 の DELTA_SIDE_BY_SIDE が空のまま。値を入れて貼り直す}"
git config --global merge.conflictstyle zdiff3
```

書けたか読み戻す。

```bash
git config --global --get-regexp '^(core\.pager|interactive\.|delta\.|merge\.conflictstyle)'
```

6 行出る。**`interactive.difffilter` と小文字で表示される**のが正しい（git がキー名を正規化するため。`~/.gitconfig` の中では `diffFilter` のまま）。

`merge.conflictstyle zdiff3` は git 2.35 以降で使える（AlmaLinux 10 の RPM は 2.52.0）。delta とは独立した設定だが、コンフリクト表示が読みやすくなるので一緒に入れている。

→ [補足](#手順-2-キー名は小文字に正規化される)

### 3. 検証する

```bash
delta --version
brew list --versions git-delta
command -v delta
```

`delta 0.19.2` / `git-delta 0.19.2` のように出る。次に、変更のあるリポジトリで差分を出す。

```bash
git diff | delta --paging=never | head -20
```

ファイル名のヘッダと、行ごとに背景色の付いた差分が出る。**`git diff` を単体で打ったときは端末に直接出る場合だけ delta を通る**（`git diff | head` のようにパイプに繋ぐと git はページャを呼ばないので、素の差分が出る）。

→ [補足](#手順-3-パイプに繋ぐとページャは働かない)

---

## lazygit と組み合わせる（任意）

lazygit は自前のページャ設定を持っているので、`~/.gitconfig` の `core.pager` は見ない。[lazygit.md](lazygit.md#設定ファイル) の設定ファイルに次を足す:

```yaml
git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never
```

**`~/.config/lazygit/config.yml` に既に `git:` があるなら、`cat >>` で追記せずに手で中身を併合する。** 同じトップレベルキーを 2 回書くと YAML として壊れる。現在の中身は `lazygit --print-config-dir` で場所を確かめてから開く。

この節はコンテナで検証していない（[未確認事項](#未確認事項)）。

---

## 設定ファイル

設定の実体は `~/.gitconfig` の `[delta]` セクション。手順 2 で書いた 3 つのほかによく使うもの:

| キー | 意味 |
|---|---|
| `features` | 名前付き設定のまとめ読み（`[delta "<名前>"]` を作って指定する） |
| `syntax-theme` | シンタックスハイライトの配色。一覧は `delta --list-syntax-themes` |
| `hyperlinks` | ファイル名を端末のハイパーリンクにする |
| `true-color` | 24 bit 色を使うか（既定は端末から自動判定） |
| `file-style` / `minus-style` / `plus-style` | ファイル名行・削除行・追加行の色 |

今の実効値は `delta --show-config` で全部出る。`delta --help` にはオプションとして同じ名前が並んでおり、コマンドラインで一時的に上書きできる。

---

## 更新

```bash
brew upgrade git-delta
```

すべてまとめて上げるなら `brew upgrade`。

---

## ロールバック

```bash
brew uninstall git-delta
git config --global --unset core.pager
git config --global --unset interactive.diffFilter
git config --global --remove-section delta
git config --global --unset merge.conflictstyle     # zdiff3 も戻す場合
git config --global --get-regexp '^(core\.pager|interactive\.|delta\.)'   # 何も出なければ消えている
```

**`core.pager` を消し忘れると、`git diff` のたびに `delta: command not found` になる。** lazygit の `git.paging` を足していた場合は `~/.config/lazygit/config.yml` からも消す。

本書ではロールバックは**本実行していない**。

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 で `git diff` / `git show` / `git log -p` の表示を [delta](https://github.com/dandavison/delta)（シンタックスハイライト付きのページャ）に置き換える。**EPEL にも AppStream にも RPM が無い**
- **進め方**: Homebrew で入れ、`git config --global` で `~/.gitconfig` に書く。**読者が書き換えるのは冒頭の変数ブロックだけ**
- **状態**: **コンテナでのみ検証済み（2026-09-22）。実機には入れていない。** 下表の検証コンテナで**この文書のコードブロックをそのまま貼って**[Homebrew の導入](homebrew.md)と手順 1〜3 を通し、`arm64_linux` のボトルが降りること・`delta 0.19.2` が入ること・使い捨てリポジトリの `git diff | delta --paging=never` が色付きで出ること・`git config --global --get-regexp` で 6 項目が読み戻せることを確認した。**実機（Raspberry Pi 5）では本実行していない**（実機の `~/.gitconfig` は `[core] autocrlf` と `[user]` だけのまま）ので、下表の実機列は「この手順を適用した結果」ではなく**現時点の状態**を書いてある。**コンテナには端末が無いため、`core.pager` 経由のページャ起動（`git diff` を素で打ったときの表示）と `navigate` の `n` / `N` は確認していない**

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| git | `git 2.52.0`（AlmaLinux の RPM） | 同じ（`2.52.0`） |
| delta | **未導入** | `git-delta 0.19.2` → コマンドは `delta` |
| `~/.gitconfig` | `[core] autocrlf` と `[user]` のみ（**delta の設定は書いていない**） | 手順 2 の 6 項目を設定 |
| lazygit | `lazygit 0.65.1`（Homebrew、[lazygit.md](lazygit.md)）。`git.paging` は未設定 | 未導入 |
| 端末 | WezTerm nightly（[wezterm-nightly.md](wezterm-nightly.md)） | 無し（pty を与えずに実行） |

> **注記**: 環境固有の値は**シェル変数**で書いてある。[手順 0](#0-変数を設定する) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${DELTA_NAVIGATE}` | `delta.navigate`。ページャ内の `n` / `N` を変更単位の移動にする | `true`（既定）/ `false` |
> | `${DELTA_LINE_NUMBERS}` | `delta.line-numbers`。差分の左に行番号を出す | `true`（既定）/ `false` |
> | `${DELTA_SIDE_BY_SIDE}` | `delta.side-by-side`。左右 2 面に分けて表示する | `false`（既定）/ `true` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`0.19.2`）は実行日によって変わる。

手順の理由・実測・落とし穴・検証記録。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| delta | 未導入 |
| Homebrew | 7.0.6 導入済み |
| git | 2.52.0（RPM）。ページャは既定の `less` |
| lazygit | 0.65.1 導入済み（[lazygit.md](lazygit.md)）。ページャ設定は無し |
| EPEL | 有効。ただし `delta` も `git-delta` も無い |

### 選択した方針

AlmaLinux 10 aarch64 で delta を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `git-delta 0.19.2` の `arm64_linux` ボトルがある。upstream の最新と一致。formula に `delta` という別名が付いているので `brew install delta` でも入る | **採用** |
| EPEL / AppStream / CRB | **`delta` も `git-delta` も無い**（`dnf list --available delta git-delta` → `Error: No matching Packages to list`）。※ `delta` という名前の無関係なパッケージも無い | 使えない |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-gnu` の tar と `.rpm` が置いてある。rpm を直接入れると dnf のリポジトリ管理外になり更新が手作業になる | 不採用（Homebrew に揃える） |
| `cargo install git-delta` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |
| diff-so-fancy / difftastic | 別物（difftastic は EPEL に `0.67.0` がある）。構文木で比較する difftastic とは用途が違うので、置き換えではなく併用できる | 対象外 |

### 手順の補足

#### 手順 0: 変数について

3 つとも `~/.gitconfig` の `[delta]` に書かれる値で、後から `git config --global delta.side-by-side true` で変えられる。`navigate` を `true` にすると、ページャ（`less`）の中で `n` が「次の変更へ」になる。delta が `less` に渡すオプションで実現しているので、`core.pager` 経由で起動したときだけ効く。

#### 手順 2: キー名は小文字に正規化される

git はセクション名とキー名を小文字に正規化して扱う。`interactive.diffFilter` と書いても、`--get-regexp` や `--list` では `interactive.difffilter` と出る。**大文字の `F` を含む正規表現では引っかからない**ので、読み戻しの正規表現は `interactive\.` までにしてある。コンテナでの実測:

```
$ git config --global --get-regexp '^(core\.pager|interactive\.|delta\.|merge\.conflictstyle)'
core.pager delta
interactive.difffilter delta --color-only
delta.navigate true
delta.line-numbers true
delta.side-by-side false
merge.conflictstyle zdiff3
$ cat ~/.gitconfig
[user]
	name = <USER>
	email = <EMAIL>
[core]
	pager = delta
[interactive]
	diffFilter = delta --color-only
[delta]
	navigate = true
	line-numbers = true
	side-by-side = false
[merge]
	conflictstyle = zdiff3
```

ファイルの中では `diffFilter` のまま残る（git が書き込むときは指定した綴りを使う）。値を 1 つだけ取るなら `git config --global --get interactive.diffFilter` は大文字のままでも通る（こちらは正規表現ではなくキー名の照合で、大小を区別しないため）。

#### 手順 3: パイプに繋ぐとページャは働かない

git は**標準出力が端末のときだけ** `core.pager` を起動する。したがって:

- `git diff` を素で打つ → delta が起動する（端末が要る。本書では未検証）
- `git diff | head` → ページャを通らず、素の unified diff が出る
- `git diff | delta --paging=never` → 明示的に delta に渡しているので色が付く

検証ブロックで 3 番目の形を使っているのはこのため。コンテナでの実測（ANSI エスケープは除いてある）:

```
$ git diff | delta --paging=never | head -12

f.txt
────────────────────────────────────────────────────────────────────────────────

───┐
1: │
───┘
a
b
B
c
d
$ git diff | head -8
diff --git a/f.txt b/f.txt
index de98044..a7bc997 100644
--- a/f.txt
+++ b/f.txt
@@ -1,3 +1,4 @@
 a
-b
+B
```

### 完了時点の状態

**検証コンテナでの出力**（実機では本実行していない）:

```
$ delta --version
delta 0.19.2
$ brew list --versions git-delta
git-delta 0.19.2
$ command -v delta
/home/linuxbrew/.linuxbrew/bin/delta
$ git --version
git version 2.52.0
$ git config --global --get-regexp '^(core\.pager|interactive\.|delta\.|merge\.conflictstyle)'
core.pager delta
interactive.difffilter delta --color-only
delta.navigate true
delta.line-numbers true
delta.side-by-side false
merge.conflictstyle zdiff3
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/git-delta/0.19.2/`（12 ファイル、7.4 MB）。

### 注意点

- **`core.pager` は PATH に `delta` がある文脈でしか動かない**: Homebrew の PATH は `~/.bashrc` の `brew shellenv` で通っているので、`~/.bashrc` を読まない文脈（cron、一部の非対話シェル、他ユーザー、`sudo -i` しない root）で `git diff` を打つと `delta: command not found` になる。固くしたいならフルパスで指定する: `git config --global core.pager /home/linuxbrew/.linuxbrew/bin/delta`
- **表示だけを変える。差分の中身は変わらない**: `git diff > patch.diff` はページャを通らないので従来どおりのパッチが出る。`git apply` や CI の挙動には影響しない
- **`sudo git` には効かない**: root は root の `~/.gitconfig` を読むので、この設定は入っていない
- **`interactive.diffFilter` が変えるのは `git add -p` の表示だけ**: 選択の操作自体は git のまま
- **lazygit は `core.pager` を見ない**: 別途 `git.paging` の設定が要る（[lazygit と組み合わせる（任意）](#lazygit-と組み合わせる任意)）
- **PATH の先頭が Homebrew になる**: `brew shellenv` を `~/.bashrc` に書いた時点で `/home/linuxbrew/.linuxbrew/bin` が先頭に来る

### 参照

- [dandavison/delta — README](https://github.com/dandavison/delta) — 使い方、`~/.gitconfig` の書き方、side-by-side と navigate の説明
- [delta manual](https://dandavison.github.io/delta/) — 全設定項目、`features` による設定のまとめ方、他ツールとの連携
- `delta --help` / `delta --show-config` / `delta --list-syntax-themes` — オプションと実効値、配色の一覧
- `git help config` の `core.pager` / `interactive.diffFilter` — git 側の仕様
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](homebrew.md)と手順 1〜3 を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。差分を出すために `/tmp` に 1 ファイルだけの使い捨てリポジトリを作った。[bat](bat.md) を先に入れた同じコンテナなので、依存は取得済みだった。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](homebrew.md)） |
| 1. git-delta | `Pouring git-delta--0.19.2.arm64_linux.bottle.tar.gz` → `12 files, 7.4MB`。**依存は取得されなかった**（`libgit2` / `oniguruma` / `zlib-ng-compat` は bat で導入済み）。`brew info git-delta` に `Aliases: delta` と出る |
| 2. git の設定 | 6 項目を `git config --global` で設定。読み戻しで**`interactive.difffilter` と小文字化される**ことが分かり、当初書いていた `interactive\.diffFilter` を含む正規表現では 1 行も出なかったため、本文の正規表現を `interactive\.` に直した |
| 3. 検証 | `delta --version` → `delta 0.19.2`。`git diff \| delta --paging=never` でファイル名ヘッダ・行番号・背景色付きの差分を確認。`git diff \| head`（パイプ）では素の unified diff になることも確認 |
| 設定の確認 | `delta --show-config` で実効値（`true-color = false` など）が出ること、`delta --list-syntax-themes` が `dark` / `light` 別に並ぶことを確認 |
| RPM 経路 | `dnf list --available delta git-delta` → `Error: No matching Packages to list`（EPEL を有効にした状態で） |

#### 未確認事項

- 実機での本実行（本書は実機に適用していない。検証はコンテナのみ）
- `git diff` を素で打ったときの `core.pager` 経由のページャ起動と表示
- `delta.navigate` の `n` / `N`（`less` の中での操作）
- `side-by-side = true` の表示
- `git add -p`（`interactive.diffFilter`）の表示
- `merge.conflictstyle zdiff3` のコンフリクト表示
- [lazygit と組み合わせる（任意）](#lazygit-と組み合わせる任意)の `git.paging` 設定
- `core.pager` をフルパスにした場合の挙動
- ロールバック（`brew uninstall` と `git config --unset`）の本実行
