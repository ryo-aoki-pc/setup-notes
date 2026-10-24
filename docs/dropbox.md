# Dropbox のセットアップ（AlmaLinux 10）

- AlmaLinux 10 で、Dropbox の公式クライアントか rclone を使い、Dropbox との同期や、Dropbox へのバックアップを行う
- 検証記録・参考資料・ロールバックと注意点は、各項のリードから開く

> [!IMPORTANT]
> - **前提と実行場所（ユーザー・端末・別のマシン）は、各項のリードに従う**。`sudo -i`・`su -` のシェルでは行わない
> - AlmaLinux 10 の項は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)と同じく、パスワードを聞かない `sudo` を前提に書いてある。各項のリードの前提に無くても、その項を行うユーザーで[ログインと sudo](almalinux-setup.md#ログインと-sudo)を先に通す

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- 公式クライアントは [Dropbox: 更新](#dropbox-更新)、同期とバックアップで使う rclone は [Dropbox と rclone: 更新](#dropbox-と-rclone-更新)で上げる

## AlmaLinux 10 で使う

- Dropbox（公式のクライアントと rclone による同期、Dropbox へのバックアップ）

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
   - 許可が終わってプロンプトが戻るまで、同じユーザーでほかの `rclone config` を実行しない（登録が `type` の無い節になって壊れる）

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
- 前提: [Dropbox と rclone](#dropbox-と-rclone)の手順 1〜4 を通してある
- 実行場所: rclone で同期かバックアップをしているホストの、自分のユーザーの bash（デスクトップの端末か SSH）

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

### Dropbox へのバックアップ

- 選んだファイルを暗号化し、毎日 Dropbox の `Backup/<ホスト名>` へ片方向で上げる。前の版は 30 日残す。Forgejo を動かしていれば、止めて取ったアーカイブも上げる（毎日数秒止まる）
- 前提: [Dropbox と rclone](#dropbox-と-rclone)の手順 1〜4 と、[ユーザーサービスの常駐](almalinux-setup.md#ユーザーサービスの常駐)を通してある。Forgejo のアーカイブも上げるなら、[Forgejo](forgejo.md#forgejo)を導入してある
- 実行場所: バックアップする PC の、自分のユーザーの bash（デスクトップの端末か SSH）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/dropbox-backup.md)・[参考資料](reference/dropbox-backup.md)・[ロールバックと注意点](extra/dropbox-backup.md)
- **この項の手順 1・4・7・9・10 で止まる**（パスワードの入力・エディタ・`--dry-run` と復号の結果の確認）
- **暗号化のパスワードを失うと戻せない**。この項の手順 1 で入れるパスワードは、パスワードの管理（KeePassXC など）に保存し、この項の手順 9・10 で確かめる

> [!IMPORTANT]
> **自分のシェルで実行する**。`sudo -i`・`su -` のシェルでは行わない

1. バックアップの暗号化のパスワードを入力する。

   ```bash
   read -rsp 'バックアップの暗号化のパスワード: ' RCLONE_BACKUP_PW; echo
   ```

   - パスワードの管理（KeePassXC など）に保存したパスワードを入力し、Enter を押す（画面には出ない）
   - **次の手順は、パスワードを入力してプロンプトが戻ってから貼る**（続けて貼ると、後ろの文字がパスワードとして読まれる）

1. 暗号化のリモートを登録する。

   ```bash
   if [ -z "${RCLONE_BACKUP_PW:-}" ]; then echo '中断: パスワードが空。手順 1 からやり直す' >&2
   elif rclone listremotes | grep -qx 'dropbox-backup:'; then echo '中断: dropbox-backup は登録済み。上書きしない' >&2
   else
     rclone config create dropbox-backup crypt remote="dropbox:Backup/$(hostname -s)" filename_encryption=off directory_name_encryption=false password="${RCLONE_BACKUP_PW}" --obscure >/dev/null
   fi
   unset RCLONE_BACKUP_PW
   printf '\n\033[7m 確認 \033[0m\n'
   rclone listremotes --long
   ```

   - `dropbox: dropbox` と `dropbox-backup: crypt` の 2 行が出ればよい
   - `中断: パスワードが空` が出たら、この項の手順 1 からやり直す
   - `中断: dropbox-backup は登録済み` が出たら、この項の手順 3 へ進む（登録をやり直すときは、[注意点](extra/dropbox-backup.md#注意点)を読んでから）

1. バックアップするものを選ぶフィルタを置く。

   ```bash
   mkdir -p ~/.config/rclone
   cat > ~/.config/rclone/backup-filters.txt <<'EOF'
   # Dropbox へ暗号化してバックアップするもの（rclone のフィルタ。書き方は https://rclone.org/filtering/ ）
   # 先頭の / はホームを指す。上から順に判定され、最後の「- **」で、並べたもの以外を外す

   # Forgejo の毎日のアーカイブ（dropbox-backup が作り、新しい 3 つを残す）
   + /.local/state/forgejo-backups/forgejo-daily-*.tar.gz

   # バックアップするフォルダーを「+ /名前/**」、ファイルを「+ /パス」で並べる（例）
   # + /Documents/**

   # 上に並べたもの以外は外す（この行は最後に残す）
   - **
   EOF
   printf '\n\033[7m 確認 \033[0m\n'
   grep -v -e '^#' -e '^$' ~/.config/rclone/backup-filters.txt
   ```

   - Forgejo のアーカイブの `+` の行と、`- **` の有効な 2 行が出ればよい

1. フィルタを編集し、バックアップするフォルダーとファイルを選ぶ。

   ```bash
   vi ~/.config/rclone/backup-filters.txt
   ```

   - バックアップするフォルダーを `+ /名前/**`、ファイルを `+ /パス` で並べる。`/` はホームを指す
   - `- **` は最後の行に残す
   - ホームの下にマウントしたほかのディスクは、`--one-file-system` で上がらない
   - **次の手順は、保存して `vi` を閉じてから貼る**（続けて貼ると、後ろの文字がエディタへの入力として読まれる）

1. バックアップのスクリプトを置く。

   ```bash
   mkdir -p ~/.local/bin
   cat > ~/.local/bin/dropbox-backup <<'EOF'
   #!/usr/bin/env bash
   # Dropbox へ暗号化してバックアップする（dropbox-backup.timer から毎日動く）。
   # 1. Forgejo があれば止めてアーカイブを取り、起動し直す（アーカイブに入れるものは docs/forgejo.md の「バックアップ」と同じ）
   # 2. フィルタで選んだファイルを dropbox-backup:current へ sync する。消えた・上書きされたものは old/<日時> へ移る
   # 3. old/ の日時のディレクトリのうち、KEEP_DAYS 日より古いものを消す
   # どこかで失敗しても残りは続け、最後に非 0 で終わる。
   # --after-stop は service の ExecStopPost から呼ぶ（途中で止められて Forgejo が止まったままなら、起動し直す）。
   set -uo pipefail

   RCLONE=/home/linuxbrew/.linuxbrew/bin/rclone
   REMOTE=dropbox-backup:
   FILTERS="${HOME}/.config/rclone/backup-filters.txt"
   QUADLET="${HOME}/.config/containers/systemd/forgejo.container"
   MARK="${HOME}/.local/state/dropbox-backup/forgejo-stopped"
   KEEP_DAYS=30
   KEEP_FORGEJO=3
   STAMP=$(date -u +%Y%m%dT%H%M%SZ)
   status=0

   # ユーザーの systemd の private ソケットにつながらないときは、forgejo-auto-update と同じく --machine で再試行する
   user_systemctl() {
     local err rc
     { err=$(systemctl --user "$@" 2>&1 1>&3 3>&-); rc=$?; } 3>&1
     if [ "${rc}" -ne 0 ] && [[ ${err} == *'Failed to connect to user scope bus'* ]]; then
       systemctl --user --machine="$(id -un)@.host" "$@"
       return
     fi
     if [ -n "${err}" ]; then printf '%s\n' "${err}" >&2; fi
     return "${rc}"
   }

   if [ "${1:-}" = --after-stop ]; then
     if [ -e "${MARK}" ] && [ ! -f "${QUADLET}" ]; then
       rm -f "${MARK}"
     elif [ -e "${MARK}" ]; then
       echo 'Forgejo: 止まったままなので、起動し直す' >&2
       user_systemctl start forgejo.service && rm -f "${MARK}"
     fi
     exit
   fi

   # フィルタが無いか、最後の有効な行が「- **」でなければ、ホーム全体を上げてしまうので止める
   last=$(grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' "${FILTERS}" 2>/dev/null | tail -n 1)
   if [ "${last}" != '- **' ]; then
     echo "中断: ${FILTERS} が無いか、最後の有効な行が「- **」でない" >&2
     exit 1
   fi

   backup_forgejo() (
     local dir="${HOME}/.local/state/forgejo-backups"
     local lockdir="${HOME}/.local/state/forgejo-auto-update"
     local archive="${dir}/forgejo-daily-${STAMP}.tar.gz"
     local was_active=0
     install -d -m 700 "${dir}" "${lockdir}" "${MARK%/*}" || return 1
     rm -f "${dir}"/forgejo-daily-*.tar.gz.tmp
     # 自動更新（forgejo-auto-update）と同じロックを取り、同時に Forgejo を止めない
     exec 9>"${lockdir}/lock"
     if ! flock -n 9; then
       echo 'Forgejo: 自動更新が動いているので、今回は飛ばした' >&2
       return 1
     fi
     # 前の回で起動し直せずに印が残っていれば、先に起動し直す（動いていれば印だけ消す）
     if [ -e "${MARK}" ]; then
       if user_systemctl is-active --quiet forgejo.service || user_systemctl start forgejo.service; then
         rm -f "${MARK}"
       else
         echo 'Forgejo: 前の回から止まったままで、起動し直せなかった' >&2
         return 1
       fi
     fi
     if user_systemctl is-active --quiet forgejo.service; then
       was_active=1
       # 起動し直すまで印を残す。止められたときは ExecStopPost が、失敗したときは trap が起動し直す
       : > "${MARK}" || return 1
       trap 'if user_systemctl start forgejo.service; then rm -f "${MARK}"; else echo "Forgejo: 起動し直せなかった" >&2; fi' EXIT
     fi
     if ! user_systemctl stop forgejo.service || podman container exists forgejo; then
       echo 'Forgejo: 止められなかったので、アーカイブを取らなかった' >&2
       return 1
     fi
     if ! (umask 077; tar --create --gzip --file="${archive}.tmp" --directory="${HOME}" \
             .local/share/forgejo .config/containers/systemd/forgejo.container); then
       rm -f "${archive}.tmp"
       echo 'Forgejo: アーカイブに失敗した' >&2
       return 1
     fi
     mv "${archive}.tmp" "${archive}" || return 1
     if [ "${was_active}" = 1 ]; then
       user_systemctl start forgejo.service || return 1
       trap - EXIT
       rm -f "${MARK}"
     fi
     echo "Forgejo: ${archive}"
     # 手元の毎日のアーカイブは新しい KEEP_FORGEJO 個を残す（自動更新・手動のものには触れない）
     find "${dir}" -maxdepth 1 -name 'forgejo-daily-*.tar.gz' -printf '%f\n' | sort -r |
       tail -n +"$((KEEP_FORGEJO + 1))" | while IFS= read -r old; do rm -f -- "${dir}/${old}"; done
   )

   if [ -f "${QUADLET}" ]; then
     backup_forgejo || status=1
   fi

   "${RCLONE}" sync "${HOME}" "${REMOTE}current" --filter-from "${FILTERS}" --one-file-system \
     --backup-dir "${REMOTE}old/${STAMP}" --verbose || status=1

   cutoff=$(date -u -d "-${KEEP_DAYS} days" +%Y%m%dT%H%M%SZ)
   while IFS= read -r d; do
     d=${d%/}
     [[ ${d} =~ ^[0-9]{8}T[0-9]{6}Z$ ]] || continue
     if [[ ${d} < ${cutoff} ]]; then
       if "${RCLONE}" purge "${REMOTE}old/${d}"; then echo "old/${d} を消した"; else status=1; fi
     fi
   done < <("${RCLONE}" lsf --dirs-only "${REMOTE}old" 2>/dev/null)

   exit "${status}"
   EOF
   chmod 755 ~/.local/bin/dropbox-backup
   printf '\n\033[7m 確認 \033[0m\n'
   bash -n ~/.local/bin/dropbox-backup && echo OK
   ```

   - `OK` が出ればよい

1. 毎日動かす service と timer を置く。

   ```bash
   mkdir -p ~/.config/systemd/user
   cat > ~/.config/systemd/user/dropbox-backup.service <<'EOF'
   [Unit]
   Description=Back up to Dropbox (rclone crypt)
   Wants=podman-user-wait-network-online.service
   After=podman-user-wait-network-online.service

   [Service]
   Type=oneshot
   ExecStart=%h/.local/bin/dropbox-backup
   ExecStopPost=%h/.local/bin/dropbox-backup --after-stop
   Nice=10
   IOSchedulingClass=idle
   EOF
   cat > ~/.config/systemd/user/dropbox-backup.timer <<'EOF'
   [Unit]
   Description=Back up to Dropbox daily

   [Timer]
   OnCalendar=*-*-* 03:10
   Persistent=true

   [Install]
   WantedBy=timers.target
   EOF
   systemctl --user daemon-reload
   ```

   - エラーが出なければよい。タイマーは、この項の手順 11 で有効にする
   - `Failed to connect to user scope bus` が出たら、`env -u XDG_RUNTIME_DIR systemctl --user daemon-reexec` を貼ってから、この手順を貼り直す

1. 上がるファイルを、変更せずに確かめる（`--dry-run`）。

   ```bash
   rclone sync ~ dropbox-backup:current --filter-from ~/.config/rclone/backup-filters.txt --one-file-system --dry-run --verbose
   ```

   - `Skipped copy as --dry-run is set` の行が、上がるファイル
   - 初回は、Forgejo のアーカイブの行は出ない
   - 思わないものが出たら、この項の手順 4 に戻る
   - **次の手順は、上がるファイルを確かめてから貼る**

1. バックアップを 1 回動かす。

   ```bash
   systemctl --user start dropbox-backup.service
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user show -p Result dropbox-backup.service
   journalctl --user-unit dropbox-backup.service -n 30 --no-pager
   ```

   - `Result=success` が出ればよい
   - Forgejo があるときは `Forgejo: <パス>` の行、初回に上がるファイルは `Copied (new)` の行、最後は `Transferred:` を確かめる
   - `Failed to connect to user scope bus` が出たら、`env -u XDG_RUNTIME_DIR systemctl --user daemon-reexec` を貼ってから、この手順を貼り直す
   - 失敗したら journal のエラーを確かめ、解消してからこの手順を貼り直す

1. パスワードの管理から写し、保存したパスワードを入力する。

   ```bash
   read -rsp '保存したパスワード: ' RCLONE_BACKUP_PW; echo
   ```

   - 保存したパスワードを入力し、Enter を押す（画面には出ない）
   - **次の手順は、パスワードを入力してプロンプトが戻ってから貼る**（続けて貼ると、後ろの文字がパスワードとして読まれる）

1. 保存したパスワードで戻せるか確かめる。

   ```bash
   if [ -z "${RCLONE_BACKUP_PW:-}" ]; then echo '中断: パスワードが空。手順 9 からやり直す' >&2; else
     F=$(rclone lsf -R --files-only --min-size 1B --format sp dropbox-backup:current | sort -t ';' -k1,1n | head -n 1 | cut -d ';' -f 2-)
     if [ -z "${F}" ]; then echo '中断: 確かめるファイルが無い。手順 8 を先に通す' >&2
     elif RCLONE_CONFIG_PWCHECK_TYPE=crypt RCLONE_CONFIG_PWCHECK_REMOTE="dropbox:Backup/$(hostname -s)" RCLONE_CONFIG_PWCHECK_FILENAME_ENCRYPTION=off RCLONE_CONFIG_PWCHECK_DIRECTORY_NAME_ENCRYPTION=false RCLONE_CONFIG_PWCHECK_PASSWORD="$(printf '%s\n' "${RCLONE_BACKUP_PW}" | rclone obscure -)" rclone check dropbox-backup:current pwcheck:current --download --files-from <(printf '%s\n' "${F}") >/dev/null 2>&1; then
       printf '\n\033[7m 確認 \033[0m\n'
       echo 'OK: 保存したパスワードで戻せる'
     else
       echo 'NG: 保存したパスワードでは戻せない' >&2
     fi
   fi
   unset RCLONE_BACKUP_PW F
   ```

   - `OK: 保存したパスワードで戻せる` が出ればよい
   - `中断:` が出たら、表示されたこの項の手順からやり直す
   - `NG: 保存したパスワードでは戻せない` は、パスワードが違うときと、Dropbox から読めなかったときに出る。`rclone about dropbox:` が通ることと保存したパスワードを見直し、この項の手順 9 からやり直す
   - それでも合わなければ、`dropbox-backup` の登録を上書きせず、[注意点](extra/dropbox-backup.md#注意点)を読む
   - **次の手順は、保存したパスワードで戻せることを確かめてから貼る**

1. タイマーを有効にし、次に動く時刻を確かめる。

   ```bash
   systemctl --user enable --now dropbox-backup.timer
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user is-enabled dropbox-backup.timer
   systemctl --user list-timers dropbox-backup.timer --no-pager
   ```

   - `enabled` が出て、`NEXT` が次の 03:10 ならよい

#### Dropbox へのバックアップ: 使い方の基本

| コマンド | 用途 |
|---|---|
| `systemctl --user start dropbox-backup.service` | 今すぐバックアップする（終わるまで戻らない） |
| `systemctl --user list-timers dropbox-backup.timer --no-pager` | 次と前回の時刻 |
| `journalctl --user-unit dropbox-backup.service -n 50 --no-pager` | バックアップのログ |
| `rclone size dropbox-backup:current` | 上がっている量 |
| `rclone lsf dropbox-backup:old` | 古い版の日時 |
| `rclone about dropbox:` | Dropbox の使用量と空き |
| `systemctl --user stop dropbox-backup.timer` | 定期的なバックアップを止める（`start` で戻す） |

- 対象を変えるときは、フィルタを直した後に、[Dropbox へのバックアップ](#dropbox-へのバックアップ)の手順 7 の `--dry-run` で上がるものを確かめる。次の回から変わる
- フィルタから外したものは `current` に残る
- 対象に含まれるファイルを手元で消すと、次の回で `old/<日時>` へ移り、30 日残る

#### Dropbox へのバックアップ: 戻す

- Dropbox から `~/dropbox-restore` に写して確かめてから、元の場所へ自分で移す
- 前提: [Dropbox へのバックアップ](#dropbox-へのバックアップ)を通してある
- 実行場所: ファイルを戻す PC の、自分のユーザーの bash（デスクトップの端末か SSH）
- 別の PC で戻すときは、`dropbox-backup:` がまだ無い PC（`rclone listremotes` に出ない）で、[Dropbox と rclone](#dropbox-と-rclone)の手順 1〜4 と、[Dropbox へのバックアップ](#dropbox-へのバックアップ)の手順 1・2 を通す。手順 2 では、`remote=` を `remote="dropbox:Backup/<元のホスト名>"` に変えて貼る
  - その PC で `dropbox-backup:` が登録済みなら、上書きしない。ほかのユーザーか、ほかの PC で行う
- Forgejo のアーカイブは、戻した後に [Forgejo: バックアップから復元する](forgejo.md#forgejo-バックアップから復元する)へ進む

1. 変数を設定する（`RESTORE_PATH` は必ず値を入れる）。

   ```bash
   RESTORE_PATH=''                    # ホームからの相対パス（フォルダーかファイル）
   ```

   ```bash
   RESTORE_FROM=current              # 古い版なら old/<日時>
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'RESTORE_PATH=%s\nRESTORE_FROM=%s\n' "${RESTORE_PATH}" "${RESTORE_FROM}"
   ```

   - `RESTORE_PATH` に戻すフォルダーかファイルのパスを入れる（例: `Documents`）。先頭の `/` と末尾の `/` は付けない
   - 古い版を戻すなら、`rclone lsf dropbox-backup:old` で日時を見て、`RESTORE_FROM` を `old/<日時>` に変える
   - 表示されたパスと戻す元が合っていることを確かめる

1. 選んだフォルダーかファイルを、復元用のフォルダーに写す。

   ```bash
   if [ -z "${RESTORE_PATH}" ]; then echo '中断: RESTORE_PATH が空。手順 1 で値を入れる' >&2; else
     rclone copy "dropbox-backup:${RESTORE_FROM}" ~/dropbox-restore --include "/${RESTORE_PATH}" --include "/${RESTORE_PATH}/**" --verbose
     printf '\n\033[7m 確認 \033[0m\n'
     find ~/dropbox-restore -type f | head -n 20
   fi
   ```

   - 指定したフォルダーかファイルが `~/dropbox-restore` の下に出ればよい
   - `中断: RESTORE_PATH が空` が出たら、この項の手順 1 で値を入れる

1. 中身を確かめ、元の場所へ移す。

   - 上書きの前に、元の場所のファイルを退避する
   - ファイルの中身を確かめてから、元の場所へ自分で移す（例: `mv ~/dropbox-restore/<パス> ~/<元の場所>`）
   - 終わったら、`~/dropbox-restore` を消す（`rm -rf ~/dropbox-restore`）

---
