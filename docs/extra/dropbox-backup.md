# Dropbox へのバックアップのロールバックと注意点

[手順書](../dropbox.md#dropbox-へのバックアップ)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/dropbox-backup.md)・[参考資料](../reference/dropbox-backup.md)

- 「手順 N」は[手順書の「Dropbox へのバックアップ」](../dropbox.md#dropbox-へのバックアップ)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- 上から順に実行する
- 実行場所: バックアップを入れた PC の、自分のユーザーの bash（デスクトップの端末か SSH）
- Dropbox 側のバックアップは、この節の手順 4 を行わない限り残る。後で戻すなら、暗号化のパスワードを保存しておく

> [!CAUTION]
> **この節の**手順 4 は、Dropbox の `Backup/<ホスト名>` にある `current` と `old` をすべて消す（取り戻せない）。消す対象のホストを確かめ、必要なファイルは先に戻しておく。

1. タイマーを止めて、unit とスクリプトを消す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user disable --now dropbox-backup.timer
   systemctl --user stop dropbox-backup.service
   rm -f ~/.config/systemd/user/dropbox-backup.service ~/.config/systemd/user/dropbox-backup.timer ~/.local/bin/dropbox-backup
   systemctl --user daemon-reload
   ```

   - `Removed '.../timers.target.wants/dropbox-backup.timer'.` が出る

1. 暗号化のリモートとフィルタを消す。

   ```bash
   rclone config delete dropbox-backup
   rm -f ~/.config/rclone/backup-filters.txt
   printf '\n\033[7m 確認 \033[0m\n'
   rclone listremotes --long
   ```

   - `dropbox-backup:` が出なくなればよい。`dropbox:` は残る

1. Forgejo のアーカイブを上げていたときだけ、手元の毎日のアーカイブを消す。

   ```bash
   rm -f ~/.local/state/forgejo-backups/forgejo-daily-*.tar.gz
   ```

   - 自動更新の `forgejo-auto-*` と、手動の `forgejo-<日時>.tar.gz` は残る

1. Dropbox 側のバックアップも消すときだけ、消す（取り戻せない）。

   ```bash
   rclone purge "dropbox:Backup/$(hostname -s)"
   printf '\n\033[7m 確認 \033[0m\n'
   rclone lsd dropbox:Backup
   ```

   - この PC のホスト名のフォルダーが出なくなればよい

1. rclone と `dropbox` の登録も要らなければ、共用部分を片づける。

   - [Dropbox と rclone のロールバック](dropbox-rclone.md#ロールバック)の手順 2〜4 を行う
   - 双方向同期やほかのバックアップで使うときは、`dropbox` の登録と rclone を残す

---

## 注意点

- **パスワードを失うと戻せない**: ホストと `rclone.conf` を失っても戻せるよう、暗号化のパスワードはホストの外のパスワードの管理（KeePassXC など）に保存する。ホスト内の `~/.config/rclone/rclone.conf` だけに頼らない
- **暗号化するのは中身だけ**: ファイル名・フォルダー名・大きさ・日時は Dropbox から見える（ファイル名には `.bin` が付く）
- **ほかのディスクは上がらない**: `--one-file-system` を付けているので、ホームの下にマウントした別のファイルシステムは対象外
- **書き換え中のファイル**: 上げている間に書き換わったファイルは、次の回で上がる。アプリの整合した状態が要るデータは、そのアプリのバックアップを対象にする
- **Forgejo は毎日数秒止まる**: 自動更新がロックを持っている日は、Forgejo の部分を飛ばす。ほかのファイルは上げるが、`Result=exit-code` になる
- **途中で止めたときは Forgejo を確かめる**: 実行中に `systemctl --user stop dropbox-backup.service` で止めると、スクリプトが止めた Forgejo は `ExecStopPost=` が起動し直す
  - 印のファイル `~/.local/state/dropbox-backup/forgejo-stopped` が残っていて、`systemctl --user is-active forgejo.service` が `inactive` のときだけ、`systemctl --user start forgejo.service` で起動し、起動できたら印を消す
  - 印が無くて `inactive` なら、このバックアップが止めたものではないので、起動しない
- **パスワードは登録の間だけ引数に載る**: 手順 2 の `rclone config create` の間、パスワードはプロセスの一覧から読める。ほかのユーザーがログインしているホストでは、その人がいない間に行う
- **設定の中身を画面に出さない**: 設定の確認には `rclone listremotes --long` と `rclone about dropbox:` を使う。`rclone config show`・`rclone config dump`・`rclone config redacted` は使わない（`type` の無い節では `redacted` もトークンを伏せない）
- **Dropbox は大文字と小文字を区別しない**: 大文字と小文字だけが違うファイル名は、Dropbox 側でぶつかる
- **linger は共有する**: Forgejo・Syncthing などが使っている間は切らない（[ユーザーサービスの常駐 のロールバック](linger.md#ロールバック)）
- **ユーザーの systemd につながらないことがある**: `Failed to connect to user scope bus via local transport: Connection refused` は、ユーザーの systemd の private ソケットへの接続が拒否される状態
  - スクリプトは、このときだけ `--machine="$(id -un)@.host"` で再試行する
  - 手で貼るコマンドで出たら、手順 6・8 の箇条書きのとおり `daemon-reexec` で直す
  - このホストの検証では、`systemd-analyze --user verify` を実行すると起きた。unit を確かめるのに使わない
- **保存したパスワードが合わないとき・登録をやり直すとき**: 一致するまで手順 11 へ進まない。手順 2 は、`dropbox-backup` が登録済みなら上書きせずに止まる
  - 元のパスワードが分からなくなっても、既存の `dropbox-backup` の登録を上書きしたり、Dropbox 側のバックアップを消したりしない（このホストが動いている間は、登録済みの設定で戻せる）
  - 元のパスワードを取り戻せなければ、ホストを失った後にそのバックアップから戻せない
