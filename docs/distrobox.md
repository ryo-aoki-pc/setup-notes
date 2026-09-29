# distrobox インストール手順（AlmaLinux 10 / EPEL）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Podman](podman.md) の実施手順と、[EPEL](epel.md) を通してあること（distrobox は EPEL にあり、AppStream には無い）。`podman info --format '{{.Host.Security.Rootless}}'` が `true` を返さないか、`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（ボックスは自分のユーザーの rootless の podman で動かすため）
> - **手順 2 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）。答えてから手順 3 を貼る
> - **手順 5 と 6 はボックスの中のコマンドになる**。手順 5 は終わってから、手順 6 は `exit` で戻ってから、次を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: ボックスに入れたコマンドをホストから呼ぶなら[ボックスのコマンドをホストから呼ぶ（任意）](#ボックスのコマンドをホストから呼ぶ任意)。以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **x86_64 のコンテナでのみ検証した手順書**で、実機では本実行していない（[対象と検証環境](#対象と検証環境)）。
>
> - 検証環境の都合で、distrobox が podman に渡す `--pids-limit=-1` を読み替えて動かした（[付録](#付録-コンテナでの検証記録2026-09-27)）
> - GUI のアプリの書き出し（`distrobox-export --app`）と、デスクトップからの起動は確かめていない

1. 変数を設定する。

   ```bash
   DBX_NAME=ubuntu                                  # ボックスの名前。<DBX_NAME>
   DBX_IMAGE=quay.io/toolbx/ubuntu-toolbox:24.04    # 元にするイメージ。<DBX_IMAGE>
   printf '%-9s = %s\n' DBX_NAME "${DBX_NAME}" DBX_IMAGE "${DBX_IMAGE}"
   ```

   - **編集が必須の変数は無い**。既定のままなら、Ubuntu 24.04 のボックスができる
   - 別のディストリにするときだけ `DBX_IMAGE` を変える（候補はこの手順の補足）
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

   <details>
   <summary>補足: イメージの選び方</summary>

   既定のイメージは、Toolbx のプロジェクトが配っている Ubuntu 24.04 のイメージ（`quay.io/toolbx/ubuntu-toolbox`）にした。

   - `sudo`・`curl`・`git` など、distrobox がボックスの初期化で要るものが最初から入っていて、初期化で入れるものが少ない
   - amd64 と arm64 の両方がある（Raspberry Pi 5 でも同じイメージ）
   - Docker Hub ではなく quay.io にあるので、Docker Hub の取得回数の上限（[podman.md の注意点](podman.md#注意点)）にかからない

   distrobox の互換一覧（上流の `docs/compatibility.md`）に載っている、ほかの Toolbx 系のイメージの例:

   | ディストリ | `DBX_IMAGE` |
   |---|---|
   | Fedora 44 | `quay.io/fedora/fedora-toolbox:44` |
   | Debian 13 | `quay.io/toolbx-images/debian-toolbox:13` |
   | Arch Linux | `quay.io/toolbx/arch-toolbox:latest` |

   本書で確かめたのは Ubuntu 24.04 だけ。[ボックスのコマンドをホストから呼ぶ（任意）](#ボックスのコマンドをホストから呼ぶ任意)は apt を使うので、Ubuntu か Debian のときだけそのまま使える。

   </details>

1. 入手できる版を見てから、distrobox を入れる。

   ```bash
   dnf -q list --showduplicates distrobox
   sudo dnf install distrobox
   ```

   - 版は `distrobox.noarch  1.8.2.3-1.el10_2  epel` のように 1 つだけ出る
   - 一緒に入るのは `hicolor-icon-theme` だけ（podman は前提の手順で入っている）
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y` と答える
   - [epel.md 手順 3](epel.md#実施手順) に書いた鍵
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. distrobox が入ったか確かめる。

   ```bash
   distrobox version
   command -v distrobox
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' distrobox
   distrobox list
   ```

   - `distrobox: 1.8.2.3`、`/usr/bin/distrobox`、`distrobox 1.8.2.3-1.el10_2 epel` が出る
   - `distrobox list` は見出しの行だけを出す（ボックスはまだ無い）

   <details>
   <summary>補足: distrobox の依存</summary>

   `rpm -q --requires distrobox` の中身は `(podman or /usr/bin/docker)` と `hicolor-icon-theme` など。

   - podman を消すと distrobox も消える（`dnf remove --assumeno podman` の `Removing dependent packages:` に `distrobox` が出た。[podman.md のロールバック](podman.md#ロールバック)の手順 7 に当たる）
   - distrobox の本体はシェルスクリプトで、`/usr/bin/distrobox-create`・`distrobox-enter` などのコマンドの集まり

   </details>

1. ボックスを作る。

   ```bash
   distrobox create --yes --name "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" --image "${DBX_IMAGE:?手順 1 の DBX_IMAGE が空のまま。値を入れて貼り直す}"
   distrobox list
   ```

   - イメージを取得してから、`Distrobox 'ubuntu' successfully created.` が出る
   - `distrobox list` に、`ubuntu`・`Created`・`quay.io/toolbx/ubuntu-toolbox:24.04` の行が出る
   - `--yes` は、イメージの取得を確かめる問い合わせ（`Do you want to pull the image now? [Y/n]`）を飛ばす

   <details>
   <summary>補足: ボックスは隔離されていない</summary>

   `distrobox create --dry-run` で、podman に渡すオプションを見られる。検証で出た主なもの:

   | オプション | 意味 |
   |---|---|
   | `--privileged` | 特権付きのコンテナ（rootless なので、ホストの root にはならない） |
   | `--security-opt label=disable` | SELinux のラベルによる分離を切る |
   | `--network host` / `--pid host` / `--ipc host` | ネットワーク・プロセス・IPC をホストと共有する |
   | `--userns keep-id:size=65536` | ボックスの中でも自分と同じ UID で動く |
   | `--volume "/home/<USER>":"/home/<USER>"` | ホームディレクトリをそのまま使う |
   | `--volume /:/run/host/` | ホストのファイルシステム全体を `/run/host` に見せる |
   | `--pids-limit=-1` | プロセス数を制限しない |

   **ボックスは「別のディストリのユーザーランドを使うための道具」で、安全のための隔離ではない**（[注意点](#注意点)）。

   </details>

1. 初回の初期化を兼ねて、ボックスの中でコマンドを 1 つ動かす。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- sh -c 'grep PRETTY_NAME /etc/os-release; id -un; pwd'
   ```

   - 初回はボックスの初期化が走る（検証では 1 分ほど）。`[ OK ]` の行が並んだ後に `Container Setup Complete!` が出る
   - その後に `PRETTY_NAME="Ubuntu 24.04.5 LTS"`・自分のユーザー名・`/home/<USER>` が出る。ユーザーもホームもホストと同じ
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

   <details>
   <summary>補足: 初期化で行われること</summary>

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

   - ボックスの中に自分と同じ名前のユーザーを作り、`sudo` をパスワード無しで使えるようにする（ボックスの中の `sudo -l` は `(root) NOPASSWD: ALL`）
   - ボックスの root は、rootless の podman の読み替えでホストの自分のユーザーになるので、ホストの root の権限は無い
   - コンテナが止まっていれば、次の `distrobox enter` でも起動と初期化の確認が走る（2 回目からは速い）

   </details>

1. ボックスのシェルに入る。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}"
   ```

   - プロンプトが `📦[<USER>@ubuntu ~]$` に変わる。ここから先はボックスの中のシェル
   - SSH など画面の無いログインから入ると、`host-spawn: command not found` が 4 行出る（理由はこの手順の補足）
   - `exit` でホストに戻る
   - **後ろの節の手順は、`exit` でホストに戻ってから貼る**

   <details>
   <summary>補足: <code>host-spawn: command not found</code></summary>

   ボックスの中の `/etc/profile.d/distrobox_profile.sh` は、`DISPLAY`・`WAYLAND_DISPLAY`・`XAUTHORITY` などが空のとき、`host-spawn` でホストの値を読みに行く。

   - SSH のログインではこれらが空なので、まだ入っていない `host-spawn` を呼んで、このメッセージが出る
   - ボックスの中での作業には影響しない（検証では、この後のコマンドはどれも動いた）
   - `host-spawn` は、ボックスの中で `distrobox-host-exec`（ホストのコマンドを呼ぶ道具）を初めて使うときに、入れるかを聞かれる（`distrobox-host-exec` のスクリプトを読んだ範囲。本書では入れていない）

   </details>

---

## ボックスのコマンドをホストから呼ぶ（任意）

- 例として、AppStream と EPEL に無い `ffmpeg` を Ubuntu のボックスに入れ、ホストのシェルから `ffmpeg` で呼べるようにする
- 手順 1 の既定の Ubuntu のイメージで作ったボックスで確かめた（apt を使う）
- ボックスに入れたものはボックスの中にだけある。ホストには、ボックスを呼び出す小さなスクリプトが `~/.local/bin` に置かれる
- **この節の手順はどれも `distrobox enter` で終わる**。プロンプトが戻ってから次を貼る

1. ボックスのパッケージの一覧を新しくする。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- sudo apt-get update
   ```

   - `Reading package lists...` で終わる
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ボックスに ffmpeg を入れる。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- sudo apt-get install -y ffmpeg
   ```

   - 検証では、依存を含めて 117 パッケージ（97.5 MB）を取得し、ボックスの中で 238 MB を使った
   - ボックスの中の `sudo` はパスワードを聞かない（手順 5 の補足）
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ffmpeg をホストから呼べるように書き出す。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- distrobox-export --bin /usr/bin/ffmpeg --export-path ~/.local/bin
   ```

   - `/usr/bin/ffmpeg from ubuntu exported successfully in /home/<USER>/.local/bin.` と `OK!` が出る
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ホストのシェルから ffmpeg を呼ぶ。

   ```bash
   command -v ffmpeg
   ffmpeg -version | head -1
   ```

   - `/home/<USER>/.local/bin/ffmpeg` と `ffmpeg version 6.1.1-3ubuntu5 ...` が出ればよい
   - `~/.local/bin` は、AlmaLinux の既定の `~/.bashrc` で PATH に入っている

   <details>
   <summary>補足: 書き出されたもの</summary>

   `~/.local/bin/ffmpeg` は、ボックスの中の ffmpeg を呼び出すシェルスクリプト:

   ```
   #!/bin/sh
   # distrobox_binary
   # name: ubuntu
   if [ -z "${CONTAINER_ID}" ]; then
   	exec "/usr/bin/distrobox-enter"  -n ubuntu  --  '/usr/bin/ffmpeg'  "$@"
   elif [ -n "${CONTAINER_ID}" ] && [ "${CONTAINER_ID}" != "ubuntu" ]; then
   	exec distrobox-host-exec '/home/<USER>/.local/bin/ffmpeg' "$@"
   else
   	exec  '/usr/bin/ffmpeg' "$@"
   fi
   ```

   - 呼ぶたびに `distrobox enter` を通るので、ボックスが止まっていれば起動から始まる
   - ホームはボックスと共有しているので、ホームの中のファイルはそのままのパスで渡せる

   </details>

---

## 更新

1. distrobox を更新する。

   ```bash
   sudo dnf upgrade distrobox
   ```

   - システム全体なら `sudo dnf upgrade`
   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. ボックスの中のパッケージを更新する。

   ```bash
   distrobox upgrade "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}"
   ```

   - Ubuntu のボックスでは `apt-get update` と `apt-get upgrade` が確認なしで走る（検証では 12 パッケージが上がった）
   - **ボックスの中身は `dnf upgrade` では上がらない**。ボックスごとにこの手順を行う
   - **次の節は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

---

## ロールバック

- 上から順に実行する
- ホームはボックスと共有しているので、ボックスを消してもホームのファイルは残る。消えるのは、ボックスの中に入れたパッケージとボックスの `/etc` など

1. ホストから呼べるようにしていたときだけ、書き出したスクリプトを消す。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- distrobox-export --bin /usr/bin/ffmpeg --export-path ~/.local/bin --delete
   ```

   - `/usr/bin/ffmpeg from ubuntu removed successfully from /home/<USER>/.local/bin.` が出る
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ボックスを消す。

   ```bash
   distrobox rm "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}"
   ```

   - `Do you really want to delete containers: ubuntu? [Y/n]` に `y` と答える
   - ボックスが動いていると、続けて `Container  ubuntu running, do you want to force delete them? [Y/n]` も聞かれる。これも `y`
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. ボックスの元にしたイメージを消し、ボックスが無くなったことを確かめる。

   ```bash
   podman rmi "${DBX_IMAGE:?手順 1 の DBX_IMAGE が空のまま。値を入れて貼り直す}"
   distrobox list
   ```

   - `distrobox list` が見出しの行だけになればよい

1. distrobox を消す。

   ```bash
   sudo dnf remove distrobox
   ```

   - `[y/N]` で聞かれる
   - 依存で入った `hicolor-icon-theme` も、ほかに使うものが無ければ一緒に消える
   - **EPEL 自体は消さない**（ほかのパッケージが使っている可能性がある）。消すなら [epel.md のロールバック](epel.md#ロールバック)

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 の上で、別のディストリ（既定は Ubuntu 24.04）のユーザーランドとパッケージを使えるようにする。EL10 の AppStream・EPEL に無いものを、そのディストリのパッケージで補う
- **進め方**: EPEL（前提の [epel.md](epel.md) で有効にする）の distrobox を入れ、rootless の podman（[podman.md](podman.md)）でボックスを作る。**読者が書き換える値は冒頭の変数ブロックだけで、既定のままでもよい**
- **状態**: **x86_64 のコンテナでのみ検証済み（2026-09-27）。実機では本実行していない**
  - 下表の検証コンテナで、[podman.md](podman.md) の実施手順を通したうえで、**この文書のコードブロックをそのまま端末に流して**、手順 1、EPEL の有効化（今の [epel.md](epel.md) の手順 1〜3。当時はこの文書の手順 2〜4）、手順 2〜6、任意節、[更新](#更新)、[ロールバック](#ロールバック)を通した
  - 確認したこと:
    - EPEL の distrobox 1.8.2.3 が入り、Ubuntu 24.04 のボックスができる
    - ボックスの中のユーザーとホームがホストと同じ
    - apt で入れた ffmpeg を書き出すと、ホストのシェルから呼べる
  - **確認していないこと**: GUI のアプリの書き出し（`--app`）とデスクトップのメニュー、SELinux が有効なときの動き、Ubuntu 以外のイメージ
  - aarch64（Raspberry Pi 5）では通していない

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2`、Docker 29.3.1、`--privileged`。[podman.md](podman.md) と同じ作り） |
| podman | 未確認 | `podman-5.8.2-9.el10_2.alma.1`（[podman.md](podman.md) の実施手順で導入） |
| EPEL | 未確認 | 未設定 → [epel.md](epel.md) の手順 2 で `epel-release-10-6.el10` を導入 |
| distrobox | 未導入 | `distrobox-1.8.2.3-1.el10_2`（epel） |
| ボックス | — | `quay.io/toolbx/ubuntu-toolbox:24.04`（Ubuntu 24.04.5 LTS） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${DBX_NAME}` | ボックスの名前 | `ubuntu`（既定） |
> | `${DBX_IMAGE}` | 元にするイメージ | `quay.io/toolbx/ubuntu-toolbox:24.04`（既定） |
>
> 出力例の値は `<USER>` / `<HOSTNAME>` のプレースホルダで書いてある。バージョン（`1.8.2.3`、`24.04.5`、`6.1.1`）とパッケージの数は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（[podman.md](podman.md) の実施手順の後）の状態:

| 項目 | 状態 |
|---|---|
| podman | 5.8.2（rootless で `true`） |
| EPEL | 未設定（`EPEL は未設定`） |
| distrobox | 未導入 |
| ffmpeg | ホストに無い（`command -v ffmpeg` が何も返さない） |

### 選択した方針

| 選択肢 | 採否 |
|---|---|
| **EPEL の distrobox（1.8.2.3）** | **採用。** システムの podman と組んで使うので RPM にした（[ツール一覧の選び方](tool-catalog.md#選び方)の規則 3）。`dnf upgrade` で上がる |
| Homebrew の distrobox（1.8.2.5） | 不採用。版は新しいが、コンテナ系のツールは RPM に揃えた（Homebrew の podman がシステムの podman を隠す問題を避けるため。[ツール一覧の注意点](tool-catalog.md#注意点)） |
| 上流の curl のインストーラ | 不採用。`dnf` の管理の外に入り、更新も手作業になる |
| AppStream の toolbox（0.3） | 代わりの選択肢。RHEL の公式の道具で、[ツール一覧](tool-catalog.md#cli-コンテナ)に載せた。本書は、ボックスのディストリを選べる distrobox にした |
| ボックスのイメージに `quay.io/toolbx/ubuntu-toolbox` を使う | **採用。** `docker.io/library/ubuntu` より初期化で入れるものが少なく、Docker Hub の取得回数の上限にもかからない（手順 1 の補足） |

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

- `distrobox list` は手順 4 の直後の表示。初期化の後はコンテナが動き続ける（[ロールバック](#ロールバック)の手順 2 で `running` と聞かれる）

### 注意点

- **ボックスは隔離ではない**: ホームを共有し、ホストのファイルシステム全体が `/run/host` に見え、ネットワークとプロセスもホストと同じ（手順 4 の補足）。信用できないソフトを試す場所にはしない
- **ボックスの `sudo` はホストの root ではない**: rootless の podman の読み替えで、ボックスの root はホストの自分のユーザーになる。ホストのシステムの設定は変えられない
- **`distrobox enter` が動いている間に貼った行は、ボックスへの入力になる**: 端末の入力をボックスの中のコマンドへ渡し続けるため
  - 検証では、`distrobox enter <名前> -- <コマンド>` の後ろの行を続けて流すと、それらの行は実行されなかった
  - 本書の手順は、どれも `distrobox enter` で終わるように分けてある
- **書き出したスクリプトの名前が、ホストのコマンドと重なることがある**: `~/.local/bin` は PATH の途中にある
  - 同じ名前のコマンドがほかの場所にもあると、どちらが呼ばれるかは PATH の順で決まる
  - Homebrew の `brew shellenv` は、自分の場所を PATH の先頭に足す
- **`podman system reset` でボックスも消える**: ボックスは podman のコンテナなので、[podman.md のロールバック](podman.md#ロールバック)の手順 6 で一緒に消える
- **ボックスは、止まっていても容量を使う**: Ubuntu のイメージと、ボックスの中に入れたパッケージの分（ffmpeg で 238 MB）。`podman system df` で見る

### 参照

- [distrobox — README](https://github.com/89luca89/distrobox) — 概要、コマンドの一覧、互換のあるイメージ（`docs/compatibility.md`）
- [distrobox — Useful tips](https://github.com/89luca89/distrobox/blob/main/docs/useful_tips.md) — 書き出し、ホストのコマンドの呼び出し
- `man distrobox-create` / `man distrobox-enter` / `man distrobox-export` / `man distrobox-rm` — オプション
- [Podman](podman.md) — 前提の rootless の podman
- [EPEL](epel.md) — 前提の EPEL の有効化

---

### 付録: コンテナでの検証記録（2026-09-27）

**環境**: [podman.md の付録](podman.md#付録-コンテナでの検証記録2026-09-27)と同じ作りの使い捨てのコンテナ。実機で加えた変更は無い。

- `quay.io/almalinuxorg/10-init:10.2` で systemd を PID 1 にし（`--privileged`）、SSH でログインした
- 同じ SSH のセッションで、先に podman.md の手順 1〜3・6〜8 を流した

**手順書の外で行った準備**（podman.md の付録の準備に加えて）:

- **podman のラッパー**: distrobox は podman に `--pids-limit=-1` を渡す
  - 検証環境の cgroup v2 には pids のコントローラが無く、crun が `pids.max` に書こうとして失敗した（``controller `pids` is not available``）
  - `--pids-limit=-1` だけを `--pids-limit=0`（設定しない）に読み替える `/usr/local/bin/podman` を、手順 1 の前に置いた
  - 実機では要らない見込み（確かめていない）
- **EPEL**: EPEL の有効化（今の epel.md の手順 2）の直後に、EPEL の metalink に `&protocol=https` を足した（プロキシが平文の HTTP を通さないため）
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
- `distrobox enter <名前> -- <コマンド>` の後ろに行を続けて流すと、それらの行は実行されなかった（[注意点](#注意点)）
- `dnf remove --assumeno podman` の `Removing dependent packages:` に `distrobox` が出た

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- GUI のアプリの書き出し（`distrobox-export --app`）と、GNOME のメニューからの起動
- デスクトップの端末から `distrobox enter` したときの表示（`host-spawn` のメッセージが出るか）
- SELinux が有効な PC での動き（ボックスはラベルによる分離を切る）
- Ubuntu 以外のイメージ（Fedora・Debian・Arch）
- `host-spawn` を入れた後の `distrobox-host-exec`
- ロールバックの `podman rmi` の後に、ほかのボックスが同じイメージを使っているとき
