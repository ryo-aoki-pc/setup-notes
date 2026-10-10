# distrobox インストール手順（AlmaLinux 10 / EPEL）

## 実施手順

- [検証記録](verification/distrobox.md)・[参考資料](reference/distrobox.md)・[ロールバックと注意点](extra/distrobox.md)

> [!IMPORTANT]
> - **前提**: [Podman](podman.md) の実施手順と、[AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」の手順 1](almalinux-setup.md#epel-と-rpm-fusion)（EPEL）を通してあること（distrobox は EPEL にあり、AppStream には無い）。`podman info --format '{{.Host.Security.Rootless}}'` が `true` を返さないか、`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（ボックスは自分のユーザーの rootless の podman で動かすため）
> - **手順 2 には対話入力がある**（トランザクション表の `[y/N]` と、EPEL の鍵の確認）。答えてから手順 3 を貼る
> - **手順 5 と 6 はボックスの中のコマンドになる**。手順 5 は終わってから、手順 6 は `exit` で戻ってから、次を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 手順の後: ボックスに入れたコマンドをホストから呼ぶなら[ボックスのコマンドをホストから呼ぶ（任意）](#ボックスのコマンドをホストから呼ぶ任意)。以後は[更新](#更新)・[ロールバック](extra/distrobox.md#ロールバック)

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
   - 一緒に入るのは `hicolor-icon-theme` だけ
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
   - SSH など画面の無いログインから入ると、`host-spawn: command not found` が 4 行出る
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

   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ffmpeg をホストから呼べるように書き出す。

   ```bash
   distrobox enter "${DBX_NAME:?手順 1 の DBX_NAME が空のまま。値を入れて貼り直す}" -- distrobox-export --bin /usr/bin/ffmpeg --export-path ~/.local/bin
   ```

   - `/usr/bin/ffmpeg from ubuntu exported successfully in /home/<USER>/.local/bin.` と `OK!` が出る
   - **次の手順は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）

1. ホストのシェルから ffmpeg を呼ぶ。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   command -v ffmpeg
   ffmpeg -version | head -1
   ```

   - `/home/<USER>/.local/bin/ffmpeg` と `ffmpeg version 6.1.1-3ubuntu5 ...` が出ればよい

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

   - **ボックスの中身は `dnf upgrade` では上がらない**。ボックスごとにこの手順を行う
   - **次の節は、プロンプトが戻ってから貼る**（続けて貼るとボックスの中のコマンドへの入力として食われる）
