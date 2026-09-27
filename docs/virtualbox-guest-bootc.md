# VirtualBox Guest Additions 導入手順（AlmaLinux 10 bootc / Atomic Desktop のゲスト）

## 実施手順

> [!IMPORTANT]
> - **VirtualBox の VM の中の AlmaLinux Atomic Desktop（GNOME）にログインし、端末を開いて自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない
> - **dnf では入れない**。Guest Additions を焼き込んだ派生イメージをこの VM でビルドし、`bootc switch` で切り替える（手順 5〜8）
> - **手順 5 の後に、VM のウィンドウのメニューで Guest Additions の CD を入れる**（ホスト側の操作。手順 5 の箇条書き）
> - **手順 8 で再起動する**。Secure Boot が有効なら、起動の途中の MokManager の画面を VM のウィンドウで操作する
> - **手順 4 には対話入力（一時パスワード）がある**。手順 7 はビルドが終わるのを待ってから次を貼る

- 手順 1 の変数を設定したシェルで、上から順にコードブロックを貼る。新しい端末を開いたら手順 1 を貼り直す
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 共有フォルダーは[共有フォルダーを使う（任意）](#共有フォルダーを使う任意)、OS やホストの VirtualBox を上げたときは[更新](#更新)、戻すときは[ロールバック](#ロールバック)
- **切り替えた後は、`sudo bootc upgrade` だけでは OS が上がらない**（[更新](#更新)の手順でビルドし直す）

> [!WARNING]
> **x86_64 のコンテナでのみ検証した手順書**で、VirtualBox の VM では実行していない（[対象と検証環境](#対象と検証環境)）。
>
> - 派生イメージのビルド（モジュールのビルドと署名、`bootc container lint`）と、切り替えた後の最初の起動で起きること（ユーザーとグループの作成、設定へのリンク、サービスの有効化）はコンテナで確かめた
> - `bootc switch`・再起動・MokManager・モジュールの読み込み・VBoxService・VBoxClient（クリップボード・画面サイズ）・共有フォルダーは確かめていない

1. 変数を設定する（既定のままでよい）。

   ```bash
   BASE_IMAGE=quay.io/almalinuxorg/atomic-desktop-gnome:10   # 元のイメージ（手順 2 の Booted image）
   echo "BASE_IMAGE = ${BASE_IMAGE}"
   ```

   - Atomic Desktop の GNOME なら、このままでよい
   - KDE なら `quay.io/almalinuxorg/atomic-desktop-kde:10` のように、手順 2 の `Booted image:` に合わせて変える（本書では GNOME だけを検証した）
   - 手順 7、[更新](#更新)、[ロールバック](#ロールバック)で使う

1. VirtualBox の VM で bootc のシステムが動いているかと、空き容量を確かめる。

   ```bash
   systemd-detect-virt
   df -h /var
   sudo bootc status
   ```

   - 1 行目が `oracle`（VirtualBox）ならよい
   - `/var` の `Avail` が 10 GB 以上あればよい（手順 7 でベースのイメージをもう 1 つ取り込むため。この手順の補足）
   - `● Booted image:` が手順 1 の `BASE_IMAGE` と同じならよい。違えば手順 1 を直して貼り直す
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 空き容量の目安と、コンテナでの表示</summary>

   **空き容量の目安**（検証コンテナでの実測）:

   - ベースのイメージ（`atomic-desktop-gnome:10` = 10.2.20260924.1）は、podman の置き場所（`/var/lib/containers`）で 4.92 GB になる。取り込むのは 83 層・圧縮で約 2.2 GB
   - 派生イメージで増えるのは 151 MB。そのうち 98 MB は、ビルドの道具を入れて消したときに書き直される rpm のデータベース
   - ビルドの途中では、gcc・kernel-devel など 15 パッケージが一時的に入る
   - `bootc switch` は、動いているイメージと中身が同じファイルを共有して取り込む。ベースが新しくなっていれば、そのぶんが増える

   **`systemd-detect-virt`**: VirtualBox では `oracle` を返す（`systemd-detect-virt --list` にある名前）。検証コンテナでは `podman` を返した。

   **`bootc status`**: 起動した VM では `● Booted image: quay.io/almalinuxorg/atomic-desktop-gnome:10` の行と、`Digest:`・`Version:` の行が出る見込み（bootc 1.16.4 のソースの表示）。検証コンテナには起動したシステムが無いので、`booted: null` の YAML が出た。

   </details>

1. Secure Boot が有効かを見る。

   ```bash
   mokutil --sb-state
   ```

   - `SecureBoot enabled` のときだけ、手順 4 でモジュールの署名鍵を用意し、手順 10 で登録を確かめる
   - 以前に手順 4 を済ませている（`/var/lib/shim-signed/mok/MOK.der` がある）なら、手順 4 は飛ばす（鍵を作り直すと、登録済みの鍵と合わなくなる）
   - **`SecureBoot disabled`（または `EFI variables are not supported on this system`）なら、手順 4 と手順 10 は飛ばす**

   <details>
   <summary>補足: Secure Boot とモジュールの署名</summary>

   - EL10 のカーネルは `CONFIG_MODULE_SIG=y`・`CONFIG_LOCK_DOWN_IN_EFI_SECURE_BOOT=y`・`CONFIG_MODULE_SIG_HASH="sha512"`（kernel-devel の `.config` で確認）。Secure Boot のときは、署名の無いモジュールを読み込まない
   - VM で Secure Boot が有効になるのは、VM の設定の「システム」→「マザーボード」で EFI とセキュアブートを有効にしている場合
   - Guest Additions のインストーラは、Secure Boot なら自分でモジュールに署名する処理を持つ
     - ただし判定は `mokutil --sb-state` の答えだけで、ビルドの中（コンテナ）では `EFI variables are not supported on this system` になるので署名しない
     - そのため、手順 7 のビルドで鍵を渡して署名する

   </details>

1. Secure Boot が有効なときだけ、署名用の鍵を作り、MOK への登録を予約する。

   ```bash
   sudo mkdir -m 0700 -p /var/lib/shim-signed/mok
   sudo openssl req -nodes -new -x509 -newkey rsa:2048 -outform DER -addext "extendedKeyUsage=codeSigning" -subj "/CN=VirtualBox Guest Additions module signing key/" -days 36500 -keyout /var/lib/shim-signed/mok/MOK.priv -out /var/lib/shim-signed/mok/MOK.der
   sudo ls -l /var/lib/shim-signed/mok
   sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
   ```

   - 鍵を作る間は `.....+++` のような行が流れる
   - `MOK.priv`（秘密鍵。`-rw-------`）と `MOK.der`（公開鍵の証明書）ができる
   - 最後の `mokutil --import` で、公開鍵を UEFI の MOK に登録する予約をする
   - **一時パスワードを 2 回聞かれる**（手順 8 の再起動の途中で 1 回だけ使う。本書には残さない）
   - **次の手順は、一時パスワードに答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 鍵の置き場所と使われ方</summary>

   - 置き場所とファイル名は、ホスト側の [virtualbox.md 手順 15](virtualbox.md#実施手順) と同じ。Guest Additions の起動スクリプト（`vboxadd`）も、この 2 つを決め打ちで見る
   - bootc でも `/var` は再起動や `bootc switch` をまたいで残る（イメージから上書きされない）
   - 鍵はイメージに入れない。手順 7 のビルドに `--secret` で渡し、ビルドの中の `sign-file`（kernel-devel）がモジュールに署名する
   - 証明書は `CA:TRUE` と `Code Signing` を持つ（検証で `openssl x509` で確認）。カーネルがこの鍵をどのキーリングに入れるかは、virtualbox.md 手順 15 の補足を見る
   - **鍵を作り直したら**、手順 7 のビルドに `--no-cache` を足す（[更新](#更新)）
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
   set -euo pipefail
   kver=$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-core)
   mods=/usr/lib/modules/${kver}/misc

   # ビルドの道具（最後に消す）
   dnf -y --repo=baseos --repo=appstream install gcc make "kernel-devel-${kver}"

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

   dnf -y remove gcc make "kernel-devel-${kver}"
   dnf clean all
   rm -rf /var/lib/dnf /var/cache/dnf /var/cache/ldconfig /var/log/dnf.* /var/log/hawkey.log /var/log/vboxadd-*

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
   - 続けて、**VM のウィンドウのメニューの「デバイス」→「Guest Additions CD イメージの挿入...」を選ぶ**（VirtualBox のホスト側の操作。ホストの VirtualBox に同梱の ISO が、VM の光学ドライブに入る）
   - GNOME が CD の中のソフトウェアを自動で実行するかを尋ねたら、**「キャンセル」を選ぶ**（自動のインストールは `/usr`・`/opt` に書けずに失敗する）
   - **次の手順は、デスクトップに CD（`VBox_GAs_7.2.20` など）が現れてから貼る**

   <details>
   <summary>補足: Containerfile がしていること</summary>

   Guest Additions のインストーラ（`VBoxLinuxAdditions.run`）を、ベースのイメージの上でそのまま動かし、bootc では困るところを直してから、ビルドの道具を消す。

   **インストーラをそのまま動かすと、bootc では 4 か所が困る**（手を加えずに流した試作ビルドでの実測）:

   | 困るところ | そのままだと | 直し方 |
   |---|---|---|
   | systemd の unit | インストーラは `systemctl status` が通るとき（systemd が PID 1 のとき）だけ unit を作る。ビルドの中では `/etc/rc.d/init.d` に SysV のスクリプトを置き、`chkconfig` も無いので有効にならない（`systemctl is-enabled vboxadd` が `disabled`） | SysV のスクリプトを消し、同梱の `routines.sh` の `systemd_wrap_init_script`（インストーラが systemd のときに使う関数）で unit を作って `systemctl enable` |
   | `/var/lib/VBoxGuestAdditions/config` | bootc はイメージの `/var` を最初のインストールでしか展開しない。切り替えた VM には入らず、`vboxadd` が `Configuration file /var/lib/VBoxGuestAdditions/config not found` で止まる | `/usr/share/factory` へ移し、tmpfiles.d の `L+` で起動のたびにリンクを張る |
   | ユーザー `vboxadd`、グループ `vboxsf`・`vboxdrmipc` | ビルドの中の `useradd` / `groupadd` はイメージの `/etc/passwd` に書く。手元で変更済みの `/etc/passwd` は切り替えで上書きされないので、VM には入らない | `/usr/lib/sysusers.d` に書き、起動時に `systemd-sysusers` に作らせる |
   | モジュールのカーネルの版 | 既定では、ビルドしているシステム（`uname -r`）のカーネル向けにビルドする | 環境変数 `TARGET_VER` でイメージのカーネルを指定する |

   - `bootc container lint` は、直す前は `sysusers`・`var-log`・`var-tmpfiles` の 3 つを警告した。直した後は `Checks passed: 13`（ベースのイメージと同じ）になる
   - インストーラの終了コードは、ビルドの中では 0 にならない（最後にモジュールが読み込まれているかを見るため）。成否は、2 つのモジュールがあるかで判定している
   - インストーラが `/var` に残すログと dnf のキャッシュも消している（残すと `var-log`・`var-tmpfiles` の警告になる）

   **ビルドの道具は消す**:

   - `gcc`・`make`・`kernel-devel` と、一緒に入った 12 パッケージ（`kernel-headers`・`glibc-devel` など）が、`dnf remove` で全部消える。ベースのイメージとパッケージの一覧が同じになることを確かめた
   - `dnf history undo` にしなかったのは、道具を入れるときにベースのパッケージが上がっていた場合に、それを下げてしまうため
   - 道具が無いので、VM の上ではモジュールを作り直せない。カーネルが変わったら、イメージごとビルドし直す（[更新](#更新)）

   **そのまま残るもの**:

   - `/opt/VBoxGuestAdditions-7.2.20`（15 MB）。bootc のイメージでは `/opt` もイメージの一部で、読み取り専用
   - `/usr/bin` と `/usr/sbin` のリンク（`VBoxClient`・`VBoxControl`・`VBoxService`・`mount.vboxsf`・`rcvboxadd` など）、setuid の `VBoxDRMClient`
   - `/etc` のファイル: udev のルール（`60-vboxadd.rules`）、GNOME にログインしたときに `VBoxClient` を起動する `/etc/xdg/autostart/vboxclient.desktop`、`depmod.d`、`/etc/kernel/postinst.d/vboxadd`
   - SELinux: インストーラの `semanage fcontext` が、`mount.vboxsf` に `mount_exec_t` を割り当てる設定をイメージの `/etc/selinux` に書く
   - `vboxvideo.ko` もビルドされる（VirtualBox の画面を VMSVGA 以外にした場合のドライバ）
   - アンインストーラ（`/usr/sbin/vbox-uninstall-guest-additions`）も入るが、`/usr`・`/opt` に書けないので使えない。戻すときは[ロールバック](#ロールバック)

   </details>

1. CD からインストーラをコピーし、壊れていないかと版を確かめる。

   ```bash
   install -m 0644 /run/media/"${USER}"/VBox_GAs_*/VBoxLinuxAdditions.run ~/vbox-ga-image/
   sh ~/vbox-ga-image/VBoxLinuxAdditions.run --check
   sh ~/vbox-ga-image/VBoxLinuxAdditions.run --info | head -1
   ```

   - `MD5 checksums are OK. All good.` が出れば壊れていない（前の `does not contain an embedded SHA256 checksum.` は出てよい）
   - `Identification: VirtualBox 7.2.20 Guest Additions for Linux` の版が、ホストの VirtualBox（「ヘルプ」→「VirtualBox について」）と同じならよい
   - **7.2.8 より古いなら、先にホストの VirtualBox を上げる**（EL10.1・10.2 のカーネルへの対応が 7.2.8 で入った）
   - `install: cannot stat` なら、CD がマウントされていない。`udisksctl mount -b /dev/sr0` でマウントしてから貼り直す

   <details>
   <summary>補足: CD の中身と確かめ方</summary>

   - ホストが VM に入れる ISO は、Oracle の rpm に同梱の `/usr/share/virtualbox/VBoxGuestAdditions.iso`（[virtualbox.md の注意点](virtualbox.md#注意点)）
   - ISO のボリューム名（Joliet）は `VBox_GAs_7.2.20`。GNOME はこれを `/run/media/<USER>/VBox_GAs_7.2.20` にマウントする見込み（VM では未確認）
   - ISO には Rock Ridge が無く、中のファイルは読み取り専用になる
   - `install -m 0644` にしてあるのは、`cp` だと写しも読み取り専用のままで、[更新](#更新)で上書きできないため
     - 検証で再現した自動マウント（所有者だけが読める 0400）では、2 回目の `cp` が `Permission denied` で失敗し、`install -m 0644` は何度でも通った
   - `VBoxLinuxAdditions.run` は makeself 2.7.1 の自己展開アーカイブで、`--check` は中の MD5 を確かめる
   - Atomic Desktop のホームは `/var/home/<USER>`（イメージの `/etc/default/useradd` が `HOME=/var/home`。`/home` は `var/home` へのリンク）
   - 版の対応: VirtualBox 7.2 の変更履歴では、7.2.8 で「RHEL 10.1・10.2 のカーネルへの追加の対応」、7.2.18 で「RHEL 10.3 のカーネルへの対応」が入っている。検証では 7.2.20 と 7.2.18 が、どちらも EL10.2 のカーネル向けにビルドできた

   検証コンテナでの出力:

   ```
   Verifying archive integrity... /var/home/<USER>/vbox-ga-image/VBoxLinuxAdditions.run does not contain an embedded SHA256 checksum.
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
   - 途中の `unable to load vboxguest kernel module` と `installer exit=1` は、ビルドの中ではモジュールを読み込めないためで、失敗ではない
   - 最後に次が出ればよい
     - `vboxguest.ko:`・`vboxsf.ko:`・`vboxvideo.ko:` の 3 行（イメージのカーネルの版。Secure Boot なら `signer=VirtualBox Guest Additions module signing key`）
     - `enabled` が 2 行
     - `Checks passed: 13`（`Warnings:` の行が無い）と `Successfully tagged localhost/vbox-ga:latest`
   - `could not parse secrets: faccessat /var/lib/shim-signed/mok/MOK.priv: no such file or directory` ですぐに止まったら、Secure Boot なのに手順 4 が済んでいない
   - **次の手順は、`sudo` のパスワードに答え、`Successfully tagged` が出てから貼る**

   <details>
   <summary>補足: ビルドの表示と所要時間</summary>

   検証コンテナでの出力の終わり（Secure Boot のとき）:

   ```
   installer exit=1
   Created symlink '/etc/systemd/system/multi-user.target.wants/vboxadd.service' → '/usr/lib/systemd/system/vboxadd.service'.
   Created symlink '/etc/systemd/system/multi-user.target.wants/vboxadd-service.service' → '/usr/lib/systemd/system/vboxadd-service.service'.
   ...
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

   - **所要時間**: 代役のコンテナでは、ベースの取り込みからビルドの終わりまで 2 分 22 秒だった。ベースを取り込んだ後のビルドだけなら約 40 秒（道具の導入 19 秒、インストーラ 12 秒）
   - **署名**: 検証では、署名したモジュールから署名を取り出し、手順 4 と同じ作り方の証明書で `openssl dgst -sha512 -verify` を通して `Verified OK` になった（Guest Additions の起動スクリプトが署名を確かめるのと同じ方法）
   - **Secure Boot が無効なとき**は `MOK_SIGN=1` も `--secret` も渡らない。Containerfile の secret のマウントは、渡されなければ何もしない（`signer=` が空のまま成功することを確かめた）
   - **動いているカーネルとイメージのカーネルが違うとき**（まだ古いデプロイメントで動いている VM など）も、モジュールはイメージのカーネル向けにできる
     - 検証では、カーネルが `6.12.0-211.53.1.el10_2` の古いタグ（`10.2.20260916.0`）を、`6.12.0-211.56.1.el10_2` のカーネルの上でビルドした
     - `depmod: ERROR: could not open directory /lib/modules/<動いているカーネル>` と `depmod: FATAL` が 2 回ずつ出て、モジュールのビルドも 2 回走るが、最後の 3 行はイメージのカーネルの版になった
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
   - Secure Boot なら、起動の途中で青い **MokManager** の画面が出る。`Enroll MOK` → `Continue` → `Yes` → 手順 4 の一時パスワード → `Reboot` と進む
   - **MokManager で何もしないで進むと、鍵は登録されず、モジュールが読み込まれない**。そのときは手順 4 の最後の `sudo mokutil --import ...` を貼り直してから再起動する
   - **次の手順は、起動したらログインし、新しい端末を開いてから貼る**

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
   - **`bootc switch` そのもの、MokManager、モジュールの読み込みは VM でしか確かめられず、本書では未確認**（コンテナでは `bootc switch` が `Detected container; this command requires a booted host system.` で止まる）

   </details>

1. Guest Additions が動いているか確かめる。

   ```bash
   lsmod | grep -E '^vbox'
   systemctl is-active vboxadd vboxadd-service
   pgrep -a VBoxClient
   sudo bootc status
   ```

   - `vboxguest` と `vboxsf` の行、`active` が 2 行出ればよい
   - `pgrep` に `/usr/bin/VBoxClient --clipboard`・`--vmsvga-session` などが並べばよい（GNOME にログインしたときに自動で起動する）
   - `● Booted image: containers-storage:localhost/vbox-ga:latest` ならよい
   - VM のウィンドウのメニューの「デバイス」→「クリップボードの共有」→「双方向」にし、ホストとの間でコピー・貼り付けを試す
   - ウィンドウの大きさを変えると、画面の解像度が追従する（VM の設定のグラフィックコントローラが VMSVGA で、メニューの「表示」→「ゲスト画面の自動リサイズ」が有効な場合）
   - **この手順は VM でしか確かめられず、本書では未確認**
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 動かないとき</summary>

   | 出るもの | 意味 | 対処 |
   |---|---|---|
   | `lsmod` に何も出ず、`systemctl is-active vboxadd` が `failed` | モジュールを読み込めていない | `journalctl -b -u vboxadd` と `sudo dmesg \| grep -i vbox` を見る。Secure Boot なら手順 10 |
   | `Key was rejected by service`（`sudo dmesg`） | Secure Boot で署名が受け入れられない | 手順 10 で鍵が登録されているか見る。**この文は一般的なカーネルのエラーで、本書では出していない** |
   | `Configuration file /var/lib/VBoxGuestAdditions/config not found`（`journalctl -b -u vboxadd`） | 起動時のリンクが張られていない | `sudo systemd-tmpfiles --create --prefix=/var/lib/VBoxGuestAdditions` の後に `sudo systemctl restart vboxadd vboxadd-service` |
   | 通知に `VBoxClient: the VirtualBox kernel service is not running.  Exiting.` | ログインした時点で `/dev/vboxguest` が無かった | モジュールを直してから、ログインし直す |

   - `VBoxClient-all`（`/usr/bin/VBoxClient-all`）が起動するのは、`--clipboard`・`--seamless`・`--draganddrop`・`--checkhostversion`・`--vmsvga-session` の 5 つ。同梱のスクリプトのコメントによれば、Wayland では `--seamless` と `--draganddrop` は何もしない（GNOME は Wayland のセッション）
   - EL10 には Xorg サーバが無いので、インストーラは X.Org のドライバを入れない（`Could not find the X.Org or XFree86 Window System, skipping.`）。画面の大きさの追従は、カーネルの `vmwgfx`（VMSVGA）と `VBoxClient --vmsvga-session` が受け持つ
   - 本文の VirtualBox のメニューの名前は日本語の表示を想定したもので、VM では確かめていない

   </details>

1. Secure Boot が有効なときだけ、鍵が登録されたかとモジュールの署名を見る。

   ```bash
   sudo mokutil --test-key /var/lib/shim-signed/mok/MOK.der
   modinfo -F signer vboxguest
   ```

   - `/var/lib/shim-signed/mok/MOK.der is already enrolled` と `VirtualBox Guest Additions module signing key` が出ればよい
   - `is not enrolled` なら、手順 8 の MokManager で登録できていない（手順 8 の箇条書き）
   - **MokManager での登録から先は VM でしか確かめられず、本書では未確認**

---

## 共有フォルダーを使う（任意）

- ホストの VirtualBox で、VM の設定の「共有フォルダー」にフォルダーを足し、「自動マウント」にチェックを入れる（VM を動かしたままでも足せる）
- 自動マウントされたフォルダーは `/media/sf_<名前>` に現れる見込み。Atomic Desktop では `/media` が `/run/media` へのリンクになっている（イメージで確認）
- 読み書きできるのは `vboxsf` グループのユーザーだけ
- **この節は VM でしか確かめられず、本書では未確認**（`vboxsf` グループに入れるところまでは、コンテナで確かめた）

1. 自分を `vboxsf` グループに入れる。

   ```bash
   sudo usermod -aG vboxsf "${USER}"
   ```

   - `vboxsf` グループは、切り替えた後の最初の起動で `systemd-sysusers` が作っている
   - **効くのはログインし直してから**。ログアウトしてログインし直す
   - **次の手順は、ログインし直し、新しい端末を開いてから貼る**

1. グループと共有フォルダーを確かめる。

   ```bash
   id -nG | tr ' ' '\n' | grep -x vboxsf
   findmnt -t vboxsf
   ```

   - `vboxsf` の行と、共有フォルダーのマウントの行が出ればよい

---

## 更新

> [!WARNING]
> **切り替えた後は、`sudo bootc upgrade` だけでは OS（ベースのイメージ）が上がらない**。bootc が見に行くのは、この VM の中の `localhost/vbox-ga:latest` だけになる。OS を上げるときも、この節の手順 2・3 でビルドし直す。

- OS（ベースのイメージ）を上げる: この節の手順 2・3。カーネルが変わっても、同じ手順でモジュールが作り直される
- ホストの VirtualBox を上げた（Guest Additions の版が変わった）: この節の手順 1 から
- Secure Boot の鍵を作り直したときは、この節の手順 2 で `sudo podman build` に `--no-cache` を足す（ビルドのキャッシュは、渡した鍵の中身の違いを見分けない）
- 古いイメージは `sudo podman image prune` で消せる

1. ホストの VirtualBox を上げたときだけ、CD を入れ直して [手順 6](#実施手順) を貼る。

   - VM のウィンドウのメニューの「デバイス」→「Guest Additions CD イメージの挿入...」で、新しい版の CD を入れる
   - [手順 6](#実施手順) の `Identification:` が、ホストの新しい版になっていればよい

1. 手順 1 の変数を設定したシェルで、[手順 7](#実施手順) を貼り直す。

   - `--pull=newer` なので、ベースが新しくなっていれば取り込み直す
   - 何も変わっていなければ、ビルドのキャッシュが使われて同じイメージになる（`Using cache` が並ぶ）
   - **次の手順は、`Successfully tagged` が出てから貼る**

1. 新しいイメージを取り込んで、再起動する。

   ```bash
   sudo bootc upgrade --apply
   ```

   - イメージが変わっていれば、取り込んで再起動する。変わっていなければ再起動しない見込み（未確認）
   - 起動したら、[手順 9](#実施手順) で確かめる

---

## ロールバック

- 切り替えた直後なら、`sudo bootc rollback` の後に再起動しても元のイメージに戻る（未確認。更新を重ねた後は、1 つ前の派生イメージに戻るだけ）
- この節の手順では消えないもの:
  - **Secure Boot の MOK**（手順 4 を行った場合）: 次の順で消す
    - `sudo mokutil --delete /var/lib/shim-signed/mok/MOK.der`（一時パスワードを 2 回）→ 再起動 → MokManager で `Delete MOK` → パスワード → `Reboot`
    - そのあと `sudo rm -rf /var/lib/shim-signed`
    - **MOK の削除は本書では試していない**
- この節の手順 1 はコンテナでは試せなかった（`bootc switch` が動かない）。手順 2・3 は検証コンテナで流した

1. 元のイメージに切り替えて、再起動する。

   ```bash
   sudo bootc switch --apply --enforce-container-sigpolicy "${BASE_IMAGE:?手順 1 の BASE_IMAGE が空のまま。値を入れて貼り直す}"
   ```

   - 元のイメージをレジストリから取り込み、署名を確かめてから再起動する
   - **次の手順は、起動したらログインし、新しい端末で手順 1 を貼ってから貼る**

   <details>
   <summary>補足: <code>--enforce-container-sigpolicy</code> を付ける理由</summary>

   - Atomic Desktop の ISO は、インストールの最後に、署名の検査付きでこのイメージを追うように設定する（AlmaLinux の atomic-ci の ISO のビルドが、署名付きのイメージにこのオプションを渡している）
   - 付けないと、元のイメージを署名の検査無しで追うことになる
   - イメージの `/etc/containers/policy.json` は、`quay.io/almalinuxorg/atomic-desktop-gnome` に sigstore の署名（`/etc/pki/containers/atomic-desktop-gnome.pub`）を求めている（イメージで確認）

   </details>

1. ビルド用のディレクトリと、podman に取り込んだイメージを消す。

   ```bash
   rm -rf ~/vbox-ga-image
   sudo podman rmi localhost/vbox-ga:latest "${BASE_IMAGE:?手順 1 の BASE_IMAGE が空のまま。値を入れて貼り直す}"
   ```

   - `Untagged:` と `Deleted:` の行が並ぶ
   - bootc は自分の置き場所にイメージを持っているので、podman のイメージを消しても起動には影響しない
   - ビルドの最初の段（`<none>`、6.43 MB）が残る。`sudo podman image prune` で消せる
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. Guest Additions のユーザー・グループ・リンク・ログを消す。

   ```bash
   sudo userdel vboxadd
   sudo groupdel vboxsf
   sudo groupdel vboxdrmipc
   sudo rm -f /var/lib/VBoxGuestAdditions /var/log/vboxadd-setup.log*
   ```

   - 何も出ずに終われば消えている

   <details>
   <summary>補足: これらが自然には消えない理由</summary>

   - ユーザーとグループは、`systemd-sysusers` が手元の `/etc/passwd`・`/etc/group` に書いたもの。元のイメージに戻しても、手元で変更済みのファイルは 3-way マージで残る
   - `/var` は、イメージを切り替えても戻らない
   - 一方、イメージが足した `/etc` のファイル（udev のルール、`vboxclient.desktop`、unit を有効にするリンク）は、手元で変えていなければ、元のイメージに戻したときに消える（ostree の `/etc` のマージの仕組み。本書では未確認）

   </details>

---

## 補足

### 対象と検証環境

- **目的**: VirtualBox の VM で動く AlmaLinux Atomic Desktop（GNOME。AlmaLinux 10.2 の bootc のイメージ）に Guest Additions を入れる
  - 使えるようにするもの: クリップボードの共有、画面サイズの自動変更、共有フォルダー、時刻の同期（VBoxService）
- **進め方**: dnf では入れられないので、Guest Additions を焼き込んだ派生イメージを VM の上でビルドし、`bootc switch` で切り替える
  - bootc の公式文書の「Booting local builds」と同じ形
  - 読者が変える値は無い（`BASE_IMAGE` は、GNOME 以外の Atomic Desktop のときだけ変える）
- **状態**: **x86_64 のコンテナでのみ検証済み（2026-09-28）。VirtualBox の VM では実行していない**
  - 下表の検証環境で、**この文書のコードブロックを上から順にそのまま貼った**（[付録](#付録-コンテナでの検証記録2026-09-28)）
    - 手順 1〜8、[更新](#更新)の手順 2・3、[ロールバック](#ロールバック)の手順 1・2: VM の代役のコンテナ（Atomic Desktop のイメージそのもの）で。手順 8、[更新](#更新)の手順 3、[ロールバック](#ロールバック)の手順 1 は、`bootc` が `Detected container` で止まる
    - 手順 9・10、[共有フォルダーを使う（任意）](#共有フォルダーを使う任意)、[ロールバック](#ロールバック)の手順 3: 手順 7 で作ったイメージを systemd で起動したコンテナ（切り替えた後の最初の起動を模したもの）で
  - 確認したこと:
    - ベースのイメージの署名を確かめて取り込めること（`policy.json` の sigstore）
    - `VBoxLinuxAdditions.run` 7.2.20 が、EL10 のカーネル（`6.12.0-211.56.1.el10_2`）向けにモジュールを 3 つビルドすること
    - 手順 4 と同じ作り方の鍵で署名したモジュールの署名が、`openssl dgst -sha512 -verify` で `Verified OK` になること
    - インストーラをそのまま流すと、bootc では unit・`/var` の設定・ユーザーとグループの 3 か所が困ること（カーネルの版を合わせる 1 か所と合わせて、本文の Containerfile が直している）と、直した後の `bootc container lint` が警告無しになること
    - 切り替えた後の最初の起動を模したときに、ユーザーとグループの作成、設定へのリンク、2 つの unit の起動（モジュールの読み込みの手前まで）が起きること
    - 動いているカーネルとイメージのカーネルが違っても、イメージのカーネル向けにビルドされること
    - ビルドのキャッシュ（鍵を作り直しただけではやり直さないこと）と、`install -m 0644` にした理由（`cp` の上書きの失敗）
  - **確認していないこと**: `bootc switch`・`bootc upgrade`・`bootc rollback`、再起動、MokManager での鍵の登録と削除、モジュールの読み込み、`/dev/vboxguest`、VBoxService、VBoxClient（クリップボード・画面サイズ）、共有フォルダーの自動マウント、SELinux のラベル（コンテナではできない）
  - 実機（検証に使った PC）の設定は変えていない。`sudo` は使わず、rootless の podman のコンテナだけで行った

| 項目 | VirtualBox の VM（対象） | 検証環境 |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-28 |
| ホスト | VirtualBox 7.2.8 以上（Guest Additions の CD はホストのもの） | VirtualBox は無し。Guest Additions は公式サイトの `VBoxGuestAdditions_7.2.20.iso`（`SHA256SUMS` で照合） |
| ゲストの OS | AlmaLinux Atomic Desktop GNOME（`quay.io/almalinuxorg/atomic-desktop-gnome:10`） | 同じイメージ（10.2.20260924.1、`sha256:7be643fe…dcff`）を podman のコンテナとして起動した代役 |
| カーネル | イメージの `6.12.0-211.56.1.el10_2.x86_64` | 実機（AlmaLinux 10.2 / x86_64 のノート PC）の `6.12.0-211.56.1.el10_2` を共有 |
| bootc / podman | 1.16.4 / 5.8.2（イメージ） | 同左（代役の中の podman で入れ子にビルド） |
| Secure Boot | 任意 | `mokutil` のスタブで両方の分岐を通した（本物はコンテナで `EFI variables are not supported on this system`） |
| SELinux | Enforcing（見込み） | 実機は Enforcing。代役のコンテナは `--privileged` |

> [!NOTE]
> 出力例の値は `<USER>` / `<UID>` / `<GID>` などのプレースホルダで書いてある。版（Guest Additions の `7.2.20`、イメージの `10.2.20260924.1`、カーネルの `6.12.0-211.56.1.el10_2`）は実行日によって変わる。MOK の秘密鍵と一時パスワードは載せない。

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

**手順 7 で作ったイメージの中身**（Secure Boot のとき。代役のコンテナで作ったイメージを、実機の rootless の podman に読み込んで見た。VM では `podman` に `sudo` を付ける）:

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
- unit は 2 つ
  - `vboxadd.service`: `ExecStart=/opt/VBoxGuestAdditions-7.2.20/init/vboxadd start`、`Type=oneshot`、`Before=` に `display-manager.service`
  - `vboxadd-service.service`: `Type=forking`、`After=vboxadd.service`
- `/usr/bin/VBoxClient`・`/usr/sbin/VBoxService`・`/usr/sbin/rcvboxadd` は `/opt/VBoxGuestAdditions-7.2.20/` へのリンク。`VBoxDRMClient` は setuid（`-rwsr-xr-x`）
- udev のルールは `KERNEL=="vboxguest", OWNER="vboxadd", MODE="0660"` と `KERNEL=="vboxuser", OWNER="vboxadd", MODE="0666"`
- `/etc/selinux/targeted/contexts/files/file_contexts.local` に `mount.vboxsf` の `mount_exec_t` が入り、`matchpathcon` もそう答える

### 注意点

- **dnf でも `.run` でも入らない**: bootc の `/usr`・`/opt` は読み取り専用。派生イメージに焼き込む（[手順 5〜8](#実施手順)）
- **Guest Additions のインストーラは、bootc 向けに 4 か所を直して使う**: unit・`/var` の設定・ユーザーとグループ・カーネルの版（[手順 5](#実施手順) の補足）
- **切り替えた後は、OS の更新もビルドし直しになる**: `bootc upgrade` はこの VM の中のイメージしか見ない（[更新](#更新)）
- **カーネルが変わったら、VM の上ではモジュールを作り直せない**: ビルドの道具をイメージから消しているため。イメージごとビルドし直す
- **Secure Boot では鍵の登録が要る**: MokManager の画面を逃すと登録されない。鍵を作り直したら `--no-cache` でビルドし直す（[手順 4・8](#実施手順)）
- **CD の自動実行は取り消す**: 自動のインストールは bootc では失敗する（[手順 5](#実施手順)）
- **アンインストーラは使えない**: 戻すときはイメージを切り替える（[ロールバック](#ロールバック)）
- **ホスト側の手順書は別**: VirtualBox 本体は [virtualbox.md](virtualbox.md)。ホスト側でモジュールを署名する鍵（同じ `/var/lib/shim-signed/mok/` の置き場所）は、ホストの PC のもので、VM の鍵とは別物

### 参照

- [bootc — Booting local builds](https://bootc-dev.github.io/bootc/booting-local-builds.html) — `podman build` と `bootc switch --transport containers-storage`
- [bootc — Filesystem](https://bootc-dev.github.io/bootc/filesystem.html) — `/var` の中身は最初のインストールでしか展開されない（Docker の `VOLUME` と同じ）、`/opt` は読み取り専用
- [bootc — Users and groups](https://bootc-dev.github.io/bootc/building/users-and-groups.html) — `/etc/passwd` の 3-way マージと `systemd-sysusers`
- [bootc-switch(8)](https://bootc-dev.github.io/bootc/man/bootc-switch.8.html) / [bootc-upgrade(8)](https://bootc-dev.github.io/bootc/man/bootc-upgrade.8.html) — `--apply`・`--transport`・`--enforce-container-sigpolicy`
- [AlmaLinux Atomic Desktop](https://github.com/AlmaLinux/atomic-desktop) — ベースのイメージの作り方（`/opt`・`/usr/local`・`policy.json`・`bootc-fetch-apply-updates` のドロップイン）
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

**VM の代役のコンテナ**（手順 1〜8 と、[更新](#更新)・[ロールバック](#ロールバック)の手順 1・2）:

- ベースのイメージそのものを `--privileged` で起動し、中に uid 1000 のユーザー（NOPASSWD の sudo）を作った
- 中の podman（rootful）は、実機の一時ディレクトリを `/var/lib/containers` にマウントし、入れ子で動くように `containers.conf` を足した（`netns="host"`・`cgroups="disabled"`・`cgroup_manager="cgroupfs"` など）
- CD: ISO の中身を `/run/media/<USER>/VBox_GAs_7.2.20` に読み取り専用でマウントした（ディレクトリ 0500、ファイル 0400、所有者はそのユーザー）
- `mokutil` はスタブにした（本物はコンテナでは `EFI variables are not supported on this system`）

| スタブ | 返すもの |
|---|---|
| `mokutil --sb-state` | `SecureBoot enabled` |
| `mokutil --import` | 一時パスワードを 2 回読み、登録の予約の印を置く |
| `mokutil --test-key` | 登録済みの印があれば `is already enrolled`（MokManager での登録は、印を置いて模した） |

**起動を模したコンテナ**（手順 9・10、[共有フォルダーを使う（任意）](#共有フォルダーを使う任意)、[ロールバック](#ロールバック)の手順 3）:

- 手順 7 で代役のコンテナの中に作ったイメージを、`podman save` / `podman load` で実機の podman に移した
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
| 6. CD | `MD5 checksums are OK. All good.`、`Identification: VirtualBox 7.2.20 Guest Additions for Linux` |
| 7. ビルド | ベースの取り込み（署名の検査あり）からビルドの終わりまで 2 分 22 秒。3 つのモジュールが `signer=VirtualBox Guest Additions module signing key`、`enabled` が 2 行、`Checks passed: 13`、`Successfully tagged localhost/vbox-ga:latest` |
| 8. 切り替え | `error: Switching: Initializing storage: Preparing for write: Detected container; this command requires a booted host system.` |
| 9. 確認（起動を模したコンテナ） | `lsmod` は空、`systemctl is-active` は `failed` が 2 行（コンテナではモジュールを読み込めない）、`pgrep` は空（画面が無い）、`bootc status` は YAML |
| 10. 署名（同上） | `is already enrolled`（スタブ）と `VirtualBox Guest Additions module signing key`（本物の `modinfo`） |
| 共有フォルダー 1・2（同上） | `usermod -aG vboxsf` が通り、`id -nG` に `vboxsf`。`findmnt -t vboxsf` は空 |
| 更新 2 | 手順 7 を貼り直すと、`Using cache` が 4 行で同じイメージ ID。ベースは取り込み直さなかった |
| 更新 3・ロールバック 1 | 手順 8 と同じ `Detected container` |
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
