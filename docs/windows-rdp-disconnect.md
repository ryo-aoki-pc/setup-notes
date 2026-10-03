# Windows 11 のリモートデスクトップを、画面をロックせずに切断する手順（tscon）

## 実施手順

> [!IMPORTANT]
> - **手順 1〜3 は、RDP（リモートデスクトップ）でつないだ Windows のセッションの中で行う**。手順 1 で管理者の Windows PowerShell（5.1）を開き、手順 2・3 をそこに貼る
> - 前提: Windows 11 Pro 以上で、設定の「システム → リモート デスクトップ」がオンになっていて、RDP でつなげること（Home は RDP でつながれる側になれない）。PC にサインインしているのと同じユーザーでつなぐ。そのユーザーは Administrators の一員（手順 3 の `tscon` に管理者の権限が要る）
> - **手順 3 を貼ると、その場で RDP が切れる**
> - **手順 4・5 は、クライアントの PC から SSH で行う**（[Windows の OpenSSH サーバー](windows-openssh-server.md)）。SSH が無ければ、PC の前で画面を見る

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 毎回の切断をデスクトップのアイコンのダブルクリックにするなら[ショートカットで切断する（任意）](#ショートカットで切断する任意)、そのショートカットを消すときは[ロールバック](#ロールバック)

> [!WARNING]
> - **この手順書は Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、Microsoft などの資料と、PowerShell のブロックの構文と引数の渡り方、ショートカットのファイルの形式だけ（[対象と検証環境](#対象と検証環境)）
> - **切断した後の PC の画面はロックされない**。PC の前にいる人が、このユーザー（Administrators の一員）としてそのまま操作できる。人が触れる場所にある PC では使わない

1. RDP でつないだセッションの中で、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」を選ぶ。UAC の確認で「はい」
   - ウィンドウのタイトルが「管理者: Windows PowerShell」になる
   - 「Windows PowerShell (x86)」（32 ビット）は使わない
   - **次の手順は、このウィンドウが開いてから、そこに貼る**

   <details>
   <summary>補足: 管理者の PowerShell を使う理由</summary>

   - `tscon` で今のセッションを PC の画面（コンソール）へ移すときは、管理者として実行する（SmartBear の TestComplete の資料。管理者でないときに何が出るかは確かめていない）
   - Microsoft の `tscon` の資料は、別のセッションにつなぐには、フル コントロールか「接続」の特殊なアクセス許可が要ると書いている
   - 管理者として開いた PowerShell も、RDP でつないだのと同じセッションで動く。手順 2・3 は、このプロセスのセッションの ID を使う
   - 32 ビットの PowerShell では `System32` が `SysWOW64` に読み替えられ、`tscon.exe` が見つからないことがある（確かめていない）

   </details>

1. 今のセッションが RDP であることと、その ID を確かめる。

   ```powershell
   quser
   'このセッションの ID: {0}' -f (Get-Process -Id $PID).SessionId
   ```

   - `quser` の自分の行（先頭に `>` が付く）のセッション名が `rdp-tcp#<N>` で、状態が `Active`
   - その行の ID と、最後の行の ID が同じ
   - 自分の行のセッション名が `console` なら、PC の前のセッション（RDP ではない）。手順 3 は貼らない

   <details>
   <summary>補足: RDP でつないだときのセッション</summary>

   - Windows 11 の Pro では、PC にサインインしているのと同じユーザーで RDP でつなぐと、新しいセッションは作られず、そのセッションが RDP へ移る。PC の画面はロック画面になる
   - ふつうに切断する（RDP の窓を閉じる）と、セッションは `Disc`（切断）の状態で残り、PC の画面はロック画面のまま。アプリは動き続ける
   - セッションの ID はつなぎ直しても変わらず、セッション名だけが `console` と `rdp-tcp#<N>` で入れ替わる（`<N>` はつなぐたびに変わる）
   - `quser` の出力の例は、実機で取っていないので載せていない

   </details>

1. セッションを PC の画面（コンソール）へ移し、RDP を切る。

   ```powershell
   tscon.exe (Get-Process -Id $PID).SessionId /dest:console
   ```

   - RDP のクライアントの窓が閉じる（クライアントが切断を知らせる）
   - 切れずに PowerShell にエラーが出たときは、管理者の PowerShell かを確かめて、手順 1 からやり直す
   - **次の手順は、RDP が切れてから、クライアントの PC で行う**（この手順の後ろに行を続けて貼らない）

   <details>
   <summary>補足: tscon がすること</summary>

   - `tscon <セッションの ID> /dest:console` は、そのセッションを `console`（PC の画面とキーボード）につなぎ、今つないでいる RDP を切る（Microsoft の `tscon` の資料の `/dest`）
   - 同じユーザーのセッションなので、`/password` は要らない（資料は、別のユーザーのセッションにつなぐときに要ると書いている）
   - Microsoft の資料の注意書きの「コンソールのセッションにはつなげない」は、つなぐ先のセッション（最初の引数）に `console` を指すことを言う、と読める。本書は最初の引数に今の RDP のセッションを指し、`/dest:` に `console` を指す（SmartBear の資料と同じ使い方）
   - セッションの ID は、`quser` の出力を切り出さずに、この PowerShell のプロセスのセッションの ID（`Process.SessionId`。ターミナル サービスのセッションの ID）から取る。出力の列の位置に頼らないため
   - PC の画面は、ロック画面を通らずにデスクトップになる。開いていたアプリはそのまま

   </details>

1. クライアントの PC から、Windows に SSH でログインする。

   - `ssh <WIN_USER>@<WIN_HOST>` でログインする（[Windows の OpenSSH サーバー](windows-openssh-server.md)の手順 9 と同じ）
   - PC の前にいるなら、SSH の代わりに PC の画面を見る。ロック画面ではなく、RDP で開いていたままのデスクトップが出ていればよい。そのときは手順 5 は飛ばす
   - **次の手順は、ログインした先のプロンプトが出てから貼る**（続けて貼ると、ログインの途中の入力として食われる）

1. SSH でログインしたシェルで、セッションが PC の画面に戻ったことを確かめる。

   ```powershell
   quser
   ```

   - 自分の行のセッション名が `console` で、状態が `Active`。ID は手順 2 と同じ
   - ログインした先のシェルが Git Bash でも cmd でも、そのまま `quser` と打てばよい
   - [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md#実施手順)の手順 3 の確認（`console` の行が `Active`）も、これで通る

---

## ショートカットで切断する（任意）

- [実施手順](#実施手順)の手順 1〜3 を、デスクトップのアイコンのダブルクリックにする。UAC の確認は毎回出る
- この節の手順 1 は、RDP でつないだセッションの中の Windows PowerShell に貼る（管理者でなくてよい。実施手順の手順 1 で開いたものに貼るなら、手順 3 より前に）
- ショートカットは、管理者として実行する Windows PowerShell で、手順 3 と同じ `tscon` を動かす

1. デスクトップに、管理者として実行するショートカットを作る。

   ```powershell
   & {
     $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'RDP をロックせずに切断.lnk'
     $s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
     $s.TargetPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
     $s.Arguments = '-NoProfile -WindowStyle Hidden -Command "tscon.exe (Get-Process -Id $PID).SessionId /dest:console"'
     $s.IconLocation = "$env:WINDIR\System32\mstsc.exe,0"
     $s.Save()
     $b = [System.IO.File]::ReadAllBytes($lnk)
     if ($b[0] -ne 0x4C) { Write-Error "中断: $lnk がショートカットの形式でない"; return }
     $b[0x15] = $b[0x15] -bor 0x20
     [System.IO.File]::WriteAllBytes($lnk, $b)
     '{0}（管理者として実行: {1}）' -f $lnk, [bool]([System.IO.File]::ReadAllBytes($lnk)[0x15] -band 0x20)
   }
   ```

   - `C:\Users\<WIN_USER>\Desktop\RDP をロックせずに切断.lnk（管理者として実行: True）` が出ればよい（OneDrive でデスクトップをバックアップしていると、`OneDrive` の下のパスになる）
   - デスクトップに「RDP をロックせずに切断」のアイコンが出る
   - 何度貼ってもよい（同じショートカットを作り直す）
   - 同じ印は、画面でも付けられる: ショートカットのプロパティの「ショートカット」タブの「詳細設定」で、「管理者として実行」にチェックを入れる

   <details>
   <summary>補足: ショートカットの作り</summary>

   - 動かすのは `powershell.exe -NoProfile -WindowStyle Hidden -Command "tscon.exe (Get-Process -Id $PID).SessionId /dest:console"`。手順 3 と同じコマンドを、隠した窓で動かす
   - `Arguments` は単一引用符で囲み、`$PID` を、ショートカットを作る PowerShell ではなく、ショートカットが起動する PowerShell に読ませる
   - `WScript.Shell` のショートカットには「管理者として実行」を付ける口が無いので、保存した `.lnk` のバイトを直す
     - `.lnk` の先頭はヘッダー（`ShellLinkHeader`。最初の 4 バイトが大きさの `0x4C`）。オフセット `0x14` からの 4 バイトが `LinkFlags` で、その `RunAsUser`（`0x00002000`）を立てる
     - リトル エンディアンなので、オフセット `0x15` のバイトの `0x20` に当たる（MS-SHLLINK）
     - Microsoft の資料は、この印を「別のユーザーとして動かす」とだけ書いている。プロパティの「管理者として実行」のチェックがこの印に当たることは、Windows では確かめていない
   - アイコンは「リモート デスクトップ接続」（`mstsc.exe`）のもの
   - デスクトップの場所は `[Environment]::GetFolderPath('Desktop')` で取る（OneDrive に移したデスクトップも、この値になる）

   </details>

1. 切断するときは、RDP でつないだセッションの中で、デスクトップのショートカットをダブルクリックする。

   - UAC の確認（Windows PowerShell）で「はい」を押すと、RDP が切れる（実施手順の手順 3 と同じ）
   - 切れないときは、ショートカットの窓が隠れていてエラーが見えない。[実施手順](#実施手順)の手順 1〜3 で切って、エラーを見る
   - PC の前（コンソール）では使わない（RDP でつないでいるときのためのもの）
   - 切った後の確かめ方は、実施手順の手順 4・5 と同じ

---

## ロールバック

- `tscon` は設定を変えないので、戻すものは無い。この節は、[ショートカットで切断する（任意）](#ショートカットで切断する任意)のショートカットを消すだけ
- この節は、このユーザーの Windows PowerShell に貼る（管理者でなくてよい）

1. ショートカットを作ったときは、消す。

   ```powershell
   & {
     $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'RDP をロックせずに切断.lnk'
     Remove-Item -LiteralPath $lnk
     Test-Path -LiteralPath $lnk
   }
   ```

   - `False` が出ればよい

---

## 補足

### 対象と検証環境

- **目的**: Windows 11 の PC に RDP でつないで使った後、PC の画面をロックさせずに切断する。セッションを PC の画面（コンソール）へ戻し、デスクトップにサインインしたままにする
  - ふつうに切断すると、セッションは `Disc`（切断）で残り、PC の画面はロック画面になる
  - デスクトップにサインインしていて、`quser` で `console` が `Active` であることを前提にするもの（[Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)の手順 3）や、画面を使う自動の操作を、RDP で使った後も続けるため
- **進め方**: RDP でつないだセッションの中の管理者の Windows PowerShell 5.1 で、`tscon.exe <このセッションの ID> /dest:console` を実行する
  - 変数は無い。読者が書き換える値も無い
  - 毎回の切断を、デスクトップのショートカットにもできる（任意）
- **状態**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](#付録-資料とブロックの確認2026-10-03)）:
    - 資料: Microsoft の `tscon`・`quser`・リモート デスクトップを有効にする手順・`Process.SessionId`・`.lnk` の形式（MS-SHLLINK）、SmartBear の TestComplete の資料（RDP をロックせずに切断する）
    - PowerShell のブロック: Linux の PowerShell 7.6.2 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査
    - 手順 3 とショートカットのコマンドが、`tscon.exe` に、セッションの ID と `/dest:console` の 2 つの引数を渡すこと（Linux の pwsh で、引数を表示するだけの偽の `tscon.exe` を使った）
    - ショートカットのバイトの直し方: Python の pylnk3 で作った `.lnk` で、オフセット `0x15` の `0x20` を立てると `RunAsUser` が立つこと
    - [ショートカットで切断する（任意）](#ショートカットで切断する任意)の手順 1 と[ロールバック](#ロールバック)のブロック: Linux の pwsh で、`WScript.Shell` を、pylnk3 で `.lnk` を書く偽物にして流したこと
  - **確かめていないこと**: Windows で貼ること（すべての手順）、RDP が切れて PC の画面がロックされずに残ること、管理者でないときのエラー、ショートカットの UAC と動き、`WScript.Shell` が作る `.lnk`、PC の画面の解像度、モニターをつないでいない PC と蓋を閉じたノート PC、24H2 より前の Windows
- 下表は、本書が前提にしている環境（ほかの Windows の手順書の実機の記録と同じ PC を想定）

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro（Enterprise・Education でもよい。Home は RDP でつながれる側になれない）。24H2 以降を想定（[Windows の OpenSSH サーバー](windows-openssh-server.md)の PC は 25H2・26H2） |
| PowerShell | Windows PowerShell 5.1（管理者として実行） |
| ユーザー | Administrators の一員。PC にサインインしているのと同じユーザーで、RDP でつなぐ |
| RDP のクライアント | どれでもよい（Windows の「リモート デスクトップ接続」、Windows App、Remmina など） |
| 確かめに使う SSH | [Windows の OpenSSH サーバー](windows-openssh-server.md)（無ければ PC の前で画面を見る） |

> [!NOTE]
> この手順書には変数が無い。コマンドはそのまま貼って実行できる。
>
> 出力例・表の中の値は `<WIN_USER>` / `<WIN_HOST>` / `<N>`（`rdp-tcp#<N>` の番号）のプレースホルダで書いてある。
>
> Windows のパスワードはこの文書に載せない（`tscon` の `/password` は使わない）。

手順書全体に関わる理由・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 選択した方針

- **`tscon` で、今のセッションを PC の画面（コンソール）へ移して切る**
  - RDP を切るときに PC の画面をロックさせない設定は、本書を書くときに見つけられなかった
  - UI の自動テストの道具（SmartBear の TestComplete など）が、テストを動かしたまま RDP を切る方法として、同じことを案内している
- **セッションの ID は、PowerShell のプロセスから取る**
  - SmartBear の資料のバッチは、`query user` の出力の 3 列目を ID として取る
  - 本書は出力の列の位置に頼らず、この PowerShell が動いているセッション（RDP でつないでいるセッション）の ID を `(Get-Process -Id $PID).SessionId` で取る
- **ショートカットは、毎回 UAC の確認が出る形にした**（利用者の選択）
  - 最上位の特権のタスクを登録し、ショートカットから `schtasks /run` で動かせば UAC の確認は出ないが、仕組みが増えるので採らなかった
- **採らなかった案**
  - ふつうの切断（RDP の窓を閉じる）: PC の画面がロック画面になる
  - サインアウト: セッションが終わり、動いていたアプリも終わる

### 注意点

- **PC の画面はロックされない**: 切った後、PC の前にいる人がこのユーザー（Administrators の一員）として操作できる。ロックするときは、PC の前で Win+L を押す
- **次に RDP でつなぐと、PC の画面はまたロック画面になる**: セッションが RDP へ移るため。切るときは、また本書の手順で切る
- **ふつうに切断してしまったとき**: もう 1 度 RDP でつないでから、本書の手順で切る。SSH のセッションから `tscon` で戻す形は確かめていない
- **画面の大きさ**: セッションは PC のモニターの解像度に戻るので、RDP の窓に合わせて並べた窓の位置や大きさが変わることがある（確かめていない）
- **モニターの無い PC・蓋を閉じたノート PC**: PC の画面へ戻したときの動きは確かめていない。蓋を閉じたときの動作（既定はスリープ）は、Windows の電源の設定に従う
- **クリップボード**: SmartBear の資料は、クリップボードが空でないまま切ると、RDP のクリップボードの共有（`rdpclip.exe`）が失敗することがあると書いている（確かめていない）
- **PC の前のセッションでは使わない**: 手順 3 とショートカットは、RDP でつないでいるときのためのもの

### 参照

- [tscon — Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/tscon)（`/dest`、`/password` が要る条件、コンソールのセッションの注意書き）
- [quser — Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/quser)（列の意味、今のセッションに付く `>`）
- [Enable Remote Desktop on your PC — Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/remotepc/remote-desktop-allow-access)（設定の「システム → リモート デスクトップ」、Home は RDP でつながれる側になれないこと）
- [Process.SessionId — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.process.sessionid)（プロセスのターミナル サービスのセッションの ID）
- MS-SHLLINK の [ShellLinkHeader](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-shllink/c3376b21-0931-45e4-b2fc-a48ac0e60d15)・[LinkFlags](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-shllink/ae350202-3ba9-4790-9e9e-98935f4ee5af)（`.lnk` のヘッダーと `RunAsUser`）、[SHELL_LINK_DATA_FLAGS](https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/ne-shlobj_core-shell_link_data_flags)（`SLDF_RUNAS_USER` = `0x00002000`）
- [Disconnecting From Remote Desktop While Running Automated Tests — SmartBear TestComplete](https://support.smartbear.com/testcomplete/docs/testing-with/running/via-rdp/keeping-computer-unlocked.html)（`tscon … /dest:console` を管理者として実行する、ロックされないことの注意、`rdpclip.exe`）
- [Windows の OpenSSH サーバー](windows-openssh-server.md)（手順 4・5 の SSH）
- [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)（デスクトップにサインインしていることを前提にする手順書）

---

### 付録: 資料とブロックの確認（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ、Ubuntu 24.04）で確かめた記録。

**資料**:

- Microsoft の `tscon` の資料: 構文は `tscon {<sessionID> | <sessionname>} [/dest:<sessionname>] [/password:<pw> | /password:*] [/v]`。`/dest` は今のセッションの名前で、つないだときに切れる。`/password` は、つなぐ人がそのセッションの持ち主でないときに要る。注意書きに「You can't connect to the console session.」がある
- Microsoft の `quser` の資料: 今のセッションの前に `>` が付く。状態は active か disconnected
- Microsoft のリモート デスクトップを有効にする資料: 「Settings → System → Remote Desktop」。Home は RDP でつながれる側になれない
- SmartBear の TestComplete の資料: `%windir%\System32\tscon.exe RDP-Tcp#NNN /dest:console` を管理者として実行する。`query user %USERNAME%` の 3 列目を取るバッチと、「管理者として実行」のショートカット。ロックされないので安全性が下がること、クリップボードが空でないと `rdpclip.exe` が失敗しうること
- MS-SHLLINK と `SHELL_LINK_DATA_FLAGS`: `ShellLinkHeader` の最初の 4 バイトは大きさ（`0x0000004C`）で、`LinkFlags` は 16 バイトの `LinkCLSID` の後（オフセット `0x14`）。`RunAsUser`（N、bit 13）は `SLDF_RUNAS_USER` = `0x00002000`（「Causes the target application to run as a different user.」）

**PowerShell のブロック**:

- 本書の `powershell` のブロック 5 個を、Linux の PowerShell 7.6.2（Microsoft の Ubuntu 24.04 のリポジトリの deb を展開した）の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer 1.25.0 の `PSUseCompatibleSyntax`（Windows PowerShell 5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0、既定の規則の指摘も 0
- わざと PowerShell 7 だけの書き方（`??`、`ForEach-Object -Parallel`、`Get-Content -AsByteStream`）を入れたファイルでは、それぞれ指摘が出た

**`tscon.exe` に渡る引数**: PATH の先頭に、引数を表示するだけの偽の `tscon.exe` を置き、手順 3 のコマンドと、ショートカットの `-Command` の文字列を、Linux の pwsh で動かした（`-WindowStyle Hidden` は Linux では使えないので外した）。どちらも 2 つの引数が渡った（Linux の `SessionId` は、ログインのセッションの番号）:

```
tscon.exe に渡った引数 2 個: [792] [/dest:console]
```

**`.lnk` の「管理者として実行」の印**: pylnk3 0.4.3 で、ショートカットと同じターゲット・引数・アイコンの `.lnk` を作り、オフセット `0x15` のバイトに `0x20` を立てて読み直した:

```
前 b[0]=0x4C b[0x14:0x18]=e1010000 RunAsUser=False HasArguments=True
後 b[0]=0x4C b[0x14:0x18]=e1210000 RunAsUser=True HasArguments=True
```

**ショートカットとロールバックのブロック**: Linux の pwsh で、`$env:WINDIR` に `C:\Windows` を入れ、`New-Object -ComObject WScript.Shell` を、pylnk3 で `.lnk` を書く偽物の関数に置き換えて流した（デスクトップは一時的な `HOME` の `Desktop`）:

- [ショートカットで切断する（任意）](#ショートカットで切断する任意)の手順 1 のブロックを 2 回続けて流し、どちらも `<一時的な HOME>/Desktop/RDP をロックせずに切断.lnk（管理者として実行: True）` が出た
- できた `.lnk` を pylnk3 で読むと、`RunAsUser` が `True` で、ターゲット（`C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`）・引数・アイコン（`C:\Windows\System32\mstsc.exe` の 0）が手順のとおりだった
- 偽物の `Save` が `.lnk` でないファイル（先頭が `0x01`）を書くようにすると、`中断: … がショートカットの形式でない` で止まり、ファイルは変えなかった（ブロックの後ろの行は動いた）
- [ロールバック](#ロールバック)の手順 1 のブロックは `False` を出し、ファイルが消えた
- 本物の `WScript.Shell` が作る `.lnk` は、pylnk3 が作るものとヘッダーの後ろが違いうる。直すのはヘッダーの中の `LinkFlags` だけ

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. 手順 3 で RDP が切れ、PC の画面がロックされずにデスクトップになること。SSH の `quser` が `console`・`Active` になること
1. 管理者でない PowerShell で手順 3 を貼ったときのエラー
1. ショートカットの UAC の確認と、ダブルクリックで切れること。`WScript.Shell` が作った `.lnk` に印を立てた後、プロパティの「管理者として実行」にチェックが入っていること
1. PC の画面の解像度、モニターの無い PC、蓋を閉じたノート PC
1. 24H2 より前の Windows
