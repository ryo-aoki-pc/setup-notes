# GNOME のデスクトップ共有の手順（PC の画面のデスクトップに RDP でつなぐ。CLI だけで設定する）の参考資料

[手順書](../gnome-desktop-sharing.md)

[検証記録](../verification/gnome-desktop-sharing.md)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- `SERVER_IP`・`SERVER_NAME`・`SERVER_FQDN` は、[gnome-remote-desktop.md](../gnome-remote-desktop.md) の手順 1 と同じ。証明書の SAN に入れる（手順 3）
- `RDP_PORT` の式は、[gnome-headless-session.md](../gnome-headless-session.md) の手順 1 と同じ。`systemctl is-enabled gnome-remote-desktop.service` は `--user` を付けないので、システムの unit（リモートログイン）を見る
  - ユーザーの unit も同じ名前（`gnome-remote-desktop.service`）なので、ユーザーの unit を見るときは必ず `--user` を付ける
- RHEL 10 の文書の 1.1 も、リモートログインと併用するときはデスクトップ共有のポートが 3390 になると書いている

### 実施手順 / 手順 2: 補足: 確かめる前提

- **PC の画面のセッション**: デスクトップ共有のデーモン（`gnome-remote-desktop-daemon` をオプション無しで動かしたもの）は、セッションの Mutter の ScreenCast と RemoteDesktop の D-Bus を使う。そのユーザーのグラフィカルなセッションが無いと、何も共有しない
- **ログインのキーリング**: ユーザーのモードの資格情報は、GNOME のキーリング（libsecret の既定のコレクション。通常は `login`）に置く
  - schema は `org.gnome.RemoteDesktop.RdpCredentials`、ラベルは `GNOME Remote Desktop RDP credentials`、値は GVariant の文字列 `{'username': <'…'>, 'password': <'…'>}`。設定アプリ（gnome-control-center 47.7）も同じ項目を読み書きする
  - ヘッドレスとシステムのモードの資格情報（TPM か `credentials.ini`）とは別の場所なので、ぶつからない
  - ログインのキーリングを開くのは、GDM でパスワードを入れてログインしたときの `pam_gnome_keyring`（gdm 47.0 の `gdm-password` の PAM）。SSH のログイン（sshd の PAM に `pam_gnome_keyring` が無い）と自動ログイン（パスワードが無い）では開かない
  - キーリングが閉じていると、`set-credentials` はロックを解く窓を PC の画面に出して待ち続ける（上流 #166・#338）
  - デーモンは接続のたびに資格情報を読み出す（`src/grd-session-rdp.c`）。閉じたキーリングにしか無いと、libsecret がそれを開こうとして PC の画面に窓を出すはずで、開けないと `Credentials are not set, denying client` で断る（上流 #157 の開発者の説明）
