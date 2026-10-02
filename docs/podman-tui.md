# podman-tui インストール手順（AlmaLinux 10 / EPEL）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Podman](podman.md) の実施手順（手順 7 の API ソケットまで）と、[EPEL](epel.md) を通してあること（podman-tui は EPEL にあり、AppStream には無い）。`systemctl --user is-active podman.socket` が `active` を返さないか、`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（podman-tui は、自分のユーザーの API ソケットにつなぐため）
> - **手順 1 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）。答えてから手順 2 を貼る
> - **手順 4 で podman-tui の画面（TUI）が開く**。`Ctrl+C` で終了してから手順 5 を貼る（`q` では終わらない）

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 日々の操作は[使い方の基本](#使い方の基本)、以後は[更新](#更新)・[ロールバック](#ロールバック)
- Docker の API でつなぐ TUI なら [lazydocker](lazydocker.md)（違いは[選択した方針](#選択した方針)）

> [!WARNING]
> **x86_64 のコンテナでのみ検証した手順書**で、実機では本実行していない。画面は、表示された文字を読み取り、キーを送って確かめた（[対象と検証環境](#対象と検証環境)）。

1. 入手できる版を見てから、podman-tui を入れる。

   ```bash
   dnf -q list --showduplicates podman-tui
   sudo dnf install podman-tui
   ```

   - 版は `podman-tui.x86_64  1.10.0-1.el10_2  epel` のように 1 つだけ出る
   - 入るのは `podman-tui` の 1 パッケージだけ（ダウンロード 9.5 MB、展開後 32 MB）
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y` と答える。違っていれば `N` で中断する
   - [epel.md 手順 3](epel.md#実施手順) に書いた鍵
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 依存と、podman との関係</summary>

   podman-tui は Go で書かれた 1 つの実行ファイルで、`rpm -q --requires podman-tui` に出る依存は glibc（`libc.so.6`・`libresolv.so.2`）だけ。

   - 入るファイルは `/usr/bin/podman-tui` とライセンスの 2 つ
   - podman のパッケージには依存しない。podman のコマンドも呼ばず、API ソケット（[podman.md 手順 7](podman.md#実施手順)）にだけつなぐ
   - そのため、podman を消しても podman-tui は残る（検証では、`sudo dnf remove --assumeno podman` が消す 30 パッケージに入っていなかった）

   </details>

1. podman-tui が入ったか確かめる。

   ```bash
   podman-tui version
   command -v podman-tui
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' podman-tui
   ```

   - `podman-tui v1.10.0`、`/usr/bin/podman-tui`、`podman-tui 1.10.0-1.el10_2 epel` が出る

1. 画面で操作する、確認用のコンテナを動かす。

   ```bash
   podman run -d --name podman-tui-web registry.access.redhat.com/ubi10/httpd-24:latest
   podman ps --filter name=podman-tui-web --format '{{.Names}} {{.Status}}'
   ```

   - `podman-tui-web Up Less than a second` のように出る
   - 初回はイメージ（285 MB）を取得する。[podman.md の Quadlet](podman.md#quadlet-で自動起動する任意) などで取得済みなら、取り直さない
   - ポートは公開しない（画面から止めるためだけのコンテナ）

1. podman-tui を起動し、確認用のコンテナを画面から止める。

   ```bash
   podman-tui
   ```

   - 最初に SYSTEM の画面が開き、上の `Connection:` に `✅ STATUS_OK`、`API version:` に `5.8.2` が出る
   - その下の `SYSTEM CONNECTIONS[1]` に、`localhost` が `✅ connected` で出る
   - `F4` でコンテナの画面（`CONTAINERS[N]`）に移り、↑↓ で `podman-tui-web` の行を選ぶ
   - `m` でコマンドのメニューを開き、↓ で `stop` まで下りて Enter を押す（確認は出ない）
   - 数秒で、`STATUS` が `▼ Exited (0) ...` に変わる
   - `Ctrl+C` で終了する
   - **次の手順は、`Ctrl+C` で終了してから貼る**（続けて貼ると podman-tui への操作として食われる）

   <details>
   <summary>補足: 画面の中身と、つながらないとき</summary>

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

   - `localhost` は、podman-tui が `XDG_RUNTIME_DIR` から作る既定の接続。設定ファイルは要らない
   - `unix://run/...` とスラッシュが 2 つなのは podman-tui の書き方で、つながっている
   - `m` のメニューは、`attach`・`checkpoint`・`commit`・`create`・`diff`・`exec`・`healthcheck`・`inspect`・`kill`・`logs`・`pause`・`port`・`prune`・`rename`・`restore`・`rm`・`run`・`start`・`stats`・`stop`・`top`・`unpause` の順。1.10.0 には、項目を選ぶキーの割り当ては無い

   止めた後のコンテナの画面（抜粋）:

   ```
   ║CONTAINER ID   IMAGE                                   POD   CREATED          STATUS                       NAMES
   ║fcb0527cb46f   registry.access.redhat.com/ubi10/http…        47 seconds ago   ▼ Exited (0) 9 seconds ago   podman-tui-web
   ```

   API ソケットが止まっていると、`Connection:` が `❌ STATUS_ERROR` に、`localhost` が `❌ connection error` になり、次のエラーの枠が出る:

   ```
   unable to connect to Podman socket: Get "http://d/v5.7.1/
   libpod/_ping": dial unix /run//user/<UID>/podman/
   podman.sock: connect: connection refused
   ```

   - `Ctrl+C` で終了し、`systemctl --user start podman.socket` で起動し直す
   - `v5.7.1` は、podman-tui が使っている podman の API の版（1.10.0 は podman 5.7.1 の部品で作られている）

   </details>

1. 確認用のコンテナが止まったことを、podman でも確かめる。

   ```bash
   podman ps -a --filter name=podman-tui-web --format '{{.Names}} {{.Status}}'
   ```

   - `podman-tui-web Exited (0) ...` と出ればよい。画面の操作が、API を通して podman に届いている

---

## 使い方の基本

| キー | 動作 |
|---|---|
| `F1` | ヘルプ（キーの一覧） |
| `F2`〜`F8` | SYSTEM・PODS・CONTAINERS・VOLUMES・IMAGES・NETWORKS・SECRETS の画面 |
| `l` / `h`（`→` / `←`） | 次 / 前の画面 |
| `j` / `k`（`↓` / `↑`） | 行を選ぶ |
| `m` | 選んだものへのコマンドのメニュー（コンテナなら `start`・`stop`・`logs`・`exec`・`rm` など） |
| `s` | 並べ替えのダイアログ |
| `Delete` | 選んだものを消す（確認の枠が出る） |
| `Tab` | ダイアログの中の項目を移る |
| `Esc` | メニューや確認の枠を閉じる |
| `Ctrl+C` | 終了（`q` では終わらない） |

- F キーが端末に取られて届かないときは、`l` / `h` で画面を移る
- 並べ替えのダイアログは、`Esc` で閉じないことがある。`Tab` で `Cancel` に移って Enter を押す
- 画面での操作は API を通るので、結果はそのまま `podman ps` などにも出る

---

## 更新

1. podman-tui を更新する。

   ```bash
   sudo dnf upgrade podman-tui
   ```

   - システム全体なら `sudo dnf upgrade`
   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる
   - EPEL の podman-tui が 2.x に上がったときは、上流の互換表で podman の版と合うかを確かめる（[注意点](#注意点)）

---

## ロールバック

- 上から順に実行する
- API ソケットは止めない。ほかの手順書も使う（止めるなら [podman.md のロールバック](podman.md#ロールバック)の手順 4）

1. 確認用のコンテナを消す。

   ```bash
   podman rm -f podman-tui-web
   ```

   - `podman-tui-web` と出る

1. 同じイメージをほかで使っていないときだけ、イメージを消す。

   ```bash
   podman rmi registry.access.redhat.com/ubi10/httpd-24:latest
   ```

   - 同じイメージを使うもの: [podman.md の Quadlet](podman.md#quadlet-で自動起動する任意)、[podman-compose](podman-compose.md)、[lazydocker](lazydocker.md)
   - 使っているコンテナが残っていると、消せずにエラーになる

1. podman-tui を消す。

   ```bash
   sudo dnf remove podman-tui
   ```

   - `[y/N]` で聞かれる。消えるのは `podman-tui` の 1 パッケージだけ
   - **EPEL 自体は消さない**（ほかのパッケージが使っている可能性がある）。消すなら [epel.md のロールバック](epel.md#ロールバック)
   - podman-tui はホームにファイルを作らなかったので、ほかに消すものは無い（検証の実測）

---

## 補足

### 対象と検証環境

- **目的**: podman のコンテナ・pod・イメージ・ボリューム・ネットワーク・シークレットを、端末の画面（TUI）で見て操作できるようにする
- **進め方**: EPEL（前提の [epel.md](epel.md) で有効にする）の podman-tui 1.10.0 を入れ、podman の API ソケットにつないで、確認用のコンテナを画面から止める。**読者が書き換える変数は無い**
- **状態**: **x86_64 のコンテナでのみ検証済み（2026-09-28）。実機では本実行していない**
  - 下表の検証コンテナで、[podman.md](podman.md) の実施手順を通したうえで、**この文書のコードブロックをそのまま端末に貼って**、EPEL の有効化（今の [epel.md](epel.md) の手順 1〜3。当時はこの文書の手順だった）、手順 1〜5、[更新](#更新)、[ロールバック](#ロールバック)を通した
  - 確認したこと:
    - EPEL の podman-tui 1.10.0 が 1 パッケージで入り、podman 5.8.2 の API ソケットに `STATUS_OK` でつながる
    - 画面のメニューの `stop` でコンテナが止まり、`podman ps` にも `Exited (0)` で出る
    - [使い方の基本](#使い方の基本)の表のキー
    - Homebrew の 2.0.0 と、API ソケットが止まっているときの画面（[注意点](#注意点)）
  - **確認していないこと**: 色や罫線の見た目、デスクトップの端末での F キー、SELinux が有効なとき、SSH でほかのホストの podman につなぐこと
  - aarch64（Raspberry Pi 5）では通していない

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-28 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2` を、x86_64 の実機の rootless の podman 5.8.2 で `--privileged` にして起動。systemd が PID 1） |
| podman | 未確認 | `podman-5.8.2-9.el10_2.alma.1`（[podman.md](podman.md) の実施手順で導入。入れ子の rootless） |
| EPEL | 未確認 | 未設定 → [epel.md](epel.md) の手順 2 で `epel-release-10-6.el10` を導入 |
| podman-tui | 未導入 | `podman-tui-1.10.0-1.el10_2`（epel） |
| 端末 | — | 160 桁 × 50 行の擬似端末（`TERM=xterm-256color`、`LANG=C.UTF-8`）の SSH のログインシェル |

- 実機の列は、この手順を適用した結果ではない

> [!NOTE]
> 出力例の値は `<USER>` / `<UID>` / `<HOSTNAME>` のプレースホルダで書いてある。バージョン（`1.10.0`・`5.8.2`）とイメージの大きさは実行日によって変わる。**鍵の fingerprint は公開情報なので本文に書いてある。**

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（[podman.md](podman.md) の実施手順の後）の状態:

| 項目 | 状態 |
|---|---|
| podman | 5.8.2（rootless で `true`）。API ソケットは `active` |
| EPEL | 未設定（`EPEL は未設定`） |
| podman-tui | 未導入 |
| podman の接続（`podman system connection list`） | 無し |

### 選択した方針

| 選択肢 | 採否 |
|---|---|
| **EPEL の podman-tui（1.10.0）** | **採用。** 上流の互換表で、1.x は podman 5.x 向け（AlmaLinux 10 は 5.8.2）。システムの podman と組んで使うので RPM にした（[ツール一覧の選び方](tool-catalog.md#選び方)の規則 3）。`dnf upgrade` で上がる |
| Homebrew の podman-tui（2.0.0） | 不採用。上流の互換表で、2.x は podman 6.x 向け。接続を podman の設定からだけ読むので、podman.md を通しただけの PC では `❌ DISCONNECTED` で、接続が 0 件だった（[注意点](#注意点)） |
| GitHub のリリースの実行ファイル | 不採用。`dnf upgrade` に乗らない |
| [lazydocker](lazydocker.md) | 別の手順書。Docker の API（`DOCKER_HOST`）でつなぐので、pod とシークレットの画面は無い。ログと CPU の使用率は見やすい |
| GUI（Pods・Podman Desktop・Cockpit） | 対象外。[ツール一覧](tool-catalog.md#コンテナ)にある |

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

### 注意点

- **終了は `Ctrl+C`**: `q` を押しても何も起きない
- **API ソケットが止まっていると、つながらない**: `❌ STATUS_ERROR` とエラーの枠が出る（手順 4 の補足）。`systemctl --user start podman.socket` で直る
- **podman に接続を登録していると、そちらを使う**: `podman system connection add` で登録した接続があると、podman-tui は `localhost` の代わりにそれを出す
  - 検証では、`local` の名前で登録した接続が `✅ connected` で出た
  - 接続を消す（`podman system connection remove`）と、`localhost` に戻る
- **Homebrew の 2.x と二重に入れない**: `brew install podman-tui` の 2.0.0 は `/home/linuxbrew/.linuxbrew/bin` に入り、PATH の先頭で `/usr/bin/podman-tui` を隠す
  - 2.0.0 は接続を podman の設定からだけ読む。podman.md を通しただけの PC では、接続が 0 件（`SYSTEM CONNECTIONS[0]`）だった
  - `podman system connection add` で接続を登録すると、2.0.0 も podman 5.8.2 に `STATUS_OK` でつながり、一覧と `start` はできた。ただし上流の互換表の外の組み合わせ
- **EPEL が 2.x に上がったら、互換表を確かめる**: 2.x は podman 6 向け。AlmaLinux の podman が 5.x のうちに EPEL だけが上がったら、動きを確かめてから使う

### 参照

- [containers/podman-tui — README（v1.10.0）](https://github.com/containers/podman-tui/blob/v1.10.0/docs/README.md) — 互換表、API ソケットの前提、キーの一覧
- [podman-tui v2.0.0 のリリースノート](https://github.com/containers/podman-tui/releases/tag/v2.0.0) — podman v6 への対応、接続を podman の設定からだけ読むこと
- `podman-tui --help`、画面の `F1`
- [Podman](podman.md) — 前提の rootless の podman と API ソケット
- [EPEL](epel.md) — 前提の EPEL の有効化

---

### 付録: コンテナでの検証記録（2026-09-28）

**環境**: x86_64 の実機（AlmaLinux 10.2 のノート PC、SELinux は Enforcing）の、rootless の podman 5.8.2 の上の使い捨てのコンテナ。

- 実機の設定は変えていない（`sudo` は使わず、終わった後にコンテナ・ボリューム・イメージを消した）
- イメージは `quay.io/almalinuxorg/10-init:10.2`（`sha256:a91c1066…fd73`、[podman.md の付録](podman.md#付録-コンテナでの検証記録2026-09-27)と同じ）
- `--privileged`・`--systemd=always` で立て、systemd を PID 1 にした。`/home` には名前付きのボリュームを付けた

**手順書の外で行った準備**（検証環境の都合）:

- `/` を shared にし、`10-init` のイメージが mask している `systemd-logind` を戻した
- `openssh-server` と `sudo` を入れ、`<USER>`（NOPASSWD の sudo）を作った
- **subuid / subgid**: 外側のコンテナに割り当てられた UID は 65537 個（0〜65536）しか無いので、`<USER>:1:999` と `<USER>:1001:64535` にした（`quay.io/podman/stable` と同じ割り当て）
  - そのため、[podman.md 手順 3](podman.md#実施手順) の出力は 2 行ではなく 4 行になった
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

- [使い方の基本](#使い方の基本)の表のキーを 1 つずつ押した。`s` の並べ替えのダイアログは、項目にいるうちは `Esc` で閉じず、`Tab` で `Cancel` に移って Enter で閉じた
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
