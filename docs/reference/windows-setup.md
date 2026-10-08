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
- 「設定アプリで通知を表示する」: 値（`SystemSettings\AccountNotifications` の `EnableAccountNotifications`）の資料は ElevenForum などだけ（広く）。24H2・25H2 の画面にあるかも確かめていない。手順 27 の `Start_AccountNotifications`（スタートのアカウントの通知）とは別
- 「検索のハイライトを表示する」: 手順 49 の `DisableSearchBoxSuggestions` で灰色になる（Microsoft Q&A の回答）。ポリシー（`EnableDynamicContentInWSB`）は管理者の窓が要り、同じく灰色にする
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

### 表示・入力・音・ストレージを変える（任意） / 手順 2: 補足: 控えのファイル

- `%LOCALAPPDATA%\setup-notes\display-before.csv` に、この節で変える値の、変える前の値を `Name`・`Value` の 2 列で書く。初めて貼ったときだけ作り、2 回目からは書き換えない（機能の更新の後に貼り直しても、元の値が残る）
- 控えを使うのは、この節の手順 16（切り替えのキー）・17（Alt+Tab とシェイク）・18（ギャラリーとホームのキーがあったか）・19（タスクの終了）。値が空なら、もとは値が無かった（戻すときは消す）
- 固定キーなどの `Flags`・`MinAnimate`・効果音のスキームは、確かめるために並べるだけ。戻すときは、`Flags` は今の値に 0x4 を立て（この節の手順 15）、アニメーションは決まった値（オンと `1`）に戻し（この節の手順 20）、効果音はこの節の手順 9 の `.reg` の控えを使う
- 読者が値を控えて手で入れる形にしなかったのは、値が多く、打ち間違えやすいため

### 表示・入力・音・ストレージを変える（任意） / 手順 3: 補足: Flags のビット

- `HKCU\Control Panel\Accessibility` の `StickyKeys`・`Keyboard Response`・`ToggleKeys` の `Flags`（REG_SZ の 10 進の数）。0x4 のビット（`SKF_HOTKEYACTIVE`・`FKF_HOTKEYACTIVE`・`TKF_HOTKEYACTIVE`）が、ショートカットで機能をオンにできるかを決める（文書。`STICKYKEYS`・`FILTERKEYS`・`TOGGLEKEYS` の構造体）
- 既定の 510 と、ショートカットを切った 506 は、Microsoft の 2007 年の Windows XP Embedded のブログ（文書。Windows 11 の既定かは確かめていない。広くも 510 とする）。126 → 122 と 62 → 58 は広く
- 既定の値に頼らず、今の値から 0x4 だけを落とすので、ほかのビットは変えない
- 型は REG_SZ のままにする（DWORD で書く例があるが誤り）。値が無いか数でないときは書かない（0 を書くと、機能を使える印 0x2 まで落ちる）
- 戻すときは、値を消さずに `-bor 4` で 0x4 を立てる。値を消したときの動きは文書に無い
- レジストリに書いただけでは、今のサインインには効かない（サインインし直した後に読む）。その間に設定の画面で切り替えると、メモリの値で書き戻されうる（推測）
- 切り替えキー（Num Lock の長押し）の秒数は、構造体の文書は 8 秒、サポートの記事は 5 秒と書いていて食い違う
- 同じ値は、Microsoft の DSC のリソース（`microsoft/winget-dsc` の `Microsoft.Windows.Setting.Accessibility`）も読み書きする（コード）

### 表示・入力・音・ストレージを変える（任意） / 手順 4: 補足: 切り替えのキーの値

- `HKCU\Keyboard Layout\Toggle` の 3 つの値（REG_SZ）。`1` が Alt+Shift、`2` が Ctrl+Shift、`3` が割り当てなし（文書。SystemParametersInfo の `SPI_SETLANGTOGGLE`）
- `Language Hotkey` が入力言語の切り替え、`Layout Hotkey` が同じ言語の中のキー配列の切り替え、`Hotkey` は古い名前で `Language Hotkey` と同じ値（ReactOS の input.cpl のコード。値の名前は Microsoft の文書に無い）
- 既定は広く `1`・`1`・`2` とされる（日本語版の値は確かめていない）。キーが無いユーザーもあるので、この節の手順 2 で控える
- 日本語の IME だけの PC では、ふだんは切り替える先が無い。タスクバーに「英語 (米国)」が勝手に出たときや、後で英語の配列を足したときに、Ctrl+Shift・Alt+Shift を押して離すだけで切り替わるのを防ぐ。WezTerm の自分用の設定は、Ctrl+Shift の組み合わせを多く使う
- Win+Space（入力言語とキー配列を順に切り替える）は、この値では消えない（サポートの記事）。誤って切り替わったときに戻す手段として残る
- 文書では、値を書いてから `SPI_SETLANGTOGGLE` を呼ぶと読み直す。この節では呼ばず、サインインし直して効かせる

