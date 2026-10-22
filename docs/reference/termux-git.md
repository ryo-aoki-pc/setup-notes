# Termux の Git の参考資料

[手順書](../android.md#termux-の-git)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux-git.md)・[注意点](../extra/termux.md)

## 選択した方針

- Git の初期設定と試験は AlmaLinux 10 と同じ bash のコマンドを使う。設定の値と試験を一か所で扱い、Termux の版とパスだけを読み替える
- Git・git-delta・GitHub CLI・lazygit は `pkg` の版を使い、lazygit は custom の設定をリンクして使う

## 補足

### Termux の Git / 手順 1: 補足: 共通の Git 設定

- AlmaLinux 10 の「Git」の手順 1〜10 は Termux でも同じコマンドで通った。`mktemp -d` の場所は Termux の `$PREFIX/tmp` になる
- 日本語のファイル名、CRLF、初期ブランチ、push・pull の rebase と autostash の試験を通した。細かな出力は検証記録に置く

### Termux の Git / Termux の Git: GitHub CLI を入れる / 手順 2〜4: 補足: ブラウザでの認証

- GitHub CLI 2.103.0 の `gh auth login` は、接続先・認証の方法・Git の通信の方式・Git の認証の順に聞き、ワンタイムコードを出して Enter を待った
- Enter の後のブラウザの起動と、認証の後の `gh auth status` は確かめていない（ログインはしていない）。ログインの前の `gh auth status` は `You are not logged into any GitHub hosts.` を出した

### Termux の Git / Termux の Git: lazygit の設定を導入する / 手順 2・3: 補足: 設定の場所とファイルを開く操作

- `lazygit --print-config-dir` は `~/.config/lazygit` を返す。custom の `config.yml` をリンクすると、delta の左右の差分が出た
- Termux の `xdg-open` は `termux-open` へのリンク。lazygit の `o` で Android のアプリへファイルを渡すには、`allow-external-apps` の許可が要る（[注意点](../extra/termux.md#注意点)）

## 参照

- [AlmaLinux 10 の「Git」](../almalinux-setup.md#git)
- [git-delta](https://github.com/dandavison/delta)
- [GitHub CLI](https://cli.github.com/)
- [lazygit の custom の設定](https://github.com/ryo-aoki-pc/lazygit)
- [Termux のパッケージ](https://github.com/termux/termux-packages)
