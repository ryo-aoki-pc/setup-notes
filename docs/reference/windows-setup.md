# Windows 11 の初期設定の手順（インストール直後の更新・貼り付けの設定・scoop・UniGet UI・表示・電源・リモート・WSL）の参考資料

[手順書](../windows-setup.md)

[検証記録](../verification/windows-setup.md#参考資料から分離した記録)

## 補足

### 実施手順 / 手順 1: 補足: 先に更新する理由

- インストールしたばかりの Windows は、インストールのメディアを作った時点の版。この後の手順には、新しい版を前提にするものがある（手順 40 の sudo は 24H2 以降、手順 28 の時計の秒など）
- この後の手順 55 の再起動より前に、Windows Update の再起動を済ませておく。途中で更新の再起動が入ると、手順 36〜54 の設定が効く時期が読みにくくなる

### 実施手順 / 手順 2: 補足: 今の窓だけにする理由

- `Process` の実行ポリシーと TLS 1.2 の追加は、この窓を閉じると無くなる。手順 17 で控える `CurrentUser` の実行ポリシーは変えない
- 再起動したら手順 1・2・3 をもう一度通す。モジュールのファイルは残るが、新しい窓では読み込み直す必要がある

### 実施手順 / 手順 4: 補足: 更新の対象

- Windows Update Agent の条件で、未導入（`IsInstalled=0`）・非表示でない（`IsHidden=0`）・自動更新の配信対象（`IsAssigned=1`）・オプションでない（`BrowseOnly=0`）ものに絞る
- オプションのドライバーやプレビュー更新は含めない。通常の自動配信に含まれるドライバーは対象になる
- 更新名の「Preview」「プレビュー」の文字では除外しないので、Windows の表示言語には依存しない
- 更新の取得先はこの PC の既定のまま。`-MicrosoftUpdate` による対象の拡大や、WSUS・Windows Update のポリシーの変更は行わない

### 実施手順 / 手順 5: 補足: 自動では再起動しない

- `-AcceptAll` は対象の更新を承認する。検索条件は手順 4 と同じで、オプションの更新は増やさない
- `-IgnoreReboot` は、必要になっても再起動せず、再起動するかを聞く対話も出さない（PSWindowsUpdate のヘルプ）
- `-AutoReboot`・`-RecurseCycle` は使わない。再起動と再検索は手順 8 の後に自分で行い、再開用のタスクも作らない

### 実施手順 / 手順 11: 補足: インストール直後の winget

- Microsoft の WinGet の文書は、初回サインイン後に Store が非同期で登録するため、まだ使えない場合にこの `Add-AppxPackage` を挙げている
- この文書は、アプリ インストーラーと Microsoft Store が含まれる Windows 11 を前提にする。これらを削ったイメージの復旧は扱わない

### 実施手順 / 手順 12: 補足: CLI を使えるようにする準備だけを winget で行う

- 製品 ID はアプリ インストーラーが `9NBLGGH4NNS1`、Microsoft Store が `9WZDNCRFJBMP`。`--exact` と `--source msstore` で、この 2 つだけを対象にする
- Store の配布情報は版が `Unknown` の場合があるので `--include-unknown` を付ける。`winget upgrade --all` に置き換えない
- `-1978335189`（`0x8A15002B`）は、winget の `UPDATE_NOT_APPLICABLE`（適用する更新が無い）。それ以外の失敗では中断する

### 実施手順 / 手順 17: 補足: 見ているもの

- `Admin` は、この PowerShell が管理者の権限で動いているか（UAC で昇格しているか）。Administrators の一員でも、普通に開いた PowerShell は `False` になる
- `ClassicMenu` は、手順 26 で作るキー（`HKCU:\Software\Classes\CLSID\{86ca1aa0-…}`）があるか
- `ScancodeMap` は、手順 51 で書く値（`HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout` の `Scancode Map`）を 16 進で並べたもの。読むだけなら管理者は要らない
- `$PROFILE` は、このユーザーの、Windows PowerShell のコンソールのプロファイル（`Microsoft.PowerShell_profile.ps1`）。管理者で開いた窓も、同じユーザーなら同じファイルを読む。PowerShell 7・PowerShell ISE・VS Code は別のファイルを読む（about_Profiles）。OneDrive でドキュメントをバックアップしていると、`OneDrive` の下のパスになる
- `Get-ExecutionPolicy -List` は、範囲（`MachinePolicy`・`UserPolicy`・`Process`・`CurrentUser`・`LocalMachine`）ごとの実行ポリシー。上の範囲ほど優先される。`MachinePolicy` か `UserPolicy` が `Undefined` でなければ、グループ ポリシーで決まっていて、手順 18 では変えられない
- プロファイルもスクリプト（`.ps1`）なので、実行ポリシーが `Restricted` だと読まれない（Microsoft の about_Execution_Policies。`Restricted` は Windows のクライアントの既定）

### 実施手順 / 手順 20: 補足: インストーラのすること

- `https://get.scoop.sh` は、公式のインストーラ（`https://raw.githubusercontent.com/scoopinstaller/install/master/install.ps1`）へ飛ぶ。`Invoke-Expression` で、取ったスクリプトをそのまま動かす（公式の README の方法）
- 中身を読んでから動かすなら、`Invoke-RestMethod -Uri https://get.scoop.sh -OutFile install.ps1` で保存して読み、`.\install.ps1` で動かす（同じ README の方法）。インストーラに Authenticode の署名は無い
- インストーラは、PowerShell 5 以上・管理者でないこと・実行ポリシー・scoop がまだ無いことを確かめてから入れる
- 入るもの
  - `~\scoop\apps\scoop\current`（scoop 本体）・`~\scoop\buckets\main`（main のバケット）・`~\scoop\shims`（コマンドの入口）
  - ユーザーの環境変数 `PATH` の先頭に `~\scoop\shims` を足す。変えたことを Windows 全体に知らせる（`WM_SETTINGCHANGE`）ので、この後にスタートメニューから起動したアプリにも届く
  - 設定のファイル `~\.config\scoop\config.json`
- git があれば、本体と main のバケットを `git clone` で取る。無ければ zip で取る
- git の無い PC では、`scoop update` が `Scoop uses Git to update itself. Run 'scoop install git' and try again.` で止まる。この文書の後に [git.md](../git.md#windows-11-で-git-for-windows-を入れる) で Git for Windows を入れれば、`scoop update` は scoop 本体と main のバケットを git の形に直して上げる（scoop 0.6.0 の `libexec/scoop-update.ps1`。scoop の `git` は入れない。[選択した方針](../verification/windows-setup.md#選択した方針)）
- 管理者で入れる方法（インストーラの `-RunAsAdmin`）は、公式の README が安全のために既定で止めているので、使わない

### 実施手順 / 手順 23: 補足: 入れ方と入る場所

- winget の定義（`Microsoft.PowerToys` 0.101.2362.0）には、自分のユーザーに入れるインストーラ（`PowerToysUserSetup-<版>-x64.exe`。管理者の確認の指定が無い）と、PC 全体に入れるインストーラ（`PowerToysSetup-<版>-x64.exe`。`elevatesSelf`）がある。`--scope user` を付けて、自分のユーザーのほうを選ばせる
- インストーラの形式は WiX の Burn で、winget は `/quiet /norestart` を渡す
- 入る場所は、Microsoft の文書では自分のユーザーなら `%USERPROFILE%\AppData\Local\Programs` の下（下のフォルダーの名前は書かれていない）
- PowerToys のいくつかの機能は、PowerToys を管理者として動かしていないと、管理者の窓には効かない（PowerToys の設定の「常に管理者として実行」）
- WebView2 のランタイムが無ければ一緒に入れる（Windows 11 には最初からある）

### 実施手順 / 手順 24: 補足: MSIX と MSI

- Microsoft の文書は、winget のパッケージは 7.6.0 から既定で MSIX を入れると書いている。winget の定義（`Microsoft.PowerShell` 7.6.6.0）も、MSIX（自分のユーザー）を先に、MSI（PC 全体。`elevatesSelf`）を後に並べている
- MSIX は自分のユーザーだけに入り、更新は winget かストアで行う。PC 全体の実行ポリシーやリモートの受け口は設定できない（Microsoft の文書）。このリポジトリの使い方では足りる
- PC 全体の MSI（`$Env:ProgramFiles\PowerShell\7`、Microsoft Update で更新）にするなら `--installer-type wix` を付ける。ただし Microsoft の文書では、7.7.0 から MSI は無くなる
- PowerShell 7.6.6 の PSReadLine 2.4.5 も、Ctrl+Enter は `InsertLineAbove`。PowerShell 7 の窓に右クリックで貼ると、同じように逆順になるはず（手順 19 は PowerShell 7 のプロファイルには書かない。[注意点](../windows-setup.md#注意点)）

### 実施手順 / 手順 29: 補足: 値の意味

- `AppsUseLightTheme` はアプリ、`SystemUsesLightTheme` はタスクバー・スタート・通知の色。0 で濃色、1 で淡色（Windows 11 の既定）
- Microsoft の DSC のリソース（`Microsoft.Windows.Settings`）も同じ 2 つを書き、すぐに効かせるために `WM_SETTINGCHANGE`（`ImmersiveColorSet`）を全部の窓に送る。本書は、手順 55 で再起動するので送らない

### 実施手順 / 手順 30: 補足: 値と、管理者の窓が conhost になる理由

- 値は、Windows Terminal の文書（グループ ポリシーの「既定のターミナル アプリケーション」）にある GUID。Windows Terminal は `DelegationConsole` が `{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}`、`DelegationTerminal` が `{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}`
- Windows 11 22H2 以降の既定は「Windows に任せる」（2 つとも `{00000000-0000-0000-0000-000000000000}`）で、Windows Terminal が入っていればそれを使う（Microsoft のサポートの記事）。この手順は、それを Windows Terminal に決める
- 管理者として起動したコンソールは、既定の端末に引き渡されず、conhost で開く。Windows Terminal の課題（microsoft/terminal の #13392。「管理者のコマンド ラインの受け手として登録できる端末は無く、COM の側の対応が要る」）が開いたまま。管理者の Windows Terminal は、Win+X の「ターミナル (管理者)」で開ける
- 設定の「システム」→「開発者向け」→「ターミナル」と、Windows Terminal の設定の「スタートアップ」→「既定のターミナル アプリケーション」でも変えられる

### 実施手順 / 手順 32: 補足: タスク マネージャーと同じ所に書く

- タスク マネージャーの「スタートアップ アプリ」と設定の「アプリ」→「スタートアップ」は、`Run` の値を消さずに、`Explorer\StartupApproved\Run` に同じ名前の値（バイナリ）を書く。先頭の 1 バイトが 2 なら起動し、3（と、止めた日時の 8 バイト）なら止める。Microsoft の文書には無いが、広く知られた形（UniGet UI のインストーラも同じ所に書く）
- OneDrive の値の名前は `OneDrive`、Edge は `MicrosoftEdgeAutoLaunch_<文字列>`。OneDrive は OneDrive の設定の「Windows にサインインしたときに OneDrive を自動的に開始する」でも止められる
- Teams（新しい Teams。手順 33 で外す）はパッケージのアプリで、起動のタスク `TeamsTfwStartupTask` の `State` を 1（「ユーザーが無効にした」）にする。値の意味は Microsoft の文書（`StartupTaskState`）にある
- 消すのではなく止めるので、タスク マネージャーからいつでも戻せる（[ロールバック](../windows-setup.md#ロールバック)の手順 8）

### 実施手順 / 手順 34: 補足: ウィジェットを外すこと

- ウィジェットの本体は、ストアのアプリ「Windows Web Experience Pack」（`MicrosoftWindows.Client.WebExperience`、ストアの ID は `9MSSGKG348SP`）。外すとボタンも消えると広く報告されている（Microsoft の文書には無い）
- ボタンだけを消す値（`TaskbarDa`）は、PowerShell からは書けない（手順 28 の補足）
- Microsoft が説明している止め方は、管理者のポリシー（「ウィジェットを許可する」）。本書では使わない

### 実施手順 / 手順 36: 補足: 変数について

- `$PC_NAME` は手順 39（PC の名前を変える）で使う
- `$LAN_IF` は、手順 37（今の状態）・手順 42（アダプターの省電力）・手順 43（プライベートにする）で使う。式は [Windows の OpenSSH サーバー](../windows-openssh-server.md)の手順 2 と同じ
- 接続の一覧は `Get-NetConnectionProfile` で見られる

### 実施手順 / 手順 37: 補足: 見ているもの

- `CtrlEnter` は、この窓の PSReadLine の Ctrl+Enter の働き。手順 19 のプロファイルを読んでいれば `AddLine`、読んでいなければ既定の `InsertLineAbove`
- `Edition` は `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion` の `EditionID`。`Core`・`CoreN`・`CoreSingleLanguage`・`CoreCountrySpecific` が Home、`Professional` などが Pro。Microsoft の文書では、Home はリモート デスクトップでつながれる側になれない
- `Sudo` は、Windows に入っている `sudo.exe` の場所。Microsoft の文書では、sudo は 24H2 以降
- `Hypervisor` は、Windows のハイパーバイザー（Hyper-V）が動いているか。WSL 2（手順 54）・メモリ整合性・Credential Guard などで動く
- `Get-DODownloadMode` は、配信の最適化のモード（`CdnOnly`・`Lan`・`Internet` など）

### 実施手順 / 手順 39: 補足: 名前の決まりと、確認の問いを出さないこと

- Windows の PC の名前は 15 文字まで（NetBIOS の名前の長さ）で、使える文字は英字・数字・ハイフン。先頭は英数字で、末尾はハイフンにしない（Microsoft の文書。数字だけの名前はドメインに入れない）
- `Rename-Computer` は、15 文字を超える名前だと「短くするが続けるか」を聞く（`-Force` で聞かない）。聞かれると、続けて貼った行が答えとして食われるので、ブロックで先に 15 文字までかを確かめて止める
- 今と同じ名前を渡すと、`Rename-Computer` はエラー（`NewNameIsOldName`）を出すので、先に比べる
- SSH・リモート デスクトップ・Syncthing は、この名前でこの PC を見分ける。Syncthing のデバイスの名前は最初の起動のときの PC の名前になるので、Syncthing より先に変える

### 実施手順 / 手順 40: 補足: 3 つの設定

- **長いパス**: `HKLM\SYSTEM\CurrentControlSet\Control\FileSystem` の `LongPathsEnabled` を 1 にすると、260 文字を超えるパスを、それを宣言したアプリ（マニフェストの `longPathAware`）が使える（Microsoft の文書）。エクスプローラーなど、宣言していないアプリは変わらない。プロセスが最初に使うときに読むので、効くのは手順 55 の再起動の後。Git for Windows には別に `core.longpaths` がある
- **開発者モード**: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock` の `AllowDevelopmentWithoutDevLicense` を 1（Microsoft の文書の `reg add` と同じ値）。管理者でなくてもシンボリック リンクを作れる（`mklink` や Git for Windows のように、作る側がその印を渡すとき）。Microsoft の文書では、レジストリで有効にしても、設定の画面で有効にしたときと違い、デバイスのポータルなどは入らない
- **sudo**: Windows 11 24H2 から Windows に入っている `sudo.exe`。`sudo config --enable` の形は 3 つ（Microsoft の文書）
  - `forceNewWindow`（既定）: 管理者のコマンドを新しい窓で動かす。Microsoft が勧める形
  - `disableInput`: 今の窓に出すが、入力を受け付けない
  - `normal`（インライン）: 今の窓で入出力する。Linux の sudo に近い。同じ窓のほかのプロセスが、管理者のプロセスを操作できるおそれがあると Microsoft は書いている
  - 利用者の選択で `normal` にした。値は `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo` の `Enabled`（0 が無効、1〜3 が上の順。microsoft/sudo のソース）
- 3 つとも、設定の「システム」→「開発者向け」（25H2 では「システム」→「詳細設定」）でも変えられる

### 実施手順 / 手順 41: 補足: どの設定で何が変わるか

- `standby-timeout-ac 0`: 電源につないでいる間、放置しても眠らない（`SUB_SLEEP` の `STANDBYIDLE` を 0 にするのと同じ。Microsoft の文書）
- `/hibernate off`: 休止状態を切り、`hiberfil.sys` を消す。高速スタートアップもこのファイルを使うので、使えなくなる（ハイブリッド スリープも）。Wake on LAN でシャットダウンから起こす（[任意節](../windows-setup.md#wake-on-lan-を使う任意)）には、高速スタートアップを切る必要がある
- `LIDACTION` を 0: 電源につないでいる間、蓋を閉じても何もしない（1 が眠る、2 が休止状態、3 がシャットダウン）。`/setactive SCHEME_CURRENT` で、今の電源プランに効かせる
- `CONSOLELOCK` を 0: 電源につないでいる間、眠りから戻ったときにサインインを求めない（既定は 1）。眠らないようにしても、手で眠らせたときのため
- `DelayLockInterval` を `0xFFFFFFFF`: Modern Standby（S0）の PC で、画面が消えた後のロック（設定の「アカウント」→「サインイン オプション」の「一定時間不在にした場合、もう一度サインインを求めるタイミング」）を「しない」にする。この値は Microsoft の文書に無く、広く使われているもの。S3 の PC では、画面が消えるだけではロックしない（ロックするのは、眠り・パスワード付きのスクリーン セーバー・ポリシー・動的ロック）
- Modern Standby の PC かは、`powercfg /a` に「スタンバイ (S0 低電力アイドル)」が出るかで分かる
- 元に戻すのは[ロールバック](../windows-setup.md#ロールバック)の手順 35（電源プランを既定に戻す。ほかに変えた電源の設定も戻る）

### 実施手順 / 手順 42: 補足: デバイス マネージャーの「電力の節約のために、コンピューターでこのデバイスの電源をオフにできるようにする」

- この手順は、デバイス マネージャーのアダプターの「電源の管理」タブの、上の項目を外すのと同じ
- `Set-NetAdapterPowerManagement` の文書にこの項目の引数は無く、`Get-NetAdapterPowerManagement` で取ったものの `AllowComputerToTurnOffDevice` を変えて渡す形は、広く使われているもの（Microsoft の文書には無い）
- `Set-NetAdapterPowerManagement` は、`-NoRestart` が無いとアダプターを起動し直す（Microsoft の文書）。SSH・リモート デスクトップでつないでいると切れるので、付ける
- この項目を外すと、Windows がアダプターに「この PC を起こす」を任せる設定（眠りからの Wake on LAN）も使えなくなる（Microsoft の古いサポートの記事）。シャットダウンからの Wake on LAN は UEFI とアダプターが行い、Windows は関わらないので、[任意節](../windows-setup.md#wake-on-lan-を使う任意)はこの手順と両立する
- 元に戻すのは[ロールバック](../windows-setup.md#ロールバック)の手順 34

### 実施手順 / 手順 45: 補足: リモート アシスタンス

- リモート アシスタンス（Windows の「クイック アシスト」とは別）は、ほかの人を招いて画面を見せる古い仕組み。システムのプロパティの「リモート」タブの「このコンピューターへのリモート アシスタンス接続を許可する」が `fAllowToGetHelp`
- グループの ID `@FirewallAPI.dll,-33002` は、Microsoft の文書には無い（Windows の `racpldlg.dll` の文字列にある）。違っていたら、`Get-NetFirewallRule | Sort-Object Group -Unique | Format-Table DisplayGroup, Group` で「リモート アシスタンス」の行の `Group` を見る
- Microsoft の無人インストールの文書は、`fAllowToGetHelp` の既定を無効と書いているが、店頭の Windows では有効なことが多いと報告されている。手順 37 の `RemoteAssistance` で、元の値を控える
- 元に戻すのは[ロールバック](../windows-setup.md#ロールバック)の手順 31

### 実施手順 / 手順 46: 補足: 自分で規則を作る理由

- Windows の既定では、ping（ICMPv4 の種類 8、ICMPv6 の種類 128）に応えない。組み込みの規則（「ファイルとプリンターの共有 (エコー要求 - ICMPv4 受信)」など）は無効で、「ファイルとプリンターの共有」の設定と一緒に変わる
- その規則を使わず、名前とグループ（`Ping (setup-notes)`）の決まった規則を作る。ほかの設定とぶつからず、消すときも分かる（[Syncthing の Windows 11 の節](../syncthing.md#windows-11-で使う)の規則と同じ形）
- 接続元は絞らない（`Any`）。プロファイルで決まるので、プライベートの LAN を通って届く、別のサブネット（WireGuard のクライアントなど）からの ping にも応える
- 元に戻すのは[ロールバック](../windows-setup.md#ロールバック)の手順 30

### 実施手順 / 手順 47: 補足: 配信の最適化

- 配信の最適化は、Windows Update とストアのアプリのファイルを、ほかの PC と分け合う仕組み。設定の「Windows Update」→「詳細オプション」→「配信の最適化」の「他のデバイスからのダウンロードを許可する」と同じ
- `Lan` は同じ NAT の後ろ（同じ LAN）の PC とだけ、`Internet` はインターネットの PC とも、`CdnOnly` は分け合わない。Microsoft の文書の既定は `Lan`（ポリシーの文書は 0 = HTTP だけと書いていて、文書の間で食い違う）
- `Set-DODownloadMode` は設定の画面と同じことをする（Microsoft の文書）。グループ ポリシーで決まっていると、そちらが優先される
- 元に戻すのは[ロールバック](../windows-setup.md#ロールバック)の手順 29

### 実施手順 / 手順 48: 補足: この設定と、リモート デスクトップ・SSH・自動サインイン

- 設定の「アカウント」→「サインイン オプション」の「セキュリティ向上のため、このデバイスでは Microsoft アカウント用に Windows Hello サインインのみを許可する」。値（2 がオン、0 がオフ）は Microsoft の文書に無く、広く使われているもの
- オンだと、Microsoft アカウントのパスワードでのリモート デスクトップに入れない、という Microsoft Q&A の回答がある
- オンだと、自動サインイン（手順 64）の設定に要る「ユーザーがこのコンピューターを使うには、ユーザー名とパスワードの入力が必要」の項目が隠れると報告されている
- 元に戻すのは[ロールバック](../windows-setup.md#ロールバック)の手順 22

### 実施手順 / 手順 49: 補足: 管理者の窓で書く理由と、効き目

- 自分のユーザーの設定（`HKCU`）だが、`HKCU\Software\Policies` の下は、管理者の権限が無いと書けない。管理者の窓も同じユーザーなので、自分の `HKCU` に書かれる
- Microsoft の文書では、このポリシーは「エクスプローラーの検索ボックスに最近の検索の項目を出さない」。スタートの検索から Web の結果が消えることは、広く報告されているもの（24H2 でも効くという報告と、効かないことがあるという報告がある）
- Windows 10 の `BingSearchEnabled` は、Windows 11 で効く根拠が見つからないので使わない
- 元に戻すのは[ロールバック](../windows-setup.md#ロールバック)の手順 23

### 実施手順 / 手順 51: 補足: Scancode Map の値

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
- スキャン コードはキーの位置で決まるので、US 配列（手順 53）でも JIS 配列でも、Caps Lock の位置のキー（`0x3A`）が Ctrl になる
- 値を 16 進の文字列で比べるのは、もう同じ値があるか（2 回目）と、ほかの割り当てがあるかを分けるため

### 実施手順 / 手順 53: 補足: キーボードの種類の値

- 日本語の Windows は、キーボードの種類（配列のドライバー）を PC 全体で 1 つ持つ。`HKLM\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters` の 4 つの値で決まり、名前は i8042prt（PS/2）だが、USB のキーボードにもかかる
- US 配列の値は、Microsoft の日本の社員のブログ（Learn に残っている「英語キーボードを快適に使う」）と同じ。設定の「時刻と言語」→「言語と地域」→「日本語」の「言語のオプション」→「キーボード レイアウト」の「英語キーボード (101/102 キー)」も、同じ値を書くと報告されている
- JIS 配列の値は、`kbd106.dll`・`PCAT_106KEY`・7・2（広く使われているもの）。手順 37 の `Keyboard` で、元の値を控える
- 手順 51 の Scancode Map は、キーの位置（スキャン コード）で変えるので、US 配列でも Caps Lock の位置のキーが Ctrl になる
- 元に戻すのは[ロールバック](../windows-setup.md#ロールバック)の手順 26

### 実施手順 / 手順 54: 補足: 入るもの

- Windows 11 では、`wsl --install --no-distribution` は Windows の機能「仮想マシン プラットフォーム」（`VirtualMachinePlatform`）を入れ、WSL のパッケージを入れる（WSL のソースの `WslInstall.cpp`）。WSL 1 の機能（`Microsoft-Windows-Subsystem-Linux`）は `--enable-wsl1` を付けたときだけ
- 機能を入れたときは、再起動が要る。この文書では手順 55 の再起動で済ませ、AlmaLinux 10 は手順 62 で入れる
- VirtualBox は、Hyper-V が動いていると、それを通して VM を動かす（NEM）。仮想マシン プラットフォームを外しても、メモリ整合性などで Hyper-V が動き続けることがある
- 元に戻すのは[ロールバック](../windows-setup.md#ロールバック)の手順 25

### 実施手順 / 手順 58: 補足: コマンドで外さない理由

- 自分のユーザーのピン留めを外す、サポートされたコマンドは無い。Microsoft の文書にある方法は、どれもポリシー（`ConfigureStartPins` やタスクバーのレイアウトの XML）か、新しいユーザーにだけかかるファイル
- タスクバーの設定（`Taskband`）やスタートのファイル（`start2.bin`）を消す方法は、Microsoft の説明が無く、形も決まっていないので採らない

### Wake on LAN を使う（任意） / 手順 3: 補足: シャットダウンからの Wake on LAN

- Microsoft の文書では、Windows 10 以降の既定のシャットダウン（高速スタートアップ）では、Windows はアダプターに起動を任せない。シャットダウン（S5）からの起動は、UEFI とアダプターだけが行い、Windows は関わらない
- そのため、高速スタートアップを切り（手順 41）、UEFI の Wake on LAN（機種によって「Power On By PCI-E」など）を有効にし、アダプターの詳細設定でマジック パケットを受けるようにする
- `*WakeOnMagicPacket` は、Microsoft の文書の標準の詳細設定の名前（1 で有効）。機種独自の項目（シャットダウンからの起動、リンクでの起動など）は、名前がアダプターごとに違う
- `-NoRestart` で、アダプターを起動し直さない（効くのは次の再起動から）
- 眠り（S3・Modern Standby）からの起動は、手順 41 で眠らないようにしたので扱わない

### ロールバック / 手順 15: 補足: 文字コードを変えずに消す

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
- 組み込みの受信規則「ファイルとプリンターの共有 (SMB 受信)」（`FPS-SMB-In-TCP`、TCP 445）を有効にする。既定では無効。ping の規則（手順 46）と同じく `-Profile Private` に絞る
- 再起動には 2 つの許可が要る
  - 「リモート システムからの強制シャットダウン」（`SeRemoteShutdownPrivilege`）。Administrators が既定で持つ。スタンドアロンのクライアントでは Administrators だけ
  - `LocalAccountTokenFilterPolicy = 1`。これが無いと、ローカル・Microsoft アカウントの管理者がネットワークログオンしたとき、UAC のリモート制限で絞られたトークンになり、再起動の権限を使えない（アクセス拒否になる）。1 にすると完全な管理者のトークンになる（UAC のリモート制限が緩む）
- ドメインに参加していない PC が対象なので、`-U '<user>%<pass>'` の資格情報はローカル・Microsoft アカウントのもの。Samba の `net` は `samba-common-tools` にある

### リモートから再起動する手段を増やす（任意） / 手順 5: 補足: WinRM を選ぶ理由

- `Restart-Computer -ComputerName` は、既定で WMI/DCOM（RPC のエンドポイント マッパー 135 と動的ポート）を使う。開けるポートが多く、絞りにくい
- 代わりに WinRM（WS-Management、TCP 5985）を有効にして、`Invoke-Command -ComputerName … { Restart-Computer -Force }` で再起動する。開けるのは 5985 の 1 つだけ
- `Enable-PSRemoting` は、WinRM のサービスの開始・リスナーの作成・受信規則の有効化に加えて、`LocalAccountTokenFilterPolicy` を 1 にする（この節の手順 4 と共有）。`-SkipNetworkProfileCheck` は、ほかにパブリックの接続があっても止まらないようにする（LAN はプライベートにしてある）
- 既定で作られる 2 つの規則のうち、`WINRM-HTTP-In-TCP-PUBLIC`（パブリック向けで、既定でローカル サブネットに絞られる）は無効にし、`WINRM-HTTP-In-TCP` をプライベートにする

### リモートから再起動する手段を増やす（任意） / 手順 6: 補足: 見張りタスクの作り

- ネットワークが切れても（OS は動いているが外から届かない）自分で再起動する。起動時と 5 分ごとに走るタスクで、`WATCHDOG_HOST`（既定はゲートウェイ）へ ping する
- SYSTEM・最上位の権限で動かす。SYSTEM は `SeShutdownPrivilege` を持つので、だれもサインインしていなくても再起動でき、ネットワークのサインインにも依らない
- 歯止め
  - 稼働 60 分未満なら何もしない。起動の直後に再起動を繰り返す（再起動ループ）のを避け、人が直す余地を残す
  - 連続して届かない回数を `HKLM:\SOFTWARE\setup-notes\net-watchdog` の `Fails` に記録し、6 回（約 30 分）でだけ再起動する。1 回でも届けば 0 に戻すので、一時的な切断では再起動しない
- 相手（ルーターなど）がずっと落ちていると、稼働 60 分ごとに再起動を繰り返す。`$limit` を増やすと猶予が延びる。相手は、LAN の中でいつも応答するものにする
- 起動時トリガーに 5 分ごとの繰り返しを足すため、`-Once` のトリガーの `Repetition` を起動時トリガーに移している（Windows PowerShell 5.1 の `New-ScheduledTaskTrigger` は、起動時トリガーに直接 `-RepetitionInterval` を取らない）

### リモートから再起動する手段を増やす（任意） / 手順 7: 補足: Remote Control を再起動後も使う

- [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)のタスクはトリガーが無く、手で `Start-ScheduledTask` したときだけ動く。再起動の後は戻らない
- ログオンのトリガー（`-AtLogOn -User <自分>`）を足すと、そのユーザーがサインインしたときに自動で始まる。自動サインイン（手順 64）と組み合わせると、無人の再起動の後も戻る
- タスクのトリガーだけを差し替える（`Set-ScheduledTask -Trigger`）。アクション・実行ユーザー・設定は変えない

### リモートから再起動する手段を増やす（任意）: 選択した方針

- **既にある接続（SSH・RDP・Remote Control）からの再起動を第一にし、それが使えないときの経路を足した**
  - SSH の sshd と RDP のサービスは再起動の後に自動で戻るので、再起動の引き金としても戻る口としても使える
- **別の PC からの再起動は、Linux からも使える SMB を主に、Windows 同士の WinRM を従にした**
  - SMB は AlmaLinux の `net rpc shutdown` でも Windows の `shutdown /m` でも使える。WinRM は Windows 同士で、開けるポートが 1 つで済む
- **電源・帯域外の手段（スマートプラグ + BIOS の通電時起動・IP-KVM・Intel AMT/vPro）は、この文書では扱わない**（利用者の選択）
  - 機器やマザーボードに依存し、設定が Windows の外になる。電源を切った後に起こすのは、既存の [Wake on LAN を使う（任意）](../windows-setup.md#wake-on-lan-を使う任意)が担う

### 参照

[検証記録](../verification/windows-setup.md#参考資料から分離した記録)

---

## VM での確認に伴う手順修正の根拠

- 手順 4・7: PSWindowsUpdate 2.2.1.5 は複数件の結果を 1 つの `Collection` として返す場合がある。`ForEach-Object { $_ }` で各更新を展開してから件数を数える。更新対象の Criteria と実際の適用コマンドは変えない。
- 手順 22〜24: 確認の [`winget list`](https://learn.microsoft.com/en-us/windows/package-manager/winget/list) も `--source winget` で導入元に絞る。source 未指定では `msstore` の初回の規約と地域情報の同意待ちになる場合がある。
- UniGet UI のユーザー向け [winget 定義](https://github.com/microsoft/winget-pkgs/blob/master/manifests/d/Devolutions/UniGetUI/2026.3.0/Devolutions.UniGetUI.installer.yaml)も `elevatesSelf` で、[インストーラー](https://github.com/Devolutions/UniGetUI/blob/v2026.3.0/InstallerExtras/CodeDependencies.iss)は Visual C++ Runtime などを必要に応じて導入する。共有 DLL の導入には[管理者権限が必要](https://learn.microsoft.com/en-us/cpp/windows/choosing-a-deployment-method?view=msvc-170)なため、ユーザー領域への導入でも管理者確認が出る場合がある。
- 手順 32 とロールバック 8: `OneDriveSetup` は初回導入の項目で、対象へ正確な名前を追加した。`Run` の値・実行ファイルを削除せず、`RunOnce` と Active Setup も変えない。[Run と RunOnce](https://learn.microsoft.com/en-us/windows/win32/setupapi/run-and-runonce-registry-keys)と [OneDriveSetup を初回導入に使う例](https://learn.microsoft.com/en-us/troubleshoot/sharepoint/lists-and-libraries/cannot-open-onedrive-on-images-using-sysprep)を参照（後者は Windows 10 の Sysprep の例）。実アプリの次回起動の確認とは分けて扱う。
- 手順 41: 確認には、隠れた電源設定も表示する `/qh` を使う。設定を書き込むコマンドは変えない。
- 手順 62・63: `WSL_UTF8` が出力側、`Console.OutputEncoding` がコンソールの読み取り側を指定する。Microsoft の [WSL 診断スクリプト](https://github.com/microsoft/WSL/blob/master/diagnostics/collect-wsl-logs.ps1)もこの 2 つを併用する。出力の可読性と WSL 2 の実起動の成否は別に判定する。

実施環境と再実行の結果は[検証記録](../verification/windows-setup.md#付録-windows-11-pro-の-vm-での導入検証2026-10-06)を参照。
