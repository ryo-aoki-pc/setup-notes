# Samba の共有を AlmaLinux 10 と Windows 11 から使う手順（cifs-utils + fstab の自動マウント / GNOME Files / Windows のネットワーク ドライブ）のロールバックと注意点

[手順書](../samba-client.md)・[検証記録](../verification/samba-client.md)・[参考資料](../reference/samba-client.md)

- 「手順 N」は[手順書](../samba-client.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)
- 手順 1 の変数を設定したシェルで、上から順に貼る（新しいシェルなら、手順 1 の 2 つのブロックを貼り直してから）
- GNOME Files でつないだままなら、先に [GNOME Files で開く（任意）](../samba-client.md#gnome-files-で開く任意)の手順 5 を貼る
- この節は、`MOUNT_POINT` の行だけを fstab から消す。ほかの共有の行は残る

1. 自動マウントを止め、マウントを外す。

   ```bash
   if [ -z "${MOUNT_POINT}" ]; then echo '中断: 手順 1 の MOUNT_POINT が空のまま。手順 1 を貼り直す' >&2; else
     sudo systemctl stop "$(systemd-escape -p --suffix=automount "${MOUNT_POINT}")" "$(systemd-escape -p --suffix=mount "${MOUNT_POINT}")"
   fi
   ```

   - 何も出ずに終わればよい

1. `/etc/fstab` からその行を消し、systemd に読み直させる。

   ```bash
   if [ -z "${MOUNT_POINT}" ]; then
     echo '中断: 手順 1 の MOUNT_POINT が空のまま。手順 1 を貼り直す' >&2
   elif findmnt "${MOUNT_POINT}" > /dev/null; then
     echo "中断: ${MOUNT_POINT} がまだマウントされている（この節の手順 1 を貼り直す）" >&2
   elif ! awk -v mp="${MOUNT_POINT}" '$1 !~ /^#/ && $2 == mp && $3 == "cifs" { f = 1 } END { exit !f }' /etc/fstab; then
     echo "中断: /etc/fstab に ${MOUNT_POINT} の cifs の行が無い" >&2
   else
     sudo cp -a /etc/fstab /etc/fstab.bak-samba-client &&
     awk -v mp="${MOUNT_POINT}" '!($1 !~ /^#/ && $2 == mp && $3 == "cifs")' /etc/fstab.bak-samba-client | sudo tee /etc/fstab > /dev/null &&
     sudo systemctl daemon-reload &&
     sudo findmnt --verify
     diff /etc/fstab.bak-samba-client /etc/fstab
   fi
   ```

   - `Success, no errors or warnings detected` が出ればよい
   - `diff` は、`15d14` のような行と、消した 1 行（`< //<SERVER>/<SHARE> <MOUNT_POINT> cifs …`）だけを出す
   - 消す前の fstab は、`/etc/fstab.bak-samba-client` に残る
   - `/etc/fstab.bak-samba-client` が要らなければ消す

1. マウント先と資格情報ファイルを消す。

   ```bash
   if [ -z "${MOUNT_POINT}" ] || [ -z "${SMB_USER}" ] || [ -z "${SERVER}" ]; then
     echo '中断: 手順 1 の変数が空のまま。手順 1 を貼り直す' >&2
   else
     sudo rmdir "${MOUNT_POINT}"
     if grep -qF "credentials=/root/smb-${SMB_USER}@${SERVER}.cred," /etc/fstab; then
       echo '資格情報ファイルは、/etc/fstab のほかの行が使っているので残す'
     else
       sudo rm -f "/root/smb-${SMB_USER}@${SERVER}.cred"
     fi
   fi
   ```

   - 何も出ずに終わればよい
   - 同じサーバーの別の共有が同じ資格情報ファイルを使っていれば、その旨を表示して残す

1. 手順 2 で cifs-utils を新しく入れたときだけ、cifs-utils を消す。

   ```bash
   sudo dnf remove cifs-utils
   ```

   - Workstation で入れた PC には最初から入っているので、消さない
   - 手順 2 で依存として入ったもの（`samba-client-libs` など）も、ほかに使うものが無ければ一緒に消える
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. [GNOME Files で開く（任意）](../samba-client.md#gnome-files-で開く任意)の手順 2 で入れたときだけ、gvfs-smb と gvfs-fuse を消す。

   ```bash
   sudo dnf remove gvfs-smb gvfs-fuse
   ```

   - GNOME を入れた PC には最初から入っているので、消さない（消すと、「ファイル」から SMB につなげなくなる）
   - トランザクション表を見て `[y/N]` に答える

---

## Windows 11 のロールバック

- [Windows 11 で使う](../samba-client.md#windows-11-で使う)の手順 2 の変数を設定した、管理者ではない Windows PowerShell（5.1）に、上から順に貼る。新しい窓なら、その手順 2 のブロックを貼り直してから貼る
- `[root]`・`[home]` も割り当てたなら、その手順 2 の 3 つ目のブロックの `DRIVE` をその文字に書き換えて貼り、この節の手順 1 を文字ごとに貼る
- 共有の中のファイルと、サーバーの Samba ユーザーは変わらない（サーバーを戻すのは [samba.md のロールバック](samba.md#ロールバック)）

1. ドライブの割り当てを外し、サインインのときにつなぎ直さないようにする。

   ```powershell
   if (-not $DRIVE) {
     Write-Error '中断: Windows 11 で使うの手順 2 の DRIVE が空のまま。値を入れて貼り直す'
   } else {
     Remove-SmbMapping -LocalPath $DRIVE -UpdateProfile -Force
     Get-SmbMapping -LocalPath $DRIVE -ErrorAction SilentlyContinue
     Test-Path -LiteralPath ('HKCU:\Network\' + $DRIVE.TrimEnd(':'))
   }
   ```

   - `Get-SmbMapping` は何も出さず、`False` が出ればよい
   - ドライブの中のファイルを開いているアプリがあると、外せないことがある。閉じてから貼り直す
   - エクスプローラーには、サインインし直すまでドライブが残って見えることがある

1. 同じサーバーのほかの割り当てを残さないときだけ、資格情報マネージャーから共有の資格情報を消す。

   ```powershell
   if (-not $SERVER) {
     Write-Error '中断: Windows 11 で使うの手順 2 の SERVER が空のまま。値を入れて貼り直す'
   } else {
     cmdkey "/delete:$SERVER"
     cmdkey "/list:$SERVER"
   }
   ```

   - 消した旨の 1 行の後の一覧に、`<SERVER>` の資格情報が出なければよい
   - 同じサーバーのほかの割り当て（`[root]` など）を残すなら、この手順は行わない（残す割り当てが、この資格情報でつなぐ）
   - **注意**: [Windows 11 で使う](../samba-client.md#windows-11-で使う)の手順 4 より前からあった `<SERVER>` の資格情報（同じ節の手順 3 で見たもの）も、その手順 4 で置き換わっているので、ここで消える。エクスプローラーで開くときに入れ直す

---

## 注意点

- **サーバーに届かないとき**（VM で測った値）
  - マウントしていない状態でアクセスすると、`ls: cannot open directory '<MOUNT_POINT>': No such device` で失敗する。接続を断られると 1 秒以内、応答が無いと約 11 秒
  - 接続に失敗すると、`systemctl --failed` に `mnt-<SHARE>.mount` が出て、`systemctl is-system-running` が `degraded` になる。サーバーに届くようになってからアクセスし直す
  - **マウントしている間に届かなくなると、ファイルを開くコマンドが長時間止まることがある**。サーバーへの接続を確認してからアクセスし直す
  - 使っていなければ、届かなくても 1 分の idle-timeout で外れた
- **外出先から WireGuard 越しに使うとき**: トンネルを張ってからアクセスする
  - `SERVER` を LAN 側の IP にしておくと、fstab の 1 行を LAN の中でも外でも使える。[wireguard-road-warrior.md](../wireguard-road-warrior.md) の `AllowedIPs` に拠点の LAN が入っているため
- **サーバーで直接変えたもの**（サーバーのシェルや Syncthing などで、Samba を通さずに）
  - samba.md の今のサーバー（`smb3 directory leases = no`）なら、`ls` にすぐ出る。消したファイルを `stat` で引くと、約 1 秒はまだあるように見える（`actimeo=1`）
  - サーバーを変えられないときは、マウントのオプションに `nohandlecache` を足す
- **GNOME Files（`smb://`）は、サーバーで変えたものを自動では出さない**: F5 ですぐ出る。gvfs はディレクトリのリースを使わないので、サーバーの設定によらない（[検証記録](../verification/samba-client.md)）
- **`sudo mount -a` はエラーを出す**: 自動マウントの行について、1 回目は `mount error(16): Device or resource busy`
  - パスをたどった時点で systemd がマウントし、そのあと mount.cifs が同じ場所にもう一度マウントしようとするため
- **資格情報ファイルは平文**: root なら読める。samba.md では Samba のパスワードは OS のパスワードと別なので、OS のパスワードと同じにしない
- **パスワードを変えたら**: サーバーで変え（samba.md では `sudo smbpasswd <SMB_USER>`）、この PC で手順 3・4 を貼り直す
- **空白を含むユーザー名・共有名・マウント先は扱わない**: 手順 6 で中断する（fstab の欄を空白で区切るため）
- **SELinux**: マウントしたファイルの型は `cifs_t`
  - ログインしたユーザーのプログラムは、そのまま読み書きできる
  - 制限のあるサービス（Apache など）から使うなら、そのサービスの boolean（`httpd_use_cifs` など）が要る
- **貼り方**: `sudo` の後ろに行が続くブロックは、どれも 1 つのコマンド（`if … fi` や `{ … }`）にしてある
  - ブラケットペーストが効かない端末で複数行を貼ると、途中の `sudo` が後ろの行を読み取って捨てるため、ブロックを `{ }` で囲む
- **Windows 11 の注意点**
  - **Windows 11 Home の PC からの接続は、全体には署名されない**
    - 24H2 の Pro・Enterprise・Education は SMB の署名を必ず求めるが、Home は求めない
    - samba.md のサーバーも署名を求めない（`server signing` の既定）ので、Home からはどちらも求めない接続になる
  - **クライアントの署名とゲストの設定は変えない**: Pro の既定（署名が必須・ゲストの接続は禁止）のままつながる
    - samba.md のサーバーはユーザーとパスワードで認証し（ゲストにしない）、SMB3 の署名にも応じるため
    - `Set-SmbClientConfiguration` の `RequireSecuritySignature` と `EnableInsecureGuestLogons` は変えない
  - **エラー 1219**: 同じサーバーに別のユーザー名でつないでいると、割り当てが断られる（エクスプローラーで別の資格情報で開いた接続など）
    - その接続を閉じるか、サインアウトしてサインインし直してから、[Windows 11 で使う](../samba-client.md#windows-11-で使う)の手順 5 を貼り直す
    - samba.md の `[root]`・`[home]` は同じユーザーでつなぐので、`[homes]` と並べて割り当てられる
  - **サインインのときにサーバーに届かないと、ドライブに赤い × が付く**: すべてのネットワーク ドライブを再接続できなかった旨の通知も出る。サーバーに届くようになってから、エクスプローラーでドライブを開き直す
    - 外出先では、先に WireGuard のトンネルを張る。`SERVER` を LAN 側の IP にしておけば、LAN の中でも外でも同じ割り当てを使える
  - **管理者の窓からは、割り当てたドライブが見えない**: 管理者の PowerShell・Windows Terminal の管理者のタブ・`sudo` では、ドライブ文字ではなく `\\<SERVER>\<SHARE>` を使う
  - **SMB の NTLM のブロックを入れると、割り当てられなくなる**
    - 24H2 から選べる設定（`Set-SmbClientConfiguration -BlockNTLM $true` か、グループ ポリシーの「Block NTLM (LM, NTLM, NTLMv2)」）で、既定では入っていない
    - samba.md のサーバーは Kerberos を使わず、NTLMv2 で認証するため
    - 入れるなら、グループ ポリシーの「Block NTLM Server Exception List」に `<SERVER>` を足す（[参考資料](../reference/samba-client.md#選択した方針)）
  - **パスワードを変えたら**: サーバーで変え、[Windows 11 の更新](../samba-client.md#windows-11-の更新)を行う
