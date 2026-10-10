# lazydocker インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- [検証記録](verification/lazydocker.md)・[参考資料](reference/lazydocker.md)・[ロールバックと注意点](extra/lazydocker.md)

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **前提**: [AlmaLinux 10 の初期設定の手順 46〜48](almalinux-setup.md#実施手順)（Homebrew）と、[Podman](podman.md) の実施手順（手順 7 の API ソケットまで）と [Docker 向けのツールから使う（任意）](podman.md#docker-向けのツールから使う任意)の節を通してあること。`command -v brew podman` が 2 行を返し、`echo "${DOCKER_HOST}"` が `unix:///run/user/<UID>/podman/podman.sock` を返さなければ、先に通す
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、lazydocker も自分のユーザーの API ソケットにつなぐため）
> - **手順 4 で lazydocker の画面（TUI）が開く**。`q` で終了してから手順 5 を貼る

- 上から順にコードブロックを貼る
- 手順の後:
  - 画面からコンテナのシェルを開くなら[podman exec でシェルを開く（任意）](#podman-exec-でシェルを開く任意)、compose のサービスを見るなら[compose のプロジェクトを見る（任意）](#compose-のプロジェクトを見る任意)
  - root のコンテナ（`sudo podman` で動かしたもの）も見るなら[root でも使う（任意）](#root-でも使う任意)
  - 日々の操作は[使い方の基本](#使い方の基本)、以後は[更新](#更新)・[ロールバック](extra/lazydocker.md#ロールバック)
- pod やシークレットも画面で扱うなら [podman-tui](podman-tui.md)（違いは[選択した方針](verification/lazydocker.md#選択した方針)）

1. brew で lazydocker を入れる。

   ```bash
   brew install lazydocker
   ```

   - **次の手順は、確認が出たら答え、インストールが終わってシェルのプロンプトに戻ってから貼る**（依存の追加を確認する `[y/n]` が出る版では、続けて貼ると回答として食われる）

1. lazydocker が入ったことと、つなぐ先を確かめる。

   ```bash
   lazydocker --version
   command -v lazydocker
   echo "${DOCKER_HOST}"
   curl -s --unix-socket "${DOCKER_HOST#unix://}" http://d/_ping; echo
   ```

   - 1 行目で `Version: 0.25.2` と `BuildSource: Homebrew` が出る
   - `/home/linuxbrew/.linuxbrew/bin/lazydocker` が出る
   - `unix:///run/user/<UID>/podman/podman.sock` と `OK` が出れば、lazydocker は podman の API ソケットにつなぐ
   - 3 行目が空なら、`DOCKER_HOST` が無い。[podman.md の Docker 向けの節](podman.md#docker-向けのツールから使う任意)を通す（参考資料を参照）

1. 画面で操作する、確認用のコンテナを動かす。

   ```bash
   podman run -d --name lazydocker-web --label name=lazydocker-web registry.access.redhat.com/ubi10/httpd-24:latest
   podman ps --filter name=lazydocker-web --format '{{.Names}} {{.Status}}'
   ```

   - `lazydocker-web Up Less than a second` のように出る

1. lazydocker を起動し、確認用のコンテナを画面から止める。

   ```bash
   lazydocker
   ```

   - 左に `[3]─Containers`・`[4]─Images`・`[5]─Volumes`・`[6]─Networks`、右に `Logs - Stats - Env - Config - Top` の枠が出る
   - ↑↓ で `running` の `lazydocker-web` の行を選ぶと、右の枠に Apache のログ（`... configured -- resuming normal operations` など）が出る
   - `s` を押し、`Are you sure you want to stop this container?` に `y` と答える
   - 行が `exited (0)` に変わる
   - `q` で終了する
   - **次の手順は、`q` で終了してから貼る**（続けて貼ると lazydocker への操作として食われる）

1. 確認用のコンテナが止まったことと、設定ファイルができたことを確かめる。

   ```bash
   podman ps -a --filter name=lazydocker-web --format '{{.Names}} {{.Status}}'
   ls -l ~/.config/lazydocker
   ```

   - `lazydocker-web Exited (0) ...` と出ればよい
   - `config.yml`（0 バイト）がある

---

## podman exec でシェルを開く（任意）

- lazydocker の `E`（シェルを開く）と `a`（アタッチ）は、`docker` コマンドを直接呼ぶ。podman だけの PC では、`+ docker exec -it ...` と出るだけで何も起きない（[注意点](extra/lazydocker.md#注意点)）
- この節で、`c`（自分で足したコマンドのメニュー）に、`podman exec` でシェルを開くコマンドを足す

1. [手順 4](#実施手順) で止めた確認用のコンテナを、起動し直す。

   ```bash
   podman start lazydocker-web
   ```

   - `lazydocker-web` と出る

1. `podman exec` でシェルを開くコマンドを、設定ファイルに足す。

   ```bash
   cat >> ~/.config/lazydocker/config.yml <<'EOF'
   customCommands:
     containers:
       - name: podman exec sh
         attach: true
         command: 'podman exec -it {{ .Container.ID }} sh'
   EOF
   cat ~/.config/lazydocker/config.yml
   ```

   - 読み戻した中身に、足した 5 行が出る
   - **注意**: 既に `customCommands:` があるなら、`cat >>` で足さずに手で中身をまとめる。同じキーが 2 つあると、後ろのものだけが使われ、前の定義は黙って無視される（参考資料を参照）

1. lazydocker を起動し、足したコマンドでコンテナのシェルを開く。

   ```bash
   lazydocker
   ```

   - `running` の `lazydocker-web` の行を選び、`c` を押す
   - `Custom Command:` の枠の `podman exec sh` で Enter を押すと、`sh-5.2$` のプロンプトになる
   - `id` を打つと `uid=1001(default) gid=0(root) groups=0(root)` と出る
   - `exit` で抜け、`Press enter to return to lazydocker ...` で Enter を押すと画面に戻る
   - `q` で終了する
   - **後ろの節の手順は、`q` で終了してから貼る**（続けて貼ると lazydocker への操作として食われる）

---

## compose のプロジェクトを見る（任意）

- 前提: [podman-compose](podman-compose.md) の実施手順を手順 4 まで通し、`~/compose-sample` のコンテナが動いていること
- lazydocker は、起動したディレクトリで `docker compose config --quiet` が通ったときだけ、`[1]─Project` と `[2]─Services` の枠を出す
- podman だけの PC では通らないので、この節で compose のコマンドを `podman-compose` に替える

1. compose のコマンドを `podman-compose` にする設定を、設定ファイルに足す。

   ```bash
   cat >> ~/.config/lazydocker/config.yml <<'EOF'
   commandTemplates:
     dockerCompose: podman-compose
   EOF
   cat ~/.config/lazydocker/config.yml
   ```

   - 読み戻した中身に、足した 2 行が出る
   - **注意**: 既に `commandTemplates:` があるなら、`cat >>` で足さずに手で中身をまとめる

1. compose ファイルのあるディレクトリで lazydocker を起動し、`web` のサービスを再起動する。

   ```bash
   cd ~/compose-sample
   lazydocker
   ```

   - 左の上に `[1]─Project`（`compose-sample`）と `[2]─Services`（`check`・`web`）の枠が出る
   - 確認用のコンテナなど compose の外のものは、`[3]─Standalone Containers` に移る
   - `web` の行を選ぶと、右の枠に Apache のログが出る
   - `r` を押すと、確認なしに `web` が再起動する
   - `q` で終了する
   - **次の手順は、`q` で終了してから貼る**（続けて貼ると lazydocker への操作として食われる）

1. `web` だけが再起動したことを確かめる。

   ```bash
   cd ~/compose-sample
   podman-compose ps --format '{{.Names}} {{.Status}}'
   ```

   - `compose-sample_web_1 Up 15 seconds` のように、`web` の動いている時間が `check` より短ければよい

---

## root でも使う（任意）

- **root のコンテナを lazydocker で見ないなら、この節は不要**
- `sudo podman` で動かした root のコンテナは、自分のユーザーのコンテナと保管場所（`/var/lib/containers`）が別で、[手順 4](#実施手順) の画面には出ない（[podman.md の注意点](extra/podman.md#注意点)。root で動かすのは[例外](verification/podman.md#選択した方針)）
- この節で、システムの podman の API ソケット（`/run/podman/podman.sock`）を有効にする
- root の共通設定が、システムのソケットを指す `DOCKER_HOST` を入れる。`/root/.bashrc` には追記しない
- 起動は `sudo -i lazydocker`。`su -`・`sudo -i`・`sudo -s` で開いた root のシェルでは `lazydocker`
- `-i` の無い `sudo lazydocker` は root の `~/.bashrc` を読まないので、root のコンテナにつながらない（[root で使うときの補足](reference/lazydocker.md#root-で使うときの補足)）
- 前提: root 自身にも [bash の共通設定](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#root-のシェルでも読む任意)を導入すること
  - この設定が Homebrew の PATH と root 用の `DOCKER_HOST` を読む。sudo の `secure_path` だけではこの節の前提を満たさない
  - `sudo -i bash -c 'command -v lazydocker'` が `/home/linuxbrew/.linuxbrew/bin/lazydocker` を返せばよい
- この節の手順 4 で lazydocker の画面（TUI）が開く
- [手順 1〜5](#実施手順) を終えた、自分のユーザーのシェルで貼る
- 補足: [root で使うときの補足](reference/lazydocker.md#root-で使うときの補足)

> [!WARNING]
> - root の lazydocker は、Homebrew を入れたユーザーが書き換えられるプログラムを、root の権限で動かす（[AlmaLinux 10 の初期設定の Homebrew を root のシェルでも使う](almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節の導入条件と同じ）
> - システムの API ソケットにつなげるのは root だけ。権限を緩めない（つなげると、root と同じことができる）

1. システムの podman の API ソケットを有効にして、root で応答を確かめる。

   ```bash
   {
     sudo systemctl enable --now podman.socket
     systemctl is-active podman.socket
     sudo curl -s --unix-socket /run/podman/podman.sock http://d/_ping; echo
     sudo podman --remote version --format '{{.Server.Version}}'
   }
   ```

   - `active`・`OK`・`5.8.2` が出ればよい
   - `Created symlink …` が出なければ、前から有効だった。元に戻すときは、この節の手順 8 を飛ばす

1. root の共通設定が接続先を設定したことを確かめる。

   ```bash
   sudo -i bash -c 'printenv DOCKER_HOST; command -v lazydocker'
   ```

   - `unix:///run/podman/podman.sock` と `/home/linuxbrew/.linuxbrew/bin/lazydocker` が出ればよい
   - root 自身の [共通設定](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#root-のシェルでも読む任意)を先に導入する。`/root/.bashrc` への `DOCKER_HOST` の追記は不要
   - 接続先が違う場合はここで止め、既存の用途を確認する

1. 確認用のコンテナを root で動かす。

   ```bash
   {
     sudo podman run -d --name lazydocker-root-web --label name=lazydocker-root-web registry.access.redhat.com/ubi10/httpd-24:latest
     sudo podman ps --filter name=lazydocker-root-web --format '{{.Names}} {{.Status}}'
   }
   ```

   - コンテナの ID の後に、`lazydocker-root-web Up Less than a second` のように出る

1. root で lazydocker を起動し、確認用のコンテナを止める。

   ```bash
   sudo -i lazydocker
   ```

   - `[3]─Containers` に `running  lazydocker-root-web` の行が出る。[手順 3](#実施手順) の `lazydocker-web` は出ない
   - ↑↓ で `lazydocker-root-web` の行を選び、`s` を押し、`Are you sure you want to stop this container?` に `y` と答える
   - 行が `exited (0)` に変わる
   - `q` で終了する
   - **次の手順は、`q` で終了してから貼る**（続けて貼ると lazydocker への操作として食われる）

1. 確認用のコンテナが止まったことと、root の設定ファイルができたことを確かめる。

   ```bash
   {
     sudo podman ps -a --filter name=lazydocker-root-web --format '{{.Names}} {{.Status}}'
     sudo ls -l /root/.config/lazydocker
   }
   ```

   - `lazydocker-root-web Exited (0) ...` と出ればよい
   - `config.yml`（0 バイト）は root の設定ファイル

1. 元に戻すときは、root の確認用コンテナと lazydocker の設定を消す。

   ```bash
   sudo podman rm -f lazydocker-root-web
   sudo rm -rf /root/.config/lazydocker
   ```

   - root の設定ファイルに手で足したものも消える
   - 共通設定と `~/.bashrc` は変更しない。ソケットはこの節の手順 8 で止める

1. 元に戻すときは、root でほかに使っていないときだけ、root のイメージを消す。

   ```bash
   sudo podman rmi registry.access.redhat.com/ubi10/httpd-24:latest
   ```

   - `Untagged:` と `Deleted:` が出る
   - 同じイメージの root のコンテナが残っていると、消せずにエラーになる

1. 元に戻すときは、この節の手順 1 で有効にしたときだけ、システムの API ソケットを止める。

   ```bash
   {
     sudo systemctl disable --now podman.socket
     systemctl is-active podman.socket
   }
   ```

   - `Removed …` と `inactive` が出ればよい
   - Cockpit の podman の画面など、ほかのものも、このソケットを使うことがある

---

## 使い方の基本

| キー | 動作 |
|---|---|
| `↑` / `↓` | 行を選ぶ |
| `←` / `→`、`1`〜`6` | 枠を移る（`3` が Containers、`4` が Images など） |
| `[` / `]` | 右の枠のタブ（Logs・Stats・Env・Config・Top）を移る |
| `s` | 止める（確認が出る） |
| `r` | 再起動する（確認は出ない） |
| `m` | ログを画面いっぱいに追う（`Ctrl+C` で戻る） |
| `e` | 止まったコンテナを隠す / また出す |
| `d` | 消す（`remove`・`remove with volumes`・`cancel` から選ぶ） |
| `c` | 自分で足したコマンドのメニュー（[podman exec の節](#podman-exec-でシェルを開く任意)） |
| `x` | 選んでいる枠のキーの一覧 |
| `q` | 終了 |

- `E`（シェル）と `a`（アタッチ）は `docker` コマンドを呼ぶので、podman だけの PC では何も起きない。シェルは `c` から開く
- 画面は英語で出る（lazydocker に日本語の翻訳は無い）

---

## 更新

1. lazydocker を更新する。

   ```bash
   brew upgrade lazydocker
   ```

   - 新しい版が無ければ `Warning: lazydocker 0.25.2 already installed` のように出て、何もしない
   - すべてまとめて上げるなら `brew upgrade`
