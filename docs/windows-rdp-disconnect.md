# Windows 11 のリモートデスクトップを、画面をロックせずに切断する手順（tscon）

## 実施手順

- [検証記録](verification/windows-rdp-disconnect.md)・[参考資料](reference/windows-rdp-disconnect.md)・[ロールバックと注意点](extra/windows-rdp-disconnect.md)

> [!IMPORTANT]
> - **手順 1〜3 は、RDP（リモートデスクトップ）でつないだ Windows のセッションの中で行う**。手順 1 で管理者の Windows PowerShell（5.1）を開き、手順 2・3 をそこに貼る
> - 前提: Windows 11 Pro 以上で、リモート デスクトップがオンになっていて（[Windows 11 の初期設定の手順 44](windows-setup.md#実施手順)、または設定の「システム → リモート デスクトップ」）、RDP でつなげること（Home は RDP でつながれる側になれない）。PC にサインインしているのと同じユーザーでつなぐ。そのユーザーは Administrators の一員（手順 3 の `tscon` に管理者の権限が要る）
> - 前提: [Windows 11 の初期設定の手順 16〜19](windows-setup.md#実施手順)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - **手順 3 を貼ると、その場で RDP が切れる**
> - **手順 4・5 は、クライアントの PC から SSH で行う**（[Windows の OpenSSH サーバー](windows-openssh-server.md)）。SSH が無ければ、PC の前で画面を見る

- 上から順にコードブロックを貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 手順の後: 毎回の切断をデスクトップのアイコンのダブルクリックにするなら[ショートカットで切断する（任意）](#ショートカットで切断する任意)、そのショートカットを消すときは[ロールバック](extra/windows-rdp-disconnect.md#ロールバック)

> [!WARNING]
> - **切断した後の PC の画面はロックされない**。PC の前にいる人が、このユーザー（Administrators の一員）としてそのまま操作できる。人が触れる場所にある PC では使わない

1. RDP でつないだセッションの中で、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」を選ぶ。UAC の確認で「はい」
   - ウィンドウのタイトルが「管理者: Windows PowerShell」になる
   - 「Windows PowerShell (x86)」（32 ビット）は使わない
   - **次の手順は、このウィンドウが開いてから、そこに貼る**

1. 今のセッションが RDP であることと、その ID を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   quser
   'このセッションの ID: {0}' -f (Get-Process -Id $PID).SessionId
   ```

   - `quser` の自分の行（先頭に `>` が付く）のセッション名が `rdp-tcp#<N>` で、状態が `Active`
   - その行の ID と、最後の行の ID が同じ
   - 自分の行のセッション名が `console` なら、PC の前のセッション（RDP ではない）。手順 3 は貼らない

1. セッションを PC の画面（コンソール）へ移し、RDP を切る。

   ```powershell
   tscon.exe (Get-Process -Id $PID).SessionId /dest:console
   ```

   - RDP のクライアントの窓が閉じる（クライアントが切断を知らせる）
   - 切れずに PowerShell にエラーが出たときは、管理者の PowerShell かを確かめて、手順 1 からやり直す
   - **次の手順は、RDP が切れてから、クライアントの PC で行う**（この手順の後ろに行を続けて貼らない）

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
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     '{0}（管理者として実行: {1}）' -f $lnk, [bool]([System.IO.File]::ReadAllBytes($lnk)[0x15] -band 0x20)
   }
   ```

   - `C:\Users\<WIN_USER>\Desktop\RDP をロックせずに切断.lnk（管理者として実行: True）` が出ればよい（OneDrive でデスクトップをバックアップしていると、`OneDrive` の下のパスになる）
   - デスクトップに「RDP をロックせずに切断」のアイコンが出る
   - 何度貼ってもよい
   - 同じ印は、画面でも付けられる: ショートカットのプロパティの「ショートカット」タブの「詳細設定」で、「管理者として実行」にチェックを入れる

1. 切断するときは、RDP でつないだセッションの中で、デスクトップのショートカットをダブルクリックする。

   - UAC の確認（Windows PowerShell）で「はい」を押すと、RDP が切れる（実施手順の手順 3 と同じ）
   - 切れないときは、[実施手順](#実施手順)の手順 1〜3 で切って、エラーを見る
   - PC の前（コンソール）では使わない
   - 切った後の確かめ方は、実施手順の手順 4・5 と同じ
