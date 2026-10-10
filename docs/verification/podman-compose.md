# podman-compose インストール手順（AlmaLinux 10 / EPEL）の検証記録

[手順書](../podman-compose.md)・[ロールバックと注意点](../extra/podman-compose.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 の VM で実施手順を検証した。SELinux Enforcing で `:Z` のラベル付けも確認した。実機では本実行していない**（[対象と検証環境](#対象と検証環境)）。

### 実施手順 / 手順 2: 補足: podman compose と podman-compose

`podman compose` は podman 自身のサブコマンドで、compose の本体（プロバイダ）を外から呼ぶだけの薄い包み。

- podman の `man podman-compose` によると、既定のプロバイダは `docker-compose` と `podman-compose` で、**`docker-compose` が入っていればそちらが優先される**
- 本書のように EPEL の podman-compose だけを入れた状態では、`/usr/bin/podman-compose` が呼ばれた
- 毎回出る `>>>> Executing external compose provider ...` の案内は、`containers.conf` の `compose_warning_logs = false` で消せる（man の記述。本書では試していない）
- 環境変数 `PODMAN_COMPOSE_WARNING_LOGS=false` でも消せる（同じ）

本書では、どのプロバイダが呼ばれるかを迷わないように、`podman-compose` を直接打つ。

### 使い方の基本 / 手順 0: 本文中の記録

- `down` と `down -v` の違いは、名前付きのボリュームを持つ別の compose ファイルで確かめた（`down` の後も `podman volume ls` に残り、`down -v` で消えた）

### 対象と検証環境

- **目的**: compose ファイル（`compose.yaml`）で書いた複数のコンテナを、AlmaLinux 10 の rootless の podman でまとめて動かす
- **進め方**: EPEL（前提の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順 17 で有効にする）の podman-compose を入れ、確認用の compose ファイル（Apache と、つながりを確かめるコンテナ）を起動する。**読者が書き換える変数は無い**
- **状態**: **x86_64 の VM で実施手順 1〜6を検証済み（2026-10-06、SELinux Enforcing）。実機では本実行していない**
  - VM の実測は[今回の付録](#付録-vm-での検証記録2026-10-06)。以下のコンテナでの結果と未確認事項は、当時の検証範囲の記録。
  - 下表の検証コンテナで、[podman.md](../podman.md) の実施手順を通したうえで、**この文書のコードブロックをそのまま端末に流して**、EPEL の有効化（今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順 17。当時はこの文書の手順だった）、手順 1〜6、[更新](../podman-compose.md#更新)、[ロールバック](../extra/podman-compose.md#ロールバック)を通した
  - 確認したこと:
    - EPEL の podman-compose 1.5.0 が入り、`podman compose` からも呼ばれる
    - `up -d` で pod・ネットワーク・2 つのコンテナができ、公開したポートとサービス名で `web` に届く
    - `down` で元に戻る
  - **確認していないこと**: SELinux が有効なときの `:Z`、docker-compose をプロバイダにしたとき、再起動の後の動き
  - aarch64（Raspberry Pi 5）では通していない

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2`、Docker 29.3.1、`--privileged`。[podman.md](../podman.md) と同じ作り） |
| podman | 未確認 | `podman-5.8.2-9.el10_2.alma.1`（[podman.md](../podman.md) の実施手順で導入） |
| EPEL | 未確認 | 未設定 → [epel.md](../almalinux-setup.md) の手順 2 で `epel-release-10-6.el10` を導入 |
| podman-compose | 未導入 | `podman-compose-1.5.0-1.el10_1`（epel） |

> [!NOTE]
> 出力例の値は `<USER>` / `<HOSTNAME>` のプレースホルダで書いてある。バージョン（`1.5.0`）とイメージの大きさは実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（[podman.md](../podman.md) の実施手順の後）の状態:

| 項目 | 状態 |
|---|---|
| podman | 5.8.2（rootless で `true`） |
| EPEL | 未設定（`EPEL は未設定`） |
| podman-compose | 未導入 |
| `~/compose-sample` | 無し |

### 選択した方針

| 選択肢 | 採否 |
|---|---|
| **EPEL の podman-compose（1.5.0）** | **採用。** システムの podman と組んで使うので RPM にした（[ツール一覧の選び方](../tool-catalog.md#選び方)の規則 3）。`dnf upgrade` で上がる |
| Homebrew の podman-compose（1.6.0） | 不採用。依存として podman 6.1.2 などを連れてきて、PATH の先頭でシステムの podman を隠す（[ツール一覧の注意点](../tool-catalog.md#注意点)の実測） |
| pip で入れる（`pip install podman-compose`） | 不採用。`dnf` の管理の外に入り、更新も別になる |
| Docker 社の docker-compose を `podman compose` から使う | 対象外。`podman compose` は docker-compose が入っていればそちらを優先する（手順 2 の補足）。本書では入れていない |
| PC の起動時に自動で動かす | compose では行わない。[podman.md の Quadlet](../podman.md#quadlet-で自動起動する任意)で動かす。compose ファイルから Quadlet の定義を作る podlet は[ツール一覧](../tool-catalog.md#cli-コンテナ)に載せた |

### 完了時点の状態

**検証コンテナでの出力**（手順 2・5・6）:

```
$ podman-compose version
podman-compose version 1.5.0
podman version 5.8.2
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' podman-compose
podman-compose 1.5.0-1.el10_1 epel
$ cd ~/compose-sample
$ podman-compose ps
CONTAINER ID  IMAGE                                             COMMAND               CREATED        STATUS        PORTS                               NAMES
dc725fda5924  registry.access.redhat.com/ubi10/httpd-24:latest  /usr/bin/run-http...  3 seconds ago  Up 3 seconds  127.0.0.1:8081->8080/tcp, 8443/tcp  compose-sample_web_1
0d0009d344fb  registry.access.redhat.com/ubi10/httpd-24:latest  sleep infinity        3 seconds ago  Up 3 seconds  8080/tcp, 8443/tcp                  compose-sample_check_1
$ podman pod ps
POD ID        NAME                STATUS      CREATED         INFRA ID    # OF CONTAINERS
edb0eb30dcd1  pod_compose-sample  Running     12 seconds ago              2
$ curl -s --retry 10 --retry-delay 1 --retry-all-errors http://127.0.0.1:8081/
hello from compose
$ podman-compose exec check curl -s http://web:8080/
hello from compose
```

### 付録: コンテナでの検証記録（2026-09-27）

**環境**: [podman.md の付録](podman.md#付録-コンテナでの検証記録2026-09-27)と同じ作りの使い捨てのコンテナ。実機で加えた変更は無い。

- `quay.io/almalinuxorg/10-init:10.2` で systemd を PID 1 にし（`--privileged`）、SSH でログインした
- 同じ SSH のセッションで、先に podman.md の手順 1〜3・5〜7 を流した

**手順書の外で行った準備**: podman.md の付録の準備に加えて、EPEL の有効化（今の AlmaLinux 10 の初期設定の手順 17）の直後に EPEL の metalink に `&protocol=https` を足した（プロキシが平文の HTTP を通さないため）。

**流し方**: podman.md の付録と同じく、ブロックを 1 行ずつ端末に流し、`[y/N]` には `y` と答えた。

| 手順 | 結果 |
|---|---|
| epel.md 1〜3. EPEL | `EPEL は未設定` → `epel-release-10-6.el10` と依存の 7 つ → `epel` の行 |
| 1. 導入 | `podman-compose.noarch  1.5.0-1.el10_1  epel`。`[y/N]` と EPEL の鍵に `y`。本体と Python のライブラリ 4 つ、合わせて 5 パッケージ（667 k） |
| 2. 確かめる | `podman-compose version 1.5.0` と `podman version 5.8.2`、`/usr/bin/podman-compose`。`podman compose version` は `>>>> Executing external compose provider "/usr/bin/podman-compose". ... <<<<` の後に同じ 2 行 |
| 3. ファイル | `compose.yaml` を置き、`cat` で読み戻した |
| 4. 起動 | ネットワークと pod の ID、イメージの取得、`compose-sample_web_1` と `compose-sample_check_1` |
| 5〜6. 確かめる | [完了時点の状態](#完了時点の状態)のとおり。どちらの `curl` も `hello from compose` |
| 更新 | `sudo dnf upgrade podman-compose` は `Nothing to do.`。`podman-compose pull` がイメージを取り直し、`up -d` はコンテナの名前を 2 つ出した |
| ロールバック | `down` の後の `podman pod ps` は見出しだけ。`podman rmi` でイメージが消え、`dnf remove` で 5 パッケージが消えた（`Freed space: 2.6 M`） |

**別に確かめたこと**（同じ作りの別のコンテナで、手順書の外のコマンドとして実行）:

- `check` に `init: true` を付けないと、`down` が 10 秒待って `StopSignal SIGTERM failed ...` を出した（手順 3 の補足）。付けると 0.9 秒で終わった
- `podman-compose exec`（`-T` の有無の両方）の後ろに行を続けて流すと、それらの行は実行されなかった
- 名前付きのボリュームを持つ compose ファイルで、`down` の後もボリュームが残り、`down -v` で消えた
- `podman-compose --help` の `-p PROJECT_NAME, --project-name PROJECT_NAME`
- 使っているコンテナがあるイメージの `podman rmi` は、`image is in use by a container` で終了コード 2 になった

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- SELinux が有効な PC での `:Z`
- `podman compose` のプロバイダに docker-compose を使ったとき
- `compose_warning_logs = false` で案内が消えること
- `depends_on`・`healthcheck`・`build` など、確認用のファイルで使っていない compose の機能
- podlet で compose ファイルから Quadlet の定義を作ること

---

### 付録: VM での検証記録（2026-10-06）

**環境**: [クリーンインストールからの検証記録](../almalinux-vm-verification.md)のコンテナ用 VM。公式 ISO から Workstation を入れた状態から始め、x86_64、SELinux Enforcing、firewalld 有効。本文のブロックを SSH の擬似端末で実行した。

- クリーンインストール後に podman.md と epel.md を通した VM で、本文の手順 1〜6 をそのまま SSH の擬似端末に貼った。EPEL の podman-compose 1.5.0 が入り、`podman compose` からも呼べた。
- `up -d` で pod・ネットワーク・`web` / `check` ができた。公開ポートとコンテナ間のサービス名 `web:8080` の両方で、確認用の HTML が返った。
- SELinux は Enforcing。ホスト側の HTML ディレクトリが `container_file_t` に変わり、カテゴリが Web コンテナの `container_t` と一致した。以前のコンテナ検証で未確認だった `:Z` を今回確認した。
- VM を再起動すると、この例の `web` / `check` は停止したままだった。自動起動の設定を足していない構成での確認で、再び使うときは `up -d` が要る。
- docker-compose をプロバイダにする分岐、実機・aarch64、更新・ロールバックは今回通していない。

---

### 付録: 現行版を新規 VM で再検証（2026-10-06）

**対象**: `setup-notes` の `5da3478` 版。公式 ISO で Workstation を入れた `clean-install` スナップショットから、新規の `alma10-current-20261006-containers` を作った。AlmaLinux 10.2 / x86_64 / SELinux Enforcing / firewalld 有効。共通 bash は `3d5323e` を新規導入した。以前の付録と別の試験で、現行ブロックを SSH の擬似端末で順に実行した。

実施手順 1〜6 を通した。podman-compose 1.5.0 / Podman 5.8.2。2 コンテナと pod が動き、ホストの `127.0.0.1:8081` と `check` からの `http://web:8080/` は両方 `hello from compose` を返した。共通 bash 導入後の構成でも通った。

ロールバックの手順 1・2・4 を通し、pod・2 コンテナ・ネットワーク・専用ディレクトリ・RPM を撤去した。手順 3 の共有イメージの削除は、lazydocker の確認用コンテナがまだ使っていたため終了 2 で拒否された（本文の注意どおり）。使用元を全て撤去した後、lazydocker のロールバックでその共有イメージを削除できた。


### 操作上の注意と併記されていた記録

- **`podman-compose exec` が動いている間に貼った行は、コンテナへの入力になる**: 検証では、`exec` の後ろの行を続けて流すと、それらの行は実行されなかった


### 実施手順 / 手順 3: 補足: compose ファイルの中身

| 行 | 意味 |
|---|---|
| `image:` | 完全な名前で書く（[podman.md 手順 6](../podman.md#実施手順) の補足） |
| `ports: "127.0.0.1:8081:8080"` | この PC の 127.0.0.1 の 8081 を、コンテナの 8080 につなぐ。[podman.md の Quadlet](../podman.md#quadlet-で自動起動する任意)の 8080 と重ならないようにした |
| `volumes: ./html:/var/www/html:Z` | compose ファイルのある場所からの相対パスで、ページのディレクトリを渡す。`:Z` は SELinux のラベルの付け替え |
| `command: sleep infinity` | 何もせずに動き続ける |
| `init: true` | コンテナの PID 1 に小さな init を置き、止めるときの信号を `sleep` に届ける |

`init: true` が無いと、`sleep infinity` が止める信号（SIGTERM）を無視し、[ロールバック](../extra/podman-compose.md#ロールバック)の `down` が 10 秒待たされた。付けると 1 秒かからなかった。

```
level=warning msg="StopSignal SIGTERM failed to stop container compose-sample_check_1 in 10 seconds, resorting to SIGKILL"
```

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 補足

  - `-T` を付けても同じだった（`-T` は擬似端末を付けないだけで、標準入力はつながったまま）
