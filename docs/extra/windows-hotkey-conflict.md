# Windows 11 でホットキーを使用しているアプリを調べる手順のロールバック

[手順書](../windows-hotkey-conflict.md)・[検証記録](../verification/windows-hotkey-conflict.md)・[参考資料](../reference/windows-hotkey-conflict.md)

- 「手順 N」「本書」は、手順書の実施手順を指す

## ロールバック

- 原因アプリの設定を戻すと、競合も戻る可能性がある

1. 調査で変更した設定を控えた状態へ戻す。

   - キー割り当てとホットキーの有効状態を、アプリの設定画面から戻す
   - 終了した候補アプリを通常起動し、IME・キーボードレイアウトも元に戻す

1. 調査用のツールを終了する。

   - Hotkey Screener と登録可否試験用の PowerShell を閉じる
   - 必要な操作が動くことを確認する

---