- **画面の設定**: gnome-shell は、ロック画面（`unlock-dialog` のモード）の間、`inhibit_remote_access` で画面の共有を止め、Mutter はつながっているリモートのセッションを閉じる（上流の README の「locking the screen also closes the remote desktop connection」、上流 #119・#172）
  - 無操作で暗くなったとき（`idle-delay`）も、シールドが出て同じモードになる。`lock-enabled` が false でも切れる
  - なので、`idle-delay` を 0 に、`lock-enabled` を false にする（[gnome-power.md 手順 1・2](../gnome-power.md#実施手順) の既定値）
- **ヘッドレスのセッション**: ヘッドレスのユーザーの unit（`gnome-remote-desktop-headless.service`）には `Conflicts=gnome-remote-desktop.service` がある。同じユーザーでは、片方を起動するともう片方が止まる

### 実施手順 / 手順 3: 補足: 退避と証明書

- 中身は [gnome-headless-session.md 手順 3](../gnome-headless-session.md#実施手順) と同じ形。違うのは、退避先（`~/.local/state/gnome-desktop-sharing-setup`）と、退避するキーの数（5 つ）
- 退避するのは、手順 4 で変える dconf のキー（`/org/gnome/desktop/remote-desktop/rdp/` の `port`・`negotiate-port`・`view-only`・`tls-cert`・`tls-key`）。未設定だったキーは空ファイルになり、ロールバックでは `reset` で戻す
- `tls-cert` と `tls-key` は、デスクトップ共有とヘッドレスのモードで共用する（ヘッドレスの専用のキーは `rdp/headless/` の下の `port`・`negotiate-port`・`enable` だけ）。`rdp/` を `dconf reset -f` すると `rdp/headless/` も消えるので、キーごとに戻す
- 証明書のパス（`~/.local/share/gnome-remote-desktop/certificates/rdp-tls.{crt,key}`）は、ヘッドレスの手順書・RHEL 10 の文書の 1.4・設定アプリ 47.7 が自分で作るときと同じ
- RHEL の文書は `winpr-makecert` で作るが、ここでは SAN を付けるために openssl で作る（[gnome-remote-desktop.md の参考資料](gnome-remote-desktop.md)）

### 実施手順 / 手順 4: 補足: grdctl（オプション無し）

- `--headless` も `--system` も付けない `grdctl` は、デスクトップ共有（上流のソースでは `GRD_RUNTIME_MODE_SCREEN_SHARE`）の設定を変える。書き先は dconf の `/org/gnome/desktop/remote-desktop/rdp/`
- 既定は `view-only=true`（見るだけ）・`negotiate-port=true`・`port=3389`・`screen-share-mode='mirror-primary'`
- `disable-port-negotiation` は、指定したポートが使われていたときに次のポートを順に試すのを止める。ポートが勝手に変わって、手順 7 で開けたポートと食い違うのを防ぐ。代わりに、ポートが使われていると待ち受けに失敗し、再試行しない
- `set-tls-cert` と `set-tls-key` は絶対パスだけを受け付ける（`~` はシェルが展開する）
- 初めて設定するときの `[x509_utils_from_pem]: BIO_new failed for certificate` と `RDP server certificate is invalid.` は、`grdctl` が設定を読み込むとき（49.3 の `src/grd-settings.c` の `update_rdp_server_fingerprint`）に、まだ空の `tls-cert` で証明書を読もうとして出すもの
  - 最初の `set-tls-cert` だけが出し、後の `grdctl` は設定済みのパスを読むので出さない（[gnome-headless-session.md 手順 4](../gnome-headless-session.md#実施手順) と同じ）
- `port` と `negotiate-port` は、次に待ち受けるときに効く。手順 4 は、既に起動しているデーモンを再起動してポートと TLS の設定を反映する。`view-only` 自体は、つないでいるクライアントにもすぐ効く

### 実施手順 / 手順 6: 補足: grdctl rdp enable

- `grdctl rdp enable` は、`/usr/libexec/gnome-remote-desktop-enable-service` を通して、セッションの systemd にユーザーの unit `gnome-remote-desktop.service` の StartUnit と EnableUnitFiles を頼む。`systemctl --user enable --now` は要らない
- unit は `WantedBy=gnome-session.target` なので、ログインのたびに起動する
- `grdctl rdp disable` は、unit を止めて無効にする

### 実施手順 / 手順 8: 補足: 待ち受けの確かめ方

- `grdctl status` の `Port:` は dconf の値で、実際に待ち受けたポートではない（上流 #255）
- 実際のポートは、`ss` か、D-Bus の `org.gnome.RemoteDesktop.User` の `/org/gnome/RemoteDesktop/Rdp/Server` の `Port` プロパティ（待ち受けていなければ -1）で見る
- unit の起動完了と待ち受け開始には時間差があるので、手順 8 は自分のデーモンのソケットを最大 30 秒待つ
- `ss -p` は、自分のプロセスなら root でなくても名前を出す。システムのデーモン（リモートログイン）は `gnome-remote-desktop` ユーザーのプロセスなので、ここには名前が出ない

### 実施手順 / 手順 9: 補足: TLS プローブ

- スクリプトは [gnome-remote-desktop.md 手順 10](../gnome-remote-desktop.md#実施手順) と同じもの。第 2 引数でポートを渡す
- `/usr/bin/python3` で動かすのは、Homebrew が PATH の先頭にあるときも、同じ Python にするため
- 最後の `openssl x509 … -fingerprint -sha1` は、Windows のクライアントで比べるための値
  - `grdctl status` の `TLS fingerprint` と、FreeRDP の `Thumbprint:` は SHA-256（コロン区切りの小文字）
  - Windows の「リモート デスクトップ接続」の警告の窓は、証明書の名前とエラーだけを出し、拇印を出さない。「証明書の表示」→「詳細」の「拇印」は SHA-1 で、コロンの無い小文字（例: `de7964917c…`）。openssl は同じ値をコロン区切りの大文字（`DE:79:64:91:7C:…`）で出す

### 実施手順 / 手順 10: 補足: クライアントに写るもの

- 既定の `screen-share-mode='mirror-primary'` は、PC の主モニターをそのままの解像度で送る。クライアントの窓の大きさに合わせるための Display Control のチャネルは `extend` のときしか作られない
- デスクトップ共有で写せるモニターは 1 枚だけ
- 認証は NLA だけ（TLS だけ・RDP のセキュリティは受け付けない）。ユーザー名とパスワードは手順 5 の RDP の資格情報で、OS のアカウントではない
- FreeRDP 3.10.3 は、保存した証明書（`~/.config/freerdp/server/<SERVER_IP>_<RDP_PORT>.pem`）が無い初めての接続でも、`REMOTE HOST IDENTIFICATION HAS CHANGED!` の警告を出してから、新しい証明書としての確認（`Do you trust the above certificate? (Y/T/N)`）を出す。`Y` で保存した後は聞かない
  - 証明書を作り直した後は、`!!!Certificate for … has changed!!!` と新旧の `Thumbprint:` を並べて聞く
- ログの見方: AlmaLinux 10 の既定は `/var/log/journal` が無く、journal は揮発（`/run/log/journal`）。揮発のときはユーザーごとの journal のファイルが分かれないので、`journalctl --user` は `No journal files were found.` になる
  - `journalctl -b _SYSTEMD_USER_UNIT=gnome-remote-desktop.service` は、システムの journal から、このユーザーの unit の行を読む（`wheel` と `adm` のグループは ACL で読める）。ヘッドレスの手順書と同じ形

### 自動ログインで使う / 手順 1: 補足: パスワードの無いキーリング

- g-r-d は、ユーザーのパスワードを知らないのでキーリングを開けない（上流 #27 の開発者の説明）。自動ログインでは、ログインのキーリングは閉じたままになる
- 上流 #27 で知られている回避策は 2 つ
  - ログインのキーリングのパスワードを空にする: ほかのパスワード（ブラウザーなど）もすべて暗号化されずに置かれる
  - パスワードの無い別のキーリングに RDP の資格情報だけを置く: この手順書はこちらを採る
- パスワードの無いキーリングを、PC の画面に窓を出さずに作るには、gnome-keyring の `org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface.CreateWithMasterPassword` を空のパスワードで呼ぶ（Secret Service の `CreateCollection` は、PC の画面にパスワードを聞く窓を出す）
- パスワードの無いキーリングも、gnome-keyring を起こした直後は閉じている。開くように頼まれると、パスワードを聞かずに開く（コンテナでの模擬。[検証記録](../verification/gnome-desktop-sharing.md#付録-資料とブロックの確認2026-10-06)）
- libsecret 0.21.2 の読み出しは、同じ属性の項目が開いたキーリングにあればそれを使い、閉じたキーリングにしか無ければ、最初に見つかった 1 つ（`locked[0]`）を開こうとする
  - ログインのキーリングに項目が残っていて、それが先に返ると、そのキーリングを開く窓が要るはず。なので、写すのではなく移す（写した後に、ログインのキーリングの項目を消す）
- 手順 1 の始めに、`rdp` のキーリングを `Unlock` する。パスワードでログインし直した後は閉じているので、開かないと、移した項目が閉じたキーリングの側に数えられる
- Secret Service のセッションは、それを開いた D-Bus の接続でしか使えないので、`busctl` を何回も呼ぶ形ではなく、1 つの接続の Python（Gio）で書いた
- 値は、`grdctl rdp set-credentials` が保存したものを `GetSecrets` で読み、そのまま `CreateItem` に渡す（ラベル・`xdg:schema` の属性も同じにする）。ユーザー名とパスワードを打ち直さない
- 作ったコレクションの実際の D-Bus パスは `~/.local/state/gnome-desktop-sharing-setup/autologin-keyring` に記録する。名前が `rdp` でも、記録と一致しない既存コレクションは再利用しない
- 元に戻す手順 8 は、この記録のコレクションだけを開き、RDP の schema に一致する項目だけを消す。コレクションと記録を消すのは、ほかの項目が無く、削除が完了したときだけ
- 再起動直後の手順 6 は、資格情報を読まずに状態を確かめる。`grdctl status` や TLS のプローブでも資格情報が読み出され、空パスワードのキーリングが先に開く可能性があるため、最初の RDP 接続を済ませてから手順 7 の読み戻しを行う
- [クリーン VM の検証](../verification/gnome-desktop-sharing.md#付録-公式-iso-から新規インストールした-aarch64-vm-での検証2026-10-07)では、OS 再起動後の `login`・`rdp` がどちらも閉じた状態から、別 VM の最初の認証で画面と入力を使え、接続後も `login` は閉じたまま `rdp` だけが開いた

### 自動ログインで使う / 手順 4: 補足: 起動画面（plymouth）を止める理由

- GDM 47.0 は、自動ログインのセッションを始めると、20 秒後に `plymouth quit --retain-splash` を呼ぶ（`daemon/gdm-manager.c` の `on_user_session_started`）
- GDM は、VT1（`GDM_INITIAL_VT`）に切り替わったときに VT1 にログイン画面が無ければ、ログイン画面を作る（`daemon/gdm-local-display-factory.c` の `on_vt_changed`）
- VirtualBox の VM では、自動ログインのセッションは VT2 で動き、約 22 秒後に plymouth が終わった直後に、GDM が VT1 にログイン画面を作って、VT1 が前に出た（起動の引数を `rhgb quiet` 付きの一般的な形にしても同じだった）
- その結果、PC の画面にはログイン画面が出て、自動ログインのセッションは裏（`Active=no`）に回る。裏のセッションは画面を描かないので、RDP でつなぐと、認証は通るのに画面が真っ黒になる
- VirtualBox の VM で、起動の引数に `rd.plymouth=0 plymouth.enable=0` を足すと、plymouth が動かず、VT の切り替えが起きないので、ログイン画面は出なかった（[検証記録](../verification/gnome-desktop-sharing.md#付録-virtualbox-の-vm-での本実行2026-10-07)）
- 裏に回ったセッションは、`sudo loginctl activate <SESSION_ID>` で前に戻せる（その起動の間だけ）。`sudo` が無いと `Interactive authentication required.` で断られる

### 自動ログインで使う / 手順 5: 補足: 再起動のコマンド

- systemd 257 の `systemctl reboot` は、端末から呼ばれると、root でも抑止（inhibitor）とログイン中のユーザーを確かめ、あれば断る（`src/systemctl/systemctl-logind.c` の `logind_check_inhibitors`）
  - PC の画面でログインしたセッションの gnome-session は、`shutdown` の強い抑止（`user session inhibited`）を持つ。SSH のログインもログイン中のユーザーに数えられる
- `-i`（`--check-inhibitors=no`）で抑止を無視させても、logind は、強い抑止を無視するときは root にも polkit の認可を求める（`src/login/logind-dbus.c` の「We want to always ask here, even for root」）
  - `sudo` を付けると root の `systemctl` は polkit の認証を聞く窓口（`pkttyagent`）を起こさない（`src/shared/polkit-agent.c` の「Clients that run as root don't need to activate/query polkit」）ので、`Interactive authentication required.` で断られる
  - `sudo` を付けない `systemctl` は、端末で `pkttyagent` を起こし、このユーザーのパスワードを聞く（`wheel` のユーザーは管理者として認証できる）
  - VM で聞かれた操作は、`org.freedesktop.login1.reboot-ignore-inhibit`（パスワードでログインしたセッションのとき）か `org.freedesktop.login1.reboot`（自動ログインのセッションのときと、ログイン画面が前にあったとき）だった

### 選択した方針

- **デスクトップ共有にする**（RHEL 10 の文書の 1.1 の方式）
  - PC の画面に出ているデスクトップを、そのまま共有する。PC の前にいる人と、同じ画面を見て操作できる
  - モニターの無い PC なら[ヘッドレスのセッション](../gnome-headless-session.md)、ログイン画面から入るなら[リモートログイン](../gnome-remote-desktop.md)
- **CLI だけで設定する** — RHEL 10 の文書の 1.1 は設定アプリでの操作だけを書いている。CLI では、上流の README の「From command line」と同じ `grdctl`（オプション無し）を使う
- **証明書は openssl で作る** — SAN に IP を入れる理由は gnome-remote-desktop.md と同じ
- **ポートを固定し、ポートのネゴシエーションを切る** — ファイアウォールで開けたポートと食い違わないように（ヘッドレスの手順書と同じ）
- **クライアントからの操作を許す**（`disable-view-only`）— 既定の見るだけは、任意節で戻せる
- **自動ログインでは、RDP の資格情報だけをパスワードの無いキーリングへ移す** — ログインのキーリングのほかの秘密は、暗号化したまま残す
- **自動ログインでは、起動画面（plymouth）を止める** — 止めないと、GDM が自動ログインの 20 秒後に plymouth を終わらせ、そのときに VT1 にログイン画面を作って前に出すので、共有するデスクトップが裏に回る。起動ごとに `loginctl activate` で戻す方法より、起動の引数で止める方を採った（PC の前にいなくても、再起動の後にそのままつながる）
- **再起動は `sudo` 無しの `systemctl reboot -i` にする** — PC の画面のセッションの抑止を無視するには polkit の認証が要り、`sudo` では聞かれずに断られるため

### 参照

- [Chapter 1. Remotely accessing the desktop — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/remotely-accessing-the-desktop)（1.1 Enabling desktop sharing on the server by using GNOME、1.3 の前提「For desktop sharing, a user is logged in to the GNOME graphical session on the server」）
- [GNOME/gnome-remote-desktop 49.3 README.md](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/blob/49.3/README.md)（Remote assistance の節。「From command line」）
- 上流のソース（49.3）: `src/grd-ctl.c`・`src/grd-settings-user.c`・`src/grd-credentials-libsecret.c`・`src/org.gnome.desktop.remote-desktop.gschema.xml.in`・`data/gnome-remote-desktop.service.in`・`data/gnome-remote-desktop-headless.service.in`
- 上流の issue: [#27](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/27)（キーリングが閉じていると認証できない。自動ログイン）・[#166](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/166)（SSH から資格情報を設定できない）・[#172](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/172)（ロックで切れる）・[#255](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/255)（`grdctl status` のポート）・[#338](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/338)（自動ログインの後の資格情報）
- [gnome-control-center #3547](https://gitlab.gnome.org/GNOME/gnome-control-center/-/issues/3547)（キーリングが閉じているときに「リモート デスクトップ」を開くと、パスワードが乱数に書き換わる。GNOME 50 で修正）
- GDM 47.0 のソース: [`daemon/gdm-manager.c`](https://gitlab.gnome.org/GNOME/gdm/-/blob/47.0/daemon/gdm-manager.c)（`on_user_session_started` の 20 秒後の `plymouth quit --retain-splash`）・[`daemon/gdm-local-display-factory.c`](https://gitlab.gnome.org/GNOME/gdm/-/blob/47.0/daemon/gdm-local-display-factory.c)（`on_vt_changed`）
- gdm のパッケージの履歴（AlmaLinux の git）: [actually quit plymouth at startup](https://git.almalinux.org/rpms/gdm/commit/ad6daf364e3156d2ed7950b08a9a977d3df68a0b)（2015 年の gdm 3.16 の変更。自動ログインでログイン画面が出ないときは、20 秒後に plymouth を終わらせる）
- systemd 257 のソース: [`src/systemctl/systemctl-logind.c`](https://github.com/systemd/systemd/blob/v257/src/systemctl/systemctl-logind.c)（`logind_check_inhibitors`）・[`src/login/logind-dbus.c`](https://github.com/systemd/systemd/blob/v257/src/login/logind-dbus.c)（`verify_shutdown_creds`）・[`src/shared/polkit-agent.c`](https://github.com/systemd/systemd/blob/v257/src/shared/polkit-agent.c)（`polkit_agent_open`）

---
