# Windows PowerShell に複数行のブロックを貼れるようにする手順（PSReadLine の Ctrl+Enter）

## 実施手順

> [!IMPORTANT]
> - **すべて Windows の Windows PowerShell（5.1）で行う**。管理者でなくてよい（同じユーザーなら、管理者の窓も同じ設定を読む）。PowerShell 7（`pwsh`）は対象外
> - **手順 1 は 1 行なので、どの貼り方でもそのまま貼れる**。手順 1 を貼った窓には、手順 2 からの複数行のブロックを、コピーボタンでコピーして右クリックで貼れる
> - **手順 5 で窓を開き直す**。手順 6・7 は新しい窓に貼る

- 上から順にコードブロックを貼る。GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 戻すときは[ロールバック](#ロールバック)

> [!WARNING]
> **この手順書の手順は、まだ実機でそのまま流していない**（2026-10-03 に書いた）。確かめたのは、原因と、手順 1 の 1 行で直ること（実機の conhost の窓）、手順 4 とロールバックの手順 1 のブロック（プロファイルの場所を一時的なファイルに差し替えた）だけ（[対象と検証環境](#対象と検証環境)）

1. 今の窓だけ、Ctrl+Enter を「行を足す」にする。

   ```powershell
   Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine
   ```

   - 何も出なければよい
   - この窓を閉じるまで効く。手順 2〜4 の複数行のブロックを、この窓に右クリックで貼れるようにするため

   <details>
   <summary>補足: 行が逆順になる理由</summary>

   - GitHub のコピーボタンは、ブロックの改行を LF だけにしてクリップボードに入れる（末尾の改行も無い）。マウスで選んで Ctrl+C でコピーしたものは、改行が CR LF になる
   - conhost の窓（Windows Terminal ではない窓。この PC では、スタートメニューから管理者として開いた Windows PowerShell）に右クリックで貼ると、LF は Ctrl+Enter のキーとして届く
   - Windows PowerShell 5.1 の PSReadLine 2.0.0 では、Ctrl+Enter は `InsertLineAbove`（今の行の上に空の行を作り、そこへ移る）。貼った行が 1 行ずつ上に入るので、ブロックが逆順になる
   - `AddLine` は Shift+Enter と同じ働きで、実行せずに次の行へ進む。LF が来るたびに次の行へ進むので元の順に入り、最後に Enter を押すとブロック全体が 1 回で動く
   - 管理者でない窓（この PC では Windows Terminal の中に開く）と、conhost の窓に Ctrl+V で貼ったときは、設定が無くても逆順にならなかった（利用者が確かめた）
   - 実測は[付録](#付録-原因の確認と貼り付けの試験2026-10-03)

   </details>

1. Windows PowerShell の版と、実行ポリシーと、プロファイルを確かめる。

   ```powershell
   'PowerShell: {0}' -f $PSVersionTable.PSVersion
   Get-ExecutionPolicy -List | Format-Table -AutoSize
   '実行ポリシー: {0}' -f (Get-ExecutionPolicy)
   'プロファイル: {0}（ある: {1}）' -f $PROFILE, (Test-Path -LiteralPath $PROFILE)
   ```

   - `PowerShell: 5.1.…` が出る。`7.…` なら、スタートメニューの「Windows PowerShell」で開き直し、手順 1 から貼る
   - `実行ポリシー:` が `RemoteSigned` か `Unrestricted` なら、手順 3 は飛ばす
   - Windows 11 の既定は `Restricted`（一覧はどれも `Undefined`）。このままではプロファイルが読まれない
   - 一覧の `MachinePolicy` か `UserPolicy` が `Undefined` でなければ、グループ ポリシーで決まっていて、手順 3 では変えられない
   - `プロファイル:` は、このユーザーの Windows PowerShell が起動のときに読むファイル。`ある: False` なら、手順 4 で作る

   <details>
   <summary>補足: 実行ポリシーとプロファイル</summary>

   - プロファイルもスクリプト（`.ps1`）なので、実行ポリシーが `Restricted` だと読まれない（Microsoft の about_Execution_Policies。`Restricted` は Windows のクライアントの既定）
   - この手順書を書いた PC は、scoop を入れたときに `CurrentUser` が `RemoteSigned` になっていて、ほかの範囲はどれも `Undefined` だった
   - `$PROFILE` は、このユーザーの、Windows PowerShell のコンソールのプロファイル（`Microsoft.PowerShell_profile.ps1`）。管理者で開いた窓も、同じユーザーなら同じファイルを読む。PowerShell 7・PowerShell ISE・VS Code は別のファイルを読む（about_Profiles）

   </details>

1. 手順 2 の実行ポリシーが `Restricted` などのときだけ、このユーザーの実行ポリシーを `RemoteSigned` にする。

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
   Get-ExecutionPolicy
   ```

   - `RemoteSigned` が出ればよい
   - エラーが出て、ほかの値が出たら、グループ ポリシーなどで決まっている。この手順書は使えないので、[ロールバック](#ロールバック)の手順 2 で戻し、ほかの手順書のブロックは conhost の窓でも Ctrl+V で貼る

   <details>
   <summary>補足: RemoteSigned にすること</summary>

   - `RemoteSigned` は、この PC で作ったスクリプトを署名無しで動かし、インターネットから落としたスクリプトには署名を求める（about_Execution_Policies）
   - `-Scope CurrentUser` なので、変わるのはこのユーザーだけで、管理者の権限は要らない
   - `-Force` は、変えてよいかの確認を出さないため

   </details>

1. プロファイルに、手順 1 と同じ 1 行を足す。

   ```powershell
   & {
     $line = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-powershell-paste.md'
     if (-not (Test-Path -LiteralPath $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
     $text = Get-Content -LiteralPath $PROFILE -Raw
     if ($text -and $text.Contains($line)) { "すでにある: $PROFILE" } else {
       if ($text -and -not $text.EndsWith("`n")) { $line = "`r`n" + $line }
       Add-Content -LiteralPath $PROFILE -Value $line
       "足した: $PROFILE"
     }
     Get-Content -LiteralPath $PROFILE
   }
   ```

   - `足した: C:\Users\<WIN_USER>\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` と、足した行が出ればよい（OneDrive でドキュメントをバックアップしていると、`OneDrive` の下のパスになる）
   - プロファイルにほかの行があれば、それも出る（そのまま残る）
   - 何度貼ってもよい（2 回目からは `すでにある:`）

   <details>
   <summary>補足: プロファイルの書き方</summary>

   - プロファイルが無ければ、`New-Item -Force` がフォルダ（`WindowsPowerShell`）ごと作る
   - 行の末尾の `# windows-powershell-paste.md` は、[ロールバック](#ロールバック)で消す行を見分けるための印
   - 足す行は ASCII の文字だけなので、既存のプロファイルの文字コードによらず足せる。Windows PowerShell 5.1 の `Add-Content` は、既存のファイルの BOM（UTF-16 LE・UTF-8）を見て、同じ文字コードで足した
   - `Add-Content` は、ファイルの末尾が改行でなくても改行を足さずに書き足す（最後の行につながった）。そのときは、行の前に改行を付けて足す
   - 対話でない起動（標準入力をリダイレクトした `powershell -Command`）でも、この行はエラーを出さなかった
   - 実測は[付録](#付録-原因の確認と貼り付けの試験2026-10-03)

   </details>

1. この窓を閉じ、Windows PowerShell（5.1）を開き直す。

   - これからほかの手順書を貼る窓（管理者の Windows PowerShell など）で開いてよい
   - 開いたときに、プロファイルを読めないという赤い字のエラーが出たら、実行ポリシーが `Restricted` のまま。手順 2 から確かめ直す
   - **次の手順は、新しい窓が開いてから貼る**

1. 新しい窓で、Ctrl+Enter が「行を足す」になったことを確かめる。

   ```powershell
   (Get-PSReadLineKeyHandler -Bound | Where-Object Key -eq 'Ctrl+Enter').Function
   ```

   - `AddLine` が出ればよい（設定する前は `InsertLineAbove`）

1. 複数行のブロックをコピーボタンでコピーして右クリックで貼り、元の順に動くことを確かめる。

   ```powershell
   & {
     '1 行目'
     '2 行目'
     '3 行目'
   }
   ```

   - このブロックを GitHub のコピーボタンでコピーし、新しい窓の中で右クリックして貼る
   - 最後の `}` の行で止まるので、Enter を押す
   - `1 行目`・`2 行目`・`3 行目` の順に出ればよい

---

## ロールバック

- この節は、このユーザーの Windows PowerShell（5.1）に貼る（管理者でなくてよい）。開いている窓の設定（[手順 1](#実施手順)）は、窓を閉じるまで残る
- 戻した後は、この設定を前提にする手順書の PowerShell のブロックを、conhost の窓では Ctrl+V で貼る（右クリックで貼ると、行が逆順になる）

1. プロファイルから、手順 4 で足した行を消す。

   ```powershell
   & {
     $line = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-powershell-paste.md'
     if (-not (Test-Path -LiteralPath $PROFILE)) { "プロファイルが無い: $PROFILE"; return }
     $bytes = [System.IO.File]::ReadAllBytes($PROFILE)
     $enc = if ($bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { [System.Text.Encoding]::Unicode } else { [System.Text.Encoding]::GetEncoding(28591) }
     $text = $enc.GetString($bytes)
     $rest = [regex]::Replace($text, '(?m)^(\uFEFF|\u00EF\u00BB\u00BF)?' + [regex]::Escape($line) + '\r?\n?', '$1')
     if ($rest -eq $text) { "その行は無い: $PROFILE" } elseif ($rest -match '^(\uFEFF|\u00EF\u00BB\u00BF)?\s*$') { Remove-Item -LiteralPath $PROFILE; "消した: $PROFILE" } else { [System.IO.File]::WriteAllBytes($PROFILE, $enc.GetBytes($rest)); "その行だけ消した: $PROFILE" }
   }
   ```

   - プロファイルにほかの行が無ければ `消した:`、あれば `その行だけ消した:` が出る

   <details>
   <summary>補足: 文字コードを変えずに消す</summary>

   - ファイルをバイトのまま読み、消す行のほかのバイトは変えずに書き戻す
   - 先頭が `FF FE`（UTF-16 LE の BOM）なら UTF-16 LE として、それ以外は 1 バイトを 1 文字にする Latin-1（コードページ 28591）として読み書きする。消す行は ASCII の文字だけなので、UTF-8（BOM の有無によらない）・Shift_JIS のどちらでも同じバイトで見つかる
   - ファイルの 1 行目は BOM の直後にあるので、行の前の BOM を許して探し、BOM は残す
   - 残りが BOM と空白だけなら、ファイルを消す
   - `Get-Content` と `Set-Content` で書き直さないのは、Windows PowerShell 5.1 が BOM の無いファイルを ANSI（日本語の Windows では Shift_JIS）として読み、`Set-Content` が指定しないと ANSI で書くため。BOM の無い UTF-8 の日本語が化ける

   </details>

1. [手順 3](#実施手順) で実行ポリシーを変えたときだけ、元に戻す。

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Undefined -Force
   Get-ExecutionPolicy
   ```

   - `Restricted` が出ればよい（Windows 11 の既定）
   - **注意**: scoop など、`RemoteSigned` を前提にするものを使っているなら戻さない（`scoop` のコマンドは PowerShell のスクリプトとして動く）

---

## 補足

### 対象と検証環境

- **目的**: GitHub の手順書のコピーボタンでコピーした PowerShell のブロックを、Windows PowerShell 5.1 の窓に右クリックで貼っても、行の順が変わらないようにする
  - conhost の窓（この PC では、スタートメニューから管理者として開いた Windows PowerShell）に右クリックで貼ると、行が逆順に入り、ブロックが動かない
  - [Windows の OpenSSH サーバー](windows-openssh-server.md)・[Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)・[RDP をロックせずに切断（Windows）](windows-rdp-disconnect.md)・[Syncthing の Windows 11 の節](syncthing.md#windows-11-で使う)は、この設定を前提にする
- **進め方**: このユーザーの Windows PowerShell のプロファイルに、`Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine` の 1 行を足す
  - プロファイルを読ませるため、実行ポリシーが `Restricted` なら、このユーザーだけ `RemoteSigned` にする
  - 変数は無い
- **状態**: 原因と直し方は実機で確かめた。この手順書の手順は、まだ実機でそのまま流していない（2026-10-03）
  - **確かめたこと**（[付録](#付録-原因の確認と貼り付けの試験2026-10-03)）:
    - 利用者の観察: Firefox で開いた GitHub のコピーボタンでコピーし、管理者の Windows PowerShell（conhost）に右クリックで貼ると、行が逆順になる。管理者でない窓（Windows Terminal）と、conhost の窓に Ctrl+V で貼ったとき、選んで Ctrl+C でコピーしたときは起きない
    - コピーボタンの中身（GitHub が描画した HTML と、Firefox でコピーした後のクリップボード）: 改行は LF だけで、末尾に改行が無い
    - 実機の `conhost.exe` で開いた Windows PowerShell 5.1 に、LF だけのブロックを貼った: 設定の前は逆順、手順 1 の 1 行の後と、同じ行を書いたファイルを起動のときに読ませた後は元の順で、Enter で全部が動いた。CR LF のブロックは、設定の有無によらず元の順
    - 手順 4 とロールバックの手順 1 のブロック: `$PROFILE` を一時的なファイルに差し替えた Windows PowerShell 5.1 で、プロファイルが無い・空・ほかの行がある（UTF-16 LE、UTF-8 の BOM の有無、Shift_JIS）・すでに行がある（BOM の直後を含む）の各場合
    - すべての `powershell` のブロックの構文: Windows PowerShell 5.1 の構文解析器
  - **確かめていないこと**: 本物のプロファイルに書いて開き直すこと（手順 4〜7）、手順 3 の実行ポリシーの変更とロールバックの手順 2、グループ ポリシーのある PC、右クリックそのもの（試験は conhost の貼り付けのコマンドを送った）、SSH でログインしたセッション、Edge・Chrome のコピーボタン
- 下表は、確かめた環境

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro（10.0.26300。x86_64 のノート PC） |
| PowerShell | Windows PowerShell 5.1.26100.9444（PSReadLine 2.0.0） |
| 窓 | conhost（`conhost.exe` で開いた窓。利用者の管理者の Windows PowerShell も conhost）。管理者でない窓は Windows Terminal 1.25.2733.0 |
| コピー | GitHub の Web のコードブロックのコピーボタン（Firefox） |

> [!NOTE]
> この手順書には変数が無い。コマンドはそのまま貼って実行できる。
>
> 出力例の値は `<WIN_USER>`（Windows のユーザー名）のプレースホルダで書いてある。パスワードは扱わない。

手順書全体に関わる理由・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 選択した方針

- **PSReadLine の Ctrl+Enter を `AddLine` にする**（利用者の選択）
  - 窓の種類（conhost・Windows Terminal）と貼り方（右クリック・Ctrl+V）を選ばずに、コピーボタンのブロックをそのまま貼れる
  - プロファイルに書くので、窓を開くたびに貼り直さなくてよい
- **採らなかった案**
  - 管理者の Windows PowerShell を Windows Terminal で開く: 設定は変えずに済むが、開き方を変える必要がある（この PC では、スタートメニューから管理者で開くと conhost になり、Windows Terminal の既定のプロファイルは Git Bash だった）
  - conhost の窓では Ctrl+V で貼る: 設定は変えずに済むが、右クリックで貼ると逆順になるのは残る（[ロールバック](#ロールバック)の後の貼り方として、その節のリードに書いた）
  - ブロックを 1 行に書く: 手順書が読みにくくなる
  - 選んで Ctrl+C でコピーする: コピーボタンを使えない
  - コピーボタンの中身の改行を変える: 中身は GitHub が作る（改行は LF）

### 注意点

- **Ctrl+Enter で上に行を作る操作（`InsertLineAbove`）は使えなくなる**: 下に行を作る Shift+Ctrl+Enter（`InsertLineBelow`）と、Shift+Enter（`AddLine`）はそのまま
- **貼ったブロックは、Enter を押すまで動かない**: コピーボタンの中身は末尾に改行が無いため。設定の後の conhost の窓では、ブロック全体が 1 つの入力になり、Enter で 1 回で動く
- **このユーザーの Windows PowerShell のコンソールの窓すべてに効く**: 管理者の窓も同じプロファイルを読む。SSH でログインしたセッションの Windows PowerShell で、SSH のクライアントから貼ったときの動きは確かめていない
- **PowerShell 7 には効かない**: PowerShell 7 は別のプロファイル（`Documents\PowerShell\Microsoft.PowerShell_profile.ps1`）を読む。この PC の PowerShell 7.6.6（PSReadLine 2.4.5）でも、Ctrl+Enter は `InsertLineAbove` だった
- **実行ポリシー**: 手順 3 で `RemoteSigned` にすると、このユーザーは、この PC で作ったスクリプト（`.ps1`）を署名無しで動かせる

### 参照

- [about_Profiles — Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-5.1)（`$PROFILE` の場所、ホストごとのプロファイル）
- [about_Execution_Policies — Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1)（`Restricted` は Windows のクライアントの既定、`RemoteSigned`、範囲の優先順）
- [Set-ExecutionPolicy — Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-5.1)
- [Set-PSReadLineKeyHandler — Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlinekeyhandler?view=powershell-5.1)
- [about_PSReadLine_Functions — Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline_functions?view=powershell-5.1)（`AddLine` は Shift+Enter、`InsertLineAbove` は Ctrl+Enter）

---

### 付録: 原因の確認と貼り付けの試験（2026-10-03）

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
| LF だけ（末尾に改行無し） | `-Command` で手順 1 の 1 行 | 元の順（`}` が最後の行） | `1 行目` / `2 行目` / `3 行目` |
| LF だけ（末尾に改行無し） | 同じ行（印のコメント付き）を書いたファイルを `-Command` の `.` で読ませた | 元の順 | `1 行目` / `2 行目` / `3 行目` |
| CR LF（末尾に改行あり） | 無し | — | `1 行目` / `2 行目` / `3 行目` |
| CR LF（末尾に改行あり） | `-Command` で手順 1 の 1 行 | — | `1 行目` / `2 行目` / `3 行目` |

**対話でない起動**: 標準入力をリダイレクトした `powershell.exe -NoProfile -Command "Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine; 'ok'"` は、エラー無しで `ok` を出した。

**`Add-Content` の書き足し方**: Windows PowerShell 5.1 で、末尾に改行の無いファイル（`Set-Alias ll Get-ChildItem`）に `Add-Content` で 1 行を足すと、`Set-Alias ll Get-ChildItemX-LINE` と最後の行につながった。手順 4 のブロックは、そのときに行の前へ CR LF を付ける。

**手順 4 とロールバックの手順 1 のブロック**: この文書から `powershell` のブロックを抜き出し（リストの字下げを外した）、Windows PowerShell 5.1 で、`$PROFILE` を一時的なディレクトリの `WindowsPowerShell\Microsoft.PowerShell_profile.ps1` に差し替えて `Invoke-Expression` で流した。どの場合も手順 4 を 2 回（2 回目は `すでにある:`）、ロールバックの手順 1 を 2 回（2 回目は `その行は無い:` か `プロファイルが無い:`）流した。既存のプロファイルの中身は、日本語のコメントと `Set-Alias ll Get-ChildItem` の 2 行:

| 既存のプロファイル | 手順 4 の後 | ロールバックの手順 1 の後 |
|---|---|---|
| 無い | `足した:`。ASCII の 1 行（93 バイト） | `消した:`（ファイルが消えた） |
| 空のファイル | 同じ | `消した:` |
| UTF-16 LE（BOM あり） | 先頭は `FF FE` のまま。足した行は 3 行目 | `その行だけ消した:`。前と同じバイト |
| UTF-8（BOM あり） | 先頭は `EF BB BF` のまま。足した行は 3 行目 | 前と同じバイト |
| UTF-8（BOM 無し）、末尾に改行無し | 足した行は 3 行目（前に CR LF を付けた）。5.1 の `Get-Content` では日本語が化けて見えた（ANSI として読む）が、バイトは変わらない | 日本語を含め前と同じバイトに、手順 4 で付けた CR LF だけが残った |
| Shift_JIS | 足した行は 3 行目 | 前と同じバイト |
| UTF-16 LE・UTF-8（BOM あり）で、手順 4 の行だけ | `すでにある:` | `消した:`（ファイルが消えた） |
| UTF-16 LE・UTF-8（BOM あり）で、1 行目が手順 4 の行、2 行目が `Set-Alias` | — | `その行だけ消した:`。BOM と `Set-Alias` の行だけが残った |

最初に書いたロールバックの手順 1 は、正規表現が `(?m)^` と行だけだったので、BOM の直後（ファイルの 1 行目）にある行を見つけられず、BOM のあるファイルで `その行は無い:` を出した。BOM を許して残すように直し、上の表はすべて直した後のもの。

**構文**: この文書の `powershell` のブロック 8 個を、Windows PowerShell 5.1 の `[System.Management.Automation.Language.Parser]::ParseInput` に通した（構文の誤りは 0）。
