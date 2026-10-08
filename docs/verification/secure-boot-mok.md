# Secure Boot の MOK 登録手順（AlmaLinux 10 / 自分でビルドするカーネルモジュールの署名鍵）の検証記録

[手順書](../secure-boot-mok.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **実機では、手順 6（MokManager での登録）を通せていない**（[対象と検証環境](#対象と検証環境)）。
>
> - 検証した PC（x86_64 のノート PC）では、MokManager でキーボードが効かず、鍵を登録できなかった
> - 登録と削除は、VirtualBox の VM の中の AlmaLinux（bootc）で確かめた

### 実施手順 / 手順 4: 補足: 鍵の作り方と、登録した鍵の行き先

**鍵の作り方は、VirtualBox のスクリプトが出す案内に `-subj` と `-days` を足しただけ。** `vboxdrv.sh` は、Secure Boot で鍵が無いと次の案内を出す（[virtualbox.md 手順 9](../virtualbox.md#実施手順) の補足の実測）:

```
    sudo mkdir -m 0700 -p /var/lib/shim-signed/mok
    sudo openssl req -nodes -new -x509 -newkey rsa:2048 -outform DER -addext "extendedKeyUsage=codeSigning" -keyout /var/lib/shim-signed/mok/MOK.priv -out /var/lib/shim-signed/mok/MOK.der
    sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
    sudo reboot
```

- 案内のままだと `Country Name (2 letter code) [XX]:` から始まる対話になり、有効期限も既定の 30 日になる（どちらも実測。OpenSSL 3.5.8）
- カーネルが署名の確認で証明書の期限を見るかは確かめていないので、100 年にしてある

**CN（`Local kernel module signing key`）は名札で、`modinfo -F signer` に出る。**

- 1 つの鍵で、この PC（VM）でビルドするモジュールのどれにも署名する。カーネルが確かめるのは鍵そのもので、名前ではない
- この文書を独立させる前（2026-09-30 より前）は、[virtualbox.md](../virtualbox.md) が `VirtualBox module signing key`、[virtualbox-guest-bootc.md](../virtualbox-guest-bootc.md) が `VirtualBox Guest Additions module signing key` で作っていた。その名前で作った鍵も、そのまま使える（手順 4 は既にある鍵を作り直さない）

**登録した鍵は `.platform` キーリングに入る。**

- EL10 のカーネルは `CONFIG_INTEGRITY_CA_MACHINE_KEYRING=y`・`CONFIG_INTEGRITY_CA_MACHINE_KEYRING_MAX=y`
- kernel-devel に入っている Kconfig の説明によれば、MOK の鍵のうち CA の条件（CA ビットと `keyCertSign`）を満たすものだけが `.machine` に入り、残りは `.platform` に入る
- この証明書は `CA:TRUE` と `Code Signing` を持つが、`keyUsage` を持たない（`openssl x509 -text` で確認）ので、`.platform` 側になる
- RHEL 10 のドキュメント（[参照](../reference/secure-boot-mok.md#参照)）は「モジュールを読み込むとき、カーネルは `.builtin_trusted_keys` と `.platform` の鍵で署名を確かめる。`.platform` には独自の公開鍵も入る」と書いており、登録後の確認に `keyctl list %:.platform`（`keyutils` パッケージ）を使っている
- VirtualBox の VM の中の AlmaLinux（同じ EL10 のカーネル）では、登録した鍵は `.platform` に入り、`.machine` には入らなかった

**予約できたかは `sudo mokutil --list-new` で見られる**（実機で、鍵の `CN=` が出た）。`sudo` を付けないと何も出ない。

**bootc のシステムでも、鍵は残る。** `/var` は再起動や `bootc switch` をまたいで残る（イメージから上書きされない）。

**`MOK.priv` は、この PC（VM）が信頼するモジュールを作れる鍵になる。** root 以外に読ませず、ほかのマシンに持ち出さない。消し方は[ロールバック](../secure-boot-mok.md#ロールバック)。

### 実施手順 / 手順 6: 補足: 画面の並びと、登録できなかった PC

**画面の並び**（VirtualBox の VM で確かめた）:

- 「Shim UEFI key management」の画面に `Press any key to perform MOK management` と `Booting in 10 seconds`
- キーを押すと「Perform MOK management」のメニュー（`Continue boot` / `Enroll MOK` / `Enroll key from disk` / `Enroll hash from disk`）
- `Enroll MOK` → 「[Enroll MOK]」（`View key 0` / `Continue`）→ `Continue` → 「Enroll the key(s)?」（`No` / `Yes`）→ `Yes` → `Password:` → メニューの先頭が `Reboot` になる

**見送ったとき**（VM でわざと何も押さなかった）: 最初の画面が数え下げて消え、そのまま起動した。鍵は登録されず、この鍵で署名したモジュールは読み込まれなかった（`sudo dmesg` に `Loading of module with unavailable key is rejected`）。手順 7 は `is not enrolled` になった。

**検証した PC では登録できなかった。**

- 検証した PC（ASUS の ROG Flow Z13 GZ302EA、BIOS 311）では、MokManager の画面は出たが、キーボードの操作が効かず、鍵を登録できなかった（利用者の報告）
  - つながっていたのは、着脱式の Asus Keyboard と、外付けの USB のキーボード（ZMK）
  - 起動した後は、予約（`sudo mokutil --list-new`）が消えていて、鍵も登録されていなかった
- 利用者は UEFI（BIOS）の設定で Secure Boot を無効にし、[virtualbox.md](../virtualbox.md) を無効の分岐で進めた
- 別のキーボードや、UEFI の設定（Fast Boot など）でキーが効くようになるかは、確かめていない

### ロールバック / 手順 0: 本文中の記録

- この節の手順は、VirtualBox の VM の中（bootc のゲスト）で本実行した。実機では行っていない

### ロールバック / 手順 3: 補足: 画面の並び

VM で確かめた並び: `Delete MOK` → 「[Delete MOK]」（`View key 0` / `Continue`）→ `Continue` → 「Delete the key(s)?」→ `Yes` → パスワード → `Reboot`。

### 対象と検証環境

- **目的**: Secure Boot が有効な AlmaLinux 10 の PC（または VM）で、自分でビルドするカーネルモジュール（VirtualBox のホストのモジュール、Guest Additions のモジュール）を読み込めるようにする。そのために、署名用の鍵を作って UEFI の MOK（Machine Owner Key）に登録する
- **進め方**: `openssl` で鍵を `/var/lib/shim-signed/mok/` に作り、`mokutil --import` で予約して、再起動の途中の MokManager で登録する。読者が編集する変数は無い
  - もとは [virtualbox.md](../virtualbox.md) と [virtualbox-guest-bootc.md](../virtualbox-guest-bootc.md) の中にあった同じ手順を、共有の前提として 1 本にした。鍵の CN は、どちらのモジュールにも使える `Local kernel module signing key` にそろえた
- **状態**: **手順 3〜7 のコマンドは、この文書に移す前に、次の検証で通したもの**（CN はそれぞれの手順書の名前だった）
  - 2026-10-06 の[クリーンインストール VM](almalinux-vm.md)では、`mokutil --sb-state` が `SecureBoot disabled` と `Platform is in Setup Mode` を返した。本文の条件に従って登録は行わず、今回の VM 試験に MOK 登録の結果は含めない
  - x86_64 の実機（[virtualbox.md の本実行](virtualbox.md#付録-実機での本実行2026-09-29)、2026-09-28。AMD のノート PC）
    - 手順 3 で `SecureBoot enabled`、手順 4 で鍵を作って予約し（`sudo mokutil --list-new` に鍵が出た）、手順 5 で再起動した
    - **手順 6 の MokManager でキーボードが効かず、登録できなかった**。手順 7 は `is not enrolled` になった。利用者が UEFI の設定で Secure Boot を無効にした
  - VirtualBox の VM の中の AlmaLinux Atomic Desktop（[virtualbox-guest-bootc.md の VM での本実行](virtualbox-guest-bootc.md#付録-virtualbox-の-vm-での本実行2026-09-29)、2026-09-29 と 2026-09-30。Secure Boot 有効）
    - 手順 3・4、MokManager での登録（手順 6）、手順 7、[ロールバック](../secure-boot-mok.md#ロールバック)（2026-09-29 の VM）
    - 登録のための再起動は、多くの回で `bootc switch --apply` の再起動を使った。**手順 5 の `sudo systemctl reboot` からの登録**は、MokManager をわざと見送った後のやり直しで通した
    - MokManager を見送ったときの失敗のしかた、`.platform` のキーリングに入ること
  - 2026-09-30 に、この文書のブロックを x86_64 のコンテナで通した（[付録](#付録-コンテナでの検証記録2026-09-30)）
    - 手順 1〜4（`mokutil` はスタブ）、手順 4 の 2 回目が `中断:` で止まること、新しい CN で証明書ができること、手順 7 とロールバックの手順 1・4・5（スタブ）
  - **確認していないこと**: 実機での MokManager の登録（キーボードが効かなかった）と、実機で署名したモジュールが受け入れられること。実機での[ロールバック](../secure-boot-mok.md#ロールバック)。aarch64

| 項目 | x86_64 の実機 | VirtualBox の VM | 検証コンテナ（2026-09-30） |
|---|---|---|---|
| 実施日 | 2026-09-28 | 2026-09-29・30 | 2026-09-30 |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64 | AlmaLinux Atomic Desktop（GNOME、bootc）10.2 / x86_64 | AlmaLinux 10.2 / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1） |
| Secure Boot | 有効（MokManager の後に無効にした） | 有効（VM の設定） | 無し（`EFI variables are not supported on this system`）。分岐は `mokutil` のスタブで確かめた |
| mokutil / openssl | 導入済み | イメージに入っている | 手順 2 で導入（`mokutil-0.7.2-4.el10.alma.1`・`openssl-3.5.8-1.el10_2.alma.1`） |

> [!NOTE]
> 出力例の値は `<USER>` のプレースホルダで書いてある。**MOK の秘密鍵と一時パスワードは載せない。**

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 注意点 / 手順 0: 本文中の記録

- **MokManager でキーボードが効かない PC がある**: 検証した PC では登録できなかった（手順 6 の補足）

### 注意点 / 手順 0: 本文中の記録

- **スナップショットに戻しても、VM の NVRAM の Secure Boot は戻らなかった**: VirtualBox の VM で試すときは、VM の設定の Secure Boot を見てから始める（[virtualbox-guest-bootc.md の付録](virtualbox-guest-bootc.md#付録-kernel-rt-のイメージの-vm-での本実行2026-09-29)）

### 付録: コンテナでの検証記録（2026-09-30）

**環境**: Ubuntu 24.04 / x86_64 のクラウドホスト上の Docker 29.3.1 で、`quay.io/almalinuxorg/almalinux:10`（`sha256:83220192…c4c8`、AlmaLinux 10.2）を非特権・`--network host` で立てた。実機で加えた変更は無い。

**手順書の外で行った準備**（検証環境の都合）:

- プロキシの CA を信頼ストアに足し、dnf にプロキシを設定した
- `sudo` を入れ、NOPASSWD の `sudo` を与えた非 root ユーザー（uid 1000）を作った
- 手順 2 の後に、`/usr/bin/mokutil` をスタブに差し替えた（本物はコンテナでは `EFI variables are not supported on this system`）

| スタブ | 返したもの |
|---|---|
| `mokutil --sb-state` | `SecureBoot enabled` |
| `mokutil --import` / `--delete` | 一時パスワードを 2 回読み、予約の印を置く |
| `mokutil --test-key` | 読めなければ `Failed to open`。登録済みの印と同じ鍵なら `is already enrolled`、違えば `is not enrolled`（MokManager での登録と削除は、印を置き換えて模した） |

**流し方**: この文書の bash のブロックをファイルから抜き出し、そのユーザーのログインシェル（`bash -l`）に 1 ブロックずつ流した。一時パスワードは標準入力から渡した。

| 手順 | 結果 |
|---|---|
| 1 | `package mokutil is not installed`・`package openssl is not installed` |
| 2 | `mokutil`・`openssl` と依存（`efivar-libs` など）が入った |
| 1（もう一度） | `mokutil-0.7.2-4.el10.alma.1.x86_64`・`openssl-3.5.8-1.el10_2.alma.1.x86_64` |
| 3 | 本物は `EFI variables are not supported on this system`（終了コード 1）。スタブで `SecureBoot enabled` |
| 4 | 鍵が無い状態から、`MOK.der`（848 バイト）と `MOK.priv`（1704 バイト、`-rw-------`）ができ、ディレクトリは `drwx------`。予約の印が置かれた。証明書は `subject=CN=Local kernel module signing key`、`X509v3 Extended Key Usage: Code Signing`、`CA:TRUE`（`keyUsage` は無い） |
| 4（2 回目） | `中断: 鍵が既にある。作り直さずに、手順 7 で登録を確かめる`。鍵のファイルは変わらなかった（`sha256sum` が同じ） |
| 7 | 登録を模す前は `is not enrolled`、模した後は `/var/lib/shim-signed/mok/MOK.der is already enrolled`。`sudo` を付けないと `Failed to open`（スタブ） |
| ロールバック 1・4・5 | 予約の印が置かれ、削除を模した後の手順 4 は `is not enrolled`、手順 5 で `/var/lib/shim-signed` が消えた |

#### 未確認事項

- 実機での MokManager の登録と、署名したモジュールの受け入れ
- 実機での[ロールバック](../secure-boot-mok.md#ロールバック)
- aarch64 の PC

---

### 付録: 現行版を新規 VM で再検証（2026-10-06）

**対象**: `setup-notes` の `5da3478` 版。公式 ISO で Workstation を入れた `clean-install` スナップショットから、新規の `alma10-current-20261006-containers` を作った。AlmaLinux 10.2 / x86_64 / SELinux Enforcing / firewalld 有効。共通 bash は `3d5323e` を新規導入した。以前の付録と別の試験で、実行対象の現行ブロックを SSH の擬似端末で順に実行した。

実施手順 1 と 3 を通した。mokutil 0.7.2 / OpenSSL 3.5.8 は Workstation に導入済み。`SecureBoot disabled` / `Platform is in Setup Mode` が出たため、本文の条件に従って MOK 作成・import・MokManager での登録は行っていない。Secure Boot 有効時の分岐が通ったとは扱わない。

### 実施手順 / 手順 3: 補足: Secure Boot とモジュールの署名

- EL10 のカーネルは `CONFIG_MODULE_SIG=y`・`CONFIG_LOCK_DOWN_IN_EFI_SECURE_BOOT=y`・`CONFIG_MODULE_SIG_HASH="sha512"`（kernel-devel の `.config` で確認）。Secure Boot のときは、署名の無いモジュールや、登録されていない鍵で署名したモジュールを読み込まない
- モジュールをビルドする側のスクリプト（VirtualBox の `vboxdrv.sh`、Guest Additions のインストーラ）も、**`mokutil --sb-state` の答えだけ**で Secure Boot かを判定し、そのときだけ署名する
- VirtualBox の VM で Secure Boot が有効になるのは、VM の設定の「システム」→「マザーボード」で「UEFI」と「セキュアブート」を有効にしている場合（英語の表示では System → Motherboard の UEFI と Secure Boot）
- コンテナでは、本物の `mokutil` は `EFI variables are not supported on this system` を返した（終了コード 1）

### 手順内の実測・検証状況

- 登録できていなければ `is not enrolled` になる（実機で、登録できなかったときに出た）。手順 6 の箇条書きのとおりやり直す

### 手順内の実測・検証状況

- `sudo` が要る。鍵のディレクトリは root だけが入れる（`drwx------`）ので、付けないと `Failed to open /var/lib/shim-signed/mok/MOK.der` になった
