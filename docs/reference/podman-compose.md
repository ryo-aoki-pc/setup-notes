# podman-compose インストール手順（AlmaLinux 10 / EPEL）の参考資料

[手順書](../podman-compose.md)・[ロールバックと注意点](../extra/podman-compose.md)

## 補足

### 実施手順 / 手順 1: 補足: 署名鍵

- fingerprint を確かめる EPEL の鍵は、[AlmaLinux 10 の初期設定の手順 17](../almalinux-setup.md#実施手順) に書いた鍵

### 実施手順 / 手順 2: 補足: podman compose

- `podman compose` は podman のサブコマンド

### 実施手順 / 手順 3: 補足: compose ファイルの中身

- `web` は Apache で、`127.0.0.1:8081` で開く。ページは `~/compose-sample/html` から読む
- `check` は、`web` にサービス名でつながるかを確かめるためだけのコンテナ（同じイメージなので、取得は 1 回で済む）

### 実施手順 / 手順 4: 補足: up -d が作るもの

podman-compose は、ディレクトリの名前（`compose-sample`）をプロジェクトの名前にして、次を作る。

| 作るもの | 名前 |
|---|---|
| pod | `pod_compose-sample` |
| ネットワーク | `compose-sample_default` |
| コンテナ | `compose-sample_web_1`・`compose-sample_check_1` |

- 同じネットワークのコンテナ同士は、サービス名（`web`・`check`）で名前が引ける（手順 6）
- `-d` を付けないと、ログを表示したまま前で動き続ける

### 実施手順 / 手順 4: 補足: 初回のイメージの取得

- 初回はイメージ（285 MB）を取得する

### 実施手順 / 手順 5: 補足: curl の試し直し

- curl は、Apache が待ち受けるまで 1 秒おきに 10 回まで試し直す

### 実施手順 / 手順 6: 補足: サービス名で引ける

- `hello from compose` が出れば、`web` という名前が、compose のネットワークの中で引けている

### 更新 / 手順 2: 補足: pull と up -d

- `pull` がイメージを取り直し、`up -d` がコンテナを作り直す

### 参照

- [containers/podman-compose — README](https://github.com/containers/podman-compose) — 対応している compose の機能と、オプション
- [Compose Specification](https://compose-spec.io/) — compose ファイルの書式
- `man podman-compose`（podman のパッケージに入っている `podman compose` の説明）/ `podman-compose --help` / `podman-compose <サブコマンド> --help`
- [Podman](../podman.md) — 前提の rootless の podman と、自動起動の Quadlet
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 前提の EPEL の有効化（手順 17）

---
