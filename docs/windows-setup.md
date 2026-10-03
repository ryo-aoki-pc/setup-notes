# Windows 11 の初期設定の手順（scoop・UniGet UI・Caps Lock を Ctrl に・旧形式のコンテキストメニュー）

## 実施手順

> [!IMPORTANT]
> - **すべて、この PC のデスクトップで行う**。SSH のセッションには貼らない（Administrators の一員の SSH のセッションは管理者の権限で動くので、手順 4 の scoop のインストーラが止まる）
> - 手順 1 で**管理者ではない** Windows PowerShell（5.1）を開き、手順 2〜7・9 をそこに貼る。手順 10 で**管理者の** Windows PowerShell を開き、手順 11・12 をそこに貼る
> - ログインするユーザーは Administrators の一員（手順 11 の Caps Lock の設定は、PC 全体の設定に書く）
> - 前提: [Windows PowerShell の貼り付けの設定](windows-powershell-paste.md)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ）。通していなければ、ブロックは Ctrl+V で貼る
> - **手順 12 で再起動する**。Caps Lock とコンテキストメニューは、再起動の後に効く
> - **手順 8・13・14 は画面で行う**（UniGet UI の起動、キーと右クリックの確認）

- 上から順にコードブロックを貼る。変数は無い（読者が書き換える値は無い）
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 項目ごとの手順: 共通は手順 1・2、scoop は手順 3〜6、UniGet UI は手順 7・8、旧形式のコンテキストメニューは手順 9・14、Caps Lock は手順 10〜13
  - 要らない項目の手順は飛ばしてよい。UniGet UI は scoop の後に入れる（手順 7 で、UniGet UI の scoop の検索に使う道具を scoop で入れる）
