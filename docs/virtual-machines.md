# 仮想マシンのセットアップ（AlmaLinux 10・Windows 11）

- AlmaLinux 10 は VirtualBox・VirtualBox の bootc ゲスト・kvm-container、Windows 11 は Hyper-V・VirtualBox・VMware Workstation Pro・Windows Sandbox
- 検証記録・参考資料・注意点は、各項のリードから開く

> [!IMPORTANT]
> - AlmaLinux 10 の項は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)と同じく、**GNOME にログインした、インストール時の管理者ユーザー（`wheel`）の bash で行う**。`sudo -i`・`su -` のシェルでは行わない
> - Windows 11 の項は、[Windows 11 のセットアップ](windows-setup.md)と同じく、**この PC のデスクトップで、Administrators のユーザーが行う**。PowerShell のブロックは **Windows PowerShell 5.1** に貼る
> - Windows 11 で[貼り付けの設定](windows-setup.md#貼り付けの設定)より前は **Ctrl+V で貼る**。設定後は GitHub のコピーボタンでコピーし、右クリックで貼れる

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- Windows 11 で GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- 入れたものを上げるときは、[VirtualBox: 更新](#virtualbox-更新)・[VirtualBox の bootc ゲスト: 更新](#virtualbox-の-bootc-ゲスト-更新)・[kvm-container を更新する](#kvm-container-を更新する)・[VirtualBox: Windows 11 の更新](#virtualbox-windows-11-の更新)を通す。Hyper-V・VMware Workstation Pro・Windows Sandbox には、更新の項は無い

## AlmaLinux 10 で使う

- VirtualBox・VirtualBox の bootc ゲスト・kvm-container

### VirtualBox

- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/virtualbox.md)・[参考資料](reference/virtualbox.md)・[注意点](extra/virtualbox.md)

> [!IMPORTANT]
> - AlmaLinux 10 用の手順。Windows 11 は[Windows の手順](#windows-11-で-virtualbox-を入れる)を管理者の Windows PowerShell 5.1 で通す
> - Windows では EPEL・Secure Boot の前提と KVM の設定は不要
> - **対象ホスト（x86_64 の PC）上で実行する**。VirtualBox には Linux の arm64 版が無いので、Raspberry Pi 5（aarch64）には入らない
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない

#### VirtualBox: リポジトリを置く

- Oracle の VirtualBox の dnf リポジトリを置き、その署名鍵を rpm と dnf に取り込む
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)を通してある
- 実行場所: 対象ホスト（x86_64 の AlmaLinux 10 の PC）の、自分のユーザーの端末（bash）
- この項の手順 4・5 には、**対話入力がある**（鍵の確認）。答えてから次の手順を貼る

1. この PC に入るかを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   uname -m
   lscpu | grep -E '^Virtualization:' || echo 'CPU の仮想化支援が見えない'
   ```

   - `uname -m` が `x86_64` で、`Virtualization:` の行に `VT-x`（Intel）か `AMD-V`（AMD）が出ればよい
   - **`aarch64` なら VirtualBox は入らないので、ここで止める**
   - `CPU の仮想化支援が見えない` と出たら、PC の UEFI（BIOS）の設定で Intel VT-x / AMD-V（SVM）を有効にしてから始める

1. Oracle の署名鍵を落として、取り込む前に fingerprint を見る。

   ```bash
   curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc -o /tmp/oracle_vbox_2016.asc
   printf '\n\033[7m 確認 \033[0m\n'
   gpg --show-keys --with-fingerprint /tmp/oracle_vbox_2016.asc
   ```

   - `gpg` が無ければ、`sudo dnf install -y gnupg2` で入れてから貼り直す
   - 次の値と一致することを目で確かめる
     - fingerprint `B9F8 D658 297A F3EF C18D 5CDF A2F6 83C5 2980 AECF`
     - uid `Oracle Corporation (VirtualBox archive signing key) <info@virtualbox.org>`
   - `sub` の下にも fingerprint が出ることがある。照らし合わせるのは `pub` の下の行
   - 違っていればここで止める
   - **次の手順は、fingerprint と uid が一致するのを確かめてから貼る**

1. 一致したら、鍵を rpm に取り込み、入ったか確かめて、落としたファイルを消す。

   ```bash
   {
     sudo rpm --import /tmp/oracle_vbox_2016.asc
     printf '\n\033[7m 確認 \033[0m\n'
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
     printf '\n\033[7m 確認 \033[0m\n'
     sudo dnf makecache --repo virtualbox
   }
   ```

   - 最初の 1 回だけ鍵の取り込みを聞かれる
   - 鍵の表示は `Importing GPG key 0x2980AECF:`（日本語は `GPG 鍵 0x2980AECF をインポート中:`）
   - fingerprint が、この項の手順 2 と同じ `B9F8 D658 297A F3EF C18D 5CDF A2F6 83C5 2980 AECF` であることを確かめて `y` と答える
   - `Metadata cache created.`（日本語では `メタデータキャッシュを作成しました。`）で終わる
   - **次の手順は、鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. `sudo` を付けない dnf にも、同じ鍵の確認を 1 回だけ通す。

   ```bash
   dnf makecache --repo virtualbox
   ```

   - この項の手順 4 と同じ fingerprint を確かめて `y` と答える
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

#### VirtualBox: VirtualBox を入れる

- VirtualBox と、カーネルモジュールのビルドに要るものを入れ、モジュールが動いているか確かめる
- 前提: [VirtualBox: リポジトリを置く](#virtualbox-リポジトリを置く)と[EPEL と RPM Fusion](almalinux-setup.md#epel-と-rpm-fusion)の手順 1 を通してある
  - `dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に EPEL を通す
  - **Secure Boot が有効な PC は、VirtualBox より先に[Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)で鍵を MOK に登録してある**。有効かは[Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)の手順 3 で分かる
  - 署名鍵の手順で再起動し、起動途中の MokManager を操作する
- 実行場所: 対象ホスト（x86_64 の AlmaLinux 10 の PC）の、自分のユーザーの端末（bash）
- この項の手順 4 には、**対話入力がある**（`[y/N]`・鍵の確認）。答えてから次の手順を貼る

1. 何が入るかを見る（`--assumeno` は必ず中断する）。

   ```bash
   sudo dnf install --assumeno VirtualBox-7.2
   ```

   - `VirtualBox-7.2 ... 7.2.20_175154_el10-1 ... virtualbox ... 105 M` と、依存の中に `liblzf ... epel` が出れば解決できている
   - `nothing provides liblzf.so.1()(64bit)` と出たら、EPEL が有効になっていない（[AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」の手順 1](almalinux-setup.md#epel-と-rpm-fusion)）

1. 動いているカーネルが、入っている中で一番新しいものかを見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
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
     printf '\n\033[7m 確認 \033[0m\n'
     rpm -q gcc make perl-interpreter mokutil openssl "kernel-devel-$(uname -r)"
     ls -d "/lib/modules/$(uname -r)/build/include"
   }
   ```

   - 6 つとも版が出て、最後の行がディレクトリを返せばよい
   - `No such file or directory` なら、kernel-devel の版が合っていない

1. VirtualBox を入れる。

   ```bash
   sudo dnf install VirtualBox-7.2
   ```

   - トランザクション表を見て、`[y/N]` に `y` と答える
   - **EPEL の署名鍵をまだ取り込んでいなければ、続けて 1 回だけ確認を求められる**（[AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」の手順 1](almalinux-setup.md#epel-と-rpm-fusion) に書いた鍵）
     - `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`、Fedora (epel10) &lt;epel@fedoraproject.org&gt;
   - 最後に `Creating group 'vboxusers'. VM users must be member of that group!` が出て、続けてモジュールのビルドが走る
   - **次の手順は、`[y/N]` と鍵の確認に答え、`Complete!`（日本語では `完了しました!`）が出てから貼る**（続けて貼ると答えとして食われる）

1. `Complete!`（日本語では `完了しました!`）だけでは成功とは限らないので、モジュールが動いているか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   systemctl is-enabled vboxdrv
   systemctl is-active vboxdrv
   lsmod | grep -E '^vbox'
   ls -l /dev/vboxdrv
   sudo tail -n 5 /var/log/vbox-setup.log
   ```

   - `enabled` と `active`、`vboxnetadp` / `vboxnetflt` / `vboxdrv` の 3 行、root だけが読み書きできる `/dev/vboxdrv` が出ればよい
   - `dnf install` の途中で `There were problems setting up VirtualBox.` が出ていた、または `active` にならないときは、ログ（`/var/log/vbox-setup.log`）で原因を見る
   - 原因を直してから、`sudo /sbin/vboxconfig` を実行し直す

#### VirtualBox: KVM と USB の設定

- KVM が仮想化支援を先に取らないようにし、USB 機器を渡すなら自分を `vboxusers` に入れて、再起動で反映させる
- 前提: [VirtualBox: VirtualBox を入れる](#virtualbox-virtualbox-を入れる)を通してある
- 実行場所: 対象ホスト（x86_64 の AlmaLinux 10 の PC）の、自分のユーザーの端末（bash）
- **この項の手順 3 で再起動する**。再起動した後は新しい端末を開いて続ける

1. KVM が仮想化支援を先に取らないように、modprobe.d に設定を置いて確かめる。

   ```bash
   {
     echo 'options kvm enable_virt_at_load=0' | sudo tee /etc/modprobe.d/kvm-virtualbox.conf
     printf '\n\033[7m 確認 \033[0m\n'
     cat /etc/modprobe.d/kvm-virtualbox.conf
     modprobe -c | grep enable_virt_at_load
   }
   ```

   - `cat` と `modprobe -c` のどちらにも `options kvm enable_virt_at_load=0` が出ればよい
   - `modprobe -c` には `alias symbol:enable_virt_at_load kvm` の行も出る（モジュールの別名の一覧の行で、気にしなくてよい）

1. USB 機器を VM に渡すときだけ、自分を `vboxusers` に入れて確かめる。

   ```bash
   {
     sudo usermod -aG vboxusers "${USER}"
     printf '\n\033[7m 確認 \033[0m\n'
     getent group vboxusers
   }
   ```

   - **VM を動かすだけなら要らない**（この手順は飛ばしてこの項の手順 3 へ）
   - `vboxusers:x:<GID>:<USER>` のように、自分の名前が出ればよい

1. 再起動して、この項の手順 1 の KVM の設定と、この項の手順 2 のグループを反映させる。

   ```bash
   sudo systemctl reboot
   ```

   - **次の手順は、起動したら新しい端末を開いてから貼る**

#### VirtualBox: 動作を確かめる

- VirtualBox の版とモジュール・KVM の状態を見て、使い捨ての VM と GUI で動くか確かめる
- 前提: [VirtualBox: KVM と USB の設定](#virtualbox-kvm-と-usb-の設定)を通し、再起動してある
- 実行場所: 対象ホスト（x86_64 の AlmaLinux 10 の PC）の、GNOME にログインした自分のユーザーの端末（bash。再起動した後に開いたもの）
- この項の手順 4 で **GUI のウィンドウが開く**（デスクトップにログインした端末から行う）。閉じてからこの項の手順 5 を貼る

1. VirtualBox の版と、モジュールと KVM の状態を確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   VBoxManage --version
   systemctl is-active vboxdrv
   lsmod | grep -E '^vbox'
   cat /sys/module/kvm/parameters/enable_virt_at_load 2>/dev/null || echo 'kvm は未ロード'
   id -nG | tr ' ' '\n' | grep -x vboxusers || echo 'vboxusers には入っていない'
   ```

   - `7.2.20r175154` のような版、`active`、vbox の 3 行、`N`（または `kvm は未ロード`）が出ればよい
   - 最後の行は、[KVM と USB の設定](#virtualbox-kvm-と-usb-の設定)の手順 2 を行ったときだけ `vboxusers` になる
   - **版の前に `WARNING: The vboxdrv kernel module is not loaded.` が出たら、モジュールが読み込まれていない**（[VirtualBox を入れる](#virtualbox-virtualbox-を入れる)の手順 5 に戻る）

1. Secure Boot が有効なときだけ、モジュールの署名を見る。

   ```bash
   modinfo -F signer vboxdrv
   ```

   - 署名者が `Local kernel module signing key` ならよい（[署名鍵](almalinux-setup.md#secure-boot-の署名鍵)）

1. 使い捨ての VM を画面無しで起動し、状態を見てから止めて消す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
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

   - 既に `vbox-selftest` があれば、変更せず中断する。別の名前で試すなら、ブロック中の `vbox-selftest` をすべて同じ名前に変える
   - `VM "vbox-selftest" has been successfully started.` が出れば動いている
   - `VMState="running"` なら動いていた
   - `controlvm ... poweroff` で止まり、`unregistervm ... --delete` は `0%...10%...` と進んで、VM のファイルごと消える

1. デスクトップにログインした端末から、GUI を起動する。

   ```bash
   VirtualBox
   ```

   - アプリ一覧の「Oracle VirtualBox」からでも同じ
   - VirtualBox マネージャーのウィンドウが開く（一覧は空）
   - 端末に `Qt WARNING: QObject::disconnect: wildcard call disconnects from destroyed signal of UIInvisibleWindow::unnamed` が何行か出るが、気にしなくてよい
   - ウィンドウを閉じると、端末がプロンプトに戻る
   - **次の手順は、ウィンドウを閉じてから貼る**（続けて貼ると VirtualBox への操作として食われる）

1. `~/.config/VirtualBox` に設定ができたか確かめる。

   ```bash
   ls ~/.config/VirtualBox
   ```

   - `VirtualBox.xml` などが並ぶ

#### VirtualBox: カーネルを更新したとき

- 新しいカーネルで起動した後に、VirtualBox のモジュールが作り直されたか確かめる
- 前提: [VirtualBox: リポジトリを置く](#virtualbox-リポジトリを置く)から[VirtualBox: 動作を確かめる](#virtualbox-動作を確かめる)までを通し、新しいカーネルで起動してある
- 実行場所: 対象ホスト（x86_64 の AlmaLinux 10 の PC）の、自分のユーザーの端末（bash。新しいカーネルで起動した後に開いたもの）
- この項は AlmaLinux 10 だけのもの（Windows 11 のドライバーは、ビルド済みのものをインストーラが入れる）
- `sudo dnf upgrade` で新しいカーネルが入ると、同じ版の `kernel-devel` も一緒に入る（installonly。[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/virtualbox.md)・[参考資料](reference/virtualbox.md)）
- **新しいカーネルで起動すると、`vboxdrv.service` がその場でモジュールをビルドし直す**（Secure Boot なら [Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵) の鍵で署名もする）。そのぶん、その 1 回の起動が遅くなる
  - スクリプトは、動いているカーネル用の vbox のモジュールが無ければ、その場でビルドする
  - 最後に「もう入っていないカーネル」用のモジュールを消す

1. 新しいカーネルで起動した後に、モジュールが作り直されたか確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   uname -r
   systemctl is-active vboxdrv
   modinfo -F vermagic vboxdrv
   ```

   - `modinfo` の先頭が `uname -r` と同じ版で、`active` ならよい
   - そうでなければ `sudo tail -n 20 /var/log/vbox-setup.log` で原因を見て、`sudo /sbin/vboxconfig` を実行する

#### VirtualBox: 更新

- VirtualBox を同じ系列の新しい版に上げる。系列を変えるときは、消してから入れ直す
- 前提: [VirtualBox: リポジトリを置く](#virtualbox-リポジトリを置く)から[VirtualBox: 動作を確かめる](#virtualbox-動作を確かめる)までを通してある
- 実行場所: 対象ホスト（x86_64 の AlmaLinux 10 の PC）の、GNOME にログインした自分のユーザーの端末（bash）
- この項は AlmaLinux 10 のもの。Windows 11 は[Windows 11 の更新](#virtualbox-windows-11-の更新)
- **系列を変えるとき（7.2 → 7.3 など）は、先に消してから入れる**（この項の手順 3・4）
  - 系列ごとにパッケージ名が違うので `dnf upgrade` では移らず、2 つを同時に入れることもできない
- VM の設定（`~/.config/VirtualBox` と `~/VirtualBox VMs`）は、rpm の操作では消えない

> [!WARNING]
> 系列の切り替え（この項の手順 3・4）に **`dnf swap` は使わない**。モジュールと設定を保持するため、この項の削除・再導入の順で切り替える。

1. VirtualBox の VM と GUI をすべて閉じる。

   - VirtualBox の裏のプロセス `VBoxSVC` が動いていると、rpm の `%pre` が `A copy of VirtualBox is currently running.  Please close it and try again.` で止める

1. 同じ系列の中で、新しい版に上げる。

   ```bash
   sudo dnf upgrade VirtualBox-7.2
   ```

   - トランザクション表を見て `[y/N]` に答える
   - [VirtualBox を入れる](#virtualbox-virtualbox-を入れる)の手順 5 と同じ確認をする
   - [VirtualBox を入れる](#virtualbox-virtualbox-を入れる)の手順 5 の確認は、**`[y/N]` に答えて `Complete!`（日本語では `完了しました!`）が出てから貼る**（続けて貼ると答えとして食われる）

1. 系列を変えるときは（この項の手順 2 の代わりに）、今の系列のパッケージを消す。

   ```bash
   sudo dnf remove VirtualBox-7.2
   ```

   - **次の手順は、`[y/N]` に答えて `Complete!`（日本語では `完了しました!`）が出てから貼る**（続けて貼ると答えとして食われる）

1. 系列を変えるときは、パッケージ名を新しい系列に置き換えて、[VirtualBox を入れる](#virtualbox-virtualbox-を入れる)の手順 1 の下見と同じ項の手順 4 からやり直す。

   - [VirtualBox を入れる](#virtualbox-virtualbox-を入れる)の手順 1・4 の `VirtualBox-7.2` を、新しい系列の名前（`VirtualBox-7.3` など）に置き換えて貼る
   - 以後は、この項の手順 2・3 も同じく置き換える

---

### VirtualBox の bootc ゲスト

- VirtualBox の VM の中の AlmaLinux Atomic Desktop（bootc）に Guest Additions を入れる。**dnf では入れない**。Guest Additions を焼き込んだ派生イメージをこの VM でビルドし、`bootc switch` で切り替える（手順 3〜7）
- 前提:
  - ホストに VirtualBox を入れ、その VM に AlmaLinux Atomic Desktop（GNOME）を入れてある。ホストは AlmaLinux 10（[VirtualBox: リポジトリを置く](#virtualbox-リポジトリを置く)から[VirtualBox: 動作を確かめる](#virtualbox-動作を確かめる)まで）でも Windows 11（[Windows の VirtualBox](#windows-11-で-virtualbox-を入れる)）でもよい
  - **Secure Boot が有効な VM は、先に[Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)を VM の中で通し、鍵を MOK に登録してある**
    - 再起動時の MokManager を VM のウィンドウで操作する。最初の画面は 10 秒で消える
    - `mokutil --sb-state` が `SecureBoot enabled` であることを確認する
    - `sudo mokutil --test-key /var/lib/shim-signed/mok/MOK.der` が `is already enrolled` を返さなければ、先に署名鍵の手順を通す
    - ホストオンリーだけなら、[Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)の手順 3 まで通す
      - [オフラインビルド](#virtualbox-の-bootc-ゲスト-ホストオンリーアダプターだけの-vm-でビルドする)の手順 2〜5 でホストに鍵を作り、[Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)の手順 5〜7 で登録する
- 実行場所:
  - ゲスト: VirtualBox の VM の中の AlmaLinux Atomic Desktop（GNOME）にログインし、端末を開いた自分のユーザーの bash。手順 1〜3・5〜8・10。`sudo -i` した root のシェルでは行わない
  - ホスト: ホストのデスクトップの、VM のウィンドウ（メニューの操作）。手順 4・9（手順 4 の CD の挿入は、ホスト側の操作）
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/virtualbox-guest-bootc.md)・[参考資料](reference/virtualbox-guest-bootc.md)・[注意点](extra/virtualbox-guest-bootc.md)
- この項の手順 1 で変数を設定したシェルに貼る。新しい端末を開いたら、この項の手順 1 を貼り直す
- **手順 7 で再起動する**。手順 6 はビルドが終わるのを待ってから次を貼る
- **インターネットに出られないホストオンリーだけの VM は、手順 6 の代わりに[オフラインビルド](#virtualbox-の-bootc-ゲスト-ホストオンリーアダプターだけの-vm-でビルドする)を通す**
  - イメージと署名鍵はホストで作り、イメージを ssh で VM へ運ぶ
- **切り替えた後は、`sudo bootc upgrade` だけでは OS が上がらない**（[更新](#virtualbox-の-bootc-ゲスト-更新)の手順でビルドし直す）
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
   - 手順 6 と[更新](#virtualbox-の-bootc-ゲスト-更新)で使う

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
   # VirtualBox Guest Additions を焼き込んだ派生イメージ（VirtualBox の bootc ゲスト）
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
   - `Identification: VirtualBox 7.2.20 Guest Additions for Linux` の版が、ホストの「ヘルプ」→「VirtualBox について」（Help → About VirtualBox...）と同じならよい
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
     - Guest Additions が動く VM でビルドし直すときの `mknod: /dev/vboxguest: Operation not permitted` と `installer exit=2` は正常
       - カーネルも新しくなったとき（ベースの更新）は、`mknod` の行が出て `installer exit=1` になる
   - 最後に次が出ればよい
     - `vboxguest.ko:`・`vboxsf.ko:`・`vboxvideo.ko:` にイメージのカーネルの版が出る。Secure Boot なら `signer=Local kernel module signing key` も出る
     - kernel-rt のイメージなら、版の末尾が `+rt` で、`SMP preempt_rt` になる
     - `enabled` が 2 行
     - `Checks passed: 13`（`Warnings:` の行が無い）と `Successfully tagged localhost/vbox-ga:latest`
   - `could not parse secrets: faccessat /var/lib/shim-signed/mok/MOK.priv: no such file or directory` で止まったら、署名鍵が無い
   - Secure Boot の[署名鍵](almalinux-setup.md#secure-boot-の署名鍵)を作ってからやり直す
   - `No match for argument: kernel-devel-uname-r = …+rt` で止まったら、kernel-rt のイメージで `rt` のリポジトリが有効になっていない
   - `pinging container registry quay.io` と `dial tcp: lookup quay.io` で止まったら、VM がインターネットに出られない
   - [オフラインビルド](#virtualbox-の-bootc-ゲスト-ホストオンリーアダプターだけの-vm-でビルドする)でビルドする
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

   - モジュールが読み込まれていないときは、[Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)の手順 7 で鍵が登録されているか見る（手順 8 の補足の表）

#### VirtualBox の bootc ゲスト: ホストオンリーアダプターだけの VM でビルドする

- ホストオンリーだけでインターネットに出られない VM は、[VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 6 の代わりに通す。その項の手順 1〜5 と 7 以降は同じ
  - そのままの[VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 6 は、ベースのイメージを取り込めずに `pinging container registry quay.io: Get "https://quay.io/v2/": dial tcp: lookup quay.io …` で止まる
- ホスト（VirtualBox を動かしている PC）で派生イメージをビルドし、1 つのファイルにして ssh で VM に運ぶ。VM はインターネットに出ない
  - ビルドの材料（[VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 3 の Containerfile と、同じ項の手順 5 でコピーしたインストーラ）は、VM から写して使う
- 前提:
  - VM の中で[VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 1〜5 を通してある
  - Secure Boot が有効な VM は、VM の中で[Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)の手順 3 まで通してある
  - ホストは、インターネットに出られ、x86_64 の AlmaLinux 10 の rootless の podman が動くこと（[Podman](containers.md#podman)の手順 1〜6）
    - Windows ホストでは WSL の AlmaLinux 10 の端末で行う。既定の NAT でホストオンリーの VM に届くことを確認済み
    - [WSL のミラーネットワーク](windows-setup.md#wsl-のネットワークをミラーにする)での接続は未確認
- 実行場所:
  - ゲスト: VirtualBox の VM の中の AlmaLinux Atomic Desktop（GNOME）にログインし、端末を開いた自分のユーザーの bash。この項の手順 1・2・5・10
  - ホスト: VirtualBox を動かしている PC の、自分のユーザーの端末（bash）。Windows のホストでは WSL の AlmaLinux 10 の端末。この項の手順 3・4・6〜9・11・12
- Secure Boot なら[署名鍵](almalinux-setup.md#secure-boot-の署名鍵)の手順 4 も、この項の手順 4・5 で代える
- [VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 6 と違うところ:
  - ベースのイメージはホストが取り込む。署名は、VM の `policy.json` と公開鍵を写して、ホストで同じように確かめる（この項の手順 7）
  - Secure Boot の鍵はホストで作り、秘密鍵はホストに置く。VM には証明書だけを置く（この項の手順 4・5。登録は [Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)の手順 5〜7）
  - OS を上げるたびに、ベースを含むイメージの全体（`podman save` のファイルで約 4.8G）を VM に運ぶ
- ホストオンリーアダプターだけの VM で OS を上げるときは、[更新](#virtualbox-の-bootc-ゲスト-更新)の手順 3 の代わりに、この項の手順 6・8〜10

1. VM の端末で、変数を設定する（既定のままでよい）。

   ```bash
   BASE_IMAGE=quay.io/almalinuxorg/atomic-desktop-gnome:latest   # 元のイメージ（「VirtualBox の bootc ゲスト」の手順 2 の Booted image）
   printf '\n\033[7m 確認 \033[0m\n'
   echo "BASE_IMAGE = ${BASE_IMAGE}"
   ```

   - [VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 1 と同じ値を入れる
   - 新しい端末を開いたら、この手順を貼り直す

1. VM の端末で、ホストオンリーアダプターの IP を見る。

   ```bash
   ip -4 -br addr show scope global
   ```

   - `enp0s3  UP  192.168.56.101/24` のような行の IP（`/24` の前）が、この項の手順 3 で使う `<VM_IP>`
   - 何も出ないときは、有線の接続が上がっていない。`nmcli -t -f NAME,DEVICE connection show` で接続の名前を見て、`sudo nmcli connection up <名前>` で上げる
     - 自動接続しない VM は `sudo nmcli connection modify <名前> connection.autoconnect yes` で有効にする（[インストール時の状態](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/virtualbox-guest-bootc.md#実施前の状態)）

1. ホストの端末で、変数を設定する（`VM_SSH` は必ず値を入れる）。

   ```bash
   VM_SSH=   # ← VM のユーザー名と、この項の手順 2 の IP（<USER>@<VM_IP>）
   ```

   ```bash
   BASE_IMAGE=quay.io/almalinuxorg/atomic-desktop-gnome:latest   # 元のイメージ（「VirtualBox の bootc ゲスト」の手順 2 の Booted image）
   printf '\n\033[7m 確認 \033[0m\n'
   echo "VM_SSH = ${VM_SSH}"
   echo "BASE_IMAGE = ${BASE_IMAGE}"
   ```

   - `BASE_IMAGE` は、この項の手順 1 と同じ値を入れる（この項の手順 8・9・12 で使う）
   - 最後の 2 行で値を読み戻して確かめる
   - 新しい端末を開いたら、この手順の 2 つのブロックを貼り直す
   - Windows のホストでは、WSL の AlmaLinux 10 の端末を開いて貼る

1. Secure Boot が有効なときだけ、ホストの端末で署名用の鍵を作り、証明書を VM に送る。

   ```bash
   if [ -z "${VM_SSH}" ]; then
     echo 'VM_SSH が空のまま。この項の手順 3 を貼り直す' >&2
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

   - Secure Boot が有効かは、VM で [Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)の手順 3 の `mokutil --sb-state` で見たもの
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
   - 置き場所は [Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)の手順 4 と同じなので、同じ項の手順 7 はそのまま使える
   - `MOK.priv` も並ぶなら、[Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)の手順 4 で VM に作った鍵が残っている。この項ではホストの鍵で署名するので、使われない
   - **一時パスワードを 2 回聞かれる**（[Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)の手順 6 の MokManager で 1 回だけ使う。本書には残さない）
   - 続けて、VM で [Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)の手順 5〜7 を行い、再起動して MokManager で登録し、`--test-key` で確かめる。ホストの端末は、開いたままにしておく
   - [Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)の手順 7 の後、この項の手順 6 はホストの端末で貼る（VM の端末を開き直したら、この項の手順 1 を貼り直す）
   - **次の手順（[Secure Boot の署名鍵](almalinux-setup.md#secure-boot-の署名鍵)の手順 5）は、一時パスワードに答えてから貼る**（続けて貼ると答えとして食われる）

1. ホストの端末で、ビルドの材料と、署名を確かめる設定を VM から写す。

   ```bash
   if [ -z "${VM_SSH}" ]; then
     echo 'VM_SSH が空のまま。この項の手順 3 を貼り直す' >&2
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
     echo '前回の設定の控えがある。上書きせず、この項の手順 12 で確認してからやり直す' >&2
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
     echo '設定のコピーに失敗した。次へ進まず、この項の手順 12 で残ったファイルを確認する' >&2
   fi
   ```

   - `quay.io/almalinuxorg/atomic-desktop-gnome` の行が `sigstoreSigned` ならよい
   - 自分のユーザーの podman のすべてに効く（`/etc/containers` の設定の代わりに読まれる）
   - 「すでにある」と出たときは何も変えずに止まる。[既存の署名設定への追加](#virtualbox-の-bootc-ゲスト-既存のコンテナ署名設定に追加する)を行ってから、この項の手順 8 へ進む
   - 新規に置く設定の控えは `~/vbox-ga-host/containers-config-created` に残す
   - コピーや `podman image trust show` が失敗したときは、次の手順に進まない

1. ホストの端末で、派生イメージをビルドする（[VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 6 の代わりに）。

   ```bash
   build_args=(--pull=newer)
   if [ -e ~/vbox-ga-mok/MOK.priv ]; then
     build_args+=(--build-arg MOK_SIGN=1 --secret "id=mok_priv,src=${HOME}/vbox-ga-mok/MOK.priv" --secret "id=mok_der,src=${HOME}/vbox-ga-mok/MOK.der")
   fi
   printf '\n\033[7m 確認 \033[0m\n'
   podman build "${build_args[@]}" --build-arg "BASE_IMAGE=${BASE_IMAGE:?この項の手順 3 の BASE_IMAGE が空のまま。値を入れて貼り直す}" -t localhost/vbox-ga:latest ~/vbox-ga-host/vbox-ga-image
   ```

   - [通常の導入](#virtualbox-の-bootc-ゲスト)の手順 6 と同じ `Storing signatures` と 3 モジュールの行が出る
   - `enabled` が 2 行、`Checks passed: 13`、`Successfully tagged localhost/vbox-ga:latest` も出ればよい
   - ホストに鍵（`~/vbox-ga-mok/MOK.priv`）があるときだけ、モジュールに署名する（3 行が `signer=Local kernel module signing key`）
   - 途中の `depmod: ERROR`・`depmod: FATAL`、`installer exit=1`、`libsemanage.semanage_rename: WARNING: … Invalid cross-device link …` は、失敗ではない（参考資料を参照）
   - **次の手順は、`Successfully tagged` が出てから貼る**

1. ホストの端末で、派生イメージとベースのイメージを 1 つのファイルにして、VM に送る。

   ```bash
   if [ -z "${VM_SSH}" ] || [ -z "${BASE_IMAGE}" ]; then
     echo 'VM_SSH か BASE_IMAGE が空のまま。この項の手順 3 を貼り直す' >&2
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

   - `Loaded image: localhost/vbox-ga:latest` と `Loaded image: quay.io/almalinuxorg/atomic-desktop-gnome:latest` が出る
   - `sudo podman images` に、この 2 つが並べばよい
   - VM の `/var` には、ファイル（約 4.8G）の分も一時的に要る（[VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 2 の空きの目安より多く）
   - 続けて[VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 7 から先を行う
   - **[VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 7 は、`Loaded image:` が出てから貼る**

1. 署名設定のコピーやビルドに失敗して復旧するときは、ホストの端末で変数を設定し直す。

   - この項の手順 3 の 2 つのブロックを貼り直し、`BASE_IMAGE` を確かめる
   - 続けて、この項の手順 12 を行う

1. 署名設定のコピーやビルドに失敗したときは、ホストの端末で、ビルドに使ったものと署名を確かめる設定を片付ける。

   ```bash
   if [ -z "${BASE_IMAGE}" ]; then
     echo 'BASE_IMAGE が空のまま。この項の手順 3 を貼り直す' >&2
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
     - 手動で戻した後に、ビルドの材料を `rm -rf ~/vbox-ga-host` で消し、イメージを `podman rmi localhost/vbox-ga:latest "${BASE_IMAGE:?この項の手順 3 を貼り直す}"` で消す
     - コピーの途中で失敗した場合も、残ったファイルを確かめてから戻す。比較自体が失敗した場合は原因を直すか、同じく手で確認する
   - Secure Boot の鍵（`~/vbox-ga-mok`）は残る

#### VirtualBox の bootc ゲスト: 共有フォルダーを使う

- 共有フォルダーを足すと、VM の中で `vboxsf` のモジュールが読み込まれ、フォルダーが `/media/sf_<名前>` に自動でマウントされる
  - `findmnt` の表示は `/run/media/sf_<名前>`（Atomic Desktop では `/media` が `run/media` へのリンク）
- 読み書きできるのは `vboxsf` グループのユーザーだけ
- 前提: [VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)を通し、Guest Additions が動いている
- 実行場所:
  - ホスト: VirtualBox マネージャーか `VBoxManage`（この項の手順 1）
  - ゲスト: VirtualBox の VM の中の AlmaLinux Atomic Desktop（GNOME）にログインし、端末を開いた自分のユーザーの bash（この項の手順 2〜4）

1. ホストの VirtualBox で、VM の設定の「共有フォルダー」にフォルダーを足す。

   - 「自動マウント」にチェックを入れる（英語の表示では Shared Folders と Auto-mount）
   - VM を動かしたままでも足せる
   - 動いている VM に共有フォルダを足す場合は `VBoxManage sharedfolder add --automount --transient` を使う。`--transient` が無いと `is already locked for a session` で断られる

1. 自分を `vboxsf` グループに入れる。

   ```bash
   sudo usermod -aG vboxsf "${USER}"
   ```

   - **効くのはログインし直してから**（この項の手順 3）

1. GNOME からログアウトして、ログインし直す。

   - **次の手順は、新しい端末を開いてから貼る**

1. グループと共有フォルダーを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   id -nG | tr ' ' '\n' | grep -x vboxsf
   findmnt -t vboxsf
   ```

   - `vboxsf` の行と、共有フォルダーのマウントの行（`/run/media/sf_<名前>` の `vboxsf`）が出ればよい
   - `vboxsf` が出ないときは、VM を再起動してログインし直し、この手順を貼り直す

#### VirtualBox の bootc ゲスト: 更新

- 切り替えた VM の OS（ベースのイメージ）や Guest Additions を上げるときに、派生イメージをビルドし直して取り込む
- 前提: [VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)を通し、`localhost/vbox-ga:latest` に切り替えてある
- 実行場所:
  - ゲスト: VirtualBox の VM の中の AlmaLinux Atomic Desktop（GNOME）にログインし、端末を開いた自分のユーザーの bash（この項の手順 1〜4）
  - ホスト: ホストのデスクトップの、VM のウィンドウ（この項の手順 2 の CD の挿入）
  - ホストオンリーだけの VM でホストでビルドし直すときは、ホストの端末（下の箇条書き）
- OS（ベースのイメージ）を上げる: この項の手順 1・3・4。カーネルが変わっても、同じ手順でモジュールが作り直される
  - 自作の kernel-rt のイメージは、先にレジストリのイメージを新しくしておく（この項の手順 3 は、レジストリにあるものを取り込む）
- ホストの VirtualBox を上げた（Guest Additions の版が変わった）: この項の手順 1 から
- ホストオンリーだけの VM は、この項の手順 3 の代わりに[オフラインビルド](#virtualbox-の-bootc-ゲスト-ホストオンリーアダプターだけの-vm-でビルドする)の手順 6・8〜10 でビルドし直し、VM へ運ぶ
- ホストの端末で、先に[オフラインビルド](#virtualbox-の-bootc-ゲスト-ホストオンリーアダプターだけの-vm-でビルドする)の手順 3 を貼る
- Secure Boot の鍵を作り直したときは、この項の手順 3 で `sudo podman build` に `--no-cache` を足す（ビルドのキャッシュは、渡した鍵の中身の違いを見分けない。ホストでビルドするときも同じ）
- 古いイメージは `sudo podman image prune` で消せる（`[y/N]` を聞く）

> [!WARNING]
> **切り替えた後は、`sudo bootc upgrade` だけでは OS（ベースのイメージ）が上がらない**。bootc が見に行くのは、この VM の中の `localhost/vbox-ga:latest` だけになる。OS を上げるときも、この項の手順 3・4 でビルドし直す。

1. 変数を設定する（既定のままでよい）。

   ```bash
   BASE_IMAGE=quay.io/almalinuxorg/atomic-desktop-gnome:latest   # 元のイメージ（「VirtualBox の bootc ゲスト」の手順 2 の Booted image）
   printf '\n\033[7m 確認 \033[0m\n'
   echo "BASE_IMAGE = ${BASE_IMAGE}"
   ```

   - [VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 1 と同じ値を入れる
   - この項の手順 3 で使う
   - 新しい端末を開いたら、この手順を貼り直す

1. ホストの VirtualBox を上げたときだけ、CD を入れ直して[VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 5 を貼る。

   - VM のウィンドウのメニューの「デバイス」→「Guest Additions CD イメージを挿入」（英語の表示では Devices → Insert Guest Additions CD image...）で、新しい版の CD を入れる
   - [VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 5 の `Identification:` が、ホストの新しい版になっていればよい

1. この項の手順 1 を貼ったシェルで、[VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 6 を貼り直す。

   - 何も変わっていなければ、ビルドのキャッシュが使われて同じイメージになる（`Using cache` が 4 行並び、最後のイメージ ID が同じ）
   - Containerfile を置き直したとき（[VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 3）は、Guest Additions の段をやり直す
   - **次の手順は、`Successfully tagged` が出てから貼る**

1. 新しいイメージを取り込んで、再起動する。

   ```bash
   sudo bootc upgrade --apply
   ```

   - イメージが変わっていれば、`Queued for next boot:` と入れ替わった層の数を出してから再起動する
   - 変わっていなければ、`No changes in ...` と `No update available.` を出して、再起動しない
   - 起動したら、[VirtualBox の bootc ゲスト](#virtualbox-の-bootc-ゲスト)の手順 8・9 で確かめる

#### VirtualBox の bootc ゲスト: 既存のコンテナ署名設定に追加する

- ホストの `~/.config/containers` に既にある署名の設定へ、VM の Atomic Desktop の署名を確かめる設定を手で足す
- 前提: [ホストオンリーアダプターだけの VM でビルドする](#virtualbox-の-bootc-ゲスト-ホストオンリーアダプターだけの-vm-でビルドする)の手順 7 で「すでにある」と出た場合だけ行う（VM から写した `~/vbox-ga-host` を使う）
- 実行場所: ホスト（VirtualBox を動かしている PC）の、自分のユーザーの端末とエディタ。Windows のホストでは WSL の AlmaLinux 10

1. 変更前の設定と公開鍵を別の場所に退避し、今回追加・変更するファイルを控える。既存の同名の鍵や設定は上書きしない。

1. 公開鍵は `~/vbox-ga-host/etc/pki/containers/*.pub` から `~/.config/containers/pki` に写す。同名があるときは内容を照合し、別の鍵なら名前と `policy.json` の参照先を合わせて分ける。

1. `policy.json` があるなら、その `transports` の `docker` に、VM の `quay.io/almalinuxorg/atomic-desktop-gnome` の項目を足す。無いなら VM のファイルを写す。どちらも鍵のパスを `~/.config/containers/pki/` に合わせる。

1. `registries.d` があるなら、VM の `almalinuxorg-atomic-desktop-gnome.yaml` を、同名が無いことを確かめて足す。無いなら VM の `registries.d` をまるごと写す（1 つでも置くと、`/etc/containers/registries.d` が読まれなくなるため）。

---

### kvm-container

- qemu-kvm と libvirt を systemd のコンテナに収め、このホストで VM を動かす（[kvm-container](https://github.com/ryo-aoki-pc/kvm-container)）

#### kvm-container を導入する

- podman と git だけのホストに kvm-container のリポジトリを clone し、イメージをビルドしてコンテナを起動する
- 前提: [ログインと sudo](almalinux-setup.md#ログインと-sudo)を通してある（ホストの sudo がパスワードなしで使える）。podman と git は、この項の手順 2 で入れる
  - CPU の SVM（AMD）/ VT-x（Intel）が有効であること。VM 内なら外側からネストした仮想化が提供されていること
  - VM 作成は x86_64 用
- 実行場所: 対象ホストの一般ユーザーの bash（画面を使う場合は GNOME の端末、画面なしの場合は SSH のシェル）。root の権限は、コマンドに付けた `sudo` だけで使う
- [仕様](https://github.com/ryo-aoki-pc/kvm-container/blob/main/docs/SPEC.md)・[参照情報](https://github.com/ryo-aoki-pc/kvm-container/blob/main/docs/reference/setup.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/repos/kvm-container/docs/verification/setup.md)
- 既に clone したリポジトリやホスト自身の libvirt がある PC では、この項の手順 4・5 の確認を省かない
- ホストごとに 1 度だけ行う。2 回目からは[VM を使う](#kvm-container-の-vm-を使う)から始める

1. 変数を設定する（既定のままでよい）。

   ```bash
   REPO=~/kvm-container   # clone 先。ユーザーのホームディレクトリ配下にする。<REPO>
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'REPO = %s\n' "${REPO}"
   [ ! -d "${REPO}" ] || cd "${REPO}"
   ```

   - `REPO` は、既定のままでよければそのまま貼る
   - clone 先を `~/kvm-container` 以外にするときだけ `REPO` を変える。ユーザーのホームディレクトリ配下にする
   - 値を読み戻して確かめる
   - clone 済みなら、最後の行でリポジトリ直下に移る
   - **新しいシェルを開いたら** (SSH を張り直したあとも)、この手順を貼り直してから先へ進む


1. podman と git を入れる。

   ```bash
   sudo dnf install podman git
   ```

   - ホストに入れるのは podman と git だけ (podman は root で使う)
   - qemu・libvirt・virt-viewer はホストに入れない
   - **次の手順は、`[y/N]` に答えてインストールが終わってから貼る** (続けて貼ると答えとして食われる)


1. podman と git が入ったか確かめる。

   ```bash
   rpm -q podman git
   ```

   - 2 行とも `podman-…` / `git-…` の版が出ればよい

1. リポジトリを clone する。

   ```bash
   [ -e "${REPO:?この項の手順 1 の REPO が空のまま。この項の手順 1 を貼り直す}/kvm.sh" ] || git clone https://github.com/ryo-aoki-pc/kvm-container.git "${REPO}"
   cd "${REPO}" && ls -l kvm.sh
   ```

   - `kvm.sh` の行 (実行権限付き) が出ればよい
   - すでに clone してあれば、`git clone` は飛ばされる
   - `already exists and is not an empty directory` で止まったら、`REPO` を変えてこの項の手順 1 から貼り直す
   - 以降の手順は、このディレクトリ (リポジトリ直下) で貼る


1. ホストの SELinux と画面の有無を確かめる。

   ```bash
   getenforce
   env | grep -E 'DISPLAY|WAYLAND|XDG_RUNTIME|XAUTH'
   if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then echo '画面あり: kvm と kvm-gui を使う'; else echo '画面なし: kvm だけを使う'; fi
   ```

   - `getenforce` は `Enforcing` のままでよい
   - GNOME の端末なら `WAYLAND_DISPLAY` / `DISPLAY` / `XDG_RUNTIME_DIR` / `XAUTHORITY` の行が並び、`画面あり` と出る
   - ディスプレイの無いホスト (SSH のみ) では `画面なし` と出る。これで正常で、以降の手順は `kvm` だけを扱う
   - **注意**: GNOME のホストで `画面なし` と出たら、SSH か `sudo -i` のシェルで貼っている。GNOME の端末を開き、この項の手順 1 から貼り直す
   - ファームウェアで SVM (AMD) / VT-x (Intel) を有効にしておく
   - ホスト自身の libvirt は停止しておく (`virbr0` / 192.168.122.0/24 の衝突を避ける)
   - 画面があっても使わない場合は、`KVM_HOST=headless` を各 `up` の前に付け、この項の手順 7 は飛ばす


1. `kvm` のイメージをビルドする。

   ```bash
   cd "${REPO:?この項の手順 1 の REPO が空のまま。値を入れて貼り直す}" && ./kvm.sh build kvm
   ```

   - 時間がかかる (AlmaLinux 10 minimal のイメージ取得と `microdnf` でのパッケージ導入)
   - ビルドの最後に `Successfully tagged localhost/kvm-container/kvm:latest` が出ればよい
   - ビルドが失敗したら `./kvm.sh build kvm 2>&1 | tee build.log` のように出力を残して原因を確認する
   - **次の手順は、ビルドが終わってから貼る**


1. GUI のイメージをビルドする (画面の無いホストでは何もしない)。

   ```bash
   [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] || ./kvm.sh build gui
   ```

   - 画面のあるホストでは GUI のイメージも作る
   - ビルドの最後に `Successfully tagged localhost/kvm-container/gui:latest` が出ればよい
   - **次の手順は、ビルドが終わってから貼る**

1. コンテナを起動する。

   ```bash
   ./kvm.sh up
   ```

   - 初回は `>> seeding …/data/var-libvirt from image …` のように `data/` の初期化が 3 回出る
   - `>> ready. VMs: …` が出れば `kvm` は起動している
   - 画面のあるホストでは、続けて `>> kvm-gui started. VM screen: ./kvm.sh viewer [VM]` が出る
   - 画面の無いホストでは `>> no display found: GUI disabled (manage the VMs with ./kvm.sh virsh / virt-install)` が出る。これで正常
   - `!! /dev/kvm not found …` や `modprobe: ERROR: could not insert 'kvm_amd': Operation not supported` で止まったら、SVM（AMD）/ VT-x（Intel）を見直す
   - VM 内なら外側のハイパーバイザーのネストした仮想化も確かめる。`--privileged` だけでは CPU の仮想化支援は増えない
   - `!! virbr0 already exists on the host …` は警告だけで、`kvm` は起動してしまう
   - 前回のコンテナの残骸なら `./kvm.sh down` → `sudo ip link del virbr0` → `./kvm.sh up` の順にやり直す
   - **次の手順は、`>> ready.` が出てから貼る**


1. 両コンテナと、コンテナをまたぐ libvirt の接続を確かめる。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo podman exec kvm systemctl is-system-running         # running (degraded ではない)
     sudo podman exec kvm ls -l /run/libvirt/virtqemud-sock   # srw-rw---- root libvirt
     ./kvm.sh virsh list --all                                # 空の一覧 (ヘッダだけ) で可
     if sudo podman container exists kvm-gui; then
       sudo podman exec kvm-gui systemctl is-system-running                          # running
       sudo podman exec kvm-gui runuser -u "$USER" -- virsh -c qemu:///system list   # 一般ユーザーが kvm-gui から kvm の libvirt に接続できること
     else
       echo 'kvm-gui が無い (画面なし): skip'
     fi
   }
   ```

   - `kvm` の `systemctl is-system-running` が `running` (`degraded` ではない)
   - `virtqemud-sock` が `srw-rw---- root libvirt`
   - `virsh list --all` は空の一覧 (ヘッダだけ) で可
   - 画面のあるホストでは `kvm-gui` も確かめる。画面の無いホストでは `skip` と出るだけ
   - `degraded` なら `./kvm.sh shell` (`kvm-gui` は `./kvm.sh shell gui`) で `systemctl --failed` を見る
   - ログは `./kvm.sh logs` (`kvm-gui` は `./kvm.sh logs gui`)
   - この後は[VM を作る](#kvm-container-で-vm-を作る)に進む

#### kvm-container で VM を作る

- ISO を `data/` に置き、`virt-install` で VM (ディスクは SATA の SSD、NIC は e1000e) を作って、virt-viewer の画面でインストールする
- 前提: [kvm-container を導入する](#kvm-container-を導入する)を通してある。コンテナが止まっていれば、先に[VM を使う](#kvm-container-の-vm-を使う)の手順 1・2 で起動する
  - VM をホストのブリッジにつなぐなら、先に[VM をホストのブリッジにつなぐ](#kvm-container-の-vm-をホストのブリッジにつなぐ)の手順 1〜8 を行う
- 実行場所: 対象ホストの一般ユーザーの bash（画面を使う場合は GNOME の端末、画面なしの場合は SSH のシェル）。root の権限は、コマンドに付けた `sudo` だけで使う
- x86_64 のホストで行う。この項の手順 4 で使う SATA と e1000e は、aarch64 の qemu-kvm には無い
- 2 台目からは、この項の手順 1 の `VM_NAME` (ISO を変えるなら `ISO` も) を変えて、この項の手順 1 から貼る

> [!CAUTION]
> - ブリッジを使うホストは、この項の手順 5 の最初のブロックだけを貼り、次のブロックは貼らない
> - 先に、この項の手順 1 の `BRIDGE` に利用中の名前を入れる。空で止まったら、この項の手順 1 で値を入れてから、最初のブロックを貼り直す

1. 変数を設定する（`ISO` は必ず値を入れる）。

   ```bash
   ISO=   # ← ダウンロードした ISO のホスト側パス (例: ~/Downloads/AlmaLinux-10-latest-x86_64-dvd.iso)。<ISO>
   ```

   ```bash
   REPO=~/kvm-container   # clone 先。ユーザーのホームディレクトリ配下にする。<REPO>
   VM_NAME=alma10         # VM 名。ディスクは /var/lib/libvirt/images/${VM_NAME}.qcow2 になる。<VM_NAME>
   VM_MEMORY=4096         # メモリ (MiB)。<VM_MEMORY>
   VM_VCPUS=2             # vCPU 数。<VM_VCPUS>
   VM_DISK=20             # ディスクの大きさ (GiB)。<VM_DISK>
   VM_NETWORK=default     # VM をつなぐ libvirt ネットワーク。ブリッジの項を通したホストで LAN に直接つなぐなら bridged。<VM_NETWORK>
   BRIDGE=br0             # ブリッジの名前 (ブリッジを使うホストだけが使う)。<BRIDGE>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in ISO REPO VM_NAME VM_MEMORY VM_VCPUS VM_DISK VM_NETWORK BRIDGE; do
     printf '%-10s = %s\n' "$v" "${!v}"
   done
   [ ! -d "${REPO}" ] || cd "${REPO}"
   ```

   - `ISO` には、ホストにダウンロードしておいた ISO の絶対パスを入れる (`~` 始まりも可。代入値を引用符で囲むと `~` は展開されない)
   - `REPO` から `BRIDGE` までは、既定のままでよければそのまま貼る
   - `REPO` は、[kvm-container を導入する](#kvm-container-を導入する)の手順 1 と同じ値を入れる
   - `VM_NETWORK` は、[VM をホストのブリッジにつなぐ](#kvm-container-の-vm-をホストのブリッジにつなぐ)を通したホストで LAN に直接つなぐなら `bridged` にする
   - `BRIDGE` は、ブリッジを使うホストだけが使う。[VM をホストのブリッジにつなぐ](#kvm-container-の-vm-をホストのブリッジにつなぐ)の手順 1 と同じ値を入れる
   - 値を読み戻して確かめる
   - 最後の行でリポジトリ直下に移る
   - **新しいシェルを開いたら** (SSH を張り直したあとも)、この手順の 2 つのブロックを貼り直してから先へ進む

1. ISO があるか確かめ、`data/` にコピーする。

   ```bash
   ls -l "${ISO:?この項の手順 1 の ISO が空のまま。値を入れて貼り直す}"
   sudo cp "${ISO:?この項の手順 1 の ISO が空のまま。値を入れて貼り直す}" data/var-libvirt/images/
   ```

   - `ls -l` が `No such file or directory` なら、この項の手順 1 の `ISO` を直して貼り直してから、この手順を貼り直す
   - ISO の大きさによっては時間がかかる
   - **次の手順は、`cp` が終わってから貼る**


1. ISO が置けたか確かめる。

   ```bash
   sudo ls -l data/var-libvirt/images/   # ISO が root 所有で置かれている
   ```

   - ISO が root 所有で置かれていればよい

1. ディスクを SATA の SSD、NIC を e1000e にして VM を作る。

   ```bash
   ./kvm.sh virt-install --name "${VM_NAME:?この項の手順 1 の VM_NAME が空のまま。値を入れて貼り直す}" --memory "${VM_MEMORY}" --vcpus "${VM_VCPUS}" \
     --machine q35 --disk "size=${VM_DISK},bus=sata,target.rotation_rate=1" \
     --cdrom "/var/lib/libvirt/images/$(basename "${ISO:?この項の手順 1 の ISO が空のまま。値を入れて貼り直す}")" --osinfo detect=on,require=off \
     --network "network=${VM_NETWORK:?この項の手順 1 の VM_NETWORK が空のまま。この項の手順 1 を貼り直す},model=e1000e" --graphics vnc --noautoconsole
   ```

   - `virt-install` はすぐ戻り、VM はインストーラが起動した状態 (`running`) になる
   - ディスクは `/var/lib/libvirt/images/${VM_NAME}.qcow2` (ホストの `data/var-libvirt/images/`) に作られる
   - ディスクは SATA の SSD (`sda`)、NIC は `e1000e` になる (確かめるのはこの項の手順 6)
   - `VM_NETWORK=bridged` でネットワークが見つからないと言われたら、[VM をホストのブリッジにつなぐ](#kvm-container-の-vm-をホストのブリッジにつなぐ)の手順 6・7 (`KVM_BRIDGE` を付けた `up`) を先に行う
   - **注意**: aarch64 のホストでは通らない想定。qemu-kvm に SATA と e1000e が無い


1. virt-viewer で画面を開き、インストールする（ブリッジを使うホストは最初のブロック、使わないホストは次のブロック。どちらか一方だけを貼る）。

   ```bash
   KVM_BRIDGE="${BRIDGE:?この項の手順 1 の BRIDGE を設定する}" ./kvm.sh viewer "${VM_NAME}"
   ```

   ```bash
   ./kvm.sh viewer "${VM_NAME}"
   ```

   - ホストのデスクトップに virt-viewer のウィンドウが開き、インストーラの画面が出る。ウィンドウの中でインストールを進める
   - インストーラが最後に再起動すると VM は `shut off` になり、ウィンドウも閉じる
   - **注意**: ディスプレイの無いホストでは `!! no display found ...` で終わる (終了コード 2)。ゲストにはシリアルコンソールかネットワーク経由でアクセスする
   - シリアルコンソールは `./kvm.sh virsh console "${VM_NAME}"` で開き、`Ctrl+]` で抜ける。ISO のインストーラがシリアルに出るかは ISO による
   - **次の手順は、VM が `shut off` になるか、ウィンドウを閉じてから貼る** (`viewer` はウィンドウが閉じるまで戻らない)


1. VM ができ、ディスクが SATA の SSD、NIC が e1000e か確かめる。

   ```bash
   ./kvm.sh virsh list --all                       # VM_NAME の行がある (インストール完了後は shut off)
   ./kvm.sh virsh domblklist "${VM_NAME}"          # sda = /var/lib/libvirt/images/${VM_NAME}.qcow2。sdb はインストール中は ISO、終了後は空 (-)
   ./kvm.sh virsh dumpxml "${VM_NAME}" | grep "bus='sata'"   # sda の行に rotation_rate='1' (SATA の SSD)
   ./kvm.sh virsh domiflist "${VM_NAME}"           # Model が e1000e
   sudo ls -l "${REPO}/data/var-libvirt/images/"   # ${VM_NAME}.qcow2 と ISO がある (root / qemu 所有)
   ```

   - `VM_NAME` の行があり、インストール完了後は `shut off`
   - `domblklist` の `sda` が `/var/lib/libvirt/images/${VM_NAME}.qcow2`。`sdb` はインストール中は ISO、終了後は空 (`-`)
   - `grep` の出力に `<target dev='sda' bus='sata' rotation_rate='1'/>` がある
   - `domiflist` の `Model` が `e1000e`
   - `data/var-libvirt/images/` に `${VM_NAME}.qcow2` と ISO がある (root / qemu 所有)


1. VM が `up` で自動起動するように設定する。

   ```bash
   ./kvm.sh virsh autostart "${VM_NAME}"           # up で自動起動する (解除は --disable)
   ```

   - 以後、`kvm` を起動するたびに (`./kvm.sh up`)、この VM も起動する
   - 自動起動させない VM では、`--disable` を付けて貼り直す
   - `down` の時点で動いていた VM は次の `up` で起動しない。`up` で起動させたい VM には、この手順の `autostart` を設定する
   - この後の起動・画面・停止は[VM を使う](#kvm-container-の-vm-を使う)

#### kvm-container の VM を使う

- コンテナと VM を起動し、画面を見て、止めるまでの流れ。ホストの起動後やログインのたびに、要る手順だけを貼る
- 前提: [kvm-container を導入する](#kvm-container-を導入する)と[VM を作る](#kvm-container-で-vm-を作る)を通してある
- 実行場所: 対象ホストの一般ユーザーの bash（画面を使う場合は GNOME の端末、画面なしの場合は SSH のシェル）。root の権限は、コマンドに付けた `sudo` だけで使う

> [!CAUTION]
> - ブリッジを使うホストは、この項の手順 2・4 の最初のブロックだけを貼り、次のブロックは貼らない
> - 先に、この項の手順 1 の `BRIDGE` に利用中の名前を入れる。空で止まったら、この項の手順 1 で値を入れてから、最初のブロックを貼り直す
> - `KVM_BRIDGE` を付けずに `kvm` を起動すると `bridged` は削除される

1. 変数を設定する（既定のままでよい）。

   ```bash
   REPO=~/kvm-container   # clone 先。ユーザーのホームディレクトリ配下にする。<REPO>
   VM_NAME=alma10         # VM 名。<VM_NAME>
   BRIDGE=br0             # ブリッジの名前 (ブリッジを使うホストだけが使う)。<BRIDGE>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in REPO VM_NAME BRIDGE; do
     printf '%-10s = %s\n' "$v" "${!v}"
   done
   [ ! -d "${REPO}" ] || cd "${REPO}"
   ```

   - `REPO` は、[kvm-container を導入する](#kvm-container-を導入する)の手順 1 と同じ値を入れる
   - `VM_NAME` は、[VM を作る](#kvm-container-で-vm-を作る)で作った VM の名前を入れる
   - `BRIDGE` は、ブリッジを使うホストだけが使う。[VM をホストのブリッジにつなぐ](#kvm-container-の-vm-をホストのブリッジにつなぐ)の手順 1 と同じ値を入れる
   - 値を読み戻して確かめる
   - 最後の行でリポジトリ直下に移る
   - **新しいシェルを開いたら** (SSH を張り直したあとも)、この手順を貼り直してから先へ進む

1. コンテナを起動する（動いていれば何もしない。ブリッジを使うホストは最初のブロック、使わないホストは次のブロック。どちらか一方だけを貼る）。

   ```bash
   cd "${REPO:?この項の手順 1 の REPO が空のまま。値を入れて貼り直す}" && KVM_BRIDGE="${BRIDGE:?この項の手順 1 の BRIDGE を設定する}" ./kvm.sh up
   ```

   ```bash
   cd "${REPO:?この項の手順 1 の REPO が空のまま。値を入れて貼り直す}" && ./kvm.sh up
   ```

   - `>> ready. VMs: …` が出れば `kvm` は起動している。動いていれば `>> kvm is already running`
   - 画面のあるホストでは、続けて `>> kvm-gui started. …` か `>> kvm-gui is already running` が出る
   - 再ログインの後なら `>> the host session has changed: recreating kvm-gui …` が出て、`kvm-gui` だけが作り直される
   - [VM を作る](#kvm-container-で-vm-を作る)の手順 7 で自動起動を設定した VM は、`kvm` の起動と一緒に起動する
   - **次の手順は、`>> ready.` か `>> kvm is already running` が出てから貼る**

1. VM を起動する。

   ```bash
   ./kvm.sh virsh start "${VM_NAME:?この項の手順 1 の VM_NAME が空のまま。値を入れて貼り直す}"
   ./kvm.sh virsh domstate "${VM_NAME}"            # running
   ```

   - `domstate` が `running` になる
   - 自動起動などで動いていれば、`start` はエラーになる。`domstate` が `running` ならそのまま先へ進む

1. VM の画面を開く（ブリッジを使うホストは最初のブロック、使わないホストは次のブロック。どちらか一方だけを貼る）。

   ```bash
   KVM_BRIDGE="${BRIDGE:?この項の手順 1 の BRIDGE を設定する}" ./kvm.sh viewer "${VM_NAME:?この項の手順 1 の VM_NAME が空のまま。値を入れて貼り直す}"
   ```

   ```bash
   ./kvm.sh viewer "${VM_NAME:?この項の手順 1 の VM_NAME が空のまま。値を入れて貼り直す}"
   ```

   - ホストのデスクトップに virt-viewer のウィンドウが開き、VM の画面が出る
   - VM が `shut off` になると、ウィンドウは自動で閉じる
   - **注意**: ディスプレイの無いホストでは `!! no display found ...` で終わる (終了コード 2)。ゲストにはシリアルコンソールかネットワーク経由でアクセスする
   - シリアルコンソールは `./kvm.sh virsh console "${VM_NAME}"` で開き、`Ctrl+]` で抜ける。ISO のインストーラがシリアルに出るかは ISO による
   - **次の手順は、ウィンドウを閉じてから貼る** (`viewer` はウィンドウが閉じるまで戻らない)

1. VM を ACPI で停止する。

   ```bash
   ./kvm.sh virsh shutdown "${VM_NAME}"            # ACPI で停止 (destroy は強制停止)
   ```

   - `shutdown` は非同期で、コマンドはすぐ戻る
   - **注意**: 起動途中の OS は ACPI に応じないことがある。OS が起動してログイン画面になってから貼る
   - **次の手順は、数十秒待ってから貼る**

1. VM が止まったか確かめる。

   ```bash
   ./kvm.sh virsh domstate "${VM_NAME}"            # shut off
   ```

   - `domstate` が `shut off` になる。`running` のままなら、少し待ってからもう一度貼る

1. ホストを再起動・シャットダウンする前だけ、コンテナを止める。

   ```bash
   ./kvm.sh down
   ```

   - 動いている VM は先に ACPI でシャットダウンされる (`>> shutting down the running VMs (up to 120 s)...`。120 秒で電源断)
   - `data/` (VM のディスク・定義) は残る
   - ホストの停止に任せると、VM が正常にシャットダウンできるとは限らない
   - ホストの起動後は、この項の手順 1 から貼る。起動するのは、自動起動を設定した VM だけ

#### kvm-container の GUI を再ログイン後に使う

- GNOME からログアウト / 再ログインしたり、ホスト側の `DISPLAY` 等を変えたりしたときに行う
- `kvm-gui` だけが作り直され、`kvm` と VM は動いたまま
- 前提: 画面のあるホストで[kvm-container を導入する](#kvm-container-を導入する)を通してあり、`kvm` のコンテナが動いている
- 実行場所: GNOME にログインし直した後に開いた、一般ユーザーの GNOME の端末（bash）。root の権限は、コマンドに付けた `sudo` だけで使う
- [VM を使う](#kvm-container-の-vm-を使う)の `up` と `viewer` も同じことをしてから動くので、それらを使うならこの項は飛ばしてよい

1. 変数を設定する（既定のままでよい）。

   ```bash
   REPO=~/kvm-container   # clone 先。ユーザーのホームディレクトリ配下にする。<REPO>
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'REPO = %s\n' "${REPO}"
   [ ! -d "${REPO}" ] || cd "${REPO}"
   ```

   - `REPO` は、[kvm-container を導入する](#kvm-container-を導入する)の手順 1 と同じ値を入れる
   - 値を読み戻して確かめる
   - 最後の行でリポジトリ直下に移る

1. `kvm-gui` を作り直す。

   ```bash
   cd "${REPO:?この項の手順 1 の REPO が空のまま。値を入れて貼り直す}" && ./kvm.sh up gui
   ```

   - `>> the host session has changed: recreating kvm-gui (the kvm container and its VMs keep running)` が出る
   - 何も変わっていなければ `>> kvm-gui is already running`
   - 引数なしの `./kvm.sh up` でも同じ (`kvm` は `>> kvm is already running` で素通りする)
   - **次の手順は、`up` が終わってから貼る**

1. VM が動いたままか確かめる。

   ```bash
   ./kvm.sh virsh list   # VM が動いたまま
   ```

   - VM が動いたままならよい

#### kvm-container の VM をホストのブリッジにつなぐ

- VM にホストと同じセグメントの IP (LAN の DHCP) を割り当てる。ホストにブリッジを作り、`KVM_BRIDGE` でそれを libvirt ネットワーク `bridged` として登録する
- 前提: [kvm-container を導入する](#kvm-container-を導入する)を通してある。[VM を作る](#kvm-container-で-vm-を作る)より前に行い、VM を作るときは `VM_NETWORK` を `bridged` にする
  - すでに VM を作ったなら、[VM を作る](#kvm-container-で-vm-を作る)では `VM_NAME` も別の名前にする (作った VM の `default` からの付け替えは扱わない)
  - ブリッジ自体はホスト側で作る (`kvm.sh` はホストのネットワーク設定を変更しない)。無線 NIC しか無いホストでは使えない
- 実行場所: **物理マシン / VM の AlmaLinux 10 + GNOME (NetworkManager) で、GNOME にログインした一般ユーザーの端末 (コンソール) から行う**。root の権限は、コマンドに付けた `sudo` だけで使う
- この項の手順 4 は NIC の接続をブリッジに切り替えるので、その NIC 越しの ssh は切れる
- NIC の元の接続名 (この項の手順 1 の `NIC_CON`) を控えてから、接続を変える (この項の手順 3・4)
- この項の手順 9 だけは、[VM を作る](#kvm-container-で-vm-を作る)の手順 4 で VM を作った後に貼る

1. 変数を設定する (`NIC` は必ず値を入れる)。

   ```bash
   NIC=   # ← ブリッジに収容する物理 NIC (ip -br link で確認。例: enp1s0)。<NIC>
   ```

   ```bash
   BRIDGE=br0             # 作るブリッジの名前。libvirt ネットワーク bridged の実体になる。<BRIDGE>
   NIC_CON=$(nmcli -g NAME,DEVICE connection show --active | awk -F: -v d="${NIC}" '$2==d{print $1}')   # NIC の現在の接続名 (自動)。<NIC_CON>
   REPO=~/kvm-container   # clone 先。ユーザーのホームディレクトリ配下にする。<REPO>
   VM_NAME=alma10         # VM 名 (この項の手順 9 で使う)。<VM_NAME>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in NIC BRIDGE NIC_CON REPO VM_NAME; do
     printf '%-8s = %s\n' "$v" "${!v}"
   done
   [ ! -d "${REPO}" ] || cd "${REPO}"
   ```

   - `NIC` には、ブリッジに収容する物理 NIC の名前を入れる (`ip -br link` で確認する)
   - `BRIDGE` は、既定のままでよければそのまま貼る
   - `NIC_CON` は `NIC` から自動で入る
   - `REPO` は、[kvm-container を導入する](#kvm-container-を導入する)の手順 1 と同じ値を入れる
   - `VM_NAME` は、[VM を作る](#kvm-container-で-vm-を作る)で作る (作った) VM の名前を入れる。この項の手順 9 で使う
   - 値を読み戻して確かめる
   - 最後の行でリポジトリ直下に移る
   - `NIC_CON` が空なら、ここで止める。`NIC` の名前が違うか、その NIC に active な接続が無い (`nmcli connection show --active` で確かめる)
   - **`NIC_CON` の値を控えておく**
   - 新しいシェルを開いたら (SSH を張り直したあとも)、この手順の 2 つのブロックを貼り直してから先へ進む。**この項の手順 4 の後に貼り直すと `NIC_CON` の値が変わる**


1. NIC が UP で、IP を持っているか確かめる。

   ```bash
   ip -br addr show "${NIC:?この項の手順 1 の NIC が空のまま。値を入れて貼り直す}"
   ```

   - NIC が `UP` で IP を持っていればよい (この IP がブリッジ側に移る)

1. ブリッジの接続と、NIC を収容する接続を作る。

   ```bash
   if [ -z "${BRIDGE}" ] || [ -z "${NIC}" ]; then echo '中断: この項の手順 1 の BRIDGE と NIC を設定してから貼り直す' >&2; else
     sudo nmcli connection add type bridge ifname "${BRIDGE}" con-name "${BRIDGE}" ipv4.method auto
     sudo nmcli connection add type bridge-slave ifname "${NIC}" master "${BRIDGE}"
   fi
   ```

   - 物理 NIC をブリッジに収容し、IP はブリッジ側に持たせる
   - **次の手順は、コンソール (GNOME の端末) から単独で貼る** (NIC の接続を切り替えるので、その NIC 越しの ssh は切れる)


1. コンソールから単独で、NIC の接続を落としてブリッジを上げる。

   ```bash
   sudo nmcli connection down "${NIC_CON:?この項の手順 1 の NIC_CON が空のまま。この項の手順 1 を貼り直す}" && sudo nmcli connection up "${BRIDGE}"
   ```

   - **注意**: この NIC 越しに ssh でつないでいるとセッションが切れ、2 つ目のコマンドが走らないことがある。コンソール (GNOME の端末) から、このブロックだけを単独で貼る
   - **次の手順は、ブリッジが上がって IP が付いてから貼る** (数秒かかる)


1. ブリッジが上がり、`kvm.sh` がブリッジと判定できるか確かめる。

   ```bash
   ip -br addr show "${BRIDGE}"                  # UP で、LAN の DHCP から IP が付く
   ls -d "/sys/class/net/${BRIDGE}/bridge"       # kvm.sh がブリッジと判定する条件 (このディレクトリがあること)
   ```

   - `ip -br addr show` でブリッジが `UP` で、LAN の DHCP から IP が付く
   - `ls -d` が `No such file or directory` なら、この項の手順 7 の `up` は `!! KVM_BRIDGE=... is not a bridge on this host` で止まる
   - そのときはブリッジの名前と状態を見直してから先へ進む


1. ブリッジを登録するため、先に `kvm` を止める。

   ```bash
   cd "${REPO:?この項の手順 1 の REPO が空のまま。この項の手順 1 を貼り直す}" && ./kvm.sh down kvm   # 動いている VM は ACPI で停止
   ```

   - 動いている VM は ACPI でシャットダウンされる (最大 120 秒待つ)
   - `kvm` が動いたままだと、この項の手順 7 の `up` は `>> kvm is already running` で戻り、`bridged` は登録されない
   - **次の手順は、`down` が終わってから貼る**


1. `KVM_BRIDGE` を付けて `kvm` を起動し、ブリッジを `bridged` として登録する。

   ```bash
   KVM_BRIDGE="${BRIDGE:?この項の手順 1 の BRIDGE が空のまま。この項の手順 1 を貼り直す}" ./kvm.sh up
   ```

   - `>> waiting for libvirt...` のあとに、`>> libvirt network "bridged" -> host bridge <ブリッジ名> (use it with …)` と出る
   - 最後に `>> ready. VMs: ...` で戻る
   - **注意**: 以後、`kvm` を起動するすべての経路に毎回 `KVM_BRIDGE=` を付ける
   - 付けずに `kvm` を起動すると `bridged` は削除される (`>> KVM_BRIDGE is not set: removing the libvirt network "bridged"`)
   - `viewer` も内部で `up` を呼ぶ。ブリッジ利用時は、[VM を作る](#kvm-container-で-vm-を作る)の手順 5・[VM を使う](#kvm-container-の-vm-を使う)の手順 4 の最初のブロックだけを貼る
   - [VM を使う](#kvm-container-の-vm-を使う)の手順 2 も最初のブロックだけを貼る
   - `./kvm.sh up gui` (再ログイン後の `kvm-gui` の作り直し) は `bridged` に影響しない。`kvm` が動いている限り `bridged` はそのまま
   - **次の手順は、`>> ready.` が出てから貼る**


1. `bridged` が登録されたか確かめる。

   ```bash
   ./kvm.sh virsh net-list                # bridged が active (default と並ぶ)
   ./kvm.sh virsh net-dumpxml bridged     # forward mode が bridge、bridge name が BRIDGE の値
   ```

   - `net-list` で `bridged` が active (`default` と並ぶ)
   - `net-list` に `bridged` が無ければ、`kvm` を止めずに `up` したか、`KVM_BRIDGE=` を付け忘れている。この項の手順 6・7 をやり直す
   - この後は[VM を作る](#kvm-container-で-vm-を作る)に進む
   - `VM_NETWORK=bridged` にすると、[VM を作る](#kvm-container-で-vm-を作る)の手順 4 は `--network network=bridged` を使う
   - VM は LAN の DHCP から IP を取る (ホストと同じセグメント)


1. [VM を作る](#kvm-container-で-vm-を作る)の手順 4 の後に、VM が `bridged` につながっていることを確かめる。

   ```bash
   ./kvm.sh virsh domiflist "${VM_NAME:?この項の手順 1 の VM_NAME を設定してから貼る}"   # Type が network、Source が bridged
   ```

   - この項の手順 1 の変数を設定したシェル (リポジトリ直下) で貼る
   - `Type` が `network`、`Source` が `bridged` ならよい
   - 既存の VM の付け替え (定義の `<source network='default'/>` を `bridged` にする) は本書では扱わない

#### kvm-container の VM を削除する

- VM の定義・UEFI 変数・ディスクを消す。ISO は、消すときだけこの項の手順 7 で消す
- 前提: [kvm-container を導入する](#kvm-container-を導入する)を通してある。コンテナが止まっていれば、先に[VM を使う](#kvm-container-の-vm-を使う)の手順 1・2 で起動する
- 実行場所: 対象ホストの一般ユーザーの bash（画面を使う場合は GNOME の端末、画面なしの場合は SSH のシェル）。root の権限は、コマンドに付けた `sudo` だけで使う
- `down` は `data/` を残す。**`clean` は削除する**
- 共有 ISO を消さないため、`--remove-all-storage` は使わず、消すディスクを `--storage` で指定する
- UEFI の VM は `--nvram` を付ける。BIOS の VM に付けてもよい

> [!CAUTION]
> **この項の手順 6 で、VM の定義・UEFI 変数・ディスク (`sda`) が消え、取り戻せない。** ISO は残る。

1. 変数を設定する（ISO も消すときは、`ISO` に必ず値を入れる）。

   ```bash
   ISO=   # ← VM を作ったときの ISO のホスト側パス (例: ~/Downloads/AlmaLinux-10-latest-x86_64-dvd.iso)。<ISO>
   ```

   ```bash
   REPO=~/kvm-container   # clone 先。ユーザーのホームディレクトリ配下にする。<REPO>
   VM_NAME=alma10         # 消す VM の名前。<VM_NAME>
   printf '\n\033[7m 確認 \033[0m\n'
   for v in ISO REPO VM_NAME; do
     printf '%-10s = %s\n' "$v" "${!v}"
   done
   [ ! -d "${REPO}" ] || cd "${REPO}"
   ```

   - `ISO` は、[VM を作る](#kvm-container-で-vm-を作る)の `ISO` と同じ値を入れる。使うのは、ISO も消すとき (この項の手順 7) だけ
   - `REPO` は、[kvm-container を導入する](#kvm-container-を導入する)の手順 1 と同じ値を入れる
   - `VM_NAME` には、消す VM の名前 ([VM を作る](#kvm-container-で-vm-を作る)の `VM_NAME`) を入れる
   - 値を読み戻して確かめる
   - 最後の行でリポジトリ直下に移る
   - **新しいシェルを開いたら** (SSH を張り直したあとも)、この手順の 2 つのブロックを貼り直してから先へ進む

1. 削除するディスクと、CD-ROM の中身を確かめる。

   ```bash
   ./kvm.sh virsh domblklist "${VM_NAME:?この項の手順 1 の VM_NAME が空のまま。値を入れて貼り直す}"   # sda = 消すディスク。sdb に ISO が入ったままなら次の手順で取り出す
   ```

   - `sda` が消すディスク
   - `sdb` が `-` なら、この項の手順 3 は飛ばす (`--cdrom` でインストールした VM は、Windows 以外はインストール後に取り出されている)
   - `vda` が出たら virtio で作った VM。この項の `sda` を `vda` に、`sdb` を `sda` に読み替えて貼る

1. `sdb` に他の VM と共有している ISO が入ったままのときだけ、取り出す。

   ```bash
   ./kvm.sh virsh change-media "${VM_NAME}" sdb --eject --config   # CD-ROM から ISO を取り出す (定義にも反映)
   ```


1. VM を ACPI で止める。

   ```bash
   ./kvm.sh virsh shutdown "${VM_NAME}"
   ```

   - 急ぐなら `shutdown` を `destroy` (強制停止) に変えて貼る
   - 止まっている VM では `domain is not running` のエラーになるが、そのまま先へ進んでよい
   - **次の手順は、数十秒待ってから貼る**

1. VM が止まったか確かめる。

   ```bash
   ./kvm.sh virsh domstate "${VM_NAME}"   # shut off。running のままなら少し待ってもう一度貼る
   ```

   - `running` のままなら、少し待ってからもう一度貼る
   - **次の手順は、`shut off` になったのを確かめてから貼る**

1. VM の定義・UEFI 変数・ディスクを消す (取り戻せない)。

   ```bash
   ./kvm.sh virsh undefine "${VM_NAME}" --nvram --storage sda   # 定義・UEFI 変数・ディスクを削除 (ISO は残る)
   sudo ls "${REPO:?この項の手順 1 の REPO が空のまま。値を入れて貼り直す}/data/var-libvirt/images" "${REPO}/data/etc-libvirt/qemu"   # qcow2 と xml が消え、ISO は残っている
   ```

   - `sudo ls` で、qcow2 と xml が消え、ISO が残っていることを確かめる

1. ISO も消すときだけ、他の VM が使っていないことを `domblklist` で確かめてから消す。

   ```bash
   sudo rm "${REPO:?この項の手順 1 の REPO が空のまま。値を入れて貼り直す}/data/var-libvirt/images/$(basename "${ISO:?この項の手順 1 の ISO が空のまま。値を入れて貼り直す}")"
   ```

#### kvm-container を更新する

- リポジトリを最新にし、イメージを作り直してコンテナを起動し直す。`data/` (VM のディスク・定義) はそのまま使える
- 前提: [kvm-container を導入する](#kvm-container-を導入する)を通してある
- 実行場所: 対象ホストの一般ユーザーの bash（画面を使う場合は GNOME の端末、画面なしの場合は SSH のシェル）。root の権限は、コマンドに付けた `sudo` だけで使う
- リポジトリに自分で加えた変更があれば、この項の手順 2 の `git pull --ff-only` の前に確かめて退避する
- [VM をホストのブリッジにつなぐ](#kvm-container-の-vm-をホストのブリッジにつなぐ)を通したホストでは、この項の手順 3 の最後の `./kvm.sh up` を `KVM_BRIDGE=br0 ./kvm.sh up` に変えて貼る (`br0` は[VM をホストのブリッジにつなぐ](#kvm-container-の-vm-をホストのブリッジにつなぐ)の手順 1 の `BRIDGE`)。付けないと `bridged` が消える

1. 変数を設定する（既定のままでよい）。

   ```bash
   REPO=~/kvm-container   # clone 先。ユーザーのホームディレクトリ配下にする。<REPO>
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'REPO = %s\n' "${REPO}"
   [ ! -d "${REPO}" ] || cd "${REPO}"
   ```

   - `REPO` は、[kvm-container を導入する](#kvm-container-を導入する)の手順 1 と同じ値を入れる
   - 値を読み戻して確かめる
   - 最後の行でリポジトリ直下に移る

1. リポジトリを最新にし、コンテナを止める。

   ```bash
   cd "${REPO:?この項の手順 1 の REPO が空のまま。この項の手順 1 を貼り直す}" && git pull --ff-only
   ./kvm.sh down
   ```

   - 動いている VM は ACPI でシャットダウンされる (最大 120 秒)
   - **次の手順は、`down` が終わってから貼る**

1. イメージを作り直して起動する。

   ```bash
   ./kvm.sh build kvm && { [ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] || ./kvm.sh build gui; } && ./kvm.sh up
   ```

   - 画面の無いホストでは `gui` を作らない
   - `>> ready.` が出れば終わり。確認は[kvm-container を導入する](#kvm-container-を導入する)の手順 9

---

## Windows 11 で使う

- Hyper-V・VirtualBox・VMware Workstation Pro と、Windows Sandbox

### Hyper-V

- Hyper-V で VM を作って使う
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/hyper-v.md)・[参考資料](reference/hyper-v.md)・[注意点](extra/hyper-v.md)

#### Hyper-V: この PC で使えるかを確かめる

- Windows 11 のこの PC で、Hyper-V が使えるかを確かめる
- 前提: 無し
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く
- Windows 11 Pro・Enterprise・Education の x64 が対象。Home には Hyper-V が無い

1. Windows のデスクトップで、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. エディション・CPU の仮想化支援・機能の今の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{
     Admin        = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     User         = "$env:USERDOMAIN\$env:USERNAME"
     Arch         = $env:PROCESSOR_ARCHITECTURE
     Edition      = (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
     Hypervisor   = (Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
     VirtFirmware = (Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1).VirtualizationFirmwareEnabled
   } | Format-List
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -like 'Microsoft-Hyper-V*' | Format-Table FeatureName, State
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -in 'HypervisorPlatform', 'VirtualMachinePlatform' | Format-Table FeatureName, State
   Get-LocalGroupMember -SID 'S-1-5-32-578' | Format-Table Name, ObjectClass
   ```

   - `Admin : True`、`Arch : AMD64`、`Edition` が `Professional`（か `Enterprise`・`Education`）ならよい
   - `Admin` が `False` なら、管理者ではない窓に貼っている。閉じて、この項の手順 1 から
   - `Edition` が `Core`（Home）なら、Hyper-V は入らない。ここで止める
   - `Hypervisor` が `False` で `VirtFirmware` も `False` なら、PC の UEFI（BIOS）の設定で Intel VT-x / AMD-V（SVM）を有効にしてから始める
   - `Microsoft-Hyper-V-All` が `Enabled` なら、もう有効。[Hyper-V を有効にして再起動する](#hyper-v-hyper-v-を有効にして再起動する)の手順 2 は飛ばす
   - 最後の表（Hyper-V Administrators の一員）は、空でよい

#### Hyper-V: Hyper-V を有効にして再起動する

- この PC の Hyper-V を有効にし、自分のユーザーで管理できるようにする
- 前提: [Hyper-V: この PC で使えるかを確かめる](#hyper-v-この-pc-で使えるかを確かめる)を通してある
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

> [!IMPORTANT]
> - **この項の手順 5 で再起動する**。開いている作業を先に保存し、動いている VM を止める。SSH やリモート デスクトップのセッションからは行わない
> - **同じ PC の VirtualBox と VMware Workstation の VM は、再起動の後は Windows のハイパーバイザーの上で動く**。遅くなり、起動しない VM が出ることがある

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開き、UAC の確認に答える

1. Hyper-V が有効でないときだけ、Hyper-V を有効にする。

   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All -NoRestart
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -like 'Microsoft-Hyper-V*' | Format-Table FeatureName, State
   ```

   - `Microsoft-Hyper-V-All`・`Microsoft-Hyper-V-Hypervisor` が `Enabled` か `EnablePending` ならよい
   - `Microsoft-Hyper-V-Services`・`Microsoft-Hyper-V-Management-PowerShell` も `Enabled` か `EnablePending` ならよい
   - **まだ再起動しない**（この項の手順 5 でまとめて行う）

1. VirtualBox か VMware Workstation も同じ PC で使うときだけ、Windows ハイパーバイザー プラットフォームも有効にする。

   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -in 'HypervisorPlatform', 'VirtualMachinePlatform' | Format-Table FeatureName, State
   ```

   - `HypervisorPlatform` が `Enabled` か `EnablePending` ならよい
   - **再起動の後、VirtualBox と VMware Workstation の VM は Windows のハイパーバイザーの上で動き、遅くなることがある**。再起動の後に、既存の VM が起動するかを確かめる

1. 自分のユーザーを Hyper-V Administrators に足す。

   ```powershell
   $HV_USER = "$env:USERDOMAIN\$env:USERNAME"
   if ((Get-LocalGroupMember -SID 'S-1-5-32-578' -ErrorAction SilentlyContinue).Name -contains $HV_USER) { "すでに一員: $HV_USER" } else { Add-LocalGroupMember -SID 'S-1-5-32-578' -Member $HV_USER }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-LocalGroupMember -SID 'S-1-5-32-578' | Format-Table Name, ObjectClass
   ```

   - 表に、ふだんログインするユーザーが出ればよい
   - 別の管理者のユーザーで昇格した窓では、`$HV_USER` がその管理者になる。表のユーザーが違ったら、`Add-LocalGroupMember -SID 'S-1-5-32-578' -Member '<PC 名>\<ふだんのユーザー>'` を打って足す

1. 再起動する。

   ```powershell
   Restart-Computer
   ```

   - **開いている作業を保存し、動いている VM（VirtualBox など）を止めてから貼る**（確認を聞かずに再起動が始まる）
   - VMware も入れるなら、先に[VMware の導入](#vmware-workstation-pro-インストールする)の手順 3 まで済ませると、再起動は 1 回で済む（同じ項の手順 4 を兼ねる）
   - **次の手順は、起動してサインインしてから行う**

#### Hyper-V: 再起動の後に確かめる

- 再起動後に、昇格せずに Hyper-V を管理できることを確かめる
- 前提: [Hyper-V: Hyper-V を有効にして再起動する](#hyper-v-hyper-v-を有効にして再起動する)を通し、再起動してサインインしてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. Hyper-V の管理のコマンドが、昇格せずに使えるかを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   whoami /groups | Select-String -Pattern 'S-1-5-32-578'
   Get-Service -Name vmms, vmcompute | Format-Table Name, Status, StartType
   Get-VMHost | Format-List LogicalProcessorCount, VirtualMachinePath, VirtualHardDiskPath
   Get-VMSwitch | Format-Table Name, SwitchType
   ```

   - `S-1-5-32-578` の行が出て、`vmms` が `Running` ならよい
   - `Get-VMSwitch` に `Default Switch` が出る
   - `Get-VMHost` が権限のエラーになったら、ログインし直していない。サインアウトしてサインインし直す

#### Hyper-V: VM を作る

- この PC に、第 2 世代の VM を作る
- 前提: [Hyper-V: 再起動の後に確かめる](#hyper-v-再起動の後に確かめる)を通し、入れる OS のインストール用の ISO を用意してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`HV_ISO` は必ず値を入れる）。

   ```powershell
   $HV_ISO = ''
   ```

   ```powershell
   $HV_VM = 'alma10'
   $HV_DIR = "$env:USERPROFILE\Hyper-V"
   $HV_CPU = 2
   $HV_MEM = 4GB
   $HV_DISK = 64GB
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ HV_ISO = $HV_ISO; HV_VM = $HV_VM; HV_DIR = $HV_DIR; HV_CPU = $HV_CPU; HV_MEM_GB = $HV_MEM / 1GB; HV_DISK_GB = $HV_DISK / 1GB } | Format-List
   ```

   - `$HV_ISO` は、入れる OS のインストール用の ISO のパス
   - `$HV_VM` は VM の名前、`$HV_DIR` は VM を置くフォルダー（その下に VM の名前のフォルダーができる）
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. 第 2 世代の VM を作り、ISO を付ける。

   ```powershell
   if (-not $HV_ISO -or -not $HV_VM -or -not $HV_DIR -or -not $HV_CPU -or -not $HV_MEM -or -not $HV_DISK) { Write-Error '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' } elseif (-not (Test-Path -LiteralPath $HV_ISO)) { Write-Error "中断: ISO が無い: $HV_ISO" } elseif (Get-VM -Name $HV_VM -ErrorAction SilentlyContinue) { Write-Error "中断: 同じ名前の VM がすでにある: $HV_VM" } else {
     New-VM -Name $HV_VM -Generation 2 -MemoryStartupBytes $HV_MEM -Path $HV_DIR -NewVHDPath "$HV_DIR\$HV_VM\$HV_VM.vhdx" -NewVHDSizeBytes $HV_DISK -SwitchName 'Default Switch' | Out-Null
     Set-VM -Name $HV_VM -ProcessorCount $HV_CPU -StaticMemory -AutomaticCheckpointsEnabled $false -CheckpointType Standard
     Set-VMFirmware -VMName $HV_VM -FirstBootDevice (Add-VMDvdDrive -VMName $HV_VM -Path $HV_ISO -Passthru)
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-VM -Name $HV_VM | Format-List Name, State, Generation, Version, ProcessorCount, DynamicMemoryEnabled, AutomaticCheckpointsEnabled, Path
     Get-VMFirmware -VMName $HV_VM | Format-List SecureBoot, SecureBootTemplate
   }
   ```

   - `State : Off`、`Generation : 2`、`DynamicMemoryEnabled : False`、`AutomaticCheckpointsEnabled : False` が出ればよい
   - `SecureBoot : On`、`SecureBootTemplate : MicrosoftWindows` が出る

1. Linux を入れるときだけ、Secure Boot のテンプレートを Linux 用に変える。

   ```powershell
   if (-not $HV_VM) { throw '中断: この項の手順 2 の $HV_VM が空のまま。値を入れて貼り直す' }
   Set-VMFirmware -VMName $HV_VM -SecureBootTemplate MicrosoftUEFICertificateAuthority
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VMFirmware -VMName $HV_VM | Format-List SecureBoot, SecureBootTemplate
   ```

   - `SecureBootTemplate : MicrosoftUEFICertificateAuthority` が出ればよい
   - **変えないままだと、Linux の ISO からは起動しない**（VM の画面に `Start PXE over IPv4` が出る）
   - Secure Boot を切って入れるなら、代わりに `Set-VMFirmware -VMName $HV_VM -EnableSecureBoot Off` を打つ

1. Windows 11 を入れるときだけ、仮想 TPM を付ける。

   ```powershell
   if (-not $HV_VM) { throw '中断: この項の手順 2 の $HV_VM が空のまま。値を入れて貼り直す' }
   Set-VMKeyProtector -VMName $HV_VM -NewLocalKeyProtector
   Enable-VMTPM -VMName $HV_VM
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VMSecurity -VMName $HV_VM | Format-List TpmEnabled
   ```

   - `TpmEnabled : True` が出ればよい

#### Hyper-V: VM を起動して OS を入れる

- VM を起動し、OS をインストールする
- 前提: [Hyper-V: VM を作る](#hyper-v-vm-を作る)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`HV_VM` は必ず値を入れる）。

   ```powershell
   $HV_VM = ''
   ```

   ```powershell

   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ HV_VM = $HV_VM } | Format-List
   ```

   - `HV_VM` は、[Hyper-V: VM を作る](#hyper-v-vm-を作る)の手順 2 と同じ VM の名前を入れる
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. VM を起動し、VM の画面を開く。

   ```powershell
   if (-not $HV_VM) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   Start-VM -Name $HV_VM
   vmconnect.exe localhost $HV_VM
   ```

   - VM の画面のウィンドウが開く

1. VM の画面で、OS のインストーラーを最後まで進める。

   - Windows の ISO は、起動の直後に `Press any key to boot from CD or DVD` が出ているあいだに、VM の画面をクリックしてキーを押す
   - インストーラーが最後に再起動するか、電源を切るまで進める
   - **次の手順は、インストールが終わってから貼る**

1. ISO を付けた DVD ドライブを、VM から外す。

   ```powershell
   if (-not $HV_VM) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   Get-VMDvdDrive -VMName $HV_VM | Remove-VMDvdDrive
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   "DVD ドライブの数: $(@(Get-VMDvdDrive -VMName $HV_VM).Count)"
   ```

   - `DVD ドライブの数: 0` が出ればよい

#### Hyper-V: 動作を確かめる

- 動いている VM の状態と、ゲストへの SSH を確かめる
- 前提: [Hyper-V: VM を起動して OS を入れる](#hyper-v-vm-を起動して-os-を入れる)を通してある。SSH を確かめるときは、ゲストの SSH サーバーとファイアウォールを設定してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`HV_VM` は必ず値を入れる）。

   ```powershell
   $HV_VM = ''
   ```

   ```powershell

   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ HV_VM = $HV_VM } | Format-List
   ```

   - `HV_VM` は、[Hyper-V: VM を作る](#hyper-v-vm-を作る)の手順 2 と同じ VM の名前を入れる
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. VM の状態と、ゲストの IP を確かめる。

   ```powershell
   if (-not $HV_VM) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VM -Name $HV_VM | Format-List Name, State, Uptime, Status
   Get-VMNetworkAdapter -VMName $HV_VM | Format-Table Name, SwitchName, MacAddress, IPAddresses
   ```

   - `State : Running` で、`IPAddresses` にゲストの IP が出ればよい
   - VM が止まっていたら、先に `Start-VM -Name $HV_VM` を打つ
   - `IPAddresses` が空のまま変わらないなら、ゲストに Hyper-V のデーモンが入っていない。VM の画面でログインして IP を見る（AlmaLinux 10 の Workstation には `hyperv-daemons` が入っている）

1. Linux のゲストなら、この PC から SSH で入れるかを確かめる。

   - この項の手順 1 で開いた PowerShell で `ssh <ゲストのユーザー>@<ゲストの IP>` を打つ（IP はこの項の手順 3 の `IPAddresses`）
   - ゲストのプロンプトが出ればよい。`exit` で戻る
   - ゲストの IP は固定ではない。つなぐ前に、この項の手順 3 で引き直す

#### Hyper-V: 使い方の基本

- 管理者ではない Windows PowerShell（5.1）で打つ。`<VM 名>` は VM の名前

| すること | コマンド |
|---|---|
| VM の一覧 | `Get-VM` |
| 起動する | `Start-VM -Name <VM 名>` |
| ゲストに電源を切らせる | `Stop-VM -Name <VM 名>` |
| 電源を切る（ゲストに知らせない） | `Stop-VM -Name <VM 名> -TurnOff` |
| VM の画面を開く | `vmconnect.exe localhost <VM 名>` |
| ゲストの IP を見る | `(Get-VMNetworkAdapter -VMName <VM 名>).IPAddresses` |
| CPU の数を変える（止めてから） | `Set-VM -Name <VM 名> -ProcessorCount 4` |
| メモリを変える（止めてから） | `Set-VM -Name <VM 名> -MemoryStartupBytes 8GB` |

#### Hyper-V: チェックポイントとクローン

- チェックポイントを取って戻し、その時点から別の VM を作る
- 前提: [Hyper-V: 動作を確かめる](#hyper-v-動作を確かめる)まで通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

> [!WARNING]
> **この項の手順 5 で作った VM があるあいだは、元の VM のチェックポイントを消さない**。消すと元のディスクが書き換わり、そこから作った VM がすべて起動しなくなる。

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`HV_VM` は必ず値を入れる）。

   ```powershell
   $HV_VM = ''
   ```

   ```powershell
   $HV_DIR = "$env:USERPROFILE\Hyper-V"
   $HV_CHECKPOINT = 'clean-install'
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ HV_VM = $HV_VM; HV_DIR = $HV_DIR; HV_CHECKPOINT = $HV_CHECKPOINT } | Format-List
   ```

   - `HV_VM` と `HV_DIR` は、[Hyper-V: VM を作る](#hyper-v-vm-を作る)の手順 2 と同じ値にする
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. VM を止めて、チェックポイントを取る。

   ```powershell
   if (-not $HV_VM -or -not $HV_DIR -or -not $HV_CHECKPOINT) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   Stop-VM -Name $HV_VM
   Checkpoint-VM -Name $HV_VM -SnapshotName $HV_CHECKPOINT
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VMSnapshot -VMName $HV_VM | Format-Table VMName, Name, SnapshotType, CreationTime
   ```

   - 付けた名前のチェックポイントが出ればよい
   - VM がすでに止まっていれば、`Stop-VM` は警告を出して何もしない

1. VM をチェックポイントの時点に戻すときは、VM を止めてから戻す。

   ```powershell
   if (-not $HV_VM -or -not $HV_DIR -or -not $HV_CHECKPOINT) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   Stop-VM -Name $HV_VM -TurnOff
   Restore-VMSnapshot -VMName $HV_VM -Name $HV_CHECKPOINT -Confirm:$false
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-VM -Name $HV_VM | Format-List Name, State, ParentCheckpointName
   ```

   - **チェックポイントより後の変更は消える**
   - `ParentCheckpointName` に、戻した先の名前が出ればよい
   - VM がすでに止まっていれば、`Stop-VM` は警告を出して何もしない

1. チェックポイントの時点から、差分ディスクで別の VM を作る。

   ```powershell
   if (-not $HV_VM -or -not $HV_DIR -or -not $HV_CHECKPOINT) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   $HV_CLONE = "$HV_VM-clone"
   if (Get-VM -Name $HV_CLONE -ErrorAction SilentlyContinue) { Write-Error "中断: 同じ名前の VM がすでにある: $HV_CLONE" } else {
     $parent = (Get-VMHardDiskDrive -VMSnapshot (Get-VMSnapshot -VMName $HV_VM -Name $HV_CHECKPOINT) | Select-Object -First 1).Path
     New-Item -ItemType Directory -Path "$HV_DIR\$HV_CLONE" | Out-Null
     New-VHD -Path "$HV_DIR\$HV_CLONE\$HV_CLONE.vhdx" -ParentPath $parent -Differencing | Out-Null
     New-VM -Name $HV_CLONE -Generation 2 -MemoryStartupBytes (Get-VM -Name $HV_VM).MemoryStartup -Path $HV_DIR -VHDPath "$HV_DIR\$HV_CLONE\$HV_CLONE.vhdx" -SwitchName 'Default Switch' | Out-Null
     Set-VM -Name $HV_CLONE -ProcessorCount (Get-VM -Name $HV_VM).ProcessorCount -StaticMemory -AutomaticCheckpointsEnabled $false -CheckpointType Standard
     $firmware = Get-VMFirmware -VMName $HV_VM
     if ($firmware.SecureBoot -eq 'On') { Set-VMFirmware -VMName $HV_CLONE -EnableSecureBoot On -SecureBootTemplate $firmware.SecureBootTemplate } else { Set-VMFirmware -VMName $HV_CLONE -EnableSecureBoot Off }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-VHD -Path "$HV_DIR\$HV_CLONE\$HV_CLONE.vhdx" | Format-List VhdType, ParentPath
     Get-VM -Name $HV_CLONE | Format-List Name, State, ProcessorCount, MemoryStartup
   }
   ```

   - `VhdType : Differencing` と、元の VM のディスクを指す `ParentPath` が出ればよい
   - 新しい VM は、ホスト名もログインも元の VM と同じ。起動してから、ゲストの中でホスト名を変える
   - 仮想 TPM と、ファームウェアに登録した鍵（MOK など）は引き継がれない

#### Hyper-V: VM どうしだけがつながるスイッチを作る

- Private のスイッチを作り、止めてある VM に 2 枚目の NIC として付ける
- 前提: [Hyper-V: 動作を確かめる](#hyper-v-動作を確かめる)まで通し、対象の VM を止めてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- このスイッチは VM どうしだけが通信でき、この PC ともインターネットともつながらない。ゲストの中で固定の IP を付ける

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`HV_VM` は必ず値を入れる）。

   ```powershell
   $HV_VM = ''
   ```

   ```powershell

   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ HV_VM = $HV_VM } | Format-List
   ```

   - `HV_VM` は、[Hyper-V: VM を作る](#hyper-v-vm-を作る)の手順 2 と同じ VM の名前を入れる
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. スイッチを作り、止めてある VM に 2 枚目の NIC として付ける。

   ```powershell
   if (-not $HV_VM) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   $HV_SWITCH = 'lab-lan'
   $switch = Get-VMSwitch -Name $HV_SWITCH -ErrorAction SilentlyContinue
   if ($switch -and $switch.SwitchType -ne 'Private') { Write-Error "中断: 同じ名前で、Private ではないスイッチがある: $HV_SWITCH" } else {
     if (-not $switch) { New-VMSwitch -Name $HV_SWITCH -SwitchType Private | Out-Null }
     Add-VMNetworkAdapter -VMName $HV_VM -SwitchName $HV_SWITCH
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-VMSwitch -Name $HV_SWITCH | Format-Table Name, SwitchType
     Get-VMNetworkAdapter -VMName $HV_VM | Format-Table Name, SwitchName, MacAddress
   }
   ```

   - `SwitchType` が `Private` のスイッチと、VM の 2 枚の NIC（`Default Switch` と、作ったスイッチ）が出ればよい
   - `中断: 同じ名前で、Private ではないスイッチがある` と出たら、`$HV_SWITCH` を別の名前にして貼り直す
   - つなぐ相手の VM にも、`$HV_VM` を相手の名前に変えて `Add-VMNetworkAdapter` の行を打つ

#### Hyper-V: VM を消す

- VM の登録とディスクを消す
- 前提: [Hyper-V: 動作を確かめる](#hyper-v-動作を確かめる)まで通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

> [!CAUTION]
> **この項の手順 2 は、VM のディスクごと消す（取り戻せない）**。[チェックポイントとクローン](#hyper-v-チェックポイントとクローン)の手順 5 で、この VM から作った VM が残っているなら、先にそちらを消す。

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. VM を止めて、登録とファイルを消す（取り戻せない）。

   ```powershell
   $HV_REMOVE = ''
   ```

   ```powershell
   if (-not $HV_REMOVE) { Write-Error '中断: $HV_REMOVE が空のまま。消す VM の名前を入れて貼り直す' } elseif (-not (Get-VM -Name $HV_REMOVE -ErrorAction SilentlyContinue)) { Write-Error "中断: VM が無い: $HV_REMOVE" } else {
     $dir = (Get-VM -Name $HV_REMOVE).Path.TrimEnd('\')
     $others = @(Get-VM | Where-Object Name -ne $HV_REMOVE)
     $disks = @($others | Get-VMHardDiskDrive | ForEach-Object { $_.Path; (Get-VHD -Path $_.Path).ParentPath })
     if ((Split-Path -Leaf $dir) -ne $HV_REMOVE) { Write-Error "中断: VM のフォルダーが、VM の名前のフォルダーではない: $dir" } elseif (($others | Where-Object { $_.Path.TrimEnd('\') -eq $dir }) -or ($disks | Where-Object { $_ -like "$dir\*" })) { Write-Error "中断: ほかの VM が、このフォルダーのファイルを使っている: $dir" } else {
       Stop-VM -Name $HV_REMOVE -TurnOff -Force -WarningAction SilentlyContinue
       Remove-VM -Name $HV_REMOVE -Force -ErrorAction Stop
       Remove-Item -LiteralPath $dir -Recurse -Force
       "`n$([char]27)[7m 確認 $([char]27)[0m"
       Get-VM | Format-Table Name, State
       Test-Path -LiteralPath $dir
     }
   }
   ```

   - 一覧から VM が消え、最後に `False` が出ればよい
   - `中断: VM のフォルダーが、VM の名前のフォルダーではない` と出たら、本書の[VM を作る](#hyper-v-vm-を作る)で作った VM ではない。このブロックでは消さない（Hyper-V マネージャーで消す）
   - `中断: ほかの VM が、このフォルダーのファイルを使っている` と出たら、この VM から作った VM を先に消す

---

### Windows 11 で VirtualBox を入れる

- VirtualBox を入れ、使い捨ての VM と管理画面の起動を確かめる
- VM を作って使う・消す・上げるときは、この項の後ろの「VirtualBox: 〜」の項を通す
- 前提: [Microsoft Store の更新](windows-setup.md#microsoft-store-の更新)で winget を用意してある
- 実行場所: この PC のデスクトップ。管理者の Windows PowerShell（5.1）をこの項の手順 1、管理者ではない窓を手順 5 で開く
- Windows 11 の x64 が対象
- Atomic Desktop のゲストに Guest Additions を入れるなら、[bootc ゲスト](#virtualbox-の-bootc-ゲスト)を通す
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/virtualbox.md)・[参考資料](reference/virtualbox.md)・[注意点](extra/virtualbox.md)

> [!IMPORTANT]
> - **SSH やリモート デスクトップのセッションからは行わない**。この項の手順 3 の途中でネットワークがいったん切れ、手順 7 は画面で行う

1. Windows のデスクトップで、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. この PC に入るか、今の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
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
   - `Admin` が `False` なら、管理者ではない窓に貼っている。閉じて、この項の手順 1 から
   - `Arch` が `ARM64` なら、この項は扱わない
   - `Winget` が空なら、Microsoft Store で「アプリ インストーラー」を更新してから始める
   - `Hypervisor` が `False` で `VirtFirmware` も `False` なら、PC の UEFI（BIOS）の設定で Intel VT-x / AMD-V（SVM）を有効にしてから始める
   - `VirtualBox` が `True` なら、もう入っている。この項の手順 3 は飛ばす（新しい版にするなら[Windows 11 の更新](#virtualbox-windows-11-の更新)）

1. VirtualBox が入っていないときだけ、winget で入れる。

   ```powershell
   winget install --exact --id Oracle.VirtualBox --source winget --accept-source-agreements --accept-package-agreements
   ```

   - **途中でネットワークがいったん切れる**
   - インストーラの画面は出ず、進み具合だけが出る。最後に、入れ終えた旨の行（英語の表示では `Successfully installed`）が出ればよい
   - **次の手順は、winget が終わってプロンプトに戻ってから貼る**（続けて貼ると、winget が何か聞いたときの答えとして食われる）

1. 入ったか、ドライバーとホストオンリーのアダプターができたかを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id Oracle.VirtualBox --source winget
   & "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" --version
   Get-CimInstance -ClassName Win32_SystemDriver -Filter "Name LIKE 'VBox%'" | Format-Table Name, State, StartMode
   Get-NetAdapter -InterfaceDescription 'VirtualBox Host-Only Ethernet Adapter*' | Format-Table Name, InterfaceDescription, Status
   ```

   - `Oracle.VirtualBox` の `7.2.20` の行と、`7.2.20r175154` が出ればよい
   - ドライバーは `VBoxSup`・`VBoxNetLwf`・`VBoxNetAdp`・`VBoxUSBMon` などが出て、`VBoxSup` が `Running` ならよい
   - ホストオンリーのアダプターが 1 つ出る（`Name` は `イーサネット 2` のように PC で違う）

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 使い捨ての VM を画面無しで起動し、Hyper-V の上で動くかを見てから止めて消す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $vbm = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
   if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
     Write-Error '管理者の PowerShell に貼っている（この項の手順 5 で開いた窓に貼る）'
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

   - `VM "vbox-selftest" has been successfully started.` と `VMState="running"` が出れば動いている
   - **`fall back to NEM` か `Snail execution mode` を含む行が出たら、VM は Hyper-V の上で動いている**（遅くなる。[注意点](extra/virtualbox.md#注意点)）
   - その行が出なければ、VirtualBox は VT-x / AMD-V を直接使っているはず
   - `poweroff` と `unregistervm` は `0%...100%` の行を出し、VM の登録と設定のファイルが消える
   - `%USERPROFILE%\VirtualBox VMs\vbox-selftest\Logs\VBoxHardening.log` が残ることがある。要らなければ `vbox-selftest` のフォルダーを手で消す
   - 既に `vbox-selftest` があれば、変更せず中断する。別の名前で試すなら、ブロック中の `vbox-selftest` をすべて同じ名前に変える

1. スタートメニューの「Oracle VirtualBox」で VirtualBox マネージャーを開き、閉じる。

   - デスクトップのショートカットでも、この項の手順 6 の窓で `& "$env:ProgramFiles\Oracle\VirtualBox\VirtualBox.exe"` を打っても同じ
   - VirtualBox マネージャーのウィンドウが開く（一覧は空）
   - 右クリックの「管理者として実行」では開かない
   - **次の手順は、ウィンドウを閉じてから貼る**

1. `%USERPROFILE%\.VirtualBox` に設定ができたか確かめる。

   ```powershell
   Get-ChildItem -LiteralPath "$env:USERPROFILE\.VirtualBox" | Format-Table Name, Length
   ```

   - `VirtualBox.xml`・`VBoxSVC.log` などが並べばよい

#### VirtualBox: Windows 11 で VM を作って使う

- AlmaLinux 10 の x86_64 の ISO から VM を作って使う。インストーラーの画面は人が操作する
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/virtualbox.md)・[参考資料](reference/virtualbox.md)・[注意点](extra/virtualbox.md)
- ふだんの操作は[使い方の基本](#virtualbox-使い方の基本)、状態を残す・複製するなら[スナップショットとクローン](#virtualbox-スナップショットとクローン)、要らなくなったら[VM を消す](#virtualbox-vm-を消す)

##### VirtualBox: VM を作る

- この PC に、AlmaLinux 10 の VM を作る
- 前提: [VirtualBox](#windows-11-で-virtualbox-を入れる)を通し、AlmaLinux 10 の x86_64 の ISO を用意してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`VB_ISO` は必ず値を入れる）。

   ```powershell
   $VB_ISO = ''
   ```

   ```powershell
   $VB_VM = 'alma10'
   $VB_BASE = "$env:USERPROFILE\VirtualBox VMs"
   $VB_CPU = 2
   $VB_MEM_MB = 4096
   $VB_DISK_MB = 65536
   $VB_SSH_PORT = 2222
   $vbm = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ ISO = $VB_ISO; VM = $VB_VM; Base = $VB_BASE; CPU = $VB_CPU; MemoryMB = $VB_MEM_MB; DiskMB = $VB_DISK_MB; SshPort = $VB_SSH_PORT } | Format-List
   ```

   - `VB_ISO` はインストール用の ISO のパス
   - `VB_BASE` の下に VM の名前のフォルダーを作る。VirtualBox 全体の既定の置き場所は変えない
   - SSH のポートはこの PC で使っていない番号にする
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. VM を登録し、EFI・CPU・メモリ・画面・NAT を設定する。

   ```powershell
   if (-not $VB_VM -or -not $VB_BASE -or -not $VB_CPU -or -not $VB_MEM_MB -or -not $VB_SSH_PORT -or -not $vbm) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   if (-not $VB_ISO -or -not (Test-Path -LiteralPath $VB_ISO -PathType Leaf)) { throw '中断: ISO のパスを入れて貼り直す' }
   if (Test-Path -LiteralPath "$VB_BASE\$VB_VM") { throw '中断: 同じ名前のフォルダーがある' }
   $registered = & $vbm list vms
   if ($registered | Where-Object { $_.StartsWith('"' + $VB_VM + '" {') }) { throw '中断: 同じ名前の VM がある' }
   & $vbm createvm --name $VB_VM --ostype RedHat_64 --basefolder $VB_BASE --register
   if ($LASTEXITCODE -ne 0) { throw '中断: VM を作れなかった' }
   & $vbm modifyvm $VB_VM --firmware efi --chipset piix3 --ioapic on --cpus $VB_CPU --memory $VB_MEM_MB --paravirt-provider kvm --graphicscontroller vmsvga --vram 128 --accelerate-3d off --audio-enabled off --nic1 nat --nictype1 82540EM --cable-connected1 on --nat-pf1 "ssh,tcp,127.0.0.1,$VB_SSH_PORT,,22" --boot1 dvd --boot2 disk --boot3 none --boot4 none
   if ($LASTEXITCODE -ne 0) { throw '中断: 設定に失敗した' }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $vbm showvminfo $VB_VM --machinereadable | Select-String -Pattern '^(name|CfgFile|firmware|chipset|cpus|memory|graphicscontroller|nic1|nictype1|boot[1-4])=|^Forwarding'
   ```

   - `firmware="EFI"`、`chipset="piix3"`、指定した `cpus`・`memory`、`graphicscontroller="vmsvga"`、`nic1="nat"` が出ればよい
   - `Forwarding(0)="ssh,tcp,127.0.0.1,<指定したポート>,,22"` は、この PC の中だけから SSH を受け付ける設定
   - エラーが出たら中断する。途中まで作った VM は[VM を消す](#virtualbox-vm-を消す)で消してから作り直す

1. 可変のディスクと光学ドライブを作り、ISO を付ける。

   ```powershell
   if (-not $VB_VM -or -not $VB_BASE -or -not $VB_DISK_MB -or -not $VB_ISO -or -not $vbm) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   & $vbm createmedium disk --filename "$VB_BASE\$VB_VM\$VB_VM.vdi" --size $VB_DISK_MB --format VDI --variant Standard
   if ($LASTEXITCODE -ne 0) { throw '中断: ディスクを作れなかった' }
   & $vbm storagectl $VB_VM --name SATA --add sata --controller IntelAhci --portcount 2
   if ($LASTEXITCODE -ne 0) { throw '中断: コントローラーを作れなかった' }
   & $vbm storageattach $VB_VM --storagectl SATA --port 0 --device 0 --type hdd --medium "$VB_BASE\$VB_VM\$VB_VM.vdi"
   if ($LASTEXITCODE -ne 0) { throw '中断: ディスクを付けられなかった' }
   & $vbm storageattach $VB_VM --storagectl SATA --port 1 --device 0 --type dvddrive --medium $VB_ISO
   if ($LASTEXITCODE -ne 0) { throw '中断: ISO を付けられなかった' }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $vbm showvminfo $VB_VM --machinereadable | Select-String -Pattern '^"SATA-[01]-0"='
   Get-ChildItem -LiteralPath "$VB_BASE\$VB_VM" | Format-Table Name, Length
   ```

   - `SATA-0-0` に `.vdi`、`SATA-1-0` に ISO のパスが出ればよい
   - フォルダーに `.vbox` と `.vdi` が並べばよい

##### VirtualBox: VM を起動して OS を入れる

- 作った VM を起動し、AlmaLinux をインストールする
- 前提: [VirtualBox: VM を作る](#virtualbox-vm-を作る)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`VB_VM` は必ず値を入れる）。

   ```powershell
   $VB_VM = ''
   ```

   ```powershell
   $vbm = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ VB_VM = $VB_VM; VBoxManage = $vbm } | Format-List
   ```

   - `VB_VM` は、[VirtualBox: VM を作る](#virtualbox-vm-を作る)の手順 2 と同じ VM の名前を入れる
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. VM のウィンドウを開いて起動する。

   ```powershell
   if (-not $VB_VM -or -not $vbm) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   & $vbm startvm $VB_VM --type gui
   ```

   - `has been successfully started` が出て、VM のウィンドウにインストーラーの起動メニューが出ればよい

1. VM の画面で AlmaLinux のインストーラーを最後まで進める。

   - `Install AlmaLinux` を選び、言語・インストール先・ソフトウェア・ユーザーを設定する
   - SSH で入るなら、ゲスト側で SSH サーバーを有効にし、ゲストのファイアウォールで SSH を許可する
   - マウスとキーが VM に入ったら、右 Ctrl（既定のホスト キー）でこの PC に戻る
   - **次の手順は、インストールを終え、ゲストの操作で電源を切ってから貼る**

1. 停止した VM の光学ドライブから ISO を外す。

   ```powershell
   if (-not $VB_VM -or -not $vbm) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   & $vbm storageattach $VB_VM --storagectl SATA --port 1 --device 0 --type dvddrive --medium emptydrive
   if ($LASTEXITCODE -ne 0) { throw '中断: ISO を外せなかった' }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $vbm showvminfo $VB_VM --machinereadable | Select-String -Pattern '^"SATA-1-0"='
   ```

   - `"SATA-1-0"="emptydrive"` が出ればよい

##### VirtualBox: Windows のホストで VM の動作を確かめる

- この PC で VM の起動と、ゲストへの SSH を確かめる
- 前提: [VirtualBox: VM を起動して OS を入れる](#virtualbox-vm-を起動して-os-を入れる)を通し、VM を止めてある。SSH を確かめるときは、ゲストの SSH サーバーとファイアウォールを設定してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`VB_VM`・`VB_SSH_PORT` は必ず値を入れる）。

   ```powershell
   $VB_VM = ''
   ```

   ```powershell
   $VB_SSH_PORT = ''
   ```

   ```powershell
   $vbm = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ VB_VM = $VB_VM; VB_SSH_PORT = $VB_SSH_PORT; VBoxManage = $vbm } | Format-List
   ```

   - `VB_VM` と `VB_SSH_PORT` は、[VirtualBox: VM を作る](#virtualbox-vm-を作る)の手順 2 と同じ値を入れる
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. VM を画面無しで起動し、状態と仮想化の載り方を確かめる。

   ```powershell
   if (-not $VB_VM -or -not $VB_SSH_PORT -or -not $vbm) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   & $vbm startvm $VB_VM --type headless
   if ($LASTEXITCODE -ne 0) { throw '中断: VM が起動しなかった' }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $vbm showvminfo $VB_VM --machinereadable | Select-String -Pattern '^VMState='
   & $vbm showvminfo $VB_VM --log 0 | Select-String -Pattern 'fall back to NEM|Snail execution mode'
   ```

   - `VMState="running"` が出ればよい
   - `fall back to NEM` か `Snail execution mode` が出たら Hyper-V 経由で動いている（[注意点](extra/virtualbox.md#注意点)）

1. この PC から SSH でゲストに入れるか確かめる。

   - この項の手順 1 で開いた PowerShell で `ssh -p $VB_SSH_PORT <ゲストのユーザー>@127.0.0.1` を打つ
   - 初回はホスト鍵の指紋をゲスト側と照合して承認する。ゲストのプロンプトが出ればよい。`exit` で戻る
   - つながらなければ起動を待ち、ゲストの SSH サーバーとファイアウォールを確かめる

#### VirtualBox: 使い方の基本

- 以下は Windows 11 のホスト用。管理者ではない Windows PowerShell（5.1）で、[VM を作る](#virtualbox-vm-を作る)の手順 2 の変数を使う

| すること | コマンド |
|---|---|
| 登録した VM の一覧 | `& $vbm list vms` |
| 動いている VM の一覧 | `& $vbm list runningvms` |
| ウィンドウを開いて起動 | `& $vbm startvm $VB_VM --type gui` |
| 画面無しで起動 | `& $vbm startvm $VB_VM --type headless` |
| ゲストに電源ボタンを送る | `& $vbm controlvm $VB_VM acpipowerbutton` |
| 状態を読む | `& $vbm showvminfo $VB_VM --machinereadable` |
| 強制的に電源を切る（未保存の内容は失われる） | `& $vbm controlvm $VB_VM poweroff` |

#### VirtualBox: スナップショットとクローン

- 停止した VM のスナップショットを取り、独立したディスクを持つ完全クローンを作る
- 前提: [VirtualBox: Windows のホストで VM の動作を確かめる](#virtualbox-windows-のホストで-vm-の動作を確かめる)まで通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

> [!WARNING]
> **この項の手順 5 の復元では、スナップショットより後の変更は消える**。

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`VB_VM` は必ず値を入れる）。

   ```powershell
   $VB_VM = ''
   ```

   ```powershell
   $VB_BASE = "$env:USERPROFILE\VirtualBox VMs"
   $VB_CLONE_PORT = 2223
   $vbm = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ VB_VM = $VB_VM; VB_BASE = $VB_BASE; VB_CLONE_PORT = $VB_CLONE_PORT; VBoxManage = $vbm } | Format-List
   ```

   - `VB_VM` と `VB_BASE` は、[VirtualBox: VM を作る](#virtualbox-vm-を作る)の手順 2 と同じ値にする
   - `VB_CLONE_PORT` は、この PC で使っていない番号にする。元の VM の SSH の転送ポートと違う番号にする
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. ゲストに電源ボタンを送り、停止を確かめる。

   ```powershell
   if (-not $VB_VM -or -not $VB_BASE -or -not $VB_CLONE_PORT -or -not $vbm) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   & $vbm controlvm $VB_VM acpipowerbutton
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $vbm showvminfo $VB_VM --machinereadable | Select-String -Pattern '^VMState='
   ```

   - `VMState="poweroff"` になるまで、最後のコマンドを打ち直して待つ
   - すでに停止していたら電源ボタンはエラーになる。その場合も状態を確かめる
   - **次の手順は、`poweroff` になってから貼る**

1. 停止した VM のスナップショットを取る。

   ```powershell
   if (-not $VB_VM -or -not $VB_BASE -or -not $VB_CLONE_PORT -or -not $vbm) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   & $vbm snapshot $VB_VM take clean-install
   if ($LASTEXITCODE -ne 0) { throw '中断: スナップショットを取れなかった' }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $vbm snapshot $VB_VM list
   ```

   - `Name: clean-install` と UUID が出ればよい

1. 元に戻すときは、VM を停止してからスナップショットを復元する。

   ```powershell
   if (-not $VB_VM -or -not $VB_BASE -or -not $VB_CLONE_PORT -or -not $vbm) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   & $vbm snapshot $VB_VM restore clean-install
   if ($LASTEXITCODE -ne 0) { throw '中断: 復元できなかった' }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $vbm snapshot $VB_VM list
   ```

   - `Name: clean-install` の行の末尾に `*` が付けばよい

1. スナップショットから完全クローンを作り、SSH の転送ポートを変える。

   ```powershell
   if (-not $VB_VM -or -not $VB_BASE -or -not $VB_CLONE_PORT -or -not $vbm) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   $VB_CLONE = "$VB_VM-clone"
   if (Test-Path -LiteralPath "$VB_BASE\$VB_CLONE") { throw '中断: クローン先のフォルダーがある' }
   $registered = & $vbm list vms
   if ($registered | Where-Object { $_.StartsWith('"' + $VB_CLONE + '" {') }) { throw '中断: 同じ名前の VM がある' }
   & $vbm clonevm $VB_VM --snapshot clean-install --name $VB_CLONE --basefolder $VB_BASE --mode machine --register
   if ($LASTEXITCODE -ne 0) { throw '中断: クローンを作れなかった' }
   & $vbm modifyvm $VB_CLONE --nat-pf1 delete ssh
   if ($LASTEXITCODE -ne 0) { throw '中断: 転送を外せなかった' }
   & $vbm modifyvm $VB_CLONE --nat-pf1 "ssh,tcp,127.0.0.1,$VB_CLONE_PORT,,22"
   if ($LASTEXITCODE -ne 0) { throw '中断: 転送を設定できなかった' }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $vbm showvminfo $VB_CLONE --machinereadable | Select-String -Pattern '^(name|CfgFile|Forwarding)|^"SATA-0-0"='
   ```

   - 新しい名前・設定とディスクのパス・クローン用の転送ポートが出ればよい
   - クローンにはディスク内のユーザー・ホスト名・SSH のホスト鍵がコピーされることがある。別の PC として使う前に、ゲスト側で元との同一性を確かめ、ホスト名と SSH のホスト鍵を変更する
   - 起動は `& $vbm startvm $VB_CLONE --type headless`、SSH は `ssh -p $VB_CLONE_PORT <ゲストのユーザー>@127.0.0.1`

#### VirtualBox: VM を消す

- 停止した VM の登録とディスクを消す
- 前提: [VirtualBox](#windows-11-で-virtualbox-を入れる)を通し、消す VM を止めてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

> [!CAUTION]
> **この項の手順 3 は、指定した VM のディスクとスナップショットも消す（取り戻せない）**。必要なデータを先に退避する。

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する。

   ```powershell
   $VB_BASE = "$env:USERPROFILE\VirtualBox VMs"
   $vbm = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ VB_BASE = $VB_BASE; VBoxManage = $vbm } | Format-List
   ```

   - `VB_BASE` は、[VirtualBox: VM を作る](#virtualbox-vm-を作る)の手順 2 と同じ VM の置き場所にする
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. 停止した VM の登録とディスクを消す（取り戻せない。`VB_REMOVE` は必ず値を入れる）。

   ```powershell
   $VB_REMOVE = ''
   ```

   ```powershell
   if (-not $VB_REMOVE -or -not $VB_BASE -or -not $vbm) { throw '中断: この項の手順 2 の変数と、消す VM の名前の VB_REMOVE を入れて貼り直す' }
   $info = & $vbm showvminfo $VB_REMOVE --machinereadable
   if ($LASTEXITCODE -ne 0) { throw '中断: VM が見つからない' }
   if ($info -notcontains 'VMState="poweroff"') { throw '中断: ゲストの操作で電源を切ってから貼り直す' }
   & $vbm unregistervm $VB_REMOVE --delete
   if ($LASTEXITCODE -ne 0) { throw '中断: 削除に失敗した' }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & $vbm list vms
   Get-ChildItem -LiteralPath "$VB_BASE\$VB_REMOVE" -Force -ErrorAction SilentlyContinue | Format-Table Name
   ```

   - 一覧から指定した VM が消え、`.vbox`・`.vdi`・`Snapshots` が無くなればよい
   - `Logs` だけ残ることがある。要らなければ、消した VM のフォルダーであることを確かめ、エクスプローラーでそのフォルダーを消す

#### VirtualBox: Windows 11 の更新

- VirtualBox を winget で上げる
- 前提: [VirtualBox](#windows-11-で-virtualbox-を入れる)を通してある
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く
- **更新の途中でも、ネットワークがいったん切れるはず**。SSH やリモート デスクトップのセッションからは行わない
- VM の中の Guest Additions は、この項では上がらない（Atomic Desktop の VM は [VirtualBox の bootc ゲストの更新](#virtualbox-の-bootc-ゲスト-更新)）

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開き、UAC の確認に答える

1. VirtualBox の VM と VirtualBox マネージャーをすべて閉じる。

   - VM は、それぞれのウィンドウを閉じるか、VirtualBox マネージャーから止める
   - **次の手順は、すべて閉じてから貼る**

1. VirtualBox が動いていないことと、新しい版があるかを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Process -Name VirtualBox, VirtualBoxVM, VBoxHeadless, VBoxSVC -ErrorAction SilentlyContinue | Format-Table Id, ProcessName
   winget list --exact --id Oracle.VirtualBox --source winget
   ```

   - プロセスは何も出なければよい
   - `VBoxSVC` だけが出たら、数秒待って貼り直す
   - `winget list` の版の列の右に、新しい版の列（英語の表示では `Available`）が出たら、新しい版がある
   - 新しい版の列が無ければ、この項の手順 4・5 は飛ばす

1. 新しい版があるときだけ、winget で上げる。

   ```powershell
   winget upgrade --exact --id Oracle.VirtualBox --source winget --accept-source-agreements --accept-package-agreements
   ```

   - 途中でネットワークがいったん切れるはず
   - **次の手順は、winget が終わってプロンプトに戻ってから貼る**（続けて貼ると、winget が何か聞いたときの答えとして食われる）

1. 新しい版にしたときだけ、新しい版になったか確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" --version
   winget list --exact --id Oracle.VirtualBox --source winget
   ```

   - 新しい版の番号が出て、`winget list` の新しい版の列が消えればよい

---

### VMware Workstation Pro

- VMware Workstation Pro を入れて VM を作る
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/vmware.md)・[参考資料](reference/vmware.md)・[注意点](extra/vmware.md)

#### VMware Workstation Pro: インストーラーを取得して確かめる

- Windows 用のインストーラーを取得し、署名と版を確かめる
- 前提: Broadcom のアカウントを用意してある
- 実行場所: この PC のデスクトップのブラウザと管理者の Windows PowerShell（5.1）。この項の手順 2 で開く
- Windows 11 の x64 が対象

1. ブラウザで Broadcom のサポート ポータルにログインし、VMware Workstation Pro の Windows 用のインストーラーを「ダウンロード」フォルダーに保存する。

   - ファイル名は `VMware-Workstation-Full-<版>-<ビルド番号>.exe` の形
   - **次の手順は、ダウンロードが終わってから行う**

1. Windows のデスクトップで、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. 変数を設定する（取得したインストーラーのパスが自動で入る。違えば直す）。

   ```powershell
   $VMW_SETUP = (Get-ChildItem -LiteralPath "$env:USERPROFILE\Downloads" -Filter 'VMware-Workstation-Full-*.exe' | Sort-Object LastWriteTime | Select-Object -Last 1).FullName
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $VMW_SETUP
   ```

   - いま取得したファイルのパスが出ればよい
   - **ファイル名の版とビルド番号が、取得したものと同じことを確かめる**（古いインストーラーが同じフォルダーにあると、そちらが出ることがある）
   - 違うファイルが出たときと、何も出ないとき（別の場所に保存した）は、`$VMW_SETUP = '<インストーラーのパス>'` を打って入れ直す

1. インストーラーの署名と版を確かめる。

   ```powershell
   if (-not $VMW_SETUP) { Write-Error '中断: この項の手順 3 の $VMW_SETUP が空のまま。値を入れて貼り直す' } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-AuthenticodeSignature -LiteralPath $VMW_SETUP | Format-List Status, @{ n = 'Signer'; e = { $_.SignerCertificate.Subject } }
     (Get-Item -LiteralPath $VMW_SETUP).VersionInfo | Format-List ProductName, ProductVersion
   }
   ```

   - `Status : Valid` と、`Signer` に `Broadcom Inc` が出ればよい
   - **`Status` が `Valid` でなければ中断する**（ファイルを消して取得し直す）
   - `ProductVersion` が取得した版と違えば中断し、この項の手順 3 から直す

#### VMware Workstation Pro: インストールする

- 取得したインストーラーで VMware Workstation Pro を入れる
- 前提: [VMware Workstation Pro: インストーラーを取得して確かめる](#vmware-workstation-pro-インストーラーを取得して確かめる)を通してある。Hyper-V や WSL 2 と併用するなら、[Hyper-V: Hyper-V を有効にして再起動する](#hyper-v-hyper-v-を有効にして再起動する)の手順 3 で Windows ハイパーバイザー プラットフォームを有効にしてある
- 実行場所: この PC のデスクトップの管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

> [!IMPORTANT]
> - **インストーラーはネットワークのドライバーを入れる**。SSH やリモート デスクトップのセッションからは確かめていない
> - **この項の手順 4 は、再起動が必要なときだけ行う**。開いている作業を保存し、動いている VM を止めてから進む

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開き、UAC の確認に答える

1. 変数を設定する。

   ```powershell
   $VMW_SETUP = (Get-ChildItem -LiteralPath "$env:USERPROFILE\Downloads" -Filter 'VMware-Workstation-Full-*.exe' | Sort-Object LastWriteTime | Select-Object -Last 1).FullName
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $VMW_SETUP
   ```

   - [VMware Workstation Pro: インストーラーを取得して確かめる](#vmware-workstation-pro-インストーラーを取得して確かめる)の手順 3 と同じ、署名と版を確かめたインストーラーのパスにする
   - 違うファイルが出たときと、何も出ないときは、`$VMW_SETUP = '<インストーラーのパス>'` を打って入れ直す
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. 使用許諾契約に同意して、画面無しでインストールする。

   ```powershell
   if (-not $VMW_SETUP) { Write-Error '中断: この項の手順 2 の $VMW_SETUP が空のまま。値を入れて貼り直す' } else {
     $p = Start-Process -FilePath $VMW_SETUP -ArgumentList '/s /v"/qn EULAS_AGREED=1 AUTOSOFTWAREUPDATE=0 DATACOLLECTION=0 REBOOT=ReallySuppress"' -Wait -PassThru
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     "ExitCode = $($p.ExitCode)"
   }
   ```

   - **注意**: `EULAS_AGREED=1` を付けて実行すると、VMware Workstation Pro の使用許諾契約に同意したことになる。契約を画面で読んでから進めるなら、このブロックは貼らずに、インストーラーをダブルクリックして画面で進める
   - `ExitCode = 0` なら入った。`ExitCode = 3010` は、入ったが再起動が要る
   - それ以外の値なら中断する（`%TEMP%` の `vminst.log` を見る）
   - `ExitCode = 0` で、Windows の機能の再起動待ちも無いなら、この項の手順 4 は飛ばす

1. `ExitCode = 3010` のときと、Windows の機能（Hyper-V など）が再起動待ちのときだけ、再起動する。

   ```powershell
   Restart-Computer
   ```

   - **開いている作業を保存し、動いている VM を止めてから貼る**（確認を聞かずに再起動が始まる）
   - Hyper-V の手順書の途中から来たなら、[Hyper-V の「Hyper-V を有効にして再起動する」の手順 5](#hyper-v-hyper-v-を有効にして再起動する)の再起動がこれに当たる（再起動は 1 回でよい）
   - **次の手順は、起動してサインインしてから行う**

#### VMware Workstation Pro: 入ったかを確かめる

- 入った版と、コマンドの場所、仮想ネットワークを確かめる
- 前提: [VMware Workstation Pro: インストールする](#vmware-workstation-pro-インストールする)を通し、必要な再起動を済ませてサインインしてある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 入った版と、コマンドの場所、仮想ネットワークを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   $VMW_DIR = @("$env:ProgramFiles\VMware\VMware Workstation", "${env:ProgramFiles(x86)}\VMware\VMware Workstation") | Where-Object { Test-Path -LiteralPath "$_\vmrun.exe" } | Select-Object -First 1
   if (-not $VMW_DIR) { Write-Error 'vmrun.exe が見つからない。インストールできていない' } else {
     $VMW_DIR
     (Get-Item -LiteralPath "$VMW_DIR\vmware.exe").VersionInfo | Format-List ProductName, ProductVersion
     & "$VMW_DIR\vmrun.exe" -T ws list
     Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'VMware Network Adapter*' | Format-Table InterfaceAlias, IPAddress, PrefixLength
   }
   ```

   - インストール先のフォルダーと版が出て、`Total running VMs: 0` が出ればよい
   - `VMware Network Adapter VMnet1`（この PC と VM だけ）と `VMnet8`（NAT）の行が出る

#### VMware Workstation Pro: VM を作る

- この PC に、AlmaLinux などの VM を作る
- 前提: [VMware Workstation Pro: 入ったかを確かめる](#vmware-workstation-pro-入ったかを確かめる)を通し、入れる OS のインストール用の ISO を用意してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く
- Windows 11 を入れる VM（仮想 TPM が要る）は、この項では扱わない

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`VMW_ISO` は必ず値を入れる）。

   ```powershell
   $VMW_ISO = ''
   ```

   ```powershell
   $VMW_VM = 'alma10'
   $VMW_BASE = "$env:USERPROFILE\VMware"
   $VMW_GUEST = 'almalinux-64'
   $VMW_CPU = 2
   $VMW_MEM_MB = 4096
   $VMW_DISK = '64GB'
   $VMW_DIR = @("$env:ProgramFiles\VMware\VMware Workstation", "${env:ProgramFiles(x86)}\VMware\VMware Workstation") | Where-Object { Test-Path -LiteralPath "$_\vmrun.exe" } | Select-Object -First 1
   $VMW_VMX = "$VMW_BASE\$VMW_VM\$VMW_VM.vmx"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ VMW_ISO = $VMW_ISO; VMW_VM = $VMW_VM; VMW_VMX = $VMW_VMX; VMW_GUEST = $VMW_GUEST; VMW_CPU = $VMW_CPU; VMW_MEM_MB = $VMW_MEM_MB; VMW_DISK = $VMW_DISK; VMW_DIR = $VMW_DIR } | Format-List
   ```

   - `$VMW_ISO` は、入れる OS のインストール用の ISO のパス
   - `$VMW_VM` は VM の名前、`$VMW_BASE` は VM を置くフォルダー（その下に VM の名前のフォルダーができる）
   - `$VMW_GUEST` は入れる OS の種類（既定は AlmaLinux）。この項は、Windows 11 を入れる VM（仮想 TPM が要る）を扱わない
   - `VMW_DIR` が空なら、VMware Workstation が入っていない。[インストールする](#vmware-workstation-pro-インストールする)から
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. VM の設定ファイルとディスクを作る。

   ```powershell
   if (-not $VMW_ISO -or -not $VMW_VM -or -not $VMW_BASE -or -not $VMW_DIR -or -not $VMW_VMX -or -not $VMW_GUEST -or -not $VMW_DISK) { Write-Error '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' } elseif (-not (Test-Path -LiteralPath $VMW_ISO)) { Write-Error "中断: ISO が無い: $VMW_ISO" } elseif (Test-Path -LiteralPath "$VMW_BASE\$VMW_VM") { Write-Error "中断: 同じ名前のフォルダーがすでにある: $VMW_BASE\$VMW_VM" } else {
     & "$VMW_DIR\vmcli.exe" VM Create -n $VMW_VM -d "$VMW_BASE\$VMW_VM" -c $VMW_GUEST
     Remove-Item -LiteralPath "$VMW_BASE\$VMW_VM\$VMW_VM.vmdk"
     & "$VMW_DIR\vmcli.exe" $VMW_VMX Disk Create -f "$VMW_BASE\$VMW_VM\$VMW_VM.vmdk" -a lsilogic -s $VMW_DISK -t 0
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ChildItem -LiteralPath "$VMW_BASE\$VMW_VM" | Format-Table Name, Length
   }
   ```

   - `VMX file is created` と `Virtual disk file creation is successful` が出て、一覧に `.vmx` と `.vmdk` が並べばよい

1. ファームウェア・CPU・メモリ・ディスク・ISO・NIC を設定する。

   ```powershell
   if (-not $VMW_ISO -or -not $VMW_VM -or -not $VMW_BASE -or -not $VMW_DIR -or -not $VMW_VMX -or -not $VMW_CPU -or -not $VMW_MEM_MB) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   $vmcli = "$VMW_DIR\vmcli.exe"
   & $vmcli $VMW_VMX ConfigParams SetEntry displayName $VMW_VM
   & $vmcli $VMW_VMX ConfigParams SetEntry firmware efi
   & $vmcli $VMW_VMX ConfigParams SetEntry cpuid.coresPerSocket $VMW_CPU
   & $vmcli $VMW_VMX Chipset SetVCpuCount $VMW_CPU
   & $vmcli $VMW_VMX Chipset SetMemSize $VMW_MEM_MB
   & $vmcli $VMW_VMX MKS SetAccel3d false
   & $vmcli $VMW_VMX Nvme SetPresent nvme0 1
   & $vmcli $VMW_VMX Disk SetBackingInfo nvme0:0 disk "$VMW_BASE\$VMW_VM\$VMW_VM.vmdk" 0
   & $vmcli $VMW_VMX Disk SetPresent nvme0:0 1
   & $vmcli $VMW_VMX Sata SetPresent sata0 1
   & $vmcli $VMW_VMX Disk SetBackingInfo sata0:0 cdrom_image $VMW_ISO 0
   & $vmcli $VMW_VMX Disk SetPresent sata0:0 1
   & $vmcli $VMW_VMX Ethernet SetVirtualDevice ethernet0 vmxnet3
   & $vmcli $VMW_VMX Ethernet SetConnectionType ethernet0 nat
   & $vmcli $VMW_VMX Ethernet SetPresent ethernet0 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Content -LiteralPath $VMW_VMX | Select-String -Pattern '^(displayName|guestOS|firmware|numvcpus|memsize|mks\.enable3d|nvme0|sata0|ethernet0)'
   ```

   - `firmware = "efi"`、`numvcpus`、`memsize`、`nvme0:0.fileName`、`sata0:0.fileName`（ISO）、`ethernet0.connectionType = "nat"` の行が出ればよい
   - `mks.enable3d` の行は出ない（3D を切った）

#### VMware Workstation Pro: VM を起動して OS を入れる

- 作った VM を起動し、OS をインストールする
- 前提: [VMware Workstation Pro: VM を作る](#vmware-workstation-pro-vm-を作る)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`VMW_VM` は必ず値を入れる）。

   ```powershell
   $VMW_VM = ''
   ```

   ```powershell
   $VMW_BASE = "$env:USERPROFILE\VMware"
   $VMW_DIR = @("$env:ProgramFiles\VMware\VMware Workstation", "${env:ProgramFiles(x86)}\VMware\VMware Workstation") | Where-Object { Test-Path -LiteralPath "$_\vmrun.exe" } | Select-Object -First 1
   $VMW_VMX = "$VMW_BASE\$VMW_VM\$VMW_VM.vmx"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ VMW_VM = $VMW_VM; VMW_BASE = $VMW_BASE; VMW_VMX = $VMW_VMX; VMW_DIR = $VMW_DIR } | Format-List
   ```

   - `VMW_VM` と `VMW_BASE` は、[VMware Workstation Pro: VM を作る](#vmware-workstation-pro-vm-を作る)の手順 2 と同じ値にする
   - `VMW_DIR` が空なら、[VMware Workstation Pro: 入ったかを確かめる](#vmware-workstation-pro-入ったかを確かめる)から確かめ直す
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. VM を起動する。

   ```powershell
   if (-not $VMW_VM -or -not $VMW_BASE -or -not $VMW_DIR -or -not $VMW_VMX) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   & "$VMW_DIR\vmrun.exe" -T ws start $VMW_VMX
   ```

   - `PID: <番号>, log output: <ログのパス>` の 1 行が出て、VMware Workstation のウィンドウが開き、VM が起動する

1. VM の画面で、OS のインストーラーを最後まで進める。

   - VM の画面をクリックすると、キーとマウスが VM に入る。Ctrl+Alt でこの PC に戻る
   - インストーラーが最後に再起動するか、電源を切るまで進める
   - **次の手順は、インストールが終わり、VM の電源を切ってから貼る**

1. ISO を外す。

   ```powershell
   if (-not $VMW_VM -or -not $VMW_BASE -or -not $VMW_DIR -or -not $VMW_VMX) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   & "$VMW_DIR\vmcli.exe" $VMW_VMX Disk SetPresent sata0:0 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   "sata0:0.present の行の数: $(@(Select-String -LiteralPath $VMW_VMX -Pattern '^sata0:0\.present').Count)"
   ```

   - `sata0:0.present の行の数: 0` が出ればよい

#### VMware Workstation Pro: 動作を確かめる

- この PC で VM の起動と、ゲストの IP・SSH を確かめる
- 前提: [VMware Workstation Pro: VM を起動して OS を入れる](#vmware-workstation-pro-vm-を起動して-os-を入れる)を通し、VM を止めてある。SSH を確かめるときは、ゲストの SSH サーバーとファイアウォールを設定してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`VMW_VM` は必ず値を入れる）。

   ```powershell
   $VMW_VM = ''
   ```

   ```powershell
   $VMW_BASE = "$env:USERPROFILE\VMware"
   $VMW_DIR = @("$env:ProgramFiles\VMware\VMware Workstation", "${env:ProgramFiles(x86)}\VMware\VMware Workstation") | Where-Object { Test-Path -LiteralPath "$_\vmrun.exe" } | Select-Object -First 1
   $VMW_VMX = "$VMW_BASE\$VMW_VM\$VMW_VM.vmx"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ VMW_VM = $VMW_VM; VMW_BASE = $VMW_BASE; VMW_VMX = $VMW_VMX; VMW_DIR = $VMW_DIR } | Format-List
   ```

   - `VMW_VM` と `VMW_BASE` は、[VMware Workstation Pro: VM を作る](#vmware-workstation-pro-vm-を作る)の手順 2 と同じ値にする
   - `VMW_DIR` が空なら、[VMware Workstation Pro: 入ったかを確かめる](#vmware-workstation-pro-入ったかを確かめる)から確かめ直す
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. VM を画面無しで起動し、Hyper-V の上で動いているかと、ゲストの IP を確かめる。

   ```powershell
   if (-not $VMW_VM -or -not $VMW_BASE -or -not $VMW_DIR -or -not $VMW_VMX) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   & "$VMW_DIR\vmrun.exe" -T ws start $VMW_VMX nogui
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$VMW_DIR\vmrun.exe" -T ws list
   Select-String -LiteralPath "$VMW_BASE\$VMW_VM\vmware.log" -Pattern 'Monitor Mode:' | Select-Object -Last 1 | ForEach-Object { ($_.Line -split '\] ')[-1] }
   & "$VMW_DIR\vmrun.exe" -T ws readVariable $VMW_VMX guestVar ip
   ```

   - `Total running VMs: 1` と、VM の `.vmx` のパスが出ればよい
   - **`Monitor Mode: ULM` なら、VM は Windows のハイパーバイザー（Hyper-V）の上で動いている**（遅くなる）
   - 最後の行にゲストの IP が出る。空なら、ゲストがまだ起動の途中。少し待って、最後の行だけを打ち直す
   - ゲストに VMware Tools（Linux は `open-vm-tools`）が入っていないと、IP は出ない（AlmaLinux 10 の Workstation には入っている）

1. Linux のゲストなら、この PC から SSH で入れるかを確かめる。

   - この項の手順 1 で開いた PowerShell で `ssh <ゲストのユーザー>@<ゲストの IP>` を打つ（IP はこの項の手順 3 の最後の行）
   - ゲストのプロンプトが出ればよい。`exit` で戻る

#### VMware Workstation Pro: 使い方の基本

- 管理者ではない Windows PowerShell 5.1 で打つ。`<vmx>` は VM の `.vmx` のパス。`$VMW_DIR` は[VM を作る](#vmware-workstation-pro-vm-を作る)の手順 2 で設定する

| すること | コマンド |
|---|---|
| 動いている VM の一覧 | `vmrun.exe -T ws list` |
| 起動する（ウィンドウを開く） | `vmrun.exe -T ws start <vmx>` |
| 起動する（画面無し） | `vmrun.exe -T ws start <vmx> nogui` |
| ゲストに電源を切らせる | `vmrun.exe -T ws stop <vmx> soft` |
| 電源を切る（ゲストに知らせない） | `vmrun.exe -T ws stop <vmx> hard` |
| ゲストの IP を見る | `vmrun.exe -T ws readVariable <vmx> guestVar ip` |
| 画面を PNG に撮る | `vmcli.exe <vmx> MKS captureScreenshot <PNG のパス>` |
| 画面に文字を打つ | `vmcli.exe <vmx> MKS sendKeySequence <文字列>` |
| CPU の数を変える（止めてから） | `vmcli.exe <vmx> Chipset SetVCpuCount 4` |
| メモリを変える（止めてから） | `vmcli.exe <vmx> Chipset SetMemSize 8192` |

#### VMware Workstation Pro: スナップショットとクローン

- スナップショットを取って戻し、その時点から別の VM（リンククローン）を作る
- 前提: [VMware Workstation Pro: 動作を確かめる](#vmware-workstation-pro-動作を確かめる)まで通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

> [!WARNING]
> **この項の手順 5 で作った VM があるあいだは、元の VM とそのスナップショットを消さない**。リンククローンは元の VM のディスクを読むので、消すと起動しなくなる。

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する（`VMW_VM` は必ず値を入れる）。

   ```powershell
   $VMW_VM = ''
   ```

   ```powershell
   $VMW_BASE = "$env:USERPROFILE\VMware"
   $VMW_DIR = @("$env:ProgramFiles\VMware\VMware Workstation", "${env:ProgramFiles(x86)}\VMware\VMware Workstation") | Where-Object { Test-Path -LiteralPath "$_\vmrun.exe" } | Select-Object -First 1
   $VMW_VMX = "$VMW_BASE\$VMW_VM\$VMW_VM.vmx"
   $VMW_SNAPSHOT = 'clean-install'
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ VMW_VM = $VMW_VM; VMW_BASE = $VMW_BASE; VMW_VMX = $VMW_VMX; VMW_DIR = $VMW_DIR; VMW_SNAPSHOT = $VMW_SNAPSHOT } | Format-List
   ```

   - `VMW_VM` と `VMW_BASE` は、[VMware Workstation Pro: VM を作る](#vmware-workstation-pro-vm-を作る)の手順 2 と同じ値にする
   - `VMW_DIR` が空なら、[VMware Workstation Pro: 入ったかを確かめる](#vmware-workstation-pro-入ったかを確かめる)から確かめ直す
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. VM を止めて、スナップショットを取る。

   ```powershell
   if (-not $VMW_VM -or -not $VMW_BASE -or -not $VMW_DIR -or -not $VMW_VMX -or -not $VMW_SNAPSHOT) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   & "$VMW_DIR\vmrun.exe" -T ws stop $VMW_VMX soft
   & "$VMW_DIR\vmrun.exe" -T ws snapshot $VMW_VMX $VMW_SNAPSHOT
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$VMW_DIR\vmrun.exe" -T ws listSnapshots $VMW_VMX
   ```

   - `Total snapshots: 1` と、付けた名前が出ればよい
   - VM がすでに止まっていれば、`stop` は `Error: The virtual machine is not powered on` を出す（そのまま進んでよい）

1. VM をスナップショットの時点に戻すときは、VM を止めてから戻す。

   ```powershell
   if (-not $VMW_VM -or -not $VMW_BASE -or -not $VMW_DIR -or -not $VMW_VMX -or -not $VMW_SNAPSHOT) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   & "$VMW_DIR\vmrun.exe" -T ws stop $VMW_VMX hard
   & "$VMW_DIR\vmrun.exe" -T ws revertToSnapshot $VMW_VMX $VMW_SNAPSHOT
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   & "$VMW_DIR\vmrun.exe" -T ws listSnapshots $VMW_VMX
   ```

   - **スナップショットより後の変更は消える**
   - VM がすでに止まっていれば、`stop` は `Error: The virtual machine is not powered on` を出す（そのまま進んでよい）

1. スナップショットの時点から、リンククローンで別の VM を作る。

   ```powershell
   if (-not $VMW_VM -or -not $VMW_BASE -or -not $VMW_DIR -or -not $VMW_VMX -or -not $VMW_SNAPSHOT) { throw '中断: この項の手順 2 の変数が空のまま。値を入れて貼り直す' }
   $VMW_CLONE = "$VMW_VM-clone"
   if (Test-Path -LiteralPath "$VMW_BASE\$VMW_CLONE") { Write-Error "中断: 同じ名前のフォルダーがすでにある: $VMW_BASE\$VMW_CLONE" } else {
     & "$VMW_DIR\vmrun.exe" -T ws clone $VMW_VMX "$VMW_BASE\$VMW_CLONE\$VMW_CLONE.vmx" linked "-snapshot=$VMW_SNAPSHOT" "-cloneName=$VMW_CLONE"
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ChildItem -LiteralPath "$VMW_BASE\$VMW_CLONE" | Format-Table Name, Length
     Get-Content -LiteralPath "$VMW_BASE\$VMW_CLONE\$VMW_CLONE.vmx" | Select-String -Pattern '^(displayName|nvme0:0\.fileName)'
   }
   ```

   - 新しいフォルダーに `.vmx` と、小さい `.vmdk`（差分）ができればよい
   - 新しい VM は、ホスト名もログインも元の VM と同じ。起動してから、ゲストの中でホスト名を変える
   - 起動: `& "$VMW_DIR\vmrun.exe" -T ws start "$VMW_BASE\$VMW_CLONE\$VMW_CLONE.vmx" nogui`
   - IP の確認: `& "$VMW_DIR\vmrun.exe" -T ws readVariable "$VMW_BASE\$VMW_CLONE\$VMW_CLONE.vmx" guestVar ip`

#### VMware Workstation Pro: VM を消す

- VM の登録とディスクを消す
- 前提: [VMware Workstation Pro: 入ったかを確かめる](#vmware-workstation-pro-入ったかを確かめる)を通してある
- 実行場所: この PC のデスクトップの管理者ではない Windows PowerShell（5.1）。この項の手順 1 で開く

> [!CAUTION]
> **この項の手順 3 は、VM のディスクごと消す（取り戻せない）**。[スナップショットとクローン](#vmware-workstation-pro-スナップショットとクローン)の手順 5 で、この VM から作った VM が残っているなら、先にそちらを消す。

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）

1. 変数を設定する。

   ```powershell
   $VMW_DIR = @("$env:ProgramFiles\VMware\VMware Workstation", "${env:ProgramFiles(x86)}\VMware\VMware Workstation") | Where-Object { Test-Path -LiteralPath "$_\vmrun.exe" } | Select-Object -First 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   [pscustomobject]@{ VMW_DIR = $VMW_DIR } | Format-List
   ```

   - `VMW_DIR` が空なら、[VMware Workstation Pro: 入ったかを確かめる](#vmware-workstation-pro-入ったかを確かめる)から確かめ直す
   - **新しい窓を開いたら**、この項の手順 2 を貼り直してから先へ進む

1. VM を止めて、登録とファイルを消す（取り戻せない）。

   ```powershell
   $VMW_REMOVE = ''
   ```

   ```powershell
   if (-not $VMW_DIR) { Write-Error '中断: この項の手順 2 の $VMW_DIR が空のまま。インストールを確かめ直す' } elseif (-not $VMW_REMOVE) { Write-Error '中断: $VMW_REMOVE が空のまま。消す VM の .vmx のパスを入れて貼り直す' } elseif (-not (Test-Path -LiteralPath $VMW_REMOVE)) { Write-Error "中断: .vmx が無い: $VMW_REMOVE" } else {
     & "$VMW_DIR\vmrun.exe" -T ws stop $VMW_REMOVE hard
     & "$VMW_DIR\vmrun.exe" -T ws deleteVM $VMW_REMOVE
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     & "$VMW_DIR\vmrun.exe" -T ws list
     Test-Path -LiteralPath $VMW_REMOVE
   }
   ```

   - 最後に `False` が出ればよい
   - VM が止まっていれば、`stop` は `Error: The virtual machine is not powered on` を出す（そのまま進んでよい）

---

### Windows Sandbox で配布物を試す

- Windows Sandbox の一時的な Windows で、配布物の起動と必要な操作を試す
- 前提: Windows 11 Pro・Enterprise・Education などの対応エディション（Home は不可）、AMD64 または ARM64（ARM64 は 22H2 以降）。UEFI / BIOS で仮想化を有効にし、RAM 4 GB 以上・ディスクの空き 1 GB 以上・CPU 2 コア以上を用意してある。Windows の VM の中では、入れ子の仮想化も有効にしてある
- 実行場所: この PC のデスクトップ。状態確認・有効化・再起動は、この項の手順 1 で開く管理者の Windows PowerShell（5.1）。起動・試験・窓を閉じた後の確認は、通常のデスクトップと Sandbox の画面
- **この項の手順 4 は、再起動が必要な場合だけ行う**。先に開いているファイルを保存し、実行中の作業を終える
- [参考資料](reference/windows-sandbox.md#windows-sandbox-で配布物を試す--手順-2-補足-対応環境)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-sandbox.md)

> [!CAUTION]
> **この項の手順 8 で Sandbox 内のファイルとアプリの状態が消える**。残す結果をホストへコピーしてから閉じる。

1. スタートメニューから、管理者の Windows PowerShell を開く。

   - 「Windows PowerShell」を検索し、右クリック →「管理者として実行」で開き、UAC の確認に答える
   - タスク マネージャー →「パフォーマンス」→「CPU」で「仮想化」が「有効」になっていることを確かめる。無効なら、UEFI / BIOS で有効にしてから、この項を始め直す
   - Windows のエディション・アーキテクチャと、RAM・ディスクの空き・CPU のコア数が、この項の前提を満たすことを確かめる
   - **次の手順は、管理者の Windows PowerShell が開いてから貼る**

1. 管理者の Windows PowerShell で、Windows Sandbox の変更前の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -ErrorAction Stop | Select-Object FeatureName, State
   ```

   - `FeatureName` が `Containers-DisposableClientVM` であることを確かめ、`State` を控える
   - `Disabled` または `DisabledWithPayloadRemoved` なら、この項の手順 3 に進む
   - `Enabled` なら、この項の手順 3・4 は飛ばす
   - `EnablePending` または `DisablePending` なら、この項の手順 3 は飛ばし、手順 4 で再起動する。再起動したらこの項の手順 2 に戻り、変更前の状態を控え直す
   - エラーや、ここに挙げていない `State` が出たら中断する

1. 無効だったときだけ、Windows Sandbox を有効にする。

   ```powershell
   & {
     $feature = Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -ErrorAction Stop
     if ($feature.State -in 'Disabled', 'DisabledWithPayloadRemoved') {
       "`n$([char]27)[7m 確認 $([char]27)[0m"
       Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All -NoRestart -ErrorAction Stop | Select-Object Online, RestartNeeded
       Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -ErrorAction Stop | Select-Object FeatureName, State
     } elseif ($feature.State -eq 'Enabled') {
       "`n$([char]27)[7m 確認 $([char]27)[0m"
       $feature | Select-Object FeatureName, State
     } else {
       Write-Error '中断: 状態が変わった。この項の手順 2 に戻って確かめる'
     }
   }
   ```

   - エラーが無く、最後の `State` が `Enabled` または `EnablePending` なら適用できている
   - `RestartNeeded` が `True`、または `State` が `EnablePending` なら、この項の手順 4 で再起動する
   - `RestartNeeded` が `False` で `State` が `Enabled` なら、この項の手順 4 は飛ばす
   - 既に `Enabled` だった場合も変更せず、この項の手順 4 は飛ばす
   - エラー・`中断:`・ここに挙げていない結果が出たら、再起動と起動確認へ進まず、この項の手順 2 に戻る

1. 再起動が必要なときだけ、作業を保存してホストを再起動する。

   ```powershell
   Restart-Computer
   ```

   - Windows が起動したらサインインし、この項の手順 1 と同じ管理者の Windows PowerShell を開く
   - この項の手順 2 で `EnablePending` または `DisablePending` だった場合は、同じ手順 2 に戻る
   - **次の手順は、Windows が起動して管理者の Windows PowerShell を開いてから貼る**

1. 管理者の Windows PowerShell で、Windows Sandbox が有効になったことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -ErrorAction Stop | Select-Object FeatureName, State
   ```

   - `State` が `Enabled` なら、この項の手順 6 に進む
   - エラーや `Enabled` 以外の状態なら中断し、この項の手順 2 に戻る

1. 通常のデスクトップのスタートメニューから、Windows Sandbox を起動する。

   - 管理者の PowerShell を閉じ、スタートメニューで「Windows Sandbox」を検索して開く
   - Windows Sandbox の窓の中に、別の Windows のデスクトップが表示されればよい
   - 起動に失敗したら、表示されたエラーを控え、この項の手順 7・8 へ進まない

1. Sandbox の中で、配布物の起動と必要な操作を試す。

   - ホストで配布物をコピーし、Sandbox の中のデスクトップへ貼り付ける
   - Sandbox の中で配布物を起動し、必要な操作ができることを確かめる。エラーや不足する依存ライブラリがあれば控える
   - Sandbox の中のデスクトップで右クリック →「新規作成」→「フォルダー」を選び、`sandbox-check` という名前にする（この項の手順 8 で使う）

1. Sandbox の窓を閉じて内部の状態を消し（取り戻せない）、起動し直して確かめる。

   - 残す結果をホストへコピーし、Sandbox の窓の右上の「×」を押す。内容を破棄する確認に答える
   - 通常のデスクトップのスタートメニューから「Windows Sandbox」をもう一度開く
   - Sandbox の中のデスクトップに、配布物と `sandbox-check` フォルダーが無ければよい
   - 確かめ終わったら、Sandbox の窓を閉じる

---
