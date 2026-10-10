# Windows 11 で OpenSSH クライアントを使う手順（ed25519 の鍵と ssh の config で AlmaLinux 10 のホストに入る）のロールバックと注意点

[手順書](../windows-ssh-client.md)・[検証記録](../verification/windows-ssh-client.md)・[参考資料](../reference/windows-ssh-client.md)

- 「手順 N」は[手順書](../windows-ssh-client.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- [手順 2](../windows-ssh-client.md#実施手順) の変数を設定した、管理者ではない Windows PowerShell（5.1）に、上から順に貼る。新しい窓なら、手順 2 のブロックを貼り直してから貼る
- ホストの `authorized_keys` の行を消すには鍵で入るので、鍵のファイルを消す手順は最後にしてある
- Windows の OpenSSH クライアントと Git の ssh は外さない（ほかの手順書も使う）

> [!CAUTION]
> **この節の手順 4 で、秘密鍵と公開鍵（`%USERPROFILE%\.ssh\id_ed25519`・`id_ed25519.pub`）を消すと、取り戻せない**。GitHub やほかのホストにも登録してある鍵（[手順 4](../windows-ssh-client.md#実施手順) で作らなかった鍵）なら、この節の手順 4 は行わない。

1. ホストの authorized_keys から、この鍵の行を消す。

   ```powershell
   $pub = "$env:USERPROFILE\.ssh\id_ed25519.pub"
   $k = ''
   if (Test-Path -LiteralPath $pub) { $k = [string]((Get-Content -LiteralPath $pub -TotalCount 1) -split ' ')[1] }
   if (-not $SSH_ALIAS) {
     Write-Error '中断: 手順 2 の SSH_ALIAS が空のまま。値を入れて貼り直す'
   } elseif ($k -notmatch '^AAAA[0-9A-Za-z+/=]+$') {
     Write-Error "中断: $pub が無いか、公開鍵の形でない（ホストの authorized_keys は変えない）"
   } else {
     $cmd = 'umask 077; grep -vF -- {0} ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.new; if [ $? -le 1 ]; then mv -f ~/.ssh/authorized_keys.new ~/.ssh/authorized_keys; else rm -f ~/.ssh/authorized_keys.new; fi; if type restorecon >/dev/null 2>&1; then restorecon -F ~/.ssh/authorized_keys; fi; grep -cF -- {0} ~/.ssh/authorized_keys' -f $k
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     & "$env:WINDIR\System32\OpenSSH\ssh.exe" $SSH_ALIAS $cmd
   }
   ```

   - 最後に `0`（この鍵の行が残っていない）が出ればよい
   - 鍵にパスフレーズを付けたなら聞かれる。鍵で入れなくなっていれば、ホストのユーザーのパスワードを聞かれる
   - ホストを既に消したなど、つなげないときは、この手順は飛ばす
   - **次の手順は、`0` が出てから貼る**（続けて貼るとパスフレーズかパスワードとして食われる）

1. `~/.ssh/config` から、[手順 7](../windows-ssh-client.md#実施手順) で足した接続先を消す。

   ```powershell
   $f = "$env:USERPROFILE\.ssh\config"
   if (-not $SSH_ALIAS) {
     Write-Error '中断: 手順 2 の SSH_ALIAS が空のまま。値を入れて貼り直す'
   } elseif (-not (Test-Path -LiteralPath $f)) {
     Write-Error "中断: $f が無い"
   } else {
     $a = [regex]::Escape($SSH_ALIAS)
     $e = [Text.Encoding]::GetEncoding(28591)
     $t = $e.GetString([IO.File]::ReadAllBytes($f))
     $n = [regex]::Replace($t, "(?ms)^# BEGIN windows-ssh-client\.md $a\r?\n.*?^# END windows-ssh-client\.md $a(\r?\n|\z)", '')
     if ($n -eq $t) {
       Write-Error "中断: $f に $SSH_ALIAS の印の行が無い"
     } else {
       [IO.File]::WriteAllBytes($f, $e.GetBytes($n))
       "`n$([char]27)[7m 確認 $([char]27)[0m"
       Select-String -LiteralPath $f -Pattern "windows-ssh-client\.md $a"
     }
   }
   ```

   - 何も出なければよい（印の行が残っていない）
   - 印の間の行だけを消し、config のほかの行はそのまま残す（ファイルのバイトをそのまま書き戻すので、文字コードは変わらない）

1. known_hosts から、ホストのホスト鍵を消す。

   ```powershell
   if (-not $SSH_HOST) {
     Write-Error '中断: 手順 2 の SSH_HOST が空のまま。値を入れて貼り直す'
   } else {
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     & "$env:WINDIR\System32\OpenSSH\ssh-keygen.exe" -R $SSH_HOST
   }
   ```

   - `# Host <SSH_HOST> found: line N` が鍵の種類の数だけと、`… known_hosts updated.`・`Original contents retained as … known_hosts.old` が出ればよい
   - Git の ssh も同じ known_hosts を使うので、Git の ssh の側で消す手順は無い
   - **注意**: 元の known_hosts は `known_hosts.old` に写される。前からあった `known_hosts.old` は上書きされる

1. [手順 4](../windows-ssh-client.md#実施手順) で作った鍵を、ほかで使っていないときだけ消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\.ssh\id_ed25519", "$env:USERPROFILE\.ssh\id_ed25519.pub"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path -LiteralPath "$env:USERPROFILE\.ssh\id_ed25519", "$env:USERPROFILE\.ssh\id_ed25519.pub"
   ```

   - `False` が 2 行出ればよい
   - [手順 4](../windows-ssh-client.md#実施手順) で `既にある:` か `公開鍵を作り直した:` と出た鍵（前からあった鍵）は消さない

---

## 注意点

- **ssh-agent は使わない**: パスフレーズを付けた鍵は、使うたびに聞かれる（ssh・scp・WezTerm の起動メニュー・ssh を使う git）
  - 同じ鍵を GitHub にも登録しているなら、git の fetch・push のたびにも聞かれる
  - パスフレーズを後から付ける・変えるのは、`& "$env:WINDIR\System32\OpenSSH\ssh-keygen.exe" -p -f "$env:USERPROFILE\.ssh\id_ed25519"`
- **2 つの ssh が、同じ `%USERPROFILE%\.ssh` を使う**: Windows の ssh（PowerShell・WezTerm の起動メニュー）と Git の ssh（Git Bash・git）は、鍵・config・known_hosts を共有する
  - WSL の AlmaLinux 10 の ssh は、WSL のホームの `~/.ssh` を使う（別のもの）。WSL から入るなら、WSL の中で鍵を作る
- **config を BOM 付きや UTF-16 で保存しない**: Windows PowerShell 5.1 の `-Encoding UTF8`・`>`・`>>`・`Out-File` は、BOM 付きの UTF-8 か UTF-16 で書く
  - Windows の ssh は UTF-8 の BOM を読み飛ばすが、Git の ssh は `Bad configuration option` で止まり、ssh を使う git（GitHub への push など）も失敗する。UTF-16 は両方が読めない
  - メモ帳で書くなら、文字コードを「UTF-8」（BOM なし）にする
- **config には、両方の ssh が知っている設定だけを書く**: Windows の ssh（9.5p2）が知らない新しい設定を書くと、Windows の ssh が止まる。書いた後は、[更新](../windows-ssh-client.md#更新)の手順 1 で両方を確かめる
- **ssh の設定は、最初に見つけた値が効く**: config の前の方の `Host *` などにある `User`・`IdentityFile` は、手順 7 で足した値より先に効く
- **Git の `usr\bin` が `PATH` の先にある PC**: PowerShell と WezTerm の起動メニューの `ssh` が、Git のものになる（[Windows 11 の初期設定の注意点](windows-setup.md#注意点)の OpenSSH サーバーと同じ）。この手順書のブロックは、どちらもフルパスで呼ぶ
- **秘密鍵のアクセス権**: Windows の ssh は、ほかの主体（Everyone・Users など）に許可のある秘密鍵を、`UNPROTECTED PRIVATE KEY FILE!` と出して使わない（手順 5・6）
- **config のアクセス権**: Windows の ssh は、ほかの主体に書き込みの許可のある config を読まず、`Bad owner or permissions on …config` で止まる
  - ほかの PC から写した config や、同期した config で起こりうる
  - 手順 6 のブロックの 1 行目の `id_ed25519` を `config` に書き換えて貼り、[更新](../windows-ssh-client.md#更新)の手順 1 で確かめ直す
- **ホストがパスワードでのログインを受け付けないとき**（`PasswordAuthentication no` にしたホストなど）: 手順 9 は使えない。手順 9 の公開鍵の 1 行（`id_ed25519.pub` の中身）を、ホストの画面などで `~/.ssh/authorized_keys` に足す
  - [AlmaLinux 10 の初期設定の任意節「SSH を公開鍵だけにする」](../almalinux-setup.md#ssh-を公開鍵だけにする任意)を通したホストが、これに当たる。足すのは、その節の手順 1（`SSH_PUBKEY` に公開鍵の 1 行を入れる）でよい
  - その節をまだ通していないホストでは、この手順書を先に通す（手順 9 でパスワードを使う）
- **FIPS モードのホスト**: ed25519 の鍵は使えない（RHEL 10 の文書）。この手順書では扱わない
