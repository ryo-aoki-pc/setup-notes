# Windows の OpenSSH クライアントの注意点

[手順書](../windows-setup.md#windows-の-openssh-クライアント)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-ssh-client.md)・[参考資料](../reference/windows-ssh-client.md)

- 「手順 N」は[手順書](../windows-setup.md#windows-の-openssh-クライアント)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **ssh-agent は使わない**: パスフレーズを付けた鍵は、使うたびに聞かれる（ssh・scp・WezTerm の起動メニュー・ssh を使う git）
  - 同じ鍵を GitHub にも登録しているなら、git の fetch・push のたびにも聞かれる
  - パスフレーズを後から付ける・変えるのは、`& "$env:WINDIR\System32\OpenSSH\ssh-keygen.exe" -p -f "$env:USERPROFILE\.ssh\id_ed25519"`
- **2 つの ssh が、同じ `%USERPROFILE%\.ssh` を使う**: Windows の ssh（PowerShell・WezTerm の起動メニュー）と Git の ssh（Git Bash・git）は、鍵・config・known_hosts を共有する
  - WSL の AlmaLinux 10 の ssh は、WSL のホームの `~/.ssh` を使う（別のもの）。WSL から入るなら、WSL の中で鍵を作る
- **config を BOM 付きや UTF-16 で保存しない**: Windows PowerShell 5.1 の `-Encoding UTF8`・`>`・`>>`・`Out-File` は、BOM 付きの UTF-8 か UTF-16 で書く
  - Windows の ssh は UTF-8 の BOM を読み飛ばすが、Git の ssh は `Bad configuration option` で止まり、ssh を使う git（GitHub への push など）も失敗する。UTF-16 は両方が読めない
  - メモ帳で書くなら、文字コードを「UTF-8」（BOM なし）にする
- **config には、両方の ssh が知っている設定だけを書く**: Windows の ssh（9.5p2）が知らない新しい設定を書くと、Windows の ssh が止まる。書いた後は、[更新](../windows-setup.md#windows-の-openssh-クライアント-更新)の手順 3 で両方を確かめる
- **ssh の設定は、最初に見つけた値が効く**: config の前の方の `Host *` などにある `User`・`IdentityFile` は、手順 7 で足した値より先に効く
- **Git の `usr\bin` が `PATH` の先にある PC**: PowerShell と WezTerm の起動メニューの `ssh` が、Git のものになる（[Windows 11 の初期設定の注意点](windows-setup.md#注意点)の OpenSSH サーバーと同じ）。この手順書のブロックは、どちらもフルパスで呼ぶ
- **秘密鍵のアクセス権**: Windows の ssh は、ほかの主体（Everyone・Users など）に許可のある秘密鍵を、`UNPROTECTED PRIVATE KEY FILE!` と出して使わない（手順 5・6）
- **config のアクセス権**: Windows の ssh は、ほかの主体に書き込みの許可のある config を読まず、`Bad owner or permissions on …config` で止まる
  - ほかの PC から写した config や、同期した config で起こりうる
  - 手順 6 のブロックの 1 行目の `id_ed25519` を `config` に書き換えて貼り、[更新](../windows-setup.md#windows-の-openssh-クライアント-更新)の手順 3 で確かめ直す
- **ホストがパスワードでのログインを受け付けないとき**（`PasswordAuthentication no` にしたホストなど）: 手順 9 は使えない。手順 9 の公開鍵の 1 行（`id_ed25519.pub` の中身）を、ホストの画面などで `~/.ssh/authorized_keys` に足す
  - [AlmaLinux 10 のセットアップの「SSH を公開鍵だけにする」](../almalinux-setup.md#ssh-を公開鍵だけにする)を通したホストが、これに当たる。足すのは、その項の手順 1（`SSH_PUBKEY` に公開鍵の 1 行を入れる）でよい
  - その節をまだ通していないホストでは、この手順書を先に通す（手順 9 でパスワードを使う）
- **FIPS モードのホスト**: ed25519 の鍵は使えない（RHEL 10 の文書）。この手順書では扱わない
