# podman-tui インストール手順（AlmaLinux 10 / EPEL）

## 実施手順

- [検証記録](verification/podman-tui.md)・[参考資料](reference/podman-tui.md)

> [!IMPORTANT]
> - **前提**: [Podman](podman.md) の実施手順（手順 7 の API ソケットまで）と、[AlmaLinux 10 の初期設定の手順 17](almalinux-setup.md#実施手順)（EPEL）を通してあること（podman-tui は EPEL にあり、AppStream には無い）。`systemctl --user is-active podman.socket` が `active` を返さないか、`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（podman-tui は、自分のユーザーの API ソケットにつなぐため）
> - **手順 1 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）。答えてから手順 2 を貼る
> - **手順 4 で podman-tui の画面（TUI）が開く**。`Ctrl+C` で終了してから手順 5 を貼る（`q` では終わらない）

- 上から順にコードブロックを貼る
- 手順の後: 日々の操作は[使い方の基本](#使い方の基本)、以後は[更新](#更新)・[ロールバック](#ロールバック)
- Docker の API でつなぐ TUI なら [lazydocker](lazydocker.md)（違いは[選択した方針](verification/podman-tui.md#選択した方針)）

1. 入手できる版を見てから、podman-tui を入れる。

   ```bash
   dnf -q list --showduplicates podman-tui
   sudo dnf install podman-tui
   ```

   - 版は `podman-tui.x86_64  1.10.0-1.el10_2  epel` のように 1 つだけ出る
   - 入るのは `podman-tui` の 1 パッケージだけ（ダウンロード 9.5 MB、展開後 32 MB）
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y` と答える。違っていれば `N` で中断する
   - [AlmaLinux 10 の初期設定の手順 17](almalinux-setup.md#実施手順) に書いた鍵
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

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
- API ソケットは止めない。ほかの手順書も使う（止めるなら [podman.md のロールバック](podman.md#ロールバック)の手順 3）

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
   - **EPEL 自体は消さない**（ほかのパッケージが使っている可能性がある）。消すなら [AlmaLinux 10 の初期設定のロールバック](almalinux-setup.md#ロールバック)の手順 34・35

---

## 注意点

- **終了は `Ctrl+C`**: `q` を押しても何も起きない
- **API ソケットが止まっていると、つながらない**: `❌ STATUS_ERROR` とエラーの枠が出る（参考資料を参照）。`systemctl --user start podman.socket` で直る
- **podman に接続を登録していると、そちらを使う**: `podman system connection add` で登録した接続があると、podman-tui は `localhost` の代わりにそれを出す
  - 接続を消す（`podman system connection remove`）と、`localhost` に戻る
- **Homebrew の 2.x と二重に入れない**: `brew install podman-tui` の 2.0.0 は `/home/linuxbrew/.linuxbrew/bin` に入り、PATH の先頭で `/usr/bin/podman-tui` を隠す
  - 2.0.0 は接続を podman の設定からだけ読むため、使う場合は先に接続を登録する
  - 2.0.0 と podman 5.8.2 は上流の互換表の外の組み合わせなので、互換表に合う版を選ぶ
- **EPEL が 2.x に上がったら、互換表を確かめる**: 2.x は podman 6 向け。AlmaLinux の podman が 5.x のうちに EPEL だけが上がったら、動きを確かめてから使う
