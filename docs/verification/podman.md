# Podman インストール手順（AlmaLinux 10 / AppStream・rootless）の検証記録

[手順書](../podman.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 の VM で検証した手順書で、実機では本実行していない。SELinux Enforcing の `:Z` と cgroup v2 の資源制限も確認した**（[対象と検証環境](#対象と検証環境)）。

### 実施手順 / 手順 3: 補足: subuid / subgid の役割

rootless のコンテナでは、コンテナの中の root（UID 0）が自分の UID に、UID 1〜65536 がこの範囲の UID に読み替えられる。範囲が無いと、UID を 1 つしか使えないコンテナになる。

- `useradd` は、ユーザーを作るときに `/etc/login.defs` の `SUB_UID_MIN`（EL10 は 524288）から空いている範囲を割り当てる
- 範囲が無いのは、`useradd` の既定を変えて作ったユーザーなど

範囲の無いユーザー（`useradd -K SUB_UID_COUNT=0 -K SUB_GID_COUNT=0` で作った）で podman を動かしたときの実測:

```
level=error msg="cannot find UID/GID for user <USER>: no subuid ranges found for user \"<USER>\" in /etc/subuid - check rootless mode in man pages."
level=warning msg="Using rootless single mapping into the namespace. This might break some images. Check /etc/subuid and /etc/subgid for adding sub*ids if not using a network user"
```

### 実施手順 / 手順 6: 補足: 短い名前のイメージ

AlmaLinux 10 の `/etc/containers/registries.conf` は、短い名前を次の順で探す設定になっている。

```
unqualified-search-registries = ["registry.access.redhat.com", "registry.redhat.io", "docker.io"]
short-name-mode = "enforcing"
```

- `/etc/containers/registries.conf.d/000-shortnames.conf` に載っている名前（`hello`・`ubuntu`・`nginx` など）は、そこに書かれたレジストリに決まる
- 載っていない名前は、端末（TTY）から実行すると、どれを取るか選ぶように求められる
- 端末でないとき（スクリプトなど）は選択の問い合わせに答えられない。検索順だけで取得できるとは考えず、レジストリから始まる完全な名前を指定する

端末から、載っていない名前を指定したときの実測:

```
$ podman pull ubi10/ubi-minimal
? Please select an image:
  ▸ registry.access.redhat.com/ubi10/ubi-minimal:latest
    registry.redhat.io/ubi10/ubi-minimal:latest
    docker.io/ubi10/ubi-minimal:latest
```

完全な名前で書けば、この問い合わせは起きず、どこから取ったかも文書に残る。

### 実施手順 / 手順 7: 補足: ソケットの仕組み

`podman.socket` はユーザーの systemd が待ち受けるソケットで、要求が来たときだけ `podman.service`（`podman system service`）を起動する。

- `podman.service` は、要求が途切れると数秒で自分から終わる（検証では 7 秒後に `inactive`）
- ソケットのファイルは `srw-rw----` で、持ち主は自分。つなげるのは自分と root だけ
- `http://d/_ping` の `d` は、curl が URL の形を要求するためだけのホスト名で、通信はソケットに行く

`sudo -iu <ユーザー>` で切り替えたシェルで実行したときの実測:

```
Failed to connect to user scope bus via local transport: $DBUS_SESSION_BUS_ADDRESS and $XDG_RUNTIME_DIR not defined (consider using --machine=<user>@.host --user to connect to bus of other user)
```

- 同じシェルの `podman` は、`The cgroupv2 manager is set to systemd but there is no systemd user session available` などの警告を出し、`cgroupfs` に切り替えて動いた
- `su - <ユーザー>` と `runuser -l <ユーザー>` のシェルには `XDG_RUNTIME_DIR` があり、`systemctl --user` が使えた（検証コンテナの systemd 257 で確認）

### Quadlet で自動起動する（任意） / 手順 2: 補足: 生成されるサービス

`daemon-reload` のときに Quadlet が定義を読み、`/run/user/<UID>/systemd/generator/hello-web.service` を作る。中身は次で見られる。

```bash
/usr/libexec/podman/quadlet -dryrun -user
```

出力の抜粋:

```
[Service]
...
ExecStart=/usr/bin/podman run --name hello-web --replace --rm --cgroups=split --sdnotify=conmon -d -v %h/hello-web:/var/www/html:Z --label io.containers.autoupdate=registry --publish 127.0.0.1:8080:8080 registry.access.redhat.com/ubi10/httpd-24:latest

[Install]
WantedBy=default.target
```

生成されたサービスに `systemctl --user enable` を使ったときの実測:

```
Failed to enable unit: Unit /run/user/<UID>/systemd/generator/hello-web.service is transient or generated
```

curl に再試行を付けたのは、最初の検証で `start` の直後の `curl -s http://127.0.0.1:8080/` が何も出さず、終了コード 56（受信の失敗）で終わったため。Apache が待ち受けを始める前だった。



- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

### 対象と検証環境

- **目的**: AlmaLinux 10 で、コンテナを自分のユーザー（rootless）で動かせるようにする。[distrobox](../distrobox.md)・[podman-compose](../podman-compose.md)・[hadolint / dive / Trivy](../image-tools.md)・[podman-tui](../podman-tui.md)・[lazydocker](../lazydocker.md) の前提になる（CLI にとっての [Homebrew](../homebrew.md) と同じ位置づけ）
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **現行 `5da3478` 版を、共通 bash `3d5323e` を新規導入した x86_64 の VM で再検証済み（2026-10-06、SELinux Enforcing）**。実施手順 1〜3・5〜7、Docker API、Quadlet の再起動後の自動起動、ロールバックを通した。subuid/subgid の追加は設定済みのため飛ばした。実機での適用とは別の記録（[今回の付録](#付録-現行版を新規-vm-で再検証2026-10-06)）
  - VM の実測は[今回の付録](#付録-vm-での検証記録2026-10-06)。以下のコンテナでの結果と未確認事項は、当時の検証範囲の記録。
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま端末に流して**、手順 1〜3・5〜7、2 つの任意節、[更新](../podman.md#更新)、[ロールバック](../podman.md#ロールバック)を通した
    - Quadlet の節の linger の有効化と解除（今の [linger.md](../linger.md) の手順 2 とロールバックの手順 2。当時は Quadlet の節とロールバックの手順だった）も、このとき通した
  - 手順 4 は、範囲の無いユーザーを同じコンテナに作って、手順 3〜6 を通した
  - 2026-10-02: もとの手順 4・5 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）
  - 2026-10-05: 手順 3・4 を、subuid / subgid の不足する側だけ補う形に直した。一時ファイルと `sudo`・`usermod`・`podman` のスタブで、両方無し・UID のみ有り・GID のみ有り・両方有りを確認した。既存の範囲を変えず、`usermod` が失敗した場合は migrate を呼ばない。実際のユーザー設定と podman では未実行
  - 確認したこと:
    - rootless で `true overlay crun netavark pasta v2` になり、`quay.io/podman/hello` が動く
    - API ソケットが `OK` を返し、Docker の API の `/version` に `Podman Engine` が出る
    - Quadlet のサービスが、コンテナの中での `sudo systemctl reboot` の後、ログインより前に起動する
    - 短い名前の問い合わせ、1024 未満のポート、linger 無しのログアウトでコンテナが止まることを再現した
  - **確認していないこと**: SELinux が有効なときの `:Z`、cgroup のコントローラと資源の制限、実機の再起動、デスクトップのログイン
  - aarch64（Raspberry Pi 5）では通していない

| 項目 | 実機（Raspberry Pi 5） | 実機（x86_64 PC） | 検証コンテナ |
|---|---|---|---|
| 実施日 | —（未実施） | —（未実施） | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64 | AlmaLinux 10.2 (Lavender Lion) / x86_64 | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2`、Docker 29.3.1、`--privileged`） |
| podman | 5.8.2（rootless）。2026-09-22 まで、ほかの手順書の検証に使っていた（[homebrew.md](../homebrew.md) の付録）。この手順で入れたものではなく、2026-09-24 のクリーンインストール後は未確認 | 未確認 | 未導入 → `podman-5.8.2-9.el10_2.alma.1` |
| systemd | 未確認 | 未確認 | `systemd-257-23.el10_2.2.alma.1`（PID 1） |
| ログイン | — | — | SSH（コンテナの中の `sshd` に、`<USER>` で鍵認証） |
| SELinux | — | — | 無効 |
| cgroup | — | — | v2。ただしコントローラが無い（ホストが cgroup v1 のため） |
| 保管場所のファイルシステム | — | — | ext4（Docker のボリュームをホームに付けた） |

- 実機の 2 列は、この手順を適用した結果ではない

> [!NOTE]
> 出力例の値は `<USER>` / `<UID>` / `<HOSTNAME>` のプレースホルダで書いてある。バージョン（`5.8.2`）とイメージの大きさは実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（AlmaLinux 10 の `10-init` イメージ）の状態:

| 項目 | 状態 |
|---|---|
| podman | 未導入（`package podman is not installed`） |
| `/etc/subuid` | `<USER>:524288:65536`（`useradd` が割り当てた） |
| linger | 無効 |

### 選択した方針

| 選択肢 | 採否 |
|---|---|
| **AppStream の podman を、自分のユーザー（rootless）で使う** | **採用。** Server の環境では最初から入っていて（手順 1 の補足）、`dnf upgrade` で上がる |
| Homebrew の podman（6.1.2） | 不採用。PATH の先頭で `/usr/bin/podman` を隠す（[ツール一覧](../tool-catalog.md#注意点)の実測）。設定も `/home/linuxbrew/.linuxbrew/etc/containers` から読む（formula の定義） |
| root で動かす（`sudo podman`） | 不採用。保管場所が `/var/lib/containers` に分かれ、コンテナが root で動く。1024 未満のポートがどうしても要るときだけ使う |
| Docker Engine（docker-ce） | 対象外。Docker の公式リポジトリに RHEL 10 向けがあるが、本書では入れていない |
| `container-tools`（メタパッケージ） | 不採用。要らないもの（cockpit-podman・toolbox など）まで入る（手順 2 の補足） |
| 自動起動に Quadlet を使う | **採用**（任意節）。podman に含まれ、定義ファイルから systemd のサービスを作る |
| 自動起動に `podman generate systemd` を使う | 不採用。`DEPRECATED command:` と出て、Quadlet を勧められる |

### 完了時点の状態

**検証コンテナでの出力**（実施手順の後）:

```
$ podman version --format '{{.Client.Version}}'
5.8.2
$ command -v podman
/usr/bin/podman
$ podman info --format '{{.Host.Security.Rootless}} {{.Store.GraphDriverName}} {{.Host.OCIRuntime.Name}} {{.Host.NetworkBackend}} {{.Host.RootlessNetworkCmd}} {{.Host.CgroupsVersion}}'
true overlay crun netavark pasta v2
$ podman info --format '{{.Store.GraphRoot}}'
/home/<USER>/.local/share/containers/storage
$ podman images
REPOSITORY            TAG         IMAGE ID      CREATED      SIZE
quay.io/podman/hello  latest      5dd467fce50b  2 years ago  787 kB
$ systemctl --user is-active podman.socket
active
$ curl -s --unix-socket "${XDG_RUNTIME_DIR}/podman/podman.sock" http://d/_ping; echo
OK
$ podman --remote version --format '{{.Server.Version}}'
5.8.2
```

任意節まで通した後は、`~/.bashrc` に `DOCKER_HOST` の行があり、`hello-web.service` が `active`（`generated`）で、`curl -s http://127.0.0.1:8080/` が `hello from quadlet` を返す。

### 付録: コンテナでの検証記録（2026-09-27）

**環境**: Ubuntu 24.04 / x86_64 のクラウドホスト上の Docker 29.3.1（cgroup v1）。実機で加えた変更は無い。

- イメージは `quay.io/almalinuxorg/10-init:10.2`（`sha256:a91c1066…fd73`、AlmaLinux 10.2）
- `--privileged`・`--network host` で立て、systemd を PID 1 にした

**手順書の外で行った準備**（検証環境の都合）:

- **cgroup**: ホストは cgroup v1 なので、コンテナの入口のスクリプトで、ホストの cgroup2 の下に自分の枝を作って `/sys/fs/cgroup` に付け直してから systemd を起動した。この cgroup2 にはコントローラが 1 つも無い
- **PID 数の制限**: podman の既定の制限（2048）を crun が設定できず、``crun: controller `pids` is not available ...`` で失敗した
  - `/etc/containers/containers.conf.d/90-verify-pids.conf` に `pids_limit = 0` を書いて外した
  - `registries.conf` などには触れていない
- **保管場所**: コンテナの `/` は Docker の overlay で、rootless の overlay を重ねられないので、`/home` と `/var/lib/containers` に Docker のボリューム（ext4）を付けた
- **デバイスとマウント**: `/dev/net/tun` と `/dev/fuse` を 0666 に、`/` を shared にした（実機の EL10 と同じ形。Docker の既定のままだと、podman が `"/" is not a shared mount` と警告した）
- **logind**: `10-init` のイメージが mask している `systemd-logind` を戻した
- **プロキシ**: CA を信頼ストアに足し、dnf にプロキシを設定し、AlmaLinux のミラー一覧を https にした。ログインシェルとユーザーの systemd（`/etc/systemd/user.conf.d`）にプロキシの環境変数を渡した
- **ログイン**: コンテナの中の `sshd`（127.0.0.1）に、`<USER>`（NOPASSWD の sudo）で鍵を使ってログインした
  - pam_systemd がセッションを作るので、`XDG_RUNTIME_DIR` とユーザーの systemd は実機の SSH と同じ形で用意される

**流し方**:

- 本文の折り畳みの外にある bash のブロックを上から順に抜き出し、SSH のログインシェルの端末（pty）に 1 ブロックずつ流した。貼り付け（bracketed paste）ではなく 1 行ずつ打ち込む形で、実際に貼るより厳しい
- `[y/N]` の確認には pty 越しに `y` と答えた。コマンドに `-y` は足していない
- 手順 4 は、`useradd -K SUB_UID_COUNT=0 -K SUB_GID_COUNT=0` で作った範囲の無いユーザーで、手順 3〜6 を通した
- Quadlet の節の手順 3 は、コンテナの中で `sudo systemctl reboot` を実行し、止まったコンテナを `docker start` で起動し直した。ログインせずに 30 秒待ってから SSH で入り直し、手順 4 を流した

| 手順 | 結果 |
|---|---|
| 1〜2. 導入 | `podman は未導入` → 30 パッケージ（ダウンロード 29 MB、展開後 91 MB）。`container-selinux` は入らなかった（手順 2 の補足） |
| 3. subuid | `/etc/subuid:<USER>:524288:65536` と `/etc/subgid:<USER>:524288:65536` |
| 4.（範囲の無いユーザー） | 手順 3 は `subuid / subgid の割り当てが無い`。手順 4 で `589824` から割り当てられ、確かめの行（もとの手順 5）は 2 行、手順 5 は `true overlay crun netavark pasta v2`、手順 6 も動いた |
| 5. 設定 | `5.8.2`、`/usr/bin/podman`、`true overlay crun netavark pasta v2`、`/home/<USER>/.local/share/containers/storage` |
| 6. 動作 | `!... Hello Podman World ...!`。`podman images` に `quay.io/podman/hello`（787 kB） |
| 7. ソケット | `Created symlink ...podman.socket ...`、`active`、`OK`、`5.8.2` |
| Docker 向け | `unix:///run/user/<UID>/podman/podman.sock`、`"Name":"Podman Engine"` |
| Quadlet 1・2（当時は linger の有効化と確認も、この節の手順だった。今の linger.md の手順 2） | `Linger=yes`、`active`、`generated`、`hello from quadlet` |
| Quadlet 3・4 | 起動し直した後、ログインする前のセッションは linger の `manager` だけ。`ActiveEnterTimestamp` が 17:38:06、ログインが 17:38:37 で、`hello from quadlet` |
| 更新 | `Nothing to do.`。`podman auto-update` は `UPDATED` が `false` |
| ロールバック | 手順 4 でイメージ 2 つ（285.8 MB）を確かめ、手順 5 の確認に `y`、手順 6 で 30 パッケージを消した（`Freed space: 91 M`） |

**最初の試行で見つけて直したこと**: Quadlet の節の手順 2 の `curl` に再試行を付けていなかったときは、`start` の直後の `curl` が何も出さずに終了コード 56 で終わった（手順 2 の補足）。

**落とし穴の再現**（同じ作りの別のコンテナで、手順書の外のコマンドとして実行）:

- `sudo -iu` / `su -` / `runuser -l` で切り替えたシェルでの `systemctl --user` と `podman`（手順 7 の補足）
- 短い名前の問い合わせ（手順 6 の補足。TTY の有無で比べた）
- 1024 未満のポートのエラー、linger の無いユーザーのログアウト（約 10 秒後にコンテナが止まった）、`sudo podman images`（空の一覧）
- `podman generate systemd` の `DEPRECATED command:`、生成された unit への `systemctl --user enable` のエラー
- [使い方の基本](../podman.md#使い方の基本)の表のコマンド（`podman image prune` は `-a` の有無で消えるものが変わった）

**残っている差**（検証環境と実機の違い）:

- SELinux が無効（`:Z` は効果を確かめていない）
- cgroup v2 にコントローラが無い（`cgroupControllers: []`）。PID 数の制限は検証環境だけ外した
- カーネルはクラウドのホストの 6.18 系（EL10 は 6.12 系）で、IPv6 はホストで無効

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- SELinux が有効なときの `:Z` と、`container-selinux` のラベル
- cgroup のコントローラ（`memory`・`pids` など）の委譲と、`--memory` などの資源の制限
- 実機の再起動の後の Quadlet の起動（検証はコンテナの再起動）
- デスクトップ（GNOME）のログインのセッションから使ったときの動き
- LAN に公開するポートと firewalld
- 新しいイメージがあるときの `podman auto-update`
- Raspberry Pi 5 のカーネルのページサイズと、イメージの動作への影響

---

### 付録: VM での検証記録（2026-10-06）

**環境**: [クリーンインストールからの検証記録](../almalinux-vm-verification.md)のコンテナ用 VM。公式 ISO から Workstation を入れた状態から始め、x86_64、SELinux Enforcing、firewalld 有効。本文のブロックを SSH の擬似端末で実行した。

**検証した版**: `0dbb522`。以下の手順番号と「本文」はこの版を指す。その後に共通 bash 設定へ統一したシェル設定の導入・移行は今回の VM では行っていない。

- Workstation のクリーンインストールでは podman は未導入だった。手順 1〜3・5〜7 を本文のまま SSH の擬似端末で通し、AppStream の podman 5.8.2 が入った。subuid / subgid は両方とも既に `524288:65536` があり、手順 4 は条件に従って飛ばした。不足を補う分岐の本実行は今回もしていない。
- `podman info` は `true overlay crun netavark pasta v2`、確認用イメージが実行でき、API ソケットは `OK` を返した。Docker 向けの任意節も通し、`/version` に `Podman Engine` が出た。
- SELinux は Enforcing のまま。Compose の `:Z` のホスト側ディレクトリは `container_file_t` になり、カテゴリがコンテナの `container_t` と一致した。追加の確認で `--memory 64m --pids-limit 32` を渡すと、コンテナ内の `memory.max` は `67108864`、`pids.max` は `32` だった。
- Quadlet の任意節の手順 1〜4 も通した。再起動後のサービス起動は 04:19:51、最初の SSH ログインは 04:20:12、本文手順 4 のログインは 04:20:42 で、サービスが先に起動した。HTTP は `hello from quadlet`。linger は `yes`、API ソケットも active だった。
- 今回は実機・aarch64、subuid / subgid の不足するユーザー、更新・ロールバックを通していない。以前のコンテナ検証とは範囲を分ける。

---

### 付録: 現行版を新規 VM で再検証（2026-10-06）

**対象**: `setup-notes` の `5da3478` 版。公式 ISO で Workstation を入れた `clean-install` スナップショットから、新規の `alma10-current-20261006-containers` を作った。AlmaLinux 10.2 / x86_64 / SELinux Enforcing / firewalld 有効。共通 bash は `3d5323e` を新規導入した。以前の付録と別の試験で、現行ブロックを SSH の擬似端末で順に実行した。

実施手順 1〜3・5〜7 と Docker API の任意節を通した。subuid/subgid は両方 `524288:65536` だったので、手順 4 は本文の条件に従って飛ばした。Podman は 5.8.2、rootless / overlay / crun / netavark / pasta / cgroup v2。hello コンテナ、ユーザー socket の `active`・`OK`、remote の版を確認した。共通 bash を読み直すと `DOCKER_HOST=unix:///run/user/1000/podman/podman.sock` になり、Docker API の応答にも `Podman Engine` が出た。Quadlet の手順 1・2 で `hello-web` が生成・起動し、HTTP は `hello from quadlet` を返した。

続けて Quadlet の手順 3 の OS 再起動を行い、boot ID が変わったこと、手順 4 のサービス起動時刻、`active` と HTTP 応答を確認した。`~/hello-web` は `container_file_t` とコンテナ専用の MCS カテゴリーになり、SELinux は Enforcing のまま。ユーザー socket と rclone の timer も再起動後に active だった。`podman auto-update --dry-run` は対象の `hello-web` を表示した。SSH の再接続まで数分待ち、補助として VirtualBox から Shift キーを送った。これが必要な条件は切り分けておらず、手順への一般的な追加とはしていない。

ロールバックの手順 1〜6 も、この専用 VM の自分のユーザーで通した。Quadlet のサービス・定義・専用ページを撤去し、socket を無効にした。自分の保管場所にコンテナ・ボリュームが無いことと、今回取得した hello イメージだけが残ることを見てから `podman system reset` の確認に答え、rootless の保管場所を消した。最後に Podman と依存を dnf で削除した。root の KVM イメージの保管場所とは別で、実環境のコンテナを対象にしていない。

### 手順中の実測・検証状況の記録

- 手順 3 で出るはずだった 2 行が出ればよい（検証では、ほかのユーザーの範囲の後ろの `589824` から割り当てられた）

### 手順中の実測・検証状況の記録

- 依存で入ったもの（`crun` など）も一緒に消える。検証コンテナでは、手順 2 で入った 30 パッケージがすべて消えた（`Freed space: 91 M`）

### 手順中の実測・検証状況の記録

- **linger が無いと、ログアウトでコンテナが止まる**: linger の無いユーザーで `podman run -d` を動かしてログアウトすると、約 10 秒後にユーザーの systemd と一緒にコンテナが止まった（検証コンテナで再現）。止めたくないものは Quadlet の節で動かし、[linger](../linger.md) を有効にする

### 手順中の実測・検証状況の記録

- **Docker Hub には、認証なしの取得に回数の上限がある**: 検証の時点の応答は `ratelimit-limit: 100;w=3600`。本書の例は quay.io と registry.access.redhat.com に寄せた

### 実施手順 / 手順 2: 補足: 一緒に入るものと、container-tools を使わない理由

素のコンテナでは、podman と依存の 29 個、合わせて 30 パッケージが入った（ダウンロード 29 MB、展開後 91 MB）。

- SELinux の方針（`selinux-policy`）が入っている PC では、`container-selinux` も一緒に入る（`(container-selinux >= 2:2.162.1 if selinux-policy)` という条件付きの依存）
- 検証コンテナには `selinux-policy` が無いので、`container-selinux` は入らなかった

### 実施手順 / 手順 5: 補足: podman info の読み方

`podman info` の全体は長い。検証コンテナでの抜粋（UID の読み替えの表）:

```
idMappings:
  ...
  uidmap:
  - container_id: 0
    host_id: <UID>
    size: 1
  - container_id: 1
    host_id: 524288
    size: 65536
```

- コンテナの中の 0 が自分の UID に、1〜65536 が手順 3 の範囲に読み替えられている
- 検証コンテナでは `cgroupControllers: []` だった。cgroup v1 のホストの上で動かしたため、コントローラが 1 つも無い（実機の値は確かめていない）

### Quadlet で自動起動する（任意） / 手順 1: 補足: 定義の中身

- `:Z` は、SELinux のラベルをこのコンテナ専用に付け替える指定。ホームそのもの（`%h`）には付けず、コンテナ用のディレクトリにだけ付ける（[注意点](../podman.md#注意点)）
- 検証環境は SELinux が無効だったので、`:Z` の効果は確かめていない
- `ubi10/httpd-24` の Apache は、コンテナの中で root ではないユーザー（`uid=1001(default)`）として動き、8080 で待ち受ける。コンテナの中でも 1024 未満のポートを使わない作りになっている

### 手順中の検証状況

- `true` なら、新しいイメージを取ってサービスを起動し直す（新しいイメージがあったときの動きは確かめていない）

### 実施手順 / 手順 1: 補足: Server の環境では最初から入っている

- 以上は comps の定義を読んだだけで、それぞれの環境で入れた PC では確かめていない
