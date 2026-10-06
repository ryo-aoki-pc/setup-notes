# podman-tui インストール手順（AlmaLinux 10 / EPEL）の検証記録

[手順書](../podman-tui.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 の VM で実施手順を検証した。SSH の擬似端末で文字の表示とキー操作を確認した。色・罫線の見た目と実機での実行は未確認**（[対象と検証環境](#対象と検証環境)）。

### ロールバック / 手順 3: 本文中の記録

   - podman-tui はホームにファイルを作らなかったので、ほかに消すものは無い（検証の実測）

### 対象と検証環境

- **目的**: podman のコンテナ・pod・イメージ・ボリューム・ネットワーク・シークレットを、端末の画面（TUI）で見て操作できるようにする
- **進め方**: EPEL（前提の [epel.md](../epel.md) で有効にする）の podman-tui 1.10.0 を入れ、podman の API ソケットにつないで、確認用のコンテナを画面から止める。**読者が書き換える変数は無い**
- **状態**: **x86_64 の VM で実施手順 1〜5を検証済み（2026-10-06、SELinux Enforcing）。実機では本実行していない**
  - VM の実測は[今回の付録](#付録-vm-での検証記録2026-10-06)。以下のコンテナでの結果と未確認事項は、当時の検証範囲の記録。
  - 下表の検証コンテナで、[podman.md](../podman.md) の実施手順を通したうえで、**この文書のコードブロックをそのまま端末に貼って**、EPEL の有効化（今の [epel.md](../epel.md) の手順 1〜3。当時はこの文書の手順だった）、手順 1〜5、[更新](../podman-tui.md#更新)、[ロールバック](../podman-tui.md#ロールバック)を通した
  - 確認したこと:
    - EPEL の podman-tui 1.10.0 が 1 パッケージで入り、podman 5.8.2 の API ソケットに `STATUS_OK` でつながる
    - 画面のメニューの `stop` でコンテナが止まり、`podman ps` にも `Exited (0)` で出る
    - [使い方の基本](../podman-tui.md#使い方の基本)の表のキー
    - Homebrew の 2.0.0 と、API ソケットが止まっているときの画面（[注意点](../podman-tui.md#注意点)）
  - **確認していないこと**: 色や罫線の見た目、デスクトップの端末での F キー、SELinux が有効なとき、SSH でほかのホストの podman につなぐこと
  - aarch64（Raspberry Pi 5）では通していない

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-28 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2` を、x86_64 の実機の rootless の podman 5.8.2 で `--privileged` にして起動。systemd が PID 1） |
| podman | 未確認 | `podman-5.8.2-9.el10_2.alma.1`（[podman.md](../podman.md) の実施手順で導入。入れ子の rootless） |
| EPEL | 未確認 | 未設定 → [epel.md](../epel.md) の手順 2 で `epel-release-10-6.el10` を導入 |
| podman-tui | 未導入 | `podman-tui-1.10.0-1.el10_2`（epel） |
| 端末 | — | 160 桁 × 50 行の擬似端末（`TERM=xterm-256color`、`LANG=C.UTF-8`）の SSH のログインシェル |

- 実機の列は、この手順を適用した結果ではない

> [!NOTE]
> 出力例の値は `<USER>` / `<UID>` / `<HOSTNAME>` のプレースホルダで書いてある。バージョン（`1.10.0`・`5.8.2`）とイメージの大きさは実行日によって変わる。**鍵の fingerprint は公開情報なので本文に書いてある。**

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（[podman.md](../podman.md) の実施手順の後）の状態:

| 項目 | 状態 |
|---|---|
| podman | 5.8.2（rootless で `true`）。API ソケットは `active` |
| EPEL | 未設定（`EPEL は未設定`） |
| podman-tui | 未導入 |
| podman の接続（`podman system connection list`） | 無し |

### 選択した方針

- 1.10.0 は EPEL の版で、上流の 1.x の最新は 1.11.3（podman 5.8.4 の部品。2026-06-28）。EPEL が上げるまでは 1.10.0 のまま

### 完了時点の状態

**検証コンテナでの出力**（手順 2・3・5）:

```
$ podman-tui version
podman-tui v1.10.0
$ command -v podman-tui
/usr/bin/podman-tui
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' podman-tui
podman-tui 1.10.0-1.el10_2 epel
$ podman run -d --name podman-tui-web registry.access.redhat.com/ubi10/httpd-24:latest
...
$ podman ps --filter name=podman-tui-web --format '{{.Names}} {{.Status}}'
podman-tui-web Up Less than a second
$ podman ps -a --filter name=podman-tui-web --format '{{.Names}} {{.Status}}'
podman-tui-web Exited (0) 19 seconds ago
```

手順 4 の画面は、手順 4 の補足のとおり。

### 付録: コンテナでの検証記録（2026-09-28）

**環境**: x86_64 の実機（AlmaLinux 10.2 のノート PC、SELinux は Enforcing）の、rootless の podman 5.8.2 の上の使い捨てのコンテナ。

- 実機の設定は変えていない（`sudo` は使わず、終わった後にコンテナ・ボリューム・イメージを消した）
- イメージは `quay.io/almalinuxorg/10-init:10.2`（`sha256:a91c1066…fd73`、[podman.md の付録](podman.md#付録-コンテナでの検証記録2026-09-27)と同じ）
- `--privileged`・`--systemd=always` で立て、systemd を PID 1 にした。`/home` には名前付きのボリュームを付けた

**手順書の外で行った準備**（検証環境の都合）:

- `/` を shared にし、`10-init` のイメージが mask している `systemd-logind` を戻した
- `openssh-server` と `sudo` を入れ、`<USER>`（NOPASSWD の sudo）を作った
- **subuid / subgid**: 外側のコンテナに割り当てられた UID は 65537 個（0〜65536）しか無いので、`<USER>:1:999` と `<USER>:1001:64535` にした（`quay.io/podman/stable` と同じ割り当て）
  - そのため、[podman.md 手順 3](../podman.md#実施手順) の出力は 2 行ではなく 4 行になった
- ログイン: コンテナの中の `sshd`（127.0.0.1）に、`<USER>` で鍵を使ってログインした。pam_systemd が、`XDG_RUNTIME_DIR` とユーザーの systemd を用意する
- 端末: 実機の tmux（EL10 の `tmux-3.3a-13`）は `capture-pane -p` でサーバーごと落ちたので、Python の擬似端末と `pyte`（端末の模倣）で画面の文字を読んだ
- cgroup v2 の `cpu`・`memory`・`pids` が委譲されていたので、これまでの検証と違い、PID 数の制限は外していない

**流し方**:

- 同じ SSH のセッションで、先に podman.md の手順 1〜3・5〜7 を流した
- 本文の折り畳みの外にある bash のブロックを上から順に抜き出し、ブラケットペーストで 1 ブロックずつ貼って Enter を送った
- `[y/N]` と鍵の確認は、表示を確かめてから `y` と答えた。コマンドに `-y` は足していない
- 手順 4 は、画面の文字を読みながらキー（`F4`・`↓`・`m`・`Enter`・`Ctrl+C`）を送った

| 手順 | 結果 |
|---|---|
| epel.md 1〜3. EPEL | `EPEL は未設定` → `epel-release-10-6.el10` と依存の 7 つ → `epel` の行 |
| 1. 導入 | `podman-tui.x86_64  1.10.0-1.el10_2  epel`。`[y/N]` と EPEL の鍵（`0xE37ED158`、fingerprint は本文のとおり）に `y`。1 パッケージ（9.5 MB、展開後 32 MB） |
| 2. 確かめる | `podman-tui v1.10.0`、`/usr/bin/podman-tui`、`podman-tui 1.10.0-1.el10_2 epel` |
| 3. 確認用のコンテナ | イメージを取得し、`podman-tui-web Up Less than a second` |
| 4. 画面 | `✅ STATUS_OK`・`API version: 5.8.2`・`localhost` が `✅ connected`。`F4` で `CONTAINERS[1]`、`m` → `↓` を 19 回で `stop` → Enter の 2 秒後に `▼ Exited (0) 1 second ago`。`Ctrl+C` でプロンプトに戻った |
| 5. 確かめる | `podman-tui-web Exited (0) 19 seconds ago` |
| 更新 | `Nothing to do.` |
| ロールバック | この節の手順 1 は `podman-tui-web`、手順 2 は `Untagged:` と `Deleted:`。手順 3 の `[y/N]` に `y` で、`podman-tui-1.10.0-1.el10_2.x86_64` が消えた（`Freed space: 32 M`）。`~/.config` には `systemd` だけが残った |

**別に確かめたこと**（同じ作りの別のコンテナで、手順書の外のコマンドとして実行）:

- [使い方の基本](../podman-tui.md#使い方の基本)の表のキーを 1 つずつ押した。`s` の並べ替えのダイアログは、項目にいるうちは `Esc` で閉じず、`Tab` で `Cancel` に移って Enter で閉じた
- 起動の前後で `find ~ -newer <印のファイル>` を比べ、podman-tui がホームにファイルを作らないこと（`~/.config/podman-tui` も `podman-tui.log` も無い）
- API ソケットを止めた状態の画面（手順 4 の補足）
- Homebrew の podman-tui 2.0.0（`podman-tui--2.0.0.x86_64_linux.bottle.tar.gz`、31.4 MB）: そのままでは `❌ DISCONNECTED` と `SYSTEM CONNECTIONS[0]`。`podman system connection add` の後は `STATUS_OK`・API の版 `5.8.2` で、コンテナの一覧と `start` ができた
- podman の接続を登録すると、1.10.0 も `localhost` ではなくその接続を出すこと
- `sudo dnf remove --assumeno podman` の 30 パッケージに、podman-tui が入らないこと

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- 色や罫線の見た目と、デスクトップの端末（GNOME の端末・WezTerm）での F キー
- `m` のメニューの `stop` 以外の操作（`exec`・`logs` など）
- SSH でほかのホストの podman につなぐこと（`podman system connection add` の `ssh://`）
- SELinux が有効な PC での動き

---

### 付録: VM での検証記録（2026-10-06）

**環境**: [クリーンインストールからの検証記録](../almalinux-vm-verification.md)のコンテナ用 VM。公式 ISO から Workstation を入れた状態から始め、x86_64、SELinux Enforcing、firewalld 有効。本文のブロックを SSH の擬似端末で実行した。

- podman.md と epel.md の後、本文の手順 1〜5 を通した。EPEL の podman-tui 1.10.0 が入り、podman 5.8.2 のソケットに `STATUS_OK` でつながった。SELinux は Enforcing のまま。
- 確認用の `podman-tui-web` に対し、F4 でコンテナ一覧、`m` でメニューを開き、`stop` を選んだ。画面と終了後の `podman ps -a` の両方で `Exited (0)` を確認した。
- 今回の確認は SSH の擬似端末での文字と操作。デスクトップの F キー・色や罫線、SSH で別ホストの podman に接続する操作、Homebrew 版、更新・ロールバック、実機・aarch64 は通していない。

---

### 付録: 現行版を新規 VM で再検証（2026-10-06）

**対象**: `setup-notes` の `5da3478` 版。公式 ISO で Workstation を入れた `clean-install` スナップショットから、新規の `alma10-current-20261006-containers` を作った。AlmaLinux 10.2 / x86_64 / SELinux Enforcing / firewalld 有効。共通 bash は `3d5323e` を新規導入した。以前の付録と別の試験で、現行ブロックを SSH の擬似端末で順に実行した。

実施手順 1〜5 を通した。EPEL の 1.10.0 が共通 bash 導入後のユーザー socket につながり、`STATUS_OK` / API 5.8.2 が出た。実画面で `F4` → 対象行 → `m` → `stop` と操作し、専用の `podman-tui-web` が `Exited (0)` になった。`Ctrl+C` でホストに戻った。色・罫線の見た目、全キー、更新はこの再検証では行っていない。

ロールバックの手順 1・3 で確認用コンテナと RPM を削除できた。手順 2 の共有イメージはほかの手順書も使っていたため、その時点では飛ばし、最後の使用元を撤去した後に削除した。

### 手順中の実測・検証状況の記録

- 検証では、`local` の名前で登録した接続が `✅ connected` で出た

### 実施手順 / 手順 1: 補足: 依存と、podman との関係

- 入るファイルは `/usr/bin/podman-tui` とライセンスの 2 つ
- podman のパッケージには依存しない。podman のコマンドも呼ばず、API ソケット（[podman.md 手順 7](../podman.md#実施手順)）にだけつなぐ
- そのため、podman を消しても podman-tui は残る（検証では、`sudo dnf remove --assumeno podman` が消す 30 パッケージに入っていなかった）

### 選択した方針

| 選択肢 | 採否 |
|---|---|
| **EPEL の podman-tui（1.10.0）** | **採用。** 上流の互換表で、1.x は podman 5.x 向け（AlmaLinux 10 は 5.8.2）。システムの podman と組んで使うので RPM にした（[ツール一覧の選び方](../tool-catalog.md#選び方)の規則 3）。`dnf upgrade` で上がる |
| Homebrew の podman-tui（2.0.0） | 不採用。上流の互換表で、2.x は podman 6.x 向け。接続を podman の設定からだけ読むので、podman.md を通しただけの PC では `❌ DISCONNECTED` で、接続が 0 件だった（[注意点](../podman-tui.md#注意点)） |
| GitHub のリリースの実行ファイル | 不採用。`dnf upgrade` に乗らない |
| [lazydocker](../lazydocker.md) | 別の手順書。Docker の API（`DOCKER_HOST`）でつなぐので、pod とシークレットの画面は無い。ログと CPU の使用率は見やすい |
| GUI（Pods・Podman Desktop・Cockpit） | 対象外。[ツール一覧](../tool-catalog.md#コンテナ)にある |

### 手順内の実測・検証状況

- 2.0.0 は接続を podman の設定からだけ読む。podman.md を通しただけの PC では、接続が 0 件（`SYSTEM CONNECTIONS[0]`）だった

### 手順内の実測・検証状況

- `podman system connection add` で接続を登録すると、2.0.0 も podman 5.8.2 に `STATUS_OK` でつながり、一覧と `start` はできた。ただし上流の互換表の外の組み合わせ

### 実施手順 / 手順 4: 補足: 画面の中身と、つながらないとき

起動した直後の SYSTEM の画面（抜粋。空白は詰めた）:

```
 Connection:   ✅ STATUS_OK          Kernel version:  6.12.0-211.56.1.el10_2.x86_64
 Hostname:     <HOSTNAME>            API version:     5.8.2
 OS type:      linux                 OCI runtime:     crun version 1.27
 Memory usage: ▉▉▉▉▉▉▉▉▉▉ 32.17%     Conmon version:  2.2.1
 Swap usage:   ▉▉▉▉▉▉▉▉▉▉   NaN%     Buildah version: 1.43.1
╔════════════ SYSTEM CONNECTIONS[1] ════════════╗
║NAME       DEFAULT   STATUS         URI                                       ║
║localhost    ✅      ✅ connected   unix://run/user/<UID>/podman/podman.sock  ║
...
   <F1> HELP  <F2> SYSTEM  <F3> PODS  <F4> CONTAINERS  <F5> VOLUMES  <F6> IMAGES  <F7> NETWORKS  <F8> SECRETS
```

止めた後のコンテナの画面（抜粋）:

```
║CONTAINER ID   IMAGE                                   POD   CREATED          STATUS                       NAMES
║fcb0527cb46f   registry.access.redhat.com/ubi10/http…        47 seconds ago   ▼ Exited (0) 9 seconds ago   podman-tui-web
```

