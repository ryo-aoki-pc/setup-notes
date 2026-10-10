# linger 有効化手順（AlmaLinux 10 / ログアウト中も自分のユーザーの systemd を動かす）

## 実施手順

- [検証記録](verification/linger.md)・[参考資料](reference/linger.md)・[ロールバックと注意点](extra/linger.md)

> [!IMPORTANT]
> - **常駐させるユーザー自身のシェル（デスクトップの端末か SSH）で実行する**。`sudo -i` した root のシェルでは行わない（`${USER}` が `root` になる）

- 上から順にコードブロックを貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 手順の後: 以後は[ロールバック](extra/linger.md#ロールバック)
- 通すと使えるようになるもの（ログアウトしている間も動く）:
  - [Syncthing](syncthing.md)、[Dropbox（公式クライアント）](dropbox.md)、[Dropbox（rclone）](dropbox-rclone.md)、[Forgejo](forgejo.md)
  - [Podman の Quadlet（任意）](podman.md#quadlet-で自動起動する任意)で動かすコンテナ

1. linger が有効になっているか確かめる。

   ```bash
   loginctl show-user "$(id -u)" -p Linger
   ```

   - `Linger=yes` が出れば、手順 2 は飛ばす
   - `Linger=no` と出たら、手順 2 で有効にする

1. linger が無効のときだけ、linger を有効にして、有効になったか確かめる。

   ```bash
   {
     sudo loginctl enable-linger "${USER}"
     printf '\n\033[7m 確認 \033[0m\n'
     loginctl show-user "$(id -u)" -p Linger
     ls /var/lib/systemd/linger
   }
   ```

   - `enable-linger` は何も出さない
   - `Linger=yes` と、自分のユーザー名が出ればよい
