# Windows Sandbox で配布物を試す（Windows 11）のロールバックと注意点

[手順書](../virtual-machines.md#windows-sandbox-で配布物を試す)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-sandbox.md)・[参考資料](../reference/windows-sandbox.md)

- 手順書の実施手順は項（###）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## Windows Sandbox を無効にする

- [Windows Sandbox で配布物を試す](../virtual-machines.md#windows-sandbox-で配布物を試す)の手順 2 で控えた `State` が `Disabled` または `DisabledWithPayloadRemoved` で、この手順書で有効にした場合だけ行う。元から `Enabled` だった場合は変更しない
- この節の手順 2〜5 は、管理者の Windows PowerShell（5.1）に貼る
- **再起動**: この節の手順 4 は、状態の確認または無効化が成功し、再起動が必要な場合だけ行う。先に開いているファイルを保存し、実行中の作業を終える
- 対象は `Containers-DisposableClientVM` だけ。Hyper-V・WSL・Virtual Machine Platform など、ほかの機能は外さない

1. Sandbox を閉じ、スタートメニューから管理者の Windows PowerShell を開く。

   - Sandbox の中に残す結果があればホストへコピーしてから、Sandbox の窓を閉じる
   - 「Windows PowerShell」を検索し、右クリック →「管理者として実行」で開き、UAC の確認に答える
   - **次の手順は、管理者の Windows PowerShell が開いてから貼る**

1. 管理者の Windows PowerShell で、Windows Sandbox の現在の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -ErrorAction Stop | Select-Object FeatureName, State
   ```

   - `State` が `Enabled` なら、この節の手順 3 に進む
   - `Disabled` または `DisabledWithPayloadRemoved` なら、この節の手順 3・4 は飛ばす
   - `EnablePending` または `DisablePending` なら、この節の手順 3 は飛ばし、手順 4 で再起動する。再起動したら、この節の手順 2 に戻る
   - エラーや、ここに挙げていない `State` が出たら中断する

1. この手順書で有効にしてまだ有効なときだけ、Windows Sandbox を無効にする。

   ```powershell
   & {
     $feature = Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -ErrorAction Stop
     if ($feature.State -eq 'Enabled') {
       "`n$([char]27)[7m 確認 $([char]27)[0m"
       Disable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -NoRestart -ErrorAction Stop | Select-Object Online, RestartNeeded
       Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -ErrorAction Stop | Select-Object FeatureName, State
     } elseif ($feature.State -in 'Disabled', 'DisabledWithPayloadRemoved') {
       "`n$([char]27)[7m 確認 $([char]27)[0m"
       $feature | Select-Object FeatureName, State
     } else {
       Write-Error '中断: 状態が変わった。この節の手順 2 に戻って確かめる'
     }
   }
   ```

   - エラーが無く、最後の `State` が `Disabled` または `DisablePending` なら無効化できている
   - `RestartNeeded` が `True`、または `State` が `DisablePending` なら、この節の手順 4 で再起動する
   - `RestartNeeded` が `False` で `State` が `Disabled` なら、この節の手順 4 は飛ばす
   - 既に `Disabled` または `DisabledWithPayloadRemoved` だった場合も変更せず、この節の手順 4 は飛ばす
   - エラー・`中断:`・ここに挙げていない結果が出たら、再起動と完了確認へ進まず、この節の手順 2 に戻る

1. 再起動が必要なときだけ、作業を保存してホストを再起動する。

   ```powershell
   Restart-Computer
   ```

   - Windows が起動したらサインインし、この節の手順 1 と同じ管理者の Windows PowerShell を開く
   - この節の手順 2 で `EnablePending` または `DisablePending` だった場合は、同じ手順 2 に戻る
   - **次の手順は、Windows が起動して管理者の Windows PowerShell を開いてから貼る**

1. 管理者の Windows PowerShell で、Windows Sandbox が無効になったことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -ErrorAction Stop | Select-Object FeatureName, State
   ```

   - `State` が `Disabled` または `DisabledWithPayloadRemoved` ならよい
   - エラーや、それ以外の状態なら中断し、この節の手順 2 に戻る

---
