# gdu インストール手順（AlmaLinux 10 / Homebrew）の検証記録

[手順書](../gdu.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **現行版 `5da3478` を、共通 bash を新規導入した別の x86_64 VM で再検証した**（末尾の再検証記録）。既存ホストの手動移行は実行していない。
>
> **x86_64 のクリーン VM で検証対象版の実施手順を本実行済み**（2026-10-06）。実機では本書の手順を順に実行していない。実機にある Homebrew 版（5.37.0）は、2026-09-21 に本書とは別の経緯で入れたもの（[対象と検証環境](#対象と検証環境)）。

### 実施手順 / 手順 2: 補足: 非対話モード

`-n` / `--non-interactive` を付けると TUI を起動せず、走査結果を標準出力に流す。**端末が無い場所（スクリプト、コンテナ、`podman exec`）でも動く数少ないモード**なので、本書の検証はここで実動作を確かめている。コンテナでの実測:

```
$ gdu-go -n /usr/share | tail -8
        0 B /dict
        0 B /desktop-directories
        0 B /backgrounds
        0 B /augeas
        0 B /applications
        0 B /appdata
        0 B /aclocal
        0 B /X11
```

そのほか非対話で使うフラグ:

- `--depth <N>`（表示する階層）
- `-p` / `--no-progress`（進捗を出さない）
- `--no-prefix`（サイズを生の数値で）
- `-c` / `--no-color`

逆に、端末でなくても TUI を出したいときは `--interactive` を付ける。

- 走査の除外は `-i` / `--ignore-dirs`（既定で `/proc,/dev,/sys,/run`）と `-x` / `--no-cross`（ファイルシステムを跨がない）
- 設定ファイルは `~/.gdu.yaml`（`--config-file` で変えられる）で、既定では作られない

### gdu の名前で呼ぶ（任意） / 手順 0: 本文中の記録

- この節はコンテナでエイリアスを検証した。シンボリックリンクは、[homebrew.md の付録](homebrew.md#付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)で、張ると `gdu` で動き、`sudo gdu` では見つからないことだけ確かめた（[未確認事項](#未確認事項)）

### ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**



- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

### 対象と検証環境

- **目的**: AlmaLinux 10 に [gdu](https://github.com/dundee/gdu)（ディスク使用量を見る TUI。`ncdu` と同じ用途で、並列処理で速い）を入れる
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **`0dbb522` の直接追記版の実施手順 1・2 を x86_64 のクリーン VM で本実行済み（2026-10-06）。コンテナでも通し検証済み（2026-09-22）**。現行版 `5da3478` は、共通 bash 新規導入後の別の VM でも再検証した（末尾の再検証記録）。既存ホストの手動移行は行っていない。
  - ただし**実機には本書と同じ経路のもの（`brew install gdu` による `gdu 5.37.0`）が 2026-09-21 から入っている**
    - [yazi](../yazi.md) 周辺のツールをまとめて入れた流れで導入したもので、**本書の手順を順に実行した結果ではない**
    - 実機で使えるコマンドは `gdu-go` だけで `gdu` は存在せず、[エイリアス](../gdu.md#gdu-の名前で呼ぶ任意)も実機には入れていない
  - コンテナでは、[Homebrew の導入](../homebrew.md)と手順 1〜2、[エイリアス](../gdu.md#gdu-の名前で呼ぶ任意)を通した
  - 確認したこと: `arm64_linux` のボトルが降りる、`gdu-go --version` が `v5.37.0` を返す、`gdu-go -n` の非対話モードが走る
  - TUI の起動・一覧の表示・`q` での終了は、2026-10-06 のクリーン VM で確認した。**確認していないこと**: EPEL 版（5.32.0）との併用、シンボリックリンク方式（張ると `gdu` で動き、`sudo gdu` では見つからないことだけ、[homebrew.md の付録](homebrew.md#付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)で確かめた）

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-21（本書とは別経緯で導入） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| gdu | `gdu 5.37.0`（Homebrew）。コマンドは `gdu-go` のみ | 同じ（`5.37.0`） |
| エイリアス / リンク | **未設定**（`command -v gdu` は何も返さない） | 手順どおり `alias gdu=gdu-go` を設定 |
| EPEL 版の `gdu` | 未導入（EPEL は有効なので入手はできる） | 未導入 |
| 端末 | WezTerm nightly（[wezterm-nightly.md](../wezterm-nightly.md)） | 無し（pty を与えずに実行） |

> [!NOTE]
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`5.37.0`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| gdu | **Homebrew 版 5.37.0 が導入済み**（2026-09-21、`gdu-go` として）。EPEL の `gdu` は未導入 |
| Homebrew | 7.0.6 導入済み |
| EPEL | 有効。`gdu 5.32.0-1.el10_2` が入手できる状態 |
| `ncdu` | 未導入（EPEL に `1.22-1.el10_1` がある） |
| `du` | `coreutils` の GNU `du`（RPM） |

### 選択した方針

AlmaLinux 10 aarch64 で gdu を入れる経路を比べた（2026-09-22 時点）:

コンテナで取った EPEL 側の実測:

### 完了時点の状態

**検証コンテナでの出力**（実機は別経緯で同じ版が入っている状態）:

```
$ gdu-go --version
Version:	 v5.37.0
Built time:	 2026-08-18 00:47:38 UTC
Built user:	 linuxbrew
$ brew list --versions gdu
gdu 5.37.0
$ command -v gdu-go
/home/linuxbrew/.linuxbrew/bin/gdu-go
$ command -v gdu
$ alias gdu
alias gdu='gdu-go'
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/gdu/5.37.0/`（7 ファイル、20.6 MB。うち `bin/gdu-go` が 20.5 MB の静的バイナリ）。

実機でも同じく `command -v gdu` は何も返さず、`command -v gdu-go` だけが `/home/linuxbrew/.linuxbrew/bin/gdu-go` を返す（エイリアスは入れていない）。

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](../homebrew.md)と手順 1〜2、[gdu の名前で呼ぶ（任意）](../gdu.md#gdu-の名前で呼ぶ任意)のエイリアス部分を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](../homebrew.md)） |
| 1. gdu | `Pouring gdu--5.37.0.arm64_linux.bottle.tar.gz` → `7 files, 20.6MB`。**依存は 0**（`brew deps --tree gdu` の出力が `gdu` の 1 行だけ）。caveat が本文に引用したとおり出た |
| 2. 検証 | `gdu-go --version` → `v5.37.0`（ビルドは 2026-08-18、`Built user: linuxbrew`）。`command -v gdu` は空。`gdu-go -n /usr/share` でサイズ順の一覧が出た |
| エイリアス | `~/.bashrc` に `alias gdu=gdu-go` を追記して読み込み直し、`alias gdu` で展開を確認。**`type -t gdu` は非対話シェルでは失敗する**ことも確認した（`bash -i` 越しなら `alias` を返す） |
| RPM 経路 | `dnf -q list --showduplicates gdu` → `5.32.0-1.el10_2 epel`。`dnf -q repoquery -l gdu \| grep bin/` → `/usr/bin/gdu` |

実機側では `brew list --versions gdu` が `gdu 5.37.0` を返し、`/home/linuxbrew/.linuxbrew/bin/` に `gdu-go` だけがあり（`Cellar/gdu/5.37.0` の作成は 2026-09-21 09:41）、`command -v gdu` は何も返さないことを確認した。

#### 未確認事項

- 実機での本実行（実機の 5.37.0 は本書とは別経緯で入ったもの）
- TUI の追加操作（`d` の削除、`--mouse`、終了以外のキーバインド）
- シンボリックリンク方式（`~/.local/bin/gdu`）
- EPEL 版（5.32.0）を併用したときの `gdu` / `gdu-go` の使い分け
- `~/.gdu.yaml` による設定
- `-D` / `--db`（解析結果の保存）や `--archive-browsing` などの追加機能
- Raspberry Pi の microSD で `/` 全体を走査したときの所要時間
- ロールバック（`brew uninstall` と `~/.bashrc` の行削除）の本実行

---

### 付録: クリーン VM での検証記録（2026-10-06）

**検証対象**: `0dbb522` の、各手順で `~/.bashrc` などへ設定を直接追記する版。以下の手順番号と「本文」はこの版を指す。検証後に共通 bash 設定へ統一された現行版（`0bc9970`）の設定リポジトリの新規導入・既存設定からの移行は、今回の VM では実行していない。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証対象版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順（`0dbb522`）**: 実施手順 1・2と、追加の TUI 起動。

**結果**: Homebrew の gdu 5.38.0 が `gdu-go` として入った。`gdu` は無いという本文の確認が通り、`/var/lib` の非対話一覧を表示した。追加で検証用ディレクトリを TUI で開き、一覧を読んで `q` で終了した。

**今回の未確認範囲**: エイリアス・削除操作、更新・ロールバックは今回流していない。

### 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1・2 と「gdu の名前で呼ぶ」手順 1 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で実行した。共通 bash `3d5323e` は先に導入した
- Homebrew から gdu 5.38.0 の bottle が入り、`gdu-go` の版・PATH・パッケージ登録と `/usr/lib` の非対話走査を確認した。共通設定を読み直すと `gdu='gdu-go'` が定義された
- 共通設定の `gdu` エイリアスから専用ディレクトリを実 TUI で開いた。`wg-vpn.sh` の一覧・使用量・合計が出て、`q` で終了値 0 に戻った
- 更新、削除操作、既存の直接追記設定からの手動移行は、この再検証では行っていない


### 実施手順 / 手順 1: 補足: ボトルと、gdu-go になる理由

**出力例**（`brew install` の最後に出る caveat）:

```
==> Caveats
To avoid a conflict with `coreutils`, `gdu` has been installed as `gdu-go`.
```

aarch64 で降ってくるボトルは `gdu--5.37.0.arm64_linux.bottle.tar.gz`。

GNU coreutils には `gdu` という名前のコマンドがある（macOS などで GNU 版 `du` を `g` 付きで入れるときの名前）。Homebrew の `coreutils` formula がこれを置くため、**衝突を避けて gdu 側の名前を変えている**。`brew info gdu` の実出力:

```
==> gdu: stable 5.37.0 (bottled), HEAD
Disk usage analyzer with console interface written in Go
https://github.com/dundee/gdu
==> Caveats
To avoid a conflict with `coreutils`, `gdu` has been installed as `gdu-go`.
```

AlmaLinux の RPM の `coreutils` は `gdu` を置かないので、**この環境では実際には衝突しない**。それでも formula は macOS と共通なので名前は変わる。`bin` に張られるリンクも 1 本だけ:

```
$ ls -l /home/linuxbrew/.linuxbrew/bin/gdu*
lrwxrwxrwx. 1 <USER> <USER> 31 Sep 21 09:41 /home/linuxbrew/.linuxbrew/bin/gdu-go -> ../Cellar/gdu/5.37.0/bin/gdu-go
```



### 選択した方針

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `gdu 5.37.0` の `arm64_linux` ボトルがある。upstream の最新と一致。**ただし入るコマンドは `gdu-go`**（formula 側の都合。[手順 1 の補足](../gdu.md#実施手順)） | **採用**（実機もこの経路） |
| EPEL の `gdu` | `gdu.aarch64 5.32.0-1.el10_2`。コマンド名は素直に `/usr/bin/gdu` で、dnf 管理なので root でも使えて `dnf upgrade` に乗る。ただし **5 マイナー古い** | 不採用。**名前を優先するならこちら** |
| GitHub Releases のバイナリ | `linux-arm64` の tar がある。展開して PATH に置くだけで名前も自由だが、更新は手作業 | 不採用（Homebrew に揃える） |
| `go install github.com/dundee/gdu/...` | Go toolchain が要る（AppStream に `golang` あり） | 不採用 |
| `ncdu` で代用 | EPEL に `1.22-1.el10_1` がある。用途は同じだがシングルスレッドで、大きな木では gdu より遅い | 対象外（併用できる） |

```
$ dnf -q list --showduplicates gdu
Available Packages
gdu.aarch64                        5.32.0-1.el10_2                          epel
$ dnf -q repoquery -l gdu | grep bin/
/usr/bin/gdu
```

