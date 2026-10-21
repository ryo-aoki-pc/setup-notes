# Termux の Firefox の参考資料

[手順書](../android.md#termux-の-firefox)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux-firefox.md)・[注意点](../extra/termux-firefox.md)

## 選択した方針

- Android のスマートフォンで PC 版（Linux 向け）の Firefox を使う方式のうち、Termux のネイティブの `firefox` を Termux:X11 に出す方式 A だけを扱う（利用者の決定）
- dwm を組み合わせ、Firefox の窓を画面いっぱいに広げる。dwm は設定ファイルが要らず、1 つの窓を画面いっぱいにし、横向きにすると窓を広げ直す

| 方式 | 扱い |
| --- | --- |
| A: Termux のネイティブの Firefox と Termux:X11 | 採用。proot を挟まず、Termux のパッケージの Firefox をそのまま使う |
| B: Termux の proot-distro の Debian に `firefox-esr` を入れる | 採らない。Debian の環境を 1 つ余分に持ち、proot を挟む分だけ重い。proot-distro は中の環境に `MOZ_FAKE_NO_SANDBOX=1` を入れるので、サンドボックスが効かないのは A と同じ |
| C: Firefox for Android の「デスクトップ版サイト」 | 採らない。中身は Android 版の Firefox のままで、PC 版の画面・拡張機能にはならない。自分の認証局のルート証明書も、利用者の Android の Firefox では信頼されなかった（[Caddy の補足](caddy.md#caddy-端末にルート証明書を入れる--手順-25-補足-android-のブラウザと警告の許可)） |
| D: PC の Firefox を RDP で使う | 採らない。PC が動いていることが要り、スマートフォンの中では動かない |

## 補足

### Termux の Firefox / 手順 1: 補足: サンドボックスと更新

- termux-packages の `x11-packages/firefox/mozconfig.cfg` は、`--disable-sandbox`・`--disable-hardening`・`--disable-updater` を付けてビルドしている（[mozconfig.cfg](https://github.com/termux/termux-packages/blob/master/x11-packages/firefox/mozconfig.cfg)）
- サンドボックスが無いので、ページを描く処理が破られたときに、Termux のファイル（ホームの鍵など）まで届くおそれがある。知らないサイトの普段の閲覧には使わない
- 自分で更新する仕組みも外してあるので、Firefox は Termux の `pkg upgrade` で上げる

### Termux の Firefox / 手順 1: 補足: 署名・入手元・Play プロテクト

- Termux とプラグインは、同じ入手元（GitHub・F-Droid）の APK でそろえる。入手元で署名が違い、混ぜると入らない（[termux-app の README](https://github.com/termux/termux-app#installation)）
- Termux:X11 の sharedUid 版は Termux と同じプロセスの扱いになり、Android が Termux を遅くするのを避けられる。GitHub の Termux でだけ使える（[Termux:X11 の README](https://github.com/termux/termux-x11#setup-instructions)）。F-Droid の Termux と通常版の組み合わせは確かめていない
- Google Play の Termux は、機能が欠ける試験版（[termux-app の README](https://github.com/termux/termux-app#google-play-store-experimental-branch)）
- Termux は Android 7 以降、Termux:X11 は Android 8 以降（各 README）。エミュレーターの Android 17 でだけ確かめた
- `universal` の APK は、どの CPU でも動く。エミュレーターでは x86_64 の APK でも通した
- どちらの APK も targetSdk は 28。Android 17 の Play プロテクトは「Android の以前のバージョンを対象」としてブロックし、「詳細」の「インストールする」で入った。入れ直し（更新）では止めなかった
- ブラウザから APK を開いたときの提供元の許可の画面は、エミュレーターでは確かめていない（「ファイル」アプリから開いた）

### Termux の Firefox / 手順 3〜5: 補足: dwm と Firefox の画面

- ウィンドウマネージャー無しでは、Firefox の窓が画面の左上の一部にしか広がらなかった。dwm を使うと画面いっぱいになり、上に dwm の細い帯が出る
- 導入の後の Termux の中（`$PREFIX`）は 1.5 GB ほどだった（Firefox の依存の mesa・llvm・gtk3 などを含む）
- Termux の Firefox の画面は英語。ページの日本語の表示と、Firefox のメニューの言語は別

### Termux の Firefox: 起動と終了 / 手順 1・2: 補足: 起動と終了の仕組み

- `-xstartup` で dwm を裏で動かし、Firefox を `exec` で動かす。Firefox が閉じると `-xstartup` が終わり、`termux-x11` と dwm も止まる。Termux:X11 の画面は「Not connected」になる
- `am start` は Termux:X11 の画面を前に出す
- `pkill -f termux-x11` で止めた後は、次の起動で Firefox が「Restore Session」を出した

### Termux の Firefox: 画面の倍率とタッチ / 手順 1・2: 補足: プロファイルと user.js

- Firefox 158 のプロファイルは、初めての起動の後に `~/.config/mozilla/firefox/<ランダム>.default-default` にできる。`installs.ini` の `Default=` がその場所を指す
- `profiles.ini` には、使われない `<ランダム>.default` も載る。設定先は `*.default-default` にする
- `user.js` は起動のたびに読まれ、`prefs.js` に写る。`layout.css.devPixelsPerPx` の `2.0` は、縦向きで 540、横向きで 1200 の CSS の画素の幅になる
- `browser.shell.checkDefaultBrowser` を `false` にすると、起動時の「Make Firefox your default browser?」が出なくなる

### Termux の Firefox: 画面の倍率とタッチ / 手順 3・4: 補足: タッチと画面の向き

- Termux:X11 の「Touchscreen input mode」は「Trackpad」が既定。「Direct touch」にすると、指で押した場所がそのままクリックになる
- 「Output」の「Display resolution mode」は `native`、「Screen orientation」は `auto` が既定。手順ではこの 2 つを変えない

### Termux の Firefox: 日本語の表示と入力 / 手順 1: 補足: フォントと言語

- Termux の `$PREFIX/etc/fonts/fonts.conf` は `/system/fonts` も読む。エミュレーターでは、Android の `NotoSansCJK-Regular.ttc` で、フォントを入れる前から日本語が出た。機種によって中身が違うので、手順では `otf-noto-sans-cjk` を入れる
- `intl.accept_languages` を `ja, en-US, en` にすると、サイトが日本語を優先する。`browser.translations.automaticallyPopup` を `false` にすると、日本語のページで翻訳の案内が出なくなる（Firefox の画面が英語なので、無いと日本語のページのたびに出た）

### Termux の Firefox: 日本語の表示と入力 / 手順 2: 補足: IME の仕組み

- Termux:X11 は、IME の変換中の文字を、文字と Backspace で X に送る（[LorieView.java](https://github.com/termux/termux-x11/blob/master/lorie/src/main/java/com/termux/x11/LorieView.java)）。Linux の側に日本語の IME は要らない
- Termux のパッケージには、Linux の側の日本語の IME（fcitx5 の mozc・anthy）が無い
- 「Enforce char based input」の説明は「Suppresses suggestions, predictive typing and CJK languages」。既定はオフで、手順もオフのままにする

### Termux の Firefox: 音 / 手順 1: 補足: PulseAudio の自動起動

- PulseAudio は Firefox の依存で入る。Termux の既定の設定は、Android に音を出す `module-sles-sink` を読む
- 音声のファイルを開くと、Firefox が `pulseaudio --start --log-target=syslog` で自動で起動した
- エミュレーターでは、耳で音を聞いていない。出力先の `RUNNING` と、`Firefox Web Browser` の入力を確かめた

### Termux の Firefox: ルート証明書を入れる / 手順 1〜4: 補足: 取り込み先と確認の範囲

- PC 版の Firefox は、Android の「信頼できる認証情報」ではなく、プロファイルの証明書の保管場所（`cert9.db`）を使う。そこへ `certutil` で取り込む
- `openssl` のコマンドは最初は無い（`pkg install openssl-tool` を勧める表示が出る）。`certutil` は `nss-utils` に入っている
- 証明書の名前はルート証明書の commonName から取り、信頼の指定を `C,,`（Web サイトの識別に使う認証局）にする
- Windows 11 の Codeg 専用の Caddy で、ホストと指紋を照合してから取り込み、警告の画面で進まずに `/api/` からログインの画面が開くところまで確かめた
- AlmaLinux 10 のホストの Caddy と、取り込んでから 12 時間以上たった後は、確かめていない

### Termux の Firefox: 強制終了されたとき / 手順 1・2: 補足: Android の設定

- Android 12 以降は、Termux の子プロセスが多いときや CPU を使いすぎたときに、Android が止める（phantom process killer。[termux-app の README](https://github.com/termux/termux-app#readme)）
- Android 14 以降は、開発者向けオプションの「子プロセスの制限を無効化」で止める（[agnostic-apollo の Android-Docs](https://github.com/agnostic-apollo/Android-Docs/blob/master/en/docs/apps/processes/phantom-cached-and-empty-processes.md)）。Android 17 のエミュレーターで、オンにすると `persist.sys.fflag.override.settings_enable_monitor_phantom_procs` が `false` になることを確かめた
- Android 12L・13 は、PC の adb で `settings put global settings_enable_monitor_phantom_procs false` を実行する（同じ文書。確かめていない）
- Android 12 は、adb で `device_config put activity_manager max_phantom_processes 2147483647` を実行する（同じ文書。確かめていない）
- エミュレーターでは強制終了は起きなかったので、この設定で強制終了が無くなることは確かめていない

## 参照

- [Termux（termux-app）](https://github.com/termux/termux-app)
- [Termux:X11](https://github.com/termux/termux-x11)
- [termux-packages の Firefox](https://github.com/termux/termux-packages/tree/master/x11-packages/firefox)
- [proot-distro](https://github.com/termux/proot-distro)
- [agnostic-apollo の Android-Docs（phantom process）](https://github.com/agnostic-apollo/Android-Docs/blob/master/en/docs/apps/processes/phantom-cached-and-empty-processes.md)
- [音声の確かめに使う Example.ogg](https://upload.wikimedia.org/wikipedia/commons/c/c8/Example.ogg)
- [AlmaLinux 10 の「Caddy: 端末にルート証明書を入れる」](../almalinux-setup.md#caddy-端末にルート証明書を入れる)
- [Codeg: Windows 11 で端末にルート証明書を入れる](../ai-agents.md#codeg-windows-11-で端末にルート証明書を入れる)
