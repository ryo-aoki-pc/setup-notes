# VirtualBox インストール手順（AlmaLinux 10 は Oracle 公式 dnf リポジトリ / Windows 11 は winget）

## 実施手順

- [検証記録](verification/virtualbox.md)・[参考資料](reference/virtualbox.md)・[ロールバックと注意点](extra/virtualbox.md)

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（管理者の Windows PowerShell 5.1 に貼る。下の EPEL と Secure Boot の前提、KVM の設定は要らない）
> - **前提**: [AlmaLinux 10 の初期設定の手順 17](almalinux-setup.md#実施手順) で EPEL を有効にしてあること（依存の `liblzf` が EPEL にしか無い）。`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す
> - **前提（Secure Boot が有効な PC）**: [secure-boot-mok.md](secure-boot-mok.md) で、モジュールの署名鍵を MOK に登録してあること（VirtualBox を入れるより前に。同書で再起動し、起動の途中の MokManager を操作する）。Secure Boot が有効かは、同書の手順 3 で分かる
> - **対象ホスト（x86_64 の PC）上で実行する**。VirtualBox には Linux の arm64 版が無いので、Raspberry Pi 5（aarch64）には入らない
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない
> - **途中で再起動が 1 回入る**（手順 13）。再起動した後は新しい端末を開いて続ける
> - **手順 4・5・9 には対話入力がある**（鍵の確認・`[y/N]`）。答えてから次の手順を貼る
> - **手順 17 で GUI のウィンドウが開く**（デスクトップにログインした端末から行う）。閉じてから手順 18 を貼る

- 上から順にコードブロックを貼る
- 手順の後: カーネルを更新したときは[カーネルを更新したとき](#カーネルを更新したとき)、以後の VirtualBox の更新は[更新](#更新)、戻すときは[ロールバック](extra/virtualbox.md#ロールバック)

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

   - 最初の 1 回だけ鍵の取り込みを聞かれる
   - `Importing GPG key 0x2980AECF:` の `Fingerprint:` が、手順 2 と同じ `B9F8 D658 297A F3EF C18D 5CDF A2F6 83C5 2980 AECF` であることを確かめて `y` と答える
   - `Metadata cache created.` で終わる
   - **次の手順は、鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. `sudo` を付けない dnf にも、同じ鍵の確認を 1 回だけ通す。

   ```bash
   dnf makecache --repo virtualbox
   ```

   - 手順 4 と同じ fingerprint を確かめて `y` と答える
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

1. 何が入るかを見る（`--assumeno` は必ず中断する）。

   ```bash
   sudo dnf install --assumeno VirtualBox-7.2
   ```

   - `VirtualBox-7.2 ... 7.2.20_175154_el10-1 ... virtualbox ... 105 M` と、依存の中に `liblzf ... epel` が出れば解決できている
   - `nothing provides liblzf.so.1()(64bit)` と出たら、EPEL が有効になっていない（[AlmaLinux 10 の初期設定の手順 17](almalinux-setup.md#実施手順)）

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

   - 6 つとも版が出て、最後の行がディレクトリを返せばよい
   - `No such file or directory` なら、kernel-devel の版が合っていない

1. VirtualBox を入れる。

   ```bash
   sudo dnf install VirtualBox-7.2
   ```

   - トランザクション表を見て、`[y/N]` に `y` と答える
   - **EPEL の署名鍵をまだ取り込んでいなければ、続けて 1 回だけ確認を求められる**（[AlmaLinux 10 の初期設定の手順 17](almalinux-setup.md#実施手順) に書いた鍵）
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

   - `cat` と `modprobe -c` のどちらにも `options kvm enable_virt_at_load=0` が出ればよい
   - `modprobe -c` には `alias symbol:enable_virt_at_load kvm` の行も出る（モジュールの別名の一覧の行で、気にしなくてよい）

1. USB 機器を VM に渡すときだけ、自分を `vboxusers` に入れて確かめる。

   ```bash
   {
     sudo usermod -aG vboxusers "${USER}"
     getent group vboxusers
   }
   ```

   - **VM を動かすだけなら要らない**（この手順は飛ばして手順 13 へ）
   - `vboxusers:x:<GID>:<USER>` のように、自分の名前が出ればよい

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
   - [手順 10](#実施手順) と同じ確認をする
   - **[手順 10](#実施手順) の確認は、`[y/N]` に答えて `Complete!` が出てから貼る**（続けて貼ると答えとして食われる）

1. 系列を変えるときは（この節の手順 2 の代わりに）、[ロールバック](extra/virtualbox.md#ロールバック)の手順 2 だけを行う。

   - [ロールバック](extra/virtualbox.md#ロールバック)の手順 2 は `sudo dnf remove VirtualBox-7.2`
   - `[y/N]` に答えてから、この節の手順 4 に進む

1. 系列を変えるときは、パッケージ名を新しい系列に置き換えて、[手順 6](#実施手順) の下見と手順 9 からやり直す。

   - 手順 6・9 の `VirtualBox-7.2` を、新しい系列の名前（`VirtualBox-7.3` など）に置き換えて貼る
   - 以後は、この節の手順 2 と[ロールバック](extra/virtualbox.md#ロールバック)の手順 2 も同じく置き換える

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows 11 の PC のデスクトップで行う**。SSH やリモート デスクトップのセッションからは行わない（この節の手順 3 の途中でネットワークがいったん切れ、手順 7 は画面で行う）
> - この節の手順 1 で**管理者の** Windows PowerShell（5.1）を開き、この節の手順 2〜4 と、[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/virtualbox.md#windows-11-のロールバック)のブロックをそこに貼る。この節の手順 5 で**管理者ではない** Windows PowerShell を開き、手順 6・8 をそこに貼る
> - ログインするユーザーは Administrators の一員（VirtualBox は PC 全体に入り、ドライバーを入れる）
> - 前提: [Windows 11 の初期設定の手順 16〜19](windows-setup.md#実施手順)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - **AlmaLinux 10 の前提（EPEL・Secure Boot の MOK の鍵）と KVM の設定は要らない**。Windows のドライバーは、Microsoft の署名付きでインストーラに入っている

- 上から順にコードブロックを貼る。変数は無い
- 手順の後: 以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/virtualbox.md#windows-11-のロールバック)
- Android の Windows App からリモート デスクトップでつないで VM に打つなら、[Windows 11 の VirtualBox を Android からリモート デスクトップで使う](#windows-11-の-virtualbox-を-android-からリモート-デスクトップで使う任意)
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
   - `Hypervisor` が `False` で `VirtFirmware` も `False` なら、PC の UEFI（BIOS）の設定で Intel VT-x / AMD-V（SVM）を有効にしてから始める
   - `VirtualBox` が `True` なら、もう入っている。この節の手順 3 は飛ばす（新しい版にするなら[Windows 11 の更新](#windows-11-の更新)）

1. VirtualBox が入っていないときだけ、winget で入れる。

   ```powershell
   winget install --exact --id Oracle.VirtualBox --source winget --accept-source-agreements --accept-package-agreements
   ```

   - **途中でネットワークがいったん切れる**
   - インストーラの画面は出ず、進み具合だけが出る。最後に、入れ終えた旨の行（英語の表示では `Successfully installed`）が出ればよい
   - **次の手順は、winget が終わってプロンプトに戻ってから貼る**（続けて貼ると、winget が何か聞いたときの答えとして食われる）

1. 入ったか、ドライバーとホストオンリーのアダプターができたかを確かめる。

   ```powershell
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
   - この節の手順 1 の管理者の窓は、[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/virtualbox.md#windows-11-のロールバック)で使う。閉じてもよい

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

   - `VM "vbox-selftest" has been successfully started.` と `VMState="running"` が出れば動いている
   - **`fall back to NEM` か `Snail execution mode` を含む行が出たら、VM は Hyper-V の上で動いている**（遅くなる。[注意点](extra/virtualbox.md#注意点)）
   - その行が出なければ、VirtualBox は VT-x / AMD-V を直接使っているはず
   - `poweroff` と `unregistervm` は `0%...100%` の行を出し、VM の登録と設定のファイルが消える
   - `%USERPROFILE%\VirtualBox VMs\vbox-selftest\Logs\VBoxHardening.log` が残ることがある。要らなければ `vbox-selftest` のフォルダーを手で消す
   - 既に `vbox-selftest` があれば、変更せず中断する。別の名前で試すなら、ブロック中の `vbox-selftest` をすべて同じ名前に変える

1. スタートメニューの「Oracle VirtualBox」で VirtualBox マネージャーを開き、閉じる。

   - デスクトップのショートカットでも、この節の手順 6 の窓で `& "$env:ProgramFiles\Oracle\VirtualBox\VirtualBox.exe"` を打っても同じ
   - VirtualBox マネージャーのウィンドウが開く（一覧は空）
   - 右クリックの「管理者として実行」では開かない
   - **次の手順は、ウィンドウを閉じてから貼る**

1. `%USERPROFILE%\.VirtualBox` に設定ができたか確かめる。

   ```powershell
   Get-ChildItem -LiteralPath "$env:USERPROFILE\.VirtualBox" | Format-Table Name, Length
   ```

   - `VirtualBox.xml`・`VBoxSVC.log` などが並べばよい

---

## Windows 11 の VirtualBox を Android からリモート デスクトップで使う（任意）

> [!IMPORTANT]
> - **この節は Android の Windows App の画面で行う**。PC と VirtualBox の設定は変えない
> - 前提: この PC がリモート デスクトップを受け付けていること（[Windows 11 の初期設定の手順 44](windows-setup.md#実施手順)）と、[Windows 11 で使う](#windows-11-で使う)で入れた VirtualBox

- Windows App は既定で、打った文字を Unicode で送る。VirtualBox の VM のウィンドウはその文字コードをキーとして読むので、別のキーになる（`1.,2` が `nczm`。[参考資料](reference/virtualbox.md#windows-11-の-virtualbox-を-android-からリモート-デスクトップで使う任意--手順-1-補足-文字が別のキーになる理由)）
- この節で、Windows App がキーの位置（スキャンコード）を送るようにする。Windows App のすべての接続にかかる
- 日本語は Android の IME では打てなくなる。PC の IME は、物理キーボードの `` Alt+` `` で切り替える（Ctrl+Space は Android が受け取る）
- 実測は[検証記録](verification/virtualbox.md#付録-android-の-windows-app-からリモート-デスクトップでつないだときのキー入力2026-10-08)

1. Android の Windows App の設定で、「使用可能な場合にスキャンコード入力を使用する」をオンにする。

   - プロファイルのアイコンをタップして設定を開き、「全般」をタップする
   - 英語の表示では「Use scancode input when available」
   - 接続している間に変えても、セッションに戻るとすぐ効いた（つなぎ直さなくてよい）

1. Windows App でこの PC につなぎ、VM のウィンドウで文字を打って確かめる。

   - VM のウィンドウのタイトル バーをタップして前に出してから打つ
   - 打った英数字がそのまま VM に出ればよい（`1.,2` が `nczm` にならない）
   - 物理キーボード（US 配列）では、Shift で打つ記号（`@`・`:`）も出る
   - **画面のキーボード（Gboard）では、Shift で打つ記号に Shift が付かない**（`@` が `2`、`:` が `;`、`!` が `1`。PC のメモ帳でも同じ）
   - 英字の大文字は、画面のキーボードでも出る
   - 物理キーボードの右 Ctrl は、VirtualBox のホスト キー。右 Ctrl との組み合わせは、ゲストではなく VirtualBox が受け取る

1. 画面のキーボードで Shift の記号を打つときだけ、VirtualBox のソフトキーボードで打つ。

   - VM のウィンドウのメニューの「入力」→「キーボード」→「Soft Keyboard...」で開く（7.2.20 では、日本語の表示でもこの項目は英語）
   - 開いたキーボードの Shift をタップしてから `2` をタップすると、`@` が出る
   - メニュー バーが無いときは、VM のウィンドウがスケール モード（メニュー バーを出さない形）になっている
   - スケール モードは、PC で `& "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" setextradata <VM 名> GUI/Scale` を実行すると、VM を動かしたまま元の形に戻る

1. 元に戻すときは、この節の手順 1 の項目をオフにする。

   - Windows App は、打った文字を Unicode で送る既定に戻る

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
   - `VBoxSVC` だけが出たら、数秒待って貼り直す
   - `winget list` の版の列の右に、新しい版の列（英語の表示では `Available`）が出たら、新しい版がある
   - 新しい版の列が無ければ、この節の手順 3・4 は飛ばす

1. 新しい版があるときだけ、winget で上げる。

   ```powershell
   winget upgrade --exact --id Oracle.VirtualBox --source winget --accept-source-agreements --accept-package-agreements
   ```

   - 途中でネットワークがいったん切れるはず
   - **次の手順は、winget が終わってプロンプトに戻ってから貼る**（続けて貼ると、winget が何か聞いたときの答えとして食われる）

1. 新しい版にしたときだけ、新しい版になったか確かめる。

   ```powershell
   & "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" --version
   winget list --exact --id Oracle.VirtualBox --source winget
   ```

   - 新しい版の番号が出て、`winget list` の新しい版の列が消えればよい
