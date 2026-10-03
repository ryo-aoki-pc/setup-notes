# Windows 11 で Syncthing を使う手順（公式の zip + タスク スケジューラ）

## 実施手順

> [!IMPORTANT]
> - **すべて Windows で行う**。手順 1 で管理者の Windows PowerShell（5.1）を開き、手順 2〜11・14 と後ろの節をそこに貼る。ログインするユーザーは Administrators の一員（手順 7 の受信の規則と手順 8 のタスクの登録に、管理者の権限が要る）
> - Syncthing そのものは、管理者ではない自分のユーザーとして、サインインしている間だけ動く（手順 8 のタスク）
> - **手順 5 には対話入力がある**（GUI のパスワード）。入力し終えてから手順 6 を貼る
> - **手順 12 は LAN の別の端末のブラウザで、手順 13 はこの PC で行う**（サインアウトしてサインインし直す）

- 上から順にコードブロックを貼る。手順 2 で変数を設定した PowerShell に貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 同期するフォルダと相手のデバイスは[同期フォルダとデバイスを追加する（任意）](#同期フォルダとデバイスを追加する任意)、止めるときは[止める・もう一度始める](#止めるもう一度始める)。以後は[更新](#更新)・[ロールバック](#ロールバック)
- AlmaLinux 10 の Syncthing は [syncthing.md](syncthing.md)。この手順書の PC は、その相手にもなる

> [!WARNING]
> **この手順書は Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、配布物の中身と署名、Syncthing のソース、Linux の同じ版での CLI の動き、PowerShell の構文だけ（[対象と検証環境](#対象と検証環境)）。

1. Windows で、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く
   - PowerShell 7（`pwsh`）ではなく、Windows PowerShell 5.1 にする（手順 6 のパイプの文字コードが違う）

1. 変数を設定する。

   ```powershell
   $ST_GUI_USER = $env:USERNAME          # GUI のログイン名。Windows のアカウントとは別物（自動で同じ名前が入る）。<WIN_USER>
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # 相手とつながる LAN の接続（自動）。<LAN_IF>
   'ST_GUI_USER = {0}' -f $ST_GUI_USER
   'LAN_IF      = {0}' -f $LAN_IF
   ```

   - **編集が必須の変数は無い**
   - 最後に値を読み戻して確かめる
   - `LAN_IF` は、インターネットにつながっている接続の名前（`イーサネット`、`Wi-Fi` など）。相手とつながる接続と違えば、`$LAN_IF = 'Wi-Fi'` のように直す
   - 変数はその PowerShell の中だけで有効。**新しい PowerShell を開いたら**、手順 2 のブロックを貼り直してから先へ進む

   <details>
   <summary>補足: 変数について</summary>

   - `$ST_GUI_USER` は **Syncthing の Web GUI にログインするための名前**で、Windows のアカウントとは関係が無い。自動で同じ名前が入るだけなので、別の名前にしてもよい（[syncthing.md](syncthing.md) の `ST_GUI_USER` と同じ扱い）
   - `$LAN_IF` は、手順 7（ネットワークをプライベートにする）・手順 11（GUI の URL を出す）・[ロールバック](#ロールバック)の手順 4 で使う。式は [Windows の OpenSSH サーバー](windows-openssh-server.md)の手順 2 と同じ
   - GUI の待ち受け（`0.0.0.0:8384`）と実行ファイルの場所（`%LOCALAPPDATA%\Programs\Syncthing\syncthing.exe`）は変える必要が無いので、変数にせずブロックに直接書いてある
   - パスワードは変数に置いたままにしない。手順 5 で読み取り、手順 6 で使ったら消す

   </details>

1. この PC に Syncthing が無いことを確かめる。

   ```powershell
   Get-Process -Name syncthing -ErrorAction SilentlyContinue | Format-Table Id, Path
   Get-ScheduledTask -TaskName 'Syncthing' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   Get-NetTCPConnection -State Listen -LocalPort 8384, 22000 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   Test-Path "$env:LOCALAPPDATA\Syncthing\config.xml", "$env:LOCALAPPDATA\Programs\Syncthing"
   ```

   - 最初の 3 つは何も出さず、最後に `False` が 2 行出ればよい
   - 何か出たら、ほかの方法で入れた Syncthing（SyncTrayzor、Syncthing Windows Setup など）がある。それを止めて外してから始める
   - [ロールバック](#ロールバック)の手順 1〜4 の後に入れ直すときは、1 行目の `True`（`config.xml`。前の鍵と設定）はそのままでよい。手順 6 が前の鍵を使うので、デバイス ID は前と同じになる

   <details>
   <summary>補足: ほかの Syncthing と重ならないようにする理由</summary>

   - Syncthing の設定と DB の置き場所は、Windows では `%LOCALAPPDATA%\Syncthing` に決まっている（ソースの `lib/locations`）。Syncthing Windows Setup の個人用の導入も、同じ場所を使う（その README）
   - 同じ設定で 2 つの Syncthing を動かすことはできない（設定のフォルダーの `syncthing.lock` で、後から起動した方が止まる）
   - 同じ待ち受けの番号（8384・22000）を、2 つの Syncthing で取り合うことにもなる

   </details>

1. 公式の zip を取って sha256 と署名を確かめ、`syncthing.exe` を置く。

   ```powershell
   & {
     $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
     $curl = "$env:WINDIR\System32\curl.exe"
     $arch = @{ AMD64 = 'amd64'; ARM64 = 'arm64' }[$env:PROCESSOR_ARCHITECTURE]
     $tmp = "$env:TEMP\syncthing-setup"
     if (Get-Process -Name syncthing -ErrorAction SilentlyContinue) { Write-Error '中断: Syncthing が動いている'; return }
     if (-not $arch) { Write-Error "中断: この手順は $env:PROCESSOR_ARCHITECTURE の Windows を扱わない"; return }
     Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & $curl -fsSL -o "$tmp\sha256sum.txt.asc" https://github.com/syncthing/syncthing/releases/latest/download/sha256sum.txt.asc
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: sha256sum.txt.asc を取れない'; return }
     $m = Select-String -LiteralPath "$tmp\sha256sum.txt.asc" -CaseSensitive -Pattern "^([0-9a-f]{64})  (syncthing-windows-$arch-(v\d+\.\d+\.\d+)\.zip)$" | Select-Object -First 1
     if (-not $m) { Write-Error '中断: sha256sum.txt.asc に Windows 版の行が無い'; return }
     $hash = $m.Matches[0].Groups[1].Value
     $zip = $m.Matches[0].Groups[2].Value
     $ver = $m.Matches[0].Groups[3].Value
     & $curl -fsSL -o "$tmp\$zip" "https://github.com/syncthing/syncthing/releases/download/$ver/$zip"
     if ($LASTEXITCODE -ne 0) { Write-Error "中断: $zip を取れない"; return }
     if ((Get-FileHash -LiteralPath "$tmp\$zip" -Algorithm SHA256).Hash -ne $hash) { Write-Error "中断: $zip の sha256 が一致しない"; return }
     Expand-Archive -LiteralPath "$tmp\$zip" -DestinationPath $tmp -Force
     $new = Join-Path $tmp (($zip -replace '\.zip$', '') + '\syncthing.exe')
     $sig = Get-AuthenticodeSignature -LiteralPath $new
     if ($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notlike 'CN=Kastelo AB,*' -or -not $sig.TimeStamperCertificate) { Write-Error "中断: syncthing.exe の署名を確かめられない（$($sig.Status)）"; return }
     New-Item -ItemType Directory -Force -Path (Split-Path $exe) | Out-Null
     Copy-Item -LiteralPath $new -Destination $exe -Force
     Remove-Item -LiteralPath $tmp -Recurse -Force
     '{0}: sha256 一致、署名 {1}' -f $zip, $sig.Status
     & $exe --version
     icacls.exe (Split-Path $exe)
   }
   ```

   - `syncthing-windows-amd64-v2.1.5.zip: sha256 一致、署名 Valid` と、`syncthing v2.1.5 "Hafnium Hornet" (go1.27.1 windows-amd64) …` の 1 行が出ればよい（版は実行した日の最新）
   - `icacls` の一覧に、自分のユーザーの `(F)`（フル コントロール）の行がある（Syncthing の自動の更新が、このフォルダーに書くため）
   - `中断:` で始まるエラーが出たら、何も置いていない（取ってきたものは `%TEMP%\syncthing-setup` に残る。次に貼ったときに消して作り直す）
   - 何度貼ってもよい（Syncthing が動いているときは止まる）

   <details>
   <summary>補足: 確かめていることと、ブロックの作り</summary>

   **sha256 と署名**

   - `sha256sum.txt.asc` は、公式のリリースのファイルの sha256 の一覧（GPG で署名した平文）。その中の `syncthing-windows-<構成>-<版>.zip` の行と、取ってきた zip を比べる。GPG の署名はここでは確かめないので、この比較で分かるのは zip が壊れていないことまで
   - 本物かどうかは、`syncthing.exe` の Authenticode の署名で確かめる。署名者は `CN=Kastelo AB`（Syncthing の開発元の会社）で、Microsoft の Trusted Signing の証明書。証明書の期限は 3 日と短いので、タイムスタンプが付いていること（`TimeStamperCertificate`）も見る（[付録](#付録-配布物と資料の調査2026-10-03)）
   - 署名者の名前は `CN=` の部分だけを見る（`L=` に ASCII でない文字があるため）

   **ブロックの作り**

   - 全体を `& { … }` で囲み、確かめられなかったら `return` でそこで止める（後ろの行を動かさない）
   - 最新の版は、`releases/latest/download/sha256sum.txt.asc`（最新のリリースへ飛ぶ）の中の zip の名前から取る。版を調べるための別の問い合わせ（GitHub の API）はしない
   - `curl.exe` は `C:\Windows\System32\curl.exe` を呼ぶ。Git for Windows や scoop の `curl` が `PATH` の先にある PC でも、同じものを使うため（[Windows の OpenSSH サーバー](windows-openssh-server.md)の手順 7 の補足と同じ理由）
   - `curl.exe` で取ったファイルには、ブラウザで取ったときのような「インターネットから来た」印（Mark of the Web）が付かないので、SmartScreen の確認は出ないはず（確かめていない）
   - `%PROCESSOR_ARCHITECTURE%` が `AMD64` なら `amd64`、`ARM64` なら `arm64` の zip を取る。arm64 の版は試していない

   **置き場所**

   - `%LOCALAPPDATA%\Programs\Syncthing` は、自分のユーザーだけが使うプログラムの置き場所。Syncthing Windows Setup の個人用の導入も同じ場所を使う
   - 置くのは `syncthing.exe` だけ（zip のほかのファイルは `README.txt` などと、Linux・macOS 向けの `etc/`）
   - 管理者の PowerShell で作ったフォルダーとファイルは、所有者が `BUILTIN\Administrators` になるが、アクセス権は `%LOCALAPPDATA%` から受け継ぐので、自分のユーザー（管理者ではない Syncthing）も書き換えられる。それを `icacls` で確かめる

   </details>

1. GUI のパスワードを読み取る。

   ```powershell
   $ST_GUI_PASS = Read-Host -AsSecureString 'Syncthing GUI のパスワード'
   ```

   - **入力は `*` で表示される**
   - ASCII の英数字と記号だけにする（ほかの文字があると、手順 6 で止まる）
   - **次の手順は、パスワードを入力し終えてから貼る**（続けて貼るとパスワードとして食われる）

1. 最初に起動する前に、鍵と設定を作り、GUI のログイン名とパスワードを入れる。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   if (-not $ST_GUI_USER) {
     Write-Error '手順 2 の $ST_GUI_USER が空'
   } elseif (-not $ST_GUI_PASS -or $ST_GUI_PASS.Length -eq 0) {
     Write-Error '手順 5 のパスワードが空'
   } else {
     $p = ([Net.NetworkCredential]::new('', $ST_GUI_PASS)).Password
     if ($p -cnotmatch '^[\x20-\x7e]+$') {
       Write-Error 'パスワードに ASCII でない文字がある（手順 5 からやり直す）'
     } else {
       $p | & $exe generate "--gui-user=$ST_GUI_USER" --gui-password=-
       if ($LASTEXITCODE -eq 0) { & $exe device-id }
     }
     Remove-Variable p
   }
   Remove-Variable ST_GUI_PASS -ErrorAction SilentlyContinue
   ```

   - `Calculated device ID`・`Updated GUI authentication user`・`Updated GUI authentication password` の行と、最後に 7 文字 x 8 の文字列が出ればよい
   - 最後の文字列が、**この PC のデバイス ID**。相手のデバイスに教える値で、秘密ではない
   - 前の鍵が残っている PC では、先頭が `Key exists; will not overwrite` になり、デバイス ID は前と同じ
   - エラーで止まったら、手順 5 からやり直す（パスワードの変数はこの手順で消える）

   <details>
   <summary>補足: パスワードの渡し方と、作られるもの</summary>

   **パスワードは標準入力で渡す**（`--gui-password=-`）。

   - コマンドラインに書くと、その間だけとはいえ、ほかのプロセスからコマンドラインが見える。[syncthing.md](syncthing.md) の手順 4 と同じ渡し方
   - Windows PowerShell 5.1 は、文字列をパイプで渡すときに、末尾に改行（CR LF）を足し、ASCII の文字コードで送る（`$OutputEncoding` の既定）。Syncthing は 1 行目だけを読み、末尾の CR LF を捨てる（ソースは `bufio.Reader.ReadLine`。Linux の同じ版で、CR LF 付きで渡したパスワードでログインできた。[付録](#付録-linux-での-cli-と-powershell-のブロックの確認2026-10-03)）
   - ASCII でない文字は `?` に置き換わって送られるはずなので、先に弾いている（`-cmatch` は大文字と小文字を区別する比較。区別しない `-match` だと、ケルビン記号などが通る）
   - `config.xml` に入るのは bcrypt のハッシュで、平文は残らない

   **作られるもの**（`%LOCALAPPDATA%\Syncthing`）

   - `cert.pem` / `key.pem`（デバイス ID のもとになる証明書と秘密鍵）と `config.xml`（設定。GUI のログイン名・パスワードのハッシュ・API キーを含む）
   - Linux の同じ版では、`.syncthing.tmp.<数字>` という空の一時ファイルも残った（消してよい）
   - GUI の待ち受けはこの時点では `127.0.0.1:8384`（この PC からだけ）

   </details>

1. LAN の接続をプライベートにし、Syncthing の受信の規則を作る。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $g = 'Syncthing (setup-notes)'
   if (-not $LAN_IF) {
     Write-Error '手順 2 の $LAN_IF が空'
   } else {
     Set-NetConnectionProfile -InterfaceAlias $LAN_IF -NetworkCategory Private
     Remove-NetFirewallRule -Group $g -ErrorAction SilentlyContinue
     New-NetFirewallRule -Name 'Syncthing-In-TCP' -DisplayName 'Syncthing (TCP 22000)' -Group $g -Direction Inbound -Action Allow -Profile Private -Program $exe -Protocol TCP -LocalPort 22000 | Out-Null
     New-NetFirewallRule -Name 'Syncthing-In-UDP' -DisplayName 'Syncthing (UDP 22000, 21027)' -Group $g -Direction Inbound -Action Allow -Profile Private -Program $exe -Protocol UDP -LocalPort 22000, 21027 | Out-Null
     New-NetFirewallRule -Name 'Syncthing-GUI-In-TCP' -DisplayName 'Syncthing GUI (TCP 8384)' -Group $g -Direction Inbound -Action Allow -Profile Private -Program $exe -Protocol TCP -LocalPort 8384 | Out-Null
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
     Get-NetFirewallRule -Group $g | Format-Table Name, Enabled, Profile, Direction, Action
   }
   ```

   - `<LAN_IF>  Private` と、3 つの規則が `True  Private  Inbound  Allow` で出ればよい
   - 既にプライベートなら、ネットワークは何も変わらない
   - 何度貼ってもよい（規則は消してから作り直す）
   - **注意**: プライベート向けのほかの許可の規則（ネットワーク探索など）も、この LAN で効くようになる（[Windows の OpenSSH サーバー](windows-openssh-server.md)の手順 5 の補足）

   <details>
   <summary>補足: 規則の中身と、最初の起動より前に作る理由</summary>

   - 3 つの規則は、[syncthing.md](syncthing.md) の手順 7 の firewalld の `syncthing`（22000/tcp・22000/udp・21027/udp）と `syncthing-gui`（8384/tcp）に当たる。22000/tcp は同期、22000/udp は QUIC、21027/udp は同じ LAN の相手を見つけるため、8384/tcp は Web GUI
   - どれも `syncthing.exe`（展開したフルパス）に限り、プライベートのネットワークだけで有効にする。持ち出した先のパブリックの Wi-Fi では開かない
   - Windows のファイアウォールは、規則の無いプログラムが待ち受けると「Windows セキュリティの重要な警告」の窓を出す。そこで「キャンセル」を押すと、そのプログラムの**拒否**の規則ができ、拒否は許可より優先され、窓は二度と出ない。先に許可の規則を作っておけば、少なくともこの LAN では窓は出ないはず（確かめていない）
   - Syncthing の公式の自動起動の説明は、「一度対話で起動して、ファイアウォールの窓で許可する」としている。本書はその代わりに、規則を先に作る
   - Syncthing の FAQ も、パブリックのままでは直接つながらずリレー経由になりやすいので、プライベートにするよう書いている
   - グループの名前（`Syncthing (setup-notes)`）は、ほかの導入の方法が作る規則と分けるためのもの

   </details>

1. サインインしたときに Syncthing を起動するタスクを登録する。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
   $action = New-ScheduledTaskAction -Execute $exe -Argument '--no-console --no-browser' -WorkingDirectory (Split-Path $exe)
   $trigger = New-ScheduledTaskTrigger -AtLogOn -User $me
   $principal = New-ScheduledTaskPrincipal -UserId $me -LogonType Interactive
   $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
   Register-ScheduledTask -TaskName 'Syncthing' -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Format-List TaskName, State
   ```

   - `TaskName : Syncthing` と `State : Ready` が出ればよい
   - 同じ名前のタスクがあれば、上書きする（`-Force`）

   <details>
   <summary>補足: タスクの設定のねらい</summary>

   - **トリガー**: 自分のユーザーがサインインしたとき（`-AtLogOn -User`）。`-User` を外すと、どのユーザーのサインインでも動く
   - **`-LogonType Interactive`**: サインインしている間のデスクトップのセッションで動く。パスワードをタスクに保存しない。サインアウトすると止まる
     - Syncthing の公式の説明は「ユーザーがログオンしているかどうかにかかわらず実行する」（パスワードを保存する）だが、本書はサインインしている間だけ動かす（[選択した方針](#選択した方針)）
   - **実行レベル**: 既定の `Limited`（「最上位の特権で実行する」を付けない）。管理者の PowerShell から登録しても、Syncthing は管理者ではない自分のユーザーとして動く。管理者で動かすと、同期で作るファイルの所有者が `Administrators` になる
   - **引数**: 公式の説明と同じ `--no-console --no-browser`
     - `--no-console` はコンソールの窓を隠す。Windows 11 24H2 以降は、`syncthing.exe` に入っている設定（`consoleAllocationPolicy` が `detached`）で、もともと窓を作らない
     - `--no-browser` は、起動のたびにブラウザで GUI を開かない
     - `--no-restart` は付けない。Syncthing は親（モニター）と子の 2 つのプロセスで動き、子が終わったとき（設定の変更・自動の更新）に親が起動し直す
   - **`-ExecutionTimeLimit (New-TimeSpan)`**: 0（無制限）。既定の 3 日で止めないため（公式の説明の「長時間実行されている場合は停止」を外す）
   - **`-AllowStartIfOnBatteries -DontStopIfGoingOnBatteries`**: ノート PC で、電池のときも起動し、電池になっても止めない（公式の説明の任意の設定）
   - **`-MultipleInstances IgnoreNew`**: 既に動いていれば、二重に起動しない
   - **`[System.Security.Principal.WindowsIdentity]::GetCurrent().Name`**: `<HOSTNAME>\<WIN_USER>`。SSH のセッションでも空にならない（[Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)の手順 5 の補足）

   </details>

1. タスクを開始し、Syncthing が起動したことを確かめる。

   ```powershell
   if (Get-Process -Name syncthing -ErrorAction SilentlyContinue) {
     Write-Error 'Syncthing はもう動いている'
   } else {
     Start-ScheduledTask -TaskName 'Syncthing'
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     (Get-ScheduledTask -TaskName 'Syncthing').State
     Get-CimInstance Win32_Process -Filter "Name='syncthing.exe'" | Format-Table ProcessId, ParentProcessId -AutoSize
     Get-NetTCPConnection -State Listen -LocalPort 8384, 22000 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   }
   ```

   - `Running` と、`syncthing.exe` が 2 つ（片方の `ParentProcessId` がもう片方の `ProcessId`）出ればよい
   - 8384 は `127.0.0.1` で待ち受けている（手順 10 で広げる）。22000 の行も出る
   - 最初の起動は DB と HTTPS の証明書を作るので、数秒かかる（ブロックは 30 秒まで待つ）
   - **注意**: 「Windows セキュリティの重要な警告」の窓が出たら、**キャンセルを押さない**（拒否の規則ができる）。「プライベート ネットワーク」だけにチェックして「アクセスを許可する」を押す

   <details>
   <summary>補足: 2 つのプロセス</summary>

   - タスクが起動するのは親（モニター）で、親が子（本体）を起動する。親は子が終わったときに起動し直すためのもの
   - 子が 60 秒の間に 4 回起動すると、親はあきらめて終わる（ソースの `cmd/syncthing/monitor.go`）。止めて始め直す操作を短い間に繰り返さない
   - 窓は出ない（タスクから起動したとき）。動いているかは、この手順のようにプロセスと待ち受けで見る

   </details>

1. GUI の待ち受けを LAN に広げて HTTPS にする。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   & $exe cli config gui raw-address set 0.0.0.0:8384
   & $exe cli config gui raw-use-tls set true
   & $exe cli config gui raw-address get
   & $exe cli config gui raw-use-tls get
   for ($i = 0; $i -lt 30 -and (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue).LocalAddress -contains '127.0.0.1'; $i++) { Start-Sleep -Seconds 1 }
   Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   ```

   - `0.0.0.0:8384` と `true` が出て、8384 の `LocalAddress` が `127.0.0.1` でなくなればよい（`::` か `0.0.0.0`）
   - 手順 6 で認証を入れてあるので、ここで待ち受けを広げる
   - `127.0.0.1` のままなら、[止める・もう一度始める](#止めるもう一度始める)の手順 1・2 で起動し直す

   <details>
   <summary>補足: <code>syncthing cli</code> と、起動し直さなくてよい理由</summary>

   - `syncthing cli` は、動いている Syncthing に REST API で話しかける。API キーは `config.xml` から自分で読むので、渡さなくてよい（[syncthing.md](syncthing.md) の手順 6 の補足と同じ）
   - Linux の同じ版（2.1.5）では、この 2 つを入れた直後から、起動し直さずに `0.0.0.0:8384` で HTTPS の待ち受けに変わった（平文の `http://` は 307 で `https://` へ飛ばされた。[付録](#付録-linux-での-cli-と-powershell-のブロックの確認2026-10-03)）
   - 証明書は Syncthing が作る自己署名のもの（`%LOCALAPPDATA%\Syncthing\https-cert.pem`）。ブラウザは警告を出す
   - Go は `0.0.0.0` の待ち受けを IPv4 と IPv6 の両方で開くので、`Get-NetTCPConnection` では `::` と出るはず（確かめていない）

   </details>

1. 待ち受け・規則・デバイス ID を確かめ、GUI の URL を出す。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $proc = @{ Label = 'Process'; Expression = { (Get-Process -Id $_.OwningProcess).ProcessName } }
   if (-not $LAN_IF) {
     Write-Error '手順 2 の $LAN_IF が空'
   } else {
     Get-NetTCPConnection -State Listen -LocalPort 8384, 22000 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, $proc
     Get-NetUDPEndpoint -LocalPort 22000, 21027 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, $proc
     Get-NetFirewallApplicationFilter | Where-Object Program -like '*\Programs\Syncthing\syncthing.exe' | Get-NetFirewallRule | Format-Table DisplayName, Enabled, Profile, Action
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
     & $exe device-id
     Get-Content -LiteralPath "$env:LOCALAPPDATA\Syncthing\syncthing.log" -Tail 5 -Encoding UTF8 -ErrorAction SilentlyContinue
     'GUI: https://{0}:8384/  （ログイン名 {1}）' -f (Get-NetIPAddress -InterfaceAlias $LAN_IF -AddressFamily IPv4).IPAddress, $ST_GUI_USER
   }
   ```

   - 8384/tcp・22000/tcp・22000/udp・21027/udp が、どれも `syncthing` で出ればよい
   - 規則は手順 7 の 3 つだけが `Allow` で出る（規則の一覧は数秒かかる）
   - **`Block` の行があれば**、警告の窓でキャンセルを押した跡。[ロールバック](#ロールバック)の手順 2 で規則をすべて消し、手順 7 を貼り直す
   - 最後の行の URL を、手順 12 で使う

   <details>
   <summary>補足: ログと、自分の PC から開いた GUI</summary>

   - Windows の Syncthing は、ログを `%LOCALAPPDATA%\Syncthing\syncthing.log` に書く（10 MiB ごとに切り替え、古いものを 3 つ残す。ソースの既定値）。文字コードは UTF-8 なので、`-Encoding UTF8` を付けて読む（付けないと、Windows PowerShell 5.1 は日本語の Windows の既定の文字コードで読む）
   - この PC のブラウザで `https://127.0.0.1:8384/` を開いても GUI は使えるが、ファイアウォールを通らないので、手順 7 の規則を確かめたことにはならない（[syncthing.md](syncthing.md) の手順 7 の補足と同じ）

   </details>

1. LAN の別の端末のブラウザで GUI に入り、デバイス ID を確かめる。

   - 手順 11 の URL を開き、自己署名の証明書の警告を受け入れ、手順 2 のログイン名と手順 5 のパスワードで入る
   - 最初に、利用状況の報告（Usage Reporting）を許可するかを聞かれる。どちらでもよい
   - Actions → Show ID のデバイス ID が、手順 11 の `device-id` と同じであることを確かめる
   - **この時点では同期するフォルダは 1 つも無い**（Syncthing 2.x は既定のフォルダを作らない）

1. この PC でサインアウトし、サインインし直す。

   - スタートメニューのユーザーのアイコン → 「サインアウト」
   - サインアウトすると、Syncthing も止まる
   - **次の手順は、サインインし直して管理者の Windows PowerShell を開いてから貼る**

1. サインインで Syncthing が起動したことを確かめる。

   ```powershell
   for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
   (Get-ScheduledTask -TaskName 'Syncthing').State
   Get-CimInstance Win32_Process -Filter "Name='syncthing.exe'" | Format-Table ProcessId, ParentProcessId -AutoSize
   Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   ```

   - `Running` と、`syncthing.exe` が 2 つ、8384 が `127.0.0.1` 以外で出ればよい
   - 手順 2 の変数は要らない

---

## 同期フォルダとデバイスを追加する（任意）

- **Syncthing 2.x は既定のフォルダ（`Sync`）を作らない**。入れただけでは何も同期しないので、GUI から足す
- 操作は [syncthing.md の同じ節](syncthing.md#同期フォルダとデバイスを追加する任意)と同じ。相手が AlmaLinux 10 でも Windows でもよい

> [!WARNING]
> **この節の手順 4 で、ユーザーのフォルダー（`C:\Users\<WIN_USER>`）を丸ごと同期しない。** `AppData\Local\Syncthing`（Syncthing 自身の設定と DB）や、ほかのアプリのデータまで同期してしまう。
>
> - 同期したいものを入れる専用のフォルダーを作る（例: `C:\Users\<WIN_USER>\Sync`）
> - OneDrive に移したデスクトップ・ドキュメントや、Dropbox のフォルダーも入れない（2 つの同期が同じファイルを書き合う）

1. 相手のデバイスにも Syncthing を入れ、そのデバイス ID を控える。

   - AlmaLinux 10 なら [syncthing.md](syncthing.md)、Windows 11 ならこの手順書

1. この PC の GUI の「リモートデバイスを追加」に、相手のデバイス ID を貼る。

   - 同じ LAN にいるなら、21027/udp のローカル探索で相手が自動で見つかる
   - VPN 越しなどで見つからなければ、デバイスのアドレスに `tcp://<相手の IP>:22000` と直接書く

1. 相手の GUI に出る通知で、このデバイスを承認する。

1. 「フォルダーを追加」でパス（例: `C:\Users\<WIN_USER>\Sync`）とフォルダー ID を決め、「共有」タブで相手のデバイスにチェックを入れる。

1. 相手に「このデバイスがフォルダーを共有しようとしています」と出るので、受け入れる。

---

## 止める・もう一度始める

- タスク スケジューラでタスクを終了しても（`Stop-ScheduledTask` も）、親のプロセス（モニター）しか止まらず、本体は動き続ける（公式の説明）。止めるのはこの節の手順 1
- 自動の更新の後の Syncthing は、タスクの外で動く（[更新](#更新)）。動いているかは、タスクの状態ではなくプロセスで見る

1. Syncthing を止める。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   if (-not (Get-Process -Name syncthing -ErrorAction SilentlyContinue)) {
     'Syncthing は動いていない'
   } else {
     & $exe cli operations shutdown
     for ($i = 0; $i -lt 30 -and (Get-Process -Name syncthing -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     Get-Process -Name syncthing -ErrorAction SilentlyContinue | Format-Table Id
     (Get-ScheduledTask -TaskName 'Syncthing').State
   }
   ```

   - プロセスの一覧は何も出ず、タスクは `Ready` になればよい
   - 次のサインインで、また起動する

1. もう一度始めるときは、タスクを開始する。

   ```powershell
   if (Get-Process -Name syncthing -ErrorAction SilentlyContinue) {
     Write-Error 'Syncthing はもう動いている'
   } else {
     Start-ScheduledTask -TaskName 'Syncthing'
     for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     (Get-ScheduledTask -TaskName 'Syncthing').State
     Get-NetTCPConnection -State Listen -LocalPort 8384 -ErrorAction SilentlyContinue | Format-Table LocalAddress, LocalPort, OwningProcess
   }
   ```

   - `Running` と、8384 の待ち受けが出ればよい

---

## 更新

- Syncthing は 12 時間ごとに新しい版を確かめ、あれば自分で入れ替えて起動し直す（入れ替える前に、リリースの署名を確かめる）。新しい版が出てから 24 時間以内に上がる
- 入れ替えは同じ場所（`%LOCALAPPDATA%\Programs\Syncthing\syncthing.exe`）で行うので、タスクと受信の規則はそのまま使える。古い実行ファイルは、同じフォルダーに `syncthing.exe.old` として残る
- **自動で入れ替えた後の Syncthing は、タスクの外で動く**（タスクは `Ready` になる）。次のサインインからは、またタスクで起動する
- 待たずに上げるときは、この節の手順を貼る

1. 今の版と、新しい版があるかを確かめる。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   & $exe --version
   & $exe upgrade --check-only
   ```

   - 新しい版があれば、`Upgrade available` の行に今の版（`current`）と新しい版（`latest`）が出る
   - 新しい版が無ければ、`no upgrade available (current "v2.1.5" >= latest "v2.1.5")` のエラーが出る。そのときは、この節の手順 2 は飛ばす

1. 新しい版があるときだけ、今すぐ上げる。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   $before = & $exe --version
   & $exe cli operations upgrade
   for ($i = 0; $i -lt 60 -and (& $exe --version) -eq $before; $i++) { Start-Sleep -Seconds 1 }
   & $exe --version
   Start-Sleep -Seconds 5
   Get-CimInstance Win32_Process -Filter "Name='syncthing.exe'" | Format-Table ProcessId, ParentProcessId -AutoSize
   ```

   - `--version` が新しい版になり、`syncthing.exe` が 2 つ出ればよい

   <details>
   <summary>補足: 更新の動き</summary>

   - 自動の更新の間隔は、設定の `autoUpgradeIntervalH`（既定 12）。0 にすると自動では上げない（GUI の Actions → Settings → General の「自動アップグレード」でも変えられる）
   - 更新では、実行ファイルのフォルダーに一時ファイルを書き、前の `syncthing.exe.old` を消し、動いている `syncthing.exe` を `syncthing.exe.old` に名前を変え、新しいものを置く（ソースの `lib/upgrade/upgrade_supported.go`）。子は終了コード 4 で終わり、Windows では親（モニター）が新しい親を起動してから終わる（ソースの `restartMonitorWindows`）。そのため、タスクが起動した親はいなくなり、タスクは `Ready` になる
   - 更新したことはログに `Automatically upgraded` と出る
   - 本書では、新しい版が出ていないので、更新を試していない（[対象と検証環境](#対象と検証環境)）

   </details>

---

## ロールバック

- 上から順に、手順 2 で変数を設定した PowerShell に貼る（変数を使うのはこの節の手順 4 だけ）
- 同期していたファイル自体は、この節のどの手順でも消えない（同期したフォルダーの `.stfolder` も残る）

> [!CAUTION]
> **この節の手順 5 で、鍵・設定・DB（`%LOCALAPPDATA%\Syncthing`）を消すと、デバイス ID が失われる**。入れ直すと、相手からは別のデバイスとして見える。入れ直すかもしれないなら、手順 5 は行わない（手順 1〜4 だけなら、入れ直したときに同じデバイス ID に戻る）。

1. Syncthing を止め、タスクを消す。

   ```powershell
   $exe = "$env:LOCALAPPDATA\Programs\Syncthing\syncthing.exe"
   if (Get-Process -Name syncthing -ErrorAction SilentlyContinue) {
     & $exe cli operations shutdown
     for ($i = 0; $i -lt 30 -and (Get-Process -Name syncthing -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
   }
   Unregister-ScheduledTask -TaskName 'Syncthing' -Confirm:$false -ErrorAction SilentlyContinue
   Get-Process -Name syncthing -ErrorAction SilentlyContinue | Format-Table Id
   Get-ScheduledTask -TaskName 'Syncthing' -ErrorAction SilentlyContinue
   ```

   - 最後の 2 つが何も出さなければよい

1. 受信の規則を消す（警告の窓が作った規則も）。

   ```powershell
   Remove-NetFirewallRule -Group 'Syncthing (setup-notes)' -ErrorAction SilentlyContinue
   Get-NetFirewallApplicationFilter | Where-Object Program -like '*\Programs\Syncthing\syncthing.exe' | Get-NetFirewallRule | Remove-NetFirewallRule
   Get-NetFirewallApplicationFilter | Where-Object Program -like '*\Programs\Syncthing\syncthing.exe'
   ```

   - 最後のコマンドが何も出さなければよい（数秒かかる）

1. 実行ファイルを消す。

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\Programs\Syncthing" -Recurse -Force
   Test-Path "$env:LOCALAPPDATA\Programs\Syncthing"
   ```

   - `False` が出ればよい（`syncthing.exe.old` も消える）

1. LAN の接続をパブリックに戻すときだけ、パブリックにする。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '手順 2 の $LAN_IF が空'
   } else {
     Set-NetConnectionProfile -InterfaceAlias $LAN_IF -NetworkCategory Public
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
   }
   ```

   - `<LAN_IF>  Public` が出ればよい
   - 手順 7 の前からプライベートだったなら、この手順は飛ばす
   - [Windows の OpenSSH サーバー](windows-openssh-server.md)をこの LAN で使っているなら、この手順は飛ばす（パブリックにすると SSH も届かなくなる）

1. 完全に消すときだけ、鍵・設定・DB・ログを消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\Syncthing" -Recurse -Force
   Test-Path "$env:LOCALAPPDATA\Syncthing"
   ```

   - `False` が出ればよい

---

## 補足

### 対象と検証環境

- **目的**: Windows 11 の PC で [Syncthing](https://syncthing.net/) の最新版を動かし、AlmaLinux 10（[syncthing.md](syncthing.md)）やほかの端末とフォルダを同期する。Web GUI は LAN からも開けるようにする
- **進め方**: 公式の zip の `syncthing.exe` を `%LOCALAPPDATA%\Programs\Syncthing` に置き、タスク スケジューラのタスクで、サインインしている間だけ動かす
  - **GUI の認証を入れてから**起動し、待ち受けを LAN に広げる。受信の規則は、最初の起動より前に作る
  - 更新は、Syncthing 自身の自動の更新に任せる
  - すべて管理者の Windows PowerShell 5.1 に貼る。読者が書き換える値は無い（既定のままで通る）
- **状態**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](#付録-配布物と資料の調査2026-10-03)）:
    - 配布物: 2.1.5 の Windows の zip の中身、`sha256sum.txt.asc` の行との一致（その GPG の署名も）、`syncthing.exe` の Authenticode の署名者・証明書の連なり・タイムスタンプ・埋め込みの設定（`consoleAllocationPolicy`）。Linux で PE を読んだだけで、Windows の `Get-AuthenticodeSignature` は通していない
    - Syncthing 2.1.5 のソース: 設定とログの場所、`--no-console`、`generate` のパスワードの読み方、モニターの起動し直しと自動の更新の動き
    - Linux の公式の tarball の同じ版（2.1.5）での CLI（[付録](#付録-linux-での-cli-と-powershell-のブロックの確認2026-10-03)）: CR LF 付きのパスワードの `generate`、手順 10 の 4 つのコマンドと起動し直さずに変わること、`cli operations restart` / `shutdown` / `upgrade`（新しい版が無いとき）、`upgrade --check-only`
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査（構文とコマンドの引数だけ）。手順 4・6 のブロックは、Linux の pwsh で偽物の署名と Linux の `syncthing` を使って流した（同じ付録）
  - **確かめていないこと**: Windows で貼ること（すべての手順）、タスクの登録と起動・サインインでの起動・サインアウトで止まること、受信の規則と警告の窓、LAN の別の端末からの GUI と同期、自動の更新とその後のタスクの状態、arm64 の Windows、24H2 より前の Windows
- 下表は、本書が前提にしている環境（ほかの Windows の手順書の実機の記録と同じ PC を想定）

| 項目 | 値 |
|---|---|
| OS | Windows 11（24H2 以降。[Windows の OpenSSH サーバー](windows-openssh-server.md)の PC は 25H2・26H2） |
| PowerShell | Windows PowerShell 5.1（管理者として実行） |
| ユーザー | Administrators の一員（Microsoft アカウントでもローカル アカウントでもよい） |
| Syncthing | 2.1.5（2026-09-08。`syncthing-windows-amd64-v2.1.5.zip`） |
| ネットワーク | LAN の接続（手順 7 でプライベートにする） |

> [!NOTE]
> 環境固有の値は**変数**で書いてある。手順 2 の PowerShell の変数に 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 設定する場所 | 意味 | 例 |
> |---|---|---|---|
> | `$ST_GUI_USER` | 手順 2 | Web GUI のログイン名。Windows のアカウントとは別物（自動で同じ名前が入る） | `<WIN_USER>` |
> | `$LAN_IF` | 手順 2 | 相手とつながる LAN の接続の名前（自動で入る） | `イーサネット` |
> | `$ST_GUI_PASS` | 手順 5 | GUI のパスワード（手順 6 で消す） | — |
>
> 出力例・表の中の値は `<WIN_USER>` / `<HOSTNAME>`（Windows のコンピューター名）/ `<LAN_IF>` / `<IP>` / `<DEVICE_ID>` / `<APIKEY>` のプレースホルダで書いてある。
>
> **GUI のパスワードと API キーはこの文書に載せない。**

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 選択した方針

Windows で Syncthing を入れる経路を比べた（2026-10-03 時点。中身はどれも公式の `syncthing.exe`）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **公式の zip を固定の場所に置く** | GitHub のリリースの `syncthing-windows-amd64-v2.1.5.zip`（Authenticode の署名付き）。更新は Syncthing 自身の自動の更新で、同じ場所の実行ファイルを入れ替える | **採用** |
| winget の `Syncthing.Syncthing` | 2.1.5（公式の zip をそのまま）。版ごとに展開するフォルダーが変わる（`…\WinGet\Packages\Syncthing.Syncthing_…\syncthing-windows-amd64-v2.1.5\`）。`Links` のシンボリック リンクは、昇格も開発者モードも無いと作られない。Syncthing 自身の自動の更新は切られない | 不採用（パスが変わり、タスクと規則が更新で壊れる） |
| scoop の `main/syncthing` | 2.1.5。shim が `--home …\current\config --no-upgrade` を付け、設定は `~\scoop\persist\syncthing\config`。実行ファイルは `current` のジャンクションの先 | 不採用（shim を通さずに起動すると別の設定になる。ジャンクションの先のプログラムに規則が効くか確かめられない） |
| Chocolatey の `syncthing` | 2.1.5（コミュニティの保守）。自動起動も規則も無い | 不採用 |
| Syncthing Windows Setup（`BillStewart.SyncthingWindowsSetup` 2.0.2） | 公式のダウンロードのページが、新しい利用者に勧めるコミュニティのインストーラー。導入のときに最新の Syncthing を取り、ログオンのタスク・規則・開始と停止のショートカットを作る。サイレントの個人用の導入では規則を作らない | 不採用（画面の操作が中心になる。中身は本書とほぼ同じ） |
| SyncTrayzor v2（`GermanCoding.SyncTrayzor` 2.2.0）・Syncthing Tray（2.1.7） | タスクバーのトレイのアプリ。Syncthing を中に持つ | 不採用（GUI のアプリを足すことになる） |

- **固定の場所に置き、Syncthing 自身に更新させた**
  - タスクの実行ファイルと、受信の規則のプログラムが、更新の後も同じパスを指す
  - 自動の更新は、入れ替える前にリリースの署名を確かめる。`winget upgrade` や `scoop update` を自分で走らせなくても、24 時間以内に上がる
  - 初回だけは本書が取ってくるので、sha256 と Authenticode の署名を確かめてから置く（手順 4）
- **サインインしている間だけ、タスク スケジューラで動かした**
  - Syncthing の公式の説明は、タスク スケジューラ（「ユーザーがログオンしているかどうかにかかわらず実行する」とパスワードの保存）か、スタートアップのフォルダーのショートカット。サービスにするのは、ほとんどの使い方では勧めていない
  - 本書は、利用者の使い方（サインインしている間だけ同期すればよい）に合わせて `-LogonType Interactive` にし、パスワードを保存しない
  - スタートアップのフォルダーより、タスクの方が、電池・実行時間・二重起動の設定と、`Start-ScheduledTask` での開始ができる
- **受信の規則は、プログラムとプライベートに絞り、最初の起動より前に作った**（手順 7 の補足）
  - 公式の説明の「一度対話で起動して、警告の窓で許可する」は、窓でキャンセルを押すと拒否の規則ができ、後から気付きにくい
- **GUI は LAN にも公開した**（[syncthing.md](syncthing.md) と同じく、認証 → 起動 → 待ち受けを広げる順）
  - この PC からだけ開くなら、手順 10 を貼らない（`127.0.0.1:8384` のまま）。そのときは手順 7 の `Syncthing-GUI-In-TCP` は要らない
- **ネットワークをプライベートにする手順は、[Windows の OpenSSH サーバー](windows-openssh-server.md)の手順 5 と同じ**
  - 既にプライベートなら何も変わらないので、本書の手順 7 にも入れた。共有の前提の手順書には分けていない
  - そのため、[ロールバック](#ロールバック)の手順 4 は、OpenSSH サーバーを使っているなら飛ばす

### 注意点

- **パブリックのネットワークでは、直接はつながりにくい**: 規則はプライベートだけで有効。持ち出した先の Wi-Fi や、パブリックになっている VPN（WireGuard のトンネルの接続など）では、相手とはリレー（Syncthing のリレーのサーバー）経由になることが多い。外向きの接続だけでも同期はできる
- **サインアウトとスリープの間は止まる**: タスクはサインインしている間だけ動く。スリープの間も同期しない。止まっている間の変更は、次に動いたときに同期される
- **GUI に入れる人は、このユーザーのファイルを読み書きできる**: Syncthing はこのユーザーとして動き、GUI からフォルダーを足せる。GUI のパスワードは、Windows のパスワードと同じ重みで扱う
- **API キーはパスワードと同じ重み**: `%LOCALAPPDATA%\Syncthing\config.xml` にあり、これ 1 つで GUI の全操作ができる。ログや issue に貼らない
- **短い間に何度も起動し直さない**: 子のプロセスが 60 秒の間に 4 回起動すると、親はあきらめて終わる（手順 9 の補足）
- **タスクの状態では、動いているかは分からない**: タスクを終了しても本体は止まらず、自動の更新の後はタスクの外で動く。止めるのは [止める・もう一度始める](#止めるもう一度始める)の手順 1、確かめるのはプロセス
- **Windows で使えない名前のファイル**: 相手（AlmaLinux 10 など）にある、`:` や `?` などを含む名前や、大文字と小文字だけが違う名前のファイルは、Windows では同期できない（Syncthing は、そのファイルを同期できなかったものとして GUI に出す。確かめていない）
- **24H2 より前の Windows**: `syncthing.exe` に入っている「コンソールの窓を作らない」設定が効かず、タスクから起動したときにコンソールの窓が一瞬出て、`--no-console` で隠れるはず（確かめていない）
- **設定とログの場所**: `%LOCALAPPDATA%\Syncthing`（設定・鍵・DB・`syncthing.log`）。戻すのに要るのは `cert.pem` / `key.pem`（失うとデバイス ID が変わる）と `config.xml`

### 参照

- [Starting Syncthing Automatically — Syncthing documentation](https://docs.syncthing.net/users/autostart.html) — Windows のタスク スケジューラ（`--no-console --no-browser`、ファイアウォールの窓、タスクを終了してもモニターしか止まらないこと）、スタートアップのフォルダー、サービス
- [Firewall Setup — Syncthing documentation](https://docs.syncthing.net/users/firewall.html) — 22000/tcp・22000/udp・21027/udp
- [Configuration — Syncthing documentation](https://docs.syncthing.net/users/config.html) — 設定の場所（`%LOCALAPPDATA%\Syncthing`）、`autoUpgradeIntervalH`
- [FAQ — Syncthing documentation](https://docs.syncthing.net/users/faq.html) — 自動の更新、Windows のネットワークをプライベートにする話（「Why do my Windows computers always connect through a relay?」）
- [Syncthing のダウンロード](https://syncthing.net/downloads/) — Windows の zip と、Syncthing Windows Setup・SyncTrayzor v2 の案内
- [Syncthing v2.1.5](https://github.com/syncthing/syncthing/releases/tag/v2.1.5) — リリースのファイルと `sha256sum.txt.asc`
- Syncthing 2.1.5 のソース — `cmd/syncthing/main.go`（`serve` の引数）、`cmd/syncthing/hideconsole_windows.go`（`--no-console`）、`cmd/syncthing/generate/generate.go`（`--gui-password=-`）、`cmd/syncthing/monitor.go`（モニターと `restartMonitorWindows`）、`lib/locations/locations.go`（設定とログの場所）
- [Console Allocation Policy — Microsoft Learn](https://learn.microsoft.com/en-us/windows/console/console-allocation-policy) — `consoleAllocationPolicy` の `detached`（Windows 11 24H2 以降）
- [about_Preference_Variables（`$OutputEncoding`）— Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-5.1) — Windows PowerShell 5.1 が native のコマンドへパイプで渡す文字コード
- [New-ScheduledTaskPrincipal](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtaskprincipal)・[New-ScheduledTaskSettingsSet](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtasksettingsset)・[New-NetFirewallRule](https://learn.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule)
- [syncthing.md](syncthing.md) — AlmaLinux 10 の Syncthing（相手の端末）
- [Windows の OpenSSH サーバー](windows-openssh-server.md) — 同じ PC で使うことの多い手順書（ネットワークをプライベートにする手順が同じ）

---

### 付録: 配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物とソースと資料を読んだ記録。

#### リリースのファイル

最新は v2.1.5（2026-09-08。次の候補は v2.1.6-rc.4）。`releases/latest/download/sha256sum.txt.asc` は v2.1.5 のファイルへ飛んだ:

```
$ curl -sS -o /dev/null -w '%{http_code} %{redirect_url}\n' https://github.com/syncthing/syncthing/releases/latest/download/sha256sum.txt.asc
302 https://github.com/syncthing/syncthing/releases/download/v2.1.5/sha256sum.txt.asc
```

`sha256sum.txt.asc` の Windows の行（改行は LF。手順 4 の正規表現で、amd64 と arm64 の行がそれぞれ 1 つだけ合った）:

```
39571e4d0900c2a2cab14c0b170f49751340a869e49734ccc8079d9b98a7974b  syncthing-windows-amd64-v2.1.5.zip
082de37dc99621064bde8378ea26b28378f312f0a4147f52844ce7425f1baab0  syncthing-windows-arm64-v2.1.5.zip
```

取ってきた amd64 の zip の sha256 は `39571e4d…7974b` で一致した。`.asc` の GPG の署名は、`https://syncthing.net/release-key.txt` の鍵で確かめられた（もう 1 つ、その鍵の一覧に無い古い鍵の署名も付いていた）:

```
gpg: Good signature from "Syncthing Release Management <release@syncthing.net>" [unknown]
Primary key fingerprint: FBA2 E162 F2F4 4657 B38F  0309 E566 5F9B D597 0C47
gpg:                using RSA key 37C84554E7E0A261E4F76E1ED26E6ED000654A3E
gpg: Can't check signature: No public key
```

zip の中（`syncthing-windows-amd64-v2.1.5/` の下）は `syncthing.exe`（27,448,104 バイト）・`README.txt`・`LICENSE.txt`・`AUTHORS.txt`・`metadata/release.sig`・`etc/`（`linux-systemd`・`macos-launchd` など。Windows 用は無い）。

#### `syncthing.exe` の署名と埋め込みの設定

PE の証明書テーブルを openssl で読んだ（Windows の `Get-AuthenticodeSignature` は通していない）:

```
subject=C = SE, ST = Sk\C3\A5ne, L = H\C3\B6llviken, O = Kastelo AB, CN = Kastelo AB
issuer=C = US, O = Microsoft Corporation, CN = Microsoft ID Verified CS AOC CA 04
subject=C = US, O = Microsoft Corporation, CN = Microsoft ID Verified CS AOC CA 04
issuer=C = US, O = Microsoft Corporation, CN = Microsoft ID Verified Code Signing PCA 2021
subject=C = US, O = Microsoft Corporation, CN = Microsoft ID Verified Code Signing PCA 2021
issuer=C = US, O = Microsoft Corporation, CN = Microsoft Identity Verification Root Certificate Authority 2020
```

- 署名者の証明書の有効期間は 2026-09-06〜2026-09-09（3 日）
- RFC 3161 のタイムスタンプ（OID `1.3.6.1.4.1.311.3.3.1`）が付いていて、時刻は 2026-09-08。期限の切れた後も、タイムスタンプで署名が有効とみなされる
- 埋め込みの manifest に `<consoleAllocationPolicy xmlns="http://schemas.microsoft.com/SMI/2024/WindowsSettings">detached</consoleAllocationPolicy>` がある（v2.1.2 から）

#### ソース（v2.1.5）

- `cmd/syncthing/generate/generate.go`: `--gui-password=-` は `bufio.NewReader(os.Stdin)` の `ReadLine()` で 1 行を読む（Go の説明: 返す行は `\r\n` も `\n` も含まない）
- `cmd/syncthing/hideconsole_windows.go`: `--no-console`（環境変数は `STHIDECONSOLE`）。説明は「Hide console window (Always enabled on Windows 11 24H2 and later)」
- `cmd/syncthing/monitor.go`: 子が 60 秒の間に 4 回起動すると `Too many restarts; not retrying further` で終わる。子が終了コード 4（更新）で終わると、Windows では `restartMonitorWindows` が新しい親を `exec.Command(...).Start()` で起動して、今の親は終わる（Linux などは `syscall.Exec` で同じプロセスのまま）
- `lib/locations/locations.go`: Windows の設定と DB は `%LOCALAPPDATA%\Syncthing`（無ければ `%APPDATA%\Syncthing`）。ログの既定は Windows だけ `syncthing.log`（ほかは標準出力）
- 自動の更新の既定は `autoUpgradeIntervalH` が 12

#### パッケージの定義（採らなかった経路）

- winget の `Syncthing.Syncthing` 2.1.5: `InstallerType: zip`、`NestedInstallerType: portable`、`RelativeFilePath: syncthing-windows-amd64-v2.1.5/syncthing.exe`、`InstallerUrl` は GitHub の公式の zip、`UpgradeBehavior: uninstallPrevious`
- scoop の `main/syncthing` 2.1.5: `"bin": [[ "syncthing.exe", "syncthing", "--home \"$dir\\config\" --no-upgrade" ]]`、`"persist": "config"`、`notes` は公式の自動起動の説明へのリンク
- `BillStewart.SyncthingWindowsSetup` 2.0.2（2026-03-19）: Inno Setup。README は、個人用の導入でログオンのタスクを作ること、対話の導入では規則を作るかを聞き、サイレントの個人用の導入では規則を作らないことを書いている。Syncthing の自動の更新は既定のまま（12 時間）
- Syncthing の公式のドキュメント（autostart）は「There is currently no official installer available for Windows.」と書いている

---

### 付録: Linux での CLI と PowerShell のブロックの確認（2026-10-03）

本書の手順 6・10 と後ろの節で使う `syncthing` のコマンドが 2.1.5 でそのとおり動くかを、Linux の公式の tarball（`syncthing-linux-amd64-v2.1.5.tar.gz`、`syncthing v2.1.5 "Hafnium Hornet" (go1.27.1 linux-amd64) builder@github.syncthing.net 2026-09-08 06:57:55 UTC`）で確かめた。一時的な `HOME` で、親（モニター）付き（`--no-restart` 無し）で動かした。Windows だけのもの（`--no-console`・タスク・ファイアウォール・ログのファイル）は確かめられない。最後に、本書の PowerShell のブロックを Linux の PowerShell 7 で確かめた記録を置く。

**`generate` に CR LF 付きでパスワードを渡す**（手順 6 の Windows PowerShell 5.1 のパイプに当たる）:

```
$ printf 'pw-Test_1\r\n' | syncthing generate --gui-user=winuser --gui-password=-
INF Generating key and certificate (cn=syncthing log.pkg=syncthing)
INF Calculated device ID (device=<DEVICE_ID> log.pkg=github)
INF Updated GUI authentication user (name=winuser log.pkg=github)
INF Updated GUI authentication password (log.pkg=github)
$ printf '' | syncthing generate --gui-user=x --gui-password=-; echo $?
syncthing: error: failed reading GUI password: EOF
1
```

起動した後に、GUI のログインの API に送った:

```
POST /rest/noauth/auth/password  {"username":"winuser","password":"pw-Test_1"}    → 204
POST /rest/noauth/auth/password  {"username":"winuser","password":"pw-Test_1\r"}  → 403
```

CR を落としたパスワードでだけログインできた。`generate` の直後の設定は `<gui enabled="true" tls="false" …>` と `<address>127.0.0.1:8384</address>` で、空の `.syncthing.tmp.<数字>` が残った。

**手順 10 のコマンド**: 4 つとも終了コード 0 で、`0.0.0.0:8384` と `true` を読み戻した。起動し直す前から、待ち受けは `0.0.0.0:8384` に変わり、HTTPS になっていた:

```
https://127.0.0.1:8384/                  → 200
http://127.0.0.1:8384/                   → 307
https://127.0.0.1:8384/rest/system/status → 403（認証無し）
```

**`cli operations restart`**: 終了コード 0。子のプロセスだけが入れ替わり（PID が変わった）、親は同じだった。3 秒で HTTPS の待ち受けに戻った。

**`cli operations shutdown`**: 終了コード 0。親と子の 2 つのプロセスが終わった（ログの最後は `Exiting`）。止まった後にもう 1 度送ると、`dial tcp 0.0.0.0:8384: connect: connection refused` で終了コード 1（`0.0.0.0` の待ち受けへの接続は、ループバックに向く）。

**更新の確認**（新しい版が無いとき）:

```
$ syncthing upgrade --check-only; echo $?
ERR Failed to check for upgrade (error="no upgrade available (current \"v2.1.5\" >= latest \"v2.1.5\")." log.pkg=main)
2
$ syncthing cli operations upgrade; echo $?
0
```

`config.xml` の `autoUpgradeIntervalH` は 12、`urAccepted` は 0（利用状況の報告をまだ聞いていない）だった。

**PowerShell のブロック**:

- 本書の `powershell` のブロック 20 個を、Linux の PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer 1.25.0 の `PSUseCompatibleSyntax`（Windows PowerShell 5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0（ほかの規則の指摘は、手順 5 の `$ST_GUI_PASS` を手順 6 で使うことへの 1 つだけ）。わざと PowerShell 7 だけの書き方（`??`、`Get-Content -AsByteStream`、`ForEach-Object -Parallel`）を入れたファイルでは、それぞれ指摘が出た
- 手順 4 のブロックを、Linux の pwsh で、パスの `\` を `/` に替え、`Get-AuthenticodeSignature` と `icacls.exe` を偽物にして流した。最新の版の行を `sha256sum.txt.asc` から取り、zip を取って sha256 が一致し、展開した `syncthing.exe` を `%LOCALAPPDATA%` に当たる場所へ置いて、一時フォルダーを消した。偽物の署名の `Status` を `Valid` 以外にすると、`中断: syncthing.exe の署名を確かめられない（HashMismatch）` で止まり、何も置かなかった
- 手順 6 のブロックを、Linux の pwsh で、`$exe` を Linux の `syncthing` にして流した。`ConvertTo-SecureString` で作ったパスワードで `generate` が通り、起動した後にそのパスワードでログインできた（204）。`パス1` は `パスワードに ASCII でない文字がある` で止まった。どちらも最後に `$ST_GUI_PASS` が消えていた。PowerShell 7 はパイプの文字コードが UTF-8 で、改行は LF なので、Windows PowerShell 5.1 と同じではない

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. `Get-AuthenticodeSignature` が `Valid` を返し、署名者が `CN=Kastelo AB, …` で始まること
1. タスクで起動したときに窓が出ないこと、サインインでの起動、サインアウトで止まること
1. 受信の規則を先に作れば、警告の窓が出ないこと
1. LAN の別の端末からの GUI と、相手との同期
1. 自動の更新と、その後のタスクの状態（`Ready`）、`syncthing.exe.old`
1. arm64 の Windows、24H2 より前の Windows
