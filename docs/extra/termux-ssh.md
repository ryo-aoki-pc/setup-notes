# Termux の SSH の注意点

[手順書の「Termux の SSH」](../android.md#termux-の-ssh)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux-ssh.md)・[参考資料](../reference/termux-ssh.md)

- 手順番号は、名前を付けた手順書の項の番号を指す

## 注意点

- sshd は、既定で 8022 番の IPv4・IPv6 のすべてのアドレスに開く。PC の公開鍵を登録し、パスワード認証を止めてから起動する
- 接続先のホスト鍵の指紋が違うときは、接続しない。IP アドレスが同じでも、同じ接続先とは限らない
- wake lock を持たせるときは、電池の消費に注意する。Android の電池の最適化やバックグラウンドの制限で、接続が保たれるかは実機で確かめていない
- `termux-wake-unlock` で wake lock を外す操作は確かめていない
