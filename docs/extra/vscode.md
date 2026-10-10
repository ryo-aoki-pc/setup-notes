# Visual Studio Code インストール手順（AlmaLinux 10 / Microsoft 公式 dnf リポジトリ）のロールバックと注意点

[手順書](../vscode.md)・[検証記録](../verification/vscode.md)・[参考資料](../reference/vscode.md)

- 「手順 N」は[手順書](../vscode.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

> [!CAUTION]
> **この節の**手順 3 の `rm -rf ~/.config/Code ~/.vscode` は、**VS Code の設定・履歴・拡張機能を消す**。残すなら、この節の手順 3 は貼らない。

1. VS Code を消す。

   ```bash
   sudo dnf remove code
   ```

   - `socat` がほかから使われていなければ、dnf の自動掃除で一緒に消える（クリーンインストールの VM では `code` と `socat` の 2 パッケージだけが消えた）
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. リポジトリのファイルを消す。

   ```bash
   sudo rm -f /etc/yum.repos.d/vscode.repo
   ```

   - Microsoft の署名鍵は `gpg-pubkey-be1229cf-5631588c` として残る（`rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n'` で確認できる）
   - 消すなら `sudo rpm -e gpg-pubkey-be1229cf-5631588c`。**ほかに Microsoft のリポジトリを使っていないことを確かめてから**にする

1. 設定・履歴・拡張機能も消すときだけ、`~/.config/Code` と `~/.vscode` を消す（取り戻せない）。

   ```bash
   rm -rf ~/.config/Code ~/.vscode      # 設定・履歴・拡張機能も消す場合
   ```

---

## 注意点

- **`.el8` のタグに驚かなくてよい**: Microsoft が EL 共通に 1 本だけ出している rpm で、EL10 向けの別ビルドは存在しない。`rpm -qi` の `Vendor` が `Microsoft Corporation` であることを確かめれば十分（[手順 5 の補足](../vscode.md#実施手順)）
- **`~/.config/code-flags.conf` は効かない**: Microsoft の rpm のラッパーは読まない（[手順 6 の補足](../vscode.md#実施手順)）
- 容量が不足する場合は、インストール前にトランザクション表と空き容量を確かめる
- **内蔵のアップデータは使わない**: rpm 版は dnf が管理する。VS Code が更新を促してきても `sudo dnf upgrade code` で上げる
- **`code-insiders` と併存できる**: コマンド名も設定ディレクトリ（`~/.config/Code - Insiders`）も別
- **Electron なので X11 のライブラリを要求する**: `libX11` / `libXcomposite` などが rpm の requires に並ぶ
  - これは XWayland 経由でも動くようにするためで、**ライブラリが入っていることは「X11 で動いている」ことを意味しない**
- **root では起動できない**: ラッパーが `--user-data-dir` の指定を要求する。そもそも root で使うものではない
- **TTY もディスプレイも無いシェルからは GUI を起動できなかった**: デスクトップの端末からは起動する
  - 原因は特定できていない
