# VirtualBox Guest Additions 導入手順（AlmaLinux 10 bootc / Atomic Desktop のゲスト）のロールバックと注意点

[手順書](../virtualbox-guest-bootc.md)・[検証記録](../verification/virtualbox-guest-bootc.md)・[参考資料](../reference/virtualbox-guest-bootc.md)

- 「手順 N」は[手順書](../virtualbox-guest-bootc.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- ホストオンリーアダプターだけの VM では、この節の手順 1 の代わりに、[ホストオンリーアダプターだけの VM でビルドする（任意）](../virtualbox-guest-bootc.md#ホストオンリーアダプターだけの-vm-でビルドする任意)の手順 10 を行う（VM はレジストリから元のイメージを取り込めないので、ホストから運んだものに切り替える）。ホストは、その節の手順 11 で片付ける
- `sudo bootc rollback` の後に再起動すると、1 つ前のデプロイメントに戻る
  - 更新を重ねた後は、1 つ前の派生イメージに戻る
  - 切り替えた直後なら元のイメージに戻る。もう一度 `sudo bootc rollback` すると派生イメージに戻る
- この節の手順では消えないもの:
  - **Secure Boot の MOK**（前提の [secure-boot-mok.md](../secure-boot-mok.md)、またはホストオンリーアダプターだけの節の手順 3・4 で登録した場合）: 要らなければ、この節の後に [secure-boot-mok.md のロールバック](secure-boot-mok.md#ロールバック)で消す
    - ホストオンリーアダプターだけの節で鍵をホストで作ったときは、VM の MOK を消した後に、ホストの端末で `rm -rf ~/vbox-ga-mok`（秘密鍵。取り戻せない。同じ鍵を使うほかの VM が無いときだけ）

1. 元のイメージに切り替えて、再起動する。

   ```bash
   sudo bootc switch --apply "${BASE_IMAGE:?手順 1 の BASE_IMAGE が空のまま。値を入れて貼り直す}"
   ```

   - 元のイメージをレジストリから取り込み、署名を確かめてから再起動する
     - 自作の kernel-rt のイメージなど、`policy.json` に載っていないレジストリのイメージは、署名を確かめない（手順 6 と同じ）
   - **次の手順は、起動したらログインし、新しい端末で手順 1 を貼ってから貼る**

1. ビルド用のディレクトリと、podman に取り込んだイメージを消す。

   ```bash
   rm -rf ~/vbox-ga-image
   printf '\n\033[7m 確認 \033[0m\n'
   sudo podman rmi localhost/vbox-ga:latest "${BASE_IMAGE:?手順 1 の BASE_IMAGE が空のまま。値を入れて貼り直す}"
   ```

   - `Untagged:` と `Deleted:` の行が並ぶ
   - bootc は自分の置き場所にイメージを持っているので、podman のイメージを消しても起動には影響しない
   - ビルドの最初の段（`<none>`、6.43 MB）が残る。`sudo podman image prune` で消せる
     - [更新](../virtualbox-guest-bootc.md#更新)でビルドし直していれば、前の派生イメージ（5.07 GB。kernel-rt のイメージでは 5.51 GB）も `<none>` で残る。同じく `sudo podman image prune` で消える
     - ホストオンリーアダプターだけの節でホストでビルドした VM では、`Deleted:` は 2 行で、`<none>` は VM にできない（ホストに残る。その節の手順 11）
   - **次の手順は、`Deleted:` の行が出てから貼る**（消し終わる前に貼ると、`sudo` が読んで捨てる）

1. Guest Additions のユーザー・グループ・リンク・ログを消す。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo userdel vboxadd
     sudo groupdel vboxsf
     sudo groupdel vboxdrmipc
     sudo rm -f /var/lib/VBoxGuestAdditions /var/log/vboxadd-setup.log*
   }
   ```

   - 何も出ずに終われば消えている

---

## 注意点

- **dnf でも `.run` でも入らない**: bootc の `/usr`・`/opt` は読み取り専用。派生イメージに焼き込む（[手順 3〜7](../virtualbox-guest-bootc.md#実施手順)）
- **公式の ISO で入れた VM は `:latest` を追う**: `BASE_IMAGE` の既定は `:latest`。別のタグを追う VM では、手順 2 の `Booted image:` に合わせて手順 1 を直す（[手順 1](../virtualbox-guest-bootc.md#実施手順) の補足）
- **Guest Additions のインストーラは、bootc 向けに 4 か所を直して使う**: unit・`/var` の設定・ユーザーとグループ・カーネルの版（[手順 3](../virtualbox-guest-bootc.md#実施手順) の補足）
  - ただし起動のたびに、`vboxguest` を読み込んだ直後にカーネルの `WARNING` が 1 回出る。Guest Additions の働きには影響が見えなかった（[手順 8](../virtualbox-guest-bootc.md#実施手順) の補足）
- **既定のカーネルでも、`vboxguest` の読み込みで同じ警告が出て、まれに起動が止まる**
  - `vboxguest` を読み込んだ直後にカーネルの `WARNING` が出ることがある。手順 7・8 の起動状態とログを確認する
  - VM をリセットすると、次の起動は通った（[手順 7](../virtualbox-guest-bootc.md#実施手順) の箇条書き、[手順 8](../virtualbox-guest-bootc.md#実施手順) の補足）
- **Windows のホストでも、同じ手順で入る**: Guest Additions の CD は、VirtualBox のインストール先の ISO（[手順 5](../virtualbox-guest-bootc.md#実施手順) の補足）。メニューの名前も本文と同じ
- **Hyper-V が動いている Windows のホストでは、手順 6 の途中で VM が 1〜7 分ずつ止まる**
  - VirtualBox が Hyper-V の上で VM を動かす形（NEM。VBox.log に `HM: HMR3Init: Attempting fall back to NEM`）で起きた。止まっている間は、VM の中の時計も仮想の時計も進まない
  - VM のウィンドウでキーを押す、VM に SSH でつなぐなど、外から働きかけると動き出した（Shift キーでは 2 回とも 5 秒以内）
  - 止まった後に、systemd の watchdog（3 分）が `systemd-logind`・`systemd-udevd`・`systemd-journald` などを強制終了した。GNOME がログイン画面に戻った回もあった
  - 動いている VM に CD を入れる操作とは関係が無かった（電源から入れ直した VM でも止まった）。止まらない回もあった
  - ビルド中はホストから VM への SSH 接続を維持する
- **ホストオンリーアダプターだけの VM では、ホストでビルドして運ぶ**: ホストの rootless の podman でビルドし、`podman save -m` のファイルを ssh で VM に送って `podman load` する（[ホストオンリーアダプターだけの VM でビルドする（任意）](../virtualbox-guest-bootc.md#ホストオンリーアダプターだけの-vm-でビルドする任意)）
  - ベースの署名は、VM の `policy.json` と公開鍵をホストの `~/.config/containers` に写して確かめる。写さないと、AlmaLinux 10 の既定の設定では確かめずに取り込む（その節の手順 6 の補足）
  - OS を上げるときも、元のイメージに戻すときも、ホストから運ぶ。`podman save` はファイルがすでにあると書かないので、消してから書く（その節の手順 8 の補足）
- **インストールに使った ISO が残っていると、Guest Additions の CD を入れられない**: VM の中で `eject /dev/sr0` してから入れる（[手順 4](../virtualbox-guest-bootc.md#実施手順)）
- **イメージに `libXt` を入れる**: 無いと GNOME のセッションで `VBoxClient --clipboard` が 5 秒ごとに落ち、クリップボードの共有が動かない（[手順 3](../virtualbox-guest-bootc.md#実施手順) の補足）
- **切り替えた後は、OS の更新もビルドし直しになる**: `bootc upgrade` はこの VM の中のイメージしか見ない（[更新](../virtualbox-guest-bootc.md#更新)）
- **カーネルが変わったら、VM の上ではモジュールを作り直せない**: ビルドの道具をイメージから消しているため。イメージごとビルドし直す
- **Secure Boot では鍵の登録が要る**: 前提の [secure-boot-mok.md](../secure-boot-mok.md) で登録する（MokManager の最初の画面は 10 秒で消え、逃すと登録されない）。鍵を作り直したら `--no-cache` でビルドし直す（[更新](../virtualbox-guest-bootc.md#更新)）
- **CD を入れても、GNOME は何も表示しない**: 自動実行の確認も、デスクトップのアイコンも出ない。10 秒ほど待ってから手順 5 を貼る（[手順 4](../virtualbox-guest-bootc.md#実施手順)）
- **元のイメージに戻すときは、`--enforce-container-sigpolicy` を付けない**: Atomic Desktop の `policy.json` の既定では断られる。付けなくても署名は確かめられる（[ロールバック](#ロールバック)の手順 1 の補足）
- **アンインストーラは使えない**: 戻すときはイメージを切り替える（[ロールバック](#ロールバック)）
- **ホスト側の手順書は別**: VirtualBox 本体は [virtualbox.md](../virtualbox.md)。ホスト側でモジュールを署名する鍵（同じ `/var/lib/shim-signed/mok/` の置き場所。どちらも [secure-boot-mok.md](../secure-boot-mok.md) で作る）は、ホストの PC のもので、VM の鍵とは別物
