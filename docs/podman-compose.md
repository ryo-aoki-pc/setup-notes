# podman-compose インストール手順（AlmaLinux 10 / EPEL）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Podman](podman.md) の実施手順と、[EPEL](epel.md) を通してあること（podman-compose は EPEL にあり、AppStream には無い）。`podman info --format '{{.Host.Security.Rootless}}'` が `true` を返さないか、`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（コンテナを自分のユーザーの rootless の podman で動かすため）
> - **手順 1 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）。答えてから手順 2 を貼る
> - **手順 6 の `podman-compose exec` は、動いている間に貼った行をコンテナへの入力として取り込む**。プロンプトが戻ってから次を貼る

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 日々の操作は[使い方の基本](#使い方の基本)、以後は[更新](#更新)・[ロールバック](#ロールバック)
- PC を再起動しても動かしておきたいものは、compose ではなく [podman.md の Quadlet](podman.md#quadlet-で自動起動する任意) で動かす（[注意点](#注意点)）

> [!WARNING]
> **x86_64 の VM で実施手順を検証した。SELinux Enforcing で `:Z` のラベル付けも確認した。実機では本実行していない**（[対象と検証環境](#対象と検証環境)）。

1. 入手できる版を見てから、podman-compose を入れる。

   ```bash
   dnf -q list --showduplicates podman-compose
   sudo dnf install podman-compose
   ```

   - 版は `podman-compose.noarch  1.5.0-1.el10_1  epel` のように 1 つだけ出る
   - 一緒に入るのは Python のライブラリ 4 つ（`python3-click`・`python3-dotenv`・`python3-dotenv+cli`・`python3-pyyaml`）
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y` と答える
   - [epel.md 手順 3](epel.md#実施手順) に書いた鍵
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. podman-compose が入ったか確かめる。

   ```bash
   podman-compose version
   command -v podman-compose
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' podman-compose
   podman compose version
   ```

   - `podman version 5.8.2` と `podman-compose version 1.5.0` の 2 行が出る
   - `/usr/bin/podman-compose`、`podman-compose 1.5.0-1.el10_1 epel` が出る
   - 最後の `podman compose`（podman のサブコマンド）は、`Executing external compose provider "/usr/bin/podman-compose"` と出してから、同じ 2 行を出す

   <details>
   <summary>補足: <code>podman compose</code> と <code>podman-compose</code></summary>

   `podman compose` は podman 自身のサブコマンドで、compose の本体（プロバイダ）を外から呼ぶだけの薄い包み。

   - podman の `man podman-compose` によると、既定のプロバイダは `docker-compose` と `podman-compose` で、**`docker-compose` が入っていればそちらが優先される**
   - 本書のように EPEL の podman-compose だけを入れた状態では、`/usr/bin/podman-compose` が呼ばれた
   - 毎回出る `>>>> Executing external compose provider ...` の案内は、`containers.conf` の `compose_warning_logs = false` で消せる（man の記述。本書では試していない）
   - 環境変数 `PODMAN_COMPOSE_WARNING_LOGS=false` でも消せる（同じ）

   本書では、どのプロバイダが呼ばれるかを迷わないように、`podman-compose` を直接打つ。

   </details>

1. 確認用の compose ファイルとページを置く。

   ```bash
   mkdir -p ~/compose-sample/html
   echo 'hello from compose' > ~/compose-sample/html/index.html
   cat > ~/compose-sample/compose.yaml <<'EOF'
   services:
     web:
       image: registry.access.redhat.com/ubi10/httpd-24:latest
       ports:
         - "127.0.0.1:8081:8080"
       volumes:
         - ./html:/var/www/html:Z
     check:
       image: registry.access.redhat.com/ubi10/httpd-24:latest
       command: sleep infinity
       init: true
   EOF
   cat ~/compose-sample/compose.yaml
   ```

   - `web` は Apache で、`127.0.0.1:8081` で開く。ページは `~/compose-sample/html` から読む
   - `check` は、`web` にサービス名でつながるかを確かめるためだけのコンテナ（同じイメージなので、取得は 1 回で済む）

   <details>
   <summary>補足: compose ファイルの中身</summary>

   | 行 | 意味 |
   |---|---|
   | `image:` | 完全な名前で書く（[podman.md 手順 6](podman.md#実施手順) の補足） |
   | `ports: "127.0.0.1:8081:8080"` | この PC の 127.0.0.1 の 8081 を、コンテナの 8080 につなぐ。[podman.md の Quadlet](podman.md#quadlet-で自動起動する任意)の 8080 と重ならないようにした |
   | `volumes: ./html:/var/www/html:Z` | compose ファイルのある場所からの相対パスで、ページのディレクトリを渡す。`:Z` は SELinux のラベルの付け替え |
   | `command: sleep infinity` | 何もせずに動き続ける |
   | `init: true` | コンテナの PID 1 に小さな init を置き、止めるときの信号を `sleep` に届ける |

   `init: true` が無いと、`sleep infinity` が止める信号（SIGTERM）を無視し、[ロールバック](#ロールバック)の `down` が 10 秒待たされた。付けると 1 秒かからなかった。

   ```
   level=warning msg="StopSignal SIGTERM failed to stop container compose-sample_check_1 in 10 seconds, resorting to SIGKILL"
   ```

   </details>

1. compose ファイルのあるディレクトリで、コンテナを起動する。

   ```bash
   cd ~/compose-sample
   podman-compose up -d
   ```

   - 初回はイメージ（285 MB）を取得する
   - 最後に `compose-sample_web_1` と `compose-sample_check_1` が出る

   <details>
   <summary>補足: <code>up -d</code> が作るもの</summary>

   podman-compose は、ディレクトリの名前（`compose-sample`）をプロジェクトの名前にして、次を作る。

   | 作るもの | 名前 |
   |---|---|
   | pod | `pod_compose-sample` |
   | ネットワーク | `compose-sample_default` |
   | コンテナ | `compose-sample_web_1`・`compose-sample_check_1` |

   - 同じネットワークのコンテナ同士は、サービス名（`web`・`check`）で名前が引ける（手順 6）
   - `-d` を付けないと、ログを表示したまま前で動き続ける

   </details>

1. 起動したコンテナと、公開したポートを確かめる。

   ```bash
   cd ~/compose-sample
   podman-compose ps
   podman pod ps
   curl -s --retry 10 --retry-delay 1 --retry-all-errors http://127.0.0.1:8081/
   ```

   - `podman-compose ps` に 2 つのコンテナが `Up` で出て、`web` の `PORTS` に `127.0.0.1:8081->8080/tcp` が出る
   - `podman pod ps` に `pod_compose-sample` が `Running` で出る
   - `hello from compose` が出ればよい（curl は、Apache が待ち受けるまで 1 秒おきに 10 回まで試し直す）

1. `check` のコンテナから、サービス名 `web` でつながるか確かめる。

   ```bash
   cd ~/compose-sample
   podman-compose exec check curl -s http://web:8080/
   ```

   - `hello from compose` が出ればよい。`web` という名前が、compose のネットワークの中で引けている
   - **次の節は、プロンプトが戻ってから貼る**（続けて貼るとコンテナの中のコマンドへの入力として食われる）

---

## 使い方の基本

どれも compose ファイル（`compose.yaml`）のあるディレクトリで打つ。別の場所からなら `-f <ファイル>` を付ける。

| コマンド | 用途 |
|---|---|
| `podman-compose up -d` | 起動する（無ければ作る） |
| `podman-compose ps` | コンテナの一覧と状態 |
| `podman-compose logs <サービス>` | ログを見る |
| `podman-compose exec <サービス> <コマンド>` | 動いているコンテナの中でコマンドを動かす（動いている間に貼った行を取り込むので、終わってから次を打つ） |
| `podman-compose pull` | イメージを取り直す |
| `podman-compose down` | コンテナ・pod・ネットワークを消す。名前付きのボリュームは残る |
| `podman-compose down -v` | 名前付きのボリュームも消す（中のデータも消える） |

- `down` と `down -v` の違いは、名前付きのボリュームを持つ別の compose ファイルで確かめた（`down` の後も `podman volume ls` に残り、`down -v` で消えた）
- 端末の画面（TUI）でサービスのログを見たり再起動したりするなら、[lazydocker の compose の節](lazydocker.md#compose-のプロジェクトを見る任意)

---

## 更新

1. podman-compose を更新する。

   ```bash
   sudo dnf upgrade podman-compose
   ```

   - システム全体なら `sudo dnf upgrade`
   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. イメージを取り直し、新しいイメージでコンテナを起動し直す。

   ```bash
   cd ~/compose-sample
   podman-compose pull
   podman-compose up -d
   ```

   - `pull` がイメージを取り直し、`up -d` がコンテナを作り直す
   - 新しいイメージが無いときも、`up -d` はコンテナの名前を出して終わる

---

## ロールバック

- 上から順に実行する
- compose で動かしていたデータを残したいときは、この節の手順 2 の前に `~/compose-sample` から取り出しておく

1. コンテナ・pod・ネットワークを消す。

   ```bash
   cd ~/compose-sample
   podman-compose down
   podman pod ps
   ```

   - `podman pod ps` が見出しの行だけになればよい

1. 確認用の compose ファイルとページを消す。

   ```bash
   cd ~
   rm -rf ~/compose-sample
   ```

1. [podman.md の Quadlet](podman.md#quadlet-で自動起動する任意)で同じイメージを使っていないときだけ、イメージを消す。

   ```bash
   podman rmi registry.access.redhat.com/ubi10/httpd-24:latest
   ```

   - 使っているコンテナが残っていると、消せずにエラーになる

1. podman-compose を消す。

   ```bash
   sudo dnf remove podman-compose
   ```

   - `[y/N]` で聞かれる。依存で入った Python のライブラリも、ほかに使うものが無ければ一緒に消える
   - **EPEL 自体は消さない**（ほかのパッケージが使っている可能性がある）。消すなら [epel.md のロールバック](epel.md#ロールバック)

---

## 補足

### 対象と検証環境

- **目的**: compose ファイル（`compose.yaml`）で書いた複数のコンテナを、AlmaLinux 10 の rootless の podman でまとめて動かす
- **進め方**: EPEL（前提の [epel.md](epel.md) で有効にする）の podman-compose を入れ、確認用の compose ファイル（Apache と、つながりを確かめるコンテナ）を起動する。**読者が書き換える変数は無い**
- **状態**: **x86_64 の VM で実施手順 1〜6を検証済み（2026-10-06、SELinux Enforcing）。実機では本実行していない**
  - VM の実測は[今回の付録](#付録-vm-での検証記録2026-10-06)。以下のコンテナでの結果と未確認事項は、当時の検証範囲の記録。
  - 下表の検証コンテナで、[podman.md](podman.md) の実施手順を通したうえで、**この文書のコードブロックをそのまま端末に流して**、EPEL の有効化（今の [epel.md](epel.md) の手順 1〜3。当時はこの文書の手順だった）、手順 1〜6、[更新](#更新)、[ロールバック](#ロールバック)を通した
  - 確認したこと:
    - EPEL の podman-compose 1.5.0 が入り、`podman compose` からも呼ばれる
    - `up -d` で pod・ネットワーク・2 つのコンテナができ、公開したポートとサービス名で `web` に届く
    - `down` で元に戻る
  - **確認していないこと**: SELinux が有効なときの `:Z`、docker-compose をプロバイダにしたとき、再起動の後の動き
  - aarch64（Raspberry Pi 5）では通していない

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2`、Docker 29.3.1、`--privileged`。[podman.md](podman.md) と同じ作り） |
| podman | 未確認 | `podman-5.8.2-9.el10_2.alma.1`（[podman.md](podman.md) の実施手順で導入） |
| EPEL | 未確認 | 未設定 → [epel.md](epel.md) の手順 2 で `epel-release-10-6.el10` を導入 |
| podman-compose | 未導入 | `podman-compose-1.5.0-1.el10_1`（epel） |

> [!NOTE]
> 出力例の値は `<USER>` / `<HOSTNAME>` のプレースホルダで書いてある。バージョン（`1.5.0`）とイメージの大きさは実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（[podman.md](podman.md) の実施手順の後）の状態:

| 項目 | 状態 |
|---|---|
| podman | 5.8.2（rootless で `true`） |
| EPEL | 未設定（`EPEL は未設定`） |
| podman-compose | 未導入 |
| `~/compose-sample` | 無し |

### 選択した方針

| 選択肢 | 採否 |
|---|---|
| **EPEL の podman-compose（1.5.0）** | **採用。** システムの podman と組んで使うので RPM にした（[ツール一覧の選び方](tool-catalog.md#選び方)の規則 3）。`dnf upgrade` で上がる |
| Homebrew の podman-compose（1.6.0） | 不採用。依存として podman 6.1.2 などを連れてきて、PATH の先頭でシステムの podman を隠す（[ツール一覧の注意点](tool-catalog.md#注意点)の実測） |
| pip で入れる（`pip install podman-compose`） | 不採用。`dnf` の管理の外に入り、更新も別になる |
| Docker 社の docker-compose を `podman compose` から使う | 対象外。`podman compose` は docker-compose が入っていればそちらを優先する（手順 2 の補足）。本書では入れていない |
| PC の起動時に自動で動かす | compose では行わない。[podman.md の Quadlet](podman.md#quadlet-で自動起動する任意)で動かす。compose ファイルから Quadlet の定義を作る podlet は[ツール一覧](tool-catalog.md#cli-コンテナ)に載せた |

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

### 注意点

- **`podman-compose exec` が動いている間に貼った行は、コンテナへの入力になる**: 検証では、`exec` の後ろの行を続けて流すと、それらの行は実行されなかった
  - `-T` を付けても同じだった（`-T` は擬似端末を付けないだけで、標準入力はつながったまま）
  - 手順 6 のように、`exec` はブロックの最後に置く
- **PC の再起動では戻らず、linger が無いとログアウトで止まる**: compose で起動したコンテナは、ふつうの `podman run -d` と同じ（[podman.md の注意点](podman.md#注意点)）。常駐させるものは Quadlet にし、[linger](linger.md) を有効にする
- **プロジェクトの名前はディレクトリの名前**: 同じ名前のディレクトリで別の compose ファイルを動かすと、同じ名前の pod・ネットワークを使う。`-p <名前>` で変えられる
- **`down -v` はボリュームの中身も消す**: `down` だけなら名前付きのボリュームは残る（[使い方の基本](#使い方の基本)）
- **1024 未満のポートは使えない**: rootless の podman と同じ制限（[podman.md の注意点](podman.md#注意点)）
- **`:Z` をホームやシステムのディレクトリに付けない**: 付けるのはコンテナ用のディレクトリだけ（[podman.md の注意点](podman.md#注意点)）

### 参照

- [containers/podman-compose — README](https://github.com/containers/podman-compose) — 対応している compose の機能と、オプション
- [Compose Specification](https://compose-spec.io/) — compose ファイルの書式
- `man podman-compose`（podman のパッケージに入っている `podman compose` の説明）/ `podman-compose --help` / `podman-compose <サブコマンド> --help`
- [Podman](podman.md) — 前提の rootless の podman と、自動起動の Quadlet
- [EPEL](epel.md) — 前提の EPEL の有効化

---

### 付録: コンテナでの検証記録（2026-09-27）

**環境**: [podman.md の付録](podman.md#付録-コンテナでの検証記録2026-09-27)と同じ作りの使い捨てのコンテナ。実機で加えた変更は無い。

- `quay.io/almalinuxorg/10-init:10.2` で systemd を PID 1 にし（`--privileged`）、SSH でログインした
- 同じ SSH のセッションで、先に podman.md の手順 1〜3・5〜7 を流した

**手順書の外で行った準備**: podman.md の付録の準備に加えて、EPEL の有効化（今の epel.md の手順 2）の直後に EPEL の metalink に `&protocol=https` を足した（プロキシが平文の HTTP を通さないため）。

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

**環境**: [クリーンインストールからの検証記録](almalinux-vm-verification.md)のコンテナ用 VM。公式 ISO から Workstation を入れた状態から始め、x86_64、SELinux Enforcing、firewalld 有効。本文のブロックを SSH の擬似端末で実行した。

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
