# VirtualBox Guest Additions 導入手順（AlmaLinux 10 bootc / Atomic Desktop のゲスト）

## 実施手順

- [検証記録](verification/virtualbox-guest-bootc.md)・[参考資料](reference/virtualbox-guest-bootc.md)・[ロールバックと注意点](extra/virtualbox-guest-bootc.md)

> [!IMPORTANT]
> - **VirtualBox の VM の中の AlmaLinux Atomic Desktop（GNOME）にログインし、端末を開いて自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない
> - **前提（Secure Boot が有効な VM）**: [secure-boot-mok.md](secure-boot-mok.md) で、この VM の署名鍵を MOK に登録してあること（同書で再起動し、起動の途中の MokManager の画面を VM のウィンドウで操作する。最初の画面は 10 秒で消える）。`mokutil --sb-state` が `SecureBoot enabled` を返し、`sudo mokutil --test-key /var/lib/shim-signed/mok/MOK.der` が `is already enrolled` を返さなければ、先に通す（ホストオンリーアダプターだけの VM では、同書の手順 3 まで。鍵はその節の手順 3・4 でホストで作り、同書の手順 5〜7 で登録する）
> - **dnf では入れない**。Guest Additions を焼き込んだ派生イメージをこの VM でビルドし、`bootc switch` で切り替える（手順 3〜7）
> - **手順 4 と手順 9 は、VM のウィンドウで行う**（手順 4 の CD の挿入は、ホスト側の操作）
> - **手順 7 で再起動する**。手順 6 はビルドが終わるのを待ってから次を貼る
> - **VM がホストオンリーアダプターだけで、インターネットに出られないときは、手順 6 の代わりに[ホストオンリーアダプターだけの VM でビルドする（任意）](#ホストオンリーアダプターだけの-vm-でビルドする任意)を行う**（ホストでビルドし、イメージを ssh で VM に運ぶ。Secure Boot の鍵も、その節でホストで作る）

- 手順 1 の変数を設定したシェルで、上から順にコードブロックを貼る。新しい端末を開いたら手順 1 を貼り直す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 手順の後: 共有フォルダーは[共有フォルダーを使う（任意）](#共有フォルダーを使う任意)、OS やホストの VirtualBox を上げたときは[更新](#更新)、戻すときは[ロールバック](extra/virtualbox-guest-bootc.md#ロールバック)
- **切り替えた後は、`sudo bootc upgrade` だけでは OS が上がらない**（[更新](#更新)の手順でビルドし直す）
- ホストは AlmaLinux 10 でも Windows 11 でもよい
- 自作の kernel-rt のイメージでも、手順 1 の `BASE_IMAGE` を変えるだけで同じ手順になる（イメージで `rt` のリポジトリを有効にしておく）
- `vboxguest` を読み込んだ直後にカーネルの `WARNING` が出ることがある。手順 7・8 の起動状態とログを確認する
  - 起動が止まった場合は、手順 7 の注意と[参考資料](reference/virtualbox-guest-bootc.md)を確認する
- VirtualBox のメニューの名前は、日本語の表示と英語の表示を並べて書いてある

> [!WARNING]
> **Windows のホストで Hyper-V が動いていると（WSL 2 を使っている PC など）、手順 6 の途中で VM が 1〜7 分ずつ止まることがある**。VirtualBox が Hyper-V の上で VM を動かす形になるため（VM のウィンドウの状態バーの「機能」のアイコンの説明に「実行エンジン: native API」と出る）。出力が止まったら、VM のウィンドウで Shift キーを押すと動き出す。止まっている間に systemd の watchdog が `systemd-logind` などを止め、GNOME がログイン画面に戻ることもある（[注意点](extra/virtualbox-guest-bootc.md#注意点)）。

1. 変数を設定する（既定のままでよい）。

   ```bash
   BASE_IMAGE=quay.io/almalinuxorg/atomic-desktop-gnome:latest   # 元のイメージ（手順 2 の Booted image）
   echo "BASE_IMAGE = ${BASE_IMAGE}"
   ```

   - 公式の ISO で入れた Atomic Desktop の GNOME なら、このままでよい（ISO は `:latest` を追う。この手順の補足）
   - 自作の kernel-rt のイメージ（レジストリにあるもの）なら、手順 2 の `Booted image:` に合わせて、そのイメージの名前にする
     - 手順 3 の Containerfile がカーネルを見分けて、`kernel-rt-devel` でビルドする
     - `kernel-rt-devel` は `rt` のリポジトリにしか無いので、そのイメージで `rt` を有効にしておく（参考資料を参照）
   - 手順 6、[更新](#更新)、[ロールバック](extra/virtualbox-guest-bootc.md#ロールバック)で使う

1. VirtualBox の VM で bootc のシステムが動いているかと、空き容量を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   systemd-detect-virt
   df -h /var
   sudo bootc status
   ```

   - 1 行目が `oracle`（VirtualBox）ならよい
   - `/var` の `Avail` が 10 GB 以上あればよい
   - `● Booted image:` が手順 1 の `BASE_IMAGE` と同じならよい。違えば手順 1 を直して貼り直す

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
   printf '\n\033[7m 確認 \033[0m\n'
   ls -l ~/vbox-ga-image
   ```

   - ヒアドキュメントは `<<'EOF'`（クォート付き）。`${...}` はシェルではなく、ビルドの中で展開される
   - `Containerfile` の 1 行が出ればよい

1. VM のウィンドウのメニューで、Guest Additions の CD を入れる。

   - 「デバイス」→「Guest Additions CD イメージを挿入」を選ぶ（英語の表示では Devices → Insert Guest Additions CD image...）
   - CD は自動でマウントされるが、GNOME の画面には何も出ない（自動実行の確認も、デスクトップのアイコンも出ない。手順 3 の補足）
   - 「仮想光学ディスク … をマシン … に挿入できません。」と出たら、インストールに使った ISO がまだ入っている。VM の端末で `eject /dev/sr0` を実行してから、もう一度選ぶ
   - **次の手順は、CD を入れて 10 秒ほどたってから貼る**

1. CD からインストーラをコピーし、壊れていないかと版を確かめる。

   ```bash
   install -m 0644 /run/media/"${USER}"/VBox_GAs_*/VBoxLinuxAdditions.run ~/vbox-ga-image/
   printf '\n\033[7m 確認 \033[0m\n'
   sh ~/vbox-ga-image/VBoxLinuxAdditions.run --check
   sh ~/vbox-ga-image/VBoxLinuxAdditions.run --info | head -1
   ```

   - `MD5 checksums are OK. All good.` が出れば壊れていない（前の `does not contain an embedded SHA256 checksum.` は出てよい）
   - `Identification: VirtualBox 7.2.20 Guest Additions for Linux` の版が、ホストの VirtualBox（「ヘルプ」→「VirtualBox について」。英語の表示では Help → About VirtualBox...）と同じならよい
   - **7.2.8 より古いなら、先にホストの VirtualBox を上げる**
   - `install: cannot stat` なら、CD がマウントされていない。`udisksctl mount -b /dev/sr0` でマウントしてから貼り直す

1. 派生イメージをビルドする。

   ```bash
   build_args=(--pull=newer)
   if mokutil --sb-state 2>/dev/null | grep -q 'SecureBoot enabled'; then
     build_args+=(--build-arg MOK_SIGN=1 --secret id=mok_priv,src=/var/lib/shim-signed/mok/MOK.priv --secret id=mok_der,src=/var/lib/shim-signed/mok/MOK.der)
   fi
   printf '\n\033[7m 確認 \033[0m\n'
   sudo podman build "${build_args[@]}" --build-arg "BASE_IMAGE=${BASE_IMAGE:?手順 1 の BASE_IMAGE が空のまま。値を入れて貼り直す}" -t localhost/vbox-ga:latest ~/vbox-ga-image
   ```

   - 初回はベースのイメージ（圧縮で約 2.2 GB）を取り込む。Atomic Desktop の `/etc/containers/policy.json` に従って、イメージの署名が確かめられる
     - 自作の kernel-rt のイメージなど、`policy.json` に載っていないレジストリのイメージは、既定（`insecureAcceptAnything`）のとおり署名を確かめずに取り込む
   - 途中の `unable to load vboxguest kernel module` と `installer exit=1` は、失敗ではない
     - Guest Additions が動いている VM でビルドし直すと（[更新](#更新)）、代わりに `mknod: /dev/vboxguest: Operation not permitted` と `installer exit=2` になる。これも失敗ではない
       - カーネルも新しくなったとき（ベースの更新）は、`mknod` の行が出て `installer exit=1` になる
   - 最後に次が出ればよい
     - `vboxguest.ko:`・`vboxsf.ko:`・`vboxvideo.ko:` の 3 行（イメージのカーネルの版。Secure Boot なら、[secure-boot-mok.md](secure-boot-mok.md) の鍵の `signer=Local kernel module signing key`）
     - kernel-rt のイメージなら、版の末尾が `+rt` で、`SMP preempt_rt` になる
     - `enabled` が 2 行
     - `Checks passed: 13`（`Warnings:` の行が無い）と `Successfully tagged localhost/vbox-ga:latest`
   - `could not parse secrets: faccessat /var/lib/shim-signed/mok/MOK.priv: no such file or directory` ですぐに止まったら、Secure Boot なのに、前提の [secure-boot-mok.md](secure-boot-mok.md) で鍵を作っていない
   - `No match for argument: kernel-devel-uname-r = …+rt` で止まったら、kernel-rt のイメージで `rt` のリポジトリが有効になっていない
   - `pinging container registry quay.io` と `dial tcp: lookup quay.io` で止まったら、VM がインターネットに出られない（ホストオンリーアダプターだけの VM など）。[ホストオンリーアダプターだけの VM でビルドする（任意）](#ホストオンリーアダプターだけの-vm-でビルドする任意)の手順でビルドする
   - **注意**: Windows のホストで Hyper-V が動いていると、途中で出力が数分止まることがある。VM のウィンドウで Shift キーを押すと動き出す（リードの WARNING）
   - **次の手順は、`Successfully tagged` が出てから貼る**

1. 作ったイメージに切り替えて、再起動する。

   ```bash
   sudo bootc switch --apply --transport containers-storage localhost/vbox-ga:latest
   ```

   - イメージを取り込んだあと、そのまま再起動する（`--apply`）
   - **注意**: 起動がロゴの画面のまま数分進まないときは、VM のウィンドウのメニューの「仮想マシン」→「リセット」で起動し直す（英語の表示では Machine → Reset。手順 8 の補足）
   - **次の手順は、起動したらログインし、新しい端末を開いてから貼る**

1. Guest Additions が動いているか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   lsmod | grep -E '^vbox'
   systemctl is-active vboxadd vboxadd-service
   pgrep -a VBoxClient
   sudo bootc status
   ```

   - `vboxguest` の行と、`active` が 2 行出ればよい（`vboxsf` は、共有フォルダーを足すまで読み込まれない）
   - `pgrep` に `/usr/bin/VBoxClient --clipboard`・`--vmsvga-session` などが並べばよい（GNOME にログインしたときに自動で起動する）
   - `● Booted image: containers-storage:localhost/vbox-ga:latest` ならよい

1. VM のウィンドウで、クリップボードの共有と画面の大きさの追従を試す。

   - メニューの「デバイス」→「クリップボードの共有」→「双方向」にし、ホストとの間でコピー・貼り付けを試す（英語の表示では Devices → Shared Clipboard → Bidirectional）
   - ウィンドウの大きさを変えると、画面の解像度が追従する
     - VM の設定のグラフィックコントローラが VMSVGA で、メニューの「表示」→「ゲストOSの画面を自動リサイズ」が有効な場合（英語の表示では View → Auto-resize Guest Display）

1. Secure Boot が有効なときだけ、モジュールの署名を見る。

   ```bash
   modinfo -F signer vboxguest
   ```

   - モジュールが読み込まれていないときは、secure-boot-mok.md の手順 7 で鍵が登録されているか見る（手順 8 の補足の表）

---

## ホストオンリーアダプターだけの VM でビルドする（任意）

- VM のネットワークが VirtualBox のホストオンリーアダプターだけで、VM からインターネットに出られないときに、[手順 6](#実施手順) の代わりに行う（Secure Boot なら、[secure-boot-mok.md 手順 4](secure-boot-mok.md#実施手順) も、この節の手順 3・4 で代える）。手順 1〜5 と、手順 7 から後はそのまま
  - そのままの手順 6 は、ベースのイメージを取り込めずに `pinging container registry quay.io: Get "https://quay.io/v2/": dial tcp: lookup quay.io …` で止まる
- ホスト（VirtualBox を動かしている PC）で派生イメージをビルドし、1 つのファイルにして ssh で VM に運ぶ。VM はインターネットに出ない
  - ビルドの材料（手順 3 の Containerfile と、手順 5 でコピーしたインストーラ）は、VM から写して使う
- ホストは、インターネットに出られ、x86_64 の AlmaLinux 10 の rootless の podman が動くこと（[podman.md](podman.md) の手順 1〜6）
  - Windows のホストでは、WSL の AlmaLinux 10 の端末で行う（WSL の既定のネットワーク〔NAT〕のままで、ホストオンリーのネットワークの VM に届いた。WSL をミラーにした PC〔[Windows 11 の初期設定の任意節](windows-setup.md#wsl-のネットワークをミラーにする任意)〕で届くかは確かめていない）
- 手順 6 と違うところ:
  - ベースのイメージはホストが取り込む。署名は、VM の `policy.json` と公開鍵を写して、ホストで同じように確かめる（この節の手順 6）
  - Secure Boot の鍵はホストで作り、秘密鍵はホストに置く。VM には証明書だけを置く（この節の手順 3・4。登録は secure-boot-mok.md の手順 5〜7）
  - OS を上げるたびに、ベースを含むイメージの全体（`podman save` のファイルで約 4.8G）を VM に運ぶ
- この節の手順 1・4・9・10 は VM の端末（先に[手順 1](#実施手順) を貼っておく）、手順 2・3・5〜8・11 はホストの端末に貼る
- ホストオンリーアダプターだけの VM で OS を上げるときは、[更新](#更新)の手順 2 の代わりに、この節の手順 5・7〜9。元のイメージに戻すときは、この節の手順 10・11

1. VM の端末で、ホストオンリーアダプターの IP を見る。

   ```bash
   ip -4 -br addr show scope global
   ```

   - `enp0s3  UP  192.168.56.101/24` のような行の IP（`/24` の前）が、この節の手順 2 で使う `<VM_IP>`
   - 何も出ないときは、有線の接続が上がっていない。`nmcli -t -f NAME,DEVICE connection show` で接続の名前を見て、`sudo nmcli connection up <名前>` で上げる
     - ISO のインストーラでネットワークを有効にしなかった VM は、起動しても自動では上がらない（[実施前の状態](verification/virtualbox-guest-bootc.md#実施前の状態)）。`sudo nmcli connection modify <名前> connection.autoconnect yes` で自動にする

1. ホストの端末で、変数を設定する（`VM_SSH` は必ず値を入れる）。

   ```bash
   VM_SSH=   # ← VM のユーザー名と、この節の手順 1 の IP（<USER>@<VM_IP>）
   echo "VM_SSH = ${VM_SSH}"
   ```

   - 同じ端末に、[手順 1](#実施手順) も貼る（この節の手順 7・8・11 で `BASE_IMAGE` を使う）
   - 新しい端末を開いたら、[手順 1](#実施手順) とこの手順を貼り直す
   - Windows のホストでは、WSL の AlmaLinux 10 の端末を開いて貼る

1. Secure Boot が有効なときだけ、ホストの端末で署名用の鍵を作り、証明書を VM に送る。

   ```bash
   if [ -z "${VM_SSH}" ]; then
     echo 'VM_SSH が空のまま。この節の手順 2 を貼り直す' >&2
   else
     rpm -q openssl >/dev/null || sudo dnf install -y openssl
     if [ ! -e ~/vbox-ga-mok/MOK.priv ]; then
       mkdir -m 0700 -p ~/vbox-ga-mok
       openssl req -nodes -new -x509 -newkey rsa:2048 -outform DER -addext "extendedKeyUsage=codeSigning" -subj "/CN=Local kernel module signing key/" -days 36500 -keyout ~/vbox-ga-mok/MOK.priv -out ~/vbox-ga-mok/MOK.der
     fi
     printf '\n\033[7m 確認 \033[0m\n'
     ls -l ~/vbox-ga-mok
     scp ~/vbox-ga-mok/MOK.der "${VM_SSH}:"
   fi
   ```

   - Secure Boot が有効かは、VM で [secure-boot-mok.md 手順 3](secure-boot-mok.md#実施手順) の `mokutil --sb-state` で見たもの
   - `MOK.priv`（秘密鍵。`-rw-------`）と `MOK.der`（公開鍵の証明書）が並び、`scp` が `MOK.der` を VM のホームに送る
   - **秘密鍵 `MOK.priv` はホストのほかのユーザーに読ませず、ほかのマシンに持ち出さない**。VM へ送るのは証明書 `MOK.der` だけ
   - 初めてつなぐときはホスト鍵を聞かれるので `yes`、続けて VM のユーザーのパスワードを入れる
   - **次の手順は、パスワードに答え、`MOK.der` の転送が終わってから、VM の端末で貼る**

1. Secure Boot が有効なときだけ、VM の端末で証明書を置き、MOK への登録を予約する。

   ```bash
   {
     sudo install -d -m 0700 /var/lib/shim-signed/mok
     sudo install -m 0644 ~/MOK.der /var/lib/shim-signed/mok/MOK.der
     rm ~/MOK.der
     printf '\n\033[7m 確認 \033[0m\n'
     sudo ls -l /var/lib/shim-signed/mok
     sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
   }
   ```

   - `MOK.der` だけが並ぶ（秘密鍵は VM に置かない）
   - 置き場所は [secure-boot-mok.md 手順 4](secure-boot-mok.md#実施手順) と同じなので、同書の手順 7 と[ロールバック](extra/secure-boot-mok.md#ロールバック)はそのまま使える
   - `MOK.priv` も並ぶなら、[secure-boot-mok.md 手順 4](secure-boot-mok.md#実施手順) で VM に作った鍵が残っている。この節ではホストの鍵で署名するので、使われない
   - **一時パスワードを 2 回聞かれる**（secure-boot-mok.md の手順 6 の MokManager で 1 回だけ使う。本書には残さない）
   - 続けて、VM で [secure-boot-mok.md 手順 5〜7](secure-boot-mok.md#実施手順) を行い、再起動して MokManager で登録し、`--test-key` で確かめる。ホストの端末は、開いたままにしておく
   - 同書の手順 7 の後、この節の手順 5 はホストの端末で貼る（VM の端末を開き直したら、[手順 1](#実施手順) を貼り直す）
   - **次の手順（secure-boot-mok.md 手順 5）は、一時パスワードに答えてから貼る**（続けて貼ると答えとして食われる）

1. ホストの端末で、ビルドの材料と、署名を確かめる設定を VM から写す。

   ```bash
   if [ -z "${VM_SSH}" ]; then
     echo 'VM_SSH が空のまま。この節の手順 2 を貼り直す' >&2
   else
     mkdir -p ~/vbox-ga-host
     printf '\n\033[7m 確認 \033[0m\n'
     ssh "${VM_SSH}" 'tar -cf - vbox-ga-image -C / etc/containers/policy.json etc/containers/registries.d etc/pki/containers' | tar -xvf - -C ~/vbox-ga-host
   fi
   ```

   - VM のユーザーのパスワードを聞かれる
   - `vbox-ga-image/Containerfile`・`vbox-ga-image/VBoxLinuxAdditions.run`・`etc/containers/policy.json` などの名前が並べばよい
   - `tar: … time stamp … is … s in the future` が混ざることがある。害は無い（参考資料を参照）
   - **次の手順は、パスワードに答え、名前が並んでから貼る**

1. ホストの端末で、ベースのイメージの署名を VM と同じ鍵で確かめるようにする。

   ```bash
   if [ -e ~/.config/containers/policy.json ] || [ -L ~/.config/containers/policy.json ] ||
      [ -e ~/.config/containers/registries.d ] || [ -L ~/.config/containers/registries.d ] ||
      [ -e ~/.config/containers/pki ] || [ -L ~/.config/containers/pki ]; then
     echo '~/.config/containers に policy.json・registries.d・pki のいずれかがすでにある。上書きせず、この手順の補足を見て手で足す' >&2
   elif [ -e ~/vbox-ga-host/containers-config-created ] || [ -L ~/vbox-ga-host/containers-config-created ]; then
     echo '前回の設定の控えがある。上書きせず、この節の手順 11 で確認してからやり直す' >&2
   elif mkdir ~/vbox-ga-host/containers-config-created &&
        mkdir ~/vbox-ga-host/containers-config-created/pki &&
        cp ~/vbox-ga-host/etc/pki/containers/*.pub ~/vbox-ga-host/containers-config-created/pki/ &&
        cp -r ~/vbox-ga-host/etc/containers/registries.d ~/vbox-ga-host/containers-config-created/ &&
        sed "s#/etc/pki/containers/#${HOME}/.config/containers/pki/#g" ~/vbox-ga-host/etc/containers/policy.json > ~/vbox-ga-host/containers-config-created/policy.json &&
        mkdir -p ~/.config/containers &&
        cp -r ~/vbox-ga-host/containers-config-created/pki ~/.config/containers/ &&
        cp -r ~/vbox-ga-host/containers-config-created/registries.d ~/.config/containers/ &&
        cp ~/vbox-ga-host/containers-config-created/policy.json ~/.config/containers/ &&
        touch ~/vbox-ga-host/containers-config-created/.ready; then
     printf '\n\033[7m 確認 \033[0m\n'
     podman image trust show
   else
     echo '設定のコピーに失敗した。次へ進まず、この節の手順 11 で残ったファイルを確認する' >&2
   fi
   ```

   - `quay.io/almalinuxorg/atomic-desktop-gnome` の行が `sigstoreSigned` ならよい
   - 自分のユーザーの podman のすべてに効く（`/etc/containers` の設定の代わりに読まれる）。消すのは、この節の手順 11
   - 「すでにある」と出たときは何も変えずに止まる。[既存の署名設定への追加](#既存のコンテナ署名設定に追加する)を行ってから、この節の手順 7 へ進む
   - 新規に置く設定の控えは `~/vbox-ga-host/containers-config-created` に残す。この節の手順 11 で、内容が変わっていないことを確かめてから消すため
   - コピーや `podman image trust show` が失敗したときは、次の手順に進まない

1. ホストの端末で、派生イメージをビルドする（[手順 6](#実施手順) の代わりに）。

   ```bash
   build_args=(--pull=newer)
   if [ -e ~/vbox-ga-mok/MOK.priv ]; then
     build_args+=(--build-arg MOK_SIGN=1 --secret "id=mok_priv,src=${HOME}/vbox-ga-mok/MOK.priv" --secret "id=mok_der,src=${HOME}/vbox-ga-mok/MOK.der")
   fi
   printf '\n\033[7m 確認 \033[0m\n'
   podman build "${build_args[@]}" --build-arg "BASE_IMAGE=${BASE_IMAGE:?手順 1 の BASE_IMAGE が空のまま。値を入れて貼り直す}" -t localhost/vbox-ga:latest ~/vbox-ga-host/vbox-ga-image
   ```

   - [手順 6](#実施手順) と同じ行が出ればよい（取り込みの `Storing signatures`、3 つのモジュールの行、`enabled` が 2 行、`Checks passed: 13`、`Successfully tagged localhost/vbox-ga:latest`）
   - ホストに鍵（`~/vbox-ga-mok/MOK.priv`）があるときだけ、モジュールに署名する（3 行が `signer=Local kernel module signing key`）
   - 途中の `depmod: ERROR`・`depmod: FATAL`、`installer exit=1`、`libsemanage.semanage_rename: WARNING: … Invalid cross-device link …` は、失敗ではない（参考資料を参照）
   - **次の手順は、`Successfully tagged` が出てから貼る**

1. ホストの端末で、派生イメージとベースのイメージを 1 つのファイルにして、VM に送る。

   ```bash
   if [ -z "${VM_SSH}" ] || [ -z "${BASE_IMAGE}" ]; then
     echo 'VM_SSH か BASE_IMAGE が空のまま。手順 1 とこの節の手順 2 を貼り直す' >&2
   else
     rm -f ~/vbox-ga-host/vbox-ga.tar
     printf '\n\033[7m 確認 \033[0m\n'
     podman save -m -o ~/vbox-ga-host/vbox-ga.tar localhost/vbox-ga:latest "${BASE_IMAGE}" && ls -lh ~/vbox-ga-host/vbox-ga.tar && scp ~/vbox-ga-host/vbox-ga.tar "${VM_SSH}:"
     rm -f ~/vbox-ga-host/vbox-ga.tar
   fi
   ```

   - `vbox-ga.tar` が約 4.8G で並び、`scp` がそれを VM のホームに送る。送った後に、ホストのファイルは消す
   - VM のユーザーのパスワードを聞かれる。`scp` が進み具合を出す
   - **次の手順は、パスワードに答え、転送が終わってから、VM の端末で貼る**

1. VM の端末で、送ったファイルからイメージを取り込む。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo podman load -i ~/vbox-ga.tar
     rm ~/vbox-ga.tar
     sudo podman images
   }
   ```

   - `Loaded image: localhost/vbox-ga:latest` と `Loaded image: quay.io/almalinuxorg/atomic-desktop-gnome:latest` が出て、`sudo podman images` にその 2 つが並べばよい
   - VM の `/var` には、ファイル（約 4.8G）の分も一時的に要る（[手順 2](#実施手順) の空きの目安より多く）
   - 続けて[手順 7](#実施手順) から先を行う
   - **[手順 7](#実施手順) は、`Loaded image:` が出てから貼る**

1. 元に戻すときは、VM の端末で、[ロールバック](extra/virtualbox-guest-bootc.md#ロールバック)の手順 1 の代わりにこれを貼る。

   ```bash
   sudo bootc switch --apply --transport containers-storage "${BASE_IMAGE:?手順 1 の BASE_IMAGE が空のまま。値を入れて貼り直す}"
   ```

   - この節の手順 9 で運んだベースのイメージに切り替えて、再起動する（`Fetching layers` が `0/0` で、`Queued for next boot: ostree-unverified-image:containers-storage:quay.io/almalinuxorg/atomic-desktop-gnome:latest`）
   - 起動した後の `sudo bootc status` の `● Booted image:` は `containers-storage:quay.io/almalinuxorg/atomic-desktop-gnome:latest` になる
     - `Digest:` も、レジストリのものとは違う値になる
     - 中身は元のイメージと同じ版（`Version:`）で、Guest Additions のモジュールと `/opt/VBoxGuestAdditions-*` は無くなる
   - 続けて[ロールバック](extra/virtualbox-guest-bootc.md#ロールバック)の手順 2 から先を行う
   - **[ロールバック](extra/virtualbox-guest-bootc.md#ロールバック)の手順 2 は、起動したらログインし、新しい端末で[手順 1](#実施手順) を貼ってから貼る**

1. 元に戻すときは、ホストの端末で、ビルドに使ったものと、署名を確かめる設定を消す。

   ```bash
   if [ -z "${BASE_IMAGE}" ]; then
     echo 'BASE_IMAGE が空のまま。手順 1 を貼り直す' >&2
   elif [ ! -f ~/vbox-ga-host/containers-config-created/.ready ]; then
     echo '新規作成した設定の控えが無いか、不完全。自動では消さず、この手順の注意に従って戻す' >&2
   else
     vbox_config_matches=1
     for vbox_config_item in policy.json registries.d pki; do
       if [ -e "${HOME}/.config/containers/${vbox_config_item}" ] || [ -L "${HOME}/.config/containers/${vbox_config_item}" ]; then
         if ! diff -qr "${HOME}/vbox-ga-host/containers-config-created/${vbox_config_item}" "${HOME}/.config/containers/${vbox_config_item}"; then
           vbox_config_matches=0
         fi
       fi
     done
     if [ "$vbox_config_matches" = 1 ]; then
       printf '\n\033[7m 確認 \033[0m\n'
       rm -rf ~/.config/containers/policy.json ~/.config/containers/registries.d ~/.config/containers/pki &&
       rm -rf ~/vbox-ga-host &&
       podman rmi localhost/vbox-ga:latest "${BASE_IMAGE}"
       rmdir --ignore-fail-on-non-empty ~/.config/containers
     else
       echo '設定・公開鍵の追加や変更、または比較の失敗がある。何も消さず、この手順の注意に従って戻す' >&2
     fi
   fi
   ```

   - 自動で消せたときは、`Untagged:` が 2 行と、`Deleted:` の行が並ぶ
   - ビルドの最初の段（`<none>`、6.43 MB）が残る。`podman image prune` で消せる（`[y/N]` を聞く）
   - **注意**: 控えが無い・不完全なときや、設定の内容が変わったときは、`policy.json`・`registries.d`・`pki` をまとめて消さない。退避と控えを見て、今回追加・変更したファイルや項目だけを手で戻す
     - 手動で戻した後に、ビルドの材料を `rm -rf ~/vbox-ga-host` で消し、イメージを `podman rmi localhost/vbox-ga:latest "${BASE_IMAGE:?手順 1 を貼り直す}"` で消す
     - コピーの途中で失敗した場合も、残ったファイルを確かめてから戻す。比較自体が失敗した場合は原因を直すか、同じく手で確認する
   - Secure Boot の鍵（`~/vbox-ga-mok`）は残る。消すときは、[ロールバック](extra/virtualbox-guest-bootc.md#ロールバック)のリード

---

## 共有フォルダーを使う（任意）

- 共有フォルダーを足すと、VM の中で `vboxsf` のモジュールが読み込まれ、フォルダーが `/media/sf_<名前>` に自動でマウントされる
  - `findmnt` の表示は `/run/media/sf_<名前>`（Atomic Desktop では `/media` が `run/media` へのリンク）
- 読み書きできるのは `vboxsf` グループのユーザーだけ

1. ホストの VirtualBox で、VM の設定の「共有フォルダー」にフォルダーを足す。

   - 「自動マウント」にチェックを入れる（英語の表示では Shared Folders と Auto-mount）
   - VM を動かしたままでも足せる
   - 動いている VM に共有フォルダを足す場合は `VBoxManage sharedfolder add --automount --transient` を使う。`--transient` が無いと `is already locked for a session` で断られる

1. 自分を `vboxsf` グループに入れる。

   ```bash
   sudo usermod -aG vboxsf "${USER}"
   ```

   - **効くのはログインし直してから**（この節の手順 3）

1. GNOME からログアウトして、ログインし直す。

   - **次の手順は、新しい端末を開いてから貼る**

1. グループと共有フォルダーを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
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
- ホストオンリーアダプターだけの VM では、この節の手順 2 の代わりに、[ホストオンリーアダプターだけの VM でビルドする（任意）](#ホストオンリーアダプターだけの-vm-でビルドする任意)の手順 5・7〜9 でホストでビルドし直し、VM に運ぶ（ホストの端末では、先に[手順 1](#実施手順) とその節の手順 2 を貼る）
- Secure Boot の鍵を作り直したときは、この節の手順 2 で `sudo podman build` に `--no-cache` を足す（ビルドのキャッシュは、渡した鍵の中身の違いを見分けない。ホストでビルドするときも同じ）
- 古いイメージは `sudo podman image prune` で消せる（`[y/N]` を聞く）

1. ホストの VirtualBox を上げたときだけ、CD を入れ直して [手順 5](#実施手順) を貼る。

   - VM のウィンドウのメニューの「デバイス」→「Guest Additions CD イメージを挿入」（英語の表示では Devices → Insert Guest Additions CD image...）で、新しい版の CD を入れる
   - [手順 5](#実施手順) の `Identification:` が、ホストの新しい版になっていればよい

1. 手順 1 の変数を設定したシェルで、[手順 6](#実施手順) を貼り直す。

   - 何も変わっていなければ、ビルドのキャッシュが使われて同じイメージになる（`Using cache` が 4 行並び、最後のイメージ ID が同じ）
   - Containerfile を置き直したとき（[手順 3](#実施手順)）は、Guest Additions の段をやり直す
   - **次の手順は、`Successfully tagged` が出てから貼る**

1. 新しいイメージを取り込んで、再起動する。

   ```bash
   sudo bootc upgrade --apply
   ```

   - イメージが変わっていれば、`Queued for next boot:` と入れ替わった層の数を出してから再起動する
   - 変わっていなければ、`No changes in ...` と `No update available.` を出して、再起動しない
   - 起動したら、[手順 8・9](#実施手順) で確かめる

---

## 既存のコンテナ署名設定に追加する

- ホストオンリーアダプターだけの VM の節の手順 6 で「すでにある」と出た場合だけ行う

1. 変更前の設定と公開鍵を別の場所に退避し、今回追加・変更するファイルを控える。既存の同名の鍵や設定は上書きしない

1. 公開鍵は `~/vbox-ga-host/etc/pki/containers/*.pub` から `~/.config/containers/pki` に写す。同名があるときは内容を照合し、別の鍵なら名前と `policy.json` の参照先を合わせて分ける

1. `policy.json` があるなら、その `transports` の `docker` に、VM の `quay.io/almalinuxorg/atomic-desktop-gnome` の項目を足す。無いなら VM のファイルを写す。どちらも鍵のパスを `~/.config/containers/pki/` に合わせる

1. `registries.d` があるなら、VM の `almalinuxorg-atomic-desktop-gnome.yaml` を、同名が無いことを確かめて足す。無いなら VM の `registries.d` をまるごと写す（1 つでも置くと、`/etc/containers/registries.d` が読まれなくなるため）

1. この節の手順 11 の自動削除は使わず、控えたファイル・項目だけを元に戻す
