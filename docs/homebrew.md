# Homebrew インストール手順（AlmaLinux 10）

## 実施手順

> [!IMPORTANT]
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew は root で動かない）
> - **実行するユーザーは `sudo` できる必要がある**（手順 1・2 で使う）
> - **手順 2 には対話入力がある**（インストーラの `RETURN` の確認）。終わってから手順 3 を貼る
> - **インターネットに出られないホストでは、本書を直接貼らず [homebrew-offline.md](homebrew-offline.md) から通す**（[ssh-socks-tunnel.md](ssh-socks-tunnel.md) でログインしてくるホストをプロキシにして、そのシェルで本書の手順 1〜4 を貼る）

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 日々の操作は[使い方の基本](#使い方の基本)。以後は[更新](#更新)・[ロールバック](#ロールバック)
- 入れたコマンドを root のシェル（`su -`、root のログイン、`sudo -i`）でも使うなら、[root のシェルでも使う](#root-のシェルでも使う任意)の節を通す
- `sudo <コマンド>` でも使うなら、[sudo でも使う](#sudo-でも使う任意)の節を通す
- 通すと使えるようになる 17 本:
  - [yazi](yazi.md)、[lazygit](lazygit.md)、[Neovim](neovim.md)、[zoxide](zoxide.md)、[bat](bat.md)、[eza](eza.md)、[git-delta](git-delta.md)、[gdu](gdu.md)、[starship](starship.md)、[ShellCheck / shfmt](shellcheck.md)、[tmux](tmux.md)、[fzf](fzf.md)
  - [Syncthing](syncthing.md)、[HackGen Console NF](hackgen.md)、[Dropbox（rclone）](dropbox-rclone.md)、[hadolint / dive / Trivy](image-tools.md)（Trivy だけは dnf）、[lazydocker](lazydocker.md)

1. 依存パッケージを入れる。

   ```bash
   sudo dnf install -y procps-ng curl file git
   ```

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

   - インストーラは続行の確認で `RETURN` を求める
   - 終わりに `==> Installation successful!` と、PATH の通し方を書いた `==> Next steps:` が出る
   - 手順 3 は、その案内と同じ内容（この手順の補足に実測を載せた）
   - **次の手順は、インストーラが終わってから貼る**（続けて貼ると `RETURN` の確認として食われる）

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
   - 自分用の bash の設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）を入れたホストでは、このブロックは貼らない。代わりに `. ~/.bashrc` と `brew --version` を実行する（その設定が同じ 1 行を読む）

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

   この 1 行は、Homebrew で入れたコマンドを使う行（[zoxide](zoxide.md) や [starship](starship.md) の初期化など）より前に置く。それらは、この 1 行が足した `PATH` からコマンドを探すので、後ろにあると `command not found` になる。`PROMPT_COMMAND` には触らないので、ほかの行との順序の制約は無い。

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

- `brew` はどれも **root では動かない**。`sudo brew ...` は、sudo の PATH に Homebrew が無いので `command not found` になる（[sudo でも使う](#sudo-でも使う任意)の節を通した後は、`brew install` などを `brew` が断る）
- 入れたコマンドを root のシェルでも使うなら [root のシェルでも使う](#root-のシェルでも使う任意)の節を、`sudo <コマンド>` で使うなら [sudo でも使う](#sudo-でも使う任意)の節を通す

---

## root のシェルでも使う（任意）

- **root のシェルで Homebrew のコマンドを使わないなら、この節は不要**
- root の `~/.bashrc`（`/root/.bashrc`）で、PATH の末尾に Homebrew の `bin` と `sbin` を足す
- `su -`、コンソールや ssh での root のログイン、`sudo -i` で開いた root のシェルで使えるようになる
- `sudo <コマンド>` は対象外（sudo の `secure_path` の PATH で動き、root の `~/.bashrc` を読まない）。[sudo でも使う](#sudo-でも使う任意)の節で使えるようにする
- RPM にも同じ名前のコマンドがあると、root のシェルでは RPM のほうが使われる
- `brew` そのものは、この節を通しても root では動かない（`brew install` などは `Running Homebrew as root is extremely dangerous …` で断られる）
- 手順 1〜4 を終えた、Homebrew を入れたユーザーのシェルで貼る
- 補足: [root のシェルで使うときの補足](#root-のシェルで使うときの補足)

> [!WARNING]
> - `/home/linuxbrew/.linuxbrew` は Homebrew を入れたユーザーの所有。root がここのコマンドを動かすと、そのユーザーが書き換えられるプログラムを root の権限で動かすことになる（そのユーザーを乗っ取られると、root まで取られる）
> - この節は **x86_64 のコンテナでのみ検証した**。実機では本実行していない（[付録](#付録-root-のシェルでも使う節のコンテナでの検証記録2026-09-30)）

1. root の `~/.bashrc` の末尾に PATH を足す 1 行を書き、root のログインシェルで確かめる。

   ```bash
   {
     if sudo grep -q '/home/linuxbrew/.linuxbrew/bin' /root/.bashrc; then echo '中断: /root/.bashrc に既にある' >&2
     else
       sudo tee -a /root/.bashrc >/dev/null <<'EOF'
   case ":${PATH}:" in *:/home/linuxbrew/.linuxbrew/bin:*) ;; *) PATH="${PATH}:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin" ;; esac
   EOF
       sudo tail -n 1 /root/.bashrc
     fi
     sudo -i bash -c 'printenv PATH; command -v brew'
   }
   ```

   - 書いた 1 行（`case ":${PATH}:" in …`）が出る
   - 最後の 2 行で、PATH の末尾が `:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin` で、`/home/linuxbrew/.linuxbrew/bin/brew` が出ればよい
   - `中断:` と出たら、何も書き換えていない（最後の 2 行は出る）
   - `su -`、コンソールや ssh での root のログインも、`sudo -i` と同じく `/root/.bash_profile` から `/root/.bashrc` を読む（コンソールでのログインは未確認）
   - 開いたままの root のシェルには効かない。開き直すか、そのシェルで `. ~/.bashrc` を実行する
   - root のシェルでどれが使われるかは、`type -a <コマンド>` で見る（先頭の行が使われる）
   - [sudo でも使う](#sudo-でも使う任意)の節を通したホストでは、`/root/.bashrc` に書く前から最後の 2 行が同じ出力になる（`sudo -i` の PATH の末尾の 2 つは、sudo の `secure_path` から来る）
     - この節の行が効いたかは、`sudo su - -c 'printenv PATH; command -v brew'` で見る

   <details>
   <summary>補足: 書く 1 行と、出力例</summary>

   - PATH の**末尾**に足すので、`/usr/bin` などにある RPM のコマンドが先に見つかる。root の `git` や `curl` などが、Homebrew が依存として入れたものに置き換わらない
   - `case` は、PATH に `/home/linuxbrew/.linuxbrew/bin` が既にあれば何もしない。root のシェルの中で `bash` を開いても、同じ場所が重ならない
   - `sbin` も足すのは、`brew shellenv` が PATH に足すのと同じ 2 つにそろえるため
   - 自分の `~/.bashrc`（手順 3）と違い、`brew shellenv` は使わない。`brew shellenv` は PATH の**先頭**に足すので RPM のコマンドが隠れるうえ、root のシェルを開くたびに、Homebrew のユーザーが所有する `brew` を root で動かす
   - ヒアドキュメントは引用符付きの `<<'EOF'` なので、`${PATH}` は書くときに展開されず、そのまま入る
   - AlmaLinux 10 の `/root/.bashrc`（rootfiles の既定）には、非対話のシェルで途中で抜ける行が無い。末尾の行は、`sudo -i <コマンド>` や `su - -c <コマンド>` でも読まれる

   **出力例**: 最後の行の、コンテナでの実測（Homebrew のユーザーのシェルから）:

   ```
   $ sudo -i bash -c 'printenv PATH; command -v brew'
   /root/.local/bin:/root/bin:/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin
   /home/linuxbrew/.linuxbrew/bin/brew
   ```

   `/root/.bashrc` に書く前は、1 行目が `/root/.local/bin:/root/bin:/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin` で終わり、2 行目は出なかった（終了コード 1）。

   </details>

1. 元に戻すときは、root の `~/.bashrc` から、この節の手順 1 で書いた 1 行を消す。

   ```bash
   {
     sudo sed -i '\#/home/linuxbrew/.linuxbrew/bin#d' /root/.bashrc
     sudo grep -c /home/linuxbrew /root/.bashrc   # 0
   }
   ```

   - 最後に `0` と出ればよい
   - 開いたままの root のシェルの PATH には残る。開き直すと消える
   - [sudo でも使う](#sudo-でも使う任意)の節も通していれば、`sudo -i`・`sudo -s` のシェルには、その節の 2 つが残る

---

## sudo でも使う（任意）

- **`sudo <コマンド>` で Homebrew のコマンドを使わないなら、この節は不要**
- sudo の設定に 1 行のファイル（`/etc/sudoers.d/homebrew`）を置き、sudo がコマンドを探す PATH（`secure_path`）の末尾に、Homebrew の `bin` と `sbin` を足す
- `sudo nvim /etc/hosts` や `sudo gdu-go /` のように、`sudo <コマンド>` で使えるようになる。`sudo -s`・`sudo -i` で開いた root のシェルでも使える
- `EDITOR=nvim` の `sudoedit` も、自分の設定の Homebrew の `nvim` で開くようになる（この節の前は、黙って `vi` で開く）
- sudo を通らない `su -`、コンソールや ssh での root のログインには効かない。そちらは [root のシェルでも使う](#root-のシェルでも使う任意)の節を通す
- RPM にも同じ名前のコマンドがあると、`sudo` では RPM のほうが使われる
- `brew` そのものは、この節を通しても root では動かない（`sudo brew install` などは `Running Homebrew as root is extremely dangerous …` で断られる）
- 手順 1〜4 を終えた、Homebrew を入れたユーザーのシェルで貼る
- 補足: [sudo で使うときの補足](#sudo-で使うときの補足)

> [!WARNING]
> - `/home/linuxbrew/.linuxbrew` は Homebrew を入れたユーザーの所有。`sudo` で打ったコマンドが `/usr/bin` などに無いと、そのユーザーが書き換えられるプログラムを root の権限で動かすことになる（そのユーザーを乗っ取られると、root まで取られる）
> - sudo の設定はホスト全体にかかる。このホストで `sudo` を使う、ほかのユーザーにも効く
> - この節は **x86_64 のコンテナでのみ検証した**。実機では本実行していない（[付録](#付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)）

1. sudo の `secure_path` の末尾に Homebrew を足すファイルを置き、`sudo` の PATH を確かめる。

   ```bash
   {
     if sudo printenv PATH | grep -q /home/linuxbrew; then echo '中断: sudo の PATH に Homebrew が既にある' >&2
     elif [ "$(sudo printenv PATH)" != /sbin:/bin:/usr/sbin:/usr/bin ]; then echo '中断: sudo の PATH が AlmaLinux 10 の既定（/sbin:/bin:/usr/sbin:/usr/bin）と違う' >&2
     else
       line='Defaults secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin'
       echo "${line}" | sudo visudo -cf - && echo "${line}" | sudo install -m 0440 /dev/stdin /etc/sudoers.d/homebrew
       sudo visudo -c
     fi
     sudo bash -c 'printenv PATH; command -v brew'
   }
   ```

   - `stdin: parsed OK`・`/etc/sudoers: parsed OK`・`/etc/sudoers.d/homebrew: parsed OK` の 3 行が出る
     - `/etc/sudoers.d` にほかのファイルがあれば、その行も出る
     - 日本語のロケール（`ja_JP.UTF-8`）では、`parsed OK` は `正しく構文解析されました` と出る
   - 最後の 2 行で、PATH の末尾が `:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin` で、`/home/linuxbrew/.linuxbrew/bin/brew` が出ればよい
   - `中断:` と出たら、何も書き換えていない（最後の 2 行は出る）
     - `既にある` なら、この節は通してある。最後の 2 行で確かめる
     - `既定と違う` なら、`secure_path` がほかで変えてある（`sudo grep -rn secure_path /etc/sudoers /etc/sudoers.d` で探す）。そのホストでは、この節は使わない
   - Homebrew で入れたコマンドを、`sudo jq --version` のように打てる
   - `sudo` でどれが使われるかは、`sudo bash -c 'type -a <コマンド>'` で見る（先頭の行が使われる）
   - 開いたままの root のシェル（`sudo -s` など）には効かない。開き直す

   <details>
   <summary>補足: 置く 1 行と置き方、出力例</summary>

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

   </details>

1. 元に戻すときは、この節の手順 1 で置いたファイルを消す。

   ```bash
   {
     sudo rm -f /etc/sudoers.d/homebrew
     sudo printenv PATH   # /sbin:/bin:/usr/sbin:/usr/bin
   }
   ```

   - 最後に `/sbin:/bin:/usr/sbin:/usr/bin` と出ればよい
   - 開いたままの root のシェル（`sudo -s` など）の PATH には残る。開き直すと消える
   - [root のシェルでも使う](#root-のシェルでも使う任意)の節も通していれば、root のシェル（`sudo -i` も）には、その節の 2 つが残る

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
   - `[y/n]` と聞かれたら、`y` を押す（Enter は要らない。[注意点](#注意点)）

---

## ロールバック

- 本書ではロールバックは**本実行していない**（`--help` でオプションを確かめただけ。[付録](#付録-コンテナでの検証記録2026-09-22)）
- 各ツールが `~/.bashrc` や `~/.config` に書いた設定は残る。それぞれの手順書のロールバックも見る
- [root のシェルでも使う](#root-のシェルでも使う任意)の節を通したなら、先にその節の手順 2 で root の `~/.bashrc` の行を消す
- [sudo でも使う](#sudo-でも使う任意)の節を通したなら、先にその節の手順 2 で `/etc/sudoers.d/homebrew` を消す
- インターネットに出られないホストでは、[ssh-socks-tunnel.md 手順 1〜3](ssh-socks-tunnel.md#実施手順) でトンネルを張ったシェルで貼る（この節の手順 1 がアンインストーラを取得する）

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

   - 確認を聞かれる
   - `/home/linuxbrew` 自体は `uninstall.sh` が消す（`--path` で変えられる）
   - **次の手順は、アンインストーラが終わってから貼る**（続けて貼ると確認として食われる）

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
  - **このリポジトリの Homebrew 系 17 本の手順書は、すべてこれを前提にしている**（実機に入っているのはそのうちの一部で、記録時点の `brew leaves` は 15 件。下表）
  - 本書の手順 1〜4 と[使い方の基本](#使い方の基本)・[更新](#更新)は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - 確認したこと: `Homebrew 7.0.6` が同じ場所に入る、`brew config` の `HOMEBREW_PREFIX` が一致する、`brew install jq` がボトルで入る
  - **本実行していないこと**: ロールバック（`uninstall.sh` の本実行）。実機でもコンテナでも実行していない（`--help` を見ただけ）
  - **実機の `~/.bashrc` の 1 行は `brew shellenv`（引数なし）で、本書が書く `brew shellenv bash` と違う**（[手順 3 の補足](#実施手順)）
  - [root のシェルでも使う](#root-のシェルでも使う任意)の節は、**x86_64 のコンテナでのみ検証した**（2026-09-30。[付録](#付録-root-のシェルでも使う節のコンテナでの検証記録2026-09-30)）
    - 通したこと: その節の手順 1・2 を、この文書のコードブロックのまま流した。その節の手順 1 の `if … fi`（もとの手順 1）を重ねて実行し、その節の手順 2 の後に手順 1 をもう一度通した
    - 確認したこと: `su -`（root のパスワード）・`su`・ssh での root のログイン・`sudo -i`・`sudo -s` のどれでも Homebrew の `jq` と `nvim` が見つかる、`sudo jq` は見つからない、RPM の `jq` があると root では RPM が先、手順 2 で `/root/.bashrc` が元のファイルと同じ内容に戻る
    - 確認していないこと: 実機、aarch64、コンソールでの root のログイン、SELinux が Enforcing のホスト
    - 2026-10-02: その節のもとの手順 1・2 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）
  - [sudo でも使う](#sudo-でも使う任意)の節は、**x86_64 のコンテナでのみ検証した**（2026-10-02。[付録](#付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)）
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
| 各ツールの公式インストーラ / GitHub Releases | バイナリ 1 つで軽いが、**ツールごとに更新方法が違う**。17 本ぶん覚えることになる | 不採用（Homebrew に揃える） |
| `cargo install` / `go install` | toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

**Homebrew に揃える判断の実質は「更新の一元化」**。`brew upgrade` 1 本で、17 本の手順書で Homebrew から入れたものがまとめて上がる。

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

[root のシェルでも使う](#root-のシェルでも使う任意)の節の補足。実測は x86_64 のコンテナで、その節の手順 1 の後のもの（[付録](#付録-root-のシェルでも使う節のコンテナでの検証記録2026-09-30)）。

| 入口 | 読むファイル | Homebrew のコマンド |
|---|---|---|
| `su -`、ssh での root のログイン | `/etc/profile` → `/root/.bash_profile` → `/root/.bashrc` | 使える（PATH の末尾） |
| `sudo -i` | 同上。PATH の始まりは sudo の `secure_path` | 使える（PATH の末尾） |
| `sudo -s`、`su`（`-` 無し） | `/root/.bashrc`（`sudo -s` でも `HOME` は `/root`） | 使える（PATH の末尾） |
| `sudo <コマンド>` | 読まない。PATH は `secure_path` の `/sbin:/bin:/usr/sbin:/usr/bin` | 使えない（`sudo: jq: command not found`）。[sudo でも使う](#sudo-でも使う任意)の節で使える |

- **`su`（`-` 無し）も、Homebrew のユーザーの PATH を引き継がない**: PATH は root のものに置き換わり、その末尾に足される
- **cron や systemd の unit では見えない**: `~/.bashrc` を読まないため（[注意点](#注意点)の「`~/.bashrc` を読まない文脈」と同じ）。フルパスで書く
- **RPM と同じ名前のコマンドは、root では RPM が先**: AppStream の `jq` も入れると、`type -a jq` の並びが root と Homebrew のユーザーで逆になる

  ```
  # root のシェル
  jq is /bin/jq
  jq is /usr/bin/jq
  jq is /home/linuxbrew/.linuxbrew/bin/jq
  # Homebrew のユーザーのシェル
  jq is /home/linuxbrew/.linuxbrew/bin/jq
  jq is /usr/bin/jq
  jq is /bin/jq
  ```

  root で Homebrew 版を使うときは、フルパス（`/home/linuxbrew/.linuxbrew/bin/<コマンド>`）で呼ぶ
- **`brew` は root では断られる**: PATH で見つかるが、`brew install` などは `Error: Running Homebrew as root is extremely dangerous and no longer supported.` で止まる（終了コード 1）
  - 断られなかったのは `brew --version`・`brew --prefix`・`brew help`・引数の無い `brew list` だけ。[使い方の基本](#使い方の基本)の表のコマンドは、どれも断られた
  - コンテナの中（`/.dockerenv` か `/run/.containerenv` がある、または `/proc/1/cgroup` に `docker` などがある）では断られない（`brew.sh` の `check-run-command-as-root`）。検証では、これらを外したコンテナで確かめた
- **設定ファイルは root のものを読む**: root で動かした Neovim の `stdpath("config")` は `/root/.config/nvim` だった。自分の `~/.config` の設定は使われない
- **シェルの初期化は `/root/.bashrc` に足さない**: [zoxide](zoxide.md) や [starship](starship.md) の `eval "$(… init bash)"` を書くと、root のシェルを開くたびに、Homebrew のユーザーが所有するコマンドが root で動く
- **この節では sudo の `secure_path` を変えない**: [root のシェルでも使う](#root-のシェルでも使う任意)の節は、root のシェルが対象。`sudo <コマンド>` で使うときは、[sudo でも使う](#sudo-でも使う任意)の節を通すか、フルパスで渡す（`sudo /home/linuxbrew/.linuxbrew/bin/jq --version` は `jq-1.8.2` を返した）

### sudo で使うときの補足

[sudo でも使う](#sudo-でも使う任意)の節の補足。実測は x86_64 のコンテナで、その節の手順 1 の後のもの（[付録](#付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)）。

| 入口 | PATH | Homebrew のコマンド |
|---|---|---|
| `sudo <コマンド>`、`sudo -u <ユーザー> <コマンド>`、`sudo bash <スクリプト>` | `secure_path`（`/sbin:/bin:/usr/sbin:/usr/bin` の後ろに 2 つ） | 使える（`sudo jq --version` は `jq-1.8.2`） |
| `sudo -E <コマンド>` | 同上（`-E` でも、自分の PATH は渡らない） | 使える |
| `sudo -s` | `/root/.local/bin:/root/bin` の後ろに `secure_path` | 使える（PATH の末尾） |
| `sudo -i` | `/root/.local/bin:/root/bin:/usr/local/sbin` の後ろに `secure_path` | 使える（PATH の末尾） |
| `sudoedit`（`EDITOR=nvim`） | エディタを `secure_path` で探し、自分のユーザーと自分の環境で動かす | Homebrew の `nvim`。設定は自分の `~/.config/nvim` |
| `sudo EDITOR=nvim visudo` | エディタを `secure_path` で探し、root で動かす | Homebrew の `nvim`。設定は `/root/.config/nvim` |
| `su -`、`sudo su -`、ssh での root のログイン | sudo の `secure_path` を通らない | 使えない（[root のシェルでも使う](#root-のシェルでも使う任意)の節で使える） |

- **RPM と同じ名前のコマンドは、`sudo` でも RPM が先**: AppStream の `jq-1.7.1` も入れると、`sudo jq --version` は RPM の `jq-` を返した。`sudo bash -c 'type -a jq'` は `/bin/jq` → `/usr/bin/jq` → Homebrew の順。`sudo` で Homebrew 版を使うときは、フルパスで呼ぶ
- **依存として入ったコマンドも `sudo` で動く**: 検証では `jq`・`neovim`・`gdu`・`glib` と依存で 231 個のコマンドが入った
  - RPM と同じ名前の 135 個（`glib` の依存の util-linux の `fdisk` など）は、RPM が先
  - 残りの 96 個（`python3.14`・`sqlite3` など）が、`sudo` で動くようになった
- **`sudo` を使う、ほかのユーザーにも効く**: 自分の PATH に Homebrew の無い、別の wheel のユーザーでも、`sudo jq --version` は `jq-1.8.2` を返した
- **設定ファイルは root のものを読む**: `sudo nvim` の `stdpath("config")` は `/root/.config/nvim` だった（root のシェルと同じ）
- **`sudoedit` と `visudo` は、この節の前は黙って `vi` で開いた**: エディタを `secure_path` で探し、見つからないと `/usr/bin/vi` を使う。`EDITOR=nvim` の `sudoedit /etc/motd` も `sudo EDITOR=nvim visudo` も、エラーを出さずに `/usr/bin/vi` だった
  - `sudo visudo` は、`EDITOR` を export していても、この節の後も `/usr/bin/vi` だった（sudo が `EDITOR` を渡さない）。`nvim` で開くなら `sudo EDITOR=nvim visudo` と打つ
- **`sudoedit` だけなら、この節は要らない**: `SUDO_EDITOR=/home/linuxbrew/.linuxbrew/bin/nvim sudoedit <ファイル>` は、この節の前でも Homebrew の `nvim` を自分のユーザーで開き、`stdpath("config")` は自分の `~/.config/nvim` だった
- **`brew` は root では断られる**: `sudo brew install tree` は `Error: Running Homebrew as root is extremely dangerous and no longer supported.`（終了コード 1）。`sudo brew --version` は動いた
  - `brew services` は root の断りから外されている（`brew.sh` の `check-run-command-as-root`）。ただし `sudo brew services list` は `Error: Need to download https://formulae.brew.sh/api/internal/packages.x86_64_linux.jws.json but cannot as root!` で止まった（自分のユーザーで `brew update` した後も同じ）
- **[root のシェルでも使う](#root-のシェルでも使う任意)の節と両方通してもよい**: `/root/.bashrc` の `case` が足さないので、`sudo -i`・`sudo -s` の PATH で 2 つは重ならなかった。片方を戻しても、もう一方の 2 つは残る
- **採らなかった形**
  - `sudo -E`: PATH は `secure_path` に置き換わる（`sudo -E printenv PATH` は、この節の前は `/sbin:/bin:/usr/sbin:/usr/bin`）
  - `alias sudo='sudo env PATH="$PATH"'`: 自分の PATH を丸ごと渡すので、Homebrew が先頭になる。RPM の `jq` があっても、`sudo env PATH="$PATH" jq --version` は Homebrew の `jq-1.8.2` を返した
  - `/usr/local/bin` や `~/.local/bin` にリンクを張る: どちらも AlmaLinux 10 の `secure_path` に無い。`~/.local/bin/gdu` のリンク（[gdu.md の「gdu の名前で呼ぶ」](gdu.md#gdu-の名前で呼ぶ任意)）は、この節を通しても `sudo gdu` で `command not found` だった
- **Homebrew を消す前に、この節を戻す**: 公式のアンインストーラ（`uninstall.sh`）は `/etc/sudoers.d` に触れない（中に `sudoers` の文字が無い）。残すと、`secure_path` に `/home/linuxbrew/.linuxbrew/bin` が残る

### 注意点

- **root で実行しない**: インストーラも `brew` も root を拒否する。ただし**実行するユーザーが `sudo` できる必要がある**（`/home/linuxbrew` を作るため）
- **導入先を変えるとすべてソースビルドになる**: [手順 2 の補足](#実施手順)
- **PATH の先頭が Homebrew になる**: `brew shellenv` は `/home/linuxbrew/.linuxbrew/bin` を `PATH` の**先頭**に足す。同じ名前の RPM が入っていると Homebrew 版が勝つ（[bat](bat.md) / [gdu](gdu.md) で実際に問題になる）
- **`sudo <tool>` は、そのままでは使えない**: sudo の PATH（`secure_path`）にも root の `PATH` にも、Homebrew は入っていない
  - `sudo <tool>` で使うなら、[sudo でも使う](#sudo-でも使う任意)の節を通す（`sudo -s`・`sudo -i` のシェルでも使えるようになる）
  - root のシェル（`su -`、root のログイン、`sudo -i`）で使うなら、[root のシェルでも使う](#root-のシェルでも使う任意)の節を通す
  - どちらも通さないなら、RPM で入れるか、フルパス（`/home/linuxbrew/.linuxbrew/bin/<tool>`）を渡す
- **依存が付く `brew install` は、端末では `[y/n]` を聞く**（Homebrew 7.0.7 の ask mode）: 入れるものの一覧の後に `==> Do you want to proceed with the installation? [y/n]` と聞き、答えは Enter を待たずに 1 文字で読む（[homebrew-offline.md 手順 4](homebrew-offline.md#実施手順) の補足の実測）
  - 同じブロックに後ろの行があると、その文字が答えとして読まれ、`n` で中止になる。各手順書の `brew install` は、`[y/n]` に答えてから次の手順を貼る
  - Homebrew の説明では `brew upgrade` でも聞く（上げるものがあったときの表示は確かめていない）。聞かせないなら `HOMEBREW_NO_ASK=1`
- **`~/.bashrc` を読まない文脈では見えない**: cron や一部の非対話シェルでは `brew shellenv` が走らないので、Homebrew で入れたコマンドが見つからない。スクリプトからはフルパスで呼ぶ
- **ユーザーごとではなく、ホストに 1 つ**: `/home/linuxbrew` は共有なので、別ユーザーが使うにはそのユーザーの `~/.bashrc` にも `brew shellenv` を書く（書き込みには所有者の権限が要る）
- **占有が大きい**: 実機で 2.8 GB。`brew cleanup` で古い版とキャッシュを掃除できる
- **匿名の利用統計が既定で有効**: 止めるなら `brew analytics off`

### 参照

- [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux) — `/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、要件
- [brew.sh](https://brew.sh/) — インストーラのワンライナーと概要
- [Homebrew — FAQ](https://docs.brew.sh/FAQ) — 更新・掃除・アンインストールのよくある質問
- [Homebrew/install](https://github.com/Homebrew/install) — `install.sh` と `uninstall.sh` の中身
- `man sudoers`（`secure_path`、`#includedir` で読まれないファイル名、`Defaults` の上書き）・`man visudo`（`-c`、`-f`） — [sudo でも使う](#sudo-でも使う任意)の節の 1 行と確かめ方
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

### 付録: root のシェルでも使う節のコンテナでの検証記録（2026-09-30）

[root のシェルでも使う（任意）](#root-のシェルでも使う任意)を足したときの記録。x86_64 のクラウドホスト上の Docker 29.3.1（cgroup v1）で、使い捨てのコンテナを立てて行った。実機で加えた変更は無い。

**環境**:

- `quay.io/almalinuxorg/almalinux:10`（AlmaLinux 10.2）を `--network host` で立て、プロキシの CA、dnf の `proxy=`、`almalinux-*.repo` の `baseurl=` を入れた
- `sudo`・`passwd`・`openssh-server` などを dnf で入れ、NOPASSWD の `sudo` を持つ非 root ユーザー（`<USER>`）を作った。root には、検証のためだけにパスワードを付けた
- Homebrew は[実施手順](#実施手順)の手順 1〜3 を、インストーラだけ `NONINTERACTIVE=1` を付けて通した（`Homebrew 7.0.7`）。`brew install jq` と `brew install neovim` で、`jq 1.8.2` と `neovim 0.12.5_1` を入れた
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

[sudo でも使う（任意）](#sudo-でも使う任意)を足したときの記録。x86_64 のクラウドホスト上の Docker 29.6.2（cgroup v1）で、使い捨てのコンテナを立てて行った。実機で加えた変更は無い。

**環境**:

- `quay.io/almalinuxorg/10-init`（AlmaLinux 10.2、`sha256:a91c1066…fd73`）を `--privileged --cgroupns=private --network host` で立て、systemd を PID 1 にして、sshd（ポート 2222）と systemd-logind を動かした
- プロキシの CA、dnf の `proxy=`、`almalinux-*.repo` の `baseurl=`、ログインシェルの `HTTPS_PROXY` を入れた
- wheel の一般ユーザーを 2 人（`<USER>`・`<USER2>`）作った。どちらの `sudo` も、既定の `%wheel ALL=(ALL) ALL` のまま。root には、検証のためだけにパスワードを付けた
- Homebrew は、`<USER>` の ssh のログインシェル（umask 0022）で[実施手順](#実施手順)の手順 1〜3 を通した
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
| 各入口 | [sudo で使うときの補足](#sudo-で使うときの補足)の表のとおり。`sudo -s` は `HOME=/root`。`sudo -u nobody jq --version` は `jq-1.8.2`。`sudo su - -c 'printenv PATH'`・`su -`（root のパスワード）・ssh での root のログインは `/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin` で、`jq` は見つからない |
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
