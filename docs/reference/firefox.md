# Firefox 最新版インストール手順（AlmaLinux 10 は Mozilla 公式 RPM リポジトリ / Windows 11 は winget）の参考資料

[手順書](../firefox.md)

## 補足

### 実施手順 / 手順 4: 補足: priority は保険

[この節の検証記録](../verification/firefox.md#実施手順--手順-4-補足-priority-は保険)

Mozilla の案内する repo ファイルには `priority` が無い。`priority=10`（数字が小さいほど優先）は、将来のリポジトリ間の優先順位に備えて足している。

将来 AppStream 側の ESR が Mozilla 側の版を追い越す状況（Mozilla 側でリリースが巻き戻る、ESR が別番号体系になる、など）に備えた保険として残している。

`repo_gpgcheck=0` は Mozilla の案内どおりで、**パッケージの署名は検証する（`gpgcheck=1`）がリポジトリメタデータには署名が無い**、という意味。

このリポジトリは `baseurl` に `$basearch` を含まない**全アーキテクチャ共通**の作りなので、`dnf list` には `firefox.x86_64` の行も出る。インストールされるのは実行中のアーキテクチャのものだけ。

### Windows 11 で使う / 手順 4: 補足: Windows では AAC と H.264 のために何も足さない理由

[この節の検証記録](../verification/firefox.md#windows-11-で使う--手順-4-補足-windows-では-aac-と-h264-のために何も足さない理由)

- Firefox の Windows 版は、H.264 を `CLSID_CMSH264DecoderMFT`、AAC を `CLSID_CMSAACDecMFT` で復号する。どちらも Windows の Media Foundation に入っている復号器（Firefox のソースの `dom/media/platforms/wmf/WMFDecoderModule.cpp`）
- 同梱の FFmpeg（`mozavcodec.dll`）のソフトウェアの復号器に、AAC と H.264 は無い（ソースの `media/ffvpx/libavcodec/codec_list.c`。あるのは Android の MediaCodec を使うものだけ）
  - Linux では、そこを OS の FFmpeg で補う。そのため、AlmaLinux 10 では[実施手順](../firefox.md#実施手順)の手順 8〜11 が要る（[選択した方針](#選択した方針)）
- MDN も、Firefox は AVC（H.264）と AAC を OS の復号器に頼ると書いている

- N エディションの Windows（メディアの機能が入っていない）では、Microsoft の Media Feature Pack が必要になる可能性がある

### Windows 11 で使う / 手順 5: 補足: コマンドで変えない理由

- Windows は既定のブラウザーを、`HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\<プロトコル>\UserChoice` にハッシュ付きで記録する。今の Windows 11 では、User Choice Protection Driver（UCPD）が `http`・`https` の `UserChoice` の書き換えを止める
- Firefox も、まず自分で `UserChoice` を書こうとし、できなければ Windows の設定の「既定に設定」の画面を開く（Mozilla の Set Default の文書）。そのため、本書は初めから設定の画面で行う
- 確かめを Win+R から開くのは、管理者の PowerShell から URL を開くと、Firefox が管理者の権限で起動するため
- Claude Code の `/login` は、既定のブラウザーでログインのページを開く。[Windows 11 の初期設定](../windows-setup.md)の後に通す順で、Claude Code より先にこの手順を行うのはそのため

### Windows 11 の更新 / 手順 2: 補足: winget での更新

[この節の検証記録](../verification/firefox.md#windows-11-の更新--手順-2-補足-winget-での更新)

- winget の定義の `UpgradeBehavior` は `install`。今の Firefox を消さずに、同じ場所へ新しい版のインストーラを重ねて入れる。プロファイルと既定のブラウザーの設定はそのまま
- winget が渡す `/PreventRebootRequired=true` は、使用中のファイルがあっても再起動が要る処理をしないスイッチ。Mozilla の文書は、動いている Firefox に重ねて入れるときにこれを付けると、入れ替えが途中で終わることがあると書いている
- winget の定義は、Mozilla が新しい版を出してから、winget-pkgs に定義が足されたときに上がる。Firefox 自身の更新の方が先に上がることもある

### Windows 11 のロールバック / 手順 1: 補足: 窓が出る理由と、アンインストーラが消すもの

- winget は、NSIS のインストーラで入れたものを、アンインストールの登録の `QuietUninstallString`（画面を出さずに消すコマンド）で消し、それが無ければ `UninstallString` で消す（winget のソースの `UninstallFlow.cpp`）
- Firefox が書くのは `UninstallString`（`C:\Program Files\Mozilla Firefox\uninstall\helper.exe`）だけなので、ふだんのアンインストールと同じ窓が出る（Firefox のソースの `shared.nsh`）
- アンインストーラは、Firefox のタスク（Default Browser Agent と Background Update）を消し、ほかに使う Mozilla のアプリ（Thunderbird など）が無ければ Mozilla Maintenance Service も外す（Firefox のソースの `uninstaller.nsi`）
- 入れ直したときのリフレッシュの勧めは、アンインストーラが `HKCU\Software\Mozilla\Firefox` に残す `Uninstalled-release` の値による（同じソース）

### 選択した方針

[この節の検証記録](../verification/firefox.md#選択した方針)

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Mozilla 公式 RPM リポジトリ** | `packages.mozilla.org/rpm/firefox` に `firefox` 156.0.1 / `firefox-esr` 153.3.0esr / `firefox-beta` 157.0b4 と各言語パックがあり、**aarch64 と x86_64 の両方**が揃っている。dnf 管理で更新できる | **採用** |
| AppStream の `firefox` | 140.15.0（ESR 140 系）。AlmaLinux がセキュリティ更新を出すが、最新版の機能は入らない | 不採用（最新版ではない） |
| Flathub の `org.mozilla.firefox` | Mozilla 公式ビルド。flathub と runtime の導入が必要で、RPM と二重管理になる | 不採用（RPM で足りる） |
| 公式 tarball を `/opt` に展開 | `linux-aarch64` のビルドが公式にある（Firefox 136 以降）。更新は Firefox 内蔵のアップデータ任せで、`.desktop` を自作する必要がある | 不採用（dnf で管理できない） |
| ソースビルド | 実用的でない | 不採用 |

**AAC と H.264 を OS の FFmpeg で補う理由**:

| 経路 | AAC | H.264 | 採否 |
|---|---|---|---|
| 何も足さない | 再生できない | OpenH264 が落ちるまでは再生できない。落ちた後は再生できる | —（元の状態） |
| **RPM Fusion（free）の `ffmpeg-libs` 7.1.5** | 再生できる | 再生できる（FFmpeg で復号） | **採用** |
| EPEL の `libavcodec-free` 7.1.2 | 再生できる | **再生できない**。H.264 を OpenH264 に任せる作りで、EL10 には中身の無い `noopenh264` しか無い。about:support には「対応」と出るのに `Couldn't open avcodec` で止まり、落ちてきた OpenH264 にも切り替わらない | 不採用 |
| RPM Fusion の `libavcodec-freeworld` | — | — | 不採用（EPEL の `ffmpeg-free` を使い続けるときに足すもの。RPM Fusion の Howto/Multimedia の案内による） |

- RPM Fusion の EL 10 向けには、`ffmpeg-libs` 7.1.5 が aarch64 と x86_64 の両方にある
- RPM Fusion は EPEL を前提にしている（`rpmfusion-free-release` が `epel-release` を要求する）

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `Mozilla.Firefox.ja` を PC 全体に** | 157.0。Mozilla の CDN の日本語版の NSIS インストーラ（x64・x86・arm64）を、winget が sha256 を確かめて画面を出さずに入れる。`Scope` は `machine` だけ。Maintenance Service が入り、以後は Firefox が自分で更新する | **採用** |
| winget の `Mozilla.Firefox` に `--locale ja` | 137.0.1 までは言語ごとのインストーラ（`InstallerLocale`）が 51 あったが、137.0.2 から英語（en-US）だけになり、言語ごとに `Mozilla.Firefox.<言語>` に分かれた。言語の無いインストーラは、`--locale` を付けると候補から外れるので、入らないはず | 不採用 |
| `Mozilla.Firefox`（英語版）に日本語の言語パック | 言語パックがあると、閉じている間の更新（Background Update）が動かない（Mozilla の文書）。本体と版を揃える必要もある（AlmaLinux 10 の[注意点](../firefox.md#注意点)と同じ） | 不採用 |
| winget の `Mozilla.Firefox.MSIX`・Microsoft Store 版 | MSIX（言語は multi）で、パッケージのアプリ（`Mozilla.MozillaFirefox`）として入る | 不採用（Mozilla の通常のインストーラと、Firefox 自身の更新にそろえた） |
| scoop の `extras/firefox` | 157.0。英語版のインストーラを 7z で展開するだけのポータブル版で、プロファイルは scoop の `persist` に作る | 不採用（日本語版でなく、PC 全体にも入らない） |
| Mozilla のサイトからインストーラを落として実行 | 同じものが入るが、ダウンロードと実行が画面の操作になる | 不採用（winget で同じインストーラが入る） |

- **PC 全体（`machine`）に入れた**: winget の定義が `machine` しか持たない。AlmaLinux 10 の dnf と同じく、PC の全ユーザーで 1 つの Firefox を使い、更新は Maintenance Service で管理者の確認なしに行える
  - Mozilla のインストーラは、管理者の権限が無いまま入れると `%LOCALAPPDATA%\Mozilla Firefox` に入れ、Maintenance Service は入れない（Firefox のソースの `installer.nsi`・`postupdate_helper.nsh`）。winget の定義では、この形は選べない
- **日本語版（`.ja`）にした**: 言語パックが要らないので、AlmaLinux 10 の「言語パックは本体と同時に上げる」（[注意点](../firefox.md#注意点)）に当たる注意が無く、閉じている間の更新も動く
- **既定のブラウザーは、Windows の設定の画面で変える**: 今の Windows 11 では、`http`・`https` の既定をコマンドで書き換えられない（[Windows 11 で使う](../firefox.md#windows-11-で使う)の手順 5 の補足）
- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた

### 参照

---
