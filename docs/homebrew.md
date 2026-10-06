# Homebrew インストール手順（AlmaLinux 10）

## 実施手順

- [検証記録](verification/homebrew.md)・[参考資料](reference/homebrew.md)

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（通常のホストでは、インストーラや `brew install` などの管理操作は root を拒否する）
> - **実行するユーザーは `sudo` できる必要がある**（手順 1・2 で使う）
> - **手順 2 には対話入力がある**（インストーラの `RETURN` の確認）。終わってから手順 3 を貼る
> - **インターネットに出られないホストでは、本書を直接貼らず [homebrew-offline.md](homebrew-offline.md) から通す**（[ssh-socks-tunnel.md](ssh-socks-tunnel.md) でログインしてくるホストをプロキシにして、そのシェルで本書の手順 1〜4 を貼る）

- 上から順にコードブロックを貼る
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

1. 公式のインストーラを実行する。

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

   - インストーラは続行の確認で `RETURN` を求める
   - 終わりに `==> Installation successful!` と、PATH の通し方を書いた `==> Next steps:` が出る
   - **次の手順は、インストーラが終わってから貼る**（続けて貼ると `RETURN` の確認として食われる）

1. 共通設定を読み直し、Homebrew の PATH を有効にする。

   ```bash
   . ~/.bashrc
   brew --version
   ```

   - `brew shellenv` は共通設定が実行する。インストーラの `Next steps` に出る `~/.bashrc` への追記も行わない

1. Homebrew が入ったか確かめる。

   ```bash
   brew --version
   command -v brew
   ls -d /home/linuxbrew/.linuxbrew
   brew config | head -12
   ```

   - `command -v brew` が `/home/linuxbrew/.linuxbrew/bin/brew` を返す
   - `brew config` の `HOMEBREW_PREFIX` が `/home/linuxbrew/.linuxbrew` ならよい

---

## 使い方の基本

各手順書が使うコマンドはこれだけ。

