# distrobox インストール手順（AlmaLinux 10 / EPEL）の参考資料

[手順書](../distrobox.md)

## 補足

### 実施手順 / 手順 3: 補足: distrobox の依存

[この節の検証記録](../verification/distrobox.md#実施手順--手順-3-補足-distrobox-の依存)

`rpm -q --requires distrobox` の中身は `(podman or /usr/bin/docker)` と `hicolor-icon-theme` など。

- podman を消すと distrobox も消える（[podman.md のロールバック](../podman.md#ロールバック)の手順 6 に当たる）
- distrobox の本体はシェルスクリプトで、`/usr/bin/distrobox-create`・`distrobox-enter` などのコマンドの集まり

### 実施手順 / 手順 4: 補足: ボックスは隔離されていない

| オプション | 意味 |
|---|---|
| `--privileged` | 特権付きのコンテナ（rootless なので、ホストの root にはならない） |
| `--security-opt label=disable` | SELinux のラベルによる分離を切る |
| `--network host` / `--pid host` / `--ipc host` | ネットワーク・プロセス・IPC をホストと共有する |
| `--userns keep-id:size=65536` | 自分の UID・GID はボックスの中でも同じ番号に対応し、ボックスの root は subordinate UID・GID に対応する |
| `--volume "/home/<USER>":"/home/<USER>"` | ホームディレクトリをそのまま使う |
| `--volume /:/run/host/` | ホストのファイルシステム全体を `/run/host` に見せる |
| `--pids-limit=-1` | プロセス数を制限しない |

**ボックスは「別のディストリのユーザーランドを使うための道具」で、安全のための隔離ではない**（[注意点](../distrobox.md#注意点)）。

### 実施手順 / 手順 5: 補足: 初期化で行われること

- ボックスの中に自分と同じ名前のユーザーを作り、`sudo` をパスワード無しで使えるようにする（ボックスの中の `sudo -l` は `(root) NOPASSWD: ALL`）
- 本書の `--userns keep-id` では、ボックスの root はホストの subordinate UID に対応する。自分の UID に対応するのはボックス内の同じ UID で、ボックスの root にホストの root の権限は無い
- コンテナが止まっていれば、次の `distrobox enter` でも起動と初期化の確認が走る（2 回目からは速い）

### 実施手順 / 手順 6: 補足: host-spawn: command not found

ボックスの中の `/etc/profile.d/distrobox_profile.sh` は、`DISPLAY`・`WAYLAND_DISPLAY`・`XAUTHORITY` などが空のとき、`host-spawn` でホストの値を読みに行く。

### ボックスのコマンドをホストから呼ぶ（任意） / 手順 4: 補足: 書き出されたもの

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

### 選択した方針

| 選択肢 | 採否 |
|---|---|
| **EPEL の distrobox（1.8.2.3）** | **採用。** システムの podman と組んで使うので RPM にした（[ツール一覧の選び方](../tool-catalog.md#選び方)の規則 3）。`dnf upgrade` で上がる |
| Homebrew の distrobox（1.8.2.5） | 不採用。版は新しいが、コンテナ系のツールは RPM に揃えた（Homebrew の podman がシステムの podman を隠す問題を避けるため。[ツール一覧の注意点](../tool-catalog.md#注意点)） |
| 上流の curl のインストーラ | 不採用。`dnf` の管理の外に入り、更新も手作業になる |
| AppStream の toolbox（0.3） | 代わりの選択肢。RHEL の公式の道具で、[ツール一覧](../tool-catalog.md#cli-コンテナ)に載せた。本書は、ボックスのディストリを選べる distrobox にした |
| ボックスのイメージに `quay.io/toolbx/ubuntu-toolbox` を使う | **採用。** `docker.io/library/ubuntu` より初期化で入れるものが少なく、Docker Hub の取得回数の上限にもかからない（手順 1 の補足） |

### 参照

- [distrobox — README](https://github.com/89luca89/distrobox) — 概要、コマンドの一覧、互換のあるイメージ（`docs/compatibility.md`）
- [distrobox — Useful tips](https://github.com/89luca89/distrobox/blob/main/docs/useful_tips.md) — 書き出し、ホストのコマンドの呼び出し
- `man distrobox-create` / `man distrobox-enter` / `man distrobox-export` / `man distrobox-rm` — オプション
- [Podman](../podman.md) — 前提の rootless の podman
- [EPEL](../epel.md) — 前提の EPEL の有効化

---
