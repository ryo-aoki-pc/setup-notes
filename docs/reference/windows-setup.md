# Windows 11 の初期設定の手順（インストール直後の更新・貼り付けの設定・scoop・UniGet UI・表示・電源・リモート・WSL・OpenSSH・Git・Firefox・WezTerm・Neovim・AI エージェント）の参考資料

[手順書](../windows-setup.md)・[ロールバックと注意点](../extra/windows-setup.md)

[検証記録](../verification/windows-setup.md#参考資料から分離した記録)

## 補足

### 実施手順 / Windows Update / 手順 1: 補足: 先に更新する理由

- インストールしたばかりの Windows は、インストールのメディアを作った時点の版。この後の手順には、新しい版を前提にするものがある（「PC 全体の設定」の手順 6 の sudo は 24H2 以降、「表示と入力」の手順 4 の時計の秒など）
- この後の「WSL と再起動」の手順 2 の再起動より前に、Windows Update の再起動を済ませておく。途中で更新の再起動が入ると、「PC 全体の設定」の手順 2 から「WSL と再起動」の手順 1 までの設定が効く時期が読みにくくなる

### 実施手順 / Windows Update / 手順 2: 補足: 今の窓だけにする理由

- `Process` の実行ポリシーと TLS 1.2 の追加は、この窓を閉じると無くなる。「貼り付けの設定」の手順 2 で控える `CurrentUser` の実行ポリシーは変えない
- 再起動したら「Windows Update」の手順 1・2・3 をもう一度通す。モジュールのファイルは残るが、新しい窓では読み込み直す必要がある
- グループ ポリシーによる制限は、この手順では変えない

### 実施手順 / Windows Update / 手順 4: 補足: 更新の対象

- Windows Update Agent の条件で、未導入（`IsInstalled=0`）・非表示でない（`IsHidden=0`）・自動更新の配信対象（`IsAssigned=1`）・オプションでない（`BrowseOnly=0`）ものに絞る
- オプションのドライバーやプレビュー更新は含めない。通常の自動配信に含まれるドライバーは対象になる
- 更新名の「Preview」「プレビュー」の文字では除外しないので、Windows の表示言語には依存しない
- 更新の取得先はこの PC の既定のまま。`-MicrosoftUpdate` による対象の拡大や、WSUS・Windows Update のポリシーの変更は行わない
- この手順はダウンロードとインストールを行わない

### 実施手順 / Windows Update / 手順 5: 補足: 自動では再起動しない

- `-AcceptAll` は対象の更新を承認する。検索条件は「Windows Update」の手順 4 と同じで、オプションの更新は増やさない
- `-IgnoreReboot` は、必要になっても再起動せず、再起動するかを聞く対話も出さない（PSWindowsUpdate のヘルプ）
- `-AutoReboot`・`-RecurseCycle` は使わない。再起動と再検索は「Windows Update」の手順 8 の後に自分で行い、再開用のタスクも作らない

### 実施手順 / Windows Update / 手順 5: 補足: Result の段階

- `Result` は、受け付け・ダウンロード・インストールの段階ごとに出る

### 実施手順 / Microsoft Store の更新 / 手順 1: 補足: 5.1 にする理由

- 実行ポリシーとプロファイルは、5.1 と 7 で別々に持つ

### 実施手順 / Microsoft Store の更新 / 手順 3: 補足: インストール直後の winget

- Microsoft の WinGet の文書は、初回サインイン後に Store が非同期で登録するため、まだ使えない場合にこの `Add-AppxPackage` を挙げている
- この文書は、アプリ インストーラーと Microsoft Store が含まれる Windows 11 を前提にする。これらを削ったイメージの復旧は扱わない

### 実施手順 / Microsoft Store の更新 / 手順 4: 補足: CLI を使えるようにする準備だけを winget で行う

- 製品 ID はアプリ インストーラーが `9NBLGGH4NNS1`、Microsoft Store が `9WZDNCRFJBMP`。`--exact` と `--source msstore` で、この 2 つだけを対象にする
- Store の配布情報は版が `Unknown` の場合があるので `--include-unknown` を付ける。`winget upgrade --all` に置き換えない
- `-1978335189`（`0x8A15002B`）は、winget の `UPDATE_NOT_APPLICABLE`（適用する更新が無い）。それ以外の失敗では中断する
- アプリ インストーラー、Microsoft Store の順に更新する

### 実施手順 / Microsoft Store の更新 / 手順 6: 補足: 対象

- 名前や発行元のフィルターは付けず、すべての Store アプリを対象にする

### 実施手順 / 貼り付けの設定 / 手順 1: 補足: 行を足す理由

- 「貼り付けの設定」の手順 2 から後の複数行のブロックを、この窓に右クリックで貼れるようにするため

### 実施手順 / 貼り付けの設定 / 手順 2: 補足: 見ているもの

- `Admin` は、この PowerShell が管理者の権限で動いているか（UAC で昇格しているか）。Administrators の一員でも、普通に開いた PowerShell は `False` になる
- `ClassicMenu` は、「表示と入力」の手順 2 で作るキー（`HKCU:\Software\Classes\CLSID\{86ca1aa0-…}`）があるか
- `ScancodeMap` は、「サインイン・検索・キーボード」の手順 4 で書く値（`HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout` の `Scancode Map`）を 16 進で並べたもの。読むだけなら管理者は要らない
- `$PROFILE` は、このユーザーの、Windows PowerShell のコンソールのプロファイル（`Microsoft.PowerShell_profile.ps1`）。管理者で開いた窓も、同じユーザーなら同じファイルを読む。PowerShell 7・PowerShell ISE・VS Code は別のファイルを読む（about_Profiles）。OneDrive でドキュメントをバックアップしていると、`OneDrive` の下のパスになる
- `Get-ExecutionPolicy -List` は、範囲（`MachinePolicy`・`UserPolicy`・`Process`・`CurrentUser`・`LocalMachine`）ごとの実行ポリシー。上の範囲ほど優先される。`MachinePolicy` か `UserPolicy` が `Undefined` でなければ、グループ ポリシーで決まっていて、「貼り付けの設定」の手順 3 では変えられない
- プロファイルもスクリプト（`.ps1`）なので、実行ポリシーが `Restricted` だと読まれない（Microsoft の about_Execution_Policies。`Restricted` は Windows のクライアントの既定）
- `Git` は、Git for Windows がもうあるか（無ければ空。この文書の後に [git.md](../windows-setup.md#git-for-windows) で入れる）
- `ProfileExists : False` なら、「貼り付けの設定」の手順 4 で作る
- `実行ポリシー:` が `RemoteSigned`・`Unrestricted`・`Bypass` のどれかなら、「貼り付けの設定」の手順 3 は何も変えない。Windows 11 の既定は `Restricted`（一覧はどれも `Undefined`）で、このままではプロファイルも scoop も動かない

### 実施手順 / 貼り付けの設定 / 手順 3: 補足: 何も書かないとき

- 今の値が `RemoteSigned`・`Unrestricted`・`Bypass` のどれかなら、何も書かない

### 実施手順 / 貼り付けの設定 / 手順 4: 補足: ほかの行と、この行を読む窓

- プロファイルにほかの行があれば、そのまま残る
- これより後に開く Windows PowerShell の窓（「PC 全体の設定」の手順 1 の管理者の窓も）は、この行を読む

### 実施手順 / アプリを入れる / 手順 1: 補足: インストーラのすること

- `https://get.scoop.sh` は、公式のインストーラ（`https://raw.githubusercontent.com/scoopinstaller/install/master/install.ps1`）へ飛ぶ。`Invoke-Expression` で、取ったスクリプトをそのまま動かす（公式の README の方法）
- 中身を読んでから動かすなら、`Invoke-RestMethod -Uri https://get.scoop.sh -OutFile install.ps1` で保存して読み、`.\install.ps1` で動かす（同じ README の方法）。インストーラに Authenticode の署名は無い
- インストーラは、PowerShell 5 以上・管理者でないこと・実行ポリシー・scoop がまだ無いことを確かめてから入れる
- 入るもの
  - `~\scoop\apps\scoop\current`（scoop 本体）・`~\scoop\buckets\main`（main のバケット）・`~\scoop\shims`（コマンドの入口）
  - ユーザーの環境変数 `PATH` の先頭に `~\scoop\shims` を足す。変えたことを Windows 全体に知らせる（`WM_SETTINGCHANGE`）ので、この後にスタートメニューから起動したアプリにも届く
  - 設定のファイル `~\.config\scoop\config.json`
- git があれば、本体と main のバケットを `git clone` で取る。無ければ zip で取る
- git の無い PC では、`scoop update` が `Scoop uses Git to update itself. Run 'scoop install git' and try again.` で止まる。この文書の後に [git.md](../windows-setup.md#git-for-windows) で Git for Windows を入れれば、`scoop update` は scoop 本体と main のバケットを git の形に直して上げる（scoop 0.6.0 の `libexec/scoop-update.ps1`。scoop の `git` は入れない。[選択した方針](../verification/windows-setup.md#選択した方針)）
- 管理者で入れる方法（インストーラの `-RunAsAdmin`）は、公式の README が安全のために既定で止めているので、使わない

### 実施手順 / アプリを入れる / 手順 2: 補足: 版

- `Current Scoop version:` の次の版は、実行した日の最新

### 実施手順 / アプリを入れる / 手順 3: 補足: winget のハッシュの確認と、版とショートカット

- winget はインストーラのハッシュを確かめてから入れる
- 最後の表の版は、実行した日の最新
- デスクトップに UniGetUI のショートカットができる（「サインイン・検索・キーボード」の手順 3 で消す）

### 実施手順 / アプリを入れる / 手順 4: 補足: 入れ方と入る場所

- winget の定義（`Microsoft.PowerToys` 0.101.2362.0）には、自分のユーザーに入れるインストーラ（`PowerToysUserSetup-<版>-x64.exe`。管理者の確認の指定が無い）と、PC 全体に入れるインストーラ（`PowerToysSetup-<版>-x64.exe`。`elevatesSelf`）がある。`--scope user` を付けて、自分のユーザーのほうを選ばせる
- インストーラの形式は WiX の Burn で、winget は `/quiet /norestart` を渡す
- 入る場所は、Microsoft の情報どうしで食い違う
  - Install PowerToys のページは、自分のユーザーなら `%USERPROFILE%\AppData\Local\Programs` の下と書く（下のフォルダーの名前は書かれていない）
  - インストーラのソース（`installer/PowerToysSetupVNext/Common.wxi` の `DefaultInstallDir` と `Product.wxs`）と、DSC・Peek のページは `%LOCALAPPDATA%\PowerToys`
  - そのため、[PowerToys のユーティリティを絞る（任意）](../windows-setup.md#powertoys-のユーティリティを絞る任意)は、場所を決め打ちせず、動いている PowerToys から取る
- PowerToys のいくつかの機能は、PowerToys を管理者として動かしていないと、管理者の窓には効かない（PowerToys の設定の「常に管理者として実行」）
- WebView2 のランタイムが無ければ一緒に入れる（Windows 11 には最初からある）

### 実施手順 / アプリを入れる / 手順 4: 補足: 版と、Caps Lock を変える所

- 最後の表の版は、実行した日の最新
- Caps Lock は、PowerToys の Keyboard Manager ではなく、「サインイン・検索・キーボード」の手順 4 の Scancode Map で変える（[選択した方針](../verification/windows-setup.md#選択した方針)）

### 実施手順 / アプリを入れる / 手順 5: 補足: MSIX と MSI

- Microsoft の文書は、winget のパッケージは 7.6.0 から既定で MSIX を入れると書いている。winget の定義（`Microsoft.PowerShell` 7.6.6.0）も、MSIX（自分のユーザー）を先に、MSI（PC 全体。`elevatesSelf`）を後に並べている
- MSIX は自分のユーザーだけに入り、更新は winget かストアで行う。PC 全体の実行ポリシーやリモートの受け口は設定できない（Microsoft の文書）。このリポジトリの使い方では足りる
- PC 全体の MSI（`$Env:ProgramFiles\PowerShell\7`、Microsoft Update で更新）にするなら `--installer-type wix` を付ける。ただし Microsoft の文書では、7.7.0 から MSI は無くなる
- PowerShell 7.6.6 の PSReadLine 2.4.5 も、Ctrl+Enter は `InsertLineAbove`。PowerShell 7 の窓に右クリックで貼ると、同じように逆順になるはず（「貼り付けの設定」の手順 4 は PowerShell 7 のプロファイルには書かない。[注意点](../extra/windows-setup.md#注意点)）
- winget の既定の範囲: 設定（`settings.json`）の `installBehavior.preferences.scope` は、書かなくても `user`（winget の `UserSettings.h`）で、user のインストーラが無ければ machine を選ぶ。そのため、範囲を変える設定は足さない
  - PowerShell 7 の MSIX（範囲の宣言が無い）と MSI（machine）は、どちらも user に当たらない。インストーラの種類の順（MSIX が MSI より先）で MSIX が選ばれる
  - `installBehavior.requirements.scope` は絞り込みで、machine だけのパッケージと、範囲を宣言しないインストーラ（MSIX・Store・持ち運び版・フォントを除く）が外れるので書かない。UniGet UI のスコープも「デフォルト」のまま（「ユーザー | ローカル」は `--scope user` を付ける）
- 管理者の確認（UAC）が出ないのは、MSIX のパッケージで、自分のユーザーに入るため

### 実施手順 / アプリを入れる / 手順 5: 補足: 版とスタートメニュー

- 最後の表の版は、実行した日の最新
- スタートメニューに「PowerShell 7」ができる

### 実施手順 / 表示と入力 / 手順 3: 補足: 貼る順と、Web の結果

- 「自動起動と標準アプリ」の手順 2 より前に貼るのは、外したアプリが戻らないようにするため（`SilentInstalledAppsEnabled`）
- スタートの検索の Web（Bing）の結果は、管理者の権限が要るので、「サインイン・検索・キーボード」の手順 2 で切る

### 実施手順 / 表示と入力 / 手順 4: 補足: ウィジェットのボタン

- ウィジェットのボタンは、「自動起動と標準アプリ」の手順 3 でウィジェットを外すと消える（この手順では書けない）

### 実施手順 / 表示と入力 / 手順 5: 補足: 値の意味

- `AppsUseLightTheme` はアプリ、`SystemUsesLightTheme` はタスクバー・スタート・通知の色。0 で濃色、1 で淡色（Windows 11 の既定）
- Microsoft の DSC のリソース（`Microsoft.Windows.Settings`）も同じ 2 つを書き、すぐに効かせるために `WM_SETTINGCHANGE`（`ImmersiveColorSet`）を全部の窓に送る。本書は、「WSL と再起動」の手順 2 で再起動するので送らない
- 設定の「個人用設定」→「色」から変えると、すぐに効く

### 実施手順 / 表示と入力 / 手順 6: 補足: 値と、管理者の窓が conhost になる理由

- 値は、Windows Terminal の文書（グループ ポリシーの「既定のターミナル アプリケーション」）にある GUID。Windows Terminal は `DelegationConsole` が `{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}`、`DelegationTerminal` が `{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}`
- Windows 11 22H2 以降の既定は「Windows に任せる」（2 つとも `{00000000-0000-0000-0000-000000000000}`）で、Windows Terminal が入っていればそれを使う（Microsoft のサポートの記事）。この手順は、それを Windows Terminal に決める
- 管理者として起動したコンソールは、既定の端末に引き渡されず、conhost で開く。Windows Terminal の課題（microsoft/terminal の #13392。「管理者のコマンド ラインの受け手として登録できる端末は無く、COM の側の対応が要る」）が開いたまま。管理者の Windows Terminal は、Win+X の「ターミナル (管理者)」で開ける
- 設定の「システム」→「開発者向け」→「ターミナル」と、Windows Terminal の設定の「スタートアップ」→「既定のターミナル アプリケーション」でも変えられる

### 実施手順 / 自動起動と標準アプリ / 手順 1: 補足: タスク マネージャーと同じ所に書く

- タスク マネージャーの「スタートアップ アプリ」と設定の「アプリ」→「スタートアップ」は、`Run` の値を消さずに、`Explorer\StartupApproved\Run` に同じ名前の値（バイナリ）を書く。先頭の 1 バイトが 2 なら起動し、3（と、止めた日時の 8 バイト）なら止める。Microsoft の文書には無いが、広く知られた形（UniGet UI のインストーラも同じ所に書く）
- OneDrive の値の名前は `OneDrive`、Edge は `MicrosoftEdgeAutoLaunch_<文字列>`。OneDrive は OneDrive の設定の「Windows にサインインしたときに OneDrive を自動的に開始する」でも止められる
- Teams（新しい Teams。「自動起動と標準アプリ」の手順 2 で外す）はパッケージのアプリで、起動のタスク `TeamsTfwStartupTask` の `State` を 1（「ユーザーが無効にした」）にする。値の意味は Microsoft の文書（`StartupTaskState`）にある
- 消すのではなく止めるので、タスク マネージャーからいつでも戻せる（[ロールバックの「表示と入力を戻す」](../extra/windows-setup.md#表示と入力を戻す)の手順 8）
- 初回導入用の `OneDriveSetup` の項目も、残っていれば止める。実行ファイルがある場合は初回インストールも延期される
- UniGet UI（`WingetUI`）は、更新を知らせるために起動する

### 実施手順 / 自動起動と標準アプリ / 手順 2: 補足: 外さないもの

- Copilot（`Microsoft.Copilot`）は外さない。`Microsoft.MicrosoftOfficeHub` はストアの名前が「Microsoft 365 Copilot」になった別のアプリ（Office の入口）

### 実施手順 / 自動起動と標準アプリ / 手順 3: 補足: ウィジェットを外すこと

- ウィジェットの本体は、ストアのアプリ「Windows Web Experience Pack」（`MicrosoftWindows.Client.WebExperience`、ストアの ID は `9MSSGKG348SP`）。外すとボタンも消えると広く報告されている（Microsoft の文書には無い）
- ボタンだけを消す値（`TaskbarDa`）は、PowerShell からは書けない（「表示と入力」の手順 4 の補足）
- Microsoft が説明している止め方は、管理者のポリシー（「ウィジェットを許可する」）。本書では使わない

### 実施手順 / PC 全体の設定 / 手順 1: 補足: プロファイルの行

- この窓は、「貼り付けの設定」の手順 4 でプロファイルに書いた行を読む（「PC 全体の設定」の手順 3 で確かめる）

### 実施手順 / PC 全体の設定 / 手順 2: 補足: 変数について

- `$PC_NAME` は「PC 全体の設定」の手順 5（PC の名前を変える）で使う
- `$LAN_IF` は、「PC 全体の設定」の手順 3（今の状態）・同じ項の手順 8（アダプターの省電力）と「ネットワークとリモート」の手順 1（プライベートにする）で使う。式は [Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)の手順 2 と同じ
- 接続の一覧は `Get-NetConnectionProfile` で見られる

### 実施手順 / PC 全体の設定 / 手順 3: 補足: 見ているもの

- `CtrlEnter` は、この窓の PSReadLine の Ctrl+Enter の働き。「貼り付けの設定」の手順 4 のプロファイルを読んでいれば `AddLine`、読んでいなければ既定の `InsertLineAbove`
- `Edition` は `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion` の `EditionID`。`Core`・`CoreN`・`CoreSingleLanguage`・`CoreCountrySpecific` が Home、`Professional` などが Pro。Microsoft の文書では、Home はリモート デスクトップでつながれる側になれない
- `Sudo` は、Windows に入っている `sudo.exe` の場所。Microsoft の文書では、sudo は 24H2 以降
- `Hypervisor` は、Windows のハイパーバイザー（Hyper-V）が動いているか。WSL 2（「WSL と再起動」の手順 1）・メモリ整合性・Credential Guard などで動く
- `Get-DODownloadMode` は、配信の最適化のモード（`CdnOnly`・`Lan`・`Internet` など）
- `Version` が 24H2（ビルド 26100）より前で `Sudo` が空なら、「PC 全体の設定」の手順 6 の sudo の行は何もしない
- `Hypervisor : True` なら、Hyper-V がもう動いている（[VirtualBox の Windows 11 の節](../virtualbox.md#windows-11-で使う)の VM は、その上で動く）

### 実施手順 / PC 全体の設定 / 手順 5: 補足: 名前の決まりと、確認の問いを出さないこと

- Windows の PC の名前は 15 文字まで（NetBIOS の名前の長さ）で、使える文字は英字・数字・ハイフン。先頭は英数字で、末尾はハイフンにしない（Microsoft の文書。数字だけの名前はドメインに入れない）
- `Rename-Computer` は、15 文字を超える名前だと「短くするが続けるか」を聞く（`-Force` で聞かない）。聞かれると、続けて貼った行が答えとして食われるので、ブロックで先に 15 文字までかを確かめて止める
- 今と同じ名前を渡すと、`Rename-Computer` はエラー（`NewNameIsOldName`）を出すので、先に比べる
- SSH・リモート デスクトップ・Syncthing は、この名前でこの PC を見分ける。Syncthing のデバイスの名前は最初の起動のときの PC の名前になるので、Syncthing より先に変える

### 実施手順 / PC 全体の設定 / 手順 6: 補足: 3 つの設定

- **長いパス**: `HKLM\SYSTEM\CurrentControlSet\Control\FileSystem` の `LongPathsEnabled` を 1 にすると、260 文字を超えるパスを、それを宣言したアプリ（マニフェストの `longPathAware`）が使える（Microsoft の文書）。エクスプローラーなど、宣言していないアプリは変わらない。プロセスが最初に使うときに読むので、効くのは「WSL と再起動」の手順 2 の再起動の後。Git for Windows には別に `core.longpaths` がある
- **開発者モード**: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock` の `AllowDevelopmentWithoutDevLicense` を 1（Microsoft の文書の `reg add` と同じ値）。管理者でなくてもシンボリック リンクを作れる（`mklink` や Git for Windows のように、作る側がその印を渡すとき）。Microsoft の文書では、レジストリで有効にしても、設定の画面で有効にしたときと違い、デバイスのポータルなどは入らない
- **sudo**: Windows 11 24H2 から Windows に入っている `sudo.exe`。`sudo config --enable` の形は 3 つ（Microsoft の文書）
  - `forceNewWindow`（既定）: 管理者のコマンドを新しい窓で動かす。Microsoft が勧める形
  - `disableInput`: 今の窓に出すが、入力を受け付けない
  - `normal`（インライン）: 今の窓で入出力する。Linux の sudo に近い。同じ窓のほかのプロセスが、管理者のプロセスを操作できるおそれがあると Microsoft は書いている
  - 利用者の選択で `normal` にした。値は `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo` の `Enabled`（0 が無効、1〜3 が上の順。microsoft/sudo のソース）
- 3 つとも、設定の「システム」→「開発者向け」（25H2 では「システム」→「詳細設定」）でも変えられる
- 管理者ではない窓で `sudo <コマンド>` を打つと、UAC の確認の後に、同じ窓でそのコマンドが管理者の権限で動く

### 実施手順 / PC 全体の設定 / 手順 7: 補足: どの設定で何が変わるか

- `standby-timeout-ac 0`: 電源につないでいる間、放置しても眠らない（`SUB_SLEEP` の `STANDBYIDLE` を 0 にするのと同じ。Microsoft の文書）
- `/hibernate off`: 休止状態を切り、`hiberfil.sys` を消す。高速スタートアップもこのファイルを使うので、使えなくなる（ハイブリッド スリープも）。Wake on LAN でシャットダウンから起こす（[任意節](../windows-setup.md#wake-on-lan-を使う任意)）には、高速スタートアップを切る必要がある
- `LIDACTION` を 0: 電源につないでいる間、蓋を閉じても何もしない（1 が眠る、2 が休止状態、3 がシャットダウン）。`/setactive SCHEME_CURRENT` で、今の電源プランに効かせる
- `CONSOLELOCK` を 0: 電源につないでいる間、眠りから戻ったときにサインインを求めない（既定は 1）。眠らないようにしても、手で眠らせたときのため
- `DelayLockInterval` を `0xFFFFFFFF`: Modern Standby（S0）の PC で、画面が消えた後のロック（設定の「アカウント」→「サインイン オプション」の「一定時間不在にした場合、もう一度サインインを求めるタイミング」）を「しない」にする。この値は Microsoft の文書に無く、広く使われているもの。S3 の PC では、画面が消えるだけではロックしない（ロックするのは、眠り・パスワード付きのスクリーン セーバー・ポリシー・動的ロック）
- Modern Standby の PC かは、`powercfg /a` に「スタンバイ (S0 低電力アイドル)」が出るかで分かる
- 元に戻すのは[ロールバックの「ネットワークと PC 全体の設定を戻す」](../extra/windows-setup.md#ネットワークと-pc-全体の設定を戻す)の手順 7（電源プランを既定に戻す。ほかに変えた電源の設定も戻る）
- 画面を消す時間は変えない
- バッテリー用の電源プランの値（スリープ時間・蓋を閉じたときの動作・`CONSOLELOCK`）は変えない
- 休止状態の無効化と `DelayLockInterval` は電源接続中だけに限定されない（バッテリーのときもかかる）

### 実施手順 / PC 全体の設定 / 手順 8: 補足: デバイス マネージャーの「電力の節約のために、コンピューターでこのデバイスの電源をオフにできるようにする」

- この手順は、デバイス マネージャーのアダプターの「電源の管理」タブの、上の項目を外すのと同じ
- `Set-NetAdapterPowerManagement` の文書にこの項目の引数は無く、`Get-NetAdapterPowerManagement` で取ったものの `AllowComputerToTurnOffDevice` を変えて渡す形は、広く使われているもの（Microsoft の文書には無い）
- `Set-NetAdapterPowerManagement` は、`-NoRestart` が無いとアダプターを起動し直す（Microsoft の文書）。SSH・リモート デスクトップでつないでいると切れるので、付ける
- この項目を外すと、Windows がアダプターに「この PC を起こす」を任せる設定（眠りからの Wake on LAN）も使えなくなる（Microsoft の古いサポートの記事）。シャットダウンからの Wake on LAN は UEFI とアダプターが行い、Windows は関わらないので、[任意節](../windows-setup.md#wake-on-lan-を使う任意)はこの手順と両立する
- 元に戻すのは[ロールバックの「ネットワークと PC 全体の設定を戻す」](../extra/windows-setup.md#ネットワークと-pc-全体の設定を戻す)の手順 6

### 実施手順 / ネットワークとリモート / 手順 1: 補足: もとからプライベートのときと、前提にする手順

- 既にプライベートなら、何も変わらない
- [Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)・[Syncthing の Windows 11 で使う](../syncthing.md#windows-11-で使う)・「ネットワークとリモート」の手順 2〜4 は、この LAN がプライベートであることを前提にする

### 実施手順 / ネットワークとリモート / 手順 2: 補足: つなぐときのユーザーと、前提にする手順書

- つなぐのは、この PC にサインインするのと同じユーザーとパスワード（Microsoft アカウントなら、そのアカウントのパスワード。「サインイン・検索・キーボード」の手順 1 も）
- [RDP をロックせずに切断（Windows）](../windows-rdp-disconnect.md)は、この手順を前提にする

### 実施手順 / ネットワークとリモート / 手順 3: 補足: リモート アシスタンス

- リモート アシスタンス（Windows の「クイック アシスト」とは別）は、ほかの人を招いて画面を見せる古い仕組み。システムのプロパティの「リモート」タブの「このコンピューターへのリモート アシスタンス接続を許可する」が `fAllowToGetHelp`
- グループの ID `@FirewallAPI.dll,-33002` は、Microsoft の文書には無い（Windows の `racpldlg.dll` の文字列にある）。違っていたら、`Get-NetFirewallRule | Sort-Object Group -Unique | Format-Table DisplayGroup, Group` で「リモート アシスタンス」の行の `Group` を見る
- Microsoft の無人インストールの文書は、`fAllowToGetHelp` の既定を無効と書いているが、店頭の Windows では有効なことが多いと報告されている。「PC 全体の設定」の手順 3 の `RemoteAssistance` で、元の値を控える
- 元に戻すのは[ロールバックの「ネットワークと PC 全体の設定を戻す」](../extra/windows-setup.md#ネットワークと-pc-全体の設定を戻す)の手順 3

### 実施手順 / ネットワークとリモート / 手順 4: 補足: 自分で規則を作る理由

- Windows の既定では、ping（ICMPv4 の種類 8、ICMPv6 の種類 128）に応えない。組み込みの規則（「ファイルとプリンターの共有 (エコー要求 - ICMPv4 受信)」など）は無効で、「ファイルとプリンターの共有」の設定と一緒に変わる
- その規則を使わず、名前とグループ（`Ping (setup-notes)`）の決まった規則を作る。ほかの設定とぶつからず、消すときも分かる（[Syncthing の Windows 11 の節](../syncthing.md#windows-11-で使う)の規則と同じ形）
- 接続元は絞らない（`Any`）。プロファイルで決まるので、プライベートの LAN を通って届く、別のサブネット（WireGuard のクライアントなど）からの ping にも応える
- 元に戻すのは[ロールバックの「ネットワークと PC 全体の設定を戻す」](../extra/windows-setup.md#ネットワークと-pc-全体の設定を戻す)の手順 2
- 何度貼ってもよいのは、規則を消してから作り直すため

### 実施手順 / ネットワークとリモート / 手順 5: 補足: 配信の最適化

- 配信の最適化は、Windows Update とストアのアプリのファイルを、ほかの PC と分け合う仕組み。設定の「Windows Update」→「詳細オプション」→「配信の最適化」の「他のデバイスからのダウンロードを許可する」と同じ
- `Lan` は同じ NAT の後ろ（同じ LAN）の PC とだけ、`Internet` はインターネットの PC とも、`CdnOnly` は分け合わない。Microsoft の文書の既定は `Lan`（ポリシーの文書は 0 = HTTP だけと書いていて、文書の間で食い違う）
- `Set-DODownloadMode` は設定の画面と同じことをする（Microsoft の文書）。グループ ポリシーで決まっていると、そちらが優先される
- 元に戻すのは[ロールバックの「ネットワークと PC 全体の設定を戻す」](../extra/windows-setup.md#ネットワークと-pc-全体の設定を戻す)の手順 1
- Windows の既定も `Lan` なので、「PC 全体の設定」の手順 3 で `Lan` だったなら何も変わらない

### 実施手順 / サインイン・検索・キーボード / 手順 1: 補足: この設定と、リモート デスクトップ・SSH・自動サインイン

- 設定の「アカウント」→「サインイン オプション」の「セキュリティ向上のため、このデバイスでは Microsoft アカウント用に Windows Hello サインインのみを許可する」。値（2 がオン、0 がオフ）は Microsoft の文書に無く、広く使われているもの
- オンだと、Microsoft アカウントのパスワードでのリモート デスクトップに入れない、という Microsoft Q&A の回答がある
- オンだと、自動サインイン（「WSL の AlmaLinux 10 と自動サインイン」の手順 5）の設定に要る「ユーザーがこのコンピューターを使うには、ユーザー名とパスワードの入力が必要」の項目が隠れると報告されている
- 元に戻すのは[ロールバックの「サインイン・検索・キーボードを戻す」](../extra/windows-setup.md#サインイン検索キーボードを戻す)の手順 5

### 実施手順 / サインイン・検索・キーボード / 手順 2: 補足: 管理者の窓で書く理由と、効き目

- 自分のユーザーの設定（`HKCU`）だが、`HKCU\Software\Policies` の下は、管理者の権限が無いと書けない。管理者の窓も同じユーザーなので、自分の `HKCU` に書かれる
- Microsoft の文書では、このポリシーは「エクスプローラーの検索ボックスに最近の検索の項目を出さない」。スタートの検索から Web の結果が消えることは、広く報告されているもの（24H2 でも効くという報告と、効かないことがあるという報告がある）
- Windows 10 の `BingSearchEnabled` は、Windows 11 で効く根拠が見つからないので使わない
- 元に戻すのは[ロールバックの「サインイン・検索・キーボードを戻す」](../extra/windows-setup.md#サインイン検索キーボードを戻す)の手順 6

### 実施手順 / サインイン・検索・キーボード / 手順 4: 補足: Scancode Map の値

Microsoft の文書（Scan code mapper for keyboards）の書式で、4 バイトずつのリトルエンディアン:

| バイト | 値 | 意味 |
|---|---|---|
| 1〜4 | `00 00 00 00` | ヘッダ（版）。0 |
| 5〜8 | `00 00 00 00` | ヘッダ（フラグ）。0 |
| 9〜12 | `02 00 00 00` | 割り当ての数（終わりの印を含む）。2 |
| 13〜16 | `1D 00 3A 00` | `0x003A001D`: Caps Lock（スキャン コード `0x3A`）を押すと、左 Ctrl（`0x1D`）として扱う |
| 17〜20 | `00 00 00 00` | 終わりの印 |

- 割り当てるのは Caps Lock だけで、左 Ctrl はそのまま（入れ替えではない）。そのため Caps Lock の働きは無くなる
- 書く場所は `HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout`（`Keyboard Layouts` ではない）。PC 全体の設定なので、管理者の権限が要る
- 文書のとおり、効くのは再起動の後で、すべてのユーザーとすべてのキーボードにかかる。ユーザーごと・キーボードごとには分けられない
- スキャン コードはキーの位置で決まるので、US 配列（「サインイン・検索・キーボード」の手順 6）でも JIS 配列でも、Caps Lock の位置のキー（`0x3A`）が Ctrl になる
- 値を 16 進の文字列で比べるのは、もう同じ値があるか（2 回目）と、ほかの割り当てがあるかを分けるため
- `中断: 別の Scancode Map がある` で止めるのは、ほかのキーの割り当てを消さないため

### 実施手順 / サインイン・検索・キーボード / 手順 5: 補足: AlmaLinux のインストーラの時計

- AlmaLinux のインストーラは、Windows を見つけると `LOCAL` にする（[windows-dual-boot.md の注意点](../extra/windows-dual-boot.md#注意点)）

### 実施手順 / サインイン・検索・キーボード / 手順 6: 補足: キーボードの種類の値

- 日本語の Windows は、キーボードの種類（配列のドライバー）を PC 全体で 1 つ持つ。`HKLM\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters` の 4 つの値で決まり、名前は i8042prt（PS/2）だが、USB のキーボードにもかかる
- US 配列の値は、Microsoft の日本の社員のブログ（Learn に残っている「英語キーボードを快適に使う」）と同じ。設定の「時刻と言語」→「言語と地域」→「日本語」の「言語のオプション」→「キーボード レイアウト」の「英語キーボード (101/102 キー)」も、同じ値を書くと報告されている
- JIS 配列の値は、`kbd106.dll`・`PCAT_106KEY`・7・2（広く使われているもの）。「PC 全体の設定」の手順 3 の `Keyboard` で、元の値を控える
- 「サインイン・検索・キーボード」の手順 4 の Scancode Map は、キーの位置（スキャン コード）で変えるので、US 配列でも Caps Lock の位置のキーが Ctrl になる
- 元に戻すのは[ロールバックの「サインイン・検索・キーボードを戻す」](../extra/windows-setup.md#サインイン検索キーボードを戻す)の手順 9
- US 配列には半角/全角のキーが無いので、日本語の入力の切り替えは、「表示と入力」の手順 7 の Ctrl+Space で行う

### 実施手順 / WSL と再起動 / 手順 1: 補足: 入るもの

- Windows 11 では、`wsl --install --no-distribution` は Windows の機能「仮想マシン プラットフォーム」（`VirtualMachinePlatform`）を入れ、WSL のパッケージを入れる（WSL のソースの `WslInstall.cpp`）。WSL 1 の機能（`Microsoft-Windows-Subsystem-Linux`）は `--enable-wsl1` を付けたときだけ
- 機能を入れたときは、再起動が要る。この文書では「WSL と再起動」の手順 2 の再起動で済ませ、AlmaLinux 10 は「WSL の AlmaLinux 10 と自動サインイン」の手順 3 で入れる
- VirtualBox は、Hyper-V が動いていると、それを通して VM を動かす（NEM）。仮想マシン プラットフォームを外しても、メモリ整合性などで Hyper-V が動き続けることがある
- 元に戻すのは[ロールバックの「サインイン・検索・キーボードを戻す」](../extra/windows-setup.md#サインイン検索キーボードを戻す)の手順 8

### 実施手順 / 再起動の後に確かめる / 手順 2: 補足: Web の結果が出たとき

- スタートの検索に Web（Bing）の結果が出たら、[検証記録](../verification/windows-setup.md)と、「サインイン・検索・キーボード」の手順 2 の補足を見る

### 実施手順 / 再起動の後に確かめる / 手順 3: 補足: コマンドで外さない理由

- 自分のユーザーのピン留めを外す、サポートされたコマンドは無い。Microsoft の文書にある方法は、どれもポリシー（`ConfigureStartPins` やタスクバーのレイアウトの XML）か、新しいユーザーにだけかかるファイル
- タスクバーの設定（`Taskband`）やスタートのファイル（`start2.bin`）を消す方法は、Microsoft の説明が無く、形も決まっていないので採らない
- Copilot を外さないのは、利用者の選択

### 実施手順 / WSL の AlmaLinux 10 と自動サインイン / 手順 1: 補足: Windows Terminal の中に開く

- 「表示と入力」の手順 6 の後なので、Windows Terminal の中に開く

### 実施手順 / WSL の AlmaLinux 10 と自動サインイン / 手順 2: 補足: Hypervisor

- `Hypervisor : True` になるのは、「WSL と再起動」の手順 1 で WSL の機能を入れたため

### 実施手順 / WSL の AlmaLinux 10 と自動サインイン / 手順 4: 補足: 版と、冒頭の 2 行

- `VERSION="10.2 …"` の版は、入れた日のイメージ
- 冒頭の 2 行は、この PowerShell セッションで WSL の出力とコンソールの読み取りを UTF-8 にそろえる（「WSL の AlmaLinux 10 と自動サインイン」の手順 3 も同じ）

### Wake on LAN を使う（任意） / 手順 2: 補足: 式

- [実施手順の「PC 全体の設定」](../windows-setup.md#pc-全体の設定)の手順 2 の 2 つ目のブロックと同じ式

### Wake on LAN を使う（任意） / 手順 3: 補足: シャットダウンからの Wake on LAN

- Microsoft の文書では、Windows 10 以降の既定のシャットダウン（高速スタートアップ）では、Windows はアダプターに起動を任せない。シャットダウン（S5）からの起動は、UEFI とアダプターだけが行い、Windows は関わらない
- そのため、高速スタートアップを切り（「PC 全体の設定」の手順 7）、UEFI の Wake on LAN（機種によって「Power On By PCI-E」など）を有効にし、アダプターの詳細設定でマジック パケットを受けるようにする
- `*WakeOnMagicPacket` は、Microsoft の文書の標準の詳細設定の名前（1 で有効）。機種独自の項目（シャットダウンからの起動、リンクでの起動など）は、名前がアダプターごとに違う
- `-NoRestart` で、アダプターを起動し直さない（効くのは次の再起動から）
- 眠り（S3・Modern Standby）からの起動は、「PC 全体の設定」の手順 7 で眠らないようにしたので扱わない

### Wake on LAN を使う（任意） / 手順 4: 補足: 203 のエラー

- `入力された環境オプションが見つかりませんでした。(203)` が出て再起動しないときは、ファームウェアがこの指定に対応していないことがある

### ロールバック / アプリと貼り付けの設定を外す / 手順 4: 補足: 先に current の読み取り専用を外す理由

- scoop はアプリを入れるたびに、`~\scoop\apps\<アプリ>\current` を版のフォルダーへのジャンクションにし、読み取り専用の属性を付ける（`lib/install.ps1` の `link_current` の `attrib $currentdir +R /L`）
- scoop 0.6.0 の `scoop uninstall scoop`（`bin/uninstall.ps1`）は、アプリごとに `unlink_current (appdir $app $global)` を呼ぶ。`unlink_current` は渡されたフォルダーの親の `current` を探すので、`~\scoop\apps\current` を探して何もしない（ふつうの `scoop uninstall <アプリ>` は版のフォルダーを渡すので、読み取り専用を外してから消す）
- 残った読み取り専用のジャンクションは、続く `Remove-Item -Recurse -Force` で「アクセスが拒否されました」になる。`$errors = $true` は関数の中だけで立つので `Not all apps could be deleted.` は出ず、`~\scoop\apps` を消すところで `Couldn't remove` の `abort` で終わる。後ろの PATH の片付けまで進まないので、ユーザーの PATH の `scoop\shims` は残る
- `~\scoop\apps` の中は名前の順に消すので、消せないアプリが `scoop` より後ろ（`scoop-search` など）なら、scoop 本体は先に消えている。前（`7zip`・`git` など）なら、scoop 本体は残る
- 1 行目で `attrib.exe -R /L` を先に当てると、`Remove-Item` がジャンクションを消せて、最後まで進む（2026-10-08 に VM で確かめた。[検証記録](../verification/windows-setup.md)）

### ロールバック / アプリと貼り付けの設定を外す / 手順 6: 補足: 文字コードを変えずに消す

- ファイルをバイトのまま読み、消す行のほかのバイトは変えずに書き戻す
- 先頭が `FF FE`（UTF-16 LE の BOM）なら UTF-16 LE として、それ以外は 1 バイトを 1 文字にする Latin-1（コードページ 28591）として読み書きする。消す行は ASCII の文字だけなので、UTF-8（BOM の有無によらない）・Shift_JIS のどちらでも同じバイトで見つかる
- ファイルの 1 行目は BOM の直後にあるので、行の前の BOM を許して探し、BOM は残す
- 残りが BOM と空白だけなら、ファイルを消す
- `Get-Content` と `Set-Content` で書き直さないのは、Windows PowerShell 5.1 が BOM の無いファイルを ANSI（日本語の Windows では Shift_JIS）として読み、`Set-Content` が指定しないと ANSI で書くため。BOM の無い UTF-8 の日本語が化ける

### リモートから再起動する手段を増やす（任意） / 手順 3: 補足: クラッシュ時の自動再起動

- `HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl` の `AutoReboot` は、カーネルが止まった（ストップ エラー）ときに自動で再起動するかを決める。Windows の既定は 1（有効）で、この手順は確認が主
- `Win32_OSRecoveryConfiguration` の `AutoReboot` と同じ値。設定の「システムの詳細設定 → 起動と回復」の「自動的に再起動する」に当たる
- OS が応答するが操作できないとき（アプリのハング・ネットワーク断）には効かない。そちらはこの節の手順 6 の見張りタスクが担う

### リモートから再起動する手段を増やす（任意） / 手順 4: 補足: SMB のリモートシャットダウンの仕組み

- `shutdown /m \\<host>`（Windows）も `net rpc shutdown`（Samba）も、MS-RSP の InitShutdown インターフェイスを使う。これは名前付きパイプ `\PIPE\InitShutdown` を SMB（TCP 445）の上で呼ぶ（ncacn_np）。WindowsShutdown インターフェイスだけが TCP（ncacn_ip_tcp の動的ポート）で、`shutdown`・`net rpc` はそちらを使わないので、開けるのは 445 だけでよい
- 組み込みの受信規則「ファイルとプリンターの共有 (SMB 受信)」（`FPS-SMB-In-TCP`、TCP 445）を有効にする。既定では無効。ping の規則（「ネットワークとリモート」の手順 4）と同じく `-Profile Private` に絞る
- 再起動には 2 つの許可が要る
  - 「リモート システムからの強制シャットダウン」（`SeRemoteShutdownPrivilege`）。Administrators が既定で持つ。スタンドアロンのクライアントでは Administrators だけ
  - `LocalAccountTokenFilterPolicy = 1`。これが無いと、ローカル・Microsoft アカウントの管理者がネットワークログオンしたとき、UAC のリモート制限で絞られたトークンになり、再起動の権限を使えない（アクセス拒否になる）。1 にすると完全な管理者のトークンになる（UAC のリモート制限が緩む）
- ドメインに参加していない PC が対象なので、`-U '<user>%<pass>'` の資格情報はローカル・Microsoft アカウントのもの。Samba の `net` は `samba-common-tools` にある
- Windows の `shutdown /m` には資格情報を渡す引数が無く、送る側のユーザーの資格情報で相手につなぐ。検証では、相手に無いユーザーからと、Microsoft アカウントでサインインした PC から送ったときに、`アクセスが拒否されました。(5)` で止まった
  - 先に `net use \\<host>\IPC$ /user:<host>\<user>` で、相手の資格情報で `IPC$` につないでおくと、`shutdown /m \\<host>` はその接続を使う。名前（`<host>`）は 2 つのコマンドでそろえる
  - `net use` は、パスワードを聞く前に `…のパスワードまたはユーザー名が無効です。` を出す。聞かれたパスワードを入れるとつながる
  - 相手が再起動すると、送る側の接続は `Disconnected` で残るので、`net use \\<host>\IPC$ /delete` で消す

### リモートから再起動する手段を増やす（任意） / 手順 5: 補足: WinRM を選ぶ理由

- `Restart-Computer -ComputerName` は、既定で WMI/DCOM（RPC のエンドポイント マッパー 135 と動的ポート）を使う。開けるポートが多く、絞りにくい
- 代わりに WinRM（WS-Management、TCP 5985）を有効にして、`Invoke-Command -ComputerName … { Restart-Computer -Force }` で再起動する。開けるのは 5985 の 1 つだけ
- `Enable-PSRemoting` は、WinRM のサービスの開始・リスナーの作成・受信規則の有効化に加えて、`LocalAccountTokenFilterPolicy` を 1 にする（この節の手順 4 と共有）。`-SkipNetworkProfileCheck` は、ほかにパブリックの接続があっても止まらないようにする（LAN はプライベートにしてある）
- Windows 11（クライアント版）の「Windows リモート管理」のグループ（`@FirewallAPI.dll,-30267`）の受信規則は 2 つ。`WINRM-HTTP-In-TCP` はパブリック向けで接続元をローカル サブネットに絞り、`WINRM-HTTP-In-TCP-NoScope` はドメイン・プライベート向けで接続元を絞らない。`Enable-PSRemoting` は両方を有効にする
  - ほかに、別のグループの互換モードの規則（`WINRM-HTTP-Compat-In-TCP`・`WINRM-HTTP-Compat-In-TCP-NoScope`）があり、既定で無効。本書は触らない
  - 本書は、ローカル サブネットに絞った `WINRM-HTTP-In-TCP` をプライベートにし、`WINRM-HTTP-In-TCP-NoScope` を切る（LAN の外からは届かないようにする）
  - 2026-10-06 の版の手順は、`WINRM-HTTP-In-TCP` をドメイン・プライベート向け、`WINRM-HTTP-In-TCP-PUBLIC` をパブリック向けとして書いていたが、Windows 11 の VM には `-PUBLIC` の規則が無かった（[検証記録](../verification/windows-setup.md)）
- `WINRM-HTTP-In-TCP` が無効のままプライベートになっていると、`Enable-PSRemoting` は `エラー:1 つ以上の更新手順を終了できませんでした。`（`winrm quickconfig` では「WinRM ファイアウォールの例外を有効にします。」の後に「WinRM のファイアウォールを有効にできません。」）で止まった（[検証記録](../verification/windows-setup.md)）。パブリック向けの例外としてこの規則を探し、パブリックに見つからないためとみている（中の動きは資料・ソースで確かめていない）
  - 止まる前に、2 つの規則（`WINRM-HTTP-In-TCP` はプライベートのまま）を有効にしてしまう。このエラーは、複数行を貼ったときの後ろの行も止めるので、`-NoScope` を切る行が動かずに残る
  - 規則が有効でプライベートのとき（手順 5 を貼り直したとき）と、無効でパブリック（既定）のときは止まらない
  - そこで手順 5 の 1 行目で規則を既定のパブリックに戻し、この節の手順 9 でもパブリックに戻す（以前の版のこの節の手順 9 は、プライベートのまま残していた）
- 規則のグループは、表示名（`DisplayGroup`）が Windows の言語で変わる（日本語の Windows では「Windows リモート管理」）ので、言語に依らない `Group`（`@FirewallAPI.dll,-30267`）で選ぶ
- ドメインに参加していない PC から `Invoke-Command -ComputerName` で送ると、Kerberos を使えないので、送る側の WinRM のクライアントが、相手を `TrustedHosts` に入れるか HTTPS を使うことを求める（about_Remote_Troubleshooting）。本書は送る側で `TrustedHosts` に相手を足す
  - 送る側の WinRM のサービスが止まっていても、`Invoke-Command` は `TrustedHosts` の検査のエラー（`ServerNotTrusted`）までは進んだ。相手に届いて再起動できたのは、サービスを動かした後（止めたまま送れるかは確かめていない）。サービスが要るのは、`TrustedHosts` を読み書きする `WSMan:\localhost` のドライブ
  - `TrustedHosts` は `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Client` の `trusted_hosts` に入る。検証のホストでは初めは値が無く、`-Value ''` で戻すと空の値で残った
  - 検証のホスト（送る側）では、WinRM のサービスを動かしている間、TCP 5985 を System が待ち受けた（受信規則 `WINRM-HTTP-In-TCP`・`-NoScope` は無効のままだった）。戻すときにサービスも止める

### リモートから再起動する手段を増やす（任意） / 手順 6: 補足: 見張りタスクの作り

- ネットワークが切れても（OS は動いているが外から届かない）自分で再起動する。起動時と 5 分ごとに走るタスクで、`WATCHDOG_HOST`（既定はゲートウェイ）へ ping する
- SYSTEM・最上位の権限で動かす。SYSTEM は `SeShutdownPrivilege` を持つので、だれもサインインしていなくても再起動でき、ネットワークのサインインにも依らない
- 歯止め
  - 稼働 60 分未満なら何もしない。起動の直後に再起動を繰り返す（再起動ループ）のを避け、人が直す余地を残す
  - 連続して届かない回数を `HKLM:\SOFTWARE\setup-notes\net-watchdog` の `Fails` に記録し、6 回（約 30 分）でだけ再起動する。1 回でも届けば 0 に戻すので、一時的な切断では再起動しない
- 相手（ルーターなど）がずっと落ちていると、稼働 60 分ごとに再起動を繰り返す。`$limit` を増やすと猶予が延びる。相手は、LAN の中でいつも応答するものにする
- 起動時トリガーに 5 分ごとの繰り返しを足すため、`-Once` のトリガーの `Repetition` を起動時トリガーに移している（Windows PowerShell 5.1 の `New-ScheduledTaskTrigger` は、起動時トリガーに直接 `-RepetitionInterval` を取らない）
- 起動時トリガーなので、登録した時点では動かず（`NextRunTime` も空）、次の起動から起動時と 5 分ごとに動く

### リモートから再起動する手段を増やす（任意） / 手順 7: 補足: Remote Control を再起動後も使う

- [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)のタスクはトリガーが無く、手で `Start-ScheduledTask` したときだけ動く。再起動の後は戻らない
- ログオンのトリガー（`-AtLogOn -User <自分>`）を足すと、そのユーザーがサインインしたときに自動で始まる。自動サインイン（「WSL の AlmaLinux 10 と自動サインイン」の手順 5）と組み合わせると、無人の再起動の後も戻る
- タスクのトリガーだけを差し替える（`Set-ScheduledTask -Trigger`）。アクション・実行ユーザー・設定は変えない

### リモートから再起動する手段を増やす（任意）: 選択した方針

- **既にある接続（SSH・RDP・Remote Control）からの再起動を第一にし、それが使えないときの経路を足した**
  - SSH の sshd と RDP のサービスは再起動の後に自動で戻るので、再起動の引き金としても戻る口としても使える
- **別の PC からの再起動は、Linux からも使える SMB を主に、Windows 同士の WinRM を従にした**
  - SMB は AlmaLinux の `net rpc shutdown` でも Windows の `shutdown /m` でも使える。WinRM は Windows 同士で、開けるポートが 1 つで済む
- **電源・帯域外の手段（スマートプラグ + BIOS の通電時起動・IP-KVM・Intel AMT/vPro）は、この文書では扱わない**（利用者の選択）
  - 機器やマザーボードに依存し、設定が Windows の外になる。電源を切った後に起こすのは、既存の [Wake on LAN を使う（任意）](../windows-setup.md#wake-on-lan-を使う任意)が担う

### プライバシーと広告の表示を切る（任意） / 手順 2: 補足: 値と画面の対応

出典の「文書」は Microsoft の文書（Microsoft Learn・サポートの記事）、「広く」はコミュニティで広く使われている情報（privacy.sexy・Ten Forums・ElevenForum・Winaero など）。値は `HKCU` の DWORD。

| 値 | 書く値 | 設定の画面 | 出典 |
|---|---|---|---|
| `Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo` の `Enabled` | 0 | 「プライバシーとセキュリティ」→「全般」の広告 ID | 広く（Windows の移行マニフェストがユーザーごとの値として扱う。Microsoft Learn は `HKLM` の同じ名前の値を書く） |
| `Control Panel\International\User Profile` の `HttpAcceptLanguageOptOut` | 1 | 同じページの言語リスト | 文書（Manage connections の 18.1） |
| `Software\Microsoft\Windows\CurrentVersion\Privacy` の `TailoredExperiencesWithDiagnosticDataEnabled` | 0 | 「診断とフィードバック」の「カスタマイズされたエクスペリエンス」（新しいビルドでは「パーソナライズされたオファー」） | 広く（移行マニフェストに値がある） |
| `Software\Microsoft\Input\TIPC` の `Enabled` | 0 | 「診断とフィードバック」の「手書き入力と入力の改善」 | 広く |
| `Software\Microsoft\Siuf\Rules` の `NumberOfSIUFInPeriod`・`PeriodInNanoSeconds` | 0・0 | 「フィードバックの頻度」の「しない」 | 文書（18.16。「自動」は 2 つとも消す） |
| `Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy` の `HasAccepted` | 0 | 「音声認識」の「オンライン音声認識」 | 文書（18.6） |
| `Software\Microsoft\Windows\CurrentVersion\SearchSettings` の `IsMSACloudSearchEnabled`・`IsAADCloudSearchEnabled` | 0 | 「検索のアクセス許可」の「クラウドのコンテンツ検索」 | 広く |
| 同じキーの `IsDeviceSearchHistoryEnabled` | 0 | 「検索のアクセス許可」の「このデバイスの検索履歴」 | 広く（Ten Forums は 0 がオフ。privacy.sexy は逆に 1 を書く） |
| `Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced` の `ShowSyncProviderNotifications` | 0 | フォルダー オプションの「表示」の、同期プロバイダーの通知 | 広く |

- 既定では、`HttpAcceptLanguageOptOut`・`Siuf\Rules` の 2 つ・`HasAccepted`・`SearchSettings` の 3 つ・`ShowSyncProviderNotifications` は値が無い（広く）。`AdvertisingInfo\Enabled`・`TailoredExperiences…`・`TIPC\Enabled` は、OOBE の選び方で 1 か 0
- キーが無いときだけ `New-Item -Force` で作る。PowerShell 5.1 の `New-Item` の文書のとおり、既にあるレジストリのキーに `-Force` を付けると、値の無い空のキーで上書きされる
- 元の値を `%LOCALAPPDATA%\setup-notes\privacy-before.csv` に控えるのは、この節の手順 5 で、値が無かったものは消し、あったものはその数と型（DWORD か QWORD）に戻すため。初めて貼ったときだけ作るので、2 回目に貼っても元の値は失われない
- 「フィードバックの頻度」を「1 日 1 回」などにしていると、`PeriodInNanoSeconds` は 864000000000 などの 32 ビットに収まらない数になる（18.16）。型は QWORD のはず（推測。文書は REG_DWORD と書く）なので、型も控える
- 広告 ID を切っても、広告の数は減らない。オンに戻すと、ID は作り直される（サポートの記事）
- 画面の名前が変わった後のビルド（「全般」→「おすすめとオファー」、「カスタマイズされたエクスペリエンス」→「パーソナライズされたオファー」）でも同じ値を使うかは、資料では確かめられなかった。日本語の表記も、「おすすめとオファー」と「推奨事項 & オファー」で割れている

### プライバシーと広告の表示を切る（任意） / 手順 4: 補足: 画面で行うもの

- 「カスタム手書き入力と入力の辞書」: 画面で切ると、覚えた単語の一覧が消える（サポートの記事）。レジストリの値を書いても、既にある辞書は消えない（広く）
- 「オプションの診断データを送信する」: 画面が書く値は資料が無い。ポリシー（`AllowTelemetry`）は画面を灰色にするので使わない。Windows 10 1903 以降の既定は「必須」だけ（文書）。Rufus の「データ収集を無効化」で入れた PC は、既に切れている見込み（確かめていない）
- 「設定アプリで通知を表示する」: 値（`SystemSettings\AccountNotifications` の `EnableAccountNotifications`）の資料は ElevenForum などだけ（広く）。24H2・25H2 の画面にあるかも確かめていない。「表示と入力」の手順 3 の `Start_AccountNotifications`（スタートのアカウントの通知）とは別
- 「検索のハイライトを表示する」: 「サインイン・検索・キーボード」の手順 2 の `DisableSearchBoxSuggestions` で灰色になる（Microsoft Q&A の回答）。ポリシー（`EnableDynamicContentInWSB`）は管理者の窓が要り、同じく灰色にする
- この節の手順 2 の値が画面でオンのまま出たら、その画面でオフにすれば、画面が値を書き直す

### プライバシーと広告の表示を切る（任意）: 選択した方針

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| 広告 ID・カスタマイズされたエクスペリエンス | 自分のユーザーの値（`HKCU`） | ポリシー（`DisabledByGroupPolicy`・`DisableTailoredExperiencesWithDiagnosticData`）: 設定の画面が灰色になり、「組織によって管理」の表示が出る。広告 ID のポリシーは全ユーザーにかかる |
| 診断データ | 画面で確かめ、オプションがオンのときだけ切る | `AllowTelemetry` のポリシー: 画面を灰色にする。0（オフ）は Enterprise・Education・Server だけ |
| 辞書・設定アプリの通知 | 画面で切る | レジストリ: 辞書は既にある分が消えない。通知の値は資料が少ない |
| アクティビティの履歴 | 入れない | 送信は KB5034204（2024-01）で廃止され、履歴はこの PC にだけ残る。24H2 以降は画面が無いと広く報告されていて、止めるのは `HKLM` のポリシー（`PublishUserActivities` など）だけ |
| Recall | 入れない | Copilot+ PC だけの機能で、管理されていない PC では、利用者が同意するまでスナップショットを保存しない（文書） |
| アプリの起動の追跡（`Start_TrackProgs`） | 入れない | 文書（18.1）にある値だが、スタートの「よく使う」と、Win+R・アドレス バーのアプリの履歴も消えると広く言われる（2025 年の新しいスタートでの働きは確かめていない） |
| ロック画面のトリビアとヒント | 入れない | 背景が Windows スポットライトの間は切れない（チェックが出ない。広く）。スポットライトを止めるポリシーは Enterprise・Education だけ（文書） |
| モバイル デバイスの提案・共有のおすすめのアプリ・スタートの閲覧履歴のサイト・Edge のおすすめ | 入れない | 資料が少ないか、管理者のポリシーで Pro では効かないものがある |
| 位置情報 | 入れない | 文書にあるのは `HKLM` のポリシーだけで、「組織によって管理」の表示が出る |
| 値を戻す方法 | 元の値をファイルに控えて、そのとおりに戻す | 既定の値に戻す: Rufus で入れた PC などでは、元が 0 のことがある |

### 表示・入力・音・ストレージを変える（任意） / 表示・入力・音・ストレージを控えて変える / 手順 2: 補足: 控えのファイル

- `%LOCALAPPDATA%\setup-notes\display-before.csv` に、この節で変える値の、変える前の値を `Name`・`Value` の 2 列で書く。初めて貼ったときだけ作り、2 回目からは書き換えない（機能の更新の後に貼り直しても、元の値が残る）
- 控えを使うのは、「表示・入力・音・ストレージを元に戻す」の手順 2（切り替えのキー）・3（Alt+Tab とシェイク）・4（ギャラリーとホームのキーがあったか）・5（タスクの終了）。値が空なら、もとは値が無かった（戻すときは消す）
- 固定キーなどの `Flags`・`MinAnimate`・効果音のスキームは、確かめるために並べるだけ。戻すときは、`Flags` は今の値に 0x4 を立て（「表示・入力・音・ストレージを元に戻す」の手順 1）、アニメーションは決まった値（オンと `1`）に戻し（同じ項の手順 6）、効果音は「表示・入力・音・ストレージを控えて変える」の手順 9 の `.reg` の控えを使う
- 読者が値を控えて手で入れる形にしなかったのは、値が多く、打ち間違えやすいため
- `{e88865ea-…}`（ギャラリー）と `{f874310e-…}`（ホーム）は、自分のユーザーにキーが既にあったか（ふつうは `False`）

### 表示・入力・音・ストレージを変える（任意） / 表示・入力・音・ストレージを控えて変える / 手順 3: 補足: Flags のビット

- `HKCU\Control Panel\Accessibility` の `StickyKeys`・`Keyboard Response`・`ToggleKeys` の `Flags`（REG_SZ の 10 進の数）。0x4 のビット（`SKF_HOTKEYACTIVE`・`FKF_HOTKEYACTIVE`・`TKF_HOTKEYACTIVE`）が、ショートカットで機能をオンにできるかを決める（文書。`STICKYKEYS`・`FILTERKEYS`・`TOGGLEKEYS` の構造体）
- 既定の 510 と、ショートカットを切った 506 は、Microsoft の 2007 年の Windows XP Embedded のブログ（文書。Windows 11 の既定かは確かめていない。広くも 510 とする）。126 → 122 と 62 → 58 は広く
- 既定の値に頼らず、今の値から 0x4 だけを落とすので、ほかのビットは変えない
- 型は REG_SZ のままにする（DWORD で書く例があるが誤り）。値が無いか数でないときは書かない（0 を書くと、機能を使える印 0x2 まで落ちる）
- 戻すときは、値を消さずに `-bor 4` で 0x4 を立てる。値を消したときの動きは文書に無い
- レジストリに書いただけでは、今のサインインには効かない（サインインし直した後に読む）。その間に設定の画面で切り替えると、メモリの値で書き戻されうる（推測）
- 切り替えキー（Num Lock の長押し）の秒数は、構造体の文書は 8 秒、サポートの記事は 5 秒と書いていて食い違う
- 同じ値は、Microsoft の DSC のリソース（`microsoft/winget-dsc` の `Microsoft.Windows.Setting.Accessibility`）も読み書きする（コード）
- 切るのは、Shift を 5 回・右 Shift の長押し・Num Lock の長押しで機能をオンにするショートカットだけ。機能そのものはオフのまま

### 表示・入力・音・ストレージを変える（任意） / 表示・入力・音・ストレージを控えて変える / 手順 4: 補足: 切り替えのキーの値

- `HKCU\Keyboard Layout\Toggle` の 3 つの値（REG_SZ）。`1` が Alt+Shift、`2` が Ctrl+Shift、`3` が割り当てなし（文書。SystemParametersInfo の `SPI_SETLANGTOGGLE`）
- `Language Hotkey` が入力言語の切り替え、`Layout Hotkey` が同じ言語の中のキー配列の切り替え、`Hotkey` は古い名前で `Language Hotkey` と同じ値（ReactOS の input.cpl のコード。値の名前は Microsoft の文書に無い）
- 既定は広く `1`・`1`・`2` とされる（日本語版の値は確かめていない）。キーが無いユーザーもあるので、「表示・入力・音・ストレージを控えて変える」の手順 2 で控える
- 日本語の IME だけの PC では、ふだんは切り替える先が無い。タスクバーに「英語 (米国)」が勝手に出たときや、後で英語の配列を足したときに、Ctrl+Shift・Alt+Shift を押して離すだけで切り替わるのを防ぐ。WezTerm の自分用の設定は、Ctrl+Shift の組み合わせを多く使う
- Win+Space（入力言語とキー配列を順に切り替える）は、この値では消えない（サポートの記事）。誤って切り替わったときに戻す手段として残る
- 文書では、値を書いてから `SPI_SETLANGTOGGLE` を呼ぶと読み直す。この節では呼ばず、サインインし直して効かせる
- 半角/全角と、[実施手順の「表示と入力」](../windows-setup.md#表示と入力)の手順 7 の Ctrl+Space（IME のオン・オフ）には関係しない
- タスクバーに「英語 (米国)」のキーボードが勝手に出るのは、この設定では防げない（言語の一覧から消す）

### 表示・入力・音・ストレージを変える（任意） / 表示・入力・音・ストレージを控えて変える / 手順 5: 補足: Alt+Tab とシェイクの値

- `Explorer\Advanced` の `MultiTaskingAltTabFilter`: 0 がすべて（今は最新の 20 個）、1 が 5 個、2 が 3 個、3 が窓だけ（広く。Winaero・ElevenForum）。値が無いときの既定は、資料で 3 個と 5 個に割れる
- 同じことをするポリシー（`BrowserAltTabBlowout`）は文書にあるが、番号が 1 つずれ（4 が窓だけ）、preview の扱いで、Alt+Tab にだけ効く。ユーザーの値は、スナップの候補にも効く
- `DisallowShaking` が 1 でシェイクを切る。build 21286 から既定で切れている（Windows Insider のブログ）。1 がオフの意味は広く。日本語の画面の名前は「タイトル バー ウィンドウのシェイク」（広く）
- Alt+Tab とスナップの候補に、Edge のタブを出さず、窓だけを並べる（設定の「システム」→「マルチタスク」の「タブを表示しない」）

### 表示・入力・音・ストレージを変える（任意） / 表示・入力・音・ストレージを控えて変える / 手順 6: 補足: ギャラリーとホームを消す仕組み

- `System.IsPinnedToNameSpaceTree` が 0 だと、その名前空間の拡張を消さずに、ナビゲーション ウィンドウに既定では出さない。「すべてのフォルダーを表示」で出る（文書。Integrate a Cloud Storage Provider）
- `HKCR` は `HKLM\SOFTWARE\Classes` と `HKCU\Software\Classes` を合わせた見え方で、両方にあるキーは合わさり、`HKCU` の値が勝つ（文書。Merged View of HKEY_CLASSES_ROOT の例）
- ギャラリーの CLSID `{e88865ea-…}` とホームの `{f874310e-…}` は広く（winutil・WinSetView・winscript など）。「表示と入力」の手順 2 と同じく、Microsoft が説明していない使い方
- `HKCU\Software\Classes\CLSID` は WOW64 でリダイレクトされる（文書）ので、32 ビットの PowerShell から書くと別の場所に入る。32 ビットのアプリのファイルを開く画面には、残ることがある（推測）
- 2024 年 6 月の更新の後に効かなくなったという報告と、25H2 に上げた後にホームが戻ったという報告が 1 件ずつある（広く。確かめていない）
- 2 つを 1 つの手順にしたのは、同じ値・同じ仕組みで、確かめ方も同じため。「表示と入力」の手順 1 の `LaunchTo` = 1 で、エクスプローラーを開いたときも「PC」になる

### 表示・入力・音・ストレージを変える（任意） / 表示・入力・音・ストレージを控えて変える / 手順 7: 補足: タスクの終了

- `Explorer\Advanced\TaskbarDeveloperSettings` の `TaskbarEndTask` = 1。Microsoft の WindowsDeveloperConfig の設定スクリプトが、同じキーと値を書く（コード）
- 機能は KB5031455（2023-10、22621.2506・22631.2506）で足された（文書）。25H2 以降は「開発者向け」のページが「詳細設定」に変わった（文書。Windows の詳細設定）
- 開発者モード（「PC 全体の設定」の手順 6）は要らない
- 設定の画面では、24H2 は「システム」→「開発者向け」、25H2 以降は「システム」→「詳細設定」の「タスクの終了」

### 表示・入力・音・ストレージを変える（任意） / 表示・入力・音・ストレージを控えて変える / 手順 8: 補足: UserPreferencesMask ではなく SystemParametersInfo を使う理由

- 設定の「アニメーション効果」は、アプリには `SPI_GETCLIENTAREAANIMATION`（0x1042）として見える（MDN の `prefers-reduced-motion` の説明と、Chromium の `animation_win.cc`）。値は `HKCU\Control Panel\Desktop` の `UserPreferencesMask`（8 バイトの REG_BINARY）の 5 バイト目の 0x02 のビット（Wine の `sysparams.c`）
- `UserPreferencesMask` は、メニューのフェード・ClearType など多くのビットを 1 つの値に詰めている。丸ごと書く例（Microsoft Q&A の回答など）は、ほかのビットまで変える
- `SystemParametersInfo` に `SPIF_UPDATEINIFILE`（1）と `SPIF_SENDCHANGE`（2）を付けて書かせると、そのビットだけを変えてプロファイルに残し、開いている窓に知らせる（文書）
- 最小化・最大化のアニメーションは `SPI_SETANIMATION`（0x0049）の `ANIMATIONINFO` の `iMinAnimate` で、`HKCU\Control Panel\Desktop\WindowMetrics` の `MinAnimate`（REG_SZ、既定 `1`）に入る（文書）
- `Add-Type` で `user32.dll` の `SystemParametersInfo` をその場でコンパイルして呼ぶ。同じ定義なら、同じ窓で貼り直しても止まらない。制約付き言語モードの PC では使えない
- 設定の画面がほかに何を書くか（メニュー・コンボ ボックスのアニメーションのビットなど）は、文書に無い。この手順では変えない
- 切ると、Firefox・Chromium は Web ページに `prefers-reduced-motion: reduce` を返す
- 設定の「アクセシビリティ」→「視覚効果」の「アニメーション効果」に当たる（「表示・入力・音・ストレージを控えて変える」の手順 14 で確かめる）

### 表示・入力・音・ストレージを変える（任意） / 表示・入力・音・ストレージを控えて変える / 手順 9: 補足: 効果音の控えとスキーム

- サウンドの画面でスキームを選ぶと、`HKCU\AppEvents\Schemes` の既定の値にスキームの名前（「サウンドなし」は `.None`、「Windows 標準」は `.Default`）を書き、`Schemes\Apps\<アプリ>\<イベント>` ごとに、そのスキームの音を `.Current` に写す。`.None` には音が無いので、`.Current` を空にするのと同じ（古い Microsoft の文書・Scripting Guy の記事と、広く使われているスクリプト）
- 先に `reg.exe export` で `HKCU\AppEvents` を丸ごと控えるのは、イベントごとの元の音を、`.Default` が無いものやアプリが自分で書いたものも含めて戻すため。画面で「Windows 標準」に戻すと、`.Default` が無いイベントは空のまま残る
- 控えは初めて貼ったときだけ作る。2 回目に貼っても、「サウンドなし」にした後の状態で上書きしない
- 戻すときの `reg.exe import` は、控えにある値を書き戻す。控えの後に足されたイベントは、空のまま残る
- 設定の「システム」→「通知」の「通知で音を鳴らす」と、起動音（「表示・入力・音・ストレージを控えて変える」の手順 10）は別の設定

### 表示・入力・音・ストレージを変える（任意） / 表示・入力・音・ストレージを控えて変える / 手順 10: 補足: 起動音をレジストリで変えない理由

- 起動音はサインインの前に鳴るので、ユーザーごとではなく PC 全体の設定（`HKLM`）
- レジストリの値は、資料どうしで食い違う（`BootAnimation` の `DisableStartupSound` と `EditionOverrides` の `UserSetting_DisableStartupSound`。多くは 1 が鳴らさない側だが、Winaero は別の値を書く。どれも広く）。ポリシー（「Windows スタートアップのサウンドをオフにする」）は Policy CSP の一覧に無い
- そのため、サウンドの画面のチェックで行う。`control.exe mmsys.cpl,,2` は、サウンドの画面を「サウンド」のタブで開く（広く）。PowerShell ではカンマが配列の区切りになるので、引数を引用符で囲む
- 「PC 全体の設定」の手順 7 で休止状態を切った（高速スタートアップも無くなる）ので、起動のたびに鳴るはず（推測）

### 表示・入力・音・ストレージを変える（任意） / 表示・入力・音・ストレージを控えて変える / 手順 11: 補足: ストレージ センサーの値

`HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy` の DWORD:

| 値 | 書く値 | 意味 |
|---|---|---|
| `01` | 1 | ストレージ センサー（ユーザー コンテンツの自動クリーンアップ）をオン |
| `04` | 1 | 一時ファイルを消す |
| `08` | 1 | ごみ箱を消す（`256` と組） |
| `256` | 30 | ごみ箱に移してから消すまでの日数（0 が許可しない・1・14・30・60） |
| `32` | 0 | ダウンロード フォルダーを消さない（`512` と組） |
| `512` | 0 | ダウンロード フォルダーの日数（0 が許可しない） |
| `2048` | 30 | 実行のタイミング（0 が空きが少ないとき・1 が毎日・7 が毎週・30 が毎月） |

- 値の名前と意味は広く（stealthpuppy・cyberdrain のスクリプトなど）。Microsoft の文書にあるのは `01` だけ（Azure Virtual Desktop の文書。`HKLM` の同じ形のパス）。値が無いときの動き（オフで、空きが少ないとオンになることがある。一時ファイルは消し、ごみ箱は 30 日、ダウンロードは消さない）は、Policy CSP の Storage の文書
- `04` の向きは、stealthpuppy の表だけが逆に書いている（同じ記事のスクリプトは 1 で消す）
- 掃除の本体は `StorageSensor\Parameters\StorageSensorV2` を読み、`StoragePolicy` は画面の表示だけ、という Microsoft Q&A の回答（社員ではない）があるが、出典が無い。書いた値で掃除が動くかは確かめていない
- 動くのはシステムのドライブだけで、サインインしてオンラインの状態が 10 分以上続いたとき（サポートの記事）
- 22H2 以降の既定では、OneDrive のファイルは 30 日開かないとオンラインだけになる（サポートの記事）。OneDrive のアカウントごとの値（`StoragePolicy` の下の `OneDrive!…` のサブキー）は、名前がアカウントで変わり、資料も少ないので、画面で外す（「表示・入力・音・ストレージを控えて変える」の手順 12）
- キーが無いときだけ作る。既にあるキーを作り直すと、OneDrive のサブキーなども消える
- PC 全体のポリシー（`HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense` の `AllowStorageSenseGlobal`）があると、そちらが勝つ

### 表示・入力・音・ストレージを変える（任意） / 表示・入力・音・ストレージを元に戻す / 手順 4: 補足: 消すもの

- 「表示・入力・音・ストレージを控えて変える」の手順 2 で無かったキー（ふつう）はキーごと消し（`False`）、あったキーは値だけを消す（`True`）

### 表示・入力・音・ストレージを変える（任意）: 選択した方針

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| 透明効果 | 変えない | `EnableTransparency` を 0 にすると、WezTerm の自分用の設定のアクリルの背景（`win32_system_backdrop = "Acrylic"`）も単色になるはず（WinUI の文書が、透明効果を切るとアクリルが単色になると書く）。利用者はアクリルを使い続ける |
| Xbox Game Bar と録画 | 入れない | Win+G を止めるサポートされた値が無い。Game Bar のアプリを外すと、ゲームを開くたびに `ms-gamingoverlay` の窓が出たという報告がある（Microsoft Q&A の質問。広く）。バックグラウンドの録画は既定でオフ。録画を止めるポリシー（`AllowGameDVR`）の CSP の注は "The policy is only enforced in Windows 10 for desktop." で、Windows 11 で効くかは書いていない（確かめていない） |
| アニメーション効果 | `SystemParametersInfo` | `UserPreferencesMask` を丸ごと書く: ほかのビットも変わる |
| 起動音 | 画面のチェック | レジストリ: 資料どうしで値の意味が食い違う |
| 効果音 | `.Current` を空にし、スキームを `.None` にする（先に `.reg` で控える） | 画面だけ: 戻すときに、元の音を全部は戻せない |
| ギャラリーとホーム | 自分のユーザーの CLSID の上書き | PC 全体の `NameSpace` を消す: 管理者が要り、ほかのユーザーにもかかる |
| ストレージ センサー | 自分のユーザーの値（ダウンロードは消さない） | ポリシー（`AllowStorageSenseGlobal`）: 設定の画面が灰色になる |
| マウス キー・ハイ コントラスト・ナレーターのショートカット | 入れない | 3 つのキーを同時に押すので誤って押しにくく、値は広くだけ |

### Edge の常駐をポリシーで止める（任意） / 手順 2: 補足: 2 つのポリシー

- `StartupBoostEnabled`（Edge 88 から）と `BackgroundModeEnabled`（Edge 77 から）。どちらも REG_DWORD のブールで、必須にも推奨にもでき、Dynamic Policy Refresh が Yes（開き直さずに読み直せる）、Per Profile が No（文書。Microsoft Edge のポリシーの文書）
- スタートアップ ブーストは、サインインのときに Edge を裏で起動しておく。4 GB を超えるメモリ（または 1 GB を超え、新しいディスク）で、Edge を数日おきに使う PC では、Edge が自分でオンにする（サポートの記事）
- バックグラウンドの実行が残ると、スタートアップ ブーストの扱いと関係なく、窓を閉じても Edge が終わらないことがある（文書）。そのため 2 つを組で切る
- 「自動起動と標準アプリ」の手順 1 の `Run` の `MicrosoftEdgeAutoLaunch_<文字列>` は、Chromium のサインインのときの起動の仕組み（バックグラウンドの実行で使う）が書く（Chromium のコード）。ポリシーを置いた後に値が消えるかは確かめていない
- Edge Update の、サインインのときのコマンド（`on-logon-startup-boost`・`on-logon-autolaunch`）でも、Edge が起動することがある（広く）。文書に無いので変えない
- 必須のポリシー（`HKLM\SOFTWARE\Policies\Microsoft\Edge`）を置くと、Edge は組織が管理している旨を出し、その切り替えを灰色にする（表示の日本語の文言は広く）
- 「サインイン・検索・キーボード」の手順 3 の `RemoveDesktopShortcutDefault` は `HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate`（Edge Update が読む）で、別のキー
- `Edge` のキーが無いときだけ作る（既にあるキーを `New-Item -Force` で作り直すと、ほかの Edge のポリシーが消える）。戻すときも、キーは消さずに 2 つの値だけを消す
- ドメイン参加か MDM の登録が要るポリシーには、その旨の注記がある。2 つのポリシーの文書には無いので、家庭の PC でも効くはず（確かめていない）

### Edge の常駐をポリシーで止める（任意）: 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **`HKLM` の必須のポリシー** | 「サインイン・検索・キーボード」の手順 3 と同じ `HKLM`。効き目がはっきりし、`edge://policy` で確かめられる。管理の表示が出て、切り替えが灰色になる | **採用** |
| 推奨のポリシー（`Edge\Recommended`） | 利用者が一度でも切り替えていると効かない（文書）。管理の表示が出るかは資料が無い | 不採用 |
| `HKCU` のポリシー | 書くのに管理者が要るのは同じ。両方あると `HKLM` が勝つ（Chromium の文書） | 不採用 |
| Edge の設定の画面 | 管理の表示は出ない。Edge が自分でオンに戻すことがあるかは、資料が無い | 代わりの手順（この節の手順 3） |
| 旧 Edge の `AllowPrelaunch` など | EdgeHTML の Edge のポリシーで、今の Edge には効かない | 不採用 |

### CopyQ を使う（任意） / 手順 2: 補足: 入れ方と入る場所

- winget の `hluk.CopyQ`（2026-10-08 の定義は 16.0.0。上流の最新は 17.0.0）は Inno Setup のインストーラ。`--scope user` は `/CURRENTUSER` を渡し、`%LOCALAPPDATA%\Programs\CopyQ` に入る
- `/CURRENTUSER` は winget の定義。入る場所は、`copyq.iss` の `{autopf}\CopyQ` を、Inno Setup が自分のユーザーの導入で `%LOCALAPPDATA%\Programs` にするため
- インストーラは `PrivilegesRequiredOverridesAllowed=dialog` なので、管理者の確認を出さずに自分のユーザーに入れられる（`shared/copyq.iss` と Inno Setup の文書）。winget の定義は `elevatesSelf` で、winget は UAC が出るかもしれない旨を出すだけで、自分では昇格しない（winget の文書）
- デスクトップのショートカットとスタートアップのタスクは既定で外れていて、入れた後の起動は `postinstall skipifsilent` なので、黙って入れると起動しない。PATH には入らない
- 自分のユーザーにしたのは、「アプリを入れる」の手順 3・4 の UniGet UI・PowerToys と同じく、管理者が要らず、ほかのユーザーにかからないため。更新も、管理者ではない窓の `## 更新` の winget で上がる
- 17.0.0 は、データを `%LOCALAPPDATA%\copyq` に移し、前の版では読めなくなる（`CHANGES.md`）
- 前に別の場所へ入れた CopyQ があると、インストーラはその場所に入れる（`UsePreviousAppDir`）。そのときは、この節の手順 3・4・7 の決め打ちのパスが外れる
- 最後の表の版は、実行した日の最新

### CopyQ を使う（任意） / 手順 4: 補足: 自動の起動の仕組み

- `copyq config autostart true` は、スタートアップ フォルダー（`CSIDL_STARTUP`）に `copyq.lnk` を作る（`winplatform.cpp`）。「自動起動と標準アプリ」の手順 1 の `Run` とは別の所なので、同じ項の手順 1 の一覧には出ない
- CLI の `config` は、値が変わったときだけショートカットを作る（`ConfigurationManager::setOptionValue`）。`copyq.ini` に `autostart=true` が残っていて `copyq.lnk` が無いと、`true` を送っても作られない。先に `false` を送るのはそのため
- アンインストーラは `copyq.lnk` を消さない（スタートアップのタスクを選んだときだけ、アンインストールの記録に入る）
- `copyq.exe` は窓を持つアプリ（GUI のサブシステム）なので、PowerShell は結果を出さずに戻る。`| Write-Output` を付けると、終わるまで待って結果を出す（CopyQ の known-issues）。`| Out-Null` は、終わるまで待って結果を捨てる
- 起動を別の手順（この節の手順 3）にしたのは、`--start-server` に `| Write-Output` を付けると、裏で動き続けるサーバーが標準出力のパイプを持ち続け、窓が戻らないおそれがあるため（Qt の `startDetached` のコード。確かめていない）。クライアントがサーバーを待つのは、既定で 1 秒だけ
- `EnableClipboardHistory`（`HKCU\Software\Microsoft\Clipboard`）の名前は広く。Windows の履歴が既定でオフなのは文書（サポートの記事）

### CopyQ を使う（任意） / 手順 6: 補足: 避けるキーと貼り付け

- CopyQ のグローバル ショートカットは `RegisterHotKey` を使う。Windows キーを含むキーは OS が予約していて、ほかが登録済みのキーと同じく失敗することがある（文書）。失敗はサーバーの記録に出るだけで、画面には出ない（コード）
- 「アプリを入れる」の手順 4 の PowerToys の高度な貼り付けは、既定で Win+Shift+V と Ctrl+Win+Alt+V を使う（文書）。Ctrl+Shift+V は、Windows 11 の書式なしの貼り付けのキー（サポートの記事）
- CopyQ は Ctrl+V などのキーを `SendInput` で送って貼る。`SendInput` は、同じか低い整合性のレベルの窓にしか届かないので、管理者の窓には貼れない（文書。UIPI）
- CopyQ の窓は、既定でスクリーンショット・画面の録画と共有に写らない（12.0.0 から。`prevent_screen_capture`）。RDP で窓が見えない不具合は 16.0.0 で直った（`CHANGES.md`）
- パスワード マネージャーなどが付ける除外の印（`ExcludeClipboardContentFromMonitorProcessing`・`CanIncludeInClipboardHistory` など）があるものは、記録しない（コード）
- 履歴は暗号化しないで保存する（`encrypt_tabs` の既定は false。項目は既定で 200 まで）。16.0.0 は `%APPDATA%\copyq`、17.0.0 からは `%LOCALAPPDATA%\copyq` の下
- 画面の日本語は、同梱の訳（約 94%）が、Windows の地域の形式に合わせて出る（推測）

### CopyQ を使う（任意）: 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `hluk.CopyQ` を `--scope user` で** | 管理者が要らず、UniGet UI・PowerToys と同じ形。`## 更新` の winget の一覧で上がる | **採用** |
| winget の `--scope machine` | `%ProgramFiles%\CopyQ` に入り、管理者の確認が要る | 不採用 |
| scoop の `extras/copyq` | extras のバケットは git が要り（この文書の時点では Git for Windows が無い）、動いている間は更新を飛ばし、シムが GUI の終了を待つ | 不採用 |
| Windows のクリップボードの履歴（Win+V） | 標準で入っている | 不採用（利用者の選択） |
| Win+V を CopyQ に割り当てる | OS が予約しているキー | 不採用 |
| インストーラの `/MERGETASKS=startup` | 起動のショートカットは作れるが、CopyQ の設定（`autostart`）とずれる | 不採用 |
| ポリシー `AllowClipboardHistory` で Windows の履歴を禁止する | 設定の画面が灰色になる。既定でオフなので要らない | 不採用 |

### PowerToys のユーティリティを絞る（任意） / 手順 2: 補足: 入る場所と、切るユーティリティの案

- 入る場所は、Microsoft の情報どうしで食い違う（[「アプリを入れる」の手順 4 の補足](#実施手順--アプリを入れる--手順-4-補足-入れ方と入る場所)）。決め打ちせず、動いている PowerToys のプロセスの場所を取り、無ければ `%LOCALAPPDATA%\PowerToys` と `%LOCALAPPDATA%\Programs\PowerToys` のうち、あるものにする
- 設定ファイルの `enabled` の名前は、設定の画面のコード（`EnabledModules.cs`）の JSON の名前。`Measure Tool`・`File Locksmith`・`Image Resizer` などは空白を含む。DSC の文書の App の例の名前（`MeasureTool`・`PowerOCR` など）とは違う
- 既定で有効なもの（main のソース）: FancyZones・Image Resizer・File Explorer Preview・PowerRename・ColorPicker・Awake・FindMyMouse・MouseHighlighter・AlwaysOnTop・Measure Tool・File Locksmith・Peek・CmdNotFound・CmdPal。ほかは既定で無効。0.101.2362.0 で同じかは、この節の手順 3 の表で確かめる
- `$PT_OFF` の案（利用者の好みで変えてよい）
  - FindMyMouse: 既定は左 Ctrl を 2 回で出る。「サインイン・検索・キーボード」の手順 4 で Caps Lock を左 Ctrl にしたので、Caps Lock を 2 回押しても出る
  - MouseHighlighter（Win+Shift+H）・ColorPicker（Win+Shift+C）・Measure Tool: 使わないなら、Win のキーの割り当てを空ける
  - FancyZones: Windows のスナップで足りるなら要らない
  - Awake: 「PC 全体の設定」の手順 7 で、電源接続中は眠らないようにした。既定のモードは何もしない
- 残す案: Always On Top（Win+Ctrl+T）・コマンド パレット（Win+Alt+Space）・PowerRename・File Locksmith・Peek・エクスプローラーのプレビュー・Image Resizer。Text Extractor（Win+Shift+T。画面の文字を読み取ってコピーする）は既定で無効で、使うなら画面でオンにする
- LightSwitch（既定で無効）は、時刻で明暗を切り替えるので、「表示と入力」の手順 5 のダークモードとぶつかる。オンにしない
- WezTerm の自分用の設定は Win のキーを使わないので、PowerToys の Win+ のショートカットとはぶつからない

### PowerToys のユーティリティを絞る（任意） / 手順 5: 補足: 設定ファイルを書く順と、変えない設定

- PowerToys のランナー（`PowerToys.exe`）は、起動のときに `%LOCALAPPDATA%\Microsoft\PowerToys\settings.json` を読んで当てはめ、ファイルを見張らない（`src/runner/main.cpp`）。そのため、終了してから書き、起動し直す。ランナーは、`enabled` のうち自分の一覧にある名前だけを使い、無い名前は黙って飛ばす（`general_settings.cpp`）ので、この節の手順 3・5 で名前を確かめる
- 設定ファイルを直接書く方法は、Microsoft の文書には無い
- Windows PowerShell 5.1 の `ConvertTo-Json` は、`-Depth` の既定が 2 で、深い入れ子が文字列に潰れるので、`-Depth 100` を付ける。`Set-Content` は ANSI か BOM 付きで書くので、`[IO.File]::WriteAllText` で BOM の無い UTF-8 にする
- 控えは、控えが無いときだけ作る（2 回目に貼っても、元の設定が残る）。この節の手順 8 で書き戻すと消すので、次にこの節を通すときは、そのときの設定を控え直す（前の控えで、その間に変えた設定を戻さない）
- `enabled` は、今ある名前のプロパティの値を書き換える。`Add-Member -Force` で足し直すと、名前が `$PT_OFF` の綴りになり、大文字と小文字が違うと、ランナーが読まないおそれがある
- 「起動時に実行」（`startup`）は、ランナーがタスク スケジューラの `\PowerToys\Autorun for <ユーザー>` を作る。キーが無ければ作る（既定で有効）
- 「常に管理者として実行」（`run_elevated`）をオンにすると、そのタスクが最上位の特権で動く。Microsoft の文書は、管理者の窓で要るときだけ「管理者として再起動」するよう勧める。管理者の窓で効かないのは、Always On Top・FancyZones・File Locksmith（昇格したプロセスを止める）など
- 自動の更新の取得（`download_updates_automatically`）は、Administrators の一員なら既定で有効。winget と UniGet UI でも上がるが、二重でも壊れないので変えない
- 書くのは `enabled` の値だけで、ほかの設定は変えない

### PowerToys のユーティリティを絞る（任意） / 手順 6: 補足: Peek・Find My Mouse・Command Not Found

- Peek の起動のキーの既定は Ctrl+Space だが、「Space で開く」（`EnableSpaceToActivate`）が既定でオンの間は Space だけになる（0.95 から。`PeekProperties.cs`・`dllmain.cpp`）。オフにすると Ctrl+Space に戻り、「表示と入力」の手順 7 の IME とぶつかる。0.95 より前の設定を引き継いだ PC も同じ
- Find My Mouse の起動の方法は、設定ファイル（`FindMyMouse\settings.json`）の `activation_method`（0 が左 Ctrl を 2 回、1 が右 Ctrl を 2 回、2 が振る、3 がショートカット）と `include_win_key`（Windows キーを押しているときだけ。0 と 1 のときだけ画面に出る）。この節では画面で変える
- Command Not Found は、有効の印があっても、画面で「インストール」を押すまで何もしない。押すと、PowerShell 7 のプロファイルに行を足す（Microsoft の文書）
- 通知領域のアイコンを 1 回クリックすると、クイック アクセス（`enable_quick_access` が既定で true）が開く。設定の窓は、右クリックのメニューの「設定」か、ダブルクリックで開く（`src/runner/tray_icon.cpp`）
- 画面の日本語の文言（「終了」「設定」「ダッシュボード」「Space で開く」「マウスを振る」など）は、英語の文言から書き、確かめていない

### PowerToys のユーティリティを絞る（任意）: 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **設定ファイル（`settings.json` の `enabled`）を、終了してから書く** | 管理者が要らず、控えから戻せる。書き方は Microsoft の文書に無い | **採用** |
| 設定の画面のスイッチ | すぐに効く。台数が少なければ足りる | この節の手順 6 で確かめに使う |
| `PowerToys.DSC.exe`（DSC v3。0.95 から同梱） | Windows PowerShell 5.1 から JSON の文字列を渡すと、中の `"` が落ちる（`$PSNativeCommandArgumentPassing` は 7.3 から）。動いている PowerToys に伝わるかは確かめていない | 不採用 |
| `winget configure`（PSDSC の `Microsoft.PowerToys.Configure` か dscv3） | PowerShell 7.2 以上と PowerShell Gallery のモジュールが要る | 不採用（1 台の個人の設定には大げさ） |
| Keyboard Manager で Caps Lock を変える | 「サインイン・検索・キーボード」の手順 4 の Scancode Map を採った（[選択した方針](../verification/windows-setup.md#選択した方針)） | 不採用 |
| 「常に管理者として実行」 | 管理者の窓でも効く機能が増えるが、自動の起動のタスクが最上位の特権で動く | 不採用（要るときだけ「管理者として再起動」） |

### PowerShell 7 のプロファイルを設定する（任意） / 手順 2: 補足: 足す行

- プロファイルは PowerShell 7 の `$PROFILE`（CurrentUserCurrentHost）で、ドキュメントの既知のフォルダーの下の `PowerShell\Microsoft.PowerShell_profile.ps1`（`CorePsPlatform.cs`・about_Profiles）。5.1 から書くので、`[Environment]::GetFolderPath('MyDocuments')` で求める。PowerShell はプロファイルを自分では作らない。MSIX の PowerShell 7 は、全ユーザーのプロファイル（`$PSHOME`）を使えない
- Ctrl+Enter: PowerShell 7.5 の PSReadLine 2.3.6 と、7.6 の 2.4.5 も、Windows モードの Ctrl+Enter は `InsertLineAbove`（`KeyBindings.cs`）
  - スタートメニューから管理者として開いた PowerShell 7 は conhost の窓になり（「表示と入力」の手順 6 の補足）、右クリックで貼ると 5.1 と同じく行が逆順になるはず
  - Windows Terminal は、貼るときに LF を CR に直す（`ControlCore::PasteText`）ので起きない。WezTerm（Windows では、貼るときに改行を CRLF に直す）は確かめていない
- ↑/↓: `HistorySearchBackward`・`HistorySearchForward`（既定は F8・Shift+F8 に割り当て）。bash-settings.md の `~/.inputrc` の `history-search-backward` と同じく、打った文字で始まる履歴だけを出す
  - `-HistorySearchCursorMovesToEnd` は付けない（既定の False で、カーソルは打った文字の後ろに残る。bash と同じ）。Microsoft の `SamplePSReadLineProfile.ps1` は付けている
  - 予測の一覧（ListView）が出ているときは、候補を選ぶ。複数行の入力の中では、ほかの行へ移る
  - 履歴のファイル（`%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`）は 5.1 と共有する
- 各行を `if (Get-Module -Name PSReadLine) { … }` で囲むのは、`pwsh -Command`・`-File` では PSReadLine が読み込まれず（`ConsoleHost.cs` の `LoadPSReadline`）、囲まないと `Set-PSReadLineKeyHandler` が PSReadLine を自動で読み込むため。`-NoExit` 付きの起動（WezTerm の起動メニューの PowerShell 7）では読み込まれる
- 行は ASCII の文字だけにする。5.1 の `Add-Content` は新しいファイルを ANSI で書き、PowerShell 7 は BOM の無いファイルを UTF-8 として読むので、日本語を書くと化ける
- 予測（Predictive IntelliSense）は書かない。PSReadLine 2.2.6 から既定で有効で、PowerShell 7 では `HistoryAndPlugin`・`InlineView`（`Cmdlets.cs`。about_PSReadLine の「既定で無効」は古い記述）。F2 で一覧（ListView）に切り替わる。予測のプラグインを入れていなければ、候補は履歴だけ
- EditMode は Windows（既定）のまま。`-EditMode Emacs` は、`Set-PSReadLineKeyHandler` で付けたキーを既定に戻し、Emacs モードには Ctrl+Enter も Ctrl+V の `Paste` も無い
- プロファイルが無ければ作る。同じ行は足さない。プロファイルにほかの行があれば、そのまま残る

### PowerShell 7 のプロファイルを設定する（任意） / 手順 2: 補足: zoxide と starship の順

- zoxide の初期化は、その時点の `prompt` を `$__zoxide_prompt_old` に入れて包み、プロンプトのたびに `__zoxide_hook` を呼ぶ。既定の `--hook pwd` では、ディレクトリが変わったときだけ `zoxide add` する（zoxide の `templates/powershell.txt`。0.9.9 と 0.10.0 で同じ）
- starship の初期化は `prompt` を定義し直すので、zoxide の後に読むと zoxide の包みを捨てる。starship の `prompt` は、最初に `$?` を控えた後に、`Invoke-Starship-PreCommand` があれば呼ぶ（starship 1.26.0 の `starship.ps1`）。この節の行は、そこで `__zoxide_hook` を呼ぶ
- 両方の README の形（starship → zoxide）では、zoxide の包みが starship の `prompt` を呼ぶ前に `if` を評価して `$?` を真に戻し、失敗したコマンドの後もプロンプトが成功の印になるおそれがある（コードからの推測。確かめていない）。WezTerm の自分用の設定の `shell/wezterm.ps1` は、元の `prompt` を呼ぶ直前に `$?` を戻している
- 初期化の行は、ツールが無ければ（`Get-Command -CommandType Application`）読まない。scoop の zoxide は shim、starship は `PATH` に足したフォルダーから見つかる
- `Invoke-Starship-PreCommand` はプロンプトのたびに呼ばれるので、`__zoxide_hook` があるかは `Test-Path -Path Function:\__zoxide_hook` で見る（starship の `starship.ps1` も `Test-Path` の形）
  - `Get-Command` は、無い名前のときに `PATH` とモジュールを探すので、zoxide を入れていない PC で、プロンプトのたびに遅くなる
- zoxide と starship の行を、それぞれの手順書から 1 行ずつ足す形にしないのは、通す順で行の順が変わるため（bash の共通設定が順を管理するのと同じ考え）

### PowerShell 7 のプロファイルを設定する（任意） / 手順 3: 補足: Tab の一覧

- 既定の Tab は、候補を 1 つずつ入れ替える
- 一覧を出す既定のキーの Ctrl+Space は、[実施手順の「表示と入力」](../windows-setup.md#表示と入力)の手順 7 で IME が受け取るので、Tab がその代わりになる

### PowerShell 7 のプロファイルを設定する（任意） / 手順 4: 補足: 5.1 から確かめる形と実行ポリシー

- 5.1 から `pwsh.exe -Command { … }` にスクリプト ブロックを渡すと、5.1 が `-EncodedCommand` に変えて渡し、結果をオブジェクトで受け取る（5.1 の `NativeCommandProcessor.cs` の minishell）。Windows では確かめていない
- 結果は、子の pwsh で `Out-String` にして文字列で受け取る。オブジェクトのまま受け取ると、5.1 は最初に届いた実行ポリシーの列で表を作るので、キーの行が空になる
  - `-Width 120` を付けるのは、子が端末の幅を取れないと、`Out-String` が空の行だけを返すため
- `-NoProfile` でも `$PROFILE` は設定される（`ConsoleHost.cs`）ので、`. $PROFILE` で読む
- Windows 版の PowerShell 7 は、`$PSHOME\powershell.config.json` に `RemoteSigned` を持って配られ、これが `LocalMachine` の値になる（`build.psm1`。MSIX の `$PSHOME` にもあるかは推測）。「貼り付けの設定」の手順 3 の 5.1 の値（レジストリ）は効かない
- すべてが `Undefined` なら `Restricted` になり、プロファイルが読まれない。そのときだけ、この節の手順 5 で `CurrentUser` を `RemoteSigned` にする（`Documents\PowerShell\powershell.config.json` に書かれる）。MSIX では `LocalMachine` に書けない
- `Set-ExecutionPolicy` に `-Force` を付けるのは、確認の問いで止まらないようにするため
- UniGet UI は scoop を `-NoProfile -ExecutionPolicy Bypass` で動かすので、このプロファイルと実行ポリシーに依らない

### PowerShell 7 のプロファイルを設定する（任意） / 手順 7: 補足: 印の行だけを消す

- [ロールバックの「アプリと貼り付けの設定を外す」](../extra/windows-setup.md#アプリと貼り付けの設定を外す)の手順 6 と同じく、ファイルをバイトのまま読み、消す行のほかのバイトを変えずに書き戻す（[ロールバックの「アプリと貼り付けの設定を外す」の手順 6 の補足](#ロールバック--アプリと貼り付けの設定を外す--手順-6-補足-文字コードを変えずに消す)）
- 消すのは、行末が `  # windows-setup.md` の行。印が行の途中にある行は消さない
- PowerToys の Command Not Found が足した行は、印が無いので残る
- `Documents\PowerShell` のフォルダーは消さない（モジュールや `powershell.config.json` が入ることがある）

### PowerShell 7 のプロファイルを設定する（任意）: 選択した方針

- **Windows で CLI ツールを組み込むシェルは、Git Bash を主にする**
  - WezTerm の自分用の設定の Windows の `default_prog` は Git Bash（`C:/Program Files/Git/bin/bash.exe -i -l`。`lua/shells.lua`）。PowerShell 7・Windows PowerShell・WSL は、起動メニュー（Ctrl+Shift+M）から開く
  - 共通の bash 設定（README の「共通の bash 設定を先に入れる」）が、fzf・starship・zoxide・eza・bat・fd を `command -v` で見つけたときだけ読むので、Git Bash では、各ツールを入れるだけで効く。`~/.bashrc` には書かない
  - Claude Code の Bash ツールと、sshd の `DefaultShell`（[Windows の OpenSSH サーバー](../windows-setup.md#ssh-の既定のシェルを-git-bash-にする任意)の任意節）も Git Bash なので、bash の設定 1 つで済む
- **PowerShell 7 は補助**: この節で、starship と zoxide だけを、入っているときだけ読む。PSFzf・eza の関数・gh の補完・yazi の `y` は入れない（主のシェルの Git Bash に同じ機能がある。PSFzf はコミュニティのモジュール）
- **Windows PowerShell 5.1 には何も足さない**: 手順書を貼る窓で、プロファイルは管理者の conhost の窓も読む。見た目と起動の時間が変わり、SSH のセッションでは scoop の shim が RedirectionGuard で起動できないことがある。5.1 のプロファイルは「貼り付けの設定」の手順 4 の 1 行のまま
- **WSL の AlmaLinux 10 は Linux のホストとして扱う**: 各手順書の AlmaLinux 10 の実施手順と共通の bash 設定を、WSL の中で通す
- **Windows Terminal の既定のプロファイルは Windows PowerShell のまま**: PowerShell 7（`{574e775e-4f2a-5b96-ac1e-a2962a402336}`）にすると、Win+X の「ターミナル」などで開く窓が PowerShell 7 になり、5.1 でだけ動く手順（Windows の OpenSSH サーバーの `Add-WindowsCapability` など）を貼り違えやすい。PowerShell 7 は実行ポリシーとプロファイルも別に持つ。「Microsoft Store の更新」の手順 1 の窓で Windows Terminal が先に設定を作るので、「アプリを入れる」の手順 5 の後も既定は Windows PowerShell のままのはず（コードからの推測）

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| Tab の補完 | 条件付きの手順（この節の手順 3） | 既定で入れる: 好みが分かれる。bash に近い動き（共通する部分まで補完し、もう 1 回で一覧）が好みなら、`MenuComplete` の代わりに `Complete` |
| 予測 | 既定のまま（F2 で一覧に切り替え） | プロファイルに `-PredictionViewStyle ListView`: 既定で候補が出るので要らない |
| EditMode | Windows（既定） | Emacs: 足したキーが消え、Ctrl+V の貼り付けも無くなる |
| 履歴の件数 | 既定（4096） | `-MaximumHistoryCount 100000`（bash の `HISTSIZE` に合わせる）: 窓を開くたびに読む量が増える |
| 起動の更新の通知・テレメトリ | 変えない | `POWERSHELL_UPDATECHECK`・`POWERSHELL_TELEMETRY_OPTOUT`: プロファイルではなく環境変数。更新の通知はバナーを出す起動だけで、WezTerm の `-NoLogo` の起動には出ない |

### Windows Terminal のフォントと貼り付けの警告を変える（任意） / 手順 2: 補足: 設定ファイルの読み書き

- 場所は、Store（MSIX）版の `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`（Microsoft の文書）
- Windows Terminal は、初めて起動したときにコメントの無い `settings.json` を書く。設定の画面でリセットすると、コメント入りの `userDefaults.json` をそのまま書く（`CascadiaSettingsSerialization.cpp`）。5.1 の `ConvertFrom-Json` はコメントを読めないので、文字列を除いた残りにコメントか末尾のカンマがあれば、書かずに止める
- Windows Terminal は BOM の無い UTF-8 で書き、ASCII 以外の文字（訳したプロファイルの名前）も入る。5.1 の `Get-Content` は BOM の無いファイルを ANSI として読むので、`[IO.File]::ReadAllText` で読む
- `ConvertTo-Json` は `-Depth 100`（既定の 2 では深い入れ子が潰れる）。字下げと、`<`・`>`・`&`・`'` の書き方（`\u003c` など）が変わるが、JSON の中身は同じで、Windows Terminal が次に保存するときに整える
- `profiles` が配列なのは古い形式で、この節のブロックは扱わない
- 保存すると、Windows Terminal がファイルの変化を見て読み直し、開いているタブにも効く
- fragment（`%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments`）に書けるのは、プロファイル・配色・アクション（キーを除く）だけで、全体の設定と `profiles.defaults` は読まれない（`_parseFragment`）
- 控えは、控えが無いときだけ作る（2 回目に貼っても、元の設定が残る）。この節の手順 6 で書き戻すと消すので、次にこの節を通すときは、そのときの設定を控え直す
- 書き戻しは `Move-Item` にせず、`Copy-Item` の後に控えを消す。Windows Terminal が見張る `settings.json` が、途中で無くならないようにするため

### Windows Terminal のフォントと貼り付けの警告を変える（任意） / 手順 3: 補足: フォント

- `profiles.defaults.font.face`。既定は `Cascadia Mono`（見つからなければ Consolas）、大きさは 12（WezTerm の自分用の設定も 12）
- 「表示と入力」の手順 6 で既定の端末にしたので、スタートメニューから開いた管理者ではない窓は Windows Terminal に渡される。Windows Terminal は、コマンド ラインが一致するプロファイル（Windows PowerShell など）を使い、無ければ `profiles.defaults` を使う（`CascadiaSettings.cpp`）。新しく作る設定の Windows PowerShell とコマンド プロンプトのプロファイルは、自分のフォントを持たない（`userDefaults.json`）ので、`profiles.defaults` が効く
- 管理者として開いた窓（conhost）のフォントは、`HKCU\Console` などの別の設定で、この節では扱わない
- hackgen.md は自分のユーザーのフォントに入れ、パッケージのアプリ向けに読み取りの権限（`S-1-15-2-1`・`S-1-15-2-2`）を足す。MSIX の Windows Terminal から見えるかは確かめていない
- 見つからないと、設定の画面に「見つからないフォント:」、端末に「次のフォントが見つかりません: …」が出る（`Resources.resw` の日本語の訳）

### Windows Terminal のフォントと貼り付けの警告を変える（任意） / 手順 4: 補足: 複数行の貼り付けの警告

- 値は版で変わった。1.22 以前は `multiLinePasteWarning`（真偽値）、1.23 は `warning.multiLinePaste`（真偽値）、1.24 から `warning.multiLinePaste` が `automatic`・`always`・`never`（既定は `automatic`。`true` は `automatic`、`false` は `never` として読む）。古い名前も読み、新しい名前に直して書き直す。Microsoft の文書（interaction のページ）は、まだ古い名前だけを書いている
- `automatic` は、シェルが角かっこで囲む貼り付け（bracketed paste）を有効にしていないときに、改行を含む文字を貼ると警告する（`TerminalPage.cpp`）。Windows PowerShell 5.1 の PSReadLine 2.0.0 も ConPTY もこれを有効にしないので、5.1 の窓では毎回出るはず（コードからの推測。確かめていない）
- 画面では「操作」→「改行を貼り付ける際に警告する」（「"角かっこで囲まれた貼り付け" がオフの場合」・「常時」・「なし」）。ダイアログの題は「警告」で、ボタンは「強制的に貼り付け」と「キャンセル」
- 出るダイアログは 1 つだけ。複数行の警告が出ないときに、5 KiB（UTF-16 で 5,120 文字）を超えると `warning.largePaste`（既定 true）の警告が出る
- Windows Terminal は、貼るときに改行を Enter として送る。PSReadLine は、閉じていない文（`& {` など）の行を続きとして受けるので、1 行ずつ届いても、この文書のブロックは正しく動く
- `trimPaste`（既定 true）は、1 行の貼り付けの末尾の空白だけを削る。貼った後に Enter が要るのは、コピーボタンの中身に末尾の改行が無いため

### Windows Terminal のフォントと貼り付けの警告を変える（任意）: 選択した方針

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| 書く場所 | `settings.json`（コメントがあれば止める） | fragment: 全体の設定と `profiles.defaults` を読まない |
| フォント | `profiles.defaults`（全プロファイル） | プロファイルごと（fragment の `updates`）: 一致するプロファイルの無い窓に効かない |
| 複数行の警告 | 既定（`automatic`）。切るのは条件付き（この節の手順 4） | 無条件に `never`: 信用できない複数行も、確かめずに動く |
| 既定のプロファイル | Windows PowerShell のまま | PowerShell 7: 5.1 でだけ動く手順を貼り違えやすい（[PowerShell 7 のプロファイルの選択した方針](#powershell-7-のプロファイルを設定する任意-選択した方針)） |
| `copyOnSelect` | 既定（false）のまま | true: 選ぶとコピーされ、右クリックが常に貼り付けになる。貼る手順書で、意図しない貼り付け（実行）になりやすい |
| 起動の大きさ | 既定（120×30）のまま | 好みなので扱わない |
| 管理者の窓（conhost）のフォント | 扱わない | 別の設定（`HKCU\Console`・ショートカットごと） |
| 戻し方 | 控えのファイルを書き戻す | 足した値だけを消す: 控えのほうが、書く前の状態に確実に戻る（その後に画面で変えたものは消える） |

### WSL のネットワークをミラーにする（任意） / 手順 3: 補足: `.wslconfig`

- `%USERPROFILE%\.wslconfig` の `[wsl2]` の `networkingMode`。既定は `nat`（2.3.25 からは、NAT に失敗すると Consomme）。`[experimental]` の `networkingMode` も、互換のために読む（`WslCoreConfig.cpp`）
- Windows 11 22H2 以上が要る（対象の 24H2・25H2 は満たす）
- 「Linux 用 Windows サブシステム設定」の画面も同じファイルに書く。そのため、ファイルがあれば上書きせず、控えてから `[wsl2]` の見出しの次に 1 行足す（見出しが無ければ末尾に足す。改行はファイルに合わせる）。`networkingMode` の行が既にあれば止める
- BOM の無い UTF-8 で書く
- `localhostForwarding` は、ミラーでは無視される
- 効くのは `wsl.exe --shutdown` の後。シェルを閉じるだけでは、VM が既定でおよそ 60 秒（`vmIdleTimeout`）残る
- 書かないもの
  - `dnsTunneling`・`firewall`・`autoProxy`: どれも既定で true（Windows 11 22H2 以上）。ミラーでは `firewall=false` を書いても、Hyper-V のファイアウォールは有効になる
  - メモリ・プロセッサ・スワップ: 既定は RAM の 50%・全論理プロセッサ・RAM の 25%。VirtualBox と RAM を分けたいときだけ `memory` を絞る
  - `[experimental]` の `autoMemoryReclaim`（既定 `dropCache`）・`sparseVhd`（新しく作る VHD にだけ効く）
  - `[experimental]` の `hostAddressLoopback`（既定 false）: true にすると、WSL からこの PC の LAN の IP あてでも Windows につながる（IPv4 だけ）。`127.0.0.1` で足りる
  - `[experimental]` の `ignoredPorts`: Windows が使っているポートでも Linux に bind させる。WSL の中で sshd を動かす手順は、このリポジトリに無い

### WSL のネットワークをミラーにする（任意） / 手順 4・5: 補足: 確かめ方

- `wslinfo --networking-mode` は、WSL が各ディストリビューションに置くコマンド。AlmaLinux 10 のイメージで使えるかは確かめていない。無ければ、WSL の中の IP と Windows の IP を比べる（ミラーでは同じ IP になる）
- ミラーを使えないとき、WSL は NAT に戻し、`wsl.exe` が理由の行（`ミラー化されたネットワーク モードはサポートされていません: …`）を出す（`Resources.resw` の `MessageMirroredNetworkingNotSupportedReason`）
  - `wslinfo --networking-mode` は、そのときも `nat` を出す（`wslinfo.cpp`）
- この節の手順 5: NAT では、WSL の中の `127.0.0.1:22` は WSL 自身を指すので、Windows の sshd には届かない。ミラーでは Windows のループバックに届く（`::1` は使えない）。`/dev/tcp` は bash の機能で、`head -n 1` で sshd の最初の 1 行（バナー。CR LF で終わる）を読む
- ミラーでは、sshd のログの送信元が、LAN の IP から `127.0.0.1` に変わるはず（確かめていない。`sshd_config` にアドレスでの絞り込みは無いので、動きは変わらない）

### WSL のネットワークをミラーにする（任意）: 選択した方針

- **ミラーにする理由**: WSL と Windows が `127.0.0.1` で互いにつながり、IPv6・マルチキャスト（mDNS）・VPN との相性がよく、LAN から WSL に直接届く（Microsoft の文書）
- **既知の問題**（Microsoft の文書。troubleshooting）
  - Docker の `-p` のポートの公開（`ignoredPorts` で避ける）、OpenVPN 2.6.501 などの一部の VPN
  - UDP 68・TCP 135/1900/2869/5004/3702/5357/5358 は、WSL に届かない
  - WSL が `accept_local`・`route_localnet`・`rp_filter` などの sysctl を自分で設定する
  - Global Secure Access のクライアントの PC では、`dnsTunneling=false` か NAT に戻す
- **LAN から WSL の中のサーバーへの受信は開けない**: ミラーでは、Hyper-V のファイアウォールが受信を絞る。開けるなら、管理者で `New-NetFirewallHyperVRule … -VMCreatorId '{40E0AC32-46A5-438A-A0B2-2B479E8F2E90}' -Protocol TCP -LocalPorts <ポート> -Profiles Private` にする（`-Profiles` の既定は Any なので、「ネットワークとリモート」の手順 2・4 と同じくプライベートに絞る）。全部を開ける `Set-NetFirewallHyperVVMSetting -DefaultInboundAction Allow` は使わない
- **ファイルに書く**: Microsoft の文書は「Linux 用 Windows サブシステム設定」の画面を勧めるが、貼って確かめられるようにファイルに書く。画面も同じファイルに書く
- [VirtualBox のゲスト（bootc）](../virtualbox-guest-bootc.md#ホストオンリーアダプターだけの-vm-でビルドする任意)の、WSL からホストオンリーのネットワークの VM に届いた記録は NAT のときのもの。ミラーでは確かめていない

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| ネットワーク | ミラー | NAT（既定）: WSL から Windows のサーバーに LAN の IP あてでつなぎ、IPv6・mDNS が使えない |
| 書くキー | `networkingMode` だけ | `dnsTunneling`・`firewall`・`autoProxy`: 既定で有効。メモリなど: 既定で足りる |
| LAN から WSL への受信 | 開けない | Hyper-V のファイアウォールの規則: 管理者が要り、WSL の中のサーバーを LAN に開ける |
| `hostAddressLoopback` | 書かない | LAN の IP あてでも Windows につながるが、`127.0.0.1` で足りる |
| 既にある `.wslconfig` | 控えてから 1 行足す（`networkingMode` があれば止める） | 上書き: 画面などで書いた値が消える |

### 実施手順 / シェルのツールを入れる / 手順 1: 補足: 確かめる値

- `Tools` が空なら、どれも入っていない
- ほかの方法で入れたものを外してから始めるのは、混ざらないようにするため

### 実施手順 / シェルのツールを入れる / 手順 3: 補足: scoop がすることと、zoxide を 0.9.9 に止める理由

- 5 つとも scoop の main のバケットの定義で、上流の Windows の zip を、定義の sha256 で確かめて置く（2026-10-08 の定義は fzf 0.74.4・zoxide 0.10.0・starship 1.26.0・eza 0.23.5・bat 0.26.1）
  - `was installed successfully!` の行の版は、入れた日の最新（zoxide は `0.9.9`）
  - fzf・zoxide・eza・bat は、`~\scoop\shims` に shim を作る（eza は `exa` の名前の shim も）
  - starship は shim を作らず、定義の `env_add_path` で `~\scoop\apps\starship\current` を自分のユーザーの `Path` の先頭に足す。scoop は、今の窓の `$env:PATH` にも足す（Scoop の `lib/system.ps1` の `Add-Path`）
  - bat は、定義の `env_set` で、自分のユーザーの環境変数 `BAT_CONFIG_DIR` を `~\scoop\apps\bat\current` にし、今の窓にも入れる。`config`・`syntaxes`・`themes` は `~\scoop\persist\bat` に控える（ファイルはハードリンク、フォルダーはジャンクション）。控えに `config` が無い最初の導入では、`%APPDATA%\bat\config` があれば写し、無ければ空のファイルを作る（定義の `pre_install`）
- **zoxide を 0.9.9 に止める理由**
  - 0.10.0 の bash の初期化は、Windows では `__zoxide_pwd` が `\command cygpath -w "\builtin pwd -L"` になり、コマンド置換が無い（`templates/bash.txt`）。今のディレクトリではなく、`<ドライブ>:\builtin pwd -L` の形の文字列を返すので、プロンプトのフックが移動に気付かず、Git Bash からは何も記録しない（上流の issue #1259）
  - 直すコミット（`1f484a4`、PR #1260、2026-07-07）は `main` にあり、`CHANGELOG.md` の `[Unreleased]` に「Bash/Zsh: fix `z` failing on Cygwin/MSYS2 due to `cygpath` being passed a bad string.」とある。2026-10-08 の時点で、タグの最新は `v0.10.0` で、このコミットを含むタグは無い
  - 0.9.9 の初期化は `\command cygpath -w "$(\builtin pwd -P)"`（Windows の `zoxide.exe` の中の文字列でも確かめた）。共通の bash 設定の Git Bash での検証（ryo-aoki-pc/bash の 2026-10-01・2026-10-06 の付録）も、0.9.9 で通っている
  - PowerShell の初期化は、この不具合に当たらない。PowerShell 7 の zoxide も Git Bash と同じ実行ファイルなので、0.9.9 にそろう
  - データベースの形は、0.9.9 と 0.10.0 で同じ（版 3 の `db.zo`。`src/db/mod.rs`）。0.10.0 から 0.9.9 に戻しても、覚えた履歴はそのまま読む
  - `main` には、データベースを平文の `db.txt` に変え、`db.zo` があれば読んで移す変更もある（`c479cc8`、#1288、2026-10-03。版になっていない）。直った版に上げると、履歴はその形に移るはず。上げた後に 0.9.9 に戻すと、上げた後に覚えたものは読まないはず
- **版の指定と止め方**（Scoop v0.6.0 のソース）
  - `scoop install zoxide@0.9.9` は、バケットの今の定義と版が違うと、バケットの git の履歴から `0.9.9` の定義を探し（`git log --follow -n 1 -G …` で見つけたコミットと、その親）、`~\scoop\workspace\zoxide.json` に書いてから入れる（v0.6.0 の #6370）。見つからなければ `WARN` の行を出して、定義の `autoupdate` で作る
  - 履歴を探すのは、main のバケットが git のリポジトリのときだけ（`lib/manifest.ps1` の `Find-HistoricalManifestInGit`）。そうでなければ `WARN  Bucket 'main' is not a git repository. Cannot search historical versions.` を出して `autoupdate` に移り、hash はバケットの履歴の定義のものではなく、そのときに取ったものになる。`autoupdate` も失敗すると、`Could not install: zoxide@0.9.9` で止まる
  - 本書の「アプリを入れる」の手順 1・2 は Git for Windows より前に scoop を入れるので、main のバケットは zip で置かれる（ScoopInstaller/Install の `install.ps1`）。git の形になるのは、最初の `scoop update`（`scoop-update.ps1` の `Sync-Bucket` の `Converting 'main' bucket to git repo...`）。`scoop install` が自分で `scoop update` を動かすのは、前の更新から 3 時間たったとき（`is_scoop_outdated`）だけなので、この節の手順 4 の先頭で `scoop update` を貼る
  - main のバケットでは、`73b1eafab`（2026-01-31）で 0.9.9 に、`f8683b6ce`（2026-07-04）で 0.10.0 になった。`f8683b6ce` の親の定義が 0.9.9
  - こうして入れたものは、`install.json` に `bucket` が無く、`url` が `workspace` の定義を指す。`scoop status` と `scoop update` は、その定義の版（0.9.9）を最新とみなすので、それだけでも上がらない。`scoop list` の `Source` は `<auto-generated>`
  - そのうえで `scoop hold` を付けた（`install.json` に `hold` を書く）。`scoop list` の `Info` が `Held package` になり、止めてあることが見える。`scoop update * --force` でも、止めたものは上げない
  - 直った版に上げるときは、`scoop unhold` の後に `scoop update zoxide --force` にする。`--force` は、版を指定して入れたもの（`bucket` が無く、`url` が `workspace` の定義）を、バケットの今の定義で入れ直す（v0.6.0 の #6730）。`--force` が無ければ、`zoxide: 0.9.9 (latest version)` の形の行を出して何もしない
  - 先に `scoop update` を貼るのは、バケットを新しくするため（`scoop update <名前>` は、前の更新から 3 時間たっていなければバケットを新しくしない）
  - 版を指定したものは、`~\scoop\workspace\zoxide.json` の場所として扱われ、`prune_installed` は入っているとみなさない（`installed` が `zoxide.json` の名前で探す）。0.10.0 が入っていても 0.9.9 を並べて入れ、`current` を 0.9.9 に付け替え、0.10.0 のフォルダーを残す。そのため、この節の手順 3 で先に外す
  - 同じ 0.9.9 がもう入っていると、`'zoxide' (0.9.9) is already installed.` の警告の後の `continue`（`scoop-install.ps1` の `ForEach-Object` の中で、囲むループが無い）が `bin/scoop.ps1` の `switch` まで抜け、同じ行のほかの名前を入れずに終わる。そのため、この節の手順 4 では zoxide だけを別の `scoop install` にした
  - 版を指定しない名前を並べたとき（この項の手順 3 の 2 行目）は、もう入っているものを `prune_installed` で飛ばす。`'<名前>' (<版>) is already installed. Skipping.` の警告は出ない（`Get-Dependency` が名前を `main/<名前>` の形に変えるので、警告を出す前の、指定した名前との突き合わせに当たらない）
  - 名前を 1 つだけ渡したときは、もう入っていれば `'<名前>' (<版>) is already installed.` と `Use 'scoop update <名前>' to install a new version.` の警告を出して終わる（`$apps.length -eq 1` の分かれ）
  - [scoop・winget・WSL を上げる](../windows-setup.md#scoopwingetwsl-を上げる)の手順 7 で、先に main のバケットの `bucket\zoxide.json` の版を見るのは、`scoop update zoxide --force` が Releases ではなく、main のバケットの今の定義を入れるため（`update` の `$pin_broken` から `Find-AppBucket`）。バケットの定義は、Releases に出てから自動の更新で上がるまで遅れる。0.10.0 のまま上げると、止めるのをやめた 0.10.0 になる
  - `scoop uninstall` は、止めてあっても消す（`hold` を見ない）。そのため、[ロールバックの「エディタとシェルのツールを消す」](../extra/windows-setup.md#エディタとシェルのツールを消す)の手順 7 に `scoop unhold` は要らない
- **VC++ ランタイム**: 5 つの Windows の実行ファイル（x64）の DLL の読み込みの表（PE のインポート表）で、`VCRUNTIME140.dll` を使うのは bat だけだった
  - fzf（Go）は `kernel32.dll` だけ。zoxide と starship は MSVC のビルドだが、C のランタイムを静的にリンクする（zoxide の `.cargo/config.toml`、starship の `release.yml` の `+crt-static`）。eza は MinGW のビルドで、Windows に付いている `msvcrt.dll` を使う
  - bat の定義の `suggest` は、extras の `vcredist2022` と `less` を勧める表示だけで、入れはしない。本書では [WezTerm](../windows-setup.md#wezterm)の手順 2（winget の `Microsoft.VCRedist.2015+.x64`、PC 全体）を前提にした。starship の定義の `suggest`（`vcredist2022`）は、入れなくてよい
- starship の定義の `notes` は、PowerShell の `$PROFILE` に `Invoke-Expression (&starship init powershell)` を足すよう案内するが、従わない。Windows PowerShell 5.1 の `$PROFILE` は、手順書を貼る窓（管理者の窓も）が読むプロファイル。PowerShell 7 には、[PowerShell 7 のプロファイルを設定する（任意）](../windows-setup.md#powershell-7-のプロファイルを設定する任意)が、zoxide と starship の行を 1 回だけ置く

### 実施手順 / シェルのツールを入れる / 手順 5: 補足: bat の設定ファイル

- Windows の bat は、`BAT_CONFIG_PATH` が無ければ `BAT_CONFIG_DIR` の下の `config` を、それも無ければ `%APPDATA%\bat\config` を読む（bat 0.26.1 の `src/bin/bat/directories.rs`・`config.rs`。`XDG_CONFIG_HOME` も `~/.config` も見ない）。scoop で入れると `BAT_CONFIG_DIR` の下になる
  - そのため、AlmaLinux 10 の [bat の設定ファイル](../almalinux-setup.md#bat-の設定ファイル)の bash のブロックを Git Bash に貼っても効かない
  - `C:\ProgramData\bat\config`（PC 全体）があれば、bat はその後ろに自分の設定をつないで読む。本書では作らない
- 書く場所は、bat が探すのと同じ順（`BAT_CONFIG_PATH`、無ければ `BAT_CONFIG_DIR` の下の `config`）で決める。`BAT_CONFIG_PATH` を自分で決めていても、bat が読む場所に書ける。どちらも無ければ（scoop の bat が入っていない）、`%APPDATA%` には書かずに止める
- `bat --config-file` の出力は使わない。bat はパイプに UTF-8 で書く（bat 0.26.1 の `src/bin/bat/main.rs` の `println!`）が、Windows PowerShell 5.1 は外部コマンドの出力を `[Console]::OutputEncoding`（日本語の Windows では OEM のコードページ 932）で読む。ユーザーのフォルダー名に ASCII 以外の文字があると、場所の文字が化けて書けない（Windows では確かめていない）
- 「無いときだけ」ではなく「空のときだけ」書く。scoop は最初の導入で空の `config` を作る（定義の `pre_install`）。`%APPDATA%\bat\config` から写されたものや、手で書いたものは変えない
- `-Encoding ASCII` にしたのは、BOM を付けないため
  - Windows PowerShell 5.1 の `-Encoding UTF8` は BOM を付ける。bat は設定の各行の前後の空白を削ってから読むが、BOM は削らず、1 行目をファイルの名前として読んで失敗する（Linux の bat 0.26.1 で確かめた。[検証記録](../verification/windows-setup.md#付録-シェルのツールの任意節のブロックの確認2026-10-08)）
  - テーマの名前と 3 行の中身は ASCII だけ。改行は CRLF になるが、bat は行末の `\r` も削る（同じ記録）
- `current\config` に書いた中身は、ハードリンクのもう一方の控え（`persist`）にも入るはず（Linux のハードリンクと PowerShell 7.5.3 では、同じ中身になった。Windows の NTFS と 5.1 では確かめていない）
- 戻す（[ロールバックの「エディタとシェルのツールを消す」](../extra/windows-setup.md#エディタとシェルのツールを消す)の手順 8）のは控えのファイルで、この節で書いた形（1 行目がテーマ、後の 2 行が同じ）のときだけ、空にする。ハードリンクのもう一方（`current\config`）も空になるので、bat を残していても組み込みの既定値に戻る。scoop の最初の導入と同じ空のファイルなので、入れ直しても困らない

### 実施手順 / シェルのツールを入れる / 手順 6・7: 補足: Git Bash での確かめ方

- AlmaLinux 10 の初期設定の「シェルのツール」の手順 4〜7・9・10 と「キー操作を試す」の手順 2〜5 は、`brew` の行を含まず、共通の bash 設定が読んだ結果を確かめるだけなので、Git Bash でもそのまま使える。この節には bash のブロックを足さず、Windows で違うところだけを箇条書きにした（同じブロックを書き写すと、片方だけ直したときに食い違う）
  - 「シェルのツール」の手順 8（tmux）は、Windows では入れない。「キー操作を試す」の手順 1 は bash-completion と `~/.inputrc`（AlmaLinux 10 の「共通の bash 設定」の手順 3・4）を確かめるもので、この節では入れていない
- WezTerm は Windows で新しいタブを開くたびに、レジストリのシステムとユーザーの環境変数を読み直す（WezTerm の `pty/src/cmdbuilder.rs` の `get_base_env`）。そのため、この項の手順 3 の後に開いた新しいタブには、WezTerm を起動し直さなくても、starship の `Path` と `BAT_CONFIG_DIR` が入るはず（確かめていない）。起動し直すのは、プロンプトが starship にならなかったときだけにした
- 違うところの出どころ
  - `bind -X` のコロンと、WezTerm のシェル統合のマウス報告よけの行: ryo-aoki-pc/bash の `docs/install.md`（Git Bash の bash 5.3 の記録）
  - eza の見出し: eza 0.23.5 の `src/output/table.rs`。Windows では `Permissions` の見出しが `Mode` になり、`User` の列は Unix のときだけ作る
  - Git for Windows の `ll`（`/etc/profile.d/aliases.sh`。ログインシェルだけ）は `~/.bashrc` より先に読まれるので、共通の bash 設定の `ll` が上書きする。`MANPAGER` は bat があれば入るが、Git Bash に `man` は無い（ryo-aoki-pc/bash の `docs/reference/readme.md`）
  - zoxide: Windows の zoxide は、Git Bash ではプロンプトのたびに `cygpath -w` を動かし、Windows の形のパスで記録する。データベースは `HOME` の下ではなく `%LOCALAPPDATA%\zoxide`（zoxide の README の `_ZO_DATA_DIR` の表と、scoop の定義の `notes`）
  - fzf の ASCII 以外の文字: fzf の `CHANGELOG.md` の 0.54.2 に、Windows では全画面（`--no-height`）で開いたときしか ASCII 以外の文字を読めず、必要なら `FZF_DEFAULT_OPTS` に `--no-height` を足すよう書いてある。キー操作と `**<Tab>` は画面の一部（`--height`）に開く
  - fzf は Windows でも `$SHELL` で外部のコマンド（プレビューの bat など）を動かし、`/` を含むパスは `cygpath -w` で直す（fzf 0.74.4 の `src/util/util_windows.go`）。Git Bash の `SHELL` は bash なので、プレビューは bash で動くはず
- スタートメニューの「Git Bash」（mintty）でも同じ共通の bash 設定を読むが、fzf は winpty の連携で動く（fzf の CHANGELOG の 0.53.0）ので、WezTerm（ConPTY）と動きが違いうる。確かめは WezTerm で行う
- 覚えたディレクトリは `%LOCALAPPDATA%\zoxide` に入る（PowerShell 7 の zoxide も同じものを使う）

### 更新 / scoop・winget・WSL を上げる / 手順 7: 補足: zoxide を上げた後の更新

- これより後は、[scoop・winget・WSL を上げる](../windows-setup.md#scoopwingetwsl-を上げる)の手順 1・2 で、ほかのツールと一緒に上がる

### ロールバック / エディタとシェルのツールを消す / 手順 7: 補足: 開き直す理由

- 共通の bash 設定と PowerShell 7 のプロファイルは、無いツールを読まないので、開いている Git Bash のタブと PowerShell 7 の窓は閉じて開き直す

### シェルのツールを入れる: 選択した方針

- **1 つの項にまとめた**（2026-10-08 に任意節として足し、2026-10-10 に必須の項にした）: AlmaLinux 10 の starship・zoxide・fzf・eza・bat は、2026-10-08 に [AlmaLinux 10 の初期設定の「シェルのツール」](../almalinux-setup.md#シェルのツール)の手順 1 などにまとめられ、ツールごとの手順書は無くなった。Windows 11 も同じく、初期設定の手順書にまとめ、5 つを 1 つの手順（`scoop install` は、版を指定しない 4 つと zoxide の 2 回）で入れる
  - git-delta と GitHub CLI も、2026-10-10 から同じ手順書の項（[git-delta](../windows-setup.md#git-delta)・[GitHub CLI](../windows-setup.md#github-cli)）にある
- **導入元は scoop の main のバケット**（README の「導入の基盤」の、CLI ツールは scoop）
  - 管理者が要らず、[更新](../windows-setup.md#更新)の `scoop update *` と UniGet UI で上がる
  - zoxide の README は、Windows では winget を勧めている。0.10.0 の不具合は zoxide の初期化（実行ファイルの中）にあるので、どちらで入れても避けられず、版を止められる scoop にそろえた
- **シェルとの組み込み方は、[PowerShell 7 のプロファイルを設定する（任意）の選択した方針](#powershell-7-のプロファイルを設定する任意-選択した方針)と同じ**: Git Bash が主、PowerShell 7 は補助（starship と zoxide だけ）、Windows PowerShell 5.1 には入れない、WSL の AlmaLinux 10 は Linux のホストとして扱う
  - Git Bash では共通の bash 設定が読むので、この節は入れて確かめるだけにし、`~/.bashrc` には書かない
  - PowerShell 7 の fzf のキー操作（PSFzf）と eza の関数は入れない（主の Git Bash に同じものがある）
- **`XDG_CONFIG_HOME` などの環境変数は足さない**: Windows の bat と eza は `XDG_CONFIG_HOME` を見ない（bat の設定は `BAT_CONFIG_DIR` か `%APPDATA%`、eza のテーマは `%APPDATA%\eza\theme.yml`。eza 0.23.5 の `src/options/theme.rs`）。starship は `STARSHIP_CONFIG` が無ければ `~\.config\starship.toml` を読む（starship 1.26.0 の `src/context.rs`。Git Bash と PowerShell 7 で 1 つ）。zoxide は `%LOCALAPPDATA%\zoxide`。足すと、gh などほかのツールの設定の置き場所まで変わる
- **bat の設定は AlmaLinux 10 と同じ 3 行**: テーマも同じ名前の変数（`BAT_THEME_NAME`）で決める。書く場所だけが違う
- **使い方と設定の節は、AlmaLinux 10 の初期設定の後ろの節を指す**: starship の 3 節は `~/.config/starship.toml`（Git Bash と PowerShell 7 で 1 つ）に書き、fzf の候補の fd は共通の bash 設定が `command -v fd` で見つける（ryo-aoki-pc/bash の `bashrc`）ので、`brew` の行を除けば Git Bash に同じブロックを貼れる。違う 2 つ（fd の入れ方と、bat の設定ファイル）だけを、この節のリードに書いた（Git Bash では確かめていない）

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| zoxide の版 | 0.9.9 に止める（`zoxide@0.9.9` と `scoop hold`）。上げるのは、main のバケットの定義が 0.10.0 より新しくなってから | 0.10.0: Git Bash で記録しない。共通の bash 設定で `__zoxide_pwd` を上書きする: 上流の初期化に合わせた上書きを持ち、直った版が出たら外す手間が要る |
| 入れる単位 | 1 つの手順で、版を指定しない 4 つを 1 回の `scoop install`、zoxide の 0.9.9 を別の 1 回 | ツールごとの節: 確かめる場所が同じ Git Bash のタブで、まとめたほうが短い。5 つを 1 回の `scoop install`: zoxide の 0.9.9 がもう入っていると、scoop がほかの 4 つを入れずに終わる |
| Git Bash での確かめ | AlmaLinux 10 の初期設定の手順を指す | 同じ bash のブロックを書き写す: 片方だけ直したときに食い違う |
| bat の設定 | `BAT_CONFIG_PATH` か `BAT_CONFIG_DIR` の下（scoop の中）に、空のときだけ書く | `BAT_CONFIG_PATH` で `~/.config/bat/config` を読ませる: scoop の定義が向ける場所と二重になる。`bat --config-file` の出力を使う: 5.1 では、ASCII 以外の文字のフォルダー名が化ける |
| VC++ ランタイム | 無ければ WezTerm の手順 3（管理者の窓） | extras の `vcredist2022` を scoop で入れる: extras のバケットを足す手順が増える |
| fzf の ASCII 以外の文字 | 変えない（手順 8 の補足だけ） | `FZF_DEFAULT_OPTS` に `--no-height`: 全画面で開き、AlmaLinux 10 と見た目が変わる。実機で確かめてから決める |

### 更新 / scoop・winget・WSL を上げる / 手順 2: 補足: SSH のセッションの任意節を貼り直す理由

- scoop で上げると、新しいジャンクションができるため

### 更新 / scoop・winget・WSL を上げる / 手順 4: 補足: wsl.exe --update

- `wsl.exe --update` は WSL のパッケージ（とカーネル）を上げる

### 更新 / scoop・winget・WSL を上げる / 手順 5: 補足: Windows の更新と、新しい窓

- Windows の更新は、このコマンドでは行わない
- 新しく開いた管理者の窓で Windows Update を行うのは、読み込み済みの窓では古いモジュールが残るため

### 参照

[検証記録](../verification/windows-setup.md#参考資料から分離した記録)

任意節（プライバシーと広告・表示と入力と音とストレージ・Edge の常駐・CopyQ。2026-10-08）の資料。「文書」は Microsoft の文書、「コード」はソースと定義、「広く」はコミュニティの情報。

- 文書: [Manage connections from Windows operating system components to Microsoft services — Microsoft Learn](https://learn.microsoft.com/en-us/windows/privacy/manage-connections-from-windows-operating-system-components-to-microsoft-services) — 18.1（広告 ID・言語リスト・`Start_TrackProgs`）、18.6（オンライン音声認識）、18.16（フィードバックの頻度）、18.21（手書き入力）、18.22（アクティビティの履歴）
- 文書: Policy CSP — [Privacy](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-privacy)・[Experience](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-experience)・[System](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-system)・[Search](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-search)・[Multitasking](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-multitasking)・[Storage](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-storage)・[ApplicationManagement](https://learn.microsoft.com/en-us/windows/client-management/mdm/policy-csp-applicationmanagement) — 採らなかったポリシーと、値が無いときの動き
- 文書: [Manage Recall — Microsoft Learn](https://learn.microsoft.com/en-us/windows/client-management/manage-recall)・[Windows spotlight — Microsoft Learn](https://learn.microsoft.com/en-us/windows/configuration/windows-spotlight/)・[Windows activity history and your privacy — Microsoft Support](https://support.microsoft.com/en-us/windows/windows-activity-history-and-your-privacy-2b279964-44ec-8c2f-e0c2-6779b07d2cbd) — 入れなかった項目
- 文書: [Diagnostics, feedback, and privacy in Windows](https://support.microsoft.com/en-us/windows/diagnostics-feedback-and-privacy-in-windows-28808a2b-a31b-dd73-dcd3-4559a5199319)・[Speech, voice activation, inking, typing, and privacy](https://support.microsoft.com/en-us/windows/privacy/speech-voice-activation-inking-typing-and-privacy)・[Windows Search and privacy](https://support.microsoft.com/en-us/windows/windows-search-and-privacy-99fb8251-7260-1cd6-1bbb-15c2370eb168) — Microsoft Support。画面の項目と、辞書が消えること
- 文書: [Launch the Windows Settings app — Microsoft Learn](https://learn.microsoft.com/en-us/windows/apps/develop/launch/launch-settings) — `ms-settings:privacy`・`storagepolicies`・`easeofaccess-visualeffects`・`clipboard`
- 文書: [STICKYKEYS](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-stickykeys)・[FILTERKEYS](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-filterkeys)・[TOGGLEKEYS](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-togglekeys)（Microsoft Learn）と [StickyKeys（Windows Embedded のブログ、2007 年）](https://learn.microsoft.com/en-us/archive/blogs/embedded/stickykeys) — `Flags` のビットと既定の 510
- 文書: [Windows keyboard shortcuts for accessibility](https://support.microsoft.com/en-us/windows/windows-keyboard-shortcuts-for-accessibility-021bcb62-45c8-e4ef-1e4f-41b8c1fc87fd)・[Keyboard shortcuts in Windows](https://support.microsoft.com/en-us/windows/keyboard-shortcuts-in-windows-dcc61a57-8ff0-cffe-9796-cb9706c75eec) — Microsoft Support。Win+Space・Ctrl+Shift+V・Win+V
- 文書: [SystemParametersInfo](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfow)・[ANIMATIONINFO](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-animationinfo) — Microsoft Learn。`SPI_SETLANGTOGGLE`・`SPI_SETCLIENTAREAANIMATION`・`SPI_SETANIMATION`
- 文書: [Integrate a Cloud Storage Provider](https://learn.microsoft.com/en-us/windows/win32/shell/integrate-cloud-storage)・[Merged View of HKEY_CLASSES_ROOT](https://learn.microsoft.com/en-us/windows/win32/sysinfo/merged-view-of-hkey-classes-root)・[Registry Keys Affected by WOW64](https://learn.microsoft.com/en-us/windows/win32/winprog64/shared-registry-keys) — Microsoft Learn。`System.IsPinnedToNameSpaceTree` と `HKCU` の上書き
- 文書: [Windows でマルチタスクを行う方法 — Microsoft サポート](https://support.microsoft.com/ja-jp/windows/how-to-multitask-in-windows-b4fa0333-98f8-ef43-e25c-06d4fb1d6960)・[Windows 10 Insider Preview Build 21286](https://blogs.windows.com/windows-insider/2021/01/06/announcing-windows-10-insider-preview-build-21286/) — Alt+Tab のタブとシェイク
- 文書: [KB5031455](https://support.microsoft.com/en-us/topic/october-31-2023-kb5031455-os-builds-22621-2506-and-22631-2506-preview-6513c5ec-c5a2-4aaf-97f5-44c13d29e0d4)・[Windows の詳細設定 — Microsoft Learn](https://learn.microsoft.com/en-us/windows/advanced-settings/) — タスクの終了
- 文書: [Manage drive space with Storage Sense — Microsoft Support](https://support.microsoft.com/en-us/windows/manage-drive-space-with-storage-sense-654f6ada-7bfc-45e5-966b-e24aded96ad5)・[Prepare and customize a VHD image of Azure Virtual Desktop — Microsoft Learn](https://learn.microsoft.com/en-us/azure/virtual-desktop/set-up-customize-master-image) — ストレージ センサーの動きと `01`
- 文書: [New-Item（5.1）— Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-item?view=powershell-5.1) — 既にあるレジストリのキーに `-Force` を付けると空のキーになる
- 文書: [StartupBoostEnabled](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/startupboostenabled)・[BackgroundModeEnabled](https://learn.microsoft.com/en-us/deployedge/microsoft-edge-policies/backgroundmodeenabled)・[Configure Microsoft Edge](https://learn.microsoft.com/en-us/deployedge/configure-microsoft-edge)（Microsoft Learn）と [Get help with startup boost — Microsoft Support](https://support.microsoft.com/en-us/topic/get-help-with-startup-boost-ebef73ed-5c72-462f-8726-512782c5e442)
- 文書: [Materials — Microsoft Learn](https://learn.microsoft.com/en-us/windows/apps/develop/ui/materials) — 透明効果を切るとアクリルが単色になる
- 文書: [RegisterHotKey](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-registerhotkey)・[SendInput](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput)・[PowerToys Advanced Paste](https://learn.microsoft.com/en-us/windows/powertoys/advanced-paste) — Microsoft Learn
- コード: [hluk/CopyQ](https://github.com/hluk/CopyQ)（`shared/copyq.iss`・`src/platform/win/winplatform.cpp`・`CHANGES.md`）と [CopyQ の known-issues](https://copyq.readthedocs.io/en/latest/known-issues.html)、[winget-pkgs の hluk.CopyQ](https://github.com/microsoft/winget-pkgs/tree/master/manifests/h/hluk/CopyQ)、[Inno Setup の PrivilegesRequiredOverridesAllowed](https://jrsoftware.org/ishelp/topic_setup_privilegesrequiredoverridesallowed.htm)
- コード: [microsoft/winget-dsc](https://github.com/microsoft/winget-dsc)（`Microsoft.Windows.Setting.Accessibility`）・[microsoft/WindowsDeveloperConfig](https://github.com/microsoft/WindowsDeveloperConfig)（`TaskbarEndTask`）
- コード: [ReactOS の input.cpl](https://github.com/reactos/reactos/blob/master/dll/cpl/input/key_settings_dialog.c)・[Wine の sysparams.c](https://github.com/wine-mirror/wine/blob/master/dlls/win32u/sysparams.c)・[Chromium の animation_win.cc](https://chromium.googlesource.com/chromium/src/+/HEAD/ui/gfx/animation/animation_win.cc)・[Chromium の auto_launch_util.cc](https://chromium.googlesource.com/chromium/src/+/main/chrome/installer/util/auto_launch_util.cc)、[MDN の prefers-reduced-motion](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion)
- 広く: [privacy.sexy の windows.yaml](https://github.com/undergroundwires/privacy.sexy/blob/master/src/application/collections/windows.yaml)・[Win10-Initial-Setup-Script](https://github.com/Disassembler0/Win10-Initial-Setup-Script/blob/master/Win10.psm1)（効果音）・[winutil の tweaks.json](https://github.com/ChrisTitusTech/winutil/blob/main/config/tweaks.json)（ギャラリーとホーム）・[stealthpuppy](https://stealthpuppy.com/windows-10-storage-sense-intune)・[cyberdrain](https://cyberdrain.com/automating-with-powershell-deploying-storagesense)（ストレージ センサー）、Ten Forums・ElevenForum・Winaero の記事

任意節（PowerToys・PowerShell 7 のプロファイル・Windows Terminal・WSL のネットワーク。2026-10-08 の 2 つ目）の資料。「文書」「コード」「広く」の区別は上と同じ。

- 文書: [Install PowerToys](https://learn.microsoft.com/en-us/windows/powertoys/install)・[PowerToys の DSC（Microsoft.PowerToys DSC v3）](https://learn.microsoft.com/en-us/windows/powertoys/dsc-configure/microsoft-dsc)・[PSDSC](https://learn.microsoft.com/en-us/windows/powertoys/dsc-configure/psdsc)・[Running as administrator](https://learn.microsoft.com/en-us/windows/powertoys/administrator)・[Peek](https://learn.microsoft.com/en-us/windows/powertoys/peek)・[Mouse utilities](https://learn.microsoft.com/en-us/windows/powertoys/mouse-utilities)・[Command Not Found](https://learn.microsoft.com/en-us/windows/powertoys/cmd-not-found) — Microsoft Learn。入る場所の食い違い、DSC、管理者で動かすこと、Peek の Space、Find My Mouse、プロファイルへの追記
- コード: [microsoft/PowerToys](https://github.com/microsoft/PowerToys)（`src/runner/main.cpp`・`general_settings.cpp`・`auto_start_helper.cpp`、`src/common/SettingsAPI/settings_helpers.cpp`、`src/settings-ui/Settings.UI.Library/EnabledModules.cs`・`PeekProperties.cs`・`FindMyMouseProperties.cs`、`src/modules/peek/peek/dllmain.cpp`、`installer/PowerToysSetupVNext/Common.wxi`・`Product.wxs`、`doc/dsc/modules/App.md`）
- 文書: [about_Profiles](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.6)・[about_Execution_Policies](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7.6)・[about_PowerShell_Config](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_config?view=powershell-7.6)・[about_PSReadLine](https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline?view=powershell-7.6)・[about_PSReadLine_Functions](https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline_functions?view=powershell-7.6)・[Set-PSReadLineOption](https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlineoption?view=powershell-7.6)・[Using predictors in PSReadLine](https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/using-predictors)・[about_Update_Notifications](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_update_notifications?view=powershell-7.6)・[about_Telemetry](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_telemetry?view=powershell-7.6) — Microsoft Learn
- コード: [PowerShell/PowerShell](https://github.com/PowerShell/PowerShell)（`CorePsPlatform.cs`・`ConsoleHost.cs`・`build.psm1`・`src/Modules/PSGalleryModules.csproj`）・[PowerShell/PSReadLine](https://github.com/PowerShell/PSReadLine)（`KeyBindings.cs`・`History.cs`・`Cmdlets.cs`・`SamplePSReadLineProfile.ps1`）
- コード: [zoxide の templates/powershell.txt](https://github.com/ajeetdsouza/zoxide/blob/v0.10.0/templates/powershell.txt)（0.9.9 も同じ形）・[starship の src/init/starship.ps1](https://github.com/starship/starship/blob/v1.26.0/src/init/starship.ps1)、自分用の設定の [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)（`lua/shells.lua`・`shell/wezterm.ps1`）と [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)（`bashrc`）
- 文書: [winget settings](https://learn.microsoft.com/en-us/windows/package-manager/winget/settings)（Microsoft Learn）と、コードの [microsoft/winget-cli](https://github.com/microsoft/winget-cli)（`doc/Settings.md`・`src/AppInstallerCommonCore/Public/winget/UserSettings.h`・`Manifest/ManifestComparator.cpp`）、[Devolutions/UniGetUI](https://github.com/Devolutions/UniGetUI)（`WinGetPkgOperationHelper.cs`） — winget の既定の範囲（「アプリを入れる」の手順 5 の補足）
- 文書: [Windows Terminal の settings.json の場所](https://learn.microsoft.com/en-us/windows/terminal/install#settings-json-file)・[JSON fragment extensions](https://learn.microsoft.com/en-us/windows/terminal/json-fragment-extensions)・[Profile - Appearance](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance)・[Interaction](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/interaction)・[Startup](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/startup) — Microsoft Learn（interaction のページは古い名前だけ）
- コード: [microsoft/terminal](https://github.com/microsoft/terminal)（`TerminalSettingsModel/MTSMSettings.h`・`CascadiaSettingsSerialization.cpp`・`CascadiaSettings.cpp`・`userDefaults.json`・`TerminalApp/TerminalPage.cpp`・`src/host/VtIo.cpp`・`src/types/utils.cpp`、日本語の訳の `Resources.resw`）
- 文書: [Advanced settings configuration in WSL](https://learn.microsoft.com/en-us/windows/wsl/wsl-config)・[Accessing network applications with WSL（Mirrored mode networking）](https://learn.microsoft.com/en-us/windows/wsl/networking#mirrored-mode-networking)・[Troubleshooting WSL](https://learn.microsoft.com/en-us/windows/wsl/troubleshooting)・[Hyper-V Firewall](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/hyper-v-firewall)・[New-NetFirewallHyperVRule](https://learn.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallhypervrule) — Microsoft Learn
- コード: [microsoft/WSL](https://github.com/microsoft/WSL)（`src/windows/common/WslCoreConfig.cpp`・`WslCoreConfig.h`、日本語の訳の `localization/strings/ja-JP/Resources.resw`）

任意節（シェルのツール。2026-10-08 の 3 つ目）の資料。「コード」の区別は上と同じ。

- コード: [ScoopInstaller/Main](https://github.com/ScoopInstaller/Main)（`bucket/fzf.json`・`zoxide.json`・`starship.json`・`eza.json`・`bat.json`。zoxide の 0.9.9 の定義は `f8683b6ce` の親）
- コード: [ScoopInstaller/Scoop](https://github.com/ScoopInstaller/Scoop)（v0.6.0。`lib/manifest.ps1` の `Find-HistoricalManifestInGit`・`generate_user_manifest`、`lib/install.ps1` の `env_add_path`・`env_set`・`persist_data`・`show_suggestions`・`test_running_process`・`prune_installed`、`lib/core.ps1` の `installed`、`lib/depends.ps1` の `Get-Dependency`、`lib/system.ps1` の `Add-Path`、`bin/scoop.ps1`、`libexec/scoop-install.ps1`・`scoop-update.ps1`（`Sync-Bucket`・`update`）・`scoop-hold.ps1`・`scoop-unhold.ps1`・`scoop-list.ps1`・`scoop-uninstall.ps1`、`CHANGELOG.md` の #6370・#6730）と [ScoopInstaller/Install](https://github.com/ScoopInstaller/Install)（`install.ps1`。git が無いときは、本体と main のバケットを zip で置く）
- コード: [ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide)（`templates/bash.txt` の v0.9.9・v0.10.0・`main`、`CHANGELOG.md`（`main`）、`src/db/mod.rs`、`.cargo/config.toml`、README の Windows の導入と `_ZO_DATA_DIR`）と、[issue #1259](https://github.com/ajeetdsouza/zoxide/issues/1259)・[PR #1260](https://github.com/ajeetdsouza/zoxide/pull/1260)・[Releases](https://github.com/ajeetdsouza/zoxide/releases)
- コード: [sharkdp/bat](https://github.com/sharkdp/bat)（v0.26.1 の `src/bin/bat/directories.rs`・`config.rs`）・[eza-community/eza](https://github.com/eza-community/eza)（v0.23.5 の `src/options/theme.rs`・`src/output/table.rs`・`src/fs/feature/git.rs`）・[junegunn/fzf](https://github.com/junegunn/fzf)（v0.74.4 の `CHANGELOG.md`・`src/util/util_windows.go`）・[starship/starship](https://github.com/starship/starship)（v1.26.0 の `src/context.rs`・`src/init/starship.ps1`・`.github/workflows/release.yml`）
- コード: [wezterm/wezterm](https://github.com/wezterm/wezterm)（`pty/src/cmdbuilder.rs` の `get_base_env`）と、自分用の設定の [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)（`bashrc`・`docs/install.md`・`docs/reference/readme.md` の「Windows 11 の Git Bash での違い」）

---

## VM での確認に伴う手順修正の根拠

- 「Windows Update」の手順 4・7: PSWindowsUpdate 2.2.1.5 は複数件の結果を 1 つの `Collection` として返す場合がある。`ForEach-Object { $_ }` で各更新を展開してから件数を数える。更新対象の Criteria と実際の適用コマンドは変えない。
- 「アプリを入れる」の手順 3〜5: 確認の [`winget list`](https://learn.microsoft.com/en-us/windows/package-manager/winget/list) も `--source winget` で導入元に絞る。source 未指定では `msstore` の初回の規約と地域情報の同意待ちになる場合がある。
- UniGet UI のユーザー向け [winget 定義](https://github.com/microsoft/winget-pkgs/blob/master/manifests/d/Devolutions/UniGetUI/2026.3.0/Devolutions.UniGetUI.installer.yaml)も `elevatesSelf` で、[インストーラー](https://github.com/Devolutions/UniGetUI/blob/v2026.3.0/InstallerExtras/CodeDependencies.iss)は Visual C++ Runtime などを必要に応じて導入する。共有 DLL の導入には[管理者権限が必要](https://learn.microsoft.com/en-us/cpp/windows/choosing-a-deployment-method?view=msvc-170)なため、ユーザー領域への導入でも管理者確認が出る場合がある。
- 「自動起動と標準アプリ」の手順 1 とロールバックの「表示と入力を戻す」の手順 8: `OneDriveSetup` は初回導入の項目で、対象へ正確な名前を追加した。`Run` の値・実行ファイルを削除せず、`RunOnce` と Active Setup も変えない。[Run と RunOnce](https://learn.microsoft.com/en-us/windows/win32/setupapi/run-and-runonce-registry-keys)と [OneDriveSetup を初回導入に使う例](https://learn.microsoft.com/en-us/troubleshoot/sharepoint/lists-and-libraries/cannot-open-onedrive-on-images-using-sysprep)を参照（後者は Windows 10 の Sysprep の例）。実アプリの次回起動の確認とは分けて扱う。
- 「PC 全体の設定」の手順 7: 確認には、隠れた電源設定も表示する `/qh` を使う。設定を書き込むコマンドは変えない。
- 「WSL の AlmaLinux 10 と自動サインイン」の手順 3・4: `WSL_UTF8` が出力側、`Console.OutputEncoding` がコンソールの読み取り側を指定する。Microsoft の [WSL 診断スクリプト](https://github.com/microsoft/WSL/blob/master/diagnostics/collect-wsl-logs.ps1)もこの 2 つを併用する。出力の可読性と WSL 2 の実起動の成否は別に判定する。

実施環境と再実行の結果は[検証記録](../verification/windows-setup.md#付録-windows-11-pro-の-vm-での導入検証2026-10-06)を参照。

---

## 統合前の参考資料: HackGen Console NF の Windows 11（もとは hackgen.md）

もとの `hackgen.md` の参考資料のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の参考資料](almalinux-setup.md#統合前の参考資料-hackgen-console-nfもとは-hackgenmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/windows-setup.md)の統合前の記録と同じ。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。前の項で開いた窓を使う） |
| Windows 11 で使う 2・3 | 「HackGen Console NF」の手順 1・2 |
| Windows 11 で使う 4（サインインし直す） | （なし。「WSL と再起動」の手順 2 の再起動で読み直す） |
| Windows 11 で使う 5 | 「再起動の後に確かめる」の手順 5 |
| Windows 11 の更新 1・2 | 「HackGen Console NF を上げる」の手順 1・2 |
| Windows 11 のロールバック 1〜3 | ロールバックの「HackGen Console NF を消す」の手順 1〜3 |

### HackGen Console NF: 補足

#### HackGen Console NF: Windows 11 で使う / 手順 2: 補足: 出た結果の意味

- 自分のユーザーの登録と `%LOCALAPPDATA%` のファイルが出たら、この節の手順で入れたもの（同じ節の手順 3 は何度貼ってもよい）
- `C:\Windows\Fonts` のファイルが出たら、PC 全体に入っていて、そのまま使える

#### HackGen Console NF: Windows 11 で使う / 手順 3: 補足: 中断したときと貼り直したとき

- `中断:` で止まったとき、取ってきたものは `%TEMP%\hackgen-setup` に残る。次に貼ったときに消して作り直す
- 何度貼ってもよいのは、同じファイルは置き直さないため

#### HackGen Console NF: Windows 11 の更新 / 手順 1: 補足: 版と sha256 を直す理由

- `$ver` と `$sha256` を直さなければ、固定した旧版を再び入れるだけで更新にはならない

#### HackGen Console NF: Windows 11 の更新 / 手順 2: 補足: 外してから入れ直す理由

- [Windows 11 のロールバック](../extra/windows-setup.md#hackgen-console-nf-を消す)の手順 1〜3 を先に行うのは、読み込まれているファイルは置き換えられないため

---

## 統合前の参考資料: OpenSSH サーバー（もとは windows-openssh-server.md）

もとの `windows-openssh-server.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/windows-setup.md)の統合前の記録と同じ。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | （なし。「PC 全体の設定」の手順 1 の管理者の窓を使う） |
| 実施手順 2（`$LAN_IF`） | （なし。「PC 全体の設定」の手順 2 の変数を使う） |
| 実施手順 3〜7 | 「OpenSSH サーバー」の手順 1〜5 |
| 実施手順 8・9 | 「SSH でログインを確かめる」の手順 3・4 |
| 公開鍵でもログインする（任意）の 1〜5 | OpenSSH サーバーに公開鍵でもログインする（任意）の 1〜5 |
| パスワード認証を切る（任意）の 1・2 | OpenSSH サーバーのパスワード認証を切る（任意）の 1・2 |
| 既定のシェルを Git Bash にする（任意）の 1〜3 | SSH の既定のシェルを Git Bash にする（任意）の 1〜3 |
| scoop のツールを SSH のセッションで使う（任意）の 1・2 | scoop のツールを SSH のセッションで使う（任意）の 1・2 |
| ロールバック 1・2 | ロールバックの「OpenSSH・Git for Windows・Firefox・WezTerm を外す」の手順 2・3 |
| ロールバック 3 | ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 5 |
| ロールバック 4 | ロールバックの「OpenSSH・Git for Windows・Firefox・WezTerm を外す」の手順 9 |

[検証記録](../verification/windows-setup.md#openssh-サーバー-参考資料から分離した記録)

### OpenSSH サーバー: 補足

#### OpenSSH サーバー: 実施手順 / 手順 1: 補足: Windows PowerShell 5.1 で開く理由

- PowerShell 7（`pwsh`）では、手順 3 が失敗する

#### OpenSSH サーバー: 実施手順 / 手順 2: 補足: 変数について

- `LAN_IF` は、インターネットにつながっている接続の名前（`イーサネット`、`Wi-Fi` など）
- 変数はその PowerShell の中だけで有効

#### OpenSSH サーバー: 実施手順 / 手順 3: 補足: 入るものと、PowerShell 7 で失敗すること

- 入るのは Windows のオプション機能「OpenSSH サーバー」（設定アプリの「システム」→「オプション機能」と同じもの）。`C:\Windows\System32\OpenSSH\sshd.exe`と、サービス `sshd`、受信の規則 `OpenSSH-Server-In-TCP` ができる
- クライアント（`ssh.exe` など）は Windows 11 に最初から入っていて、この手順では変わらない
- 先頭の `if` は、PowerShell 7（`PSEdition` が `Core`）で貼ったときに何もしないで止めるためのもの
- 機能は Windows Update から取ってくるので、数分かかる

#### OpenSSH サーバー: 実施手順 / 手順 4: 補足: 最初の起動で作られるもの

- 最初に起動したときに、`C:\ProgramData\ssh` にホスト鍵 3 組（RSA・ECDSA・ED25519）と `sshd_config`、`logs` ができる。
- [既定のシェルを Git Bash にする（任意）](../windows-setup.md#ssh-の既定のシェルを-git-bash-にする任意)では、レジストリの `HKLM:\SOFTWARE\OpenSSH` に値を足す

#### OpenSSH サーバー: 実施手順 / 手順 6: 補足: 既定でも有効なのに書く理由と、置き換える理由

- パスワード認証は既定で有効。この手順はそれを明示的な行にするので、[パスワード認証を切る（任意）](../windows-setup.md#openssh-サーバーのパスワード認証を切る任意)で `no` にした PC も、この手順を貼れば戻る
- `sshd_config` の末尾は `Match Group administrators` のブロックなので、末尾に足した行はそのブロックの中の設定になる。そこで、既定の行を置き換える
- `sshd -t` は設定の検査だけをする（誤りが無ければ何も出さない）。誤りがあれば再起動しないので、動いている sshd は古い設定のまま残る
- Windows PowerShell 5.1 の `Set-Content -Encoding ascii` は BOM 無しの ASCII、CRLF で書く
- Microsoft の文書は、Windows の OpenSSH の認証の方法は `password` と `publickey` だけとしている
- 行を置き換えるので、何度貼っても結果は同じ

#### OpenSSH サーバー: 実施手順 / 手順 7: 補足: ユーザー名

- Microsoft アカウントでも、ユーザー名はメールアドレスではなく、`C:\Users\` の下のフォルダーの名前

#### OpenSSH サーバー: 実施手順 / 手順 8: 補足: 変数について

- 変数はそのシェルの中だけで有効

#### OpenSSH サーバー: 公開鍵でもログインする（任意） / 手順 1: 補足: 鍵の種類とパスフレーズ

- ED25519 は Windows と AlmaLinux 10 の OpenSSH のどちらも扱え、鍵が短く、この節の手順 3 で 1 行のまま貼れる
- パスフレーズは、秘密鍵のファイルが漏れたときの守り。空にすると、この節の手順 5 と[パスワード認証を切る（任意）](../windows-setup.md#openssh-サーバーのパスワード認証を切る任意)の手順 2 で聞かれなくなる。後から付けるなら `ssh-keygen -p -f ~/.ssh/id_ed25519`
- 秘密鍵（`~/.ssh/id_ed25519`）はクライアントから出さない。Windows に渡すのは、この節の手順 2 の公開鍵だけ

#### OpenSSH サーバー: 公開鍵でもログインする（任意） / 手順 3: 補足: 読み戻し

- `$PUBKEY` が空、または `ssh-` などで始まらなければ、この節の手順 4 は何もしないで止まる

#### OpenSSH サーバー: 公開鍵でもログインする（任意） / 手順 4: 補足: クライアントを足す

- この節の手順 4 を貼り直すと、`administrators_authorized_keys` に行が足される

#### OpenSSH サーバー: 公開鍵でもログインする（任意） / 手順 5: 補足: 鍵で入ったときのログ

- `-o PasswordAuthentication=no` は、鍵が通らなかったときにパスワードへ移らず、そこで終わらせるため

#### OpenSSH サーバー: パスワード認証を切る（任意） / 手順 1: 補足: 切る前と後

- 行を置き換える理由と `sshd -t` は、[手順 6](../windows-setup.md#openssh-サーバー) の補足と同じ
- Microsoft の文書は、Windows の OpenSSH の認証の方法は `password` と `publickey` だけで、`KbdInteractiveAuthentication` は使えないとしている
- 行を置き換えるので、何度貼っても結果は同じ

#### OpenSSH サーバー: 既定のシェルを Git Bash にする（任意） / 手順 1: 補足: DefaultShell

- `DefaultShell` は Windows の sshd だけの設定で、`sshd_config` ではなくレジストリに置く。この PC の全ユーザーの SSH のセッションに効く
- `bin\bash.exe` は、Git の `usr\bin\bash.exe` を `MSYSTEM=MINGW64` と `PATH` を整えて起動する入口。
- sshd の再起動は要らない。次のログインから変わる

#### OpenSSH サーバー: 既定のシェルを Git Bash にする（任意） / 手順 2: 補足: パスワードを 2 回聞かれる理由

- 鍵を登録していなければ 2 回聞かれるのは、`ssh` が 2 つあるため

#### OpenSSH サーバー: 既定のシェルを Git Bash にする（任意） / 手順 3: 補足: 戻る時期

- `DefaultShell` を消すと、次のログインから cmd.exe に戻る

#### OpenSSH サーバー: scoop のツールを SSH のセッションで使う（任意） / 手順 1: 補足: 貼り直し

- 作り直すものが無ければ何も出ないので、何度貼ってもよい

#### OpenSSH サーバー: 参照

[検証記録](../verification/windows-setup.md#openssh-サーバー-参考資料から分離した記録)

---

## 統合前の参考資料: Git の Windows 11（もとは git.md）

もとの `git.md` の参考資料のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の参考資料](almalinux-setup.md#統合前の参考資料-gitもとは-gitmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/windows-setup.md)の統合前の記録と同じ。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で Git for Windows を入れるの 1 | （なし。「PC 全体の設定」の手順 1 の管理者の窓を使う） |
| Windows 11 で Git for Windows を入れるの 2・3 | 「Git for Windows」の手順 1・2 |
| Windows 11 で Git for Windows を入れるの 4 | （なし。再起動の後に開く窓を使う） |
| Windows 11 で Git for Windows を入れるの 5 | 「Git Bash と WezTerm の設定」の手順 1 |
| Windows 11 で Git for Windows を入れるの 6（Git Bash で実施手順） | 「Git Bash と WezTerm の設定」の手順 2・3 |
| 更新 2 | 「Git for Windows・Firefox・WezTerm を上げる」の手順 2 |
| ロールバック 1〜5（Git Bash） | ロールバックの「Git Bash の設定を戻す」の手順 2〜6 |
| ロールバック 6 | ロールバックの「OpenSSH・Git for Windows・Firefox・WezTerm を外す」の手順 4 |

### Git: 補足

#### Git: 実施手順 / 手順 3: 補足: Windows の system の行

- Windows で出る `system` の行（インストーラが書いたもの）より、手順 5・6 で書く `global` の値が優先される

#### Git: Windows 11 で Git for Windows を入れる / 手順 2: 補足: 確かめていること

- Git for Windows を PC 全体に入れると、`git` は `C:\Program Files\Git\cmd\git.exe`、Git Bash は `C:\Program Files\Git\git-bash.exe`（スタートメニューの Git Bash）と `C:\Program Files\Git\bin\bash.exe`（ほかのプログラムから bash を起動する入口）になる
- `bin\bash.exe` は、[Windows の OpenSSH サーバーの既定のシェルを Git Bash にする（任意）](../windows-setup.md#ssh-の既定のシェルを-git-bash-にする任意)が決め打ちにしている。Claude Code（Windows）の公式の文書も、Git Bash の場所の例にこのパスを挙げる
- 管理者の権限が無いと、インストーラは入れる先の既定を `%LOCALAPPDATA%\Programs\Git` に変える（上流の `install.iss`。画面で入れるとき）。その形では、上の 2 つのパスが無い
- `--source winget` を付けた `winget list` は、入っているアプリを winget のカタログと照合し、確認に要らない Microsoft Store のソースの初回同意を避ける
- `--accept-source-agreements` は、winget を初めて使う PC で出るソースの同意の問いに答えるため（続けて貼った行が答えとして食われないように）
- `…\AppData\Local\Programs\Git\cmd\git.exe` の Git for Windows を外してから始めるのは、ほかの手順書が `C:\Program Files\Git` を前提にしているため

#### Git: Windows 11 で Git for Windows を入れる / 手順 3: 補足: UAC

- 管理者の窓から動かすので、UAC の確認も出ないはず

#### Git: Windows 11 で Git for Windows を入れる / 手順 4: 補足: 開き直す理由

- 同じ節の手順 3 で PC 全体の `PATH` に足された `C:\Program Files\Git\cmd` は、開いていた PowerShell には入らない

#### Git: Windows 11 で Git for Windows を入れる / 手順 5: 補足: PATH と、ほかの git

- `PATH` に足されるのは `C:\Program Files\Git\cmd`（`git.exe`・`git-gui.exe` など）だけ。`bash`・`ssh`・`ls` などは足されないので、PowerShell の `ssh` は Windows のものが使われる
- Windows の `PATH` は、PC 全体の値の後ろに自分のユーザーの値が続く。scoop の git（`…\scoop\shims\git.exe`。自分のユーザーの `PATH`）があっても、新しく開いた窓では Git for Windows の `git` が先に見つかる
- scoop は、scoop の git が入っていなければ `PATH` の `git` を使う（scoop のソースの `Get-HelperPath`）。そのため、`scoop update` と `scoop bucket add` は Git for Windows の `git` で動く。scoop の git が入っていると、scoop はそちらを使う
- Claude Code（Windows）は、Git for Windows があれば Bash のツールを Git Bash で動かし、無ければ PowerShell のツールだけを使う（公式の setup の文書）

#### Git: Windows 11 で Git for Windows を入れる / 手順 5: 補足: 版

- `git version` の版は、実行した日の最新

---

## 統合前の参考資料: Firefox の Windows 11（もとは firefox.md）

もとの `firefox.md` の参考資料のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の参考資料](almalinux-setup.md#統合前の参考資料-firefoxもとは-firefoxmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/windows-setup.md)の統合前の記録と同じ。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。「PC 全体の設定」の手順 1 の管理者の窓を使う） |
| Windows 11 で使う 2〜5 | 「Firefox」の手順 1〜4 |
| Windows 11 の更新 1・2 | 「Git for Windows・Firefox・WezTerm を上げる」の手順 3・4 |
| Windows 11 のロールバック 1〜3 | ロールバックの「OpenSSH・Git for Windows・Firefox・WezTerm を外す」の手順 5〜7 |

### Firefox: 補足

#### Firefox: Windows 11 で使う / 手順 2: 補足: 入れたものがあるとき

- `Mozilla Firefox (x64 ja)` が `C:\Program Files\Mozilla Firefox` で出たときも、同じ節の手順 3 を貼れば、新しい版があれば上がる

#### Firefox: Windows 11 で使う / 手順 3: 補足: 入れ方と版

- winget はインストーラの sha256 を確かめてから、画面を出さずに入れる。管理者の PowerShell なので、管理者の確認（UAC）は出ない
- `winget list` に出る版は、実行した日の最新

#### Firefox: Windows 11 で使う / 手順 4: 補足: Windows では AAC と H.264 のために何も足さない理由

[この節の検証記録](../verification/windows-setup.md#firefox-windows-11-で使う--手順-4-補足-windows-では-aac-と-h264-のために何も足さない理由)

- Firefox の Windows 版は、H.264 を `CLSID_CMSH264DecoderMFT`、AAC を `CLSID_CMSAACDecMFT` で復号する。どちらも Windows の Media Foundation に入っている復号器（Firefox のソースの `dom/media/platforms/wmf/WMFDecoderModule.cpp`）
- 同梱の FFmpeg（`mozavcodec.dll`）のソフトウェアの復号器に、AAC と H.264 は無い（ソースの `media/ffvpx/libavcodec/codec_list.c`。あるのは Android の MediaCodec を使うものだけ）
  - Linux では、そこを OS の FFmpeg で補う。そのため、AlmaLinux 10 では[実施手順](../almalinux-setup.md#firefox)の手順 8〜11 が要る（[選択した方針](almalinux-setup.md#firefox-選択した方針)）
- MDN も、Firefox は AVC（H.264）と AAC を OS の復号器に頼ると書いている

- N エディションの Windows（メディアの機能が入っていない）では、Microsoft の Media Feature Pack が必要になる可能性がある

#### Firefox: Windows 11 で使う / 手順 4: 補足: 言語パック

- 日本語版なので、言語パックは要らない

#### Firefox: Windows 11 で使う / 手順 5: 補足: コマンドで変えない理由

- Windows は既定のブラウザーを、`HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\<プロトコル>\UserChoice` にハッシュ付きで記録する。今の Windows 11 では、User Choice Protection Driver（UCPD）が `http`・`https` の `UserChoice` の書き換えを止める
- Firefox も、まず自分で `UserChoice` を書こうとし、できなければ Windows の設定の「既定に設定」の画面を開く（Mozilla の Set Default の文書）。そのため、本書は初めから設定の画面で行う
- 確かめを Win+R から開くのは、管理者の PowerShell から URL を開くと、Firefox が管理者の権限で起動するため
- Claude Code の `/login` は、既定のブラウザーでログインのページを開く。[Windows 11 の初期設定](../windows-setup.md)の後に通す順で、Claude Code より先にこの手順を行うのはそのため

#### Firefox: Windows 11 の更新 / 手順 1: 補足: 新しい版が無いとき

- winget に新しい版が無いのは、Firefox が自分で先に上げているからのこともある

#### Firefox: Windows 11 の更新 / 手順 2: 補足: winget での更新

[この節の検証記録](../verification/windows-setup.md#firefox-windows-11-の更新--手順-2-補足-winget-での更新)

- winget の定義の `UpgradeBehavior` は `install`。今の Firefox を消さずに、同じ場所へ新しい版のインストーラを重ねて入れる。プロファイルと既定のブラウザーの設定はそのまま
- winget が渡す `/PreventRebootRequired=true` は、使用中のファイルがあっても再起動が要る処理をしないスイッチ。Mozilla の文書は、動いている Firefox に重ねて入れるときにこれを付けると、入れ替えが途中で終わることがあると書いている
- winget の定義は、Mozilla が新しい版を出してから、winget-pkgs に定義が足されたときに上がる。Firefox 自身の更新の方が先に上がることもある

#### Firefox: Windows 11 のロールバック / 手順 1: 補足: 窓が出る理由と、アンインストーラが消すもの

- winget は、NSIS のインストーラで入れたものを、アンインストールの登録の `QuietUninstallString`（画面を出さずに消すコマンド）で消し、それが無ければ `UninstallString` で消す（winget のソースの `UninstallFlow.cpp`）
- Firefox が書くのは `UninstallString`（`C:\Program Files\Mozilla Firefox\uninstall\helper.exe`）だけなので、ふだんのアンインストールと同じ窓が出る（Firefox のソースの `shared.nsh`）
- アンインストーラは、Firefox のタスク（Default Browser Agent と Background Update）を消し、ほかに使う Mozilla のアプリ（Thunderbird など）が無ければ Mozilla Maintenance Service も外す（Firefox のソースの `uninstaller.nsi`）
- 入れ直したときのリフレッシュの勧めは、アンインストーラが `HKCU\Software\Mozilla\Firefox` に残す `Uninstalled-release` の値による（同じソース）

---

## 統合前の参考資料: WezTerm の Windows 11（もとは wezterm-nightly.md）

もとの `wezterm-nightly.md` の参考資料のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の参考資料](almalinux-setup.md#統合前の参考資料-weztermもとは-wezterm-nightlymd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/windows-setup.md)の統合前の記録と同じ。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。「PC 全体の設定」の手順 1 の管理者の窓を使う） |
| Windows 11 で使う 2〜6 | 「WezTerm」の手順 1〜5 |
| Windows 11 の更新 1〜4 | 「Git for Windows・Firefox・WezTerm を上げる」の手順 1・5〜7 |
| Windows 11 のロールバック 1 | ロールバックの「OpenSSH・Git for Windows・Firefox・WezTerm を外す」の手順 8 |

### WezTerm: 補足

#### WezTerm: Windows 11 で使う / 手順 1: 補足: WezTerm の中の PowerShell を使わない理由

- WezTerm が動いていると、同じ節の手順 4 が止まる

#### WezTerm: Windows 11 で使う / 手順 2: 補足: 確かめる値の意味

- `Version` が `20240203-110809-5046fc22` なら stable（winget の `wez.wezterm` など）。同じ登録なので、nightly で上書きされる
- ほかの方法で入れた WezTerm を外すのは、混ざらないようにするため

#### WezTerm: Windows 11 で使う / 手順 4: 補足: 版と、中断・貼り直し

- 最後に出る `wezterm <版>` の版は、実行した日の nightly
- `中断:` で止まったとき、取ってきたものとログは `%TEMP%\wezterm-setup` に残る。次に貼ったときに消して作り直す
- 何度貼ってもよいのは、同じ場所に上書きするため

#### WezTerm: Windows 11 で使う / 手順 6: 補足: 右クリックのメニュー

- エクスプローラーでフォルダーを右クリックすると「Open WezTerm here」がある（Windows 11 の新しいメニューでは「その他のオプションを確認」の中）

#### WezTerm: Windows 11 の更新 / 手順 2: 補足: 窓を閉じる理由

- WezTerm が動いていると、同じ節の手順 3（[Windows 11 で使う](../windows-setup.md#wezterm)の手順 4 のブロック）が止まる

#### WezTerm: Windows 11 のロールバック / 手順 1: 補足: アンインストーラの動き

- アンインストーラは `C:\Program Files\WezTerm\unins000.exe`（Inno Setup）。場所は登録の `UninstallString` から読む
- 引数の `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART` は、Inno Setup のアンインストーラの標準の引数（確認の窓も完了の窓も出さない）
- アンインストーラは自分の写しを `%TEMP%` に作り、写しの方が消す。終了コードが返った時点では片付けがまだ続いていることがある（Inno Setup の文書）ので、登録とフォルダーが消えるまで 60 秒まで待つ
- 消えるもの: インストーラが置いたファイルとフォルダー、スタートメニューの「WezTerm」、右クリックの「Open WezTerm here」、PC 全体の `PATH` の `C:\Program Files\WezTerm`、アンインストールの登録
- 残るもの: 設定ファイルと、WezTerm が作る作業用のフォルダー（ソースでは `%USERPROFILE%\.local\share\wezterm`・`%APPDATA%\wezterm`・`%LOCALAPPDATA%\wezterm`。作られていれば）

---

## 統合前の参考資料: git-delta の Windows 11（もとは git-delta.md）

もとの `git-delta.md` の参考資料のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の参考資料](almalinux-setup.md#統合前の参考資料-git-deltaもとは-git-deltamd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/windows-setup.md)の統合前の記録と同じ。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。前の項で開いた窓を使う） |
| Windows 11 で使う 2〜5 | 「git-delta」の手順 1〜4 |
| Windows 11 の更新 1 | 「scoop・winget・WSL を上げる」の手順 1・2 |
| Windows 11 のロールバック 1・3 | ロールバックの「Git の道具を消す」の手順 3・4 |
| Windows 11 のロールバック 2 | ロールバックの「Git Bash の設定を戻す」の手順 3 |

### git-delta: 補足

#### git-delta: Windows 11 で使う / 手順 2: 補足: VC++ ランタイム

- scoop の delta は、上流の `x86_64-pc-windows-msvc` のビルドで、`delta.exe` のインポート表に `VCRUNTIME140.dll` がある（[検証記録の付録](../verification/windows-setup.md#git-delta-付録-windows-11-の配布物と資料の調査2026-10-08)）。無い PC では起動しない
- scoop の `delta.json` は VC++ ランタイムを入れない（`depends` も `suggest` も無い）。winget の `dandavison.delta` は、依存として `Microsoft.VCRedist.2015+.x64` を持つ
- 入れ方は新しく書かず、[wezterm-nightly.md の Windows 11 で使う](../windows-setup.md#wezterm)の手順 3（管理者の窓の winget。PC 全体）を指す。手順書の並びでは WezTerm を先に入れるので、ふつうはもう入っている
  - 設定の「インストールされているアプリ」では「Microsoft Visual C++ v14 Redistributable (x64)」と出る（前の版で入れた PC では「… 2015-2022 …」）
  - extras のバケットの `vcredist2022`（scoop）でも入るが、extras を足すことになり、入れるときに UAC の確認も出るので採らない
- 同じ前提は bat・Neovim・yazi にもある。eza（windows-gnu のビルド）と starship・zoxide・fd（CRT を静的にリンク）、gh（Go）には無い

#### git-delta: Windows 11 で使う / 手順 2: 補足: 確かめる値の意味

- `Delta` が空なら、delta は入っていない。`C:\Users\<WIN_USER>\scoop\shims\delta.exe` だけなら、もう scoop で入っている（同じ節の手順 3 の `scoop install` は何も変えない）
- ほかの方法で入れた delta を外すのは、混ざらないようにするため

#### git-delta: Windows 11 で使う / 手順 3: 補足: scoop の名前と版

- scoop の名前は `delta`（Homebrew の formula の `git-delta` ではない）
- `'delta' (<版>) was installed successfully!` の版は、実行した日の最新

#### git-delta: Windows 11 で使う / 手順 4: 補足: 実施手順の手順 1・3 を Git Bash で貼る

- 手順 1・3 のブロックは bash と git だけを使うので、Git Bash にそのまま貼れる。PowerShell 向けに書き分けない（[git.md](../almalinux-setup.md#git) と同じ考え方）
- `git config --global` が書くのは `C:\Users\<WIN_USER>\.gitconfig`（Git Bash の `HOME`）。Git Bash・PowerShell 7・cmd の `git config --global --list --show-origin` が同じファイルを示すことは、[git.md の検証記録](../verification/windows-setup.md#git-付録-windows-11-の-git-bash-での検証記録2026-09-30)で確かめてある
- 手順 2（`brew install`）と手順 4（`brew list` を含む）は指さない。入れることと版・場所は、Windows 11 の節の手順 3 で PowerShell から確かめる
- 手順 3 は `merge.conflictstyle zdiff3` も書く。[git.md](../almalinux-setup.md#git) の手順 6 と同じ値なので、どちらを先に通してもよい（AlmaLinux 10 と同じ）
- 手順 1 の変数はそのタブの中だけで有効なので、手順 3 も同じタブに貼る

#### git-delta: Windows 11 で使う / 手順 5: 補足: 変更のあるリポジトリが無いとき

- `git -C ~/.config/bash show` が出すのは、[共通の bash 設定](../../README.md#共通の-bash-設定を先に入れる)の clone の、最後のコミットの差分

#### git-delta: Windows 11 で使う / 手順 5: 補足: ページャの less と PowerShell の git

- git は `core.pager` の `delta` を PATH から探して起動する（scoop の shim の `~\scoop\shims\delta.exe`）
- delta 0.20.1 のページャは、`delta.pager`（`--pager`）・`DELTA_PAGER`・`BAT_PAGER`・`PAGER` の順に決まり、どれも無ければ `less`。そのコマンドを PATH から探し、見つからなければ、ページャを使わずに標準出力へ書く（ソースの `src/utils/bat/output.rs` と `src/env.rs`）
- **Git Bash** では、PATH の先頭が Git の `/usr/bin` なので、delta は Git for Windows の `usr\bin\less.exe` を使う
- **PowerShell・cmd** の PATH には Git の `cmd` しか無い（Git for Windows の既定の `Path Option=Cmd`）。それでも、そこの `git.exe`（Git for Windows の git-wrapper）は、`mingw64\bin`・`usr\bin`・`%HOME%\bin` を PATH の先頭に足してから本体の `mingw64\bin\git.exe` を動かす（git-wrapper のソースの `setup_environment`。`cmd\git.exe` は `git.res` の版の情報だけを持ち、PATH を絞る `MINIMAL_PATH=1` の文字列のリソースが無い）。その PATH を受け継ぐ delta も、Git for Windows の less を使う
- 上流の文書は、Windows では新しい less が要り、古い `less.exe` を使うと色が崩れたり変な文字が出たりすると書いている。Git for Windows の less は MSYS2 の今の版なので、これに当たらないはず（版は確かめていない）
- **scoop の less は入れなかった**: 設計の段階では、PowerShell から git を使うときだけ scoop の less（main の `less.json`。上流の文書が勧める `jftuga/less-Windows` の配布物）を入れる任意の手順を考えた。上のとおり、git が起動する delta には、Git Bash でも PowerShell でも Git の `usr\bin` が scoop の shims より前に来るので、入れても使われない（`DELTA_PAGER` か `delta.pager` で場所を指したときと、PowerShell で delta を直に動かしたときだけ使われる）
- PowerShell で delta を直に動かす（`git diff | delta` など）と、PATH に less が無いので、delta はページャを使わずに出す（上の `output.rs` の動き）
- `delta.navigate`（手順 1 の `DELTA_NAVIGATE`）が `true` だと、delta は less の検索履歴の写しを `%LOCALAPPDATA%\delta\delta.lesshst` に作り、`LESSHISTFILE` で less に渡す（ソースの `src/features/navigate.rs`。Linux では `~/.local/share/delta/lesshst`）。Windows で `n` / `N` が効くかは確かめていない
- PowerShell・cmd で打つ `git diff` も、同じ `~/.gitconfig` を読んで delta を通る（[注意点](../extra/almalinux-setup.md#注意点)）
- どれも、ソースを読んだだけで、Windows では確かめていない（[検証記録](../verification/windows-setup.md#git-delta-windows-11-で使う-検証状況の記録)）

#### git-delta: Windows 11 では: 選択した方針

[Windows 11 で使う](../windows-setup.md#git-delta)の理由。**Windows の実機では未検証**（[検証記録](../verification/windows-setup.md#git-delta-windows-11-で使う-検証状況の記録)）。

- **scoop の main のバケットで入れた**（winget は採らない）
  - [README の導入の基盤](../../README.md#導入の基盤)の「CLI ツールは scoop」と同じ。管理者が要らず、[Windows 11 の初期設定の更新](../windows-setup.md#更新)の `scoop update *` と UniGet UI で上がる
  - winget の `dandavison.delta` 0.20.1 も、同じ上流の zip（portable）を同じ sha256 で入れる。違うのは入れ方と上げ方と、VC++ ランタイムを依存として入れるかだけ
  - 上流の zip を手で置く形や `cargo install git-delta`（Rust が要る）は、更新が手作業になる
  - scoop の定義は x64 だけ。arm64 の Windows 11 では、scoop はこの x64 の版を入れる（Scoop のソースの `Get-SupportedArchitecture`。確かめていない）
  - 版は固定しない（`scoop hold` しない）。scoop で止めるのは、Git Bash で移動先を記録しない 0.10.0 を避ける zoxide だけ（[Windows 11 の初期設定のシェルのツールを入れる（任意）](../windows-setup.md#シェルのツールを入れる)）
- **設定は git の `~/.gitconfig` だけ**: delta は自分の設定ファイルを持たず、`[delta]` セクションを読む。`XDG_CONFIG_HOME` は関係しないので設定しない。Git Bash・PowerShell・cmd の git が同じファイルを読む（[Windows 11 で使う / 手順 4 の補足](#git-delta-windows-11-で使う--手順-4-補足-実施手順の手順-13-を-git-bash-で貼る)）
- **シェルとの組み込み方**
  - delta はどのシェルにも初期化の行が要らない。git が `core.pager` と `interactive.diffFilter` で呼ぶので、`~/.gitconfig` を書けば、どのシェルの git にも効く
  - **Git Bash が主**: WezTerm の自分用の設定の `default_prog` は Git Bash（`bash.exe -i -l`）。git の設定は Git Bash で[実施手順](../almalinux-setup.md#git-delta)の手順 1・3 を貼って書く（AlmaLinux 10 と同じブロック）。共通の bash 設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）は delta を扱わず、`PAGER` なども設定しない
  - **PowerShell 7 のプロファイルには何も足さない**。[Windows 11 の初期設定の PowerShell 7 のプロファイルを設定する（任意）](../windows-setup.md#powershell-7-のプロファイルを設定する任意)が読むのは starship と zoxide だけ
  - **Windows PowerShell 5.1 のプロファイルにも足さない**。手順書を貼る窓のプロファイルは、Windows 11 の初期設定の「貼り付けの設定」の手順 4 の 1 行のまま
  - **WSL の AlmaLinux 10 は Linux のホストとして扱う**。WSL の git は WSL の中の `~/.gitconfig` を読むので、[実施手順](../almalinux-setup.md#git-delta)を WSL の中で通す
- **VC++ ランタイムは前提にした**: [Windows 11 で使う / 手順 2 の補足](#git-delta-windows-11-で使う--手順-2-補足-vc-ランタイム)
- **scoop の less は入れない**: [Windows 11 で使う / 手順 5 の補足](#git-delta-windows-11-で使う--手順-5-補足-ページャの-less-と-powershell-の-git)
- **lazygit**: 自分用の lazygit の設定（[ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit)）は、`git.diffRenderers` で `delta --no-gitconfig …` を呼ぶ。`~/.gitconfig` の `[delta]` を読まないので、この文書の変数は lazygit の表示に効かない。Windows の lazygit は描画のコマンドを cmd.exe で動かすので、単一引用符を使わない（その README の「Windows で使う場合」）。この文書の任意節の yaml は引用符を使わない
- **ロールバックは、git の設定を先に外す**: scoop の delta を先に消すと、`core.pager` が残って、git が delta を起動できなくなる。[Windows 11 の初期設定のロールバックの「アプリと貼り付けの設定を外す」](../extra/windows-setup.md#アプリと貼り付けの設定を外す)の手順 4（scoop ごと外す）も `~/.gitconfig` は変えないので、その前に外す
- **Git Bash は WezTerm のタブで確かめる**: 自分用の設定で Git Bash が開く。スタートメニューの「Git Bash」（mintty）でも同じ `~/.gitconfig` を読むはずだが、確かめていない
- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた

---

## 統合前の参考資料: GitHub CLI の Windows 11（もとは gh.md）

もとの `gh.md` の参考資料のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の参考資料](almalinux-setup.md#統合前の参考資料-github-cliもとは-ghmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/windows-setup.md)の統合前の記録と同じ。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。前の項で開いた窓を使う） |
| Windows 11 で使う 2〜6 | 「GitHub CLI」の手順 1〜5 |
| Windows 11 の更新 1 | 「scoop・winget・WSL を上げる」の手順 1・2 |
| Windows 11 のロールバック 1〜6 | ロールバックの「Git の道具を消す」の手順 5〜10 |

### GitHub CLI: 補足

#### GitHub CLI: Windows 11 で使う / 手順 2: 補足: 確かめる値の意味

- `GitCred` の `credential.helper manager` は、Git for Windows のインストーラの既定の Git Credential Manager
- `GitCred` に `auth git-credential` で終わる行があれば、前に gh を Git の資格情報のヘルパーにしてある（`gh auth setup-git` など）。同じ節の手順 4 で Git の認証は聞かれない
- `GitCred` が空なのは、Git の資格情報のヘルパーが無いこと。同じ節の手順 4 で `Y` と答えると、gh が `~/.gitconfig` に自分をヘルパーとして書く
- `Gh` が空なら、gh は入っていない。`C:\Users\<WIN_USER>\scoop\shims\gh.exe` だけなら、もう scoop で入っている（同じ節の手順 3 の `scoop install` は何も変えない）
- ほかの方法で入れた gh を外すのは、混ざらないようにするため。外してもログインと設定は残り、scoop の gh も同じ場所を読む

#### GitHub CLI: Windows 11 で使う / 手順 3: 補足: 版

- `'gh' (<版>) was installed successfully!` の版は、実行した日の最新

#### GitHub CLI: Windows 11 で使う / 手順 4: 補足: Git の認証に n と答える理由

gh 2.102.0 のソースを読んで決めた（[検証記録の付録](../verification/windows-setup.md#github-cli-付録-windows-11-の節の資料と-linux-での確認2026-10-08)）。**Windows では確かめていない**。

- **問いが出る条件**: `gh auth login` で HTTPS を選ぶと、github.com の Git の資格情報のヘルパーが gh でなければ、`Authenticate Git with your GitHub credentials?`（既定は Yes）を聞く
  - ヘルパーは `credential.https://github.com.helper`、無ければ `credential.helper` を、スコープを問わずに読む
  - Git for Windows は、インストーラの既定の選択で `system`（`C:\Program Files\Git\etc\gitconfig`）に `credential.helper=manager`（Git Credential Manager）を書く（[git.md の検証記録](../verification/almalinux-setup.md#git-実施手順--手順-3-補足-設定の-3-つの場所)）。そのため、[Windows 11 の初期設定](../windows-setup.md)の順に通した PC では、この問いが出る
- **Yes と答えたとき**（ソースからの推論）
  - ヘルパーがある（Git for Windows の既定）: `~/.gitconfig` は変えない。`git credential reject` で github.com の資格情報を消してから、`git credential approve` で gh のトークンを Git Credential Manager に入れる。以後、git の HTTPS も gh のトークン（GitHub CLI の OAuth アプリ。`workflow` の権限も付く）で GitHub につなぐ
  - ヘルパーが無い: `~/.gitconfig` の `credential.https://github.com.helper` と `credential.https://gist.github.com.helper` に、空の値（ほかのヘルパーを切る）と `!<gh の場所> auth git-credential` を書く。`gh auth setup-git` と同じ
- **No を選んだ理由**
  - git の HTTPS の認証は、Git for Windows の Git Credential Manager が自分のサインイン（Git Credential Manager の OAuth アプリ）で行う。gh と git のトークンが別になるので、`gh auth logout`・GitHub CLI の認可の取り消し・gh を消すことが、git の push に効かない
  - Yes にすると、gh のトークンが Git Credential Manager にも残る。`gh auth logout` は gh 自身の置き場所しか消さないので、ロールバックに 1 手順増える（[Windows 11 のロールバック](../extra/windows-setup.md#git-の道具を消す)の手順 4）
  - `~/.gitconfig` に gh の場所を書かない。書くと、scoop を外した後も git がその場所の gh を呼ぶ
- **Git の資格情報のヘルパーが無い PC**（[Windows 11 で使う](../windows-setup.md#github-cli)の手順 2 の `GitCred` が空）では、Yes でよい。git の HTTPS の認証を gh に任せることになる（外すのは[Windows 11 のロールバック](../extra/windows-setup.md#git-の道具を消す)の手順 3）
- **gh が書く自分の場所**: 環境変数 `GH_PATH` が無ければ、`PATH` の上の同じ名前のファイルが自分自身（かそのシンボリックリンク）ならそれ、違えば自分の実行ファイルの場所を書く（`internal/ghcmd/cmd.go`）
  - scoop の shim（`~\scoop\shims\gh.exe`）は別の実行ファイルなので、`C:\Users\<WIN_USER>\scoop\apps\gh\current\bin\gh.exe` になるはず（推論）。`current` は scoop の更新の後も同じ場所を指す
  - SSH のセッションの git からその場所を呼ぶと、scoop の `current` のジャンクションが [windows-openssh-server.md の任意節](../windows-setup.md#scoop-のツールを-ssh-のセッションで使う任意)の制限に当たるはず（確かめていない）

#### GitHub CLI: Windows 11 で使う / 手順 4: 補足: ワンタイムコード

- gh の既定では、ワンタイムコードはクリップボードにも入る

#### GitHub CLI: Windows 11 で使う / 手順 6: 補足: トークンと設定の置き場所

ソースから（gh 2.102.0、go-gh 2.16.1、go-keyring 0.2.8）。**Windows では確かめていない**。

| もの | Windows 11 の場所 | AlmaLinux 10 の場所 |
|---|---|---|
| トークン | 資格情報マネージャーの汎用資格情報 `gh:github.com:<GITHUB_USER>` と、今のアカウントの写しの `gh:github.com:`（名前はソースからの推論） | OS の資格情報ストア |
| トークン（ストアを使えないとき） | `%APPDATA%\GitHub CLI\hosts.yml`（平文） | `~/.config/gh/hosts.yml`（平文） |
| 設定（`config.yml`・`hosts.yml`） | `%APPDATA%\GitHub CLI` | `~/.config/gh` |
| 状態・拡張機能・キャッシュ | `%LOCALAPPDATA%\GitHub CLI` | `~/.local/state/gh`・`~/.local/share/gh`・`~/.cache/gh` |

- 設定の場所は、環境変数 `GH_CONFIG_DIR`、次に `XDG_CONFIG_HOME`（`%XDG_CONFIG_HOME%\gh`）があれば、そちらが先になる（go-gh の `ConfigDir`）
- `gh auth status` の `(keyring)` は、トークンが資格情報マネージャーにあること。平文のときは `hosts.yml` の場所が出る
- Git Credential Manager が git のために置く資格情報（`git:https://github.com` の名前になるはず）は、gh の項目とは別

#### GitHub CLI: Windows 11 では: 選択した方針

[Windows 11 で使う](../windows-setup.md#github-cli)の理由。**Windows の実機では未検証**（[検証記録](../verification/windows-setup.md#github-cli-windows-11-で使う-検証状況の記録)）。

- **scoop の main のバケットの `gh`**: [README の導入の基盤](../../README.md#導入の基盤)の「CLI ツールは scoop」に合わせた
  - 管理者の権限が要らない。[Windows 11 の初期設定の更新](../windows-setup.md#更新)の `scoop update *` でほかのツールとまとめて上がり、UniGet UI にも出る
  - winget の `GitHub.cli` は、先に並ぶのが MSI（`Scope: machine`。`C:\Program Files\GitHub CLI` に入り、UAC が出る）。同じ zip の portable もあるが、採らない
  - 上流の MSI や zip を手で入れる形は、更新が手作業になる
  - scoop は、定義の sha256（上流の `gh_<版>_checksums.txt` と同じ値）で zip を確かめる。`gh.exe` には `GitHub, Inc.` の Authenticode の署名があるが、手順では確かめない
  - 版は固定しない（`scoop hold` しない）。scoop で止めるのは、Git Bash で移動先を記録しない 0.10.0 を避ける zoxide だけ（[Windows 11 の初期設定のシェルのツールを入れる（任意）](../windows-setup.md#シェルのツールを入れる)）
- **`XDG_CONFIG_HOME` は設定しない**: 設定すると、gh の設定の場所が `%XDG_CONFIG_HOME%\gh` に変わり、設定した窓と設定していない窓で、gh が別のログインの一覧を読む
  - Git for Windows の起動スクリプト、自分用の bash 設定、WezTerm の設定は、どれも `XDG_CONFIG_HOME` を設定しない。そのため、Git Bash・PowerShell・cmd の gh は、同じ `%APPDATA%\GitHub CLI` を読む（ソースと設定を読んだだけ）
  - トークンは資格情報マネージャー（ユーザーごと）にあるので、どのシェルからも同じ
- **git の HTTPS の認証は Git Credential Manager のまま**: [Windows 11 で使う / 手順 4 の補足](#github-cli-windows-11-で使う--手順-4-補足-git-の認証に-n-と答える理由)
- **シェルとの組み込み方**
  - gh はシェルの初期化が要らない。scoop の shims（ユーザーの `PATH`）にあるので、Git Bash・PowerShell・cmd のどれからでも動く
  - **Git Bash が主**: WezTerm の自分用の設定の `default_prog` は Git Bash（`bash.exe -i -l`）。共通の bash 設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）は gh を扱わない。bash の補完も入れない（足すなら bash リポジトリの変更になる）
  - **PowerShell 7 のプロファイルには何も足さない**: [Windows 11 の初期設定の任意節](../windows-setup.md#powershell-7-のプロファイルを設定する任意)が読むのは starship と zoxide だけ。gh の PowerShell の補完（`gh completion -s powershell`）は、pwsh を開くたびに gh を 1 回動かすので入れない
  - **Windows PowerShell 5.1 のプロファイルにも足さない**: 手順書を貼る窓のプロファイルは、Windows 11 の初期設定の「貼り付けの設定」の手順 4 の 1 行のまま
  - **WSL の AlmaLinux 10 は Linux のホストとして扱う**: WSL の中で[実施手順](../almalinux-setup.md#github-cli)を通す。設定とトークンは WSL の中にあり、Windows の gh とは別
- **Visual C++ のランタイムは要らない**: `gh.exe`（Go）のインポートは `kernel32.dll` だけ。bat・delta と違い、[wezterm-nightly.md の Windows 11 で使う](../windows-setup.md#wezterm)の手順 3 を前提にしない
- **ロールバックは、ログアウトを先にする**: `gh auth logout` が資格情報マネージャーの gh の項目を消す。gh を先に消すと（[Windows 11 の初期設定のロールバックの「アプリと貼り付けの設定を外す」](../extra/windows-setup.md#アプリと貼り付けの設定を外す)の手順 4 で scoop ごと外したときも）、その項目が残る
- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた

---

## 統合前の参考資料: Neovim の Windows 11（もとは neovim.md）

もとの `neovim.md` の参考資料のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の参考資料](almalinux-setup.md#統合前の参考資料-neovimもとは-neovimmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/windows-setup.md)の統合前の記録と同じ。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。前の項で開いた窓を使う） |
| Windows 11 で使う 2・3 | 「Neovim」の手順 1・2 |
| Windows 11 で使う 4 | 「Neovim」の手順 4 |
| Windows 11 で使う 5（`checkhealth`） | （外した。自分用の設定の導入（「Neovim」の手順 3）で確かめる） |
| 既定のエディタにする（任意）の 2・3 | Neovim を既定のエディタにする（任意）の 1・2 |
| Windows 11 の更新 1 | 「scoop・winget・WSL を上げる」の手順 1・2 |
| Windows 11 のロールバック 1 | ロールバックの「エディタとシェルのツールを消す」の手順 5 |
| Windows 11 のロールバック 2 | Neovim を既定のエディタにする（任意）の 2 |

### Neovim: 補足

#### Neovim: Windows 11 で使う / 手順 2: 補足: 確かめる値の意味

- `Nvim` が空なら、Neovim は入っていない。`C:\Users\<WIN_USER>\scoop\shims\nvim.exe` だけなら、もう scoop で入っている

#### Neovim: Windows 11 で使う / 手順 3・4: 補足: 版

- 同じ節の手順 3 の `'neovim' (<版>) was installed successfully!` と、手順 4 の `NVIM v…` の版は、実行した日の最新

#### Neovim: Windows 11 では: 選択した方針

[Windows 11 で使う](../windows-setup.md#neovim)・[既定のエディタにする（任意）](../windows-setup.md#neovim-を既定のエディタにする任意)の手順 2・3 の理由。**Windows 実機では未検証**（[検証記録](../verification/windows-setup.md#neovim-windows-11-で使う-検証状況の記録)）。

- **scoop の main の `neovim` で、自分のユーザーに入れる**（管理者の権限は要らない）
  - [Windows 11 の初期設定の「アプリを入れる」](../windows-setup.md#アプリを入れる)の手順 1・2 で入れた scoop に、CLI のツールをまとめる。自分用の設定（LazyVimStarter）の Windows の導入も scoop の `neovim` を使う
  - winget の `Neovim.Neovim` は PC 全体に入る MSI（`C:\Program Files\Neovim`）。PC 全体の `PATH` はユーザーの `PATH` より先に引かれるので、両方あると winget の方が使われる。Windows 11 で使うの手順 2 で見つけたら、外してから始める
- **VC++ のランタイムは、wezterm-nightly.md の Windows 11 で使うの手順 3 を指す**（winget の `Microsoft.VCRedist.2015+.x64`。管理者の窓）
  - scoop の `neovim` はランタイムを入れず、`extras/vcredist2022` を勧めるだけ（`neovim.json` の `suggest`）。`nvim.exe` は `VCRUNTIME140.dll` を使う（リリースの zip のインポート表。[検証記録の付録](../verification/windows-setup.md#neovim-付録-windows-11-の節の資料と-linux-での確認2026-10-08)）
  - 無いと、`nvim.exe` は何も出さずに終わる（LazyVimStarter の検証記録の 2026-10-06 のクリーンな Windows 11 の VM の記録。ブロックは自動で流したもの）
  - デスクトップで打つと、`VCRUNTIME140.dll` が見つからない旨のシステム エラーの窓が出ることもある（読み込みに失敗したときの Windows の通常の振る舞い。確かめていない）。そのため手順書は、窓が出る場合も書いた
  - Windows で入れる手順を 1 か所にするため、この文書には入れ方を書かない。scoop の `vcredist2022` は x64 と x86 の両方を入れ、UAC の確認が出る
- **`XDG_CONFIG_HOME` をユーザーの環境変数にしない**
  - Neovim と lazygit は追従するが、yazi は Windows では読まない（`%APPDATA%\yazi\config` のまま）
  - WezTerm は、`~/.wezterm.lua` が無ければ、`~/.config/wezterm` の代わりに `$XDG_CONFIG_HOME/wezterm` を読む（`~/.config` の側は探さない。[wezterm-nightly.md の検証記録の実測](../verification/almalinux-setup.md#wezterm-設定ファイルの探索順序実測)）
  - git は `~/.gitconfig`（git.md が書く場所）を読み続け、`~/.config/git/config` の代わりに `$XDG_CONFIG_HOME/git/config` を読む
  - このように、追従するもの・読まないもの・一部だけ変わるものがあり、ツールごとに読む場所が割れる
  - LazyVimStarter の検証記録（2026-09-30）に、`XDG_CONFIG_HOME` を付けたまま Neovim が設定を見つけなかった記録がある
- **`EDITOR`・`VISUAL` は、任意のユーザーの環境変数にする**
  - WezTerm の Git Bash は、共通の bash 設定が `nvim` にするので要らない。Windows PowerShell・Windows Terminal から起動したツールにだけ効かせる
  - lazygit 0.66.0 は、`os.edit` などが無いと、git の `core.editor` → `GIT_EDITOR` → `VISUAL` → `EDITOR` の順に探し、最初の語のファイル名で既知のプリセットを選ぶ。どれも無いと `vim` のプリセットになる。Windows の lazygit はエディタを `cmd.exe` で動かすので、Git for Windows の `usr\bin\vim` は見つからない
  - 値を `nvim` だけにするのは、`nvim.exe` やフルパスでは `nvim` のプリセットに合わないため
  - Git for Windows のインストーラで Vim を選ぶと、`core.editor` は書かれず、git は `EDITOR` を使う。そのため PowerShell の `git commit` も Neovim になる
  - ほかの値があれば止め、元に戻す手順は値が `nvim` のときだけ消す（元の値を消さないため）
- **起動の確かめは `:checkhealth`**（AlmaLinux 10 の手順 2 と同じ）。TUI が開くので、節の最後の手順にした

---

## 統合前の参考資料: lazygit の Windows 11（もとは lazygit.md）

もとの `lazygit.md` の参考資料のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の参考資料](almalinux-setup.md#統合前の参考資料-lazygitもとは-lazygitmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/windows-setup.md)の統合前の記録と同じ。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。前の項で開いた窓を使う） |
| Windows 11 で使う 2〜4 | 「lazygit」の手順 1〜3 |
| Windows 11 で使う 5・6 | 「lazygit」の手順 5・6 |
| Windows 11 の更新 1 | 「scoop・winget・WSL を上げる」の手順 1・2 |
| Windows 11 のロールバック 1 | ロールバックの「Git の道具を消す」の手順 2 |

### lazygit: 補足

#### lazygit: Windows 11 で使う / 手順 2: 補足: 確かめる値の意味

- `Lazygit` が空なら、lazygit は入っていない。`C:\Users\<WIN_USER>\scoop\shims\lazygit.exe` だけなら、もう scoop で入っている（自分用の Neovim の設定の導入でも入る）

#### lazygit: Windows 11 で使う / 手順 4・5: 補足: 版

- 同じ節の手順 4 の `'lazygit' (<版>) was installed successfully!` と、手順 5 の `version=` の版は、実行した日の最新

#### lazygit: Windows 11 で使う / 手順 6: 補足: 新しい窓と確かめ用のリポジトリ

- `EDITOR` を `nvim` にした後、新しい窓で lazygit を起動し直すのは、今の窓には入らないため
- `%TEMP%\lazygit-check` を消す前に `Set-Location ~` で出るのは、この窓の今のフォルダーがそこにあり、今のフォルダーのままでは使用中で消せないため

#### lazygit: Windows 11 では: 選択した方針

[Windows 11 で使う](../windows-setup.md#lazygit)の理由。**Windows 実機では未検証**（[検証記録](../verification/windows-setup.md#lazygit-windows-11-で使う-検証状況の記録)）。

- **scoop の extras の `lazygit`**（main のバケットには無い）
  - extras のバケットを足すのに git が要る（Git for Windows）。extras は、ほかのアプリ（`vcredist2022`・`neovide` など）も使うので、ロールバックでも外さない
  - lazygit は Go の 1 つの実行ファイルなので、VC++ のランタイムは要らない（自分用の設定が使う delta は要る。[git-delta.md の Windows 11 で使う](../windows-setup.md#git-delta)の手順 2 で確かめる）
  - winget の `JesseDuffield.lazygit` と両方あると、`PATH` の順でどちらかが使われ、分かりにくい。Windows 11 で使うの手順 2 で見つけたら、外してから始める
- **設定の置き場所は `%LOCALAPPDATA%\lazygit`**
  - lazygit 0.66.0 の Config.md の Windows の既定の場所。`%APPDATA%\lazygit\config.yml` も探す（adrg/xdg の Windows の `XDG_CONFIG_DIRS` は `%ProgramData%` と `%APPDATA%`）
  - `XDG_CONFIG_HOME` は設定しない（[neovim.md の参考資料](#neovim-windows-11-では-選択した方針)）
- **自分用の設定は、設定のリポジトリの README の Windows の例へリンクする**（clone のコマンドはこの文書に載せない）。その例は `%LOCALAPPDATA%\lazygit` に直接 clone する（シンボリックリンクには、開発者モードか管理者の権限が要るため）。状態ファイル `state.yml` は、そのリポジトリの `.gitignore` で除いてある
- **確かめの起動は `%TEMP%\lazygit-check` の空のリポジトリで行う**
  - 読者のリポジトリの場所を決め打ちできないため。git 管理外で起動すると、リポジトリを作るか聞かれる
  - `git init` が失敗したまま起動すると、元のフォルダーでリポジトリを作るか聞かれるので、`.git` ができたことを確かめてから起動する
- **`e` キーのエディタ**: Windows PowerShell から起動したときは、ユーザーの環境変数 `EDITOR` で決まる（[neovim.md の参考資料](#neovim-windows-11-では-選択した方針)）。自分用の設定は `os.editInTerminal` を `true` にした（`false` を明示すると、lazygit 0.66.0 ではプリセットより優先され、端末のエディタに端末が渡らない。ryo-aoki-pc/lazygit#10）

---

## 統合前の参考資料: yazi の Windows 11（もとは yazi.md）

もとの `yazi.md` の参考資料のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の参考資料](almalinux-setup.md#統合前の参考資料-yaziもとは-yazimd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/windows-setup.md)の統合前の記録と同じ。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。前の項で開いた窓を使う） |
| Windows 11 で使う 2〜5 | 「yazi」の手順 1〜4 |
| Windows 11 で使う 6〜9 | 「yazi」の手順 6〜9 |
| Windows 11 の更新 1 | 「scoop・winget・WSL を上げる」の手順 1・2 |
| Windows 11 のロールバック 1・2 | ロールバックの「エディタとシェルのツールを消す」の手順 2・3 |

### yazi: 補足

#### yazi: Windows 11 で使う / 手順 2: 補足: 変数について

- 既定は、プレビュー・検索用のツールを一緒に入れる想定になっている（どれも scoop の main のバケットにある）
- 1 つだけにするときも `@('fd')` の形のままにするのは、`'fd'` だけにすると、1 文字ずつ別の名前として scoop に渡るため

#### yazi: Windows 11 で使う / 手順 3: 補足: 確かめる値の意味

- ほかの場所の yazi を外すのは、混ざらないようにするため
- `Config : True` なら、設定がもうある（[設定ファイル](../almalinux-setup.md#yazi-の設定ファイル)）

#### yazi: Windows 11 で使う / 手順 4: 補足: 版と、出る行・環境変数

- 同じ節の手順 4 の `'yazi' (<版>) was installed successfully!` と、手順 6 の `Version:` の版は、実行した日の最新
- `suggests installing` の行のものを入れなくてよいのは、VC++ のランタイムを同じ節の手順 3 で確かめてあるため
- imagemagick が足すユーザーの環境変数（`MAGICK_HOME` など）と `PATH` は、今の窓にも入る。ほかの開いている窓は、開き直してから効く

#### yazi: Windows 11 では: 選択した方針

[Windows 11 で使う](../windows-setup.md#yazi)の理由。**Windows 実機では未検証**（[検証記録](../verification/windows-setup.md#yazi-windows-11-で使う-検証状況の記録)）。

- **scoop の main の `yazi`**: yazi の公式の文書が Windows で案内する経路の 1 つ。依存のツールも main にある
- **`$YAZI_EXTRAS` は、AlmaLinux 10 の `YAZI_EXTRAS` に合わせた**
  - 公式の文書の scoop の一覧（ffmpeg・7zip・jq・poppler・fd・ripgrep・fzf・zoxide・resvg・imagemagick）から zoxide を外した。AlmaLinux 10 の一覧にも無く、AlmaLinux 10 は [AlmaLinux 10 の初期設定の「シェルのツール」の手順 1](../almalinux-setup.md#シェルのツール)、Windows 11 は [Windows 11 の初期設定のシェルのツールを入れる（任意）](../windows-setup.md#シェルのツールを入れる)で入れる（Windows の zoxide は、Git Bash での記録の問題があるので、その節で 0.9.9 に止めてある）
  - Homebrew の `font-symbols-only-nerd-font` の代わりは、[hackgen.md の Windows 11 で使う](../windows-setup.md#hackgen-console-nf)の HackGen Console NF
  - 変数が無いまま `scoop install yazi @YAZI_EXTRAS` を流すと、空の引数が 1 つ scoop に渡った（Linux の PowerShell 7.5.3 での模擬。[検証記録の付録](../verification/windows-setup.md#yazi-付録-windows-11-の節の資料と-linux-での確認2026-10-08)）
    - そのため、Windows 11 で使うの手順 4 は、同じ節の手順 2 を貼っていない窓では止める
- **`file` は、Git for Windows の `usr\bin\file.exe` を `YAZI_FILE_ONE` で渡す**
  - yazi の文書が勧める唯一の形。scoop・Chocolatey の `file` は Unicode のファイル名を扱えない
  - yazi は `YAZI_FILE_ONE` をシェルを通さずに起動するので、`Program Files` の空白は問題にならない
    - yazi 26.9.1 の `yazi-plugin/preset/plugins/mime-local.lua`・`file.lua` は、`Command(<YAZI_FILE_ONE の値>)` で起動する
    - Lua の `Command` は、`yazi-binding/src/process/command.rs` の `tokio::process::Command::new`（シェルを挟まない）。`ya env` も `Command::new` で動かす（`yazi-cli/src/env/env.rs`）
  - PowerShell の `PATH` には `file` が無い。Git Bash には `/usr/bin/file` があるが、PowerShell や Windows Terminal から起動したときにも同じに動くよう、ユーザーの環境変数にする
  - Windows 11 で使うの手順 5 は、前の値を確かめずに上書きする。元の値は同じ節の手順 3 で控え、Windows 11 のロールバックの手順 2 の後に手で戻す
  - そのロールバックの手順 2 は、値が Git for Windows の `file.exe` のときだけ消す（neovim.md の `EDITOR`・`VISUAL` と同じく、後から変えた値は残す）
- **VC++ のランタイムは、neovim.md と同じく wezterm-nightly.md の手順 3 を指す**: yazi 26.9.1 の Windows 版（msvc）の `yazi.exe`・`ya.exe` は `VCRUNTIME140.dll` を使い、scoop の `yazi` はランタイムを入れない（リリースの zip のインポート表。[検証記録の付録](../verification/windows-setup.md#yazi-付録-windows-11-の節の資料と-linux-での確認2026-10-08)）
- **設定は `%APPDATA%\yazi\config`**: Windows の yazi は `XDG_CONFIG_HOME` を見ない（yazi 26.9.1 の `yazi-fs/src/xdg.rs`）。状態は `%APPDATA%\yazi\state`、キャッシュは `%LOCALAPPDATA%\yazi`。自分用の設定の Windows の clone は、設定のリポジトリの README の例へリンクする
- **`y` は Git Bash の共通の設定だけで使う**: Windows PowerShell 5.1 は手順書を貼る窓なので、ツールの初期化（PowerShell 版の `y`）は足さない。WezTerm の自分用の設定は、Windows の新しいタブで Git Bash を開く
  - PowerShell 7 のプロファイル（[Windows 11 の初期設定の任意節](../windows-setup.md#powershell-7-のプロファイルを設定する任意)）にも、`y` は足していない。その節が足すのは貼り付け・履歴の検索と zoxide・starship の行だけで、PowerShell 版の `y` はこの文書の範囲の外にした
- **ファイルを開くエディタは、自分用の設定の Neovim を前提にした**（Windows 11 で使うのリードで、先に neovim.md を通すよう案内する）
  - 上流の既定（yazi 26.9.1 の `yazi-config/preset/yazi-default.toml`）の `[opener]` の `edit` は、Windows では `code %s` と `code -w %s`（VS Code）
  - `${EDITOR:-vi}` は `for = "unix"` の行だけで、Windows の yazi は `EDITOR` を見ない
  - テキスト（`text/*`）は `edit` が最初の候補なので、自分用の設定が無いと、Git Bash の `y` から開いても Enter で `code` が動く
  - 自分用の設定（`ryo-aoki-pc/yazi` の `yazi.toml`）は、Windows の `edit` を `nvim %s`（`block = true`）にしてある
- **確かめは `ya env`**: 26.9.1 には `yazi --debug` が無く、`ya env` が設定の場所・変数・依存の版・`file -bL --mime-type` の結果を出す
- **TUI の手順を節の最後にした**: Git Bash の `y` の確かめを先にし、PowerShell の `yazi` の起動を最後に置いた
  - Git Bash のタブを開くところ（コマンドの無い手順 7）と、そこに貼る `type -t y` と `y`（`bash` のブロックの手順 8。git.md と同じく、Git Bash には bash の構文で貼る）を分けた
  - 手順 8 の `y` も TUI を開くので、手順 8 の最後で閉じてから PowerShell に戻る

---

## 統合前の参考資料: Claude Code の Windows 11（もとは claude-code.md）

もとの `claude-code.md` の参考資料のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の参考資料](almalinux-setup.md#統合前の参考資料-claude-codeもとは-claude-codemd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/windows-setup.md)の統合前の記録と同じ。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。前の項で開いた窓を使う） |
| Windows 11 で使う 2〜9 | 「Claude Code」の手順 1〜8 |
| Windows 11 の更新 1 | 「AI エージェントとプラグインを上げる」の手順 1 |
| Windows 11 のロールバック 1〜4 | ロールバックの「AI エージェントとプラグインを消す」の手順 2〜5 |

### Claude Code: 補足

#### Claude Code: Windows 11 で使う / 手順 1: 補足: x86 の PowerShell

- 「Windows PowerShell (x86)」は 32 ビットで動き、インストーラが `Claude Code does not support 32-bit Windows` で止まる

#### Claude Code: Windows 11 で使う / 手順 3: 補足: 確かめていることと、Git for Windows の役割

- `[Environment]::Is64BitProcess` は、インストーラが最初に見る値と同じ。スタートメニューの「Windows PowerShell (x86)」は、64 ビットの Windows でも 32 ビットで動く（公式の Troubleshoot installation）
- native installer の置き場所は `%USERPROFILE%\.local\bin\claude.exe` に決まっている（公式の文書）。同じ名前のコマンドがほかにもあると、`PATH` の順で先のものが動き、版が食い違う（公式の Check for conflicting installations）
- Git for Windows は任意（公式の Set up on Windows）。入っていれば、Claude Code は Git Bash を Bash のツールと Monitor のツールに使う。無ければ PowerShell のツールでコマンドを動かす
- Claude Code が Git Bash を探す順は、`C:\Program Files\Git`・`C:\Program Files (x86)\Git` → `PATH` の `git` の `bin\bash.exe`（公式の Troubleshoot installation）。ほかの場所に入れたときは、設定の `env` の `CLAUDE_CODE_GIT_BASH_PATH` に `bash.exe` のパスを書く

#### Claude Code: Windows 11 で使う / 手順 5: 補足: PATH の足し方

[この節の検証記録](../verification/windows-setup.md#claude-code-windows-11-で使う--手順-5-補足-path-の足し方)

- native installer は `PATH` を変えない（この節の手順 4 の補足）。公式の文書（Troubleshoot installation の Verify your PATH）は、Windows PowerShell に `[Environment]::SetEnvironmentVariable('PATH', "$currentPath;$env:USERPROFILE\.local\bin", 'User')` を貼る形で足す。この手順も同じ書き方で、あれば足さないようにしただけ
- `SetEnvironmentVariable` の `User` は、レジストリの `HKCU\Environment` の `Path` に書き、開いているウィンドウに環境が変わったことを知らせる。そのため、この後に開いた PowerShell に効く（サインインし直さなくてよい）
- 読むときに `%USERPROFILE%` のような書き方は展開され、書き戻すと展開した形（`C:\Users\<WIN_USER>\...`）で残る（.NET Framework の `Environment` の動き）。自分のユーザーの PATH なので、困ることは無いはず
- 足すのは自分のユーザーの PATH だけで、システムの PATH（管理者の権限が要る）は変えない
- 公式の文書は、画面からでも同じことができるとしている（システムのプロパティ → 環境変数 → ユーザー環境変数の `Path` → 新規）
- 開いている PowerShell には効かない。同じ節の手順 6 で開き直す

#### Claude Code: Windows 11 で使う / 手順 6: 補足: 開き直した PowerShell が読む PATH

- 開き直した PowerShell は、同じ節の手順 5 で足した PATH と、Git for Windows を入れたばかりなら、その PATH も読む

#### Claude Code: Windows 11 で使う / 手順 8: 補足: ログインの流れと、ログインの情報の置き場所

[この節の検証記録](../verification/windows-setup.md#claude-code-windows-11-で使う--手順-8-補足-ログインの流れとログインの情報の置き場所)

- 公式の文書（Authentication）: 最初の起動でブラウザが開く。`ANTHROPIC_API_KEY` を設定していると、ブラウザの代わりにその鍵を使ってよいか 1 度だけ聞かれる。ブラウザが Claude Code の待ち受けに戻れないとき（SSH のセッションなど）は、ブラウザに出たコードを端末に貼る

- 開き直した PowerShell は `C:\Users\<WIN_USER>` で始まる。ホームのフォルダーの信頼は保存されない（[windows-claude-remote-control.md](../windows-claude-remote-control.md)）ので、起動のたびに聞かれる。作業したいディレクトリに `cd` してから起動してもよい
- ログインの情報は `%USERPROFILE%\.claude\.credentials.json` に置かれ、ユーザーのプロファイルのアクセス権を引き継ぐ（公式の文書）
- Remote Control（[windows-claude-remote-control.md](../windows-claude-remote-control.md)）は claude.ai のアカウントでのログインが要る（API キーでは使えない）

#### Claude Code: Windows 11 で使う / 手順 9: 補足: 後ろに続けて貼らない理由

- AlmaLinux 10 では、ブラケットペースト無しで、`claude auth status` の後ろに貼った行を読んで捨てた（[使い方の基本](../almalinux-setup.md#claude-code-の使い方の基本)）

#### Claude Code: Windows 11 のロールバック / 手順 2: 補足: 消すもの

[この節の検証記録](../verification/windows-setup.md#claude-code-windows-11-のロールバック--手順-2-補足-消すもの)

- 公式の文書の Windows PowerShell の手順が消すのは、`%USERPROFILE%\.local\bin\claude.exe` と `%USERPROFILE%\.local\share\claude`（版のファイル）の 2 つ
- 本書は、更新の名残の `claude.exe.old.*`（[Windows 11 の更新](../windows-setup.md#ai-エージェントとプラグインを上げる)の補足）と、`%USERPROFILE%\.local\state\claude`（ロック）・`%USERPROFILE%\.cache\claude`（更新の途中のファイル）も消す。消去対象の根拠と検証範囲は検証記録に置く
- 空になった `%USERPROFILE%\.local\share` などは残る

---

## 統合前の参考資料: Codex CLI の Windows 11（もとは codex.md）

もとの `codex.md` の参考資料のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の参考資料](almalinux-setup.md#統合前の参考資料-codex-cliもとは-codexmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/windows-setup.md)の統合前の記録と同じ。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1〜8 | 「Codex CLI」の手順 1〜8 |
| Windows 11 の更新 1 | 「AI エージェントとプラグインを上げる」の手順 2 |
| Windows 11 の更新 2・3 | 「AI エージェントとプラグインを上げる」の手順 3（版の確かめは、その箇条書き） |
| Windows 11 のロールバック 1〜4 | ロールバックの「AI エージェントとプラグインを消す」の手順 6〜9 |

### Codex CLI: 補足

#### Codex CLI: Windows 11 で使う / 手順 2: 補足: 置き場所と PowerShell の設定

- 実行ファイルの入口は `%LOCALAPPDATA%\Programs\OpenAI\Codex\bin\codex.exe`。`bin` は `%USERPROFILE%\.codex\packages\standalone\` 内の配布物を指すジャンクションになる
- インストーラーがユーザー用 PATH と、今の PowerShell の PATH の両方を設定する
- `&` でスクリプトブロックとして呼び、インストーラーの StrictMode・エラー処理の設定を呼び出し元に残さない
- PowerShell 全体の ExecutionPolicy を変更する手順は不要

---

## 統合前の参考資料: Grok Build の Windows 11（もとは grok-build.md）

もとの `grok-build.md` の参考資料のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の参考資料](almalinux-setup.md#統合前の参考資料-grok-buildもとは-grok-buildmd)に移した）。見出しの付け方とリンクの直し方は、[検証記録](../verification/windows-setup.md)の統合前の記録と同じ。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1〜8 | 「Grok Build」の手順 1〜8 |
| Windows 11 の更新 1・2 | 「AI エージェントとプラグインを上げる」の手順 2・4 |
| Windows 11 のロールバック 1〜5 | ロールバックの「AI エージェントとプラグインを消す」の手順 10〜14 |

### Grok Build: 補足

#### Grok Build: Windows 11 の更新 / 手順 1: 補足: 終了する理由

- 先に Grok を終了するのは、動いている `grok.exe` は置き換えられないため

### Grok Build: 選択した方針

#### Grok Build: Windows 11 で使う / 手順 2: インストーラーの動き

- `%USERPROFILE%\.grok\downloads\grok-windows-<アーキ>.exe` を取ってきて、`%USERPROFILE%\.grok\bin\grok.exe` と `agent.exe` に写す（リンクではなくコピー）
- Grok が使う Git（MinGit）を `%LOCALAPPDATA%\grok\git\<版>` に置く。zip は SHA-256 を確かめてから展開する
- PowerShell の補完を `%USERPROFILE%\.grok\completions\powershell\grok.ps1` に書く（プロファイルには足さない）
- 自分のユーザーの PATH の先頭に `%USERPROFILE%\.grok\bin` を足し、今の窓の `$env:Path` にも足す（`[Environment]::SetEnvironmentVariable('Path', …, 'User')`。[claude-code.md の参考資料](#claude-code-windows-11-で使う--手順-5-補足-path-の足し方)と同じ書き方で、`%USERPROFILE%` のような書き方は展開した形で書き戻される）
- スクリプトの先頭で `$ErrorActionPreference = 'Stop'` にするので、`irm … | iex` ではなく `&` でスクリプトブロックとして呼び、今の窓にその設定を残さない（codex.md と同じ）。失敗したときの `exit 1` は、どちらの呼び方でも窓を閉じることがある
