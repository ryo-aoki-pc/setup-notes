# distrobox インストール手順（AlmaLinux 10 / EPEL）の検証記録

[手順書](../distrobox.md)・[ロールバックと注意点](../extra/distrobox.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 の VM で実施手順を検証した。以前のコンテナ検証で必要だった `--pids-limit` の読み替えは今回不要だった。GUI の書き出しと実機での実行は未確認**（[対象と検証環境](#対象と検証環境)）。

### 実施手順 / 手順 1: 補足: イメージの選び方

既定のイメージは、Toolbx のプロジェクトが配っている Ubuntu 24.04 のイメージ（`quay.io/toolbx/ubuntu-toolbox`）にした。

- `sudo`・`curl`・`git` など、distrobox がボックスの初期化で要るものが最初から入っていて、初期化で入れるものが少ない
- amd64 と arm64 の両方がある（Raspberry Pi 5 でも同じイメージ）
- Docker Hub ではなく quay.io にあるので、Docker Hub の取得回数の上限（[podman.md の注意点](../extra/podman.md#注意点)）にかからない

distrobox の互換一覧（上流の `docs/compatibility.md`）に載っている、ほかの Toolbx 系のイメージの例:

| ディストリ | `DBX_IMAGE` |
|---|---|
| Fedora 44 | `quay.io/fedora/fedora-toolbox:44` |
| Debian 13 | `quay.io/toolbx-images/debian-toolbox:13` |
| Arch Linux | `quay.io/toolbx/arch-toolbox:latest` |

本書で確かめたのは Ubuntu 24.04 だけ。[ボックスのコマンドをホストから呼ぶ（任意）](../distrobox.md#ボックスのコマンドをホストから呼ぶ任意)は apt を使うので、Ubuntu か Debian のときだけそのまま使える。

### ボックスのコマンドをホストから呼ぶ（任意） / 手順 0: 本文中の記録

- 手順 1 の既定の Ubuntu のイメージで作ったボックスで確かめた（apt を使う）

### 対象と検証環境

- **目的**: AlmaLinux 10 の上で、別のディストリ（既定は Ubuntu 24.04）のユーザーランドとパッケージを使えるようにする。EL10 の AppStream・EPEL に無いものを、そのディストリのパッケージで補う
- **進め方**: EPEL（前提の [AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」](../almalinux-setup.md#epel-と-rpm-fusion)の手順 1 で有効にする）の distrobox を入れ、rootless の podman（[podman.md](../podman.md)）でボックスを作る。**読者が書き換える値は冒頭の変数ブロックだけで、既定のままでもよい**
- **状態**: **x86_64 の VM で実施手順 1〜6を検証済み（2026-10-06、SELinux Enforcing）。実機では本実行していない**
  - これは 2026-10-06 の時点の状態
  - VM の実測は[今回の付録](#付録-vm-での検証記録2026-10-06)。以下のコンテナでの結果と未確認事項は、当時の検証範囲の記録。
  - 下表の検証コンテナで、[podman.md](../podman.md) の実施手順を通したうえで、**この文書のコードブロックをそのまま端末に流して**、手順 1、EPEL の有効化（今の [AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」](../almalinux-setup.md#epel-と-rpm-fusion)の手順 1。当時はこの文書の手順 2〜4）、手順 2〜6、任意節、[更新](../distrobox.md#更新)、[ロールバック](../extra/distrobox.md#ロールバック)を通した
  - 確認したこと:
    - EPEL の distrobox 1.8.2.3 が入り、Ubuntu 24.04 のボックスができる
    - ボックスの中のユーザーとホームがホストと同じ
    - apt で入れた ffmpeg を書き出すと、ホストのシェルから呼べる
  - **確認していないこと**: GUI のアプリの書き出し（`--app`）とデスクトップのメニュー、SELinux が有効なときの動き、Ubuntu 以外のイメージ
  - aarch64（Raspberry Pi 5）では通していない
- 2026-10-11: Hyper-V の VM で Codex が再検証した（末尾の付録）。
  - 実施・確認: 実施手順・ffmpeg の書き出し・更新を確認。任意節の手順 4 は既存 Homebrew 版が選ばれ、通らなかった。
  - 未確認: GUI アプリの書き出し、他ディストリ、更新がある場合、ロールバック、実機・aarch64・Secure Boot 有効環境は今回未実施。

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2`、Docker 29.3.1、`--privileged`。[podman.md](../podman.md) と同じ作り） |
| podman | 未確認 | `podman-5.8.2-9.el10_2.alma.1`（[podman.md](../podman.md) の実施手順で導入） |
| EPEL | 未確認 | 未設定 → [epel.md](../almalinux-setup.md) の手順 2 で `epel-release-10-6.el10` を導入 |
| distrobox | 未導入 | `distrobox-1.8.2.3-1.el10_2`（epel） |
| ボックス | — | `quay.io/toolbx/ubuntu-toolbox:24.04`（Ubuntu 24.04.5 LTS） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../distrobox.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${DBX_NAME}` | ボックスの名前 | `ubuntu`（既定） |
> | `${DBX_IMAGE}` | 元にするイメージ | `quay.io/toolbx/ubuntu-toolbox:24.04`（既定） |
>
> 出力例の値は `<USER>` / `<HOSTNAME>` のプレースホルダで書いてある。バージョン（`1.8.2.3`、`24.04.5`、`6.1.1`）とパッケージの数は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（[podman.md](../podman.md) の実施手順の後）の状態:

| 項目 | 状態 |
|---|---|
| podman | 5.8.2（rootless で `true`） |
| EPEL | 未設定（`EPEL は未設定`） |
| distrobox | 未導入 |
| ffmpeg | ホストに無い（`command -v ffmpeg` が何も返さない） |

### 完了時点の状態

**検証コンテナでの出力**（手順 3〜5 と任意節）:

```
$ distrobox version
distrobox: 1.8.2.3
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' distrobox
distrobox 1.8.2.3-1.el10_2 epel
$ distrobox list
ID           | NAME                 | STATUS             | IMAGE
8289f44b8410 | ubuntu               | Created            | quay.io/toolbx/ubuntu-toolbox:24.04
$ distrobox enter ubuntu -- sh -c 'grep PRETTY_NAME /etc/os-release; id -un; pwd'
...
Container Setup Complete!
PRETTY_NAME="Ubuntu 24.04.5 LTS"
<USER>
/home/<USER>
$ command -v ffmpeg
/home/<USER>/.local/bin/ffmpeg
$ ffmpeg -version | head -1
ffmpeg version 6.1.1-3ubuntu5 Copyright (c) 2000-2023 the FFmpeg developers
```

- `distrobox list` は手順 4 の直後の表示。初期化の後はコンテナが動き続ける（[ロールバック](../extra/distrobox.md#ロールバック)の手順 2 で `running` と聞かれる）

### 付録: コンテナでの検証記録（2026-09-27）

**環境**: [podman.md の付録](podman.md#付録-コンテナでの検証記録2026-09-27)と同じ作りの使い捨てのコンテナ。実機で加えた変更は無い。

- `quay.io/almalinuxorg/10-init:10.2` で systemd を PID 1 にし（`--privileged`）、SSH でログインした
- 同じ SSH のセッションで、先に podman.md の手順 1〜3・5〜7 を流した

**手順書の外で行った準備**（podman.md の付録の準備に加えて）:

- **podman のラッパー**: distrobox は podman に `--pids-limit=-1` を渡す
  - 検証環境の cgroup v2 には pids のコントローラが無く、crun が `pids.max` に書こうとして失敗した（``controller `pids` is not available``）
  - `--pids-limit=-1` だけを `--pids-limit=0`（設定しない）に読み替える `/usr/local/bin/podman` を、手順 1 の前に置いた
  - 実機では要らない見込み（確かめていない）
- **EPEL**: EPEL の有効化（今の AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」の手順 1）の直後に、EPEL の metalink に `&protocol=https` を足した（プロキシが平文の HTTP を通さないため）
- ボックスの中の apt は、`http://archive.ubuntu.com` にそのままつながった

**流し方**: [podman.md の付録](podman.md#付録-コンテナでの検証記録2026-09-27)と同じく、ブロックを 1 行ずつ端末に流し、`[y/N]`・`[Y/n]` には `y` と答えた。手順 6 はボックスのシェルに入ったところで `grep PRETTY_NAME /etc/os-release` と `exit` を打った。

| 手順 | 結果 |
|---|---|
| 1. 変数 | `DBX_NAME  = ubuntu`、`DBX_IMAGE = quay.io/toolbx/ubuntu-toolbox:24.04` |
| epel.md 1〜3. EPEL | `EPEL は未設定` → `epel-release-10-6.el10` と依存の 7 つ（`dnf-plugins-core` など） → `epel` の行 |
| 2. 導入 | `distrobox.noarch  1.8.2.3-1.el10_2  epel`。`[y/N]` と EPEL の鍵（`0xE37ED158`、fingerprint は本文のとおり）に `y`。`distrobox` と `hicolor-icon-theme` の 2 つ（300 k） |
| 3. 確かめる | `distrobox: 1.8.2.3`、`/usr/bin/distrobox`、`distrobox 1.8.2.3-1.el10_2 epel`、`distrobox list` は見出しだけ |
| 4. 作成 | `quay.io/toolbx/ubuntu-toolbox:24.04` を取得して `Distrobox 'ubuntu' successfully created.`。`distrobox list` は `Created` |
| 5. 初期化 | `[ OK ]` が 12 行並んで `Container Setup Complete!`、続けて `PRETTY_NAME="Ubuntu 24.04.5 LTS"`・`<USER>`・`/home/<USER>`。別の試行で時間を計ると 1 分 17 秒だった |
| 6. シェル | `host-spawn: command not found` が 4 行、プロンプトは `📦[<USER>@ubuntu ~]$`。`exit` で戻った |
| 任意 1〜2 | `apt-get update` の後、ffmpeg と依存の 117 パッケージ（97.5 MB、ボックスの中で 238 MB） |
| 任意 3〜4 | `/usr/bin/ffmpeg from ubuntu exported successfully in /home/<USER>/.local/bin.`、`command -v ffmpeg` → `/home/<USER>/.local/bin/ffmpeg`、`ffmpeg version 6.1.1-3ubuntu5` |
| 更新 | `sudo dnf upgrade distrobox` は `Nothing to do.`。`distrobox upgrade ubuntu` は確認なしで 12 パッケージを上げた |
| ロールバック | 書き出しを消した後、`distrobox rm` は 2 回の確認（削除と、動いているコンテナの強制削除）に `y`。`podman rmi` の後の `distrobox list` は見出しだけ。`dnf remove` で `distrobox` と `hicolor-icon-theme` が消えた |

**別に確かめたこと**（同じ作りの別のコンテナで、手順書の外のコマンドとして実行）:

- `--yes` を付けない `distrobox create` は `Image quay.io/toolbx/arch-toolbox:latest not found.` と `Do you want to pull the image now? [Y/n]:` を出した（`n` で中断）
- `distrobox create --dry-run` で、podman に渡すオプション（手順 4 の補足の表）を見た
- `distrobox enter <名前> -- <コマンド>` の後ろに行を続けて流すと、それらの行は実行されなかった（[注意点](../extra/distrobox.md#注意点)）
- `dnf remove --assumeno podman` の `Removing dependent packages:` に `distrobox` が出た

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- GUI のアプリの書き出し（`distrobox-export --app`）と、GNOME のメニューからの起動
- デスクトップの端末から `distrobox enter` したときの表示（`host-spawn` のメッセージが出るか）
- SELinux が有効な PC での動き（ボックスはラベルによる分離を切る）
- Ubuntu 以外のイメージ（Fedora・Debian・Arch）
- `host-spawn` を入れた後の `distrobox-host-exec`
- ロールバックの `podman rmi` の後に、ほかのボックスが同じイメージを使っているとき

---

### 付録: VM での検証記録（2026-10-06）

**環境**: [クリーンインストールからの検証記録](../almalinux-vm-verification.md)のコンテナ用 VM。公式 ISO から Workstation を入れた状態から始め、x86_64、SELinux Enforcing、firewalld 有効。本文のブロックを SSH の擬似端末で実行した。

- podman.md と epel.md を通した VM で、手順 1〜6 を本文のまま実行した。EPEL の distrobox 1.8.2.3 と `quay.io/toolbx/ubuntu-toolbox:24.04` を使い、Ubuntu 24.04.5 LTS のボックスができた。
- SELinux は Enforcing、cgroup v2 に pids のコントローラがある。以前のコンテナ検証の podman ラッパーは置かず、`--pids-limit=-1` のまま初期化を完了した。1 vCPU の VM では初期化に約 8 分かかった。
- 手順 6 で対話のシェルに入り、OS・ユーザー・作業ディレクトリを確認して `exit` で戻った。ホームはホストと共有された。
- Homebrew を設定済みのホストの `.bashrc` も共有されるため、入った直後に `bash: /home/linuxbrew/.linuxbrew/bin/brew: No such file or directory` が出た。ボックスにはその prefix が無いことが原因で、シェルへの入退場とコマンドの実行はできた。ホストの設定をボックスでも無条件に読む場合の注意として残す。
- ffmpeg の書き出しの任意節、GUI のアプリの書き出し、Ubuntu 以外、更新・ロールバック、実機・aarch64 は今回通していない。

---

### 付録: 現行版を新規 VM で再検証（2026-10-06）

**対象**: `setup-notes` の `5da3478` 版。公式 ISO で Workstation を入れた `clean-install` スナップショットから、新規の `alma10-current-20261006-containers` を作った。AlmaLinux 10.2 / x86_64 / SELinux Enforcing / firewalld 有効。共通 bash は `3d5323e` を新規導入した。以前の付録と別の試験で、現行ブロックを SSH の擬似端末で順に実行した。

実施手順 1〜6 を通した。EPEL の distrobox 1.8.2.3、Ubuntu 24.04.5 LTS。cgroup v2 と SELinux Enforcing の VM で、以前のコンテナ検証のラッパーを使わず初期化できた。対話シェルの OS・ユーザー・共有ホームを確認し、`exit` でホストに戻った。今回の共通 bash は Homebrew の実行ファイルの有無を確認するため、ボックス内で prefix が無くても以前の付録の `brew: No such file or directory` は出なかった。ffmpeg / GUI の書き出しと、更新はこの再検証では行っていない。

ロールバックの手順 2〜4 も通した。`ubuntu` の削除確認に答え、Ubuntu イメージを消すと一覧は見出しだけになり、RPM も削除できた。今回は ffmpeg を書き出していないため手順 1 は飛ばした。

### 手順中の実測・検証状況の記録

- 初回はボックスの初期化が走る（検証では 1 分ほど）。`[ OK ]` の行が並んだ後に `Container Setup Complete!` が出る

### 手順中の実測・検証状況の記録

- 検証では、依存を含めて 117 パッケージ（97.5 MB）を取得し、ボックスの中で 238 MB を使った

### 手順中の実測・検証状況の記録

- Ubuntu のボックスでは `apt-get update` と `apt-get upgrade` が確認なしで走る（検証では 12 パッケージが上がった）

### 手順中の実測・検証状況の記録

- 検証では、`distrobox enter <名前> -- <コマンド>` の後ろの行を続けて流すと、それらの行は実行されなかった

### 手順中の実測・検証状況の記録

- 初回はボックスの初期化が走る。`[ OK ]` の行が並んだ後に `Container Setup Complete!` が出る

### 実施手順 / 手順 4: 補足: ボックスは隔離されていない

`distrobox create --dry-run` で、podman に渡すオプションを見られる。検証で出た主なもの:

### 実施手順 / 手順 5: 補足: 初期化で行われること

初回の `distrobox enter` はコンテナを起動し、ボックスの中で distrobox の初期化（`distrobox-init`）を走らせる。検証での表示:

```
Starting container...                    [ OK ]
Installing basic packages...             [ OK ]
Setting up devpts mounts...              [ OK ]
Setting up read-only mounts...           [ OK ]
Setting up read-write mounts...          [ OK ]
Setting up host's sockets integration... [ OK ]
Integrating host's themes, icons, fonts... [ OK ]
Setting up distrobox profile...          [ OK ]
Setting up sudo...                       [ OK ]
Setting up user's group list...          [ OK ]
Setting up existing user...              [ OK ]
Ensuring user's access...                [ OK ]

Container Setup Complete!
```

### 実施手順 / 手順 6: 補足: host-spawn: command not found

- SSH のログインではこれらが空なので、まだ入っていない `host-spawn` を呼んで、このメッセージが出る
- ボックスの中での作業には影響しない（検証では、この後のコマンドはどれも動いた）
- `host-spawn` は、ボックスの中で `distrobox-host-exec`（ホストのコマンドを呼ぶ道具）を初めて使うときに、入れるかを聞かれる（`distrobox-host-exec` のスクリプトを読んだ範囲。本書では入れていない）

### 手順内の実測・検証状況

- **ボックスは、止まっていても容量を使う**: Ubuntu のイメージと、ボックスの中に入れたパッケージの分（ffmpeg で 238 MB）。`podman system df` で見る

### 実施手順 / 手順 3: 補足: distrobox の依存

- podman を消すと distrobox も消える（`dnf remove --assumeno podman` の `Removing dependent packages:` に `distrobox` が出た。[podman.md のロールバック](../extra/podman.md#ロールバック)の手順 6 に当たる）

## 付録: Hyper-V の VM で通した記録（2026-10-11）

- 実施したのは Codex。対象は手順書のコミット `d69f1130f94d831b60bc9bd38a568d2cfb71659e`。下表は直す前の手順を通した結果。
- 証跡は `D:\vmverify\codex\units\C13\` の下にあり、このリポジトリには入っていない。
- 表の seq は `session/steps.jsonl` の連番。
- 確認出力は `session/after-confirm/`、TUI・対話・確認見出しの無い手順は `session/session-001.raw` の rawFrom / rawTo に対応する箇所で照合した。
- VM の値は `<USER>`・`<HOSTNAME>`・`<SERVER_IP>`・`<UID>` で書く。

### 環境

| 項目 | 値 |
|---|---|
| ホスト | Windows 11 Pro、build 26300、Hyper-V |
| VM | Generation 2、構成版 12.0、2 vCPU、3072 MB、64 GiB、Default Switch・eth0 1 枚、Secure Boot 無効 |
| ゲスト | AlmaLinux 10.2 (Lavender Lion)、x86_64、kernel 6.12.0-211.64.1.el10_2.x86_64 |
| 開始状態 | after-CL1 の新規クローン（初期設定・linger・Podman・Docker API・Quadlet の後）、SELinux Enforcing・rootless=true |
| 共通 bash | 67abb84ed5601b242870841ff1da381388f5427a（一般ユーザーと今回導入した root） |
| 対象版 | distrobox 1.8.2.3-1.el10_2、Ubuntu 24.04.5 LTS、ffmpeg 6.1.1-3ubuntu5（既存 Homebrew 版 9.0.2） |
| 貼り方 | GNOME コンソールにログインした状態で、SSH の対話の bash にドライバでブロックを順に貼った。TUI は SSH の端末の文字とキー操作で確認した |

### 手順ごとの結果

| 節 | 項 | 手順 | 判定 | 根拠 | メモ |
|---|---|---:|---|---|---|
| 実施手順 | — | 1 | 通した | `session/steps.jsonl` seq 1 | DBX_NAME=ubuntu、公開の Ubuntu 24.04 イメージ。既定値のまま |
| 実施手順 | — | 2 | 通した | `session/steps.jsonl` seq 2 | 1.8.2.3 を導入。`session/steps.jsonl` seq 3 で y。追加依存なし（hicolor-icon-theme は導入済み） |
| 実施手順 | — | 3 | 通した | `session/steps.jsonl` seq 4 | 版・/usr/bin/distrobox・epel が一致。list は見出しだけ |
| 実施手順 | — | 4 | 通した | `session/steps.jsonl` seq 5 | `session/steps.jsonl` seq 7 まで待機。successfully created、ubuntu / Created / 指定イメージ |
| 実施手順 | — | 5 | 通した | `session/steps.jsonl` seq 8 | `session/steps.jsonl` seq 10 まで待機。Container Setup Complete!、Ubuntu 24.04.5 LTS、<USER>、/home/<USER> |
| 実施手順 | — | 6 | 通した | `session/steps.jsonl` seq 11 | ボックスのプロンプトへ移り、`session/steps.jsonl` seq 12 の exit でホストへ戻った。host-spawn エラーなし |
| ボックスのコマンドをホストから呼ぶ（任意） | — | 1 | 通した | `session/steps.jsonl` seq 13 | apt-get update 完了。LANG が日本語なので英語の Reading package lists 相当は日本語で出た |
| ボックスのコマンドをホストから呼ぶ（任意） | — | 2 | 通した | `session/steps.jsonl` seq 14 | ffmpeg 7:6.1.1-3ubuntu5 と依存の導入完了 |
| ボックスのコマンドをホストから呼ぶ（任意） | — | 3 | 通した | `session/steps.jsonl` seq 15 | exported successfully と OK! |
| ボックスのコマンドをホストから呼ぶ（任意） | — | 4 | 通らなかった | `session/steps.jsonl` seq 16 | Homebrew の /home/linuxbrew/.linuxbrew/bin/ffmpeg 9.0.2 が選ばれた。書き出した実体は直接呼ぶと 6.1.1-3ubuntu5（prereq-diagnostics.txt） |
| 更新 | — | 1 | 通した | `session/steps.jsonl` seq 17 | 更新なしで正常終了 |
| 更新 | — | 2 | 通した | `session/steps.jsonl` seq 18 | Ubuntu の更新 0、新規 0、削除 0、保留 0 |
| extra / ロールバック | — | 全手順 | 未実施 | 今回の対象外 | 過去のロールバック記録は保持 |

Ubuntu の初期化、対話シェルへの移動と exit、ffmpeg の導入と書き出しは成功した。Ubuntu の更新は 0 件。

### 通らなかった手順と見立て

- 任意節の手順 4 は通らなかった。
- `command -v ffmpeg` は `/home/linuxbrew/.linuxbrew/bin/ffmpeg`、版は 9.0.2。
- `prereq-diagnostics.txt` の type -a と書き出し先の直接呼び出しでは Ubuntu 版 6.1.1-3ubuntu5 を確認した。
- 既存プログラムと PATH の優先順による差で、SSH や Hyper-V 固有とする証拠は無い。
- 過去のコンテナで通常の ffmpeg 呼び出しが通った記録も保持する。

### 指摘と状態

| 重大度 | 場所 | 指摘 | 状態 |
|---|---|---|---|
| 低 | docs/distrobox.md / 実施手順 / 手順 2 | 文言の直し | 直した |
| 低 | docs/reference/distrobox.md / 補足 / 実施手順 / 手順 2 | 文言の直し | 直した |
| 低 | docs/distrobox.md / 実施手順 / 手順 6 | 文言の直し | 直した |
| 低 | docs/distrobox.md / ボックスのコマンドをホストから呼ぶ（任意）/ 手順 1 | 文言の直し | 直した |
| 中 | docs/distrobox.md / ボックスのコマンドをホストから呼ぶ（任意）/ 手順 4 | ブロックの直し | 直した。ブロック全体の貼り直しは未実施 |
| 低 | docs/distrobox.md / ボックスのコマンドをホストから呼ぶ（任意）/ 手順 4 | 文言の直し | 直した |

### 手順書を直した所

- docs/distrobox.md / 実施手順 / 手順 2: 文言。根拠: C13/session/after-confirm/0002-実施手順-2.txt、prereq-diagnostics.txt。対応する出力を VM の証跡で確認。文言の直しで、ブロックは変更していない。
- docs/reference/distrobox.md / 補足 / 実施手順 / 手順 2: 文言。
- 根拠: C13/session/after-confirm/0002-実施手順-2.txt、prereq-diagnostics.txt。
- 対応する出力を VM の証跡で確認。
- 文言の直しで、ブロックは変更していない。
- docs/distrobox.md / 実施手順 / 手順 6: 文言。根拠: C13/session/session-001.raw seq 11・12。対応する出力を VM の証跡で確認。文言の直しで、ブロックは変更していない。
- docs/distrobox.md / ボックスのコマンドをホストから呼ぶ（任意）/ 手順 1: 文言。根拠: C13/session/session-001.raw seq 13。対応する出力を VM の証跡で確認。文言の直しで、ブロックは変更していない。
- docs/distrobox.md / ボックスのコマンドをホストから呼ぶ（任意）/ 手順 4: ブロック。
- 根拠: C13/session/after-confirm/0016-ボックスのコマンドをホストから呼ぶ（任意）-4.txt、prereq-diagnostics.txt。
- 直した後のブロックは、VM で貼り直していない。
- docs/distrobox.md / ボックスのコマンドをホストから呼ぶ（任意）/ 手順 4: 文言。
- 根拠: C13/prereq-diagnostics.txt、session/after-confirm/0016-ボックスのコマンドをホストから呼ぶ（任意）-4.txt。
- 対応する出力を VM の証跡で確認。
- 文言の直しで、ブロックは変更していない。

### 確かめていないこと

- GUI アプリの書き出し、他ディストリ、更新がある場合、ロールバック、実機・aarch64・Secure Boot 有効環境は今回未実施。
- 今回の Hyper-V の結果を、別のハイパーバイザや実機の成功範囲に広げない。過去の付録はその当時の検証範囲として残す。
