# eza インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、共通設定も自分のユーザーに導入するため）

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 普段使いにするなら[エイリアスを足す（任意）](#エイリアスを足す任意)。列や時刻の書式は[表示を調整する](#表示を調整する)、以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **現行版 `5da3478` を、共通 bash 設定を新規導入した別の x86_64 VM でも再検証した**（末尾の再検証記録）。既存ホストの手動移行は今回は実行していない。
>
> **x86_64 のクリーン VM で検証対象版の実施手順を本実行済み**（2026-10-06）。コンテナでも検証したが、実機では本実行していない（[対象と検証環境](#対象と検証環境)）。

1. 共通の bash 設定が導入済みか確かめる。

   ```bash
   echo "${__bash_config_loaded-読まれていない}"
   ```

   - `1` が出ればよい。未導入なら [共通設定の導入](../README.md#共通の-bash-設定を先に入れる)を行い、端末を開き直す

1. brew で eza を入れる。

   ```bash
   brew install eza
   ```

   - 確認が出たら表示された導入予定を確かめて `y` と答え、処理が終わってプロンプトに戻ってから次の手順を貼る（[Homebrew の注意点](homebrew.md#注意点)）
   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - 依存は `libgit2` 1 つだけ（`--git` 列のため）

   <details>
   <summary>補足: 降ってくるボトル</summary>

   aarch64 で降ってくるボトルは `eza--0.23.5.arm64_linux.bottle.tar.gz`。

   </details>

1. git 管理下のディレクトリに `cd` してから、eza の版と `Git` 列を確かめる。

   ```bash
   eza --version
   brew list --versions eza
   command -v eza
   eza -l --git --header .
   ```

   - `cd` する先は自分のリポジトリでよい
   - `eza --version` は `v0.23.5 [+git]` を含む 3 行を出す
   - `[+git]` が付いていれば、git 連携込みでビルドされている
   - 最後の行で、`Git` 列が出ることを確かめる
   - `Permissions Size User Date Modified Git Name` という見出しが出る
   - 変更したファイルの `Git` 列に `-M` が付く
   - **git 管理下でないディレクトリでは、`Git` 列そのものが出ない**

   <details>
   <summary>補足: <code>Git</code> 列の読み方</summary>

   `--git` は **git 管理下のディレクトリでしか列を出さない**。コンテナで使い捨てのリポジトリを作って確かめた実測:

   ```
   $ eza -l --git --header .
   Permissions Size User   Date Modified Git Name
   .rw-r--r--@    8 <USER> 22 Sep 20:47   -M f.txt
   $ eza -la --git --group-directories-first .
   drwxr-xr-x@ - <USER> 22 Sep 20:47  -I .git
   .rw-r--r--@ 8 <USER> 22 Sep 20:47  -M f.txt
   ```

   - `Git` 列は 2 文字で、左がインデックスの状態、右が作業ツリーの状態
   - `-M` は「インデックスは変更なし・作業ツリーで変更あり」、`-I` は ignore されているもの

   git 管理下でない `/etc` では列自体が出ない:

   ```
   $ eza -l --git /etc | head -3
   .rw-r--r--@   16 root  2 Sep 10:54 adjtime
   .rw-r--r--@   12 root 15 Jan 00:00 adjtime.rpmnew
   .rw-r--r--@ 1.5k root 29 Nov  2023 aliases
   ```

   パーミッション欄の末尾に付く `@` は拡張属性があることを示す（`-@` / `--extended` で中身が見られる）。SELinux を使う AlmaLinux では多くのファイルに付く。

   </details>

---

## エイリアスを足す（任意）

- **`ls` は置き換えない**。`ll` / `la` / `lt` を足す形にする（理由は[注意点](#注意点)）

1. 共通設定を読み直し、ll / la / lt を確かめる。

   ```bash
   . ~/.bashrc
   alias ll la lt
   ```

   - `ll` は `eza -l --git --group-directories-first`、`la` は `-la`、`lt` は `eza --tree --level=2`
   - 共通のオプションは bash リポジトリで管理する。`EZA_OPTS` の設定や `~/.bashrc` への追記は不要

---

## 表示を調整する

設定ファイルは無く、すべてコマンドラインオプションと環境変数で決める。よく使うもの:

| やりたいこと | オプション |
|---|---|
| 列の見出しを出す | `--header`（`-h`） |
| 時刻の書式を変える | `--time-style=long-iso` / `iso` / `relative` / `+%Y-%m-%d` |
| 8 進数のパーミッション | `--octal-permissions`（`-o`） |
| アイコンを出す | `--icons=always`（**Nerd Font が要る**） |
| ディレクトリを先に並べる | `--group-directories-first` |
| `.gitignore` のファイルを隠す | `--git-ignore` |
| git 連携を切る | `--no-git` |

- 色は `LS_COLORS` と `EZA_COLORS` を見る
- 全オプションは `eza --help`（86 行）と `man eza`

---

## 更新

1. brew で eza を更新する。

   ```bash
   brew upgrade eza
   ```

   - すべてまとめて上げるなら `brew upgrade`

---

## ロールバック

- 本書ではロールバックは**本実行していない**

1. brew で eza を消す。

   ```bash
   brew uninstall eza
   ```

   - 依存の `libgit2` は [bat](bat.md) / [git-delta](git-delta.md) が必要とする間は残る。Homebrew 7 では、不要になった依存は `brew uninstall` の後に自動で削除される。自動削除を無効にしていた場合は、`brew autoremove --dry-run` で対象を確認してから `brew autoremove` を使う

1. 端末を閉じて開き直す。

   - 削除したツールの設定は、次のシェルでは共通設定から読み込まれない
   - `~/.bashrc` にツール別の行は書いていないので、削除も不要

---

## 補足

- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

### 対象と検証環境

- **目的**: AlmaLinux 10 に [eza](https://github.com/eza-community/eza)（`ls` の代わりになる一覧表示。git 連携・ツリー表示・色分けが付く）を入れる。**EPEL にも AppStream にも RPM が無い**
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **`0dbb522` の直接追記版の実施手順 1〜3 を x86_64 のクリーン VM で本実行済み（2026-10-06）。コンテナでも検証済み（2026-09-22）。実機には入れていない**。現行版 `5da3478` の共通 bash 新規導入後の再検証も、末尾に記録した。既存ホストの手動移行は今回は実行していない。
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**[Homebrew の導入](homebrew.md)と手順 2〜3 を通した
  - 確認したこと: `arm64_linux` のボトルが降りる、`v0.23.5 [+git]` が出る、git リポジトリで `Git` 列に `-M` / `-I` が付く
  - **確認していないこと**: 色分けの見え方とアイコン（`--icons`）。コンテナには端末が無いため
  - **実機（Raspberry Pi 5）では本実行していない**ので、下表の実機列は「この手順を適用した結果」ではなく**現時点の状態**を書いてある

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| eza | **未導入** | `eza 0.23.5`（`arm64_linux` ボトル） |
| 一緒に入る依存 | — | `libgit2` とその先 7 つ |
| Nerd Font | `font-symbols-only-nerd-font 3.5.1`（Homebrew、[yazi.md](yazi.md)） | 無し |
| 端末 | WezTerm nightly（[wezterm-nightly.md](wezterm-nightly.md)） | 無し（pty を与えずに実行） |

> [!NOTE]
> シェルのエイリアス・初期化は bash リポジトリの値を使う。本書で設定するシェル変数は無い。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| eza | 未導入 |
| Homebrew | 7.0.6 導入済み |
| EPEL | 有効。ただし `eza` も `exa` も無い |
| `ls` | `coreutils` の GNU `ls`（RPM）。置き換えない |

### 選択した方針

AlmaLinux 10 aarch64 で eza を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `eza 0.23.5` の `arm64_linux` ボトルがある。upstream の最新と一致 | **採用** |
| EPEL / AppStream / CRB | **`eza` も、前身の `exa` も無い**（`dnf list --available eza exa` → `Error: No matching Packages to list`） | 使えない |
| 公式の deb リポジトリ | eza は Debian/Ubuntu 向けの apt リポジトリを配っているが、**RPM 版の配布は無い** | 使えない |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-gnu` / `musl` のビルドがある。展開して PATH に置くだけだが、更新は手作業 | 不採用（Homebrew に揃える） |
| `cargo install eza` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

コンテナで取った RPM 側の実測:

```
$ dnf list --available eza exa delta git-delta starship
Last metadata expiration check: 0:00:08 ago on Tue Sep 22 20:46:27 2026.
Error: No matching Packages to list
```

- この 1 回の実行で、eza / exa / delta / git-delta / starship のどれも無いことを確かめている
- [git-delta.md](git-delta.md) と [starship.md](starship.md) でも同じ出力を使っている

### 完了時点の状態

**検証コンテナでの出力**（実機では本実行していない）:

```
$ eza --version
eza - A modern, maintained replacement for ls
v0.23.5 [+git]
https://github.com/eza-community/eza
$ brew list --versions eza
eza 0.23.5
$ command -v eza
/home/linuxbrew/.linuxbrew/bin/eza
$ alias ll la lt
alias ll='eza -l --git --group-directories-first'
alias la='eza -la --git --group-directories-first'
alias lt='eza --tree --level=2'
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/eza/0.23.5/`（15 ファイル、2.0 MB）。man ページ（`share/man/man1/eza.1`）とシェル補完も同梱される。

### 注意点

- **`alias ls=eza` は勧めない**。`ll` / `la` を足すだけにしておくと、`ls` はいつでも GNU のものとして残る
  - eza は GNU `ls` の全オプションを実装していない
  - `-G` の意味が違い（`ls` は「グループを出さない」、eza は「グリッド表示」）、`--time-style` に渡せる値も別物
  - エイリアスは対話シェルにしか効かないのでスクリプトは壊れないが、**壊れないぶん、手が覚えたフラグが通らないときに原因が分かりにくい**
- **エイリアスの確認に `type -t` は使えない**: bash は非対話シェルでエイリアスを展開しないため、`type -t ll` はエイリアスを見つけられない（`alias ll` なら確認できる）
  - 関数を定義する [zoxide](zoxide.md) / [yazi](yazi.md) の `y()` は、この制約を受けない
- **アイコンには Nerd Font が要る**: `--icons=always` はグリフを出すだけなので、フォントが無い端末では豆腐になる
  - 実機には `font-symbols-only-nerd-font` が入っている（[yazi.md](yazi.md)）が、本書では見え方を確認していない
- **`--git` は大きなリポジトリで遅くなる**: 毎回 git の状態を引くため。気になるなら `--no-git`、リポジトリの一覧だけなら `--git-repos-no-status`
- **Homebrew 全般の注意は [homebrew.md の注意点](homebrew.md#注意点)**: PATH の先頭が Homebrew になる、`sudo eza` はそのままでは使えない、など

### 参照

- [eza-community/eza — README](https://github.com/eza-community/eza) — 使い方、各ディストリビューションでの入手方法、`ls` との違い
- [eza.rocks](https://eza.rocks) — 公式サイト。スクリーンショットと機能一覧
- `eza --help` / `man eza` — 全オプション（`--help` は 86 行）
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](homebrew.md)と手順 2〜3、[エイリアスを足す（任意）](#エイリアスを足す任意)を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。[bat](bat.md) を先に入れた同じコンテナなので、依存の `libgit2` は取得済みだった。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](homebrew.md)） |
| 2. eza | `Pouring eza--0.23.5.arm64_linux.bottle.tar.gz` → `15 files, 2MB`。**依存は取得されなかった**（`libgit2` は bat で導入済みのため）。単独で入れた場合の依存は `brew deps --tree eza` で `libgit2` とその先 7 つ |
| 3. 検証 | `eza --version` → `v0.23.5 [+git]`。`eza -l --git --header` で `Git` 列が出て、変更ファイルに `-M`、`.git` に `-I` が付いた。`/etc`（git 管理外）では `Git` 列が出ないことも確認 |
| エイリアス | `~/.bashrc` に 3 行追記して読み込み直し、`alias ll la lt` で 3 つとも展開されることを確認。**`type -t ll` は非対話シェルでは失敗する**ことも確認した |
| 表示オプション | `--header` / `--octal-permissions` / `--tree --level=2` / `--icons=always` が動作。`EZA_COLORS=... eza -l --color=always` もエラーなく実行できたが、**色の正しさは判定していない** |
| RPM 経路 | `dnf list --available eza exa` → `Error: No matching Packages to list`（EPEL を有効にした状態で） |

#### 未確認事項

- 実機での本実行（本書は実機に適用していない。検証はコンテナのみ）
- 端末での色分けの見え方（`LS_COLORS` / `EZA_COLORS` の効き方）
- アイコン表示（`--icons=always` と Nerd Font の組み合わせ）
- `--git-repos` / `--git-repos-no-status`、`--loc`、`--total-size` などの重い機能
- 大きなリポジトリでの `--git` の速度
- ロールバック（`brew uninstall` と `~/.bashrc` の行削除）の本実行

---

### 付録: クリーン VM での検証記録（2026-10-06）

**検証対象**: `0dbb522` の、各手順で `~/.bashrc` などへ設定を直接追記する版。以下の手順番号と「本文」はこの版を指す。検証後に共通 bash 設定へ統一された現行版（`0bc9970`）の設定リポジトリの新規導入・既存設定からの移行は、今回の VM では実行していない。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証対象版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順（`0dbb522`）**: 実施手順 1〜3。

**結果**: Homebrew の eza 0.23.5 を導入し、パスと版、検証用 Git リポジトリの一覧を確認した。変更したファイルの Git 列は `-M` だった。

**今回の未確認範囲**: エイリアス・アイコン、更新・ロールバックは今回流していない。


### 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜3 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で実行した。先に共通 bash `3d5323e` を新規導入した
- eza 0.23.5 の bottle・版・PATH を確認し、共通設定の `ll` / `la` / `lt` を読み直した。使い捨ての Git リポジトリで `ll` の変更記号 `-M`、隠しファイル一覧と深さ 2 の木を確認した
- 更新・削除、任意の色設定、既存ホストの設定移行は今回は実行していない
