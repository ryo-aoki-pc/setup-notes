# distrobox インストール手順（AlmaLinux 10 / EPEL）

## 実施手順

- [検証記録](verification/distrobox.md)・[参考資料](reference/distrobox.md)

> [!IMPORTANT]
> - **前提**: [Podman](podman.md) の実施手順と、[AlmaLinux 10 の初期設定の手順 17](almalinux-setup.md#実施手順)（EPEL）を通してあること（distrobox は EPEL にあり、AppStream には無い）。`podman info --format '{{.Host.Security.Rootless}}'` が `true` を返さないか、`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（ボックスは自分のユーザーの rootless の podman で動かすため）
> - **手順 2 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）。答えてから手順 3 を貼る
> - **手順 5 と 6 はボックスの中のコマンドになる**。手順 5 は終わってから、手順 6 は `exit` で戻ってから、次を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: ボックスに入れたコマンドをホストから呼ぶなら[ボックスのコマンドをホストから呼ぶ（任意）](#ボックスのコマンドをホストから呼ぶ任意)。以後は[更新](#更新)・[ロールバック](#ロールバック)

1. 変数を設定する。

   ```bash
   DBX_NAME=ubuntu                                  # ボックスの名前。<DBX_NAME>
   DBX_IMAGE=quay.io/toolbx/ubuntu-toolbox:24.04    # 元にするイメージ。<DBX_IMAGE>
   printf '%-9s = %s\n' DBX_NAME "${DBX_NAME}" DBX_IMAGE "${DBX_IMAGE}"
   ```

   - **編集が必須の変数は無い**。既定のままなら、Ubuntu 24.04 のボックスができる
   - 別のディストリにするときだけ `DBX_IMAGE` を変える（候補はこの手順の補足）
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. 入手できる版を見てから、distrobox を入れる。

   ```bash
   dnf -q list --showduplicates distrobox
   sudo dnf install distrobox
   ```

   - 版は `distrobox.noarch  1.8.2.3-1.el10_2  epel` のように 1 つだけ出る
   - 一緒に入るのは `hicolor-icon-theme` だけ（podman は前提の手順で入っている）
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y` と答える
   - [AlmaLinux 10 の初期設定の手順 17](almalinux-setup.md#実施手順) に書いた鍵
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. distrobox が入ったか確かめる。

   ```bash
   distrobox version
   command -v distrobox
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' distrobox
   distrobox list
   ```

   - `distrobox: 1.8.2.3`、`/usr/bin/distrobox`、`distrobox 1.8.2.3-1.el10_2 epel` が出る
   - `distrobox list` は見出しの行だけを出す（ボックスはまだ無い）

1. ボックスを作る。

   ```bash
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
   - その後に `PRETTY_NAME="Ubuntu 24.04.5 LTS"`・自分のユーザー名・`/home/<USER>` が出る。ユーザーもホームもホストと同じ
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ボックスのシェルに入る。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}"
   ```

   - プロンプトが `📦[<USER>@ubuntu ~]$` に変わる。ここから先はボックスの中のシェル
   - SSH など画面の無いログインから入ると、`host-spawn: command not found` が 4 行出る（理由はこの手順の補足）
   - `exit` でホストに戻る
   - **後ろの節の手順は、`exit` でホストに戻ってから貼る**

---

## ボックスのコマンドをホストから呼ぶ（任意）

- 例として、AppStream と EPEL に無い `ffmpeg` を Ubuntu のボックスに入れ、ホストのシェルから `ffmpeg` で呼べるようにする
- ボックスに入れたものはボックスの中にだけある。ホストには、ボックスを呼び出す小さなスクリプトが `~/.local/bin` に置かれる
- **この節の手順はどれも `distrobox enter` で終わる**。プロンプトが戻ってから次を貼る

1. ボックスのパッケージの一覧を新しくする。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- sudo apt-get update
   ```

   - `Reading package lists...` で終わる
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ボックスに ffmpeg を入れる。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- sudo apt-get install -y ffmpeg
   ```

   - ボックスの中の `sudo` はパスワードを聞かない（参考資料を参照）
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ffmpeg をホストから呼べるように書き出す。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- distrobox-export --bin /usr/bin/ffmpeg --export-path ~/.local/bin
   ```

   - `/usr/bin/ffmpeg from ubuntu exported successfully in /home/<USER>/.local/bin.` と `OK!` が出る
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ホストのシェルから ffmpeg を呼ぶ。

   ```bash
   command -v ffmpeg
   ffmpeg -version | head -1
   ```

   - `/home/<USER>/.local/bin/ffmpeg` と `ffmpeg version 6.1.1-3ubuntu5 ...` が出ればよい
   - `~/.local/bin` は、AlmaLinux の既定の `~/.bashrc` で PATH に入っている

---

## 更新

1. distrobox を更新する。

   ```bash
   sudo dnf upgrade distrobox
   ```

   - システム全体なら `sudo dnf upgrade`
   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. ボックスの中のパッケージを更新する。

   ```bash
   distrobox upgrade "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}"
   ```

   - Ubuntu のボックスでは `apt-get update` と `apt-get upgrade` が確認なしで走る
   - **ボックスの中身は `dnf upgrade` では上がらない**。ボックスごとにこの手順を行う
   - **次の節は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

---

## ロールバック

- 上から順に実行する
- ホームはボックスと共有しているので、ボックスを消してもホームのファイルは残る。消えるのは、ボックスの中に入れたパッケージとボックスの `/etc` など

1. ホストから呼べるようにしていたときだけ、書き出したスクリプトを消す。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- distrobox-export --bin /usr/bin/ffmpeg --export-path ~/.local/bin --delete
   ```

   - `/usr/bin/ffmpeg from ubuntu removed successfully from /home/<USER>/.local/bin.` が出る
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ボックスを消す。

   ```bash
   distrobox rm "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}"
   ```

   - `Do you really want to delete containers: ubuntu? [Y/n]` に `y` と答える
   - ボックスが動いていると、続けて `Container  ubuntu running, do you want to force delete them? [Y/n]` も聞かれる。これも `y`
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. ボックスの元にしたイメージを消し、ボックスが無くなったことを確かめる。

   ```bash
   podman rmi "${DBX_IMAGE:?手順 1 の DBX_IMAGE が空のまま。値を入れて貼り直す}"
   distrobox list
   ```

   - `distrobox list` が見出しの行だけになればよい

1. distrobox を消す。

   ```bash
   sudo dnf remove distrobox
   ```

   - `[y/N]` で聞かれる
   - 依存で入った `hicolor-icon-theme` も、ほかに使うものが無ければ一緒に消える
   - **EPEL 自体は消さない**（ほかのパッケージが使っている可能性がある）。消すなら [AlmaLinux 10 の初期設定のロールバック](almalinux-setup.md#ロールバック)の手順 34・35

---

## 注意点

- **ボックスは隔離ではない**: ホームを共有し、ホストのファイルシステム全体が `/run/host` に見え、ネットワークとプロセスもホストと同じ（参考資料を参照）。信用できないソフトを試す場所にはしない
- **ボックスの `sudo` はホストの root ではない**: 本書の `--userns keep-id` では、ボックスの root はホストの subordinate UID に対応する。自分の UID はボックス内の同じ UID に対応し、ホストの root の権限は得られない
- **`distrobox enter` が動いている間に貼った行は、ボックスへの入力になる**: 端末の入力をボックスの中のコマンドへ渡し続けるため
  - `distrobox enter <名前> -- <コマンド>` の処理が終了してプロンプトに戻ってから、次の手順を貼る
  - 本書の手順は、どれも `distrobox enter` で終わるように分けてある
- **書き出したスクリプトの名前が、ホストのコマンドと重なることがある**: `~/.local/bin` は PATH の途中にある
  - 同じ名前のコマンドがほかの場所にもあると、どちらが呼ばれるかは PATH の順で決まる
  - Homebrew の `brew shellenv` は、自分の場所を PATH の先頭に足す
- **`podman system reset` でボックスも消える**: ボックスは podman のコンテナなので、[podman.md のロールバック](podman.md#ロールバック)の手順 5 で一緒に消える
- 必要な空き容量は、導入予定のパッケージとトランザクション表で確かめる
