# Secure Boot の MOK 登録手順（AlmaLinux 10 / 自分でビルドするカーネルモジュールの署名鍵）の参考資料

[AlmaLinux 10 の「Secure Boot の署名鍵」](../almalinux-setup.md#secure-boot-の署名鍵)・[ロールバックと注意点](../extra/secure-boot-mok.md)

集約前の節名・手順番号から現在の項への対応は [集約対応表](../dev/consolidation-map.md) を参照する。本文の実測・失敗・未確認範囲は当時の記録を保持する。

## 補足

### Secure Boot の署名鍵 / 手順 1: 補足: 2 つの役目と、入っていた環境

- `mokutil` は、Secure Boot が有効かを見る（手順 3）のと、MOK への登録の予約と確認（手順 4・7）に使う。`openssl` は鍵を作る（手順 4）
- [virtualbox.md](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/virtualbox.md#実施前の状態) の実機（GNOME の PC）と、[virtualbox-guest-bootc.md](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/virtualbox-guest-bootc.md#実施前の状態) の VM（Atomic Desktop のイメージ）には、どちらも入っていた
- 素のコンテナ（`quay.io/almalinuxorg/almalinux:10`）には、どちらも無かった

### Secure Boot の署名鍵 / 手順 2: 補足: bootc のシステム

- bootc のシステムで dnf で入れられないのは、`/usr` が読み取り専用だから

### Secure Boot の署名鍵 / 手順 3: 補足: Secure Boot が無効のとき

- Secure Boot が無効なら、署名していないモジュールも読み込まれるので、この文書の手順は要らない

### Secure Boot の署名鍵 / 手順 4: 補足: 登録の予約

- 最後の `mokutil --import` で、公開鍵を UEFI の MOK に登録する予約をする（登録するのは、同じ項の手順 6 の MokManager）

### Secure Boot の署名鍵 / 手順 5: 補足: VM のウィンドウを先に開いておく

- MokManager の最初の画面は、再起動の途中で出て、出てから 10 秒で消える（手順 6）。VM に SSH でつないで貼ったときは、消える前に、VM のウィンドウでキーを押すことになる
- Hyper-V の第 2 世代の VM では、手順 5 を貼ってから 3 秒足らずで最初の画面が出た（[検証記録の付録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/secure-boot-mok.md#付録-hyper-v-の-vm-で通した記録2026-10-11)）。手順 5 の `sudo systemctl reboot` から最初の画面までを、ほかのハイパーバイザと実機で測った記録は無い
  - VirtualBox の VM の記録にある時間は、別のコマンド（`bootc switch --apply`。イメージの切り替えの後に再起動する）を貼ってから 54 秒、の 1 つだけ（[virtualbox-guest-bootc.md の検証記録の付録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/virtualbox-guest-bootc.md#付録-ホストでビルドして-vm-に運ぶ形の本実行2026-09-30)）
- その VM では、画面を見張る道具がキーを送った。人が、貼った後にウィンドウを開いて間に合うかも、先に開いておけば間に合うかも、確かめていない

### Secure Boot の署名鍵 / 手順 7: 補足: 読み込めないときの見方

- `sudo keyctl list %:.platform` に、手順 4 の鍵の CN があるかを見る（`keyutils` パッケージ）
- `sudo dmesg` に `Loading of module with unavailable key is rejected` が出ていれば、モジュールを署名した鍵が登録されていない（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/secure-boot-mok.md#実施手順--手順-6-補足-画面の並びと登録できなかった-pc)の手順 6 の補足）

### 選択した方針

- **鍵の場所は `/var/lib/shim-signed/mok/MOK.{der,priv}` に固定する**: VirtualBox の `vboxdrv.sh` と Guest Additions の `vboxadd` が、この場所を決め打ちで使う
- **鍵は 1 つにし、作り直さない**: 登録済みの鍵を作り直すと、その鍵で署名したモジュールと合わなくなる。手順 4 は、鍵があれば `中断:` で止まる
- **CN は用途を問わない名前にする**: 1 つの鍵で、この PC（VM）のモジュールのどれにも署名するため
- **登録は、モジュールをビルドする前に済ませる**: 鍵が登録済みなら、[AlmaLinux 10 の「VirtualBox」](../virtual-machines.md#virtualbox) の `dnf install` の `%post` が、ビルド → 署名 → 読み込みまで一度に済ませる（[仮想マシンのセットアップの「VirtualBox: VirtualBox を入れる」の手順 4](../virtual-machines.md#virtualbox-virtualbox-を入れる) の補足）
- **集約前は独立した手順書にした**: VirtualBox のホストと、bootc のゲストの Guest Additions の 2 本で、同じ鍵の作り方・MokManager・確認の手順が重なっていたため

### 参照

- [RHEL 10 — Managing, monitoring, and updating the kernel](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html-single/managing_monitoring_and_updating_the_kernel/index) — Secure Boot でのモジュールの署名、MOK への鍵の登録、`.platform` キーリング
- `man mokutil`（`--sb-state` / `--import` / `--test-key` / `--list-new` / `--delete` / `--list-delete`）
- [VirtualBox](../virtual-machines.md#virtualbox) / [VirtualBox Guest Additions（bootc のゲスト）](../virtual-machines.md#virtualbox-の-bootc-ゲスト) — この鍵で署名したモジュールを使う手順書

---
