# Podman インストール手順（AlmaLinux 10 / AppStream・rootless）の参考資料

[手順書](../podman.md)

## 補足

### 実施手順 / 手順 1: 補足: Server の環境では最初から入っている

[この節の検証記録](../verification/podman.md#実施手順--手順-1-補足-server-の環境では最初から入っている)

AlmaLinux 10 のインストーラのグループ定義（AppStream の comps）では、Server と Server with GUI の環境に「コンテナー管理」（`container-management`）のグループが入っている。

- このグループの必須パッケージは `podman` と `buildah`。この 2 つの環境で入れた PC には、podman が最初から入っている
- Workstation と Minimal Install の環境には、このグループが無い

### 実施手順 / 手順 2: 補足: 一緒に入るものと、container-tools を使わない理由

| パッケージ | 役割 |
|---|---|
| `crun` | コンテナを実際に起動するランタイム（OCI ランタイム） |
| `conmon` | コンテナごとに付き添い、ログと終了コードを受け取る |
| `netavark` / `aardvark-dns` | コンテナのネットワークと、コンテナ名での名前解決 |
| `passt` | rootless のネットワーク（`pasta`）。ポートの公開もここを通る |
| `containers-common` | `/etc/containers` の設定（レジストリ、署名の方針、保管の方式） |
| `shadow-utils-subid` | subuid / subgid を読むライブラリ（手順 3） |
| `criu` | コンテナのチェックポイントと復元（本書では使わない） |

AppStream には、podman・buildah・skopeo・toolbox・cockpit-podman・podman-docker・udica などをまとめて入れるメタパッケージ `container-tools` もある。

- 本書は podman だけを入れ、ほかは[ツール一覧](../tool-catalog.md#cli-コンテナ)から要るものを足す形にした

### 実施手順 / 手順 5: 補足: podman info の読み方

3 行目の 6 つの値の意味:

| 値 | 意味 |
|---|---|
| `true` | rootless（自分のユーザー）で動いている |
| `overlay` | イメージの層を重ねて保管する方式 |
| `crun` | OCI ランタイム |
| `netavark` | コンテナのネットワーク |
| `pasta` | rootless のネットワークと、ポートの公開 |
| `v2` | cgroup v2 |

### Quadlet で自動起動する（任意） / 手順 1: 補足: 定義の中身

| 行 | 意味 |
|---|---|
| `Image=` | イメージ。完全な名前で書く（手順 6 の補足） |
| `ContainerName=` | コンテナの名前。`podman ps` に出る |
| `PublishPort=127.0.0.1:8080:8080` | この PC の 127.0.0.1 の 8080 を、コンテナの 8080 につなぐ。`127.0.0.1:` を付けているので、この PC の中からしか開けない |
| `Volume=%h/hello-web:/var/www/html:Z` | ホームの `hello-web` を、コンテナの公開ディレクトリにする。`%h` はホームディレクトリ |
| `AutoUpdate=registry` | `podman auto-update` の対象にする（[更新](../podman.md#更新)） |
| `TimeoutStartSec=300` | 初回はイメージの取得を待つので、起動の待ち時間を延ばす |
| `WantedBy=default.target` | ユーザーの systemd が起動したときに、このサービスも起動する |

### 参照

- [Basic Setup and Use of Podman in a Rootless environment](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md) — rootless の前提（subuid / subgid、保管場所、ネットワーク）
- [podman-systemd.unit(5)](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) — Quadlet の定義の書き方
- [podman-auto-update(1)](https://docs.podman.io/en/latest/markdown/podman-auto-update.1.html) / [podman-system-service(1)](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html) / [podman-system-reset(1)](https://docs.podman.io/en/latest/markdown/podman-system-reset.1.html)
- [podman-run(1)](https://docs.podman.io/en/latest/markdown/podman-run.1.html) — `--volume` の `:Z`、`--publish`
- [RHEL 10 — Building, running, and managing containers](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/building_running_and_managing_containers/index) — RHEL の podman の文書
- `man containers-registries.conf` — 短い名前の扱い（`unqualified-search-registries`・`short-name-mode`）
- [linger](../linger.md) — [Quadlet の節](../podman.md#quadlet-で自動起動する任意)の前提の手順書

---
