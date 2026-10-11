# Podman インストール手順（AlmaLinux 10 / AppStream・rootless）の検証記録

[手順書](../podman.md)・[ロールバックと注意点](../extra/podman.md)

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

- **目的**: AlmaLinux 10 で、コンテナを自分のユーザー（rootless）で動かせるようにする。[distrobox](../distrobox.md)・[podman-compose](../podman-compose.md)・[hadolint / dive / Trivy](../image-tools.md)・[podman-tui](../podman-tui.md)・[lazydocker](../lazydocker.md) の前提になる（CLI にとっての Homebrew〔[AlmaLinux 10 の初期設定の「Homebrew」](../almalinux-setup.md#homebrew)の手順 1〜3〕と同じ位置づけ）
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **現行 `5da3478` 版を、共通 bash `3d5323e` を新規導入した x86_64 の VM で再検証済み（2026-10-06、SELinux Enforcing）**。実施手順 1〜3・5〜7、Docker API、Quadlet の再起動後の自動起動、ロールバックを通した。subuid/subgid の追加は設定済みのため飛ばした。実機での適用とは別の記録（[今回の付録](#付録-現行版を新規-vm-で再検証2026-10-06)）
  - VM の実測は[今回の付録](#付録-vm-での検証記録2026-10-06)。以下のコンテナでの結果と未確認事項は、当時の検証範囲の記録。
  - 2026-10-11: Hyper-V の VM（AlmaLinux 10.2 / x86_64 / SELinux Enforcing。Kickstart で入れた Workstation のクローンに、[AlmaLinux 10 の初期設定](../almalinux-setup.md)の実施手順と [linger](../linger.md) を通した後の状態）で、`114c2b2` の実施手順・「Docker 向けのツールから使う（任意）」・「Quadlet で自動起動する（任意）」の 12 手順を、SSH の対話の bash に貼って通した（[付録](#付録-hyper-v-の-vm-で通した記録2026-10-11)）
    - 結果: 通した 11、通らなかった 0、条件に当たらず飛ばした 1（実施手順の手順 4。subuid / subgid が両方あった）、未実施 0
    - 確認したこと: Workstation に AppStream の podman 5.8.2 が 16 パッケージで入る、`true overlay crun netavark pasta v2`、API ソケット、`DOCKER_HOST`、Quadlet のサービスが OS の再起動の後に最初のログイン（わざと遅らせた SSH）の 59 秒前に起動する、SELinux Enforcing のまま `:Z` の先が `container_file_t` になる
    - SELinux の拒否: 通しの中の読み（別の SSH から打った `ausearch` の `<no matches>`）は、読み方のせいで当てにならない。後から、この VM のスナップショットのクローンで監査ログのファイルを数え直して、AVC の行は 0 行だった（[数え直し](#selinux-の拒否の数え直しhyper-v2026-10-11)）
    - 直した所: 実施手順の手順 7 の箇条書きに、初めて有効にしたときに出る `Created symlink …` の行を足した（文言だけ。ブロックは変えていない）
    - 未実施の範囲: 実施手順の手順 4 の不足を補う側（今回も当たらなかった）、「使い方の基本」の表、[更新](../podman.md#更新)、[ロールバック](../extra/podman.md#ロールバック)、デスクトップの端末に貼る形、実機、aarch64
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま端末に流して**、手順 1〜3・5〜7、2 つの任意節、[更新](../podman.md#更新)、[ロールバック](../extra/podman.md#ロールバック)を通した
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
| podman | 5.8.2（rootless）。2026-09-22 まで、ほかの手順書の検証に使っていた（[homebrew.md](../almalinux-setup.md) の付録）。この手順で入れたものではなく、2026-09-24 のクリーンインストール後は未確認 | 未確認 | 未導入 → `podman-5.8.2-9.el10_2.alma.1` |
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

---

### 付録: Hyper-V の VM で通した記録（2026-10-11）

- **何を**: [手順書](../podman.md)の実施手順（7 手順）・「Docker 向けのツールから使う（任意）」（1 手順）・「Quadlet で自動起動する（任意）」（4 手順）を、コミット `114c2b2` の本文で、上から通した
  - 「使い方の基本」の表・[更新](../podman.md#更新)・[ロールバック](../extra/podman.md#ロールバック)は、この通しの範囲の外（流していない）
- **結果**: 12 手順のうち、通した 11、通らなかった 0、条件に当たらず飛ばした 1（実施手順の手順 4。subuid / subgid が両方あった）、未実施 0
- **どの状態から**: Hyper-V の VM（Kickstart で入れた AlmaLinux 10.2 の Workstation のクローン）に、[AlmaLinux 10 の初期設定](../almalinux-setup.md)の実施手順を通した後の状態（[その記録](almalinux-setup.md#付録-hyper-vvmwarevirtualbox-の-vm-で今の順番で通した記録2026-10-11)の Hyper-V の列の、スナップショット `after-AS4` の続き）
  - 同じ起動の中で、先に、初期設定の任意節「画面オフ・画面ロック・自動サスペンドを止める（任意）」と [linger](../linger.md) の手順 1・2 を通した（[linger の検証記録の付録](linger.md#付録-hyper-v-の-vm-で通した記録2026-10-11)）。`Linger=yes` になっていた
  - podman は未導入で、`~/.config/containers` は無かった。共通の bash 設定は、初期設定で導入済み
- **誰が・どう通したか**: Claude Code のサブエージェントが、手順書から抜き出したブロックを、SSH の対話の bash にブラケットペーストで 1 つずつ貼った（手順書の「デスクトップの端末か SSH」のうち、SSH の側）
  - 貼ったブロックは、手順書のものと 1 文字も違わない（`session/steps.jsonl` の `sha256` と `pastedSha256` が同じ。今の手順書のブロックとも、sha256 が同じ）
  - VM のコンソールは、同じユーザーで GNOME にログインした状態だった（再起動の後は、手順 4 を貼り終えてからログインし直した）
  - sudo は NOPASSWD（初期設定の「ログインと sudo」の手順 3）で、パスワードは 1 度も聞かれなかった
- **証跡**: 追跡していない `.verification/campaign/hv/CL1/`（このリポジトリには入っていない）。下のファイルの名前は、そこからの相対パス。`seq` は `session/steps.jsonl` の番号、`after-confirm/` は `session/after-confirm/`
- この VM の値は `<USER>`・`<UID>`・`<SERVER_IP>` で書いた。パスワードと鍵は載せていない

#### 環境（Hyper-V、2026-10-11）

| 項目 | 内容 |
|---|---|
| ホスト | Windows 11 Pro 10.0.26300 |
| ハイパーバイザ | Hyper-V（第 2 世代の VM、VM の構成の版 12.0。`meta.json`） |
| VM | UEFI、Secure Boot オフ、2 vCPU、4096 MB（ゲストの `free -m` の合計は 3908 MB）、ディスク 64 GB、NIC 1 枚（`eth0`） |
| ゲスト | AlmaLinux 10.2 (Lavender Lion)、kernel `6.12.0-211.64.1.el10_2.x86_64`、x86_64、SELinux Enforcing、`systemd-257-23.el10_2.2.alma.1`、ロケール `ja_JP.UTF-8`。プロンプトは starship |
| 入ったもの | `podman-5.8.2-9.el10_2.alma.1` と、依存の 15 個（`aardvark-dns-1.17.1-1.el10_2`・`catatonit-0.2.1-1.el10`・`conmon-2.2.1-2.el10`・`container-selinux-2.248.0-1.el10_2`・`containers-common-5.8-2.el10`・`containers-common-extra-5.8-2.el10`・`criu-4.2-2.el10_2.alma.1`・`criu-libs-4.2-2.el10_2.alma.1`・`crun-1.27-2.el10_2`・`libnet-1.3-7.el10`・`netavark-1.17.2-1.el10`・`passt-0^20251210.gd04c480-7.el10_2`・`passt-selinux-0^20251210.gd04c480-7.el10_2`・`podman-sequoia-0.4.0~pqc.3-1.el10_2`・`shadow-utils-subid-4.15.0-11.el10`） |
| イメージ | `quay.io/podman/hello:latest`（`5dd467fce50b`、787 kB）、`registry.access.redhat.com/ubi10/httpd-24:latest`（`1112213d5d2c`、285 MB、ビルドは 2026-10-08） |
| 手順書 | `docs/podman.md`、コミット `114c2b2`（`114c2b2bfd14b51f9e1925b150cbf72e1954f311`） |
| 実施の日時 | 2026-10-11 10:49〜10:53 UTC（ゲストの時計で 19:49〜19:53 JST） |
| 貼り方 | ドライバ（`rb.mjs paste`）で、SSH の対話の bash にブラケットペーストで 1 ブロックずつ。検証用に変えた値は無い |

#### 手順ごとの結果（Hyper-V、2026-10-11）

| 節 | 手順 | 判定 | 結果 | 根拠 |
|---|---|---|---|---|
| 実施手順 | 1 | 通した | `パッケージ podman はインストールされていません` と `podman は未導入`（手順 2 へ進む側） | seq 17、`session/session-001.raw` |
| 実施手順 | 2 | 通した | `podman-7:5.8.2-9.el10_2.alma.1`（AppStream）と依存 15 個の 16 パッケージ（依存は、14 個が AppStream、`shadow-utils-subid` が BaseOS。`ダウンロードサイズの合計: 24 M`、`インストール後のサイズ: 73 M`）。`完了しました!`。`-y` なので問いは出ない。プロンプトの表示で 33 秒 | seq 18、`session/session-001.raw` |
| 実施手順 | 3 | 通した | `/etc/subuid:<USER>:524288:65536` と `/etc/subgid:<USER>:524288:65536` | seq 19、`after-confirm/0019-実施手順-3.txt` |
| 実施手順 | 4 | 条件に当たらず飛ばした | 手順 3 で両方に割り当てが出たので、貼っていない | seq 20（メモの行）、seq 19 の出力 |
| 実施手順 | 5 | 通した | `5.8.2`、`/usr/bin/podman`、`true overlay crun netavark pasta v2`、`/home/<USER>/.local/share/containers/storage` | seq 21、`after-confirm/0021-実施手順-5.txt` |
| 実施手順 | 6 | 通した | イメージの取得の行（`Trying to pull quay.io/podman/hello:latest...` から `Writing manifest to image destination` まで）の後に、`!... Hello Podman World ...!` から始まる絵と案内。`podman images` に `quay.io/podman/hello  latest  5dd467fce50b  2 years ago  787 kB`。取得を含めて 2 秒 | seq 22、`after-confirm/0022-実施手順-6.txt` |
| 実施手順 | 7 | 通した | `Created symlink '/home/<USER>/.config/systemd/user/sockets.target.wants/podman.socket' → '/usr/lib/systemd/user/podman.socket'.` の 1 行の後に、`active`・`OK`・`5.8.2` | seq 23、`after-confirm/0023-実施手順-7.txt` |
| Docker 向けのツールから使う（任意） | 1 | 通した | `unix:///run/user/<UID>/podman/podman.sock` と `"Name":"Podman Engine"` | seq 24、`after-confirm/0024-Docker_向けのツールから使う（任意）-1.txt` |
| Quadlet で自動起動する（任意） | 1 | 通した | 出力の無い手順（エラーは出ていない）。置いたものは、手順 2 の後に別の SSH で見た（生成されたユニットの `SourcePath` と `[X-Container]` の 5 行、`~/hello-web/index.html` の `ls -Z` の行。定義のファイルそのものと、ページの中身を読んだ出力は、証跡のファイルに無い。ページの中身は、手順 2 の `curl` の出力にある） | seq 25、`quadlet-before-reboot.txt` |
| Quadlet で自動起動する（任意） | 2 | 通した | `active`・`generated`・`hello from quadlet`。ブロックの全体で 15 秒（プロンプトの表示。初回の `start` の、285 MB のイメージの取得を含む） | seq 26、`after-confirm/0026-Quadlet_で自動起動する（任意）-2.txt` |
| Quadlet で自動起動する（任意） | 3 | 通した | `sudo systemctl reboot`。パスワードは聞かれず、`The system will reboot now!` の後に SSH が切れた。boot ID が変わった | seq 27、`quadlet-before-reboot.txt`・`quadlet-after-reboot.txt` |
| Quadlet で自動起動する（任意） | 4 | 通した | `ActiveEnterTimestamp=Sun 2026-10-11 19:52:29 JST`、`Timestamp=Sun 2026-10-11 19:53:28 JST`、`hello from quadlet`。サービスの起動が、ログインの 59 秒前 | seq 28（つなぎ直し）・29、`after-confirm/0029-Quadlet_で自動起動する（任意）-4.txt`、`quadlet-after-reboot.txt` |

- 箇条書きに無い行が出たのは、実施手順の手順 7（`Created symlink …` の 1 行）と手順 6（イメージの取得の 5 行）の 2 つ（[指摘と状態](#指摘と状態hyper-v2026-10-11)）。どちらも、箇条書きの成功条件は出ている。ほかは、箇条書きのとおり
- 実施手順の手順 4 の、不足を補う側は、今回も通していない（2026-10-06 の 2 回の VM の検証でも、割り当てが両方あって飛ばしている）
- 手順書には無い確かめ（別の SSH で読んだだけで、何も書き込んでいない。`quadlet-before-reboot.txt`・`quadlet-after-reboot.txt`・`facts-after-reboot.txt`・`guest-facts-end.txt`）
  - 生成されたユニットは `/run/user/<UID>/systemd/generator/hello-web.service` で、`ExecStart=` は、上の「Quadlet で自動起動する（任意） / 手順 2: 補足: 生成されるサービス」の抜粋と同じ行だった
  - `127.0.0.1:8080` を待ち受けるプロセスは `pasta.avx2`
  - SELinux は Enforcing のまま。`~/hello-web` と `index.html` は `container_file_t:s0:c341,c859`、コンテナのプロセスは `container_t:s0:c341,c859` で、カテゴリが一致した。再起動の後の `~/hello-web` は `container_file_t:s0:c88,c600`（カテゴリが変わった）。AVC の拒否を探した読みは、再起動の前も後も `<no matches>` だったが、読み方のせいで当てにならない（[SELinux の拒否の数え直し](#selinux-の拒否の数え直しhyper-v2026-10-11)。後からの数え直しでは 0 行）
  - 再起動の順: ブロックを貼ったのが 19:52:17（`session/session-001.raw` の、再起動の知らせの行の時刻）、起動の時刻が 19:52:24、`<USER>` のユーザーの systemd と `hello-web.service` が 19:52:29、GDM のログイン画面が 19:52:40、最初のログイン（手順 4 を貼った SSH）が 19:53:28。logind のセッションは、Id 1 が linger の `manager`、Id 2 が GDM、Id 3 がこの SSH
    - 起動の時刻は、`quadlet-after-reboot.txt` の boot ID の次の行の値（`idle-check.txt` では `--- uptime` の下にある）。`idle-check.txt` の journal の抜粋には 19:52:22 のカーネルの行があり、`last` の `reboot` の行は 19:52:26 で、数秒の幅がある
  - 再起動の後も、`podman.socket` は `active`・`enabled`、新しいシェルの `DOCKER_HOST` は同じ値、`Linger=yes`
  - 終わりの状態: イメージ 2 つ（285.9 MB）、コンテナ 1 つ（`hello-web`）、ボリューム 0。`~/.local/share/containers` は 284M。`podman-auto-update.timer` は `disabled`

#### 通らなかった手順と、手順書の前提と違えた所（Hyper-V、2026-10-11）

- 通らなかった手順は無い
- 手順書の前提と違えた所も無い。手順書は「デスクトップの端末か SSH」と書いていて、SSH から貼るのは手順書のとおり
- 手順書の外で行ったこと
  - 再起動の後、最初のログインを遅らせた。前の接続が切れてから 70 秒後に、ドライバをつなぎ直した（担当の報告では、SSH のポートが開いたことを TCP の接続だけで見てから、「ログインより前」を意味のある差で見るために待った）
  - ドライバとは別の SSH（鍵で、パスワードなし）で、状態を読んだ（上の「手順書には無い確かめ」）
  - 画面オフの任意節の確かめのために、コンソールで GNOME にログインした（起動の後と、再起動の後の 2 回。2 回目は、Quadlet の節の手順 4 を貼り終えた後）。Podman の手順の前提ではない

#### Hyper-V に左右されたと思われる値（2026-10-11）

担当の報告が挙げた値を、値のまま並べた。ほかのハイパーバイザと比べて確かめたものではない。どれも、手順の「確認」の出力には出ない。

| 項目 | 値 |
|---|---|
| `systemd-detect-virt` | `microsoft`。`hostnamectl` は `Chassis: vm`・`Hardware Vendor: Microsoft Corporation`・`Hardware Model: Virtual Machine`・`Firmware Version: Hyper-V UEFI Release v4.1` |
| NIC と IP | `eth0`、`<SERVER_IP>/20`（VM の起動し直しと、ゲストの再起動の後も同じ）。コンテナの Apache の起動のログ（`AH00558`）に、この IP が出る |
| `podman info` | `rootless=true`・`overlay`・`crun`・`netavark`・`pasta`・cgroup `v2`（`cgroupManager=systemd`、コントローラは `cpu memory pids`）、`arch=amd64` |
| メモリとディスク | `free -m` の合計は 3908 MB。終わりの `/` は 39G のうち 8.1G、`/home` は 19G のうち 6.1G（始めは 8.0G・5.8G） |
| 時間 | `sudo dnf install -y podman` は 33 秒（24 MB のダウンロードは 2 秒）、実施手順の手順 6 のブロック（`podman run --rm quay.io/podman/hello` の取得を含む）は 2 秒、Quadlet の節の手順 2 のブロック（初回の `start` のイメージの取得を含む）は 15 秒。どれも、プロンプトの表示。再起動は、貼ってから 12 秒後にユーザーの systemd が動いていた |
| 失敗しているユニット | `mcelog.service`（起動のたびに failed。初期設定の通しのときから同じ。手順には影響しない。Hyper-V によるかは確かめていない） |

- 時間は、静かなホストで測ったものではない（担当の報告では、同じ時刻に、ほかの検証の VM が同じホストで動いていた）
- 担当の報告は、ハイパーバイザのせいで変わった出力は無い、とみている

#### 過去の記録と違った所（Hyper-V、2026-10-11）

どれも、手順の判定は変えない。

| 所 | 今回（Hyper-V の VM。Workstation） | 過去の記録 |
|---|---|---|
| 実施手順の手順 1 の `rpm -q` の文 | `パッケージ podman はインストールされていません`（ロケールは `ja_JP.UTF-8`） | 2026-09-27 のコンテナは `package podman is not installed`。判定に使う `podman は未導入` は同じ |
| 実施手順の手順 2 で入る数 | 16 パッケージ（ダウンロード 24 M、インストール後 73 M）。`container-selinux` と `passt-selinux` が入った | 2026-09-27 のコンテナは 30 パッケージ（ダウンロード 29 MB、展開後 91 MB）で、`container-selinux` は入らなかった（後ろの「実施手順 / 手順 2: 補足: 一緒に入るものと、container-tools を使わない理由」） |
| Quadlet の節の手順 3 の後の SSH | ブロックを貼ってから 12 秒後にはユーザーの systemd が動いていて、70 秒後のつなぎ直しは 1 回で通った。担当の報告では、コンソールにキーは送っていない | 2026-10-06 の新規 VM（VirtualBox）は、SSH の再接続まで数分待ち、補助として Shift キーを送った |
| `:Z` のカテゴリ | 再起動の前後で、`c341,c859` から `c88,c600` に変わった | 2026-10-06 の記録は、カテゴリがコンテナと一致したことだけを書いている（再起動の前後は比べていない） |

#### 指摘と状態（Hyper-V、2026-10-11）

| 連番 | 重大度 | 場所 | 何が起きたか | 見立て | 状態 |
|---|---|---|---|---|---|
| 1 | 低 | 実施手順の手順 7 の箇条書き（`114c2b2` の `docs/podman.md:105`） | 「確認」の見出しの後ろに、`Created symlink '/home/<USER>/.config/systemd/user/sockets.target.wants/podman.socket' → '/usr/lib/systemd/user/podman.socket'.` が 1 行出てから、`active`・`OK`・`5.8.2` が出た。箇条書きは、後ろの 3 つだけを書いていた | 手順書の書き方。`systemctl --user enable --now` が、初めて有効にしたときに出す行で、「確認」の見出しがその前にあるので、判定する出力に混じる。2026-09-27 のコンテナの記録にも同じ行がある。SSH にも Hyper-V にもよらないとみる（見立て） | 直した（箇条書きを 1 つ足した。文言だけで、ブロックは変えていない。VM では流し直していない） |
| 2 | 低 | 実施手順の手順 6 の箇条書き | 初回は、「確認」の見出しの後ろに、イメージの取得の行が 5 行出てから、`!... Hello Podman World ...!` の絵が出る。箇条書きは、取得の行に触れていない | `podman run` が、手元に無いイメージを取るときの表示。担当の報告は指摘に挙げていない（証跡と照らして気付いた）。読み違えは起きないとみる（見立て） | 未対応（手順書は変えていない） |

- 環境と道具（手順書の指摘ではない）
  - 再起動のブロックを貼ったとき、ドライバは `accepted: false`・`state: disconnected` を返した（bash が行を受け付けた印を見る前に、接続が切れた）。コマンドは動いている（出力に `The system will reboot now!`）。失敗と読まない
  - `mcelog.service` が、起動のたびに failed になる（`systemctl is-system-running` は `degraded` と、担当の報告にある）

#### 手順書を直した所（Hyper-V、2026-10-11）

- `docs/podman.md` の実施手順の手順 7: 箇条書きに「初めて有効にしたときは、その前に `Created symlink …` の行が 1 つ出る」を足した（指摘 1）
  - 文言だけの直し。コードブロックは変えていないので、貼り直す所は無い
  - 足した文は、今回の `after-confirm/0023-実施手順-7.txt` の出力のとおり。2 回目に貼ったときに出ないことは、今回は見ていない
- [ロールバックと注意点](../extra/podman.md)と[参考資料](../reference/podman.md)は、変えていない

#### 報告と証跡の照合（Hyper-V、2026-10-11）

- 12 手順の判定と、「確認」の後ろの出力は、担当の報告（`result.md`）と証跡で食い違わない
- 実施手順の手順 2 の時間: 報告は 35 秒（ドライバの記録の 35.1 秒で、落ち着くのを待つ時間を含む）。プロンプトの表示は `took 33s`。この記録には 33 秒と書いた
- `meta.json` の `snapshot` は `clean-install` と書く。報告は「`after-AS4` の続き」と書き、始めの状態の記録（`guest-facts-start.txt` の、`/home` の使用が 5.8G・podman は未導入。`session/session-001.raw` の starship のプロンプト）は、報告のほうと合う（`/` の 8.0G と `/home` の 5.8G は、初期設定の通しの終わりの値と同じ）。この記録には、報告のほうを書いた
- 報告だけにあって、証跡のファイルでは確かめられないもの
  - `~/.config/containers/systemd/hello-web.container` の大きさ（306 バイト）
  - 再起動のブロックを貼ってから 19 秒後に、SSH のポートが開いていたこと
  - `DOCKER_HOST` を入れた共通の bash 設定の行（`~/.config/bash/bashrc` の 46〜52 行）
  - AVC の拒否を読んだコマンド（`ausearch -m avc -ts boot`。証跡にあるのは、`<no matches>` の行だけ。この読みは、根拠にしていない。[SELinux の拒否の数え直し](#selinux-の拒否の数え直しhyper-v2026-10-11)）
  - 終わりに VM を止めて、スナップショット `after-CL1` を取ったこと

#### SELinux の拒否の数え直し（Hyper-V、2026-10-11）

- **通しの中の読みは、根拠にしない**: 担当は、ドライバとは別の SSH（`tools/side-ssh.sh`。`BatchMode` で、端末は無い）から `sudo -n ausearch -m avc -ts boot` を打ち、再起動の前も後も `<no matches>` を得た（`quadlet-before-reboot.txt`・`quadlet-after-reboot.txt` の最後の行。コマンドは、担当の報告による）
  - `--input-logs` を付けない `ausearch` は、標準入力が端末でないと、監査ログではなく標準入力を読む。標準入力がすぐ閉じれば、ログを見ないまま `<no matches>` を返す
  - 同じ日に、Samba と Syncthing の手順書を通した担当が見つけた（別の SSH から打った `ausearch` が 2 分止まった。追跡していない `.verification/campaign/hv/R3/result.md` の「4. 見つけた不具合」と `R3/facts-avc.txt`）。この VM で、`--input-logs` の有り無しを比べてはいない
- **後から、監査ログのファイルを数え直した**: 2026-10-11 12:44 UTC に、検証の司令塔（単位を担当に割り振る役。通した担当とは別）が、止めてあった VM を起動し直して数えた。`type=AVC`・`type=USER_AVC`・`type=SELINUX_ERR` の行は、どれも 0 行。`getenforce` は `Enforcing`
  - 数えた VM: この通しの終わりのスナップショット `after-CL1` のクローン（`vmv-hv-rdp`）。通しの VM そのもの（`vmv-hv-desktop`）では数えていない。クローンは、この通しまでの監査ログを引き継いでいて、その後に別の手順書の通し（`.verification/campaign/hv/R4/`）に使った分も入っている
  - 数え方: `sudo -n sh -c 'grep -h -c "^type=AVC" /var/log/audit/audit.log* | paste -sd+ | bc'` と、同じ形の `^type=USER_AVC`・`^type=SELINUX_ERR`（ファイルは `audit.log` と `audit.log.1` の 2 つ）。`sudo -n ausearch --input-logs -m AVC,USER_AVC,SELINUX_ERR` は `<no matches>` で、`denied` を含む行も無い
  - ログの範囲: 最初の記録が 2026-10-11 07:23:58 UTC（epoch 秒 `1791703438`。初期設定の通しの始めに、通しの VM を作って起動したころ。`.verification/campaign/hv/AS1/meta.json` の時刻は 07:24:02 UTC）、最後の記録が 12:44:18 UTC（`1791722658`。数え直した時刻）。初期設定の通しと、この通し（10:49〜10:53 UTC。再起動の前も後も）は、この範囲に入る
  - 証跡: 追跡していない `.verification/campaign/hv/AVC-recheck/vmv-hv-rdp/avc.txt`（ゲストで打った行は、同じ `AVC-recheck/` の `remote.sh`）

#### 確かめていないこと（Hyper-V、2026-10-11）

- 実施手順の手順 4 の、不足を補う側。今の形（2026-10-05 に直した後）を、実際のユーザーと podman で通した記録は、まだ無い
- 実施手順の手順 1 が版を出して、手順 2 を飛ばす側
- 実施手順の手順 7 を 2 回目に貼ったときの出力
- 「使い方の基本」の表、更新（`sudo dnf upgrade podman`・`podman auto-update`）、ロールバック
- Docker 向けの節の「既に別の値がある場合」と、lazydocker などから実際につなぐこと
- Quadlet の節で、最初のログインを GDM（デスクトップ）からにした場合（今回の最初のログインは SSH）。再起動しない側
- 資源の制限（`--memory` など）、LAN に公開するポートと firewalld
- デスクトップの端末（Ptyxis・WezTerm）に貼る形
- 実機、aarch64。今回は、VMware と VirtualBox の VM では通していない

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

- `:Z` は、SELinux のラベルをこのコンテナ専用に付け替える指定。ホームそのもの（`%h`）には付けず、コンテナ用のディレクトリにだけ付ける（[注意点](../extra/podman.md#注意点)）
- 検証環境は SELinux が無効だったので、`:Z` の効果は確かめていない
- `ubi10/httpd-24` の Apache は、コンテナの中で root ではないユーザー（`uid=1001(default)`）として動き、8080 で待ち受ける。コンテナの中でも 1024 未満のポートを使わない作りになっている

### 手順中の検証状況

- `true` なら、新しいイメージを取ってサービスを起動し直す（新しいイメージがあったときの動きは確かめていない）

### 実施手順 / 手順 1: 補足: Server の環境では最初から入っている

- 以上は comps の定義を読んだだけで、それぞれの環境で入れた PC では確かめていない
