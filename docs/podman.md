# Podman インストール手順（AlmaLinux 10 / AppStream・rootless）

## 実施手順

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **自分のユーザーでログインしたシェル（デスクトップの端末か SSH）で実行する**。`sudo -i` した root のシェルや、`sudo -iu <ユーザー>` で切り替えたシェルでは行わない（コンテナを自分のユーザーで動かすため。`sudo -iu` のシェルには `XDG_RUNTIME_DIR` が無く、手順 7 の `systemctl --user` が失敗する）

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: [lazydocker](lazydocker.md) など Docker の API を使うツールから使うなら[Docker 向けのツールから使う（任意）](#docker-向けのツールから使う任意)、コンテナを常駐させるなら[Quadlet で自動起動する（任意）](#quadlet-で自動起動する任意)。日々の操作は[使い方の基本](#使い方の基本)、以後は[更新](#更新)・[ロールバック](#ロールバック)
- 通すと使えるようになるもの: [distrobox](distrobox.md)、[podman-compose](podman-compose.md)、[hadolint / dive / Trivy](image-tools.md)、[podman-tui](podman-tui.md)、[lazydocker](lazydocker.md)、[ツール一覧の CLI: コンテナ](tool-catalog.md#cli-コンテナ)の行

> [!WARNING]
> **x86_64 のコンテナでのみ検証した手順書**で、実機では本実行していない（[対象と検証環境](#対象と検証環境)）。
>
> - Docker のコンテナの中で systemd を動かし、その中で rootless の podman を入れ子で動かした。[Quadlet](#quadlet-で自動起動する任意) の再起動は、コンテナの再起動で確かめた
> - SELinux は無効で、cgroup のコントローラも無い環境だった。`:Z` のラベルの付け替えと、資源の制限（`--memory` など）は確かめていない

1. podman が入っているか確かめる。

   ```bash
   rpm -q podman || echo 'podman は未導入'
   ```

   - `podman-5.8.2-...` のように版が出れば、手順 2 は飛ばす
   - `podman は未導入` と出たら、手順 2 で入れる

   <details>
   <summary>補足: Server の環境では最初から入っている</summary>

   AlmaLinux 10 のインストーラのグループ定義（AppStream の comps）では、Server と Server with GUI の環境に「コンテナー管理」（`container-management`）のグループが入っている。

   - このグループの必須パッケージは `podman` と `buildah`。この 2 つの環境で入れた PC には、podman が最初から入っている
   - Workstation と Minimal Install の環境には、このグループが無い
   - 以上は comps の定義を読んだだけで、それぞれの環境で入れた PC では確かめていない

   </details>

1. podman が未導入のときだけ、AppStream から入れる。

   ```bash
   sudo dnf install -y podman
   ```

   - 依存として `crun`・`conmon`・`netavark`・`aardvark-dns`・`passt`・`containers-common` などが一緒に入る

   <details>
   <summary>補足: 一緒に入るものと、<code>container-tools</code> を使わない理由</summary>

   素のコンテナでは、podman と依存の 29 個、合わせて 30 パッケージが入った（ダウンロード 29 MB、展開後 91 MB）。

   | パッケージ | 役割 |
   |---|---|
   | `crun` | コンテナを実際に起動するランタイム（OCI ランタイム） |
   | `conmon` | コンテナごとに付き添い、ログと終了コードを受け取る |
   | `netavark` / `aardvark-dns` | コンテナのネットワークと、コンテナ名での名前解決 |
   | `passt` | rootless のネットワーク（`pasta`）。ポートの公開もここを通る |
   | `containers-common` | `/etc/containers` の設定（レジストリ、署名の方針、保管の方式） |
   | `shadow-utils-subid` | subuid / subgid を読むライブラリ（手順 3） |
   | `criu` | コンテナのチェックポイントと復元（本書では使わない） |

   - SELinux の方針（`selinux-policy`）が入っている PC では、`container-selinux` も一緒に入る（`(container-selinux >= 2:2.162.1 if selinux-policy)` という条件付きの依存）
   - 検証コンテナには `selinux-policy` が無いので、`container-selinux` は入らなかった

   AppStream には、podman・buildah・skopeo・toolbox・cockpit-podman・podman-docker・udica などをまとめて入れるメタパッケージ `container-tools` もある。

   - 本書は podman だけを入れ、ほかは[ツール一覧](tool-catalog.md#cli-コンテナ)から要るものを足す形にした

   </details>

1. 自分のユーザーに、rootless 用の UID・GID の範囲（subuid / subgid）があるか確かめる。

   ```bash
   for f in /etc/subuid /etc/subgid; do
     grep -H "^${USER}:" "$f" || printf '%s: 自分の割り当てが無い\n' "$f"
   done
   ```

   - `/etc/subuid:<USER>:524288:65536` と `/etc/subgid:<USER>:524288:65536` のような 2 行が出れば、手順 4 は飛ばす
   - 片方でも `自分の割り当てが無い` と出たら、手順 4 で不足している側だけ割り当てる

   <details>
   <summary>補足: subuid / subgid の役割</summary>

   rootless のコンテナでは、コンテナの中の root（UID 0）が自分の UID に、UID 1〜65536 がこの範囲の UID に読み替えられる。範囲が無いと、UID を 1 つしか使えないコンテナになる。

   - `useradd` は、ユーザーを作るときに `/etc/login.defs` の `SUB_UID_MIN`（EL10 は 524288）から空いている範囲を割り当てる
   - 範囲が無いのは、`useradd` の既定を変えて作ったユーザーなど

   範囲の無いユーザー（`useradd -K SUB_UID_COUNT=0 -K SUB_GID_COUNT=0` で作った）で podman を動かしたときの実測:

   ```
   level=error msg="cannot find UID/GID for user <USER>: no subuid ranges found for user \"<USER>\" in /etc/subuid - check rootless mode in man pages."
   level=warning msg="Using rootless single mapping into the namespace. This might break some images. Check /etc/subuid and /etc/subgid for adding sub*ids if not using a network user"
   ```

   </details>

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
   - 手順 3 で出るはずだった 2 行が出ればよい（検証では、ほかのユーザーの範囲の後ろの `589824` から割り当てられた）
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

   <details>
   <summary>補足: <code>podman info</code> の読み方</summary>

   3 行目の 6 つの値の意味:

   | 値 | 意味 |
   |---|---|
   | `true` | rootless（自分のユーザー）で動いている |
   | `overlay` | イメージの層を重ねて保管する方式 |
   | `crun` | OCI ランタイム |
   | `netavark` | コンテナのネットワーク |
   | `pasta` | rootless のネットワークと、ポートの公開 |
   | `v2` | cgroup v2 |

   `podman info` の全体は長い。検証コンテナでの抜粋（UID の読み替えの表）:

   ```
   idMappings:
     ...
     uidmap:
     - container_id: 0
       host_id: <UID>
       size: 1
     - container_id: 1
       host_id: 524288
       size: 65536
   ```

   - コンテナの中の 0 が自分の UID に、1〜65536 が手順 3 の範囲に読み替えられている
   - 検証コンテナでは `cgroupControllers: []` だった。cgroup v1 のホストの上で動かしたため、コントローラが 1 つも無い（実機の値は確かめていない）

   </details>

1. イメージを完全な名前で指定して、コンテナを 1 つ動かす。

   ```bash
   podman run --rm quay.io/podman/hello
   podman images
   ```

   - `!... Hello Podman World ...!` から始まる絵と案内が出る
   - `podman images` に `quay.io/podman/hello` の行が出る
   - **イメージはレジストリの名前から書く**（`quay.io/...`、`registry.access.redhat.com/...`）。短い名前だと、どこから取るかを聞かれることがある（この手順の補足）

   <details>
   <summary>補足: 短い名前のイメージ</summary>

   AlmaLinux 10 の `/etc/containers/registries.conf` は、短い名前を次の順で探す設定になっている。

   ```
   unqualified-search-registries = ["registry.access.redhat.com", "registry.redhat.io", "docker.io"]
   short-name-mode = "enforcing"
   ```

   - `/etc/containers/registries.conf.d/000-shortnames.conf` に載っている名前（`hello`・`ubuntu`・`nginx` など）は、そこに書かれたレジストリに決まる
   - 載っていない名前は、端末（TTY）から実行すると、どれを取るか選ぶように求められる
   - 端末でないとき（スクリプトなど）は選択の問い合わせに答えられない。検索順だけで取得できるとは考えず、レジストリから始まる完全な名前を指定する

   端末から、載っていない名前を指定したときの実測:

   ```
   $ podman pull ubi10/ubi-minimal
   ? Please select an image:
     ▸ registry.access.redhat.com/ubi10/ubi-minimal:latest
       registry.redhat.io/ubi10/ubi-minimal:latest
       docker.io/ubi10/ubi-minimal:latest
   ```

   完全な名前で書けば、この問い合わせは起きず、どこから取ったかも文書に残る。

   </details>

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

   <details>
   <summary>補足: ソケットの仕組み</summary>

   `podman.socket` はユーザーの systemd が待ち受けるソケットで、要求が来たときだけ `podman.service`（`podman system service`）を起動する。

   - `podman.service` は、要求が途切れると数秒で自分から終わる（検証では 7 秒後に `inactive`）
   - ソケットのファイルは `srw-rw----` で、持ち主は自分。つなげるのは自分と root だけ
   - `http://d/_ping` の `d` は、curl が URL の形を要求するためだけのホスト名で、通信はソケットに行く

   `sudo -iu <ユーザー>` で切り替えたシェルで実行したときの実測:

   ```
   Failed to connect to user scope bus via local transport: $DBUS_SESSION_BUS_ADDRESS and $XDG_RUNTIME_DIR not defined (consider using --machine=<user>@.host --user to connect to bus of other user)
   ```

   - 同じシェルの `podman` は、`The cgroupv2 manager is set to systemd but there is no systemd user session available` などの警告を出し、`cgroupfs` に切り替えて動いた
   - `su - <ユーザー>` と `runuser -l <ユーザー>` のシェルには `XDG_RUNTIME_DIR` があり、`systemctl --user` が使えた（検証コンテナの systemd 257 で確認）

   </details>

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

   <details>
   <summary>補足: 定義の中身</summary>

   | 行 | 意味 |
   |---|---|
   | `Image=` | イメージ。完全な名前で書く（手順 6 の補足） |
   | `ContainerName=` | コンテナの名前。`podman ps` に出る |
   | `PublishPort=127.0.0.1:8080:8080` | この PC の 127.0.0.1 の 8080 を、コンテナの 8080 につなぐ。`127.0.0.1:` を付けているので、この PC の中からしか開けない |
   | `Volume=%h/hello-web:/var/www/html:Z` | ホームの `hello-web` を、コンテナの公開ディレクトリにする。`%h` はホームディレクトリ |
   | `AutoUpdate=registry` | `podman auto-update` の対象にする（[更新](#更新)） |
   | `TimeoutStartSec=300` | 初回はイメージの取得を待つので、起動の待ち時間を延ばす |
   | `WantedBy=default.target` | ユーザーの systemd が起動したときに、このサービスも起動する |

   - `:Z` は、SELinux のラベルをこのコンテナ専用に付け替える指定。ホームそのもの（`%h`）には付けず、コンテナ用のディレクトリにだけ付ける（[注意点](#注意点)）
   - 検証環境は SELinux が無効だったので、`:Z` の効果は確かめていない
   - `ubi10/httpd-24` の Apache は、コンテナの中で root ではないユーザー（`uid=1001(default)`）として動き、8080 で待ち受ける。コンテナの中でも 1024 未満のポートを使わない作りになっている

   </details>

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
   - **`systemctl --user enable` は使わない**。自動で起動するかは、定義の `[Install]` で決まる（この手順の補足）

   <details>
   <summary>補足: 生成されるサービス</summary>

   `daemon-reload` のときに Quadlet が定義を読み、`/run/user/<UID>/systemd/generator/hello-web.service` を作る。中身は次で見られる。

   ```bash
   /usr/libexec/podman/quadlet -dryrun -user
   ```

   出力の抜粋:

   ```
   [Service]
   ...
   ExecStart=/usr/bin/podman run --name hello-web --replace --rm --cgroups=split --sdnotify=conmon -d -v %h/hello-web:/var/www/html:Z --label io.containers.autoupdate=registry --publish 127.0.0.1:8080:8080 registry.access.redhat.com/ubi10/httpd-24:latest

   [Install]
   WantedBy=default.target
   ```

   生成されたサービスに `systemctl --user enable` を使ったときの実測:

   ```
   Failed to enable unit: Unit /run/user/<UID>/systemd/generator/hello-web.service is transient or generated
   ```

   curl に再試行を付けたのは、最初の検証で `start` の直後の `curl -s http://127.0.0.1:8080/` が何も出さず、終了コード 56（受信の失敗）で終わったため。Apache が待ち受けを始める前だった。

   </details>

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
   - `true` なら、新しいイメージを取ってサービスを起動し直す（新しいイメージがあったときの動きは確かめていない）

---

## ロールバック

- 上から順に、通した節の分だけ実行する
- この節の手順 5 の前に、ほかの手順書（distrobox・podman-compose）で作ったものが要らないか確かめる
- Quadlet の節を通し、linger も切るときは、この節の後に [linger.md のロールバック](linger.md#ロールバック)を行う（[Syncthing](syncthing.md)・[Dropbox](dropbox.md) など、ほかに linger を使うものが無いかは、そこで確かめる）

> [!CAUTION]
> **この節の**手順 5 の `podman system reset` で、自分のコンテナ・イメージ・ボリュームがすべて消える。[distrobox](distrobox.md) のボックスや [podman-compose](podman-compose.md) のコンテナも含む。

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
   - 依存で入ったもの（`crun` など）も一緒に消える。検証コンテナでは、手順 2 で入った 30 パッケージがすべて消えた（`Freed space: 91 M`）

---

## 補足

- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

### 対象と検証環境

- **目的**: AlmaLinux 10 で、コンテナを自分のユーザー（rootless）で動かせるようにする。[distrobox](distrobox.md)・[podman-compose](podman-compose.md)・[hadolint / dive / Trivy](image-tools.md)・[podman-tui](podman-tui.md)・[lazydocker](lazydocker.md) の前提になる（CLI にとっての [Homebrew](homebrew.md) と同じ位置づけ）
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **x86_64 のコンテナでのみ検証済み（2026-09-27）。実機では本実行していない**
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま端末に流して**、手順 1〜3・5〜7、2 つの任意節、[更新](#更新)、[ロールバック](#ロールバック)を通した
    - Quadlet の節の linger の有効化と解除（今の [linger.md](linger.md) の手順 2 とロールバックの手順 2。当時は Quadlet の節とロールバックの手順だった）も、このとき通した
  - 手順 4 は、範囲の無いユーザーを同じコンテナに作って、手順 3〜6 を通した
  - 2026-10-02: もとの手順 4・5 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）
  - 2026-10-05: 手順 3・4 を、subuid / subgid の不足する側だけ補う形に直した。一時ファイルと `sudo`・`usermod`・`podman` のスタブで、両方無し・UID のみ有り・GID のみ有り・両方有りを確認した。既存の範囲を変えず、`usermod` が失敗した場合は migrate を呼ばない。実際のユーザー設定と podman では未実行
  - 確認したこと:
    - rootless で `true overlay crun netavark pasta v2` になり、`quay.io/podman/hello` が動く
    - API ソケットが `OK` を返し、Docker の API の `/version` に `Podman Engine` が出る
    - Quadlet のサービスが、コンテナの中での `sudo systemctl reboot` の後、ログインより前に起動する
    - 短い名前の問い合わせ、1024 未満のポート、linger 無しのログアウトでコンテナが止まることを再現した
  - **確認していないこと**: SELinux が有効なときの `:Z`、cgroup のコントローラと資源の制限、実機の再起動、デスクトップのログイン
  - aarch64（Raspberry Pi 5）では通していない

| 項目 | 実機（Raspberry Pi 5） | 実機（x86_64 PC） | 検証コンテナ |
|---|---|---|---|
| 実施日 | —（未実施） | —（未実施） | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64 | AlmaLinux 10.2 (Lavender Lion) / x86_64 | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2`、Docker 29.3.1、`--privileged`） |
| podman | 5.8.2（rootless）。2026-09-22 まで、ほかの手順書の検証に使っていた（[homebrew.md](homebrew.md) の付録）。この手順で入れたものではなく、2026-09-24 のクリーンインストール後は未確認 | 未確認 | 未導入 → `podman-5.8.2-9.el10_2.alma.1` |
| systemd | 未確認 | 未確認 | `systemd-257-23.el10_2.2.alma.1`（PID 1） |
| ログイン | — | — | SSH（コンテナの中の `sshd` に、`<USER>` で鍵認証） |
| SELinux | — | — | 無効 |
| cgroup | — | — | v2。ただしコントローラが無い（ホストが cgroup v1 のため） |
| 保管場所のファイルシステム | — | — | ext4（Docker のボリュームをホームに付けた） |

- 実機の 2 列は、この手順を適用した結果ではない

> [!NOTE]
> 出力例の値は `<USER>` / `<UID>` / `<HOSTNAME>` のプレースホルダで書いてある。バージョン（`5.8.2`）とイメージの大きさは実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（AlmaLinux 10 の `10-init` イメージ）の状態:

| 項目 | 状態 |
|---|---|
| podman | 未導入（`package podman is not installed`） |
| `/etc/subuid` | `<USER>:524288:65536`（`useradd` が割り当てた） |
| linger | 無効 |

### 選択した方針

| 選択肢 | 採否 |
|---|---|
| **AppStream の podman を、自分のユーザー（rootless）で使う** | **採用。** Server の環境では最初から入っていて（手順 1 の補足）、`dnf upgrade` で上がる |
| Homebrew の podman（6.1.2） | 不採用。PATH の先頭で `/usr/bin/podman` を隠す（[ツール一覧](tool-catalog.md#注意点)の実測）。設定も `/home/linuxbrew/.linuxbrew/etc/containers` から読む（formula の定義） |
| root で動かす（`sudo podman`） | 不採用。保管場所が `/var/lib/containers` に分かれ、コンテナが root で動く。1024 未満のポートがどうしても要るときだけ使う |
| Docker Engine（docker-ce） | 対象外。Docker の公式リポジトリに RHEL 10 向けがあるが、本書では入れていない |
| `container-tools`（メタパッケージ） | 不採用。要らないもの（cockpit-podman・toolbox など）まで入る（手順 2 の補足） |
| 自動起動に Quadlet を使う | **採用**（任意節）。podman に含まれ、定義ファイルから systemd のサービスを作る |
| 自動起動に `podman generate systemd` を使う | 不採用。`DEPRECATED command:` と出て、Quadlet を勧められる |

### 完了時点の状態

**検証コンテナでの出力**（実施手順の後）:

```
$ podman version --format '{{.Client.Version}}'
5.8.2
$ command -v podman
/usr/bin/podman
$ podman info --format '{{.Host.Security.Rootless}} {{.Store.GraphDriverName}} {{.Host.OCIRuntime.Name}} {{.Host.NetworkBackend}} {{.Host.RootlessNetworkCmd}} {{.Host.CgroupsVersion}}'
true overlay crun netavark pasta v2
$ podman info --format '{{.Store.GraphRoot}}'
/home/<USER>/.local/share/containers/storage
$ podman images
REPOSITORY            TAG         IMAGE ID      CREATED      SIZE
quay.io/podman/hello  latest      5dd467fce50b  2 years ago  787 kB
$ systemctl --user is-active podman.socket
active
$ curl -s --unix-socket "${XDG_RUNTIME_DIR}/podman/podman.sock" http://d/_ping; echo
OK
$ podman --remote version --format '{{.Server.Version}}'
5.8.2
```

任意節まで通した後は、`~/.bashrc` に `DOCKER_HOST` の行があり、`hello-web.service` が `active`（`generated`）で、`curl -s http://127.0.0.1:8080/` が `hello from quadlet` を返す。

### 注意点

- **イメージは完全な名前で書く**: 短い名前は、端末から実行すると取る場所を聞かれる（手順 6 の補足）
- **`sudo podman` は別の保管場所**: 自分のユーザーのコンテナとイメージは、`sudo podman` からは見えない（[使い方の基本](#使い方の基本)）
  - root のコンテナを lazydocker で見るなら、[lazydocker.md の root でも使う](lazydocker.md#root-でも使う任意)の節（システムの API ソケットを使う）
- **1024 未満のポートは使えない**: 自分のユーザーで `-p 127.0.0.1:80:8080` のように指定すると、次のように失敗する
  - `Error: pasta failed with exit code 1:` と `Failed to bind port 80 (Permission denied) for option '-t 127.0.0.1/80-80:8080-8080'`
  - `sysctl net.ipv4.ip_unprivileged_port_start` は `1024`。8080 など 1024 以上の番号にする
- **`:Z` をホームやシステムのディレクトリに付けない**: `:Z` は指定したディレクトリの SELinux のラベルを付け替える。`podman-run(1)` の `--volume` の説明も、システムのファイルやディレクトリの付け替えを戒めている
- **linger が無いと、ログアウトでコンテナが止まる**: linger の無いユーザーで `podman run -d` を動かしてログアウトすると、約 10 秒後にユーザーの systemd と一緒にコンテナが止まった（検証コンテナで再現）。止めたくないものは Quadlet の節で動かし、[linger](linger.md) を有効にする
- **API ソケットにつなげると、自分のコンテナを何でも操作できる**: ソケットのファイルの権限（`srw-rw----`、持ち主は自分）を変えない
- **容量**: イメージは `~/.local/share/containers/storage` に溜まる。`podman system df` で見て、`podman image prune -a` で掃除する（`ubi10/httpd-24` は 285 MB）
- **Docker Hub には、認証なしの取得に回数の上限がある**: 検証の時点の応答は `ratelimit-limit: 100;w=3600`。本書の例は quay.io と registry.access.redhat.com に寄せた
- **Raspberry Pi 5 で使うイメージは arm64 があるか見る**: `podman manifest inspect <イメージ>` に `"architecture": "arm64"` があればよい。本書の例のイメージにはどれもある
- **Homebrew の formula が podman を連れてくることがある**: podman-compose などを Homebrew で入れると、依存の podman が `/usr/bin/podman` を隠す（[ツール一覧](tool-catalog.md#注意点)）
  - システムの podman との互換性が要るものや、別の podman を依存で入れるものは RPM を選ぶ
  - [image-tools.md](image-tools.md) の hadolint・dive と [lazydocker.md](lazydocker.md) は、RPM の提供状況などを比べて Homebrew を選んでいる

### 参照

- [Basic Setup and Use of Podman in a Rootless environment](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md) — rootless の前提（subuid / subgid、保管場所、ネットワーク）
- [podman-systemd.unit(5)](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) — Quadlet の定義の書き方
- [podman-auto-update(1)](https://docs.podman.io/en/latest/markdown/podman-auto-update.1.html) / [podman-system-service(1)](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html) / [podman-system-reset(1)](https://docs.podman.io/en/latest/markdown/podman-system-reset.1.html)
- [podman-run(1)](https://docs.podman.io/en/latest/markdown/podman-run.1.html) — `--volume` の `:Z`、`--publish`
- [RHEL 10 — Building, running, and managing containers](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/building_running_and_managing_containers/index) — RHEL の podman の文書
- `man containers-registries.conf` — 短い名前の扱い（`unqualified-search-registries`・`short-name-mode`）
- [linger](linger.md) — [Quadlet の節](#quadlet-で自動起動する任意)の前提の手順書

---

### 付録: コンテナでの検証記録（2026-09-27）

**環境**: Ubuntu 24.04 / x86_64 のクラウドホスト上の Docker 29.3.1（cgroup v1）。実機で加えた変更は無い。

- イメージは `quay.io/almalinuxorg/10-init:10.2`（`sha256:a91c1066…fd73`、AlmaLinux 10.2）
- `--privileged`・`--network host` で立て、systemd を PID 1 にした

**手順書の外で行った準備**（検証環境の都合）:

- **cgroup**: ホストは cgroup v1 なので、コンテナの入口のスクリプトで、ホストの cgroup2 の下に自分の枝を作って `/sys/fs/cgroup` に付け直してから systemd を起動した。この cgroup2 にはコントローラが 1 つも無い
- **PID 数の制限**: podman の既定の制限（2048）を crun が設定できず、``crun: controller `pids` is not available ...`` で失敗した
  - `/etc/containers/containers.conf.d/90-verify-pids.conf` に `pids_limit = 0` を書いて外した
  - `registries.conf` などには触れていない
- **保管場所**: コンテナの `/` は Docker の overlay で、rootless の overlay を重ねられないので、`/home` と `/var/lib/containers` に Docker のボリューム（ext4）を付けた
- **デバイスとマウント**: `/dev/net/tun` と `/dev/fuse` を 0666 に、`/` を shared にした（実機の EL10 と同じ形。Docker の既定のままだと、podman が `"/" is not a shared mount` と警告した）
- **logind**: `10-init` のイメージが mask している `systemd-logind` を戻した
- **プロキシ**: CA を信頼ストアに足し、dnf にプロキシを設定し、AlmaLinux のミラー一覧を https にした。ログインシェルとユーザーの systemd（`/etc/systemd/user.conf.d`）にプロキシの環境変数を渡した
- **ログイン**: コンテナの中の `sshd`（127.0.0.1）に、`<USER>`（NOPASSWD の sudo）で鍵を使ってログインした
  - pam_systemd がセッションを作るので、`XDG_RUNTIME_DIR` とユーザーの systemd は実機の SSH と同じ形で用意される

**流し方**:

- 本文の折り畳みの外にある bash のブロックを上から順に抜き出し、SSH のログインシェルの端末（pty）に 1 ブロックずつ流した。貼り付け（bracketed paste）ではなく 1 行ずつ打ち込む形で、実際に貼るより厳しい
- `[y/N]` の確認には pty 越しに `y` と答えた。コマンドに `-y` は足していない
- 手順 4 は、`useradd -K SUB_UID_COUNT=0 -K SUB_GID_COUNT=0` で作った範囲の無いユーザーで、手順 3〜6 を通した
- Quadlet の節の手順 3 は、コンテナの中で `sudo systemctl reboot` を実行し、止まったコンテナを `docker start` で起動し直した。ログインせずに 30 秒待ってから SSH で入り直し、手順 4 を流した

| 手順 | 結果 |
|---|---|
| 1〜2. 導入 | `podman は未導入` → 30 パッケージ（ダウンロード 29 MB、展開後 91 MB）。`container-selinux` は入らなかった（手順 2 の補足） |
| 3. subuid | `/etc/subuid:<USER>:524288:65536` と `/etc/subgid:<USER>:524288:65536` |
| 4.（範囲の無いユーザー） | 手順 3 は `subuid / subgid の割り当てが無い`。手順 4 で `589824` から割り当てられ、確かめの行（もとの手順 5）は 2 行、手順 5 は `true overlay crun netavark pasta v2`、手順 6 も動いた |
| 5. 設定 | `5.8.2`、`/usr/bin/podman`、`true overlay crun netavark pasta v2`、`/home/<USER>/.local/share/containers/storage` |
| 6. 動作 | `!... Hello Podman World ...!`。`podman images` に `quay.io/podman/hello`（787 kB） |
| 7. ソケット | `Created symlink ...podman.socket ...`、`active`、`OK`、`5.8.2` |
| Docker 向け | `unix:///run/user/<UID>/podman/podman.sock`、`"Name":"Podman Engine"` |
| Quadlet 1・2（当時は linger の有効化と確認も、この節の手順だった。今の linger.md の手順 2） | `Linger=yes`、`active`、`generated`、`hello from quadlet` |
| Quadlet 3・4 | 起動し直した後、ログインする前のセッションは linger の `manager` だけ。`ActiveEnterTimestamp` が 17:38:06、ログインが 17:38:37 で、`hello from quadlet` |
| 更新 | `Nothing to do.`。`podman auto-update` は `UPDATED` が `false` |
| ロールバック | 手順 4 でイメージ 2 つ（285.8 MB）を確かめ、手順 5 の確認に `y`、手順 6 で 30 パッケージを消した（`Freed space: 91 M`） |

**最初の試行で見つけて直したこと**: Quadlet の節の手順 2 の `curl` に再試行を付けていなかったときは、`start` の直後の `curl` が何も出さずに終了コード 56 で終わった（手順 2 の補足）。

**落とし穴の再現**（同じ作りの別のコンテナで、手順書の外のコマンドとして実行）:

- `sudo -iu` / `su -` / `runuser -l` で切り替えたシェルでの `systemctl --user` と `podman`（手順 7 の補足）
- 短い名前の問い合わせ（手順 6 の補足。TTY の有無で比べた）
- 1024 未満のポートのエラー、linger の無いユーザーのログアウト（約 10 秒後にコンテナが止まった）、`sudo podman images`（空の一覧）
- `podman generate systemd` の `DEPRECATED command:`、生成された unit への `systemctl --user enable` のエラー
- [使い方の基本](#使い方の基本)の表のコマンド（`podman image prune` は `-a` の有無で消えるものが変わった）

**残っている差**（検証環境と実機の違い）:

- SELinux が無効（`:Z` は効果を確かめていない）
- cgroup v2 にコントローラが無い（`cgroupControllers: []`）。PID 数の制限は検証環境だけ外した
- カーネルはクラウドのホストの 6.18 系（EL10 は 6.12 系）で、IPv6 はホストで無効

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- SELinux が有効なときの `:Z` と、`container-selinux` のラベル
- cgroup のコントローラ（`memory`・`pids` など）の委譲と、`--memory` などの資源の制限
- 実機の再起動の後の Quadlet の起動（検証はコンテナの再起動）
- デスクトップ（GNOME）のログインのセッションから使ったときの動き
- LAN に公開するポートと firewalld
- 新しいイメージがあるときの `podman auto-update`
- Raspberry Pi 5 のカーネルのページサイズと、イメージの動作への影響
