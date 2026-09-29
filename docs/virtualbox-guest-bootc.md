# VirtualBox Guest Additions 導入手順（AlmaLinux 10 bootc / Atomic Desktop のゲスト）

## 実施手順

> [!IMPORTANT]
> - **VirtualBox の VM の中の AlmaLinux Atomic Desktop（GNOME）にログインし、端末を開いて自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない
> - **dnf では入れない**。Guest Additions を焼き込んだ派生イメージをこの VM でビルドし、`bootc switch` で切り替える（手順 5〜9）
> - **手順 6 と手順 12 は、VM のウィンドウで行う**（手順 6 の CD の挿入は、ホスト側の操作）
> - **手順 9 で再起動する**。Secure Boot が有効なら、手順 10 で起動の途中の MokManager の画面を VM のウィンドウで操作する（最初の画面は 10 秒で消える）
> - **手順 4 には対話入力（一時パスワード）がある**。手順 8 はビルドが終わるのを待ってから次を貼る

- 手順 1 の変数を設定したシェルで、上から順にコードブロックを貼る。新しい端末を開いたら手順 1 を貼り直す
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 共有フォルダーは[共有フォルダーを使う（任意）](#共有フォルダーを使う任意)、OS やホストの VirtualBox を上げたときは[更新](#更新)、戻すときは[ロールバック](#ロールバック)
- **切り替えた後は、`sudo bootc upgrade` だけでは OS が上がらない**（[更新](#更新)の手順でビルドし直す）
- 自作の kernel-rt のイメージでも、手順 1 の `BASE_IMAGE` を変えるだけで同じ手順になる（イメージで `rt` のリポジトリを有効にしておく）
  - kernel-rt では、起動のたびに `vboxguest` を読み込んだ直後に、カーネルの `WARNING` が 1 回出る（Guest Additions は動く。手順 11 の補足）
- VirtualBox のメニューの名前は、日本語の表示と英語の表示を並べて書いてある

1. 変数を設定する（既定のままでよい）。

   ```bash
   BASE_IMAGE=quay.io/almalinuxorg/atomic-desktop-gnome:latest   # 元のイメージ（手順 2 の Booted image）
   echo "BASE_IMAGE = ${BASE_IMAGE}"
   ```

   - 公式の ISO で入れた Atomic Desktop の GNOME なら、このままでよい（ISO は `:latest` を追う。この手順の補足）
   - KDE なら `quay.io/almalinuxorg/atomic-desktop-kde:latest` のように、手順 2 の `Booted image:` に合わせて変える（本書では GNOME だけを検証した）
   - 自作の kernel-rt のイメージ（レジストリにあるもの）なら、手順 2 の `Booted image:` に合わせて、そのイメージの名前にする
     - 手順 5 の Containerfile がカーネルを見分けて、`kernel-rt-devel` でビルドする
     - `kernel-rt-devel` は `rt` のリポジトリにしか無いので、そのイメージで `rt` を有効にしておく（手順 5 の補足）
     - VM では、検証用に作った kernel-rt のイメージで確かめた（手順 5 の補足）
   - 手順 8、[更新](#更新)、[ロールバック](#ロールバック)で使う

   <details>
   <summary>補足: 既定を <code>:latest</code> にしている理由</summary>

   - Atomic Desktop の公式の ISO（`atomic-desktop-gnome-amd64.iso`）は、インストールの最後に `quay.io/almalinuxorg/atomic-desktop-gnome:latest` を追うように切り替える
     - atomic-desktop の `iso.toml` のキックスタートの `%post` が `bootc switch --mutate-in-place` を実行し、ISO のビルドの設定がタグを `latest` にしている
   - VM に ISO から入れると、手順 2 の `Booted image:` は `:latest` だった。以前の既定の `:10` のままでは、手順 2 で食い違った
   - 2026-09-28 に quay.io の API で見たときは、`:latest`・`:10`・`:10.2` が同じ digest を指していた。追うタグが違えば、いずれ中身がずれる
   - `bootc switch` で別のタグ（`:10` など）に切り替えた VM では、手順 2 の `Booted image:` と同じ値にする

   </details>

1. VirtualBox の VM で bootc のシステムが動いているかと、空き容量を確かめる。

   ```bash
   systemd-detect-virt
   df -h /var
   sudo bootc status
   ```

   - 1 行目が `oracle`（VirtualBox）ならよい
   - `/var` の `Avail` が 10 GB 以上あればよい（手順 8 でベースのイメージをもう 1 つ取り込むため。この手順の補足）
   - `● Booted image:` が手順 1 の `BASE_IMAGE` と同じならよい。違えば手順 1 を直して貼り直す
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 空き容量の目安と、表示の例</summary>

   **空き容量の目安**（検証コンテナでの実測）:

   - ベースのイメージ（`atomic-desktop-gnome:10` = 10.2.20260924.1）は、podman の置き場所（`/var/lib/containers`）で 4.92 GB になる。取り込むのは 83 層・圧縮で約 2.2 GB
   - 派生イメージで増えるのは 151 MB。そのうち 98 MB は、ビルドの道具を入れて消したときに書き直される rpm のデータベース
   - ビルドの途中では、gcc・kernel-devel（kernel-rt なら kernel-rt-devel）など 15 パッケージが一時的に入る
   - `bootc switch` は、動いているイメージと中身が同じファイルを共有して取り込む。ベースが新しくなっていれば、そのぶんが増える

   **VM での実測**（80 GB のディスクに ISO の既定のパーティション）:

   - `/var` は 47G で、使用量は ISO で入れた直後が 5.7G、手順 8 の後が 11G、[ロールバック](#ロールバック)の後が 6.1G だった
   - 手順 8 の後の内訳は、`/var/lib/containers` が 5.2G、`/sysroot/ostree/repo` が 4.5G

   **`systemd-detect-virt`**: VM では `oracle` だった（`systemd-detect-virt --list` にある名前）。検証コンテナでは `podman` を返した。

   **`bootc status`**: VM に ISO から入れた直後は、次のとおりだった（検証コンテナには起動したシステムが無いので、`booted: null` の YAML が出た）。

   ```
   mount: (hint) your fstab has been modified, but systemd still uses
          the old version; use 'systemctl daemon-reload' to reload.
   ● Booted image: quay.io/almalinuxorg/atomic-desktop-gnome:latest
           Digest: sha256:<DIGEST> (amd64)
          Version: 10.2.20260918.1 (2026-09-19T10:12:11Z)
   ```

   - 先頭の `mount: (hint)` の 2 行は、この VM では `bootc status`・`bootc switch`・`bootc upgrade` を実行するたびに出た。手順の結果には影響しなかった

   </details>

1. Secure Boot が有効かを見る。

   ```bash
   mokutil --sb-state
   ```

   - `SecureBoot enabled` のときだけ、手順 4 でモジュールの署名鍵を用意し、手順 13 で登録を確かめる
   - 以前に手順 4 を済ませている（`/var/lib/shim-signed/mok/MOK.der` がある）なら、手順 4 は飛ばす（鍵を作り直すと、登録済みの鍵と合わなくなる）
   - **`SecureBoot disabled`（または `EFI variables are not supported on this system`）なら、手順 4・10・13 は飛ばす**

   <details>
   <summary>補足: Secure Boot とモジュールの署名</summary>

   - EL10 のカーネルは `CONFIG_MODULE_SIG=y`・`CONFIG_LOCK_DOWN_IN_EFI_SECURE_BOOT=y`・`CONFIG_MODULE_SIG_HASH="sha512"`（kernel-devel の `.config` で確認）。Secure Boot のときは、署名の無いモジュールを読み込まない
   - VM で Secure Boot が有効になるのは、VM の設定の「システム」→「マザーボード」で「UEFI」と「セキュアブート」を有効にしている場合（英語の表示では System → Motherboard の UEFI と Secure Boot）
   - Guest Additions のインストーラは、Secure Boot なら自分でモジュールに署名する処理を持つ
     - ただし判定は `mokutil --sb-state` の答えだけで、ビルドの中（コンテナ）では `EFI variables are not supported on this system` になるので署名しない
     - そのため、手順 8 のビルドで鍵を渡して署名する

   </details>

1. Secure Boot が有効なときだけ、署名用の鍵を作り、MOK への登録を予約する。

   ```bash
   {
     sudo mkdir -m 0700 -p /var/lib/shim-signed/mok
     sudo openssl req -nodes -new -x509 -newkey rsa:2048 -outform DER -addext "extendedKeyUsage=codeSigning" -subj "/CN=VirtualBox Guest Additions module signing key/" -days 36500 -keyout /var/lib/shim-signed/mok/MOK.priv -out /var/lib/shim-signed/mok/MOK.der
     sudo ls -l /var/lib/shim-signed/mok
     sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
   }
   ```

   - 鍵を作る間は `.....+++` のような行が流れる
   - `MOK.priv`（秘密鍵。`-rw-------`）と `MOK.der`（公開鍵の証明書）ができる
   - 最後の `mokutil --import` で、公開鍵を UEFI の MOK に登録する予約をする
   - **一時パスワードを 2 回聞かれる**（手順 10 の MokManager で 1 回だけ使う。本書には残さない）
   - **次の手順は、一時パスワードに答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 鍵の置き場所と使われ方</summary>

   - 置き場所とファイル名は、ホスト側の [virtualbox.md 手順 12](virtualbox.md#実施手順) と同じ。Guest Additions の起動スクリプト（`vboxadd`）も、この 2 つを決め打ちで見る
   - bootc でも `/var` は再起動や `bootc switch` をまたいで残る（イメージから上書きされない）
   - 鍵はイメージに入れない。手順 8 のビルドに `--secret` で渡し、ビルドの中の `sign-file`（kernel-devel）がモジュールに署名する
   - 証明書は `CA:TRUE` と `Code Signing` を持つ（検証で `openssl x509` で確認）
   - VM では、登録した鍵は `.platform` のキーリングに入り、`.machine` には入らなかった（`sudo keyctl list %:.platform`。理由は virtualbox.md 手順 12 の補足）
   - **鍵を作り直したら**、手順 8 のビルドに `--no-cache` を足す（[更新](#更新)）
   - `MOK.priv` は、この VM が信頼するモジュールを作れる鍵になる。root 以外に読ませず、ほかのマシンに持ち出さない

   </details>

1. ビルド用のディレクトリに Containerfile を置く。

   ```bash
   mkdir -p ~/vbox-ga-image
   cat > ~/vbox-ga-image/Containerfile <<'EOF'
   # VirtualBox Guest Additions を焼き込んだ派生イメージ（docs/virtualbox-guest-bootc.md）
   ARG BASE_IMAGE=quay.io/almalinuxorg/atomic-desktop-gnome:10

   FROM scratch AS ctx
   COPY VBoxLinuxAdditions.run /

   FROM ${BASE_IMAGE}
   ARG MOK_SIGN=0
   RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
       --mount=type=tmpfs,target=/tmp \
       --mount=type=secret,id=mok_priv \
       --mount=type=secret,id=mok_der <<'EOS'
   # -x: 実行するコマンドを「+」付きでビルドの表示に出す（最後の結果の表示の前で止める）
   set -euxo pipefail
   # イメージのカーネル（bootc のイメージには 1 つだけ）。kernel-rt のイメージでは版の末尾に +rt が付く
   kver=$(ls /usr/lib/modules)
   mods=/usr/lib/modules/${kver}/misc

   # VBoxClient が XWayland のクリップボードで読み込む（イメージに無いと --clipboard が落ち続ける）
   dnf -y install libXt

   # ビルドの道具（最後に消す）。カーネルと同じ版の kernel-devel か kernel-rt-devel が、イメージで有効なリポジトリから入る
   dnf -y install gcc make "kernel-devel-uname-r = ${kver}"

   # イメージのカーネル向けにビルドする。ビルド中はモジュールを読み込めないので、終了コードは 0 にならない
   TARGET_VER=${kver} sh /ctx/VBoxLinuxAdditions.run --nox11 || echo "installer exit=$?"
   test -f "${mods}/vboxguest.ko"
   test -f "${mods}/vboxsf.ko"
   set -- /opt/VBoxGuestAdditions-*
   ga=$1
   test -x "${ga}/init/vboxadd"

   # ビルド中は systemd が動いていないので、インストーラは SysV のスクリプトを置く。systemd の unit に作り直す
   rm -f /etc/rc.d/init.d/vboxadd /etc/rc.d/init.d/vboxadd-service
   (
     . "${ga}/routines.sh"
     systemd_wrap_init_script "${ga}/init/vboxadd" vboxadd
     systemd_wrap_init_script "${ga}/init/vboxadd-service" vboxadd-service
   )
   systemctl enable vboxadd.service vboxadd-service.service

   # Secure Boot のときは MOK の鍵で署名する
   if [ "${MOK_SIGN}" = 1 ]; then
     hash=$(sed -n 's/^CONFIG_MODULE_SIG_HASH="\(.*\)"$/\1/p' "/usr/src/kernels/${kver}/.config")
     for m in "${mods}"/vbox*.ko; do
       "/usr/src/kernels/${kver}/scripts/sign-file" "${hash}" /run/secrets/mok_priv /run/secrets/mok_der "${m}"
     done
   fi
   depmod -a "${kver}"

   # /var はイメージから更新されないので、設定は /usr に置いて起動時にリンクを張る
   mkdir -p /usr/share/factory/var/lib
   mv /var/lib/VBoxGuestAdditions /usr/share/factory/var/lib/
   echo 'L+ /var/lib/VBoxGuestAdditions - - - -' > /usr/lib/tmpfiles.d/vboxadd.conf

   # ユーザーとグループは起動時に systemd-sysusers で作る
   cat > /usr/lib/sysusers.d/vboxadd.conf <<'EOT'
   u vboxadd -:1 - /var/run/vboxadd /bin/false
   g vboxsf -
   g vboxdrmipc -
   EOT

   dnf -y remove gcc make "kernel-devel-uname-r = ${kver}"
   dnf clean all
   rm -rf /var/lib/dnf /var/cache/dnf /var/cache/ldconfig /var/log/dnf.* /var/log/hawkey.log /var/log/vboxadd-*

   # 結果を表示する（コマンドの表示は止める）
   set +x
   for m in "${mods}"/vbox*.ko; do
     echo "${m##*/}: $(modinfo -F vermagic "${m}")signer=$(modinfo -F signer "${m}")"
   done
   systemctl is-enabled vboxadd.service vboxadd-service.service
   EOS

   RUN bootc container lint
   EOF
   ls -l ~/vbox-ga-image
   ```

   - ヒアドキュメントは `<<'EOF'`（クォート付き）。`${...}` はシェルではなく、ビルドの中で展開される
   - `Containerfile` の 1 行が出ればよい

   <details>
   <summary>補足: Containerfile がしていること</summary>

   Guest Additions のインストーラ（`VBoxLinuxAdditions.run`）を、ベースのイメージの上でそのまま動かし、bootc では困るところを直してから、ビルドの道具を消す。足りないライブラリ（`libXt`）も入れる。

   **インストーラをそのまま動かすと、bootc では 4 か所が困る**（手を加えずに流した試作ビルドでの実測）:

   | 困るところ | そのままだと | 直し方 |
   |---|---|---|
   | systemd の unit | インストーラは `systemctl status` が通るとき（systemd が PID 1 のとき）だけ unit を作る。ビルドの中では `/etc/rc.d/init.d` に SysV のスクリプトを置き、`chkconfig` も無いので有効にならない（`systemctl is-enabled vboxadd` が `disabled`） | SysV のスクリプトを消し、同梱の `routines.sh` の `systemd_wrap_init_script`（インストーラが systemd のときに使う関数）で unit を作って `systemctl enable` |
   | `/var/lib/VBoxGuestAdditions/config` | bootc はイメージの `/var` を最初のインストールでしか展開しない。切り替えた VM には入らず、`vboxadd` が `Configuration file /var/lib/VBoxGuestAdditions/config not found` で止まる | `/usr/share/factory` へ移し、tmpfiles.d の `L+` で起動のたびにリンクを張る |
   | ユーザー `vboxadd`、グループ `vboxsf`・`vboxdrmipc` | ビルドの中の `useradd` / `groupadd` はイメージの `/etc/passwd` に書く。手元で変更済みの `/etc/passwd` は切り替えで上書きされないので、VM には入らない | `/usr/lib/sysusers.d` に書き、起動時に `systemd-sysusers` に作らせる |
   | モジュールのカーネルの版 | 既定では、ビルドしているシステム（`uname -r`）のカーネル向けにビルドする | 環境変数 `TARGET_VER` でイメージのカーネル（`/usr/lib/modules` の版）を指定する |

   - `bootc container lint` は、直す前は `sysusers`・`var-log`・`var-tmpfiles` の 3 つを警告した。直した後は `Checks passed: 13`（ベースのイメージと同じ）になる
   - インストーラの終了コードは、ビルドの中では 0 にならない（最後にモジュールが読み込まれているかを見るため）。成否は、2 つのモジュールがあるかで判定している
   - インストーラが `/var` に残すログと dnf のキャッシュも消している（残すと `var-log`・`var-tmpfiles` の警告になる）
   - 先頭の `ARG BASE_IMAGE` の既定値（`:10`）は、手順 8 の `--build-arg` で上書きされるので使われない

   **コマンドの表示**（`set -x`。検証コンテナでの実測）:

   - RUN の中のコマンドは、実行する前に `+` を付けてビルドの表示に出る（`$(…)` の中のコマンドは `++`）
     - 変数は展開した値で出るので、カーネルの版（`+ kver=…`）や、署名のハッシュ（`+ hash=sha512`）も分かる
   - インストーラ（`sh /ctx/VBoxLinuxAdditions.run`）は別のプロセスなので、中のコマンドは出ない。インストーラ自身の表示は、これまでどおり出る
   - `routines.sh` を読むサブシェルは `-x` を引き継ぐので、`systemd_wrap_init_script` の中の行も出る（unit 2 つで約 90 行）
   - ヒアドキュメントの中身（sysusers.d の 3 行）は出ない（`+ cat` の 1 行だけ）
   - 最後の結果の行の前で `set +x` にしているので、手順 8 の「最後に次が出ればよい」の行は、トレースと混ざらずに出る
   - トレースは標準エラーに出るので、標準出力の行と前後が入れ替わることがある（`installer exit=1` の後に `+ echo 'installer exit=1'` が出た）

   **kernel-rt のイメージ**（検証用に作ったイメージでの実測。コンテナと VM）:

   - カーネルの版は、イメージの `/usr/lib/modules` から取る（bootc のイメージにはカーネルが 1 つだけ）
     - kernel-rt のイメージには `kernel-core` が無い（`kernel-rt-core` が持つ）ので、`rpm -q kernel-core` では取れない
     - 版の末尾に `+rt` が付く（`6.12.0-211.56.1.el10_2.x86_64+rt`）ので、`kernel-devel-<版>` という名前も成り立たない
   - 道具は `kernel-devel-uname-r = <版>` で指定する。`kernel-devel` は `…x86_64`、`kernel-rt-devel` は `…x86_64+rt` を provide するので、1 行でどちらにも合う
   - `kernel-rt-devel` は `rt` のリポジトリにしか無い（AppStream・BaseOS には無い）
     - dnf には `--repo` を付けないので、イメージで有効なリポジトリから入る。kernel-rt のイメージでは `rt` を有効にしておく
     - 公式のイメージの `almalinux-rt.repo` は `enabled=0`。`rt` が無効のままの kernel-rt のイメージでは、`No match for argument: kernel-devel-uname-r = …+rt` で止まった
   - 公式のイメージでは、dnf は有効な baseos・appstream・crb・extras・epel を読み、道具として入るのは 15 パッケージだった
   - 署名（`.config` と `sign-file`）・`depmod`・`TARGET_VER` は同じ版を使うので、kernel-rt でもそのまま通る。3 つのモジュールは、PREEMPT_RT のカーネル向けにもビルドできた
   - kernel-rt のイメージに切り替えた VM でも、手順 1〜13 がそろった（Secure Boot の有効と無効。[付録](#付録-kernel-rt-のイメージの-vm-での本実行2026-09-29)）
     - `…+rt` のカーネルで起動し、モジュールが読み込まれ、クリップボード・画面の大きさ・共有フォルダー・時刻の同期が動いた
     - ただし `vboxguest` を読み込んだ直後に、カーネルの `WARNING` が 1 回出る（手順 11 の補足）

   **`libXt` を入れる**（VM での実測）:

   - GNOME のセッションでは XWayland の画面を開けるので、`VBoxClient --clipboard` は X11 のクリップボードの経路を選ぶ（`Detected via connection: VBGHDISPLAYSERVERTYPE_XWAYLAND`）
   - その経路で `dlopen('libXt.so.6')` が `cannot open shared object file` で失敗し、`Trace/breakpoint trap`（SIGTRAP）で落ちる。Atomic Desktop のイメージに `libXt` が無いため
   - 親のプロセスが作り直すので、ログインした直後から 5 秒ごとに落ち続けた（`coredumpctl` に 54 個）。クリップボードの共有は動かず、画面には何も出ない
   - `libXt` を入れたイメージでは落ちなくなり、ホストとの間のコピー・貼り付けが両方向で通った。入るのは `libXt` の 1 つだけ（179 k）
   - `libXt` は、道具より先に別の `dnf install` で入れている。明示して入れたパッケージなので、最後の `dnf remove` の巻き添えにならない

   **ビルドの道具は消す**:

   - `gcc`・`make`・`kernel-devel`（kernel-rt なら `kernel-rt-devel`）と、一緒に入った 12 パッケージ（`kernel-headers`・`glibc-devel` など）が、`dnf remove` で全部消える
     - `libXt` の行を足す前の Containerfile で、ベースのイメージとパッケージの一覧が同じになることを確かめた（検証コンテナ）
     - 今の Containerfile では、`libXt` の 1 つが増える（kernel と kernel-rt のイメージの両方で確かめた）
   - `dnf history undo` にしなかったのは、道具を入れるときにベースのパッケージが上がっていた場合に、それを下げてしまうため
   - 道具が無いので、VM の上ではモジュールを作り直せない。カーネルが変わったら、イメージごとビルドし直す（[更新](#更新)）

   **そのまま残るもの**:

   - `/opt/VBoxGuestAdditions-7.2.20`（15 MB）。bootc のイメージでは `/opt` もイメージの一部で、読み取り専用
   - `/usr/bin` と `/usr/sbin` のリンク（`VBoxClient`・`VBoxControl`・`VBoxService`・`mount.vboxsf`・`rcvboxadd` など）、setuid の `VBoxDRMClient`
   - `/etc` のファイル: udev のルール（`60-vboxadd.rules`）、GNOME にログインしたときに `VBoxClient` を起動する `/etc/xdg/autostart/vboxclient.desktop`、`depmod.d`、`/etc/kernel/postinst.d/vboxadd`
   - SELinux: インストーラの `semanage fcontext` が、`mount.vboxsf` に `mount_exec_t` を割り当てる設定をイメージの `/etc/selinux` に書く
   - `vboxvideo.ko` もビルドされる（VirtualBox の画面を VMSVGA 以外にした場合のドライバ）
   - アンインストーラ（`/usr/sbin/vbox-uninstall-guest-additions`）も入るが、`/usr`・`/opt` に書けないので使えない。戻すときは[ロールバック](#ロールバック)

   **CD を入れたときの GNOME**（VM での実測）:

   - 自動実行の確認は出ない。EL10 の `gsettings-desktop-schemas`（47.1-4.el10）は `org.gnome.desktop.media-handling` の `autorun-never` の既定が `true`
   - デスクトップにアイコンも出ない（有効な拡張は `background-logo@fedorahosted.org` だけで、デスクトップのアイコンの拡張が無い）
   - CD を入れてから 10 秒ほど後に確かめると、`/run/media/<USER>/VBox_GAs_7.2.20` にマウントされていた（手順 7 の補足）

   </details>

1. VM のウィンドウのメニューで、Guest Additions の CD を入れる。

   - 「デバイス」→「Guest Additions CD イメージを挿入」を選ぶ（英語の表示では Devices → Insert Guest Additions CD image...）
   - VirtualBox のホスト側の操作。ホストの VirtualBox に同梱の ISO が、VM の光学ドライブに入る
   - CD は自動でマウントされるが、GNOME の画面には何も出ない（自動実行の確認も、デスクトップのアイコンも出ない。手順 5 の補足）
   - **次の手順は、CD を入れて 10 秒ほどたってから貼る**

1. CD からインストーラをコピーし、壊れていないかと版を確かめる。

   ```bash
   install -m 0644 /run/media/"${USER}"/VBox_GAs_*/VBoxLinuxAdditions.run ~/vbox-ga-image/
   sh ~/vbox-ga-image/VBoxLinuxAdditions.run --check
   sh ~/vbox-ga-image/VBoxLinuxAdditions.run --info | head -1
   ```

   - `MD5 checksums are OK. All good.` が出れば壊れていない（前の `does not contain an embedded SHA256 checksum.` は出てよい）
   - `Identification: VirtualBox 7.2.20 Guest Additions for Linux` の版が、ホストの VirtualBox（「ヘルプ」→「VirtualBox について」。英語の表示では Help → About VirtualBox...）と同じならよい
   - **7.2.8 より古いなら、先にホストの VirtualBox を上げる**（EL10.1・10.2 のカーネルへの対応が 7.2.8 で入った）
   - `install: cannot stat` なら、CD がマウントされていない。`udisksctl mount -b /dev/sr0` でマウントしてから貼り直す

   <details>
   <summary>補足: CD の中身と確かめ方</summary>

   - ホストが VM に入れる ISO は、Oracle の rpm に同梱の `/usr/share/virtualbox/VBoxGuestAdditions.iso`（[virtualbox.md の注意点](virtualbox.md#注意点)）
   - ISO のボリューム名（Joliet）は `VBox_GAs_7.2.20`
   - VM では、GNOME がこれを `/run/media/<USER>/VBox_GAs_7.2.20` にマウントした（`iso9660`・`ro`・`uid=<UID>`・`dmode=500`・`fmode=400`）
   - ISO には Rock Ridge が無く、中のファイルは読み取り専用になる
   - `install -m 0644` にしてあるのは、`cp` だと写しも読み取り専用のままで、[更新](#更新)で上書きできないため
     - 検証で再現した自動マウント（所有者だけが読める 0400。VM の自動マウントと同じ）では、2 回目の `cp` が `Permission denied` で失敗し、`install -m 0644` は何度でも通った
   - `VBoxLinuxAdditions.run` は makeself 2.7.1 の自己展開アーカイブで、`--check` は中の MD5 を確かめる
   - ホームの場所: ISO のインストーラで作ったユーザーは `/home/<USER>`（`/home` は `var/home` へのリンク）。イメージの `/etc/default/useradd` は `HOME=/var/home` なので、`useradd` で足したユーザーは `/var/home/<USER>` になる（検証コンテナ）
   - 版の対応: VirtualBox 7.2 の変更履歴では、7.2.8 で「RHEL 10.1・10.2 のカーネルへの追加の対応」、7.2.18 で「RHEL 10.3 のカーネルへの対応」が入っている。検証では 7.2.20 と 7.2.18 が、どちらも EL10.2 のカーネル向けにビルドできた

   VM での出力:

   ```
   Verifying archive integrity... /home/<USER>/vbox-ga-image/VBoxLinuxAdditions.run does not contain an embedded SHA256 checksum.
        0%    65%  100%   MD5 checksums are OK. All good.
   Identification: VirtualBox 7.2.20 Guest Additions for Linux
   ```

   </details>

1. 派生イメージをビルドする。

   ```bash
   build_args=(--pull=newer)
   if mokutil --sb-state 2>/dev/null | grep -q 'SecureBoot enabled'; then
     build_args+=(--build-arg MOK_SIGN=1 --secret id=mok_priv,src=/var/lib/shim-signed/mok/MOK.priv --secret id=mok_der,src=/var/lib/shim-signed/mok/MOK.der)
   fi
   sudo podman build "${build_args[@]}" --build-arg "BASE_IMAGE=${BASE_IMAGE:?手順 1 の BASE_IMAGE が空のまま。値を入れて貼り直す}" -t localhost/vbox-ga:latest ~/vbox-ga-image
   ```

   - 初回はベースのイメージ（圧縮で約 2.2 GB）を取り込む。Atomic Desktop の `/etc/containers/policy.json` に従って、イメージの署名が確かめられる
     - 自作の kernel-rt のイメージなど、`policy.json` に載っていないレジストリのイメージは、既定（`insecureAcceptAnything`）のとおり署名を確かめずに取り込む
   - 途中の `+` で始まる行は、Containerfile の中で実行したコマンド（手順 5 の補足）
   - 途中の `unable to load vboxguest kernel module` と `installer exit=1` は、ビルドの中ではモジュールを読み込めないためで、失敗ではない
     - Guest Additions が動いている VM でビルドし直すと（[更新](#更新)）、代わりに `mknod: /dev/vboxguest: Operation not permitted` と `installer exit=2` になる。これも失敗ではない
       - カーネルも新しくなったとき（ベースの更新）は、`mknod` の行が出て `installer exit=1` になる
   - 最後に次が出ればよい
     - `vboxguest.ko:`・`vboxsf.ko:`・`vboxvideo.ko:` の 3 行（イメージのカーネルの版。Secure Boot なら `signer=VirtualBox Guest Additions module signing key`）
     - kernel-rt のイメージなら、版の末尾が `+rt` で、`SMP preempt_rt` になる
     - `enabled` が 2 行
     - `Checks passed: 13`（`Warnings:` の行が無い）と `Successfully tagged localhost/vbox-ga:latest`
   - `could not parse secrets: faccessat /var/lib/shim-signed/mok/MOK.priv: no such file or directory` ですぐに止まったら、Secure Boot なのに手順 4 が済んでいない
   - `No match for argument: kernel-devel-uname-r = …+rt` で止まったら、kernel-rt のイメージで `rt` のリポジトリが有効になっていない
   - **次の手順は、`sudo` のパスワードに答え、`Successfully tagged` が出てから貼る**

   <details>
   <summary>補足: ビルドの表示と所要時間</summary>

   検証コンテナでの出力（Secure Boot のとき。`set -x` を足した今の Containerfile）の抜粋:

   ```
   + kver=6.12.0-211.56.1.el10_2.x86_64
   ...
   + dnf -y install gcc make 'kernel-devel-uname-r = 6.12.0-211.56.1.el10_2.x86_64'
   ...
   installer exit=1
   + echo 'installer exit=1'
   + test -f /usr/lib/modules/6.12.0-211.56.1.el10_2.x86_64/misc/vboxguest.ko
   + test -f /usr/lib/modules/6.12.0-211.56.1.el10_2.x86_64/misc/vboxsf.ko
   ...
   + systemctl enable vboxadd.service vboxadd-service.service
   Created symlink '/etc/systemd/system/multi-user.target.wants/vboxadd.service' → '/usr/lib/systemd/system/vboxadd.service'.
   Created symlink '/etc/systemd/system/multi-user.target.wants/vboxadd-service.service' → '/usr/lib/systemd/system/vboxadd-service.service'.
   ...
   + set +x
   vboxguest.ko: 6.12.0-211.56.1.el10_2.x86_64 SMP preempt mod_unload modversions signer=VirtualBox Guest Additions module signing key
   vboxsf.ko: 6.12.0-211.56.1.el10_2.x86_64 SMP preempt mod_unload modversions signer=VirtualBox Guest Additions module signing key
   vboxvideo.ko: 6.12.0-211.56.1.el10_2.x86_64 SMP preempt mod_unload modversions signer=VirtualBox Guest Additions module signing key
   enabled
   enabled
   ...
   Checks passed: 13
   Checks skipped: 1
   ...
   Successfully tagged localhost/vbox-ga:latest
   ```

   - **kernel-rt のイメージ**（検証用のイメージ。[付録](#付録-コマンドの表示と-kernel-rt-のコンテナでの確認2026-09-29)）: `+ kver=6.12.0-211.56.1.el10_2.x86_64+rt` になり、dnf は `kernel-rt-devel` を `rt` のリポジトリから入れた
     - 最後の 3 行は `vboxguest.ko: 6.12.0-211.56.1.el10_2.x86_64+rt SMP preempt_rt mod_unload modversions signer=VirtualBox Guest Additions module signing key` の形で、`Checks passed: 13` も同じだった
     - VM でも同じ形だった（[VM の付録](#付録-kernel-rt-のイメージの-vm-での本実行2026-09-29)）。`kernel-rt-devel` は、イメージのカーネルと同じ版が入った（`rt` の最新でない 211.55.1 でも）
     - VM では、HTTP のローカルのレジストリからベースを取り込んで、333 秒だった。取り込みに `Storing signatures` は出なかった（`policy.json` に載っていないため）
   - **所要時間**: 代役のコンテナでは、ベースの取り込みからビルドの終わりまで 2 分 22 秒だった。ベースを取り込んだ後のビルドだけなら約 40 秒（道具の導入 19 秒、インストーラ 12 秒）
     - VM（4 vCPU・8 GB）では、ベースの取り込みを含めて 305 秒だった。Containerfile を変えた後のビルドし直しは 161 秒、何も変えないビルドし直しは 5 秒
     - VM では、ベースの取り込みの `Getting image source signatures` の後に `Storing signatures` が出た（`policy.json` の署名の検査）
   - **署名**: 検証では、署名したモジュールから署名を取り出し、手順 4 と同じ作り方の証明書で `openssl dgst -sha512 -verify` を通して `Verified OK` になった（Guest Additions の起動スクリプトが署名を確かめるのと同じ方法）
   - **Secure Boot が無効なとき**は `MOK_SIGN=1` も `--secret` も渡らない。Containerfile の secret のマウントは、渡されなければ何もしない（`signer=` が空のまま成功することを確かめた）
     - Secure Boot が無効の VM（kernel-rt）でも、`signer=` が空のまま成功した
     - 切り替えた後は、`module verification failed: signature and/or required key missing - tainting kernel` を出して読み込まれた
   - **動いているカーネルとイメージのカーネルが違うとき**（まだ古いデプロイメントで動いている VM など）も、モジュールはイメージのカーネル向けにできる
     - 検証では、カーネルが `6.12.0-211.53.1.el10_2` の古いタグ（`10.2.20260916.0`）を、`6.12.0-211.56.1.el10_2` のカーネルの上でビルドした
     - `depmod: ERROR: could not open directory /lib/modules/<動いているカーネル>` と `depmod: FATAL` が 2 回ずつ出て、モジュールのビルドも 2 回走るが、最後の 3 行はイメージのカーネルの版になった
     - VM でも同じことが起きた。ISO で入れた直後の VM は `6.12.0-211.55.1.el10_2`（10.2.20260918.1）で動いており、`:latest`（10.2.20260926.0）の `6.12.0-211.56.1.el10_2` 向けのモジュールができた。切り替えた後はそのカーネルで起動し、モジュールが読み込まれた
   - **キャッシュ**（どれも実測）:
     - 何も変えずにビルドし直すと、全部の段がキャッシュから使われ（`Using cache` が 4 行）、同じイメージ ID になる
     - `MOK_SIGN` が変わったとき、`VBoxLinuxAdditions.run` が変わったとき（7.2.18 に差し替えた）は、Guest Additions の段をやり直す
     - **鍵を作り直しただけでは、キャッシュが使われて古い鍵の署名のまま**になった（`modinfo -F sig_key` が変わらない）。`--no-cache` を足すと新しい鍵で署名された
   - `--pull=newer` は、レジストリのベースが新しいときだけ取り込み直す（何も変わっていなければ取り込まない）

   </details>

1. 作ったイメージに切り替えて、再起動する。

   ```bash
   sudo bootc switch --apply --transport containers-storage localhost/vbox-ga:latest
   ```

   - イメージを取り込んだあと、そのまま再起動する（`--apply`）
   - Secure Boot なら、起動の途中で青い **MokManager** の画面が出る（手順 10）
   - **Secure Boot が無効なら、手順 10 は飛ばし、起動したらログインして新しい端末を開いてから手順 11 を貼る**

   <details>
   <summary>補足: 切り替えで起きること</summary>

   - `/usr` と `/opt` は、新しいイメージのものになる
   - `/etc` は、手元の変更を残しつつ新しいイメージとマージされる（ostree の 3-way マージ）。イメージで足したファイル（udev のルール、`vboxclient.desktop`、unit を有効にするリンク）は、手元に無いので足される
   - 手元で変更済みの `/etc/passwd`・`/etc/group` は手元のものが残るので、Guest Additions のユーザーとグループは入らない。最初の起動で `systemd-sysusers` が作る
   - `/var` はそのまま残る。`/var/lib/VBoxGuestAdditions` のリンクは、起動のたびに `systemd-tmpfiles` が張る
   - 起動時の `vboxadd.service` は、イメージのカーネル向けのモジュールがそろっているので作り直さず、読み込むだけにする

   **切り替えた後の最初の起動をコンテナで模した結果**（systemd を PID 1 にし、ベースのイメージの `/etc/passwd` などに戻し、`/var` を空にした）:

   - `systemd-sysusers` が `Creating group 'vboxsf' with GID <GID>.`・`vboxdrmipc`・`Creating user 'vboxadd' (n/a) with UID <UID> and GID 1.` を出した
   - `/var/lib/VBoxGuestAdditions -> /usr/share/factory/var/lib/VBoxGuestAdditions` のリンクができた
   - `vboxadd.service` と `vboxadd-service.service` は `enabled` で、起動時に動いた。モジュールの作り直し（`Setting up modules`）には入らず、コンテナではモジュールを読み込めないので `unable to load vboxguest kernel module` で `failed` になった
   - コンテナでは、`bootc switch` が `Detected container; this command requires a booted host system.` で止まる

   **VM での結果**:

   - `bootc switch` は `layers already present: 65; layers needed: 20 (1.7 GB)` から取り込みを始め、`Deploying: done (8 seconds)` と `Queued for next boot: ostree-unverified-image:containers-storage:localhost/vbox-ga:latest` を出して再起動した（端末の SSH は切れた）
   - MokManager の画面の並び:
     - 「Shim UEFI key management」の画面に `Press any key to perform MOK management` と `Booting in 10 seconds`
     - キーを押すと「Perform MOK management」のメニュー（`Continue boot` / `Enroll MOK` / `Enroll key from disk` / `Enroll hash from disk`）
     - `Enroll MOK` → 「[Enroll MOK]」（`View key 0` / `Continue`）→ `Continue` → 「Enroll the key(s)?」（`No` / `Yes`）→ `Yes` → `Password:` → メニューの先頭が `Reboot` になる
   - 切り替えた後の最初の起動では、コンテナで模したときと同じく、`systemd-sysusers` がユーザーとグループを作り、`/var/lib/VBoxGuestAdditions` のリンクが張られた
     - `vboxadd` は `VirtualBox Guest Additions: Starting.` から作り直しに入らずに終わり、`vboxadd-service` が `Starting VirtualBox Guest Addition service.` を出した

   </details>

1. Secure Boot が有効なときだけ、起動の途中の MokManager で鍵を登録する。

   - 最初の画面の `Press any key to perform MOK management` は、`Booting in 10 seconds` から数え下げて 10 秒で消える。消える前に何かキーを押す
   - 続けて `Enroll MOK` → `Continue` → `Yes` → 手順 4 の一時パスワード → `Reboot` と進む
   - **MokManager で何もしないで進むと、鍵は登録されず、モジュールが読み込まれない**。そのときは手順 4 の最後の `sudo mokutil --import ...` を貼り直してから再起動する
   - 画面の並びは、手順 9 の補足
   - **次の手順は、起動したらログインし、新しい端末を開いてから貼る**

1. Guest Additions が動いているか確かめる。

   ```bash
   lsmod | grep -E '^vbox'
   systemctl is-active vboxadd vboxadd-service
   pgrep -a VBoxClient
   sudo bootc status
   ```

   - `vboxguest` の行と、`active` が 2 行出ればよい（`vboxsf` は、共有フォルダーを足すまで読み込まれない）
   - `pgrep` に `/usr/bin/VBoxClient --clipboard`・`--vmsvga-session` などが並べばよい（GNOME にログインしたときに自動で起動する）
   - `● Booted image: containers-storage:localhost/vbox-ga:latest` ならよい

   <details>
   <summary>補足: 動かないときと、kernel-rt で出る警告</summary>

   | 出るもの | 意味 | 対処 |
   |---|---|---|
   | `lsmod` に何も出ず、`systemctl is-active vboxadd` が `failed` | モジュールを読み込めていない | `journalctl -b -u vboxadd` と `sudo dmesg \| grep -i vbox` を見る。Secure Boot なら手順 13 |
   | `Loading of module with unavailable key is rejected`（`sudo dmesg`） | Secure Boot で、署名の鍵が登録されていない | 手順 13 で鍵が登録されているか見る。登録できていなければ手順 10 の箇条書き |
   | `Configuration file /var/lib/VBoxGuestAdditions/config not found`（`journalctl -b -u vboxadd`） | 起動時のリンクが張られていない | `sudo systemd-tmpfiles --create --prefix=/var/lib/VBoxGuestAdditions` の後に `sudo systemctl restart vboxadd vboxadd-service` |
   | `vboxclient.desktop[...]: GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name is not activatable`（`journalctl --user -b`） | ログインした時点で `/dev/vboxguest` が無かった。`VBoxClient-all` が出そうとした通知も、出せずに終わった | モジュールを直してから、ログインし直す |
   | `coredumpctl list` に `/usr/bin/VBoxClient` が 5 秒ごとに並ぶ（`SIGTRAP`） | `libXt` の無いイメージで、`VBoxClient --clipboard` が落ち続けている（手順 5 の補足） | 手順 5 の Containerfile（`libXt` の行がある版）を置き直し、[更新](#更新)の手順 2・3 を行う |

   - 表の 2 行目と 4 行目は、VM で MokManager をわざと見送ったときに出たもの
     - `vboxadd` のログは `unable to load vboxguest kernel module, see dmesg` で、2 つの unit は `failed` になった
     - `VBoxClient-all` は `notify-send "VBoxClient: the VirtualBox kernel service is not running.  Exiting."` を実行するが、GNOME の通知には出ず、ユーザーのジャーナルに 4 行目の文が残った
   - `VBoxClient-all`（`/usr/bin/VBoxClient-all`）が起動するのは、`--clipboard`・`--seamless`・`--draganddrop`・`--checkhostversion`・`--vmsvga-session` の 5 つ。同梱のスクリプトのコメントによれば、Wayland では `--seamless` と `--draganddrop` は何もしない（GNOME は Wayland のセッション）
     - VM で動き続けていたのは、`--clipboard`（親と子の 2 つ）と `--vmsvga-session`（2 つ）だけだった
   - EL10 には Xorg サーバが無いので、インストーラは X.Org のドライバを入れない（`Could not find the X.Org or XFree86 Window System, skipping.`）。画面の大きさの追従は、カーネルの `vmwgfx`（VMSVGA）と `VBoxClient --vmsvga-session` が受け持つ
   - VM で確かめたこと（ホスト側の操作は、同じ働きの `VBoxManage controlvm` で行った）:
     - 画面の大きさ: `setvideomodehint 1600 900 32` を送ると、Guest Additions を入れる前は 1280x800 のままで、入れた後は 1600x900 に変わった
     - クリップボード（`clipboard mode bidirectional`）: ホストで `wl-copy` した文字列を VM の端末に貼れ、VM の端末でコピーした文字列をホストの `wl-paste` で読めた
     - 時刻の同期: 切り替えた後の最初の起動で、VBoxService が `timesync vgsvcTimeSyncWorker: Radical guest time change` を出して、4 時間ずれていた時計を直した
   - メニューの名前は、VirtualBox 7.2.20 の翻訳ファイル（`/usr/share/virtualbox/nls/VirtualBox_ja.qm`）と、GUI のライブラリ（`UICommon.so`）の英語の文字列で確かめた

   **kernel-rt で出る警告**（VM での実測。[付録](#付録-kernel-rt-のイメージの-vm-での本実行2026-09-29)）:

   - kernel-rt の VM では、起動のたびに `vboxguest` を読み込んだ直後に、`sudo dmesg` に次の行と呼び出し履歴が 1 回出た
     - `WARNING: CPU: <CPU> PID: <PID> at kernel/rcu/tree_plugin.h:826 rcu_sched_clock_irq+0x330/0x340`（`Comm: (udev-worker)`）
     - Secure Boot の有効と無効、`211.55.1` と `211.56.1` の kernel-rt のどちらでも、4 回の起動すべてで出た。Guest Additions を入れる前の起動では出ない
   - レジスタの値（`RAX: 00000000ffffffff`）から、モジュールを読み込んだタスクの RCU の読み取り側の入れ子が -1 になっている（`rcu_read_unlock` が 1 回多い）と読める。原因は調べていない
   - 警告の後も、RCU の stall や `BUG:` は出ず、Guest Additions の働き（上の確認、クリップボード・画面の大きさ・共有フォルダー・時刻の同期）にも影響は見えなかった
     - `/proc/sys/kernel/tainted` に `W`（警告）が加わる（Secure Boot が有効なら 4608）
   - 既定のカーネル（PREEMPT_RT でないもの）でこの警告が出るかは、確かめていない

   </details>

1. VM のウィンドウで、クリップボードの共有と画面の大きさの追従を試す。

   - メニューの「デバイス」→「クリップボードの共有」→「双方向」にし、ホストとの間でコピー・貼り付けを試す（英語の表示では Devices → Shared Clipboard → Bidirectional）
   - ウィンドウの大きさを変えると、画面の解像度が追従する
     - VM の設定のグラフィックコントローラが VMSVGA で、メニューの「表示」→「ゲストOSの画面を自動リサイズ」が有効な場合（英語の表示では View → Auto-resize Guest Display）
   - **次の手順は、手順 11 の `sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. Secure Boot が有効なときだけ、鍵が登録されたかとモジュールの署名を見る。

   ```bash
   {
     sudo mokutil --test-key /var/lib/shim-signed/mok/MOK.der
     modinfo -F signer vboxguest
   }
   ```

   - `/var/lib/shim-signed/mok/MOK.der is already enrolled` と `VirtualBox Guest Additions module signing key` が出ればよい
   - `is not enrolled` なら、手順 10 の MokManager で登録できていない（手順 10 の箇条書き）

---

## 共有フォルダーを使う（任意）

- 共有フォルダーを足すと、VM の中で `vboxsf` のモジュールが読み込まれ、フォルダーが `/media/sf_<名前>` に自動でマウントされる
  - `findmnt` の表示は `/run/media/sf_<名前>`（Atomic Desktop では `/media` が `run/media` へのリンク）
- 読み書きできるのは `vboxsf` グループのユーザーだけ（入る前は `Permission denied` になった）

1. ホストの VirtualBox で、VM の設定の「共有フォルダー」にフォルダーを足す。

   - 「自動マウント」にチェックを入れる（英語の表示では Shared Folders と Auto-mount）
   - VM を動かしたままでも足せる
   - 検証では、動いている VM に `VBoxManage sharedfolder add --automount --transient` で足した。`--transient` が無いと、`VBoxManage` は `is already locked for a session` で断った

1. 自分を `vboxsf` グループに入れる。

   ```bash
   sudo usermod -aG vboxsf "${USER}"
   ```

   - `vboxsf` グループは、切り替えた後の最初の起動で `systemd-sysusers` が作っている
   - **効くのはログインし直してから**（この節の手順 3）

1. GNOME からログアウトして、ログインし直す。

   - **次の手順は、新しい端末を開いてから貼る**

1. グループと共有フォルダーを確かめる。

   ```bash
   id -nG | tr ' ' '\n' | grep -x vboxsf
   findmnt -t vboxsf
   ```

   - `vboxsf` の行と、共有フォルダーのマウントの行（`/run/media/sf_<名前>` の `vboxsf`）が出ればよい

---

## 更新

> [!WARNING]
> **切り替えた後は、`sudo bootc upgrade` だけでは OS（ベースのイメージ）が上がらない**。bootc が見に行くのは、この VM の中の `localhost/vbox-ga:latest` だけになる。OS を上げるときも、この節の手順 2・3 でビルドし直す。

- OS（ベースのイメージ）を上げる: この節の手順 2・3。カーネルが変わっても、同じ手順でモジュールが作り直される
  - 自作の kernel-rt のイメージは、先にレジストリのイメージを新しくしておく（この節の手順 2 は、レジストリにあるものを取り込む）
- ホストの VirtualBox を上げた（Guest Additions の版が変わった）: この節の手順 1 から
- Secure Boot の鍵を作り直したときは、この節の手順 2 で `sudo podman build` に `--no-cache` を足す（ビルドのキャッシュは、渡した鍵の中身の違いを見分けない）
- 古いイメージは `sudo podman image prune` で消せる（`[y/N]` を聞く）

1. ホストの VirtualBox を上げたときだけ、CD を入れ直して [手順 7](#実施手順) を貼る。

   - VM のウィンドウのメニューの「デバイス」→「Guest Additions CD イメージを挿入」（英語の表示では Devices → Insert Guest Additions CD image...）で、新しい版の CD を入れる
   - [手順 7](#実施手順) の `Identification:` が、ホストの新しい版になっていればよい

1. 手順 1 の変数を設定したシェルで、[手順 8](#実施手順) を貼り直す。

   - `--pull=newer` なので、ベースが新しくなっていれば取り込み直す
   - 何も変わっていなければ、ビルドのキャッシュが使われて同じイメージになる（`Using cache` が 4 行並び、最後のイメージ ID が同じ）
   - Containerfile を置き直したとき（[手順 5](#実施手順)）は、Guest Additions の段をやり直す
   - **次の手順は、`Successfully tagged` が出てから貼る**

1. 新しいイメージを取り込んで、再起動する。

   ```bash
   sudo bootc upgrade --apply
   ```

   - イメージが変わっていれば、`Queued for next boot:` と入れ替わった層の数を出してから再起動する
   - 変わっていなければ、`No changes in ...` と `No update available.` を出して、再起動しない
   - 起動したら、[手順 11・12](#実施手順) で確かめる

---

## ロールバック

- `sudo bootc rollback` の後に再起動すると、1 つ前のデプロイメントに戻る
  - 更新を重ねた後は、1 つ前の派生イメージに戻るだけだった（VM で確認）
  - 切り替えた直後なら、元のイメージに戻った（kernel-rt のイメージの VM で確認。もう一度 `sudo bootc rollback` すると、派生イメージに戻った）
- この節の手順では消えないもの:
  - **Secure Boot の MOK**（手順 4 を行った場合）: 次の順で消す（VM で確認）
    - `sudo mokutil --delete /var/lib/shim-signed/mok/MOK.der`（一時パスワードを 2 回）→ 再起動
    - MokManager の最初の画面で 10 秒以内にキーを押し、`Delete MOK` → `Continue` → `Yes` → パスワード → `Reboot`
    - 起動したら `sudo mokutil --test-key /var/lib/shim-signed/mok/MOK.der` が `is not enrolled` になる。そのあと `sudo rm -rf /var/lib/shim-signed`

1. 元のイメージに切り替えて、再起動する。

   ```bash
   sudo bootc switch --apply "${BASE_IMAGE:?手順 1 の BASE_IMAGE が空のまま。値を入れて貼り直す}"
   ```

   - 元のイメージをレジストリから取り込み、署名を確かめてから再起動する
     - 自作の kernel-rt のイメージなど、`policy.json` に載っていないレジストリのイメージは、署名を確かめない（手順 8 と同じ）
   - **次の手順は、起動したらログインし、新しい端末で手順 1 を貼ってから貼る**

   <details>
   <summary>補足: <code>--enforce-container-sigpolicy</code> を付けない理由</summary>

   - Atomic Desktop の ISO は、インストールの最後に `--enforce-container-sigpolicy` 付きの `bootc switch --mutate-in-place` でこのイメージを追うように設定する（AlmaLinux の atomic-ci の ISO のビルド）
   - しかし、ここで同じオプションを付けると、取り込む前に次のエラーで止まった（VM で実測）
     - ``containers-policy.json specifies a default of `insecureAcceptAnything`; refusing usage``
     - イメージの `/etc/containers/policy.json` の既定（`default`）が `insecureAcceptAnything` のため。bootc はこのオプションのとき、既定が何でも受け入れる設定を拒む
   - 付けなくても、署名は `policy.json` のとおりに確かめられる
     - `policy.json` は `quay.io/almalinuxorg/atomic-desktop-gnome` に sigstore の署名（`/etc/pki/containers/atomic-desktop-gnome.pub`）を求めている（イメージで確認）
     - VM で、この鍵を別の鍵に差し替えてから同じ `bootc switch` を実行すると、`cryptographic signature verification failed: invalid signature when validating ASN.1 encoded signature` で断られた（確かめた後に元に戻した）

   </details>

1. ビルド用のディレクトリと、podman に取り込んだイメージを消す。

   ```bash
   rm -rf ~/vbox-ga-image
   sudo podman rmi localhost/vbox-ga:latest "${BASE_IMAGE:?手順 1 の BASE_IMAGE が空のまま。値を入れて貼り直す}"
   ```

   - `Untagged:` と `Deleted:` の行が並ぶ
   - bootc は自分の置き場所にイメージを持っているので、podman のイメージを消しても起動には影響しない
   - ビルドの最初の段（`<none>`、6.43 MB）が残る。`sudo podman image prune` で消せる
     - [更新](#更新)でビルドし直していれば、前の派生イメージ（5.07 GB。kernel-rt のイメージでは 5.51 GB）も `<none>` で残る。同じく `sudo podman image prune` で消える
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. Guest Additions のユーザー・グループ・リンク・ログを消す。

   ```bash
   {
     sudo userdel vboxadd
     sudo groupdel vboxsf
     sudo groupdel vboxdrmipc
     sudo rm -f /var/lib/VBoxGuestAdditions /var/log/vboxadd-setup.log*
   }
   ```

   - 何も出ずに終われば消えている

   <details>
   <summary>補足: これらが自然には消えない理由</summary>

   - ユーザーとグループは、`systemd-sysusers` が手元の `/etc/passwd`・`/etc/group` に書いたもの。元のイメージに戻しても、手元で変更済みのファイルは 3-way マージで残る
   - `/var` は、イメージを切り替えても戻らない
   - 一方、イメージが足した `/etc` のファイルは、手元で変えていなければ、元のイメージに戻したときに消える（ostree の `/etc` のマージの仕組み）
     - VM では、この節の手順 1 の後に、udev のルール、`vboxclient.desktop`、unit を有効にするリンク、`/etc/kernel/postinst.d/vboxadd`、`depmod.d` のファイル、SELinux の `file_contexts.local` の `mount.vboxsf` の行が消えていた
     - 残っていたのは、ユーザーとグループ、`/var/lib/VBoxGuestAdditions` のリンク、`/var/log/vboxadd-setup.log` と `.1`〜`.4`

   </details>

---

## 補足

### 対象と検証環境

- **目的**: VirtualBox の VM で動く AlmaLinux Atomic Desktop（GNOME。AlmaLinux 10.2 の bootc のイメージ）に Guest Additions を入れる
  - 使えるようにするもの: クリップボードの共有、画面サイズの自動変更、共有フォルダー、時刻の同期（VBoxService）
- **進め方**: dnf では入れられないので、Guest Additions を焼き込んだ派生イメージを VM の上でビルドし、`bootc switch` で切り替える
  - bootc の公式文書の「Booting local builds」と同じ形
  - 読者が変える値は無い（`BASE_IMAGE` は、GNOME 以外の Atomic Desktop と、自作の kernel-rt のイメージのときだけ変える）
- **状態**: **VirtualBox の VM で本実行済み（2026-09-29）**。その前に x86_64 のコンテナで検証した（2026-09-28）
  - 下表の VM で、**この文書のコードブロックを上から順にそのまま貼った**（[VM の付録](#付録-virtualbox-の-vm-での本実行2026-09-29)）
    - 手順 1〜13、[共有フォルダーを使う（任意）](#共有フォルダーを使う任意)、[更新](#更新)の手順 2・3、[ロールバック](#ロールバック)の手順 1〜3
    - VM はホストの x86_64 の実機の VirtualBox 7.2.20 で動かし、公式の ISO で入れた。VM の Secure Boot は有効
    - ホスト側のメニューの操作（CD の挿入・クリップボードの共有・共有フォルダーの追加・画面の大きさ）は、同じ働きの `VBoxManage` で行った
  - VM で見つかって直したこと:
    - `BASE_IMAGE` の既定を `:10` から `:latest` にした（ISO は `:latest` を追う。手順 1）
    - Containerfile に `libXt` を足した（無いと `VBoxClient --clipboard` が落ち続け、クリップボードの共有が動かない。手順 5）
    - [ロールバック](#ロールバック)の手順 1 から `--enforce-container-sigpolicy` を外した（Atomic Desktop の `policy.json` では取り込みを断られる）
    - 手順 6 の CD の合図（GNOME は何も表示しない）、手順 10 の MokManager の最初の画面（10 秒）、手順 11 の `vboxsf` と失敗したときの表、メニューの名前（日本語の表示の 2 か所と、英語の表示）
  - 確認したこと:
    - `bootc switch`、`bootc upgrade`（イメージが変わったときと、変わらないときの両方）、`bootc rollback`
    - MokManager での鍵の登録と削除。登録を見送ったときの失敗のしかた
    - モジュールの読み込み、VBoxService（時刻の同期）、VBoxClient（クリップボードの両方向・画面の大きさ）、共有フォルダーの自動マウントと読み書き
    - SELinux（`mount.vboxsf` が `mount_exec_t`、AVC の拒否が 0）、署名の検査（`policy.json` の鍵を差し替えると断られる）
    - 元のイメージに戻すと、イメージが足した `/etc` のファイルが消えること
  - **確認していないこと**:
    - VirtualBox の GUI のメニューそのものでの操作（名前は翻訳ファイルと文字列で確かめた）
    - [更新](#更新)の手順 1（ホストの VirtualBox の新しい版が無い）、KDE・COSMIC の Atomic Desktop
    - 直した Containerfile（`set -x` と kernel-rt の対応）を、既定のカーネルのイメージの VM で流すこと
    - 既定のカーネルのイメージでの、Secure Boot が無効の VM と、切り替えた直後の `bootc rollback`（どちらも kernel-rt のイメージでは確かめた）
    - 認証の要るレジストリにある、自作のイメージ
  - コンテナでの検証（2026-09-28。[付録](#付録-コンテナでの検証記録2026-09-28)）: Atomic Desktop のイメージそのものを VM の代役にし、中の podman にコードブロックを貼った
    - 確かめたのは、派生イメージのビルド（モジュールのビルドと署名、`bootc container lint`）と、切り替えた後の最初の起動を systemd を PID 1 にしたコンテナで模した結果
    - このとき実機の設定は変えていない（`sudo` を使わず、rootless の podman だけ）
  - 2026-09-28: 手順 4・13 と、[ロールバック](#ロールバック)の手順 3のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は、2026-09-29 に VM で流した（ブラケットペーストの効く端末で）
  - 2026-09-29（VM の本実行の後）: 手順 5 の Containerfile を直した（[付録](#付録-コマンドの表示と-kernel-rt-のコンテナでの確認2026-09-29)）
    - `set -x` で RUN の中のコマンドを表示し、最後の結果の行の前で `set +x` にした
    - kernel-rt のイメージのため、カーネルの版を `/usr/lib/modules` から取り、道具を `kernel-devel-uname-r` の指定で入れるようにした。dnf の `--repo` は外し、イメージで有効なリポジトリを使う
    - 直した版は、x86_64 のコンテナ（クラウドホスト上の Docker）で手順 1・3〜5・7・8 を流して確かめた（手順 6 の CD は、読み取り専用のマウントで代えた）。ベースは公式のイメージと、kernel を kernel-rt に入れ替えた検証用のイメージ（ローカルのレジストリに置いた）の 2 つ
    - 既定のカーネルのイメージでは、直した版を VM で流していない。kernel-rt のイメージでは、同じ日に VM で流した（次の項目）
  - 2026-09-29（夜）: 直した版を、同じ実機の VirtualBox の VM で流した（[付録](#付録-kernel-rt-のイメージの-vm-での本実行2026-09-29)）
    - VM は公式の ISO で新しく入れ、検証用の kernel-rt のイメージ（ローカルのレジストリに置いた）に切り替えてから、この文書のブロックを貼った
    - Secure Boot が無効の VM で手順 1〜3・5〜9・11・12、有効の VM で手順 1〜13
    - 有効の VM で、[共有フォルダーを使う（任意）](#共有フォルダーを使う任意)の手順 1〜4、[更新](#更新)の手順 2・3（変わらないときと、ベースとカーネルが新しくなったとき）、[ロールバック](#ロールバック)の手順 1〜3
    - 確認したこと: kernel-rt での起動、`kernel-rt-devel` でのビルドと署名、MokManager での登録、モジュールの読み込み、VBoxClient・VBoxService
    - あわせて確認したこと: 共有フォルダーの読み書き、カーネルが変わる更新、切り替えた直後の `bootc rollback`
    - 見つかったこと: kernel-rt では、`vboxguest` の読み込みの直後にカーネルの `WARNING` が 1 回出る（[手順 11](#実施手順) の補足）
    - 直したこと: カーネルも新しくなる更新では `installer exit=1` になる（[手順 8](#実施手順) の箇条書き）。[ロールバック](#ロールバック)のリードの「切り替えた直後」の見込みを、確かめた結果にした

| 項目 | VirtualBox の VM（本実行） | 検証環境（コンテナ） |
|---|---|---|
| 実施日 | 2026-09-29 | 2026-09-28 |
| ホスト | AlmaLinux 10.2 / x86_64 のノート PC の VirtualBox 7.2.20（[virtualbox.md](virtualbox.md) で導入）。Guest Additions の CD はホストのもの | VirtualBox は無し。Guest Additions は公式サイトの `VBoxGuestAdditions_7.2.20.iso`（`SHA256SUMS` で照合） |
| ゲストの OS | 公式の ISO（`atomic-desktop-gnome-amd64.iso`、2026-09-21）で入れた Atomic Desktop GNOME（10.2.20260918.1）。派生イメージのベースは `:latest`（10.2.20260926.0） | 同じイメージ（10.2.20260924.1、`sha256:7be643fe…dcff`）を podman のコンテナとして起動した代役 |
| VM | 4 vCPU・8 GB・VMSVGA（128 MB）・SATA の 80 GB の VDI・NAT。UEFI とセキュアブート（`modifynvram` で Microsoft と Oracle の鍵を登録） | — |
| カーネル | ISO の `6.12.0-211.55.1.el10_2` → 派生イメージの `6.12.0-211.56.1.el10_2` | 実機（AlmaLinux 10.2 / x86_64 のノート PC）の `6.12.0-211.56.1.el10_2` を共有 |
| bootc / podman | 1.16.4 / 5.8.2（イメージ） | 同左（代役の中の podman で入れ子にビルド） |
| GNOME | 49.4（Wayland） | 無し |
| Secure Boot | 有効 | `mokutil` のスタブで両方の分岐を通した（本物はコンテナで `EFI variables are not supported on this system`） |
| SELinux | Enforcing | 実機は Enforcing。代役のコンテナは `--privileged` |

> [!NOTE]
> 出力例の値は `<USER>` / `<UID>` / `<GID>` / `<DIGEST>` などのプレースホルダで書いてある。版（Guest Additions の `7.2.20`、イメージの `10.2.20260926.0`、カーネルの `6.12.0-211.56.1.el10_2`）は実行日によって変わる。MOK の秘密鍵、一時パスワード、VM のユーザーのパスワードは載せない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

`quay.io/almalinuxorg/atomic-desktop-gnome:10`（10.2.20260924.1）の中身（検証コンテナで確認）:

| 項目 | 状態 |
|---|---|
| Guest Additions | 無し。`@guest-desktop-agents` で `spice-vdagent`・`open-vm-tools`・`qemu-guest-agent`・`hyperv-daemons` は入っている |
| カーネル | `kernel-core-6.12.0-211.56.1.el10_2`。`CONFIG_VBOXGUEST` と `CONFIG_DRM_VBOXVIDEO` は無効（`CONFIG_DRM_VMWGFX=m` はある） |
| ビルドの道具 | `gcc`・`make`・`kernel-devel` は無い。`bzip2`・`tar`・`perl-interpreter`・`mokutil`・`openssl`・`podman`・`policycoreutils-python-utils` はある |
| ディレクトリ | `/opt` は実ディレクトリ（イメージの一部）。`/media` → `run/media`、`/home` → `var/home`、`/usr/local` → `/var/usrlocal`。`/var` の中は `/var/tmp` だけ |
| リポジトリ | `baseos`・`appstream`・`crb`・`extras`・`epel` |
| 署名の検査 | `/etc/containers/policy.json` が `quay.io/almalinuxorg/atomic-desktop-gnome` に sigstore の署名を求める。`containers-storage` などは `insecureAcceptAnything` |
| 自動更新 | `bootc-fetch-apply-updates.timer` は無効。GNOME ソフトウェアに rpm-ostree / bootc のプラグインは無い |
| `bootc container lint` | `Checks passed: 13`、`Checks skipped: 1` |

VM に公式の ISO から入れた直後の状態（2026-09-29）:

| 項目 | 状態 |
|---|---|
| イメージ | `quay.io/almalinuxorg/atomic-desktop-gnome:latest`（10.2.20260918.1）。カーネルは `6.12.0-211.55.1.el10_2` |
| ユーザー | インストーラで作った管理者（`wheel`）。ホームは `/home/<USER>`。root は無効 |
| ネットワーク | インストーラでネットワークを有効にしなかったので、接続 `enp0s3` の自動接続が `no` だった（[VM の付録](#付録-virtualbox-の-vm-での本実行2026-09-29)の準備で直した） |
| 時刻 | `RTC in local TZ: yes`、NTP は無効。VM の RTC は UTC なので、タイムゾーンとの差だけずれていた（インストーラの既定の America/New_York のままで 4 時間） |
| sshd | `enabled` / `active` |
| GNOME | 49.4（Wayland）。`autorun-never` は `true`、有効な拡張は `background-logo@fedorahosted.org` だけ |
| `/var` | 47G。使用量は 5.7G |
| `/etc/containers/policy.json` | 既定（`default`）は `insecureAcceptAnything`。`quay.io/almalinuxorg/atomic-desktop-gnome` は `sigstoreSigned`（ほかに Red Hat のレジストリ 2 つも） |
| `libXt` | 無い |

### 選択した方針

AlmaLinux 10 の bootc の VM に Guest Additions を入れる経路を比べた（2026-09-28 時点）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **派生イメージに焼き込み、`bootc switch` する** | bootc の想定どおりの形。モジュールをイメージのカーネル向けにビルドし、署名もビルドの中でできる | **採用** |
| VM の上で `VBoxLinuxAdditions.run` を実行する | `/usr`・`/opt` が読み取り専用で入らない | 不可 |
| `bootc usr-overlay` の上で実行する | 一時的な書き込み層なので、再起動で消える | 不採用 |
| dnf / rpm-ostree で RPM を入れる | EL10 には Guest Additions の RPM が無い（AppStream・EPEL 10・ELRepo el10 のどれにも無い）。Fedora の `virtualbox-guest-additions` は Fedora 43〜Rawhide だけ | 不可 |
| カーネルのモジュール（`vboxguest`）を使う | Fedora の方式。EL10 のカーネルは `CONFIG_VBOXGUEST` が無効 | 不可 |

Guest Additions の入手元とビルドの場所:

- **ホストの CD（採用）**: ホストの VirtualBox に同梱の ISO なので、必ず同じ版になる（Linux のホストでは、Oracle の rpm の署名で守られた配布物）。代わりに、VM のウィンドウで CD を入れる操作が 1 回要る
- 公式サイトの ISO（不採用）: 版を自分で合わせる必要がある。検証では、ホストの CD の代わりにこれを使った
- **VM の上でビルドする（採用）**: レジストリが要らない。代わりに VM に 10 GB ほどの空きが要り、OS の更新のたびに VM でビルドし直す
- 別のマシンでビルドしてレジストリに置く（不採用）: 複数の VM で使うなら向くが、レジストリと認証の準備が要る

### 完了時点の状態

**手順 8 で作ったイメージの中身**（Secure Boot のとき。代役のコンテナで作ったイメージを、実機の rootless の podman に読み込んで見た。VM では `podman` に `sudo` を付ける）:

```
$ podman images localhost/vbox-ga
REPOSITORY         TAG         IMAGE ID      CREATED        SIZE
localhost/vbox-ga  latest      <IMAGE_ID>    5 minutes ago  5.07 GB
$ podman run --rm --network none localhost/vbox-ga:latest sh -c 'ls /usr/lib/modules/*/misc; systemctl is-enabled vboxadd vboxadd-service; cat /usr/lib/tmpfiles.d/vboxadd.conf /usr/lib/sysusers.d/vboxadd.conf; find /var | sort'
vboxguest.ko
vboxsf.ko
vboxvideo.ko
enabled
enabled
L+ /var/lib/VBoxGuestAdditions - - - -
u vboxadd -:1 - /var/run/vboxadd /bin/false
g vboxsf -
g vboxdrmipc -
/var
/var/cache
/var/lib
/var/log
/var/tmp
```

- ベースのイメージとの差は 151 MB。パッケージの一覧はベースと同じ（ビルドの道具は残らない）
  - これは `libXt` の行を足す前の Containerfile の結果。今の Containerfile では `libXt` が増え、VM の `bootc upgrade` で入れ替わった層は 151.5 MB → 151.9 MB だった
- unit は 2 つ
  - `vboxadd.service`: `ExecStart=/opt/VBoxGuestAdditions-7.2.20/init/vboxadd start`、`Type=oneshot`、`Before=` に `display-manager.service`
  - `vboxadd-service.service`: `Type=forking`、`After=vboxadd.service`
- `/usr/bin/VBoxClient`・`/usr/sbin/VBoxService`・`/usr/sbin/rcvboxadd` は `/opt/VBoxGuestAdditions-7.2.20/` へのリンク。`VBoxDRMClient` は setuid（`-rwsr-xr-x`）
- udev のルールは `KERNEL=="vboxguest", OWNER="vboxadd", MODE="0660"` と `KERNEL=="vboxuser", OWNER="vboxadd", MODE="0666"`
- `/etc/selinux/targeted/contexts/files/file_contexts.local` に `mount.vboxsf` の `mount_exec_t` が入り、`matchpathcon` もそう答える

**VM での状態**（手順 13 の後。`lsmod` から `pgrep -a VBoxClient` までは、`libXt` を足した版へ[更新](#更新)した後のもの。`pgrep -a VBoxService` から下は手順書の外のコマンドで、更新の前に見た）:

```
$ lsmod | grep -E '^vbox'
vboxguest             528384  4
$ systemctl is-active vboxadd vboxadd-service
active
active
$ pgrep -a VBoxClient
<PID> /usr/bin/VBoxClient --clipboard
<PID> /usr/bin/VBoxClient --clipboard
<PID> /usr/bin/VBoxClient --vmsvga-session
<PID> /usr/bin/VBoxClient --vmsvga-session
$ pgrep -a VBoxService
<PID> /usr/sbin/VBoxService --pidfile /var/run/vboxadd-service.sh
$ getent passwd vboxadd; getent group vboxsf vboxdrmipc
vboxadd:x:<UID>:1::/var/run/vboxadd:/bin/false
vboxsf:x:<GID>:
vboxdrmipc:x:<GID>:
$ ls -Z /opt/VBoxGuestAdditions-7.2.20/other/mount.vboxsf
system_u:object_r:mount_exec_t:s0 /opt/VBoxGuestAdditions-7.2.20/other/mount.vboxsf
$ sudo keyctl list %:.platform | grep -i virtualbox
<ID>: ---lswrv     0     0 asymmetric: VirtualBox Guest Additions module signing key: <KEY_ID>
```

- ホストの `VBoxManage showvminfo <VM> --machinereadable` では、`GuestAdditionsVersion="7.2.20 r175154"`、`GuestAdditionsRunLevel=2` だった
- ゲストのジャーナルの AVC の拒否は 0 件だった

### 注意点

- **dnf でも `.run` でも入らない**: bootc の `/usr`・`/opt` は読み取り専用。派生イメージに焼き込む（[手順 5〜9](#実施手順)）
- **公式の ISO で入れた VM は `:latest` を追う**: `BASE_IMAGE` の既定は `:latest`。別のタグを追う VM では、手順 2 の `Booted image:` に合わせて手順 1 を直す（[手順 1](#実施手順) の補足）
- **Guest Additions のインストーラは、bootc 向けに 4 か所を直して使う**: unit・`/var` の設定・ユーザーとグループ・カーネルの版（[手順 5](#実施手順) の補足）
- **kernel-rt のイメージでも、同じ手順で入る**: `kernel-rt-devel` のある `rt` のリポジトリをイメージで有効にしておく。VM で確かめた（[手順 5](#実施手順) の補足）
  - ただし起動のたびに、`vboxguest` を読み込んだ直後にカーネルの `WARNING` が 1 回出る。Guest Additions の働きには影響が見えなかった（[手順 11](#実施手順) の補足）
- **イメージに `libXt` を入れる**: 無いと GNOME のセッションで `VBoxClient --clipboard` が 5 秒ごとに落ち、クリップボードの共有が動かない（[手順 5](#実施手順) の補足）
- **切り替えた後は、OS の更新もビルドし直しになる**: `bootc upgrade` はこの VM の中のイメージしか見ない（[更新](#更新)）
- **カーネルが変わったら、VM の上ではモジュールを作り直せない**: ビルドの道具をイメージから消しているため。イメージごとビルドし直す
- **Secure Boot では鍵の登録が要る**: MokManager の最初の画面は 10 秒で消え、逃すと登録されない。鍵を作り直したら `--no-cache` でビルドし直す（[手順 4・10](#実施手順)）
- **CD を入れても、GNOME は何も表示しない**: 自動実行の確認も、デスクトップのアイコンも出ない。10 秒ほど待ってから手順 7 を貼る（[手順 6](#実施手順)）
- **元のイメージに戻すときは、`--enforce-container-sigpolicy` を付けない**: Atomic Desktop の `policy.json` の既定では断られる。付けなくても署名は確かめられる（[ロールバック](#ロールバック)の手順 1 の補足）
- **アンインストーラは使えない**: 戻すときはイメージを切り替える（[ロールバック](#ロールバック)）
- **ホスト側の手順書は別**: VirtualBox 本体は [virtualbox.md](virtualbox.md)。ホスト側でモジュールを署名する鍵（同じ `/var/lib/shim-signed/mok/` の置き場所）は、ホストの PC のもので、VM の鍵とは別物

### 参照

- [bootc — Booting local builds](https://bootc-dev.github.io/bootc/booting-local-builds.html) — `podman build` と `bootc switch --transport containers-storage`
- [bootc — Filesystem](https://bootc-dev.github.io/bootc/filesystem.html) — `/var` の中身は最初のインストールでしか展開されない（Docker の `VOLUME` と同じ）、`/opt` は読み取り専用
- [bootc — Users and groups](https://bootc-dev.github.io/bootc/building/users-and-groups.html) — `/etc/passwd` の 3-way マージと `systemd-sysusers`
- [bootc-switch(8)](https://bootc-dev.github.io/bootc/man/bootc-switch.8.html) / [bootc-upgrade(8)](https://bootc-dev.github.io/bootc/man/bootc-upgrade.8.html) — `--apply`・`--transport`・`--enforce-container-sigpolicy`
- [AlmaLinux Atomic Desktop](https://github.com/AlmaLinux/atomic-desktop) — ベースのイメージの作り方（`/opt`・`/usr/local`・`policy.json`・`bootc-fetch-apply-updates` のドロップイン）、ISO の `iso.toml`（キックスタートの `%post` の `bootc switch --mutate-in-place`）とビルドの設定（`LATEST_TAG=latest`）
- [Oracle VirtualBox User Guide 7.2 — Guest Additions](https://docs.oracle.com/en/virtualization/virtualbox/7.2/user/guestadditions.html) — Guest Additions の機能と、Linux のゲストへの導入
- [VirtualBox — Changelog 7.2](https://www.virtualbox.org/wiki/Changelog-7.2) — RHEL 10.1・10.2（7.2.8）と RHEL 10.3（7.2.18）のカーネルへの対応、Wayland のクリップボード
- [VirtualBox のソース（GitHub の v7.2.20）](https://github.com/VirtualBox/virtualbox/tree/v7.2.20/src/VBox/Additions/linux/installer) — `vboxadd.sh`・`install.sh.in`・`vboxadd-x11.sh` と `src/VBox/Installer/linux/routines.sh`。ISO の中のスクリプトと同じ中身であることを確かめた
- `man tmpfiles.d`（`L+`）/ `man sysusers.d`（`uid:gid`）/ `man Containerfile`（`RUN --mount=type=secret`）

---

### 付録: コンテナでの検証記録（2026-09-28）

**環境**: AlmaLinux 10.2 / x86_64 のノート PC（カーネル `6.12.0-211.56.1.el10_2`、SELinux は Enforcing、Secure Boot は有効）の上の、rootless の podman 5.8.2。VirtualBox は入れていない。`sudo` は使わず、実機の設定は変えていない（使ったのは `~/.local/share/containers` と一時ディレクトリだけで、終わった後に消した）。

**使ったもの**:

- ベースのイメージ `quay.io/almalinuxorg/atomic-desktop-gnome:10`（10.2.20260924.1、マニフェストリストの digest `sha256:7be643fe193b907fe0eb4da59b46a91f5eb851a750b04edd5a4ab76f81d8dcff`、4.92 GB）。実機の rootless の podman での取り込みは 2 分 8 秒
- カーネルがずれる場合の試験に、`:10.2.20260916.0`（カーネル `6.12.0-211.53.1.el10_2`）
- Guest Additions: 公式サイトの `VBoxGuestAdditions_7.2.20.iso` を `SHA256SUMS`（`4c6ba898…16e7`）で照合し、`bsdtar --options 'iso9660:!rockridge'` で取り出した（ホストの CD の代わり）
  - ISO には Rock Ridge が無く、オプション無しの bsdtar は `Tried to parse Rockridge extensions, but none found` で失敗した
- キャッシュの試験に、7.2.18 の ISO（同じく照合）

**VM の代役のコンテナ**（手順 1〜9 と、[更新](#更新)・[ロールバック](#ロールバック)の手順 1・2）:

- ベースのイメージそのものを `--privileged` で起動し、中に uid 1000 のユーザー（NOPASSWD の sudo）を作った
- 中の podman（rootful）は、実機の一時ディレクトリを `/var/lib/containers` にマウントし、入れ子で動くように `containers.conf` を足した（`netns="host"`・`cgroups="disabled"`・`cgroup_manager="cgroupfs"` など）
- CD: ISO の中身を `/run/media/<USER>/VBox_GAs_7.2.20` に読み取り専用でマウントした（ディレクトリ 0500、ファイル 0400、所有者はそのユーザー）
- `mokutil` はスタブにした（本物はコンテナでは `EFI variables are not supported on this system`）

| スタブ | 返すもの |
|---|---|
| `mokutil --sb-state` | `SecureBoot enabled` |
| `mokutil --import` | 一時パスワードを 2 回読み、登録の予約の印を置く |
| `mokutil --test-key` | 登録済みの印があれば `is already enrolled`（MokManager での登録は、印を置いて模した） |

**起動を模したコンテナ**（手順 11・13、[共有フォルダーを使う（任意）](#共有フォルダーを使う任意)、[ロールバック](#ロールバック)の手順 3）:

- 手順 8 で代役のコンテナの中に作ったイメージを、`podman save` / `podman load` で実機の podman に移した
- `/etc/passwd`・`/etc/group`・`/etc/shadow`・`/etc/gshadow` をベースのイメージのものに戻し、ログインするユーザーを足した（手元で変更済みの `/etc` は 3-way マージで残る、を模す）
- `/var` は空の tmpfs にし、systemd を PID 1 で起動した。`/var/lib/shim-signed/mok/MOK.der` は代役のコンテナから写した（VM では `/var` が残る）

**流し方**: 本文の `bash` のコードブロックを抜き出し、1 つずつ新しい `podman exec`（そのユーザーで、`HOME` と `USER` を設定）で実行した。各ブロックの先頭に手順 1 のブロックを足した（本文の「新しい端末を開いたら手順 1 を貼り直す」と同じ）。手順 4 の一時パスワードは標準入力から渡した。

| 手順 | 結果 |
|---|---|
| 1. 変数 | `BASE_IMAGE = quay.io/almalinuxorg/atomic-desktop-gnome:10` |
| 2. 環境 | `podman`（VM なら `oracle`）、`df -h /var` の空き、`bootc status` は起動したシステムが無いので `booted: null` の YAML |
| 3. Secure Boot | `SecureBoot enabled`（スタブ） |
| 4. 鍵 | `MOK.der`（876 バイト）と `MOK.priv`（`-rw-------`）。`mokutil --import` はスタブ |
| 5. Containerfile | 2668 バイト。実機で先に試した Containerfile と同じ中身 |
| 7. CD | `MD5 checksums are OK. All good.`、`Identification: VirtualBox 7.2.20 Guest Additions for Linux` |
| 8. ビルド | ベースの取り込み（署名の検査あり）からビルドの終わりまで 2 分 22 秒。3 つのモジュールが `signer=VirtualBox Guest Additions module signing key`、`enabled` が 2 行、`Checks passed: 13`、`Successfully tagged localhost/vbox-ga:latest` |
| 9. 切り替え | `error: Switching: Initializing storage: Preparing for write: Detected container; this command requires a booted host system.` |
| 11. 確認（起動を模したコンテナ） | `lsmod` は空、`systemctl is-active` は `failed` が 2 行（コンテナではモジュールを読み込めない）、`pgrep` は空（画面が無い）、`bootc status` は YAML |
| 13. 署名（同上） | `is already enrolled`（スタブ）と `VirtualBox Guest Additions module signing key`（本物の `modinfo`） |
| 共有フォルダー 2・4（同上） | `usermod -aG vboxsf` が通り、`id -nG` に `vboxsf`。`findmnt -t vboxsf` は空 |
| 更新 2 | 手順 8 を貼り直すと、`Using cache` が 4 行で同じイメージ ID。ベースは取り込み直さなかった |
| 更新 3・ロールバック 1 | 手順 9 と同じ `Detected container` |
| ロールバック 2 | `Untagged:` が 2 行と `Deleted:` が 4 行。ビルドの最初の段（`<none>`、6.43 MB）が残った |
| ロールバック 3（起動を模したコンテナ） | 何も出ずに終わり、`vboxadd`・`vboxsf`・`vboxdrmipc`・リンク・ログが消えた |

**手順書を流す前に、別のコンテナで確かめたこと**:

| 確認 | 結果 |
|---|---|
| ベースのイメージの中身 | [実施前の状態](#実施前の状態)。`bootc switch --help` に `--apply`・`--transport`・`--enforce-container-sigpolicy`、`bootc upgrade --help` に `--apply` がある |
| インストーラをそのまま流す（試作ビルド） | 終了コード 1。`/etc/rc.d/init.d/vboxadd`・`vboxadd-service` だけで unit は無く、`systemctl is-enabled` は `disabled`（`systemd-sysv-install` が無い）。インストールのログに `ln: failed to create symbolic link '/etc/rc.d/rc3.d/S10vboxadd'` など 14 行。`bootc container lint` は `sysusers`・`var-log`・`var-tmpfiles` の 3 つを警告 |
| 試作ビルドが残したもの | `/var/lib/VBoxGuestAdditions/{config,filelist}`、`/var/log/vboxadd-{install,setup}.log`、dnf のキャッシュと履歴、`/var/cache/ldconfig/aux-cache`。`/etc` にユーザー 1 つとグループ 2 つ、udev のルール、`vboxclient.desktop`、X のセッションのスクリプト 2 つ、`depmod.d`、`kernel/postinst.d`・`prerm.d`、SELinux の `file_contexts.local` |
| 試作ビルドの initramfs | `Updating initramfs` の後に `Failed to connect to system scope bus via local transport`（`systemd-inhibit` が失敗し、dracut は動かない）。`/boot` は空のまま |
| vboxvideo | EL10.2 の kernel-devel の `Makefile` が `RHEL_DRM_VERSION = 6` なので、インストーラはビルドする（7 以上なら飛ばす） |
| 設定が無いときの `vboxadd` | 試作ビルドのイメージで `/var` を空にすると、`rcvboxadd start` が `Configuration file /var/lib/VBoxGuestAdditions/config not found` で終了コード 1 |
| 署名の確かさ | 署名したモジュールの `sig_hashalgo` は `sha512`。署名を取り出し、kernel-devel の `extract-module-sig.pl` と `openssl dgst -sha512 -verify` で `Verified OK` |
| キャッシュ | 鍵だけを作り直したビルドは `Using cache` が 4 行で、`sig_key` が古い鍵のまま。`--no-cache` で新しい鍵の `sig_key` に変わった。7.2.18 の `.run` では Guest Additions の段をやり直し、`7.2.18 r175117` のモジュールと `/opt/VBoxGuestAdditions-7.2.18` になった |
| カーネルがずれる場合 | `10.2.20260916.0`（`211.53.1`）を `211.56.1` の上でビルドして、モジュールは `211.53.1` 向け。`depmod: FATAL` が 2 回出て、ビルドも 2 回走った |
| 起動の模擬（実機の podman でビルドしたイメージでも） | `systemd-sysusers` が `vboxsf`・`vboxdrmipc`・`vboxadd` を作り、tmpfiles がリンクを張った。`vboxadd` は `Starting.` → `reloading kernel modules and services` → `unable to load vboxguest kernel module` で、作り直し（`Setting up modules`）には入らなかった |
| 署名の検査が効いていること | 代役のコンテナで、`policy.json` の鍵を別の鍵に差し替えて取り込むと `Source image rejected: cryptographic signature verification failed: invalid signature when validating ASN.1 encoded signature`。元の `policy.json` では取り込めた |
| リポジトリ | `dnf repoquery --available '*virtualbox*' '*vboxguest*' '*vbox*'` と `--whatprovides 'kmod(vboxguest.ko)'` は、`appstream`・`baseos`・`crb`・`epel`・`extras` のどれでも空。ELRepo の el10 の一覧にも `vbox` を含むものは無い |
| `cp` と `install` | 0400 の `.run` を `cp` で 2 回写すと、2 回目が `Permission denied`。`install -m 0644` は通る |
| ISO の中のスクリプト | `vboxadd`・`vboxadd-service`・`vboxadd-x11` は、GitHub の v7.2.20 と同じ（`$Id` の行を除く） |

**読んだファイル**: ISO の中の `VBoxLinuxAdditions.run` を `--noexec` で展開した `install.sh`・`routines.sh` と、その中の `VBoxGuestAdditions-amd64.tar.bz2` の `init/vboxadd`・`init/vboxadd-service`・`init/vboxadd-x11`・`other/98vboxadd-xclient`。bootc の `lints.rs`（main）と `status.rs`・`cli.rs`（v1.16.4）、AlmaLinux の `bootc-images` と `atomic-desktop` の Containerfile とスクリプト。

#### 未確認事項

- VirtualBox の VM での本実行（本書は VM に適用していない。検証はコンテナのみ）
- `bootc switch --apply --transport containers-storage`・`bootc upgrade --apply`・`bootc rollback`・`bootc switch --enforce-container-sigpolicy` の実際の動作と表示
- MokManager での鍵の登録と削除、署名したモジュールがカーネルに受け入れられること
- モジュールの読み込み、`/dev/vboxguest`、`vboxadd.service` と `vboxadd-service.service`（VBoxService の時刻の同期など）の実際の動作
- VBoxClient（GNOME の Wayland でのクリップボードの共有、`--vmsvga-session` での画面サイズの追従）
- 共有フォルダーの自動マウント（マウントされる場所、`vboxsf` グループでの読み書き）と、`mount -t vboxsf` での手動のマウント
- SELinux（Enforcing）の下での動作（`mount.vboxsf` の `mount_exec_t` がデプロイ時に付くか）
- GNOME での CD の自動マウントの場所（`/run/media/<USER>/VBox_GAs_7.2.20`）と、自動実行を尋ねる画面
- VirtualBox のメニューの日本語の名前
- 切り替えた後に、イメージが足した `/etc` のファイルが、元のイメージに戻したときに消えること
- KDE・COSMIC の Atomic Desktop と、素の `almalinux-bootc:10` での動作

---

### 付録: VirtualBox の VM での本実行（2026-09-29）

前の付録の後、x86_64 の実機の VirtualBox の VM で本実行した。前の付録の未確認事項のうち、次のものはこれで済んだ。

- VM での本実行、`bootc switch`・`bootc upgrade`・`bootc rollback`
- MokManager での鍵の登録と削除、モジュールの読み込み、VBoxService・VBoxClient
- 共有フォルダーの自動マウントと読み書き、SELinux の下での動作
- CD の自動マウントの場所と自動実行、メニューの日本語の名前、元のイメージに戻したときの `/etc`

**環境**:

- ホスト: AlmaLinux 10.2 / x86_64 のノート PC（カーネル `6.12.0-211.56.1.el10_2`、GNOME 49.4 / Wayland、SELinux は Enforcing、ロケールは en_US.UTF-8）
  - VirtualBox 7.2.20 は、同じ日に [virtualbox.md](virtualbox.md) を実機で通して入れた（ホストの Secure Boot は無効。virtualbox.md の付録）
- VM は[対象と検証環境](#対象と検証環境)の表のとおり
- ISO: 公式の `atomic-desktop-gnome-amd64.iso`（3,062,765,568 バイト、2026-09-21）を、同じ場所の `atomic-desktop-gnome-amd64.iso-CHECKSUM` の sha256 で照合した

**手順書の外で行った準備**（検証環境の都合）:

- VM は `VBoxManage` で作った
  - `createvm --ostype RedHat10_64`、`modifyvm --firmware=efi --memory=8192 --cpus=4 --vram=128 --graphicscontroller=vmsvga --audio-enabled=off --nic1=nat --rtc-use-utc=on`、`--natpf1 "ssh,tcp,127.0.0.1,2222,,22"`
  - SATA に 80 GB の VDI（可変）と ISO をつなぎ、`modifynvram` で `inituefivarstore` → `enrollmssignatures` → `enrollorclpk` → `secureboot --enable`
  - クリップボードと共有フォルダーは足さなかった（手順書が読者にさせる設定なので、その手順のところで足した）
- ISO の GRUB の既定（`Install AlmaLinux 10.2`）から Anaconda を起動し、キーボードだけで操作した（`VBoxManage controlvm` の `keyboardputstring` / `keyboardputscancode`。画面は `screenshotpng`）
  - English（US）、US 配列、自動パーティション、管理者のユーザー（パスワードあり）、root は無効、時刻は既定のまま。インストールは約 1 分
  - **Reboot System の前に ISO を取り出したら、灰色の画面のまま再起動しなかった**（インストーラが ISO から動いているため）。`controlvm reset` でディスクから起動した
- 最初のログインの後:
  - GNOME のツアーは Skip
  - ネットワーク: `sudo nmcli con mod enp0s3 connection.autoconnect yes && sudo nmcli con up enp0s3`（[実施前の状態](#実施前の状態)の表）
  - 画面の消灯とロックを止めた（`gsettings` で `org.gnome.desktop.session idle-delay` を 0、`org.gnome.desktop.screensaver lock-enabled` を false）
  - VM を止めてスナップショットを取った（戻すことは無かった）
- ホストの画面のロックは、`gnome-session-inhibit --inhibit idle` で止めた

**流し方**:

- 本文の `bash` のコードブロックを抜き出し（リストの字下げだけ外す）、ホストから VM への SSH のログインシェル（`ssh -p 2222`）に 1 つずつ貼って Enter を送った
  - 端末は擬似端末の上の bash で、ブラケットペーストが効く
  - `sudo` のパスワードと `mokutil` の一時パスワードは、入力待ちが出てから送った
- GNOME のセッション（CD の自動マウントと VBoxClient）は、VM の画面でログインしたままにした
- 手順書の版: 52299ac（`{ … }` で囲んだ後）の版を貼った。VM で見つけた 2 か所（`libXt`、[ロールバック](#ロールバック)の手順 1）は、直した版を貼り直した
- 手順 1 は、手順 2 の分岐のとおり `:latest` に直して貼り直し、SSH をつなぎ直すたびに貼り直した
- ホスト側のメニューの操作は、同じ働きの `VBoxManage` で行った

| 手順書の操作 | 使ったコマンド |
|---|---|
| 「デバイス」→「Guest Additions CD イメージを挿入」 | `VBoxManage storageattach <VM> --storagectl SATA --port 1 --device 0 --type dvddrive --medium additions`（`list systemproperties` の `Default Guest Additions ISO` は `/usr/share/virtualbox/VBoxGuestAdditions.iso`） |
| 「デバイス」→「クリップボードの共有」→「双方向」 | `VBoxManage controlvm <VM> clipboard mode bidirectional` |
| ウィンドウの大きさを変える（自動リサイズ） | `VBoxManage controlvm <VM> setvideomodehint 1600 900 32` |
| 設定の「共有フォルダー」で足し、「自動マウント」にチェック | `VBoxManage sharedfolder add <VM> --name <名前> --hostpath <パス> --automount --transient` |
| GNOME からログアウトしてログインし直す | `gnome-session-quit --logout --no-prompt` の後、VM の画面でログイン |

| 手順 | 結果 |
|---|---|
| 1. 変数 | `BASE_IMAGE = quay.io/almalinuxorg/atomic-desktop-gnome:10`（直す前の既定） |
| 2. 環境 | `oracle`、`/var` の空き 42G、`● Booted image: quay.io/almalinuxorg/atomic-desktop-gnome:latest`（10.2.20260918.1）。手順書の分岐のとおり、手順 1 を `:latest` に直して貼り直した |
| 3. Secure Boot | `SecureBoot enabled` |
| 4. 鍵（囲んだ形） | `MOK.der`（876 バイト）と `MOK.priv`（1708 バイト、`-rw-------`）。`sudo` は手順 2 の記憶で聞かれず、一時パスワードを 2 回 |
| 5〜6. Containerfile | 2668 バイト。CD を入れても GNOME の画面には何も出ず、10 秒ほど後に `/run/media/<USER>/VBox_GAs_7.2.20` にマウントされていた |
| 7. CD | `MD5 checksums are OK. All good.`、`Identification: VirtualBox 7.2.20 Guest Additions for Linux` |
| 8. ビルド | 305 秒。署名を確かめてベースを取り込み（`Storing signatures`）、`depmod: ERROR` と `depmod: FATAL` が 2 回ずつ（動いているカーネルは 211.55.1）、`installer exit=1`。3 つのモジュールが 211.56.1 向けで署名あり、`enabled` が 2 行、`Checks passed: 13`、`Successfully tagged localhost/vbox-ga:latest` |
| 9〜10. 切り替え（1 回目） | `layers already present: 65; layers needed: 20 (1.7 GB)` → `Queued for next boot: ostree-unverified-image:containers-storage:localhost/vbox-ga:latest` → 再起動。MokManager をわざと見送った（次の表） |
| 9〜10. 切り替え（やり直し） | 手順 10 の箇条書きのとおり `sudo mokutil --import ...` を貼り直し、`sudo systemctl reboot` → 最初の画面でキー → `Enroll MOK` → `Continue` → `Yes` → パスワード → `Reboot` |
| 11. 確認 | `vboxguest` の行だけ（`vboxsf` は無い）、`active` が 2 行、`VBoxClient --clipboard` と `--vmsvga-session` が 2 つ、`● Booted image: containers-storage:localhost/vbox-ga:latest`（`Rollback image:` は元の `:latest`）。ただし `VBoxClient --clipboard` は、ログインの直後から 5 秒ごとに落ちていた（次の表） |
| 13. 署名（囲んだ形） | `is already enrolled`、`VirtualBox Guest Additions module signing key` |
| 5・8 を直した版で貼り直し、更新 3 | Containerfile 2834 バイト → ビルド 161 秒（`libXt-1.3.0-5.el10` が入り、`mknod: /dev/vboxguest: Operation not permitted` と `installer exit=2`）→ `sudo bootc upgrade --apply` が `Queued for next boot:` と入れ替わった層（151.5 MB → 151.9 MB）を出して再起動。`VBoxClient --clipboard` は落ちなくなった |
| 共有フォルダー 1〜4 | 足すと `vboxsf` が読み込まれ、`/run/media/sf_<名前>`（`gid=<GID>`、`dmode=0770`、`fmode=0770`）にマウントされた。グループに入る前は `Permission denied`。手順 2 は無出力 → ログインし直し → 手順 4 で `vboxsf` とマウントの行。ホストとの間で読み書きできた |
| 更新 2・3（変更なし） | `Using cache` が 4 行で同じイメージ ID（5 秒）。`No changes in ...` と `No update available.` を出し、再起動しなかった（boot_id が同じ） |
| ロールバック 1（直す前） | ``containers-policy.json specifies a default of `insecureAcceptAnything`; refusing usage`` で止まった |
| ロールバック 1（直した版） | `Fetching layers 0/0`、`Deploying: done (7 seconds)`、`Queued for next boot: quay.io/almalinuxorg/atomic-desktop-gnome:latest` → 再起動。イメージが足した `/etc` のファイルと `/opt` の本体が消えていた |
| ロールバック 2 | `Untagged:` が 2 行、`Deleted:` が 2 行。`<none>` が 2 つ（6.43 MB と、`libXt` を足す前の 5.07 GB）残り、`sudo podman image prune`（`[y/N]` に `y`）で消えた。`/var` の使用量は 6.1G |
| ロールバック 3（囲んだ形） | 無出力。ユーザー・グループ・リンク・ログ 5 つが消えた |

**手順書の外で確かめたこと**:

| 確認 | 結果 |
|---|---|
| MokManager を見送る | `Press any key to perform MOK management` が `Booting in 10 seconds` から数え下げて消え、そのまま起動した。`sudo dmesg` に `Loading of module with unavailable key is rejected` が 2 回、`vboxadd` は `unable to load vboxguest kernel module, see dmesg` で `failed`、VBoxClient は動かず、`mokutil --test-key` は `is not enrolled`。通知は出ず、`journalctl --user -b` に `GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name is not activatable` |
| `VBoxClient --clipboard` が落ちる原因 | `coredumpctl` に `/usr/bin/VBoxClient --clipboard` の `SIGTRAP` が 54 個。GNOME のセッションと同じ `DISPLAY`・`XAUTHORITY` を付けて前面で動かすと、`VBGHDISPLAYSERVERTYPE_XWAYLAND` → `Initializing X11 clipboard (regular mode)` → `dlopen('libXt.so.6', RTLD_NOW \| RTLD_LOCAL) failed` → `Trace/breakpoint trap`。X の画面を開けない環境では `PURE_WAYLAND` の経路になり、落ちなかった。`bootc usr-overlay` で `libXt` を入れると、XWayland の経路のまま動いた |
| クリップボード | `libXt` を入れた版で、ホストの `wl-copy` → VM の端末に Ctrl+Shift+V、VM の端末で Ctrl+Shift+A・Ctrl+Shift+C → ホストの `wl-paste`。どちらの向きも文字列が届いた |
| 画面の大きさ | `setvideomodehint 1600 900 32` を送ると、入れる前は 1280x800 のまま、入れた後は 1600x900 になり、1280x800 に戻せた |
| 時刻の同期 | 入れる前は 4 時間ずれていた（[実施前の状態](#実施前の状態)）。切り替えた後の起動で `timesync vgsvcTimeSyncWorker: Radical guest time change: -14 387 957 862 000ns` が出て、直った |
| `vboxsf` | 共有フォルダーが無いうちは読み込まれない（`vboxadd` のコメントに `Module vboxsf module might not be loaded if VM has no Shared Folder mappings.`） |
| キーリング | 登録した鍵は `.platform` にあり、`.machine` には無かった |
| SELinux | `mount.vboxsf` の本体が `mount_exec_t`。ゲストのジャーナルの AVC の拒否は 0 件 |
| ホストから見た状態 | `GuestAdditionsVersion="7.2.20 r175154"`、`GuestAdditionsRunLevel=2`。`guestproperty` に `/VirtualBox/GuestInfo/OS/Release = '6.12.0-211.56.1.el10_2.x86_64'` |
| `bootc rollback` | 更新の後に `sudo bootc rollback` → `Next boot: rollback deployment.` → 再起動すると、1 つ前の派生イメージ（`libXt` 無し）で起動し、VBoxClient がまた落ち始めた。元のイメージのデプロイメントは、もう残っていなかった |
| 署名の検査 | `policy.json` の `quay.io/almalinuxorg/atomic-desktop-gnome` の鍵を別の鍵に差し替え、`--enforce-container-sigpolicy` を付けずに `bootc switch --apply` → `cryptographic signature verification failed: invalid signature when validating ASN.1 encoded signature`。元に戻した |
| MOK の削除 | `sudo mokutil --delete ...`（一時パスワード 2 回）→ `sudo mokutil --list-delete` に鍵 → 再起動 → 最初の画面でキー → `Delete MOK` → 「[Delete MOK]」（`View key 0` / `Continue`）→ `Continue` → 「Delete the key(s)?」→ `Yes` → パスワード → `Reboot` → `is not enrolled`（`.platform` にも MOK の一覧にも無い）→ `sudo rm -rf /var/lib/shim-signed` |
| メニューの名前 | 翻訳ファイル（`VirtualBox_ja.qm`）に「Guest Additions CD イメージを挿入(&I)」「クリップボードの共有(&C)」「双方向」「ゲストOSの画面を自動リサイズ(&G)」「VirtualBox について(&A)」「マザーボード(&M)」「UEFI(&E)」「セキュアブート」「自動マウント(&A)」。英語は `UICommon.so` の `Insert Guest Additions CD image...`・`&Shared Clipboard`・`Bidirectional`・`Auto-resize &Guest Display`・`About VirtualBox...`・`Motherboard`・`U&EFI`・`&Secure Boot`・`Auto-mount` |

#### 未確認事項

- VirtualBox の GUI のメニューそのものでの操作と、ウィンドウの大きさを手で変えたときの追従（同じ働きの `VBoxManage` で確かめた）
- Secure Boot が無効の VM での手順（手順 4・10・13 を飛ばす分岐。ビルドはコンテナで確かめた）
- 切り替えた直後の `bootc rollback`（`Rollback image:` が元のイメージであることだけ見た）
- [更新](#更新)の手順 1（ホストの VirtualBox の新しい版がまだ無い）と、ベースのイメージが新しくなったときの更新
- KDE・COSMIC の Atomic Desktop と、素の `almalinux-bootc:10` での動作
- ホストが Wayland でない場合のクリップボード
- VirtualBox の画面の日本語の表示（ホストのロケールが en_US.UTF-8 のため。名前は翻訳ファイルで確かめた）
- ブラケットペーストが効かない端末に、`{ … }` で囲んだ形を貼ったとき

---

### 付録: コマンドの表示と kernel-rt のコンテナでの確認（2026-09-29）

前の付録の VM での本実行の後に、手順 5 の Containerfile を直した（`set -x` でコマンドを表示する、kernel-rt のイメージでもビルドできるようにする）。直した版は VM では流さず、次のコンテナで確かめた。途中の版では dnf に `--repo=baseos --repo=appstream --repo=rt` を付けていたが、外して、イメージで有効なリポジトリを使う形にした（下の表は外した版の結果）。

**環境**:

- x86_64 のクラウドホスト（Ubuntu 24.04、4 vCPU・16 GB、カーネル `6.18.44-fc-v37`、cgroup v1）の Docker 29.3.1。利用者の実機と VM は使っていない
- VM の代役: `quay.io/almalinuxorg/atomic-desktop-gnome:latest`（10.2、カーネル `6.12.0-211.56.1.el10_2`、podman 5.8.2）を `--privileged`・`--network host` で起動し、中に uid 1000 のユーザー（NOPASSWD の sudo）を作った
  - 中の podman（rootful）は、ホストのディレクトリを `/var/lib/containers` にマウントした（overlay）
- Guest Additions: 公式サイトの `VBoxGuestAdditions_7.2.20.iso` を `SHA256SUMS`（`4c6ba898…16e7`）で照合し、`bsdtar --options 'iso9660:!rockridge'` で取り出した
  - `/run/media/<USER>/VBox_GAs_7.2.20` に読み取り専用でマウントした（ディレクトリ 0500、ファイル 0400、所有者はそのユーザー）
- `mokutil` はスタブにした（前の付録の 1 つ目と同じ。`--sb-state` は `SecureBoot enabled`）

**kernel-rt の検証用イメージ**（AlmaLinux は kernel-rt の bootc イメージを公開していないので作った。手順書には載せない）:

- 公式のイメージ（上と同じ）から、`kernel`・`kernel-core`・`kernel-modules`・`kernel-modules-core`・`kernel-modules-extra` を `rpm -e --nodeps` で外し、古い `/usr/lib/modules/<版>` を消した
- `dnf -y --repo=baseos --repo=appstream --repo=rt install kernel-rt kernel-rt-modules-extra` で、`rt` のリポジトリの 6.12.0-211.56.1.el10_2 を入れた
  - `kernel-rt-core`・`kernel-rt-modules`・`kernel-rt-modules-core` と `realtime-setup` も入り、initramfs はイメージの kernel-install（`Generating initramfs`）が作った
  - `/usr/lib/modules` は `6.12.0-211.56.1.el10_2.x86_64+rt` の 1 つだけになった
- そのままでは `bootc container lint` が 3 つを警告したので、検証用に直して `Checks passed: 13` にした
  - `/boot` の `symvers-<版>+rt.xz`（消した）、`realtime-setup` が足す `realtime` グループ（sysusers.d に `g realtime -`）、`/var/lib/rpm-state/kernel`（消した）
- `rt` を有効にしたもの（`almalinux-rt.repo` の `[rt]` を `enabled=1` にした）と、無効のまま（公式のイメージと同じ `enabled=0`）のものの 2 つを作った
  - Docker でビルドし（2 分半ほど）、`registry:2` で立てたローカルのレジストリに `localhost:5000/atomic-desktop-gnome-rt:latest`（有効）と `:rt-disabled`（無効）として置いた（どちらも 5.35 GB）
  - どちらも起動はしていない

**検証環境だけの設定**（手順書のコマンドは変えていない）:

- 中の podman の `containers.conf.d` は、前の付録の 1 つ目と同じ `netns = "host"`・`cgroups = "disabled"`・`cgroup_manager = "cgroupfs"`・`events_logger = "file"` に、`default_ulimits = ["nofile=20000:20000", "nproc=64313:64313"]` を足した
  - 足す前は、RUN の段が ``setrlimit `RLIMIT_NOFILE`: Operation not permitted``（`nofile` を足すと次は `RLIMIT_NPROC`）で失敗した。代役のコンテナの上限（`nofile` は 20000）を超える値を設定しようとしたため
- プロキシを通すため、sudo の `env_keep` に `HTTPS_PROXY` などを足した（podman build が RUN の段に渡す）
- `registries.conf.d` で `localhost:5000` を `insecure = true` にした（ローカルのレジストリが HTTP のため）

**流し方**:

- 前の付録の 1 つ目と同じく、本文の `bash` のコードブロックを抜き出し、各ブロックの先頭に手順 1 のブロックを足して、1 つずつ新しい `docker exec` で実行した
- kernel-rt の回は、読者が手順 1 を直すのと同じく、`BASE_IMAGE=` の値だけを `localhost:5000/atomic-desktop-gnome-rt:latest`（`rt` が無効の回は `:rt-disabled`）に書き換えた
- 抜き出した RUN の本体（ヒアドキュメントの中）と、全部のブロックは `bash -n` を通った

| 手順 | kernel（`BASE_IMAGE` は既定） | kernel-rt（検証用のイメージ。`rt` は有効） |
|---|---|---|
| 1 | `BASE_IMAGE = quay.io/almalinuxorg/atomic-desktop-gnome:latest` | `BASE_IMAGE = localhost:5000/atomic-desktop-gnome-rt:latest` |
| 3・4 | `SecureBoot enabled`（スタブ）、`MOK.der`（876 バイト）と `MOK.priv`（`-rw-------`） | kernel の回の鍵をそのまま使った |
| 5・7 | Containerfile 3225 バイト、`MD5 checksums are OK. All good.`、`Identification: VirtualBox 7.2.20 Guest Additions for Linux` | kernel の回のものをそのまま使った |
| 8 のコマンドの表示 | `+ kver=6.12.0-211.56.1.el10_2.x86_64`、`+ dnf … 'kernel-devel-uname-r = 6.12.0-211.56.1.el10_2.x86_64'`。`+` で始まる行は 126 行（そのうち `routines.sh` の分が 92 行）。`+ set +x` の後は、結果の行だけ | `+ kver=6.12.0-211.56.1.el10_2.x86_64+rt`、`+ TARGET_VER=6.12.0-211.56.1.el10_2.x86_64+rt`。`+ set +x` の後は、結果の行だけ |
| 8 の道具 | 有効な AppStream・BaseOS・CRB・Extras・EPEL のメタデータを読み（`rt` は読まない）、`kernel-devel`（`appstream`）を含む 15 パッケージを入れて、最後に 15 パッケージを消した | `rt` のメタデータ（25 MB）も読み、`kernel-rt-devel`（`rt`）を含む 15 パッケージを入れて、最後に 15 パッケージを消した |
| 8 のインストーラ | `Building the Guest Additions 7.2.20 modules for kernel 6.12.0-211.56.1.el10_2.x86_64.`、`depmod: FATAL` が 2 回（動いているカーネルが別のため）、`installer exit=1` | `… for kernel 6.12.0-211.56.1.el10_2.x86_64+rt.`。3 つのモジュールがビルドでき、あとは kernel の回と同じ表示 |
| 8 の結果 | 3 つのモジュールが `6.12.0-211.56.1.el10_2.x86_64 SMP preempt mod_unload modversions` で `signer=VirtualBox Guest Additions module signing key`、`enabled` が 2 行、`Checks passed: 13`、`Successfully tagged localhost/vbox-ga:latest` | 3 つのモジュールが `6.12.0-211.56.1.el10_2.x86_64+rt SMP preempt_rt mod_unload modversions` で署名あり、`enabled` が 2 行、`Checks passed: 13`、`Successfully tagged` |
| 8 の所要時間 | 771 秒（ベースの取り込みを含む。`Storing signatures` が出た） | 728 秒（検証用のイメージの取り込みを含む） |
| できたイメージ | 5.07 GB。パッケージの一覧はベースに `libXt-1.3.0-5.el10` を足したもの | 5.51 GB。パッケージの一覧はベースに `libXt-1.3.0-5.el10` を足したもの。`/usr/lib/modules/<版>+rt/misc` に `vboxguest.ko`・`vboxsf.ko`・`vboxvideo.ko`（`sig_hashalgo` は `sha512`） |

- **`rt` が無効の kernel-rt のイメージ**（`:rt-disabled`）では、27 秒で止まった
  - `+ dnf -y install gcc make 'kernel-devel-uname-r = 6.12.0-211.56.1.el10_2.x86_64+rt'` の後に `No match for argument: kernel-devel-uname-r = 6.12.0-211.56.1.el10_2.x86_64+rt` と `Error: Unable to find a match: …`
- `--repo` を付けていた途中の版は、公式のイメージと `rt` が無効の検証用のイメージで流し、どちらも表の「8 の結果」と同じ行が出て、パッケージの差も `libXt` だけだった（`--repo=rt` が無効の `rt` も使うため、止まらなかった）
- 所要時間の多くは、最後のイメージの書き出し（`COMMIT`）だった。この環境の入れ子の podman での値で、[手順 8](#実施手順) の補足の時間とは比べられない
- この環境では、インストーラの始めに `libkmod: ERROR … could not open /proc/modules` と `Error: could not get list of modules` が出た。ホストのカーネルがモジュールに対応していない（`/proc/modules` が無い）ためで、ビルドの結果は変わらなかった
- 検証用のイメージのレジストリ（`localhost:5000`）は `policy.json` に載っていないので、取り込みで `Storing signatures` は出なかった（公式のイメージの取り込みでは出た）

#### 未確認事項

- 直した Containerfile での VM の本実行（手順 8 のビルド、手順 9 以降）
- kernel-rt のイメージでの `bootc switch`、MokManager での登録、起動、モジュールの読み込み、VBoxService・VBoxClient、共有フォルダー、更新、ロールバック
- 検証用ではない、利用者が作った kernel-rt のイメージ（作り方によって、`rt` のリポジトリが有効かどうかや `/usr/lib/modules` の中身が違いうる）
- Secure Boot が無効の分岐（直した行は分岐と関係しないので、今回は流していない）

---

### 付録: kernel-rt のイメージの VM での本実行（2026-09-29）

前の付録の後に、直した Containerfile（`57d70c8` の版）を、VM の付録と同じ実機の VirtualBox の VM で流した。自作の kernel-rt のイメージで動いている VM を作り、Secure Boot が無効の回と有効の回に分けた。

前の 2 つの付録の未確認事項のうち、次のものはこれで済んだ（どれも kernel-rt のイメージでの確認）。

- 直した Containerfile での VM の本実行。kernel-rt のイメージでの `bootc switch`・MokManager での登録・起動・モジュールの読み込み・VBoxService・VBoxClient・共有フォルダー・更新・ロールバック
- Secure Boot が無効の VM での手順（手順 4・10・13 を飛ばす分岐）、切り替えた直後の `bootc rollback`、ベースのイメージが新しくなったときの更新

**環境**:

- ホスト: VM の付録と同じノート PC（AlmaLinux 10.2、カーネル `6.12.0-211.56.1.el10_2`、VirtualBox 7.2.20、SELinux は Enforcing、GNOME 49.4 / Wayland）
  - ホストの Secure Boot は無効（VirtualBox のモジュールは署名なしで読み込まれている）。VM の Secure Boot は、VM の NVRAM の設定で切り替えた
- VM: VM の付録と同じ設定で新しく作った（4 vCPU・8 GB・VMSVGA 128 MB・SATA の 80 GB の VDI・NAT・UEFI とセキュアブート）
- ISO: VM の付録と同じ `atomic-desktop-gnome-amd64.iso`（sha256 が一致）
  - 入れた直後は `quay.io/almalinuxorg/atomic-desktop-gnome:latest`（10.2.20260918.1、カーネル `6.12.0-211.55.1.el10_2`）だった

**kernel-rt の検証用イメージ**（ホストの rootless の podman 5.8.2 で作った。手順書には載せない）:

- 前の付録と同じ作り方を、ベースと版を引数にして 2 つ作った
  - 作り方: `rpm -e --nodeps` で kernel の 5 つを外し、`dnf -y --repo=baseos --repo=appstream --repo=rt install kernel-rt-<版> kernel-rt-modules-extra-<版>` で入れた
  - そのうえで `[rt]` を `enabled=1` にし、lint の警告を直した
  - 1 つ目: ISO と同じ `10.2.20260918.1` に kernel-rt `6.12.0-211.55.1.el10_2`（ビルド 52 秒）。初めの `:latest`
  - 2 つ目: `10.2.20260926.0`（今の `:latest`）に kernel-rt `6.12.0-211.56.1.el10_2`（ビルド 56 秒）。[更新](#更新)を試すときに `:latest` にした
- どちらも `Generating initramfs`（rpm-ostree の kernel-install）で initramfs ができ、`Checks passed: 13`（警告なし）だった
- 送り出す前に、元のイメージと比べた
  - `/usr/lib/modules` は `…+rt` の 1 つだけ、`/boot` は空、`CONFIG_PREEMPT_RT=y`・`CONFIG_MODULE_SIG=y`・`CONFIG_LOCK_DOWN_IN_EFI_SECURE_BOOT=y`
  - initramfs の dracut のモジュールは元と同じで、大きさも同じくらい（約 243 MB）
  - `vmlinuz` の署名者は、元の kernel と同じ `AlmaLinux Secure Boot Signing`（`pesign -S`）
- 一緒に `realtime-setup`・`tuna`・`tuned-profiles-realtime` が入った
  - このイメージでは、Guest Additions を入れる前から `tuned-ppd.service`（SELinux の拒否）と `mcelog.service`（`CPU is unsupported`）が `failed` だった

**検証環境だけの設定**（手順書のコマンドは変えていない）:

- レジストリ: ホストの rootless の podman で `quay.io/libpod/registry:2.8.2` を `127.0.0.1:5000` に立て、2 つのイメージを置いた
  - VM からは NAT の `10.0.2.2:5000` で届くように、VM に `--nat-localhostreachable1=on` を付けた（付けない VM は `localhostReachable="0"`）
  - VM の `/etc/containers/registries.conf.d/90-pr56-registry.conf` で、`10.0.2.2:5000` を `insecure = true` にした（HTTP のため）
    - bootc と `sudo podman` の両方がこれを読んだ
- 手順 1 の前に、`sudo bootc switch --apply 10.0.2.2:5000/atomic-desktop-gnome-rt:latest` で VM を kernel-rt のイメージに切り替えた
  - `layers already present: 83; layers needed: 1 (366.4 MB)` の後に再起動した
  - Secure Boot のまま `6.12.0-211.55.1.el10_2.x86_64+rt`（`SMP PREEMPT_RT`）で起動し、lockdown は `integrity` だった
  - 止めてスナップショットを取り、Secure Boot が無効の回と有効の回をそこから始めた。無効の回は `VBoxManage modifynvram <VM> secureboot --disable`
- **スナップショットに戻しても、NVRAM の Secure Boot の設定は戻らなかった**（無効のまま。VirtualBox 7.2.20）
  - 有効の回は、`modifynvram <VM> secureboot --enable` で戻してから始めた。MOK は登録されていなかった
- Anaconda の後の Reboot System は、ISO をつないだまま選んだ。ディスクから起動し、VM の付録の灰色の画面は起きなかった

**流し方**:

- VM の付録と同じ。抜き出したブロックを、ホストから VM への SSH の擬似端末に 1 つずつ貼った
  - ホスト側のメニューの操作は、VM の付録の対応表の `VBoxManage` で行った
- 手順 1 は、手順 2 の分岐のとおり `BASE_IMAGE=10.0.2.2:5000/atomic-desktop-gnome-rt:latest` に直して貼り直した。新しい端末を開くたびに貼り直した
- 手順書の版: `57d70c8`（抜き出した全部のブロックは `bash -n` を通った）

| 手順 | Secure Boot が無効 | Secure Boot が有効 |
|---|---|---|
| 1・2 | 既定の値 → `oracle`、`/var` の空き 41G、`● Booted image: 10.0.2.2:5000/atomic-desktop-gnome-rt:latest`（`Version: 10.2.20260918.1` はベースのラベル）→ 手順 1 を直して貼り直した | 同じ |
| 3・4 | `SecureBoot disabled`。手順 4・10・13 は飛ばした | `SecureBoot enabled`。`MOK.der`（876 バイト）と `MOK.priv`（1704 バイト、`-rw-------`）、一時パスワードを 2 回 |
| 5〜7 | Containerfile 3225 バイト（写しと同じ中身）。CD を入れても画面に何も出ず、`/run/media/<USER>/VBox_GAs_7.2.20`。`All good.`、`VirtualBox 7.2.20 Guest Additions for Linux` | 同じ |
| 8 | 333 秒（ベースの取り込みを含む）。`+ kver=6.12.0-211.55.1.el10_2.x86_64+rt`、`+` の行は 118。dnf は AppStream・BaseOS・CRB・Extras・RT・EPEL を読み、`kernel-rt-devel-6.12.0-211.55.1`（`rt`）を含む 15 パッケージを入れて消した。`installer exit=1`、`+ '[' 0 = 1 ']'`。3 行が `…+rt SMP preempt_rt mod_unload modversions signer=`、`enabled` が 2 行、`Checks passed: 13` | 332 秒。`+` の行は 126（`+ hash=sha512` と、`sign-file sha512 /run/secrets/mok_priv /run/secrets/mok_der …` が 3 行。鍵の中身は出ない）。3 行が `signer=VirtualBox Guest Additions module signing key` |
| 9・10 | `layers already present: 84; layers needed: 2 (152.2 MB)`、`Queued for next boot: ostree-unverified-image:containers-storage:localhost/vbox-ga:latest`。GRUB（`ostree:0` と `ostree:1`、1 秒）から、MokManager を経ずに起動した | 同じ層の数。MokManager の最初の画面でキー → `Enroll MOK` → `Continue` → `Yes` → パスワード → `Reboot` |
| 11 | `vboxguest` の行、`active` が 2 行、`VBoxClient --clipboard`・`--vmsvga-session` が 2 つずつ、`● Booted image: containers-storage:localhost/vbox-ga:latest`（`Rollback image:` は kernel-rt のイメージ） | 同じ |
| 12 | クリップボードは両方向で文字列が届いた。`setvideomodehint 1600 900 32` で 1600x900 になり、1280x800 に戻せた | 同じ |
| 13 | 飛ばした | `is already enrolled`、`VirtualBox Guest Additions module signing key` |

Secure Boot が有効の回では、続けて次を流した。無効の回では、手順 12 の後に切り替えた直後の `bootc rollback` だけを試した。

| 節と手順 | 結果 |
|---|---|
| 共有フォルダー 1〜4 | 足すと `vboxsf` が読み込まれ（`… on 6.12.0-211.55.1.el10_2.x86_64+rt`）、`/run/media/sf_<名前>`（`gid=<GID>`、`dmode=0770`、`fmode=0770`）。グループに入る前は `Permission denied`。手順 2 は無出力 → ログインし直し → 手順 4 で `vboxsf` とマウントの行。256 MB のファイルが両方向で sha256 まで一致した |
| 更新 2・3（変わらないとき） | 新しい端末で手順 1 を貼り直してから手順 8: 3 秒、`Using cache` が 4 行で同じイメージ ID → `No changes in ostree-unverified-image:containers-storage:localhost/vbox-ga:latest => sha256:<DIGEST>` と `No update available.`、再起動しない（boot_id が同じ） |
| 更新 2・3（ベースとカーネルが新しくなったとき） | ホストで `:latest` を 2 つ目のイメージにした後、手順 8: 376 秒。新しいベースを取り込み、`+ kver=6.12.0-211.56.1.el10_2.x86_64+rt`、`kernel-rt-devel-6.12.0-211.56.1`（`rt`）。動いているカーネルと違うので `depmod: FATAL` が 2 回、`mknod: /dev/vboxguest: Operation not permitted` と `installer exit=1` → `sudo bootc upgrade --apply` が `layers already present: 66; layers needed: 20 (2.2 GB)` の後に再起動 → `6.12.0-211.56.1.el10_2.x86_64+rt` で手順 11〜13 がそろった |
| ロールバック 1 | 新しい端末で手順 1 を貼り直してから: `Fetching layers 0/0`、`Deploying: done (11 seconds)`、`Queued for next boot: 10.0.2.2:5000/atomic-desktop-gnome-rt:latest`。署名の検査の表示は無い → 再起動。モジュール・`/opt` の本体・イメージが足した `/etc` のファイルが消え、ユーザー・グループ・`/var` のリンク・ログ 4 つが残った |
| ロールバック 2 | `Untagged:` が 2 行、`Deleted:` が 4 行。`podman images` に `<none>` が 2 つ（前の派生イメージ 5.51 GB と 6.43 MB）→ `sudo podman image prune`（`[y/N]` に `y`）で、親のイメージも含めて 5 つ消えた。`/var` の使用量は 7.7G |
| ロールバック 3 | 無出力。ユーザー・グループ・リンク・ログが消えた。MOK は登録されたまま |
| 切り替えた直後の `bootc rollback`（Secure Boot が無効の回） | `Next boot: rollback deployment.` → 再起動 → kernel-rt のイメージ（Guest Additions 無し）で起動 → もう一度 `sudo bootc rollback` → 再起動 → 派生イメージに戻り、手順 11 がそろった |

- 手順書を直したところ: [手順 8](#実施手順) の `installer exit=1`（カーネルも新しくなったとき）、[手順 11](#実施手順) の補足の警告、[ロールバック](#ロールバック)のリードと手順 1・2

**手順書の外で確かめたこと**:

| 確認 | 結果 |
|---|---|
| カーネルの警告 | Guest Additions を入れた後の 4 回の起動すべてで、`vboxguest: Successfully loaded …` の直後に `WARNING: CPU: <CPU> PID: <PID> at kernel/rcu/tree_plugin.h:826 rcu_sched_clock_irq+0x330/0x340`（`Comm: (udev-worker)`）と呼び出し履歴。割り込まれていたのは `__fput` → `dput` → `kmem_cache_free` の途中で、`RAX: 00000000ffffffff`。Guest Additions を入れる前の起動では出ない |
| 警告の後 | RCU の stall・`BUG:`・`scheduling while atomic` は出ず、VBox のコアダンプも無い。`irq/20-vboxguest` のスレッドは `SCHED_FIFO` の 50 |
| taint | Secure Boot が無効: `loading out-of-tree module taints kernel.` と `module verification failed: signature and/or required key missing - tainting kernel`、`tainted` は 12800（O・E・W）。有効: 前の 1 行だけで、4608（O・W） |
| 鍵 | 登録した鍵は `.platform` のキーリングにあり、`.machine` には無い（VM の付録と同じ） |
| 時刻の同期 | どちらの回も、切り替えた後の起動で `timesync vgsvcTimeSyncWorker: Radical guest time change` が出て、4 時間のずれが直った |
| ホストから見た状態 | `GuestAdditionsRunLevel=2`、`GuestAdditionsVersion="7.2.20 r175154"`、`/VirtualBox/GuestInfo/OS/Release = '6.12.0-211.55.1.el10_2.x86_64+rt'`、`OS/Version` に `PREEMPT_RT` |
| SELinux | AVC の拒否は、Guest Additions を入れる前からの `tuned-ppd` のものだけ |

#### 未確認事項

- 直した Containerfile を、既定のカーネルのイメージの VM で流すこと
- 既定のカーネルで、同じ `rcu_sched_clock_irq` の警告が出るか。警告の原因
- `rt` が無効の kernel-rt のイメージを VM で使ったとき（前の付録のコンテナでは、手順 8 で止まることを確かめた）
- 検証用ではない、利用者が作った kernel-rt のイメージ
- 認証の要るレジストリ（bootc の文書では、bootc は `/etc/ostree/auth.json` などを読む。手順 8 の `sudo podman` が同じ認証で取り込めるかは確かめていない）
- kernel-rt の VM を長く動かしたとき（今回は 1 回の起動で長くて 16 分ほど）、kernel-rt での MOK の削除、[更新](#更新)の手順 1
