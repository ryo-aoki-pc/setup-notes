# Secure Boot の MOK 登録手順（AlmaLinux 10 / 自分でビルドするカーネルモジュールの署名鍵）の検証記録

[手順書](../almalinux-setup.md#secure-boot-の署名鍵-実施手順)・[ロールバックと注意点](../extra/secure-boot-mok.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **実機では、手順 6（MokManager での登録）を通せていない**（[対象と検証環境](#対象と検証環境)）。
>
> - 検証した PC（x86_64 のノート PC）では、MokManager でキーボードが効かず、鍵を登録できなかった
> - 登録と削除は、VirtualBox の VM の中の AlmaLinux（bootc）で確かめた
> - 2026-10-11 に、Hyper-V の VM の AlmaLinux 10.2（Workstation）でも、コンソールへのキー送信で登録を通した（[付録](#付録-hyper-v-の-vm-で通した記録2026-10-11)）。実機では、今も通せていない

### 実施手順 / 手順 4: 補足: 鍵の作り方と、登録した鍵の行き先

**鍵の作り方は、VirtualBox のスクリプトが出す案内に `-subj` と `-days` を足しただけ。** `vboxdrv.sh` は、Secure Boot で鍵が無いと次の案内を出す（[virtualbox.md の「VirtualBox を入れる」の手順 4](../almalinux-setup.md#virtualbox-virtualbox-を入れる) の補足の実測）:

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
- この文書を独立させる前（2026-09-30 より前）は、[virtualbox.md](../almalinux-setup.md#virtualbox-実施手順) が `VirtualBox module signing key`、[virtualbox-guest-bootc.md](../almalinux-setup.md#virtualbox-の-bootc-ゲスト-実施手順) が `VirtualBox Guest Additions module signing key` で作っていた。その名前で作った鍵も、そのまま使える（手順 4 は既にある鍵を作り直さない）

**登録した鍵は `.platform` キーリングに入る。**

- EL10 のカーネルは `CONFIG_INTEGRITY_CA_MACHINE_KEYRING=y`・`CONFIG_INTEGRITY_CA_MACHINE_KEYRING_MAX=y`
- kernel-devel に入っている Kconfig の説明によれば、MOK の鍵のうち CA の条件（CA ビットと `keyCertSign`）を満たすものだけが `.machine` に入り、残りは `.platform` に入る
- この証明書は `CA:TRUE` と `Code Signing` を持つが、`keyUsage` を持たない（`openssl x509 -text` で確認）ので、`.platform` 側になる
- RHEL 10 のドキュメント（[参照](../reference/secure-boot-mok.md#参照)）は「モジュールを読み込むとき、カーネルは `.builtin_trusted_keys` と `.platform` の鍵で署名を確かめる。`.platform` には独自の公開鍵も入る」と書いており、登録後の確認に `keyctl list %:.platform`（`keyutils` パッケージ）を使っている
- VirtualBox の VM の中の AlmaLinux（同じ EL10 のカーネル）では、登録した鍵は `.platform` に入り、`.machine` には入らなかった

**予約できたかは `sudo mokutil --list-new` で見られる**（実機で、鍵の `CN=` が出た）。`sudo` を付けないと何も出ない。

**bootc のシステムでも、鍵は残る。** `/var` は再起動や `bootc switch` をまたいで残る（イメージから上書きされない）。

**`MOK.priv` は、この PC（VM）が信頼するモジュールを作れる鍵になる。** root 以外に読ませず、ほかのマシンに持ち出さない。消し方は[ロールバック](../extra/secure-boot-mok.md#ロールバック)。

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
- 利用者は UEFI（BIOS）の設定で Secure Boot を無効にし、[virtualbox.md](../almalinux-setup.md#virtualbox-実施手順) を無効の分岐で進めた
- 別のキーボードや、UEFI の設定（Fast Boot など）でキーが効くようになるかは、確かめていない

### ロールバック / 手順 0: 本文中の記録

- この節の手順は、VirtualBox の VM の中（bootc のゲスト）で本実行した。実機では行っていない

### ロールバック / 手順 3: 補足: 画面の並び

VM で確かめた並び: `Delete MOK` → 「[Delete MOK]」（`View key 0` / `Continue`）→ `Continue` → 「Delete the key(s)?」→ `Yes` → パスワード → `Reboot`。

### 対象と検証環境

- **目的**: Secure Boot が有効な AlmaLinux 10 の PC（または VM）で、自分でビルドするカーネルモジュール（VirtualBox のホストのモジュール、Guest Additions のモジュール）を読み込めるようにする。そのために、署名用の鍵を作って UEFI の MOK（Machine Owner Key）に登録する
- **進め方**: `openssl` で鍵を `/var/lib/shim-signed/mok/` に作り、`mokutil --import` で予約して、再起動の途中の MokManager で登録する。読者が編集する変数は無い
  - もとは [virtualbox.md](../almalinux-setup.md#virtualbox-実施手順) と [virtualbox-guest-bootc.md](../almalinux-setup.md#virtualbox-の-bootc-ゲスト-実施手順) の中にあった同じ手順を、共有の前提として 1 本にした。鍵の CN は、どちらのモジュールにも使える `Local kernel module signing key` にそろえた
- **状態**: **手順 3〜7 のコマンドは、この文書に移す前に、次の検証で通したもの**（CN はそれぞれの手順書の名前だった）
  - これは 2026-10-06 までの状態。2026-10-11 に、この文書のブロック（今の CN）のまま、Hyper-V の VM で手順 1〜7 を上から通した（下の 2026-10-11 の行）
  - 2026-10-06 の[クリーンインストール VM](../almalinux-vm-verification.md)では、`mokutil --sb-state` が `SecureBoot disabled` と `Platform is in Setup Mode` を返した。本文の条件に従って登録は行わず、今回の VM 試験に MOK 登録の結果は含めない
  - x86_64 の実機（[virtualbox.md の本実行](virtualbox.md#付録-実機での本実行2026-09-29)、2026-09-28。AMD のノート PC）
    - 手順 3 で `SecureBoot enabled`、手順 4 で鍵を作って予約し（`sudo mokutil --list-new` に鍵が出た）、手順 5 で再起動した
    - **手順 6 の MokManager でキーボードが効かず、登録できなかった**。手順 7 は `is not enrolled` になった。利用者が UEFI の設定で Secure Boot を無効にした
  - VirtualBox の VM の中の AlmaLinux Atomic Desktop（[virtualbox-guest-bootc.md の VM での本実行](virtualbox-guest-bootc.md#付録-virtualbox-の-vm-での本実行2026-09-29)、2026-09-29 と 2026-09-30。Secure Boot 有効）
    - 手順 3・4、MokManager での登録（手順 6）、手順 7、[ロールバック](../extra/secure-boot-mok.md#ロールバック)（2026-09-29 の VM）
    - 登録のための再起動は、多くの回で `bootc switch --apply` の再起動を使った。**手順 5 の `sudo systemctl reboot` からの登録**は、MokManager をわざと見送った後のやり直しで通した
    - MokManager を見送ったときの失敗のしかた、`.platform` のキーリングに入ること
  - 2026-09-30 に、この文書のブロックを x86_64 のコンテナで通した（[付録](#付録-コンテナでの検証記録2026-09-30)）
    - 手順 1〜4（`mokutil` はスタブ）、手順 4 の 2 回目が `中断:` で止まること、新しい CN で証明書ができること、手順 7 とロールバックの手順 1・4・5（スタブ）
  - **確認していないこと**: 実機での MokManager の登録（キーボードが効かなかった）と、実機で署名したモジュールが受け入れられること。実機での[ロールバック](../extra/secure-boot-mok.md#ロールバック)。aarch64
  - **2026-10-11 に、Hyper-V の第 2 世代の VM（Secure Boot 有効。x86_64。Kickstart で入れた AlmaLinux 10.2 の Workstation のクローン）で、実施手順 1〜7 を上から通した**（[付録](#付録-hyper-v-の-vm-で通した記録2026-10-11)）
    - 結果: 通した 6（手順 1・3〜7）、通らなかった 0、条件に当たらず飛ばした 1（手順 2。`mokutil` と `openssl` は入っていた）、未実施 0
    - 通し方: ブロックは、SSH の対話の bash に貼った（GNOME のコンソールにはログインしていない）。手順 6 の MokManager は、人が VM のウィンドウで押す代わりに、コンソールへのキー送信で操作し、画面の PNG で確かめた
    - 確認したこと: この文書のブロック（CN は `Local kernel module signing key`）と、スタブではない `mokutil`・MokManager で、鍵の作成・予約・登録・手順 7 の `is already enrolled` まで。この VM では、登録した鍵は `.platform` に入り、`.machine` は空だった。登録の後の手順 4 は `中断:` で止まり、鍵のファイルは変わらなかった。VM の電源を入れ直した後も、手順 7 は `is already enrolled` だった
    - 手順書と違った所: `sudo` が OS のパスワードを聞いた（初期設定を通していないベース。手順 4 の入力は、一時パスワードの 2 回と合わせて 3 回）。この点では、手順書は変えていない（手順書は、NOPASSWD の `sudo` を前提に書く決まり）
    - 直した所: 文言だけを、手順書の 2 か所と参考資料の 2 か所。手順 6 の注意と、参考資料の手順 7 の補足の案内先を、この検証記録の手順 6 の補足に直した。手順 5 に、VM に SSH でつないで貼るときは先に VM のウィンドウを開いておく 1 行を足し、その理由を参考資料の手順 5 の補足に書いた。コードブロックは変えていない（直した文言は、VM では流していない）
    - 確認していないこと: 人が VM のウィンドウや物理のキーボードでキーを押す形（先にウィンドウを開いておけば間に合うかも）、MokManager を見送ったときの分岐とやり直し、手順 2 の導入と手順 3 の無効の分岐、[ロールバック](../extra/secure-boot-mok.md#ロールバック)、この鍵で署名したモジュールの読み込み、GNOME の端末に貼る形、NOPASSWD の `sudo` での通し。今回は、VMware Workstation Pro と VirtualBox の VM では通していない（VirtualBox の VM の記録は、上の行の、この文書に移す前のコマンドのもの）。実機と aarch64 は、上の行のまま

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
- 実機での[ロールバック](../extra/secure-boot-mok.md#ロールバック)
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

---

### 付録: Hyper-V の VM で通した記録（2026-10-11）

- **何を**: [手順書](https://github.com/ryo-aoki-pc/setup-notes/blob/114c2b2bfd14b51f9e1925b150cbf72e1954f311/docs/secure-boot-mok.md)の実施手順 1〜7（コミット `114c2b2`）を、上から最後まで通した
  - この文書のブロック（CN は `Local kernel module signing key`）を、スタブではない `mokutil` と MokManager で、手順 1 から 7 まで通した記録は、この検証記録にある中では、これが初めて（それまでの登録の記録は、この文書に移す前の手順書のコマンドのもの）
  - [ロールバック](../extra/secure-boot-mok.md#ロールバック)は流していない
- **どの状態から**: Secure Boot を有効にして入れた AlmaLinux 10.2 の Workstation のスナップショット `clean-install` からのクローン。初期設定（[almalinux-setup.md](../almalinux-setup.md)）は通していない
  - ベースを Kickstart で入れたことと、Secure Boot を有効にした状態で入れたことは、依頼で示された前提で、この通しの証跡では確かめていない（証跡にあるのは、クローンの始めの `mokutil --sb-state` が `SecureBoot enabled` だったこと）
- **誰が**: VM で通した担当と、この付録を書いた担当は別（どちらもエージェント）。付録は、通した担当の報告と証跡を照らして書いた（書く担当は、VM に触れていない）
  - 書いた後に、さらに別の担当（エージェント）が、付録と手順書の直しを証跡に当てて点検した（点検した担当も、VM に触れていない）
- **どう通したか**: 手順書から抜き出したブロックを、SSH の対話の bash に、ブラケットペーストで 1 つずつ貼った（GNOME のコンソールにはログインしていない）
  - 貼ったブロックは、手順書のものと 1 文字も違わない（`session/steps.jsonl` の `sha256` と `pastedSha256` が同じ。直した後の手順書のブロックとも、sha256 が同じ）
  - 手順 6 の MokManager は、人が VM のウィンドウで押す代わりに、コンソールへのキー送信で操作し、画面の PNG で確かめた（[キー送信と、人が物理のキーボードで行う操作との違い](#キー送信と人が物理のキーボードで行う操作との違い)）
  - 手順 6 の最後の「起動したらログインし、新しい端末を開く」は、SSH の入り直しにした
- **結果**: 通した 6（手順 1・3・4・5・6・7）、通らなかった 0、条件に当たらず飛ばした 1（手順 2）、未実施 0
- **証跡**: 追跡していない `.verification/campaign/hv/CL4/`（このリポジトリには入っていない）。下のファイルの名前は、ここからの相対パス。`seq` は `session/steps.jsonl` の番号
- 出力の中の VM の値は、`<USER>`・`<HOSTNAME>`・`<SERVER_IP>` で書いた。MOK の秘密鍵・一時パスワード・`sudo` のパスワードは載せていない（一時パスワードのファイルは、この付録を書く担当も開いていない）
- 行番号は、コミット `114c2b2` のもの。直した後の手順書では、行がずれている

#### 環境（Hyper-V）

| 項目 | 内容 |
|---|---|
| ホスト | Windows 11 Pro 10.0.26300 |
| ハイパーバイザ | Hyper-V。`meta.json` の層の値は `Generation=2`・`Version=12.0`・`HypervisorPresent=True`（`vmms.exe` 10.0.26100.8875 は、担当の報告による） |
| VM | 第 2 世代（UEFI）、Secure Boot 有効、2 vCPU、3072 MB（ゲストから見えるのは 2640 MB）、ディスク 64 GB（ゲストでは `sda`）、NIC 1 枚（ゲストでは `eth0`）。Secure Boot のテンプレートが `MicrosoftUEFICertificateAuthority` であること、メモリが固定であること、NIC が Default Switch であることは、担当の報告による |
| ベース | Secure Boot を有効にして入れた AlmaLinux 10.2 の Workstation のスナップショット `clean-install` からのクローン（差分ディスクを付けた新しい VM。起動を始めてから SSH が通るまで 10.5 秒）。始めから `mokutil --sb-state` は `SecureBoot enabled`、鍵のファイルは無い |
| クローンと NVRAM | この検証の基盤では、スナップショットからのクローンは新しい VM として作られ、NVRAM（登録した MOK）を引き継がない（層の作りからの見立て。クローンで登録が無くなることは、試していない） |
| ゲスト | AlmaLinux 10.2 (Lavender Lion)、kernel `6.12.0-211.64.1.el10_2.x86_64`、x86_64、`systemd-detect-virt` は `microsoft`。`sudo` と `ls` の表示は日本語 |
| 関係するパッケージ | `mokutil-0.7.2-4.el10.alma.1`・`openssl-3.5.8-2.el10_2.alma.1`・`shim-x64-16.1-4.el10.alma.1`・`grub2-efi-x64-2.12-46.el10_2.alma.1`・`keyutils-1.6.3-5.el10`（どれも入っていた。この通しで入れたものは無い） |
| ゲストの道具 | `hyperv-daemons` 0-0.50.20220731git。`open-vm-tools` 13.0.10 と `qemu-guest-agent` 10.1.0-16 も入っている（`meta.json`） |
| `sudo` | パスワードを聞く設定（初期設定を通していないベース）。手順書は、聞かない設定（NOPASSWD）を前提に書いてある |
| 手順書 | `docs/secure-boot-mok.md`、コミット `114c2b2`（`114c2b2bfd14b51f9e1925b150cbf72e1954f311`）。貼ったブロックの sha256 は `steps.jsonl` にある |
| 実施の日時 | 2026-10-11 11:30〜11:37 UTC（ゲストの時計で 20:30〜20:37 JST）。手順 1 を貼ってから手順 7 の出力まで 3 分 59 秒 |
| 貼り方 | ドライバ（`rb.mjs paste`）で、SSH の対話の bash にブラケットペーストで 1 ブロックずつ。パスワードの入力は、ファイルから伏せて送った（`steps.jsonl` には `masked` とだけ残る）。手順 6 は、層の `Send-VmvKeys`（Hyper-V の `Msvm_Keyboard`）と `Save-VmvScreenshot` |
| 終わりの状態 | VM は停止、スナップショット `after-CL4`（MOK に鍵を登録済み）。担当の報告による |

#### 手順ごとの結果（Hyper-V）

| 手順 | 判定 | 出たもの | 根拠の場所 |
|---|---|---|---|
| 1 | 通した | `mokutil-0.7.2-4.el10.alma.1.x86_64`・`openssl-3.5.8-2.el10_2.alma.1.x86_64` の 2 行 | seq 1、`session/session-001.raw` |
| 2 | 条件に当たらず飛ばした | 手順 1 で 2 つとも版が出た。`dnf install` は貼っていない | seq 2（メモ） |
| 3 | 通した | `SecureBoot enabled` | seq 3 |
| 4 | 通した | `.` と `+` の行が流れて `-----` で終わり、「確認」の後ろに `MOK.der`（848 バイト、`-rw-r--r--`）と `MOK.priv`（1704 バイト、`-rw-------`）、続けて `input password:` と `input password again:`。2 回に答えると、プロンプトに戻った。その前に、`sudo` が OS のパスワードを 1 回聞いた（入力は合わせて 3 回） | seq 4〜7、`session/after-confirm/0004-実施手順-4.txt` |
| 5 | 通した | `The system will reboot now!` が出て、SSH が切れた。`sudo` は聞かなかった（手順 4 の `sudo` から 1 分以内）。貼ってから 3 秒足らずで、MokManager の最初の画面が出た | seq 9、`screens/boot1-watch.log`、`screens/boot1-001.png`・`boot1-002.png` |
| 6 | 通した（キー送信で） | 画面の並びは、手順書のとおり（[手順 6 の画面](#手順-6-の画面hyper-v)）。次の起動では、MokManager は出なかった | seq 11（メモ）、`screens/boot1-002.png`・`boot1-after-key-1.png`〜`boot1-after-key-3.png`・`mok-01-…`〜`mok-09-…`・`boot2-*.png` |
| 7 | 通した | `/var/lib/shim-signed/mok/MOK.der is already enrolled`。`sudo` が OS のパスワードを聞いた（入り直した SSH のセッション） | seq 12・13 |

- 手順書の外で、同じブロックをもう一度貼った所
  - 手順 4 の 2 回目（登録の後。seq 17）: `中断: 鍵が既にある。作り直さずに、手順 7 で登録を確かめる` で止まった。前後で、`MOK.der` の `sha256sum` の先頭 16 桁と、2 つのファイルの更新時刻・大きさは同じだった（seq 16・18）
  - 手順 7 の 2 回目（VM の電源を切って入れ直した後。seq 20・21）: `is already enrolled`。`sudo keyctl list %:.platform` の中の `Local kernel module signing key` は 1 行（seq 22）。起動の PNG（`screens/boot3-cold-*.png`）に、MokManager の画面は無い
- 読むだけの確かめ（手順書の外。seq 8・14・15）
  - 手順 4 の後の `sudo mokutil --list-new`: `[key 1]`、`Subject: CN=Local kernel module signing key`、`Not After : Sep 17 11:31:13 2126 GMT`、`CA:TRUE`、`Code Signing`。鍵のディレクトリは `drwx------. 2 root root`
  - 手順 7 の後: `mokutil --sb-state` は `SecureBoot enabled`、`sudo mokutil --list-new` は 0 行、`mokutil --list-enrolled` は 4 つ（1〜3 は AlmaLinux OS Foundation が 2 つと AlmaLinux Secure Boot CA、4 つ目が `CN=Local kernel module signing key` で、SHA1 の指紋は予約のときと同じ）
  - `sudo` を付けない `mokutil --test-key /var/lib/shim-signed/mok/MOK.der` は、`Failed to open /var/lib/shim-signed/mok/MOK.der`（終了コード 255）
  - `sudo dmesg`: `secureboot: Secure boot enabled`、`Kernel is locked down from EFI Secure Boot mode; see man kernel_lockdown.7`、`integrity: Loading X.509 certificate: UEFI:MokListRT (MOKvar table)`、`integrity: Loaded X.509 cert 'Local kernel module signing key: …'`
  - `sudo keyctl list %:.platform` は `7 keys in keyring:` で、その中に `asymmetric: Local kernel module signing key: …`。`sudo keyctl list %:.machine` は `keyring is empty`（[手順 4 の補足](#実施手順--手順-4-補足-鍵の作り方と登録した鍵の行き先)の、VirtualBox の VM の記録と同じ）
  - `/sys/kernel/security/lockdown` は `none [integrity] confidentiality`、`/proc/sys/kernel/tainted` は `0`

#### 手順 6 の画面（Hyper-V）

| 順 | 送ったキー | 出た画面 | PNG |
|---|---|---|---|
| 0 | （手順 5 の再起動） | 黒い画面の中央に青い枠。上に `Shim UEFI key management`、中央に `Press any key to perform MOK management`、左下に `Booting in 10 seconds` | `boot1-002.png` |
| 1 | ↓（最初のキー） | `Perform MOK management`: `Continue boot`（選ばれている）/ `Enroll MOK` / `Enroll key from disk` / `Enroll hash from disk` | `boot1-after-key-1.png`〜`boot1-after-key-3.png` |
| 2 | ↓ → Enter | ↓ で `Enroll MOK` が選ばれ、Enter で `[Enroll MOK]`: `View key 0`（選ばれている）/ `Continue` | `mok-01`・`mok-02` |
| 3 | ↓ → Enter | ↓ で `Continue` が選ばれ、Enter で `Enroll the key(s)?`: `No`（選ばれている）/ `Yes` | `mok-03`・`mok-04` |
| 4 | ↓ → Enter | ↓ で `Yes` が選ばれ、Enter で `Password:` の欄 | `mok-05`・`mok-06` |
| 5 | 一時パスワード（12 文字） | `Password:` の欄のまま。打った文字は出ない（打つ前の PNG と、中身が 1 バイトも違わない） | `mok-07` |
| 6 | Enter | `Perform MOK management`: `Reboot`（選ばれている）/ `Enroll key from disk` / `Enroll hash from disk` | `mok-08` |
| 7 | Enter | 再起動。GRUB のメニュー → `Booting 'AlmaLinux …'` → カーネルのメッセージ → 起動中の画面 → GDM のログインの画面。MokManager は出ない | `mok-09`・`boot2-001.png`・`boot2-003.png`・`boot2-004.png`・`boot2-019.png` |

- PNG は `screens/` の下。`mok-01`〜`mok-09` は、`mok-01-menu-enroll-selected.png`・`mok-02-enroll-mok.png`・`mok-03-continue-selected.png`・`mok-04-enroll-the-keys.png`・`mok-05-yes-selected.png`・`mok-06-password-prompt.png`・`mok-07-password-typed.png`・`mok-08-after-password.png`・`mok-09-after-reboot-enter.png`
- 順 2 から後ろの「送ったキー」は、担当のメモ（seq 11）による（キーを送った道具の表示は、ファイルに残っていない）。PNG の選択の動きと合っている。最初のキーは、`screens/boot1-watch.log` に残っている
- 画面の並びは、手順書の手順 6 の箇条書き（`Enroll MOK` → `Continue` → `Yes` → 一時パスワード → `Reboot`）と、VirtualBox の VM で確かめた並び（[手順 6 の補足](#実施手順--手順-6-補足-画面の並びと登録できなかった-pc)）のとおりだった
- どのメニューも、出たときに選ばれているのは 1 つ目（`Continue boot`・`View key 0`・`No`）で、登録に進む項目は、↓ を 1 回押した所にあった
- 最初の画面で送った ↓ は、次のメニューの選択を動かさなかった（`Continue boot` が選ばれたまま）
- 最初のキーの後は、画面は待ち続けた。最初のキー（11:31:52 UTC）から `Reboot` の Enter（11:33:53 ごろ）まで約 2 分で、その間に画面が先へ進むことは無かった
- `View key 0`（証明書の中身）は開いていない
- 時間
  - 手順 5 を貼ってから 2.4 秒の時点の PNG は `Hyper-V` のロゴ（`boot1-001.png`）、2.8 秒の時点の PNG が最初の画面（`boot1-002.png`）
  - `Reboot` の Enter の 1〜2 秒後の PNG（`mok-09`）は GRUB のメニュー、約 20 秒後の PNG（`boot2-019.png`）は GDM のログインの画面。SSH の入り直しは 3.9 秒
  - 電源を入れ直したとき（`boot3-cold`）は、見張りを始めて 0.8 秒の PNG が GRUB のメニュー、22.7 秒の PNG が GDM のログインの画面

#### キー送信と、人が物理のキーボードで行う操作との違い

手順書の手順 6 は、人が PC のキーボード（VM なら、VM のウィンドウ）で押す操作として書いてある。この通しは、次の所が違う。

- **キーの届け方**: Hyper-V の WMI（`Msvm_Keyboard`）で、ゲストの仮想のキーボードにキーを入れた。↓ と Enter は `TypeKey`（仮想キーコード）、一時パスワードは `TypeScancodes`（US 配列のスキャンコード）。物理のキーボードも、VM のウィンドウ（仮想マシン接続）のフォーカスも通っていない
  - 実機の MokManager でキーボードが効かなかった件（[手順 6 の補足](#実施手順--手順-6-補足-画面の並びと登録できなかった-pc)）は、物理のキーボードの話で、この通しからは何も分からない
- **最初のキーの速さ**: 画面を 1 秒おきに撮って青い画素の割合を見る道具（`tools/Watch-MokManager.ps1`）が、最初の画面を見つけた約 0.3 秒後に ↓ を送った
  - 人が画面を見てから押して 10 秒に間に合うか、SSH で貼った後に VM のウィンドウを開いて間に合うかは、確かめていない
  - 最初の画面は、`Booting in 10 seconds` の 1 枚しか撮っていない。数字が減る所と、10 秒で消える所は見ていない
  - 道具は、先に GDM のログインの画面で、キーを送らない形で動かし、青の割合が 0 と出ることを見てから使った（`screens/pretest-watch.log`・`screens/pretest-001.png`）
- **画面の見方**: 人は、VM のウィンドウで見る。この通しは、Hyper-V の画面の取得（1024×768 の PNG）で見た。キーを送るたびに約 1 秒待って PNG を撮り、それを見てから次のキーを送った
- **一時パスワード**: 検証用にその場で作った、英小文字と数字だけの 12 文字を、ファイルから読んで送った（`tools/Send-MokPassword.ps1`。値は表示していない）
  - 記号と大文字（キー配列や Shift で位置が変わる文字）は打っていない。JIS のキーボードで記号を含むパスワードを打つときに、同じ文字が入るかは確かめていない
  - `Password:` の欄が出ていることを PNG で確かめてから送り、Enter は別に送った
- **ログイン**: 手順 6 の最後の「起動したらログインし、新しい端末を開く」は行わず、SSH を入り直して手順 7 を貼った

#### 通らなかった手順と、手順書と違った所（Hyper-V）

- 通らなかった手順は無い
- 手順書の書き方と違ったのは、`sudo` のパスワードの 1 つ
  - 手順 4 は、手順書の「一時パスワードを 2 回」の前に `[sudo] <USER> のパスワード:` が 1 回入り、入力は 3 回になった。手順 7 と、電源を入れ直した後の手順 7 でも聞いた。手順 5 では聞かなかった
  - 見立て: 環境のせい（この VM は初期設定を通しておらず、`sudo` が NOPASSWD ではない）。SSH から貼ったせいでも、Hyper-V のせいでも、手順書のせいでもない。手順書は変えていない
  - ブラケットペーストで貼った手順 4 のブロックは、`sudo` がパスワードを聞いても、後ろの行は失われなかった（鍵の作成・「確認」・`ls`・`mokutil --import` まで順に動いた）
- SSH から貼ったことで違った所は、手順 5 で SSH が切れることだけ（ドライバの記録は `accepted: false`・`disconnected`。出力には `The system will reboot now!` が残っている）。この手順書に、デスクトップのセッションが要るコマンドは無い

#### Hyper-V に左右されたと思われる値

担当の報告が挙げた値を、証跡と照らして並べた。ほかのハイパーバイザと比べて確かめたものではない。

| 項目 | 値 |
|---|---|
| `systemd-detect-virt` | `microsoft` |
| DMI | `Microsoft Corporation` / `Virtual Machine` / BIOS `Hyper-V UEFI Release v4.1` |
| NIC とディスク | `eth0`、`sda`（64G） |
| アドレス | `<SERVER_IP>`。再起動の後も、電源を入れ直した後も、同じアドレスで SSH がつながった |
| ログインの案内 | `Web console: https://<HOSTNAME>.mshome.net:9090/ or https://<SERVER_IP>:9090/` |
| `efibootmgr` | `BootCurrent: 0002`、`BootOrder: 0002,0001,0000`、`Boot0000* EFI Network`、`Boot0001* EFI SCSI Device`、`Boot0002* AlmaLinux`（`\EFI\almalinux\shimx64.efi`） |
| MokManager の画面 | 1024×768 の画面の中央に、640×456 画素ほどの青い枠（`boot1-002.png` の青い画素の範囲）。ファームウェアの段階の画面も、層の道具で撮れた |
| 再起動から最初の画面まで | 手順 5 を貼ってから 3 秒足らず |
| MOK の一覧の渡り方 | `sudo dmesg` に `efi: … MOKvar=0x…` と `integrity: Loading X.509 certificate: UEFI:MokListRT (MOKvar table)` |
| 起動の時間 | クローンの起動を始めてから SSH が通るまで 10.5 秒（`meta.json` の `secondsToSsh`）。`Reboot` の Enter から GDM のログインの画面まで約 20 秒 |

- 時間は、ほかの VM が動いていないホストで測ったものかを確かめていない。性能の比べには使わない

#### 見つかった指摘と状態

担当の報告（`result.md` の 4 節）が挙げた指摘。重大度は、報告が付けたもの。報告の T1（スナップショットからのクローンと NVRAM）は、検証の基盤の話なので、[環境の表](#環境hyper-v)に書いた。

| 連番 | 種別 | 重大度 | 場所 | 何が起きたか | 切り分け | 状態 |
|---|---|---|---|---|---|---|
| D1 | 手順書 | 低 | `docs/secure-boot-mok.md:80`（手順 6 の注意）、`docs/reference/secure-boot-mok.md:28`（手順 7 の補足） | 手順 6 の注意は「参考資料を参照」、参考資料は「手順 6 の補足」と書くが、参考資料に手順 6 の補足は無い（「キーボード」の語も無い）。キーボードが効かなかった PC の記録と、`Loading of module with unavailable key is rejected` の記録は、この検証記録の[手順 6 の補足](#実施手順--手順-6-補足-画面の並びと登録できなかった-pc)にある | 手順書のせい（文書を分けたときの行き先の食い違い、とみる）。VM で通した結果には関わらない | 直した（文言。2 か所とも、この検証記録の手順 6 の補足へのリンクにした） |
| D2 | 手順書 | 低 | `docs/secure-boot-mok.md:73`（手順 5）、`:11`（リード） | Hyper-V の VM では、手順 5 を貼ってから 3 秒足らずで MokManager の最初の画面が出た。リードと手順 6 は「VM なら VM のウィンドウで押す」と書くが、貼る前にウィンドウを開いておくことは書いていない | Hyper-V の再起動の速さと、手順書の書き方の両方（担当の報告の見立て。同じ再起動を、ほかのハイパーバイザで測って比べてはいない）。関わるのは、SSH から貼るときだけ（VM のウィンドウの端末に貼るなら、ウィンドウは開いている）。人が間に合うかは、確かめていない | 直した（文言。手順 5 に 1 行を足した。時間は、Hyper-V の VM の値として、参考資料の手順 5 の補足に書いた。リードは変えていない） |
| E1 | 環境 | 低 | ベースの VM | `sudo` が OS のパスワードを聞く。手順 4 の入力が 3 回になった | 環境のせい（初期設定を通していない）。手順書は、NOPASSWD の `sudo` を前提に書く決まり | 対応しない（手順書は変えない） |

#### 手順書を直した所

どれも文言だけ（箇条書きと補足）。コードブロックは変えておらず、VM では流していない。

- [手順書](https://github.com/ryo-aoki-pc/setup-notes/blob/114c2b2bfd14b51f9e1925b150cbf72e1954f311/docs/secure-boot-mok.md)の手順 6: 注意の「（参考資料を参照）」を、この検証記録の手順 6 の補足へのリンクにした（D1）
- [参考資料](../reference/secure-boot-mok.md)の「実施手順 / 手順 7」の補足: 「（手順 6 の補足）」を、この検証記録の手順 6 の補足へのリンクにした（D1）
- 手順書の手順 5: 「VM に SSH でつないで貼るときは、貼る前に VM のウィンドウを開いておく」を足した（D2）
- 参考資料: [「実施手順 / 手順 5」の補足](../reference/secure-boot-mok.md#実施手順--手順-5-補足-vm-のウィンドウを先に開いておく)を足した（D2。Hyper-V の VM で測った時間と、`sudo systemctl reboot` からの時間を、ほかのハイパーバイザと実機では測っていないこと。VirtualBox の VM の記録にある、別のコマンドからの 54 秒も書いた）
- 直していない所
  - [ロールバックと注意点](../extra/secure-boot-mok.md)は変えていない。ロールバックの手順 2 も同じ再起動だが、この通しでは流していない
  - 手順 6 に、選ばれている項目・押すキー・`Password:` の欄に文字が出ないことは足していない（手順書と食い違ってはいない。上の「手順 6 の画面」に書いた）

#### 報告と証跡を照らした所

- 担当の報告（`result.md`）の判定と出力は、`session/steps.jsonl`・`session/session-001.raw`〜`session-003.raw`・PNG と合っていた
- 証跡のほうが細かかった所
  - 報告は「`Reboot` の Enter から 28 秒の時点で GDM のログイン画面（`boot2-025.png`。それより前の何枚目で出たかは見ていない）」と書く。証跡では、約 20 秒後の `boot2-019.png` が、もうログインの画面だった
  - 報告の表は、`Reboot` の後を「カーネルのメッセージ → GDM のログイン画面」と書く。`mok-09` は GRUB のメニューで、その後に `Booting 'AlmaLinux …'`、カーネルのメッセージ、起動中の画面が続く
  - 報告は、`boot2` と `boot3-cold` の PNG の一部だけを開いている。この付録を書くときに、73 枚の PNG を中身の同じもの（28 通り）にまとめ、全部の種類を開いた。`boot2` と `boot3-cold` に、MokManager の画面は無い
  - 報告は、MokManager の青い枠を「640×480 ほど」と書く。`boot1-002.png` の青い画素の範囲は、640×456 画素ほど
- 証跡のファイルに無く、担当の報告だけによるもの
  - ホストの Windows の版と `vmms.exe` の版、Secure Boot のテンプレートの名前、メモリが固定であること、NIC が Default Switch であること
  - 電源の入れ直しの操作（VM を止めてから起動したこと）。証跡にあるのは、担当のメモ（seq 19）、SSH のセッションを閉じてから 12 秒後に始めた見張りの PNG（`boot3-cold`。1 枚目が GRUB のメニュー）、3 つ目のセッションの `uptime -s`（新しい起動の時刻）で、止め方（ゲストの終了か、電源を切る形か）は残っていない
  - 一時パスワードが、英小文字と数字だけの 12 文字であること（ファイルは開いていない。ファイルの大きさは 12 バイト）
  - 終わりの状態（VM の停止とスナップショット `after-CL4`）、手順書のファイルを変えていないこと（`git status --short` が 0 行）
  - 一時パスワードの値が記録のファイルに無いこと（担当が値で探して 0 件）。3 つの `session-00N.raw` では、`[sudo] <USER> のパスワード:`・`input password:`・`input password again:` の後ろに、打った文字は出ていない

#### 確かめていないこと（Hyper-V）

- 人が行う形: VM のウィンドウ（仮想マシン接続）や物理のキーボードでキーを押す、画面を見てから 10 秒以内に押す、SSH で貼ってから VM のウィンドウを開く、貼る前に VM のウィンドウを開いておく（手順 5 に足した 1 行の形）
- 最初の画面の数え下げと、10 秒で消えること。何もしないで進んだとき（登録されない）と、そのやり直し（手順 6 の 3 つ目の箇条書き）
- `View key 0` の中身、記号や大文字を含む一時パスワード、一時パスワードを間違えたとき
- 手順 2 の導入、手順 3 の `SecureBoot disabled` の分岐（この VM は、どちらにも当たらない）
- GNOME のコンソールにログインして、その端末に貼る形。NOPASSWD の `sudo` での通し
- この鍵で署名したモジュールが読み込まれること（[virtualbox.md](https://github.com/ryo-aoki-pc/setup-notes/blob/114c2b2bfd14b51f9e1925b150cbf72e1954f311/docs/virtualbox.md) の側。見たのは、鍵が `.platform` に入った所まで）
- [ロールバック](../extra/secure-boot-mok.md#ロールバック)（`Delete MOK`）
- SELinux の拒否の有無（この通しでは、監査ログを読んでいない）
- 直した文言（VM では流していない）
- 実機、aarch64、bootc のシステム。今回は、VMware Workstation Pro と VirtualBox の VM では通していない（VirtualBox の VM での登録と削除の記録は、[対象と検証環境](#対象と検証環境)の状態の行の、この文書に移す前のコマンドのもの）
