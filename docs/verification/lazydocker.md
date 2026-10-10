# lazydocker インストール手順（AlmaLinux 10 / Homebrew）の検証記録

[手順書](../lazydocker.md)・[ロールバックと注意点](../extra/lazydocker.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **基本操作・podman exec の任意節・既存設定を使った root の表示と停止は、aarch64 の実機（SELinux Enforcing）でも検証済み（2026-10-06）**。x86_64 のクリーン VM では `0dbb522` 版の新規導入と停止操作を検証した（[VM の記録](#付録-vm-での検証記録2026-10-06)）。共通 bash 設定への統一後の前提・変更ブロックは、この VM で本実行していない。更新・全ロールバック・compose の任意節の実行記録は、x86_64 のコンテナのみ。画面は、表示された文字を読み取り、キーを送って確かめた（[対象と検証環境](#対象と検証環境)、[実機での検証記録](#付録-aarch64-の実機での検証記録2026-10-06)）。

### 実施手順 / 手順 2: 補足: DOCKER_HOST が無いとき

lazydocker は `DOCKER_HOST` を読み、無ければ Docker の既定のソケット（`/var/run/docker.sock`）につなごうとする。`DOCKER_HOST` を外して起動したときの、画面の `Error` の枠（実測）:

```
Docker event stream returned error: Cannot connect to the Docker daemon at
unix:///var/run/docker.sock. Is the docker daemon running?
Retry count: 26
```

- 起動はするが、枠は空のまま。`Retry count` は増え続け、`Esc` でも消えない。`q` で終わる
- API ソケットが止まっているときも、同じ文言で `unix:///run/user/<UID>/podman/podman.sock` と出る。`systemctl --user start podman.socket` で直る

### root でも使う（任意）: 検証状況の記録

> [!WARNING]
> - root の lazydocker は、Homebrew を入れたユーザーが書き換えられるプログラムを、root の権限で動かす（[AlmaLinux 10 の初期設定の Homebrew を root のシェルでも使う](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節の導入条件と同じ）
> - システムの API ソケットにつなげるのは root だけ。権限を緩めない（つなげると、root と同じことができる）
> - この節の検証の範囲は[コンテナの付録](#付録-root-でも使う節のコンテナでの検証記録2026-10-05)と[実機の付録](#付録-aarch64-の実機での検証記録2026-10-06)



- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

### 対象と検証環境

- **目的**: コンテナ・イメージ・ボリューム・ネットワークと、compose のサービスを、端末の画面（TUI）で見て操作できるようにする。podman の API ソケットに、Docker の API としてつなぐ
  - 任意節で、root のコンテナ（`sudo podman` で動かしたもの）も、`sudo -i lazydocker` で見られるようにする
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **aarch64 の実機で基本操作・podman exec・既存設定を使った root の表示と停止を検証済み（2026-10-06）。x86_64 の新規 VM では、現行 `5da3478` 版と共通 bash `3d5323e` で実施手順 1〜5 とロールバックを再検証した（同日）**。実機は導入済みの環境で、一時設定と確認用コンテナを使った。[実機の範囲と後片付け](#付録-aarch64-の実機での検証記録2026-10-06)、[現行版の VM 記録](#付録-現行版を新規-vm-で再検証2026-10-06)を参照。更新・compose の任意節は、この新規 VM では再実行していない。以前の `0dbb522` 版の VM 記録とコンテナ記録も付録に残した
  - 下表の検証コンテナで、[podman.md](../podman.md) の実施手順と Docker 向けの節、[Homebrew の導入](../almalinux-setup.md)を通したうえで、**この文書のコードブロックをそのまま端末に貼って**、手順 1〜5、2 つの任意節、[更新](../lazydocker.md#更新)、[ロールバック](../extra/lazydocker.md#ロールバック)を通した
  - compose の任意節の前には、EPEL の有効化（今の [AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」](../almalinux-setup.md#epel-と-rpm-fusion)の手順 1。当時は podman-compose.md の手順 1〜3）と、[podman-compose.md](../podman-compose.md) の手順 1〜6 を通した
  - 検証コンテナで確認したこと:
    - lazydocker 0.25.2 が `DOCKER_HOST` で podman 5.8.2 の API ソケットにつながり、コンテナ・イメージ・ボリューム・ネットワークとログを出す
    - 画面の `s` でコンテナが止まり、`podman ps` にも `Exited (0)` で出る
    - `c` に足した `podman exec` でシェルが開き、`dockerCompose: podman-compose` で Project と Services の枠が出て、`r` で `web` が再起動する
    - [使い方の基本](../lazydocker.md#使い方の基本)の表のキーと、`E`・`a` が何も起こさないこと
  - **確認していないこと**: 色や罫線の見た目、デスクトップの端末での表示、`w`（ブラウザで開く）・`b`（まとめての操作）・`p`（一時停止）・`/`（絞り込み）
  - aarch64 の実機では、手順書全体をコードブロックのまま順に貼る検証はしていない
  - [root でも使う](../lazydocker.md#root-でも使う任意)の節は、**目印付きの追記・撤去への修正前の手順 1〜8 を、x86_64 のコンテナで検証した**（2026-10-05。[付録](#付録-root-でも使う節のコンテナでの検証記録2026-10-05)）。当時の目印付き追記・撤去ブロックは一時ファイルとスタブでの検証のみ。現行手順は共通設定の確認を行い、直接追記・撤去はしない。aarch64 の実機では、既存のソケット・bash の設定を使った表示と停止だけを追加で検証した（2026-10-06）
    - 検証コンテナで通したこと: その節の手順 1〜8 を、この文書のコードブロックのまま、`sudo` のユーザーの端末に、ブラケットペーストの無しと有りで 1 回ずつ貼った。手順 1・2 は重ねても貼った
    - 検証コンテナで確認したこと:
      - root の画面に root のコンテナだけが出て、`s` で止まる。`su -`・`sudo -s` の root のシェルでも同じ
      - `sudo lazydocker` はつながらず、`sudo -E lazydocker` は自分のコンテナを出す
      - homebrew.md のどちらの節だけでも動く。その節の手順 6〜8 で、`/root/.bashrc` が元と同じ内容に戻る
    - 確認していないこと: root の Quadlet のコンテナ。実機でのソケットの新規有効化、bash 設定の追加・撤去、再起動後の動作
    - 2026-10-05: 自分用の bash の設定を root のシェルにも入れたホストの箇条書き（その節の手順 2・6）は、その設定の検証の中で、代わりのコマンドと、その節の手順 6〜8 を x86_64 のコンテナで流して確かめた（[ryo-aoki-pc/bash の docs/install.md の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-root-のシェルでも読む節の検証記録2026-10-05)）
    - 同日、手順 2・6 を、今回追加した行に目印を付け、その行だけ消す形に直した。未設定・既存の同値・既存の別値の 3 通りと繰り返し適用を、一時ファイルと `sudo`・`podman` のスタブで確認した（いずれも撤去後のファイルは元と同じ）。既存の別値は上書きせずに手順を止める。この変更後のブロックは実際の root の環境では未実行

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-10-06（aarch64 の導入済み環境） | 2026-09-28 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2` を、x86_64 の実機の rootless の podman 5.8.2 で `--privileged` にして起動。systemd が PID 1） |
| podman | aarch64 は 5.8.2（`podman-5.8.2-9.el10_2.alma.1.aarch64`、rootless と root を確認） | `podman-5.8.2-9.el10_2.alma.1`（[podman.md](../podman.md) の実施手順で導入。入れ子の rootless） |
| Homebrew | aarch64 は 7.0.8 | 7.0.6（[homebrew.md](../almalinux-setup.md) の手順 1〜4 で導入） |
| lazydocker | aarch64 は導入済みの 0.25.2（Homebrew、arm64、ボトルから導入した記録あり） | 0.25.2（`x86_64_linux` のボトル） |
| podman-compose | aarch64 は未導入 | `podman-compose-1.5.0-1.el10_1`（epel。compose の任意節だけで使った） |
| `docker` コマンド | aarch64 は無し（`podman-docker` も無し） | 無し（`podman-docker` は入れていない） |
| 端末 | aarch64 は 160 桁 × 50 行の擬似端末（`TERM=xterm-256color`、`LANG=C.UTF-8`、pexpect と pyte で文字を読み取った） | 160 桁 × 50 行の擬似端末（`TERM=xterm-256color`、`LANG=C.UTF-8`）の SSH のログインシェル |

- 実機の列の aarch64 は導入済み環境での動作検証の値。x86_64 PC での本実行は未確認

> [!NOTE]
> 出力例の値は `<USER>` / `<UID>` / `<HOSTNAME>` のプレースホルダで書いてある。バージョン（`0.25.2`・`5.8.2`）とイメージの大きさは実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（[podman.md](../podman.md) の実施手順と Docker 向けの節、Homebrew の導入の後）の状態:

| 項目 | 状態 |
|---|---|
| podman | 5.8.2（rootless で `true`）。API ソケットは `active` |
| `DOCKER_HOST` | `unix:///run/user/<UID>/podman/podman.sock`（`~/.bashrc`） |
| Homebrew | 7.0.6（`brew leaves` は空） |
| `docker` コマンド | 無し |
| lazydocker | 未導入。`~/.config/lazydocker` も無い |

### 選択した方針

| 選択肢 | 採否 |
|---|---|
| **Homebrew の lazydocker（0.25.2）** | **採用。** AppStream にも EPEL にも RPM が無い。`arm64_linux` のボトルもある |
| GitHub のリリースの実行ファイル / `go install` | 不採用。更新が手作業になる |
| `podman-docker`（AppStream）で `docker` を podman に読み替える | 不採用。入れると、既定の設定のまま `E`・`a`・compose の判定が動いた（検証で確認）。ただし `/usr/bin/docker` がシステム全体に入り、呼ぶたびに `Emulate Docker CLI using podman. ...` が出る。本書は自分の設定ファイルだけで補った |
| Docker Engine（docker-ce） | 対象外（[podman.md](podman.md#選択した方針) と同じ） |
| [podman-tui](../podman-tui.md) | 別の手順書。podman の API でつなぎ、pod とシークレットも扱える。`DOCKER_HOST` は要らない |
| **root のコンテナは `sudo -i lazydocker` で見る**（`/root/.bashrc` の `DOCKER_HOST` で、システムの API ソケットにつなぐ） | **採用**（[root でも使う](../lazydocker.md#root-でも使う任意)の節）。自分の `~/.bashrc` と同じ形で、効くのは root のシェルだけ |
| `/run/docker.sock` を root のソケットへのリンクにして、`sudo lazydocker` で起動する | 不採用。root で動く Docker の API を使うツールが、どれも root の podman につながる（podman-docker の tmpfiles.d と同じ仕組み） |
| 毎回 `sudo DOCKER_HOST=unix:///run/podman/podman.sock lazydocker` と打つ | 不採用。設定は残らないが長い（動くことは確かめた） |
| システムの `podman.socket` の `SocketGroup` を変え、自分の lazydocker から直接つなぐ | 不採用。`sudo` を経ずに、root と同じことができるようになる |

### 完了時点の状態

**検証コンテナでの出力**（手順 2・5）:

```
$ lazydocker --version
Version: 0.25.2
Date: 2026-04-19T02:50:06Z
BuildSource: Homebrew
Commit:
OS: linux
Arch: amd64
$ command -v lazydocker
/home/linuxbrew/.linuxbrew/bin/lazydocker
$ echo "${DOCKER_HOST}"
unix:///run/user/<UID>/podman/podman.sock
$ curl -s --unix-socket "${DOCKER_HOST#unix://}" http://d/_ping; echo
OK
$ podman ps -a --filter name=lazydocker-web --format '{{.Names}} {{.Status}}'
lazydocker-web Exited (0) 13 seconds ago
$ ls -l ~/.config/lazydocker
total 0
-rw-r--r--. 1 <USER> <USER> 0 Sep 28 00:34 config.yml
```

2 つの任意節を通した後の `~/.config/lazydocker/config.yml`:

```
customCommands:
  containers:
    - name: podman exec sh
      attach: true
      command: 'podman exec -it {{ .Container.ID }} sh'
commandTemplates:
  dockerCompose: podman-compose
```

### root で使うときの補足

[root でも使う](../lazydocker.md#root-でも使う任意)の節の補足。実測は x86_64 のコンテナで、その節の手順 5 の後のもの（[付録](#付録-root-でも使う節のコンテナでの検証記録2026-10-05)）。

### 付録: コンテナでの検証記録（2026-09-28）

**環境**: [podman-tui.md の付録](podman-tui.md#付録-コンテナでの検証記録2026-09-28)と同じ作りの使い捨てのコンテナ（x86_64 の実機の rootless の podman の上）。実機で加えた変更は無い。

**手順書の外で行った準備**: podman-tui.md の付録の準備と同じ。Homebrew のインストーラは `NONINTERACTIVE=1` を付けずに流し、`Press RETURN/ENTER to continue` に Enter を送った。

**流し方**:

- 同じ SSH のセッションで、先に podman.md の手順 1〜3・5〜7 と Docker 向けの節、[homebrew.md](../almalinux-setup.md) の手順 1〜4 を流した
- 本文の折り畳みの外にある bash のブロックを上から順に抜き出し、ブラケットペーストで 1 ブロックずつ貼って Enter を送った
- 画面の手順は、画面の文字を読みながらキーを送った

| 手順 | 結果 |
|---|---|
| 1. 導入 | `Pouring lazydocker--0.25.2.x86_64_linux.bottle.tar.gz`、`6 files, 13.2MB` |
| 2. 確かめる | `Version: 0.25.2`・`BuildSource: Homebrew`、`/home/linuxbrew/.linuxbrew/bin/lazydocker`、`unix:///run/user/<UID>/podman/podman.sock`、`OK` |
| 3. 確認用のコンテナ | イメージを取得し、`lazydocker-web Up Less than a second` |
| 4. 画面 | 4 つの枠と右のログ。`running  lazydocker-web` の行。`←` / `→` で枠を移れた。`s` → `Are you sure you want to stop this container?` → `y` で `exited (0)`。`q` でプロンプトに戻った |
| 5. 確かめる | `lazydocker-web Exited (0) 13 seconds ago`、`config.yml`（0 バイト） |
| podman exec の節 | 手順 1 は `lazydocker-web`、手順 2 の読み戻しに 5 行。手順 3 は `c` → `podman exec sh` → Enter で `sh-5.2$`、`id` で `uid=1001(default) gid=0(root) groups=0(root)`、`exit` と Enter で画面に戻り、`q` |
| compose の節 | 先に EPEL の有効化（今の AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」の手順 1）と、podman-compose.md の手順 1〜6 を通した。手順 1 の読み戻しに 2 行。手順 2 は `[1]─Project`（`compose-sample`）・`[2]─Services`（`check`・`web`）・`[3]─Standalone Containers`（`lazydocker-web`）で、`web` を選んで `r`。手順 3 は `compose-sample_web_1 Up 14 seconds` と `compose-sample_check_1 Up 48 seconds` |
| 更新 | `Warning: lazydocker 0.25.2 already installed` |
| ロールバック | 先に podman-compose.md のロールバック手順 1〜2 を通した。手順 1 は `lazydocker-web`、手順 2 は `Untagged:` と `Deleted:`、手順 3 は `Uninstalling /home/linuxbrew/.linuxbrew/Cellar/lazydocker/0.25.2... (6 files, 13.2MB)`、手順 4 は何も出ずに終わった。最後に podman-compose.md のロールバック手順 4 を通した |

**別に確かめたこと**（同じ作りの別のコンテナで、手順書の外のコマンドとして実行）:

- `DOCKER_HOST` を外したとき・API ソケットを止めたときの画面（手順 2 の補足）
- `docker` コマンドの無い状態の `E`（`+ docker exec -it ...` の後に何も起きない）と `a`（`-it` のコンテナで `+ docker attach --sig-proxy=false <ID>` の後に何も起きない）
- `--label name=` を付けないときの名前の出方と、並びが入れ替わって `r` で別のコンテナを再起動したこと（手順 3 の補足）
- `customCommands:` を 2 回書いたとき（podman exec の節の手順 2 の補足）
- 既定の設定のまま `~/compose-sample` で起動すると、Project と Services の枠が出ないこと
- `podman-docker` を入れると、既定の設定のまま `E`（`bash-5.2$`）・`a`（`Ctrl+P` `Ctrl+Q` で抜けた）・compose の判定が動くこと。確かめた後に `sudo dnf remove -y podman-docker` で外した
- [使い方の基本](../lazydocker.md#使い方の基本)の表のキー

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- 色や罫線の見た目と、デスクトップの端末での表示
- `w`（ブラウザで開く）・`b`（まとめての操作）・`p`（一時停止）・`/`（絞り込み）
- compose のサービスへの `r` 以外の操作（`U`・`D` での up・down など）
- SELinux が有効な PC での動き

### 付録: root でも使う節のコンテナでの検証記録（2026-10-05）

[root でも使う（任意）](../lazydocker.md#root-でも使う任意)を足したときの記録。x86_64 のクラウドホスト（Ubuntu 24.04、cgroup v1）上の Docker 29.6.2 で、使い捨てのコンテナを立てて行った。実機で加えた変更は無い。

**環境**:

- イメージは `quay.io/almalinuxorg/10-init:10.2`（`sha256:c8a5eee8…28e1`。中のパッケージは `x86_64_v2` のもの）。`--privileged --cgroupns=private` で立て、systemd を PID 1 にした
- 版: `podman-5.8.2-9.el10_2.alma.1`、`sudo-1.9.17-10.p2.el10_2.6`、`systemd-257-23.el10_2.2.alma.1`、`bash-5.2.26-6.el10`、`rootfiles-8.1-54.el10`、Homebrew 7.0.8、lazydocker 0.25.2
- `/etc/sudoers` は `Defaults always_set_home`・`Defaults env_reset`・`env_keep`（`LANG` や `LC_*` など。`DOCKER_HOST` は無い）・`secure_path = /sbin:/bin:/usr/sbin:/usr/bin`
- `/root/.bash_profile` は `~/.bashrc` を読む

**手順書の外で行った準備**（検証環境の都合）:

- **cgroup**: ホストは cgroup v1 なので、コンテナの入口のスクリプトで、ホストの cgroup2 の下に枝を作って移り、新しい cgroup の名前空間で `/sys/fs/cgroup` に cgroup2 を付け直してから systemd を起動した。コントローラは無いので、`/etc/containers/containers.conf.d/90-verify.conf` に `pids_limit = 0` を書いた
- **ネットワーク**: root の podman（netavark）が作る `podman0` と nft の表がクラウドのホストに及ばないように、コンテナは Docker の bridge（自分の network namespace）で立てた。プロキシには、ホストの側の中継で届かせた
- **プロキシ**: CA を信頼ストアに足し、dnf の `proxy=`、`almalinux-*.repo` の `baseurl=`（https）、ログインシェルとシステム・ユーザーの systemd のプロキシの環境変数を入れた。`sudo` はプロキシの環境変数を消すので、root の podman のイメージの取得のために、同じ `90-verify.conf` の `[engine]` の `env` にも書いた
- **保管場所**: `/home` と `/var/lib/containers` に Docker のボリューム（ext4）を付けた
- **ログイン**: `systemd-logind` の mask を戻し、コンテナの中の `sshd` に、`<USER>`（wheel、`/etc/sudoers.d` に NOPASSWD の設定）で鍵を使ってログインした
- **前提の手順書**: [podman.md](../podman.md) の手順 1〜3・5〜7 と Docker 向けの節、[homebrew.md](../almalinux-setup.md) の手順 1〜4（インストーラだけ `NONINTERACTIVE=1`）、この文書の手順 1〜3 は、端末の無い ssh からスクリプトで流した（貼ってはいない）
  - その ssh を閉じたとき、linger が無いので自分の `lazydocker-web` が止まった。入口の確認の前に `podman start` で起動し直した
- homebrew.md の [root のシェルでも使う](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節の手順 1 は、下の端末に貼った

**流し方**:

- ホストの tmux 3.4 のペイン（160x50）から `docker exec -it … ssh -t <USER>@127.0.0.1` でログインした
- この文書から節のブロック（折り畳みの外のもの）を抜き出し、手順ごとに `tmux paste-buffer` で貼った。1 回目はブラケットペースト無し、2 回目は `paste-buffer -p`（ブラケットペースト有り。貼った後に Enter を送った）
- 画面は `tmux capture-pane` で読み、キーは `tmux send-keys` で送った

| 手順・確認 | 結果 |
|---|---|
| 節の前 | `sudo -i lazydocker` は `-bash: line 1: lazydocker: command not found`（終了コード 127）。`podman.socket`（システム）は `disabled`、root のイメージは 0 個、`/root/.config` は無い |
| 1 | `Created symlink '/etc/systemd/system/sockets.target.wants/podman.socket' → '/usr/lib/systemd/system/podman.socket'.`、`active`、`OK`、`5.8.2`。ソケットは `srw-rw---- root root` |
| 2 | 書いた行、`unix:///run/podman/podman.sock`、`/home/linuxbrew/.linuxbrew/bin/lazydocker`。もう一度貼ると `中断: /root/.bashrc に DOCKER_HOST が既にある` と同じ 2 行で、`/root/.bashrc` の SHA-256 は変わらない |
| 3 | イメージ（285 MB）を取得し、ID と `lazydocker-root-web Up Less than a second` |
| 4 | 枠に出たのは root のコンテナとイメージだけ（`running  lazydocker-root-web`、`registry.access.redhat.com/ubi10/httpd-24`）。`s` → `Are you sure you want to stop this container?` → `y` で `exited (0)`。`q` でプロンプトに戻った |
| 5 | `lazydocker-root-web Exited (0) 20 seconds ago`、`config.yml`（root の持ち物、0 バイト） |
| 自分の lazydocker | 自分のコンテナ（`lazydocker-web`）と自分のイメージ（`quay.io/podman/hello`・`ubi10/httpd-24`）だけ |
| `sudo -i printenv TERM LANG HOME DOCKER_HOST` | `xterm`、`C.utf8`、`/root`、`unix:///run/podman/podman.sock` |
| `sudo -s`・`su -` | どちらも `HOME` は `/root`、`DOCKER_HOST` は root のソケットで、`lazydocker` の画面は `running  lazydocker-root-web` だけ。`su -` は検証のためだけに root にパスワードを付け、後で `/etc/shadow` を戻した |
| `sudo lazydocker` | root のシェルの節だけのときは `sudo: lazydocker: command not found`（終了コード 1）。homebrew.md の sudo の節の手順 1 の後は、`Error` の枠に `Cannot connect to the Docker daemon at unix:///var/run/docker.sock` が出て、`Retry count` が増えた |
| `sudo -E lazydocker` | `sudo -E printenv` は `HOME` が `/root`、`DOCKER_HOST` が `unix:///run/user/<UID>/podman/podman.sock`。画面は `running  lazydocker-web`（自分のコンテナ）。自分のホームに root の持ち物のファイルはできなかった |
| `sudo DOCKER_HOST=unix:///run/podman/podman.sock lazydocker` | `running  lazydocker-root-web` |
| root の `c`・`E` | root の設定ファイルに [podman exec の節](../lazydocker.md#podman-exec-でシェルを開く任意)の手順 2 の 5 行を書くと、`c` → `podman exec sh` → Enter で `+ podman exec -it <ID> sh` と `sh-5.2$`、`id` は `uid=1001(default) gid=0(root) groups=0(root)`、`exit` と Enter で画面に戻った。`E` は `+ docker exec -it <ID> /bin/sh -c ...` と `Press enter to return to lazydocker ...` だけ |
| 6 | `lazydocker-root-web`、`0`。`/root/.bashrc` の SHA-256 が、この節の前（homebrew.md の root のシェルの節の後）と一致し、その節の `case` の行は残った。空の `/root/.config` は残った |
| 7 | `Untagged: registry.access.redhat.com/ubi10/httpd-24:latest`、`Deleted: 8b178ff9bc02…` |
| 8 | `Removed '/etc/systemd/system/sockets.target.wants/podman.socket'.`、`inactive`。`/run/podman/podman.sock` のファイルは残り、つなぐと `curl` は終了コード 7 |
| podman-docker | AppStream の `podman-docker-5.8.2-9.el10_2.alma.1` を入れると、`/run/docker.sock -> /run/podman/podman.sock` ができた。`/root/.bashrc` に行が無いまま、手順 2 の確かめの行が `unix:///run/podman/podman.sock` と `lazydocker` の 2 行を出し、`grep -c DOCKER_HOST /root/.bashrc` は `0`。ソケットを有効にすると、`sudo lazydocker` は root のコンテナを出した。`dnf remove` の後もリンクは残ったので、手で消した |
| 2 回目（ブラケットペースト有り） | 手順 1〜8 が 1 回目と同じ結果。ソケットが有効なまま手順 1 をもう一度貼ると、`Created symlink` は出ず、`active`・`OK`・`5.8.2` だけ |
| 前提の分岐（2 回目の途中） | 手順 2 の後に homebrew.md の root のシェルの節の手順 2 を貼ると、`DOCKER_HOST` の行は残り、sudo の節だけで `sudo -i bash -c '…'` が `lazydocker` を見つけた。手順 5 の後に sudo の節の手順 2 も貼ると、手順 2 の確かめの行は `unix:///run/podman/podman.sock` の 1 行だけで、`sudo -i lazydocker` は `-bash: line 1: lazydocker: command not found`（終了コード 127） |
| 後 | 手順 8 の後、`/root/.bashrc` の SHA-256 は、homebrew.md の 2 つの節を通す前と一致した。root のイメージとコンテナは 0 個、`podman.socket` は `disabled` |

#### 未確認事項（root の節）

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- SELinux が Enforcing のホスト（検証のコンテナには SELinux が無い）
- root の Quadlet（`/etc/containers/systemd`）で動かしたコンテナの見え方と操作
- 再起動の後の、システムの `podman.socket` の起動
- コンソールでの root のログインと、bash 以外の root のシェル
- root で compose のプロジェクトを見ること

### 付録: aarch64 の実機での検証記録（2026-10-06）

AlmaLinux 10.2 の aarch64 ホストで、導入済みの lazydocker 0.25.2 を使って検証した。事前確認は 2026-10-05、画面操作と後片付けは 2026-10-06（Asia/Tokyo）。SELinux は Enforcing、cgroup は v2。Homebrew は 7.0.8、Podman は 5.8.2。`docker`・`podman-docker`・`podman-compose` は無い。

**実施前の状態**:

- ユーザーの `podman.socket` は `inactive/disabled`、`DOCKER_HOST` は空。ユーザーのコンテナとイメージは 0 件で、`~/.config/lazydocker` は無い
- `~/.bashrc` は自分用の bash の設定を読み、ユーザーのソケットがあるときに `DOCKER_HOST` を入れる。設定の追記は不要だった
- システムの `podman.socket` は `active/enabled`。root のログインシェルには、既に `DOCKER_HOST=unix:///run/podman/podman.sock` と Homebrew の lazydocker の PATH がある
- root のコンテナは 0 件、既存イメージは 3 件。`/root/.config/lazydocker` は無い

**検証方法**:

- 手順書のブロックを実機で機械的に流さず、既存状態を確かめながら個別に実行した。新規導入・更新・アンインストールは行っていない
- Codex の通常のサンドボックスでは `podman` が `/run/user/<UID>/libpod` の read-only エラー、`systemctl` が `Operation not permitted` で失敗した。同じユーザーのサンドボックス外のコマンドでは動いた
- ユーザーのソケットは `systemctl --user start podman.socket` で一時起動し、`. ~/.bashrc` で既存設定を読み直した。永続的な有効化は行っていない
- 名前の衝突を避け、確認用コンテナはユーザーを `lazydocker-verify-20261005`、root を `lazydocker-root-verify-20261005` にした。それぞれ同名の `name` ラベルを付け、本文と同じ `registry.access.redhat.com/ubi10/httpd-24:latest` を使った。取得したイメージは arm64
- 設定は `CONFIG_DIR=/tmp/lazydocker-verification/config` と、root 用の `CONFIG_DIR=/tmp/lazydocker-root-verification/config` に分離した。`CONFIG_DIR` は [0.25.2 の設定処理](https://github.com/jesseduffield/lazydocker/blob/v0.25.2/pkg/config/app_config.go)で対応を確認した。通常の設定ディレクトリは作っていない
- 最初は `/usr/bin/tmux`（`next-3.4`）を使ったが、`capture-pane -p` で `server exited unexpectedly` になった。`/usr/bin/python3` の pexpect と、一時ディレクトリだけに取得した pyte で、160 桁 × 50 行の擬似端末を読み取る方法へ替えた。`TERM=xterm-256color`、`LANG=C.UTF-8`
- ユーザーの画面では `DOCKER_HOST` をユーザーのソケットに指定。root は `sudo -n -i env CONFIG_DIR=/tmp/lazydocker-root-verification/config TERM=xterm-256color lazydocker` で、既存のログインシェルの接続先を使った

| 確認 | 結果 |
|---|---|
| 導入済みの本体 | `Version: 0.25.2`、`BuildSource: Homebrew`、`Arch: arm64`。パスは `/home/linuxbrew/.linuxbrew/bin/lazydocker`。Homebrew の導入記録は `poured_from_bottle: true`、formula の `arm64_linux` ボトルも確認 |
| ユーザー API | 既存 bash 設定を読み直すと `unix:///run/user/<UID>/podman/podman.sock`。`/_ping` は `OK`、remote のサーバー版は `5.8.2`、`/version` に `Podman Engine` |
| ユーザーの基本画面 | Containers・Images・Volumes・Networks、専用名の `running`、Apache の `resuming normal operations` を表示 |
| ユーザーの停止 | Config タブの ID を確認用コンテナと照合し、`s` → 確認 → `y` で `exited (0)`。`q` で終了コード 0。`podman ps -a` も `Exited (0)` |
| 初回設定 | 分離したディレクトリに `config.yml`（0 バイト）を作った |
| podman exec の任意節 | コンテナを `podman start` し、一時設定に本文の `customCommands` を追加。`c` → `podman exec sh` → Enter で `sh-5.2$`、`id` は `uid=1001(default) gid=0(root) groups=0(root)`。`exit` → Enter で画面に戻り、`q` で終了コード 0 |
| root の接続 | 既存のシステムソケットの `/_ping` は `OK`。権限は `srw-rw---- root root` |
| root の画面と停止 | root の専用コンテナ・Apache ログを表示し、ユーザーの確認用コンテナは出なかった。Config タブの ID を照合後、`s` → 確認 → `y` で `exited (0)`。`q` で終了コード 0、Podman 側も `Exited (0)`。一時設定は root 所有の 0 バイト |

**後片付け**: 今回のコンテナだけを `podman rm -f lazydocker-verify-20261005` と `sudo -n podman rm lazydocker-root-verify-20261005` で撤去し、今回取得した UBI httpd のイメージをユーザーと root の保管場所からそれぞれ `podman rmi` で撤去した。ユーザーのソケットは `systemctl --user stop podman.socket` で `inactive/disabled` に戻した。root のソケットは元の `active/enabled` を維持した。通常の設定ディレクトリはユーザー・root とも作られず、既存の bash 設定と lazydocker 本体は残った。ユーザーのコンテナ・イメージは 0 件、root のコンテナは 0 件、root の既存イメージは開始前と同じ 3 件。一時設定と検証用の端末も撤去した。

**このホストで実施する場合**: 一般ユーザーの手順は、前提の [Podman 手順 7](../podman.md#実施手順)でユーザーの API ソケットを有効にし、既存の bash 設定を読み直せば実施できる。root の任意節は既存のソケットと設定で動いた。compose の任意節は `podman-compose` と確認用プロジェクトが未導入なので、そのままでは実施できない。

#### 今回確認していないこと

- 新規インストール、更新、`brew uninstall` と通常の設定ディレクトリ削除を含む全ロールバック
- compose の任意節。前提を追加する検証はしていない
- 実機での root のソケットの新規有効化、`/root/.bashrc` への追記・撤去、root の Quadlet、再起動後の動作
- デスクトップの端末での見た目、その他のキー操作、x86_64 の実機

---

### 付録: VM での検証記録（2026-10-06）

**検証した版**: コミット `0dbb522` の lazydocker.md と前提の手順書を使った。共通の bash 設定へ統一する前の版で、今回の VM にその共通設定は導入していない。後から変更されたコードブロックと、共通設定を前提にした構築の流れは、この VM で本実行していない。

**環境**: [クリーンインストールからの検証記録](../almalinux-vm-verification.md)のコンテナ用 VM。公式 ISO から Workstation を入れた状態から始め、x86_64、SELinux Enforcing、firewalld 有効。この版のブロックを SSH の擬似端末で実行した。

- `0dbb522` 版の podman.md の Docker 向けの節と homebrew.md の後、同じ版の lazydocker.md の実施手順 1〜5 を通した。Homebrew の lazydocker 0.25.2 が `DOCKER_HOST` で podman 5.8.2 のソケットにつながった。
- `lazydocker-web` と Apache のログが表示された。`s` で Stop の確認を開き、`y` で止めると `Exited (0)` になった。`q` で終え、CLI でも停止を確認した。SELinux は Enforcing のまま。
- 今回は基本の導入と停止操作まで。シェル・compose・root の任意節、全キーの網羅、色・罫線、更新・ロールバック、実機・aarch64 は通していない。root の任意節の既存のコンテナ記録を VM の結果とは扱わない。

---

### 付録: 現行版を新規 VM で再検証（2026-10-06）

**対象**: `setup-notes` の `5da3478` 版。公式 ISO で Workstation を入れた `clean-install` スナップショットから、新規の `alma10-current-20261006-containers` を作った。AlmaLinux 10.2 / x86_64 / SELinux Enforcing / firewalld 有効。共通 bash は `3d5323e` を新規導入した。以前の付録と別の試験で、現行ブロックを SSH の擬似端末で順に実行した。

実施手順 1〜5 を通した。Homebrew の 0.25.2 が、現行の共通 bash が設定した `DOCKER_HOST` で Podman 5.8.2 に接続した。実画面で `lazydocker-web` と Apache のログを確認し、`s` → `y` で `exited (0)`、`q` でホストに戻った。以前の `0dbb522` 版の付録で未実施だった、共通設定からの導入と基本操作を今回通し直した。シェル・compose・root の任意節、更新はこの再検証では行っていない。

ロールバックの手順 1〜4 を通した。専用コンテナを撤去し、ほかの使用元も無くなった時点で共有イメージを削除、本体を brew で削除、設定ディレクトリを撤去した。

### 実施手順 / 手順 3: 補足: --label name= を付ける理由

- Red Hat の UBI のイメージには `name=ubi10/httpd-24` のようなラベルが付いていて、コンテナはそれを受け継ぐ
- 付けずに動かすと、同じイメージのコンテナ（Quadlet の `hello-web`、compose の `web`・`check` など）がどれも `ubi10/httpd-24` の名前で並ぶ
- 検証では、止めた後に並びが入れ替わり、`r` で意図しない方のコンテナを再起動した
- `--label name=<名前>` で上書きすると、その名前で出た

### podman exec でシェルを開く（任意） / 手順 2: 補足: 足した設定と、キーが重なったとき

- `sh` にしたのは、`bash` の無いイメージでも動くようにするため。UBI のイメージでは `sh-5.2$` と出る
- 検証で、`customCommands:` を 2 回書いた設定を読ませた。エラーにならずに起動し、前に書いた `first entry` がメニューから消え、後ろに書いた `podman exec sh` だけが出た

### compose のプロジェクトを見る（任意） / 手順 1: 補足: 替わるコマンド

- compose のプロジェクトかどうかは、起動のときに `podman-compose config --quiet` の終了コードで決まる
- `~/compose-sample` では終了コード 0、compose ファイルの無いホームでは `CRITICAL:podman_compose:no compose.yaml, docker-compose.yml or container-compose.yml file found, pass files with -f` と出て 255 だった
- compose ファイルの無いディレクトリで起動すると、Project と Services の枠が出ないだけで、ほかは変わらない

### root で使うときの補足

- **入口と前提の節**: `-i` の無い 3 つは、[AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通したときだけ動く（通さないと `sudo: lazydocker: command not found`）
  - `su -` は、[AlmaLinux 10 の初期設定の Homebrew を root のシェルでも使う](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節が要る
  - `sudo -i lazydocker` は、どちらの節だけでも動いた。どちらも無いと `-bash: line 1: lazydocker: command not found`
- **`sudo -E` は使わない**: `HOME` は `/root`（`/etc/sudoers` の `always_set_home`）で root の設定を読みながら、root の権限で自分のコンテナを操作する
  - 自分の `~/.config/lazydocker` に、root の持ち物のファイルはできなかった
- **root の設定ファイルは `/root/.config/lazydocker/config.yml`**: 自分の設定（任意節で足した `c` のコマンドなど）は使わない
  - root でも `c` からシェルを開くなら、[podman exec の節](../lazydocker.md#podman-exec-でシェルを開く任意)の手順 2 の 5 行を、`sudo` で root の設定ファイルに書く
  - 書いたコンテナでは、root の画面の `c` → `podman exec sh` で `sh-5.2$` が開いた
- **`E` と `a` は root でも何も起きない**: `docker` コマンドが無いため（[注意点](../extra/lazydocker.md#注意点)）
- **root のシェルの `DOCKER_HOST` は、ほかのツールにも効く**: root のシェルで動かす Docker の API を使うツールも、root の podman につながる。podman 自身は `DOCKER_HOST` を読まない
- **podman-docker を入れたホストでは**: `/etc/profile.d/podman-docker.sh` が、`DOCKER_HOST` の無い root のログインシェルに同じ値を入れ、`/run/docker.sock` を root のソケットへのリンクにする
  - その節の手順 2 の確かめの行は、書く前から同じ 2 行を出した。`if` は `/root/.bashrc` しか見ないので、同じ行を書き足す（害は無い）
  - `-i` の無い `sudo lazydocker` も、root のコンテナにつながった
  - podman-docker を外しても、`/run/docker.sock` のリンクは再起動まで残った
- **ソケットの権限を緩めない**: root の API ソケットにつなげると、root でコンテナを動かせる（ホストの `/` を付けたコンテナなど）。`SocketGroup` などで広げない（[選択した方針](#選択した方針)）

### 実施手順 / 手順 1: 補足: ボトル

x86_64 で降ってきたボトルは `lazydocker--0.25.2.x86_64_linux.bottle.tar.gz`（5.0 MB）。

```
==> Pouring lazydocker--0.25.2.x86_64_linux.bottle.tar.gz
🍺  /home/linuxbrew/.linuxbrew/Cellar/lazydocker/0.25.2: 6 files, 13.2MB
```

### 実施手順 / 手順 4: 補足: 画面の中身

起動した直後の画面（抜粋。右の枠は幅を詰め、ログの行は折り返しを変えた）:

```
╭─[3]─Containers─────────────────────────────────────╮╭─Logs - Stats - Env - Config - Top───────────╮
│running  lazydocker-web 3.27% 8080/tcp, 8443/tcp reg││=> sourcing 10-set-mpm.sh ...                  │
│                                                    ││=> sourcing 20-copy-config.sh ...              │
...
╭─[4]─Images─────────────────────────────────────────╮│... AH00489: Apache/2.4.63 (Red Hat Enterprise │
│quay.io/podman/hello                      latest 786││Linux) OpenSSL/3.5.8 configured -- resuming    │
│registry.access.redhat.com/ubi10/httpd-24 latest 285││normal operations                              │
...
╭─[6]─Networks───────────────────────────────────────╮│                                               │
│bridge bridge                                       ││                                               │
...
PgUp/PgDn: scroll, b: view bulk commands, q: quit, x: menu, ← → ↑ ↓: navigate          Donate 0.25.2
```

### root でも使う（任意） / 手順 4: 補足: 画面の中身

起動した直後の画面（抜粋。右の枠は幅を詰め、ログの行は折り返しを変えた）:

```
╭─[3]─Containers─────────────────────────────────────╮╭─Logs - Stats - Env - Config - Top───────────╮
│running  lazydocker-root-web 0.00% 8080/tcp, 8443/tc││=> sourcing 10-set-mpm.sh ...                  │
│                                                    ││=> sourcing 20-copy-config.sh ...              │
...
╭─[4]─Images─────────────────────────────────────────╮│... AH00489: Apache/2.4.63 (Red Hat Enterprise │
│registry.access.redhat.com/ubi10/httpd-24 latest 285││Linux) OpenSSL/3.5.8 configured -- resuming    │
...
```
