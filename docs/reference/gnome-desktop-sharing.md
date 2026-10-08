# GNOME のデスクトップ共有の手順（PC の画面のデスクトップに、遠隔から RDP でつなぐ。PC の画面を触らずに CLI だけで設定する）の参考資料

[手順書](../gnome-desktop-sharing.md)

[検証記録](../verification/gnome-desktop-sharing.md)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- `SERVER_IP`・`SERVER_NAME`・`SERVER_FQDN` は、[gnome-remote-desktop.md](../gnome-remote-desktop.md) の手順 1 と同じ。証明書の SAN に入れる（手順 5）
- `RDP_PORT` の式は、[gnome-headless-session.md](../gnome-headless-session.md) の手順 1 と同じ。`systemctl is-enabled gnome-remote-desktop.service` は `--user` を付けないので、システムの unit（リモートログイン）を見る
  - ユーザーの unit も同じ名前（`gnome-remote-desktop.service`）なので、ユーザーの unit を見るときは必ず `--user` を付ける
- RHEL 10 の文書の 1.1 も、リモートログインと併用するときはデスクトップ共有のポートが 3390 になると書いている

### 実施手順 / 手順 2: 補足: 再起動の前に確かめること

- この手順書は、手順 13 で PC を再起動して、自動ログインでデスクトップを作る。PC の画面を触れないので、再起動から戻ってこられないと、遠隔では直せない
- 確かめるのは、再起動の後に SSH で入り直せること（`sshd.service` が enabled、firewalld の永続の設定に `ssh` がある）と、GNOME が自動で起動すること（既定の target が `graphical.target`、`gdm.service` が enabled）
- `/sys/class/drm/card*-*/status` の `connected` の数は、PC につながっているモニターの数。デスクトップ共有は PC の主モニターを写す（`screen-share-mode='mirror-primary'`）ので、モニターの無い PC には写すものが無い
  - aarch64 の実機の検証では、HDMI の無い Raspberry Pi 5 の seat0 に、GNOME Shell の仮想モニターを足して写した（[検証記録](../verification/gnome-desktop-sharing.md#付録-このホストでの検証2026-10-07)）。手順書には入れず、モニターの無い PC は[ヘッドレスのセッション](../gnome-headless-session.md)を使う（「選択した方針」）
- `lsblk` の `crypt` は、LUKS などで暗号化したブロックデバイス。起動のときにパスフレーズを PC の画面で入れる構成なら、手順 13 の再起動の後に入力を待って止まる。TPM などで自動で開く構成かどうかは、この確認では分からないので、手順書は利用者に確かめさせる

### 実施手順 / 手順 3: 補足: 確かめる前提

- **PC の画面のセッション**: デスクトップ共有のデーモン（`gnome-remote-desktop-daemon` をオプション無しで動かしたもの）は、セッションの Mutter の ScreenCast と RemoteDesktop の D-Bus を使う。そのユーザーのグラフィカルなセッションが無いと、何も共有しない
  - この手順書では、セッションは手順 13 の再起動の後に、GDM の自動ログインで作る。手順 3 では、PC の画面のセッションを前提にしない（一覧を出すだけ）
- **資格情報の置き場所**: ユーザーのモードの資格情報は、GNOME のキーリング（libsecret）に置く
  - schema は `org.gnome.RemoteDesktop.RdpCredentials`、ラベルは `GNOME Remote Desktop RDP credentials`、値は GVariant の文字列 `{'username': <'…'>, 'password': <'…'>}`。設定アプリ（gnome-control-center 47.7）も同じ項目を読み書きする
  - ヘッドレスとシステムのモードの資格情報（TPM か `credentials.ini`）とは別の場所なので、ぶつからない
  - ログインのキーリングを開くのは、GDM でパスワードを入れてログインしたときの `pam_gnome_keyring`（gdm 47.0 の `gdm-password` の PAM）。SSH のログイン（sshd の PAM に `pam_gnome_keyring` が無い）と自動ログイン（パスワードが無い）では開かない
  - 手順 3 の `SearchItems` は、項目を読むだけで、キーリングを開かない。SSH のシェルからでも、gnome-keyring は D-Bus で起動する（`org.freedesktop.secrets` が activatable）
- **画面の設定**: gnome-shell は、ロック画面（`unlock-dialog` のモード）の間、`inhibit_remote_access` で画面の共有を止め、Mutter はつながっているリモートのセッションを閉じる（上流の README の「locking the screen also closes the remote desktop connection」、上流 #119・#172）
  - 無操作で暗くなったとき（`idle-delay`）も、シールドが出て同じモードになる。`lock-enabled` が false でも切れる
  - なので、`idle-delay` を 0 に、`lock-enabled` を false にする（[AlmaLinux 10 の初期設定](../almalinux-setup.md)の「画面オフ・画面ロック・自動サスペンドを止める（任意）」の手順 1・2 の既定値）
  - 遠隔の PC は、眠ると起こす手段が無いので、サスペンドの mask（同書の手順 4）も前提にし、`suspend.target` が `masked` かを見る
- **ヘッドレスのセッション**: ヘッドレスのユーザーの unit（`gnome-remote-desktop-headless.service`）には `Conflicts=gnome-remote-desktop.service` がある。同じユーザーでは、片方を起動するともう片方が止まる

### 実施手順 / 手順 4: 補足: 残っている資格情報を消す理由

- 設定アプリやこの手順書の以前の版で入れた資格情報は、ログインのキーリングにある。自動ログインでは、ログインのキーリングは閉じたまま
- libsecret 0.21.2 の読み出しは、同じ属性の項目が開いたキーリングにあればそれを使い、閉じたキーリングにしか無ければ、最初に見つかった 1 つ（`locked[0]`）を開こうとする
  - 起動の直後は、手順 7 のキーリング（パスワード無し）もまだ閉じている。ログインのキーリングの項目が先に返ると、そのキーリングを開く窓が PC の画面に出るはずで、遠隔からは答えられない
  - なので、手順 7 のキーリングの外にある項目は消す（写すのではなく、手順 7 で入れ直す）
- 閉じたキーリングの項目は、開かないと消せない。PC の画面に窓を出さずに開くには、gnome-keyring の `org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface.UnlockWithMasterPassword` に、そのキーリングのパスワードを渡す（Secret Service の `Unlock` は、PC の画面に窓を出す）
  - VM では、違うパスワードで `org.gnome.keyring.Error.Denied: The password was invalid` が返り、何も消さずに止まった
- 開いたキーリングは、消した後に `Lock` で閉じ直す（自動ログインのときと同じ状態に戻す）。もとから開いていたキーリングは閉じない
- パスワードは `getpass` で読み、画面とシェルの履歴に残さない。Secret Service のセッションは、それを開いた D-Bus の接続でしか使えないので、1 つの接続の Python（Gio）で書いた

### 実施手順 / 手順 5: 補足: 退避と証明書

- 中身は [gnome-headless-session.md 手順 3](../gnome-headless-session.md#実施手順) と同じ形。違うのは、退避先（`~/.local/state/gnome-desktop-sharing-setup`）と、退避するキーの数（5 つ）
- 退避するのは、手順 6 で変える dconf のキー（`/org/gnome/desktop/remote-desktop/rdp/` の `port`・`negotiate-port`・`view-only`・`tls-cert`・`tls-key`）。未設定だったキーは空ファイルになり、ロールバックでは `reset` で戻す
- `tls-cert` と `tls-key` は、デスクトップ共有とヘッドレスのモードで共用する（ヘッドレスの専用のキーは `rdp/headless/` の下の `port`・`negotiate-port`・`enable` だけ）。`rdp/` を `dconf reset -f` すると `rdp/headless/` も消えるので、キーごとに戻す
- 証明書のパス（`~/.local/share/gnome-remote-desktop/certificates/rdp-tls.{crt,key}`）は、ヘッドレスの手順書・RHEL 10 の文書の 1.4・設定アプリ 47.7 が自分で作るときと同じ
- RHEL の文書は `winpr-makecert` で作るが、ここでは SAN を付けるために openssl で作る（[gnome-remote-desktop.md の参考資料](gnome-remote-desktop.md)）

### 実施手順 / 手順 6: 補足: grdctl（オプション無し）

- `--headless` も `--system` も付けない `grdctl` は、デスクトップ共有（上流のソースでは `GRD_RUNTIME_MODE_SCREEN_SHARE`）の設定を変える。書き先は dconf の `/org/gnome/desktop/remote-desktop/rdp/`
- dconf への書き込みなので、PC の画面のセッションが無くても（SSH だけでも）設定できる
- 既定は `view-only=true`（見るだけ）・`negotiate-port=true`・`port=3389`・`screen-share-mode='mirror-primary'`
- `disable-port-negotiation` は、指定したポートが使われていたときに次のポートを順に試すのを止める。ポートが勝手に変わって、手順 10 で開けたポートと食い違うのを防ぐ。代わりに、ポートが使われていると待ち受けに失敗し、再試行しない
- `set-tls-cert` と `set-tls-key` は絶対パスだけを受け付ける（`~` はシェルが展開する）
- 初めて設定するときの `[x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` は、`grdctl` が設定を読み込むとき（49.3 の `src/grd-settings.c` の `update_rdp_server_fingerprint`）に、まだ空の `tls-cert` で証明書を読もうとして出すもの
  - 最初の `set-tls-cert` だけが出し、後の `grdctl` は設定済みのパスを読むので出さない（[gnome-headless-session.md 手順 4](../gnome-headless-session.md#実施手順) と同じ）
- `port` と `negotiate-port` は、次に待ち受けるときに効く。手順 6 は、既に起動しているデーモンを再起動してポートと TLS の設定を反映する。`view-only` 自体は、つないでいるクライアントにもすぐ効く

### 実施手順 / 手順 7: 補足: パスワードの無いキーリングに直接入れる

- g-r-d は、ユーザーのパスワードを知らないのでキーリングを開けない（上流 #27 の開発者の説明）。自動ログインでは、ログインのキーリングは閉じたままになる
- 上流 #27 で知られている回避策は 2 つ
  - ログインのキーリングのパスワードを空にする: ほかのパスワード（ブラウザーなど）もすべて暗号化されずに置かれる
  - パスワードの無い別のキーリングに RDP の資格情報だけを置く: この手順書はこちらを採る
- `grdctl rdp set-credentials` は、libsecret の既定のコレクション（`default` の別名。通常は `login`）に書く。ログインのキーリングが閉じていると、PC の画面に「認証が必要です」の窓を出して待ち続ける（上流 #166・#338）
  - VM では、Ctrl+C で `grdctl` を止めても PC の画面の窓は残り、RDP の画面で「キャンセル」を押して閉じた（[検証記録](../verification/gnome-desktop-sharing.md#付録-pc-の画面を触らない版を-x86_64-の-vm-で通した記録2026-10-07)）
  - 画面で一度もログインしていないユーザーには、ログインのキーリングがそもそも無く、書き込みはキーリングを作る窓を出すはず
- そこで、`grdctl` を使わず、Python（Gio）で Secret Service に直接書く
  - パスワードの無いキーリングを、PC の画面に窓を出さずに作るには、gnome-keyring の `CreateWithMasterPassword` を空のパスワードで呼ぶ（Secret Service の `CreateCollection` は、PC の画面にパスワードを聞く窓を出す）
  - 項目の値は、g-r-d と同じく GVariant の `a{sv}`（`username` と `password`）を `print_(True)`（`g_variant_print` と同じ）で文字にしたもの。ラベル・`xdg:schema` の属性も `grdctl` と同じにする
  - VM では、入れた項目を `grdctl status --show-credentials` がユーザー名で読み、RDP の認証も通った
  - `CreateItem` の `replace` を真にするので、貼り直すと同じキーリングの項目を上書きする（資格情報の変更）
- 標準入力はヒアドキュメント（スクリプトそのもの）なので、ユーザー名は `/dev/tty` を開き直して `input()` で読み、パスワードは `getpass`（`/dev/tty` を使う）で読む
  - `open('/dev/tty', 'r+')` は、テキストの読み書きのモードでは `io.UnsupportedOperation: File or stream is not seekable.` で失敗した（検証で直した）
- パスワードの無いキーリングも、gnome-keyring を起こした直後は閉じている。開くように頼まれると、パスワードを聞かずに開く（コンテナでの模擬と、VM の再起動の後の最初の RDP の認証）
- 作ったコレクションの実際の D-Bus パスは `~/.local/state/gnome-desktop-sharing-setup/autologin-keyring` に記録する。名前が `rdp` でも、記録と一致しない既存コレクションは再利用しない。記録のファイル名は、この手順書の以前の版の任意節「自動ログインで使う」と同じなので、その版で作ったキーリングもそのまま使える
- 元に戻す[ロールバック](../gnome-desktop-sharing.md#ロールバック)の手順 4 は、この記録のコレクションだけを開き、RDP の schema に一致する項目だけを消す。コレクションと記録を消すのは、ほかの項目が無く、削除が完了したときだけ

### 実施手順 / 手順 9: 補足: grdctl rdp enable

- `grdctl rdp enable` は、`/usr/libexec/gnome-remote-desktop-enable-service` を通して、セッションの systemd にユーザーの unit `gnome-remote-desktop.service` の StartUnit と EnableUnitFiles を頼む。`systemctl --user enable --now` は要らない
- unit は `WantedBy=gnome-session.target` なので、PC の画面のセッションが始まるたびに起動する
- PC の画面のセッションが無い（SSH だけの）ときに貼っても、エラーにならずに unit が起動し、待ち受けはしなかった（VM）。再起動の後の自動ログインで、待ち受けを始めた
- `grdctl rdp disable` は、unit を止めて無効にする

### 実施手順 / 手順 12: 補足: 起動画面（plymouth）を止める理由

- GDM 47.0 は、自動ログインのセッションを始めると、20 秒後に `plymouth quit --retain-splash` を呼ぶ（`daemon/gdm-manager.c` の `on_user_session_started`）
- GDM は、VT1（`GDM_INITIAL_VT`）に切り替わったときに VT1 にログイン画面が無ければ、ログイン画面を作る（`daemon/gdm-local-display-factory.c` の `on_vt_changed`）
- VirtualBox の VM では、自動ログインのセッションは VT2 で動き、約 22 秒後に plymouth が終わった直後に、GDM が VT1 にログイン画面を作って、VT1 が前に出た（起動の引数を `rhgb quiet` 付きの一般的な形にしても同じだった）
- その結果、PC の画面にはログイン画面が出て、自動ログインのセッションは裏（`Active=no`）に回る。裏のセッションは画面を描かないので、RDP でつなぐと、認証は通るのに画面が真っ黒になる
- VirtualBox の VM で、起動の引数に `rd.plymouth=0 plymouth.enable=0` を足すと、plymouth が動かず、VT の切り替えが起きないので、ログイン画面は出なかった（[検証記録](../verification/gnome-desktop-sharing.md#付録-virtualbox-の-vm-での本実行2026-10-07)）
- 裏に回ったセッションは、`sudo loginctl activate <SESSION_ID>` で前に戻せる（[つながらなくなったとき](../gnome-desktop-sharing.md#つながらなくなったとき)の手順 2）。`sudo` が無いと `Interactive authentication required.` で断られる

### 実施手順 / 手順 13: 補足: 再起動のコマンド

- systemd 257 の `systemctl reboot` は、端末から呼ばれると、抑止（inhibitor）を確かめ、強い抑止があれば断る（`src/systemctl/systemctl-logind.c` の `logind_check_inhibitors`）
  - v257 から、root でも抑止を確かめる。root は、抑止が無ければ、ほかのユーザーのセッションを確かめない（同じ関数の「root respects inhibitors since v257 but keeps ignoring sessions by default」）
  - 自分と同じ uid のセッション（SSH のログインなど）は、root でなくても数えない
  - gnome-session が `shutdown` の強い抑止（`user session inhibited`）を取るのは、アプリが終了を止めているときだけ（テキスト エディターに保存していない文書があるときなど）。アプリが止めていなければ取らない
- `-i`（`--check-inhibitors=no`）で抑止を無視させても、logind は、強い抑止を無視するときは root にも polkit の認可を求める（`src/login/logind-dbus.c` の「We want to always ask here, even for root」）
  - `sudo` を付けると root の `systemctl` は polkit の認証を聞く窓口（`pkttyagent`）を起こさない（`src/shared/polkit-agent.c` の「Clients that run as root don't need to activate/query polkit」）ので、`Interactive authentication required.` で断られる
  - 強い抑止が無ければ、`sudo systemctl reboot -i` は認証を聞かれずに再起動した
  - `sudo` を付けない `systemctl` は、端末で `pkttyagent` を起こし、このユーザーのパスワードを聞く（`wheel` のユーザーは管理者として認証できる）。抑止の有無にかかわらず通る
  - VM で聞かれた操作は、`org.freedesktop.login1.reboot-ignore-inhibit`（保存していない文書があり、強い抑止があったとき）か `org.freedesktop.login1.reboot`（無かったとき）だった。PC の画面にセッションが無いとき（ログイン画面だけ）も `org.freedesktop.login1.reboot` だった
  - 2026-10-07 の最初の記録は、この違いをセッションの種類（パスワードでのログインか自動ログインか）の違いと書いていた

### 実施手順 / 手順 14: 補足: 待ち受けの確かめ方

- `grdctl status` の `Port:` は dconf の値で、実際に待ち受けたポートではない（上流 #255）
- 実際のポートは、`ss` か、D-Bus の `org.gnome.RemoteDesktop.User` の `/org/gnome/RemoteDesktop/Rdp/Server` の `Port` プロパティ（待ち受けていなければ -1）で見る
- unit の起動完了と待ち受け開始には時間差があるので、手順 14 は自分のデーモンのソケットを最大 30 秒待つ
- 待ち受けに失敗しても、デーモンは動き続け、unit は `active` のまま。ポートのネゴシエーションを切っているので、ほかのポートも試さず、ポートが空いても待ち受け直さない（手順 6 の補足）
  - 原因を直した後は、手順 6 を貼り直す。手順 6 は、起動中のデーモンを再起動する
  - 理由は、デーモンのログの `Failed to start RDP server: Error binding to address [::]:<RDP_PORT>: Address already in use` で分かる（ログの見方は手順 16 の補足）
- `ss -p` は、自分のプロセスなら root でなくても名前を出す。システムのデーモン（リモートログイン）は `gnome-remote-desktop` ユーザーのプロセスなので、ここには名前が出ない
- 手順 14 は資格情報を読まない。読み出しが先に起きないので、停電などで再起動したときと同じく、最初の RDP の認証が資格情報を読む流れも確かめられる（検証では、再起動の後にこの手順だけを貼ってから、クライアントから直接つないだ）

### 実施手順 / 手順 15: 補足: TLS プローブ

- スクリプトは [gnome-remote-desktop.md 手順 10](../gnome-remote-desktop.md#実施手順) と同じもの。第 2 引数でポートを渡す
- `/usr/bin/python3` で動かすのは、Homebrew が PATH の先頭にあるときも、同じ Python にするため
- `grdctl status` は資格情報を読み出す（`Username: (hidden)` と出るのは、読めたとき）。手順 7 のキーリングはパスワードが無いので、PC の画面に窓は出ない
- 最後の `openssl x509 … -fingerprint -sha1` は、Windows のクライアントで比べるための値
  - `grdctl status` の `TLS fingerprint` と、FreeRDP の `Thumbprint:` は SHA-256（コロン区切りの小文字）
  - Windows の「リモート デスクトップ接続」の警告の窓は、証明書の名前とエラーだけを出し、拇印を出さない。「証明書の表示」→「詳細」の「拇印」は SHA-1 で、コロンの無い小文字（例: `de7964917c…`）。openssl は同じ値をコロン区切りの大文字（`DE:79:64:91:7C:…`）で出す

### 実施手順 / 手順 16: 補足: クライアントに写るもの

- 既定の `screen-share-mode='mirror-primary'` は、PC の主モニターをそのままの解像度で送る。クライアントの窓の大きさに合わせるための Display Control のチャネルは `extend` のときしか作られない
- デスクトップ共有で写せるモニターは 1 枚だけ
- 認証は NLA だけ（TLS だけ・RDP のセキュリティは受け付けない）。ユーザー名とパスワードは手順 7 の RDP の資格情報で、OS のアカウントではない
- FreeRDP 3.10.3 は、保存した証明書（`~/.config/freerdp/server/<SERVER_IP>_<RDP_PORT>.pem`）が無い初めての接続でも、`REMOTE HOST IDENTIFICATION HAS CHANGED!` の警告を出してから、新しい証明書としての確認（`Do you trust the above certificate? (Y/T/N)`）を出す。`Y` で保存した後は聞かない
  - 証明書を作り直した後は、`!!!Certificate for … has changed!!!` と新旧の `Thumbprint:` を並べて聞く
- 画面で一度もログインしていないユーザーの最初の自動ログインでは、`gnome-tour` の「AlmaLinux 10.2 (Lavender Lion) へようこそ」の窓が出た（gnome-initial-setup の窓は出なかった）。RDP の画面で「スキップ」を押して閉じた
- ログの見方: AlmaLinux 10 の既定は `/var/log/journal` が無く、journal は揮発（`/run/log/journal`）。揮発のときはユーザーごとの journal のファイルが分かれないので、`journalctl --user` は `No journal files were found.` になる
  - `journalctl -b _SYSTEMD_USER_UNIT=gnome-remote-desktop.service` は、システムの journal から、このユーザーの unit の行を読む（`wheel` と `adm` のグループは ACL で読める）。ヘッドレスの手順書と同じ形

### つながらなくなったとき: 補足

- 手順 1: ロック画面の間は、新しい接続も認証の後に `Session creation inhibited` で断られる。`loginctl unlock-session` は、logind からセッションへ `Unlock` を送る。VM では、GNOME のロック画面が解け（`org.gnome.ScreenSaver.GetActive` が `b true` から `b false`）、つなぎ直せた
  - 自分のセッションなので、`sudo` は要らなかった
- 手順 2: VM で `sudo chvt 1` で VT1 に切り替えると、GDM が VT1 にログイン画面を作り、自動ログインのセッションが `Active=no` になった。`sudo loginctl activate` で `Active=yes` に戻り、つないだままの FreeRDP にも画面が戻って、入力も届いた
- 手順 3: VM で、RDP の画面からログアウトすると、PC の画面はログイン画面のままになり（自動ログインし直さない）、`RDP_PORT` は閉じた（ユーザーの unit も止まる）。再起動すると、自動ログインで戻った
  - ログアウトの確認の窓は、「キャンセル」を押さないと 60 秒で自動でログアウトする
  - aarch64 の実機の検証では、OS の再起動の代わりに GDM とユーザーマネージャーを起動し直して、自動ログインさせた（[検証記録](../verification/gnome-desktop-sharing.md#付録-このホストでの検証2026-10-07)）。リモートログインのデーモンとの順序の問題（[gnome-remote-desktop.md](../gnome-remote-desktop.md)）があるので、手順には再起動を採った

### 注意点の補足: 後からリモートログインを有効にしたとき

- リモートログインの手順 4（`sudo grdctl --system rdp …`）を貼っている間に、システムのデーモンが起動して 3389 で待ち受けた
  - VM では 2 回とも、同じ秒に共有のデーモンが `RDP server stopped` を出した
  - 約 3 秒後に `Failed to start RDP server: Error binding to address [::]:3389: Address already in use` を出して、待ち受けをやめた。ユーザーの unit は `active` のまま
  - 共有のデーモンが待ち受けをいったん止める仕組みは確かめていない
- firewalld は、ポート（`--add-port`）とサービス（`--add-service`）を別々に持つ。この手順書が手順 10 で開けた `3389/tcp` は、リモートログインが開けた `rdp` のサービスとは別に残る
  - リモートログインの「接続元を LAN に絞る」は、`rdp` のサービスを外して、LAN だけを通す rich rule にする。ゾーンに `3389/tcp` が残っていると、LAN の外からも 3389 に届く
  - リモートログインのロールバックは `rdp` のサービスと rich rule だけを消す。この手順書のロールバックの手順 1 は、移した後の `RDP_PORT`（3390）だけを閉じる。どちらも `3389/tcp` を消さない
- そのため、注意点では、`RDP_PORT=3389` でこの手順書のロールバックの手順 1（LAN に絞ったなら手順 2）を貼って閉じてから、3390 へ移す。閉じても、リモートログインは `rdp` のサービスか、同書の rich rule で届く
- この補足の記録は、PC の前でパスワードでログインしていた以前の版（当時の手順 4・7・8・9 が、今の手順 6・10・14・15）で取った

### 選択した方針

- **デスクトップ共有にする**（RHEL 10 の文書の 1.1 の方式）
  - PC の画面に出ているデスクトップを、そのまま共有する。PC の前にいる人と、同じ画面を見て操作できる
  - モニターの無い PC なら[ヘッドレスのセッション](../gnome-headless-session.md)、ログイン画面から入るなら[リモートログイン](../gnome-remote-desktop.md)
- **PC の画面を触らない前提にする**（2026-10-07、利用者の依頼）— 遠隔の PC で、PC の画面・キーボード・マウスを使えなくても、SSH のシェルと RDP のクライアントだけで、設定・確認・復旧・ロールバックができるようにした
  - 以前の版は、PC の前でパスワードでログインしておくことを前提にし、自動ログインを任意節にしていた。その記録は検証記録に残す
- **自動ログインでデスクトップを作る** — SSH から GDM のログイン画面でログインする手段は無いので、PC の画面のセッションは自動ログインで作る。PC の前にいる人がこのデスクトップを使える危険は、手順書のリードの `[!WARNING]` に書いた
- **資格情報は、パスワードの無いキーリングに直接入れる** — 自動ログインではログインのキーリングが開かないので、`grdctl rdp set-credentials` は PC の画面に窓を出して止まる。ログインのキーリングのほかの秘密は、暗号化したまま残す
  - SSH から毎回ログインのキーリングを OS のパスワードで開く案は、停電などで再起動したときに、SSH で入り直すまで RDP が使えないので、利用者の選択で採らなかった
- **再起動の前に、戻ってこられるかを確かめる** — 遠隔では、SSH・GNOME の自動起動・ディスクの暗号化のどれかで止まると直せない
- **つながらなくなったときの直し方も SSH からにする** — ロックは `loginctl unlock-session`、ログイン画面が前に出たときは `loginctl activate`、ログアウトしたときは再起動
- **CLI だけで設定する** — RHEL 10 の文書の 1.1 は設定アプリでの操作だけを書いている。CLI では、上流の README の「From command line」と同じ `grdctl`（オプション無し）を使う
- **証明書は openssl で作る** — SAN に IP を入れる理由は gnome-remote-desktop.md と同じ
- **ポートを固定し、ポートのネゴシエーションを切る** — ファイアウォールで開けたポートと食い違わないように（ヘッドレスの手順書と同じ）
- **クライアントからの操作を許す**（`disable-view-only`）— 既定の見るだけは、任意節で戻せる
- **起動画面（plymouth）を止める** — 止めないと、GDM が自動ログインの 20 秒後に plymouth を終わらせ、そのときに VT1 にログイン画面を作って前に出すので、共有するデスクトップが裏に回る。起動ごとに `loginctl activate` で戻す方法より、起動の引数で止める方を採った（PC の前にいなくても、再起動の後にそのままつながる）
- **再起動は `sudo` 無しの `systemctl reboot -i` にする** — PC の画面のアプリが終了を止めていると、その抑止を無視するのに polkit の認証が要り、`sudo` では聞かれずに断られるため。`sudo` 無しの形は、止められていてもいなくても通る
- **ロールバックの最後に、PC の画面のセッションを終わらせる** — 自動ログインをやめても、今のセッションはロックされずに残るので、`loginctl terminate-session` でログイン画面に戻す

### 参照

- [Chapter 1. Remotely accessing the desktop — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/remotely-accessing-the-desktop)（1.1 Enabling desktop sharing on the server by using GNOME、1.3 の前提「For desktop sharing, a user is logged in to the GNOME graphical session on the server」）
- [GNOME/gnome-remote-desktop 49.3 README.md](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/blob/49.3/README.md)（Remote assistance の節。「From command line」）
- 上流のソース（49.3）: `src/grd-ctl.c`・`src/grd-settings-user.c`・`src/grd-credentials-libsecret.c`・`src/org.gnome.desktop.remote-desktop.gschema.xml.in`・`data/gnome-remote-desktop.service.in`・`data/gnome-remote-desktop-headless.service.in`
- 上流の issue: [#27](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/27)（キーリングが閉じていると認証できない。自動ログイン）・[#166](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/166)（SSH から資格情報を設定できない）・[#172](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/172)（ロックで切れる）・[#255](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/255)（`grdctl status` のポート）・[#338](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/338)（自動ログインの後の資格情報）
- [gnome-control-center #3547](https://gitlab.gnome.org/GNOME/gnome-control-center/-/issues/3547)（キーリングが閉じているときに「リモート デスクトップ」を開くと、パスワードが乱数に書き換わる。GNOME 50 で修正）
- GDM 47.0 のソース: [`daemon/gdm-manager.c`](https://gitlab.gnome.org/GNOME/gdm/-/blob/47.0/daemon/gdm-manager.c)（`on_user_session_started` の 20 秒後の `plymouth quit --retain-splash`）・[`daemon/gdm-local-display-factory.c`](https://gitlab.gnome.org/GNOME/gdm/-/blob/47.0/daemon/gdm-local-display-factory.c)（`on_vt_changed`）
- gdm のパッケージの履歴（AlmaLinux の git）: [actually quit plymouth at startup](https://git.almalinux.org/rpms/gdm/commit/ad6daf364e3156d2ed7950b08a9a977d3df68a0b)（2015 年の gdm 3.16 の変更。自動ログインでログイン画面が出ないときは、20 秒後に plymouth を終わらせる）
- systemd 257 のソース: [`src/systemctl/systemctl-logind.c`](https://github.com/systemd/systemd/blob/v257/src/systemctl/systemctl-logind.c)（`logind_check_inhibitors`）・[`src/login/logind-dbus.c`](https://github.com/systemd/systemd/blob/v257/src/login/logind-dbus.c)（`verify_shutdown_creds`）・[`src/shared/polkit-agent.c`](https://github.com/systemd/systemd/blob/v257/src/shared/polkit-agent.c)（`polkit_agent_open`）
- gnome-keyring 42.1 の D-Bus の内部のインターフェース `org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface`（`CreateWithMasterPassword`・`UnlockWithMasterPassword`）。VM の gnome-keyring で呼んで確かめた

---
