# Dropbox 公式クライアント導入手順（AlmaLinux 10 / x86_64 / headless + systemd ユーザーサービス）

## 実施手順

- [検証記録](verification/dropbox.md)・[参考資料](reference/dropbox.md)

> [!IMPORTANT]
> - **x86_64 の PC で実行する**。Dropbox は Linux の ARM 版を出していないので、Raspberry Pi 5（aarch64）では [dropbox-rclone.md](dropbox-rclone.md) を使う
> - **前提**: [linger](linger.md) を有効にしてあること（ログアウト中も Dropbox を動かすため）。`loginctl show-user "$(id -u)" -p Linger` が `Linger=yes` を返さなければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（デーモンは自分のホームに入り、同期するファイルの持ち主として動く）
> - **手順 2 で止まる**（fingerprint の目視）
> - **手順 8 はブラウザでリンクする**。この PC でなくても、ブラウザがあればどこでもよい
> - **ログアウト中も同期するなら、PC を眠らせない**（[AlmaLinux 10 の初期設定の「画面オフ・画面ロック・自動サスペンドを止める（任意）」](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)。Workstation で入れた PC は、ログイン画面のまま 15 分で眠る）

- 上から順にコードブロックを貼る
- 手順の後: 日々の操作は[使い方の基本](#使い方の基本)。以後は[更新](#更新)・[ロールバック](#ロールバック)

1. この PC で公式クライアントが動くかを確かめる。

   ```bash
   uname -m
   stat -f -c %T "${HOME}"
   df -h "${HOME}"
   ```

   - `uname -m` が `x86_64` ならよい
   - **`aarch64` ならここで止め、[dropbox-rclone.md](dropbox-rclone.md) へ進む**
   - `stat` が `xfs`（AlmaLinux の既定）・`ext2/ext3`（ext4 もこう出る）・`btrfs` のどれかなら、Dropbox が対応するファイルシステム
   - `df` の `Avail` が、Dropbox で使っている容量より大きいこと（リンクすると全部落ちてくる）

1. Dropbox の署名鍵を落として、fingerprint を見る。

   ```bash
   curl -fsSL https://linux.dropbox.com/fedora/rpm-public-key.asc -o /tmp/dropbox-key.asc
   gpg --show-keys --with-fingerprint /tmp/dropbox-key.asc
   ```

   - `gpg: command not found` と出たら、`sudo dnf install -y gnupg2` で入れてから貼り直す（GNOME のデスクトップには入っている）
   - 次の値と一致することを目で確かめる
     - fingerprint `1C61 A265 6FB5 7B7E 4DE0  F4C1 FC91 8B33 5044 912E`
     - uid `Dropbox Automatic Signing Key <linux@dropbox.com>`
   - 違っていればここで止める
   - **次の手順は、fingerprint と uid が一致するのを確かめてから貼る**

1. tarball と署名を落とし、署名が正しいときだけホームに展開する。

   ```bash
   DBX_URL=$(curl -fsS -o /dev/null -w '%{redirect_url}' 'https://www.dropbox.com/download?plat=lnx.x86_64')
   echo "${DBX_URL}"
   curl -fL -o /tmp/dropbox-lnx.tar.gz "${DBX_URL:?URL を取れなかった。この手順を貼り直す}"
   curl -fsSL -o /tmp/dropbox-lnx.tar.gz.asc "${DBX_URL}.asc"
   gpg --dearmor < /tmp/dropbox-key.asc > /tmp/dropbox-key.gpg
   gpgv --keyring /tmp/dropbox-key.gpg /tmp/dropbox-lnx.tar.gz.asc /tmp/dropbox-lnx.tar.gz && tar -xzf /tmp/dropbox-lnx.tar.gz -C ~
   ```

   - `echo` が出す URL の末尾に版が入っている（例 `dropbox-lnx.x86_64-270.4.3312.tar.gz`、約 87 MiB）
   - `gpgv: Good signature from "Dropbox Automatic Signing Key <linux@dropbox.com>"` が出れば、`~/.dropbox-dist` に展開されている
   - `BAD signature` のときは展開されない（`tar` は `&&` の後ろにある）ので、ここで止める

1. 展開した版を確かめ、落としたファイルを消す。

   ```bash
   ls ~/.dropbox-dist
   du -sh ~/.dropbox-dist
   rm -f /tmp/dropbox-lnx.tar.gz /tmp/dropbox-lnx.tar.gz.asc /tmp/dropbox-key.asc /tmp/dropbox-key.gpg
   ```

   - `VERSION`・`dropbox-lnx.x86_64-<版>`・`dropboxd` の 3 つが出る
   - `du` は約 150 MB（270.4.3312 で `153M`）

1. 操作に使う `dropbox` コマンドを `~/.local/bin` に置く。

   ```bash
   mkdir -p ~/.local/bin
   curl -fsSL -o ~/.local/bin/dropbox https://linux.dropbox.com/packages/dropbox.py
   chmod +x ~/.local/bin/dropbox
   command -v dropbox
   dropbox version
   ```

   - `command -v` が `/home/<USER>/.local/bin/dropbox` を出す
   - `Dropbox daemon version: 270.4.3312` と `Dropbox command-line interface version: 2026.05.06` が出る

1. ユーザーサービスを置いて、Dropbox を起動する。

   ```bash
   mkdir -p ~/.config/systemd/user
   cat > ~/.config/systemd/user/dropbox.service <<'EOF'
   [Unit]
   Description=Dropbox (headless)

   [Service]
   Type=simple
   ExecStart=%h/.dropbox-dist/dropboxd
   Restart=always
   RestartSec=10
   UnsetEnvironment=DISPLAY WAYLAND_DISPLAY

   [Install]
   WantedBy=default.target
   EOF
   systemctl --user daemon-reload
   systemctl --user enable --now dropbox.service
   systemctl --user is-enabled dropbox.service   # enabled
   systemctl --user is-active dropbox.service    # active
   ```

   - `Created symlink '.../default.target.wants/dropbox.service' → ...` が出る
   - `enabled`・`active` が出ればよい
   - [linger](linger.md) が有効なので、ログアウトしても止まらない（linger が無いと、ログアウトした時点で Dropbox も止まる）

1. リンク用の URL を出す。

   ```bash
   sleep 30
   dropbox status
   ```

   - `To link this computer to a Dropbox account, visit the following url:` の次の行に、URL（`https://www.dropbox.com/cli_link_nonce?nonce=...`）が出る
   - `Connecting...` や `Starting...` だけで URL が出なければ、少し待って `dropbox status` だけを貼り直す
   - **URL は他人に見せない**（開いた人の Dropbox アカウントにこの PC がつながる）

1. ブラウザで手順 7 の URL を開き、この PC を Dropbox に接続する。

   - Dropbox にログインして、この PC の接続を承認する（この PC のブラウザでなくてもよい）
   - **次の手順は、ブラウザで接続し終えてから貼る**

1. 同期が始まったか確かめる。

   ```bash
   dropbox status
   ls ~/Dropbox
   journalctl --user -u dropbox.service -n 20 --no-pager
   ```

   - `dropbox status` からリンク用の URL の案内が消え、同期の状態が出れば、リンクできている
   - `~/Dropbox` ができ、アカウントのファイルが落ちてくる（リンクする前は `No such file or directory`）

---

## 使い方の基本

| コマンド | 用途 |
|---|---|
| `dropbox status` | 状態を見る。リンクしていないときは、リンク用の URL を出す |
| `dropbox filestatus ~/Dropbox/<パス>` | ファイルごとの同期の状態 |
| `dropbox exclude add ~/Dropbox/<フォルダ>` | そのフォルダをこの PC に同期しない（選択型同期） |
| `dropbox exclude list` | 同期しないフォルダの一覧（`exclude remove` で同期に戻す） |
| `dropbox sharelink ~/Dropbox/<パス>` | 共有リンクを作る |
| `dropbox lansync n` | LAN 同期を止める（`y` で戻す） |
| `dropbox help` | コマンドの一覧（`dropbox help <コマンド>` で使い方） |
| `systemctl --user stop dropbox.service` | デーモンを止める（`start` で動かす）。`dropbox stop` は 10 秒後に戻される |
| `journalctl --user -u dropbox.service -f` | デーモンの出力を追う |

  - `exclude add` / `exclude remove` は何も出さずに終わった
  - `exclude list` は `Dropbox isn't responding!`、`filestatus` は `File doesn't exist`、`sharelink` は `Couldn't get shared link: ... does not exist` を返した
- `exclude` に渡すパスは、Dropbox フォルダの中でなければならない（`dropbox help exclude` の `Any specified path must be within Dropbox.`）
- 公式ヘルプは、これらのコマンドを Dropbox フォルダの一番上（`~/Dropbox`）で実行するよう案内している

---

## 更新

- デーモンは、`~/.dropbox-dist` の中身を自分で入れ替えて更新する作り（tarball の README と `dropbox.py` の説明）
- `dropbox.py` は自分では更新しない

1. デーモンと CLI の版を確かめる。

   ```bash
   dropbox version
   ```

   - 手で入れ直すときは、`systemctl --user stop dropbox.service` で止めてから [手順 2〜4](#実施手順) をやり直し、`systemctl --user start dropbox.service` で動かす（コンテナで、268.4.4124 から 270.4.3312 に入れ直せた）
   - 入れ直すと、古い版のディレクトリ（`~/.dropbox-dist/dropbox-lnx.x86_64-<古い版>`）が残る。新しい版で動いているのを `dropbox version` で確かめてから、`rm -rf` で消してよい

1. CLI（dropbox.py）を取り直す。

   ```bash
   curl -fsSL -o ~/.local/bin/dropbox https://linux.dropbox.com/packages/dropbox.py
   dropbox version
   ```

---

## ロールバック

- 上から順に実行する
- 同期していたファイルはクラウドに残る。この PC の `~/Dropbox` を消すのは、この節の手順 4 だけ
- 手順 2 で作られた `~/.gnupg` は、ほかでも使うので消さない
- linger も切るときは、この節の後に [linger.md のロールバック](linger.md#ロールバック)を行う（ほかに linger を使うものが無いかは、そこで確かめる）

> [!CAUTION]
> **この節の**手順 4 で、`~/.dropbox`（リンクの情報）と `~/Dropbox`（この PC の複製）を消す。まだ同期していない変更があれば失われる。
>
> - **デーモンが動いている間に `~/Dropbox` を消すと、クラウドからも消える**。手順 4 は、デーモンが動いていれば `中断:` で止まる
> - 入れ直す可能性があるなら残す

1. サービスを止めて外す。

   ```bash
   systemctl --user disable --now dropbox.service
   rm -f ~/.config/systemd/user/dropbox.service
   systemctl --user daemon-reload
   ```

   - `Removed '.../default.target.wants/dropbox.service'.` が出る

1. ブラウザで Dropbox の Web を開き、この PC のリンクを解除する。

   - アカウントの設定 → セキュリティ → デバイス にある

1. デーモンと CLI を消す。

   ```bash
   rm -rf ~/.dropbox-dist ~/.local/bin/dropbox
   ```

1. 完全に消すときだけ、リンクの情報とこの PC の複製を消す（取り戻せない）。

   ```bash
   if pgrep -u "$(id -un)" -x dropbox >/dev/null; then echo '中断: Dropbox のデーモンがまだ動いている。この節の手順 1 を先に貼る' >&2; else
   rm -rf ~/.dropbox ~/Dropbox
   fi
   ```

---

## 注意点

- **Basic（無料）プランは同時に 3 台まで**: 公式クライアントは、そのうちの 1 台に数えられる（公式ヘルプ。dropbox.com へのログインは数えない）
- **リンクすると全部落ちてくる**: headless では、最初に同期するフォルダを選べない。要らないフォルダは、リンクした直後に `dropbox exclude add` で外す（[使い方の基本](#使い方の基本)）
- **LAN 同期の受信は開けていない**: firewalld の定義済みサービス `dropbox-lansync`（17500/tcp・udp）は開けていない
  - LAN 内にほかの公式クライアントが無ければ要らない（Raspberry Pi 5 は rclone なので、LAN 同期に加わらない）
  - 使うなら `sudo firewall-cmd --permanent --add-service=dropbox-lansync` と `sudo firewall-cmd --reload`
- **`dropbox stop` は戻される**: `Restart=always` なので 10 秒後に起こし直される。止めるなら `systemctl --user stop dropbox.service`
- **リンク用の URL は他人に見せない**: 開いた人のアカウントにこの PC がつながる。リンクするまでは journal にも 5 秒ごとに残る
- **眠ると止まる**: サスペンド中は同期しない。常時動かす PC は [画面オフ・画面ロック・自動サスペンドを止める（任意）](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意) の節で眠らないようにする
- **フォルダの場所は `~/Dropbox` のまま**: headless の `dropbox` コマンドには、場所を移す機能が無い
