# zoxide 最新版インストール手順（AlmaLinux 10 / Homebrew・dnf）

## 実施手順

> [!IMPORTANT]
> - **入れ方を 1 つ選ぶ**: Homebrew（手順 2。x86_64・aarch64）か、dnf（手順 3〜5。COPR の `kray74/cli-tools` で、**x86_64 だけ**）。選ばなかった方の手順は飛ばす
> - **前提**: Homebrew で入れるなら、[Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew は root で動かず、設定も自分の `~/.bashrc` に書くため）。dnf で入れるときも、`sudo` は dnf のコマンドにだけ付けてある
> - **dnf の手順 3 と手順 5 には対話入力がある**（COPR の有効化の `[y/N]`、トランザクションと COPR の GPG 鍵の `[y/N]`）。答えてから次の手順を貼る
> - Homebrew で入れた zoxide を dnf に入れ替えるときは、先に[ロールバック](#ロールバック)の手順 1 と手順 4 で消しておく

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **dnf の経路（手順 3〜5 と、更新・ロールバックの dnf の手順）は x86_64 のコンテナでのみ検証した**。実機では本実行していない（[対象と検証環境](#対象と検証環境)）。

1. 変数を設定する。

   ```bash
   ZOXIDE_CMD=z                    # zoxide が定義するコマンド名。cd にすると cd を置き換える。<ZOXIDE_CMD>
   printf 'ZOXIDE_CMD = %s\n' "${ZOXIDE_CMD}"
   ```

   - **編集が必須の変数は無い**。既定では `z` コマンドが増えるだけで、`cd` はそのまま残る
   - `cd` 自体を置き換えたい場合だけ、`ZOXIDE_CMD=cd` にする
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す
   - dnf で入れるなら（x86_64 だけ）、手順 2 は飛ばす

   <details>
   <summary>補足: 変数について</summary>

   `--cmd cd` を渡すと `cd` 自体が zoxide の関数に置き換わり、`cd foo` が「まず実在するディレクトリ、無ければ履歴から推測」という動きになる。

   - 便利な反面、**スクリプトやツールが呼ぶ `cd` の挙動まで変わる**ので、本書の既定は `z`（`cd` はそのまま）にしてある
   - 実機も `--cmd` 無し（＝ `z`）で入れてある

   </details>

1. Homebrew で入れるときは、brew で zoxide と fzf を入れる。

   ```bash
   brew install zoxide fzf
   ```

   - `fzf` は必須ではないが、入れておくと候補から選ぶ `zi` が使える
   - aarch64 でもビルド済みのボトルが降ってくる
   - Homebrew で入れたなら、手順 3〜5 は飛ばす

1. x86_64 の PC で dnf で入れるときは（手順 2 の代わりに）、COPR を有効にする。

   ```bash
   sudo dnf copr enable kray74/cli-tools
   ```

   - 有効化してよいか `[y/N]` で聞かれる
   - `Repository successfully enabled.` と出ればよい
   - chroot は `epel-10-x86_64` になる。aarch64 では `epel-10-aarch64` が無いと言われて止まり、何も変わらない
   - **次の手順は、`[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: COPR の選び方 / できる repo ファイル</summary>

   EPEL 10 にも AppStream にも zoxide は無く、EL10 向けの RPM は COPR にしか無い（[選択した方針](#選択した方針)）。

   - `kray74/cli-tools` は 10 本の CLI をまとめた個人の COPR で、spec を [GitHub](https://github.com/kray74/cli-tools) で公開している
   - zoxide は上流のリリースの tarball から `cargo build --locked` でビルドされ、`cargo test` も通してある（spec の `%check`）
   - 有効化の前に出る警告のとおり、COPR の中身は Fedora が審査しない

   `dnf copr enable` は chroot を `/etc/os-release` と `$basearch` から推定する（EL 系は `epel-<major>-<arch>`。copr プラグインの `_guess_chroot`）。検証コンテナでできた repo ファイル:

   ```
   $ cat /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:kray74:cli-tools.repo
   [copr:copr.fedorainfracloud.org:kray74:cli-tools]
   name=Copr repo for cli-tools owned by kray74
   baseurl=https://download.copr.fedorainfracloud.org/results/kray74/cli-tools/epel-10-$basearch/
   type=rpm-md
   skip_if_unavailable=True
   gpgcheck=1
   gpgkey=https://download.copr.fedorainfracloud.org/results/kray74/cli-tools/pubkey.gpg
   repo_gpgcheck=0
   enabled=1
   enabled_metadata=1
   ```

   aarch64 では、次のように止まる（x86_64 のコンテナで `dnf --forcearch aarch64 copr enable kray74/cli-tools` として確かめた。repo ファイルは作られない）:

   ```
   Error: It wasn't possible to enable this project.
   Repository 'epel-10-aarch64' does not exist in project 'kray74/cli-tools'.
   Available repositories: 'epel-10-x86_64', 'fedora-44-x86_64'
   ```

   </details>

1. dnf で入れるときは、この COPR から入るパッケージを zoxide と fzf に絞る。

   ```bash
   {
     sudo dnf config-manager --save --setopt='copr:copr.fedorainfracloud.org:kray74:cli-tools.includepkgs=zoxide,fzf'
     grep -n includepkgs /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:kray74:cli-tools.repo
   }
   ```

   - `11:includepkgs=zoxide,fzf` と出ればよい
   - 絞らないと、同じ COPR の chezmoi・lazygit・yazi なども候補になる（この手順の補足）

   <details>
   <summary>補足: 絞る理由</summary>

   `kray74/cli-tools` には、zoxide と fzf のほかに chezmoi・eza・lazygit・starship・tailscale・topgrade・vivid・yazi がある（2026-09-29）。

   - EPEL にも同じ名前のパッケージがある。絞らないと、EPEL から入れた chezmoi 2.72.0 が、`dnf upgrade` でこの COPR の 2.72.2 に置き換わった（コンテナで確認）
   - fzf は絞った後も候補に残すので、EPEL の fzf 0.58.0 が入っていれば、この COPR の 0.74.4 に上がる（Homebrew の fzf と同じ版）
   - lazygit・yazi・starship・eza は、本リポジトリでは Homebrew で入れている。RPM でも入れると、同じ名前のコマンドが 2 つになる

   絞った後にこの COPR から見えるのは、zoxide と fzf（とそれぞれの `.src`）だけ:

   ```
   $ dnf list --available --repo 'copr:copr.fedorainfracloud.org:kray74:cli-tools'
   Available Packages
   fzf.src         0.74.4-1.el10    copr:copr.fedorainfracloud.org:kray74:cli-tools
   fzf.x86_64      0.74.4-1.el10    copr:copr.fedorainfracloud.org:kray74:cli-tools
   zoxide.src      0.10.0-1.el10    copr:copr.fedorainfracloud.org:kray74:cli-tools
   zoxide.x86_64   0.10.0-1.el10    copr:copr.fedorainfracloud.org:kray74:cli-tools
   ```

   </details>

1. dnf で入れるときは、zoxide と fzf を入れる。

   ```bash
   sudo dnf install zoxide fzf
   ```

   - `fzf` は必須ではないが、入れておくと候補から選ぶ `zi` が使える（zoxide の RPM も `Recommends: fzf`）
   - トランザクション表の `[y/N]` の後に、COPR の GPG 鍵の取り込みを聞かれる
   - fingerprint は `7BED C827 A615 D85B 4426 0607 33CE 1956 4056 78BB`（`kray74_cli-tools`）
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 取り込まれる鍵 / 入るファイル</summary>

   鍵はインストールのときに COPR の `pubkey.gpg` から取り込まれる:

   ```
   Importing GPG key 0x405678BB:
    Userid     : "kray74_cli-tools (None) <kray74#cli-tools@copr.fedorahosted.org>"
    Fingerprint: 7BED C827 A615 D85B 4426 0607 33CE 1956 4056 78BB
    From       : https://download.copr.fedorainfracloud.org/results/kray74/cli-tools/pubkey.gpg
   ```

   - 鍵の自己署名は SHA-256（`gpg --list-packets` の `digest algo 8`）なので、EL10 の rpm がそのまま取り込む（SHA-1 の鍵は取り込めない。[tool-catalog.md の注意点](tool-catalog.md#注意点)）
   - 取り込んだ鍵は `gpg-pubkey-405678bb-69063860` という名前で残る
   - zoxide の RPM には、本体（`/usr/bin/zoxide`）のほかに man ページ（`man zoxide`）と、bash・zsh・fish の補完が入る
   - fzf の RPM は `/usr/bin/fzf` と `/usr/bin/fzf-tmux`

   </details>

1. `~/.bashrc` のいちばん最後に、zoxide の初期化の 1 行を書く。

   ```bash
   printf 'eval "$(zoxide init bash --cmd %s)"\n' "${ZOXIDE_CMD:?手順 1 の ZOXIDE_CMD が空のまま。値を入れて貼り直す}" >> ~/.bashrc
   . ~/.bashrc
   type -t "${ZOXIDE_CMD}"
   ```

   - いちばん最後に置く理由は、この手順の補足
   - **この 1 行を書かないと `z` は使えない**（zoxide 本体はシェル関数を出力するだけで、`zoxide` コマンド自体では移動できない）
   - `function` と出れば読み込めている
   - 自分用の bash の設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）を入れたホストでは、このブロックは貼らない。代わりに `. ~/.bashrc` と `type -t z` を実行する（その設定が `--cmd z` の初期化を最後に読む）

   <details>
   <summary>補足: init の中身</summary>

   `zoxide init bash` は**シェル関数の定義を標準出力に吐くだけ**のコマンドで、`eval` しなければ何も起こらない。実機での出力は 181 行あり、先頭は次のようになっている:

   ```
   $ zoxide init bash | head -12
   # shellcheck shell=bash

   # =============================================================================
   #
   # Utility functions for zoxide.
   #

   # pwd based on the value of _ZO_RESOLVE_SYMLINKS.
   function __zoxide_pwd() {
       \builtin pwd -L
   }
   ```

   定義されるのは次のもの:

   - `__zoxide_z` などの内部関数
   - `--cmd` で指定した名前（既定 `z`）と、その対話版（`zi`）
   - `PROMPT_COMMAND` へのフック（プロンプトを出すたびに、今のディレクトリをデータベースに加算する）

   **`~/.bashrc` の最後に置く**のは、このフックが他の `PROMPT_COMMAND` 設定に上書きされないようにするため。

   `zi` は内部で `fzf` を呼ぶので、`fzf` が無いとそのサブコマンドだけ失敗する（`z` は動く）。

   </details>

1. zoxide が入ったか確かめ、記録を試すディレクトリへ移る。

   ```bash
   zoxide --version
   command -v zoxide
   cd /usr/share
   ```

   - `command -v zoxide` は、Homebrew なら `/home/linuxbrew/.linuxbrew/bin/zoxide`、dnf なら `/usr/bin/zoxide`
   - **注意**: 対話シェル（端末に貼る）で実行する。スクリプトの中では記録されない（この手順の補足）
   - **次の手順は、プロンプトが戻ってから貼る**（zoxide はプロンプトを出すときに今のディレクトリを記録する。ブラケットペーストで続けて貼ると、プロンプトが出る前に手順 8 が走り、`/usr/share` がまだ無い）

   <details>
   <summary>補足: データベース / 記録されるタイミング</summary>

   学習結果は `~/.local/share/zoxide/db.zo`（バイナリ）に入る。中身は `zoxide query --list`（パスの一覧）や `zoxide query --list --score`（スコア付き）で読める。実機は 5 エントリ、287 バイト:

   ```
   $ ls -l ~/.local/share/zoxide/
   -rw-r--r--. 1 <USER> <USER> 287 Sep 22 18:31 db.zo
   $ zoxide query --list | wc -l
   5
   ```

   特定のパスを忘れさせるには `zoxide remove`（引数はパス）。

   **記録されるのは、対話シェルがプロンプトを出すときだけ**。`zoxide init` が仕込むのは `PROMPT_COMMAND` のフックで、プロンプトを出すときの今のディレクトリを 1 つ記録する。

   - 非対話シェル（スクリプトや `bash -c`）で `cd` しても、データベースは増えない
   - 2026-09-22 の検証コンテナで、当時の確認のブロック（`cd /tmp && cd /usr/share && cd ~` を含む）をスクリプトとして流したときは、`zoxide query --list` の出力が空になった
   - 対話シェルでも、プロンプトが出るまでの間の `cd` は最後の 1 つしか記録されない。ホーム（`$HOME`）は既定で記録しない（`_ZO_EXCLUDE_DIRS` の既定値）
   - ブラケットペーストで貼ると、複数行の貼り付けは 1 つの入力として実行され、プロンプトは最後に 1 回しか出ない
   - そのため、`cd ~` で終わる当時のブロックは、ブラケットペーストの有無にかかわらず何も残さなかった（2026-09-29 に dnf の検証コンテナで確認）。確認を手順 7 と手順 8 に分けたのはこのため

   </details>

1. データベースに記録されたか確かめ、ホームに戻る。

   ```bash
   zoxide query --list
   cd ~
   ```

   - `/usr/share` が出れば動いている
   - 以後は `z share` のように末尾の一部を書けば `/usr/share` に飛ぶ
   - `fzf` を入れた場合は、`zi` で候補を対話的に選べる

---

## 更新

- データベース（`~/.local/share/zoxide/db.zo`）は更新で消えない

1. Homebrew で入れたときは、brew で zoxide を更新する。

   ```bash
   brew upgrade zoxide
   ```

   - すべてまとめて上げるなら `brew upgrade`

1. dnf で入れたときは、dnf で zoxide と fzf を更新する。

   ```bash
   sudo dnf upgrade zoxide fzf
   ```

   - 通常の `sudo dnf upgrade` にも含まれる
   - COPR が新しい版をビルドするまでは上がらない（`Nothing to do.`）

---

## ロールバック

- Homebrew の経路（この節の手順 1）のロールバックは**本実行していない**
- dnf の経路（この節の手順 2・3）と、この節の手順 4・5 は、x86_64 のコンテナで通した

1. Homebrew で入れたときは、brew で zoxide を消す。

   ```bash
   brew uninstall zoxide
   ```

1. dnf で入れたときは、zoxide と fzf を消す。

   ```bash
   sudo dnf remove zoxide fzf
   ```

   - 消えるのはこの 2 つだけ
   - fzf をほかの用途でも使っているなら、`fzf` を外して `zoxide` だけ消す
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. dnf で入れたときは、COPR の登録を消す。

   ```bash
   sudo dnf copr remove kray74/cli-tools
   ```

   - `/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:kray74:cli-tools.repo` が消える
   - COPR の GPG 鍵は `gpg-pubkey-405678bb-69063860` として残る（`rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n'` で確認できる）

1. `~/.bashrc` から初期化の行を消す。

   ```bash
   sed -i '/zoxide init/d' ~/.bashrc          # ~/.bashrc に書いた 1 行を消す
   ```

   - `~/.bashrc` から `zoxide init` の行を消し忘れると、新しいシェルを開くたびに `zoxide: command not found` が出る
     - `ZOXIDE_CMD=cd` にしていた場合は、`cd` が壊れたように見える

1. 学習したディレクトリの履歴も捨てるときだけ、`~/.local/share/zoxide` を消す。

   ```bash
   rm -rf ~/.local/share/zoxide
   ```

   - 履歴は `~/.local/share/zoxide/db.zo` に入っている
   - **残しておけば、入れ直したときにそのまま使える**

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [zoxide](https://github.com/ajeetdsouza/zoxide)（よく行くディレクトリを覚えて短い入力で移動するツール）の最新版を入れる。**EPEL にも AppStream にも RPM が無い**ので、dnf で入れるなら COPR を使う
- **進め方**: Homebrew（既定。x86_64・aarch64）か、x86_64 なら COPR `kray74/cli-tools` の dnf で入れ、`~/.bashrc` に初期化の 1 行を足す。**読者が書き換えるのは冒頭の変数ブロック（コマンド名）だけ**
- **状態**: Homebrew の経路は**実機で本実行済み（2026-09-21）**。dnf の経路は **x86_64 のコンテナのみで検証（2026-09-29）**
  - Homebrew: 下表のホストで `brew install zoxide` を実行し、`~/.bashrc` に `eval "$(zoxide init bash)"` を書いて常用中（データベースに 5 エントリ）
  - **実機の初期化は `--cmd` 無し（コマンド名 `z`）で入れてある**
  - [Homebrew の導入](homebrew.md)と手順 2・6、それに当時の確認のブロック（今の手順 7・8 の元。`brew list --versions zoxide` と `cd /tmp && cd /usr/share && cd ~` を含む 1 つのブロック）は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - 確認したこと（Homebrew）: ボトルが降りる、`~/.bashrc` に書いた初期化で `z` 関数が定義される（`type -t z` → `function`）
  - ただし**非対話シェルでは `cd` が記録されない**ため、そのときの `zoxide query --list` は空だった（[手順 7 の補足](#実施手順)）
  - dnf: 手順 1・3〜8、[更新](#更新)の手順 2、[ロールバック](#ロールバック)の手順 2〜5 を、x86_64 のコンテナで**この文書のコードブロックのまま**、擬似端末の対話シェルに貼って通した（[付録](#付録-dnf-の経路のコンテナでの検証記録2026-09-29)）
  - 確認したこと（dnf）: `includepkgs` で COPR の候補が zoxide と fzf だけになる、鍵の fingerprint、`/usr/bin/zoxide`、`type -t z` → `function`、手順 8 で `/usr/share` が出る、`zi share` で `/usr/share` に移る
  - **確認していないこと**: `ZOXIDE_CMD=cd` の形、Homebrew の経路の `zi`（fzf 連携）、dnf の経路の実機、aarch64 の dnf（COPR に chroot が無い）

| 項目 | 実機 | 検証コンテナ | dnf の検証コンテナ |
|---|---|---|---|
| 実施日 | 2026-09-21 | 2026-09-22 | 2026-09-29 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） | AlmaLinux 10.2 (Lavender Lion) / x86_64（`docker.io/library/almalinux:10`、クラウドホスト上の Docker 29.3.1） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） | 使わない |
| 入った zoxide | `zoxide 0.10.0`（`arm64_linux` ボトル） | 同じ（`0.10.0`） | `zoxide-0.10.0-1.el10.x86_64`（COPR `kray74/cli-tools`） |
| fzf | `fzf 0.74.4`（Homebrew） | 未導入 | `fzf-0.74.4-1.el10.x86_64`（同じ COPR） |
| シェル | bash（`~/.bashrc` に `eval "$(zoxide init bash)"`） | bash（初期化は未設定） | bash（`~/.bashrc` に `eval "$(zoxide init bash --cmd z)"`） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${ZOXIDE_CMD}` | `zoxide init` の `--cmd` に渡す名前。定義されるコマンドが決まる | `z`（既定）/ `cd` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`0.10.0`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| zoxide | 未導入 |
| Homebrew | 7.0.6 導入済み |
| fzf | `brew install yazi ...` の一部として同時に導入（[yazi.md](yazi.md)） |
| EPEL | 有効。ただし `zoxide` は無い |

### 選択した方針

AlmaLinux 10 aarch64 で zoxide を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `zoxide 0.10.0` の `arm64_linux` ボトルがある。upstream の最新リリース（v0.10.0、2026-07-04）と一致 | **採用** |
| EPEL / AppStream / CRB | **`zoxide` というパッケージが無い**（`dnf list --available zoxide` → `Error: No matching Packages to list`） | 使えない |
| 公式 install.sh | `~/.local/bin` にバイナリを 1 つ置く。root 不要で軽いが、更新は自分で再実行する | 不採用（Homebrew に揃える） |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-musl` のビルドがある。展開して PATH に置くだけだが、更新は手作業 | 不採用 |
| `cargo install zoxide` | Rust toolchain（appstream に `rust 1.92.0` あり）が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

dnf で入れる経路は、2026-09-29 に x86_64 も含めて探し直した（EPEL はミラーのディレクトリ一覧とコンテナの `dnf list`、COPR は API とリポジトリのメタデータ）:

| 経路 | x86_64 | aarch64 | 採否 |
|---|---|---|---|
| **COPR `kray74/cli-tools`** | `zoxide-0.10.0-1.el10`（`epel-10-x86_64`）。spec は GitHub で公開、上流の tarball から cargo でビルド。man と補完も入る。同じ COPR の fzf は 0.74.4 | chroot が無い | **採用**（dnf の経路） |
| COPR `shdwchn10/AllTheTools` | `zoxide-0.10.0-1.el10` | `zoxide-0.10.0-1.el10` | 不採用（RPM に補完が無い。同じ COPR の fzf は 0.74.3） |
| COPR `faramirza/epel10` | `zoxide-0.10.0-2.el10` | `zoxide-0.10.0-2.el10` | 不採用（説明が無く、71 本の中に vim・tmux・jq・nano など BaseOS / AppStream と同じ名前のパッケージがある） |
| COPR `ldivizio/tools` | EL10 向けのビルドが無い（`fedora-44-x86_64` だけ） | 無い | 使えない |
| EPEL 10（10.0〜10.4・10z、testing も） | 無い（コンテナで EPEL を有効にしても `No matching Packages to list`） | 無い | 使えない |
| EPEL 9 | `zoxide-0.9.8-2.el9` | 調べていない | 不採用（EL9 向けで、版も古い） |
| Terra（`terrael10`） | 無い | 無い | 使えない |

- **既定は Homebrew のまま**にした。dnf の経路は x86_64 にしか無く、実機（Raspberry Pi 5）は aarch64 のため
- [tool-catalog.md の選び方](tool-catalog.md#選び方)（RPM が Homebrew と同版以上なら RPM）は COPR を RPM に数えないので、一覧の推奨も Homebrew のまま
- dnf で入れると、zoxide は `/usr/bin` に入って `dnf upgrade` で上がり、`sudo` や root のシェルからも見える
- COPR は個人のリポジトリで、Fedora は中身を審査しない（`dnf copr enable` の警告）。更新が止まったら Homebrew に移す

### 完了時点の状態

Homebrew の経路（実機）:

```
$ brew list --versions zoxide
zoxide 0.10.0
$ zoxide --version
zoxide 0.10.0
$ command -v zoxide
/home/linuxbrew/.linuxbrew/bin/zoxide
$ type -t z
function
$ grep -n 'zoxide init' ~/.bashrc
34:eval "$(zoxide init bash)"
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/zoxide/0.10.0/`。データベースは `~/.local/share/zoxide/db.zo`。

dnf の経路（検証コンテナ）:

```
$ rpm -q zoxide fzf
zoxide-0.10.0-1.el10.x86_64
fzf-0.74.4-1.el10.x86_64
$ command -v zoxide
/usr/bin/zoxide
$ type -t z
function
$ grep -n includepkgs /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:kray74:cli-tools.repo
11:includepkgs=zoxide,fzf
```

### 注意点

- **初期化の 1 行が本体**: `brew install` や `dnf install` だけでは `z` は増えない。`~/.bashrc` に `eval "$(zoxide init bash)"` を書き、シェルを開き直す
- **`--cmd cd` は影響範囲が広い**: `cd` を置き換えると、シェル関数やエイリアス経由の `cd` の挙動も変わる。既定の `z` から始めるのが無難
- **root のシェルでは効かない**: 手順 6 の初期化の行は自分の `~/.bashrc` だけにあり、root のシェルでは実行されない（root の `.bashrc` には書かない）。Homebrew の zoxide は、そのままでは `sudo` 経由では見えない（[homebrew.md の注意点](homebrew.md#注意点)。homebrew.md の[root のシェルでも使う](homebrew.md#root-のシェルでも使う任意)・[sudo でも使う](homebrew.md#sudo-でも使う任意)の節は、PATH を足すだけ）。dnf で入れた zoxide は `/usr/bin` にある
- **Homebrew と dnf の両方には入れない**: 両方あると、PATH で先に来る Homebrew の方が使われる。入れ替えるときは先に消す（[実施手順](#実施手順)のリード）
- **`includepkgs` を外さない**: 外すと、同じ COPR の chezmoi などが、EPEL の同じ名前のパッケージを `dnf upgrade` で置き換える（[手順 4 の補足](#実施手順)）
- **学習はプロンプトを出すたびに走る**: `PROMPT_COMMAND` にフックが入り、そのときの今のディレクトリを記録する。プロンプトを自前で組んでいる場合は順序に注意する
- **アンインストール時に行を消し忘れると毎回エラーが出る**: [ロールバック](#ロールバック)の `sed` を忘れない
- **他のツールとの連携**: yazi の `z` キー、fzf の `zi` はこのデータベースを共有する

### 参照

- [ajeetdsouza/zoxide — README](https://github.com/ajeetdsouza/zoxide) — 各 OS のインストール方法、シェルごとの `zoxide init` の書き方、`--cmd` の説明
- [zoxide — Installation](https://github.com/ajeetdsouza/zoxide#installation) — 公式 install.sh と各ディストリビューションの状況
- `zoxide --help` / `zoxide query --help` — `query --list` / `--score`、`remove`
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作
- [kray74/cli-tools — Copr](https://copr.fedorainfracloud.org/coprs/kray74/cli-tools/) — chroot（`epel-10-x86_64` と `fedora-44-x86_64`）とビルドの履歴
- [kray74/cli-tools — GitHub](https://github.com/kray74/cli-tools) — COPR の spec（`zoxide/zoxide.spec`）
- `man dnf.conf` — `includepkgs`

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで、非 root ユーザーを作って[Homebrew の導入](homebrew.md)と手順 2・6・7 を通した（手順 7 は当時の確認のブロックで、今の手順 7・8 の元）。実機で加えた変更は `dnf install podman` だけ。 実行したのは**この文書のコードブロックをそのまま抜き出したスクリプト**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git sudo` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](homebrew.md)） |
| 2. zoxide | `Pouring zoxide--0.10.0.arm64_linux.bottle.tar.gz`。ソースビルドは発生しない |
| 6. 初期化 | `~/.bashrc` に `eval "$(zoxide init bash --cmd z)"` を追記して読み込み直し、`type -t z` → `function` |
| 7. 検証 | `zoxide --version` → `zoxide 0.10.0`。`cd` を 3 回してからの `zoxide query --list` は**空**（非対話シェルでは `PROMPT_COMMAND` のフックが走らないため） |
| fzf | `brew install zoxide fzf` で `fzf 0.74.4` と依存の `ncurses 6.6` も入った |
| RPM 経路 | EPEL を有効にしても `dnf list --available zoxide` は `Error: No matching Packages to list` |

実機側では `type -t z` が `function` を返し、`~/.bashrc` の 34 行目に `eval "$(zoxide init bash)"` があり、データベースに 5 エントリ溜まっていることを確認した（対話シェルでは記録される）。

#### 未確認事項

- `ZOXIDE_CMD=cd`（`--cmd cd`）での動作。実機は `--cmd` 無しで入れてある
- `zi`（fzf 連携）の実動作
- bash 以外のシェル（zsh / fish）での `zoxide init`
- `_ZO_DATA_DIR` などの環境変数による挙動の変更
- ロールバック（`brew uninstall` と `~/.bashrc` の行削除）の本実行

### 付録: dnf の経路のコンテナでの検証記録（2026-09-29）

`docker.io/library/almalinux:10`（AlmaLinux 10.2、x86_64）のコンテナに NOPASSWD の sudo を与えた一般ユーザーを作り、**この文書のコードブロックをそのまま**、擬似端末（pty）で開いた対話の bash に貼って通した。

- `[y/N]` には、プロンプトが出てから `y` を返した
- 通しは、ブロックを 1 行ずつ Enter で送る形（ブラケットペースト無し）で行った。手順 7・8 は、ブロックをブラケットペーストの開始と終了の制御文字で囲んで 1 回で送る形でも通した
- ブラケットペーストの有無の比較（この付録の最後）は、文書を書く前に同じコマンドで zoxide を入れた 1 つ目のコンテナで行った。ブラケットペースト有りは `TERM=xterm-256color`（`bind -v` が `enable-bracketed-paste on`）
- 検証環境だけの変更:
  - ホストの外向きの通信がプロキシ経由なので、dnf にプロキシ（`/etc/dnf/dnf.conf` の `proxy=`）とプロキシの CA を設定した
  - AlmaLinux の repo ファイルは `mirrorlist=` を止め、コメントにある `baseurl=`（`https://repo.almalinux.org/...`）を使った（ミラーリストが返す http のミラーを、プロキシが通さないため）
  - `sudo` と `procps-ng` は先に入れた（コンテナのイメージに無い）

| 手順 | 結果 |
|---|---|
| 前提 | `dnf-4.20.0-22.el10_2.alma.1` と `python3-dnf-plugins-core-4.7.0-10.el10`（`dnf copr` と `dnf config-manager` の本体）は最初から入っていた。`dnf-plugins-core` というパッケージは無いが、要らなかった |
| 3. COPR | 警告文の後の `[y/N]` に `y` → `Repository successfully enabled.`。repo ファイルの `baseurl` は `.../kray74/cli-tools/epel-10-$basearch/` |
| 4. 絞り込み | `11:includepkgs=zoxide,fzf`。COPR から見えるのは zoxide と fzf（と各 `.src`）だけ |
| 5. 導入 | `fzf-0.74.4-1.el10` と `zoxide-0.10.0-1.el10` の 2 つ（2.3 MB）。トランザクションの後に鍵 `0x405678BB` の取り込みを聞かれ、`Key imported successfully` |
| 6. 初期化 | `type -t z` → `function` |
| 7・8. 確認 | `zoxide 0.10.0`、`/usr/bin/zoxide`。手順 8 の `zoxide query --list` → `/usr/share`（ブラケットペーストの有りと無しの両方） |
| `zi` | 1 つ目のコンテナで、`zi share` で fzf が開き、Enter で `/usr/share` に移った |
| 更新の手順 2 | `Nothing to do.`（COPR の最新が 0.10.0 のため） |
| ロールバックの手順 2〜5 | `dnf remove` で消えたのは zoxide と fzf の 2 つだけ。`dnf copr remove` で repo ファイルが消え、鍵 `gpg-pubkey-405678bb-69063860` は残った。`sed` で `~/.bashrc` の行が消え、`~/.local/share/zoxide` も消えた |
| aarch64 | 別のコンテナで、`dnf --forcearch aarch64 copr enable kray74/cli-tools` は `Repository 'epel-10-aarch64' does not exist in project 'kray74/cli-tools'.` で止まり、repo ファイルは作られなかった |
| `includepkgs` | 別のコンテナで EPEL の fzf 0.58.0 と chezmoi 2.72.0 を入れてから COPR を有効にすると、`dnf upgrade --assumeno` の候補は、絞る前は chezmoi 2.72.2 と fzf 0.74.4（どちらも COPR）、絞った後は fzf 0.74.4 だけ |
| EPEL 10 | 別のコンテナで `epel-release` を入れても、`dnf list --available zoxide` は `Error: No matching Packages to list`（fzf 0.58.0・chezmoi 2.72.0 は EPEL にある）。検証環境だけ、EPEL の repo ファイルも `metalink=` を止めて `dl.fedoraproject.org` を直接指した |

**当時の確認のブロックが空になる理由**は、1 つ目のコンテナで確かめた。

- ブラケットペースト無し: `cd /tmp && cd /usr/share && cd ~` は 1 行なので、プロンプトは `~` に戻ってから 1 回だけ出る。ホームは既定で記録しないので、`zoxide query --list` は空
- `cd /tmp`・`cd /usr/share`・`cd ~` を別々の行で入れると、`/tmp` と `/usr/share` が記録された（行ごとにプロンプトが出る）
- ブラケットペースト有り: `cd` を別々の行に書いても、1 回の貼り付けは 1 つの入力として実行され、プロンプトは最後に 1 回しか出ないので空
- 手順 7 と手順 8 に分けて貼ると、手順 7 の後のプロンプトで `/usr/share` が記録された

#### 未確認事項（dnf の経路）

- 実機（x86_64 の PC）での本実行
- aarch64（COPR に chroot が無い）
- `ZOXIDE_CMD=cd` の形
- COPR が次の版を出したときの `dnf upgrade`（検証の時点では 0.10.0 が最新）
