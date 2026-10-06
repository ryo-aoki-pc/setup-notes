# Homebrew インストール手順（AlmaLinux 10）の参考資料

[手順書](../homebrew.md)

## 補足

### 選択した方針

**Homebrew に揃える判断の実質は「更新の一元化」**。`brew upgrade` 1 本で、17 本の手順書で Homebrew から入れたものがまとめて上がる。

### root のシェルで使うときの補足

| 入口 | 読むファイル | Homebrew のコマンド |
|---|---|---|
| `su -`、ssh での root のログイン | `/etc/profile` → `/root/.bash_profile` → `/root/.bashrc` | 使える（PATH の末尾） |
| `sudo -i` | 同上。PATH の始まりは sudo の `secure_path` | 使える（PATH の末尾） |
| `sudo -s`、`su`（`-` 無し） | `/root/.bashrc`（`sudo -s` でも `HOME` は `/root`） | 使える（PATH の末尾） |
| `sudo <コマンド>` | 読まない。PATH は `secure_path` の `/sbin:/bin:/usr/sbin:/usr/bin` | 使えない（`sudo: jq: command not found`）。[sudo でも使う](../homebrew.md#sudo-でも使う任意)の節で使える |

- **`su`（`-` 無し）も、Homebrew のユーザーの PATH を引き継がない**: PATH は root のものに置き換わり、その末尾に足される
- **cron や systemd の unit では見えない**: `~/.bashrc` を読まないため（[注意点](../homebrew.md#注意点)の「`~/.bashrc` を読まない文脈」と同じ）。フルパスで書く
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

### sudo で使うときの補足

| 入口 | PATH | Homebrew のコマンド |
|---|---|---|
| `sudo <コマンド>`、`sudo -u <ユーザー> <コマンド>`、`sudo bash <スクリプト>` | `secure_path`（`/sbin:/bin:/usr/sbin:/usr/bin` の後ろに 2 つ） | 使える（`sudo jq --version` は `jq-1.8.2`） |
| `sudo -E <コマンド>` | 同上（`-E` でも、自分の PATH は渡らない） | 使える |
| `sudo -s` | `/root/.local/bin:/root/bin` の後ろに `secure_path` | 使える（PATH の末尾） |
| `sudo -i` | `/root/.local/bin:/root/bin:/usr/local/sbin` の後ろに `secure_path` | 使える（PATH の末尾） |
| `sudoedit`（`EDITOR=nvim`） | エディタを `secure_path` で探し、自分のユーザーと自分の環境で動かす | Homebrew の `nvim`。設定は自分の `~/.config/nvim` |
| `sudo EDITOR=nvim visudo` | エディタを `secure_path` で探し、root で動かす | Homebrew の `nvim`。設定は `/root/.config/nvim` |
| `su -`、`sudo su -`、ssh での root のログイン | sudo の `secure_path` を通らない | 使えない（[root のシェルでも使う](../homebrew.md#root-のシェルでも使う任意)の節で使える） |

### 参照

---
