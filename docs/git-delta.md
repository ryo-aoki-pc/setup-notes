# git-delta（delta）インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。Homebrew の導入・管理は一般ユーザーで行い、設定も自分の `~/.gitconfig` に書く
> - **手順 2 で Homebrew の確認が出る場合がある**。答えて導入が完了してから手順 3 を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: lazygit を使っているなら[lazygit と組み合わせる（任意）](#lazygit-と組み合わせる任意)。設定項目の一覧は[設定ファイル](#設定ファイル)、以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **x86_64 のクリーン VM で実施手順を本実行済み**（2026-10-06）で、実機では本実行していない（[対象と検証環境](#対象と検証環境)）。

1. 変数を設定する。

   ```bash
   DELTA_NAVIGATE=true       # ページャ内で n / N を「次の変更・前の変更」にする。<DELTA_NAVIGATE>
   DELTA_LINE_NUMBERS=true   # 差分の左に行番号を出す。<DELTA_LINE_NUMBERS>
   DELTA_SIDE_BY_SIDE=false  # true にすると左右 2 面に分けて表示する。<DELTA_SIDE_BY_SIDE>
   for v in DELTA_NAVIGATE DELTA_LINE_NUMBERS DELTA_SIDE_BY_SIDE; do printf '%-19s = %s\n' "$v" "${!v}"; done
   ```

   - **編集が必須の変数は無い**。3 つとも表示の好みなので、既定のままで進められる
   - 広い画面で左右に並べたいなら、`DELTA_SIDE_BY_SIDE=true` にする
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

   <details>
   <summary>補足: 変数について</summary>

   - 3 つとも `~/.gitconfig` の `[delta]` に書かれる値で、後から `git config --global delta.side-by-side true` で変えられる
   - `navigate` を `true` にすると、ページャ（`less`）の中で `n` が「次の変更へ」になる。delta が `less` に渡すオプションで実現しているので、`core.pager` 経由で起動したときだけ効く

   </details>

1. brew で git-delta を入れる。

   ```bash
   brew install git-delta
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - **formula 名は `git-delta` だが、入るコマンドは `delta`**（`brew install delta` でも同じ formula に解決される）
   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

   <details>
   <summary>補足: 降ってくるボトル</summary>

   aarch64 で降ってくるボトルは `git-delta--0.19.2.arm64_linux.bottle.tar.gz`。

   </details>

1. `git config --global` で git の設定を書き、読み戻す。

   ```bash
   if [ -z "${DELTA_NAVIGATE}" ] || [ -z "${DELTA_LINE_NUMBERS}" ] || [ -z "${DELTA_SIDE_BY_SIDE}" ]; then
     echo '中断: 手順 1 の変数が空。3 つとも設定してから貼り直す' >&2
   else
     git config --global core.pager delta &&
       git config --global interactive.diffFilter 'delta --color-only' &&
       git config --global delta.navigate "${DELTA_NAVIGATE}" &&
       git config --global delta.line-numbers "${DELTA_LINE_NUMBERS}" &&
       git config --global delta.side-by-side "${DELTA_SIDE_BY_SIDE}" &&
       git config --global merge.conflictstyle zdiff3 &&
       git config --global --get-regexp '^(core\.pager|interactive\.difffilter|delta\.(navigate|line-numbers|side-by-side)|merge\.conflictstyle)$'
   fi
   ```

   - `~/.gitconfig` を直接編集せず、`git config --global` で書く（既にある `[user]` や `[core]` を壊さない）
   - 最後の行で、書けたか読み戻す
   - 設定した 6 項目が出る。`中断:` が出た場合は、どの設定も書き換えていない
   - **`interactive.difffilter` と小文字で表示される**のが正しい（git がキー名を正規化するため。`~/.gitconfig` の中では `diffFilter` のまま）
   - `merge.conflictstyle zdiff3` は delta とは独立した設定だが、コンフリクト表示が読みやすくなるので一緒に入れている
   - `zdiff3` は git 2.35 以降で使える（AlmaLinux 10 の RPM は 2.52.0）
   - [git.md 手順 6](git.md#実施手順) でも同じ値を入れる。先に通していても、同じキーが書き直されるだけ

   <details>
   <summary>補足: キー名は小文字に正規化される</summary>

   git はセクション名とキー名を小文字に正規化して扱う。`interactive.diffFilter` と書いても、`--get-regexp` や `--list` では `interactive.difffilter` と出る。**大文字の `F` を含む正規表現では引っかからない**ので、読み戻しでは小文字を使う。以前の広い正規表現でのコンテナ実測:

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

   - ファイルの中では `diffFilter` のまま残る（git が書き込むときは指定した綴りを使う）
   - 値を 1 つだけ取るなら、`git config --global --get interactive.diffFilter` は大文字のままでも通る（こちらは正規表現ではなくキー名の照合で、大小を区別しないため）

   </details>

1. 変更のあるリポジトリに `cd` してから、delta の版と差分の表示を確かめる。

   ```bash
   delta --version
   brew list --versions git-delta
   command -v delta
   git diff | delta --paging=never | head -20
   ```

   - 版は `delta 0.19.2` / `git-delta 0.19.2` のように出る
   - 最後の行で、変更のあるリポジトリの差分を出す
   - ファイル名のヘッダと、行ごとに背景色の付いた差分が出る
   - **`git diff` を単体で打ったときは、端末に直接出る場合だけ delta を通る**。`git diff | head` のようにパイプに繋ぐと git はページャを呼ばないので、素の差分が出る

   <details>
   <summary>補足: パイプに繋ぐとページャは働かない</summary>

   git は**標準出力が端末のときだけ** `core.pager` を起動する。したがって:

   - `git diff` を素で打つ → delta が起動する（端末が要る。本書では未検証）
   - `git diff | head` → ページャを通らず、素の unified diff が出る
   - `git diff | delta --paging=never` → 明示的に delta に渡しているので色が付く

   この手順で 3 番目の形を使っているのはこのため。コンテナでの実測（ANSI エスケープは除いてある）:

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

   </details>

---

## lazygit と組み合わせる（任意）

- lazygit は自前のページャ設定を持っているので、`~/.gitconfig` の `core.pager` は見ない
- この節はコンテナで検証していない（[未確認事項](#未確認事項)）
- lazygit 0.65.1 の公式設定に合わせて `git.diffRenderers` を使う（2026-10-05 に対象版の資料とソースを確認。TUI での表示は未検証）

> [!WARNING]
> **この節の手順 1 で、`~/.config/lazygit/config.yml` に既に `git:` があるなら、`cat >>` で追記せずに手で中身を併合する。** 同じトップレベルキーを 2 回書くと YAML として壊れる。

1. [lazygit.md](lazygit.md#設定ファイル) の設定ファイルに、delta をページャにする設定を足す。

   ```yaml
   git:
     diffRenderers:
       - type: stdinFilter
         colorArg: always
         command: delta --dark --paging=never
   ```

   - 現在の中身は、`lazygit --print-config-dir` で場所を確かめてから開く

---

## 設定ファイル

設定の実体は `~/.gitconfig` の `[delta]` セクション。手順 3 で書いた 3 つのほかによく使うもの:

| キー | 意味 |
|---|---|
| `features` | 名前付き設定のまとめ読み（`[delta "<名前>"]` を作って指定する） |
| `syntax-theme` | シンタックスハイライトの配色。一覧は `delta --list-syntax-themes` |
| `hyperlinks` | ファイル名を端末のハイパーリンクにする |
| `true-color` | 24 bit 色を使うか（既定は端末から自動判定） |
| `file-style` / `minus-style` / `plus-style` | ファイル名行・削除行・追加行の色 |

- 今の実効値は `delta --show-config` で全部出る
- `delta --help` にはオプションとして同じ名前が並んでおり、コマンドラインで一時的に上書きできる

---

## 更新

1. brew で git-delta を更新する。

   ```bash
   brew upgrade git-delta
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - **ほかのコマンドは、Homebrew の確認が出たら答え、更新が終わってから貼る**（続けて貼ると確認の答えとして食われる）

---

## ロールバック

- 本書ではロールバックは**本実行していない**

1. brew で git-delta を消し、git から delta の設定を外す。

   ```bash
   brew uninstall git-delta
   git config --global --unset core.pager
   git config --global --unset interactive.diffFilter
   git config --global --remove-section delta
   ```

   - **`core.pager` を消し忘れると、`git diff` のたびに `delta: command not found` になる**

1. `zdiff3` も戻すときだけ、`merge.conflictstyle` を外す。

   ```bash
   git config --global --unset merge.conflictstyle     # zdiff3 も戻す場合
   ```

   - [git.md](git.md) を通したなら外さない（同じ設定を使う）

1. delta の設定が消えたか確かめる。

   ```bash
   git config --global --get-regexp '^(core\.pager|interactive\.difffilter|delta\.)'   # 何も出なければ消えている
   ```

   - 何も出なければ消えている
   - lazygit の `git.diffRenderers` に delta の項目を足していた場合は、その項目も消す（ほかの renderer は残す）。以前の `git.paging` を使っていた場合は、そちらの delta 設定を外す

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 で `git diff` / `git show` / `git log -p` の表示を [delta](https://github.com/dandavison/delta)（シンタックスハイライト付きのページャ）に置き換える。**EPEL にも AppStream にも RPM が無い**
- **進め方**: Homebrew で入れ、`git config --global` で `~/.gitconfig` に書く。**読者が書き換えるのは冒頭の変数ブロックだけ**
- **状態**: **x86_64 のクリーン VM で実施手順を本実行済み（2026-10-06）。コンテナでも検証済み（2026-09-22）。実機には入れていない**
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**[Homebrew の導入](homebrew.md)と手順 2〜4 を通した
  - 確認したこと: `arm64_linux` のボトルが降りる、`delta 0.19.2` が入る、使い捨てリポジトリの `git diff | delta --paging=never` が色付きで出る、`git config --global --get-regexp` で 6 項目が読み戻せる
  - コンテナで未確認だった `core.pager` 経由のページャ起動（`git diff` を素で打ったときの表示）と `navigate` の `n` / `N` は、2026-10-06 のクリーン VM で確認した（末尾の付録）
  - **実機（Raspberry Pi 5）では本実行していない**（実機の `~/.gitconfig` は `[core] autocrlf` と `[user]` だけのまま）ので、下表の実機列は「この手順を適用した結果」ではなく**現時点の状態**を書いてある
  - 2026-10-05: 手順 3 の空チェックを先頭に移した。一時的な Git 設定ファイルで、3 変数を 1 つずつ空にすると変更が無く、正常時には 6 項目が設定されて既存の別キーは残ることを確認した
  - lazygit 0.65.1 の任意設定は、同版の公式資料とソースに合わせて `git.diffRenderers` に訂正した。TUI での連携は未検証のまま

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| git | `git 2.52.0`（AlmaLinux の RPM） | 同じ（`2.52.0`） |
| delta | **未導入** | `git-delta 0.19.2` → コマンドは `delta` |
| `~/.gitconfig` | `[core] autocrlf` と `[user]` のみ（**delta の設定は書いていない**） | 手順 3 の 6 項目を設定 |
| lazygit | `lazygit 0.65.1`（Homebrew、[lazygit.md](lazygit.md)）。`git.paging` は未設定 | 未導入 |
| 端末 | WezTerm nightly（[wezterm-nightly.md](wezterm-nightly.md)） | 無し（pty を与えずに実行） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${DELTA_NAVIGATE}` | `delta.navigate`。ページャ内の `n` / `N` を変更単位の移動にする | `true`（既定）/ `false` |
> | `${DELTA_LINE_NUMBERS}` | `delta.line-numbers`。差分の左に行番号を出す | `true`（既定）/ `false` |
> | `${DELTA_SIDE_BY_SIDE}` | `delta.side-by-side`。左右 2 面に分けて表示する | `false`（既定）/ `true` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`0.19.2`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

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

- **`core.pager` は PATH に `delta` がある文脈でしか動かない**
  - Homebrew の PATH は `~/.bashrc` の `brew shellenv` で通っているので、`~/.bashrc` を読まない文脈（cron、一部の非対話シェル、他ユーザー、`sudo -i` しない root）で `git diff` を打つと `delta: command not found` になる
  - 固くしたいなら、フルパスで指定する: `git config --global core.pager /home/linuxbrew/.linuxbrew/bin/delta`
- **表示だけを変える。差分の中身は変わらない**: `git diff > patch.diff` はページャを通らないので従来どおりのパッチが出る。`git apply` や CI の挙動には影響しない
- **`sudo git` には効かない**: root は root の `~/.gitconfig` を読むので、この設定は入っていない
- **`interactive.diffFilter` が変えるのは `git add -p` の表示だけ**: 選択の操作自体は git のまま
- **lazygit は `core.pager` を見ない**: 0.65.1 では別途 `git.diffRenderers` を設定する（[lazygit と組み合わせる（任意）](#lazygit-と組み合わせる任意)）
- **Homebrew 全般の注意は [homebrew.md の注意点](homebrew.md#注意点)**: PATH の先頭が Homebrew になる、`~/.bashrc` を読まない文脈では見えない、など

### 参照

- [dandavison/delta — README](https://github.com/dandavison/delta) — 使い方、`~/.gitconfig` の書き方、side-by-side と navigate の説明
- [delta manual](https://dandavison.github.io/delta/) — 全設定項目、`features` による設定のまとめ方、他ツールとの連携
- [lazygit 0.65.1 の差分表示設定](https://github.com/jesseduffield/lazygit/blob/v0.65.1/docs/Custom_DiffRenderers.md) — `git.diffRenderers` の `stdinFilter` と delta の指定
- `delta --help` / `delta --show-config` / `delta --list-syntax-themes` — オプションと実効値、配色の一覧
- `git help config` の `core.pager` / `interactive.diffFilter` — git 側の仕様
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](homebrew.md)と手順 2〜4 を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。差分を出すために `/tmp` に 1 ファイルだけの使い捨てリポジトリを作った。[bat](bat.md) を先に入れた同じコンテナなので、依存は取得済みだった。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](homebrew.md)） |
| 2. git-delta | `Pouring git-delta--0.19.2.arm64_linux.bottle.tar.gz` → `12 files, 7.4MB`。**依存は取得されなかった**（`libgit2` / `oniguruma` / `zlib-ng-compat` は bat で導入済み）。`brew info git-delta` に `Aliases: delta` と出る |
| 3. git の設定 | 6 項目を `git config --global` で設定。**読み戻しで`interactive.difffilter` と小文字化される**ことが分かり、当初書いていた `interactive\.diffFilter` を含む正規表現では 1 行も出なかったため、本文の正規表現を `interactive\.` に直した |
| 4. 検証 | `delta --version` → `delta 0.19.2`。`git diff \| delta --paging=never` でファイル名ヘッダ・行番号・背景色付きの差分を確認。`git diff \| head`（パイプ）では素の unified diff になることも確認 |
| 設定の確認 | `delta --show-config` で実効値（`true-color = false` など）が出ること、`delta --list-syntax-themes` が `dark` / `light` 別に並ぶことを確認 |
| RPM 経路 | `dnf list --available delta git-delta` → `Error: No matching Packages to list`（EPEL を有効にした状態で） |

#### 未確認事項

- 実機での本実行（本書は実機に適用していない）
- `side-by-side = true` の表示
- `git add -p`（`interactive.diffFilter`）の表示
- `merge.conflictstyle zdiff3` のコンフリクト表示
- [lazygit と組み合わせる（任意）](#lazygit-と組み合わせる任意)の `git.paging` 設定
- `core.pager` をフルパスにした場合の挙動
- ロールバック（`brew uninstall` と `git config --unset`）の本実行

---

### 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜4と、追加のページャ操作。

**結果**: Homebrew の git-delta 0.20.1 を導入し、6 設定を読み戻した。検証用リポジトリの差分を、パイプと `core.pager` 経由の実際の less 661 の画面で表示し、行番号を確認した。複数ファイルと離れた変更を用意し、`n` で変更へ進み `N` で前へ戻った。最初の目印より前に `N` で進もうとすると `Pattern not found` になる。初回の短いキー試験はこの境界に当たったため、前後の目印がある位置でも確認し直した。

**今回の未確認範囲**: lazygit の delta 連携、side-by-side、merge・interactive.diffFilter の実際の操作、更新・ロールバックは今回確認していない。


### 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜4 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM の SSH 対話 PTY で実行した。delta 0.20.1 の bottle・版・PATH と Git のページャなど 6 設定を確認した
- 使い捨ての Git リポジトリで差分を表示し、ファイル名・行番号と変更行の出力を確認した。実機のリポジトリや資格情報は使っていない
- 更新・削除と任意のテーマ選択はこの再検証では実行していない
