# Windows 11 で Claude Code の Remote Control を SSH の切断後も動かす手順（タスク スケジューラ + WezTerm）の参考資料

[手順書](../windows-claude-remote-control.md)・[ロールバックと注意点](../extra/windows-claude-remote-control.md)

## 補足

### 実施手順 / 手順 2: 補足: 変数

- ホームそのもの（`C:\Users\<WIN_USER>`）を `PROJECT_DIR` に使えないのは、Claude Code がホームの信頼を保存しないため
- 変数はその PowerShell の中だけで有効

### 実施手順 / 手順 3: 補足: quser の行と --help

- `quser` の `console` の行が `Active` なのは、デスクトップにログインしていること
- `claude remote-control --help` は、help を出した後に終わらない（[注意点](../extra/windows-claude-remote-control.md#注意点)）

### 実施手順 / 手順 4: 補足: 対話で起動する理由

- この起動は信頼と確認を一度受けるためのもの。タスクが同じことを無人で起動する

### 実施手順 / 手順 5: 補足: タスクの設定のねらい

- `-LogonType Interactive`: ログオン中のデスクトップのセッションでタスクを動かす。WezTerm の窓がそこに開く。`S4U` はデスクトップが無いので WezTerm が開けない
- `-UserId` は `[System.Security.Principal.WindowsIdentity]::GetCurrent().Name`（`<HOSTNAME>\<WIN_USER>`）。SSH のセッションでは `$env:USERDOMAIN` が空で、`$env:USERDOMAIN\$env:USERNAME` は登録に失敗する
- `-ExecutionTimeLimit (New-TimeSpan)` は 0（`PT0S`、無制限）。既定の 3 日で止めないため
- `-MultipleInstances IgnoreNew`: すでに動いていれば二重に起動しない
- `--cwd` と `--name` の値は空白を含みうるので二重引用符で囲む
- 登録には管理者の権限が要る（SSH のセッションは昇格している）。昇格していないシェルでは `アクセスが拒否されました` になる
- トリガーは付けない（手で `Start-ScheduledTask` したときだけ動く。起動時の自動起動は本書では扱わない）

### 実施手順 / 手順 6: 補足: プロセスの見分け方

- デスクトップで別の `claude remote-control` も動かしていると、`claude.exe` が複数出る。タスクのものは親が手順 6 で開いた WezTerm（`wezterm-gui.exe`）
- つないだ端末が無い間は、`claude --print` の子プロセスは出ないことがある（接続すると出る）

### 参照

- [Continue local sessions from any device with Remote Control](https://code.claude.com/docs/en/remote-control)（`claude remote-control`、`--spawn`、Requirements、Resume sessions after stopping the server、Limitations の tmux / screen と 10 分の終了、Connection and security、Trusted Devices）
- [Advanced setup](https://code.claude.com/docs/en/setup)（Windows の native installer）
- [New-ScheduledTaskPrincipal](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtaskprincipal)（`-LogonType` の `Interactive` と `S4U`）
- [New-ScheduledTaskSettingsSet](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtasksettingsset)（`-ExecutionTimeLimit`、`-MultipleInstances`）
- [Avoid killing child processes by sshd after session ended · PowerShell/Win32-OpenSSH #1642](https://github.com/PowerShell/Win32-OpenSSH/issues/1642)（SSH の切断でセッションのプロセスが止まること）
- [Windows implementation issues · zellij-org/zellij #4745](https://github.com/zellij-org/zellij/issues/4745)（zellij の Windows 版の既知の問題）
- [Windows 11 の初期設定の「OpenSSH サーバー」](../windows-setup.md#openssh-サーバー)（前提。SSH のセッションの権限。`DefaultShell` は同書の任意節）
- [RDP をロックせずに切断（Windows）](../windows-rdp-disconnect.md)（RDP で使った後、デスクトップのセッションを `console` に戻して切る）

---
