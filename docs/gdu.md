# gdu インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew は root で動かず、エイリアスも自分の `~/.bashrc` に書くため）

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: `gdu` という名前で呼びたいなら[gdu の名前で呼ぶ（任意）](#gdu-の名前で呼ぶ任意)。以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **コンテナでのみ通し検証した手順書**で、実機では本書の手順を順に実行していない。実機にある同じ Homebrew 版（5.37.0）は、2026-09-21 に本書とは別の経緯で入れたもの（[対象と検証環境](#対象と検証環境)）。

1. brew で gdu を入れる。

   ```bash
   brew install gdu
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - 依存は無い（Go の静的バイナリ 1 つ、約 20 MB）
   - **入るコマンドは `gdu` ではなく `gdu-go`**
   - `brew install` の最後に ``To avoid a conflict with `coreutils`, `gdu` has been installed as `gdu-go`.`` という caveat が出る（出力例はこの手順の補足）

   <details>
   <summary>補足: ボトルと、<code>gdu-go</code> になる理由</summary>

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

   </details>

1. `gdu-go` が入ったことと、TUI を起動せずに走査できることを確かめる。

   ```bash
   gdu-go --version
   brew list --versions gdu
   command -v gdu-go
   command -v gdu || echo 'gdu という名前のコマンドは無い'
   gdu-go -n /usr/share | tail -5
   ```

   - `Version: v5.37.0` と出る
   - `command -v gdu` の行は `gdu という名前のコマンドは無い` になる。[gdu の名前で呼ぶ（任意）](#gdu-の名前で呼ぶ任意)をやるまでは、これが正しい状態
   - 最後の `gdu-go -n` では、サイズの大きい順に並んだ一覧が出る
   - **TUI で使うときは引数にディレクトリを渡すだけ**（`gdu-go ~` など。`q` で終了）

   <details>
   <summary>補足: 非対話モード</summary>

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

   </details>

---

## gdu の名前で呼ぶ（任意）

- この節はコンテナでエイリアスのみ検証しており、シンボリックリンクは未検証（[未確認事項](#未確認事項)）

1. `~/.bashrc` に、`gdu-go` のエイリアスを足す。

   ```bash
   echo 'alias gdu=gdu-go' >> ~/.bashrc
   . ~/.bashrc
   alias gdu
   ```

   - `alias gdu='gdu-go'` と出れば入っている
   - **`alias` の確認に `type -t` は使えない**（[注意点](#注意点)を参照）
   - **エイリアスが効くのは対話シェルだけ**。スクリプト、`sudo`、他のツールからの呼び出しでは `gdu-go` のままになる

1. スクリプト・`sudo`・他のツールからも `gdu` で呼びたいときだけ、シンボリックリンクにする。

   ```bash
   mkdir -p ~/.local/bin && ln -sfn /home/linuxbrew/.linuxbrew/bin/gdu-go ~/.local/bin/gdu
   ```

   - `~/.local/bin` は AlmaLinux の既定の `~/.bashrc` で PATH に入っている
   - リンク先を Cellar ではなく `/home/linuxbrew/.linuxbrew/bin` にしてあるので、`brew upgrade` で版が上がってもリンクは張り直さなくてよい
   - ただし **PATH の順序では Homebrew のほうが先**なので、EPEL 版の `/usr/bin/gdu` を同時に入れている場合はどちらが呼ばれるか変わる（[注意点](#注意点)）

---

## 更新

1. brew で gdu を更新する。

   ```bash
   brew upgrade gdu
   ```

   - すべてまとめて上げるなら `brew upgrade`

---

## ロールバック

- 本書ではロールバックは**本実行していない**

1. brew で gdu を消す。

   ```bash
   brew uninstall gdu
   ```

1. エイリアスを足していたときだけ、`~/.bashrc` からその行を消す。

   ```bash
   sed -i '/alias .*=gdu-go/d' ~/.bashrc     # エイリアスを足していた場合
   ```

1. シンボリックリンクを作っていたときだけ、`~/.local/bin/gdu` を消す。

   ```bash
   rm -f ~/.local/bin/gdu                    # シンボリックリンクを作っていた場合
   ```

1. 設定ファイルを作っていたときだけ、`~/.gdu.yaml` を消す。

   ```bash
   rm -f ~/.gdu.yaml                         # 設定ファイルを作っていた場合
   ```

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [gdu](https://github.com/dundee/gdu)（ディスク使用量を見る TUI。`ncdu` と同じ用途で、並列処理で速い）を入れる
- **進め方**: Homebrew で入れる。**実行ファイル名が `gdu-go` になる**のが唯一の引っかかりどころ。**読者が書き換える変数は無い**
- **状態**: **コンテナでのみ通し検証済み（2026-09-22）**
  - ただし**実機には本書と同じ経路のもの（`brew install gdu` による `gdu 5.37.0`）が 2026-09-21 から入っている**
    - [yazi](yazi.md) 周辺のツールをまとめて入れた流れで導入したもので、**本書の手順を順に実行した結果ではない**
    - 実機で使えるコマンドは `gdu-go` だけで `gdu` は存在せず、[エイリアス](#gdu-の名前で呼ぶ任意)も実機には入れていない
  - コンテナでは、[Homebrew の導入](homebrew.md)と手順 1〜2、[エイリアス](#gdu-の名前で呼ぶ任意)を通した
  - 確認したこと: `arm64_linux` のボトルが降りる、`gdu-go --version` が `v5.37.0` を返す、`gdu-go -n` の非対話モードが走る
  - **確認していないこと**: TUI の起動、EPEL 版（5.32.0）との併用、シンボリックリンク方式

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-21（本書とは別経緯で導入） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| gdu | `gdu 5.37.0`（Homebrew）。コマンドは `gdu-go` のみ | 同じ（`5.37.0`） |
| エイリアス / リンク | **未設定**（`command -v gdu` は何も返さない） | 手順どおり `alias gdu=gdu-go` を設定 |
| EPEL 版の `gdu` | 未導入（EPEL は有効なので入手はできる） | 未導入 |
| 端末 | WezTerm nightly（[wezterm-nightly.md](wezterm-nightly.md)） | 無し（pty を与えずに実行） |

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

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `gdu 5.37.0` の `arm64_linux` ボトルがある。upstream の最新と一致。**ただし入るコマンドは `gdu-go`**（formula 側の都合。[手順 1 の補足](#実施手順)） | **採用**（実機もこの経路） |
| EPEL の `gdu` | `gdu.aarch64 5.32.0-1.el10_2`。コマンド名は素直に `/usr/bin/gdu` で、dnf 管理なので root でも使えて `dnf upgrade` に乗る。ただし **5 マイナー古い** | 不採用。**名前を優先するならこちら** |
| GitHub Releases のバイナリ | `linux-arm64` の tar がある。展開して PATH に置くだけで名前も自由だが、更新は手作業 | 不採用（Homebrew に揃える） |
| `go install github.com/dundee/gdu/...` | Go toolchain が要る（AppStream に `golang` あり） | 不採用 |
| `ncdu` で代用 | EPEL に `1.22-1.el10_1` がある。用途は同じだがシングルスレッドで、大きな木では gdu より遅い | 対象外（併用できる） |

コンテナで取った EPEL 側の実測:

```
$ dnf -q list --showduplicates gdu
Available Packages
gdu.aarch64                        5.32.0-1.el10_2                          epel
$ dnf -q repoquery -l gdu | grep bin/
/usr/bin/gdu
```

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

### 注意点

- **コマンド名が `gdu-go`**: これが最大の引っかかりどころ。`gdu` と打って `command not found` になったら、まず `command -v gdu-go` を見る
- **エイリアスの確認に `type -t` は使えない**: bash は非対話シェルでエイリアスを展開しないため、`type -t gdu` はエイリアスを見つけられない（`alias gdu` なら確認できる）
  - 関数を定義する [zoxide](zoxide.md) / [yazi](yazi.md) の `y()` は、この制約を受けない
- **EPEL 版と同時に入れると版が 2 つ並ぶ**: 名前が違う（`/usr/bin/gdu` と `gdu-go`）ので上書きされず、**共存してしまう**
  - `gdu` と打つと EPEL の 5.32.0、`gdu-go` と打つと Homebrew の 5.37.0 という状態になる
  - どちらか片方にする
- **エイリアスは対話シェルだけ**: スクリプトや `sudo` からは `gdu-go`。全部で揃えたいならシンボリックリンク
- **走査は I/O が重い**: Raspberry Pi の microSD で `/` 全体を走らせると時間がかかる。`-x`（ファイルシステムを跨がない）や対象ディレクトリの限定を併用する
- **TUI からファイルを消せる**: `d` で削除できるので、root 権限で起動するときは特に注意する（`sudo gdu-go` は PATH に Homebrew が無いので、フルパスが要る。[homebrew.md の注意点](homebrew.md#注意点)）

### 参照

- [dundee/gdu — README](https://github.com/dundee/gdu) — 使い方、キーバインド、各ディストリビューションでの入手方法
- [gdu — Configuration](https://github.com/dundee/gdu/blob/master/docs/configuration.md) — `~/.gdu.yaml` の項目
- `gdu-go --help` — 全フラグ（非対話モード、除外、データベース出力など）
- [Homebrew の gdu formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/g/gdu.rb) — `gdu-go` にリネームしている箇所
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](homebrew.md)と手順 1〜2、[gdu の名前で呼ぶ（任意）](#gdu-の名前で呼ぶ任意)のエイリアス部分を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](homebrew.md)） |
| 1. gdu | `Pouring gdu--5.37.0.arm64_linux.bottle.tar.gz` → `7 files, 20.6MB`。**依存は 0**（`brew deps --tree gdu` の出力が `gdu` の 1 行だけ）。caveat が本文に引用したとおり出た |
| 2. 検証 | `gdu-go --version` → `v5.37.0`（ビルドは 2026-08-18、`Built user: linuxbrew`）。`command -v gdu` は空。`gdu-go -n /usr/share` でサイズ順の一覧が出た |
| エイリアス | `~/.bashrc` に `alias gdu=gdu-go` を追記して読み込み直し、`alias gdu` で展開を確認。**`type -t gdu` は非対話シェルでは失敗する**ことも確認した（`bash -i` 越しなら `alias` を返す） |
| RPM 経路 | `dnf -q list --showduplicates gdu` → `5.32.0-1.el10_2 epel`。`dnf -q repoquery -l gdu \| grep bin/` → `/usr/bin/gdu` |

実機側では `brew list --versions gdu` が `gdu 5.37.0` を返し、`/home/linuxbrew/.linuxbrew/bin/` に `gdu-go` だけがあり（`Cellar/gdu/5.37.0` の作成は 2026-09-21 09:41）、`command -v gdu` は何も返さないことを確認した。

#### 未確認事項

- 実機での本実行（実機の 5.37.0 は本書とは別経緯で入ったもの。検証はコンテナのみ）
- TUI の起動と操作（`d` の削除、`--mouse`、キーバインド）
- シンボリックリンク方式（`~/.local/bin/gdu`）
- EPEL 版（5.32.0）を併用したときの `gdu` / `gdu-go` の使い分け
- `~/.gdu.yaml` による設定
- `-D` / `--db`（解析結果の保存）や `--archive-browsing` などの追加機能
- Raspberry Pi の microSD で `/` 全体を走査したときの所要時間
- ロールバック（`brew uninstall` と `~/.bashrc` の行削除）の本実行
