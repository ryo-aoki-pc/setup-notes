# Windows 11 の初期設定の手順（インストール直後の更新・貼り付けの設定・scoop・UniGet UI・表示・電源・リモート・WSL・OpenSSH・Git・Firefox・WezTerm・Neovim・AI エージェント）の検証記録

[手順書](../windows-setup.md)・[ロールバックと注意点](../extra/windows-setup.md)

## 2026-10-10 にまとめた手順（Windows 11 で通していない）

**2026-10-10 に、12 本の手順書の Windows 11 の部分と windows-openssh-server.md を、この文書にまとめた。まとめた後の手順は、Windows 11 で通していない**（[付録](#付録-13-本の手順書をまとめた記録2026-10-10)）。

- 足した項: 「HackGen Console NF」「OpenSSH サーバー」「Git for Windows」「Firefox」「WezTerm」と、再起動の後の「SSH でログインを確かめる」から「Codex・Grok のプラグイン」までの 12 項。任意節は OpenSSH サーバーの 4 つと「Neovim を既定のエディタにする（任意）」を足した。更新は 4 項に分け（3 項を足した）、ロールバックは 6 項を足した
- 移したコマンドは、もとの手順書で確かめたもの（どこまで確かめたかは、後ろの「統合前の記録」のそれぞれの節）。窓の使い分け・再起動の回数・項の順番と、つなぎを直した手順は、静的な確認だけ
- 次の「最新の検証範囲」は、まとめる前の 12 項（2026-10-08 の時点）の範囲

## 最新の検証範囲（2026-10-08 UTC）

**Windows の実機では全手順を通していない。新規の Windows 11 Pro 26H2 の VM での検証結果。**

- 2026-10-08 の追加検証（[付録](#付録-pr-104-の未検証項目を同じ-vm-で確かめた記録2026-10-08)）
  - GitHub のコピーボタンからの貼り付け（管理者の conhost・Windows Terminal）、画面（「PC 全体の設定」の手順 1、「WSL と再起動」の手順 2、「再起動の後に確かめる」の手順 1〜4、「WSL の AlmaLinux 10 と自動サインイン」の手順 1・2・5）、分岐（「PC 全体の設定」の手順 5、「サインイン・検索・キーボード」の手順 5・6）
  - 2 枚目の NIC（ホストオンリー）での ping と、RDP のログイン・`tscon`
  - Wake on LAN の節の手順 2〜4・8、リモートから再起動する節の手順 2〜11（AlmaLinux の VM からの SMB・WinRM の実トリガーと、見張りタスクによる再起動）
  - 更新の手順 1〜5、ロールバックの全部（5 項）
  - 直した本文: 「Microsoft Store の更新」の手順 1、「再起動の後に確かめる」の手順 3・4、「WSL の AlmaLinux 10 と自動サインイン」の手順 1、Wake on LAN の節の手順 4、再起動の節の手順 5・6・9・11、ロールバックの「表示と入力を戻す」の手順 9、「アプリと貼り付けの設定を外す」の手順 4、「サインイン・検索・キーボードを戻す」の手順 4（管理者ではない窓で行う）、「ネットワークと PC 全体の設定を戻す」の手順 3・7・8 とリード
  - 撤去の前にスナップショット `pr104-before-rollback-20261008` を撮った
- 2026-10-08 の追加検証その 2（[付録](#付録-別の-windows-からの再起動とwinrm-の手順-5-の貼り直しを確かめた記録2026-10-08)）
  - 別の Windows（ホストの実機）から、再起動の節の手順 4 の `net use` と `shutdown /m`、手順 5 の `TrustedHosts` と `Invoke-Command` で、VM を実際に再起動した
  - 再起動の節の手順 5 を、以前の版の同じ節の手順 9 の後に貼り直すと止まることを確かめ、手順 5・9 を直した
  - 直した本文: 再起動の節の手順 4・5・9
  - 相手の VM のリンク クローンは、正しい資格情報でも NTLM が拒否され（4625 の状態 `0xc000006d`・副状態 `0x0`）、送る側に使えなかった。sysprep をしていないのでマシンの SID の重複が原因とみたが、確かめていない
- 2026-10-08 の時点で確認していないこと
  - Store の CLI の準備と更新の適用（「Microsoft Store の更新」の手順 3・4・6）、Windows Update の再起動の分岐（「Windows Update」の手順 8）。2026-10-08 には対象の更新が無かった（「Windows Update」の手順 5 の適用は 2026-10-06 に確かめた）
  - WSL 2 の AlmaLinux 10（「WSL の AlmaLinux 10 と自動サインイン」の手順 3・4、更新の手順 4 の `dnf -y upgrade`、ロールバックの「アプリと貼り付けの設定を外す」の手順 8）。この VM の仮想化の制約で動かない
  - Wake on LAN の UEFI の設定とマジック パケットでの起動
  - 別の Windows の `Get-Credential` の窓での資格情報の入力（`PSCredential` で渡した）、`-ComputerName`・`TrustedHosts` を IP にしたとき、この PC と同じ名前・同じパスワードのローカル アカウントから `net use` 無しで `shutdown /m` を送ったとき、Microsoft アカウントの PC を再起動される側にしたとき
  - Windows の実機での通し実行
- 以下は 2026-10-06〜07 の検証の要約（[付録](#付録-windows-11-pro-の-vm-での導入検証2026-10-06)）。そのときの「未検証」は、2026-10-08 の付録で多くを確かめた
- 初期設定は Windows Update の 4 件の適用と残り 0 件、Store の更新なし、Scoop・UniGet UI・PowerToys・PowerShell 7 の導入、指定値の読み戻しと一部の実画面を確認した。「再起動の後に確かめる」の手順 1〜4、「WSL の AlmaLinux 10 と自動サインイン」の手順 1 と通常権限の Windows PowerShell 5.1 への LF 3 行の貼り付け順は、利用者の手動確認を含む。343 文字のパスとシンボリックリンクの作成・読み取り・削除も、通常権限の PowerShell 7.6.6 で確認した。
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
> - **「PC 全体の設定」の手順 6 のインラインの sudo、同じ項の手順 7 の放置でロックしない設定、「ネットワークとリモート」の手順 2 のリモート デスクトップ、「サインイン・検索・キーボード」の手順 1 の Windows Hello 以外のサインイン、「WSL の AlmaLinux 10 と自動サインイン」の手順 5 の自動サインインを重ねると、PC に触れる人と、このユーザーのパスワードを知る人は、このユーザー（管理者）として操作できる**。人が触れる場所にある PC では、「PC 全体の設定」の手順 7 と「WSL の AlmaLinux 10 と自動サインイン」の手順 5 は行わない

### 実施手順 / Windows Update / 手順 3: 補足: 導入元と残るもの

- PSWindowsUpdate は Microsoft 標準のコマンドではなく、PowerShell Gallery に公開されている外部モジュール。2026-10-04 にヘルプを調べた版は 2.2.1.5
- `CurrentUser` は、このユーザーのドキュメントの `WindowsPowerShell\Modules` に置く。NuGet のプロバイダーも、無ければ自分のユーザーに入れる
- `-Force` は今回の導入の確認を省く。PSGallery 全体を `Trusted` にする設定は書かない
- `Import-Module -Global` は、この PowerShell の次の手順でもコマンドを使えるようにする指定。PC 全体へのインストールではない

### 実施手順 / Microsoft Store の更新 / 手順 2: 補足: ストアのアプリと CLI

- 同梱の Store CLI は `store.exe`。2026-10-04 にヘルプを確かめた Store 22608.1401.5.0 では、CLI 自体が `Preview` 表記だった
- 「Microsoft Store の更新」の手順 5〜7 は Store の全アプリを対象にする。winget が認識できるアプリだけの更新ではない
- 「アプリ インストーラー」（`winget`）と、「表示と入力」の手順 6 で既定の端末にする Windows Terminal も、先に更新しておく
- Windows Insider への参加や、Store の配布チャネルの変更は行わない

### 実施手順 / Microsoft Store の更新 / 手順 7: 補足: 確認できている範囲

- `updates` と `--apply` の存在は同梱のヘルプで確認した。古い Store からの準備、更新の適用、進行中・失敗・更新なしの場合の実際の表示は未検証
- `Get-AppxPackage` の版と `Status` は、インストールされているパッケージの状態。これだけでは、新しい版が無いことや、全アプリの更新完了は分からない
- CLI の再検索の結果と併せて判定する。終了コードが 0 だったことだけを根拠に、完了の行は出さない

### 実施手順 / 貼り付けの設定 / 手順 1: 補足: 行が逆順になる理由

- GitHub のコピーボタンは、ブロックの改行を LF だけにしてクリップボードに入れる（末尾の改行も無い）。マウスで選んで Ctrl+C でコピーしたものは、改行が CR LF になる
- conhost の窓（Windows Terminal ではない窓。検証した PC では、スタートメニューから管理者として開いた Windows PowerShell）に右クリックで貼ると、LF は Ctrl+Enter のキーとして届く
- Windows PowerShell 5.1 の PSReadLine 2.0.0 では、Ctrl+Enter は `InsertLineAbove`（今の行の上に空の行を作り、そこへ移る）。貼った行が 1 行ずつ上に入るので、ブロックが逆順になる
- `AddLine` は Shift+Enter と同じ働きで、実行せずに次の行へ進む。LF が来るたびに次の行へ進むので元の順に入り、最後に Enter を押すとブロック全体が 1 回で動く
- 管理者でない窓（検証した PC では Windows Terminal の中に開く）と、conhost の窓に Ctrl+V で貼ったときは、設定が無くても逆順にならなかった（利用者が確かめた）
- 実測は[付録](#付録-原因の確認と貼り付けの試験2026-10-03)

### 実施手順 / 貼り付けの設定 / 手順 3: 補足: 実行ポリシーと scoop・プロファイル

- `scoop` のコマンドは PowerShell のスクリプト（`~\scoop\shims\scoop.ps1`）なので、`RemoteSigned`・`Unrestricted`・`Bypass` のどれかでないと動かない。scoop のインストーラも、これを確かめて止まる（[付録](#付録-配布物と資料の調査2026-10-03)）
- 「貼り付けの設定」の手順 4 のプロファイルも、同じ理由で、このポリシーでないと読まれない
- `RemoteSigned` は、この PC で書いたスクリプトはそのまま動かし、インターネットから取ったファイル（Mark of the Web の付いたもの）には署名を求める
- `-Scope CurrentUser` は自分のユーザーだけの設定で、管理者の権限は要らない。`-Force` は確認の問い（`[Y] はい` など）を出さないため
- PowerShell 7 は、実行ポリシーを Windows PowerShell 5.1 とは別に持つ。PowerShell 7 で scoop を使うときは、そちらの `Get-ExecutionPolicy` も見る

### 実施手順 / 貼り付けの設定 / 手順 4: 補足: プロファイルの書き方

- プロファイルが無ければ、`New-Item -Force` がフォルダ（`WindowsPowerShell`）ごと作る
- 行の末尾の `# windows-setup.md` は、[ロールバック](../extra/windows-setup.md#ロールバック)で消す行を見分けるための印。2026-10-03 の前の版（貼り付けの設定が別の手順書 `windows-powershell-paste.md` だったとき）は、印が `# windows-powershell-paste.md` だった。どちらの印の行も、この手順は「すでにある」とみなし、ロールバックは消す
- 足す行は ASCII の文字だけなので、既存のプロファイルの文字コードによらず足せる。Windows PowerShell 5.1 の `Add-Content` は、既存のファイルの BOM（UTF-16 LE・UTF-8）を見て、同じ文字コードで足した
- `Add-Content` は、ファイルの末尾が改行でなくても改行を足さずに書き足す（最後の行につながった）。そのときは、行の前に改行を付けて足す
- 対話でない起動（標準入力をリダイレクトした `powershell -Command`）でも、この行はエラーを出さなかった
- 実測は[付録](#付録-原因の確認と貼り付けの試験2026-10-03)（印を変える前のブロックで試した）

### 実施手順 / アプリを入れる / 手順 3: 補足: 入れ方と入る場所

- `Devolutions.UniGetUI` は、UniGet UI の公式の README が最初に挙げる入れ方（UniGet UI は Devolutions 社に移った。もとの `MartiCliment.UniGetUI` ではない）
- winget の定義では、`--scope user` のときに Inno Setup のインストーラへ `/CURRENTUSER /NoWinGet /NoAutoStart` を渡す（自分のユーザーに入れる、winget を入れ直さない、入れた後に起動しない）。インストーラは `cdn.devolutions.net` から取り、sha256 を winget が確かめる（[付録](#付録-配布物と資料の調査2026-10-03)）
- 入る場所は `%LOCALAPPDATA%\Programs\UniGetUI`、設定は `%LOCALAPPDATA%\UniGetUI`（ソースのインストーラの定義と `CoreData.cs` から。確かめていない）
- スタートメニューとデスクトップにショートカットを作る。winget の定義はデスクトップのショートカットを止めるスイッチ（`/NoDesktopShortcut`）を渡さない
- `--accept-source-agreements` と `--accept-package-agreements` は、winget を初めて使う PC で出る同意の問いに答えるため（続けて貼った行が答えとして食われないように）
- scoop-search は、UniGet UI が scoop のパッケージを検索するのに使う道具（ソースの `Scoop.cs` が「検索に要る」とする依存）。無いと、UniGet UI が起動したときに入れるかを聞く。ここで先に入れておく
- scoop の `extras/unigetui` を採らなかった理由は、[選択した方針](../verification/windows-setup.md#選択した方針)

### 実施手順 / 表示と入力 / 手順 1: 補足: 値の意味

- `Explorer\Advanced` の値（フォルダー オプションの「表示」タブと、設定の「個人用設定」→「スタート」に当たる）
  - `HideFileExt` が 0: 「登録されている拡張子は表示しない」を外す（既定は 1）
  - `Hidden` が 1: 隠しファイルを表示する（隠すときの値は 2）
  - `LaunchTo` が 1: エクスプローラーを「PC」で開く（2 か値が無いと「ホーム」）
  - `Start_TrackDocs` が 0: 設定の「スタート、エクスプローラーのおすすめのファイル、最近使ったファイル、ジャンプ リストの項目を表示する」を切る（既定は 1）。Microsoft の文書（Windows のコンポーネントから Microsoft のサービスへの接続を管理する）に、この値を 0 にすると書いてある。ジャンプ リストも空になる
- `Explorer` の値（フォルダー オプションの「全般」タブの「プライバシー」に当たる）: `ShowRecent` が 0 で「最近使用したファイルを表示する」、`ShowFrequent` が 0 で「よく使うフォルダーを表示する」を切る
- `HideFileExt`・`Hidden`・`Start_TrackDocs` は、Microsoft が出している DSC のリソース（`microsoft/winget-dsc` の `Microsoft.Windows.Developer`）が同じ値を書く。`LaunchTo`・`ShowRecent`・`ShowFrequent` は Microsoft の文書には無く、広く使われている値（[付録](#付録-windows-11-の設定の調査2026-10-03)）
- 同じことは、設定の「システム」→「開発者向け」→「エクスプローラー」と、フォルダー オプションの画面からもできる

### 実施手順 / 表示と入力 / 手順 3: 補足: 値と設定の画面の対応

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

### 実施手順 / 自動起動と標準アプリ / 手順 2: 補足: 外すアプリと、戻ってくること

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
- 戻すときは、[ロールバックの「表示と入力を戻す」](../extra/windows-setup.md#表示と入力を戻す)の手順 9 で、ストアの ID を指定して winget で入れる

### 実施手順 / ネットワークとリモート / 手順 1: 補足: プライベートにする理由

- Windows のファイアウォールの受信の規則は、ネットワークの種類（プライベート・パブリック）ごとに有効にできる。OpenSSH サーバーの機能が作る規則も、Syncthing の Windows 11 の節で作る規則も、「ネットワークとリモート」の手順 2〜4 の規則も、プライベートだけで有効にする
- Windows 11 は、新しくつないだネットワークをパブリックにすることがある。[Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)を検証した PC の有線 LAN はパブリックで、そのままでは LAN からの SSH が捨てられ、プライベートにすると通った（同書の手順 5 の補足）
- 同じ PC では、パブリックからプライベートにすると、それまで効いていなかった許可の規則 45 本がこの LAN で効くようになった。主なものは、ネットワーク探索（10 本）、リモート アシスタンス（4 本。「ネットワークとリモート」の手順 3 で切る）、デバイス キャスト機能（3 本）。ファイルとプリンターの共有は無効のままだった
- この操作は、もとは Windows の OpenSSH サーバーの手順 5 と Syncthing の Windows 11 の手順 7 の両方にあった。2026-10-03 に、インストール直後の作業としてここへまとめた。ブロックは OpenSSH サーバーの手順 5（実機で通したもの）から、`Get-NetFirewallRule` の行を除いて移した（変数の手順の番号だけ変えた）
- ノート PC を持ち出したとき: プライベートにしたのはこの接続（有線 LAN か、この Wi-Fi のネットワーク）だけ。出先の Wi-Fi は、つないだときにパブリックかプライベートかを選ぶ（既定はパブリック）

### 実施手順 / サインイン・検索・キーボード / 手順 5: 補足: Windows と Linux の時計の扱い

- Windows は、ハードウェアの時計（RTC）を地方時として読み書きする。Linux は UTC として扱うのが普通で、両方が違う扱いのままデュアル ブートすると、起動し直すたびに 9 時間ずれる。2 つの OS のどちらかにそろえればよい
- AlmaLinux 10 のインストーラ（anaconda）は、NTFS のパーティションを見つけると、AlmaLinux の側を地方時にする（`/etc/adjtime` に `LOCAL`。[windows-dual-boot.md の注意点](../extra/windows-dual-boot.md#注意点)。インストーラのソースから読んだこと）。その流れで入れたなら、もうそろっているので、この手順は要らない（行うと、かえって 9 時間ずれる）
- AlmaLinux の側を UTC にした（`timedatectl set-local-rtc 0`）ときだけ、Windows も UTC にそろえる。`HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation` の `RealTimeIsUniversal` を 1 にすると、Windows も UTC として扱う。Microsoft の文書には無い値で、Arch Linux の wiki が勧める形（DWORD。64 ビットの Windows では QWORD という古い勧めは、wiki から消えた）
- Arch Linux の wiki は、両方を UTC にする形を勧めている（Linux の側を地方時にする `timedatectl set-local-rtc 1` は勧めていない）。本書は、AlmaLinux のインストーラの既定（地方時）に合わせ、2026-10-03 に [windows-dual-boot.md](../windows-dual-boot.md) とそろえた
- 元に戻すのは[ロールバックの「サインイン・検索・キーボードを戻す」](../extra/windows-setup.md#サインイン検索キーボードを戻す)の手順 10

### 実施手順 / WSL の AlmaLinux 10 と自動サインイン / 手順 3: 補足: AlmaLinux 10 の WSL のイメージ

- `AlmaLinux-10` は、WSL のディストリビューションの一覧（`wsl --list --online`）の AlmaLinux 10 の名前。イメージは AlmaLinux の `wsl-images`（GitHub）にあり、`wsl.exe` が sha256 を確かめて入れる（WSL の `DistributionInfo.json`。2026-10-03 は 10.2）
- 最初の起動で、AlmaLinux のイメージの `oobe` がユーザーを作る。作ったユーザーは uid 1000 で、`wheel` に入る（`sudo` を使える）。systemd が動く（`wsl.conf` の `systemd=true`）
- Linux のユーザー名とパスワードは、Windows のものとは別。パスワードは `sudo` で聞かれる
- [Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)の検証では、この AlmaLinux 10 からこの PC に SSH でつないで確かめた

### 実施手順 / WSL の AlmaLinux 10 と自動サインイン / 手順 5: 補足: Autologon のすること

- Autologon は Microsoft の Sysinternals の道具で、Windows の自動ログオンの設定（`HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon` の `AutoAdminLogon` など）を書き、パスワードは LSA のシークレットとして、暗号にして置く（Microsoft の文書。管理者は取り出せる）
- winget の定義（`Microsoft.Sysinternals.Autologon` 3.10）は zip の持ち運び版で、`%LOCALAPPDATA%\Microsoft\WinGet\Packages` の下に展開する。定義の取り先は版の付かない URL で、2026-10-03 は sha256 が一致した。Microsoft が zip を差し替えると、定義が直るまで winget が失敗する
- コマンド ラインでパスワードを渡す形（`autologon <ユーザー> <ドメイン> <パスワード>`）は、パスワードがプロセスのコマンド ラインに見え、履歴にも残りうるので使わず、窓で入れる
- `-accepteula` は、使用許諾の窓を出さないため
- Microsoft アカウントでは、`Username` をメールアドレスにし、`Domain` を `MicrosoftAccount` か PC の名前にする、という報告があるが、確かめていない。パスワード（PIN ではない）が要り、「サインイン・検索・キーボード」の手順 1 でパスワードのサインインを使えるようにしておく
- [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)は、デスクトップにサインインしていることを前提にする。再起動の後もサインインした状態にするため
- 止めるのは[ロールバックの「サインイン・検索・キーボードを戻す」](../extra/windows-setup.md#サインイン検索キーボードを戻す)の手順 3

### リモートから再起動する手段を増やす（任意）: 検証状況の記録

- **Windows の実機では通していない（未検証。2026-10-06 に書いた）**。ほかの節と同じく、資料と、Linux の PowerShell 7.6.6・PSScriptAnalyzer 1.25.0 での構文・互換・模擬までで確かめた（[付録](#付録-リモート再起動の節の資料とブロックの確認2026-10-06)）
- **確かめたこと**:
  - 資料: MS-RSP の transport（InitShutdown・WinReg は名前付きパイプ、WindowsShutdown は TCP）、「リモート システムからの強制シャットダウン」（`SeRemoteShutdownPrivilege`）の既定、`LocalAccountTokenFilterPolicy`（既定で管理者に限定、1 で緩む）、`CrashControl\AutoReboot`（既定 1）、Samba の `net rpc shutdown` と Windows の `shutdown /m`、`Enable-PSRemoting`/`Disable-PSRemoting`
  - 新しいブロック 10 個の構文（誤り 0）と 5.1 互換（`Set-ItemProperty -Type` の指摘だけ。動的なパラメーターで当たらない）
  - 見張りスクリプトの判定（稼働 60 分の歯止め・連続失敗のしきい値・届いたら 0 に戻すこと）と、手順 6・7 の中断（管理者でない・変数が空・タスクが無い）を、偽物のコマンドレットで模擬
- **確かめていないこと**: Windows で貼ること、別の PC から `net rpc shutdown`・`shutdown /m`・WinRM で実際に再起動できること、見張りタスクがネットワーク断で再起動し・ループしないこと、再起動の後に SSH・RDP が自動で戻ること、Microsoft アカウントでの SMB・WinRM の認証、`FPS-SMB-In-TCP`・`WINRM-HTTP-In-TCP*` の規則名が版・機種で一致すること

### プライバシーと広告の表示を切る（任意）: 検証状況の記録

- **Windows の実機では通していない（未実施。2026-10-08 に書いた）**。どのブロックも、Windows では貼っていない
- **確かめたこと**:
  - 資料: Microsoft の文書（Manage connections の 18.1・18.6・18.16、Policy CSP の Privacy・Experience・System・Search、サポートの記事の画面の項目）と、広く使われている情報（privacy.sexy・Ten Forums・ElevenForum など）。値ごとの出典は[参考資料](../reference/windows-setup.md)
  - この節のブロック 4 個の構文（誤り 0）と 5.1 互換（`Set-ItemProperty` の `-Type` の指摘だけ。動的なパラメーターで当たらない）。この節の手順 2 の `->` の左と控え（キーや値が無いとき・QWORD のとき・2 回目）と、この節の手順 5 で値と種類が流す前に戻ること・控えが無いときの中断を、偽物のコマンドレットで模擬（[付録](#付録-プライバシー表示入力音ストレージedgecopyq-の任意節のブロックの確認2026-10-08)）
- **確かめていないこと**:
  - Windows で貼ること、控えのファイルの書き出しと読み戻しを Windows PowerShell 5.1 で流すこと
  - `HKCU` に書いた値が画面の切り替えに出ることと、サインインし直した後に効くこと（`AdvertisingInfo\Enabled`・`TailoredExperiences…`・`TIPC\Enabled`・`SearchSettings` の 3 つ・`ShowSyncProviderNotifications` は広くだけ）
  - `IsDeviceSearchHistoryEnabled` の 0 がオフであること（資料どうしで食い違う）
  - 「サインイン・検索・キーボード」の手順 2 の `DisableSearchBoxSuggestions` で「検索のハイライトを表示する」が灰色になること（Microsoft Q&A の回答だけ）
  - 「フィードバックの頻度」を「1 日 1 回」などにしていた PC で、`PeriodInNanoSeconds` が QWORD であることと、この節の手順 5 がその型で戻すこと
  - 画面の切り替えで戻したときに、書いた `HKCU` の値も直ること
  - 日本語の画面の文言（「おすすめとオファー」と「推奨事項 & オファー」の表記の割れ、「パーソナライズされたオファー」の置き場所、「設定アプリで通知を表示する」・同期プロバイダーの通知の項目の名前）
  - Rufus の「データ収集を無効化」で入れた PC で、広告 ID・カスタマイズされたエクスペリエンス・診断データ・オンライン音声認識が既に切れているか
  - 24H2・25H2・26H2 の違い（26H2 で値を確かめた資料は無い）

### 表示・入力・音・ストレージを変える（任意）: 検証状況の記録

- **Windows の実機では通していない（未実施。2026-10-08 に書いた）**。どのブロックも、Windows では貼っていない
- **確かめたこと**:
  - 資料: Microsoft の文書（`STICKYKEYS`・`FILTERKEYS`・`TOGGLEKEYS`・`SystemParametersInfo`・`ANIMATIONINFO`・Integrate a Cloud Storage Provider・WOW64 のリダイレクト・KB5031455・Policy CSP の Storage・ストレージ センサーのサポートの記事）、コード（`microsoft/winget-dsc`・`microsoft/WindowsDeveloperConfig`・ReactOS・Wine・Chromium）、広く使われている情報（winutil・Disassembler0・stealthpuppy・cyberdrain など）。値ごとの出典は[参考資料](../reference/windows-setup.md)
  - この節のブロック 21 個の構文（誤り 0）と 5.1 互換（`Set-ItemProperty` の `-Type` の指摘だけ）。「表示・入力・音・ストレージを控えて変える」の手順 3 と「表示・入力・音・ストレージを元に戻す」の手順 1 の `Flags` のビット、「表示・入力・音・ストレージを控えて変える」の手順 9 と「表示・入力・音・ストレージを元に戻す」の手順 7 の控えの有無と書き戻し、「表示・入力・音・ストレージを控えて変える」の手順 11 と「表示・入力・音・ストレージを元に戻す」の手順 9 のストレージ センサー、「表示・入力・音・ストレージを控えて変える」の手順 2・4 と「表示・入力・音・ストレージを元に戻す」の手順 2 の切り替えのキー、「表示・入力・音・ストレージを控えて変える」の手順 6 と「表示・入力・音・ストレージを元に戻す」の手順 4 のギャラリーとホームを、偽物のコマンドレットと `reg.exe` で模擬。「表示・入力・音・ストレージを控えて変える」の手順 8 と「表示・入力・音・ストレージを元に戻す」の手順 6 の `Add-Type` の宣言のコンパイルと、多重定義の選ばれ方（[付録](#付録-プライバシー表示入力音ストレージedgecopyq-の任意節のブロックの確認2026-10-08)）
- **確かめていないこと**:
  - Windows で貼ること、控えのファイル（`display-before.csv`・`appevents.reg`）の書き出しと読み戻しを Windows で流すこと
  - 固定キーなどの Windows 11 の既定（510・126・62）、サインアウトのときに書き戻されないこと、サインインし直す前に設定の画面で上書きされること
  - 入力言語の切り替えのキーの日本語版の既定と、サインインし直した後に効くこと
  - `MultiTaskingAltTabFilter` の値の意味と既定（広くだけ）
  - ギャラリーとホームを消す値が 24H2・25H2・26H2 で効くこと（効かなくなった・戻ったという報告が 1 件ずつある）
  - `SystemParametersInfo` で切った後に、設定の「アニメーション効果」がオフと出ること。`Add-Type` の宣言の呼び分けが Windows で働くこと
  - 効果音の `.reg` の書き戻しで元に戻ること、起動音のチェックで UAC が出るか
  - ストレージ センサー: `StoragePolicy` の値で掃除が動くか（掃除は `StorageSensorV2` を読むという主張がある）、`04` の向き、Windows 11 が `08` と `32` を読むか、OneDrive の既定、書いた値が画面に出ること。25H2 の 26200.8328 で多くのアプリが消えたという掲示板の報告（1 件。Microsoft の返答は無い）
  - 日本語の画面の文言（固定キーなどの「…用のキーボード ショートカット」、ストレージ センサーの項目と選択肢、「タスクの終了」の置き場所）

### Edge の常駐をポリシーで止める（任意）: 検証状況の記録

- **Windows の実機では通していない（未実施。2026-10-08 に書いた）**。どのブロックも、Windows では貼っていない
- **確かめたこと**:
  - 資料: Microsoft Edge のポリシーの文書（`StartupBoostEnabled`・`BackgroundModeEnabled`・Configure Microsoft Edge）、スタートアップ ブーストのサポートの記事、Chromium の `auto_launch_util.cc`
  - この節のブロック 2 個の構文（誤り 0）と 5.1 互換（`Set-ItemProperty` の `-Type` の指摘だけ）。模擬はしていない（[付録](#付録-プライバシー表示入力音ストレージedgecopyq-の任意節のブロックの確認2026-10-08)）
- **確かめていないこと**:
  - Windows で貼ること、家庭の PC（ドメイン・MDM なし）で 2 つのポリシーが効くこと
  - 「組織によって管理」の表示の日本語の文言と、ポリシーを消した後に表示が消えるか
  - 「自動起動と標準アプリ」の手順 1 の `Run` の `MicrosoftEdgeAutoLaunch_*` が消えるか、Edge Update のサインインのときのコマンドで Edge が起動するか
  - 画面で切った値を、Edge が自分でオンに戻すか

### CopyQ を使う（任意）: 検証状況の記録

- **Windows の実機では通していない（未実施。2026-10-08 に書いた）**。どのブロックも、Windows では貼っていない
- **確かめたこと**:
  - 資料: winget の `hluk.CopyQ` 16.0.0 の定義、CopyQ 16.0.0・17.0.0 のソース（`shared/copyq.iss`・`winplatform.cpp`・`CHANGES.md`・訳のファイル）と文書、Inno Setup と winget の文書、`RegisterHotKey`・`SendInput`・PowerToys の高度な貼り付けの文書
  - この節のブロック 6 個の構文（誤り 0）と 5.1 互換（指摘 0）。`winget`・`copyq.exe` を呼ぶので、模擬はしていない（[付録](#付録-プライバシー表示入力音ストレージedgecopyq-の任意節のブロックの確認2026-10-08)）
- **確かめていないこと**:
  - Windows で貼ること、winget の版（16.0.0。上流は 17.0.0）で UAC が出ないこと、入る場所（前に入れた CopyQ の場所に入ると、決め打ちのパスが外れる）
  - `config autostart true` の出力と、`| Write-Output`・`| Out-Null` で終わるまで待つこと、サインインのときに起動すること
  - `EnableClipboardHistory` の値の名前（広く）
  - 更新でインストーラが閉じた CopyQ が、起動し直さないこと
  - 日本語の画面の文言（「設定...」・「ショートカット」・「メインウィンドウの表示切り替え」など。訳のファイルから書いた）と、割り当てたグローバル ショートカットが効くこと
  - RDP の画面とスクリーンショットに CopyQ の窓が写らないこと

### PowerToys のユーティリティを絞る（任意）: 検証状況の記録

- **Windows の実機では通していない（未実施。2026-10-08 に書いた）**。どのブロックも、Windows では貼っていない
- **確かめたこと**:
  - 資料: PowerToys の main のソース（`src/runner/main.cpp`・`general_settings.cpp`・`auto_start_helper.cpp`・`settings_helpers.cpp`・`EnabledModules.cs`・`PeekProperties.cs`・`FindMyMouseProperties.cs`・Peek の `dllmain.cpp`・インストーラの `Common.wxi`・`Product.wxs`）と、Microsoft Learn の Install・DSC・PSDSC・Running as administrator・Peek・Mouse utilities・Command Not Found のページ。値ごとの出典は[参考資料](../reference/windows-setup.md)
  - この節のブロック 4 個の構文（誤り 0）と 5.1 互換（指摘 0）。この節の手順 2 の `$PT_EXE` の選び方、手順 3 の `無い名前:`、手順 5 の中断（動いている・`$PT_EXE` が空・無い名前・`enabled` が無い・読めない）と書き換え（変わったのは `enabled` の 6 つだけで、7 段の入れ子と配列は型まで保った。2 回目は控えを書き換えない）、手順 8 の書き戻し（流す前とバイトで一致し、控えが消えた）を、Linux の PowerShell 7.5.3 と偽物のコマンドレットで模擬（[付録](#付録-powertoyspowershell-7windows-terminalwsl-の任意節のブロックの確認2026-10-08)）
- **確かめていないこと**:
  - Windows で貼ること。0.101.2362.0 の入る場所（`%LOCALAPPDATA%\PowerToys` か `%LOCALAPPDATA%\Programs\PowerToys`）と、動いているプロセスから場所を取れること
  - `settings.json` を直接書いて、起動し直した PowerToys に効くこと。終了のときに PowerToys が設定ファイルを書き直さないこと
  - 0.101.2362.0 の設定ファイルの `enabled` の名前と既定（main のソースから書いた）
  - `Get-ScheduledTask` で `\PowerToys\Autorun for <WIN_USER>` が読めること
  - 日本語の画面の文言（通知領域の「終了」・「設定」・「ダッシュボード」・Peek の「Space で開く」・Find My Mouse の「マウスを振る」・Command Not Found の「インストール」）
  - 通知領域のアイコンを 1 回クリックするとクイック アクセスが開き、右クリックの「設定」かダブルクリックで設定の窓が開くこと（main のソースから書いた）
  - 0.95 より前の設定を引き継いだ PC での Peek の起動のキー

### PowerShell 7 のプロファイルを設定する（任意）: 検証状況の記録

- **Windows の実機では通していない（未実施。2026-10-08 に書いた）**。どのブロックも、Windows では貼っていない
- **確かめたこと**:
  - 資料: PowerShell 7.5.4・7.6.0・7.6.6 のソース（`CorePsPlatform.cs`・`ConsoleHost.cs`・`build.psm1`・`PSGalleryModules.csproj`）、PSReadLine 2.3.6・2.4.5 のソース（`KeyBindings.cs`・`History.cs`・`Cmdlets.cs`）、zoxide 0.9.9・0.10.0 の `templates/powershell.txt`、starship 1.26.0 の `starship.ps1`、自分用の WezTerm の設定（`lua/shells.lua`・`shell/wezterm.ps1`）、Microsoft Learn の about_Profiles・about_Execution_Policies・about_PowerShell_Config・about_PSReadLine・Using predictors。値ごとの出典は[参考資料](../reference/windows-setup.md)
  - 貼り付けの設定の原因（PSReadLine の Ctrl+Enter が `InsertLineAbove`）は、PowerShell 7.6.6（PSReadLine 2.4.5）でも同じだった（もとの手順書 `windows-powershell-paste.md` の注意点の記録。この記録の「操作上の注意と併記されていた記録」）
  - この節のブロック 6 個の構文（誤り 0）と 5.1 互換（指摘 0）。この節の手順 2・3 の足し方（無いときに作る・2 回目は `すでにある:` で変わらない・末尾に改行の無いファイル・BOM 付きのファイル・5 行のうち 2 行があるファイル）と、手順 7 の消し方（BOM 付きの UTF-8・UTF-16LE・CRLF・LF。印の行だけならファイルを消し、印の形の違う行と PowerToys の Command Not Found の行は残る）を、Linux の PowerShell 7.5.3 で模擬（[付録](#付録-powertoyspowershell-7windows-terminalwsl-の任意節のブロックの確認2026-10-08)）
  - 足したプロファイルを、Linux の PowerShell 7.5.3（PSReadLine 2.3.6）と Linux 版の starship 1.26.0・zoxide 0.10.0 で読んだ。この節の手順 4 のキーの表が `AddLine`・`HistorySearchBackward`・`HistorySearchForward`・`MenuComplete` になり、新しいディレクトリで `prompt` を呼ぶと zoxide に記録された（`Invoke-Starship-PreCommand` を除いた形では記録されない）。2 つが無いと、どちらも読まなかった。実行ポリシーの手順 5・8 は、Linux では流せない（同じ付録）
- **確かめていないこと**:
  - Windows で貼ること。5.1 の `Add-Content` と `Get-Content -Raw` が、PowerShell 7 のプロファイルに行を足すこと（「貼り付けの設定」の手順 4 と同じ形）
  - 5.1 から `pwsh.exe -NoLogo -NoProfile -Command { … }` を呼ぶ形（minishell）で、結果が表で出ること。非対話の起動で `Set-PSReadLineKeyHandler` が通ること
  - MSIX の PowerShell 7 の `$PSHOME` に `powershell.config.json`（`RemoteSigned`）があること
  - スタートメニューから管理者として開いた PowerShell 7（conhost の窓）に右クリックで貼ると、この節の行が無ければ逆順になり、あれば正しい順になること。WezTerm（ConPTY）の PowerShell 7 に複数行を貼ったときに Ctrl+Enter の行が要るか
  - zoxide → starship の順（`Invoke-Starship-PreCommand` で zoxide の記録を呼ぶ）で、`z` が移動先を記録し、失敗したコマンドの後に starship のエラーの印が出ること。README の starship → zoxide の順で `$?` が崩れるか
  - Tab の `MenuComplete` を既定で入れるか（条件付きの手順のままにした）
  - OneDrive でドキュメントをバックアップしている PC のプロファイルの場所
  - スタートメニューの PowerShell 7 の表示名（MSIX の表示名は「PowerShell」のはず。PowerShell のソースの `packaging.psm1` から書いた。「アプリを入れる」の手順 5 の「PowerShell 7」とは違う）

### Windows Terminal のフォントと貼り付けの警告を変える（任意）: 検証状況の記録

- **Windows の実機では通していない（未実施。2026-10-08 に書いた）**。どのブロックも、Windows では貼っていない
- **確かめたこと**:
  - 資料: microsoft/terminal の main と release-1.21〜1.24 のソース（`MTSMSettings.h`・`CascadiaSettingsSerialization.cpp`・`CascadiaSettings.cpp`・`userDefaults.json`・`TerminalPage.cpp`・`VtIo.cpp`・`utils.cpp`・日本語の訳の `Resources.resw`）と、Microsoft Learn の Windows Terminal のページ。値ごとの出典は[参考資料](../reference/windows-setup.md)
  - 貼り付けの設定の原因を確かめた PC の、管理者ではない窓は Windows Terminal 1.25.2733.0 だった（[対象と検証環境](#対象と検証環境)）
  - この節のブロック 4 個の構文（誤り 0）と 5.1 互換（指摘 0）。この節の手順 2〜4 の中断（ファイルが無い・行とブロックのコメント・末尾のカンマ・配列の `profiles`・控えが無い・版が 1.24 より前）と、文字列の中の `//`・`/*` では止まらないこと、書き換え（変わったのは `profiles.defaults.font.face` と `warning.multiLinePaste` だけで、`font.size` などと、入れ子・空と 1 要素の配列・`null` は型まで保った）、手順 6 の書き戻し（流す前とバイトで一致し、控えが消えた）を、Linux の PowerShell 7.5.3 と偽物の `Get-AppxPackage` で模擬（[付録](#付録-powertoyspowershell-7windows-terminalwsl-の任意節のブロックの確認2026-10-08)）
- **確かめていないこと**:
  - Windows で貼ること。5.1 の `ConvertFrom-Json`・`ConvertTo-Json -Depth 100` で、実際の `settings.json` の配列（`profiles.list`・`actions`・空の配列）が形を保って書き戻されること
  - 管理者ではない 5.1 の窓（Windows Terminal 1.25）に複数行を貼るたびに「警告」が出ること（コードからの推測）。出るなら、ほかの手順書のリードにも書くか
  - 自分のユーザーに入れた HackGen Console NF が、MSIX の Windows Terminal から見えること（hackgen.md の検証記録でも未確認）
  - 日本語の画面の文言（`Resources.resw` の訳から書いた）と、「見つからないフォント:」の出方
  - 「Microsoft Store の更新」の手順 1 の窓で Windows Terminal が先に設定を作り、「アプリを入れる」の手順 5 の後も既定のプロファイルが Windows PowerShell のままであること
  - 管理者の窓（conhost）のフォントは、この節の範囲外

### WSL のネットワークをミラーにする（任意）: 検証状況の記録

- **Windows の実機では通していない（未実施。2026-10-08 に書いた）**。どのブロックも、Windows では貼っていない
- **確かめたこと**:
  - 資料: microsoft/WSL の master のソース（`WslCoreConfig.cpp`・`WslCoreConfig.h`・日本語の訳の `Resources.resw`）と、Microsoft Learn の wsl-config・networking・troubleshooting・Hyper-V Firewall・`New-NetFirewallHyperVRule` のページ。値ごとの出典は[参考資料](../reference/windows-setup.md)
  - 同じ PC の WSL の記録は 2.7.13.0（カーネル 6.18.33.2-microsoft-standard-WSL2）で、ネットワークは既定の NAT だった（[Windows の OpenSSH サーバーの検証記録](#統合前の記録-openssh-サーバーもとは-windows-openssh-servermd)と [VirtualBox のゲスト（bootc）の検証記録](virtualbox-guest-bootc.md)）
  - この節のブロック 6 個の構文（誤り 0）と 5.1 互換（指摘 0）。この節の手順 3 の作成・控え・`[wsl2]` の行の直後への挿入（CRLF・LF・大文字の `[WSL2]`・`[wsl2]` の無いファイル・BOM 付き）と、`networkingMode` の行があるときの中断、手順 6 の戻し（控えからはバイトで一致・作ったままなら消す・手で変えたら中断）を、Linux の PowerShell 7.5.3 で模擬。`wsl.exe` を呼ぶ手順 2・4・5・7 は、偽物の関数で流れを見ただけ（[付録](#付録-powertoyspowershell-7windows-terminalwsl-の任意節のブロックの確認2026-10-08)）
- **確かめていないこと**:
  - Windows で貼ること。既にある `.wslconfig`（設定の画面が書いたもの）に 1 行足して、WSL が読むこと
  - AlmaLinux 10 の WSL のイメージで `wslinfo --networking-mode` が使えること（無ければ `ip` で比べる）
  - ミラーを使えない PC で `wsl.exe` が出す文言（`ミラー化されたネットワーク モードはサポートされていません`。`Resources.resw` の訳から書いた）
  - ミラーで、WSL から `127.0.0.1:22` の Windows の sshd に届くことと、LAN の IP あてが届かないこと（文書の言い方からの推測。ミラーでも `127.0.0.1` に届かないというコミュニティの報告もある）
  - ミラーで、WSL からホストオンリーのネットワークの VirtualBox の VM に届くか（[virtualbox-guest-bootc.md](../virtualbox-guest-bootc.md) の記録は NAT のとき）
  - Docker・VPN との相性（[WireGuard Road Warrior の Windows 11 の節](../wireguard.md#windows-11-で使う)のトンネルを張った PC での WSL の通信を含む）
  - 対象の 24H2・25H2 と、利用者の 26H2（26300）の違い

### シェルのツールを入れる（任意）: 検証状況の記録

- **Windows の実機では通していない（未実施。2026-10-08 に書いた）**。どのブロックも、Windows では貼っていない
- **確かめたこと**（[付録](#付録-シェルのツールの任意節のブロックの確認2026-10-08)）:
  - 上流の zoxide（2026-10-08 05:11 UTC。06:22 UTC と 06:40 UTC にタグを見直しても同じ）: タグの最新は `v0.10.0`。Git Bash の記録を直すコミット `1f484a4`（#1260）は `main` にあり、どのタグにも入っていない。そのため、0.9.9 に止める形で書いた
  - scoop の main の 5 つの定義と、バケットの履歴の zoxide 0.9.9 の定義。6 つの zip（5 つと zoxide 0.10.0。x64）の sha256 が定義と一致した。PE のインポート表で `VCRUNTIME140.dll` を読み込むのは bat だけ。0.9.9 の `zoxide.exe` に `cygpath -w "$(\builtin pwd -P)"` がある
  - Scoop v0.6.0 のソース: 版の指定（バケットの履歴）・`hold`・`unhold`・`update --force`・`list`・`uninstall` の動きと表示
  - Scoop v0.6.0 の `install` の分かれを、偽の scoop のフォルダーで Linux の pwsh 7.5.3 で動かした: 版を指定した同じ版がもう入っていると、同じ行のほかの名前を入れずに終わる。版を指定しない名前を並べると、入っているものを何も出さずに飛ばす。main が git でなければ、履歴を探さない
  - Linux の bat 0.26.1 で、CRLF の 3 行の設定が効き、BOM を付けると 1 行目で失敗すること
  - この節のブロック 10 個の構文（誤り 0）と 5.1 互換（指摘 0）。偽物の `scoop` と本物の Linux の bat で、手順 2〜6・10〜13 の流れを Linux の PowerShell 7.5.3 で模擬した（手順 4・6・10 を直した後に、もう一度流した。最後に、手順書から取り出し直したブロックで、構文・互換・模擬を通し直した）
- **確かめていないこと**:
  - Windows で貼ること（すべての手順）。`scoop install zoxide@0.9.9` がバケットの履歴から定義を取り出すことと、`hold`・`list`・`unhold`・`update --force`・`uninstall` の実際の表示
  - Git for Windows より前に zip で置いた main のバケットを、この節の手順 4 の `scoop update` が git の形に直すこと
  - 5.1 の `Set-Content -Encoding ASCII` と `[IO.File]::WriteAllText` が、NTFS のハードリンクの控え（`persist`）にも同じ中身を書くこと
  - WezTerm の新しいタブが、起動し直さずに starship の `Path` と `BAT_CONFIG_DIR` を読むこと
  - Git Bash で、AlmaLinux 10 の初期設定の「シェルのツール」の手順 4〜7・9・10 と「キー操作を試す」の手順 2〜5 を通すこと（zoxide の Windows の形のパスでの記録、eza の見出しと `Git` の列、bat のプレビュー、Git for Windows に `/etc/os-release` があるか、fzf の ASCII 以外の文字）
  - 0.10.0 で記録されないことの再現と、直った版への上げ方（まだ出ていない）
  - Git Bash で、AlmaLinux 10 の初期設定の後ろの節（starship・fzf・eza・bat）を貼ること（リードで案内した、fd を scoop で入れる形を含む）
  - `VCRUNTIME140.dll` が無いときの `bat --version` の出方
  - SSH のセッション、arm64 の Windows、スタートメニューの Git Bash（mintty）

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
  - 任意節（2026-10-08）: プライバシーと広告の表示・表示と入力と音とストレージ センサー・Edge の常駐のポリシー・CopyQ
  - 任意節（2026-10-08 の 2 つ目）: PowerToys のユーティリティ・PowerShell 7 のプロファイル・Windows Terminal のフォントと貼り付けの警告・WSL のネットワークのミラー
  - 任意節（2026-10-08 の 3 つ目）: Git Bash のシェルのツール（starship・zoxide・fzf・eza・bat）
- **進め方**: 最初に管理者の Windows PowerShell 5.1 で Windows Update を行い、必要なら手動で再起動する。その後、通常の窓で Store と自分のユーザーの設定を、管理者の窓で PC 全体の設定を行う
  - 設定の後に 1 回再起動し、WSL のディストリビューションと自動サインインを入れる
- **状態**: **Windows の実機では通していない**（2026-10-03 に作成、2026-10-04 に更新を CLI 化）
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも、この文書の形のまま Windows で貼ってはいない
  - **確かめたこと**:
    - CLI による更新（「Windows Update」と「Microsoft Store の更新」の全部）: PSWindowsUpdate 2.2.1.5 の配布物のヘルプ、Windows Update Agent の検索条件、WinGet の文書と Store の製品 ID。この PC の Store 22608.1401.5.0 のヘルプで `updates`・`--apply` を確認した（[付録](#付録-cli-による更新手順の確認2026-10-04)）
    - 新しい更新・削除のブロック: Windows PowerShell 5.1 の構文解析器と、偽物のコマンドレット・CLI を使った模擬。再起動待ち・更新失敗・Store CLI 不足などで止まることを確認した。実際の更新コマンドやモジュールの導入・削除は実行していない
    - 貼り付けの設定（「貼り付けの設定」の手順 1〜4 と「PC 全体の設定」の手順 3・4。[付録](#付録-原因の確認と貼り付けの試験2026-10-03)）: 原因（コピーボタンの中身が LF だけで、conhost の右クリックの貼り付けが LF を Ctrl+Enter として送り、PSReadLine 2.0.0 の Ctrl+Enter が `InsertLineAbove`）と、「貼り付けの設定」の手順 1 の 1 行で直ることを、実機の Windows 11 の conhost の窓で確かめた。「貼り付けの設定」の手順 4 とロールバックの「アプリと貼り付けの設定を外す」の手順 6 は、もとの手順書（`windows-powershell-paste.md`）のときのブロックを、プロファイルを一時的なファイルに差し替えた実機の Windows PowerShell 5.1 で、文字コードの違うプロファイルを含めて流した。印を変えた今のブロックは、Linux の pwsh で模擬しただけ
    - LAN をプライベートにする「ネットワークとリモート」の手順 1 のブロックは、[Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)の手順 5（実機で通した）にあったものから、規則を確かめる行を除いて移した
    - scoop・UniGet UI・Caps Lock・コンテキストメニュー（最初の版の 4 項目）: [配布物と資料の調査の付録](#付録-配布物と資料の調査2026-10-03)
    - 足した項目: Microsoft の文書（Microsoft Learn・サポートの記事・ポリシーの文書）、Microsoft の DSC のリソース（`microsoft/winget-dsc`）、winget の定義、各ツールのソース（PowerShell・sudo・WSL・winget・PSReadLine・UniGet UI など）、Microsoft Store の API（[設定の調査の付録](#付録-windows-11-の設定の調査2026-10-03)）
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。条件で止まるブロック（プロファイルの行、PC の名前、自動で起動するアプリ、リモート デスクトップなど）は、偽物のコマンドレットで模擬して流した（[ブロックの確認の付録](#付録-足した項目の-powershell-のブロックの確認2026-10-03)）
    - 2026-10-05 に直したロールバックの「アプリと貼り付けの設定を外す」の手順 7 と「ネットワークと PC 全体の設定を戻す」の手順 1: Linux の PowerShell 7.6.6 で、記録した元値の復元と、空・不正値・書き込み失敗の分岐を模擬確認した。Windows の設定は変更していない（[付録](#付録-ロールバックの元値復元の模擬確認2026-10-05)）
  - **確かめていないこと**:
    - PSWindowsUpdate の初回導入・実更新・再起動後の再検索、古い Store から CLI を用意すること、Store の実更新と完了・失敗の表示。CLI 自体は `Preview` 表記
    - Windows で貼ること（すべての手順）と、画面の文言（設定・ストア・UniGet UI・Autologon）
    - Microsoft の文書に無い値が効くこと（エクスプローラーの `LaunchTo`・`ShowRecent`・`ShowFrequent`、スタートの提案の値、`StartupApproved`、`DelayLockInterval`、`DevicePasswordLessBuildVersion`、`RealTimeIsUniversal`、キーボードの種類、旧形式のコンテキストメニュー、スタートの検索の Web の結果）と、効く時期
    - Home の PC、Modern Standby の PC でのロック、Microsoft アカウントでの自動サインイン、arm64 の Windows
- 下表は、本書が前提にしている環境（ほかの Windows の手順書の実機の記録と同じ PC を想定）

| 項目 | 値 |
|---|---|
| OS | Windows 11（[Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)の実機の記録は 25H2）。x64。Pro を想定（Home では「ネットワークとリモート」の手順 2 を飛ばす） |
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
| CopyQ（任意節） | 16.0.0（winget の `hluk.CopyQ`、自分のユーザー。2026-10-08 の定義。上流の最新は 17.0.0） |
| Windows Terminal（任意節） | 1.24 以降（`warning.multiLinePaste` が 3 つの値の版）。貼り付けの設定の原因を確かめた PC は 1.25.2733.0 |
| WSL（任意節） | 同じ PC の記録は 2.7.13.0（ネットワークは既定の NAT）。ミラーには Windows 11 22H2 以上が要る |
| シェルのツール（任意節） | scoop の main の fzf 0.74.4・starship 1.26.0・eza 0.23.5・bat 0.26.1（2026-10-08 の定義）と、バケットの履歴の zoxide 0.9.9（main の定義は 0.10.0） |
| WSL の AlmaLinux 10 | `AlmaLinux-10`（2026-10-03 のイメージは 10.2） |

貼り付けの設定（「貼り付けの設定」の手順 1〜4 と「PC 全体の設定」の手順 3・4）の原因を確かめた環境（[付録](#付録-原因の確認と貼り付けの試験2026-10-03)）:

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro（10.0.26300。x86_64 のノート PC） |
| PowerShell | Windows PowerShell 5.1.26100.9444（PSReadLine 2.0.0） |
| 窓 | conhost（`conhost.exe` で開いた窓。利用者の管理者の Windows PowerShell も conhost）。管理者でない窓は Windows Terminal 1.25.2733.0 |
| コピー | GitHub の Web のコードブロックのコピーボタン（Firefox） |

> [!NOTE]
> 環境固有の値は**変数**で書いてある。「PC 全体の設定」の手順 2 の PowerShell の変数に 1 度だけ設定すれば、同じ項の手順 3 から「WSL と再起動」の手順 1 までのコマンドはそのまま貼って実行できる。
>
> | 変数 | 設定する場所 | 意味 | 例 |
> |---|---|---|---|
> | `$PC_NAME` | 「PC 全体の設定」の手順 2 | この PC の新しい名前（名前を変えるときに入れる。変えないなら空のままにして「PC 全体の設定」の手順 5 を飛ばす） | `<HOSTNAME>` |
> | `$LAN_IF` | 「PC 全体の設定」の手順 2（[ロールバック](../extra/windows-setup.md#ロールバック)では「サインイン・検索・キーボードを戻す」の手順 2、[Wake on LAN を使う（任意）](../windows-setup.md#wake-on-lan-を使う任意)では手順 2） | ほかの PC とつながる LAN の接続の名前（自動で入る） | `イーサネット` |
> | `$OLD_PC_NAME` | [ロールバックの「ネットワークと PC 全体の設定を戻す」](../extra/windows-setup.md#ネットワークと-pc-全体の設定を戻す)の手順 9 | 元の PC の名前（名前を戻すときに入れる） | `<HOSTNAME>` |
> | `$OLD_EXECUTION_POLICY` | [ロールバックの「アプリと貼り付けの設定を外す」](../extra/windows-setup.md#アプリと貼り付けの設定を外す)の手順 7 | 「貼り付けの設定」の手順 2 で控えた `CurrentUser` の実行ポリシー | `Undefined` |
> | `$OLD_DOWNLOAD_MODE` | [ロールバックの「ネットワークと PC 全体の設定を戻す」](../extra/windows-setup.md#ネットワークと-pc-全体の設定を戻す)の手順 1 | 「PC 全体の設定」の手順 3 で控えた配信の最適化のモード | `CdnOnly` |
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
  - 管理者の Windows PowerShell を Windows Terminal で開く（Win+X の「ターミナル (管理者)」）: 設定は変えずに済むが、開き方を変える必要がある。既定の端末を Windows Terminal にしても（「表示と入力」の手順 6）、スタートメニューから管理者で開くと conhost になる（「表示と入力」の手順 6 の補足）
  - conhost の窓では Ctrl+V で貼る: 設定は変えずに済むが、右クリックで貼ると逆順になるのは残る（[ロールバック](../extra/windows-setup.md#ロールバック)の後の貼り方として、その「アプリと貼り付けの設定を外す」の手順 6 に書いた）
  - ブロックを 1 行に書く: 手順書が読みにくくなる
  - 選んで Ctrl+C でコピーする: コピーボタンを使えない
  - コピーボタンの中身の改行を変える: 中身は GitHub が作る（改行は LF）
- **この文書にまとめた**: もとは別の手順書（`windows-powershell-paste.md`）で、Windows の PowerShell のブロックを貼る手順書の共有の前提だった。Windows のインストール直後に行うものなので、2026-10-03 に、この文書の「貼り付けの設定」の手順 1〜4 にまとめた（実行ポリシーの手順も重なっていた）。ほかの手順書は、この文書の「貼り付けの設定」の手順 1〜4 を前提にする

### 操作上の注意と併記されていた記録

- **PowerShell 7 のプロファイルは別**: 「貼り付けの設定」の手順 4 の行は Windows PowerShell 5.1 のプロファイルにだけ書く。PowerShell 7（「アプリを入れる」の手順 5）は `Documents\PowerShell\Microsoft.PowerShell_profile.ps1` を読み、貼り付けの設定の原因を確かめた PC の PowerShell 7.6.6（PSReadLine 2.4.5）でも Ctrl+Enter は `InsertLineAbove` だった（もとの手順書 `windows-powershell-paste.md` の注意点の記録）。この文書の手順書群は、Windows PowerShell 5.1 に貼る

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
- [hackgen.md](../almalinux-setup.md#hackgen-console-nf) — HackGen Console NF（AlmaLinux 10 と Windows 11）
- [Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー) — 同じ PC で使うことの多い手順書（scoop のツールを SSH のセッションで使う任意節。LAN がプライベートである前提）

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
  - ほかの規則の指摘は、「アプリを入れる」の手順 1 の `Invoke-Expression`（公式のインストーラの方法なので、そのまま）と、ASCII でない文字を含むファイルの BOM（貼るので関係が無い）だけ
  - わざと PowerShell 7 だけの書き方（`??`、`Get-Content -AsByteStream`、`ForEach-Object -Parallel`、`Join-Path -AdditionalChildPath`）を入れたファイルでは、それぞれ指摘が出た
- `(Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass'`（「貼り付けの設定」の手順 3）は、列挙の値と文字列を比べて、`RemoteSigned` で `False`、`Restricted` で `True` になった

**「サインイン・検索・キーボード」の手順 4 と[ロールバックの「サインイン・検索・キーボードを戻す」](../extra/windows-setup.md#サインイン検索キーボードを戻す)の手順 11 のブロック**を、管理者の判定を `$true` に替え、レジストリ（`Get-ItemProperty`・`New-ItemProperty`・`Remove-ItemProperty`）を値を覚えておく偽物にして、`Scancode Map` が無いとき・本書の値のとき・別の値（`00 00 00 00 00 00 00 00 02 00 00 00 00 00 5B E0 00 00 00 00`）のときで流した:

| ブロック | 無い | 本書の値 | 別の値 |
|---|---|---|---|
| 「サインイン・検索・キーボード」の手順 4 | 書き（1 回）、`Scancode Map = 00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00` | 書かずに同じ行 | `中断: 別の Scancode Map がある（…）` で止まり、書かない |
| ロールバックの「サインイン・検索・キーボードを戻す」の手順 11 | `Scancode Map は無い` | 消して `Scancode Map を消した` | `中断: 本書の値ではない Scancode Map がある（…）` で止まり、消さない |

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（「貼り付けの設定」の手順 2 の判定、scoop のインストーラ、winget の表示、UniGet UI の画面）
1. `HKCU` の CLSID の設定で、今の Windows 11（25H2・26H2）のエクスプローラーが旧形式のメニューを出すこと
1. Scancode Map で、Caps Lock が Ctrl になること（JIS 配列のキーボード、リモート デスクトップでつないだときも）
1. 更新（scoop・UniGet UI）とロールバック、arm64 の Windows

---

### 付録: 原因の確認と貼り付けの試験（2026-10-03）

この付録は、もとの手順書 `docs/windows-powershell-paste.md`（2026-10-03 にこの文書へまとめて消した）の付録を移したもの。手順の番号だけ、この文書の番号に付け替えた（当時の手順 1〜7 は今の「貼り付けの設定」の手順 1〜4 と「PC 全体の設定」の手順 1・3・4、当時のロールバックの手順 1・2 は今の[ロールバックの「アプリと貼り付けの設定を外す」](../extra/windows-setup.md#アプリと貼り付けの設定を外す)の手順 6・7）。試験したブロックは当時のもの（プロファイルの行の印は `# windows-powershell-paste.md`。今の「貼り付けの設定」の手順 4 とロールバックの「アプリと貼り付けの設定を外す」の手順 6 は、印を変え、古い印の行も見つけるようにした。その確認は[ブロックの確認の付録](#付録-足した項目の-powershell-のブロックの確認2026-10-03)）。

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
| LF だけ（末尾に改行無し） | `-Command` で「貼り付けの設定」の手順 1 の 1 行 | 元の順（`}` が最後の行） | `1 行目` / `2 行目` / `3 行目` |
| LF だけ（末尾に改行無し） | 同じ行（印のコメント付き）を書いたファイルを `-Command` の `.` で読ませた | 元の順 | `1 行目` / `2 行目` / `3 行目` |
| CR LF（末尾に改行あり） | 無し | — | `1 行目` / `2 行目` / `3 行目` |
| CR LF（末尾に改行あり） | `-Command` で「貼り付けの設定」の手順 1 の 1 行 | — | `1 行目` / `2 行目` / `3 行目` |

**対話でない起動**: 標準入力をリダイレクトした `powershell.exe -NoProfile -Command "Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine; 'ok'"` は、エラー無しで `ok` を出した。

**`Add-Content` の書き足し方**: Windows PowerShell 5.1 で、末尾に改行の無いファイル（`Set-Alias ll Get-ChildItem`）に `Add-Content` で 1 行を足すと、`Set-Alias ll Get-ChildItemX-LINE` と最後の行につながった。「貼り付けの設定」の手順 4 のブロックは、そのときに行の前へ CR LF を付ける。

**「貼り付けの設定」の手順 4 とロールバックの「アプリと貼り付けの設定を外す」の手順 6 のブロック**: 当時の文書から `powershell` のブロックを抜き出し（リストの字下げを外した）、Windows PowerShell 5.1 で、`$PROFILE` を一時的なディレクトリの `WindowsPowerShell\Microsoft.PowerShell_profile.ps1` に差し替えて `Invoke-Expression` で流した。どの場合も「貼り付けの設定」の手順 4 を 2 回（2 回目は `すでにある:`）、ロールバックの「アプリと貼り付けの設定を外す」の手順 6 を 2 回（2 回目は `その行は無い:` か `プロファイルが無い:`）流した。既存のプロファイルの中身は、日本語のコメントと `Set-Alias ll Get-ChildItem` の 2 行:

| 既存のプロファイル | 「貼り付けの設定」の手順 4 の後 | ロールバックの「アプリと貼り付けの設定を外す」の手順 6 の後 |
|---|---|---|
| 無い | `足した:`。ASCII の 1 行（93 バイト） | `消した:`（ファイルが消えた） |
| 空のファイル | 同じ | `消した:` |
| UTF-16 LE（BOM あり） | 先頭は `FF FE` のまま。足した行は 3 行目 | `その行だけ消した:`。前と同じバイト |
| UTF-8（BOM あり） | 先頭は `EF BB BF` のまま。足した行は 3 行目 | 前と同じバイト |
| UTF-8（BOM 無し）、末尾に改行無し | 足した行は 3 行目（前に CR LF を付けた）。5.1 の `Get-Content` では日本語が化けて見えた（ANSI として読む）が、バイトは変わらない | 日本語を含め前と同じバイトに、「貼り付けの設定」の手順 4 で付けた CR LF だけが残った |
| Shift_JIS | 足した行は 3 行目 | 前と同じバイト |
| UTF-16 LE・UTF-8（BOM あり）で、「貼り付けの設定」の手順 4 の行だけ | `すでにある:` | `消した:`（ファイルが消えた） |
| UTF-16 LE・UTF-8（BOM あり）で、1 行目が「貼り付けの設定」の手順 4 の行、2 行目が `Set-Alias` | — | `その行だけ消した:`。BOM と `Set-Alias` の行だけが残った |

最初に書いたロールバックの「アプリと貼り付けの設定を外す」の手順 6 は、正規表現が `(?m)^` と行だけだったので、BOM の直後（ファイルの 1 行目）にある行を見つけられず、BOM のあるファイルで `その行は無い:` を出した。BOM を許して残すように直し、上の表はすべて直した後のもの。

**構文**: 当時の文書の `powershell` のブロック 8 個を、Windows PowerShell 5.1 の `[System.Management.Automation.Language.Parser]::ParseInput` に通した（構文の誤りは 0）。

---

### 付録: Windows 11 の設定の調査（2026-10-03）

インストール直後の作業をこの文書にまとめたとき（2026-10-03）に、Windows を動かせない環境（クラウドの Linux のコンテナ）で、文書・ソース・定義を読んだ記録。確かさは、Microsoft の文書かソース（「文書」）、Microsoft の書いたコードや配布物の中身（「コード」）、それ以外の広く使われている情報（「広く」）で書く。

**自分のユーザーの設定（「表示と入力」と「自動起動と標準アプリ」）**

- エクスプローラー（「表示と入力」の手順 1）: `HideFileExt`・`Hidden`・`Start_TrackDocs` は、Microsoft の DSC のリソース `microsoft/winget-dsc`（コミット `8a8387e`）の `Microsoft.Windows.Developer` が同じ値を書く（コード）。`Start_TrackDocs` を 0 にするのは、Microsoft Learn の「Manage connections from Windows operating system components to Microsoft services」の 33 節にもある（文書）。`LaunchTo`・`ShowRecent`・`ShowFrequent` は広く
- スタートと提案（「表示と入力」の手順 3）: 設定の画面の文言は Microsoft のサポートの記事（文書）。値（`Start_IrisRecommendations`・`Start_AccountNotifications`・`ContentDeliveryManager` の `SubscribedContent-*`・`SystemPaneSuggestionsEnabled`・`SilentInstalledAppsEnabled`・`UserProfileEngagement\ScoobeSystemSettingEnabled`）は広く。2025 年の終わりのスタートの作り直しで足された切り替えの値は、見つからなかった
- スタートの検索の Web の結果（「サインイン・検索・キーボード」の手順 2）: `HKCU\Software\Policies\Microsoft\Windows\Explorer` の `DisableSearchBoxSuggestions` は、ポリシーの文書（`WindowsExplorer.admx`）では「エクスプローラーの検索ボックスに最近の検索を出さない」。スタートの検索の Web の結果が消えるのは広く。`HKCU\Software\Policies` は、管理者でないと書けない（Microsoft のフォーラムの回答）
- タスクバー（「表示と入力」の手順 4）: `TaskbarAl`・`ShowTaskViewButton`・`SearchboxTaskbarMode`（0 が消す、1 がアイコン、2 が検索ボックス、3 がアイコンとラベル）は DSC の `Taskbar`（コード）。ポリシーの `ConfigureSearchOnTaskbarMode` は番号の意味が違う（文書）。`ShowSecondsInSystemClock` は 22H2 の 2023 年 5 月のプレビューの更新（KB5026446）から（広く）。`TaskbarDa` は UCPD（`ucpd.sys`）が守っていて、`powershell.exe`・`reg.exe` などからの書き込みは拒まれる（広く。ドライバーを解析した記事）
- ダークモード（「表示と入力」の手順 5）: `AppsUseLightTheme`・`SystemUsesLightTheme` は DSC の `Microsoft.Windows.Settings` が書き、`WM_SETTINGCHANGE`（`ImmersiveColorSet`）を送る（コード）
- 既定の端末（「表示と入力」の手順 6）: `HKCU\Console\%%Startup` の GUID は Windows Terminal の文書の `group-policy.md`（文書）。22H2 以降の既定（「Windows に任せる」）は Microsoft のサポートの記事（文書）。管理者のコンソールが引き渡されないことは、microsoft/terminal の #13392（「管理者のコマンド ラインの受け手として登録できる端末は無い」）と #10276・#10682・#15126 で、開いたまま
- IME（「表示と入力」の手順 7）: 設定の画面（`ms-settings:regionlanguage-jpnime`）は Microsoft のサポートの記事（文書）。レジストリの値は、ある開発者が画面の前後で見比べた記録だけ（`cuzic/awase`）。Ctrl+Space を Windows が使うのは中国語の IME だけ（Microsoft のキーボード ショートカットの文書）
- 自動で起動するアプリ（「自動起動と標準アプリ」の手順 1）: `StartupApproved\Run` の先頭の 1 バイト（2 が起動、3 が停止）は広く（UniGet UI のインストーラも同じ所に書く）。Teams の起動のタスクの名前 `TeamsTfwStartupTask` は、Teams の MSIX の `AppxManifest.xml`（26198.304.4946.9672）にある（コード）。`State` の値は `StartupTaskState`（文書）。UniGet UI を winget で入れると、`Run` に `WingetUI`（`--daemon`）ができる（winget の定義が `/NoRunOnStartup` を渡さない。インストーラの定義 `UniGetUI.iss`）
- 標準アプリ（「自動起動と標準アプリ」の手順 2・3）: パッケージの名前・パッケージ ファミリー名・ストアの ID は、Microsoft Store の API（`storeedgefd.dsx.mp.microsoft.com`）で確かめた（文書）。「Microsoft 365 Copilot」は `Microsoft.MicrosoftOfficeHub`（`9WZDNCRD29V9`）で、Copilot（`Microsoft.Copilot`、`9NHT9RB2F4HD`）とは別のパッケージ。自分のユーザーから外しただけのアプリは機能の更新で戻りうる（「Remove provisioned apps during update」。文書）
- PowerToys（「アプリを入れる」の手順 4）: winget の定義 0.101.2362.0 に、自分のユーザーのインストーラ（`PowerToysUserSetup`、管理者の指定無し）と PC 全体のインストーラ（`elevatesSelf`）がある。形式は Burn、渡す引数は `/quiet /norestart`
- ピン留め（「再起動の後に確かめる」の手順 3）: 自分のユーザーで使える、サポートされたコマンドは見つからなかった。Microsoft の文書の方法は、タスクバーのレイアウトの XML、`ConfigureStartPins`（24H2 の KB5062660 から `applyOnce`）などのポリシーとプロビジョニングだけ

**PC 全体の設定（「PC 全体の設定」の手順 5 から「WSL と再起動」の手順 1 まで）**

- PC の名前（「PC 全体の設定」の手順 5）: `Rename-Computer` は、15 文字を超える名前で `ShouldContinue` の問いを出し（`-Force` で出さない）、今と同じ名前で `NewNameIsOldName` のエラーを出す（PowerShell のソースの `Computer.cs`。5.1 は文書の文言が同じ）。名前の決まりは Microsoft Learn の「Naming conventions in Active Directory」（文書）
- 長いパス・開発者モード（「PC 全体の設定」の手順 6）: `LongPathsEnabled` と `AllowDevelopmentWithoutDevLicense` は Microsoft Learn（「Maximum Path Length Limitation」と「Developer Mode」）の値（文書）
- sudo（「PC 全体の設定」の手順 6）: 24H2 から（文書）。`sudo config --enable` の 3 つの形と、インラインの危うさは Microsoft Learn（文書）。レジストリの値（`HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo` の `Enabled`。0〜3）は microsoft/sudo の `helpers.rs`（コード）。Home で使えるかは書かれていない
- 電源（「PC 全体の設定」の手順 7）: `powercfg` の別名（`SUB_BUTTONS`・`LIDACTION`・`SUB_NONE`・`CONSOLELOCK`）と値は、Microsoft Learn の電源の設定の文書（文書）。休止状態を切ると高速スタートアップのファイルも無くなる（文書から言えること。1 文で書いた文書は無い）。`DelayLockInterval` は広く（Microsoft の文書は見つからなかった）。S3 の PC では、画面が消えるだけではロックしない（眠り・パスワード付きのスクリーン セーバー・`InactivityTimeoutSecs`・動的ロックだけがロックする。文書からの推論）
- アダプター（「PC 全体の設定」の手順 8）: `Set-NetAdapterPowerManagement` は `-NoRestart` が無いとアダプターを起動し直す（文書）。`AllowComputerToTurnOffDevice` は WMI のクラスの文書では読み取り専用で、変えて渡す形は広く。この項目を外すと、Windows が任せる Wake on LAN も効かなくなる（Windows 7 の頃のサポートの記事 KB2740020。2026-05 に消え、MicrosoftDocs の履歴から読んだ）
- リモート デスクトップ（「ネットワークとリモート」の手順 2）: Home はつながれる側になれない（文書）。`fDenyTSConnections`・`UserAuthentication`、規則のグループ `@FirewallAPI.dll,-28752` と規則の名前 `RemoteDesktop-UserMode-In-TCP` は、Azure の VM の切り分けの文書と無人インストールの文書（文書）。画面でオンとオフにし直したときに規則のプロファイルが戻るかは、分からなかった
- リモート アシスタンス（「ネットワークとリモート」の手順 3）: `fAllowToGetHelp`（無人インストールの文書）。規則のグループ `@FirewallAPI.dll,-33002` は、Windows の `racpldlg.dll` の文字列にある（コード。Learn には無い）
- ping（「ネットワークとリモート」の手順 4）: `New-NetFirewallRule` の `-Protocol ICMPv4 -IcmpType 8` と `ICMPv6`・`128`（文書）
- 配信の最適化（「ネットワークとリモート」の手順 5）: 既定は LAN（配信の最適化の文書。ポリシーの文書は 0 と書いていて食い違う）。`Set-DODownloadMode`・`Get-DODownloadMode`（文書）
- Windows Hello（「サインイン・検索・キーボード」の手順 1）: `DevicePasswordLessBuildVersion` は広く（Microsoft の文書は見つからなかった）
- Edge のショートカット（「サインイン・検索・キーボード」の手順 3）: `RemoveDesktopShortcutDefault`（Edge Update 1.3.155.1 から）と、`CreateDesktopShortcutDefault` が入っていると効かないことは、Edge Update のポリシーの文書（文書）
- 時計（「サインイン・検索・キーボード」の手順 5）: `RealTimeIsUniversal` は Microsoft の文書に無い。Arch Linux の wiki は DWORD を勧める（QWORD の古い勧めは消えた）
- キーボードの種類（「サインイン・検索・キーボード」の手順 6）: US 配列の 4 つの値は、Microsoft の日本の社員のブログ（Learn の archive の「英語キーボードを快適に使う」）。JIS の値は広く
- WSL（「WSL と再起動」の手順 1 と「WSL の AlmaLinux 10 と自動サインイン」の手順 3）: `--no-distribution` は Windows 11 では仮想マシン プラットフォームだけを入れる（WSL のソースの `WslInstall.cpp`）。`AlmaLinux-10` は `DistributionInfo.json`（2026-10-03、10.2.20260526.0）。最初の起動のユーザーの作成は AlmaLinux の `wsl-images` の `oobe`（uid 1000、`wheel`、`systemd=true`）
- Autologon（「WSL の AlmaLinux 10 と自動サインイン」の手順 5）: winget の定義 3.10 は版の付かない `AutoLogon.zip` を取り、2026-10-03 は sha256 が一致した。パスワードは LSA のシークレットに置く（Microsoft Learn の Autologon と「Protecting the automatic logon password」）。Microsoft アカウントの `Domain` の入れ方は分からなかった
- PowerShell 7（「アプリを入れる」の手順 5）: 7.6.0 から winget は MSIX を既定で入れ、7.7.0 から MSI は無くなる（Microsoft Learn の Windows への入れ方）。winget の選び方（MSIX が MSI より先）は winget のソースの `ManifestComparator.cpp`。PowerShell 7.6.6 の PSReadLine は 2.4.5 で、Ctrl+Enter は `InsertLineAbove`（PSReadLine の `KeyBindings.cs`）

---

### 付録: 足した項目の PowerShell のブロックの確認（2026-10-03）

インストール直後の作業をこの文書にまとめた後の、全部のブロックを、Linux（クラウドのコンテナ）の PowerShell 7.6.6 と PSScriptAnalyzer 1.25.0 で確かめた。Windows では貼っていない。

**構文と Windows PowerShell 5.1 との互換**:

- この文書の `powershell` のブロック 90 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた
  - `Set-ItemProperty` の `-Type` が 5.1 に無いという指摘が 54 個出た。`-Type` はレジストリのプロバイダーが足す動的なパラメーターで、5.1 の `Set-ItemProperty` の文書にもある（`reference/5.1/Microsoft.PowerShell.Management/Set-ItemProperty.md` の「This is a dynamic parameter made available by the Registry provider」）。互換の検査は動的なパラメーターを見ないので、指摘は当たらない
  - ほかは、「アプリを入れる」の手順 1 の `Invoke-Expression`（公式のインストーラの方法）と、1 つの変数だけのブロック（「PC 全体の設定」の手順 2・ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 9 の `$PC_NAME`・`$OLD_PC_NAME`）の「代入して使っていない」だけ
- 「貼り付けの設定」の手順 4 とロールバックの「アプリと貼り付けの設定を外す」の手順 6 の正規表現と文字列、「PC 全体の設定」の手順 5 の名前の正規表現も、この構文解析器で読めた

**偽物のコマンドレットで流したブロック**（Linux の pwsh。レジストリは、値を覚えておく偽物の `Set-ItemProperty`・`Get-ItemProperty`・`Get-Item`・`Test-Path`・`New-Item` にした）:

| ブロック | 流した場合 | 結果 |
|---|---|---|
| 「貼り付けの設定」の手順 4（プロファイルに足す） | 無い・空・UTF-8（BOM の有無）・Shift_JIS の既存のファイル、新しい印の行がある、古い印（`# windows-powershell-paste.md`）の行がある、両方ある | 無いときだけ `足した:`、2 回目と印の行があるときは `すでにある:` |
| ロールバックの「アプリと貼り付けの設定を外す」の手順 6（プロファイルから消す） | 上の各場合と、UTF-16 LE、BOM の直後の行、新旧の両方の行。正規表現の BOM は、もとの手順書と同じく `\uFEFF` などの ASCII の書き方（文字をそのまま書くと、コピーと貼り付けで落ちうる） | どちらの印の行も消え、ほかの行と BOM はバイトのまま残った。残りが BOM と空白だけならファイルを消した。UTF-8（BOM 無し、末尾に改行無し）では、「貼り付けの設定」の手順 4 で付けた CR LF だけが残った（もとの手順書の付録と同じ） |
| 「PC 全体の設定」の手順 5（PC の名前） | 空、`my-pc`、今と同じ名前（大文字と小文字の違いも）、16 文字以上、数字だけ、先頭か末尾がハイフン、`_` を含む、1 文字 | 空と使えない名前は `中断:`、同じ名前は `すでにこの名前:`、ほかは `Rename-Computer -NewName <名前>` を 1 回呼んだ |
| ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 9（名前を戻す） | 空、今と同じ名前、別の名前、16 文字以上、数字だけ | 空と使えない名前は `中断:`、同じ名前は `すでにこの名前:`、ほかは `Rename-Computer` を 1 回（`-Force` は付けない） |
| 「自動起動と標準アプリ」の手順 1（自動で起動するアプリ） | `Run` に `OneDrive`・`MicrosoftEdgeAutoLaunch_ABC`・`WingetUI`、Teams の起動のタスクあり。もう 1 回は `OneDrive` だけで Teams 無し | `OneDrive` と Edge に `03 00 00 00` と 8 バイトの日時を書き、Teams の `State` を 1 にした。一覧は 2 つが `止めている`、`WingetUI` が `起動する`。2 回目は `OneDrive` だけを止めた |
| ロールバックの「表示と入力を戻す」の手順 8 | 上の後 | 2 つを `02` と 11 バイトの 0 に、Teams を 2 に戻した |
| 「自動起動と標準アプリ」の手順 2・3（標準アプリ・ウィジェット） | 11 個のうち 3 個と Copilot だけが入っている。ウィジェットは無い場合とある場合 | 入っている 3 個だけ `Remove-AppxPackage` に渡し、ほかは `無い:`。Copilot には触れなかった |
| 「PC 全体の設定」の手順 8・ロールバックの「ネットワークと PC 全体の設定を戻す」の手順 6（アダプター） | `$LAN_IF` が空、`Enabled` のアダプター、`Unsupported` のアダプター | 空は止まり、`Unsupported` は `対象外:`。ほかは `AllowComputerToTurnOffDevice` を `Disabled`（戻すときは `Enabled`）にして、`-NoRestart` 付きで渡した |
| 「ネットワークとリモート」の手順 2（リモート デスクトップ） | `EditionID` が `Core`・`CoreSingleLanguage`・`Professional` | Home の 2 つは `中断:` で何も書かず、`Professional` だけ 2 つの値を書いて規則を `-Profile Private` にした |
| 「サインイン・検索・キーボード」の手順 3（ショートカット） | すべてのユーザーのデスクトップに `Microsoft Edge.lnk` があり、自分のデスクトップに `UniGetUI.lnk` が無い。2 回 | ポリシーを書き、1 回目は Edge を `消した:`、UniGet UI を `無い:`。2 回目はどちらも `無い:` |
| OpenSSH サーバーの手順 5・Syncthing の Windows 11 の手順 7（LAN がプライベートかを確かめる） | `$LAN_IF` が空、パブリック、プライベート | 空とパブリックは止まり（Syncthing は規則を作らない）、プライベートだけ規則を確かめた（作った） |

**Wake on LAN の 1 行**（任意節の手順 7）: Linux の Python 3.11 で、MAC アドレスの例を入れて流し、102 バイト（`FF` が 6 個と MAC が 16 回）のパケットを送れた（受け取る側は確かめていない）。

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（画面の手順と、設定・ストア・UniGet UI・Autologon の文言を含む）
1. Microsoft の文書に無いレジストリの値（[状態](#対象と検証環境)の「確かめていないこと」）が、24H2・25H2・26H2 で効くこと
1. 「PC 全体の設定」の手順 8 の `AllowComputerToTurnOffDevice` を変えて渡す形が、今の Windows 11 の `Set-NetAdapterPowerManagement` で効くこと
1. 「ネットワークとリモート」の手順 2 の後に、設定の画面でリモート デスクトップをオンとオフにしたとき、規則のプロファイルが戻るか
1. Modern Standby の PC で、「PC 全体の設定」の手順 7 の後に放置してもロックしないこと
1. Microsoft アカウントでの自動サインイン（「WSL の AlmaLinux 10 と自動サインイン」の手順 5）と、Wake on LAN（任意節）
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
- もとの手順 4〜52（今の「貼り付けの設定」の手順 1 から「WSL の AlmaLinux 10 と自動サインイン」の手順 5 まで）と、既存の任意節・更新・ロールバックのコマンドを、変更前の文書と比較した。手順参照の番号以外は変わっていない
- 既存の付録も、手順参照の番号以外は変わっていない。別の手順書の番号・ロールバックの番号・当時の番号は、元の参照先を保った
- 関連する 12 本の手順書は、初期設定を参照する番号だけの変更であることを比較した。実施手順は 64、ロールバックは 41 手順になった

**模擬の実行**:

- 新しいブロックのコマンドレットと `store.exe`・`winget.exe` を、検証用の PowerShell 関数に置き換えて 61 ケースを通した
- PowerShell の版と管理者かどうかの判定は、検証用の値に差し替えた。コマンドに渡る引数と、成功・警告・エラーの分岐を確認した

| 対象 | 確認した分岐 |
|---|---|
| 準備（「Windows Update」の手順 2・3） | 5.1／7、管理者／通常の窓、実行ポリシーの制限、モジュールと NuGet の有無、違う PSGallery の URL、導入と読み込みの失敗 |
| Windows Update（「Windows Update」の手順 4〜8） | 対象 0 件／通常の更新あり、オプション・プレビュー・非表示・導入済みの除外、検索と導入の失敗、再起動待ちと判定できない場合、検索中に再起動待ちになる場合 |
| Store（「Microsoft Store の更新」の手順 2〜7） | CLI の有無・一括更新への対応、登録の失敗、2 製品だけの準備、更新なしの終了コード、検索・適用・再検索の失敗、必要なパッケージの欠落・不正常な状態 |
| モジュールの保守（更新の手順 5・ロールバックの「再起動と PSWindowsUpdate」の手順 4） | モジュールだけの更新・削除、失敗時の中断、管理者の窓で削除しないこと、ほかの場所に残ったモジュールを続けて消さないこと |

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
- 実施手順の「貼り付けの設定」の手順 3 と「ネットワークとリモート」の手順 5、ロールバックの「アプリと貼り付けの設定を外す」の手順 7 と「ネットワークと PC 全体の設定を戻す」の手順 1 を本文から抜き出し、設定の読み書きだけを偽物のコマンドレットに置き換えた
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

### 付録: プライバシー・表示・入力・音・ストレージ・Edge・CopyQ の任意節のブロックの確認（2026-10-08）

「プライバシーと広告の表示を切る（任意）」「表示・入力・音・ストレージを変える（任意）」「Edge の常駐をポリシーで止める（任意）」「CopyQ を使う（任意）」を足したときに、PowerShell のブロックを、Linux（クラウドのコンテナ、Ubuntu 24.04）の PowerShell 7.5.3 と PSScriptAnalyzer 1.25.0 で確かめた。Windows では貼っていない。

**対象のブロック**:

- `origin/main` との差分で、足したか変えた `powershell` のブロック 34 個（手順書のブロックは 117 個から 150 個になった）
  - プライバシーと広告の節の 4 個（その節の手順 2・4・5・6）、表示・入力・音・ストレージの節の 21 個（その節の「表示・入力・音・ストレージを控えて変える」の手順 2〜12・14 と「表示・入力・音・ストレージを元に戻す」の手順 1〜9）、Edge の常駐の節の 2 個（その節の手順 2・5）、CopyQ の節の 6 個（その節の手順 2〜5・7・8）
  - [更新](../windows-setup.md#更新)の手順 3 の 1 個（winget の一覧に `hluk.CopyQ` を足した）
- [実施手順](../windows-setup.md#実施手順)の全部（12 項）、[ロールバック](../extra/windows-setup.md#ロールバック)の全部（5 項）、Wake on LAN とリモートからの再起動の任意節の手順は、`origin/main` と 1 行も変わっていない

**構文と Windows PowerShell 5.1 との互換**:

- 34 個を、PowerShell 7.5.3 の構文解析器に通した（構文の誤りは 0）。表示・入力・音・ストレージの「表示・入力・音・ストレージを控えて変える」の手順 8 と「表示・入力・音・ストレージを元に戻す」の手順 6 の here-string（閉じの `'@` はリストの字下げの位置）も、字下げを外した形で読めた
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル `win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework`）を当てた
  - 互換の指摘は 16 個で、すべて `PSUseCompatibleCommands` の `Set-ItemProperty` の `-Type`（ブロックの中の 16 か所すべて）。レジストリのプロバイダーが足す動的なパラメーターで、ほかの手順と同じ既知の偽陽性（[付録](#付録-足した項目の-powershell-のブロックの確認2026-10-03)）
  - `PSUseCompatibleSyntax` と `PSUseCompatibleTypes` の指摘は 0
  - わざと PowerShell 7 だけの書き方（`??`・`Get-Content -AsByteStream`・`ForEach-Object -Parallel`）を入れたファイルでは、3 つとも指摘が出た
- 既定の規則の指摘は 12 個で、すべて `PSUseBOMForUnicodeEncodedFile`（日本語を含むファイルに BOM が無い。貼るので関係が無い）

**`Add-Type` の宣言**（表示・入力・音・ストレージの「表示・入力・音・ストレージを控えて変える」の手順 8 と「表示・入力・音・ストレージを元に戻す」の手順 6。2 つの宣言は同じ文字列）:

- 宣言（`ANIMATIONINFO` の構造体と、`SystemParametersInfo` の 3 つの多重定義）は、PowerShell 7.5.3 の `Add-Type` でそのままコンパイルできた。構造体の大きさは 8 バイト（`cbSize` の 8 と同じ）。Linux では、呼び出しは例外になった（`user32.dll` は Windows の DLL）
- 同じ窓で同じ宣言の `Add-Type` を 2 回流しても、誤りは出なかった（「表示・入力・音・ストレージを控えて変える」の手順 8 の後に「表示・入力・音・ストレージを元に戻す」の手順 6 を貼る場合）
- 同じ 3 つの形で、中身を「受け取った値を覚えるだけ」にした型に差し替えて、2 つのブロックを流した:
  - `0x1043`（`SPI_SETCLIENTAREAANIMATION`）は `IntPtr` の形、`0x0049`（`SPI_SETANIMATION`）は `ref ANIMATIONINFO` の形（`uiParam` と `cbSize` が 8）、`0x1042`（`SPI_GETCLIENTAREAANIMATION`）は `ref int` の形が選ばれた。`fWinIni` は、設定の 2 つが 3、読み戻しが 0
  - 「表示・入力・音・ストレージを控えて変える」の手順 8 は `pvParam` が 0・`iMinAnimate` が 0 で、`ClientAreaAnimation : 0`・`MinAnimate : 0` を出した。「表示・入力・音・ストレージを元に戻す」の手順 6 は 1・1 で、`1`・`1` を出した（`MinAnimate` の行は、偽物の型が覚えた値を返す偽物の `Get-ItemProperty` で出した）

**偽物のコマンドレットで流したブロック**（Linux の pwsh）:

- レジストリは、キーと値と種類を覚えておく偽物（`Get-Item`・`Get-ItemProperty`・`Set-ItemProperty`・`New-Item`・`Remove-ItemProperty`・`Test-Path`・`Get-ChildItem`・`Join-Path`）に置き換えた
  - 値の無いキーの `Get-ItemProperty` は何も返さず、既にあるキーへの `New-Item -Force` は中の値を消す偽物にした。どの場合も、既にあるキーへの `New-Item` は呼ばれなかった
- `reg.exe` は、`export`・`import`・`add`・`query`・`delete` を真似る関数にした（控えのファイルは `.reg` の形式ではない）
- `%LOCALAPPDATA%` は一時のディレクトリにし、控えの CSV と `reg.exe` の控えは、そこに本物のファイルとして書いた

| 対象 | 流した場合 | 結果 |
|---|---|---|
| 「表示・入力・音・ストレージを控えて変える」の手順 3（固定キーなど） | `Flags` が `510`・`126`・`62`。続けてもう 1 回 | `StickyKeys: 510 -> 506`・`Keyboard Response: 126 -> 122`・`ToggleKeys: 62 -> 58` を出し、文字列（REG_SZ）で書いた。2 回目は `506 -> 506` などで変わらない |
| 同じ「表示・入力・音・ストレージを控えて変える」の手順 3 | `StickyKeys` のキーが無い、`Keyboard Response` に `Flags` が無い、`ToggleKeys` が `abc` | 3 つとも `無い:` を出し、何も書かなかった |
| 「表示・入力・音・ストレージを元に戻す」の手順 1（戻す） | 「表示・入力・音・ストレージを控えて変える」の手順 3 の後。続けてもう 1 回。上の無い・`abc` の場合 | `506 -> 510`・`122 -> 126`・`58 -> 62`。2 回目は変わらない。無い・`abc` は `無い:` で、何も書かなかった |
| プライバシーと広告の手順 2 | `Enabled`（`AdvertisingInfo`）・`NumberOfSIUFInPeriod`・`HasAccepted`・`IsDeviceSearchHistoryEnabled` が 1、`PeriodInNanoSeconds` が QWORD の `864000000000`。`Privacy` と `Input\TIPC` のキーが無い。ほかの 4 つは値だけが無い（同じキーにほかの値がある） | `控えた:` と 11 行を出した。あった値は `AdvertisingInfo\Enabled: 1 -> 0` の形、無かった値は `User Profile\HttpAcceptLanguageOptOut:  -> 1` の形（左が空）。`New-Item` は無い 2 つのキーにだけ呼び、ほかの値は残った。控えの CSV は 11 行（無かった値は値と種類が空、`PeriodInNanoSeconds` は `QWord`） |
| 同じ手順 2 の 2 回目 | 上の後 | `控えはもうある（書き換えない）` を出し、CSV は変わらない。`->` の左は今の値（`0 -> 0` など） |
| 同じ節の手順 5（戻す） | 上の後。控えのファイルを消した後 | あった 5 つを元の値に（`PeriodInNanoSeconds` は QWORD で）書き、無かった 6 つは消した。値と種類が、流す前とすべて一致した（手順 2 で作った 2 つのキーは、値の無いまま残る）。控えが無いときは `中断: 控えが無い:` で止まった |
| 「表示・入力・音・ストレージを控えて変える」の手順 11（ストレージ センサー） | キーが無い | キーを作り、`01:  -> 1` から `2048:  -> 30` の 7 行（左は空）を出した |
| 同じ「表示・入力・音・ストレージを控えて変える」の手順 11 | `01=0`・`256=1`・`2048=0` と、ほかの値（`StoragePoliciesNotified`）がある | `01: 0 -> 1`・`256: 1 -> 30`・`2048: 0 -> 30` と、左が空の 4 行。`New-Item` は呼ばず、ほかの値は残った |
| 「表示・入力・音・ストレージを元に戻す」の手順 9（戻す） | 上の後。キーが無い | 7 つだけを消し、`StoragePoliciesNotified` は残った。キーが無いときは、何も出さず、誤りも出なかった |
| 「表示・入力・音・ストレージを控えて変える」の手順 9（効果音） | 控えが無い。`.Current` のあるイベントが 4 つ、無いイベントが 1 つ | `reg.exe export HKCU\AppEvents <控え> /y` を 1 回呼び、`Scheme : .None` と `空にしたイベント : 4` を出した。`.Default` の値と、`.Current` の無いイベントは変えなかった |
| 同じ「表示・入力・音・ストレージを控えて変える」の手順 9 の 2 回目 | 控えがある | `控えはもうある（書き換えない）` を出し、`reg.exe export` を呼ばずに同じ 2 行を出した |
| 同じ「表示・入力・音・ストレージを控えて変える」の手順 9 | 控えが無く、`reg.exe export` が失敗する（ファイルができない） | `中断: 控えを作れなかった:` で止まり、スキームとイベントを変えなかった |
| 「表示・入力・音・ストレージを元に戻す」の手順 7（戻す） | 1 回目の控えがある。控えが無い | `reg.exe import <控え>` を 1 回呼び、`Scheme : .Default` を出した（イベントの値と種類も戻った）。控えが無いときは `中断: 控えが無い:` で止まった |
| 「表示・入力・音・ストレージを控えて変える」の手順 2・4 と「表示・入力・音・ストレージを元に戻す」の手順 2（切り替えのキー） | `Hotkey`・`Language Hotkey` が `1`、`Layout Hotkey` が `2`。キーが無い。控えが無い | 「表示・入力・音・ストレージを控えて変える」の手順 2 は `控えた:` と 13 行の表。「表示・入力・音・ストレージを控えて変える」の手順 4 は `1 -> 3`・`1 -> 3`・`2 -> 3`、「表示・入力・音・ストレージを元に戻す」の手順 2 は控えの `1`・`1`・`2` に戻した。キーが無いときは「表示・入力・音・ストレージを控えて変える」の手順 4 がキーを作り、控えが無いときは「表示・入力・音・ストレージを元に戻す」の手順 2 が `控えが無い（既定の値にする）` を出して `1`・`1`・`2` にした |
| 「表示・入力・音・ストレージを控えて変える」の手順 6 と「表示・入力・音・ストレージを元に戻す」の手順 4（ギャラリーとホーム） | ギャラリーのキーが無く、ホームのキーがある | 「表示・入力・音・ストレージを控えて変える」の手順 6 は `既にあった …: False`・`True` を出し、2 つに `System.IsPinnedToNameSpaceTree` の 0 を書いた。「表示・入力・音・ストレージを元に戻す」の手順 4 は、無かったギャラリーをキーごと消し（`残っている …: False`）、あったホームは値だけを消した（`True`） |

- 「表示・入力・音・ストレージを控えて変える」の手順 9 の `Get-ChildItem -Path '…\Apps\*\*'` が、2 段下のキーそのもの（イベント）を返すことは、Linux のファイル システムのプロバイダーで確かめた（レジストリのプロバイダーでは確かめていない）

**残っている未確認事項**:

1. Windows（Windows PowerShell 5.1）で、すべてのブロックを貼って通すこと。5.1 の `Add-Type`（.NET Framework のコンパイラー）で宣言が通り、`SystemParametersInfo` が設定を変えて `WindowMetrics\MinAnimate` に書くこと
1. 本物のレジストリのプロバイダーの動き（`-Type` で既にある値の種類が変わること、値の無いキーの `Get-ItemProperty`、`(default)` の読み書き、`Get-ChildItem` のワイルドカード）と、5.1 の `Export-Csv`・`Import-Csv` での控えの読み書き
1. 本物の `reg.exe` の出力と、`.reg` の書き戻しで効果音の値が種類（`REG_EXPAND_SZ`）まで戻ること
1. `winget`・`copyq.exe`・`Start-Process 'ms-settings:…'`・`control.exe` を呼ぶブロック（Edge と CopyQ の節は、構文と互換だけ）
1. 書いた値が画面と動作に効くこと（それぞれの節の「検証状況の記録」の「確かめていないこと」）

### 付録: PowerToys・PowerShell 7・Windows Terminal・WSL の任意節のブロックの確認（2026-10-08）

「PowerToys のユーティリティを絞る（任意）」「PowerShell 7 のプロファイルを設定する（任意）」「Windows Terminal のフォントと貼り付けの警告を変える（任意）」「WSL のネットワークをミラーにする（任意）」を足したときに、PowerShell のブロックを、Linux（クラウドのコンテナ、Ubuntu 24.04）の PowerShell 7.5.3 と PSScriptAnalyzer 1.25.0 で確かめた。Windows では貼っていない。

**対象のブロック**:

- `origin/main` との差分で、足した `powershell` のブロック 20 個（手順書のブロックは 150 個から 170 個になった。既にあるブロックで変えたものは無い）
  - PowerToys の節の 4 個（その節の手順 2・3・5・8）、PowerShell 7 の節の 6 個（その節の手順 2〜5・7・8）、Windows Terminal の節の 4 個（その節の手順 2〜4・6）、WSL の節の 6 個（その節の手順 2〜7）
- [実施手順](../windows-setup.md#実施手順)の全部（12 項）、[ロールバック](../extra/windows-setup.md#ロールバック)の全部（5 項）、既にある任意節 6 つ（Wake on LAN〜CopyQ）、[更新](../windows-setup.md#更新)は、`origin/main` と 1 行も変わっていない（変えたのは、実施手順とロールバックのリードと、注意点）。手順書のアラートは 5 つのまま

**構文と Windows PowerShell 5.1 との互換**:

- 20 個を、PowerShell 7.5.3 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル `win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework`）を当てた
  - 互換の指摘は 0 個（3 つの規則とも 0）。レジストリに書くブロックが無いので、`Set-ItemProperty -Type` の既知の偽陽性も出ない
  - わざと PowerShell 7 だけの書き方（`??`・`Get-Content -AsByteStream`・`ForEach-Object -Parallel`）を入れたファイルでは、`PSUseCompatibleSyntax` が 1 個、`PSUseCompatibleCommands` が 2 個の指摘を出した
- 既定の規則の指摘は 14 個で、すべて `PSUseBOMForUnicodeEncodedFile`（日本語を含むファイルに BOM が無い。貼るので関係が無い）。日本語を含まない 6 個（PowerShell 7 の節の手順 4・5・8、WSL の節の手順 4・5・7）には指摘が無い

**模擬の仕方**（Linux の pwsh 7.5.3）:

- `%LOCALAPPDATA%`・`%USERPROFILE%`・`HOME`（ドキュメントは `$HOME/Documents`）は一時のディレクトリにし、設定ファイル・控え・プロファイル・`.wslconfig` は、本物のファイルとして読み書きした
- `Get-Process`・`Start-Process`・`Get-ScheduledTask`・`Get-AppxPackage`・`wsl.exe` は、決めた値を返すか、呼ばれたことを覚えるだけの関数にした
- 設定ファイルは Python で作った
  - PowerToys: 1 行の `settings.json`。`enabled` の 30 個と、7 段の入れ子・1 要素と空の配列・空のオブジェクト・`null`・小数・2^53 を超える整数・日本語と `<&>"\/` を含む文字列
  - Windows Terminal: 字下げのある `settings.json`。`profiles.list` の 4 個（1 つは自分の `font` を持つ）、`actions` の入れ子、1 要素と空の配列、`null`、`ms-appx:///…` の URL、`/* … */` と `//` を中身に持つ文字列
- 書いた後は、型まで比べる JSON の差分（Python の `json`）と、ファイルのバイト（SHA-256）で確かめた

**PowerToys の節**:

| 対象 | 流した場合 | 結果 |
|---|---|---|
| 手順 2（変数） | 動いている `PowerToys` の `Path` がある。プロセスが無く、`%LOCALAPPDATA%\PowerToys\PowerToys.exe` と `%LOCALAPPDATA%\Programs\PowerToys\PowerToys.exe` の両方・`Programs` だけ・どちらも無い | プロセスがあればその `Path`、無ければ `%LOCALAPPDATA%\PowerToys` → `Programs\PowerToys` の順に、あるものを取った。どれも無いと `PT_EXE = ` の後ろが空 |
| 手順 3（確かめる） | 設定ファイルが無い。ある。`Measure Tool` が無い | 無いと `中断: 設定ファイルが無い:`。あれば 30 行の表（`$PT_OFF` の 6 個だけ `Off` が `True`）・`startup: True / run_elevated: False`・偽物のタスクの行。`Measure Tool` が無いと、表の後に `無い名前: Measure Tool` |
| 手順 5（書く） | `PowerToys` か `PowerToys.Settings` が動いている、`$PT_EXE` が空、`Measure Tool` が無い、`enabled` が無い、JSON が壊れている | どれも `中断:` で止まり、設定ファイルを変えず、控えを作らなかった（無い名前・`enabled` が無い・壊れているときは、`Start-Process` も呼ばれなかった） |
| 同じ手順 5 | 1 回目。続けて 2 回目 | 1 回目は `控えた:` と `FindMyMouse: False` の形の 6 行を出し、`Start-Process` を `$PT_EXE` で 1 回呼んだ。控えは流す前とバイトで一致。JSON の差分は `enabled` の 6 個の `true -> false` だけで、入れ子（7 段）・配列・`null`・数・文字列は型まで同じ。2 回目は `控えはもうある（書き換えない）` を出し、控えも設定ファイルも変わらなかった |
| 手順 8（戻す） | 動いている。控えがある。続けてもう 1 回 | 動いていると `中断:` で、控えは残った。控えがあると `FindMyMouse: True` の形の 6 行を出して `Start-Process` を呼び、設定ファイルは流す前とバイトで一致し、控えは消えた。もう 1 回では `中断: 控えが無い:` |
| 手順 5・8 | 先頭に `// コメント` の行を足した、字下げのある設定ファイル | PowerShell 7.5.3 の `ConvertFrom-Json` はコメントを読み飛ばしたので止まらず、書いたファイルからコメントが消えた（JSON の差分は上と同じ 6 個）。手順 8 でバイトまで戻った |

**PowerShell 7 の節**:

| 対象 | 流した場合 | 結果 |
|---|---|---|
| 手順 2（足す） | プロファイルも `Documents\PowerShell` も無い。続けてもう 1 回 | フォルダーとファイルを作り、`足した:` の 5 行と中身（5 行）を出した。2 回目は `すでにある:` の 5 行で、ファイルはバイトまで変わらない |
| 同じ手順 2 | 末尾に改行の無い 2 行（間は CRLF）。BOM 付きの UTF-8 で、日本語の行と、5 行のうち 2 行がある（CRLF） | 前者は改行（CRLF）を足してから 5 行を足し、元の 2 行はそのまま（7 行）。後者は 2 行が `すでにある:`、3 行が `足した:` で、元のバイト（BOM を含む）は先頭にそのまま残った。Linux の `Add-Content` が足した行の区切りは LF だった |
| 手順 3（Tab） | プロファイルが無い。手順 2 の後に 2 回 | 無いと `中断: プロファイルが無い。この節の手順 2 を先に貼る:`。手順 2 の後は `足した:`、2 回目は `すでにある:` で変わらない |
| 手順 7（消す） | 手順 2・3 で書いた 6 行だけ。BOM 付きの UTF-8 で印の行だけ。BOM 付きの UTF-16LE で印の行だけ | どれも `消した:` で、ファイルが消えた |
| 同じ手順 7 | BOM 付きの UTF-8（日本語の行・印の行・ほかの行・末尾に改行の無い印の行、CRLF）。BOM 付きの UTF-16LE（日本語の行・印の行・ほかの行）。LF だけのファイル（ほかの 4 行と印の 2 行） | どれも `その行だけ消した:` で、印の行だけが消え、残りは BOM と UTF-16LE を含めてバイトまで期待どおり |
| 同じ手順 7 | 印の前の空白が 1 つの行・印が行末に無い行・PowerToys の Command Not Found の 2 行だけ。プロファイルが無い | 前者は `その行は無い:` で、ファイルは変わらない。無いと `プロファイルが無い:` |

- 手順 2・3 で書いたプロファイルを、PowerShell 7.5.3（PSReadLine 2.3.6）で読んだ。Linux の `$PROFILE` は `~/.config/powershell/…` なので、そこにドキュメントのプロファイルへのシンボリック リンクを置き、`pwsh.exe` は Linux の pwsh へのリンクにした
  - 手順 4 のブロックは、キーの表で `Ctrl+Enter` が `AddLine`、`UpArrow` が `HistorySearchBackward`、`DownArrow` が `HistorySearchForward`、`Tab` が `MenuComplete` を出した。実行ポリシーの表は、Linux なのですべて `Unrestricted` だった
  - 手順 5・8 の `Set-ExecutionPolicy` は、`Operation is not supported on this platform.` で流せなかった
  - starship 1.26.0 と zoxide 0.10.0 の Linux 版を `PATH` に置くと、プロファイルを読んでも誤りは 0 で、`__zoxide_hook`・`Invoke-Starship-PreCommand`・`z` があり、`prompt` は starship のものになった。新しいディレクトリに移って `prompt` を呼ぶと、そのディレクトリが zoxide に記録された
  - 比べるために、starship の行から `Invoke-Starship-PreCommand` の定義を除いた形で同じことをすると、`__zoxide_hook` はあるが、zoxide には何も記録されなかった
  - 2 つを `PATH` から外すと、プロファイルは誤り無しで読まれ、`__zoxide_hook`・`Invoke-Starship-PreCommand`・`z` は無く、`prompt` は starship のものではなかった

**Windows Terminal の節**:

| 対象 | 流した場合 | 結果 |
|---|---|---|
| 手順 2（控える） | 設定ファイルが無い。`//` の行のコメント・`/* */` のコメント・末尾のカンマがある。`profiles` が配列 | どれも `中断:` で止まり、控えを作らなかった。続けて手順 3 を貼ると `中断: 控えが無い。この節の手順 2 を先に貼る` |
| 同じ手順 2 | 上の字下げの設定ファイル（文字列の中に `//`・`/*`・`ms-appx:///` がある）。続けてもう 1 回 | 止まらずに `控えた:` と、`Version : 1.25.2733.0`（偽物の `Get-AppxPackage`）などの 5 行と、自分のフォントを持つ `AlmaLinux-10` の表を出した。控えはバイトで一致し、設定ファイルは変わらない。2 回目は `控えはもうある（書き換えない）` |
| 手順 3・4 | 控えがあり、設定ファイルに `//` のコメントがある | どちらも `中断: コメントか末尾のカンマがある:` で、変えなかった |
| 手順 3（フォント） | `profiles.defaults` が空・無い・`font.size` と `font.weight` と `colorScheme` がある。続けてもう 1 回 | `face: HackGen Console NF`。JSON の差分は `profiles.defaults.font.face` を足したこと（無いときは `defaults`・`font` ごと）だけで、`size` などは残り、入れ子（5 段）・空と 1 要素の配列・`null` は型まで同じ。2 回目はバイトまで変わらない |
| 手順 4（警告） | 版が 1.23.12811.0・パッケージが無い・1.25.2733.0。`warning.multiLinePaste` が `true` | 1.23 とパッケージが無いときは `中断: Windows Terminal の版が 1.24 より前:` で、変えなかった。1.25 では `warning.multiLinePaste: never` で、差分はその値だけ（`true` は文字列の `never` に変わった） |
| 手順 6（戻す） | 手順 2〜4 の後（設定ファイル 4 種）。続けてもう 1 回 | `face:  / warning.multiLinePaste: `（`true` だったものは `True`）を出し、流す前とバイトで一致し、控えが消えた。もう 1 回では `中断: 控えが無い:` |

**WSL の節**:

| 対象 | 流した場合 | 結果 |
|---|---|---|
| 手順 2（確かめる） | `.wslconfig` が無い | `無い:` と、偽物の `wsl.exe` の 2 行。`$env:WSL_UTF8` はブロックの後も `1` のまま残った |
| 手順 3（書く） | ファイルが無い。続けてもう 1 回 | `作った:` で、中身は `[wsl2]`・`networkingMode=mirrored` の 2 行（CRLF）。控えは作らない。2 回目は `中断: networkingMode の行がもうある` |
| 同じ手順 3 | `[wsl2]` とほかの 2 つの値（CRLF）。`# comment`・`[WSL2]  `（大文字、後ろに空白）・ほかの値（LF だけ）。`[experimental]` だけで、末尾に改行が無い。BOM 付きの UTF-8 | どれも `控えた:` と `足した:`。`networkingMode=mirrored` は `[wsl2]` の行の直後に、ファイルの改行（CRLF か LF）で入った。`[wsl2]` が無いと、改行を足してから `[wsl2]` と 1 行を末尾に足した。BOM 付きのファイルは、BOM の無い UTF-8 で書いた |
| 同じ手順 3 | `networkingMode=nat`。`  NetworkingMode = NAT`（字下げ・大文字・空白） | どちらも `中断: networkingMode の行がもうある` で、ファイルを変えず、控えを作らなかった |
| 同じ手順 3 | `#networkingMode=nat`（コメントの行）だけ | 止まらずに、`[wsl2]` の直後に足した（コメントの行は残る） |
| 同じ手順 3 | 前の控えが残っていて、ファイルに `networkingMode` が無い | `控えはもうある（書き換えない）` で、控えを残して足した。手順 6 では、前の控えの中身に戻った |
| 手順 6（戻す） | 上のそれぞれの後。手順 3 で作った後に手で 1 行足した。ファイルも控えも無い | 控えがあれば `控えから戻した:` で、控えは消えた（手順 3 で控えたときは、手順 3 の前とバイトで一致した。BOM も）。手順 3 で作ったままなら `消した:` でファイルが消えた。手で足した後は `中断: この節で作った形ではない`。どちらも無いと `無い:` |
| 手順 4・5・7 | `wsl.exe` を、`wslinfo` には `mirrored` を返す関数にした | 書いたとおりの引数で呼ばれた（流れを見ただけで、WSL は動かしていない。関数には `--` が渡らないので、本物の `wsl.exe` への `--` の渡り方は見ていない） |

- Linux の pwsh は `.` で始まるファイルを隠しファイルとして扱い、手順 6 の `-Force` の無い `Remove-Item` が `You do not have sufficient access rights to perform this operation or the item is hidden, system, or read only.` で断った。上の表は、`Remove-Item` に `-Force` を足す関数をかぶせて流した結果

**残っている未確認事項**:

1. Windows（Windows PowerShell 5.1）で、20 個のブロックを貼って通すこと。5.1 の `ConvertFrom-Json`・`ConvertTo-Json -Depth 100` で、PowerToys と Windows Terminal の設定ファイルの入れ子と配列（空・1 要素）が形を保つこと。コメントのある PowerToys の設定ファイルで、5.1 では手順 5 が止まるか（7.5.3 はコメントを読み飛ばして消した）
1. 5.1 の `Add-Content` が PowerShell 7 のプロファイルに足す行の文字コードと改行（Linux の 7.5.3 では LF）。UTF-16LE のプロファイルに足すとき
1. 本物の `Get-Process`・`Start-Process`・`Get-ScheduledTask`・`Get-AppxPackage` の値と動き。WSL の節の手順 6 の `-Force` の無い `Remove-Item` が、Windows の `.wslconfig` を消せること
1. `wsl.exe` と、5.1 から `pwsh.exe -Command { … }` を呼ぶブロック（PowerShell 7 の実行ポリシーの手順 5・8 を含む）。Windows 版の starship・zoxide と、対話の窓でのキーとプロンプト
1. 書いた値が PowerToys・Windows Terminal・WSL に効くこと（それぞれの節の「検証状況の記録」の「確かめていないこと」）

### 付録: シェルのツールの任意節のブロックの確認（2026-10-08）

「シェルのツールを入れる（任意）」を足したときに、上流と scoop の資料・配布物を調べ、PowerShell のブロックを、Linux（クラウドのコンテナ）の PowerShell 7.5.3 と PSScriptAnalyzer 1.25.0 で確かめた。**Windows の実機では未検証**（どのブロックも、Windows では貼っていない）。

**上流の zoxide**（2026-10-08 05:11 UTC に確かめた）:

- 06:22 UTC と 06:40 UTC にも `git ls-remote --tags` を見直した。タグの最新は `v0.10.0` のまま、`main` も `86b443c` のままだった。06:40 UTC の scoop の main の `bucket/zoxide.json` も `0.10.0`
- `git ls-remote --tags` のタグの最新は `v0.10.0`。`main` は `86b443c`（`git describe` は `v0.10.0-22-g86b443c`）
- `1f484a4`「Fix MSYS2 cygpath pwd substitution (#1260)」（2026-07-07）は `main` にあり、`git tag --contains` は何も出さなかった
- `main` の `CHANGELOG.md` の `[Unreleased]` の Fixed に「Bash/Zsh: fix `z` failing on Cygwin/MSYS2 due to `cygpath` being passed a bad string.」がある
- `templates/bash.txt` の、Windows のときの `__zoxide_pwd`
  - v0.9.9: `\command cygpath -w "$(\builtin pwd -P)"`
  - v0.10.0: `\command cygpath -w "{{ pwd }}"`（`pwd` は `\builtin pwd -L` などの文字列で、コマンド置換が無い）
  - `main`: `\command cygpath -w "$({{ pwd }})"`
- `src/db/mod.rs` の `VERSION` は、v0.9.9 と v0.10.0 のどちらも 3（`db.zo`）。`main` の `c479cc8`（#1288、2026-10-03）は `db.txt` に変え、`db.txt` が無くて `db.zo` があれば、それを読んで移す
- GitHub の API（`releases/latest`）は、この環境の `gh` からは使えなかった（リポジトリへのアクセスが無い旨の 403）。版になったかは、タグと `main` で判断した

**scoop の定義**（ScoopInstaller/Main の `master`。2026-10-08 に取得）:

| 定義 | 版 | 書いてあること |
|---|---|---|
| `fzf.json` | 0.74.4 | `bin` は `fzf.exe` |
| `zoxide.json` | 0.10.0 | `bin` は `zoxide.exe`。`notes` は `_ZO_DATA_DIR is located at '$env:LOCALAPPDATA\zoxide' by default` |
| `starship.json` | 1.26.0 | `bin` は無く、`env_add_path` が `.`。`suggest` は `extras/vcredist2022`。`notes` は `$PROFILE` に `Invoke-Expression (&starship init powershell)` を足す案内と、Powerline のフォント |
| `eza.json` | 0.23.5 | `bin` は `eza.exe` と、`exa` の名前の `eza.exe`。64bit（`x86_64-pc-windows-gnu`）だけ |
| `bat.json` | 0.26.1 | `env_set` は `BAT_CONFIG_DIR` に `$dir`。`persist` は `config`・`syntaxes`・`themes`。`pre_install` は、控えに `config` が無ければ `%APPDATA%\bat\config` を写し、空のファイルを作る。`suggest` は `extras/vcredist2022` と `less` |

- `bucket/zoxide.json` の履歴: `f8683b6ce`（2026-07-04、0.10.0 に）、`73b1eafab`（2026-01-31、0.9.9 に）
- Scoop と同じ探し方（`git log --follow -n 1 --format=%H -G 'version.: .0\.9\.9' -- bucket/zoxide.json`）は `f8683b6ce` を出した。その親（`f8683b6ce^`）の定義が 0.9.9 で、64bit の hash は `5af00d0916f0…`、arm64 は `58c55ef6f0ea…`

**配布物**（上の定義の x64 の zip を落とし、Linux の `sha256sum` と `objdump -p` で見た）:

| zip | sha256 | 実行ファイルが読み込む DLL |
|---|---|---|
| `fzf-0.74.4-windows_amd64.zip` | 定義と一致 | `kernel32.dll` だけ |
| `zoxide-0.9.9-x86_64-pc-windows-msvc.zip` | 履歴の定義と一致 | `KERNEL32.dll`・`ntdll.dll`・`ole32.dll`・`shell32.dll`・`api-ms-win-core-synch-l1-2-0.dll` |
| `zoxide-0.10.0-x86_64-pc-windows-msvc.zip` | 定義と一致 | `KERNEL32.dll`・`ntdll.dll`・`combase.dll`・`shell32.dll`・`userenv.dll`・`api-ms-win-core-synch-l1-2-0.dll` |
| `starship-x86_64-pc-windows-msvc.zip`（1.26.0） | 定義と一致 | `KERNEL32.dll`・`ADVAPI32.dll`・`user32.dll`・`setupapi.dll` などで、`VCRUNTIME140.dll` は無い |
| `eza.exe_x86_64-pc-windows-gnu.zip`（0.23.5） | 定義と一致 | `msvcrt.dll`・`KERNEL32.dll`・`advapi32.dll` などで、`VCRUNTIME140.dll` は無い |
| `bat-v0.26.1-x86_64-pc-windows-msvc.zip` | 定義と一致 | `VCRUNTIME140.dll` と、`api-ms-win-crt-*`（UCRT）・`kernel32.dll` など |

- 0.9.9 の `zoxide.exe` の文字列に `\command cygpath -w "$(\builtin pwd -P)"` がある。0.10.0 の `zoxide.exe` では `\command cygpath -w "` で切れている（テンプレートの `{{ pwd }}` の前）
- `eza.exe` の文字列に `v0.23.5 [+git]` がある

**Scoop のソース**（ScoopInstaller/Scoop の `v0.6.0`、2026-09-30。ここは読んだだけ。`install` の分かれは、後の「Scoop v0.6.0 を動かした確認」で動かした）:

- `scoop install <名前>@<版>`: `generate_user_manifest` が `INFO  Resolving historical manifest for '<名前>' (<版>)` を出し、SQLite のキャッシュ（設定したときだけ）→ バケットの git の履歴（`Find-HistoricalManifestInGit`。見つけたコミットの親とそのコミットの定義の版を比べる）→ `autoupdate` の順に定義を探す。履歴の定義は `~\scoop\workspace\<名前>.json` に書く
- 版を指定したものは `~\scoop\workspace\<名前>.json` の場所になり、`prune_installed`（`installed` は `<名前>.json` の名前で探す）は入っているとみなさない。ほかの版が入っていても、並べて入れて `current` を付け替える
- 版を指定した同じ版がもう入っていると、`'<名前>' (<版>) is already installed.` の警告の後の `continue`（`ForEach-Object` の中で、囲むループが無い）が `bin/scoop.ps1` の `switch` まで抜け、同じ行のほかの名前を入れずに終わる
- 版を指定しない名前を並べたときは、入っているものを `prune_installed` で飛ばす。`'<名前>' (<版>) is already installed. Skipping.` の警告は、`Get-Dependency` が名前を `main/<名前>` の形に変えるので、指定した名前との突き合わせに当たらず出ない
- 名前を 1 つだけ渡したときは、もう入っていれば `'<名前>' (<版>) is already installed.` と `Use 'scoop update <名前>' to install a new version.` の警告を出して終わる
- バケットの履歴を探すのは、main が git のリポジトリのときだけ（`Find-HistoricalManifestInGit`）。そうでなければ `WARN  Bucket 'main' is not a git repository. Cannot search historical versions.` を出して `autoupdate` に移る。git の形に直すのは `scoop update` の `Sync-Bucket`（`Converting 'main' bucket to git repo...`）。ScoopInstaller/Install の `install.ps1` は、git が無ければ main を zip で置く
- `env_add_path` は `Add-Path` で、ユーザーの `Path` と今のセッションの `$env:PATH` に足し、`Adding <場所> to your path.` を出す。`env_set` は `Setting user environment variable: <名前> = <値>` を出し、今のセッションにも入れる
- `scoop hold`: `<名前> is now held and can not be updated anymore.`。すでに止めてあれば `'<名前>' is already held.`。`scoop unhold`: `<名前> is no longer held and can be updated again.`
- `scoop update`: 止めたものは、古くても `'<名前>' is held to version <版>` の警告で飛ばす。版を指定して入れたものは、`--force` のときだけバケットの今の定義で入れ直す（#6730）。名前を渡したときは、前の更新から 3 時間たっていなければバケットを新しくしない（`is_scoop_outdated`）
- `scoop list`: `Source` は、`bucket` が無く `url` が `workspace` の定義なら `<auto-generated>`。`Info` は、`hold` があれば `Held package`
- `scoop update zoxide --force`（版を指定して入れたもの）: `update` の `$pin_broken` から `Find-AppBucket` で、main のバケットの今の定義を入れる（Releases は見ない）
- `scoop uninstall`: `hold` を見ない。動いているプロセスがあれば、`The following instances of "<名前>" are still running. Close them and try again.` で止まる

**Scoop v0.6.0 を動かした確認**（`v0.6.0` の `bin/scoop.ps1` と `lib`。Linux の pwsh 7.5.3）:

- `SCOOP`・`XDG_CONFIG_HOME`・`USERPROFILE` を一時のフォルダーにし、`apps\<名前>\<版>` に `manifest.json` と `install.json`（`bucket` は `main`）を置いて、入っている形にした。main のバケットの定義の `url` は使えない場所にし、ダウンロードは失敗させた
- 設定ファイルの場所が Linux では読めず、どの場合も `Updating Scoop...` が動いて失敗した。下の結果は、その後の行

| 入っているもの | 渡した引数 | 結果 |
|---|---|---|
| zoxide 0.9.9 | `install fzf zoxide@0.9.9 starship` | `WARN  'zoxide' (0.9.9) is already installed.` と `Use 'scoop update zoxide' to install a new version.` だけで、`Installing 'fzf'` の行は出なかった |
| zoxide 0.9.9 | `install fzf starship`（比べるため） | `Installing 'fzf' (0.74.4) [64bit] from 'main' bucket` の後、ダウンロードで失敗した |
| zoxide 0.9.9 | `install zoxide@0.9.9` | 1 行目と同じ 2 行の警告 |
| zoxide 0.9.9 | `install zoxide`（名前 1 つ） | 同じ 2 行の警告 |
| fzf と starship | `install fzf starship` | 何も出さなかった。`lib` を読み込んで `Get-Dependency` と `prune_installed` を同じ順に呼ぶと、名前は `main/fzf`・`main/starship` になり、どちらも飛ばす側に入り、`fzf`・`starship` との突き合わせ（警告を出す側）は空だった |
| zoxide 0.10.0（main は git でない） | `install zoxide@0.9.9` | `INFO  Resolving historical manifest for 'zoxide' (0.9.9)`・`WARN  Bucket 'main' is not a git repository. Cannot search historical versions.`・`WARN  No historical manifest found for 'zoxide@0.9.9'; attempting autoupdate` の後、ダウンロードで失敗して `Could not install: zoxide@0.9.9` |

- zoxide 0.10.0 が入った形で `lib` を読み込むと、`installed '<SCOOP>\workspace\zoxide.json'` は `False`、`installed zoxide` は `True`、`prune_installed` に workspace の場所と `fzf` を渡すと、どちらも入れる側に入った
- `switch` → スクリプト → `ForEach-Object { …; continue }` の形だけの小さな模型でも、`continue` の後ろ（同じスクリプトの残り）は動かず、`switch` の後ろから続いた

**bat の設定ファイル**（Linux の bat 0.26.1。`bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz`）:

- `BAT_CONFIG_DIR` のフォルダーに、CRLF の 3 行（`--theme="ansi"`・`--style="numbers,changes,header"`・`--paging=never`）の `config` を置くと、`--decorations=always --color=never` で、行番号と見出しだけ（格子の線が無い）の表示になった。空の `config` では、格子の線のある既定の表示
- 同じ 3 行の先頭に BOM（`EF BB BF`）を付けると、`[bat error]: '<BOM>--theme=ansi': No such file or directory (os error 2)` の形のエラーで、終了コードが 1 になった

**構文と Windows PowerShell 5.1 との互換**（最後の確認。手順書の今のブロックを取り出し直して通した）:

- `claude/win11-postinstall-2-tools` との差分で足した `powershell` のブロックは、この節の 10 個（この節の手順 2〜5・10〜13 と、手順 6 の 2 個）と、git-delta.md の 6 個・gh.md の 10 個の 26 個。手順書のブロックは 170 個から 180 個になり、既にあるブロックで変えたものは無い（変えたのは、リードの「手順の後に、この順に通す手順書」〔git-delta・GitHub CLI の入れ子の箇条書き〕と「手順の後の節」、`## 更新` と `## ロールバック` のリードだけ。手順書のアラートは 5 つのまま）
- 26 個を PowerShell 7.5.3 の構文解析器に通した（構文の誤り 0）。この節の 10 個は、手順 4・6・10 を直した後にも通している（そのときも誤り 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows PowerShell 5.1 のプロファイル 3 つ。Windows Server 2016 Datacenter の `win-8_x64_10.0.14393.0_…`、Windows Server 2019 Datacenter の `win-8_x64_10.0.17763.0_…`、Windows 10 Pro の `win-48_x64_10.0.17763.0_…`）・`PSUseCompatibleCmdlets`（`desktop-5.1.14393.206-windows`）を当てた。互換の指摘は、4 つの規則とも 0 個
  - わざと PowerShell 7 だけの書き方（`??`・`Get-Content -AsByteStream`・`ForEach-Object -Parallel`）を入れたファイルでは、`PSUseCompatibleSyntax` が 1 個、`PSUseCompatibleCommands` が 6 個（プロファイルごとに 2 個）の指摘を出した。`}` の足りないファイルは、構文の誤り 1 個
- 既定の規則の指摘は 5 個で、どれもこの節のブロック。4 個は `PSUseBOMForUnicodeEncodedFile`（日本語を含む、手順 6 の 2 個と手順 10・12。貼るので関係が無い）、1 個は手順 6 の変数だけのブロックの `PSUseDeclaredVarsMoreThanAssignments`（変数は、手順 6 のもう 1 つのブロックで使う）。git-delta.md と gh.md のブロックには指摘が無い

**模擬**（Linux の pwsh 7.5.3。手順 4・6・10 を直した後に全部を流し直し、最後に手順書から取り出し直したブロックでもう一度流した。表は最後の結果で、前の回と違ったのは `Scoop` の行と、足した 2 つの場合だけ）:

- `%USERPROFILE%`・`%LOCALAPPDATA%`・`%APPDATA%`・`%WINDIR%` を一時のフォルダーにした。`scoop` は、渡った引数を覚えて shim のファイルを作る・消す関数（最後の回は、shims に置いた `scoop.ps1` からその関数を呼んだ）、fzf・zoxide・starship・eza は版の行を出すだけのスクリプト、bat は本物の Linux 版 0.26.1 にした。管理者の判定（`WindowsPrincipal`。Linux では使えない）は `$false` に置き換えた
- 偽物の `scoop install` の bat は、scoop の `pre_install` と `persist` のように、控えの空の `config` を作って `current\config` からハードリンクし、`BAT_CONFIG_DIR` を入れた（`current` はシンボリック リンク）
- 偽物の `scoop install` は、上の「Scoop v0.6.0 を動かした確認」の分かれをまねた（版を指定した同じ版で、その回を終える。名前を並べたときは、入っているものを何も出さずに飛ばす。名前 1 つで入っていれば、2 行の警告）。`hold` は止めた状態を覚え、`update zoxide` はバケットの `zoxide.json` の版を入れる

| 対象 | 流した場合 | 結果 |
|---|---|---|
| 手順 2 | 何も無い（VC++ ランタイムの DLL と共通の bash 設定も無い） | `Admin : False`・`BashConfig : False`・`VCRuntime : False`。`Tools`・`Zoxide` は空。`Scoop` は偽物の `shims/scoop.ps1`（前の回は関数だけで、`Scoop` は空だった） |
| 同じ手順 2 | 偽物の zoxide 0.10.0 の shim・DLL・`bashrc` がある | `BashConfig : True`・`VCRuntime : True`、`Tools` は shim の zoxide だけ、`Zoxide : zoxide 0.10.0` |
| 同じ手順 2 | 続けて、偽物の fzf を winget の `Microsoft\WinGet\Links` に置き、PATH の後ろに足した（最後の回だけ） | `Tools` に、その `Links` の `fzf` と、shim の zoxide が並んだ |
| 手順 3・4 | 続けて | `scoop` に `uninstall zoxide`・`update`・`install fzf starship eza bat`・`install zoxide@0.9.9`・`hold zoxide` が渡った。4 つの導入の行・`Resolving historical manifest`・`zoxide is now held` |
| 手順 2 | 手順 4 の後 | `Tools` は、4 つの shim と `apps/starship/current/starship` の 5 つ。`Zoxide : zoxide 0.9.9` |
| 同じ手順 4 | 続けてもう 1 回 | 2 行目は何も出さず、3 行目は `'zoxide' (0.9.9) is already installed.` の 2 行の警告、4 行目は `'zoxide' is already held.` |
| 手順 5 | 手順 4 の後 | 5 つの版の行と、5 つの場所と、偽物の `scoop list` の表（`<auto-generated>`・`Held package`） |
| 手順 2・4・5 | main の zoxide 0.9.9 だけがあり、ほかの 4 つと bat の環境変数は無い（手順 3 を飛ばす分かれ） | 手順 2 は `Zoxide : zoxide 0.9.9`。手順 4 は 4 つを入れ、3 行目は警告だけで、4 行目で止めた。手順 5 は 5 つの版と場所と、`main`・`Held package` の行 |
| 手順 6 | 控えの `config` が空 | 変数のブロックは何も出さない。`書いた:` と 3 行。ファイルは ASCII だけ（0x7E より大きいバイトが 0 個で、BOM も無い）。控えと `current\config` は同じ i ノードで、同じ中身。本物の bat の `--config-file` も同じ場所を出し、行番号と見出しだけの表示になった |
| 同じ手順 6 | 続けてもう 1 回 | `中身がある（書き換えない）:` で、変えなかった |
| 同じ手順 6 | `$BAT_THEME_NAME` が空 | `中断: BAT_THEME_NAME が空のまま。値を入れて貼り直す` |
| 同じ手順 6 | `config` が空白と改行だけ。テーマは `Monokai Extended` | `書いた:` と、`--theme="Monokai Extended"` で始まる 3 行。本物の bat が読んだ |
| 同じ手順 6 | `BAT_CONFIG_PATH` も `BAT_CONFIG_DIR` も無い | `中断: BAT_CONFIG_DIR が無い。この節の手順 4 で bat を入れたかを確かめる`。`%APPDATA%\bat\config` は作らなかった |
| 同じ手順 6 | `BAT_CONFIG_PATH` を別のフォルダーの `config`（まだ無い）にした | `書いた:` とその場所と 3 行。本物の bat の `--config-file` も同じ場所を出した |
| 手順 12 | 控えの中身が、CRLF の 3 行・LF の 3 行（テーマに空白）・4 行目がある・`--style` を変えた・空 | CRLF と LF は `空にした:` で、控えと `current\config` がどちらも 0 バイトになった。4 行目があるときと `--style` を変えたときは `この節で書いた形ではない（変えない）:` で、変えなかった。空は `もう空:` |
| 同じ手順 12 | 手順 11 の後（bat を消し、控えだけが残る）に、控えに CRLF の 3 行を書いた（最後の回だけ） | `空にした:` で、控えが 0 バイトになった |
| 同じ手順 12 | 控えが無い | `無い:` |
| 手順 10 | バケットの `zoxide.json` の版が `0.10.0` | `Scoop was updated successfully!` の後に `中断: scoop の main のバケットの zoxide はまだ 0.10.0。日を置いて、この節の手順 9 から`。zoxide は 0.9.9 で止めたまま |
| 同じ手順 10 | 版が `nightly`・`zoxide.json` が無い | どちらも `中断:`（無いときは `Get-Content` のエラーの後）。zoxide は 0.9.9 で止めたまま |
| 同じ手順 10 | 版が `0.10.1` | `scoop` に `unhold zoxide`・`update zoxide --force` が渡り、最後に `zoxide 0.10.1`。止めていない状態になった |
| 手順 11 | 手順 10 の後 | `scoop` に `uninstall fzf zoxide starship eza bat` が渡った。後の 2 つのコマンドは何も出さなかった（Linux では、ユーザーの環境変数はいつも空） |
| 手順 13 | `%LOCALAPPDATA%\zoxide\db.zo` がある。続けてもう 1 回 | どちらも `False` |

- Linux の pwsh では、`Join-Path`・`Test-Path`・`Remove-Item` は `\` を区切りとして扱ったので、ブロックの `\` を直さずに流せた
- Linux の 7.5.3 の `Set-Content` が書いた行の区切りは LF だった。手順 12 の CRLF の場合は、`[IO.File]::WriteAllText` で作った

**残っている未確認事項**:

1. Windows（Windows PowerShell 5.1）で、10 個のブロックを貼って通すこと。本物の scoop の表示（版の指定・`hold`・`list`・`unhold`・`update --force`・`uninstall`）
1. 5.1 の `Set-Content -Encoding ASCII` と `[IO.File]::WriteAllText` が、NTFS のハードリンクの控えにも同じ中身を書くこと
1. WezTerm の新しいタブが、起動し直さずに starship の `Path` と `BAT_CONFIG_DIR` を読むこと
1. Git Bash での確かめ（この節の手順 7・8）のすべて
1. 直った zoxide の版への上げ方（まだ出ていない）
1. main のバケットを zip で置いた PC で、この節の手順 4 の `scoop update` が git の形に直してから、0.9.9 を履歴から取ること

### 操作上の注意と併記されていた記録

   - **注意**: この後は Hyper-V が動くので、[VirtualBox](../virtualbox.md#windows-11-で使う) の VM は Hyper-V の上で動く（遅くなり、[virtualbox-guest-bootc.md](../virtualbox-guest-bootc.md) の検証では VM が数分ずつ止まった）


### 操作上の注意と併記されていた記録

   - Microsoft アカウントのときの `Username` と `Domain` の入れ方は確かめていない（この手順の補足）


### 実施手順 / 表示と入力 / 手順 2: 補足: この設定の仕組み

- Windows 11 のエクスプローラーは、右クリックで新しい形のメニューを出し、その中の「その他のオプションを確認」（Shift+F10 か Shift+右クリックでも）で旧形式のメニューを出す
- 新しい形のメニューは、CLSID `{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}` の COM のクラスが出している。自分のユーザーの `HKCU\Software\Classes\CLSID` に同じ CLSID の `InprocServer32` を空の既定の値で置くと、そのクラスを読めなくなり、エクスプローラーは最初から旧形式のメニューを出す
- Microsoft が説明している設定ではない（サポート外）。広く使われている方法で、25H2 でも効くという記事が複数ある（本書では確かめていない）
- 自分のユーザーだけにかかり、管理者の権限は要らない。消せば元に戻る（[ロールバックの「表示と入力を戻す」](../extra/windows-setup.md#表示と入力を戻す)の手順 2）
- PowerShell の `New-Item -Force` で作らず `reg.exe` を使うのは、`New-Item -Force` が既にあるキーを作り直して中の値を消すため。`reg.exe add /f /ve` は既定の値だけを書く



### 実施手順 / 表示と入力 / 手順 4: 補足: 値の意味とウィジェットのボタン

- `TaskbarAl`: 0 で左、1（か値が無い）で中央
- `ShowTaskViewButton`: 0 でタスク ビューのボタンを消す
- `ShowSecondsInSystemClock`: 1 で時計に秒を出す（22H2 の 2023 年 5 月の更新から。設定の「個人用設定」→「タスク バー」→「タスク バーの動作」の「システム トレイの時計に秒を表示する」）
- `SearchboxTaskbarMode`（`Explorer\Advanced` ではなく `Search` の下）: 0 で消す、1 でアイコンだけ、2 で検索ボックス、3 でアイコンとラベル。スタートを開いて文字を打てば、検索はそのまま使える
- 4 つとも、Microsoft の DSC のリソース（`Microsoft.Windows.Developer` の `Taskbar`）が同じ値を書く。同じリソースはこの 4 つでエクスプローラーを起動し直さないので、タスクバーはすぐに読み直すはず（確かめていない）
- ウィジェットのボタンの値（`TaskbarDa`）は、24H2 から UCPD（ユーザーの選択を守るドライバー）が守っていて、PowerShell・`reg.exe` からは書けない（「アクセスが拒否されました」になると広く報告されている）。設定の画面（「個人用設定」→「タスク バー」→「ウィジェット」）からは切れる。本書は、「自動起動と標準アプリ」の手順 3 でウィジェットそのものを外す



### 実施手順 / 表示と入力 / 手順 7: 補足: レジストリに書かない理由と、Ctrl+Space の取り合い

- この設定のレジストリの値は、Microsoft の文書に無い。ある開発者が設定の画面の前後で見比べた記録（`HKCU\Software\Microsoft\IME\15.0\IMEJP\MSIME` の `IsKeyAssignmentEnabled` を 1、`KeyAssignmentCtrlSpace` を 2）はあるが、同じ人が「動いている IME に効く時期が保証されない」として書くのを避けている。本書も画面で変える
- 割り当てられるキーは、無変換・変換・Ctrl+Space・Shift+Space。Ctrl+Space には、最初は何も割り当てられていない
- Windows が Ctrl+Space を使うのは、中国語の IME のオン・オフだけ（Microsoft のキーボード ショートカットの文書）。日本語だけの PC では、Windows の操作とはぶつからない
- IME が Ctrl+Space を取るので、アプリの Ctrl+Space は効かなくなるはず（PowerShell の PSReadLine の `MenuComplete`、VS Code の候補の表示、Excel の列の選択など。確かめていない）
- 英数と日本語の切り替えの既定の Win+Space（入力言語の切り替え）と、半角/全角のキーはそのまま使える



### 実施手順 / ネットワークとリモート / 手順 2: 補足: 有効にする値と、規則を絞ること

- `fDenyTSConnections` を 0 にすると、リモート デスクトップの接続を受け付ける（1 が既定で、受け付けない）。`UserAuthentication` を 1 にすると、ネットワーク レベル認証（NLA）を求める（設定の画面で有効にしたときの既定）。どちらも Microsoft の文書（Azure の VM のリモート デスクトップの切り分け）にある値
- 受信の規則は、表示の名前が日本語に訳されるので、Microsoft の勧める形（`@FirewallAPI.dll,-28752` のグループ）で指定する。規則の名前は `RemoteDesktop-UserMode-In-TCP`・`-UDP` など（3389 番）
- `-Profile Private` で、プライベートの LAN（「ネットワークとリモート」の手順 1）からだけ受け付ける。持ち出した先のパブリックの Wi-Fi では開かない。[Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)の検証の PC は、規則がすべてのプロファイルで有効だった
- 設定の画面でリモート デスクトップをオンとオフにし直すと、規則のプロファイルが戻るかは確かめていない。画面で変えたら、この手順の最後の行で確かめ直す
- 元に戻すのは[ロールバックの「ネットワークと PC 全体の設定を戻す」](../extra/windows-setup.md#ネットワークと-pc-全体の設定を戻す)の手順 4



### 実施手順 / サインイン・検索・キーボード / 手順 3: 補足: 場所とポリシー

- Edge のショートカットは、すべてのユーザーのデスクトップ（`C:\Users\Public\Desktop`）にある。ここは管理者でないと消せない。名前は `Microsoft Edge.lnk`（製品の名前なので訳されないはず。確かめていない）
- UniGet UI のショートカットは、「アプリを入れる」の手順 3 で入れたときに自分のデスクトップにできる（インストーラの定義の `{autodesktop}\UniGetUI`）。OneDrive でデスクトップをバックアップしていると場所が変わるので、`GetFolderPath('Desktop')` で探す
- Edge のショートカットは、Edge の更新で作り直されることがある。Edge Update のポリシー `RemoveDesktopShortcutDefault` を 1 にすると、Edge の更新や再起動のときに、すべてのユーザーのデスクトップの Edge のショートカットを消す（Microsoft の文書。Edge Update 1.3.155.1 から）。`CreateDesktopShortcutDefault` は、Edge が入っていると効かない（同じ文書）
- 元に戻すのは[ロールバックの「サインイン・検索・キーボードを戻す」](../extra/windows-setup.md#サインイン検索キーボードを戻す)の手順 7（ポリシーだけ。消したショートカットは戻らない）



### 実施手順 / 再起動の後に確かめる / 手順 4: 補足: UniGet UI と scoop

- UniGet UI は、`PATH` から `scoop.ps1` を探して scoop を見つける。PowerShell 7（`pwsh.exe`）があればそれで、無ければ Windows PowerShell 5.1 で、`-ExecutionPolicy Bypass` を付けて動かす（ソースの `Scoop.cs`）
- UniGet UI は、scoop の更新に git が要るとして、無ければ `scoop install main/git` を勧める（同じソース）。本書は git を Git for Windows にそろえるので、勧めに従わない（[選択した方針](../verification/windows-setup.md#選択した方針)）
- UniGet UI は、「アプリを入れる」の手順 3 で入れたときに、サインインのときに起動する設定（`Run` の `WingetUI`）も作る。「自動起動と標準アプリ」の手順 1 では止めていない
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
| PowerToys の Keyboard Manager | 再起動が要らず、ユーザーごと。PowerToys が動いている間だけ効き、サインインの画面では効かず、管理者の窓には PowerToys を管理者で動かさないと効かない（Microsoft の文書） | 不採用（PowerToys は「アプリを入れる」の手順 4 で入れるが、Caps Lock には使わない） |
| Sysinternals の Ctrl2Cap | キーボードのフィルター ドライバーを入れる | 不採用（ドライバーを足さずに済む方法がある） |

**旧形式のコンテキストメニュー**

| 経路 | 状況 | 採否 |
|---|---|---|
| **`HKCU\Software\Classes\CLSID\{86ca1aa0-…}\InprocServer32` を空にする** | 自分のユーザーだけ、管理者は要らない。サポート外 | **採用** |
| 何もしない（「その他のオプションを確認」か Shift+右クリック） | 毎回 1 手間かかる | 不採用 |

**貼り付けの設定（「貼り付けの設定」の手順 1〜4）**

**LAN をプライベートに（「ネットワークとリモート」の手順 1）**

- もとは [Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)の手順 5 と、[Syncthing の Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 7 の両方で、同じ操作をしていた。インストール直後に 1 度行うものなので、ここへまとめ、2 つの手順書は確かめるだけにした
- 規則をパブリックにも広げる方法は採らない。持ち出した先でも、同じサブネットの相手に開くため（OpenSSH サーバーの[選択した方針](#openssh-サーバー-選択した方針)）

**表示・整理の設定（「表示と入力」と「自動起動と標準アプリ」）**

- **レジストリに書けるものは書き、書けないもの・Microsoft の文書が無く効く時期が読めないものは画面で行う**
  - エクスプローラー・スタート・タスクバー・ダークモード・既定の端末・自動で起動するアプリは、自分のユーザーのレジストリに書く。多くは Microsoft の DSC のリソース（`microsoft/winget-dsc`）が同じ値を書いている
  - IME の Ctrl+Space（「表示と入力」の手順 7）は、レジストリの値が Microsoft の文書に無く、効く時期も分からないので、設定の画面を開いて変える
  - タスクバーとスタートのピン留め（「再起動の後に確かめる」の手順 3）は、自分のユーザーで使える、サポートされたコマンドが無い（ポリシーとプロビジョニングだけ）ので、画面で外す
  - ウィジェットのボタン（`TaskbarDa`）は UCPD が守っていて書けないので、ウィジェットそのものを外す（「自動起動と標準アプリ」の手順 3）
- **標準アプリは、自分のユーザーから外す（`Remove-AppxPackage`）**: 管理者の権限が要らず、ストアからいつでも入れ直せる。PC に置かれた元（プロビジョニング）を外す方法は、ほかのユーザーにもかかるので採らない。そのため、機能の更新の後に戻ってくることがある
- **自動で起動するアプリは、消さずに止める**: タスク マネージャーと同じ所（`StartupApproved\Run`）に書き、いつでもタスク マネージャーから戻せるようにした

**PC 全体・ネットワーク・サインイン（「PC 全体の設定」の手順 5 から「WSL と再起動」の手順 1 までと、「WSL の AlmaLinux 10 と自動サインイン」の手順 5）**

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
- PowerToys・PowerShell 7・Autologon・WSL・CopyQ（任意節）は、このリポジトリでは Windows でだけ使うので、この文書に置いた
- **scoop の `git` は入れない**: git は [git.md](../windows-setup.md#git-for-windows) の Git for Windows（`C:\Program Files\Git`）にそろえる。ほかの手順書（OpenSSH サーバーの既定のシェル、Claude Code）がその場所を使う。scoop は `PATH` の `git` を使い、git 無しで入れた scoop も、Git for Windows を入れた後の `scoop update` で git の形に直る（scoop 0.6.0 の `libexec/scoop-update.ps1`）

**窓と再起動**

- **管理者ではない PowerShell と管理者の PowerShell を分けた**
  - scoop のインストーラは、管理者の PowerShell では止まる。scoop・UniGet UI・PowerToys（自分のユーザーへの導入）と、自分のユーザーの表示の設定は、どれも管理者の権限が要らない
  - PC 全体の設定（`HKLM`・ファイアウォール・電源・機能）と、管理者しか書けない `HKCU\Software\Policies` だけ、管理者の PowerShell で行う
  - そのため、[Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)の SSH のセッション（Administrators の一員なら管理者の権限で動く）には貼らない
- **設定のための再起動を 1 回にまとめた**: Scancode Map・PC の名前・キーボードの種類・WSL の機能は再起動、エクスプローラーの設定はエクスプローラーの起動し直しで効く。再起動 1 回で全部効く（hackgen.md の Windows のフォントも、サインインし直す代わりにこの再起動で効く）。Windows Update は先に「Windows Update」の手順 1〜8 で済ませ、必要な再起動は同じ項の手順 8 で行う
- **Windows PowerShell 5.1 にそろえた**: Windows 11 に最初からあり、ほかの Windows の手順書とも同じ。実行ポリシーとプロファイルは PowerShell 7 と別に持つので、5.1 の値を変える

## 参考資料から分離した記録

### 参考資料: 実施手順 / PC 全体の設定 / 手順 2: 補足: 変数について

- `$PC_NAME` は「PC 全体の設定」の手順 5（PC の名前を変える）で使う
- `$LAN_IF` は、「PC 全体の設定」の手順 3（今の状態）・同じ項の手順 8（アダプターの省電力）と「ネットワークとリモート」の手順 1（プライベートにする）で使う。式は [Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)の手順 2 と同じ
- 接続の一覧は `Get-NetConnectionProfile` で見られる。[Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)の検証の PC では、WSL を動かしていても `vEthernet (WSL (Hyper-V firewall))` は一覧に出ず、有線 LAN の 1 行だけだった

### 参考資料: 実施手順 / ネットワークとリモート / 手順 3: 補足: リモート アシスタンス

- リモート アシスタンス（Windows の「クイック アシスト」とは別）は、ほかの人を招いて画面を見せる古い仕組み。システムのプロパティの「リモート」タブの「このコンピューターへのリモート アシスタンス接続を許可する」が `fAllowToGetHelp`
- [Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)の検証の PC では、LAN をプライベートにすると、リモート アシスタンスの受信の規則 4 本が効くようになった（「ネットワークとリモート」の手順 1 の補足）
- グループの ID `@FirewallAPI.dll,-33002` は、Microsoft の文書には無い（Windows の `racpldlg.dll` の文字列にある）。違っていたら、`Get-NetFirewallRule | Sort-Object Group -Unique | Format-Table DisplayGroup, Group` で「リモート アシスタンス」の行の `Group` を見る
- Microsoft の無人インストールの文書は、`fAllowToGetHelp` の既定を無効と書いているが、店頭の Windows では有効なことが多いと報告されている。「PC 全体の設定」の手順 3 の `RemoteAssistance` で、元の値を控える
- 元に戻すのは[ロールバックの「ネットワークと PC 全体の設定を戻す」](../extra/windows-setup.md#ネットワークと-pc-全体の設定を戻す)の手順 3

### 参考資料: 実施手順 / サインイン・検索・キーボード / 手順 1: 補足: この設定と、リモート デスクトップ・SSH・自動サインイン

- 設定の「アカウント」→「サインイン オプション」の「セキュリティ向上のため、このデバイスでは Microsoft アカウント用に Windows Hello サインインのみを許可する」。値（2 がオン、0 がオフ）は Microsoft の文書に無く、広く使われているもの
- オンだと、Microsoft アカウントのパスワードでのリモート デスクトップに入れない、という Microsoft Q&A の回答がある。[Windows の OpenSSH サーバー](../extra/windows-setup.md#注意点)の検証の PC では、オンのまま SSH にパスワードで入れた（Q&A の報告とは違った）
- オンだと、自動サインイン（「WSL の AlmaLinux 10 と自動サインイン」の手順 5）の設定に要る「ユーザーがこのコンピューターを使うには、ユーザー名とパスワードの入力が必要」の項目が隠れると報告されている
- 元に戻すのは[ロールバックの「サインイン・検索・キーボードを戻す」](../extra/windows-setup.md#サインイン検索キーボードを戻す)の手順 5

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 実施手順 / Microsoft Store の更新 / 手順 4

   - 終わったら「Microsoft Store の更新」の手順 5 へ。まだ CLI が使えない場合は止める（この準備からの通し実行は未検証）

### 実施手順 / 表示と入力 / 手順 7

   - 設定の Microsoft IME の画面が開く。「キーとタッチのカスタマイズ」を開き、「キーの割り当て」をオンにして、「Ctrl + Space」を「IME-オン/オフ」にする（画面の文言は確かめていない）

### 実施手順 / WSL と再起動 / 手順 1

   - 必要な機能（仮想マシン プラットフォーム）を入れた旨と、再起動を求める旨の行が出ればよい（出力は確かめていない）

### 実施手順 / 再起動の後に確かめる / 手順 3

   - 画面の文言は確かめていない

### ロールバック / 表示と入力を戻す / 手順 7

   - 「キーとタッチのカスタマイズ」で、「Ctrl + Space」を「なし」にするか、「キーの割り当て」をオフにする（画面の文言は確かめていない）

### ロールバック / ネットワークと PC 全体の設定を戻す / 手順 3

   - システムのプロパティの「リモート」タブが開く。「このコンピューターへのリモート アシスタンス接続を許可する」にチェックを入れて「OK」を押す（画面の文言は確かめていない）

   - この画面は、`fAllowToGetHelp` と、リモート アシスタンスの受信の規則をまとめて戻すはず（確かめていない）。規則をコマンドでまとめて有効にすると、「ネットワークとリモート」の手順 3 の前に無効だった規則（パブリック向けなど）まで有効になりうるので、画面で戻す

### 補足

- **JIS 配列では「英数」のキーが Ctrl になる**: 日本語の配列のキーボードの Caps Lock は「英数」のキー（スキャン コード `0x3A`）なので、そのキーの IME の働き（英数への切り替え）も無くなるはず（確かめていない）

- **リモート デスクトップと Scancode Map**: Microsoft の文書は、Scancode Map がターミナル サービスでは正しく働かないことがあると書いている。この PC にリモート デスクトップでつないだとき、つないだ側の PC でつないだときの効き方は確かめていない

- **このユーザーの Windows PowerShell のコンソールの窓すべてに効く**: 管理者の窓も同じプロファイルを読む。SSH でログインしたセッションの Windows PowerShell で、SSH のクライアントから貼ったときの動きは確かめていない

## 付録: Windows 11 Pro の VM での導入検証（2026-10-06）

**VM での部分検証結果**。利用者の希望で一度中断し、`<OTHER_PC>` への引き継ぎを準備した。その後の「やはりこのホストで作業を再開してください。」により、`<HOST_PC>` の元の VM で再開した。「Windows Update」の手順 2〜7、「Microsoft Store の更新」の手順 2・5・7、「貼り付けの設定」の手順 1〜4、「アプリを入れる」の手順 1〜5、「表示と入力」の手順 1〜6、「自動起動と標準アプリ」の手順 1〜3、「WSL の AlmaLinux 10 と自動サインイン」の手順 2 の CLI 実行と値の読み戻し、管理者設定（「PC 全体の設定」の手順 6〜8、「ネットワークとリモート」の手順 1〜5、「サインイン・検索・キーボード」の手順 1〜4）を確認した。「表示と入力」の手順 7 の設定と「再起動の後に確かめる」の手順 1 の Caps Lock・Ctrl+Space は利用者が手動で確認した。「自動起動と標準アプリ」の手順 1 は修正版の実行と値の読み戻し、「WSL と再起動」の手順 2 の OS 再起動はログで確認し、「再起動の後に確かめる」の手順 2 の Explorer・タスクバーなどの一部を実画面で確認した。WSL（「WSL と再起動」の手順 1）はパッケージ・機能の導入まで成功したが、「WSL の AlmaLinux 10 と自動サインイン」の手順 3・4 と VirtualBox の入れ子の VM の実起動は検証環境の制約で未達。「WSL の AlmaLinux 10 と自動サインイン」の手順 5 は Autologon の導入・実体・署名・UAC の画面を確認したが、本文と補助タスクの起動要求は取消で終了した。その後、利用者が Explorer から手動で起動・設定し、2 CPU の通常再起動で無入力の自動サインインを確認した。本文の起動経路が成功した結果とは扱わない。その後、Bing の結果なし（「再起動の後に確かめる」の手順 2）、不要な Edge/Store のピン解除（同じ項の手順 3）、WinGet/Scoop 有効と scoop-search/UniGetUI の導入済み一覧（同じ項の手順 4）を利用者が手動で確認した。さらに、「再起動の後に確かめる」の手順 4 のスタートからの起動と WinGet/Scoop の GUI の版表示、「WSL の AlmaLinux 10 と自動サインイン」の手順 1 の通常権限の Windows PowerShell 5.1 のスタートからの起動、LF 3 行の右クリック貼り付け順を利用者が手動確認した。貼り付けは「貼り付けの設定」の手順 1〜4 と「PC 全体の設定」の手順 4 の確認として今回の fixture の範囲に限定する。AI の画面確認、ピン解除の正確な文言、GitHub の直接コピー経路・管理者窓への貼り付けと残る GUI の効果、認証後の RDP ログインと ping は未確認。追加の事前交渉では TCP 到達と CredSSP の選択・必須を確認し、通常権限の PowerShell 7 で長いパスとシンボリックリンクの実操作も確認した。Git の共通手順による 12 キーは試験用の global 設定で検証し、本人の設定には反映していない。「Microsoft Store の更新」の手順 6 は条件により飛ばし、実適用は未確認。「再起動の後に確かめる」の手順 2〜4、「WSL の AlmaLinux 10 と自動サインイン」の手順 1 と貼り付け fixture の手動確認は回答済みで、この範囲の結果を記録した。追加の Firefox・既定ブラウザー・HackGen の GUI・ゲスト内の VirtualBox Manager は回答待ち。Windows の実機で全手順を通した記録ではない。

**環境と導入元**:

| 項目 | 値 |
|---|---|
| インストール媒体 | 利用者が Rufus 4.15.2396 の画面で専用の 16 GiB VHD に作成し、USB の記憶装置として VM に接続した |
| ISO | Microsoft 公式の日本語の製品版。SHA256 は `923EC1A2EC46CCBE607FC81BEAF9753BFBB6FC62220B7B8BFFD56E66F6DE3A0C` |
| OS | Windows 11 Pro 26H2、26300.9457、x64 |
| VM | VirtualBox 7.2.20、メモリ 8 GiB、当初 CPU 4 個、復旧比較後は 2 個のままで 4 個に戻す再試験は未実施、EFI・Secure Boot・TPM 2.0。Hyper-V の NEM バックエンド |
| 導入先 | 新規の 256 GiB ディスク。単独の Windows の VM で、デュアルブート向けのパーティション作成は試していない |
| ユーザー | ローカル アカウント `<WIN_USER>`、Administrators の一員 |
| PowerShell | Windows PowerShell 5.1、x64。デスクトップにサインインした対話タスクで実行した。当初は Session 2、「Microsoft Store の更新」の手順 7 は復旧後の Session 1 |
| 検証用の追加物 | Guest Additions と検証コードは別の DVD から導入した。Rufus の元媒体は変更していない。利用者の要望により、専用 VM の検証用パスワードを変更した |
| 導入前の基準記録 | Guest Additions の導入前に採取した読み取りの JSON。保護した原記録の SHA256 は `F0465DE273E11E84517816E20DEAFC71A87520875C6D8DD017ABF29B47211C0C` |

- Rufus の 7 項目は生成された回答ファイルで確認した。回答ファイルは `boot.wim` のイメージ 2 の `Autounattend.xml` にあり、7 項目すべての最終的な効果を証明した記録ではない

**実行方法**:

- 本文の折り畳みの外にある PowerShell ブロックを抽出し、コマンドを変えずに `Invoke-Expression` で順番に実行した。同じ実行グループ内では、「アプリを入れる」の手順 1 を除いてスコープを共有した。「アプリを入れる」の手順 1 はインストーラーが dot-source と判定しないよう別のスコープで呼び、同じプロセスの環境変数を引き継いだ
- 「Windows Update」の手順 2〜7 と PC 全体の設定は管理者、「Microsoft Store の更新」の手順 2・5・7、「貼り付けの設定」の手順 1〜4、「アプリを入れる」の手順 1〜5、「表示と入力」の手順 1〜6、「自動起動と標準アプリ」の手順 1〜3 は通常権限の対話タスクで実行した。「表示と入力」の手順 7 の IME の設定は利用者が画面で行った。「Windows Update」の手順 1、「Microsoft Store の更新」の手順 1、「PC 全体の設定」の手順 1 の画面操作と本文の貼り付けはタスクで代替した。その後、「WSL の AlmaLinux 10 と自動サインイン」の手順 1 の通常窓の起動と、メモ帳からの LF 3 行 fixture の右クリック貼り付けは利用者が手動確認した。GitHub の直接経路・管理者窓への貼り付けは未試験
- 出力・エラー・終了コードと、実行前後の読み取りの状態を採取した。検証用コードの実行準備は、本文の設定が効いたという判定には使っていない

**確認できた結果**:

| 手順 | 実際の結果 |
|---|---|
| 「Windows Update」の手順 2・3 | NuGet 2.8.5.208 と PSWindowsUpdate 2.2.1.5 の初回導入・読み込みが成功した |
| 「Windows Update」の手順 4（修正前） | 表には KB5007651・KB890830・KB2267602 の 3 件が出たが、件数の表示は 1 件だった。検索結果の 1 要素が `Collection<PSObject>` で、その中に 3 件を持つことを診断で確認した |
| 「Windows Update」の手順 4・7（修正後） | 検索結果を `ForEach-Object { $_ }` で展開するように直した。実検索の 1 件・0 件は正しく表示・判定した。修正後の 3 件の表示は、型の診断と Windows PowerShell 5.1 の模擬で確認した範囲で、実更新前の 3 件では再検索していない |
| 「Windows Update」の手順 5・6 | 元の手順のまま 2 回実行した。KB5007651・KB890830・KB2267602・KB4052623 の計 4 件がすべて `Installed` になり、再起動待ちは `False` だった |
| 「Windows Update」の手順 7（修正前） | 最初の 3 件を適用した後は KB4052623 が残り、再度適用した後は残り 0 件・確認完了・再起動待ちなしになった。0 件は元のコードでも正しく判定した |
| 「Windows Update」の手順 7（復旧の再起動後） | 管理者の「Windows Update」の手順 2・3・7 のバッチ `20261006-084631Z-30eaa70d` はすべて完了し、エラーは 0 件。「Windows Update」の手順 7 の実出力は更新 0 件・再起動待ちなしだった |
| 「Microsoft Store の更新」の手順 2 | 通常権限の Session 2 で成功した。`winget.exe` と `store.exe` が使えた |
| 「Microsoft Store の更新」の手順 3・4 | Windows Update の作業中に Store が 22506.1400.2.0 から 22608.1401.5.0 へ自動更新されたため飛ばした。古い Store から CLI を準備する分岐は未検証 |
| 「Microsoft Store の更新」の手順 5（初回） | `updates --help` の終了と `--apply` 対応を確認した。再起動後に回収した初回のログには `Updates available (31 found)` と `Store-managed updates available for bulk installation`、App Installer・Terminal など 31 件の全一覧があった。この初回は CLI の自然終了と終了コードを確認できず、強制停止で中断した |
| 「Microsoft Store の更新」の手順 5（再起動後の再実行） | 通常権限の「Microsoft Store の更新」の手順 2・5 のバッチ `20261006-084901Z-83141775` は正常終了し、「Microsoft Store の更新」の手順 5 は `No updates found.` を明示した。エラーの記録は空配列、CLI の終了コードは 0 だった |
| 「Microsoft Store の更新」の手順 6 | 「Microsoft Store の更新」の手順 5 で更新なしを明示したため、条件により飛ばした。`store updates --apply` の実適用は未検証 |
| 「Microsoft Store の更新」の手順 7 | 再サインイン後の通常権限の Session 1、Windows PowerShell 5.1.26100.9444 でバッチ `20261006-101014Z-da3b4e6d` を実行した。`No updates found.`、App Installer 1.29.379.0 と Terminal 1.24.12741.0 の `Ok`、winget v1.29.380 を確認。エラー 0 件・CLI の終了コード 0・タスク結果 0 で正常終了し、終了記録も今回のバッチに対応した |
| 「貼り付けの設定」の手順 1・2 | バッチ `20261006-101122Z-361fe6d7` を通常権限で実行した。初期状態は Scoop・Git なし、ClassicMenu は `False`、Scancode Map なし、プロファイルなし。実行ポリシーの全範囲は `Undefined`、実効値は `Restricted` だった。「貼り付けの設定」の手順 1 の設定コマンドはエラーなく無出力で終了した |
| 「貼り付けの設定」の手順 3・4 | 実効の実行ポリシーは `RemoteSigned` になり、既定のプロファイルへ印付きの 1 行だけを追加した。バッチ全体はエラー 0 件・タスク結果 0 で終了記録も一致した。続く新しい PowerShell のバッチで `RemoteSigned` と Ctrl+Enter の `AddLine` を確認し、プロファイルが読み込まれることを確認した。その後、通常窓での LF 3 行 fixture の右クリック貼り付け順を利用者が手動確認した。GitHub の直接経路・管理者窓は未試験 |
| 「アプリを入れる」の手順 1・2 | 通常権限の Session 1 のバッチ `20261006-102102Z-85dd008c` で、`Initializing...` に続き `Scoop was installed successfully!` を確認した。Scoop v0.6.0（2026-09-30）、main バケット（1,669 件）、ユーザーの `PATH` に `C:\Users\<WIN_USER>\scoop\shims` を確認。エラー 0 件、「アプリを入れる」の手順 2 の終了コード 0・タスク結果 0 で終了記録も一致した |
| 「アプリを入れる」の手順 3（初回の一覧確認中断） | バッチ `20261006-102229Z-e5e945ca` で scoop-search 2.1.0 と UniGet UI 2026.3.0 の導入が成功した。利用者が Visual C++ ランタイムの管理者確認を許可した後、`Successfully installed` が出た。続く source 未指定の `winget list` は `msstore` の規約と地域情報の初回同意待ちになり、対象 CLI を操作側で中断した |
| 「アプリを入れる」の手順 3（修正後の再実行） | 通常権限の Session 1 のバッチ `20261006-103736Z-d0d5c6cc` は、scoop-search は既存、UniGet UI は既存で新しい版なしと表示した。`--source winget` を付けた一覧は UniGetUI・Devolutions.UniGetUI・2026.3.0 を正常に表示した。エラー 0 件・終了コード 0・タスク結果 0 で終了記録も一致した。初回導入のやり直しではなく、既存の導入の確認だった |
| 「アプリを入れる」の手順 4 | 通常権限の Session 1 のバッチ `20261006-103844Z-c2c5935a` で PowerToys 0.101.2362.0 のハッシュ確認・初回導入・一覧表示が成功した。HKCU の登録と `%LOCALAPPDATA%\PowerToys` の本体の存在・FileVersion 0.101.2362.0 を確認。10:40:04.713 UTC にエラー 0 件・終了コード 0・タスク結果 0 で終了し、終了記録も一致した |
| 「アプリを入れる」の手順 5 | 通常権限の Session 1 のバッチ `20261006-104359Z-4a9f9dd6` で PowerShell 7.6.6.0 のハッシュ確認・初回導入・一覧表示が成功した。ユーザーの MSIX は `Microsoft.PowerShell_8wekyb3d8bbwe`、Status は `Ok`、版は 7.6.6.0。WindowsApps の `pwsh.exe` と `PowerShell 7.6.6` の表示を確認した。10:45:16.137 UTC にエラー 0 件・終了コード 0・タスク結果 0 で終了し、終了記録も一致した |
| 「表示と入力」の手順 1〜6 | バッチ `20261006-104548Z-b74ba246` はすべてエラー 0 件・タスク結果 0 で終了記録も一致した。10:54:13.309 UTC の独立の読み取りもエラー 0 件で、指定したレジストリの全値と型を確認した。GUI の効果は未確認 |
| 「表示と入力」の手順 7 | 利用者が IME のオン・オフを Ctrl+Space に設定し、設定画面を閉じたことを確認した。IsKeyAssignmentEnabled=1・KeyAssignmentCtrlSpace=2 を DWORD で読み戻した。その後の「再起動の後に確かめる」の手順 1 では利用者が実際のキー入力も確認した |
| 「自動起動と標準アプリ」の手順 1（修正前） | 通常権限のバッチ `20261006-111347Z-f222f42c` で Edge の MicrosoftEdgeAutoLaunch_* の StartupApproved の先頭バイトが 3 になった。OneDrive の正確な名前と Teams のキーはなく、該当部分は何もしなかった。出力には `OneDriveSetup: 起動する` が残った。11:19:49 UTC の独立の読み取りでは Run の項目が実在したが、参照先の `C:\Windows\System32\OneDriveSetup.exe` はなく、動いているインストーラーを確認した結果ではない |
| 「自動起動と標準アプリ」の手順 1（修正後） | 「自動起動と標準アプリ」の手順 1 と対応するロールバックの「表示と入力を戻す」の手順 8 の対象へ正確な名前 `OneDriveSetup` を追加した。修正版のバッチ `20261006-112432Z-9ca3808b` はエラー 0 件・終了コード 0・タスク結果 0 で終了した。11:26:39.6657555 UTC の独立の読み取りで OneDriveSetup と Edge の StartupApproved の先頭バイト 3 を確認した。Run の値と実行ファイルは消さず、RunOnce と Active Setup は変更していない。参照先の実行ファイルは不在で、署名は確認していない |
| 「自動起動と標準アプリ」の手順 2・3 | 同じバッチは 11:14:32.816 UTC にすべてエラー 0 件・タスク結果 0 で終了し、終了記録も一致した。「自動起動と標準アプリ」の手順 2 は Clipchamp・BingNews・BingWeather・Solitaire・OfficeHub・Todos・FeedbackHub・GetHelp・PowerAutomateDesktop の 9 個、同じ項の手順 3 は Web Experience Pack を外した。Outlook と Teams は最初から不在だった。独立の読み取りでも対象 11 個と Web Experience Pack はすべて不在で、最初から不在の Copilot も不在のままだった |
| 「PC 全体の設定」の手順 2・3 | バッチ `20261006-104738Z-a4ee1724` は管理者・Session 1・Ctrl+Enter `AddLine`。Professional、26H2、26300.9457、PC_NAME は空、対象 LAN は「イーサネット」（index 13）で Public、RemoteDesktop は 1、RemoteAssistance は 1、HelloOnly は 2、キーボードは `kbd106.dll`、配信の最適化は Lan だった |
| 「PC 全体の設定」の手順 4・6〜8、「ネットワークとリモート」の手順 3・5、「サインイン・検索・キーボード」の手順 1〜4 | バッチ `20261006-105215Z-41e42451` はエラー 0 件・タスク結果 0 で終了記録も一致し、10:52:34.809 UTC に終了した。独立の読み取りでも変更した値と型を確認した。このバッチの「PC 全体の設定」の手順 4 は CLI の順だけを確認した。その後、通常窓での LF 3 行 fixture の右クリック貼り付け順を利用者が手動確認したが、管理者窓は未試験 |
| 「PC 全体の設定」の手順 7（確認の修正後） | 元の `/q` では LIDACTION と CONSOLELOCK の確認値が空だった。`/qh` に直したバッチ `20261006-105558Z-e052cc85` は 10:55:59.198 UTC にエラー 0 件・終了コード 0・タスク結果 0 で終了し、終了記録も一致した。AC の STANDBYIDLE・LIDACTION・CONSOLELOCK はすべて 0、HibernateEnabled は 0 だった |
| 「PC 全体の設定」の手順 5、「サインイン・検索・キーボード」の手順 5・6 | PC_NAME が空、単独の Windows、JIS 106/109 キーの条件により飛ばした。キーボードの `kbd106.dll`・PCAT_106KEY・7・2 を保持した。改名・UTC・US 配列への変更の分岐は未検証 |
| 「ネットワークとリモート」の手順 1・2・4 | 利用者がこの VM に限って許可した後、「PC 全体の設定」の手順 2 を含むバッチ `20261006-111436Z-5b60cb90` は 11:14:48.986 UTC にすべてエラー 0 件・タスク結果 0 で終了し、終了記録も一致した。11:16:41.776 UTC の読み取りもエラー 0 件で、LAN のイーサネット・index 13 は Private、RDP の fDenyTSConnections=0・UserAuthentication=1、RDP の 3 規則と ICMP の 2 規則は有効・Private・Inbound・Allow を確認した。追加の TCP 到達・事前交渉は確認したが、認証情報送信・実際の RDP ログインと ping は未確認 |
| 「WSL と再起動」の手順 1（再起動前の導入確認） | バッチ `20261006-105428Z-57f1244c` は 10:55:24.498 UTC にエラー 0 件・終了コード 0・タスク結果 0 で終了し、終了記録も一致した。WSL 3.0.1 の導入と VirtualMachinePlatform の DISM が成功し、再起動を求めた。11:07:33.958 UTC の独立の読み取りもエラー 0 件で、WSL 3.0.1.0 の登録・`Ok` と VirtualMachinePlatform の `Enabled` を確認した。この時点では再起動後の WSL 2 の実起動はまだ試していなかった |
| 「WSL と再起動」の手順 2（後回収のログで再起動を確認） | 11:33:51 UTC に通常の `Restart-Computer` を実行し、CLI はエラー 0 件・タスク結果 0 だった。後回収のイベントでは User32 1074 が 11:33:53.778 UTC、Kernel-General 13 の終了が 11:34:13.593 UTC、Kernel-General 12 が OS の起動を 11:39:02.500 UTC と記録し、EventLog 6005 は 11:39:13.762 UTC だった。約 5 分遅れて OS が再起動したことを確認した。最初の起動のロック画面・対話画面への到達は直接確認していない |
| 「WSL と再起動」の手順 2 後の復旧起動 | 利用者の明示承認後、11:45:29.857 UTC に対象 VM の強制停止が成功した。停止後の退避を経て起動し、VM の状態は 11:48:17.364 UTC に running、ゲスト OS の LastBoot は 11:48:29.5 UTC だった。GuestControl は終了コード 0 で応答し、Explorer は 0・未サインイン、管理者と通常権限のタスクは Ready。20:49 JST のロック画面を確認し、手動サインインを依頼した。「WSL と再起動」の手順 2 による 11:39 の起動とは別の、強制停止後の起動として扱う |
| 「再起動の後に確かめる」の手順 1（利用者の手動確認） | ツールの Caps_Lock+A と Ctrl+A は入力の到達を確認できなかった。その後、利用者が「その通りになりました。」と回答し、実際の入力で Caps Lock+A の全選択、Caps Lock 単独で大文字にならないこと、Ctrl+Space による IME の A/あ と文字入力の切り替えを確認した。利用者の手動確認として合格とし、自動入力の試験が成功した結果とは扱わない |
| 「再起動の後に確かめる」の手順 2（一部） | 新しい Explorer は PC を開き、`gui-fixtures-visible.txt` の拡張子と Hidden 属性の `hidden.txt` の薄色表示を確認した。ファイルの右クリックで直接、送る・プロパティのある旧形式のメニューが開いた。タスクバーは左寄せ・検索/タスクビュー/ウィジェットなし・時計に秒、全体はダークモード、Edge と UniGet UI のデスクトップのショートカットなしを実画面で確認した。Bing の結果なしは、後の「問題ありませんでした。」という利用者の手動回答で確認した。AI はその検索画面を確認できていない |
| 「再起動の後に確かめる」の手順 3（利用者の手動確認） | 不要な Edge/Store のピン解除について、利用者が「問題ありませんでした。」と回答した。手動確認は合格。AI の画面確認と、ピン解除メニューの正確な文言は未確認 |
| 「再起動の後に確かめる」の手順 4（利用者の手動確認） | WinGet/Scoop 有効と scoop-search/UniGetUI の導入済み一覧について、利用者が「問題ありませんでした。」と回答した。追加の起動経路・GUI の版表示についても「確認しました。」と回答し、スタートからの起動と WinGet/Scoop の GUI の版表示を手動確認PASSとした。AI の画面確認は未実施 |
| 「WSL の AlmaLinux 10 と自動サインイン」の手順 1、「貼り付けの設定」の手順 1〜4/「PC 全体の設定」の手順 4（通常窓の fixture） | 利用者の「確認しました。」により、スタートから通常権限の Windows PowerShell 5.1 を開き、メモ帳の LF 3 行を右クリックで貼って paste-line-1→2→3 の順で実行できたことを手動確認PASSとした。今回の fixture の範囲であり、GitHub の直接コピー経路・管理者窓・AI の画面確認は未試験 |
| 「WSL の AlmaLinux 10 と自動サインイン」の手順 2 | 通常権限の Session 1 のバッチ `20261006-120810Z-1dab0034` は 12:08:13.075 UTC にエラー 0 件・タスク結果 0 で正常終了した。CtrlEnter=AddLine・20 バイトの Scancode Map・kbd106.dll・LongPaths=1・DeveloperMode=1・Sudo=3・Hibernate=0・RemoteDesktop=0・LanCategory=Private を確認した |
| 「WSL の AlmaLinux 10 と自動サインイン」の手順 3・4（文字コード修正前） | 「WSL の AlmaLinux 10 と自動サインイン」の手順 3 の CLI は終了コード -1・`HCS_E_HYPERV_NOT_INSTALLED`、同じ項の手順 4 は終了コード -1・`WSL_E_DISTRO_NOT_FOUND` だった。AlmaLinux 10 の導入と実起動は成功していない |
| 「WSL の AlmaLinux 10 と自動サインイン」の手順 3・4（文字コード修正後） | `WSL_UTF8` と `Console.OutputEncoding` の UTF-8 を併用する修正版を、バッチ `20261006-122748Z-427db2bf` で実行した。12:27:55.850 UTC に終了し、両手順の PowerShell のエラー記録 0 件・タスク結果 0 だったが、CLI は終了コード -1 で同じ仮想化エラー・ディストリビューションなしだった。両手順の日本語出力は読めた。文字コードの修正は確認したが、WSL の実起動は合格としていない |
| 「WSL の AlmaLinux 10 と自動サインイン」の手順 5（再開後・起動要求取消） | 通常権限の UTF-8 修正版 manifest のバッチ `20261006-173336Z-f88f0701` で、Autologon の導入成功・winget の終了コード 0 を確認した。17:33:57.0822889 UTC に、`%LOCALAPPDATA%\Microsoft\WinGet\Packages` の下に初めてできた Autologon64.exe の 3.10・署名 Valid・Microsoft Corporation を確認し、UAC の実画面でも製品 Autologon・発行元 Microsoft Corporation を確認した。その後、`Start-Process` が「この操作はユーザーによって取り消されました。」を記録し、17:35:47.0813252 UTC にエラー 1 件・タスク結果 1 で終了、タスクは Ready になった。起動要求取消の原因は未特定で、この試行では Autologon の設定は未実施・自動サインインは未検証だった |
| 「WSL の AlmaLinux 10 と自動サインイン」の手順 5（Explorer の手動起動・設定後の再起動） | 利用者が手動起動・UAC・Enable・成功表示・終了を報告し、指定した Winlogon の 3 値を読み戻した。2 CPU の条件で通常の OS 再起動を 1 回要求し、VM への入力なしで LastBoot 23:18:13.5 UTC と `<WIN_USER>`・Explorer・PowerToys の Session 1 を確認した。手動設定後の自動サインインは合格。本文と補助タスクの取消履歴は維持し、その起動経路の成功とは扱わない |

- 貼り付けの fixture は `C:\verify\paste-order-check-20261007.txt`（45 バイト、LF、UTF-8 BOM なし）。SHA256 は `1AE3B7504E8FA11B8A7A23EFB9DA9230DFA946A4FB418BE10EA2D22B5416DBB0`。利用者のメモ帳からの貼り付け確認で、AI が本文の GitHub コピーボタンを操作した試験ではない
- 「Windows Update」の手順 4・7 の修正は、複数更新の件数表示の誤差を直すもの。「Windows Update」の手順 5 は変更していない
- 「表示と入力」の手順 1 は DWORD の HideFileExt=0・Hidden=1・LaunchTo=1・Start_TrackDocs=0・ShowRecent=0・ShowFrequent=0、同じ項の手順 2 は String の既定値が空、同じ項の手順 3 は指定した 11 個の DWORD が 0 だった。「表示と入力」の手順 4 は TaskbarAl=0・TaskView=0・秒=1・検索=0、同じ項の手順 5 は明暗の 2 値が 0、同じ項の手順 6 は 2 つの委譲の GUID が本文と完全に一致した。その後の実画面で Explorer・旧形式のメニュー・タスクバー・ダークモードを確認したが、既定の端末など、すべての効果を確認したわけではない
- 管理者設定の読み取りでは、LongPathsEnabled=1・AllowDevelopmentWithoutDevLicense=1・Sudo Enabled=3、DelayLockInterval=4294967295・HibernateEnabled=0 を DWORD で確認した。NIC の AllowComputerToTurnOffDevice は Disabled、RemoteAssistance は 0 で対象の 15 規則はすべて False、HelloOnly は 0、Bing の提案抑止は 1、Edge のショートカット抑止は 1 だった。Edge と UniGet UI の 2 つのショートカットは削除後も不在で、Scancode Map の 20 バイトは本文と一致した
- 配信の最適化は導入前から Lan で、「ネットワークとリモート」の手順 5 は同じ値を確認した。VM のファームウェアはスリープと休止状態を使えず、「PC 全体の設定」の手順 7 の実際の眠り・復帰・蓋の動作は試していない
- 「WSL と再起動」の手順 1 後の `wsl --version` は終了コード 0 で WSL 3.0.1.0・カーネル 6.18.40.1-1・WSLg 1.0.79、`wsl --status` は終了コード 0 で既定のバージョン 2 を表示した。同時に「このコンピューターで仮想化が有効になっていないため、WSL2を開始できません」と表示した。CPU の VMMonitorModeExtensions・SLAT は False、VirtualizationFirmwareEnabled・HypervisorPresent は True だった。この読み取り時点では「WSL と再起動」の手順 1 後の再起動をまだしておらず、復旧起動後の WSL 2 の結果とは分けて扱う
- WSL 1 の機能 `Microsoft-Windows-Subsystem-Linux` は Disabled で、この手順では不要なので正常。`wsl --list --verbose` はディストリビューションなしと表示して終了コード -1 だった。「WSL と再起動」の手順 1 は `--no-distribution` なので、これも導入失敗とは判定しない
- 当時の LastBoot は 12:04:48.5 UTC だった。11:48 の復旧起動の後、利用者が完了を知らせる前の追加の起動で、理由はまだ特定していない。手動サインイン後の「WSL の AlmaLinux 10 と自動サインイン」の手順 2 と以下の読み取りは、この時点の起動後の状態として扱う
- 12:09:46.1127459 UTC の管理者の読み取りはエラー 0 件で、IME の 1・2、OneDriveSetup と Edge の StartupApproved の先頭 3、NIC の Disabled、AC の 3 値 0、RDP の有効・NLA と Private の規則などが保持されていた
- 12:17:44.0437403 UTC の WSL の読み取りはエラー 0 件・タイムアウト 0 件だった。WSL 3.0.1.0 は Ok、VirtualMachinePlatform は Enabled、WSL 1 の機能は Disabled、CPU の VMMonitorModeExtensions・SLAT は False、VirtualizationFirmwareEnabled・HypervisorPresent は True。`wsl --status` は既定 2 で、この時点では WSL 2 の警告はなかったが、`--list` はディストリビューションなし・終了コード -1 だった。「WSL の AlmaLinux 10 と自動サインイン」の手順 3・4 の実行結果を優先し、パッケージと機能の導入確認から実起動の成功とは判断しない
- 初回導入と設定確認の時点では、後続の [Git for Windows](../windows-setup.md#git-for-windows)・[Firefox](../windows-setup.md#firefox)・[WezTerm](../windows-setup.md#wezterm)・[Claude Code](../windows-setup.md#claude-code)・[VirtualBox](../virtualbox.md#windows-11-で使う)・[WireGuard](../wireguard.md#windows-11-で使う)・[HackGen Console NF](../windows-setup.md#hackgen-console-nf)は、同じ VM で導入部分を確認した。VirtualBox は 7.2.20、WireGuard は 1.1.1 だった。追加検証では InstalledFontCollection の HackGen の 2 ファミリーと、WezTerm の右クリック用レジストリ項目を確認した。Git の共通手順 3・5・6・7 は非対話の Git Bash と隔離した global 設定で検証し、12 キーの値・global スコープ・試験用ファイルの出どころを確認した。この時点では本人の user.name/user.email と実 global 設定への反映、対話的な Git Bash の GUI、pull 動作は未検証。GUI の一覧・実クリックと認証、VPN の接続は未確認。Firefox・既定ブラウザー・HackGen の GUI・ゲスト内の VirtualBox Manager の確認は回答待ち
- VirtualBox の入れ子の VM の起動試験は、バッチ `20261006-123615Z-9406750f` で `VERR_NEM_NOT_AVAILABLE`（ゲストの CPUID が VirtualBox の署名）・`VERR_SVM_NO_SVM` となり失敗した。試験用 VM は `unregister --delete` で削除し、フォルダーも不在だった。後始末の終了コード 0 を起動成功とは扱わず、WSL とともにこの検証環境の制約として記録する
- 「ネットワークとリモート」の手順 1・2・4 は当初、具体的な許可が不足しているとして自動承認レビューに拒否された。利用者が「この VM に限って許可する」と明示した後に実行した。読み戻した RDP の規則は TCP/UDP 3389 と Shadow、ICMP は IPv4 の Type 8 と IPv6 の Type 128 だった
- 「Microsoft Store の更新」の手順 5 の待機中に診断した HTTPS の接続先からは HTTP 404・204・200 の応答があった。この応答だけでは Store の検索が完了できるとは判断しない。CLI の故障とも断定していない
- live snapshot は約 8 分進まず、対象 VM の `IProgress.Cancel` で取り消した（`VERR_SSM_CANCELLED`）。snapshot は保存できていない。この検証環境の復旧経過を、「Microsoft Store の更新」の手順 5 の CLI 障害とは断定しない
- 05:09 UTC の pause 中に差分 VDI 11.7 GB・USB VHD 188 MB と VM 情報をホストの一時保存先へコピーし、resume した。`clonemedium` は書き込みロックで失敗し、独立した全ディスク clone は取得できていない。既存の親ディスク・過去 snapshot は維持した
- ユーザーの承認後、05:29:11 UTC に `poweroff` が成功した。最初の再起動は接続中の Rufus USB から Windows Setup の言語・キーボード画面へ戻った。「次へ」やインストールは操作していない
- 05:31:53 UTC に再び `poweroff` し、Rufus USB の接続を `none` にした。媒体ファイルは削除・変更していない。05:32:22 UTC に Windows のルート差分 VDI から起動した
- Guest Additions 7.2.20 のサービスは Running・Automatic で、認証した GuestControl の読み取り probe は終了コード 0 で戻った。読み取り記録の最終起動は 05:36:42.500 UTC。05:38:02 UTC に起動時の更新画面が終了し、Windows のロック画面へ移った。この時点で UI 入力を止め、`<WIN_USER>` の手動サインインを待った
- 認証した GuestControl の monitor は成功し、管理者・通常権限の両タスクは Ready、原基準記録の SHA256 も一致した。再起動前の「Microsoft Store の更新」の手順 5 の記録は `step_started`・`running` のまま。`finished` の時刻は前の「Microsoft Store の更新」の手順 2 より古く、「Microsoft Store の更新」の手順 5 の終了を示していない
- 復旧直後の読み取りでは Store プロセスは 0 個だった。初回の「Microsoft Store の更新」の手順 5 は更新 31 件の全一覧を採取できたが、CLI の自然終了と終了コードは確認できず、強制停止による中断として扱う
- サインイン後に管理者の「Windows Update」の手順 2・3・7 と通常権限の「Microsoft Store の更新」の手順 2・5 を再実行した。「Windows Update」の手順 7 は更新 0 件・再起動待ちなし、「Microsoft Store の更新」の手順 5 はエラーなし・終了コード 0 で正常終了した。この時点では「Microsoft Store の更新」の手順 5 の出力の回収を待っていた
- 「Microsoft Store の更新」の手順 5 の再実行が完了した後、08:51:06 UTC に VirtualBox の VM が aborted になった。ホストのログは画面数の変更の直後に例外 `0xc0000005` を記録していた。ログを保存し、対象 UUID を指定して GUI で起動し直した。Store コマンドのエラーとは判定していない
- 08:54:41.069 UTC に VM が起動し、再び Windows のロック画面を確認した。手動サインインを再依頼して待っていた。この時点では指定ユーザーのログオン失敗でゲストのファイルを回収できなかった
- ホストに出た以前の無人インストール用ファイルの削除確認は Escape で取り消し、ファイルは削除していない
- その後、ホストの接続用の認証情報の不一致を確認し、GuestControl の接続を復旧した。ゲストのパスワードは再変更していない。回収した「Microsoft Store の更新」の手順 5 の出力は `No updates found.` で、エラーの記録は空配列だった。「Microsoft Store の更新」の手順 6 は飛ばし、同じ項の手順 7 は手動サインイン後に実行する予定
- 接続復旧後の読み取りでは Explorer・VBoxTray のプロセスがなく、`Win32_ComputerSystem.UserName` は空だった。この時点はログオフ状態で、再サインインを待った
- ログオン前の補助読み取りでは、Store 22608.1401.5.0・App Installer 1.29.379.0・Terminal 1.24.12741.0 は Status 0（Ok）だった。その後、利用者の再サインインを確認して「Microsoft Store の更新」の手順 7 を実行し、10:10:39.719 UTC に正常終了した
- 「アプリを入れる」の手順 1・2 の初回バッチ `20261006-101239Z-3352f6ed` では、「アプリを入れる」の手順 1 の出力は空でエラー 0 件、同じ項の手順 2 は `scoop` 未検出でエラー 1 件・タスク結果 1 だった。補助ハーネスの dot-source 呼び出しが、Scoop の公式インストーラーの「関数だけを読み込む」分岐に入り、実インストールを行っていなかった。「アプリを入れる」の手順 1 の呼び出しだけをハーネス側で直し、本文のコマンドは変えずに再実行すると導入と確認が成功した
- 「アプリを入れる」の手順 3 では、依存関係の `vcredist2022_x64.exe` と管理者確認のプロセスを確認した。実ファイルは Microsoft Corporation の有効な署名で、製品は Microsoft Visual C++ v14 Redistributable x64 14.51.36247、版は 14.51.36247.0 だった。取得した GUI の画面は黒く、実際の UAC の文言は観察できていない。利用者が管理者確認を許可した後、VC x64 の HKLM の `Installed=1` と `Version=v14.51.36247.00`、UniGet UI の導入成功の出力を確認した
- 補助のユーザー別アプリの読み取りでは、UniGet UI 2026.3.0 の HKCU 登録と `%LOCALAPPDATA%\Programs\UniGetUI` の本体、`UniGetUI.exe` の版 2026.3.0.0、scoop-search の実ファイルを確認した
- 続く source 未指定の `winget list` は `msstore` の初回同意待ちになった。対象の引数と親プロセスを確かめて一覧確認の CLI を中断した。これは操作側による中断として扱い、自然な検索失敗とは判定しない。「アプリを入れる」の手順 3・4・5 の一覧確認の 3 行だけに `--source winget` を足し、「アプリを入れる」の手順 3 の再実行で一覧の正常表示と終了を確認した
- 「アプリを入れる」の手順 4・5 の実体確認は読み取りエラー 0 件だった。画面の取得は対象を選び直しても 2 回 `foreground window did not report a process id` となり、CLI は正常に応答していた。GUI の操作や表示は確認済みにはしていない
- 「WSL と再起動」の手順 2 の再起動要求後、黒画面・GuestControl 未応答から暫定的に新しい起動を未確認としていた。後回収のイベントと停止時に保存した VBox.log で、11:39 に OS が再起動していたことを確認し、記録を訂正した。VBox.log には HyperV Reset・ACPI Reset と RESETTING/RUNNING、ゲスト VBoxService の 11:39:13.394 UTC のログ開始、graphics capability Yes があった
- 検証側の最後の GuestControl の失敗確認は新しい起動より前の 11:38:45 UTC で、強制停止直前の再応答の確認が不足していた。強制停止案は当初、別の明示承認が必要として自動承認レビューに拒否された。その後、利用者が「承認します」と明示して強制停止・退避・復旧起動を行った。イベント 41・6008 は後の強制停止後の復旧起動時に発生したもので、「WSL と再起動」の手順 2 の自然な再起動の失敗を示すものとして扱わない。Minidump は 0 件、読み取りエラーは 0 件だった
- 停止後に差分 VDI（約 22.95 GB）・設定・NVRAM・ログの計 4 ファイルを退避し、すべて元と退避先の SHA256 が一致した。11:47:42 UTC に退避の記録を保存した。差分ディスクなので既存の immutable の親が必要で、独立した全ディスク clone ではない。その後に利用者の手動サインインと、「WSL の AlmaLinux 10 と自動サインイン」の手順 2 と「再起動の後に確かめる」の手順 2 の一部を確認した
- 「WSL の AlmaLinux 10 と自動サインイン」の手順 2 の確認時点では CLI が正常に応答した。画面が黒くなった際は 1 回のクリックで戻り、表示が消えていた状態として扱う。この時点の観察を VM のハングとは判定しない
- 利用者の希望で検証を一度中断し、`<OTHER_PC>` へ引き継いで続行する予定とした。この中断中は追加の VM 操作を行わず、検証結果の保存と未実施の範囲の整理のみを行った。中断時点では「WSL の AlmaLinux 10 と自動サインイン」の手順 5 は実行していなかった
- 2026-10-07 JST に、利用者の指示で `<HOST_PC>` の元の VM で再開した（以下の時刻は 2026-10-06 UTC）。元の VM は poweroff、状態変更時刻は 14:54:57 UTC だった。同じ UUID を `--type separate` で起動し、ゲストの LastBoot は 17:09:21.5 UTC。利用者の手動サインイン「完了」の後、CIM のユーザーと Explorer・PowerToys・UniGet UI の Session 1 の実プロセス、両検証タスクの Ready を確認した
- 「WSL の AlmaLinux 10 と自動サインイン」の手順 5 の Autologon64.exe の SHA256 は `5D96BBC4E5B726D87C7CF547F5FE98F8F05434EC2130BD60CBF5671FD3A7381B`。17:33:57.0822889 UTC の確認ではタスクは Running、Consent は Session 1 で、利用者の UAC と有効化の操作を待っていた。自動入力の `u` はスタートの検索に届かず画面が閉じ、GUI のキー入力の到達は未確認のまま。この時点では「再起動の後に確かめる」の手順 2 の Bing・同じ項の手順 3・4 は合格としていなかった。最新の VBox ログでも NEM の Hyper-V mode を確認し、WSL と入れ子の VM は再実行せず、ホストのセキュリティ設定も変更していない
- 「WSL の AlmaLinux 10 と自動サインイン」の手順 5 は導入成功の後、Autologon の起動要求が取り消されて終了した。利用者は UAC・パスワード・Enable の依頼に「VMが無かった」と回答し、取消の原因は未特定。設定は未実施で、自動サインインも未検証のまま
- `<HOST_PC>` のホストのイベント 1000 は 17:35:36 UTC に VirtualBoxVM.exe の Qt6GuiVBox.dll+0xd5c74・0xc0000005、17:35:41 UTC に 0xc000041d を記録した。直前の VBoxUI.log には host-screen count changed が 6 回あった。一方、VBoxHeadless は running、ゲストの LastBoot 17:09:21.5 UTC と Explorer のログインを維持していた。表示プロセスの障害として記録し、「WSL の AlmaLinux 10 と自動サインイン」の手順 5 の取消原因の確定とは扱わない。証跡を `evidence/frontend-crash-20261006-173536` に保存した
- 21:57:23.0140619 UTC の最初の GUI だけの再接続は、VBoxUI.log の aboutToQuit が 10.346 秒で、ウィンドウの復旧を確認できなかった。その後、利用者は表示しているホスト PC が `<HOST_PC>` と回答した
- 2 回目は `VBoxManage startvm <VM_UUID> --type separate` で GUI のウィンドウが戻り、PID 14420・ウィンドウ 1507508 のホストメニューを実画面で確認した。ただしゲストは黒画面だった。VBox.log には `DetachFramebuffer: Invalid framebuffer object` と `AttachFramebuffer: Framebuffer already attached to 0` があり、経過時間 01:37:41 の実際の heartbeat unresponsive は回復を確認できていない。この検知だけでゲスト OS の停止を確定しない
- GuestControl の新しいセッションは starting のままタイムアウトした。22:04:23.928 UTC の ACPI による通常終了要求から約 3 分後も VM は running で、通常終了は未確認だった。強制停止による復旧だけを利用者に明確に確認した
- 22:07:34 UTC ごろの一時停止中に、active VDI（25,531,777,024 バイト）・vbox・NVRAM の 3 データを `%TEMP%\recovery-backup-frontend-20261006-220734` へコピーし、すべて元とコピーの SHA256 が一致した。一方、稼働中の VBox.log のハッシュ確認は file-in-use で失敗し、3 データの照合結果とは分ける。RAM は保存しておらず、差分 VDI のため親 VDI が必要で、独立した clone ではない。`evidence/frontend-reattach-20261006-215723/backup-manifest.json` に記録した。finally の resume は 22:09:27.292 UTC に完了し、VM は running と確認した
- 利用者が今回の明確な確認に「起動し直してよいです」と回答した後、22:28:04.227054 UTC に対象 VM の poweroff を確認し、同じ UUID を separate で起動した。直後の running 判定は早すぎてコマンドが終了コード 1 になったが、再び start は行わず、22:28:27.944 UTC の読み取りで running、VMStateChangeTime 22:28:13.867 UTC を確認した
- この 4 CPU の起動では Guest Additions は level 1・base driver までロードした。bootmgfw.efi・Windows の kernel ID・WDDM/USB の記録はあるが、経過時間 28.940 秒以降は 5 分を超えて進展を確認できず、約 11 分 55 秒の観測でも VBoxService に到達しなかった。この試験ではデスクトップとサインインは復旧しなかった
- 切り分けとして提案した CPU 数 4→2 は、自動承認レビューが「CPU の永続設定変更の明示承認がなく、再起動の許可だけでは不足」として実行前に拒否した。その時点では変更せず、この変更について利用者に明確な承認を依頼した
- 利用者が CPU 数の比較に「承認します。」と回答した後、22:40:04.323245 UTC に poweroff を確認し、4→2 の設定と読み戻しを行った。separate の起動要求は 22:40:04.5050719 UTC、VMStateChangeTime は 22:40:09.392 UTC、22:40:45.3348627 UTC に running を確認した
- 2 CPU の起動は、経過 57.677 秒に VBoxGuest、62.560 秒に WDDM、83.716 秒に VBoxService（ゲストの時刻 22:41:30.328 UTC）、84.340 秒に graphics まで進み、Windows のロック画面を実画面で確認した。22:42:21.189987 UTC に GuestControl が成功し、LastBoot 22:40:23.5 UTC を読み戻した。この時点では CIM のユーザーは空、LogonUI は Session 1 で、手動サインインは未完了だった。両検証タスクは Ready で、通常権限タスクの結果 1 は前の「WSL の AlmaLinux 10 と自動サインイン」の手順 5 の取消を保持していた。証跡は `evidence/restart-20261006-222804/VBox-cpu2-ready.log`・`cpu2-diagnostic.json` に保存した。CPU 数以外のハードウェアとホストのセキュリティ設定は変更していない。比較で復旧した結果であり、原因を確定したものではない
- この時点では 2 CPU のままで検証を続けることにし、4 CPU に戻す再試験は行っていなかった。利用者の「完了」の回答後、22:52:26.7068317 UTC の読み取りでユーザー `<HOSTNAME>\<WIN_USER>`、Explorer（PID 2676・7916）と VBoxTray（PID 8868）の Session 1 を確認し、手動サインインは完了した。LastBoot は 22:40:23.5 UTC のままで、通常権限タスクは Ready、前の取消による結果 1 を保持していた。この時点では Autologon は未設定で、再び開く補助コード `relaunch-autologon.ps1` も VM では実行していなかった
- 通常権限タスクで Autologon の新しい起動要求 `20261006-225840-29f9cb04` を 1 回行い、22:58:52.2323842 UTC に要求を完了した。補助コードは実体のハッシュ・Microsoft の署名の確認を通過し、22:59:32.8630346 UTC は Consent の Session 1・通常権限タスク Running だった。今回の UAC 文言は画面取得で確認できず、利用者は「VMの画面にはデスクトップしか映っていません」と回答した
- この要求の完了記録は、開始 22:58:55.1901170 UTC・終了 23:00:58.8458588 UTC・result fail、Start-Process の「この操作はユーザーによって取り消されました」、native_code null だった。利用者が取消を押したかどうかと、取消の原因は未確認。23:05:02.7386707 UTC の GuestControl は同じ LastBoot 22:40:23.5 UTC と `<WIN_USER>`・Explorer の Session 1、Autologon64 と Consent の不在、通常権限タスク Ready・結果 1 を確認した。完了記録は `evidence/autologon-relaunch-20261006-225840-29f9cb04/guest-launch-result.json` に保存した。同じ裏のタスクからは起動を繰り返さず、署名済みの実体を Explorer で選択表示する要求を 1 回行った。この時点では表示成功は未確認で、Autologon の設定と次回起動の自動サインインも未確認だった
- 選択表示の補助コードの記録は 23:07:24.3667475 UTC で、実体の SHA256 一致・有効な Microsoft の署名・`<WIN_USER>` の Session 1 を確認し、Autologon 自体の起動と設定操作は行っていない。23:08:18.8449035 UTC の GuestControl では、通常権限タスク Ready・結果 0、対象 Autologon フォルダーを開いた Explorer（PID 4156）の Session 1、Autologon と Consent の不在を確認した。完了記録 `explorer-display-result.json` を保存した。Explorer を開く処理は成功したが、画面取得は新しく選び直しても 2 回 CreateForMonitor の 0x80070057 で失敗し、画面の視認は未確認。UI 入力を止め、利用者にタスクバーの Explorer から選択された実体を手動で起動し、製品・発行元を確認して設定する操作を依頼した。この時点では Autologon の設定と次回起動の自動サインインは未確認だった

- 利用者が Explorer から Autologon を手動で起動し、UAC・パスワードと Enable・成功表示・終了を行ったと「完了」で報告した。23:16:09.4770037 UTC の読み取りでは、Winlogon の指定した 3 値だけ（AutoAdminLogon=1・DefaultUserName=`<WIN_USER>`・DefaultDomainName=`<HOSTNAME>`）を確認した。秘密値は読み取っていない。Autologon と Consent は不在、両検証タスクは Ready・結果 0、LastBoot は 22:40:23.5 UTC だった
- 23:17:36.0232656 UTC に通常の OS 再起動 `shutdown.exe /r /t 10` を 1 回要求し、終了コードは 0、ホストからの poweroff は行っていない。利用者には検証中の VM に入力しないよう事前に伝え、検証側も GUI 入力・認証操作を行っていない。23:19:40.9676058 UTC の GuestControl は終了コード 0 で、LastBoot 23:18:13.5 UTC、ユーザー `<HOSTNAME>\<WIN_USER>`、Explorer（PID 5656・7920）と PowerToys（PID 5528）の Session 1、LogonUI・LockApp・Autologon・Consent の不在、両タスク Ready・結果 0 と指定 3 値の保持を確認した。2 CPU の条件で、手動設定後の無入力の自動サインインを合格とした。本文と補助タスクの Start-Process の取消履歴は維持し、元の起動経路の成功に置き換えない。前後の読み取りと再起動要求は `evidence/autologon-reboot-20261006-2316` に保存した。その後、利用者はホストの通常デスクトップと、VM が見えないことを報告した。ホストのイベントでは VirtualBoxVM（PID 26348）が 23:28:23.7379115 UTC に Qt6GuiVBox.dll+0xd5ec6・0xc0000005、23:28:27.2549383 UTC に 0xc000041d を記録した。原因は未確定で、ゲストは同じ起動とサインインを維持した。表示の再接続 1 回は終了コード 0 だったが、別の表示プロセスは 10.330 秒で aboutToQuit となり、ウィンドウは戻らなかった。強制オプションなしの通常 OS 終了要求はホスト時刻 23:33:55.791 UTC に終了コード 0、VM の poweroff は 23:34:08.177 UTC。同じ 2 CPU の設定で separate 起動を 1 回要求した時刻は 23:34:45.0165607 UTC、終了コード 0、running の状態変更は 23:34:50.521 UTC だった。ゲスト時刻 23:36:42.8632541 UTC の読み取りでは LastBoot 23:35:01.5 UTC、`<WIN_USER>`、Explorer・PowerToys の Session 1、両タスク Ready・結果 0、認証画面なしを確認した。新しいウィンドウで Windows の起動画面から実際のデスクトップを視認し、再度の自動サインインも CLI で確認した。証跡は `evidence/frontend-reattach-20261006-2330` に保存した。その後、利用者の手動の最大化・前面表示の「完了」を受け、その時点で実際のデスクトップ（1057×1143）の最大化を視認した。Edge のピンの右クリックは対象を選び直した 1 回の再試行でも failed to activate captured window となり、GUI 入力を停止した。この時点では「再起動の後に確かめる」の手順 2 の Bing、同じ項の手順 3 のピン、同じ項の手順 4 の UniGet UI の操作は未確認で、利用者にまとめて手動の確認を依頼し、UniGet UI を開いたままの報告を待っていた。ゲスト時刻 23:50:04.3380797 UTC の読み取りでは同じ LastBoot 23:35:01.5 UTC と `<WIN_USER>`、UniGet UI 2026.3.0.0・有効な Devolutions Inc の署名・Session 1 のプロセスを確認した。23:50:48.0115251 UTC に Get-StartApps の Name=UniGetUI・AppID=Devolutions.UniGetUI でスタートの入口も確認したが、これらは GUI の起動・検出・一覧確認の代用にはしない。最新のウィンドウを選び直した画面取得は 1057×1143 の内部が黒く、1 回の再取得も黒かった。23:57:21.8597671 UTC の GuestControl は同じ LastBoot 23:35:01.5 UTC、`<WIN_USER>`、Explorer と UniGet UI の Session 1 で正常に応答した。この時点では画面内容を確認できず、「再起動の後に確かめる」の手順 2〜4 の結果待ちを維持していた。その後、最後の 3 点について利用者が「問題ありませんでした。」と回答し、Bing/Web の結果なし、不要な Edge/Store のピン解除、UniGet UI の WinGet/Scoop 有効と scoop-search/UniGetUI の導入済み一覧を、利用者の手動確認として合格とした。AI はこれらの画面を確認できていない。この質問では、ピン解除の正確な文言、UniGet UI のスタートからの起動と WinGet/Scoop の GUI の版表示は未確認だった。その後に後者と通常窓での LF 3 行の右クリック貼り付けを依頼し、利用者が「確認しました。」と回答した。「再起動の後に確かめる」の手順 4 の起動経路と GUI の版表示、「WSL の AlmaLinux 10 と自動サインイン」の手順 1 のスタートから開く通常権限の Windows PowerShell 5.1、「貼り付けの設定」の手順 1〜4 と「PC 全体の設定」の手順 4 の今回の fixture による paste-line-1→2→3 の順序を利用者手動確認として合格とした。AI の画面確認は未実施、GitHub のコピーボタンからの直接経路・管理者窓への貼り付け・ピン解除の正確な文言は未試験

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
- WireGuard は管理者の Windows PowerShell 5.1 で wireguard-road-warrior.md の「Windows 11 で WireGuard と鍵を用意する」の手順 6 を変更せず実行し、45 bytes・ASCII・LF の鍵ペアと公開鍵の対応、Administrators と SYSTEM だけの ACL を確認した。管理サービスは公式 CLI による一時的な起動・削除で検証した。鍵とサービスとプロセスは削除し、検証タスクの要求ファイルも元に戻した。新しくできた管理サービスの Data は残し、設定ファイルは 0 件だった。鍵の内容・ハッシュは記録していない。「Windows 11 で WireGuard と鍵を用意する」の手順 5 の GUI と VPN 接続は未確認。証跡は `evidence/remaining-wireguard-local-20261007-094630-d8f8efb9`。
- RDP は、ゲストに設定された公開証明書を読み取り、SHA256・名前・有効期間を照合して TLS 1.3（`TLS_AES_256_GCM_SHA384`）を確立した。CredSSP の選択後の TLS までで、RDP の資格情報は送信していない。終了コード 0、一時的なループバック転送と待受けの撤去を確認した。認証後のログインと ping は未確認。証跡は `evidence/remaining-rdp-tls-20261007-095055-a37a84b1`。

- スタートアップの追加試験では、新規の Run 項目 2 つに StartupApproved の先頭バイト 2（有効）・3（無効）を設定し、通常の OS 再起動を 1 回行った。起動から 122 秒の最初の読み取りは両記録がなく、確認不能・VBox CLI 終了コード 33 だった。その失敗記録を保持した。有効側は遅れて Explorer の Session 1 から起動し、その記録から 160.754 秒後の読み取りで無効側の記録がないことを確認した。後の観測と後片付けは終了コード 0、今回の Run 2 値・承認 2 値と専用ディレクトリを削除した。既存 OneDriveSetup の参照先は存在しないため、この結果を OneDrive・Teams 本体の次回起動の合格には広げない。証跡は `evidence/remaining-startup-20261007-f0126d5a`。

**未試験・環境未達の範囲**:

1. Windows Update の再起動の分岐（「Windows Update」の手順 8）
1. Store の初回 CLI 準備（「Microsoft Store の更新」の手順 3・4）、「Microsoft Store の更新」の手順 6 の更新適用
1. GUI の残る効果、GitHub の直接コピー経路と管理者窓への貼り付け、ピン解除の正確なメニュー文言
1. 認証情報送信・認証後の RDP ログインと ping（TCP 到達・事前交渉・証明書の照合による TLS の確立まで追加検証済み）。「PC 全体の設定」の手順 5 と「サインイン・検索・キーボード」の手順 5・6 の変更する分岐は条件により飛ばした
1. 「WSL と再起動」の手順 2 による最初の起動の対話画面への到達、「WSL の AlmaLinux 10 と自動サインイン」の手順 5 の本文と補助タスクからの起動経路、任意節、更新とロールバック。後続ツールは Firefox の既定・コーデック、VirtualBox Manager、WezTerm の GUI、Claude Code の認証、WireGuard の実接続などが未確認。「WSL の AlmaLinux 10 と自動サインイン」の手順 3・4 の WSL 2 と入れ子の VM の実起動は、この検証環境では未達
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
| 「Windows Update」の手順 1〜7 | 管理者の窓で「Windows Update」の手順 2〜4・6・7 を貼った。対象の更新は 0 件で、`Windows Update の確認完了（対象の更新なし・再起動待ちなし）`。「Windows Update」の手順 5・8 は条件に当たらなかった |
| 「Microsoft Store の更新」の手順 1〜7 | 「Microsoft Store の更新」の手順 2 で Store 22608.1401.5.0 と `store.exe`・`winget.exe`。「Microsoft Store の更新」の手順 5 は `No updates found.`。「Microsoft Store の更新」の手順 3・4・6 は条件に当たらなかった |
| 「PC 全体の設定」の手順 1 | スタートで「Windows PowerShell」を右クリック →「管理者として実行」。UAC の確認（Windows PowerShell、発行元 Microsoft Windows。既定のボタンは「いいえ」）で「はい」を選ぶと、「管理者: Windows PowerShell」の conhost の窓（`ConsoleWindowClass`）が開き、プロファイルのエラーは出なかった |
| 「PC 全体の設定」の手順 2・3 | GitHub のコピーボタンから管理者の窓に貼った。`Admin : True`・`CtrlEnter : AddLine`・Professional・26H2・26300.9457・`LanCategory : Private`・`RemoteDesktop : 0`・`RemoteAssistance : 0`・`HelloOnly : 0`・`Keyboard : kbd106.dll`・`Hypervisor : True`・配信の最適化 `Lan` |
| 「PC 全体の設定」の手順 4 | 管理者の conhost の窓に右クリックで貼ると、最後の `}` の後で止まり、Enter で `1 行目`・`2 行目`・`3 行目` の順に出た（逆順にならない） |
| 「PC 全体の設定」の手順 5（PC の名前を変える分岐） | `$PC_NAME = 'PR104-VERIFY'` で「PC 全体の設定」の手順 2 を貼り直し、「PC 全体の設定」の手順 5 は警告と `再起動の後に PR104-VERIFY になる`。再起動の前に貼り直しても同じ出力 |
| 「サインイン・検索・キーボード」の手順 5・6（UTC と US 配列の分岐） | 「サインイン・検索・キーボード」の手順 5 で `RealTimeIsUniversal : 1`、同じ項の手順 6 で `kbd101.dll`・`PCAT_101KEY`・`7`・`0` |
| 「WSL と再起動」の手順 2 | `Restart-Computer` の後、自動サインインでデスクトップに戻った（Autologon の `DefaultDomainName` が元の名前 `<HOSTNAME>` のままでも通った） |
| 「再起動の後に確かめる」の手順 1 | ホストからのキーで確かめた。US 配列で Shift+2 が `@`、Caps Lock+A で全選択（Caps Lock だけでは大文字にならない）、Ctrl+Space で IME がオン（「あ」、変換の候補が出る）とオフに入れ替わった |
| 「再起動の後に確かめる」の手順 2 | スタートの検索に Web の結果が出なかった。エクスプローラーは「PC」を開き、拡張子と隠しファイルが見え、ファイルの右クリックで「送る」「プロパティ」のある旧形式のメニュー。タスクバーは左寄せで、タスク ビュー・検索・ウィジェットのボタンが無く、時計に秒。全体が濃い色 |
| 「再起動の後に確かめる」の手順 3 | タスクバーのアイコンの右クリックのメニューの文言は「タスクバーからピン留めを外す」で、本文の「タスク バーからピン留めを外す」と違ったので直した。スタートのピン留めの右クリックは「スタートからピン留めを外す」で、本文どおり。Edge はスタートにピン留めされたまま残した |
| 「再起動の後に確かめる」の手順 4 | スタートから UniGet UI 2026.3.0 を起動した。左の「パッケージマネージャー」で WinGet と Scoop が有効・「利用可能」。版はそれぞれの「バージョンを表示」で出た（WinGet v1.29.380、Scoop v0.6.0 - Released at 2026-09-30）。本文の「見つかっている（版が出ている）」と違ったので直した。インストール済みの一覧に `scoop-search` 2.1.0（Scoop: main）と `Devolutions.UniGetUI` 2026.3.0 |
| 「WSL の AlmaLinux 10 と自動サインイン」の手順 1・2 | スタートから開いた通常の Windows PowerShell は、Windows Terminal の中に開いた。「WSL の AlmaLinux 10 と自動サインイン」の手順 2 を GitHub のコピーボタンからコピーして右クリックで貼ると、「警告 複数の行を含むテキストを貼り付けようとしています…」の確認（「強制的に貼り付け」「キャンセル」）が出た。強制的に貼り付けると、完結した行から順に動いた。`ComputerName : PR104-VERIFY`・`Keyboard : kbd101.dll` などが出た |
| 「WSL の AlmaLinux 10 と自動サインイン」の手順 5（本文の起動経路） | Windows Terminal の通常の窓に貼った。winget は入っている旨（`Found an existing package already installed.`・`No available upgrade found.`、英語）を出し、UAC の確認（Autologon、Microsoft Corporation、このコンピューター上のハード ドライブ）で「はい」を選ぶと Autologon の窓が開いた（`Username` が <WIN_USER>、`Domain` が <HOSTNAME>）。パスワードを入れて `Enable` を押すと `Autologon successfully configured.` の旨。以後の再起動で、入力無しに自動サインインした |

- 「PC 全体の設定」の手順 5 と「サインイン・検索・キーボード」の手順 5・6 の分岐は、[ロールバック](../extra/windows-setup.md#ロールバック)の「サインイン・検索・キーボードを戻す」の手順 1・2・9・10、「ネットワークと PC 全体の設定を戻す」の手順 9、「再起動と PSWindowsUpdate」の手順 1 で戻した。ロールバックの「再起動と PSWindowsUpdate」の手順 1 の再起動の後、名前は `<HOSTNAME>`、キーボードは `kbd106.dll`・`PCAT_106KEY`・`7`・`2`、`RealTimeIsUniversal` は無し。ロールバックの「サインイン・検索・キーボードを戻す」の手順 10 は何も出さなかった
- 時計: `RealTimeIsUniversal=1` で起動すると、システムの時刻が 9 時間進み、VBoxService が 32,369,482 ミリ秒戻した（VM の RTC は地方時）。ロールバックの再起動では逆に 9 時間遅れ、32,418,700 ミリ秒進めた。本文の「再起動の後に、時刻を同期し直す」に当たる
- 実施手順の「WSL の AlmaLinux 10 と自動サインイン」の手順 3・4 の WSL 2 は扱っていない（この VM では動かない。上の付録）

**ping とリモート デスクトップ（2 枚目の NIC で）**:

- 2 枚目の NIC を足した直後（パブリック）は、外からの ping が届かなかった
- 管理者の窓で、「PC 全体の設定」の手順 2 の `$LAN_IF` を `'イーサネット 3'` に直して貼り、同じ項の手順 8（`AllowComputerToTurnOffDevice : Disabled`。`WakeOnMagicPacket` は `Unsupported`）と「ネットワークとリモート」の手順 1（Private）・2（RDP の 3 規則が Private）・4（ping の 2 規則）を貼った
- AlmaLinux の 2 台とホストからの ping は、どれも 0% loss
- RDP: AlmaLinux の VM の FreeRDP から、試験用の資格情報で 192.168.56.107 につないだ。Kerberos は失敗して NTLM で認証され、ログインできた
  - `quser` で `rdp-tcp#0` が Active。RDP のセッションの画面（1280x800、`TerminalServerSession : True`）を撮った。PC の画面はロック画面になった
  - 切断すると `Disc`。昇格したプロセスから `tscon.exe <ID> /dest:console` を実行すると、`console` が Active に戻り、PC の画面はロックされていなかった
- 再起動すると、ホストオンリーのネットワーク（既定ゲートウェイの無い「識別されていないネットワーク」）の「イーサネット 3」はパブリックに戻った。NAT の「イーサネット」はプライベートのまま。以後、2 枚目の NIC を使う確認の前に「ネットワークとリモート」の手順 1 を貼り直した

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
- この節の「表示と入力を戻す」の手順 1〜9 と「アプリと貼り付けの設定を外す」の手順 1〜8 は、管理者ではない Windows PowerShell（Windows Terminal の中）に貼った

| この節の手順 | 結果 |
|---|---|
| 「表示と入力を戻す」の手順 1 | `HideFileExt : 1`・`Hidden : 2`・`Start_TrackDocs : 1`、`LaunchTo` は出なかった |
| 「表示と入力を戻す」の手順 2 | `この操作を正しく終了しました。` と `False` |
| 「表示と入力を戻す」の手順 3 | 8 つの値がすべて `1` |
| 「表示と入力を戻す」の手順 4 | 3 つの値は何も出なかった。画面のタスクバーは中央寄せで、検索ボックスとタスク ビューのボタンが出た |
| 「表示と入力を戻す」の手順 5 | `1` が 2 つ。画面が淡色になった |
| 「表示と入力を戻す」の手順 6 | 2 つの値は何も出なかった |
| 「表示と入力を戻す」の手順 7 | Microsoft IME の設定の画面が開いた。「キーとタッチのカスタマイズ」を開くと、「キーの割り当て」の「各キー / キーの組み合わせに好みの機能を割り当てます」のスイッチが「オン」で、「Ctrl + Space」は「IME-オン/オフ」（選択肢は「IME-オン/オフ」と「なし」）。本文の 2 つの方法のうち、スイッチをオフにした。`IsKeyAssignmentEnabled` が 0 になった（`KeyAssignmentCtrlSpace` は 2 のまま） |
| 「表示と入力を戻す」の手順 8 | `戻した: MicrosoftEdgeAutoLaunch_<番号>` と `戻した: OneDriveSetup`（Teams のキーは無かった） |
| 「表示と入力を戻す」の手順 9 | 約 15 分かかった。11 個の ID のうち 9 個と Teams（`Microsoft.Teams` 26198.304.4946.9672）は `Successfully installed` で入った（Clipchamp・天気・Office Hub・To Do・フィードバック Hub・問い合わせ・Power Automate・Outlook・ウィジェットの Windows Web Experience Pack）。入らなかった 2 つは次のとおり |
| 「表示と入力を戻す」の手順 9（ニュース `9WZDNCRFHVFW`） | `Failed to install or upgrade Microsoft Store package. Error code: 0x80073cfb`。AppX のイベント 404・474 は、イメージに残っていた `Microsoft.BingNews_1.0.2.0_x64__8wekyb3d8bbwe`（SYSTEM 用に Staged）と同じ ID で中身が違うので展開を止めた、というものだった |
| 「表示と入力を戻す」の手順 9（Solitaire `9WZDNCRFHWD2`） | `No package found matching input criteria.`（msstore のソースにその ID が無い。名前で探しても見つからなかった） |
| 「表示と入力を戻す」の手順 9（登録し直し） | どちらも PC にプロビジョニングされたパッケージとして残っていたので、`Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.BingNews_8wekyb3d8bbwe`（と Solitaire の同じ形）で登録し直すと、`Microsoft.BingNews` 1.0.2.0 と `Microsoft.MicrosoftSolitaireCollection` 4.27.9181.0 が `Ok` になった。本文に箇条書きを足した |
| 「アプリと貼り付けの設定を外す」の手順 1〜3 | PowerShell 7・PowerToys（`PowerToys (Preview) x64`）・UniGet UI とも `Successfully uninstalled`、続く `winget list` は `No installed package found matching input criteria.`。動いていた PowerToys と UniGet UI は閉じられた |
| 「アプリと貼り付けの設定を外す」の手順 4（本文のまま） | `Are you sure? (yN):` に `y` を入れると、`Uninstalling 'scoop-search'` の後に `WARN  Couldn't remove ~\scoop\apps\scoop-search: 項目 …\current を削除できません: パス 'current' へのアクセスが拒否されました。` と、`Couldn't remove ~\scoop\apps: …` で止まった。`Scoop has been uninstalled.` は出ず、scoop 本体は消えていた（貼り直すと `scoop.ps1` が見つからない旨）。ユーザーの PATH に `scoop\shims` が残った |
| 「アプリと貼り付けの設定を外す」の手順 4（原因） | `current` のジャンクションに読み取り専用の属性が付いていた。scoop 0.6.0 の `bin/uninstall.ps1` は、アプリの `current` の読み取り専用を外さずに消そうとする（[参考資料](../reference/windows-setup.md)） |
| 「アプリと貼り付けの設定を外す」の手順 5（本文のまま、同じ項の手順 4 が止まった後） | `Remove-Item … -ErrorAction SilentlyContinue` も消せず、`True`・`False`。`attrib.exe -R /L` で `current` の読み取り専用を外してから貼り直すと、`False` が 2 行になった。PATH の `scoop\shims` は残った |
| 「アプリと貼り付けの設定を外す」の手順 4（直した形） | 「アプリを入れる」の手順 1・2 と `scoop install scoop-search` で入れ直し（`current` は `ReadOnly, Directory, ReparsePoint`）、1 行目に `current` の読み取り専用を外す行を足したブロックを貼った。`y` を入れると `Uninstalling 'scoop-search'`・`Removing ~\scoop\shims from your path.`・`Scoop has been uninstalled.` で終わり、ユーザーの PATH から `scoop\shims` も消えた。本文をこの形に直した |
| 「アプリと貼り付けの設定を外す」の手順 5（直した同じ項の手順 4 の後） | `False` が 2 行 |
| 「アプリと貼り付けの設定を外す」の手順 6 | `消した: C:\Users\<WIN_USER>\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`（プロファイルにはその 1 行だけがあった） |
| 「アプリと貼り付けの設定を外す」の手順 7 | `$OLD_EXECUTION_POLICY = 'Undefined'`（2026-10-06 の実施手順の「貼り付けの設定」の手順 2 の記録）で、表の `CurrentUser` を含むすべてが `Undefined` |
| 「アプリと貼り付けの設定を外す」の手順 8 | `WSL_E_DISTRO_NOT_FOUND`（AlmaLinux-10 は入れられていなかった）。一覧はディストリビューションが無い旨 |
| 「サインイン・検索・キーボードを戻す」の手順 1 | スタートで「Windows PowerShell」を探し、右側の「管理者として実行」を押した。UAC の確認（Windows PowerShell、発行元 Microsoft Windows）で「はい」を選び、conhost の窓が開いた |
| 「サインイン・検索・キーボードを戻す」の手順 1 の後の貼り付け | この節の「アプリと貼り付けの設定を外す」の手順 6 でプロファイルの行を消したので、実施手順の「PC 全体の設定」の手順 4 の 3 行の試験を右クリックで貼ると、`}`・`'3 行目'`・`'2 行目'`・`'1 行目'`・`& {` の逆順に入った（本文のこの節の「アプリと貼り付けの設定を外す」の手順 6 の「右クリックで貼ると、行が逆順になる」のとおり）。Ctrl+C で捨て、Ctrl+V で貼ると `1 行目`・`2 行目`・`3 行目` の順に動いた。この節の「サインイン・検索・キーボードを戻す」の手順 2 から「再起動と PSWindowsUpdate」の手順 1 までは Ctrl+V で貼った |
| 「サインイン・検索・キーボードを戻す」の手順 2 | `LAN_IF = イーサネット` |
| 「サインイン・検索・キーボードを戻す」の手順 3 | 管理者の窓から起動したので UAC の確認は出ず、Autologon の窓（`Username` <WIN_USER>、`Domain` <HOSTNAME>）が開いた。`Disable` を押すと「AutoLogon is disabled.」の窓が出て、「OK」で Autologon も閉じた。`AutoAdminLogon` は 0 |
| 「サインイン・検索・キーボードを戻す」の手順 4（本文のまま、管理者の窓） | `Found Autologon [Microsoft.Sysinternals.Autologon]` の後、`The package installed for user scope cannot be uninstalled when running with administrator privileges.` で外れなかった（「WSL の AlmaLinux 10 と自動サインイン」の手順 5 は管理者ではない窓で `--scope user` で入れる）。続く `AutoAdminLogon` は 0 |
| 「サインイン・検索・キーボードを戻す」の手順 4（管理者ではない窓） | 同じブロックをこの節の「表示と入力を戻す」の手順 1〜9 と「アプリと貼り付けの設定を外す」の手順 1〜8 の窓に貼ると、`Successfully uninstalled` と `0`。`Autologon64.exe` も消えた。本文のこの節の「サインイン・検索・キーボードを戻す」の手順 4 を管理者ではない窓で行う形に直し、節のリードも直した |
| 「サインイン・検索・キーボードを戻す」の手順 5 | `DevicePasswordLessBuildVersion : 2`（2026-10-06 の実施手順の「PC 全体の設定」の手順 3 の記録では `HelloOnly` は 2） |
| 「サインイン・検索・キーボードを戻す」の手順 6・7 | どちらも何も出なかった |
| 「サインイン・検索・キーボードを戻す」の手順 8 | `wsl.exe --uninstall` は何も表示しなかった。`Disable-WindowsOptionalFeature` は `RestartNeeded : True`。WSL のパッケージは消え、仮想マシン プラットフォームは `Disabled` になった |
| 「サインイン・検索・キーボードを戻す」の手順 9 | `kbd106.dll`・`PCAT_106KEY`・`7`・`2`（「サインイン・検索・キーボード」の手順 6 は前の分岐の確認の後に戻してあったので、同じ値の書き直し） |
| 「サインイン・検索・キーボードを戻す」の手順 10 | 何も出なかった |
| 「サインイン・検索・キーボードを戻す」の手順 11 | `Scancode Map を消した` |
| 「ネットワークと PC 全体の設定を戻す」の手順 1 | `$OLD_DOWNLOAD_MODE = 'Lan'`（2026-10-06 の実施手順の「PC 全体の設定」の手順 3 の記録）で `Lan` |
| 「ネットワークと PC 全体の設定を戻す」の手順 2 | 何も出なかった |
| 「ネットワークと PC 全体の設定を戻す」の手順 3 | システムのプロパティの「リモート」タブが開き、「このコンピューターへのリモート アシスタンス接続を許可する(R)」のチェックを入れて「OK」を押すと、窓が閉じた。`fAllowToGetHelp` は 1、リモート アシスタンスの規則 15 個がすべて有効になった（パブリック向けの `RemoteAssistance-In-TCP-EdgeScope` なども）。「ネットワークとリモート」の手順 3 の前の規則の状態は記録していないので、元に戻ったかは確かめられない。本文の「手順 45 の前に無効だった規則（パブリック向けなど）まで有効になりうるので、画面で戻す」の理由は観察と合わないので、箇条書きを観察に合わせて直した |
| 「ネットワークと PC 全体の設定を戻す」の手順 4 | 3 つの規則が `False  Any` |
| 「ネットワークと PC 全体の設定を戻す」の手順 5 | `イーサネット  Public`（2026-10-06 の実施手順の「PC 全体の設定」の手順 3 の `LanCategory` は `Public`） |
| 「ネットワークと PC 全体の設定を戻す」の手順 6 | `AllowComputerToTurnOffDevice : Enabled` |
| 「ネットワークと PC 全体の設定を戻す」の手順 7 | `powercfg /hibernate on` が「システム ファームウェアは休止状態をサポートしていません。」の旨で失敗し、`HibernateEnabled: 0`。本文に箇条書きを足した |
| 「ネットワークと PC 全体の設定を戻す」の手順 8 | `このコンピューターでは sudo が無効化されています。`（本文の「無効になった旨の英語の行を出す」を直した）、`LongPathsEnabled : 0`、`AllowDevelopmentWithoutDevLicense : 0` |
| 「ネットワークと PC 全体の設定を戻す」の手順 9 | `$OLD_PC_NAME = '<HOSTNAME>'` で `すでにこの名前: <HOSTNAME>`（名前は前の分岐の確認の後に戻してあった） |
| 「再起動と PSWindowsUpdate」の手順 1 | `Restart-Computer` の後、起動の途中の「機能をカスタマイズしています。100% 完了。」（この節の「サインイン・検索・キーボードを戻す」の手順 8 の仮想マシン プラットフォームを外す処理）のまま 20 分進まなかった。下の「起動が止まったこと」 |
| 「再起動と PSWindowsUpdate」の手順 2 | 電源を入れ直した後、自動サインインはされずロック画面になり（この節の「サインイン・検索・キーボードを戻す」の手順 3 のとおり）、パスワードでサインインした。メモ帳で、Caps Lock の位置のキー（0x3A）を押しても Ctrl にはならず（`a` を押すと全選択ではなく文字が入った）、JIS 配列の Caps Lock（Shift+英数）でオンにすると `A`・`B` と大文字になり、もう一度で小文字に戻った（JIS 配列の PC では Caps Lock は Shift+英数）。ファイルの右クリックは新しい形のメニュー（最後に「その他のオプションを確認」）。エクスプローラーは「ホーム」で開き、隠しファイルは見えず、淡色で、タスクバーは中央寄せ（検索ボックス・タスク ビューあり）、時計に秒は無かった |
| 「再起動と PSWindowsUpdate」の手順 3・4 | 新しく開いた管理者ではない窓（Windows Terminal の中。この節の「アプリと貼り付けの設定を外す」の手順 6 の後なので Ctrl+V で貼った）で、`PSWindowsUpdate を外した`。`Documents\WindowsPowerShell\Modules` は空になった |

**起動が止まったこと（ロールバックの「再起動と PSWindowsUpdate」の手順 1）**:

- 05:06 UTC に再起動し、05:07 に VBoxService が動き出した後、05:08〜05:12 にゲストが 240 秒止まった（VBox.log の `TM: Giving up catch-up attempt at a 240 078 329 157 ns lag`）。その後はハートビートが戻ったが、ディスクの読み書きが 0 のまま、画面は「機能をカスタマイズしています。100% 完了。」で止まり、ゲストのセッションも始められなかった
- 05:28 に `VBoxManage controlvm reset` でリセットした。ファームウェアは `BdsDxe: failed to load Boot0003 "Windows Boot Manager" from HD(2,GPT,…)/\EFI\Microsoft\Boot\bootmgfw.efi: Not Found` を出した後（外した USB の VHD の起動項目とみている）、Windows の起動の回転表示のまま、また 11 分進まなかった（CPU は 5% ほどで、待っている状態）
- 05:40 に電源を切って入れ直すと、2 分でロック画面まで起動した。サインインの後、この節の「サインイン・検索・キーボードを戻す」の手順 8 の結果（WSL のパッケージ無し、仮想マシン プラットフォームは `Disabled`）は保たれていた
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

- つなぎ替えた直後の再起動される側の接続（`イーサネット`）は、`識別されていないネットワーク`・`Public` だった。管理者の conhost の窓で `$LAN_IF = 'イーサネット'` を入れてから実施手順の「ネットワークとリモート」の手順 1 を貼り、`Private` にしてから試した（再起動の節の手順 4・5 の受信規則はプライベートだけで有効）。SMB での再起動の後は `Public` に戻ったので、WinRM を試す前に `Set-NetConnectionProfile` で `Private` に戻した
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

---

## 付録: 13 本の手順書をまとめた記録（2026-10-10）

### まとめたもの

- git・firefox・hackgen・wezterm-nightly・git-delta・neovim・lazygit・gh・yazi・claude-code・codex・grok-build の Windows 11 の部分と windows-openssh-server.md を、手順書の 17 項・任意節 5 つ・更新（4 項に分けた）・ロールバックの 6 項と注意点に移し、もとの文書は消した（AlmaLinux 10 の部分は、[AlmaLinux 10 の初期設定の検証記録の付録](almalinux-setup.md#付録-12-本の手順書をまとめた記録2026-10-10)）
- 必須にしたもの: もとは任意節の「シェルのツールを入れる」（starship・zoxide 0.9.9・fzf・eza・bat）、自分用の設定 4 つ（Neovim・WezTerm・lazygit・yazi）、Codex・Grok のプラグイン（Node.js は、自分用の Neovim の設定が scoop で入れる `nodejs` を使い、無いときだけ `nodejs-lts` を入れる）
- 窓の使い分け: 管理者ではない窓 #1 に「HackGen Console NF」、管理者の窓 #2 に「OpenSSH サーバー」「Git for Windows」「Firefox」「WezTerm」を足した。設定のための再起動は「WSL と再起動」の 1 回のまま（フォントと WezTerm の VC++ ランタイムも、この再起動で読み直す）。再起動の後は、「WSL の AlmaLinux 10 と自動サインイン」の手順 1 の窓・Git Bash・WezTerm のタブで行う

### 手順を変えたところ

- 各ツールの「管理者ではない（管理者の）PowerShell を開く」手順は外し、項の窓を使う
- 「HackGen Console NF」: サインインし直す手順（もとの 4）を外し、フォントの確かめ（もとの 5）を「再起動の後に確かめる」の手順 5 に移した
- 「OpenSSH サーバー」: `$LAN_IF` の手順（もとの 2）は「PC 全体の設定」の手順 2 と同じなので外した。ログインの確かめ（もとの 8・9）は、再起動の後の「SSH でログインを確かめる」に移し、クライアントの例をこの PC の WSL の AlmaLinux 10 にした
- 「Git for Windows」: PowerShell を開き直す手順（もとの 4）を外し、確かめ（もとの 5）を「Git Bash と WezTerm の設定」の手順 1 に移した。Git Bash では、clone より前に[AlmaLinux 10 の初期設定の「Git」](../almalinux-setup.md#git)を貼る（Git for Windows の `system` の `core.autocrlf=true` のため）
- 「WezTerm」: VC++ ランタイムが再起動を求めても、「WSL と再起動」の再起動でまとめる
- 「シェルのツールを入れる」: もとの任意節の手順 2〜8 を項にした（もとの 1 は外した）。zoxide を上げる手順（もとの 9・10）は更新へ、戻す手順（もとの 11〜13）はロールバックへ移した
- 「Neovim」: LazyVimStarter の「Windows 11 に導入する」の手順 1・3〜11 を通す（scoop を入れる手順 2 と、手順 7 のフォントは飛ばす）。`checkhealth` の手順（もとの 5）は、その導入の手順 10 で行う
- 「lazygit」「yazi」: 自分用の設定を、TUI の確かめより前に入れる
- 外したもの: git-delta の「lazygit と組み合わせる（任意）」
- 更新: 窓ごとに 4 項に分けた（scoop・winget・WSL と zoxide、AI エージェントとプラグイン、HackGen Console NF、管理者の窓の Git for Windows・Firefox・WezTerm）
- ロールバック: 窓ごとに 6 項に分け、今の 5 項より前に置いた。Git Bash の戻しと OpenSSH の `DefaultShell` の削除は、Git for Windows を外す前に行う

### 静的な確認

- 環境: AlmaLinux 10 の初期設定の検証記録の付録と同じコンテナ。Windows も Windows PowerShell 5.1 も無いので、どのブロックも Windows 11 では流していない
- PowerShell のブロック: この文書と extra の 288 個（まとめるときに書き換えた・足したもの 11 個）を、Linux の PowerShell 7.6.6（公式の `powershell-7.6.6-linux-x64.tar.gz`。SHA256 をリリースの `hashes.sha256` と照合）の構文解析器にかけ、誤りは 0。PowerShell 7 にしか無い演算子（`&&`・`||`・`??`・`?.`・三項演算子）も 0
- PSScriptAnalyzer 1.25.0 の、Windows PowerShell 5.1（`win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework`）との互換の検査（PSUseCompatibleSyntax・PSUseCompatibleCommands・PSUseCompatibleTypes）: 指摘は 75 で、73 は `Set-ItemProperty -Type`（レジストリのプロバイダーの動的なパラメーターなので当たらない。前からある指摘）、2 は「Codex・Grok のプラグイン」の手順 1 の `node`（外部のコマンドなので当たらない）
- bash のブロック（SSH のクライアントのシェルと Git Bash に貼るもの）14 個: `bash -n` の誤りは 0。ShellCheck 0.11.0 の指摘は、変数だけのブロックの SC2034 が 2 だけ
- 形・リンク・手順の参照・消したファイルの中身: [AlmaLinux 10 の初期設定の検証記録の付録「12 本の手順書をまとめた記録」](almalinux-setup.md#付録-12-本の手順書をまとめた記録2026-10-10)の「静的な確認」と同じ（同じスクリプトで、リポジトリ全体を確かめた）。この文書のアラートは 4 つ、extra は 2 つ
- 見直し: 同じく、サブエージェントに点検させた。見つかったものは、次の節のとおり直した

### 見直しで直したこと

- 「Codex・Grok のプラグイン」の手順 1: Node.js を確かめる行と入れる行が 1 つのブロックにあり、コピーボタンで貼ると、「Neovim」の手順 3 で scoop の `nodejs` が入っていても `nodejs-lts` を入れた。版を確かめ、18.18 より古いか無いときだけ入れるブロックにした（もとの coding-agents.md のブロックも同じ形だった）
- 「Neovim」の手順 3: LazyVimStarter の「Windows 11 に導入する」の手順 10 は画面を開かない。手順 11 は `:qa!` で閉じる
- 「Git for Windows・Firefox・WezTerm を上げる」: 自分用の設定の WezTerm のタブは Git Bash なので、Git for Windows を上げる前に WezTerm を閉じ、Remote Control のタスクも止める。タスクを止める手順を先頭に移した（手順の番号が変わったので、統合前の記録の対応表も直した）
- 手順の後の節: Git for Windows の既定（`core.autocrlf=true`）のまま clone したリポジトリを直す節への案内が抜けていたので、足した
- 更新: 共通の bash 設定を上げる手順への案内を足した
- Git Bash のタブで行う手順の後に、次の PowerShell のブロックを貼る窓を書いた（「Git Bash と WezTerm の設定」の手順 5、「シェルのツールを入れる」の手順 7、「git-delta」の手順 4）。「Codex CLI」「Grok Build」の手順 4 も、開き直す窓を書いた
- 「WezTerm」の手順 5: OpenGL が使えないときにその場で開く方法を、管理者の窓からではなく「ファイル名を指定して実行」からにした。手順 2 で再起動を待つときは、「Git Bash と WezTerm の設定」より前に済ませることを書いた
- リード: 飛ばさない手順に「シェルのツールを入れる」を、画面で行う手順に PowerShell を開き直す手順などを足した
- ロールバック: `[!CAUTION]` に zoxide の履歴を消す手順を足し、`[!WARNING]` と続けて置かないようにした。「lazygit は scoop の外に残すものが無い」を、設定が `%LOCALAPPDATA%\lazygit` に残る、に直した
- 参考資料: もとの任意節「シェルのツールを入れる」と、項に分けた「更新」の補足の見出しを、今の項と手順の番号にした
- そのほか、同じ文書へのリンクの書き方と、「同書」の指す先を直した

### 確認していないこと

- Windows 11 での、この文書の順番の通し（足した 17 項・任意節 5 つ・更新の 4 項・ロールバックの 6 項）と、窓の使い分け・1 回の再起動でフォントと VC++ ランタイムが読み直されること。この確認を行った環境は Linux のコンテナで、Windows も Windows PowerShell 5.1 も無い（PowerShell のブロックは、Linux の PowerShell 7.6.6 で構文を解析しただけ）
- 自分用の設定 4 つを、この文書の順番で入れること
- 移したコマンドの、統合前の記録の範囲を超える確かめ（統合前の記録の「確認していないこと」は、そのまま残る）

---

## 統合前の記録: HackGen Console NF の Windows 11（もとは hackgen.md）

もとの `hackgen.md` の検証記録のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の検証記録](almalinux-setup.md#統合前の記録-hackgen-console-nfもとは-hackgenmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。前の項で開いた窓を使う） |
| Windows 11 で使う 2・3 | 「HackGen Console NF」の手順 1・2 |
| Windows 11 で使う 4（サインインし直す） | （なし。「WSL と再起動」の手順 2 の再起動で読み直す） |
| Windows 11 で使う 5 | 「再起動の後に確かめる」の手順 5 |
| Windows 11 の更新 1・2 | 「HackGen Console NF を上げる」の手順 1・2 |
| Windows 11 のロールバック 1〜3 | ロールバックの「HackGen Console NF を消す」の手順 1〜3 |

### HackGen Console NF: 最新の確認範囲（Windows 11）

- 通したこと（どれも Windows 11 Pro の同じクリーン VM。実機ではない）
  - 2026-10-06〜07: Windows 節の手順 2・3 による 4 ファイル・ユーザー登録・アプリ用の読み取り許可、再サインイン後の登録、WezTerm CLI でのフォント解決とラスタ生成（[付録](#hackgen-console-nf-付録-windows-11-pro-の-vm-での新規導入の検証2026-10-06)）
  - 2026-10-08: 手順 5 の設定のフォントの一覧（2 ファミリーのタイルと見本）、WezTerm の窓での表示、更新の手順 1、ロールバック（[付録](#hackgen-console-nf-付録-windows-11-pro-の-vm-での追加検証2026-10-08)）
- 確認していないこと
  - メモ帳・Windows Terminal などほかのアプリでの選択、太字・行の高さの見た目の比べ
  - 新しい版への更新、arm64 の Windows、Windows の実機
- 以降の既存記録は、各実施日・対象版・範囲に従う履歴として保持した

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### HackGen Console NF: 補足

#### HackGen Console NF: Windows 11 で使う: 検証状況の記録

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、上流の zip の sha256・中身・ファミリー名、scoop と winget の定義、Linux の PowerShell 7 での構文と模擬の実行だけ（[対象と検証環境](almalinux-setup.md#hackgen-console-nf-対象と検証環境)）。

#### HackGen Console NF: Windows 11 で使う / 手順 3: 補足: 確かめていることと、入れ方

**版と sha256 を固定した**

- HackGen の上流は、リリースの sha256 を出していない。`HackGen_NF_v2.10.0.zip` の sha256 は、[実施手順](../almalinux-setup.md#hackgen-console-nf)の手順 4 の補足で取った zip・Homebrew の cask `font-hackgen-nerd`・scoop の個人のバケット（mo-san）の定義の 3 つで同じ値だった（[付録](#hackgen-console-nf-付録-windows-11-の配布物と資料の調査2026-10-03)）
- そのため版（2.10.0）と sha256 をブロックに書き、一致しなければ止める。新しい版が出たら、この文書を直してから貼る（[Windows 11 の更新](../windows-setup.md#hackgen-console-nf-を上げる)）
- `curl.exe` は `C:\Windows\System32\curl.exe` を呼ぶ。Git for Windows や scoop の `curl` が `PATH` の先にある PC でも、同じものを使うため（[syncthing.md の Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 4 の補足と同じ）

**入れるもの**

- zip の中の 4 つの ttf を全部入れる: `HackGenConsoleNF-{Regular,Bold}.ttf`（ファミリー名は `HackGen Console NF`）と `HackGen35ConsoleNF-{Regular,Bold}.ttf`（`HackGen35 Console NF`）。AlmaLinux 10 の cask と同じ 4 つ
- アプリの設定に書くのはファミリー名（`HackGen Console NF`。スペースが入る）で、ファイル名ではない

**自分のユーザーに入れる**（管理者の権限は要らない）

- 置き場所は `%LOCALAPPDATA%\Microsoft\Windows\Fonts`、登録は `HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts` に `<ファイル名> (TrueType)` = ファイルのフルパス。Windows 10 1809 から、フォントをユーザーごとに入れられる
- 書き方は、scoop の nerd-fonts のバケットの定義（`Hack-NF.json` など）と同じ。そこでは、パッケージのアプリ（Microsoft Store のアプリなど）からも読めるように、フォルダーに「すべてのアプリケーション パッケージ」（`S-1-15-2-1`）と「制限されたすべてのアプリケーション パッケージ」（`S-1-15-2-2`）の読み取りを足している。本書の `icacls` も同じ（足すだけで、ほかの許可は変えない）
- 登録したフォントは、サインインのときに読み込まれる。そのため、使えるのはサインインし直した（か再起動した）後
- 読み込まれているフォントのファイルは、置き換えも削除もできない。2 回目に貼るときに同じファイルなら置き直さないのは、そのため

#### HackGen Console NF: Windows 11 の更新 / 手順 1: 補足: 更新を手作業にしている理由

- 上流は sha256 を出していないので、版と sha256 をこの文書に書いて確かめている（[Windows 11 で使う](../windows-setup.md#hackgen-console-nf)の手順 3 の補足）。新しい版の値は、この文書を直す人が確かめる
- 2.10.0 のファイルの日付は 2024-12-29 で、2026-10-03 の時点でもこれが最新だった
- GitHub の API は、サインインしないと 1 時間に 60 回まで

#### HackGen Console NF: 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物と、ほかの経路の定義を読んだ記録。

`HackGen_NF_v2.10.0.zip` を GitHub のリリースから取った:

```
$ sha256sum HackGen_NF_v2.10.0.zip
f8abd483d5edfad88a78ed511978f43c83b43c48e364aa29ebe4a68217474428  HackGen_NF_v2.10.0.zip
$ unzip -l HackGen_NF_v2.10.0.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  2024-12-29 16:11   HackGen_NF_v2.10.0/
 13462380  2024-12-29 16:04   HackGen_NF_v2.10.0/HackGen35ConsoleNF-Bold.ttf
 12922844  2024-12-29 16:04   HackGen_NF_v2.10.0/HackGen35ConsoleNF-Regular.ttf
 13464288  2024-12-29 16:04   HackGen_NF_v2.10.0/HackGenConsoleNF-Bold.ttf
 12922800  2024-12-29 16:04   HackGen_NF_v2.10.0/HackGenConsoleNF-Regular.ttf
---------                     -------
 52772312                     5 files
$ fc-scan --format '%{file}: family=%{family} style=%{style}\n' HackGen_NF_v2.10.0/*.ttf
HackGen_NF_v2.10.0/HackGen35ConsoleNF-Bold.ttf: family=HackGen35 Console NF style=Bold
HackGen_NF_v2.10.0/HackGen35ConsoleNF-Regular.ttf: family=HackGen35 Console NF style=Regular
HackGen_NF_v2.10.0/HackGenConsoleNF-Bold.ttf: family=HackGen Console NF style=Bold
HackGen_NF_v2.10.0/HackGenConsoleNF-Regular.ttf: family=HackGen Console NF style=Regular
```

sha256 は、次の 3 つと同じだった:

- [実施手順](../almalinux-setup.md#hackgen-console-nf)の手順 4 の補足（2026-09-24 にコンテナの Homebrew が取った zip）
- Homebrew の cask `font-hackgen-nerd` の定義（`https://formulae.brew.sh/api/cask/font-hackgen-nerd.json` の `sha256`。版は 2.10.0）
- scoop の個人のバケット `mo-san/scoop-bucket` の `font-hackgen-console-nf.json` の `hash`（版は 2.10.0）

scoop と winget の HackGen:

- `mo-san/scoop-bucket`（最後のコミットは 2026-09-11）の `font-hackgen-console-nf.json` は、`HackGenConsoleNF-(Regular|Bold)` の 2 つだけを入れる。`--global` が無ければ自分のユーザー（`%LOCALAPPDATA%\Microsoft\Windows\Fonts` と `HKCU`）に入れる。インストールのスクリプトに `Join-Path $env:LOCALAPPDATA Microsoft Windows Fonts` と `Join-Path SOFTWARE Microsoft 'Windows NT' CurrentVersion Fonts`（引数が 3 つ以上）がある
  - Windows PowerShell 5.1 の `Join-Path` は `-Path` と `-ChildPath` の 2 つしか取らない（Microsoft Learn の 5.1 の説明）。残りの引数を受ける `-AdditionalChildPath` は PowerShell 6 から
  - scoop 0.6.0 の `lib/install.ps1` は、定義の `installer` のスクリプトを `Invoke-Command ([scriptblock]::Create(…))` で、`scoop` を打った PowerShell の中で動かす
  - PSScriptAnalyzer の `PSUseCompatibleCommands` は、名前を付けた `-AdditionalChildPath` は 5.1 に無いと指摘したが、名前を付けずに並べた引数は指摘しなかった。Windows PowerShell 5.1 で失敗することは、Windows では確かめていない
- `matthewjberger/scoop-nerd-fonts`（367 の定義）に HackGen は無い。`Hack-NF.json` などのインストールのスクリプトが、[Windows 11 で使う](../windows-setup.md#hackgen-console-nf)の手順 3 の書き方のもと（`%LOCALAPPDATA%\Microsoft\Windows\Fonts` に置き、フォルダーに `S-1-15-2-1`・`S-1-15-2-2` の `ReadAndExecute` を足し、`HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts` に `<ファイル名> (TrueType)` = フルパスを書く）
- winget-pkgs（2026-10-03 の `master`）の `manifests` の下に、名前に `hackgen` を含むものは無かった

---

#### HackGen Console NF: 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-03）

Linux（クラウドのコンテナ）に PowerShell 7.6.6（GitHub のリリースの `powershell-7.6.6-linux-x64.tar.gz`）と PSScriptAnalyzer 1.25.0 を入れて確かめた。

**構文と Windows PowerShell 5.1 との互換**:

- Windows 11 の 3 節の `powershell` のブロック 5 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0（ほかの規則の指摘は、ASCII でない文字を含むファイルの BOM だけ）

**[Windows 11 で使う](../windows-setup.md#hackgen-console-nf)の手順 3 のブロック**を、パスの `\` を `/` に替え、`$env:WINDIR`・`$env:LOCALAPPDATA`・`$env:TEMP` を一時的なディレクトリにして流した。`System32/curl.exe` は Linux の `curl` へのリンク、`icacls.exe` は引数を記録するだけの偽物、レジストリ（`New-ItemProperty`・`Get-ItemProperty`）は値を覚えておく偽物にした:

- 1 回目: zip を取り、sha256 が一致し、4 つの ttf がフォントのフォルダーに置かれ、一時フォルダーが消えた。読み戻しに `HackGen35ConsoleNF-Bold (TrueType) : <フォントのフォルダー>/HackGen35ConsoleNF-Bold.ttf` などの 4 行が出た。`icacls.exe` には `<フォントのフォルダー> /grant *S-1-15-2-1:(OI)(CI)(RX) *S-1-15-2-2:(OI)(CI)(RX)` が渡った
- 2 回目（同じフォルダーに）: 同じ 4 行が出て、ttf の ctime は変わらなかった（置き直していない）
- `$sha256` を別の値にしたもの: `中断: HackGen_NF_v2.10.0.zip の sha256 が一致しない` で止まり、フォントのフォルダーには何も作らず、取った zip は一時フォルダーに残った
- 置けなかったとき（`Copy-Item` の失敗）の分かれ道は試していない（root で動かしたので、書き込めないフォルダーを作れなかった）

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. サインインし直した後に、設定のフォントの一覧と、アプリ（WezTerm と、Windows Terminal などのパッケージのアプリ）で `HackGen Console NF` が使えること
1. 登録を消してサインインし直した後に、ファイルを消せること（Windows 11 のロールバック）
1. scoop の個人のバケットの HackGen が、Windows PowerShell 5.1 で本当に失敗すること（採らなかった理由の確かめ）
1. arm64 の Windows

---

### HackGen Console NF: 本文から分離した確認範囲と実測

#### HackGen Console NF: 付録: Windows 11 Pro の VM での新規導入の検証（2026-10-06）

[Windows 11 の初期設定](windows-setup.md#付録-windows-11-pro-の-vm-での導入検証2026-10-06)を検証中の専用 VM で、[Windows 11 で使う](../windows-setup.md#hackgen-console-nf)の手順 2・3 のコードブロックを抜き出して、そのまま実行した。画面で端末を開いて貼る操作は試していない。

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro 26H2 / ビルド 26300.9457 / x64 |
| VM | VirtualBox 7.2.20。Rufus で作った媒体からクリーンインストールした専用 VM |
| PowerShell | Windows PowerShell 5.1.26100.9444 / Desktop / x64。ログオン中のユーザーの通常権限（Session 1） |
| 配布物 | `HackGen_NF_v2.10.0.zip` |
| zip の SHA256 | `F8ABD483D5EDFAD88A78ED511978F43C83B43C48E364AA29EBE4A68217474428` |
| 検証時の本文の SHA256 | `27F32F24DB057AE78FDA4C2B4783DA1572CF28A8843975F6108FCC78024D00A8`（この追記より前） |
| 抜き出したブロックの manifest の SHA256 | `C6CABB3918DD87333CBD94E4CB4C06A0BBE29CCF99FDAD3FBC0CC5947DF6EFF1` |

**確認したこと**:

- 手順 2・3（バッチ `20261006-110024Z-28d92065`、完了 11:00:28 UTC）:
  - 手順 2 は出力がなく、既存の HackGen のファイルと登録は見つからなかった
  - 手順 3 は zip の SHA256 一致の検査を通過し、ユーザーのフォントフォルダーに 4 つの ttf を置き、対応する `HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts` の登録を出した
  - PowerShell のエラーは 0、最後の終了コードと検証用タスクの終了コードは 0。要求したバッチと完了記録が対応した
- 独立した読み戻し（11:05:43 UTC）:
  - `HackGenConsoleNF-Regular.ttf`・`HackGenConsoleNF-Bold.ttf`・`HackGen35ConsoleNF-Regular.ttf`・`HackGen35ConsoleNF-Bold.ttf` の 4 ファイルが存在し、サイズはいずれも 0 より大きかった。4 つとも登録パスが実ファイルと一致した
  - `PrivateFontCollection` で `HackGen Console NF` と `HackGen35 Console NF` を読み込めた
  - フォントフォルダーの `ALL APPLICATION PACKAGES`（`S-1-15-2-1`）と `ALL RESTRICTED APPLICATION PACKAGES`（`S-1-15-2-2`）への許可を確認した。どちらも `ReadAndExecute, Synchronize`、`ObjectInherit, ContainerInherit` だった
  - 最初の追加検査はアカウント名を SID に変換する処理で失敗したため、raw SDDL と SID を読む方法で確認し直した。本文の導入ブロックの失敗ではない
- 再サインイン後の追加検査（2026-10-07 04:04:16〜04:04:23 UTC）:
  - 同じ VM の通常権限の PowerShell 7.6.6・Session 1 で、`InstalledFontCollection` が `HackGen Console NF` と `HackGen35 Console NF` を認識した
  - 設定やメモ帳のフォント一覧の確認は利用者に依頼済みで、回答待ち。GUI の選択・描画は未確認。証跡は `.verification/evidence/remaining-local-20261007-040410-0e3dc87e/guest-result.json`

**確認していないこと**:

- 手順 5 の設定のフォント一覧。Windows の初期設定で再起動・サインインは済んでいるが、フォントの GUI 確認は回答待ち
- WezTerm や Windows Terminal などのアプリでの利用と見た目。`PrivateFontCollection` と `InstalledFontCollection` の認識だけでは、アプリで選択・描画できると判定しない
- 更新、ロールバック、arm64 の Windows

---

#### HackGen Console NF: 付録: Windows 11 Pro の VM での WezTerm CLI によるフォント利用の検証（2026-10-07）

前の導入と同じ VM の通常権限の PowerShell 7.6.6・Session 1 で、WezTerm の `ls-fonts --codepoints 61,3042,6f22,2192,e0b0,f07c --rasterize-ascii` を実行した。各ファミリーを指定した使い捨ての設定を `--config-file` で渡し、フォントサイズは 12.0、`custom_block_glyphs=false` と `check_for_updates=false` にした。GUI のウィンドウは検査していない。

| ファミリー | DirectWrite が使ったユーザーフォント | ラスタのピクセル数 | alpha が 0 でないピクセル数 |
|---|---|---:|---:|
| HackGen Console NF | `HackGenConsoleNF-Regular.ttf` | 974 | 639 |
| HackGen35 Console NF | `HackGen35ConsoleNF-Regular.ttf` | 1031 | 665 |

**確認したこと**:

- 両ファミリーの `a`・`あ`・`漢`・`→`・Powerline の U+E0B0・Nerd Fonts の U+F07C、計 12 glyph を確認した。glyph ID はすべて 0 以外で `notdef` がなく、セル幅は両ファミリーとも順に `1/2/2/1/1/1`。別のフォントへの fallback や WezTerm の独自 glyph ではなかった
- stdout の ANSI `38:6` の RGBA を文字ごとに集計し、bearing・offset、ラスタの幅・高さ、各チャンネルの 0〜255 の範囲と、alpha が 0 でない領域を確認した。計 2005 ピクセル中 1304 は alpha が 0 以外、359 は 255。HackGen35 の矢印だけ最大 alpha が 254 で、すべての glyph に 255 を要求する判定はしていない
- 2 回の CLI 終了コードは 0、stderr は空、作業フォルダーの cleanup は成功した。実ユーザーとインストール先の WezTerm 設定 3 パスは前後とも存在せず、実設定は不変だった
- 実行時刻は 2026-10-07 09:20:26〜09:20:46 UTC。証跡は `.verification/evidence/remaining-wezterm-font-20261007-092017-4d5448f6` の `guest-result.json` と独立した `glyph-assessment.json` に保存した。raw stdout の NUL padding と ANSI は解析用のコピーだけで処理し、元の JSON は保持した
- raw JSON の SHA256 は `9B2C1DC0A426F36FF2971561FCC041077D62EFE718D8D85403C68CB1E6A40475`、評価 JSON は `C12A3BF87D1FD9BE9C9061AD12DB6F6866B2A4141E993CC3F80221184E753C68`。文字ごとの寸法と alpha の領域は評価 JSON と[WezTerm の付録](#wezterm-付録-windows-11-pro-の-vm-での-hackgen-の-cli-ラスタ生成の検証2026-10-07)に記録した

**確認していないこと**:

- Windows の設定・メモ帳・WezTerm GUI のフォント一覧と選択、画面上の描画や字形・太字・行の高さ。今回の CLI ラスタ生成をスクリーン上の見た目の確認へ広げない
- Windows Terminal などのパッケージのアプリでの利用、選んだ 6 文字以外、更新・ロールバック、arm64 の Windows。以前の付録の未確認事項はその時点の履歴として保持した

---

#### HackGen Console NF: 付録: Windows 11 Pro の VM での追加検証（2026-10-08）

上の付録と同じ VM（[windows-setup.md の検証記録の 2026-10-08 の付録](windows-setup.md#付録-pr-104-の未検証項目を同じ-vm-で確かめた記録2026-10-08)の環境）で、画面のフォントの一覧と WezTerm の窓での表示、更新の確認を行った。手順は [Windows 11 で使う](../windows-setup.md#hackgen-console-nf)の番号。

- 手順 5:
  - 設定 → 個人用設定 → フォント は、ライセンス認証していないこの VM でも開いた。ただし、画面の検索欄は使えなかった（UI Automation で `IsEnabled` が `False`）
  - 一覧をスクロールすると、「HackGen Console NF」と「HackGen35 Console NF」のタイルが、どちらも「2 フォント フェイス」で、見本の文がこのフォントで描かれて並んだ
  - 本文の手順 5 に、検索欄が使えないときは一覧をスクロールする旨を足した
- WezTerm の窓での表示: 一時的な `%USERPROFILE%\.wezterm.lua` で `HackGen Console NF` を指定すると、英字・かな・漢字・矢印・Powerline の記号・Nerd Font のフォルダーのアイコン・日本語の文が表示された（[wezterm-nightly.md の検証記録](almalinux-setup.md#統合前の記録-weztermもとは-wezterm-nightlymd)の 2026-10-08 の付録。この VM では `prefer_egl` も要った）
- Windows 11 の更新の手順 1: `v2.10.0`。新しい版は無いので、この節の手順 2 は行っていない
- Windows 11 のロールバック（管理者ではない窓。Windows Terminal の中に開き、複数行の警告で「強制的に貼り付け」を押した）:
  - この節の手順 1: 最後のコマンドは何も出さなかった
  - この節の手順 2: サインアウトの代わりに再起動した（自動サインインで戻った）
  - この節の手順 3: 最後のコマンドは何も出さなかった（4 つの ttf が消えた）

**確認していないこと**:

- メモ帳・Windows Terminal などほかのアプリでの選択、太字・行の高さの見た目の比べ、新しい版への更新、arm64 の Windows、Windows の実機

---

## 統合前の記録: OpenSSH サーバー（もとは windows-openssh-server.md）

もとの `windows-openssh-server.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

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

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### OpenSSH サーバー: 補足

#### OpenSSH サーバー: 操作上の注意と併記されていた記録

   - Windows Update から取ってくるので、数分かかる（検証した PC では 8〜9 分）

#### OpenSSH サーバー: 操作上の注意と併記されていた記録

   - **注意**: パスワードを続けて間違えると、Windows のロックアウトのポリシーでアカウントがロックされる（検証した PC は 10 回で 10 分。[注意点](../extra/windows-setup.md#注意点)）

#### OpenSSH サーバー: 実施手順: 検証状況の記録

> [!WARNING]
> **Administrators の一員で SSH にログインすると、そのセッションは UAC の確認無しで管理者の権限を持つ**（検証した PC では High Mandatory Level）。このユーザーのパスワードを知る人は、SSH が届くところから、この PC の管理者として操作できる（[注意点](../extra/windows-setup.md#注意点)）。

#### OpenSSH サーバー: 実施手順 / 手順 2: 補足: 変数について

- `$LAN_IF` は、手順 5（ネットワークがプライベートか確かめる）と手順 7（接続先の IP を出す）で使う
- 接続の一覧は `Get-NetConnectionProfile` で見られる。検証した PC では、WSL を動かしていても `vEthernet (WSL (Hyper-V firewall))` は一覧に出ず、有線 LAN の 1 行だけだった
- 公開鍵の `$PUBKEY` は[公開鍵でもログインする（任意）](../windows-setup.md#openssh-サーバーに公開鍵でもログインする任意)でしか使わないので、手順 2 ではなくその節の手順 3 で設定する

#### OpenSSH サーバー: 実施手順 / 手順 5: 補足: プライベートにする理由

- プライベートにする操作は、2026-10-03 に [Windows 11 の初期設定の「ネットワークとリモート」の手順 1](../windows-setup.md#ネットワークとリモート) へ移し、この手順は確かめるだけにした（Windows のインストール直後の作業をまとめたため。Syncthing の Windows 11 の節も同じ前提）。下の実測は、移す前の、この手順でプライベートにしていたときのもの
- 手順 3 でできる規則は、プライベートのネットワークだけで有効。検証した PC の有線 LAN は「パブリック」だったので、そのままでは LAN からの SSH が捨てられる
- WSL の AlmaLinux 10 から、この PC の LAN の IP（`<WIN_HOST>`）の 22/tcp につないで確かめた
  - パブリックのとき: 5 秒待っても応答が無い
  - プライベートにした後: すぐにバナー（`SSH-2.0-OpenSSH_for_Windows_9.5`）が返った
- 検証した PC では、パブリックからプライベートにすると、それまで効いていなかった許可の規則 45 本がこの LAN で効くようになった。主なものは、ネットワーク探索（10 本）、リモート アシスタンス（4 本）、デバイス キャスト機能（3 本）。ファイルとプリンターの共有は無効のままだった
- 規則の接続元は `Any` なので、LAN を通って届く別のサブネットの相手も受け付ける。検証した PC には、WireGuard のクライアントのアドレスからも入れた（[注意点](../extra/windows-setup.md#注意点)）
- パブリックのまま開ける方法（規則をパブリックにも広げる）は採らなかった（[選択した方針](#openssh-サーバー-選択した方針)）

#### OpenSSH サーバー: 実施手順 / 手順 7: 補足: フルパスで呼ぶ理由

- Git for Windows を入れた PC では、`PATH` の順によって、`ssh-keygen` が Git の `usr\bin\ssh-keygen.exe` になる。検証した PC では、ユーザーの `PATH` の先頭側に Git の `usr\bin` があり、`ssh`・`ssh-keygen`・`whoami` がどれも Git のものになった
- Windows の OpenSSH のものを確実に使うため、`$env:WINDIR\System32\OpenSSH\` から呼ぶ

#### OpenSSH サーバー: 実施手順 / 手順 9: 補足: ログインした後のセッションと、Microsoft アカウント

- `-o PubkeyAuthentication=no` は、クライアントの鍵を使わせずに、パスワードで入れることを確かめるため。[公開鍵でもログインする（任意）](../windows-setup.md#openssh-サーバーに公開鍵でもログインする任意)で鍵を登録した後も、これを付ければパスワードを聞かれる
- 既定のシェルは cmd.exe。sshd が `PROMPT` を `<ユーザー>@<ホスト名> <パス>>` の形にする
- 指紋が手順 7 と違えば、`no` で止める。途中の経路で別の相手につながっている
- Windows のイベント ビューアーの「アプリケーションとサービス ログ」→「OpenSSH」→「Operational」に、`sshd: Accepted password for <WIN_USER> from <IP> port <PORT> ssh2` が残る。PowerShell では `Get-WinEvent -LogName OpenSSH/Operational -MaxEvents 10`
- 検証した PC のユーザーは Microsoft アカウントで、設定の「Windows Hello サインインのみを許可する」がオンのまま、そのアカウントのパスワードで入れた（[注意点](../extra/windows-setup.md#注意点)）
- ローカル アカウントの標準ユーザーでも、このブロックのまま（`WIN_USER` だけ直して）入れた。`whoami /groups` の `Mandatory Label` は `Medium Mandatory Level` だった

#### OpenSSH サーバー: 公開鍵でもログインする（任意） / 手順 4: 補足: 鍵の置き場所とアクセス権

- Windows の `sshd_config` の末尾には `Match Group administrators` と `AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys` がある。Administrators の一員のユーザーは、ホームの `.ssh\authorized_keys` ではなく、このファイルの鍵で認証される
- Microsoft の文書は、このファイルのアクセス権を Administrators と SYSTEM だけにするよう求めている。`/inheritance:r` で `C:\ProgramData\ssh` から受け継ぐ `Authenticated Users` の読み取りなどを外し、2 つだけを付ける。アクセス権が違うときの sshd の振る舞いは、試していない
- `icacls` にはグループを SID で渡した（`S-1-5-32-544` が Administrators、`S-1-5-18` が SYSTEM）。表示の言語に左右されないため
- `-Encoding ascii` は、Windows PowerShell 5.1 の `Add-Content` が既定で使うコードページ（日本語版では Shift_JIS）で書かないため。公開鍵は ASCII の文字だけでできている
- `Get-LocalGroupMember` は、Microsoft アカウントのユーザーも `<HOSTNAME>\<WIN_USER>` の名前で返した

#### OpenSSH サーバー: 既定のシェルを Git Bash にする（任意） / 手順 2: 補足: Git Bash のセッション

- 対話のログインでも、ログインシェルにはならない（`shopt login_shell` が off）。`~/.bash_profile` は読まれず、`~/.bashrc` は読まれる。プロンプトは Git の `/etc/bash.bashrc` の `PS1`
- bash は、sshd から起動されたことを見分けて、`bash -c` のときも `~/.bashrc` を読む。検証した PC では、`~/.bashrc` の `eval "$(zoxide init bash)"` のエラーが、`ssh … <コマンド>` のたびに出た（原因と対処は[scoop のツールを SSH のセッションで使う（任意）](../windows-setup.md#scoop-のツールを-ssh-のセッションで使う任意)）
- `PATH` は `/mingw64/bin:/usr/bin` の後ろに Windows の `PATH` が続き、`git` は `/mingw64/bin/git` になる。ホームは `/c/Users/<WIN_USER>`
- `scp`（既定の SFTP の方式）、`scp -O`（旧来の方式。サーバー側では、`~/.bashrc` を読んだ bash の上で `scp` が動いた）、`sftp` の 3 つで、ファイルを送って消せた

#### OpenSSH サーバー: scoop のツールを SSH のセッションで使う（任意） / 手順 1: 補足: RedirectionGuard と、作り直す理由

- sshd には、IFEO（`HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\sshd.exe`）の `MitigationOptions` で RedirectionGuard が掛けてある（19 バイトの値の最後のバイトが `0x10`）。SYSTEM で動く sshd を、ジャンクションを使った攻撃から守るためのもので、本書では外さない
- `GetProcessMitigationPolicy` で `ProcessRedirectionTrustPolicy` を見ると、sshd の 3 つのプロセスと、その下の bash・PowerShell はどれも `Enforce=1` で、`services.exe` とローカルのシェルは 0 だった
- 信頼されるかどうかは、ジャンクションを作ったときに決まる
  - 同じ向き先で、一般ユーザーが作ったものは SSH のセッションから開けず（エラー 448）、管理者が作ったものは開けた
  - 一般ユーザーが作ったものの所有者を、後から Administrators に変えても開けなかった
- そこで、一般ユーザーの所有のもの（= 一般ユーザーが作ったもの）だけを選び、管理者の PowerShell で消して作り直す。管理者が作ったものは所有者が `BUILTIN\Administrators` になるので、2 回目からは選ばれない
- `cmd.exe /c rmdir` はジャンクションそのものだけを消し、向き先の中身には触れない。scoop が付けた読み取り専用の属性は、`attrib /L` で外してから消し、作り直した後に付け直す
- Windows PowerShell 5.1 の `Get-ChildItem -Recurse` は、ジャンクションの中へは入らなかった（`current` を通った重複は出ない）
- 管理者が作ったジャンクションも、一般ユーザーが消せた（ACL は `C:\Users\<WIN_USER>` から受け継ぐ）。scoop の更新の邪魔にはならない
- 検証した PC では、`current` 39 個と persist（`nodejs\<版>\bin`・`python\<版>\Scripts` など）14 個の、53 個を作り直した。作り直した後も、向き先・読み取り専用の属性は前と同じだった

#### OpenSSH サーバー: 対象と検証環境

- **目的**: LAN のほかの PC（AlmaLinux 10 など）から、Windows 11 の PC に SSH で入れるようにする
  - Windows のオプション機能「OpenSSH サーバー」を入れ、Windows のユーザーのパスワードで認証する
  - 受け付けるのは、プライベートにしたネットワークからだけ（プライベートにするのは [Windows 11 の初期設定の「ネットワークとリモート」の手順 1](../windows-setup.md#ネットワークとリモート)。手順 5 で確かめる）
  - 公開鍵での認証、パスワード認証を切る方法、ログインしたときのシェルを Git Bash にする方法、scoop のツールを SSH のセッションで使う方法は、任意節にした
- **進め方**: 値は、Windows では手順 2、クライアントでは手順 8 の変数に 1 度だけ書き、以降のコマンドをそのまま貼る
  - Windows の手順は管理者の Windows PowerShell に、クライアントの手順は bash に貼る
  - 読者が書き換えるのは、`WIN_HOST`（クライアント）だけ。公開鍵の任意節では `$PUBKEY`（Windows）も
- **状態**: **実機で本実行済み（2026-09-29・2026-09-30、同じ PC）。2026-09-29 は公開鍵を主にしていた版、2026-09-30 はパスワードを主にした今の版**
  - 2026-09-29（公開鍵が主の版。クライアントは同じ PC の WSL の AlmaLinux 10）:
    - x86_64 のノート PC（Windows 11 Pro 25H2）で、手順 1〜5・7・8、[公開鍵でもログインする（任意）](../windows-setup.md#openssh-サーバーに公開鍵でもログインする任意)の手順 1〜4、[パスワード認証を切る（任意）](../windows-setup.md#openssh-サーバーのパスワード認証を切る任意)の手順 1・2、Git Bash の任意節、ロールバックを通した
    - 当時は、手順 7 の後に鍵で対話のログインをしていた（今の手順 9 は、パスワードでのログインに変えた）
    - scoop の任意節は、その後に原因を調べて足し、同じ PC で通した
    - ロールバックで実施前の状態に戻した後、当時の文書から機械的に抜き出したブロックで、同じ範囲（ロールバックを除く）をもう 1 度通した
  - 2026-09-30 の朝（公開鍵が主の版のまま。[追加の確認の付録](#openssh-サーバー-付録-追加の確認2026-09-30)）:
    - LAN の別の IP からの接続: 同じ PC の VirtualBox の VM を LAN にブリッジ接続し、ルーターの DHCP で別の IP を受け取った AlmaLinux 10.2 をクライアントにして、手順 8、当時の鍵での対話のログイン、[パスワード認証を切る（任意）](../windows-setup.md#openssh-サーバーのパスワード認証を切る任意)の手順 2、Git Bash と scoop の任意節の手順 2、ロールバックの手順 4 を流した。Windows の設定は変えていない
    - Windows の再起動の後に、sshd が自動で起動したこと（2 回の起動のどちらも、起動の 30〜40 秒後に待ち受けを始めていた）
  - 2026-09-30 の 1 回目（今の版を、2026-09-29 の後の PC に適用）:
    - パスワード認証を切り、鍵を登録してあった PC に、手順 2・6 を流し、`PasswordAuthentication` を `no` から `yes` にした
    - 書き直した文書から抜き出した手順 2〜5・7 を流した（何も変わらなかった）。手順 6 の 2 回目は、スマートフォンのセッションが切れた後に流し、出力も `sshd_config` のハッシュも変わらなかった
    - パスワードでのログインは、利用者がスマートフォンの SSH のアプリから、WireGuard 越しに行った（Microsoft アカウントのパスワード）
  - 2026-09-30 の 2 回目（今の版を、実施前の状態から通した）:
    - `C:\ProgramData\ssh`（アクセス権ごと）と `HKLM:\SOFTWARE\OpenSSH`、WSL の `known_hosts` を控えてから、ロールバックの手順 1〜4 で実施前の状態にした
    - この文書から抜き出したブロックで、手順 2〜9、公開鍵の任意節の手順 1〜5、パスワード認証を切る任意節の手順 1・2、戻すための手順 6 を通した
    - 手順 8・9 は、試験用に作ったローカル アカウントの標準ユーザーで流した（`WIN_USER` を直した）。検証した PC のユーザー（Microsoft アカウント）のパスワードは、OpenSSH の `ssh` では流していない
    - 公開鍵の任意節は、WSL に作った試験用の Linux ユーザーで、パスフレーズ付きの鍵を新しく作って通した
    - 試験用のユーザーで、ロックアウトを確かめた
    - 最後に、控えからホスト鍵・登録した鍵・`DefaultShell`・`known_hosts` を戻し（ハッシュとアクセス権が控えと一致）、試験用のユーザーを消した（Windows のプロファイルのフォルダーは、読み込まれたまま外れず、残った。付録）
  - コードブロックは端末に貼らず、Claude Code から昇格した Windows PowerShell 5.1 と、WSL の bash に、手順ごとのスクリプトにして渡した。手順 1（PowerShell を開く）は、その形で代えた（付録）
  - 確認したこと:
    - 機能の導入（8〜9 分、再起動無し）、sshd の自動起動の設定と待ち受け
    - LAN の接続がパブリックのままでは LAN の IP あての接続が捨てられ、プライベートにすると通ること
    - 手順 6 の後の `sshd_config` が、既定の `sshd_config` から作っても、`no` にしてあったものから作っても、同じになること
    - パスワードでのログイン: ローカル アカウントの標準ユーザー（手順 8・9 のブロック、cmd）と、Microsoft アカウント（スマートフォンのアプリ。「Windows Hello サインインのみを許可する」がオンのまま）。WireGuard のクライアントのアドレスからの接続
    - 公開鍵でのログイン（cmd と Git Bash、パスフレーズ付きの鍵を新しく作る流れも）、ホスト鍵の指紋の照合、パスワード認証を切った後に `Permission denied` ですぐ終わること、手順 6 で戻ること
    - Administrators の一員のセッションは High Mandatory Level（2026-09-29 に確かめた）、標準ユーザーのセッションは Medium Mandatory Level
    - ロックアウト: ローカル アカウントでは、SSH のパスワードの失敗も数えられ、10 回目でロックされること
    - Windows の再起動の後に sshd が自動で起動すること（利用者が 2 回起動し直したときのログ）
    - Git Bash での `git`・`scp`・`scp -O`・`sftp`、`DefaultShell` を消すと cmd に戻ること
    - SSH のセッションで scoop のツールが起動しない原因（sshd の RedirectionGuard）と、ジャンクションを管理者で作り直すと起動すること（scoop の任意節。一般ユーザーで作り直して壊した状態から、この文書のブロックで直した）
    - ロールバックの後に残るもの（`C:\ProgramData\ssh` とレジストリのキー）と、消した後に入れ直せること
    - 変数が空のとき・PowerShell 7 で貼ったときに、手順 3、公開鍵の任意節の手順 4、パスワード認証を切る任意節の手順 2、ロールバックの手順 4 が何も変えずに止まること
  - **確認していないこと**:
    - Microsoft アカウントのパスワードで、手順 8・9 のブロック（OpenSSH の `ssh`）から入ること
    - LAN の別の PC（実機）から、この文書の手順で入ること（LAN の別の IP からは、同じ PC の VM から、2026-09-29 の版の手順で鍵で入った。[付録](#openssh-サーバー-付録-追加の確認2026-09-30)。WSL からの接続は、sshd には送信元がこの PC の LAN の IP として届いた。[注意点](../extra/windows-setup.md#注意点)）
    - 端末に貼る操作そのもの（PowerShell の PSReadLine での複数行の貼り付け、bash の対話の入力）
    - 標準ユーザーの鍵での認証（`authorized_keys`）、既定の UAC の設定での振る舞い
    - Microsoft アカウントのロックアウト
    - Windows Update での OpenSSH の更新
  - **2026-10-03 の変更**: LAN をプライベートにする操作を [Windows 11 の初期設定の「ネットワークとリモート」の手順 1](../windows-setup.md#ネットワークとリモート) へ移し、手順 5 を確かめるだけのブロックに、ロールバックの手順 3 をそこを指すコマンドの無い手順に変えた。今の手順 5 のブロックは、構文の検査（Linux の pwsh 7.6.6 と PSScriptAnalyzer 1.25.0 の 5.1 互換）と、偽物の `Get-NetConnectionProfile` での模擬だけで、実機では流していない。上と付録の「手順 5」「ロールバックの手順 3」は、当時の、プライベートにするブロックとパブリックに戻すブロックを指す
  - 実測の記録は[付録（2026-09-29）](#openssh-サーバー-付録-実機での検証記録2026-09-29)、[追加の確認の付録（2026-09-30）](#openssh-サーバー-付録-追加の確認2026-09-30)、[パスワード認証の付録（2026-09-30）](#openssh-サーバー-付録-パスワード認証の検証記録2026-09-30)

下表は実機で採取した値。

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-29、2026-09-30 |
| PC | x86_64 のノート PC（AMD Ryzen AI MAX+ 395） |
| OS | Windows 11 Pro 25H2（ビルド 26200.9457、日本語） |
| PowerShell | Windows PowerShell 5.1.26100.9444（手順で使う）/ PowerShell 7.6.6（Microsoft Store 版。手順 3 が失敗した） |
| OpenSSH | オプション機能 `OpenSSH.Server~~~~0.0.1.0`（`OpenSSH_9.5p2 for Windows`）。クライアントは同じ版が最初から入っていた |
| Git for Windows | 2.55.0.windows.3（GNU bash 5.3.15） |
| ユーザー | Microsoft アカウント。Administrators の一員。「Windows Hello サインインのみを許可する」がオン（`DevicePasswordLessBuildVersion` が 2） |
| UAC | 有効。管理者は確認無しで昇格する設定（`ConsentPromptBehaviorAdmin` が 0） |
| アカウントのロックアウト | `net accounts` で、10 回の失敗で 10 分（観測期間 10 分） |
| ネットワーク | 有線 LAN 1 本（IPv4、/24）。2026-09-29 の手順の前はパブリック |
| クライアント（2026-09-29） | 同じ PC の WSL 2.7.13.0（カーネル 6.18.33.2-microsoft-standard-WSL2、既定の NAT）の AlmaLinux 10.2。`openssh-clients-9.9p1-23.el10_2.alma.1` |
| クライアント（2026-09-30） | 1 回目のパスワード: スマートフォンの SSH のアプリ（WireGuard のクライアント）。ほかは上と同じ WSL（公開鍵の任意節は、WSL に作った試験用の Linux ユーザー） |
| 試験用のユーザー（2026-09-30） | Windows のローカル アカウントの標準ユーザー（`Users` だけ）。WSL の Linux ユーザー。どちらも検証の後に消した（Windows のプロファイルのフォルダーは残った） |

> [!NOTE]
> 環境固有の値は**変数**で書いてある。Windows では手順 2 の PowerShell の変数に、クライアントでは手順 8 のシェル変数に 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 設定する場所 | 意味 | 例 |
> |---|---|---|---|
> | `$LAN_IF` | Windows（手順 2） | クライアントとつながる LAN の接続の名前（自動で入る） | `イーサネット` |
> | `${WIN_HOST}` | クライアント（手順 8） | Windows の LAN の IP アドレス | `192.168.1.30` |
> | `${WIN_USER}` | クライアント（手順 8） | Windows のユーザー名（既定はクライアントのユーザー名） | `${USER}` |
> | `$PUBKEY` | Windows（公開鍵の任意節の手順 3） | クライアントの公開鍵の 1 行 | `ssh-ed25519 AAAA… <USER>@<HOSTNAME>` |
>
> 出力例・ログ・表の中の値は `<WIN_HOST>` / `<WIN_USER>` / `<HOSTNAME>`（Windows のコンピューター名）/ `<hostname>` と `<win_user>`（`whoami` が小文字で出すもの）/ `<LAN_IF>` / `<USER>`（クライアントのユーザー名）/ `<IP>` / `<PORT>` のプレースホルダで書いてある。
>
> パスワードと秘密鍵はこの文書に載せない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### OpenSSH サーバー: 実施前の状態

実機で、2026-09-29 に手順 1 の前に確かめた状態:

| 項目 | 状態 |
|---|---|
| OpenSSH サーバー | 未導入（サービス `sshd` が無く、`Get-WindowsCapability` は `NotPresent`） |
| OpenSSH クライアント | `C:\Windows\System32\OpenSSH` に 9.5p2。サービス `ssh-agent` は `Disabled` |
| `C:\ProgramData\ssh` | 空 |
| `HKLM:\SOFTWARE\OpenSSH` | 無し |
| 受信の規則 | 名前に ssh を含むものは無し |
| 22/tcp | 待ち受け無し |
| LAN の接続 | `<LAN_IF>`。パブリック |
| リモート デスクトップ | 有効（規則はすべてのプロファイル）。本書では変えない |
| `PATH` | ユーザーの `PATH` の先頭側に Git の `usr\bin` があり、`ssh`・`ssh-keygen`・`whoami` は Git のものが動く |
| WSL | `AlmaLinux-10`（停止中）。`~/.ssh/id_ed25519`（パスフレーズ無し）が前からあった |

- 2026-09-30 の 1 回目は、[完了時点の状態](#openssh-サーバー-完了時点の状態)の PC（`PasswordAuthentication no`、鍵を 1 つ登録、既定のシェルは Git Bash、LAN はプライベート）から始めた
- 2026-09-30 の 2 回目は、ロールバックの手順 1〜4 の後に、上の表の OpenSSH サーバー・`C:\ProgramData\ssh`・`HKLM:\SOFTWARE\OpenSSH`・受信の規則・22/tcp・LAN の接続（パブリック）が同じ状態になったことを確かめてから始めた（`C:\ProgramData\ssh` は空ではなく、無かった）

#### OpenSSH サーバー: 選択した方針

- **Windows のオプション機能（Feature on Demand）で入れる**
  - `Add-WindowsCapability` の 1 つで、サービス・受信の規則・既定の `sshd_config` がそろう
  - Microsoft の文書は、Windows Update で保守されるこの版を、ほとんどの場合に勧めている
  - GitHub の Win32-OpenSSH（winget の `Microsoft.OpenSSH.Preview`）は新しい版を使えるが、本書では試していない
- **パスワードで認証し、公開鍵は任意節にした**（手順 6 でパスワード認証を明示的に有効にする）
  - クライアントで鍵を作って Windows に登録しなくても、Windows のユーザーのパスワードだけで入れる。鍵を扱いにくいクライアント（スマートフォンのアプリなど）からも入れる
  - 受け付けるのは、プライベートにしたネットワークから届く接続だけ（[Windows 11 の初期設定の「ネットワークとリモート」の手順 1](../windows-setup.md#ネットワークとリモート)）
  - パスワードの総当たりへの備えは、Windows のアカウントのロックアウトのポリシー（検証した PC は 10 回で 10 分）。ローカル アカウントでは、SSH での失敗も数えられ、10 回目でロックされた
  - 鍵で入れるようにしたら、パスワード認証を切れる（[パスワード認証を切る（任意）](../windows-setup.md#openssh-サーバーのパスワード認証を切る任意)）。2026-09-29 の版は、この形（公開鍵だけ）を主にしていた
- **LAN の接続をプライベートにし、規則は変えない**
  - 機能が作る規則は、プライベートのネットワークだけで有効。家の LAN をプライベートにすれば、規則を変えずに LAN から入れる
  - 持ち出した先のパブリックの Wi-Fi では、閉じたままになる
  - 規則をパブリックにも広げる（接続元を同じサブネットに絞る）方法は採らなかった。持ち出した先でも、同じサブネットの相手に開くため
  - プライベートにすると、プライベート向けのほかの規則（ネットワーク探索など）もこの LAN で効く（手順 5 の補足）
  - プライベートにする操作は、Windows のインストール直後の作業として [Windows 11 の初期設定の「ネットワークとリモート」の手順 1](../windows-setup.md#ネットワークとリモート) にまとめた（2026-10-03。もとは手順 5 で行っていた。Syncthing の Windows 11 の節も同じ前提にした）
- **Windows PowerShell 5.1 で貼る**
  - Microsoft Store の PowerShell 7 では、手順 3 の Dism のコマンドが失敗した
  - ほかの手順（NetSecurity などのコマンド）もこのシェルにそろえ、1 つの PowerShell で通せるようにした
- **公開鍵の任意節では、ED25519 の鍵をクライアントで作る**: 秘密鍵をクライアントから出さない。Windows に渡すのは公開鍵の 1 行だけ
- **既定のシェルは任意節にした**: 既定の cmd.exe でも使える。Git Bash にすると、Linux のクライアントからシェルの道具と `git` をそのまま使える

#### OpenSSH サーバー: 完了時点の状態

実機で、2026-09-29 の 2 回目の通し（既定のシェルを Git Bash にした状態）の後に確かめた状態。この後に、scoop の任意節で scoop のジャンクションを作り直した:

```
PS> Get-Service sshd, ssh-agent | Format-Table Name, Status, StartType
Name       Status StartType
----       ------ ---------
ssh-agent Stopped  Disabled
sshd      Running Automatic

PS> Get-NetConnectionProfile | Format-Table InterfaceAlias, NetworkCategory
InterfaceAlias NetworkCategory
-------------- ---------------
<LAN_IF>               Private

PS> Get-NetFirewallRule -Name OpenSSH-Server-In-TCP | Format-Table Name, DisplayName, Enabled, Profile, Direction, Action
Name                  DisplayName               Enabled Profile Direction Action
----                  -----------               ------- ------- --------- ------
OpenSSH-Server-In-TCP OpenSSH SSH Server (sshd)    True Private   Inbound  Allow

PS> Get-NetFirewallRule -Name OpenSSH-Server-In-TCP | Get-NetFirewallApplicationFilter | Format-List Program
Program : %SystemRoot%\system32\OpenSSH\sshd.exe

PS> Get-ItemProperty HKLM:\SOFTWARE\OpenSSH | Format-List DefaultShell
DefaultShell : C:\Program Files\Git\bin\bash.exe

PS> Get-ChildItem C:\ProgramData\ssh -Force | Format-Table Mode, Length, Name
Mode  Length Name
----  ------ ----
d----        logs
-a--- 98     administrators_authorized_keys
-a--- 505    ssh_host_ecdsa_key
-a--- 178    ssh_host_ecdsa_key.pub
-a--- 411    ssh_host_ed25519_key
-a--- 98     ssh_host_ed25519_key.pub
-a--- 2602   ssh_host_rsa_key
-a--- 570    ssh_host_rsa_key.pub
-a--- 2295   sshd_config
-a--- 6      sshd.pid
```

- 管理者でない PowerShell からは、`icacls C:\ProgramData\ssh\administrators_authorized_keys` が `Access is denied.` になった（公開鍵の任意節の手順 4 のアクセス権が効いている）
- `sshd_config` は、既定の 2297 バイトから、パスワード認証を切る任意節の手順 1 の 1 行の置き換えで 2 バイト減った
- 2026-09-30 に手順 6 を流した後は、`sshd_config` の 51 行目が `PasswordAuthentication yes` になり、2296 バイト（既定から 1 バイト減）になった。ほかは上と同じ（`sshd.pid` だけ、プロセス ID の桁が増えて 7 バイト。[付録（2026-09-30）](#openssh-サーバー-付録-パスワード認証の検証記録2026-09-30)）
- 2026-09-30 の 2 回目の通しの後は、控えから `C:\ProgramData\ssh` と `DefaultShell` を戻したので、1 回目の後と同じ状態（ファイルのハッシュとアクセス権が一致）

#### OpenSSH サーバー: 操作上の注意と併記されていた記録

  - この設定がオンだと、Microsoft アカウントのパスワードが sshd のログにエラー 1326 を残して拒否され、オフにして sshd を再起動すると通った、という報告がある（[参照](../reference/windows-setup.md#openssh-サーバー-参照)の Q&A）。検証した PC では起きなかった

#### OpenSSH サーバー: 操作上の注意と併記されていた記録

- **パスワードを続けて間違えたとき**（ローカル アカウントの標準ユーザーで試した）

#### OpenSSH サーバー: 操作上の注意と併記されていた記録

- **鍵で入ったセッションは、ユーザーの資格情報を持たない**（Microsoft の文書）。セッションの中から、そのユーザーとしてほかのサーバーの共有などへ認証できない。本書では、鍵でもパスワードでも試していない

#### OpenSSH サーバー: 操作上の注意と併記されていた記録

  - 標準ユーザーの鍵は `C:\Users\<ユーザー>\.ssh\authorized_keys` に置く（Microsoft の文書）。本書では試していない。公開鍵の任意節の手順 4 は、Administrators の一員でなければ止まる

#### OpenSSH サーバー: 操作上の注意と併記されていた記録

  - scoop のジャンクションは、[scoop のツールを SSH のセッションで使う（任意）](../windows-setup.md#scoop-のツールを-ssh-のセッションで使う任意)で、管理者で作り直せば通る。scoop 以外のツールのジャンクションも、同じ理由で通らないはず（試していない）

#### OpenSSH サーバー: 注意点 / 手順 0: 本文中の記録

  - 検証した PC の UAC は、管理者が確認無しで昇格する設定だった。既定の UAC での振る舞いは確かめていない

#### OpenSSH サーバー: 注意点 / 手順 0: 本文中の記録

  - 検証した PC では、設定の「セキュリティ向上のため、このデバイスでは Microsoft アカウント用に Windows Hello サインインのみを許可する」がオンのまま、Microsoft アカウントのパスワードで入れた

#### OpenSSH サーバー: 注意点 / 手順 0: 本文中の記録

  - 検証した PC のロックアウトのポリシーは、10 回の失敗で 10 分（`net accounts`）

#### OpenSSH サーバー: 注意点 / 手順 0: 本文中の記録

  - ほかのユーザーの接続には影響しなかった。Microsoft アカウントのロックアウトは試していない

#### OpenSSH サーバー: 注意点 / 手順 0: 本文中の記録

  - 検証した PC には、[WireGuard VPN](../wireguard.md) のクライアントのアドレスから、パスワードで入れた

#### OpenSSH サーバー: 注意点 / 手順 0: 本文中の記録

  - 検証した PC では、scoop の `current` を通る `zoxide.exe` と `python.exe` が Git Bash から `Is a directory` になり、scoop の shim は `Could not create process with command …` で失敗した。`PATH` のうち scoop の 7 つのディレクトリも開けなかった

#### OpenSSH サーバー: 参照

- [Get started with OpenSSH Server for Windows](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse)（`Add-WindowsCapability`、サービスの起動、規則 `OpenSSH-Server-In-TCP`、外し方）
- [Key-Based Authentication in OpenSSH for Windows](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement)（`administrators_authorized_keys` とアクセス権、SID で書く `icacls`、標準ユーザーの `authorized_keys`、鍵で入ったセッションの資格情報）
- [OpenSSH Server Configuration for Windows](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh-server-configuration)（`DefaultShell`、`AuthorizedKeysFile`、使える認証の方法、Windows で使えない設定）
- [Unable to log into SSH server using Microsoft account](https://learn.microsoft.com/en-us/answers/questions/1332375/unable-to-log-into-ssh-server-using-microsoft-acco)（Microsoft Q&A。Microsoft アカウントのパスワードがエラー 1326 で拒否された例と、「Windows Hello サインインのみ」をオフにする回避策）
- [Win32-OpenSSH の wiki](https://github.com/PowerShell/Win32-OpenSSH/wiki)
- `Get-Help Add-WindowsCapability` / `Get-Help Set-NetConnectionProfile` / `Get-Help New-ItemProperty`
- [WireGuard Road Warrior 設定手順](../wireguard.md#almalinux-10-の-pc-からつなぐ)（別の PC からの接続を外出先に広げるとき。本書では試していない）

#### OpenSSH サーバー: 付録: 実機での検証記録（2026-09-29）

この付録の手順番号は、今の番号に付け替えてある。「鍵の節」は[公開鍵でもログインする（任意）](../windows-setup.md#openssh-サーバーに公開鍵でもログインする任意)、「切る節」は[パスワード認証を切る（任意）](../windows-setup.md#openssh-サーバーのパスワード認証を切る任意)のこと。「当時の手順 12」は、手順 7 の後に鍵で対話のログインをしていた手順（今の文書には無い）。

**流し方**:

- Windows の手順は、ブロックを UTF-8（BOM 付き）の `.ps1` にし、Claude Code の PowerShell から `sudo powershell.exe -NoProfile -ExecutionPolicy Bypass -File <ファイル>` で 1 手順ずつ実行した
  - Windows の `sudo` はインラインのモードで、UAC は確認無しで昇格する設定
  - 各 `.ps1` の先頭に、変数のブロック（今の手順 2 と、鍵の節の手順 3。当時は 1 つの手順）を付けた。同じ PowerShell に貼り続けたときと同じ変数にするため
  - `$PUBKEY` は、`''` の中だけを鍵の節の手順 2 の出力に置き換えた
- クライアントの手順は、`wsl.exe -d AlmaLinux-10 --exec bash <スクリプト>` で実行した
  - 手順 8 は、`WIN_HOST=` の後ろだけを書き換えた
  - 当時の手順 12 と Git Bash の任意節の手順 2 の対話は、`script` の擬似端末に `yes`・`whoami`・`exit` を流し込んだ
- 2 回目は、この文書の `powershell` と `bash` のブロックを順に抜き出したファイルを、上の置き換えだけで使った

**1 回目**（下書きのブロック）:

- 手順 3 は、最初に Microsoft Store の PowerShell 7.6.6 で流し、266 秒後に `Add-WindowsCapability` と `Get-WindowsCapability` が `クラスが登録されていません` で失敗した。状態は `NotPresent` のまま
- Windows PowerShell 5.1 で流し直すと、532 秒で `State : Installed`（`RestartNeeded : False`）になった
- 手順 4・5、鍵の節の手順 4、切る節の手順 1、手順 7、当時の手順 12、切る節の手順 2、Git Bash の任意節の手順 1・2 を通した。ホスト鍵の指紋は、手順 7 と、クライアントの `ssh-keygen -lF <WIN_HOST>` で一致した
- ロールバックの手順 1〜4 で、実施前の状態に戻した。`Remove-WindowsCapability` は 6 秒、`RestartNeeded : False`
  - 外した直後に残っていたもの: `C:\ProgramData\ssh` の全ファイル（ホスト鍵・`sshd_config`・`administrators_authorized_keys`）と、`HKLM:\SOFTWARE\OpenSSH` の `DefaultShell`
  - 消えていたもの: サービス `sshd`、`sshd.exe`、規則 `OpenSSH-Server-In-TCP`

**2 回目**（この文書のブロック）:

- 先に、何も変えずに止まるかを確かめた
  - PowerShell 7 で手順 3: `Write-Error: Windows PowerShell（5.1）で貼る。…`
  - `$PUBKEY` が空のまま鍵の節の手順 4: `手順 3 の $PUBKEY が空か、公開鍵の形でない`（`C:\ProgramData\ssh` はできなかった）
- 手順 3 は 486 秒。導入の直後は、`C:\ProgramData\ssh` も `HKLM:\SOFTWARE\OpenSSH` もまだ無く、手順 4 で sshd を起動した後にできた
- 鍵の節の手順 4 の後・切る節の手順 1 の前に、パスワードを聞かれることと、セッションが High Mandatory Level であることを確かめた（ホスト鍵は `UserKnownHostsFile=/dev/null` で、`known_hosts` に残さなかった）
- 切る節の手順 1 は 2 回流し、`PasswordAuthentication` の行が 1 行のままだった
- 当時の手順 12 で、初回の `ED25519 key fingerprint is SHA256:…` が手順 7 と一致し、`yes` の後に cmd のプロンプトになった
- Git Bash の任意節は、手順 1 → 2 → 3（cmd に戻る）→ 1 の順に流し、Git Bash の状態で終えた
- `WIN_HOST` が空のまま、切る節の手順 2 とロールバックの手順 4 のブロックを流し、どちらも何もしないで止まった

**切り分け: WSL から届かなかった接続**:

- 最初に使った試験の誤り
  - `/dev/tcp` でつなぎ、バナーを `head -c 40` で読んでいた
  - Windows の sshd のバナー（`SSH-2.0-OpenSSH_for_Windows_9.5` と CRLF で 33 バイト）の後は、クライアントを待つ。40 バイトがそろわず、つながっていても 5 秒のタイムアウトになった
  - このため、しばらく「どの規則を足しても届かない」と見誤った
- `read -t 5` で 1 行を読む形に直して、測り直した

  | LAN の接続 | 規則 | `<WIN_HOST>`（LAN の IP）あて | WSL の既定の経路の先の IP あて |
  |---|---|---|---|
  | パブリック | 機能の規則だけ | 届かない | 届かない |
  | プライベート | 機能の規則だけ | 届く | 届かない |
  | プライベート | WSL の範囲（`172.25.32.0/20`）からの 22/tcp を許す一時的な規則（パブリック） | 届く | 届く |

- 捨てていたのは、WFP の `Query User` のフィルター（層は `FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4`、条件は `FWPM_CONDITION_ORIGINAL_PROFILE_ID` が 1）
  - `netsh wfp show netevents localport=22` のドロップの記録と、`netsh wfp show filters` で突き合わせた
  - 機能の規則（プライベート）から作られたフィルターの条件は、プロファイル ID が 2
- sshd のログ（`OpenSSH/Operational`）では、WSL から LAN の IP あての接続の送信元は `<WIN_HOST>` だった
- 一時的な規則（`Verify-WSL-sshd`）は、確かめた後に消した
- 途中で、どのプロファイルでも有効なブロックの規則が 1 つ見つかった。別のソフトが作ったもので、特定のローカルユーザーのプロセスだけに効き、SYSTEM で動く sshd には関係しなかった

**切り分け: SSH のセッションで scoop のツールが起動しない**（2 回目の後）:

- 症状
  - Git Bash の既定のシェルで、`ssh … <コマンド>` のたびに `Shim: Could not create process with command '"C:\Users\<WIN_USER>\scoop\apps\zoxide\current\zoxide.exe"  init bash'.` が出た
  - SSH のセッションの `cmd /c dir …\zoxide\current\zoxide.exe` は `ファイルが見つかりません`。Git Bash の `ls -la …\zoxide\current\` は、名前は出るものの、どれもディレクトリで日付が 1601 年の、壊れた属性で出た
  - ローカルのシェルでは、昇格していてもいなくても、`current` を通して動いた
- SSH のセッションの PowerShell で `CreateFileW` を呼ぶと、`…\zoxide\current\zoxide.exe` はエラー 448（`信頼されていないマウントポイントが含まれているため、パスをスキャンできません。`）、`…\zoxide\0.9.9\zoxide.exe` は成功した
- 同じ PowerShell から、自分と親のプロセスの `GetProcessMitigationPolicy(ProcessRedirectionTrustPolicy)` を順にたどった
  - PowerShell・bash 2 つ・sshd 3 つは `flags=0x1`（Enforce）、`services.exe`・`wininit.exe` は `0x0`
  - ローカルの PowerShell は `0x0`
  - IFEO の `sshd.exe` に `MitigationOptions`（19 バイト、最後が `0x10`）があった
- 信頼の判定を試した（向き先はどれも `…\zoxide\0.9.9`）

  | ジャンクション | 所有者 | SSH のセッションから開く |
  |---|---|---|
  | 一般ユーザーの PowerShell で作った | `<HOSTNAME>\<WIN_USER>` | エラー 448 |
  | 管理者の PowerShell（`sudo`）で作った | `BUILTIN\Administrators` | 開けた |
  | 一般ユーザーで作り、管理者で所有者を Administrators に変えた（`icacls /setowner … /L`） | `BUILTIN\Administrators` | エラー 448 |

- SSH のセッションで `PATH` の各ディレクトリを開くと、scoop の `current` を通る 7 つがエラー 448 だった（ほかに、ローカルにも無い WinGet のパスが 1 つ、エラー 2）
- 対処
  - 作り直す処理を一時的なジャンクションで試し、向き先の中身が残ること、読み取り専用の属性が戻ること、2 回目は何もしないこと、一般ユーザーが後から消せることを確かめた
  - scoop の 53 個を作り直し、作り直す前に控えた一覧と、向き先・属性が一致した
  - SSH のセッションで `zoxide`・`rg`・`fd`・`nvim`・`gh`・`jq`・`lazygit`・`node`・`python` が動き、`Shim:` の行は出なくなった。`PATH` の scoop の 7 つも開けた
  - 最後に、`zoxide` の `current` を一般ユーザーで作り直して壊し、[scoop のツールを SSH のセッションで使う（任意）](../windows-setup.md#scoop-のツールを-ssh-のセッションで使う任意)の 2 つのブロックをそのまま流して、直ることを確かめた（手順 1 は 1 行を出し、2 回目は何も出さなかった）

**残っている未確認事項**:

1. LAN の別の PC（AlmaLinux 10）からの接続。送信元が LAN の別の IP になる接続は、まだ流していない
1. 端末に貼る操作そのもの（Windows PowerShell 5.1 の PSReadLine での複数行の貼り付け、`if … else` のブロック）
1. パスフレーズ付きの鍵と、鍵の節の手順 1 で鍵を新しく作る流れ
1. 標準ユーザーの `authorized_keys`、パスワード（Microsoft アカウント）でのログイン
1. 既定の UAC の設定で、SSH のセッションが High Mandatory Level になるか
1. Windows の再起動の後に sshd が自動で起動するか、Windows Update での OpenSSH の更新
1. `scoop update` の後に、更新したアプリが SSH のセッションで起動しなくなり、scoop の任意節の手順 1 で直ること（理屈の上ではそうなるが、実際の更新では試していない）

---

#### OpenSSH サーバー: 付録: 追加の確認（2026-09-30）

前の付録の「残っている未確認事項」のうち、1（LAN の別の IP からの接続）と 6 の前半（再起動の後の自動起動）を、同じ PC で確かめた。Windows の設定（`sshd_config`・登録した鍵・規則・ネットワークのプロファイル）は変えていない。このときの文書は公開鍵が主の版（2026-09-29 の版）で、この付録の手順の番号は今の版に付け替えた。今の版に同じコマンドが無いものは、当時の番号で書いた。

**再起動の後の自動起動**:

- 手順を通した後（2026-09-29 の 13:40）に、Windows は 2 回起動し直していた（システムのイベント ログの `Microsoft-Windows-Kernel-General` の ID 12 で、2026-09-30 の 1:29:00 と 1:43:45）
- `OpenSSH/Operational` の `sshd: Server listening on 0.0.0.0 port 22.` と `sshd: Server listening on :: port 22.` が、1:29:41 と 1:44:18 にあった（起動の 41 秒後と 33 秒後。手では起動していない）
- `Get-Service sshd` は `Running`・`Automatic` で、WSL の AlmaLinux 10 から `<WIN_HOST>` に鍵でログインでき、Git Bash のセッションになった
- 管理者でない PowerShell からは、sshd のプロセスの開始時刻と `C:\ProgramData\ssh\ssh_host_ed25519_key.pub` は読めなかった（`ssh-keygen -lf` は `Permission denied`）。`OpenSSH/Operational` とシステムのイベント ログは読めた

**LAN の別の IP からの接続**:

- クライアント: 同じ PC の VirtualBox 7.2.20 の VM の AlmaLinux 10.2（Atomic Desktop、`openssh-clients-9.9p1`。[virtualbox-guest-bootc.md の付録](virtualbox-guest-bootc.md#付録-windows-のホストの-virtualbox-の-vm-での本実行2026-09-30)の VM）
  - VM のネットワークを、動かしたまま NAT から有線 LAN のアダプターへのブリッジ接続に切り替えた（`VBoxManage controlvm <VM> nic1 bridged <アダプター>`）
  - VM の NetworkManager が DHCP で取り直し、ルーターから `<VM_IP>`（`<WIN_HOST>` と同じサブネットの別の IP）を受け取った
- 鍵: VM に秘密鍵を置かず、WSL の `ssh-agent` に前からの鍵（`administrators_authorized_keys` に登録済み）を載せ、WSL から VM へエージェントを転送して入った
  - VM の `~/.ssh` には鍵が無いので、当時の手順 12（鍵での対話のログイン）などの ssh は、転送されたエージェントの鍵で認証される
- 流し方: WSL の tmux の擬似端末から VM に入り、この文書の `bash` のブロックを抜き出したものを、ブラケットペーストで貼った
  - 手順 8 は、`WIN_HOST=` の後ろを書き換えた。`WIN_USER` は、VM のユーザー名が Windows と違うので、手順 8 のとおり `<WIN_USER>` に直した
- この PC は、Git Bash の任意節（`DefaultShell`）と scoop の任意節を通した状態だった

| 手順 | 結果 |
|---|---|
| 8 | `WIN_HOST = <WIN_HOST>`、`WIN_USER = <WIN_USER>` |
| 当時の 12（今の手順 9 から `-o PubkeyAuthentication=no` を除いた、鍵での対話のログイン） | `ED25519 key fingerprint is SHA256:<指紋>.`（WSL の `ssh-keyscan -t ed25519 <WIN_HOST> \| ssh-keygen -lf -` と一致）→ `yes` → `<WIN_USER>@<HOSTNAME> MINGW64 ~` のプロンプト。`whoami` は `<win_user>`、`echo "$SSH_CONNECTION"` は `<VM_IP> <PORT> <WIN_HOST> 22` |
| パスワード認証を切る 2 | パスワードを聞かずに `<WIN_USER>@<WIN_HOST>: Permission denied (publickey,keyboard-interactive).`、2 つ目は `<win_user>` |
| Git Bash の任意節 2 | `5.3.15(1)-release MINGW64`、`git version 2.55.0.windows.3`、対話のプロンプト → `exit` |
| scoop の任意節 2 | `zoxide 0.9.9`（`Shim:` の行は無い） |
| ロールバック 4 | `# Host <WIN_HOST> found: line 1`〜`3`（ED25519・RSA・ECDSA。ssh がログインの後にほかのホスト鍵も `known_hosts` に足していた）、`… known_hosts updated.`、`Original contents retained as …/known_hosts.old` |

- Windows の `OpenSSH/Operational` には、`sshd: Accepted publickey for <WIN_USER> from <VM_IP> port <PORT> ssh2: ED25519 SHA256:…` が残った（送信元は、この PC の LAN の IP ではなく、VM の IP）
- LAN の接続はプライベートのままで、規則 `OpenSSH-Server-In-TCP`（プライベート）で通った
- `OpenSSH/Operational` の `Accepted publickey` のうち、LAN の別の IP からのものは、この確認の 2 分間の 5 件だけだった。[パスワード認証の付録](#openssh-サーバー-付録-パスワード認証の検証記録2026-09-30)の未確認事項の「利用者の公開鍵での接続は、LAN の別の IP からもログに残っていた」は、この確認の接続
- 終わった後に、VM を NAT に戻し、WSL の `ssh-agent` を止めた

**残っている未確認事項**:

1. LAN の別の PC（実機）からの接続（今回は同じ PC の VM から確かめただけ）
1. 端末に貼る操作そのもの（Windows PowerShell 5.1 の PSReadLine での複数行の貼り付け、`if … else` のブロック）
1. パスフレーズ付きの鍵と、鍵の節の手順 1 で鍵を新しく作る流れ
1. 標準ユーザーの `authorized_keys`、パスワード（Microsoft アカウント）でのログイン
1. 既定の UAC の設定で、SSH のセッションが High Mandatory Level になるか
1. Windows Update での OpenSSH の更新
1. `scoop update` の後に、更新したアプリが SSH のセッションで起動しなくなり、scoop の任意節の手順 1 で直ること

---

#### OpenSSH サーバー: 付録: パスワード認証の検証記録（2026-09-30）

**流し方**:

- 前の付録と同じく、Windows の手順は `.ps1`（UTF-8、BOM 付き）にして、`sudo powershell.exe -NoProfile -ExecutionPolicy Bypass -File` で 1 手順ずつ流した。各 `.ps1` の先頭に手順 2 のブロックを付けた
- 始めの状態は、2026-09-29 の[完了時点の状態](#openssh-サーバー-完了時点の状態)（`PasswordAuthentication no`、鍵を 1 つ登録、既定のシェルは Git Bash、LAN はプライベート）
  - アカウントは Microsoft アカウント（`Get-LocalUser` の `PrincipalSource` が `MicrosoftAccount`）
  - 設定の「Windows Hello サインインのみを許可する」はオン（利用者が画面で確かめた。レジストリの `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device` の `DevicePasswordLessBuildVersion` は 2）
- 手順 6 の再起動の前に、`Get-Process sshd` が 1 つだけ（待ち受けだけで、セッションが無い）ことを確かめた
- パスワードは利用者が自分の端末で入れ、成否は `OpenSSH/Operational` のログで確かめた

**1 回目の結果**（2026-09-29 の後の PC に適用）:

- 手順 6: `…:51:PasswordAuthentication yes` と `…:87:Match Group administrators` が出た。`sshd_config` は 2295 バイトから 2296 バイトになった
- WSL から `ssh -o PubkeyAuthentication=no -o BatchMode=yes <WIN_USER>@<WIN_HOST> true`（パスワードを聞かない形）でつなぐと、`Permission denied (publickey,password,keyboard-interactive).` で終わり、sshd が `password` を返すようになった
- 利用者がスマートフォンの SSH のアプリから WireGuard 越しにつなぎ、Microsoft アカウントのパスワードで入った。`whoami` は `<WIN_USER>`（既定のシェルが Git Bash なので、Git の `whoami`）
  - ログには `sshd: Accepted password for <WIN_USER> from <IP> port <PORT> ssh2` が 2 回残った。`<IP>` は WireGuard のクライアントのアドレス（LAN の外のサブネット）
  - 1 回目の切断の記録は `Received disconnect from <IP> port <PORT>:11: Normal Shutdown`（OpenSSH の `ssh` なら `disconnected by user`）
- WSL から、公開鍵の任意節の手順 5 を流した。パスワードを聞かれずに `<WIN_USER>` が出た（既定のシェルが Git Bash なので、Git の `whoami`）
- 文書を書き直した後に、`## 実施手順` の `powershell` のブロックを順に抜き出し、手順 2〜5・7 を流した
  - 手順 3 は 9 秒で `RestartNeeded : False` と `State : Installed`（入っていたので取りに行かなかった）
  - 手順 4・5 は、`sshd  Running  Automatic`、22 番の 2 行、`<LAN_IF>  Private`、`OpenSSH-Server-In-TCP  True  Private  Inbound  Allow` で、何も変わらなかった
  - 手順 7 は、`<WIN_USER>@<WIN_HOST>` と ED25519 の指紋を出した。指紋は、2026-09-29 に WSL の `known_hosts` に入った鍵（`ssh-keygen -F <WIN_HOST> -l`）と同じだった
- 抜き出した手順 6 は、最初に流したブロックと行が同じだった（末尾の改行だけが違った）
  - このときスマートフォンのセッションがつながっていた（`sshd` のプロセスが 3 つ）ので、再起動する 2 回目は流さなかった
  - 代わりに、`sshd_config` の写しに手順 6 の置き換えを Windows PowerShell 5.1 でもう 1 度当て、ハッシュが変わらないことを確かめた
- [完了時点の状態](#openssh-サーバー-完了時点の状態)の確認のコマンドを流し直し、`sshd_config` と `sshd.pid` の長さのほかは 2026-09-29 と同じ値だった
- スマートフォンのセッションが切れた後に、抜き出した手順 6 をもう 1 度流した。出力は 1 回目と同じで、`sshd_config` のハッシュは変わらず、sshd は再起動した（プロセス ID が変わった）

**2 回目: 実施前の状態からの通し**:

- 試験用のユーザーを 2 つ作った
  - Windows: ローカル アカウントの標準ユーザー（`New-LocalUser` と、`Users` への追加。Administrators には入れない）。パスワードはランダムに作り、作業用のファイルにだけ置いた
  - WSL: Linux のユーザー（`useradd -m`）。公開鍵の任意節を、空の `~/.ssh` から通すため
  - 一時的な `HOME` では代えられなかった。`ssh-keygen` は `$HOME` ではなく passwd のホームを見て、いつものユーザー（`<USER>`）の `~/.ssh/id_ed25519` の `Overwrite (y/n)?` で止まった（何も答えずに打ち切り、鍵が変わっていないことを確かめた）
- 対話（ホスト鍵の確認・パスワード・パスフレーズ・cmd のプロンプト）には、WSL の Python の `pty` で動かす小さなスクリプトで答えた。ブロックは文書から抜き出したまま流した
- 控え: `robocopy /E /COPYALL /B` で `C:\ProgramData\ssh` を、`reg export` で `HKLM\SOFTWARE\OpenSSH` を、`cp -p` で WSL の `known_hosts` と `known_hosts.old` を控えた
- ロールバック: 手順 1 は 6 秒で `State : NotPresent`、手順 2 は `False` が 2 行、手順 3 は `<LAN_IF>  Public`、手順 4 は `found: line 4`〜`6` の 3 行と `known_hosts updated.`
- 手順 2〜7:
  - 手順 3 は 493 秒で `RestartNeeded : False` と `State : Installed`。直後は `C:\ProgramData\ssh` もレジストリのキーも無く、sshd は `Stopped` / `Manual`
  - 手順 4 の後の `sshd_config` は、`C:\Windows\System32\OpenSSH\sshd_config_default` と同じ（2297 バイト、51 行目は `#PasswordAuthentication yes`）
  - 手順 5 で `Public` から `Private` になった
  - 手順 6 の後の `sshd_config`（2296 バイト）は、1 回目の後のもの（`no` から `yes` にしたもの）とハッシュが同じだった
  - 手順 7 は新しいホスト鍵の指紋を出した
- 手順 8・9（試験用の標準ユーザー。`WIN_HOST=` の後ろと、`WIN_USER` の値だけを書き換えた）:
  - 初回の `ED25519 key fingerprint is SHA256:…` が手順 7 と一致し、`yes` の後にパスワードを聞かれた
  - cmd のプロンプトが出て、`whoami` は `<hostname>\<試験用のユーザー>`。`whoami /groups` は `BUILTIN\Users` と `Mandatory Label\Medium Mandatory Level`
  - ログは `Accepted password for <試験用のユーザー> from <WIN_HOST> port <PORT> ssh2`
- 公開鍵の任意節（WSL の試験用のユーザー。`WIN_USER` は検証した PC のユーザー（`<WIN_USER>`）に直した）:
  - 手順 1 は `Created directory '/home/<試験用のユーザー>/.ssh'.` の後にパスフレーズを 2 回聞き、手順 2 は 1 行の公開鍵を出した
  - 手順 3・4 は、`$PUBKEY` の `''` の中だけを手順 2 の出力に置き換えて流した。`icacls` は `NT AUTHORITY\SYSTEM:(F)` と `BUILTIN\Administrators:(F)` の 2 行
  - 手順 5 は、初回のホスト鍵の確認に `yes` と答えると、パスワードではなくパスフレーズ（`Enter passphrase for key …`）を聞き、`<hostname>\<win_user>` を出した
- パスワード認証を切る任意節:
  - 手順 1 は `…:51:PasswordAuthentication no`、`…:87:Match Group administrators`、`…:88:       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys`
  - 手順 2 の 1 つ目は、パスワードを聞かずに `Permission denied (publickey,keyboard-interactive).`。2 つ目はパスフレーズを聞き、`<hostname>\<win_user>` を出した
  - 試験用の標準ユーザーも、パスワードを聞かれずに `Permission denied (publickey,keyboard-interactive).` になった
  - 手順 6 を流し直すと、`Permission denied (publickey,password,keyboard-interactive).` に戻り、試験用の標準ユーザーがパスワードで入れた
- 戻し: sshd を止め、`robocopy /MIR /COPYALL /B`（`sshd.pid` は除く）と `reg import` で戻し、sshd を起動した
  - ファイルのハッシュと `icacls` の出力が控えと一致し、ホスト鍵の指紋は元に戻った。`DefaultShell` も戻った
  - WSL の `known_hosts` を控えから戻すと、いつものユーザー（`<USER>`）の鍵で、ホスト鍵の警告無しに入れた
  - 戻しのスクリプトを最初に流したときは、構文の誤り（Windows PowerShell 5.1 の `( a ; b )`）で何も実行されなかった。そのとき、戻した `known_hosts` の WSL から接続すると、`REMOTE HOST IDENTIFICATION HAS CHANGED!` で止まった

**ロックアウト**（試験用の標準ユーザー）:

- `net accounts` は、しきい値 10 回・ロックの時間 10 分・観測期間 10 分
- 間違ったパスワードを、1 回の接続で 3 回（`ssh` の既定の `NumberOfPasswordPrompts`）ずつ送った

  | 接続 | `BadPasswordAttempts` | ロック |
  |---|---|---|
  | 前 | 0 | 無し |
  | 1 回目 | 3 | 無し |
  | 2 回目 | 6 | 無し |
  | 3 回目 | 9 | 無し |
  | 4 回目 | 10 | 有り |

- セキュリティのログ: 失敗ごとにイベント 4625（ログオンの種類 8、`Status 0xc000006d`・`SubStatus 0xc000006a`、プロセスは `sshd.exe`）。10 回目の直後にイベント 4740（ロック）
- ロックの後は、正しいパスワードでも入れなかった
  - `ssh -v` では、鍵交換が終わった後（ユーザー名を送った段階）で `Connection reset by <WIN_HOST> port 22` になり、パスワードを聞かれなかった
  - sshd のログには何も残らなかった
  - 同じときに検証した PC のユーザー（`<WIN_USER>`）でつなぐと、ふだんどおり認証の方法の一覧（`publickey,password,keyboard-interactive`）が返った
- ロックは 10 分で解けた（20 秒ごとに確かめ、ロックの 10 分 6 秒後に解けていた）。`BadPasswordAttempts` は 0 に戻り、正しいパスワードで入れた

**試験用のユーザーの後片付け**:

- Windows のユーザーは `Remove-LocalUser` で消えたが、プロファイルは `Remove-CimInstance` が `別のプロセスが使用中です` で消せなかった
  - `Win32_UserProfile` は `Loaded : True`。User Profile Service の Operational のログには、最初の SSH のログオン（パスワードで入った 1 回目）でハイブを読み込んだ記録だけがあり、外した記録が無かった
  - そのユーザーの SID で動くプロセスは無く、`reg unload` は `Access is denied.` だった
  - 30 秒ごとに 10 分待っても外れなかったので、プロファイルのフォルダーは残し、再起動の後に消すことにした
- WSL の Linux ユーザーは、WSL が起こしたログインシェルが残っていて 1 回目の `userdel` が失敗し、それを止めてから消した

**再起動の後の自動起動**（ログから）:

- 2026-09-29 の作業の後に、利用者がこの PC を 2 回起動し直していた
- どちらも、起動（System のイベント 6005）と同じ秒か 1 秒後に、`OpenSSH/Operational` に `Server listening on 0.0.0.0 port 22.` と `:: port 22.` が出ていた

**残っている未確認事項**（2026-09-30 の時点）:

1. Microsoft アカウントのパスワードで、手順 8・9 のブロック（OpenSSH の `ssh`）から入ること
1. LAN の別の PC から、この文書の手順で入ること（利用者の公開鍵での接続は、LAN の別の IP からもログに残っていた）
1. 端末に貼る操作そのもの（Windows PowerShell 5.1 の PSReadLine での複数行の貼り付け、bash の対話の入力）
1. 標準ユーザーの鍵での認証（`authorized_keys`）と、既定の UAC の設定での振る舞い
1. Microsoft アカウントのロックアウト
1. Windows Update での OpenSSH の更新
1. 「Windows Hello サインインのみを許可する」をオンにしたまま、パスワードで入れる理由（Q&A の報告とは違った。Microsoft アカウントのパスワードでサインインしたことがあるかどうかなど、条件は調べていない）


#### OpenSSH サーバー: 操作上の注意と併記されていた記録

  - Administrators の一員でログインすると、`whoami /groups` で `Mandatory Label\High Mandatory Level` と、有効な `BUILTIN\Administrators` が出た。cmd のウィンドウのタイトルも `管理者: …` になる


#### OpenSSH サーバー: 操作上の注意と併記されていた記録

  - SSH のパスワードの失敗も、1 回ずつセキュリティのログのイベント 4625（ログオンの種類 8、プロセスは `sshd.exe`）として数えられ、10 回目でロックされた（イベント 4740）


#### OpenSSH サーバー: 操作上の注意と併記されていた記録

  - ロック中は、正しいパスワードでも入れない。パスワードを聞かれる前に `Connection reset by <WIN_HOST> port 22` で切られ、sshd のログにも残らなかった


#### OpenSSH サーバー: 操作上の注意と併記されていた記録

  - ロックは 10 分で解け、正しいパスワードで入れた


#### OpenSSH サーバー: 操作上の注意と併記されていた記録

  - パスワードの認証を有効にすると、Administrators の一員でないユーザーも、パスワードがあれば SSH で入れる。ローカル アカウントの標準ユーザーで、手順 8・9 のとおりに入れた


#### OpenSSH サーバー: 操作上の注意と併記されていた記録

  - WSL の既定の NAT では、WSL の既定の経路の先（`vEthernet (WSL (Hyper-V firewall))` の IP）あての接続は、パブリックとして判定され、LAN の接続をプライベートにした後も捨てられた


#### OpenSSH サーバー: 操作上の注意と併記されていた記録

  - LAN の IP あての接続は、sshd には送信元がこの PC の LAN の IP として届き、LAN のプロファイル（プライベート）で判定された


#### OpenSSH サーバー: 操作上の注意と併記されていた記録

- **設定を変えたとき**: `sshd_config` を変えたら `Restart-Service sshd`（手順 6）。レジストリの `DefaultShell` は、再起動しなくても次のログインから効いた


#### OpenSSH サーバー: 操作上の注意と併記されていた記録

  - 検証では、`Remove-WindowsCapability` は `RestartNeeded : False` を返し、再起動せずに入れ直せた

### OpenSSH サーバー: 参考資料から分離した記録

#### OpenSSH サーバー: 参考資料: 実施手順 / 手順 3: 補足: 入るものと、PowerShell 7 で失敗すること

- 入るのは Windows のオプション機能「OpenSSH サーバー」（設定アプリの「システム」→「オプション機能」と同じもの）。`C:\Windows\System32\OpenSSH\sshd.exe`（`OpenSSH_9.5p2 for Windows`）と、サービス `sshd`、受信の規則 `OpenSSH-Server-In-TCP` ができる
- 入れた直後の `sshd` は `Stopped` / `Manual`。規則は `Enabled True`、`Profile Private`、TCP 22、接続元は `Any`、プログラムは `sshd.exe` に限られている
- クライアント（`ssh.exe` など）は Windows 11 に最初から入っていて、この手順では変わらない。`ssh-agent` のサービスも `Disabled` のまま
- Microsoft Store の PowerShell 7.6.6 の管理者のシェルでは、`Add-WindowsCapability` が約 4 分後に `クラスが登録されていません` で失敗し、`Get-WindowsCapability` も同じエラーになった。どちらも Dism モジュール（`C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\Dism`）のコマンド。Windows PowerShell 5.1 では通った
- 先頭の `if` は、PowerShell 7（`PSEdition` が `Core`）で貼ったときに何もしないで止めるためのもの

#### OpenSSH サーバー: 参考資料: 実施手順 / 手順 4: 補足: 最初の起動で作られるもの

- 最初に起動したときに、`C:\ProgramData\ssh` にホスト鍵 3 組（RSA・ECDSA・ED25519）と `sshd_config`、`logs` ができる。手順 3 の直後は、このディレクトリは空（1 回目）か、無かった（2 回目。ロールバックで消した後）
- レジストリの `HKLM:\SOFTWARE\OpenSSH` も、手順 3 の直後には無く、この時点でできていた（値は無い）。[既定のシェルを Git Bash にする（任意）](../windows-setup.md#ssh-の既定のシェルを-git-bash-にする任意)は、ここに値を足す

#### OpenSSH サーバー: 参考資料: 実施手順 / 手順 6: 補足: 既定でも有効なのに書く理由と、置き換える理由

- 入れた直後の `sshd_config` の 51 行目は `#PasswordAuthentication yes`（コメント）で、パスワード認証は既定で有効。この手順はそれを明示的な行にするので、[パスワード認証を切る（任意）](../windows-setup.md#openssh-サーバーのパスワード認証を切る任意)で `no` にした PC も、この手順を貼れば戻る
- `sshd_config` の末尾は `Match Group administrators` のブロックなので、末尾に足した行はそのブロックの中の設定になる。そこで、既定の行を置き換える
- `sshd -t` は設定の検査だけをする（誤りが無ければ何も出さない）。誤りがあれば再起動しないので、動いている sshd は古い設定のまま残る
- 元の `sshd_config` は ASCII（BOM 無し、改行は CRLF）。Windows PowerShell 5.1 の `Set-Content -Encoding ascii` も CRLF で書く
- パスワード認証を切ってあった PC でこの手順を貼ると、sshd が返す方法は `publickey,keyboard-interactive` から `publickey,password,keyboard-interactive` になった。Microsoft の文書は、Windows の OpenSSH の認証の方法は `password` と `publickey` だけとしている

#### OpenSSH サーバー: 参考資料: 公開鍵でもログインする（任意） / 手順 1: 補足: 鍵の種類とパスフレーズ

- ED25519 にしたのは、Windows の sshd（OpenSSH 9.5p2）と AlmaLinux 10 の ssh（OpenSSH 9.9p1）のどちらも扱え、鍵が短く、この節の手順 3 で 1 行のまま貼れるため
- パスフレーズは、秘密鍵のファイルが漏れたときの守り。空にすると、この節の手順 5 と[パスワード認証を切る（任意）](../windows-setup.md#openssh-サーバーのパスワード認証を切る任意)の手順 2 で聞かれなくなる。後から付けるなら `ssh-keygen -p -f ~/.ssh/id_ed25519`
- 秘密鍵（`~/.ssh/id_ed25519`）はクライアントから出さない。Windows に渡すのは、この節の手順 2 の公開鍵だけ

#### OpenSSH サーバー: 参考資料: 公開鍵でもログインする（任意） / 手順 5: 補足: 鍵で入ったときのログ

- `-o PasswordAuthentication=no` は、鍵が通らなかったときにパスワードへ移らず、そこで終わらせるため
- Windows のログには、`sshd: Accepted publickey for <WIN_USER> from <IP> port <PORT> ssh2: ED25519 SHA256:…` が残る

#### OpenSSH サーバー: 参考資料: パスワード認証を切る（任意） / 手順 1: 補足: 切る前と後

- 行を置き換える理由と `sshd -t` は、[手順 6](../windows-setup.md#openssh-サーバー) の補足と同じ
- この手順の前は、`ssh -o PubkeyAuthentication=no` で `<WIN_USER>@<WIN_HOST>'s password:` と聞かれ、sshd が返す方法は `publickey,password,keyboard-interactive` だった。後は `publickey,keyboard-interactive`
- 残る `keyboard-interactive` は、クライアントにパスワードを聞かずに、すぐ `Permission denied` で終わる（この節の手順 2 で確かめる）。Microsoft の文書は、Windows の OpenSSH の認証の方法は `password` と `publickey` だけで、`KbdInteractiveAuthentication` は使えないとしている

#### OpenSSH サーバー: 参考資料: 既定のシェルを Git Bash にする（任意） / 手順 1: 補足: DefaultShell

- `DefaultShell` は Windows の sshd だけの設定で、`sshd_config` ではなくレジストリに置く。この PC の全ユーザーの SSH のセッションに効く
- `bin\bash.exe` は、Git の `usr\bin\bash.exe` を `MSYSTEM=MINGW64` と `PATH` を整えて起動する入口。コマンドの実行では、sshd が `"c:\program files\git\bin\bash.exe" -c "<コマンド>"` を起動していた（`DefaultShellCommandOption` は設定しなくてよかった）

---

## 統合前の記録: Git の Windows 11（もとは git.md）

もとの `git.md` の検証記録のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の検証記録](almalinux-setup.md#統合前の記録-gitもとは-gitmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

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

### Git: 最新の確認範囲（Windows 11）

- 通したこと（どれも Windows 11 Pro の同じクリーン VM。実機ではない）
  - 2026-10-06〜07: Windows 節の新規導入・PATH の手順 2・3・5、非対話 Bash と隔離した `global` での共通手順 3〜7・9〜11（[付録](#git-付録-windows-11-pro-の-vm-での新規導入の検証2026-10-06)）
  - 2026-10-08: スタートから開いた対話の Git Bash に右クリックのメニューで貼り、実ユーザーの `global` で実施手順 1・3〜11（`system` の `pull.ff=only` を一時的に置いて手順 8 の分岐も）、ロールバックの手順 1〜6、更新の手順 2（[付録](#git-付録-windows-11-pro-の-vm-での対話の-git-bash-による通し検証2026-10-08)）
- 確認していないこと
  - 本人の名前・メールアドレスと、外部のリモートへの認証・push・pull
  - 新しい版に上げる更新、arm64 の Windows
- 機能試験の初回ホスト側通信の終了コード 1 と、後に回収したゲストの成功は別々に記録した。以降の既存記録は、各実施日・対象版・範囲に従う履歴として保持した

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### Git: 補足

#### Git: Windows 11 で Git for Windows を入れる / 手順 3: 補足: winget の定義と、黙って入れたときの選択

**winget の定義**（`Git.Git` 2.55.0.5。2026-10-03 の winget-pkgs）

- インストーラは、上流の GitHub のリリースの `Git-2.55.0.5-64-bit.exe`（Inno Setup）。winget は、定義に書かれた sha256 を確かめてから動かす（[付録](#git-付録-windows-11-の配布物と資料の調査2026-10-03)）
- 定義のスコープは `user` と `machine` の 2 つだが、どちらも同じインストーラで、winget はスコープに合わせたスイッチを渡さない。渡すのは `/SP- /SILENT /SUPPRESSMSGBOXES /NORESTART` と `/LOG=…` だけ
- 入れる先は、インストーラが権限で決める。管理者の権限があれば `C:\Program Files\Git` に入れ、PC 全体の `PATH` とレジストリ（`HKLM`）に書く。Administrators の一員が管理者でない窓から動かすと、インストーラが UAC で昇格を求める（定義の `ElevationRequirement: elevatesSelf`）
- `--scope machine` は、PC 全体に入ることを winget にもそろえるため。付けないと、winget は `user` の項目を選ぶ（winget の設定の既定）
- arm64 の Windows では、同じ定義の `Git-2.55.0.5-arm64.exe` が選ばれる
- 上流は 2026-09-28 に 2.56.0 を出したが、2026-10-03 の winget-pkgs にはまだ無い。載ると、この手順でもそれが入る（2.56.0 から、内部のパスが `mingw64` から `ucrt64` に変わった。上流のリリースノート）

**黙って入れたときの選択**（画面のインストーラの既定と同じ。上流の `install.iss` を読んだ）

| 画面 | 既定の選択 | 書かれるもの |
|---|---|---|
| PATH | Git from the command line and also from 3rd-party software | PC 全体の `PATH` に `C:\Program Files\Git\cmd` |
| 既定のブランチ名 | Let Git decide | `system` に `init.defaultBranch=master` |
| エディタ | Use Vim (the ubiquitous text editor) as Git's default editor | `core.editor` は書かない |
| HTTPS | Use the native Windows Secure Channel library | `system` に `http.sslBackend=schannel` |
| 改行 | Checkout Windows-style, commit Unix-style line endings | `system` に `core.autocrlf=true` |
| 端末 | Use MinTTY | — |
| `git pull` | Merge | `system` に `pull.rebase=false` |
| 認証 | Git Credential Manager | `system` に `credential.helper=manager` |
| ほか | ファイルシステムのキャッシュは有効、シンボリックリンクは無効（開発者モードが無いとき） | `system` に `core.fscache=true`・`core.symlinks=false` |
| 部品 | エクスプローラーの「Open Git Bash here」「Open Git GUI here」・Git LFS・`.git*` と `.sh` の関連付け | — |

- 入れない部品: デスクトップのアイコン、Windows Terminal の Git Bash のプロファイル、毎日の更新の確認
- スタートメニューの「Git」フォルダーには、Git Bash・Git CMD・Git GUI が入る
- `system` の改行・`git pull`・ブランチ名は、[実施手順](../almalinux-setup.md#git)の手順 5・6 で `global` に書いて上書きする
- 上げるとき・入れ直すときは、前に入れたときの選択を引き継ぐ（インストーラが前の選択を覚えている）
- 選択は `--custom '/o:CRLFOption=CRLFCommitAsIs'` のように渡して変えられるが、本書では渡さない（[選択した方針](../reference/almalinux-setup.md#git-選択した方針)）

#### Git: 付録: Windows 11 の Git Bash での検証記録（2026-09-30）

前の付録の未確認事項のうち、Windows 11 の Git Bash での実行、`global` の置き場所、PowerShell・cmd から呼ぶ git、`rerere` を、次の PC で確かめた。

**環境**:

- Windows 11 Pro 25H2（ビルド 26200、日本語）/ x86_64 のノート PC（AMD Ryzen AI MAX+ 395）。[windows-openssh-server.md](../windows-setup.md#openssh-サーバー) を通した PC と同じ
- Git for Windows 2.55.0.windows.3（`C:\Program Files\Git`、GNU bash 5.3.15、`MSYSTEM=MINGW64`）
- 流したのは Claude Code の Bash（Git for Windows の bash）。端末（mintty）ではなく、出力はパイプに出た

**流し方**:

- この文書の `bash` のブロックを機械的に抜き出し（リストの字下げだけ外す）、1 つのスクリプトから順に `.`（source）で読み込んだ。同じシェルに貼り続けたときと同じく、変数は残る
- スクリプトの先頭で `export HOME=$(mktemp -d /tmp/gitmd-home.XXXXXX)` とした
  - `global` はそこの `.gitconfig` に書かれ、その PC の `~/.gitconfig` は変わらなかった（前後の md5 が同じ）
  - `system` は、インストーラが書いた本物（`C:/Program Files/Git/etc/gitconfig`）を読んだ
- 書き換えたのは手順 1 の 2 つの値（`Test User` / `test@example.com`）だけ
- 手順 2 は Windows なので飛ばした。手順 8 は、手順 7 の `pull.ff` が空なので飛ばした
- 改行を直す節の前に、手順書の外で、LF の 2 ファイルのリポジトリを `git -c core.autocrlf=true clone` し、CRLF の 1 行を足した（前の付録と同じ作り方）

| 手順 | 結果 |
|---|---|
| 1 | `GIT_USER_NAME  = Test User`、`GIT_USER_EMAIL = test@example.com` |
| 3 | `git version 2.55.0.windows.3`。`system` の 13 行（[手順 3](../almalinux-setup.md#git) の補足）。`global` の行は無い |
| 4 | `user.name Test User`、`user.email test@example.com` |
| 5・6 | 何も出ない |
| 7 | 14 行が `global`、`pull.ff` は空 |
| 9 | `?? a.txt`・`?? crlf.txt`・`?? 日本語.txt`、`i/crlf  w/crlf  attr/  crlf.txt`、`main`、`* [new branch]      main -> main` と `branch 'main' set up to track 'origin/main'.` |
| 10 | `Created autostash: <HASH>`、`Rebasing (1/1)Applied autostash.`（パイプでは同じ行に続く）、`Successfully rebased and updated refs/heads/main.`。`git log` は `b: b.txt` → `a: 2` → `first` の 1 本で、` M crlf.txt` が残った |
| 11 | 何も出ない |
| 改行を直す 1〜4 | 手順 1 は ` M y.txt` と `2`、手順 2 は `Saved working directory and index state WIP on main: <HASH> init`、手順 3 は `0` で `git status --short` は空、手順 4 は `modified:   y.txt` と `Dropped refs/stash@{0}`。2 つのファイルは `i/lf    w/lf` になり、差分は足した 1 行だけ（CR は付かない） |
| ロールバック 1〜3・5 | 何も出ない。使い捨ての `HOME` の `.gitconfig` は 0 バイトになった |

**手順書の外で確かめたこと**:

| 確認 | 結果 |
|---|---|
| `global` の場所 | Git Bash・PowerShell 7・cmd の `git config --global --list --show-origin` が、どれも `file:C:/Users/<WIN_USER>/.gitconfig` を示した（場所とキーの数だけを見て、値は読んでいない）。その PC では、PowerShell の `git` は `C:\Program Files\Git\mingw64\bin\git.exe`、環境変数 `HOME` は `C:\Users\<WIN_USER>` だった |
| `rerere` | 使い捨ての `HOME` で `rerere.enabled=true`・`merge.conflictStyle=zdiff3` にし、同じ衝突を 2 回起こした。1 回目は `Recorded preimage for 'f'`、解いてコミットすると `Recorded resolution for 'f'.`。2 回目は `Resolved 'f' using previous resolution.` で、ファイルは解いた中身になり、`git status --short` は `UU f` のまま（`git add` はされない） |
| `zdiff3` | 衝突の表示に、共通の祖先の段（`\|\|\|\|\|\|\| <HASH>` の後に元の行）が出た |

##### Git: 未確認事項

- AlmaLinux 10 の実機での本実行と、既存の `~/.gitconfig`（`[core] autocrlf` がある）との組み合わせ
- Git for Windows のインストーラの既定の選択で書かれる値（`core.autocrlf=true` など）と、`git pull` の「Only ever fast-forward」で書かれる `pull.ff=only`
- Git Bash の端末（mintty）に貼る操作そのもの、環境変数 `HOME` の無い Windows の PC
- aarch64 での実行、[更新](../almalinux-setup.md#更新)で新しい版に上がるところ

---

#### Git: 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、winget の定義・インストーラ・上流と winget のソースを読んだ記録。[Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)・[更新](../almalinux-setup.md#更新)の手順 2・[ロールバック](../extra/almalinux-setup.md#git-の道具を消す)の手順 6 は、これをもとに書いた。

**winget の定義**: winget-pkgs（2026-10-03 の `master`、コミット `c612893`）の `manifests/g/Git/Git` の一番新しい版は `2.55.0.5`（`2.56.0` のディレクトリは無い）。`Git.Git.installer.yaml` の抜粋（arm64 の 2 つは、`Git-2.55.0.5-arm64.exe` で同じ形）:

```
PackageIdentifier: Git.Git
PackageVersion: 2.55.0.5
InstallerType: inno
InstallerSwitches:
  Silent: /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
  SilentWithProgress: /SP- /SILENT /SUPPRESSMSGBOXES /NORESTART
UpgradeBehavior: install
ReleaseDate: 2026-08-20
ElevationRequirement: elevatesSelf
Installers:
- Architecture: x64
  Scope: user
  InstallerUrl: https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.5/Git-2.55.0.5-64-bit.exe
  InstallerSha256: D065A4E23C3D9A6B5073D609B5BE0830227EC3CA053C083BA385061DDFAF94C6
- Architecture: x64
  Scope: machine
  InstallerUrl: https://github.com/git-for-windows/git/releases/download/v2.55.0.windows.5/Git-2.55.0.5-64-bit.exe
  InstallerSha256: D065A4E23C3D9A6B5073D609B5BE0830227EC3CA053C083BA385061DDFAF94C6
```

- `Git.Git.locale.en-US.yaml` は、`Publisher: The Git Development Community`・`PackageName: Git`・`Moniker: git`。`Agreements` は無い
- 上流のタグ（`git ls-remote --tags`）の一番新しい正式版は `v2.56.0.windows.1`。winget-pkgs にはまだ載っていなかった

**インストーラ**: 定義の URL から `Git-2.55.0.5-64-bit.exe` を取った:

```
$ sha256sum Git-2.55.0.5-64-bit.exe
d065a4e23c3d9a6b5073d609b5be0830227ec3ca053c083ba385061ddfaf94c6  Git-2.55.0.5-64-bit.exe
```

- 65,343,712 バイト。sha256 は定義の `InstallerSha256` と一致した
- `osslsigncode verify`: Authenticode の署名者は `CN=Johannes Schindelin`（`O=Johannes Schindelin`・`L=Bruehl`・`C=DE`）、ダイジェストは一致、タイムスタンプは `Microsoft Public RSA Timestamping CA 2020` の 2026-08-20 16:05:39 GMT
  - 証明書の連鎖は、Linux の CA の一覧に `Microsoft Identity Verification Root Certificate Authority 2020` が無く、検証できなかった
- `innoextract` 1.9 は、このインストーラ（Inno Setup 7）を読めなかった（`Could not determine setup data version!`）。そのため、既定の選択は上流のソースで確かめた

**インストーラのソース**（git-for-windows/build-extra の `installer/install.iss`。2.55.0(5) のリリースのコミット `f7c8964` と、2026-10-03 の `main` の `0ec0fba` で、下の既定は同じ）:

- `PrivilegesRequired=none`、`DefaultDirName={pf}\Git`（`main` では `{commonpf}\Git`）
  - Inno Setup のソース（jrsoftware/issrc の `Setup.MainFunc.pas`・`Setup.SpawnServer.pas`）では、`none` は管理者の権限を要求しないが、昇格できるユーザー（Administrators の一員で、UAC で分けられたトークン）なら UAC で昇格し直す。管理者の権限で動けば、管理者のモード（`HKLM`・PC 全体の `PATH`）で入れる
  - 入れる先が書き込めないとき（管理者でないとき）は、入れる先の画面で `{userpf}\Git`（`%LOCALAPPDATA%\Programs\Git`）に変える
- 選択（`ReplayChoice`）は、`/o:<キー>=<値>` → `/LOADINF` のファイル → 入っている Git の `system` から推した値 → 前に入れたときの選択 → 既定 の順に決まる
- 既定: `Editor Option=VIM`・`Default Branch Option`（空）・`Path Option=Cmd`・`SSH Option=OpenSSH`・`CURL Option=WinSSL`・`CRLF Option=CRLFAlways`・`Bash Terminal Option=MinTTY`・`Git Pull Behavior Option=Merge`・`Use Credential Manager=Enabled`・`Performance Tweaks FSCache=Enabled`・`Enable Symlinks=Auto`（開発者モードが無く、管理者で動いていれば無効）
- 部品の既定（`Types: default`）: `ext`・`ext\shellhere`・`ext\guihere`・`gitlfs`・`assoc`・`assoc_sh`。`icons`（デスクトップのアイコン）・`autoupdate`・`windowsterminal` は入っていない。スタートメニューの Git Bash・Git CMD・Git GUI は、部品によらず作る
- `system` に書く値: `core.autocrlf`、`pull.rebase`（Merge なら `false`、Rebase なら `true`）か `pull.ff=only`（Fast-forward only）、`credential.helper=manager`、`core.fscache=true`、`core.symlinks`、`http.sslBackend`、`init.defaultBranch`（「Let Git decide」でも `master` を書く）。`core.editor` は、Vim なら書かない
- `Path Option=Cmd` は `{app}\cmd` を `PATH` の最後に足し（管理者のモードでは PC 全体の `PATH`）、削除のときに外す
- Git のファイル（`usr\bin\msys-2.0.dll` など）を使っているプロセスがあると、黙って動かしたときも閉じるよう求める問いを出す。`/SUPPRESSMSGBOXES` では「キャンセル」と答えたことになり、中断する
  - Inno Setup の文書（`NextButtonClick`）: 黙って動かしたときに、入れ始める前に `NextButtonClick` が False を返すと、Setup は終わる

**winget のソース**（microsoft/winget-cli、2026-10-02 のコミット `3973956`）:

- `ManifestCommon.cpp`: Inno Setup の既定のスイッチは、`Silent`・`SilentWithProgress`（定義と同じ）・`Log`（`/LOG="<LOGPATH>"`）・`InstallLocation`（`/DIR="<INSTALLPATH>"`）
- `ShellExecuteInstallerHandler.cpp`: 渡すのは、黙って動かすスイッチ（`--silent` が無ければ `SilentWithProgress`）・`Log`・定義の `Custom`・`--custom`・更新のときの `Update`・`--location` のときの `InstallLocation`。スコープに合わせたスイッチは無い。`--override` があれば、その値だけを渡す
- `UserSettings.h`: スコープの既定（`installBehavior.preferences.scope`）は `user`
- `UninstallFlow.cpp`: Inno Setup のパッケージは、「アプリと機能」の静かな削除のコマンドを動かす。管理者の権限で動いているときは、自分のユーザーのスコープのパッケージの削除を断る（PC 全体に入れたものは当たらない）
  - Inno Setup が書く静かな削除のコマンドは、`"<unins000.exe>" /SILENT`（jrsoftware/issrc の `Setup.Install.pas`）
- 日本語の文言（`Localization/Resources/ja-JP/winget.resw`）: `インストールが完了しました`・`利用可能なアップグレードが見つかりませんでした。`・`正常にアンインストールされました`・`入力条件に一致するインストール済みのパッケージが見つかりませんでした。`

**ほか**:

- Git for Windows のリリースノート（build-extra の `ReleaseNotes.md`）: 2.56.0（2026-09-28）で Windows 8.1 のサポートを外し、`/mingw64/bin/git.exe` が `/ucrt64/bin/git.exe` に変わった
- scoop（ScoopInstaller/Scoop の `lib/core.ps1`）: `Get-HelperPath -Helper Git` は、scoop の git が無ければ `Get-Command git` の場所を返す
- Claude Code の setup の文書: Windows では Git for Windows は任意で、あれば Bash のツールに Git Bash を使い、無ければ PowerShell のツールを使う。Git Bash が見つからないときの `CLAUDE_CODE_GIT_BASH_PATH` の例は `C:\Program Files\Git\bin\bash.exe`

---

#### Git: 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-03）

Linux（クラウドのコンテナ）の PowerShell 7.6.6 と PSScriptAnalyzer 1.25.0 で確かめた。

**構文と Windows PowerShell 5.1 との互換**:

- `powershell` のブロック 5 個（[Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)の手順 2・3・5、[更新](../almalinux-setup.md#更新)の手順 2、[ロールバック](../extra/almalinux-setup.md#git-の道具を消す)の手順 6）を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。指摘は 0

**偽の `winget` で流した**: 5 個のブロックを、受け取った引数を数えて表示するだけの関数 `winget` を置いた pwsh で、順に流した:

- `winget` には、どのブロックでも書いたとおりの引数が 1 つずつ渡った。手順 3 の `install` は 10 個（`install`・`--exact`・`--id`・`Git.Git`・`--source`・`winget`・`--scope`・`machine`・`--accept-source-agreements`・`--accept-package-agreements`）
- 2 つのパスを渡した `Test-Path` は、`False` を 2 行出した（Linux なので、どちらも無い）。`Get-Command git -All | Format-Table Source` は、Linux の `git` の場所を表にした
- winget そのものの動き（定義の選び方・インストーラの起動・表示）は、Windows でしか確かめられない

**残っている未確認事項**:

1. Windows で、[Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)の手順 1〜6 を通すこと（管理者の窓から UAC が出ずに入ること、`C:\Program Files\Git` に入ること、`PATH`、Git Bash が開くこと）
1. 黙って入れたときに `system` に書かれる値が、その節の手順 3 の補足の表のとおりになること。その後に、[実施手順](../almalinux-setup.md#git)の手順 1・3〜11 を Git Bash で通すこと
1. [更新](../almalinux-setup.md#更新)の手順 2 で新しい版に上がること（2.56.0 が winget に載った後）と、Git Bash を開いたまま上げたときの動き
1. [ロールバック](../extra/almalinux-setup.md#git-の道具を消す)の手順 6 で外れること（`PATH` から外れること、残るもの）
1. 公式のインストーラで入れた PC を、winget で上げること
1. arm64 の Windows

---

#### Git: 実施手順 / 手順 7: 補足: 出力と、Windows の模擬

- `git config --get` は、3 つの場所のうち優先される値を返す。`--show-scope` は、その値を書いた場所を前に付ける
- 1 行目の `cd ~` は、リポジトリの中の `local` の設定を拾わないため
- 検証コンテナで、`/etc/gitconfig` に Git for Windows のインストーラの選択で書かれうる値（`core.autocrlf=true`・`pull.rebase=false`・`init.defaultBranch=master`・`pull.ff=only`）を置いて通すと、14 行は `global` になり、`pull.ff` だけが `system	only` になった:

```
user.name             global	<GIT_USER_NAME>
user.email            global	<GIT_USER_EMAIL>
pull.rebase           global	true
rebase.autoStash      global	true
core.autocrlf         global	false
init.defaultBranch    global	main
core.quotepath        global	false
fetch.prune           global	true
push.autoSetupRemote  global	true
rerere.enabled        global	true
merge.conflictStyle   global	zdiff3
diff.algorithm        global	histogram
branch.sort           global	-committerdate
tag.sort              global	version:refname
pull.ff               system	only
```

- Windows 11 の Git Bash（使い捨ての `HOME`）でも、14 行が `global` になり、`pull.ff` は空だった（その PC の `system` に `pull.ff` が無いので、手順 8 は飛ばした）
  - `system` の `init.defaultbranch=master` は、`global` の `main` で上書きされた



### Git: 参考資料から分離した記録

#### Git: 参考資料: Windows 11 で Git for Windows を入れる / 手順 5: 補足: PATH と、ほかの git

- `PATH` に足されるのは `C:\Program Files\Git\cmd`（`git.exe`・`git-gui.exe` など）だけ。`bash`・`ssh`・`ls` などは足されないので、PowerShell の `ssh` は Windows のものが使われる
  - 以前の検証の PC は Git の `usr\bin` も `PATH` にあり、`ssh`・`ssh-keygen` が Git のものになっていた（[windows-openssh-server.md 手順 7](../windows-setup.md#openssh-サーバー) の補足）
- Windows の `PATH` は、PC 全体の値の後ろに自分のユーザーの値が続く。scoop の git（`…\scoop\shims\git.exe`。自分のユーザーの `PATH`）があっても、新しく開いた窓では Git for Windows の `git` が先に見つかる
- scoop は、scoop の git が入っていなければ `PATH` の `git` を使う（scoop のソースの `Get-HelperPath`）。そのため、`scoop update` と `scoop bucket add` は Git for Windows の `git` で動く。scoop の git が入っていると、scoop はそちらを使う
- Claude Code（Windows）は、Git for Windows があれば Bash のツールを Git Bash で動かし、無ければ PowerShell のツールだけを使う（公式の setup の文書）

#### Git: 付録: Windows 11 Pro の VM での新規導入の検証（2026-10-06）

[Windows 11 の初期設定](windows-setup.md#付録-windows-11-pro-の-vm-での導入検証2026-10-06)を検証中の専用 VM で、[Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)の手順 2・3・5 のコードブロックを抜き出して、そのまま実行した。画面で端末を開いて貼る操作は試していない。

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro 26H2 / ビルド 26300.9457 / x64 |
| VM | VirtualBox 7.2.20。Rufus で作った媒体からクリーンインストールした専用 VM |
| PowerShell | Windows PowerShell 5.1.26100.9444 / Desktop / x64。手順 2・3 は管理者、手順 5 は新しい通常権限のプロセス。どちらも同じログオンユーザーの Session 1 |
| WinGet | 1.29.380。確認の `winget list` は `--source winget` 付き |
| 検証時の本文の SHA256 | `A14BFED2E1703FED0B083224F9012CBB631F002B8AC3E77151223F97BA73E57B`（この追記より前） |
| 抜き出したブロックの manifest の SHA256 | `AF11A0B15F103A89BD9A697601A68FD62A772CCFCB43A53FA659A27356B81B55` |

**確認したこと**:

- 手順 2・3（バッチ `20261006-105816Z-096906b0`、完了 10:59:22 UTC）:
  - 未導入時は `Get-Command git` に出力がなく、Git Bash のパスは `False`、一覧は `No installed package found matching input criteria.` だった。最後の winget の終了コード `-1978335212` は、この未導入の確認で期待する結果
  - インストーラーのハッシュ検証が成功し、`Successfully installed` が出た。続く一覧は `Git.Git 2.55.0.5` で、PowerShell のエラーは 0、最後の終了コードは 0
- 手順 5（バッチ `20261006-110243Z-62c3d475`、完了 11:02:43 UTC）:
  - 新しい通常権限のプロセスで、`Get-Command git` は `C:\Program Files\Git\cmd\git.exe`、版は `git version 2.55.0.windows.5` だった
  - `C:\Program Files\Git\bin\bash.exe` と `C:\Program Files\Git\git-bash.exe` の存在確認は、どちらも `True`。PowerShell のエラーは 0、最後の終了コードは 0
- 両バッチとも検証用タスクの終了コードは 0 で、要求したバッチと完了記録が対応した

**確認していないこと**:

- 手順 1・4 の端末を開く画面操作と、手順 6 の Git Bash の起動・表示。手順 4 は新しいプロセスを起動して `PATH` を確認することで代替した
- この VM の Git Bash での[実施手順](../almalinux-setup.md#git)。`GIT_USER_NAME` と `GIT_USER_EMAIL` は設定しておらず、`global` の設定も書いていない
- インストーラーが書いた `system` の値、更新、削除、arm64 の Windows

---

#### Git: 付録: Windows 11 Pro の VM での非対話 Bash による設定の検証（2026-10-07）

前の新規導入と同じ VM で、共通の[実施手順](../almalinux-setup.md#git)の 3・5・6・7 のコードブロックを抜き出して、そのまま実行した。2026-09-30 の実機で `HOME` を使い捨てにした検証とは別の記録で、今回は `HOME` と `CODEX_HOME` を変更していない。

| 項目 | 値 |
|---|---|
| 環境 | Windows 11 Pro の専用 VM、通常権限の `<WIN_USER>`。PowerShell 7.6.6 が非対話の `C:\Program Files\Git\bin\bash.exe` を起動 |
| Git | `git version 2.55.0.windows.5`。`--noprofile --norc` で起動し、プロファイルは読み込まない |
| 実行範囲 | 共通手順 3・5・6・7。子 Bash プロセスだけの `GIT_CONFIG_GLOBAL` で専用 scratch の `global.gitconfig` を指定 |
| 実行時刻 | 2026-10-07 04:18:58〜04:19:20 UTC |
| 検証時の本文の SHA256 | `2541D4BE9E3CD490A2474567EC30635496610BBA507922DD25148837BF4ED6A3`（この追記より前） |
| 実行した source manifest の SHA256 | `87AFDF5F88FA15E43C9BB851FEE6E5586EB531741191C3FA4F29B3CD4A77D180` |

**確認したこと**:

- 手順 3 は実物の `C:/Program Files/Git/etc/gitconfig` を読み、`system` の `core.autocrlf=true` を確認した
- 手順 5 の 3 キーと手順 6 の 9 キー、計 12 キーはすべて指定値になった。独立した読み戻しのスコープは `global`、origin は専用 scratch のファイルで、手順 7 の出力とも一致した。本人設定を省いたため、手順 7 の 14 キーすべてを確認した結果とは扱わない
- 実ユーザーの `.gitconfig`・`.config/git/config`、Git の `etc/gitconfig`、`C:\ProgramData\Git\config` は、前後の存在状態と SHA256 が一致した。`pull.ff` は前後とも未設定で、取得の終了コード 1 と空の出力も一致した
- 4 ブロックの終了コードはすべて 0、補助検証は `passed=true` で CLI の終了コードも 0。作成した `C:\verify\git-config-probe-<GUID>` の scratch だけを削除し、削除成功を確認した
- 証跡は `evidence/remaining-git-20261007-041841-0ff6f533` の `guest-result.json` と `source-manifest-executed.json` に保存した

**確認していないこと**:

- 本人の `GIT_USER_NAME`・`GIT_USER_EMAIL` と共通手順 4。この検証では実ユーザーの `global` に設定を書いていない
- 対話 Git Bash の起動・表示・コピーと貼り付け。非対話 CLI の成功を画面操作の成功とは扱わない
- 共通手順 9〜11 の使い捨てリポジトリでの改行・push・pull と後片付け、更新、削除。古い実機・コンテナの検証結果は前の付録に残す

---

#### Git: 付録: Windows 11 Pro の VM での非対話 Bash による push・pull と後片付けの検証（2026-10-07）

前の設定検証と同じ VM で、共通の[実施手順](../almalinux-setup.md#git)の 4・5・6・9・10・11 の Bash ブロックを変更せず実行した。Windows PowerShell 5.1 の接続用 launcher が、通常権限の PowerShell 7.6.6 の検証 helper を起動し、その helper が Git Bash を非対話で起動した。手順 9・10 は 1 つの Bash セッションで続けて実行した。

| 項目 | 値 |
|---|---|
| 実行環境 | 同じ専用 Windows 11 Pro VM、通常権限の `<WIN_USER>`、PowerShell 7.6.6、Git 2.55.0.windows.5 |
| Bash | `C:\Program Files\Git\bin\bash.exe --noprofile --norc`。子プロセスの `LC_ALL=C` |
| 隔離 | 子 Bash だけの `GIT_CONFIG_GLOBAL` と `TMPDIR` を専用 scratch に指定。`HOME` と `CODEX_HOME` は変更しない |
| 名前・メール | `VM Verification`・`vm-verification@example.invalid`。合成値だけを scratch の設定へ書いた |
| ゲストでの実行時刻 | 2026-10-07 09:27:08〜09:28:01 UTC |
| 実行時の本文の SHA256 | `7EA606C3138280166C7F35A90AB20C7E0D14005C640D8681E87E76C209BFE736`（この追記より前） |
| 実行した manifest の SHA256 | `2B6B05CB73AA6BF9AB78ED1E542543BFA0B34805E9BB75991D3BCCA6FDF462AB` |

**確認したこと**:

- 14 フェーズすべての終了コードが 0、挙動検査 9 件が PASS、Bash 全体の終了コードも 0 で `ALL_PHASES_PASS` を出した。合成の名前・メールと、設定 12 キーの値・`global` のスコープ・scratch の origin を確認した
- 手順 9 の出力に `?? 日本語.txt` が引用や置換文字なしで出た。helper は stdout とフェーズのログを strict UTF-8 で読んだ。`main`、最初のローカル push と `origin/main` の upstream、index と作業ファイルの CRLF が一致した
- 手順 10 は、履歴が 3 コミットの直線で merge がなく、古いローカルコミットが別の ID へ書き換わり、書き換え後の親が remote のコミットになった。設定値の読み戻しだけでなく、実際の rebase を確認した
- autostash の作成出力と実オブジェクト、その親が古いローカルコミットであること、適用の出力と stash が残らないことを確認した。未コミットの CRLF の変更は復元され、HEAD と index の元の内容、日本語のパス、合成のコミット作者も保持された
- 手順 11 の前に `realpath` と `cygpath` で削除先が専用 scratch の配下であることを確認した。手順 11 が fixture だけを消し、外側の scratch と `HOME` を保持した後、helper が scratch を削除した。実ユーザーの設定ファイル 4 件の存在状態と SHA256 は前後一致し、`pull.ff` も未設定のままだった

**初回の接続と後の回収**:

- 初回のホスト側 GuestControl には 55 秒の上限を付けた。ホスト側の CLI 終了コードは 1、直後の結果コピーも 1 だった。この値を Git の実行結果の成功へ置き換えていない
- 後で完成したゲストの結果を回収し、2026-10-07 09:36:30 UTC のコピーは終了コード 0 だった。再実行はしていない。ゲスト自身の結果は終了コード 0・`passed=true`・cleanup 成功で、完了時刻は `guest-result.json` の値を使った
- 証跡は `.verification/evidence/remaining-git-behavior-20261007-092648-ddbf22f4` の `guest-result.json`・実行した manifest/helper・初回の `host-execution-result.json`・後の `host-recovery-result.json`・独立した `git-behavior-assessment.json` に保存した。元の証跡は変更していない

**確認していないこと**:

- 本人の名前・メールを実ユーザーの設定へ反映すること、対話 Git Bash の画面・コピーと貼り付け、外部リモートへの認証や network pull
- `pull.ff` を変更する手順 8、利用中の既存の設定との組み合わせ、更新・削除、arm64 の Windows。今回の隔離した機能テストを全手順の通し成功とは扱わない

---

#### Git: 付録: Windows 11 Pro の VM での対話の Git Bash による通し検証（2026-10-08）

上の付録と同じ VM（[windows-setup.md の検証記録の 2026-10-08 の付録](windows-setup.md#付録-pr-104-の未検証項目を同じ-vm-で確かめた記録2026-10-08)の環境）で、スタートメニューから開いた Git Bash（mintty）に、本文のブロックを右クリックのメニューの「Paste」で貼り、[実施手順](../almalinux-setup.md#git)の手順 1・3〜11 とロールバックの手順 1〜5 を通した。ロールバックの手順 6 と更新の手順 2 は、管理者の Windows PowerShell に貼った。上の付録と違い、子プロセスの `GIT_CONFIG_GLOBAL` は使わず、実ユーザーの `global`（`C:\Users\<WIN_USER>\.gitconfig`）に書いた。

| 項目 | 値 |
|---|---|
| Git | `git version 2.55.0.windows.5`（上の付録で入れたもの） |
| 始める前 | `global` の設定ファイルは無かった。`system`（`C:/Program Files/Git/etc/gitconfig`）の SHA256 は `381C2FDA5A3B5ADF7102F5B05F68D7DC3281A44171F9B40556CA56CFDD8461C3` で、`pull.ff` は無かった |
| 名前とメールアドレス | 試験用の架空の値（`PR104 Verification`・`pr104-verification@example.invalid`） |
| 手順 8 の分岐 | 確かめるため、管理者の窓で一時的に `git config --system pull.ff only` を足した（終わった後に外した） |

**確認したこと**:

- Windows 11 で Git for Windows を入れるの手順 6: スタートメニューの「Git Bash」で、`<WIN_USER>@<HOSTNAME> MINGW64 ~` と `$` の窓が開いた
- 窓の中の右クリックで、`Copy`・`Paste`（`Shift+Ins`）などのメニューが出た。本文に「Paste」で貼る旨を足した
- 手順 1・3〜7: 手順 7 で、`global` の 14 キー（名前・メールアドレスと、手順 5・6 の 12 キー）が出て、`pull.ff` は `system  only` だった
- 手順 8: `global  true`
- 手順 9: `?? 日本語.txt`、`i/crlf  w/crlf`（CRLF のまま入った）、ブランチは `main`、`branch 'main' set up to track 'origin/main'.`
- 手順 10: `Created autostash`・`Applied autostash.`・`Successfully rebased and updated refs/heads/main.`、履歴は一直線、作業中の `M crlf.txt` が残った
- 手順 11: 使い捨てのリポジトリが消えた
- 手順 8 を行わない場合（`global` の `pull.ff` を外し、`system` の `only` だけにした場合）の分岐した pull は、`fatal: Not possible to fast-forward, aborting.`（終了コード 128）で止まった
- ロールバックの手順 1〜4: 今回足した 15 キー（手順 4・5・6・8 のもの）を `--unset` で外した。手順 5 の `git config --global --list` は何も出さなかった。ただし `~/.gitconfig` は 0 バイトのファイルとして残った（始める前は無かった）。本文に注意を足した
- 一時的な `system` の `pull.ff` を外し、`system` の SHA256 が始める前と同じに戻った
- 更新の手順 2（管理者の窓）: `No available upgrade found.`、`winget list` は `Git  Git.Git  2.55.0.5`
- ロールバックの手順 6（管理者の窓、Git Bash は閉じた状態）: `Found Git [Git.Git]`・`Starting package uninstall...`・`Successfully uninstalled`、`winget list` は `No installed package found matching input criteria.`、最後は `False`。途中で「Git Uninstall」の進捗の窓（「Uninstalling Git...」）が出て、何も押さずに閉じた

**検証の手順で起きたこと**:

- 最初の通しでは、検証の操作が窓を前に出すために Alt を 1 回だけ押したため、mintty がメニューの操作に入り、貼った後の Enter が食われた。手順 5・6・7 の 3 つのブロックが 1 行につながって実行され、`pull.rebase` が入らず `tag.sort` が `version:refnamecd` になった。操作を直し、手順 4〜7 を貼り直して（どれも何度貼ってもよい）、正しい値になったことを手順 7 で確かめた

**確認していないこと**:

- 本人の名前・メールアドレスと、外部のリモート（GitHub など）への認証・push・pull
- Ctrl+V・Shift+Insert のキーでの貼り付け（検証の操作では、Shift+Insert が正しいキーとして届かなかった）、arm64 の Windows、Windows の実機

---

## 統合前の記録: Firefox の Windows 11（もとは firefox.md）

もとの `firefox.md` の検証記録のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の検証記録](almalinux-setup.md#統合前の記録-firefoxもとは-firefoxmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。「PC 全体の設定」の手順 1 の管理者の窓を使う） |
| Windows 11 で使う 2〜5 | 「Firefox」の手順 1〜4 |
| Windows 11 の更新 1・2 | 「Git for Windows・Firefox・WezTerm を上げる」の手順 3・4 |
| Windows 11 のロールバック 1〜3 | ロールバックの「OpenSSH・Git for Windows・Firefox・WezTerm を外す」の手順 5〜7 |

### Firefox: 最新の確認範囲（Windows 11）

- 通したこと（どれも Windows 11 Pro の同じクリーン VM。実機ではない）
  - 2026-10-06: Windows 節の手順 2・3 による新規導入。WinGet の一覧と本体の版、Maintenance Service と Default Browser Agent のタスク（[付録](#firefox-付録-windows-11-pro-の-vm-での新規導入の検証2026-10-06)）
  - 2026-10-08: 手順 4 のスタートからの起動・`about:support`（release・日本語・H.264 と AAC のソフトウェアデコード）と、作った mp4・m4a の再生、手順 5 の既定のブラウザーの切り替え（画面の文言に本文を直した）、更新の手順 1、ロールバック（[付録](#firefox-付録-windows-11-pro-の-vm-での追加検証2026-10-08)）
- 確認していないこと
  - 実際の Web の動画と音の出力、ハードウェアのデコード
  - winget で新しい版に上げる更新の手順 2、閉じている間の更新、arm64 の Windows、N エディション、Windows の実機
- 以降の既存記録は、各実施日・対象版・範囲に従う履歴として保持した

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### Firefox: 補足

#### Firefox: Windows 11 で使う: 検証状況の記録

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、winget の定義、Mozilla のインストーラの sha256・署名・中身、Mozilla の文書と Firefox・winget のソース、Linux の PowerShell 7 での構文だけ（[対象と検証環境](almalinux-setup.md#firefox-対象と検証環境)）。

#### Firefox: Windows 11 で使う / 手順 2: 補足: 調べている場所

- Mozilla のインストーラは、アンインストールの登録に `Mozilla Firefox (<構成> <言語>)` の表示名（`DisplayName`）を書く（ESR は `Mozilla Firefox ESR (…)`）。管理者で入れたものは `HKLM`、管理者でないユーザーが自分に入れたもの（`%LOCALAPPDATA%\Mozilla Firefox`）は `HKCU` に書かれる（Firefox のソースの `shared.nsh`。[付録](#firefox-付録-windows-11-の配布物と資料の調査2026-10-03)）
- Microsoft Store 版と winget の `Mozilla.Firefox.MSIX` は、パッケージのアプリ（`Mozilla.MozillaFirefox`）として入る
- 別の言語の Firefox が入っている場所に重ねて入れたときにどうなるかは、確かめていない。そのため、先に外す

#### Firefox: Windows 11 で使う / 手順 3: 補足: winget の定義と、インストーラが入れるもの

**winget の定義**（`Mozilla.Firefox.ja` 157.0。[付録](#firefox-付録-windows-11-の配布物と資料の調査2026-10-03)）

- インストーラは、Mozilla の CDN（`download-installer.cdn.mozilla.net`）の日本語版の `Firefox Setup 157.0.exe`（NSIS）。x64・x86・arm64 があり、winget は PC の構成に合うものを選ぶ
- `Scope` は `machine` だけ（自分のユーザーに入れる定義は無い）。`--scope machine` は、その確かめ
- winget がインストーラに渡すのは `/S /PreventRebootRequired=true`（画面を出さない。使用中のファイルがあっても、再起動が要る処理をしない）
- `--accept-source-agreements` と `--accept-package-agreements` は、winget を初めて使う PC で出る同意の問いに答えるため（続けて貼った行が答えとして食われないように）

**インストーラが入れるもの**（Mozilla の Full Installer Configuration の既定。スイッチで変えていない）

- 本体: `C:\Program Files\Mozilla Firefox`（64 ビットの Windows の既定の場所）
  - 場所は変えない（`--location` を付けない）。既定の場所のときだけ、アンインストールの登録のキーの名前が `Mozilla Firefox` になり、winget の定義の `ProductCode` と合う（Firefox のソースの `postupdate_helper.nsh`）
- Mozilla Maintenance Service: 管理者で入れたときだけ入る。管理者の確認なしに、`C:\Program Files` の Firefox を更新するためのサービス（[Windows 11 の更新](../windows-setup.md#git-for-windowsfirefoxwezterm-を上げる)）
- Default Browser Agent のタスク: タスク スケジューラの `\Mozilla\` に、24 時間ごとに既定のブラウザーが何かを調べて Mozilla に送るタスクを作る（テレメトリを切っていれば送らない。Mozilla の Default Browser Agent の文書）
- ショートカット: デスクトップ・スタートメニュー（ふつうのものとプライベート ブラウジングのもの）と、タスクバーへのピン留め
  - 要らなければ、この手順の `winget install` に `--custom '/DesktopShortcut=false /TaskbarShortcut=false'` を足すと作らないはず（Mozilla の文書のスイッチ。確かめていない）

#### Firefox: 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、winget の定義、配布物、資料とソースを読んだ記録。

##### Firefox: winget の定義

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

##### Firefox: インストーラ

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

##### Firefox: Firefox のソースと文書

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

##### Firefox: winget のソース

winget-cli の `master`（2026-10-02 のコミット `39739564`）を読んだ:

- `src/AppInstallerCommonCore/Manifest/ManifestComparator.cpp` の `LocaleComparator`
  - `--locale` を付けると、それが「要件」になり、インストーラの言語と完全に合う（`MinimumDistanceScoreAsPerfectMatch` 以上）ものだけが候補に残る
  - 言語の無いインストーラをそのまま許すのは、入れた後の更新で前の言語を引き継ぐときだけ。言語の無いインストーラと `ja` の距離を出す `GetDistanceOfLanguage` は読んでいない
- `src/AppInstallerCLICore/Workflows/UninstallFlow.cpp`: NSIS（`Nullsoft`）で入れたものは、`SilentUninstallCommand` があればそれを、無ければ `StandardUninstallCommand` を使う
  - `src/AppInstallerRepositoryCore/Microsoft/ARPHelper.cpp` で `SilentUninstallCommand` を作るのは、アンインストールの登録の `QuietUninstallString` だけ
- `src/AppInstallerCLICore/Argument.cpp`: `winget list` の `--upgrade-available`

##### Firefox: Microsoft の文書と MDN

- 「Windows で既定のアプリを変更する」（日本語）: 設定アプリで [アプリ>既定のアプリ] → [アプリケーションの既定の設定] で Microsoft Edge を選ぶ → [Microsoft Edge を既定のブラウザーにする] の横の [既定に設定]。[Windows 11 で使う](../windows-setup.md#firefox)の手順 5 は、これを Firefox に読み替えた
- MDN の Web video codec guide は「Firefox support for AVC is dependent upon the operating system's built-in or preinstalled codecs」、Web audio codec guide は「Firefox relies upon a platform's native support for AAC」と書いている

---

#### Firefox: 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-03）

Linux（クラウドのコンテナ）の PowerShell 7.6.6（GitHub のリリースの `powershell-7.6.6-linux-x64.tar.gz`）と PSScriptAnalyzer 1.25.0 で確かめた。

**構文と Windows PowerShell 5.1 との互換**:

- Windows 11 の 3 節の `powershell` のブロック 6 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0 で、既定の規則の指摘も 0
  - わざと PowerShell 7 だけの書き方（`??`、`Get-Content -AsByteStream`）を入れたファイルでは、それぞれ指摘が出た
- `winget` はコマンドレットではないので、引数はこの検査の対象外。`winget list` の `--upgrade-available` は winget のソースで確かめた。ほかの引数は [Windows 11 の初期設定](../windows-setup.md)の winget と同じ形

**偽物のコマンドで流した**: 6 個のブロックを、`Get-ItemProperty`・`Get-AppxPackage`・`winget`・`Get-Item`・`Get-Service`・`Get-ScheduledTask`・`Test-Path` を「渡された引数を記録し、決まった値を返す偽物」にして流した。

- [Windows 11 で使う](../windows-setup.md#firefox)の手順 2: アンインストールの登録の偽物（`Mozilla Firefox (x64 ja)`・`Mozilla Maintenance Service`・`Git`・表示名の無いもの）から、`Mozilla Firefox (x64 ja)` の行だけが出た
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

#### Firefox: Windows 11 で使う / 手順 4: 補足: Windows では AAC と H.264 のために何も足さない理由

- Mozilla のサポートの記事（support.mozilla.org）は、この文書を書いた環境からは読めなかった。Windows で再生しては確かめていない

- N エディションの Windows（メディアの機能が入っていない）では、Microsoft の Media Feature Pack が要るはず（確かめていない）

#### Firefox: Windows 11 の更新 / 手順 2: 補足: winget での更新

- winget の定義は、Mozilla が新しい版を出してから、winget-pkgs に定義が足されたときに上がる（どれだけ遅れるかは確かめていない）。Firefox 自身の更新の方が先に上がることもある

### Firefox: 本文から分離した確認範囲と実測

#### Firefox: 付録: Windows 11 Pro の VM での新規導入の検証（2026-10-06）

[Windows 11 の初期設定](windows-setup.md#付録-windows-11-pro-の-vm-での導入検証2026-10-06)を検証中の専用 VM で、[Windows 11 で使う](../windows-setup.md#firefox)の手順 2・3 のコードブロックを抜き出して、そのまま実行した。画面で端末を開いて貼る操作は試していない。

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

---

#### Firefox: 付録: Windows 11 Pro の VM での追加検証（2026-10-08）

上の付録と同じ VM（[windows-setup.md の検証記録の 2026-10-08 の付録](windows-setup.md#付録-pr-104-の未検証項目を同じ-vm-で確かめた記録2026-10-08)の環境）で、上の付録が「確認していないこと」に挙げた画面の操作を確かめた。

**確認したこと**:

- Firefox を初めて起動したとき（この付録の操作で GitHub の文書を開くため）、「Firefox へようこそ」の画面（「続行」）、翻訳の案内、タスクバーへのピン留めの案内が出た。ピン留めは「行わない」を選んだ
- Windows 11 で使うの手順 4:
  - スタートメニューの「Firefox」から起動すると、「Firefox を優先ブラウザーに設定しますか？」の確認が出た。「後で」を選び、既定にするのは手順 5 で行った
  - `about:support` の「アプリケーション基本情報」: 版は 157.0.1（winget で入れた 157.0 から、Firefox が自分で上げた）、「更新チャンネル」は `release`、「プログラムの実行ファイル」は `C:\Program Files\Mozilla Firefox\firefox.exe`。メニューと画面は日本語
  - 「コーデックサポート情報」: `H264` と `AAC` の「ソフトウェアデコーディング」が「対応」（ハードウェアは未対応。VM の画面のアダプターに 3D は無い）
  - 再生の試験: ホストの ffmpeg で作った 6 秒の H.264（baseline）+ AAC の mp4 と、AAC だけの m4a を、VM の中のファイルの HTML で再生した。mp4 は 6.00 秒まで進み、映像は 180 フレームで落ちたフレームは 0、どちらもエラー無し。`canPlayType` と MSE の `isTypeSupported` は対応の旨を返した
  - 音の出力は確かめていない（VM に音声のデバイスが無く、`about:support` の音声のバックエンドは `(remote error)`）
- Windows 11 で使うの手順 5:
  - 設定 →「アプリ」→「既定のアプリ」の見出しは「アプリケーションの既定値を設定する」で、本文の「アプリケーションの既定の設定」と違った。一覧に「Firefox」が 2 つ並んだ（UI Automation の名前では `App_User_Firefox-308046B0AF4A39CB` と `App_Machine_Firefox-308046B0AF4A39CB`）
  - 上の「Firefox」を開くと、「Firefox を既定のブラウザーに設定する」と「既定値に設定」のボタン（本文は「既定のブラウザーにする」「既定に設定」）。押すとチェックの印が出た。本文の文言を画面に合わせて直した
  - 押した後、`.htm`・`.html`・`HTTP`・`HTTPS` が Firefox になった。`.pdf`・`.shtml`・`.svg`・`.xht`・`.xhtml` は Microsoft Edge のまま
  - Win+R に `https://www.mozilla.org/ja/` を入れると、Firefox で開いた
  - レジストリでは、`https` の `UserChoiceLatest` の `ProgId` が `FirefoxURL-308046B0AF4A39CB` になり、従来の `UserChoice` は `MSEdgeHTM` のままだった
- Windows 11 の更新の手順 1: 1 行目は `157.0.1`、`winget list --upgrade-available` は `No installed package found matching input criteria.`（本文の「見つからない旨が出たら、新しい版は無い（Firefox が自分で先に上げていることもある）」）。この節の手順 2 は飛ばした
- Windows 11 のロールバック（Firefox の窓を閉じてから）:
  - この節の手順 1: winget は `Found Mozilla Firefox (x64 ja) [Mozilla.Firefox.ja]`・`Starting package uninstall...`・`Successfully uninstalled` を、アンインストーラーの窓が開いている間に出してプロンプトに戻った（本文の「winget が先に終わっても」のとおり）
  - アンインストーラーの窓「Mozilla Firefox のアンインストール」は、「代わりに Firefox をリフレッシュしますか？」（「Firefox をリフレッシュ」は押さない）→「次へ」→「次の場所の Firefox をアンインストールします: C:\Program Files\Mozilla Firefox」→「削除」→「Mozilla Firefox のアンインストールを完了します」（「Firefox をアンインストールした理由を Mozilla に知らせる」のチェックは外れていた）→「完了」の順だった
  - この節の手順 2: `winget list` は見つからない旨、サービスとタスクは何も出なかったが、`Test-Path` は `True` だった。`C:\Program Files\Mozilla Firefox` に `update_telemetry.json`（37 バイト。Firefox が自分で更新したときに書いたもの）だけが残っていた。本文に箇条書きを足し、検証ではフォルダーごと消した
  - プロファイル（`%APPDATA%\Mozilla\Firefox` と `%LOCALAPPDATA%\Mozilla\Firefox`）は残った（本文のとおり）
  - 既定のアプリの画面では、`.htm`・`.html` などはもう Microsoft Edge に戻っていた。この節の手順 3 として「Microsoft Edge を既定のブラウザーに設定する」の「既定値に設定」を押すと、`http`・`https` の `UserChoice` と `UserChoiceLatest` が `MSEdgeHTM` になった

**確認していないこと**:

- 実際の Web の動画（YouTube など）の再生と音の出力、ハードウェアのデコード
- 2 つの「Firefox」のうち下のもの（`App_Machine_…`）で既定にしたときの動き、Firefox の設定の「既定のブラウザーにする」からの経路
- Background Update のタスクによる閉じている間の更新、winget で新しい版に上げる手順 2、arm64 の Windows、N エディション、Windows の実機

---

## 統合前の記録: WezTerm の Windows 11（もとは wezterm-nightly.md）

もとの `wezterm-nightly.md` の検証記録のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の検証記録](almalinux-setup.md#統合前の記録-weztermもとは-wezterm-nightlymd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。「PC 全体の設定」の手順 1 の管理者の窓を使う） |
| Windows 11 で使う 2〜6 | 「WezTerm」の手順 1〜5 |
| Windows 11 の更新 1〜4 | 「Git for Windows・Firefox・WezTerm を上げる」の手順 1・5〜7 |
| Windows 11 のロールバック 1 | ロールバックの「OpenSSH・Git for Windows・Firefox・WezTerm を外す」の手順 8 |

### WezTerm: 最新の確認範囲（Windows 11）

- 通したこと（どれも Windows 11 Pro の同じクリーン VM。実機ではない）
  - 2026-10-06〜07: Windows 節の手順 2・4・5 による新規導入、CLI の版と登録・PATH・ショートカット、CLI でのフォント解決とラスタ生成（[付録](#wezterm-付録-windows-11-pro-の-vm-での導入検証2026-10-06)）
  - 2026-10-08: 手順 6 のスタートからの起動（この VM では OpenGL のエラーで開かず、`prefer_egl` で開いた）、「Open WezTerm here」の実クリックと HackGen Console NF の表示、更新（同じ版の入れ直し）、ロールバック（[付録](#wezterm-付録-windows-11-pro-の-vm-での追加検証2026-10-08)）
- 確認していないこと
  - 3D の描画がある環境で、設定ファイル無しに手順 6 で窓が開くこと
  - 自分用の設定と Git Bash、Visual C++ Runtime の新規導入、新しい版に上がる更新、arm64 の Windows、Windows の実機
- 以降の既存記録は、各実施日・対象版・範囲に従う履歴として保持した

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### WezTerm: 補足

#### WezTerm: Windows 11 で使う: 検証状況の記録

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、配布物（インストーラの sha256・Inno Setup の版・署名の有無・中の実行ファイル）、インストーラの定義と作り方、Inno Setup の文書とソース、Linux の PowerShell 7 での構文と模擬の実行だけ（[対象と検証環境](almalinux-setup.md#wezterm-対象と検証環境)）。

#### WezTerm: Windows 11 で使う / 手順 2: 補足: 確かめていること

- レジストリのキーは、WezTerm のインストーラ（Inno Setup）がアンインストールのために作る登録。名前の `{BCF6F0DA-…}` はインストーラの定義の `AppId` で、stable と nightly で同じ（winget の `wez.wezterm` と `wez.wezterm.nightly` の `ProductCode` も同じ値）。`DisplayVersion` が WezTerm の版
- WezTerm の実行ファイル（`wezterm.exe`・`wezterm-gui.exe`・`wezterm-mux-server.exe`）は `VCRUNTIME140.dll`（Visual C++ の再頒布可能パッケージ）を読み込むが、インストーラはこれを入れない（[付録](#wezterm-付録-windows-11-の配布物と資料の調査2026-10-03)）。無いと起動できないはず（確かめていない）
- `Get-Process` は、ほかのユーザーやセッションの WezTerm も数える

#### WezTerm: Windows 11 で使う / 手順 3: 補足: winget の定義

- `Microsoft.VCRedist.2015+.x64` は、2026-10-03 の winget-pkgs で 14.51.36247.0。インストーラは Microsoft の `VC_redist.x64.exe`（`download.visualstudio.microsoft.com`）で、winget は定義の sha256 を確かめてから動かす。PC 全体に入る（`Scope: machine`）
- winget の `wez.wezterm.nightly` の定義も、これを依存に書いている（winget で入れると先にこれが入る。本書は winget で WezTerm を入れないので、ここで入れる）
- 定義は、終了コード 3010（再起動が要る）も成功として扱う
- Microsoft の文書では、x64 のパッケージには arm64 の分も入っている。arm64 の Windows では試していない

#### WezTerm: Windows 11 で使う / 手順 4: 本文中の記録

   - `取れない` と `sha256 が一致しない` は、nightly が入れ替わる最中に取ったときにも出る（毎日の入れ替えは日本時間の昼ごろで、2026-10-03 は 13 時 13 分。main が変わったときにも入れ替わる）。少し待って貼り直す

#### WezTerm: Windows 11 で使う / 手順 4: 補足: 確かめていることと、インストーラの引数

**sha256**

- `WezTerm-nightly-setup.exe.sha256` は、同じ nightly のリリースに置かれた sha256（`<64 桁>  WezTerm-nightly-setup.exe` の 1 行）。上流の CI が、ビルドしたファイルからリリースに上げる直前に作る（[付録](#wezterm-付録-windows-11-の配布物と資料の調査2026-10-03)）
- 同じ場所から取るので、分かるのは壊れていないこと（途中で切れていない、入れ替えの最中のものではない）まで。インストーラにも中の `wezterm*.exe` にも Authenticode の署名は無く、本物かどうかは確かめられない（[注意点](../extra/almalinux-setup.md#注意点)）
- sha256 を先に、インストーラを後に取る。間で nightly が入れ替わると、一致せずに止まる
- `-ne` の比較は大文字と小文字を区別しない（`.sha256` は小文字、`Get-FileHash` は大文字）
- `curl.exe` は `C:\Windows\System32\curl.exe` を呼ぶ（[hackgen.md の Windows 11 で使う](../windows-setup.md#hackgen-console-nf)の手順 3 の補足と同じ）
- `curl.exe` で取ったファイルには「インターネットから来た」印（Mark of the Web）が付かないので、署名の無いインストーラでも SmartScreen の確認は出ないはず（確かめていない）

**インストーラの引数**（Inno Setup の標準の引数。WezTerm の公式の文書も、これで動かせると書いている）

- `/VERYSILENT`: 画面も進み具合の窓も出さない
- `/SUPPRESSMSGBOXES`: メッセージボックスを出さず、既定の答えで進む
- `/NORESTART`: 再起動しない
- `/NOCLOSEAPPLICATIONS`: 使っているファイルを持つアプリを閉じない。Inno Setup は、黙って動かすと既定では動いている WezTerm を閉じる（中の Claude Code なども止まる）。このブロックは WezTerm が動いていれば先に止まるので、念のため
- `/LOG="…"`: ログを `%TEMP%\wezterm-setup\setup.log` に書く（失敗したときに読む）
- 終了コードは 0 が成功で、0 以外は失敗（Inno Setup の文書）
- 管理者で入れる定義（`PrivilegesRequired` が既定の `admin`）。管理者の窓から動かすので、UAC の確認は出ないはず
- 定義の最後の「WezTerm を起動する」は `skipifsilent` なので、黙って入れたときは WezTerm を起動しない

**入るもの**（インストーラの定義 `ci/windows-installer.iss`）

- `C:\Program Files\WezTerm` に、`wezterm.exe`（CLI）・`wezterm-gui.exe`（窓）・`wezterm-mux-server.exe`・`strip-ansi-escapes.exe`・`conpty.dll` と `OpenConsole.exe`（Microsoft の署名付き）・`libEGL.dll` と `libGLESv2.dll`・`mesa\opengl32.dll`。アンインストーラの `unins000.exe` と `unins000.dat`
- PC 全体の `PATH`（`HKLM` の環境変数）の末尾に `C:\Program Files\WezTerm`
- スタートメニューの「WezTerm」（全ユーザー）。デスクトップのアイコンは既定で作らない
- エクスプローラーの右クリックの「Open WezTerm here」（フォルダー・フォルダーの背景・ドライブ。`HKLM\Software\Classes`）
- 前に入れた WezTerm があれば、同じ場所に上書きする（Inno Setup の既定の `UsePreviousAppDir`）
- シェル統合のスクリプトと補完は入らない（AlmaLinux 10 の RPM の `/etc/profile.d/wezterm.sh` に当たるものは無い）

#### WezTerm: Windows 11 で使う / 手順 5: 補足: 版の読み方

- 版は、ビルドした日ではなく、もとにした main の最後のコミットの日時と、そのコミットの頭 8 桁（`<年月日>-<時分秒>-<コミット>`）
- nightly は毎日ビルドし直されるが、コミットの無い日は同じ版になる（2026-10-03 のビルドは `20260929-043349-cab25161`）
- `DisplayName` は `WezTerm <版>`（Inno Setup の既定の形）
- `UninstallString` は、[Windows 11 のロールバック](../extra/windows-setup.md#opensshgit-for-windowsfirefoxwezterm-を外す)の手順 1 が使う

#### WezTerm: 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物とソースと資料を読んだ記録。

##### WezTerm: nightly のリリースのファイル

GitHub の `nightly` のリリースの Windows のファイルは 4 つ（`.asc`・`.sig`・`.sha512` は 404）:

| ファイル | 大きさ | `Last-Modified` |
|---|---|---|
| `WezTerm-nightly-setup.exe` | 45,473,308 バイト | 2026-10-03 04:13:07 UTC |
| `WezTerm-nightly-setup.exe.sha256` | 92 バイト | 2026-10-03 04:13:06 UTC |
| `WezTerm-windows-nightly.zip` | 70,856,196 バイト | 2026-10-03 04:13:08 UTC |
| `WezTerm-windows-nightly.zip.sha256` | 94 バイト | 2026-10-03 04:13:06 UTC |

```
$ cat WezTerm-nightly-setup.exe.sha256
1e52712f6111c3583e37eabeeef6c8d2896fe67ec8ce1ef38585e65ca01a923c  WezTerm-nightly-setup.exe
$ sha256sum WezTerm-nightly-setup.exe
1e52712f6111c3583e37eabeeef6c8d2896fe67ec8ce1ef38585e65ca01a923c  WezTerm-nightly-setup.exe
$ strings -n 8 WezTerm-nightly-setup.exe | grep 'Inno Setup' | sort -u
Inno Setup Messages (6.5.0) (u)
Inno Setup Setup Data (6.7.0)
```

- `.sha256` の改行は LF だけで、ハッシュとファイル名の間は空白 2 つ（`sha256sum` の形）
- インストーラは 32 ビットの PE（Inno Setup の起動部）で、PE の証明書テーブル（Authenticode の署名）は大きさ 0。署名は無い
- innoextract 1.9（Ubuntu 24.04 の）は、Inno Setup 6.7 の中身を読めなかった（`Could not determine setup data version!`）。入るファイルは、下のインストーラの定義と zip で見た

zip の中（版のフォルダー名が `20260929-043349-cab25161`。`git ls-remote` の main の先頭も `cab25161…` だった）:

```
WezTerm-windows-20260929-043349-cab25161/conpty.dll
WezTerm-windows-20260929-043349-cab25161/libEGL.dll
WezTerm-windows-20260929-043349-cab25161/libGLESv2.dll
WezTerm-windows-20260929-043349-cab25161/mesa/opengl32.dll
WezTerm-windows-20260929-043349-cab25161/OpenConsole.exe
WezTerm-windows-20260929-043349-cab25161/strip-ansi-escapes.exe
WezTerm-windows-20260929-043349-cab25161/wezterm-gui.exe
WezTerm-windows-20260929-043349-cab25161/wezterm-mux-server.exe
WezTerm-windows-20260929-043349-cab25161/wezterm.exe
WezTerm-windows-20260929-043349-cab25161/wezterm.pdb
```

PE を pefile で読んだ結果:

- どれも x64（`Machine` が `0x8664`）。arm64 のものは無い
- 証明書テーブルがあるのは `conpty.dll` と `OpenConsole.exe`（Microsoft のもの）だけで、`wezterm*.exe`・`strip-ansi-escapes.exe`・`libEGL.dll`・`libGLESv2.dll`・`mesa\opengl32.dll` には無い
- `wezterm.exe`・`wezterm-gui.exe`・`wezterm-mux-server.exe`・`strip-ansi-escapes.exe` の読み込むものに `VCRUNTIME140.dll` がある（ほかは `api-ms-win-crt-*`。Windows に入っている UCRT）

##### WezTerm: インストーラの定義と作り方（main の 2026-10-03 の時点）

`ci/windows-installer.iss`:

- `AppId={{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}`、`DefaultDirName={autopf}\WezTerm`、`ArchitecturesAllowed=x64 arm64`、`ArchitecturesInstallIn64BitMode=x64 arm64`、`MinVersion=10.0.17763`、`ChangesEnvironment=true`
- `PrivilegesRequired=lowest` はコメントにしてあり、既定の `admin`（管理者で入れ、`{autopf}` は `C:\Program Files`）
- `[Tasks]` の `desktopicon` は `Flags: unchecked`。`[Icons]` は `{autoprograms}\WezTerm`（`AppUserModelID: "org.wezfurlong.wezterm"`）
- `[Run]` の `wezterm-gui.exe` の起動は `Flags: nowait postinstall skipifsilent`
- `[Registry]` は `HKA` の `Software\Classes\{Drive,Directory\Background,Directory}\shell\Open WezTerm here`（`uninsdeletekey`）
- `[Code]` の `CurStepChanged(ssPostInstall)` が `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment` の `Path` の末尾に `{app}` を足し、`CurUninstallStepChanged(usPostUninstall)` が消す。`InitializeSetup` で、arm64 の Windows では x64 のエミュレーションがあるかを確かめる
- `[Files]` に Visual C++ の再頒布可能パッケージは無い

`ci/deploy.sh` と `.github/workflows/gen_windows_continuous.yml`:

- 毎日 03:10 UTC（と、main の Rust のファイルなどが変わったとき）に `windows-2025` でビルドし、`BUILD_REASON=Schedule` のときファイル名を `WezTerm-windows-nightly.zip`・`WezTerm-nightly-setup` にする。版（`MyAppVersion`）は `git show -s --format=%cd-%h --date=format:%Y%m%d-%H%M%S`（`core.abbrev=8`）
- 別のジョブ（`ubuntu-latest`）が、ビルドのファイルを受け取って `sha256sum $f > $f.sha256` で `.sha256` を作り、`gh release upload --clobber nightly` で上げる
- Windows の版に署名の手順は無い（`codesign` があるのは macOS の版だけ）

##### WezTerm: Inno Setup（文書と、`jrsoftware/issrc` の 2026-10-03 のソース）

- 黙って動かす引数: `/VERYSILENT`・`/SUPPRESSMSGBOXES`・`/NORESTART`・`/NOCLOSEAPPLICATIONS`・`/LOG="filename"`。終了コードは 0 が成功、1〜8 が失敗の種類
- `CloseApplications` の既定は `yes` で、黙って動かしているときは「使用中のファイルを持つアプリを、コマンドラインで止められない限りいつも閉じて起動し直す」
- アンインストールの登録（`Setup.Install.pas`）: `DisplayName`（`AppVerName` が無ければ `<AppName> <AppVersion>`）・`DisplayVersion`・`InstallLocation`・`UninstallString`（`"<…>\unins000.exe"`）・`QuietUninstallString`（同じものに ` /SILENT`）。キーの名前は `<AppId>_is1`
- アンインストーラ（`unins???.exe`、既定の置き場所は `{app}`）は `/VERYSILENT`・`/SUPPRESSMSGBOXES`・`/NORESTART` を受け付け、`%TEMP%` に自分の写しを作って、写しが消す。「終了コードを受け取った時点では、アンインストールの処理がまだ動いていることがある」

##### WezTerm: winget・scoop・Chocolatey

- winget の `wez.wezterm.nightly`（`manifests/w/wez/wezterm/nightly/`）: `20260929-043349-cab25161` と `20260917-114457-b09b56c2` の 2 つ。どちらも `InstallerUrl` は `…/releases/download/nightly/WezTerm-nightly-setup.exe`、`InstallerType: inno`、`Scope: machine`、`ProductCode: '{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1'`、依存は `Microsoft.VCRedist.2015+.x64`
  - `20260929-043349-cab25161` の `InstallerSha256` は、2026-10-02 06:51 UTC のコミットで `6438C905…DA474`、2026-10-03 06:02 UTC のコミットで `1E52712F…A923C`（この日のインストーラと同じ）に変わった。同じ版でも、ビルドのたびに sha256 が変わる
  - `20260917-114457-b09b56c2` の `InstallerSha256` は `513C4271…530EA` のまま（同じ URL の今のファイルとは合わない）
  - コミットの履歴（2026-08-21〜10-03）では、bot の更新は 1〜11 日おきで、毎日ではない（2026-09-21 の次は 10-02）
- winget の `wez.wezterm`: 最新は `20240203-110809-5046fc22`。`ProductCode` は nightly と同じ
- winget の `Microsoft.VCRedist.2015+.x64`: 最新は `14.51.36247.0`（`InstallerType: burn`、`Scope: machine`、`InstallerSuccessCodes: 3010`）
- scoop の `versions/wezterm-nightly`: `"version": "nightly"`、`url` は `…/releases/download/nightly/WezTerm-windows-nightly.zip`、`hash` は無い。scoop の `lib/install.ps1` は、版が `nightly` のとき `This is a nightly version. Downloaded files won't be verified.` と出して確かめない
- scoop の `extras/wezterm`: `20240203-110809-5046fc22`
- Chocolatey の `wezterm`: `20240203.110809.0`。`wezterm-nightly` は無い

##### WezTerm: WezTerm のソース（main）

- `config/src/config.rs` の `load_with_overrides`: `~/.wezterm.lua` → `CONFIG_DIRS` の `wezterm.lua` の順に並べ、Windows だけ `current_exe()` のフォルダーの `wezterm.lua` を先頭に入れ、その前に `WEZTERM_CONFIG_FILE`、さらに前に `--config-file`。`HOME_DIR` は `dirs_next::home_dir()`（Windows では `%USERPROFILE%`）、`CONFIG_DIRS` は `XDG_CONFIG_HOME` があれば `<それ>\wezterm`、無ければ `<HOME>\.config\wezterm`
- 作業用のフォルダー: `RUNTIME_DIR` は `dirs_next::runtime_dir()` が無い Windows では `<HOME>\.local\share\wezterm`、`DATA_DIR` は `dirs_next::data_dir()`（`%APPDATA%`）の `wezterm`、`CACHE_DIR` は `dirs_next::cache_dir()`（`%LOCALAPPDATA%`）の `wezterm`
- `wezterm-gui/src/update.rs`: 更新の確認は `releases/latest`（stable）の `tag_name` と今の版を文字列で比べ、新しいときだけ知らせる
- 公式の文書（`docs/install/windows.md`）: インストーラは Inno Setup で、Program Files に入れて `PATH` に登録する。Inno Setup の標準の引数で動かせる。nightly の setup.exe と zip へのリンクがある。winget・scoop・Chocolatey の案内は stable（`wez.wezterm`・`extras/wezterm`・`wezterm`）
- 公式の文書（`docs/config/launch.md`）: Windows で `default_prog` が無いときは `%COMSPEC%`、無ければ `cmd.exe`

---

#### WezTerm: 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-03）

Linux（クラウドのコンテナ）の PowerShell 7.6.6 と PSScriptAnalyzer 1.25.0 で確かめた。

**構文と Windows PowerShell 5.1 との互換**:

- Windows 11 の 3 節の `powershell` のブロック 6 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）と、既定の規則を当てた。指摘は 0

**[Windows 11 で使う](../windows-setup.md#wezterm)の手順 4 のブロック**を、パスの `\` を `/` に替え、`$env:WINDIR`・`$env:TEMP`・`C:\Program Files\WezTerm` を一時的なディレクトリにして流した。`System32/curl.exe` は Linux の `curl` を呼ぶ小さなスクリプト（失敗・壊れたファイル・中身の違う `.sha256` を作れる）、`Get-Process` と `Start-Process` は偽物（`Start-Process` は引数を出し、`wezterm.exe` の代わりに版を出すスクリプトを置く）、管理者の判定は値に置き換えた:

- 通常: 本物の `.sha256` とインストーラを取り、sha256 が一致し、`Start-Process` に `-FilePath <一時フォルダー>/WezTerm-nightly-setup.exe` と `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCLOSEAPPLICATIONS /LOG="<一時フォルダー>/setup.log"` が渡った。`WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0` と `wezterm 20260929-043349-cab25161` が出て、一時フォルダーが消えた
- 管理者でない・`vcruntime140.dll` が無い・WezTerm が動いている: それぞれの `中断:` で止まり、何も取らなかった
- `curl` の失敗: `中断: WezTerm-nightly-setup.exe.sha256 を取れない`
- 取ったインストーラに 1 バイト足したもの: `中断: WezTerm-nightly-setup.exe の sha256 が一致しない`（`Start-Process` は呼ばれず、取ったものは一時フォルダーに残った）
- `.sha256` の中身が `Not Found`: `中断: WezTerm-nightly-setup.exe.sha256 に sha256 の行が無い`
- インストーラの終了コードが 4: `中断: インストーラが終了コード 4 で終わった（ログは <一時フォルダー>/setup.log）`

**[Windows 11 のロールバック](../extra/windows-setup.md#opensshgit-for-windowsfirefoxwezterm-を外す)の手順 1 のブロック**を、`C:\Program Files\WezTerm` を一時的なディレクトリにして流した。`Get-ItemProperty`・`Test-Path`（登録のキーだけ）・`Get-Process`・`Start-Process` を偽物にし、`Start-Process` は 3 秒後に登録とフォルダーを消す（アンインストーラの写しが後から消すのをまねる）:

- 通常: `Start-Process` に `-FilePath C:\Program Files\WezTerm\unins000.exe`（`UninstallString` の引用符の中）と `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART` が渡り、3 秒待ってから `False` が 2 行出た
- 登録が無い・`UninstallString` が別の形（`MsiExec.exe /X{0000}`）・WezTerm が動いている・アンインストーラの終了コードが 1: それぞれの `中断:` で止まった
- フォルダーに `wezterm.lua` が残るとき: 60 秒待ってから `False` と `True` が出た

[Windows 11 で使う](../windows-setup.md#wezterm)の手順 2 のブロックも、管理者の判定を値に置き換えて流し、`VCRuntime` が偽物の `vcruntime140.dll` の有無で `True` と `False` になることを見た。

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. インストーラが黙って入り、`PATH`・スタートメニュー・右クリックのメニュー・アンインストールの登録ができること。前の版が入っている PC で上書きできること
1. `VCRUNTIME140.dll` の無い PC で WezTerm が起動しないことと、[Windows 11 で使う](../windows-setup.md#wezterm)の手順 3 で起動するようになること
1. スタートメニューから起動した WezTerm の窓と、自分用の設定での Git Bash
1. アンインストーラが黙って消すこと
1. arm64 の Windows

### WezTerm: 本文から分離した確認範囲と実測

#### WezTerm: 付録: Windows 11 Pro の VM での導入検証（2026-10-06）

Rufus で作ったインストールメディアからクリーンインストールした専用 VM で、[Windows 11 の初期設定](windows-setup.md#付録-windows-11-pro-の-vm-での導入検証2026-10-06)の後に実行した。本文の PowerShell のブロックを抽出して、サインイン中の同じユーザーの管理者の Windows PowerShell に実行した。GUI のコピー・貼り付けや WezTerm の起動は試していない。

| 項目 | 確認した値 |
|---|---|
| OS | Windows 11 Pro 26H2、26300.9457、x64 |
| PowerShell | Windows PowerShell 5.1.26100.9444、64 ビット、管理者、セッション 1 |
| 初回導入前 | `Version`・`Location`・`OnPath`・`Running` は空、`Admin: True`、`VCRuntime: True` |
| Visual C++ Runtime | Windows 初期設定の「アプリを入れる」の手順 3 の依存関係として導入済み。この節の手順 3 は条件により飛ばした |
| 作業フォルダー | 実行前に `%TEMP%\wezterm-setup` が無いことを確認 |
| 入った版 | `20261005-054844-37254829` |

**初回導入と確認（この節の手順 2・4・5）**:

- 実行記録は `20261006-110954Z-cd78c35a`。2026-10-06 11:10:17.710 UTC に完了し、手順ごとのエラーは 0、最後の CLI とタスクの終了値は 0、開始と完了の対応も確認した
- 手順 4 は `WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0` と `wezterm 20261005-054844-37254829` を出した。本文の `.sha256` とインストーラの照合を通して初回導入された
- 手順 5 の登録は `DisplayName: WezTerm version 20261005-054844-37254829`、`DisplayVersion: 20261005-054844-37254829`、`InstallLocation: C:\Program Files\WezTerm\`。`UninstallString` は `"C:\Program Files\WezTerm\unins000.exe"` だった
- CLI の版も登録と一致した。PC 全体の `PATH` の `C:\Program Files\WezTerm` は 1 行だけで、全ユーザーのスタートメニューの `WezTerm.lnk` は `True`
- 導入先に `wezterm.exe`・`wezterm-gui.exe`・`wezterm-mux-server.exe`・`unins000.exe`・`unins000.dat`、`conpty.dll`・`OpenConsole.exe`・`strip-ansi-escapes.exe`・`libEGL.dll`・`libGLESv2.dll`・`mesa` が並ぶことを確認した
- 2026-10-07 04:04:16〜04:04:23 UTC の追加読み取りは、通常権限の PowerShell 7.6.6・Session 1 で行った。`HKCR\Directory\shell\Open WezTerm here` と `HKCR\Directory\Background\shell\Open WezTerm here` のコマンド項目が存在した。メニューをクリックして実際に起動することは未確認。証跡は `.verification/evidence/remaining-local-20261007-040410-0e3dc87e/guest-result.json`

**未検証の範囲**:

- 手順 1 の GUI での管理者の PowerShell の開き方とコピー・貼り付け、手順 6 の WezTerm の窓・既定のシェル、「Open WezTerm here」の動作。ショートカットやファイルがあることと、GUI が動くことは別に確認する必要がある
- 自分用の設定と Git Bash、設定ファイルの探索順、新しい PowerShell が PC 全体の `PATH` を読むこと
- `VCRUNTIME140.dll` が無い場合と手順 3 による導入、前の版への上書き、更新・アンインストール、arm64。Windows の実機での通し実行

2026-10-03 以前の付録は当時の確認範囲を記した履歴として保持した。今回も本文のコマンドは変更していない。

---

#### WezTerm: 付録: Windows 11 Pro の VM での HackGen の CLI ラスタ生成の検証（2026-10-07）

前の初回導入と同じ VM の通常権限の PowerShell 7.6.6・Session 1 で、導入済みの `wezterm.exe` の `ls-fonts` を使った。`--config-file` で scratch の設定だけを渡し、`--codepoints 61,3042,6f22,2192,e0b0,f07c --rasterize-ascii` の stdout を採取した。設定はファミリーだけを替えた 2 通りで、フォントサイズは 12.0、`custom_block_glyphs=false` と `check_for_updates=false`。本文の導入コードと実ユーザーの設定は変更していない。

**フォント解決と数値ラスタ**:

- `HackGen Console NF` は `HackGenConsoleNF-Regular.ttf`、`HackGen35 Console NF` は `HackGen35ConsoleNF-Regular.ttf` を、ユーザーのフォントフォルダーから DirectWrite で使った。計 12 glyph はすべて ID が 0 以外、`notdef` なし。フォントの fallback と WezTerm の独自 glyph は出なかった
- 各文字の bearing と offset、ANSI `38:6` の RGBA を記録した。NUL padding は解析用のコピーだけから除き、元の stdout と JSON は変更していない。glyph 名中の `#0` を ID 0 と誤認せず、カンマ後の数値を glyph ID として判定した
- 下表のセル幅は両ファミリーで一致した。ラスタ欄は幅×高さと、alpha が 0 でないピクセル数／全ピクセル数。すべての文字に透明でないピクセルがあり、各 RGBA の値は 0〜255 に収まった

| 文字・コードポイント | セル幅 | HackGen Console NF | HackGen35 Console NF |
|---|---:|---|---|
| a / U+0061 | 1 | 8×8、52/64 | 8×9、61/72 |
| あ / U+3042 | 2 | 13×14、117/182 | 14×14、117/196 |
| 漢 / U+6F22 | 2 | 15×16、144/240 | 16×16、150/256 |
| → / U+2192 | 1 | 10×9、39/90 | 10×9、38/90 |
| Powerline / U+E0B0 | 1 | 10×19、117/190 | 11×19、137/209 |
| Nerd Fonts / U+F07C | 1 | 16×13、170/208 | 16×13、162/208 |

- 計 2005 ピクセル中、alpha が 0 以外は 1304、255 は 359。HackGen35 の U+2192 は最大 alpha 254、他の 11 glyph は最大 255 だった。各文字に 255 のピクセルが必要という判定はしていない
- 両 CLI の終了コードは 0、stderr は空、09:20:26〜09:20:46 UTC に実行した。scratch の削除は成功し、実ユーザーとインストール先の WezTerm 設定 3 パスの存在状態は前後不変だった
- 証跡は `.verification/evidence/remaining-wezterm-font-20261007-092017-4d5448f6` の `guest-result.json` と `glyph-assessment.json`。raw の SHA256 は `9B2C1DC0A426F36FF2971561FCC041077D62EFE718D8D85403C68CB1E6A40475`、独立した評価 JSON は `C12A3BF87D1FD9BE9C9061AD12DB6F6866B2A4141E993CC3F80221184E753C68`。文字ごとの RGBA の範囲・透明でない領域・ラスタの SHA256 も評価 JSON に保存した

**確認していないこと**:

- スタートからの WezTerm GUI 起動、既定のシェル、GUI のフォントメニューと選択、スクリーン上の字形・太字・行の高さ、右クリックのメニューの実クリック。CLI の数値ラスタを画面上の描画の確認へ広げない
- 自分用の設定と Git Bash、設定ファイルの探索順、選んだ文字以外、Visual C++ Runtime が無い場合、更新・上書き・アンインストール、arm64 の Windows。以前の付録はその時点の履歴として保持した

---

#### WezTerm: 付録: Windows 11 Pro の VM での追加検証（2026-10-08）

上の付録と同じ VM（[windows-setup.md の検証記録の 2026-10-08 の付録](windows-setup.md#付録-pr-104-の未検証項目を同じ-vm-で確かめた記録2026-10-08)の環境）で、GUI の起動・右クリックの項目・更新を確かめた。手順は [Windows 11 で使う](../windows-setup.md#wezterm)の番号。WezTerm は 20261005-054844-37254829。

**手順 6（スタートメニューから起動）**:

- スタートメニューの「WezTerm」から起動すると、窓が開かずにプロセスが終わった。`%USERPROFILE%\.local\share\wezterm\wezterm-gui.exe-log-<番号>.txt` に `ERROR  wezterm_gui::frontend > Failed to create window: The OpenGL implementation is too old to work with glium`
  - この VM の画面のアダプターは VirtualBox の VBoxSVGA で、3D の描画を使っていない
  - `wezterm-gui.exe --config front_end="Software"` でも同じエラー
  - `wezterm-gui.exe --config prefer_egl=true` では窓が開き、中で `cmd.exe` が動いた（設定ファイルが無いときのシェル。`%COMSPEC%`）。窓の中の `wezterm --version` は `wezterm 20261005-054844-37254829`
  - 本文の手順 6 に、ログの場所と `config.prefer_egl = true` の箇条書きを足した
- エクスプローラーでフォルダーの背景を右クリックすると、旧形式のメニュー（windows-setup.md の「表示と入力」の手順 2）に「Open WezTerm here」がそのまま出た。レジストリのコマンドは `wezterm-gui.exe start --no-auto-connect --cwd "%V"`
  - 設定ファイルが無いままでは、同じ OpenGL のエラーで開かなかった
  - 一時的に `%USERPROFILE%\.wezterm.lua`（`config.prefer_egl = true` と `config.font = wezterm.font 'HackGen Console NF'` だけ）を置くと、`C:\verify\gui-fixtures` で窓が開いた。英字・かな・漢字・矢印・Powerline の記号・Nerd Font のフォルダーのアイコン・日本語の文が、HackGen Console NF で表示された（画面で確かめた）
  - 一時的な設定と試験用の文のファイルは、確かめた後に消した

**Windows 11 の更新**:

- この節の手順 2: 1 行目は `20261005-054844-37254829`、WezTerm のプロセスは無し
- この節の手順 3（手順 4 の貼り直し）: `WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0` と `wezterm 20261005-054844-37254829`。版は同じで、本文の「同じ版なら、main に新しいコミットが無かった」に当たる
- この節の手順 1・4 は、Remote Control のタスクが無いので飛ばした

**Windows 11 のロールバック**:

- この節の手順 1（WezTerm の窓は無い状態）: `False` が 2 行出て、その後は何も出なかった（登録・`C:\Program Files\WezTerm`・`PATH` の行が消えた）

**確認していないこと**:

- 3D の描画がある環境（実機の GPU）で、設定ファイル無しに手順 6 で窓が開くこと
- 自分用の設定（`ryo-aoki-pc/wezterm`）と Git Bash、新しい版に上がる更新、arm64 の Windows、Windows の実機

---

## 統合前の記録: git-delta の Windows 11（もとは git-delta.md）

もとの `git-delta.md` の検証記録のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の検証記録](almalinux-setup.md#統合前の記録-git-deltaもとは-git-deltamd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。前の項で開いた窓を使う） |
| Windows 11 で使う 2〜5 | 「git-delta」の手順 1〜4 |
| Windows 11 の更新 1 | 「scoop・winget・WSL を上げる」の手順 1・2 |
| Windows 11 のロールバック 1・3 | ロールバックの「Git の道具を消す」の手順 3・4 |
| Windows 11 のロールバック 2 | ロールバックの「Git Bash の設定を戻す」の手順 3 |

### git-delta: 補足

#### git-delta: Windows 11 で使う: 検証状況の記録

> [!WARNING]
> **[Windows 11 で使う](../windows-setup.md#git-delta)と、後ろの Windows 11 の 2 節（更新・ロールバック）は、Windows の実機では未検証**（2026-10-08 に書いた。Windows を動かせないクラウドの Linux のコンテナで書き、どのブロックも Windows では貼っていない）。確かめたのは、scoop と winget の定義、配布物の中身と sha256、delta・Git for Windows・Scoop のソース、PowerShell の構文と偽物のコマンドでの模擬だけ（[対象と検証環境](almalinux-setup.md#git-delta-対象と検証環境)の「状態（Windows 11）」）。

#### git-delta: 付録: Windows 11 の配布物と資料の調査（2026-10-08）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、scoop と winget の定義・配布物・delta と Git for Windows と Scoop のソースを読んだ記録。**Windows の実機では未検証**。

**定義**（2026-10-08 の `ScoopInstaller/Main` と `microsoft/winget-pkgs` の `master`）:

- scoop の `bucket/delta.json`: `version` は `0.20.1`。`architecture` は `64bit` だけで、URL は `https://github.com/dandavison/delta/releases/download/0.20.1/delta-0.20.1-x86_64-pc-windows-msvc.zip`、hash は `c9af7484b33f1dbc1312a892fc7d5753a6d3365140a4000d49e575a2de742c25`、`extract_dir` は `delta-0.20.1-x86_64-pc-windows-msvc`
  - `bin` は `delta.exe` の 1 つ。`depends` と `suggest` は無い（VC++ ランタイムも less も入れない）
- winget の `manifests/d/dandavison/delta/0.20.1/dandavison.delta.installer.yaml`: `InstallerType: zip`・`NestedInstallerType: portable`・`ReleaseDate: 2026-10-04`。`InstallerSha256` は scoop と同じ値。`Dependencies` に `Microsoft.VCRedist.2015+.x64`
- 上流のタグ（`git ls-remote --tags https://github.com/dandavison/delta`）の版の最新は `0.20.1`（その前は `0.20.0`）

**配布物**（scoop の定義の URL から取った zip）:

```
$ sha256sum delta-win.zip
c9af7484b33f1dbc1312a892fc7d5753a6d3365140a4000d49e575a2de742c25  delta-win.zip
$ unzip -l delta-win.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
  7618048  2026-10-04 19:35   delta-0.20.1-x86_64-pc-windows-msvc/delta.exe
     1058  2026-10-04 19:35   delta-0.20.1-x86_64-pc-windows-msvc/LICENSE
     7991  2026-10-04 19:35   delta-0.20.1-x86_64-pc-windows-msvc/README.md
---------                     -------
  7627097                     3 files
$ objdump -p delta-0.20.1-x86_64-pc-windows-msvc/delta.exe | grep 'DLL Name' | awk '{print $3}' | sort -fu | tr '\n' ' '
advapi32.dll api-ms-win-core-handle-l1-1-0.dll api-ms-win-core-synch-l1-2-0.dll api-ms-win-crt-convert-l1-1-0.dll api-ms-win-crt-filesystem-l1-1-0.dll api-ms-win-crt-heap-l1-1-0.dll api-ms-win-crt-locale-l1-1-0.dll api-ms-win-crt-math-l1-1-0.dll api-ms-win-crt-runtime-l1-1-0.dll api-ms-win-crt-stdio-l1-1-0.dll api-ms-win-crt-string-l1-1-0.dll api-ms-win-crt-time-l1-1-0.dll bcryptprimitives.dll combase.dll iphlpapi.dll kernel32.dll netapi32.dll ntdll.dll ole32.dll oleaut32.dll pdh.dll powrprof.dll psapi.dll Secur32.dll shell32.dll VCRUNTIME140.dll ws2_32.dll
```

- `delta.exe` は `PE32+ executable (console) x86-64`（`file` の表示）。インポート表に `VCRUNTIME140.dll` がある（msvc のビルドで、CRT を静的にリンクしていない）。`api-ms-win-crt-*` は Windows 10 以降に付いている UCRT
- PE のセキュリティのディレクトリは空で、Authenticode の署名は無い

**delta 0.20.1 のソース**（`0.20.1` のタグ）:

- `src/env.rs`: ページャの候補は、`DELTA_PAGER` と、bat の `get_pager_executable`（`BAT_PAGER`、無ければ `PAGER`）
- `src/utils/bat/output.rs`: `delta.pager`（`--pager`）があればそれを、無ければ環境変数の候補を、どれも無ければ `less` を使う。`grep_cli::resolve_binary` で PATH から探し、見つからなければ、ページャを起動せずに標準出力へ書く。`less` には `--RAW-CONTROL-CHARS` と（1 画面に収まれば終わる）`--quit-if-one-screen` を渡し、Windows では less の版が 558 より前なら `--no-init` も足す
- `src/features/navigate.rs`: `navigate` が `true` のとき、less の検索履歴の写しを作って `LESSHISTFILE` で渡す。場所は、Windows では `dirs::data_local_dir()` の下の `delta\delta.lesshst`（`%LOCALAPPDATA%\delta\delta.lesshst`）、Linux では XDG の data の下の `delta/lesshst`
- 上流の文書（`manual/src/tips-and-tricks/using-delta-on-windows.md`）: Windows では新しい `less.exe` が要る（`jftuga/less-Windows` を案内）。色が崩れたり変な文字が出たりするときは、古い `less.exe` を拾っている

**Git for Windows のソース**（`git-for-windows/MINGW-packages` の `main` の `mingw-w64-git`、2026-10-08）:

- `mingw-w64-git.mak`: `cmd/git.exe` は、`git-wrapper.o` と `git.res`（版の情報）から作る
- `git-wrapper.c`: `main` の `full_path` の既定は 1 で、`MINIMAL_PATH=1 ` の文字列のリソースがあるときだけ 0 になる。`setup_environment` は、`full_path` が 1 なら PATH の先頭に `<Git>\mingw64\bin;<Git>\usr\bin;<HOME>\bin;` を足してから、本体の git を動かす（0 なら `<Git>\cmd;` だけ）
- そのため、PowerShell の PATH に Git の `cmd` しか無くても（Git for Windows の既定の `Path Option=Cmd`。[git.md の検証記録](#git-付録-windows-11-の配布物と資料の調査2026-10-03)）、git が起動する delta には `usr\bin` の less が見えるはず

**Scoop のソース**（`ScoopInstaller/Scoop` の `master`、2026-09-30 のコミット `e6aa3b3`）:

- `lib/install.ps1`: 入れ終わると `'<名前>' (<版>) was installed successfully!`。そのアプリのフォルダーのプロセスが動いていると `The following instances of "<名前>" are still running. Close them and try again.`
- `libexec/scoop-install.ps1`: 名前を 1 つだけ渡し、そのアプリが入っていれば、`'<名前>' (<版>) is already installed.` と `Use 'scoop update <名前>' to install a new version.` の警告を出して終わる（`$apps.length -eq 1` の分かれ）。`'<名前>' (<版>) is already installed. Skipping.` は名前を並べたときの分かれのもので、main のアプリには出ない（[windows-setup.md の付録](windows-setup.md#付録-シェルのツールの任意節のブロックの確認2026-10-08)）
- `libexec/scoop-update.ps1`: `scoop update` は `Scoop was updated successfully!`。名前を付けて新しい版が無いと `<名前>: <版> (latest version)`。動いているときは `Running process detected, skip updating.` で飛ばす
- `libexec/scoop-uninstall.ps1`・`lib/core.ps1`: 成功は `'<名前>' was uninstalled.`、入っていなければ `'<名前>' isn't installed.`
- `lib/manifest.ps1` の `Get-SupportedArchitecture`: arm64 の定義が無いアプリは、Windows 11（ビルド 22000 以降）では `64bit` の定義を使う

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. `scoop install delta` が `delta.exe` の shim を作り、`(Get-Command delta -All).Source` が scoop の shims の 1 行になること
1. VC++ ランタイムが無い PC で、delta がどう失敗するか（[Windows 11 で使う](../windows-setup.md#git-delta)の手順 2 で止める前提）
1. WezTerm の Git Bash で、[実施手順](../almalinux-setup.md#git-delta)の手順 1・3 が通り、6 項目が読み戻せること
1. Git Bash と PowerShell の `git diff` が、delta と Git for Windows の less で出ること（PowerShell の git が `usr\bin` を足すのはソースから）。色・行番号の見え方、`n` / `N`（`%LOCALAPPDATA%\delta\delta.lesshst`）
1. `git add -p`（`interactive.diffFilter`）と、Windows の lazygit の `git.diffRenderers`
1. 新しい版が出た後の[Windows 11 の更新](../windows-setup.md#scoopwingetwsl-を上げる)、less を開いたままの `Running process detected`、[Windows 11 のロールバック](../extra/windows-setup.md#git-の道具を消す)
1. arm64 の Windows（x64 の版をエミュレーションで動かす）と、SSH のセッション（scoop の shim と RedirectionGuard）

---

#### git-delta: 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-08）

Linux（クラウドのコンテナ）の PowerShell 7.5.3 と PSScriptAnalyzer 1.25.0、git 2.43.0 で確かめた。**Windows の実機では未検証**。

**構文と Windows PowerShell 5.1 との互換**:

- 手順書の Windows 11 の 3 節の `powershell` のブロック 6 個（Windows 11 で使うの手順 2・3、更新の手順 1、ロールバックの手順 1〜3）を取り出し、PowerShell 7.5.3 の構文解析器に通した（構文の誤り 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）と、既定の規則の Error・Warning を当てた（指摘 0）
  - 同じ設定で、`??` を書いたファイル・`Get-Content -AsByteStream` を書いたファイル・`}` の足りないファイルは、それぞれ指摘された
- 最後に（2026-10-08、手順書の今のブロックを取り出し直して）、6 個を構文解析器にもう一度通し（誤り 0）、互換の規則を `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows PowerShell 5.1 のプロファイル 3 つ。Windows Server 2016・Windows Server 2019・Windows 10 Pro）・`PSUseCompatibleCmdlets`（`desktop-5.1.14393.206-windows`）にして当てた。互換の指摘も既定の規則の指摘も 0 個（[windows-setup.md の付録](windows-setup.md#付録-シェルのツールの任意節のブロックの確認2026-10-08)と同じ回）

**模擬**:

- 偽物: `scoop`（渡った引数を記録し、`install` で偽物の `delta` を shims のフォルダーに置き、`update` と `uninstall` は Scoop のソースと同じ形の行を返すシェルスクリプト）と、`--version` に `delta 0.20.1` を返す `delta`
- `HOME` は使い捨てのフォルダー（`[user]` だけの `.gitconfig`）、`WINDIR` は `System32\vcruntime140.dll` だけを置いた使い捨てのフォルダーにした。管理者の判定（`WindowsPrincipal`）は Linux では使えないので `$false` に置き換え、出力は `Out-String -Width 200` で受けた
- Windows 11 で使うの手順 2: 入れる前は `Admin : False`・`VCRuntime : True`・`Delta` が空。入れた後は `Delta` が shims の `delta` の 1 つ。`vcruntime140.dll` を消すと `VCRuntime : False`。git を PATH から外すと `Git` が空になり、エラーは出なかった
- 手順 3: 1 回目は偽物の `'delta' (0.20.1) was installed successfully!` の後に `delta 0.20.1` と shims の `delta` の 1 行。2 回目は偽物の `is already installed. Skipping.` の後に同じ 2 行
  - 偽物の警告を、名前 1 つのときの形（`WARN  'delta' (0.20.1) is already installed.` と `Use 'scoop update delta' to install a new version.`）に直して流し直した（2026-10-08 の 2 回目）。2 回目はその 2 行の後に、同じ 2 行が出た
- 手順 4 の代わりに、[実施手順](../almalinux-setup.md#git-delta)の手順 1・3 の bash のブロックを手順書から取り出して bash で流した: 変数の 3 行と、`core.pager delta`・`interactive.difffilter delta --color-only`・`delta.navigate true`・`delta.line-numbers true`・`delta.side-by-side false`・`merge.conflictstyle zdiff3` の 6 行。`.gitconfig` の `[user]` は残った
- 更新の手順 1: 偽物の `Scoop was updated successfully!` と `delta: 0.20.1 (latest version)` の後、`delta 0.20.1`
- ロールバックの手順 1: 何も出さず、`.gitconfig` には `[user]` と `[merge] conflictstyle = zdiff3` だけが残った。もう一度貼ると、`fatal: no such section: delta` の 1 行だけ
- ロールバックの手順 2: 何も出さず、`[merge]` も消えて `[user]` だけが残った
- ロールバックの手順 3: 偽物の `'delta' was uninstalled.` の後、2 行目は何も出さなかった。もう一度貼ると偽物の `'delta' isn't installed.`
- 最後に（2026-10-08、手順書の今のブロックを取り出し直して）、偽物を作り直して全部を流し直した（偽物の `scoop` の警告は、名前 1 つのときの形）。手順 2（入れる前・`vcruntime140.dll` が無いとき・git が PATH に無いとき・入れた後）、手順 3 の 1 回目と 2 回目、[実施手順](../almalinux-setup.md#git-delta)の手順 1・3 の 6 行、更新の手順 1、ロールバックの手順 1〜3 と 2 回目は、上と同じ結果だった。`.gitconfig` には、同じ使い捨ての `HOME` で先に流した gh の模擬の `[credential "https://example.com"]` も残った（delta の手順は触らなかった）
- 本物の scoop の表示、Windows の `Get-Command` が返す shim のパス、Windows の git・less・delta での表示は、Windows で動かしていないので確かめていない

---

## 統合前の記録: GitHub CLI の Windows 11（もとは gh.md）

もとの `gh.md` の検証記録のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の検証記録](almalinux-setup.md#統合前の記録-github-cliもとは-ghmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。前の項で開いた窓を使う） |
| Windows 11 で使う 2〜6 | 「GitHub CLI」の手順 1〜5 |
| Windows 11 の更新 1 | 「scoop・winget・WSL を上げる」の手順 1・2 |
| Windows 11 のロールバック 1〜6 | ロールバックの「Git の道具を消す」の手順 5〜10 |

### GitHub CLI: 補足

#### GitHub CLI: Windows 11 で使う: 検証状況の記録

- **[Windows 11 で使う](../windows-setup.md#github-cli)・[Windows 11 の更新](../windows-setup.md#scoopwingetwsl-を上げる)・[Windows 11 のロールバック](../extra/windows-setup.md#git-の道具を消す)は、Windows の実機では未検証**（2026-10-08 に書いた。Windows を動かせないクラウドの Linux のコンテナで書き、どのブロックも Windows では貼っていない）
- 確かめた範囲は[対象と検証環境](almalinux-setup.md#github-cli-対象と検証環境)の「状態（Windows 11）」と[付録](#github-cli-付録-windows-11-の節の資料と-linux-での確認2026-10-08)

#### GitHub CLI: 付録: Windows 11 の節の資料と Linux での確認（2026-10-08）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物の定義とソースを読み、手順書の PowerShell のブロックを Linux の PowerShell で確かめた記録。**Windows の実機では未検証**。

**資料**（2026-10-08 に取得）:

- scoop の `ScoopInstaller/Main` の `bucket/gh.json`: `version` は `2.102.0`。64bit は `gh_2.102.0_windows_amd64.zip`（32bit と arm64 の zip もある）。`bin` は `bin\gh.exe` だけで、`persist`・`env_set`・`env_add_path`・`depends`・`suggest` は無い。`autoupdate` の hash は上流の `gh_<版>_checksums.txt` から取る
- 上流の版: `cli/cli` のタグの最新（プレリリースを除く）は `v2.102.0`（`git ls-remote` で見た）
- 64bit の zip: sha256 は `ae64e556ecc240b200f7eba60d550e4bb60d78e860e69dd88c449405b86067f4` で、定義の `hash` と、上流の `gh_2.102.0_checksums.txt` の行の両方と一致した。中身は `LICENSE` と `bin/gh.exe` の 2 つ
  - `gh.exe` は `PE32+ executable (console) x86-64`。PE のインポート表は `kernel32.dll` だけ（Visual C++ のランタイムを使わない。`objdump -p` で読んだ）
  - Authenticode の署名があり、署名者の証明書は `O = "GitHub, Inc.", CN = "GitHub, Inc."`、発行者は `Microsoft ID Verified CS AOC CA 03`（PE のセキュリティのディレクトリから取り出し、`openssl pkcs7 -print_certs` で証明書を並べただけ。Windows の `Get-AuthenticodeSignature` は通していない）
- winget の `GitHub.cli` 2.102.0 の定義: x86・x64・arm64 のそれぞれで、先に MSI（`InstallerType: wix`、`Scope: machine`、x64 は `DefaultInstallLocation: '%ProgramFiles%/GitHub CLI'`）、次に同じ zip の portable（x64 の `InstallerSha256` は scoop と同じ値）が並ぶ
- gh 2.102.0 のソース
  - `pkg/cmd/auth/login/login.go`・`pkg/cmd/auth/shared/login_flow.go`: 対話の問いは `Where do you use GitHub?` → `What is your preferred protocol for Git operations on this host?`（`HTTPS` / `SSH`）→（HTTPS のときだけ）Git の認証の問い → `How would you like to authenticate GitHub CLI?` の順。終わると `Logged in as <GITHUB_USER>` を出す。資格情報ストアに置けなければ `Authentication credentials saved in plain text` を出す
  - `internal/authflow/flow.go` と `internal/config/config.go`: 設定の `clipboard` の既定は `enabled` で、ワンタイムコードをクリップボードに入れて `One-time code (<コード>) copied to clipboard` を出す。入れられなければ `Failed to copy one-time code to clipboard` の後に `First copy your one-time code: <コード>` を出す（クリップボードを使わない設定でも、この行を出す）。続けて `Press Enter to open <URL> in your browser...` を出す。ブラウザを開けなければ `Failed opening a web browser at …`
  - `pkg/cmd/auth/shared/git_credential.go`: Git の認証の問いは `Authenticate Git with your GitHub credentials?`（既定は Yes）。github.com の Git の資格情報のヘルパーが gh なら聞かない。Yes のときは、トークンに `workflow` の権限も求める。`Setup` は、ヘルパーが無ければ gh を書き、あれば `Updater` で資格情報を入れ替える
  - `pkg/cmd/auth/shared/gitcredentials/helper_config.go`: ヘルパーは `git config credential.https://github.com.helper`、空なら `git config credential.helper` で読む（どちらもスコープを指定しないので、Git for Windows の `system` の `manager` も入る）。gh かどうかは、`!` の後の最初の語の名前が `gh`（`.exe` を除く）かで見る。gh を書くときは、`--global --replace-all` で空の値を置いてから、`--global --add` で `!<gh の場所> auth git-credential` を足す（gist のホストも同じ）
  - `pkg/cmd/auth/shared/gitcredentials/updater.go`: `git credential reject`（`protocol=https`・`host=<ホスト>`）の後に `git credential approve`（アカウント名と gh のトークン）を流す
  - `internal/config/config.go`: トークンは、資格情報ストアのサービス名 `gh:<ホスト>`（`keyringServiceName`）に置く。`Logout` は、アカウントが 1 つならホストごと消し、ストアの空の名前とアカウント名の 2 つも消す
  - `pkg/cmd/auth/logout/logout.go`: 候補のアカウントが 1 つなら問わない。複数なら `What account do you want to log out of?` で選ばせる。ログインが無ければ `not logged in to any hosts`。終わると `Logged out of <ホスト> account <名前>`
  - `pkg/cmd/auth/status/status.go`: `Logged in to <ホスト> account <名前> (<置き場所>)` と `Git operations protocol: <値>`。置き場所は、ストアなら `keyring`、平文なら設定の場所の `hosts.yml`（`oauth_token` を置き換える）。ログインが無ければ `You are not logged into any GitHub hosts.`
  - `internal/ghcmd/cmd.go`: 新しい版があると、`A new release of gh is available:` と今の版と新しい版を出す。Git の資格情報のヘルパーに書く自分の場所は、`GH_PATH` が無ければ、`executable` で決める
- go-gh 2.16.1（gh 2.102.0 の `go.mod`）の `pkg/config/config.go`: 設定の場所は `GH_CONFIG_DIR` → `XDG_CONFIG_HOME` → Windows では AppData の `GitHub CLI`。状態・データ・キャッシュは、`XDG_STATE_HOME` などが無ければ LocalAppData の `GitHub CLI`
- go-keyring 0.2.8（同じ `go.mod`）の `keyring_windows.go`: 資格情報マネージャーの汎用資格情報に、`<サービス名>:<アカウント名>` の名前で置く（`credName`。gh では `gh:github.com:<GITHUB_USER>` と `gh:github.com:` になるはず）
- Git for Windows の起動スクリプト（`git-for-windows/MSYS2-packages` の `filesystem/profile`・`filesystem/bash.bashrc` と、`git-for-windows/build-extra` の `git-extra/env.sh`・`aliases.sh`・`git-prompt.sh`・`bash_profile.sh`）は、`XDG_CONFIG_HOME` を含まない（`grep` で見た）。自分用の bash 設定の `bashrc`（`ryo-aoki-pc/bash` の `54af594`）と WezTerm の設定（`lua/shells.lua` の `set_environment_variables` は `WEZTERM_SHELL_INTEGRATION` だけ）も設定しない
- Git for Windows の `system` の `credential.helper=manager` は、[Windows 11 の Git Bash での検証](almalinux-setup.md#git-実施手順--手順-3-補足-設定の-3-つの場所)で見た値
- scoop 本体（`ScoopInstaller/Scoop` の `master`、2026-09-30 のコミット `e6aa3b3`）のメッセージ: 導入は `'<名前>' (<版>) was installed successfully!`、入っているときは、名前を 1 つだけ渡せば `'<名前>' (<版>) is already installed.` と `Use 'scoop update <名前>' to install a new version.`（`libexec/scoop-install.ps1` の `$apps.length -eq 1` の分かれ。`… Skipping.` は名前を並べたときの分かれのもので、main のアプリには出ない。[windows-setup.md の付録](windows-setup.md#付録-シェルのツールの任意節のブロックの確認2026-10-08)）。更新は `Scoop was updated successfully!`、新しい版が無ければ `<名前>: <版> (latest version)`、動いているときは `Running process detected, skip updating.`。削除は `'<名前>' was uninstalled.`、入っていなければ `'<名前>' isn't installed.`、動いているときは `The following instances of "<名前>" are still running. Close them and try again.`

**構文と Windows PowerShell 5.1 との互換**（Linux の PowerShell 7.5.3 と PSScriptAnalyzer 1.25.0）:

- 手順書の `powershell` のブロック 10 個（Windows 11 で使うの手順 2〜4・6、Windows 11 の更新の手順 1、Windows 11 のロールバックの手順 1・3〜6）を取り出し、PowerShell 7.5.3 の構文解析器に通した（構文の誤り 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）と、既定の規則の Error・Warning を当てた（指摘 0）。同じ設定で、`??` を書いたファイル・`Get-Content -AsByteStream` を書いたファイル・`}` の足りないファイルは、それぞれ指摘された
- 最後に（2026-10-08、手順書の今のブロックを取り出し直して）、10 個を構文解析器にもう一度通し（誤り 0）、互換の規則を `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows PowerShell 5.1 のプロファイル 3 つ。Windows Server 2016・Windows Server 2019・Windows 10 Pro）・`PSUseCompatibleCmdlets`（`desktop-5.1.14393.206-windows`）にして当てた。互換の指摘も既定の規則の指摘も 0 個（[windows-setup.md の付録](windows-setup.md#付録-シェルのツールの任意節のブロックの確認2026-10-08)と同じ回）

**模擬**（Linux の PowerShell 7.5.3 と git 2.43.0）:

- 管理者の判定（`WindowsPrincipal`。Linux では使えない）を `$false` に置き換え、出力は `Out-String -Width 200` で受けた。渡った引数を記録して Scoop のソースと同じ形の行を返す偽物の `scoop`（`install` で偽物の `gh` を shims に置き、`uninstall` で消す）と、`--version`・`auth status`・`auth login`・`auth logout` に答える偽物の `gh` を `PATH` の先頭に置いた。git は本物で、`HOME` を使い捨てのフォルダーにし、`GIT_CONFIG_SYSTEM` で `credential.helper = manager` の `system` の設定を読ませ、`manager` には受け取った操作と入力を記録するだけの偽物の `git-credential-manager` を置いた
- Windows 11 で使うの手順 2: 入れる前は `GitCred : credential.helper manager`・`Gh` は空、入れた後は `Gh` が偽物の shim の場所。`gh auth setup-git` と同じ形の行（`--replace-all` の空の値と、`--add` の `!'C:\Users\u\scoop\apps\gh\current\bin\gh.exe' auth git-credential`。gist のホストも）を `--global` に置くと、`GitCred` にその行が並んだ。git を `PATH` から外すと、`Git` と `GitCred` が空になり、エラーは出なかった
- Windows 11 で使うの手順 3: 1 回目は偽物の導入の行・版の 2 行・shim の場所。2 回目は偽物の `is already installed. Skipping.` の後に同じ行
  - 偽物の警告を、名前 1 つのときの形（`WARN  'gh' (2.102.0) is already installed.` と `Use 'scoop update gh' to install a new version.`）に直して流し直した（2026-10-08 の 2 回目）。2 回目はその 2 行の後に、版の 2 行と shim の場所が出た
- Windows 11 で使うの手順 6: ログインの前は偽物の gh の `You are not logged into any GitHub hosts.` と `credential.helper manager`、偽物の `gh auth login` の後は `(keyring)` の行と `Git operations protocol: https` と `credential.helper manager`
- Windows 11 の更新の手順 1: 偽物の `Scoop was updated successfully!` と `gh: 2.102.0 (latest version)` の後に版の 2 行。偽物の scoop に `update` と `update gh` が渡った
- Windows 11 のロールバックの手順 1: 偽物の gh に `auth logout` が渡った（2 回目は `not logged in to any hosts`）
- Windows 11 のロールバックの手順 3: github.com と gist.github.com の gh の行（空の値を含む）だけが `--global` から消え、`credential.https://example.com.helper store` は残った。最後のコマンドは `credential.helper manager` と、その `example.com` の行を出した。2 回目は何も変えなかった。`credential.https://github.com.helper` が gh でない値（`store`）のときも残した
- Windows 11 のロールバックの手順 4: 偽物の `git-credential-manager` に `erase` と、`protocol=https`・`host=github.com` の 2 行が渡った。bash から CR LF の 2 行を `git credential reject` に渡したときも、ヘルパーには CR の無い 2 行が渡った（Windows PowerShell 5.1 のパイプは CR LF で送る。5.1 では確かめていない）
- Windows 11 のロールバックの手順 5: 偽物の `'gh' was uninstalled.` の後、`Get-Command` の行は何も出さなかった（2 回目は偽物の `'gh' isn't installed.`）
- Windows 11 のロールバックの手順 6: `$env:APPDATA` と `$env:LOCALAPPDATA` を使い捨てのフォルダーにし、`GitHub CLI` のフォルダー（`hosts.yml` と `extensions`）を作ってから貼ると、`False` が 2 行出た。2 回目もエラー無しで `False` が 2 行
- 最後に（2026-10-08、手順書の今のブロックを取り出し直して）、偽物を作り直して全部を流し直した（偽物の `scoop` の警告は、名前 1 つのときの形）。上の各項目と同じ結果だった（手順 2 の git が無いときにエラーが出ないこと、ロールバックの手順 3 で gh の行だけが消え、`store` の行が残ること、手順 4 でヘルパーに `erase` と 2 行が渡ること、手順 5・6 の 2 回目を含む）
- 本物の scoop と gh の表示、Windows の `Get-Command` が返す shim のパス、資格情報マネージャー、Git Credential Manager は、Windows で動かしていないので確かめていない

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（scoop での導入・更新・削除）
1. `gh auth login` の問いを Windows PowerShell 5.1 の conhost の窓で答えること、ワンタイムコードがクリップボードに入ること、既定のブラウザが開くこと、資格情報マネージャーに置かれること
1. Git の認証に `Y` と答えたときに、Git Credential Manager に gh のトークンが入ることと、ロールバックの手順 4 で消えること
1. Git Bash・PowerShell 7・cmd の gh が、同じ設定（`%APPDATA%\GitHub CLI`）とログインを使うこと
1. SSH のセッション（scoop の shim と、資格情報マネージャーを読めるか）、arm64 の Windows、winget の gh があるとき

---

## 統合前の記録: Neovim の Windows 11（もとは neovim.md）

もとの `neovim.md` の検証記録のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の検証記録](almalinux-setup.md#統合前の記録-neovimもとは-neovimmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

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

#### Neovim: Windows 11 で使う: 検証状況の記録

- **[Windows 11 で使う](../windows-setup.md#neovim)・[Windows 11 の更新](../windows-setup.md#scoopwingetwsl-を上げる)・[Windows 11 のロールバック](../extra/windows-setup.md#エディタとシェルのツールを消す)と、[既定のエディタにする（任意）](../windows-setup.md#neovim-を既定のエディタにする任意)の手順 2・3 は、Windows 実機では未検証**（2026-10-08 に書いた。Windows を動かせないクラウドの Linux のコンテナで書き、どのブロックも Windows では貼っていない）
- 確かめた範囲は[対象と検証環境](almalinux-setup.md#neovim-対象と検証環境)の「状態（Windows 11）」と[付録](#neovim-付録-windows-11-の節の資料と-linux-での確認2026-10-08)

#### Neovim: 付録: Windows 11 の節の資料と Linux での確認（2026-10-08）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物の定義とソースを読み、手順書の PowerShell のブロックを Linux の PowerShell で確かめた記録。**Windows 実機では未検証**。

**資料**（2026-10-08 に取得）:

- scoop の `ScoopInstaller/Main` の `bucket/neovim.json`: `version` は `0.12.5`。64bit は `nvim-win64.zip`（`extract_dir` は `nvim-win64`）、arm64 は `nvim-win-arm64.zip`。`bin` は `bin\nvim.exe` と `bin\xxd.exe`。`suggest` は `{"vcredist": "extras/vcredist2022"}`（ランタイムは入れず、勧めるだけ）
- scoop 本体（`ScoopInstaller/Scoop` の `master`）の `lib/install.ps1`・`libexec/scoop-install.ps1`・`scoop-update.ps1`・`scoop-uninstall.ps1`: 手順書の箇条書きに書いた `'<名前>' (<版>) was installed successfully!`・`'<名前>' suggests installing '<候補>'.`・`'<名前>' (<版>) is already installed.`・`Scoop was updated successfully!`・`<名前>: <版> (latest version)`・`Latest versions for all apps are installed!`・`Running process detected, skip updating.`・`'<名前>' was uninstalled.`・`'<名前>' isn't installed.` の文字列。`scoop uninstall` は、そのアプリのフォルダーから動いているプロセスがあると、消さずに止まる
  - 更新で新しい版が無いときの表示は、最初は `The latest version of '<名前>' (<版>) is already installed.` と書いていた。この文字列は `scoop-update.ps1` の `update` の中にあるが、名前を指定した `scoop update <名前>` は、最新のアプリを `update` に渡さず、`<名前>: <版> (latest version)` と `Latest versions for all apps are installed! For more information try 'scoop status'` を出す（同じファイルの 440〜473 行目。見直しで読み直して、手順書を直した）
  - `Running process detected, skip updating.` も `update` の中にあり、新しい版があるときだけ出る

**配布物のインポート表**（`objdump -p` の `DLL Name`。Windows の実行ファイルは動かしていない）:

- GitHub のリリースの `nvim-win64.zip` の sha256 は `de8625ba…0de1` で、`neovim.json` の `hash` と一致した
- `bin\nvim.exe`・`bin\lua51.dll`・`bin\xxd.exe`・`bin\win32yank.exe` は、どれも `VCRUNTIME140.dll`（と `api-ms-win-crt-*`）を読み込む。`MSVCP140.dll` は読み込まない
- zip の `bin` には `DbgHelp.dll`・`lua51.dll`・`nvim.exe`・`tee.exe`・`win32yank.exe`・`xxd.exe` がある。scoop の `bin`（shim）は `nvim.exe` と `xxd.exe` だけ

**Linux の Neovim 0.12.5 で確かめたこと**（GitHub のリリースの `nvim-linux-x86_64.tar.gz`〔sha256 `bce0f56e…6875`〕を一時的な場所に展開し、`HOME` も一時的な場所にした）:

```
$ nvim --version | head -3
NVIM v0.12.5
Build type: Release
LuaJIT 2.1.1774638290
$ nvim --clean --headless "+lua io.stdout:write(vim.fn.stdpath('config'), '\n', vim.fn.stdpath('data'), '\n')" +qa
<一時的な HOME>/.config/nvim
<一時的な HOME>/.local/share/nvim
```

- `--version` の 3 行目が LuaJIT なので、Windows 11 で使うの手順 4 は `Select-Object -First 3` にした（`-First 2` では `Build type` までしか出ない）
- `stdpath` の行は、`--clean` でも置き場所を 2 行で書き出し、終了コード 0 で終わった。Windows では `%LOCALAPPDATA%\nvim` と `%LOCALAPPDATA%\nvim-data` になるはず（同じ配布物の `runtime/doc/starting.txt` の base-directories。キャッシュは `~/AppData/Local/Temp/nvim-data`、ログは `nvim-data` の `nvim.log`）だが、Windows では流していない

**構文と Windows PowerShell 5.1 との互換**（Linux の PowerShell 7.5.3 と PSScriptAnalyzer 1.25.0）:

- 手順書の `powershell` のブロック 8 個を取り出し、PowerShell 7.5.3 の構文解析器に通した（構文の誤り 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0（ほかの規則の指摘は、ASCII でない文字を含むブロックの BOM だけ）

**模擬**（Linux の PowerShell 7.5.3）:

- ブロックの文字列のうち、管理者の判定（`WindowsPrincipal`。Linux では使えない）を `$false` に、`[Environment]` のユーザーの環境変数（Linux の .NET では読み書きされない）を、値をハッシュテーブルに記録する偽物のクラスに置き換えた。`$env:WINDIR`・`$env:APPDATA`・`$env:TEMP` と `C:\Program Files\Git\usr\bin\file.exe` は一時的な場所にした。scoop は、渡った引数を記録してメッセージだけを出す偽物の `scoop.ps1`
- Windows 11 で使うの手順 2: `VCRuntime` は、偽物の `System32\vcruntime140.dll` の有無で `False` / `True` になった。PATH の先に別の `nvim` を置くと、`Nvim` に 2 つの場所が `, ` でつながって出た
- Windows 11 で使うの手順 4: Linux の Neovim で、上の 3 行・`(Get-Command nvim -All).Source` の 1 行・`stdpath` の 2 行が出た
- 既定のエディタにするの手順 2: 値が無いときは `EDITOR = nvim`・`VISUAL = nvim` を書いた。2 回目も同じ表示で、値は変わらなかった。`EDITOR` が `code` のときは `中断: ユーザーの環境変数 EDITOR か VISUAL に、nvim ではない値がある（code）` で止まり、値は変わらなかった
- 既定のエディタにするの手順 3: どちらも `nvim` のときは両方消えた。`EDITOR` が `code`・`VISUAL` が `nvim` のときは、`VISUAL` だけ消え、`EDITOR = code` が残った
- 更新とロールバックの手順 1: 偽物の scoop に `update`・`update neovim`・`uninstall neovim` が渡った。ロールバックの手順 1 の `Get-Command` の行は、PATH に `nvim` が無いときは何も出さなかった

**最後の確認**（見直しの後。レビューの指摘で手順書・検証記録・参考資料を直した後に、同じ Linux のコンテナで確かめ直した。**Windows 実機では未検証**）:

- 手順書の `powershell` のブロックを取り出し直した。neovim.md は 8 個で、中身は直す前と同じだった（直したのは箇条書きと 1 行の説明だけで、ブロックの位置だけが変わった）
- PowerShell 7.5.3 の構文解析器で、構文の誤りは 0。PSScriptAnalyzer 1.25.0 の 5.1 互換の 3 規則の指摘は 0。ほかの規則の指摘は、既定のエディタにするの手順 2 の BOM の 1 件だけ（ASCII でない文字を含む）
- 偽物の scoop を作り直した。メッセージは scoop 本体のソース（`master`。この日に取り直し、前の取得と同じだった）から写し、入っているアプリ・最新の版・動いているアプリを記録したファイルで出し分ける。実際の scoop の出力ではない
  - 前の模擬の偽物の scoop は、更新で新しい版が無いときに `The latest version of '<名前>' (1.0) is already installed.` を出していた。手順書の箇条書きに合わせて手で書いたもので、scoop の振る舞いから取ったものではない。そのため、前の模擬では手順書の誤りが見つからなかった
- 模擬の結果（16 通り。表示は偽物のもの）:
  - Windows 11 で使うの手順 2: `VCRuntime` は、偽物の `vcruntime140.dll` の有無で `False` / `True` になった。PATH の先に別の `nvim` を置くと、`Nvim` に 2 つの場所が `, ` でつながった
  - 手順 3: 入っていないときは `'neovim' (0.12.5) was installed successfully!`、入っているときは `WARN  'neovim' (0.12.5) is already installed.` と `Use 'scoop update neovim' to install a new version.`
  - 手順 4: Linux の Neovim で、3 行・場所の 1 行・`stdpath` の 2 行が出た（前の記録と同じ）
  - 更新の手順 1: 新しい版が無いときは `neovim: 0.12.5 (latest version)` と `Latest versions for all apps are installed! For more information try 'scoop status'`。新しい版（0.12.6 にした）があるときは `'neovim' (0.12.6) was installed successfully!`。neovim が動いている扱いにすると `Running process detected, skip updating.` で、版は変わらなかった
  - ロールバックの手順 1: `'neovim' was uninstalled.` の後の `Get-Command` の行は、何も出さなかった。もう一度貼ると `ERROR 'neovim' isn't installed.`
  - 既定のエディタにするの手順 2: 値が無いときと 2 回目は `EDITOR = nvim`・`VISUAL = nvim`。`EDITOR` が `code` のときと、`VISUAL` が `nvim.exe` のときは `中断:` で止まり、値は変わらなかった
  - 既定のエディタにするの手順 3: どちらも `nvim` なら両方消え、`EDITOR` が `code` なら `EDITOR = code` が残った
- 取り出したブロック・偽物・模擬のスクリプトと出力は、リポジトリの外の作業用の場所に置いた（リポジトリには入れていない）

**2 回目の見直しの後の確認**（2026-10-08。2 回目のレビューの指摘で手順書・検証記録・参考資料を直した後に、同じ Linux のコンテナで確かめ直した。**Windows 実機では未検証**）:

- 手順書の変更は、Windows 11 のロールバックのリードの箇条書きだけ（LazyVimStarter のロールバックの手順 6 が取り戻せないことを足した。手順 7 が lazygit と zenhan も消すことは、前の見直しで書いてあった）。ブロックは変えていない
  - LazyVimStarter の `custom`（`6c894ee`）の docs/setup.md の「ロールバック」を読み直した
  - その手順 6 は、`%LOCALAPPDATA%\nvim` と `nvim-data` を `Remove-Item -Recurse -Force` で消して `.bak` を戻す（その節の `[!CAUTION]` と、1 行の説明の「取り戻せない」）
  - その手順 7 は `scoop uninstall neovim zenhan lazygit`
- 手順書の `powershell` のブロックを取り出し直した。neovim.md は 8 個で、中身は前の確認と同じだった
- PowerShell 7.5.3 の構文解析器で、構文の誤りは 0。PSScriptAnalyzer 1.25.0 の 5.1 互換の 3 規則の指摘は 0。ほかの規則の指摘は、既定のエディタにするの手順 2 の BOM の 1 件だけ
- 偽物の scoop での模擬を、前の確認と同じ 16 通りで流し直した。結果は前の確認と同じだった（表示は偽物のもの）

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（scoop での導入・更新・削除）
1. `VCRUNTIME140.dll` が無い PC で、`nvim --version` が何も出さずに終わるか、システム エラーの窓が出るか（何も出さずに終わった記録は、LazyVimStarter の検証記録の 2026-10-06 のクリーンな VM で、自動で流したものだけ）と、x64 のランタイムだけで起動すること
1. Windows の `stdpath` の値と、Windows PowerShell 5.1 から `"+lua …"` の引数がそのまま渡ること
1. `:checkhealth` の表示と、`:qa` で閉じた後の窓
1. ユーザーの環境変数 `EDITOR`・`VISUAL` が、新しい Windows PowerShell・WezTerm のタブ・lazygit の `e` キー・PowerShell の `git commit` に効くこと
1. winget の Neovim（`C:\Program Files\Neovim`）があるときに、手順 2 で見つかること
1. SSH のセッションと、arm64 の Windows

---

## 統合前の記録: lazygit の Windows 11（もとは lazygit.md）

もとの `lazygit.md` の検証記録のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の検証記録](almalinux-setup.md#統合前の記録-lazygitもとは-lazygitmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。前の項で開いた窓を使う） |
| Windows 11 で使う 2〜4 | 「lazygit」の手順 1〜3 |
| Windows 11 で使う 5・6 | 「lazygit」の手順 5・6 |
| Windows 11 の更新 1 | 「scoop・winget・WSL を上げる」の手順 1・2 |
| Windows 11 のロールバック 1 | ロールバックの「Git の道具を消す」の手順 2 |

### lazygit: 補足

#### lazygit: Windows 11 で使う: 検証状況の記録

- **[Windows 11 で使う](../windows-setup.md#lazygit)・[Windows 11 の更新](../windows-setup.md#scoopwingetwsl-を上げる)・[Windows 11 のロールバック](../extra/windows-setup.md#git-の道具を消す)は、Windows 実機では未検証**（2026-10-08 に書いた。Windows を動かせないクラウドの Linux のコンテナで書き、どのブロックも Windows では貼っていない）
- 確かめた範囲は[対象と検証環境](almalinux-setup.md#lazygit-対象と検証環境)の「状態（Windows 11）」と[付録](#lazygit-付録-windows-11-の節の資料と-linux-での確認2026-10-08)

#### lazygit: 付録: Windows 11 の節の資料と Linux での確認（2026-10-08）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物の定義とソースを読み、手順書の PowerShell のブロックを Linux の PowerShell で確かめた記録。**Windows 実機では未検証**。

**資料**（2026-10-08 に取得）:

- scoop の `ScoopInstaller/Extras` の `bucket/lazygit.json`: `version` は `0.66.0`。64bit は `lazygit_0.66.0_Windows_x86_64.zip`（32bit・arm64 もある）。`bin` は `lazygit.exe`。`suggest`・`depends` は無い
- scoop 本体（`ScoopInstaller/Scoop` の `master`）の `lib/buckets.ps1` の `list_buckets`: バケットごとに `Name`・`Source`・`Updated`・`Manifests` を持つオブジェクトを返す（Windows 11 で使うの手順 2 の `Where-Object Name -eq 'extras'` が使う形）。`add_bucket` は git が無いと `Git is required for buckets.` で止まり、足せたら `The <名前> bucket was added successfully.` を出す
- 同じく、手順書の箇条書きに書いたインストール・更新・削除のメッセージの文字列（neovim.md の検証記録の付録と同じ）
- GitHub のリリースの `lazygit_0.66.0_Windows_x86_64.zip` の sha256 は `ed8fab4a…3e4b` で、`lazygit.json` の `hash` と一致した。中の `lazygit.exe` のインポート表（`objdump -p` の `DLL Name`）は `kernel32.dll` だけだった（Go の実行ファイル。Windows の実行ファイルは動かしていない）
- lazygit 0.66.0 の `docs/Config.md`: Windows の既定の場所は `%LOCALAPPDATA%\lazygit\config.yml` で、`%APPDATA%\lazygit\config.yml` も見つける（古い場所の `%APPDATA%\jesseduffield\lazygit\config.yml` もある）
- lazygit 0.66.0 の `pkg/commands/git_commands/file.go` の `guessDefaultEditor`: git の `core.editor` → `GIT_EDITOR` → `VISUAL` → `EDITOR` の順に探し、最初の空白までの語の `filepath.Base` をエディタの名前にする。`pkg/config/editor_presets.go` の `getPreset` は、その名前のプリセット（`nvim` など）が無ければ `vim` を使い、`getEditInTerminal` は `os.editInTerminal` が書いてあればプリセットより優先する

**構文と Windows PowerShell 5.1 との互換**（Linux の PowerShell 7.5.3 と PSScriptAnalyzer 1.25.0）:

- 手順書の `powershell` のブロック 7 個を取り出し、PowerShell 7.5.3 の構文解析器に通した（構文の誤り 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0（ほかの規則の指摘は、ASCII でない文字を含むブロックの BOM だけ）

**模擬**（Linux の PowerShell 7.5.3）:

- ブロックの文字列のうち、管理者の判定（`WindowsPrincipal`。Linux では使えない）を `$false` に、`[Environment]` のユーザーの環境変数（Linux の .NET では読み書きされない）を、値をハッシュテーブルに記録する偽物のクラスに置き換えた。`$env:WINDIR`・`$env:APPDATA`・`$env:TEMP` と `C:\Program Files\Git\usr\bin\file.exe` は一時的な場所にした。scoop は、渡った引数を記録してメッセージだけを出す偽物の `scoop.ps1`
- Windows 11 で使うの手順 2: 偽物の `scoop bucket list` が `main` だけを返すと `Extras : False`、`extras` を足した後は `True` になった。scoop が PATH に無いときは `Scoop` が空・`Extras : False` で、エラーにならずに表が出た
- Windows 11 で使うの手順 3: 偽物の scoop に `bucket add extras` が渡り、続く `bucket list` に `extras` が出た
- Windows 11 で使うの手順 6: パスの `\` を `/` に替えて流すと、`%TEMP%` に当たる一時的なフォルダーに `lazygit-check/.git` ができ、偽物の lazygit がそこで起動し、窓の今のフォルダーもそこになった。2 回目（同じリポジトリ）も同じだった。`%TEMP%` に当たる場所を通常のファイルにして `git init` を失敗させると、`中断: 確かめ用のリポジトリ（%TEMP%\lazygit-check）を作れない` で止まり、lazygit は起動せず、今のフォルダーも変わらなかった
- 更新とロールバック: 偽物の scoop に `update`・`update lazygit`・`uninstall lazygit` が渡った。ロールバックの手順 1 の `Get-Command` の行は、PATH に `lazygit` が無いときは何も出さなかった

**最後の確認**（見直しの後。レビューの指摘で手順書・検証記録・参考資料を直した後に、同じ Linux のコンテナで確かめ直した。**Windows 実機では未検証**）:

- 手順書の `powershell` のブロックを取り出し直した。lazygit.md は 7 個で、中身は直す前と同じだった（直したのは箇条書きだけで、ブロックの位置だけが変わった）
- PowerShell 7.5.3 の構文解析器で、構文の誤りは 0。PSScriptAnalyzer 1.25.0 の 5.1 互換の 3 規則の指摘は 0。ほかの規則の指摘は、Windows 11 で使うの手順 6 の BOM の 1 件だけ（ASCII でない文字を含む）
- 偽物の scoop は、neovim.md の検証記録の付録の「最後の確認」と同じもの（メッセージは scoop 本体のソースから写した。実際の scoop の出力ではない）。前の模擬の偽物が、更新で新しい版が無いときに出していた `The latest version of …` は、手で書いたもので、scoop の振る舞いから取ったものではない
- 模擬の結果（13 通り。表示は偽物のもの）:
  - Windows 11 で使うの手順 2・3: バケットが `main` だけなら `Extras : False`、手順 3 で `The extras bucket was added successfully.` と `main`・`extras` の 2 行の一覧が出た後は `True`。scoop が PATH に無いときは `Scoop` が空・`Extras : False` で、エラーにならずに表が出た
  - 手順 4: 入っていないときは `'lazygit' (0.66.0) was installed successfully!`、入っているときは `WARN  'lazygit' (0.66.0) is already installed.` と `Use 'scoop update lazygit' to install a new version.`
  - 手順 6: 前の記録と同じ（新しいリポジトリ・同じリポジトリでもう一度・`git init` の失敗の 3 通り。失敗では `中断:` で止まり、lazygit は起動せず、今のフォルダーも変わらなかった）
  - 更新の手順 1: 新しい版が無いときは `lazygit: 0.66.0 (latest version)` と `Latest versions for all apps are installed! For more information try 'scoop status'`。新しい版（0.66.1 にした）があるときは `'lazygit' (0.66.1) was installed successfully!`
  - ロールバックの手順 1: `'lazygit' was uninstalled.` の後の `Get-Command` の行は、何も出さなかった

**2 回目の見直しの後の確認**（2026-10-08。2 回目のレビューの指摘で手順書・検証記録・参考資料を直した後に、同じ Linux のコンテナで確かめ直した。**Windows 実機では未検証**）:

- 手順書の変更は、箇条書きだけ（Windows 11 で使うの手順 6 に、`%TEMP%\lazygit-check` を消す前に `Set-Location ~` でこの窓をそこから出すことを足した）。ブロックは変えていない
- 手順書の `powershell` のブロックを取り出し直した。lazygit.md は 7 個で、中身は前の確認と同じだった
- PowerShell 7.5.3 の構文解析器で、構文の誤りは 0。PSScriptAnalyzer 1.25.0 の 5.1 互換の 3 規則の指摘は 0。ほかの規則の指摘は、Windows 11 で使うの手順 6 の BOM の 1 件だけ
- 偽物の scoop・lazygit での模擬を、前の確認と同じ 13 通りで流し直した。結果は前の確認と同じだった（表示は偽物のもの）
- 手順 6 の後の今のフォルダー: ブロックを流した後、模擬の窓の今のフォルダーは `%TEMP%` に当たる場所の `lazygit-check` のままだった。続けて `Set-Location ~` を流すとそこから出て、`Remove-Item -Recurse -Force` で `lazygit-check` を消せた
  - Linux はプロセスの今のフォルダーでも消せるので、Windows で今のフォルダーのままでは消せないことは確かめていない

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（extras のバケットの追加、scoop での導入・更新・削除）
1. 実際の scoop の `scoop bucket list` で、手順 2 の `Extras` が正しく出ること
1. `lazygit --version`・`--print-config-dir` の表示と、`%TEMP%\lazygit-check` での TUI の起動
1. Windows PowerShell から起動した lazygit の `e` キーが、git の `core.editor` と `VISUAL`・`EDITOR` が無いと失敗し、ユーザーの環境変数を `nvim` にすると Neovim で開くこと
1. `%TEMP%\lazygit-check` を、手順 6 の窓の今のフォルダーのままでは消せず、`Set-Location ~` の後なら消せること
1. 自分用の設定（`%LOCALAPPDATA%\lazygit` への clone）と delta との組み合わせ
1. SSH のセッションと、arm64 の Windows

---

## 統合前の記録: yazi の Windows 11（もとは yazi.md）

もとの `yazi.md` の検証記録のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の検証記録](almalinux-setup.md#統合前の記録-yaziもとは-yazimd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。前の項で開いた窓を使う） |
| Windows 11 で使う 2〜5 | 「yazi」の手順 1〜4 |
| Windows 11 で使う 6〜9 | 「yazi」の手順 6〜9 |
| Windows 11 の更新 1 | 「scoop・winget・WSL を上げる」の手順 1・2 |
| Windows 11 のロールバック 1・2 | ロールバックの「エディタとシェルのツールを消す」の手順 2・3 |

### yazi: 補足

#### yazi: Windows 11 で使う: 検証状況の記録

- **[Windows 11 で使う](../windows-setup.md#yazi)・[Windows 11 の更新](../windows-setup.md#scoopwingetwsl-を上げる)・[Windows 11 のロールバック](../extra/windows-setup.md#エディタとシェルのツールを消す)は、Windows 実機では未検証**（2026-10-08 に書いた。Windows を動かせないクラウドの Linux のコンテナで書き、どのブロックも Windows では貼っていない）
- 確かめた範囲は[対象と検証環境](almalinux-setup.md#yazi-対象と検証環境)の「状態（Windows 11）」と[付録](#yazi-付録-windows-11-の節の資料と-linux-での確認2026-10-08)

#### yazi: 付録: Windows 11 の節の資料と Linux での確認（2026-10-08）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物の定義とソースを読み、手順書の PowerShell のブロックを Linux の PowerShell で確かめた記録。**Windows 実機では未検証**。

**資料**（2026-10-08 に取得）:

- scoop の `ScoopInstaller/Main` の `bucket/yazi.json`: `version` は `26.9.1`。64bit は `yazi-x86_64-pc-windows-msvc.zip`、arm64 は `yazi-aarch64-pc-windows-msvc.zip`。`bin` は `ya.exe` と `yazi.exe`。`suggest`・`depends` は無い（VC++ のランタイムも `file` も入れない）
- yazi 26.9.1 の `yazi-cli/src/env/env.rs`（`ya env`）: `Config` の各行は設定のフォルダーのファイル（`yazi.toml` など）と文字数か読めない理由、`Variables` の `YAZI_FILE_ONE` は Rust の `Debug` の形（`Some("…")`。`\` は `\\` で出る）、`Dependencies` の `file` は `YAZI_FILE_ONE`（無ければ `file`）を `--version` で動かした版、最後の `Routine` は一時的なファイルに `Hello, World!` を書いて `file -bL --mime-type` を動かした結果の 1 行目
- yazi 26.9.1 の `yazi-version/src/lib.rs`: `--version` は `Version: <版> (<コミット> <日付>)` と `Triple : <ビルドしたホストの組> (<OS>-<アーキテクチャ>)` の行を出す
- yazi 26.9.1 の `yazi-boot/src/args.rs` と `yazi-cli/src/args.rs`: `yazi` の引数に `--debug` は無く（`--cwd-file`・`--version` など）、環境と設定を出すのは `ya env`（`Print environment and configuration information.`）
- yazi 26.9.1 の `yazi-fs/src/xdg.rs`: Windows の設定は `YAZI_CONFIG_HOME`（絶対パスのとき）か `%APPDATA%\yazi\config`、状態は `%APPDATA%\yazi\state`、キャッシュは `%LOCALAPPDATA%\yazi`。`XDG_CONFIG_HOME` を読むのは Linux などだけ
- yazi 26.9.1 の `yazi-cli/src/env/env.rs` の `config_state`（2 回目の見直しで読んだ）: 設定のフォルダーのファイルを `read_to_string` で読み、読めなければ `<パス> (<エラー>)` を出す
  - フォルダーを作るのは `ya pkg`（`yazi-cli/src/package/mod.rs`）と、yazi の状態のフォルダー（`yazi-dds/src/state.rs`）だけ。`yazi --version` と `ya env` は作らない
- yazi 26.9.1 の `yazi-config/preset/yazi-default.toml` の `[opener]`（2 回目の見直しで読んだ）
  - `edit` は `${EDITOR:-vi} %s`（`for = "unix"`）と、`code %s`（`for = "windows"`・`orphan`）・`code -w %s`（`for = "windows"`・`block`）。`text/*` などの規則は `edit` を最初に使う
  - 自分用の設定（`ryo-aoki-pc/yazi` の `custom`、`1e6b294`）の `yazi.toml` は、Windows の `edit` を `nvim %s`（`block`）と `neovide %s`（`orphan`）にしてある
- yazi 26.9.1 の `yazi-plugin/preset/plugins/mime-local.lua`・`file.lua`（2 回目の見直しで読んだ）: `YAZI_FILE_ONE`（無ければ `file`）を Lua の `Command` で起動する
  - `yazi-binding/src/process/command.rs` の `Command` は `tokio::process::Command::new` で、シェルを挟まない
- scoop 本体のメッセージの文字列（neovim.md の検証記録の付録と同じ）。複数のアプリを並べた `scoop install` は、入っていたものに `'<名前>' (<版>) is already installed. Skipping.` を出す（`libexec/scoop-install.ps1`）
- 同じ日の scoop の main の定義で、`$YAZI_EXTRAS` の 9 個はどれもある（ffmpeg 9.0.2・7zip 26.04・jq 1.8.2・poppler 26.09.0-0・fd 10.5.0・ripgrep 15.2.0・fzf 0.74.4・resvg 0.47.0・imagemagick 7.1.2-32）。`jq` は `jid`、`ripgrep` は `extras/vcredist2022` を `suggest` に持つ。`imagemagick` は `MAGICK_HOME` などのユーザーの環境変数を足す（`env_set`）
- GitHub のリリースの `yazi-x86_64-pc-windows-msvc.zip` の sha256 は `7c033e5f…8d21` で、`yazi.json` の `hash` と一致した。中の `yazi.exe`・`ya.exe` のインポート表（`objdump -p` の `DLL Name`）には `VCRUNTIME140.dll`（と `api-ms-win-crt-*`）がある。Windows の実行ファイルは動かしていない

**構文と Windows PowerShell 5.1 との互換**（Linux の PowerShell 7.5.3 と PSScriptAnalyzer 1.25.0）:

- 手順書の `powershell` のブロック 9 個を取り出し、PowerShell 7.5.3 の構文解析器に通した（構文の誤り 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0（ほかの規則の指摘は、ASCII でない文字を含むブロックの BOM だけ）

**模擬**（Linux の PowerShell 7.5.3）:

- ブロックの文字列のうち、管理者の判定（`WindowsPrincipal`。Linux では使えない）を `$false` に、`[Environment]` のユーザーの環境変数（Linux の .NET では読み書きされない）を、値をハッシュテーブルに記録する偽物のクラスに置き換えた。`$env:WINDIR`・`$env:APPDATA`・`$env:TEMP` と `C:\Program Files\Git\usr\bin\file.exe` は一時的な場所にした。scoop は、渡った引数を記録してメッセージだけを出す偽物の `scoop.ps1`
- Windows 11 で使うの手順 2・4: `$YAZI_EXTRAS` を設定すると、偽物の scoop に `install yazi ffmpeg 7zip jq poppler fd ripgrep fzf resvg imagemagick`（引数 11 個）が渡った。`$YAZI_EXTRAS = @()` では `install yazi`（引数 2 個）
  - 比べるために、変数を確かめない `scoop install yazi @YAZI_EXTRAS` だけを、`$YAZI_EXTRAS` が無い状態（この節の手順 2 を貼っていない新しい窓に当たる）で流すと、空の引数が 1 つ足されて scoop に渡った（引数 3 個）。手順書のブロックは、変数を消して流すと、`中断: この節の手順 2 の $YAZI_EXTRAS が無い。手順 2 を貼り直す` で止まり、scoop は呼ばれなかった
- Windows 11 で使うの手順 3: `FileExe`・`YaziFileOne`・`Config` が、偽物の `file.exe`・環境変数・`%APPDATA%\yazi\config` に当たるフォルダーの有無で変わった
- Windows 11 で使うの手順 5: `file.exe` に当たるファイルが無いときは `中断:` で止まり、環境変数は書かなかった。あるときは、ユーザーの環境変数と今の窓の `$env:YAZI_FILE_ONE` の両方に入り、`YAZI_FILE_ONE = <パス>` が出た
- Windows 11 で使うの手順 6・9: 偽物の yazi・ya で、3 つのコマンドと `yazi` がこの順に動いた（表示は偽物のもの。実際の `ya env` は流していない）
- ロールバックの手順 1: yazi と ya が PATH にあるときは `Source` の表に 2 行が出て、無いときは `Get-Command` の行は何も出さなかった
- ロールバックの手順 2: ユーザーの環境変数と今の窓の値が消え、`YAZI_FILE_ONE = ` が出た。無いときに貼り直しても、エラーにならなかった

**最後の確認**（見直しの後。レビューの指摘で手順書・検証記録・参考資料を直した後に、同じ Linux のコンテナで確かめ直した。**Windows 実機では未検証**）:

- 手順書の `powershell` のブロックを取り出し直した。yazi.md は 9 個で、中身は直す前と同じだった（直したのは箇条書きと 1 行の説明だけで、ブロックの位置だけが変わった）
- PowerShell 7.5.3 の構文解析器で、構文の誤りは 0。PSScriptAnalyzer 1.25.0 の 5.1 互換の 3 規則の指摘は 0。ほかの規則の指摘は、Windows 11 で使うの手順 2・4・5 の BOM の 3 件だけ（ASCII でない文字を含む）
- 偽物の scoop は、neovim.md の検証記録の付録の「最後の確認」と同じもの（メッセージは scoop 本体のソースから写した。実際の scoop の出力ではない）。前の模擬の偽物が、更新で新しい版が無いときに出していた `The latest version of …` は、手で書いたもので、scoop の振る舞いから取ったものではない
- imagemagick の環境変数が今の窓にも入ることは、scoop 本体のソースで読んだだけ（`lib/install.ps1` の `env_set` の `Set-Content env:\$name`、`lib/system.ps1` の `Add-Path` の「current session」の `$env:PATH`。scoop の `.ps1` は同じ PowerShell の中で動く）。模擬はしていない
- 模擬の結果（18 通り。表示は偽物のもの）:
  - Windows 11 で使うの手順 4: 手順 2 の `$YAZI_EXTRAS` で、偽物の scoop に `install yazi ffmpeg 7zip jq poppler fd ripgrep fzf resvg imagemagick`（引数 11 個）が渡った。7zip を入っている扱いにすると、`WARN  '7zip' (26.04) is already installed. Skipping.` の後に残りの 9 個が入った
  - 同じ手順 4: `@()` では `install yazi`、`@('fd')` では `install yazi fd`。`@()` を付けずに `$YAZI_EXTRAS = 'fd'` にすると、`install yazi f d`（引数 4 個）が渡った（文字列が 1 文字ずつに分かれる。手順 2 の箇条書きに足した）。変数が無いときは `中断:` で止まり、scoop は呼ばれなかった
  - 手順 3: `YAZI_FILE_ONE` に別の値（scoop の `file` の場所に当たる文字列）を入れておくと、`YaziFileOne` にその値が出た。続く手順 5 は確かめずに Git for Windows の `file.exe` に書き換え、ユーザーの値と今の窓の値の両方が変わった（手順 3 の箇条書きに、上書きされることを足した）
  - 手順 5: `file.exe` に当たるファイルが無いときは `中断:` で止まり、値は書かなかった（前の記録と同じ）
  - 更新の手順 1: 新しい版が無いときは `yazi: 26.9.1 (latest version)` と `Latest versions for all apps are installed! For more information try 'scoop status'`
  - ロールバックの手順 1・2: 前の記録と同じ（`Get-Command` の行は、yazi と ya が PATH に無ければ何も出さない。`YAZI_FILE_ONE` はユーザーと今の窓から消え、2 回目もエラーにならない）
- ロールバックのリードに足した 2 つの確認（`git -C "$env:APPDATA\yazi\config" status --short` と `… log --oneline '@{u}..'`）:
  - PowerShell 7.5.3 の構文解析器で誤り 0。`'@{u}..'` は 1 つの引数になった（引用符が無いと、`@{` がハッシュテーブルとして読まれる）
  - Linux の git 2.43.0 で、上流のある使い捨ての clone を `$env:APPDATA` の下に置いて流した（`\` は `/` にした）。push 済みのときは 2 つとも何も出さなかった。push していないコミットを 1 つ足すと、`status --short` は何も出さず、`log --oneline '@{u}..'` だけがそのコミットを出した

**2 回目の見直しの後の確認**（2026-10-08。2 回目のレビューの指摘で手順書・検証記録・参考資料を直した後に、同じ Linux のコンテナで確かめ直した。**Windows 実機では未検証**）:

- 手順書の変更: Windows 11 で使うの手順 7 は、コマンドの無い手順の箇条書きで `type -t y` と `y` を打たせていた
  - Git Bash のタブを開く手順 7（コマンドの無い手順）と、`type -t y`・`y` の `bash` のブロックの手順 8 に分けた。PowerShell の `yazi` は手順 9 になった
  - ほかの変更は、箇条書き・リード・1 行の説明だけ
- 手順書の `powershell` のブロックを取り出し直した。yazi.md は 9 個で、中身は前の確認と同じだった（位置と、TUI の手順の番号だけが変わった）。`bash` のブロックは、Windows 11 で使うの手順 8 の 1 個が増えた
- PowerShell 7.5.3 の構文解析器で、構文の誤りは 0。PSScriptAnalyzer 1.25.0 の 5.1 互換の 3 規則の指摘は 0。ほかの規則の指摘は、Windows 11 で使うの手順 2・4・5 の BOM の 3 件だけ
- 偽物の scoop・yazi・ya での模擬を、前の確認と同じ 18 通りで流し直した。結果は前の確認と同じだった（TUI の手順は手順 9 として流した。表示は偽物のもの）
  - `@()` を付けずに `$YAZI_EXTRAS = 'fd'` にすると、偽物の scoop に `install yazi f d`（引数 4 個）が渡り、`@('fd')` では `install yazi fd`（引数 3 個）だった。Linux の PowerShell 7.5.3 だけで流し、Windows PowerShell 5.1 では流していない
- Windows 11 で使うの手順 8 の `bash` のブロック: `bash -n` で誤り 0
  - Linux の bash 5.2.21 で、bash リポジトリ（`bdb64c2`）の `bashrc` の `y` を定義し、`--cwd-file` にフォルダーを書く偽物の yazi で、ブロックをそのまま流した
  - `type -t y` は `function` を出した。偽物の yazi が別のフォルダー（名前に空白と日本語を含む）を書くと、`y` の後にそのフォルダーへ移った。何も書かないとき（`Q` に当たる）と、同じフォルダーを書いたときは、移らなかった
  - Windows の Git Bash と WezTerm のタブでは流していない
- `ya env` の `Config` の行: Linux の `ya` 26.9.1（GitHub のリリースの `yazi-x86_64-unknown-linux-gnu.zip`）を擬似端末で動かした
  - `YAZI_CONFIG_HOME` を無いフォルダーにしても、空のフォルダーにしても、6 行とも `No such file or directory (os error 2)` だった。無いフォルダーは作られなかった
  - Linux は、フォルダーが無いときもファイルが無いときも ENOENT（2）を返す。最初に手順書に書いた `os error 2` は、この振る舞いに当たる
  - Windows では、フォルダーが無いと ERROR_PATH_NOT_FOUND（`os error 3`）、フォルダーがあってファイルが無いと ERROR_FILE_NOT_FOUND（`os error 2`）になるはずなので、手順書の箇条書きを両方に分けた。Windows では流していない

**ロールバックの手順 2 を直した後の確認**（2026-10-08。git-delta.md などの Windows 11 の節が入った版に載せ替えた後のレビューの指摘で直してから、同じ Linux のコンテナで確かめ直した。**Windows 実機では未検証**）:

- 手順書の変更: Windows 11 のロールバックの手順 2 は、`YAZI_FILE_ONE` を値に関係なく消していた
  - 値が `C:\Program Files\Git\usr\bin\file.exe` のときだけ消し、今の窓の値はユーザーの値に合わせる形にした。Windows 11 で使うの手順 3 で控えた元の値は、その箇条書きの 1 行で戻す
  - ほかの変更は、箇条書き・リード・1 行の説明だけ（Windows 11 で使うの手順 7・8 の条件に WezTerm の自分用の設定を足した、など）
- 手順書の `powershell` のブロックを取り出し直した。yazi.md は 9 個で、ロールバックの手順 2 のほかは前の確認と同じだった
- PowerShell 7.5.3 の構文解析器で、構文の誤りは 0。PSScriptAnalyzer 1.25.0 の 5.1 互換の 3 規則の指摘は 0。ほかの規則の指摘は、Windows 11 で使うの手順 2・4・5 の BOM の 3 件だけ
- 模擬（ユーザーの環境変数は、前の記録と同じく値をハッシュテーブルに記録する偽物）:
  - 値が Git for Windows の `file.exe` のときは、ユーザーの値と今の窓の値が消え、`YAZI_FILE_ONE = ` が出た。2 回目もエラーにならなかった。大文字と小文字だけが違う値（`c:\program files\git\usr\bin\FILE.EXE`）も消えた
  - ほかの値（scoop の `file` の場所に当たる文字列）は残り、`YAZI_FILE_ONE = <その値>` が出て、今の窓の値もその値になった
  - ほかの値を入れておき、Windows 11 で使うの手順 5（`file.exe` は一時的な場所の空のファイル）→ ロールバックの手順 2 → 箇条書きの 1 行（控えた値を入れたもの）の順に流すと、ユーザーの値は元の値に戻った（今の窓の値は空のまま）

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（scoop での導入・更新・削除）
1. `VCRUNTIME140.dll` が無い PC で、`yazi --version` が何も出さずに終わるか、システム エラーの窓が出るか
1. `ya env` の `Routine` が `text/plain` になり、`Dependencies` に `$YAZI_EXTRAS` のツールの版が出ること
1. `ya env` の `Config` の行が、設定のフォルダーが無いときに `os error 3`、フォルダーはあってファイルが無いときに `os error 2` になること
1. ユーザーの環境変数 `YAZI_FILE_ONE` が、新しい窓と WezTerm のタブに効くこと
1. TUI のプレビュー（PDF・動画・画像・書庫）と、WezTerm・Windows Terminal・conhost での画像の表示
1. WezTerm の Git Bash のタブ（手順 7）に手順 8 の `bash` のブロックを貼り、`y`（共通の bash 設定）で閉じたフォルダーへ移ること
1. Enter でテキストを開いたときのエディタ（自分用の設定では `nvim`、上流の既定の設定では `code`）
1. 自分用の設定（`%APPDATA%\yazi\config` への clone）との組み合わせ
1. SSH のセッションと、arm64 の Windows

---

## 統合前の記録: Claude Code の Windows 11（もとは claude-code.md）

もとの `claude-code.md` の検証記録のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の検証記録](almalinux-setup.md#統合前の記録-claude-codeもとは-claude-codemd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1 | （なし。前の項で開いた窓を使う） |
| Windows 11 で使う 2〜9 | 「Claude Code」の手順 1〜8 |
| Windows 11 の更新 1 | 「AI エージェントとプラグインを上げる」の手順 1 |
| Windows 11 のロールバック 1〜4 | ロールバックの「AI エージェントとプラグインを消す」の手順 2〜5 |

### Claude Code: 最新の確認範囲（Windows 11）

- 通したこと（どれも Windows 11 Pro の同じクリーン VM。実機ではない）
  - 2026-10-06: Windows 節の手順 2〜5 による native installer の新規導入とユーザー PATH、新しいプロセスでの手順 7 の版・署名・doctor の導入診断（[付録](#claude-code-付録-windows-11-pro-の-vm-での導入検証2026-10-06)）
  - 2026-10-08: スタートから開いた窓への貼り付けで、手順 7、更新（2.1.291 → 2.1.293）、ロールバックの手順 1〜4、入れ直し（手順 2〜7。PATH の変更がスタートから開き直した窓に届いた）、手順 8 のログインの画面の手前まで、手順 9 のログインしていない分岐（[付録](#claude-code-付録-windows-11-pro-の-vm-での追加検証2026-10-08)）
- 確認していないこと
  - ログイン（claude.ai での承認）と、その後の手順 8・9、認証を要するコマンドと Remote Control
  - 手順 8 でブラウザが自動で開かなかった原因（本文の `c` で URL をコピーする経路は確かめた）
- 導入診断が正常でも認証済みとは扱わない。以降の既存記録は、各実施日・対象版・範囲に従う履歴として保持した

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### Claude Code: 補足

#### Claude Code: Windows 11 で使う / 手順 0: 本文中の記録

- 手順の後: `claude` のコマンドラインは[使い方の基本](../almalinux-setup.md#claude-code-の使い方の基本)（確かめたのは Linux だけ）。SSH でログインして Remote Control を使い続けるなら [windows-claude-remote-control.md](../windows-claude-remote-control.md)。以後は[Windows 11 の更新](../windows-setup.md#ai-エージェントとプラグインを上げる)・[Windows 11 のロールバック](../extra/windows-setup.md#ai-エージェントとプラグインを消す)

#### Claude Code: Windows 11 で使う: 検証状況の記録

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、公式の文書、インストーラ（`install.ps1`）と Windows の `claude.exe`（2.1.288）の中身と署名、Linux の PowerShell 7 での構文と模擬の実行、Linux の同じ版の native installer の動きだけ（[対象と検証環境](almalinux-setup.md#claude-code-対象と検証環境)）。

#### Claude Code: Windows 11 で使う / 手順 2: 補足: チャンネルの決まり方と、後から変える方法

- この節の手順 4 のインストーラは、Claude Code の `claude install <チャンネル>` を動かす。`claude install` は、選んだチャンネルを自分のユーザーの設定（`%USERPROFILE%\.claude\settings.json`）の `autoUpdatesChannel` に書き、以後の自動の更新と `claude update` はそのチャンネルを追う（公式の文書の Install a specific version と Configure release channel。書かれることは Linux の native installer の 2.1.288 で確かめた）
- 入れた後でチャンネルを変えるときは、`claude install stable`（戻すときは `claude install latest`）を打つ。Linux の 2.1.288 では、`latest` の 2.1.288 から `stable` の 2.1.285 に下がり、`autoUpdatesChannel` も `stable` になった（[付録](#claude-code-付録-windows-11-の配布物と資料の調査2026-10-03)）
- セッションの中の `/config` の Auto-update channel でも変えられる（公式の文書。`stable` へ移るときは、今の版に留まるか、下げるかを聞かれる）
- [実施手順](../almalinux-setup.md#claude-code)（AlmaLinux 10）の dnf の版では、チャンネルは repo ファイルの `baseurl` で決まり、`autoUpdatesChannel` は効かない

#### Claude Code: Windows 11 で使う / 手順 4: 補足: インストーラがすることと、irm | iex にしない理由

`https://claude.ai/install.ps1` は `https://downloads.claude.ai/claude-code-releases/bootstrap.ps1` へ飛ぶ。2026-10-03 に読んだ中身（[付録](#claude-code-付録-windows-11-の配布物と資料の調査2026-10-03)）:

- `claude-code-releases/latest` から一番新しい版の番号を取り、その版の `manifest.json` の `win32-x64`（arm64 の Windows なら `win32-arm64`）の sha256 と照らして、`claude.exe` を `%USERPROFILE%\.claude\downloads` に落とす。合わなければ `Checksum verification failed` で止まる
- 落とした `claude.exe` で `claude install <チャンネル>` を動かし、終わったら落としたファイルを消す。`claude install` が、選んだチャンネルの版を `%USERPROFILE%\.local\share\claude\versions` に置き、`%USERPROFILE%\.local\bin\claude.exe` を作る
- **インストーラは、`manifest.json` の GPG の署名も、`claude.exe` の Authenticode の署名も確かめない**（sha256 の照合だけで、`manifest.json` も同じ HTTPS のサーバーから取る）。署名はこの節の手順 7 で確かめる
- `PATH` は変えない。`claude install` は、`PATH` に無ければ足し方を出すだけ（Windows の `claude.exe` の 2.1.288 の中に、`PATH` を書く処理の文字列は見当たらなかった）

**公式の文書の既定の形 `irm https://claude.ai/install.ps1 | iex` にしない理由**:

- `Invoke-Expression` はスクリプトを今のスコープで動かすので、スクリプトの先頭の `Set-StrictMode -Version Latest`・`$ErrorActionPreference = "Stop"`・`$ProgressPreference = 'SilentlyContinue'` が、入れた後の PowerShell にも残る（Linux の PowerShell 7.6.6 で確かめた。付録）。残ると、後から貼ったブロックで、未定義の変数がエラーになり、どのエラーでも止まるようになる
- この手順の形（`& ([scriptblock]::Create(...)) <チャンネル>`）は、公式の文書がチャンネルを選ぶときに使う形で、別のスコープで動くので何も残らない。`irm` は `Invoke-RestMethod` の別名

#### Claude Code: Windows 11 で使う / 手順 7: 補足: 署名と doctor の出力

- 公式の文書（Binary integrity and code signing）は、Windows の `claude.exe` は「Anthropic, PBC」が署名し、`Get-AuthenticodeSignature` で確かめられるとしている
- 2.1.288 の Windows の `claude.exe`（x64）の署名を Linux で読むと、署名者は DigiCert の Code Signing の CA が出した `CN="Anthropic, PBC"`（証明書の期限は 2026-10-20）で、DigiCert のタイムスタンプ（2026-10-02）が付いていた（[付録](#claude-code-付録-windows-11-の配布物と資料の調査2026-10-03)）。タイムスタンプがあるので、証明書の期限が切れた後も `Valid` のままのはず
- `claude doctor` の行は、Linux の native installer の 2.1.288 の出力（同じ付録）から引いた。Windows では `Platform: win32-x64` になるはず（確かめていない）
- 自動の更新は、Claude Code を起動したときと動いている間に確かめ、裏で入れて、次の起動から新しい版になる（公式の文書）。`claude doctor` の `Last update attempt` に最後の結果が出る

#### Claude Code: Windows 11 の更新 / 手順 1: 補足: 更新の動き

- 出力の文言は公式の文書（Update manually）から。Linux の native installer の 2.1.288 では、`Current version: 2.1.288`・`Checking for updates to latest version...`・`Claude Code is up to date (2.1.288)` と出た（[付録](#claude-code-付録-windows-11-の配布物と資料の調査2026-10-03)）
- Windows では、動いている `claude.exe` を同じフォルダーの `claude.exe.old.<数字>` に名前を変えてから、新しい版を置く（公式の Troubleshoot installation）
- 新しい版は `%USERPROFILE%\.local\share\claude\versions` に置かれる。古い版は、使っているものと新しい 2 つを残して消される（公式の文書の Install on network storage）
- [windows-claude-remote-control.md](../windows-claude-remote-control.md) の実機では、検証の間に、自動の更新で 2.1.283 から 2.1.286 に上がった

#### Claude Code: 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、インストーラと配布物と資料を読んだ記録。

##### Claude Code: インストーラ（`install.ps1`）

```
$ curl -sS -o /dev/null -w '%{http_code} %{redirect_url}\n' https://claude.ai/install.ps1
302 https://downloads.claude.ai/claude-code-releases/bootstrap.ps1
$ curl -sS -o install.ps1 -L https://claude.ai/install.ps1
$ sha256sum install.ps1
cd17c6b555f761d60373659824bf805e1510538226e4c7028e19d7494937a333  install.ps1
```

3,189 バイトの PowerShell。読んだ中身:

- `param` の位置引数 `$Target`（既定は `latest`。`^(stable|latest|\d+\.\d+\.\d+(-[^\s]+)?)$` に合わないと拒む）
- 先頭で `Set-StrictMode -Version Latest`・`$ErrorActionPreference = "Stop"`・`$ProgressPreference = 'SilentlyContinue'`
- `[Environment]::Is64BitProcess` が偽なら `Claude Code does not support 32-bit Windows. ...` で止まる
- `$env:PROCESSOR_ARCHITECTURE` が `ARM64` なら `win32-arm64`、ほかは `win32-x64`
- `https://downloads.claude.ai/claude-code-releases/latest` から版の番号を取り（`$Target` によらず一番新しい版。コメントは「最新のインストーラを持つため」）、`<版>/manifest.json` の `platforms.<プラットフォーム>.checksum` を読む
- `<版>/<プラットフォーム>/claude.exe` を `Invoke-WebRequest` で `%USERPROFILE%\.claude\downloads\claude-<版>-<プラットフォーム>.exe` に落とし、`Get-FileHash` の sha256 が合わなければ `Checksum verification failed` で消して止まる
- `Setting up Claude Code...` を出して `& $binaryPath install $Target` を動かし、`finally` で 1 秒待ってから落としたファイルを消す。終了コードが 0 でなければ `Installation failed (exit code <N>)`、0 なら `✅ Installation complete!`
- `manifest.json` の署名（`manifest.json.sig`）も、`claude.exe` の Authenticode の署名も、確かめる処理は無い。`PATH` にも触らない

##### Claude Code: リリースと `manifest.json`

```
$ for c in latest stable; do printf '%s: ' $c; curl -fsS https://downloads.claude.ai/claude-code-releases/$c; echo; done
latest: 2.1.288
stable: 2.1.285
```

2.1.288 の `manifest.json`（`buildDate` は 2026-10-02T17:00:28Z）の署名を、`https://downloads.claude.ai/keys/claude-code.asc` の鍵（fingerprint `31DD DE24 DDFA B679 F42D  7BD2 BAA9 29FF 1A7E CACE`。[実施手順](../almalinux-setup.md#claude-code)の手順 3 の dnf の鍵と同じ）で確かめた（gpg 2.4.4）:

```
gpg:                using RSA key 31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE
gpg: Good signature from "Anthropic Claude Code Release Signing <security@anthropic.com>" [unknown]
```

Windows の行:

| プラットフォーム | sha256 | 大きさ |
|---|---|---|
| `win32-x64` | `84304f7d4b0cd0ebcbe8318695a260151b48991a6659c3366fdd5da290c0ab91` | 249,149,600 |
| `win32-arm64` | `5015d2b92866232b85384ac6e5eef4ff155418a92123503e52714c29186af8c6` | 236,673,184 |

`2.1.288/win32-x64/claude.exe` を取り、sha256 が `manifest.json` と一致した。

##### Claude Code: `claude.exe`（2.1.288、x64）の署名

osslsigncode 2.8 の `verify` の出力の抜粋（Windows の `Get-AuthenticodeSignature` は通していない）:

```
Signer's certificate:
	Signer #0:
		Subject: /jurisdictionC=US/jurisdictionST=Delaware/businessCategory=Private Organization/serialNumber=4860621/C=US/ST=California/L=San Francisco/O=Anthropic, PBC/CN=Anthropic, PBC
		Issuer : /C=US/O=DigiCert, Inc./CN=DigiCert Trusted G4 Code Signing RSA4096 SHA384 2021 CA1
		Certificate expiration date:
			notBefore : Oct 14 00:00:00 2025 GMT
			notAfter : Oct 20 23:59:59 2026 GMT
Countersignatures:
	Timestamp time: Oct  2 16:56:42 2026 GMT
	Issuer: /C=US/O=DigiCert, Inc./CN=DigiCert Trusted G4 TimeStamping RSA4096 SHA256 2025 CA1
...
Number of verified signatures: 1
Succeeded
```

- 署名の中の証明書を Linux の PowerShell 7.6.6 の `X509Certificate2` に読ませると、`Subject` は `CN="Anthropic, PBC", O="Anthropic, PBC", L=San Francisco, S=California, C=US, SERIALNUMBER=4860621, ...` だった（名前に `,` があるので引用符で囲まれる）。[Windows 11 で使う](../windows-setup.md#claude-code)の手順 7 の箇条書きは、この形から引いた
- 公式の文書（Binary integrity and code signing）の「signed by "Anthropic, PBC"」と合う

##### Claude Code: `claude.exe` の中の文字列

`strings` で読んだ（Linux 版の 2.1.288 の実行ファイルにも同じ文字列がある）:

- Windows で `PATH` に無いときの案内: `Native installation exists but ${D} is not in your PATH. Add it by opening: System Properties → Environment Variables → Edit User PATH → New → Add the path above. Then restart your terminal.`（`${D}` は `claude.exe` のフォルダー）。`SetEnvironmentVariable`・`HKCU\Environment` のような、`PATH` を書く処理の文字列は無かった
- 置き場所: 版は `<XDG_DATA_HOME か ホーム\.local\share>\claude\versions`、更新の途中のファイルは `<XDG_CACHE_HOME か ホーム\.cache>\claude\staging`、ロックは `<XDG_STATE_HOME か ホーム\.local\state>\claude\locks`、実行ファイルは `ホーム\.local\bin\claude.exe`
- 更新のときに退ける名前は `<実行ファイル>.old.<ミリ秒>.<PID>`
- `claude install` は、`latest` / `stable` を渡されると、自分のユーザーの設定に `autoUpdatesChannel` を書く（`Install: Saved autoUpdatesChannel=...`）
- 更新のときに `manifest.json` の署名を確かめる処理の文言（`predates manifest signature enforcement` など）がある。どの条件で強制されるかは読んでいない

##### Claude Code: Linux の native installer の同じ版での動き

一時的な `HOME` で、Linux の 2.1.288 の実行ファイル（`manifest.json` の `linux-x64` と sha256 が一致）に `install latest` を動かした（`install.ps1` が Windows で動かすのと同じ `claude install`。標準入力無し・`TERM=dumb`。空行は詰めた）:

```
Checking installation status...
Installing Claude Code native build latest...
Setting up launcher and shell integration...
⚠ Setup notes:
  ● Native installation exists but ~/.local/bin is not in your PATH. Run:
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> your shell config file && source your shell config file
✔ Claude Code successfully installed!
  Version: 2.1.288
  Location: ~/.local/bin/claude
  Next: Run claude --help to get started
⚠ Setup notes:
  ● Native installation exists but ~/.local/bin is not in your PATH. Run:
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> your shell config file && source your shell config file
```

- `Setup notes:` は、成功の表示の前と後に 2 回出た
- できたもの: `~/.local/bin/claude`（`~/.local/share/claude/versions/2.1.288` へのリンク）、`~/.cache/claude/staging`、`~/.local/state/claude/locks`、`~/.claude/settings.json`（`{"autoUpdatesChannel": "latest"}`）、`~/.claude.json`。シェルの設定ファイルは変わらなかった
- `claude doctor`: `Running: native (2.1.288)`・`Config install method: native`・`Auto-updates: enabled`・`Auto-update channel: latest`・`Last update attempt: none recorded`・`No installation issues found.`
- `claude update`: `Current version: 2.1.288`・`Checking for updates to latest version...`・`Claude Code is up to date (2.1.288)`、終了コード 0
- 続けて `claude install stable`: `Installing Claude Code native build stable...`・`Version: 2.1.285`。`claude --version` は `2.1.285 (Claude Code)`、`autoUpdatesChannel` は `stable` になり、`versions` には 2.1.285 と 2.1.288 が残った

##### Claude Code: 公式の文書（2026-10-03）

- Advanced setup の Set up on Windows: native の Windows は Git for Windows が任意（Bash のツールと Monitor のツールに Git Bash が要る。無ければ PowerShell のツール）、管理者として動かさなくてよい
- 同じ文書: native installer は裏で自動で更新する。WinGet・Homebrew・apt・dnf・apk は自動では更新しない。`claude update` の出力は `Successfully updated from <古い版> to version <新しい版>` か `Claude Code is up to date (<版>)`。アンインストールの Windows PowerShell は `.local\bin\claude.exe` と `.local\share\claude`、設定は `.claude` と `.claude.json`
- Troubleshoot installation: PowerShell のインストーラが終わっても `claude` が見つからないときは、`[Environment]::SetEnvironmentVariable('PATH', "$currentPath;$env:USERPROFILE\.local\bin", 'User')` で足して端末を開き直す。更新の後に `claude.exe` が無いときは、`claude.exe.old.*` の一番新しいものの名前を戻す（v2.1.281 より前は、退けたファイルを消すことがあった）
- Authentication: Windows のログインの情報は `%USERPROFILE%\.claude\.credentials.json`

##### Claude Code: パッケージの定義（採らなかった経路）

- winget の `Anthropic.ClaudeCode`（winget-pkgs の 2026-10-03 の `master` を浅い sparse clone で見た）: 最新は 2.1.286（`ReleaseDate: 2026-09-30`）。`InstallerType: portable`、`Commands: claude`、x64 と arm64 の `InstallerUrl` は `downloads.claude.ai/claude-code-releases/2.1.286/win32-*/claude.exe`、`Publisher: Anthropic PBC`。定義の先頭のコメントは `Created with YamlCreate.ps1 Dumplings Mod`
- scoop の `main/claude-code`: 2.1.288。`storage.googleapis.com` の `claude-code-releases/2.1.288/win32-x64/claude.exe` で、`hash` は上の `win32-x64` と同じ。`autoupdate` は `manifest.json` の `checksum` を使う。`notes` に Git と `CLAUDE_CODE_GIT_BASH_PATH`
- Chocolatey の `claude-code`: 2.1.285（`community.chocolatey.org` のパッケージの飛び先の名前で見ただけ）

---

#### Claude Code: 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-03）

Linux（クラウドのコンテナ）の PowerShell 7.6.6 と PSScriptAnalyzer 1.25.0 で確かめた。

**構文と Windows PowerShell 5.1 との互換**:

- Windows 11 の 3 節の `powershell` のブロック 12 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。指摘は 0

**[Windows 11 で使う](../windows-setup.md#claude-code)の手順 2・4**: 文書から抜き出したブロックを、`$env:USERPROFILE` を一時的なディレクトリにして、そのまま流した（本物の `install.ps1` を取って動かす）:

- 手順 2 は `CC_CHANNEL = latest` を出した
- `$CC_CHANNEL` を空にした手順 4 は、`手順 2 の $CC_CHANNEL が空` のエラーだけを出し、何も取らなかった
- `latest` の手順 4 は、版（2.1.288）と `manifest.json` を取り、`win32-x64` の `claude.exe` を `%USERPROFILE%\.claude\downloads` に落として sha256 が合い、`Setting up Claude Code...` まで進んだ。その後の `claude.exe install latest` は、Linux では Windows の実行ファイルを動かせないので、`failed to run` のエラーで止まった。落としたファイルは消え、空の `.claude\downloads` が残った
- 流した後の PowerShell は、`$ErrorActionPreference` が `Continue`、`$ProgressPreference` が `Continue`、未定義の変数を読んでもエラーにならなかった（インストーラの設定が残っていない）

**`irm … | iex` との違い**: `install.ps1` と同じ先頭（`param` と `Set-StrictMode -Version Latest`・`$ErrorActionPreference = "Stop"`・`$ProgressPreference = "SilentlyContinue"`）の文字列を `iex` に渡すと、流した後も `$ErrorActionPreference` が `Stop`、`$ProgressPreference` が `SilentlyContinue` のままで、未定義の変数を読むと `VariableIsUndefined` のエラーになった。`& ([scriptblock]::Create(...)) stable` では何も残らず、位置引数の `stable` が `$Target` に入った。Windows PowerShell 5.1 では確かめていない

**[Windows 11 で使う](../windows-setup.md#claude-code)の手順 5 と[Windows 11 のロールバック](../extra/windows-setup.md#ai-エージェントとプラグインを消す)の手順 2〜4**: 文書から抜き出したブロックの `[Environment]::GetEnvironmentVariable('Path', 'User')` と `SetEnvironmentVariable('Path', …, 'User')` を、値を覚えておく偽物に置き換え（Linux の .NET は `User` の環境変数を持たない）、`$env:USERPROFILE` を一時的なディレクトリにして流した（パスの `\` は Linux の pwsh がそのまま区切りとして扱った）:

- 手順 5、PATH に無いとき: `PATH に <USERPROFILE>\.local\bin を足した` で、書いたのは 1 回、値は前の値の後ろに `;<USERPROFILE>\.local\bin`
- もう 1 度: `はもうある` で、書かなかった。末尾に `\` の付いた `<USERPROFILE>\.local\bin\` があるときも `はもうある`
- PATH が空のとき: `<USERPROFILE>\.local\bin` だけを書いた
- `claude.exe` が無いとき: `中断: <USERPROFILE>\.local\bin\claude.exe が無い（この節の手順 4 で入っていない）` で、書かなかった
- ロールバックの手順 2: `claude.exe`・`claude.exe.old.<数字>.<数字>`・`.local\share\claude`・`.local\state\claude`・`.cache\claude` が消え、`False` が 2 行出た。空の `.local\bin`・`.local\share`・`.local\state`・`.cache` と、`.claude`・`.claude.json` は残った
- ロールバックの手順 3、`.local\bin` が空のとき: PATH から `<USERPROFILE>\.local\bin` だけが外れ（書いたのは 1 回）、`.local\bin` も消えた。もう 1 度流すと、書かなかった
- `.local\bin` に別のファイル（`uv.exe`）があるとき: ロールバックの手順 2 の一覧に `uv.exe` が出て、手順 3 は `中断: <USERPROFILE>\.local\bin にほかのファイルがある（ほかのツールが使っている）` で、PATH を変えなかった
- ロールバックの手順 4: `.claude` と `.claude.json` が消え、`False` が 2 行出た

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. `claude install` が Windows で出す文言（`Setup notes:` の `PATH` の案内と、`Location:` の表示）
1. `PATH` を足して開き直した PowerShell で `claude` が動くこと（`SetEnvironmentVariable` の知らせが、スタートメニューから開いた PowerShell に届くこと）
1. `Get-AuthenticodeSignature` が `Valid` を返し、署名者が `CN="Anthropic, PBC", …` で始まること
1. Firefox でのログインと、`claude auth status --text` の表示
1. 自動の更新と `claude update`、更新のときの `claude.exe.old.*`
1. ロールバック（動いている `claude.exe` を消せないこと、`.local\state\claude` と `.cache\claude` が Windows でも作られること）
1. arm64 の Windows、Git for Windows が無いとき、Windows PowerShell 5.1 での `irm … | iex` の後に設定が残ること

---

#### Claude Code: Windows 11 で使う / 手順 5: 補足: PATH の足し方

- 読むときに `%USERPROFILE%` のような書き方は展開され、書き戻すと展開した形（`C:\Users\<WIN_USER>\...`）で残る（.NET Framework の `Environment` の動き。Windows では確かめていない）。自分のユーザーの PATH なので、困ることは無いはず

#### Claude Code: Windows 11 で使う / 手順 8: 補足: ログインの流れと、ログインの情報の置き場所

- 画面の文言は、公式の文書と Windows の `claude.exe`（2.1.288）の中の文字列から引いた。Windows では画面を見ていない

#### Claude Code: Windows 11 のロールバック / 手順 2: 補足: 消すもの

- 本書は、更新の名残の `claude.exe.old.*`（[Windows 11 の更新](../windows-setup.md#ai-エージェントとプラグインを上げる)の補足）と、`%USERPROFILE%\.local\state\claude`（ロック）・`%USERPROFILE%\.cache\claude`（更新の途中のファイル）も消す。この 2 つは、Linux の native installer の 2.1.288 が作ったフォルダーと、`claude.exe` の中の置き場所の決め方（`XDG_*` が無ければホームの下）から足したもので、Windows では確かめていない

---

#### Claude Code: 付録: Windows 11 Pro の VM での導入検証（2026-10-06）

Rufus で作ったインストールメディアからクリーンインストールした専用 VM で、[Windows 11 の初期設定](windows-setup.md#付録-windows-11-pro-の-vm-での導入検証2026-10-06)と Git for Windows の導入の後に実行した。本文の PowerShell のブロックを抽出して、サインイン中の同じユーザーの通常権限で実行した。GUI のコピー・貼り付けや認証操作は試していない。

| 項目 | 確認した値 |
|---|---|
| OS | Windows 11 Pro 26H2、26300.9457、x64 |
| PowerShell | Windows PowerShell 5.1.26100.9444、64 ビット、通常権限、セッション 1 |
| 前提の設定 | CurrentUser の実行ポリシー `RemoteSigned`、新しい PowerShell の Ctrl+Enter は `AddLine` |
| 初回導入前 | `claude` のコマンドと `%USERPROFILE%\.local\bin\claude.exe` は無い。Git は `C:\Program Files\Git\cmd\git.exe`、`bin\bash.exe` も存在 |
| チャンネル・入った版 | `latest`、2.1.291 |

**初回導入（この節の手順 2〜5）**:

- 実行記録は `20261006-110358Z-6b9ec610`。2026-10-06 11:04:38.473 UTC に完了し、手順ごとのエラーは 0、タスクの終了値は 0、開始と完了の対応も確認した
- 公式の native installer が `Claude Code successfully installed!`、版 2.1.291、最後に `Installation complete!` を出した。自分のユーザーの `PATH` に `%USERPROFILE%\.local\bin` が追加された

**新しい PowerShell での確認（この節の手順 7）**:

- 実行記録は `20261006-111039Z-7d090b3a`。2026-10-06 11:10:46.409 UTC に完了し、手順のエラーは 0、最後の CLI とタスクの終了値は 0、開始と完了の対応も確認した
- `Get-Command claude -All` は `%USERPROFILE%\.local\bin\claude.exe` の 1 行だけで、`claude --version` は `2.1.291 (Claude Code)`。Authenticode は `Valid` で、署名者は `CN="Anthropic, PBC", O="Anthropic, PBC", …`
- `claude doctor` は `Running: native (2.1.291)`、`Platform: win32-x64`、導入先と一致する `Path`、`Config install method: native`、`Search: OK (bundled)`、`Auto-updates: enabled`、`Auto-update channel: latest`、`No installation issues found.` を出した
- `doctor` の認証が要る項目は資格情報が無い旨を表示した。Managed settings と Organization policy は取得されず、Remote Control は claude.ai にサインインしていないため利用可否を確認できなかった。導入の診断が正常でも、認証が済んだことにはならない

**未検証の範囲**:

- 手順 1・6 の GUI での PowerShell の開き方、コピー・貼り付け、環境変更の通知がスタートメニューから開いた PowerShell に届くこと
- 手順 8・9 の初期設定・Firefox でのログイン・認証後の状態。認証を要するコマンドや Remote Control の接続
- 自動の更新・`claude update`・チャンネル切り替え、ロールバック、arm64、Git for Windows が無い場合。Windows の実機での通し実行

2026-10-03 以前の付録は当時の確認範囲を記した履歴として保持した。今回も本文のコマンドは変更していない。

---

#### Claude Code: 付録: Windows 11 Pro の VM での追加検証（2026-10-08）

上の付録と同じ VM（[windows-setup.md の検証記録の 2026-10-08 の付録](windows-setup.md#付録-pr-104-の未検証項目を同じ-vm-で確かめた記録2026-10-08)の環境）で、上の付録が「確認していないこと」に挙げた項目を、画面の操作と本文のブロックの貼り付けで確かめた。ログインは行っていない。

| 項目 | 値 |
|---|---|
| 端末 | スタートメニューから開いた通常の Windows PowerShell 5.1（Windows Terminal の中に開く） |
| 貼り方 | 本文のブロックを右クリックで貼り、複数行の警告が出たら「強制的に貼り付け」を押した（windows-setup.md の付録の「操作の方法」） |
| Claude Code | 2.1.291（上の付録で入れたもの）から、更新で 2.1.293 |

**確認したこと**:

- Windows 11 で使うの手順 7: スタートから開いた窓で、`claude` の場所が `C:\Users\<WIN_USER>\.local\bin\claude.exe` の 1 行、署名は `Valid` で `CN="Anthropic, PBC"`、`claude doctor` は native の 2.1.291 と `No installation issues found.`
- Windows 11 の更新の手順 1: `claude update` は `Successfully updated from 2.1.291 to version 2.1.293`
- Windows 11 のロールバックの手順 1〜4（2.1.293 で）:
  - 手順 1: プロセスもタスクも出なかった
  - 手順 2: `False` が 2 行。`.local\bin` の一覧は空
  - 手順 3: ユーザーの PATH から `C:\Users\<WIN_USER>\.local\bin` が消えた
  - 手順 4: `%USERPROFILE%\.claude` と `%USERPROFILE%\.claude.json` の `False` が 2 行
- 入れ直し（Windows 11 で使うの手順 2〜7）:
  - 手順 2〜5: インストーラは `Setup notes` に PATH に無い旨を出し、手順 5 でユーザーの PATH に足した
  - 手順 6: 窓を閉じて、スタートメニューから開き直した（再起動もサインアウトもしていない）
  - 手順 7: 開き直した窓で `claude` が見つかり、2.1.293・署名 `Valid`・`No installation issues found.`。手順 5 の PATH の変更は、スタートから開き直した窓に届いた
- Windows 11 で使うの手順 8（ログインの手前まで）:
  - 文字の色の組み合わせの画面の後、`Select login method:` に 3 つの選択肢（`Claude account with subscription`・`Anthropic Console account`・ほかのプラットフォーム）が出た
  - `Claude account with subscription` を選ぶと、ブラウザは自動では開かず、開かなかったときの案内が出た（原因は分からない）
  - 本文の案内どおり `c` を押すと、claude.com の認可の URL がクリップボードに入った。Firefox に貼ると claude.ai のログインの画面が出た。ここでログインはしていない
  - ログインを待つ画面は Esc でも Ctrl+C でも終わらなかったので、`claude.exe` のプロセスを止めた
- Windows 11 で使うの手順 9: `Not logged in. Run claude auth login to authenticate.`（本文の「ログインしていない」の分岐）。ログインの情報のファイルは作られていなかった
- 検証の最後に、Windows 11 のロールバックの手順 1〜4 をもう一度通した（2.1.293 で）。手順 1 は何も出さず、手順 2 は `False` が 2 行で `.local\bin` は空、手順 3 はユーザーの PATH から `.local\bin` が消え（`scoop\shims` などは残った）、手順 4 は `False` が 2 行

**確認していないこと**:

- ログイン（claude.ai のアカウントでの承認とコードの貼り付け）と、ログインした後の手順 8 の続き・手順 9 の `Login method:` の行・認証の要るコマンドと Remote Control
- ブラウザが自動で開かなかった原因。既定のブラウザは Firefox にしてあった（[firefox.md の検証記録](almalinux-setup.md#統合前の記録-firefoxもとは-firefoxmd)の 2026-10-08 の付録）
- `stable` のチャンネル、自動の更新、arm64 の Windows、Windows の実機

---

## 統合前の記録: Codex CLI の Windows 11（もとは codex.md）

もとの `codex.md` の検証記録のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の検証記録](almalinux-setup.md#統合前の記録-codex-cliもとは-codexmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1〜8 | 「Codex CLI」の手順 1〜8 |
| Windows 11 の更新 1 | 「AI エージェントとプラグインを上げる」の手順 2 |
| Windows 11 の更新 2・3 | 「AI エージェントとプラグインを上げる」の手順 3（版の確かめは、その箇条書き） |
| Windows 11 のロールバック 1〜4 | ロールバックの「AI エージェントとプラグインを消す」の手順 6〜9 |

### Codex CLI: 補足

#### Codex CLI: Windows 11 で使う: 検証状況の記録

> [!WARNING]
> Windows 11 の実機では未検証。公式資料・インストーラーの内容と構文を確認した範囲は[補足](almalinux-setup.md#codex-cli-対象と検証環境)に記載する。

### Codex CLI: 本文から分離した確認範囲と実測

#### Codex CLI: Windows 11 のロールバック

- 設定・会話履歴と、Windows sandbox が作ったユーザー・ポリシーなどは残る。OS の sandbox 設定を元に戻す手順は未検証

---

## 統合前の記録: Grok Build の Windows 11（もとは grok-build.md）

もとの `grok-build.md` の検証記録のうち、Windows 11 の節を、内容を変えずに移したもの（ほかの節は、[AlmaLinux 10 の初期設定の検証記録](almalinux-setup.md#統合前の記録-grok-buildもとは-grok-buildmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [Windows 11 の初期設定](../windows-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| Windows 11 で使う 1〜8 | 「Grok Build」の手順 1〜8 |
| Windows 11 の更新 1・2 | 「AI エージェントとプラグインを上げる」の手順 2・4 |
| Windows 11 のロールバック 1〜5 | ロールバックの「AI エージェントとプラグインを消す」の手順 10〜14 |

### Grok Build: 付録: コンテナでの検証（2026-10-09）

#### Grok Build: Windows 11 の節: 構文の検査

- Windows 11 で使う・Windows 11 の更新・Windows 11 のロールバックの PowerShell の 12 ブロックを、PowerShell 7.6.6 の `[System.Management.Automation.Language.Parser]::ParseInput` で解析した（エラー 0）
- PSScriptAnalyzer 1.25.0 の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（プロファイル `win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework`）で指摘 0
- `install.ps1` は読んで確かめただけで、実行していない（置く場所・MinGit の SHA-256 の確認・ユーザーの PATH の先頭に足すこと・`$ErrorActionPreference = 'Stop'`・失敗のときの `exit 1`）
- Windows のロールバックの手順 3 は、[claude-code.md](../almalinux-setup.md#claude-code) の Windows 11 のロールバックの手順 3 と同じ書き方（その手順は Windows 11 の VM で通っている）だが、この手順書のブロックとしては Windows で流していない
