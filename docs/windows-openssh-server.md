# Windows 11 で OpenSSH サーバーを使う手順（OpenSSH.Server の機能 + パスワード認証）

## 実施手順

> [!IMPORTANT]
> - **手順 1〜7 は Windows で行う**。手順 1 で管理者の Windows PowerShell（5.1）を開き、手順 2〜7 をそこに貼る
> - **手順 8・9 は、クライアントの PC（AlmaLinux 10 など）の自分のユーザーのシェルに貼る**
> - SSH でログインするのは、この PC の Windows のユーザー。パスワードは、そのユーザーの Windows のパスワード（Microsoft アカウントなら、そのアカウントのパスワード）。Administrators の一員でないユーザーも入れる（[注意点](#注意点)）
> - **手順 9 には対話入力がある**（ホスト鍵の確認とパスワード）

- 上から順にコードブロックを貼る。Windows の手順は手順 2 で変数を設定した PowerShell に、クライアントの手順は手順 8 で変数を設定したシェルに貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後に、必要なら次の任意節を行う
  - 鍵でも入る: [公開鍵でもログインする（任意）](#公開鍵でもログインする任意)
  - 鍵で入れるようにした後、パスワードを受け付けないようにする: [パスワード認証を切る（任意）](#パスワード認証を切る任意)
  - ログインしたときのシェルを Git Bash にする: [既定のシェルを Git Bash にする（任意）](#既定のシェルを-git-bash-にする任意)
  - scoop で入れたツールが SSH のセッションで起動しない: [scoop のツールを SSH のセッションで使う（任意）](#scoop-のツールを-ssh-のセッションで使う任意)
- 戻すときは[ロールバック](#ロールバック)

> [!WARNING]
> **Administrators の一員で SSH にログインすると、そのセッションは UAC の確認無しで管理者の権限を持つ**（検証した PC では High Mandatory Level）。このユーザーのパスワードを知る人は、SSH が届くところから、この PC の管理者として操作できる（[注意点](#注意点)）。

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

   <details>
   <summary>補足: 変数について</summary>

   - `$LAN_IF` は、手順 5（ネットワークをプライベートにする）、手順 7（接続先の IP を出す）、[ロールバック](#ロールバック)の手順 3 で使う
   - 接続の一覧は `Get-NetConnectionProfile` で見られる。検証した PC では、WSL を動かしていても `vEthernet (WSL (Hyper-V firewall))` は一覧に出ず、有線 LAN の 1 行だけだった
   - 公開鍵の `$PUBKEY` は[公開鍵でもログインする（任意）](#公開鍵でもログインする任意)でしか使わないので、手順 2 ではなくその節の手順 3 で設定する

   </details>

1. OpenSSH サーバーの機能を入れる。

   ```powershell
   if ($PSVersionTable.PSEdition -ne 'Desktop') {
     Write-Error 'Windows PowerShell（5.1）で貼る。PowerShell 7 では Add-WindowsCapability が失敗する'
   } else {
     Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
     Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Format-List Name, State
   }
   ```

   - Windows Update から取ってくるので、数分かかる（検証した PC では 8〜9 分）
   - `RestartNeeded : False` と `State : Installed` が出ればよい
   - 既に入っていれば、すぐに `State : Installed` が出る

   <details>
   <summary>補足: 入るものと、PowerShell 7 で失敗すること</summary>

   - 入るのは Windows のオプション機能「OpenSSH サーバー」（設定アプリの「システム」→「オプション機能」と同じもの）。`C:\Windows\System32\OpenSSH\sshd.exe`（`OpenSSH_9.5p2 for Windows`）と、サービス `sshd`、受信の規則 `OpenSSH-Server-In-TCP` ができる
   - 入れた直後の `sshd` は `Stopped` / `Manual`。規則は `Enabled True`、`Profile Private`、TCP 22、接続元は `Any`、プログラムは `sshd.exe` に限られている
   - クライアント（`ssh.exe` など）は Windows 11 に最初から入っていて、この手順では変わらない。`ssh-agent` のサービスも `Disabled` のまま
   - Microsoft Store の PowerShell 7.6.6 の管理者のシェルでは、`Add-WindowsCapability` が約 4 分後に `クラスが登録されていません` で失敗し、`Get-WindowsCapability` も同じエラーになった。どちらも Dism モジュール（`C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\Dism`）のコマンド。Windows PowerShell 5.1 では通った
   - 先頭の `if` は、PowerShell 7（`PSEdition` が `Core`）で貼ったときに何もしないで止めるためのもの

   </details>

1. sshd を自動で起動するようにして起動し、待ち受けを確かめる。

   ```powershell
   Set-Service -Name sshd -StartupType Automatic
   Start-Service -Name sshd
   Get-Service -Name sshd | Format-Table Name, Status, StartType
   Get-NetTCPConnection -State Listen -LocalPort 22 | Format-Table LocalAddress, LocalPort, OwningProcess
   ```

   - `sshd  Running  Automatic` が出る
   - 22 番で `0.0.0.0` と `::` の 2 行が出ればよい

   <details>
   <summary>補足: 最初の起動で作られるもの</summary>

   - 最初に起動したときに、`C:\ProgramData\ssh` にホスト鍵 3 組（RSA・ECDSA・ED25519）と `sshd_config`、`logs` ができる。手順 3 の直後は、このディレクトリは空（1 回目）か、無かった（2 回目。ロールバックで消した後）
   - レジストリの `HKLM:\SOFTWARE\OpenSSH` も、手順 3 の直後には無く、この時点でできていた（値は無い）。[既定のシェルを Git Bash にする（任意）](#既定のシェルを-git-bash-にする任意)は、ここに値を足す

   </details>

1. LAN の接続をプライベートにし、sshd の受信の規則を確かめる。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '手順 2 の $LAN_IF が空'
   } else {
     Set-NetConnectionProfile -InterfaceAlias $LAN_IF -NetworkCategory Private
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
     Get-NetFirewallRule -Name OpenSSH-Server-In-TCP | Format-Table Name, Enabled, Profile, Direction, Action
   }
   ```

   - `<LAN_IF>  Private` と、`OpenSSH-Server-In-TCP  True  Private  Inbound  Allow` が出ればよい
   - 既にプライベートなら、何も変わらない
   - **注意**: プライベート向けのほかの許可の規則（ネットワーク探索など）も、この LAN で効くようになる（[選択した方針](#選択した方針)）

   <details>
   <summary>補足: プライベートにする理由</summary>

   - 手順 3 でできる規則は、プライベートのネットワークだけで有効。検証した PC の有線 LAN は「パブリック」だったので、そのままでは LAN からの SSH が捨てられる
   - WSL の AlmaLinux 10 から、この PC の LAN の IP（`<WIN_HOST>`）の 22/tcp につないで確かめた
     - パブリックのとき: 5 秒待っても応答が無い
     - プライベートにした後: すぐにバナー（`SSH-2.0-OpenSSH_for_Windows_9.5`）が返った
   - 検証した PC では、パブリックからプライベートにすると、それまで効いていなかった許可の規則 45 本がこの LAN で効くようになった。主なものは、ネットワーク探索（10 本）、リモート アシスタンス（4 本）、デバイス キャスト機能（3 本）。ファイルとプリンターの共有は無効のままだった
   - 規則の接続元は `Any` なので、LAN を通って届く別のサブネットの相手も受け付ける。検証した PC には、WireGuard のクライアントのアドレスからも入れた（[注意点](#注意点)）
   - パブリックのまま開ける方法（規則をパブリックにも広げる）は採らなかった（[選択した方針](#選択した方針)）

   </details>

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

   <details>
   <summary>補足: 既定でも有効なのに書く理由と、置き換える理由</summary>

   - 入れた直後の `sshd_config` の 51 行目は `#PasswordAuthentication yes`（コメント）で、パスワード認証は既定で有効。この手順はそれを明示的な行にするので、[パスワード認証を切る（任意）](#パスワード認証を切る任意)で `no` にした PC も、この手順を貼れば戻る
   - `sshd_config` の末尾は `Match Group administrators` のブロックなので、末尾に足した行はそのブロックの中の設定になる。そこで、既定の行を置き換える
   - `sshd -t` は設定の検査だけをする（誤りが無ければ何も出さない）。誤りがあれば再起動しないので、動いている sshd は古い設定のまま残る
   - 元の `sshd_config` は ASCII（BOM 無し、改行は CRLF）。Windows PowerShell 5.1 の `Set-Content -Encoding ascii` も CRLF で書く
   - パスワード認証を切ってあった PC でこの手順を貼ると、sshd が返す方法は `publickey,keyboard-interactive` から `publickey,password,keyboard-interactive` になった。Microsoft の文書は、Windows の OpenSSH の認証の方法は `password` と `publickey` だけとしている

   </details>

1. 接続先と、ホスト鍵の指紋を表示する。

   ```powershell
   '{0}@{1}' -f $env:USERNAME, (Get-NetIPAddress -InterfaceAlias $LAN_IF -AddressFamily IPv4).IPAddress
   & "$env:WINDIR\System32\OpenSSH\ssh-keygen.exe" -lf "$env:ProgramData\ssh\ssh_host_ed25519_key.pub"
   ```

   - 1 行目の `<WIN_USER>@<WIN_HOST>` が、手順 8 で使う値
   - 2 行目の `256 SHA256:<指紋> system@<HOSTNAME> (ED25519)` を、手順 9 の初回の接続で照合する
   - Microsoft アカウントでも、ユーザー名はメールアドレスではなく、`C:\Users\` の下のフォルダーの名前

   <details>
   <summary>補足: フルパスで呼ぶ理由</summary>

   - Git for Windows を入れた PC では、`PATH` の順によって、`ssh-keygen` が Git の `usr\bin\ssh-keygen.exe` になる。検証した PC では、ユーザーの `PATH` の先頭側に Git の `usr\bin` があり、`ssh`・`ssh-keygen`・`whoami` がどれも Git のものになった
   - Windows の OpenSSH のものを確実に使うため、`$env:WINDIR\System32\OpenSSH\` から呼ぶ

   </details>

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
   - **注意**: パスワードを続けて間違えると、Windows のロックアウトのポリシーでアカウントがロックされる（検証した PC は 10 回で 10 分。[注意点](#注意点)）
   - **後ろの節を貼るのは、`exit` でクライアントのシェルに戻ってから**（続けて貼ると Windows の cmd への入力として食われる）

   <details>
   <summary>補足: ログインした後のセッションと、Microsoft アカウント</summary>

   - `-o PubkeyAuthentication=no` は、クライアントの鍵を使わせずに、パスワードで入れることを確かめるため。[公開鍵でもログインする（任意）](#公開鍵でもログインする任意)で鍵を登録した後も、これを付ければパスワードを聞かれる
   - 既定のシェルは cmd.exe。sshd が `PROMPT` を `<ユーザー>@<ホスト名> <パス>>` の形にする
   - 指紋が手順 7 と違えば、`no` で止める。途中の経路で別の相手につながっている
   - Windows のイベント ビューアーの「アプリケーションとサービス ログ」→「OpenSSH」→「Operational」に、`sshd: Accepted password for <WIN_USER> from <IP> port <PORT> ssh2` が残る。PowerShell では `Get-WinEvent -LogName OpenSSH/Operational -MaxEvents 10`
   - 検証した PC のユーザーは Microsoft アカウントで、設定の「Windows Hello サインインのみを許可する」がオンのまま、そのアカウントのパスワードで入れた（[注意点](#注意点)）
   - ローカル アカウントの標準ユーザーでも、このブロックのまま（`WIN_USER` だけ直して）入れた。`whoami /groups` の `Mandatory Label` は `Medium Mandatory Level` だった

   </details>

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

   <details>
   <summary>補足: 鍵の種類とパスフレーズ</summary>

   - ED25519 にしたのは、Windows の sshd（OpenSSH 9.5p2）と AlmaLinux 10 の ssh（OpenSSH 9.9p1）のどちらも扱え、鍵が短く、この節の手順 3 で 1 行のまま貼れるため
   - パスフレーズは、秘密鍵のファイルが漏れたときの守り。空にすると、この節の手順 5 と[パスワード認証を切る（任意）](#パスワード認証を切る任意)の手順 2 で聞かれなくなる。後から付けるなら `ssh-keygen -p -f ~/.ssh/id_ed25519`
   - 秘密鍵（`~/.ssh/id_ed25519`）はクライアントから出さない。Windows に渡すのは、この節の手順 2 の公開鍵だけ

   </details>

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

   <details>
   <summary>補足: 鍵の置き場所とアクセス権</summary>

   - Windows の `sshd_config` の末尾には `Match Group administrators` と `AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys` がある。Administrators の一員のユーザーは、ホームの `.ssh\authorized_keys` ではなく、このファイルの鍵で認証される
   - Microsoft の文書は、このファイルのアクセス権を Administrators と SYSTEM だけにするよう求めている。`/inheritance:r` で `C:\ProgramData\ssh` から受け継ぐ `Authenticated Users` の読み取りなどを外し、2 つだけを付ける。アクセス権が違うときの sshd の振る舞いは、試していない
   - `icacls` にはグループを SID で渡した（`S-1-5-32-544` が Administrators、`S-1-5-18` が SYSTEM）。表示の言語に左右されないため
   - `-Encoding ascii` は、Windows PowerShell 5.1 の `Add-Content` が既定で使うコードページ（日本語版では Shift_JIS）で書かないため。公開鍵は ASCII の文字だけでできている
   - `Get-LocalGroupMember` は、Microsoft アカウントのユーザーも `<HOSTNAME>\<WIN_USER>` の名前で返した

   </details>

1. クライアントの PC で、鍵で入れることを確かめる。

   ```bash
   if [ -z "${WIN_HOST}" ] || [ -z "${WIN_USER}" ]; then echo '中断: 手順 8 の WIN_HOST か WIN_USER が空のまま' >&2; else
     ssh -o PasswordAuthentication=no "${WIN_USER}@${WIN_HOST}" whoami
   fi
   ```

   - パスワードを聞かれずに、`<hostname>\<win_user>` が出ればよい（パスフレーズを付けたなら、それを聞かれる）
   - 既定のシェルを Git Bash にした PC では、Git の `whoami` が動き、`<WIN_USER>` だけが出る

   <details>
   <summary>補足: 鍵で入ったときのログ</summary>

   - `-o PasswordAuthentication=no` は、鍵が通らなかったときにパスワードへ移らず、そこで終わらせるため
   - Windows のログには、`sshd: Accepted publickey for <WIN_USER> from <IP> port <PORT> ssh2: ED25519 SHA256:…` が残る

   </details>

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

   <details>
   <summary>補足: 切る前と後</summary>

   - 行を置き換える理由と `sshd -t` は、[手順 6](#実施手順) の補足と同じ
   - この手順の前は、`ssh -o PubkeyAuthentication=no` で `<WIN_USER>@<WIN_HOST>'s password:` と聞かれ、sshd が返す方法は `publickey,password,keyboard-interactive` だった。後は `publickey,keyboard-interactive`
   - 残る `keyboard-interactive` は、クライアントにパスワードを聞かずに、すぐ `Permission denied` で終わる（この節の手順 2 で確かめる）。Microsoft の文書は、Windows の OpenSSH の認証の方法は `password` と `publickey` だけで、`KbdInteractiveAuthentication` は使えないとしている

   </details>

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

   <details>
   <summary>補足: DefaultShell</summary>

   - `DefaultShell` は Windows の sshd だけの設定で、`sshd_config` ではなくレジストリに置く。この PC の全ユーザーの SSH のセッションに効く
   - `bin\bash.exe` は、Git の `usr\bin\bash.exe` を `MSYSTEM=MINGW64` と `PATH` を整えて起動する入口。コマンドの実行では、sshd が `"c:\program files\git\bin\bash.exe" -c "<コマンド>"` を起動していた（`DefaultShellCommandOption` は設定しなくてよかった）

   </details>

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

   <details>
   <summary>補足: Git Bash のセッション</summary>

   - 対話のログインでも、ログインシェルにはならない（`shopt login_shell` が off）。`~/.bash_profile` は読まれず、`~/.bashrc` は読まれる。プロンプトは Git の `/etc/bash.bashrc` の `PS1`
   - bash は、sshd から起動されたことを見分けて、`bash -c` のときも `~/.bashrc` を読む。検証した PC では、`~/.bashrc` の `eval "$(zoxide init bash)"` のエラーが、`ssh … <コマンド>` のたびに出た（原因と対処は[scoop のツールを SSH のセッションで使う（任意）](#scoop-のツールを-ssh-のセッションで使う任意)）
   - `PATH` は `/mingw64/bin:/usr/bin` の後ろに Windows の `PATH` が続き、`git` は `/mingw64/bin/git` になる。ホームは `/c/Users/<WIN_USER>`
   - `scp`（既定の SFTP の方式）、`scp -O`（旧来の方式。サーバー側では、`~/.bashrc` を読んだ bash の上で `scp` が動いた）、`sftp` の 3 つで、ファイルを送って消せた

   </details>

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
- 前提: scoop が `C:\Users\<WIN_USER>\scoop` に入っていること（[windows-setup.md 手順 3〜6](windows-setup.md#実施手順) で入れた形）
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

   <details>
   <summary>補足: RedirectionGuard と、作り直す理由</summary>

   - sshd には、IFEO（`HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\sshd.exe`）の `MitigationOptions` で RedirectionGuard が掛けてある（19 バイトの値の最後のバイトが `0x10`）。SYSTEM で動く sshd を、ジャンクションを使った攻撃から守るためのもので、本書では外さない
   - `GetProcessMitigationPolicy` で `ProcessRedirectionTrustPolicy` を見ると、sshd の 3 つのプロセスと、その下の bash・PowerShell はどれも `Enforce=1` で、`services.exe` とローカルのシェルは 0 だった
   - 信頼されるかどうかは、ジャンクションを作ったときに決まる
     - 同じ向き先で、一般ユーザーが作ったものは SSH のセッションから開けず（エラー 448）、管理者が作ったものは開けた
     - 一般ユーザーが作ったものの所有者を、後から Administrators に変えても開けなかった
   - そこで、一般ユーザーの所有のもの（= 一般ユーザーが作ったもの）だけを選び、管理者の PowerShell で消して作り直す。管理者が作ったものは所有者が `BUILTIN\Administrators` になるので、2 回目からは選ばれない
   - `cmd.exe /c rmdir` はジャンクションそのものだけを消し、向き先の中身には触れない。scoop が付けた読み取り専用の属性は、`attrib /L` で外してから消し、作り直した後に付け直す
   - Windows PowerShell 5.1 の `Get-ChildItem -Recurse` は、ジャンクションの中へは入らなかった（`current` を通った重複は出ない）
   - 管理者が作ったジャンクションも、一般ユーザーが消せた（ACL は `C:\Users\<WIN_USER>` から受け継ぐ）。scoop の更新の邪魔にはならない
   - 検証した PC では、`current` 39 個と persist（`nodejs\<版>\bin`・`python\<版>\Scripts` など）14 個の、53 個を作り直した。作り直した後も、向き先・読み取り専用の属性は前と同じだった

   </details>

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

- この節の手順 1〜3 は Windows の管理者の Windows PowerShell（手順 2 の変数を設定したもの）に、手順 4 はクライアントの手順 8 のシェルに貼る
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
   - 手順 5 の前からプライベートだったなら、この手順は飛ばす

1. クライアントの PC で、Windows のホスト鍵を `known_hosts` から消す。

   ```bash
   ssh-keygen -R "${WIN_HOST:?手順 8 の WIN_HOST が空のまま}"
   ```

   - `# Host <WIN_HOST> found: line N` が鍵の種類の数だけ出て、`… known_hosts updated.` で終わればよい
   - **注意**: 元の `known_hosts` は `~/.ssh/known_hosts.old` に写される。前からあった `known_hosts.old` は上書きされる

---

## 補足

### 対象と検証環境

- **目的**: LAN のほかの PC（AlmaLinux 10 など）から、Windows 11 の PC に SSH で入れるようにする
  - Windows のオプション機能「OpenSSH サーバー」を入れ、Windows のユーザーのパスワードで認証する
  - 受け付けるのは、プライベートにしたネットワークからだけ（手順 5）
  - 公開鍵での認証、パスワード認証を切る方法、ログインしたときのシェルを Git Bash にする方法、scoop のツールを SSH のセッションで使う方法は、任意節にした
- **進め方**: 値は、Windows では手順 2、クライアントでは手順 8 の変数に 1 度だけ書き、以降のコマンドをそのまま貼る
  - Windows の手順は管理者の Windows PowerShell に、クライアントの手順は bash に貼る
  - 読者が書き換えるのは、`WIN_HOST`（クライアント）だけ。公開鍵の任意節では `$PUBKEY`（Windows）も
- **状態**: **実機で本実行済み（2026-09-29・2026-09-30、同じ PC）。2026-09-29 は公開鍵を主にしていた版、2026-09-30 はパスワードを主にした今の版**
  - 2026-09-29（公開鍵が主の版。クライアントは同じ PC の WSL の AlmaLinux 10）:
    - x86_64 のノート PC（Windows 11 Pro 25H2）で、手順 1〜5・7・8、[公開鍵でもログインする（任意）](#公開鍵でもログインする任意)の手順 1〜4、[パスワード認証を切る（任意）](#パスワード認証を切る任意)の手順 1・2、Git Bash の任意節、ロールバックを通した
    - 当時は、手順 7 の後に鍵で対話のログインをしていた（今の手順 9 は、パスワードでのログインに変えた）
    - scoop の任意節は、その後に原因を調べて足し、同じ PC で通した
    - ロールバックで実施前の状態に戻した後、当時の文書から機械的に抜き出したブロックで、同じ範囲（ロールバックを除く）をもう 1 度通した
  - 2026-09-30 の朝（公開鍵が主の版のまま。[追加の確認の付録](#付録-追加の確認2026-09-30)）:
    - LAN の別の IP からの接続: 同じ PC の VirtualBox の VM を LAN にブリッジ接続し、ルーターの DHCP で別の IP を受け取った AlmaLinux 10.2 をクライアントにして、手順 8、当時の鍵での対話のログイン、[パスワード認証を切る（任意）](#パスワード認証を切る任意)の手順 2、Git Bash と scoop の任意節の手順 2、ロールバックの手順 4 を流した。Windows の設定は変えていない
    - Windows の再起動の後に、sshd が自動で起動したこと（2 回の起動のどちらも、起動の 30〜40 秒後に待ち受けを始めていた）
  - 2026-09-30 の 1 回目（今の版を、2026-09-29 の後の PC に適用）:
    - パスワード認証を切り、鍵を登録してあった PC に、手順 2・6 を流し、`PasswordAuthentication` を `no` から `yes` にした
    - 書き直した文書から抜き出した手順 2〜5・7 を流した（何も変わらなかった）。手順 6 の 2 回目は、スマートフォンのセッションが切れた後に流し、出力も `sshd_config` のハッシュも変わらなかった
    - パスワードでのログインは、利用者がスマートフォンの SSH のアプリから、WireGuard 越しに行った（Microsoft アカウントのパスワード）
  - 2026-09-30 の 2 回目（今の版を、実施前の状態から通した）:
    - `C:\ProgramData\ssh`（アクセス権ごと）と `HKLM:\SOFTWARE\OpenSSH`、WSL の `known_hosts` を控えてから、ロールバックの手順 1〜4 で実施前の状態にした
    - この文書から抜き出したブロックで、手順 2〜9、公開鍵の任意節の手順 1〜5、パスワード認証を切る任意節の手順 1・2、戻すための手順 6 を通した
    - 手順 8・9 は、試験用に作ったローカル アカウントの標準ユーザーで流した（`WIN_USER` を直した）。検証した PC のユーザー（Microsoft アカウント）のパスワードは、OpenSSH の `ssh` では流していない
    - 公開鍵の任意節は、WSL に作った試験用の Linux ユーザーで、パスフレーズ付きの鍵を新しく作って通した
    - 試験用のユーザーで、ロックアウトを確かめた
    - 最後に、控えからホスト鍵・登録した鍵・`DefaultShell`・`known_hosts` を戻し（ハッシュとアクセス権が控えと一致）、試験用のユーザーを消した（Windows のプロファイルのフォルダーは、読み込まれたまま外れず、残った。付録）
  - コードブロックは端末に貼らず、Claude Code から昇格した Windows PowerShell 5.1 と、WSL の bash に、手順ごとのスクリプトにして渡した。手順 1（PowerShell を開く）は、その形で代えた（付録）
  - 確認したこと:
    - 機能の導入（8〜9 分、再起動無し）、sshd の自動起動の設定と待ち受け
    - LAN の接続がパブリックのままでは LAN の IP あての接続が捨てられ、プライベートにすると通ること
    - 手順 6 の後の `sshd_config` が、既定の `sshd_config` から作っても、`no` にしてあったものから作っても、同じになること
    - パスワードでのログイン: ローカル アカウントの標準ユーザー（手順 8・9 のブロック、cmd）と、Microsoft アカウント（スマートフォンのアプリ。「Windows Hello サインインのみを許可する」がオンのまま）。WireGuard のクライアントのアドレスからの接続
    - 公開鍵でのログイン（cmd と Git Bash、パスフレーズ付きの鍵を新しく作る流れも）、ホスト鍵の指紋の照合、パスワード認証を切った後に `Permission denied` ですぐ終わること、手順 6 で戻ること
    - Administrators の一員のセッションは High Mandatory Level（2026-09-29 に確かめた）、標準ユーザーのセッションは Medium Mandatory Level
    - ロックアウト: ローカル アカウントでは、SSH のパスワードの失敗も数えられ、10 回目でロックされること
    - Windows の再起動の後に sshd が自動で起動すること（利用者が 2 回起動し直したときのログ）
    - Git Bash での `git`・`scp`・`scp -O`・`sftp`、`DefaultShell` を消すと cmd に戻ること
    - SSH のセッションで scoop のツールが起動しない原因（sshd の RedirectionGuard）と、ジャンクションを管理者で作り直すと起動すること（scoop の任意節。一般ユーザーで作り直して壊した状態から、この文書のブロックで直した）
    - ロールバックの後に残るもの（`C:\ProgramData\ssh` とレジストリのキー）と、消した後に入れ直せること
    - 変数が空のとき・PowerShell 7 で貼ったときに、手順 3、公開鍵の任意節の手順 4、パスワード認証を切る任意節の手順 2、ロールバックの手順 4 が何も変えずに止まること
  - **確認していないこと**:
    - Microsoft アカウントのパスワードで、手順 8・9 のブロック（OpenSSH の `ssh`）から入ること
    - LAN の別の PC（実機）から、この文書の手順で入ること（LAN の別の IP からは、同じ PC の VM から、2026-09-29 の版の手順で鍵で入った。[付録](#付録-追加の確認2026-09-30)。WSL からの接続は、sshd には送信元がこの PC の LAN の IP として届いた。[注意点](#注意点)）
    - 端末に貼る操作そのもの（PowerShell の PSReadLine での複数行の貼り付け、bash の対話の入力）
    - 標準ユーザーの鍵での認証（`authorized_keys`）、既定の UAC の設定での振る舞い
    - Microsoft アカウントのロックアウト
    - Windows Update での OpenSSH の更新
  - 実測の記録は[付録（2026-09-29）](#付録-実機での検証記録2026-09-29)、[追加の確認の付録（2026-09-30）](#付録-追加の確認2026-09-30)、[パスワード認証の付録（2026-09-30）](#付録-パスワード認証の検証記録2026-09-30)

下表は実機で採取した値。

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-29、2026-09-30 |
| PC | x86_64 のノート PC（AMD Ryzen AI MAX+ 395） |
| OS | Windows 11 Pro 25H2（ビルド 26200.9457、日本語） |
| PowerShell | Windows PowerShell 5.1.26100.9444（手順で使う）/ PowerShell 7.6.6（Microsoft Store 版。手順 3 が失敗した） |
| OpenSSH | オプション機能 `OpenSSH.Server~~~~0.0.1.0`（`OpenSSH_9.5p2 for Windows`）。クライアントは同じ版が最初から入っていた |
| Git for Windows | 2.55.0.windows.3（GNU bash 5.3.15） |
| ユーザー | Microsoft アカウント。Administrators の一員。「Windows Hello サインインのみを許可する」がオン（`DevicePasswordLessBuildVersion` が 2） |
| UAC | 有効。管理者は確認無しで昇格する設定（`ConsentPromptBehaviorAdmin` が 0） |
| アカウントのロックアウト | `net accounts` で、10 回の失敗で 10 分（観測期間 10 分） |
| ネットワーク | 有線 LAN 1 本（IPv4、/24）。2026-09-29 の手順の前はパブリック |
| クライアント（2026-09-29） | 同じ PC の WSL 2.7.13.0（カーネル 6.18.33.2-microsoft-standard-WSL2、既定の NAT）の AlmaLinux 10.2。`openssh-clients-9.9p1-23.el10_2.alma.1` |
| クライアント（2026-09-30） | 1 回目のパスワード: スマートフォンの SSH のアプリ（WireGuard のクライアント）。ほかは上と同じ WSL（公開鍵の任意節は、WSL に作った試験用の Linux ユーザー） |
| 試験用のユーザー（2026-09-30） | Windows のローカル アカウントの標準ユーザー（`Users` だけ）。WSL の Linux ユーザー。どちらも検証の後に消した（Windows のプロファイルのフォルダーは残った） |

> [!NOTE]
> 環境固有の値は**変数**で書いてある。Windows では手順 2 の PowerShell の変数に、クライアントでは手順 8 のシェル変数に 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 設定する場所 | 意味 | 例 |
> |---|---|---|---|
> | `$LAN_IF` | Windows（手順 2） | クライアントとつながる LAN の接続の名前（自動で入る） | `イーサネット` |
> | `${WIN_HOST}` | クライアント（手順 8） | Windows の LAN の IP アドレス | `192.168.1.30` |
> | `${WIN_USER}` | クライアント（手順 8） | Windows のユーザー名（既定はクライアントのユーザー名） | `${USER}` |
> | `$PUBKEY` | Windows（公開鍵の任意節の手順 3） | クライアントの公開鍵の 1 行 | `ssh-ed25519 AAAA… <USER>@<HOSTNAME>` |
>
> 出力例・ログ・表の中の値は `<WIN_HOST>` / `<WIN_USER>` / `<HOSTNAME>`（Windows のコンピューター名）/ `<hostname>` と `<win_user>`（`whoami` が小文字で出すもの）/ `<LAN_IF>` / `<USER>`（クライアントのユーザー名）/ `<IP>` / `<PORT>` のプレースホルダで書いてある。
>
> パスワードと秘密鍵はこの文書に載せない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

実機で、2026-09-29 に手順 1 の前に確かめた状態:

| 項目 | 状態 |
|---|---|
| OpenSSH サーバー | 未導入（サービス `sshd` が無く、`Get-WindowsCapability` は `NotPresent`） |
| OpenSSH クライアント | `C:\Windows\System32\OpenSSH` に 9.5p2。サービス `ssh-agent` は `Disabled` |
| `C:\ProgramData\ssh` | 空 |
| `HKLM:\SOFTWARE\OpenSSH` | 無し |
| 受信の規則 | 名前に ssh を含むものは無し |
| 22/tcp | 待ち受け無し |
| LAN の接続 | `<LAN_IF>`。パブリック |
| リモート デスクトップ | 有効（規則はすべてのプロファイル）。本書では変えない |
| `PATH` | ユーザーの `PATH` の先頭側に Git の `usr\bin` があり、`ssh`・`ssh-keygen`・`whoami` は Git のものが動く |
| WSL | `AlmaLinux-10`（停止中）。`~/.ssh/id_ed25519`（パスフレーズ無し）が前からあった |

- 2026-09-30 の 1 回目は、[完了時点の状態](#完了時点の状態)の PC（`PasswordAuthentication no`、鍵を 1 つ登録、既定のシェルは Git Bash、LAN はプライベート）から始めた
- 2026-09-30 の 2 回目は、ロールバックの手順 1〜4 の後に、上の表の OpenSSH サーバー・`C:\ProgramData\ssh`・`HKLM:\SOFTWARE\OpenSSH`・受信の規則・22/tcp・LAN の接続（パブリック）が同じ状態になったことを確かめてから始めた（`C:\ProgramData\ssh` は空ではなく、無かった）

### 選択した方針

- **Windows のオプション機能（Feature on Demand）で入れる**
  - `Add-WindowsCapability` の 1 つで、サービス・受信の規則・既定の `sshd_config` がそろう
  - Microsoft の文書は、Windows Update で保守されるこの版を、ほとんどの場合に勧めている
  - GitHub の Win32-OpenSSH（winget の `Microsoft.OpenSSH.Preview`）は新しい版を使えるが、本書では試していない
- **パスワードで認証し、公開鍵は任意節にした**（手順 6 でパスワード認証を明示的に有効にする）
  - クライアントで鍵を作って Windows に登録しなくても、Windows のユーザーのパスワードだけで入れる。鍵を扱いにくいクライアント（スマートフォンのアプリなど）からも入れる
  - 受け付けるのは、プライベートにしたネットワークから届く接続だけ（手順 5）
  - パスワードの総当たりへの備えは、Windows のアカウントのロックアウトのポリシー（検証した PC は 10 回で 10 分）。ローカル アカウントでは、SSH での失敗も数えられ、10 回目でロックされた
  - 鍵で入れるようにしたら、パスワード認証を切れる（[パスワード認証を切る（任意）](#パスワード認証を切る任意)）。2026-09-29 の版は、この形（公開鍵だけ）を主にしていた
- **LAN の接続をプライベートにし、規則は変えない**
  - 機能が作る規則は、プライベートのネットワークだけで有効。家の LAN をプライベートにすれば、規則を変えずに LAN から入れる
  - 持ち出した先のパブリックの Wi-Fi では、閉じたままになる
  - 規則をパブリックにも広げる（接続元を同じサブネットに絞る）方法は採らなかった。持ち出した先でも、同じサブネットの相手に開くため
  - プライベートにすると、プライベート向けのほかの規則（ネットワーク探索など）もこの LAN で効く（手順 5 の補足）
- **Windows PowerShell 5.1 で貼る**
  - Microsoft Store の PowerShell 7 では、手順 3 の Dism のコマンドが失敗した
  - ほかの手順（NetSecurity などのコマンド）もこのシェルにそろえ、1 つの PowerShell で通せるようにした
- **公開鍵の任意節では、ED25519 の鍵をクライアントで作る**: 秘密鍵をクライアントから出さない。Windows に渡すのは公開鍵の 1 行だけ
- **既定のシェルは任意節にした**: 既定の cmd.exe でも使える。Git Bash にすると、Linux のクライアントからシェルの道具と `git` をそのまま使える

### 完了時点の状態

実機で、2026-09-29 の 2 回目の通し（既定のシェルを Git Bash にした状態）の後に確かめた状態。この後に、scoop の任意節で scoop のジャンクションを作り直した:

```
PS> Get-Service sshd, ssh-agent | Format-Table Name, Status, StartType
Name       Status StartType
----       ------ ---------
ssh-agent Stopped  Disabled
sshd      Running Automatic

PS> Get-NetConnectionProfile | Format-Table InterfaceAlias, NetworkCategory
InterfaceAlias NetworkCategory
-------------- ---------------
<LAN_IF>               Private

PS> Get-NetFirewallRule -Name OpenSSH-Server-In-TCP | Format-Table Name, DisplayName, Enabled, Profile, Direction, Action
Name                  DisplayName               Enabled Profile Direction Action
----                  -----------               ------- ------- --------- ------
OpenSSH-Server-In-TCP OpenSSH SSH Server (sshd)    True Private   Inbound  Allow

PS> Get-NetFirewallRule -Name OpenSSH-Server-In-TCP | Get-NetFirewallApplicationFilter | Format-List Program
Program : %SystemRoot%\system32\OpenSSH\sshd.exe

PS> Get-ItemProperty HKLM:\SOFTWARE\OpenSSH | Format-List DefaultShell
DefaultShell : C:\Program Files\Git\bin\bash.exe

PS> Get-ChildItem C:\ProgramData\ssh -Force | Format-Table Mode, Length, Name
Mode  Length Name
----  ------ ----
d----        logs
-a--- 98     administrators_authorized_keys
-a--- 505    ssh_host_ecdsa_key
-a--- 178    ssh_host_ecdsa_key.pub
-a--- 411    ssh_host_ed25519_key
-a--- 98     ssh_host_ed25519_key.pub
-a--- 2602   ssh_host_rsa_key
-a--- 570    ssh_host_rsa_key.pub
-a--- 2295   sshd_config
-a--- 6      sshd.pid
```

- 管理者でない PowerShell からは、`icacls C:\ProgramData\ssh\administrators_authorized_keys` が `Access is denied.` になった（公開鍵の任意節の手順 4 のアクセス権が効いている）
- `sshd_config` は、既定の 2297 バイトから、パスワード認証を切る任意節の手順 1 の 1 行の置き換えで 2 バイト減った
- 2026-09-30 に手順 6 を流した後は、`sshd_config` の 51 行目が `PasswordAuthentication yes` になり、2296 バイト（既定から 1 バイト減）になった。ほかは上と同じ（`sshd.pid` だけ、プロセス ID の桁が増えて 7 バイト。[付録（2026-09-30）](#付録-パスワード認証の検証記録2026-09-30)）
- 2026-09-30 の 2 回目の通しの後は、控えから `C:\ProgramData\ssh` と `DefaultShell` を戻したので、1 回目の後と同じ状態（ファイルのハッシュとアクセス権が一致）

### 注意点

- **SSH のセッションは管理者の権限を持つ**
  - Administrators の一員でログインすると、`whoami /groups` で `Mandatory Label\High Mandatory Level` と、有効な `BUILTIN\Administrators` が出た。cmd のウィンドウのタイトルも `管理者: …` になる
  - このユーザーのパスワードを知る人と、登録した鍵を持つ人は、この PC の管理者として操作できる。パスワードと秘密鍵の扱いは、管理者のパスワードと同じにする
  - 検証した PC の UAC は、管理者が確認無しで昇格する設定だった。既定の UAC での振る舞いは確かめていない
- **パスワードでのログイン**
  - ユーザー名は、Microsoft アカウントでもメールアドレスではなく、`C:\Users\` の下のフォルダーの名前（手順 7）。パスワードは、そのアカウントのパスワード（PIN ではない）
  - 検証した PC では、設定の「セキュリティ向上のため、このデバイスでは Microsoft アカウント用に Windows Hello サインインのみを許可する」がオンのまま、Microsoft アカウントのパスワードで入れた
  - この設定がオンだと、Microsoft アカウントのパスワードが sshd のログにエラー 1326 を残して拒否され、オフにして sshd を再起動すると通った、という報告がある（[参照](#参照)の Q&A）。検証した PC では起きなかった
- **パスワードを続けて間違えたとき**（ローカル アカウントの標準ユーザーで試した）
  - 検証した PC のロックアウトのポリシーは、10 回の失敗で 10 分（`net accounts`）
  - SSH のパスワードの失敗も、1 回ずつセキュリティのログのイベント 4625（ログオンの種類 8、プロセスは `sshd.exe`）として数えられ、10 回目でロックされた（イベント 4740）
  - ロック中は、正しいパスワードでも入れない。パスワードを聞かれる前に `Connection reset by <WIN_HOST> port 22` で切られ、sshd のログにも残らなかった
  - ロックは 10 分で解け、正しいパスワードで入れた
  - ほかのユーザーの接続には影響しなかった。Microsoft アカウントのロックアウトは試していない
- **鍵で入ったセッションは、ユーザーの資格情報を持たない**（Microsoft の文書）。セッションの中から、そのユーザーとしてほかのサーバーの共有などへ認証できない。本書では、鍵でもパスワードでも試していない
- **標準ユーザーでログインするとき**
  - パスワードの認証を有効にすると、Administrators の一員でないユーザーも、パスワードがあれば SSH で入れる。ローカル アカウントの標準ユーザーで、手順 8・9 のとおりに入れた
  - 標準ユーザーのセッションは `Medium Mandatory Level` で、管理者の権限を持たない
  - 標準ユーザーの鍵は `C:\Users\<ユーザー>\.ssh\authorized_keys` に置く（Microsoft の文書）。本書では試していない。公開鍵の任意節の手順 4 は、Administrators の一員でなければ止まる
- **LAN の外のサブネットからの接続**
  - 規則の接続元は `Any` で、プロファイルは接続を受けた LAN で決まる。LAN を通って届く接続なら、送信元が別のサブネットでも受け付ける
  - 検証した PC には、[WireGuard VPN](wireguard.md) のクライアントのアドレスから、パスワードで入れた
- **WSL から、この PC につなぐとき**: この PC の LAN の IP（`<WIN_HOST>`）あてにつなぐ
  - WSL の既定の NAT では、WSL の既定の経路の先（`vEthernet (WSL (Hyper-V firewall))` の IP）あての接続は、パブリックとして判定され、手順 5 の後も捨てられた
  - LAN の IP あての接続は、sshd には送信元がこの PC の LAN の IP として届き、LAN のプロファイル（プライベート）で判定された
- **Git の ssh が先に見つかる PC**: `PATH` の順で、Windows の `ssh`・`ssh-keygen` ではなく Git のものが動く。Windows の OpenSSH のものは `C:\Windows\System32\OpenSSH\` から呼ぶ（手順 7）
- **SSH のセッションでは、一般ユーザーが作ったジャンクションをたどれない**
  - sshd に掛けてある RedirectionGuard を、セッションのプロセスが引き継ぐため。開こうとすると、エラー 448（`ERROR_UNTRUSTED_MOUNT_POINT`）になる
  - 検証した PC では、scoop の `current` を通る `zoxide.exe` と `python.exe` が Git Bash から `Is a directory` になり、scoop の shim は `Could not create process with command …` で失敗した。`PATH` のうち scoop の 7 つのディレクトリも開けなかった
  - ローカルのシェルは、昇格していても RedirectionGuard が掛かっておらず、影響を受けない
  - scoop のジャンクションは、[scoop のツールを SSH のセッションで使う（任意）](#scoop-のツールを-ssh-のセッションで使う任意)で、管理者で作り直せば通る。scoop 以外のツールのジャンクションも、同じ理由で通らないはず（試していない）
- **設定を変えたとき**: `sshd_config` を変えたら `Restart-Service sshd`（手順 6）。レジストリの `DefaultShell` は、再起動しなくても次のログインから効いた
- **機能を外したとき**
  - Microsoft の文書は、使っている間に外したなら Windows を再起動するよう書いている
  - 検証では、`Remove-WindowsCapability` は `RestartNeeded : False` を返し、再起動せずに入れ直せた
- **ログ**: イベント ビューアーの「OpenSSH」→「Operational」（手順 9 の補足）

### 参照

- [Get started with OpenSSH Server for Windows](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse)（`Add-WindowsCapability`、サービスの起動、規則 `OpenSSH-Server-In-TCP`、外し方）
- [Key-Based Authentication in OpenSSH for Windows](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement)（`administrators_authorized_keys` とアクセス権、SID で書く `icacls`、標準ユーザーの `authorized_keys`、鍵で入ったセッションの資格情報）
- [OpenSSH Server Configuration for Windows](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh-server-configuration)（`DefaultShell`、`AuthorizedKeysFile`、使える認証の方法、Windows で使えない設定）
- [Unable to log into SSH server using Microsoft account](https://learn.microsoft.com/en-us/answers/questions/1332375/unable-to-log-into-ssh-server-using-microsoft-acco)（Microsoft Q&A。Microsoft アカウントのパスワードがエラー 1326 で拒否された例と、「Windows Hello サインインのみ」をオフにする回避策）
- [Win32-OpenSSH の wiki](https://github.com/PowerShell/Win32-OpenSSH/wiki)
- `Get-Help Add-WindowsCapability` / `Get-Help Set-NetConnectionProfile` / `Get-Help New-ItemProperty`
- [WireGuard Road Warrior 設定手順](wireguard-road-warrior.md)（別の PC からの接続を外出先に広げるとき。本書では試していない）

---

### 付録: 実機での検証記録（2026-09-29）

この付録の手順番号は、今の番号に付け替えてある。「鍵の節」は[公開鍵でもログインする（任意）](#公開鍵でもログインする任意)、「切る節」は[パスワード認証を切る（任意）](#パスワード認証を切る任意)のこと。「当時の手順 12」は、手順 7 の後に鍵で対話のログインをしていた手順（今の文書には無い）。

**流し方**:

- Windows の手順は、ブロックを UTF-8（BOM 付き）の `.ps1` にし、Claude Code の PowerShell から `sudo powershell.exe -NoProfile -ExecutionPolicy Bypass -File <ファイル>` で 1 手順ずつ実行した
  - Windows の `sudo` はインラインのモードで、UAC は確認無しで昇格する設定
  - 各 `.ps1` の先頭に、変数のブロック（今の手順 2 と、鍵の節の手順 3。当時は 1 つの手順）を付けた。同じ PowerShell に貼り続けたときと同じ変数にするため
  - `$PUBKEY` は、`''` の中だけを鍵の節の手順 2 の出力に置き換えた
- クライアントの手順は、`wsl.exe -d AlmaLinux-10 --exec bash <スクリプト>` で実行した
  - 手順 8 は、`WIN_HOST=` の後ろだけを書き換えた
  - 当時の手順 12 と Git Bash の任意節の手順 2 の対話は、`script` の擬似端末に `yes`・`whoami`・`exit` を流し込んだ
- 2 回目は、この文書の `powershell` と `bash` のブロックを順に抜き出したファイルを、上の置き換えだけで使った

**1 回目**（下書きのブロック）:

- 手順 3 は、最初に Microsoft Store の PowerShell 7.6.6 で流し、266 秒後に `Add-WindowsCapability` と `Get-WindowsCapability` が `クラスが登録されていません` で失敗した。状態は `NotPresent` のまま
- Windows PowerShell 5.1 で流し直すと、532 秒で `State : Installed`（`RestartNeeded : False`）になった
- 手順 4・5、鍵の節の手順 4、切る節の手順 1、手順 7、当時の手順 12、切る節の手順 2、Git Bash の任意節の手順 1・2 を通した。ホスト鍵の指紋は、手順 7 と、クライアントの `ssh-keygen -lF <WIN_HOST>` で一致した
- ロールバックの手順 1〜4 で、実施前の状態に戻した。`Remove-WindowsCapability` は 6 秒、`RestartNeeded : False`
  - 外した直後に残っていたもの: `C:\ProgramData\ssh` の全ファイル（ホスト鍵・`sshd_config`・`administrators_authorized_keys`）と、`HKLM:\SOFTWARE\OpenSSH` の `DefaultShell`
  - 消えていたもの: サービス `sshd`、`sshd.exe`、規則 `OpenSSH-Server-In-TCP`

**2 回目**（この文書のブロック）:

- 先に、何も変えずに止まるかを確かめた
  - PowerShell 7 で手順 3: `Write-Error: Windows PowerShell（5.1）で貼る。…`
  - `$PUBKEY` が空のまま鍵の節の手順 4: `手順 3 の $PUBKEY が空か、公開鍵の形でない`（`C:\ProgramData\ssh` はできなかった）
- 手順 3 は 486 秒。導入の直後は、`C:\ProgramData\ssh` も `HKLM:\SOFTWARE\OpenSSH` もまだ無く、手順 4 で sshd を起動した後にできた
- 鍵の節の手順 4 の後・切る節の手順 1 の前に、パスワードを聞かれることと、セッションが High Mandatory Level であることを確かめた（ホスト鍵は `UserKnownHostsFile=/dev/null` で、`known_hosts` に残さなかった）
- 切る節の手順 1 は 2 回流し、`PasswordAuthentication` の行が 1 行のままだった
- 当時の手順 12 で、初回の `ED25519 key fingerprint is SHA256:…` が手順 7 と一致し、`yes` の後に cmd のプロンプトになった
- Git Bash の任意節は、手順 1 → 2 → 3（cmd に戻る）→ 1 の順に流し、Git Bash の状態で終えた
- `WIN_HOST` が空のまま、切る節の手順 2 とロールバックの手順 4 のブロックを流し、どちらも何もしないで止まった

**切り分け: WSL から届かなかった接続**:

- 最初に使った試験の誤り
  - `/dev/tcp` でつなぎ、バナーを `head -c 40` で読んでいた
  - Windows の sshd のバナー（`SSH-2.0-OpenSSH_for_Windows_9.5` と CRLF で 33 バイト）の後は、クライアントを待つ。40 バイトがそろわず、つながっていても 5 秒のタイムアウトになった
  - このため、しばらく「どの規則を足しても届かない」と見誤った
- `read -t 5` で 1 行を読む形に直して、測り直した

  | LAN の接続 | 規則 | `<WIN_HOST>`（LAN の IP）あて | WSL の既定の経路の先の IP あて |
  |---|---|---|---|
  | パブリック | 機能の規則だけ | 届かない | 届かない |
  | プライベート | 機能の規則だけ | 届く | 届かない |
  | プライベート | WSL の範囲（`172.25.32.0/20`）からの 22/tcp を許す一時的な規則（パブリック） | 届く | 届く |

- 捨てていたのは、WFP の `Query User` のフィルター（層は `FWPM_LAYER_ALE_AUTH_RECV_ACCEPT_V4`、条件は `FWPM_CONDITION_ORIGINAL_PROFILE_ID` が 1）
  - `netsh wfp show netevents localport=22` のドロップの記録と、`netsh wfp show filters` で突き合わせた
  - 機能の規則（プライベート）から作られたフィルターの条件は、プロファイル ID が 2
- sshd のログ（`OpenSSH/Operational`）では、WSL から LAN の IP あての接続の送信元は `<WIN_HOST>` だった
- 一時的な規則（`Verify-WSL-sshd`）は、確かめた後に消した
- 途中で、どのプロファイルでも有効なブロックの規則が 1 つ見つかった。別のソフトが作ったもので、特定のローカルユーザーのプロセスだけに効き、SYSTEM で動く sshd には関係しなかった

**切り分け: SSH のセッションで scoop のツールが起動しない**（2 回目の後）:

- 症状
  - Git Bash の既定のシェルで、`ssh … <コマンド>` のたびに `Shim: Could not create process with command '"C:\Users\<WIN_USER>\scoop\apps\zoxide\current\zoxide.exe"  init bash'.` が出た
  - SSH のセッションの `cmd /c dir …\zoxide\current\zoxide.exe` は `ファイルが見つかりません`。Git Bash の `ls -la …\zoxide\current\` は、名前は出るものの、どれもディレクトリで日付が 1601 年の、壊れた属性で出た
  - ローカルのシェルでは、昇格していてもいなくても、`current` を通して動いた
- SSH のセッションの PowerShell で `CreateFileW` を呼ぶと、`…\zoxide\current\zoxide.exe` はエラー 448（`信頼されていないマウントポイントが含まれているため、パスをスキャンできません。`）、`…\zoxide\0.9.9\zoxide.exe` は成功した
- 同じ PowerShell から、自分と親のプロセスの `GetProcessMitigationPolicy(ProcessRedirectionTrustPolicy)` を順にたどった
  - PowerShell・bash 2 つ・sshd 3 つは `flags=0x1`（Enforce）、`services.exe`・`wininit.exe` は `0x0`
  - ローカルの PowerShell は `0x0`
  - IFEO の `sshd.exe` に `MitigationOptions`（19 バイト、最後が `0x10`）があった
- 信頼の判定を試した（向き先はどれも `…\zoxide\0.9.9`）

  | ジャンクション | 所有者 | SSH のセッションから開く |
  |---|---|---|
  | 一般ユーザーの PowerShell で作った | `<HOSTNAME>\<WIN_USER>` | エラー 448 |
  | 管理者の PowerShell（`sudo`）で作った | `BUILTIN\Administrators` | 開けた |
  | 一般ユーザーで作り、管理者で所有者を Administrators に変えた（`icacls /setowner … /L`） | `BUILTIN\Administrators` | エラー 448 |

- SSH のセッションで `PATH` の各ディレクトリを開くと、scoop の `current` を通る 7 つがエラー 448 だった（ほかに、ローカルにも無い WinGet のパスが 1 つ、エラー 2）
- 対処
  - 作り直す処理を一時的なジャンクションで試し、向き先の中身が残ること、読み取り専用の属性が戻ること、2 回目は何もしないこと、一般ユーザーが後から消せることを確かめた
  - scoop の 53 個を作り直し、作り直す前に控えた一覧と、向き先・属性が一致した
  - SSH のセッションで `zoxide`・`rg`・`fd`・`nvim`・`gh`・`jq`・`lazygit`・`node`・`python` が動き、`Shim:` の行は出なくなった。`PATH` の scoop の 7 つも開けた
  - 最後に、`zoxide` の `current` を一般ユーザーで作り直して壊し、[scoop のツールを SSH のセッションで使う（任意）](#scoop-のツールを-ssh-のセッションで使う任意)の 2 つのブロックをそのまま流して、直ることを確かめた（手順 1 は 1 行を出し、2 回目は何も出さなかった）

**残っている未確認事項**:

1. LAN の別の PC（AlmaLinux 10）からの接続。送信元が LAN の別の IP になる接続は、まだ流していない
1. 端末に貼る操作そのもの（Windows PowerShell 5.1 の PSReadLine での複数行の貼り付け、`if … else` のブロック）
1. パスフレーズ付きの鍵と、鍵の節の手順 1 で鍵を新しく作る流れ
1. 標準ユーザーの `authorized_keys`、パスワード（Microsoft アカウント）でのログイン
1. 既定の UAC の設定で、SSH のセッションが High Mandatory Level になるか
1. Windows の再起動の後に sshd が自動で起動するか、Windows Update での OpenSSH の更新
1. `scoop update` の後に、更新したアプリが SSH のセッションで起動しなくなり、scoop の任意節の手順 1 で直ること（理屈の上ではそうなるが、実際の更新では試していない）

---

### 付録: 追加の確認（2026-09-30）

前の付録の「残っている未確認事項」のうち、1（LAN の別の IP からの接続）と 6 の前半（再起動の後の自動起動）を、同じ PC で確かめた。Windows の設定（`sshd_config`・登録した鍵・規則・ネットワークのプロファイル）は変えていない。このときの文書は公開鍵が主の版（2026-09-29 の版）で、この付録の手順の番号は今の版に付け替えた。今の版に同じコマンドが無いものは、当時の番号で書いた。

**再起動の後の自動起動**:

- 手順を通した後（2026-09-29 の 13:40）に、Windows は 2 回起動し直していた（システムのイベント ログの `Microsoft-Windows-Kernel-General` の ID 12 で、2026-09-30 の 1:29:00 と 1:43:45）
- `OpenSSH/Operational` の `sshd: Server listening on 0.0.0.0 port 22.` と `sshd: Server listening on :: port 22.` が、1:29:41 と 1:44:18 にあった（起動の 41 秒後と 33 秒後。手では起動していない）
- `Get-Service sshd` は `Running`・`Automatic` で、WSL の AlmaLinux 10 から `<WIN_HOST>` に鍵でログインでき、Git Bash のセッションになった
- 管理者でない PowerShell からは、sshd のプロセスの開始時刻と `C:\ProgramData\ssh\ssh_host_ed25519_key.pub` は読めなかった（`ssh-keygen -lf` は `Permission denied`）。`OpenSSH/Operational` とシステムのイベント ログは読めた

**LAN の別の IP からの接続**:

- クライアント: 同じ PC の VirtualBox 7.2.20 の VM の AlmaLinux 10.2（Atomic Desktop、`openssh-clients-9.9p1`。[virtualbox-guest-bootc.md の付録](virtualbox-guest-bootc.md#付録-windows-のホストの-virtualbox-の-vm-での本実行2026-09-30)の VM）
  - VM のネットワークを、動かしたまま NAT から有線 LAN のアダプターへのブリッジ接続に切り替えた（`VBoxManage controlvm <VM> nic1 bridged <アダプター>`）
  - VM の NetworkManager が DHCP で取り直し、ルーターから `<VM_IP>`（`<WIN_HOST>` と同じサブネットの別の IP）を受け取った
- 鍵: VM に秘密鍵を置かず、WSL の `ssh-agent` に前からの鍵（`administrators_authorized_keys` に登録済み）を載せ、WSL から VM へエージェントを転送して入った
  - VM の `~/.ssh` には鍵が無いので、当時の手順 12（鍵での対話のログイン）などの ssh は、転送されたエージェントの鍵で認証される
- 流し方: WSL の tmux の擬似端末から VM に入り、この文書の `bash` のブロックを抜き出したものを、ブラケットペーストで貼った
  - 手順 8 は、`WIN_HOST=` の後ろを書き換えた。`WIN_USER` は、VM のユーザー名が Windows と違うので、手順 8 のとおり `<WIN_USER>` に直した
- この PC は、Git Bash の任意節（`DefaultShell`）と scoop の任意節を通した状態だった

| 手順 | 結果 |
|---|---|
| 8 | `WIN_HOST = <WIN_HOST>`、`WIN_USER = <WIN_USER>` |
| 当時の 12（今の手順 9 から `-o PubkeyAuthentication=no` を除いた、鍵での対話のログイン） | `ED25519 key fingerprint is SHA256:<指紋>.`（WSL の `ssh-keyscan -t ed25519 <WIN_HOST> \| ssh-keygen -lf -` と一致）→ `yes` → `<WIN_USER>@<HOSTNAME> MINGW64 ~` のプロンプト。`whoami` は `<win_user>`、`echo "$SSH_CONNECTION"` は `<VM_IP> <PORT> <WIN_HOST> 22` |
| パスワード認証を切る 2 | パスワードを聞かずに `<WIN_USER>@<WIN_HOST>: Permission denied (publickey,keyboard-interactive).`、2 つ目は `<win_user>` |
| Git Bash の任意節 2 | `5.3.15(1)-release MINGW64`、`git version 2.55.0.windows.3`、対話のプロンプト → `exit` |
| scoop の任意節 2 | `zoxide 0.9.9`（`Shim:` の行は無い） |
| ロールバック 4 | `# Host <WIN_HOST> found: line 1`〜`3`（ED25519・RSA・ECDSA。ssh がログインの後にほかのホスト鍵も `known_hosts` に足していた）、`… known_hosts updated.`、`Original contents retained as …/known_hosts.old` |

- Windows の `OpenSSH/Operational` には、`sshd: Accepted publickey for <WIN_USER> from <VM_IP> port <PORT> ssh2: ED25519 SHA256:…` が残った（送信元は、この PC の LAN の IP ではなく、VM の IP）
- LAN の接続はプライベートのままで、規則 `OpenSSH-Server-In-TCP`（プライベート）で通った
- `OpenSSH/Operational` の `Accepted publickey` のうち、LAN の別の IP からのものは、この確認の 2 分間の 5 件だけだった。[パスワード認証の付録](#付録-パスワード認証の検証記録2026-09-30)の未確認事項の「利用者の公開鍵での接続は、LAN の別の IP からもログに残っていた」は、この確認の接続
- 終わった後に、VM を NAT に戻し、WSL の `ssh-agent` を止めた

**残っている未確認事項**:

1. LAN の別の PC（実機）からの接続（今回は同じ PC の VM から確かめただけ）
1. 端末に貼る操作そのもの（Windows PowerShell 5.1 の PSReadLine での複数行の貼り付け、`if … else` のブロック）
1. パスフレーズ付きの鍵と、鍵の節の手順 1 で鍵を新しく作る流れ
1. 標準ユーザーの `authorized_keys`、パスワード（Microsoft アカウント）でのログイン
1. 既定の UAC の設定で、SSH のセッションが High Mandatory Level になるか
1. Windows Update での OpenSSH の更新
1. `scoop update` の後に、更新したアプリが SSH のセッションで起動しなくなり、scoop の任意節の手順 1 で直ること

---

### 付録: パスワード認証の検証記録（2026-09-30）

**流し方**:

- 前の付録と同じく、Windows の手順は `.ps1`（UTF-8、BOM 付き）にして、`sudo powershell.exe -NoProfile -ExecutionPolicy Bypass -File` で 1 手順ずつ流した。各 `.ps1` の先頭に手順 2 のブロックを付けた
- 始めの状態は、2026-09-29 の[完了時点の状態](#完了時点の状態)（`PasswordAuthentication no`、鍵を 1 つ登録、既定のシェルは Git Bash、LAN はプライベート）
  - アカウントは Microsoft アカウント（`Get-LocalUser` の `PrincipalSource` が `MicrosoftAccount`）
  - 設定の「Windows Hello サインインのみを許可する」はオン（利用者が画面で確かめた。レジストリの `HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device` の `DevicePasswordLessBuildVersion` は 2）
- 手順 6 の再起動の前に、`Get-Process sshd` が 1 つだけ（待ち受けだけで、セッションが無い）ことを確かめた
- パスワードは利用者が自分の端末で入れ、成否は `OpenSSH/Operational` のログで確かめた

**1 回目の結果**（2026-09-29 の後の PC に適用）:

- 手順 6: `…:51:PasswordAuthentication yes` と `…:87:Match Group administrators` が出た。`sshd_config` は 2295 バイトから 2296 バイトになった
- WSL から `ssh -o PubkeyAuthentication=no -o BatchMode=yes <WIN_USER>@<WIN_HOST> true`（パスワードを聞かない形）でつなぐと、`Permission denied (publickey,password,keyboard-interactive).` で終わり、sshd が `password` を返すようになった
- 利用者がスマートフォンの SSH のアプリから WireGuard 越しにつなぎ、Microsoft アカウントのパスワードで入った。`whoami` は `<WIN_USER>`（既定のシェルが Git Bash なので、Git の `whoami`）
  - ログには `sshd: Accepted password for <WIN_USER> from <IP> port <PORT> ssh2` が 2 回残った。`<IP>` は WireGuard のクライアントのアドレス（LAN の外のサブネット）
  - 1 回目の切断の記録は `Received disconnect from <IP> port <PORT>:11: Normal Shutdown`（OpenSSH の `ssh` なら `disconnected by user`）
- WSL から、公開鍵の任意節の手順 5 を流した。パスワードを聞かれずに `<WIN_USER>` が出た（既定のシェルが Git Bash なので、Git の `whoami`）
- 文書を書き直した後に、`## 実施手順` の `powershell` のブロックを順に抜き出し、手順 2〜5・7 を流した
  - 手順 3 は 9 秒で `RestartNeeded : False` と `State : Installed`（入っていたので取りに行かなかった）
  - 手順 4・5 は、`sshd  Running  Automatic`、22 番の 2 行、`<LAN_IF>  Private`、`OpenSSH-Server-In-TCP  True  Private  Inbound  Allow` で、何も変わらなかった
  - 手順 7 は、`<WIN_USER>@<WIN_HOST>` と ED25519 の指紋を出した。指紋は、2026-09-29 に WSL の `known_hosts` に入った鍵（`ssh-keygen -F <WIN_HOST> -l`）と同じだった
- 抜き出した手順 6 は、最初に流したブロックと行が同じだった（末尾の改行だけが違った）
  - このときスマートフォンのセッションがつながっていた（`sshd` のプロセスが 3 つ）ので、再起動する 2 回目は流さなかった
  - 代わりに、`sshd_config` の写しに手順 6 の置き換えを Windows PowerShell 5.1 でもう 1 度当て、ハッシュが変わらないことを確かめた
- [完了時点の状態](#完了時点の状態)の確認のコマンドを流し直し、`sshd_config` と `sshd.pid` の長さのほかは 2026-09-29 と同じ値だった
- スマートフォンのセッションが切れた後に、抜き出した手順 6 をもう 1 度流した。出力は 1 回目と同じで、`sshd_config` のハッシュは変わらず、sshd は再起動した（プロセス ID が変わった）

**2 回目: 実施前の状態からの通し**:

- 試験用のユーザーを 2 つ作った
  - Windows: ローカル アカウントの標準ユーザー（`New-LocalUser` と、`Users` への追加。Administrators には入れない）。パスワードはランダムに作り、作業用のファイルにだけ置いた
  - WSL: Linux のユーザー（`useradd -m`）。公開鍵の任意節を、空の `~/.ssh` から通すため
  - 一時的な `HOME` では代えられなかった。`ssh-keygen` は `$HOME` ではなく passwd のホームを見て、いつものユーザー（`<USER>`）の `~/.ssh/id_ed25519` の `Overwrite (y/n)?` で止まった（何も答えずに打ち切り、鍵が変わっていないことを確かめた）
- 対話（ホスト鍵の確認・パスワード・パスフレーズ・cmd のプロンプト）には、WSL の Python の `pty` で動かす小さなスクリプトで答えた。ブロックは文書から抜き出したまま流した
- 控え: `robocopy /E /COPYALL /B` で `C:\ProgramData\ssh` を、`reg export` で `HKLM\SOFTWARE\OpenSSH` を、`cp -p` で WSL の `known_hosts` と `known_hosts.old` を控えた
- ロールバック: 手順 1 は 6 秒で `State : NotPresent`、手順 2 は `False` が 2 行、手順 3 は `<LAN_IF>  Public`、手順 4 は `found: line 4`〜`6` の 3 行と `known_hosts updated.`
- 手順 2〜7:
  - 手順 3 は 493 秒で `RestartNeeded : False` と `State : Installed`。直後は `C:\ProgramData\ssh` もレジストリのキーも無く、sshd は `Stopped` / `Manual`
  - 手順 4 の後の `sshd_config` は、`C:\Windows\System32\OpenSSH\sshd_config_default` と同じ（2297 バイト、51 行目は `#PasswordAuthentication yes`）
  - 手順 5 で `Public` から `Private` になった
  - 手順 6 の後の `sshd_config`（2296 バイト）は、1 回目の後のもの（`no` から `yes` にしたもの）とハッシュが同じだった
  - 手順 7 は新しいホスト鍵の指紋を出した
- 手順 8・9（試験用の標準ユーザー。`WIN_HOST=` の後ろと、`WIN_USER` の値だけを書き換えた）:
  - 初回の `ED25519 key fingerprint is SHA256:…` が手順 7 と一致し、`yes` の後にパスワードを聞かれた
  - cmd のプロンプトが出て、`whoami` は `<hostname>\<試験用のユーザー>`。`whoami /groups` は `BUILTIN\Users` と `Mandatory Label\Medium Mandatory Level`
  - ログは `Accepted password for <試験用のユーザー> from <WIN_HOST> port <PORT> ssh2`
- 公開鍵の任意節（WSL の試験用のユーザー。`WIN_USER` は検証した PC のユーザー（`<WIN_USER>`）に直した）:
  - 手順 1 は `Created directory '/home/<試験用のユーザー>/.ssh'.` の後にパスフレーズを 2 回聞き、手順 2 は 1 行の公開鍵を出した
  - 手順 3・4 は、`$PUBKEY` の `''` の中だけを手順 2 の出力に置き換えて流した。`icacls` は `NT AUTHORITY\SYSTEM:(F)` と `BUILTIN\Administrators:(F)` の 2 行
  - 手順 5 は、初回のホスト鍵の確認に `yes` と答えると、パスワードではなくパスフレーズ（`Enter passphrase for key …`）を聞き、`<hostname>\<win_user>` を出した
- パスワード認証を切る任意節:
  - 手順 1 は `…:51:PasswordAuthentication no`、`…:87:Match Group administrators`、`…:88:       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys`
  - 手順 2 の 1 つ目は、パスワードを聞かずに `Permission denied (publickey,keyboard-interactive).`。2 つ目はパスフレーズを聞き、`<hostname>\<win_user>` を出した
  - 試験用の標準ユーザーも、パスワードを聞かれずに `Permission denied (publickey,keyboard-interactive).` になった
  - 手順 6 を流し直すと、`Permission denied (publickey,password,keyboard-interactive).` に戻り、試験用の標準ユーザーがパスワードで入れた
- 戻し: sshd を止め、`robocopy /MIR /COPYALL /B`（`sshd.pid` は除く）と `reg import` で戻し、sshd を起動した
  - ファイルのハッシュと `icacls` の出力が控えと一致し、ホスト鍵の指紋は元に戻った。`DefaultShell` も戻った
  - WSL の `known_hosts` を控えから戻すと、いつものユーザー（`<USER>`）の鍵で、ホスト鍵の警告無しに入れた
  - 戻しのスクリプトを最初に流したときは、構文の誤り（Windows PowerShell 5.1 の `( a ; b )`）で何も実行されなかった。そのとき、戻した `known_hosts` の WSL から接続すると、`REMOTE HOST IDENTIFICATION HAS CHANGED!` で止まった

**ロックアウト**（試験用の標準ユーザー）:

- `net accounts` は、しきい値 10 回・ロックの時間 10 分・観測期間 10 分
- 間違ったパスワードを、1 回の接続で 3 回（`ssh` の既定の `NumberOfPasswordPrompts`）ずつ送った

  | 接続 | `BadPasswordAttempts` | ロック |
  |---|---|---|
  | 前 | 0 | 無し |
  | 1 回目 | 3 | 無し |
  | 2 回目 | 6 | 無し |
  | 3 回目 | 9 | 無し |
  | 4 回目 | 10 | 有り |

- セキュリティのログ: 失敗ごとにイベント 4625（ログオンの種類 8、`Status 0xc000006d`・`SubStatus 0xc000006a`、プロセスは `sshd.exe`）。10 回目の直後にイベント 4740（ロック）
- ロックの後は、正しいパスワードでも入れなかった
  - `ssh -v` では、鍵交換が終わった後（ユーザー名を送った段階）で `Connection reset by <WIN_HOST> port 22` になり、パスワードを聞かれなかった
  - sshd のログには何も残らなかった
  - 同じときに検証した PC のユーザー（`<WIN_USER>`）でつなぐと、ふだんどおり認証の方法の一覧（`publickey,password,keyboard-interactive`）が返った
- ロックは 10 分で解けた（20 秒ごとに確かめ、ロックの 10 分 6 秒後に解けていた）。`BadPasswordAttempts` は 0 に戻り、正しいパスワードで入れた

**試験用のユーザーの後片付け**:

- Windows のユーザーは `Remove-LocalUser` で消えたが、プロファイルは `Remove-CimInstance` が `別のプロセスが使用中です` で消せなかった
  - `Win32_UserProfile` は `Loaded : True`。User Profile Service の Operational のログには、最初の SSH のログオン（パスワードで入った 1 回目）でハイブを読み込んだ記録だけがあり、外した記録が無かった
  - そのユーザーの SID で動くプロセスは無く、`reg unload` は `Access is denied.` だった
  - 30 秒ごとに 10 分待っても外れなかったので、プロファイルのフォルダーは残し、再起動の後に消すことにした
- WSL の Linux ユーザーは、WSL が起こしたログインシェルが残っていて 1 回目の `userdel` が失敗し、それを止めてから消した

**再起動の後の自動起動**（ログから）:

- 2026-09-29 の作業の後に、利用者がこの PC を 2 回起動し直していた
- どちらも、起動（System のイベント 6005）と同じ秒か 1 秒後に、`OpenSSH/Operational` に `Server listening on 0.0.0.0 port 22.` と `:: port 22.` が出ていた

**残っている未確認事項**（2026-09-30 の時点）:

1. Microsoft アカウントのパスワードで、手順 8・9 のブロック（OpenSSH の `ssh`）から入ること
1. LAN の別の PC から、この文書の手順で入ること（利用者の公開鍵での接続は、LAN の別の IP からもログに残っていた）
1. 端末に貼る操作そのもの（Windows PowerShell 5.1 の PSReadLine での複数行の貼り付け、bash の対話の入力）
1. 標準ユーザーの鍵での認証（`authorized_keys`）と、既定の UAC の設定での振る舞い
1. Microsoft アカウントのロックアウト
1. Windows Update での OpenSSH の更新
1. 「Windows Hello サインインのみを許可する」をオンにしたまま、パスワードで入れる理由（Q&A の報告とは違った。Microsoft アカウントのパスワードでサインインしたことがあるかどうかなど、条件は調べていない）
