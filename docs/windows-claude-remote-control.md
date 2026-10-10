# Windows 11 で Claude Code の Remote Control を SSH の切断後も動かす手順（タスク スケジューラ + WezTerm）

## 実施手順

- [検証記録](verification/windows-claude-remote-control.md)・[参考資料](reference/windows-claude-remote-control.md)・[ロールバックと注意点](extra/windows-claude-remote-control.md)

> [!IMPORTANT]
> - **すべて、SSH でログインした Windows の PC で行う**。手順 1 で Windows PowerShell（5.1）を起動し、手順 2〜7・9 と、[止める・もう一度始める](#止めるもう一度始める)・[ロールバック](extra/windows-claude-remote-control.md#ロールバック)をそこに貼る。デスクトップで開いた PowerShell には貼らない
> - ログインするユーザーは **Administrators の一員**（手順 5 のタスク登録に管理者の権限が要る。Administrators の一員の SSH のセッションは、UAC の確認無しで管理者の権限を持つ。[Windows の OpenSSH サーバー](extra/windows-openssh-server.md#注意点)）
> - 前提: [Windows の OpenSSH サーバー](windows-openssh-server.md)で SSH でログインできること。Claude Code を公式の native installer で入れ（[Claude Code の Windows 11 で使う](claude-code.md#windows-11-で使う)。この手順書の検証の PC は、PowerShell で `irm https://claude.ai/install.ps1 | iex` で入れた）、`claude` の `/login` で claude.ai のアカウント（Pro / Max / Team / Enterprise）にログインしてあること。API キーでは Remote Control を使えない。WezTerm が `C:\Program Files\WezTerm` に入っていること（[WezTerm の Windows 11 で使う](wezterm-nightly.md#windows-11-で使う)）
> - 前提: [Windows 11 の初期設定の「貼り付けの設定」の手順 1〜4](windows-setup.md#貼り付けの設定)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。このユーザーのプロファイルに書くので、SSH でログインした Windows PowerShell も読む
> - **この PC のデスクトップにログインしたままにしておくこと**。タスクはログオン中のデスクトップのセッションで WezTerm を開く。ログオフすると動かない（[注意点](extra/windows-claude-remote-control.md#注意点)）。再起動の後に自動でサインインさせるのは [Windows 11 の初期設定の「WSL の AlmaLinux 10 と自動サインイン」の手順 5](windows-setup.md#wsl-の-almalinux-10-と自動サインイン)
> - **手順 4 には対話入力がある**（ディレクトリの信頼のダイアログと、初回の Remote Control の確認。URL が出たら Ctrl+C）

- 上から順にコードブロックを貼る。手順 2 で変数を設定した PowerShell に貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 手順の後に、止めるとき・もう一度始めるときは[止める・もう一度始める](#止めるもう一度始める)、全部消すときは[ロールバック](extra/windows-claude-remote-control.md#ロールバック)

> [!WARNING]
> **Remote Control をつなぐと、この claude.ai のアカウントで入れる人が、スマートフォンやブラウザからこの PC の `<PROJECT_DIR>` で、このユーザーとして Claude Code を動かせる**（ファイルの読み書きとコマンドの実行。SSH のセッションから登録するので、タスクは管理者の権限を持ちうる）。会話の転写（メッセージ・応答・ツールの動き）は Anthropic のサーバーに保存される（[注意点](extra/windows-claude-remote-control.md#注意点)）。タスクが開く WezTerm の窓はデスクトップに見える。窓を閉じる・中で Ctrl+C すると Claude Code が止まる。

1. クライアントの PC から Windows に SSH でログインし、Windows PowerShell を起動する。

   - `ssh <WIN_USER>@<WIN_HOST>` でログインする（[Windows の OpenSSH サーバー](windows-openssh-server.md)の手順 9 と同じ。スマートフォンの SSH のアプリでもよい）
   - ログインした先のシェルが Git Bash でも cmd でも、`powershell` と打つ
   - プロンプトが `PS C:\Users\<WIN_USER>>` になる
   - **次の手順は、このプロンプトが出てから貼る**（続けて貼ると、ログインした先のシェルへの入力として食われる）

1. 変数を設定する（`PROJECT_DIR` は必ず値を入れる）。

   ```powershell
   $PROJECT_DIR = ''                     # ← Remote Control のセッションを動かすディレクトリ（プロジェクト）を書く。<PROJECT_DIR>
   ```

   ```powershell
   $RC_NAME = if ($PROJECT_DIR) { Split-Path $PROJECT_DIR -Leaf }   # claude.ai/code とアプリに出るセッション名（既定はディレクトリ名）。<RC_NAME>
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'PROJECT_DIR = {0}' -f $PROJECT_DIR
   'RC_NAME     = {0}' -f $RC_NAME
   ```

   - 最後に値を読み戻して確かめる
   - `PROJECT_DIR` は、`C:\Users\<WIN_USER>\src\myproject` のような、存在するプロジェクトのディレクトリの絶対パス。ホームそのもの（`C:\Users\<WIN_USER>`）は使えない
   - **新しい PowerShell を開いたら**、手順 2 のブロックを貼り直してから先へ進む

1. Claude Code・WezTerm・ログインと、デスクトップのセッションを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   claude --version
   claude auth status --text
   & 'C:\Program Files\WezTerm\wezterm.exe' --version
   quser
   ```

   - `claude` の版と、ログイン済みを示す行、`wezterm 2026…` が出ればよい
   - `quser` に、自分のユーザーの `console` の行が `Active` で出ること。出なければ、この PC にログインしてから続ける
   - RDP で使った後にふつうに切断していると、自分の行のセッション名が空で、状態が `Disc`（切断）になる。RDP でつなぎ直し、[RDP をロックせずに切断する手順](windows-rdp-disconnect.md)で切ると `console` に戻る
   - `claude remote-control --help` は貼らない

1. 初回だけ、対話で起動して信頼と Remote Control の確認に答え、URL が出たら止める。

   ```powershell
   if (-not $PROJECT_DIR) {
     Write-Error '手順 2 の $PROJECT_DIR が空'
   } elseif (-not (Test-Path -LiteralPath $PROJECT_DIR -PathType Container)) {
     Write-Error '中断: $PROJECT_DIR は存在するディレクトリではない'
   } else {
     Set-Location -LiteralPath $PROJECT_DIR -ErrorAction Stop
     claude remote-control --name $RC_NAME --spawn same-dir
   }
   ```

   - ディレクトリが無い、ファイルを指定した、または移動できない場合は起動しない。手順 2 の値とディレクトリへのアクセスを確かめてから貼り直す
   - 信頼のダイアログ（`Is this a project you created or one you trust?`）が出たら、**↓ で `Yes, I trust this folder` を選び Enter**（既定は `No, exit`）
   - 初めて Remote Control を使うときは `Enable Remote Control? (y/n)` が出る。`y`
   - `https://claude.ai/code/<SESSION_ID>` の URL と `space to show QR code` が出れば、起動できている
   - **Ctrl+C** で止める
   - **次の手順は、Ctrl+C で止めてプロンプトに戻ってから貼る**（続けて貼ると Claude Code への入力として食われる）

1. タスクを登録する（WezTerm で `claude remote-control` を起動するタスク）。

   ```powershell
   if (-not $PROJECT_DIR) {
     Write-Error '手順 2 の $PROJECT_DIR が空'
   } elseif (-not (Test-Path -LiteralPath $PROJECT_DIR -PathType Container)) {
     Write-Error '中断: $PROJECT_DIR は存在するディレクトリではない'
   } else {
     $me = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
     $wt = 'C:\Program Files\WezTerm\wezterm.exe'
     $arg = 'start --cwd "{0}" -- claude remote-control --name "{1}" --spawn same-dir' -f $PROJECT_DIR, $RC_NAME
     $action = New-ScheduledTaskAction -Execute $wt -Argument $arg
     $principal = New-ScheduledTaskPrincipal -UserId $me -LogonType Interactive
     $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Register-ScheduledTask -TaskName 'claude-remote-control' -Action $action -Principal $principal -Settings $settings -Force | Format-List TaskName, State
   }
   ```

   - `State : Ready` が出ればよい

1. タスクを開始し、動いていることを確かめる。

   ```powershell
   Start-ScheduledTask -TaskName 'claude-remote-control'
   Start-Sleep -Seconds 8
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-ScheduledTask -TaskName 'claude-remote-control').State
   Get-CimInstance Win32_Process -Filter "Name='claude.exe'" | Where-Object CommandLine -like '*--spawn same-dir*' | Select-Object ProcessId, ParentProcessId | Format-Table -AutoSize
   ```

   - `Running` と、`claude.exe` のプロセスが出ればよい（親は WezTerm）
   - デスクトップには WezTerm の窓が開き、中で Claude Code が動く
   - 数十秒で claude.ai/code の一覧に `<RC_NAME>` が出る（手順 8 で確かめる）

1. SSH の接続を切る。

   ```powershell
   exit
   ```

   - ログインした先のシェルに戻る（Git Bash なら `<WIN_USER>@<HOSTNAME> MINGW64 ~`、cmd なら `C:\Users\<WIN_USER>>`）
   - そこでもう 1 度 `exit` と打つと、SSH が切れてクライアントのプロンプトに戻る。SSH のアプリで接続を閉じてもよい
   - タスクで起動した WezTerm と Claude Code は、デスクトップのセッションに残る

1. 切断した後も、スマートフォンかブラウザからセッションが使えることを確かめる。

   - claude.ai/code か、Claude のアプリの **Code** の一覧に `<RC_NAME>` が、コンピューターのアイコンと緑の点付きで出る
   - 開いてメッセージを送ると、この PC の `<PROJECT_DIR>` で Claude Code が動いて返事が来る
   - 返事が来なければ、手順 9 でログインし直して確かめる

1. 必要なら SSH でログインし直し、タスクとプロセスが残っていることを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-ScheduledTask -TaskName 'claude-remote-control').State
   Get-CimInstance Win32_Process -Filter "Name='claude.exe'" | Where-Object CommandLine -like '*--spawn same-dir*' | Select-Object ProcessId | Format-Table -AutoSize
   ```

   - `Running` と、手順 6 と同じプロセスが残っている
   - 手順 2 の変数は要らない

---

## 止める・もう一度始める

- この節は、SSH でログインした PowerShell に貼る（変数は要らない）
- 止めるのはこの節の手順 1、もう一度始めるのは手順 2

1. セッションを止める。

   ```powershell
   Stop-ScheduledTask -TaskName 'claude-remote-control'
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-CimInstance Win32_Process -Filter "Name='claude.exe'" | Where-Object CommandLine -like '*--spawn same-dir*' | Select-Object ProcessId | Format-Table -AutoSize
   ```

   - `claude.exe` のプロセスが消える（デスクトップで別に動かしている分は残る）
   - WezTerm の窓も閉じる

1. もう一度始めるときは、タスクを開始する。

   ```powershell
   Start-ScheduledTask -TaskName 'claude-remote-control'
   ```

   - 止めてから約 4 時間以内なら、claude.ai/code の同じセッションが戻る（それを過ぎると新しいセッションになる。公式ドキュメント）
   - ネットワークが約 10 分切れると、Claude Code のサーバーは自分で終わり WezTerm の窓が閉じる（公式ドキュメント）。そのときもこの手順で始め直す
