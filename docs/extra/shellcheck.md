# ShellCheck と shfmt の注意点

[手順書](../almalinux-setup.md#shellcheck-と-shfmt)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shellcheck.md)・[参考資料](../reference/shellcheck.md)

- 「手順 N」は[手順書](../almalinux-setup.md#shellcheck-と-shfmt)の手順 N、「本書」「この文書」は手順書を指す

## 注意点

- **EPEL 版と brew 版を両方入れない**: どちらもコマンド名は `shellcheck` で、PATH の先頭にある Homebrew 版が勝つ
  - EPEL のパッケージ名だけ大文字の `ShellCheck` なので、`rpm -q shellcheck` では見つからない
- **指摘があると `rc=1`**: CI に組むときはこれが期待どおりだが、`set -e` のスクリプトの途中で呼ぶと止まる
  - `|| true` は終了コードを成功に変える。CI の成否判定が必要なら付けない
- **`sudo shellcheck` は、そのままでは使えない**: sudo の PATH に Homebrew が無い（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）。root で走らせるなら、[AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う)の節を通すか、フルパスか EPEL 版
