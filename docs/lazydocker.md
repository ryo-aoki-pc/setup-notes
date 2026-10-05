# lazydocker インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) と、[Podman](podman.md) の実施手順（手順 7 の API ソケットまで）と [Docker 向けのツールから使う（任意）](podman.md#docker-向けのツールから使う任意)の節を通してあること。`command -v brew podman` が 2 行を返し、`echo "${DOCKER_HOST}"` が `unix:///run/user/<UID>/podman/podman.sock` を返さなければ、先に通す
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew は root で動かず、lazydocker も自分のユーザーの API ソケットにつなぐため）
> - **手順 4 で lazydocker の画面（TUI）が開く**。`q` で終了してから手順 5 を貼る

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後:
  - 画面からコンテナのシェルを開くなら[podman exec でシェルを開く（任意）](#podman-exec-でシェルを開く任意)、compose のサービスを見るなら[compose のプロジェクトを見る（任意）](#compose-のプロジェクトを見る任意)
  - root のコンテナ（`sudo podman` で動かしたもの）も見るなら[root でも使う（任意）](#root-でも使う任意)
  - 日々の操作は[使い方の基本](#使い方の基本)、以後は[更新](#更新)・[ロールバック](#ロールバック)
- pod やシークレットも画面で扱うなら [podman-tui](podman-tui.md)（違いは[選択した方針](#選択した方針)）

> [!WARNING]
> **x86_64 のコンテナでのみ検証した手順書**で、実機では本実行していない。画面は、表示された文字を読み取り、キーを送って確かめた（[対象と検証環境](#対象と検証環境)）。

1. brew で lazydocker を入れる。

   ```bash
   brew install lazydocker
   ```

   - ビルド済みのボトルが降ってくる。依存は無い
   - aarch64 でもソースからのビルドにはならない

   <details>
   <summary>補足: ボトル</summary>

   x86_64 で降ってきたボトルは `lazydocker--0.25.2.x86_64_linux.bottle.tar.gz`（5.0 MB）。

   ```
   ==> Pouring lazydocker--0.25.2.x86_64_linux.bottle.tar.gz
   🍺  /home/linuxbrew/.linuxbrew/Cellar/lazydocker/0.25.2: 6 files, 13.2MB
   ```

   - aarch64 向けの `arm64_linux` のボトルもある（formulae.brew.sh の JSON で確認）
   - AppStream・EPEL に RPM は無い（[ツール一覧](tool-catalog.md)の調査）

   </details>

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
   - 3 行目が空なら、`DOCKER_HOST` が無い。[podman.md の Docker 向けの節](podman.md#docker-向けのツールから使う任意)を通す（この手順の補足）

   <details>
   <summary>補足: <code>DOCKER_HOST</code> が無いとき</summary>

   lazydocker は `DOCKER_HOST` を読み、無ければ Docker の既定のソケット（`/var/run/docker.sock`）につなごうとする。`DOCKER_HOST` を外して起動したときの、画面の `Error` の枠（実測）:

   ```
   Docker event stream returned error: Cannot connect to the Docker daemon at
   unix:///var/run/docker.sock. Is the docker daemon running?
   Retry count: 26
   ```

   - 起動はするが、枠は空のまま。`Retry count` は増え続け、`Esc` でも消えない。`q` で終わる
   - API ソケットが止まっているときも、同じ文言で `unix:///run/user/<UID>/podman/podman.sock` と出る。`systemctl --user start podman.socket` で直る

   </details>

1. 画面で操作する、確認用のコンテナを動かす。

   ```bash
   podman run -d --name lazydocker-web --label name=lazydocker-web registry.access.redhat.com/ubi10/httpd-24:latest
   podman ps --filter name=lazydocker-web --format '{{.Names}} {{.Status}}'
   ```

   - `lazydocker-web Up Less than a second` のように出る
   - 初回はイメージ（285 MB）を取得する。[podman.md の Quadlet](podman.md#quadlet-で自動起動する任意) などで取得済みなら、取り直さない
   - `--label name=lazydocker-web` は、lazydocker の画面にこの名前で出すため（この手順の補足）

   <details>
   <summary>補足: <code>--label name=</code> を付ける理由</summary>

   lazydocker は、コンテナに `name` というラベルがあると、コンテナの名前の代わりにそれを出す（上流のソースの `pkg/commands/docker.go`）。

   - Red Hat の UBI のイメージには `name=ubi10/httpd-24` のようなラベルが付いていて、コンテナはそれを受け継ぐ
   - 付けずに動かすと、同じイメージのコンテナ（Quadlet の `hello-web`、compose の `web`・`check` など）がどれも `ubi10/httpd-24` の名前で並ぶ
   - 検証では、止めた後に並びが入れ替わり、`r` で意図しない方のコンテナを再起動した
   - `--label name=<名前>` で上書きすると、その名前で出た

   </details>

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

   <details>
   <summary>補足: 画面の中身</summary>

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

   - `[1]─Project` と `[2]─Services` の枠は、compose のプロジェクトのディレクトリで起動し、compose のコマンドが通ったときだけ出る（[compose のプロジェクトを見る（任意）](#compose-のプロジェクトを見る任意)）
   - `s` の確認の枠の下には `n/esc: no, y/enter: yes` と出る
   - `x` を押すと、選んでいる枠のキーの一覧が出る（`Esc` で閉じる）

   </details>

1. 確認用のコンテナが止まったことと、設定ファイルができたことを確かめる。

   ```bash
   podman ps -a --filter name=lazydocker-web --format '{{.Names}} {{.Status}}'
   ls -l ~/.config/lazydocker
   ```

   - `lazydocker-web Exited (0) ...` と出ればよい。画面の操作が、API を通して podman に届いている
   - `config.yml`（0 バイト）がある。lazydocker が最初の起動で作った空のファイルで、中身が無ければ既定の設定で動く

---

## podman exec でシェルを開く（任意）

- lazydocker の `E`（シェルを開く）と `a`（アタッチ）は、`docker` コマンドを直接呼ぶ。podman だけの PC では、`+ docker exec -it ...` と出るだけで何も起きない（[注意点](#注意点)）
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
   - `{{ .Container.ID }}` は、lazydocker が選んだコンテナの ID に置き換える（シェルの変数ではない）
   - **注意**: 既に `customCommands:` があるなら、`cat >>` で足さずに手で中身をまとめる。同じキーが 2 つあると、後ろのものだけが使われ、前の定義は黙って無視される（この手順の補足）

   <details>
   <summary>補足: 足した設定と、キーが重なったとき</summary>

   | 行 | 意味 |
   |---|---|
   | `customCommands:` → `containers:` | Containers の枠の `c` のメニューに出すコマンド |
   | `name:` | メニューに出る名前 |
   | `attach: true` | 画面を離れて、コマンドを端末でそのまま動かす（シェルのような対話のあるもの向け） |
   | `command:` | 動かすコマンド。`{{ .Container.ID }}` は選んだコンテナの ID |

   - `sh` にしたのは、`bash` の無いイメージでも動くようにするため。UBI のイメージでは `sh-5.2$` と出る
   - 検証で、`customCommands:` を 2 回書いた設定を読ませた。エラーにならずに起動し、前に書いた `first entry` がメニューから消え、後ろに書いた `podman exec sh` だけが出た

   </details>

1. lazydocker を起動し、足したコマンドでコンテナのシェルを開く。

   ```bash
   lazydocker
   ```

   - `running` の `lazydocker-web` の行を選び、`c` を押す
   - `Custom Command:` の枠の `podman exec sh` で Enter を押すと、`sh-5.2$` のプロンプトになる
   - `id` を打つと `uid=1001(default) gid=0(root) groups=0(root)` と出る（Apache のコンテナのユーザー）
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
   - **注意**: 既に `commandTemplates:` があるなら、`cat >>` で足さずに手で中身をまとめる（[podman exec の節](#podman-exec-でシェルを開く任意)の手順 2 と同じ理由）

   <details>
   <summary>補足: 替わるコマンド</summary>

   `dockerCompose` は、lazydocker が compose を操作するときのコマンドの頭の部分。サービスの再起動（`restartService`）などの既定のコマンドは、どれもこれを使う（`lazydocker --config` で既定の設定の全体が出る）。

   - compose のプロジェクトかどうかは、起動のときに `podman-compose config --quiet` の終了コードで決まる
   - `~/compose-sample` では終了コード 0、compose ファイルの無いホームでは `CRITICAL:podman_compose:no compose.yaml, docker-compose.yml or container-compose.yml file found, pass files with -f` と出て 255 だった
   - compose ファイルの無いディレクトリで起動すると、Project と Services の枠が出ないだけで、ほかは変わらない

   </details>

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
- `sudo podman` で動かした root のコンテナは、自分のユーザーのコンテナと保管場所（`/var/lib/containers`）が別で、[手順 4](#実施手順) の画面には出ない（[podman.md の注意点](podman.md#注意点)。root で動かすのは[例外](podman.md#選択した方針)）
- この節で、システムの podman の API ソケット（`/run/podman/podman.sock`）を有効にする
- root の `~/.bashrc`（`/root/.bashrc`）に、そこを指す `DOCKER_HOST` を書く（自分の `~/.bashrc` の [Docker 向けの節](podman.md#docker-向けのツールから使う任意)と同じ形）
- 起動は `sudo -i lazydocker`。`su -`・`sudo -i`・`sudo -s` で開いた root のシェルでは `lazydocker`
- `-i` の無い `sudo lazydocker` は root の `~/.bashrc` を読まないので、root のコンテナにつながらない（[root で使うときの補足](#root-で使うときの補足)）
- 前提: Homebrew の lazydocker が、root の PATH にあること
  - [homebrew.md の root のシェルでも使う](homebrew.md#root-のシェルでも使う任意)か[sudo でも使う](homebrew.md#sudo-でも使う任意)の節を通す（`su -` でも使うなら root のシェルの節）
  - `sudo -i bash -c 'command -v lazydocker'` が `/home/linuxbrew/.linuxbrew/bin/lazydocker` を返せばよい
- この節の手順 4 で lazydocker の画面（TUI）が開く
- [手順 1〜5](#実施手順) を終えた、自分のユーザーのシェルで貼る
- 補足: [root で使うときの補足](#root-で使うときの補足)

> [!WARNING]
> - root の lazydocker は、Homebrew を入れたユーザーが書き換えられるプログラムを、root の権限で動かす（[homebrew.md の root のシェルでも使う](homebrew.md#root-のシェルでも使う任意)の節の WARNING と同じ）
> - システムの API ソケットにつなげるのは root だけ。権限を緩めない（つなげると、root と同じことができる）
> - この節の検証の範囲は[付録](#付録-root-でも使う節のコンテナでの検証記録2026-10-05)

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
   - 自分のユーザーのソケット（[podman.md 手順 7](podman.md#実施手順) の `systemctl --user`）とは別のソケット
   - `Created symlink …` が出なければ、前から有効だった。元に戻すときは、この節の手順 8 を飛ばす

   <details>
   <summary>補足: システムの API ソケット</summary>

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

   </details>

1. root の `~/.bashrc` の末尾に `DOCKER_HOST` を書き、root のログインシェルで確かめる。

   ```bash
   {
     if sudo grep -q DOCKER_HOST /root/.bashrc; then echo '中断: /root/.bashrc に DOCKER_HOST が既にある' >&2
     else
       sudo tee -a /root/.bashrc >/dev/null <<'EOF'
   export DOCKER_HOST=unix:///run/podman/podman.sock
   EOF
       sudo tail -n 1 /root/.bashrc
     fi
     sudo -i bash -c 'printenv DOCKER_HOST; command -v lazydocker'
   }
   ```

   - 書いた 1 行（`export DOCKER_HOST=unix:///run/podman/podman.sock`）が出る
   - 最後の 2 行が `unix:///run/podman/podman.sock` と `/home/linuxbrew/.linuxbrew/bin/lazydocker` ならよい
     - 2 行目が出なければ、リードの前提（homebrew.md の節）を通していない
   - `中断:` と出たら、何も書き換えていない（最後の 2 行は出る）
     - `sudo grep -n DOCKER_HOST /root/.bashrc` で見て、同じ値なら済んでいる。違う値なら手で直す
   - podman-docker を入れたホストでは、書く前から最後の 2 行が同じ出力になる（[root で使うときの補足](#root-で使うときの補足)）
   - 開いたままの root のシェルには効かない。開き直すか、そのシェルで `. ~/.bashrc` を実行する
   - root のシェルにも自分用の bash の設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash) の [docs/install.md の「root のシェルでも読む」](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#root-のシェルでも読む任意)）を入れたホストでは、このブロックは貼らない。代わりに `sudo -i bash -c 'printenv DOCKER_HOST; command -v lazydocker'` を実行する（その設定が、この節の手順 1 のソケットがあるときに同じ `DOCKER_HOST` を入れる）

   <details>
   <summary>補足: 書く 1 行と、<code>sudo -i</code> で読まれる仕組み</summary>

   - `sudo -i` は root のログインシェルを開き、`/root/.bash_profile` から `/root/.bashrc` を読む。`sudo -i <コマンド>` でも読む
   - `-i` の無い `sudo` は root の `~/.bashrc` を読まず、自分の環境の `DOCKER_HOST` も消す（AlmaLinux 10 の `/etc/sudoers` は `env_reset` で、`env_keep` に `DOCKER_HOST` は無い）
   - 自分の `~/.bashrc` の行（[podman.md の Docker 向けの節](podman.md#docker-向けのツールから使う任意)）と違い、`${XDG_RUNTIME_DIR}` は使わない。root のソケットは `/run/podman` に決まっている
   - 先頭の `if` は、ほかで書いた `DOCKER_HOST` に重ねないため
   - ヒアドキュメントは引用符付きの `<<'EOF'` なので、書いた行がそのまま入る

   **出力例**: 最後の行の、コンテナでの実測:

   ```
   $ sudo -i bash -c 'printenv DOCKER_HOST; command -v lazydocker'
   unix:///run/podman/podman.sock
   /home/linuxbrew/.linuxbrew/bin/lazydocker
   ```

   `/root/.bashrc` に書く前は 1 行目が出なかった。homebrew.md のどちらの節も通していないと 2 行目も出ず、終了コードは 1 だった。

   </details>

1. 確認用のコンテナを root で動かす。

   ```bash
   {
     sudo podman run -d --name lazydocker-root-web --label name=lazydocker-root-web registry.access.redhat.com/ubi10/httpd-24:latest
     sudo podman ps --filter name=lazydocker-root-web --format '{{.Names}} {{.Status}}'
   }
   ```

   - コンテナの ID の後に、`lazydocker-root-web Up Less than a second` のように出る
   - root の保管場所に、イメージ（285 MB）を取得する。自分のユーザーで取得したイメージは使われない
   - 名前を[手順 3](#実施手順) の `lazydocker-web` と分けて、どちらのコンテナの画面かを見分ける

1. root で lazydocker を起動し、確認用のコンテナを止める。

   ```bash
   sudo -i lazydocker
   ```

   - `[3]─Containers` に `running  lazydocker-root-web` の行が出る。[手順 3](#実施手順) の `lazydocker-web` は出ない
   - ↑↓ で `lazydocker-root-web` の行を選び、`s` を押し、`Are you sure you want to stop this container?` に `y` と答える
   - 行が `exited (0)` に変わる
   - `q` で終了する
   - **次の手順は、`q` で終了してから貼る**（続けて貼ると lazydocker への操作として食われる）

   <details>
   <summary>補足: 画面の中身</summary>

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

   - 出るのは root のコンテナとイメージだけ。[手順 3](#実施手順) の `lazydocker-web` と、自分のユーザーの `quay.io/podman/hello` は出ない
   - `-i` を付けずに `sudo lazydocker` と打つと（[homebrew.md の sudo でも使う](homebrew.md#sudo-でも使う任意)の節を通したホスト）、`Error` の枠に次が出て、枠は空のまま:

   ```
   Docker event stream returned error: Cannot connect to the Docker daemon at
   unix:///var/run/docker.sock. Is the docker daemon running?
   Retry count: 3
   ```

   </details>

1. 確認用のコンテナが止まったことと、root の設定ファイルができたことを確かめる。

   ```bash
   {
     sudo podman ps -a --filter name=lazydocker-root-web --format '{{.Names}} {{.Status}}'
     sudo ls -l /root/.config/lazydocker
   }
   ```

   - `lazydocker-root-web Exited (0) ...` と出ればよい
   - `config.yml`（0 バイト）は root の設定ファイル。自分の `~/.config/lazydocker` の設定（任意節で足したもの）は、root では使われない

1. 元に戻すときは、root の確認用のコンテナと設定、`/root/.bashrc` の行を消す。

   ```bash
   {
     sudo podman rm -f lazydocker-root-web
     sudo rm -rf /root/.config/lazydocker
     sudo sed -i '\#^export DOCKER_HOST=unix:///run/podman/podman\.sock$#d' /root/.bashrc
     sudo grep -c DOCKER_HOST /root/.bashrc   # 0
   }
   ```

   - `lazydocker-root-web` と、最後に `0` が出ればよい
   - root の設定ファイルに手で足したもの（`c` のコマンドなど）も消える
   - 開いたままの root のシェルの `DOCKER_HOST` は残る。開き直すと消える
   - root のシェルにも自分用の bash の設定を入れたホストでは、`/root/.bashrc` にこの行は無い（最後に `0` と出る）。その設定は、この節の手順 8 の後もソケットのファイルが残る間（再起動まで）、`DOCKER_HOST` を入れる

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

---

## ロールバック

- 上から順に実行する
- [root でも使う](#root-でも使う任意)の節を通したなら、先にその節の手順 6〜8 で戻す（この節の手順 3 で、root の lazydocker も消える）
- `DOCKER_HOST` の行と API ソケットは、ほかのツールも使うので残す。消すなら [podman.md のロールバック](podman.md#ロールバック)の手順 2・3
- compose の任意節で使った `~/compose-sample` は、[podman-compose のロールバック](podman-compose.md#ロールバック)で消す

1. 確認用のコンテナを消す。

   ```bash
   podman rm -f lazydocker-web
   ```

   - `lazydocker-web` と出る

1. 同じイメージをほかで使っていないときだけ、イメージを消す。

   ```bash
   podman rmi registry.access.redhat.com/ubi10/httpd-24:latest
   ```

   - 同じイメージを使うもの: [podman.md の Quadlet](podman.md#quadlet-で自動起動する任意)、[podman-compose](podman-compose.md)、[podman-tui](podman-tui.md)
   - 使っているコンテナが残っていると、消せずにエラーになる

1. lazydocker を消す。

   ```bash
   brew uninstall lazydocker
   ```

   - `Uninstalling /home/linuxbrew/.linuxbrew/Cellar/lazydocker/0.25.2...` と出る

1. 設定も消すときだけ、`~/.config/lazydocker` を消す。

   ```bash
   rm -rf ~/.config/lazydocker
   ```

   - 任意節で足した設定も消える

---

## 補足

### 対象と検証環境

- **目的**: コンテナ・イメージ・ボリューム・ネットワークと、compose のサービスを、端末の画面（TUI）で見て操作できるようにする。podman の API ソケットに、Docker の API としてつなぐ
  - 任意節で、root のコンテナ（`sudo podman` で動かしたもの）も、`sudo -i lazydocker` で見られるようにする
- **進め方**: Homebrew の lazydocker 0.25.2 を入れ、[podman.md の Docker 向けの節](podman.md#docker-向けのツールから使う任意)の `DOCKER_HOST` でつなぐ。podman だけの PC で動かないところ（シェルと compose）は、任意節の設定で補う。**読者が書き換える変数は無い**
- **状態**: **x86_64 のコンテナでのみ検証済み（2026-09-28）。実機では本実行していない**
  - 下表の検証コンテナで、[podman.md](podman.md) の実施手順と Docker 向けの節、[Homebrew の導入](homebrew.md)を通したうえで、**この文書のコードブロックをそのまま端末に貼って**、手順 1〜5、2 つの任意節、[更新](#更新)、[ロールバック](#ロールバック)を通した
  - compose の任意節の前には、EPEL の有効化（今の [epel.md](epel.md) の手順 1〜3。当時は podman-compose.md の手順 1〜3）と、[podman-compose.md](podman-compose.md) の手順 1〜6 を通した
  - 確認したこと:
    - lazydocker 0.25.2 が `DOCKER_HOST` で podman 5.8.2 の API ソケットにつながり、コンテナ・イメージ・ボリューム・ネットワークとログを出す
    - 画面の `s` でコンテナが止まり、`podman ps` にも `Exited (0)` で出る
    - `c` に足した `podman exec` でシェルが開き、`dockerCompose: podman-compose` で Project と Services の枠が出て、`r` で `web` が再起動する
    - [使い方の基本](#使い方の基本)の表のキーと、`E`・`a` が何も起こさないこと
  - **確認していないこと**: 色や罫線の見た目、デスクトップの端末での表示、`w`（ブラウザで開く）・`b`（まとめての操作）・`p`（一時停止）・`/`（絞り込み）
  - aarch64（Raspberry Pi 5）では通していない
  - [root でも使う](#root-でも使う任意)の節は、**x86_64 のコンテナでのみ検証した**（2026-10-05。[付録](#付録-root-でも使う節のコンテナでの検証記録2026-10-05)）
    - 通したこと: その節の手順 1〜8 を、この文書のコードブロックのまま、`sudo` のユーザーの端末に、ブラケットペーストの無しと有りで 1 回ずつ貼った。手順 1・2 は重ねても貼った
    - 確認したこと:
      - root の画面に root のコンテナだけが出て、`s` で止まる。`su -`・`sudo -s` の root のシェルでも同じ
      - `sudo lazydocker` はつながらず、`sudo -E lazydocker` は自分のコンテナを出す
      - homebrew.md のどちらの節だけでも動く。その節の手順 6〜8 で、`/root/.bashrc` が元と同じ内容に戻る
    - 確認していないこと: 実機、aarch64、SELinux が Enforcing のホスト、root の Quadlet のコンテナ
    - 2026-10-05: 自分用の bash の設定を root のシェルにも入れたホストの箇条書き（その節の手順 2・6）は、その設定の検証の中で、代わりのコマンドと、その節の手順 6〜8 を x86_64 のコンテナで流して確かめた（[ryo-aoki-pc/bash の docs/install.md の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#付録-root-のシェルでも読む節の検証記録2026-10-05)）

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-28 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2` を、x86_64 の実機の rootless の podman 5.8.2 で `--privileged` にして起動。systemd が PID 1） |
| podman | 未確認 | `podman-5.8.2-9.el10_2.alma.1`（[podman.md](podman.md) の実施手順で導入。入れ子の rootless） |
| Homebrew | 未確認 | 7.0.6（[homebrew.md](homebrew.md) の手順 1〜4 で導入） |
| lazydocker | 未導入 | 0.25.2（`x86_64_linux` のボトル） |
| podman-compose | 未確認 | `podman-compose-1.5.0-1.el10_1`（epel。compose の任意節だけで使った） |
| `docker` コマンド | — | 無し（`podman-docker` は入れていない） |
| 端末 | — | 160 桁 × 50 行の擬似端末（`TERM=xterm-256color`、`LANG=C.UTF-8`）の SSH のログインシェル |

- 実機の列は、この手順を適用した結果ではない

> [!NOTE]
> 出力例の値は `<USER>` / `<UID>` / `<HOSTNAME>` のプレースホルダで書いてある。バージョン（`0.25.2`・`5.8.2`）とイメージの大きさは実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（[podman.md](podman.md) の実施手順と Docker 向けの節、Homebrew の導入の後）の状態:

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
| [podman-tui](podman-tui.md) | 別の手順書。podman の API でつなぎ、pod とシークレットも扱える。`DOCKER_HOST` は要らない |
| **root のコンテナは `sudo -i lazydocker` で見る**（`/root/.bashrc` の `DOCKER_HOST` で、システムの API ソケットにつなぐ） | **採用**（[root でも使う](#root-でも使う任意)の節）。自分の `~/.bashrc` と同じ形で、効くのは root のシェルだけ |
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

[root でも使う](#root-でも使う任意)の節の補足。実測は x86_64 のコンテナで、その節の手順 5 の後のもの（[付録](#付録-root-でも使う節のコンテナでの検証記録2026-10-05)）。

| 入口 | `DOCKER_HOST` | 画面に出るもの |
|---|---|---|
| `sudo -i lazydocker`、`sudo -i`・`su -`・`sudo -s` で開いた root のシェルの `lazydocker` | `/root/.bashrc` の `unix:///run/podman/podman.sock` | root のコンテナ |
| `sudo lazydocker` | 無い（`sudo` が消す） | 何も出ない。`Cannot connect to the Docker daemon at unix:///var/run/docker.sock`（その節の手順 4 の補足） |
| `sudo -E lazydocker` | 自分の `unix:///run/user/<UID>/podman/podman.sock` | 自分のコンテナ（root が自分のソケットにつなぐ） |
| `sudo DOCKER_HOST=unix:///run/podman/podman.sock lazydocker` | 打った値 | root のコンテナ |

- **入口と前提の節**: `-i` の無い 3 つは、[homebrew.md の sudo でも使う](homebrew.md#sudo-でも使う任意)の節を通したときだけ動く（通さないと `sudo: lazydocker: command not found`）
  - `su -` は、[homebrew.md の root のシェルでも使う](homebrew.md#root-のシェルでも使う任意)の節が要る
  - `sudo -i lazydocker` は、どちらの節だけでも動いた。どちらも無いと `-bash: line 1: lazydocker: command not found`
- **`sudo -E` は使わない**: `HOME` は `/root`（`/etc/sudoers` の `always_set_home`）で root の設定を読みながら、root の権限で自分のコンテナを操作する
  - 自分の `~/.config/lazydocker` に、root の持ち物のファイルはできなかった
- **root の設定ファイルは `/root/.config/lazydocker/config.yml`**: 自分の設定（任意節で足した `c` のコマンドなど）は使わない
  - root でも `c` からシェルを開くなら、[podman exec の節](#podman-exec-でシェルを開く任意)の手順 2 の 5 行を、`sudo` で root の設定ファイルに書く
  - 書いたコンテナでは、root の画面の `c` → `podman exec sh` で `sh-5.2$` が開いた
- **`E` と `a` は root でも何も起きない**: `docker` コマンドが無いため（[注意点](#注意点)）
- **root のシェルの `DOCKER_HOST` は、ほかのツールにも効く**: root のシェルで動かす Docker の API を使うツールも、root の podman につながる。podman 自身は `DOCKER_HOST` を読まない
- **podman-docker を入れたホストでは**: `/etc/profile.d/podman-docker.sh` が、`DOCKER_HOST` の無い root のログインシェルに同じ値を入れ、`/run/docker.sock` を root のソケットへのリンクにする
  - その節の手順 2 の確かめの行は、書く前から同じ 2 行を出した。`if` は `/root/.bashrc` しか見ないので、同じ行を書き足す（害は無い）
  - `-i` の無い `sudo lazydocker` も、root のコンテナにつながった
  - podman-docker を外しても、`/run/docker.sock` のリンクは再起動まで残った
- **ソケットの権限を緩めない**: root の API ソケットにつなげると、root でコンテナを動かせる（ホストの `/` を付けたコンテナなど）。`SocketGroup` などで広げない（[選択した方針](#選択した方針)）

### 注意点

- **`E` と `a` は `docker` コマンドを呼ぶ**: podman だけの PC では、`+ docker exec -it <ID> /bin/sh -c ...` と `Press enter to return to lazydocker ...` が出るだけで、エラーも出ない
  - シェルは [podman exec の節](#podman-exec-でシェルを開く任意)の `c` で開く
  - `a` は `-it` で起動したコンテナにだけ使える。`-it` でないコンテナでは `Container does not support attaching. ...` と出る
- **UBI のイメージのコンテナは、イメージの名前で並ぶ**: lazydocker はコンテナの `name` ラベルを名前として出す（手順 3 の補足）
  - 同じイメージのコンテナが並ぶと見分けにくい。操作する前に、右の枠の `Config` タブの `ID` を `podman ps` と見比べる
  - 自分で動かすコンテナなら、手順 3 のように `podman run` の `--label name=<名前>` で分けられる
- **`r` は確認なしで再起動する**: `s`（止める）は確認が出るが、`r` はすぐに実行する
- **`DOCKER_HOST` が無いか API ソケットが止まっていると、枠が空のまま**: 手順 2 の補足のエラーが出る
- **pod とシークレットは出ない**: Docker の API に無いため。pod は [podman-tui](podman-tui.md) で見る
- **設定ファイルの同じキーを重ねない**: `cat >>` で同じトップレベルのキーを 2 回書くと、後ろだけが効く（[podman exec の節](#podman-exec-でシェルを開く任意)の手順 2 の補足）
- **`sudo lazydocker` は root のコンテナにつながらない**: `sudo` が `DOCKER_HOST` を消す（Homebrew の lazydocker は、そのままでは `sudo` の PATH にも無い。[homebrew.md の注意点](homebrew.md#注意点)）
  - root のコンテナは、[root でも使う](#root-でも使う任意)の節を通して `sudo -i lazydocker` で見る

### 参照

- [jesseduffield/lazydocker — README](https://github.com/jesseduffield/lazydocker) — 機能と、各 OS への導入
- [lazydocker — Config.md](https://github.com/jesseduffield/lazydocker/blob/master/docs/Config.md) — `customCommands`・`commandTemplates` の書き方、設定ファイルの場所（Linux は `~/.config/lazydocker/config.yml`）
- [lazydocker — Keybindings](https://github.com/jesseduffield/lazydocker/blob/master/docs/keybindings/Keybindings_en.md) — 枠ごとのキー
- `lazydocker --config` — 既定の設定の全体
- [Homebrew](homebrew.md) / [Podman](podman.md) / [podman-compose](podman-compose.md) — 前提の手順書
- [podman-system-service(1)](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html) — root の API ソケット（`unix:///run/podman/podman.sock`）
- `man sudo`（`-i`）・`man sudoers`（`env_reset`・`env_keep`） — [root でも使う](#root-でも使う任意)の節で、`-i` の無い `sudo` に `DOCKER_HOST` が渡らない理由

---

### 付録: コンテナでの検証記録（2026-09-28）

**環境**: [podman-tui.md の付録](podman-tui.md#付録-コンテナでの検証記録2026-09-28)と同じ作りの使い捨てのコンテナ（x86_64 の実機の rootless の podman の上）。実機で加えた変更は無い。

**手順書の外で行った準備**: podman-tui.md の付録の準備と同じ。Homebrew のインストーラは `NONINTERACTIVE=1` を付けずに流し、`Press RETURN/ENTER to continue` に Enter を送った。

**流し方**:

- 同じ SSH のセッションで、先に podman.md の手順 1〜3・5〜7 と Docker 向けの節、[homebrew.md](homebrew.md) の手順 1〜4 を流した
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
| compose の節 | 先に EPEL の有効化（今の epel.md の手順 1〜3）と、podman-compose.md の手順 1〜6 を通した。手順 1 の読み戻しに 2 行。手順 2 は `[1]─Project`（`compose-sample`）・`[2]─Services`（`check`・`web`）・`[3]─Standalone Containers`（`lazydocker-web`）で、`web` を選んで `r`。手順 3 は `compose-sample_web_1 Up 14 seconds` と `compose-sample_check_1 Up 48 seconds` |
| 更新 | `Warning: lazydocker 0.25.2 already installed` |
| ロールバック | 先に podman-compose.md のロールバック手順 1〜2 を通した。手順 1 は `lazydocker-web`、手順 2 は `Untagged:` と `Deleted:`、手順 3 は `Uninstalling /home/linuxbrew/.linuxbrew/Cellar/lazydocker/0.25.2... (6 files, 13.2MB)`、手順 4 は何も出ずに終わった。最後に podman-compose.md のロールバック手順 4 を通した |

**別に確かめたこと**（同じ作りの別のコンテナで、手順書の外のコマンドとして実行）:

- `DOCKER_HOST` を外したとき・API ソケットを止めたときの画面（手順 2 の補足）
- `docker` コマンドの無い状態の `E`（`+ docker exec -it ...` の後に何も起きない）と `a`（`-it` のコンテナで `+ docker attach --sig-proxy=false <ID>` の後に何も起きない）
- `--label name=` を付けないときの名前の出方と、並びが入れ替わって `r` で別のコンテナを再起動したこと（手順 3 の補足）
- `customCommands:` を 2 回書いたとき（podman exec の節の手順 2 の補足）
- 既定の設定のまま `~/compose-sample` で起動すると、Project と Services の枠が出ないこと
- `podman-docker` を入れると、既定の設定のまま `E`（`bash-5.2$`）・`a`（`Ctrl+P` `Ctrl+Q` で抜けた）・compose の判定が動くこと。確かめた後に `sudo dnf remove -y podman-docker` で外した
- [使い方の基本](#使い方の基本)の表のキー

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- 色や罫線の見た目と、デスクトップの端末での表示
- `w`（ブラウザで開く）・`b`（まとめての操作）・`p`（一時停止）・`/`（絞り込み）
- compose のサービスへの `r` 以外の操作（`U`・`D` での up・down など）
- SELinux が有効な PC での動き

### 付録: root でも使う節のコンテナでの検証記録（2026-10-05）

[root でも使う（任意）](#root-でも使う任意)を足したときの記録。x86_64 のクラウドホスト（Ubuntu 24.04、cgroup v1）上の Docker 29.6.2 で、使い捨てのコンテナを立てて行った。実機で加えた変更は無い。

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
- **前提の手順書**: [podman.md](podman.md) の手順 1〜3・5〜7 と Docker 向けの節、[homebrew.md](homebrew.md) の手順 1〜4（インストーラだけ `NONINTERACTIVE=1`）、この文書の手順 1〜3 は、端末の無い ssh からスクリプトで流した（貼ってはいない）
  - その ssh を閉じたとき、linger が無いので自分の `lazydocker-web` が止まった。入口の確認の前に `podman start` で起動し直した
- homebrew.md の [root のシェルでも使う](homebrew.md#root-のシェルでも使う任意)の節の手順 1 は、下の端末に貼った

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
| root の `c`・`E` | root の設定ファイルに [podman exec の節](#podman-exec-でシェルを開く任意)の手順 2 の 5 行を書くと、`c` → `podman exec sh` → Enter で `+ podman exec -it <ID> sh` と `sh-5.2$`、`id` は `uid=1001(default) gid=0(root) groups=0(root)`、`exit` と Enter で画面に戻った。`E` は `+ docker exec -it <ID> /bin/sh -c ...` と `Press enter to return to lazydocker ...` だけ |
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
