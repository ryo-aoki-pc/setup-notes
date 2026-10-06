# GNOME のデスクトップ共有の手順（PC の画面のデスクトップに RDP でつなぐ。CLI だけで設定する）の検証記録

[手順書](../gnome-desktop-sharing.md)

## 補足

### 対象と検証環境

- **目的**: PC の画面で GNOME にログインしているユーザーのデスクトップを、別のマシンの RDP クライアントから共有して使う。設定は、そのユーザーの SSH のシェルから CLI だけで行う
- **方式**: ユーザーのモードの gnome-remote-desktop（オプション無しの `grdctl`、ユーザーの `gnome-remote-desktop.service`）。RHEL 10 の文書の「1.1 Enabling desktop sharing on the server by using GNOME」と同じ仕組みを、設定アプリの代わりに `grdctl` で設定する
- **状態**: **x86_64 の VirtualBox の VM（AlmaLinux 10.2 の Workstation のクリーンインストール）で本実行した（2026-10-07。[付録](#付録-virtualbox-の-vm-での本実行2026-10-07)）。実機では流していない**
  - 通したもの: この文書のブロックを、SSH でログインした共有するユーザーの対話の bash に、ブラケットペーストで貼った。書き換えたのは手順 1 の `SERVER_IP` と、任意節の `LAN_SUBNET` だけ
    - PR の最初の版（`81012d3`）: 前提の gnome-power.md 手順 1〜4 → 実施手順 1〜10 → [見るだけにする（任意）](../gnome-desktop-sharing.md#見るだけにする任意) → [ロールバック](../gnome-desktop-sharing.md#ロールバック)の手順 1・3・4
    - レビューで直した版（`f3450e6`）: 実施手順 1〜10 → [接続元を LAN に絞る（任意）](../gnome-desktop-sharing.md#接続元を-lan-に絞る任意) → [自動ログインで使う（任意）](../gnome-desktop-sharing.md#自動ログインで使う任意)
    - この検証で直した版: 直した 5 つのブロック（実施手順 9、自動ログインで使うの手順 4・5・6・8）を流し直し、続けて PC を再起動して PC の画面でパスワードでログインし、ロールバックの手順 2〜4
  - 確認したこと
    - 実施手順 2・6〜9 と各任意節の確認の箇条書きの出力が、手順書の記載どおりに出る（手順 2 の 8 行、`grdctl status` の各行、`ss` の 1 行、TLS のプローブの 3 つ）
    - FreeRDP 3.10.3 で、`Thumbprint:` が `TLS fingerprint` と一致し、PC の画面のデスクトップが PC の解像度（1280x800）のまま出る。クライアントのクリックと文字の入力が PC の画面に出て、PC の上部バーに共有中の印が出る
    - Windows 11 の「リモート デスクトップ接続」（mstsc 10.0.26100.8875）で、ホストオンリーのネットワーク越しに NLA で接続でき、キーの入力が PC に届き、画面の更新が送られる。証明書の「拇印」は SHA-1 で、手順 9 の `sha1 Fingerprint=` と一致する
    - 見るだけにすると、つないでいるクライアントの入力がすぐに効かなくなり、戻すとすぐに効く
    - LAN に絞った後は、`LAN_SUBNET` の外（VirtualBox の NAT 経由、送信元 10.0.2.2）からは接続できず、中（192.168.56.0/24）からはつながる
    - PC の画面のセッションをロックすると、RDP の接続がすぐに切れ（`ERRINFO_LOGOFF_BY_USER`）、ロック中の新しい接続は認証の後に断られる（`Session creation inhibited`）。ロックを解くと、またつながる
    - 自動ログイン: パスワードの無いキーリングへ移した資格情報で、PC の画面にキーリングの窓を出さずにつながる（起動画面を止めた後）
    - 2 回のロールバックの後、firewalld・dconf・証明書・資格情報・`custom.conf`・起動の引数が実施前に戻る（[完了時点の状態](#完了時点の状態)）
    - SELinux が Enforcing のまま、AVC は出なかった
  - この検証で直したこと（[付録の「見つかった問題と直したこと」](#見つかった問題と直したこと)）
    - 実施手順 4: 初めて設定するときに出る `BIO_new failed for certificate` と `RDP server certificate is invalid.` の注記を足した
    - 実施手順 9・10: Windows の拇印（SHA-1）と比べる値を手順 9 で出し、手順 10 に Windows での比べ方と、FreeRDP の初回の警告を足した。ログを見るコマンドを `journalctl -b _SYSTEMD_USER_UNIT=…` に直した
    - 自動ログインで使う: 起動画面（plymouth）を止める手順を足し（新しい手順 4）、再起動を `sudo` 無しの `systemctl reboot -i` に直し（手順 5）、確認に `Active` を足し（手順 6）、戻す手順で起動の引数も戻す（手順 8）
  - 確認していないこと
    - 実機（物理のモニター・キーボード・マウス）、aarch64、サスペンドできる実機での前提の手順 3・4 の効き目
    - Windows の「リモート デスクトップ接続」の窓に PC の画面が写ること（窓の中身が DirectX の面で、撮影できなかった）。Windows の資格情報の窓での入力（検証では `cmdkey` で先に登録した）
    - 無操作で暗くなって切れること（ロックで切れることは確かめた）、PC の上部バーの印から共有を止めること
    - 後からリモートログインを有効にしたとき、ほかのユーザーのヘッドレスのセッションとの併用、同じユーザーのヘッドレスのセッションが有効なときの手順 2・6 の中断、手順 2 の最後の行が `0` でないとき
    - 設定アプリの「リモート デスクトップ」との行き来、`passwd` でパスワードを変えたとき、Homebrew が PATH の先頭にあるホスト
    - ロールバックの手順 4 の「生成の途中で止まっていた」の分岐、退避が不完全なときの中断
  - 2026-10-06 の記録（ブロックを書いた時点の、資料とコンテナでの模擬）は、[付録](#付録-資料とブロックの確認2026-10-06)に残す
- 下表は、VM に入っていた版（2026-10-07 に `rpm -q` で確かめた。手順書を書いたときの対象〔2026-10-06 の最新〕と同じ）

| 項目 | 値 |
|---|---|
| OS | AlmaLinux 10.2 (Lavender Lion)、GNOME の Workstation、kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing |
| GNOME | `gnome-remote-desktop-49.3-4.el10_2`、`gnome-shell-49.4-9.el10_2.alma.1`、`mutter-49.4-4.el10_2`、`gdm-47.0-24.el10_2`、`gnome-session-46.0-11.el10`、`gnome-control-center-47.7-7.el10` |
| キーリング | `gnome-keyring-42.1-20.el10`、`libsecret-0.21.2-8.el10`、`glib2-2.80.4-12.el10_2.22`、`python3-gobject-base-3.46.0-7.el10` |
| そのほか | `firewalld-2.4.3-4.el10_2`、`openssl-3.5.8-1.el10_2.alma.1`、`systemd-257-23.el10_2.2.alma.1`、`plymouth-24.004.60-17.el10.alma.2`、`polkit-125-4.el10_2.1`、`grubby-8.40-83.el10.alma.1` |
| クライアント | 別の VM の AppStream の `freerdp-3.10.3-12.el10_2.13`（`xfreerdp`）と、ホストの Windows 11 Pro 10.0.26300 の「リモート デスクトップ接続」（`mstsc.exe` 10.0.26100.8875） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../gnome-desktop-sharing.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${SERVER_IP}` | クライアントが接続に使う PC の IP アドレス | `192.168.10.100` |
> | `${SERVER_NAME}` / `${SERVER_FQDN}` | PC のホスト名 / FQDN（`hostname` / `hostname -f` から自動で入る） | `my-pc` / `my-pc.lan` |
> | `${RDP_PORT}` | RDP で待ち受けるポート（リモートログインのデーモンが有効なら 3390、無ければ 3389。自動で入る） | `3389` |
> | `${LAN_SUBNET}` | LAN のサブネット。[接続元を LAN に絞る](../gnome-desktop-sharing.md#接続元を-lan-に絞る任意)ときだけ、その節で設定する | `192.168.10.0/24` |
>
> 出力例・ログの中の値は `<HOSTNAME>` / `<SERVER_IP>` / `<RDP_PORT>` / `<USER>` / `<UID>` / `<SESSION_ID>` / `<N>` のプレースホルダで書いてある。`<...>` を含むコマンドは bash のコードブロックには置かない。2026-10-07 の付録の値（`verifier`・`pr100-pc.test`・`192.168.56.81` など）は、検証用の VM の試験用の値。

### 実施前の状態

- 2026-10-07 の VM（クリーンインストールのスナップショットから作った直後）
  - 上の表の版。システムのリモートログイン（`gnome-remote-desktop.service`）・ユーザーの `gnome-remote-desktop.service`・`gnome-remote-desktop-headless.service` は、どれも `disabled`
  - dconf の `/org/gnome/desktop/remote-desktop/` は空。`/etc/gdm/custom.conf` は RPM の既定（`AutomaticLogin` の行は無い）
  - firewalld は `public` ゾーン（`cockpit`・`dhcpv6-client`・`ssh`。ポートと rich rule は無し）
  - `~/.local/share/keyrings`・`~/.local/share/gnome-remote-desktop`・`~/.local/state` は無い（PC の画面で 1 度もログインしていない）
  - logind の `CanSuspend` は `challenge`（サスペンドできる PC として、前提の gnome-power.md 手順 3・4 も行った）

### 完了時点の状態

- 2026-10-07 の 2 回目のロールバックの後
  - dconf の `/org/gnome/desktop/remote-desktop/` は `[rdp]` の `enable=false` だけ（`grdctl rdp disable` が書く。既定の値と同じ）
  - firewalld のポートと rich rule は空。ユーザーの `gnome-remote-desktop.service` は `disabled`・`inactive` で、3389/tcp は待ち受けていない
  - RDP の資格情報は、ログインのキーリングにも無い（`aoao 0 0`）。`rdp.keyring` は無い
  - 証明書と鍵、退避先（`~/.local/state/gnome-desktop-sharing-setup`）、`~/rdp_tls_probe.py` は無い。空の `~/.local/share/gnome-remote-desktop` が残る
  - `/etc/gdm/custom.conf` に `AutomaticLogin` の行は無い。起動の引数に `rd.plymouth=0 plymouth.enable=0` は無い
  - 前提の gnome-power.md で変えた値は残る（手順書のとおり）
- ホスト（Windows）: 検証で登録した `TERMSRV/<SERVER_IP>` の資格情報は消した。`HKCU\Software\Microsoft\Terminal Server Client` と `Documents\Default.rdp` は検証の前と同じ

### 付録: VirtualBox の VM での本実行（2026-10-07）

#### 環境と準備

| 項目 | 値 |
|---|---|
| ホスト | Windows 11 Pro 10.0.26300、VirtualBox 7.2.20（Hyper-V の NEM） |
| VM | [AlmaLinux 10 の環境構築の検証](../almalinux-vm-verification.md)の `clean-install` スナップショット（公式 ISO の Workstation）から、リンククローンを 2 台新しく作った。PC 役（共有する側、RAM 6 GiB）とクライアント役（RAM 4 GiB） |
| CPU | 1 vCPU。2 vCPU にした初回は、2 台とも UEFI の `CpuMpPei` か、カーネルの起動の途中（`evm: HMAC attrs` の後）で止まったので、前回の検証と同じ 1 vCPU に戻した |
| ネットワーク | NAT（SSH 用の転送）と、ホストオンリー `192.168.56.0/24`（PC 役 `192.168.56.81`、クライアント役 `192.168.56.82`、ホスト `192.168.56.1`）。LAN の外の試験だけ、PC 役の NAT に `127.0.0.1:23389 → 3389` の転送を足した |
| 試験用の値 | ユーザー `verifier`、PC 役のホスト名 `pr100-pc.test`、RDP のユーザー名 `rdpuser`（パスワードは VM 専用の乱数。リポジトリには載せない） |

- 手順書の外の準備
  - 2 台とも、ホストオンリーの接続を `nmcli` で作り、ホスト名を付け、`~/.config/gnome-initial-setup-done` を置いた。マウスを USB タブレットにした（VM の画面をクリックするため）
  - PC の画面でのログインは、VirtualBox のキーボード入力でパスワードを打った（GDM のパスワードでのログイン）。最初に出たツアーの案内は「スキップ」で閉じた
  - クライアント役には `dnf install freerdp` で FreeRDP を入れた（既定のミラーの 1 つが止まったので、このときだけ `repo.almalinux.org` を指定した）。画面を消さない設定とサスペンドの mask も行った
  - FreeRDP は、クライアント役の SSH の端末から、GNOME のセッションの XWayland（`DISPLAY=:0`）に窓を出して動かした。証明書・`Domain:`・`Password:` の問いは端末で答えた
  - 画面は `VBoxManage controlvm … screenshotpng` で撮り、クライアント役の画面へのクリックとキーは VirtualBox の入力で送った
- 手順書のブロックは、SSH の対話の bash に、ブラケットペーストで 1 つずつ貼り、プロンプトが戻ってから次を貼った。手順 5 などの問いには、問いが出てから答えた
- 前提の gnome-power.md 手順 1〜4 は、記載どおり（`uint32 0`・`false`・4 行・3 行・`masked` が 5 行）

#### 実施手順（81012d3 と f3450e6 で 1 回ずつ）

- 手順 1: `RDP_PORT = 3389`（リモートログインは無効）。`SERVER_NAME` と `SERVER_FQDN` は `pr100-pc.test`
- 手順 2: f3450e6 の版で次の 8 行（81012d3 の版は最後の `0` が無い 7 行）

  ```text
   6 1000 verifier seat0 6738 user    tty2  no -
  ScreenCast: ok
  b false
  uint32 0
  false
  false
  disabled
  0
  ```

- 手順 3: `rdp-tls.crt`（`-rw-r--r--`）と `rdp-tls.key`（`-rw-------`）、`設定の退避と証明書の準備が完了`。退避した 5 つのキーは、どれも未設定（空のファイル）だった
- 手順 4: 最初の `grdctl rdp set-tls-cert` が `[ERROR][com.freerdp.crypto] - [x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` を 1 回ずつ出した。残りの設定は入り、読み戻しは `negotiate-port false`・`port uint16 3389`・`tls-cert`・`tls-key`・`view-only false`
- 手順 5: `Username: ` と `Password: ` を聞かれ、PC の画面に窓は出なかった（パスワードでログインしたので、ログインのキーリングは開いている）
- 手順 6・7: `enabled`、`success` が 2 行と `3389/tcp`
- 手順 8: `Unit status: active`・`Status: enabled`・`Port: 3389`・`View-only: no`・`Negotiate port: no`・`Username: (hidden)`・`Password: (hidden)` と、`LISTEN 0 5 *:3389 *:* users:(("gnome-remote-de",pid=<N>,fd=10))`
- 手順 9: `selectedProtocol=0x2`、`TLSv1.3 TLS_AES_256_GCM_SHA384`、`fingerprint:` と `TLS fingerprint:` が一致、SAN は `DNS:pr100-pc.test, DNS:pr100-pc.test, DNS:192.168.56.81, IP Address:192.168.56.81`（`SERVER_NAME` と `SERVER_FQDN` が同じなので重なる）
  - このプローブの接続は、PC 側の journal に `client authentication failure` と `Network or intentional disconnect` を残す（NLA の前で切るため）
- 手順 10（FreeRDP）: `xfreerdp /v:192.168.56.81:3389 /u:rdpuser`
  - 保存した証明書が無い初めての接続でも、先に `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` と `Host key verification failed.` が出て、その後に `Certificate details`・`Thumbprint:`・`Do you trust the above certificate? (Y/T/N)` が出た。`Thumbprint:` は手順 8 の `TLS fingerprint` と一致
  - `Y` の後に `Domain:`（空のまま Enter）と `Password:` を聞かれ、`krb5_parse_name (Configuration file does not specify default realm)` の後に NTLM でつながった
  - 窓に PC の画面が 1280x800 のまま出た（窓はクライアントの画面からはみ出し、縮小されない）。PC の上部バーに共有中の印（オレンジ）が出た
  - クライアントの窓から、PC のアクティビティの画面を開き、`text editor` で検索してテキストエディターを起動し、文字を入力できた（PC の画面にもそのまま出た）
  - f3450e6 の版では証明書を作り直したので、`!!!Certificate for 192.168.56.81:3389 (RDP-Server) has changed!!!` と新旧の `Thumbprint:` が並んで聞かれた
- 手順 10 の最後の箇条書きの `journalctl --user -b -u gnome-remote-desktop.service` は `No journal files were found.` だった（`/var/log/journal` が無く、journal は揮発）。`journalctl -b _SYSTEMD_USER_UNIT=gnome-remote-desktop.service` は、`sudo` 無しで読めた（`wheel` のユーザー）

クライアント役の FreeRDP の窓に写った、PC の画面のデスクトップ（81012d3 の手順 10。VirtualBox の VM の画面から、FreeRDP の窓の部分を切り出して 75% に縮小した。右上のオレンジが共有中の印）:

![FreeRDP: 192.168.56.81 の窓に、PC の上部バーの共有中の印と、クライアントから打った typed through RDP from pr100-client の文字が写っている](../images/gnome-desktop-sharing/freerdp-shared-desktop.png)

#### Windows の「リモート デスクトップ接続」

- ホストの `mstsc /v:192.168.56.81:3389`（資格情報は検証のときだけ `cmdkey /generic:TERMSRV/192.168.56.81` で先に登録し、終わってから消した）
- 警告の窓は「このリモート コンピューターの ID を識別できません。接続しますか?」で、証明書の名前（`pr100-pc.test`）と「この証明書は信頼された認証機関からのものではありません。」だけを出し、拇印は出さなかった
- 「証明書の表示」→「詳細」の「拇印」は、`828271180a0dcdb433606035519891545726d107`（1 回目の証明書）と `de7964917cc59c679638258a29f2b3e81cc9ac57`（作り直した証明書）。どちらも、その証明書の `openssl x509 -fingerprint -sha1`（`82:82:71:…`・`DE:79:64:…`）と同じ値で、SHA-256 の `TLS fingerprint` とは違う
  - 直した手順 9 の `sha1 Fingerprint=DE:79:64:91:7C:C5:9C:67:96:38:25:8A:29:F2:B3:E8:1C:C9:AC:57` と比べて一致した
- 「はい」でつながった。PC 側の journal に `RDP.RDPGFX` の `H264 (AVC444): true, H264 (AVC420): true` などが出て、PC の上部バーには共有中の印に加えてマイクの印も出た（FreeRDP では出なかった）
- mstsc の入力の窓へ直接送ったキー（` mstsc`）が、PC のテキストエディターに入った
- PC の画面を変えるたびに、PC からホストへ送ったバイト数が約 9〜10 万バイトずつ増え、確認応答も同じ値だった
- mstsc の窓の中身は、`PrintWindow` でも画面の取り込みでも黒く写った（描画が DirectX の面のため）。窓に PC の画面が写ることは、画像では確かめていない
- クライアント役の FreeRDP とホストの mstsc は、同時につながり、FreeRDP の窓も更新され続けた

#### 任意節

- 見るだけにする: 手順 1 で `View-only: yes`。つないだままのクライアントから打った文字は PC に入らなかった。手順 2 で `View-only: no` に戻すと、すぐに入った
- 接続元を LAN に絞る: `LAN_SUBNET=192.168.56.0/24` で、`success` が 3 行、`--list-ports` は空、rich rule は `rule family="ipv4" source address="192.168.56.0/24" port port="3389" protocol="tcp" accept`
  - 絞る前は、NAT 経由（送信元 10.0.2.2）とホストオンリー経由（送信元 192.168.56.1）の両方から、RDP のネゴシエーションと TLS が通った
  - 絞った後は、NAT 経由は時間切れでつながらず、ホストオンリー経由は通った。つないでいた FreeRDP（192.168.56.82）は切れなかった
- 自動ログインで使う（f3450e6 の版）
  - 手順 1: `移した先: /org/freedesktop/secrets/collection/rdp/1`。貼り直すと `すでに移してある: /org/freedesktop/secrets/collection/rdp/1`。`rdp.keyring` は、`display-name=rdp` などが読める暗号化されていないファイルだった
  - 手順 2: `aoao 1 "/org/freedesktop/secrets/collection/rdp/1" 0` と `b false`
  - 手順 3: `[daemon]`・`AutomaticLoginEnable=True`・`AutomaticLogin=verifier`
  - 手順 4（当時の再起動）: `sudo systemctl reboot` は `Operation inhibited by "verifier" (PID … "gnome-session-b", user verifier), reason is "user session inhibited".`・`User verifier is logged in on tty2.`・`User verifier is logged in on sshd.` で断られた。`sudo systemctl reboot -i` は `Call to Reboot failed: Interactive authentication required.`。`sudo` 無しの `systemctl reboot -i` は `==== AUTHENTICATING FOR org.freedesktop.login1.reboot-ignore-inhibit ====` とこのユーザーのパスワードを聞き、入れると再起動した
  - 再起動の後、GDM は自動でログインした（`Service=gdm-autologin`、tty2）。しかし約 22 秒後に plymouth が終わった直後、GDM が tty1 にログイン画面（greeter）を作り、tty1 が前に出た。自動ログインのセッションは `Active=no` になった
  - 手順 5（当時の確認）の出力は記載どおり（`Service=gdm-autologin`・`Unit status: active`・`Username: (hidden)`・`b true`・`b false`・`ss` の 1 行）だったが、手順 6（接続）は、認証は通るのに FreeRDP の窓が真っ黒だった（窓も既定の 1024x768 のまま）
  - 起動の引数を一般的な形（`rhgb quiet` を足し、検証用のシリアルコンソールを外す）にして再起動しても、同じく約 22 秒後にログイン画面が前に出た
  - `loginctl activate 1` は `Interactive authentication required.` で断られ、`sudo loginctl activate 1` で自動ログインのセッションが前に戻った。その後は RDP に PC のデスクトップが写った（PC の画面にキーリングの窓は出ていない）
  - 起動の引数に `rd.plymouth=0 plymouth.enable=0` を足して再起動すると、2 分以上たっても tty2 の自動ログインのセッションが前のままで、ログイン画面は出なかった。何も触らずに RDP で PC のデスクトップが写った
- 自動ログインで使う（この検証で直した版）
  - 手順 4（新しい手順）: `args=` の行の最後に `rhgb quiet rd.plymouth=0 plymouth.enable=0`
  - 手順 5: `systemctl reboot -i` は `==== AUTHENTICATING FOR org.freedesktop.login1.reboot ====` とパスワードを聞き、入れると再起動した（自動ログインのセッションからは、この操作だった）
  - 再起動の後、約 100 秒の間、tty2 の自動ログインのセッションが前のままで、ログイン画面は出なかった
  - 手順 6: `Service=gdm-autologin`・`Active=yes` の後、記載どおりの行が出た
  - 手順 7: FreeRDP でつながり、PC のデスクトップ（ログインした直後のアクティビティの画面）が写った。PC の画面にキーリングの窓は無かった。続けて、ホストの mstsc も同時につながった
  - 手順 8: `0`・`0`・`o "/"`。貼り直すと `0`・`0`・`rdp のキーリングは無い（消し済み）`。`custom.conf` と起動の引数が戻り、`rdp.keyring` が消えた
  - 戻した後、`systemctl reboot -i` で再起動すると、GDM のログイン画面が出た（自動ログインしない）

#### ロックと切断

- PC の画面のセッションを `loginctl lock-session` でロックすると、つないでいた FreeRDP がすぐに `ERRINFO_LOGOFF_BY_USER` で切れた。PC の journal は `Disconnected by EIS`
- ロック中も 3389/tcp は待ち受けていて、新しい接続は認証の後に `Broken pipe` で切れた。PC の journal は `Failed to start remote desktop session: … Session creation inhibited`
- PC の画面でパスワードを入れてロックを解くと、また FreeRDP でつながった

#### ロールバック

- 1 回目（81012d3 の実施手順と見るだけにするの後。手順は f3450e6 の版）: 手順 1 で `success` が 2 行と空の `--list-ports`、手順 3 で `disabled`、手順 4 で `sha256sum --check` が 2 つとも `完了`（OK）になって証明書と鍵を消した
  - 戻した後の dconf は `enable=false` だけで、空の `~/.local/share/gnome-remote-desktop` が残った。`grdctl status` は `TLS certificate:` が空に戻り、`BIO_new failed for certificate` を出した
- 2 回目（f3450e6 の実施手順・LAN に絞る・自動ログインと、その戻しの後。PC を再起動して PC の画面でパスワードでログインしてから）: 手順 1 の代わりに手順 2 で `success` が 2 行と空の rich rule、手順 3 で `disabled`、手順 4 で 2 つとも `完了` で削除。結果は[完了時点の状態](#完了時点の状態)
- 2 回目の後に、手順 3 を済ませていない状態で手順 4 と手順 6 を貼ると、それぞれ `中断: 手順 3 が完了していない。設定は変更しない` と `中断: 手順 3 が完了していない。有効にしない` で止まり、何も変わらなかった

#### 見つかった問題と直したこと

| 箇所 | 見つかったこと | 直したこと |
|---|---|---|
| 実施手順 4 | 初めて設定するときに `BIO_new failed for certificate` と `RDP server certificate is invalid.` が出る（ヘッドレスの手順書には同じ注記がある） | 害が無いことの箇条書きを足した |
| 実施手順 10 | Windows の窓は拇印を出さず、「詳細」の「拇印」は SHA-1 で、手順 8 の `TLS fingerprint`（SHA-256）とは比べられない | 手順 9 で `openssl x509 … -fingerprint -sha1` を出し、手順 10 に Windows での比べ方を書いた |
| 実施手順 10 | FreeRDP 3.10.3 は、初めての接続でも `REMOTE HOST IDENTIFICATION HAS CHANGED!` を出す | 続く `Thumbprint:` で判断する、と書いた |
| 実施手順 10 | `journalctl --user` は、既定の構成では `No journal files were found.` | ヘッドレスの手順書と同じ `journalctl -b _SYSTEMD_USER_UNIT=…` にした |
| 自動ログインで使う | `sudo systemctl reboot` も `sudo systemctl reboot -i` も断られ、PC を再起動できない | `sudo` 無しの `systemctl reboot -i` にして、パスワードを聞かれることを書いた |
| 自動ログインで使う | 自動ログインの約 22 秒後に GDM のログイン画面が前に出て、RDP の画面が真っ黒になる | 起動画面（plymouth）を止める手順を足し、確認に `Active` を足し、戻す手順で起動の引数も戻すようにした |

- 直した版の `bash` のブロック 25 個は、どれも `bash -n` を通った。直した 5 つのブロックは、上の「この検証で直した版」のとおり VM で流し直した（手順書の最終版のブロックと、流したブロックが同じことも確かめた）

### 付録: 資料とブロックの確認（2026-10-06）

- 書いた環境は、KVM の無いクラウドの Linux のコンテナ（Ubuntu 24.04、x86_64）。QEMU の TCG で AlmaLinux 10.2 の GenericCloud に Workstation のパッケージを入れる VM を用意し始めたが、`dnf upgrade` の途中で、利用者の判断で VM での検証を見送った。このときは VM で手順書のブロックを 1 つも貼っていない
- 手順書の確認の箇条書きにある出力（`grdctl status` の行、`ss` の `users:(("gnome-remote-de",…))` など）は、このときは上流のソースから書いたもので、実物の出力ではなかった

**ソースと文書**:

- 上流 49.3 の `src/grd-ctl.c`: オプション無しの `grdctl` は `GRD_RUNTIME_MODE_SCREEN_SHARE`。`rdp enable` は `/usr/libexec/gnome-remote-desktop-enable-service <PID> user true` を動かし、セッションの systemd に `gnome-remote-desktop.service` の StartUnit と EnableUnitFiles を頼む。`status` の `View-only:` はこのモードだけに出る
- 上流 49.3 の `src/org.gnome.desktop.remote-desktop.gschema.xml.in`: `view-only` の既定は true、`negotiate-port` は true、`port` は 3389、`screen-share-mode` は `mirror-primary`。ヘッドレスの schema（`rdp/headless/`）にあるのは `port`・`negotiate-port`・`enable` だけで、`tls-cert`・`tls-key` は共用
- 上流 49.3 の `src/grd-settings.c` と `src/grd-credentials-libsecret.c`: デスクトップ共有の資格情報は libsecret の既定のコレクションに、schema `org.gnome.RemoteDesktop.RdpCredentials` で置く
- 上流 49.3 の `data/gnome-remote-desktop.service.in`（`WantedBy=gnome-session.target`）と `data/gnome-remote-desktop-headless.service.in`（`Conflicts=gnome-remote-desktop.service`）
- gnome-shell 49.4 の `js/ui/main.js`・`js/ui/sessionMode.js`・`js/ui/screenShield.js` と mutter 49.4 の `meta-dbus-session-manager.c`: ロック画面のモードでは `inhibit_remote_access` が呼ばれ、リモートのセッションが閉じられる。無操作のシールドも同じモードに入る
- AlmaLinux の `gnome-remote-desktop.spec`（`imports/c10/gnome-remote-desktop-49.3-4.el10_2`）のパッチは、VNC の暗号化・接続の数の制限・マルチタッチ・ヘッドレスとリモートログインの受け渡しで、デスクトップ共有の設定と資格情報の置き場所は変えない
- RHEL 10 の文書の 1.1 は設定アプリでの操作だけで、CLI の手順は無い。リモートログインと併用するとポートが 3390 になることは書いてある

**ブロックの構文と、部品の確かめ**:

- 手順書の `bash` のブロック 24 個を抜き出し、ホスト（Ubuntu 24.04 の bash 5.2）の `bash -n` と ShellCheck 0.9.0（`-s bash`。変数のブロックのために SC2034・SC2154 は外した）にかけた。どれも通った
- `gdm-47.0-24.el10_2` の RPM の `/etc/gdm/custom.conf` には `[daemon]` の行がある。その写しに、[自動ログインで使う（任意）](../gnome-desktop-sharing.md#自動ログインで使う任意)の手順 3 と同節の手順 8 の `sed` をかけ、`[daemon]` の直後に 2 行が入り、消すと元に戻ることを確かめた（コンテナの GNU sed）
- コンテナの dconf 0.40.0 で、`grdctl rdp set-port 3390` の後の `dconf read …/rdp/port` が `uint16 3390` になり、その文字列を `dconf write` で書き戻せ、`dconf reset` で読み出しが空に戻ることを確かめた（[ロールバック](../gnome-desktop-sharing.md#ロールバック)の手順 3 の戻し方）。`/usr/bin/gsettings list-recursively org.gnome.desktop.remote-desktop.rdp` は `port uint16 3389` の形で出す

**自動ログインの節のキーリングの操作の模擬**:

- 環境: `quay.io/almalinuxorg/almalinux:10.2` のコンテナに、`gnome-keyring-42.1-20.el10`・`libsecret-0.21.2-8.el10`・`python3-gobject-base-3.46.0-7.el10`・`gnome-remote-desktop-49.3-4.el10_2` を入れた。一般ユーザーで `dbus-run-session` の中に gnome-keyring-daemon（secrets）を立てた。systemd・GNOME のセッション・GDM・gcr の窓は無い
- 用意: `gnome-keyring-daemon --unlock` で、パスワード付きのログインのキーリングを作って開き、`secret-tool store` で、`grdctl rdp set-credentials` と同じ形の項目（schema・ラベル・GVariant の値）を置いた
- 手順書の初めの版（ログインのキーリングの項目を残して、パスワードの無いキーリングへ写すだけ）では、デーモンを立て直してパスワード無しで起こすと、写したキーリングも `Locked` が `b true` で、`secret-tool lookup` は何も返さなかった
  - 写したキーリングのファイルは、暗号化されない文字のファイル（`~/.local/share/keyrings/rdp.keyring`）だった
  - 写したキーリングだけを `Unlock` すると、窓（prompt）無しで `b false` になり、`secret-tool lookup` が値を返した
  - ログインのキーリングのパスワードを空にした場合も、起こした直後は `b true` で、`Unlock` は窓無しで通った
  - libsecret 0.21.2 の読み出しは、同じ属性の項目が閉じたキーリングにしか無いと、最初に見つかった 1 つ（`locked[0]`）を開こうとする（ソースで確かめた）。ログインのキーリングの項目が先に返ると、そのキーリングを開く窓が要るはず、と判断した
- 直した版（写した後に、ログインのキーリングの項目を消す。同節の手順 1 の始めに、`rdp` のキーリングを `Unlock` する）を、手順書のブロックのまま流して、次を確かめた
  - パスワードで開いたデーモンで、同節の手順 1 が `移した先: /org/freedesktop/secrets/collection/rdp/1`（終了コード 0）、貼り直すと `すでに移してある: /org/freedesktop/secrets/collection/rdp/1`（終了コード 0）
  - 同節の手順 2 が `aoao 1 "/org/freedesktop/secrets/collection/rdp/1" 0` と `b false`
  - デーモンを立て直し、パスワードで開き直した直後は、`rdp` のキーリングが `b true` だった。そこで同節の手順 1 を貼り直すと、窓無しで開いて `すでに移してある:`（終了コード 0）、同節の手順 2 も同じ 2 行
  - デーモンを立て直してパスワード無しで起こした後（自動ログインの代わり）に、同節の手順 6 の `grdctl status` が `Username: (hidden)`・`Password: (hidden)` を出した（grdctl 自身の libsecret の読み出し）。続く `Locked` の行は、ログインのキーリングが `b true`、移したキーリングが `b false`
    - このコンテナでは証明書を設定していないので、`grdctl status` は `[x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` も出した
  - 同節の手順 8 の `busctl` の行で `o "/"` が出て、`rdp.keyring` が消えた。貼り直すと `rdp のキーリングは無い（消し済み）`
- この模擬で確かめていないこと: GDM の自動ログイン、GNOME のセッションの中の gnome-keyring（PAM の `pam_gnome_keyring` が起こすもの）、gnome-remote-desktop のデーモンが接続のときに読み出すこと、PC の画面に窓が出ないこと、同節の手順 6 の `loginctl` と `ss` の行

---
