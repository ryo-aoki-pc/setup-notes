# Flatpak / Flathub 導入手順（AlmaLinux 10）の参考資料

[手順書](../flatpak.md)

## 補足

### 実施手順 / 手順 4: 補足: 鍵は登録ファイルの中にある

`flathub.flatpakrepo` は鍵を**本文に base64 で埋め込んで**いて、`flatpak remote-add` はこの鍵をリモートの設定に取り込む。以後の取得はすべてこの鍵で署名を検証する。したがって、確かめるべきは「登録ファイルの中の鍵が Flathub のものか」の 1 点になる（[VS Code](../vscode.md) の手順で rpm の鍵を確かめているのと同じ考え方）。

`gpg --show-keys` は鍵を**鍵束に取り込まずに表示するだけ**。ただし `~/.gnupg` が無ければ最初の実行で作られる（`gpg: directory '/home/<USER>/.gnupg' created`）。

### 参照

---
