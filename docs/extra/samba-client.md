# Samba クライアントの注意点

[手順書](../samba.md#samba-クライアント)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/samba-client.md)・[参考資料](../reference/samba-client.md)

- 「手順 N」は[手順書](../samba.md#samba-クライアント)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **サーバーに届かないとき**（VM で測った値）
  - マウントしていない状態でアクセスすると、`ls: cannot open directory '<MOUNT_POINT>': No such device` で失敗する。接続を断られると 1 秒以内、応答が無いと約 11 秒
  - 接続に失敗すると、`systemctl --failed` に `mnt-<SHARE>.mount` が出て、`systemctl is-system-running` が `degraded` になる。サーバーに届くようになってからアクセスし直す
  - **マウントしている間に届かなくなると、ファイルを開くコマンドが長時間止まることがある**。サーバーへの接続を確認してからアクセスし直す
  - 使っていなければ、届かなくても 1 分の idle-timeout で外れた
- **外出先から WireGuard 越しに使うとき**: トンネルを張ってからアクセスする
  - `SERVER` を LAN 側の IP にしておくと、fstab の 1 行を LAN の中でも外でも使える。[WireGuard: AlmaLinux 10 の PC からつなぐ](../wireguard.md#wireguard-almalinux-10-の-pc-からつなぐ)で取り込む conf の `AllowedIPs` に、拠点の LAN が入っているため
- **サーバーで直接変えたもの**（サーバーのシェルや Syncthing などで、Samba を通さずに）
  - samba.md の今のサーバー（`smb3 directory leases = no`）なら、`ls` にすぐ出る。消したファイルを `stat` で引くと、約 1 秒はまだあるように見える（`actimeo=1`）
  - サーバーを変えられないときは、マウントのオプションに `nohandlecache` を足す
- **GNOME Files（`smb://`）は、サーバーで変えたものを自動では出さない**: F5 ですぐ出る。gvfs はディレクトリのリースを使わないので、サーバーの設定によらない（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/samba-client.md)）
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
    - その接続を閉じるか、サインアウトしてサインインし直してから、[Windows 11 で使う](../samba.md#windows-11-で-samba-クライアントを使う)の手順 5 を貼り直す
    - samba.md の `[root]`・`[home]` は同じユーザーでつなぐので、`[homes]` と並べて割り当てられる
  - **サインインのときにサーバーに届かないと、ドライブに赤い × が付く**: すべてのネットワーク ドライブを再接続できなかった旨の通知も出る。サーバーに届くようになってから、エクスプローラーでドライブを開き直す
    - 外出先では、先に WireGuard のトンネルを張る。`SERVER` を LAN 側の IP にしておけば、LAN の中でも外でも同じ割り当てを使える
  - **管理者の窓からは、割り当てたドライブが見えない**: 管理者の PowerShell・Windows Terminal の管理者のタブ・`sudo` では、ドライブ文字ではなく `\\<SERVER>\<SHARE>` を使う
  - **SMB の NTLM のブロックを入れると、割り当てられなくなる**
    - 24H2 から選べる設定（`Set-SmbClientConfiguration -BlockNTLM $true` か、グループ ポリシーの「Block NTLM (LM, NTLM, NTLMv2)」）で、既定では入っていない
    - samba.md のサーバーは Kerberos を使わず、NTLMv2 で認証するため
    - 入れるなら、グループ ポリシーの「Block NTLM Server Exception List」に `<SERVER>` を足す（[参考資料](../reference/samba-client.md#選択した方針)）
  - **パスワードを変えたら**: サーバーで変え、[Windows 11 の更新](../samba.md#samba-クライアント-windows-11-の更新)を行う
