# Dropbox と rclone の注意点

[手順書](../dropbox.md#dropbox-と-rclone)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/dropbox-rclone.md)・[参考資料](../reference/dropbox-rclone.md)

- 「手順 N」は[手順書](../dropbox.md#dropbox-と-rclone)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **bisync は rclone の「advanced command」**: rclone の文書は、注意して使うよう書いている。削除も伝わる双方向同期なので、[使い方の基本](../dropbox.md#dropbox-と-rclone-使い方の基本)の削除と競合の扱いを先に読んでおく
- **毎回すべてを一覧する**: 15 分ごとに Dropbox の全体を一覧するので、ファイルが多いと時間と API の呼び出しが増える
  - 既定では rclone 全体で共有の Dropbox の app key を使う。`too_many_requests` が続くなら、間隔を広げるか、rclone の文書のとおり自分の app key を作る
- **Dropbox は大文字と小文字を区別しない**: 手元で大文字と小文字だけが違う 2 つのファイルは、Dropbox 側でぶつかる。Dropbox が受け付けない名前もある
- **止めるときは `systemctl --user stop`**: SIGTERM を受けた rclone は、転送中のファイルを片づけて止まる
  - `kill -9`・電源断・SSH の切断（SIGHUP）では、その場で止まり、ロックと書きかけが残る
  - ロックは `--max-lock 2m` で 2 分後に切れ、timer の次の回が `--recover` で回復を試みる
- **トークンは平文で入る**: `~/.config/rclone/rclone.conf`（権限 600）にある。`rclone config create` はトークン入りの設定を画面に出すので、手順 2 では `>/dev/null` を付けた
- **linger は、ほかのユーザーサービス（Syncthing など）と共有する**: linger を切るのは、どれも使わなくなったときだけ
- **Syncthing・Samba と重ねない**: `~/Dropbox` を Syncthing の同期フォルダに入れない（2 つの同期が同じファイルを書き合う）。[Samba](../samba.md#samba-サーバー) でホームを公開していると、`~/Dropbox` も SMB から見える
- **端末の上限**: Basic（無料）プランは同時に 3 台まで。rclone のような連携アプリが数えられるかは、公式ヘルプに書かれていない
- **眠ると止まる**: サスペンド中は同期しない。常時動かすなら [画面オフ・画面ロック・自動サスペンドを止める](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める) の節で眠らないようにする
