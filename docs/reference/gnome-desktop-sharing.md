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
  - ログインのキーリングを開くのは、GDM でパスワードを入れてログインしたときの `pam_gnome_keyring`。SSH のログイン・自動ログイン・指紋では開かない
  - キーリングが閉じていると、`set-credentials` はロックを解く窓を PC の画面に出して待ち続ける（上流 #166・#338）。接続のたびの資格情報の読み出しも失敗し、`Credentials are not set, denying client` で断る（上流 #27）
- **画面の設定**: gnome-shell は、ロック画面（`unlock-dialog` のモード）の間、`inhibit_remote_access` で画面の共有を止め、Mutter はつながっているリモートのセッションを閉じる（上流の README の「locking the screen also closes the remote desktop connection」、上流 #119・#172）
  - 無操作で暗くなったとき（`idle-delay`）も、シールドが出て同じモードになる。`lock-enabled` が false でも切れる
  - なので、`idle-delay` を 0 に、`lock-enabled` を false にする（[gnome-power.md 手順 1・2](../gnome-power.md#実施手順) の既定値）
- **ヘッドレスのセッション**: ヘッドレスのユーザーの unit（`gnome-remote-desktop-headless.service`）には `Conflicts=gnome-remote-desktop.service` がある。同じユーザーでは、片方を起動するともう片方が止まる

### 実施手順 / 手順 3: 補足: 退避と証明書

- 中身は [gnome-headless-session.md 手順 3](../gnome-headless-session.md#実施手順) と同じ形で、退避先だけが違う（`~/.local/state/gnome-desktop-sharing-setup`）
- 退避するのは、手順 4 で変える dconf のキー（`/org/gnome/desktop/remote-desktop/rdp/` の `port`・`negotiate-port`・`view-only`・`tls-cert`・`tls-key`）。未設定だったキーは空ファイルになり、ロールバックでは `reset` で戻す
- `tls-cert` と `tls-key` は、デスクトップ共有とヘッドレスのモードで共用する（ヘッドレスの専用のキーは `rdp/headless/` の下の `port`・`negotiate-port`・`enable` だけ）。`rdp/` を `dconf reset -f` すると `rdp/headless/` も消えるので、キーごとに戻す
- 証明書のパス（`~/.local/share/gnome-remote-desktop/certificates/rdp-tls.{crt,key}`）は、ヘッドレスの手順書・RHEL 10 の文書の 1.4・設定アプリ 47.7 が自分で作るときと同じ
- RHEL の文書は `winpr-makecert` で作るが、ここでは SAN を付けるために openssl で作る（[gnome-remote-desktop.md の参考資料](gnome-remote-desktop.md)）

### 実施手順 / 手順 4: 補足: grdctl（オプション無し）

- `--headless` も `--system` も付けない `grdctl` は、デスクトップ共有（上流のソースでは `GRD_RUNTIME_MODE_SCREEN_SHARE`）の設定を変える。書き先は dconf の `/org/gnome/desktop/remote-desktop/rdp/`
- 既定は `view-only=true`（見るだけ）・`negotiate-port=true`・`port=3389`・`screen-share-mode='mirror-primary'`
- `disable-port-negotiation` は、指定したポートが使われていたときに次のポートを順に試すのを止める。ポートが勝手に変わって、手順 7 で開けたポートと食い違うのを防ぐ。代わりに、ポートが使われていると待ち受けに失敗し、再試行しない
- `set-tls-cert` と `set-tls-key` は絶対パスだけを受け付ける（`~` はシェルが展開する）
- `port` と `negotiate-port` は、次に待ち受けるときに効く。`view-only` は、つないでいるクライアントにもすぐ効く

### 実施手順 / 手順 6: 補足: grdctl rdp enable

- `grdctl rdp enable` は、`/usr/libexec/gnome-remote-desktop-enable-service` を通して、セッションの systemd にユーザーの unit `gnome-remote-desktop.service` の StartUnit と EnableUnitFiles を頼む。`systemctl --user enable --now` は要らない
- unit は `WantedBy=gnome-session.target` なので、ログインのたびに起動する
- `grdctl rdp disable` は、unit を止めて無効にする

### 実施手順 / 手順 8: 補足: 待ち受けの確かめ方

- `grdctl status` の `Port:` は dconf の値で、実際に待ち受けたポートではない（上流 #255）
- 実際のポートは、`ss` か、D-Bus の `org.gnome.RemoteDesktop.User` の `/org/gnome/RemoteDesktop/Rdp/Server` の `Port` プロパティ（待ち受けていなければ -1）で見る
- `ss -p` は、自分のプロセスなら root でなくても名前を出す。システムのデーモン（リモートログイン）は `gnome-remote-desktop` ユーザーのプロセスなので、ここには名前が出ない

### 実施手順 / 手順 9: 補足: TLS プローブ

- スクリプトは [gnome-remote-desktop.md 手順 10](../gnome-remote-desktop.md#実施手順) と同じもの。第 2 引数でポートを渡す
- `/usr/bin/python3` で動かすのは、Homebrew が PATH の先頭にあるときも、同じ Python にするため

### 実施手順 / 手順 10: 補足: クライアントに写るもの

- 既定の `screen-share-mode='mirror-primary'` は、PC の主モニターをそのままの解像度で送る。クライアントの窓の大きさに合わせるための Display Control のチャネルは `extend` のときしか作られない
- デスクトップ共有で写せるモニターは 1 枚だけ
- 認証は NLA だけ（TLS だけ・RDP のセキュリティは受け付けない）。ユーザー名とパスワードは手順 5 の RDP の資格情報で、OS のアカウントではない

### 自動ログインで使う / 手順 1: 補足: パスワードの無いキーリング

- g-r-d は、ユーザーのパスワードを知らないのでキーリングを開けない（上流 #27 の開発者の説明）。自動ログインでは、ログインのキーリングは閉じたままになる
- 上流 #27 で知られている回避策は 2 つ
  - ログインのキーリングのパスワードを空にする: ほかのパスワード（ブラウザーなど）もすべて暗号化されずに置かれる
  - パスワードの無い別のキーリングに RDP の資格情報だけを置く: この手順書はこちらを採る
- パスワードの無いキーリングを、PC の画面に窓を出さずに作るには、gnome-keyring の `org.gnome.keyring.InternalUnsupportedGuiltRiddenInterface.CreateWithMasterPassword` を空のパスワードで呼ぶ（Secret Service の `CreateCollection` は、PC の画面にパスワードを聞く窓を出す）
- パスワードの無いキーリングも、gnome-keyring を起こした直後は閉じている。開くように頼まれると、パスワードを聞かずに開く（コンテナでの模擬。[検証記録](../verification/gnome-desktop-sharing.md#付録-資料とブロックの確認2026-10-06)）
- libsecret は、同じ属性の項目が開いたキーリングにあればそれを使い、閉じたキーリングにしか無ければ、それらを開こうとする
  - ログインのキーリングに項目が残っていると、そのキーリングを開く窓が要るので、写すのではなく移す（写した後に、ログインのキーリングの項目を消す）
- Secret Service のセッションは、それを開いた D-Bus の接続でしか使えないので、`busctl` を何回も呼ぶ形ではなく、1 つの接続の Python（Gio）で書いた
- 値は、`grdctl rdp set-credentials` が保存したものを `GetSecrets` で読み、そのまま `CreateItem` に渡す（ラベル・`xdg:schema` の属性も同じにする）。ユーザー名とパスワードを打ち直さない

### 選択した方針

- **デスクトップ共有にする**（RHEL 10 の文書の 1.1 の方式）
  - PC の画面に出ているデスクトップを、そのまま共有する。PC の前にいる人と、同じ画面を見て操作できる
  - モニターの無い PC なら[ヘッドレスのセッション](../gnome-headless-session.md)、ログイン画面から入るなら[リモートログイン](../gnome-remote-desktop.md)
- **CLI だけで設定する** — RHEL 10 の文書の 1.1 は設定アプリでの操作だけを書いている。CLI では、上流の README の「From command line」と同じ `grdctl`（オプション無し）を使う
- **証明書は openssl で作る** — SAN に IP を入れる理由は gnome-remote-desktop.md と同じ
- **ポートを固定し、ポートのネゴシエーションを切る** — ファイアウォールで開けたポートと食い違わないように（ヘッドレスの手順書と同じ）
- **クライアントからの操作を許す**（`disable-view-only`）— 既定の見るだけは、任意節で戻せる
- **自動ログインでは、RDP の資格情報だけをパスワードの無いキーリングへ移す** — ログインのキーリングのほかの秘密は、暗号化したまま残す

### 参照

- [Chapter 1. Remotely accessing the desktop — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/remotely-accessing-the-desktop)（1.1 Enabling desktop sharing on the server by using GNOME、1.3 の前提「For desktop sharing, a user is logged in to the GNOME graphical session on the server」）
- [GNOME/gnome-remote-desktop 49.3 README.md](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/blob/49.3/README.md)（Remote assistance の節。「From command line」）
- 上流のソース（49.3）: `src/grd-ctl.c`・`src/grd-settings-user.c`・`src/grd-credentials-libsecret.c`・`src/org.gnome.desktop.remote-desktop.gschema.xml.in`・`data/gnome-remote-desktop.service.in`・`data/gnome-remote-desktop-headless.service.in`
- 上流の issue: [#27](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/27)（キーリングが閉じていると認証できない。自動ログイン）・[#166](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/166)（SSH から資格情報を設定できない）・[#172](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/172)（ロックで切れる）・[#255](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/255)（`grdctl status` のポート）・[#338](https://gitlab.gnome.org/GNOME/gnome-remote-desktop/-/issues/338)（自動ログインの後の資格情報）
- [gnome-control-center #3547](https://gitlab.gnome.org/GNOME/gnome-control-center/-/issues/3547)（キーリングが閉じているときに「リモート デスクトップ」を開くと、パスワードが乱数に書き換わる。GNOME 50 で修正）

---
