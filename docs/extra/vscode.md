# VS Code の注意点

[手順書](../almalinux-setup.md#vs-code)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/vscode.md)・[参考資料](../reference/vscode.md)

- 「手順 N」は[手順書](../almalinux-setup.md#vs-code)の手順 N、「本書」「この文書」は手順書を指す

## 注意点

- **`.el8` のタグに驚かなくてよい**: Microsoft が EL 共通に 1 本だけ出している rpm で、EL10 向けの別ビルドは存在しない。`rpm -qi` の `Vendor` が `Microsoft Corporation` であることを確かめれば十分（[手順 5 の補足](../almalinux-setup.md#vs-code)）
- **`~/.config/code-flags.conf` は効かない**: Microsoft の rpm のラッパーは読まない（[手順 6 の補足](../almalinux-setup.md#vs-code)）
- 容量が不足する場合は、インストール前にトランザクション表と空き容量を確かめる
- **内蔵のアップデータは使わない**: rpm 版は dnf が管理する。VS Code が更新を促してきても `sudo dnf upgrade code` で上げる
- **`code-insiders` と併存できる**: コマンド名も設定ディレクトリ（`~/.config/Code - Insiders`）も別
- **Electron なので X11 のライブラリを要求する**: `libX11` / `libXcomposite` などが rpm の requires に並ぶ
  - これは XWayland 経由でも動くようにするためで、**ライブラリが入っていることは「X11 で動いている」ことを意味しない**
- **root では起動できない**: ラッパーが `--user-data-dir` の指定を要求する。そもそも root で使うものではない
- **TTY もディスプレイも無いシェルからは GUI を起動できなかった**: デスクトップの端末からは起動する
  - 原因は特定できていない
