# Windows 11 の初期設定の手順（インストール直後の更新・貼り付けの設定・scoop・UniGet UI・表示・電源・リモート・WSL）

## 実施手順

> [!IMPORTANT]
> - **すべて、この PC のデスクトップで行う**。SSH のセッションには貼らない（Administrators の一員の SSH のセッションは管理者の権限で動くので、手順 8 の scoop のインストーラが止まる）
> - 窓の使い分け: 手順 3 で**管理者ではない** Windows PowerShell（5.1）を開き、手順 4〜22 をそこに貼る。手順 23 で**管理者の** Windows PowerShell を開き、手順 24〜43 をそこに貼る。再起動の後は、手順 48 で開く管理者ではない PowerShell に手順 49〜52 を貼る
> - ログインするユーザーは Administrators の一員（手順 24〜43 は PC 全体の設定を書く）
> - **手順 4 は 1 行なので、どの貼り方でもそのまま貼れる**。手順 4 を貼った窓には、それより後の複数行のブロックを、GitHub のコピーボタンでコピーして右クリックで貼れる。Windows の PowerShell のブロックを貼るほかの手順書も、手順 4〜7 を前提にする
> - **手順 43 で再起動する**（この文書の再起動はこの 1 回。手順 1 の Windows Update の再起動は別）。多くの設定は、再起動の後に効く
> - **画面で行う手順**: 1・2・3・23・44〜48。手順 19 は設定の画面を開いて変える。**対話入力のある手順**: 50（WSL のユーザー名とパスワード）・52（自動サインインのパスワード）。**条件付きの手順**: 27（PC の名前を変えるとき）・32（Pro 以上）・40（デュアル ブートで、AlmaLinux の時計を UTC にしたとき）・41（US 配列のキーボード）

- 上から順にコードブロックを貼る。手順 24 の変数は、管理者の PowerShell を開き直したら貼り直す
- GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 項目ごとの手順（要らない項目の手順は飛ばしてよい。手順 3〜7・23〜25・43 は飛ばさない）
  - 更新: 1・2。貼り付けの設定: 4〜7・25・26
  - 入れるもの: scoop は 8・9、UniGet UI は 10・47、PowerToys は 11、PowerShell 7 は 12、WSL の AlmaLinux 10 は 42・50・51、自動サインイン（Autologon）は 52
  - 表示: エクスプローラーは 13、旧形式のコンテキストメニューは 14、スタートと検索は 15・37、タスクバーは 16・46、ダークモードは 17、既定の端末は 18
  - 入力: IME の Ctrl+Space は 19、Caps Lock を Ctrl には 39、US 配列のキーボードは 41。確かめるのは 44
  - 整理: 自動で起動するアプリは 20、標準アプリは 21、ウィジェットは 22、デスクトップのショートカットは 38
  - PC 全体: PC の名前は 27、長いパス・開発者モード・sudo は 28、電源とロックは 29、LAN のアダプターの省電力は 30、デュアル ブートの時計は 40
  - ネットワーク: LAN をプライベートには 31、リモート デスクトップは 32、リモート アシスタンスは 33、ping は 34、配信の最適化は 35
  - サインイン: Windows Hello だけのサインインを切るのは 36、自動サインインは 52
