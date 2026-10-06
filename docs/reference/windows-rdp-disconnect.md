# Windows 11 のリモートデスクトップを、画面をロックせずに切断する手順（tscon）の参考資料

[手順書](../windows-rdp-disconnect.md)

## 補足

### 実施手順 / 手順 1: 補足: 管理者の PowerShell を使う理由

[この節の検証記録](../verification/windows-rdp-disconnect.md#実施手順--手順-1-補足-管理者の-powershell-を使う理由)

- `tscon` で今のセッションを PC の画面（コンソール）へ移すときは、管理者として実行する（SmartBear の TestComplete の資料）
- Microsoft の `tscon` の資料は、別のセッションにつなぐには、フル コントロールか「接続」の特殊なアクセス許可が要ると書いている
- 管理者として開いた PowerShell も、RDP でつないだのと同じセッションで動く。手順 2・3 は、このプロセスのセッションの ID を使う
- 32 ビットの PowerShell では `System32` が `SysWOW64` に読み替えられ、`tscon.exe` が見つからないことがある

### 実施手順 / 手順 2: 補足: RDP でつないだときのセッション

[この節の検証記録](../verification/windows-rdp-disconnect.md#実施手順--手順-2-補足-rdp-でつないだときのセッション)

- Windows 11 の Pro では、PC にサインインしているのと同じユーザーで RDP でつなぐと、新しいセッションは作られず、そのセッションが RDP へ移る。PC の画面はロック画面になる
- ふつうに切断する（RDP の窓を閉じる）と、セッションは `Disc`（切断）の状態で残り、PC の画面はロック画面のまま。アプリは動き続ける
- セッションの ID はつなぎ直しても変わらず、セッション名だけが `console` と `rdp-tcp#<N>` で入れ替わる（`<N>` はつなぐたびに変わる）

### 実施手順 / 手順 3: 補足: tscon がすること

- `tscon <セッションの ID> /dest:console` は、そのセッションを `console`（PC の画面とキーボード）につなぎ、今つないでいる RDP を切る（Microsoft の `tscon` の資料の `/dest`）
- 同じユーザーのセッションなので、`/password` は要らない（資料は、別のユーザーのセッションにつなぐときに要ると書いている）
- Microsoft の資料の注意書きの「コンソールのセッションにはつなげない」は、つなぐ先のセッション（最初の引数）に `console` を指すことを言う、と読める。本書は最初の引数に今の RDP のセッションを指し、`/dest:` に `console` を指す（SmartBear の資料と同じ使い方）
- セッションの ID は、`quser` の出力を切り出さずに、この PowerShell のプロセスのセッションの ID（`Process.SessionId`。ターミナル サービスのセッションの ID）から取る。出力の列の位置に頼らないため
- PC の画面は、ロック画面を通らずにデスクトップになる。開いていたアプリはそのまま

### ショートカットで切断する（任意） / 手順 1: 補足: ショートカットの作り

[この節の検証記録](../verification/windows-rdp-disconnect.md#ショートカットで切断する任意--手順-1-補足-ショートカットの作り)

- 動かすのは `powershell.exe -NoProfile -WindowStyle Hidden -Command "tscon.exe (Get-Process -Id $PID).SessionId /dest:console"`。手順 3 と同じコマンドを、隠した窓で動かす
- `Arguments` は単一引用符で囲み、`$PID` を、ショートカットを作る PowerShell ではなく、ショートカットが起動する PowerShell に読ませる
- `WScript.Shell` のショートカットには「管理者として実行」を付ける口が無いので、保存した `.lnk` のバイトを直す
  - `.lnk` の先頭はヘッダー（`ShellLinkHeader`。最初の 4 バイトが大きさの `0x4C`）。オフセット `0x14` からの 4 バイトが `LinkFlags` で、その `RunAsUser`（`0x00002000`）を立てる
  - リトル エンディアンなので、オフセット `0x15` のバイトの `0x20` に当たる（MS-SHLLINK）
  - Microsoft の資料は、この印を「別のユーザーとして動かす」とだけ書いている。チェック項目との対応については検証記録を参照する
- アイコンは「リモート デスクトップ接続」（`mstsc.exe`）のもの
- デスクトップの場所は `[Environment]::GetFolderPath('Desktop')` で取る（OneDrive に移したデスクトップも、この値になる）

### 選択した方針

[この節の検証記録](../verification/windows-rdp-disconnect.md#選択した方針)

- **`tscon` で、今のセッションを PC の画面（コンソール）へ移して切る**

  - UI の自動テストの道具（SmartBear の TestComplete など）が、テストを動かしたまま RDP を切る方法として、同じことを案内している
- **セッションの ID は、PowerShell のプロセスから取る**
  - SmartBear の資料のバッチは、`query user` の出力の 3 列目を ID として取る
  - 本書は出力の列の位置に頼らず、この PowerShell が動いているセッション（RDP でつないでいるセッション）の ID を `(Get-Process -Id $PID).SessionId` で取る
- **ショートカットは、毎回 UAC の確認が出る形にした**（利用者の選択）
  - 最上位の特権のタスクを登録し、ショートカットから `schtasks /run` で動かせば UAC の確認は出ないが、仕組みが増えるので採らなかった
- **採らなかった案**
  - ふつうの切断（RDP の窓を閉じる）: PC の画面がロック画面になる
  - サインアウト: セッションが終わり、動いていたアプリも終わる

### 参照

- [tscon — Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/tscon)（`/dest`、`/password` が要る条件、コンソールのセッションの注意書き）
- [quser — Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/quser)（列の意味、今のセッションに付く `>`）
- [Enable Remote Desktop on your PC — Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/remotepc/remote-desktop-allow-access)（設定の「システム → リモート デスクトップ」、Home は RDP でつながれる側になれないこと）
- [Process.SessionId — Microsoft Learn](https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.process.sessionid)（プロセスのターミナル サービスのセッションの ID）
- MS-SHLLINK の [ShellLinkHeader](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-shllink/c3376b21-0931-45e4-b2fc-a48ac0e60d15)・[LinkFlags](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-shllink/ae350202-3ba9-4790-9e9e-98935f4ee5af)（`.lnk` のヘッダーと `RunAsUser`）、[SHELL_LINK_DATA_FLAGS](https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/ne-shlobj_core-shell_link_data_flags)（`SLDF_RUNAS_USER` = `0x00002000`）
- [Disconnecting From Remote Desktop While Running Automated Tests — SmartBear TestComplete](https://support.smartbear.com/testcomplete/docs/testing-with/running/via-rdp/keeping-computer-unlocked.html)（`tscon … /dest:console` を管理者として実行する、ロックされないことの注意、`rdpclip.exe`）
- [Windows の OpenSSH サーバー](../windows-openssh-server.md)（手順 4・5 の SSH）
- [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)（デスクトップにサインインしていることを前提にする手順書）

---
