# Termux の SSH の参考資料

[手順書](../android.md#termux-の-ssh)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux-ssh.md)・[注意点](../extra/termux-ssh.md)

## 選択した方針

- Termux からホストへは公開鍵でつなぎ、ホストの tmux を使う。ホストで動かす AI エージェントの導入は [AI エージェントの手順書](../ai-agents.md)で扱う
- PC から Termux へは、公開鍵だけを許可した sshd でつなぐ。手動の起動と停止を確かめてから、termux-services でも起動できるようにする

## 補足

### Termux の SSH / 手順 3〜8: 補足: 鍵と接続の設定

- Termux の OpenSSH でも ed25519 の鍵と `~/.ssh/config` の Host を使える。HostName・Port・IdentityFile・IdentitiesOnly を指定して、別名でつなげた
- ホスト側で出したホスト鍵の指紋と、接続先から得た指紋が一致した。指紋は、初めてつなぐ相手を確かめるために使う
- ホストの代わりに、Termux 自身の sshd（`127.0.0.1` の 8022 番）を相手にして、別名での接続とホストの tmux への出入りを確かめた。AlmaLinux 10・Windows 11 のホストへの接続は確かめていない

### Termux の SSH / Termux の SSH: PC から Termux に入る / 手順 2・3・6: 補足: sshd の設定

- Termux の sshd は、既定で 8022 番の IPv4・IPv6 のすべてのアドレスで待ち受ける
- `sshd_config` は `$PREFIX/etc/ssh/sshd_config.d/*.conf` を読み、公開鍵は `~/.ssh/authorized_keys` から読む
- Termux はユーザーを 1 つだけ持つ。PC から接続するときのユーザー名は問わない
- `sshd -T` は、設定の名前を `PasswordAuthentication` のように大文字の混じった形で出す。手順書の確認は `grep -i` で探す
- PC からの接続は、エミュレーターに `adb forward` で 8022 番をつないで確かめた。スマートフォンの IP への LAN・WireGuard 越しの接続は確かめていない

### Termux の SSH / Termux の SSH: PC から Termux に入る / 手順 4・5・7: 補足: wake lock と IP アドレス

- `termux-wake-lock` を実行し、Android の許可に答えると、Termux の通知に `wake lock held` が出て、電池の最適化の例外に入った
- `termux-wake-unlock` で、通知は `1 session` に戻った
- `ifconfig` は `/proc/net/dev` を読めない警告を出すが、`wlan0` の `inet` に IP アドレスが出た

### Termux の SSH / Termux の SSH: sshd を termux-services で動かす / 手順 2〜5: 補足: ログインシェルとサービス

- termux-services は、シェルの起動時に `service-daemon` を始める。`SVDIR` はログインシェルで入るので、導入後に `exec bash -l` で読み直す
- sshd は、最初は `down` のファイルがあり、止まっている。`sv-enable sshd` で有効にすると、サービスが sshd を起動する
- 手で起動した sshd を止めてから有効にすると、ログに 8022 番の待ち受けが出て、PC から入り直せた
- `sv-disable sshd` で `down: sshd` になり、PC から入れなくなった。Termux の APK を入れ直した後も、Termux を開くと `service-daemon` が動き出した

## 参照

- [Termux の OpenSSH パッケージ](https://github.com/termux/termux-packages/tree/master/packages/openssh)
- [termux-services](https://github.com/termux/termux-services)
- [AlmaLinux 10 の「SSH を公開鍵だけにする」](../almalinux-setup.md#ssh-を公開鍵だけにする)
- [Windows 11 の「OpenSSH サーバー」](../windows-setup.md#openssh-サーバー)
