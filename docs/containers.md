# コンテナのセットアップ（AlmaLinux 10）

- AlmaLinux 10 で、Podman とその周りの道具（podman-compose・podman-tui・lazydocker）と Distrobox を入れて使う
- 検証記録・参考資料・注意点は、各用途の末尾の「補足と注意点」の折りたたみから開く

> [!IMPORTANT]
> - **前提と実行場所（ユーザー・端末・別のマシン）は、各項のリードに従う**。`sudo -i`・`su -` のシェルでは行わない
> - AlmaLinux 10 の項は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)と同じく、パスワードを聞かない `sudo` を前提に書いてある。各項のリードの前提に無くても、その項を行うユーザーで[ログインと sudo](almalinux-setup.md#ログインと-sudo)を先に通す

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- bash のブロックは、ブラケットペーストの効く端末（GNOME の端末・WezTerm・SSH の先）に貼り、貼った後に Enter を押す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- 入れたものは、[Podman: 更新](#podman-更新)・[podman-compose: 更新](#podman-compose-更新)・[podman-tui: 更新](#podman-tui-更新)・[lazydocker: 更新](#lazydocker-更新)・[Distrobox: 更新](#distrobox-更新)で上げる

## AlmaLinux 10 で使う

- Podman とその周りの道具（podman-compose・podman-tui・lazydocker）と Distrobox

### Podman

- AppStream の podman を入れ、自分のユーザー（rootless）でコンテナを動かせるようにする
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)を通してある
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- 導入後は、必要な[コンテナ用ツール](tool-catalog.md#cli-コンテナ)を追加する

> [!IMPORTANT]
> - **自分のユーザーでログインした bash（デスクトップの端末か SSH）で行う**
> - `sudo -i` の root のシェルや、`sudo -iu <ユーザー>` で切り替えたシェルでは行わない

1. podman が入っているか確かめる。

   ```bash
   rpm -q podman || echo 'podman は未導入'
   ```

   - podman の版が出れば、手順 2 は飛ばす
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

   - subuid と subgid の両方に自分の割り当てが出れば、手順 4 は飛ばす
   - 片方でも `自分の割り当てが無い` と出たら、手順 4 で不足している側だけ割り当てる

1. 片方でも割り当てが無いときだけ、不足する側に範囲を割り当て、podman に読み直させる。

   ```bash
   # ユーザーと割り当ての範囲を確認する
   if [ -z "${USER}" ] || [ "${USER}" = root ]; then echo '中断: 自分のユーザーのシェルで貼る' >&2
   elif SUBID_START=$(awk -F: '{ e = $2 + $3; if (e > m) m = e } END { print (m > 524288 ? m : 524288) }' /etc/subuid /etc/subgid); then
     # 不足する UID・GID の割り当てを組み立てる
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
   # 版と実行ファイルの場所を確認する
   podman version --format '{{.Client.Version}}'
   command -v podman
   # rootless の動作設定と保存先を確認する
   podman info --format '{{.Host.Security.Rootless}} {{.Store.GraphDriverName}} {{.Host.OCIRuntime.Name}} {{.Host.NetworkBackend}} {{.Host.RootlessNetworkCmd}} {{.Host.CgroupsVersion}}'
   podman info --format '{{.Store.GraphRoot}}'
   ```

   - 実行ファイルが `/usr/bin/podman` で、rootless が `true` ならよい

1. イメージを完全な名前で指定して、コンテナを 1 つ動かす。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # コンテナを実行する
   podman run --rm quay.io/podman/hello
   # 取得したイメージを確認する
   podman images
   ```

   - `Hello Podman World` と、取得したイメージの行が出ればよい

1. API ソケットを有効にして、応答を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # API ソケットを有効にして稼働状態を確認する
   systemctl --user enable --now podman.socket
   systemctl --user is-active podman.socket
   # API の応答とサーバーの版を確認する
   curl -s --unix-socket "${XDG_RUNTIME_DIR}/podman/podman.sock" http://d/_ping; echo
   podman --remote version --format '{{.Server.Version}}'
   ```

   - `active`・`OK` とサーバーの版が出ればよい
   - `Failed to connect to user scope bus` と出たら、`sudo -iu` などで切り替えたシェルで実行している。自分のユーザーでログインし直す

#### Podman: Docker 向けのツールから使う

- Docker の API に `DOCKER_HOST` でつなぐツール（[lazydocker](#lazydocker) など）のための設定
- 前提: [Podman](#podman)と[共通の bash 設定](shell-terminal.md#共通の-bash-設定)を通してある
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- [画像の道具](almalinux-setup.md#画像の道具) の dive と Trivy、[podman-tui](#podman-tui) は podman を直接読むので、この項は要らない

1. 共通設定を読み直し、ソケットが Docker の API に答えるか確かめる。

   ```bash
   # 共通の bash 設定を再読込する
   . ~/.bashrc
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%s\n' "${DOCKER_HOST-}"
   curl -s --unix-socket "${DOCKER_HOST#unix://}" http://d/version | grep -o '"Name":"Podman Engine"'
   ```

   - `unix:///run/user/…/podman/podman.sock` と `"Name":"Podman Engine"` が出ればよい
   - 既に別の値がある場合は上書きせず、その用途を確認する
   - `~/.bashrc` には追記しない

#### Podman: Quadlet で自動起動する

- 確認用に、`registry.access.redhat.com/ubi10/httpd-24`（Apache）を `127.0.0.1:8080` で動かす
- 前提: [Podman](#podman)と[ユーザーサービスの常駐](almalinux-setup.md#ユーザーサービスの常駐)（linger）を通してある
  - `loginctl show-user "$(id -u)" -p Linger` が `Linger=yes` でなければ、先に通す
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）

1. 確認用の Web サーバーの定義とページを置く。

   ```bash
   # Web ページを作成する
   mkdir -p ~/hello-web ~/.config/containers/systemd
   echo 'hello from quadlet' > ~/hello-web/index.html
   # Quadlet の定義を作成する
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
   # 定義を再読込してサービスを起動する
   systemctl --user daemon-reload
   systemctl --user start hello-web.service
   printf '\n\033[7m 確認 \033[0m\n'
   # サービスの稼働状態と登録状態を確認する
   systemctl --user is-active hello-web.service
   systemctl --user is-enabled hello-web.service
   # Web サーバーの応答を確認する
   curl -s --retry 10 --retry-delay 1 --retry-all-errors http://127.0.0.1:8080/
   ```

   - `active`・`generated`・`hello from quadlet` が出ればよい
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
   # サービスの起動時刻とログイン時刻を確認する
   systemctl --user show hello-web.service -p ActiveEnterTimestamp
   loginctl show-session "${XDG_SESSION_ID}" -p Timestamp
   # Web サーバーの応答を確認する
   curl -s http://127.0.0.1:8080/
   ```

   - 1 行目の時刻（サービスが起動した時刻）が、2 行目の時刻（ログインした時刻）より前ならよい
   - `hello from quadlet` が出る

#### Podman: 使い方の基本

| コマンド | 用途 |
|---|---|
| `podman ps -a` | コンテナの一覧（止まっているものも） |
| `podman images` | イメージの一覧 |
| `podman run -d --name <名前> -p 127.0.0.1:<ポート>:<ポート> <イメージ>` | 裏で動かす。自分のユーザーでは 1024 未満のポートを使えない（[Podman の補足と注意点](#podman-の補足と注意点)の「注意点」） |
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
   - **次の手順は、答えて完了してから貼る**（続けて貼ると、更新を断っても後ろの新しいイメージの確かめが動く）

1. [Quadlet で自動起動する](#podman-quadlet-で自動起動する)を通したときだけ、新しいイメージがあるかを見る。

   ```bash
   podman auto-update --dry-run
   ```

   - `UPDATED` の列が `true` の行が無ければ、新しいイメージは無い。この項の手順 3 は飛ばす
   - **次の手順は、`UPDATED` の列を確かめてから貼る**（続けて貼ると、新しいイメージがあれば、確かめる前に当ててサービスを起動し直す）

1. [Quadlet で自動起動する](#podman-quadlet-で自動起動する)を通していて、新しいイメージがあったときだけ、イメージを当てる。

   ```bash
   podman auto-update
   ```

   - `UPDATED` が `true` の行のサービスが、新しいイメージで起動し直す

<details id="podman-の補足と注意点">
  <summary>Podman の補足と注意点</summary>

**注意点**

- **イメージは完全な名前で書く**: 短い名前は、端末から実行すると取る場所を聞かれる（この折りたたみの「参照」）
- **`sudo podman` は別の保管場所**: 自分のユーザーのコンテナとイメージは、`sudo podman` からは見えない（[使い方の基本](#podman-使い方の基本)）
  - root のコンテナを lazydocker で見るなら、[lazydocker: root でも使う](#lazydocker-root-でも使う)の節（システムの API ソケットを使う）
- **1024 未満のポートは使えない**: 自分のユーザーで `-p 127.0.0.1:80:8080` のように指定すると、次のように失敗する
  - `Error: pasta failed with exit code 1:` と `Failed to bind port 80 (Permission denied) for option '-t 127.0.0.1/80-80:8080-8080'`
  - `sysctl net.ipv4.ip_unprivileged_port_start` は `1024`。8080 など 1024 以上の番号にする
- **linger が無いと、ログアウトでコンテナが止まる**: 止めたくないものは Quadlet の節で動かし、[linger](almalinux-setup.md#ユーザーサービスの常駐) を有効にする
- **容量**: イメージは `~/.local/share/containers/storage` に溜まる。`podman system df` で見て、`podman image prune -a` で掃除する（`ubi10/httpd-24` は 285 MB）
- **Docker Hub には、認証なしの取得に回数の上限がある**: 本書の例は quay.io と registry.access.redhat.com に寄せた
- **aarch64 のホストで使うイメージは arm64 があるか見る**: `podman manifest inspect <イメージ>` に `"architecture": "arm64"` があればよい。本書の例のイメージにはどれもある
- **Homebrew の formula が podman を連れてくることがある**: podman-compose などを Homebrew で入れると、依存の podman が `/usr/bin/podman` を隠す（[ツール一覧](tool-catalog.md#注意点)）
  - システムの podman との互換性が要るものや、別の podman を依存で入れるものは RPM を選ぶ
  - [画像の道具](almalinux-setup.md#画像の道具) の hadolint・dive と [lazydocker](#lazydocker) は、RPM の提供状況などを比べて Homebrew を選んでいる
- [Podman](#podman)の手順 7 の API ソケットにつなげると、自分のコンテナを何でも操作できる。ソケットの権限（`srw-rw----`、持ち主は自分）を変えない
- [Podman: Quadlet で自動起動する](#podman-quadlet-で自動起動する)の手順 1 の `:Z` は指定したディレクトリの SELinux ラベルを付け替える。ホーム全体やシステムのディレクトリには付けず、コンテナ用の `~/hello-web` だけに付ける
- [Podman: Quadlet で自動起動する](#podman-quadlet-で自動起動する)の手順 3 で再起動すると、SSH の接続は切れる

**[Podman](#podman)の手順 1**

- `podman-5.8.2-...` のように版が出れば、手順 2 は飛ばす

**[Podman](#podman)の手順 1: Server の環境では最初から入っている**

実測は検証記録（`docs/verification/podman.md` の「実施手順 / 手順 1: 補足: Server の環境では最初から入っている」）

AlmaLinux 10 のインストーラのグループ定義（AppStream の comps）では、Server と Server with GUI の環境に「コンテナー管理」（`container-management`）のグループが入っている。

- このグループの必須パッケージは `podman` と `buildah`。この 2 つの環境で入れた PC には、podman が最初から入っている
- Workstation と Minimal Install の環境には、このグループが無い

**[Podman](#podman)の手順 2: 一緒に入るものと、container-tools を使わない理由**

| パッケージ | 役割 |
|---|---|
| `crun` | コンテナを実際に起動するランタイム（OCI ランタイム） |
| `conmon` | コンテナごとに付き添い、ログと終了コードを受け取る |
| `netavark` / `aardvark-dns` | コンテナのネットワークと、コンテナ名での名前解決 |
| `passt` | rootless のネットワーク（`pasta`）。ポートの公開もここを通る |
| `containers-common` | `/etc/containers` の設定（レジストリ、署名の方針、保管の方式） |
| `shadow-utils-subid` | subuid / subgid を読むライブラリ（手順 3） |
| `criu` | コンテナのチェックポイントと復元（本書では使わない） |

AppStream には、podman・buildah・skopeo・toolbox・cockpit-podman・podman-docker・udica などをまとめて入れるメタパッケージ `container-tools` もある。

- 本書は podman だけを入れ、ほかは[ツール一覧](tool-catalog.md#cli-コンテナ)から要るものを足す形にした

**[Podman](#podman)の手順 3**

- `/etc/subuid:<USER>:524288:65536` と `/etc/subgid:<USER>:524288:65536` のような 2 行が出れば、手順 4 は飛ばす

**[Podman](#podman)の手順 4: 割り当てる範囲**

- `SUBID_START=` の行で、登録済みの範囲のいちばん後ろ（1 つも無ければ 524288）を始まりにする
- `usermod` の行で、そこから 65536 個を不足する側だけに割り当てる。既存の UID・GID の範囲は変更しない
- `podman system migrate` は、それまでに podman を使っていたときに、新しい範囲を反映させる

**[Podman](#podman)の手順 5**

- `5.8.2` と `/usr/bin/podman` が出る
- 3 行目が `true overlay crun netavark pasta v2` なら、自分のユーザー（rootless）で動く
- イメージとコンテナは、4 行目の場所（`/home/<USER>/.local/share/containers/storage`）に入る

**[Podman](#podman)の手順 5: podman info の読み方**

3 行目の 6 つの値の意味:

| 値 | 意味 |
|---|---|
| `true` | rootless（自分のユーザー）で動いている |
| `overlay` | イメージの層を重ねて保管する方式 |
| `crun` | OCI ランタイム |
| `netavark` | コンテナのネットワーク |
| `pasta` | rootless のネットワークと、ポートの公開 |
| `v2` | cgroup v2 |

**[Podman](#podman)の手順 6**

- `!... Hello Podman World ...!` から始まる絵と案内が出る
- `podman images` に `quay.io/podman/hello` の行が出る
- **イメージはレジストリの名前から書く**（`quay.io/...`、`registry.access.redhat.com/...`）。短い名前の扱いは、この折りたたみの「注意点」で確かめる

**[Podman](#podman)の手順 7**

- 初めて有効にしたときは、その前に `Created symlink '/home/<USER>/.config/systemd/user/sockets.target.wants/podman.socket' → '/usr/lib/systemd/user/podman.socket'.` の行が 1 つ出る
- `active`・`OK`・`5.8.2` が出ればよい

**[Podman](#podman)の手順 7: このソケットを使うもの**

- [Trivy](almalinux-setup.md#画像の道具)、[podman-tui](#podman-tui)、[lazydocker](#lazydocker)、GUI の Pods・Podman Desktop

**[Podman: Docker 向けのツールから使う](#podman-docker-向けのツールから使う)のリード**

- `DOCKER_HOST` は共通の bash 設定が入れる。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

**[Podman: Docker 向けのツールから使う](#podman-docker-向けのツールから使う)の手順 1: 共通設定とソケット**

- 共通設定はソケットがあるときだけ `DOCKER_HOST` を入れる
- ソケットの有効化は[Podman](#podman)の手順 7 で行う

**[Podman: Quadlet で自動起動する](#podman-quadlet-で自動起動する)のリード**

- Quadlet は、`~/.config/containers/systemd` に置いた定義から、ユーザーの systemd のサービスを作る仕組み。podman に含まれている
- この項の手順 3 で再起動する
- `podman run -d` で動かしたコンテナは、PC を再起動すると戻らない。linger が無いと、ログアウトしただけで止まる（この折りたたみの「注意点」）

**[Podman: Quadlet で自動起動する](#podman-quadlet-で自動起動する)の手順 1: 定義の中身**

| 行 | 意味 |
|---|---|
| `Image=` | イメージ。完全な名前で書く（[Podman](#podman)の手順 6） |
| `ContainerName=` | コンテナの名前。`podman ps` に出る |
| `PublishPort=127.0.0.1:8080:8080` | この PC の 127.0.0.1 の 8080 を、コンテナの 8080 につなぐ。`127.0.0.1:` を付けているので、この PC の中からしか開けない |
| `Volume=%h/hello-web:/var/www/html:Z` | ホームの `hello-web` を、コンテナの公開ディレクトリにする。`%h` はホームディレクトリ |
| `AutoUpdate=registry` | `podman auto-update` の対象にする（[更新](#podman-更新)） |
| `TimeoutStartSec=300` | 初回はイメージの取得を待つので、起動の待ち時間を延ばす |
| `WantedBy=default.target` | ユーザーの systemd が起動したときに、このサービスも起動する |

**[Podman: Quadlet で自動起動する](#podman-quadlet-で自動起動する)の手順 2**

- 初回の `start` は、数十秒かかることがある

**[Podman: Quadlet で自動起動する](#podman-quadlet-で自動起動する)の手順 2: 起動の待ち時間と、enable を使わない理由**

- 初回の `start` に数十秒かかるのは、イメージの取得を待つため
- `start` から戻った直後は、Apache がまだ待ち受けていないことがある。curl は、応答が来るまで 1 秒おきに 10 回まで試し直す
- `systemctl --user enable` を使わないのは、自動で起動するかが定義の `[Install]` で決まるため

**[Podman: 使い方の基本](#podman-使い方の基本)のリード**

- `sudo podman` は root 用の別の保管場所（`/var/lib/containers`）を使うので、自分のコンテナもイメージも見えない

**参照**

- 検証記録（`docs/verification/podman.md`）
- [Basic Setup and Use of Podman in a Rootless environment](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md) — rootless の前提（subuid / subgid、保管場所、ネットワーク）
- [podman-systemd.unit(5)](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) — Quadlet の定義の書き方
- [podman-auto-update(1)](https://docs.podman.io/en/latest/markdown/podman-auto-update.1.html) / [podman-system-service(1)](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html) / [podman-system-reset(1)](https://docs.podman.io/en/latest/markdown/podman-system-reset.1.html)
- [podman-run(1)](https://docs.podman.io/en/latest/markdown/podman-run.1.html) — `--volume` の `:Z`、`--publish`
- [RHEL 10 — Building, running, and managing containers](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/building_running_and_managing_containers/index) — RHEL の podman の文書
- `man containers-registries.conf` — 短い名前の扱い（`unqualified-search-registries`・`short-name-mode`）
- [linger](almalinux-setup.md#ユーザーサービスの常駐) — [Quadlet の節](#podman-quadlet-で自動起動する)の前提の手順書

</details>

---

### podman-compose

- EPEL の podman-compose を入れ、compose ファイルで 2 つのコンテナを動かして確かめる
- 前提: [Podman](#podman)と[EPEL と RPM Fusion](almalinux-setup.md#epel-と-rpm-fusion)の手順 1 を通してある
  - `podman info --format '{{.Host.Security.Rootless}}'` が `true` を返さない、または `dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に前提を通す
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）

- PC を再起動しても動かしておきたいものは、compose ではなく [Podman の Quadlet](#podman-quadlet-で自動起動する) で動かす（[podman-compose の補足と注意点](#podman-compose-の補足と注意点)の「注意点」）

> [!IMPORTANT]
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（コンテナを自分のユーザーの rootless の podman で動かすため）

1. podman-compose を導入し、版と呼び出し先を確認する。

   ```bash
   # 配布されている版を確認する
   dnf -q list --showduplicates podman-compose
   # podman-compose を導入する
   sudo dnf install podman-compose
   printf '\n\033[7m 確認 \033[0m\n'
   # 導入した版と実行ファイルの場所を確認する
   podman-compose version
   command -v podman-compose
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' podman-compose
   # podman compose の呼び出し先を確認する
   podman compose version
   ```

   - トランザクション表の内容を確かめ、`[y/N]` に `y` と答える
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y` と答える
   - `/usr/bin/podman-compose` と、podman-compose・podman の版が出ればよい

1. 確認用の compose ファイルとページを置く。

   ```bash
   # 確認用の Web ページを作成する
   mkdir -p ~/compose-sample/html
   echo 'hello from compose' > ~/compose-sample/html/index.html
   # compose ファイルを作成して確認する
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
   # compose の作業ディレクトリへ移動する
   cd ~/compose-sample
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose up -d
   ```

   - `web` と `check` のコンテナ名が出ればよい

1. 起動したコンテナと、公開したポートを確かめる。

   ```bash
   # compose の作業ディレクトリへ移動する
   cd ~/compose-sample
   printf '\n\033[7m 確認 \033[0m\n'
   # コンテナと pod の稼働状態を確認する
   podman-compose ps
   podman pod ps
   # Web サーバーの応答を確認する
   curl -s --retry 10 --retry-delay 1 --retry-all-errors http://127.0.0.1:8081/
   ```

   - `web` と `check` が `Up`、pod が `Running` で、Web の公開ポートが出ればよい
   - `hello from compose` が出ればよい

1. `check` のコンテナから、サービス名 `web` でつながるか確かめる。

   ```bash
   # compose の作業ディレクトリへ移動する
   cd ~/compose-sample
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose exec check curl -s http://web:8080/
   ```

   - `hello from compose` が出ればよい
   - **ほかの項の手順は、プロンプトが戻ってから貼る**（終わる前に貼ると、動いているコマンドへの入力になる）

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
   - **次の手順は、答えて完了してから貼る**（続けて貼ると、更新を断ってもイメージの取得とコンテナの起動し直しが動く）

1. イメージを取り直し、新しいイメージでコンテナを起動し直す。

   ```bash
   # compose のイメージを取得する
   cd ~/compose-sample
   podman-compose pull
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose up -d
   ```

<details id="podman-compose-の補足と注意点">
  <summary>podman-compose の補足と注意点</summary>

**注意点**

- **`podman-compose exec` の実行中に新たに貼った文字は、コンテナへの入力になる**。同じ入力として最初に貼ったホスト用の後ろの行は、`exec` の終了後に元のシェルで動く
  - `-T` は擬似端末を付けないだけで、標準入力はつながったままなので、実行中に新たに貼る文字の入力を止める用途には使わない
- **PC の再起動では戻らず、linger が無いとログアウトで止まる**: compose で起動したコンテナは、ふつうの `podman run -d` と同じ（[Podman の補足と注意点](#podman-の補足と注意点)の「注意点」）。常駐させるものは Quadlet にし、[linger](almalinux-setup.md#ユーザーサービスの常駐) を有効にする
- **プロジェクトの名前はディレクトリの名前**: 同じ名前のディレクトリで別の compose ファイルを動かすと、同じ名前の pod・ネットワークを使う。`-p <名前>` で変えられる
- **1024 未満のポートは使えない**: rootless の podman と同じ制限（[Podman の補足と注意点](#podman-の補足と注意点)の「注意点」）
- この項の手順 2 の `:Z` はコンテナ用の `~/compose-sample/html` だけに付ける。ホーム全体やシステムのディレクトリには付けない
- この項の `down -v` は、名前付きのボリュームの中のデータも消す。ボリュームを残すときは `down` だけにする

**[podman-compose](#podman-compose)のリード**

- **手順 1 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）
- **手順 5 の `podman-compose exec` は、動いている間に貼った行をコンテナへの入力として取り込む**。プロンプトが戻ってから次を貼る。次をコンテナの中で動かす場合は、コンテナのシェルを開いてから別に貼る

**[podman-compose](#podman-compose)の手順 1**

- 版は `podman-compose.noarch  1.5.0-1.el10_1  epel` のように 1 つだけ出る
- 一緒に入るのは未導入の Python のライブラリで、最大 4 つ（`python3-click`・`python3-dotenv`・`python3-dotenv+cli`・`python3-pyyaml`）
- `podman-compose version 1.5.0` と `podman version 5.8.2` の 2 行が出る
- `/usr/bin/podman-compose`、`podman-compose 1.5.0-1.el10_1 epel` が出る
- 最後の `podman compose` は、`Executing external compose provider "/usr/bin/podman-compose"` と出してから、同じ 2 行を出す
- EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる

**[podman-compose](#podman-compose)の手順 1: 署名鍵**

- fingerprint を確かめる EPEL の鍵は、[AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」の手順 1](almalinux-setup.md#epel-と-rpm-fusion) に書いた鍵

**[podman-compose](#podman-compose)の手順 1: podman compose**

- `podman compose` は podman のサブコマンド

**[podman-compose](#podman-compose)の手順 2: compose ファイルの中身**

- `web` は Apache で、`127.0.0.1:8081` で開く。ページは `~/compose-sample/html` から読む
- `check` は、`web` にサービス名でつながるかを確かめるためだけのコンテナ（同じイメージなので、取得は 1 回で済む）

**[podman-compose](#podman-compose)の手順 3**

- 最後に `compose-sample_web_1` と `compose-sample_check_1` が出る

**[podman-compose](#podman-compose)の手順 3: up -d が作るもの**

podman-compose は、ディレクトリの名前（`compose-sample`）をプロジェクトの名前にして、次を作る。

| 作るもの | 名前 |
|---|---|
| pod | `pod_compose-sample` |
| ネットワーク | `compose-sample_default` |
| コンテナ | `compose-sample_web_1`・`compose-sample_check_1` |

- 同じネットワークのコンテナ同士は、サービス名（`web`・`check`）で名前が引ける（[podman-compose](#podman-compose)の手順 5）
- `-d` を付けないと、ログを表示したまま前で動き続ける

**[podman-compose](#podman-compose)の手順 3: 初回のイメージの取得**

- 初回はイメージ（285 MB）を取得する

**[podman-compose](#podman-compose)の手順 4**

- `podman-compose ps` に 2 つのコンテナが `Up` で出て、`web` の `PORTS` に `127.0.0.1:8081->8080/tcp` が出る
- `podman pod ps` に `pod_compose-sample` が `Running` で出る

**[podman-compose](#podman-compose)の手順 4: curl の試し直し**

- curl は、Apache が待ち受けるまで 1 秒おきに 10 回まで試し直す

**[podman-compose](#podman-compose)の手順 5: サービス名で引ける**

- `hello from compose` が出れば、`web` という名前が、compose のネットワークの中で引けている

**[podman-compose: 更新](#podman-compose-更新)の手順 2**

- 新しいイメージが無いときも、`up -d` はコンテナの名前を出して終わる

**[podman-compose: 更新](#podman-compose-更新)の手順 2: pull と up -d**

- `pull` がイメージを取り直し、`up -d` がコンテナを作り直す

**参照**

- 検証記録（`docs/verification/podman-compose.md`）
- [containers/podman-compose — README](https://github.com/containers/podman-compose) — 対応している compose の機能と、オプション
- [Compose Specification](https://compose-spec.io/) — compose ファイルの書式
- `man podman-compose`（podman のパッケージに入っている `podman compose` の説明）/ `podman-compose --help` / `podman-compose <サブコマンド> --help`
- [Podman](#podman) — 前提の rootless の podman と、自動起動の Quadlet
- [AlmaLinux 10 の初期設定](almalinux-setup.md) — 前提の EPEL の有効化（「EPEL と RPM Fusion」の手順 1）

</details>

---

### podman-tui

- EPEL の podman-tui を入れ、確認用のコンテナを画面（TUI）から止めて確かめる
- 前提: [Podman](#podman)の手順 7（API ソケット）までと、[EPEL と RPM Fusion](almalinux-setup.md#epel-と-rpm-fusion)の手順 1 を通してある
  - `systemctl --user is-active podman.socket` が `active` を返さない、または `dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に前提を通す
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- Docker の API でつなぐ TUI なら [lazydocker](#lazydocker)
- EPEL 版と Homebrew の 2.x は二重に入れない。podman の版に合うものを選ぶ

> [!IMPORTANT]
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（podman-tui は、自分のユーザーの API ソケットにつなぐため）

1. podman-tui を導入し、版と実行ファイルの場所を確認する。

   ```bash
   # 配布されている版を確認する
   dnf -q list --showduplicates podman-tui
   # podman-tui を導入する
   sudo dnf install podman-tui
   printf '\n\033[7m 確認 \033[0m\n'
   podman-tui version
   command -v podman-tui
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' podman-tui
   ```

   - トランザクション表の内容を確かめ、`[y/N]` に `y` と答える
   - fingerprint `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）なら `y`、違えば `N` で中断する
   - `/usr/bin/podman-tui` と版が出ればよい

1. 画面で操作する、確認用のコンテナを動かす。

   ```bash
   # 確認用のコンテナを起動する
   podman run -d --name podman-tui-web registry.access.redhat.com/ubi10/httpd-24:latest
   printf '\n\033[7m 確認 \033[0m\n'
   podman ps --filter name=podman-tui-web --format '{{.Names}} {{.Status}}'
   ```

   - `podman-tui-web` が `Up` ならよい

1. podman-tui でコンテナを停止し、結果を確認する。

   ```bash
   # podman-tui を起動する
   podman-tui
   printf '\n\033[7m 確認 \033[0m\n'
   podman ps -a --filter name=podman-tui-web --format '{{.Names}} {{.Status}}'
   ```

   - 接続が `STATUS_OK`・`connected` ならよい
   - `F4` でコンテナの画面（`CONTAINERS[N]`）に移り、↑↓ で `podman-tui-web` の行を選ぶ
   - `m` でコマンドのメニューを開き、↓ で `stop` まで下りて Enter を押す（確認は出ない）
   - `Ctrl+C` で終了する
   - `podman-tui-web` が `Exited (0)` ならよい

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
   - EPEL の podman-tui が 2.x に上がったときは、上流の互換表で podman の版と合うかを確かめる（[podman-tui の補足と注意点](#podman-tui-の補足と注意点)の「注意点」）

<details id="podman-tui-の補足と注意点">
  <summary>podman-tui の補足と注意点</summary>

**注意点**

- **終了は `Ctrl+C`**: `q` を押しても何も起きない
- **API ソケットが止まっていると、つながらない**: `❌ STATUS_ERROR` とエラーの枠が出る（この折りたたみの「podman-tuiの手順 3: 画面の中身と、つながらないとき」）。`systemctl --user start podman.socket` で直る
- **podman に接続を登録していると、そちらを使う**: `podman system connection add` で登録した接続があると、podman-tui は `localhost` の代わりにそれを出す
  - 接続を消す（`podman system connection remove`）と、`localhost` に戻る
- **Homebrew の 2.x と二重に入れない**: `brew install podman-tui` の 2.0.0 は `/home/linuxbrew/.linuxbrew/bin` に入り、PATH の先頭で `/usr/bin/podman-tui` を隠す
  - 2.0.0 は接続を podman の設定からだけ読むため、使う場合は先に接続を登録する
  - 2.0.0 と podman 5.8.2 は上流の互換表の外の組み合わせなので、互換表に合う版を選ぶ
- **EPEL が 2.x に上がったら、互換表を確かめる**: 2.x は podman 6 向け。AlmaLinux の podman が 5.x のうちに EPEL だけが上がったら、動きを確かめてから使う

**[podman-tui](#podman-tui)のリード**

- **手順 1 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）
- **手順 3 で podman-tui の画面（TUI）が開く**。`Ctrl+C` で終了する（`q` では終わらない）
- lazydocker との違いは検証記録（`docs/verification/podman-tui.md` の「選択した方針」）で確かめる

**[podman-tui](#podman-tui)の手順 1**

- 版は `podman-tui.x86_64  1.10.0-1.el10_2  epel` のように 1 つだけ出る
- 入るのは `podman-tui` の 1 パッケージだけ（ダウンロード 9.5 MB、展開後 32 MB）
- `podman-tui v1.10.0`、`/usr/bin/podman-tui`、`podman-tui 1.10.0-1.el10_2 epel` が出る
- EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる

**[podman-tui](#podman-tui)の手順 1: 依存と、podman との関係**

podman-tui は Go で書かれた 1 つの実行ファイルで、`rpm -q --requires podman-tui` に出る依存は glibc（`libc.so.6`・`libresolv.so.2`）だけ。

**[podman-tui](#podman-tui)の手順 1: 署名鍵**

- fingerprint を確かめる EPEL の鍵は、[AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」の手順 1](almalinux-setup.md#epel-と-rpm-fusion) に書いた鍵

**[podman-tui](#podman-tui)の手順 2**

- `podman-tui-web Up Less than a second` のように出る

**[podman-tui](#podman-tui)の手順 2: 確認用のコンテナ**

- 初回はイメージ（285 MB）を取得する。[Podman: Quadlet で自動起動する](#podman-quadlet-で自動起動する) などで取得済みなら、取り直さない
- ポートは公開しない（画面から止めるためだけのコンテナ）

**[podman-tui](#podman-tui)の手順 3**

- 最初に SYSTEM の画面が開き、上の `Connection:` に `✅ STATUS_OK`、`API version:` に `5.8.2` が出る
- その下の `SYSTEM CONNECTIONS[1]` に、`localhost` が `✅ connected` で出る
- 数秒で、`STATUS` が `▼ Exited (0) ...` に変わる
- `podman-tui-web Exited (0) ...` と出ればよい

**[podman-tui](#podman-tui)の手順 3: 画面の中身と、つながらないとき**

実測は検証記録（`docs/verification/podman-tui.md` の「実施手順 / 手順 4: 補足: 画面の中身と、つながらないとき」）

- `localhost` は、podman-tui が `XDG_RUNTIME_DIR` から作る既定の接続。設定ファイルは要らない
- `unix://run/...` とスラッシュが 2 つなのは podman-tui の書き方で、つながっている
- `m` のメニューは、`attach`・`checkpoint`・`commit`・`create`・`diff`・`exec`・`healthcheck`・`inspect`・`kill`・`logs`・`pause`・`port`・`prune`・`rename`・`restore`・`rm`・`run`・`start`・`stats`・`stop`・`top`・`unpause` の順。1.10.0 には、項目を選ぶキーの割り当ては無い

API ソケットが止まっていると、`Connection:` が `❌ STATUS_ERROR` に、`localhost` が `❌ connection error` になり、次のエラーの枠が出る:

```text
unable to connect to Podman socket: Get "http://d/v5.7.1/
libpod/_ping": dial unix /run//user/<UID>/podman/
podman.sock: connect: connection refused
```

- `Ctrl+C` で終了し、`systemctl --user start podman.socket` で起動し直す
- `v5.7.1` は、podman-tui が使っている podman の API の版（1.10.0 は podman 5.7.1 の部品で作られている）

**[podman-tui](#podman-tui)の手順 3: podman でも確かめる理由**

- `podman-tui-web Exited (0) ...` と出れば、画面の操作が API を通して podman に届いている

**[podman-tui: 使い方の基本](#podman-tui-使い方の基本)のリード**

- 画面での操作は API を通るので、結果はそのまま `podman ps` などにも出る

**参照**

- 検証記録（`docs/verification/podman-tui.md`）
- [containers/podman-tui — README（v1.10.0）](https://github.com/containers/podman-tui/blob/v1.10.0/docs/README.md) — 互換表、API ソケットの前提、キーの一覧
- [podman-tui v2.0.0 のリリースノート](https://github.com/containers/podman-tui/releases/tag/v2.0.0) — podman v6 への対応、接続を podman の設定からだけ読むこと
- `podman-tui --help`、画面の `F1`
- [Podman](#podman) — 前提の rootless の podman と API ソケット
- [AlmaLinux 10 の初期設定](almalinux-setup.md) — 前提の EPEL の有効化（「EPEL と RPM Fusion」の手順 1）

</details>

---

### lazydocker

- Homebrew の lazydocker を入れ、podman の API ソケットにつないで、確認用のコンテナを画面（TUI）から止める
- 前提: [共通の bash 設定](shell-terminal.md#共通の-bash-設定)、[Homebrew](almalinux-setup.md#homebrew)の手順 1〜2、[Podman](#podman)の手順 7（API ソケット）まで、[Podman: Docker 向けのツールから使う](#podman-docker-向けのツールから使う)を通してある
  - `command -v brew podman` が 2 行を返さない、または `echo "${DOCKER_HOST}"` が `unix:///run/user/<UID>/podman/podman.sock` を返さなければ、先に前提を通す
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）
- pod やシークレットも画面で扱うなら [podman-tui](#podman-tui)

> [!IMPORTANT]
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、lazydocker も自分のユーザーの API ソケットにつなぐため）

1. lazydocker を導入し、版と接続先を確認する。

   ```bash
   # lazydocker を導入する
   brew install lazydocker
   printf '\n\033[7m 確認 \033[0m\n'
   # 版と実行ファイルの場所を確認する
   lazydocker --version
   command -v lazydocker
   # API の接続先と応答を確認する
   echo "${DOCKER_HOST}"
   curl -s --unix-socket "${DOCKER_HOST#unix://}" http://d/_ping; echo
   ```

   - 依存の追加を確認する `[y/n]` などが出たら、内容を見て答える
   - 実行ファイルが `/home/linuxbrew/.linuxbrew/bin/lazydocker` で、版が出ればよい
   - 接続先が自分の podman のソケットで、`OK` が出ればよい
   - 3 行目が空なら、`DOCKER_HOST` が無い。[Podman: Docker 向けのツールから使う](#podman-docker-向けのツールから使う)を通す

1. 画面で操作する、確認用のコンテナを動かす。

   ```bash
   # 確認用のコンテナを起動する
   podman run -d --name lazydocker-web --label name=lazydocker-web registry.access.redhat.com/ubi10/httpd-24:latest
   printf '\n\033[7m 確認 \033[0m\n'
   podman ps --filter name=lazydocker-web --format '{{.Names}} {{.Status}}'
   ```

   - `lazydocker-web` が `Up` ならよい

1. lazydocker でコンテナを停止し、結果を確認する。

   ```bash
   # lazydocker を起動する
   lazydocker
   printf '\n\033[7m 確認 \033[0m\n'
   # コンテナの停止を確認する
   podman ps -a --filter name=lazydocker-web --format '{{.Names}} {{.Status}}'
   # lazydocker の設定ファイルを確認する
   ls -l ~/.config/lazydocker
   ```

   - ↑↓ で `running` の `lazydocker-web` を選ぶ
   - `s` を押し、`Are you sure you want to stop this container?` に `y` と答える
   - `q` で終了する
   - `lazydocker-web` が `Exited (0)` で、`config.yml` があればよい

#### lazydocker: podman exec でシェルを開く

- この項で、`c`（自分で足したコマンドのメニュー）に、`podman exec` でシェルを開くコマンドを足す
- 前提: [lazydocker](#lazydocker)を通してある（確認用のコンテナ `lazydocker-web` と、設定ファイル `~/.config/lazydocker/config.yml` を使う）
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）

1. [手順 3](#lazydocker) で止めた確認用のコンテナを、起動し直す。

   ```bash
   podman start lazydocker-web
   ```

   - `lazydocker-web` と出る

1. `podman exec` でシェルを開くコマンドを、設定ファイルに足す。

   ```bash
   # シェルを開くコマンドの設定を追加する
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

   - `customCommands` に足した設定が出ればよい
   - 既に `customCommands:` があるなら、`cat >>` で足さずに手で中身をまとめる

1. lazydocker を起動し、足したコマンドでコンテナのシェルを開く。

   ```bash
   lazydocker
   ```

   - `running` の `lazydocker-web` の行を選び、`c` を押す
   - `Custom Command:` の `podman exec sh` で Enter を押す
   - `id` でコンテナのユーザーが出ればよい
   - `exit` で抜け、`Press enter to return to lazydocker ...` で Enter を押すと画面に戻る
   - `q` で終了する
   - **ほかの項の手順は、`q` で終了してから貼る**（lazydocker を開いたまま貼ると、lazydocker への入力になる）

#### lazydocker: compose のプロジェクトを見る

- この項で、compose のコマンドを `podman-compose` に替え、compose のプロジェクトを見る

- 前提: [lazydocker](#lazydocker)を通し、[podman-compose](#podman-compose)を手順 3 まで通して、`~/compose-sample` のコンテナが動いている
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）

1. compose のコマンドを `podman-compose` にする設定を、設定ファイルに足す。

   ```bash
   # compose の実行コマンドの設定を追加する
   cat >> ~/.config/lazydocker/config.yml <<'EOF'
   commandTemplates:
     dockerCompose: podman-compose
   EOF
   printf '\n\033[7m 確認 \033[0m\n'
   cat ~/.config/lazydocker/config.yml
   ```

   - `commandTemplates` に足した設定が出ればよい
   - **注意**: 既に `commandTemplates:` があるなら、`cat >>` で足さずに手で中身をまとめる

1. lazydocker で web を再起動し、稼働時間を確認する。

   ```bash
   # compose のプロジェクトで lazydocker を起動する
   cd ~/compose-sample
   lazydocker
   cd ~/compose-sample
   printf '\n\033[7m 確認 \033[0m\n'
   podman-compose ps --format '{{.Names}} {{.Status}}'
   ```

   - `Project` と `Services` の枠に `compose-sample`・`check`・`web` が出ればよい
   - `web` の行を選び、`r` で再起動する
   - `q` で終了する
   - `web` の稼働時間が `check` より短ければよい

#### lazydocker: root でも使う

- この項で、システムの podman の API ソケット（`/run/podman/podman.sock`）を有効にし、root のコンテナを lazydocker で見る
- **root のコンテナを lazydocker で見ないなら、この項は不要**
- 前提: [lazydocker](#lazydocker)と[共通の bash 設定を root に入れる](shell-terminal.md#共通の-bash-設定を-root-に入れる)を通してある
  - `sudo -i bash -c 'command -v lazydocker'` が `/home/linuxbrew/.linuxbrew/bin/lazydocker` を返せばよい
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）。root の権限は、コマンドに付けた `sudo` で使う
- [Podman の補足と注意点](#podman-の補足と注意点)の「注意点」と、検証記録（`docs/verification/podman.md` の「選択した方針」）の root を使う条件を先に確認する

> [!WARNING]
> - root の lazydocker は、一般ユーザーが書き換えられるプログラムを root 権限で動かす。[root 用 Homebrew](almalinux-setup.md#homebrew-を-root-のシェルでも使う)と同じ導入条件で行う
> - システムの API ソケットにつなげるのは root だけ。権限を緩めない（つなげると、root と同じことができる）

1. システムの podman の API ソケットを有効にして、root で応答を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # システムの API ソケットを有効にする
   sudo systemctl enable --now podman.socket
   systemctl is-active podman.socket
   # API の応答とサーバーの版を確認する
   sudo curl -s --unix-socket /run/podman/podman.sock http://d/_ping; echo
   sudo podman --remote version --format '{{.Server.Version}}'
   ```

   - `active`・`OK` とサーバーの版が出ればよい

1. root の共通設定が接続先を設定したことを確かめる。

   ```bash
   sudo -i bash -c 'printenv DOCKER_HOST; command -v lazydocker'
   ```

   - `unix:///run/podman/podman.sock` と `/home/linuxbrew/.linuxbrew/bin/lazydocker` が出ればよい
   - 接続先が違う場合はここで止め、既存の用途を確認する

1. 確認用のコンテナを root で動かす。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   sudo podman run -d --name lazydocker-root-web --label name=lazydocker-root-web registry.access.redhat.com/ubi10/httpd-24:latest
   sudo podman ps --filter name=lazydocker-root-web --format '{{.Names}} {{.Status}}'
   ```

   - `lazydocker-root-web` が `Up` ならよい

1. root の lazydocker でコンテナを停止し、結果を確認する。

   ```bash
   # root の lazydocker を起動する
   sudo -i lazydocker
   printf '\n\033[7m 確認 \033[0m\n'
   # コンテナの停止を確認する
   sudo podman ps -a --filter name=lazydocker-root-web --format '{{.Names}} {{.Status}}'
   # root の lazydocker の設定ファイルを確認する
   sudo ls -l /root/.config/lazydocker
   ```

   - `Containers` に `lazydocker-root-web` が出ればよい
   - ↑↓ で `lazydocker-root-web` の行を選び、`s` を押し、`Are you sure you want to stop this container?` に `y` と答える
   - `q` で終了する
   - `lazydocker-root-web` が `Exited (0)` で、root の `config.yml` があればよい

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

#### lazydocker: 更新

- Homebrew の lazydocker を上げる
- 前提: [lazydocker](#lazydocker)を通してある
- 実行場所: 自分のユーザーでログインした bash（GNOME の端末か SSH）。Homebrew の更新は root のシェルでは行わない

1. lazydocker を更新する。

   ```bash
   brew upgrade lazydocker
   ```

   - すべてまとめて上げるなら `brew upgrade`

<details id="lazydocker-の補足と注意点">
  <summary>lazydocker の補足と注意点</summary>

**注意点**

- **`E` と `a` は `docker` コマンドを呼ぶ**: podman だけの PC では、`+ docker exec -it <ID> /bin/sh -c ...` と `Press enter to return to lazydocker ...` が出るだけで、エラーも出ない
  - シェルは [podman exec の節](#lazydocker-podman-exec-でシェルを開く)の `c` で開く
  - `a` は `-it` で起動したコンテナにだけ使える。`-it` でないコンテナでは `Container does not support attaching. ...` と出る
- **UBI のイメージのコンテナは、イメージの名前で並ぶ**: lazydocker はコンテナの `name` ラベルを名前として出す（この折りたたみの「lazydocker の手順 2: --label name= を付ける理由」）
  - 同じイメージのコンテナが並ぶと見分けにくい。操作する前に、右の枠の `Config` タブの `ID` を `podman ps` と見比べる
  - 自分で動かすコンテナなら、手順 2 のように `podman run` の `--label name=<名前>` で分けられる
- **`DOCKER_HOST` が無いか API ソケットが止まっていると、枠が空のまま**: 接続先が無い場合は `Cannot connect to the Docker daemon at unix:///var/run/docker.sock` と出る
- **pod とシークレットは出ない**: Docker の API に無いため。pod は [podman-tui](#podman-tui) で見る
- **設定ファイルの同じキーを重ねない**: `cat >>` で同じトップレベルのキーを 2 回書くと、後ろだけが効く（この折りたたみの「lazydocker: podman exec でシェルを開くの手順 2: 足した設定と、キーが重なったとき」）
- **`sudo lazydocker` は root のコンテナにつながらない**: `sudo` が `DOCKER_HOST` を消す（Homebrew の lazydocker は、そのままでは `sudo` の PATH にも無い。[Homebrew の補足と注意点](almalinux-setup.md#homebrew-の補足と注意点)の「注意点」）
  - root のコンテナは、[root でも使う](#lazydocker-root-でも使う)の節を通して `sudo -i lazydocker` で見る
- `r` は確認なしでコンテナを再起動する。操作前に右の `Config` タブの `ID` を `podman ps` と見比べ、対象を確かめる
- [lazydocker: compose のプロジェクトを見る](#lazydocker-compose-のプロジェクトを見る)の手順 2 の `r` は、確認なしで `web` を再起動する。対象の行を確かめてから押す

**[lazydocker](#lazydocker)のリード**

- ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない
- **手順 3 で lazydocker の画面（TUI）が開く**。`q` で終了する
- podman-tui との違いは検証記録（`docs/verification/lazydocker.md` の「選択した方針」）で確かめる

**[lazydocker](#lazydocker)の手順 1**

- 1 行目で `Version: 0.25.2` と `BuildSource: Homebrew` が出る
- `/home/linuxbrew/.linuxbrew/bin/lazydocker` が出る
- `unix:///run/user/<UID>/podman/podman.sock` と `OK` が出れば、lazydocker は podman の API ソケットにつなぐ

**[lazydocker](#lazydocker)の手順 1: ボトル**

実測は検証記録（`docs/verification/lazydocker.md` の「実施手順 / 手順 1: 補足: ボトル」）

- aarch64 向けの `arm64_linux` のボトルもある（formulae.brew.sh の JSON で確認）
- AppStream・EPEL に RPM は無い（[ツール一覧](tool-catalog.md)の調査）
- ビルド済みのボトルが降ってくる。依存は無い
- aarch64 でもソースからのビルドにはならない

**[lazydocker](#lazydocker)の手順 2**

- `lazydocker-web Up Less than a second` のように出る

**[lazydocker](#lazydocker)の手順 2: --label name= を付ける理由**

lazydocker は、コンテナに `name` というラベルがあると、コンテナの名前の代わりにそれを出す（上流のソースの `pkg/commands/docker.go`）。

**[lazydocker](#lazydocker)の手順 2: イメージの取得**

- 初回はイメージ（285 MB）を取得する。[Podman: Quadlet で自動起動する](#podman-quadlet-で自動起動する) などで取得済みなら、取り直さない

**[lazydocker](#lazydocker)の手順 3**

- 左に `[3]─Containers`・`[4]─Images`・`[5]─Volumes`・`[6]─Networks`、右に `Logs - Stats - Env - Config - Top` の枠が出る
- ↑↓ で `running` の `lazydocker-web` の行を選ぶと、右の枠に Apache のログ（`... configured -- resuming normal operations` など）が出る
- `lazydocker-web Exited (0) ...` と出ればよい
- `config.yml`（0 バイト）がある
- 行が `exited (0)` に変わる

**[lazydocker](#lazydocker)の手順 3: 画面の中身**

実測は検証記録（`docs/verification/lazydocker.md` の「実施手順 / 手順 4: 補足: 画面の中身」）

- `[1]─Project` と `[2]─Services` の枠は、compose のプロジェクトのディレクトリで起動し、compose のコマンドが通ったときだけ出る（[compose のプロジェクトを見る](#lazydocker-compose-のプロジェクトを見る)）
- `s` の確認の枠の下には `n/esc: no, y/enter: yes` と出る
- `x` を押すと、選んでいる枠のキーの一覧が出る（`Esc` で閉じる）

**[lazydocker](#lazydocker)の手順 3: 確かめたものの意味**

- `lazydocker-web Exited (0) ...` と出れば、画面の操作が、API を通して podman に届いている
- `config.yml`（0 バイト）は、lazydocker が最初の起動で作った空のファイルで、中身が無ければ既定の設定で動く

**[lazydocker: podman exec でシェルを開く](#lazydocker-podman-exec-でシェルを開く)のリード**

- lazydocker の `E`（シェルを開く）と `a`（アタッチ）は、`docker` コマンドを直接呼ぶ。podman だけの PC では、`+ docker exec -it ...` と出るだけで何も起きない（この折りたたみの「注意点」）
- この項の手順 2 で、既に `customCommands:` があるなら `cat >>` で足さずに手で中身をまとめる

**[lazydocker: podman exec でシェルを開く](#lazydocker-podman-exec-でシェルを開く)の手順 2**

- 読み戻した中身に、足した 5 行が出る
- **注意**: 既に `customCommands:` があるなら、`cat >>` で足さずに手で中身をまとめる。同じキーが重なったときの動きは、この折りたたみの「lazydocker: podman exec でシェルを開くの手順 2: 足した設定と、キーが重なったとき」で確かめる

**[lazydocker: podman exec でシェルを開く](#lazydocker-podman-exec-でシェルを開く)の手順 2: 足した設定と、キーが重なったとき**

| 行 | 意味 |
|---|---|
| `customCommands:` → `containers:` | Containers の枠の `c` のメニューに出すコマンド |
| `name:` | メニューに出る名前 |
| `attach: true` | 画面を離れて、コマンドを端末でそのまま動かす（シェルのような対話のあるもの向け） |
| `command:` | 動かすコマンド。`{{ .Container.ID }}` は選んだコンテナの ID |

- `{{ .Container.ID }}` は、lazydocker が選んだコンテナの ID に置き換える（シェルの変数ではない）

- 同じトップレベルのキーを 2 回書くと、後ろの定義だけが使われ、前の定義は黙って無視される

**[lazydocker: podman exec でシェルを開く](#lazydocker-podman-exec-でシェルを開く)の手順 3**

- `Custom Command:` の枠の `podman exec sh` で Enter を押すと、`sh-5.2$` のプロンプトになる
- `id` を打つと `uid=1001(default) gid=0(root) groups=0(root)` と出る

**[lazydocker: podman exec でシェルを開く](#lazydocker-podman-exec-でシェルを開く)の手順 3: コンテナのユーザー**

- `id` の `uid=1001(default) gid=0(root) groups=0(root)` は、Apache のコンテナのユーザー

**[lazydocker: compose のプロジェクトを見る](#lazydocker-compose-のプロジェクトを見る)のリード**

- lazydocker は、起動したディレクトリで `docker compose config --quiet` が通ったときだけ、`[1]─Project` と `[2]─Services` の枠を出す
- この項の手順 1 で、既に `commandTemplates:` があるなら `cat >>` で足さずに手で中身をまとめる

**[lazydocker: compose のプロジェクトを見る](#lazydocker-compose-のプロジェクトを見る)の手順 1**

- 読み戻した中身に、足した 2 行が出る

**[lazydocker: compose のプロジェクトを見る](#lazydocker-compose-のプロジェクトを見る)の手順 1: 替わるコマンド**

`dockerCompose` は、lazydocker が compose を操作するときのコマンドの頭の部分。サービスの再起動（`restartService`）などの既定のコマンドは、どれもこれを使う（`lazydocker --config` で既定の設定の全体が出る）。

**[lazydocker: compose のプロジェクトを見る](#lazydocker-compose-のプロジェクトを見る)の手順 1: キーが重なったとき**

- 既に `commandTemplates:` があるときに `cat >>` で足さないのは、この折りたたみの「lazydocker: podman exec でシェルを開くの手順 2: 足した設定と、キーが重なったとき」と同じ理由

**[lazydocker: compose のプロジェクトを見る](#lazydocker-compose-のプロジェクトを見る)の手順 2**

- 左の上に `[1]─Project`（`compose-sample`）と `[2]─Services`（`check`・`web`）の枠が出る
- 確認用のコンテナなど compose の外のものは、`[3]─Standalone Containers` に移る
- `web` の行を選ぶと、右の枠に Apache のログが出る
- `r` を押すと、確認なしに `web` が再起動する
- `compose-sample_web_1 Up 15 seconds` のように、`web` の動いている時間が `check` より短ければよい

**[lazydocker: root でも使う](#lazydocker-root-でも使う)のリード**

- この設定が Homebrew の PATH と root 用の `DOCKER_HOST` を読む。sudo の `secure_path` だけではこの項の前提を満たさない
- root の共通設定が、システムのソケットを指す `DOCKER_HOST` を入れる。`/root/.bashrc` には追記しない
- 起動は `sudo -i lazydocker`。`su -`・`sudo -i`・`sudo -s` で開いた root のシェルでは `lazydocker`
- この項の手順 4 で lazydocker の画面（TUI）が開く
- root のコンテナは `/var/lib/containers` にあり、[lazydocker](#lazydocker)の手順 3 の一般ユーザーの画面には出ない
- `-i` の無い `sudo lazydocker` は root の `~/.bashrc` を読まないので、root のコンテナにつながらない（この折りたたみの「lazydocker: root でも使うの手順 4: root で使うときの補足」）

**[lazydocker: root でも使う](#lazydocker-root-でも使う)の手順 1**

- `active`・`OK`・`5.8.2` が出ればよい

**[lazydocker: root でも使う](#lazydocker-root-でも使う)の手順 1: システムの API ソケット**

システムの `podman.socket` の中身（`systemctl cat podman.socket` の抜粋）:

```ini
[Socket]
ListenStream=%t/podman/podman.sock
SocketMode=0660
```

- `%t` はシステムでは `/run` なので、ソケットは `/run/podman/podman.sock`。持ち主は root で `srw-rw----`、つなげるのは root だけ
- 要求が来たときだけ、root の `podman.service`（`podman system service`）が起動し、要求が途切れると自分から終わる
- `sudo podman --remote` は、指定が無ければこのソケットにつなぐ
- `podman.socket` を止めた後も、ソケットのファイルは再起動まで残る。つなごうとすると失敗する（`curl` は終了コード 7）
- 自分のユーザーのソケット（[Podman](#podman)の手順 7 の `systemctl --user`）とは別のソケット

**[lazydocker: root でも使う](#lazydocker-root-でも使う)の手順 2**

- root 自身の [共通設定](shell-terminal.md#共通の-bash-設定を-root-に入れる)を先に導入する。`/root/.bashrc` への `DOCKER_HOST` の追記は不要

**[lazydocker: root でも使う](#lazydocker-root-でも使う)の手順 3**

- コンテナの ID の後に、`lazydocker-root-web Up Less than a second` のように出る

**[lazydocker: root でも使う](#lazydocker-root-でも使う)の手順 3: 確認用のコンテナ**

- root の保管場所に、イメージ（285 MB）を取得する。自分のユーザーで取得したイメージは使われない
- 名前を[lazydocker](#lazydocker)の手順 2 の `lazydocker-web` と分けて、どちらのコンテナの画面かを見分ける

**[lazydocker: root でも使う](#lazydocker-root-でも使う)の手順 4**

- 行が `exited (0)` に変わる
- `lazydocker-root-web Exited (0) ...` と出ればよい
- `config.yml`（0 バイト）は root の設定ファイル
- `[3]─Containers` に `running  lazydocker-root-web` の行が出る。[lazydocker](#lazydocker)の手順 2 の `lazydocker-web` は出ない

**[lazydocker: root でも使う](#lazydocker-root-でも使う)の手順 4: 画面の中身**

実測は検証記録（`docs/verification/lazydocker.md` の「root でも使う / 手順 4: 補足: 画面の中身」）

- 出るのは root のコンテナとイメージだけ。[lazydocker](#lazydocker)の手順 2 の `lazydocker-web` と、自分のユーザーの `quay.io/podman/hello` は出ない
- `-i` を付けずに `sudo lazydocker` と打つと（[AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](almalinux-setup.md#homebrew-を-sudo-でも使う)の節を通したホスト）、`Error` の枠に次が出て、枠は空のまま:

```text
Docker event stream returned error: Cannot connect to the Docker daemon at
unix:///var/run/docker.sock. Is the docker daemon running?
Retry count: 3
```

**[lazydocker: root でも使う](#lazydocker-root-でも使う)の手順 4: root の設定ファイル**

- 自分の `~/.config/lazydocker` の設定（任意節で足したもの）は、root では使われない

**[lazydocker: root でも使う](#lazydocker-root-でも使う)の手順 4: root で使うときの補足**

| 入口 | `DOCKER_HOST` | 画面に出るもの |
|---|---|---|
| `sudo -i lazydocker`、`sudo -i`・`su -`・`sudo -s` で開いた root のシェルの `lazydocker` | `/root/.bashrc` の `unix:///run/podman/podman.sock` | root のコンテナ |
| `sudo lazydocker` | 無い（`sudo` が消す） | 何も出ない。`Cannot connect to the Docker daemon at unix:///var/run/docker.sock`（この折りたたみの「lazydocker: root でも使うの手順 4: 画面の中身」） |
| `sudo -E lazydocker` | 自分の `unix:///run/user/<UID>/podman/podman.sock` | 自分のコンテナ（root が自分のソケットにつなぐ） |
| `sudo DOCKER_HOST=unix:///run/podman/podman.sock lazydocker` | 打った値 | root のコンテナ |

**[lazydocker: 使い方の基本](#lazydocker-使い方の基本)のリード**

- 画面は英語で出る（lazydocker に日本語の翻訳は無い）

**[lazydocker: 更新](#lazydocker-更新)の手順 1**

- 新しい版が無ければ `Warning: lazydocker 0.25.2 already installed` のように出て、何もしない

**参照**

- 検証記録（`docs/verification/lazydocker.md`）
- [jesseduffield/lazydocker — README](https://github.com/jesseduffield/lazydocker) — 機能と、各 OS への導入
- [lazydocker — Config.md](https://github.com/jesseduffield/lazydocker/blob/master/docs/Config.md) — `customCommands`・`commandTemplates` の書き方、設定ファイルの場所（Linux は `~/.config/lazydocker/config.yml`）
- [lazydocker — Keybindings](https://github.com/jesseduffield/lazydocker/blob/master/docs/keybindings/Keybindings_en.md) — 枠ごとのキー
- `lazydocker --config` — 既定の設定の全体
- [AlmaLinux 10 の初期設定](almalinux-setup.md)（「Homebrew」の手順 1〜2 の Homebrew） / [Podman](#podman) / [podman-compose](#podman-compose) — 前提の手順書
- [podman-system-service(1)](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html) — root の API ソケット（`unix:///run/podman/podman.sock`）
- `man sudo`（`-i`）・`man sudoers`（`env_reset`・`env_keep`） — [root でも使う](#lazydocker-root-でも使う)の節で、`-i` の無い `sudo` に `DOCKER_HOST` が渡らない理由

</details>

---

### Distrobox

- EPEL の distrobox を入れ、podman のコンテナでほかのディストリ（既定は Ubuntu 24.04）のボックスを作って入る
- 前提: [Podman](#podman)と[EPEL と RPM Fusion](almalinux-setup.md#epel-と-rpm-fusion)の手順 1 を通してある
  - `podman info --format '{{.Host.Security.Rootless}}'` が `true` を返さない、または `dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に前提を通す
- 実行場所: ホストの、自分のユーザーでログインした bash（GNOME の端末か SSH）
- この項の手順 1 で変数を設定したシェルに貼る
- **この項の手順 3 で作るボックスはホームを共有し、ホストのファイルシステム全体が `/run/host` に見え、ネットワークとプロセスも共有する。信用できないソフトを試す場所にはしない**

> [!IMPORTANT]
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（ボックスは自分のユーザーの rootless の podman で動かすため）

1. 変数を設定する。

   ```bash
   DBX_NAME=ubuntu                                  # ボックスの名前。<DBX_NAME>
   DBX_IMAGE=quay.io/toolbx/ubuntu-toolbox:24.04    # 元にするイメージ。<DBX_IMAGE>
   printf '\n\033[7m 確認 \033[0m\n'
   printf '%-9s = %s\n' DBX_NAME "${DBX_NAME}" DBX_IMAGE "${DBX_IMAGE}"
   ```

   - 編集が必須の変数は無い
   - 別のディストリにするときだけ `DBX_IMAGE` を変える（候補は [Distrobox の補足と注意点](#distrobox-の補足と注意点)の「参照」の互換のあるイメージで確かめる）
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. Distrobox を導入し、版とボックスの一覧を確認する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   # 配布されている版を確認する
   dnf -q list --showduplicates distrobox
   # Distrobox を導入する
   sudo dnf install distrobox
   # 導入した版と実行ファイルの場所を確認する
   distrobox version
   command -v distrobox
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' distrobox
   # ボックスの一覧を確認する
   distrobox list
   ```

   - トランザクション表の内容を確かめ、`[y/N]` に `y` と答える
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y` と答える
   - 実行ファイルが `/usr/bin/distrobox` で、版が出ればよい

1. ボックスを作る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   distrobox create --yes --name "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" --image "${DBX_IMAGE:?手順 1 の DBX_IMAGE が空のまま。値を入れて貼り直す}"
   distrobox list
   ```

   - `distrobox list` に作ったボックスが `Created` で出ればよい

1. 初回の初期化を兼ねて、ボックスの中でコマンドを 1 つ動かす。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- sh -c 'grep PRETTY_NAME /etc/os-release; id -un; pwd'
   ```

   - `Container Setup Complete!` と、自分のユーザー名・ホームが出ればよい
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼ると、初期化に失敗しても後ろのボックスへの接続が動く）

1. ボックスのシェルに入る。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}"
   ```

   - ボックスのプロンプトに変わればよい
   - `host-spawn: command not found` が出ても、ボックスのプロンプトに入れればよい
   - `exit` でホストに戻る
   - **ほかの項の手順は、`exit` でホストに戻ってから貼る**（続けて貼ると、ボックスのシェルの中ではなく、ボックスのシェルを閉じた後の元のシェルで動く）

#### Distrobox: ボックスのコマンドをホストから呼ぶ

- 例として、AppStream と EPEL に無い `ffmpeg` を Ubuntu のボックスに入れ、ホストのシェルから `ffmpeg` で呼べるようにする
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

1. ボックスのパッケージの一覧を新しくする。

   ```bash
   distrobox enter "${DBX_NAME:?この項の手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- sudo apt-get update
   ```

   - パッケージ一覧の読み込みが完了すればよい
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼ると、一覧の更新に失敗しても後ろのパッケージ導入が動く）

1. ボックスに ffmpeg を入れる。

   ```bash
   distrobox enter "${DBX_NAME:?この項の手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- sudo apt-get install -y ffmpeg
   ```

   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼ると、導入に失敗しても後ろのホストへの書き出しが動く）

1. ffmpeg をホストへ書き出し、呼び出す版を確認する。

   ```bash
   # ffmpeg の呼び出し口を作成する
   distrobox enter "${DBX_NAME:?この項の手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- distrobox-export --bin /usr/bin/ffmpeg --export-path ~/.local/bin
   printf '\n\033[7m 確認 \033[0m\n'
   command -v ffmpeg
   ~/.local/bin/ffmpeg -version | head -1
   ```

   - `OK!` と `ffmpeg version` が出ればよい
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
   - **次の手順は、答えて完了してから貼る**（続けて貼ると、ホスト側の更新を断ってもボックス内の更新が動く）

1. ボックスの中のパッケージを更新する。

   ```bash
   distrobox upgrade "${DBX_NAME:?この項の手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}"
   ```

   - ボックスの中身は、ホストの `dnf upgrade` では上がらない。ボックスごとにこの手順を行う
   - **ほかの項の手順は、プロンプトが戻ってから貼る**（終わる前に貼ると、動いているコマンドへの入力になる）

<details id="distrobox-の補足と注意点">
  <summary>Distrobox の補足と注意点</summary>

**注意点**

- **ボックスの `sudo` はホストの root ではない**: 本書の `--userns keep-id` では、ボックスの root はホストの subordinate UID に対応する。自分の UID はボックス内の同じ UID に対応し、ホストの root の権限は得られない
- **`distrobox enter` の実行中に新たに貼った文字は、ボックスへの入力になる**: 同じ入力として最初に貼った後ろの行は、`enter` の終了後に元のシェルで動く
  - `distrobox enter <名前> -- <コマンド>` と同じ入力に続けたホスト用のコマンドは、その処理が終わってからホストで動く
  - 次をボックス内で動かす場合は、ボックスのプロンプトが出てから別に貼る
- **書き出したスクリプトの名前が、ホストのコマンドと重なることがある**: `~/.local/bin` は PATH の途中にある
  - 同じ名前のコマンドがほかの場所にもあると、どちらが呼ばれるかは PATH の順で決まる
  - Homebrew の `brew shellenv` は、自分の場所を PATH の先頭に足す
- 必要な空き容量は、導入予定のパッケージとトランザクション表で確かめる
- この項の手順 3 で作るボックスはホームを共有し、ホストのファイルシステム全体が `/run/host` に見え、ネットワークとプロセスも共有する。信用できないソフトを試す場所にはしない
- `podman system reset` を行うと、ボックスも一緒に消える

**[Distrobox](#distrobox)のリード**

- **手順 2 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）
- **手順 4 と 5 はボックスの中のコマンドになる**。手順 4 は終わってから、手順 5 は `exit` で戻ってから、次を貼る

**[Distrobox](#distrobox)の手順 1**

- **編集が必須の変数は無い**。既定のままなら、Ubuntu 24.04 のボックスができる

**[Distrobox](#distrobox)の手順 2**

- 版は `distrobox.noarch  1.8.2.3-1.el10_2  epel` のように 1 つだけ出る
- `hicolor-icon-theme` が未導入なら一緒に入る。導入済みなら追加されない
- `distrobox: 1.8.2.3`、`/usr/bin/distrobox`、`distrobox 1.8.2.3-1.el10_2 epel` が出る
- `distrobox list` は見出しの行だけを出す（ボックスはまだ無い）
- EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる

**[Distrobox](#distrobox)の手順 2: 一緒に入るものと鍵**

- 未導入なら一緒に入る依存が `hicolor-icon-theme` だけなのは、podman は前提の手順で入っているため
- 確認を求められる EPEL の署名鍵は、[AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」の手順 1](almalinux-setup.md#epel-と-rpm-fusion) に書いた鍵

**[Distrobox](#distrobox)の手順 2: distrobox の依存**

`rpm -q --requires distrobox` の中身は `(podman or /usr/bin/docker)` と `hicolor-icon-theme` など。

- distrobox の本体はシェルスクリプトで、`/usr/bin/distrobox-create`・`distrobox-enter` などのコマンドの集まり

**[Distrobox](#distrobox)の手順 3**

- イメージを取得してから、`Distrobox 'ubuntu' successfully created.` が出る
- `distrobox list` に、`ubuntu`・`Created`・`quay.io/toolbx/ubuntu-toolbox:24.04` の行が出る
- `--yes` は、イメージの取得を確かめる問い合わせ（`Do you want to pull the image now? [Y/n]`）を飛ばす

**[Distrobox](#distrobox)の手順 3: ボックスは隔離されていない**

| オプション | 意味 |
|---|---|
| `--privileged` | 特権付きのコンテナ（rootless なので、ホストの root にはならない） |
| `--security-opt label=disable` | SELinux のラベルによる分離を切る |
| `--network host` / `--pid host` / `--ipc host` | ネットワーク・プロセス・IPC をホストと共有する |
| `--userns keep-id:size=65536` | 自分の UID・GID はボックスの中でも同じ番号に対応し、ボックスの root は subordinate UID・GID に対応する |
| `--volume "/home/<USER>":"/home/<USER>"` | ホームディレクトリをそのまま使う |
| `--volume /:/run/host/` | ホストのファイルシステム全体を `/run/host` に見せる |
| `--pids-limit=-1` | プロセス数を制限しない |

ボックスは「別のディストリのユーザーランドを使うための道具」で、安全のための隔離ではない。実行前の注意は [Distrobox](#distrobox)のリードにある。

**[Distrobox](#distrobox)の手順 4**

- 初回はボックスの初期化が走る。`[ OK ]` の行が並んだ後に `Container Setup Complete!` が出る
- その後に `PRETTY_NAME="Ubuntu 24.04.5 LTS"`・自分のユーザー名・`/home/<USER>` が出る

**[Distrobox](#distrobox)の手順 4: 初期化で行われること**

- ボックスの中に自分と同じ名前のユーザーを作り、`sudo` をパスワード無しで使えるようにする（ボックスの中の `sudo -l` は `(root) NOPASSWD: ALL`）
- 本書の `--userns keep-id` では、ボックスの root はホストの subordinate UID に対応する。自分の UID に対応するのはボックス内の同じ UID で、ボックスの root にホストの root の権限は無い
- コンテナが止まっていれば、次の `distrobox enter` でも起動と初期化の確認が走る（2 回目からは速い）
- 同じ項の手順 4 で出るユーザー名とホームは、ホストと同じ

**[Distrobox](#distrobox)の手順 5**

- プロンプトが `📦[<USER>@ubuntu ~]$` に変わる。ここから先はボックスの中のシェル
- SSH など画面の無いログインから入ると、`host-spawn: command not found` が出ることがある。出なくても、ボックスのプロンプトに入れればよい

**[Distrobox](#distrobox)の手順 5: host-spawn: command not found**

ボックスの中の `/etc/profile.d/distrobox_profile.sh` は、`DISPLAY`・`WAYLAND_DISPLAY`・`XAUTHORITY` などが空のとき、`host-spawn` でホストの値を読みに行く。

**[Distrobox: ボックスのコマンドをホストから呼ぶ](#distrobox-ボックスのコマンドをホストから呼ぶ)のリード**

- ボックスに入れたものはボックスの中にだけある。ホストには、ボックスを呼び出す小さなスクリプトが `~/.local/bin` に置かれる
- **この項の手順 2・3 は `distrobox enter` で終わる**。プロンプトが戻ってから次を貼る

**[Distrobox: ボックスのコマンドをホストから呼ぶ](#distrobox-ボックスのコマンドをホストから呼ぶ)の手順 2**

- `Reading package lists...` または `パッケージリストを読み込んでいます... 完了` で終わる

**[Distrobox: ボックスのコマンドをホストから呼ぶ](#distrobox-ボックスのコマンドをホストから呼ぶ)の手順 3: ボックスの中の sudo**

- ボックスの中の `sudo` はパスワードを聞かない（この折りたたみの「Distroboxの手順 4: 初期化で行われること」の初期化で、パスワード無しにしてある）

**[Distrobox: ボックスのコマンドをホストから呼ぶ](#distrobox-ボックスのコマンドをホストから呼ぶ)の手順 4**

- `/usr/bin/ffmpeg from ubuntu exported successfully in /home/<USER>/.local/bin.` と `OK!` が出る
- 最後の行が `ffmpeg version 6.1.1-3ubuntu5 ...` なら、書き出したコマンドを呼べている

**[Distrobox: ボックスのコマンドをホストから呼ぶ](#distrobox-ボックスのコマンドをホストから呼ぶ)の手順 4: 書き出されたもの**

`~/.local/bin/ffmpeg` は、ボックスの中の ffmpeg を呼び出すシェルスクリプト:

```text
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
- `~/.local/bin` は、AlmaLinux の既定の `~/.bashrc` で PATH に入っている

**[Distrobox: 更新](#distrobox-更新)の手順 3: ボックスの中の更新**

- Ubuntu のボックスでは `apt-get update` と `apt-get upgrade` が確認なしで走る

**選択した方針**

| 選択肢 | 採否 |
|---|---|
| **EPEL の distrobox（1.8.2.3）** | **採用。** システムの podman と組んで使うので RPM にした（[ツール一覧の選び方](tool-catalog.md#選び方)の規則 3）。`dnf upgrade` で上がる |
| Homebrew の distrobox（1.8.2.5） | 不採用。版は新しいが、コンテナ系のツールは RPM に揃えた（Homebrew の podman がシステムの podman を隠す問題を避けるため。[ツール一覧の注意点](tool-catalog.md#注意点)） |
| 上流の curl のインストーラ | 不採用。`dnf` の管理の外に入り、更新も手作業になる |
| AppStream の toolbox（0.3） | 代わりの選択肢。RHEL の公式の道具で、[ツール一覧](tool-catalog.md#cli-コンテナ)に載せた。本書は、ボックスのディストリを選べる distrobox にした |
| ボックスのイメージに `quay.io/toolbx/ubuntu-toolbox` を使う | **採用。** `docker.io/library/ubuntu` より初期化で入れるものが少なく、Docker Hub の取得回数の上限にもかからない（[Distrobox](#distrobox)の手順 1 の `DBX_IMAGE`） |

**参照**

- 検証記録（`docs/verification/distrobox.md`）
- [distrobox — README](https://github.com/89luca89/distrobox) — 概要、コマンドの一覧、互換のあるイメージ（`docs/compatibility.md`）
- [distrobox — Useful tips](https://github.com/89luca89/distrobox/blob/main/docs/useful_tips.md) — 書き出し、ホストのコマンドの呼び出し
- `man distrobox-create` / `man distrobox-enter` / `man distrobox-export` / `man distrobox-rm` — オプション
- [Podman](#podman) — 前提の rootless の podman
- [AlmaLinux 10 の初期設定](almalinux-setup.md) — 前提の EPEL の有効化（「EPEL と RPM Fusion」の手順 1）

</details>

---
