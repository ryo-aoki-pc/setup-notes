# Windows 11 の初期設定の手順（インストール直後の更新・貼り付けの設定・scoop・UniGet UI・表示・電源・リモート・WSL）の検証記録

[手順書](../windows-setup.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 操作上の注意と併記されていた記録

   - `Current Scoop version:` の次に `v0.6.0 - Released at 2026-09-30` の形の行が出ればよい（版は実行した日の最新）

### 操作上の注意と併記されていた記録

   - 最後の表に `UniGetUI` と `Devolutions.UniGetUI` の行が出ればよい（版は実行した日の最新。2026-10-03 は 2026.3.0）

### 操作上の注意と併記されていた記録

   - 最後の表に `PowerToys` と `Microsoft.PowerToys` の行が出ればよい（版は実行した日の最新。2026-10-03 の定義は 0.101.2362.0）

### 操作上の注意と併記されていた記録

   - 最後の表に `PowerShell` と `Microsoft.PowerShell` の行が出ればよい（版は実行した日の最新。2026-10-03 の定義は 7.6.6.0）

### 操作上の注意と併記されていた記録

   - AlmaLinux 10 などの Python があるマシンでは、`python3 -c "import socket; m = bytes.fromhex('<MAC>'.replace('-', '').replace(':', '')); s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1); s.sendto(b'\xff' * 6 + m * 16, ('255.255.255.255', 9))"` で送れる（`<MAC>` はこの節の手順 3 の値。この 1 行は Linux で送れることだけ確かめた）

### 実施手順: 検証状況の記録

> [!WARNING]
> - **この手順書は Windows の実機で通していない**。貼り付けの設定は原因と直し方を実機で確かめた。CLI による更新は、配布物のヘルプ・Store CLI のヘルプと、Windows PowerShell 5.1 での構文・模擬の確認までで、更新の適用と再起動は未検証（[対象と検証環境](#対象と検証環境)）
> - **手順 40 のインラインの sudo、手順 41 の放置でロックしない設定、手順 44 のリモート デスクトップ、手順 48 の Windows Hello 以外のサインイン、手順 64 の自動サインインを重ねると、PC に触れる人と、このユーザーのパスワードを知る人は、このユーザー（管理者）として操作できる**。人が触れる場所にある PC では、手順 41・64 は行わない

### 実施手順 / 手順 3: 補足: 導入元と残るもの

- PSWindowsUpdate は Microsoft 標準のコマンドではなく、PowerShell Gallery に公開されている外部モジュール。2026-10-04 にヘルプを調べた版は 2.2.1.5
- `CurrentUser` は、このユーザーのドキュメントの `WindowsPowerShell\Modules` に置く。NuGet のプロバイダーも、無ければ自分のユーザーに入れる
- `-Force` は今回の導入の確認を省く。PSGallery 全体を `Trusted` にする設定は書かない
- `Import-Module -Global` は、この PowerShell の次の手順でもコマンドを使えるようにする指定。PC 全体へのインストールではない

### 実施手順 / 手順 10: 補足: ストアのアプリと CLI

- 同梱の Store CLI は `store.exe`。2026-10-04 にヘルプを確かめた Store 22608.1401.5.0 では、CLI 自体が `Preview` 表記だった
- 手順 13〜15 は Store の全アプリを対象にする。winget が認識できるアプリだけの更新ではない
- 「アプリ インストーラー」（`winget`）と、手順 30 で既定の端末にする Windows Terminal も、先に更新しておく
- Windows Insider への参加や、Store の配布チャネルの変更は行わない

### 実施手順 / 手順 15: 補足: 確認できている範囲

- `updates` と `--apply` の存在は同梱のヘルプで確認した。古い Store からの準備、更新の適用、進行中・失敗・更新なしの場合の実際の表示は未検証
- `Get-AppxPackage` の版と `Status` は、インストールされているパッケージの状態。これだけでは、新しい版が無いことや、全アプリの更新完了は分からない
- CLI の再検索の結果と併せて判定する。終了コードが 0 だったことだけを根拠に、完了の行は出さない

### 実施手順 / 手順 16: 補足: 行が逆順になる理由

- GitHub のコピーボタンは、ブロックの改行を LF だけにしてクリップボードに入れる（末尾の改行も無い）。マウスで選んで Ctrl+C でコピーしたものは、改行が CR LF になる
- conhost の窓（Windows Terminal ではない窓。検証した PC では、スタートメニューから管理者として開いた Windows PowerShell）に右クリックで貼ると、LF は Ctrl+Enter のキーとして届く
- Windows PowerShell 5.1 の PSReadLine 2.0.0 では、Ctrl+Enter は `InsertLineAbove`（今の行の上に空の行を作り、そこへ移る）。貼った行が 1 行ずつ上に入るので、ブロックが逆順になる
- `AddLine` は Shift+Enter と同じ働きで、実行せずに次の行へ進む。LF が来るたびに次の行へ進むので元の順に入り、最後に Enter を押すとブロック全体が 1 回で動く
- 管理者でない窓（検証した PC では Windows Terminal の中に開く）と、conhost の窓に Ctrl+V で貼ったときは、設定が無くても逆順にならなかった（利用者が確かめた）
- 実測は[付録](#付録-原因の確認と貼り付けの試験2026-10-03)

### 実施手順 / 手順 18: 補足: 実行ポリシーと scoop・プロファイル

- `scoop` のコマンドは PowerShell のスクリプト（`~\scoop\shims\scoop.ps1`）なので、`RemoteSigned`・`Unrestricted`・`Bypass` のどれかでないと動かない。scoop のインストーラも、これを確かめて止まる（[付録](#付録-配布物と資料の調査2026-10-03)）
- 手順 19 のプロファイルも、同じ理由で、このポリシーでないと読まれない
- `RemoteSigned` は、この PC で書いたスクリプトはそのまま動かし、インターネットから取ったファイル（Mark of the Web の付いたもの）には署名を求める
- `-Scope CurrentUser` は自分のユーザーだけの設定で、管理者の権限は要らない。`-Force` は確認の問い（`[Y] はい` など）を出さないため
- PowerShell 7 は、実行ポリシーを Windows PowerShell 5.1 とは別に持つ。PowerShell 7 で scoop を使うときは、そちらの `Get-ExecutionPolicy` も見る

### 実施手順 / 手順 19: 補足: プロファイルの書き方

- プロファイルが無ければ、`New-Item -Force` がフォルダ（`WindowsPowerShell`）ごと作る
- 行の末尾の `# windows-setup.md` は、[ロールバック](../windows-setup.md#ロールバック)で消す行を見分けるための印。2026-10-03 の前の版（貼り付けの設定が別の手順書 `windows-powershell-paste.md` だったとき）は、印が `# windows-powershell-paste.md` だった。どちらの印の行も、この手順は「すでにある」とみなし、ロールバックは消す
- 足す行は ASCII の文字だけなので、既存のプロファイルの文字コードによらず足せる。Windows PowerShell 5.1 の `Add-Content` は、既存のファイルの BOM（UTF-16 LE・UTF-8）を見て、同じ文字コードで足した
- `Add-Content` は、ファイルの末尾が改行でなくても改行を足さずに書き足す（最後の行につながった）。そのときは、行の前に改行を付けて足す
- 対話でない起動（標準入力をリダイレクトした `powershell -Command`）でも、この行はエラーを出さなかった
- 実測は[付録](#付録-原因の確認と貼り付けの試験2026-10-03)（印を変える前のブロックで試した）

### 実施手順 / 手順 22: 補足: 入れ方と入る場所

- `Devolutions.UniGetUI` は、UniGet UI の公式の README が最初に挙げる入れ方（UniGet UI は Devolutions 社に移った。もとの `MartiCliment.UniGetUI` ではない）
- winget の定義では、`--scope user` のときに Inno Setup のインストーラへ `/CURRENTUSER /NoWinGet /NoAutoStart` を渡す（自分のユーザーに入れる、winget を入れ直さない、入れた後に起動しない）。インストーラは `cdn.devolutions.net` から取り、sha256 を winget が確かめる（[付録](#付録-配布物と資料の調査2026-10-03)）
- 入る場所は `%LOCALAPPDATA%\Programs\UniGetUI`、設定は `%LOCALAPPDATA%\UniGetUI`（ソースのインストーラの定義と `CoreData.cs` から。確かめていない）
- スタートメニューとデスクトップにショートカットを作る。winget の定義はデスクトップのショートカットを止めるスイッチ（`/NoDesktopShortcut`）を渡さない
- `--accept-source-agreements` と `--accept-package-agreements` は、winget を初めて使う PC で出る同意の問いに答えるため（続けて貼った行が答えとして食われないように）
- scoop-search は、UniGet UI が scoop のパッケージを検索するのに使う道具（ソースの `Scoop.cs` が「検索に要る」とする依存）。無いと、UniGet UI が起動したときに入れるかを聞く。ここで先に入れておく
- scoop の `extras/unigetui` を採らなかった理由は、[選択した方針](../verification/windows-setup.md#選択した方針)

### 実施手順 / 手順 25: 補足: 値の意味

- `Explorer\Advanced` の値（フォルダー オプションの「表示」タブと、設定の「個人用設定」→「スタート」に当たる）
  - `HideFileExt` が 0: 「登録されている拡張子は表示しない」を外す（既定は 1）
  - `Hidden` が 1: 隠しファイルを表示する（隠すときの値は 2）
  - `LaunchTo` が 1: エクスプローラーを「PC」で開く（2 か値が無いと「ホーム」）
  - `Start_TrackDocs` が 0: 設定の「スタート、エクスプローラーのおすすめのファイル、最近使ったファイル、ジャンプ リストの項目を表示する」を切る（既定は 1）。Microsoft の文書（Windows のコンポーネントから Microsoft のサービスへの接続を管理する）に、この値を 0 にすると書いてある。ジャンプ リストも空になる
- `Explorer` の値（フォルダー オプションの「全般」タブの「プライバシー」に当たる）: `ShowRecent` が 0 で「最近使用したファイルを表示する」、`ShowFrequent` が 0 で「よく使うフォルダーを表示する」を切る
- `HideFileExt`・`Hidden`・`Start_TrackDocs` は、Microsoft が出している DSC のリソース（`microsoft/winget-dsc` の `Microsoft.Windows.Developer`）が同じ値を書く。`LaunchTo`・`ShowRecent`・`ShowFrequent` は Microsoft の文書には無く、広く使われている値（[付録](#付録-windows-11-の設定の調査2026-10-03)）
- 同じことは、設定の「システム」→「開発者向け」→「エクスプローラー」と、フォルダー オプションの画面からもできる

### 実施手順 / 手順 27: 補足: 値と設定の画面の対応

- `Explorer\Advanced`（設定の「個人用設定」→「スタート」）
  - `Start_IrisRecommendations`: 「ヒント、ショートカット、新しいアプリなどのおすすめを表示する」
  - `Start_AccountNotifications`: 「アカウント関連の通知を表示する」
- `ContentDeliveryManager`
  - `SubscribedContent-338393Enabled`・`-353694Enabled`・`-353696Enabled`: 「プライバシーとセキュリティ」→「全般」（新しいビルドでは「おすすめとオファー」）の「設定アプリでおすすめのコンテンツを表示する」
  - `SubscribedContent-338389Enabled`: 「システム」→「通知」→「追加の設定」の「Windows を使用する際のヒントや提案を入手する」
  - `SubscribedContent-310093Enabled`: 同じ所の「更新後とサインイン時に Windows のウェルカム エクスペリエンスを表示する」
  - `SubscribedContent-338388Enabled`・`SystemPaneSuggestionsEnabled`: Windows 10 の「スタートにおすすめを表示する」。Windows 11 に画面は無いが、0 にして害は無い
  - `SilentInstalledAppsEnabled`: 宣伝のアプリを黙って入れる働き（画面は無い）
- `UserProfileEngagement\ScoobeSystemSettingEnabled`: 「通知」→「追加の設定」の「Windows を最大限に活用し、このデバイスの設定を完了する方法を提案する」
- どれも Microsoft の文書には値が書かれておらず、広く使われている値（画面の文言は Microsoft のサポートの記事にある）。2025 年の終わりにスタートの作りが変わり、そこで足された切り替えの値は確かめられなかった（[付録](#付録-windows-11-の設定の調査2026-10-03)）
- スタートの「おすすめ」の欄を丸ごと消すのは、管理者のポリシー（`HideRecommendedSection`）が要る。本書では使わない

### 実施手順 / 手順 33: 補足: 外すアプリと、戻ってくること

| アプリ | パッケージの名前 | 戻すときのストアの ID |
|---|---|---|
| Clipchamp | `Clipchamp.Clipchamp` | `9P1J8S7CCWWT` |
| Microsoft ニュース | `Microsoft.BingNews` | `9WZDNCRFHVFW` |
| MSN 天気 | `Microsoft.BingWeather` | `9WZDNCRFJ3Q2` |
| Microsoft Solitaire Collection | `Microsoft.MicrosoftSolitaireCollection` | `9WZDNCRFHWD2` |
| Microsoft 365（Office の入口。ストアの名前は Microsoft 365 Copilot） | `Microsoft.MicrosoftOfficeHub` | `9WZDNCRD29V9` |
| Microsoft To Do | `Microsoft.Todos` | `9NBLGGH5R558` |
| フィードバック Hub | `Microsoft.WindowsFeedbackHub` | `9NBLGGH4R32N` |
| 問い合わせ（Get Help） | `Microsoft.GetHelp` | `9PKDZBMV1H3T` |
| Outlook（新しい） | `Microsoft.OutlookForWindows` | `9NRX63209R7B` |
| Microsoft Teams | `MSTeams` | winget の `Microsoft.Teams` |
| Power Automate | `Microsoft.PowerAutomateDesktop` | `9NFTCH6J7FHV` |

- 名前とストアの ID は、Microsoft Store の API で確かめた（[付録](#付録-windows-11-の設定の調査2026-10-03)）。名前は `*` を使わずに書く（`*Copilot*` のように書くと、残す Copilot も当たる）
- `Remove-AppxPackage` は、自分のユーザーからだけ外す。管理者の権限は要らない。PC に置かれた元（プロビジョニングされたパッケージ）は残るので、新しく作ったユーザーには入る
- Microsoft の文書では、Windows の更新で入れ直さない印は、管理者が元ごと外したとき（プロビジョニングの解除）にだけ付く。自分のユーザーから外しただけのアプリは、機能の更新の後に戻ってくることがあると広く報告されている
- 戻すときは、[ロールバック](../windows-setup.md#ロールバック)の手順 9 で、ストアの ID を指定して winget で入れる

### 実施手順 / 手順 43: 補足: プライベートにする理由

- Windows のファイアウォールの受信の規則は、ネットワークの種類（プライベート・パブリック）ごとに有効にできる。OpenSSH サーバーの機能が作る規則も、Syncthing の Windows 11 の節で作る規則も、手順 44〜46 の規則も、プライベートだけで有効にする
- Windows 11 は、新しくつないだネットワークをパブリックにすることがある。[Windows の OpenSSH サーバー](../windows-openssh-server.md)を検証した PC の有線 LAN はパブリックで、そのままでは LAN からの SSH が捨てられ、プライベートにすると通った（同書の手順 5 の補足）
- 同じ PC では、パブリックからプライベートにすると、それまで効いていなかった許可の規則 45 本がこの LAN で効くようになった。主なものは、ネットワーク探索（10 本）、リモート アシスタンス（4 本。手順 45 で切る）、デバイス キャスト機能（3 本）。ファイルとプリンターの共有は無効のままだった
- この操作は、もとは Windows の OpenSSH サーバーの手順 5 と Syncthing の Windows 11 の手順 7 の両方にあった。2026-10-03 に、インストール直後の作業としてここへまとめた。ブロックは OpenSSH サーバーの手順 5（実機で通したもの）から、`Get-NetFirewallRule` の行を除いて移した（変数の手順の番号だけ変えた）
- ノート PC を持ち出したとき: プライベートにしたのはこの接続（有線 LAN か、この Wi-Fi のネットワーク）だけ。出先の Wi-Fi は、つないだときにパブリックかプライベートかを選ぶ（既定はパブリック）

### 実施手順 / 手順 52: 補足: Windows と Linux の時計の扱い

- Windows は、ハードウェアの時計（RTC）を地方時として読み書きする。Linux は UTC として扱うのが普通で、両方が違う扱いのままデュアル ブートすると、起動し直すたびに 9 時間ずれる。2 つの OS のどちらかにそろえればよい
- AlmaLinux 10 のインストーラ（anaconda）は、NTFS のパーティションを見つけると、AlmaLinux の側を地方時にする（`/etc/adjtime` に `LOCAL`。[windows-dual-boot.md の注意点](../windows-dual-boot.md#注意点)。インストーラのソースから読んだこと）。その流れで入れたなら、もうそろっているので、この手順は要らない（行うと、かえって 9 時間ずれる）
- AlmaLinux の側を UTC にした（`timedatectl set-local-rtc 0`）ときだけ、Windows も UTC にそろえる。`HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation` の `RealTimeIsUniversal` を 1 にすると、Windows も UTC として扱う。Microsoft の文書には無い値で、Arch Linux の wiki が勧める形（DWORD。64 ビットの Windows では QWORD という古い勧めは、wiki から消えた）
- Arch Linux の wiki は、両方を UTC にする形を勧めている（Linux の側を地方時にする `timedatectl set-local-rtc 1` は勧めていない）。本書は、AlmaLinux のインストーラの既定（地方時）に合わせ、2026-10-03 に [windows-dual-boot.md](../windows-dual-boot.md) とそろえた
- 元に戻すのは[ロールバック](../windows-setup.md#ロールバック)の手順 27

### 実施手順 / 手順 62: 補足: AlmaLinux 10 の WSL のイメージ

- `AlmaLinux-10` は、WSL のディストリビューションの一覧（`wsl --list --online`）の AlmaLinux 10 の名前。イメージは AlmaLinux の `wsl-images`（GitHub）にあり、`wsl.exe` が sha256 を確かめて入れる（WSL の `DistributionInfo.json`。2026-10-03 は 10.2）
- 最初の起動で、AlmaLinux のイメージの `oobe` がユーザーを作る。作ったユーザーは uid 1000 で、`wheel` に入る（`sudo` を使える）。systemd が動く（`wsl.conf` の `systemd=true`）
- Linux のユーザー名とパスワードは、Windows のものとは別。パスワードは `sudo` で聞かれる
- [Windows の OpenSSH サーバー](../windows-openssh-server.md)の検証では、この AlmaLinux 10 からこの PC に SSH でつないで確かめた

### 実施手順 / 手順 64: 補足: Autologon のすること

- Autologon は Microsoft の Sysinternals の道具で、Windows の自動ログオンの設定（`HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon` の `AutoAdminLogon` など）を書き、パスワードは LSA のシークレットとして、暗号にして置く（Microsoft の文書。管理者は取り出せる）
- winget の定義（`Microsoft.Sysinternals.Autologon` 3.10）は zip の持ち運び版で、`%LOCALAPPDATA%\Microsoft\WinGet\Packages` の下に展開する。定義の取り先は版の付かない URL で、2026-10-03 は sha256 が一致した。Microsoft が zip を差し替えると、定義が直るまで winget が失敗する
- コマンド ラインでパスワードを渡す形（`autologon <ユーザー> <ドメイン> <パスワード>`）は、パスワードがプロセスのコマンド ラインに見え、履歴にも残りうるので使わず、窓で入れる
- `-accepteula` は、使用許諾の窓を出さないため
- Microsoft アカウントでは、`Username` をメールアドレスにし、`Domain` を `MicrosoftAccount` か PC の名前にする、という報告があるが、確かめていない。パスワード（PIN ではない）が要り、手順 48 でパスワードのサインインを使えるようにしておく
- [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)は、デスクトップにサインインしていることを前提にする。再起動の後もサインインした状態にするため
- 止めるのは[ロールバック](../windows-setup.md#ロールバック)の手順 20

### リモートから再起動する手段を増やす（任意）: 検証状況の記録

- **Windows の実機では通していない（未検証。2026-10-06 に書いた）**。ほかの節と同じく、資料と、Linux の PowerShell 7.6.6・PSScriptAnalyzer 1.25.0 での構文・互換・模擬までで確かめた（[付録](#付録-リモート再起動の節の資料とブロックの確認2026-10-06)）
- **確かめたこと**:
  - 資料: MS-RSP の transport（InitShutdown・WinReg は名前付きパイプ、WindowsShutdown は TCP）、「リモート システムからの強制シャットダウン」（`SeRemoteShutdownPrivilege`）の既定、`LocalAccountTokenFilterPolicy`（既定で管理者に限定、1 で緩む）、`CrashControl\AutoReboot`（既定 1）、Samba の `net rpc shutdown` と Windows の `shutdown /m`、`Enable-PSRemoting`/`Disable-PSRemoting`
  - 新しいブロック 10 個の構文（誤り 0）と 5.1 互換（`Set-ItemProperty -Type` の指摘だけ。動的なパラメーターで当たらない）
  - 見張りスクリプトの判定（稼働 60 分の歯止め・連続失敗のしきい値・届いたら 0 に戻すこと）と、手順 6・7 の中断（管理者でない・変数が空・タスクが無い）を、偽物のコマンドレットで模擬
- **確かめていないこと**: Windows で貼ること、別の PC から `net rpc shutdown`・`shutdown /m`・WinRM で実際に再起動できること、見張りタスクがネットワーク断で再起動し・ループしないこと、再起動の後に SSH・RDP が自動で戻ること、Microsoft アカウントでの SMB・WinRM の認証、`FPS-SMB-In-TCP`・`WINRM-HTTP-In-TCP*` の規則名が版・機種で一致すること

### 対象と検証環境

- **目的**: Windows 11 をインストールした直後に行う設定を、1 本の手順にまとめる
  - 更新（Windows Update・Microsoft Store）と、GitHub のコピーボタンでコピーしたブロックを Windows PowerShell に貼れるようにする設定（もとは別の手順書 `windows-powershell-paste.md`）
  - 入れるもの: [scoop](https://scoop.sh/)（コマンドラインのツール）、[UniGet UI](https://devolutions.net/unigetui/)（winget・scoop などのパッケージを画面で扱う）、PowerToys、PowerShell 7、WSL の AlmaLinux 10、Sysinternals の Autologon
  - 表示と入力: エクスプローラー・スタート・タスクバー・ダークモード・既定の端末・旧形式のコンテキストメニュー・IME の Ctrl+Space・Caps Lock を Ctrl に・US 配列
  - 整理: 標準アプリ・ウィジェット・自動で起動するアプリ・デスクトップのショートカット
  - PC 全体: PC の名前・長いパス・開発者モード・sudo・電源とロック・LAN のアダプターの省電力・デュアル ブートの時計
  - ネットワーク: LAN をプライベートに（もとは Windows の OpenSSH サーバーと Syncthing の Windows 11 の節にあった）・リモート デスクトップ・リモート アシスタンス・ping・配信の最適化
  - サインイン: Windows Hello だけのサインインを切る・自動サインイン
  - Git for Windows・Firefox・WezTerm・Claude Code・VirtualBox・WireGuard・HackGen Console NF は、AlmaLinux 10 と同じツールなので、それぞれの手順書の Windows 11 の節にある（[選択した方針](../verification/windows-setup.md#選択した方針)）。この文書のリードから順に案内する
- **進め方**: 最初に管理者の Windows PowerShell 5.1 で Windows Update を行い、必要なら手動で再起動する。その後、通常の窓で Store と自分のユーザーの設定を、管理者の窓で PC 全体の設定を行う
  - 設定の後に 1 回再起動し、WSL のディストリビューションと自動サインインを入れる
- **状態**: **Windows の実機では通していない**（2026-10-03 に作成、2026-10-04 に更新を CLI 化）
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも、この文書の形のまま Windows で貼ってはいない
  - **確かめたこと**:
    - CLI による更新（手順 1〜15）: PSWindowsUpdate 2.2.1.5 の配布物のヘルプ、Windows Update Agent の検索条件、WinGet の文書と Store の製品 ID。この PC の Store 22608.1401.5.0 のヘルプで `updates`・`--apply` を確認した（[付録](#付録-cli-による更新手順の確認2026-10-04)）
    - 新しい更新・削除のブロック: Windows PowerShell 5.1 の構文解析器と、偽物のコマンドレット・CLI を使った模擬。再起動待ち・更新失敗・Store CLI 不足などで止まることを確認した。実際の更新コマンドやモジュールの導入・削除は実行していない
    - 貼り付けの設定（手順 16〜19・37・38。[付録](#付録-原因の確認と貼り付けの試験2026-10-03)）: 原因（コピーボタンの中身が LF だけで、conhost の右クリックの貼り付けが LF を Ctrl+Enter として送り、PSReadLine 2.0.0 の Ctrl+Enter が `InsertLineAbove`）と、手順 16 の 1 行で直ることを、実機の Windows 11 の conhost の窓で確かめた。手順 19 とロールバックの手順 15 は、もとの手順書（`windows-powershell-paste.md`）のときのブロックを、プロファイルを一時的なファイルに差し替えた実機の Windows PowerShell 5.1 で、文字コードの違うプロファイルを含めて流した。印を変えた今のブロックは、Linux の pwsh で模擬しただけ
    - LAN をプライベートにする手順 43 のブロックは、[Windows の OpenSSH サーバー](../windows-openssh-server.md)の手順 5（実機で通した）にあったものから、規則を確かめる行を除いて移した
    - scoop・UniGet UI・Caps Lock・コンテキストメニュー（最初の版の 4 項目）: [配布物と資料の調査の付録](#付録-配布物と資料の調査2026-10-03)
    - 足した項目: Microsoft の文書（Microsoft Learn・サポートの記事・ポリシーの文書）、Microsoft の DSC のリソース（`microsoft/winget-dsc`）、winget の定義、各ツールのソース（PowerShell・sudo・WSL・winget・PSReadLine・UniGet UI など）、Microsoft Store の API（[設定の調査の付録](#付録-windows-11-の設定の調査2026-10-03)）
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。条件で止まるブロック（プロファイルの行、PC の名前、自動で起動するアプリ、リモート デスクトップなど）は、偽物のコマンドレットで模擬して流した（[ブロックの確認の付録](#付録-足した項目の-powershell-のブロックの確認2026-10-03)）
    - 2026-10-05 に直したロールバックの手順 16・29: Linux の PowerShell 7.6.6 で、記録した元値の復元と、空・不正値・書き込み失敗の分岐を模擬確認した。Windows の設定は変更していない（[付録](#付録-ロールバックの元値復元の模擬確認2026-10-05)）
  - **確かめていないこと**:
    - PSWindowsUpdate の初回導入・実更新・再起動後の再検索、古い Store から CLI を用意すること、Store の実更新と完了・失敗の表示。CLI 自体は `Preview` 表記
    - Windows で貼ること（すべての手順）と、画面の文言（設定・ストア・UniGet UI・Autologon）
    - Microsoft の文書に無い値が効くこと（エクスプローラーの `LaunchTo`・`ShowRecent`・`ShowFrequent`、スタートの提案の値、`StartupApproved`、`DelayLockInterval`、`DevicePasswordLessBuildVersion`、`RealTimeIsUniversal`、キーボードの種類、旧形式のコンテキストメニュー、スタートの検索の Web の結果）と、効く時期
    - Home の PC、Modern Standby の PC でのロック、Microsoft アカウントでの自動サインイン、arm64 の Windows
- 下表は、本書が前提にしている環境（ほかの Windows の手順書の実機の記録と同じ PC を想定）

| 項目 | 値 |
|---|---|
| OS | Windows 11（[Windows の OpenSSH サーバー](../windows-openssh-server.md)の実機の記録は 25H2）。x64。Pro を想定（Home では手順 44 を飛ばす） |
| PowerShell | Windows PowerShell 5.1（管理者ではないものと、管理者として実行したもの） |
| ユーザー | Administrators の一員（Microsoft アカウントでもローカル アカウントでもよい） |
| winget | Windows 11 の「アプリ インストーラー」に入っているもの |
| PSWindowsUpdate | PowerShell Gallery の外部モジュール（ヘルプの確認は 2.2.1.5） |
| Store CLI | Microsoft Store 同梱の `store.exe`（ヘルプの確認は 22608.1401.5.0、Preview） |
| scoop | 0.6.0（2026-09-30） |
| UniGet UI | 2026.3.0（winget の `Devolutions.UniGetUI`） |
| PowerToys | 0.101.2362.0（winget の `Microsoft.PowerToys`、自分のユーザー） |
| PowerShell 7 | 7.6.6.0（winget の `Microsoft.PowerShell`、MSIX） |
| Autologon | 3.10（winget の `Microsoft.Sysinternals.Autologon`） |
| WSL の AlmaLinux 10 | `AlmaLinux-10`（2026-10-03 のイメージは 10.2） |

貼り付けの設定（手順 16〜19・37・38）の原因を確かめた環境（[付録](#付録-原因の確認と貼り付けの試験2026-10-03)）:

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro（10.0.26300。x86_64 のノート PC） |
| PowerShell | Windows PowerShell 5.1.26100.9444（PSReadLine 2.0.0） |
| 窓 | conhost（`conhost.exe` で開いた窓。利用者の管理者の Windows PowerShell も conhost）。管理者でない窓は Windows Terminal 1.25.2733.0 |
| コピー | GitHub の Web のコードブロックのコピーボタン（Firefox） |

> [!NOTE]
> 環境固有の値は**変数**で書いてある。手順 36 の PowerShell の変数に 1 度だけ設定すれば、手順 37〜54 のコマンドはそのまま貼って実行できる。
>
> | 変数 | 設定する場所 | 意味 | 例 |
> |---|---|---|---|
> | `$PC_NAME` | 手順 36 | この PC の新しい名前（名前を変えるときに入れる。変えないなら空のままにして手順 39 を飛ばす） | `<HOSTNAME>` |
> | `$LAN_IF` | 手順 36（[ロールバック](../windows-setup.md#ロールバック)では手順 19、[Wake on LAN を使う（任意）](../windows-setup.md#wake-on-lan-を使う任意)では手順 2） | ほかの PC とつながる LAN の接続の名前（自動で入る） | `イーサネット` |
> | `$OLD_PC_NAME` | [ロールバック](../windows-setup.md#ロールバック)の手順 37 | 元の PC の名前（名前を戻すときに入れる） | `<HOSTNAME>` |
> | `$OLD_EXECUTION_POLICY` | [ロールバック](../windows-setup.md#ロールバック)の手順 16 | 手順 17 で控えた `CurrentUser` の実行ポリシー | `Undefined` |
> | `$OLD_DOWNLOAD_MODE` | [ロールバック](../windows-setup.md#ロールバック)の手順 29 | 手順 37 で控えた配信の最適化のモード | `CdnOnly` |
>
> 出力例・表の中の値は `<WIN_USER>`（Windows のユーザー名）/ `<HOSTNAME>`（コンピューター名）/ `<LAN_IF>` / `<名前>` / `<版>` のプレースホルダで書いてある。パスワード・回復キーはこの文書に載せない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 選択した方針

項目ごとに経路を比べた（2026-10-03 時点）。

**Windows Update と Store の更新（2026-10-04）**

| 経路 | 状況 | 採否 |
|---|---|---|
| **PSWindowsUpdate** | 外部モジュールの導入が必要だが、検索・適用・再起動待ちの確認を短いコマンドで行える | **採用**（利用者の選択。通常の更新のみ、自動再起動なし） |
| Windows Update Agent の COM API を直接使う | 追加のモジュールは不要だが、結果と再起動待ちを扱うコードが長くなる | 不採用 |
| 設定の Windows Update | これまでの手順 | 不採用（コマンドラインから行う依頼） |
| **Store CLI の `store updates --apply`** | Store 同梱。全 Store アプリを対象にできる。確認した版では CLI 自体が Preview | **採用**（利用者の選択。実更新は未検証） |
| `winget upgrade --all --source msstore` | WinGet が認識する Store アプリが対象 | 不採用（全 Store アプリの更新を代替したとはみなさない） |
| Microsoft Store の画面 | これまでの手順 | 不採用（CLI が使えない場合も、画面へ黙って切り替えない） |

- **PSReadLine の Ctrl+Enter を `AddLine` にする**（利用者の選択）
  - 窓の種類（conhost・Windows Terminal）と貼り方（右クリック・Ctrl+V）を選ばずに、コピーボタンのブロックをそのまま貼れる
  - プロファイルに書くので、窓を開くたびに貼り直さなくてよい
- **採らなかった案**
  - 管理者の Windows PowerShell を Windows Terminal で開く（Win+X の「ターミナル (管理者)」）: 設定は変えずに済むが、開き方を変える必要がある。既定の端末を Windows Terminal にしても（手順 30）、スタートメニューから管理者で開くと conhost になる（手順 30 の補足）
  - conhost の窓では Ctrl+V で貼る: 設定は変えずに済むが、右クリックで貼ると逆順になるのは残る（[ロールバック](../windows-setup.md#ロールバック)の後の貼り方として、その手順 15 に書いた）
  - ブロックを 1 行に書く: 手順書が読みにくくなる
  - 選んで Ctrl+C でコピーする: コピーボタンを使えない
  - コピーボタンの中身の改行を変える: 中身は GitHub が作る（改行は LF）
- **この文書にまとめた**: もとは別の手順書（`windows-powershell-paste.md`）で、Windows の PowerShell のブロックを貼る手順書の共有の前提だった。Windows のインストール直後に行うものなので、2026-10-03 に、この文書の手順 16〜19 にまとめた（実行ポリシーの手順も重なっていた）。ほかの手順書は、この文書の手順 16〜19 を前提にする

### 操作上の注意と併記されていた記録

- **PowerShell 7 のプロファイルは別**: 手順 19 の行は Windows PowerShell 5.1 のプロファイルにだけ書く。PowerShell 7（手順 24）は `Documents\PowerShell\Microsoft.PowerShell_profile.ps1` を読み、貼り付けの設定の原因を確かめた PC の PowerShell 7.6.6（PSReadLine 2.4.5）でも Ctrl+Enter は `InsertLineAbove` だった（もとの手順書 `windows-powershell-paste.md` の注意点の記録）。この文書の手順書群は、Windows PowerShell 5.1 に貼る

### 参照

- [PSWindowsUpdate（PowerShell Gallery）](https://www.powershellgallery.com/packages/PSWindowsUpdate/2.2.1.5) — 外部モジュールの配布元。配布物の `PSWindowsUpdate.dll-Help.xml` に検索条件・`IgnoreReboot`・`Get-WURebootStatus -Silent` の説明
- [IUpdateSearcher::Search（Microsoft Learn）](https://learn.microsoft.com/en-us/windows/win32/api/wuapi/nf-wuapi-iupdatesearcher-search) — `IsInstalled`・`IsHidden`・`IsAssigned`・`BrowseOnly`
- [PowerShell のパッケージ マネージャーの準備（Microsoft Learn）](https://learn.microsoft.com/en-us/powershell/gallery/powershellget/install-powershellget) — Windows PowerShell 5.1 の TLS 1.2 と NuGet
- [WinGet の導入と初回登録（Microsoft Learn）](https://learn.microsoft.com/en-us/windows/package-manager/winget/)・[upgrade](https://learn.microsoft.com/en-us/windows/package-manager/winget/upgrade) — `Add-AppxPackage -RegisterByFamilyName`、製品 ID とソースを指定した更新
- [Microsoft Store](https://apps.microsoft.com/detail/9wzdncrfjbmp)・[アプリ インストーラー](https://apps.microsoft.com/detail/9nblggh4nns1) — CLI の準備で使う製品 ID。Store CLI の引数は、同梱の `store.exe updates --help` で確認した
- [ScoopInstaller/Install](https://github.com/ScoopInstaller/Install) — 公式のインストーラ（`irm get.scoop.sh | iex`、実行ポリシー、管理者での導入を止めていること、`-RunAsAdmin`）
- [Scoop](https://scoop.sh/) と [ScoopInstaller/Scoop](https://github.com/ScoopInstaller/Scoop) — `bin/uninstall.ps1`（`scoop uninstall scoop`）、`libexec/scoop-update.ps1`
- [Devolutions/UniGetUI](https://github.com/Devolutions/UniGetUI) — README の入れ方、`UniGetUI.iss`（インストーラ）、`src/UniGetUI.PackageEngine.Managers.Scoop/Scoop.cs`、`src/Shared/AutoUpdater.InstallerArguments.cs`
- [winget-pkgs](https://github.com/microsoft/winget-pkgs) — winget の定義（`Devolutions.UniGetUI`・`Microsoft.PowerToys`・`Microsoft.PowerShell`・`Microsoft.Sysinternals.Autologon`）
- [microsoft/winget-dsc](https://github.com/microsoft/winget-dsc) — Microsoft の DSC のリソース（`Microsoft.Windows.Developer`・`Microsoft.Windows.Settings`）。エクスプローラー・タスクバー・ダークモードの値
- [Configuration of Keyboard and Mouse Class Drivers — Microsoft Learn](https://learn.microsoft.com/en-us/previous-versions/windows/hardware/hid/keyboard-and-mouse-class-drivers#scan-code-mapper-for-keyboards) — 節「Scan code mapper for keyboards」。Scancode Map の書式、再起動、全ユーザー
- [PowerToys Keyboard Manager — Microsoft Learn](https://learn.microsoft.com/en-us/windows/powertoys/keyboard-manager)・[Install PowerToys](https://learn.microsoft.com/en-us/windows/powertoys/install) — 採らなかった方法の制限、PowerToys の入る場所
- [about_Execution_Policies](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1)・[about_Profiles](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-5.1)・[Set-ExecutionPolicy](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-5.1) — Microsoft Learn
- [Set-PSReadLineKeyHandler](https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlinekeyhandler?view=powershell-5.1)・[about_PSReadLine_Functions](https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline_functions?view=powershell-5.1) — `AddLine` は Shift+Enter、`InsertLineAbove` は Ctrl+Enter
- [Manage connections from Windows operating system components to Microsoft services — Microsoft Learn](https://learn.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services) — `Start_TrackDocs`、ウィジェットのポリシー
- [Privacy settings for recommendations & offers in Windows 11 — Microsoft Support](https://support.microsoft.com/en-us/windows/privacy-settings-for-recommendations-offers-in-windows-11-807608ee-3de2-4498-8e7c-eb10d655567f) — 設定の「おすすめとオファー」の画面
- [Windows Terminal の group-policy.md（MicrosoftDocs/terminal）](https://github.com/MicrosoftDocs/terminal) と [microsoft/terminal #13392](https://github.com/microsoft/terminal/issues/13392) — 既定の端末の GUID、管理者のコンソールが引き渡されないこと
- [Microsoft 日本語 IME — Microsoft サポート](https://support.microsoft.com/ja-jp/windows/microsoft-%E6%97%A5%E6%9C%AC%E8%AA%9E-ime-da40471d-6b91-4042-ae8b-713a96476916) — キーとタッチのカスタマイズ
- [StartupTaskState — Microsoft Learn](https://learn.microsoft.com/en-us/uwp/api/windows.applicationmodel.startuptaskstate) — Teams の起動のタスクの `State`
- [Remove provisioned apps during update — Microsoft Learn](https://learn.microsoft.com/en-us/windows/application-management/remove-provisioned-apps-during-update) — 外したアプリが更新で戻ること
- [Microsoft Edge Update policies — Microsoft Learn](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-update-policies) — `RemoveDesktopShortcutDefault`
- [hackgen.md](../hackgen.md) — HackGen Console NF（AlmaLinux 10 と Windows 11）
- [Windows の OpenSSH サーバー](../windows-openssh-server.md) — 同じ PC で使うことの多い手順書（scoop のツールを SSH のセッションで使う任意節。LAN がプライベートである前提）

- [Force shutdown from a remote system — Microsoft Learn](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-10/security/threat-protection/security-policy-settings/force-shutdown-from-a-remote-system) — `SeRemoteShutdownPrivilege`、既定は Administrators、クライアントでも Administrators
- [[MS-RSP]: Transport — Microsoft Learn](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-rsp/6dfeb978-7a02-4826-b537-a1760fbf8074) — InitShutdown・WinReg は名前付きパイプ（`\PIPE\InitShutdown`）、WindowsShutdown は TCP
- [User Account Control and remote restrictions — Microsoft Learn](https://learn.microsoft.com/en-us/troubleshoot/windows-server/windows-security/user-account-control-and-remote-restriction) — `LocalAccountTokenFilterPolicy`。ローカル アカウントのネットワークログオンのトークンの絞り込みと、1 にしたときの挙動
- [Win32_OSRecoveryConfiguration — Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-osrecoveryconfiguration) — `AutoReboot`（`CrashControl\AutoReboot`、既定 1）
- [Enable-PSRemoting](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/enable-psremoting?view=powershell-5.1)・[Disable-PSRemoting](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/disable-psremoting?view=powershell-5.1) — Microsoft Learn。WinRM の有効化・無効化と、後始末（サービス・リスナー・規則・`LocalAccountTokenFilterPolicy`）
- [net(8) — Samba](https://www.samba.org/samba/docs/current/man-html/net.8.html) — `net rpc shutdown [-t timeout] [-r] [-f] [-C message]`、`-I`、`-U`
- [shutdown — Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/shutdown) — `/r`・`/f`・`/t`・`/m \\<host>`
- [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md) — 手順 7 で再起動後も使えるようにするタスク

### 付録: 配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物とソースと資料を読んだ記録。この付録と次の付録は、この文書の最初の版（scoop・UniGet UI・Caps Lock・コンテキストメニューの 4 項目）を書いたときのもの。手順の番号は、今の番号に付け替えた。

#### scoop

`get.scoop.sh` は、公式のインストーラへ飛んだ:

```
$ curl -sS -o /dev/null -w '%{http_code} %{redirect_url}\n' https://get.scoop.sh
301 https://raw.githubusercontent.com/scoopinstaller/install/master/install.ps1
```

取った `install.ps1`（787 行）の読んだところ:

- `Test-Prerequisite` が、次のときに止める（`Deny-Install`）
  - PowerShell 5 より前、.NET Framework 4.5 より前、`Robocopy.exe` が無い
  - 管理者の権限で動いていて `-RunAsAdmin` が無い: `Running the installer as administrator is disabled by default, see https://github.com/ScoopInstaller/Install#for-admin for details.`（環境変数 `CI` があるときと、Windows サンドボックスのユーザーは除く）
  - 実行ポリシーが `Unrestricted`・`RemoteSigned`・`ByPass` のどれでもない
  - `scoop` のコマンドがもうある: `Scoop is already installed. Run 'scoop update' to get the latest version.`（終了コード 0）
- `Test-ValidateParameter` が、`~\scoop`（か `C:\ProgramData\scoop`）が空でないフォルダーのときに止める: `'<場所>' exists and is not empty, please specify another path.`
- `Invoke-Expression` で動かしたときの止まり方は `exit` ではなく `break`（開いている PowerShell を閉じない）
- git があれば `ScoopInstaller/Scoop` と `ScoopInstaller/Main` を `git clone` し、無ければ両方の `master.zip` を取って展開する
- `PATH` は、`HKCU:\Environment` の `PATH` の先頭に `~\scoop\shims` を足し、`SendMessageTimeout` で `WM_SETTINGCHANGE`（`Environment`）を送る
- 最後に `Scoop was installed successfully!` と `Type 'scoop help' for instructions.` を出す

scoop 本体は v0.6.0（`CHANGELOG.md` の先頭が `## [v0.6.0](…) - 2026-09-30`。`scoop --version` はこの行から `v0.6.0 - Released at 2026-09-30` を作る）。ソース（コミット `e6aa3b36`）で読んだところ:

- `libexec/scoop-update.ps1`: git が無いと `Scoop uses Git to update itself. Run 'scoop install git' and try again.`。動いているアプリは `Running process detected, skip updating.` で飛ばす。上げるものが無いと `Latest versions for all apps are installed!`
- `libexec/scoop-status.ps1`: 何も古くなければ `Everything is ok!`
- `lib/buckets.ps1`: git が無いと `Git is required for buckets. Run 'scoop install git' and try again.`
- `lib/install.ps1`: 入れ終わると `'<名前>' (<版>) was installed successfully!`。定義の `installer` などのスクリプトは、`Invoke-Command ([scriptblock]::Create(…))` で、`scoop` を打った PowerShell の中で動かす
- `bin/uninstall.ps1`（`scoop uninstall scoop`）: `Are you sure? (yN)` を聞き、入れたアプリを 1 つずつ外し、`-p` が無ければ `persist` だけを残して `~\scoop` の中を消し、`PATH` から `shims` を外す。`~\.config\scoop` には触れない。最後に `Scoop has been uninstalled.`
- main のバケットの定義: `git` は 2.56.0（PortableGit の `.7z.exe` なので、依存で `7zip` が入る）、`scoop-search` は 2.1.0（`scoop-search.exe` 1 つ）

#### UniGet UI

winget の定義（winget-pkgs の `manifests/d/Devolutions/UniGetUI/2026.3.0/Devolutions.UniGetUI.installer.yaml`）の要点:

```
PackageIdentifier: Devolutions.UniGetUI
PackageVersion: 2026.3.0
InstallerType: inno
ReleaseDate: 2026-09-16
ElevationRequirement: elevatesSelf
Installers:
- Architecture: x64
  Scope: user
  InstallerUrl: https://cdn.devolutions.net/download/Devolutions.UniGetUI.win-x64.2026.3.0.0.exe
  InstallerSha256: 92C18BC8A3E4D01481474B49315198A7545AA8413BA83D2D929AC74823F455BC
  InstallerSwitches:
    Custom: /CURRENTUSER /NoWinGet /NoAutoStart
- Architecture: x64
  Scope: machine
  …
    Custom: /ALLUSERS /NoWinGet /NoAutoStart
  InstallationMetadata:
    DefaultInstallLocation: '%ProgramFiles%\UniGetUI'
```

scoop の `extras/unigetui` の定義（2026.3.0）は、GitHub のリリースの `UniGetUI.x64.zip` を展開し、`"pre_install": "Set-Content -Value $null -Path \"$dir\\ForceUniGetUIPortable\""` と `"persist": "Settings"` でポータブル版にする。

ソース（`Devolutions/UniGetUI` の 2026-10-02 のコミット `b1eb136`）で読んだところ:

- `UniGetUI.iss`（インストーラ）: `PrivilegesRequired=lowest`、`DefaultDirName="{autopf64}\UniGetUI"`（自分のユーザーへの導入では `%LOCALAPPDATA%\Programs\UniGetUI`）。スタートメニューとデスクトップのショートカットは既定で作り、デスクトップは `/NoDesktopShortcut` で止まる。`/NoAutoStart` は、入れた後に起動しないためのスイッチ
- `src/Shared/AutoUpdater.InstallerArguments.cs`: UniGet UI の自動の更新は、新しいインストーラを `/SILENT … /NoWinGet …` で動かす。ポータブル版では `/TASKS="portableinstall" /DIR="<今のフォルダー>"` を足し、今のフォルダーにそのまま上書きする
- `src/UniGetUI.Core.Logger/AppPaths.cs`: フォルダーに `ForceUniGetUIPortable` があり、書き込めれば、設定をそのフォルダーの `Settings` に置く（ポータブル版）
- `src/UniGetUI.Core.Data/CoreData.cs`: ポータブル版でなければ、設定は `%LOCALAPPDATA%\UniGetUI`（古い `~\.wingetui` があれば移す）
- `src/UniGetUI.PackageEngine.Managers.Scoop/Scoop.cs`:
  - `PATH` から `scoop.ps1` を探す。`pwsh.exe` があればそれで、無ければ Windows PowerShell 5.1 で、`-NoProfile -ExecutionPolicy Bypass` を付けて動かす
  - 依存に `Scoop-Search`（「検索に要る」。`scoop install main/scoop-search`）と `Git`（「scoop の更新に要る」。`scoop install main/git`）を持つ

上流の README は、入れ方を winget（`Devolutions.UniGetUI`）・scoop（`extras/unigetui`）・Chocolatey・Microsoft Store・インストーラの順に挙げ、公式のサイトは `https://devolutions.net/unigetui/` と書いている。

#### Caps Lock とコンテキストメニュー

- Microsoft Learn の「Configuration of Keyboard and Mouse Class Drivers」（古い版の文書の置き場所にある）の「Scan code mapper for keyboards」: 値の書式（ヘッダ 2 つの DWORD は 0、3 つ目は終わりの印を含む割り当ての数、割り当ては 1 つ 1 DWORD で、下位の WORD が送るキー・上位の WORD が押したキー）、再起動が要ること、全ユーザー・全キーボードにかかること、ターミナル サービスでは正しく働かないことがあること、消して再起動すれば戻ること。例 1（Caps Lock と左 Ctrl の入れ替え）の `0x003A001D` が「Caps Lock → 左 Ctrl」
- Microsoft Learn の PowerToys の Keyboard Manager: PowerToys が動いている間だけ効く、サインインの画面（パスワードの画面）では効かない、管理者の窓には PowerToys を管理者で動かさないと効かない
- 旧形式のコンテキストメニューの CLSID（`{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}`）は、Microsoft の文書には無い。25H2 で効くという記事を検索で見ただけ

---

### 付録: Linux での PowerShell のブロックの確認（2026-10-03）

Linux（クラウドのコンテナ）に PowerShell 7.6.6（GitHub のリリースの `powershell-7.6.6-linux-x64.tar.gz`）と PSScriptAnalyzer 1.25.0 を入れて確かめた。

**構文と Windows PowerShell 5.1 との互換**:

- 当時の本書の `powershell` のブロック 19 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0
  - ほかの規則の指摘は、手順 20 の `Invoke-Expression`（公式のインストーラの方法なので、そのまま）と、ASCII でない文字を含むファイルの BOM（貼るので関係が無い）だけ
  - わざと PowerShell 7 だけの書き方（`??`、`Get-Content -AsByteStream`、`ForEach-Object -Parallel`、`Join-Path -AdditionalChildPath`）を入れたファイルでは、それぞれ指摘が出た
- `(Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass'`（手順 18）は、列挙の値と文字列を比べて、`RemoteSigned` で `False`、`Restricted` で `True` になった

**手順 51 と[ロールバック](../windows-setup.md#ロールバック)の手順 28 のブロック**を、管理者の判定を `$true` に替え、レジストリ（`Get-ItemProperty`・`New-ItemProperty`・`Remove-ItemProperty`）を値を覚えておく偽物にして、`Scancode Map` が無いとき・本書の値のとき・別の値（`00 00 00 00 00 00 00 00 02 00 00 00 00 00 5B E0 00 00 00 00`）のときで流した:

| ブロック | 無い | 本書の値 | 別の値 |
|---|---|---|---|
| 手順 51 | 書き（1 回）、`Scancode Map = 00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00` | 書かずに同じ行 | `中断: 別の Scancode Map がある（…）` で止まり、書かない |
| ロールバックの手順 28 | `Scancode Map は無い` | 消して `Scancode Map を消した` | `中断: 本書の値ではない Scancode Map がある（…）` で止まり、消さない |

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（手順 17 の判定、scoop のインストーラ、winget の表示、UniGet UI の画面）
1. `HKCU` の CLSID の設定で、今の Windows 11（25H2・26H2）のエクスプローラーが旧形式のメニューを出すこと
1. Scancode Map で、Caps Lock が Ctrl になること（JIS 配列のキーボード、リモート デスクトップでつないだときも）
1. 更新（scoop・UniGet UI）とロールバック、arm64 の Windows

---

### 付録: 原因の確認と貼り付けの試験（2026-10-03）

この付録は、もとの手順書 `docs/windows-powershell-paste.md`（2026-10-03 にこの文書へまとめて消した）の付録を移したもの。手順の番号だけ、この文書の番号に付け替えた（当時の手順 1〜7 は今の手順 16・17・18・19・35・37・38、当時のロールバックの手順 1・2 は今の[ロールバック](../windows-setup.md#ロールバック)の手順 15・16）。試験したブロックは当時のもの（プロファイルの行の印は `# windows-powershell-paste.md`。今の手順 19 とロールバックの手順 15 は、印を変え、古い印の行も見つけるようにした。その確認は[ブロックの確認の付録](#付録-足した項目の-powershell-のブロックの確認2026-10-03)）。

**利用者の観察**: Firefox で開いた GitHub の [RDP をロックせずに切断](../windows-rdp-disconnect.md)の PowerShell のブロックを、コピーボタンでコピーして、スタートメニューから管理者として開いた Windows PowerShell（conhost の窓）に右クリックで貼ると、行が逆順になった。選んで Ctrl+C でコピーしたもの、管理者でない Windows PowerShell の窓、conhost の窓に Ctrl+V で貼ったものは、元の順に入った。

**コピーボタンの中身**:

- GitHub が描画した HTML（`gh api` で `Accept: application/vnd.github.html+json` を付けて取った windows-rdp-disconnect.md）では、ブロックの `data-snippet-clipboard-copy-content` の値は、改行が LF だけで、末尾に改行が無かった
- 利用者が Firefox のコピーボタンでコピーした直後のクリップボード（同書の「ショートカットで切断する（任意）」の手順 1 のブロック）: 702 文字、CR LF は 0 個、LF だけの改行は 12 個、末尾に改行無し

**PSReadLine のキー**: この PC の Windows PowerShell 5.1.26100.9444 の PSReadLine 2.0.0 の `Get-PSReadLineKeyHandler -Bound`:

```
Enter            AcceptLine
Shift+Enter      AddLine
Ctrl+Enter       InsertLineAbove
Shift+Ctrl+Enter InsertLineBelow
Ctrl+v           Paste
```

**conhost の窓に貼る試験**: `conhost.exe powershell.exe -NoProfile -NoExit` で窓を開き、`Set-Clipboard` でクリップボードに入れた 5 行のブロック（`& {`、一時的なファイルに `1 行目`〜`3 行目` を書く 3 行、`}`）を、窓へ `WM_SYSCOMMAND` の `0xFFF1`（conhost の貼り付けのコマンド）を送って貼った。続けて CR だけを同じ方法で貼り、Enter の代わりにした。クリップボードは試験の前の中身に戻した。

| 貼ったもの | 窓の設定 | 貼った直後の画面 | Enter の後のファイル |
|---|---|---|---|
| LF だけ（末尾に改行無し） | 無し | 逆順（`& {` が最後の行） | 作られない |
| LF だけ（末尾に改行無し） | `-Command` で手順 16 の 1 行 | 元の順（`}` が最後の行） | `1 行目` / `2 行目` / `3 行目` |
| LF だけ（末尾に改行無し） | 同じ行（印のコメント付き）を書いたファイルを `-Command` の `.` で読ませた | 元の順 | `1 行目` / `2 行目` / `3 行目` |
| CR LF（末尾に改行あり） | 無し | — | `1 行目` / `2 行目` / `3 行目` |
| CR LF（末尾に改行あり） | `-Command` で手順 16 の 1 行 | — | `1 行目` / `2 行目` / `3 行目` |

**対話でない起動**: 標準入力をリダイレクトした `powershell.exe -NoProfile -Command "Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine; 'ok'"` は、エラー無しで `ok` を出した。

**`Add-Content` の書き足し方**: Windows PowerShell 5.1 で、末尾に改行の無いファイル（`Set-Alias ll Get-ChildItem`）に `Add-Content` で 1 行を足すと、`Set-Alias ll Get-ChildItemX-LINE` と最後の行につながった。手順 19 のブロックは、そのときに行の前へ CR LF を付ける。

**手順 19 とロールバックの手順 15 のブロック**: 当時の文書から `powershell` のブロックを抜き出し（リストの字下げを外した）、Windows PowerShell 5.1 で、`$PROFILE` を一時的なディレクトリの `WindowsPowerShell\Microsoft.PowerShell_profile.ps1` に差し替えて `Invoke-Expression` で流した。どの場合も手順 19 を 2 回（2 回目は `すでにある:`）、ロールバックの手順 15 を 2 回（2 回目は `その行は無い:` か `プロファイルが無い:`）流した。既存のプロファイルの中身は、日本語のコメントと `Set-Alias ll Get-ChildItem` の 2 行:

| 既存のプロファイル | 手順 19 の後 | ロールバックの手順 15 の後 |
|---|---|---|
| 無い | `足した:`。ASCII の 1 行（93 バイト） | `消した:`（ファイルが消えた） |
| 空のファイル | 同じ | `消した:` |
| UTF-16 LE（BOM あり） | 先頭は `FF FE` のまま。足した行は 3 行目 | `その行だけ消した:`。前と同じバイト |
| UTF-8（BOM あり） | 先頭は `EF BB BF` のまま。足した行は 3 行目 | 前と同じバイト |
| UTF-8（BOM 無し）、末尾に改行無し | 足した行は 3 行目（前に CR LF を付けた）。5.1 の `Get-Content` では日本語が化けて見えた（ANSI として読む）が、バイトは変わらない | 日本語を含め前と同じバイトに、手順 19 で付けた CR LF だけが残った |
| Shift_JIS | 足した行は 3 行目 | 前と同じバイト |
| UTF-16 LE・UTF-8（BOM あり）で、手順 19 の行だけ | `すでにある:` | `消した:`（ファイルが消えた） |
| UTF-16 LE・UTF-8（BOM あり）で、1 行目が手順 19 の行、2 行目が `Set-Alias` | — | `その行だけ消した:`。BOM と `Set-Alias` の行だけが残った |

最初に書いたロールバックの手順 15 は、正規表現が `(?m)^` と行だけだったので、BOM の直後（ファイルの 1 行目）にある行を見つけられず、BOM のあるファイルで `その行は無い:` を出した。BOM を許して残すように直し、上の表はすべて直した後のもの。

**構文**: 当時の文書の `powershell` のブロック 8 個を、Windows PowerShell 5.1 の `[System.Management.Automation.Language.Parser]::ParseInput` に通した（構文の誤りは 0）。

---

### 付録: Windows 11 の設定の調査（2026-10-03）

インストール直後の作業をこの文書にまとめたとき（2026-10-03）に、Windows を動かせない環境（クラウドの Linux のコンテナ）で、文書・ソース・定義を読んだ記録。確かさは、Microsoft の文書かソース（「文書」）、Microsoft の書いたコードや配布物の中身（「コード」）、それ以外の広く使われている情報（「広く」）で書く。

**自分のユーザーの設定（手順 25〜34）**

- エクスプローラー（手順 25）: `HideFileExt`・`Hidden`・`Start_TrackDocs` は、Microsoft の DSC のリソース `microsoft/winget-dsc`（コミット `8a8387e`）の `Microsoft.Windows.Developer` が同じ値を書く（コード）。`Start_TrackDocs` を 0 にするのは、Microsoft Learn の「Manage connections from Windows operating system components to Microsoft services」の 33 節にもある（文書）。`LaunchTo`・`ShowRecent`・`ShowFrequent` は広く
- スタートと提案（手順 27）: 設定の画面の文言は Microsoft のサポートの記事（文書）。値（`Start_IrisRecommendations`・`Start_AccountNotifications`・`ContentDeliveryManager` の `SubscribedContent-*`・`SystemPaneSuggestionsEnabled`・`SilentInstalledAppsEnabled`・`UserProfileEngagement\ScoobeSystemSettingEnabled`）は広く。2025 年の終わりのスタートの作り直しで足された切り替えの値は、見つからなかった
- スタートの検索の Web の結果（手順 49）: `HKCU\Software\Policies\Microsoft\Windows\Explorer` の `DisableSearchBoxSuggestions` は、ポリシーの文書（`WindowsExplorer.admx`）では「エクスプローラーの検索ボックスに最近の検索を出さない」。スタートの検索の Web の結果が消えるのは広く。`HKCU\Software\Policies` は、管理者でないと書けない（Microsoft のフォーラムの回答）
- タスクバー（手順 28）: `TaskbarAl`・`ShowTaskViewButton`・`SearchboxTaskbarMode`（0 が消す、1 がアイコン、2 が検索ボックス、3 がアイコンとラベル）は DSC の `Taskbar`（コード）。ポリシーの `ConfigureSearchOnTaskbarMode` は番号の意味が違う（文書）。`ShowSecondsInSystemClock` は 22H2 の 2023 年 5 月のプレビューの更新（KB5026446）から（広く）。`TaskbarDa` は UCPD（`ucpd.sys`）が守っていて、`powershell.exe`・`reg.exe` などからの書き込みは拒まれる（広く。ドライバーを解析した記事）
- ダークモード（手順 29）: `AppsUseLightTheme`・`SystemUsesLightTheme` は DSC の `Microsoft.Windows.Settings` が書き、`WM_SETTINGCHANGE`（`ImmersiveColorSet`）を送る（コード）
- 既定の端末（手順 30）: `HKCU\Console\%%Startup` の GUID は Windows Terminal の文書の `group-policy.md`（文書）。22H2 以降の既定（「Windows に任せる」）は Microsoft のサポートの記事（文書）。管理者のコンソールが引き渡されないことは、microsoft/terminal の #13392（「管理者のコマンド ラインの受け手として登録できる端末は無い」）と #10276・#10682・#15126 で、開いたまま
- IME（手順 31）: 設定の画面（`ms-settings:regionlanguage-jpnime`）は Microsoft のサポートの記事（文書）。レジストリの値は、ある開発者が画面の前後で見比べた記録だけ（`cuzic/awase`）。Ctrl+Space を Windows が使うのは中国語の IME だけ（Microsoft のキーボード ショートカットの文書）
- 自動で起動するアプリ（手順 32）: `StartupApproved\Run` の先頭の 1 バイト（2 が起動、3 が停止）は広く（UniGet UI のインストーラも同じ所に書く）。Teams の起動のタスクの名前 `TeamsTfwStartupTask` は、Teams の MSIX の `AppxManifest.xml`（26198.304.4946.9672）にある（コード）。`State` の値は `StartupTaskState`（文書）。UniGet UI を winget で入れると、`Run` に `WingetUI`（`--daemon`）ができる（winget の定義が `/NoRunOnStartup` を渡さない。インストーラの定義 `UniGetUI.iss`）
- 標準アプリ（手順 33・34）: パッケージの名前・パッケージ ファミリー名・ストアの ID は、Microsoft Store の API（`storeedgefd.dsx.mp.microsoft.com`）で確かめた（文書）。「Microsoft 365 Copilot」は `Microsoft.MicrosoftOfficeHub`（`9WZDNCRD29V9`）で、Copilot（`Microsoft.Copilot`、`9NHT9RB2F4HD`）とは別のパッケージ。自分のユーザーから外しただけのアプリは機能の更新で戻りうる（「Remove provisioned apps during update」。文書）
- PowerToys（手順 23）: winget の定義 0.101.2362.0 に、自分のユーザーのインストーラ（`PowerToysUserSetup`、管理者の指定無し）と PC 全体のインストーラ（`elevatesSelf`）がある。形式は Burn、渡す引数は `/quiet /norestart`
- ピン留め（手順 58）: 自分のユーザーで使える、サポートされたコマンドは見つからなかった。Microsoft の文書の方法は、タスクバーのレイアウトの XML、`ConfigureStartPins`（24H2 の KB5062660 から `applyOnce`）などのポリシーとプロビジョニングだけ

**PC 全体の設定（手順 39〜54）**

- PC の名前（手順 39）: `Rename-Computer` は、15 文字を超える名前で `ShouldContinue` の問いを出し（`-Force` で出さない）、今と同じ名前で `NewNameIsOldName` のエラーを出す（PowerShell のソースの `Computer.cs`。5.1 は文書の文言が同じ）。名前の決まりは Microsoft Learn の「Naming conventions in Active Directory」（文書）
- 長いパス・開発者モード（手順 40）: `LongPathsEnabled` と `AllowDevelopmentWithoutDevLicense` は Microsoft Learn（「Maximum Path Length Limitation」と「Developer Mode」）の値（文書）
- sudo（手順 40）: 24H2 から（文書）。`sudo config --enable` の 3 つの形と、インラインの危うさは Microsoft Learn（文書）。レジストリの値（`HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo` の `Enabled`。0〜3）は microsoft/sudo の `helpers.rs`（コード）。Home で使えるかは書かれていない
- 電源（手順 41）: `powercfg` の別名（`SUB_BUTTONS`・`LIDACTION`・`SUB_NONE`・`CONSOLELOCK`）と値は、Microsoft Learn の電源の設定の文書（文書）。休止状態を切ると高速スタートアップのファイルも無くなる（文書から言えること。1 文で書いた文書は無い）。`DelayLockInterval` は広く（Microsoft の文書は見つからなかった）。S3 の PC では、画面が消えるだけではロックしない（眠り・パスワード付きのスクリーン セーバー・`InactivityTimeoutSecs`・動的ロックだけがロックする。文書からの推論）
- アダプター（手順 42）: `Set-NetAdapterPowerManagement` は `-NoRestart` が無いとアダプターを起動し直す（文書）。`AllowComputerToTurnOffDevice` は WMI のクラスの文書では読み取り専用で、変えて渡す形は広く。この項目を外すと、Windows が任せる Wake on LAN も効かなくなる（Windows 7 の頃のサポートの記事 KB2740020。2026-05 に消え、MicrosoftDocs の履歴から読んだ）
- リモート デスクトップ（手順 44）: Home はつながれる側になれない（文書）。`fDenyTSConnections`・`UserAuthentication`、規則のグループ `@FirewallAPI.dll,-28752` と規則の名前 `RemoteDesktop-UserMode-In-TCP` は、Azure の VM の切り分けの文書と無人インストールの文書（文書）。画面でオンとオフにし直したときに規則のプロファイルが戻るかは、分からなかった
- リモート アシスタンス（手順 45）: `fAllowToGetHelp`（無人インストールの文書）。規則のグループ `@FirewallAPI.dll,-33002` は、Windows の `racpldlg.dll` の文字列にある（コード。Learn には無い）
- ping（手順 46）: `New-NetFirewallRule` の `-Protocol ICMPv4 -IcmpType 8` と `ICMPv6`・`128`（文書）
- 配信の最適化（手順 47）: 既定は LAN（配信の最適化の文書。ポリシーの文書は 0 と書いていて食い違う）。`Set-DODownloadMode`・`Get-DODownloadMode`（文書）
- Windows Hello（手順 48）: `DevicePasswordLessBuildVersion` は広く（Microsoft の文書は見つからなかった）
- Edge のショートカット（手順 50）: `RemoveDesktopShortcutDefault`（Edge Update 1.3.155.1 から）と、`CreateDesktopShortcutDefault` が入っていると効かないことは、Edge Update のポリシーの文書（文書）
- 時計（手順 52）: `RealTimeIsUniversal` は Microsoft の文書に無い。Arch Linux の wiki は DWORD を勧める（QWORD の古い勧めは消えた）
- キーボードの種類（手順 53）: US 配列の 4 つの値は、Microsoft の日本の社員のブログ（Learn の archive の「英語キーボードを快適に使う」）。JIS の値は広く
- WSL（手順 54・62）: `--no-distribution` は Windows 11 では仮想マシン プラットフォームだけを入れる（WSL のソースの `WslInstall.cpp`）。`AlmaLinux-10` は `DistributionInfo.json`（2026-10-03、10.2.20260526.0）。最初の起動のユーザーの作成は AlmaLinux の `wsl-images` の `oobe`（uid 1000、`wheel`、`systemd=true`）
- Autologon（手順 64）: winget の定義 3.10 は版の付かない `AutoLogon.zip` を取り、2026-10-03 は sha256 が一致した。パスワードは LSA のシークレットに置く（Microsoft Learn の Autologon と「Protecting the automatic logon password」）。Microsoft アカウントの `Domain` の入れ方は分からなかった
- PowerShell 7（手順 24）: 7.6.0 から winget は MSIX を既定で入れ、7.7.0 から MSI は無くなる（Microsoft Learn の Windows への入れ方）。winget の選び方（MSIX が MSI より先）は winget のソースの `ManifestComparator.cpp`。PowerShell 7.6.6 の PSReadLine は 2.4.5 で、Ctrl+Enter は `InsertLineAbove`（PSReadLine の `KeyBindings.cs`）

---

### 付録: 足した項目の PowerShell のブロックの確認（2026-10-03）

インストール直後の作業をこの文書にまとめた後の、全部のブロックを、Linux（クラウドのコンテナ）の PowerShell 7.6.6 と PSScriptAnalyzer 1.25.0 で確かめた。Windows では貼っていない。

**構文と Windows PowerShell 5.1 との互換**:

- この文書の `powershell` のブロック 90 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた
  - `Set-ItemProperty` の `-Type` が 5.1 に無いという指摘が 54 個出た。`-Type` はレジストリのプロバイダーが足す動的なパラメーターで、5.1 の `Set-ItemProperty` の文書にもある（`reference/5.1/Microsoft.PowerShell.Management/Set-ItemProperty.md` の「This is a dynamic parameter made available by the Registry provider」）。互換の検査は動的なパラメーターを見ないので、指摘は当たらない
  - ほかは、手順 20 の `Invoke-Expression`（公式のインストーラの方法）と、1 つの変数だけのブロック（手順 36・ロールバックの手順 37 の `$PC_NAME`・`$OLD_PC_NAME`）の「代入して使っていない」だけ
- 手順 19 とロールバックの手順 15 の正規表現と文字列、手順 39 の名前の正規表現も、この構文解析器で読めた

**偽物のコマンドレットで流したブロック**（Linux の pwsh。レジストリは、値を覚えておく偽物の `Set-ItemProperty`・`Get-ItemProperty`・`Get-Item`・`Test-Path`・`New-Item` にした）:

| ブロック | 流した場合 | 結果 |
|---|---|---|
| 手順 19（プロファイルに足す） | 無い・空・UTF-8（BOM の有無）・Shift_JIS の既存のファイル、新しい印の行がある、古い印（`# windows-powershell-paste.md`）の行がある、両方ある | 無いときだけ `足した:`、2 回目と印の行があるときは `すでにある:` |
| ロールバックの手順 15（プロファイルから消す） | 上の各場合と、UTF-16 LE、BOM の直後の行、新旧の両方の行。正規表現の BOM は、もとの手順書と同じく `\uFEFF` などの ASCII の書き方（文字をそのまま書くと、コピーと貼り付けで落ちうる） | どちらの印の行も消え、ほかの行と BOM はバイトのまま残った。残りが BOM と空白だけならファイルを消した。UTF-8（BOM 無し、末尾に改行無し）では、手順 19 で付けた CR LF だけが残った（もとの手順書の付録と同じ） |
| 手順 39（PC の名前） | 空、`my-pc`、今と同じ名前（大文字と小文字の違いも）、16 文字以上、数字だけ、先頭か末尾がハイフン、`_` を含む、1 文字 | 空と使えない名前は `中断:`、同じ名前は `すでにこの名前:`、ほかは `Rename-Computer -NewName <名前>` を 1 回呼んだ |
| ロールバックの手順 37（名前を戻す） | 空、今と同じ名前、別の名前、16 文字以上、数字だけ | 空と使えない名前は `中断:`、同じ名前は `すでにこの名前:`、ほかは `Rename-Computer` を 1 回（`-Force` は付けない） |
| 手順 32（自動で起動するアプリ） | `Run` に `OneDrive`・`MicrosoftEdgeAutoLaunch_ABC`・`WingetUI`、Teams の起動のタスクあり。もう 1 回は `OneDrive` だけで Teams 無し | `OneDrive` と Edge に `03 00 00 00` と 8 バイトの日時を書き、Teams の `State` を 1 にした。一覧は 2 つが `止めている`、`WingetUI` が `起動する`。2 回目は `OneDrive` だけを止めた |
| ロールバックの手順 8 | 上の後 | 2 つを `02` と 11 バイトの 0 に、Teams を 2 に戻した |
| 手順 33・34（標準アプリ・ウィジェット） | 11 個のうち 3 個と Copilot だけが入っている。ウィジェットは無い場合とある場合 | 入っている 3 個だけ `Remove-AppxPackage` に渡し、ほかは `無い:`。Copilot には触れなかった |
| 手順 42・ロールバックの手順 34（アダプター） | `$LAN_IF` が空、`Enabled` のアダプター、`Unsupported` のアダプター | 空は止まり、`Unsupported` は `対象外:`。ほかは `AllowComputerToTurnOffDevice` を `Disabled`（戻すときは `Enabled`）にして、`-NoRestart` 付きで渡した |
| 手順 44（リモート デスクトップ） | `EditionID` が `Core`・`CoreSingleLanguage`・`Professional` | Home の 2 つは `中断:` で何も書かず、`Professional` だけ 2 つの値を書いて規則を `-Profile Private` にした |
| 手順 50（ショートカット） | すべてのユーザーのデスクトップに `Microsoft Edge.lnk` があり、自分のデスクトップに `UniGetUI.lnk` が無い。2 回 | ポリシーを書き、1 回目は Edge を `消した:`、UniGet UI を `無い:`。2 回目はどちらも `無い:` |
| OpenSSH サーバーの手順 5・Syncthing の Windows 11 の手順 7（LAN がプライベートかを確かめる） | `$LAN_IF` が空、パブリック、プライベート | 空とパブリックは止まり（Syncthing は規則を作らない）、プライベートだけ規則を確かめた（作った） |

**Wake on LAN の 1 行**（任意節の手順 7）: Linux の Python 3.11 で、MAC アドレスの例を入れて流し、102 バイト（`FF` が 6 個と MAC が 16 回）のパケットを送れた（受け取る側は確かめていない）。

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（画面の手順と、設定・ストア・UniGet UI・Autologon の文言を含む）
1. Microsoft の文書に無いレジストリの値（[状態](#対象と検証環境)の「確かめていないこと」）が、24H2・25H2・26H2 で効くこと
1. 手順 42 の `AllowComputerToTurnOffDevice` を変えて渡す形が、今の Windows 11 の `Set-NetAdapterPowerManagement` で効くこと
1. 手順 44 の後に、設定の画面でリモート デスクトップをオンとオフにしたとき、規則のプロファイルが戻るか
1. Modern Standby の PC で、手順 41 の後に放置してもロックしないこと
1. Microsoft アカウントでの自動サインイン（手順 64）と、Wake on LAN（任意節）
1. 更新とロールバック、Home の PC、arm64 の Windows

### 付録: CLI による更新手順の確認（2026-10-04）

Windows Update と Microsoft Store の画面の手順を、コマンドラインに置き換えた。通常の更新だけにすること、再起動を手動にすること、Preview 表記の Store CLI を使うことは、利用者が選んだ。

**資料とヘルプ**:

- PSWindowsUpdate 2.2.1.5 の nupkg を取得し、インストールせずにヘルプ・エイリアス・表示の定義を読んだ
  - `Criteria`、`IgnoreReboot`（再起動も再起動の問いも行わない）、`Get-WURebootStatus -Silent`（真偽値）の説明を確認した
  - Windows Update Agent の `Search` の文書で、`IsAssigned=1` が自動更新の配信対象、`BrowseOnly=0` がオプションではない更新であることを確認した
- WinGet の文書で初回登録の `Add-AppxPackage` と、製品 ID・ソースを指定する更新を確認した
  - Store の配布情報で、Microsoft Store の製品 ID `9WZDNCRFJBMP` とパッケージ ファミリー名を確認した
  - winget の `AppInstallerErrors.h` で、`0x8A15002B` が `UPDATE_NOT_APPLICABLE` であることを確認した
- この PC の Microsoft Store 22608.1401.5.0 で、`store.exe --help`・`store.exe updates --help`・`store.exe update --help` を実行した
  - CLI の版は `22608.1401.5.0 - Preview`。一括の `updates` と `--apply` があり、例には `store updates --apply` と書かれていた
  - `store updates` による実際の検索や、`--apply` による更新は実行していない

**構文と既存の動作**:

- Windows PowerShell 5.1.26100.9444 の構文解析器で、この文書の PowerShell ブロック 105 個を解析し、構文の誤りは 0 だった
- もとの手順 4〜52（今の手順 16〜64）と、既存の任意節・更新・ロールバックのコマンドを、変更前の文書と比較した。手順参照の番号以外は変わっていない
- 既存の付録も、手順参照の番号以外は変わっていない。別の手順書の番号・ロールバックの番号・当時の番号は、元の参照先を保った
- 関連する 12 本の手順書は、初期設定を参照する番号だけの変更であることを比較した。実施手順は 64、ロールバックは 41 手順になった

**模擬の実行**:

- 新しいブロックのコマンドレットと `store.exe`・`winget.exe` を、検証用の PowerShell 関数に置き換えて 61 ケースを通した
- PowerShell の版と管理者かどうかの判定は、検証用の値に差し替えた。コマンドに渡る引数と、成功・警告・エラーの分岐を確認した

| 対象 | 確認した分岐 |
|---|---|
| 準備（手順 2・3） | 5.1／7、管理者／通常の窓、実行ポリシーの制限、モジュールと NuGet の有無、違う PSGallery の URL、導入と読み込みの失敗 |
| Windows Update（手順 4〜8） | 対象 0 件／通常の更新あり、オプション・プレビュー・非表示・導入済みの除外、検索と導入の失敗、再起動待ちと判定できない場合、検索中に再起動待ちになる場合 |
| Store（手順 10〜15） | CLI の有無・一括更新への対応、登録の失敗、2 製品だけの準備、更新なしの終了コード、検索・適用・再検索の失敗、必要なパッケージの欠落・不正常な状態 |
| モジュールの保守（更新の手順 5・ロールバックの手順 41） | モジュールだけの更新・削除、失敗時の中断、管理者の窓で削除しないこと、ほかの場所に残ったモジュールを続けて消さないこと |

- 検索・導入・再検索で同じ条件を渡すこと、`AcceptAll` と `IgnoreReboot` を渡すこと、自動再起動や再開タスクを作らないことを検査した
- 更新が残る場合、検索に失敗した場合、再起動待ちの場合に、Windows Update の完了の行を出さないことを確認した
- Store は、コマンドが終了しただけで独自の完了の行を出さない。CLI の実際の表示は確認していないので、本文で再検索の結果も読んで判定する形にした

**残っている未確認事項**:

- PSWindowsUpdate・NuGet の初回導入、Windows Update の実際の対象一覧・ダウンロード・インストール、再起動後の再検索
- 古い Store からの CLI の準備、Store の実更新・進行中の表示・完了待ち・失敗時の終了コード、App Installer や Terminal が自己更新した後の窓の状態
- モジュールの実際の更新・削除。CLI の引数も模擬の関数で受けただけで、更新時のネイティブの処理は流していない
- この PC のモジュールの導入・削除、Windows／Store の更新、再起動は行っていない。上の結果を実更新の検証としては扱わない

### 付録: ロールバックの元値復元の模擬確認（2026-10-05）

- Linux の PowerShell 7.6.6 の構文解析器で、修正後の本書の PowerShell ブロック 107 個を解析し、構文の誤りは 0 だった
- 実施手順 18・47 とロールバックの手順 16・29 を本文から抜き出し、設定の読み書きだけを偽物のコマンドレットに置き換えた
  - 実行ポリシー: 元の `CurrentUser` が `Undefined`・`Restricted`・`AllSigned`・`RemoteSigned`・`Unrestricted`・`Bypass` の 6 通りで、実施後に元値へ戻った
  - 配信の最適化: 元の値が `Internet`・`Lan`・`CdnOnly` の 3 通りで、実施後に元値へ戻った
  - どちらも、元値が空または不正なら設定の読み書きを呼ばず、設定の書き込みが失敗した場合はその後の読み戻しへ進まなかった
- Windows PowerShell 5.1 での実行、Windows の実設定の復元、グループ ポリシーがある PC では確認していない


### 付録: リモート再起動の節の資料とブロックの確認（2026-10-06）

「リモートから再起動する手段を増やす（任意）」を足したときに、資料と PowerShell のブロックを、Linux（クラウドのコンテナ、Ubuntu 24.04）の PowerShell 7.6.6 と PSScriptAnalyzer 1.25.0 で確かめた。Windows では貼っていない。

**資料**:

- MS-RSP の transport: InitShutdown・WinReg の各インターフェイスは名前付きパイプ（`\PIPE\InitShutdown`・`\PIPE\winreg`、SMB の ncacn_np）、WindowsShutdown だけが TCP（ncacn_ip_tcp の動的エンドポイント）。`shutdown /m` と `net rpc shutdown` は InitShutdown を使うので、SMB（445）だけでよい
- 「リモート システムからの強制シャットダウン」（`SeRemoteShutdownPrivilege`）: 既定はスタンドアロンのサーバー・クライアントとも Administrators。この権限を持つアカウントだけが遠隔から再起動できる
- `LocalAccountTokenFilterPolicy`: 無い（既定）と 0 は、ローカル・Microsoft アカウントのネットワークログオンのトークンを絞り、管理の操作を断る。1 で完全な管理者のトークンになる
- `CrashControl\AutoReboot`（`Win32_OSRecoveryConfiguration.AutoReboot`）: 既定 1。ストップ エラーの後に自動で再起動する
- Samba の `net(8)`: `net rpc shutdown [-t timeout] [-r] [-f] [-C message]`、`-I ipaddress`、`-U [DOMAIN\]USERNAME[%PASSWORD]`。Windows の `shutdown` は `/r`・`/f`・`/t`・`/m \\<host>`
- `Enable-PSRemoting`/`Disable-PSRemoting`: 有効化は WinRM の開始・リスナー・規則・`LocalAccountTokenFilterPolicy=1`。無効化はセッション構成だけを戻すので、サービス・規則・ポリシーは手で戻す

**構文と Windows PowerShell 5.1 との互換**:

- この節の `powershell` のブロック 10 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）。見張りタスクの中の `.ps1`（here-string）も、取り出して通した（誤り 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の 5.1 のプロファイル）を当てた。指摘は `Set-ItemProperty` の `-Type`（レジストリのプロバイダーが足す動的なパラメーター。ほかの手順と同じ既知の偽陽性）だけで、ほかの互換の指摘は 0

**偽物のコマンドレットで流したブロック**（Linux の pwsh。レジストリは、値を覚えておく偽物に置き換えた）:

| 対象 | 流した場合 | 結果 |
|---|---|---|
| 見張りスクリプト（手順 6 の `.ps1`） | 稼働 10 分、稼働 120 分で届く・届かない（しきい値未満・到達）、記録のキーが無い | 稼働 60 分未満と、届いたときは `Fails` を 0 にして再起動せず。届かないと加算し、6 回目（しきい値）でだけ `Restart-Computer -Force` を呼んで 0 に戻した |
| 手順 7（Remote Control のトリガー） | `claude-remote-control` のタスクが無い | `中断:` で止まり、`Set-ScheduledTask` を呼ばなかった |
| 手順 6 の始めの検査 | 管理者でない・`$WATCHDOG_HOST` が空 | `中断:` で止まり、ファイルの作成・タスクの登録へ進まなかった |

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. 別の PC から `net rpc shutdown`（AlmaLinux）・`shutdown /r /m`（Windows）・WinRM の `Invoke-Command { Restart-Computer }` で、実際に再起動できること。`FPS-SMB-In-TCP`・`WINRM-HTTP-In-TCP*` の規則名が版・機種で一致すること
1. 見張りタスクが、ネットワークが切れたときに約 30 分で再起動し、一時的な切断では再起動しないこと。相手がずっと落ちているときのループ
1. 再起動の後に SSH（sshd）・RDP が自動で戻ること、手順 7 のログオンのトリガーで Remote Control が戻ること
1. Microsoft アカウントでの SMB・WinRM の認証、`LocalAccountTokenFilterPolicy` の戻し
1. `Register-ScheduledTask`・`Set-NetFirewallRule`・`Enable-PSRemoting` など、Windows 専用のコマンドレットの実際の動作（Linux の pwsh には無いので模擬・資料まで）

### 操作上の注意と併記されていた記録

   - **注意**: この後は Hyper-V が動くので、[VirtualBox](../virtualbox.md#windows-11-で使う) の VM は Hyper-V の上で動く（遅くなり、[virtualbox-guest-bootc.md](../virtualbox-guest-bootc.md) の検証では VM が数分ずつ止まった）


### 操作上の注意と併記されていた記録

   - Microsoft アカウントのときの `Username` と `Domain` の入れ方は確かめていない（この手順の補足）


### 実施手順 / 手順 26: 補足: この設定の仕組み

- Windows 11 のエクスプローラーは、右クリックで新しい形のメニューを出し、その中の「その他のオプションを確認」（Shift+F10 か Shift+右クリックでも）で旧形式のメニューを出す
- 新しい形のメニューは、CLSID `{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}` の COM のクラスが出している。自分のユーザーの `HKCU\Software\Classes\CLSID` に同じ CLSID の `InprocServer32` を空の既定の値で置くと、そのクラスを読めなくなり、エクスプローラーは最初から旧形式のメニューを出す
- Microsoft が説明している設定ではない（サポート外）。広く使われている方法で、25H2 でも効くという記事が複数ある（本書では確かめていない）
- 自分のユーザーだけにかかり、管理者の権限は要らない。消せば元に戻る（[ロールバック](../windows-setup.md#ロールバック)の手順 2）
- PowerShell の `New-Item -Force` で作らず `reg.exe` を使うのは、`New-Item -Force` が既にあるキーを作り直して中の値を消すため。`reg.exe add /f /ve` は既定の値だけを書く



### 実施手順 / 手順 28: 補足: 値の意味とウィジェットのボタン

- `TaskbarAl`: 0 で左、1（か値が無い）で中央
- `ShowTaskViewButton`: 0 でタスク ビューのボタンを消す
- `ShowSecondsInSystemClock`: 1 で時計に秒を出す（22H2 の 2023 年 5 月の更新から。設定の「個人用設定」→「タスク バー」→「タスク バーの動作」の「システム トレイの時計に秒を表示する」）
- `SearchboxTaskbarMode`（`Explorer\Advanced` ではなく `Search` の下）: 0 で消す、1 でアイコンだけ、2 で検索ボックス、3 でアイコンとラベル。スタートを開いて文字を打てば、検索はそのまま使える
- 4 つとも、Microsoft の DSC のリソース（`Microsoft.Windows.Developer` の `Taskbar`）が同じ値を書く。同じリソースはこの 4 つでエクスプローラーを起動し直さないので、タスクバーはすぐに読み直すはず（確かめていない）
- ウィジェットのボタンの値（`TaskbarDa`）は、24H2 から UCPD（ユーザーの選択を守るドライバー）が守っていて、PowerShell・`reg.exe` からは書けない（「アクセスが拒否されました」になると広く報告されている）。設定の画面（「個人用設定」→「タスク バー」→「ウィジェット」）からは切れる。本書は、手順 34 でウィジェットそのものを外す



### 実施手順 / 手順 31: 補足: レジストリに書かない理由と、Ctrl+Space の取り合い

- この設定のレジストリの値は、Microsoft の文書に無い。ある開発者が設定の画面の前後で見比べた記録（`HKCU\Software\Microsoft\IME\15.0\IMEJP\MSIME` の `IsKeyAssignmentEnabled` を 1、`KeyAssignmentCtrlSpace` を 2）はあるが、同じ人が「動いている IME に効く時期が保証されない」として書くのを避けている。本書も画面で変える
- 割り当てられるキーは、無変換・変換・Ctrl+Space・Shift+Space。Ctrl+Space には、最初は何も割り当てられていない
- Windows が Ctrl+Space を使うのは、中国語の IME のオン・オフだけ（Microsoft のキーボード ショートカットの文書）。日本語だけの PC では、Windows の操作とはぶつからない
- IME が Ctrl+Space を取るので、アプリの Ctrl+Space は効かなくなるはず（PowerShell の PSReadLine の `MenuComplete`、VS Code の候補の表示、Excel の列の選択など。確かめていない）
- 英数と日本語の切り替えの既定の Win+Space（入力言語の切り替え）と、半角/全角のキーはそのまま使える



### 実施手順 / 手順 44: 補足: 有効にする値と、規則を絞ること

- `fDenyTSConnections` を 0 にすると、リモート デスクトップの接続を受け付ける（1 が既定で、受け付けない）。`UserAuthentication` を 1 にすると、ネットワーク レベル認証（NLA）を求める（設定の画面で有効にしたときの既定）。どちらも Microsoft の文書（Azure の VM のリモート デスクトップの切り分け）にある値
- 受信の規則は、表示の名前が日本語に訳されるので、Microsoft の勧める形（`@FirewallAPI.dll,-28752` のグループ）で指定する。規則の名前は `RemoteDesktop-UserMode-In-TCP`・`-UDP` など（3389 番）
- `-Profile Private` で、プライベートの LAN（手順 43）からだけ受け付ける。持ち出した先のパブリックの Wi-Fi では開かない。[Windows の OpenSSH サーバー](../windows-openssh-server.md)の検証の PC は、規則がすべてのプロファイルで有効だった
- 設定の画面でリモート デスクトップをオンとオフにし直すと、規則のプロファイルが戻るかは確かめていない。画面で変えたら、この手順の最後の行で確かめ直す
- 元に戻すのは[ロールバック](../windows-setup.md#ロールバック)の手順 32



### 実施手順 / 手順 50: 補足: 場所とポリシー

- Edge のショートカットは、すべてのユーザーのデスクトップ（`C:\Users\Public\Desktop`）にある。ここは管理者でないと消せない。名前は `Microsoft Edge.lnk`（製品の名前なので訳されないはず。確かめていない）
- UniGet UI のショートカットは、手順 22 で入れたときに自分のデスクトップにできる（インストーラの定義の `{autodesktop}\UniGetUI`）。OneDrive でデスクトップをバックアップしていると場所が変わるので、`GetFolderPath('Desktop')` で探す
- Edge のショートカットは、Edge の更新で作り直されることがある。Edge Update のポリシー `RemoveDesktopShortcutDefault` を 1 にすると、Edge の更新や再起動のときに、すべてのユーザーのデスクトップの Edge のショートカットを消す（Microsoft の文書。Edge Update 1.3.155.1 から）。`CreateDesktopShortcutDefault` は、Edge が入っていると効かない（同じ文書）
- 元に戻すのは[ロールバック](../windows-setup.md#ロールバック)の手順 24（ポリシーだけ。消したショートカットは戻らない）



### 実施手順 / 手順 59: 補足: UniGet UI と scoop

- UniGet UI は、`PATH` から `scoop.ps1` を探して scoop を見つける。PowerShell 7（`pwsh.exe`）があればそれで、無ければ Windows PowerShell 5.1 で、`-ExecutionPolicy Bypass` を付けて動かす（ソースの `Scoop.cs`）
- UniGet UI は、scoop の更新に git が要るとして、無ければ `scoop install main/git` を勧める（同じソース）。本書は git を Git for Windows にそろえるので、勧めに従わない（[選択した方針](../verification/windows-setup.md#選択した方針)）
- UniGet UI は、手順 22 で入れたときに、サインインのときに起動する設定（`Run` の `WingetUI`）も作る。手順 32 では止めていない
- 画面の文言と並びは、Windows で確かめていない



### 選択した方針

**scoop**

| 経路 | 状況 | 採否 |
|---|---|---|
| **公式のインストーラ（`get.scoop.sh`）を管理者ではない PowerShell で** | 公式の README の方法。自分のユーザーの `~\scoop` に入る | **採用** |
| 管理者の PowerShell で `-RunAsAdmin` を付ける | 公式の README が安全のために既定で止めている | 不採用 |

**UniGet UI**

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `Devolutions.UniGetUI` を `--scope user` で** | 公式の README の筆頭。Devolutions のインストーラを、sha256 を確かめて自分のユーザーに入れる。UniGet UI 自身の更新とぶつからない | **採用** |
| winget の `--scope machine` | `%ProgramFiles%\UniGetUI` に入り、管理者の確認が要る | 不採用（自分のユーザーで足りる） |
| scoop の `extras/unigetui` | 同じ版の zip を、`ForceUniGetUIPortable` を置いたポータブル版として入れる。UniGet UI の自動の更新は、ポータブル版をその場（scoop の版のフォルダー）で上書きするので、scoop の記録とずれる | 不採用 |
| Microsoft Store・インストーラの直接の実行・Chocolatey | README にある。Store は画面の操作、Chocolatey は別のパッケージ マネージャーを足すことになる | 不採用 |

**Caps Lock を Ctrl に**

| 経路 | 状況 | 採否 |
|---|---|---|
| **Scancode Map（レジストリ）** | Microsoft の文書の方法。常駐するアプリが要らない（サインインの画面や管理者の窓でも効くはず。確かめていない）。管理者の権限と再起動が要り、すべてのユーザー・すべてのキーボードにかかる | **採用** |
| PowerToys の Keyboard Manager | 再起動が要らず、ユーザーごと。PowerToys が動いている間だけ効き、サインインの画面では効かず、管理者の窓には PowerToys を管理者で動かさないと効かない（Microsoft の文書） | 不採用（PowerToys は手順 23 で入れるが、Caps Lock には使わない） |
| Sysinternals の Ctrl2Cap | キーボードのフィルター ドライバーを入れる | 不採用（ドライバーを足さずに済む方法がある） |

**旧形式のコンテキストメニュー**

| 経路 | 状況 | 採否 |
|---|---|---|
| **`HKCU\Software\Classes\CLSID\{86ca1aa0-…}\InprocServer32` を空にする** | 自分のユーザーだけ、管理者は要らない。サポート外 | **採用** |
| 何もしない（「その他のオプションを確認」か Shift+右クリック） | 毎回 1 手間かかる | 不採用 |

**貼り付けの設定（手順 16〜19）**

**LAN をプライベートに（手順 43）**

- もとは [Windows の OpenSSH サーバー](../windows-openssh-server.md)の手順 5 と、[Syncthing の Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 7 の両方で、同じ操作をしていた。インストール直後に 1 度行うものなので、ここへまとめ、2 つの手順書は確かめるだけにした
- 規則をパブリックにも広げる方法は採らない。持ち出した先でも、同じサブネットの相手に開くため（OpenSSH サーバーの[選択した方針](windows-openssh-server.md#選択した方針)）

**表示・整理の設定（手順 25〜34）**

- **レジストリに書けるものは書き、書けないもの・Microsoft の文書が無く効く時期が読めないものは画面で行う**
  - エクスプローラー・スタート・タスクバー・ダークモード・既定の端末・自動で起動するアプリは、自分のユーザーのレジストリに書く。多くは Microsoft の DSC のリソース（`microsoft/winget-dsc`）が同じ値を書いている
  - IME の Ctrl+Space（手順 31）は、レジストリの値が Microsoft の文書に無く、効く時期も分からないので、設定の画面を開いて変える
  - タスクバーとスタートのピン留め（手順 58）は、自分のユーザーで使える、サポートされたコマンドが無い（ポリシーとプロビジョニングだけ）ので、画面で外す
  - ウィジェットのボタン（`TaskbarDa`）は UCPD が守っていて書けないので、ウィジェットそのものを外す（手順 34）
- **標準アプリは、自分のユーザーから外す（`Remove-AppxPackage`）**: 管理者の権限が要らず、ストアからいつでも入れ直せる。PC に置かれた元（プロビジョニング）を外す方法は、ほかのユーザーにもかかるので採らない。そのため、機能の更新の後に戻ってくることがある
- **自動で起動するアプリは、消さずに止める**: タスク マネージャーと同じ所（`StartupApproved\Run`）に書き、いつでもタスク マネージャーから戻せるようにした

**PC 全体・ネットワーク・サインイン（手順 39〜54・64）**

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| PC の名前 | `Rename-Computer`（15 文字までをブロックで確かめる） | `-Force`: 15 文字を超える名前を黙って短くする |
| sudo | `sudo config --enable normal`（インライン。利用者の選択） | 既定の `forceNewWindow`: Microsoft が勧める形だが、新しい窓が開く |
| 電源 | `powercfg`（電源接続中だけスリープと蓋の動作を止め、休止状態は電源に関係なく切る） | バッテリーのときもスリープしない: 持ち出したノート PC の電池が減る |
| 放置したときのロック | 電源接続中の `CONSOLELOCK` と、電源に関係なくかかる Modern Standby の `DelayLockInterval` | ポリシー（`InactivityTimeoutSecs`）: ロックさせる側の設定 |
| アダプターの省電力 | `Get-NetAdapterPowerManagement` で取ったものを変えて `-NoRestart` で渡す | `PnPCapabilities`（Windows 7 の頃のサポートの記事の値）: 起動し直しが要る |
| リモート デスクトップ | レジストリと、組み込みの規則をプライベートに絞る | 規則をそのまま（すべてのプロファイル）: 持ち出した先で開く |
| ping | 自分の名前とグループの規則（プライベート） | 組み込みの「ファイルとプリンターの共有」の規則: その共有の設定と一緒に変わる |
| 配信の最適化 | `Set-DODownloadMode`（設定の画面と同じ） | ポリシー（`DODownloadMode`）: 設定の画面で変えられなくなる |
| スタートの検索の Web の結果 | `HKCU` のポリシー `DisableSearchBoxSuggestions`（管理者の窓で書く） | `BingSearchEnabled`: Windows 11 で効く根拠が無い |
| Edge のショートカット | 消して、Edge Update の `RemoveDesktopShortcutDefault` | `CreateDesktopShortcutDefault`: Edge が入っていると効かない（Microsoft の文書） |
| PowerShell 7 | winget の既定（MSIX、自分のユーザー） | MSI（`--installer-type wix`）: 7.7.0 から無くなる（Microsoft の文書） |
| WSL | `wsl --install --no-distribution` を再起動の前に、ディストリビューションを後に | 1 回の `wsl --install AlmaLinux-10`: 機能を入れた直後は再起動が要り、ユーザーの作成と順が前後する |
| 自動サインイン | Sysinternals の Autologon の窓でパスワードを入れる（LSA のシークレットに置く） | Autologon のコマンド ラインでパスワードを渡す: プロセスのコマンド ラインと履歴に残る。`Winlogon` の `DefaultPassword` に書く: 平文で残る |

**アプリの置き場所**

- Git for Windows・Firefox・WezTerm・Claude Code・VirtualBox・WireGuard・HackGen Console NF は、AlmaLinux 10 でも使うツールなので、それぞれの手順書の Windows 11 の節に置いた（同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、1 つの手順書にする）。この文書のリードから、入れる順に案内する
- PowerToys・PowerShell 7・Autologon・WSL は、このリポジトリでは Windows でだけ使うので、この文書に置いた
- **scoop の `git` は入れない**: git は [git.md](../git.md#windows-11-で-git-for-windows-を入れる) の Git for Windows（`C:\Program Files\Git`）にそろえる。ほかの手順書（OpenSSH サーバーの既定のシェル、Claude Code）がその場所を使う。scoop は `PATH` の `git` を使い、git 無しで入れた scoop も、Git for Windows を入れた後の `scoop update` で git の形に直る（scoop 0.6.0 の `libexec/scoop-update.ps1`）

**窓と再起動**

- **管理者ではない PowerShell と管理者の PowerShell を分けた**
  - scoop のインストーラは、管理者の PowerShell では止まる。scoop・UniGet UI・PowerToys（自分のユーザーへの導入）と、自分のユーザーの表示の設定は、どれも管理者の権限が要らない
  - PC 全体の設定（`HKLM`・ファイアウォール・電源・機能）と、管理者しか書けない `HKCU\Software\Policies` だけ、管理者の PowerShell で行う
  - そのため、[Windows の OpenSSH サーバー](../windows-openssh-server.md)の SSH のセッション（Administrators の一員なら管理者の権限で動く）には貼らない
- **設定のための再起動を 1 回にまとめた**: Scancode Map・PC の名前・キーボードの種類・WSL の機能は再起動、エクスプローラーの設定はエクスプローラーの起動し直しで効く。再起動 1 回で全部効く（hackgen.md の Windows のフォントも、サインインし直す代わりにこの再起動で効く）。Windows Update は先に手順 1〜8 で済ませ、必要な再起動は手順 8 で行う
- **Windows PowerShell 5.1 にそろえた**: Windows 11 に最初からあり、ほかの Windows の手順書とも同じ。実行ポリシーとプロファイルは PowerShell 7 と別に持つので、5.1 の値を変える

## 参考資料から分離した記録

### 参考資料: 実施手順 / 手順 36: 補足: 変数について

- `$PC_NAME` は手順 39（PC の名前を変える）で使う
- `$LAN_IF` は、手順 37（今の状態）・手順 42（アダプターの省電力）・手順 43（プライベートにする）で使う。式は [Windows の OpenSSH サーバー](../windows-openssh-server.md)の手順 2 と同じ
- 接続の一覧は `Get-NetConnectionProfile` で見られる。[Windows の OpenSSH サーバー](../windows-openssh-server.md)の検証の PC では、WSL を動かしていても `vEthernet (WSL (Hyper-V firewall))` は一覧に出ず、有線 LAN の 1 行だけだった

### 参考資料: 実施手順 / 手順 45: 補足: リモート アシスタンス

- リモート アシスタンス（Windows の「クイック アシスト」とは別）は、ほかの人を招いて画面を見せる古い仕組み。システムのプロパティの「リモート」タブの「このコンピューターへのリモート アシスタンス接続を許可する」が `fAllowToGetHelp`
- [Windows の OpenSSH サーバー](../windows-openssh-server.md)の検証の PC では、LAN をプライベートにすると、リモート アシスタンスの受信の規則 4 本が効くようになった（手順 43 の補足）
- グループの ID `@FirewallAPI.dll,-33002` は、Microsoft の文書には無い（Windows の `racpldlg.dll` の文字列にある）。違っていたら、`Get-NetFirewallRule | Sort-Object Group -Unique | Format-Table DisplayGroup, Group` で「リモート アシスタンス」の行の `Group` を見る
- Microsoft の無人インストールの文書は、`fAllowToGetHelp` の既定を無効と書いているが、店頭の Windows では有効なことが多いと報告されている。手順 37 の `RemoteAssistance` で、元の値を控える
- 元に戻すのは[ロールバック](../windows-setup.md#ロールバック)の手順 31

### 参考資料: 実施手順 / 手順 48: 補足: この設定と、リモート デスクトップ・SSH・自動サインイン

- 設定の「アカウント」→「サインイン オプション」の「セキュリティ向上のため、このデバイスでは Microsoft アカウント用に Windows Hello サインインのみを許可する」。値（2 がオン、0 がオフ）は Microsoft の文書に無く、広く使われているもの
- オンだと、Microsoft アカウントのパスワードでのリモート デスクトップに入れない、という Microsoft Q&A の回答がある。[Windows の OpenSSH サーバー](../windows-openssh-server.md#注意点)の検証の PC では、オンのまま SSH にパスワードで入れた（Q&A の報告とは違った）
- オンだと、自動サインイン（手順 64）の設定に要る「ユーザーがこのコンピューターを使うには、ユーザー名とパスワードの入力が必要」の項目が隠れると報告されている
- 元に戻すのは[ロールバック](../windows-setup.md#ロールバック)の手順 22

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 実施手順 / 手順 12

   - 終わったら手順 13 へ。まだ CLI が使えない場合は止める（この準備からの通し実行は未検証）

### 実施手順 / 手順 31

   - 設定の Microsoft IME の画面が開く。「キーとタッチのカスタマイズ」を開き、「キーの割り当て」をオンにして、「Ctrl + Space」を「IME-オン/オフ」にする（画面の文言は確かめていない）

### 実施手順 / 手順 54

   - 必要な機能（仮想マシン プラットフォーム）を入れた旨と、再起動を求める旨の行が出ればよい（出力は確かめていない）

### 実施手順 / 手順 58

   - 画面の文言は確かめていない

### ロールバック / 手順 7

   - 「キーとタッチのカスタマイズ」で、「Ctrl + Space」を「なし」にするか、「キーの割り当て」をオフにする（画面の文言は確かめていない）

### ロールバック / 手順 31

   - システムのプロパティの「リモート」タブが開く。「このコンピューターへのリモート アシスタンス接続を許可する」にチェックを入れて「OK」を押す（画面の文言は確かめていない）

   - この画面は、`fAllowToGetHelp` と、リモート アシスタンスの受信の規則をまとめて戻すはず（確かめていない）。規則をコマンドでまとめて有効にすると、手順 45 の前に無効だった規則（パブリック向けなど）まで有効になりうるので、画面で戻す

### 補足

- **JIS 配列では「英数」のキーが Ctrl になる**: 日本語の配列のキーボードの Caps Lock は「英数」のキー（スキャン コード `0x3A`）なので、そのキーの IME の働き（英数への切り替え）も無くなるはず（確かめていない）

- **リモート デスクトップと Scancode Map**: Microsoft の文書は、Scancode Map がターミナル サービスでは正しく働かないことがあると書いている。この PC にリモート デスクトップでつないだとき、つないだ側の PC でつないだときの効き方は確かめていない

- **このユーザーの Windows PowerShell のコンソールの窓すべてに効く**: 管理者の窓も同じプロファイルを読む。SSH でログインしたセッションの Windows PowerShell で、SSH のクライアントから貼ったときの動きは確かめていない
