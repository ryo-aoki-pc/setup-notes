# Firefox 最新版インストール手順（AlmaLinux 10 は Mozilla 公式 RPM リポジトリ / Windows 11 は winget）のロールバックと注意点

[手順書](../firefox.md)・[検証記録](../verification/firefox.md)・[参考資料](../reference/firefox.md)

- 「手順 N」は[手順書](../firefox.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

> [!WARNING]
> **ダウングレードした Firefox は、新しいプロファイルを読めないことがある**（[注意点](#注意点)）。

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)
- RPM Fusion の FFmpeg を外し、AppStream の ESR に戻す
- AAC・H.264 のための FFmpeg だけ外すなら、この節の手順 1 だけ行う。RPM Fusion 自体も外すなら、続けて [AlmaLinux 10 の初期設定のロールバック](almalinux-setup.md#ロールバック)の手順 32・33 を行う
- EPEL は外さない（[btop.md](../btop.md) などほかの手順書でも使う。外すなら [AlmaLinux 10 の初期設定のロールバック](almalinux-setup.md#ロールバック)の手順 34・35）
- プロファイル（`~/.mozilla/firefox`、新しく作られた場合は `~/.config/mozilla/firefox`）は、この節のどの手順でも消えない

1. FFmpeg のライブラリを消す。

   ```bash
   sudo dnf remove ffmpeg-libs
   ```

   - 手順 8 で一緒に入った依存も、ほかに使うものが無ければ一緒に消える
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. Mozilla の repo ファイルを消す。

   ```bash
   sudo rm -f /etc/yum.repos.d/mozilla.repo
   ```

1. AppStream に無い言語パックを、ダウングレードより先に消す。

   ```bash
   sudo dnf remove ${FF_L10N}                    # 言語パックは AppStream に無いので先に消す
   ```

   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. Firefox を AppStream の ESR（140 系）にダウングレードする。

   ```bash
   sudo dnf distro-sync "${FF_PKG}"              # 140 系へダウングレードされる
   ```

   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. Mozilla の鍵も消すときだけ、その署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-d98f0353-55a94004
   ```

---

## Windows 11 のロールバック

- この節の手順 1・2 は、管理者の Windows PowerShell（5.1）に貼る
- **この節の手順 1 で、Firefox のアンインストールの窓が開く**（winget は Firefox のアンインストーラを、画面を出したまま起動する）
- プロファイル（`%APPDATA%\Mozilla\Firefox` と `%LOCALAPPDATA%\Mozilla\Firefox`）は、この節のどの手順でも消えない
  - 入れ直すと、同じプロファイルを使う（最初の起動で「Firefox をリフレッシュ」を勧められることがある）
  - 要らなければ手で消す（取り戻せない。ブックマークと保存したパスワードも消える）
- 既定のブラウザーは、Firefox を外すと Windows が戻す（Microsoft Edge になるはず）。別のブラウザーにするなら、この節の手順 3

1. Firefox をすべて閉じてから、winget でアンインストーラを起動する。

   ```powershell
   winget uninstall --exact --id Mozilla.Firefox.ja --source winget
   ```

   - Firefox のアンインストールの窓が開くので、案内に沿ってアンインストールを選び、最後に「完了」を押す
   - 「Firefox をリフレッシュ」を勧める画面が出ても、リフレッシュは選ばない（プロファイルを作り直すだけで、Firefox は消えない）
   - **次の手順は、アンインストールの窓で「完了」を押してから貼る**（winget が先に終わっても、窓が閉じるまでは消し終わっていない）

1. Firefox が消えたことを確かめる。

   ```powershell
   winget list --exact --id Mozilla.Firefox.ja --source winget
   Test-Path -LiteralPath "$env:ProgramFiles\Mozilla Firefox"
   Get-Service -Name MozillaMaintenance -ErrorAction SilentlyContinue | Format-Table Name, Status
   Get-ScheduledTask -TaskPath '\Mozilla\' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   ```

   - `winget list` が見つからない旨を出し、`False` が出て、最後の 2 つが何も出さなければよい
   - Firefox が自分で更新した PC では、`C:\Program Files\Mozilla Firefox` に `update_telemetry.json` だけが残り、`True` になることがある。中がそれだけなら、フォルダーごと手で消してよい
   - `MozillaMaintenance` が残るのは、Thunderbird などほかの Mozilla のアプリが使っているとき

1. 別のブラウザーを既定にするときだけ、Windows の設定で既定にする。

   - 設定 →「アプリ」→「既定のアプリ」で使うブラウザーを選び、「既定値に設定」を押す（[Windows 11 で使う](../firefox.md#windows-11-で使う)の手順 5 と同じ操作）

---

## 注意点

- **チャンネルが変わる**: ESR（年 1 回のメジャー更新）から Rapid Release（4 週間ごと）に移る
  - 企業ポリシーで ESR を使っている場合は、この手順を使わない
- **セキュリティ更新の出所が変わる**: AppStream 版は AlmaLinux が、mozilla 版は Mozilla が直接出す
  - `dnf upgrade` の対象になるのは同じだが、AlmaLinux のエラータ（`dnf updateinfo`）には載らない
- **ダウングレードするとプロファイルを読めないことがある**: 156 で開いたプロファイルを 140 で開くと、「新しいバージョンの Firefox で作成されたプロファイル」と警告が出る
  - 戻す前提があるなら、先に `~/.mozilla/firefox`（新しく作られた場合は `~/.config/mozilla/firefox`）を退避しておく
- **言語パックは本体と同時に上げる**: バージョンが食い違うと UI が英語に戻る。`dnf upgrade` 全体を流していれば自動で揃う
- パッケージの導入・削除が終わったことを確かめる
- **RPM Fusion は Fedora の外のリポジトリ**: free は「Fedora がライセンス以外の理由で配れないオープンソースのソフト」を配る（RPM Fusion の Configuration の説明）
  - 鍵の照合と、`rpmfusion-free-release` の署名の確かめ方は [AlmaLinux 10 の初期設定の手順 18〜21](../almalinux-setup.md#実施手順) にある
- **FFmpeg を入れたら Firefox を起動し直す**: 起動中の Firefox は読み直さない（手順 11）
- **EPEL の `libavcodec-free` とは同居できない**: 入っていると手順 8 が止まる。残したままだと H.264 が再生できない（手順 9）
- **aarch64 では Widevine を必要とするコンテンツの再生を前提にしない**
- **Windows 11 の注意点**
  - **AAC と H.264 のために足すものは無い**: Windows の Media Foundation で復号する（[Windows 11 で使う](../firefox.md#windows-11-で使う)の手順 4 の補足）。N エディションの Windows では、Media Feature Pack が要るはず
  - **管理者の PowerShell から Firefox を起動しない**: Firefox が管理者の権限で動き、プロファイルに管理者の持ち物のファイルができうる。起動はスタートメニューから
  - **言語パックを足さない**: 閉じている間の更新（Background Update）が止まる。別の言語にしたいなら、その言語の `Mozilla.Firefox.<言語>` を入れ直す
  - **Firefox を開いたまま `winget upgrade` しない**: 入れ替えが途中で終わることがある（[Windows 11 の更新](../firefox.md#windows-11-の更新)の手順 2 の補足）
  - **英語版の `Mozilla.Firefox` と同じ `ProductCode`**: winget の定義では、`Mozilla.Firefox` と言語ごとの `Mozilla.Firefox.<言語>` の `ProductCode` が同じ。言語を指定して更新する
  - **アンインストールで窓が出る**: `winget uninstall` でも、Firefox のアンインストーラが画面を出す（[Windows 11 のロールバック](#windows-11-のロールバック)の手順 1 の補足）
