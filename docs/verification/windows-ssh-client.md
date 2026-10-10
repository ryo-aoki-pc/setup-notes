# Windows 11 で OpenSSH クライアントを使う手順（ed25519 の鍵と ssh の config で AlmaLinux 10 のホストに入る）の検証記録

[手順書](../windows-ssh-client.md)・[ロールバックと注意点](../extra/windows-ssh-client.md)

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **この手順書は Windows の実機で流していない**。確かめたのは、資料とソース、AlmaLinux 10.2 のパッケージの中身、Linux の OpenSSH での config の読み方、Linux の PowerShell 7 での構文と模擬の実行だけ（[対象と検証環境](#対象と検証環境)）。

### 対象と検証環境

- **目的**: Windows 11 の PC から、LAN の AlmaLinux 10 のホストに、パスワードではなく ed25519 の鍵で SSH ログインする。短い名前（`SSH_ALIAS`）で入れるよう、`%USERPROFILE%\.ssh\config` に接続先を足す
  - 鍵・config・known_hosts は、Windows の OpenSSH クライアント（PowerShell・WezTerm の起動メニュー）と、Git for Windows の ssh（Git Bash・git）の両方で使う
  - 逆向き（AlmaLinux 10 から Windows 11 に入る）は [Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)
- **進め方**: 管理者ではない Windows PowerShell 5.1 に、上から順に貼る。読者が編集するのは `SSH_HOST` と `SSH_ALIAS`（違えば `SSH_USER` も）
  - ホスト鍵の指紋は、ホストの画面などで見て（手順 8）、最初の接続で照合する
  - 公開鍵は、パスワードで 1 回ログインして、ホストの `~/.ssh/authorized_keys` に足す（手順 9。`ssh-copy-id` は使わない）
  - ssh-agent は使わない（利用者の選択。[参考資料の選択した方針](../reference/windows-ssh-client.md#選択した方針)）
- **状態**: **Windows の実機では流していない（未検証。2026-10-08 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](#付録-資料とブロックの確認2026-10-08)）:
    - 資料とソース: Win32-OpenSSH の v9.5.0.0 のソース（config を開くときの UTF-8 の BOM の読み飛ばし、秘密鍵と config のアクセス権の検査、`ssh-keygen` が作る秘密鍵のアクセス権）、ユーザーの WezTerm の設定（起動メニューの ssh）、この PC の前の記録（2 つの ssh の版、GitHub に登録した鍵）
    - AlmaLinux 10.2 の既定: BaseOS の `openssh-server-9.9p1-28.el10_2.alma.1`・`almalinux-release-10.2-21.el10`・`firewalld-2.4.3-4.el10_2` の中身と、comps の `core` のグループ（パスワード認証が既定で有効、sshd が既定で有効、public のゾーンが ssh を通す、ホスト鍵の公開鍵が 0644 でコメント無し）
    - config の読み方: Linux の OpenSSH 9.6p1（Git の ssh と同じく、Win32 の手を入れていない OpenSSH）で、CRLF の config・UTF-8 の BOM 付きの config・UTF-16 の config を `ssh -G` で読ませた
    - PowerShell のブロック: Linux の PowerShell 7.5.3 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。全ブロックを、代役の `ssh.exe`・`ssh-keygen.exe`・`icacls.exe` で流した（見直しの後のブロックで流し直した）。ホストに渡すシェルのコマンドは `bash -n` と、代役のホームでの実行で確かめた
  - **確かめていないこと**（Windows で貼ること。すべての手順）:
    - 鍵: Windows の `ssh-keygen` の問い方（`-y` を含む）と、作った秘密鍵のアクセス権。`icacls` の表示と直し方
    - config: Windows と Git の ssh の `-G` の実際の出力。config のアクセス権が悪いときの止まり方
    - 接続: パスワードとホスト鍵の問い（パイプで公開鍵を渡しながら、コンソールから読むこと）、鍵でのログイン、`ls -lZ` のラベル、鍵交換の方式、標準の AlmaLinux 10 の ISO で入れたホストへの接続
    - パイプ: `$OutputEncoding` を変えた Windows PowerShell 5.1 が、ネイティブのコマンドへのパイプの先頭に BOM を付けるか
    - そのほか: WezTerm の起動メニュー、更新、ロールバック
- 下表は、本書が前提にしている環境（ほかの Windows の手順書の実機の記録と同じ PC を想定）

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro（24H2 以降。利用者の PC は 26H2） |
| PowerShell | Windows PowerShell 5.1（管理者ではない窓） |
| Windows の ssh | `C:\Windows\System32\OpenSSH\ssh.exe`（`OpenSSH_for_Windows_9.5p2, LibreSSL 3.8.2`。[virtualbox-guest-bootc.md の記録](virtualbox-guest-bootc.md)） |
| Git の ssh | `C:\Program Files\Git\usr\bin\ssh.exe`（Git for Windows 2.55.0 の `OpenSSH_10.5p1`。[bash の設定のリポジトリの検証記録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md)） |
| つなぐ先 | AlmaLinux 10.2 のホスト（`openssh-server-9.9p1-28.el10_2.alma.1`）。パスワードでの SSH ログインを受け付けること |

> [!NOTE]
> 環境固有の値は**PowerShell の変数**で書いてある。[手順 2](../windows-ssh-client.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `$SSH_HOST` | AlmaLinux 10 のホストの IP アドレスか DNS 名 | `192.168.1.20` |
> | `$SSH_ALIAS` | ssh で打つ短い名前（config の `Host`） | `alma` |
> | `$SSH_USER` | ホストのユーザー名（既定は Windows のユーザー名） | `$env:USERNAME` |
>
> 出力例の値は `<SSH_HOST>` / `<SSH_ALIAS>` / `<SSH_USER>` / `<WIN_USER>`（Windows のユーザー名）/ `<HOSTNAME>` のプレースホルダで書いてある。模擬で使った値（`192.0.2.10` など）は、文書用のアドレスと試験用の名前。
>
> パスワード・パスフレーズ・秘密鍵はこの文書に載せない。模擬で作った鍵は、パスフレーズ無しの使い捨て。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

Windows では流していないので、記録は無い。前の記録から分かっている利用者の PC の状態:

- `%USERPROFILE%\.ssh\id_ed25519` があり、GitHub に登録してある（パスフレーズ無し。bash の設定のリポジトリの検証記録）。手順 4 は、この鍵を使って何もしないはず
- ユーザーの `PATH` の先頭側に Git の `usr\bin` があった時期がある（[windows-openssh-server.md の記録](windows-setup.md#openssh-サーバー-実施手順--手順-7-補足-フルパスで呼ぶ理由)）。手順 3 の `Get-Command` で今の順を確かめる

### 完了時点の状態

Windows では流していないので、記録は無い。模擬で手順 7 の後にできた config（前からの `Host github.com` の行に足したもの。Linux で流したので改行は LF だけ。Windows の `Add-Content` は CR LF で書く）:

```
Host github.com
  User git
# BEGIN windows-ssh-client.md <SSH_ALIAS>
Host <SSH_ALIAS>
  HostName <SSH_HOST>
  User <SSH_USER>
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
# END windows-ssh-client.md <SSH_ALIAS>
```

### 付録: 資料とブロックの確認（2026-10-08）

Windows を動かせない環境（クラウドの Linux のコンテナ、Ubuntu 24.04。OpenSSH 9.6p1）で確かめた記録。Windows では、どのブロックも貼っていない。

#### 資料とソース

- Win32-OpenSSH（GitHub の PowerShell/openssh-portable の `v9.5.0.0` タグ）
  - `contrib/win32/win32compat/inc/stdio.h` で `fopen` を `w32_fopen_utf8` に置き換え、`misc.c` の `w32_fopen_utf8` は、読むために開いたファイルの先頭の UTF-8 の BOM（`EF BB BF`）を読み飛ばす。`readconf.c` は config を `fopen(filename, "r")` で開くので、Windows の ssh は BOM 付きの UTF-8 の config を読める
  - `readconf.c` は、ユーザーの config を `check_secure_file_permission(filename, pw, 1)` で確かめ、合わなければ `Bad owner or permissions on …` で止まる。`authfile.c` は、秘密鍵を `check_secure_file_permission(filename, NULL, 0)` で確かめ、合わなければ `WARNING: UNPROTECTED PRIVATE KEY FILE!` を出してその鍵を使わない
  - `w32-sshfileperm.c` の `check_secure_file_permission`: 所有者は Administrators・SYSTEM・本人・TrustedInstaller のどれか。許可（allow）を持てるのは Administrators・SYSTEM・本人だけで、ほかの主体は、読むだけを許すとき（config）だけ、書き込みの無い許可を持てる
  - `authfile.c` の `sshkey_save_private_blob` は、秘密鍵を `sshbuf_write_file(filename, keybuf, 0600)` で書く
    - `contrib/win32/win32compat/fileio.c` の `createFile_flags_setup` は、そのモードから `O:<本人>D:PAI(A;;FA;;;BA)(A;;FA;;;SY)(A;;<読み書き>;;;<本人>)` の SDDL を作る
    - 受け継ぎを切り（`D:PAI`）、ほかの主体の許可は付けない
  - `authfile.c` の `sshkey_load_private_type` は、秘密鍵を読む前に `sshkey_perm_ok`（Windows では `check_secure_file_permission`）で確かめる
    - `ssh-keygen -y`（`ssh-keygen.c` の `do_print_public` → `load_identity`）も、合わなければ秘密鍵を読まない
- AlmaLinux 10.2 の BaseOS（`repo.almalinux.org` の `10.2/BaseOS/x86_64/os`。RPM の sha256 は repodata の `primary.xml` と一致）
  - `openssh-server-9.9p1-28.el10_2.alma.1`: `/etc/ssh/sshd_config` は `#PasswordAuthentication yes`・`#PermitRootLogin prohibit-password`（どちらも既定のまま）で、`Include /etc/ssh/sshd_config.d/*.conf`。同梱の `50-redhat.conf` と `40-redhat-crypto-policies.conf` は `PasswordAuthentication` と `PermitRootLogin` を書かない
  - 同じ RPM の `/usr/libexec/openssh/sshd-keygen` は、ホスト鍵を `ssh-keygen -q -t <種類> -f <鍵> -C '' -N ''` で作り、公開鍵を `chmod 644` にする。コメントが空の鍵の `ssh-keygen -lf` は、Linux の ssh-keygen で `256 SHA256:<指紋> no comment (ED25519)` の形になった
  - `almalinux-release-10.2-21.el10` の `/usr/lib/systemd/system-preset/90-default.preset` に `enable sshd.service`
  - `firewalld-2.4.3-4.el10_2` の `/usr/lib/firewalld/zones/public.xml` に `ssh`・`dhcpv6-client`・`cockpit` のサービス
  - BaseOS の comps で、`openssh-server` と `openssh-clients` は `core` のグループの必須（`mandatory`）
  - このリポジトリの前の記録では、ISO で入れた AlmaLinux の bootc の VM で `sshd -T` が `passwordauthentication yes` だった（[virtualbox-guest-bootc.md の記録](virtualbox-guest-bootc.md)）。標準の ISO で入れたホストの `sshd -T` は測っていない
- ユーザーの WezTerm の設定（ryo-aoki-pc/wezterm の `e935df8`）: `lua/shells.lua` の `ssh_entries()` は、`wezterm.enumerate_ssh_hosts()` の Host（ワイルドカードを除く。github.com などは並べない）を、Windows では `{ "ssh.exe", <Host> }` を `DefaultDomain` で起動する項目にする（`ssh.exe` は名前だけで、パスは決めていない）。README は、起動メニューを Ctrl+Shift+M、設定の読み直しを Ctrl+Shift+R とし、`~/.ssh/config` を編集したら Ctrl+Shift+R で反映すると書いている
- bash の設定のリポジトリ（ryo-aoki-pc/bash の `bdb64c2`）の検証記録: 利用者の PC の Git for Windows 2.55.0 の ssh は `OpenSSH_10.5p1`、`~/.ssh/id_ed25519` は GitHub に登録済みでパスフレーズ無し。初回の接続の指紋の行は、Git の ssh では `ED25519 key fingerprint is: SHA256:…`、WSL の AlmaLinux 10.2 の ssh（9.9p1）では `ED25519 key fingerprint is SHA256:….` だった

#### config の読み方（Linux の OpenSSH 9.6p1）

- CR LF の config（印の行と `Host` のブロック）を `ssh -G -F <config> <SSH_ALIAS>` で読ませると、`user`・`hostname`・`identitiesonly yes`・`identityfile ~/.ssh/id_ed25519` がこの順で出た（`~` は展開されずに出る）
- 同じ config の先頭に UTF-8 の BOM を付けると、`line 1: Bad configuration option: \357\273\277#` と `terminating, 1 bad configuration options` で止まった
- UTF-16（`FF FE` で始まる）の config は、`line 1: no argument after keyword "\377\376h"` と `terminating, 1 bad configuration options` で止まった
- Git の ssh（10.5p1）も、Win32 の手を入れていない OpenSSH なので同じはず（Windows では確かめていない）

#### PowerShell のブロック

- 本書の `powershell` のブロック 15 個を、Linux の PowerShell 7.5.3 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer 1.25.0 の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0
- 既定の規則の指摘は、ASCII でない文字を含むファイルの BOM（11 件）と、必須の変数の 1 変数だけのブロックの「代入して使っていない」（2 件）だけ
- 見直しの後のブロック（手順 2・3 の入れ替え、手順 4・7・9 とロールバックの手順 2 の変更の後）でも、3 つの数は同じだった
- ホストに貼る `bash` のブロック（手順 8）と、ホストで動くシェルのコマンド（手順 9・10、ロールバックの手順 1。PowerShell の文字列として解釈した後のもの）は、`bash -n` で誤り無し

#### 模擬

Linux の pwsh で、`$env:WINDIR`・`$env:USERPROFILE` を一時ディレクトリにし、次の代役を置いて、ブロックを上から順に同じセッションに流した（見直しの後のブロックで流し直した記録）。

- `System32\OpenSSH\ssh.exe`: `-V` は版の 1 行、`-G` は config の先頭の UTF-8 の BOM を外してから Linux の `ssh -G -F` に渡す（`w32_fopen_utf8` の代わり）。それ以外は、残りの引数をつないだコマンドを、ホストに見立てたホームで `bash -c` に渡す（標準入力もそのまま渡す）
- Git の `usr\bin\ssh.exe`（ブロックの `C:\Program Files\Git` を一時ディレクトリに置き換えた）: `-G` は BOM を外さずに Linux の `ssh -G -F` に渡す。それ以外は Windows の ssh の代役と同じ
- `ssh-keygen.exe`: `-R` は Linux の `ssh-keygen -R <ホスト> -f <known_hosts>`、`-y` は Linux の `ssh-keygen` にそのまま渡す。鍵を作るときは `-N ''`（パスフレーズ無し）を足して渡す（パスフレーズの問いは試していない）
- `icacls.exe`: 引数を表示するだけ
- ブロックの中の Windows のパスの `\.ssh\` を `/.ssh/` に、`[Security.Principal.WindowsIdentity]::GetCurrent().User.Value` を試験用の SID に置き換えた（どちらも Linux では使えない）
- Win32 の秘密鍵のアクセス権の確かめの代わりに、Linux の `ssh-keygen` が 0644 の秘密鍵を読まないことを使った

結果:

- 変数が空のまま: 手順 7・9・10、更新の手順 1、ロールバックの手順 1〜3 は `中断: 手順 2 の …` で止まった
- 手順 3: 2 つの代役の版、`Test-Path` の 3 つの値、`GIT_SSH= GIT_SSH_COMMAND= HOME=` の行が出た（`HOME` を消した環境）
- 手順 4（鍵が無い）: 鍵の対が作られた。2 回目は `既にある: …（この鍵を使う）` だけが出て、秘密鍵は変わらなかった
- 手順 4（秘密鍵だけ）: `公開鍵を作り直した: …` が出て、1 行の公開鍵ができた。鍵の欄は元の公開鍵と同じで、先頭は `ssh-`（BOM 無し）。秘密鍵は変わらなかった
- 手順 4（秘密鍵だけで 0644）: `中断: … から ed25519 の公開鍵を作れなかった` で止まり、公開鍵のファイルはできなかった
  - その前に、Linux の `ssh-keygen` の `UNPROTECTED PRIVATE KEY FILE!` と `Load key "…": bad permissions` が出た
  - 0600 に直して貼り直すと、作り直した
- 手順 6: `icacls.exe` に、`<鍵> /reset`（2 つ）、`<鍵> /inheritance:r /grant:r *<SID>:F /grant:r *S-1-5-18:F /grant:r *S-1-5-32-544:F`（8 つ）、`<鍵>`（1 つ）の引数が渡った
- 手順 7（config が無い）: 印の付いた 7 行ができ、先頭は `23 20 42`（`# B`。BOM 無し）。2 つの代役の `-G` の両方で、`user`・`hostname`・`identitiesonly`・`identityfile` の 4 行が出た
- 手順 7（末尾に改行の無い `Host github.com` / `  User git` の config）: 前の行の後ろに改行を入れてから 7 行を足した（[完了時点の状態](#完了時点の状態)）
- 手順 7 の止まり方（config は変わらなかった）:
  - 同じ `SSH_ALIAS` で 2 回目に貼ると、`中断: Host <SSH_ALIAS> は … にもうある`
  - 前からある config の 1 行目が `Host=<SSH_ALIAS>`・`host = <SSH_ALIAS>`・`Host github.com <SSH_ALIAS>` のときも、同じ `中断:`
  - BOM 付きの config では `中断: … の先頭に BOM がある …`。`SSH_ALIAS` に空白を入れると `中断: 手順 2 の値は、…`（config は作られなかった）
- 手順 7 で止めないもの: 1 行目が `HostName <SSH_ALIAS>` や `Host <SSH_ALIAS>2` の config には足した。前の方に `Host *` / `  User someoneelse` があると、2 つの `-G` の `user` は `someoneelse` だった
- 手順 9（`~/.ssh` の無いホーム）: `added` が出て、`~/.ssh` は 0700、`authorized_keys` は 0600 で、公開鍵の 1 行だけが入った。先頭は `ssh-` で、`ssh-keygen -lf` が指紋を出した
- 手順 9（`$OutputEncoding` を BOM 付きの UTF-8 にした窓。0644 で、末尾に改行の無い 1 行が既にある `authorized_keys`）:
  - この窓の pwsh 7.5.3 は、ネイティブのコマンドへのパイプの先頭に `EF BB BF` を付けた（`od` で確かめた）
  - `added` が出て、前の行の後ろに改行を入れてから足した。足した行の先頭は `ssh-`（BOM は捨てられた）で、`ssh-keygen -lf` が指紋を出した。モードは 0644 のままだった
  - 比べるために、`sed` の無い前の版のコマンドを同じ窓で流すと、行の先頭に `EF BB BF` が残り、`ssh-keygen -lf` は `is not a public key file` と出した
  - ホストのコマンドに、BOM と CR LF の付いた公開鍵の 1 行を `bash` で直接渡すと、BOM と CR の無い行が 0600 で入った
- 手順 9 の重なりと止まり方: 続けてもう 1 回貼ると、同じ行が 2 行になった。公開鍵のファイルが空のときは `中断: … が無いか、ed25519 の公開鍵の形でない` で止まり、`authorized_keys` は変わらなかった
- 手順 10: 代役のホームで `whoami` と `ls -lZ` が動いた（ラベルは `?`。SELinux の無い環境）。手順 9 の前から 0644 だった `authorized_keys` は `-rw-r--r--` のまま
- 更新の手順 1: 2 つの代役の版と、`user`・`hostname` が 2 組出た
- ロールバックの手順 1: この鍵の行（2 行あっても両方）を消し、ほかの行は残して `0` を出した
  - この鍵だけのときは、空の `authorized_keys` が残った
  - `authorized_keys` が無いときは、`grep` のエラー（2 つ）だけが出て、ファイルは作られなかった
  - 公開鍵のファイルが無いときは `中断: … が無いか、公開鍵の形でない（ホストの authorized_keys は変えない）` で止まり、`authorized_keys` は変わらなかった
- ロールバックの手順 2: 印の間の 7 行だけを消し、前の `Host github.com` と後ろに足した `Host after` のブロックは残った。2 回目は `中断: … に <SSH_ALIAS> の印の行が無い`、config が無いときは `中断: … が無い` で止まった
- ロールバックの手順 2（CP932 の config）: 1 行目が CP932 の `# 自宅のサーバー` の CR LF の config に、手順 7 で足してから消すと、元のバイトと同じに戻った
- ロールバックの手順 3（`<SSH_HOST>` の鍵が 2 種類の `known_hosts`）: `# Host <SSH_HOST> found: line 1`・`line 2`、`… known_hosts updated.`、`Original contents retained as … known_hosts.old` が出た
  - ほかのホストの行は残った
- ロールバックの手順 4: `False` が 2 行出た

**模擬と見直しで見つけて直したこと**:

- 最初の版のロールバックの手順 1 は、`$k = if (Test-Path …) { … }` で鍵を取っていた
  - 公開鍵のファイルが無いと、`$k` は空のコレクションのように振る舞い、`$k -notmatch '^AAAA…'` が偽になって `中断:` で止まらなかった
  - 代役のホストでは、空の鍵のまま `grep -vF -- ~/.ssh/authorized_keys` が動き（パスがパターンになり、標準入力を読む）、`authorized_keys` が空になった
  - `$k` を空の文字列から始め、`[string]` にしてから比べる形に直し、止まることを確かめた
  - 手順 9 の公開鍵の形の確かめも、空のファイルで同じことが起きるので `[string]` にした
  - PowerShell 7.5.3 で確かめた。Windows PowerShell 5.1 での振る舞いは確かめていない
- 前の版のロールバックの手順 2 は、config を `[IO.File]::ReadAllText` で読み、BOM の無い UTF-8 で書き戻していた
  - CP932 のコメントのある config（上の模擬と同じもの）では、先頭が `23 20 8e a9 91 ee …` から `23 20 ef bf bd ef bf bd …`（U+FFFD の並び）に変わった
  - Latin-1（`28591`）でバイトのまま読み書きする形に直し、元のバイトに戻ることを確かめた
- 前の版の手順 9 は、BOM 付きの UTF-8 の `$OutputEncoding` の窓で、BOM の付いた行を足した（上の模擬の比べたもの）。ホストで `sed` で 1 行目の先頭の BOM を捨てる形に直した
- 前の版の手順 7 の正規表現（`^\s*Host\s+…`）は、`Host=<SSH_ALIAS>` に当たらなかった（pwsh で確かめた）。`Host` の後ろの `=` も受ける形に直した
- 前の版の手順 4 は、秘密鍵があれば公開鍵が無くても何もしなかった（手順 9 が `中断:` で止まる）。`ssh-keygen -y` で公開鍵を作り直す分かれ道を足した
- 実施手順の変数の手順を手順 2 に、確かめの手順を手順 3 に入れ替えた（ほかの Windows の手順書と同じ順）。この記録の手順の番号は、入れ替えた後のもの

#### 残っている未確認事項

1. Windows で、すべての手順を貼って通すこと
1. 手順 3 の実際の表示（`Get-Command` の順、Git の ssh の版）
1. Windows の `ssh-keygen` のパスフレーズの問いと、作った秘密鍵のアクセス権（`icacls` の表示）。手順 6 の `/reset` と `/inheritance:r` の後の表示
1. 手順 4 の `ssh-keygen -y`（公開鍵の作り直し）のパスフレーズの問いと、秘密鍵のアクセス権が悪いときの表示
1. 手順 7 の `Add-Content -Encoding ascii` が CR LF で書くこと。Windows と Git の ssh の `-G` の実際の出力と、BOM 付きの config で Git の ssh と git が止まること
1. config のアクセス権が悪いときの `Bad owner or permissions on …` と、手順 6 のブロックを config に当てて直ること
1. 手順 9 で、パイプで公開鍵を渡しながら、ホスト鍵の問いとパスワードをコンソールから読むこと（Win32-OpenSSH のソースでは、パスワードは `conin$` から読む）
1. `$OutputEncoding` を UTF-8 にした Windows PowerShell 5.1 が、ネイティブのコマンドへのパイプの先頭に BOM を付けるか（手順 9 は、付いても捨てる）
1. 手順 10 の鍵でのログインと、`ls -lZ` の `ssh_home_t`
1. 手順 11 の WezTerm の起動メニュー
1. 標準の AlmaLinux 10 の ISO で入れたホストで、パスワードの SSH ログインが既定で通ること（`sshd -T`）
1. 更新とロールバック
1. 鍵交換の方式（`ssh -v` の `kex: algorithm:`。Windows の 9.5p2 と Git の 10.5p1 で違うか）
