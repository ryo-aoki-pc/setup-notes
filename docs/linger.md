# linger 有効化手順（AlmaLinux 10 / ログアウト中も自分のユーザーの systemd を動かす）

## 実施手順

- [検証記録](verification/linger.md)・[参考資料](reference/linger.md)

> [!IMPORTANT]
> - **常駐させるユーザー自身のシェル（デスクトップの端末か SSH）で実行する**。`sudo -i` した root のシェルでは行わない（`${USER}` が `root` になる）

- 上から順にコードブロックを貼る
- 手順の後: 以後は[ロールバック](#ロールバック)
- 通すと使えるようになるもの（ログアウトしている間も動く）:
  - [Syncthing](syncthing.md)、[Dropbox（公式クライアント）](dropbox.md)、[Dropbox（rclone）](dropbox-rclone.md)
  - [Podman の Quadlet（任意）](podman.md#quadlet-で自動起動する任意)で動かすコンテナ

1. linger が有効になっているか確かめる。

   ```bash
   loginctl show-user "$(id -u)" -p Linger
   ```

   - `Linger=yes` が出れば、手順 2 は飛ばす（ほかの手順書で有効にしてある）
   - `Linger=no` と出たら、手順 2 で有効にする

1. linger が無効のときだけ、linger を有効にして、有効になったか確かめる。

   ```bash
   {
     sudo loginctl enable-linger "${USER}"
     loginctl show-user "$(id -u)" -p Linger
     ls /var/lib/systemd/linger
   }
   ```

   - linger を有効にすると、ログインしていない間もユーザーの systemd が動き続ける
   - `enable-linger` は何も出さない
   - `Linger=yes` と、自分のユーザー名が出ればよい

---

## ロールバック

> [!WARNING]
> **linger を切ると、ログアウトしている間は、自分のユーザーのサービスがすべて止まる**（Syncthing・Dropbox・Quadlet のコンテナなど）。止まっていること自体は気付きにくい。

- linger を使う手順書（[Syncthing](syncthing.md#ロールバック)・[Dropbox](dropbox.md#ロールバック)・[Dropbox（rclone）](dropbox-rclone.md#ロールバック)・[Podman の Quadlet](podman.md#ロールバック)）のロールバックを先に行う
- この節の手順も、そのユーザー自身のシェルで貼る

1. ほかに自分で有効にしたユーザーのサービスと、Quadlet の定義が残っていないか見る。

   ```bash
   ls ~/.config/systemd/user/*.wants/ 2>/dev/null
   ls ~/.config/containers/systemd/ 2>/dev/null
   ```

   - どちらも何も出さなければ、この節の手順 2 で linger を切る
   - 1 つ目の `ls` が何か出す（Syncthing の `sh.brew.syncthing.service`、Dropbox（rclone）の `dropbox-rclone.timer` など）なら、linger はそれが使っているので、この節の手順 2 は飛ばす
   - 2 つ目の `ls` が何か出す（`hello-web.container` など）なら、[Podman の Quadlet](podman.md#quadlet-で自動起動する任意) のコンテナが linger を使っているので、この節の手順 2 は飛ばす
   - 1 つ目の `ls` が `podman.socket` だけを出すときは、linger を切ってよい（[podman.md 手順 7](podman.md#実施手順) の API ソケット。ログインしている間に使うもの）

1. ほかにユーザーのサービスを常駐させていないときだけ、linger を切る。

   ```bash
   sudo loginctl disable-linger "${USER}"
   ```

   - 何も出さずに終わる。`loginctl show-user "$(id -u)" -p Linger` は `Linger=no` になる

---

## 注意点

- **linger はユーザーごとに 1 つで、使う側の手順書で共有する**: どれか 1 本で有効にすれば、ほかの手順書では手順 1 で `Linger=yes` を確かめるだけでよい。切るのは、どれも使わなくなったときだけ（[ロールバック](#ロールバック)）
- **ログアウト中も動かすなら、PC を眠らせない**: linger はサスペンドを止めない（[gnome-power.md](gnome-power.md)。Workstation で入れた PC は、ログイン画面のまま 15 分で眠る）
- **`sudo -iu` で切り替えたシェルでは、`systemctl --user` が失敗する**: `XDG_RUNTIME_DIR` が無いため（[podman.md の検証記録](verification/podman.md)・[参考資料](reference/podman.md)）。常駐させるユーザーで、直接ログインしたシェルを使う
