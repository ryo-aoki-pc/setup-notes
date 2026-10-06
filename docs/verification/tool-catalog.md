# AlmaLinux 10 の CLI / GUI ツール導入元一覧の検証記録

[手順書](../tool-catalog.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### AlmaLinux 10 の CLI / GUI ツール導入元一覧: 検証状況の記録

> [!WARNING]
> **状態**: **調査は 2026-09-24（UTC 20:51〜21:20）**。検証の方法と環境は[補足](../reference/tool-catalog.md#補足)にまとめた。
>
> - x86_64 は AlmaLinux 10.2 のコンテナで、**表の導入コマンドを実行して入ることを確かめた**。確かめた深さは行ごとの「確認」列に書いてある
> - **aarch64 の列は、リポジトリのメタデータと API から調べただけ**で、どの行も実機にもコンテナにも入れていない
> - GUI アプリはどれも画面を出していない
> - 実機（Raspberry Pi 5 と x86_64 PC）には何も入れていない
> - **[CLI: コンテナ](../tool-catalog.md#cli-コンテナ)と GUI の[コンテナ](../tool-catalog.md#コンテナ)の節は 2026-09-27（UTC 16:26〜17:40）に調べた**。このとき表にあった podman-tui と lazydocker は、2026-09-28 に手順書にした（[文書化済みのツール](../tool-catalog.md#文書化済みのツール)）
> - 2026-09-28 に、[ベンダーの dnf リポジトリ](../tool-catalog.md#ベンダーの-dnf-リポジトリ)と[更新](../tool-catalog.md#更新)のブロックを `{ … }` で囲んだ（[README の記法](../../README.md#記法)）。中のコマンドは変えていない
> - [CLI: 定番の置き換え](../tool-catalog.md#cli-定番の置き換え)の表にあった tmux は、2026-10-01 に手順書にした（[文書化済みのツール](../tool-catalog.md#文書化済みのツール)）
> - 同じ表にあった fzf は、2026-10-02 に手順書にした（bash への組み込みまで。[文書化済みのツール](../tool-catalog.md#文書化済みのツール)）
> - 2026-10-03 に、zoxide の dnf（COPR）の経路を zoxide.md から外し、[文書化済みのツール](../tool-catalog.md#文書化済みのツール)の「zoxide（dnf）」の行を消した

### CLI: 定番の置き換え / 手順 0: 本文中の記録

- 試していないこと: `~/.bashrc` に追記して使うもの（atuin など。[zoxide](../zoxide.md) と同じ形）のシェルへの組み込み、mosh のサーバー側の導入と UDP の許可

### CLI: コンテナ / 手順 0: 本文中の記録

- この節は 2026-09-27 に調べた（[付録](#付録-コンテナ関連の追加調査2026-09-27)）

### コンテナ / 手順 0: 本文中の記録

- Podman Desktop の行は 2026-09-24 の調査。ほかの 3 行は 2026-09-27 に調べた

### コンテナ / 手順 0: 本文中の記録

- Cockpit は `sudo systemctl enable --now cockpit.socket` の後、`https://127.0.0.1:9090/` が応答し、`/usr/share/cockpit/podman` があることまで確かめた。ブラウザでのログインと画面は見ていない

### コンテナ / 手順 0: 本文中の記録

- distrobox の GUI には DistroShelf（Flathub `com.ranfdev.DistroShelf` 1.5.2、検証済み、GNOME 50）もある（メタデータのみ）

### 対象と検証環境

- **目的**: AlmaLinux 10 で使う CLI・GUI ツールを、導入元ごとに比べて 1 か所から選べるようにする。**個別の手順書を作るほどではないツールは、この一覧の 1 行で済ませる**

| 項目 | 値 |
|---|---|
| 調査日時 | 2026-09-24、UTC 20:51〜21:20（版の取得は 20:51〜20:57） |
| 検証コンテナ | `quay.io/almalinuxorg/almalinux:10`（`sha256:83220192…c4c8`、AlmaLinux 10.2 (Lavender Lion) / x86_64、dnf 4.20.0） |
| コンテナの動かし方 | Ubuntu 24.04 / x86_64 のクラウドホスト上の Docker 29.3.1。`--network host`、Flatpak だけ `--privileged`。非 root ユーザーに NOPASSWD の sudo |
| Homebrew | 7.0.6（[homebrew.md](../homebrew.md) の手順 1〜3 をそのまま通して導入） |
| EPEL | `epel-release-10-6.el10`（`extras`）。CRB はイメージの既定で有効 |
| flatpak | `flatpak-1.16.0-9.el10_2.1`（AppStream） |
| aarch64 の調べ方 | RPM: `dnf --forcearch=aarch64 repoquery`。Homebrew: formulae.brew.sh の JSON のボトル（`arm64_linux`）。Flathub: `flatpak remote-ls --arch=aarch64` と `flatpak remote-info --arch=aarch64` |
| コンテナの節の調査日時 | 2026-09-27、UTC 16:26〜17:40 |
| コンテナの節の検証コンテナ | `quay.io/almalinuxorg/10-init:10.2`（`sha256:a91c1066…fd73`）を `--privileged` で立て、systemd を PID 1 にした。中で rootless の podman を動かすため（[podman.md](../podman.md) の付録と同じ作り） |
| コンテナの節の aarch64 の調べ方 | RPM: AppStream・BaseOS・EPEL 10.2・Trivy のリポジトリの `primary.xml` を直接読んだ。Homebrew と Flathub は上と同じ |

- これまでの手順書の「コンテナのみ」の検証は、実機（Raspberry Pi 5）の上の podman で `docker.io/library/almalinux:10` を使っていた
- **この一覧は x86_64 のクラウドホスト上の Docker で、`quay.io` の同じ AlmaLinux 10 公式イメージを使っている**（Docker Hub がレート制限を返したため）

### 操作上の注意と併記されていた記録

- **Flathub の「検証済み」はアプリの公開元の確認**で、中身の審査ではない

### 操作上の注意と併記されていた記録

- **EL10 の rpm は、自己署名のハッシュが SHA-1 の古い鍵を取り込まない**（ベンダーのリポジトリの鍵で実測）

### 注意点 / 手順 0: 本文中の記録

  - 代わりに、aarch64 に提供があるものはすべて、`flatpak remote-info` のコミットの件名が x86_64 と一致することを確かめた（同じ版のビルドと推定できる）

### 注意点 / 手順 0: 本文中の記録

  - 調査時は、ほかのアプリも合わせた 13 本で 8.1 GB になった（[付録](#付録-コンテナでの検証記録2026-09-24)）

### 付録: コンテナでの検証記録（2026-09-24）

使い捨てのコンテナを 5 つ使い分けた。どれも同じイメージで、プロキシの CA を信頼ストアに足し、`tester` ユーザーに NOPASSWD の sudo を与えている。

| コンテナ | 用途 |
|---|---|
| `meta` | 版の調査だけ（EPEL と flatpak を入れて照会） |
| `cli` | Homebrew と CLI（Homebrew / EPEL / mise のリポジトリ） |
| `gui` | GUI の RPM（ベンダー / EPEL） |
| `fp` | [flatpak.md](../flatpak.md) の検証と、この一覧の Flathub のアプリ（`--privileged`） |
| `fps` | 再現の確認だけ（Flathub 登録直後の `flatpak search`） |

**版の調査で使ったコマンド**（`meta` で実行。`$(cat /tmp/rpmnames.txt)` はパッケージ名の一覧、`"..."` は 1 行目と同じ書式、`<...>` は実際には値を入れた）:

```
dnf -q repoquery --latest-limit=1 --arch=x86_64,noarch --qf "%{name}\t%{version}-%{release}\t%{arch}\t%{repoid}\n" $(cat /tmp/rpmnames.txt)
dnf -q --forcearch=aarch64 --setopt=cachedir=/var/cache/dnf-aarch64 repoquery --latest-limit=1 --arch=aarch64,noarch --qf "..." $(cat /tmp/rpmnames.txt)
dnf -q --forcearch=<ARCH> --repofrompath=<ID>,<URL> --repo=<ID> repoquery --latest-limit=1 --qf "..." <PACKAGE>
flatpak remote-ls flathub --app --arch=<ARCH> --columns=application,version,branch,runtime,download-size
flatpak remote-info --arch=<ARCH> flathub <ID>
curl -s https://formulae.brew.sh/api/formula/<FORMULA>.json
curl -s https://flathub.org/api/v2/verification/<ID>/status
```

**導入の結果:**

| グループ | 結果 |
|---|---|
| Homebrew（`cli`） | 表の Homebrew の行と、比較のための `podman-tui` / `podman-compose`、合わせて 24 個を 1 つずつ `brew install` し、すべて終了コード 0。すべてボトルで、ソースビルドは 0。1 個あたり 2〜12 秒。全部入れた時点で `/home/linuxbrew/.linuxbrew` は 1.5 GB（`podman-compose` とその依存を消した後は 959 MB） |
| EPEL の CLI（`cli`） | `fastfetch` / `duf` / `mosh` / `restic` / `distrobox` / `podman-compose` / `podman-tui` がすべて終了コード 0。追加で入ったパッケージ数は fastfetch 3、duf 1、mosh 3、restic 4、distrobox 31（podman を含む）、podman-compose 5。CRB を有効にする操作はしていない（イメージの既定で有効） |
| mise（`cli`） | `dnf config-manager --add-repo` の後の `dnf install -y mise` で鍵 `0x7413A06D` が取り込まれ、`mise --version` → `2026.9.13 linux-x64 (2026-09-24)` |
| ベンダーの GUI（`gui`） | `google-chrome-stable --version` → `Google Chrome 154.0.8037.57` |
| EPEL の GUI（`gui`） | `chromium-browser --version` → `Chromium 153.0.8010.52`、`keepassxc-cli --version` → `2.7.11`、`gnome-tweaks --version` → `46.1`。`meld --version` は画面が無いため GTK の初期化で落ちた（`AttributeError: 'NoneType' object has no attribute 'props'`）。`remmina --version` は案内文だけで版を出さなかった。この 2 つは `rpm -q` で版を確認した |
| 更新（`cli` / `fp`） | [更新](../tool-catalog.md#更新)の 3 行を実行した。`brew upgrade` は無出力で終了コード 0（導入直後なので上げるものが無い）、`sudo dnf upgrade` はイメージの作成後に出た更新を当てて `Complete!`、`sudo flatpak update` は `Nothing to do.` |
| Flathub（`fp`） | 13 本（一覧に載っていないアプリを含む）を `sudo flatpak install -y --noninteractive flathub <ID>` で入れ、すべて終了コード 0、`flatpak run --command=true` もすべて成功。`--noninteractive` は進捗表示を抑えるためだけに足した。`/var/lib/flatpak` は GNOME 50 の 6 本で 3.4 GB、FDO 25.08 の 4 本を足して 5.7 GB、FDO 26.08 の 3 本を足して 8.1 GB |

#### 未確認事項

- aarch64 での導入と起動（本書の aarch64 列はすべてメタデータ）
- GUI アプリの画面の表示と操作（コンテナに画面が無い）
- Raspberry Pi 5 で Flathub のアプリ（Electron 系・ブラウザ・GPU を使うもの）が実際に動くか
- 実機（x86_64 PC）での導入。デスクトップの環境では依存の数が変わる（[vscode.md](../vscode.md) の実測では、コンテナより大幅に少なかった）
- RPM Fusion（EL10）の有効化
- atuin・direnv など、`~/.bashrc` に追記して使うツールのシェルへの組み込み
- lazydocker・dive を podman の API ソケットで使うこと
- mosh の接続（サーバー側の導入と UDP の許可）
- Flathub の Chrome / Chromium / Edge など未検証の公開元のアプリの中身

---

### 付録: コンテナ関連の追加調査（2026-09-27）

[CLI: コンテナ](../tool-catalog.md#cli-コンテナ)と GUI の[コンテナ](../tool-catalog.md#コンテナ)の節のために、同じクラウドホストの Docker で使い捨てのコンテナを 2 つ使った。

- どちらも `quay.io/almalinuxorg/10-init:10.2` で systemd を PID 1 にした
- 非 root ユーザー（NOPASSWD の sudo）に SSH でログインして、表の導入コマンドをそのまま実行した

| コンテナ | 用途 |
|---|---|
| `cat1` | CLI の行と Cockpit。先に [podman.md](../podman.md) の手順 1〜3・5〜7 と Docker 向けの節、EPEL の有効化（今の [epel.md](../epel.md) の手順 1〜3。当時は btop.md の手順 1〜3）、[homebrew.md](../homebrew.md) の手順 1〜4 を通した |
| `fp1` | GUI の Flathub の行。[flatpak.md](../flatpak.md) の手順 1〜5 を通してから入れた |

**手順書の外で行った準備**（検証環境の都合）:

- プロキシの CA を信頼ストアに足し、dnf にプロキシを設定し、AlmaLinux のミラー一覧と EPEL の metalink を https にした
- cgroup v2 に pids のコントローラが無い環境なので、`/etc/containers/containers.conf.d/` で podman の既定の PID 数の制限を外した
- `fp1` では、`sudo` がプロキシの環境変数を消して `flatpak remote-add` が証明書の検証で失敗したので、sudoers の `env_keep` にプロキシの変数を足した

**結果:**

| 行 | 結果 |
|---|---|
| podman-tui | `sudo dnf install -y podman-tui` で 1 パッケージ（9.5 MB）。`podman-tui version` → `podman-tui v1.10.0`。端末を与えて起動すると、`localhost`（`unix://run/user/<UID>/podman/podman.sock`）が `connected` になり、`STATUS_OK`・API の版 `5.8.2`・`crun version 1.27` を出した。`Ctrl+C` で終了した |
| lazydocker | `lazydocker--0.25.2.x86_64_linux.bottle.tar.gz`。`lazydocker --version` → `Version: 0.25.2`・`BuildSource: Homebrew`。`DOCKER_HOST` を podman のソケットにした状態で起動し、`Containers`・`Images`・`Volumes`・`Networks` の枠に、動かしていた `ubi10/httpd-24` のコンテナ（`127.0.0.1:8090`）と、その Apache のログを出した。`q` で終了した |
| toolbox | 4 パッケージ（`toolbox`・`flatpak-session-helper`・弱い依存の `p11-kit-server` と `skopeo`、12 MB）。`toolbox --version` → `toolbox version 0.3` |
| podman-docker | 1 パッケージ（106 kB）。`command -v docker` → `/usr/bin/docker` |
| buildah | 1 パッケージ（10 MB）。`buildah --version` → `buildah version 1.43.2 (image-spec 1.1.1, runtime-spec 1.2.1)`（RPM は `1.43.1-6.el10_2`） |
| skopeo | toolbox の弱い依存で入っていて、`Package skopeo-2:1.22.2-5.el10_2.x86_64 is already installed.`。`skopeo --version` → `skopeo version 1.22.2` |
| podlet | `podlet--0.3.2.x86_64_linux.bottle.tar.gz`。`podlet --version` → `podlet 0.3.2` |
| cosign | `cosign--3.1.3.x86_64_linux.bottle.tar.gz`。`cosign version` → `GitVersion: v3.1.3` |
| Cockpit | `sudo dnf install -y cockpit-podman` だけでは 2 パッケージ（`cockpit-podman`・`cockpit-bridge`）。続けて `sudo dnf install -y cockpit cockpit-podman` で 102 パッケージ（44 MB）。`cockpit.socket` を有効にすると `https://127.0.0.1:9090/` が応答し（`<title>Loading...`）、`/cockpit/@localhost/podman/index.html` が 200 を返した |
| Pods / BoxBuddy | `sudo flatpak install -y flathub <ID>` で入れ、`flatpak run --command=true` がどちらも成功した。`flatpak info` は Pods 3.1.1（20.2 MB）、BoxBuddy 2.6.1（1.4 MB）で、runtime はどちらも `org.gnome.Platform/x86_64/50`。`/var/lib/flatpak` は 2.5 GB |
| aarch64 | AppStream（toolbox・podman-docker・buildah・skopeo・cockpit-podman）、BaseOS（cockpit 356.2）、EPEL 10.2（podman-tui 1.10.0）、Trivy のリポジトリ（0.74.0）のどれも aarch64 にある。Homebrew の lazydocker・podlet・cosign・hadolint・dive は `arm64_linux` のボトルがある。Flathub の Pods・BoxBuddy・Podman Desktop は、`flatpak remote-info --arch=aarch64` のコミットの件名が x86_64 と一致した |
| 移した行 | podman-compose（EPEL 1.5.0 / Homebrew 1.6.0）・podman-tui（1.10.0 / 2.0.0）・distrobox（1.8.2.3 / 1.8.2.5）・lazydocker 0.25.2・dive 0.13.1 は、2026-09-24 と同じ版だった |

最初の調査の[未確認事項](#未確認事項)にあった「lazydocker・dive を podman の API ソケットで使うこと」は、この調査で片付いた。

- lazydocker は、`DOCKER_HOST` で podman の API ソケットにつないで動いた（上の表）
- dive は API ソケットを使わず、`--source podman` で podman のコマンドからイメージを読んだ（[image-tools.md](../image-tools.md)）

#### 未確認事項（2026-09-27 の調査）

- aarch64 での導入と起動（この調査の aarch64 もメタデータのみ）
- Pods・BoxBuddy・Podman Desktop・Cockpit の画面と操作
- toolbox でボックスを作ること（AlmaLinux のホストで `toolbox create` がどのイメージを選ぶか）
- cosign での署名と検証
- podman-tui・lazydocker での操作（コンテナの停止・削除など）


### 分離前の検証状況の記録

> [!WARNING]
>
> - **aarch64 の列は、リポジトリのメタデータと API から調べただけ**で、どの行も実機にもコンテナにも入れていない
> - GUI アプリはどれも画面を出していない
> - 実機（Raspberry Pi 5 と x86_64 PC）には何も入れていない


### 操作上の注意と併記されていた記録

- toolbox は、弱い依存として skopeo も入れた（ほかに `flatpak-session-helper`・`p11-kit-server`）。そのため skopeo の行の導入コマンドは `already installed` で終わった


### 操作上の注意と併記されていた記録

  - `-d` を付けると、`equal sign is needed when assigning values to '--detach=<DETACH>'` で失敗した


### 操作上の注意と併記されていた記録

- Pods と BoxBuddy の 2 本で、`/var/lib/flatpak` は 2.5 GB になった（GNOME 50 の runtime）
