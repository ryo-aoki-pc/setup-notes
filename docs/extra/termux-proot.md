# Termux の proot-distro の注意点

[手順書の「Termux の proot-distro」](../android.md#termux-の-proot-distro)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux-proot.md)・[参考資料](../reference/termux-proot.md)

- 手順番号は、名前を付けた手順書の項の番号を指す

## 注意点

- Ubuntu へ入るときは `proot-distro login --isolated ubuntu` を使う。`--isolated` を付けないと、Termux のホーム・`$PREFIX` と共有のストレージがコンテナにつながる
- 既定のモードでは、コンテナの中から Termux のホームの鍵なども読める。Ubuntu の中で動かすコマンドに、これらのファイルを渡さない
- Ubuntu の中は root。コンテナのファイルを変えられるので、実行するコマンドを確かめる
