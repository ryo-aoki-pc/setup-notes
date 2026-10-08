# podman-compose インストール手順（AlmaLinux 10 / EPEL）の参考資料

[手順書](../podman-compose.md)

## 補足

### 実施手順 / 手順 4: 補足: up -d が作るもの

podman-compose は、ディレクトリの名前（`compose-sample`）をプロジェクトの名前にして、次を作る。

| 作るもの | 名前 |
|---|---|
| pod | `pod_compose-sample` |
| ネットワーク | `compose-sample_default` |
| コンテナ | `compose-sample_web_1`・`compose-sample_check_1` |

- 同じネットワークのコンテナ同士は、サービス名（`web`・`check`）で名前が引ける（手順 6）
- `-d` を付けないと、ログを表示したまま前で動き続ける

### 参照

- [containers/podman-compose — README](https://github.com/containers/podman-compose) — 対応している compose の機能と、オプション
- [Compose Specification](https://compose-spec.io/) — compose ファイルの書式
- `man podman-compose`（podman のパッケージに入っている `podman compose` の説明）/ `podman-compose --help` / `podman-compose <サブコマンド> --help`
- [Podman](../podman.md) — 前提の rootless の podman と、自動起動の Quadlet
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 前提の EPEL の有効化（手順 17）

---
