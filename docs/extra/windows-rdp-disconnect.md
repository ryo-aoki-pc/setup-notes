# Windows 11 のリモートデスクトップを、画面をロックせずに切断する手順（tscon）のロールバックと注意点

[手順書](../windows-rdp-disconnect.md)・[検証記録](../verification/windows-rdp-disconnect.md)・[参考資料](../reference/windows-rdp-disconnect.md)

- 「手順 N」は[手順書](../windows-rdp-disconnect.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- `tscon` は設定を変えないので、戻すものは無い。この節は、[ショートカットで切断する（任意）](../windows-rdp-disconnect.md#ショートカットで切断する任意)のショートカットを消すだけ
- この節は、このユーザーの Windows PowerShell に貼る（管理者でなくてよい）

1. ショートカットを作ったときは、消す。

   ```powershell
   & {
     $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'RDP をロックせずに切断.lnk'
     Remove-Item -LiteralPath $lnk
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Test-Path -LiteralPath $lnk
   }
   ```

   - `False` が出ればよい

---

## 注意点

- **PC の画面はロックされない**: 切った後、PC の前にいる人がこのユーザー（Administrators の一員）として操作できる。ロックするときは、PC の前で Win+L を押す
- **次に RDP でつなぐと、PC の画面はまたロック画面になる**: セッションが RDP へ移るため。切るときは、また本書の手順で切る
- **ふつうに切断してしまったとき**: もう 1 度 RDP でつないでから、本書の手順で切る
- **画面の大きさ**: セッションは PC のモニターの解像度に戻るので、RDP の窓に合わせて並べた窓の位置や大きさが変わることがある
- **モニターの無い PC・蓋を閉じたノート PC**: 蓋を閉じたときの動作は Windows の電源設定に従う。事前にスリープの設定を確かめる
- **クリップボード**: SmartBear の資料は、クリップボードが空でないまま切ると、RDP のクリップボードの共有（`rdpclip.exe`）が失敗することがあると書いている
- **PC の前のセッションでは使わない**: 手順 3 とショートカットは、RDP でつないでいるときのためのもの
