# lazydocker インストール手順（AlmaLinux 10 / Homebrew）の参考資料

[手順書](../lazydocker.md)・[ロールバックと注意点](../extra/lazydocker.md)

## 補足

### 実施手順 / 手順 1: 補足: ボトル

[この節の検証記録](../verification/lazydocker.md#実施手順--手順-1-補足-ボトル)

- aarch64 向けの `arm64_linux` のボトルもある（formulae.brew.sh の JSON で確認）
- AppStream・EPEL に RPM は無い（[ツール一覧](../tool-catalog.md)の調査）
- ビルド済みのボトルが降ってくる。依存は無い
- aarch64 でもソースからのビルドにはならない

### 実施手順 / 手順 3: 補足: --label name= を付ける理由

lazydocker は、コンテナに `name` というラベルがあると、コンテナの名前の代わりにそれを出す（上流のソースの `pkg/commands/docker.go`）。

### 実施手順 / 手順 3: 補足: イメージの取得

- 初回はイメージ（285 MB）を取得する。[podman.md の Quadlet](../podman.md#quadlet-で自動起動する任意) などで取得済みなら、取り直さない

### 実施手順 / 手順 4: 補足: 画面の中身

[この節の検証記録](../verification/lazydocker.md#実施手順--手順-4-補足-画面の中身)

- `[1]─Project` と `[2]─Services` の枠は、compose のプロジェクトのディレクトリで起動し、compose のコマンドが通ったときだけ出る（[compose のプロジェクトを見る（任意）](../lazydocker.md#compose-のプロジェクトを見る任意)）
- `s` の確認の枠の下には `n/esc: no, y/enter: yes` と出る
- `x` を押すと、選んでいる枠のキーの一覧が出る（`Esc` で閉じる）

### 実施手順 / 手順 5: 補足: 確かめたものの意味

- `lazydocker-web Exited (0) ...` と出れば、画面の操作が、API を通して podman に届いている
- `config.yml`（0 バイト）は、lazydocker が最初の起動で作った空のファイルで、中身が無ければ既定の設定で動く

### podman exec でシェルを開く（任意） / 手順 2: 補足: 足した設定と、キーが重なったとき

| 行 | 意味 |
|---|---|
| `customCommands:` → `containers:` | Containers の枠の `c` のメニューに出すコマンド |
| `name:` | メニューに出る名前 |
| `attach: true` | 画面を離れて、コマンドを端末でそのまま動かす（シェルのような対話のあるもの向け） |
| `command:` | 動かすコマンド。`{{ .Container.ID }}` は選んだコンテナの ID |

- `{{ .Container.ID }}` は、lazydocker が選んだコンテナの ID に置き換える（シェルの変数ではない）

### podman exec でシェルを開く（任意） / 手順 3: 補足: コンテナのユーザー

- `id` の `uid=1001(default) gid=0(root) groups=0(root)` は、Apache のコンテナのユーザー

### compose のプロジェクトを見る（任意） / 手順 1: 補足: 替わるコマンド

`dockerCompose` は、lazydocker が compose を操作するときのコマンドの頭の部分。サービスの再起動（`restartService`）などの既定のコマンドは、どれもこれを使う（`lazydocker --config` で既定の設定の全体が出る）。

### compose のプロジェクトを見る（任意） / 手順 1: 補足: キーが重なったとき

- 既に `commandTemplates:` があるときに `cat >>` で足さないのは、[podman exec の節](../lazydocker.md#podman-exec-でシェルを開く任意)の手順 2 と同じ理由

### root でも使う（任意） / 手順 1: 補足: システムの API ソケット

システムの `podman.socket` の中身（`systemctl cat podman.socket` の抜粋）:

```
[Socket]
ListenStream=%t/podman/podman.sock
SocketMode=0660
```

- `%t` はシステムでは `/run` なので、ソケットは `/run/podman/podman.sock`。持ち主は root で `srw-rw----`、つなげるのは root だけ
- 要求が来たときだけ、root の `podman.service`（`podman system service`）が起動し、要求が途切れると自分から終わる
- `sudo podman --remote` は、指定が無ければこのソケットにつなぐ
- この節の手順 8 で止めた後も、ソケットのファイルは再起動まで残る。つなごうとすると失敗する（`curl` は終了コード 7）
- 自分のユーザーのソケット（[podman.md 手順 7](../podman.md#実施手順) の `systemctl --user`）とは別のソケット

### root でも使う（任意） / 手順 3: 補足: 確認用のコンテナ

- root の保管場所に、イメージ（285 MB）を取得する。自分のユーザーで取得したイメージは使われない
- 名前を[実施手順](../lazydocker.md#実施手順)の手順 3 の `lazydocker-web` と分けて、どちらのコンテナの画面かを見分ける

### root でも使う（任意） / 手順 4: 補足: 画面の中身

[この節の検証記録](../verification/lazydocker.md#root-でも使う任意--手順-4-補足-画面の中身)

- 出るのは root のコンテナとイメージだけ。[手順 3](../lazydocker.md#実施手順) の `lazydocker-web` と、自分のユーザーの `quay.io/podman/hello` は出ない
- `-i` を付けずに `sudo lazydocker` と打つと（[AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通したホスト）、`Error` の枠に次が出て、枠は空のまま:

```
Docker event stream returned error: Cannot connect to the Docker daemon at
unix:///var/run/docker.sock. Is the docker daemon running?
Retry count: 3
```

### root でも使う（任意） / 手順 5: 補足: root の設定ファイル

- 自分の `~/.config/lazydocker` の設定（任意節で足したもの）は、root では使われない

### root でも使う（任意） / 手順 6: 補足: ソケットのファイルが残る間

- ソケットのファイルが再起動まで残る間は、共通設定が `DOCKER_HOST` を入れる

### root で使うときの補足

| 入口 | `DOCKER_HOST` | 画面に出るもの |
|---|---|---|
| `sudo -i lazydocker`、`sudo -i`・`su -`・`sudo -s` で開いた root のシェルの `lazydocker` | `/root/.bashrc` の `unix:///run/podman/podman.sock` | root のコンテナ |
| `sudo lazydocker` | 無い（`sudo` が消す） | 何も出ない。`Cannot connect to the Docker daemon at unix:///var/run/docker.sock`（その節の手順 4 の補足） |
| `sudo -E lazydocker` | 自分の `unix:///run/user/<UID>/podman/podman.sock` | 自分のコンテナ（root が自分のソケットにつなぐ） |
| `sudo DOCKER_HOST=unix:///run/podman/podman.sock lazydocker` | 打った値 | root のコンテナ |

### 参照

- [jesseduffield/lazydocker — README](https://github.com/jesseduffield/lazydocker) — 機能と、各 OS への導入
- [lazydocker — Config.md](https://github.com/jesseduffield/lazydocker/blob/master/docs/Config.md) — `customCommands`・`commandTemplates` の書き方、設定ファイルの場所（Linux は `~/.config/lazydocker/config.yml`）
- [lazydocker — Keybindings](https://github.com/jesseduffield/lazydocker/blob/master/docs/keybindings/Keybindings_en.md) — 枠ごとのキー
- `lazydocker --config` — 既定の設定の全体
- [AlmaLinux 10 の初期設定](../almalinux-setup.md)（手順 46〜48 の Homebrew） / [Podman](../podman.md) / [podman-compose](../podman-compose.md) — 前提の手順書
- [podman-system-service(1)](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html) — root の API ソケット（`unix:///run/podman/podman.sock`）
- `man sudo`（`-i`）・`man sudoers`（`env_reset`・`env_keep`） — [root でも使う](../lazydocker.md#root-でも使う任意)の節で、`-i` の無い `sudo` に `DOCKER_HOST` が渡らない理由

---
