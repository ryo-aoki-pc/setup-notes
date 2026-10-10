# Podman インストール手順（AlmaLinux 10 / AppStream・rootless）のロールバックと注意点

[手順書](../podman.md)・[検証記録](../verification/podman.md)・[参考資料](../reference/podman.md)

- 「手順 N」は[手順書](../podman.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

- 上から順に、通した節の分だけ実行する
- この節の手順 5 の前に、ほかの手順書（distrobox・podman-compose・[Forgejo](forgejo.md#ロールバック)）で作ったものが要らないか確かめる。Forgejo が動いているときは先に止め、Quadlet の定義も外す
- Quadlet の節を通し、linger も切るときは、この節の後に [linger.md のロールバック](linger.md#ロールバック)を行う（[Syncthing](../syncthing.md)・[Dropbox](../dropbox.md)・[Forgejo](../forgejo.md) など、ほかに linger を使うものが無いかは、そこで確かめる）

> [!CAUTION]
> **この節の**手順 5 の `podman system reset` で、自分のコンテナ・イメージ・ボリュームがすべて消える。[distrobox](../distrobox.md) のボックスや [podman-compose](../podman-compose.md)・[Forgejo](../forgejo.md) のコンテナも含む。Forgejo の bind mount 先の `~/.local/share/forgejo` と Quadlet の定義は残るので、[Forgejo のロールバック](forgejo.md#ロールバック)で扱う。

1. Quadlet の節を通したときだけ、確認用のサービスと定義とページを消す。

   ```bash
   systemctl --user stop hello-web.service
   rm ~/.config/containers/systemd/hello-web.container
   systemctl --user daemon-reload
   rm -rf ~/hello-web
   ```

1. Docker 向けのツールを閉じ、今のシェルの接続先を外す。

   ```bash
   unset DOCKER_HOST
   ```

   - `~/.bashrc` の行の削除は不要。この節の手順 3 で API ソケットを止める
   - ソケットのファイルが残る間は、新しいシェルでも共通設定が `DOCKER_HOST` を入れる。再起動後にソケットが無ければ入れない

1. API ソケットを止める。

   ```bash
   systemctl --user disable --now podman.socket
   ```

1. 消す前に、残っているものを見る。

   ```bash
   podman ps -a
   podman images
   podman volume ls
   podman system df
   ```

   - **次の手順は、消してよいか確かめてから貼る**

1. 自分のコンテナ・イメージ・ボリュームをすべて消す（取り戻せない）。

   ```bash
   podman system reset
   ```

   - `Are you sure you want to continue? [y/N]` に `y` と答える
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. 手順 2 で podman を入れたときだけ、podman を消す。

   ```bash
   sudo dnf remove podman
   ```

   - `[y/N]` で聞かれる。distrobox や podman-compose を入れていれば、それらも一緒に消える
   - podman-tui は podman に依存しないので残る（[podman-tui のロールバック](podman-tui.md#ロールバック)で消す）
   - 依存で入ったもの（`crun` など）も一緒に消える

---

## 注意点

- **イメージは完全な名前で書く**: 短い名前は、端末から実行すると取る場所を聞かれる（参考資料を参照）
- **`sudo podman` は別の保管場所**: 自分のユーザーのコンテナとイメージは、`sudo podman` からは見えない（[使い方の基本](../podman.md#使い方の基本)）
  - root のコンテナを lazydocker で見るなら、[lazydocker.md の root でも使う](../lazydocker.md#root-でも使う任意)の節（システムの API ソケットを使う）
- **1024 未満のポートは使えない**: 自分のユーザーで `-p 127.0.0.1:80:8080` のように指定すると、次のように失敗する
  - `Error: pasta failed with exit code 1:` と `Failed to bind port 80 (Permission denied) for option '-t 127.0.0.1/80-80:8080-8080'`
  - `sysctl net.ipv4.ip_unprivileged_port_start` は `1024`。8080 など 1024 以上の番号にする
- **`:Z` をホームやシステムのディレクトリに付けない**: `:Z` は指定したディレクトリの SELinux のラベルを付け替える。`podman-run(1)` の `--volume` の説明も、システムのファイルやディレクトリの付け替えを戒めている
- **linger が無いと、ログアウトでコンテナが止まる**: 止めたくないものは Quadlet の節で動かし、[linger](../linger.md) を有効にする
- **API ソケットにつなげると、自分のコンテナを何でも操作できる**: ソケットのファイルの権限（`srw-rw----`、持ち主は自分）を変えない
- **容量**: イメージは `~/.local/share/containers/storage` に溜まる。`podman system df` で見て、`podman image prune -a` で掃除する（`ubi10/httpd-24` は 285 MB）
- **Docker Hub には、認証なしの取得に回数の上限がある**: 本書の例は quay.io と registry.access.redhat.com に寄せた
- **Raspberry Pi 5 で使うイメージは arm64 があるか見る**: `podman manifest inspect <イメージ>` に `"architecture": "arm64"` があればよい。本書の例のイメージにはどれもある
- **Homebrew の formula が podman を連れてくることがある**: podman-compose などを Homebrew で入れると、依存の podman が `/usr/bin/podman` を隠す（[ツール一覧](../tool-catalog.md#注意点)）
  - システムの podman との互換性が要るものや、別の podman を依存で入れるものは RPM を選ぶ
  - [image-tools.md](../image-tools.md) の hadolint・dive と [lazydocker.md](../lazydocker.md) は、RPM の提供状況などを比べて Homebrew を選んでいる
