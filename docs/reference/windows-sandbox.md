# Windows Sandbox で配布物を試すの参考資料

[手順書](../virtual-machines.md#windows-sandbox-で配布物を試す)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-sandbox.md)

## 補足

### Windows Sandbox で配布物を試す / 手順 2: 補足: 対応環境

- クリーンな Windows で配布物を起動し、開発用 PC に既にあるツールや依存ライブラリに頼っていないかを確かめるため、初期設定の後に、要るときだけ通す項にした
- Microsoft の導入手順は、Windows 11 Pro・Enterprise・Education などの対応エディションを対象とし、Home は対象外としている。AMD64 と、Windows 11 22H2 以降の ARM64 に対応する
- 最低要件は、UEFI / BIOS で有効にした仮想化、RAM 4 GB、ディスクの空き 1 GB、CPU 2 コア。Microsoft は RAM 8 GB、SSD、ハイパースレッディングを含む 4 コアを推奨している
- Windows の VM の中で使う場合は入れ子の仮想化が要る。この項は、前提を満たす PC を対象にしており、VM 側の仮想化設定を変える手順は含めない
- [Microsoft Learn: Install Windows Sandbox](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-install)

### Windows Sandbox で配布物を試す / 手順 3・4: 補足: 変更前の状態と再起動

- `Containers-DisposableClientVM` は Windows Sandbox のオプション機能の名前。`-All` は必要な親機能も有効にし、`-NoRestart` は自動の再起動を止める
- 導入前に `State` を控え、`Disabled` または `DisabledWithPayloadRemoved` の場合だけ有効にする。`Enabled` は変更しない。`EnablePending`・`DisablePending` の場合は再起動してから状態を読み直し、導入前の状態を判定し直す
- 適用後は `RestartNeeded` と機能の `State` を読み、成功を確かめてから、別の手順の `Restart-Computer` で必要な再起動を行う。失敗の後に続けて再起動しない
- [Microsoft Learn: Get-WindowsOptionalFeature](https://learn.microsoft.com/en-us/powershell/module/dism/get-windowsoptionalfeature?view=windowsserver2025-ps)
- [Microsoft Learn: Enable-WindowsOptionalFeature](https://learn.microsoft.com/en-us/powershell/module/dism/enable-windowsoptionalfeature?view=windowsserver2025-ps)

### Windows Sandbox で配布物を試す / 手順 6〜8: 補足: 起動・試験・状態の消去

- Microsoft の起動手順は、スタートメニューで Windows Sandbox を開く形。機能の導入後は、管理者の PowerShell を閉じて通常のデスクトップから起動する
- ホストからコピーした配布物を Sandbox の中で試す。Windows 11 24H2 以降の Sandbox にはメモ帳などの標準アプリが無いため、確認用のフォルダーはエクスプローラーで作る
- Sandbox の窓を閉じると、内部のファイル・インストールしたアプリ・状態が破棄される。次の起動は新しい環境になる。Windows 11 22H2 以降では、Sandbox の中の Windows を再起動した場合は状態が残る
- `.wsb` の `MappedFolders` で共有するホスト側のフォルダーは別に管理される。窓を閉じても、ホスト側に保存したものや共有フォルダーへの変更は消えない
- [Microsoft Learn: Windows Sandbox overview](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-overview)
- [Microsoft Learn: Install Windows Sandbox — Usage](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-install#usage)
- [Microsoft Learn: Windows Sandbox configuration — Mapped folders](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-configure-using-wsb-file#mapped-folders)
