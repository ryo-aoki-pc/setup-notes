# linger 有効化手順（AlmaLinux 10 / ログアウト中も自分のユーザーの systemd を動かす）のロールバックと注意点

[手順書](../linger.md)・[検証記録](../verification/linger.md)・[参考資料](../reference/linger.md)

- 「手順 N」は[手順書](../linger.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

> [!WARNING]
> **linger を切ると、ログアウトしている間は、自分のユーザーのサービスがすべて止まる**（Syncthing・Dropbox・Forgejo・Quadlet のコンテナなど）。止まっていること自体は気付きにくい。

- linger を使う手順書（[Syncthing](syncthing.md#ロールバック)・[Dropbox](dropbox.md#ロールバック)・[Dropbox（rclone）](dropbox-rclone.md#ロールバック)・[Forgejo](forgejo.md#ロールバック)・[Podman の Quadlet](podman.md#ロールバック)）のロールバックを先に行う
- この節の手順も、そのユーザー自身のシェルで貼る

1. ほかに自分で有効にしたユーザーのサービスと、Quadlet の定義が残っていないか見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   ls ~/.config/systemd/user/*.wants/ 2>/dev/null
   ls ~/.config/containers/systemd/ 2>/dev/null
   ```

   - どちらも何も出さなければ、この節の手順 2 で linger を切る
   - 1 つ目の `ls` が何か出す（Syncthing の `sh.brew.syncthing.service`、Dropbox（rclone）の `dropbox-rclone.timer` など）なら、linger はそれが使っているので、この節の手順 2 は飛ばす
   - 2 つ目の `ls` が何か出す（`hello-web.container`・[Forgejo](../forgejo.md) の `forgejo.container` など）なら、[Podman の Quadlet](../podman.md#quadlet-で自動起動する任意) のコンテナが linger を使っているので、この節の手順 2 は飛ばす
   - 1 つ目の `ls` が `podman.socket` だけを出すときは、linger を切ってよい（[podman.md 手順 7](../podman.md#実施手順) の API ソケット。ログインしている間に使うもの）

1. ほかにユーザーのサービスを常駐させていないときだけ、linger を切る。

   ```bash
   sudo loginctl disable-linger "${USER}"
   ```

   - 何も出さずに終わる。`loginctl show-user "$(id -u)" -p Linger` は `Linger=no` になる

---

## 注意点

- **linger はユーザーごとに 1 つで、使う側の手順書で共有する**: どれか 1 本で有効にすれば、ほかの手順書では手順 1 で `Linger=yes` を確かめるだけでよい。切るのは、どれも使わなくなったときだけ（[ロールバック](#ロールバック)）
- **ログアウト中も動かすなら、PC を眠らせない**: linger はサスペンドを止めない（[AlmaLinux 10 の初期設定の「画面オフ・画面ロック・自動サスペンドを止める（任意）」](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)。Workstation で入れた PC は、ログイン画面のまま 15 分で眠る）
- **`sudo -iu` で切り替えたシェルでは、`systemctl --user` が失敗する**: `XDG_RUNTIME_DIR` が無いため（[podman.md の検証記録](../verification/podman.md)・[参考資料](../reference/podman.md)）。常駐させるユーザーで、直接ログインしたシェルを使う
