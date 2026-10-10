# Windows 11 で OpenSSH クライアントを使う手順（ed25519 の鍵と ssh の config で AlmaLinux 10 のホストに入る）の参考資料

[手順書](../windows-ssh-client.md)・[ロールバックと注意点](../extra/windows-ssh-client.md)

[検証記録](../verification/windows-ssh-client.md)

## 補足

### 実施手順 / 手順 3: 補足: 2 つの ssh と、共有する .ssh

- Windows 11 には、2 つの OpenSSH クライアントがある
  - Windows の OpenSSH クライアント（`C:\Windows\System32\OpenSSH\ssh.exe`。Windows のオプション機能で、Windows Update で上がる）。PowerShell で `ssh` と打ったときと、WezTerm の自分用の設定の起動メニュー（`ssh.exe` を名前で起動する）は、ふつうはこちら
  - Git for Windows に入っている ssh（`C:\Program Files\Git\usr\bin\ssh.exe`）。git が SSH でつなぐとき（`git@github.com:…` など）と、Git Bash で `ssh` と打ったときは、こちら。Git for Windows のインストーラの既定（`SSH Option=OpenSSH`、同梱の ssh を使う）のまま入れた PC の形
- どちらも `%USERPROFILE%\.ssh` を `~/.ssh` として使うので、鍵・config・known_hosts は 1 組になる
  - Windows の ssh は、ホームをユーザーのプロファイルのパスから取る（`HOME` を見ない）
  - git は、`HOME` が無ければ `%HOMEDRIVE%%HOMEPATH%`（または `%USERPROFILE%`）を `HOME` にして、Git の ssh を動かす
