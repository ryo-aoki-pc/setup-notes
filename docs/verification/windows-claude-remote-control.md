# Windows 11 で Claude Code の Remote Control を SSH の切断後も動かす手順（タスク スケジューラ + WezTerm）の検証記録

[手順書](../windows-claude-remote-control.md)・[ロールバックと注意点](../extra/windows-claude-remote-control.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順 / 手順 1: 補足: なぜタスク スケジューラと WezTerm を使うか

- Windows の sshd は、SSH のセッションが終わるとそのセッションで動かしたプロセスの木を止める（実測は[付録](#付録-実機での検証記録2026-10-01)）。SSH のシェルで `claude remote-control` を直接起動しても、切断で止まる
- タスク スケジューラのタスクで起動したプロセスは、Task Scheduler のサービスの子で SSH のセッションの木に入らないので、切断後も残る
- Claude Code は本物の端末を必要とする。タスクに WezTerm を起動させ、その中で `claude remote-control` を動かす。WezTerm はログオン中のデスクトップのセッションに窓を開く（公式ドキュメントが挙げる tmux / screen の Windows での代わり）
- 端末の多重化（zellij）で試した経緯と、動かなかった理由は[選択した方針](#選択した方針)にある

### 実施手順 / 手順 2: 補足: 変数について

- 変数を使うのは手順 4・5 だけ。手順 6 以降と後ろの節は、タスク名 `claude-remote-control`（固定）だけで動く
- `RC_NAME` は `claude remote-control --name` に渡す。付けないと `<hostname>-graceful-unicorn` のようなホスト名入りの自動の名前になる
- 別のプロジェクトでもう 1 つ動かすなら、別のタスク名で手順 4・5 をやり直す（本書では試していない）

### 実施手順 / 手順 4: 補足: この手順で受ける一度きりの確認

- 信頼はディレクトリごとに `~/.claude.json` に保存される。Remote Control の確認（`Enable Remote Control?`）はこの PC で一度きり
- `--spawn same-dir` を付けないと、この後に `Choose [1/2]`（`same-dir` か `worktree` か）の確認が出て、無人のタスクではそこで止まる（実測は[付録](#付録-実機での検証記録2026-10-01)）。本書は `same-dir`（1 つのディレクトリを共有）に固定する
- ここで作ったセッションは Ctrl+C で切れる。タスク（手順 6）は別のセッションを作る

### 対象と検証環境

- **目的**: Windows 11 の PC に SSH でログインしているときに Claude Code の Remote Control を始め、SSH を切った後もスマートフォンやブラウザから使い続けられるようにする
  - Claude Code の公式ドキュメントは、SSH を切った後も残すには tmux か screen の中で起動するよう書いている。Windows にはどちらも無いので、タスク スケジューラで WezTerm を起動し、その中で `claude remote-control` を動かす
- **進め方**: 値は手順 2 の変数に 1 度だけ書き、以降のコマンドをそのまま貼る
  - すべて、SSH でログインした Windows の PC の Windows PowerShell（5.1）に貼る
  - 読者が書き換えるのは `$PROJECT_DIR` だけ
- **状態**: **起動と SSH 切断後の継続動作は実機で本実行済み（2026-10-01、x86_64 のノート PC の Windows 11 Pro 26H2）**
  - 2026-10-05 に足した手順 4・5 のディレクトリの検査と、手順 4 の移動失敗時の停止は、Linux の PowerShell 7.6.6 で模擬確認しただけ。変更後のブロックを Windows では貼っていない（[付録](#付録-ディレクトリの検査と停止の模擬確認2026-10-05)）
  - 通したこと:
    - SSH（`ssh localhost`、使い捨ての鍵）でログインしたシェルから、手順 4（信頼と Remote Control の確認）・手順 5（タスク登録）・手順 6（開始）を通し、手順 7 で SSH を切った
    - 切断の後、タスクで起動した `claude remote-control` が動き続け、Anthropic へ接続していること（プロセスの存続・TLS の接続・claude.ai のセッションが `connected`）を確かめた
    - 別の Claude Code のセッションからそのセッションへメッセージを送り、1 ターン処理して返事を作ったこと（遠隔から操作できること）を確かめた
    - [止める・もう一度始める](../windows-claude-remote-control.md#止めるもう一度始める)・[ロールバック](../extra/windows-claude-remote-control.md#ロールバック)（タスクの削除まで）を通した
  - 確認したこと:
    - sshd が SSH のセッションの子プロセスを切断で止めること（対照の実測）
    - `--spawn same-dir` が無いと `claude remote-control` が `Choose [1/2]` の確認で止まること
  - **確認していないこと**:
    - 別の端末（スマートフォンの実機、LAN の別の PC）からの接続・操作（同じ PC から `ssh localhost` と別セッションのメッセージで検証した）
    - PC の再起動の後の自動起動（本書はトリガーを付けない）、デスクトップをロック／ログオフしたときの挙動（検証はログオン中・コンソールが `Active`）
    - 標準ユーザー、Microsoft アカウントのパスワードの端末からの利用
  - 実測の記録は[付録](#付録-実機での検証記録2026-10-01)

下表は実機で採取した値。

| 項目 | 値 |
|---|---|
| 実施日 | 2026-10-01 |
| PC | x86_64 のノート PC（AMD Ryzen AI MAX+ 395） |
| OS | Windows 11 Pro 26H2（ビルド 26300.9457、日本語） |
| PowerShell | Windows PowerShell 5.1.26100.9444 |
| OpenSSH | `OpenSSH_for_Windows_9.5p2`。`DefaultShell` は Git Bash（[Windows の OpenSSH サーバー](../windows-openssh-server.md)の任意節） |
| WezTerm | 20260905-153129-092dcf70（`C:\Program Files\WezTerm`） |
| Claude Code | 2.1.286（native installer、`C:\Users\<WIN_USER>\.local\bin\claude.exe`） |
| ユーザー | Microsoft アカウント。Administrators の一員。SSH のセッションは High Mandatory Level |
| Claude のプラン | Max |
| クライアント | 同じ PC から `ssh localhost`（使い捨ての鍵）。別の端末は未確認 |

> [!NOTE]
> 環境固有の値は**変数**で書いてある。手順 2 の PowerShell の変数に 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 設定する場所 | 意味 | 例 |
> |---|---|---|---|
> | `$PROJECT_DIR` | 手順 2 | Remote Control のセッションを動かすディレクトリ（ホームは不可） | `C:\Users\<WIN_USER>\src\myproject` |
> | `$RC_NAME` | 手順 2 | claude.ai/code とアプリに出るセッション名（既定はディレクトリ名） | `myproject` |
>
> 出力例・ログ・表の中の値は `<WIN_HOST>` / `<WIN_USER>` / `<HOSTNAME>`（Windows のコンピューター名）/ `<PROJECT_DIR>` / `<RC_NAME>` / `<SESSION_ID>` のプレースホルダで書いてある。
>
> Claude のアカウント（メールアドレス）、セッションの URL（`https://claude.ai/code/<SESSION_ID>`）と QR コード、`~/.claude/` の資格情報はこの文書に載せない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

実機で、2026-10-01 に手順 1 の前に確かめた状態:

| 項目 | 状態 |
|---|---|
| Claude Code | native installer の `C:\Users\<WIN_USER>\.local\bin\claude.exe`、claude.ai にログイン済み。Remote Control の確認は受け入れ済み（`~/.claude.json` の `remoteDialogSeen`） |
| WezTerm | `C:\Program Files\WezTerm` に導入済み。デスクトップで別の `claude remote-control` を動かしていた（本書の手順とは別） |
| sshd | Running / Automatic。`DefaultShell` は Git Bash。SSH のセッションは High Mandatory Level |
| タスク | `claude-remote-control` は無い |

### 選択した方針

- **タスク スケジューラで WezTerm を起動し、その中で `claude remote-control` を動かす**
  - SSH のシェルで直接起動したプロセスは、切断で sshd に止められる（付録の対照）。タスクのプロセスは Task Scheduler のサービスの子で、SSH の木に入らないので残る
  - `claude remote-control` は本物の端末を要する。WezTerm の中では何時間も動く（実機で常用しているものがある）。タスクに WezTerm を開かせて、その中で動かす
  - `-LogonType Interactive` で、ログオン中のデスクトップのセッションに WezTerm を開く。`S4U`（デスクトップにログオンしていなくても動く）はデスクトップが無く、WezTerm を開けない
- **`--spawn same-dir` を付ける**: 付けないと `claude remote-control` が `Choose [1/2]`（`same-dir` か `worktree` か）の確認で止まり、無人のタスクではセッションを作れない（付録の実測）
- **初回だけ対話で起動して信頼と Remote Control の確認を受ける**（手順 4）: 無人のタスクの中ではこれらのダイアログに答えられない。信頼はディレクトリごと、Remote Control の確認は PC ごとに一度きり
- **トリガーを付けない**: 手で `Start-ScheduledTask` したときだけ動く。起動時の自動起動は本書では扱わない
- **採らなかった案**
  - 端末の多重化（zellij）の中で動かす: zellij は 0.44 から Windows でネイティブに動き、サーバーは SSH の切断後も残るが、**ペインの中で Claude Code の TUI が動かず、起動の直後に終了した**（接続中・デタッチ前でも）。Windows 版の移植の既知の問題（zellij の issue #4745）とみられる。実測は付録
  - 端末を持たないタスク（WezTerm 無しで `claude remote-control` を直接起動）: Claude Code は端末を要するので向かない
  - WSL の tmux の中で動かす: Windows の `claude.exe` は WSL から動かせない（`Exec format error`）

### 完了時点の状態

実機で、手順 7（SSH の切断）の後に確かめた状態。

```
PS> (Get-ScheduledTask -TaskName 'claude-remote-control').State
Running
PS> Get-CimInstance Win32_Process -Filter "Name='claude.exe'" | Where-Object CommandLine -like '*remote-control*'
  … <PID>  <PPID(WezTerm)>  claude.exe remote-control --name <RC_NAME> --spawn same-dir
  … <PID2> <PID(上の claude)> claude.exe --print --sdk-url https://api.anthropic.com/v1/code/sessions/<SESSION_ID> …
```

- claude.ai/code の一覧に `<RC_NAME>` が `connected` で出る

### 操作上の注意と併記されていた記録

  - この claude.ai のアカウントで入れる人は、スマートフォンやブラウザから `<PROJECT_DIR>` でこのユーザーとして Claude Code を動かせる。アカウントのパスワードと端末の扱いは、この PC の管理者のパスワードと同じにする。Trusted Devices（claude.ai の設定）を使うと、登録した端末からしか操作できなくなる（本書では試していない）

### 付録: 実機での検証記録（2026-10-01）

x86_64 のノート PC（Windows 11 Pro 26H2）で、同じ PC から `ssh localhost`（使い捨ての ed25519 の鍵を `administrators_authorized_keys` に一時登録）でログインして検証した。SSH のセッションを一度きりの `ssh … "powershell -File …"` で動かし、戻った時点を「切断後」とした。

**流し方**:

- SSH のセッションの PowerShell は High Mandatory Level（Administrators の一員）。タスクの登録は、昇格していないシェルでは `アクセスが拒否されました`（0x80070534 ではない）になり、SSH の昇格したセッションで通った
- タスクの `-UserId` に `$env:USERDOMAIN\$env:USERNAME` を使うと、SSH のセッションでは `$env:USERDOMAIN` が空で `0x80070534`（ERROR_NONE_MAPPED）になった。`[System.Security.Principal.WindowsIdentity]::GetCurrent().Name` にして通った

**対照（SSH の切断でプロセスが止まる）**:

- SSH のセッションで `Start-Process` の子プロセスを起こし、切断した後に数えたら 0 だった（sshd がセッションの木を止める）

**`--spawn same-dir` が要る理由**:

- `--spawn` 無しでタスクを起動すると、WezTerm の窓で `claude remote-control` が `Choose [1/2] (default: 1):`（`same-dir` / `worktree`）の確認で止まり、セッションを作らなかった（プロセスは生きていて Anthropic へ TLS は張っていたが、claude.ai にセッションが出ず、ローカルの転写も空）。デスクトップの窓を撮って確かめた。`--spawn same-dir` を足すと、確認は出ずにセッションを作って接続した

**遠隔からの操作の確認**:

- タスクで起動したセッションが claude.ai に `connected` で出た後、別の Claude Code のセッションからそのセッションへメッセージを送ると、1 ターンを処理して応答を作った（`is_error: false`、`stop_reason: end_turn`）。遠隔のクライアントからの入力を受けて動くことを確かめた

**zellij を試した記録（不採用）**:

- zellij 0.45.1（winget の `Zellij.Zellij`、`%LOCALAPPDATA%\Zellij`）を入れ、`zellij attach -c <名前> -- claude remote-control …` で試した
- zellij の**サーバー**は SSH の切断後も残った（`zellij list-sessions` に出続けた）。しかし**ペインの中の Claude Code は、起動の直後に終了した**。サーバーモード（`claude remote-control`）でも対話モード（`claude --remote-control`）でも、接続中でデタッチ前でも、`claude.exe` のプロセスが残らなかった
- 原因の切り分け: 一度だけ URL を出したので起動はしていた。zellij の初回の「Tip」の浮動ペインがキー入力を奪うこと、`claude remote-control` が端末の扱いでペインと相性が悪いことが重なったとみられる。zellij の Windows 版は 0.44（2026-03）からの新しい移植で、既知の問題が追跡されている（issue #4745）
- WezTerm（本書の方式）では同じ `claude remote-control` が動き続けたので、Claude Code 側ではなく zellij の Windows のペインの問題と判断した

**残っている未確認事項**:

1. 別の端末（スマートフォンの実機、LAN の別の PC）からの接続・操作
1. PC の再起動の後の自動起動（ログオンのトリガー）
1. デスクトップをロック／ログオフしたときの挙動
1. 標準ユーザー、Microsoft アカウントのパスワードの端末からの利用
1. スリープからの復帰時の再接続、10 分のネットワーク断での終了

### 付録: ディレクトリの検査と停止の模擬確認（2026-10-05）

- Linux の PowerShell 7.6.6 の構文解析器で、修正後の本書の PowerShell ブロック 11 個を解析し、構文の誤りは 0 だった
- 手順 4・5 を本文から抜き出した。`claude` とタスクのコマンドレットは呼び出しを記録する偽物に、Windows のユーザー名取得は検証用の固定値に置き換えた
- `PROJECT_DIR` が空・存在しないパス・ファイルなら、起動もタスク登録も呼ばなかった
- 一時ディレクトリの通常の名前・空白入り・角括弧入りのパスでは、指定したディレクトリへ移動してから起動を呼び、タスクの `--cwd` にも同じパスを渡した
- `Set-Location` が失敗する場合を模擬し、後続の起動を呼ばないことを確認した。変更前の手順では、存在しないパスを指定しても元の場所で起動を呼ぶことを再現した
- Windows PowerShell 5.1 での実行、Windows のパスやアクセス権、実際の Claude Code・WezTerm の起動とタスク登録は、この確認では行っていない

### 手順中の実測・検証範囲

- RDP で使った後にふつうに切断していると、自分の行のセッション名が空で、状態が `Disc`（切断）になる。RDP でつなぎ直し、[RDP をロックせずに切断する手順](windows-rdp-disconnect.md)で切ると `console` に戻る（その手順書は Windows の実機で流していない）

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 実施手順

> - 前提: [Windows 11 の初期設定の「貼り付けの設定」の手順 1〜4](../windows-setup.md#貼り付けの設定)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。このユーザーのプロファイルに書くので、SSH でログインした Windows PowerShell も読む（SSH のクライアントから貼ったときの動きは確かめていない）

### 補足

- **デスクトップにログオンしている必要がある**: タスクは `Interactive` で、ログオン中のデスクトップのセッションに WezTerm を開く。ログオフすると動かない。ロック中の挙動は確かめていない

  - PC がスリープすると、その間は使えない。公式ドキュメントは、復帰すれば自動でつなぎ直すと書いている。本書では確かめていない（Windows の電源の設定は本書の対象外）

- **`claude remote-control --help` は終わらない**: help を出した後も終了しないことがあった。手順には入れていない

- **Claude Code の自動更新**: native installer は背景で更新する。動いているサーバーは古い版のままで、次に始め直したときから新しい版になる（検証中に 2.1.283 から 2.1.286 に上がった）

- **起動時の自動起動**: タスクにログオンのトリガー（`New-ScheduledTaskTrigger -AtLogOn`）を足せば、ログオンで自動で始められる（本書では確かめていない）
