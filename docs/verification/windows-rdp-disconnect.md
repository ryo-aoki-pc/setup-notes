# Windows 11 のリモートデスクトップを、画面をロックせずに切断する手順（tscon）の検証記録

[手順書](../windows-rdp-disconnect.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> - **この手順書は Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、Microsoft などの資料と、PowerShell のブロックの構文と引数の渡り方、ショートカットのファイルの形式だけ（[対象と検証環境](#対象と検証環境)）
> - **切断した後の PC の画面はロックされない**。PC の前にいる人が、このユーザー（Administrators の一員）としてそのまま操作できる。人が触れる場所にある PC では使わない

### 対象と検証環境

- **目的**: Windows 11 の PC に RDP でつないで使った後、PC の画面をロックさせずに切断する。セッションを PC の画面（コンソール）へ戻し、デスクトップにサインインしたままにする
  - ふつうに切断すると、セッションは `Disc`（切断）で残り、PC の画面はロック画面になる
  - デスクトップにサインインしていて、`quser` で `console` が `Active` であることを前提にするもの（[Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)の手順 3）や、画面を使う自動の操作を、RDP で使った後も続けるため
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
    - [ショートカットで切断する（任意）](../windows-rdp-disconnect.md#ショートカットで切断する任意)の手順 1 と[ロールバック](../windows-rdp-disconnect.md#ロールバック)のブロック: Linux の pwsh で、`WScript.Shell` を、pylnk3 で `.lnk` を書く偽物にして流したこと
  - **確かめていないこと**: Windows で貼ること（すべての手順）、RDP が切れて PC の画面がロックされずに残ること、管理者でないときのエラー、ショートカットの UAC と動き、`WScript.Shell` が作る `.lnk`、PC の画面の解像度、モニターをつないでいない PC と蓋を閉じたノート PC、24H2 より前の Windows
- 下表は、本書が前提にしている環境（ほかの Windows の手順書の実機の記録と同じ PC を想定）

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro（Enterprise・Education でもよい。Home は RDP でつながれる側になれない）。24H2 以降を想定（[Windows の OpenSSH サーバー](../windows-openssh-server.md)の PC は 25H2・26H2） |
| PowerShell | Windows PowerShell 5.1（管理者として実行） |
| ユーザー | Administrators の一員。PC にサインインしているのと同じユーザーで、RDP でつなぐ |
| RDP のクライアント | どれでもよい（Windows の「リモート デスクトップ接続」、Windows App、Remmina など） |
| 確かめに使う SSH | [Windows の OpenSSH サーバー](../windows-openssh-server.md)（無ければ PC の前で画面を見る） |

> [!NOTE]
> この手順書には変数が無い。コマンドはそのまま貼って実行できる。
>
> 出力例・表の中の値は `<WIN_USER>` / `<WIN_HOST>` / `<N>`（`rdp-tcp#<N>` の番号）のプレースホルダで書いてある。
>
> Windows のパスワードはこの文書に載せない（`tscon` の `/password` は使わない）。

手順書全体に関わる理由・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

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

- [ショートカットで切断する（任意）](../windows-rdp-disconnect.md#ショートカットで切断する任意)の手順 1 のブロックを 2 回続けて流し、どちらも `<一時的な HOME>/Desktop/RDP をロックせずに切断.lnk（管理者として実行: True）` が出た
- できた `.lnk` を pylnk3 で読むと、`RunAsUser` が `True` で、ターゲット（`C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`）・引数・アイコン（`C:\Windows\System32\mstsc.exe` の 0）が手順のとおりだった
- 偽物の `Save` が `.lnk` でないファイル（先頭が `0x01`）を書くようにすると、`中断: … がショートカットの形式でない` で止まり、ファイルは変えなかった（ブロックの後ろの行は動いた）
- [ロールバック](../windows-rdp-disconnect.md#ロールバック)の手順 1 のブロックは `False` を出し、ファイルが消えた
- 本物の `WScript.Shell` が作る `.lnk` は、pylnk3 が作るものとヘッダーの後ろが違いうる。直すのはヘッダーの中の `LinkFlags` だけ

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. 手順 3 で RDP が切れ、PC の画面がロックされずにデスクトップになること。SSH の `quser` が `console`・`Active` になること
1. 管理者でない PowerShell で手順 3 を貼ったときのエラー
1. ショートカットの UAC の確認と、ダブルクリックで切れること。`WScript.Shell` が作った `.lnk` に印を立てた後、プロパティの「管理者として実行」にチェックが入っていること
1. PC の画面の解像度、モニターの無い PC、蓋を閉じたノート PC
1. 24H2 より前の Windows

### 手順中の実測・検証状況の記録

- **画面の大きさ**: セッションは PC のモニターの解像度に戻るので、RDP の窓に合わせて並べた窓の位置や大きさが変わることがある（確かめていない）

### 手順中の実測・検証状況の記録

- **クリップボード**: SmartBear の資料は、クリップボードが空でないまま切ると、RDP のクリップボードの共有（`rdpclip.exe`）が失敗することがあると書いている（確かめていない）

### 手順中の検証状況

- **ふつうに切断してしまったとき**: もう 1 度 RDP でつないでから、本書の手順で切る。SSH のセッションから `tscon` で戻す形は確かめていない

### 手順中の検証状況

- **モニターの無い PC・蓋を閉じたノート PC**: PC の画面へ戻したときの動きは確かめていない。蓋を閉じたときの動作（既定はスリープ）は、Windows の電源の設定に従う

### 実施手順 / 手順 1: 補足: 管理者の PowerShell を使う理由

- `tscon` で今のセッションを PC の画面（コンソール）へ移すときは、管理者として実行する（SmartBear の TestComplete の資料。管理者でないときに何が出るかは確かめていない）

- 32 ビットの PowerShell では `System32` が `SysWOW64` に読み替えられ、`tscon.exe` が見つからないことがある（確かめていない）

### 実施手順 / 手順 2: 補足: RDP でつないだときのセッション

- `quser` の出力の例は、実機で取っていないので載せていない

### ショートカットで切断する（任意） / 手順 1: 補足: ショートカットの作り

- Microsoft の資料は、この印を「別のユーザーとして動かす」とだけ書いている。プロパティの「管理者として実行」のチェックがこの印に当たることは、Windows では確かめていない

### 選択した方針

- RDP を切るときに PC の画面をロックさせない設定は、本書を書くときに見つけられなかった
