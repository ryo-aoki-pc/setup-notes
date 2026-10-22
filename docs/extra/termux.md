# Termux の注意点

[手順書の「Termux」](../android.md#termux)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux.md)・[参考資料](../reference/termux.md)

- 手順番号は、名前を付けた手順書の項の番号を指す

## 注意点

- Termux とプラグインの入手元（GitHub・F-Droid）を混ぜない。Google Play の Termux は使わない
- `~/.termux/termux.properties` の `allow-external-apps` は、既定の `false` のままにする
- `termux-open` でファイルを Android のアプリへ渡すには、`allow-external-apps = true` が要る。lazygit の `o` や yazi から Android のアプリで開く操作も当たる
- `true` にすると、許可を持つほかのアプリが Termux でコマンドを動かせる。ファイルを渡すためだけに、この設定を変えない
- 開発者向けオプションをオフにすると、[Termux: 強制終了されたとき](../android.md#termux-強制終了されたとき)の手順 2 の「子プロセスの制限を無効化」も戻るという説明がある（[Android-Docs](https://github.com/agnostic-apollo/Android-Docs/blob/master/en/docs/apps/processes/phantom-cached-and-empty-processes.md)。確かめていない）
