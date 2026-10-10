# GNOME Remote Desktop 有効化手順（リモートログイン方式）の検証記録

[手順書](../gnome-remote-desktop.md)・[ロールバックと注意点](../extra/gnome-remote-desktop.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順 / 手順 0: 本文中の記録

- 2026-10-02 より前にこの手順を終えたサーバーは、[設定済みのサーバーで GDM の後に起動させる](../gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる)を行う（手順 5 のドロップインが無い）

### 実施手順 / 手順 2: 補足: 証明書

- OpenSSL 3.x では `-nodes` は deprecated。`-noenc` を使う
- `hostname` と `hostname -f` が同じ値を返す環境（環境 2。`SERVER_NAME` = `SERVER_FQDN`）では、SAN に同じ DNS エントリが 2 つ入る。エラーにはならず、動作にも影響しない

生成物:

```
/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
```

環境 2 で生成された証明書の内容:

```
$ sudo openssl x509 -in /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt -noout -subject -dates -ext subjectAltName,extendedKeyUsage
subject=CN=<HOSTNAME>
notBefore=Sep 16 16:02:07 2026 GMT
notAfter=Sep 13 16:02:07 2036 GMT
X509v3 Subject Alternative Name:
    DNS:<HOSTNAME>, DNS:<HOSTNAME>, DNS:<SERVER_IP>, IP Address:<SERVER_IP>
X509v3 Extended Key Usage:
    TLS Web Server Authentication
```

**GRD が証明書に要求するもの**

特殊な拡張や独自形式の要求は無く、要件は 3 つだけ:

- **PEM 形式**であること（OpenSSH 形式の鍵は不可。`grdctl status` が `[x509_utils_from_pem]: BIO_new failed` を出す）
- システムデーモン用は **`gnome-remote-desktop` ユーザー/グループ所有**で読めること
- SELinux コンテキストが `gnome_remote_desktop_var_lib_t`（`/var/lib/gnome-remote-desktop` 配下に置けば自動で付く）

**SAN と有効期間を指定している理由**

- **SAN を付与** — 付けないと CN だけで照合され、IP アドレスで接続したときにクライアントで毎回「名前が一致しない」警告が出る
- **有効期間 10 年** — 自己署名証明書を毎年更新する手間を避ける

**落とし穴: FreeRDP は SAN の `IP:` を見ない**

**FreeRDP 3.10 は SAN の DNS エントリしか照合せず、`IP:` エントリを無視する。** IP アドレスで接続する運用なら、IP を **DNS エントリとしても併記**する必要がある（この手順のコマンドの `DNS:${SERVER_IP}`）。

`DNS:${SERVER_IP}` を入れずに `IP:${SERVER_IP}` だけにした場合、`${SERVER_IP}` で接続すると:

```
@           WARNING: CERTIFICATE NAME MISMATCH!           @
The hostname used for this connection (<SERVER_IP>:3389)
does not match any of the names given in the certificate:
Common Name (CN):
	<HOSTNAME>
Alternative names:
	 <HOSTNAME>
	 <HOSTNAME>.<DOMAIN>          ← IP エントリが列挙されていない
```

`DNS:${SERVER_IP}` を追加すると警告は消える（環境 1 で実測）。

### 実施手順 / 手順 5: 補足: サービスとファイアウォール

- `gdm` は両環境とも既に active、`systemctl get-default` も既に `graphical.target` だったため、RHEL 標準手順にある `systemctl enable --now gdm` / `systemctl set-default graphical.target` は不要だった
- `--add-service=rdp` は firewalld 定義済みサービスで 3389/tcp を開放する（`--add-port=3389/tcp` と等価）

**GDM の後に起動させる理由**

- パッケージの `gnome-remote-desktop.service` には GDM との順序が無い。環境 2 では、起動のときに GDM より 6 秒先に立ち上がった
- 先に立ち上がると、GDM が表示の一覧を公開する前に取りに行って失敗する。その後は、表示の変更（ログイン画面がどのセッションか）を受け取れない
- その起動の間は、リモートログインがいつも、資格情報は通るのに真っ暗な画面のまま 30 秒で切れる（[付録](#付録-真っ暗な画面のまま切れた原因の調査記録環境-22026-10-02)）
- `After=gdm.service` は順番だけを決める。GDM が無いと起動しない、といった依存は足さない

### 設定済みのサーバーで GDM の後に起動させる / 手順 0: 本文中の記録

- **この節の手順 1 は、`/etc/systemd/system/gnome-remote-desktop.service.d/10-after-gdm.conf` が無いサーバーだけ**（2026-10-02 より前の手順 5 で設定したもの）。今の手順 5 は、このドロップインを置く

### 設定済みのサーバーで GDM の後に起動させる / 手順 3: 補足: restart にしない理由

- 残っていたログイン画面のセッションは、デーモンが消えると閉じ、GDM はその表示を消す
- `restart` では、これが新しいデーモンの起動と重なる。環境 2 では、新しいデーモンが表示の一覧を読む間に消えた表示を取りこぼし、消えた表示を持ったままになった
- GDM は表示のパスを使い回す。同じパスで次のログイン画面が作られると、デーモンはそれを新しい表示として扱わず、引き渡し口を作らない。その 1 回は真っ暗なまま切れた（[付録](#付録-真っ暗な画面のまま切れた原因の調査記録環境-22026-10-02)）
- 止めて 5 秒待つと、ログイン画面のセッションが閉じてから新しいデーモンが起動する

### 設定済みのサーバーで GDM の後に起動させる / 手順 4: 補足: 受け渡し役のデーモンを再起動する理由

- 受け渡し役のデーモンは、システムのデーモンが消えると引き渡し口（`/org/gnome/RemoteDesktop/Rdp/Handovers/session<ID>`）を手放し、戻ると取り直す（RHEL の独自パッチ）
- 取り直すときに口がまだ無いと、口が足されるのを待つ。環境 2 では、2 回とも待つほうに入った
- 待ち方に 2 つの穴があり、どちらでも止まった
  - 1 回目: 足された口が自分のものかを、自分のセッション ID で確かめる。ユーザーのサービス（`gnome-remote-desktop-handover.service`）はセッションの外にいるので ID を引けず、`Could not get session id` を出して見送った（4 回出た）
  - 2 回目: 口は、待ち始める前に足されていた（D-Bus の記録で、断られてから 9 ミリ秒後に口ができていた）。パッチは「後から足された」知らせしか見ないので、何も出さずに待ち続けた
- 再起動すると、最初の問い合わせ（システムのデーモンがユーザーからセッションを引く）で口が見つかる。環境 2 では、2 回とも `RDP server started` まで進んだ
- 取り直さないままだと、そのユーザーでログインしたときに、ログイン画面はパスワードを受け付けた後、名前とアイコンのまま進まなかった（1 分以上待ってもタイムアウトしない。試験用のユーザーで確かめた）
- 待っている間に受け渡し役のデーモンを再起動すると、その場で引き渡された

### 対象と検証環境

- **方式**: リモートログイン（システムデーモン `grdctl --system`）
- **TLS 証明書**: openssl で生成（追加パッケージ不要）
- **状態**: 下記 2 環境で動作確認済み。加えて、クリーンインストールした x86_64 の VM で実施手順 1〜11・LAN 限定・ロールバック 1・2 を本実行し、再起動後の GDM からのログインまで確認した（2026-10-06。[今回の付録](#付録-クリーンインストールした-vm-での検証2026-10-06)）
  - 2026-10-06: 別の新規 VM で現行手順を再検証した。今回の実施・解除・未実施範囲は[新しい付録](#付録-現行版の新規-vm-での再検証2026-10-06)に記録した
  - 2026-09-28: 手順 2〜5・8・9、[ロールバック](../extra/gnome-remote-desktop.md#ロールバック)の手順 1、[注意点](../extra/gnome-remote-desktop.md#注意点)の「設定レイヤーの食い違い」の確認方法のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-02: 手順 5 に GDM の後に起動させるドロップインを足し、[設定済みのサーバーで GDM の後に起動させる](../gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる)を足した
    - 環境 2 で、Windows 11 からのリモートログインが真っ暗な画面のまま切れたため（[付録](#付録-真っ暗な画面のまま切れた原因の調査記録環境-22026-10-02)）
    - その節の手順 1〜5 は、環境 2 の実機で流した（手順 5 の後は、手順 1 で置き直した）
    - 直した後、利用者が Windows 11 の「リモートデスクトップ接続」でつなぎ、GDM のログイン画面が出て、ログインできた（ヘッドレスのセッションに引き渡された。[注意点](../extra/gnome-remote-desktop.md#注意点)）
    - その節の手順 3 は、はじめ `restart` で流した。その後の最初の接続だけが、また真っ暗なまま切れたので、止めて待ってから起動する今の形に直し、流し直した（付録）。今の形で起動し直した後は、1 回目の接続から通った（FreeRDP で。Windows からは確かめていない）
    - 同じ日に、ヘッドレスのセッションとの組み合わせ・切断とつなぎ直し・同時の接続・GDM の再起動を、試験用のユーザーとコンテナの FreeRDP 3.10.3 で確かめた（[付録の追加の確認](#追加の確認)）。システム共通の RDP の資格情報は、ファイルを控えてテスト用の値に差し替え、終わってから戻した
    - 手順 5 の今のブロックと、[ロールバック](../extra/gnome-remote-desktop.md#ロールバック)の手順 1 は、構文の検査だけで、流していない
    - 起動のときにドロップインが効くこと（再起動して確かめること）は、まだしていない
  - 2026-10-05: 証明書生成の空変数検査、起動し直しの共通手順への参照、LAN 限定の rich rule の撤去を追加した。変更後は構文検査とスタブでの確認だけで、実機では流していない

| | 環境 1（初回構築） | 環境 2（openssl 手順の再検証） |
|---|---|---|
| 実施日 | 2026-09-08 | 2026-09-16 |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64 | AlmaLinux 10.2 (Lavender Lion) / aarch64 |
| `gnome-remote-desktop` | 49.3-4.el10_2 | 49.3-4.el10_2 |
| `gdm` | 47.0-22.el10_2 | 47.0-22.el10_2 |
| OpenSSL | 3.5 | 3.5.8 |
| 証明書 | 当初 `winpr-makecert` → 後に openssl 製へ差し替え | 最初から本書の openssl 手順で構築 |
| 確認範囲 | 実クライアント（Android）から GDM ログインまで | TLS ハンドシェイク・証明書提示まで（[手順 10 の補足](../gnome-remote-desktop.md#実施手順)）。2026-10-02 に、実クライアント（Windows 11）と FreeRDP 3.10.3 から GDM ログインまで |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../gnome-remote-desktop.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${SERVER_IP}` | クライアントが接続に使うサーバーの IP アドレス | `192.168.10.100` |
> | `${LAN_SUBNET}` | LAN のサブネット。[接続元を LAN に絞る](../gnome-remote-desktop.md#接続元を-lan-に絞る任意)場合だけ、その節の冒頭で設定する | `192.168.10.0/24` |
> | `${SERVER_NAME}` / `${SERVER_FQDN}` | サーバーのホスト名 / FQDN（`hostname` / `hostname -f` から自動で入る） | `my-server` / `my-server.lan` |
>
> 出力例・ログ・表の中の値は `<HOSTNAME>` / `<HOSTNAME>.<DOMAIN>` / `<SERVER_IP>` / `<USER>`（OS アカウント名）/ `<FINGERPRINT>`（証明書の TLS fingerprint）のプレースホルダで書いてある。
>
> - **`<...>` を含むコマンドは bash のコードブロックには置かない**（本文中のインラインコードで示し、値に読み替える）
> - 読者が値を入れる必要があるコードブロックは、先頭で変数が空なら中断するようにしてあり、値を入れずに貼っても何も実行されない
>
> TLS fingerprint は**証明書を生成するたびに変わる**ので、自環境では `grdctl --system status` の表示を正とすること。

手順書全体に関わる理由・実測・落とし穴と調査記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| `gnome-remote-desktop` | インストール済み（`/usr/bin/grdctl` あり） |
| RDP バックエンド | 無効（`Status: disabled`） |
| `gnome-remote-desktop.service` | `disabled` / `inactive` |
| TLS 証明書・鍵 | 未設定（`grdctl status` が証明書エラーを出力 / `TLS certificate: (null)`） |
| システム RDP 資格情報 | 未設定 |
| `gdm` | active、`systemctl get-default` = `graphical.target` |
| firewalld | active、default zone = `public`、3389/tcp 未開放 |
| SELinux | Enforcing |
| `freerdp` / `podman` | 未インストール（本手順では不要） |
| NIC | 環境 1: `bridge0` = <SERVER_IP>/24、`enp198s0f3u1u1`（ともに public ゾーン）<br>環境 2: `end0` = <SERVER_IP>/24（public ゾーン） |

### 完了時点の状態

環境 2 の出力:

```
$ sudo grdctl --system status
Overall:
	Unit status: active
RDP:
	Status: enabled
	Port: 3389
	TLS certificate: /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
	TLS fingerprint: <FINGERPRINT>
	TLS key: /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
	Username: (hidden)
	Password: (hidden)

$ systemctl is-enabled gnome-remote-desktop.service
enabled
$ systemctl is-active gnome-remote-desktop.service
active
$ ss -lntp | grep 3389
LISTEN 0      5                  *:3389             *:*
$ firewall-cmd --list-services
cockpit dhcpv6-client rdp ssh
```

journal:

```
gnome-remote-de[2415]: RDP server started
```

---

### 注意点 / 手順 0: 本文中の記録

  - 切断してもセッションは残り、次に同じユーザーでログインすると、そのセッションに戻った（環境 2、2026-10-02。[付録の追加の確認](#追加の確認)）

### 注意点 / 手順 0: 本文中の記録

  - そのユーザーでログイン画面からログインすると、新しいセッションは作られず、常駐しているヘッドレスのセッションに引き渡された（環境 2、2026-10-02。Windows 11 の「リモートデスクトップ接続」と FreeRDP で）

### 注意点 / 手順 0: 本文中の記録

- **GDM を再起動したとき**: 1 回試した範囲では、このデーモンはすれ違わず、リモートログインは通った（環境 2、2026-10-02）

### 付録: ログインできなかった原因の調査記録（環境 1、2026-09-08）

#### 判明した 2 つの落とし穴

##### 落とし穴 1: `grdctl` の対話入力は TTY 必須

`grdctl --system rdp set-credentials` を引数なしで実行すると `Username: ` / `Password: ` のプロンプトが出るが、これは **stdin ではなく制御端末（TTY）から直接読む**（`getpass` 相当）。

そのため以下はいずれも**失敗する（しかも exit 0 で成功したように見える）**:

```bash
# NG: TTY がない実行環境（スクリプト、Claude Code の ! 実行など）
sudo grdctl --system rdp set-credentials

# NG: パイプで流し込む
printf 'user\npass\n' | sudo grdctl --system rdp set-credentials
```

対処は、本物の端末エミュレータ上で対話入力する（パスワードが記録に残らないため推奨）:

```bash
sudo grdctl --system rdp set-credentials
```

引数で渡す形（`sudo grdctl --system rdp set-credentials <username> <password>`）でも設定できるが、シェル履歴・`ps`・会話ログに残る。

設定できたかは次で確認する。`(empty)` / `(null)` なら未設定、`(hidden)` なら設定済み:

```bash
sudo grdctl --system status | grep Username
```

> `--show-credentials` を付けるとパスワードが**平文で表示される**。設定の有無を見るだけなら付けないこと。

##### 落とし穴 2: 資格情報の変更にはデーモンの再起動が必要

デーモンは**起動時に資格情報を読み込んでキャッシュする**。稼働中に `grdctl` で設定・変更しても反映されず、ログには次が出続ける:

```
[RDP] Credentials are not set, denying client
```

`grdctl --system status` 側は設定済みに見えるため紛らわしい。設定・変更のたびに再起動する:

```bash
sudo systemctl restart gnome-remote-desktop.service
```

#### ログによる失敗原因の切り分け

`journalctl -u gnome-remote-desktop -f` を見ながら接続すると、失敗の種類がログの署名で判別できる。ループバック接続テスト（`xfreerdp /v:127.0.0.1:3389 /u:<user> /p:<pass> /cert:ignore /auth-only`）で実測した結果:

| 状況 | サーバー側ログの署名 |
|---|---|
| 資格情報が未設定 / 未反映 | `[RDP] Credentials are not set, denying client` |
| **ユーザー名が不一致** | `ntlm_fetch_ntlm_v2_hash: Could not find user in SAM database`<br>`AcceptSecurityContext status SEC_E_NO_CREDENTIALS [0x8009030E]` |
| **パスワードが不一致** | `AcceptSecurityContext status SEC_E_MESSAGE_ALTERED [0x8009030F]` |
| 認証成功 | 上記エラーが出ず `[DaemonSystem] ... handover` 系のログに進む |

ユーザー名不一致とパスワード不一致が**別の署名になる**点が切り分けの決め手。

なお NLA 失敗の直後に出る以下は、失敗したクライアントが低いセキュリティレベルで再接続を試みて GRD が拒否した副次的なログであり、独立した問題ではない:

```
[rdp_server_accept_nego]: server supports only NLA Security
[rdp_server_accept_nego]: Protocol security negotiation failure
[freerdp_tls_handshake]: BIO_do_handshake failed
```

#### ユーザー名の照合仕様（実測）

ループバックテストで確認した挙動:

| テスト | 結果 |
|---|---|
| 正しいユーザー名・パスワード | **成功**（NLA 通過 → handover まで到達） |
| ユーザー名が違う | 失敗（SAM database エラー） |
| パスワードが違う | 失敗（MESSAGE_ALTERED） |
| ドメイン付き `/d:WORKGROUP` | **成功** — ドメイン部分は無視される |
| 大文字小文字違い（`RDPTEST` vs `rdptest`） | **失敗** — 照合は **case-sensitive** |
| ハイフン入り（`my-user`） | **成功** — ハイフンは問題なし |

→ **ユーザー名の大文字小文字は完全一致が必要。ドメイン欄の値は影響しない。**

#### 常に出るが無害なログ

以下は環境要因による既知の出力で、RDP 接続の成否とは無関係:

- `Init TPM credentials failed ... using GKeyFile as fallback` — TPM 非対応環境でのフォールバック
- SELinux AVC: `/dev/tpm0`・`/dev/tpmrm0` への `getattr` 拒否、TCP ポート 2321 への `name_connect` 拒否 — いずれも上記 TPM 初期化試行に伴うもの
- `kerberos_AcquireCredentialsHandleA: krb5_init_context ...` — Kerberos 未設定環境で NTLM にフォールバックする際の出力

---

### 決着: 原因はクライアント側のユーザー名の誤り

#### 結論

接続失敗の原因は、**Android クライアントに入力していたユーザー名が、サーバーに設定した値（`<USER>`）と違っていた**こと。クライアント側で正しいユーザー名に修正して解決した。

サーバー側の設定（TLS 証明書・サービス・ファイアウォール・GDM ハンドオーバー）はすべて当初から正常だった。

#### 成功時のログ

```
09:25:42  [RDP] Client cannot handle graphics and audio simultaneously. Disabling audio output redirection
09:25:43  [RDP] Sending server redirection          ← GDM へのハンドオーバー成功
09:25:43  ERRINFO_LOGOFF_BY_USER                    ← 利用者によるログオフ
```

`Sending server redirection` が出れば、1 段目の RDP 認証を通過して GDM／ユーザーセッションへの引き渡しに成功している。

#### 設定済みユーザー名の確認方法

`grdctl --system status` は `(hidden)` としか表示せず、`--show-credentials` を使うとパスワードまで平文で出てしまう。**ユーザー名だけ**を確認したい場合は資格情報ストアから該当フィールドのみ抽出する:

```bash
sudo grep -oP "'username':\s*<'\K[^']*" \
  /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/credentials.ini
```

資格情報は GVariant 形式で `credentials=` という 1 つのキーにまとめて格納されている（`/etc/gnome-remote-desktop/grd.conf` の方には TLS 設定と `enabled` しか無い）。

#### デバッグ用の詳細ログ（必要時のみ）

FreeRDP の詳細ログは systemd ドロップインで有効化できる:

```bash
sudo mkdir -p /etc/systemd/system/gnome-remote-desktop.service.d
sudo tee /etc/systemd/system/gnome-remote-desktop.service.d/99-debug.conf <<'CONF'
[Service]
Environment=WLOG_LEVEL=TRACE
CONF
sudo systemctl daemon-reload && sudo systemctl restart gnome-remote-desktop.service
```

これでクライアントが送るユーザー名が `mstshash` クッキーとして見える場合がある:

```
[DEBUG][com.freerdp.core.nego] - [nego_read_request_token_or_cookie]:
    received cookie [Cookie: mstshash=<クライアントが送ったユーザー名>]
```

ただし注意点が 2 つある:

- **`mstshash` を送らないクライアントもある**（今回の Android クライアントは送らなかった）。その場合ユーザー名はログから特定できない。NLA は TLS 内で流れるため、パケットキャプチャでも読めない。
- **TRACE は極めて冗長**で、`[Pcap_Open]: Recursion detected!` というスタックトレースを大量に吐く既知の不具合がある。

調査が終わったら必ず削除する:

```bash
sudo rm -f /etc/systemd/system/gnome-remote-desktop.service.d/99-debug.conf
sudo rmdir /etc/systemd/system/gnome-remote-desktop.service.d
sudo systemctl daemon-reload && sudo systemctl restart gnome-remote-desktop.service
sudo systemctl show gnome-remote-desktop -p Environment   # 空であることを確認
```

> `systemctl restart` は**接続中の RDP セッションを切断する**。利用者がいないタイミングで実行すること。

#### 教訓

ログの署名を最初に確認していれば早く切り分けられた。順に:

1. `Credentials are not set` → 未設定、または設定後にデーモンを再起動していない
1. `Could not find user in SAM database` → **ユーザー名**が違う
1. `SEC_E_MESSAGE_ALTERED` → **パスワード**が違う
1. `Sending server redirection` → 認証成功

今回は一貫して 2 が出ていた（3 は一度も出ていない）ため、パスワードの再設定を繰り返しても解決しなかった。

---

### 付録: winpr-makecert で証明書を作る場合（RHEL 10 公式手順）

環境 1 では当初この方法で構築し、後に openssl 製へ差し替えた。以下はその記録。

| 項目 | 値 |
|---|---|
| 種別 | X.509 v3、自己署名（Issuer = Subject） |
| Subject | `CN=<hostname>` |
| 鍵 | RSA 2048 bit、PKCS#8 PEM（`-----BEGIN PRIVATE KEY-----`） |
| 署名 | sha256WithRSAEncryption |
| 有効期間 | 1 年 |
| 拡張 | `Extended Key Usage: TLS Web Server Authentication` のみ |
| SAN | **なし** |

#### winpr-makecert 製証明書のプロファイル（実測）

##### 注意点（すべて実測で確認）

#### openssl 製との比較（実測）

環境 1 で方式 2 の証明書に差し替えて動作確認した（確認後は openssl 製に戻してある）。

#### 方式 1: ホストに freerdp をインストールする（環境 1 で当初実施）

→ `freerdp-2:3.10.3-12.el10_2.10.x86_64` をインストール。

ホストにパッケージを入れずに winpr-makecert 製の証明書が必要な場合。rootless podman で動作確認済み（環境 1）。[手順 1](../gnome-remote-desktop.md#実施手順) の変数を設定したうえで:

- イメージ pull に約 200 MB のダウンロードが発生する

| 確認項目 | 結果 |
|---|---|
| `grdctl --system status` の fingerprint | `8a:24:8a:40:…` に切り替わった |
| クライアントに届く Thumbprint | `8a:24:8a:40:…` で **grdctl の表示と完全一致** |
| TLS ハンドシェイク | 成功（NLA 段階の `SAM database` まで到達、`BIO_do_handshake` は出ない） |
| ホスト名 `<HOSTNAME>` で接続 | 名前不一致なし |
| IP `<SERVER_IP>` で接続 | **名前不一致の警告あり** |

IP で接続したときの警告は SAN が無いことが原因で、openssl 製との実質的な差はここだけ:

```
The hostname used for this connection (<SERVER_IP>:3389)
does not match the name given in the certificate:      ← 単数形。SAN が無く CN のみ
Common Name (CN):
	<HOSTNAME>
```

openssl 製では「Alternative names」の一覧が出るのに対し、winpr-makecert 製は SAN 自体が無いため CN だけで照合される。**ホスト名で接続する運用なら winpr-makecert 製でも実用上問題ない。IP で接続するなら openssl 製を使う。** また有効期間が 1 年なので、毎年の更新が必要になる。

---

### 付録: 真っ暗な画面のまま切れた原因の調査記録（環境 2、2026-10-02）

Windows 11 の「リモートデスクトップ接続」から環境 2 にリモートログインすると、資格情報は通るのに真っ暗な画面のまま切れた。そのときの切り分けと、直した記録。

| 項目 | 版 |
|---|---|
| `gnome-remote-desktop` | 49.3-4.el10_2 |
| `gdm` | 47.0-24.el10_2 |
| `glib2` | 2.80.4-12.el10_2.22 |
| `gnome-shell` / `mutter` | 49.4 |

#### 症状

- つなぐたびに、システムデーモンのログが次の形になった（前日の 2 回も同じ）

  ```
  01:02:55  [RDP] Network or intentional disconnect, stopping session
  01:03:26  [DaemonSystem] Aborting handover, removing remote client with remote id /org/gnome/RemoteDesktop/Client/1151524738
  01:03:26  [ERROR][com.freerdp.core.peer] - [rdp_set_error_info]: ERRINFO_CB_CONNECTION_CANCELLED [0x00010409]
  ```

- 成功したときに出る `[RDP] Sending server redirection`（[成功時のログ](#成功時のログ)）が出ない。打ち切りは、つないでから約 30 秒後
- つなぐたびに、GDM がリモートログイン用のログイン画面のセッションを作った（`loginctl` で `gdm` の `greeter`、SEAT が `-`、`Remote=yes`）
  - その中で `gnome-remote-desktop-daemon --handover` は動いていたが、何も出力していなかった
  - 打ち切られた後もセッションは残り、前日の分と合わせて 4 つになっていた（gnome-shell が約 150MB ずつ）
- 同じ秒に `transport_read_layer: ... Connection reset by peer` と `client authentication failure` も出ていた。ただ、ログイン画面のセッションはできていたので、資格情報は通っている

#### 切り分け

- GDM の表示の一覧（`busctl --system call org.gnome.DisplayManager /org/gnome/DisplayManager/Displays org.freedesktop.DBus.ObjectManager GetManagedObjects`）
  - ログイン画面の表示には、`RemoteId`（打ち切りのログの remote id）と `SessionId`（`c291` など）が正しく入っていた
- システムデーモンの引き渡し口（`busctl --system tree org.gnome.RemoteDesktop`）
  - `/org/gnome/RemoteDesktop/Rdp/Handovers/` に、ログイン画面のセッションの口が無かった
  - ヘッドレスのセッションの口（`session62` など）はあった。終わったヘッドレスのセッションの分も、17 個消えずに残っていた
- 起動のときのログ（GDM が立ち上がったのと同じ秒）に、[設定済みのサーバーで GDM の後に起動させる](../gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる)の手順 2 の補足の警告が出ていた
  - `gnome-remote-desktop.service` は 00:09:12、`gdm.service` は 00:09:18 に始まっていた。ユニットの `After=` に GDM は無い

#### 原因

gnome-remote-desktop 49.3（と CentOS Stream 10 の独自パッチ）・gdm 47.0・GLib 2.80.4 のソースを読み、次のようにつながると判断した。

1. GDM は、バス名 `org.gnome.DisplayManager` を取ってから、表示の一覧（`/org/gnome/DisplayManager/Displays`）を公開する（`on_name_acquired` の中の `register_manager`）
1. 先に起動して待っていたシステムデーモンは、バス名が現れてすぐに一覧（`GetManagedObjects`）を取りに行き、公開の前だったので失敗した（起動のときの警告）
1. GLib の `GDBusObjectManagerClient` は、この失敗のとき、子のオブジェクトのシグナルの購読を外したままにする（`on_get_managed_objects_finish` の `maybe_unsubscribe_signals`）
   - 表示の追加と削除（`InterfacesAdded` / `InterfacesRemoved`）は別の購読で受けるので、その後も届く
   - 表示のプロパティの変更（`PropertiesChanged`）は届かない
1. ログイン画面の表示は、`SessionId` が空のまま追加され、ログイン画面のセッションができてから `PropertiesChanged` で `SessionId` が入る（gdm の `gdm-remote-display.c` の `g_object_bind_property`）
1. システムデーモンはこれを受け取れないので、ログイン画面のセッションの引き渡し口を作らない
1. ログイン画面の handover デーモンは、口が無いと、できるのを黙って待つ（RHEL の独自パッチ）。そのまま 30 秒たち、システムデーモンが接続を打ち切る。その間、クライアントには何も描かれない

- ヘッドレスのセッションの表示は `SessionId` が入った状態で追加されるので、口はできていた
- 終わったヘッドレスのセッションの口が残ったのは、システムデーモンが付け直した `RemoteId` の変更が届かず、削除のときに照合できなかったためと考えられる（確かめていない）

#### 直した記録

**1 回目（06:04。その節の手順 3 は、当時は `restart` だった）**

- [設定済みのサーバーで GDM の後に起動させる](../gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる)の手順 1〜3 を流した
  - その節の手順 2 は `1`、手順 3 の後は `RDP server started` の 1 行だけだった
  - 残っていた 4 つのログイン画面のセッションは閉じた（ログイン画面の handover デーモンは、システムデーモンが消えると logout する）
  - ただし、閉じたログイン画面の口が 1 つ（`sessionc44`）、新しいシステムデーモンに残った
- その後、ヘッドレスのセッションの受け渡し役のデーモンが `[DaemonHandover] Could not get session id` を 4 回出した
  - 引き渡し口 `session62` は、システムデーモンの側には戻っていた
  - その節の手順 4 で再起動すると、`RDP server started` まで進んだ
- その節の手順 5（元に戻す）は、流してから手順 1 で置き直した（動いているデーモンには触れない）

**Windows からの確認（06:30〜06:34）**

利用者が Windows 11 の「リモートデスクトップ接続」で 3 回つないだ。D-Bus の流れは `sudo busctl --system monitor` で記録した。

| つないだ時刻 | ログイン画面のセッション | 結果 |
|---|---|---|
| 06:30:08 | c310 | 真っ暗なまま。15 秒後にクライアントが切った（`ERRINFO_LOGOFF_BY_USER`） |
| 06:30:26 | c311 | `[RDP] Sending server redirection` の後、ログイン画面が出た |
| 06:31:30 | c312 | ログイン画面が出て、ヘッドレスのセッションのユーザー（`<USER>`）でログインした |

- 2・3 回目は、GDM が `SessionId` を入れた（PropertiesChanged）数ミリ秒後に、システムデーモンがログイン画面の引き渡し口を作った
- 1 回目は、口が作られなかった。ログイン画面の handover デーモンの `RequestHandover` は `No handover interface for session` で返り、そのまま待った
  - GDM がこのとき作った表示のパス（`/org/gnome/DisplayManager/Displays/366850084816`）は、06:04 に閉じた c44 の表示と同じだった
  - 新しいシステムデーモンは、起動の途中で消えた c44 の表示を取りこぼし、持ったままだった（`sessionc44` の口が残ったのもこのため）。同じパスの表示は新しい表示として扱われず、口が作られなかった、と考えられる
- 3 回目のログインでは、GDM がヘッドレスのセッションの表示の `RemoteId` を、この接続のものに付け替えた
  - システムデーモンは `session62` の口を待ち状態（`HandoverIsWaiting`）にした。ヘッドレスのセッションの受け渡し役のデーモンが、`StartHandover`・`TakeClient` で接続を引き取った
  - そのセッションの gnome-shell に `Added virtual monitor Meta-1` が出た。切断（06:34:13）で `Removed virtual monitor Meta-1` が出て、セッションは残った
  - このとき、システムデーモンが `GLib-CRITICAL **: g_atomic_ref_count_dec: assertion 'old_value > 0' failed` を 1 回出した。デーモンは動き続けた

**2 回目（06:37。その節の手順 3 を今の形にして）**

- 1 回目の接続のログイン画面のセッション（c310）を `sudo loginctl terminate-session c310` で閉じてから、その節の手順 3（止めて 5 秒待ってから起動）を流した
  - `RDP server started` の 1 行だけが出て、引き渡し口は `session62` だけになった（`sessionc44` も消えた）
- ヘッドレスのセッションの受け渡し役のデーモンは、今度は何も出さずに止まった
  - `RequestHandover` が `No handover interface for session` で返った 9 ミリ秒後に、システムデーモンが `session62` の口を作った
  - 受け渡し役のデーモンは、その後で口の一覧を読み始めた。`session62` を「後から足された口」として受け取れず、待ち続けた（RHEL のパッチは、足されたときの知らせしか見ない）
  - その節の手順 4 で再起動すると、`RequestHandover` が `session62` を返し、`RDP server started` まで進んだ
- 今の形で起動し直した後の接続は、追加の確認の 1 回目（FreeRDP）で通った。Windows からは確かめていない
- 起動のときにドロップインが効くか（次の起動で `Error calling GetManagedObjects` が出ないか）は、まだ確かめていない

#### 追加の確認

同じ日の 07:13〜07:31 に、まだ確かめていなかった組み合わせを、試験用のユーザー（`grdtest`。終わってから消した）とコンテナの FreeRDP 3.10.3 で確かめた。

- クライアントの窓は常駐しているヘッドレスのセッションの画面に出し、[claude-code-gui.md](../claude-code-gui.md) の `scripts/gnome-gui.py` で撮って操作した
- システム共通の RDP の資格情報は、`credentials.ini` を中身を読まずに控え、テスト用の値に差し替えた。終わってから控えを戻し、ハッシュが同じことを確かめた
- 試験用のユーザーのヘッドレスのセッションの RDP は、[gnome-headless-session.md](../gnome-headless-session.md) と同じ設定で 3390 にした（ドロップインは最後の確認でだけ置いた）
- 差し替えた後、[設定済みのサーバーで GDM の後に起動させる](../gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる)の手順 3・4 で起動し直してから始めた

| 確かめたこと | 結果 |
|---|---|
| 起動し直した後の 1 回目の接続 | ログイン画面が出た |
| ヘッドレスのセッションの無いユーザーでログイン | 新しいセッション（`Remote=yes`、`Service=gdm-password`）ができ、クライアントにはデスクトップ全体が出た |
| そのセッションを切断 | クライアント用のモニターは消え、セッションは残った |
| 同じユーザーでもう一度ログイン | 残っていたセッションに戻った（開いたままの窓もそのまま） |
| ヘッドレスのセッションの RDP（3390）に直接つなぐ | ログイン画面を通らず、そのセッションに入った |
| 3390 でつないだまま、3389 から同じユーザーでログイン | 3389 の方がそのセッションに入り、3390 の接続は切られた（サーバーは `ERRINFO_RPC_INITIATED_DISCONNECT`、クライアントは `ERRINFO_LOGOFF_BY_USER`） |
| 3389 でつないだまま、3390 からつなぐ | 3390 の方が入り、3389 の接続は切られた |
| 受け渡し役が止まったまま、同じユーザーでログイン | パスワードは通った（ログインのキーリングも開いた）が、ログイン画面が名前とアイコンのまま 1 分以上進まなかった |
| その状態で受け渡し役を再起動 | その場で引き渡され、セッションに入った |
| GDM を再起動してからログイン | すれ違いの警告は出ず、ログインまで通った |
| ドロップイン（`--virtual-monitor`）のあるヘッドレスのセッションに 3389 で入る | `Meta-1` が足され、クライアントには壁紙だけが写った（上部バーもウィンドウも無い） |

- 2 段目の引き渡し（ログイン画面からユーザーのセッションへ）のたびに、システムデーモンが `GLib-CRITICAL **: g_atomic_ref_count_dec: assertion 'old_value > 0' failed` を 1 回出した（6 回とも）。デーモンは動き続け、次の接続にも影響は無かった
- GDM を再起動すると、2 つのヘッドレスのセッションが止まって起動し直された
  - `<USER>` の方は、起動し直しが前のセッションの片付けとぶつかって 1 秒で終わった。`sudo systemctl start gnome-headless-session@<USER>.service` で起動した
  - 終わったセッションは、その間に PAM が起こしたキーリングのデーモンが新しいセッションにも使われていて、`closing` のまま残った
- 2026-10-02 の実機では確かめていないこと: 起動のときにドロップインが効くこと（PC の再起動）、Windows からの同じ確認。再起動は 2026-10-06 の x86_64 の VM で確認した（末尾の付録）

### 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を ISO から新規に入れた VirtualBox の VM（x86_64、1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で、検証用ユーザーの SSH PTY に現行のブロックを個別に貼った。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、GNOME Shell は `49.4-9.el10_2.alma.1`、Mutter は `49.4-4.el10_2`、GDM は `47.0-24.el10_2`、GNOME Remote Desktop は `49.3-4.el10_2`。利用者のアカウントは使っていない。

実施手順 1〜11、接続元を LAN に絞る任意節、ロールバック 1・2 を本実行した。手順 7 は、参照先の「設定済みのサーバーで GDM の後に起動させる」の手順 3・4（stop → 5 秒 → start と、受け渡し役の再起動）を通した。証明書・秘密鍵の所有者、0644・0600、SELinux のラベル、modulus の一致、TLS 1.3 と fingerprint の一致を確認した。手順 8 の `firewall-cmd --list-services` は、SSH の一般ユーザーからは polkit の `Authorization failed` で失敗したため `sudo` を付け、同じブロックを流し直して成功した。

クライアントは LAN の別の AlmaLinux VM。AppStream の `freerdp-3.10.3-12.el10_2.13` を、Homebrew の Xvfb 21.1.24（1600x900）と xdotool 4.20260303.1 で操作し、XGetImage から PNG を保存して実像を確認した。証明書の指紋はサーバー側と照合して一時的に受け入れた。システム共通の資格情報と GDM の OS パスワードは、使い捨ての値を端末または GUI に対話入力し、引数・ログには出していない。

| 確認 | 結果 |
|---|---|
| GDM のログイン画面 | 3389 番のシステム共通の認証後、ユーザー一覧と OS パスワード欄が表示された |
| ヘッドレス設定の無い試験ユーザー | `Service=gdm-password` の新しい Wayland セッションができ、電卓の `7×8=56` を確認した |
| 切断と再接続 | 同じ session と Leader に戻り、電卓の 56 が残った |
| LAN 限定 | `rdp` サービスを閉じ、指定 LAN の 3389/tcp の rich rule に置き換えた。LAN の別 VM から引き続きつながった |
| VM を再起動した後の初回接続 | GDM → 既に自動起動しているユーザーのヘッドレスセッションへ入った。電卓の `9×9=81` を確認した |
| 起動順 | GDM の active 時刻は起動後 33.488638 秒、システム RDP の開始は 33.510534 秒。`After=gdm.service` が効き、`GetManagedObjects` の警告は無かった |
| ロールバック 1・2 | システム RDP が disabled / inactive、3389 番の待ち受けと rich rule が消え、資格情報とドロップインを解除した |

受け渡し時には、従来の記録と同じ `g_atomic_ref_count_dec` の CRITICAL が 1 回出たが、画面と入力に支障は見えなかった。TPM の無い VM なので資格情報は GKeyFile へフォールバックした。再起動後の AVC は無かった。1 vCPU では GNOME の描画開始まで待ち時間があり、unit が active になった直後の画面だけで成否を決めていない。

今回の RDP は、GUI 検証用の `--virtual-monitor` をロールバックした標準のヘッドレス構成で測った。Windows / Android の今回の接続、VM の外の実機、指定 LAN の外からの拒否、旧証明書への差し戻し（ロールバック 3・4）は今回確認していない。

実行ログは `.verification/desktop/` の `rdp-system-plan-session`、`rdp-restart-plan-session`、`rdp-status-fixed-plan-session`、`rdp-lan-plan-session`、`rdp-rollback-plan-session`、`rdp-after-reboot.log`。画面は `rdp-gdm-initial.png`、`rdp-new-calc-result.png`、`rdp-new-reconnected.png`、`rdp-gdm-after-reboot.png`、`rdp-handover-result-after-reboot.png` に保存した。

---

### 付録: 現行版の新規 VM での再検証（2026-10-06）

**環境と流し方**: `5da3478` の現行手順を、別のクリーンな AlmaLinux 10.2 Workstation / x86_64 の VM（1 vCPU、SELinux Enforcing、firewalld 稼働、US 配列）で実行した。SSH の一般ユーザーの対話 PTY に折り畳みの外のブロックを手順ごとに貼り、応答とプロンプトを待った。GUI は GNOME 49.4 のヘッドレスセッションに仮想モニターを付け、操作後の PNG を目視した。既存の実機・資格情報は使っていない。

実施手順 1〜10 と 11 の RDP 接続を本実行した。証明書の SAN はホスト名と VM の IP、crt / key は 644 / 600、対応する公開鍵が一致し、SELinux のラベルも確認した。GDM の後に起動する drop-in を読み戻し、system の RDP が 3389 で TLS 1.3 を受け付けた。指定 LAN の rich rule も実行した。

別の新規 VM の FreeRDP `3.10.3` で、証明書の指紋を照合して接続した。RDP 専用資格情報で GDM に到達し、検証用 OS ユーザーでログインして handover が完了した。既存の headless セッションへ引き渡され、RDP のキーで Firefox の窓を移して画面と入力を確認した。VM 再起動後も system サービスと 3389 の待受、LAN rule は維持された。再起動後の実再接続は headless の 3390 で行い、3389 の GDM ログインは再起動前の 1 回である。

ロールバック 1・2 を実行し、RDP 有効化・資格情報・firewall の許可・GDM 依存の drop-in を解除した。system サービスは `disabled` になった。system 側の証明書はこのロールバックの削除対象ではないので保持した。LAN 外からの拒否、Windows / Android、別ユーザーの同時接続、物理 PC は今回実施していない。

### 手順中の実測・検証状況の記録

- ローカルでログイン中のユーザーと同一ユーザーで接続すると、GDM が既存セッションの扱い（切替 or 拒否）を求める場合がある（確かめていない）

### 実施手順 / 手順 3: 補足: SELinux コンテキスト

`restorecon` は両環境とも差分なし。コンテキストは元から `gnome_remote_desktop_var_lib_t` で正しい状態だった。

```
-rw-r--r--. 1 gnome-remote-desktop gnome-remote-desktop unconfined_u:object_r:gnome_remote_desktop_var_lib_t:s0 1249 Sep 16 16:02 rdp-tls.crt
-rw-------. 1 gnome-remote-desktop gnome-remote-desktop unconfined_u:object_r:gnome_remote_desktop_var_lib_t:s0 1704 Sep 16 16:02 rdp-tls.key
```

### 実施手順 / 手順 4: 補足: grdctl

**`grdctl --system rdp enable` / `disable` はサービスの起動・停止も行う**（環境 2 で確認）。

### 実施手順 / 手順 10: 補足: TLS プローブと、FreeRDP クライアントでの確かめ方

環境 2 での結果（`127.0.0.1` と `${SERVER_IP}` の両方で同じ）:

```
$ python3 ~/rdp_tls_probe.py "${SERVER_IP}"
negotiation: type=0x02 (RESPONSE) selectedProtocol=0x2
tls: TLSv1.3 TLS_AES_256_GCM_SHA384
fingerprint: <FINGERPRINT>
subject=CN=<HOSTNAME>
X509v3 Subject Alternative Name:
    DNS:<HOSTNAME>, DNS:<HOSTNAME>, DNS:<SERVER_IP>, IP Address:<SERVER_IP>
```

- サーバーに FreeRDP クライアントが無い環境（環境 2）でも使え、RDP のパスワードは不要

### 付録: winpr-makecert で証明書を作る場合（RHEL 10 公式手順）

- `winpr-makecert` が生成した秘密鍵は **0644** だったため 0600 に絞った（親ディレクトリ `/var/lib/gnome-remote-desktop` が 0700 のため実害はないが念のため）
- このとき生成された証明書の TLS fingerprint: `<FINGERPRINT>`
- メイン手順と同じ `rdp-tls` という名前で出力するので、openssl 製の証明書が既にある場合は上書きされる。残したい場合は出力名を変える（例: `rdp-tls-winpr`）

### 手順中の検証状況

- GDM 47 と gnome-settings-daemon の既定値による（コンテナでログイン画面の設定値を読んだもので、本書の環境では確かめていない）

### 手順内の実測・検証状況

- **設定レイヤーの食い違い（環境 2 で発生）**

### 手順内の実測・検証状況

- `grdctl --system rdp disable` → `enable` と続けて実行した後、`/etc` 側は `enabled=true` なのにこのファイルに `enabled=false` が書かれ、**サービスを再起動しても `Status: disabled` のまま 3389 が LISTEN しなかった**

### 手順内の実測・検証状況

- デーモン稼働中にもう一度 `sudo grdctl --system rdp enable` を実行したところ、このファイルが削除されて `Status: enabled` に戻った

### 実施手順 / 手順 6: 補足: 資格情報

環境 2 では資格情報を `systemctl enable --now` の**前**に設定したが、手順 4 の `rdp enable` で既にデーモンが起動していたため、やはり再起動するまで反映されなかった。落とし穴の詳細は[付録の調査記録](../verification/gnome-remote-desktop.md#落とし穴-1-grdctl-の対話入力は-tty-必須)。

### 実施手順 / 手順 9: 補足: 鍵と証明書

- 環境 2 で一致を確認

- `openssl pkey` には `-modulus` が無い（OpenSSL 3.5 で確認）。鍵側は `openssl rsa` を使う

### 設定済みのサーバーで GDM の後に起動させる / 手順 2: 補足: すれ違ったときのログ

環境 2 では、起動のとき（GDM が立ち上がったのと同じ秒）に、次の 1 行が出ていた:

```
gnome-remote-desktop-daemon[<PID>]: (gnome-remote-desktop-daemon:<PID>): GLib-GIO-WARNING **: 00:09:18.973: Error calling GetManagedObjects() when name owner :1.26 for name org.gnome.DisplayManager came back: GDBus.Error:org.freedesktop.DBus.Error.UnknownMethod: Object does not exist at path “/org/gnome/DisplayManager/Displays”
```

### 参考資料の証明書生成で確認した表示

- **`--hostname "${SERVER_NAME}"` は必須。** 渡さないとコンテナのランダム ID が CN になる:
  ```
  subject=CN=f4fd0ab7095a        ← --hostname なしの場合
  subject=CN=<HOSTNAME>       ← --hostname あり
  ```

- **`-n "CN=..."` は使ってはいけない。** winpr-makecert の `-n` は解析が壊れており、subject が破損する:
  ```
  subject=L=<HOSTNAME の一部>, O=<HOSTNAME の一部>, CN=CN=<HOSTNAME>
  ```
  `--hostname` だけで正しい CN になるので `-n` は不要。
