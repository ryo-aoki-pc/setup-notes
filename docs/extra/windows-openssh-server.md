# Windows 11 で OpenSSH サーバーを使う手順（OpenSSH.Server の機能 + パスワード認証）のロールバックと注意点

[手順書](../windows-openssh-server.md)・[検証記録](../verification/windows-openssh-server.md)・[参考資料](../reference/windows-openssh-server.md)

- 「手順 N」は[手順書](../windows-openssh-server.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

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
     "`n$([char]27)[7m 確認 $([char]27)[0m"
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
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path "$env:ProgramData\ssh", HKLM:\SOFTWARE\OpenSSH
   ```

   - `False` が 2 行出ればよい

1. LAN の接続をパブリックに戻すときだけ、[Windows 11 の初期設定のロールバックの「ネットワークと PC 全体の設定を戻す」](windows-setup.md#ネットワークと-pc-全体の設定を戻す)の手順 5 を行う。

   - この LAN でほかにプライベートの規則を使うもの（[Syncthing の Windows 11 の節](../syncthing.md#windows-11-で使う)、リモート デスクトップなど）があれば、戻さない

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
  - [Windows 11 の初期設定の「サインイン・検索・キーボード」の手順 1](../windows-setup.md#サインイン検索キーボード) を通した PC では、この設定はオフになっている
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
  - ミラーにした PC（[Windows 11 の初期設定の任意節](../windows-setup.md#wsl-のネットワークをミラーにする任意)）では、`127.0.0.1` あてにつなぐ。LAN の IP あてはつながらず、sshd のログの送信元も `127.0.0.1` になるはず（`127.0.0.1` で届くことも含め、確かめていない）
- **Git の ssh が先に見つかる PC**: `PATH` の順で、Windows の `ssh`・`ssh-keygen` ではなく Git のものが動く。Windows の OpenSSH のものは `C:\Windows\System32\OpenSSH\` から呼ぶ（手順 7）
- **SSH のセッションでは、一般ユーザーが作ったジャンクションをたどれない**
  - sshd に掛けてある RedirectionGuard を、セッションのプロセスが引き継ぐため。開こうとすると、エラー 448（`ERROR_UNTRUSTED_MOUNT_POINT`）になる
  - ローカルのシェルは、昇格していても RedirectionGuard が掛かっておらず、影響を受けない
  - scoop のジャンクションは、[scoop のツールを SSH のセッションで使う（任意）](../windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)で、管理者で作り直す
- **設定を変えたとき**: `sshd_config` を変えたら `Restart-Service sshd`（手順 6）。レジストリの `DefaultShell` は、次のログインから使われる
- **機能を外したとき**
  - Microsoft の文書は、使っている間に外したなら Windows を再起動するよう書いている
- **ログ**: イベント ビューアーの「OpenSSH」→「Operational」
