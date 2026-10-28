# コンテナのセットアップ（AlmaLinux 10）

- AlmaLinux 10 で、Podman とその周りの道具（podman-compose・podman-tui・lazydocker）と Distrobox を入れて使う
- 検証記録・参考資料・注意点は、各項のリードから開く

> [!IMPORTANT]
> - **前提と実行場所（ユーザー・端末・別のマシン）は、各項のリードに従う**。`sudo -i`・`su -` のシェルでは行わない
> - AlmaLinux 10 の項は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)と同じく、パスワードを聞かない `sudo` を前提に書いてある。各項のリードの前提に無くても、その項を行うユーザーで[ログインと sudo](almalinux-setup.md#ログインと-sudo)を先に通す

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- 入れたものは、[Podman: 更新](#podman-更新)・[podman-compose: 更新](#podman-compose-更新)・[podman-tui: 更新](#podman-tui-更新)・[lazydocker: 更新](#lazydocker-更新)・[Distrobox: 更新](#distrobox-更新)で上げる

## AlmaLinux 10 で使う

- Podman とその周りの道具（podman-compose・podman-tui・lazydocker）と Distrobox

### Podman

- AppStream の podman を入れ、自分のユーザー（rootless）でコンテナを動かせるようにする
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)を通してある
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/podman.md)・[参考資料](reference/podman.md)・[注意点](extra/podman.md)
- 導入後は、必要な[コンテナ用ツール](tool-catalog.md#cli-コンテナ)を追加する

> [!IMPORTANT]
> - **自分のユーザーでログインした bash（デスクトップの端末か SSH）で行う**
> - `sudo -i` の root のシェルや、`sudo -iu <ユーザー>` で切り替えたシェルでは行わない

1. podman が入っているか確かめる。

   ```bash
   rpm -q podman || echo 'podman は未導入'
   ```

   - `podman-5.8.2-...` のように版が出れば、手順 2 は飛ばす
   - `podman は未導入` と出たら、手順 2 で入れる

1. podman が未導入のときだけ、AppStream から入れる。

   ```bash
   sudo dnf install -y podman
   ```

1. 自分のユーザーに、rootless 用の UID・GID の範囲（subuid / subgid）があるか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   for f in /etc/subuid /etc/subgid; do
     grep -H "^${USER}:" "$f" || printf '%s: 自分の割り当てが無い\n' "$f"
   done
   ```

   - `/etc/subuid:<USER>:524288:65536` と `/etc/subgid:<USER>:524288:65536` のような 2 行が出れば、手順 4 は飛ばす
   - 片方でも `自分の割り当てが無い` と出たら、手順 4 で不足している側だけ割り当てる

1. 片方でも割り当てが無いときだけ、不足する側に範囲を割り当て、podman に読み直させる。

   ```bash
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: 自分のユーザーのシェルで貼る' >&2
   elif SUBID_START=$(awk -F: '{ e = $2 + $3; if (e > m) m = e } END { print (m > 524288 ? m : 524288) }' /etc/subuid /etc/subgid); then
     SUBID_ARGS=()
     if ! grep -q "^${USER}:" /etc/subuid; then
       SUBID_ARGS+=(--add-subuids "${SUBID_START}-$((SUBID_START + 65535))")
     fi
     if ! grep -q "^${USER}:" /etc/subgid; then
       SUBID_ARGS+=(--add-subgids "${SUBID_START}-$((SUBID_START + 65535))")
     fi
     if [ "${#SUBID_ARGS[@]}" -eq 0 ]; then echo '両方とも割り当て済み'
     else
       printf '\n\033[7m 確認 \033[0m\n'
       sudo usermod "${SUBID_ARGS[@]}" "${USER}" &&
       podman system migrate &&
       grep -H "^${USER}:" /etc/subuid /etc/subgid
     fi
   else echo '中断: /etc/subuid または /etc/subgid を読めない' >&2
   fi
   ```

   - 手順 3 で出るはずだった 2 行が出ればよい

1. 自分のユーザーで動く設定になっているか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   podman version --format '{{.Client.Version}}'
   command -v podman
   podman info --format '{{.Host.Security.Rootless}} {{.Store.GraphDriverName}} {{.Host.OCIRuntime.Name}} {{.Host.NetworkBackend}} {{.Host.RootlessNetworkCmd}} {{.Host.CgroupsVersion}}'
   podman info --format '{{.Store.GraphRoot}}'
   ```

   - `5.8.2` と `/usr/bin/podman` が出る
   - 3 行目が `true overlay crun netavark pasta v2` なら、自分のユーザー（rootless）で動く
   - イメージとコンテナは、4 行目の場所（`/home/<USER>/.local/share/containers/storage`）に入る

1. イメージを完全な名前で指定して、コンテナを 1 つ動かす。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   podman run --rm quay.io/podman/hello
   podman images
   ```

   - `!... Hello Podman World ...!` から始まる絵と案内が出る
   - `podman images` に `quay.io/podman/hello` の行が出る
   - **イメージはレジストリの名前から書く**（`quay.io/...`、`registry.access.redhat.com/...`）。短い名前だと、どこから取るかを聞かれることがある（参考資料を参照）

1. API ソケットを有効にして、応答を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user enable --now podman.socket
   systemctl --user is-active podman.socket
   curl -s --unix-socket "${XDG_RUNTIME_DIR}/podman/podman.sock" http://d/_ping; echo
   podman --remote version --format '{{.Server.Version}}'
   ```

   - `active`・`OK`・`5.8.2` が出ればよい
   - 初めて有効にしたときは、その前に `Created symlink '/home/<USER>/.config/systemd/user/sockets.target.wants/podman.socket' → '/usr/lib/systemd/user/podman.socket'.` の行が 1 つ出る
   - `Failed to connect to user scope bus` と出たら、`sudo -iu` などで切り替えたシェルで実行している。自分のユーザーでログインし直す

#### Podman: Docker 向けのツールから使う

- Docker の API に `DOCKER_HOST` でつなぐツール（[lazydocker](#lazydocker) など）のための設定
- 前提: [Podman](#podman)と[共通の bash 設定](shell-terminal.md#共通の-bash-設定)を通してある
  - `DOCKER_HOST` は共通の bash 設定が入れる。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- [画像の道具](almalinux-setup.md#画像の道具) の dive と Trivy、[podman-tui](#podman-tui) は podman を直接読むので、この項は要らない

1. 共通設定を読み直し、ソケットが Docker の API に答えるか確かめる。

   ```bash
   . ~/.bashrc
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%s\n' "${DOCKER_HOST-}"
   curl -s --unix-socket "${DOCKER_HOST#unix://}" http://d/version | grep -o '"Name":"Podman Engine"'
   ```

   - `unix:///run/user/…/podman/podman.sock` と `"Name":"Podman Engine"` が出ればよい
   - 既に別の値がある場合は上書きせず、その用途を確認する
   - `~/.bashrc` には追記しない

#### Podman: Quadlet で自動起動する

- `podman run -d` で動かしたコンテナは、PC を再起動すると戻らない。linger が無いと、ログアウトしただけで止まる（[注意点](extra/podman.md#注意点)）
- Quadlet は、`~/.config/containers/systemd` に置いた定義から、ユーザーの systemd のサービスを作る仕組み。podman に含まれている
- 確認用に、`registry.access.redhat.com/ubi10/httpd-24`（Apache）を `127.0.0.1:8080` で動かす
- 前提: [Podman](#podman)と[ユーザーサービスの常駐](almalinux-setup.md#ユーザーサービスの常駐)（linger）を通してある
  - `loginctl show-user "$(id -u)" -p Linger` が `Linger=yes` でなければ、先に通す
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- この項の手順 3 で再起動する

1. 確認用の Web サーバーの定義とページを置く。

   ```bash
   mkdir -p ~/hello-web ~/.config/containers/systemd
   echo 'hello from quadlet' > ~/hello-web/index.html
   cat > ~/.config/containers/systemd/hello-web.container <<'EOF'
   [Unit]
   Description=Quadlet の確認用の Web サーバー

   [Container]
   Image=registry.access.redhat.com/ubi10/httpd-24:latest
   ContainerName=hello-web
   PublishPort=127.0.0.1:8080:8080
   Volume=%h/hello-web:/var/www/html:Z
   AutoUpdate=registry

   [Service]
   TimeoutStartSec=300

   [Install]
   WantedBy=default.target
   EOF
   ```

1. systemd に定義を読み直させ、サービスを起動して応答を確かめる。

   ```bash
   systemctl --user daemon-reload
   systemctl --user start hello-web.service
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user is-active hello-web.service
   systemctl --user is-enabled hello-web.service
   curl -s --retry 10 --retry-delay 1 --retry-all-errors http://127.0.0.1:8080/
   ```

   - `active`・`generated`・`hello from quadlet` が出ればよい
   - 初回の `start` は、数十秒かかることがある
   - **`systemctl --user enable` は使わない**

1. 再起動しても起動するかを確かめるときだけ、再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - 再起動しないなら、この項の手順 4 も飛ばす
   - **次の手順は、再起動した後にログインし直してから貼る**

1. 再起動の後、ログインより前にサービスが起動していたことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl --user show hello-web.service -p ActiveEnterTimestamp
   loginctl show-session "${XDG_SESSION_ID}" -p Timestamp
   curl -s http://127.0.0.1:8080/
   ```

   - 1 行目の時刻（サービスが起動した時刻）が、2 行目の時刻（ログインした時刻）より前ならよい
   - `hello from quadlet` が出る

#### Podman: 使い方の基本

| コマンド | 用途 |
|---|---|
| `podman ps -a` | コンテナの一覧（止まっているものも） |
| `podman images` | イメージの一覧 |
| `podman run -d --name <名前> -p 127.0.0.1:<ポート>:<ポート> <イメージ>` | 裏で動かす。自分のユーザーでは 1024 未満のポートを使えない（[注意点](extra/podman.md#注意点)） |
| `podman logs <名前>` | ログを見る（`-f` で追い続ける） |
| `podman exec -it <名前> bash` | 動いているコンテナの中でシェルを開く |
| `podman stop <名前>` / `podman rm <名前>` | 止める / 消す |
| `podman rmi <イメージ>` | イメージを消す |
| `podman pull <イメージ>` | 取得だけする |
| `podman manifest inspect <イメージ>` | 取得せずに、対応しているアーキ（`arm64` など）を見る |
| `podman system df` | イメージ・コンテナ・ボリュームの容量 |
| `podman image prune -a` | どのコンテナも使っていないイメージを消す（`-a` 無しは、名前の無いイメージだけ） |
| `podman unshare ls -ln <パス>` | コンテナから見える UID で、ファイルの持ち主を見る |

- どれも `sudo` を付けない
- `sudo podman` は root 用の別の保管場所（`/var/lib/containers`）を使うので、自分のコンテナもイメージも見えない

#### Podman: 更新

- podman と、Quadlet で動かすコンテナのイメージを上げる
- 前提: [Podman](#podman)を通してある
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）

1. podman を更新する。

   ```bash
   sudo dnf upgrade podman
   ```

   - システム全体なら `sudo dnf upgrade`
   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. [Quadlet で自動起動する](#podman-quadlet-で自動起動する)を通したときだけ、新しいイメージがあるか見てから当てる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   podman auto-update --dry-run
   podman auto-update
   ```

   - `UPDATED` の列が `false` なら、新しいイメージは無い
   - `true` なら、新しいイメージを取ってサービスを起動し直す

---

### podman-compose

- EPEL の podman-compose を入れ、compose ファイルで 2 つのコンテナを動かして確かめる
- 前提: [Podman](#podman)と[EPEL と RPM Fusion](almalinux-setup.md#epel-と-rpm-fusion)の手順 1 を通してある
  - `podman info --format '{{.Host.Security.Rootless}}'` が `true` を返さない、または `dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に前提を通す
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/podman-compose.md)・[参考資料](reference/podman-compose.md)・[注意点](extra/podman-compose.md)
- **手順 1 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）。答えてから手順 2 を貼る
- **手順 6 の `podman-compose exec` は、動いている間に貼った行をコンテナへの入力として取り込む**。プロンプトが戻ってから次を貼る
- PC を再起動しても動かしておきたいものは、compose ではなく [Podman の Quadlet](#podman-quadlet-で自動起動する) で動かす（[注意点](extra/podman-compose.md#注意点)）

> [!IMPORTANT]
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（コンテナを自分のユーザーの rootless の podman で動かすため）

1. 入手できる版を見てから、podman-compose を入れる。

   ```bash
   dnf -q list --showduplicates podman-compose
   sudo dnf install podman-compose
   ```

   - 版は `podman-compose.noarch  1.5.0-1.el10_1  epel` のように 1 つだけ出る
   - 一緒に入るのは未導入の Python のライブラリで、最大 4 つ（`python3-click`・`python3-dotenv`・`python3-dotenv+cli`・`python3-pyyaml`）
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y` と答える
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. podman-compose が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose version
   command -v podman-compose
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' podman-compose
   podman compose version
   ```

   - `podman-compose version 1.5.0` と `podman version 5.8.2` の 2 行が出る
   - `/usr/bin/podman-compose`、`podman-compose 1.5.0-1.el10_1 epel` が出る
   - 最後の `podman compose` は、`Executing external compose provider "/usr/bin/podman-compose"` と出してから、同じ 2 行を出す

1. 確認用の compose ファイルとページを置く。

   ```bash
   mkdir -p ~/compose-sample/html
   echo 'hello from compose' > ~/compose-sample/html/index.html
   cat > ~/compose-sample/compose.yaml <<'EOF'
   services:
     web:
       image: registry.access.redhat.com/ubi10/httpd-24:latest
       ports:
         - "127.0.0.1:8081:8080"
       volumes:
         - ./html:/var/www/html:Z
     check:
       image: registry.access.redhat.com/ubi10/httpd-24:latest
       command: sleep infinity
       init: true
   EOF
   cat ~/compose-sample/compose.yaml
   ```

1. compose ファイルのあるディレクトリで、コンテナを起動する。

   ```bash
   cd ~/compose-sample
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose up -d
   ```

   - 最後に `compose-sample_web_1` と `compose-sample_check_1` が出る

1. 起動したコンテナと、公開したポートを確かめる。

   ```bash
   cd ~/compose-sample
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose ps
   podman pod ps
   curl -s --retry 10 --retry-delay 1 --retry-all-errors http://127.0.0.1:8081/
   ```

   - `podman-compose ps` に 2 つのコンテナが `Up` で出て、`web` の `PORTS` に `127.0.0.1:8081->8080/tcp` が出る
   - `podman pod ps` に `pod_compose-sample` が `Running` で出る
   - `hello from compose` が出ればよい

1. `check` のコンテナから、サービス名 `web` でつながるか確かめる。

   ```bash
   cd ~/compose-sample
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose exec check curl -s http://web:8080/
   ```

   - `hello from compose` が出ればよい
   - **ほかの項の手順は、プロンプトが戻ってから貼る**（続けて貼るとコンテナの中のコマンドへの入力として食われる）

#### podman-compose: 使い方の基本

どれも compose ファイル（`compose.yaml`）のあるディレクトリで打つ。別の場所からなら `-f <ファイル>` を付ける。

| コマンド | 用途 |
|---|---|
| `podman-compose up -d` | 起動する（無ければ作る） |
| `podman-compose ps` | コンテナの一覧と状態 |
| `podman-compose logs <サービス>` | ログを見る |
| `podman-compose exec <サービス> <コマンド>` | 動いているコンテナの中でコマンドを動かす（動いている間に貼った行を取り込むので、終わってから次を打つ） |
| `podman-compose pull` | イメージを取り直す |
| `podman-compose down` | コンテナ・pod・ネットワークを消す。名前付きのボリュームは残る |
| `podman-compose down -v` | 名前付きのボリュームも消す（中のデータも消える） |

- 端末の画面（TUI）でサービスのログを見たり再起動したりするなら、[lazydocker の compose の節](#lazydocker-compose-のプロジェクトを見る)

#### podman-compose: 更新

- podman-compose を上げ、確認用の compose のイメージを取り直す
- 前提: [podman-compose](#podman-compose)を通してある（この項の手順 2 は `~/compose-sample` を使う）
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）

1. podman-compose を更新する。

   ```bash
   sudo dnf upgrade podman-compose
   ```

   - システム全体なら `sudo dnf upgrade`
   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. イメージを取り直し、新しいイメージでコンテナを起動し直す。

   ```bash
   cd ~/compose-sample
   podman-compose pull
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose up -d
   ```

   - 新しいイメージが無いときも、`up -d` はコンテナの名前を出して終わる

---

### podman-tui

- EPEL の podman-tui を入れ、確認用のコンテナを画面（TUI）から止めて確かめる
- 前提: [Podman](#podman)の手順 7（API ソケット）までと、[EPEL と RPM Fusion](almalinux-setup.md#epel-と-rpm-fusion)の手順 1 を通してある
  - `systemctl --user is-active podman.socket` が `active` を返さない、または `dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に前提を通す
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/podman-tui.md)・[参考資料](reference/podman-tui.md)・[注意点](extra/podman-tui.md)
- **手順 1 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）。答えてから手順 2 を貼る
- **手順 4 で podman-tui の画面（TUI）が開く**。`Ctrl+C` で終了してから手順 5 を貼る（`q` では終わらない）
- Docker の API でつなぐ TUI なら [lazydocker](#lazydocker)（違いは[選択した方針](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/podman-tui.md#選択した方針)）

> [!IMPORTANT]
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（podman-tui は、自分のユーザーの API ソケットにつなぐため）

1. 入手できる版を見てから、podman-tui を入れる。

   ```bash
   dnf -q list --showduplicates podman-tui
   sudo dnf install podman-tui
   ```

   - 版は `podman-tui.x86_64  1.10.0-1.el10_2  epel` のように 1 つだけ出る
   - 入るのは `podman-tui` の 1 パッケージだけ（ダウンロード 9.5 MB、展開後 32 MB）
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）なら `y`、違えば `N` で中断する
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. podman-tui が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   podman-tui version
   command -v podman-tui
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' podman-tui
   ```

   - `podman-tui v1.10.0`、`/usr/bin/podman-tui`、`podman-tui 1.10.0-1.el10_2 epel` が出る

1. 画面で操作する、確認用のコンテナを動かす。

   ```bash
   podman run -d --name podman-tui-web registry.access.redhat.com/ubi10/httpd-24:latest
   printf '\n\033[7m 確認 \033[0m\n'
   podman ps --filter name=podman-tui-web --format '{{.Names}} {{.Status}}'
   ```

   - `podman-tui-web Up Less than a second` のように出る

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

   - `podman-tui-web Exited (0) ...` と出ればよい

#### podman-tui: 使い方の基本

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

#### podman-tui: 更新

- podman-tui を上げる
- 前提: [podman-tui](#podman-tui)を通してある
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）

1. podman-tui を更新する。

   ```bash
   sudo dnf upgrade podman-tui
   ```

   - システム全体なら `sudo dnf upgrade`
   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる
   - EPEL の podman-tui が 2.x に上がったときは、上流の互換表で podman の版と合うかを確かめる（[注意点](extra/podman-tui.md#注意点)）

---

### lazydocker

- Homebrew の lazydocker を入れ、podman の API ソケットにつないで、確認用のコンテナを画面（TUI）から止める
- 前提: [共通の bash 設定](shell-terminal.md#共通の-bash-設定)、[Homebrew](almalinux-setup.md#homebrew)の手順 1〜3、[Podman](#podman)の手順 7（API ソケット）まで、[Podman: Docker 向けのツールから使う](#podman-docker-向けのツールから使う)を通してある
  - ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない
  - `command -v brew podman` が 2 行を返さない、または `echo "${DOCKER_HOST}"` が `unix:///run/user/<UID>/podman/podman.sock` を返さなければ、先に前提を通す
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/lazydocker.md)・[参考資料](reference/lazydocker.md)・[注意点](extra/lazydocker.md)
- **手順 4 で lazydocker の画面（TUI）が開く**。`q` で終了してから手順 5 を貼る
- pod やシークレットも画面で扱うなら [podman-tui](#podman-tui)（違いは[選択した方針](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/lazydocker.md#選択した方針)）

> [!IMPORTANT]
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、lazydocker も自分のユーザーの API ソケットにつなぐため）

1. brew で lazydocker を入れる。

   ```bash
   brew install lazydocker
   ```

   - **次の手順は、確認が出たら答え、インストールが終わってシェルのプロンプトに戻ってから貼る**（依存の追加を確認する `[y/n]` が出る版では、続けて貼ると回答として食われる）

1. lazydocker が入ったことと、つなぐ先を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   lazydocker --version
   command -v lazydocker
   echo "${DOCKER_HOST}"
   curl -s --unix-socket "${DOCKER_HOST#unix://}" http://d/_ping; echo
   ```

   - 1 行目で `Version: 0.25.2` と `BuildSource: Homebrew` が出る
   - `/home/linuxbrew/.linuxbrew/bin/lazydocker` が出る
   - `unix:///run/user/<UID>/podman/podman.sock` と `OK` が出れば、lazydocker は podman の API ソケットにつなぐ
   - 3 行目が空なら、`DOCKER_HOST` が無い。[Podman: Docker 向けのツールから使う](#podman-docker-向けのツールから使う)を通す（参考資料を参照）

1. 画面で操作する、確認用のコンテナを動かす。

   ```bash
   podman run -d --name lazydocker-web --label name=lazydocker-web registry.access.redhat.com/ubi10/httpd-24:latest
   printf '\n\033[7m 確認 \033[0m\n'
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
   printf '\n\033[7m 確認 \033[0m\n'
   podman ps -a --filter name=lazydocker-web --format '{{.Names}} {{.Status}}'
   ls -l ~/.config/lazydocker
   ```

   - `lazydocker-web Exited (0) ...` と出ればよい
   - `config.yml`（0 バイト）がある

#### lazydocker: podman exec でシェルを開く

- lazydocker の `E`（シェルを開く）と `a`（アタッチ）は、`docker` コマンドを直接呼ぶ。podman だけの PC では、`+ docker exec -it ...` と出るだけで何も起きない（[注意点](extra/lazydocker.md#注意点)）
- この項で、`c`（自分で足したコマンドのメニュー）に、`podman exec` でシェルを開くコマンドを足す
- 前提: [lazydocker](#lazydocker)を通してある（確認用のコンテナ `lazydocker-web` と、設定ファイル `~/.config/lazydocker/config.yml` を使う）
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）

1. [手順 4](#lazydocker) で止めた確認用のコンテナを、起動し直す。

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
   printf '\n\033[7m 確認 \033[0m\n'
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
   - **ほかの項の手順は、`q` で終了してから貼る**（続けて貼ると lazydocker への操作として食われる）

#### lazydocker: compose のプロジェクトを見る

- lazydocker は、起動したディレクトリで `docker compose config --quiet` が通ったときだけ、`[1]─Project` と `[2]─Services` の枠を出す
- podman だけの PC では通らないので、この項で compose のコマンドを `podman-compose` に替える
- 前提: [lazydocker](#lazydocker)を通し、[podman-compose](#podman-compose)を手順 4 まで通して、`~/compose-sample` のコンテナが動いている
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）

1. compose のコマンドを `podman-compose` にする設定を、設定ファイルに足す。

   ```bash
   cat >> ~/.config/lazydocker/config.yml <<'EOF'
   commandTemplates:
     dockerCompose: podman-compose
   EOF
   printf '\n\033[7m 確認 \033[0m\n'
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
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose ps --format '{{.Names}} {{.Status}}'
   ```

   - `compose-sample_web_1 Up 15 seconds` のように、`web` の動いている時間が `check` より短ければよい

#### lazydocker: root でも使う

- この項で、システムの podman の API ソケット（`/run/podman/podman.sock`）を有効にし、root のコンテナを lazydocker で見る
- **root のコンテナを lazydocker で見ないなら、この項は不要**
- root のコンテナは `/var/lib/containers` にあり、[手順 4](#lazydocker)の一般ユーザーの画面には出ない
- 前提: [lazydocker](#lazydocker)と[共通の bash 設定を root に入れる](shell-terminal.md#共通の-bash-設定を-root-に入れる)を通してある
  - この設定が Homebrew の PATH と root 用の `DOCKER_HOST` を読む。sudo の `secure_path` だけではこの項の前提を満たさない
  - `sudo -i bash -c 'command -v lazydocker'` が `/home/linuxbrew/.linuxbrew/bin/lazydocker` を返せばよい
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）。root の権限は、コマンドに付けた `sudo` で使う
- [注意点](extra/podman.md#注意点)と[root を使う条件](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/podman.md#選択した方針)を先に確認する
- root の共通設定が、システムのソケットを指す `DOCKER_HOST` を入れる。`/root/.bashrc` には追記しない
- 起動は `sudo -i lazydocker`。`su -`・`sudo -i`・`sudo -s` で開いた root のシェルでは `lazydocker`
- `-i` の無い `sudo lazydocker` は root の `~/.bashrc` を読まないので、root のコンテナにつながらない（[root で使うときの補足](reference/lazydocker.md#root-で使うときの補足)）
- この項の手順 4 で lazydocker の画面（TUI）が開く
- 補足: [root で使うときの補足](reference/lazydocker.md#root-で使うときの補足)

> [!WARNING]
> - root の lazydocker は、一般ユーザーが書き換えられるプログラムを root 権限で動かす。[root 用 Homebrew](almalinux-setup.md#homebrew-を-root-のシェルでも使う)と同じ導入条件で行う
> - システムの API ソケットにつなげるのは root だけ。権限を緩めない（つなげると、root と同じことができる）

1. システムの podman の API ソケットを有効にして、root で応答を確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo systemctl enable --now podman.socket
     systemctl is-active podman.socket
     sudo curl -s --unix-socket /run/podman/podman.sock http://d/_ping; echo
     sudo podman --remote version --format '{{.Server.Version}}'
   }
   ```

   - `active`・`OK`・`5.8.2` が出ればよい

1. root の共通設定が接続先を設定したことを確かめる。

   ```bash
   sudo -i bash -c 'printenv DOCKER_HOST; command -v lazydocker'
   ```

   - `unix:///run/podman/podman.sock` と `/home/linuxbrew/.linuxbrew/bin/lazydocker` が出ればよい
   - root 自身の [共通設定](shell-terminal.md#共通の-bash-設定を-root-に入れる)を先に導入する。`/root/.bashrc` への `DOCKER_HOST` の追記は不要
   - 接続先が違う場合はここで止め、既存の用途を確認する

1. 確認用のコンテナを root で動かす。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo podman run -d --name lazydocker-root-web --label name=lazydocker-root-web registry.access.redhat.com/ubi10/httpd-24:latest
     sudo podman ps --filter name=lazydocker-root-web --format '{{.Names}} {{.Status}}'
   }
   ```

   - コンテナの ID の後に、`lazydocker-root-web Up Less than a second` のように出る

1. root で lazydocker を起動し、確認用のコンテナを止める。

   ```bash
   sudo -i lazydocker
   ```

   - `[3]─Containers` に `running  lazydocker-root-web` の行が出る。[手順 3](#lazydocker) の `lazydocker-web` は出ない
   - ↑↓ で `lazydocker-root-web` の行を選び、`s` を押し、`Are you sure you want to stop this container?` に `y` と答える
   - 行が `exited (0)` に変わる
   - `q` で終了する
   - **次の手順は、`q` で終了してから貼る**（続けて貼ると lazydocker への操作として食われる）

1. 確認用のコンテナが止まったことと、root の設定ファイルができたことを確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo podman ps -a --filter name=lazydocker-root-web --format '{{.Names}} {{.Status}}'
     sudo ls -l /root/.config/lazydocker
   }
   ```

   - `lazydocker-root-web Exited (0) ...` と出ればよい
   - `config.yml`（0 バイト）は root の設定ファイル

#### lazydocker: 使い方の基本

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
| `c` | 自分で足したコマンドのメニュー（[podman exec の節](#lazydocker-podman-exec-でシェルを開く)） |
| `x` | 選んでいる枠のキーの一覧 |
| `q` | 終了 |

- `E`（シェル）と `a`（アタッチ）は `docker` コマンドを呼ぶので、podman だけの PC では何も起きない。シェルは `c` から開く
- 画面は英語で出る（lazydocker に日本語の翻訳は無い）

#### lazydocker: 更新

- Homebrew の lazydocker を上げる
- 前提: [lazydocker](#lazydocker)を通してある
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）。Homebrew の更新は root のシェルでは行わない

1. lazydocker を更新する。

   ```bash
   brew upgrade lazydocker
   ```

   - 新しい版が無ければ `Warning: lazydocker 0.25.2 already installed` のように出て、何もしない
   - すべてまとめて上げるなら `brew upgrade`

---

### Distrobox

- EPEL の distrobox を入れ、podman のコンテナでほかのディストリ（既定は Ubuntu 24.04）のボックスを作って入る
- 前提: [Podman](#podman)と[EPEL と RPM Fusion](almalinux-setup.md#epel-と-rpm-fusion)の手順 1 を通してある
  - `podman info --format '{{.Host.Security.Rootless}}'` が `true` を返さない、または `dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に前提を通す
- 実行場所: ホストの、自分のユーザーでログインした bash（GNOME の端末か SSH）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/distrobox.md)・[参考資料](reference/distrobox.md)・[注意点](extra/distrobox.md)
- この項の手順 1 で変数を設定したシェルに貼る
- **手順 2 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）。答えてから手順 3 を貼る
- **手順 5 と 6 はボックスの中のコマンドになる**。手順 5 は終わってから、手順 6 は `exit` で戻ってから、次を貼る

> [!IMPORTANT]
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（ボックスは自分のユーザーの rootless の podman で動かすため）

1. 変数を設定する。

   ```bash
   DBX_NAME=ubuntu                                  # ボックスの名前。<DBX_NAME>
   DBX_IMAGE=quay.io/toolbx/ubuntu-toolbox:24.04    # 元にするイメージ。<DBX_IMAGE>
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%-9s = %s\n' DBX_NAME "${DBX_NAME}" DBX_IMAGE "${DBX_IMAGE}"
   ```

   - **編集が必須の変数は無い**。既定のままなら、Ubuntu 24.04 のボックスができる
   - 別のディストリにするときだけ `DBX_IMAGE` を変える（候補はこの手順の補足）
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. 入手できる版を見てから、distrobox を入れる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   dnf -q list --showduplicates distrobox
   sudo dnf install distrobox
   ```

   - 版は `distrobox.noarch  1.8.2.3-1.el10_2  epel` のように 1 つだけ出る
   - `hicolor-icon-theme` が未導入なら一緒に入る。導入済みなら追加されない
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y` と答える
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. distrobox が入ったか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   distrobox version
   command -v distrobox
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' distrobox
   distrobox list
   ```

   - `distrobox: 1.8.2.3`、`/usr/bin/distrobox`、`distrobox 1.8.2.3-1.el10_2 epel` が出る
   - `distrobox list` は見出しの行だけを出す（ボックスはまだ無い）

1. ボックスを作る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   distrobox create --yes --name "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" --image "${DBX_IMAGE:?手順 1 の DBX_IMAGE が空のまま。値を入れて貼り直す}"
   distrobox list
   ```

   - イメージを取得してから、`Distrobox 'ubuntu' successfully created.` が出る
   - `distrobox list` に、`ubuntu`・`Created`・`quay.io/toolbx/ubuntu-toolbox:24.04` の行が出る
   - `--yes` は、イメージの取得を確かめる問い合わせ（`Do you want to pull the image now? [Y/n]`）を飛ばす

1. 初回の初期化を兼ねて、ボックスの中でコマンドを 1 つ動かす。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- sh -c 'grep PRETTY_NAME /etc/os-release; id -un; pwd'
   ```

   - 初回はボックスの初期化が走る。`[ OK ]` の行が並んだ後に `Container Setup Complete!` が出る
   - その後に `PRETTY_NAME="Ubuntu 24.04.5 LTS"`・自分のユーザー名・`/home/<USER>` が出る
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ボックスのシェルに入る。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}"
   ```

   - プロンプトが `📦[<USER>@ubuntu ~]$` に変わる。ここから先はボックスの中のシェル
   - SSH など画面の無いログインから入ると、`host-spawn: command not found` が出ることがある。出なくても、ボックスのプロンプトに入れればよい
   - `exit` でホストに戻る
   - **ほかの項の手順は、`exit` でホストに戻ってから貼る**

#### Distrobox: ボックスのコマンドをホストから呼ぶ

- 例として、AppStream と EPEL に無い `ffmpeg` を Ubuntu のボックスに入れ、ホストのシェルから `ffmpeg` で呼べるようにする
- ボックスに入れたものはボックスの中にだけある。ホストには、ボックスを呼び出す小さなスクリプトが `~/.local/bin` に置かれる
- 前提: [Distrobox](#distrobox)を通して、ボックスを作ってある
- 実行場所: ホストの、自分のユーザーでログインした bash（GNOME の端末か SSH）。ボックスの中のシェルには貼らない
- **この項の手順 2〜4 は `distrobox enter` で終わる**。プロンプトが戻ってから次を貼る

1. 変数を設定する（既定のままでよい）。

   ```bash
   DBX_NAME=ubuntu                                  # ボックスの名前。<DBX_NAME>
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%-9s = %s\n' DBX_NAME "${DBX_NAME}"
   ```

   - [Distrobox](#distrobox)の手順 1 で `DBX_NAME` を変えたときは、同じ値を入れる
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. ボックスのパッケージの一覧を新しくする。

   ```bash
   distrobox enter "${DBX_NAME:?この項の手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- sudo apt-get update
   ```

   - `Reading package lists...` または `パッケージリストを読み込んでいます... 完了` で終わる
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ボックスに ffmpeg を入れる。

   ```bash
   distrobox enter "${DBX_NAME:?この項の手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- sudo apt-get install -y ffmpeg
   ```

   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ffmpeg をホストから呼べるように書き出す。

   ```bash
   distrobox enter "${DBX_NAME:?この項の手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- distrobox-export --bin /usr/bin/ffmpeg --export-path ~/.local/bin
   ```

   - `/usr/bin/ffmpeg from ubuntu exported successfully in /home/<USER>/.local/bin.` と `OK!` が出る
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ホストのシェルから ffmpeg を呼ぶ。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   command -v ffmpeg
   ~/.local/bin/ffmpeg -version | head -1
   ```

   - 最後の行が `ffmpeg version 6.1.1-3ubuntu5 ...` なら、書き出したコマンドを呼べている
   - `command -v ffmpeg` が `/home/<USER>/.local/bin/ffmpeg` 以外なら、通常の `ffmpeg` は既存の別の版を呼ぶ。ボックスの版を使うときは `~/.local/bin/ffmpeg` で呼ぶ

#### Distrobox: 更新

- distrobox と、ボックスの中のパッケージを上げる
- 前提: [Distrobox](#distrobox)を通して、ボックスを作ってある
- 実行場所: ホストの、自分のユーザーでログインした bash（GNOME の端末か SSH）。ボックスの中のシェルには貼らない

1. 変数を設定する（既定のままでよい）。

   ```bash
   DBX_NAME=ubuntu                                  # ボックスの名前。<DBX_NAME>
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%-9s = %s\n' DBX_NAME "${DBX_NAME}"
   ```

   - [Distrobox](#distrobox)の手順 1 で `DBX_NAME` を変えたときは、同じ値を入れる
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. distrobox を更新する。

   ```bash
   sudo dnf upgrade distrobox
   ```

   - システム全体なら `sudo dnf upgrade`
   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. ボックスの中のパッケージを更新する。

   ```bash
   distrobox upgrade "${DBX_NAME:?この項の手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}"
   ```

   - **ボックスの中身は `dnf upgrade` では上がらない**。ボックスごとにこの手順を行う
   - **ほかの項の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

---
