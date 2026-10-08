# lazygit 最新版インストール手順（AlmaLinux 10 / Homebrew）の検証記録

[手順書](../lazygit.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順 / 手順 2: 補足: ボトルが降りること

aarch64 で降ってくるボトルは `lazygit--0.65.1.arm64_linux.bottle.tar.gz`。

ボトルが降りたことの確認（実測、コンテナ）:

```
==> Downloading bottle manifests
✔︎ Bottle Manifest lazygit (0.65.1)
==> Fetching downloads for: lazygit
✔︎ Bottle lazygit (0.65.1)
==> Pouring lazygit--0.65.1.arm64_linux.bottle.tar.gz
🍺  /home/linuxbrew/.linuxbrew/Cellar/lazygit/0.65.1: 6 files, 18.8MB
```

### ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**

### 対象と検証環境

- **目的**: AlmaLinux 10 に git の TUI クライアント [lazygit](https://github.com/jesseduffield/lazygit) の最新版を入れる
- **進め方**: Homebrew で入れる
  - **読者が書き換えるのは冒頭の変数ブロック（エディタ）だけ**
  - RPM（COPR）経路は実機でもコンテナでも通らなかった（[選択した方針](../reference/lazygit.md#選択した方針)）
- **状態**: **実機で本実行済み（2026-09-20）**。**x86_64 のクリーン VM でも現行の実施手順を本実行済み（2026-10-06）**
  - 下表のホストで `brew install lazygit` を実行し、`lazygit 0.65.1` が入って常用中
  - [Homebrew の導入](../almalinux-setup.md)と手順 2〜3、[設定ファイル](../lazygit.md#設定ファイル)の節は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - 確認したこと: ボトルが降りる、`lazygit --version` が出る、`config.yml` を書いた後に `lazygit --print-config-dir` が `~/.config/lazygit` を返す
  - **コンテナでは TUI の起動と `e` キーの動作は確認していない**（端末が無いため）
  - **実機には設定ファイルを置いていない**
  - 2026-10-02: [設定ファイル](../lazygit.md#設定ファイル)の手順 1 を、`LG_EDITOR` が空なら何もせずに止める `if … fi` にした
    - それまでは、ヒアドキュメントの中の `${LG_EDITOR:?…}` が `cat` しか止めず（[gnome-power.md 手順 3 の補足](almalinux-setup.md#画面オフロックサスペンド-実施手順--手順-3-補足-ログイン画面の設定の置き場所とgdm-ユーザーで読む理由)）、`>>` が空の `config.yml` を作り、後ろの `lazygit --print-config-dir` も動いた
    - 直した形は、擬似端末の対話の bash にブラケットペースト無しで、変数を空にしたときと値を入れたときの 1 回ずつ貼って確かめた（`HOME` は使い捨てのディレクトリ、`lazygit` はスタブ）
  - 2026-10-05: 既存設定への無条件追記をやめ、エディタの存在も確かめる形にした。一時ディレクトリとスタブで、新規作成・再実行・既存 `os:` ありの 3 通りを確認した（既存内容は変わらず、`os:` は重複しない）。TUI は起動していない

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| 入った lazygit | `lazygit 0.65.1`（`arm64_linux` ボトル、6 ファイル / 18.8 MB） | 同じ（`0.65.1`） |
| git | `git-2.52.0-1.el10.aarch64`（RPM） | `git 2.52.0`（依存で導入） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../lazygit.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${LG_EDITOR}` | lazygit の `e` キーで開くエディタ。[設定ファイル](../lazygit.md#設定ファイル)でだけ使う | `nvim` |
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

### 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで、非 root ユーザーを作って[Homebrew の導入](../almalinux-setup.md)と手順 2〜3、[設定ファイル](../lazygit.md#設定ファイル)の節を通した。実機で加えた変更は `dnf install podman` だけ。 実行したのは**この文書のコードブロックをそのまま抜き出したスクリプト**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git sudo` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](../almalinux-setup.md)） |
| 2. lazygit | `Pouring lazygit--0.65.1.arm64_linux.bottle.tar.gz`（6 files, 18.8MB）。ソースビルドは発生しない |
| 3. 検証 | `lazygit --version` → `build source=Homebrew, version=0.65.1, os=linux, arch=arm64, git version=2.52.0` |
| 設定ファイル | `config.yml` を書いたあと `lazygit --print-config-dir` → `/home/<USER>/.config/lazygit` |
| COPR（`dejan`） | `copr enable` は成功。`dnf install lazygit` はメタデータ 403 → `No match for argument: lazygit` |
| COPR（`atim`） | 同上（403） |
| `curl` での確認 | 両プロジェクトとも `repodata/repomd.xml` が `copr-pulp-prod.s3.amazonaws.com` にリダイレクトされ、HTTP 403 |

実機でも 2026-09-20 に `dnf copr enable dejan/lazygit` → `dnf install lazygit` を 2 度試して入らず（`dnf history` にトランザクションが残っていない）、そのあと `brew install lazygit` に切り替えている。**同じ失敗が 2 日後のコンテナでも再現した。**

#### 未確認事項

- TUI からの commit・push・pull（クリーン VM では起動・一覧と差分の表示・終了を確認）
- [設定ファイル](../lazygit.md#設定ファイル)の節（`config.yml` を書いた状態での `e` キーの動作）
- COPR の 403 が解消したあとに `dnf install lazygit` が通るか（通れば RPM 管理に移せる）
- GitHub Releases の tarball 経路
- ロールバック（`brew uninstall`）の本実行

---

### 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜3。

**結果**: Homebrew の lazygit 0.66.0 を導入し、RPM の Git 2.52.0 が使われることを確認した。検証用リポジトリで起動し、初回の案内を Enter で閉じて、変更・未追跡ファイル、ブランチ、コミット、差分の画面を読み、`q` で終了した。捕捉ライブラリが private SGR を受けられず初回の画面読み取りが止まったため、検証補助だけを直して画面を取得し直した。

**今回の未確認範囲**: エディタ連携の設定、自分用の設定、リモートへの push/pull、更新・ロールバックは今回確認していない。

### 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜3 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM の SSH 対話 PTY で実行し、Homebrew の lazygit 0.66.0 の導入・版・PATH・TUI・`q` での終了を確認した
- 個人設定 `ryo-aoki-pc/lazygit` の `custom` (`dc3873e`) も README どおり公開 URL から clone してリンクした。0.66.0 が旧キー 4 個を自動移行し設定ファイルを書き換える問題を再現したため、当該キーを現行名・配置へ修正した。修正後の TUI で再書き換えが無いことと公式 0.66.0 JSON Schema のエラー 0 件を確認した（設定リポジトリ README の記録）
- 実リポジトリへのコミット・push、上流設定更新、パッケージの更新・削除は今回は実行していない

### 選択した方針

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

### 実施手順 / 手順 3: 補足: 起動時の注意

- このホストは RPM の git 2.52.0 を使っている

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 実施手順 / 手順 3

   - 初回に `Thanks for using lazygit...` の案内が出たら Enter で閉じる。ファイル・変更差分・ブランチ・コミットの一覧が出ればよい（0.66.0 のクリーン VM で確認）
