# Podman インストール手順（AlmaLinux 10 / AppStream・rootless）

## 実施手順

- [検証記録](verification/podman.md)・[参考資料](reference/podman.md)

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **自分のユーザーでログインしたシェル（デスクトップの端末か SSH）で実行する**。`sudo -i` した root のシェルや、`sudo -iu <ユーザー>` で切り替えたシェルでは行わない（コンテナを自分のユーザーで動かすため。`sudo -iu` のシェルには `XDG_RUNTIME_DIR` が無く、手順 7 の `systemctl --user` が失敗する）

- 上から順にコードブロックを貼る
- 手順の後: [lazydocker](lazydocker.md) など Docker の API を使うツールから使うなら[Docker 向けのツールから使う（任意）](#docker-向けのツールから使う任意)、コンテナを常駐させるなら[Quadlet で自動起動する（任意）](#quadlet-で自動起動する任意)。日々の操作は[使い方の基本](#使い方の基本)、以後は[更新](#更新)・[ロールバック](#ロールバック)
- 通すと使えるようになるもの: [distrobox](distrobox.md)、[podman-compose](podman-compose.md)、[hadolint / dive / Trivy](image-tools.md)、[podman-tui](podman-tui.md)、[lazydocker](lazydocker.md)、[Forgejo](forgejo.md)、[ツール一覧の CLI: コンテナ](tool-catalog.md#cli-コンテナ)の行

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

   - 依存として `crun`・`conmon`・`netavark`・`aardvark-dns`・`passt`・`containers-common` などが一緒に入る

1. 自分のユーザーに、rootless 用の UID・GID の範囲（subuid / subgid）があるか確かめる。

   ```bash
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
       sudo usermod "${SUBID_ARGS[@]}" "${USER}" &&
       podman system migrate &&
       grep -H "^${USER}:" /etc/subuid /etc/subgid
     fi
   else echo '中断: /etc/subuid または /etc/subgid を読めない' >&2
   fi
   ```

   - `SUBID_START=` の行で、登録済みの範囲のいちばん後ろ（1 つも無ければ 524288）を始まりにする
   - `usermod` の行で、そこから 65536 個を不足する側だけに割り当てる。既存の UID・GID の範囲は変更しない
   - 手順 3 で出るはずだった 2 行が出ればよい
   - `podman system migrate` は、それまでに podman を使っていたときに、新しい範囲を反映させる

1. 自分のユーザーで動く設定になっているか確かめる。

   ```bash
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
   podman run --rm quay.io/podman/hello
   podman images
   ```

   - `!... Hello Podman World ...!` から始まる絵と案内が出る
   - `podman images` に `quay.io/podman/hello` の行が出る
   - **イメージはレジストリの名前から書く**（`quay.io/...`、`registry.access.redhat.com/...`）。短い名前だと、どこから取るかを聞かれることがある（参考資料を参照）

1. API ソケットを有効にして、応答を確かめる。

   ```bash
   systemctl --user enable --now podman.socket
   systemctl --user is-active podman.socket
   curl -s --unix-socket "${XDG_RUNTIME_DIR}/podman/podman.sock" http://d/_ping; echo
   podman --remote version --format '{{.Server.Version}}'
   ```

   - `active`・`OK`・`5.8.2` が出ればよい
   - このソケットを使うもの: [Trivy](image-tools.md)、[podman-tui](podman-tui.md)、[lazydocker](lazydocker.md)、GUI の Pods・Podman Desktop
   - `Failed to connect to user scope bus` と出たら、`sudo -iu` などで切り替えたシェルで実行している。自分のユーザーでログインし直す

---

## Docker 向けのツールから使う（任意）

- Docker の API に `DOCKER_HOST` でつなぐツール（[lazydocker](lazydocker.md) など）のための設定
- [image-tools.md](image-tools.md) の dive と Trivy、[podman-tui](podman-tui.md) は podman を直接読むので、この節は要らない

1. 共通設定を読み直し、ソケットが Docker の API に答えるか確かめる。

   ```bash
   . ~/.bashrc
   printf '%s\n' "${DOCKER_HOST-}"
   curl -s --unix-socket "${DOCKER_HOST#unix://}" http://d/version | grep -o '"Name":"Podman Engine"'
   ```

   - `unix:///run/user/…/podman/podman.sock` と `"Name":"Podman Engine"` が出ればよい
   - 共通設定はソケットがあるときだけ `DOCKER_HOST` を入れる。既に別の値がある場合は上書きせず、その用途を確認する
   - ソケットの有効化は [手順 7](#実施手順)で行う。`~/.bashrc` には追記しない

---

## Quadlet で自動起動する（任意）

- `podman run -d` で動かしたコンテナは、PC を再起動すると戻らない。linger が無いと、ログアウトしただけで止まる（[注意点](#注意点)）
- Quadlet は、`~/.config/containers/systemd` に置いた定義から、ユーザーの systemd のサービスを作る仕組み。podman に含まれている
- 確認用に、`registry.access.redhat.com/ubi10/httpd-24`（Apache）を `127.0.0.1:8080` で動かす
- **前提**: [linger](linger.md) を有効にしてあること（ログインしていない間もユーザーの systemd を動かすため）。`loginctl show-user "$(id -u)" -p Linger` が `Linger=yes` を返さなければ、先に通す
- この節の手順 3 で再起動する

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

   - 定義の各行の意味は、この手順の補足

1. systemd に定義を読み直させ、サービスを起動して応答を確かめる。

   ```bash
   systemctl --user daemon-reload
   systemctl --user start hello-web.service
   systemctl --user is-active hello-web.service
   systemctl --user is-enabled hello-web.service
   curl -s --retry 10 --retry-delay 1 --retry-all-errors http://127.0.0.1:8080/
   ```

   - `active`・`generated`・`hello from quadlet` が出ればよい
   - 初回の `start` はイメージの取得を待つので、数十秒かかることがある
   - `start` から戻った直後は、Apache がまだ待ち受けていないことがある。curl は、応答が来るまで 1 秒おきに 10 回まで試し直す
   - **`systemctl --user enable` は使わない**。自動で起動するかは、定義の `[Install]` で決まる（参考資料を参照）

1. 再起動しても起動するかを確かめるときだけ、再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - 再起動しないなら、この節の手順 4 も飛ばす
   - **次の手順は、再起動した後にログインし直してから貼る**

1. 再起動の後、ログインより前にサービスが起動していたことを確かめる。

   ```bash
   systemctl --user show hello-web.service -p ActiveEnterTimestamp
   loginctl show-session "${XDG_SESSION_ID}" -p Timestamp
   curl -s http://127.0.0.1:8080/
   ```

   - 1 行目の時刻（サービスが起動した時刻）が、2 行目の時刻（ログインした時刻）より前ならよい
   - `hello from quadlet` が出る

---

## 使い方の基本

| コマンド | 用途 |
|---|---|
| `podman ps -a` | コンテナの一覧（止まっているものも） |
| `podman images` | イメージの一覧 |
| `podman run -d --name <名前> -p 127.0.0.1:<ポート>:<ポート> <イメージ>` | 裏で動かす。自分のユーザーでは 1024 未満のポートを使えない（[注意点](#注意点)） |
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

---

## 更新

1. podman を更新する。

   ```bash
   sudo dnf upgrade podman
   ```

   - システム全体なら `sudo dnf upgrade`
   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. Quadlet の節を通したときだけ、新しいイメージがあるか見てから当てる。

   ```bash
   podman auto-update --dry-run
   podman auto-update
   ```

   - `UPDATED` の列が `false` なら、新しいイメージは無い
   - `true` なら、新しいイメージを取ってサービスを起動し直す

---

## ロールバック

- 上から順に、通した節の分だけ実行する
- この節の手順 5 の前に、ほかの手順書（distrobox・podman-compose・[Forgejo](forgejo.md#ロールバック)）で作ったものが要らないか確かめる。Forgejo が動いているときは先に止め、Quadlet の定義も外す
- Quadlet の節を通し、linger も切るときは、この節の後に [linger.md のロールバック](linger.md#ロールバック)を行う（[Syncthing](syncthing.md)・[Dropbox](dropbox.md)・[Forgejo](forgejo.md) など、ほかに linger を使うものが無いかは、そこで確かめる）

> [!CAUTION]
> **この節の**手順 5 の `podman system reset` で、自分のコンテナ・イメージ・ボリュームがすべて消える。[distrobox](distrobox.md) のボックスや [podman-compose](podman-compose.md)・[Forgejo](forgejo.md) のコンテナも含む。Forgejo の bind mount 先の `~/.local/share/forgejo` と Quadlet の定義は残るので、[Forgejo のロールバック](forgejo.md#ロールバック)で扱う。

1. Quadlet の節を通したときだけ、確認用のサービスと定義とページを消す。

   ```bash
   systemctl --user stop hello-web.service
   rm ~/.config/containers/systemd/hello-web.container
   systemctl --user daemon-reload
   rm -rf ~/hello-web
   ```

1. Docker 向けのツールを閉じ、今のシェルの接続先を外す。

   ```bash
   unset DOCKER_HOST
   ```

   - `~/.bashrc` の行の削除は不要。この節の手順 3 で API ソケットを止める
   - ソケットのファイルが残る間は、新しいシェルでも共通設定が `DOCKER_HOST` を入れる。再起動後にソケットが無ければ入れない

1. API ソケットを止める。

   ```bash
   systemctl --user disable --now podman.socket
   ```

1. 消す前に、残っているものを見る。

   ```bash
   podman ps -a
   podman images
   podman volume ls
   podman system df
   ```

   - **次の手順は、消してよいか確かめてから貼る**

1. 自分のコンテナ・イメージ・ボリュームをすべて消す（取り戻せない）。

   ```bash
   podman system reset
   ```

   - `Are you sure you want to continue? [y/N]` に `y` と答える
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. 手順 2 で podman を入れたときだけ、podman を消す。

   ```bash
   sudo dnf remove podman
   ```

   - `[y/N]` で聞かれる。distrobox や podman-compose を入れていれば、それらも一緒に消える
   - podman-tui は podman に依存しないので残る（[podman-tui のロールバック](podman-tui.md#ロールバック)で消す）
   - 依存で入ったもの（`crun` など）も一緒に消える

---

## 注意点

- **イメージは完全な名前で書く**: 短い名前は、端末から実行すると取る場所を聞かれる（参考資料を参照）
- **`sudo podman` は別の保管場所**: 自分のユーザーのコンテナとイメージは、`sudo podman` からは見えない（[使い方の基本](#使い方の基本)）
  - root のコンテナを lazydocker で見るなら、[lazydocker.md の root でも使う](lazydocker.md#root-でも使う任意)の節（システムの API ソケットを使う）
- **1024 未満のポートは使えない**: 自分のユーザーで `-p 127.0.0.1:80:8080` のように指定すると、次のように失敗する
  - `Error: pasta failed with exit code 1:` と `Failed to bind port 80 (Permission denied) for option '-t 127.0.0.1/80-80:8080-8080'`
  - `sysctl net.ipv4.ip_unprivileged_port_start` は `1024`。8080 など 1024 以上の番号にする
- **`:Z` をホームやシステムのディレクトリに付けない**: `:Z` は指定したディレクトリの SELinux のラベルを付け替える。`podman-run(1)` の `--volume` の説明も、システムのファイルやディレクトリの付け替えを戒めている
- **linger が無いと、ログアウトでコンテナが止まる**: 止めたくないものは Quadlet の節で動かし、[linger](linger.md) を有効にする
- **API ソケットにつなげると、自分のコンテナを何でも操作できる**: ソケットのファイルの権限（`srw-rw----`、持ち主は自分）を変えない
- **容量**: イメージは `~/.local/share/containers/storage` に溜まる。`podman system df` で見て、`podman image prune -a` で掃除する（`ubi10/httpd-24` は 285 MB）
- **Docker Hub には、認証なしの取得に回数の上限がある**: 本書の例は quay.io と registry.access.redhat.com に寄せた
- **Raspberry Pi 5 で使うイメージは arm64 があるか見る**: `podman manifest inspect <イメージ>` に `"architecture": "arm64"` があればよい。本書の例のイメージにはどれもある
- **Homebrew の formula が podman を連れてくることがある**: podman-compose などを Homebrew で入れると、依存の podman が `/usr/bin/podman` を隠す（[ツール一覧](tool-catalog.md#注意点)）
  - システムの podman との互換性が要るものや、別の podman を依存で入れるものは RPM を選ぶ
  - [image-tools.md](image-tools.md) の hadolint・dive と [lazydocker.md](lazydocker.md) は、RPM の提供状況などを比べて Homebrew を選んでいる
