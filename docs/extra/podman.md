# Podman の注意点

[手順書](../containers.md#podman)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/podman.md)・[参考資料](../reference/podman.md)

- 「手順 N」は[手順書](../containers.md#podman)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **イメージは完全な名前で書く**: 短い名前は、端末から実行すると取る場所を聞かれる（参考資料を参照）
- **`sudo podman` は別の保管場所**: 自分のユーザーのコンテナとイメージは、`sudo podman` からは見えない（[使い方の基本](../containers.md#podman-使い方の基本)）
  - root のコンテナを lazydocker で見るなら、[lazydocker: root でも使う](../containers.md#lazydocker-root-でも使う)の節（システムの API ソケットを使う）
- **1024 未満のポートは使えない**: 自分のユーザーで `-p 127.0.0.1:80:8080` のように指定すると、次のように失敗する
  - `Error: pasta failed with exit code 1:` と `Failed to bind port 80 (Permission denied) for option '-t 127.0.0.1/80-80:8080-8080'`
  - `sysctl net.ipv4.ip_unprivileged_port_start` は `1024`。8080 など 1024 以上の番号にする
- **`:Z` をホームやシステムのディレクトリに付けない**: `:Z` は指定したディレクトリの SELinux のラベルを付け替える。`podman-run(1)` の `--volume` の説明も、システムのファイルやディレクトリの付け替えを戒めている
- **linger が無いと、ログアウトでコンテナが止まる**: 止めたくないものは Quadlet の節で動かし、[linger](../almalinux-setup.md#ユーザーサービスの常駐) を有効にする
- **API ソケットにつなげると、自分のコンテナを何でも操作できる**: ソケットのファイルの権限（`srw-rw----`、持ち主は自分）を変えない
- **容量**: イメージは `~/.local/share/containers/storage` に溜まる。`podman system df` で見て、`podman image prune -a` で掃除する（`ubi10/httpd-24` は 285 MB）
- **Docker Hub には、認証なしの取得に回数の上限がある**: 本書の例は quay.io と registry.access.redhat.com に寄せた
- **Raspberry Pi 5 で使うイメージは arm64 があるか見る**: `podman manifest inspect <イメージ>` に `"architecture": "arm64"` があればよい。本書の例のイメージにはどれもある
- **Homebrew の formula が podman を連れてくることがある**: podman-compose などを Homebrew で入れると、依存の podman が `/usr/bin/podman` を隠す（[ツール一覧](../tool-catalog.md#注意点)）
  - システムの podman との互換性が要るものや、別の podman を依存で入れるものは RPM を選ぶ
  - [画像の道具](../almalinux-setup.md#画像の道具) の hadolint・dive と [lazydocker](../containers.md#lazydocker) は、RPM の提供状況などを比べて Homebrew を選んでいる
