# Windows 11 を AlmaLinux 10 とのデュアルブート向けに入れる手順（ESP を 2 GiB にし、AlmaLinux 用の空きを残す）の参考資料

[手順書](../windows-dual-boot.md)

[検証記録](../verification/windows-dual-boot.md#参考資料から分離した記録)

## 補足

### 実施手順 / 手順 1: 補足: 3rd Party UEFI CA が要る理由

- Rufus は、大きなファイル（`install.wim`）がある ISO を NTFS で USB に書き、USB の末尾に UEFI:NTFS の小さなパーティションを足す。PC はまずこの UEFI:NTFS を起動し、それが NTFS の中の Windows のブートローダーを起動する（Rufus 4.15 の `src/drive.c`）
- Rufus の `res/uefi/readme.txt` によれば、UEFI:NTFS のブートローダーと NTFS のドライバーは Microsoft の Secure Boot の署名付き。この署名は 3rd Party UEFI CA（Microsoft Corporation UEFI CA）で確かめられる
- AlmaLinux 10 の shim も、同じ系列の CA（2011 と 2023 の Microsoft UEFI CA）で署名されている（AlmaLinux の wiki）
- Secured-core PC など、3rd Party UEFI CA を既定で許可しない PC がある。許可していないと、Secure Boot の違反で起動が止まる

### 次回だけ AlmaLinux で起動する（任意） / 手順 7: 補足: Save は要らず、確認画面だけでは成功といえない

- `Set reboot` は、その場で `BootNext` を書いてから再起動の確認を出す。`Save` は通常の起動順（`BootOrder`）を書く別の操作
- v0.5.0 は、`BootNext` の書き込みの成否を確認せずに再起動の確認を出す。そのため `Yes` ですぐ再起動せず、この節の手順 8 で読み戻す
- 対象を間違えた場合も `No` を選び、[取り消す節](../windows-dual-boot.md#次回起動の指定を取り消す任意)で自分が指定した対象を確認して解除してからやり直す

### 選択した方針

**Rufus の 7 項目と、この文書の手順の関係**:

| Rufus の項目 | Rufus がすること（4.15 の `src/wue.c`） | この文書の手順 |
|---|---|---|
| 4GB以上のRAM、セキュアブート及びTPM 2.0の要件を削除 | `boot.wim` の中のレジストリに `HKLM\SYSTEM\Setup\LabConfig` の `BypassTPMCheck`・`BypassSecureBootCheck`・`BypassRAMCheck` を書く | 無し（要件を満たす PC でも、Rufus はオンを勧めている） |
| オンラインアカウントの要件を削除 | `BypassNRO` を 1 にする。ネットワークから外しておくことが条件 | 手順 2・7 |
| ローカルアカウントを次の名前で作成: | 空のパスワードの管理者のアカウントを作り、次のサインインで変更を求める | 手順 7 |
| 地域設定をこのユーザーと同じものに設定 | Rufus を動かした PC の入力ロケール・ロケール・タイムゾーンを書く | 手順 11・13 |
| データ収集を無効化 | ライセンスの画面を隠し、プライバシーの質問に「いいえ」で答える | 手順 7 |
| BitLocker 自動デバイス暗号化を無効化します。 | `PreventDeviceEncryption` を true にする | 手順 11 |
| 利便性向上パッチ(Microsoftの各種ソフトウェアの無効化) | OneDrive・Outlook・Teams を外し、Copilot・ニュースなどを切り、`HiberbootEnabled` を 0 にする | 手順 11・12 |

- ローカルアカウントの名前の既定は、Rufus を動かした Windows のユーザー名
- 「スタート」の後に「警告: デバイス “<デバイス>” のデータは消去されます。」の確認が出る



### 参照

- [UEFI/GPT-based hard drive partitions](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/configure-uefigpt-based-hard-drive-partitions)（ESP・MSR・回復の大きさと並び、サンプルの `CreatePartitions-UEFI.txt`）
- [Windows and GPT FAQ](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-and-gpt-faq)（ESP は先頭に 1 つ）
- [create partition efi](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/create-partition-efi)（diskpart の `create partition efi size=`）
- [Boot to UEFI Mode or legacy BIOS mode](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/boot-to-uefi-mode-or-legacy-bios-mode)（`PEFirmwareType`）
- [Windows Recovery Environment (Windows RE) technical reference](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-recovery-environment--windows-re--technical-reference)（セットアップが WinRE を回復パーティションへコピーする段階、回復パーティションの広げ方）
- [KB5028997: Instructions to manually resize your partition to install the WinRE update](https://support.microsoft.com/en-us/topic/kb5028997-instructions-to-manually-resize-your-partition-to-install-the-winre-update-400faa27-9343-461c-ada9-24c8229763bf)（`reagentc /disable` → `reagentc /enable`）
- [インストール メディアを使用して Windows を再インストールする](https://support.microsoft.com/ja-jp/windows/reinstall-windows-with-the-installation-media-d8369486-3e33-7d9c-dccc-859e2b022fc7)（セットアップの手順）
- [Windows 11, version 25H2 known issues](https://learn.microsoft.com/en-us/windows/release-health/status-windows-11-25h2)（KB5089549 と ESP の空き）
- [BitLocker countermeasures](https://learn.microsoft.com/en-us/windows/security/operating-system-security/data-protection/bitlocker/countermeasures) / [Find your BitLocker recovery key](https://support.microsoft.com/en-us/windows/find-your-bitlocker-recovery-key-6b71ad27-0b89-ea08-f143-056f5ab347d6)（PCR 7、回復キー）
- [Rufus](https://github.com/pbatard/rufus) 4.15 のソース: `src/wue.c`（「インストーラーをカスタムしますか?」の各項目）、`src/drive.c`（USB の並びと UEFI:NTFS）、`res/loc/rufus.loc`（日本語の表示）、[issue #2499](https://github.com/pbatard/rufus/issues/2499)（地域設定でタイムゾーンが設定されなかった報告）
- [rhinstaller/anaconda](https://github.com/rhinstaller/anaconda) の `rhel-10` ブランチ（既存の ESP の再利用、Windows の検出と `/etc/adjtime`）
- [QEFI Entry Manager](https://github.com/Inokinoki/QEFIEntryManager) / [v0.5.0 の配布物](https://github.com/Inokinoki/QEFIEntryManager/releases/tag/v0.5.0)（Windows の管理者起動、次回だけ別の OS を起動）
  - [GUI の操作](https://github.com/Inokinoki/QEFIEntryManager/blob/v0.5.0/qefientryview.cpp)と [EFI 変数の書き込み](https://github.com/Inokinoki/QEFIEntryManager/blob/v0.5.0/qefientrystaticlist.cpp)（`Set reboot` と `Save` の違い、書き込みの結果を確認していないこと）
  - [CLI のマニュアル](https://github.com/Inokinoki/QEFIEntryManager/blob/v0.5.0/qefibootmgr.8)と [CLI の実装](https://github.com/Inokinoki/QEFIEntryManager/blob/v0.5.0/cli.cpp)、[同梱の qefivar](https://github.com/Inokinoki/qefivar/blob/6e0a29d9267a83cb79c0b4f324e382ba9ffbe1c8/qefi.cpp)（`-v`・`-N`、未設定の `BootNext` を `0000` と表示する不具合）
- [BCDEdit /enum](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--enum) / [BcdBootMgrElementTypes](https://learn.microsoft.com/en-us/previous-versions/windows/desktop/bcd/bcdbootmgrelementtypes)（ファームウェアの一覧、`DisplayOrder` と `BootSequence`）

---
