# Termux の参考資料

[手順書](../android.md#termux)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux.md)・[注意点](../extra/termux.md)

## 選択した方針

- Termux のネイティブのパッケージ（`pkg`）を標準にし、glibc が要る Claude Code だけ proot-distro の Ubuntu に置く（利用者の決定）
- Neovim の外部コマンドも `pkg` の版を使い、Mason には npm の道具だけを任せる。glibc 向けのバイナリを Termux に入れない
- Termux のまま使う道具は、proot の処理を挟まず、Termux:API のクリップボードも使える。速さの数値比較はしていない

| 方式 | 扱い |
| --- | --- |
| Termux のネイティブのパッケージを標準にする | 採用。シェル・Git・Neovim・Codex CLI を `pkg` で管理し、Termux:API と組み合わせる |
| proot-distro の Ubuntu に全部入れる | 採らない。glibc が要らない道具にも proot の処理が入り、Termux の環境を別に持つ。Claude Code にだけ使う |
| Homebrew を使う | 採らない。`pkg` にある道具を別の管理元に分けず、Termux のパッケージを使う |

## 補足

### Termux / 手順 1: 補足: 署名・入手元・Play プロテクト

- Termux とプラグインは、同じ入手元（GitHub・F-Droid）の APK でそろえる。入手元で署名が違い、混ぜると入らない（[termux-app の README](https://github.com/termux/termux-app#installation)）
- Google Play の Termux は、機能が欠ける試験版（[termux-app の README](https://github.com/termux/termux-app#google-play-store-experimental-branch)）
- Termux は Android 7 以降が対象。Android 17 のエミュレーター（x86_64）で確かめた。実機の aarch64 は確かめていない
- `universal` は、複数の CPU 向けの APK をまとめたもの。エミュレーター（x86_64）でも、この APK で入った
- Termux v0.118.3 の APK の targetSdk は 28。Android 17 の Play プロテクトは「Android の以前のバージョンを対象」としてブロックし、「詳細」の「インストールする」で入った。同じ版の入れ直し（「このアプリを更新しますか？」→「更新」）では止めなかった。Termux:API v0.53.0 も同じだった
- Termux の APK を入れ直すと、開いていたセッションは閉じた。開き直すと新しいセッションになり、ホームのファイル・`~/.termux` の設定・パッケージは残った
- ブラウザから APK を開いたときの提供元の許可の画面は、エミュレーターでは確かめていない（「ファイル」アプリから開いた）

### Termux / Termux: 基本の設定 / 手順 1: 補足: ストレージの場所

- `termux-setup-storage` は、共有のストレージを指すリンクを `~/storage/` に作る。Download は `~/storage/downloads`、共有のストレージ全体は `~/storage/shared`
- `~/storage/shared` にシンボリックリンクは作れなかった。設定リポジトリや開発のファイルは Termux のホームに置く

### Termux / Termux: 基本の設定 / 手順 2・3: 補足: キーの帯とフォント

- `~/.termux/termux.properties` は初回起動時にコメントだけの見本が置かれる。`extra-keys` で、キーの帯を 2 段 8 列にする
- Termux のフォントは `~/.termux/font.ttf` に置く。HackGen Console NF では、starship・eza・lazygit・Neovim の Nerd Fonts の記号が出た

### Termux / Termux: Termux:API を入れる / 手順 1・2: 補足: APK とクリップボード

- Termux:API は Android のアプリと、`pkg` の `termux-api` の両方を使う。アプリの APK は Termux と同じ入手元にそろえる
- Android は、裏で動くアプリのクリップボードの読み取りを止める。Termux が前にあるときは往復でき、ほかのアプリが前にあると `termux-clipboard-get` は空だった
- Termux:API を入れた Termux の画面では、Neovim の標準の Termux 用 provider で、ヤンクした文字を Android のクリップボードに送れた

### Termux / Termux: 強制終了されたとき / 手順 1・2: 補足: Android の設定

- Android 12 以降は、Termux の子プロセスが多いときや CPU を使いすぎたときに、Android が止める（phantom process killer。[termux-app の README](https://github.com/termux/termux-app#readme)）
- Android 14 以降は、開発者向けオプションの「子プロセスの制限を無効化」で止める（[agnostic-apollo の Android-Docs](https://github.com/agnostic-apollo/Android-Docs/blob/master/en/docs/apps/processes/phantom-cached-and-empty-processes.md)）
- Android 17 のエミュレーターで、オンにすると `persist.sys.fflag.override.settings_enable_monitor_phantom_procs` が `false` になることを確かめた
- Android 12L・13 は、PC の adb で `settings put global settings_enable_monitor_phantom_procs false` を実行する（同じ文書。確かめていない）
- Android 12 は、adb で `device_config put activity_manager max_phantom_processes 2147483647` を実行する（同じ文書。確かめていない）
- エミュレーターでは強制終了は起きなかったので、この設定で強制終了が無くなることは確かめていない

## 参照

- [Termux（termux-app）](https://github.com/termux/termux-app)
- [Termux:API（termux-api）](https://github.com/termux/termux-api)
- [Termux のパッケージ（termux-packages）](https://github.com/termux/termux-packages)
- [HackGen](https://github.com/yuru7/HackGen)
- [proot-distro](https://github.com/termux/proot-distro)
- [agnostic-apollo の Android-Docs（phantom process）](https://github.com/agnostic-apollo/Android-Docs/blob/master/en/docs/apps/processes/phantom-cached-and-empty-processes.md)