| コマンド | 用途 |
|---|---|
| `brew install <formula>` | 入れる。ビルド済みのボトルがあれば `Pouring ...` と出て、ソースビルドは走らない |
| `brew uninstall <formula>` | 消す。Homebrew 7.0.7 では、不要になった依存も既定で自動削除する（[注意点](#注意点)） |
| `brew list --versions` | 入っているものと版の一覧 |
| `brew leaves` | ほかの導入済み formula や cask から依存されていない formula の一覧。明示的に入れたものの履歴ではない |
| `brew info <formula>` | 版・依存・caveat（[gdu](gdu.md) のような名前の注意書き） |
| `brew deps --tree <formula>` | 依存の木。単独で入れたときに何が付いてくるか |
| `brew outdated` | 更新できるものの一覧。何も無ければ無出力 |
| `brew autoremove` | 依存として入って、もう誰も使っていないものを消す（`--dry-run` で確認できる） |

- `brew install`・`brew upgrade` などの管理操作は、Homebrew を入れた一般ユーザーで行う。通常のホストでは root での実行を断られる（`brew --version` などの例外は[root のシェルで使うときの補足](reference/homebrew.md#root-のシェルで使うときの補足)）
- `sudo brew ...` は、sudo の PATH に Homebrew が無ければ `command not found` になる。[sudo でも使う](#sudo-でも使う任意)の節を通しても、管理操作は一般ユーザーで行う
- 入れたコマンドを root のシェルでも使うなら [root のシェルでも使う](#root-のシェルでも使う任意)の節を、`sudo <コマンド>` で使うなら [sudo でも使う](#sudo-でも使う任意)の節を通す
- Homebrew 7.0.7 の `brew install` は、端末で依存や依存先も導入する計画なら `[y/n]` を聞く。指定したものだけの計画、または端末を使わない実行では聞かない（[注意点](#注意点)）

---

## root のシェルでも使う（任意）

- root でも使う場合は、[bash の root 用導入手順](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#root-のシェルでも読む任意)で root 自身の clone と読み込み口を用意する
- 自分専用のマシンで、一般ユーザーを信用できる場合だけ行う。root のシェルから Homebrew のユーザー所有のコマンドを実行するため
- 共通設定の `brew shellenv` は Homebrew を PATH の先頭に入れる。同名の RPM コマンドより Homebrew が優先される
- `sudo <コマンド>` は別で、次の「sudo でも使う」の `secure_path` を使う

1. root のログインシェルから Homebrew が見えることを確かめる。

   ```bash
   sudo -i bash -c 'printenv PATH; command -v brew'
   ```

   - `/home/linuxbrew/.linuxbrew/bin/brew` が出ればよい。`/root/.bashrc` に PATH の行は追記しない
   - `brew install` などは一般ユーザーで行う

1. root の共通設定も外す場合だけ、bash のロールバックを行う。

   - [root の導入手順](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#root-のシェルでも読む任意)のロールバックを参照する
   - Homebrew 自体を削除した場合は、共通設定が自動で読み込みを省略する

---

## sudo でも使う（任意）

- **`sudo <コマンド>` で Homebrew のコマンドを使わないなら、この節は不要**
- sudo の設定に 1 行のファイル（`/etc/sudoers.d/homebrew`）を置き、sudo がコマンドを探す PATH（`secure_path`）の末尾に、Homebrew の `bin` と `sbin` を足す
- `sudo nvim /etc/hosts` や `sudo gdu-go /` のように、`sudo <コマンド>` で使えるようになる。`sudo -s`・`sudo -i` で開いた root のシェルでも使える
- `EDITOR=nvim` の `sudoedit` も、自分の設定の Homebrew の `nvim` で開くようになる（この節の前は、黙って `vi` で開く）
- sudo を通らない `su -`、コンソールや ssh での root のログインには効かない。そちらは [root のシェルでも使う](#root-のシェルでも使う任意)の節を通す
- RPM にも同じ名前のコマンドがあると、`sudo` では RPM のほうが使われる
- `brew install` などの管理操作は、この節を通しても一般ユーザーで行う（通常のホストでは `sudo brew install` などを `Running Homebrew as root is extremely dangerous …` で断られる）
- 手順 1〜4 を終えた、Homebrew を入れたユーザーのシェルで貼る
- 補足: [sudo で使うときの補足](reference/homebrew.md#sudo-で使うときの補足)

> [!WARNING]
> - `/home/linuxbrew/.linuxbrew` は Homebrew を入れたユーザーの所有。`sudo` で打ったコマンドが `/usr/bin` などに無いと、そのユーザーが書き換えられるプログラムを root の権限で動かすことになる（そのユーザーを乗っ取られると、root まで取られる）
> - sudo の設定はホスト全体にかかる。このホストで `sudo` を使う、ほかのユーザーにも効く

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

- 各ツールが `~/.bashrc` や `~/.config` に書いた設定は残る。それぞれの手順書のロールバックも見る
- root の共通設定も外したい場合だけ、[root のシェルでも使う](#root-のシェルでも使う任意)の手順 2 を行う。Homebrew の削除だけなら、共通設定は残してよい
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

1. アンインストーラを消して、端末を開き直す。

   ```bash
   rm -f /tmp/uninstall.sh
   ```

   - 共通設定は Homebrew が無ければ何もしない。`~/.bashrc` の編集は不要

---

## 注意点

- **導入・更新は一般ユーザーで行う**: 通常のホストでは、インストーラや `brew install` などの管理操作は root を拒否する。ただし**実行するユーザーが `sudo` できる必要がある**（`/home/linuxbrew` を作るため）
- **導入先を変えるとすべてソースビルドになる**: [手順 2 の補足](#実施手順)
- **PATH の先頭が Homebrew になる**: `brew shellenv` は `/home/linuxbrew/.linuxbrew/bin` を `PATH` の**先頭**に足す。同じ名前の RPM が入っていると Homebrew 版が勝つ（[bat](bat.md) / [gdu](gdu.md) で実際に問題になる）
- **`sudo <tool>` は、そのままでは使えない**: sudo の PATH（`secure_path`）にも root の `PATH` にも、Homebrew は入っていない
  - `sudo <tool>` で使うなら、[sudo でも使う](#sudo-でも使う任意)の節を通す（`sudo -s`・`sudo -i` のシェルでも使えるようになる）
  - root のシェル（`su -`、root のログイン、`sudo -i`）で使うなら、[root のシェルでも使う](#root-のシェルでも使う任意)の節を通す
  - どちらも通さないなら、RPM で入れるか、フルパス（`/home/linuxbrew/.linuxbrew/bin/<tool>`）を渡す
- **`brew install` は、依存や依存先も含む計画なら端末で `[y/n]` を聞く**（Homebrew 7.0.7 の既定の ask mode）
  - 同じブロックに後ろの行があると、その文字が答えとして読まれ、`n` で中止になる。各手順書の `brew install` は、`[y/n]` に答えてから次の手順を貼る
  - 7.0.7 のヘルプでは、指定した formula / cask だけを入れる計画と、TTY が無い実行では確認を省く。端末では表示に従い、確認を求められたら答える
  - `brew upgrade` も 7.0.7 では ask mode が既定。名前を指定した場合はその名前以外も更新する計画、名前を省略した場合は更新対象があるときに、TTY で確認する
  - 導入・更新が終わり、プロンプトに戻ってから次の手順を貼る。確認を省く指定は `HOMEBREW_NO_ASK=1`、または `brew install` / `brew upgrade` の `--no-ask` / `--yes` / `-y`
- **不要な依存は自動で消えることがある**: Homebrew 7.0.7 の `brew uninstall` と `brew cleanup` は、不要になった依存を既定で自動削除する
  - 自動削除を止めるときは、そのコマンドに `HOMEBREW_NO_AUTOREMOVE=1` を付ける。明示的な `brew autoremove` は、残った不要な依存を消すための操作
- **`~/.bashrc` を読まない文脈では見えない**: cron や一部の非対話シェルでは `brew shellenv` が走らないので、Homebrew で入れたコマンドが見つからない。スクリプトからはフルパスで呼ぶ
- **ユーザーごとではなく、ホストに 1 つ**: `/home/linuxbrew` は共有なので、別ユーザーが使うには、そのユーザーにも bash の共通設定を導入する（書き込みには所有者の権限が要る）
- 古い版とキャッシュを掃除するなら `brew cleanup` を実行する
- **匿名の利用統計が既定で有効**: 止めるなら `brew analytics off`
