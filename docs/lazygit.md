# lazygit 最新版インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

**すべて対象ホスト上で、自分のシェルで実行する**（`sudo -i` した root のシェルでは行わない。Homebrew は root で動かない）。手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る（各手順の末尾で折り畳んである「補足」の中のブロックは、手順を進めるためには貼らなくてよい）。理由・実測出力・落とし穴は、手順ごとのものはその手順の「補足」に、全体に関わるものは後半の[補足](#補足)にまとめてあり、実行するだけなら読まなくてよい。

**前提: Homebrew が入っていること。** `command -v brew` でバージョンが出なければ、先に [Homebrew](homebrew.md) を通す。

設定を書く場所は[設定ファイル](#設定ファイル)。以後の更新は[更新](#更新)、戻すときは[ロールバック](#ロールバック)。

1. **変数を設定する**

   **このブロックは編集必須の変数が無い。** `e` キーで開くエディタを変えたいときだけ書き換える。**新しいシェルを開いたら（SSH を張り直したあとも）先にこのブロックを貼り直す。**

   ```bash
   LG_EDITOR=nvim                  # lazygit の e キーで開くエディタ。vim / code など。<LG_EDITOR>
   ```

   **値を読み戻して確かめる。**

   ```bash
   printf 'LG_EDITOR = %s\n' "${LG_EDITOR}"
   ```

   <details>
   <summary>補足: 変数について</summary>

   `LG_EDITOR` を使うのは[設定ファイル](#設定ファイル)の節だけ。lazygit は設定が無ければ `EDITOR` 環境変数を見るので、`~/.bashrc` に `export EDITOR=nvim` があれば設定ファイルは要らない。

   </details>

1. **lazygit を入れる**

   ```bash
   brew install lazygit
   ```

   aarch64 でもビルド済みのボトル（`lazygit--0.65.1.arm64_linux.bottle.tar.gz`）が降ってくるので、ソースからのビルドにはならない。

   <details>
   <summary>補足: ボトルが降りること</summary>

   ボトルが降りたことの確認（実測、コンテナ）:

   ```
   ==> Downloading bottle manifests
   ✔︎ Bottle Manifest lazygit (0.65.1)
   ==> Fetching downloads for: lazygit
   ✔︎ Bottle lazygit (0.65.1)
   ==> Pouring lazygit--0.65.1.arm64_linux.bottle.tar.gz
   🍺  /home/linuxbrew/.linuxbrew/Cellar/lazygit/0.65.1: 6 files, 18.8MB
   ```

   </details>

1. **検証する**

   ```bash
   lazygit --version
   brew list --versions lazygit
   command -v lazygit
   ```

   `build source=Homebrew, version=0.65.1, os=linux, arch=arm64` のように出る。次に、git リポジトリのルートに `cd` してから `lazygit` を起動して確認する（`q` で終了）。git 管理下でないディレクトリで起動すると、リポジトリを作るか聞かれる。

   <details>
   <summary>補足: 起動時の注意</summary>

   `lazygit --version` の `git version` 欄には、lazygit が呼ぶ git のバージョンが出る。**git が入っていないと lazygit は起動しない**（Homebrew 版は git を依存に持たないので、RPM の git か `brew install git` のどちらかが要る）。このホストは RPM の git 2.52.0 を使っている。

   git 管理下でないディレクトリで起動すると `Would you like to create a new repository?` と聞かれる。意図せず `.git` を作らないよう、リポジトリのルートで起動する。

   </details>

---

## 設定ファイル

パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く。置き場所は `~/.config/lazygit/config.yml`（`lazygit --print-config-dir` で確認できる）。エディタだけ指定する最小の例:

```bash
mkdir -p ~/.config/lazygit
cat >> ~/.config/lazygit/config.yml <<EOF
os:
  edit: '${LG_EDITOR:?手順 1 の LG_EDITOR が空のまま。値を入れて貼り直す} {{filename}}'
EOF
lazygit --print-config-dir
```

既定値の全体は `lazygit --config` で表示できる。アプリ内では `x` でキーバインド一覧が出る。

---

## 更新

```bash
brew upgrade lazygit
```

すべてまとめて上げるなら `brew upgrade`。

---

## ロールバック

```bash
brew uninstall lazygit
```

`~/.config/lazygit/` と `~/.local/state/lazygit/` は残るので、要らなければ手で消す。

本書ではロールバックは**本実行していない**。

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に git の TUI クライアント [lazygit](https://github.com/jesseduffield/lazygit) の最新版を入れる
- **進め方**: Homebrew で入れる。**読者が書き換えるのは冒頭の変数ブロック（エディタ）だけ**。RPM（COPR）経路は実機でもコンテナでも通らなかった（[選択した方針](#選択した方針)）
- **状態**: **実機で本実行済み（2026-09-20）。** 下表のホストで `brew install lazygit` を実行し、`lazygit 0.65.1` が入って常用中。[Homebrew の導入](homebrew.md)と手順 2〜3、[設定ファイル](#設定ファイル)の節は 2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直し、ボトルが降りること・`lazygit --version` が出ること・`config.yml` を書いた後に `lazygit --print-config-dir` が `~/.config/lazygit` を返すことを確認した。**コンテナでは TUI の起動と `e` キーの動作は確認していない**（端末が無いため）。**実機には設定ファイルを置いていない**

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| 入った lazygit | `lazygit 0.65.1`（`arm64_linux` ボトル、6 ファイル / 18.8 MB） | 同じ（`0.65.1`） |
| git | `git-2.52.0-1.el10.aarch64`（RPM） | `git 2.52.0`（依存で導入） |

> **注記**: 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${LG_EDITOR}` | lazygit の `e` キーで開くエディタ。[設定ファイル](#設定ファイル)でだけ使う | `nvim` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`0.65.1`）は実行日によって変わる。`<git リポジトリ>` のような `<...>` を含むコマンドは bash のコードブロックに置いていない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| lazygit | 未導入（COPR から入れようとして失敗した直後） |
| Homebrew | 7.0.6 導入済み（同じ日の少し前に公式インストーラで導入） |
| git | `git-2.52.0-1.el10.aarch64` 導入済み |
| 有効な追加リポジトリ | epel、crb、raspberrypi、COPR（dejan/lazygit を有効化した状態） |

### 選択した方針

AlmaLinux 10 aarch64 で lazygit の最新版を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `lazygit 0.65.1` の `arm64_linux` ボトルがある。upstream の最新リリース（v0.65.1、2026-09-13）と一致 | **採用** |
| COPR `dejan/lazygit` | `epel-10-aarch64` chroot はあるが、**リポジトリメタデータを取得できない**（`repomd.xml` が 403）。`dnf install lazygit` は `No match for argument` で終わる。実機でも 2 度試して入らなかった | 不採用（入らない） |
| COPR `atim/lazygit` | 同上。`epel-10-aarch64` chroot はあるが `repomd.xml` が 403 | 不採用（入らない） |
| GitHub Releases の tarball | `lazygit_<version>_Linux_arm64.tar.gz` がある。展開して PATH に置くだけだが、更新は手作業 | 不採用 |
| EPEL / AppStream | `lazygit` は無い（`dnf list lazygit` → `No matching Packages to list`） | 使えない |
| `go install` | Go toolchain が要り、更新のたびにビルドする | 不採用 |

**COPR が通らないことの実測**（コンテナ、2026-09-22）。`dnf copr enable` 自体は成功して repo ファイルもできるが、メタデータの取得で落ちる:

```
$ sudo dnf copr enable dejan/lazygit
Repository successfully enabled.
$ sudo dnf install lazygit
Copr repo for lazygit owned by dejan             98  B/s | 333  B     00:03
Errors during downloading metadata for repository 'copr:copr.fedorainfracloud.org:dejan:lazygit':
  - Status code: 403 for https://copr-pulp-prod.s3.amazonaws.com/artifact/...&Expires=1790097163 (IP: 52.217.69.236)
Error: Failed to download metadata for repo '...': Cannot download repomd.xml: ...
Ignoring repositories: copr:copr.fedorainfracloud.org:dejan:lazygit
No match for argument: lazygit
Error: Unable to find a match: lazygit
```

`atim/lazygit` でも同じ 403。dnf を介さず `curl -L` で `repomd.xml` を取っても同じで、COPR の配信元（`download.copr.fedorainfracloud.org`）が S3 の署名付き URL にリダイレクトし、その署名が期限切れになっている。一方で COPR 全体が落ちているわけではなく、同じ日に `lihaohong/yazi` の `epel-10-aarch64` はメタデータを取得できている（[yazi.md](yazi.md)）。**プロジェクトごとの問題で、いずれ直る可能性がある**。

### 完了時点の状態

```
$ brew list --versions lazygit
lazygit 0.65.1
$ lazygit --version
commit=, build date=, build source=Homebrew, version=0.65.1, os=linux, arch=arm64, git version=2.52.0
$ command -v lazygit
/home/linuxbrew/.linuxbrew/bin/lazygit
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/lazygit/0.65.1/`（6 ファイル、18.8 MB）。`commit=` と `build date=` が空なのは Homebrew ビルドの仕様。

### 注意点

- **PATH の先頭が Homebrew になる**: `brew shellenv` が `/home/linuxbrew/.linuxbrew/bin` を PATH の先頭に置く。RPM 版と両方入れると分かりにくくなるので、どちらか一方にする
- **COPR 経路は「有効化は成功するのに入らない」**: `dnf copr enable` が通っても、メタデータが取れなければ `dnf install` は `No match for argument` になるだけで、原因は警告行にしか出ない。COPR を使う前に `curl -sS -o /dev/null -w '%{http_code}\n' -L <chroot の repodata/repomd.xml>` で 200 が返るか確かめると早い
- **git が要る**: lazygit は git のラッパーなので、git の設定（`user.name` / `user.email`、認証）はそのまま効く
- **設定ファイルは自分で作る**: `lazygit --print-config-dir` が返すディレクトリは、初回起動時には空のことがある

### 参照

- [jesseduffield/lazygit — README](https://github.com/jesseduffield/lazygit) — 各 OS のインストール方法と機能一覧
- [lazygit Config Docs](https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md) — `config.yml` の項目（`os.edit` など）
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作
- [atim/lazygit — Copr](https://copr.fedorainfracloud.org/coprs/atim/lazygit/) / [dejan/lazygit — Copr](https://copr.fedorainfracloud.org/coprs/dejan/lazygit/) — chroot の一覧（`epel-10-aarch64` はある）

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで、非 root ユーザーを作って[Homebrew の導入](homebrew.md)と手順 2〜3、[設定ファイル](#設定ファイル)の節を通した。実機で加えた変更は `dnf install podman` だけ。 実行したのは**この文書のコードブロックをそのまま抜き出したスクリプト**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git sudo` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](homebrew.md)） |
| 2. lazygit | `Pouring lazygit--0.65.1.arm64_linux.bottle.tar.gz`（6 files, 18.8MB）。ソースビルドは発生しない |
| 3. 検証 | `lazygit --version` → `build source=Homebrew, version=0.65.1, os=linux, arch=arm64, git version=2.52.0` |
| 設定ファイル | `config.yml` を書いたあと `lazygit --print-config-dir` → `/home/<USER>/.config/lazygit` |
| COPR（`dejan`） | `copr enable` は成功。`dnf install lazygit` はメタデータ 403 → `No match for argument: lazygit` |
| COPR（`atim`） | 同上（403） |
| `curl` での確認 | 両プロジェクトとも `repodata/repomd.xml` が `copr-pulp-prod.s3.amazonaws.com` にリダイレクトされ、HTTP 403 |

実機でも 2026-09-20 に `dnf copr enable dejan/lazygit` → `dnf install lazygit` を 2 度試して入らず（`dnf history` にトランザクションが残っていない）、そのあと `brew install lazygit` に切り替えている。**同じ失敗が 2 日後のコンテナでも再現した。**

#### 未確認事項

- TUI の起動・キー操作（コンテナに端末が無いため。実機では常用している）
- [設定ファイル](#設定ファイル)の節（`config.yml` を書いた状態での `e` キーの動作）
- COPR の 403 が解消したあとに `dnf install lazygit` が通るか（通れば RPM 管理に移せる）
- GitHub Releases の tarball 経路
- ロールバック（`brew uninstall`）の本実行
