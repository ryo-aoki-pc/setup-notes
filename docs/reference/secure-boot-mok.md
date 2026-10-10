# Secure Boot の MOK 登録手順（AlmaLinux 10 / 自分でビルドするカーネルモジュールの署名鍵）の参考資料

[手順書](../secure-boot-mok.md)・[ロールバックと注意点](../extra/secure-boot-mok.md)

## 補足

### 実施手順 / 手順 1: 補足: 2 つの役目と、入っていた環境

- `mokutil` は、Secure Boot が有効かを見る（手順 3）のと、MOK への登録の予約と確認（手順 4・7）に使う。`openssl` は鍵を作る（手順 4）
- [virtualbox.md](../verification/virtualbox.md#実施前の状態) の実機（GNOME の PC）と、[virtualbox-guest-bootc.md](../verification/virtualbox-guest-bootc.md#実施前の状態) の VM（Atomic Desktop のイメージ）には、どちらも入っていた
- 素のコンテナ（`quay.io/almalinuxorg/almalinux:10`）には、どちらも無かった

### 実施手順 / 手順 2: 補足: bootc のシステム

- bootc のシステムで dnf で入れられないのは、`/usr` が読み取り専用だから

### 実施手順 / 手順 3: 補足: Secure Boot が無効のとき

- Secure Boot が無効なら、署名していないモジュールも読み込まれるので、この文書の手順は要らない

### 実施手順 / 手順 4: 補足: 登録の予約

- 最後の `mokutil --import` で、公開鍵を UEFI の MOK に登録する予約をする（登録するのは、同じ節の手順 6 の MokManager）

### 実施手順 / 手順 7: 補足: 読み込めないときの見方

- `sudo keyctl list %:.platform` に、手順 4 の鍵の CN があるかを見る（`keyutils` パッケージ）
- `sudo dmesg` に `Loading of module with unavailable key is rejected` が出ていれば、モジュールを署名した鍵が登録されていない（手順 6 の補足）

### 選択した方針

- **鍵の場所は `/var/lib/shim-signed/mok/MOK.{der,priv}` に固定する**: VirtualBox の `vboxdrv.sh` と Guest Additions の `vboxadd` が、この場所を決め打ちで使う
- **鍵は 1 つにし、作り直さない**: 登録済みの鍵を作り直すと、その鍵で署名したモジュールと合わなくなる。手順 4 は、鍵があれば `中断:` で止まる
- **CN は用途を問わない名前にする**: 1 つの鍵で、この PC（VM）のモジュールのどれにも署名するため
- **登録は、モジュールをビルドする前に済ませる**: 鍵が登録済みなら、[virtualbox.md](../virtualbox.md) の `dnf install` の `%post` が、ビルド → 署名 → 読み込みまで一度に済ませる（[virtualbox.md の「VirtualBox を入れる」の手順 4](../virtualbox.md#virtualbox-を入れる) の補足）
- **独立した手順書にした**: VirtualBox のホストと、bootc のゲストの Guest Additions の 2 本で、同じ鍵の作り方・MokManager・確認の手順が重なっていたため

### 参照

- [RHEL 10 — Managing, monitoring, and updating the kernel](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html-single/managing_monitoring_and_updating_the_kernel/index) — Secure Boot でのモジュールの署名、MOK への鍵の登録、`.platform` キーリング
- `man mokutil`（`--sb-state` / `--import` / `--test-key` / `--list-new` / `--delete` / `--list-delete`）
- [VirtualBox](../virtualbox.md) / [VirtualBox Guest Additions（bootc のゲスト）](../virtualbox-guest-bootc.md) — この鍵で署名したモジュールを使う手順書

---
