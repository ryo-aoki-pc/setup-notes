# VirtualBox インストール手順（AlmaLinux 10 は Oracle 公式 dnf リポジトリ / Windows 11 は winget）のロールバックと注意点

[手順書](../virtualbox.md)・[検証記録](../verification/virtualbox.md)・[参考資料](../reference/virtualbox.md)

- 「手順 N」は[手順書](../virtualbox.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)
- この節の手順では消えないもの:
  - **Oracle の署名鍵** `gpg-pubkey-2980aecf-5719f4e1`: 消すなら `sudo rpm -e gpg-pubkey-2980aecf-5719f4e1`
  - **Secure Boot の MOK**（前提の [secure-boot-mok.md](../secure-boot-mok.md) で登録した場合）: ほかにその鍵で署名したモジュールを使っていなければ、[secure-boot-mok.md のロールバック](secure-boot-mok.md#ロールバック)で消す
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

## Windows 11 のロールバック

- 上から順に、[Windows 11 で使う](../virtualbox.md#windows-11-で使う)の手順 1 と同じ管理者の Windows PowerShell（5.1）に貼る
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
   - 再起動の後も `VBoxNetAdp` が `Stopped` で残ることがある（ドライバーのファイルと登録が残る）。動いていないので、そのままでよい
   - VirtualBox の VM の中で試したときは、その VM の Guest Additions のドライバー（`VBoxGuest`・`VBoxMouse`・`VBoxSF`・`VBoxWddm`）も出る。これは消さない

1. VM とその設定も消すときだけ、`%USERPROFILE%\VirtualBox VMs` と `%USERPROFILE%\.VirtualBox` を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\VirtualBox VMs", "$env:USERPROFILE\.VirtualBox" -Recurse -Force -ErrorAction SilentlyContinue
   Test-Path -LiteralPath "$env:USERPROFILE\VirtualBox VMs", "$env:USERPROFILE\.VirtualBox"
   ```

   - `False` が 2 行出ればよい
   - VM の置き場所を既定から変えていたら（VirtualBox マネージャーの環境設定）、そのフォルダーは別に消す

---

## 注意点

- **EPEL が要る**: 依存の `liblzf` が EPEL にしか無い（[検証記録](../verification/virtualbox.md)・[参考資料](../reference/virtualbox.md)）。前提の [AlmaLinux 10 の初期設定の手順 17](../almalinux-setup.md#実施手順) で有効にする
- **`Complete!` でもモジュールができていないことがある**: `%post` は失敗を無視する。`systemctl is-active vboxdrv` と `/var/log/vbox-setup.log` で確かめる（[手順 9・10](../virtualbox.md#実施手順)）
- **sudo を付けない dnf にも鍵の確認が要る**: `repo_gpgcheck=1` のため。確認を通すまで、`sudo` 無しの dnf はどのパッケージでも失敗する（[検証記録](../verification/virtualbox.md)・[参考資料](../reference/virtualbox.md)）
- **Secure Boot では `mokutil` と、登録した鍵が要る**: vboxdrv.sh は `mokutil --sb-state` の出力だけで判定する。鍵の場所は `/var/lib/shim-signed/mok/` 固定で、前提の [secure-boot-mok.md](../secure-boot-mok.md) で作って登録する
- **MokManager でキーボードが効かなければ、[secure-boot-mok.md](../secure-boot-mok.md) の手順 6 に従って対処する**。Secure Boot を無効にするとモジュールは署名されない。後で有効に戻すなら、鍵を登録して `sudo /sbin/vboxconfig` を実行する
- **EL10 のカーネルでは KVM と同居できない**: `enable_virt_at_load=0` が要り、それでも KVM の VM と VirtualBox の VM は同時に動かない（[手順 11](../virtualbox.md#実施手順)）
- **カーネルを更新した後の最初の起動は遅くなる**: `vboxdrv.service` がモジュールをビルドし直す（[カーネルを更新したとき](../virtualbox.md#カーネルを更新したとき)）
- **系列がパッケージ名に入っている**: 7.2 → 7.3 は `dnf upgrade` では移らない（[更新](../virtualbox.md#更新)）
- **vboxusers は USB のためだけ**: VM の起動には要らない（[手順 12](../virtualbox.md#実施手順)）
- **Extension Pack は本書では扱わない**: 追加機能（マニュアルによれば VRDP のサーバー、ホストの Web カメラの受け渡し、Intel の PXE ブート ROM、ディスクイメージの暗号化、クラウド連携）をまとめた別配布
  - ライセンスは GPL ではなく **PUEL（個人利用と教育利用に限って無償）**
  - rpm の `%postun` が `/usr/lib/virtualbox/ExtensionPacks` を消すので、入れた場合は **VirtualBox の更新のたびに入れ直す**ことになる（rpm のスクリプトからの推定）
- **Guest Additions はゲスト側の話で対象外**: ISO は rpm に同梱されている（`/usr/share/virtualbox/VBoxGuestAdditions.iso`）。ゲストが AlmaLinux の bootc（Atomic Desktop）なら [virtualbox-guest-bootc.md](../virtualbox-guest-bootc.md)
- **公式の repo ファイルは `http://`**: 本書の repo ファイルは `https://` にしてある。署名の検証はどちらでも行われる
- **Windows 11 の注意点**
  - **Hyper-V が動いている PC では、VM が Hyper-V の上で動き、遅くなる**（WSL 2 を使う PC など）
    - VirtualBox のマニュアル（11.30）は、Hyper-V が動いていると Hyper-V を仮想化の土台に使い、大きく遅くなることがあると書いている
    - マニュアルのトラブルシューティング（13.7.6.7）は、Hyper-V Platform・Virtual Machine Platform・Windows Hypervisor Platform を切って再起動するよう勧めている（本書は切らない。[選択した方針](../reference/virtualbox.md#選択した方針)）
    - 止まっている間に VM の中の systemd の watchdog が `systemd-logind` などを止め、GNOME がログイン画面に戻った回もあった
    - VM が Hyper-V の上かは、VM のログ（[Windows 11 で使う](../virtualbox.md#windows-11-で使う)の手順 6）か、VM のウィンドウの状態バー（プロセッサーのアイコンに緑の亀）で分かる
  - **入れる・上げる・消すときに、ネットワークがいったん切れる**: ブリッジ接続のドライバーを入れるため（MSI の画面の警告。上げる・消すときも切れるはず）。SSH やリモート デスクトップでつないでいる PC では行わない
  - **VirtualBox は管理者ではない窓で動かす**: 管理者の窓から起動すると、VM も管理者の権限で動く（[Windows 11 で使う](../virtualbox.md#windows-11-で使う)の[検証記録](../verification/virtualbox.md)・[参考資料](../reference/virtualbox.md)）
  - **`VBoxManage` は `PATH` に入らない**: `C:\Program Files\Oracle\VirtualBox\VBoxManage.exe` を場所ごと呼ぶ（インストーラが足す環境変数は `VBOX_MSI_INSTALL_PATH` だけ）
  - **Secure Boot の MOK は要らない**: ドライバーは Microsoft の署名付きで配られる。[secure-boot-mok.md](../secure-boot-mok.md) は Linux だけのもの
  - **ロールバックで残るもの**: 依存で入った Visual C++ の再頒布可能パッケージと、インストーラが「信頼された発行元」に入れた Oracle の証明書（[Windows 11 のロールバック](#windows-11-のロールバック)）
  - **Android の Windows App からリモート デスクトップでつなぐと、VM に打った文字が別のキーになる**: Windows App の既定の Unicode の入力を、VirtualBox はキーとして読み違える。[Windows 11 の VirtualBox を Android からリモート デスクトップで使う](../virtualbox.md#windows-11-の-virtualbox-を-android-からリモート-デスクトップで使う任意)で、スキャンコードで送る設定にする
