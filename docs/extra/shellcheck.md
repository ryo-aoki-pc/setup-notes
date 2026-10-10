# ShellCheck / shfmt インストール手順（AlmaLinux 10 / Homebrew）のロールバックと注意点

[手順書](../shellcheck.md)・[検証記録](../verification/shellcheck.md)・[参考資料](../reference/shellcheck.md)

- 「手順 N」は[手順書](../shellcheck.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

1. ShellCheck と shfmt を消す。

   ```bash
   brew uninstall shellcheck shfmt
   ```

   - 他の formula が使う依存は残る。不要になった `gmp` / `libffi` などは Homebrew が自動で削除する場合がある（[Homebrew の注意点](almalinux-setup.md#注意点)）。残った不要な依存を整理する操作は `brew autoremove`
   - 設定ファイルは作っていないので、消すものは無い（`.shellcheckrc` や `.editorconfig` を自分で置いた場合はそれを消す）

---

## 注意点

- **`shfmt -w` は元ファイルを上書きする**: git 管理下で、差分を確認できる状態でだけ使う。`-d` で先に差分を見る習慣にしておくと事故らない
- **shfmt の既定はタブ**: `-i` を渡さないと、スペース系のスクリプトは全行が差分になる
  - プロジェクトで揃えるなら `.editorconfig` を置き、コマンドラインでは `-i` を**渡さない**（渡すと `.editorconfig` が無視される）
- **EPEL 版と brew 版を両方入れない**: どちらもコマンド名は `shellcheck` で、PATH の先頭にある Homebrew 版が勝つ
  - EPEL のパッケージ名だけ大文字の `ShellCheck` なので、`rpm -q shellcheck` では見つからない
- **指摘があると `rc=1`**: CI に組むときはこれが期待どおりだが、`set -e` のスクリプトの途中で呼ぶと止まる
  - 件数は[手順 5](../shellcheck.md#実施手順)の JSON と `jq` で数える。`-f quiet` は何も出さず、終了コードだけで成否を確認する形式
  - `|| true` は終了コードを成功に変えるだけで、件数は数えない。CI の成否判定が必要なら付けない
- **`sudo shellcheck` は、そのままでは使えない**: sudo の PATH に Homebrew が無い（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）。root で走らせるなら、[AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通すか、フルパスか EPEL 版
- **コメントの中の `shellcheck` という語がディレクティブと誤認される**: 行末コメントを `# shellcheck -S に渡す…` のように書くと、**SC1126（error）**「Place shellcheck directives before commands, not after.」が出る
  - 本書の手順 1 の行末コメントは、これを踏んだので `shellcheck` を外した書き方に直してある
- **SC2034 は誤検出も出やすい**: 外部から `source` される変数や、`export` せずに使う設定ファイルの変数は「未使用」に見える。個別に潰すならディレクティブ、全体で切るなら `.shellcheckrc`
