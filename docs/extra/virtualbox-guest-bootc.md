# VirtualBox の bootc ゲストの注意点

[手順書](../virtual-machines.md#virtualbox-の-bootc-ゲスト)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/virtualbox-guest-bootc.md)・[参考資料](../reference/virtualbox-guest-bootc.md)

- 「手順 N」は[手順書](../virtual-machines.md#virtualbox-の-bootc-ゲスト)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **dnf でも `.run` でも入らない**: bootc の `/usr`・`/opt` は読み取り専用。派生イメージに焼き込む（[手順 3〜7](../virtual-machines.md#virtualbox-の-bootc-ゲスト)）
- **公式の ISO で入れた VM は `:latest` を追う**: `BASE_IMAGE` の既定は `:latest`。別のタグを追う VM では、手順 2 の `Booted image:` に合わせて手順 1 を直す（[手順 1](../virtual-machines.md#virtualbox-の-bootc-ゲスト) の補足）
- **Guest Additions のインストーラは、bootc 向けに 4 か所を直して使う**: unit・`/var` の設定・ユーザーとグループ・カーネルの版（[手順 3](../virtual-machines.md#virtualbox-の-bootc-ゲスト) の補足）
  - ただし起動のたびに、`vboxguest` を読み込んだ直後にカーネルの `WARNING` が 1 回出る。Guest Additions の働きには影響が見えなかった（[手順 8](../virtual-machines.md#virtualbox-の-bootc-ゲスト) の補足）
- **既定のカーネルでも、`vboxguest` の読み込みで同じ警告が出て、まれに起動が止まる**
  - `vboxguest` を読み込んだ直後にカーネルの `WARNING` が出ることがある。手順 7・8 の起動状態とログを確認する
  - VM をリセットすると、次の起動は通った（[手順 7](../virtual-machines.md#virtualbox-の-bootc-ゲスト) の箇条書き、[手順 8](../virtual-machines.md#virtualbox-の-bootc-ゲスト) の補足）
- **Windows のホストでも、同じ手順で入る**: Guest Additions の CD は、VirtualBox のインストール先の ISO（[手順 5](../virtual-machines.md#virtualbox-の-bootc-ゲスト) の補足）。メニューの名前も本文と同じ
- **Hyper-V が動いている Windows のホストでは、手順 6 の途中で VM が 1〜7 分ずつ止まる**
  - VirtualBox が Hyper-V の上で VM を動かす形（NEM。VBox.log に `HM: HMR3Init: Attempting fall back to NEM`）で起きた。止まっている間は、VM の中の時計も仮想の時計も進まない
  - VM のウィンドウでキーを押す、VM に SSH でつなぐなど、外から働きかけると動き出した（Shift キーでは 2 回とも 5 秒以内）
  - 止まった後に、systemd の watchdog（3 分）が `systemd-logind`・`systemd-udevd`・`systemd-journald` などを強制終了した。GNOME がログイン画面に戻った回もあった
  - 動いている VM に CD を入れる操作とは関係が無かった（電源から入れ直した VM でも止まった）。止まらない回もあった
  - ビルド中はホストから VM への SSH 接続を維持する
- **ホストオンリーアダプターだけの VM では、ホストでビルドして運ぶ**: ホストの rootless の podman でビルドし、`podman save -m` のファイルを ssh で VM に送って `podman load` する（[ホストオンリーアダプターだけの VM でビルドする](../virtual-machines.md#virtualbox-の-bootc-ゲスト-ホストオンリーアダプターだけの-vm-でビルドする)）
  - ベースの署名は、VM の `policy.json` と公開鍵をホストの `~/.config/containers` に写して確かめる。写さないと、AlmaLinux 10 の既定の設定では確かめずに取り込む（その項の手順 7 の補足）
  - OS を上げるときは、ホストから運ぶ。`podman save` はファイルがすでにあると書かないので、消してから書く（その項の手順 9 の補足）
- **インストールに使った ISO が残っていると、Guest Additions の CD を入れられない**: VM の中で `eject /dev/sr0` してから入れる（[手順 4](../virtual-machines.md#virtualbox-の-bootc-ゲスト)）
- **イメージに `libXt` を入れる**: 無いと GNOME のセッションで `VBoxClient --clipboard` が 5 秒ごとに落ち、クリップボードの共有が動かない（[手順 3](../virtual-machines.md#virtualbox-の-bootc-ゲスト) の補足）
- **切り替えた後は、OS の更新もビルドし直しになる**: `bootc upgrade` はこの VM の中のイメージしか見ない（[更新](../virtual-machines.md#virtualbox-の-bootc-ゲスト-更新)）
- **カーネルが変わったら、VM の上ではモジュールを作り直せない**: ビルドの道具をイメージから消しているため。イメージごとビルドし直す
- **Secure Boot では鍵の登録が要る**: 前提の [Secure Boot の署名鍵](../almalinux-setup.md#secure-boot-の署名鍵) で登録する（MokManager の最初の画面は 10 秒で消え、逃すと登録されない）。鍵を作り直したら `--no-cache` でビルドし直す（[更新](../virtual-machines.md#virtualbox-の-bootc-ゲスト-更新)）
- **CD を入れても、GNOME は何も表示しない**: 自動実行の確認も、デスクトップのアイコンも出ない。10 秒ほど待ってから手順 5 を貼る（[手順 4](../virtual-machines.md#virtualbox-の-bootc-ゲスト)）
- **ホスト側の手順書は別**: VirtualBox 本体は [VirtualBox](../virtual-machines.md#virtualbox)。ホスト側でモジュールを署名する鍵（同じ `/var/lib/shim-signed/mok/` の置き場所。どちらも [Secure Boot の署名鍵](../almalinux-setup.md#secure-boot-の署名鍵) で作る）は、ホストの PC のもので、VM の鍵とは別物
