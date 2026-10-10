# Dropbox を rclone で同期する手順（AlmaLinux 10 / Raspberry Pi 5 / Homebrew + systemd ユーザータイマー）のロールバックと注意点

[手順書](../dropbox-rclone.md)・[検証記録](../verification/dropbox-rclone.md)・[参考資料](../reference/dropbox-rclone.md)

- 「手順 N」は[手順書](../dropbox-rclone.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- 上から順に実行する
- Dropbox 側のファイルは、この節のどの手順でも消えない
- linger も切るときは、この節の後に [linger.md のロールバック](linger.md#ロールバック)を行う（ほかに linger を使うものが無いかは、そこで確かめる）

> [!CAUTION]
> **この節の**手順 5 で `~/Dropbox` を消すのは、手順 1 でタイマーを止めてからにする。タイマーが動いている間に手元で消すと、次の回で Dropbox 側からも消える（半分を超える削除は `Safety abort` で止まるが、それより少なければ消える）。手順 5 は、タイマーかサービスが動いていれば `中断:` で止まる。
> まだ Dropbox に上がっていない手元の変更は、取り戻せない。

1. タイマーを止めて unit を消す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user disable --now dropbox-rclone.timer
   systemctl --user stop dropbox-rclone.service
   rm -f ~/.config/systemd/user/dropbox-rclone.service ~/.config/systemd/user/dropbox-rclone.timer
   systemctl --user daemon-reload
   ```

   - `Removed '.../timers.target.wants/dropbox-rclone.timer'.` が出る

1. rclone の設定から Dropbox を消す。

   ```bash
   rclone config delete dropbox
   printf '\n\033[7m 確認 \033[0m\n'
   rclone listremotes
   ```

   - `rclone listremotes` に `dropbox:` が出なくなる（ほかにリモートが無ければ何も出ない）

1. ブラウザで Dropbox の Web を開き、rclone の接続を解除する。

   - アカウントの設定 → 接続済みのアプリ にある
   - 手元から消しただけでは、トークンは Dropbox 側で生きている

1. rclone をほかで使わないときだけ、rclone を消す。

   ```bash
   brew uninstall rclone
   ```

   - 空になった `~/.config/rclone/rclone.conf` は残る

1. 手元のファイルも消すときだけ、`~/Dropbox` とフィルタを消す（取り戻せない）。

   ```bash
   if systemctl --user is-active --quiet dropbox-rclone.timer dropbox-rclone.service; then echo '中断: 同期のタイマーかサービスがまだ動いている。この節の手順 1 を先に貼る' >&2; else
   rm -rf ~/Dropbox ~/.config/rclone/dropbox-filters.txt ~/.config/rclone/dropbox-filters.txt.md5
   fi
   ```

   - まだ Dropbox に上がっていない手元の変更は失われる
   - `~/.cache/rclone/bisync` は、ほかの同期も使うので残す（Dropbox の一覧やロックの記録も残る）
   - 先頭の `if` は、タイマーを止めないまま貼ったときに、削除が Dropbox 側へ伝わるのを防ぐ

---

## 注意点

- **bisync は rclone の「advanced command」**: rclone の文書は、注意して使うよう書いている。削除も伝わる双方向同期なので、[使い方の基本](../dropbox-rclone.md#使い方の基本)の削除と競合の扱いを先に読んでおく
- **毎回すべてを一覧する**: 15 分ごとに Dropbox の全体を一覧するので、ファイルが多いと時間と API の呼び出しが増える
  - 既定では rclone 全体で共有の Dropbox の app key を使う。`too_many_requests` が続くなら、間隔を広げるか、rclone の文書のとおり自分の app key を作る
- **Dropbox は大文字と小文字を区別しない**: 手元で大文字と小文字だけが違う 2 つのファイルは、Dropbox 側でぶつかる。Dropbox が受け付けない名前もある
- **止めるときは `systemctl --user stop`**: SIGTERM を受けた rclone は、転送中のファイルを片づけて止まる
  - `kill -9`・電源断・SSH の切断（SIGHUP）では、その場で止まり、ロックと書きかけが残る
  - ロックは `--max-lock 2m` で 2 分後に切れ、timer の次の回が `--recover` で回復を試みる
- **トークンは平文で入る**: `~/.config/rclone/rclone.conf`（権限 600）にある。`rclone config create` はトークン入りの設定を画面に出すので、手順 2 では `>/dev/null` を付けた
- **Raspberry Pi 5 の linger は Syncthing と共有している**: linger を切るのは、どちらも使わなくなったときだけ（[linger.md のロールバック](linger.md#ロールバック)で確かめる）
- **Syncthing・Samba と重ねない**: `~/Dropbox` を Syncthing の同期フォルダに入れない（2 つの同期が同じファイルを書き合う）。[Samba](../samba.md) でホームを公開していると、`~/Dropbox` も SMB から見える
- **端末の上限**: Basic（無料）プランは同時に 3 台まで。rclone のような連携アプリが数えられるかは、公式ヘルプに書かれていない
- **眠ると止まる**: サスペンド中は同期しない。常時動かすなら [画面オフ・画面ロック・自動サスペンドを止める（任意）](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意) の節で眠らないようにする