### 表示・入力・音・ストレージを変える（任意） / 手順 5: 補足: Alt+Tab とシェイクの値

- `Explorer\Advanced` の `MultiTaskingAltTabFilter`: 0 がすべて（今は最新の 20 個）、1 が 5 個、2 が 3 個、3 が窓だけ（広く。Winaero・ElevenForum）。値が無いときの既定は、資料で 3 個と 5 個に割れる
- 同じことをするポリシー（`BrowserAltTabBlowout`）は文書にあるが、番号が 1 つずれ（4 が窓だけ）、preview の扱いで、Alt+Tab にだけ効く。ユーザーの値は、スナップの候補にも効く
- `DisallowShaking` が 1 でシェイクを切る。build 21286 から既定で切れている（Windows Insider のブログ）。1 がオフの意味は広く。日本語の画面の名前は「タイトル バー ウィンドウのシェイク」（広く）

### 表示・入力・音・ストレージを変える（任意） / 手順 6: 補足: ギャラリーとホームを消す仕組み

- `System.IsPinnedToNameSpaceTree` が 0 だと、その名前空間の拡張を消さずに、ナビゲーション ウィンドウに既定では出さない。「すべてのフォルダーを表示」で出る（文書。Integrate a Cloud Storage Provider）
- `HKCR` は `HKLM\SOFTWARE\Classes` と `HKCU\Software\Classes` を合わせた見え方で、両方にあるキーは合わさり、`HKCU` の値が勝つ（文書。Merged View of HKEY_CLASSES_ROOT の例）
- ギャラリーの CLSID `{e88865ea-…}` とホームの `{f874310e-…}` は広く（winutil・WinSetView・winscript など）。手順 26 と同じく、Microsoft が説明していない使い方
- `HKCU\Software\Classes\CLSID` は WOW64 でリダイレクトされる（文書）ので、32 ビットの PowerShell から書くと別の場所に入る。32 ビットのアプリのファイルを開く画面には、残ることがある（推測）
- 2024 年 6 月の更新の後に効かなくなったという報告と、25H2 に上げた後にホームが戻ったという報告が 1 件ずつある（広く。確かめていない）
- 2 つを 1 つの手順にしたのは、同じ値・同じ仕組みで、確かめ方も同じため。手順 25 の `LaunchTo` = 1 で、エクスプローラーを開いたときも「PC」になる

### 表示・入力・音・ストレージを変える（任意） / 手順 7: 補足: タスクの終了

- `Explorer\Advanced\TaskbarDeveloperSettings` の `TaskbarEndTask` = 1。Microsoft の WindowsDeveloperConfig の設定スクリプトが、同じキーと値を書く（コード）
- 機能は KB5031455（2023-10、22621.2506・22631.2506）で足された（文書）。25H2 以降は「開発者向け」のページが「詳細設定」に変わった（文書。Windows の詳細設定）
- 開発者モード（手順 40）は要らない

### 表示・入力・音・ストレージを変える（任意） / 手順 8: 補足: UserPreferencesMask ではなく SystemParametersInfo を使う理由

- 設定の「アニメーション効果」は、アプリには `SPI_GETCLIENTAREAANIMATION`（0x1042）として見える（MDN の `prefers-reduced-motion` の説明と、Chromium の `animation_win.cc`）。値は `HKCU\Control Panel\Desktop` の `UserPreferencesMask`（8 バイトの REG_BINARY）の 5 バイト目の 0x02 のビット（Wine の `sysparams.c`）
- `UserPreferencesMask` は、メニューのフェード・ClearType など多くのビットを 1 つの値に詰めている。丸ごと書く例（Microsoft Q&A の回答など）は、ほかのビットまで変える
- `SystemParametersInfo` に `SPIF_UPDATEINIFILE`（1）と `SPIF_SENDCHANGE`（2）を付けて書かせると、そのビットだけを変えてプロファイルに残し、開いている窓に知らせる（文書）
- 最小化・最大化のアニメーションは `SPI_SETANIMATION`（0x0049）の `ANIMATIONINFO` の `iMinAnimate` で、`HKCU\Control Panel\Desktop\WindowMetrics` の `MinAnimate`（REG_SZ、既定 `1`）に入る（文書）
- `Add-Type` で `user32.dll` の `SystemParametersInfo` をその場でコンパイルして呼ぶ。同じ定義なら、同じ窓で貼り直しても止まらない。制約付き言語モードの PC では使えない
- 設定の画面がほかに何を書くか（メニュー・コンボ ボックスのアニメーションのビットなど）は、文書に無い。この手順では変えない
- 切ると、Firefox・Chromium は Web ページに `prefers-reduced-motion: reduce` を返す

