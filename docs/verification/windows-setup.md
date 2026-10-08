# Windows 11 の初期設定の手順（インストール直後の更新・貼り付けの設定・scoop・UniGet UI・表示・電源・リモート・WSL）の検証記録

[手順書](../windows-setup.md)

## 最新の検証範囲（2026-10-08 UTC）

**Windows の実機では全手順を通していない。新規の Windows 11 Pro 26H2 の VM での検証結果。**

- 2026-10-08 の追加検証（[付録](#付録-pr-104-の未検証項目を同じ-vm-で確かめた記録2026-10-08)）
  - GitHub のコピーボタンからの貼り付け（管理者の conhost・Windows Terminal）、手順 35・55〜61・64 の画面、手順 39・52・53 の分岐
  - 2 枚目の NIC（ホストオンリー）での ping と、RDP のログイン・`tscon`
  - Wake on LAN の節の手順 2〜4・8、リモートから再起動する節の手順 2〜11（AlmaLinux の VM からの SMB・WinRM の実トリガーと、見張りタスクによる再起動）
  - 更新の手順 1〜5、ロールバックの手順 1〜41
  - 直した本文: 手順 9・58・59・60、Wake on LAN の節の手順 4、再起動の節の手順 5・6・9・11、ロールバックの手順 9・13・21（管理者ではない窓で行う）・31・35・36 とリード
  - 撤去の前にスナップショット `pr104-before-rollback-20261008` を撮った
- 2026-10-08 の追加検証その 2（[付録](#付録-別の-windows-からの再起動とwinrm-の手順-5-の貼り直しを確かめた記録2026-10-08)）
  - 別の Windows（ホストの実機）から、再起動の節の手順 4 の `net use` と `shutdown /m`、手順 5 の `TrustedHosts` と `Invoke-Command` で、VM を実際に再起動した
  - 再起動の節の手順 5 を、以前の版の同じ節の手順 9 の後に貼り直すと止まることを確かめ、手順 5・9 を直した
  - 直した本文: 再起動の節の手順 4・5・9
  - 相手の VM のリンク クローンは、正しい資格情報でも NTLM が拒否され（4625 の状態 `0xc000006d`・副状態 `0x0`）、送る側に使えなかった。sysprep をしていないのでマシンの SID の重複が原因とみたが、確かめていない
- 2026-10-08 の時点で確認していないこと
  - Store の CLI の準備と更新の適用（手順 11・12・14）、Windows Update の再起動の分岐（手順 8）。2026-10-08 には対象の更新が無かった（手順 5 の適用は 2026-10-06 に確かめた）
  - WSL 2 の AlmaLinux 10（手順 62・63、更新の手順 4 の `dnf -y upgrade`、ロールバックの手順 17）。この VM の仮想化の制約で動かない
  - Wake on LAN の UEFI の設定とマジック パケットでの起動
  - 別の Windows の `Get-Credential` の窓での資格情報の入力（`PSCredential` で渡した）、`-ComputerName`・`TrustedHosts` を IP にしたとき、この PC と同じ名前・同じパスワードのローカル アカウントから `net use` 無しで `shutdown /m` を送ったとき、Microsoft アカウントの PC を再起動される側にしたとき
  - Windows の実機での通し実行
- 以下は 2026-10-06〜07 の検証の要約（[付録](#付録-windows-11-pro-の-vm-での導入検証2026-10-06)）。そのときの「未検証」は、2026-10-08 の付録で多くを確かめた
- 初期設定は Windows Update の 4 件の適用と残り 0 件、Store の更新なし、Scoop・UniGet UI・PowerToys・PowerShell 7 の導入、指定値の読み戻しと一部の実画面を確認した。56〜60 と通常権限の Windows PowerShell 5.1 への LF 3 行の貼り付け順は、利用者の手動確認を含む。343 文字のパスとシンボリックリンクの作成・読み取り・削除も、通常権限の PowerShell 7.6.6 で確認した。
- 追加の 5 項目は次の限定した範囲で成功した。

  1. Git: 子 Bash の global 設定と使い捨てリポジトリに隔離し、12 キーの設定と、実 rebase・autostash・日本語ファイル名・CRLF・最初の push を確認した。機能試験は 14 フェーズ・9 検査が成功した。初回のホストの待ち時間切れとコピー失敗を残し、同じ実行の正常終了を後から回収した。本人の設定・対話的な Git Bash・外部の認証を伴う接続は未検証。
  1. WezTerm / HackGen: 2 ファミリーの各 6 文字、計 12 glyph が自身の DirectWrite フォントを使い、欠損のない glyph と画素を CLI で生成した。GUI のフォント一覧・描画の見た目・右クリックの実操作は未確認。
  1. WireGuard: ローカルの鍵生成・公開鍵の対応・ACL と、管理サービスの CLI による一時的な起動・削除を確認した。鍵・サービス・プロセスは削除し、新規の Data は保持した。GUI・VPN 接続・外部との疎通は未確認。
  1. RDP: TCP 到達・CredSSP の選択と必須、公開証明書の SHA256・名前・有効期間を照合した TLS 1.3 の確立まで確認した。一時転送と待受けは撤去済み。資格情報の送信・認証後のログイン・ping は未確認。
  1. スタートアップ: 新規の Run 2 項目と StartupApproved の先頭バイト 2/3、通常の OS 再起動 1 回で、有効側の起動と無効側の記録の不在を確認した。初回の両記録なし・終了コード 33 は履歴として保持し、有効側の遅延起動後に再観測して合格とした。専用の値 4 件とディレクトリは撤去済み。OneDrive・Teams 本体の次回起動の効果へは広げない。

- WSL はパッケージ・機能の導入まで成功したが、AlmaLinux 10 の実起動と入れ子の VM は、この VM の仮想化機能の公開範囲による制約で失敗した。復旧比較後は 2 CPU のままで、4 CPU に戻す再試験とホストのセキュリティ変更は行っていない。
- Autologon は本文と補助タスクの起動要求が取消で終了した履歴を残す。その後の利用者による Explorer 経由の手動起動・設定と、2 CPU の通常再起動で無入力の自動サインインを確認した。元の起動経路の成功には置き換えない。
- Firefox と既定ブラウザー、HackGen の GUI、ゲスト内の VirtualBox Manager は利用者に確認を依頼済みで回答未取得。残る GUI、Claude Code の認証、GitHub の直接コピー経路と管理者窓への貼り付け、未実施の分岐・任意節・更新・ロールバックも未検証。
- 生の証跡・実行用ハーネスはローカルの .verification/ に保管し、この PR には含めない。以下の evidence/... は .verification/evidence/... 内の記録を指す。本文の結果要約とハッシュを公開し、秘密値は記載しない。

以下は文書分離前から保存されている過去の記録です。「未検証」「未確認」は、それぞれの実施時点の範囲を指します。最新の結果は上の要約と、末尾の 2026-10-06 と 2026-10-08 の VM 検証付録に従い、実施日・対象版・実行範囲を区別します。

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
> 出力例・表の中の値は `<WIN_USER>`（Windows のユーザー名）/ `<HOSTNAME>`（コンピューター名）/ `<hostname>`（`whoami` が小文字で出すコンピューター名）/ `<HOST_PC>`（VM を動かしたホストの PC のコンピューター名。別の Windows から再起動した付録では送る側）/ `<OTHER_PC>`（引き継ぎ先として準備した別の PC の名前）/ `<LAN_IF>` / `<名前>` / `<版>` のプレースホルダで書いてある。パスワード・回復キーはこの文書に載せない。

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

## 付録: Windows 11 Pro の VM での導入検証（2026-10-06）

**VM での部分検証結果**。利用者の希望で一度中断し、`<OTHER_PC>` への引き継ぎを準備した。その後の「やはりこのホストで作業を再開してください。」により、`<HOST_PC>` の元の VM で再開した。手順 2〜7・10・13・15〜30・32〜34・61 の CLI 実行と値の読み戻し、管理者設定（40〜51）を確認した。31 の設定と 56 の Caps Lock・Ctrl+Space は利用者が手動で確認した。32 は修正版の実行と値の読み戻し、55 の OS 再起動はログで確認し、57 の Explorer・タスクバーなどの一部を実画面で確認した。WSL（54）はパッケージ・機能の導入まで成功したが、62・63 と VirtualBox の入れ子の VM の実起動は検証環境の制約で未達。64 は Autologon の導入・実体・署名・UAC の画面を確認したが、本文と補助タスクの起動要求は取消で終了した。その後、利用者が Explorer から手動で起動・設定し、2 CPU の通常再起動で無入力の自動サインインを確認した。本文の起動経路が成功した結果とは扱わない。その後、Bing の結果なし（57）、不要な Edge/Store のピン解除（58）、WinGet/Scoop 有効と scoop-search/UniGetUI の導入済み一覧（59）を利用者が手動で確認した。さらに、59 のスタートからの起動と WinGet/Scoop の GUI の版表示、60 の通常権限の Windows PowerShell 5.1 のスタートからの起動、LF 3 行の右クリック貼り付け順を利用者が手動確認した。貼り付けは 16〜19・38 の確認として今回の fixture の範囲に限定する。AI の画面確認、ピン解除の正確な文言、GitHub の直接コピー経路・管理者窓への貼り付けと残る GUI の効果、認証後の RDP ログインと ping は未確認。追加の事前交渉では TCP 到達と CredSSP の選択・必須を確認し、通常権限の PowerShell 7 で長いパスとシンボリックリンクの実操作も確認した。Git の共通手順による 12 キーは試験用の global 設定で検証し、本人の設定には反映していない。14 は条件により飛ばし、実適用は未確認。57〜60 と貼り付け fixture の手動確認は回答済みで、この範囲の結果を記録した。追加の Firefox・既定ブラウザー・HackGen の GUI・ゲスト内の VirtualBox Manager は回答待ち。Windows の実機で全手順を通した記録ではない。

**環境と導入元**:

| 項目 | 値 |
|---|---|
| インストール媒体 | 利用者が Rufus 4.15.2396 の画面で専用の 16 GiB VHD に作成し、USB の記憶装置として VM に接続した |
| ISO | Microsoft 公式の日本語の製品版。SHA256 は `923EC1A2EC46CCBE607FC81BEAF9753BFBB6FC62220B7B8BFFD56E66F6DE3A0C` |
| OS | Windows 11 Pro 26H2、26300.9457、x64 |
| VM | VirtualBox 7.2.20、メモリ 8 GiB、当初 CPU 4 個、復旧比較後は 2 個のままで 4 個に戻す再試験は未実施、EFI・Secure Boot・TPM 2.0。Hyper-V の NEM バックエンド |
| 導入先 | 新規の 256 GiB ディスク。単独の Windows の VM で、デュアルブート向けのパーティション作成は試していない |
| ユーザー | ローカル アカウント `<WIN_USER>`、Administrators の一員 |
| PowerShell | Windows PowerShell 5.1、x64。デスクトップにサインインした対話タスクで実行した。当初は Session 2、手順 15 は復旧後の Session 1 |
| 検証用の追加物 | Guest Additions と検証コードは別の DVD から導入した。Rufus の元媒体は変更していない。利用者の要望により、専用 VM の検証用パスワードを変更した |
| 導入前の基準記録 | Guest Additions の導入前に採取した読み取りの JSON。保護した原記録の SHA256 は `F0465DE273E11E84517816E20DEAFC71A87520875C6D8DD017ABF29B47211C0C` |

- Rufus の 7 項目は生成された回答ファイルで確認した。回答ファイルは `boot.wim` のイメージ 2 の `Autounattend.xml` にあり、7 項目すべての最終的な効果を証明した記録ではない

**実行方法**:

- 本文の折り畳みの外にある PowerShell ブロックを抽出し、コマンドを変えずに `Invoke-Expression` で順番に実行した。同じ実行グループ内では、手順 20 を除いてスコープを共有した。手順 20 はインストーラーが dot-source と判定しないよう別のスコープで呼び、同じプロセスの環境変数を引き継いだ
- 手順 2〜7 と PC 全体の設定は管理者、手順 10・13・15〜30・32〜34 は通常権限の対話タスクで実行した。手順 31 の IME の設定は利用者が画面で行った。手順 1・9・35 の画面操作と本文の貼り付けはタスクで代替した。その後、60 の通常窓の起動と、メモ帳からの LF 3 行 fixture の右クリック貼り付けは利用者が手動確認した。GitHub の直接経路・管理者窓への貼り付けは未試験
- 出力・エラー・終了コードと、実行前後の読み取りの状態を採取した。検証用コードの実行準備は、本文の設定が効いたという判定には使っていない

**確認できた結果**:

| 手順 | 実際の結果 |
|---|---|
| 2・3 | NuGet 2.8.5.208 と PSWindowsUpdate 2.2.1.5 の初回導入・読み込みが成功した |
| 4（修正前） | 表には KB5007651・KB890830・KB2267602 の 3 件が出たが、件数の表示は 1 件だった。検索結果の 1 要素が `Collection<PSObject>` で、その中に 3 件を持つことを診断で確認した |
| 4・7（修正後） | 検索結果を `ForEach-Object { $_ }` で展開するように直した。実検索の 1 件・0 件は正しく表示・判定した。修正後の 3 件の表示は、型の診断と Windows PowerShell 5.1 の模擬で確認した範囲で、実更新前の 3 件では再検索していない |
| 5・6 | 元の手順のまま 2 回実行した。KB5007651・KB890830・KB2267602・KB4052623 の計 4 件がすべて `Installed` になり、再起動待ちは `False` だった |
| 7（修正前） | 最初の 3 件を適用した後は KB4052623 が残り、再度適用した後は残り 0 件・確認完了・再起動待ちなしになった。0 件は元のコードでも正しく判定した |
| 7（復旧の再起動後） | 管理者の手順 2・3・7 のバッチ `20261006-084631Z-30eaa70d` はすべて完了し、エラーは 0 件。手順 7 の実出力は更新 0 件・再起動待ちなしだった |
| 10 | 通常権限の Session 2 で成功した。`winget.exe` と `store.exe` が使えた |
| 11・12 | Windows Update の作業中に Store が 22506.1400.2.0 から 22608.1401.5.0 へ自動更新されたため飛ばした。古い Store から CLI を準備する分岐は未検証 |
| 13（初回） | `updates --help` の終了と `--apply` 対応を確認した。再起動後に回収した初回のログには `Updates available (31 found)` と `Store-managed updates available for bulk installation`、App Installer・Terminal など 31 件の全一覧があった。この初回は CLI の自然終了と終了コードを確認できず、強制停止で中断した |
| 13（再起動後の再実行） | 通常権限の手順 10・13 のバッチ `20261006-084901Z-83141775` は正常終了し、手順 13 は `No updates found.` を明示した。エラーの記録は空配列、CLI の終了コードは 0 だった |
| 14 | 手順 13 で更新なしを明示したため、条件により飛ばした。`store updates --apply` の実適用は未検証 |
| 15 | 再サインイン後の通常権限の Session 1、Windows PowerShell 5.1.26100.9444 でバッチ `20261006-101014Z-da3b4e6d` を実行した。`No updates found.`、App Installer 1.29.379.0 と Terminal 1.24.12741.0 の `Ok`、winget v1.29.380 を確認。エラー 0 件・CLI の終了コード 0・タスク結果 0 で正常終了し、終了記録も今回のバッチに対応した |
| 16・17 | バッチ `20261006-101122Z-361fe6d7` を通常権限で実行した。初期状態は Scoop・Git なし、ClassicMenu は `False`、Scancode Map なし、プロファイルなし。実行ポリシーの全範囲は `Undefined`、実効値は `Restricted` だった。手順 16 の設定コマンドはエラーなく無出力で終了した |
| 18・19 | 実効の実行ポリシーは `RemoteSigned` になり、既定のプロファイルへ印付きの 1 行だけを追加した。バッチ全体はエラー 0 件・タスク結果 0 で終了記録も一致した。続く新しい PowerShell のバッチで `RemoteSigned` と Ctrl+Enter の `AddLine` を確認し、プロファイルが読み込まれることを確認した。その後、通常窓での LF 3 行 fixture の右クリック貼り付け順を利用者が手動確認した。GitHub の直接経路・管理者窓は未試験 |
| 20・21 | 通常権限の Session 1 のバッチ `20261006-102102Z-85dd008c` で、`Initializing...` に続き `Scoop was installed successfully!` を確認した。Scoop v0.6.0（2026-09-30）、main バケット（1,669 件）、ユーザーの `PATH` に `C:\Users\<WIN_USER>\scoop\shims` を確認。エラー 0 件、手順 21 の終了コード 0・タスク結果 0 で終了記録も一致した |
| 22（初回の一覧確認中断） | バッチ `20261006-102229Z-e5e945ca` で scoop-search 2.1.0 と UniGet UI 2026.3.0 の導入が成功した。利用者が Visual C++ ランタイムの管理者確認を許可した後、`Successfully installed` が出た。続く source 未指定の `winget list` は `msstore` の規約と地域情報の初回同意待ちになり、対象 CLI を操作側で中断した |
| 22（修正後の再実行） | 通常権限の Session 1 のバッチ `20261006-103736Z-d0d5c6cc` は、scoop-search は既存、UniGet UI は既存で新しい版なしと表示した。`--source winget` を付けた一覧は UniGetUI・Devolutions.UniGetUI・2026.3.0 を正常に表示した。エラー 0 件・終了コード 0・タスク結果 0 で終了記録も一致した。初回導入のやり直しではなく、既存の導入の確認だった |
| 23 | 通常権限の Session 1 のバッチ `20261006-103844Z-c2c5935a` で PowerToys 0.101.2362.0 のハッシュ確認・初回導入・一覧表示が成功した。HKCU の登録と `%LOCALAPPDATA%\PowerToys` の本体の存在・FileVersion 0.101.2362.0 を確認。10:40:04.713 UTC にエラー 0 件・終了コード 0・タスク結果 0 で終了し、終了記録も一致した |
| 24 | 通常権限の Session 1 のバッチ `20261006-104359Z-4a9f9dd6` で PowerShell 7.6.6.0 のハッシュ確認・初回導入・一覧表示が成功した。ユーザーの MSIX は `Microsoft.PowerShell_8wekyb3d8bbwe`、Status は `Ok`、版は 7.6.6.0。WindowsApps の `pwsh.exe` と `PowerShell 7.6.6` の表示を確認した。10:45:16.137 UTC にエラー 0 件・終了コード 0・タスク結果 0 で終了し、終了記録も一致した |
| 25〜30 | バッチ `20261006-104548Z-b74ba246` はすべてエラー 0 件・タスク結果 0 で終了記録も一致した。10:54:13.309 UTC の独立の読み取りもエラー 0 件で、指定したレジストリの全値と型を確認した。GUI の効果は未確認 |
| 31 | 利用者が IME のオン・オフを Ctrl+Space に設定し、設定画面を閉じたことを確認した。IsKeyAssignmentEnabled=1・KeyAssignmentCtrlSpace=2 を DWORD で読み戻した。その後の手順 56 では利用者が実際のキー入力も確認した |
| 32（修正前） | 通常権限のバッチ `20261006-111347Z-f222f42c` で Edge の MicrosoftEdgeAutoLaunch_* の StartupApproved の先頭バイトが 3 になった。OneDrive の正確な名前と Teams のキーはなく、該当部分は何もしなかった。出力には `OneDriveSetup: 起動する` が残った。11:19:49 UTC の独立の読み取りでは Run の項目が実在したが、参照先の `C:\Windows\System32\OneDriveSetup.exe` はなく、動いているインストーラーを確認した結果ではない |
| 32（修正後） | 手順 32 と対応するロールバック 8 の対象へ正確な名前 `OneDriveSetup` を追加した。修正版のバッチ `20261006-112432Z-9ca3808b` はエラー 0 件・終了コード 0・タスク結果 0 で終了した。11:26:39.6657555 UTC の独立の読み取りで OneDriveSetup と Edge の StartupApproved の先頭バイト 3 を確認した。Run の値と実行ファイルは消さず、RunOnce と Active Setup は変更していない。参照先の実行ファイルは不在で、署名は確認していない |
| 33・34 | 同じバッチは 11:14:32.816 UTC にすべてエラー 0 件・タスク結果 0 で終了し、終了記録も一致した。33 は Clipchamp・BingNews・BingWeather・Solitaire・OfficeHub・Todos・FeedbackHub・GetHelp・PowerAutomateDesktop の 9 個、34 は Web Experience Pack を外した。Outlook と Teams は最初から不在だった。独立の読み取りでも対象 11 個と Web Experience Pack はすべて不在で、最初から不在の Copilot も不在のままだった |
| 36・37 | バッチ `20261006-104738Z-a4ee1724` は管理者・Session 1・Ctrl+Enter `AddLine`。Professional、26H2、26300.9457、PC_NAME は空、対象 LAN は「イーサネット」（index 13）で Public、RemoteDesktop は 1、RemoteAssistance は 1、HelloOnly は 2、キーボードは `kbd106.dll`、配信の最適化は Lan だった |
| 38・40〜42・45・47〜51 | バッチ `20261006-105215Z-41e42451` はエラー 0 件・タスク結果 0 で終了記録も一致し、10:52:34.809 UTC に終了した。独立の読み取りでも変更した値と型を確認した。このバッチの 38 は CLI の順だけを確認した。その後、通常窓での LF 3 行 fixture の右クリック貼り付け順を利用者が手動確認したが、管理者窓は未試験 |
| 41（確認の修正後） | 元の `/q` では LIDACTION と CONSOLELOCK の確認値が空だった。`/qh` に直したバッチ `20261006-105558Z-e052cc85` は 10:55:59.198 UTC にエラー 0 件・終了コード 0・タスク結果 0 で終了し、終了記録も一致した。AC の STANDBYIDLE・LIDACTION・CONSOLELOCK はすべて 0、HibernateEnabled は 0 だった |
| 39・52・53 | PC_NAME が空、単独の Windows、JIS 106/109 キーの条件により飛ばした。キーボードの `kbd106.dll`・PCAT_106KEY・7・2 を保持した。改名・UTC・US 配列への変更の分岐は未検証 |
| 43・44・46 | 利用者がこの VM に限って許可した後、手順 36 を含むバッチ `20261006-111436Z-5b60cb90` は 11:14:48.986 UTC にすべてエラー 0 件・タスク結果 0 で終了し、終了記録も一致した。11:16:41.776 UTC の読み取りもエラー 0 件で、LAN のイーサネット・index 13 は Private、RDP の fDenyTSConnections=0・UserAuthentication=1、RDP の 3 規則と ICMP の 2 規則は有効・Private・Inbound・Allow を確認した。追加の TCP 到達・事前交渉は確認したが、認証情報送信・実際の RDP ログインと ping は未確認 |
| 54（再起動前の導入確認） | バッチ `20261006-105428Z-57f1244c` は 10:55:24.498 UTC にエラー 0 件・終了コード 0・タスク結果 0 で終了し、終了記録も一致した。WSL 3.0.1 の導入と VirtualMachinePlatform の DISM が成功し、再起動を求めた。11:07:33.958 UTC の独立の読み取りもエラー 0 件で、WSL 3.0.1.0 の登録・`Ok` と VirtualMachinePlatform の `Enabled` を確認した。この時点では再起動後の WSL 2 の実起動はまだ試していなかった |
| 55（後回収のログで再起動を確認） | 11:33:51 UTC に通常の `Restart-Computer` を実行し、CLI はエラー 0 件・タスク結果 0 だった。後回収のイベントでは User32 1074 が 11:33:53.778 UTC、Kernel-General 13 の終了が 11:34:13.593 UTC、Kernel-General 12 が OS の起動を 11:39:02.500 UTC と記録し、EventLog 6005 は 11:39:13.762 UTC だった。約 5 分遅れて OS が再起動したことを確認した。最初の起動のロック画面・対話画面への到達は直接確認していない |
| 55 後の復旧起動 | 利用者の明示承認後、11:45:29.857 UTC に対象 VM の強制停止が成功した。停止後の退避を経て起動し、VM の状態は 11:48:17.364 UTC に running、ゲスト OS の LastBoot は 11:48:29.5 UTC だった。GuestControl は終了コード 0 で応答し、Explorer は 0・未サインイン、管理者と通常権限のタスクは Ready。20:49 JST のロック画面を確認し、手動サインインを依頼した。手順 55 による 11:39 の起動とは別の、強制停止後の起動として扱う |
| 56（利用者の手動確認） | ツールの Caps_Lock+A と Ctrl+A は入力の到達を確認できなかった。その後、利用者が「その通りになりました。」と回答し、実際の入力で Caps Lock+A の全選択、Caps Lock 単独で大文字にならないこと、Ctrl+Space による IME の A/あ と文字入力の切り替えを確認した。利用者の手動確認として合格とし、自動入力の試験が成功した結果とは扱わない |
| 57（一部） | 新しい Explorer は PC を開き、`gui-fixtures-visible.txt` の拡張子と Hidden 属性の `hidden.txt` の薄色表示を確認した。ファイルの右クリックで直接、送る・プロパティのある旧形式のメニューが開いた。タスクバーは左寄せ・検索/タスクビュー/ウィジェットなし・時計に秒、全体はダークモード、Edge と UniGet UI のデスクトップのショートカットなしを実画面で確認した。Bing の結果なしは、後の「問題ありませんでした。」という利用者の手動回答で確認した。AI はその検索画面を確認できていない |
| 58（利用者の手動確認） | 不要な Edge/Store のピン解除について、利用者が「問題ありませんでした。」と回答した。手動確認は合格。AI の画面確認と、ピン解除メニューの正確な文言は未確認 |
| 59（利用者の手動確認） | WinGet/Scoop 有効と scoop-search/UniGetUI の導入済み一覧について、利用者が「問題ありませんでした。」と回答した。追加の起動経路・GUI の版表示についても「確認しました。」と回答し、スタートからの起動と WinGet/Scoop の GUI の版表示を手動確認PASSとした。AI の画面確認は未実施 |
| 60・16〜19/38（通常窓の fixture） | 利用者の「確認しました。」により、スタートから通常権限の Windows PowerShell 5.1 を開き、メモ帳の LF 3 行を右クリックで貼って paste-line-1→2→3 の順で実行できたことを手動確認PASSとした。今回の fixture の範囲であり、GitHub の直接コピー経路・管理者窓・AI の画面確認は未試験 |
| 61 | 通常権限の Session 1 のバッチ `20261006-120810Z-1dab0034` は 12:08:13.075 UTC にエラー 0 件・タスク結果 0 で正常終了した。CtrlEnter=AddLine・20 バイトの Scancode Map・kbd106.dll・LongPaths=1・DeveloperMode=1・Sudo=3・Hibernate=0・RemoteDesktop=0・LanCategory=Private を確認した |
| 62・63（文字コード修正前） | 62 の CLI は終了コード -1・`HCS_E_HYPERV_NOT_INSTALLED`、63 は終了コード -1・`WSL_E_DISTRO_NOT_FOUND` だった。AlmaLinux 10 の導入と実起動は成功していない |
| 62・63（文字コード修正後） | `WSL_UTF8` と `Console.OutputEncoding` の UTF-8 を併用する修正版を、バッチ `20261006-122748Z-427db2bf` で実行した。12:27:55.850 UTC に終了し、両手順の PowerShell のエラー記録 0 件・タスク結果 0 だったが、CLI は終了コード -1 で同じ仮想化エラー・ディストリビューションなしだった。両手順の日本語出力は読めた。文字コードの修正は確認したが、WSL の実起動は合格としていない |
| 64（再開後・起動要求取消） | 通常権限の UTF-8 修正版 manifest のバッチ `20261006-173336Z-f88f0701` で、Autologon の導入成功・winget の終了コード 0 を確認した。17:33:57.0822889 UTC に、`%LOCALAPPDATA%\Microsoft\WinGet\Packages` の下に初めてできた Autologon64.exe の 3.10・署名 Valid・Microsoft Corporation を確認し、UAC の実画面でも製品 Autologon・発行元 Microsoft Corporation を確認した。その後、`Start-Process` が「この操作はユーザーによって取り消されました。」を記録し、17:35:47.0813252 UTC にエラー 1 件・タスク結果 1 で終了、タスクは Ready になった。起動要求取消の原因は未特定で、この試行では Autologon の設定は未実施・自動サインインは未検証だった |
| 64（Explorer の手動起動・設定後の再起動） | 利用者が手動起動・UAC・Enable・成功表示・終了を報告し、指定した Winlogon の 3 値を読み戻した。2 CPU の条件で通常の OS 再起動を 1 回要求し、VM への入力なしで LastBoot 23:18:13.5 UTC と `<WIN_USER>`・Explorer・PowerToys の Session 1 を確認した。手動設定後の自動サインインは合格。本文と補助タスクの取消履歴は維持し、その起動経路の成功とは扱わない |

- 貼り付けの fixture は `C:\verify\paste-order-check-20261007.txt`（45 バイト、LF、UTF-8 BOM なし）。SHA256 は `1AE3B7504E8FA11B8A7A23EFB9DA9230DFA946A4FB418BE10EA2D22B5416DBB0`。利用者のメモ帳からの貼り付け確認で、AI が本文の GitHub コピーボタンを操作した試験ではない
- 手順 4・7 の修正は、複数更新の件数表示の誤差を直すもの。手順 5 は変更していない
- 手順 25 は DWORD の HideFileExt=0・Hidden=1・LaunchTo=1・Start_TrackDocs=0・ShowRecent=0・ShowFrequent=0、26 は String の既定値が空、27 は指定した 11 個の DWORD が 0 だった。28 は TaskbarAl=0・TaskView=0・秒=1・検索=0、29 は明暗の 2 値が 0、30 は 2 つの委譲の GUID が本文と完全に一致した。その後の実画面で Explorer・旧形式のメニュー・タスクバー・ダークモードを確認したが、既定の端末など、すべての効果を確認したわけではない
- 管理者設定の読み取りでは、LongPathsEnabled=1・AllowDevelopmentWithoutDevLicense=1・Sudo Enabled=3、DelayLockInterval=4294967295・HibernateEnabled=0 を DWORD で確認した。NIC の AllowComputerToTurnOffDevice は Disabled、RemoteAssistance は 0 で対象の 15 規則はすべて False、HelloOnly は 0、Bing の提案抑止は 1、Edge のショートカット抑止は 1 だった。Edge と UniGet UI の 2 つのショートカットは削除後も不在で、Scancode Map の 20 バイトは本文と一致した
- 配信の最適化は導入前から Lan で、手順 47 は同じ値を確認した。VM のファームウェアはスリープと休止状態を使えず、手順 41 の実際の眠り・復帰・蓋の動作は試していない
- 手順 54 後の `wsl --version` は終了コード 0 で WSL 3.0.1.0・カーネル 6.18.40.1-1・WSLg 1.0.79、`wsl --status` は終了コード 0 で既定のバージョン 2 を表示した。同時に「このコンピューターで仮想化が有効になっていないため、WSL2を開始できません」と表示した。CPU の VMMonitorModeExtensions・SLAT は False、VirtualizationFirmwareEnabled・HypervisorPresent は True だった。この読み取り時点では手順 54 後の再起動をまだしておらず、復旧起動後の WSL 2 の結果とは分けて扱う
- WSL 1 の機能 `Microsoft-Windows-Subsystem-Linux` は Disabled で、この手順では不要なので正常。`wsl --list --verbose` はディストリビューションなしと表示して終了コード -1 だった。手順 54 は `--no-distribution` なので、これも導入失敗とは判定しない
- 当時の LastBoot は 12:04:48.5 UTC だった。11:48 の復旧起動の後、利用者が完了を知らせる前の追加の起動で、理由はまだ特定していない。手動サインイン後の手順 61 と以下の読み取りは、この時点の起動後の状態として扱う
- 12:09:46.1127459 UTC の管理者の読み取りはエラー 0 件で、IME の 1・2、OneDriveSetup と Edge の StartupApproved の先頭 3、NIC の Disabled、AC の 3 値 0、RDP の有効・NLA と Private の規則などが保持されていた
- 12:17:44.0437403 UTC の WSL の読み取りはエラー 0 件・タイムアウト 0 件だった。WSL 3.0.1.0 は Ok、VirtualMachinePlatform は Enabled、WSL 1 の機能は Disabled、CPU の VMMonitorModeExtensions・SLAT は False、VirtualizationFirmwareEnabled・HypervisorPresent は True。`wsl --status` は既定 2 で、この時点では WSL 2 の警告はなかったが、`--list` はディストリビューションなし・終了コード -1 だった。62・63 の実行結果を優先し、パッケージと機能の導入確認から実起動の成功とは判断しない
- 初回導入と設定確認の時点では、後続の [Git for Windows](../git.md#windows-11-で-git-for-windows-を入れる)・[Firefox](../firefox.md#windows-11-で使う)・[WezTerm](../wezterm-nightly.md#windows-11-で使う)・[Claude Code](../claude-code.md#windows-11-で使う)・[VirtualBox](../virtualbox.md#windows-11-で使う)・[WireGuard](../wireguard-road-warrior.md#windows-11-で使う)・[HackGen Console NF](../hackgen.md#windows-11-で使う)は、同じ VM で導入部分を確認した。VirtualBox は 7.2.20、WireGuard は 1.1.1 だった。追加検証では InstalledFontCollection の HackGen の 2 ファミリーと、WezTerm の右クリック用レジストリ項目を確認した。Git の共通手順 3・5・6・7 は非対話の Git Bash と隔離した global 設定で検証し、12 キーの値・global スコープ・試験用ファイルの出どころを確認した。この時点では本人の user.name/user.email と実 global 設定への反映、対話的な Git Bash の GUI、pull 動作は未検証。GUI の一覧・実クリックと認証、VPN の接続は未確認。Firefox・既定ブラウザー・HackGen の GUI・ゲスト内の VirtualBox Manager の確認は回答待ち
- VirtualBox の入れ子の VM の起動試験は、バッチ `20261006-123615Z-9406750f` で `VERR_NEM_NOT_AVAILABLE`（ゲストの CPUID が VirtualBox の署名）・`VERR_SVM_NO_SVM` となり失敗した。試験用 VM は `unregister --delete` で削除し、フォルダーも不在だった。後始末の終了コード 0 を起動成功とは扱わず、WSL とともにこの検証環境の制約として記録する
- 手順 43・44・46 は当初、具体的な許可が不足しているとして自動承認レビューに拒否された。利用者が「この VM に限って許可する」と明示した後に実行した。読み戻した RDP の規則は TCP/UDP 3389 と Shadow、ICMP は IPv4 の Type 8 と IPv6 の Type 128 だった
- 手順 13 の待機中に診断した HTTPS の接続先からは HTTP 404・204・200 の応答があった。この応答だけでは Store の検索が完了できるとは判断しない。CLI の故障とも断定していない
- live snapshot は約 8 分進まず、対象 VM の `IProgress.Cancel` で取り消した（`VERR_SSM_CANCELLED`）。snapshot は保存できていない。この検証環境の復旧経過を、手順 13 の CLI 障害とは断定しない
- 05:09 UTC の pause 中に差分 VDI 11.7 GB・USB VHD 188 MB と VM 情報をホストの一時保存先へコピーし、resume した。`clonemedium` は書き込みロックで失敗し、独立した全ディスク clone は取得できていない。既存の親ディスク・過去 snapshot は維持した
- ユーザーの承認後、05:29:11 UTC に `poweroff` が成功した。最初の再起動は接続中の Rufus USB から Windows Setup の言語・キーボード画面へ戻った。「次へ」やインストールは操作していない
- 05:31:53 UTC に再び `poweroff` し、Rufus USB の接続を `none` にした。媒体ファイルは削除・変更していない。05:32:22 UTC に Windows のルート差分 VDI から起動した
- Guest Additions 7.2.20 のサービスは Running・Automatic で、認証した GuestControl の読み取り probe は終了コード 0 で戻った。読み取り記録の最終起動は 05:36:42.500 UTC。05:38:02 UTC に起動時の更新画面が終了し、Windows のロック画面へ移った。この時点で UI 入力を止め、`<WIN_USER>` の手動サインインを待った
- 認証した GuestControl の monitor は成功し、管理者・通常権限の両タスクは Ready、原基準記録の SHA256 も一致した。再起動前の手順 13 の記録は `step_started`・`running` のまま。`finished` の時刻は前の手順 10 より古く、手順 13 の終了を示していない
- 復旧直後の読み取りでは Store プロセスは 0 個だった。初回の手順 13 は更新 31 件の全一覧を採取できたが、CLI の自然終了と終了コードは確認できず、強制停止による中断として扱う
- サインイン後に管理者の手順 2・3・7 と通常権限の手順 10・13 を再実行した。手順 7 は更新 0 件・再起動待ちなし、手順 13 はエラーなし・終了コード 0 で正常終了した。この時点では手順 13 の出力の回収を待っていた
- 手順 13 の再実行が完了した後、08:51:06 UTC に VirtualBox の VM が aborted になった。ホストのログは画面数の変更の直後に例外 `0xc0000005` を記録していた。ログを保存し、対象 UUID を指定して GUI で起動し直した。Store コマンドのエラーとは判定していない
- 08:54:41.069 UTC に VM が起動し、再び Windows のロック画面を確認した。手動サインインを再依頼して待っていた。この時点では指定ユーザーのログオン失敗でゲストのファイルを回収できなかった
- ホストに出た以前の無人インストール用ファイルの削除確認は Escape で取り消し、ファイルは削除していない
- その後、ホストの接続用の認証情報の不一致を確認し、GuestControl の接続を復旧した。ゲストのパスワードは再変更していない。回収した手順 13 の出力は `No updates found.` で、エラーの記録は空配列だった。手順 14 は飛ばし、手順 15 は手動サインイン後に実行する予定
- 接続復旧後の読み取りでは Explorer・VBoxTray のプロセスがなく、`Win32_ComputerSystem.UserName` は空だった。この時点はログオフ状態で、再サインインを待った
- ログオン前の補助読み取りでは、Store 22608.1401.5.0・App Installer 1.29.379.0・Terminal 1.24.12741.0 は Status 0（Ok）だった。その後、利用者の再サインインを確認して手順 15 を実行し、10:10:39.719 UTC に正常終了した
- 手順 20・21 の初回バッチ `20261006-101239Z-3352f6ed` では、手順 20 の出力は空でエラー 0 件、手順 21 は `scoop` 未検出でエラー 1 件・タスク結果 1 だった。補助ハーネスの dot-source 呼び出しが、Scoop の公式インストーラーの「関数だけを読み込む」分岐に入り、実インストールを行っていなかった。手順 20 の呼び出しだけをハーネス側で直し、本文のコマンドは変えずに再実行すると導入と確認が成功した
- 手順 22 では、依存関係の `vcredist2022_x64.exe` と管理者確認のプロセスを確認した。実ファイルは Microsoft Corporation の有効な署名で、製品は Microsoft Visual C++ v14 Redistributable x64 14.51.36247、版は 14.51.36247.0 だった。取得した GUI の画面は黒く、実際の UAC の文言は観察できていない。利用者が管理者確認を許可した後、VC x64 の HKLM の `Installed=1` と `Version=v14.51.36247.00`、UniGet UI の導入成功の出力を確認した
- 補助のユーザー別アプリの読み取りでは、UniGet UI 2026.3.0 の HKCU 登録と `%LOCALAPPDATA%\Programs\UniGetUI` の本体、`UniGetUI.exe` の版 2026.3.0.0、scoop-search の実ファイルを確認した
- 続く source 未指定の `winget list` は `msstore` の初回同意待ちになった。対象の引数と親プロセスを確かめて一覧確認の CLI を中断した。これは操作側による中断として扱い、自然な検索失敗とは判定しない。手順 22・23・24 の一覧確認の 3 行だけに `--source winget` を足し、手順 22 の再実行で一覧の正常表示と終了を確認した
- 手順 23・24 の実体確認は読み取りエラー 0 件だった。画面の取得は対象を選び直しても 2 回 `foreground window did not report a process id` となり、CLI は正常に応答していた。GUI の操作や表示は確認済みにはしていない
- 手順 55 の再起動要求後、黒画面・GuestControl 未応答から暫定的に新しい起動を未確認としていた。後回収のイベントと停止時に保存した VBox.log で、11:39 に OS が再起動していたことを確認し、記録を訂正した。VBox.log には HyperV Reset・ACPI Reset と RESETTING/RUNNING、ゲスト VBoxService の 11:39:13.394 UTC のログ開始、graphics capability Yes があった
- 検証側の最後の GuestControl の失敗確認は新しい起動より前の 11:38:45 UTC で、強制停止直前の再応答の確認が不足していた。強制停止案は当初、別の明示承認が必要として自動承認レビューに拒否された。その後、利用者が「承認します」と明示して強制停止・退避・復旧起動を行った。イベント 41・6008 は後の強制停止後の復旧起動時に発生したもので、手順 55 の自然な再起動の失敗を示すものとして扱わない。Minidump は 0 件、読み取りエラーは 0 件だった
- 停止後に差分 VDI（約 22.95 GB）・設定・NVRAM・ログの計 4 ファイルを退避し、すべて元と退避先の SHA256 が一致した。11:47:42 UTC に退避の記録を保存した。差分ディスクなので既存の immutable の親が必要で、独立した全ディスク clone ではない。その後に利用者の手動サインインと、手順 61・57 の一部を確認した
- 手順 61 の確認時点では CLI が正常に応答した。画面が黒くなった際は 1 回のクリックで戻り、表示が消えていた状態として扱う。この時点の観察を VM のハングとは判定しない
- 利用者の希望で検証を一度中断し、`<OTHER_PC>` へ引き継いで続行する予定とした。この中断中は追加の VM 操作を行わず、検証結果の保存と未実施の範囲の整理のみを行った。中断時点では手順 64 は実行していなかった
- 2026-10-07 JST に、利用者の指示で `<HOST_PC>` の元の VM で再開した（以下の時刻は 2026-10-06 UTC）。元の VM は poweroff、状態変更時刻は 14:54:57 UTC だった。同じ UUID を `--type separate` で起動し、ゲストの LastBoot は 17:09:21.5 UTC。利用者の手動サインイン「完了」の後、CIM のユーザーと Explorer・PowerToys・UniGet UI の Session 1 の実プロセス、両検証タスクの Ready を確認した
- 手順 64 の Autologon64.exe の SHA256 は `5D96BBC4E5B726D87C7CF547F5FE98F8F05434EC2130BD60CBF5671FD3A7381B`。17:33:57.0822889 UTC の確認ではタスクは Running、Consent は Session 1 で、利用者の UAC と有効化の操作を待っていた。自動入力の `u` はスタートの検索に届かず画面が閉じ、GUI のキー入力の到達は未確認のまま。この時点では 57 の Bing・58・59 は合格としていなかった。最新の VBox ログでも NEM の Hyper-V mode を確認し、WSL と入れ子の VM は再実行せず、ホストのセキュリティ設定も変更していない
- 手順 64 は導入成功の後、Autologon の起動要求が取り消されて終了した。利用者は UAC・パスワード・Enable の依頼に「VMが無かった」と回答し、取消の原因は未特定。設定は未実施で、自動サインインも未検証のまま
- `<HOST_PC>` のホストのイベント 1000 は 17:35:36 UTC に VirtualBoxVM.exe の Qt6GuiVBox.dll+0xd5c74・0xc0000005、17:35:41 UTC に 0xc000041d を記録した。直前の VBoxUI.log には host-screen count changed が 6 回あった。一方、VBoxHeadless は running、ゲストの LastBoot 17:09:21.5 UTC と Explorer のログインを維持していた。表示プロセスの障害として記録し、手順 64 の取消原因の確定とは扱わない。証跡を `evidence/frontend-crash-20261006-173536` に保存した
- 21:57:23.0140619 UTC の最初の GUI だけの再接続は、VBoxUI.log の aboutToQuit が 10.346 秒で、ウィンドウの復旧を確認できなかった。その後、利用者は表示しているホスト PC が `<HOST_PC>` と回答した
- 2 回目は `VBoxManage startvm <VM_UUID> --type separate` で GUI のウィンドウが戻り、PID 14420・ウィンドウ 1507508 のホストメニューを実画面で確認した。ただしゲストは黒画面だった。VBox.log には `DetachFramebuffer: Invalid framebuffer object` と `AttachFramebuffer: Framebuffer already attached to 0` があり、経過時間 01:37:41 の実際の heartbeat unresponsive は回復を確認できていない。この検知だけでゲスト OS の停止を確定しない
- GuestControl の新しいセッションは starting のままタイムアウトした。22:04:23.928 UTC の ACPI による通常終了要求から約 3 分後も VM は running で、通常終了は未確認だった。強制停止による復旧だけを利用者に明確に確認した
- 22:07:34 UTC ごろの一時停止中に、active VDI（25,531,777,024 バイト）・vbox・NVRAM の 3 データを `%TEMP%\recovery-backup-frontend-20261006-220734` へコピーし、すべて元とコピーの SHA256 が一致した。一方、稼働中の VBox.log のハッシュ確認は file-in-use で失敗し、3 データの照合結果とは分ける。RAM は保存しておらず、差分 VDI のため親 VDI が必要で、独立した clone ではない。`evidence/frontend-reattach-20261006-215723/backup-manifest.json` に記録した。finally の resume は 22:09:27.292 UTC に完了し、VM は running と確認した
- 利用者が今回の明確な確認に「起動し直してよいです」と回答した後、22:28:04.227054 UTC に対象 VM の poweroff を確認し、同じ UUID を separate で起動した。直後の running 判定は早すぎてコマンドが終了コード 1 になったが、再び start は行わず、22:28:27.944 UTC の読み取りで running、VMStateChangeTime 22:28:13.867 UTC を確認した
- この 4 CPU の起動では Guest Additions は level 1・base driver までロードした。bootmgfw.efi・Windows の kernel ID・WDDM/USB の記録はあるが、経過時間 28.940 秒以降は 5 分を超えて進展を確認できず、約 11 分 55 秒の観測でも VBoxService に到達しなかった。この試験ではデスクトップとサインインは復旧しなかった
- 切り分けとして提案した CPU 数 4→2 は、自動承認レビューが「CPU の永続設定変更の明示承認がなく、再起動の許可だけでは不足」として実行前に拒否した。その時点では変更せず、この変更について利用者に明確な承認を依頼した
- 利用者が CPU 数の比較に「承認します。」と回答した後、22:40:04.323245 UTC に poweroff を確認し、4→2 の設定と読み戻しを行った。separate の起動要求は 22:40:04.5050719 UTC、VMStateChangeTime は 22:40:09.392 UTC、22:40:45.3348627 UTC に running を確認した
- 2 CPU の起動は、経過 57.677 秒に VBoxGuest、62.560 秒に WDDM、83.716 秒に VBoxService（ゲストの時刻 22:41:30.328 UTC）、84.340 秒に graphics まで進み、Windows のロック画面を実画面で確認した。22:42:21.189987 UTC に GuestControl が成功し、LastBoot 22:40:23.5 UTC を読み戻した。この時点では CIM のユーザーは空、LogonUI は Session 1 で、手動サインインは未完了だった。両検証タスクは Ready で、通常権限タスクの結果 1 は前の手順 64 の取消を保持していた。証跡は `evidence/restart-20261006-222804/VBox-cpu2-ready.log`・`cpu2-diagnostic.json` に保存した。CPU 数以外のハードウェアとホストのセキュリティ設定は変更していない。比較で復旧した結果であり、原因を確定したものではない
- この時点では 2 CPU のままで検証を続けることにし、4 CPU に戻す再試験は行っていなかった。利用者の「完了」の回答後、22:52:26.7068317 UTC の読み取りでユーザー `<HOSTNAME>\<WIN_USER>`、Explorer（PID 2676・7916）と VBoxTray（PID 8868）の Session 1 を確認し、手動サインインは完了した。LastBoot は 22:40:23.5 UTC のままで、通常権限タスクは Ready、前の取消による結果 1 を保持していた。この時点では Autologon は未設定で、再び開く補助コード `relaunch-autologon.ps1` も VM では実行していなかった
- 通常権限タスクで Autologon の新しい起動要求 `20261006-225840-29f9cb04` を 1 回行い、22:58:52.2323842 UTC に要求を完了した。補助コードは実体のハッシュ・Microsoft の署名の確認を通過し、22:59:32.8630346 UTC は Consent の Session 1・通常権限タスク Running だった。今回の UAC 文言は画面取得で確認できず、利用者は「VMの画面にはデスクトップしか映っていません」と回答した
- この要求の完了記録は、開始 22:58:55.1901170 UTC・終了 23:00:58.8458588 UTC・result fail、Start-Process の「この操作はユーザーによって取り消されました」、native_code null だった。利用者が取消を押したかどうかと、取消の原因は未確認。23:05:02.7386707 UTC の GuestControl は同じ LastBoot 22:40:23.5 UTC と `<WIN_USER>`・Explorer の Session 1、Autologon64 と Consent の不在、通常権限タスク Ready・結果 1 を確認した。完了記録は `evidence/autologon-relaunch-20261006-225840-29f9cb04/guest-launch-result.json` に保存した。同じ裏のタスクからは起動を繰り返さず、署名済みの実体を Explorer で選択表示する要求を 1 回行った。この時点では表示成功は未確認で、Autologon の設定と次回起動の自動サインインも未確認だった
- 選択表示の補助コードの記録は 23:07:24.3667475 UTC で、実体の SHA256 一致・有効な Microsoft の署名・`<WIN_USER>` の Session 1 を確認し、Autologon 自体の起動と設定操作は行っていない。23:08:18.8449035 UTC の GuestControl では、通常権限タスク Ready・結果 0、対象 Autologon フォルダーを開いた Explorer（PID 4156）の Session 1、Autologon と Consent の不在を確認した。完了記録 `explorer-display-result.json` を保存した。Explorer を開く処理は成功したが、画面取得は新しく選び直しても 2 回 CreateForMonitor の 0x80070057 で失敗し、画面の視認は未確認。UI 入力を止め、利用者にタスクバーの Explorer から選択された実体を手動で起動し、製品・発行元を確認して設定する操作を依頼した。この時点では Autologon の設定と次回起動の自動サインインは未確認だった

- 利用者が Explorer から Autologon を手動で起動し、UAC・パスワードと Enable・成功表示・終了を行ったと「完了」で報告した。23:16:09.4770037 UTC の読み取りでは、Winlogon の指定した 3 値だけ（AutoAdminLogon=1・DefaultUserName=`<WIN_USER>`・DefaultDomainName=`<HOSTNAME>`）を確認した。秘密値は読み取っていない。Autologon と Consent は不在、両検証タスクは Ready・結果 0、LastBoot は 22:40:23.5 UTC だった
- 23:17:36.0232656 UTC に通常の OS 再起動 `shutdown.exe /r /t 10` を 1 回要求し、終了コードは 0、ホストからの poweroff は行っていない。利用者には検証中の VM に入力しないよう事前に伝え、検証側も GUI 入力・認証操作を行っていない。23:19:40.9676058 UTC の GuestControl は終了コード 0 で、LastBoot 23:18:13.5 UTC、ユーザー `<HOSTNAME>\<WIN_USER>`、Explorer（PID 5656・7920）と PowerToys（PID 5528）の Session 1、LogonUI・LockApp・Autologon・Consent の不在、両タスク Ready・結果 0 と指定 3 値の保持を確認した。2 CPU の条件で、手動設定後の無入力の自動サインインを合格とした。本文と補助タスクの Start-Process の取消履歴は維持し、元の起動経路の成功に置き換えない。前後の読み取りと再起動要求は `evidence/autologon-reboot-20261006-2316` に保存した。その後、利用者はホストの通常デスクトップと、VM が見えないことを報告した。ホストのイベントでは VirtualBoxVM（PID 26348）が 23:28:23.7379115 UTC に Qt6GuiVBox.dll+0xd5ec6・0xc0000005、23:28:27.2549383 UTC に 0xc000041d を記録した。原因は未確定で、ゲストは同じ起動とサインインを維持した。表示の再接続 1 回は終了コード 0 だったが、別の表示プロセスは 10.330 秒で aboutToQuit となり、ウィンドウは戻らなかった。強制オプションなしの通常 OS 終了要求はホスト時刻 23:33:55.791 UTC に終了コード 0、VM の poweroff は 23:34:08.177 UTC。同じ 2 CPU の設定で separate 起動を 1 回要求した時刻は 23:34:45.0165607 UTC、終了コード 0、running の状態変更は 23:34:50.521 UTC だった。ゲスト時刻 23:36:42.8632541 UTC の読み取りでは LastBoot 23:35:01.5 UTC、`<WIN_USER>`、Explorer・PowerToys の Session 1、両タスク Ready・結果 0、認証画面なしを確認した。新しいウィンドウで Windows の起動画面から実際のデスクトップを視認し、再度の自動サインインも CLI で確認した。証跡は `evidence/frontend-reattach-20261006-2330` に保存した。その後、利用者の手動の最大化・前面表示の「完了」を受け、その時点で実際のデスクトップ（1057×1143）の最大化を視認した。Edge のピンの右クリックは対象を選び直した 1 回の再試行でも failed to activate captured window となり、GUI 入力を停止した。この時点では 57 の Bing、58 のピン、59 の UniGet UI の操作は未確認で、利用者にまとめて手動の確認を依頼し、UniGet UI を開いたままの報告を待っていた。ゲスト時刻 23:50:04.3380797 UTC の読み取りでは同じ LastBoot 23:35:01.5 UTC と `<WIN_USER>`、UniGet UI 2026.3.0.0・有効な Devolutions Inc の署名・Session 1 のプロセスを確認した。23:50:48.0115251 UTC に Get-StartApps の Name=UniGetUI・AppID=Devolutions.UniGetUI でスタートの入口も確認したが、これらは GUI の起動・検出・一覧確認の代用にはしない。最新のウィンドウを選び直した画面取得は 1057×1143 の内部が黒く、1 回の再取得も黒かった。23:57:21.8597671 UTC の GuestControl は同じ LastBoot 23:35:01.5 UTC、`<WIN_USER>`、Explorer と UniGet UI の Session 1 で正常に応答した。この時点では画面内容を確認できず、57〜59 の結果待ちを維持していた。その後、最後の 3 点について利用者が「問題ありませんでした。」と回答し、Bing/Web の結果なし、不要な Edge/Store のピン解除、UniGet UI の WinGet/Scoop 有効と scoop-search/UniGetUI の導入済み一覧を、利用者の手動確認として合格とした。AI はこれらの画面を確認できていない。この質問では、ピン解除の正確な文言、UniGet UI のスタートからの起動と WinGet/Scoop の GUI の版表示は未確認だった。その後に後者と通常窓での LF 3 行の右クリック貼り付けを依頼し、利用者が「確認しました。」と回答した。59 の起動経路と GUI の版表示、60 のスタートから開く通常権限の Windows PowerShell 5.1、16〜19・38 の今回の fixture による paste-line-1→2→3 の順序を利用者手動確認として合格とした。AI の画面確認は未実施、GitHub のコピーボタンからの直接経路・管理者窓への貼り付け・ピン解除の正確な文言は未試験

**追加検証（2026-10-07 UTC）**:

- RDP はホストのループバックから一時的な NAT 転送を通し、ゲストの TCP 3389 への到達と事前交渉を確認した。TLS と CredSSP を候補にした要求には `selectedProtocol=2`（CredSSP）、TLS だけの要求には `failureCode=5`（CredSSP 必須）が返った。値の意味は Microsoft の [RDP Negotiation Response](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-rdpbcgr/b2975bdc-6d56-49ee-9c57-f2ff3a0b6817) と [RDP Negotiation Failure](https://learn.microsoft.com/ja-jp/openspecs/windows_protocols/ms-rdpbcgr/1b3920e7-0116-4345-bc45-f2c4ad012761) による。認証情報は送信せず、この時点では TLS の確立・認証後の RDP ログイン・ping は未検証。
- 初回はプロトコル確認後の後片付けが失敗し、終了コード 1 となった記録を保持した。その後の `natpf1 delete` は終了コード 0 で、一時転送とホストの待受けの撤去、元の転送なしの状態への復元を確認した。ホストとゲストのファイアウォールは変更していない。証跡は `evidence/remaining-network-20261007-035624-8a4e672a/rdp-probe-result.json` と `cleanup-followup.json`。
- 通常権限の PowerShell 7.6.6・Session 1 で、拡張パス接頭辞を使わない 343 文字のパスの作成・読み取り・削除と、SymbolicLink の作成・読み取り・リンクの削除・元ファイルの保持を確認した。試験用の置き場所の後片付けも成功した。PowerShell 5.1 や全アプリでの効果へは広げない。
- 同じ追加検証の InstalledFontCollection は `HackGen Console NF` と `HackGen35 Console NF` を認識した。WezTerm は Directory と Directory/Background の右クリック用レジストリ項目が存在した。GUI のフォント一覧・描画、WezTerm の実クリックは未確認。証跡は `evidence/remaining-local-20261007-040410-0e3dc87e/guest-result.json`。
- Git は検証時の `docs/git.md`（SHA256 `2541D4BE9E3CD490A2474567EC30635496610BBA507922DD25148837BF4ED6A3`）の共通手順 3・5・6・7 を変更せず、通常権限の PowerShell 7.6.6 から非対話の Git Bash で実行した。各終了コードは 0、12 キーすべての値・global スコープ・試験用ファイルの出どころが期待値と一致し、手順 7 の出力とも一致した。子 Bash の `GIT_CONFIG_GLOBAL` だけを試験用ファイルに向け、`HOME` と `CODEX_HOME` は変更していない。実際の system 設定の SHA256 は前後一致し、本人の global 設定は未作成のまま、`pull.ff` も未設定のまま保持した。試験用ファイルと置き場所は削除済み。この時点では本人の identity 設定と実 global への反映、対話的な Git Bash の GUI、pull 動作は未検証。証跡は `evidence/remaining-git-20261007-041841-0ff6f533/guest-result.json`。
- Firefox・既定ブラウザー・HackGen の GUI・ゲスト内の VirtualBox Manager は利用者に確認を依頼済みで、回答待ち。2 CPU のままで、4 CPU に戻す試験、WSL 2 と入れ子の VM の再試験は行っていない。

**追加検証（2026-10-07 09 UTC）**:

- Git の共通手順 4・5・6・9・10・11 を通常権限の PowerShell 7 から同じ非対話の Git Bash で実行した。identity は検証専用の架空値とし、子プロセスの `GIT_CONFIG_GLOBAL` だけを隔離した。日本語ファイル名・CRLF・最初の push と upstream、分岐した履歴の実 rebase、autostash の作成・適用と未コミット変更の復元、手順 11 による試験用リポジトリの削除を確認した。14 フェーズの終了コードと 9 検査はすべて成功し、実設定も保持した。ホストの 55 秒の待ち時間が先に切れ、最初の実行と結果コピーは終了コード 1 だった。その記録を残し、同じ実行が終了コード 0 で完了した結果を後からコピーした。再実行はしていない。証跡は `evidence/remaining-git-behavior-20261007-092648-ddbf22f4`。
- WezTerm の `ls-fonts --codepoints ... --rasterize-ascii` で、HackGen Console NF と HackGen35 Console NF の各 6 文字（英字・かな・漢字・矢印・Powerline・フォルダーアイコン）が自身の DirectWrite フォントを使い、欠損でない glyph と画素を生成した。日本語 2 文字は各 2 セル、他は各 1 セルだった。終了コード 0、一時設定の削除と実設定の保持を確認した。GUI の窓や表示の見た目の確認には広げない。証跡は `evidence/remaining-wezterm-font-20261007-092017-4d5448f6`。
- WireGuard は管理者の Windows PowerShell 5.1 で手順 6 を変更せず実行し、45 bytes・ASCII・LF の鍵ペアと公開鍵の対応、Administrators と SYSTEM だけの ACL を確認した。管理サービスは公式 CLI による一時的な起動・削除で検証した。鍵とサービスとプロセスは削除し、検証タスクの要求ファイルも元に戻した。新しくできた管理サービスの Data は残し、設定ファイルは 0 件だった。鍵の内容・ハッシュは記録していない。手順 5 の GUI と VPN 接続は未確認。証跡は `evidence/remaining-wireguard-local-20261007-094630-d8f8efb9`。
- RDP は、ゲストに設定された公開証明書を読み取り、SHA256・名前・有効期間を照合して TLS 1.3（`TLS_AES_256_GCM_SHA384`）を確立した。CredSSP の選択後の TLS までで、RDP の資格情報は送信していない。終了コード 0、一時的なループバック転送と待受けの撤去を確認した。認証後のログインと ping は未確認。証跡は `evidence/remaining-rdp-tls-20261007-095055-a37a84b1`。

- スタートアップの追加試験では、新規の Run 項目 2 つに StartupApproved の先頭バイト 2（有効）・3（無効）を設定し、通常の OS 再起動を 1 回行った。起動から 122 秒の最初の読み取りは両記録がなく、確認不能・VBox CLI 終了コード 33 だった。その失敗記録を保持した。有効側は遅れて Explorer の Session 1 から起動し、その記録から 160.754 秒後の読み取りで無効側の記録がないことを確認した。後の観測と後片付けは終了コード 0、今回の Run 2 値・承認 2 値と専用ディレクトリを削除した。既存 OneDriveSetup の参照先は存在しないため、この結果を OneDrive・Teams 本体の次回起動の合格には広げない。証跡は `evidence/remaining-startup-20261007-f0126d5a`。

**未試験・環境未達の範囲**:

1. Windows Update の再起動の分岐（手順 8）
1. Store の初回 CLI 準備（手順 11・12）、手順 14 の更新適用
1. GUI の残る効果、GitHub の直接コピー経路と管理者窓への貼り付け、ピン解除の正確なメニュー文言
1. 認証情報送信・認証後の RDP ログインと ping（TCP 到達・事前交渉・証明書の照合による TLS の確立まで追加検証済み）。手順 39・52・53 の変更する分岐は条件により飛ばした
1. 手順 55 による最初の起動の対話画面への到達、64 の本文と補助タスクからの起動経路、任意節、更新とロールバック。後続ツールは Firefox の既定・コーデック、VirtualBox Manager、WezTerm の GUI、Claude Code の認証、WireGuard の実接続などが未確認。62・63 の WSL 2 と入れ子の VM の実起動は、この検証環境では未達
1. すべての本文の GUI 貼り付け、Windows の実機での通し実行

## 付録: PR #104 の未検証項目を同じ VM で確かめた記録（2026-10-08）

**VM での追加検証**。上の 2026-10-06〜07 の付録で「未試験・環境未達」として残した項目のうち、同じ VM で行えるものを通した。Windows の実機では通していない。時刻は UTC（画面の時計は JST）。

**環境**:

| 項目 | 値 |
|---|---|
| ホストと VM | 上の付録と同じ。ホストは Windows 11 Pro の x86_64 の PC、VirtualBox 7.2.20（Hyper-V の NEM）。VM は `windows11-verify-20261006`（Windows 11 Pro 26H2、26300.9457、2 CPU、メモリ 8 GiB） |
| 始める前の控え | 2026-10-07 22:26 ごろに OS を止めて、スナップショット `pr104-baseline-20261008` を撮った |
| 2 枚目の NIC | 利用者の許可を得て足した。内部ネットワークで足してスナップショット `pr104-nic2-added-20261008` を撮り、動かしたままホストオンリーのネットワーク（192.168.56.0/24）に付け替えた。ゲストでは「イーサネット 3」、DHCP で 192.168.56.107 |
| ゲストの中の重なり | VirtualBox（[virtualbox.md の Windows 11 で使う](../virtualbox.md#windows-11-で使う)）が作ったホストオンリーのアダプター「イーサネット 2」が 192.168.56.1/24 を持ち、2 枚目の NIC と重なったので、検証の間だけ無効にした |
| 相手の VM | 同じホストの AlmaLinux 10.2 の VM 2 台（PR #100 の検証で作った `alma10-pr100-client-20261007`・`alma10-pr100-pc-20261007`、192.168.56.82・.81）。前の記録が挙げた `alma10-current-20261006-server`・`-peer` は、ログインの資格情報が分からず使わなかった（起動して ACPI で止めただけ） |
| RDP のクライアント | `alma10-pr100-client-20261007` の FreeRDP 3.10.3（`wlfreerdp`。`mutter --wayland --headless --virtual-monitor 1280x800` の中で動かした） |

**操作の方法**:

- ゲストの中の 2 つの検証タスク（管理者と通常権限。どちらもサインインしたデスクトップの Session 1）が、SendInput のマウスとキー・UI Automation・画面の取得・コンソールの読み取りで操作した
- UAC の確認（セキュア デスクトップ）には SendInput が届かないので、ホストの `VBoxManage controlvm keyboardputscancode` で Shift+Tab と Enter を送って「はい」を選んだ。そのときの画面は、ホストの `screenshotpng` で撮った
- 本文のブロックは、ゲストの Firefox で GitHub の PR #104 のブランチの文書を開き、コードブロックの「Copy code to clipboard」ボタン（UI Automation の Button）を押してコピーし、窓に貼った
  - windows-setup.md のボタンは 117 個で、抜き出したブロック 117 個と対応した。押してコピーした中身を、windows-setup.md・git.md・claude-code.md の合わせて 50 回、抜き出したブロックと比べた。49 回は一致した（どれも LF だけ・末尾の改行なし）。1 回（claude-code.md の Windows 11 で使うの手順 7 の最初）は、クリップボードが前の中身のままで、押し直すと一致した
  - その後は、抜き出したブロックの文字列（LF、末尾の改行なし）を検証タスクがクリップボードに置き、同じ貼り方で貼った
- 貼り方: conhost の窓は窓の中の右クリック、Windows Terminal の窓は右クリック（複数行の警告が出たら「強制的に貼り付け」）、mintty（Git Bash）は右クリックのメニューの「Paste」。最後に Enter を押した
- 検証用のパスワードは、画面の記録・ログ・この記録に出していない（Autologon の窓と RDP・SMB・WinRM のトリガーには、ホストの一時ファイルから渡し、使った後に消した）

**実施手順で確かめたこと**:

| 手順 | 結果 |
|---|---|
| 1〜7（Windows Update） | 管理者の窓で手順 2〜4・6・7 を貼った。対象の更新は 0 件で、`Windows Update の確認完了（対象の更新なし・再起動待ちなし）`。手順 5・8 は条件に当たらなかった |
| 9〜15（Store） | 手順 10 で Store 22608.1401.5.0 と `store.exe`・`winget.exe`。手順 13 は `No updates found.`。手順 11・12・14 は条件に当たらなかった |
| 35 | スタートで「Windows PowerShell」を右クリック →「管理者として実行」。UAC の確認（Windows PowerShell、発行元 Microsoft Windows。既定のボタンは「いいえ」）で「はい」を選ぶと、「管理者: Windows PowerShell」の conhost の窓（`ConsoleWindowClass`）が開き、プロファイルのエラーは出なかった |
| 36・37 | GitHub のコピーボタンから管理者の窓に貼った。`Admin : True`・`CtrlEnter : AddLine`・Professional・26H2・26300.9457・`LanCategory : Private`・`RemoteDesktop : 0`・`RemoteAssistance : 0`・`HelloOnly : 0`・`Keyboard : kbd106.dll`・`Hypervisor : True`・配信の最適化 `Lan` |
| 38 | 管理者の conhost の窓に右クリックで貼ると、最後の `}` の後で止まり、Enter で `1 行目`・`2 行目`・`3 行目` の順に出た（逆順にならない） |
| 39（PC の名前を変える分岐） | `$PC_NAME = 'PR104-VERIFY'` で手順 36 を貼り直し、手順 39 は警告と `再起動の後に PR104-VERIFY になる`。再起動の前に貼り直しても同じ出力 |
| 52・53（UTC と US 配列の分岐） | 手順 52 で `RealTimeIsUniversal : 1`、手順 53 で `kbd101.dll`・`PCAT_101KEY`・`7`・`0` |
| 55 | `Restart-Computer` の後、自動サインインでデスクトップに戻った（Autologon の `DefaultDomainName` が元の名前 `<HOSTNAME>` のままでも通った） |
| 56 | ホストからのキーで確かめた。US 配列で Shift+2 が `@`、Caps Lock+A で全選択（Caps Lock だけでは大文字にならない）、Ctrl+Space で IME がオン（「あ」、変換の候補が出る）とオフに入れ替わった |
| 57 | スタートの検索に Web の結果が出なかった。エクスプローラーは「PC」を開き、拡張子と隠しファイルが見え、ファイルの右クリックで「送る」「プロパティ」のある旧形式のメニュー。タスクバーは左寄せで、タスク ビュー・検索・ウィジェットのボタンが無く、時計に秒。全体が濃い色 |
| 58 | タスクバーのアイコンの右クリックのメニューの文言は「タスクバーからピン留めを外す」で、本文の「タスク バーからピン留めを外す」と違ったので直した。スタートのピン留めの右クリックは「スタートからピン留めを外す」で、本文どおり。Edge はスタートにピン留めされたまま残した |
| 59 | スタートから UniGet UI 2026.3.0 を起動した。左の「パッケージマネージャー」で WinGet と Scoop が有効・「利用可能」。版はそれぞれの「バージョンを表示」で出た（WinGet v1.29.380、Scoop v0.6.0 - Released at 2026-09-30）。本文の「見つかっている（版が出ている）」と違ったので直した。インストール済みの一覧に `scoop-search` 2.1.0（Scoop: main）と `Devolutions.UniGetUI` 2026.3.0 |
| 60・61 | スタートから開いた通常の Windows PowerShell は、Windows Terminal の中に開いた。手順 61 を GitHub のコピーボタンからコピーして右クリックで貼ると、「警告 複数の行を含むテキストを貼り付けようとしています…」の確認（「強制的に貼り付け」「キャンセル」）が出た。強制的に貼り付けると、完結した行から順に動いた。`ComputerName : PR104-VERIFY`・`Keyboard : kbd101.dll` などが出た |
| 64（本文の起動経路） | Windows Terminal の通常の窓に貼った。winget は入っている旨（`Found an existing package already installed.`・`No available upgrade found.`、英語）を出し、UAC の確認（Autologon、Microsoft Corporation、このコンピューター上のハード ドライブ）で「はい」を選ぶと Autologon の窓が開いた（`Username` が <WIN_USER>、`Domain` が <HOSTNAME>）。パスワードを入れて `Enable` を押すと `Autologon successfully configured.` の旨。以後の再起動で、入力無しに自動サインインした |

- 手順 39・52・53 の分岐は、[ロールバック](../windows-setup.md#ロールバック)の手順 18・19・26・27・37・38 で戻した。手順 38 の再起動の後、名前は `<HOSTNAME>`、キーボードは `kbd106.dll`・`PCAT_106KEY`・`7`・`2`、`RealTimeIsUniversal` は無し。手順 27 は何も出さなかった
- 時計: `RealTimeIsUniversal=1` で起動すると、システムの時刻が 9 時間進み、VBoxService が 32,369,482 ミリ秒戻した（VM の RTC は地方時）。ロールバックの再起動では逆に 9 時間遅れ、32,418,700 ミリ秒進めた。本文の「再起動の後に、時刻を同期し直す」に当たる
- 実施手順 62・63 の WSL 2 は扱っていない（この VM では動かない。上の付録）

**ping とリモート デスクトップ（2 枚目の NIC で）**:

- 2 枚目の NIC を足した直後（パブリック）は、外からの ping が届かなかった
- 管理者の窓で、手順 36 の `$LAN_IF` を `'イーサネット 3'` に直して貼り、手順 42（`AllowComputerToTurnOffDevice : Disabled`。`WakeOnMagicPacket` は `Unsupported`）・43（Private）・44（RDP の 3 規則が Private）・46（ping の 2 規則）を貼った
- AlmaLinux の 2 台とホストからの ping は、どれも 0% loss
- RDP: AlmaLinux の VM の FreeRDP から、試験用の資格情報で 192.168.56.107 につないだ。Kerberos は失敗して NTLM で認証され、ログインできた
  - `quser` で `rdp-tcp#0` が Active。RDP のセッションの画面（1280x800、`TerminalServerSession : True`）を撮った。PC の画面はロック画面になった
  - 切断すると `Disc`。昇格したプロセスから `tscon.exe <ID> /dest:console` を実行すると、`console` が Active に戻り、PC の画面はロックされていなかった
- 再起動すると、ホストオンリーのネットワーク（既定ゲートウェイの無い「識別されていないネットワーク」）の「イーサネット 3」はパブリックに戻った。NAT の「イーサネット」はプライベートのまま。以後、2 枚目の NIC を使う確認の前に手順 43 を貼り直した

**Wake on LAN を使う（任意）**:

- この節の手順 2 は `LAN_IF = イーサネット`（NAT の NIC）
- この節の手順 3: `Set-NetAdapterAdvancedProperty` が `*WakeOnMagicPacket` を見つけられない旨のエラーで、Wake の行の表は空。`MacAddress` は出た。Intel PRO/1000 MT Desktop Adapter の Windows 標準の（受信トレイ）ドライバーには標準の項目が無く、本文の「無い旨のエラーが出たら」の分岐に当たった
- この節の手順 8 も同じエラー（Set と Get の 2 つ）
- この節の手順 4: `shutdown.exe /r /fw /t 0` は `入力された環境オプションが見つかりませんでした。(203)` を出し、再起動しなかった。VirtualBox の EFI がこの指定に対応していないとみて、本文に分岐を足した
- この節の手順 5〜7 は、VM ではマジック パケットで電源を入れられないので行っていない

**リモートから再起動する手段を増やす（任意）**:

| この節の手順 | 結果 |
|---|---|
| 2 | 本文のままでは `LAN_IF = イーサネット`・`WATCHDOG_HOST = 10.0.2.2`（NAT の NIC と、その既定ゲートウェイ）。2 枚目の NIC で試すため、`$LAN_IF = 'イーサネット 3'`・`$WATCHDOG_HOST = '192.168.56.82'` に直して貼り直した |
| 3 | `AutoReboot : 1`（もとから 1） |
| 4 | `FPS-SMB-In-TCP  True  Private  Inbound  Allow` と `LocalAccountTokenFilterPolicy : 1` |
| 4 のトリガー | AlmaLinux の VM に `samba-common-tools` 4.23.5 を入れ、`net rpc shutdown -r -f -t 0 -I 192.168.56.107 -U '<WIN_USER>%<PASS>'` で `Shutdown of remote machine succeeded`。約 1 分で再起動し、自動サインインした。System のイベント 1074 は、`wininit.exe (192.168.56.82)` が `<HOSTNAME>\<WIN_USER>` の代わりに再起動、理由は「レガシ API シャットダウン」 |
| 5（本文のまま） | `Enable-PSRemoting` は成功したが、最後の `Get-NetFirewallRule -DisplayGroup 'Windows Remote Management'` が見つからない旨のエラー（日本語の Windows の表示名は「Windows リモート管理」） |
| 5（規則の実際） | グループ `@FirewallAPI.dll,-30267`（Windows リモート管理）の規則は `WINRM-HTTP-In-TCP`（パブリック、接続元 `LocalSubnet`）と `WINRM-HTTP-In-TCP-NoScope`（ドメイン・プライベート、接続元 `Any`）。`-PUBLIC` の規則は無い。本文のままでは、前者がプライベートになり、後者は有効のまま残った（ファイアウォールのイベント 2099 の時刻とプロファイルで確かめた） |
| 5（直した形） | `WINRM-HTTP-In-TCP` を `-Enabled True -Profile Private`、`WINRM-HTTP-In-TCP-NoScope` を無効にし、`-Group '@FirewallAPI.dll,-30267'` で表示した。`WINRM-HTTP-In-TCP  True  Private`・`WINRM-HTTP-In-TCP-NoScope  False`・`RemoteAddress : LocalSubnet`。本文をこの形に直した |
| 5 のトリガー（別の Windows の形） | 別の Windows は使えなかったので、VM の中から自分の IP に `Invoke-Command -ComputerName 192.168.56.107 -Credential …` を送った。`TrustedHosts` が空だと「認証スキームが Kerberos と異なる場合、またはクライアント コンピューターがドメインに参加していない場合は、HTTPS トランスポートを使用するか、または宛先コンピューターが TrustedHosts 構成設定に追加されている必要があります」で止まった。`Set-Item WSMan:\localhost\Client\TrustedHosts -Value 192.168.56.107 -Concatenate -Force` の後は通り、High Mandatory Level で動いた。`TrustedHosts` は空に戻した。本文に注意を足した |
| 5 のトリガー（AlmaLinux から） | pywinrm 0.5.0（NTLM、HTTP 5985）で、`whoami /groups` は High Mandatory Level。`Restart-Computer -Force` で再起動し、自動サインインした。イベント 1074 は `wmiprvse.exe` |
| 6 | `net-watchdog  Ready`。登録の直後は `LastTaskResult : 267011`（まだ動いていない）・`NextRunTime` が空で、起動時のトリガーなので次の起動まで動かなかった。本文に注意を足した |
| 6（起動の後） | 起動時に動き（`LastTaskResult : 0`）、その後 5 分ごとに動いた。稼働 60 分未満の間は `Fails : 0` |
| 6（届かないとき） | 相手の AlmaLinux の VM（192.168.56.82）を 01:34 に止めた。稼働 60 分を過ぎた最初の実行（02:24）から `Fails` が 1・2・3・4・5 と 5 分ごとに増え、6 回目の 02:50:00 にイベント 1074（`wmiprvse.exe` が `NT AUTHORITY\SYSTEM` の代わりに再起動）で再起動した。02:50:31 に起動して自動サインインし、起動時の実行で `Fails : 0` に戻った。その後も 5 分ごとに動き、稼働 60 分未満なので何もしなかった |
| 7 | `中断: claude-remote-control のタスクが無い（…）`（このタスクを作っていないので、期待どおり） |
| 8 | `FPS-SMB-In-TCP  False  Private` |
| 9（本文のまま） | `Disable-PSRemoting` の警告（リスナー・ファイアウォールの例外・`LocalAccountTokenFilterPolicy` は手で戻す旨）の後、`-DisplayGroup 'Windows Remote Management'` が見つからない旨のエラー。サービスは `Stopped`・`Manual` になったが、`WINRM-HTTP-In-TCP` は `True  Private` のまま残った |
| 9（直した形） | `-Group '@FirewallAPI.dll,-30267'` で無効にし、`WINRM-HTTP-In-TCP` と `-NoScope` がどちらも `False`。TCP 5985 の待ち受けも無くなった。`WINRM-HTTP-In-TCP` の `Profile` は `Private` のまま（手順 5 で変えたもの。無効なので働かない）。WinRM のリスナーの設定は残る（サービスが止まっているので待ち受けない） |
| 10 | `LocalAccountTokenFilterPolicy : 0`（値を消すのではなく 0 を書く。0 は値が無いときと同じ働き） |
| 11 | 何も出なかった（タスクが消えた）。値のキーと `net-watchdog.ps1` も消えたが、空のキー `HKLM:\SOFTWARE\setup-notes` と空のフォルダー `C:\ProgramData\setup-notes` は残った。本文に箇条書きを足し、検証では手で消した |

- Wake on LAN の節の手順 4 の後、管理者の窓から `Restart-Computer` で再起動すると、「再起動しています」の画面のまま 20 分あまり進まなかった
  - VBox.log には、ディスクのリセットの後に `TM: Giving up catch-up attempt at a 809 068 784 843 ns lag` と、ゲストのハートビートが 809 秒途切れた記録があった（Hyper-V の上の VirtualBox の停止とみている）
  - ホストからのキーでも進まず、`VBoxManage controlvm reset` でリセットすると、VM のファームウェアの設定の画面（UiApp）が開いた。「Continue」で Windows が起動し、自動サインインした。イベント 41・6008 は出ていない
  - UiApp が開いたのが、Wake on LAN の節の手順 4 の指定の名残かは分からない

**更新**:

| この節の手順 | 結果 |
|---|---|
| 1 | `Scoop was updated successfully!`。`scoop status` は `Scoop is up to date.`・`Everything is ok!` |
| 2 | 条件に当たらない（`Everything is ok!`）。最初のまとめ貼りでは貼ったが、出力は残っていない |
| 3 | 4 つの ID とも `No available upgrade found.`（英語） |
| 4 | `wsl.exe --update` は最新である旨。`dnf -y upgrade` は `WSL_E_DISTRO_NOT_FOUND`（この VM では AlmaLinux-10 を入れられていない） |
| 5 | `PSWindowsUpdate 2.2.1.5`（`C:\Users\<WIN_USER>\Documents\WindowsPowerShell\Modules\PSWindowsUpdate\2.2.1.5`） |

- Windows Terminal の窓に貼ると、この節の手順 1・4・5（複数行）では複数行の警告が出て、手順 2・3（1 行）では出なかった

**ロールバック**:

- 始める前に、ゲストの「イーサネット 2」を有効に戻し、OS を止めて 2 枚目の NIC を外し、スナップショット `pr104-before-rollback-20261008` を撮った（利用者はここへ戻せる）
- 各ツールの Windows 11 のロールバックを先に流した（それぞれの検証記録の 2026-10-08 の付録）
- この節の手順 1〜17 は、管理者ではない Windows PowerShell（Windows Terminal の中）に貼った

| この節の手順 | 結果 |
|---|---|
| 1 | `HideFileExt : 1`・`Hidden : 2`・`Start_TrackDocs : 1`、`LaunchTo` は出なかった |
| 2 | `この操作を正しく終了しました。` と `False` |
| 3 | 8 つの値がすべて `1` |
| 4 | 3 つの値は何も出なかった。画面のタスクバーは中央寄せで、検索ボックスとタスク ビューのボタンが出た |
| 5 | `1` が 2 つ。画面が淡色になった |
| 6 | 2 つの値は何も出なかった |
| 7 | Microsoft IME の設定の画面が開いた。「キーとタッチのカスタマイズ」を開くと、「キーの割り当て」の「各キー / キーの組み合わせに好みの機能を割り当てます」のスイッチが「オン」で、「Ctrl + Space」は「IME-オン/オフ」（選択肢は「IME-オン/オフ」と「なし」）。本文の 2 つの方法のうち、スイッチをオフにした。`IsKeyAssignmentEnabled` が 0 になった（`KeyAssignmentCtrlSpace` は 2 のまま） |
| 8 | `戻した: MicrosoftEdgeAutoLaunch_<番号>` と `戻した: OneDriveSetup`（Teams のキーは無かった） |
| 9 | 約 15 分かかった。11 個の ID のうち 9 個と Teams（`Microsoft.Teams` 26198.304.4946.9672）は `Successfully installed` で入った（Clipchamp・天気・Office Hub・To Do・フィードバック Hub・問い合わせ・Power Automate・Outlook・ウィジェットの Windows Web Experience Pack）。入らなかった 2 つは次のとおり |
| 9（ニュース `9WZDNCRFHVFW`） | `Failed to install or upgrade Microsoft Store package. Error code: 0x80073cfb`。AppX のイベント 404・474 は、イメージに残っていた `Microsoft.BingNews_1.0.2.0_x64__8wekyb3d8bbwe`（SYSTEM 用に Staged）と同じ ID で中身が違うので展開を止めた、というものだった |
| 9（Solitaire `9WZDNCRFHWD2`） | `No package found matching input criteria.`（msstore のソースにその ID が無い。名前で探しても見つからなかった） |
| 9（登録し直し） | どちらも PC にプロビジョニングされたパッケージとして残っていたので、`Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.BingNews_8wekyb3d8bbwe`（と Solitaire の同じ形）で登録し直すと、`Microsoft.BingNews` 1.0.2.0 と `Microsoft.MicrosoftSolitaireCollection` 4.27.9181.0 が `Ok` になった。本文に箇条書きを足した |
| 10〜12 | PowerShell 7・PowerToys（`PowerToys (Preview) x64`）・UniGet UI とも `Successfully uninstalled`、続く `winget list` は `No installed package found matching input criteria.`。動いていた PowerToys と UniGet UI は閉じられた |
| 13（本文のまま） | `Are you sure? (yN):` に `y` を入れると、`Uninstalling 'scoop-search'` の後に `WARN  Couldn't remove ~\scoop\apps\scoop-search: 項目 …\current を削除できません: パス 'current' へのアクセスが拒否されました。` と、`Couldn't remove ~\scoop\apps: …` で止まった。`Scoop has been uninstalled.` は出ず、scoop 本体は消えていた（貼り直すと `scoop.ps1` が見つからない旨）。ユーザーの PATH に `scoop\shims` が残った |
| 13（原因） | `current` のジャンクションに読み取り専用の属性が付いていた。scoop 0.6.0 の `bin/uninstall.ps1` は、アプリの `current` の読み取り専用を外さずに消そうとする（[参考資料](../reference/windows-setup.md)） |
| 14（本文のまま、13 が止まった後） | `Remove-Item … -ErrorAction SilentlyContinue` も消せず、`True`・`False`。`attrib.exe -R /L` で `current` の読み取り専用を外してから貼り直すと、`False` が 2 行になった。PATH の `scoop\shims` は残った |
| 13（直した形） | 手順 20・21 と `scoop install scoop-search` で入れ直し（`current` は `ReadOnly, Directory, ReparsePoint`）、1 行目に `current` の読み取り専用を外す行を足したブロックを貼った。`y` を入れると `Uninstalling 'scoop-search'`・`Removing ~\scoop\shims from your path.`・`Scoop has been uninstalled.` で終わり、ユーザーの PATH から `scoop\shims` も消えた。本文をこの形に直した |
| 14（直した 13 の後） | `False` が 2 行 |
| 15 | `消した: C:\Users\<WIN_USER>\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`（プロファイルにはその 1 行だけがあった） |
| 16 | `$OLD_EXECUTION_POLICY = 'Undefined'`（2026-10-06 の実施手順 17 の記録）で、表の `CurrentUser` を含むすべてが `Undefined` |
| 17 | `WSL_E_DISTRO_NOT_FOUND`（AlmaLinux-10 は入れられていなかった）。一覧はディストリビューションが無い旨 |
| 18 | スタートで「Windows PowerShell」を探し、右側の「管理者として実行」を押した。UAC の確認（Windows PowerShell、発行元 Microsoft Windows）で「はい」を選び、conhost の窓が開いた |
| 18 の後の貼り付け | この節の手順 15 でプロファイルの行を消したので、実施手順 38 の 3 行の試験を右クリックで貼ると、`}`・`'3 行目'`・`'2 行目'`・`'1 行目'`・`& {` の逆順に入った（本文のこの節の手順 15 の「右クリックで貼ると、行が逆順になる」のとおり）。Ctrl+C で捨て、Ctrl+V で貼ると `1 行目`・`2 行目`・`3 行目` の順に動いた。この節の手順 19〜38 は Ctrl+V で貼った |
| 19 | `LAN_IF = イーサネット` |
| 20 | 管理者の窓から起動したので UAC の確認は出ず、Autologon の窓（`Username` <WIN_USER>、`Domain` <HOSTNAME>）が開いた。`Disable` を押すと「AutoLogon is disabled.」の窓が出て、「OK」で Autologon も閉じた。`AutoAdminLogon` は 0 |
| 21（本文のまま、管理者の窓） | `Found Autologon [Microsoft.Sysinternals.Autologon]` の後、`The package installed for user scope cannot be uninstalled when running with administrator privileges.` で外れなかった（手順 64 は管理者ではない窓で `--scope user` で入れる）。続く `AutoAdminLogon` は 0 |
| 21（管理者ではない窓） | 同じブロックをこの節の手順 1〜17 の窓に貼ると、`Successfully uninstalled` と `0`。`Autologon64.exe` も消えた。本文のこの節の手順 21 を管理者ではない窓で行う形に直し、節のリードも直した |
| 22 | `DevicePasswordLessBuildVersion : 2`（2026-10-06 の実施手順 37 の記録では `HelloOnly` は 2） |
| 23・24 | どちらも何も出なかった |
| 25 | `wsl.exe --uninstall` は何も表示しなかった。`Disable-WindowsOptionalFeature` は `RestartNeeded : True`。WSL のパッケージは消え、仮想マシン プラットフォームは `Disabled` になった |
| 26 | `kbd106.dll`・`PCAT_106KEY`・`7`・`2`（手順 53 は前の分岐の確認の後に戻してあったので、同じ値の書き直し） |
| 27 | 何も出なかった |
| 28 | `Scancode Map を消した` |
| 29 | `$OLD_DOWNLOAD_MODE = 'Lan'`（2026-10-06 の実施手順 37 の記録）で `Lan` |
| 30 | 何も出なかった |
| 31 | システムのプロパティの「リモート」タブが開き、「このコンピューターへのリモート アシスタンス接続を許可する(R)」のチェックを入れて「OK」を押すと、窓が閉じた。`fAllowToGetHelp` は 1、リモート アシスタンスの規則 15 個がすべて有効になった（パブリック向けの `RemoteAssistance-In-TCP-EdgeScope` なども）。手順 45 の前の規則の状態は記録していないので、元に戻ったかは確かめられない。本文の「手順 45 の前に無効だった規則（パブリック向けなど）まで有効になりうるので、画面で戻す」の理由は観察と合わないので、箇条書きを観察に合わせて直した |
| 32 | 3 つの規則が `False  Any` |
| 33 | `イーサネット  Public`（2026-10-06 の実施手順 37 の `LanCategory` は `Public`） |
| 34 | `AllowComputerToTurnOffDevice : Enabled` |
| 35 | `powercfg /hibernate on` が「システム ファームウェアは休止状態をサポートしていません。」の旨で失敗し、`HibernateEnabled: 0`。本文に箇条書きを足した |
| 36 | `このコンピューターでは sudo が無効化されています。`（本文の「無効になった旨の英語の行を出す」を直した）、`LongPathsEnabled : 0`、`AllowDevelopmentWithoutDevLicense : 0` |
| 37 | `$OLD_PC_NAME = '<HOSTNAME>'` で `すでにこの名前: <HOSTNAME>`（名前は前の分岐の確認の後に戻してあった） |
| 38 | `Restart-Computer` の後、起動の途中の「機能をカスタマイズしています。100% 完了。」（この節の手順 25 の仮想マシン プラットフォームを外す処理）のまま 20 分進まなかった。下の「起動が止まったこと」 |
| 39 | 電源を入れ直した後、自動サインインはされずロック画面になり（この節の手順 20 のとおり）、パスワードでサインインした。メモ帳で、Caps Lock の位置のキー（0x3A）を押しても Ctrl にはならず（`a` を押すと全選択ではなく文字が入った）、JIS 配列の Caps Lock（Shift+英数）でオンにすると `A`・`B` と大文字になり、もう一度で小文字に戻った（JIS 配列の PC では Caps Lock は Shift+英数）。ファイルの右クリックは新しい形のメニュー（最後に「その他のオプションを確認」）。エクスプローラーは「ホーム」で開き、隠しファイルは見えず、淡色で、タスクバーは中央寄せ（検索ボックス・タスク ビューあり）、時計に秒は無かった |
| 40・41 | 新しく開いた管理者ではない窓（Windows Terminal の中。この節の手順 15 の後なので Ctrl+V で貼った）で、`PSWindowsUpdate を外した`。`Documents\WindowsPowerShell\Modules` は空になった |

**起動が止まったこと（ロールバックの手順 38）**:

- 05:06 UTC に再起動し、05:07 に VBoxService が動き出した後、05:08〜05:12 にゲストが 240 秒止まった（VBox.log の `TM: Giving up catch-up attempt at a 240 078 329 157 ns lag`）。その後はハートビートが戻ったが、ディスクの読み書きが 0 のまま、画面は「機能をカスタマイズしています。100% 完了。」で止まり、ゲストのセッションも始められなかった
- 05:28 に `VBoxManage controlvm reset` でリセットした。ファームウェアは `BdsDxe: failed to load Boot0003 "Windows Boot Manager" from HD(2,GPT,…)/\EFI\Microsoft\Boot\bootmgfw.efi: Not Found` を出した後（外した USB の VHD の起動項目とみている）、Windows の起動の回転表示のまま、また 11 分進まなかった（CPU は 5% ほどで、待っている状態）
- 05:40 に電源を切って入れ直すと、2 分でロック画面まで起動した。サインインの後、この節の手順 25 の結果（WSL のパッケージ無し、仮想マシン プラットフォームは `Disabled`）は保たれていた
- 実施手順の確認の途中（Wake on LAN の節の手順 4 の後）でも同じような停止があった。Hyper-V の上の VirtualBox（NEM）でゲストが止まる問題とみていて、手順の誤りとは扱っていない

**検証の手順で起きたこと（ロールバック）**:

- 2 枚目の NIC を外すために OS を止めた後、一時的に足していた共有フォルダー（検証用のエージェントが使う）が消えていたので、足し直した
- VM の GUI の窓がいつの間にか閉じ、ゲストの画面が 360x249 に縮んで、貼り付けのクリックが外れた（そのとき Git の手順 6 は実際には動いていた）。`VBoxManage controlvm setvideomodehint 1274 1029 32` で戻した
- 始めたときの事故（下の「検証の手順で起きたこと」）で動いた `read-wsl-state.ps1` は、ゲストの `C:\verify\wsl-raw-530c2a261db84989bd0f2629cdf8cf54` も作っていた（残してある）
- 最後に、ゲストの検証用のエージェントを止め、`C:\verify\request-Admin.ps1`・`request-User.ps1` を始める前の控えに戻し（SHA256 は `C3BAD24F…`・`69A5A62C…` で一致）、今回の `C:\verify\pr104`・`C:\verify\pr104-backup` を消し、一時的な共有フォルダーを外した。VM は動いたまま（サインイン済み）にした。AlmaLinux の VM 4 台は電源を切ってある
- 生の証跡（画面 214 枚・ログ・ハーネス）は、ローカルの `.verification/evidence/pr104-20261008` に控えた（この PR には含めない。検証用のパスワードを含むファイルが無いことを確かめた）

**検証の手順で起きたこと**:

- 始めたとき、ゲストの検証タスクを起動すると、前の検証（上の付録）が置いた要求のファイルがそのまま動いた。管理者のタスクは `read-wsl-state.ps1` を動かして、ゲストの `C:\verify\wsl-after-step55-recovery-20261006.json` を上書きした（ホストに控えた前の証跡は残っている）。通常権限のタスクの `show-autologon-location` は失敗し、記録のファイルは変わらなかった。要求のファイルは `C:\verify\pr104-backup` に控えてから差し替えた

## 付録: 別の Windows からの再起動と、WinRM の手順 5 の貼り直しを確かめた記録（2026-10-08）

**VM とホストの実機での追加検証**。上の付録で確かめられなかった、[リモートから再起動する手段を増やす](../windows-setup.md#リモートから再起動する手段を増やす任意)の節の「別の Windows で動かすトリガー」を確かめた。再起動される側（この PC）は VM、送る側（別の Windows）は最後にホストの実機を使った。時刻は UTC。

**環境**:

| 項目 | 値 |
|---|---|
| 再起動される側 | `windows11-verify-20261006`（上の付録と同じ VM。`<HOSTNAME>`、試験用のローカル アカウント `<WIN_USER>`）。上の付録のロールバックの後の状態をスナップショット `pr104-after-rollback-20261008` に控え、ロールバックを流す前のスナップショット `pr104-before-rollback-20261008`（再起動の節の手段は元に戻した後）に戻してから、再起動の節の手順 2〜5 を管理者の conhost の窓に貼り直した。終わった後は `pr104-after-rollback-20261008` に戻した（電源は切ったまま） |
| 送る側（1 つ目） | 再起動される側の VM のリンク クローン（`pr104-baseline-20261008` から作り、名前を `PR104-SENDER` に変えた）。2 台を VirtualBox の NAT ネットワーク（10.0.77.0/24）でつないだ。後で消した |
| 送る側（2 つ目） | 手元の Windows 11 Enterprise 評価版の ISO から無人インストールした新しい VM。インストールが止まったので使わずに消した |
| 送る側（3 つ目） | ホストの実機（`<HOST_PC>`。Windows 11 Pro 26H2 の 26300、ワークグループ、Microsoft アカウントでサインイン、Windows PowerShell 5.1.26100.9444）。利用者の許可を得て使った。再起動される側の VM をホストオンリーのネットワーク（192.168.56.0/24、VM は 192.168.56.108）につなぎ替え、VM の中の VirtualBox のホストオンリーのアダプター「イーサネット 2」（192.168.56.1 で重なる）を無効にした |

**再起動の節の手順 5 の貼り直しと手順 9**:

- `pr104-before-rollback-20261008` に戻した直後（以前の版の再起動の節の手順 9 の後で、`WINRM-HTTP-In-TCP` は無効・プライベート）に本文のままの再起動の節の手順 5 を貼ると、`Enable-PSRemoting` が `WinRM は要求を受信するように更新されました。`・`WinRM サービスが開始されました。` などの後に `Set-WSManQuickConfig : エラー:1 つ以上の更新手順を終了できませんでした。` で止まり、後ろの 3 行は動かなかった
- このとき `winrm quickconfig -force` は「WinRM ファイアウォールの例外を有効にします。」の後に「WinRM のファイアウォールを有効にできません。」。止まった後の規則は `WINRM-HTTP-In-TCP  True  Private`・`WINRM-HTTP-In-TCP-NoScope  True`（接続元 Any）で、接続元を絞らない規則が開いたまま残った
- 規則の状態を変えて `Enable-PSRemoting -Force -SkipNetworkProfileCheck` を流した結果

| `WINRM-HTTP-In-TCP` の前の状態 | 結果 |
|---|---|
| 無効・プライベート | 止まる。2 つの規則とも有効になる |
| 無効・パブリック（既定） | 通る（`WinRM ファイアウォールの例外を有効にしました。`）。2 つの規則とも有効になる |
| 有効・プライベート（`-NoScope` は無効） | 通る。何も出さず、規則も変えない |

- 再起動の節の手順 9 に規則をパブリックに戻す行を足した形を貼ると、`WINRM-HTTP-In-TCP  False  Public`・`-NoScope  False`。続けて手順 5 の 1 行目に同じ行を足した形を貼ると、`WinRM ファイアウォールの例外を有効にしました。` の後に `WINRM-HTTP-In-TCP  True  Private`・`-NoScope  False`。手順 5 をもう一度貼っても同じ表になった
- 以前の版の再起動の節の手順 9 を貼った後に、直した手順 5 を貼っても通り、同じ表になった
- 本文の再起動の節の手順 5（1 行目と箇条書き）と手順 9 をこの形に直した。参考資料にも理由を足した

**送る側がクローンのとき（使えなかった）**:

- クローンの通常権限の conhost の窓（Windows PowerShell 5.1）で、`shutdown /r /f /t 0 /m \\<HOSTNAME>` は `<HOSTNAME>: アクセスが拒否されました。(5)`（終了コード 5）。送る側のユーザーは、再起動される側と同じ名前・同じパスワード
- 別に作った標準ユーザー（再起動される側に無い名前）の窓でも同じ (5)。`net use \\<HOSTNAME>\IPC$ /user:<HOSTNAME>\<WIN_USER>` は、`\\<HOSTNAME>\IPC$ のパスワードまたはユーザー名が無効です。` の後に `'<HOSTNAME>' に接続するための '<HOSTNAME>\<WIN_USER>' のパスワードを入力してください:` と聞き、正しいパスワードを入れても `システム エラー 1326 が発生しました。`
- 再起動される側のセキュリティのログ（4625、NTLM）: 再起動される側に無いユーザーは副状態 `0xc0000064`、誤ったパスワードは `0xc000006a`。正しい資格情報（同じ名前のユーザーの素通しと、`net use` で入れたもの）は、状態 `0xc000006d`・副状態 `0x0`・失敗の理由「ログオン中にエラーが発生しました」だった
- クローンは sysprep をしていないので、マシンの SID が再起動される側と同じ。SID の重複した PC の間の NTLM の認証が拒否されたとみて、送る側に使うのをやめた（原因は確かめていない）

**送る側がホストの実機のとき**:

- つなぎ替えた直後の再起動される側の接続（`イーサネット`）は、`識別されていないネットワーク`・`Public` だった。管理者の conhost の窓で `$LAN_IF = 'イーサネット'` を入れてから実施手順 43 を貼り、`Private` にしてから試した（再起動の節の手順 4・5 の受信規則はプライベートだけで有効）。SMB での再起動の後は `Public` に戻ったので、WinRM を試す前に `Set-NetConnectionProfile` で `Private` に戻した
- `<HOSTNAME>` は mDNS（`<HOSTNAME>.local`）で、VM の IPv6 のリンクローカル アドレスと 192.168.56.108 に解決された。ping と TCP 445・5985 は届いた（`Test-NetConnection` は IPv6 のリンクローカルを使った）
- 始める前のホスト: WinRM のサービスは `Stopped`・`Manual`、`HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WSMAN\Client` に `trusted_hosts` の値は無かった。受信規則 `WINRM-HTTP-In-TCP`・`-NoScope` は無効
- SMB（再起動の節の手順 4）
  - `net use` をせずに `shutdown /r /f /t 0 /m \\<HOSTNAME>` を実行すると、`<HOSTNAME>: Access is denied.(5)`（このときの端末は UTF-8 のコード ページで、表示が英語）。再起動される側に 4624・4625 は残らなかった
  - `net use \\<HOSTNAME>\IPC$ /user:<HOSTNAME>\<WIN_USER>` を、非表示の conhost の中の cmd で実行し、パスワードのプロンプトにコンソールの入力としてパスワードを入れた。`\\<HOSTNAME>\IPC$ のパスワードまたはユーザー名が無効です。`・`'<HOSTNAME>' に接続するための '<HOSTNAME>\<WIN_USER>' のパスワードを入力してください:`・`コマンドは正常に終了しました。`。再起動される側の 4624 は、NTLM・ワークステーション名 `<HOST_PC>`・昇格したトークン
  - 続けて `shutdown /r /f /t 0 /m \\<HOSTNAME>` は何も出さずに終了コード 0。再起動される側は 08:56:35 に起動し、約 2 分で自動サインインした。System のイベント 1074 は、`wininit.exe ([<ホストの IPv6 のリンクローカル>])` が `<HOSTNAME>\<WIN_USER>` の代わりに再起動を始めた、理由コード `0x800000ff`
  - ホストの `net use` の一覧には `Disconnected  \\<HOSTNAME>\IPC$` が残り、`net use \\<HOSTNAME>\IPC$ /delete` で `was deleted successfully.` と消えた
  - パスワードを標準入力のリダイレクトで渡した `net use` は 1326 で失敗し、再起動される側にログは残らなかった（本文の形ではない）。`New-SmbMapping` で IP あてに資格情報を渡すとつながった（確かめた後に外した）
- WinRM（再起動の節の手順 5）
  - `TrustedHosts` が無いまま、Windows PowerShell 5.1 で `Invoke-Command -ComputerName <HOSTNAME> -Credential …` を実行すると、`WinRM クライアントは要求を処理できません。認証スキームが Kerberos と異なる場合、またはクライアント コンピューターがドメインに参加していない場合は、 HTTPS トランスポートを使用するか、または宛先コンピューターが TrustedHosts 構成設定に追加されている必要があります。…`（`ServerNotTrusted,PSSessionStateBroken`）。ホストの WinRM のサービスは止まったままで、ここまで進んだ
  - 利用者が、ホストの管理者の Windows PowerShell で、本文の手順 5 の注意の 3 つ（`Start-Service WinRM`、`(Get-Item WSMan:\localhost\Client\TrustedHosts).Value` で控える、`Set-Item WSMan:\localhost\Client\TrustedHosts -Value <HOSTNAME> -Concatenate -Force`）を貼った。WinRM は `Running`、`trusted_hosts` は `<HOSTNAME>`。このとき、ホストでも TCP 5985 を System が待ち受けた（受信規則は無効のまま）
  - 管理者ではない Windows PowerShell 5.1 から、コンピューター名を付けないユーザー名 `<WIN_USER>` の資格情報で `Invoke-Command -ComputerName <HOSTNAME> … -ScriptBlock { hostname; whoami; … }` を送ると、`<HOSTNAME>`・`<hostname>\<WIN_USER>`・`High Mandatory Level`（4.8 秒）
  - `-ScriptBlock { Restart-Computer -Force }` は、エラー無しに 5.3 秒で戻り、何も出さなかった。再起動される側は 09:15:59 に起動し、自動サインインした。System のイベント 1074 は、`wmiprvse.exe` が `<HOSTNAME>\<WIN_USER>` の代わりに再起動を始めた、理由コード `0x80070015`。4624 は NTLM・ワークステーション名 `<HOST_PC>`・昇格したトークン
  - 資格情報は、`Get-Credential` の窓ではなく、パスワードのファイルから作った `PSCredential` で渡した（窓での入力は確かめていない）
  - 戻し（再起動の節の手順 9 の箇条書き）: 利用者が同じ管理者の窓で `Set-Item WSMan:\localhost\Client\TrustedHosts -Value '' -Force` と `Stop-Service WinRM` を貼った。WinRM は `Stopped`・`Manual`、TCP 5985 の待ち受けは無くなった。`trusted_hosts` は値が無い状態には戻らず、空の値で残った。ホストの `net use` の一覧に、再起動される側への接続は残っていない
- 本文に足したもの: 再起動の節の手順 4 の別の Windows からの形（`net use` → `shutdown /m` → `net use … /delete`、`net use` をしないと (5)、パスワードの前の表示）、手順 5 の `TrustedHosts` を先に足す順・`Invoke-Command` の成功の条件と `-ComputerName` の名前、手順 9 の送る側の戻し方（`TrustedHosts` とサービス。送る側のサービスが止まっていれば先に動かす）

**検証の手順で起きたこと**:

- クローンの通常権限の conhost の窓には、SendInput の Unicode の文字が入らなかった（Enter だけ届いた）。コマンドはクリップボードと Ctrl+V で貼り、パスワードのプロンプトには窓の右クリックで貼って、すぐにクリップボードを消した
- 新しい VM の無人インストールは、開始から 13 分の `AHCI#0: Port 0 reset` の後、画面が黒いまま CPU だけ回り、ディスクへの書き込みが 35 分止まった。一時停止と再開でも動かなかったので、VM を消した（Hyper-V の上の VirtualBox の停止とみている）
- `VBoxManage unattended install` は、渡した使い捨てのユーザー（その VM だけのもの。再起動される側の試験用のパスワードとは別）のパスワードを平文で表示した。VM と応答のファイル（`autounattend.xml`）は消した
- ホストで UAC の確認を出して管理者の窓を開く操作は、このツールの安全の判定で止められたので、ホストの管理者の操作は利用者が行った
- 生の証跡は、ローカルの `.verification/evidence/pr104-20261008/win2win` に控えた（この PR には含めない。検証用のパスワードを含まないことを確かめた）
