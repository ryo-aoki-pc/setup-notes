# VirtualBox の注意点

手順: [AlmaLinux 10](../virtual-machines.md#virtualbox)・[Windows 11](../virtual-machines.md#windows-11-で-virtualbox-を入れる)。[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/virtualbox.md)・[参考資料](../reference/virtualbox.md)

- 手順書の実施手順は項（###）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **Windows 11 で作った VM を戻す・消すとき**: スナップショットへの復元は[スナップショットとクローン](../virtual-machines.md#virtualbox-スナップショットとクローン)、VM とディスクの削除は[VM を消す](../virtual-machines.md#virtualbox-vm-を消す)で行う。削除は停止した VM だけで行う。途中まで作って失敗した VM も同じ手順で消せる
- **NAT の SSH 転送はクローンにもコピーされる**。本書は完全クローンを作った後にポートを変える。同じポートのまま両方を起動しない
- **完全クローンにはゲストの識別情報もコピーされることがある**。MAC アドレスを再生成しただけで済ませず、別の PC として使う前にホスト名や SSH のホスト鍵をゲスト側で確かめて変更する
- **スナップショットはバックアップの代わりにならない**。元の VM のディスクと一緒に失われる。必要なデータは別の場所に退避する
- **ホストオンリー・ブリッジ・Extension Pack・USB の受け渡しは、VM を作って使う節の対象外**。この節の検証では確かめていない

- **EPEL が要る**: 依存の `liblzf` が EPEL にしか無い（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/virtualbox.md)・[参考資料](../reference/virtualbox.md)）。前提の [AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」の手順 1](../almalinux-setup.md#epel-と-rpm-fusion) で有効にする
- **`Complete!` でもモジュールができていないことがある**: `%post` は失敗を無視する。`systemctl is-active vboxdrv` と `/var/log/vbox-setup.log` で確かめる（[VirtualBox を入れる](../virtual-machines.md#virtualbox-virtualbox-を入れる)の手順 4・5）
- **sudo を付けない dnf にも鍵の確認が要る**: `repo_gpgcheck=1` のため。確認を通すまで、`sudo` 無しの dnf はどのパッケージでも失敗する（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/virtualbox.md)・[参考資料](../reference/virtualbox.md)）
- **Secure Boot では `mokutil` と、登録した鍵が要る**: vboxdrv.sh は `mokutil --sb-state` の出力だけで判定する。鍵の場所は `/var/lib/shim-signed/mok/` 固定で、前提の [Secure Boot の署名鍵](../almalinux-setup.md#secure-boot-の署名鍵) で作って登録する
- **MokManager でキーボードが効かなければ、[Secure Boot の署名鍵](../almalinux-setup.md#secure-boot-の署名鍵) の手順 6 に従って対処する**。Secure Boot を無効にするとモジュールは署名されない。後で有効に戻すなら、鍵を登録して `sudo /sbin/vboxconfig` を実行する
- **EL10 のカーネルでは KVM と同居できない**: `enable_virt_at_load=0` が要り、それでも KVM の VM と VirtualBox の VM は同時に動かない（[KVM と USB の設定](../virtual-machines.md#virtualbox-kvm-と-usb-の設定)の手順 1）
- **カーネルを更新した後の最初の起動は遅くなる**: `vboxdrv.service` がモジュールをビルドし直す（[カーネルを更新したとき](../virtual-machines.md#virtualbox-カーネルを更新したとき)）
- **系列がパッケージ名に入っている**: 7.2 → 7.3 は `dnf upgrade` では移らない（[更新](../virtual-machines.md#virtualbox-更新)）
- **vboxusers は USB のためだけ**: VM の起動には要らない（[KVM と USB の設定](../virtual-machines.md#virtualbox-kvm-と-usb-の設定)の手順 2）
- **Extension Pack は本書では扱わない**: 追加機能（マニュアルによれば VRDP のサーバー、ホストの Web カメラの受け渡し、Intel の PXE ブート ROM、ディスクイメージの暗号化、クラウド連携）をまとめた別配布
  - ライセンスは GPL ではなく **PUEL（個人利用と教育利用に限って無償）**
  - rpm の `%postun` が `/usr/lib/virtualbox/ExtensionPacks` を消すので、入れた場合は **VirtualBox の更新のたびに入れ直す**ことになる（rpm のスクリプトからの推定）
- **Guest Additions はゲスト側の話で対象外**: ISO は rpm に同梱されている（`/usr/share/virtualbox/VBoxGuestAdditions.iso`）。ゲストが AlmaLinux の bootc（Atomic Desktop）なら [VirtualBox の bootc ゲスト](../virtual-machines.md#virtualbox-の-bootc-ゲスト)
- **公式の repo ファイルは `http://`**: 本書の repo ファイルは `https://` にしてある。署名の検証はどちらでも行われる
- **Windows 11 の注意点**
  - **Hyper-V が動いている PC では、VM が Hyper-V の上で動き、遅くなる**（WSL 2 を使う PC など）
    - VirtualBox のマニュアル（11.30）は、Hyper-V が動いていると Hyper-V を仮想化の土台に使い、大きく遅くなることがあると書いている
    - マニュアルのトラブルシューティング（13.7.6.7）は、Hyper-V Platform・Virtual Machine Platform・Windows Hypervisor Platform を切って再起動するよう勧めている（本書は切らない。[選択した方針](../reference/virtualbox.md#選択した方針)）
    - 止まっている間に VM の中の systemd の watchdog が `systemd-logind` などを止め、GNOME がログイン画面に戻った回もあった
    - VM が Hyper-V の上かは、VM のログ（[Windows 11 で使う](../virtual-machines.md#windows-11-で-virtualbox-を入れる)の手順 6）か、VM のウィンドウの状態バー（プロセッサーのアイコンに緑の亀）で分かる
  - **入れる・上げる・消すときに、ネットワークがいったん切れる**: ブリッジ接続のドライバーを入れるため（MSI の画面の警告。上げる・消すときも切れるはず）。SSH やリモート デスクトップでつないでいる PC では行わない
  - **VirtualBox は管理者ではない窓で動かす**: 管理者の窓から起動すると、VM も管理者の権限で動く（[Windows 11 で使う](../virtual-machines.md#windows-11-で-virtualbox-を入れる)の[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/virtualbox.md)・[参考資料](../reference/virtualbox.md)）
  - **`VBoxManage` は `PATH` に入らない**: `C:\Program Files\Oracle\VirtualBox\VBoxManage.exe` を場所ごと呼ぶ（インストーラが足す環境変数は `VBOX_MSI_INSTALL_PATH` だけ）
  - **Secure Boot の MOK は要らない**: ドライバーは Microsoft の署名付きで配られる。[Secure Boot の署名鍵](../almalinux-setup.md#secure-boot-の署名鍵) は Linux だけのもの
  - **Android の Windows App からリモート デスクトップでつなぐと、VM に打った文字が別のキーになる**: Windows App の既定の Unicode の入力を、VirtualBox はキーとして読み違える。[Windows 11 の VirtualBox を Android からリモート デスクトップで使う](../virtual-machines.md#virtualbox-windows-11-の-virtualbox-を-android-からリモート-デスクトップで使う)で、スキャンコードで送る設定にする
