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

### Termux の Firefox / 手順 3・4・6: 補足: dwm と Firefox の画面

- ウィンドウマネージャー無しでは、Firefox の窓が画面の左上の一部にしか広がらなかった。dwm を使うと画面いっぱいになり、上に dwm の細い帯が出る
- 導入の後の Termux の中（`$PREFIX`）は 1.5 GB ほどだった（Firefox の依存の mesa・llvm・gtk3 などを含む）
- Termux の Firefox の画面は英語。ページの日本語の表示と、Firefox のメニューの言語は別

### Termux の Firefox: 起動と終了 / 手順 1・2: 補足: 起動と終了の仕組み

- `-xstartup` で dwm を裏で動かし、Firefox を `exec` で動かす。Firefox が閉じると `-xstartup` が終わり、`termux-x11` と dwm も止まる。Termux:X11 の画面は「Not connected」になる
- `am start` は Termux:X11 の画面を前に出す
- `pkill -f termux-x11` で止めた後は、次の起動で Firefox が「Restore Session」を出した

### Termux の Firefox: ホーム画面のアイコンで起動する / 手順 2: 補足: スクリプトとアイコン

- Termux:Widget は、`~/.shortcuts/` のスクリプトをターミナルの画面で、`~/.shortcuts/tasks/` のスクリプトを裏で動かす。ホーム画面のアイコンには、裏で動かす `~/.shortcuts/tasks/Firefox` を使う
- アイコンは `~/.shortcuts/icons/<スクリプトの名前>.png` に置く。`Firefox` には `Firefox.png` を使う。termux-widget の README は、フォルダーを `0700`、アイコンを `0600` にすることを勧めている
- `termux-x11` の実際のプロセスの名前は `termux-x11 com.termux.x11 :0 -xstartup …`。`$PREFIX/bin/termux-x11` が `--nice-name="termux-x11 com.termux.x11 $*"` を付けて起動する
- `pgrep -f 'termux-x11 com.termux.x11 :0'` で既に動いているかを見分け、動いていれば 2 つ目を起動せず、`am start` で Termux:X11 の画面を前に出す

### Termux の Firefox: ホーム画面のアイコンで起動する / 手順 2: 補足: 倍率の優先

