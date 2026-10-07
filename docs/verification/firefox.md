# Firefox 最新版インストール手順（AlmaLinux 10 は Mozilla 公式 RPM リポジトリ / Windows 11 は winget）の検証記録

[手順書](../firefox.md)

## 最新の確認範囲（Windows 11）

Windows 11 Pro のクリーン VM の管理者の Windows PowerShell 5.1 で、Windows 節の手順 2・3 による新規導入を確認した（2026-10-06）。WinGet の一覧と本体の版、Maintenance Service と Default Browser Agent のタスクまでを確認した。

GUI の起動と about:support の言語・チャンネル・コーデック表示、動画の再生、既定のブラウザーの切り替え、手で貼る操作、更新・ロールバックは未検証。

[今回の付録](#付録-windows-11-pro-の-vm-での新規導入の検証2026-10-06)。以降の既存記録は、各実施日・対象版・範囲に従う履歴として保持した。

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順 / 手順 1: 補足: 変数について

本書で導入するのは `firefox`（Rapid Release）だけ。配布の調査では、ほかのチャンネルもリポジトリにあることを確かめた:

```
$ dnf -q list --available firefox-l10n-ja firefox-esr firefox-beta | tail -6
Available Packages
firefox-beta.aarch64                     157.0b4-1                       mozilla
firefox-beta.x86_64                      157.0b4-1                       mozilla
firefox-esr.aarch64                      153.3.0esr-1                    mozilla
firefox-esr.x86_64                       153.3.0esr-1                    mozilla
firefox-l10n-ja.noarch                   156.0.1-1                       mozilla
```

`firefox-esr` は **Mozilla の ESR（153 系）** で、AppStream の ESR 140 とは別物。並べて入れることもできる（`/usr/lib/firefox-esr`）が、本書では扱わない。

`FF_L10N` は `firefox-l10n-<言語コード>` の形で `noarch`。本体とバージョンが揃っていないと UI に反映されないので、常に本体と一緒に入れ替える。

### 実施手順 / 手順 3: 補足: 鍵の警告

`gpg --show-keys` は主鍵 1 つと副鍵 6 つを表示する。有効な署名用副鍵は 1 つだけで、残りは期限切れ:

```
pub   rsa4096 2015-07-17 [SC]
      14F26682D0916CDD81E37B6D61B7B526D98F0353
uid                      Mozilla Software Releases <release@mozilla.com>
sub   rsa4096 2026-08-06 [S] [expires: 2028-08-05]
sub   rsa4096 2021-05-17 [S] [expired: 2023-05-17]
...
```

`rpm --import` はこの期限切れ副鍵について warning を出す。取り込み自体は成功している:

```
$ sudo rpm --import https://packages.mozilla.org/rpm/firefox/signing-key.gpg
warning: Certificate 61B7B526D98F0353:
  Subkey F1A6668FBB7D572E is expired: The subkey is not live
  Policy rejects subkey 1C69C4E55E9905DB: Policy rejected non-revocation signature (SubkeyBinding) requiring second pre-image resistance
  Subkey EBE41E90F6F12F6D is expired: The subkey is not live
  ...
```

先に `rpm --import` しておくのは、`dnf install` の途中で「この鍵を取り込むか」と聞かれたときに fingerprint を目視で照合する手間を、独立した手順に分けるため。取り込まずに進めても dnf が同じ鍵を取りに行って同じ確認を出す。

### 実施手順 / 手順 5: 補足: 言語パックのクォートと、ESR からの載せ替え

`FF_L10N` を空にした場合にクォートで空文字列を渡さないよう、言語パックだけクォートしていない。

実機では `dnf upgrade firefox` で載せ替えた（`dnf history` の記録）:

```
$ sudo dnf history info 16
Command Line   : upgrade firefox
Packages Altered:
    Upgrade  firefox-156.0-1.aarch64           @mozilla
    Upgraded firefox-140.15.0-1.el10_2.aarch64 @@System
```

本書では `dnf install` 1 本にしてある（未導入のホストでもそのまま使えるため）。ESR が入っている状態でも `Upgrading` として解決されることをコンテナで確認した:

```
$ dnf install --assumeno firefox firefox-l10n-ja
Package firefox-140.15.0-1.el10_2.aarch64 is already installed.
Installing:
 firefox-l10n-ja   noarch    156.0.1-1   mozilla   497 k
Upgrading:
 firefox           aarch64   156.0.1-1   mozilla   107 M
```

依存パッケージの追加は無い（ESR 版と同じ共有ライブラリで動く）。未導入のホストに新規で入れる場合は、GTK などデスクトップ側の依存で 100 以上のパッケージが付いてくる。

### 実施手順 / 手順 8: 補足: 手順 8〜11 で足すもの、入るもの、鍵の確認の実測

手順 8〜11 では、Firefox が自前で復号できない AAC と H.264 のために、RPM Fusion（free）の FFmpeg のライブラリを入れる。理由と、EPEL の `libavcodec-free` を採らなかった経緯は[選択した方針](../reference/firefox.md#選択した方針)にある。

Firefox だけを入れたコンテナでは 79 パッケージが入った（ダウンロード 42 MB、展開後 137 MB）。内訳は EPEL 44・BaseOS 17・AppStream 14・RPM Fusion 4（`ffmpeg-libs`・`x264-libs`・`x265-libs`・`vvenc-libs`）で、CRB からは無い。実機（GNOME のデスクトップ）では、既に入っているものが多く 60 パッケージだった（EPEL 44・AppStream 10・RPM Fusion 4・BaseOS 2）。

x86_64 の実機（GNOME のデスクトップ、EPEL は入れ済み）では 62 パッケージだった（ダウンロード 40 MB、展開後 128 MB。EPEL 47・AppStream 10・RPM Fusion 4・BaseOS 1）。弱い依存として、次のものも入った:

- `intel-vpl-gpu-rt`・`jxl-pixbuf-loader`・`vmaf-models`
- `tesseract-langpack-jpn`・`tesseract-langpack-jpn_vert`（`Supplements: (tesseract and langpacks-ja)` なので、日本語の `langpacks-ja` が入ったホストで付く）

Firefox のプロセスが読み込むのは `/usr/lib64/libavcodec.so.61.19.101`（FFmpeg 7.1）だった（コンテナで `/proc/<pid>/maps` を見た）。コマンドの `ffmpeg` は入らない（要るなら `sudo dnf install ffmpeg`）。

**`noopenh264` が入る理由**: `ffmpeg-libs` が `libopenh264.so.7` を要求し、x86_64 の実機の有効なリポジトリでそれを提供するのは、EPEL の `noopenh264`（中身の無い OpenH264）だけだった。aarch64 でも同じ（メタデータで確認）。x86_64 の実機では、Firefox のプロセスが `/usr/lib64/libopenh264.so.2.4.1` も読み込んだが、H.264 + AAC の mp4 は再生できた。EPEL の `libavcodec-free` と違い、H.264 は FFmpeg 自身のデコーダで復号される。

EPEL の鍵の確認の実測（RPM Fusion の有効化（今の [rpmfusion.md](../rpmfusion.md) の手順 3）で、EPEL が依存として入ったコンテナ）。RPM Fusion の鍵は rpmfusion.md の手順 2 で取り込んであるので聞かれない:

```
Importing GPG key 0xE37ED158:
 Userid     : "Fedora (epel10) <epel@fedoraproject.org>"
 Fingerprint: 7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10
```

### 実施手順 / 手順 9: 補足: EPEL の libavcodec-free を外す理由

EPEL の `libavcodec-free`（EPEL の `ffmpeg-free` のライブラリ）は、EPEL の Chromium や `gstreamer1-plugin-libav` など、`libavcodec.so.61` を使うパッケージの依存で入っていることがある。`ffmpeg-libs` とは同居できず、手順 8 は次のように止まる（`libavcodec-free` を入れたコンテナでの実測）:

```
Error:
 Problem: problem with installed package libswresample-free-7.1.2-1.el10_2.aarch64
  - package ffmpeg-libs-7.1.5-1.el10.aarch64 from rpmfusion-free-updates conflicts with libswresample-free provided by libswresample-free-7.1.2-1.el10_2.aarch64 from @System
  - package ffmpeg-libs-7.1.5-1.el10.aarch64 from rpmfusion-free-updates conflicts with libswresample-free provided by libswresample-free-7.1.2-1.el10_2.aarch64 from epel
  - conflicting requests
```

`--allowerasing` を付けると、`Removing dependent packages:` に 3 つが並んで入れ替わった。`ffmpeg-libs` は同じ共有ライブラリ（`libavcodec.so.61` など）と `libavcodec-freeworld` を提供する。入れ替えた後、Firefox は H.264 と AAC を再生できた。

`libavcodec-free` を残したままでは、H.264 の動画が再生できない（[選択した方針](../reference/firefox.md#選択した方針)）。コマンドの `ffmpeg-free` も入っているときは、RPM Fusion の [Howto/Multimedia](https://rpmfusion.org/Howto/Multimedia) が案内する `sudo dnf swap ffmpeg-free ffmpeg --allowerasing` になる（本書では試していない）。

### 実施手順 / 手順 11: 補足: 起動し直す理由と、about:support の表

FFmpeg を入れる前から起動していた Firefox では、入れた後も about:support の `H264` と `AAC` は「未対応」のままで、AAC の復号も失敗した。起動し直すと「対応」になった（コンテナでの実測）。

「コーデックサポート情報」の「ソフトウェアデコーディング」の列（「ハードウェアデコーディング」は、どちらもすべて「未対応」）:

| コーデック名 | 入れる前 | 入れた後 |
|---|---|---|
| H264 | 未対応 | 対応 |
| VP9 | 対応 | 対応 |
| AV1 | 対応 | 対応 |
| HEVC | 未対応 | 対応 |
| AAC | 未対応 | 対応 |
| Opus | 対応 | 対応 |

この表の `H264` は FFmpeg の側だけを示す。Firefox が起動後に自動で落とす Cisco の OpenH264（プロファイルの `gmp-gmpopenh264`）で H.264 を再生できているときも、FFmpeg が無ければ「未対応」と出る。

### ロールバック / 手順 0: 本文中の記録

- この節の手順 1 はコンテナと x86_64 の VM で本実行した

### ロールバック / 手順 0: 本文中の記録

- Firefox を戻す手順（この節の手順 2〜5）も x86_64 の VM で本実行した（2026-10-06）。`157.0-1` から AppStream の `140.16.0-1.el10_2` に戻り、言語パック・Mozilla の repo と署名鍵も外れた

### Windows 11 で使う: 検証状況の記録

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、winget の定義、Mozilla のインストーラの sha256・署名・中身、Mozilla の文書と Firefox・winget のソース、Linux の PowerShell 7 での構文だけ（[対象と検証環境](#対象と検証環境)）。

### Windows 11 で使う / 手順 2: 補足: 調べている場所

- Mozilla のインストーラは、アンインストールの登録に `Mozilla Firefox (<構成> <言語>)` の表示名（`DisplayName`）を書く（ESR は `Mozilla Firefox ESR (…)`）。管理者で入れたものは `HKLM`、管理者でないユーザーが自分に入れたもの（`%LOCALAPPDATA%\Mozilla Firefox`）は `HKCU` に書かれる（Firefox のソースの `shared.nsh`。[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
- Microsoft Store 版と winget の `Mozilla.Firefox.MSIX` は、パッケージのアプリ（`Mozilla.MozillaFirefox`）として入る
- 別の言語の Firefox が入っている場所に重ねて入れたときにどうなるかは、確かめていない。そのため、先に外す

### Windows 11 で使う / 手順 3: 補足: winget の定義と、インストーラが入れるもの

**winget の定義**（`Mozilla.Firefox.ja` 157.0。[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）

- インストーラは、Mozilla の CDN（`download-installer.cdn.mozilla.net`）の日本語版の `Firefox Setup 157.0.exe`（NSIS）。x64・x86・arm64 があり、winget は PC の構成に合うものを選ぶ
- `Scope` は `machine` だけ（自分のユーザーに入れる定義は無い）。`--scope machine` は、その確かめ
- winget がインストーラに渡すのは `/S /PreventRebootRequired=true`（画面を出さない。使用中のファイルがあっても、再起動が要る処理をしない）
- `--accept-source-agreements` と `--accept-package-agreements` は、winget を初めて使う PC で出る同意の問いに答えるため（続けて貼った行が答えとして食われないように）

**インストーラが入れるもの**（Mozilla の Full Installer Configuration の既定。スイッチで変えていない）

- 本体: `C:\Program Files\Mozilla Firefox`（64 ビットの Windows の既定の場所）
  - 場所は変えない（`--location` を付けない）。既定の場所のときだけ、アンインストールの登録のキーの名前が `Mozilla Firefox` になり、winget の定義の `ProductCode` と合う（Firefox のソースの `postupdate_helper.nsh`）
- Mozilla Maintenance Service: 管理者で入れたときだけ入る。管理者の確認なしに、`C:\Program Files` の Firefox を更新するためのサービス（[Windows 11 の更新](../firefox.md#windows-11-の更新)）
- Default Browser Agent のタスク: タスク スケジューラの `\Mozilla\` に、24 時間ごとに既定のブラウザーが何かを調べて Mozilla に送るタスクを作る（テレメトリを切っていれば送らない。Mozilla の Default Browser Agent の文書）
- ショートカット: デスクトップ・スタートメニュー（ふつうのものとプライベート ブラウジングのもの）と、タスクバーへのピン留め
  - 要らなければ、この手順の `winget install` に `--custom '/DesktopShortcut=false /TaskbarShortcut=false'` を足すと作らないはず（Mozilla の文書のスイッチ。確かめていない）

### 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に、Firefox の**最新版**（Rapid Release）を入れる
  - AlmaLinux 10 では dnf 管理で入れ、Windows 版と同じように AAC と H.264 の動画も再生できるようにする。標準リポジトリ（AppStream）の `firefox` は ESR 140 系で、最新版より 16 メジャー古い
  - Windows 11 では日本語版を PC 全体に入れ、既定のブラウザーにする。[Windows 11 の初期設定](../windows-setup.md)の後に通す手順書の 1 つ
- **進め方**
  - **AlmaLinux 10**（[実施手順](../firefox.md#実施手順)）: Mozilla が公式に配っている RPM リポジトリ `packages.mozilla.org/rpm/firefox` を 1 つ足し、`dnf install` する。続けて、[rpmfusion.md](../rpmfusion.md) で有効にした RPM Fusion（free）から、FFmpeg のライブラリ `ffmpeg-libs` を入れる（手順 8〜11）。**読者が書き換えるのは冒頭の変数ブロックだけ**で、既定（最新版 + 日本語パック）ならそのまま貼れる
  - **Windows 11**（[Windows 11 で使う](../firefox.md#windows-11-で使う)）: winget の `Mozilla.Firefox.ja`（Mozilla の日本語版のインストーラ）を、管理者の Windows PowerShell 5.1 から PC 全体（`C:\Program Files\Mozilla Firefox`）に入れ、Windows の設定で既定のブラウザーにする。更新は Firefox 自身（Mozilla Maintenance Service）に任せる。変数は無く、AAC・H.264 のために足すものも無い
- **状態（AlmaLinux 10）**
  - 2026-10-06: 別の新規 VM で現行手順を再検証した。今回の実施・解除・未実施範囲は[新しい付録](#付録-現行版の新規-vm-での再検証2026-10-06)に記録した
  - **2026-10-06: クリーンな x86_64 の VM で手順 1〜8・10・11 とロールバック 1〜5 を本実行済み**。Mozilla 157 の日本語 GUI と H.264/AAC の動画再生、AppStream の ESR 140 への復元を確認した（末尾の付録）。手順 9 は衝突が無かったため省略した
  - **手順 1〜7（Firefox）は実機で本実行済み（2026-09-21）**
    - 下表のホストで `dnf upgrade firefox` を実行し、AppStream の `140.15.0-1.el10_2` から mozilla の `156.0-1` に載せ替えて、そのまま常用している
    - 2026-09-25 に OS を入れ直した後も、手順 5 の `dnf install firefox firefox-l10n-ja` で入れ直した（`dnf history` では `Upgrade firefox-156.0.1-1.aarch64 @mozilla`）
    - 本書の手順（鍵の照合 → repo → install → 検証）は、2026-09-22 に同じ OS のコンテナで通し直した
    - 確認したこと: `156.0.1-1` が入る、ESR からの載せ替えが `Upgrading` として解決される、ロールバックが `Downgrading` に解決される
    - **コンテナでは GUI を起動していない**（実機では 156.0 が動作中）
    - **ESR / Beta チャンネルと言語パック以外の l10n は未検証**
  - **手順 8〜11（AAC・H.264）と、その前の RPM Fusion の有効化も実機で本実行済み（2026-09-28）**。aarch64 と x86_64 の 2 台
    - RPM Fusion の有効化は、今の [rpmfusion.md](../rpmfusion.md) の手順 1〜3。当時はこの文書の手順 8〜11 で、今の手順 8〜11 は手順 12〜14 だった
    - 下表の aarch64 の実機で、利用者が手順どおりに入れた（[付録](#付録-実機での本実行2026-09-28)）
      - rpmfusion.md 手順 2 の鍵が登録されている
      - `dnf history` に、rpmfusion.md 手順 3（4 パッケージ）と手順 8（`ffmpeg-libs` ほか 60 パッケージ）の実行が残っている
      - `libavcodec-free` は入っていなかったので、手順 9 は要らなかった
    - 利用者が、再生できなかった動画が再生できるようになったことを確かめた
    - 同じ実機で、一時プロファイルの headless の Firefox を Marionette で動かして次を確かめた
      - about:support の H264・HEVC・AAC が「対応」になる
      - AAC と H.264 の再生が通る
      - Firefox のプロセスが `/usr/lib64/libavcodec.so.61.19.101` を読み込んでいる
    - この文書の手順 1〜10 と rpmfusion.md の手順 1〜3 のブロックは、同じ OS の aarch64 コンテナでもそのまま流して通した（条件付きの手順 9 は、`libavcodec-free` を入れた別のコンテナで）
    - 下表の x86_64 の実機では、rpmfusion.md の手順 1〜3 と、手順 8・10 のコマンドを実行した（[付録](#付録-x86_64-の実機での本実行2026-09-28)）
      - YouTube の動画が 360p から上がらず、音声が AAC だけの動画は再生できなかったホスト
      - dnf は `--assumeno` でトランザクション表を確かめてから、`-y` を付けて入れた。手順 9 は要らなかった
      - 一時プロファイルの headless の Firefox で、about:support の H264・HEVC・AAC が「対応」になり、AAC の復号と H.264 + AAC の mp4 の再生が通ることを確かめた
      - 同じく、音声が AAC だけの YouTube の動画が VP9 1080p60 + AAC で再生された（FFmpeg を切ると「ご利用のブラウザではこの動画を再生できません。」になった）
      - 起動し直した利用者の Firefox が `/usr/lib64/libavcodec.so.61.19.101` を読み込むことを確かめた
      - 利用者が、その Firefox の画面で 2 本の動画が再生できることを確かめた（[付録](#付録-x86_64-の実機での画面の確認2026-09-28)）
    - 音声が AAC だけの YouTube の動画は、x86_64 の実機でだけ確かめた（利用者の画面と headless の Firefox。aarch64 の例の動画は、実機に入れる前に YouTube 側で Opus が足されていた。代わりに、AAC を MSE で流すテストを実機でも通した）
  - 2026-09-28: 手順 4 のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-02: もとの手順 3・4 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）:
    - winget の定義: `Mozilla.Firefox.ja` と `Mozilla.Firefox` の 157.0（インストーラの種類・スコープ・スイッチ・URL・sha256・`ProductCode`）と、`Mozilla.Firefox` から言語のインストーラが無くなった版（137.0.2）
    - 配布物: x64 の日本語版の `Firefox Setup 157.0.exe` の sha256（winget の定義と Mozilla の `SHA256SUMS` と一致）・Authenticode の署名者（`Mozilla Corporation`）・中身（Maintenance Service のインストーラ、Default Browser Agent、日本語の `updater.ini`）。Linux で読んだだけで、Windows の `Get-AuthenticodeSignature` は通していない
    - Mozilla の文書と Firefox のソース: インストーラの既定（場所・Maintenance Service・タスク・ショートカット）、アンインストーラが消すもの、閉じている間の更新の条件、既定のブラウザーの設定のしかた、Windows で H.264 と AAC を Media Foundation で復号すること
    - winget のソース: `--locale` の扱い、NSIS のインストーラで入れたもののアンインストールで窓が出ること、`winget list --upgrade-available`
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査（[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
  - **確かめていないこと**: Windows で貼ること（すべての手順）、winget の表示、入れた後の about:support と動画の再生、Windows の設定の画面の名前と既定のブラウザーの切り替え、Firefox 自身の更新と `winget upgrade`、アンインストールの窓、arm64 の Windows、N エディション

AlmaLinux 10:

| 項目 | 実機 | 検証コンテナ | 検証コンテナ（rpmfusion.md と手順 8〜11） | 実機（rpmfusion.md と手順 8〜11） | x86_64 の実機（rpmfusion.md と手順 8〜11） |
|---|---|---|---|---|---|
| 実施日 | 2026-09-21 | 2026-09-22 | 2026-09-28 | 2026-09-28 | 2026-09-28 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） | 同左 | 実機と同じホスト（2026-09-25 に入れ直した後） | AlmaLinux 10.2 (Lavender Lion) / x86_64（AMD Strix Halo のノート PC） |
| カーネル | 6.12.96 | ホストと同じ | ホストと同じ | 6.12.96 | 6.12.0-211.56.1.el10_2 |
| dnf | 4.20.0 | 4.20.0 | 4.20.0 | 4.20.0 | 4.20.0 |
| 実施前の Firefox | `firefox-140.15.0-1.el10_2.aarch64`（appstream、ESR 140） | 同じものを `dnf install firefox` で用意 | `firefox-156.0.1-1.aarch64`（mozilla。手順 2〜5 で用意） | `firefox-156.0.1-1.aarch64`（mozilla。2026-09-25 に手順 5 で入れ直したもの） | `firefox-156.0.1-1.x86_64`（mozilla） |
| 入った Firefox | `firefox-156.0-1.aarch64`（mozilla、Vendor: Mozilla） | `firefox-156.0.1-1.aarch64` | 同左。FFmpeg は `ffmpeg-libs-7.1.5-1.el10.aarch64`（rpmfusion-free-updates） | Firefox は変わらない。FFmpeg は `ffmpeg-libs-7.1.5-1.el10.aarch64`（rpmfusion-free-updates） | Firefox は変わらない。FFmpeg は `ffmpeg-libs-7.1.5-1.el10.x86_64`（rpmfusion-free-updates） |
| デスクトップ | GNOME 49 / Wayland | 無し（`--version` まで） | 無し（headless の Firefox を Marionette で操作） | GNOME 49（`gnome-shell` 49.4） | GNOME 49（`gnome-shell` 49.4）/ Wayland |
| SELinux | Enforcing | コンテナ側は無効 | コンテナ側は無効 | Enforcing | Enforcing |

Windows 11（前提にしている環境。ほかの Windows の手順書の実機の記録と同じ PC を想定）:

| 項目 | 値 |
|---|---|
| OS | Windows 11（x64。[Windows の OpenSSH サーバー](../windows-openssh-server.md)の PC は 25H2・26H2） |
| PowerShell | Windows PowerShell 5.1（管理者として実行） |
| ユーザー | Administrators の一員 |
| winget | Windows 11 の「アプリ インストーラー」に入っているもの |
| Firefox | 157.0（winget の `Mozilla.Firefox.ja`。Mozilla が 2026-09-29 に出した版） |

> [!NOTE]
> AlmaLinux 10 の環境固有の値は**シェル変数**で書いてある。[手順 1](../firefox.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。Windows 11 の節には変数が無い（winget の ID とパスはブロックに直接書いてある）。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${FF_PKG}` | 本書で導入するパッケージ名。`firefox`（最新版）から変更しない | `firefox` |
> | `${FF_L10N}` | 言語パックのパッケージ名。空にすると英語 UI のまま | `firefox-l10n-ja` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。Windows 11 のタスクの名前の末尾の番号（インストール先ごとに決まる）は `<番号>` と書いた。バージョン（`156.0.1-1`、`7.1.5-1.el10`、Windows の `157.0`）は実行日によって変わる。
>
> 鍵の fingerprint（Mozilla・RPM Fusion・EPEL）は公開情報なので本文に書いてある。プロファイルや保存されたパスワードには触れない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

AlmaLinux 10 の実機（2026-09-21）。Windows 11 の PC は、[Windows 11 で使う](../firefox.md#windows-11-で使う)の手順 2 で確かめる。

| 項目 | 状態 |
|---|---|
| Firefox | `firefox-140.15.0-1.el10_2.aarch64`（appstream）。`firefox --version` は `Mozilla Firefox 140.15.0esr` |
| AppStream の候補 | `140.10.1-1.el10_2` 〜 `140.15.0-1.el10_2`（ESR 140 系のみ。Rapid Release は無い） |
| 有効な追加リポジトリ | epel、crb、raspberrypi（mozilla はまだ無い） |
| Flatpak | `flatpak-1.16.0` は導入済みだが**リモートが 1 つも登録されていない**（flathub 無し） |
| 鍵 | `rpm -q gpg-pubkey` に Mozilla の鍵は無し |

rpmfusion.md と手順 8〜11 の前の実機（2026-09-28）。2026-09-25 に OS を入れ直し、Firefox は手順 5 で入れ直してある:

| 項目 | 状態 |
|---|---|
| Firefox | `firefox-156.0.1-1.aarch64`（mozilla） |
| FFmpeg | `/usr/lib64/libavcodec*` が無い |
| 有効な追加リポジトリ | mozilla・crb・raspberrypi など。**EPEL と RPM Fusion は無い** |
| プロファイル | `~/.config/mozilla/firefox`（`~/.mozilla` は無い）。Cisco の OpenH264（`gmp-gmpopenh264`）はまだ落ちていない |

rpmfusion.md と手順 8〜11 の前の x86_64 の実機（2026-09-28）:

| 項目 | 状態 |
|---|---|
| Firefox | `firefox-156.0.1-1.x86_64`（mozilla）と `firefox-l10n-ja` |
| FFmpeg | `/usr/lib64/libavcodec*` が無い |
| 有効な追加リポジトリ | mozilla・epel・crb など。**EPEL は入れ済み（鍵も登録済み）で、RPM Fusion は無い** |
| プロファイル | `~/.mozilla/firefox`。OpenH264 2.6.0（`gmp-gmpopenh264`）と Widevine（`gmp-widevinecdm`）は落ちてきている。利用者が DRM の再生（`media.eme.enabled`）を有効にしている |
| `gpg` | このユーザーでは使ったことが無く、`~/.gnupg` が無い |

### 選択した方針

**最新版であることの確認**:

AlmaLinux 10 で Firefox の最新版を使う経路を比べた（2026-09-22 時点）:

- Mozilla の `product-details` が返す `LATEST_FIREFOX_VERSION` は `156.0.1`、`FIREFOX_ESR` は `140.16.0esr`（2026-09-22）
- リポジトリの `firefox` 156.0.1 は、Rapid Release の最新と一致する

- Mozilla の Linux 版 Firefox は、AAC と H.264 のデコーダを持っていない
  - 同梱の FFmpeg（`libmozavcodec.so`、62.29.101）に入っているデコーダは、flac・mp3・vorbis・opus・pcm だけだった（[付録](#付録-動画が再生できなかった件の切り分け2026-09-28)）
  - AAC と H.264 は、OS の `libavcodec.so.53`〜`.63` を探して読み込む。AlmaLinux 10 の標準リポジトリには FFmpeg が無い
- そのため、音声が AAC しか無い YouTube の動画は再生できない。同じ動画が、Windows の Firefox では再生できた（利用者の報告）
  - YouTube は「ご利用のブラウザではこの動画を再生できません。」と出す（[x86_64 の付録](#付録-x86_64-の実機での本実行2026-09-28)で再現した）
- YouTube の動画には、720p 以上が H.264 だけのときがある（VP9 は 360p だけ。2 本の動画で見た）
  - H.264 を復号できない Firefox では、360p までしか選べない
  - 1 本は、14 分後に読み直すと VP9 が各解像度に揃っていた（[x86_64 の付録](#付録-x86_64-の実機での本実行2026-09-28)）
- H.264 は、Firefox が起動後に自動で落とす Cisco の OpenH264（GMP プラグイン）でも再生できる。AAC を補えるのは FFmpeg だけ
  - ただし x86_64 の実機では、OpenH264 が落ちてきているのに、利用者の Firefox で 1080p を選べず 360p のままだった
  - 同じ時刻の一時プロファイルでは、OpenH264 で H.264 の 1080p60 を再生できた。違いの原因は分かっていない
  - FFmpeg を入れると、H.264 は OpenH264 を使わずに FFmpeg で復号される

FFmpeg のライブラリの入れ方を比べた（2026-09-28 時点。aarch64 のコンテナで Firefox 156.0.1 を動かして確かめた）:

Windows 11 で Firefox を入れる経路を比べた（2026-10-03 時点。winget の定義は [付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）:

| Flathub の `org.mozilla.firefox` | Mozilla 公式ビルド。ただしこのホストは flatpak にリモートが 1 つも登録されておらず、flathub の追加と ~150 MB の runtime 導入から始まる。RPM と二重管理になる | 不採用（RPM で足りる） |

| winget の `Mozilla.Firefox` に `--locale ja` | 137.0.1 までは言語ごとのインストーラ（`InstallerLocale`）が 51 あったが、137.0.2 から英語（en-US）だけになり、言語ごとに `Mozilla.Firefox.<言語>` に分かれた。言語の無いインストーラは、`--locale` を付けると候補から外れるので、入らないはず（winget のソースで読んだだけ） | 不採用 |

### 完了時点の状態

AlmaLinux 10 の実機（2026-09-21）。Windows 11 は流していないので、記録は無い（入るものはこの節の最後の箇条書き）。

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' firefox
firefox 156.0-1 mozilla
$ firefox --version
Mozilla Firefox 156.0
$ rpm -qi firefox | sed -n '/^Vendor/p;/^Build Date/p'
Build Date  : Wed Sep  9 20:41:48 2026
Vendor      : Mozilla
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i mozilla
gpg-pubkey-d98f0353-55a94004 Mozilla Software Releases <release@mozilla.com> public key
```

- 入るファイル: 本体は `/usr/lib/firefox/`、起動スクリプトは `/usr/bin/firefox`、`.desktop` は `/usr/share/applications/firefox.desktop`
- 本体の場所は AppStream 版（`/usr/lib64/firefox/`）と違うが、起動スクリプトと `.desktop` は同じパスなので、アプリ一覧やデフォルトブラウザの設定はそのまま引き継がれる
- 2026-09-25 に入れ直した実機では、プロファイルは `~/.config/mozilla/firefox` に作られた（`~/.mozilla` は無い）

rpmfusion.md と手順 8〜11 の後（コンテナ、2026-09-28）:

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' ffmpeg-libs rpmfusion-free-release epel-release
epel-release 10-6.el10 extras

ffmpeg-libs 7.1.5-1.el10 rpmfusion-free-updates

rpmfusion-free-release 10-1 @commandline

$ ls /usr/lib64/libavcodec.so.*
/usr/lib64/libavcodec.so.61
/usr/lib64/libavcodec.so.61.19.101
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i fusion
gpg-pubkey-db85ddd7-67a63d8b RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org> public key
```

- 有効なリポジトリに `epel` と `rpmfusion-free-updates` が加わる（`rpmfusion-free-updates-testing` の repo ファイルも置かれるが、無効）
- about:support の「コーデックサポート情報」では、H264・HEVC・AAC の「ソフトウェアデコーディング」が「対応」になる（[手順 11 の補足](../firefox.md#実施手順)）

実機（2026-09-28、利用者が手順どおりに入れた後）:

```
$ rpm -q ffmpeg-libs rpmfusion-free-release epel-release
ffmpeg-libs-7.1.5-1.el10.aarch64
rpmfusion-free-release-10-1.noarch
epel-release-10-6.el10.noarch
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i -E 'fusion|epel'
gpg-pubkey-db85ddd7-67a63d8b RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org> public key
gpg-pubkey-e37ed158-65785fa9 Fedora (epel10) <epel@fedoraproject.org> public key
```

- RPM Fusion の有効化で、CRB の `selinux-policy-extra` と `selinux-policy-targeted-extra` も入っている（[rpmfusion.md 手順 3 の補足](../rpmfusion.md#実施手順)）

x86_64 の実機（2026-09-28、rpmfusion.md の手順 1〜3 と手順 8 を実行した後の手順 10）:

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' ffmpeg-libs rpmfusion-free-release epel-release
epel-release 10-8.el10_2 epel

ffmpeg-libs 7.1.5-1.el10 rpmfusion-free-updates

rpmfusion-free-release 10-1 @commandline

$ ls /usr/lib64/libavcodec.so.*
/usr/lib64/libavcodec.so.61
/usr/lib64/libavcodec.so.61.19.101
```

- EPEL が前から入っていたホストなので、`epel-release` の版と `from_repo` はコンテナと違う
- EPEL の `noopenh264` も入っている（[手順 8 の補足](../firefox.md#実施手順)）

Windows 11 で入るもの（winget の定義・Mozilla の文書・Firefox のソースから。Windows では確かめていない）:

- 本体: `C:\Program Files\Mozilla Firefox`。「アプリと機能」の名前は `Mozilla Firefox (x64 ja)`
- サービス: `MozillaMaintenance`（Mozilla Maintenance Service）
- タスク スケジューラの `\Mozilla\`: `Firefox Default Browser Agent <番号>`（インストーラが作る）と `Firefox Background Update <番号>`（Firefox を起動すると作られる）
- ショートカット: デスクトップ・スタートメニュー（ふつうのものとプライベート ブラウジングのもの）・タスクバーのピン留め
- プロファイル: `%APPDATA%\Mozilla\Firefox`（設定・ブックマーク・パスワード）と `%LOCALAPPDATA%\Mozilla\Firefox`（キャッシュ）。ユーザーごとに作られる
- 更新のための作業場所: `C:\ProgramData\Mozilla-1de4eec8-1241-4177-a864-e594e8d1fb38`（Firefox のソースの `commonupdatedir.cpp`）

### 注意点 / 手順 0: 本文中の記録

  - DRM の要る動画は、FFmpeg を入れても直らない（DRM の動画そのものは試していない）

### 参照

- [Install Firefox on Linux — Mozilla Support](https://support.mozilla.org/en-US/kb/install-firefox-linux) — 公式のインストール経路の一覧
- [Introducing Mozilla's Firefox Nightly .rpm package — Firefox Nightly News](https://blog.nightly.mozilla.org/2026/01/19/introducing-mozillas-firefox-nightly-rpm-package-for-rpm-based-linux-distributions/) — RPM リポジトリの repo ファイルの書き方（RHEL / CentOS / Rocky 向けの `tee` の例）と鍵の fingerprint
- [Firefox Developer Edition and Beta: Try out Mozilla's .rpm package! — Mozilla Hacks](https://hacks.mozilla.org/2026/03/firefox-developer-edition-and-beta-try-out-mozillas-rpm-package/) — beta / devedition チャンネルの追加
- [firefox_versions.json — Mozilla product-details](https://product-details.mozilla.org/1.0/firefox_versions.json) — その時点の最新版と ESR の版を機械可読で返す
- [RPM Fusion（free）](../rpmfusion.md) — 手順 8 の前提。鍵の照合と有効化、RPM Fusion の Configuration・keys のページへのリンク
- [Multimedia — RPM Fusion](https://rpmfusion.org/Howto/Multimedia) — `ffmpeg-free` からの切り替え（`dnf swap`）と、`libavcodec-freeworld` の位置づけ
- `man dnf.conf`（`priority`、`gpgcheck`、`repo_gpgcheck`）
- [Full Installer Configuration — Firefox Source Docs](https://firefox-source-docs.mozilla.org/browser/installer/windows/installer/FullConfig.html) — Windows のフルのインストーラのスイッチと既定（場所・ショートカット・Maintenance Service・Default Browser Agent・`/PreventRebootRequired`）
- [Background Updates — Firefox Source Docs](https://firefox-source-docs.mozilla.org/toolkit/mozapps/update/docs/BackgroundUpdates.html) — 閉じている間の更新のタスクと、それが動く条件（Maintenance Service・言語パック）
- [Default Browser Agent — Firefox Source Docs](https://firefox-source-docs.mozilla.org/toolkit/mozapps/defaultagent/default-browser-agent/index.html) — インストーラが作るタスクの中身
- [Set Default — Firefox Source Docs](https://firefox-source-docs.mozilla.org/widget/windows/shell/set-default.html) — Windows で既定のブラウザーにするしかたと UCPD
- Firefox のソース（`release` の枝、2026-10-03）— `browser/installer/windows/nsis/installer.nsi`・`uninstaller.nsi`・`shared.nsh`・`postupdate_helper.nsh`（入れるもの・消すもの・アンインストールの登録）、`dom/media/platforms/wmf/WMFDecoderModule.cpp`（H.264 と AAC の Media Foundation の復号器）、`media/ffvpx/libavcodec/codec_list.c`（同梱の FFmpeg の復号器）、`toolkit/mozapps/update/common/commonupdatedir.cpp`（更新の作業場所）
- [winget-pkgs の `Mozilla.Firefox.ja`](https://github.com/microsoft/winget-pkgs/tree/master/manifests/m/Mozilla/Firefox/ja) — winget の定義（`Mozilla.Firefox` は同じ場所の 1 つ上）
- winget-cli のソース（2026-10-02）— `src/AppInstallerCommonCore/Manifest/ManifestComparator.cpp`（`--locale`）、`src/AppInstallerCLICore/Workflows/UninstallFlow.cpp` と `src/AppInstallerRepositoryCore/Microsoft/ARPHelper.cpp`（アンインストールのコマンドの選び方）
- [Windows で既定のアプリを変更する — Microsoft サポート](https://support.microsoft.com/ja-jp/windows/apps/change-default-apps-in-windows) — 設定の「既定のアプリ」と「既定に設定」
- MDN の [Web video codec guide](https://developer.mozilla.org/en-US/docs/Web/Media/Guides/Formats/Video_codecs)・[Web audio codec guide](https://developer.mozilla.org/en-US/docs/Web/Media/Guides/Formats/Audio_codecs) — Firefox は AVC と AAC を OS の復号器に頼る
- [Windows 11 の初期設定](../windows-setup.md) — この文書の Windows 11 の節の前に通す手順書

### 付録: コンテナでの検証記録（2026-09-22）

実機の設定に触れずに手順を通すため、`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで実行した。実機で加えた変更は `dnf install podman` だけ。 最後にもう 1 つ新しいコンテナを立て、**この文書のコードブロックをそのまま抜き出したスクリプト**（`sudo` を外し、`dnf install` / `dnf upgrade` に `-y` を付けただけ）を流して、上から順に貼れば通ることを確かめている。

手順ごとの結果:

| 手順 | 結果 |
|---|---|
| 2〜3. 鍵 | `gpg --show-keys` の fingerprint が `14F26682D0916CDD81E37B6D61B7B526D98F0353` と一致。`rpm --import` は期限切れ副鍵の warning を出して成功、`gpg-pubkey-d98f0353-55a94004` が登録された |
| 4. repo | メタデータ取得に成功。`firefox` は `154.0.1-1` / `155.0-1` / `155.0.1-1` / `156.0-1` / `156.0.1-1` の 5 世代が aarch64・x86_64 の両方で見えた |
| 5. install | ESR 140.15.0 が入った状態から `dnf upgrade -y firefox` で `156.0.1-1` に載せ替え。追加の依存パッケージ無し |
| 6. 検証 | `firefox --version` → `Mozilla Firefox 156.0.1`、`rpm -qi` の `Signature` は `Key ID 678e455d76767aa3`（Mozilla の署名用副鍵） |
| 言語パック | 未導入のコンテナで `dnf install -y firefox firefox-l10n-ja` → `firefox 156.0.1-1 mozilla` と `firefox-l10n-ja 156.0.1-1 mozilla` が入る |
| ロールバック | repo ファイルを消して `dnf --assumeno distro-sync firefox` → `Downgrading firefox 140.15.0-1.el10_2 appstream` 1 パッケージ |

途中で 1 度、`packages.mozilla.org` の名前解決がコンテナ内でタイムアウトして `dnf` がメタデータ取得に失敗した（`Curl error (6): Could not resolve host`）。同じコマンドの再実行で通ったので、リポジトリ側ではなく一時的なものと判断している。

#### 未確認事項

- 実機の GUI で 156 系を起動したあとの `about:support` の記載（実機では常用しているが、`about:support` の内容を記録していない）
- `firefox-esr`（Mozilla の ESR 153 系）と `firefox-beta` の導入、および AppStream の ESR 140 との共存
- 日本語以外の言語パック、`firefox-devedition`
- ロールバック（`distro-sync` によるダウングレード）の本実行と、その後のプロファイルの読み込み
- Flathub 版との併用時の挙動（`.desktop` の重複、既定ブラウザの選択）

### 付録: 動画が再生できなかった件の切り分け（2026-09-28）

AlmaLinux 10 の Firefox（Mozilla 版 156.0.1）で YouTube の一部の動画が再生できず、同じ動画は Windows の Firefox では再生できた（利用者の報告）。原因を切り分け、RPM Fusion の有効化と手順 8〜11（当時はどちらもこの文書の手順で、手順 8〜14）をコンテナで確かめた記録。

**動画の形式**: watch ページの `ytInitialPlayerResponse` にある `adaptiveFormats` を `curl` で読んだ。同じ日に 2 回読んだところ、形式が変わっていた:

| 読んだとき | 映像 | 音声 |
|---|---|---|
| 1 回目 | 各解像度に H.264（`avc1.4d40xx`）と VP9 | **AAC（itag 140、`mp4a.40.2`）だけ** |
| 2 回目 | 720p 以上は H.264（`avc1.6400xx`）だけ、VP9 は 360p だけ | AAC と Opus（itag 251） |

1 回目の形式では、AAC を復号できない Firefox は音声を再生できない。2 回目の形式なら、FFmpeg が無くても Opus で音声を再生でき、映像は VP9 の 360p か、OpenH264 が落ちていれば H.264 になる。

**Firefox の中身**（実機の `/usr/lib/firefox`）:

- `libmozavcodec.so` を Python の ctypes で読み込んで調べた。`avcodec_version` は 62.29.101、`av_codec_iterate` で列挙したデコーダは `flac mp3 libvorbis pcm_alaw pcm_f32le pcm_mulaw pcm_s16le pcm_s24le pcm_s32le pcm_u8 libopus` だけ
- `libxul.so` の文字列にある読み込み先は、`libavcodec.so.53`〜`libavcodec.so.63` と `libavcodec-ffmpeg.so.56`〜`58`
- 実機には `/usr/lib64/libavcodec*` が無く、プロファイルに OpenH264（`gmp-gmpopenh264`）も無かった

**調べ方**:

- headless の Firefox を `--marionette -remote-allow-system-access` で起動し、Python の標準ライブラリだけで書いた Marionette のクライアントから、ページでスクリプトを動かした（一時プロファイルを使い、日本語 UI にした）
- 素材は RPM Fusion の `ffmpeg` で作った: 3 秒の AAC の m4a、断片化した AAC の m4a、H.264 Main + AAC の mp4、VP9 + Opus の webm、Opus の webm
- 調べたのは次の 5 つ
  - about:support の「コーデックサポート情報」
  - `OfflineAudioContext.decodeAudioData` での AAC の復号
  - MSE（`MediaSource`。YouTube と同じ再生の仕方）での AAC の再生
  - `<video>` での H.264 + AAC の mp4 の再生
  - YouTube の同じ動画（2 回目の形式）がどの形式で再生されるか（`getStatsForNerds().codecs`）
- コンテナは podman（rootless）の `docker.io/library/almalinux:10`（aarch64、2026-09-02 のイメージ）。Firefox は手順 2〜5 と同じ方法で入れた

**結果**:

| 状態 | about:support の H264 / AAC | AAC の復号 / MSE | H.264 + AAC の mp4 | YouTube |
|---|---|---|---|---|
| 実機、何も足さない | 未対応 / 未対応 | `EncodingError` / `addSourceBuffer` が `NotSupportedError` | `NotSupportedError` | — |
| コンテナ、何も足さない（起動直後） | 未対応 / 未対応 | 実機と同じ | `NotSupportedError` | — |
| コンテナ、何も足さない（OpenH264 2.6.0 が落ちた後） | 未対応 / 未対応 | 実機と同じ | 映像は再生された | H.264 1080p60（itag 299）+ Opus で再生された |
| コンテナ、EPEL の `libavcodec-free` 7.1.2 | 対応 / 対応 | 再生できた | `Couldn't open avcodec`（OpenH264 が落ちた後も同じ） | — |
| コンテナ、`ffmpeg-libs` 7.1.5（Firefox を起動し直す前） | 未対応 / 未対応 | 入れる前と同じ | 映像は再生された（OpenH264） | — |
| コンテナ、`ffmpeg-libs` 7.1.5（起動し直した後） | 対応 / 対応（HEVC も対応） | 再生できた | 再生できた | H.264 1080p60（itag 299）+ Opus で再生された |

- OpenH264 2.6.0 は、Firefox を起動して 1 分ほどでプロファイルの `gmp-gmpopenh264` に落ちてきた（`media.gmp-gmpopenh264.enabled` は既定で true）
- 何も足さない状態でも、起動直後は `MediaSource.isTypeSupported('audio/mp4; codecs="mp4a.40.2"')` が true を返した（`addSourceBuffer` は失敗する）。しばらく後は false になった
- EPEL の `libavcodec-free` では、`media.ffmpeg.allow-openh264`（既定で true）により H.264 が `noopenh264` に回る。about:support の「対応」は、復号できることを意味しない
- `ffmpeg-libs` を入れた後、Firefox のプロセスが `/usr/lib64/libavcodec.so.61.19.101` を読み込んでいることを `/proc/<pid>/maps` で確かめた

**文書どおりに通るか**: 新しいコンテナで `gnupg2` だけ先に入れ、この文書の `## 実施手順` の bash ブロックを抜き出したスクリプトを流した。変えたのは、`sudo` を外したことと、`dnf install` に `-y` を付けたことだけで、条件付きの手順 9 は外した。

| 手順 | 結果 |
|---|---|
| 1〜6 | `firefox` と `firefox-l10n-ja` の `156.0.1-1` が入った（197 パッケージ、ダウンロード 226 MB） |
| rpmfusion.md 1・2. 鍵 | fingerprint が `5FC4AE73FC2B08B9DFE7EB990C8489D8DB85DDD7` と一致。`rpm --import` は何も表示せず、`gpg-pubkey-db85ddd7-67a63d8b` が登録された |
| rpmfusion.md 3. リポジトリ | `rpmfusion-free-release 10-1` と、依存の `epel-release 10-6.el10`、弱い依存の `dnf-plugins-core` の 3 パッケージ |
| 8. FFmpeg | `ffmpeg-libs 7.1.5-1.el10` ほか 79 パッケージ（ダウンロード 42 MB、展開後 137 MB）。EPEL の鍵 `0xE37ED158` の取り込みが 1 回あった |
| 9. 衝突 | 別のコンテナで、EPEL の `libavcodec-free` を入れてから手順 8 を実行すると `conflicts with libswresample-free` で止まった。`dnf install --allowerasing ffmpeg-libs` で `libavcodec-free`・`libavutil-free`・`libswresample-free` の 3 つが外れて入れ替わった |
| 10〜11. 確認 | `ffmpeg-libs 7.1.5-1.el10 rpmfusion-free-updates` と `/usr/lib64/libavcodec.so.61`。起動した Firefox で、about:support の H264・HEVC・AAC が「対応」になり、AAC と H.264 の再生も通った |
| ロールバック 1 と rpmfusion.md のロールバック 1〜2 | ロールバックの手順 1 で 78 パッケージ・119 MB が消えた（手順 8 で入ったもののうち `glibc-gconv-extra` だけが残った）。rpmfusion.md のロールバックの手順 1 は `rpmfusion-free-release` の 1 つだけで、`epel-release` と `dnf-plugins-core` は残った。その手順 2 で `gpg-pubkey-db85ddd7-67a63d8b` が消えた |

**x86_64**: `dnf --forcearch=x86_64` で `ffmpeg-libs.x86_64 7.1.5-1.el10` が見えた。空の installroot に `ffmpeg-libs` を入れる解決が、238 パッケージで通った（導入・起動はしていない）。

#### 未確認事項

- 実機（Raspberry Pi 5）への導入と、画面での再生（手順 11 の GUI の確認）
- x86_64 での導入と再生（メタデータのみ）
- 音声が AAC だけの YouTube の動画の再生（YouTube の形式が変わったので、MSE で AAC を流すテストで代えた）
- コマンドの `ffmpeg-free` が入っているホストでの切り替え（RPM Fusion の案内では `dnf swap ffmpeg-free ffmpeg --allowerasing`）
- ハードウェアでの復号（about:support ではすべて「未対応」だった）
- DRM（Widevine）の要る動画
- AppStream の ESR 140 に戻したときに、`~/.config/mozilla/firefox` のプロファイルを読むか

### 付録: 実機での本実行（2026-09-28）

前の付録の後、利用者が実機（2026-09-25 に入れ直した Raspberry Pi 5）で手順どおりに入れ、再生できなかった動画が再生できるようになった。前の付録の未確認事項のうち、実機への導入と再生はこれで済んだ。

**`dnf history`**（時刻は実機の JST）:

| ID | 日時 | コマンド | 結果 |
|---|---|---|---|
| 19 | 2026-09-28 02:13 | `--setopt=localpkg_gpgcheck=1 install https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-10.noarch.rpm` | Success。`rpmfusion-free-release`・`epel-release`（extras）・`selinux-policy-extra`・`selinux-policy-targeted-extra`（crb）の 4 パッケージ |
| 20 | 2026-09-28 02:15 | `install ffmpeg-libs` | Success（7 秒）。60 パッケージ（EPEL 44・AppStream 10・RPM Fusion 4・BaseOS 2） |

- rpmfusion.md 手順 2 の RPM Fusion の鍵（`gpg-pubkey-db85ddd7-67a63d8b`）と、手順 8 で取り込まれた EPEL の鍵（`gpg-pubkey-e37ed158-65785fa9`）が登録されていた
- `libavcodec-free` は入っておらず、`--allowerasing` の実行も無い（手順 9 は要らなかった）
- `dnf repoquery --installed --qf '%{name} %{reason}'` では、`selinux-policy-extra` が `weak-dependency`、`selinux-policy-targeted-extra` が `dependency`。`epel-release` の Recommends の `(selinux-policy-epel if selinux-policy)` を、`selinux-policy-extra` が `selinux-policy-epel` を提供して満たしている

**入れた後の Firefox**（一時プロファイルの headless の Firefox を、前の付録と同じプローブで調べた。利用者のプロファイルには触れていない）:

- about:support の「コーデックサポート情報」は、H264・HEVC・AAC の「ソフトウェアデコーディング」が「対応」。「ハードウェアデコーディング」はすべて「未対応」
- `decodeAudioData` で AAC を復号でき、MSE で AAC を流せた。H.264 + AAC の mp4 も再生できた
- Firefox のコンテンツプロセス 2 つが `/usr/lib64/libavcodec.so.61.19.101` を読み込んでいた

#### 未確認事項

- 音声が AAC だけの YouTube の動画での再生（例の動画は、実機に入れる前に YouTube 側で Opus が足されていた）
- 画面に出した about:support の表示（headless の Firefox でだけ確かめた）
- x86_64 での導入と再生（メタデータのみ）

### 付録: x86_64 の実機での本実行（2026-09-28）

x86_64 の実機（AMD Strix Halo のノート PC）で、YouTube の動画 2 本について利用者から報告があった。1 本目は 360p から上げられず、2 本目は再生できなかった。Firefox は手順 1〜7 の mozilla 版で、FFmpeg は入れていなかった。原因を切り分け、RPM Fusion の有効化（今の rpmfusion.md の手順 1〜3）と、手順 8・10 のコマンド（当時はこの文書の手順 8〜12 と手順 14）を実行した記録（時刻は JST）。

**動画の形式**: 前の付録と同じく、watch ページの `adaptiveFormats` を `curl` で読んだ。どちらもライブ配信のアーカイブで、配信が終わったのは 1 本目が前日の 21:40、2 本目が当日の 02:40:

| 動画 | 読んだとき | 映像 | 音声 |
|---|---|---|---|
| 1 本目 | 02:40 | H.264 は 144p・360p・720p・720p60・1080p60。**VP9 は 360p だけ** | AAC（itag 140）と Opus（itag 251） |
| 1 本目 | 02:54 | H.264 と VP9 が 144p〜1080p60 に揃った | AAC と Opus（itag 249・250・251） |
| 2 本目 | 03:00 | H.264 と VP9 が 144p〜1080p60 に揃っている | **AAC（itag 140）だけ** |

- 1 本目の 02:40 の形式で 360p より上を選ぶには、H.264 を復号できなければならない
- 2 本目は、AAC を復号できなければ再生できない

**利用者の Firefox の状態**（02:40 ごろ。プロファイルとプロセスを読んだだけで、Firefox には触れていない）:

- `/usr/lib64/libavcodec*` が無い
- プロファイルには OpenH264 2.6.0 と Widevine が落ちてきている
- RDD プロセスが読み込んでいたのは同梱の `libmozavcodec.so` だけで、OpenH264 の GMP プロセスは立っていなかった

**FFmpeg を入れる前の再現**: 前の付録と同じく、一時プロファイルの headless の Firefox を Marionette で動かした。OpenH264 が落ちてきた後に起動し直してから調べた。

| 条件 | H.264 の `isTypeSupported` | YouTube の画質の選択肢 | 再生された形式 |
|---|---|---|---|
| 1 本目（02:44） | true | 1080p・720p・360p・144p | 1080p を選ぶと H.264 1080p60（itag 299）+ Opus。コマ落ち 0。GMP プロセスが `libgmpopenh264.so` を読み込んだ |
| 1 本目、利用者の拡張機能 7 つを既定の設定で足した（02:49） | true | 同じ | H.264 1080p60（itag 299）が選ばれた。Enhancer for YouTube が自動再生を止め、再生は始まらなかった |

- Enhancer for YouTube は `MediaSource.isTypeSupported` を包む。形式を隠すのは「60fps 以上を使わない」（`blockhfrformats`）と「WebM を使わない」（`blockwebmformats`）を有効にしたときだけで、利用者の設定ではどちらも false だった
- DRM を有効にして Widevine を落とした一時プロファイルでも、H.264 の `isTypeSupported` は true だった（02:56。FFmpeg を入れた後で、`media.ffmpeg.enabled` を false にして試した）
- 利用者のプロファイルの YouTube の localStorage は、`yt-player-performance-cap` が空で、`yt-player-quality` が 1080 だった
- SELinux の拒否と、Firefox のクラッシュの記録は無かった
- 利用者の Firefox だけが H.264 を使わなかった理由は分からなかった。一時プロファイルとの違いで確かめていないのは、YouTube へのログインと、画面のある（headless でない）Firefox であること

**入れた記録**: dnf は `--assumeno` で表を確かめてから、`-y` を付けて実行した。

| 手順 | 結果 |
|---|---|
| rpmfusion.md 1. 鍵 | fingerprint と uid が一致。このユーザーは `gpg` を初めて使ったので、`~/.gnupg` を作ったという 2 行が先に出た |
| rpmfusion.md 2. 鍵 | `rpm --import` は何も表示せず、`gpg-pubkey-db85ddd7-67a63d8b` が登録された |
| rpmfusion.md 3. リポジトリ | `rpmfusion-free-release 10-1` の 1 パッケージだけ。`epel-release`・`selinux-policy-extra`・`selinux-policy-targeted-extra`・`dnf-plugins-core` は入っていた |
| 8. FFmpeg | `ffmpeg-libs 7.1.5-1.el10` ほか 62 パッケージ（ダウンロード 40 MB、展開後 128 MB）。`noopenh264` も入った。EPEL の鍵は登録済みで、確認は出なかった |
| 9 | 要らなかった（`libavcodec-free` が無い） |
| 10. 確認 | `ffmpeg-libs 7.1.5-1.el10 rpmfusion-free-updates` と `/usr/lib64/libavcodec.so.61` |

**入れた後の確認**（一時プロファイルの headless の Firefox。利用者のプロファイルには触れていない）:

- about:support の「コーデックサポート情報」は、H264・HEVC・AAC の「ソフトウェアデコーディング」が「対応」になった
- `decodeAudioData` で AAC を復号でき（5.06 秒、48 kHz、2 ch）、MSE の `addSourceBuffer` も AAC で通った
- H.264（High）+ AAC の mp4（MDN のサンプルの `flower.mp4`、960x540）が最後まで再生された（150 フレーム、コマ落ち 0）
  - このとき、RDD とユーティリティのプロセスが `/usr/lib64/libavcodec.so.61.19.101` と、`noopenh264` の `/usr/lib64/libopenh264.so.2.4.1` を読み込んだ
  - OpenH264 の GMP プロセスは立たなかった
- 1 本目は、VP9 1080p60（itag 303）+ Opus で再生された（02:54。VP9 が揃った後なので、H.264 は使われていない）
- 2 本目は、VP9 1080p60（itag 303）+ **AAC（itag 140）** で再生された（03:02。23 秒まで再生して 1,381 フレーム、コマ落ち 0）
  - FFmpeg を切った一時プロファイル（`media.ffmpeg.enabled` が false）では、YouTube が「ご利用のブラウザではこの動画を再生できません。」を出した（03:01）
- 利用者が Firefox を起動し直した後（03:02 に起動）、その RDD とユーティリティのプロセスも `/usr/lib64/libavcodec.so.61.19.101` を読み込んでいた

#### 未確認事項

- 起動し直した利用者の Firefox での、2 本の動画の画面での再生と about:support の表示
- 利用者の Firefox で、OpenH264 があるのに H.264 が使われなかった理由
- YouTube（MSE）の H.264 を FFmpeg で復号すること（x86_64。1 本目は、FFmpeg を入れた時点で VP9 が揃っていた）
- ハードウェアでの復号（このホストには VA-API のドライバ `mesa-va-drivers` が入っていない）

### 付録: x86_64 の実機での画面の確認（2026-09-28）

前の付録の後、利用者が Firefox を起動し直し、2 本の動画が画面で再生できることを確かめた（利用者の報告）。前の付録の未確認事項のうち、画面での再生はこれで済んだ。

#### 未確認事項

- 画面に出した about:support の表示（headless の Firefox でだけ確かめた）
- 利用者の Firefox で、OpenH264 があるのに H.264 が使われなかった理由
- YouTube（MSE）の H.264 を FFmpeg で復号すること（x86_64）
- ハードウェアでの復号

---

### 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、winget の定義、配布物、資料とソースを読んだ記録。

#### winget の定義

winget-pkgs の `master`（2026-10-03 16:10 UTC のコミット `c6128933`）を、`manifests/m/Mozilla/Firefox` だけ浅く取った（sparse checkout）:

- `Mozilla.Firefox` と `Mozilla.Firefox.ja` の最新は、どちらも 157.0。Mozilla の `product-details` も、`LATEST_FIREFOX_VERSION` が 157.0、`LAST_RELEASE_DATE` が 2026-09-29 だった
- `manifests/m/Mozilla/Firefox` の下には、版のフォルダーのほかに、`Beta`・`DeveloperEdition`・`ESR`・`MSIX`・`Nightly`・`Unbranded` と、言語ごとのフォルダー（`ja` など）がある
- `Mozilla.Firefox` の定義は、137.0.1 までは `InstallerLocale` の付いたインストーラが 51 個並んでいたが、137.0.2 からは付いていない（英語版だけ）。`Mozilla.Firefox.ja` の定義は 137.0.2 からある（64 版）

`Mozilla.Firefox.ja` 157.0 の `Mozilla.Firefox.ja.installer.yaml`（`Protocols` と `FileExtensions` は省いた）:

```
PackageIdentifier: Mozilla.Firefox.ja
PackageVersion: "157.0"
InstallerType: nullsoft
Scope: machine
InstallerSwitches:
  Silent: /S /PreventRebootRequired=true
  SilentWithProgress: /S /PreventRebootRequired=true
  InstallLocation: /InstallDirectoryPath="<INSTALLPATH>"
UpgradeBehavior: install
ProductCode: Mozilla Firefox
ReleaseDate: 2026-09-29
Installers:
- Architecture: x86
  InstallerUrl: https://download-installer.cdn.mozilla.net/pub/firefox/releases/157.0/win32/ja/Firefox%20Setup%20157.0.exe
  InstallerSha256: D3F2D99344550473B2FE9E9688470B2DF7D89501B6C0AF6243DEAEC689F8AC60
- Architecture: x64
  InstallerUrl: https://download-installer.cdn.mozilla.net/pub/firefox/releases/157.0/win64/ja/Firefox%20Setup%20157.0.exe
  InstallerSha256: B3ADC7530D1B1BC383994239908E06A937AE6D2FF85DEA6C1B609A57FA86B220
- Architecture: arm64
  InstallerUrl: https://download-installer.cdn.mozilla.net/pub/firefox/releases/157.0/win64-aarch64/ja/Firefox%20Setup%20157.0.exe
  InstallerSha256: 6CCED47FC296950E89803A3ACBA480C633370ACD9EAE4648ED3F47550AAC5E6A
ManifestType: installer
ManifestVersion: 1.12.0
```

- `Mozilla.Firefox` 157.0 の定義は、URL の `ja` が `en-US` になっているほかは同じ（`ProductCode` も `Mozilla Firefox`）。言語ごとのフォルダー 100 個の最新の版の定義も、`ProductCode` はどれも `Mozilla Firefox` だった
- `Mozilla.Firefox.MSIX` 157.0 は、`InstallerType: msix`・`PackageFamilyName: Mozilla.MozillaFirefox_jag0gd4e3s9p2` で、URL は `…/157.0/win64/multi/Firefox%20Setup%20157.0.msix`
- scoop の `extras/firefox`（157.0）は、`…/157.0/win64/en-US/Firefox%20Setup%20157.0.exe#/dl.7z`（英語版のインストーラを 7z で展開する）で、`persist` は `distribution`・`profile`

#### インストーラ

x64 の日本語版を取った:

```
$ sha256sum ff-157.0-win64-ja.exe
b3adc7530d1b1bc383994239908e06a937ae6d2ff85dea6c1b609a57fa86b220  ff-157.0-win64-ja.exe
$ grep 'win64/ja/Firefox Setup 157.0.exe' SHA256SUMS
b3adc7530d1b1bc383994239908e06a937ae6d2ff85dea6c1b609a57fa86b220  win64/ja/Firefox Setup 157.0.exe
```

- 大きさは 93,612,392 バイト。sha256 は、winget の定義と、Mozilla の `releases/157.0/SHA256SUMS` の行と一致した
- Authenticode の署名（`osslsigncode verify` は `Succeeded`）: 署名者は `C=US, ST=California, L=San Francisco, O=Mozilla Corporation, OU=Firefox Engineering Operations, CN=Mozilla Corporation`（発行者は `DigiCert Trusted G4 Code Signing RSA4096 SHA384 2021 CA1`）。タイムスタンプは 2026-09-24
- 7z で中を見た（74 ファイル）: `core/maintenanceservice_installer.exe`・`core/maintenanceservice.exe`・`core/default-browser-agent.exe`・`core/updater.exe`・`core/mozavcodec.dll`（同梱の FFmpeg。`Lavc62.29.101`）・`core/wmfclearkey.dll` など
- `core/updater.ini` の文言は日本語（`Title=Firefox の更新`）で、`core/update-settings.ini` は `ACCEPTED_MAR_CHANNEL_IDS=firefox-mozilla-release`

#### Firefox のソースと文書

Firefox のソースは、GitHub の `mozilla-firefox/firefox` の `release` の枝（`browser/config/version.txt` は 157.0.1）を読んだ:

- `browser/installer/windows/nsis/installer.nsi`
  - Maintenance Service は、スイッチで指定が無ければ、管理者で `HKLM` に書けるときだけ入れる（`maintenanceservice_installer.exe`）
  - Default Browser Agent は `default-browser-agent.exe register-task` でタスクを作る。最後に `firefox.exe --backgroundtask install` を動かす
- `browser/installer/windows/nsis/postupdate_helper.nsh`
  - 既定の場所は、管理者なら `$PROGRAMFILES64\Mozilla Firefox\`（64 ビットのビルド）、そうでなければ `%LOCALAPPDATA%\Mozilla Firefox\`
  - Windows 10 以降で既定の場所に入れたときだけ、アンインストールの登録のキーが `…\Uninstall\Mozilla Firefox` になる（ほかは `Mozilla Firefox <版> (<構成> <言語>)`）
- `browser/installer/windows/nsis/shared.nsh`
  - アンインストールの登録の `DisplayName` は `Mozilla Firefox (<構成> <言語>)`（ESR は ` ESR` が入る）
  - 書くのは `UninstallString`（`uninstall\helper.exe`）で、`QuietUninstallString` は書かない。管理者でないときは `HKCU` に書く
- `browser/installer/windows/nsis/uninstaller.nsi`
  - `firefox.exe --backgroundtask uninstall` と `default-browser-agent.exe uninstall` で、Firefox が作ったタスク（Background Update を含む）を消す
  - ほかに Maintenance Service を使う Mozilla のアプリが無ければ、そのアンインストーラを `/S` で動かす
  - 既定のプロファイルがあれば、リフレッシュを勧める。最後に `HKCU\Software\Mozilla\Firefox` に `Uninstalled-release` を書く（次の起動でリフレッシュを勧めるため）
- `dom/media/platforms/wmf/WMFDecoderModule.cpp`: H.264 は `CLSID_CMSH264DecoderMFT`、AAC は `CLSID_CMSAACDecMFT` で作る。MP3 には Media Foundation を使わない（「Always use ffvpx for mp3」）
- `media/ffvpx/libavcodec/codec_list.c`: 同梱の FFmpeg の復号器は、VP8・VP9・FLAC・MP3・AV1（libdav1d と内蔵のもの）・Vorbis・Opus・PCM と、Android の MediaCodec のもの（AAC・H.264・HEVC など）だけ
- `toolkit/mozapps/update/common/commonupdatedir.cpp`: 更新の作業場所は `C:\ProgramData\Mozilla-1de4eec8-1241-4177-a864-e594e8d1fb38`

Mozilla の文書（firefox-source-docs）:

- Full Installer Configuration: どのスイッチを付けても画面を出さずに入れる。タスクバーのピン留め・デスクトップ・スタートメニュー・プライベート ブラウジングのショートカット、Maintenance Service、Default Browser Agent のタスクは、どれも既定で有効。`/PreventRebootRequired=true` を付けて動いている Firefox に重ねて入れると、入れ替えが途中で終わることがある
- Background Updates: 閉じている間の更新は Windows だけで、既定は 7 時間ごと。条件は、`app.update.background.enabled` と `app.update.auto` が true、インストーラで入れたもの、書き込めるか Maintenance Service が使えること、プロキシの設定が無いこと、言語パックが無いこと など
- Default Browser Agent: タスクは `Mozilla` のフォルダーに、入れた Firefox ごとに 1 つ作られ、24 時間ごとに動く。インストーラを動かしたユーザーとして、昇格せずに動く
- Set Default: まず `UserChoice` を書こうとし、できなければ Windows の設定を開く。UCPD は `http`・`https`・`.pdf` の `UserChoice` の書き換えを止める（`htm`・`html` は対象外）。Windows 11 の設定には「既定に設定」のボタンがある

日本語の訳（`mozilla-l10n/firefox-l10n` の `main` の `ja`）: about:support の「アプリケーション基本情報」「更新チャンネル」「プログラムの実行ファイル」「コーデックサポート情報」「ソフトウェアデコーディング」「対応」、設定の「既定のブラウザー」「既定のブラウザーにする」。

Mozilla のサポート（support.mozilla.org）は、JavaScript の確認の画面が返ってきて読めなかった（curl と WebFetch）。

#### winget のソース

winget-cli の `master`（2026-10-02 のコミット `39739564`）を読んだ:

- `src/AppInstallerCommonCore/Manifest/ManifestComparator.cpp` の `LocaleComparator`
  - `--locale` を付けると、それが「要件」になり、インストーラの言語と完全に合う（`MinimumDistanceScoreAsPerfectMatch` 以上）ものだけが候補に残る
  - 言語の無いインストーラをそのまま許すのは、入れた後の更新で前の言語を引き継ぐときだけ。言語の無いインストーラと `ja` の距離を出す `GetDistanceOfLanguage` は読んでいない
- `src/AppInstallerCLICore/Workflows/UninstallFlow.cpp`: NSIS（`Nullsoft`）で入れたものは、`SilentUninstallCommand` があればそれを、無ければ `StandardUninstallCommand` を使う
  - `src/AppInstallerRepositoryCore/Microsoft/ARPHelper.cpp` で `SilentUninstallCommand` を作るのは、アンインストールの登録の `QuietUninstallString` だけ
- `src/AppInstallerCLICore/Argument.cpp`: `winget list` の `--upgrade-available`

#### Microsoft の文書と MDN

- 「Windows で既定のアプリを変更する」（日本語）: 設定アプリで [アプリ>既定のアプリ] → [アプリケーションの既定の設定] で Microsoft Edge を選ぶ → [Microsoft Edge を既定のブラウザーにする] の横の [既定に設定]。[Windows 11 で使う](../firefox.md#windows-11-で使う)の手順 5 は、これを Firefox に読み替えた
- MDN の Web video codec guide は「Firefox support for AVC is dependent upon the operating system's built-in or preinstalled codecs」、Web audio codec guide は「Firefox relies upon a platform's native support for AAC」と書いている

---

### 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-03）

Linux（クラウドのコンテナ）の PowerShell 7.6.6（GitHub のリリースの `powershell-7.6.6-linux-x64.tar.gz`）と PSScriptAnalyzer 1.25.0 で確かめた。

**構文と Windows PowerShell 5.1 との互換**:

- Windows 11 の 3 節の `powershell` のブロック 6 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0 で、既定の規則の指摘も 0
  - わざと PowerShell 7 だけの書き方（`??`、`Get-Content -AsByteStream`）を入れたファイルでは、それぞれ指摘が出た
- `winget` はコマンドレットではないので、引数はこの検査の対象外。`winget list` の `--upgrade-available` は winget のソースで確かめた。ほかの引数は [Windows 11 の初期設定](../windows-setup.md)の winget と同じ形

**偽物のコマンドで流した**: 6 個のブロックを、`Get-ItemProperty`・`Get-AppxPackage`・`winget`・`Get-Item`・`Get-Service`・`Get-ScheduledTask`・`Test-Path` を「渡された引数を記録し、決まった値を返す偽物」にして流した。

- [Windows 11 で使う](../firefox.md#windows-11-で使う)の手順 2: アンインストールの登録の偽物（`Mozilla Firefox (x64 ja)`・`Mozilla Maintenance Service`・`Git`・表示名の無いもの）から、`Mozilla Firefox (x64 ja)` の行だけが出た
- どのブロックでも、`winget` に渡る引数と、`$env:ProgramFiles` から組み立てるパス（`C:\Program Files\Mozilla Firefox\firefox.exe`）が本文のとおりだった
- 本物の Windows の出力（winget の表示、サービスとタスクの有無）は確かめていない

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. winget が x64 の日本語版を選んで `C:\Program Files\Mozilla Firefox` に入れ、Maintenance Service と Default Browser Agent のタスクができること
1. about:support の表示と、H.264・AAC の動画の再生
1. 設定の画面の名前（「既定のアプリ」「既定に設定」）と、既定のブラウザーが Firefox になること。最初の起動で Firefox が既定のブラウザーにするかを聞くこと
1. Firefox 自身の更新（起動している間と、閉じている間の Background Update）と、`winget upgrade`
1. `winget uninstall` で窓が出ること、消えるもの・残るもの、外した後の既定のブラウザー
1. `winget upgrade --all` などで、英語版の `Mozilla.Firefox` と取り違えないこと
1. arm64 の Windows、N エディション

### 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を新規に入れた x86_64 の VirtualBox VM（1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で確認した。シェルのブロックは手順書から抜き出して、検証用ユーザーの SSH の対話シェルへ個別に貼った。GUI はヘッドレスの GNOME に 1920x1080 の仮想モニターを付け、既存の `scripts/gnome-gui.py` を変更せずコピーして、操作の後に撮った PNG を見た。利用者のアカウントは使っていない。

実施手順 1〜8・10・11 を本実行した。手順 8 が衝突せず通ったため、条件付きの手順 9 は省略した。AppStream の ESR `140.16.0-1.el10_2` から Mozilla の `157.0-1` と `firefox-l10n-ja-157.0-1` に載せ替わり、Vendor と導入元は Mozilla。GUI の `about:support` は日本語で、更新チャンネル `release`、実行ファイル `/usr/lib/firefox/firefox-bin`、H264 と AAC のソフトウェアデコーディング「対応」だった。

前提の EPEL と RPM Fusion free もこの VM で通し、`ffmpeg-libs-7.1.5-1.el10` を入れた。隔離した検証プロファイルの GUI（headless オプション無し）で、MDN の `flower.mp4`（H.264 High + AAC LC、960x540）をローカルから再生した。画面に花の動画が写り、Marionette で `paused=false`・`error=null`、復号フレームが 8 → 750 に増えたことを確認した。`canPlayType` は H.264 と AAC の両方が `probably`。VM には音声の出力デバイスが無く、耳で音を聴く確認とハードウェアデコードはしていない。

動画の形式を調べるためだけに、検証用の `ffmpeg` CLI（6 RPM）も追加した。Firefox の導入手順に必要なのは `ffmpeg-libs` で、CLI は手順の前提に足していない。プローブが `about:support` を読む起動にだけ `--marionette --remote-allow-system-access` を使い、通常の Firefox の設定には足していない。監査ログファイルを指定した AVC の照合は `<no matches>` だった。Windows の節、Web サービスへのサインイン、音声の実出力は未確認。

続けてロールバック 1〜5 を本実行した。`ffmpeg-libs` と検証用 CLI・ほかで使われていない依存が削除され、言語パックを外してから `distro-sync firefox` で `140.16.0-1.el10_2` に戻った。Mozilla の repo と署名鍵も削除できた。新しい版のプロファイルを古い版で開くことは確認せず、動画の確認に使った隔離プロファイルを保持した。

---

### 付録: 現行版の新規 VM での再検証（2026-10-06）

**環境と流し方**: `5da3478` の現行手順を、別のクリーンな AlmaLinux 10.2 Workstation / x86_64 の VM（1 vCPU、SELinux Enforcing、firewalld 稼働、US 配列）で実行した。SSH の一般ユーザーの対話 PTY に折り畳みの外のブロックを手順ごとに貼り、応答とプロンプトを待った。GUI は GNOME 49.4 のヘッドレスセッションに仮想モニターを付け、操作後の PNG を目視した。既存の実機・資格情報は使っていない。

実施手順 1〜8・10 と GUI の起動を実行した。8 が衝突せず通ったため条件付きの 9 は省略した。OS の ESR `140.16.0-1.el10_2` から Mozilla の `157.0-1` / 日本語言語パックに切り替わり、鍵の指紋・導入元・依存関係を確認した。更新も成功し変更は無かった。

codec 確認では、MDN の `flower.mp4`（検証用の ffprobe で H.264 High + AAC LC と確認）を隔離プロファイルの通常 GUI で再生した。花の動画が画面に映り、Marionette で `error=null`、復号フレームが `147` → `656` に増え、再生時刻が進むことを確認した。H.264 / AAC の `canPlayType` は両方 `probably`。追加の AAC デコードは Web Audio で 2 チャンネル・44100 Hz・222970 サンプルになった。ただしこの素材の観測ピークは 0 で、耳で音を聴く試験はしていない。今回の手順 11 はこの実デコード・再生の観測で検証し、codec 導入後の about:support 表の再取得はしていない。

ロールバック 1〜5 を実行し、`ffmpeg-libs`・形式確認のためだけに追加した `ffmpeg` CLI と未使用依存、日本語言語パック、Mozilla repo / 鍵を削除した。`distro-sync` で ESR `140.16.0-1.el10_2` に戻った。隔離プロファイルは古い Firefox で開いていない。ハードウェアデコード、音声の実出力、既定ブラウザー変更、Web サービスへのサインイン、Windows は今回実施していない。

### 手順中の実測・検証状況の記録

- 企業ポリシーで ESR を使っている場合は、この手順を使わない。Mozilla の ESR / Beta の配布は調べたが、導入・更新・ロールバックは未検証

### 手順中の実測・検証状況の記録

- **AAC と H.264 のために足すものは無い**: Windows の Media Foundation で復号する（[Windows 11 で使う](../firefox.md#windows-11-で使う)の手順 4 の補足）。N エディションの Windows では、Media Feature Pack が要るはず（確かめていない）

### 実施手順 / 手順 4: 補足: priority は保険

Mozilla の案内する repo ファイルには `priority` が無い。この環境では `priority=10`（数字が小さいほど優先）を足しているが、**あってもなくても解決結果は変わらなかった**。ESR 140 と最新版 156 では後者のバージョンが高く、dnf はリポジトリの優先度ではなくバージョンで選ぶため:

```
$ dnf install --assumeno firefox          # priority 行を書く前
Installing:
 firefox        aarch64  156.0.1-1   mozilla   107 M
$ printf 'priority=10\n' >> /etc/yum.repos.d/mozilla.repo
$ dnf install --assumeno firefox          # priority=10 を足した後
Installing:
 firefox        aarch64  156.0.1-1   mozilla   107 M
```

### 手順中の検証状況

- **注意**: 画面の名前は、Microsoft のサポートの記事（Edge を既定にする例）と Firefox の日本語の訳から取った。Windows の画面では確かめていない

### 手順中の検証状況

- 既定のブラウザーは、Firefox を外すと Windows が戻す（Microsoft Edge になるはず。確かめていない）。別のブラウザーにするなら、この節の手順 3

### 手順中の検証状況

- **英語版の `Mozilla.Firefox` と同じ `ProductCode`**: winget の定義では、`Mozilla.Firefox` と言語ごとの `Mozilla.Firefox.<言語>`（100 個）の `ProductCode` が、どれも `Mozilla Firefox` になっている。`winget upgrade --all` や UniGet UI の一括の更新で取り違えないかは、確かめていない

### 手順内の実測・検証状況

- **更新のたびに 107 MB 落ちてくる**: 4 週間ごとの Rapid Release なので、従量課金の回線では効いてくる

### Windows 11 で使う / 手順 4: 補足: Windows では AAC と H.264 のために何も足さない理由

- Mozilla のサポートの記事（support.mozilla.org）は、この文書を書いた環境からは読めなかった。Windows で再生しては確かめていない

- N エディションの Windows（メディアの機能が入っていない）では、Microsoft の Media Feature Pack が要るはず（確かめていない）

### Windows 11 の更新 / 手順 2: 補足: winget での更新

- winget の定義は、Mozilla が新しい版を出してから、winget-pkgs に定義が足されたときに上がる（どれだけ遅れるかは確かめていない）。Firefox 自身の更新の方が先に上がることもある

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 補足

- **aarch64 の Firefox には Widevine が無い**: Firefox 156（aarch64）には `media.gmp-widevinecdm.*` の設定が無く、`media.eme.enabled` も既定で false だった

---

### 付録: Windows 11 Pro の VM での新規導入の検証（2026-10-06）

[Windows 11 の初期設定](windows-setup.md#付録-windows-11-pro-の-vm-での導入検証2026-10-06)を検証中の専用 VM で、[Windows 11 で使う](../firefox.md#windows-11-で使う)の手順 2・3 のコードブロックを抜き出して、そのまま実行した。画面で端末を開いて貼る操作は試していない。

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro 26H2 / ビルド 26300.9457 / x64 |
| VM | VirtualBox 7.2.20。Rufus で作った媒体からクリーンインストールした専用 VM |
| PowerShell | Windows PowerShell 5.1.26100.9444 / Desktop / x64。ログオン中のユーザーの管理者権限（Session 1） |
| WinGet | 1.29.380。`Mozilla.Firefox.ja` を `--source winget` で新規導入 |
| 検証時の本文の SHA256 | `421701DAB73DA6AD10A0DCEBEF0E88692A382107A6A8086CA54F66C98E55E331`（この追記より前） |
| 抜き出したブロックの manifest の SHA256 | `D294CB1ACBECD20715E47E6EF19194F41248360171544A2713E347CA896D926A` |

**確認したこと**（バッチ `20261006-110251Z-aa3cdf07`、完了 11:03:25 UTC）:

- 手順 2 は出力がなく、`HKLM`・`HKCU` のアンインストール登録と Mozilla の Appx パッケージは見つからなかった
- 手順 3 は x64 の日本語版 `Firefox Setup 157.0.exe` を取り、インストーラーのハッシュ検証が成功し、`Successfully installed` が出た
- 続く一覧は `Mozilla Firefox (x64 ja) / Mozilla.Firefox.ja / 157.0`。`C:\Program Files\Mozilla Firefox\firefox.exe` の `ProductVersion` も `157.0` だった
- `MozillaMaintenance` サービスは `Stopped / Manual`、`Firefox Default Browser Agent 308046B0AF4A39CB` のタスクは `Ready` だった
- PowerShell のエラーは 0、最後の終了コードと検証用タスクの終了コードは 0。要求したバッチと完了記録が対応した

**確認していないこと**:

- 手順 1 の端末を開く画面操作。検証用の起動処理で代替した
- 手順 4 の起動と `about:support`。画面の言語、Release チャンネル、H.264・AAC の対応表示と実際の動画の再生
- 手順 5 の既定のブラウザーへの切り替え。Default Browser Agent のタスクがあることだけでは、Firefox が既定になったと判定しない
- ショートカット、プロファイル、Background Update のタスク、Firefox 自身の更新、`winget upgrade`、アンインストール、arm64 の Windows、N エディション