- そのため、`HOME` を別の場所にしていると、Git の ssh だけが別の `.ssh` を使う。git が使う ssh は、`GIT_SSH_COMMAND` → `core.sshCommand` → `GIT_SSH` → `PATH` の `ssh` の順に決まるので、手順 3 でこの 3 つも空なことを確かめる
- ブロックの中では、どちらの ssh もフルパスで呼ぶ。ユーザーの `PATH` の先頭側に Git の `usr\bin` があると、`ssh`・`ssh-keygen` が Git のものになる（[Windows の OpenSSH サーバーの手順 7 の補足](../verification/windows-openssh-server.md#実施手順--手順-7-補足-フルパスで呼ぶ理由)）

### 実施手順 / 手順 4: 補足: 鍵の種類とパスフレーズ

- ED25519 は、Windows の ssh・Git の ssh・AlmaLinux 10 の sshd のどれも扱え、鍵が短い。Microsoft の文書も、種類を指定しないときの既定を Ed25519 としている
- `-N ''`（空のパスフレーズ）は書かない。Windows PowerShell 5.1 は、ネイティブのコマンドに空の文字列の引数を渡さない（PowerShell 7.3 からは渡す）ので、`-N` の値が抜ける。パスフレーズは `ssh-keygen` に聞かせる
- パスフレーズは、秘密鍵のファイルが漏れたときの守り。ssh-agent を使わないので、付けると鍵を使うたびに聞かれる（[選択した方針](#選択した方針)）。後から付けるなら、[注意点](../extra/windows-ssh-client.md#注意点)の `ssh-keygen -p`
- 既に `id_ed25519` があれば作らない。GitHub に登録した鍵をそのまま使える。ホストごとに鍵を分ける形にはしなかった（鍵の管理が増えるため）
- 秘密鍵だけがあるとき（秘密鍵だけをほかの PC から写したときなど）は、`ssh-keygen -y` で秘密鍵から公開鍵を作り直す。`ssh-keygen -t` を流すと、上書きを聞かれる
  - 出力が `ssh-ed25519 AAAA` で始まるときだけ、`Set-Content -Encoding ascii` で `id_ed25519.pub` に書く。`>` は、Windows PowerShell 5.1 では UTF-16 で書くので使わない
  - Win32-OpenSSH の `ssh-keygen -y` は、秘密鍵を読む前にアクセス権を確かめる（`authfile.c` の `sshkey_load_private_type` が `sshkey_perm_ok` を呼ぶ）
  - 写した鍵は `Everyone` などが付いていることがあるので、そのときは手順 5・6 で直してから作り直す

### 実施手順 / 手順 5: 補足: 秘密鍵のアクセス権

- Windows の ssh は、秘密鍵の所有者が本人・Administrators・SYSTEM（か TrustedInstaller）で、ほかの主体に許可が無いことを確かめる。合わなければ `WARNING: UNPROTECTED PRIVATE KEY FILE!` と出して、その鍵を使わない（Win32-OpenSSH のソース）
- `%USERPROFILE%` の下に作ったファイルは、プロファイルから SYSTEM・Administrators・本人の許可を受け継ぐので、そのままで合う
- Windows の `ssh-keygen` で作った秘密鍵は、受け継がない 3 つの許可になるはず（Windows では確かめていない）
  - Win32-OpenSSH v9.5.0.0 のソースでは、`authfile.c` の `sshkey_save_private_blob` が秘密鍵を `0600` で開く
  - `contrib/win32/win32compat/fileio.c` の `createFile_flags_setup` が、そのモードを `O:<本人>D:PAI(A;;FA;;;BA)(A;;FA;;;SY)(A;;<読み書き>;;;<本人>)` の SDDL にする
  - `D:PAI` は受け継ぎを切った DACL。Administrators と SYSTEM はフル コントロール、本人は読み書き（フル コントロールではない）
- ほかの PC から写した鍵や、共有のフォルダーを通した鍵は、`Everyone` などの許可が付くことがある。そのときだけ手順 6 で直す
- Git の ssh は、このアクセス権の確かめをしない。秘密鍵のアクセス権が悪いと、Windows の ssh だけが鍵を使わない

### 実施手順 / 手順 6: 補足: アクセス権の直し方

- `icacls <鍵> /reset` で明示の許可をすべて外して受け継ぐ形に戻し、`/inheritance:r` で受け継いだ許可も外してから、`/grant:r` で本人・SYSTEM（`S-1-5-18`）・Administrators（`S-1-5-32-544`）だけにフル コントロールを付ける
- `/inheritance:r` と `/grant:r` だけでは、`Everyone` などの明示の許可が残る（`/grant:r` は、名指しした主体の許可だけを置き換える）。そのため先に `/reset` を行う
- 主体は SID で渡す（表示の言語に左右されないため。[windows-openssh-server.md](../windows-openssh-server.md) の公開鍵の任意節と同じ）。本人の SID は `[Security.Principal.WindowsIdentity]::GetCurrent().User.Value`。`"*${sid}:F"` と波かっこで書くのは、`$sid:F` がスコープ付きの変数として読まれないため

### 実施手順 / 手順 7: 補足: config の書き方と文字コード

- 足すのは `Host`・`HostName`・`User`・`IdentityFile`・`IdentitiesOnly` の 5 行と、前後の印の 2 行。印（`#` で始まる行）は ssh が読み飛ばす。[ロールバック](../extra/windows-ssh-client.md#ロールバック)の手順 2 は、この印の間だけを消す
- `IdentitiesOnly yes` で、この接続先には `IdentityFile` の鍵だけを使う（ほかの鍵を順に試さない）。`IdentityFile` は `~/.ssh/…` と `/` で書く。どちらの ssh も `~` を展開する
- 書く文字コードは `-Encoding ascii`（BOM の無い ASCII。値は ASCII の英数字と記号だけに限っている）。Windows PowerShell 5.1 の `-Encoding UTF8` は BOM を付け、`>`・`>>`・`Out-File` は UTF-16 で書く
  - Windows の ssh は UTF-8 の BOM を読み飛ばすが（Win32-OpenSSH のソース）、Git の ssh は読み飛ばさず、`Bad configuration option` で止まる。そのため、BOM のある config には足さずに止める
  - 改行は CR LF になる。ssh は行の末尾の CR を空白として捨てる
- 同じ `Host` がもうあるかは、`Host <別名>` と `Host=<別名>` の両方の書き方で探す（ssh_config は `=` でも区切れる）。2 つ目の `Host` のブロックを足しても、ssh は最初のものを使い、足した値は効かない
- `Add-Content` は、末尾に改行の無いファイルに、改行を入れずに続けて書く（このリポジトリの [windows-setup.md の記録](../verification/windows-setup.md)）。そのため、末尾に改行が無ければ、先に空の 1 行（改行）を書く
- 確かめは、2 つの ssh の `-G`（config を読んだ結果の表示）で行う。Git の ssh のほうが BOM に厳しく、Windows の ssh（9.5p2）は新しい設定を知らないので、両方を必ず確かめる

### 実施手順 / 手順 8: 補足: ホスト鍵の指紋

- 最初の接続で出る指紋を、別の経路（ホストの画面か、すでに信頼している接続）で見た指紋と照合する。照合した後は known_hosts に入り、以後は聞かれない
- AlmaLinux 10 の sshd は、最初の起動のときに ED25519・ECDSA・RSA のホスト鍵を作る。公開鍵は 0644 なので、`sudo` 無しで読める。コメントは空なので `no comment` と出る（AlmaLinux 10.2 の `sshd-keygen`）
- 初回の接続の表示は、ssh の版で少し違う（Git の 10.5p1 は `ED25519 key fingerprint is: SHA256:…`、AlmaLinux 10.2 の 9.9p1 は `ED25519 key fingerprint is SHA256:….`）。照合するのは `SHA256:` の後ろ

### 実施手順 / 手順 9: 補足: 公開鍵の足し方

- `ssh-copy-id` は使わない。Git for Windows の Git Bash には入っているはずだが（MinGit 以外）、PowerShell のブロックにそろえるため、同じことをするコマンドを 1 回の ssh で送る
  - `umask 077` で、新しく作る `~/.ssh` を 0700、`authorized_keys` を 0600 にする。sshd の `StrictModes` は、group・other に書き込みのあるものを断る（前からある `authorized_keys` のモードは変えない）
  - `authorized_keys` の末尾に改行が無ければ、先に改行を足す（`ssh-copy-id` と同じ）
  - Windows PowerShell 5.1 は、ネイティブのコマンドへのパイプを CR LF で送るので、`tr -d '\r'` で CR を捨てる
  - 1 行目の先頭の UTF-8 の BOM は、`sed` で捨てる。プロファイルで `$OutputEncoding` を UTF-8 にした 5.1 は、BOM を付けて送るかもしれない（Windows では確かめていない）
    - BOM の付いた行は、`ssh-keygen -lf` が公開鍵と認めなかった（[検証記録の模擬](../verification/windows-ssh-client.md#模擬)）。sshd もその行の鍵を使わないはず（sshd では確かめていない）
  - `restorecon` は、あるときだけ動かし、無くても `added` の判定に入れない（`ssh-copy-id` と同じ）。ラベルは `ssh_home_t` になる
- ホストに渡すコマンドの中に二重引用符を使わない。Windows PowerShell 5.1 は、ネイティブのコマンドの引数の中の二重引用符を逃がさない。単一引用符は、PowerShell の単一引用符の文字列の中で `''` と重ねて書く
- `-o PubkeyAuthentication=no` は、鍵を試さず（パスフレーズも聞かず）にパスワードへ進むため（[windows-openssh-server.md の手順 9](../windows-openssh-server.md#実施手順) と同じ）
- Windows の ssh は、ホスト鍵の問いへの答えとパスワードを、標準入力ではなくコンソールから読む（Win32-OpenSSH のソース）。そのため、標準入力で渡す公開鍵は、問いに食われない（Windows では確かめていない）
- AlmaLinux 10 の既定では、一般のユーザーはパスワードで SSH に入れ、root はパスワードでは入れない（`PermitRootLogin prohibit-password`）。ホストを固くして `PasswordAuthentication no` にしているときは、この手順は使えない（[注意点](../extra/windows-ssh-client.md#注意点)）

### 実施手順 / 手順 10: 補足: 鍵でのログインの確かめ方

- `-o PreferredAuthentications=publickey` は、鍵が通らなかったときにパスワードへ移らず、そこで失敗させるため
- 2 つの ssh で確かめるのは、Git の ssh が同じ鍵・config・known_hosts を使っていること（ホスト鍵を聞かれないこと）も見るため

### 実施手順 / 手順 11: 補足: WezTerm の起動メニュー

- 自分用の設定（ryo-aoki-pc/wezterm）は、`~/.ssh/config` の `Host`（ワイルドカードを含むものと、github.com などの git のホストは除く）を、起動メニューに `ssh <Host>` として並べる。起動するのは `ssh.exe` で、パスは決めていない
- WezTerm の設定の読み直し（Ctrl+Shift+R）で、config に足した `Host` が並ぶ
- config の読み取りに失敗しても、設定の全体は落ちず、ssh の項目だけが出ない。WezTerm が BOM 付きの config を読めるかは確かめていない

### ロールバック / 手順 1: 補足: 行の消し方

- 公開鍵の 2 つ目の欄（`AAAA…` の base64）が形に合うときだけ動かす。空のまま `grep -vF --` に渡すと、`authorized_keys` のパスがパターンになって標準入力を読み、`authorized_keys` を空にしうる（[検証記録の模擬](../verification/windows-ssh-client.md#模擬)）
- `grep -vF` の終了コードが 1（残る行が無い）でも書き戻し、2（読めない）のときは書き戻さない
- `grep -cF` は、消した後に残っている行の数（`0` ならよい）

### ロールバック / 手順 2: 補足: バイトのまま書き戻す

- config を Latin-1（コードページ `28591`）として読み、同じ符号化で書き戻す。Latin-1 は 256 のバイトを 1 つずつ別の文字に当てるので、印の間の外のバイトは、文字コードによらず変わらない
- 印と別名は ASCII なので、Latin-1 として読んでも正規表現はそのまま効く
- UTF-8 として読み書きすると、UTF-8 として正しくないバイト（CP932 で保存した日本語のコメントなど）が U+FFFD に置き換わる（[検証記録の模擬](../verification/windows-ssh-client.md#模擬)）。手順 7 は BOM の無い CP932 の config を止めない

### 選択した方針

- **Windows だけの手順書にした**（利用者の選択）。AlmaLinux 10 の SSH クライアントの手順は、この手順書には入れない
- **ssh-agent は使わない**（利用者の選択）
  - Windows の ssh-agent のサービスは既定で無効で、有効にするには管理者の権限が要る（Microsoft の文書）
  - 鍵にパスフレーズを付けたら、使うたびに聞かれる。付けなければ聞かれないが、秘密鍵のファイルを持つ人は誰でも入れる（Microsoft は空のパスフレーズを勧めていない）
- **Windows の ssh と Git の ssh をそろえる設定（`core.sshCommand` を Windows の ssh にする）はしない**
  - git.md の、両 OS に同じ bash のブロックを貼る形を崩すことになり、ssh-agent を使わない限り得るものが無い
  - 代わりに、config は両方の ssh が読める書き方に限り、手順 7 と更新で両方の `-G` を確かめる
- **winget や scoop の OpenSSH（新しい版の Win32-OpenSSH）は入れない**: 3 つ目の `ssh.exe` が `PATH` に加わり、`PATH` の順によっては PowerShell と WezTerm が使う ssh が変わる（どれが動くかが分かりにくくなる）。得るのは新しい版だけ
- **鍵交換の方式は、確かめてから書く**: Windows の 9.5p2 も `sntrup761x25519-sha512@openssh.com`（耐量子のハイブリッド）を扱う。AlmaLinux 10 の既定の暗号ポリシーとの組み合わせで実際に選ばれる方式は、`ssh -v` の `kex: algorithm:` の行で測る（[検証記録の未確認事項](../verification/windows-ssh-client.md#残っている未確認事項)）
- **WSL の AlmaLinux 10 の ssh は、別のものとして扱う**: WSL のホームの `~/.ssh` は別にあり、Windows の `%USERPROFILE%\.ssh` を共有しない。WSL から入るなら、WSL の中で鍵を作る

### 参照

- [Get started with OpenSSH for Windows (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse)（クライアントの機能、オプション機能の画面）
- [OpenSSH key management for Windows (Microsoft Learn)](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement)（Ed25519 の既定、ssh-agent のサービス、空のパスフレーズ）
- [about_Parsing (Microsoft Learn)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parsing)（ネイティブのコマンドへの空の文字列の引数。7.3 からの変更）
- [about_Character_Encoding (PowerShell 5.1, Microsoft Learn)](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding?view=powershell-5.1)
- [PowerShell/openssh-portable の v9.5.0.0](https://github.com/PowerShell/openssh-portable/tree/v9.5.0.0)（`contrib/win32/win32compat/misc.c` の `w32_fopen_utf8`、`w32-sshfileperm.c`、`readconf.c`、`authfile.c`）
- [Using secure communications between two systems with OpenSSH — Securing networks (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/securing_networks/using-secure-communications-between-two-systems-with-openssh)（`PermitRootLogin` の既定の `prohibit-password`、FIPS モードと Ed25519）
- `man ssh_config`（`Host`、`IdentitiesOnly`、`-G`）/ `man ssh-keygen`（`-l`、`-R`、`-p`）/ `contrib/ssh-copy-id`（OpenSSH）
- [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)（`lua/shells.lua` の `ssh_entries()` と README の「SSH ホスト」）
- [Windows の OpenSSH サーバー](../windows-openssh-server.md)（逆向き）
