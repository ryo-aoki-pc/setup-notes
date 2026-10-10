# Firefox 最新版インストール手順（AlmaLinux 10 は Mozilla 公式 RPM リポジトリ / Windows 11 は winget）

## 実施手順

- [検証記録](verification/firefox.md)・[参考資料](reference/firefox.md)・[ロールバックと注意点](extra/firefox.md)

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（管理者の Windows PowerShell 5.1 に貼る。AAC・H.264 のための手順 8〜11 に当たる手順は無い）
> - **前提（手順 8 から）**: [AlmaLinux 10 の初期設定の手順 18〜21](almalinux-setup.md#実施手順) で RPM Fusion（free）を有効にしてあること（その前提の同書の手順 17 の EPEL も）。`dnf repolist enabled | grep -E '^rpmfusion'` で何も出なければ、手順 7 の後に先に通す
> - **すべて対象ホスト上で実行する**。手順 7 と手順 11 の GUI の確認だけ、デスクトップセッションで行う
> - **手順 5・8・9 には対話入力がある**（トランザクション表の `[y/N]`。手順 8 は EPEL の鍵の確認も）。答えてから次の手順を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- Firefox を入れ済みのホストに AAC・H.264 の再生だけ足すなら、[AlmaLinux 10 の初期設定の手順 17〜21](almalinux-setup.md#実施手順)（EPEL と RPM Fusion）を通してから、手順 8 から貼る（手順 8 以降は変数を使わない）
- 手順の後: 以後は[更新](#更新)・[ロールバック](extra/firefox.md#ロールバック)

1. 変数を設定する。

   ```bash
   FF_PKG=firefox                  # 本書は最新版（Rapid Release）の firefox だけを扱う。変更しない。<FF_PKG>
   FF_L10N=firefox-l10n-ja         # 日本語 UI の言語パック。要らなければ空にする。<FF_L10N>
   for v in FF_PKG FF_L10N; do printf '%-9s = %s\n' "$v" "${!v}"; done
   ```

   - **編集が必須の変数は無い**。最新版（Rapid Release）を入れるなら既定のままでよい
   - `FF_PKG` は `firefox` のまま使う。ESR / Beta の導入・確認・ロールバックは本書では扱わない
   - 最後の行で値を読み戻す
   - `FF_PKG` が空なら、ここで止めて直す
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. 署名鍵を落として、取り込む前に fingerprint と uid を確かめる。

   ```bash
   curl -fsSL https://packages.mozilla.org/rpm/firefox/signing-key.gpg | gpg --show-keys
   ```

   - `gpg` が無ければ、`sudo dnf install -y gnupg2` で入れてから貼り直す
   - `pub` 行の fingerprint が `14F26682D0916CDD81E37B6D61B7B526D98F0353`
   - uid が `Mozilla Software Releases <release@mozilla.com>`
   - 違っていればここで止める
   - **次の手順は、この 2 つを目で確かめてから貼る**

1. 一致したら、鍵を rpm に取り込み、入ったか確かめる。

   ```bash
   {
     sudo rpm --import https://packages.mozilla.org/rpm/firefox/signing-key.gpg
     rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i mozilla
   }
   ```

   - `rpm --import` は期限切れの副鍵についての warning を出すが、署名に使う副鍵は別にあるので問題ない（参考資料を参照）
   - `gpg-pubkey-d98f0353-55a94004 Mozilla Software Releases ...` の 1 行が出る

1. Mozilla のリポジトリを追加し、入手できる版を見る。

   ```bash
   {
     sudo tee /etc/yum.repos.d/mozilla.repo >/dev/null <<'EOF'
   [mozilla]
   name=Mozilla Packages
   baseurl=https://packages.mozilla.org/rpm/firefox
   enabled=1
   gpgcheck=1
   repo_gpgcheck=0
   gpgkey=https://packages.mozilla.org/rpm/firefox/signing-key.gpg
   priority=10
   EOF
     dnf -q list --showduplicates "${FF_PKG}" | tail -6
   }
   ```

   - 一覧の下のほうに、`mozilla` リポジトリ提供の版が出る
   - このリポジトリは `baseurl` にアーキテクチャを含まないので、`x86_64` の行も一緒に並ぶ（参考資料を参照）

1. Firefox を入れる。

   ```bash
   sudo dnf install "${FF_PKG:?手順 1 の FF_PKG が空のまま。値を入れて貼り直す}" ${FF_L10N}
   ```

   - AppStream の Firefox（ESR）が既に入っているホストでは、この 1 コマンドが `Upgrading: firefox` として解決される（参考資料を参照）
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. Mozilla 公式のビルドが入ったか確かめる。

   ```bash
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' "${FF_PKG}" ${FF_L10N}
   firefox --version
   rpm -qi "${FF_PKG}" | sed -n '/^Vendor/p;/^Build Date/p'
   ```

   - `from_repo` が `mozilla`、`Vendor` が `Mozilla` なら、Mozilla 公式のビルドが入っている

1. デスクトップのセッションで Firefox を起動し、`about:support` で公式のビルドかを確かめる。

   - 次のように出ればよい（日本語 UI の表記）
     - 「更新チャンネル」が `release`
     - 「プログラムの実行ファイル」が `/usr/lib/firefox/firefox-bin`（AppStream 版の `/usr/lib64` ではない）
   - 日本語パックを入れた場合は、`about:preferences` の言語で日本語を選べる

1. [RPM Fusion](almalinux-setup.md#実施手順) を有効にしたホストで、入手できる版を見てから FFmpeg のライブラリを入れる。

   ```bash
   dnf -q list --showduplicates ffmpeg-libs
   sudo dnf install ffmpeg-libs
   ```

   - 版は `ffmpeg-libs.aarch64  7.1.5-1.el10  rpmfusion-free-updates` のように出る
   - 依存として、RPM Fusion の `x264-libs`・`x265-libs` などと、EPEL のライブラリが入る
   - EPEL の `noopenh264` も依存で入るが、H.264 の再生には影響しない（参考資料を参照）
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを目で確かめてから `y` と答える。違っていれば `N` で中断する
   - `conflicts with libswresample-free` と出て止まったら、手順 9 で入れ直す。入ったときは手順 9 は飛ばす
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. 手順 8 が `libavcodec-free` との衝突で止まったときだけ、それを外して入れ直す。

   ```bash
   sudo dnf install --allowerasing ffmpeg-libs
   ```

   - トランザクション表の `Removing dependent packages:` に、`libavcodec-free`・`libavutil-free`・`libswresample-free` の 3 つが出る
   - この 3 つのほかにも `Removing` に出たら、`N` で止める
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. FFmpeg のライブラリが入ったか確かめる。

   ```bash
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' ffmpeg-libs rpmfusion-free-release epel-release
   ls /usr/lib64/libavcodec.so.*
   ```

   - `ffmpeg-libs 7.1.5-1.el10 rpmfusion-free-updates` の行と、`rpmfusion-free-release`・`epel-release` の行が出る
   - `/usr/lib64/libavcodec.so.61` がある

1. Firefox をすべて閉じてから起動し直し、AAC・H.264 の再生を確かめる。

   - **起動中の Firefox は FFmpeg を読み直さないので、開いていたら全部閉じてから起動し直す**
   - `about:support` の「コーデックサポート情報」で、`H264` と `AAC` の「ソフトウェアデコーディング」が「対応」になる
   - 再生できなかった動画が再生できる

---

## 更新

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 の更新](#windows-11-の更新)
- 通常の `dnf upgrade` に含まれる
- 手順 8 の `ffmpeg-libs`（RPM Fusion）も、`dnf upgrade` で一緒に上がる

1. Firefox だけ上げるときは、言語パックと一緒に上げる。

   ```bash
   sudo dnf upgrade "${FF_PKG}" ${FF_L10N}
   ```

   - Firefox 内蔵の自動更新機能は RPM 版では無効で（`/usr/lib/firefox` に一般ユーザーの書き込み権が無い）、更新は dnf 側で行う
   - 本体だけ上げて言語パックを取り残すと UI が英語に戻るので、両方まとめて上げる

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows のデスクトップで行う**。この節の手順 1 で管理者の Windows PowerShell（5.1）を開き、この節の手順 2・3 と、[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/firefox.md#windows-11-のロールバック)のブロックをそこに貼る。ログインするユーザーは Administrators の一員（Firefox を PC 全体の `C:\Program Files\Mozilla Firefox` に入れ、Mozilla Maintenance Service も入れるため）
> - 前提: [Windows 11 の初期設定の手順 16〜19](windows-setup.md#実施手順)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - **この節の手順 4・5 は画面の操作**（Firefox を起動して確かめる、Windows の設定で既定のブラウザーにする）

- 上から順にコードブロックを貼る。変数は無い（[実施手順](#実施手順)の手順 1 の `FF_PKG`・`FF_L10N` は AlmaLinux 10 だけで使う）
- 手順の後: 以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/firefox.md#windows-11-のロールバック)
- [Windows 11 の初期設定](windows-setup.md)の後に通す手順書では、[git.md](git.md) の次に通す。後で通す [wezterm-nightly.md](wezterm-nightly.md)・[claude-code.md](claude-code.md) より先に既定のブラウザーにしておくと、Claude Code のログイン（`/login`）が Firefox で開く
- AAC と H.264 は Windows の機能（Media Foundation）で再生するので、[実施手順](#実施手順)の手順 8〜11（RPM Fusion の FFmpeg）に当たる手順は無い（この節の手順 4 の補足）

1. Windows で、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. Firefox がまだ入っていないことを確かめる。

   ```powershell
   $arp = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
   Get-ItemProperty -Path $arp -ErrorAction SilentlyContinue | Where-Object DisplayName -like 'Mozilla Firefox*' | Format-Table DisplayName, DisplayVersion, InstallLocation
   Get-AppxPackage -Name 'Mozilla.MozillaFirefox' | Format-Table Name, Version
   ```

   - どちらも何も出なければ、入っていない
   - `Mozilla Firefox (x64 ja)` が `C:\Program Files\Mozilla Firefox` で出たら、この節の手順で入れたもの（か同じもの）。この節の手順 3 はそのまま貼ってよい（新しい版があれば上がる）
   - ほかのもの（`(x64 en-US)` などのほかの言語・`(x86 ja)`・ESR・`%LOCALAPPDATA%` の下・Microsoft Store 版の `Mozilla.MozillaFirefox`）が出たら、設定 →「アプリ」→「インストールされているアプリ」で外してから始める（プロファイルは残る）

1. winget で日本語版の Firefox を PC 全体に入れ、入ったか確かめる。

   ```powershell
   winget install --exact --id Mozilla.Firefox.ja --source winget --scope machine --accept-source-agreements --accept-package-agreements
   winget list --exact --id Mozilla.Firefox.ja --source winget
   (Get-Item -LiteralPath "$env:ProgramFiles\Mozilla Firefox\firefox.exe").VersionInfo | Format-List FileName, ProductVersion
   Get-Service -Name MozillaMaintenance | Format-Table Name, Status, StartType
   Get-ScheduledTask -TaskPath '\Mozilla\' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   ```

   - winget はインストーラの sha256 を確かめてから、画面を出さずに入れる。管理者の PowerShell なので、管理者の確認（UAC）は出ない
   - `winget list` に `Mozilla Firefox (x64 ja)  Mozilla.Firefox.ja  157.0` の形の行が出ればよい（版は実行した日の最新）
   - `FileName` が `C:\Program Files\Mozilla Firefox\firefox.exe` で、`ProductVersion` が同じ版
   - `MozillaMaintenance`（Mozilla Maintenance Service）の行が出る。ふだんは止まっていて、更新のときだけ動く
   - タスクの一覧に `Firefox Default Browser Agent <番号>` が出る
   - `winget` が見つからないと出たら、Microsoft Store で「アプリ インストーラー」を更新してから貼り直す

1. スタートメニューから Firefox を起動し、`about:support` で日本語版の公式のビルドかを確かめる。

   - スタートメニューの「Firefox」から起動する（管理者の PowerShell からは起動しない。Firefox が管理者の権限で動いてしまう）
   - 最初の起動で、Firefox を既定のブラウザーにするかを聞かれることがある。選ぶと Windows の設定が開くので、この節の手順 5 の操作をそこで行ってよい
   - アドレスバーに `about:support` を入れ、「アプリケーション基本情報」を見る
     - 「更新チャンネル」が `release`
     - 「プログラムの実行ファイル」が `C:\Program Files\Mozilla Firefox\firefox.exe`
   - 同じページの「コーデックサポート情報」で、`H264` と `AAC` の「ソフトウェアデコーディング」が「対応」になる
     - 情報が利用できないと出たら、動画を 1 本再生してから開き直す
   - メニューやボタンが日本語で出る（日本語版なので、言語パックは要らない）

1. Windows の設定で、Firefox を既定のブラウザーにする。

   - 設定（Win+I）→「アプリ」→「既定のアプリ」を開き、「アプリケーションの既定値を設定する」の一覧で「Firefox」を選ぶ（2 つ並んだときは上のもの）
   - 「Firefox を既定のブラウザーに設定する」の横の「既定値に設定」を押す（押すと横にチェックの印が出る）
   - 押した後は、同じ画面の `.htm`・`.html`・`HTTP`・`HTTPS` などの既定が Firefox になる
   - Win+R の「ファイル名を指定して実行」に `https://www.mozilla.org/ja/` を入れて Enter を押し、Firefox で開けばよい
   - Firefox の設定（`about:preferences`）の「既定のブラウザー」の「既定のブラウザーにする」からでもよい（Firefox が自分で既定にできなければ、同じ Windows の設定の画面が開く）
   - 画面の名前が異なる場合は、Windows の既定のアプリの設定から Firefox を選ぶ

---

## Windows 11 の更新

- Firefox は自分で更新する。起動している間に新しい版を取り、次に起動したときに入れ替える
- 閉じている間も、Firefox を起動すると作られるタスク（タスク スケジューラの `\Mozilla\` の `Firefox Background Update <番号>`。7 時間ごと）が新しい版を取って入れる
- `C:\Program Files` への書き込みは Mozilla Maintenance Service が行うので、管理者の確認（UAC）は出ない
- 待たずに上げるときは、Firefox のメニュー →「ヘルプ」→「Firefox について」を開く（新しい版を確かめて取る）か、この節の手順を管理者の Windows PowerShell（5.1）に貼る
- 日本語版なので、言語パックは使わない。言語パックを足すと、閉じている間の更新が止まる（Mozilla の Background Updates の文書）

1. 今の版と、winget に新しい版があるかを確かめる。

   ```powershell
   (Get-Item -LiteralPath "$env:ProgramFiles\Mozilla Firefox\firefox.exe").VersionInfo.ProductVersion
   winget list --exact --id Mozilla.Firefox.ja --source winget --upgrade-available
   ```

   - 1 行目が今の版
   - winget に新しい版があれば、`Mozilla.Firefox.ja` の行に今の版と新しい版が並ぶ
   - 行が出ずに、見つからない旨が出たら、新しい版は無い（Firefox が自分で先に上げていることもある）。この節の手順 2 は飛ばす

1. 新しい版があるときだけ、Firefox をすべて閉じてから winget で上げる。

   ```powershell
   winget upgrade --exact --id Mozilla.Firefox.ja --source winget --accept-source-agreements --accept-package-agreements
   (Get-Item -LiteralPath "$env:ProgramFiles\Mozilla Firefox\firefox.exe").VersionInfo.ProductVersion
   ```

   - 最後の行が新しい版になればよい
   - **注意**: Firefox を開いたままだと、入れ替えが途中で終わることがある（参考資料を参照）
