# Secure Boot の MOK 登録手順（AlmaLinux 10 / 自分でビルドするカーネルモジュールの署名鍵）のロールバックと注意点

[手順書](../secure-boot-mok.md)・[検証記録](../verification/secure-boot-mok.md)・[参考資料](../reference/secure-boot-mok.md)

- 「手順 N」は[手順書](../secure-boot-mok.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

> [!CAUTION]
> **この節の**手順 5 で、秘密鍵（`MOK.priv`）を消す。**消した鍵は取り戻せず**、その鍵で署名したモジュールは、作り直すまで Secure Boot で読み込まれない。

- 先に、この鍵で署名したモジュールを使う手順書のロールバックを行う（[VirtualBox](virtualbox.md#ロールバック)・[VirtualBox Guest Additions](virtualbox-guest-bootc.md#ロールバック)）
- この節の手順 3 は、起動の途中の MokManager の画面で行う

1. MOK から鍵を消す予約をする。

   ```bash
   sudo mokutil --delete /var/lib/shim-signed/mok/MOK.der
   ```

   - **一時パスワードを 2 回聞かれる**（この節の手順 3 で 1 回だけ使う）
   - 予約は `sudo mokutil --list-delete` で見られる
   - **次の手順は、一時パスワードに答えてから貼る**（続けて貼ると答えとして食われる）

1. 再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - 起動の途中で青い **MokManager** の画面が出る（この節の手順 3）

1. 起動の途中の MokManager で、鍵を消す。

   - 最初の画面で 10 秒以内にキーを押し、`Delete MOK` → `Continue` → `Yes` → この節の手順 1 の一時パスワード → `Reboot` と進む
   - **次の手順は、起動したらログインし、新しい端末を開いてから貼る**

1. 鍵が消えたか確かめる。

   ```bash
   sudo mokutil --test-key /var/lib/shim-signed/mok/MOK.der
   ```

   - `is not enrolled` が出ればよい（VM では、`.platform` のキーリングからも MOK の一覧からも消えた）
   - **次の手順は、`is not enrolled` が出たのを確かめてから貼る**

1. 鍵のファイルを消す（取り戻せない）。

   ```bash
   sudo rm -rf /var/lib/shim-signed
   ```

---

## 注意点

- **MokManager の最初の画面は 10 秒で消える**: 逃すと登録されず、予約も消える（手順 6）
- **鍵を作り直したら、署名したモジュールも作り直す**: bootc のゲストでは、ビルドに `--no-cache` を足す（[virtualbox-guest-bootc.md の更新](../virtualbox-guest-bootc.md#更新)）
