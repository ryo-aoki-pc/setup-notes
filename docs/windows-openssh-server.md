# Windows 11 で OpenSSH サーバーを使う手順（OpenSSH.Server の機能 + パスワード認証）

## 実施手順

- [検証記録](verification/windows-openssh-server.md)・[参考資料](reference/windows-openssh-server.md)

> [!IMPORTANT]
> - **手順 1〜7 は Windows で行う**。手順 1 で管理者の Windows PowerShell（5.1）を開き、手順 2〜7 をそこに貼る
> - 前提: [Windows 11 の初期設定の手順 16〜19](windows-setup.md#実施手順)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、Windows のブロックは Ctrl+V で貼る
> - 前提: クライアントとつながる LAN の接続がプライベートであること（[Windows 11 の初期設定の手順 43](windows-setup.md#実施手順)）。手順 5 で確かめる
> - **手順 8・9 は、クライアントの PC（AlmaLinux 10 など）の自分のユーザーのシェルに貼る**
> - SSH でログインするのは、この PC の Windows のユーザー。パスワードは、そのユーザーの Windows のパスワード（Microsoft アカウントなら、そのアカウントのパスワード）。Administrators の一員でないユーザーも入れる（[注意点](#注意点)）
> - **手順 9 には対話入力がある**（ホスト鍵の確認とパスワード）

- 上から順にコードブロックを貼る。Windows の手順は手順 2 で変数を設定した PowerShell に、クライアントの手順は手順 8 で変数を設定したシェルに貼る
- 手順の後に、必要なら次の任意節を行う
  - 鍵でも入る: [公開鍵でもログインする（任意）](#公開鍵でもログインする任意)
  - 鍵で入れるようにした後、パスワードを受け付けないようにする: [パスワード認証を切る（任意）](#パスワード認証を切る任意)
  - ログインしたときのシェルを Git Bash にする: [既定のシェルを Git Bash にする（任意）](#既定のシェルを-git-bash-にする任意)
  - scoop で入れたツールが SSH のセッションで起動しない: [scoop のツールを SSH のセッションで使う（任意）](#scoop-のツールを-ssh-のセッションで使う任意)
- 戻すときは[ロールバック](#ロールバック)

1. Windows で、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く
   - PowerShell 7（`pwsh`）では、手順 3 が失敗する

1. Windows の管理者の PowerShell で、変数を設定する。

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # クライアントとつながる LAN の接続（自動）。<LAN_IF>
   'LAN_IF = {0}' -f $LAN_IF
   ```

   - 最後に値を読み戻して確かめる
   - `LAN_IF` は、インターネットにつながっている接続の名前（`イーサネット`、`Wi-Fi` など）。クライアントとつながる接続と違えば、`$LAN_IF = 'Wi-Fi'` のように直す
   - 変数はその PowerShell の中だけで有効。**新しい PowerShell を開いたら**、手順 2 のブロックを貼り直してから先へ進む

1. OpenSSH サーバーの機能を入れる。

   ```powershell
   if ($PSVersionTable.PSEdition -ne 'Desktop') {
     Write-Error 'Windows PowerShell（5.1）で貼る。PowerShell 7 では Add-WindowsCapability が失敗する'
   } else {
     Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
     Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Format-List Name, State
   }
   ```

   - Windows Update から取ってくるので、数分かかる
   - `RestartNeeded : False` と `State : Installed` が出ればよい
   - 既に入っていれば、すぐに `State : Installed` が出る

1. sshd を自動で起動するようにして起動し、待ち受けを確かめる。

   ```powershell
   Set-Service -Name sshd -StartupType Automatic
   Start-Service -Name sshd
   Get-Service -Name sshd | Format-Table Name, Status, StartType
   Get-NetTCPConnection -State Listen -LocalPort 22 | Format-Table LocalAddress, LocalPort, OwningProcess
   ```

   - `sshd  Running  Automatic` が出る
   - 22 番で `0.0.0.0` と `::` の 2 行が出ればよい

1. LAN の接続がプライベートなことと、sshd の受信の規則を確かめる。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '手順 2 の $LAN_IF が空'
   } elseif ((Get-NetConnectionProfile -InterfaceAlias $LAN_IF).NetworkCategory -ne 'Private') {
     Write-Error '中断: LAN の接続がプライベートではない（Windows 11 の初期設定の手順 43 でプライベートにする）'
   } else {
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
     Get-NetFirewallRule -Name OpenSSH-Server-In-TCP | Format-Table Name, Enabled, Profile, Direction, Action
   }
   ```

   - `<LAN_IF>  Private` と、`OpenSSH-Server-In-TCP  True  Private  Inbound  Allow` が出ればよい
   - `中断:` が出たら、[Windows 11 の初期設定の手順 43](windows-setup.md#実施手順) でプライベートにしてから、この手順を貼り直す（手順 2 の変数はそのまま使える）
   - **注意**: プライベートの LAN では、プライベート向けのほかの許可の規則（ネットワーク探索など）も効く（[選択した方針](verification/windows-openssh-server.md#選択した方針)）

1. パスワード認証を有効にし、設定を検査してから sshd を再起動する。

   ```powershell
   $c = "$env:ProgramData\ssh\sshd_config"
   (Get-Content $c) -replace '^#?PasswordAuthentication .*', 'PasswordAuthentication yes' | Set-Content $c -Encoding ascii
   & "$env:WINDIR\System32\OpenSSH\sshd.exe" -t
   if ($LASTEXITCODE -eq 0) { Restart-Service -Name sshd } else { Write-Error 'sshd_config に誤りがある（sshd は再起動していない）' }
   Select-String -Path $c -Pattern '^PasswordAuthentication', '^Match'
   ```

   - `…sshd_config:51:PasswordAuthentication yes` と `…sshd_config:87:Match Group administrators` が出ればよい
   - 何度貼っても結果は同じ

1. 接続先と、ホスト鍵の指紋を表示する。

   ```powershell
   '{0}@{1}' -f $env:USERNAME, (Get-NetIPAddress -InterfaceAlias $LAN_IF -AddressFamily IPv4).IPAddress
   & "$env:WINDIR\System32\OpenSSH\ssh-keygen.exe" -lf "$env:ProgramData\ssh\ssh_host_ed25519_key.pub"
   ```

   - 1 行目の `<WIN_USER>@<WIN_HOST>` が、手順 8 で使う値
   - 2 行目の `256 SHA256:<指紋> system@<HOSTNAME> (ED25519)` を、手順 9 の初回の接続で照合する
   - Microsoft アカウントでも、ユーザー名はメールアドレスではなく、`C:\Users\` の下のフォルダーの名前

1. クライアントの PC で、変数を設定する（`WIN_HOST` は必ず値を入れる）。

   ```bash
   WIN_HOST=                             # ← 手順 7 の @ の後ろ（Windows の IP アドレス）を書く。<WIN_HOST>
   ```

   ```bash
   WIN_USER=${USER}                      # Windows のユーザー名。手順 7 の @ の前と違えば直す。<WIN_USER>
   for v in WIN_HOST WIN_USER; do
     printf '%-8s = %s\n' "$v" "${!v}"
   done
   ```

   - 最後に値を読み戻して確かめる
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**、手順 8 の 2 つのブロックを貼り直してから先へ進む

1. クライアントの PC で、ホスト鍵を照合し、パスワードでログインする。

   ```bash
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 手順 8 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh -o PubkeyAuthentication=no "${WIN_USER}@${WIN_HOST}"
   fi
   ```

   - 初回は `ED25519 key fingerprint is SHA256:…` と `Are you sure you want to continue connecting (yes/no/[fingerprint])?` が出る。手順 7 の指紋と同じなら `yes`
   - `<WIN_USER>@<WIN_HOST>'s password:` で、Windows のユーザーのパスワードを入れる（Microsoft アカウントなら、そのアカウントのパスワード。PIN ではない）
   - `<WIN_USER>@<HOSTNAME> C:\Users\<WIN_USER>>` の cmd のプロンプトが出ればよい。`whoami` で `<hostname>\<win_user>`（小文字）が出る
     - [既定のシェルを Git Bash にする（任意）](#既定のシェルを-git-bash-にする任意)の後は、`<WIN_USER>@<HOSTNAME> MINGW64 ~` のプロンプトになり、`whoami`（Git のもの）は `<WIN_USER>` だけを出す
   - `exit` でクライアントのシェルに戻る
   - **注意**: パスワードを続けて間違えると、Windows のロックアウトのポリシーでアカウントがロックされる（[注意点](#注意点)）
   - **後ろの節を貼るのは、`exit` でクライアントのシェルに戻ってから**（続けて貼ると Windows の cmd への入力として食われる）

---

## 公開鍵でもログインする（任意）

- クライアントで作った鍵で、パスワードを入れずに入れるようにする。パスワード認証は有効のまま
- この節の手順 1・2・5 はクライアントの PC の手順 8 のシェルに、手順 3・4 は Windows の管理者の Windows PowerShell に貼る
- 登録できるのは、Administrators の一員のユーザーの鍵だけ（この節の手順 4 で確かめる。標準ユーザーは[注意点](#注意点)）
- 登録した鍵を持つ人も、パスワードを知る人と同じく、この PC の管理者として操作できる（[注意点](#注意点)）

1. クライアントの PC で、鍵ペアが無ければ作る。

   ```bash
   ls ~/.ssh/id_ed25519.pub 2>/dev/null || ssh-keygen -t ed25519
   ```

   - 鍵があれば、`/home/<USER>/.ssh/id_ed25519.pub` と出て何もしない（その鍵を使う）
   - 無ければ、保存先（Enter で既定の `~/.ssh/id_ed25519`）とパスフレーズ（2 回）を聞かれる
   - **次の手順は、パスフレーズを入力し終えてから貼る**（続けて貼るとパスフレーズとして食われる）

1. クライアントの PC で、公開鍵を表示する。

   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

   - `ssh-ed25519 AAAA… <USER>@<HOSTNAME>` の 1 行が出る。この 1 行をコピーし、この節の手順 3 で Windows に貼る
   - 公開鍵は秘密ではない。チャットやメールで Windows 側へ渡してもよい

1. Windows の管理者の PowerShell で、変数を設定する（`$PUBKEY` は必ず値を入れる）。

   ```powershell
   $PUBKEY = ''                          # ← この節の手順 2 の 1 行を '' の中に貼る。<PUBKEY>
   ```

   ```powershell
   'PUBKEY = {0}' -f $PUBKEY
   ```

   - 改行を入れずに 1 行のまま貼る
   - 最後に値を読み戻して確かめる。空、または `ssh-` などで始まらなければ、この節の手順 4 は何もしないで止まる
   - **新しい PowerShell を開いたら**、この手順の 2 つのブロックを貼り直してから先へ進む

1. 公開鍵を `administrators_authorized_keys` に登録する。

   ```powershell
   if ($PUBKEY -notmatch '^(ssh-|ecdsa-|sk-)') {
     Write-Error 'この節の手順 3 の $PUBKEY が空か、公開鍵の形でない'
   } elseif (-not (Get-LocalGroupMember -SID S-1-5-32-544 | Where-Object Name -like "*\$env:USERNAME")) {
     Write-Error "$env:USERNAME は Administrators の一員ではない（注意点を見る）"
   } else {
     $f = "$env:ProgramData\ssh\administrators_authorized_keys"
     Add-Content -Path $f -Value $PUBKEY -Encoding ascii
     icacls.exe $f /inheritance:r /grant '*S-1-5-32-544:F' /grant '*S-1-5-18:F'
     icacls.exe $f
   }
   ```

   - 最後の `icacls` に、`NT AUTHORITY\SYSTEM:(F)` と `BUILTIN\Administrators:(F)` の 2 行だけが出ればよい
   - クライアントを足すときは、そのクライアントでこの節の手順 1・2 を行い、この節の手順 3 の `$PUBKEY` を貼り直してから、この節の手順 4 を貼る（行が足される）

1. クライアントの PC で、鍵で入れることを確かめる。

   ```bash
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 手順 8 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh -o PasswordAuthentication=no "${WIN_USER}@${WIN_HOST}" whoami
   fi
   ```

   - パスワードを聞かれずに、`<hostname>\<win_user>` が出ればよい（パスフレーズを付けたなら、それを聞かれる）
   - 既定のシェルを Git Bash にした PC では、Git の `whoami` が動き、`<WIN_USER>` だけが出る

---

## パスワード認証を切る（任意）

- 鍵を持たない相手からのパスワードを受け付けないようにする（パスワードの総当たりを受け付けない）
- 前提: [公開鍵でもログインする（任意）](#公開鍵でもログインする任意)を行い、使うクライアントが鍵で入れること。切った後は、鍵を登録していないクライアント（スマートフォンのアプリなど）からは入れない
- この節の手順 1 は Windows の管理者の Windows PowerShell に、手順 2 はクライアントの手順 8 のシェルに貼る
- パスワード認証に戻すときは、[手順 6](#実施手順) を貼り直す

1. Windows で、パスワード認証を切り、設定を検査してから sshd を再起動する。

   ```powershell
   $c = "$env:ProgramData\ssh\sshd_config"
   (Get-Content $c) -replace '^#?PasswordAuthentication .*', 'PasswordAuthentication no' | Set-Content $c -Encoding ascii
   & "$env:WINDIR\System32\OpenSSH\sshd.exe" -t
   if ($LASTEXITCODE -eq 0) { Restart-Service -Name sshd } else { Write-Error 'sshd_config に誤りがある（sshd は再起動していない）' }
   Select-String -Path $c -Pattern '^PasswordAuthentication', '^Match', 'administrators_authorized_keys'
   ```

   - `…sshd_config:51:PasswordAuthentication no` と、`Match Group administrators` とその次の `AuthorizedKeysFile` の行が出ればよい
   - 何度貼っても結果は同じ

1. クライアントの PC で、鍵が無いと入れず、鍵ではコマンドが通ることを確かめる。

   ```bash
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 手順 8 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh -o PubkeyAuthentication=no "${WIN_USER}@${WIN_HOST}" true
     ssh "${WIN_USER}@${WIN_HOST}" whoami
   fi
   ```

   - 1 つ目は、パスワードを聞かずに `<WIN_USER>@<WIN_HOST>: Permission denied (publickey,keyboard-interactive).` で失敗すればよい
   - 2 つ目は、`<hostname>\<win_user>` が出ればよい（パスフレーズを付けたなら、それを聞かれる）
     - 既定のシェルを Git Bash にした PC では、Git の `whoami` が動き、`<WIN_USER>` だけが出る

---

## 既定のシェルを Git Bash にする（任意）

- SSH でログインしたとき・コマンドを実行するときのシェルを、cmd.exe から Git for Windows の bash に変える
- 前提: Git for Windows が `C:\Program Files\Git` に入っていること
- この節の手順 1・3 は Windows の管理者の Windows PowerShell に、手順 2 はクライアントの手順 8 のシェルに貼る

1. Windows で、既定のシェルを Git Bash にする。

   ```powershell
   if (-not (Test-Path 'C:\Program Files\Git\bin\bash.exe')) {
     Write-Error 'C:\Program Files\Git\bin\bash.exe が無い（Git for Windows が入っていない）'
   } else {
     New-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -Value 'C:\Program Files\Git\bin\bash.exe' -PropertyType String -Force | Format-List DefaultShell
   }
   ```

   - `DefaultShell : C:\Program Files\Git\bin\bash.exe` が出ればよい
   - sshd の再起動は要らない。次のログインから変わる

1. クライアントの PC で、bash になったことを確かめる。

   ```bash
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 手順 8 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh "${WIN_USER}@${WIN_HOST}" 'echo "$BASH_VERSION $MSYSTEM"; git --version'
     ssh "${WIN_USER}@${WIN_HOST}"
   fi
   ```

   - 鍵を登録していなければ、パスワードを 2 回聞かれる（`ssh` が 2 つある）
   - 1 つ目で `5.3.15(1)-release MINGW64` と `git version 2.55.0.windows.3` のような 2 行が出ればよい
   - 2 つ目は、`<WIN_USER>@<HOSTNAME> MINGW64 ~` と `$` のプロンプトになる。`exit` で戻る
   - **注意**: コマンドを実行するときも、Windows 側の `~/.bashrc` が読まれる
   - `Shim: Could not create process …` が出るなら、[scoop のツールを SSH のセッションで使う（任意）](#scoop-のツールを-ssh-のセッションで使う任意)を行う

1. 元に戻すときは、`DefaultShell` を消す。

   ```powershell
   Remove-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell
   ```

   - 何も出ずに終わればよい。次のログインから cmd.exe に戻る

---

## scoop のツールを SSH のセッションで使う（任意）

- scoop で入れたツール（`zoxide`・`rg`・`nvim` など）が、SSH のセッションでだけ起動しないときに行う
  - 症状は、scoop の shim の `Could not create process with command …`、Git Bash の `Is a directory`、Windows のエラー 448（信頼されていないマウントポイント）
- 原因は、sshd の緩和策 RedirectionGuard。管理者以外が作ったジャンクションを、SSH のセッションのプロセスはたどれない
  - scoop の `current` と persist のジャンクションは、一般ユーザーの scoop が作るので、この制限に当たる
- この節は、それらのジャンクションを、管理者の PowerShell で同じ向き先のまま作り直す（中身は変えない）
- 前提: scoop が `C:\Users\<WIN_USER>\scoop` に入っていること（[Windows 11 の初期設定の手順 20・21](windows-setup.md#実施手順) で入れた形）
- この節の手順 1 は Windows の管理者の Windows PowerShell に、手順 2 はクライアントの手順 8 のシェルに貼る
- `scoop install`・`scoop update` の後は、新しいジャンクションが一般ユーザーの作ったものになるので、この節の手順 1 を貼り直す

1. Windows で、scoop のジャンクションを管理者で作り直す。

   ```powershell
   Get-ChildItem "$env:USERPROFILE\scoop\apps" -Recurse -Depth 4 -Force -Attributes ReparsePoint -ErrorAction SilentlyContinue |
     Where-Object { $_.LinkType -eq 'Junction' -and (Get-Acl $_.FullName).Owner -notlike '*\Administrators' } |
     ForEach-Object {
       $link = $_.FullName; $target = @($_.Target)[0]; $ro = $_.Attributes -band [IO.FileAttributes]::ReadOnly
       if (Test-Path -LiteralPath $target) {
         attrib.exe -R "$link" /L
         cmd.exe /c rmdir "$link"
         New-Item -ItemType Junction -Path $link -Target $target | Out-Null
         if ($ro) { attrib.exe +R "$link" /L }
         '{0} -> {1}' -f $link, $target
       }
     }
   ```

   - 作り直したジャンクションごとに、`…\scoop\apps\<アプリ>\current -> …\scoop\apps\<アプリ>\<版>` の形の行が出る
   - 作り直すものが無ければ、何も出ない（何度貼ってもよい）

1. クライアントの PC で、scoop のツールが動くことを確かめる。

   ```bash
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 手順 8 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh "${WIN_USER}@${WIN_HOST}" 'zoxide --version'
   fi
   ```

   - 鍵を登録していなければ、パスワードを聞かれる
   - `zoxide 0.9.9` のような版が出て、`Shim:` で始まる行が出なければよい（`zoxide` の代わりに、scoop で入れたほかのツールでもよい）

---

## ロールバック

- この節の手順 1・2 は Windows の管理者の Windows PowerShell（手順 2 の変数を設定したもの）に、手順 4 はクライアントの手順 8 のシェルに貼る。手順 3 は Windows 11 の初期設定のロールバックで行う
- 機能を外しても、`C:\ProgramData\ssh` とレジストリの `HKLM:\SOFTWARE\OpenSSH` は残る。この節の手順 2 で消す

> [!CAUTION]
> **この節の手順 2 で、ホスト鍵と、登録した公開鍵（`C:\ProgramData\ssh`）を消す。** 入れ直すとホスト鍵が変わり、クライアントの `known_hosts` と合わなくなる（この節の手順 4 で消す）。

1. sshd を止め、OpenSSH サーバーの機能を外す。

   ```powershell
   if ($PSVersionTable.PSEdition -ne 'Desktop') {
     Write-Error 'Windows PowerShell（5.1）で貼る'
   } else {
     Stop-Service -Name sshd
     Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
     Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Format-List Name, State
   }
   ```

   - `RestartNeeded : False` と `State : NotPresent` が出ればよい
   - サービス `sshd`、`sshd.exe`、受信の規則 `OpenSSH-Server-In-TCP` が消える。クライアントの `ssh.exe` などは残る

1. 設定・ホスト鍵・登録した公開鍵と、レジストリのキーを消す（取り戻せない）。

   ```powershell
   Remove-Item -Path "$env:ProgramData\ssh" -Recurse -Force
   Remove-Item -Path HKLM:\SOFTWARE\OpenSSH -Recurse
   Test-Path "$env:ProgramData\ssh", HKLM:\SOFTWARE\OpenSSH
   ```

   - `False` が 2 行出ればよい

1. LAN の接続をパブリックに戻すときだけ、[Windows 11 の初期設定のロールバック](windows-setup.md#ロールバック)の手順 33 を行う。

   - この LAN でほかにプライベートの規則を使うもの（[Syncthing の Windows 11 の節](syncthing.md#windows-11-で使う)、リモート デスクトップなど）があれば、戻さない

1. クライアントの PC で、Windows のホスト鍵を `known_hosts` から消す。

   ```bash
   ssh-keygen -R "${WIN_HOST:?手順 8 の WIN_HOST が空のまま}"
   ```

   - `# Host <WIN_HOST> found: line N` が鍵の種類の数だけ出て、`… known_hosts updated.` で終わればよい
   - **注意**: 元の `known_hosts` は `~/.ssh/known_hosts.old` に写される。前からあった `known_hosts.old` は上書きされる

---

## 注意点

- **SSH のセッションは管理者の権限を持つ**
  - Administrators の一員でログインすると、`whoami /groups` で `Mandatory Label\High Mandatory Level` と、有効な `BUILTIN\Administrators` を確認する
  - このユーザーのパスワードを知る人と、登録した鍵を持つ人は、この PC の管理者として操作できる。パスワードと秘密鍵の扱いは、管理者のパスワードと同じにする
- **パスワードでのログイン**
  - ユーザー名は、Microsoft アカウントでもメールアドレスではなく、`C:\Users\` の下のフォルダーの名前（手順 7）。パスワードは、そのアカウントのパスワード（PIN ではない）
  - Microsoft アカウントのパスワードが sshd のログにエラー 1326 を残して拒否される場合は、Windows Hello 限定の設定をオフにして sshd を再起動する
  - [Windows 11 の初期設定の手順 48](windows-setup.md#実施手順) を通した PC では、この設定はオフになっている
- **パスワードを続けて間違えたとき**
  - SSH のパスワードの失敗もロックアウトの対象になる。`net accounts` でポリシーを確認し、パスワードを続けて試さない
  - ロック中は、正しいパスワードでも入れない。ロックアウトのポリシーで決まる時間を待ってから再接続する
- **鍵で入ったセッションは、ユーザーの資格情報を持たない**（Microsoft の文書）。セッションの中から、そのユーザーとしてほかのサーバーの共有などへ認証できない
- **標準ユーザーでログインするとき**
  - パスワードの認証を有効にすると、Administrators の一員でないユーザーも、パスワードがあれば SSH で入れる
  - 標準ユーザーのセッションは `Medium Mandatory Level` で、管理者の権限を持たない
  - 標準ユーザーの鍵は `C:\Users\<ユーザー>\.ssh\authorized_keys` に置く（Microsoft の文書）。公開鍵の任意節の手順 4 は、Administrators の一員でなければ止まる
- **LAN の外のサブネットからの接続**
  - 規則の接続元は `Any` で、プロファイルは接続を受けた LAN で決まる。LAN を通って届く接続なら、送信元が別のサブネットでも受け付ける
- **WSL から、この PC につなぐとき**
  - WSL のネットワークが既定（NAT）なら、この PC の LAN の IP（`<WIN_HOST>`）あてにつなぐ
  - ミラーにした PC（[Windows 11 の初期設定の任意節](windows-setup.md#wsl-のネットワークをミラーにする任意)）では、`127.0.0.1` あてにつなぐ。LAN の IP あてはつながらず、sshd のログの送信元も `127.0.0.1` になるはず（`127.0.0.1` で届くことも含め、確かめていない）
- **Git の ssh が先に見つかる PC**: `PATH` の順で、Windows の `ssh`・`ssh-keygen` ではなく Git のものが動く。Windows の OpenSSH のものは `C:\Windows\System32\OpenSSH\` から呼ぶ（手順 7）
- **SSH のセッションでは、一般ユーザーが作ったジャンクションをたどれない**
  - sshd に掛けてある RedirectionGuard を、セッションのプロセスが引き継ぐため。開こうとすると、エラー 448（`ERROR_UNTRUSTED_MOUNT_POINT`）になる
  - ローカルのシェルは、昇格していても RedirectionGuard が掛かっておらず、影響を受けない
  - scoop のジャンクションは、[scoop のツールを SSH のセッションで使う（任意）](#scoop-のツールを-ssh-のセッションで使う任意)で、管理者で作り直す
- **設定を変えたとき**: `sshd_config` を変えたら `Restart-Service sshd`（手順 6）。レジストリの `DefaultShell` は、次のログインから使われる
- **機能を外したとき**
  - Microsoft の文書は、使っている間に外したなら Windows を再起動するよう書いている
- **ログ**: イベント ビューアーの「OpenSSH」→「Operational」
