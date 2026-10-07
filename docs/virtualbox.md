# VirtualBox インストール手順（AlmaLinux 10 は Oracle 公式 dnf リポジトリ / Windows 11 は winget）

## 実施手順

- [検証記録](verification/virtualbox.md)・[参考資料](reference/virtualbox.md)

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（管理者の Windows PowerShell 5.1 に貼る。下の EPEL と Secure Boot の前提、KVM の設定は要らない）
> - **前提**: [EPEL](epel.md) を有効にしてあること（依存の `liblzf` が EPEL にしか無い）。`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す
> - **前提（Secure Boot が有効な PC）**: [secure-boot-mok.md](secure-boot-mok.md) で、モジュールの署名鍵を MOK に登録してあること（VirtualBox を入れるより前に。同書で再起動し、起動の途中の MokManager を操作する）。Secure Boot が有効かは、同書の手順 3 で分かる
> - **対象ホスト（x86_64 の PC）上で実行する**。VirtualBox には Linux の arm64 版が無いので、Raspberry Pi 5（aarch64）には入らない
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない
> - **途中で再起動が 1 回入る**（手順 13）。再起動した後は新しい端末を開いて続ける
> - **手順 4・5・9 には対話入力がある**（鍵の確認・`[y/N]`）。答えてから次の手順を貼る
> - **手順 17 で GUI のウィンドウが開く**（デスクトップにログインした端末から行う）。閉じてから手順 18 を貼る

- 上から順にコードブロックを貼る
- 手順の後: カーネルを更新したときは[カーネルを更新したとき](#カーネルを更新したとき)、以後の VirtualBox の更新は[更新](#更新)、戻すときは[ロールバック](#ロールバック)

1. この PC に入るかを確かめる。

   ```bash
   uname -m
   lscpu | grep -E '^Virtualization:' || echo 'CPU の仮想化支援が見えない'
   ```

   - `uname -m` が `x86_64` で、`Virtualization:` の行に `VT-x`（Intel）か `AMD-V`（AMD）が出ればよい
   - **`aarch64` なら VirtualBox は入らないので、ここで止める**
   - `CPU の仮想化支援が見えない` と出たら、PC の UEFI（BIOS）の設定で Intel VT-x / AMD-V（SVM）を有効にしてから始める

1. Oracle の署名鍵を落として、取り込む前に fingerprint を見る。

   ```bash
   curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc -o /tmp/oracle_vbox_2016.asc
   gpg --show-keys --with-fingerprint /tmp/oracle_vbox_2016.asc
   ```

   - `gpg` が無ければ、`sudo dnf install -y gnupg2` で入れてから貼り直す（GNOME のデスクトップには入っている）
   - 次の値と一致することを目で確かめる
     - fingerprint `B9F8 D658 297A F3EF C18D 5CDF A2F6 83C5 2980 AECF`
     - uid `Oracle Corporation (VirtualBox archive signing key) <info@virtualbox.org>`
   - `sub` の下にも fingerprint が出ることがある（Homebrew の gnupg が先に見つかる PC。[検証記録](verification/virtualbox.md)・[参考資料](reference/virtualbox.md)）。照らし合わせるのは `pub` の下の行
   - 違っていればここで止める
   - **次の手順は、fingerprint と uid が一致するのを確かめてから貼る**

1. 一致したら、鍵を rpm に取り込み、入ったか確かめて、落としたファイルを消す。

   ```bash
   {
     sudo rpm --import /tmp/oracle_vbox_2016.asc
     rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i virtualbox
     rm -f /tmp/oracle_vbox_2016.asc
   }
   ```

   - `gpg-pubkey-2980aecf-5719f4e1 Oracle Corporation (VirtualBox archive signing key) ...` が出れば入っている

1. repo ファイルを置き、`sudo` の dnf でメタデータの鍵を受け入れる。

   ```bash
   {
     sudo tee /etc/yum.repos.d/virtualbox.repo >/dev/null <<'EOF'
   [virtualbox]
   name=Oracle VirtualBox for EL$releasever - $basearch
   baseurl=https://download.virtualbox.org/virtualbox/rpm/el/$releasever/$basearch
   enabled=1
   gpgcheck=1
   repo_gpgcheck=1
   gpgkey=https://www.virtualbox.org/download/oracle_vbox_2016.asc
   EOF
     cat /etc/yum.repos.d/virtualbox.repo
     sudo dnf makecache --repo virtualbox
   }
   ```

   - ヒアドキュメントは `<<'EOF'`（クォート付き）。`$releasever` / `$basearch` は dnf が展開するので、シェルに展開させない
   - このリポジトリは**メタデータにも署名がある**（`repo_gpgcheck=1`）
   - dnf はそれを確かめるための鍵を rpm とは別に持つので、最初の 1 回だけ鍵の取り込みを聞かれる
   - `Importing GPG key 0x2980AECF:` の `Fingerprint:` が、手順 2 と同じ `B9F8 D658 297A F3EF C18D 5CDF A2F6 83C5 2980 AECF` であることを確かめて `y` と答える
   - `Metadata cache created.` で終わる
   - **次の手順は、鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. `sudo` を付けない dnf にも、同じ鍵の確認を 1 回だけ通す。

   ```bash
   dnf makecache --repo virtualbox
   ```

   - こちらはユーザーごとの別のキャッシュを使う
   - 通しておかないと、`sudo` を付けない `dnf list` などが**関係の無いパッケージでも**失敗する
   - 手順 4 と同じ fingerprint を確かめて `y` と答える
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

1. 何が入るかを見る（`--assumeno` は必ず中断する）。

   ```bash
   sudo dnf install --assumeno VirtualBox-7.2
   ```

   - `VirtualBox-7.2 ... 7.2.20_175154_el10-1 ... virtualbox ... 105 M` と、依存の中に `liblzf ... epel` が出れば解決できている
   - `nothing provides liblzf.so.1()(64bit)` と出たら、[EPEL](epel.md) が有効になっていない

1. 動いているカーネルが、入っている中で一番新しいものかを見る。

   ```bash
   uname -r
   rpm -q --last kernel-core | head -1
   ```

   - 2 つの版が同じならよい
   - **違っていれば（更新したカーネルでまだ起動していなければ）、再起動してから続ける**
   - **次の手順は、2 つの版が同じなのを確かめてから貼る**

1. カーネルモジュールのビルドに要るものを、VirtualBox より先に入れて確かめる。

   ```bash
   {
     sudo dnf install -y gcc make perl-interpreter mokutil openssl "kernel-devel-$(uname -r)"
     rpm -q gcc make perl-interpreter mokutil openssl "kernel-devel-$(uname -r)"
     ls -d "/lib/modules/$(uname -r)/build/include"
   }
   ```

   - VirtualBox は、自分のカーネルモジュール（`vboxdrv` / `vboxnetflt` / `vboxnetadp`）を**インストールの途中で、この PC の上でビルドする**
   - 6 つとも版が出て、最後の行がディレクトリを返せばよい
   - `No such file or directory` なら、kernel-devel の版が合っていない

1. VirtualBox を入れる。

   ```bash
   sudo dnf install VirtualBox-7.2
   ```

   - トランザクション表を見て、`[y/N]` に `y` と答える
   - **EPEL の署名鍵をまだ取り込んでいなければ、続けて 1 回だけ確認を求められる**（[epel.md 手順 3](epel.md#実施手順) に書いた鍵）
     - `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`、Fedora (epel10) &lt;epel@fedoraproject.org&gt;
   - 最後に `Creating group 'vboxusers'. VM users must be member of that group!` が出て、続けてモジュールのビルドが走る
   - **次の手順は、`[y/N]` と鍵の確認に答え、`Complete!` が出てから貼る**（続けて貼ると答えとして食われる）

1. `Complete!` だけでは成功とは限らないので、モジュールが動いているか確かめる。

   ```bash
   systemctl is-enabled vboxdrv
   systemctl is-active vboxdrv
   lsmod | grep -E '^vbox'
   ls -l /dev/vboxdrv
   sudo tail -n 5 /var/log/vbox-setup.log
   ```

   - モジュールのビルドや読み込みに失敗しても、dnf は `Complete!` で終わる
   - `enabled` と `active`、`vboxnetadp` / `vboxnetflt` / `vboxdrv` の 3 行、root だけが読み書きできる `/dev/vboxdrv` が出ればよい
   - `dnf install` の途中で `There were problems setting up VirtualBox.` が出ていた、または `active` にならないときは、ログ（`/var/log/vbox-setup.log`）で原因を見る
   - 原因を直してから、`sudo /sbin/vboxconfig` を実行し直す

1. KVM が仮想化支援を先に取らないように、modprobe.d に設定を置いて確かめる。

   ```bash
   {
     echo 'options kvm enable_virt_at_load=0' | sudo tee /etc/modprobe.d/kvm-virtualbox.conf
     cat /etc/modprobe.d/kvm-virtualbox.conf
     modprobe -c | grep enable_virt_at_load
   }
   ```

   - **EL10 のカーネル（6.12 系）では、KVM のモジュールが読み込まれた時点で VT-x / AMD-V を確保し、VirtualBox の VM が起動できなくなる**
   - KVM を使っていなくても、VT-x / AMD-V のある PC では起動時に自動で読み込まれる
   - この設定で、KVM が自分の VM を動かす間だけ確保するように変える
   - `cat` と `modprobe -c` のどちらにも `options kvm enable_virt_at_load=0` が出ればよい（後者は modprobe が読んだ設定）
   - `modprobe -c` には `alias symbol:enable_virt_at_load kvm` の行も出る（モジュールの別名の一覧の行で、気にしなくてよい）
   - **効くのは次に kvm が読み込まれたとき**なので、手順 13 の再起動で反映させる
   - KVM（libvirt / GNOME Boxes など）はこの後も使えるが、**KVM の VM と VirtualBox の VM は同時には動かせない**

1. USB 機器を VM に渡すときだけ、自分を `vboxusers` に入れて確かめる。

   ```bash
   {
     sudo usermod -aG vboxusers "${USER}"
     getent group vboxusers
   }
   ```

   - **VM を動かすだけなら要らない**（この手順は飛ばして手順 13 へ）
   - `vboxusers:x:<GID>:<USER>` のように、自分の名前が出ればよい
   - **効くのはログインし直してから**（手順 13 の再起動で済む）

1. 再起動して、手順 11 の KVM の設定と、手順 12 のグループを反映させる。

   ```bash
   sudo systemctl reboot
   ```

   - **次の手順は、起動したら新しい端末を開いてから貼る**

1. VirtualBox の版と、モジュールと KVM の状態を確かめる。

   ```bash
   VBoxManage --version
   systemctl is-active vboxdrv
   lsmod | grep -E '^vbox'
   cat /sys/module/kvm/parameters/enable_virt_at_load 2>/dev/null || echo 'kvm は未ロード'
   id -nG | tr ' ' '\n' | grep -x vboxusers || echo 'vboxusers には入っていない'
   ```

   - `7.2.20r175154` のような版、`active`、vbox の 3 行、`N`（または `kvm は未ロード`）が出ればよい
   - 最後の行は、手順 12 を行ったときだけ `vboxusers` になる
   - **版の前に `WARNING: The vboxdrv kernel module is not loaded.` が出たら、モジュールが読み込まれていない**（手順 10 に戻る）

1. Secure Boot が有効なときだけ、モジュールの署名を見る。

   ```bash
   modinfo -F signer vboxdrv
   ```

   - `Local kernel module signing key` が出れば、[secure-boot-mok.md](secure-boot-mok.md) の鍵で署名したモジュールが使われている（旧手順で作った鍵なら `VirtualBox module signing key`）

1. 使い捨ての VM を画面無しで起動し、状態を見てから止めて消す。

   ```bash
   if VBoxManage showvminfo vbox-selftest >/dev/null 2>&1; then
     echo 'vbox-selftest はすでにある。変更せずに中断する' >&2
   elif VBoxManage createvm --name vbox-selftest --ostype Other_64 --register; then
     if VBoxManage modifyvm vbox-selftest --memory 64 --nic1 none --audio-enabled off &&
        VBoxManage startvm vbox-selftest --type headless; then
       VBoxManage showvminfo vbox-selftest --machinereadable | grep -E '^VMState='
       VBoxManage controlvm vbox-selftest poweroff
     fi
     VBoxManage unregistervm vbox-selftest --delete
   else
     echo 'VM を作れなかった。変更・起動・削除は行わない' >&2
   fi
   ```

   - VirtualBox が VT-x / AMD-V を取れるか（KVM とぶつからないか）は、ここで初めて分かる
   - 既に `vbox-selftest` があれば、変更せず中断する。別の名前で試すなら、ブロック中の `vbox-selftest` をすべて同じ名前に変える
   - 作成に失敗したときも、変更・起動・削除には進まない。削除するのは、このブロックで作成できた VM だけ
   - `VM "vbox-selftest" has been successfully started.` が出れば動いている（起動するディスクが無いので、中では何も動かない）
   - `VMState="running"` なら動いていた
   - `controlvm ... poweroff` で止まり、`unregistervm ... --delete` は `0%...10%...` と進んで、VM のファイルごと消える

1. デスクトップにログインした端末から、GUI を起動する。

   ```bash
   VirtualBox
   ```

   - アプリ一覧の「Oracle VirtualBox」からでも同じ
   - VirtualBox マネージャーのウィンドウが開く（手順 16 の VM は消してあるので一覧は空）
   - 端末に `Qt WARNING: QObject::disconnect: wildcard call disconnects from destroyed signal of UIInvisibleWindow::unnamed` が何行か出るが、気にしなくてよい
   - ウィンドウを閉じると、端末がプロンプトに戻る
   - **次の手順は、ウィンドウを閉じてから貼る**（続けて貼ると VirtualBox への操作として食われる）

1. `~/.config/VirtualBox` に設定ができたか確かめる。

   ```bash
   ls ~/.config/VirtualBox
   ```

   - `VirtualBox.xml` などが並ぶ

---

## カーネルを更新したとき

- この節は AlmaLinux 10 だけのもの（Windows 11 のドライバーは、ビルド済みのものをインストーラが入れる）
- `sudo dnf upgrade` で新しいカーネルが入ると、同じ版の `kernel-devel` も一緒に入る（installonly。[検証記録](verification/virtualbox.md)・[参考資料](reference/virtualbox.md)）
- **新しいカーネルで起動すると、`vboxdrv.service` がその場でモジュールをビルドし直す**（Secure Boot なら [secure-boot-mok.md](secure-boot-mok.md) の鍵で署名もする）。そのぶん、その 1 回の起動が遅くなる
  - スクリプトは、動いているカーネル用の vbox のモジュールが無ければ、その場でビルドする
  - 最後に「もう入っていないカーネル」用のモジュールを消す

1. 新しいカーネルで起動した後に、モジュールが作り直されたか確かめる。

   ```bash
   uname -r
   systemctl is-active vboxdrv
   modinfo -F vermagic vboxdrv
   ```

   - `modinfo` の先頭が `uname -r` と同じ版で、`active` ならよい
   - そうでなければ `sudo tail -n 20 /var/log/vbox-setup.log` で原因を見て、`sudo /sbin/vboxconfig` を実行する

---

## 更新

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 の更新](#windows-11-の更新)
- **系列を変えるとき（7.2 → 7.3 など）は、先に消してから入れる**（この節の手順 3・4）
  - 系列ごとにパッケージ名が違うので `dnf upgrade` では移らず、2 つを同時に入れることもできない
- VM の設定（`~/.config/VirtualBox` と `~/VirtualBox VMs`）は、rpm の操作では消えない

> [!WARNING]
> 系列の切り替え（この節の手順 3・4）に **`dnf swap` は使わない**。モジュールと設定を保持するため、この節の削除・再導入の順で切り替える。

1. VirtualBox の VM と GUI をすべて閉じる。

   - VirtualBox の裏のプロセス `VBoxSVC` が動いていると、rpm の `%pre` が `A copy of VirtualBox is currently running.  Please close it and try again.` で止める

1. 同じ系列の中で、新しい版に上げる。

   ```bash
   sudo dnf upgrade VirtualBox-7.2
   ```

   - トランザクション表を見て `[y/N]` に答える
   - **更新のたびに `%post` がモジュールをビルドし直す**ので、[手順 10](#実施手順) と同じ確認をする
   - コンテナで 7.2.18 → 7.2.20 を上げたときは、`%post` が新規導入のときと同じ表示を出した
   - モジュールは 7.2.20 用に作り直された（`modinfo -F version` が `7.2.18 r175117` → `7.2.20 r175154`）
   - `/sbin/vboxconfig` と udev のルールも残った
   - **[手順 10](#実施手順) の確認は、`[y/N]` に答えて `Complete!` が出てから貼る**（続けて貼ると答えとして食われる）

1. 系列を変えるときは（この節の手順 2 の代わりに）、[ロールバック](#ロールバック)の手順 2 だけを行う。

   - [ロールバック](#ロールバック)の手順 2 は `sudo dnf remove VirtualBox-7.2`
   - `[y/N]` に答えてから、この節の手順 4 に進む

1. 系列を変えるときは、パッケージ名を新しい系列に置き換えて、[手順 6](#実施手順) の下見と手順 9 からやり直す。

   - 手順 6・9 の `VirtualBox-7.2` を、新しい系列の名前（`VirtualBox-7.3` など）に置き換えて貼る
   - 以後は、この節の手順 2 と[ロールバック](#ロールバック)の手順 2 も同じく置き換える
   - repo ファイル・鍵・EPEL・ビルドの道具・MOK・KVM の設定はそのまま使える

---

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)
- この節の手順では消えないもの:
  - **Oracle の署名鍵** `gpg-pubkey-2980aecf-5719f4e1`: 消すなら `sudo rpm -e gpg-pubkey-2980aecf-5719f4e1`
  - **Secure Boot の MOK**（前提の [secure-boot-mok.md](secure-boot-mok.md) で登録した場合）: ほかにその鍵で署名したモジュールを使っていなければ、[secure-boot-mok.md のロールバック](secure-boot-mok.md#ロールバック)で消す
  - **ログ** `/var/log/vbox-setup.log`（と `.1`〜`.4`）: 要らなければ手で消す
  - **前提の EPEL と、手順 8 の gcc / kernel-devel など**: ほかでも使うので消さない

> [!CAUTION]
> **この節の手順 4 で、VM とその設定（`~/.config/VirtualBox` と `~/VirtualBox VMs`）が消える**。消した VM は取り戻せない。

1. VirtualBox の VM と GUI をすべて閉じる。

   - VM は、それぞれのウィンドウを閉じるか、VirtualBox マネージャーから止める

1. VirtualBox を消す。

   ```bash
   sudo dnf remove VirtualBox-7.2
   ```

   - **依存で入ったもの（Qt 6 など）も一緒に消える**
     - 素のコンテナでは、本体と合わせて 86 パッケージ・712 MB。依存の `xml-common` を消したときに、`/etc/xml/catalog.rpmsave` が残った
   - モジュール・`vboxdrv.service`・udev のルール・`/sbin/vboxconfig`・`/etc/vbox` は、これで消える
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. repo ファイル・KVM の設定・`vboxusers` グループ・dnf のキャッシュを消す。

   ```bash
   {
     sudo rm -f /etc/yum.repos.d/virtualbox.repo /etc/modprobe.d/kvm-virtualbox.conf
     sudo groupdel vboxusers
     sudo rm -rf /var/cache/dnf/virtualbox*
     rm -rf /var/tmp/dnf-"${USER}"-*/virtualbox*
   }
   ```

   - `vboxusers` グループは rpm を消しても残るので、ここで消す（手順 12 で自分を入れていても、グループごと消える）
   - 最後の 2 行は、手順 4・5 で取り込んだメタデータ用の鍵（`pubring/A2F683C52980AECF.pub`）を含む dnf のキャッシュを消す（root の分とユーザーの分）
   - **`dnf clean all` ではこの鍵は削除されないので、上の削除手順も行う**
   - KVM の設定を消したことは、次の起動から効く

1. VM とその設定も消すときだけ、`~/.config/VirtualBox` と `~/VirtualBox VMs` を消す（取り戻せない）。

   ```bash
   rm -rf ~/.config/VirtualBox ~/"VirtualBox VMs"
   ```

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows 11 の PC のデスクトップで行う**。SSH やリモート デスクトップのセッションからは行わない（この節の手順 3 の途中でネットワークがいったん切れ、手順 7 は画面で行う）
> - この節の手順 1 で**管理者の** Windows PowerShell（5.1）を開き、この節の手順 2〜4 と、後ろの Windows 11 の 2 節（更新・ロールバック）のブロックをそこに貼る。この節の手順 5 で**管理者ではない** Windows PowerShell を開き、手順 6・8 をそこに貼る
> - ログインするユーザーは Administrators の一員（VirtualBox は PC 全体に入り、ドライバーを入れる）
> - 前提: [Windows 11 の初期設定の手順 16〜19](windows-setup.md#実施手順)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - **AlmaLinux 10 の前提（EPEL・Secure Boot の MOK の鍵）と KVM の設定は要らない**。Windows のドライバーは、Microsoft の署名付きでインストーラに入っている

- 上から順にコードブロックを貼る。変数は無い
- 手順の後: 以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](#windows-11-のロールバック)
- VM に AlmaLinux の Atomic Desktop を入れて Guest Additions を使うなら、[virtualbox-guest-bootc.md](virtualbox-guest-bootc.md)（Windows のホストでも同じ手順で入った）

1. Windows のデスクトップで、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. この PC に入るか、今の状態を確かめる。

   ```powershell
   [pscustomobject]@{
     Admin        = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Arch         = $env:PROCESSOR_ARCHITECTURE
     Winget       = (Get-Command winget -ErrorAction SilentlyContinue).Source
     VirtualBox   = Test-Path -LiteralPath "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
     Hypervisor   = (Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
     VirtFirmware = (Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1).VirtualizationFirmwareEnabled
   } | Format-List
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -in 'Microsoft-Hyper-V-All', 'VirtualMachinePlatform', 'HypervisorPlatform' | Format-Table FeatureName, State
   ```

   - `Admin : True` と `Arch : AMD64` が出ればよい
   - `Admin` が `False` なら、管理者ではない窓に貼っている。閉じて、この節の手順 1 から
   - `Arch` が `ARM64` なら、この節は扱わない
   - `Winget` が空なら、Microsoft Store で「アプリ インストーラー」を更新してから始める
   - `Hypervisor` が `True` なら、Hyper-V のハイパーバイザーが動いている（WSL 2 を使う PC など）。VirtualBox の VM は Hyper-V の上で動き、遅くなる（[注意点](#注意点)）
   - `Hypervisor` が `False` で `VirtFirmware` も `False` なら、PC の UEFI（BIOS）の設定で Intel VT-x / AMD-V（SVM）を有効にしてから始める
   - 最後の表は、Hyper-V を使う Windows の機能の状態（`Enabled` / `Disabled`）。一覧を作るのに数秒かかる
   - `VirtualBox` が `True` なら、もう入っている。この節の手順 3 は飛ばす（新しい版にするなら[Windows 11 の更新](#windows-11-の更新)）

1. VirtualBox が入っていないときだけ、winget で入れる。

   ```powershell
   winget install --exact --id Oracle.VirtualBox --source winget --accept-source-agreements --accept-package-agreements
   ```

   - 依存の Microsoft Visual C++ の再頒布可能パッケージ（`Microsoft.VCRedist.2015+.x64`）が無ければ、先にそれが入る
   - **途中でネットワークがいったん切れる**（VirtualBox のネットワークのドライバーを入れるため）
   - インストーラの画面は出ず、進み具合だけが出る。最後に、入れ終えた旨の行（英語の表示では `Successfully installed`）が出ればよい
   - デスクトップとスタートメニューに「Oracle VirtualBox」のショートカットができる
   - **次の手順は、winget が終わってプロンプトに戻ってから貼る**（続けて貼ると、winget が何か聞いたときの答えとして食われる）

1. 入ったか、ドライバーとホストオンリーのアダプターができたかを確かめる。

   ```powershell
   winget list --exact --id Oracle.VirtualBox --source winget
   & "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" --version
   Get-CimInstance -ClassName Win32_SystemDriver -Filter "Name LIKE 'VBox%'" | Format-Table Name, State, StartMode
   Get-NetAdapter -InterfaceDescription 'VirtualBox Host-Only Ethernet Adapter*' | Format-Table Name, InterfaceDescription, Status
   ```

   - `Oracle.VirtualBox` の `7.2.20` の行と、`7.2.20r175154` が出ればよい（版は実行した日の最新）
   - `VBoxManage` は `PATH` に入らないので、場所を付けて呼ぶ
   - ドライバーは `VBoxSup`・`VBoxNetLwf`・`VBoxNetAdp`・`VBoxUSBMon` などが出て、`VBoxSup` が `Running` ならよい
   - ホストオンリーのアダプターが 1 つ出る（`Name` は `イーサネット 2` のように PC で違う）

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）
   - VM と VirtualBox マネージャーは、自分のユーザー（管理者ではない権限）で動かす
   - この節の手順 1 の管理者の窓は、後ろの Windows 11 の 2 節で使う。閉じてもよい

1. 使い捨ての VM を画面無しで起動し、Hyper-V の上で動くかを見てから止めて消す。

   ```powershell
   $vbm = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
   if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
     Write-Error '管理者の PowerShell に貼っている（この節の手順 5 で開いた窓に貼る）'
   } else {
     & $vbm showvminfo vbox-selftest *> $null
     if ($LASTEXITCODE -eq 0) {
       Write-Error 'vbox-selftest はすでにある。変更せずに中断する'
     } else {
       & $vbm createvm --name vbox-selftest --ostype Other_64 --register
       if ($LASTEXITCODE -eq 0) {
         & $vbm modifyvm vbox-selftest --memory 64 --nic1 none --audio-enabled off
         if ($LASTEXITCODE -eq 0) {
           & $vbm startvm vbox-selftest --type headless
           if ($LASTEXITCODE -eq 0) {
             & $vbm showvminfo vbox-selftest --machinereadable | Select-String -Pattern '^VMState='
             & $vbm showvminfo vbox-selftest --log 0 | Select-String -Pattern 'fall back to NEM|Snail execution mode'
             & $vbm controlvm vbox-selftest poweroff
           }
         }
         & $vbm unregistervm vbox-selftest --delete
       } else {
         Write-Error 'VM を作れなかった。変更・起動・削除は行わない'
       }
     }
   }
   ```

   - VirtualBox が VT-x / AMD-V（か Hyper-V）を使えるかは、ここで初めて分かる
   - `VM "vbox-selftest" has been successfully started.` と `VMState="running"` が出れば動いている（起動するディスクが無いので、中では何も動かない）
   - **`fall back to NEM` か `Snail execution mode` を含む行が出たら、VM は Hyper-V の上で動いている**（遅くなる。[注意点](#注意点)）
   - その行が出なければ、VirtualBox は VT-x / AMD-V を直接使っているはず
   - `poweroff` と `unregistervm` は `0%...100%` の行を出し、VM のファイルごと消える
   - 既に `vbox-selftest` があれば、変更せず中断する。別の名前で試すなら、ブロック中の `vbox-selftest` をすべて同じ名前に変える
   - 作成に失敗したときも、変更・起動・削除には進まない。削除するのは、このブロックで作成できた VM だけ

1. スタートメニューの「Oracle VirtualBox」で VirtualBox マネージャーを開き、閉じる。

   - デスクトップのショートカットでも、この節の手順 6 の窓で `& "$env:ProgramFiles\Oracle\VirtualBox\VirtualBox.exe"` を打っても同じ
   - VirtualBox マネージャーのウィンドウが開く（この節の手順 6 の VM は消してあるので、一覧は空）
   - 右クリックの「管理者として実行」では開かない
   - **次の手順は、ウィンドウを閉じてから貼る**

1. `%USERPROFILE%\.VirtualBox` に設定ができたか確かめる。

   ```powershell
   Get-ChildItem -LiteralPath "$env:USERPROFILE\.VirtualBox" | Format-Table Name, Length
   ```

   - `VirtualBox.xml`・`VBoxSVC.log` などが並べばよい
   - Windows の VirtualBox は、全体の設定を `%USERPROFILE%\.VirtualBox` に置く（AlmaLinux 10 の `~/.config/VirtualBox` に当たる。マニュアルの 13.1.2「Global Settings」）

---

## Windows 11 の更新

- この節は、[Windows 11 で使う](#windows-11-で使う)の手順 1 と同じ管理者の Windows PowerShell（5.1）に貼る
- 7.2 の中の更新も、系列が変わる更新（7.3 など。まだ出ていない）も、winget の同じ ID（`Oracle.VirtualBox`）で上がる。AlmaLinux 10 と違い、名前に系列が入らない
- VirtualBox マネージャーも、決まった間隔で新しい版を確かめる（環境設定の Update のタブ。マニュアル）。入れ替えは、この節の手順で行う
- **更新の途中でも、ネットワークがいったん切れるはず**（ドライバーを入れ直すため）
- VM の中の Guest Additions は、この節では上がらない（Atomic Desktop の VM は [virtualbox-guest-bootc.md の更新](virtualbox-guest-bootc.md#更新)）

1. VirtualBox の VM と VirtualBox マネージャーをすべて閉じる。

   - VM は、それぞれのウィンドウを閉じるか、VirtualBox マネージャーから止める
   - **次の手順は、すべて閉じてから貼る**

1. VirtualBox が動いていないことと、新しい版があるかを確かめる。

   ```powershell
   Get-Process -Name VirtualBox, VirtualBoxVM, VBoxHeadless, VBoxSVC -ErrorAction SilentlyContinue | Format-Table Id, ProcessName
   winget list --exact --id Oracle.VirtualBox --source winget
   ```

   - プロセスは何も出なければよい
   - `VBoxSVC` だけが出たら、数秒待って貼り直す（VirtualBox マネージャーや VM を閉じた後、しばらく残る。ソースでは、使われなくなってから 5 秒で終わる）
   - `winget list` の版の列の右に、新しい版の列（英語の表示では `Available`）が出たら、新しい版がある
   - 新しい版の列が無ければ、この節の手順 3・4 は飛ばす

1. 新しい版があるときだけ、winget で上げる。

   ```powershell
   winget upgrade --exact --id Oracle.VirtualBox --source winget --accept-source-agreements --accept-package-agreements
   ```

   - 新しい版のインストーラを、今の版の上から動かす（winget の定義の `UpgradeBehavior: install`）。VM と設定は残る
   - 途中でネットワークがいったん切れるはず
   - **次の手順は、winget が終わってプロンプトに戻ってから貼る**（続けて貼ると、winget が何か聞いたときの答えとして食われる）

1. 新しい版にしたときだけ、新しい版になったか確かめる。

   ```powershell
   & "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" --version
   winget list --exact --id Oracle.VirtualBox --source winget
   ```

   - 新しい版の番号が出て、`winget list` の新しい版の列が消えればよい

---

## Windows 11 のロールバック

- 上から順に、[Windows 11 で使う](#windows-11-で使う)の手順 1 と同じ管理者の Windows PowerShell（5.1）に貼る
- この節の手順では消えないもの:
  - **VM とその設定**（`%USERPROFILE%\VirtualBox VMs` と `%USERPROFILE%\.VirtualBox`）: 消すなら、この節の手順 4
  - **依存で入った Microsoft Visual C++ の再頒布可能パッケージ**: ほかのアプリも使うので消さない
  - **Oracle の証明書**（インストーラが `--silent` のときに「信頼された発行元」に入れたもの）: インストーラと MSI に、消す処理は見当たらない
- **アンインストールの途中でも、ネットワークがいったん切れるはず**（ドライバーを外すため）

> [!CAUTION]
> **この節の手順 4 で、VM とその設定（`%USERPROFILE%\VirtualBox VMs` と `%USERPROFILE%\.VirtualBox`）が消える**。消した VM は取り戻せない。

1. VirtualBox の VM と VirtualBox マネージャーをすべて閉じる。

   - VM は、それぞれのウィンドウを閉じるか、VirtualBox マネージャーから止める
   - **次の手順は、すべて閉じてから貼る**

1. VirtualBox が動いていなければ、winget で消す。

   ```powershell
   if (Get-Process -Name VirtualBox, VirtualBoxVM, VBoxHeadless, VBoxSVC -ErrorAction SilentlyContinue) {
     Write-Error '中断: VirtualBox が動いている（この節の手順 1 で閉じ、数秒待って貼り直す）'
   } else {
     winget uninstall --exact --id Oracle.VirtualBox --source winget
   }
   ```

   - `中断:` で始まるエラーが出たら、何も消していない
   - 途中でネットワークがいったん切れるはず
   - **次の手順は、winget が終わってプロンプトに戻ってから貼る**（続けて貼ると、winget が何か聞いたときの答えとして食われる）

1. 消えたか確かめる。

   ```powershell
   winget list --exact --id Oracle.VirtualBox --source winget
   Test-Path -LiteralPath "$env:ProgramFiles\Oracle\VirtualBox"
   Get-CimInstance -ClassName Win32_SystemDriver -Filter "Name LIKE 'VBox%'" | Format-Table Name, State
   Get-NetAdapter -InterfaceDescription 'VirtualBox Host-Only Ethernet Adapter*' -ErrorAction SilentlyContinue
   ```

   - `winget list` は、入っているパッケージが見つからない旨を出す
   - `False` が出て、最後の 2 つは何も出さなければよい
   - ドライバーの行が残ったら、再起動してから貼り直す

1. VM とその設定も消すときだけ、`%USERPROFILE%\VirtualBox VMs` と `%USERPROFILE%\.VirtualBox` を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\VirtualBox VMs", "$env:USERPROFILE\.VirtualBox" -Recurse -Force -ErrorAction SilentlyContinue
   Test-Path -LiteralPath "$env:USERPROFILE\VirtualBox VMs", "$env:USERPROFILE\.VirtualBox"
   ```

   - `False` が 2 行出ればよい
   - VM の置き場所を既定から変えていたら（VirtualBox マネージャーの環境設定）、そのフォルダーは別に消す

