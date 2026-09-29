# Homebrew インストール手順（AlmaLinux 10）

## 実施手順

> [!IMPORTANT]
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew は root で動かない）
> - **実行するユーザーは `sudo` できる必要がある**（手順 1・2 で使う）
> - **手順 2 には対話入力がある**（インストーラの `RETURN` の確認と `sudo` のパスワード）。終わってから手順 3 を貼る
> - **インターネットに出られないホストでは、本書を直接貼らず [homebrew-offline.md](homebrew-offline.md) から通す**（ssh でログインしてくるホストをプロキシにして、そのシェルで本書の手順 1〜4 を貼る）

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 日々の操作は[使い方の基本](#使い方の基本)。以後は[更新](#更新)・[ロールバック](#ロールバック)
- 通すと使えるようになる 15 本:
  - [yazi](yazi.md)、[lazygit](lazygit.md)、[Neovim](neovim.md)、[zoxide](zoxide.md)、[bat](bat.md)、[eza](eza.md)、[git-delta](git-delta.md)、[gdu](gdu.md)、[starship](starship.md)、[ShellCheck / shfmt](shellcheck.md)
  - [Syncthing](syncthing.md)、[HackGen Console NF](hackgen.md)、[Dropbox（rclone）](dropbox-rclone.md)、[hadolint / dive / Trivy](image-tools.md)（Trivy だけは dnf）、[lazydocker](lazydocker.md)

1. 依存パッケージを入れる。

   ```bash
   sudo dnf install -y procps-ng curl file git
   ```

   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 依存パッケージの役割</summary>

   | パッケージ | 用途 |
   |---|---|
   | `curl` | インストーラ自身と、ボトル・formula の取得 |
   | `git` | `brew update` が Homebrew 本体と formula の索引を git で更新するため |
   | `file` | インストーラと `brew` がバイナリの種別を判定するため |
   | `procps-ng` | `pgrep` など。インストーラの事前チェックで使う |

   コンテナでの実測では、`curl` は導入済みで `file` / `git` / `procps-ng` の 3 つが新規、依存を含めて 30 個ほどが入った（`git-core` / `openssh-clients` / `perl-*` など）。実機は最初から git が入っていた。

   **`development-tools` グループは要らない。** インストーラの `Next steps` が勧めてくるが、あれは**ソースビルドをする場合**のもので、ボトルだけ使うなら入れなくてよい（手順 2 の補足）。

   </details>

1. 公式のインストーラを実行する。

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

   - インストーラは続行の確認で `RETURN` を求め、途中でも `sudo` のパスワードを聞く（`/home/linuxbrew` を作るため）
   - 終わりに `==> Installation successful!` と、PATH の通し方を書いた `==> Next steps:` が出る
   - 手順 3 は、その案内と同じ内容（この手順の補足に実測を載せた）
   - **次の手順は、インストーラが終わってから貼る**（続けて貼ると `RETURN` の確認や `sudo` のパスワードとして食われる）

   <details>
   <summary>補足: 導入先を変えてはいけない</summary>

   Homebrew の Linux 版がビルド済みのボトルを配っているのは **`/home/linuxbrew/.linuxbrew` に入っている場合だけ**。別の場所（`~/.homebrew` など）に入れると、`brew install` のたびに**すべてソースからビルドされる**。Raspberry Pi でこれをやると 1 つ入れるのに数十分かかる。

   インストーラは `sudo` で `/home/linuxbrew` を作り、実行したユーザーの所有にする。したがって **root で実行してはいけないが、`sudo` できるユーザーである必要がある**。

   コンテナでの実測（`NONINTERACTIVE=1` 付き。末尾の案内が本書の手順 3 の中身）:

   ```
   ==> Pouring portable-ruby-4.0.7.arm64_linux.bottle.tar.gz
   Warning: /home/linuxbrew/.linuxbrew/bin is not in your PATH.
     Instructions on how to configure your shell for Homebrew
     can be found in the 'Next steps' section below.
   ==> Installation successful!
   ...
   ==> Next steps:
   - Run these commands in your terminal to add Homebrew to your PATH:
       echo >> /home/<USER>/.bashrc
       echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"' >> /home/<USER>/.bashrc
       eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
   - Install Homebrew's dependencies if you have sudo access:
       sudo dnf group install development-tools
     For more information, see:
       https://docs.brew.sh/Homebrew-on-Linux
   - Run brew help to get started
   - Further documentation:
       https://docs.brew.sh
   ```

   Homebrew は自前の Ruby（`portable-ruby`）を持ってくるので、システムの Ruby は要らない。

   `NONINTERACTIVE=1` を付けると `RETURN` の確認を飛ばす。**スクリプトやコンテナから流すとき専用**で、手で入れるときは付けない（本書の検証でだけ使っている）。

   </details>

1. `~/.bashrc` に 1 行書いて、`brew` を PATH に入れる。

   ```bash
   echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"' >> ~/.bashrc
   eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
   brew --version
   ```

   - `Homebrew 7.0.6` のように出れば通っている
   - 1 行目で `~/.bashrc` に書き、2 行目で今のシェルにも即時に反映している

   <details>
   <summary>補足: <code>~/.bashrc</code> に書く 1 行</summary>

   `brew shellenv` は `PATH` / `MANPATH` / `INFOPATH` / `HOMEBREW_PREFIX` などの `export` 文を標準出力に吐くだけのコマンドで、`eval` しなければ何も起こらない。**`~/.bashrc` に書くのは 1 行だけ**で、実体はその都度生成される。

   `echo '...' >> ~/.bashrc` を**シングルクォート**にしてあるのは、`$(...)` をここで展開させず、**文字列のまま**書き込むため。ダブルクォートにすると、貼った時点の `brew shellenv` の出力がベタ書きされてしまい、導入先を変えたときに追従しない。

   **引数の `bash` は省略できる。** 実機の `~/.bashrc:26` は引数なしで書かれていて、本書（インストーラの案内どおり `bash` 付き）と違う:

   ```
   $ grep -n 'brew shellenv' ~/.bashrc
   26:eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
   ```

   引数なしだと `brew` が親プロセスからシェルを推測する。bash を使っている限り結果は同じなので実機はそのままにしてある。**明示したほうが確実**なので、本書はインストーラの案内どおり `bash` 付きで書いている。

   この 1 行を `~/.bashrc` の**どこに置くか**は問わない（`PATH` を触るだけで `PROMPT_COMMAND` には触らない）。[zoxide](zoxide.md) や [starship](starship.md) の初期化とは違って、順序の制約は無い。

   </details>

1. Homebrew が入ったか確かめる。

   ```bash
   brew --version
   command -v brew
   ls -d /home/linuxbrew/.linuxbrew
   brew config | head -12
   ```

   - `command -v brew` が `/home/linuxbrew/.linuxbrew/bin/brew` を返す
   - `brew config` の `HOMEBREW_PREFIX` が `/home/linuxbrew/.linuxbrew` ならよい

   <details>
   <summary>補足: <code>brew config</code> の読み方</summary>

   コンテナでの実測:

   ```
   $ brew config | head -12
   HOMEBREW_VERSION: 7.0.6
   ORIGIN: https://github.com/Homebrew/brew
   HEAD: 570982948a8a194f0f42f43f4a5bce2d1c9f64cb
   Last commit: 29 hours ago
   Branch: stable
   Core tap: N/A
   Core cask tap: N/A
   HOMEBREW_PREFIX: /home/linuxbrew/.linuxbrew
   Homebrew Ruby: 4.0.7 => /home/linuxbrew/.linuxbrew/Homebrew/Library/Homebrew/vendor/portable-ruby/4.0.7/bin/ruby
   CPU: quad-core 64-bit arm
   Clang: N/A
   Git: 2.52.0 => /bin/git
   ```

   見るところは 3 つ:

   - **`HOMEBREW_PREFIX` が `/home/linuxbrew/.linuxbrew`**（ここが違うとボトルが使えない）
   - **`Branch: stable`**
   - **`CPU` が `arm`**（`arm64_linux` のボトルが降りる）

   `Core tap: N/A` と `Clang: N/A` は異常ではない（formula は API 経由で取得し、ボトルだけ使うならコンパイラは要らない）。

   パスだけ知りたいときは `brew --prefix` / `brew --cellar` / `brew --repository`。

   </details>

---

## 使い方の基本

各手順書が使うコマンドはこれだけ。

| コマンド | 用途 |
|---|---|
| `brew install <formula>` | 入れる。ビルド済みのボトルがあれば `Pouring ...` と出て、ソースビルドは走らない |
| `brew uninstall <formula>` | 消す。依存は残る |
| `brew list --versions` | 入っているものと版の一覧 |
| `brew leaves` | **自分で明示的に入れたものだけ**の一覧（依存として入ったものを除く） |
| `brew info <formula>` | 版・依存・caveat（[gdu](gdu.md) のような名前の注意書き） |
| `brew deps --tree <formula>` | 依存の木。単独で入れたときに何が付いてくるか |
| `brew outdated` | 更新できるものの一覧。何も無ければ無出力 |
| `brew autoremove` | 依存として入って、もう誰も使っていないものを消す（`--dry-run` で確認できる） |

`brew` はどれも **root では動かない**。`sudo brew ...` は明示的に拒否される。

---

## 更新

- Homebrew 自身と formula の索引を更新してから、入れたものを上げる
- インターネットに出られないホストでは、[homebrew-offline.md の更新](homebrew-offline.md#更新)で行う

1. Homebrew 自身と formula の索引を更新し、上げられるものを見る。

   ```bash
   brew update
   brew outdated
   ```

   - `brew update` が `Already up-to-date.` を返し、`brew outdated` が無出力なら、上げるものは無いので、この節の手順 2 は飛ばす
   - **`brew install` / `brew upgrade` は既定で自動更新が走る**ので、普段は `brew update` を明示しなくてよい（抑えるには `HOMEBREW_NO_AUTO_UPDATE=1`）

1. 上げるものがあるときだけ、入れたものを上げる。

   ```bash
   brew upgrade
   ```

   - 特定のものだけなら `brew upgrade <formula>`

---

## ロールバック

- 本書ではロールバックは**本実行していない**（`--help` でオプションを確かめただけ。[付録](#付録-コンテナでの検証記録2026-09-22)）
- 各ツールが `~/.bashrc` や `~/.config` に書いた設定は残る。それぞれの手順書のロールバックも見る
- インターネットに出られないホストでは、[homebrew-offline.md 手順 1〜3](homebrew-offline.md#実施手順) でトンネルを張ったシェルで貼る（この節の手順 1 がアンインストーラを取得する）

> [!CAUTION]
> **この節の手順 2 で本実行すると、Homebrew で入れたものが全部消える。** [yazi](yazi.md) / [lazygit](lazygit.md) / [Neovim](neovim.md) / [zoxide](zoxide.md) 以下、`brew leaves` に出るものはすべて使えなくなる。

1. 本実行の前に、何が消えるか見る。

   ```bash
   brew leaves
   brew list --versions | wc -l
   curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh -o /tmp/uninstall.sh
   bash /tmp/uninstall.sh --dry-run
   ```

   - 公式のアンインストーラを `/tmp/uninstall.sh` に落として、**まず `--dry-run` で何が消えるか見る**
   - **次の手順は、内容を確かめてから貼る**

1. アンインストーラを本実行する（取り戻せない）。

   ```bash
   bash /tmp/uninstall.sh
   ```

   - `sudo` のパスワードと確認を聞かれる
   - `/home/linuxbrew` 自体は `uninstall.sh` が消す（`--path` で変えられる）
   - **次の手順は、アンインストーラが終わってから貼る**（続けて貼ると確認や `sudo` のパスワードとして食われる）

1. 終わったら、`~/.bashrc` の行とアンインストーラを消す。

   ```bash
   sed -i '/brew shellenv/d' ~/.bashrc
   rm -f /tmp/uninstall.sh
   ```

   - **`~/.bashrc` の行を消し忘れると、新しいシェルを開くたびにエラーが出る**

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [Homebrew](https://brew.sh/)（Linux 版。旧称 Linuxbrew）を入れて、**EPEL や AppStream に無い／古い CLI ツールを root 権限なしで新しい版のまま使える**ようにする
- **進め方**: 公式インストーラで `/home/linuxbrew/.linuxbrew` に入れ、`~/.bashrc` に 1 行足す。**読者が書き換える値は無い**
- **状態**: **実機で本実行済み（2026-09-20）**
  - 下表のホストに公式インストーラで `Homebrew 7.0.6` を入れ、`~/.bashrc` に `brew shellenv` を書いて常用中
  - **このリポジトリの Homebrew 系 15 本の手順書は、すべてこれを前提にしている**（実機に入っているのはそのうちの一部で、記録時点の `brew leaves` は 15 件。下表）
  - 本書の手順 1〜4 と[使い方の基本](#使い方の基本)・[更新](#更新)は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - 確認したこと: `Homebrew 7.0.6` が同じ場所に入る、`brew config` の `HOMEBREW_PREFIX` が一致する、`brew install jq` がボトルで入る
  - **本実行していないこと**: ロールバック（`uninstall.sh` の本実行）。実機でもコンテナでも実行していない（`--help` を見ただけ）
  - **実機の `~/.bashrc` の 1 行は `brew shellenv`（引数なし）で、本書が書く `brew shellenv bash` と違う**（[手順 3 の補足](#実施手順)）

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | `7.0.6`（`/home/linuxbrew/.linuxbrew`、`Branch: stable`） | 同じ（`7.0.6`、同じ場所に新規導入） |
| `~/.bashrc` の行 | `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"`（**引数なし**） | `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"`（本書どおり） |
| 入れたもの | `brew leaves` が 15 件（`fd` / `ffmpeg-full` / `fzf` / `gdu` / `imagemagick-full` / `jq` / `lazygit` / `neovim` / `poppler` / `resvg` / `ripgrep` / `sevenzip` / `tree-sitter-cli` / `yazi` / `zoxide`）。その後 2026-09-23 に [ShellCheck / shfmt](shellcheck.md) を足して 17 件 | `jq` 1 件のみ（動作確認用） |
| 占有サイズ | 2.8 GB | 216 MB |
| git | RPM の `git 2.52.0`（`/bin/git`） | 同じ |

> [!NOTE]
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`7.0.6`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| Homebrew | 未導入（`command -v brew` が何も返さず、`/home/linuxbrew` も無い） |
| git | RPM の `git 2.52.0` が導入済み |
| EPEL | 有効（`epel-release 10-8.el10_2`） |
| `~/.bashrc` | AlmaLinux の既定のまま |

### 選択した方針

AlmaLinux 10 aarch64 で「EPEL / AppStream に無い、または古い CLI ツール」を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `arm64_linux` のボトルが揃っていて**ソースビルドが要らない**。root 権限なしで upstream の最新版を追え、1 つの `brew upgrade` でまとめて上がる。占有は大きい（実機で 2.8 GB） | **採用** |
| EPEL / AppStream / CRB の RPM | root 権限で `dnf` に乗るのが利点。ただし目的のツールが**無い**（`eza` / `git-delta` / `starship` / `zoxide`）か、**古い**（`bat 0.24.0` / `neovim 0.10.1` / `fzf 0.58.0`）ことが多い。同版なら RPM を選ぶ（手順書では [btop.md](btop.md) と、[image-tools.md](image-tools.md) の Trivy が例。[ツール一覧](tool-catalog.md)の fastfetch などもこの規則で RPM にした） | 併用（無い・古いときだけ Homebrew） |
| COPR | EL10 向けの chroot があるとは限らず、`epel-10-aarch64` の repomd が 403 になる例を実測している（[lazygit.md](lazygit.md)）。EL9 向けを流用した例は [wezterm-nightly.md](wezterm-nightly.md) | 不採用（ツールごとに当たり外れが大きい） |
| 各ツールの公式インストーラ / GitHub Releases | バイナリ 1 つで軽いが、**ツールごとに更新方法が違う**。15 本ぶん覚えることになる | 不採用（Homebrew に揃える） |
| `cargo install` / `go install` | toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

**Homebrew に揃える判断の実質は「更新の一元化」**。`brew upgrade` 1 本で、15 本の手順書で Homebrew から入れたものがまとめて上がる。

### 完了時点の状態

**検証コンテナでの出力**（動作確認に `jq` を 1 つだけ入れた状態）:

```
$ brew --version
Homebrew 7.0.6
$ command -v brew
/home/linuxbrew/.linuxbrew/bin/brew
$ brew list --versions
jq 1.8.2
oniguruma 6.9.10
$ brew leaves
jq
$ brew deps --tree jq
jq
└── oniguruma
$ grep -n 'brew shellenv' ~/.bashrc
26:eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
$ du -sh /home/linuxbrew/.linuxbrew
216M	/home/linuxbrew/.linuxbrew
```

実機は同じ `7.0.6` で、`brew leaves` が 15 件、占有は 2.8 GB（`ffmpeg-full` と `imagemagick-full` が大きい）。

### 注意点

- **root で実行しない**: インストーラも `brew` も root を拒否する。ただし**実行するユーザーが `sudo` できる必要がある**（`/home/linuxbrew` を作るため）
- **導入先を変えるとすべてソースビルドになる**: [手順 2 の補足](#実施手順)
- **PATH の先頭が Homebrew になる**: `brew shellenv` は `/home/linuxbrew/.linuxbrew/bin` を `PATH` の**先頭**に足す。同じ名前の RPM が入っていると Homebrew 版が勝つ（[bat](bat.md) / [gdu](gdu.md) で実際に問題になる）
- **`sudo <tool>` が使えない**: root の `PATH` に Homebrew は入っていない。root でも使いたいものは RPM で入れるか、フルパス（`/home/linuxbrew/.linuxbrew/bin/<tool>`）を渡す
- **`~/.bashrc` を読まない文脈では見えない**: cron や一部の非対話シェルでは `brew shellenv` が走らないので、Homebrew で入れたコマンドが見つからない。スクリプトからはフルパスで呼ぶ
- **ユーザーごとではなく、ホストに 1 つ**: `/home/linuxbrew` は共有なので、別ユーザーが使うにはそのユーザーの `~/.bashrc` にも `brew shellenv` を書く（書き込みには所有者の権限が要る）
- **占有が大きい**: 実機で 2.8 GB。`brew cleanup` で古い版とキャッシュを掃除できる
- **匿名の利用統計が既定で有効**: 止めるなら `brew analytics off`

### 参照

- [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux) — `/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、要件
- [brew.sh](https://brew.sh/) — インストーラのワンライナーと概要
- [Homebrew — FAQ](https://docs.brew.sh/FAQ) — 更新・掃除・アンインストールのよくある質問
- [Homebrew/install](https://github.com/Homebrew/install) — `install.sh` と `uninstall.sh` の中身
- `brew help` / `man brew` / `brew config` — サブコマンドと環境の確認

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で手順 1〜4 と[使い方の基本](#使い方の基本)・[更新](#更新)を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、インストーラだけ `NONINTERACTIVE=1` を付けている。

| 手順 | 結果 |
|---|---|
| 実施前 | `command -v brew` は無出力、`/home/linuxbrew` も無い |
| 1. 依存パッケージ | `curl` は導入済み。`file` / `git` / `procps-ng` が新規で、依存込み 30 個ほど（`git-core` / `openssh-clients` / `perl-*` / `groff-base` など）。`curl` と `openssl-libs` は `Upgrading` に解決された |
| 2. インストーラ | `portable-ruby-4.0.7.arm64_linux` を `Pouring` して `==> Installation successful!`。所要 1 分弱。`Warning: /home/linuxbrew/.linuxbrew/bin is not in your PATH.` と `==> Next steps:`（本文に全文を引用）が出た |
| 3. PATH | `~/.bashrc` の 26 行目に `eval "$(... brew shellenv bash)"` が入り、同じシェルで `brew --version` → `Homebrew 7.0.6` |
| 4. 検証 | `command -v brew` → `/home/linuxbrew/.linuxbrew/bin/brew`。`brew config` の `HOMEBREW_PREFIX` / `Branch: stable` / `CPU: quad-core 64-bit arm` を確認。`brew --prefix` / `--cellar` / `--repository` も期待どおり |
| 使い方の基本 | 導入直後は `brew list --versions` / `brew leaves` / `brew outdated` がいずれも無出力。`brew install jq` で `oniguruma` → `jq` の順にボトルが降り（`Pouring jq--1.8.2.arm64_linux.bottle.1.tar.gz`）、`brew leaves` は `jq` だけを返した。`brew deps --tree jq` は `jq └── oniguruma`。`brew autoremove --dry-run` は無出力 |
| 更新 | `brew update` → `Already up-to-date.`、`brew outdated` は無出力（導入直後なので当然） |
| ロールバック | **本実行していない。** `uninstall.sh` を落として `--help` だけ見た。`-n, --dry-run` / `-f, --force` / `-p, --path=PATH` / `--skip-cache-and-logs` があり、`NONINTERACTIVE` が非空なら `--force` 相当になることを確認 |
| 占有 | `jq` を 1 つ入れた状態で 216 MB |

実機側は読み取りだけで次を確認した: `brew --version` → `7.0.6`、`brew config` がコンテナと同じ `HEAD` / `Branch: stable`、`~/.bashrc:26` が**引数なしの `brew shellenv`**、`brew leaves` が 15 件、`brew outdated` が無出力、占有 2.8 GB、`/home/linuxbrew/.linuxbrew/Homebrew` の作成が 2026-09-20 17:26。

#### 未確認事項

- `--dry-run` の実出力（`uninstall.sh --help` に記載があることだけ確認した）
- `brew cleanup` の効果と、掃除後の占有
- 導入先を `/home/linuxbrew/.linuxbrew` 以外にした場合に本当にソースビルドになるか
- 複数ユーザーで共有する場合の権限
- `brew analytics off` の挙動
- 対話での導入（本書の検証はすべて `NONINTERACTIVE=1` 付き。実機の 2026-09-20 の導入は対話だったが、そのときのログは残していない）
- bash 以外のシェル（zsh / fish）での `brew shellenv`
- **[ロールバック](#ロールバック)の本実行**（`uninstall.sh` は `--help` を見ただけで、実機でもコンテナでも走らせていない）
