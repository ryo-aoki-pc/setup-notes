# Dropbox の注意点

[手順書](../dropbox.md#dropbox)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/dropbox.md)・[参考資料](../reference/dropbox.md)

- 「手順 N」は[手順書](../dropbox.md#dropbox)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **Basic（無料）プランは同時に 3 台まで**: 公式クライアントは、そのうちの 1 台に数えられる（公式ヘルプ。dropbox.com へのログインは数えない）
- **リンクすると全部落ちてくる**: headless では、最初に同期するフォルダを選べない。要らないフォルダは、リンクした直後に `dropbox exclude add` で外す（[使い方の基本](../dropbox.md#dropbox-使い方の基本)）
- **LAN 同期の受信は開けていない**: firewalld の定義済みサービス `dropbox-lansync`（17500/tcp・udp）は開けていない
  - LAN 内にほかの公式クライアントが無ければ要らない（Raspberry Pi 5 は rclone なので、LAN 同期に加わらない）
  - 使うなら `sudo firewall-cmd --permanent --add-service=dropbox-lansync` と `sudo firewall-cmd --reload`
- **`dropbox stop` は戻される**: `Restart=always` なので 10 秒後に起こし直される。止めるなら `systemctl --user stop dropbox.service`
- **リンク用の URL は他人に見せない**: 開いた人のアカウントにこの PC がつながる。リンクするまでは journal にも 5 秒ごとに残る
- **眠ると止まる**: サスペンド中は同期しない。常時動かす PC は [画面オフ・画面ロック・自動サスペンドを止める](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める) の節で眠らないようにする
- **フォルダの場所は `~/Dropbox` のまま**: headless の `dropbox` コマンドには、場所を移す機能が無い
