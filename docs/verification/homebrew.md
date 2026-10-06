# Homebrew インストール手順（AlmaLinux 10）の検証記録

[手順書](../homebrew.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順 / 手順 1: 補足: 依存パッケージの役割

| パッケージ | 用途 |
|---|---|
| `curl` | インストーラ自身と、ボトル・formula の取得 |
| `git` | `brew update` が Homebrew 本体と formula の索引を git で更新するため |
| `file` | インストーラと `brew` がバイナリの種別を判定するため |
| `procps-ng` | `pgrep` など。インストーラの事前チェックで使う |

コンテナでの実測では、`curl` は導入済みで `file` / `git` / `procps-ng` の 3 つが新規、依存を含めて 30 個ほどが入った（`git-core` / `openssh-clients` / `perl-*` など）。実機は最初から git が入っていた。

**`development-tools` グループは要らない。** インストーラの `Next steps` が勧めてくるが、あれは**ソースビルドをする場合**のもので、ボトルだけ使うなら入れなくてよい（手順 2 の補足）。

### 実施手順 / 手順 2: 本文中の記録

   - 手順 3 は、その案内と同じ内容（この手順の補足に実測を載せた）

### 実施手順 / 手順 2: 補足: 導入先を変えてはいけない

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

### 実施手順 / 手順 4: 補足: brew config の読み方

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

### sudo でも使う（任意）: 検証状況の記録

> [!WARNING]
> - `/home/linuxbrew/.linuxbrew` は Homebrew を入れたユーザーの所有。`sudo` で打ったコマンドが `/usr/bin` などに無いと、そのユーザーが書き換えられるプログラムを root の権限で動かすことになる（そのユーザーを乗っ取られると、root まで取られる）
> - sudo の設定はホスト全体にかかる。このホストで `sudo` を使う、ほかのユーザーにも効く
> - この節は **x86_64 のコンテナでのみ検証した**。実機では本実行していない（[付録](#付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)）

### sudo でも使う（任意） / 手順 1: 補足: 置く 1 行と置き方、出力例

- `secure_path` は、sudo がコマンドを探す PATH で、動かすコマンドの `PATH` にもなる。AlmaLinux 10 の `/etc/sudoers` は `Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin`
- `secure_path` は 1 つの文字列の設定で、`+=` では足せない（`+=` は `env_keep` のような一覧の設定だけ）。既定の値を書き直し、その末尾に 2 つを足す
- 末尾に足すので、`/usr/bin` などにある RPM のコマンドが先に見つかる。`sudo git` や `sudo fdisk` が、Homebrew が依存として入れたものに置き換わらない
- `/etc/sudoers` の最後の行（`#includedir /etc/sudoers.d`）で、このディレクトリのファイルが後から読まれる。後から読まれた `secure_path` が勝つので、`/etc/sudoers` は書き換えない
- 先頭の `if` は、ほかで変えた `secure_path` を、この 1 行で消さないため。`sudo printenv PATH` は、sudo がコマンドに渡す PATH（`secure_path`）をそのまま出す
- ファイル名に `.` を入れない。sudo は `.` を含む名前のファイルを読まない（`homebrew.conf` は、警告も出ずに読まれなかった）
- `visudo -cf -` で 1 行の書式を確かめ、通ったときだけ置く。`"` を閉じない行は `stdin:1:35: unexpected line break in string` で止まり、ファイルは置かれなかった
- 書式を誤ったファイルを直接置いても、`sudo` は使えた。ただし、呼ぶたびに同じ誤りを表示し、その行を飛ばした
- `install -m 0440 /dev/stdin` は、root の所有でモードが 0440 の新しいファイルを作る
  - モードが 0644 だと、`sudo` は読むが、`visudo -c` が `bad permissions, should be mode 0440` で失敗した
  - 所有者が自分のユーザーだと、`sudo` は `is owned by uid <UID>, should be 0` と表示して読まなかった
- `fi` の前の `visudo -c` は、置いたファイルも含めて、書式・所有者・モードを確かめる。`/etc/sudoers.d` はモード 0750 で、自分のユーザーからは中を見られない

**出力例**: 最後の行の、コンテナでの実測（Homebrew のユーザーのシェルから）:

```
$ sudo bash -c 'printenv PATH; command -v brew'
/sbin:/bin:/usr/sbin:/usr/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin
/home/linuxbrew/.linuxbrew/bin/brew
```

ファイルを置く前は、1 行目が `/sbin:/bin:/usr/sbin:/usr/bin` だけで、2 行目は出なかった（終了コード 1）。

### ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**（`--help` でオプションを確かめただけ。[付録](#付録-コンテナでの検証記録2026-09-22)）



- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

### 対象と検証環境

- **目的**: AlmaLinux 10 に [Homebrew](https://brew.sh/)（Linux 版。旧称 Linuxbrew）を入れて、**EPEL や AppStream に無い／古い CLI ツールを root 権限なしで新しい版のまま使える**ようにする
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **実機で本実行済み（2026-09-20）。`0dbb522` の直接追記版の実施手順 1〜4 を x86_64 のクリーン VM でも本実行済み（2026-10-06）**。現行版 `5da3478` の共通 bash 新規導入・実施手順 1〜4・root 自身の共通設定を、新しい VM で再検証した（[現行版の再検証](#付録-現行の共通-bash-設定での再検証2026-10-06)）。既存ホストからの手動移行は行っていない。
  - 下表のホストに公式インストーラで `Homebrew 7.0.6` を入れ、`~/.bashrc` に `brew shellenv` を書いて常用中
  - **このリポジトリの Homebrew 系 17 本の手順書は、すべてこれを前提にしている**（実機に入っているのはそのうちの一部で、記録時点の `brew leaves` は 15 件。下表）
  - 本書の手順 1〜4 と[使い方の基本](../homebrew.md#使い方の基本)・[更新](../homebrew.md#更新)は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - 確認したこと: `Homebrew 7.0.6` が同じ場所に入る、`brew config` の `HOMEBREW_PREFIX` が一致する、`brew install jq` がボトルで入る
  - **本実行していないこと**: ロールバック（`uninstall.sh` の本実行）。実機でもコンテナでも実行していない（`--help` を見ただけ）
  - **実機の `~/.bashrc` の 1 行は `brew shellenv`（引数なし）で、本書が書く `brew shellenv bash` と違う**（[手順 3 の補足](../homebrew.md#実施手順)）
  - [root のシェルでも使う](../homebrew.md#root-のシェルでも使う任意)の節は、**x86_64 のコンテナでのみ検証した**（2026-09-30。[付録](#付録-root-のシェルでも使う節のコンテナでの検証記録2026-09-30)）
    - 通したこと: その節の手順 1・2 を、この文書のコードブロックのまま流した。その節の手順 1 の `if … fi`（もとの手順 1）を重ねて実行し、その節の手順 2 の後に手順 1 をもう一度通した
    - 確認したこと: `su -`（root のパスワード）・`su`・ssh での root のログイン・`sudo -i`・`sudo -s` のどれでも Homebrew の `jq` と `nvim` が見つかる、`sudo jq` は見つからない、RPM の `jq` があると root では RPM が先、手順 2 で `/root/.bashrc` が元のファイルと同じ内容に戻る
    - 確認していないこと: 実機、aarch64、コンソールでの root のログイン、SELinux が Enforcing のホスト
    - 2026-10-02: その節のもとの手順 1・2 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）
    - 2026-10-05: 自分用の bash の設定を root のシェルにも入れたホストの箇条書き（その節の手順 1）は、その設定の検証の中で、代わりのコマンドを x86_64 のコンテナで流して確かめた（[ryo-aoki-pc/bash の docs/install.md の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-root-のシェルでも読む節の検証記録2026-10-05)）
  - [sudo でも使う](../homebrew.md#sudo-でも使う任意)の節は、**x86_64 のコンテナでのみ検証した**（2026-10-02。[付録](#付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)）
    - 通したこと: その節の手順 1・2 を、この文書のコードブロックのまま、`sudo` のユーザーの端末に、ブラケットペーストの無しと有りで 1 回ずつ貼った。その節の手順 1 の `if … fi`（もとの手順 1）を重ねて貼り、その節の手順 2 の後に手順 1 をもう一度通した
    - 確認したこと: `sudo jq`・`sudo nvim`・`sudo -u`・`sudo -s`・`sudo -i`・`sudo` で動かすスクリプトで Homebrew のコマンドが見つかる、ほかの wheel のユーザーの `sudo` にも効く、RPM の `jq` があると `sudo` では RPM が先、`su -` と ssh での root のログインは変わらない、`EDITOR=nvim` の `sudoedit` と `sudo EDITOR=nvim visudo` が Homebrew の `nvim` で開く、既定と違う `secure_path` と書式の誤りではファイルを置かない、root のシェルでも使う節と両方通しても PATH が重ならない
    - 確認していないこと: 実機、aarch64、SELinux が Enforcing のホスト（置いたファイルのラベル）、LDAP などから配る sudo の設定、sudo の RPM を更新した後
    - 2026-10-02: その節のもとの手順 1・2 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | `7.0.6`（`/home/linuxbrew/.linuxbrew`、`Branch: stable`） | 同じ（`7.0.6`、同じ場所に新規導入） |
| `~/.bashrc` の行 | `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"`（**引数なし**） | `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"`（本書どおり） |
| 入れたもの | `brew leaves` が 15 件（`fd` / `ffmpeg-full` / `fzf` / `gdu` / `imagemagick-full` / `jq` / `lazygit` / `neovim` / `poppler` / `resvg` / `ripgrep` / `sevenzip` / `tree-sitter-cli` / `yazi` / `zoxide`）。その後 2026-09-23 に [ShellCheck / shfmt](../shellcheck.md) を足して 17 件 | `jq` 1 件のみ（動作確認用） |
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
| EPEL / AppStream / CRB の RPM | root 権限で `dnf` に乗るのが利点。ただし目的のツールが**無い**（`eza` / `git-delta` / `starship` / `zoxide`）か、**古い**（`bat 0.24.0` / `neovim 0.10.1` / `fzf 0.58.0`）ことが多い。同版なら RPM を選ぶ（手順書では [btop.md](../btop.md) と、[image-tools.md](../image-tools.md) の Trivy が例。[ツール一覧](../tool-catalog.md)の fastfetch などもこの規則で RPM にした） | 併用（無い・古いときだけ Homebrew） |
| COPR | EL10 向けの chroot があるとは限らず、`epel-10-aarch64` の repomd が 403 になる例を実測している（[lazygit.md](../lazygit.md)）。zoxide の COPR（x86_64 だけ）も、Homebrew と同じ版なので 2026-10-03 に外した（[zoxide.md](zoxide.md#選択した方針)）。WezTerm Nightly だけは、Homebrew の公式 tap の nightly が古く aarch64 に無いので、EL9 向けの COPR を流用している（[wezterm-nightly.md](../reference/wezterm-nightly.md#選択した方針)） | 不採用（ツールごとに当たり外れが大きい） |
| 各ツールの公式インストーラ / GitHub Releases | バイナリ 1 つで軽いが、**ツールごとに更新方法が違う**。17 本ぶん覚えることになる | 不採用（Homebrew に揃える） |
| `cargo install` / `go install` | toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

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

### root のシェルで使うときの補足

[root のシェルでも使う](../homebrew.md#root-のシェルでも使う任意)の節の補足。実測は x86_64 のコンテナで、その節の手順 1 の後のもの（[付録](#付録-root-のシェルでも使う節のコンテナでの検証記録2026-09-30)）。

  root で Homebrew 版を使うときは、フルパス（`/home/linuxbrew/.linuxbrew/bin/<コマンド>`）で呼ぶ
- **`brew install` などは root では断られる**: PATH で見つかるが、通常のホストでは `Error: Running Homebrew as root is extremely dangerous and no longer supported.` で止まる（終了コード 1）
  - 断られなかったのは `brew --version`・`brew --prefix`・`brew help`・引数の無い `brew list` だけ。[使い方の基本](../homebrew.md#使い方の基本)の表のコマンドは、どれも断られた
  - コンテナの中（`/.dockerenv` か `/run/.containerenv` がある、または `/proc/1/cgroup` に `docker` などがある）では断られない（`brew.sh` の `check-run-command-as-root`）。検証では、これらを外したコンテナで確かめた
- **設定ファイルは root のものを読む**: root で動かした Neovim の `stdpath("config")` は `/root/.config/nvim` だった。自分の `~/.config` の設定は使われない
- **シェルの初期化は `/root/.bashrc` に足さない**: [zoxide](../zoxide.md) や [starship](../starship.md) の `eval "$(… init bash)"` を書くと、root のシェルを開くたびに、Homebrew のユーザーが所有するコマンドが root で動く
  - 自分用の bash の設定を root のシェルにも入れると（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash) の [docs/install.md の「root のシェルでも読む」](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#root-のシェルでも読む任意)）、これらの初期化も root で動く。自分専用のマシンで、一般ユーザーを信用できるときだけにする
- **この節では sudo の `secure_path` を変えない**: [root のシェルでも使う](../homebrew.md#root-のシェルでも使う任意)の節は、root のシェルが対象。`sudo <コマンド>` で使うときは、[sudo でも使う](../homebrew.md#sudo-でも使う任意)の節を通すか、フルパスで渡す（`sudo /home/linuxbrew/.linuxbrew/bin/jq --version` は `jq-1.8.2` を返した）

### sudo で使うときの補足

[sudo でも使う](../homebrew.md#sudo-でも使う任意)の節の補足。実測は x86_64 のコンテナで、その節の手順 1 の後のもの（[付録](#付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)）。

### 注意点 / 手順 0: 本文中の記録

  - 入れるものの一覧の後に `==> Do you want to proceed with the installation? [y/n]` と聞き、答えは Enter を待たずに 1 文字で読む（[homebrew-offline.md 手順 4](../homebrew-offline.md#実施手順) の補足の実測）

### 注意点 / 手順 0: 本文中の記録

  - 7.0.7 のソースで確かめた仕様。過去の付録の「依存が残った」という実測は、そのときの版と条件での記録として残している

### 参照

- [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux) — `/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、要件
- [brew.sh](https://brew.sh/) — インストーラのワンライナーと概要
- [Homebrew — FAQ](https://docs.brew.sh/FAQ) — 更新・掃除・アンインストールのよくある質問
- [Homebrew/install](https://github.com/Homebrew/install) — `install.sh` と `uninstall.sh` の中身
- [Homebrew 7.0.7 の leaves](https://github.com/Homebrew/brew/blob/7.0.7/Library/Homebrew/cmd/leaves.rb) — `brew leaves` のヘルプと実装（2026-10-05 に照合）
- [Homebrew 7.0.7 の install](https://github.com/Homebrew/brew/blob/7.0.7/Library/Homebrew/cmd/install.rb)・[upgrade](https://github.com/Homebrew/brew/blob/7.0.7/Library/Homebrew/cmd/upgrade.rb)・[uninstall](https://github.com/Homebrew/brew/blob/7.0.7/Library/Homebrew/cmd/uninstall.rb)・[cleanup](https://github.com/Homebrew/brew/blob/7.0.7/Library/Homebrew/cleanup.rb) — 確認を聞く条件と、不要な依存の自動削除（2026-10-05 に照合）
- `man sudoers`（`secure_path`、`#includedir` で読まれないファイル名、`Defaults` の上書き）・`man visudo`（`-c`、`-f`） — [sudo でも使う](../homebrew.md#sudo-でも使う任意)の節の 1 行と確かめ方
- `brew help` / `man brew` / `brew config` — サブコマンドと環境の確認

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で手順 1〜4 と[使い方の基本](../homebrew.md#使い方の基本)・[更新](../homebrew.md#更新)を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、インストーラだけ `NONINTERACTIVE=1` を付けている。

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
- bash 以外のシェル（zsh / fish）での `brew shellenv`
- **[ロールバック](../homebrew.md#ロールバック)の本実行**（`uninstall.sh` は `--help` を見ただけで、実機でもコンテナでも走らせていない）

### 付録: root のシェルでも使う節のコンテナでの検証記録（2026-09-30）

[root のシェルでも使う（任意）](../homebrew.md#root-のシェルでも使う任意)を足したときの記録。x86_64 のクラウドホスト上の Docker 29.3.1（cgroup v1）で、使い捨てのコンテナを立てて行った。実機で加えた変更は無い。

**環境**:

- `quay.io/almalinuxorg/almalinux:10`（AlmaLinux 10.2）を `--network host` で立て、プロキシの CA、dnf の `proxy=`、`almalinux-*.repo` の `baseurl=` を入れた
- `sudo`・`passwd`・`openssh-server` などを dnf で入れ、NOPASSWD の `sudo` を持つ非 root ユーザー（`<USER>`）を作った。root には、検証のためだけにパスワードを付けた
- Homebrew は[実施手順](../homebrew.md#実施手順)の手順 1〜3 を、インストーラだけ `NONINTERACTIVE=1` を付けて通した（`Homebrew 7.0.7`）。`brew install jq` と `brew install neovim` で、`jq 1.8.2` と `neovim 0.12.5_1` を入れた
- 版: `sudo-1.9.17-10.p2.el10_2.6`、`rootfiles-8.1-54.el10`、`bash-5.2.26-6.el10`、`util-linux-2.40.2-18.el10`、`openssh-server-9.9p1-27.el10_2.alma.1`
- `/etc/sudoers` の `secure_path` は `/sbin:/bin:/usr/sbin:/usr/bin`。`/root/.bash_profile` は `~/.bashrc` を読む
- `/root/.bashrc` は `/etc/bashrc` を読み、`$HOME/.local/bin:$HOME/bin` を PATH の先頭に足し、`rm`・`cp`・`mv` の alias を置く。非対話のシェルで途中で抜ける行は無い

**流し方**: 節のコードブロックを文書から抜き出し、`<USER>` の `bash -i` の標準入力に 1 手順ずつ流した。対話のシェル（`su -`・`su`・`sudo -i`・`sudo -s`・`ssh -tt`）は Python の `pty` で開き、パスワードと `printenv PATH`・`type -a jq`・`exit` を送った。

| 手順・確認 | 結果 |
|---|---|
| 節の手順 1 の前 | `sudo -i bash -c 'printenv PATH; command -v brew'` は `/root/.local/bin:/root/bin:/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin` だけで、終了コード 1。`sudo su - -c 'printenv PATH'` は `/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin`。`sudo jq --version` は `sudo: jq: command not found` |
| 節の手順 1 の `if … fi`（もとの手順 1） | `/root/.bashrc` の末尾に 1 行入り（22 行から 23 行）、その行が表示された |
| 節の手順 1 の確かめの行（もとの手順 2） | その手順の補足の出力例のとおり |
| 節の手順 1 の `if … fi`（もとの手順 1）をもう一度 | `中断: /root/.bashrc に既にある`。ファイルは変わらない |
| `su -`（`<USER>` から、root のパスワード） | PATH は `/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin`。`type -a jq` は `jq is /home/linuxbrew/.linuxbrew/bin/jq` |
| `su`（`-` 無し） | PATH は `/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin` の後ろに 2 つ（`<USER>` の PATH は引き継がない）。`jq` は Homebrew 版 |
| `sudo -i`（対話） | 節の手順 1 の確かめの行（もとの手順 2）と同じ PATH。`jq` は Homebrew 版 |
| `sudo -s`（対話） | `HOME=/root`。PATH は `/root/.local/bin:/root/bin:/sbin:/bin:/usr/sbin:/usr/bin` の後ろに 2 つ。`jq` は Homebrew 版 |
| ssh での root のログイン | 公開鍵で `127.0.0.1:2222` の sshd に入った。コマンドを渡した `ssh root@… 'printenv PATH; command -v jq'` も、`ssh -tt` のログインシェルも、PATH の末尾に 2 つが付き、`jq` は Homebrew 版 |
| root の `su - -c`・`bash -l -c` | どちらも PATH の末尾に 2 つが付き、`command -v jq` は Homebrew 版 |
| `sudo jq`・`sudo nvim` | どちらも `command not found`（対象外のまま）。`sudo /home/linuxbrew/.linuxbrew/bin/jq --version` は `jq-1.8.2` |
| 入れ子のシェル | `sudo -i bash -ic 'printenv PATH'` でも 2 つは 1 回ずつ。同じシェルで `. ~/.bashrc` を 2 回読んでも、PATH の `linuxbrew` を含む要素は 2 つのまま |
| RPM の jq | AppStream の `jq-1.7.1-11.el10_2.2` を入れると、root の `type -a jq` は `/bin/jq` → `/usr/bin/jq` → Homebrew の順、`<USER>` は Homebrew → `/usr/bin/jq` → `/bin/jq` の順。RPM の `jq --version` は `jq-` とだけ出した（Homebrew 版は `jq-1.8.2`） |
| Neovim | root の `command -v nvim` は `/home/linuxbrew/.linuxbrew/bin/nvim`、`nvim --version` は `NVIM v0.12.5`、`stdpath("config")` は `/root/.config/nvim`（`<USER>` では `/home/<USER>/.config/nvim`） |
| root の `brew` | 同じ中身のコンテナを `--cgroupns=private` で立て直し、`/.dockerenv` を消して確かめた。`brew config`・`brew install tree`・`brew list --versions`・`brew leaves`・`brew info jq`・`brew deps --tree jq`・`brew outdated`・`brew autoremove --dry-run`・`brew uninstall jq`・`brew update` は `Error: Running Homebrew as root is extremely dangerous and no longer supported.`（終了コード 1）。`brew --version`・`brew --prefix`・`brew help`・引数の無い `brew list` は動いた。目印を外す前のコンテナでは、root の `brew` は断られない |
| 節の手順 2 | `0` と出た。`/root/.bashrc` の SHA-256 が、節の手順 1 の前に写したものと一致した。`sudo -i` の PATH から 2 つが消え、`command -v brew` は終了コード 1 |
| 節の手順 2 の後に手順 1 | 1 回目と同じ結果 |

#### 未確認事項（root の節）

- 実機（aarch64 の Raspberry Pi 5）での実行
- コンソール（仮想端末や GNOME のログイン画面）での root のログイン。検証では root の `bash -l -c` を代わりにした
- SELinux が Enforcing のホスト（検証のコンテナには SELinux が無い）
- 端末への貼り付け（検証は標準入力に流しただけ。ブラケットペーストの有無も見ていない）
- bash 以外の root のシェル（zsh など）

### 付録: sudo でも使う節のコンテナでの検証記録（2026-10-02）

[sudo でも使う（任意）](../homebrew.md#sudo-でも使う任意)を足したときの記録。x86_64 のクラウドホスト上の Docker 29.6.2（cgroup v1）で、使い捨てのコンテナを立てて行った。実機で加えた変更は無い。

**環境**:

- `quay.io/almalinuxorg/10-init`（AlmaLinux 10.2、`sha256:a91c1066…fd73`）を `--privileged --cgroupns=private --network host` で立て、systemd を PID 1 にして、sshd（ポート 2222）と systemd-logind を動かした
- プロキシの CA、dnf の `proxy=`、`almalinux-*.repo` の `baseurl=`、ログインシェルの `HTTPS_PROXY` を入れた
- wheel の一般ユーザーを 2 人（`<USER>`・`<USER2>`）作った。どちらの `sudo` も、既定の `%wheel ALL=(ALL) ALL` のまま。root には、検証のためだけにパスワードを付けた
- Homebrew は、`<USER>` の ssh のログインシェル（umask 0022）で[実施手順](../homebrew.md#実施手順)の手順 1〜3 を通した
  - インストーラだけ `NONINTERACTIVE=1` を付け、そのときだけ NOPASSWD の `sudo` の設定を置いた（終わったら消した）
  - `Homebrew 7.0.7`。`brew install jq neovim gdu glib` で `jq 1.8.2`・`neovim 0.12.5_1`・`gdu 5.37.0`・`glib 2.90.0` を入れた
  - `docker exec` は umask が 0000 で、そこから入れた 1 回目は `/home/linuxbrew/.linuxbrew/bin` などが 0777 になった。コンテナを作り直し、ssh から入れ直した
- Homebrew の root の断り（`brew.sh` の `check-run-command-as-root`）が効くように、`/.dockerenv` を消し、`/proc/1/cgroup` に `docker` が出ないようにした（`--cgroupns=private`）
- 版: `sudo-1.9.17-10.p2.el10_2.6`、`bash-5.2.26-6.el10`、`coreutils-single-9.5-8.el10_2`、`vim-minimal-9.1.083-9.el10_2.20`、`glib2-2.80.4-12.el10_2.22`、`openssh-server-9.9p1-28.el10_2.alma.1`、`systemd-257-23.el10_2.2.alma.1`
- `/etc/sudoers` の 88 行目は `Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin`、最後の 120 行目は `#includedir /etc/sudoers.d`。`/etc/sudoers.d` は `root:root` の 0750 で、空
- `/home/linuxbrew` は `root:root` の 0755、`/home/linuxbrew/.linuxbrew/bin` と `sbin` は `<USER>` の所有の 0775

**流し方**:

- ホストの tmux 3.4 のペイン（200x50）から `docker exec -it … ssh -t -p 2222 <USER>@127.0.0.1` でログインした
- この文書から節のブロック（折り畳みの外のもの）を抜き出し、手順ごとに `tmux paste-buffer` で貼った（[tmux.md の付録](tmux.md#付録-コンテナでの検証記録2026-10-01)と同じ形）
  - 1 回目はブラケットペースト無し、2 回目は `paste-buffer -p`（ブラケットペースト有り。貼った後に Enter を送った）
- 画面は `tmux capture-pane` で読んだ。エディタは、別の `docker exec` から `/proc/<PID>/exe` と `/proc/<PID>/environ` で、実体・ユーザー・`HOME`・`PATH` を見た
- `<USER2>` と、開いたままの `sudo -s` は、別の tmux のペインから同じように ssh でログインして確かめた

| 手順・確認 | 結果 |
|---|---|
| 節の手順 1 の前 | `sudo printenv PATH` は `/sbin:/bin:/usr/sbin:/usr/bin`。`sudo jq --version` と `sudo brew --version` は `sudo: …: command not found`（終了コード 1）。節の手順 1 の確かめの行（もとの手順 2）は 1 行目だけを出し、終了コード 1 |
| 節の手順 1 の前のエディタ | `EDITOR=nvim VISUAL=nvim sudoedit /etc/motd` は `/usr/bin/vi` を `<USER>` で動かした（`HOME` と `PATH` は `<USER>` のもの）。`sudo EDITOR=nvim visudo` と `sudo visudo` は `/usr/bin/vi` を root で動かした |
| 同（フルパス） | `SUDO_EDITOR=/home/linuxbrew/.linuxbrew/bin/nvim sudoedit /etc/motd` は Homebrew の `nvim` を `<USER>` で動かし、`stdpath("config")` は `/home/<USER>/.config/nvim`。`sudo EDITOR=/home/linuxbrew/.linuxbrew/bin/nvim visudo` は Homebrew の `nvim` を root で動かし、`stdpath("config")` は `/root/.config/nvim` |
| 節の手順 1 の `if … fi`（もとの手順 1） | `stdin: parsed OK`・`/etc/sudoers: parsed OK`・`/etc/sudoers.d/homebrew: parsed OK`。置いたファイルは `root:root` の 0440（116 バイト）で、中身はその手順の `line` の 1 行 |
| 節の手順 1 の確かめの行（もとの手順 2） | その手順の補足の出力例のとおり |
| 節の手順 1 の `if … fi`（もとの手順 1）をもう一度 | `中断: sudo の PATH に Homebrew が既にある`。ファイルの SHA-256 は変わらない |
| 各入口 | [sudo で使うときの補足](../reference/homebrew.md#sudo-で使うときの補足)の表のとおり。`sudo -s` は `HOME=/root`。`sudo -u nobody jq --version` は `jq-1.8.2`。`sudo su - -c 'printenv PATH'`・`su -`（root のパスワード）・ssh での root のログインは `/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin` で、`jq` は見つからない |
| `<USER2>` | 自分の PATH に Homebrew は無く、`command -v jq` は終了コード 1。`sudo jq --version` は `jq-1.8.2` |
| エディタ（節の後） | `EDITOR=nvim VISUAL=nvim sudoedit /etc/motd` は Homebrew の `nvim` を `<USER>` で動かし、`stdpath("config")` は `/home/<USER>/.config/nvim`。`sudo EDITOR=nvim visudo` は Homebrew の `nvim` を root で動かし、`stdpath("config")` は `/root/.config/nvim` |
| `EDITOR` を export したとき | `export EDITOR=nvim VISUAL=nvim` の後の `sudo visudo` は、節の前も後も `/usr/bin/vi`。節の後の `sudoedit /etc/motd` は Homebrew の `nvim` |
| `sudo nvim` | `NVIM v0.12.5`。`stdpath("config")` は `/root/.config/nvim` |
| RPM の jq | AppStream の `jq-1.7.1-11.el10_2.2` を入れると、`sudo jq --version` は `jq-`、`sudo bash -c 'type -a jq'` は `/bin/jq` → `/usr/bin/jq` → Homebrew の順。`sudo env PATH="$PATH" jq --version` は `jq-1.8.2`。消した後の `sudo jq --version` は `jq-1.8.2` |
| コマンドの数 | Homebrew の `bin` と `sbin` に 231 個。`/usr/bin`・`/usr/sbin` と同じ名前が 135 個、無いものが 96 個 |
| gdu と gsettings | `sudo gdu-go --version` は `v5.37.0`。`~/.local/bin/gdu` のリンクは `<USER>` では動き、`sudo gdu --version` は `sudo: gdu: command not found`。`sudo sh -c 'command -v gsettings'` と `sudo -u <USER2> env sh -c 'command -v gsettings'` は `/bin/gsettings`（`<USER>` の `command -v gsettings` は Homebrew の `glib` のもの） |
| root の brew | `sudo brew --version` は `Homebrew 7.0.7`。`sudo brew install tree` は `Error: Running Homebrew as root is extremely dangerous and no longer supported.`（終了コード 1）。`sudo brew services list` と `sudo brew services start jq` は `Error: Need to download https://formulae.brew.sh/api/internal/packages.x86_64_linux.jws.json but cannot as root!`（終了コード 1。`<USER>` で `brew update` した後も同じ）。`/home/linuxbrew` の下に root の所有のファイルはできなかった |
| root の節との組み合わせ | root の節の手順 1 の後、`sudo -i` と `sudo -s` の PATH で 2 つは 1 回ずつ。この節の手順 2 の後も、`sudo -i` と `sudo -s` には root の節の 2 つが残り、`sudo jq` は `command not found` |
| 同（この節だけ） | root の節の手順 1 の確かめの行（もとの手順 2）は、`/root/.bashrc` に書く前から 2 つと `brew` を出した。root の節の手順 2 の後も `sudo -i` に 2 つが残った。`sudo su - -c 'printenv PATH; command -v brew'` は、root の節の行があるときだけ `brew` を出した |
| 節の手順 2 | `/sbin:/bin:/usr/sbin:/usr/bin`。`/etc/sudoers.d` は空に戻った。この後の `sudo -E printenv PATH` は `/sbin:/bin:/usr/sbin:/usr/bin` |
| 節の手順 2 の後に手順 1 | 1 回目と同じ結果。ファイルの SHA-256 も同じ |
| 開いたままのシェル | 別のペインで開いていた `sudo -s` は、節の手順 1 の後も 2 つが無く、開き直すと付いた。節の手順 2 の後も 2 つが残り、開き直すと消えた |
| 既定と違うホスト | root で `/etc/sudoers.d/site`（`Defaults secure_path = /usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin`、0440）を置くと、節の手順 1 の `if … fi`（もとの手順 1）は `中断: sudo の PATH が AlmaLinux 10 の既定（/sbin:/bin:/usr/sbin:/usr/bin）と違う` で止まり、`homebrew` は作られなかった |
| 書式の誤り | 節の手順 1 の `line` を `'Defaults secure_path = "/sbin:/bin'` に変えた写しは、`stdin:1:35: unexpected line break in string` を出し、`homebrew` を置かなかった。同じ行のファイルを root で直接置くと、`sudo` は呼ぶたびに同じ誤りを表示したが、終了コードは 0 で、PATH は既定のままだった（`visudo -c` は終了コード 1） |
| 所有者・モード・名前 | `<USER>` の所有のファイルは `sudo: /etc/sudoers.d/zzowner is owned by uid <UID>, should be 0` と出て読まれなかった。root の所有で 0644 のファイルは読まれたが、`visudo -c` が `bad permissions, should be mode 0440`。`homebrew.conf` という名前のファイルは、何も出ずに読まれなかった |
| 日本語のロケール | コンテナのイメージは訳を入れない（`%_install_langs C.utf8`）ので、それを外して `sudo` を入れ直した。`LANG=ja_JP.UTF-8` では、`visudo -c` は `/etc/sudoers: 正しく構文解析されました`、節の前の `sudo jq --version` は `sudo: jq: コマンドが見つかりません` |
| 2 回目（ブラケットペースト有り） | 節の手順 1、手順 1 の `if … fi`（もう一度）、手順 2、手順 1、手順 2 が、1 回目と同じ結果 |

#### 未確認事項（sudo の節）

- 実機（aarch64 の Raspberry Pi 5、x86_64 の PC）での実行
- SELinux が Enforcing のホスト（`install` で置いたファイルのラベル。検証のコンテナには SELinux が無い）
- LDAP や SSSD から配る sudo の設定
- `sudo` の RPM を更新して、`/etc/sudoers` の既定の `secure_path` が変わったとき
- root の Homebrew の API のキャッシュがあるときの `sudo brew services`（検証では、どれも API の取得で止まった）
- bash 以外のシェル

---

### 付録: クリーン VM での検証記録（2026-10-06）

**検証対象**: `0dbb522` の、各手順で `~/.bashrc` などへ設定を直接追記する版。以下の手順番号と「本文」はこの版を指す。検証後に共通 bash 設定へ統一された現行版（`0bc9970`）の設定リポジトリの新規導入・既存設定からの移行は、今回の VM では実行していない。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証対象版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順（`0dbb522`）**: 実施手順 1〜4。

**結果**: 公式インストーラーの sudo のパスワード確認と RETURN の確認に答え、Homebrew 7.0.8 が `/home/linuxbrew/.linuxbrew` に入った。本文どおり `brew shellenv bash` を `~/.bashrc` に足し、`brew --version`・`brew config`・PATH を確認した。検証用 sudo は通常のコマンドを NOPASSWD にしていたが、インストーラーの `sudo -v` はパスワードを要求した。パスワードを入力して進め、sudoers は変更しなかった。

ボトルの取得中には `Landlock ABI 10 or later is required to deny all network access; found ABI 6` という警告が出た。Homebrew は、このカーネルが対応する制限を適用すると表示し、導入は続行して成功した。警告だけで導入失敗とは扱わない。

**今回の未確認範囲**: root・sudo で Homebrew を使う任意節、更新・ロールバックは今回流していない。

### 付録: 現行の共通 bash 設定での再検証（2026-10-06）

`5da3478` の実施手順 1〜4 を、公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing）で通した。先に README の共通 bash の clone と `install.sh` を実行し、OS 既定の `~/.bashrc` に読み込み口だけを設定した。SSH の対話 PTY でインストーラの VM 専用パスワードと RETURN に答えた。

Homebrew 7.0.8 が標準 prefix に入り、手順 3 の `. ~/.bashrc` で `/home/linuxbrew/.linuxbrew/bin/brew` が見つかった。インストーラの案内する `brew shellenv` の行は追加していない。`brew config` の prefix と stable branch も一致した。依存 RPM は Workstation に既にあり、追加は無かった。

一般ユーザーの共通設定の再実行で、`~/.bashrc`・元の控え・`~/.bash_profile` の SHA256 は変わらず、読み込み口は 1 行、控えは 0600 だった。root 自身にも共通 bash を新規導入し、root の対話シェルで Homebrew の PATH と版を確認した。sudo の `secure_path` を変更する任意節、Homebrew の更新・削除はこの再検証では行っていない。

### 手順中の実測・検証状況の記録

- `brew upgrade` も 7.0.7 では ask mode が既定。名前を指定した場合はその名前以外も更新する計画、名前を省略した場合は更新対象があるときに、TTY で確認する（公式ソースで確認。更新対象がある状態での表示は未確認）

### 手順中の実測・検証状況の記録

- **占有が大きい**: 実機で 2.8 GB。`brew cleanup` で古い版とキャッシュを掃除できる

### sudo で使うときの補足

- **RPM と同じ名前のコマンドは、`sudo` でも RPM が先**: AppStream の `jq-1.7.1` も入れると、`sudo jq --version` は RPM の `jq-` を返した。`sudo bash -c 'type -a jq'` は `/bin/jq` → `/usr/bin/jq` → Homebrew の順。`sudo` で Homebrew 版を使うときは、フルパスで呼ぶ
- **依存として入ったコマンドも `sudo` で動く**: 検証では `jq`・`neovim`・`gdu`・`glib` と依存で 231 個のコマンドが入った
  - RPM と同じ名前の 135 個（`glib` の依存の util-linux の `fdisk` など）は、RPM が先
  - 残りの 96 個（`python3.14`・`sqlite3` など）が、`sudo` で動くようになった
- **`sudo` を使う、ほかのユーザーにも効く**: 自分の PATH に Homebrew の無い、別の wheel のユーザーでも、`sudo jq --version` は `jq-1.8.2` を返した
- **設定ファイルは root のものを読む**: `sudo nvim` の `stdpath("config")` は `/root/.config/nvim` だった（root のシェルと同じ）
- **`sudoedit` と `visudo` は、この節の前は黙って `vi` で開いた**: エディタを `secure_path` で探し、見つからないと `/usr/bin/vi` を使う。`EDITOR=nvim` の `sudoedit /etc/motd` も `sudo EDITOR=nvim visudo` も、エラーを出さずに `/usr/bin/vi` だった
  - `sudo visudo` は、`EDITOR` を export していても、この節の後も `/usr/bin/vi` だった（sudo が `EDITOR` を渡さない）。`nvim` で開くなら `sudo EDITOR=nvim visudo` と打つ
- **`sudoedit` だけなら、この節は要らない**: `SUDO_EDITOR=/home/linuxbrew/.linuxbrew/bin/nvim sudoedit <ファイル>` は、この節の前でも Homebrew の `nvim` を自分のユーザーで開き、`stdpath("config")` は自分の `~/.config/nvim` だった
- **`brew install` などは root では断られる**: `sudo brew install tree` は `Error: Running Homebrew as root is extremely dangerous and no longer supported.`（終了コード 1）。`sudo brew --version` は動いた
  - `brew services` は root の断りから外されている（`brew.sh` の `check-run-command-as-root`）。ただし `sudo brew services list` は `Error: Need to download https://formulae.brew.sh/api/internal/packages.x86_64_linux.jws.json but cannot as root!` で止まった（自分のユーザーで `brew update` した後も同じ）
- **[root のシェルでも使う](../homebrew.md#root-のシェルでも使う任意)の節と両方通してもよい**: `/root/.bashrc` の `case` が足さないので、`sudo -i`・`sudo -s` の PATH で 2 つは重ならなかった。片方を戻しても、もう一方の 2 つは残る
- **採らなかった形**
  - `sudo -E`: PATH は `secure_path` に置き換わる（`sudo -E printenv PATH` は、この節の前は `/sbin:/bin:/usr/sbin:/usr/bin`）
  - `alias sudo='sudo env PATH="$PATH"'`: 自分の PATH を丸ごと渡すので、Homebrew が先頭になる。RPM の `jq` があっても、`sudo env PATH="$PATH" jq --version` は Homebrew の `jq-1.8.2` を返した
  - `/usr/local/bin` や `~/.local/bin` にリンクを張る: どちらも AlmaLinux 10 の `secure_path` に無い。`~/.local/bin/gdu` のリンク（[gdu.md の「gdu の名前で呼ぶ」](../gdu.md#gdu-の名前で呼ぶ任意)）は、この節を通しても `sudo gdu` で `command not found` だった
- **Homebrew を消す前に、この節を戻す**: 公式のアンインストーラ（`uninstall.sh`）は `/etc/sudoers.d` に触れない（中に `sudoers` の文字が無い）。残すと、`secure_path` に `/home/linuxbrew/.linuxbrew/bin` が残る

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 補足

  - 7.0.7 のヘルプでは、指定した formula / cask だけを入れる計画と、TTY が無い実行では確認を省く。コンテナで確認が出なかった記録だけでは、端末でも出ないとは判断できない