- Windows を AlmaLinux 10 とのデュアルブート向けに入れるときは、先に [Windows 11 のデュアルブート向けの導入](windows-dual-boot.md)を通してから、この文書を手順 1 から始める
- 手順の後に、この順に通す手順書（どれも Windows 11 の節がある）
  - [Git for Windows](git.md#windows-11-で-git-for-windows-を入れる)（続けて、Git Bash で同じ文書の実施手順）→ [Firefox](firefox.md#windows-11-で使う)（既定のブラウザーにする）→ [WezTerm](wezterm-nightly.md#windows-11-で使う) → [Claude Code](claude-code.md#windows-11-で使う) → [VirtualBox](virtualbox.md#windows-11-で使う) → [WireGuard](wireguard-road-warrior.md#windows-11-で使う) → [HackGen Console NF](hackgen.md#windows-11-で使う)
  - HackGen Console NF を手順 43 の再起動より前に入れれば、そちらのサインインし直す手順は要らない
  - 必要なら: [Windows の OpenSSH サーバー](windows-openssh-server.md)・[Syncthing の Windows 11 で使う](syncthing.md#windows-11-で使う)・[Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)・[RDP をロックせずに切断（Windows）](windows-rdp-disconnect.md)
- 手順の後: Wake on LAN は[Wake on LAN を使う（任意）](#wake-on-lan-を使う任意)、以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> - **この手順書は Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、Microsoft などの文書、パッケージの定義とソース、Linux の PowerShell 7 での構文と模擬の実行だけ。手順 4〜7 の貼り付けの設定だけは、原因と直し方を実機の conhost の窓で確かめた（[対象と検証環境](#対象と検証環境)）
> - **手順 28 のインラインの sudo、手順 29 の放置でロックしない設定、手順 32 のリモート デスクトップ、手順 36 の Windows Hello 以外のサインイン、手順 52 の自動サインインを重ねると、PC に触れる人と、このユーザーのパスワードを知る人は、このユーザー（管理者）として操作できる**。人が触れる場所にある PC では、手順 29・52 は行わない

1. 設定の Windows Update で、更新が無くなるまで更新する。

   - スタート →「設定」→「Windows Update」→「更新プログラムのチェック」。出たものをすべて入れる
   - 再起動を求められたら再起動し、もう一度チェックする。「最新の状態です」になるまで繰り返す
   - 画面の文言は確かめていない
   - **次の手順は、「最新の状態です」になってから行う**

   <details>
   <summary>補足: 先に更新する理由</summary>

   - インストールしたばかりの Windows は、インストールのメディアを作った時点の版。この後の手順には、新しい版を前提にするものがある（手順 28 の sudo は 24H2 以降、手順 16 の時計の秒など）
   - この後の手順 43 の再起動より前に、Windows Update の再起動を済ませておく。途中で更新の再起動が入ると、手順 24〜42 の設定が効く時期が読みにくくなる

   </details>

1. Microsoft Store で、アプリをすべて更新する。

   - Microsoft Store を開き、左下の「ライブラリ」→「更新プログラムを取得する」（画面の文言は確かめていない）
   - 「アプリ インストーラー」（`winget`）と「Windows Terminal」も上がる。すべて終わるまで待つ
   - **次の手順は、更新が終わってから行う**

   <details>
   <summary>補足: ストアのアプリを先に上げる理由</summary>

   - `winget` は「アプリ インストーラー」に入っていて、ストアで上がる。古いままだと、この後の `winget install` の引数（`--scope` など）が通らないことがある
   - 手順 18 で既定の端末にする Windows Terminal も、ストアのアプリ

   </details>

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする（実行ポリシーとプロファイルは、5.1 と 7 で別々に持つ）

1. 今の窓だけ、Ctrl+Enter を「行を足す」にする。

   ```powershell
   Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine
   ```

   - 何も出なければよい
   - この窓を閉じるまで効く。手順 5 から後の複数行のブロックを、この窓に右クリックで貼れるようにするため

   <details>
   <summary>補足: 行が逆順になる理由</summary>

   - GitHub のコピーボタンは、ブロックの改行を LF だけにしてクリップボードに入れる（末尾の改行も無い）。マウスで選んで Ctrl+C でコピーしたものは、改行が CR LF になる
   - conhost の窓（Windows Terminal ではない窓。検証した PC では、スタートメニューから管理者として開いた Windows PowerShell）に右クリックで貼ると、LF は Ctrl+Enter のキーとして届く
   - Windows PowerShell 5.1 の PSReadLine 2.0.0 では、Ctrl+Enter は `InsertLineAbove`（今の行の上に空の行を作り、そこへ移る）。貼った行が 1 行ずつ上に入るので、ブロックが逆順になる
   - `AddLine` は Shift+Enter と同じ働きで、実行せずに次の行へ進む。LF が来るたびに次の行へ進むので元の順に入り、最後に Enter を押すとブロック全体が 1 回で動く
   - 管理者でない窓（検証した PC では Windows Terminal の中に開く）と、conhost の窓に Ctrl+V で貼ったときは、設定が無くても逆順にならなかった（利用者が確かめた）
   - 実測は[付録](#付録-原因の確認と貼り付けの試験2026-10-03)

   </details>

1. 管理者ではないことと、今の状態を確かめる。

   ```powershell
   $sm = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' -ErrorAction SilentlyContinue).'Scancode Map'
   [pscustomobject]@{
     PowerShell    = $PSVersionTable.PSVersion.ToString()
     Admin         = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Winget        = (Get-Command winget -ErrorAction SilentlyContinue).Source
     Scoop         = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Git           = (Get-Command git -ErrorAction SilentlyContinue).Source
     ClassicMenu   = Test-Path -LiteralPath 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
     ScancodeMap   = if ($sm) { ($sm | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' } else { '' }
     Profile       = $PROFILE
     ProfileExists = Test-Path -LiteralPath $PROFILE
   } | Format-List
   Get-ExecutionPolicy -List | Format-Table -AutoSize
   '実行ポリシー: {0}' -f (Get-ExecutionPolicy)
   ```

   - `PowerShell : 5.1.…` と `Admin : False` が出ればよい。`7.…` か `True` なら、窓を閉じて手順 3 から
   - `Winget` に `…\WindowsApps\winget.exe` の場所が出ればよい。空なら、手順 2 でストアの「アプリ インストーラー」を更新してから
   - `Git` は、Git for Windows がもうあるか（無ければ空。この文書の後に [git.md](git.md#windows-11-で-git-for-windows-を入れる) で入れる）
   - `ClassicMenu` は旧形式のコンテキストメニューの設定があるか（無ければ `False`）
   - `ScancodeMap` が空でなければ、キーの割り当てがもうある。その値を控える（手順 39 は、違う値があれば止まる）
   - `Profile` は、このユーザーの Windows PowerShell が起動のときに読むファイル。`ProfileExists : False` なら、手順 7 で作る
   - 最後の表の `CurrentUser` の値を控える（[ロールバック](#ロールバック)の手順 16 で使う。何も設定していなければ `Undefined`）
   - `実行ポリシー:` が `RemoteSigned`・`Unrestricted`・`Bypass` のどれかなら、手順 6 は何も変えない。Windows 11 の既定は `Restricted`（一覧はどれも `Undefined`）で、このままではプロファイルも scoop も動かない
   - `Scoop` に場所が出たら、scoop はもう入っている。手順 8・9 は飛ばす

   <details>
   <summary>補足: 見ているもの</summary>

   - `Admin` は、この PowerShell が管理者の権限で動いているか（UAC で昇格しているか）。Administrators の一員でも、普通に開いた PowerShell は `False` になる
   - `ClassicMenu` は、手順 14 で作るキー（`HKCU:\Software\Classes\CLSID\{86ca1aa0-…}`）があるか
   - `ScancodeMap` は、手順 39 で書く値（`HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout` の `Scancode Map`）を 16 進で並べたもの。読むだけなら管理者は要らない
   - `$PROFILE` は、このユーザーの、Windows PowerShell のコンソールのプロファイル（`Microsoft.PowerShell_profile.ps1`）。管理者で開いた窓も、同じユーザーなら同じファイルを読む。PowerShell 7・PowerShell ISE・VS Code は別のファイルを読む（about_Profiles）。OneDrive でドキュメントをバックアップしていると、`OneDrive` の下のパスになる
   - `Get-ExecutionPolicy -List` は、範囲（`MachinePolicy`・`UserPolicy`・`Process`・`CurrentUser`・`LocalMachine`）ごとの実行ポリシー。上の範囲ほど優先される。`MachinePolicy` か `UserPolicy` が `Undefined` でなければ、グループ ポリシーで決まっていて、手順 6 では変えられない
   - プロファイルもスクリプト（`.ps1`）なので、実行ポリシーが `Restricted` だと読まれない（Microsoft の about_Execution_Policies。`Restricted` は Windows のクライアントの既定）

   </details>

1. スクリプトの実行ポリシーを RemoteSigned にする。

   ```powershell
   if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force }
   Get-ExecutionPolicy
   ```

   - `RemoteSigned`（もとから `Unrestricted` か `Bypass` だった PC では、その値）が出ればよい
   - 今の値が `RemoteSigned`・`Unrestricted`・`Bypass` のどれかなら、何も書かない
   - 「より限定的なスコープで定義されたポリシーによって上書きされます」の旨のエラーが出て、ほかの値が出たら、グループ ポリシー（`MachinePolicy` か `UserPolicy`）で決められている。その PC では、scoop も手順 7 のプロファイルも使えない（ほかの手順書のブロックは、conhost の窓でも Ctrl+V で貼る）

   <details>
   <summary>補足: 実行ポリシーと scoop・プロファイル</summary>

   - `scoop` のコマンドは PowerShell のスクリプト（`~\scoop\shims\scoop.ps1`）なので、`RemoteSigned`・`Unrestricted`・`Bypass` のどれかでないと動かない。scoop のインストーラも、これを確かめて止まる（[付録](#付録-配布物と資料の調査2026-10-03)）
   - 手順 7 のプロファイルも、同じ理由で、このポリシーでないと読まれない
   - `RemoteSigned` は、この PC で書いたスクリプトはそのまま動かし、インターネットから取ったファイル（Mark of the Web の付いたもの）には署名を求める
   - `-Scope CurrentUser` は自分のユーザーだけの設定で、管理者の権限は要らない。`-Force` は確認の問い（`[Y] はい` など）を出さないため
   - PowerShell 7 は、実行ポリシーを Windows PowerShell 5.1 とは別に持つ。PowerShell 7 で scoop を使うときは、そちらの `Get-ExecutionPolicy` も見る

   </details>

1. プロファイルに、手順 4 と同じ 1 行を足す。

   ```powershell
   & {
     $line = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-setup.md'
     $old = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-powershell-paste.md'
     if (-not (Test-Path -LiteralPath $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
     $text = Get-Content -LiteralPath $PROFILE -Raw
     if ($text -and ($text.Contains($line) -or $text.Contains($old))) { "すでにある: $PROFILE" } else {
       if ($text -and -not $text.EndsWith("`n")) { $line = "`r`n" + $line }
       Add-Content -LiteralPath $PROFILE -Value $line
       "足した: $PROFILE"
     }
     Get-Content -LiteralPath $PROFILE
   }
   ```

   - `足した: C:\Users\<WIN_USER>\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` と、足した行が出ればよい（OneDrive でドキュメントをバックアップしていると、`OneDrive` の下のパスになる）
   - プロファイルにほかの行があれば、それも出る（そのまま残る）
   - 何度貼ってもよい（2 回目からは `すでにある:`）。前の版の手順書（`windows-powershell-paste.md`）で足した行があるときも `すでにある:` で、何も足さない
   - これより後に開く Windows PowerShell の窓（手順 23 の管理者の窓も）は、この行を読む

   <details>
   <summary>補足: プロファイルの書き方</summary>

   - プロファイルが無ければ、`New-Item -Force` がフォルダ（`WindowsPowerShell`）ごと作る
   - 行の末尾の `# windows-setup.md` は、[ロールバック](#ロールバック)で消す行を見分けるための印。2026-10-03 の前の版（貼り付けの設定が別の手順書 `windows-powershell-paste.md` だったとき）は、印が `# windows-powershell-paste.md` だった。どちらの印の行も、この手順は「すでにある」とみなし、ロールバックは消す
   - 足す行は ASCII の文字だけなので、既存のプロファイルの文字コードによらず足せる。Windows PowerShell 5.1 の `Add-Content` は、既存のファイルの BOM（UTF-16 LE・UTF-8）を見て、同じ文字コードで足した
   - `Add-Content` は、ファイルの末尾が改行でなくても改行を足さずに書き足す（最後の行につながった）。そのときは、行の前に改行を付けて足す
   - 対話でない起動（標準入力をリダイレクトした `powershell -Command`）でも、この行はエラーを出さなかった
   - 実測は[付録](#付録-原因の確認と貼り付けの試験2026-10-03)（印を変える前のブロックで試した）

   </details>

1. scoop を入れる。

   ```powershell
   Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
   ```

   - 最後に `Scoop was installed successfully!` が出ればよい
   - `Running the installer as administrator is disabled by default` が出たら、管理者の PowerShell に貼っている。閉じて手順 3 から
   - `Scoop is already installed` が出たら、もう入っている（何も変えずに終わる）。手順 9 へ進む
   - `'C:\Users\<WIN_USER>\scoop' exists and is not empty` が出たら、前に入れた scoop の残り（`persist` など）がある。要らなければ[ロールバック](#ロールバック)の手順 14 で消してから貼り直す

   <details>
   <summary>補足: インストーラのすること</summary>

   - `https://get.scoop.sh` は、公式のインストーラ（`https://raw.githubusercontent.com/scoopinstaller/install/master/install.ps1`）へ飛ぶ。`Invoke-Expression` で、取ったスクリプトをそのまま動かす（公式の README の方法）
   - 中身を読んでから動かすなら、`Invoke-RestMethod -Uri https://get.scoop.sh -OutFile install.ps1` で保存して読み、`.\install.ps1` で動かす（同じ README の方法）。インストーラに Authenticode の署名は無い
   - インストーラは、PowerShell 5 以上・管理者でないこと・実行ポリシー・scoop がまだ無いことを確かめてから入れる
   - 入るもの
     - `~\scoop\apps\scoop\current`（scoop 本体）・`~\scoop\buckets\main`（main のバケット）・`~\scoop\shims`（コマンドの入口）
     - ユーザーの環境変数 `PATH` の先頭に `~\scoop\shims` を足す。変えたことを Windows 全体に知らせる（`WM_SETTINGCHANGE`）ので、この後にスタートメニューから起動したアプリにも届く
     - 設定のファイル `~\.config\scoop\config.json`
   - git があれば、本体と main のバケットを `git clone` で取る。無ければ zip で取る
   - git の無い PC では、`scoop update` が `Scoop uses Git to update itself. Run 'scoop install git' and try again.` で止まる。この文書の後に [git.md](git.md#windows-11-で-git-for-windows-を入れる) で Git for Windows を入れれば、`scoop update` は scoop 本体と main のバケットを git の形に直して上げる（scoop 0.6.0 の `libexec/scoop-update.ps1`。scoop の `git` は入れない。[選択した方針](#選択した方針)）
   - 管理者で入れる方法（インストーラの `-RunAsAdmin`）は、公式の README が安全のために既定で止めているので、使わない

   </details>

1. scoop が入ったことを確かめる。

   ```powershell
   scoop --version
   scoop bucket list
   [Environment]::GetEnvironmentVariable('Path', 'User') -split ';' | Where-Object { $_ -like '*\scoop\shims' }
   ```

   - `Current Scoop version:` の次に `v0.6.0 - Released at 2026-09-30` の形の行が出ればよい（版は実行した日の最新）
   - `scoop bucket list` に `main` の行が出る
   - 最後に `C:\Users\<WIN_USER>\scoop\shims` が出る

1. UniGet UI（winget）と、その scoop の検索に使う scoop-search を入れる。

   ```powershell
   scoop install scoop-search
   winget install --exact --id Devolutions.UniGetUI --source winget --scope user --accept-source-agreements --accept-package-agreements
   winget list --exact --id Devolutions.UniGetUI
   ```

   - `scoop install scoop-search` の最後に `'scoop-search' (2.1.0) was installed successfully!` の形の行が出る
   - winget はインストーラのハッシュを確かめてから入れる。管理者の確認（UAC）は出ないはず
   - 最後の表に `UniGetUI` と `Devolutions.UniGetUI` の行が出ればよい（版は実行した日の最新。2026-10-03 は 2026.3.0）
   - デスクトップに UniGetUI のショートカットができる（手順 38 で消す）

   <details>
   <summary>補足: 入れ方と入る場所</summary>

   - `Devolutions.UniGetUI` は、UniGet UI の公式の README が最初に挙げる入れ方（UniGet UI は Devolutions 社に移った。もとの `MartiCliment.UniGetUI` ではない）
   - winget の定義では、`--scope user` のときに Inno Setup のインストーラへ `/CURRENTUSER /NoWinGet /NoAutoStart` を渡す（自分のユーザーに入れる、winget を入れ直さない、入れた後に起動しない）。インストーラは `cdn.devolutions.net` から取り、sha256 を winget が確かめる（[付録](#付録-配布物と資料の調査2026-10-03)）
   - 入る場所は `%LOCALAPPDATA%\Programs\UniGetUI`、設定は `%LOCALAPPDATA%\UniGetUI`（ソースのインストーラの定義と `CoreData.cs` から。確かめていない）
   - スタートメニューとデスクトップにショートカットを作る。winget の定義はデスクトップのショートカットを止めるスイッチ（`/NoDesktopShortcut`）を渡さない
   - `--accept-source-agreements` と `--accept-package-agreements` は、winget を初めて使う PC で出る同意の問いに答えるため（続けて貼った行が答えとして食われないように）
   - scoop-search は、UniGet UI が scoop のパッケージを検索するのに使う道具（ソースの `Scoop.cs` が「検索に要る」とする依存）。無いと、UniGet UI が起動したときに入れるかを聞く。ここで先に入れておく
   - scoop の `extras/unigetui` を採らなかった理由は、[選択した方針](#選択した方針)

   </details>

1. PowerToys を、自分のユーザーに入れる。

   ```powershell
   winget install --exact --id Microsoft.PowerToys --source winget --scope user --accept-source-agreements --accept-package-agreements
   winget list --exact --id Microsoft.PowerToys
   ```

   - 最後の表に `PowerToys` と `Microsoft.PowerToys` の行が出ればよい（版は実行した日の最新。2026-10-03 の定義は 0.101.2362.0）
   - 管理者の確認（UAC）は出ないはず
   - Caps Lock は、PowerToys の Keyboard Manager ではなく、手順 39 の Scancode Map で変える（[選択した方針](#選択した方針)）

   <details>
   <summary>補足: 入れ方と入る場所</summary>

   - winget の定義（`Microsoft.PowerToys` 0.101.2362.0）には、自分のユーザーに入れるインストーラ（`PowerToysUserSetup-<版>-x64.exe`。管理者の確認の指定が無い）と、PC 全体に入れるインストーラ（`PowerToysSetup-<版>-x64.exe`。`elevatesSelf`）がある。`--scope user` を付けて、自分のユーザーのほうを選ばせる
   - インストーラの形式は WiX の Burn で、winget は `/quiet /norestart` を渡す
   - 入る場所は、Microsoft の文書では自分のユーザーなら `%USERPROFILE%\AppData\Local\Programs` の下（下のフォルダーの名前は書かれていない）
   - PowerToys のいくつかの機能は、PowerToys を管理者として動かしていないと、管理者の窓には効かない（PowerToys の設定の「常に管理者として実行」）
   - WebView2 のランタイムが無ければ一緒に入れる（Windows 11 には最初からある）

   </details>

1. PowerShell 7 を、自分のユーザーに入れる。

   ```powershell
   winget install --exact --id Microsoft.PowerShell --source winget --accept-source-agreements --accept-package-agreements
   winget list --exact --id Microsoft.PowerShell
   ```

   - 最後の表に `PowerShell` と `Microsoft.PowerShell` の行が出ればよい（版は実行した日の最新。2026-10-03 の定義は 7.6.6.0）
   - 管理者の確認（UAC）は出ないはず（MSIX のパッケージで、自分のユーザーに入る）
   - スタートメニューに「PowerShell 7」ができる。この文書とほかの手順書のブロックは、引き続き Windows PowerShell 5.1 に貼る

   <details>
   <summary>補足: MSIX と MSI</summary>

   - Microsoft の文書は、winget のパッケージは 7.6.0 から既定で MSIX を入れると書いている。winget の定義（`Microsoft.PowerShell` 7.6.6.0）も、MSIX（自分のユーザー）を先に、MSI（PC 全体。`elevatesSelf`）を後に並べている
   - MSIX は自分のユーザーだけに入り、更新は winget かストアで行う。PC 全体の実行ポリシーやリモートの受け口は設定できない（Microsoft の文書）。このリポジトリの使い方では足りる
   - PC 全体の MSI（`$Env:ProgramFiles\PowerShell\7`、Microsoft Update で更新）にするなら `--installer-type wix` を付ける。ただし Microsoft の文書では、7.7.0 から MSI は無くなる
   - PowerShell 7.6.6 の PSReadLine 2.4.5 も、Ctrl+Enter は `InsertLineAbove`。PowerShell 7 の窓に右クリックで貼ると、同じように逆順になるはず（手順 7 は PowerShell 7 のプロファイルには書かない。[注意点](#注意点)）

   </details>

1. エクスプローラーで、拡張子と隠しファイルを表示し、「PC」で開き、最近使ったものを出さないようにする。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   $exp = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
   Set-ItemProperty -Path $adv -Name HideFileExt -Type DWord -Value 0
   Set-ItemProperty -Path $adv -Name Hidden -Type DWord -Value 1
   Set-ItemProperty -Path $adv -Name LaunchTo -Type DWord -Value 1
   Set-ItemProperty -Path $adv -Name Start_TrackDocs -Type DWord -Value 0
   Set-ItemProperty -Path $exp -Name ShowRecent -Type DWord -Value 0
   Set-ItemProperty -Path $exp -Name ShowFrequent -Type DWord -Value 0
   Get-ItemProperty -Path $adv | Format-List HideFileExt, Hidden, LaunchTo, Start_TrackDocs
   Get-ItemProperty -Path $exp | Format-List ShowRecent, ShowFrequent
   ```

   - `HideFileExt : 0`・`Hidden : 1`・`LaunchTo : 1`・`Start_TrackDocs : 0`・`ShowRecent : 0`・`ShowFrequent : 0` が出ればよい
   - 開いているエクスプローラーの窓には、開き直すか手順 43 の再起動の後に効く

   <details>
   <summary>補足: 値の意味</summary>

   - `Explorer\Advanced` の値（フォルダー オプションの「表示」タブと、設定の「個人用設定」→「スタート」に当たる）
     - `HideFileExt` が 0: 「登録されている拡張子は表示しない」を外す（既定は 1）
     - `Hidden` が 1: 隠しファイルを表示する（隠すときの値は 2）
     - `LaunchTo` が 1: エクスプローラーを「PC」で開く（2 か値が無いと「ホーム」）
     - `Start_TrackDocs` が 0: 設定の「スタート、エクスプローラーのおすすめのファイル、最近使ったファイル、ジャンプ リストの項目を表示する」を切る（既定は 1）。Microsoft の文書（Windows のコンポーネントから Microsoft のサービスへの接続を管理する）に、この値を 0 にすると書いてある。ジャンプ リストも空になる
   - `Explorer` の値（フォルダー オプションの「全般」タブの「プライバシー」に当たる）: `ShowRecent` が 0 で「最近使用したファイルを表示する」、`ShowFrequent` が 0 で「よく使うフォルダーを表示する」を切る
   - `HideFileExt`・`Hidden`・`Start_TrackDocs` は、Microsoft が出している DSC のリソース（`microsoft/winget-dsc` の `Microsoft.Windows.Developer`）が同じ値を書く。`LaunchTo`・`ShowRecent`・`ShowFrequent` は Microsoft の文書には無く、広く使われている値（[付録](#付録-windows-11-の設定の調査2026-10-03)）
   - 同じことは、設定の「システム」→「開発者向け」→「エクスプローラー」と、フォルダー オプションの画面からもできる

   </details>

1. 自分のユーザーで、旧形式のコンテキストメニューを出すようにする。

   ```powershell
   reg.exe add 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /f /ve
   reg.exe query 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /ve
   ```

   - `reg.exe add` が成功の 1 行を出し、`reg.exe query` に `(既定)`（英語の表示では `(Default)`）と `REG_SZ` の行が出ればよい（値は空）
   - エクスプローラーに効くのは、手順 43 の再起動の後

   <details>
   <summary>補足: この設定の仕組み</summary>

   - Windows 11 のエクスプローラーは、右クリックで新しい形のメニューを出し、その中の「その他のオプションを確認」（Shift+F10 か Shift+右クリックでも）で旧形式のメニューを出す
   - 新しい形のメニューは、CLSID `{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}` の COM のクラスが出している。自分のユーザーの `HKCU\Software\Classes\CLSID` に同じ CLSID の `InprocServer32` を空の既定の値で置くと、そのクラスを読めなくなり、エクスプローラーは最初から旧形式のメニューを出す
   - Microsoft が説明している設定ではない（サポート外）。広く使われている方法で、25H2 でも効くという記事が複数ある（本書では確かめていない）
   - 自分のユーザーだけにかかり、管理者の権限は要らない。消せば元に戻る（[ロールバック](#ロールバック)の手順 2）
   - PowerShell の `New-Item -Force` で作らず `reg.exe` を使うのは、`New-Item -Force` が既にあるキーを作り直して中の値を消すため。`reg.exe add /f /ve` は既定の値だけを書く

   </details>

1. スタートと設定の、おすすめ・提案・ヒントを切る。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
   $upe = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement'
   Set-ItemProperty -Path $adv -Name Start_IrisRecommendations -Type DWord -Value 0
   Set-ItemProperty -Path $adv -Name Start_AccountNotifications -Type DWord -Value 0
   foreach ($n in 'SubscribedContent-338393Enabled', 'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled', 'SubscribedContent-338389Enabled', 'SubscribedContent-310093Enabled', 'SubscribedContent-338388Enabled', 'SystemPaneSuggestionsEnabled', 'SilentInstalledAppsEnabled') { Set-ItemProperty -Path $cdm -Name $n -Type DWord -Value 0 }
   if (-not (Test-Path -LiteralPath $upe)) { New-Item -Path $upe | Out-Null }
   Set-ItemProperty -Path $upe -Name ScoobeSystemSettingEnabled -Type DWord -Value 0
   Get-ItemProperty -Path $adv | Format-List Start_IrisRecommendations, Start_AccountNotifications
   Get-ItemProperty -Path $cdm | Format-List SubscribedContent-338393Enabled, SubscribedContent-353694Enabled, SubscribedContent-353696Enabled, SubscribedContent-338389Enabled, SubscribedContent-310093Enabled, SubscribedContent-338388Enabled, SystemPaneSuggestionsEnabled, SilentInstalledAppsEnabled
   Get-ItemProperty -Path $upe | Format-List ScoobeSystemSettingEnabled
   ```

   - 並んだ値がすべて `0` ならよい
   - 外したアプリが戻らないように、手順 21 より前に貼る（`SilentInstalledAppsEnabled`）
   - スタートの検索の Web（Bing）の結果は、管理者の権限が要るので、手順 37 で切る

   <details>
   <summary>補足: 値と設定の画面の対応</summary>

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

   </details>

1. タスクバーを左に寄せ、タスク ビューと検索のボタンを消し、時計に秒を出す。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   Set-ItemProperty -Path $adv -Name TaskbarAl -Type DWord -Value 0
   Set-ItemProperty -Path $adv -Name ShowTaskViewButton -Type DWord -Value 0
   Set-ItemProperty -Path $adv -Name ShowSecondsInSystemClock -Type DWord -Value 1
   Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name SearchboxTaskbarMode -Type DWord -Value 0
   Get-ItemProperty -Path $adv | Format-List TaskbarAl, ShowTaskViewButton, ShowSecondsInSystemClock
   Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' | Format-List SearchboxTaskbarMode
   ```

   - `TaskbarAl : 0`・`ShowTaskViewButton : 0`・`ShowSecondsInSystemClock : 1`・`SearchboxTaskbarMode : 0` が出ればよい
   - タスクバーには、すぐか、手順 43 の再起動の後に効く
   - ウィジェットのボタンは、手順 22 でウィジェットを外すと消える（この手順では書けない）

   <details>
   <summary>補足: 値の意味とウィジェットのボタン</summary>

   - `TaskbarAl`: 0 で左、1（か値が無い）で中央
   - `ShowTaskViewButton`: 0 でタスク ビューのボタンを消す
   - `ShowSecondsInSystemClock`: 1 で時計に秒を出す（22H2 の 2023 年 5 月の更新から。設定の「個人用設定」→「タスク バー」→「タスク バーの動作」の「システム トレイの時計に秒を表示する」）
   - `SearchboxTaskbarMode`（`Explorer\Advanced` ではなく `Search` の下）: 0 で消す、1 でアイコンだけ、2 で検索ボックス、3 でアイコンとラベル。スタートを開いて文字を打てば、検索はそのまま使える
   - 4 つとも、Microsoft の DSC のリソース（`Microsoft.Windows.Developer` の `Taskbar`）が同じ値を書く。同じリソースはこの 4 つでエクスプローラーを起動し直さないので、タスクバーはすぐに読み直すはず（確かめていない）
   - ウィジェットのボタンの値（`TaskbarDa`）は、24H2 から UCPD（ユーザーの選択を守るドライバー）が守っていて、PowerShell・`reg.exe` からは書けない（「アクセスが拒否されました」になると広く報告されている）。設定の画面（「個人用設定」→「タスク バー」→「ウィジェット」）からは切れる。本書は、手順 22 でウィジェットそのものを外す

   </details>

1. ダークモードにする。

   ```powershell
   $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
   Set-ItemProperty -Path $p -Name AppsUseLightTheme -Type DWord -Value 0
   Set-ItemProperty -Path $p -Name SystemUsesLightTheme -Type DWord -Value 0
   Get-ItemProperty -Path $p | Format-List AppsUseLightTheme, SystemUsesLightTheme
   ```

   - `AppsUseLightTheme : 0` と `SystemUsesLightTheme : 0` が出ればよい
   - 動いているアプリとタスクバーには、手順 43 の再起動の後に効く（設定の「個人用設定」→「色」から変えると、すぐに効く）

   <details>
   <summary>補足: 値の意味</summary>

   - `AppsUseLightTheme` はアプリ、`SystemUsesLightTheme` はタスクバー・スタート・通知の色。0 で濃色、1 で淡色（Windows 11 の既定）
   - Microsoft の DSC のリソース（`Microsoft.Windows.Settings`）も同じ 2 つを書き、すぐに効かせるために `WM_SETTINGCHANGE`（`ImmersiveColorSet`）を全部の窓に送る。本書は、手順 43 で再起動するので送らない

   </details>

1. 既定の端末を Windows Terminal にする。

   ```powershell
   $p = 'HKCU:\Console\%%Startup'
   if (-not (Test-Path -LiteralPath $p)) { New-Item -Path $p | Out-Null }
   Set-ItemProperty -LiteralPath $p -Name DelegationConsole -Type String -Value '{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}'
   Set-ItemProperty -LiteralPath $p -Name DelegationTerminal -Type String -Value '{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}'
   Get-ItemProperty -LiteralPath $p | Format-List DelegationConsole, DelegationTerminal
   ```

   - `DelegationConsole : {2EACA947-…}` と `DelegationTerminal : {E12CFF52-…}` が出ればよい
   - 次に起動したコンソールのアプリから効く
   - **注意**: 管理者として開いた PowerShell は、この設定でも conhost の窓で開く（Windows Terminal の側の制限）。手順 23 の管理者の窓に右クリックで貼れるのは、手順 4〜7 の設定による

   <details>
   <summary>補足: 値と、管理者の窓が conhost になる理由</summary>

   - 値は、Windows Terminal の文書（グループ ポリシーの「既定のターミナル アプリケーション」）にある GUID。Windows Terminal は `DelegationConsole` が `{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}`、`DelegationTerminal` が `{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}`
   - Windows 11 22H2 以降の既定は「Windows に任せる」（2 つとも `{00000000-0000-0000-0000-000000000000}`）で、Windows Terminal が入っていればそれを使う（Microsoft のサポートの記事）。この手順は、それを Windows Terminal に決める
   - 管理者として起動したコンソールは、既定の端末に引き渡されず、conhost で開く。Windows Terminal の課題（microsoft/terminal の #13392。「管理者のコマンド ラインの受け手として登録できる端末は無く、COM の側の対応が要る」）が開いたまま。管理者の Windows Terminal は、Win+X の「ターミナル (管理者)」で開ける
   - 設定の「システム」→「開発者向け」→「ターミナル」と、Windows Terminal の設定の「スタートアップ」→「既定のターミナル アプリケーション」でも変えられる

   </details>

1. Microsoft IME の設定を開き、Ctrl+Space で IME をオン・オフするようにする。

   ```powershell
   Start-Process 'ms-settings:regionlanguage-jpnime'
   ```

   - 設定の Microsoft IME の画面が開く。「キーとタッチのカスタマイズ」を開き、「キーの割り当て」をオンにして、「Ctrl + Space」を「IME-オン/オフ」にする（画面の文言は確かめていない）
   - 「以前のバージョンの Microsoft IME を使う」がオンだと、この項目は出ない
   - 効くのは、次に IME を使う窓から（確かめるのは手順 44）
   - **次の手順は、設定を閉じてから PowerShell に貼る**

   <details>
   <summary>補足: レジストリに書かない理由と、Ctrl+Space の取り合い</summary>

   - この設定のレジストリの値は、Microsoft の文書に無い。ある開発者が設定の画面の前後で見比べた記録（`HKCU\Software\Microsoft\IME\15.0\IMEJP\MSIME` の `IsKeyAssignmentEnabled` を 1、`KeyAssignmentCtrlSpace` を 2）はあるが、同じ人が「動いている IME に効く時期が保証されない」として書くのを避けている。本書も画面で変える
   - 割り当てられるキーは、無変換・変換・Ctrl+Space・Shift+Space。Ctrl+Space には、最初は何も割り当てられていない
   - Windows が Ctrl+Space を使うのは、中国語の IME のオン・オフだけ（Microsoft のキーボード ショートカットの文書）。日本語だけの PC では、Windows の操作とはぶつからない
   - IME が Ctrl+Space を取るので、アプリの Ctrl+Space は効かなくなるはず（PowerShell の PSReadLine の `MenuComplete`、VS Code の候補の表示、Excel の列の選択など。確かめていない）
   - 英数と日本語の切り替えの既定の Win+Space（入力言語の切り替え）と、半角/全角のキーはそのまま使える

   </details>

1. 自動で起動するアプリのうち、OneDrive・Edge・Teams を止める。

   ```powershell
   & {
     $run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
     $ok = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
     if (-not (Test-Path -LiteralPath $ok)) { New-Item -Path $ok -Force | Out-Null }
     $names = (Get-Item -LiteralPath $run).Property | Where-Object { $_ -eq 'OneDrive' -or $_ -like 'MicrosoftEdgeAutoLaunch_*' }
     foreach ($n in $names) {
       Set-ItemProperty -LiteralPath $ok -Name $n -Type Binary -Value ([byte[]](3, 0, 0, 0) + [BitConverter]::GetBytes((Get-Date).ToFileTime()))
       "止めた: $n"
     }
     $teams = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe\TeamsTfwStartupTask'
     if (Test-Path -LiteralPath $teams) { Set-ItemProperty -LiteralPath $teams -Name State -Type DWord -Value 1; '止めた: Teams' }
     (Get-Item -LiteralPath $run).Property | ForEach-Object { $b = (Get-ItemProperty -LiteralPath $ok -ErrorAction SilentlyContinue).$_; '{0}: {1}' -f $_, $(if ($b -and $b[0] -ne 2) { '止めている' } else { '起動する' }) }
   }
   ```

   - `止めた: OneDrive` などと、`Run` にあるアプリごとに `止めている` か `起動する` が出ればよい
   - 無いものは何もしない（Edge の行は、Edge の設定によっては無い）
   - `WingetUI: 起動する` は UniGet UI（更新を知らせるために起動する）。止めるなら、タスク マネージャーの「スタートアップ アプリ」で無効にする
   - 効くのは、次のサインインから

   <details>
   <summary>補足: タスク マネージャーと同じ所に書く</summary>

   - タスク マネージャーの「スタートアップ アプリ」と設定の「アプリ」→「スタートアップ」は、`Run` の値を消さずに、`Explorer\StartupApproved\Run` に同じ名前の値（バイナリ）を書く。先頭の 1 バイトが 2 なら起動し、3（と、止めた日時の 8 バイト）なら止める。Microsoft の文書には無いが、広く知られた形（UniGet UI のインストーラも同じ所に書く）
   - OneDrive の値の名前は `OneDrive`、Edge は `MicrosoftEdgeAutoLaunch_<文字列>`。OneDrive は OneDrive の設定の「Windows にサインインしたときに OneDrive を自動的に開始する」でも止められる
   - Teams（新しい Teams。手順 21 で外す）はパッケージのアプリで、起動のタスク `TeamsTfwStartupTask` の `State` を 1（「ユーザーが無効にした」）にする。値の意味は Microsoft の文書（`StartupTaskState`）にある
   - 消すのではなく止めるので、タスク マネージャーからいつでも戻せる（[ロールバック](#ロールバック)の手順 8）

   </details>

1. 要らない標準アプリを、自分のユーザーから外す。

   ```powershell
   foreach ($n in 'Clipchamp.Clipchamp', 'Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.Todos', 'Microsoft.WindowsFeedbackHub', 'Microsoft.GetHelp', 'Microsoft.OutlookForWindows', 'MSTeams', 'Microsoft.PowerAutomateDesktop') {
     $p = Get-AppxPackage -Name $n
     if ($p) { $p | Remove-AppxPackage; "外した: $n" } else { "無い: $n" }
   }
   ```

   - 11 個のアプリごとに `外した:` か `無い:` が出ればよい
   - 赤い字のエラーが出たアプリは、外せなかった（動いていれば閉じて貼り直す）
   - Copilot（`Microsoft.Copilot`）は外さない。`Microsoft.MicrosoftOfficeHub` はストアの名前が「Microsoft 365 Copilot」になった別のアプリ（Office の入口）
   - 機能の更新（Windows の大きな更新）の後に、戻ってくることがある。そのときはこの手順を貼り直す

   <details>
   <summary>補足: 外すアプリと、戻ってくること</summary>

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
   - 戻すときは、[ロールバック](#ロールバック)の手順 9 で、ストアの ID を指定して winget で入れる

   </details>

1. ウィジェット（Windows Web Experience Pack）を外す。

   ```powershell
   $p = Get-AppxPackage -Name MicrosoftWindows.Client.WebExperience
   if ($p) { $p | Remove-AppxPackage; '外した: MicrosoftWindows.Client.WebExperience' } else { '無い: MicrosoftWindows.Client.WebExperience' }
   ```

   - `外した:` か `無い:` が出ればよい
   - タスクバーのウィジェットのボタンと、設定のウィジェットの切り替えが消える（手順 43 の再起動の後に確かめる）

   <details>
   <summary>補足: ウィジェットを外すこと</summary>

   - ウィジェットの本体は、ストアのアプリ「Windows Web Experience Pack」（`MicrosoftWindows.Client.WebExperience`、ストアの ID は `9MSSGKG348SP`）。外すとボタンも消えると広く報告されている（Microsoft の文書には無い）
   - ボタンだけを消す値（`TaskbarDa`）は、PowerShell からは書けない（手順 16 の補足）
   - Microsoft が説明している止め方は、管理者のポリシー（「ウィジェットを許可する」）。本書では使わない

   </details>

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く。UAC の確認が出たら「はい」
   - 手順 3 の PowerShell は閉じてよい（再起動の後は、手順 48 で開き直す）
   - この窓は、手順 7 でプロファイルに書いた行を読む（手順 25 で確かめる）
   - 開いたときに、プロファイルを読めないという赤い字のエラーが出たら、実行ポリシーが `Restricted` のまま。手順 6 を、この窓で貼り直す

1. 変数を設定する（PC の名前を変えるなら、`PC_NAME` に値を入れる）。

   ```powershell
   $PC_NAME = ''   # この PC の新しい名前（15 文字まで。英字・数字・ハイフン）。<HOSTNAME>
   ```

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # ほかの PC とつながる LAN の接続（自動）。<LAN_IF>
   'PC_NAME = {0}' -f $PC_NAME
   'LAN_IF  = {0}' -f $LAN_IF
   ```

   - 最後に値を読み戻して確かめる
   - `PC_NAME` は、SSH・リモート デスクトップ・Syncthing などで、この PC を見分ける名前。名前を変えないなら、空のままにして手順 27 を飛ばす
   - `LAN_IF` は、インターネットにつながっている接続の名前（`イーサネット`、`Wi-Fi` など）。ほかの PC とつながる接続と違えば、`$LAN_IF = 'Wi-Fi'` のように直す
   - 変数はその PowerShell の中だけで有効。**新しい PowerShell を開いたら**、手順 24 のブロックを貼り直してから先へ進む

   <details>
   <summary>補足: 変数について</summary>

   - `$PC_NAME` は手順 27（PC の名前を変える）で使う
   - `$LAN_IF` は、手順 25（今の状態）・手順 30（アダプターの省電力）・手順 31（プライベートにする）で使う。式は [Windows の OpenSSH サーバー](windows-openssh-server.md)の手順 2 と同じ
   - 接続の一覧は `Get-NetConnectionProfile` で見られる。[Windows の OpenSSH サーバー](windows-openssh-server.md)の検証の PC では、WSL を動かしていても `vEthernet (WSL (Hyper-V firewall))` は一覧に出ず、有線 LAN の 1 行だけだった

   </details>

1. 管理者であることと、プロファイルの行が効いていることと、今の値を確かめる。

   ```powershell
   $cv = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
   [pscustomobject]@{
     Admin            = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     CtrlEnter        = (Get-PSReadLineKeyHandler -Bound | Where-Object Key -eq 'Ctrl+Enter').Function
     Edition          = $cv.EditionID
     Version          = '{0}（{1}.{2}）' -f $cv.DisplayVersion, $cv.CurrentBuild, $cv.UBR
     ComputerName     = $env:COMPUTERNAME
     LanCategory      = if ($LAN_IF) { (Get-NetConnectionProfile -InterfaceAlias $LAN_IF).NetworkCategory } else { '' }
     RemoteDesktop    = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
     RemoteAssistance = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' -ErrorAction SilentlyContinue).fAllowToGetHelp
     HelloOnly        = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' -ErrorAction SilentlyContinue).DevicePasswordLessBuildVersion
     Keyboard         = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters' -ErrorAction SilentlyContinue).'LayerDriver JPN'
     Sudo             = (Get-Command sudo -ErrorAction SilentlyContinue).Source
     Hypervisor       = (Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
   } | Format-List
   Get-DODownloadMode
   ```

   - `Admin : True` と `CtrlEnter : AddLine` が出ればよい
   - `Admin` が `False` なら、管理者ではない窓に貼っている。手順 23 から
   - `CtrlEnter` が `InsertLineAbove` なら、この窓はプロファイルを読んでいない。手順 4・6・7 をこの窓で貼り直してから（手順 4 を先に貼ると、手順 6・7 を右クリックで貼れる）、窓を開き直して手順 24 から
   - `Version` が 24H2（ビルド 26100）より前で `Sudo` が空なら、手順 28 の sudo の行は何もしない
   - 次の値を控える（[ロールバック](#ロールバック)で、元に戻すかを決めるのに使う）
     - `ComputerName`（PC の名前。ロールバックの手順 37）と `LanCategory`（LAN の種類。ロールバックの手順 33）
     - `RemoteDesktop`（1 なら無効、0 ならもう有効。ロールバックの手順 32）と `RemoteAssistance`（1 なら有効、0 なら無効。ロールバックの手順 31）
     - `HelloOnly`（2 ならオン、0 ならオフ。ロールバックの手順 22）と `Keyboard`（`kbd106.dll` なら JIS 配列。ロールバックの手順 26）
     - 最後の行の配信の最適化のモード（`Lan` が Windows の既定。ロールバックの手順 29）
   - `Hypervisor : True` なら、Hyper-V がもう動いている（[VirtualBox の Windows 11 の節](virtualbox.md#windows-11-で使う)の VM は、その上で動く）
   - `Edition` が `Core` で始まる（Home）なら、手順 32 は飛ばす

   <details>
   <summary>補足: 見ているもの</summary>

   - `CtrlEnter` は、この窓の PSReadLine の Ctrl+Enter の働き。手順 7 のプロファイルを読んでいれば `AddLine`、読んでいなければ既定の `InsertLineAbove`
   - `Edition` は `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion` の `EditionID`。`Core`・`CoreN`・`CoreSingleLanguage`・`CoreCountrySpecific` が Home、`Professional` などが Pro。Microsoft の文書では、Home はリモート デスクトップでつながれる側になれない
   - `Sudo` は、Windows に入っている `sudo.exe` の場所。Microsoft の文書では、sudo は 24H2 以降
   - `Hypervisor` は、Windows のハイパーバイザー（Hyper-V）が動いているか。WSL 2（手順 42）・メモリ整合性・Credential Guard などで動く
   - `Get-DODownloadMode` は、配信の最適化のモード（`CdnOnly`・`Lan`・`Internet` など）

   </details>

1. 複数行のブロックをコピーボタンでコピーして右クリックで貼り、元の順に動くことを確かめる。

   ```powershell
   & {
     '1 行目'
     '2 行目'
     '3 行目'
   }
   ```

   - このブロックを GitHub のコピーボタンでコピーし、手順 23 の窓の中で右クリックして貼る
   - 最後の `}` の行で止まるので、Enter を押す
   - `1 行目`・`2 行目`・`3 行目` の順に出ればよい

1. PC の名前を変えるときだけ、名前を変える（効くのは再起動の後）。

   ```powershell
   if (-not $PC_NAME) {
     Write-Error '中断: 手順 24 の $PC_NAME が空'
   } elseif ($PC_NAME -notmatch '^[A-Za-z0-9]([A-Za-z0-9-]{0,13}[A-Za-z0-9])?$' -or $PC_NAME -match '^[0-9]+$') {
     Write-Error "中断: 使えない名前（15 文字まで。英字・数字・ハイフンで、先頭と末尾は英数字。数字だけは不可）: $PC_NAME"
   } elseif ($PC_NAME -eq $env:COMPUTERNAME) {
     "すでにこの名前: $PC_NAME"
   } else {
     Rename-Computer -NewName $PC_NAME
     "再起動の後に $PC_NAME になる"
   }
   ```

   - 再起動を求める旨の警告と、`再起動の後に <HOSTNAME> になる` が出ればよい
   - 何度貼ってもよい（2 回目からは `すでにこの名前:`。再起動の前は、まだ古い名前と比べる）
   - 効くのは、手順 43 の再起動の後
   - 名前を変えないなら（手順 24 の `PC_NAME` が空なら）、この手順は飛ばす

   <details>
   <summary>補足: 名前の決まりと、確認の問いを出さないこと</summary>

   - Windows の PC の名前は 15 文字まで（NetBIOS の名前の長さ）で、使える文字は英字・数字・ハイフン。先頭は英数字で、末尾はハイフンにしない（Microsoft の文書。数字だけの名前はドメインに入れない）
   - `Rename-Computer` は、15 文字を超える名前だと「短くするが続けるか」を聞く（`-Force` で聞かない）。聞かれると、続けて貼った行が答えとして食われるので、ブロックで先に 15 文字までかを確かめて止める
   - 今と同じ名前を渡すと、`Rename-Computer` はエラー（`NewNameIsOldName`）を出すので、先に比べる
   - SSH・リモート デスクトップ・Syncthing は、この名前でこの PC を見分ける。Syncthing のデバイスの名前は最初の起動のときの PC の名前になるので、Syncthing より先に変える

   </details>

1. 長いパス・開発者モード・sudo（今の窓で動く形）を有効にする。

   ```powershell
   $dev = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -Type DWord -Value 1
   if (-not (Test-Path -LiteralPath $dev)) { New-Item -Path $dev | Out-Null }
   Set-ItemProperty -Path $dev -Name AllowDevelopmentWithoutDevLicense -Type DWord -Value 1
   if (Get-Command sudo -ErrorAction SilentlyContinue) { sudo config --enable normal } else { 'sudo が無い（24H2 より前の Windows）' }
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' | Format-List LongPathsEnabled
   Get-ItemProperty -Path $dev | Format-List AllowDevelopmentWithoutDevLicense
   ```

   - `LongPathsEnabled : 1` と `AllowDevelopmentWithoutDevLicense : 1` が出ればよい
   - sudo は、今の窓で動く形（インライン）になった旨の英語の行を出す
   - 管理者ではない窓で `sudo <コマンド>` を打つと、UAC の確認の後に、同じ窓でそのコマンドが管理者の権限で動く
   - **注意**: インラインの sudo は、同じ窓のほかの（管理者でない）プロセスから、管理者のコマンドに入力を送れる形（Microsoft の文書。この手順の補足）

   <details>
   <summary>補足: 3 つの設定</summary>

   - **長いパス**: `HKLM\SYSTEM\CurrentControlSet\Control\FileSystem` の `LongPathsEnabled` を 1 にすると、260 文字を超えるパスを、それを宣言したアプリ（マニフェストの `longPathAware`）が使える（Microsoft の文書）。エクスプローラーなど、宣言していないアプリは変わらない。プロセスが最初に使うときに読むので、効くのは手順 43 の再起動の後。Git for Windows には別に `core.longpaths` がある
   - **開発者モード**: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock` の `AllowDevelopmentWithoutDevLicense` を 1（Microsoft の文書の `reg add` と同じ値）。管理者でなくてもシンボリック リンクを作れる（`mklink` や Git for Windows のように、作る側がその印を渡すとき）。Microsoft の文書では、レジストリで有効にしても、設定の画面で有効にしたときと違い、デバイスのポータルなどは入らない
   - **sudo**: Windows 11 24H2 から Windows に入っている `sudo.exe`。`sudo config --enable` の形は 3 つ（Microsoft の文書）
     - `forceNewWindow`（既定）: 管理者のコマンドを新しい窓で動かす。Microsoft が勧める形
     - `disableInput`: 今の窓に出すが、入力を受け付けない
     - `normal`（インライン）: 今の窓で入出力する。Linux の sudo に近い。同じ窓のほかのプロセスが、管理者のプロセスを操作できるおそれがあると Microsoft は書いている
     - 利用者の選択で `normal` にした。値は `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo` の `Enabled`（0 が無効、1〜3 が上の順。microsoft/sudo のソース）
   - 3 つとも、設定の「システム」→「開発者向け」（25H2 では「システム」→「詳細設定」）でも変えられる

   </details>

1. 電源につないでいる間は眠らず、休止状態を切り、蓋を閉じても何もせず、放置してもロックしないようにする。

   ```powershell
   powercfg /change standby-timeout-ac 0
   powercfg /hibernate off
   powercfg /setacvalueindex SCHEME_CURRENT SUB_BUTTONS LIDACTION 0
   powercfg /setacvalueindex SCHEME_CURRENT SUB_NONE CONSOLELOCK 0
   powercfg /setactive SCHEME_CURRENT
   Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name DelayLockInterval -Type DWord -Value 0xFFFFFFFF
   foreach ($s in 'SUB_SLEEP STANDBYIDLE', 'SUB_BUTTONS LIDACTION', 'SUB_NONE CONSOLELOCK') { '{0}: {1}' -f $s, ((powercfg /q SCHEME_CURRENT $s.Split(' ')) | Select-String -Pattern 'AC' | Select-Object -Last 1) }
   'HibernateEnabled: {0}' -f (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power').HibernateEnabled
   ```

   - 3 つの行の AC の値が `0x00000000` で、`HibernateEnabled: 0` が出ればよい（`powercfg` の表示は日本語）
   - 画面を消す時間は変えない（画面は消えるが、眠らず、ロックもしない）
   - バッテリーのときは変えない（眠り、蓋を閉じると眠る）
   - **注意**: PC の前にいる人は、このユーザーとしてそのまま使える（リードの `[!WARNING]`）

   <details>
   <summary>補足: どの設定で何が変わるか</summary>

   - `standby-timeout-ac 0`: 電源につないでいる間、放置しても眠らない（`SUB_SLEEP` の `STANDBYIDLE` を 0 にするのと同じ。Microsoft の文書）
   - `/hibernate off`: 休止状態を切り、`hiberfil.sys` を消す。高速スタートアップもこのファイルを使うので、使えなくなる（ハイブリッド スリープも）。Wake on LAN でシャットダウンから起こす（[任意節](#wake-on-lan-を使う任意)）には、高速スタートアップを切る必要がある
   - `LIDACTION` を 0: 電源につないでいる間、蓋を閉じても何もしない（1 が眠る、2 が休止状態、3 がシャットダウン）。`/setactive SCHEME_CURRENT` で、今の電源プランに効かせる
   - `CONSOLELOCK` を 0: 電源につないでいる間、眠りから戻ったときにサインインを求めない（既定は 1）。眠らないようにしても、手で眠らせたときのため
   - `DelayLockInterval` を `0xFFFFFFFF`: Modern Standby（S0）の PC で、画面が消えた後のロック（設定の「アカウント」→「サインイン オプション」の「一定時間不在にした場合、もう一度サインインを求めるタイミング」）を「しない」にする。この値は Microsoft の文書に無く、広く使われているもの。S3 の PC では、画面が消えるだけではロックしない（ロックするのは、眠り・パスワード付きのスクリーン セーバー・ポリシー・動的ロック）
   - Modern Standby の PC かは、`powercfg /a` に「スタンバイ (S0 低電力アイドル)」が出るかで分かる
   - 元に戻すのは[ロールバック](#ロールバック)の手順 35（電源プランを既定に戻す。ほかに変えた電源の設定も戻る）

   </details>

1. LAN のアダプターを、電力の節約のために止めないようにする。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '手順 24 の $LAN_IF が空'
   } else {
     $pm = Get-NetAdapterPowerManagement -Name $LAN_IF
     if ($pm.AllowComputerToTurnOffDevice -eq 'Unsupported') { "このアダプターは対象外: $LAN_IF" } else {
       $pm.AllowComputerToTurnOffDevice = 'Disabled'
       $pm | Set-NetAdapterPowerManagement -NoRestart
     }
     Get-NetAdapterPowerManagement -Name $LAN_IF | Format-List Name, AllowComputerToTurnOffDevice, WakeOnMagicPacket
   }
   ```

   - `AllowComputerToTurnOffDevice : Disabled` が出ればよい
   - `このアダプターは対象外:` なら、このアダプターには設定が無い（何もしない）
   - アダプターは起動し直さない（`-NoRestart`）。効くのは、手順 43 の再起動の後

   <details>
   <summary>補足: デバイス マネージャーの「電力の節約のために、コンピューターでこのデバイスの電源をオフにできるようにする」</summary>

   - この手順は、デバイス マネージャーのアダプターの「電源の管理」タブの、上の項目を外すのと同じ
   - `Set-NetAdapterPowerManagement` の文書にこの項目の引数は無く、`Get-NetAdapterPowerManagement` で取ったものの `AllowComputerToTurnOffDevice` を変えて渡す形は、広く使われているもの（Microsoft の文書には無い）
   - `Set-NetAdapterPowerManagement` は、`-NoRestart` が無いとアダプターを起動し直す（Microsoft の文書）。SSH・リモート デスクトップでつないでいると切れるので、付ける
   - この項目を外すと、Windows がアダプターに「この PC を起こす」を任せる設定（眠りからの Wake on LAN）も使えなくなる（Microsoft の古いサポートの記事）。シャットダウンからの Wake on LAN は UEFI とアダプターが行い、Windows は関わらないので、[任意節](#wake-on-lan-を使う任意)はこの手順と両立する
   - 元に戻すのは[ロールバック](#ロールバック)の手順 34

   </details>

1. LAN の接続をプライベートにする。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '手順 24 の $LAN_IF が空'
   } else {
     Set-NetConnectionProfile -InterfaceAlias $LAN_IF -NetworkCategory Private
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
   }
   ```

   - `<LAN_IF>  Private` が出ればよい
   - 既にプライベートなら、何も変わらない
   - **注意**: プライベート向けのほかの許可の規則（ネットワーク探索など）も、この LAN で効くようになる（この手順の補足）
   - [Windows の OpenSSH サーバー](windows-openssh-server.md)・[Syncthing の Windows 11 で使う](syncthing.md#windows-11-で使う)・手順 32〜34 は、この LAN がプライベートであることを前提にする

   <details>
   <summary>補足: プライベートにする理由</summary>

   - Windows のファイアウォールの受信の規則は、ネットワークの種類（プライベート・パブリック）ごとに有効にできる。OpenSSH サーバーの機能が作る規則も、Syncthing の Windows 11 の節で作る規則も、手順 32〜34 の規則も、プライベートだけで有効にする
   - Windows 11 は、新しくつないだネットワークをパブリックにすることがある。[Windows の OpenSSH サーバー](windows-openssh-server.md)を検証した PC の有線 LAN はパブリックで、そのままでは LAN からの SSH が捨てられ、プライベートにすると通った（同書の手順 5 の補足）
   - 同じ PC では、パブリックからプライベートにすると、それまで効いていなかった許可の規則 45 本がこの LAN で効くようになった。主なものは、ネットワーク探索（10 本）、リモート アシスタンス（4 本。手順 33 で切る）、デバイス キャスト機能（3 本）。ファイルとプリンターの共有は無効のままだった
   - この操作は、もとは Windows の OpenSSH サーバーの手順 5 と Syncthing の Windows 11 の手順 7 の両方にあった。2026-10-03 に、インストール直後の作業としてここへまとめた。ブロックは OpenSSH サーバーの手順 5（実機で通したもの）から、`Get-NetFirewallRule` の行を除いて移した（変数の手順の番号だけ変えた）
   - ノート PC を持ち出したとき: プライベートにしたのはこの接続（有線 LAN か、この Wi-Fi のネットワーク）だけ。出先の Wi-Fi は、つないだときにパブリックかプライベートかを選ぶ（既定はパブリック）

   </details>

1. Pro 以上のときだけ、リモート デスクトップを有効にし、受け付けるのをプライベートの LAN に絞る。

   ```powershell
   $ed = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').EditionID
   if ($ed -like 'Core*') { Write-Error "中断: Home（$ed）は、リモート デスクトップでつながれる側になれない" } else {
     Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Type DWord -Value 0
     Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Type DWord -Value 1
     Set-NetFirewallRule -Group '@FirewallAPI.dll,-28752' -Enabled True -Profile Private
     Get-NetFirewallRule -Group '@FirewallAPI.dll,-28752' | Format-Table Name, Enabled, Profile, Direction, Action
   }
   ```

   - `RemoteDesktop-UserMode-In-TCP` などの行が `True  Private  Inbound  Allow` で出ればよい
   - 手順 25 の `Edition` が `Core` で始まる（Home）なら、この手順は飛ばす（貼っても `中断:` で止まる）
   - つなぐのは、この PC にサインインするのと同じユーザーとパスワード（Microsoft アカウントなら、そのアカウントのパスワード。手順 36 も）
   - [RDP をロックせずに切断（Windows）](windows-rdp-disconnect.md)は、この手順を前提にする

   <details>
   <summary>補足: 有効にする値と、規則を絞ること</summary>

   - `fDenyTSConnections` を 0 にすると、リモート デスクトップの接続を受け付ける（1 が既定で、受け付けない）。`UserAuthentication` を 1 にすると、ネットワーク レベル認証（NLA）を求める（設定の画面で有効にしたときの既定）。どちらも Microsoft の文書（Azure の VM のリモート デスクトップの切り分け）にある値
   - 受信の規則は、表示の名前が日本語に訳されるので、Microsoft の勧める形（`@FirewallAPI.dll,-28752` のグループ）で指定する。規則の名前は `RemoteDesktop-UserMode-In-TCP`・`-UDP` など（3389 番）
   - `-Profile Private` で、プライベートの LAN（手順 31）からだけ受け付ける。持ち出した先のパブリックの Wi-Fi では開かない。[Windows の OpenSSH サーバー](windows-openssh-server.md)の検証の PC は、規則がすべてのプロファイルで有効だった
   - 設定の画面でリモート デスクトップをオンとオフにし直すと、規則のプロファイルが戻るかは確かめていない。画面で変えたら、この手順の最後の行で確かめ直す
   - 元に戻すのは[ロールバック](#ロールバック)の手順 32

   </details>

1. リモート アシスタンスを切る。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' -Name fAllowToGetHelp -Type DWord -Value 0
   Set-NetFirewallRule -Group '@FirewallAPI.dll,-33002' -Enabled False
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance' | Format-List fAllowToGetHelp
   Get-NetFirewallRule -Group '@FirewallAPI.dll,-33002' | Format-Table Name, Enabled, Profile
   ```

   - `fAllowToGetHelp : 0` と、リモート アシスタンスの規則が `False` で並べばよい
   - `Set-NetFirewallRule` が規則が見つからない旨のエラーを出したら、グループの ID が違う（この手順の補足）

   <details>
   <summary>補足: リモート アシスタンス</summary>

   - リモート アシスタンス（Windows の「クイック アシスト」とは別）は、ほかの人を招いて画面を見せる古い仕組み。システムのプロパティの「リモート」タブの「このコンピューターへのリモート アシスタンス接続を許可する」が `fAllowToGetHelp`
   - [Windows の OpenSSH サーバー](windows-openssh-server.md)の検証の PC では、LAN をプライベートにすると、リモート アシスタンスの受信の規則 4 本が効くようになった（手順 31 の補足）
   - グループの ID `@FirewallAPI.dll,-33002` は、Microsoft の文書には無い（Windows の `racpldlg.dll` の文字列にある）。違っていたら、`Get-NetFirewallRule | Sort-Object Group -Unique | Format-Table DisplayGroup, Group` で「リモート アシスタンス」の行の `Group` を見る
   - Microsoft の無人インストールの文書は、`fAllowToGetHelp` の既定を無効と書いているが、店頭の Windows では有効なことが多いと報告されている。手順 25 の `RemoteAssistance` で、元の値を控える
   - 元に戻すのは[ロールバック](#ロールバック)の手順 31

   </details>

1. プライベートの LAN からの ping（ICMP のエコー要求）に応える規則を作る。

   ```powershell
   $g = 'Ping (setup-notes)'
   Remove-NetFirewallRule -Group $g -ErrorAction SilentlyContinue
   New-NetFirewallRule -Name 'Ping-ICMPv4-In-setup-notes' -DisplayName 'Ping (ICMPv4 エコー要求)' -Group $g -Direction Inbound -Action Allow -Profile Private -Protocol ICMPv4 -IcmpType 8 | Out-Null
   New-NetFirewallRule -Name 'Ping-ICMPv6-In-setup-notes' -DisplayName 'Ping (ICMPv6 エコー要求)' -Group $g -Direction Inbound -Action Allow -Profile Private -Protocol ICMPv6 -IcmpType 128 | Out-Null
   Get-NetFirewallRule -Group $g | Format-Table Name, Enabled, Profile, Direction, Action
   ```

   - 2 つの規則が `True  Private  Inbound  Allow` で出ればよい
   - 何度貼ってもよい（規則は消してから作り直す）
   - LAN の別の PC から、この PC の IP アドレスへ ping が通るようになる

   <details>
   <summary>補足: 自分で規則を作る理由</summary>

   - Windows の既定では、ping（ICMPv4 の種類 8、ICMPv6 の種類 128）に応えない。組み込みの規則（「ファイルとプリンターの共有 (エコー要求 - ICMPv4 受信)」など）は無効で、「ファイルとプリンターの共有」の設定と一緒に変わる
   - その規則を使わず、名前とグループ（`Ping (setup-notes)`）の決まった規則を作る。ほかの設定とぶつからず、消すときも分かる（[Syncthing の Windows 11 の節](syncthing.md#windows-11-で使う)の規則と同じ形）
   - 接続元は絞らない（`Any`）。プロファイルで決まるので、プライベートの LAN を通って届く、別のサブネット（WireGuard のクライアントなど）からの ping にも応える
   - 元に戻すのは[ロールバック](#ロールバック)の手順 30

   </details>

1. 配信の最適化を、LAN の PC とだけ共有するようにする。

   ```powershell
   Set-DODownloadMode -DownloadMode Lan
   Get-DODownloadMode
   ```

   - `Lan` が出ればよい
   - Windows の既定も `Lan` なので、手順 25 で `Lan` だったなら何も変わらない

   <details>
   <summary>補足: 配信の最適化</summary>

   - 配信の最適化は、Windows Update とストアのアプリのファイルを、ほかの PC と分け合う仕組み。設定の「Windows Update」→「詳細オプション」→「配信の最適化」の「他のデバイスからのダウンロードを許可する」と同じ
   - `Lan` は同じ NAT の後ろ（同じ LAN）の PC とだけ、`Internet` はインターネットの PC とも、`CdnOnly` は分け合わない。Microsoft の文書の既定は `Lan`（ポリシーの文書は 0 = HTTP だけと書いていて、文書の間で食い違う）
   - `Set-DODownloadMode` は設定の画面と同じことをする（Microsoft の文書）。グループ ポリシーで決まっていると、そちらが優先される
   - 元に戻すのは[ロールバック](#ロールバック)の手順 29

   </details>

1. 「Windows Hello サインインのみを許可する」を切る。

   ```powershell
   $k = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -Path $k -Name DevicePasswordLessBuildVersion -Type DWord -Value 0
   Get-ItemProperty -Path $k | Format-List DevicePasswordLessBuildVersion
   ```

   - `DevicePasswordLessBuildVersion : 0` が出ればよい
   - サインインの画面で、PIN のほかにパスワードも選べるようになる

   <details>
   <summary>補足: この設定と、リモート デスクトップ・SSH・自動サインイン</summary>

   - 設定の「アカウント」→「サインイン オプション」の「セキュリティ向上のため、このデバイスでは Microsoft アカウント用に Windows Hello サインインのみを許可する」。値（2 がオン、0 がオフ）は Microsoft の文書に無く、広く使われているもの
   - オンだと、Microsoft アカウントのパスワードでのリモート デスクトップに入れない、という Microsoft Q&A の回答がある。[Windows の OpenSSH サーバー](windows-openssh-server.md#注意点)の検証の PC では、オンのまま SSH にパスワードで入れた（Q&A の報告とは違った）
   - オンだと、自動サインイン（手順 52）の設定に要る「ユーザーがこのコンピューターを使うには、ユーザー名とパスワードの入力が必要」の項目が隠れると報告されている
   - 元に戻すのは[ロールバック](#ロールバック)の手順 22

   </details>

1. スタートの検索で、Web（Bing）の結果を出さないようにする。

   ```powershell
   $k = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -Path $k -Name DisableSearchBoxSuggestions -Type DWord -Value 1
   Get-ItemProperty -Path $k | Format-List DisableSearchBoxSuggestions
   ```

   - `DisableSearchBoxSuggestions : 1` が出ればよい
   - 効くのは、手順 43 の再起動の後

   <details>
   <summary>補足: 管理者の窓で書く理由と、効き目</summary>

   - 自分のユーザーの設定（`HKCU`）だが、`HKCU\Software\Policies` の下は、管理者の権限が無いと書けない。管理者の窓も同じユーザーなので、自分の `HKCU` に書かれる
   - Microsoft の文書では、このポリシーは「エクスプローラーの検索ボックスに最近の検索の項目を出さない」。スタートの検索から Web の結果が消えることは、広く報告されているもの（24H2 でも効くという報告と、効かないことがあるという報告がある）
   - Windows 10 の `BingSearchEnabled` は、Windows 11 で効く根拠が見つからないので使わない
   - 元に戻すのは[ロールバック](#ロールバック)の手順 23

   </details>

1. デスクトップの Edge と UniGet UI のショートカットを消し、Edge が作り直したら消すようにする。

   ```powershell
   $k = 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate'
   if (-not (Test-Path -LiteralPath $k)) { New-Item -Path $k -Force | Out-Null }
   Set-ItemProperty -Path $k -Name RemoveDesktopShortcutDefault -Type DWord -Value 1
   foreach ($f in (Join-Path ([Environment]::GetFolderPath('CommonDesktopDirectory')) 'Microsoft Edge.lnk'), (Join-Path ([Environment]::GetFolderPath('Desktop')) 'UniGetUI.lnk')) {
     if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f; "消した: $f" } else { "無い: $f" }
   }
   Get-ItemProperty -Path $k | Format-List RemoveDesktopShortcutDefault
   ```

   - 2 つのファイルについて `消した:` か `無い:` と、`RemoveDesktopShortcutDefault : 1` が出ればよい
   - ほかのショートカットは消さない。要らなければ手で消す

   <details>
   <summary>補足: 場所とポリシー</summary>

   - Edge のショートカットは、すべてのユーザーのデスクトップ（`C:\Users\Public\Desktop`）にある。ここは管理者でないと消せない。名前は `Microsoft Edge.lnk`（製品の名前なので訳されないはず。確かめていない）
   - UniGet UI のショートカットは、手順 10 で入れたときに自分のデスクトップにできる（インストーラの定義の `{autodesktop}\UniGetUI`）。OneDrive でデスクトップをバックアップしていると場所が変わるので、`GetFolderPath('Desktop')` で探す
   - Edge のショートカットは、Edge の更新で作り直されることがある。Edge Update のポリシー `RemoveDesktopShortcutDefault` を 1 にすると、Edge の更新や再起動のときに、すべてのユーザーのデスクトップの Edge のショートカットを消す（Microsoft の文書。Edge Update 1.3.155.1 から）。`CreateDesktopShortcutDefault` は、Edge が入っていると効かない（同じ文書）
   - 元に戻すのは[ロールバック](#ロールバック)の手順 24（ポリシーだけ。消したショートカットは戻らない）

   </details>

1. Caps Lock を左 Ctrl にする Scancode Map を書く。

   ```powershell
   & {
     $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
     $want = '00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00'
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない（手順 23 から）'; return }
     $now = (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue).'Scancode Map'
     $nowHex = if ($now) { ($now | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' } else { '' }
     if ($nowHex -and $nowHex -ne $want) { Write-Error "中断: 別の Scancode Map がある（$nowHex）"; return }
     if (-not $nowHex) { New-ItemProperty -Path $key -Name 'Scancode Map' -PropertyType Binary -Value ([byte[]]($want -split ' ' | ForEach-Object { [Convert]::ToByte($_, 16) })) | Out-Null }
     'Scancode Map = {0}' -f ((((Get-ItemProperty -Path $key).'Scancode Map') | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')
   }
   ```

   - `Scancode Map = 00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00` が出ればよい
   - 同じ値がもうあれば、何も書かずに同じ行を出す（何度貼ってもよい）
   - `中断: 別の Scancode Map がある` が出たら、ほかのキーの割り当てがある。消さないように止めている（両方を使うなら、その値を手で直す。数を 1 つ増やし、終わりの印の前に `1D 00 3A 00` を足す）
   - 効くのは、手順 43 の再起動の後

   <details>
   <summary>補足: Scancode Map の値</summary>

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
   - スキャン コードはキーの位置で決まるので、US 配列（手順 41）でも JIS 配列でも、Caps Lock の位置のキー（`0x3A`）が Ctrl になる
   - 値を 16 進の文字列で比べるのは、もう同じ値があるか（2 回目）と、ほかの割り当てがあるかを分けるため

   </details>

1. AlmaLinux とデュアル ブートし、AlmaLinux の時計を UTC にしているときだけ、Windows も UTC にする。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name RealTimeIsUniversal -Type DWord -Value 1
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' | Format-List RealTimeIsUniversal
   ```

   - `RealTimeIsUniversal : 1` が出ればよい
   - 効くのは、手順 43 の再起動の後。時刻がずれていたら、設定の「時刻と言語」→「日付と時刻」の「今すぐ同期」で合わせ直す
   - AlmaLinux の `timedatectl` の `RTC in local TZ:` が `yes`（`/etc/adjtime` の 3 行目が `LOCAL`）なら、この手順は飛ばす。AlmaLinux のインストーラは、Windows を見つけると `LOCAL` にする（[windows-dual-boot.md の注意点](windows-dual-boot.md#注意点)）
   - デュアル ブートしない PC でも、この手順は飛ばす

   <details>
   <summary>補足: Windows と Linux の時計の扱い</summary>

   - Windows は、ハードウェアの時計（RTC）を地方時として読み書きする。Linux は UTC として扱うのが普通で、両方が違う扱いのままデュアル ブートすると、起動し直すたびに 9 時間ずれる。2 つの OS のどちらかにそろえればよい
   - AlmaLinux 10 のインストーラ（anaconda）は、NTFS のパーティションを見つけると、AlmaLinux の側を地方時にする（`/etc/adjtime` に `LOCAL`。[windows-dual-boot.md の注意点](windows-dual-boot.md#注意点)。インストーラのソースから読んだこと）。その流れで入れたなら、もうそろっているので、この手順は要らない（行うと、かえって 9 時間ずれる）
   - AlmaLinux の側を UTC にした（`timedatectl set-local-rtc 0`）ときだけ、Windows も UTC にそろえる。`HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation` の `RealTimeIsUniversal` を 1 にすると、Windows も UTC として扱う。Microsoft の文書には無い値で、Arch Linux の wiki が勧める形（DWORD。64 ビットの Windows では QWORD という古い勧めは、wiki から消えた）
   - Arch Linux の wiki は、両方を UTC にする形を勧めている（Linux の側を地方時にする `timedatectl set-local-rtc 1` は勧めていない）。本書は、AlmaLinux のインストーラの既定（地方時）に合わせ、2026-10-03 に [windows-dual-boot.md](windows-dual-boot.md) とそろえた
   - 元に戻すのは[ロールバック](#ロールバック)の手順 27

   </details>

1. US 配列（101/102 キー）のキーボードを使うときだけ、キーボードの種類を変える。

   ```powershell
   $k = 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters'
   Set-ItemProperty -Path $k -Name 'LayerDriver JPN' -Type String -Value 'kbd101.dll'
   Set-ItemProperty -Path $k -Name OverrideKeyboardIdentifier -Type String -Value 'PCAT_101KEY'
   Set-ItemProperty -Path $k -Name OverrideKeyboardType -Type DWord -Value 7
   Set-ItemProperty -Path $k -Name OverrideKeyboardSubtype -Type DWord -Value 0
   Get-ItemProperty -Path $k | Format-List 'LayerDriver JPN', OverrideKeyboardIdentifier, OverrideKeyboardType, OverrideKeyboardSubtype
   ```

   - `LayerDriver JPN : kbd101.dll`・`OverrideKeyboardIdentifier : PCAT_101KEY`・`OverrideKeyboardType : 7`・`OverrideKeyboardSubtype : 0` が出ればよい
   - JIS 配列（日本語の 106/109 キー）のキーボードなら、この手順は飛ばす
   - 効くのは、手順 43 の再起動の後。US 配列には半角/全角のキーが無いので、日本語の入力の切り替えは、手順 19 の Ctrl+Space（または Alt+`）で行う

   <details>
   <summary>補足: キーボードの種類の値</summary>

   - 日本語の Windows は、キーボードの種類（配列のドライバー）を PC 全体で 1 つ持つ。`HKLM\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters` の 4 つの値で決まり、名前は i8042prt（PS/2）だが、USB のキーボードにもかかる
   - US 配列の値は、Microsoft の日本の社員のブログ（Learn に残っている「英語キーボードを快適に使う」）と同じ。設定の「時刻と言語」→「言語と地域」→「日本語」の「言語のオプション」→「キーボード レイアウト」の「英語キーボード (101/102 キー)」も、同じ値を書くと報告されている
   - JIS 配列の値は、`kbd106.dll`・`PCAT_106KEY`・7・2（広く使われているもの）。手順 25 の `Keyboard` で、元の値を控える
   - 手順 39 の Scancode Map は、キーの位置（スキャン コード）で変えるので、US 配列でも Caps Lock の位置のキーが Ctrl になる
   - 元に戻すのは[ロールバック](#ロールバック)の手順 26

   </details>

1. WSL を使えるように、Windows の機能を入れる（ディストリビューションは再起動の後に入れる）。

   ```powershell
   wsl.exe --install --no-distribution
   ```

   - 必要な機能（仮想マシン プラットフォーム）を入れた旨と、再起動を求める旨の行が出ればよい（出力は確かめていない）
   - もう入っていれば、何もしない
   - **注意**: この後は Hyper-V が動くので、[VirtualBox](virtualbox.md#windows-11-で使う) の VM は Hyper-V の上で動く（遅くなり、[virtualbox-guest-bootc.md](virtualbox-guest-bootc.md) の検証では VM が数分ずつ止まった）

   <details>
   <summary>補足: 入るもの</summary>

   - Windows 11 では、`wsl --install --no-distribution` は Windows の機能「仮想マシン プラットフォーム」（`VirtualMachinePlatform`）を入れ、WSL のパッケージを入れる（WSL のソースの `WslInstall.cpp`）。WSL 1 の機能（`Microsoft-Windows-Subsystem-Linux`）は `--enable-wsl1` を付けたときだけ
   - 機能を入れたときは、再起動が要る。この文書では手順 43 の再起動で済ませ、AlmaLinux 10 は手順 50 で入れる
   - VirtualBox は、Hyper-V が動いていると、それを通して VM を動かす（NEM）。仮想マシン プラットフォームを外しても、メモリ整合性などで Hyper-V が動き続けることがある
   - 元に戻すのは[ロールバック](#ロールバック)の手順 25

   </details>

1. 再起動する。

   ```powershell
   Restart-Computer
   ```

   - 保存していない作業があれば、先に保存する（すぐに再起動が始まる）
   - ほかのユーザーがサインインしていると、エラーで止まる。そのときは、スタートメニューの電源から再起動する
   - **次の手順は、起動してサインインしてから行う**

1. キーボードで、Caps Lock・Ctrl+Space・配列を確かめる。

   - メモ帳を開いて何か打ち、Caps Lock を押したまま A を押すと、全部が選ばれる（Ctrl+A）
   - Caps Lock だけを押しても、Caps Lock のランプは点かず、大文字にもならない
   - 日本語の配列（JIS）のキーボードでは、「英数」（Caps Lock）のキーが Ctrl になる
   - Ctrl+Space を押すたびに、IME のオンとオフが入れ替わる（タスクバーの「あ」と「A」）
   - 手順 41 を行ったなら、記号が US 配列の位置で出る（Shift+2 で `@`）

1. エクスプローラー・タスクバー・スタートが変わったことを確かめる。

   - ファイルかデスクトップを右クリックすると、「その他のオプションを確認」を選ばなくても、「送る」「プロパティ」などの並ぶ旧形式のメニューが出る
   - エクスプローラーを開くと「PC」が出て、ファイル名に拡張子が付き、隠しファイルも見える
   - タスクバーのアイコンが左に寄り、タスク ビュー・検索・ウィジェットのボタンが無く、時計に秒が出る。全体が濃い色になっている
   - スタートを開いて文字を打っても、Web（Bing）の結果が出ない（手順 37。出たら、手順 37 の補足）
   - デスクトップに Edge と UniGet UI のショートカットが無い

1. タスクバーとスタートの、要らないピン留めを外す。

   - タスクバーのアイコン（Microsoft Edge・Microsoft Store など）を右クリックし、「タスク バーからピン留めを外す」
   - スタートを開き、ピン留めされたアプリを右クリックし、「スタートからピン留めを外す」
   - Copilot は外さない（利用者の選択）。使うアプリは残す
   - 画面の文言は確かめていない

   <details>
   <summary>補足: コマンドで外さない理由</summary>

   - 自分のユーザーのピン留めを外す、サポートされたコマンドは無い。Microsoft の文書にある方法は、どれもポリシー（`ConfigureStartPins` やタスクバーのレイアウトの XML）か、新しいユーザーにだけかかるファイル
   - タスクバーの設定（`Taskband`）やスタートのファイル（`start2.bin`）を消す方法は、Microsoft の説明が無く、形も決まっていないので採らない

   </details>

1. スタートメニューから UniGet UI を起動し、WinGet と Scoop が使えることを確かめる。

   - スタートメニューで「UniGetUI」を探して開く
   - 初回は、使い方の案内や設定の問いが出ることがある。読んで進める
   - 設定のパッケージ マネージャーの一覧で、WinGet と Scoop が有効になっていて、見つかっている（版が出ている）ことを確かめる
   - 「インストール済みのパッケージ」に、手順 10 で scoop で入れた `scoop-search` と、winget の `UniGetUI` などが出る
   - git が無い旨の警告が出たら、この文書の後に [git.md](git.md#windows-11-で-git-for-windows-を入れる) で Git for Windows を入れる（scoop の `git` は入れない）

   <details>
   <summary>補足: UniGet UI と scoop</summary>

   - UniGet UI は、`PATH` から `scoop.ps1` を探して scoop を見つける。PowerShell 7（`pwsh.exe`）があればそれで、無ければ Windows PowerShell 5.1 で、`-ExecutionPolicy Bypass` を付けて動かす（ソースの `Scoop.cs`）
   - UniGet UI は、scoop の更新に git が要るとして、無ければ `scoop install main/git` を勧める（同じソース）。本書は git を Git for Windows にそろえるので、勧めに従わない（[選択した方針](#選択した方針)）
   - UniGet UI は、手順 10 で入れたときに、サインインのときに起動する設定（`Run` の `WingetUI`）も作る。手順 20 では止めていない
   - 画面の文言と並びは、Windows で確かめていない

   </details>

1. 管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」にはしない）

1. 再起動の後の状態を確かめる。

   ```powershell
   $sm = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' -ErrorAction SilentlyContinue).'Scancode Map'
   [pscustomobject]@{
     ComputerName  = $env:COMPUTERNAME
     CtrlEnter     = (Get-PSReadLineKeyHandler -Bound | Where-Object Key -eq 'Ctrl+Enter').Function
     ScancodeMap   = if ($sm) { ($sm | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' } else { '' }
     Keyboard      = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters' -ErrorAction SilentlyContinue).'LayerDriver JPN'
     LongPaths     = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem').LongPathsEnabled
     DeveloperMode = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
     Sudo          = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo' -ErrorAction SilentlyContinue).Enabled
     Hibernate     = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power').HibernateEnabled
     RemoteDesktop = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server').fDenyTSConnections
     LanCategory   = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).NetworkCategory
     Hypervisor    = (Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
   } | Format-List
   ```

   - 次の値が出ればよい（行わなかった手順の値は、元のまま）
     - `ComputerName` が手順 24 の `PC_NAME`（大文字）、`CtrlEnter : AddLine`、`ScancodeMap : 00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00`
     - `Keyboard` は、手順 41 を行ったなら `kbd101.dll`
     - `LongPaths : 1`・`DeveloperMode : 1`・`Sudo : 3`・`Hibernate : 0`
     - `RemoteDesktop : 0`（手順 32 を行ったとき）・`LanCategory : Private`
     - `Hypervisor : True`（手順 42 で WSL の機能を入れたので）

1. WSL に AlmaLinux 10 を入れ、ユーザーを作る。

   ```powershell
   wsl.exe --install AlmaLinux-10
   ```

   - ダウンロードの後に `Enter new UNIX username:` と聞かれるので、Linux のユーザー名を入れる。続けてパスワードを 2 回入れる
   - AlmaLinux 10 のシェル（`[<ユーザー>@<HOSTNAME> ~]$`）になったら、`exit` で PowerShell に戻る
   - **次の手順は、`exit` で PowerShell に戻ってから貼る**（続けて貼ると、AlmaLinux 10 のシェルへの入力として食われる）

   <details>
   <summary>補足: AlmaLinux 10 の WSL のイメージ</summary>

   - `AlmaLinux-10` は、WSL のディストリビューションの一覧（`wsl --list --online`）の AlmaLinux 10 の名前。イメージは AlmaLinux の `wsl-images`（GitHub）にあり、`wsl.exe` が sha256 を確かめて入れる（WSL の `DistributionInfo.json`。2026-10-03 は 10.2）
   - 最初の起動で、AlmaLinux のイメージの `oobe` がユーザーを作る。作ったユーザーは uid 1000 で、`wheel` に入る（`sudo` を使える）。systemd が動く（`wsl.conf` の `systemd=true`）
   - Linux のユーザー名とパスワードは、Windows のものとは別。パスワードは `sudo` で聞かれる
   - [Windows の OpenSSH サーバー](windows-openssh-server.md)の検証では、この AlmaLinux 10 からこの PC に SSH でつないで確かめた

   </details>

1. AlmaLinux 10 が WSL 2 で動くことを確かめる。

   ```powershell
   $env:WSL_UTF8 = '1'
   wsl.exe --list --verbose
   wsl.exe --distribution AlmaLinux-10 -- head -n 2 /etc/os-release
   ```

   - `AlmaLinux-10` の行の `VERSION` が `2` で、`NAME="AlmaLinux"` と `VERSION="10.2 …"` の形の行が出ればよい（版は入れた日のイメージ）
   - `WSL_UTF8` は、`wsl.exe` の表示を、この窓で読める形（UTF-8）にするため（この窓の中だけ）

1. 自動サインイン（Sysinternals の Autologon）を入れて起動し、パスワードを入れて有効にする。

   ```powershell
   winget install --exact --id Microsoft.Sysinternals.Autologon --source winget --scope user --accept-source-agreements --accept-package-agreements
   $exe = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter Autologon64.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
   if (-not $exe) { Write-Error '中断: Autologon64.exe が見つからない' } else { Start-Process -FilePath $exe -ArgumentList '-accepteula' }
   ```

   - UAC の確認が出たら「はい」。Autologon の窓が開く
   - `Username` にこの PC のユーザー名、`Domain` に PC の名前（入っている値のまま）、`Password` にこのユーザーのパスワードを入れ、`Enable` を押す
   - Microsoft アカウントのときの `Username` と `Domain` の入れ方は確かめていない（この手順の補足）
   - 効くのは、次に起動したときから（起動のときに Shift を押していると、その回は飛ばす）
   - 人が触れる場所にある PC では、この手順は行わない（リードの `[!WARNING]`）

   <details>
   <summary>補足: Autologon のすること</summary>

   - Autologon は Microsoft の Sysinternals の道具で、Windows の自動ログオンの設定（`HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon` の `AutoAdminLogon` など）を書き、パスワードは LSA のシークレットとして、暗号にして置く（Microsoft の文書。管理者は取り出せる）
   - winget の定義（`Microsoft.Sysinternals.Autologon` 3.10）は zip の持ち運び版で、`%LOCALAPPDATA%\Microsoft\WinGet\Packages` の下に展開する。定義の取り先は版の付かない URL で、2026-10-03 は sha256 が一致した。Microsoft が zip を差し替えると、定義が直るまで winget が失敗する
   - コマンド ラインでパスワードを渡す形（`autologon <ユーザー> <ドメイン> <パスワード>`）は、パスワードがプロセスのコマンド ラインに見え、履歴にも残りうるので使わず、窓で入れる
   - `-accepteula` は、使用許諾の窓を出さないため
   - Microsoft アカウントでは、`Username` をメールアドレスにし、`Domain` を `MicrosoftAccount` か PC の名前にする、という報告があるが、確かめていない。パスワード（PIN ではない）が要り、手順 36 でパスワードのサインインを使えるようにしておく
   - [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)は、デスクトップにサインインしていることを前提にする。再起動の後もサインインした状態にするため
   - 止めるのは[ロールバック](#ロールバック)の手順 20

   </details>

---

## Wake on LAN を使う（任意）

- 電源を切った（シャットダウンした）この PC を、LAN の別の PC から起こせるようにする。有線 LAN だけ（Wi-Fi では使えない）
- 前提: 手順 29（休止状態を切ると、高速スタートアップも切れる）と手順 30（アダプターの省電力）。この節の手順 2〜4・8 は、この節の手順 1 で開く管理者の Windows PowerShell（5.1）に貼る
- **この節の手順 4 で再起動して UEFI の画面に入り、この節の手順 5 は UEFI の画面、手順 6 はこの PC、手順 7 は LAN の別の PC で行う**
- Windows の側の値は Microsoft の文書の標準の名前（`*WakeOnMagicPacket`）だけを変える。アダプターに独自の項目があれば、この節の手順 3 の表で確かめる

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. 変数を設定する。

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # 有線 LAN の接続（自動）。<LAN_IF>
   'LAN_IF = {0}' -f $LAN_IF
   ```

   - 手順 24 の 2 つ目のブロックと同じ式。Wi-Fi の名前が出たら、`$LAN_IF = 'イーサネット'` のように有線 LAN の名前に直す

1. アダプターのマジック パケットでの起動を有効にし、MAC アドレスを表示する。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error 'この節の手順 2 の $LAN_IF が空'
   } else {
     Set-NetAdapterAdvancedProperty -Name $LAN_IF -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 1 -NoRestart
     Get-NetAdapterAdvancedProperty -Name $LAN_IF | Where-Object { $_.RegistryKeyword -like '*Wake*' -or $_.DisplayName -like '*Wake*' } | Format-Table DisplayName, DisplayValue, RegistryKeyword
     Get-NetAdapter -Name $LAN_IF | Format-List Name, InterfaceDescription, MacAddress
   }
   ```

   - 表に `*WakeOnMagicPacket` の行があり、`DisplayValue` が有効の旨（`Enabled` か「有効」）になればよい
   - `MacAddress` の値を控える（この節の手順 7 で使う）
   - `*WakeOnMagicPacket` が無い旨のエラーが出たら、このアダプターは標準の名前を持たない。表のほかの `Wake` の項目（「Shutdown Wake-On-Lan」など）を、デバイス マネージャーのアダプターの「詳細設定」で有効にする

   <details>
   <summary>補足: シャットダウンからの Wake on LAN</summary>

   - Microsoft の文書では、Windows 10 以降の既定のシャットダウン（高速スタートアップ）では、Windows はアダプターに起動を任せない。シャットダウン（S5）からの起動は、UEFI とアダプターだけが行い、Windows は関わらない
   - そのため、高速スタートアップを切り（手順 29）、UEFI の Wake on LAN（機種によって「Power On By PCI-E」など）を有効にし、アダプターの詳細設定でマジック パケットを受けるようにする
   - `*WakeOnMagicPacket` は、Microsoft の文書の標準の詳細設定の名前（1 で有効）。機種独自の項目（シャットダウンからの起動、リンクでの起動など）は、名前がアダプターごとに違う
   - `-NoRestart` で、アダプターを起動し直さない（効くのは次の再起動から）
   - 眠り（S3・Modern Standby）からの起動は、手順 29 で眠らないようにしたので扱わない

   </details>

1. 再起動して、UEFI の設定の画面に入る。

   ```powershell
   shutdown.exe /r /fw /t 0
   ```

   - すぐに再起動し、UEFI（BIOS）の設定の画面が開く
   - **次の手順は、UEFI の設定の画面が開いてから行う**

1. UEFI の設定の画面で、Wake on LAN を有効にして保存し、Windows を起動する。

   - 項目の名前と場所は機種ごとに違う（「Wake on LAN」「Power On By PCI-E」「Resume by LAN」など）。機種の説明書で確かめる
   - 保存して終える（Save & Exit）と、Windows が起動する
   - 「ErP」「Deep Sleep」などの、電源を切ったときの消費を減らす項目が有効だと、Wake on LAN が効かないことがある

1. この PC を、スタートメニューの電源の「シャットダウン」で切る。

   - 有線 LAN のケーブルはつないだままにする

1. LAN の別の PC から、この PC の MAC アドレスあてにマジック パケットを送り、この PC が起動することを確かめる。

   - AlmaLinux 10 などの Python があるマシンでは、`python3 -c "import socket; m = bytes.fromhex('<MAC>'.replace('-', '').replace(':', '')); s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM); s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1); s.sendto(b'\xff' * 6 + m * 16, ('255.255.255.255', 9))"` で送れる（`<MAC>` はこの節の手順 3 の値。この 1 行は Linux で送れることだけ確かめた）
   - 起動しなければ、この節の手順 3 の表の項目と、UEFI の設定を見直す
   - 元に戻すときは、この節の手順 8

1. 元に戻すときは、管理者の PowerShell で、マジック パケットでの起動を切る。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error 'この節の手順 2 の $LAN_IF が空'
   } else {
     Set-NetAdapterAdvancedProperty -Name $LAN_IF -RegistryKeyword '*WakeOnMagicPacket' -RegistryValue 0 -NoRestart
     Get-NetAdapterAdvancedProperty -Name $LAN_IF -RegistryKeyword '*WakeOnMagicPacket' | Format-Table DisplayName, DisplayValue
   }
   ```

   - 新しい PowerShell なら、先にこの節の手順 2 を貼る
   - UEFI の Wake on LAN も、この節の手順 4・5 と同じように入って切る

---

## 更新

- scoop で入れたものは scoop で、winget で入れたもの（UniGet UI・PowerToys・PowerShell 7・Autologon）は winget で上げる。UniGet UI の画面からも、scoop と winget のパッケージをまとめて上げられる（UniGet UI と PowerToys は、自分でも新しい版を確かめる）
- Windows の大きな更新（機能の更新）の後は、外したアプリと切った提案が戻ることがある。[手順 15](#実施手順)・[手順 20〜22](#実施手順) を貼り直す
- Git for Windows・Firefox・WezTerm・Claude Code・VirtualBox・WireGuard・HackGen Console NF は、それぞれの手順書の「Windows 11 の更新」
- この節の手順は、手順 3 と同じ、管理者ではない Windows PowerShell（5.1）に貼る

1. scoop とバケットを上げ、古くなったものを確かめる。

   ```powershell
   scoop update
   scoop status
   ```

   - `scoop update` は `Scoop was updated successfully!` を出す
   - git が無いと `Scoop uses Git to update itself. Run 'scoop install git' and try again.` で止まる。先に [git.md](git.md#windows-11-で-git-for-windows-を入れる) で Git for Windows を入れる（初めての `scoop update` は、scoop 本体と main のバケットを git の形に直す）
   - `scoop status` は、古いものがあれば名前と版を並べる。`Everything is ok!` なら、この節の手順 2 は飛ばす

1. 古いものがあるときだけ、scoop で入れたものを上げる。

   ```powershell
   scoop update *
   ```

   - アプリごとに `'<名前>' (<版>) was installed successfully!` の形の行が出る
   - 動いているアプリは `Running process detected, skip updating.` で飛ばされる。閉じてから貼り直す
   - SSH のセッションで scoop のツールを使っているなら、[Windows の OpenSSH サーバー](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の任意節の手順 1 を、管理者の PowerShell で貼り直す（新しいジャンクションができるため）

1. winget で入れたものを上げる。

   ```powershell
   foreach ($id in 'Devolutions.UniGetUI', 'Microsoft.PowerToys', 'Microsoft.PowerShell', 'Microsoft.Sysinternals.Autologon') { winget upgrade --exact --id $id --source winget --accept-source-agreements --accept-package-agreements }
   ```

   - それぞれ、新しい版が無ければ更新が見つからない旨の行を出して何もしない
   - 動いている UniGet UI・PowerToys は、インストーラが閉じる
   - 入れていないものは、入っていない旨の行を出すだけ

1. WSL と AlmaLinux 10 を上げる。

   ```powershell
   wsl.exe --update
   wsl.exe --distribution AlmaLinux-10 --user root -- dnf -y upgrade
   ```

   - `wsl.exe --update` は WSL のパッケージ（とカーネル）を上げる。新しい版が無ければ、最新である旨を出す
   - `dnf -y upgrade` の最後に `Complete!` か `Nothing to do.` が出ればよい

---

## ロールバック

- この節の手順 1〜17 は手順 3 と同じ管理者ではない Windows PowerShell（5.1）に、この節の手順 19〜38 はこの節の手順 18 で開く管理者の Windows PowerShell に貼る
- 残す項目の手順は飛ばす。項目ごとのこの節の手順
  - 表示と入力: エクスプローラーは 1、コンテキストメニューは 2、スタートは 3・23、タスクバーは 4、ダークモードは 5、既定の端末は 6、IME は 7、キーボードは 26・28
  - 整理: 自動で起動するアプリは 8、標準アプリとウィジェットは 9、ショートカットのポリシーは 24
  - 入れたもの: PowerShell 7 は 10、PowerToys は 11、UniGet UI は 12、scoop は 13・14、WSL は 17・25、Autologon は 20・21
  - 貼り付けの設定: 15・16
  - PC 全体: PC の名前は 37、長いパス・開発者モード・sudo は 36、電源とロックは 35、アダプターは 34、時計は 27
  - ネットワークとサインイン: 配信の最適化は 29、ping は 30、リモート アシスタンスは 31、リモート デスクトップは 32、LAN の種類は 33、Windows Hello は 22
- 多くは、元に戻すかを手順 25 で控えた値で決める
- Git for Windows など、ほかの手順書で入れたものは、それぞれの手順書の「Windows 11 のロールバック」

> [!CAUTION]
> **この節の手順 13 は、scoop で入れたすべてのアプリを消す**（本書の外で入れたものも）。**この節の手順 14 は、それらの設定（`~\scoop\persist`）を、この節の手順 17 は WSL の AlmaLinux 10 のファイルをすべて消す**（取り戻せない）。残すなら、その手順は行わない。

1. エクスプローラーの表示を既定に戻す。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   $exp = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
   Set-ItemProperty -Path $adv -Name HideFileExt -Type DWord -Value 1
   Set-ItemProperty -Path $adv -Name Hidden -Type DWord -Value 2
   Remove-ItemProperty -Path $adv -Name LaunchTo -ErrorAction SilentlyContinue
   Set-ItemProperty -Path $adv -Name Start_TrackDocs -Type DWord -Value 1
   Set-ItemProperty -Path $exp -Name ShowRecent -Type DWord -Value 1
   Set-ItemProperty -Path $exp -Name ShowFrequent -Type DWord -Value 1
   Get-ItemProperty -Path $adv | Format-List HideFileExt, Hidden, LaunchTo, Start_TrackDocs
   ```

   - `HideFileExt : 1`・`Hidden : 2`・`Start_TrackDocs : 1` が出て、`LaunchTo` が空ならよい
   - エクスプローラーには、開き直すか再起動の後に効く

1. 旧形式のコンテキストメニューの設定を消す。

   ```powershell
   reg.exe delete 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' /f
   Test-Path -LiteralPath 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
   ```

   - `False` が出ればよい
   - エクスプローラーに効くのは、サインインし直すか、この節の手順 38 の再起動の後

1. スタートと設定の、おすすめ・提案・ヒントを既定に戻す。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
   Set-ItemProperty -Path $adv -Name Start_IrisRecommendations -Type DWord -Value 1
   Set-ItemProperty -Path $adv -Name Start_AccountNotifications -Type DWord -Value 1
   foreach ($n in 'SubscribedContent-338393Enabled', 'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled', 'SubscribedContent-338389Enabled', 'SubscribedContent-310093Enabled', 'SubscribedContent-338388Enabled', 'SystemPaneSuggestionsEnabled', 'SilentInstalledAppsEnabled') { Set-ItemProperty -Path $cdm -Name $n -Type DWord -Value 1 }
   Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Name ScoobeSystemSettingEnabled -ErrorAction SilentlyContinue
   Get-ItemProperty -Path $cdm | Format-List SubscribedContent-338393Enabled, SubscribedContent-353694Enabled, SubscribedContent-353696Enabled, SubscribedContent-338389Enabled, SubscribedContent-310093Enabled, SubscribedContent-338388Enabled, SystemPaneSuggestionsEnabled, SilentInstalledAppsEnabled
   ```

   - 並んだ値がすべて `1` ならよい
   - スタートの検索の Web の結果は、この節の手順 23 で戻す

1. タスクバーを既定に戻す。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   foreach ($n in 'TaskbarAl', 'ShowTaskViewButton', 'ShowSecondsInSystemClock') { Remove-ItemProperty -Path $adv -Name $n -ErrorAction SilentlyContinue }
   Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name SearchboxTaskbarMode -ErrorAction SilentlyContinue
   Get-ItemProperty -Path $adv | Format-List TaskbarAl, ShowTaskViewButton, ShowSecondsInSystemClock
   ```

   - 3 つの値が空ならよい（値が無いと既定の、中央・タスク ビューあり・秒なし・検索ボックス）
   - ウィジェットは、この節の手順 9 で入れ直す

1. 淡色（ライトモード）に戻す。

   ```powershell
   $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
   Set-ItemProperty -Path $p -Name AppsUseLightTheme -Type DWord -Value 1
   Set-ItemProperty -Path $p -Name SystemUsesLightTheme -Type DWord -Value 1
   Get-ItemProperty -Path $p | Format-List AppsUseLightTheme, SystemUsesLightTheme
   ```

   - 2 つとも `1` が出ればよい

1. 既定の端末を「Windows に任せる」に戻す。

   ```powershell
   foreach ($n in 'DelegationConsole', 'DelegationTerminal') { Remove-ItemProperty -LiteralPath 'HKCU:\Console\%%Startup' -Name $n -ErrorAction SilentlyContinue }
   Get-ItemProperty -LiteralPath 'HKCU:\Console\%%Startup' -ErrorAction SilentlyContinue | Format-List DelegationConsole, DelegationTerminal
   ```

   - 2 つの値が空ならよい（Windows 11 22H2 以降は、Windows Terminal が入っていればそれを使う）

1. Microsoft IME の設定を開き、Ctrl+Space の割り当てを外す。

   ```powershell
   Start-Process 'ms-settings:regionlanguage-jpnime'
   ```

   - 「キーとタッチのカスタマイズ」で、「Ctrl + Space」を「なし」にするか、「キーの割り当て」をオフにする（画面の文言は確かめていない）
   - **次の手順は、設定を閉じてから PowerShell に貼る**

1. 自動で起動するアプリ（OneDrive・Edge・Teams）を、起動するように戻す。

   ```powershell
   & {
     $ok = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
     $props = (Get-Item -LiteralPath $ok -ErrorAction SilentlyContinue).Property | Where-Object { $_ -eq 'OneDrive' -or $_ -like 'MicrosoftEdgeAutoLaunch_*' }
     foreach ($n in $props) { Set-ItemProperty -LiteralPath $ok -Name $n -Type Binary -Value ([byte[]](2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)); "戻した: $n" }
     $teams = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe\TeamsTfwStartupTask'
     if (Test-Path -LiteralPath $teams) { Set-ItemProperty -LiteralPath $teams -Name State -Type DWord -Value 2; '戻した: Teams' }
   }
   ```

   - 止めていたものごとに `戻した:` が出ればよい（無ければ何も出ない）
   - 効くのは、次のサインインから。タスク マネージャーの「スタートアップ アプリ」からでも戻せる

1. 外した標準アプリとウィジェットを戻すときだけ、ストアと winget から入れ直す。

   ```powershell
   foreach ($id in '9P1J8S7CCWWT', '9WZDNCRFHVFW', '9WZDNCRFJ3Q2', '9WZDNCRFHWD2', '9WZDNCRD29V9', '9NBLGGH5R558', '9NBLGGH4R32N', '9PKDZBMV1H3T', '9NRX63209R7B', '9NFTCH6J7FHV', '9MSSGKG348SP') { winget install --exact --id $id --source msstore --accept-source-agreements --accept-package-agreements }
   winget install --exact --id Microsoft.Teams --source winget --accept-source-agreements --accept-package-agreements
   ```

   - アプリごとに、入れた旨か、もう入っている旨の行が出る
   - 要らないアプリは、その ID を消してから貼る（ID とアプリの対応は手順 21 の補足の表。`9MSSGKG348SP` がウィジェット）

1. PowerShell 7 を外す。

   ```powershell
   winget uninstall --exact --id Microsoft.PowerShell --source winget
   winget list --exact --id Microsoft.PowerShell
   ```

   - 最後のコマンドが、入っているパッケージが見つからない旨の行を出せばよい
   - PowerShell 7 のプロファイル（`Documents\PowerShell`）は残る

1. PowerToys を外す。

   ```powershell
   winget uninstall --exact --id Microsoft.PowerToys --source winget
   winget list --exact --id Microsoft.PowerToys
   ```

   - 最後のコマンドが、入っているパッケージが見つからない旨の行を出せばよい
   - 動いている PowerToys は、アンインストーラが閉じる。設定（`%LOCALAPPDATA%\Microsoft\PowerToys`）は残る

1. UniGet UI を外す。

   ```powershell
   winget uninstall --exact --id Devolutions.UniGetUI --source winget
   winget list --exact --id Devolutions.UniGetUI
   ```

   - 最後のコマンドが、入っているパッケージが見つからない旨の行を出せばよい
   - 動いている UniGet UI は、アンインストーラが閉じる
   - 設定（`%LOCALAPPDATA%\UniGetUI`）は残る。要らなければ手で消す

1. scoop と、scoop で入れたすべてのアプリを外す。

   ```powershell
   scoop uninstall scoop
   ```

   - `Are you sure? (yN)` と聞かれるので、`y` を入れる
   - 最後に `Scoop has been uninstalled.` が出ればよい（`~\scoop\persist` は残る）
   - 消せないアプリがあると `Not all apps could be deleted. Try again or restart.` で止まる。そのアプリを閉じて貼り直す
   - **次の手順は、`Scoop has been uninstalled.` が出てから貼る**（続けて貼ると `y` の答えとして食われる）

1. scoop の残りを消すときだけ、`persist` と設定を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\scoop", "$env:USERPROFILE\.config\scoop" -Recurse -Force -ErrorAction SilentlyContinue
   Test-Path "$env:USERPROFILE\scoop", "$env:USERPROFILE\.config\scoop"
   ```

   - `False` が 2 行出ればよい
   - この手順を行わないと、scoop を入れ直すときに手順 8 が `exists and is not empty` で止まる

1. プロファイルから、手順 7 で足した行を消す。

   ```powershell
   & {
     $line = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-setup.md'
     $old = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-powershell-paste.md'
     if (-not (Test-Path -LiteralPath $PROFILE)) { "プロファイルが無い: $PROFILE"; return }
     $bytes = [System.IO.File]::ReadAllBytes($PROFILE)
     $enc = if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { [System.Text.Encoding]::Unicode } else { [System.Text.Encoding]::GetEncoding(28591) }
     $text = $enc.GetString($bytes)
     $rest = [regex]::Replace($text, '(?m)^(\uFEFF|\u00EF\u00BB\u00BF)?(' + [regex]::Escape($line) + '|' + [regex]::Escape($old) + ')\r?\n?', '$1')
     if ($rest -eq $text) { "その行は無い: $PROFILE" } elseif ($rest -match '^(\uFEFF|\u00EF\u00BB\u00BF)?\s*$') { Remove-Item -LiteralPath $PROFILE; "消した: $PROFILE" } else { [System.IO.File]::WriteAllBytes($PROFILE, $enc.GetBytes($rest)); "その行だけ消した: $PROFILE" }
   }
   ```

   - プロファイルにほかの行が無ければ `消した:`、あれば `その行だけ消した:` が出る
   - 前の版の手順書（`windows-powershell-paste.md`）の印の行も消す
   - 開いている窓の設定（手順 4・7）は、窓を閉じるまで残る。戻した後は、Windows の PowerShell のブロックを、conhost の窓では Ctrl+V で貼る（右クリックで貼ると、行が逆順になる）

   <details>
   <summary>補足: 文字コードを変えずに消す</summary>

   - ファイルをバイトのまま読み、消す行のほかのバイトは変えずに書き戻す
   - 先頭が `FF FE`（UTF-16 LE の BOM）なら UTF-16 LE として、それ以外は 1 バイトを 1 文字にする Latin-1（コードページ 28591）として読み書きする。消す行は ASCII の文字だけなので、UTF-8（BOM の有無によらない）・Shift_JIS のどちらでも同じバイトで見つかる
   - ファイルの 1 行目は BOM の直後にあるので、行の前の BOM を許して探し、BOM は残す
   - 残りが BOM と空白だけなら、ファイルを消す
   - `Get-Content` と `Set-Content` で書き直さないのは、Windows PowerShell 5.1 が BOM の無いファイルを ANSI（日本語の Windows では Shift_JIS）として読み、`Set-Content` が指定しないと ANSI で書くため。BOM の無い UTF-8 の日本語が化ける

   </details>

1. 実行ポリシーを戻すときだけ、自分のユーザーの値を消す。

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser -Force
   Get-ExecutionPolicy -List | Format-Table -AutoSize
   ```

   - 手順 5 で `CurrentUser` が `Undefined` だったときだけ行う。`RemoteSigned` などだったなら飛ばす（手順 6 はその値を変えていない）
   - 表の `CurrentUser` が `Undefined` に戻ればよい
   - **注意**: PowerShell のスクリプトを使うほかの道具（scoop を残すときの scoop も）が動かなくなる。プロファイルも読まれなくなる

1. WSL の AlmaLinux 10 を消すときだけ、登録を外す（取り戻せない）。

   ```powershell
   wsl.exe --unregister AlmaLinux-10
   $env:WSL_UTF8 = '1'
   wsl.exe --list --verbose
   ```

   - AlmaLinux 10 の中のファイルは、すべて消える
   - 最後の一覧に `AlmaLinux-10` が無ければよい（ほかのディストリビューションが無ければ、無い旨の行）

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. 変数を設定する。

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # ほかの PC とつながる LAN の接続（自動）。<LAN_IF>
   'LAN_IF = {0}' -f $LAN_IF
   ```

   - 手順 24 の 2 つ目のブロックと同じ（`LAN_IF` が違えば直す）
   - `LAN_IF` は、この節の手順 33・34 で使う

1. 自動サインインを止めるときは、Autologon を起動し、`Disable` を押す。

   ```powershell
   $exe = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter Autologon64.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
   if (-not $exe) { Write-Error '中断: Autologon64.exe が見つからない' } else { Start-Process -FilePath $exe -ArgumentList '-accepteula' }
   ```

   - Autologon の窓で `Disable` を押す。自動ログオンの設定と、置いてあったパスワード（LSA のシークレット）が消える
   - **次の手順は、Autologon の窓が閉じてから貼る**

1. Autologon を外す。

   ```powershell
   winget uninstall --exact --id Microsoft.Sysinternals.Autologon --source winget
   (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon').AutoAdminLogon
   ```

   - アンインストールの成功の行と、`0` が出ればよい（自動ログオンが無効）
   - `1` が出たら、この節の手順 20 で `Disable` を押していない。外す前に戻って押す（外した後は、もう一度入れてから）

1. 手順 25 で `HelloOnly` が `2` だったときだけ、「Windows Hello サインインのみを許可する」をオンに戻す。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' -Name DevicePasswordLessBuildVersion -Type DWord -Value 2
   Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' | Format-List DevicePasswordLessBuildVersion
   ```

   - `DevicePasswordLessBuildVersion : 2` が出ればよい

1. スタートの検索の Web の結果を、出すように戻す。

   ```powershell
   Remove-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name DisableSearchBoxSuggestions -ErrorAction SilentlyContinue
   (Get-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -ErrorAction SilentlyContinue).DisableSearchBoxSuggestions
   ```

   - 何も出なければよい（値が無い）

1. Edge のショートカットを消すポリシーを外す。

   ```powershell
   Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate' -Name RemoveDesktopShortcutDefault -ErrorAction SilentlyContinue
   (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate' -ErrorAction SilentlyContinue).RemoveDesktopShortcutDefault
   ```

   - 何も出なければよい
   - 消したショートカットは戻らない（要れば、スタートメニューの Edge を右クリックして作る）

1. WSL も外すときだけ、WSL のパッケージと仮想マシン プラットフォームを外す。

   ```powershell
   wsl.exe --uninstall
   Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
   ```

   - `Disable-WindowsOptionalFeature` の結果に `RestartNeeded : True` が出る（この節の手順 38 で再起動する）
   - ほかのディストリビューションを使っているなら、この手順は行わない
   - メモリ整合性などで、Hyper-V は動き続けることがある（VirtualBox は Hyper-V の上のまま）

1. 手順 41 を行ったときだけ、キーボードの種類を JIS 配列に戻す。

   ```powershell
   $k = 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters'
   Set-ItemProperty -Path $k -Name 'LayerDriver JPN' -Type String -Value 'kbd106.dll'
   Set-ItemProperty -Path $k -Name OverrideKeyboardIdentifier -Type String -Value 'PCAT_106KEY'
   Set-ItemProperty -Path $k -Name OverrideKeyboardType -Type DWord -Value 7
   Set-ItemProperty -Path $k -Name OverrideKeyboardSubtype -Type DWord -Value 2
   Get-ItemProperty -Path $k | Format-List 'LayerDriver JPN', OverrideKeyboardIdentifier, OverrideKeyboardType, OverrideKeyboardSubtype
   ```

   - `kbd106.dll`・`PCAT_106KEY`・`7`・`2` が出ればよい
   - 手順 25 の `Keyboard` が `kbd106.dll` でなかったなら、その値に直してから貼る

1. 手順 40 を行ったときだけ、時計の扱いを地方時に戻す。

   ```powershell
   Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name RealTimeIsUniversal -ErrorAction SilentlyContinue
   (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation').RealTimeIsUniversal
   ```

   - 何も出なければよい。再起動の後に、時刻を同期し直す

1. Caps Lock を戻すときだけ、Scancode Map を消す。

   ```powershell
   & {
     $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
     $want = '00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00'
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない（この節の手順 18 から）'; return }
     $now = (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue).'Scancode Map'
     $nowHex = if ($now) { ($now | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' } else { '' }
     if (-not $nowHex) { 'Scancode Map は無い'; return }
     if ($nowHex -ne $want) { Write-Error "中断: 本書の値ではない Scancode Map がある（$nowHex）"; return }
     Remove-ItemProperty -Path $key -Name 'Scancode Map'
     'Scancode Map を消した'
   }
   ```

   - `Scancode Map を消した` が出ればよい
   - `中断:` が出たら、本書の後でほかの割り当てを足している。消さずに止めている

1. 手順 25 で配信の最適化が `Internet` だったときだけ、`Internet` に戻す。

   ```powershell
   Set-DODownloadMode -DownloadMode Internet
   Get-DODownloadMode
   ```

   - `Internet` が出ればよい
   - `Lan`（既定）だったなら、この手順は飛ばす

1. ping に応える規則を消す。

   ```powershell
   Remove-NetFirewallRule -Group 'Ping (setup-notes)' -ErrorAction SilentlyContinue
   Get-NetFirewallRule -Group 'Ping (setup-notes)' -ErrorAction SilentlyContinue
   ```

   - 何も出なければよい

1. 手順 25 で `RemoteAssistance` が `1` だったときだけ、システムのプロパティでリモート アシスタンスを戻す。

   ```powershell
   SystemPropertiesRemote.exe
   ```

   - システムのプロパティの「リモート」タブが開く。「このコンピューターへのリモート アシスタンス接続を許可する」にチェックを入れて「OK」を押す（画面の文言は確かめていない）
   - この画面は、`fAllowToGetHelp` と、リモート アシスタンスの受信の規則をまとめて戻すはず（確かめていない）。規則をコマンドでまとめて有効にすると、手順 33 の前に無効だった規則（パブリック向けなど）まで有効になりうるので、画面で戻す
   - **次の手順は、システムのプロパティを閉じてから貼る**

1. 手順 25 で `RemoteDesktop` が `1`（無効）だったときだけ、リモート デスクトップを無効に戻す。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Type DWord -Value 1
   Set-NetFirewallRule -Group '@FirewallAPI.dll,-28752' -Enabled False -Profile Any
   Get-NetFirewallRule -Group '@FirewallAPI.dll,-28752' | Format-Table Name, Enabled, Profile
   ```

   - 規則が `False  Any` で並べばよい
   - **注意**: リモート デスクトップでつないでいるときに貼ると、その場で切れる
   - [RDP をロックせずに切断（Windows）](windows-rdp-disconnect.md)を使っているなら、この手順は飛ばす

1. LAN の接続をパブリックに戻すときだけ、パブリックにする。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error 'この節の手順 19 の $LAN_IF が空'
   } else {
     Set-NetConnectionProfile -InterfaceAlias $LAN_IF -NetworkCategory Public
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
   }
   ```

   - `<LAN_IF>  Public` が出ればよい
   - 手順 25 で `LanCategory` が `Private` だったなら（もとからプライベート）、この手順は飛ばす
   - [Windows の OpenSSH サーバー](windows-openssh-server.md)・[Syncthing の Windows 11 で使う](syncthing.md#windows-11-で使う)・リモート デスクトップをこの LAN で使っているなら、この手順は飛ばす（パブリックにすると届かなくなる）

1. アダプターを、電力の節約のために止められるように戻す。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error 'この節の手順 19 の $LAN_IF が空'
   } else {
     $pm = Get-NetAdapterPowerManagement -Name $LAN_IF
     if ($pm.AllowComputerToTurnOffDevice -ne 'Unsupported') {
       $pm.AllowComputerToTurnOffDevice = 'Enabled'
       $pm | Set-NetAdapterPowerManagement -NoRestart
     }
     Get-NetAdapterPowerManagement -Name $LAN_IF | Format-List Name, AllowComputerToTurnOffDevice
   }
   ```

   - `AllowComputerToTurnOffDevice : Enabled` が出ればよい（このアダプターに設定が無ければ `Unsupported` のまま）
   - 効くのは、この節の手順 38 の再起動の後

1. 電源の設定を既定に戻し、休止状態を戻し、放置したときのロックを戻す。

   ```powershell
   powercfg /restoredefaultschemes
   powercfg /hibernate on
   Remove-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name DelayLockInterval -ErrorAction SilentlyContinue
   'HibernateEnabled: {0}' -f (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power').HibernateEnabled
   ```

   - `HibernateEnabled: 1` が出ればよい
   - **注意**: `/restoredefaultschemes` は、電源プランをすべて既定に戻す（本書の外で変えた電源の設定も消える）

1. 長いパス・開発者モード・sudo を切る。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -Type DWord -Value 0
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name AllowDevelopmentWithoutDevLicense -Type DWord -Value 0
   if (Get-Command sudo -ErrorAction SilentlyContinue) { sudo config --enable disable }
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' | Format-List LongPathsEnabled
   Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' | Format-List AllowDevelopmentWithoutDevLicense
   ```

   - `LongPathsEnabled : 0` と `AllowDevelopmentWithoutDevLicense : 0` が出ればよい
   - sudo は、無効になった旨の英語の行を出す

1. PC の名前を戻すときだけ、元の名前にする（`OLD_PC_NAME` は必ず値を入れる）。

   ```powershell
   $OLD_PC_NAME = ''   # 手順 25 で控えた元の名前。<HOSTNAME>
   ```

   ```powershell
   if (-not $OLD_PC_NAME) {
     Write-Error '中断: $OLD_PC_NAME が空'
   } elseif ($OLD_PC_NAME -notmatch '^[A-Za-z0-9]([A-Za-z0-9-]{0,13}[A-Za-z0-9])?$' -or $OLD_PC_NAME -match '^[0-9]+$') {
     Write-Error "中断: 使えない名前（15 文字まで。英字・数字・ハイフンで、先頭と末尾は英数字。数字だけは不可）: $OLD_PC_NAME"
   } elseif ($OLD_PC_NAME -eq $env:COMPUTERNAME) {
     "すでにこの名前: $OLD_PC_NAME"
   } else {
     Rename-Computer -NewName $OLD_PC_NAME
     "再起動の後に $OLD_PC_NAME になる"
   }
   ```

   - `再起動の後に <HOSTNAME> になる` が出ればよい
   - 効くのは、この節の手順 38 の再起動の後

1. 再起動する。

   ```powershell
   Restart-Computer
   ```

   - この節の手順 20〜37 の多くは、再起動の後に効く（この節の手順 1〜9 だけなら、サインインし直すだけでよい）
   - **次の手順は、起動してサインインしてから行う**

1. 元に戻ったことを確かめる。

   - Caps Lock を押すとランプが点き、大文字になる（この節の手順 28 を行ったとき）
   - 右クリックで新しい形のメニューが出る（この節の手順 2 を行ったとき）
   - エクスプローラー・タスクバー・スタートが既定の見た目に戻る（この節の手順 1・3〜5 を行ったとき）

---

## 補足

### 対象と検証環境

- **目的**: Windows 11 をインストールした直後に行う設定を、1 本の手順にまとめる
  - 更新（Windows Update・Microsoft Store）と、GitHub のコピーボタンでコピーしたブロックを Windows PowerShell に貼れるようにする設定（もとは別の手順書 `windows-powershell-paste.md`）
  - 入れるもの: [scoop](https://scoop.sh/)（コマンドラインのツール）、[UniGet UI](https://devolutions.net/unigetui/)（winget・scoop などのパッケージを画面で扱う）、PowerToys、PowerShell 7、WSL の AlmaLinux 10、Sysinternals の Autologon
  - 表示と入力: エクスプローラー・スタート・タスクバー・ダークモード・既定の端末・旧形式のコンテキストメニュー・IME の Ctrl+Space・Caps Lock を Ctrl に・US 配列
  - 整理: 標準アプリ・ウィジェット・自動で起動するアプリ・デスクトップのショートカット
  - PC 全体: PC の名前・長いパス・開発者モード・sudo・電源とロック・LAN のアダプターの省電力・デュアル ブートの時計
  - ネットワーク: LAN をプライベートに（もとは Windows の OpenSSH サーバーと Syncthing の Windows 11 の節にあった）・リモート デスクトップ・リモート アシスタンス・ping・配信の最適化
  - サインイン: Windows Hello だけのサインインを切る・自動サインイン
  - Git for Windows・Firefox・WezTerm・Claude Code・VirtualBox・WireGuard・HackGen Console NF は、AlmaLinux 10 と同じツールなので、それぞれの手順書の Windows 11 の節にある（[選択した方針](#選択した方針)）。この文書のリードから順に案内する
- **進め方**: 管理者の権限の要らないもの（自分のユーザーの設定と導入）を管理者ではない Windows PowerShell 5.1 で、PC 全体の設定を管理者の PowerShell で行い、最後に 1 回再起動する。再起動の後に、WSL のディストリビューションと自動サインインを入れる
- **状態**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**。手順 4〜7 の貼り付けの設定だけは、原因と直し方を実機で確かめた
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも、この文書の形のまま Windows で貼ってはいない
  - **確かめたこと**:
    - 貼り付けの設定（手順 4〜7・25・26。[付録](#付録-原因の確認と貼り付けの試験2026-10-03)）: 原因（コピーボタンの中身が LF だけで、conhost の右クリックの貼り付けが LF を Ctrl+Enter として送り、PSReadLine 2.0.0 の Ctrl+Enter が `InsertLineAbove`）と、手順 4 の 1 行で直ることを、実機の Windows 11 の conhost の窓で確かめた。手順 7 とロールバックの手順 15 は、もとの手順書（`windows-powershell-paste.md`）のときのブロックを、プロファイルを一時的なファイルに差し替えた実機の Windows PowerShell 5.1 で、文字コードの違うプロファイルを含めて流した。印を変えた今のブロックは、Linux の pwsh で模擬しただけ
    - LAN をプライベートにする手順 31 のブロックは、[Windows の OpenSSH サーバー](windows-openssh-server.md)の手順 5（実機で通した）にあったものから、規則を確かめる行を除いて移した
    - scoop・UniGet UI・Caps Lock・コンテキストメニュー（最初の版の 4 項目）: [配布物と資料の調査の付録](#付録-配布物と資料の調査2026-10-03)
    - 足した項目: Microsoft の文書（Microsoft Learn・サポートの記事・ポリシーの文書）、Microsoft の DSC のリソース（`microsoft/winget-dsc`）、winget の定義、各ツールのソース（PowerShell・sudo・WSL・winget・PSReadLine・UniGet UI など）、Microsoft Store の API（[設定の調査の付録](#付録-windows-11-の設定の調査2026-10-03)）
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。条件で止まるブロック（プロファイルの行、PC の名前、自動で起動するアプリ、リモート デスクトップなど）は、偽物のコマンドレットで模擬して流した（[ブロックの確認の付録](#付録-足した項目の-powershell-のブロックの確認2026-10-03)）
  - **確かめていないこと**:
    - Windows で貼ること（すべての手順）と、画面の文言（設定・ストア・UniGet UI・Autologon）
    - Microsoft の文書に無い値が効くこと（エクスプローラーの `LaunchTo`・`ShowRecent`・`ShowFrequent`、スタートの提案の値、`StartupApproved`、`DelayLockInterval`、`DevicePasswordLessBuildVersion`、`RealTimeIsUniversal`、キーボードの種類、旧形式のコンテキストメニュー、スタートの検索の Web の結果）と、効く時期
    - Home の PC、Modern Standby の PC でのロック、Microsoft アカウントでの自動サインイン、arm64 の Windows
- 下表は、本書が前提にしている環境（ほかの Windows の手順書の実機の記録と同じ PC を想定）

| 項目 | 値 |
|---|---|
| OS | Windows 11（[Windows の OpenSSH サーバー](windows-openssh-server.md)の PC は 25H2・26H2）。x64。Pro を想定（Home では手順 32 を飛ばす） |
| PowerShell | Windows PowerShell 5.1（管理者ではないものと、管理者として実行したもの） |
| ユーザー | Administrators の一員（Microsoft アカウントでもローカル アカウントでもよい） |
| winget | Windows 11 の「アプリ インストーラー」に入っているもの |
| scoop | 0.6.0（2026-09-30） |
| UniGet UI | 2026.3.0（winget の `Devolutions.UniGetUI`） |
| PowerToys | 0.101.2362.0（winget の `Microsoft.PowerToys`、自分のユーザー） |
| PowerShell 7 | 7.6.6.0（winget の `Microsoft.PowerShell`、MSIX） |
| Autologon | 3.10（winget の `Microsoft.Sysinternals.Autologon`） |
| WSL の AlmaLinux 10 | `AlmaLinux-10`（2026-10-03 のイメージは 10.2） |

貼り付けの設定（手順 4〜7・25・26）の原因を確かめた環境（[付録](#付録-原因の確認と貼り付けの試験2026-10-03)）:

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro（10.0.26300。x86_64 のノート PC） |
| PowerShell | Windows PowerShell 5.1.26100.9444（PSReadLine 2.0.0） |
| 窓 | conhost（`conhost.exe` で開いた窓。利用者の管理者の Windows PowerShell も conhost）。管理者でない窓は Windows Terminal 1.25.2733.0 |
| コピー | GitHub の Web のコードブロックのコピーボタン（Firefox） |

> [!NOTE]
> 環境固有の値は**変数**で書いてある。手順 24 の PowerShell の変数に 1 度だけ設定すれば、手順 25〜42 のコマンドはそのまま貼って実行できる。
>
> | 変数 | 設定する場所 | 意味 | 例 |
> |---|---|---|---|
> | `$PC_NAME` | 手順 24 | この PC の新しい名前（名前を変えるときに入れる。変えないなら空のままにして手順 27 を飛ばす） | `<HOSTNAME>` |
> | `$LAN_IF` | 手順 24（[ロールバック](#ロールバック)では手順 19、[Wake on LAN を使う（任意）](#wake-on-lan-を使う任意)では手順 2） | ほかの PC とつながる LAN の接続の名前（自動で入る） | `イーサネット` |
> | `$OLD_PC_NAME` | [ロールバック](#ロールバック)の手順 37 | 元の PC の名前（名前を戻すときに入れる） | `<HOSTNAME>` |
>
> 出力例・表の中の値は `<WIN_USER>`（Windows のユーザー名）/ `<HOSTNAME>`（コンピューター名）/ `<LAN_IF>` / `<名前>` / `<版>` のプレースホルダで書いてある。パスワード・回復キーはこの文書に載せない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 選択した方針

項目ごとに経路を比べた（2026-10-03 時点）。

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
| PowerToys の Keyboard Manager | 再起動が要らず、ユーザーごと。PowerToys が動いている間だけ効き、サインインの画面では効かず、管理者の窓には PowerToys を管理者で動かさないと効かない（Microsoft の文書） | 不採用（PowerToys は手順 11 で入れるが、Caps Lock には使わない） |
| Sysinternals の Ctrl2Cap | キーボードのフィルター ドライバーを入れる | 不採用（ドライバーを足さずに済む方法がある） |

**旧形式のコンテキストメニュー**

| 経路 | 状況 | 採否 |
|---|---|---|
| **`HKCU\Software\Classes\CLSID\{86ca1aa0-…}\InprocServer32` を空にする** | 自分のユーザーだけ、管理者は要らない。サポート外 | **採用** |
| 何もしない（「その他のオプションを確認」か Shift+右クリック） | 毎回 1 手間かかる | 不採用 |

**貼り付けの設定（手順 4〜7）**

- **PSReadLine の Ctrl+Enter を `AddLine` にする**（利用者の選択）
  - 窓の種類（conhost・Windows Terminal）と貼り方（右クリック・Ctrl+V）を選ばずに、コピーボタンのブロックをそのまま貼れる
  - プロファイルに書くので、窓を開くたびに貼り直さなくてよい
- **採らなかった案**
  - 管理者の Windows PowerShell を Windows Terminal で開く（Win+X の「ターミナル (管理者)」）: 設定は変えずに済むが、開き方を変える必要がある。既定の端末を Windows Terminal にしても（手順 18）、スタートメニューから管理者で開くと conhost になる（手順 18 の補足）
  - conhost の窓では Ctrl+V で貼る: 設定は変えずに済むが、右クリックで貼ると逆順になるのは残る（[ロールバック](#ロールバック)の後の貼り方として、その手順 15 に書いた）
  - ブロックを 1 行に書く: 手順書が読みにくくなる
  - 選んで Ctrl+C でコピーする: コピーボタンを使えない
  - コピーボタンの中身の改行を変える: 中身は GitHub が作る（改行は LF）
- **この文書にまとめた**: もとは別の手順書（`windows-powershell-paste.md`）で、Windows の PowerShell のブロックを貼る手順書の共有の前提だった。Windows のインストール直後に行うものなので、2026-10-03 に、この文書の手順 4〜7 にまとめた（実行ポリシーの手順も重なっていた）。ほかの手順書は、この文書の手順 4〜7 を前提にする

**LAN をプライベートに（手順 31）**

- もとは [Windows の OpenSSH サーバー](windows-openssh-server.md)の手順 5 と、[Syncthing の Windows 11 で使う](syncthing.md#windows-11-で使う)の手順 7 の両方で、同じ操作をしていた。インストール直後に 1 度行うものなので、ここへまとめ、2 つの手順書は確かめるだけにした
- 規則をパブリックにも広げる方法は採らない。持ち出した先でも、同じサブネットの相手に開くため（OpenSSH サーバーの[選択した方針](windows-openssh-server.md#選択した方針)）

**表示・整理の設定（手順 13〜22）**

- **レジストリに書けるものは書き、書けないもの・Microsoft の文書が無く効く時期が読めないものは画面で行う**
  - エクスプローラー・スタート・タスクバー・ダークモード・既定の端末・自動で起動するアプリは、自分のユーザーのレジストリに書く。多くは Microsoft の DSC のリソース（`microsoft/winget-dsc`）が同じ値を書いている
  - IME の Ctrl+Space（手順 19）は、レジストリの値が Microsoft の文書に無く、効く時期も分からないので、設定の画面を開いて変える
  - タスクバーとスタートのピン留め（手順 46）は、自分のユーザーで使える、サポートされたコマンドが無い（ポリシーとプロビジョニングだけ）ので、画面で外す
  - ウィジェットのボタン（`TaskbarDa`）は UCPD が守っていて書けないので、ウィジェットそのものを外す（手順 22）
- **標準アプリは、自分のユーザーから外す（`Remove-AppxPackage`）**: 管理者の権限が要らず、ストアからいつでも入れ直せる。PC に置かれた元（プロビジョニング）を外す方法は、ほかのユーザーにもかかるので採らない。そのため、機能の更新の後に戻ってくることがある
- **自動で起動するアプリは、消さずに止める**: タスク マネージャーと同じ所（`StartupApproved\Run`）に書き、いつでもタスク マネージャーから戻せるようにした

**PC 全体・ネットワーク・サインイン（手順 27〜42・52）**

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| PC の名前 | `Rename-Computer`（15 文字までをブロックで確かめる） | `-Force`: 15 文字を超える名前を黙って短くする |
| sudo | `sudo config --enable normal`（インライン。利用者の選択） | 既定の `forceNewWindow`: Microsoft が勧める形だが、新しい窓が開く |
| 電源 | `powercfg`（電源につないでいる間だけ眠らない） | バッテリーのときも眠らない: 持ち出したノート PC の電池が減る |
| 放置したときのロック | 眠りから戻ったときの `CONSOLELOCK` と、Modern Standby の `DelayLockInterval` | ポリシー（`InactivityTimeoutSecs`）: ロックさせる側の設定 |
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
- **scoop の `git` は入れない**: git は [git.md](git.md#windows-11-で-git-for-windows-を入れる) の Git for Windows（`C:\Program Files\Git`）にそろえる。ほかの手順書（OpenSSH サーバーの既定のシェル、Claude Code）がその場所を使う。scoop は `PATH` の `git` を使い、git 無しで入れた scoop も、Git for Windows を入れた後の `scoop update` で git の形に直る（scoop 0.6.0 の `libexec/scoop-update.ps1`）

**窓と再起動**

- **管理者ではない PowerShell と管理者の PowerShell を分けた**
  - scoop のインストーラは、管理者の PowerShell では止まる。scoop・UniGet UI・PowerToys（自分のユーザーへの導入）と、自分のユーザーの表示の設定は、どれも管理者の権限が要らない
  - PC 全体の設定（`HKLM`・ファイアウォール・電源・機能）と、管理者しか書けない `HKCU\Software\Policies` だけ、管理者の PowerShell で行う
  - そのため、[Windows の OpenSSH サーバー](windows-openssh-server.md)の SSH のセッション（Administrators の一員なら管理者の権限で動く）には貼らない
- **再起動を 1 回にまとめた**: Scancode Map・PC の名前・キーボードの種類・WSL の機能は再起動、エクスプローラーの設定はエクスプローラーの起動し直しで効く。再起動 1 回で全部効く（hackgen.md の Windows のフォントも、サインインし直す代わりにこの再起動で効く）。Windows Update の再起動は、その前の手順 1 で済ませる
- **Windows PowerShell 5.1 にそろえた**: Windows 11 に最初からあり、ほかの Windows の手順書とも同じ。実行ポリシーとプロファイルは PowerShell 7 と別に持つので、5.1 の値を変える

### 注意点

- **重ねると、触れる人がそのまま使える PC になる**: 放置でロックしない（手順 29）・自動サインイン（手順 52）は、PC の前にいる人をこのユーザー（Administrators の一員）として通す。インラインの sudo（手順 28）・リモート デスクトップ（手順 32）・Windows Hello 以外のサインイン（手順 36）は、このユーザーのパスワードを知る人の入口を増やす。人が触れる場所にある PC では、手順 29・52 は行わない
- **Caps Lock の働きは無くなる**: Caps Lock を左 Ctrl にするだけで、Caps Lock をほかのキーに割り当てない。大文字を続けて打つときは Shift を押す
- **Scancode Map は、すべてのユーザー・すべてのキーボードにかかる**: PC 全体の設定。この PC にサインインするほかのユーザーと、つないだ外付けのキーボードにもかかる
- **JIS 配列では「英数」のキーが Ctrl になる**: 日本語の配列のキーボードの Caps Lock は「英数」のキー（スキャン コード `0x3A`）なので、そのキーの IME の働き（英数への切り替え）も無くなるはず（確かめていない）
- **リモート デスクトップと Scancode Map**: Microsoft の文書は、Scancode Map がターミナル サービスでは正しく働かないことがあると書いている。この PC にリモート デスクトップでつないだとき、つないだ側の PC でつないだときの効き方は確かめていない
- **Ctrl+Space はアプリでは使えなくなる**: IME が受け取るので、PowerShell（PSReadLine の `MenuComplete`）・VS Code・Excel などの Ctrl+Space は効かなくなるはず（手順 19 の補足）
- **管理者の PowerShell は conhost の窓で開く**: 既定の端末を Windows Terminal にしても（手順 18）、管理者として開いた PowerShell は conhost の窓になる。右クリックで貼れるのは、手順 4〜7 のプロファイルの設定による
- **外したアプリと提案は、機能の更新で戻ることがある**: 自分のユーザーから外したアプリ（手順 21・22）は、PC に置かれた元が残るので、Windows の大きな更新の後に戻ってくることがある。手順 15・20〜22 を貼り直す
- **サポート外の設定**: 旧形式のコンテキストメニュー（手順 14）は Microsoft が説明していない設定で、Windows の更新で効かなくなることがある。そのときは、手順 5 の `ClassicMenu` と手順 14 の `reg.exe query` で、設定が残っているかを見る。手順 13・15・20 の値の多くも、Microsoft の文書には値が書かれておらず、広く使われているもの
- **SSH のセッションで scoop のツールを使うとき**: sshd の緩和策（RedirectionGuard）で、一般ユーザーの scoop が作るジャンクションをたどれない。[Windows の OpenSSH サーバー](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の任意節を、`scoop install`・`scoop update` の後に貼る
- **PowerShell 7 で scoop を使うとき**: 実行ポリシーは Windows PowerShell 5.1 とは別に持つ。UniGet UI は、PowerShell 7 があればそれで scoop を動かす（`-ExecutionPolicy Bypass` 付き）
- **PowerShell 7 のプロファイルは別**: 手順 7 の行は Windows PowerShell 5.1 のプロファイルにだけ書く。PowerShell 7（手順 12）は `Documents\PowerShell\Microsoft.PowerShell_profile.ps1` を読み、貼り付けの設定の原因を確かめた PC の PowerShell 7.6.6（PSReadLine 2.4.5）でも Ctrl+Enter は `InsertLineAbove` だった（もとの手順書 `windows-powershell-paste.md` の注意点の記録）。この文書の手順書群は、Windows PowerShell 5.1 に貼る
- **scoop のアプリは自分のユーザーだけ**: `~\scoop` に入るので、ほかのユーザーには見えない。scoop の `--global` は管理者が要り、本書では使わない
- **貼ったブロックは、Enter を押すまで動かない**: コピーボタンの中身は末尾に改行が無いため。手順 4〜7 の後の conhost の窓では、ブロック全体が 1 つの入力になり、Enter で 1 回で動く
- **Ctrl+Enter で上に行を作る操作（`InsertLineAbove`）は使えなくなる**: 下に行を作る Shift+Ctrl+Enter（`InsertLineBelow`）と、Shift+Enter（`AddLine`）はそのまま
- **このユーザーの Windows PowerShell のコンソールの窓すべてに効く**: 管理者の窓も同じプロファイルを読む。SSH でログインしたセッションの Windows PowerShell で、SSH のクライアントから貼ったときの動きは確かめていない

### 参照

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
- [hackgen.md](hackgen.md) — HackGen Console NF（AlmaLinux 10 と Windows 11）
- [Windows の OpenSSH サーバー](windows-openssh-server.md) — 同じ PC で使うことの多い手順書（scoop のツールを SSH のセッションで使う任意節。LAN がプライベートである前提）

---

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
  - ほかの規則の指摘は、手順 8 の `Invoke-Expression`（公式のインストーラの方法なので、そのまま）と、ASCII でない文字を含むファイルの BOM（貼るので関係が無い）だけ
  - わざと PowerShell 7 だけの書き方（`??`、`Get-Content -AsByteStream`、`ForEach-Object -Parallel`、`Join-Path -AdditionalChildPath`）を入れたファイルでは、それぞれ指摘が出た
- `(Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass'`（手順 6）は、列挙の値と文字列を比べて、`RemoteSigned` で `False`、`Restricted` で `True` になった

**手順 39 と[ロールバック](#ロールバック)の手順 28 のブロック**を、管理者の判定を `$true` に替え、レジストリ（`Get-ItemProperty`・`New-ItemProperty`・`Remove-ItemProperty`）を値を覚えておく偽物にして、`Scancode Map` が無いとき・本書の値のとき・別の値（`00 00 00 00 00 00 00 00 02 00 00 00 00 00 5B E0 00 00 00 00`）のときで流した:

| ブロック | 無い | 本書の値 | 別の値 |
|---|---|---|---|
| 手順 39 | 書き（1 回）、`Scancode Map = 00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00` | 書かずに同じ行 | `中断: 別の Scancode Map がある（…）` で止まり、書かない |
| ロールバックの手順 28 | `Scancode Map は無い` | 消して `Scancode Map を消した` | `中断: 本書の値ではない Scancode Map がある（…）` で止まり、消さない |

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（手順 5 の判定、scoop のインストーラ、winget の表示、UniGet UI の画面）
1. `HKCU` の CLSID の設定で、今の Windows 11（25H2・26H2）のエクスプローラーが旧形式のメニューを出すこと
1. Scancode Map で、Caps Lock が Ctrl になること（JIS 配列のキーボード、リモート デスクトップでつないだときも）
1. 更新（scoop・UniGet UI）とロールバック、arm64 の Windows

---

### 付録: 原因の確認と貼り付けの試験（2026-10-03）

この付録は、もとの手順書 `docs/windows-powershell-paste.md`（2026-10-03 にこの文書へまとめて消した）の付録を移したもの。手順の番号だけ、この文書の番号に付け替えた（当時の手順 1〜7 は今の手順 4・5・6・7・23・25・26、当時のロールバックの手順 1・2 は今の[ロールバック](#ロールバック)の手順 15・16）。試験したブロックは当時のもの（プロファイルの行の印は `# windows-powershell-paste.md`。今の手順 7 とロールバックの手順 15 は、印を変え、古い印の行も見つけるようにした。その確認は[ブロックの確認の付録](#付録-足した項目の-powershell-のブロックの確認2026-10-03)）。

**利用者の観察**: Firefox で開いた GitHub の [RDP をロックせずに切断](windows-rdp-disconnect.md)の PowerShell のブロックを、コピーボタンでコピーして、スタートメニューから管理者として開いた Windows PowerShell（conhost の窓）に右クリックで貼ると、行が逆順になった。選んで Ctrl+C でコピーしたもの、管理者でない Windows PowerShell の窓、conhost の窓に Ctrl+V で貼ったものは、元の順に入った。

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
| LF だけ（末尾に改行無し） | `-Command` で手順 4 の 1 行 | 元の順（`}` が最後の行） | `1 行目` / `2 行目` / `3 行目` |
| LF だけ（末尾に改行無し） | 同じ行（印のコメント付き）を書いたファイルを `-Command` の `.` で読ませた | 元の順 | `1 行目` / `2 行目` / `3 行目` |
| CR LF（末尾に改行あり） | 無し | — | `1 行目` / `2 行目` / `3 行目` |
| CR LF（末尾に改行あり） | `-Command` で手順 4 の 1 行 | — | `1 行目` / `2 行目` / `3 行目` |

**対話でない起動**: 標準入力をリダイレクトした `powershell.exe -NoProfile -Command "Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine; 'ok'"` は、エラー無しで `ok` を出した。

**`Add-Content` の書き足し方**: Windows PowerShell 5.1 で、末尾に改行の無いファイル（`Set-Alias ll Get-ChildItem`）に `Add-Content` で 1 行を足すと、`Set-Alias ll Get-ChildItemX-LINE` と最後の行につながった。手順 7 のブロックは、そのときに行の前へ CR LF を付ける。

**手順 7 とロールバックの手順 15 のブロック**: 当時の文書から `powershell` のブロックを抜き出し（リストの字下げを外した）、Windows PowerShell 5.1 で、`$PROFILE` を一時的なディレクトリの `WindowsPowerShell\Microsoft.PowerShell_profile.ps1` に差し替えて `Invoke-Expression` で流した。どの場合も手順 7 を 2 回（2 回目は `すでにある:`）、ロールバックの手順 15 を 2 回（2 回目は `その行は無い:` か `プロファイルが無い:`）流した。既存のプロファイルの中身は、日本語のコメントと `Set-Alias ll Get-ChildItem` の 2 行:

| 既存のプロファイル | 手順 7 の後 | ロールバックの手順 15 の後 |
|---|---|---|
| 無い | `足した:`。ASCII の 1 行（93 バイト） | `消した:`（ファイルが消えた） |
| 空のファイル | 同じ | `消した:` |
| UTF-16 LE（BOM あり） | 先頭は `FF FE` のまま。足した行は 3 行目 | `その行だけ消した:`。前と同じバイト |
| UTF-8（BOM あり） | 先頭は `EF BB BF` のまま。足した行は 3 行目 | 前と同じバイト |
| UTF-8（BOM 無し）、末尾に改行無し | 足した行は 3 行目（前に CR LF を付けた）。5.1 の `Get-Content` では日本語が化けて見えた（ANSI として読む）が、バイトは変わらない | 日本語を含め前と同じバイトに、手順 7 で付けた CR LF だけが残った |
| Shift_JIS | 足した行は 3 行目 | 前と同じバイト |
| UTF-16 LE・UTF-8（BOM あり）で、手順 7 の行だけ | `すでにある:` | `消した:`（ファイルが消えた） |
| UTF-16 LE・UTF-8（BOM あり）で、1 行目が手順 7 の行、2 行目が `Set-Alias` | — | `その行だけ消した:`。BOM と `Set-Alias` の行だけが残った |

最初に書いたロールバックの手順 15 は、正規表現が `(?m)^` と行だけだったので、BOM の直後（ファイルの 1 行目）にある行を見つけられず、BOM のあるファイルで `その行は無い:` を出した。BOM を許して残すように直し、上の表はすべて直した後のもの。

**構文**: 当時の文書の `powershell` のブロック 8 個を、Windows PowerShell 5.1 の `[System.Management.Automation.Language.Parser]::ParseInput` に通した（構文の誤りは 0）。

---

### 付録: Windows 11 の設定の調査（2026-10-03）

インストール直後の作業をこの文書にまとめたとき（2026-10-03）に、Windows を動かせない環境（クラウドの Linux のコンテナ）で、文書・ソース・定義を読んだ記録。確かさは、Microsoft の文書かソース（「文書」）、Microsoft の書いたコードや配布物の中身（「コード」）、それ以外の広く使われている情報（「広く」）で書く。

**自分のユーザーの設定（手順 13〜22）**

- エクスプローラー（手順 13）: `HideFileExt`・`Hidden`・`Start_TrackDocs` は、Microsoft の DSC のリソース `microsoft/winget-dsc`（コミット `8a8387e`）の `Microsoft.Windows.Developer` が同じ値を書く（コード）。`Start_TrackDocs` を 0 にするのは、Microsoft Learn の「Manage connections from Windows operating system components to Microsoft services」の 33 節にもある（文書）。`LaunchTo`・`ShowRecent`・`ShowFrequent` は広く
- スタートと提案（手順 15）: 設定の画面の文言は Microsoft のサポートの記事（文書）。値（`Start_IrisRecommendations`・`Start_AccountNotifications`・`ContentDeliveryManager` の `SubscribedContent-*`・`SystemPaneSuggestionsEnabled`・`SilentInstalledAppsEnabled`・`UserProfileEngagement\ScoobeSystemSettingEnabled`）は広く。2025 年の終わりのスタートの作り直しで足された切り替えの値は、見つからなかった
- スタートの検索の Web の結果（手順 37）: `HKCU\Software\Policies\Microsoft\Windows\Explorer` の `DisableSearchBoxSuggestions` は、ポリシーの文書（`WindowsExplorer.admx`）では「エクスプローラーの検索ボックスに最近の検索を出さない」。スタートの検索の Web の結果が消えるのは広く。`HKCU\Software\Policies` は、管理者でないと書けない（Microsoft のフォーラムの回答）
- タスクバー（手順 16）: `TaskbarAl`・`ShowTaskViewButton`・`SearchboxTaskbarMode`（0 が消す、1 がアイコン、2 が検索ボックス、3 がアイコンとラベル）は DSC の `Taskbar`（コード）。ポリシーの `ConfigureSearchOnTaskbarMode` は番号の意味が違う（文書）。`ShowSecondsInSystemClock` は 22H2 の 2023 年 5 月のプレビューの更新（KB5026446）から（広く）。`TaskbarDa` は UCPD（`ucpd.sys`）が守っていて、`powershell.exe`・`reg.exe` などからの書き込みは拒まれる（広く。ドライバーを解析した記事）
- ダークモード（手順 17）: `AppsUseLightTheme`・`SystemUsesLightTheme` は DSC の `Microsoft.Windows.Settings` が書き、`WM_SETTINGCHANGE`（`ImmersiveColorSet`）を送る（コード）
- 既定の端末（手順 18）: `HKCU\Console\%%Startup` の GUID は Windows Terminal の文書の `group-policy.md`（文書）。22H2 以降の既定（「Windows に任せる」）は Microsoft のサポートの記事（文書）。管理者のコンソールが引き渡されないことは、microsoft/terminal の #13392（「管理者のコマンド ラインの受け手として登録できる端末は無い」）と #10276・#10682・#15126 で、開いたまま
- IME（手順 19）: 設定の画面（`ms-settings:regionlanguage-jpnime`）は Microsoft のサポートの記事（文書）。レジストリの値は、ある開発者が画面の前後で見比べた記録だけ（`cuzic/awase`）。Ctrl+Space を Windows が使うのは中国語の IME だけ（Microsoft のキーボード ショートカットの文書）
- 自動で起動するアプリ（手順 20）: `StartupApproved\Run` の先頭の 1 バイト（2 が起動、3 が停止）は広く（UniGet UI のインストーラも同じ所に書く）。Teams の起動のタスクの名前 `TeamsTfwStartupTask` は、Teams の MSIX の `AppxManifest.xml`（26198.304.4946.9672）にある（コード）。`State` の値は `StartupTaskState`（文書）。UniGet UI を winget で入れると、`Run` に `WingetUI`（`--daemon`）ができる（winget の定義が `/NoRunOnStartup` を渡さない。インストーラの定義 `UniGetUI.iss`）
- 標準アプリ（手順 21・22）: パッケージの名前・パッケージ ファミリー名・ストアの ID は、Microsoft Store の API（`storeedgefd.dsx.mp.microsoft.com`）で確かめた（文書）。「Microsoft 365 Copilot」は `Microsoft.MicrosoftOfficeHub`（`9WZDNCRD29V9`）で、Copilot（`Microsoft.Copilot`、`9NHT9RB2F4HD`）とは別のパッケージ。自分のユーザーから外しただけのアプリは機能の更新で戻りうる（「Remove provisioned apps during update」。文書）
- PowerToys（手順 11）: winget の定義 0.101.2362.0 に、自分のユーザーのインストーラ（`PowerToysUserSetup`、管理者の指定無し）と PC 全体のインストーラ（`elevatesSelf`）がある。形式は Burn、渡す引数は `/quiet /norestart`
- ピン留め（手順 46）: 自分のユーザーで使える、サポートされたコマンドは見つからなかった。Microsoft の文書の方法は、タスクバーのレイアウトの XML、`ConfigureStartPins`（24H2 の KB5062660 から `applyOnce`）などのポリシーとプロビジョニングだけ

**PC 全体の設定（手順 27〜42）**

- PC の名前（手順 27）: `Rename-Computer` は、15 文字を超える名前で `ShouldContinue` の問いを出し（`-Force` で出さない）、今と同じ名前で `NewNameIsOldName` のエラーを出す（PowerShell のソースの `Computer.cs`。5.1 は文書の文言が同じ）。名前の決まりは Microsoft Learn の「Naming conventions in Active Directory」（文書）
- 長いパス・開発者モード（手順 28）: `LongPathsEnabled` と `AllowDevelopmentWithoutDevLicense` は Microsoft Learn（「Maximum Path Length Limitation」と「Developer Mode」）の値（文書）
- sudo（手順 28）: 24H2 から（文書）。`sudo config --enable` の 3 つの形と、インラインの危うさは Microsoft Learn（文書）。レジストリの値（`HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo` の `Enabled`。0〜3）は microsoft/sudo の `helpers.rs`（コード）。Home で使えるかは書かれていない
- 電源（手順 29）: `powercfg` の別名（`SUB_BUTTONS`・`LIDACTION`・`SUB_NONE`・`CONSOLELOCK`）と値は、Microsoft Learn の電源の設定の文書（文書）。休止状態を切ると高速スタートアップのファイルも無くなる（文書から言えること。1 文で書いた文書は無い）。`DelayLockInterval` は広く（Microsoft の文書は見つからなかった）。S3 の PC では、画面が消えるだけではロックしない（眠り・パスワード付きのスクリーン セーバー・`InactivityTimeoutSecs`・動的ロックだけがロックする。文書からの推論）
- アダプター（手順 30）: `Set-NetAdapterPowerManagement` は `-NoRestart` が無いとアダプターを起動し直す（文書）。`AllowComputerToTurnOffDevice` は WMI のクラスの文書では読み取り専用で、変えて渡す形は広く。この項目を外すと、Windows が任せる Wake on LAN も効かなくなる（Windows 7 の頃のサポートの記事 KB2740020。2026-05 に消え、MicrosoftDocs の履歴から読んだ）
- リモート デスクトップ（手順 32）: Home はつながれる側になれない（文書）。`fDenyTSConnections`・`UserAuthentication`、規則のグループ `@FirewallAPI.dll,-28752` と規則の名前 `RemoteDesktop-UserMode-In-TCP` は、Azure の VM の切り分けの文書と無人インストールの文書（文書）。画面でオンとオフにし直したときに規則のプロファイルが戻るかは、分からなかった
- リモート アシスタンス（手順 33）: `fAllowToGetHelp`（無人インストールの文書）。規則のグループ `@FirewallAPI.dll,-33002` は、Windows の `racpldlg.dll` の文字列にある（コード。Learn には無い）
- ping（手順 34）: `New-NetFirewallRule` の `-Protocol ICMPv4 -IcmpType 8` と `ICMPv6`・`128`（文書）
- 配信の最適化（手順 35）: 既定は LAN（配信の最適化の文書。ポリシーの文書は 0 と書いていて食い違う）。`Set-DODownloadMode`・`Get-DODownloadMode`（文書）
- Windows Hello（手順 36）: `DevicePasswordLessBuildVersion` は広く（Microsoft の文書は見つからなかった）
- Edge のショートカット（手順 38）: `RemoveDesktopShortcutDefault`（Edge Update 1.3.155.1 から）と、`CreateDesktopShortcutDefault` が入っていると効かないことは、Edge Update のポリシーの文書（文書）
- 時計（手順 40）: `RealTimeIsUniversal` は Microsoft の文書に無い。Arch Linux の wiki は DWORD を勧める（QWORD の古い勧めは消えた）
- キーボードの種類（手順 41）: US 配列の 4 つの値は、Microsoft の日本の社員のブログ（Learn の archive の「英語キーボードを快適に使う」）。JIS の値は広く
- WSL（手順 42・50）: `--no-distribution` は Windows 11 では仮想マシン プラットフォームだけを入れる（WSL のソースの `WslInstall.cpp`）。`AlmaLinux-10` は `DistributionInfo.json`（2026-10-03、10.2.20260526.0）。最初の起動のユーザーの作成は AlmaLinux の `wsl-images` の `oobe`（uid 1000、`wheel`、`systemd=true`）
- Autologon（手順 52）: winget の定義 3.10 は版の付かない `AutoLogon.zip` を取り、2026-10-03 は sha256 が一致した。パスワードは LSA のシークレットに置く（Microsoft Learn の Autologon と「Protecting the automatic logon password」）。Microsoft アカウントの `Domain` の入れ方は分からなかった
- PowerShell 7（手順 12）: 7.6.0 から winget は MSIX を既定で入れ、7.7.0 から MSI は無くなる（Microsoft Learn の Windows への入れ方）。winget の選び方（MSIX が MSI より先）は winget のソースの `ManifestComparator.cpp`。PowerShell 7.6.6 の PSReadLine は 2.4.5 で、Ctrl+Enter は `InsertLineAbove`（PSReadLine の `KeyBindings.cs`）

---

### 付録: 足した項目の PowerShell のブロックの確認（2026-10-03）

インストール直後の作業をこの文書にまとめた後の、全部のブロックを、Linux（クラウドのコンテナ）の PowerShell 7.6.6 と PSScriptAnalyzer 1.25.0 で確かめた。Windows では貼っていない。

**構文と Windows PowerShell 5.1 との互換**:

- この文書の `powershell` のブロック 90 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた
  - `Set-ItemProperty` の `-Type` が 5.1 に無いという指摘が 54 個出た。`-Type` はレジストリのプロバイダーが足す動的なパラメーターで、5.1 の `Set-ItemProperty` の文書にもある（`reference/5.1/Microsoft.PowerShell.Management/Set-ItemProperty.md` の「This is a dynamic parameter made available by the Registry provider」）。互換の検査は動的なパラメーターを見ないので、指摘は当たらない
  - ほかは、手順 8 の `Invoke-Expression`（公式のインストーラの方法）と、1 つの変数だけのブロック（手順 24・ロールバックの手順 37 の `$PC_NAME`・`$OLD_PC_NAME`）の「代入して使っていない」だけ
- 手順 7 とロールバックの手順 15 の正規表現と文字列、手順 27 の名前の正規表現も、この構文解析器で読めた

**偽物のコマンドレットで流したブロック**（Linux の pwsh。レジストリは、値を覚えておく偽物の `Set-ItemProperty`・`Get-ItemProperty`・`Get-Item`・`Test-Path`・`New-Item` にした）:

| ブロック | 流した場合 | 結果 |
|---|---|---|
| 手順 7（プロファイルに足す） | 無い・空・UTF-8（BOM の有無）・Shift_JIS の既存のファイル、新しい印の行がある、古い印（`# windows-powershell-paste.md`）の行がある、両方ある | 無いときだけ `足した:`、2 回目と印の行があるときは `すでにある:` |
| ロールバックの手順 15（プロファイルから消す） | 上の各場合と、UTF-16 LE、BOM の直後の行、新旧の両方の行。正規表現の BOM は、もとの手順書と同じく `\uFEFF` などの ASCII の書き方（文字をそのまま書くと、コピーと貼り付けで落ちうる） | どちらの印の行も消え、ほかの行と BOM はバイトのまま残った。残りが BOM と空白だけならファイルを消した。UTF-8（BOM 無し、末尾に改行無し）では、手順 7 で付けた CR LF だけが残った（もとの手順書の付録と同じ） |
| 手順 27（PC の名前） | 空、`my-pc`、今と同じ名前（大文字と小文字の違いも）、16 文字以上、数字だけ、先頭か末尾がハイフン、`_` を含む、1 文字 | 空と使えない名前は `中断:`、同じ名前は `すでにこの名前:`、ほかは `Rename-Computer -NewName <名前>` を 1 回呼んだ |
| ロールバックの手順 37（名前を戻す） | 空、今と同じ名前、別の名前、16 文字以上、数字だけ | 空と使えない名前は `中断:`、同じ名前は `すでにこの名前:`、ほかは `Rename-Computer` を 1 回（`-Force` は付けない） |
| 手順 20（自動で起動するアプリ） | `Run` に `OneDrive`・`MicrosoftEdgeAutoLaunch_ABC`・`WingetUI`、Teams の起動のタスクあり。もう 1 回は `OneDrive` だけで Teams 無し | `OneDrive` と Edge に `03 00 00 00` と 8 バイトの日時を書き、Teams の `State` を 1 にした。一覧は 2 つが `止めている`、`WingetUI` が `起動する`。2 回目は `OneDrive` だけを止めた |
| ロールバックの手順 8 | 上の後 | 2 つを `02` と 11 バイトの 0 に、Teams を 2 に戻した |
| 手順 21・22（標準アプリ・ウィジェット） | 11 個のうち 3 個と Copilot だけが入っている。ウィジェットは無い場合とある場合 | 入っている 3 個だけ `Remove-AppxPackage` に渡し、ほかは `無い:`。Copilot には触れなかった |
| 手順 30・ロールバックの手順 34（アダプター） | `$LAN_IF` が空、`Enabled` のアダプター、`Unsupported` のアダプター | 空は止まり、`Unsupported` は `対象外:`。ほかは `AllowComputerToTurnOffDevice` を `Disabled`（戻すときは `Enabled`）にして、`-NoRestart` 付きで渡した |
| 手順 32（リモート デスクトップ） | `EditionID` が `Core`・`CoreSingleLanguage`・`Professional` | Home の 2 つは `中断:` で何も書かず、`Professional` だけ 2 つの値を書いて規則を `-Profile Private` にした |
| 手順 38（ショートカット） | すべてのユーザーのデスクトップに `Microsoft Edge.lnk` があり、自分のデスクトップに `UniGetUI.lnk` が無い。2 回 | ポリシーを書き、1 回目は Edge を `消した:`、UniGet UI を `無い:`。2 回目はどちらも `無い:` |
| OpenSSH サーバーの手順 5・Syncthing の Windows 11 の手順 7（LAN がプライベートかを確かめる） | `$LAN_IF` が空、パブリック、プライベート | 空とパブリックは止まり（Syncthing は規則を作らない）、プライベートだけ規則を確かめた（作った） |

**Wake on LAN の 1 行**（任意節の手順 7）: Linux の Python 3.11 で、MAC アドレスの例を入れて流し、102 バイト（`FF` が 6 個と MAC が 16 回）のパケットを送れた（受け取る側は確かめていない）。

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（画面の手順と、設定・ストア・UniGet UI・Autologon の文言を含む）
1. Microsoft の文書に無いレジストリの値（[状態](#対象と検証環境)の「確かめていないこと」）が、24H2・25H2・26H2 で効くこと
1. 手順 30 の `AllowComputerToTurnOffDevice` を変えて渡す形が、今の Windows 11 の `Set-NetAdapterPowerManagement` で効くこと
1. 手順 32 の後に、設定の画面でリモート デスクトップをオンとオフにしたとき、規則のプロファイルが戻るか
1. Modern Standby の PC で、手順 29 の後に放置してもロックしないこと
1. Microsoft アカウントでの自動サインイン（手順 52）と、Wake on LAN（任意節）
1. 更新とロールバック、Home の PC、arm64 の Windows
