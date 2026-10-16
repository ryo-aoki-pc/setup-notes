# Dropbox のセットアップ（AlmaLinux 10）

- AlmaLinux 10 で、Dropbox の公式クライアントか rclone を使い、Dropbox とファイルを同期する
- 検証記録・参考資料・ロールバックと注意点は、各項のリードから開く

> [!IMPORTANT]
> - **前提と実行場所（ユーザー・端末・別のマシン）は、各項のリードに従う**。`sudo -i`・`su -` のシェルでは行わない
> - AlmaLinux 10 の項は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)と同じく、パスワードを聞かない `sudo` を前提に書いてある。各項のリードの前提に無くても、その項を行うユーザーで[ログインと sudo](almalinux-setup.md#ログインと-sudo)を先に通す

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- 入れたものは、[Dropbox: 更新](#dropbox-更新)・[Dropbox と rclone: 更新](#dropbox-と-rclone-更新)で上げる

## AlmaLinux 10 で使う

- Dropbox（公式のクライアントと rclone）

### Dropbox

- Dropbox の公式クライアント（ヘッドレスのデーモン）をホームに入れ、ユーザーサービスとして常駐させ、この PC を Dropbox のアカウントにリンクする
- 前提: [ユーザーサービスの常駐](almalinux-setup.md#ユーザーサービスの常駐)（linger。ログアウト中も Dropbox を動かすため）を通してある
  - `loginctl show-user "$(id -u)" -p Linger` が `Linger=yes` を返さなければ、先に[ユーザーサービスの常駐](almalinux-setup.md#ユーザーサービスの常駐)を通す
  - **ログアウト中も同期するなら、PC を眠らせない**（[画面オフ・画面ロック・自動サスペンドを止める](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)を通す。Workstation で入れた PC は、ログイン画面のまま 15 分で眠る）
- 実行場所: x86_64 の PC の、自分のユーザーの bash（デスクトップの端末か SSH）。**手順 8 はブラウザでリンクする**。この PC でなくても、ブラウザがあればどこでもよい
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/dropbox.md)・[参考資料](reference/dropbox.md)・[ロールバックと注意点](extra/dropbox.md)
- **手順 2 で止まる**（fingerprint の目視）

> [!IMPORTANT]
> - **x86_64 の PC で実行する**。Dropbox は Linux の ARM 版を出していないので、Raspberry Pi 5（aarch64）では [Dropbox と rclone](#dropbox-と-rclone) を使う
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（デーモンは自分のホームに入り、同期するファイルの持ち主として動く）

1. この PC で公式クライアントが動くかを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   uname -m
   stat -f -c %T "${HOME}"
   df -h "${HOME}"
   ```

   - `uname -m` が `x86_64` ならよい
   - **`aarch64` ならここで止め、[Dropbox と rclone](#dropbox-と-rclone) へ進む**
   - `stat` が `xfs`・`ext2/ext3`（ext4 もこう出る）・`btrfs` のどれかなら、Dropbox が対応するファイルシステム
   - `df` の `Avail` が、Dropbox で使っている容量より大きいこと

1. Dropbox の署名鍵を落として、fingerprint を見る。

   ```bash
   curl -fsSL https://linux.dropbox.com/fedora/rpm-public-key.asc -o /tmp/dropbox-key.asc
   printf '\n\033[7m 確認 \033[0m\n'
   gpg --show-keys --with-fingerprint /tmp/dropbox-key.asc
   ```

   - `gpg: command not found` と出たら、`sudo dnf install -y gnupg2` で入れてから貼り直す
   - 次の値と一致することを目で確かめる
     - fingerprint `1C61 A265 6FB5 7B7E 4DE0  F4C1 FC91 8B33 5044 912E`
     - uid `Dropbox Automatic Signing Key <linux@dropbox.com>`
   - 違っていればここで止める
   - **次の手順は、fingerprint と uid が一致するのを確かめてから貼る**

1. tarball と署名を落とし、署名が正しいときだけホームに展開する。

   ```bash
   DBX_URL=$(curl -fsS -o /dev/null -w '%{redirect_url}' 'https://www.dropbox.com/download?plat=lnx.x86_64')
   printf '\n\033[7m 確認 \033[0m\n'
   echo "${DBX_URL}"
   curl -fL -o /tmp/dropbox-lnx.tar.gz "${DBX_URL:?URL を取れなかった。この手順を貼り直す}"
   curl -fsSL -o /tmp/dropbox-lnx.tar.gz.asc "${DBX_URL}.asc"
   gpg --dearmor < /tmp/dropbox-key.asc > /tmp/dropbox-key.gpg
   gpgv --keyring /tmp/dropbox-key.gpg /tmp/dropbox-lnx.tar.gz.asc /tmp/dropbox-lnx.tar.gz && tar -xzf /tmp/dropbox-lnx.tar.gz -C ~
   ```

   - `echo` が出す URL の末尾に版が入っている（例 `dropbox-lnx.x86_64-270.4.3312.tar.gz`、約 87 MiB）
   - `gpgv: Good signature from "Dropbox Automatic Signing Key <linux@dropbox.com>"`（日本語では同じ署名者からの `正しい署名`）が出れば、`~/.dropbox-dist` に展開されている
   - `BAD signature` のときは展開されない（`tar` は `&&` の後ろにある）ので、ここで止める

1. 展開した版を確かめ、落としたファイルを消す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
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
   printf '\n\033[7m 確認 \033[0m\n'
   command -v dropbox
   dropbox version
   ```

   - `command -v` が `/home/<USER>/.local/bin/dropbox` を出す
   - `Dropbox daemon version: 272.4.3798` と `Dropbox command-line interface version: 2026.09.28` のように、本体と CLI の版が出る

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
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user enable --now dropbox.service
   systemctl --user is-enabled dropbox.service   # enabled
   systemctl --user is-active dropbox.service    # active
   ```

   - `Created symlink '.../default.target.wants/dropbox.service' → ...` が出る
   - `enabled`・`active` が出ればよい

1. リンク用の URL を出す。

   ```bash
   sleep 30
   printf '\n\033[7m 確認 \033[0m\n'
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
   printf '\n\033[7m 確認 \033[0m\n'
   dropbox status
   ls ~/Dropbox
   journalctl --user -u dropbox.service -n 20 --no-pager
   ```

   - `dropbox status` からリンク用の URL の案内が消え、同期の状態が出れば、リンクできている
   - `~/Dropbox` ができ、アカウントのファイルが落ちてくる（リンクする前は `No such file or directory`）

#### Dropbox: 使い方の基本

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

#### Dropbox: 更新

- Dropbox のデーモンと CLI の版を確かめ、CLI（dropbox.py）を取り直す
- 前提: [Dropbox](#dropbox)を通してある
- 実行場所: Dropbox を入れた PC の、自分のユーザーの bash（デスクトップの端末か SSH）
- デーモンは、`~/.dropbox-dist` の中身を自分で入れ替えて更新する作り（tarball の README と `dropbox.py` の説明）
- `dropbox.py` は自分では更新しない

1. デーモンと CLI の版を確かめる。

   ```bash
   dropbox version
   ```

   - 手で入れ直すときは、`systemctl --user stop dropbox.service` で止めてから[Dropbox](#dropbox)の手順 2〜4 をやり直し、`systemctl --user start dropbox.service` で動かす
   - 入れ直すと、古い版のディレクトリ（`~/.dropbox-dist/dropbox-lnx.x86_64-<古い版>`）が残る。新しい版で動いているのを `dropbox version` で確かめてから、`rm -rf` で消してよい

1. CLI（dropbox.py）を取り直す。

   ```bash
   curl -fsSL -o ~/.local/bin/dropbox https://linux.dropbox.com/packages/dropbox.py
   dropbox version
   ```

---

### Dropbox と rclone

- Homebrew で rclone を入れ、Dropbox と `~/Dropbox` を `rclone bisync` で 15 分ごとに同期する（公式クライアントの無い aarch64 向け）
- 前提: [Homebrew](almalinux-setup.md#homebrew)の手順 1〜3 と、[ユーザーサービスの常駐](almalinux-setup.md#ユーザーサービスの常駐)（linger）を通してある
  - `command -v brew` で何も出なければ、先に[Homebrew](almalinux-setup.md#homebrew)を通す
  - `loginctl show-user "$(id -u)" -p Linger` が `Linger=yes` でなければ、先に[ユーザーサービスの常駐](almalinux-setup.md#ユーザーサービスの常駐)を通す
  - **ログアウト中も同期するなら、Raspberry Pi 5 を眠らせない**（[画面オフ・画面ロック・自動サスペンドを止める](almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)を通す）
- 実行場所: Raspberry Pi 5（aarch64）などの、自分のユーザーの bash（デスクトップの端末か SSH）。**手順 3 はブラウザで認証する**
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/dropbox-rclone.md)・[参考資料](reference/dropbox-rclone.md)・[ロールバックと注意点](extra/dropbox-rclone.md)
- **手順 3・6・7・8 で止まる**（ブラウザでの許可・エディタ・`--dry-run` の結果の確認・最初の同期の完了）
- 手順 1 の導入で `[y/n]` が出たら、答えてプロンプトが戻ってから手順 2 を貼る
- x86_64 の PC では、公式クライアントの [Dropbox](#dropbox) を勧める（この手順も同じように動く）

> [!IMPORTANT]
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、同期するファイルの持ち主として動かすため）
> - 手順 2 は、Raspberry Pi 5 のデスクトップの端末で貼るか、手元の PC から `ssh -L localhost:53682:localhost:53682 <USER>@<HOSTNAME>` で入り直してから貼る

1. brew で rclone を入れる。

   ```bash
   brew install rclone
   ```

   - 最後の Caveats の「`mount` subcommand on macOS」は macOS の話で、ここでは関係ない
   - 依存の一覧と `[y/n]` が出たら、入るものを見て `y` と答える
   - **次の手順は、導入が終わってプロンプトが戻ってから貼る**（問い合わせ中に続けて貼ると、後ろの文字が答えとして読まれる）

1. rclone が入ったことを確かめ、Dropbox を登録する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   rclone version
   command -v rclone
   rclone config create dropbox dropbox >/dev/null
   ```

   - `rclone v1.75.2` のような版と `os/arch:` などの行、`/home/linuxbrew/.linuxbrew/bin/rclone` が出ればよい
   - `http://127.0.0.1:53682/auth?state=...` が表示され、`Waiting for code...` で許可を待つ（手順 3 で許可する）
   - SSH で入っているときは、`ssh -L` でトンネルを張った端末で貼る

1. ブラウザで手順 2 の URL を開き、rclone のアクセスを許可する。

   - Dropbox にログインしてから許可する
   - SSH で入っているときは、手元の PC のブラウザで開く
   - **次の手順は、ブラウザで許可してプロンプトが戻ってから貼る**

1. Dropbox に届くかと、使っている容量を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   rclone listremotes --long
   rclone about dropbox:
   rclone lsd dropbox:
   df -h ~
   ```

   - `listremotes` が `dropbox: dropbox` を出す
   - `lsd` が Dropbox の一番上のフォルダを並べる
   - **`Used:` が `Avail` より大きいとき、または一部のフォルダだけ同期するときは、手順 6 で絞る**
   - 全部同期するなら、手順 6 は飛ばす

1. フィルタのファイルと、同期先の `~/Dropbox` を用意する。

   ```bash
   mkdir -p ~/.config/rclone ~/Dropbox
   cat > ~/.config/rclone/dropbox-filters.txt <<'EOF'
   # rclone bisync のフィルタ（書き方は https://rclone.org/filtering/ ）
   # このファイルを変えたら、次の同期は --resync で行う（Dropbox と rclone の「同期するフォルダを変える」）

   # Dropbox が同期しないファイル（rclone の bisync の文書の例から）
   - .dropbox.attr
   - ~*.tmp
   - ~$*
   - .~*
   - desktop.ini
   - .dropbox

   # rclone が強制終了や電源断で残す書きかけのファイル
   - *.partial

   # 一部のフォルダだけ同期するときは、同期するフォルダを「+ /名前/**」で並べ、最後に「- **」を置く（上から順に判定される）
   # + /Documents/**
   # + /Photos/**
   # - **
   EOF
   printf '\n\033[7m 確認 \033[0m\n'
   grep -v -e '^#' -e '^$' ~/.config/rclone/dropbox-filters.txt
   ```

   - 最後の `grep` が、有効な 7 行（`- .dropbox.attr` から `- *.partial` まで）を出す

1. 同期するフォルダを絞るときだけ、フィルタのファイルを編集する。

   ```bash
   vi ~/.config/rclone/dropbox-filters.txt
   ```

   - 最後の 3 行の `# ` を外し、同期するフォルダを `+ /名前/**` の形で並べる（`/Documents` と `/Photos` は例なので書き換える）
   - `- **` は最後の行に残す
   - **次の手順は、保存して `vi` を閉じてから貼る**

1. 最初の同期で何が起きるかを見る（`--dry-run`）。

   ```bash
   rclone bisync dropbox: ~/Dropbox --filters-file ~/.config/rclone/dropbox-filters.txt --resync --max-lock 2m --dry-run --verbose
   ```

   - `Resync is copying files to - Path2` の後の `Skipped copy as --dry-run is set` の行が、Dropbox から手元に落ちてくるファイル
   - `Resync is copying files to - Path1` の後に `Skipped copy` の行があれば、それは手元にだけあるファイルで、Dropbox に上がる（`~/Dropbox` が空なら `There was nothing to transfer`）
   - 最後に `Bisync successful` が出る（`--dry-run` でも出る）
   - **次の手順は、コピーされるファイルを確かめてから貼る**

1. 最初の同期を行う（Dropbox の中身を落とす）。

   ```bash
   rclone bisync dropbox: ~/Dropbox --filters-file ~/.config/rclone/dropbox-filters.txt --resync --max-lock 2m --verbose
   ```

   - `Copied (new)` の行がファイルごとに出て、最後に `Bisync successful` が出れば終わり
   - アカウントが大きいと時間がかかる。SSH が切れると止まるので、Raspberry Pi 5 のデスクトップの端末で行う方が無難
   - 途中で止まったときは、2 分待ってからこの手順を貼り直す
   - **次の手順は、`Bisync successful` が出てプロンプトが戻ってから貼る**

1. 15 分ごとに同期する service と timer を置いて、timer を有効にする。

   ```bash
   mkdir -p ~/.config/systemd/user
   cat > ~/.config/systemd/user/dropbox-rclone.service <<'EOF'
   [Unit]
   Description=rclone bisync (Dropbox <-> ~/Dropbox)

   [Service]
   Type=oneshot
   ExecStart=/home/linuxbrew/.linuxbrew/bin/rclone bisync dropbox: %h/Dropbox --filters-file %h/.config/rclone/dropbox-filters.txt --resilient --recover --max-lock 2m --conflict-resolve newer --verbose
   EOF
   cat > ~/.config/systemd/user/dropbox-rclone.timer <<'EOF'
   [Unit]
   Description=rclone bisync (Dropbox <-> ~/Dropbox) every 15 minutes

   [Timer]
   OnBootSec=5min
   OnUnitInactiveSec=15min

   [Install]
   WantedBy=timers.target
   EOF
   systemctl --user daemon-reload
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user enable --now dropbox-rclone.timer
   systemctl --user is-enabled dropbox-rclone.timer    # enabled
   ```

   - `enabled` が出ればよい
   - `Created symlink '.../timers.target.wants/dropbox-rclone.timer' → ...` が出る

1. 1 回動かして、結果と次の実行時刻を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user start dropbox-rclone.service
   systemctl --user show -p Result dropbox-rclone.service      # Result=success
   journalctl --user -u dropbox-rclone.service -n 20 --no-pager
   systemctl --user list-timers dropbox-rclone.timer --no-pager
   ```

   - `Result=success` と、journal の `Bisync successful` が出ればよい
   - `list-timers` の `NEXT` が、次に同期する時刻
   - 失敗すると、最初の行で `Job for dropbox-rclone.service failed ...` と出る。journal の `ERROR` の行を見る（[使い方の基本](#dropbox-と-rclone-使い方の基本)）

#### Dropbox と rclone: 使い方の基本

| コマンド | 用途 |
|---|---|
| `systemctl --user start dropbox-rclone.service` | 今すぐ同期する（終わるまで戻らない） |
| `systemctl --user list-timers dropbox-rclone.timer --no-pager` | 次に同期する時刻と、前回の時刻 |
| `journalctl --user -u dropbox-rclone.service -n 50 --no-pager` | 同期のログ（`Bisync successful` か `ERROR` を見る） |
| `systemctl --user stop dropbox-rclone.timer` | 定期的な同期を止める（`start` で戻す） |
| `rclone about dropbox:` | Dropbox の使用量と空き |
| `rclone lsd dropbox:` | Dropbox 側のフォルダを見る（`rclone ls dropbox:<フォルダ>` でファイル） |
| `find ~/Dropbox -name '*.conflict*'` | 競合で残った方のファイルを探す |

- **削除は伝わる**。手元で消すと次の回で Dropbox からも消え、逆も同じ
- **一度に半分を超えて消えていると、同期は止まる**（`Safety abort: too many deletes`）
  - 誤って消したのなら、手元に戻すと次の回から元どおりに動く
  - 本当に消すのなら、rclone の案内のとおり `--force` を付けて手で 1 回動かす
- 両方で変えたファイルは新しい方が残り、古い方は `<名前>.conflict1` として両側に残る
- 同期を途中で止めるなら `systemctl --user stop dropbox-rclone.service`。後始末をして止まる（`kill -9` はしない）

#### Dropbox と rclone: 同期するフォルダを変える

- rclone の同期で使うフィルタのファイルを変え、`--resync` で同期し直す
- 前提: [Dropbox と rclone](#dropbox-と-rclone)を通してある
- 実行場所: rclone で同期しているホストの、自分のユーザーの bash（デスクトップの端末か SSH）
- フィルタを変えたら、次の同期は `--resync` で行う。しないと `Bisync critical error: filters file has changed (must run --resync)` で止まる
- 外したフォルダの手元の複製は、消えずに残る（同期されなくなるだけ）。要らなければ手で消す

1. タイマーとサービスを止めて、フィルタのファイルを編集する。

   ```bash
   systemctl --user stop dropbox-rclone.timer dropbox-rclone.service
   vi ~/.config/rclone/dropbox-filters.txt
   ```

   - 同期の途中なら、`systemctl --user stop` は後始末が終わるまで待つ
   - 書き方は[Dropbox と rclone](#dropbox-と-rclone)の手順 6 と同じ
   - **次の手順は、保存して `vi` を閉じてから貼る**

1. 変えた後の同期で何が起きるかを見る（`--dry-run`）。

   ```bash
   rclone bisync dropbox: ~/Dropbox --filters-file ~/.config/rclone/dropbox-filters.txt --resync --max-lock 2m --dry-run --verbose
   ```

   - 見方は[Dropbox と rclone](#dropbox-と-rclone)の手順 7 と同じ
   - **次の手順は、コピーされるファイルを確かめてから貼る**

1. `--resync` で同期し直し、タイマーを戻す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   rclone bisync dropbox: ~/Dropbox --filters-file ~/.config/rclone/dropbox-filters.txt --resync --max-lock 2m --verbose
   systemctl --user start dropbox-rclone.timer
   systemctl --user list-timers dropbox-rclone.timer --no-pager
   ```

   - `Bisync successful` の後に、`list-timers` が次の時刻を出せばよい

#### Dropbox と rclone: 更新

- Homebrew で入れた rclone を上げる
- 前提: [Dropbox と rclone](#dropbox-と-rclone)を通してある
- 実行場所: rclone で同期しているホストの、自分のユーザーの bash（デスクトップの端末か SSH）

1. rclone を上げる。

   ```bash
   brew upgrade rclone
   ```

   - 新しい版が無ければ `Warning: rclone 1.75.2 already installed` のように出る
   - 依存の一覧と `[y/n]` が出たら、更新するものを見て `y` と答える
   - **次の手順は、更新が終わってプロンプトが戻ってから貼る**（問い合わせ中に続けて貼ると、後ろの文字が答えとして読まれる）

1. 更新後の版を確かめる。

   ```bash
   rclone version | head -1
   ```

   - `rclone v` に続いて版が出ればよい

---