- `user.js` に `layout.css.devPixelsPerPx` が無いときは、`GDK_SCALE=2` で倍率 2 倍になる
- `user.js` に `layout.css.devPixelsPerPx` があるときは、その値が優先される。`2.0` と `GDK_SCALE=2` を併用しても 4 倍にはならず、2 倍のまま
- Firefox は一度使った倍率を `prefs.js` にも残す。`user.js` の行を消しただけでは前の倍率が残るので、`GDK_SCALE=2` だけで確かめるときは `prefs.js` の行も消した
- [手順書の「Termux の Firefox: ホーム画面のアイコンで起動する」の手順 2](../android.md#termux-の-firefox-ホーム画面のアイコンで起動する)のスクリプト（`MOZ_USE_XINPUT2=1 GDK_SCALE=2`）で、`user.js`・`prefs.js` に倍率が無い状態からホーム画面のアイコンで起動すると、倍率 2 倍で開き、1 本指でスクロールできた

### Termux の Firefox: ホーム画面のアイコンで起動する / 手順 3: 補足: 裏からの画面の起動と権限

- Android は、裏で動くアプリから画面を出すことを止める。アイコンを押しても、X サーバーと Firefox が裏で起動するだけで、Termux:X11 の画面が出ないことがある
- Termux に「他のアプリの上に重ねて表示」を許可すると、この制限の例外になる。許可前のログは `Background activity launch blocked! … callingPackage: com.termux`、許可後は `BAL_ALLOW_SAW_PERMISSION` だった
- Android 17 では、最初は「アプリはアクセスを拒否されました」と出て、権限をオンにできなかった。Termux のアプリ情報で「制限付き設定を許可」を押すと、オンにできた
- エミュレーターには画面ロックが無く、解除の確認は出なかった。画面ロックのある端末では、解除を求められることがある

### Termux の Firefox: 画面の倍率とタッチ / 手順 1・2: 補足: プロファイルと user.js

- Firefox 158 のプロファイルは、初めての起動の後に `~/.config/mozilla/firefox/<ランダム>.default-default` にできる。`installs.ini` の `Default=` がその場所を指す
- `profiles.ini` には、使われない `<ランダム>.default` も載る。設定先は `*.default-default` にする
- `user.js` は起動のたびに読まれ、`prefs.js` に写る。`layout.css.devPixelsPerPx` の `2.0` は、縦向きで 540、横向きで 1200 の CSS の画素の幅になる
- `browser.shell.checkDefaultBrowser` を `false` にすると、起動時の「Make Firefox your default browser?」が出なくなる

### Termux の Firefox / 手順 5: 補足: タッチの方式

- Termux:X11 の「Touchscreen input mode」は「Trackpad」が既定。画面をタッチパッドとして使うので、押した場所ではなく、ポインターのある場所が押される（初めての起動で、「Skip this step」が押せなかった）
- 「Direct touch」にすると、指で押した場所がそのままクリックになる

### Termux の Firefox: 画面の倍率とタッチ / 手順 3: 補足: 画面の向き

- 「Output」の「Display resolution mode」は `native`、「Screen orientation」は `auto` が既定。手順ではこの 2 つを変えない
- 横向きにすると、dwm が窓を広げ直し、倍率 2.0 で 1200 の CSS の画素の幅になった（Wikipedia が横のメニュー付きの形で出た）

### Termux の Firefox: 画面の倍率とタッチ / 手順 4: 補足: XInput2 とスクロール

- `MOZ_USE_XINPUT2=1` は、Firefox に X の XInput2（タッチの入力）を使わせる環境変数。付けずに Direct touch で 1 本指を上下になぞると、マウスのドラッグとして扱われ、文字が選ばれた
- `MOZ_USE_XINPUT2=1` を付けると、1 本指でスクロールでき、指を離した後も勢いで少し流れた。タップでのリンクの移動と、ツールバーの「≡」のメニューも使えた
- 2 本指の操作は、エミュレーターで作れないので確かめていない

### Termux の Firefox: ダークテーマにする / 手順 2: 補足: テーマの指定と user.js

- `ui.systemUsesDarkTheme` は、Firefox にシステムのテーマの明暗を指定する設定。`1` で暗い表示、`0` で明るい表示にする
- Firefox のテーマは既定の `default-theme@mozilla.org`（システムに合わせる）。Termux:X11 の中には GTK の暗いテーマが無く、そのままでは明るい表示になる
- `ui.systemUsesDarkTheme` は `prefs.js` にも残る。`user.js` の値が起動のたびに `prefs.js` を上書きするので、明るい表示に戻すときは `user.js` の値を `0` にする

### Termux の Firefox: ダークテーマにする / 手順 3: 補足: サイトの表示と確認の範囲

- 確かめたサイトは、[MDN の日本語版](https://developer.mozilla.org/ja/)と日本語の Wikipedia
- MDN はダーク表示（`prefers-color-scheme`）に対応し、本文まで暗い色になった
- 日本語の Wikipedia は、既定の表示では明るいままだった
- `0` に戻して起動すると、「New Tab」は明るい表示に戻り、MDN の本文も白に戻った

### Termux の Firefox: 日本語の表示と入力 / 手順 1: 補足: フォントと言語

- Termux の `$PREFIX/etc/fonts/fonts.conf` は `/system/fonts` も読む。エミュレーターでは、Android の `NotoSansCJK-Regular.ttc` で、フォントを入れる前から日本語が出た。機種によって中身が違うので、手順では `otf-noto-sans-cjk` を入れる
- `intl.accept_languages` を `ja, en-US, en` にすると、サイトが日本語を優先する。`browser.translations.automaticallyPopup` を `false` にすると、日本語のページで翻訳の案内が出なくなる（Firefox の画面が英語なので、無いと日本語のページのたびに出た）

### Termux の Firefox: 日本語の表示と入力 / 手順 2: 補足: IME の仕組み

- Termux:X11 は、IME の変換中の文字を、文字と Backspace で X に送る（[LorieView.java](https://github.com/termux/termux-x11/blob/master/lorie/src/main/java/com/termux/x11/LorieView.java)）。Linux の側に日本語の IME は要らない
- Termux のパッケージには、Linux の側の日本語の IME（fcitx5 の mozc・anthy）が無い
- 「Enforce char based input」の説明は「Suppresses suggestions, predictive typing and CJK languages」。既定はオフで、手順もオフのままにする

### Termux の Firefox: 音 / 手順 2: 補足: PulseAudio の自動起動

- PulseAudio は Firefox の依存で入る。Termux の既定の設定は、Android に音を出す `module-sles-sink` を読む
- `pulseaudio` のパッケージは、入れるときに「Android 8 以降で音が出ないときは、`$PREFIX/etc/pulse/default.pa` の `module-sles-sink` を `module-aaudio-sink` に変える」と案内する。エミュレーターでは、変えずに `RUNNING` になった（変えた形は確かめていない）
- 音声のファイルを開くと、Firefox が `pulseaudio --start --log-target=syslog` で自動で起動した
- エミュレーターでは、耳で音を聞いていない。出力先の `RUNNING` と、`Firefox Web Browser` の入力を確かめた
- 6 秒の音声では、Termux に切り替えて貼る間に再生が終わり、`IDLE` になった。手順では 2 分半の音声を使う。Termux:X11 が裏に回っても、再生は続いた

### Termux の Firefox: H.264 の動画を再生する / 手順 1: 補足: FFmpeg の読み込みと版

- Linux の Firefox は、H.264 の復号の仕組みを持たず、システムの FFmpeg（`libavcodec`）を `dlopen` で読み込む
- Termux の `firefox` は、依存で `ffmpeg` を入れる。termux-packages の `x11-packages/firefox/build.sh` は、FFmpeg と PulseAudio が `dlopen` を通した依存であると記している
- そのため、手順 1 の `pkg install -y ffmpeg` は、ふつう何も入れず（`ffmpeg is already the newest version`）、`ffmpeg` を手で入れたものとして記録するだけになる（`ffmpeg set to manually installed.`。`apt autoremove` の対象にならない）
- Firefox 158 の `FFmpegLibWrapper.h` では、`FFMPEG_MAX_MAJOR_VERSION` が `63`。Firefox 158 が読めるのは libavcodec 63（FFmpeg 9）まで
- `FFmpegRuntimeLinker.cpp` は、`libavcodec.so.63` から `libavcodec.so.53` まで順に探す
- 確かめたときの版は Firefox 158.0.1 と FFmpeg 9.0.2
- `$PREFIX/lib` に `libavcodec.so.63`（`libavcodec.so.63.1.102`）・`libavformat.so.63`・`libavutil.so.61` があり、`libx264` も入っていた

### Termux の Firefox: H.264 の動画を再生する / 手順 2: 補足: 動画の形式と確認の範囲

- [MDN の学習用の動画](https://mdn.github.io/learning-area/html/multimedia-and-embedding/video-and-audio-content/rabbit320.mp4)は、`ffprobe` で H.264 の Constrained Baseline（320 × 240）と AAC LC、7.8 秒だった
- Android 17 のエミュレーター（x86_64）で開くと、設定を変えずに再生が自動で始まり、白いうさぎの画が出て、最後まで再生された（`0:08 / 0:08`）
- 再生時は、Firefox の復号のプロセス（RDD・utility）と本体の `/proc/<pid>/maps` で、`libavcodec.so.63.1.102` の読み込みを確かめた
- PulseAudio の入力に `Firefox Web Browser` が出た
- 実機での H.264 の再生・ハードウェアの復号・YouTube などのサイトの動画・FFmpeg 10 以降（libavcodec 64 以降）に上がったときは、確かめていない

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

### Termux の Firefox: 更新 / 手順 3: 補足: Termux:Widget の更新

- Termux:Widget の更新は確かめていない

## 参照

- [Termux（termux-app）](https://github.com/termux/termux-app)
- [Termux:X11](https://github.com/termux/termux-x11)
- [Termux:Widget（termux-widget）](https://github.com/termux/termux-widget)
- [termux-packages の Firefox](https://github.com/termux/termux-packages/tree/master/x11-packages/firefox)
- [Firefox の FFmpegLibWrapper.h](https://github.com/mozilla-firefox/firefox/blob/main/dom/media/platforms/ffmpeg/FFmpegLibWrapper.h)
- [proot-distro](https://github.com/termux/proot-distro)
- [agnostic-apollo の Android-Docs（phantom process）](https://github.com/agnostic-apollo/Android-Docs/blob/master/en/docs/apps/processes/phantom-cached-and-empty-processes.md)
- [音声の確かめに使うファイル（Wikimedia Commons、2 分 30 秒）](https://commons.wikimedia.org/wiki/File:Bach_-_Cello_Suite_no._1_in_G_major,_BWV_1007_-_I._Pr%C3%A9lude.ogg)
- [AlmaLinux 10 の「Caddy: 端末にルート証明書を入れる」](../almalinux-setup.md#caddy-端末にルート証明書を入れる)
- [Codeg: Windows 11 で端末にルート証明書を入れる](../ai-agents.md#codeg-windows-11-で端末にルート証明書を入れる)
