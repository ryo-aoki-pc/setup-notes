# Windows 11 で OpenSSH サーバーを使う手順（OpenSSH.Server の機能 + パスワード認証）の参考資料

[手順書](../windows-openssh-server.md)・[ロールバックと注意点](../extra/windows-openssh-server.md)

[検証記録](../verification/windows-openssh-server.md#参考資料から分離した記録)

## 補足

### 実施手順 / 手順 1: 補足: Windows PowerShell 5.1 で開く理由

- PowerShell 7（`pwsh`）では、手順 3 が失敗する

### 実施手順 / 手順 2: 補足: 変数について

- `LAN_IF` は、インターネットにつながっている接続の名前（`イーサネット`、`Wi-Fi` など）
- 変数はその PowerShell の中だけで有効

### 実施手順 / 手順 3: 補足: 入るものと、PowerShell 7 で失敗すること

- 入るのは Windows のオプション機能「OpenSSH サーバー」（設定アプリの「システム」→「オプション機能」と同じもの）。`C:\Windows\System32\OpenSSH\sshd.exe`と、サービス `sshd`、受信の規則 `OpenSSH-Server-In-TCP` ができる
- クライアント（`ssh.exe` など）は Windows 11 に最初から入っていて、この手順では変わらない
- 先頭の `if` は、PowerShell 7（`PSEdition` が `Core`）で貼ったときに何もしないで止めるためのもの
- 機能は Windows Update から取ってくるので、数分かかる

### 実施手順 / 手順 4: 補足: 最初の起動で作られるもの

- 最初に起動したときに、`C:\ProgramData\ssh` にホスト鍵 3 組（RSA・ECDSA・ED25519）と `sshd_config`、`logs` ができる。
- [既定のシェルを Git Bash にする（任意）](../windows-openssh-server.md#既定のシェルを-git-bash-にする任意)では、レジストリの `HKLM:\SOFTWARE\OpenSSH` に値を足す

### 実施手順 / 手順 6: 補足: 既定でも有効なのに書く理由と、置き換える理由

- パスワード認証は既定で有効。この手順はそれを明示的な行にするので、[パスワード認証を切る（任意）](../windows-openssh-server.md#パスワード認証を切る任意)で `no` にした PC も、この手順を貼れば戻る
- `sshd_config` の末尾は `Match Group administrators` のブロックなので、末尾に足した行はそのブロックの中の設定になる。そこで、既定の行を置き換える
- `sshd -t` は設定の検査だけをする（誤りが無ければ何も出さない）。誤りがあれば再起動しないので、動いている sshd は古い設定のまま残る
- Windows PowerShell 5.1 の `Set-Content -Encoding ascii` は BOM 無しの ASCII、CRLF で書く
- Microsoft の文書は、Windows の OpenSSH の認証の方法は `password` と `publickey` だけとしている
- 行を置き換えるので、何度貼っても結果は同じ

### 実施手順 / 手順 7: 補足: ユーザー名

- Microsoft アカウントでも、ユーザー名はメールアドレスではなく、`C:\Users\` の下のフォルダーの名前

### 実施手順 / 手順 8: 補足: 変数について

- 変数はそのシェルの中だけで有効

### 公開鍵でもログインする（任意） / 手順 1: 補足: 鍵の種類とパスフレーズ

- ED25519 は Windows と AlmaLinux 10 の OpenSSH のどちらも扱え、鍵が短く、この節の手順 3 で 1 行のまま貼れる
- パスフレーズは、秘密鍵のファイルが漏れたときの守り。空にすると、この節の手順 5 と[パスワード認証を切る（任意）](../windows-openssh-server.md#パスワード認証を切る任意)の手順 2 で聞かれなくなる。後から付けるなら `ssh-keygen -p -f ~/.ssh/id_ed25519`
- 秘密鍵（`~/.ssh/id_ed25519`）はクライアントから出さない。Windows に渡すのは、この節の手順 2 の公開鍵だけ

### 公開鍵でもログインする（任意） / 手順 3: 補足: 読み戻し

- `$PUBKEY` が空、または `ssh-` などで始まらなければ、この節の手順 4 は何もしないで止まる

### 公開鍵でもログインする（任意） / 手順 4: 補足: クライアントを足す

- この節の手順 4 を貼り直すと、`administrators_authorized_keys` に行が足される

### 公開鍵でもログインする（任意） / 手順 5: 補足: 鍵で入ったときのログ

- `-o PasswordAuthentication=no` は、鍵が通らなかったときにパスワードへ移らず、そこで終わらせるため

### パスワード認証を切る（任意） / 手順 1: 補足: 切る前と後

- 行を置き換える理由と `sshd -t` は、[手順 6](../windows-openssh-server.md#実施手順) の補足と同じ
- Microsoft の文書は、Windows の OpenSSH の認証の方法は `password` と `publickey` だけで、`KbdInteractiveAuthentication` は使えないとしている
- 行を置き換えるので、何度貼っても結果は同じ

### 既定のシェルを Git Bash にする（任意） / 手順 1: 補足: DefaultShell

- `DefaultShell` は Windows の sshd だけの設定で、`sshd_config` ではなくレジストリに置く。この PC の全ユーザーの SSH のセッションに効く
- `bin\bash.exe` は、Git の `usr\bin\bash.exe` を `MSYSTEM=MINGW64` と `PATH` を整えて起動する入口。
- sshd の再起動は要らない。次のログインから変わる

### 既定のシェルを Git Bash にする（任意） / 手順 2: 補足: パスワードを 2 回聞かれる理由

- 鍵を登録していなければ 2 回聞かれるのは、`ssh` が 2 つあるため

### 既定のシェルを Git Bash にする（任意） / 手順 3: 補足: 戻る時期

- `DefaultShell` を消すと、次のログインから cmd.exe に戻る

### scoop のツールを SSH のセッションで使う（任意） / 手順 1: 補足: 貼り直し

- 作り直すものが無ければ何も出ないので、何度貼ってもよい

### 参照

[検証記録](../verification/windows-openssh-server.md#参考資料から分離した記録)

---
