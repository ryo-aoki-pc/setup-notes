# Secure Boot の署名鍵の注意点

[手順書](../almalinux-setup.md#secure-boot-の署名鍵)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/secure-boot-mok.md)・[参考資料](../reference/secure-boot-mok.md)

- 「手順 N」は[手順書](../almalinux-setup.md#secure-boot-の署名鍵)の手順 N、「本書」「この文書」は手順書を指す

## 注意点

- **MokManager の最初の画面は 10 秒で消える**: 逃すと登録されず、予約も消える（手順 6）
- **鍵を作り直したら、署名したモジュールも作り直す**: bootc のゲストでは、ビルドに `--no-cache` を足す（[VirtualBox の bootc ゲスト: 更新](../virtual-machines.md#virtualbox-の-bootc-ゲスト-更新)）
