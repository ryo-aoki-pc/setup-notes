# Android のセットアップ

- Android のスマートフォンで、Termux の Firefox（PC 版）を入れて使う
- 検証記録・参考資料・注意点は、各項のリードから開く

> [!IMPORTANT]
> - **前提と実行場所は、各項のリードに従う**。コマンドはスマートフォンの Termux の画面に貼る

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- Termux の新しい画面では、使う項の変数の手順を貼り直す
- 入れたものは、[Termux の Firefox: 更新](#termux-の-firefox-更新)で上げる

## Android で使う

- Termux の Firefox を、Termux:X11 の画面で使う

### Termux の Firefox

- Android のスマートフォンで、Termux のパッケージの PC 版（Linux 向け）の Firefox を、Termux:X11 の画面で使う
- 前提: 無し（Android 8 以降。空きが 2 GB ほど要る）
- 実行場所: スマートフォン。コマンドは Termux の画面に貼る
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux-firefox.md)・[参考資料](reference/termux-firefox.md)・[注意点](extra/termux-firefox.md)
- 画面は Android のエミュレーター（x86_64、Android 17）で撮った。画面内の値は試験用

> [!WARNING]
> Termux の Firefox は、サンドボックスを外してビルドされている（[補足](reference/termux-firefox.md#termux-の-firefox--手順-1-補足-サンドボックスと更新)）。知らないサイトの普段の閲覧には使わず、自分のサイトの確かめなどに使う。

1. スマートフォンで、GitHub のリリースから Termux と Termux:X11 の APK を入れる。

   - Termux は [termux-app のリリース](https://github.com/termux/termux-app/releases)の最新の `termux-app_v<版>+github-debug_universal.apk`
   - Termux:X11 は [nightly](https://github.com/termux/termux-x11/releases/tag/nightly) の `termux-x11-universal-sharedUid-debug.apk`
   - F-Droid の Termux を使っているときは、Termux:X11 は sharedUid の付かない `termux-x11-universal-debug.apk` にする。Google Play の Termux は使わない
   - ダウンロードした APK を開く。提供元の許可を求められたら許可し、「続行」→「インストール」を押す
   - 「Google Play プロテクト」の「安全ではないアプリをブロックしました」が出たら、「詳細」→「インストールする」を押す（2 つとも出る）
   - Termux:X11 の APK を開いて、開くアプリを聞かれたら、「パッケージ インストーラ」（「パッケージ インストーラで開く」）の「1 回のみ」を押す
   - ![Google Play プロテクトの「安全ではないアプリをブロックしました」と「インストールする」](images/android/termux-firefox-play-protect-v0.118.3.png)

1. Termux を開き、パッケージを更新する。

   ```bash
   pkg upgrade -y
   ```

   - 「通知の送信を Termux に許可しますか？」では「許可」を押す
   - 設定ファイルの扱い（`*** openssl.cnf (Y/I/N/O/D/Z) [default=N] ?` など）を何回か聞かれる。どれも Enter（既定の N）を押す
   - **次の手順は、更新が終わって `$` に戻ってから貼る**（続けて貼ると、設定ファイルの扱いへの答えとして読まれる）

1. Termux で、Firefox・Termux:X11 のコマンド・dwm を入れる。

   ```bash
   pkg install -y x11-repo && pkg install -y termux-x11-nightly firefox dwm
   ```

   - 数分かかる。最後に `Setting up firefox (<版>)` などが出て、`$` に戻ればよい

1. Termux で、Firefox を起動する。

   ```bash
   termux-x11 :0 -xstartup "sh -c 'dwm & MOZ_USE_XINPUT2=1 exec firefox'" >/dev/null 2>&1 &
   sleep 3; am start -n com.termux.x11/.MainActivity
   ```

   - Termux:X11 の画面が前に出て、Firefox の「Welcome to Firefox」が開く

1. Termux:X11 の設定で、タッチの方式を Direct touch にする。

   - Termux:X11 の通知 →「Preferences」→「Pointer」→「Touchscreen input mode」→「Direct touch」を選ぶ
   - 戻るボタンで Termux:X11 の画面に戻る
   - ![「Touchscreen input mode」の「Trackpad」「Simulated touchscreen」「Direct touch」](images/android/termux-firefox-x11-touch-mode-v1.03.01.png)

1. Termux:X11 の画面で、Firefox の初めての起動を確かめる。

   - 「Welcome to Firefox」の画面が 5 枚続く。「Skip this step」を押して進め、最後の画面で「Start browsing」を押す
   - 「New Tab」が開けばよい
   - 文字が小さいときは、[Termux の Firefox: 画面の倍率とタッチ](#termux-の-firefox-画面の倍率とタッチ)を通す
   - ![画面いっぱいの Firefox の「Welcome to Firefox」と「Skip this step」](images/android/termux-firefox-first-start-v158.0.1.png)

#### Termux の Firefox: 起動と終了

- Firefox を起動し、メニューから終了する
- 前提: [Termux の Firefox](#termux-の-firefox)を通してある
- 実行場所: スマートフォンの Termux と Termux:X11

1. Termux で、Firefox を起動する。

   ```bash
   termux-x11 :0 -xstartup "sh -c 'dwm & MOZ_USE_XINPUT2=1 exec firefox'" >/dev/null 2>&1 &
   sleep 3; am start -n com.termux.x11/.MainActivity
   ```

   - Termux:X11 の画面が前に出て、Firefox が開く
   - 「Make Firefox your default browser?」が出たら「Not now」を押す
   - ページは 1 本指でなぞってスクロールする（[Termux の Firefox: 画面の倍率とタッチ](#termux-の-firefox-画面の倍率とタッチ)の手順 4）

1. Firefox のメニューで、Firefox を終了する。

   - 右上の「≡」→ いちばん下の「Exit（Ctrl+Q）」を押す
   - Termux:X11 の画面が「Not connected」になればよい
   - 終了にはメニューの「Exit」を使い、`pkill` で止めない
   - ![Firefox の「≡」メニューのいちばん下にある「Exit Ctrl+Q」](images/android/termux-firefox-exit-menu-v158.0.1.png)

#### Termux の Firefox: ホーム画面のアイコンで起動する

- ホーム画面のアイコンから、PC 版の Firefox を倍率 2 倍で起動する。`user.js` に倍率を設定してあるときは、そちらが優先される
- 前提: [Termux の Firefox](#termux-の-firefox)を通してある
- 実行場所: スマートフォンの Termux・Android の設定・ホーム画面
- 画面は Android のエミュレーター（x86_64、Android 17、Termux:Widget v0.15.0）で撮った。画面内の値は試験用

> [!WARNING]
> この項の手順 3 で許可する「他のアプリの上に重ねて表示」は、Termux がほかのアプリの画面に重ねて表示できるようになる権限。要らなくなったら、同じ画面でオフに戻す（[補足](reference/termux-firefox.md#termux-の-firefox-ホーム画面のアイコンで起動する--手順-3-補足-裏からの画面の起動と権限)）。

1. スマートフォンで、GitHub のリリースから Termux:Widget の APK を入れる。

   - [termux-widget のリリース](https://github.com/termux/termux-widget/releases)の `termux-widget-app_v<版>+github.debug.apk` をダウンロードする
   - F-Droid の Termux を使っているときは、F-Droid の Termux:Widget を入れる
   - APK の入れ方は、[Termux の Firefox](#termux-の-firefox)の手順 1 と同じ

1. Termux で、起動のスクリプトとアイコンを置く。

   ```bash
   mkdir -p ~/.shortcuts/tasks ~/.shortcuts/icons
   cat > ~/.shortcuts/tasks/Firefox <<'EOF'
   #!/data/data/com.termux/files/usr/bin/sh
   # ホーム画面のアイコンから、PC 版の Firefox を倍率 2 倍で起動する（setup-notes の docs/android.md）
   if ! pgrep -f 'termux-x11 com.termux.x11 :0' >/dev/null; then
     termux-x11 :0 -xstartup "sh -c 'dwm & MOZ_USE_XINPUT2=1 GDK_SCALE=2 exec firefox'" >/dev/null 2>&1 &
     sleep 3
   fi
   am start -n com.termux.x11/.MainActivity >/dev/null
   EOF
   cp "$PREFIX/share/icons/hicolor/128x128/apps/firefox.png" ~/.shortcuts/icons/Firefox.png
   chmod 700 ~/.shortcuts ~/.shortcuts/tasks ~/.shortcuts/tasks/Firefox
   chmod -R a-x,u=rwX,go-rwx ~/.shortcuts/icons
   printf '\n\033[7m 確認 \033[0m\n'
   ls -l ~/.shortcuts/tasks ~/.shortcuts/icons
   ```

   - `~/.shortcuts/tasks` の `Firefox` が `-rwx------` ならよい
   - `~/.shortcuts/icons` の `Firefox.png` が `-rw-------` ならよい

1. Android の設定で、Termux に「他のアプリの上に重ねて表示」を許可する。

   - 設定 →「アプリ」→「特別なアプリアクセス」→「他のアプリの上に重ねて表示」→「Termux」→「他のアプリの上に重ねて表示できるようにする」をオンにする
   - 「アプリはアクセスを拒否されました」が出たら「閉じる」を押し、設定 →「アプリ」→「Termux」（アプリ情報）→ 右上の「︙」→「制限付き設定を許可」を押す
   - 「制限付き設定を許可」を押した後は、もう一度「他のアプリの上に重ねて表示できるようにする」をオンにする。画面ロックの解除を求められたら解除する
   - 「他のアプリの上に重ねて表示できるようにする」がオンならよい
   - ![Termux の「他のアプリの上に重ねて表示できるようにする」がオンになっている画面](images/android/termux-firefox-overlay-android-17.png)

1. ホーム画面に、Firefox のショートカットを置く。

   - ホーム画面の何も無い所を長押し →「ウィジェット」→ 一覧の「Termux:Widget」の右の矢印を押す
   - 「Termux shortcut」（1 × 1）→「Termux shortcutウィジェットを追加」を押す
   - スクリプトの選択の画面で「tasks/」→「Firefox」を押す
   - Firefox のアイコンと「Firefox 1 × 1」が出たら「ホーム画面に追加」→「ホーム画面に追加」を押す
   - Firefox のロゴに Termux の小さな印が付いた「Firefox」のアイコンがホーム画面にできればよい
   - ![Termux:Widget の Firefox のアイコンと「Firefox 1 × 1」「ホーム画面に追加」](images/android/termux-firefox-widget-add-v0.15.0.png)

1. ホーム画面の Firefox のアイコンを押し、起動を確認する。

   - Firefox を閉じた状態で押す。Termux:X11 の画面に倍率 2 倍の Firefox の「New Tab」が出ればよい（`user.js` に倍率があれば、その値になる）
   - Firefox が既に開いているときは、Termux:X11 の画面が前に出ればよい
   - Termux:X11 の画面が出ないときは、この項の手順 3 の許可を確かめる
   - 終了は、[Termux の Firefox: 起動と終了](#termux-の-firefox-起動と終了)の手順 2 のメニューの「Exit」を使う
   - ![ホーム画面のアイコンの列の右端に、Termux の印が付いた Firefox のロゴの「Firefox」](images/android/termux-firefox-home-icon-v0.15.0.png)

#### Termux の Firefox: 画面の倍率とタッチ

- Firefox の文字の大きさを設定し、タッチとページのスクロールの操作を確かめる
- 前提: [Termux の Firefox](#termux-の-firefox)を通してある
- 実行場所: スマートフォンの Termux と Termux:X11
- この項の手順 2 は、[Termux の Firefox: 起動と終了](#termux-の-firefox-起動と終了)の手順 2 で Firefox を閉じてから貼る

1. Termux で、変数を設定する。

   ```bash
   FF_SCALE='2.0'
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'FF_SCALE=%s\n' "${FF_SCALE}"
   ```

   - `FF_SCALE=2.0` と出ればよい。倍率を変えるときは、この項の手順 1 の値を変える

1. Firefox を閉じてから、Termux で倍率と既定のブラウザの確認を設定する。

   ```bash
   if [ -z "${FF_SCALE}" ]; then echo '中断: FF_SCALE が空のまま' >&2
   elif pgrep -x firefox >/dev/null; then echo '中断: Firefox が開いている。Firefox のメニューの Exit で閉じてから貼り直す' >&2
   else
     p=$(ls -d ~/.config/mozilla/firefox/*.default-default)
     if [ ! -d "$p" ]; then echo '中断: Firefox のプロファイルを 1 つに特定できない' >&2; else
       if [ -f "$p/user.js" ]; then
         sed -i -e '/^[[:space:]]*user_pref("layout\.css\.devPixelsPerPx",/d' -e '/^[[:space:]]*user_pref("browser\.shell\.checkDefaultBrowser",/d' "$p/user.js"
       fi &&
       printf 'user_pref("layout.css.devPixelsPerPx", "%s");\nuser_pref("browser.shell.checkDefaultBrowser", false);\n' "${FF_SCALE}" >> "$p/user.js"
       printf '\n\033[7m 確認 \033[0m\n'
       cat "$p/user.js"
     fi
   fi
   ```

   - `layout.css.devPixelsPerPx` と `browser.shell.checkDefaultBrowser` の行が 1 つずつ出ればよい
   - `中断:` が出たら、Firefox を閉じているかと、この項の手順 1 の値を確かめてから貼り直す

1. Termux:X11 の画面で、Firefox の大きさとタッチの操作を確かめる。

   - [Termux の Firefox: 起動と終了](#termux-の-firefox-起動と終了)の手順 1 で起動する
   - Firefox の文字が読める大きさになり、指で押した場所がクリックになればよい
   - 押した場所と違う所が押されるときは、[Termux の Firefox](#termux-の-firefox)の手順 5 でタッチの方式を Direct touch にする
   - 横向きにすると、広い幅で表示される
   - 画面の下のキーの帯の右側にあるキーボードのボタンで、Android のキーボードを出す。戻るボタンで隠す
   - ![倍率 2.0 の Firefox の「New Tab」](images/android/termux-firefox-scale-v158.0.1.png)

1. Termux:X11 の画面で、タッチ操作でページをスクロールする。

   - ページの上に 1 本指を置き、上へなぞるとページの下へ進み、下へなぞると上へ戻る（スマートフォンのブラウザと同じ）
   - 指を離すと、勢いで少し流れる
   - タップはクリックになり、リンクやボタンを押せる
   - キーの帯で動かすときは、先にページの本文を一度タップする
   - 画面の下のキーの帯の `PGDN` で 1 画面下へ、`PGUP` で 1 画面上へ動く
   - `END` でページのいちばん下へ、`HOME` でいちばん上へ動く
   - `MOZ_USE_XINPUT2=1` を付けずに起動した Firefox で文字が選ばれるときは、[Termux の Firefox: 起動と終了](#termux-の-firefox-起動と終了)の手順 2 で閉じ、同じ項の手順 1 で起動し直す

#### Termux の Firefox: ダークテーマにする

- Firefox の画面と、ダーク表示に対応したサイトを暗い色にする
- 前提: [Termux の Firefox](#termux-の-firefox)を通してある
- 実行場所: スマートフォンの Termux と Termux:X11
- 画面は Android のエミュレーター（x86_64、Android 17、Firefox 158.0.1）で撮った。画面内の値は試験用
- この項の手順 2 は、[Termux の Firefox: 起動と終了](#termux-の-firefox-起動と終了)の手順 2 で Firefox を閉じてから貼る

1. Termux で、変数を設定する。

   ```bash
   FF_DARK='1'
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'FF_DARK=%s\n' "${FF_DARK}"
   ```

   - 暗い表示にするときは `FF_DARK='1'` のままでよい。明るい表示に戻すときは `'0'` に変える
   - `FF_DARK=1`（明るい表示に戻すときは `FF_DARK=0`）と出ればよい

1. Firefox を閉じてから、Termux でダークテーマを設定する。

   ```bash
   if [ -z "${FF_DARK}" ]; then echo '中断: FF_DARK が空のまま' >&2
   elif pgrep -x firefox >/dev/null; then echo '中断: Firefox が開いている。Firefox のメニューの Exit で閉じてから貼り直す' >&2
   else
     p=$(ls -d ~/.config/mozilla/firefox/*.default-default)
     if [ ! -d "$p" ]; then echo '中断: Firefox のプロファイルを 1 つに特定できない' >&2; else
       if [ -f "$p/user.js" ]; then
         sed -i -e '/^[[:space:]]*user_pref("ui\.systemUsesDarkTheme",/d' "$p/user.js"
       fi &&
       printf 'user_pref("ui.systemUsesDarkTheme", %s);\n' "${FF_DARK}" >> "$p/user.js"
       printf '\n\033[7m 確認 \033[0m\n'
       grep 'ui.systemUsesDarkTheme' "$p/user.js"
     fi
   fi
   ```

   - `user_pref("ui.systemUsesDarkTheme", 1);` が 1 行出ればよい（明るい表示に戻すときは `user_pref("ui.systemUsesDarkTheme", 0);`）
   - `中断:` が出たら、Firefox を閉じているかと、この項の手順 1 の値を確かめてから貼り直す
   - 設定の意味は[補足](reference/termux-firefox.md#termux-の-firefox-ダークテーマにする--手順-2-補足-テーマの指定と-userjs)

1. Termux:X11 の画面で、Firefox とサイトの色を確かめる。

   - [Termux の Firefox: 起動と終了](#termux-の-firefox-起動と終了)の手順 1 か、[Termux の Firefox: ホーム画面のアイコンで起動する](#termux-の-firefox-ホーム画面のアイコンで起動する)の手順 5 で起動する
   - Firefox のツールバー・タブ・「New Tab」が暗い色になればよい
   - ダーク表示に対応したサイト（[MDN の日本語版](https://developer.mozilla.org/ja/)など）を開くと、本文まで暗い色になる。対応していないサイトは明るいまま
   - 明るい表示に戻すときは、この項の手順 1 で `FF_DARK='0'` にし、Firefox を閉じてこの項の手順 2 を貼り直してから起動する
   - ![ツールバー・タブ・「New Tab」が暗い色の Firefox](images/android/termux-firefox-dark-v158.0.1.png)

#### Termux の Firefox: 日本語の表示と入力

- 日本語のフォントとページの優先言語を設定し、Gboard で日本語を入力する
- 前提: [Termux の Firefox](#termux-の-firefox)を通してある
- 実行場所: スマートフォンの Termux と Termux:X11
- この項の手順 1 は、[Termux の Firefox: 起動と終了](#termux-の-firefox-起動と終了)の手順 2 で Firefox を閉じてから貼る

1. Firefox を閉じてから、Termux で日本語のフォントと優先言語を設定する。

   ```bash
   if pgrep -x firefox >/dev/null; then echo '中断: Firefox が開いている。Firefox のメニューの Exit で閉じてから貼り直す' >&2; else
     p=$(ls -d ~/.config/mozilla/firefox/*.default-default)
     if [ ! -d "$p" ]; then echo '中断: Firefox のプロファイルを 1 つに特定できない' >&2; else
       pkg install -y otf-noto-sans-cjk &&
       if [ -f "$p/user.js" ]; then
         sed -i -e '/^[[:space:]]*user_pref("intl\.accept_languages",/d' -e '/^[[:space:]]*user_pref("browser\.translations\.automaticallyPopup",/d' "$p/user.js"
       fi &&
       printf 'user_pref("intl.accept_languages", "ja, en-US, en");\nuser_pref("browser.translations.automaticallyPopup", false);\n' >> "$p/user.js"
       printf '\n\033[7m 確認 \033[0m\n'
       cat "$p/user.js"
     fi
   fi
   ```

   - `intl.accept_languages` と `browser.translations.automaticallyPopup` の行が 1 つずつ出ればよい
   - `中断:` が出たら、Firefox を閉じてから貼り直す。プロファイルが見つからないときは、[Termux の Firefox](#termux-の-firefox)の初めての起動まで通してあるか確かめる

1. Termux:X11 の画面で、Firefox に日本語を入力する。

   - [Termux の Firefox: 起動と終了](#termux-の-firefox-起動と終了)の手順 1 で起動する
   - キーの帯のキーボードのボタンで Gboard を出し、日本語（かな）にして、Firefox の入力欄で打って候補を選ぶ
   - 変換中の「にほんご」が入力欄に出て、候補の「日本語」を押すと「日本語」が入ればよい
   - Termux:X11 の「Preferences」→「Keyboard」→「Enforce char based input」はオフのまま使う
   - 日本語のページで翻訳の案内が出ず、日本語が優先されることも確かめる
   - ![Firefox の入力欄の「にほんご」と Gboard の候補の「日本語」](images/android/termux-firefox-ja-input-v158.0.1.png)

#### Termux の Firefox: 音

- Firefox が音声を再生している間の出力先を確かめる
- 前提: [Termux の Firefox](#termux-の-firefox)を通してある
- 実行場所: スマートフォンの Termux と Termux:X11

1. Termux:X11 の画面で、Firefox で音声を再生する。

   - [Termux の Firefox: 起動と終了](#termux-の-firefox-起動と終了)の手順 1 で起動する
   - Firefox で[2 分半の音声ファイル](https://upload.wikimedia.org/wikipedia/commons/9/9d/Bach_-_Cello_Suite_no._1_in_G_major%2C_BWV_1007_-_I._Pr%C3%A9lude.ogg)を開く。再生が始まらなければ、再生のボタンを押す
   - **次の手順は、再生している間に Termux に切り替えて貼る**

1. Firefox で音声を再生している間に、Termux で出力先を確かめる。

   ```bash
   pactl list short sinks
   ```

   - `OpenSL_ES_sink` の行が `RUNNING` ならよい
   - PulseAudio を手で起動する必要はない
   - `RUNNING` なのに音が聞こえないときは、[補足](reference/termux-firefox.md#termux-の-firefox-音--手順-2-補足-pulseaudio-の自動起動)の `module-aaudio-sink` を読む

#### Termux の Firefox: H.264 の動画を再生する

- H.264 の動画を再生する。Firefox は Termux の FFmpeg を読み込んで再生するので、設定の変更は要らない（[補足](reference/termux-firefox.md#termux-の-firefox-h264-の動画を再生する--手順-1-補足-ffmpeg-の読み込みと版)）
- 前提: [Termux の Firefox](#termux-の-firefox)を通してある
- 実行場所: スマートフォンの Termux と Termux:X11
- 画面は Android のエミュレーター（x86_64、Android 17、Firefox 158.0.1）で撮った。画面内の値は試験用

1. Termux で、FFmpeg が入っていることと版を確かめる。

   ```bash
   pkg install -y ffmpeg
   printf '\n\033[7m 確認 \033[0m\n'
   dpkg-query -W -f='${Package} ${Version}\n' firefox ffmpeg
   ls "$PREFIX"/lib/libavcodec.so.*
   ```

   - 「確認」の後に `ffmpeg 9.…` と `firefox 158.…` などの 2 行と、`libavcodec.so.63` などのファイルが出ればよい
   - `libavcodec.so.` の後の数字が、Firefox の読める上限（Firefox 158 では 63）以下ならよい
   - FFmpeg が既に入っていれば、`ffmpeg is already the newest version` と出て、何も入れない

1. Termux:X11 の画面で、H.264 の動画を再生する。

   - [Termux の Firefox: 起動と終了](#termux-の-firefox-起動と終了)の手順 1 か、[Termux の Firefox: ホーム画面のアイコンで起動する](#termux-の-firefox-ホーム画面のアイコンで起動する)の手順 5 で起動する
   - Firefox で[MDN の学習用の動画](https://mdn.github.io/learning-area/html/multimedia-and-embedding/video-and-audio-content/rabbit320.mp4)を開く
   - 白いうさぎの画が出て、最後まで再生されればよい（`0:08 / 0:08`）
   - 再生されないときは、この項の手順 1 で `libavcodec.so` の版を確かめる
   - ![Firefox のタブ「rabbit320.mp4」と白いうさぎの画、再生の帯「0:08 / 0:08」](images/android/termux-firefox-h264-v158.0.1.png)

#### Termux の Firefox: ルート証明書を入れる

- Caddy のルート証明書を、Termux の Firefox のプロファイルに入れる
- 前提: [Termux の Firefox](#termux-の-firefox)を通してあり、ホストの Caddy が HTTPS と `/caddy-root.crt` を公開している
- 実行場所: スマートフォンの Termux と Termux:X11。ホストの指紋は、ホスト側の手順で表示する
- 対象は AlmaLinux 10 のホストの Caddy と、Windows 11 の Codeg 専用の Caddy
- AlmaLinux 10 のホストの指紋は、[Caddy: 端末にルート証明書を入れる](almalinux-setup.md#caddy-端末にルート証明書を入れる)の手順 1 で出して控える
- Windows 11 のホストの指紋は、[Codeg: Windows 11 で端末にルート証明書を入れる](ai-agents.md#codeg-windows-11-で端末にルート証明書を入れる)の手順 1 で出して控える
- この項の手順 3 は、[Termux の Firefox: 起動と終了](#termux-の-firefox-起動と終了)の手順 2 で Firefox を閉じてから貼る

> [!WARNING]
> この項の手順 2 で出した指紋がホストのものと同じでなければ、手順 3 で取り込まない。手順 4 でサイトの証明書の警告が出たら、警告の画面で進まない。

1. Termux で、変数を設定する（`CADDY_URL` は必ず値を入れる）。

   ```bash
   CADDY_URL=''  # ホストの HTTPS の URL を入れる
   ```

   - `https://<SERVER_IP>:<サイトのポート>` を入れる。Codeg は `https://<SERVER_IP>:3443` にする

1. Termux で、ルート証明書を取得し、名前・期限・指紋を表示する。

   ```bash
   if [ -z "${CADDY_URL}" ]; then echo '中断: CADDY_URL が空のまま' >&2; else
     pkg install -y nss-utils openssl-tool &&
     curl -sSkf -o ~/caddy-root.crt "${CADDY_URL}/caddy-root.crt" && {
       printf '\n\033[7m 確認 \033[0m\n'
       openssl x509 -in ~/caddy-root.crt -noout -subject -enddate -fingerprint -sha256
     }
   fi
   ```

   - `subject=`・`notAfter=`・`sha256 Fingerprint=` が出ればよい
   - ホスト側で控えた SHA-256 の指紋と同じなら、この項の手順 3 へ進む。違えば取り込まない
   - `curl:` で始まる行が出て「確認」が出ないときは、`CADDY_URL` とつながる道（WireGuard など）を確かめてから貼り直す

1. Firefox を閉じてから、Termux でルート証明書を取り込む。

   ```bash
   if pgrep -x firefox >/dev/null; then echo '中断: Firefox が開いている。Firefox のメニューの Exit で閉じてから貼り直す' >&2; else
     p=$(ls -d ~/.config/mozilla/firefox/*.default-default)
     n=$(openssl x509 -in ~/caddy-root.crt -noout -subject -nameopt multiline | sed -n 's/^ *commonName *= //p')
     if [ ! -d "$p" ]; then echo '中断: Firefox のプロファイルを 1 つに特定できない' >&2
     elif [ -z "$n" ]; then echo '中断: ルート証明書から名前を取れない。この項の手順 2 を貼り直す' >&2
     else
       certutil -A -d "sql:$p" -n "$n" -t 'C,,' -i ~/caddy-root.crt
       printf '\n\033[7m 確認 \033[0m\n'
       certutil -L -d "sql:$p"
     fi
   fi
   ```

   - 入れたルート証明書の名前と `C,,` が出ればよい
   - `中断:` が出たら、その内容に従って直してから貼り直す

1. Firefox を起動し、通常のタブでサイトを開いて確かめる。

   - [Termux の Firefox: 起動と終了](#termux-の-firefox-起動と終了)の手順 1 で起動する
   - 通常のタブで、この項の手順 1 の URL を開く。Codeg は `https://<SERVER_IP>:3443/api/` を開く
   - 証明書の警告が出ずにサイトが開けばよい。Codeg はログインの画面（アクセストークンの入力欄）になる
   - 12 時間以上たってから、もう一度通常のタブで開き、警告が出ないことを確かめる
   - 警告が出たら進まず、この項の手順 2 の指紋から確かめ直す

#### Termux の Firefox: 強制終了されたとき

- `[Process completed (signal 9) - press Enter]` が出て Firefox が落ちたときだけ、Android の設定を変える
- 前提: [Termux の Firefox](#termux-の-firefox)を通してある
- 実行場所: スマートフォンの Android の設定

1. Android の設定で、Android のバージョンを確かめる。

   - 設定の「デバイス情報」（エミュレーターでは「エミュレートされたデバイスについて」）で Android のバージョンを確かめる
   - Android 14 以降なら、この項の手順 2 へ進む
   - Android 12・12L・13 はこの項の手順 2 を飛ばし、[補足](reference/termux-firefox.md#termux-の-firefox-強制終了されたとき--手順-12-補足-android-の設定)の方法を使う

1. Android 14 以降のときだけ、開発者向けオプションで子プロセスの制限を無効化する。

   - 「開発者向けオプション」が無いときは、設定の「デバイス情報」のいちばん下の「ビルド番号」を 7 回押す
   - 設定 →「システム」→ いちばん下の「開発者向けオプション」→「子プロセスの制限を無効化」をオンにする
   - 「子プロセスの制限を無効化」がオンになればよい
   - ![Android 17 の開発者向けオプションで「子プロセスの制限を無効化」がオンになっている画面](images/android/termux-firefox-child-process-android-17.png)

#### Termux の Firefox: 更新

- Termux のパッケージと、Termux:X11・Termux:Widget の APK を更新する
- 前提: [Termux の Firefox](#termux-の-firefox)を通してある
- 実行場所: スマートフォンの Termux と Android の画面

1. Termux で、パッケージを更新する。

   ```bash
   pkg upgrade -y
   ```

   - 設定ファイルの扱いを聞かれたら Enter を押す
   - Firefox もこのコマンドで更新する
   - **次の手順は、更新が終わって `$` に戻ってから行う**

1. スマートフォンで、Termux:X11 の nightly の APK を入れ直して更新する。

   - GitHub の nightly から `termux-x11-universal-sharedUid-debug.apk` をダウンロードして開く
   - 「このアプリを更新しますか？」→「更新」を押す
   - 「アプリを更新しました」と出ればよい

1. Termux:Widget を入れているときは、スマートフォンで APK を入れ直して更新する。

   - [termux-widget のリリース](https://github.com/termux/termux-widget/releases)から `termux-widget-app_v<版>+github.debug.apk` をダウンロードして開く
   - F-Droid の Termux を使っているときは、F-Droid の Termux:Widget を入れる
   - 「このアプリを更新しますか？」→「更新」を押す
   - 「アプリを更新しました」と出ればよい

---