### 表示・入力・音・ストレージを変える（任意） / 手順 9: 補足: 効果音の控えとスキーム

- サウンドの画面でスキームを選ぶと、`HKCU\AppEvents\Schemes` の既定の値にスキームの名前（「サウンドなし」は `.None`、「Windows 標準」は `.Default`）を書き、`Schemes\Apps\<アプリ>\<イベント>` ごとに、そのスキームの音を `.Current` に写す。`.None` には音が無いので、`.Current` を空にするのと同じ（古い Microsoft の文書・Scripting Guy の記事と、広く使われているスクリプト）
- 先に `reg.exe export` で `HKCU\AppEvents` を丸ごと控えるのは、イベントごとの元の音を、`.Default` が無いものやアプリが自分で書いたものも含めて戻すため。画面で「Windows 標準」に戻すと、`.Default` が無いイベントは空のまま残る
- 控えは初めて貼ったときだけ作る。2 回目に貼っても、「サウンドなし」にした後の状態で上書きしない
- 戻すときの `reg.exe import` は、控えにある値を書き戻す。控えの後に足されたイベントは、空のまま残る

### 表示・入力・音・ストレージを変える（任意） / 手順 10: 補足: 起動音をレジストリで変えない理由

- 起動音はサインインの前に鳴るので、ユーザーごとではなく PC 全体の設定（`HKLM`）
- レジストリの値は、資料どうしで食い違う（`BootAnimation` の `DisableStartupSound` と `EditionOverrides` の `UserSetting_DisableStartupSound`。多くは 1 が鳴らさない側だが、Winaero は別の値を書く。どれも広く）。ポリシー（「Windows スタートアップのサウンドをオフにする」）は Policy CSP の一覧に無い
- そのため、サウンドの画面のチェックで行う。`control.exe mmsys.cpl,,2` は、サウンドの画面を「サウンド」のタブで開く（広く）。PowerShell ではカンマが配列の区切りになるので、引数を引用符で囲む
- 手順 41 で休止状態を切った（高速スタートアップも無くなる）ので、起動のたびに鳴るはず（推測）

### 表示・入力・音・ストレージを変える（任意） / 手順 11: 補足: ストレージ センサーの値

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
- 22H2 以降の既定では、OneDrive のファイルは 30 日開かないとオンラインだけになる（サポートの記事）。OneDrive のアカウントごとの値（`StoragePolicy` の下の `OneDrive!…` のサブキー）は、名前がアカウントで変わり、資料も少ないので、画面で外す（この節の手順 12）
- キーが無いときだけ作る。既にあるキーを作り直すと、OneDrive のサブキーなども消える
- PC 全体のポリシー（`HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense` の `AllowStorageSenseGlobal`）があると、そちらが勝つ

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
- 手順 32 の `Run` の `MicrosoftEdgeAutoLaunch_<文字列>` は、Chromium のサインインのときの起動の仕組み（バックグラウンドの実行で使う）が書く（Chromium のコード）。ポリシーを置いた後に値が消えるかは確かめていない
- Edge Update の、サインインのときのコマンド（`on-logon-startup-boost`・`on-logon-autolaunch`）でも、Edge が起動することがある（広く）。文書に無いので変えない
- 必須のポリシー（`HKLM\SOFTWARE\Policies\Microsoft\Edge`）を置くと、Edge は組織が管理している旨を出し、その切り替えを灰色にする（表示の日本語の文言は広く）
- 手順 50 の `RemoveDesktopShortcutDefault` は `HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate`（Edge Update が読む）で、別のキー
- `Edge` のキーが無いときだけ作る（既にあるキーを `New-Item -Force` で作り直すと、ほかの Edge のポリシーが消える）。戻すときも、キーは消さずに 2 つの値だけを消す
- ドメイン参加か MDM の登録が要るポリシーには、その旨の注記がある。2 つのポリシーの文書には無いので、家庭の PC でも効くはず（確かめていない）

