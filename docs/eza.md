# eza インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew は root で動かず、エイリアスも自分の `~/.bashrc` に書くため）

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 普段使いにするなら[エイリアスを足す（任意）](#エイリアスを足す任意)。列や時刻の書式は[表示を調整する](#表示を調整する)、以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **コンテナでのみ検証した手順書**で、実機では本実行していない（[対象と検証環境](#対象と検証環境)）。

1. **変数を設定する**

   - **編集が必須の変数は無い**。[エイリアスを足す（任意）](#エイリアスを足す任意)で `ll` / `la` に付ける共通オプションを決めるだけで、既定のままでよい
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

   ```bash
   EZA_OPTS="--git --group-directories-first"   # ll / la に共通で付けるオプション。<EZA_OPTS>
   ```

   **値を読み戻して確かめる。**

   ```bash
   printf 'EZA_OPTS = %s\n' "${EZA_OPTS}"
   ```

   <details>
   <summary>補足: 変数について</summary>

   - `${EZA_OPTS}` は[エイリアスを足す（任意）](#エイリアスを足す任意)でしか使わない。エイリアスを作らないなら、空のままでも手順 2〜3 は通る
   - `--group-directories-first` は、GNU `ls` の同名オプションと同じ意味
   - `--git` は、git 管理下でだけ `Git` 列を足す

   </details>

1. **eza を入れる**

   ```bash
   brew install eza
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - 依存は `libgit2` 1 つだけ（`--git` 列のため）

   <details>
   <summary>補足: 降ってくるボトル</summary>

   aarch64 で降ってくるボトルは `eza--0.23.5.arm64_linux.bottle.tar.gz`。

   </details>

1. **検証する**

   ```bash
   eza --version
   brew list --versions eza
   command -v eza
   ```

   - `v0.23.5 [+git]` を含む 3 行が出る
   - `[+git]` が付いていれば、git 連携込みでビルドされている

   次に、git 管理下のディレクトリで `Git` 列が出ることを確かめる（`cd` する先は自分のリポジトリでよい）。

   ```bash
   eza -l --git --header .
   ```

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

**`ls` は置き換えない。** `ll` / `la` / `lt` を足す形にする（理由は[注意点](#注意点)）。

```bash
printf 'alias ll="eza -l %s"\nalias la="eza -la %s"\nalias lt="eza --tree --level=2"\n' \
  "${EZA_OPTS:?手順 1 の EZA_OPTS が空のまま。値を入れて貼り直す}" "${EZA_OPTS}" >> ~/.bashrc
. ~/.bashrc
alias ll la lt
```

- `alias ll='eza -l --git --group-directories-first'` のように 3 行出れば入っている
- **`alias` の確認に `type -t` は使えない**（非対話シェルではエイリアスが展開されず、`type` が見つけられない。[補足](#補足)の[注意点](#注意点)を参照）

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

```bash
brew upgrade eza
```

すべてまとめて上げるなら `brew upgrade`。

---

## ロールバック

```bash
brew uninstall eza
sed -i '/alias l[lat]=.*eza/d' ~/.bashrc     # エイリアスを足していた場合
```

- 依存の `libgit2` は [bat](bat.md) / [git-delta](git-delta.md) も使うので、不要になったものだけ消すなら `brew autoremove`
- 本書ではロールバックは**本実行していない**

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [eza](https://github.com/eza-community/eza)（`ls` の代わりになる一覧表示。git 連携・ツリー表示・色分けが付く）を入れる。**EPEL にも AppStream にも RPM が無い**
- **進め方**: Homebrew で入れ、必要なら `~/.bashrc` にエイリアスを足す。**読者が書き換えるのは冒頭の変数ブロックだけ**
- **状態**: **コンテナでのみ検証済み（2026-09-22）。実機には入れていない**
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
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${EZA_OPTS}` | `ll` / `la` のエイリアスに共通で付けるオプション | `--git --group-directories-first`（既定） |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`0.23.5`）は実行日によって変わる。

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
- **PATH の先頭が Homebrew になる**: `brew shellenv` を `~/.bashrc` に書いた時点で `/home/linuxbrew/.linuxbrew/bin` が先頭に来る
- **`sudo eza` は使えない**: root の PATH に Homebrew は入っていない

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