---

## 注意点

- **EPEL が要る**: 依存の `liblzf` が EPEL にしか無い（[検証記録](verification/virtualbox.md)・[参考資料](reference/virtualbox.md)）。前提の [epel.md](epel.md) で有効にする
- **`Complete!` でもモジュールができていないことがある**: `%post` は失敗を無視する。`systemctl is-active vboxdrv` と `/var/log/vbox-setup.log` で確かめる（[手順 9・10](#実施手順)）
- **sudo を付けない dnf にも鍵の確認が要る**: `repo_gpgcheck=1` のため。確認を通すまで、`sudo` 無しの dnf はどのパッケージでも失敗する（[検証記録](verification/virtualbox.md)・[参考資料](reference/virtualbox.md)）
- **Secure Boot では `mokutil` と、登録した鍵が要る**: vboxdrv.sh は `mokutil --sb-state` の出力だけで判定する。鍵の場所は `/var/lib/shim-signed/mok/` 固定で、前提の [secure-boot-mok.md](secure-boot-mok.md) で作って登録する
- **MokManager でキーボードが効かなければ、[secure-boot-mok.md](secure-boot-mok.md) の手順 6 に従って対処する**。Secure Boot を無効にするとモジュールは署名されない。後で有効に戻すなら、鍵を登録して `sudo /sbin/vboxconfig` を実行する
- **EL10 のカーネルでは KVM と同居できない**: `enable_virt_at_load=0` が要り、それでも KVM の VM と VirtualBox の VM は同時に動かない（[手順 11](#実施手順)）
- **カーネルを更新した後の最初の起動は遅くなる**: `vboxdrv.service` がモジュールをビルドし直す（[カーネルを更新したとき](#カーネルを更新したとき)）
- **系列がパッケージ名に入っている**: 7.2 → 7.3 は `dnf upgrade` では移らない（[更新](#更新)）
- **vboxusers は USB のためだけ**: VM の起動には要らない（[手順 12](#実施手順)）
- **Extension Pack は本書では扱わない**: 追加機能（マニュアルによれば VRDP のサーバー、ホストの Web カメラの受け渡し、Intel の PXE ブート ROM、ディスクイメージの暗号化、クラウド連携）をまとめた別配布
  - ライセンスは GPL ではなく **PUEL（個人利用と教育利用に限って無償）**
  - rpm の `%postun` が `/usr/lib/virtualbox/ExtensionPacks` を消すので、入れた場合は **VirtualBox の更新のたびに入れ直す**ことになる（rpm のスクリプトからの推定）
- **Guest Additions はゲスト側の話で対象外**: ISO は rpm に同梱されている（`/usr/share/virtualbox/VBoxGuestAdditions.iso`）。ゲストが AlmaLinux の bootc（Atomic Desktop）なら [virtualbox-guest-bootc.md](virtualbox-guest-bootc.md)
- **公式の repo ファイルは `http://`**: 本書の repo ファイルは `https://` にしてある。署名の検証はどちらでも行われる
- **Windows 11 の注意点**
  - **Hyper-V が動いている PC では、VM が Hyper-V の上で動き、遅くなる**（WSL 2 を使う PC など）
    - VirtualBox のマニュアル（11.30）は、Hyper-V が動いていると Hyper-V を仮想化の土台に使い、大きく遅くなることがあると書いている
    - マニュアルのトラブルシューティング（13.7.6.7）は、Hyper-V Platform・Virtual Machine Platform・Windows Hypervisor Platform を切って再起動するよう勧めている（本書は切らない。[選択した方針](reference/virtualbox.md#選択した方針)）
    - 止まっている間に VM の中の systemd の watchdog が `systemd-logind` などを止め、GNOME がログイン画面に戻った回もあった
    - VM が Hyper-V の上かは、VM のログ（[Windows 11 で使う](#windows-11-で使う)の手順 6）か、VM のウィンドウの状態バー（プロセッサーのアイコンに緑の亀）で分かる
  - **入れる・上げる・消すときに、ネットワークがいったん切れる**: ブリッジ接続のドライバーを入れるため（MSI の画面の警告。上げる・消すときも切れるはず）。SSH やリモート デスクトップでつないでいる PC では行わない
  - **VirtualBox は管理者ではない窓で動かす**: 管理者の窓から起動すると、VM も管理者の権限で動く（[Windows 11 で使う](#windows-11-で使う)の[検証記録](verification/virtualbox.md)・[参考資料](reference/virtualbox.md)）
  - **`VBoxManage` は `PATH` に入らない**: `C:\Program Files\Oracle\VirtualBox\VBoxManage.exe` を場所ごと呼ぶ（インストーラが足す環境変数は `VBOX_MSI_INSTALL_PATH` だけ）
  - **Secure Boot の MOK は要らない**: ドライバーは Microsoft の署名付きで配られる。[secure-boot-mok.md](secure-boot-mok.md) は Linux だけのもの
  - **ロールバックで残るもの**: 依存で入った Visual C++ の再頒布可能パッケージと、インストーラが「信頼された発行元」に入れた Oracle の証明書（[Windows 11 のロールバック](#windows-11-のロールバック)）