### Edge の常駐をポリシーで止める（任意）: 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **`HKLM` の必須のポリシー** | 手順 50 と同じ `HKLM`。効き目がはっきりし、`edge://policy` で確かめられる。管理の表示が出て、切り替えが灰色になる | **採用** |
| 推奨のポリシー（`Edge\Recommended`） | 利用者が一度でも切り替えていると効かない（文書）。管理の表示が出るかは資料が無い | 不採用 |
| `HKCU` のポリシー | 書くのに管理者が要るのは同じ。両方あると `HKLM` が勝つ（Chromium の文書） | 不採用 |
| Edge の設定の画面 | 管理の表示は出ない。Edge が自分でオンに戻すことがあるかは、資料が無い | 代わりの手順（この節の手順 3） |
| 旧 Edge の `AllowPrelaunch` など | EdgeHTML の Edge のポリシーで、今の Edge には効かない | 不採用 |

### CopyQ を使う（任意） / 手順 2: 補足: 入れ方と入る場所

- winget の `hluk.CopyQ`（2026-10-08 の定義は 16.0.0。上流の最新は 17.0.0）は Inno Setup のインストーラ。`--scope user` は `/CURRENTUSER` を渡し、`%LOCALAPPDATA%\Programs\CopyQ` に入る
- `/CURRENTUSER` は winget の定義。入る場所は、`copyq.iss` の `{autopf}\CopyQ` を、Inno Setup が自分のユーザーの導入で `%LOCALAPPDATA%\Programs` にするため
- インストーラは `PrivilegesRequiredOverridesAllowed=dialog` なので、管理者の確認を出さずに自分のユーザーに入れられる（`shared/copyq.iss` と Inno Setup の文書）。winget の定義は `elevatesSelf` で、winget は UAC が出るかもしれない旨を出すだけで、自分では昇格しない（winget の文書）
- デスクトップのショートカットとスタートアップのタスクは既定で外れていて、入れた後の起動は `postinstall skipifsilent` なので、黙って入れると起動しない。PATH には入らない
- 自分のユーザーにしたのは、手順 22・23 の UniGet UI・PowerToys と同じく、管理者が要らず、ほかのユーザーにかからないため。更新も、管理者ではない窓の `## 更新` の winget で上がる
- 17.0.0 は、データを `%LOCALAPPDATA%\copyq` に移し、前の版では読めなくなる（`CHANGES.md`）
- 前に別の場所へ入れた CopyQ があると、インストーラはその場所に入れる（`UsePreviousAppDir`）。そのときは、この節の手順 3・4・7 の決め打ちのパスが外れる

### CopyQ を使う（任意） / 手順 4: 補足: 自動の起動の仕組み

- `copyq config autostart true` は、スタートアップ フォルダー（`CSIDL_STARTUP`）に `copyq.lnk` を作る（`winplatform.cpp`）。手順 32 の `Run` とは別の所なので、手順 32 の一覧には出ない
- CLI の `config` は、値が変わったときだけショートカットを作る（`ConfigurationManager::setOptionValue`）。`copyq.ini` に `autostart=true` が残っていて `copyq.lnk` が無いと、`true` を送っても作られない。先に `false` を送るのはそのため
- アンインストーラは `copyq.lnk` を消さない（スタートアップのタスクを選んだときだけ、アンインストールの記録に入る）
- `copyq.exe` は窓を持つアプリ（GUI のサブシステム）なので、PowerShell は結果を出さずに戻る。`| Write-Output` を付けると、終わるまで待って結果を出す（CopyQ の known-issues）。`| Out-Null` は、終わるまで待って結果を捨てる
- 起動を別の手順（この節の手順 3）にしたのは、`--start-server` に `| Write-Output` を付けると、裏で動き続けるサーバーが標準出力のパイプを持ち続け、窓が戻らないおそれがあるため（Qt の `startDetached` のコード。確かめていない）。クライアントがサーバーを待つのは、既定で 1 秒だけ
- `EnableClipboardHistory`（`HKCU\Software\Microsoft\Clipboard`）の名前は広く。Windows の履歴が既定でオフなのは文書（サポートの記事）

### CopyQ を使う（任意） / 手順 6: 補足: 避けるキーと貼り付け

- CopyQ のグローバル ショートカットは `RegisterHotKey` を使う。Windows キーを含むキーは OS が予約していて、ほかが登録済みのキーと同じく失敗することがある（文書）。失敗はサーバーの記録に出るだけで、画面には出ない（コード）
- 手順 23 の PowerToys の高度な貼り付けは、既定で Win+Shift+V と Ctrl+Win+Alt+V を使う（文書）。Ctrl+Shift+V は、Windows 11 の書式なしの貼り付けのキー（サポートの記事）
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

---
