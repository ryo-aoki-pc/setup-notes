# Secure Boot の MOK 登録手順（AlmaLinux 10 / 自分でビルドするカーネルモジュールの署名鍵）

## 実施手順

- [検証記録](verification/secure-boot-mok.md)・[参考資料](reference/secure-boot-mok.md)・[ロールバックと注意点](extra/secure-boot-mok.md)

> [!IMPORTANT]
> - **Secure Boot が有効な PC（または VM）で、カーネルモジュールをビルドする手順書より先に通す**。手順 3 で Secure Boot が無効と分かったら、この文書はそこで終わり
> - **自分のシェルで実行する**（`sudo` できるユーザー）。bootc のシステム（AlmaLinux Atomic Desktop など）でも同じ手順になる
> - **手順 4 で一時パスワードを 2 回聞かれ、手順 5 で再起動する**。答えてから次の手順を貼る
> - **手順 6 は、起動の途中の MokManager の画面で行う**（最初の画面は 10 秒で消える。VM なら VM のウィンドウで操作する）

- 上から順にコードブロックを貼る
- 手順の後: 以後は[ロールバック](extra/secure-boot-mok.md#ロールバック)
- 通すと使えるようになるもの（この鍵で署名したモジュールが、Secure Boot のまま読み込まれる）:
  - [VirtualBox](virtualbox.md) のホストのモジュール（`vboxdrv` など）
  - [VirtualBox Guest Additions（bootc のゲスト）](virtualbox-guest-bootc.md) のモジュール（`vboxguest` など）

1. `mokutil` と `openssl` が入っているか確かめる。

   ```bash
   rpm -q mokutil openssl
   ```

   - 2 つとも版が出れば、手順 2 は飛ばす
   - `package mokutil is not installed` のように出たら、手順 2 で入れる

1. どちらかが未導入のときだけ、`mokutil` と `openssl` を入れる。

   ```bash
   sudo dnf install -y mokutil openssl
   ```

   - bootc のシステムでは dnf で入れられない（`/usr` が読み取り専用）が、Atomic Desktop のイメージには 2 つとも入っている

1. Secure Boot が有効かを見る。

   ```bash
   mokutil --sb-state
   ```

   - `SecureBoot enabled` なら、手順 4 から続ける
   - **`SecureBoot disabled`（または `EFI variables are not supported on this system`）なら、この文書の手順はここで終わり**（署名していないモジュールも読み込まれる）

1. 鍵がまだ無いときだけ、署名用の鍵を作り、MOK への登録を予約する。

   ```bash
   if sudo test -e /var/lib/shim-signed/mok/MOK.der; then echo '中断: 鍵が既にある。作り直さずに、手順 7 で登録を確かめる' >&2; else
     sudo mkdir -m 0700 -p /var/lib/shim-signed/mok
     sudo openssl req -nodes -new -x509 -newkey rsa:2048 -outform DER -addext "extendedKeyUsage=codeSigning" -subj "/CN=Local kernel module signing key/" -days 36500 -keyout /var/lib/shim-signed/mok/MOK.priv -out /var/lib/shim-signed/mok/MOK.der
     sudo ls -l /var/lib/shim-signed/mok
     sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
   fi
   ```

   - 鍵を作る間は `.....+++` のような行が流れる
   - `MOK.priv`（秘密鍵。`-rw-------`）と `MOK.der`（公開鍵の証明書）ができる
   - **`MOK.priv` は登録した鍵で信頼するモジュールを作れる秘密鍵**。root 以外に読ませず、ほかのマシンに持ち出さない
   - **場所とファイル名は変えない**（VirtualBox の `vboxdrv.sh` と、Guest Additions の起動スクリプト `vboxadd` が、この 2 つを決め打ちで使う）
   - 最後の `mokutil --import` で、公開鍵を UEFI の MOK に登録する予約をする
   - **一時パスワードを 2 回聞かれる**（手順 6 の MokManager で 1 回だけ使う。本書には残さない）
   - `中断: 鍵が既にある` と出たら、前に作った鍵がある。作り直すと、登録済みの鍵や、その鍵で署名したモジュールと合わなくなるので、手順 7 へ進む
   - VirtualBox Guest Additions の、ホストオンリーアダプターだけの VM では、この手順の代わりに [virtualbox-guest-bootc.md のその節](virtualbox-guest-bootc.md#ホストオンリーアダプターだけの-vm-でビルドする任意)の手順 3・4 で、鍵をホストで作り、証明書だけを VM に置いて予約する（手順 5 から先は同じ）
   - **次の手順は、一時パスワードに答えてから貼る**（続けて貼ると答えとして食われる）

1. 再起動する。

   ```bash
   sudo systemctl reboot
   ```

   - 起動の途中で青い **MokManager** の画面が出る（手順 6）

1. 起動の途中の MokManager で、鍵を登録する。

   - 最初の画面の `Press any key to perform MOK management` は、`Booting in 10 seconds` から数え下げて 10 秒で消える。消える前に何かキーを押す（VM なら、VM のウィンドウで押す）
   - 続けて `Enroll MOK` → `Continue` → `Yes` → 手順 4 の一時パスワード → `Reboot` と進む
   - **何もしないで進むと登録されない**。そのときは `sudo mokutil --import /var/lib/shim-signed/mok/MOK.der`（手順 4 の最後の行）を貼り直してから、手順 5 からやり直す
   - **注意**: MokManager でキーボードが効かない PC がある（参考資料を参照）
   - **次の手順は、起動したらログインし、新しい端末を開いてから貼る**

1. 鍵が登録されたか確かめる。

   ```bash
   sudo mokutil --test-key /var/lib/shim-signed/mok/MOK.der
   ```

   - `/var/lib/shim-signed/mok/MOK.der is already enrolled` が出れば、登録できている
   - 登録できていなければ `is not enrolled` になる。手順 6 の箇条書きのとおりやり直す
   - `sudo` が要る。鍵のディレクトリは root だけが入れる（`drwx------`）