- 手順の後: 以後は[更新](#更新)・[ロールバック](#ロールバック)
- フォントの HackGen Console NF は、[hackgen.md の Windows 11 で使う](hackgen.md#windows-11-で使う)で入れる（AlmaLinux 10 と同じ手順書にまとめてある）。この文書の手順 12 の再起動より前に入れれば、そちらのサインインし直す手順は要らない
- 関連する手順書: git の設定は [git.md](git.md)、scoop で入れたツールを SSH のセッションで使うのは [Windows の OpenSSH サーバー](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)

> [!WARNING]
> **この手順書は Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、パッケージの定義、scoop のインストーラと UniGet UI のソース、Microsoft の文書、Linux の PowerShell 7 での構文と模擬の実行だけ（[対象と検証環境](#対象と検証環境)）。

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする（手順 3 の実行ポリシーは、5.1 と 7 で別々に持つ）

1. 管理者ではないことと、今の状態を確かめる。

   ```powershell
   $sm = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout' -ErrorAction SilentlyContinue).'Scancode Map'
   [pscustomobject]@{
     Admin       = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Scoop       = (Get-Command scoop -ErrorAction SilentlyContinue).Source
     Winget      = (Get-Command winget -ErrorAction SilentlyContinue).Source
     Git         = (Get-Command git -ErrorAction SilentlyContinue).Source
     ClassicMenu = Test-Path -LiteralPath 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
     ScancodeMap = if ($sm) { ($sm | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' } else { '' }
   } | Format-List
   Get-ExecutionPolicy -List | Format-Table -AutoSize
   ```

   - `Admin : False` が出ればよい。`True` なら管理者の PowerShell に貼っている。閉じて手順 1 から
   - `Winget` に `…\WindowsApps\winget.exe` の場所が出ればよい。空なら、Microsoft Store で「アプリ インストーラー」を更新してから始める
   - `Scoop` に場所が出たら、scoop はもう入っている。手順 3・4 は飛ばす
   - `Git` に場所が出たら、手順 6 は飛ばす
   - `ClassicMenu` は旧形式のコンテキストメニューの設定があるか（無ければ `False`）
   - `ScancodeMap` が空でなければ、キーの割り当てがもうある。その値を控える（手順 11 は、違う値があれば止まる）
   - 最後の表の `CurrentUser` の値を控える（[ロールバック](#ロールバック)の手順 5 で使う。何も設定していなければ `Undefined`）

   <details>
   <summary>補足: 見ているもの</summary>

   - `Admin` は、この PowerShell が管理者の権限で動いているか（UAC で昇格しているか）。Administrators の一員でも、普通に開いた PowerShell は `False` になる
   - `ClassicMenu` は、手順 9 で作るキー（`HKCU:\Software\Classes\CLSID\{86ca1aa0-…}`）があるか
   - `ScancodeMap` は、手順 11 で書く値（`HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout` の `Scancode Map`）を 16 進で並べたもの。読むだけなら管理者は要らない
   - `Get-ExecutionPolicy -List` は、範囲（`MachinePolicy`・`UserPolicy`・`Process`・`CurrentUser`・`LocalMachine`）ごとの実行ポリシー。上の範囲ほど優先される

   </details>

1. スクリプトの実行ポリシーを RemoteSigned にする。

   ```powershell
   if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force }
   Get-ExecutionPolicy
   ```

   - `RemoteSigned`（もとから `Unrestricted` か `Bypass` だった PC では、その値）が出ればよい
   - 今の値が `RemoteSigned`・`Unrestricted`・`Bypass` のどれかなら、何も書かない
   - 「より限定的なスコープで定義されたポリシーによって上書きされます」の旨のエラーが出たら、グループ ポリシー（`MachinePolicy` か `UserPolicy`）で決められている。その PC では scoop を入れられない

   <details>
   <summary>補足: 実行ポリシーと scoop</summary>

   - Windows 11 の既定の実行ポリシーは `Restricted`（スクリプトを動かさない）
   - `scoop` のコマンドは PowerShell のスクリプト（`~\scoop\shims\scoop.ps1`）なので、`RemoteSigned`・`Unrestricted`・`Bypass` のどれかでないと動かない。scoop のインストーラも、これを確かめて止まる（[付録](#付録-配布物と資料の調査2026-10-03)）
   - `RemoteSigned` は、この PC で書いたスクリプトはそのまま動かし、インターネットから取ったファイル（Mark of the Web の付いたもの）には署名を求める
   - `-Scope CurrentUser` は自分のユーザーだけの設定で、管理者の権限は要らない。`-Force` は確認の問い（`[Y] はい` など）を出さないため
   - PowerShell 7 は、実行ポリシーを Windows PowerShell 5.1 とは別に持つ。PowerShell 7 で scoop を使うときは、そちらの `Get-ExecutionPolicy` も見る

   </details>

1. scoop を入れる。

   ```powershell
   Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
   ```

   - 最後に `Scoop was installed successfully!` が出ればよい
   - `Running the installer as administrator is disabled by default` が出たら、管理者の PowerShell に貼っている。閉じて手順 1 から
   - `Scoop is already installed` が出たら、もう入っている（何も変えずに終わる）。手順 5 へ進む
   - `'C:\Users\<WIN_USER>\scoop' exists and is not empty` が出たら、前に入れた scoop の残り（`persist` など）がある。要らなければ[ロールバック](#ロールバック)の手順 4 で消してから貼り直す

   <details>
   <summary>補足: インストーラのすること</summary>

   - `https://get.scoop.sh` は、公式のインストーラ（`https://raw.githubusercontent.com/scoopinstaller/install/master/install.ps1`）へ飛ぶ。`Invoke-Expression` で、取ったスクリプトをそのまま動かす（公式の README の方法）
   - 中身を読んでから動かすなら、`Invoke-RestMethod -Uri https://get.scoop.sh -OutFile install.ps1` で保存して読み、`.\install.ps1` で動かす（同じ README の方法）。インストーラに Authenticode の署名は無い
   - インストーラは、PowerShell 5 以上・管理者でないこと・実行ポリシー・scoop がまだ無いことを確かめてから入れる
   - 入るもの
     - `~\scoop\apps\scoop\current`（scoop 本体）・`~\scoop\buckets\main`（main のバケット）・`~\scoop\shims`（コマンドの入口）
     - ユーザーの環境変数 `PATH` の先頭に `~\scoop\shims` を足す。変えたことを Windows 全体に知らせる（`WM_SETTINGCHANGE`）ので、この後にスタートメニューから起動したアプリにも届く
     - 設定のファイル `~\.config\scoop\config.json`
   - git があれば、本体と main のバケットを `git clone` で取る。無ければ zip で取る（その場合、`scoop update` で git を求められる。手順 6）
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

1. git が無いときだけ、scoop で git を入れる。

   ```powershell
   scoop install git
   git --version
   ```

   - 手順 2 の `Git` に場所が出ていたら、この手順は飛ばす
   - `git version 2.56.0.windows.1` の形の行が出ればよい（版は実行した日の最新）
   - 依存の 7-Zip（`7zip`）も一緒に入る

   <details>
   <summary>補足: git が要る理由</summary>

   - scoop は、自分とバケットの更新（`scoop update`）と、バケットの追加（`scoop bucket add`）に git を使う。無いと `Scoop uses Git to update itself. Run 'scoop install git' and try again.` で止まる
   - UniGet UI も、scoop の更新に git が要るとして、無ければ `scoop install main/git` を勧める（ソースの `Scoop.cs`）
   - Git for Windows をインストーラで入れた PC（[git.md](git.md)）では、その `git` を使うので、この手順は要らない
   - scoop の git（`main/git`）は Git for Windows の持ち運び版（PortableGit）で、`git` のほかに `sh`・`gpg` なども `~\scoop\shims` に置く。PortableGit の 7z の自己展開の形を開くために、7-Zip が依存で入る

   </details>

1. UniGet UI（winget）と、その scoop の検索に使う scoop-search を入れる。

   ```powershell
   scoop install scoop-search
   winget install --exact --id Devolutions.UniGetUI --source winget --scope user --accept-source-agreements --accept-package-agreements
   winget list --exact --id Devolutions.UniGetUI
   ```

   - `scoop install scoop-search` の最後に `'scoop-search' (2.1.0) was installed successfully!` の形の行が出る
   - winget はインストーラのハッシュを確かめてから入れる。管理者の確認（UAC）は出ないはず
   - 最後の表に `UniGetUI` と `Devolutions.UniGetUI` の行が出ればよい（版は実行した日の最新。2026-10-03 は 2026.3.0）
   - デスクトップに UniGetUI のショートカットができる（要らなければ手で消す）

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

1. スタートメニューから UniGet UI を起動し、WinGet と Scoop が使えることを確かめる。

   - スタートメニューで「UniGetUI」を探して開く
   - 初回は、使い方の案内や設定の問いが出ることがある。読んで進める
   - 設定のパッケージ マネージャーの一覧で、WinGet と Scoop が有効になっていて、見つかっている（版が出ている）ことを確かめる
   - 「インストール済みのパッケージ」に、手順 6・7 で scoop で入れたもの（`scoop-search` など）と、winget の `UniGetUI` が出る
   - **次の手順は、この PowerShell に戻ってから貼る**（UniGet UI は開いたままでもよい）

   <details>
   <summary>補足: UniGet UI と scoop</summary>

   - UniGet UI は、`PATH` から `scoop.ps1` を探して scoop を見つける。PowerShell 7（`pwsh.exe`）があればそれで、無ければ Windows PowerShell 5.1 で、`-ExecutionPolicy Bypass` を付けて動かす（ソースの `Scoop.cs`）
   - 手順 4 より前に UniGet UI を起動していたら、scoop の `PATH` が届いていないことがある。UniGet UI を閉じて開き直す
   - 画面の文言と並びは、Windows で確かめていない

   </details>

1. 自分のユーザーで、旧形式のコンテキストメニューを出すようにする。

   ```powershell
   reg.exe add 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /f /ve
   reg.exe query 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' /ve
   ```

   - `reg.exe add` が成功の 1 行を出し、`reg.exe query` に `(既定)`（英語の表示では `(Default)`）と `REG_SZ` の行が出ればよい（値は空）
   - エクスプローラーに効くのは、手順 12 の再起動の後（Caps Lock を変えないなら、サインアウトしてサインインし直す）

   <details>
   <summary>補足: この設定の仕組み</summary>

   - Windows 11 のエクスプローラーは、右クリックで新しい形のメニューを出し、その中の「その他のオプションを確認」（Shift+F10 か Shift+右クリックでも）で旧形式のメニューを出す
   - 新しい形のメニューは、CLSID `{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}` の COM のクラスが出している。自分のユーザーの `HKCU\Software\Classes\CLSID` に同じ CLSID の `InprocServer32` を空の既定の値で置くと、そのクラスを読めなくなり、エクスプローラーは最初から旧形式のメニューを出す
   - Microsoft が説明している設定ではない（サポート外）。広く使われている方法で、25H2 でも効くという記事が複数ある（本書では確かめていない）
   - 自分のユーザーだけにかかり、管理者の権限は要らない。消せば元に戻る（[ロールバック](#ロールバック)の手順 1）
   - PowerShell の `New-Item -Force` で作らず `reg.exe` を使うのは、`New-Item -Force` が既にあるキーを作り直して中の値を消すため。`reg.exe add /f /ve` は既定の値だけを書く

   </details>

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く。UAC の確認が出たら「はい」
   - 手順 1 の PowerShell は開いたままでよい（[ロールバック](#ロールバック)も同じ使い分け）

1. Caps Lock を左 Ctrl にする Scancode Map を書く。

   ```powershell
   & {
     $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
     $want = '00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00'
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない（手順 10 から）'; return }
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
   - 効くのは、手順 12 の再起動の後

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
   - 値を 16 進の文字列で比べるのは、もう同じ値があるか（2 回目）と、ほかの割り当てがあるかを分けるため

   </details>

1. 再起動する。

   ```powershell
   Restart-Computer
   ```

   - 保存していない作業があれば、先に保存する（すぐに再起動が始まる）
   - ほかのユーザーがサインインしていると、エラーで止まる。そのときは、スタートメニューの電源から再起動する
   - **次の手順は、起動してサインインしてから行う**

1. Caps Lock が Ctrl として働くことを確かめる。

   - メモ帳を開いて何か打ち、Caps Lock を押したまま A を押すと、全部が選ばれる（Ctrl+A）
   - Caps Lock だけを押しても、Caps Lock のランプは点かず、大文字にもならない
   - 日本語の配列（JIS）のキーボードでは、「英数」（Caps Lock）のキーが Ctrl になる

1. エクスプローラーで右クリックし、旧形式のメニューが出ることを確かめる。

   - ファイルかデスクトップを右クリックすると、「その他のオプションを確認」を選ばなくても、「送る」「プロパティ」などの並ぶ旧形式のメニューが出る

---

## 更新

- scoop で入れたものは scoop で、UniGet UI は UniGet UI 自身か winget で上げる。UniGet UI の画面からも、scoop と winget のパッケージをまとめて上げられる
- HackGen Console NF は、[hackgen.md の Windows 11 の更新](hackgen.md#windows-11-の更新)
- この節の手順は、手順 1 と同じ、管理者ではない Windows PowerShell（5.1）に貼る

1. scoop とバケットを上げ、古くなったものを確かめる。

   ```powershell
   scoop update
   scoop status
   ```

   - `scoop update` は `Scoop was updated successfully!` を出す
   - `scoop status` は、古いものがあれば名前と版を並べる。`Everything is ok!` なら、この節の手順 2 は飛ばす

1. 古いものがあるときだけ、scoop で入れたものを上げる。

   ```powershell
   scoop update *
   ```

   - アプリごとに `'<名前>' (<版>) was installed successfully!` の形の行が出る
   - 動いているアプリは `Running process detected, skip updating.` で飛ばされる。閉じてから貼り直す
   - SSH のセッションで scoop のツールを使っているなら、[Windows の OpenSSH サーバー](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の任意節の手順 1 を、管理者の PowerShell で貼り直す（新しいジャンクションができるため）

1. UniGet UI をすぐに上げるときだけ、winget で上げる。

   ```powershell
   winget upgrade --exact --id Devolutions.UniGetUI --source winget --accept-source-agreements --accept-package-agreements
   ```

   - 新しい版が無ければ、更新が見つからない旨の行が出て何もしない
   - 動いている UniGet UI は、インストーラが閉じる
   - 待つなら、この手順は要らない（UniGet UI は自分で新しい版を確かめて上げる。設定で切れる）

---

## ロールバック

- この節の手順 1〜5 は手順 1 と同じ管理者ではない Windows PowerShell（5.1）に、手順 7・8 はこの節の手順 6 で開く管理者の Windows PowerShell に貼る
- 項目ごとのこの節の手順: コンテキストメニューは 1、UniGet UI は 2、scoop は 3〜5、Caps Lock は 6〜8。残すものの手順は飛ばす
- HackGen Console NF は、[hackgen.md の Windows 11 のロールバック](hackgen.md#windows-11-のロールバック)

> [!CAUTION]
> **この節の手順 3 は、scoop で入れたすべてのアプリを消す**（手順 6 の git や、本書の外で入れたものも）。**この節の手順 4 は、それらの設定（`~\scoop\persist`）も消す**（取り戻せない）。scoop を残すなら、この節の手順 3・4 は行わない。

1. 旧形式のコンテキストメニューの設定を消す。

   ```powershell
   reg.exe delete 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' /f
   Test-Path -LiteralPath 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
   ```

   - `False` が出ればよい
   - エクスプローラーに効くのは、再起動（この節の手順 8）かサインインし直した後

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
   - この手順を行わないと、scoop を入れ直すときに手順 4 が `exists and is not empty` で止まる

1. 実行ポリシーを戻すときだけ、自分のユーザーの値を消す。

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser -Force
   Get-ExecutionPolicy -List | Format-Table -AutoSize
   ```

   - 手順 2 で `CurrentUser` が `Undefined` だったときだけ行う。`RemoteSigned` などだったなら飛ばす（手順 3 はその値を変えていない）
   - 表の `CurrentUser` が `Undefined` に戻ればよい
   - PowerShell のスクリプトを使うほかの道具（scoop を残すときの scoop も）が動かなくなる

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. Caps Lock を戻すときだけ、Scancode Map を消す。

   ```powershell
   & {
     $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
     $want = '00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00'
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない（この節の手順 6 から）'; return }
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

1. 再起動する。

   ```powershell
   Restart-Computer
   ```

   - この節の手順 7 を行ったときに要る（行わず、この節の手順 1 だけなら、サインインし直すだけでよい）
   - **次の手順は、起動してサインインしてから行う**

1. Caps Lock とコンテキストメニューが元に戻ったことを確かめる。

   - Caps Lock を押すとランプが点き、大文字になる（この節の手順 7 を行ったとき）
   - 右クリックで新しい形のメニューが出る（この節の手順 1 を行ったとき）

---

## 補足

### 対象と検証環境

- **目的**: Windows 11 の PC を使い始めるときの設定を、1 本の手順にまとめる
  - [scoop](https://scoop.sh/)（コマンドラインのツールを自分のユーザーに入れるパッケージ マネージャー）を入れる
  - [UniGet UI](https://devolutions.net/unigetui/)（winget・scoop などのパッケージを画面で入れる・上げるアプリ）を入れる
  - Caps Lock を Ctrl にする
  - エクスプローラーの右クリックで、旧形式のコンテキストメニューを出す
  - 依頼にはフォントの HackGen Console NF もあったが、AlmaLinux 10 と同じツールなので [hackgen.md](hackgen.md#windows-11-で使う) にまとめた（[選択した方針](#選択した方針)）
- **進め方**: 管理者の権限の要らないもの（scoop・UniGet UI・コンテキストメニュー）を管理者ではない Windows PowerShell 5.1 で、PC 全体の設定（Caps Lock）だけを管理者の PowerShell で行い、最後に 1 回再起動する
  - scoop は公式のインストーラ、UniGet UI は winget の自分のユーザーへの導入、Caps Lock は Scancode Map、コンテキストメニューは自分のユーザーのレジストリ
- **状態**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](#付録-配布物と資料の調査2026-10-03)）:
    - scoop: 公式のインストーラ（`install.ps1`）と scoop 0.6.0 のソースを読んだ（管理者・実行ポリシー・既に入っているときに止まること、`PATH` の書き方、git の要るところ、`scoop uninstall scoop` の動き）
    - UniGet UI: winget の定義（2026.3.0）、scoop の `extras/unigetui` の定義、2026-10-02 のソース（インストーラの定義、ポータブル版の自動の更新、scoop の見つけ方と依存）
    - Caps Lock と PowerToys: Microsoft の文書
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。Scancode Map を書く・消す 2 つのブロックは、Linux の pwsh で偽物のレジストリを使って流した（[付録](#付録-linux-での-powershell-のブロックの確認2026-10-03)）
  - **確かめていないこと**: Windows で貼ること（すべての手順）、winget と UniGet UI の画面と表示、旧形式のコンテキストメニューが今の Windows 11 で出ること、Scancode Map が JIS 配列のキーボード・リモート デスクトップで効くこと、arm64 の Windows
- 下表は、本書が前提にしている環境（ほかの Windows の手順書の実機の記録と同じ PC を想定）

| 項目 | 値 |
|---|---|
| OS | Windows 11（[Windows の OpenSSH サーバー](windows-openssh-server.md)の PC は 25H2・26H2）。x64 |
| PowerShell | Windows PowerShell 5.1（管理者ではないものと、管理者として実行したもの） |
| ユーザー | Administrators の一員（Microsoft アカウントでもローカル アカウントでもよい） |
| winget | Windows 11 の「アプリ インストーラー」に入っているもの |
| scoop | 0.6.0（2026-09-30） |
| UniGet UI | 2026.3.0（winget の `Devolutions.UniGetUI`） |

> [!NOTE]
> 本書には変数が無い。版・sha256・パスは、ブロックに直接書いてある。
>
> 出力例・表の中の値は `<WIN_USER>`（Windows のユーザー名）/ `<名前>` / `<版>` のプレースホルダで書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 選択した方針

4 つの項目ごとに経路を比べた（2026-10-03 時点）。

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
| PowerToys の Keyboard Manager | 再起動が要らず、ユーザーごと。PowerToys が動いている間だけ効き、サインインの画面では効かず、管理者の窓には PowerToys を管理者で動かさないと効かない（Microsoft の文書） | 不採用 |
| Sysinternals の Ctrl2Cap | キーボードのフィルター ドライバーを入れる | 不採用（ドライバーを足さずに済む方法がある） |

**旧形式のコンテキストメニュー**

| 経路 | 状況 | 採否 |
|---|---|---|
| **`HKCU\Software\Classes\CLSID\{86ca1aa0-…}\InprocServer32` を空にする** | 自分のユーザーだけ、管理者は要らない。サポート外 | **採用** |
| 何もしない（「その他のオプションを確認」か Shift+右クリック） | 毎回 1 手間かかる | 不採用 |

- **HackGen Console NF は hackgen.md に置いた**
  - 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けず 1 つの手順書にする（[hackgen.md の Windows 11 で使う](hackgen.md#windows-11-で使う)）
  - 依頼では 5 つを 1 本にまとめる指定だったが、同じ日にこの規則ができたので、利用者に確かめて移した
- **管理者ではない PowerShell と管理者の PowerShell を分けた**
  - scoop のインストーラは、管理者の PowerShell では止まる。scoop と UniGet UI（自分のユーザーへの導入）とコンテキストメニューは、どれも管理者の権限が要らない
  - Scancode Map だけが PC 全体の設定なので、そこだけ管理者の PowerShell を開く
  - そのため、[Windows の OpenSSH サーバー](windows-openssh-server.md)の SSH のセッション（Administrators の一員なら管理者の権限で動く）には貼らない
- **再起動を最後の 1 回にまとめた**
  - Scancode Map は再起動、コンテキストメニューはエクスプローラーの起動し直しで効く。再起動 1 回で両方とも効く（hackgen.md の Windows のフォントも、サインインし直す代わりにこの再起動で効く）
- **Windows PowerShell 5.1 にそろえた**
  - Windows 11 に最初からあり、ほかの Windows の手順書（[Windows の OpenSSH サーバー](windows-openssh-server.md)・[syncthing.md の Windows 11 で使う](syncthing.md#windows-11-で使う)）とも同じ
  - 実行ポリシーは PowerShell 7 と別に持つので、5.1 の値を変える

### 注意点

- **Caps Lock の働きは無くなる**: Caps Lock を左 Ctrl にするだけで、Caps Lock をほかのキーに割り当てない。大文字を続けて打つときは Shift を押す
- **すべてのユーザー・すべてのキーボードにかかる**: Scancode Map は PC 全体の設定。この PC にサインインするほかのユーザーと、つないだ外付けのキーボードにもかかる
- **JIS 配列では「英数」のキーが Ctrl になる**: 日本語の配列のキーボードの Caps Lock は「英数」のキー（スキャン コード `0x3A`）なので、そのキーの IME の働き（英数への切り替え）も無くなるはず（確かめていない）
- **リモート デスクトップ**: Microsoft の文書は、Scancode Map がターミナル サービスでは正しく働かないことがあると書いている。この PC にリモート デスクトップでつないだとき、つないだ側の PC でつないだときの効き方は確かめていない
- **コンテキストメニューの設定はサポート外**: Windows の更新で効かなくなることがある。そのときは、手順 2 の `ClassicMenu` と手順 9 の `reg.exe query` で、設定が残っているかを見る
- **SSH のセッションで scoop のツールを使うとき**: sshd の緩和策（RedirectionGuard）で、一般ユーザーの scoop が作るジャンクションをたどれない。[Windows の OpenSSH サーバー](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)の任意節を、`scoop install`・`scoop update` の後に貼る
- **PowerShell 7 で scoop を使うとき**: 実行ポリシーは Windows PowerShell 5.1 とは別に持つ。UniGet UI は、PowerShell 7 があればそれで scoop を動かす（`-ExecutionPolicy Bypass` 付き）
- **scoop のアプリは自分のユーザーだけ**: `~\scoop` に入るので、ほかのユーザーには見えない。scoop の `--global` は管理者が要り、本書では使わない

### 参照

- [ScoopInstaller/Install](https://github.com/ScoopInstaller/Install) — 公式のインストーラ（`irm get.scoop.sh | iex`、実行ポリシー、管理者での導入を止めていること、`-RunAsAdmin`）
- [Scoop](https://scoop.sh/) と [ScoopInstaller/Scoop](https://github.com/ScoopInstaller/Scoop) — `bin/uninstall.ps1`（`scoop uninstall scoop`）、`libexec/scoop-update.ps1`
- [Devolutions/UniGetUI](https://github.com/Devolutions/UniGetUI) — README の入れ方、`UniGetUI.iss`（インストーラ）、`src/UniGetUI.PackageEngine.Managers.Scoop/Scoop.cs`、`src/Shared/AutoUpdater.InstallerArguments.cs`
- [winget-pkgs の `Devolutions.UniGetUI`](https://github.com/microsoft/winget-pkgs/tree/master/manifests/d/Devolutions/UniGetUI) — winget の定義
- [Configuration of Keyboard and Mouse Class Drivers — Microsoft Learn](https://learn.microsoft.com/en-us/previous-versions/windows/hardware/hid/keyboard-and-mouse-class-drivers#scan-code-mapper-for-keyboards) — 節「Scan code mapper for keyboards」。Scancode Map の書式、再起動、全ユーザー
- [PowerToys Keyboard Manager — Microsoft Learn](https://learn.microsoft.com/en-us/windows/powertoys/keyboard-manager) — 採らなかった方法の制限
- [about_Execution_Policies — Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1)
- [hackgen.md](hackgen.md) — HackGen Console NF（AlmaLinux 10 と Windows 11）
- [Windows の OpenSSH サーバー](windows-openssh-server.md) — 同じ PC で使うことの多い手順書（scoop のツールを SSH のセッションで使う任意節）

---

### 付録: 配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物とソースと資料を読んだ記録。

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

- 本書の `powershell` のブロック 19 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0
  - ほかの規則の指摘は、手順 4 の `Invoke-Expression`（公式のインストーラの方法なので、そのまま）と、ASCII でない文字を含むファイルの BOM（貼るので関係が無い）だけ
  - わざと PowerShell 7 だけの書き方（`??`、`Get-Content -AsByteStream`、`ForEach-Object -Parallel`、`Join-Path -AdditionalChildPath`）を入れたファイルでは、それぞれ指摘が出た
- `(Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass'`（手順 3）は、列挙の値と文字列を比べて、`RemoteSigned` で `False`、`Restricted` で `True` になった

**手順 11 と[ロールバック](#ロールバック)の手順 7 のブロック**を、管理者の判定を `$true` に替え、レジストリ（`Get-ItemProperty`・`New-ItemProperty`・`Remove-ItemProperty`）を値を覚えておく偽物にして、`Scancode Map` が無いとき・本書の値のとき・別の値（`00 00 00 00 00 00 00 00 02 00 00 00 00 00 5B E0 00 00 00 00`）のときで流した:

| ブロック | 無い | 本書の値 | 別の値 |
|---|---|---|---|
| 手順 11 | 書き（1 回）、`Scancode Map = 00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00` | 書かずに同じ行 | `中断: 別の Scancode Map がある（…）` で止まり、書かない |
| ロールバックの手順 7 | `Scancode Map は無い` | 消して `Scancode Map を消した` | `中断: 本書の値ではない Scancode Map がある（…）` で止まり、消さない |

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（手順 2 の判定、scoop のインストーラ、winget の表示、UniGet UI の画面）
1. `HKCU` の CLSID の設定で、今の Windows 11（25H2・26H2）のエクスプローラーが旧形式のメニューを出すこと
1. Scancode Map で、Caps Lock が Ctrl になること（JIS 配列のキーボード、リモート デスクトップでつないだときも）
1. 更新（scoop・UniGet UI）とロールバック、arm64 の Windows
