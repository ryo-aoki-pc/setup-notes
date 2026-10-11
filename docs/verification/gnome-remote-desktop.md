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
      - これは 2026-09-28 の時点の状態。囲んだ形の手順 3〜5・8・9 は、その後、VM で貼って通している（2026-10-06 の 2 つの付録と、2026-10-11 の付録）。手順 2 は、2026-10-05 に `if` で囲む形に変わった。ロールバックの手順 1 は、2026-10-06 の 2 つの付録の VM で流している（2026-10-11 の通しでは流していない）。注意点の確認方法のブロックは、2026-10-11 の通しでは流していない
  - 2026-10-02: 手順 5 に GDM の後に起動させるドロップインを足し、[設定済みのサーバーで GDM の後に起動させる](../gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる)を足した
    - 環境 2 で、Windows 11 からのリモートログインが真っ暗な画面のまま切れたため（[付録](#付録-真っ暗な画面のまま切れた原因の調査記録環境-22026-10-02)）
    - その節の手順 1〜5 は、環境 2 の実機で流した（手順 5 の後は、手順 1 で置き直した）
    - 直した後、利用者が Windows 11 の「リモートデスクトップ接続」でつなぎ、GDM のログイン画面が出て、ログインできた（ヘッドレスのセッションに引き渡された。[注意点](../extra/gnome-remote-desktop.md#注意点)）
    - その節の手順 3 は、はじめ `restart` で流した。その後の最初の接続だけが、また真っ暗なまま切れたので、止めて待ってから起動する今の形に直し、流し直した（付録）。今の形で起動し直した後は、1 回目の接続から通った（FreeRDP で。Windows からは確かめていない）
    - 同じ日に、ヘッドレスのセッションとの組み合わせ・切断とつなぎ直し・同時の接続・GDM の再起動を、試験用のユーザーとコンテナの FreeRDP 3.10.3 で確かめた（[付録の追加の確認](#追加の確認)）。システム共通の RDP の資格情報は、ファイルを控えてテスト用の値に差し替え、終わってから戻した
    - 手順 5 の今のブロックと、[ロールバック](../extra/gnome-remote-desktop.md#ロールバック)の手順 1 は、構文の検査だけで、流していない
      - これは 2026-10-02 の時点の状態。手順 5 の今のブロックは、その後、VM で貼って通している（2026-10-06 の 2 つの付録と、2026-10-11 の付録）。ロールバックの手順 1 も、2026-10-06 の 2 つの付録の VM で流している（2026-10-11 の通しでは流していない）
    - 起動のときにドロップインが効くこと（再起動して確かめること）は、まだしていない
      - これは 2026-10-02 の時点の状態。VM では、再起動の後に GDM の後で起動することを確かめた（2026-10-06 の VirtualBox の VM と、2026-10-11 の Hyper-V の VM）。環境 2 の実機を再起動して確かめた記録は、この検証記録には無い
  - 2026-10-05: 証明書生成の空変数検査、起動し直しの共通手順への参照、LAN 限定の rich rule の撤去を追加した。変更後は構文検査とスタブでの確認だけで、実機では流していない
    - これは 2026-10-05 の時点の状態。その後、VM では流している: 手順 2 の今のブロック（`中断:` でない側）と、手順 7 から節の手順 3 へ進む形は、2026-10-06 の 2 つの付録と、2026-10-11 の付録。LAN 限定の rich rule と、その撤去（ロールバックの手順 2）は、2026-10-06 の 2 つの付録（2026-10-11 の通しでは流していない）。`中断:` の側と実機は、2026-10-11 の通しでは流していない
  - **2026-10-11 に、Hyper-V の VM（x86_64。Kickstart で入れた Workstation に、初期設定・画面オフの任意節の手順 1〜5・linger・Podman を通したもののクローン）で、実施手順 1〜11 を上から通した**（[付録](#付録-hyper-v-の-vm-で通した記録2026-10-11)）
    - 通し方: ブロックは、SSH の対話の bash に 1 つずつ貼った（書き換えたのは手順 1 の `SERVER_IP` だけ）。VM のコンソールは、GDM のログイン画面のまま（ログインしていない）。手順 7 は、節「設定済みのサーバーで GDM の後に起動させる」の手順 3 を貼った
    - クライアント: 手順 11 は、同じ仮想スイッチの別の VM（AlmaLinux 10.2）の FreeRDP 3.10.3 から行った。**Windows のクライアントからは、確かめていない**
    - 結果: 11 手順のうち、通した 10、通らなかった 1、条件に当たらず飛ばした 0、未実施 0。手順 7 が案内する節の手順 4 は、ヘッドレスのセッションが無いので飛ばした
    - 通らなかったもの: 手順 11 の、書かれていたコマンド名 `xfreerdp3`。AlmaLinux 10 の `freerdp` パッケージに無く、`コマンドが見つかりませんでした` で終わった。同じ引数で `xfreerdp` に読み替えると、最後まで通った
    - 確認したこと: 手順 1〜10 の出力が、箇条書き（手順 8 はコードのコメント）と食い違わない（手順 3 には、通したときは出力を照らす箇条書きが無かった。手順 2・5・6 は、確認の見出しの無い手順）。FreeRDP の `Thumbprint:` が `TLS fingerprint` と同じ。RDP の認証の後に GDM のログイン画面が出て、OS アカウントでログインすると、新しいセッション（`Service=gdm-password`・`Remote=yes`）のデスクトップが出る。クライアントから送ったキーで電卓が起動する。SELinux は Enforcing のまま、VM の監査ログに拒否の行は無い（同じ日に、監査ログのファイルを直接数え直した結果。付録）
    - 範囲の外で確かめたこと: 切ってつなぎ直すと、同じセッションに戻る。VM を再起動した後、`gdm.service` の 0.19 秒後にデーモンが起動し、節の手順 2 は `0` で、リモートログインが通る
    - 直した所: 手順書の指摘 7 つのうち 4 つ（手順 11 のコマンド名を `xfreerdp` に。手順 11 に、FreeRDP の入力待ちと警告の箇条書き。手順 3 に、確認の箇条書き。手順 4 に、TPM の行の箇条書きと「手順 10・11 で使う」）。どれも箇条書きの文言で、コードブロックは変えていない。未対応は 3 つ（ログイン画面のキー操作、手順 9・10 の `openssl` と `python3` が Homebrew のものになること、手順 5 の `systemctl enable --now` が何も出さないこと）
    - 未実施の範囲と、確認していないこと: Windows・Android のクライアント、クライアントからのマウス・クリップボード・音、任意節「接続元を LAN に絞る」、節の手順 1・5、ロールバック、ヘッドレスのセッションやデスクトップ共有との併用、PC の画面でログイン中のユーザーでのリモートログイン、手順 2 の `中断:` の側、TPM のある PC、実機

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

---

### 付録: Hyper-V の VM で通した記録（2026-10-11）

- **何を**: [手順書](../gnome-remote-desktop.md)の実施手順 1〜11（コミット `114c2b2`）を、上から最後まで通した
  - 手順 7 は、コードブロックの無い手順。箇条書きのとおり、節「[設定済みのサーバーで GDM の後に起動させる](../gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる)」の手順 3 を貼った。ヘッドレスのセッションが無いので、同節の手順 4 は、条件に当たらず飛ばした
  - 任意節「接続元を LAN に絞る」、同節の手順 1・5、ロールバックは、この通しでは流していない
  - 手順書の外で、切ってつなぎ直すことと、VM を再起動した後のリモートログイン（同節の手順 2 を含む）も確かめた。11 手順の数には入れていない
- **結果**: 11 手順のうち、通した 10、通らなかった 1、条件に当たらず飛ばした 0、未実施 0
  - 手順 1〜10 の出力は、手順書の箇条書き（手順 8 は、コードのコメント）と食い違わなかった
    - 手順 3 には、通したとき（`114c2b2`）は、出力を照らす箇条書きが無かった（[指摘 4](#指摘と状態2026-10-11)）。手順 2・5・6 は、確認の見出しの無い手順で、別の SSH の読みと、後ろの手順の出力で確かめた（下の表）
  - 通らなかったのは、手順 11。書かれていたコマンド名 `xfreerdp3` は、クライアント（AlmaLinux 10.2）に無く、`コマンドが見つかりませんでした` で終わった（終了コード 127）。同じ引数で `xfreerdp` に読み替えると、RDP の認証 → GDM のログイン画面 → OS アカウントでのログイン → デスクトップ、まで通った
  - 担当の報告は、この手順 11 を「通した（コマンド名を読み替えた）」に入れて、「通した 11、通らなかった 0」と数えている（[報告と証跡が食い違っていた所](#報告と証跡が食い違っていた所2026-10-11)）
- **どの状態から**: Hyper-V の列の VM のスナップショット `after-CL1` のクローン
  - Kickstart で入れた AlmaLinux 10.2 の Workstation に、[初期設定](../almalinux-setup.md)の実施手順（[記録](almalinux-setup.md#付録-hyper-vvmwarevirtualbox-の-vm-で今の順番で通した記録2026-10-11)）、同書の任意節「画面オフ・画面ロック・自動サスペンドを止める」の手順 1〜5、[linger.md](../linger.md)、[podman.md](../podman.md) を通した後の状態
  - ヘッドレスのセッション（[gnome-headless-session.md](../gnome-headless-session.md)）とデスクトップ共有（[gnome-desktop-sharing.md](../gnome-desktop-sharing.md)）は、この VM には入っていない
- **どう通したか**: 手順書から抜き出したブロックを、SSH の対話の bash に 1 つずつ貼った（手順書の「すべてサーバー上で実行する」と、手順 6 の「本物の端末で」に当たる）
  - VM のコンソールでは、GNOME にログインしていない（終わりまで GDM のログイン画面のまま。キーも送っていない）
  - 手順 11 は、同じ仮想スイッチにつないだ別の VM（以下「クライアント」。AlmaLinux 10.2 の FreeRDP 3.10.3）から行った。Windows のクライアントからは、確かめていない
  - 実アカウントでのログインは無い。新しく決めたパスワードは、手順 6 の RDP のパスワードの 1 つ（OS のパスワードとは別の値）
- **誰が**: 通したのは、検証の担当のエージェント。この付録は、その報告と証跡のファイルを、VM に触れない別の担当が照らし合わせて書いた
- **証跡**: 追跡していない `.verification/campaign/hv/R4/`（このリポジトリには入っていない）。下のファイルの名前は、ここからの相対パス
  - `seq` は、主の VM が `session/steps.jsonl`、クライアントが `peer/session/steps.jsonl` の番号。`after-confirm/` は `session/after-confirm/`、PNG は `screens/`
- 出力の中の VM の値は、`<USER>`・`<UID>`・`<HOSTNAME>`・`<SERVER_IP>`・`<PID>`・`<FINGERPRINT>`・`<システムRDPユーザー名>` で書いた。パスワードと鍵は載せていない

#### 環境（2026-10-11）

| 項目 | 内容 |
|---|---|
| ホスト | Windows 11 Pro 10.0.26300 |
| ハイパーバイザ | Hyper-V（担当の報告では `vmms.exe` 10.0.26100.8875）。層の `Get-VmvBackend` は `Generation=2`・`Version=12.0`・`HypervisorPresent=True`（`meta.json`） |
| VM | 第 2 世代（UEFI）、Secure Boot オフ、vTPM 無し、2 vCPU、3072 MB（ゲストから見えるのは 2900 MB）、ディスク 64 GB、NIC 1 枚（Default Switch） |
| クライアント | 同じ世代の VM で、2 vCPU、2048 MB（ゲストから見えるのは 1639 MB）。Kickstart で入れたベースのスナップショット `clean-install` のクローンで、初期設定は通していない（sudo はパスワードを聞く）。[gnome-headless-session.md の通し](gnome-headless-session.md#付録-hyper-v-の-vm-で通した記録2026-10-11)で作って FreeRDP を入れたものを、そのまま起動した |
| ゲスト | 2 台とも AlmaLinux 10.2 (Lavender Lion)、kernel `6.12.0-211.64.1.el10_2.x86_64`、x86_64。VM は SELinux Enforcing、firewalld 有効（`public`、`eth0`） |
| VM に入っていた版 | `gnome-remote-desktop-49.3-4.el10_2`、`gnome-shell-49.4-9.el10_2.alma.1`、`mutter-49.4-4.el10_2`、`gdm-47.0-24.el10_2`、`freerdp-libs-3.10.3-12.el10_2.14`、`openssl-3.5.8-2.el10_2.alma.1`、`firewalld-2.4.3-4.el10_2`、`systemd-257-23.el10_2.2.alma.1`、`python3-3.12.15-1.el10_2` |
| VM の PATH | 先頭が Homebrew（初期設定を通した後なので）。対話のシェルの `openssl` は `/home/linuxbrew/.linuxbrew/bin/openssl`（`OpenSSL 4.0.3 29 Sep 2026`）が先で、OS のものは `/usr/bin/openssl`。`python3` も Homebrew のもの（`Python 3.15.0`）が先（主の seq 16）。`sudo` から見える `openssl` は `/bin/openssl`（`OpenSSL 3.5.8 25 Aug 2026`。`facts-after-step3.txt`） |
| クライアントの版 | `freerdp-3.10.3-12.el10_2.14`（`xfreerdp --version` は `This is FreeRDP version 3.10.3 (n/a)`。`/usr/bin/xfreerdp` と `/usr/bin/wlfreerdp` があり、`xfreerdp3`・`sdl-freerdp`・`sdl-freerdp3`・`wlfreerdp3` は無い。`type` の読み。`xfreerdp` が `freerdp` パッケージのものであることは `dnf repoquery` で読んだが、`wlfreerdp` は `rpm -qf` で確かめていない。`peer/guest-facts-start.txt`）。`xorg-x11-server-Xwayland-24.1.9-4.el10_2.3` |
| 手順書 | `docs/gnome-remote-desktop.md`、コミット `114c2b2`（`114c2b2bfd14b51f9e1925b150cbf72e1954f311`。`steps.jsonl` の `docCommit`） |
| 実施の日時 | 2026-10-11 11:29〜11:43 UTC（ゲストの時計で 20:29〜20:43 JST）。手順 1〜10 は 11:31:02〜11:33:08 UTC。手順 11 は、クライアントのコンソールのログイン（11:33:29）から最初の切断（11:37:53）まで。範囲の外のつなぎ直しは 11:38:05〜11:40:41、再起動と、その後のリモートログインは 11:40:53〜11:43:04 |
| 貼り方 | ドライバ（`rb.mjs paste`）で、SSH の対話の bash にブラケットペーストで 1 ブロックずつ。貼った中身は手順書のまま（`steps.jsonl` の `sha256` と `pastedSha256` が同じ）。手順 1 の 1 つ目のブロックだけ、`SERVER_IP` に VM の IP を入れた |
| sudo | VM は NOPASSWD（初期設定の「ログインと sudo」）で、1 度もパスワードを聞かなかった。クライアントでは、sudo を使っていない |
| 検証用の値 | `SERVER_IP`（VM の Default Switch の IP）と、RDP のユーザー名・パスワード（この検証のために決めた値。記録に載せていない） |
| 始めの状態 | `gnome-remote-desktop.service` は `disabled`・`inactive`、`gnome-headless-session@<USER>.service` は `disabled`（担当の報告。`guest-facts-start.txt` の読みには、ユニットの名前が出ていない）。`/var/lib/gnome-remote-desktop` と `/etc/gnome-remote-desktop` は空で、ドロップインのディレクトリは無い。firewalld のサービスは `cockpit dhcpv6-client ssh`、3389・3390 の待ち受けは無い。`Linger=yes`。このユーザーのセッションは `manager`（linger）と SSH だけで、ヘッドレスのセッションは無い。コンソールは GDM のログイン画面（`c1`、`seat0`、`greeter`）。`/dev/tpm*` は無い（`guest-facts-start.txt`） |

#### 手順ごとの結果（2026-10-11）

| 手順 | 判定 | 出力と、確かめたこと | 根拠 |
|---|---|---|---|
| 1 | 通した | `SERVER_IP = <SERVER_IP>`・`SERVER_NAME = <HOSTNAME>`・`SERVER_FQDN = <HOSTNAME>.mshome.net` | 主の seq 1・2、`after-confirm/0002-実施手順-1.txt` |
| 2 | 通した | `中断:` は出ず、`openssl req` が鍵を作る進み（`.`・`+`・`*` の行と `-----`）だけを出した（確認の見出しの無い手順）。別の SSH で読んだ証明書は `CN=<HOSTNAME>`、SAN は `DNS:<HOSTNAME>, DNS:<HOSTNAME>.mshome.net, DNS:<SERVER_IP>, IP Address:<SERVER_IP>`、`TLS Web Server Authentication`、有効期間は 2026-10-11 から 2036-10-08 | 主の seq 3、`session/session-001.raw`、`facts-after-step3.txt` |
| 3 | 通した | `restorecon -Rv` は何も出さなかった。「確認」の後は、`合計 8`、`rdp-tls.crt`（`-rw-r--r--.`、1261 バイト）、`rdp-tls.key`（`-rw-------.`、1704 バイト）。どちらも所有者とグループが `gnome-remote-desktop`、コンテキストは `unconfined_u:object_r:gnome_remote_desktop_var_lib_t:s0` | 主の seq 4、`after-confirm/0004-実施手順-3.txt` |
| 4 | 通した | `Init TPM credentials failed because No TPM device found, using GKeyFile as fallback.` が 3 行（コマンドごとに 1 行）だけ。箇条書きの `sudo grdctl --system status` を続けて打つと、`Unit status: active`・`Status: enabled`・`Port: 3389`・`TLS fingerprint: <FINGERPRINT>`・`Username: (empty)`・`Password: (empty)`。デーモンは、この手順で起動していた（journal の `Starting gnome-remote-desktop.service` が、貼った秒の 20:31:30） | 主の seq 5・6、`session/session-001.raw`、`facts-after-step5.txt` |
| 5 | 通した | 出力は `success` が 2 行だけ（`firewall-cmd` の 2 つ）。`systemctl enable --now` は何も出さなかった（`Created symlink` の行が出ない）。確認の見出しの無い手順。別の SSH で、ドロップインの中身（`[Unit]`・`After=gdm.service`）、`systemctl show … -p After` の `gdm.service`、`enabled`・`active`、firewalld の runtime と permanent の両方の `rdp`、`LISTEN 0 5 *:3389 *:*` を読んだ | 主の seq 7、`session/session-001.raw`、`facts-after-step5.txt` |
| 6 | 通した | `Init TPM credentials failed …` の 1 行の後に `Username:`、答えると `Password:`（打った文字は出ない）、答えるとプロンプトに戻った（入力待ちを含めて 30 秒）。確認の見出しの無い手順。入ったことは、手順 8 の `Username: (hidden)`・`Password: (hidden)` と、手順 11 の認証で確かめた | 主の seq 8〜10、`session/session-001.raw` |
| 7 | 通した | コードブロックの無い手順。節の手順 3 を貼った（下の表） | 主の seq 11（メモ）・12 |
| 8 | 通した | `Init TPM credentials failed …` の 1 行の後に、`Unit status: active`・`Status: enabled`・`Port: 3389`・`TLS fingerprint: <FINGERPRINT>`・`Username: (hidden)`・`Password: (hidden)`。`systemctl status` は `Loaded: … enabled`、`Drop-In:` に `10-after-gdm.conf`、`Active: active (running)` で、ページャで止まらずに戻った。`ss` は `LISTEN 0 5 *:3389 *:*` の 1 行。サービスは `cockpit dhcpv6-client rdp ssh` | 主の seq 13、`after-confirm/0013-実施手順-8.txt` |
| 9 | 通した | `SHA2-256(stdin)=` の 2 行が、同じ値 | 主の seq 14、`after-confirm/0014-実施手順-9.txt` |
| 10 | 通した | `negotiation: type=0x02 (RESPONSE) selectedProtocol=0x2`、`tls: TLSv1.3 TLS_AES_256_GCM_SHA384`、`fingerprint:` の値は手順 4・8 の `TLS fingerprint` と同じ、`subject=CN=<HOSTNAME>`、SAN は手順 2 と同じ（`DNS:<SERVER_IP>` を含む）。サーバーの journal には、貼った秒（20:33:06）に、`nla_recv() error: -1`・`client authentication failure`・`[RDP] Network or intentional disconnect, stopping session` を含む 9 行（箇条書きの「出るが正常」のとおり）。`~/rdp_tls_probe.py` は消していない | 主の seq 15、`after-confirm/0015-実施手順-10.txt`、`grd-journal-after-probe.txt` |
| 11 | 通らなかった（`xfreerdp` に読み替えて通した） | 下の「手順 11（クライアントからのログイン）」 | クライアントの seq 2〜8、`screens/peer-02-rdp-gdm-greeter.png`・`peer-03-rdp-after-os-login.png`・`peer-04-rdp-typed-calc.png`・`peer-05-rdp-calculator-56.png`、`screens/rdp-login/login-20261011-113603-*.png`、`facts-step11-greeter.txt`・`facts-step11-loggedin.txt`・`client-input-check.txt`、`grd-journal-step11.txt`・`gdm-journal-step11.txt`・`user-handover-journal-step11.txt` |

節「設定済みのサーバーで GDM の後に起動させる」:

| 節の手順 | 判定 | 出力と、確かめたこと | 根拠 |
|---|---|---|---|
| 3（手順 7 から） | 通した | 「確認」の後は、`10月 11 20:32:44 <HOSTNAME> gnome-remote-de[<PID>]: RDP server started` の 1 行だけ（12.0 秒。中に `sleep 5` が 2 つ） | 主の seq 12、`after-confirm/0012-設定済みのサーバーで_GDM_の後に起動させる-3.txt` |
| 4 | 条件に当たらず飛ばした | ヘッドレスのセッションが無い（`loginctl` に `headless` の行が無い） | 主の seq 11（メモ）、`guest-facts-start.txt` |
| 2（範囲の外。再起動の後に貼った） | 通した | `0`（すれ違っていない） | 主の seq 20、`session/session-002.raw` |
| 1・5 | 流していない | 手順 7 の箇条書きのとおり（「その節の手順 1・2・5 は行わない」） | — |

- 条件に当たらなかった分岐: 手順 2 の `中断:` の側、手順 7 を行わなかったときの `Credentials are not set, denying client`、TPM のある PC の `grdctl` の出力、既にある証明書の差し替え
- sudo のある手順は、どれもパスワードを聞かれずに進んだ
- 貼り付けごとの時間（`steps.jsonl` の `durationMs`。出力が止まってからドライバが待つ時間を含む）: 手順 5 が 2.8 秒、節の手順 3 が 12.0 秒、手順 6 は入力待ちと判定されるまで 3.3 秒（2 つの入力を含めると 30 秒）、ほかは 1.8〜2.0 秒

**手順 11（クライアントからのログイン）**:

- クライアントの用意（手順書の外）: コンソールで GNOME にログインし、アクティビティ画面を Esc で閉じて、SSH のシェルに `DISPLAY=:0` と `XAUTHORITY`（`/run/user/<UID>/.mutter-Xwaylandauth.*`）を入れた。FreeRDP は、前の通しで入れてあった
  - クライアントのコマンドは、その SSH のシェルから起動した。窓はクライアントのコンソールの画面に出て、入力待ち（証明書・`Domain:`・`Password:`）は SSH の端末に出た
- **書かれたままの形**（クライアントの seq 2・3）: `xfreerdp3 /v:<SERVER_IP>:3389 /u:<システムRDPユーザー名>` は、`bash: xfreerdp3: コマンドが見つかりませんでした...` と `よく似たコマンドは: 'xfreerdp'` で終わった（続けて打った `echo "exit=$?"` は `exit=127`）
  - `dnf -q provides "*/xfreerdp3"` は `エラー: 一致する項目はありませんでした。…`。`dnf -q repoquery --whatprovides "*/bin/xfreerdp*"` が返したのは、`freerdp` パッケージの 8 つの版だけ
- **`xfreerdp` に読み替えた形**（seq 4〜7。引数は同じ）
  - 出た順: `[verify_cb]: Certificate verification failure 'self-signed certificate (18)' at stack position 0` → `[verify_cb]: CN = <HOSTNAME>` → `[x509_utils_from_pem]: BIO_new failed for certificate` → `[tls_print_new_certificate_warn]` の 12 行 → `Certificate details for <SERVER_IP>:3389 (RDP-Server):`（`Common Name`・`Subject`・`Issuer`・`Valid from`・`Valid to`・`Thumbprint`）→ `Do you trust the above certificate? (Y/T/N)`
  - 12 行の警告は、`The host key for <SERVER_IP>:3389 has changed`、`WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!`、`IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!`、`Add correct host key in /home/<USER>/.config/freerdp/server/<SERVER_IP>_3389.pem to get rid of this message.`、`Host key verification failed.` など。このクライアントが、この VM につなぐのは初めてだった（`~/.config/freerdp/server/` にあったのは、別の VM の証明書の 1 つだけ。クライアントの seq 1）
  - `Thumbprint:` は、手順 4・8 の `TLS fingerprint` と同じ値だった。`Y` と答えると、`Domain:`（空のまま Enter）、`Password:`（手順 6 のもの）の順に聞かれた
  - パスワードの後に、`[ERROR][com.winpr.sspi.Kerberos] - [kerberos_AcquireCredentialsHandleA]: krb5_parse_name (Configuration file does not specify default realm [-1765328160])` が 2 行出た。続けて `[WARN]` の 3 行（`expected messageChannelId=1008, got 1003` が 2 行と、`license binary blob::type BB_ERROR_BLOB, length=0, skipping.`）と `[INFO]` の行が出て、3 秒後（20:35:16）に `rdp_recv_server_redirection_pdu` が出た。サーバーのデーモンは、同じ秒に `[RDP] Sending server redirection` を出した
- **GDM のログイン画面**: クライアントの画面に `FreeRDP: <SERVER_IP>` という題の窓が出て、利用者の一覧（`<USER>`）と「アカウントが見つかりませんか?」が写った（`screens/peer-02-rdp-gdm-greeter.png`）
  - VM には、コンソールのログイン画面（`c1`、`seat0`）とは別に、seat の無い `greeter` のセッション（`c2`。`Remote=yes`・`Type=wayland`・`Service=gdm-launch-environment`）と、`gdm` のユーザーの `gnome-remote-desktop-daemon --handover` ができた（`facts-step11-greeter.txt`）
- **OS アカウントでのログイン**: 利用者が選ばれるとパスワードの欄になり（`screens/rdp-login/login-20261011-113603-2-password-field.png`）、OS のパスワードの後、20:36:15 に、そのユーザーの新しいセッション（番号 43。`Service=gdm-password`・`Type=wayland`・`Remote=yes`・`Class=user`）ができた
  - 20:36:19 に、そのユーザーの `gnome-remote-desktop-handover.service` が起動し、20:36:22 に `RDP server started` を出した。同じ秒に、クライアントに `rdp_recv_server_redirection_pdu` がもう 1 度出て、接続元のポートが変わり（39666 → 33188）、窓がデスクトップ（アクティビティ画面。上部バーに、共有中の橙色の印）に切り替わった（`peer-03-rdp-after-os-login.png`、`facts-step11-loggedin.txt`）
  - ログイン画面のセッション `c2` は消えた。`loginctl list-sessions` では、新しいセッションの `TTY` の列が `headless` と出る（ヘッドレスのセッションではない。[gnome-headless-session.md の検証記録](gnome-headless-session.md)の 2026-10-08 の付録と同じ見え方）
- **入力**: クライアントのコンソールに送った `calc` → Enter → `7*8` → Enter が届き、VM のセッションで電卓が起動して、`7×8 = 56` が出た（`peer-04-rdp-typed-calc.png`・`peer-05-rdp-calculator-56.png`。VM に、20:37:02 に起動した `/usr/bin/gnome-calculator` のプロセスがある。`client-input-check.txt`）
- **サーバーのログ**（`gdm-journal-step11.txt`・`grd-journal-step11.txt`・`user-handover-journal-step11.txt`）
  - GDM: `gdm-password]: gkr-pam: unable to locate daemon control file` と `gkr-pam: stashed password to try later in open session`
  - システムのデーモン: つないだ秒に `krb5_init_context (Included profile directory could not be read [-1429577696])` が 2 行。1 回目のつなぎ直しの秒に、`[RDP] Sending server redirection` の後、`BIO_read retries exceeded`・`ERRCONNECT_CONNECT_TRANSPORT_FAILED`・`[RDP] Network or intentional disconnect, stopping session`。2 回目のつなぎ直しの秒に、`g_atomic_ref_count_dec: assertion 'old_value > 0' failed` が 1 回
  - 受け渡し役のデーモン: 起動のときに `libEGL warning: failed to get driver name for fd -1`・`MESA-LOADER: failed to retrieve device information`・`MESA: error: ZINK: failed to choose pdev`・`libEGL warning: egl: failed to create dri2 screen` を出してから `RDP server started`。続けて `[RDP.RDPGFX] CapsAdvertise: Accepting capability set with version RDPGFX_CAPVERSION_107, Client cap flags: H264 (AVC444): false, H264 (AVC420): false`
- 切断は、クライアントの SSH の端末の Ctrl+C（`xfreerdp` は `Caught signal '割り込み' [2]`・`ERRCONNECT_CONNECT_CANCELLED` を出して終わった。2 回目の切断の後に読んだ終了コードは 145）

**範囲の外で確かめたこと**（手順書の外。11 手順の数に入れていない）:

| 確かめたこと | 結果 | 根拠 |
|---|---|---|
| 切った後 | セッション（43）は `State=active` のまま残り、電卓のプロセスも残った。Mutter の `GetCurrentState` のモニターは空になり、3389 の接続は 0 になった | `facts-step11-disconnected.txt` |
| つなぎ直し | 証明書の確認は出ず、`Domain:` から始まった（1 回目の `Y` で、証明書が `~/.config/freerdp/server/<SERVER_IP>_3389.pem` に保存されていた。1261 バイト）。RDP の認証の後は、また GDM のログイン画面。OS のパスワードの後、同じセッション（43。`Leader` も `Timestamp` も同じ）に戻り、`7×8 = 56` の電卓が、そのまま写った | クライアントの seq 9〜13、`screens/peer-06-reconnect-gdm-greeter.png`・`peer-07-reconnect-same-session.png`、`facts-step11-reconnected.txt` |
| ログイン画面のキー操作 | つなぎ直しのとき、ログイン画面の利用者は、Enter を送っただけでは選ばれなかった（`screens/rdp-login/login-20261011-113916-2-password-field.png` は、利用者の一覧のまま）。Tab を 1 回送ると利用者の項目に枠が付き（`peer-07a-reconnect-after-tab.png`）、その後の Enter でパスワードの欄になった。キーは、クライアントのコンソールに送ったもの（送ったキーの順は、担当の報告による）。マウスでのクリックは、していない | `screens/rdp-login/login-20261011-113916-*.png`・`login-20261011-114006-*.png`、`peer-07a-reconnect-after-tab.png` |
| VM の再起動 | `sudo systemctl reboot` を送ってから 14.5 秒で、ドライバの SSH がつながり直した（seq 18 の 11:40:53.6 UTC から、seq 19 の終わりの 11:41:08.1 UTC まで。担当の報告は「15 秒」）。boot ID が変わった | 主の seq 17〜19、`facts-reboot.txt` |
| 再起動の後の起動の順 | `gdm.service` が active になったのは起動から 4.978705 秒、`gnome-remote-desktop.service` は 5.171633 秒（GDM の 0.19 秒後）。`RDP server started` が出て、`*:3389` で待ち受け、`enabled`・`active`、firewalld に `rdp`。節の手順 2 は `0` | `facts-reboot.txt`、主の seq 20 |
| 再起動の後のリモートログイン | RDP の認証 → GDM のログイン画面（真っ暗にならない。`peer-08-after-reboot-gdm-greeter.png`）→ OS のパスワード → 新しいセッション（16。`Service=gdm-password`・`Remote=yes`）のデスクトップ（`peer-09-after-reboot-logged-in.png`）。VM のコンソールは、GDM のログイン画面のまま（`main-03-console-after-reboot-remote-login.png`） | クライアントの seq 14〜17、`facts-reboot.txt` |

- ユーザーのセッションへ引き渡すたびに、システムのデーモンが `g_atomic_ref_count_dec: assertion 'old_value > 0' failed` を 1 回出した（20:36:22・20:40:11・20:42:23 の 3 回）。デーモンは動き続け、次の接続にも響かなかった（[2026-10-02 の記録](#追加の確認)と同じ）
- Kerberos の `[ERROR]` の 2 行は、クライアントが認証を通った 3 回とも出た
- 終わりの状態: VM は、リモートログインが有効なまま止めた（スナップショット `after-R4`）。`~/rdp_tls_probe.py` は消していない。クライアントには、保存した証明書が残っている

#### 通らなかった手順と、手順書の前提と違えた所（2026-10-11）

- **手順書のせい**: 手順 11 の `xfreerdp3`。AlmaLinux 10 の `freerdp` パッケージを入れたクライアントにあるのは `xfreerdp` と `wlfreerdp` で、`xfreerdp3` は無い（クライアントで有効なリポジトリにも、この名前のファイルを持つパッケージは無い）。SSH から起動したことにも、Hyper-V にもよらない（クライアントに、この名前のコマンドが無い）
  - `xfreerdp3` は、初版（2026-09-08 の `5ddc2a4`）から書かれていた。その日の実クライアントは Android で、この名前のコマンドを流した記録は、この検証記録に無い（2026-10-02 と 2026-10-06 の記録は、FreeRDP 3.10.3 からつないだと書くが、打ったコマンドの名前を残していない。[ログによる失敗原因の切り分け](#ログによる失敗原因の切り分け)のループバックの確かめは `xfreerdp`）
  - ほかの配布物に `xfreerdp3` という名前のコマンドがあるかは、確かめていない
- **SSH から貼ったせい**: 無い。手順書は「すべてサーバー上で実行する」「本物の端末で」と書いていて、SSH の対話の bash は、それに当たる（手順 6 の対話入力は、SSH の端末で聞かれた）
  - 手順 11 だけは、手順書が思い描く形（クライアントのデスクトップの端末で起動する）と違い、クライアントの SSH のシェルから `xfreerdp` を起動して、窓をコンソールの GNOME のセッションに出した
  - ログイン画面とデスクトップへのキーは、人がクライアントのキーボードで打つ代わりに、検証の道具でクライアントのコンソールに送った（[検証用のパスワードの扱い](#検証用のパスワードの扱い2026-10-11)）
- **Hyper-V のせい**: 確認の出力が変わった所は無い。値として変わるのは、`SERVER_FQDN` と証明書の SAN の `mshome.net`、Default Switch の IP、TPM が無いこと、GPU が無いこと（下の表）
  - Default Switch の IP が変わると、手順 1 の `SERVER_IP` と証明書の SAN の IP が古くなる、というのが担当の見立て。この通しでは IP が変わらなかったので、変わったときの動きは確かめていない

#### Hyper-V に左右されたと思われる値（2026-10-11）

担当の報告が挙げた値を、証跡と照らして、値のまま並べた。ほかのハイパーバイザや実機と比べて確かめたものではない。時間は、静かなホストで測ったものではない（同じ時刻に、ほかの単位の VM が動いていた）。性能の比べには使わない。

| 項目 | 値 |
|---|---|
| `systemd-detect-virt` | `microsoft`。`hostnamectl` は `Chassis: vm`・`Hardware Vendor: Microsoft Corporation`・`Hardware Model: Virtual Machine`・`Firmware Version: Hyper-V UEFI Release v4.1`（`guest-facts-start.txt`） |
| NIC と IP | 2 台とも `eth0` で、アドレスは `/20`（Default Switch）。2 台のあいだは、この IP で直接届いた（クライアントからの ping は平均 0.4 ミリ秒。`peer/guest-facts-start.txt`）。VM の IP は、ゲストを再起動しても同じだった。止めた 1 時間後に起動し直したときも、同じだった（下の数え直しのときの記録。`.verification/campaign/hv/AVC-recheck/vmv-hv-rdp/meta.json`）。クライアントの IP も、前の通しのときと同じだった |
| ホスト名と FQDN | `hostname -f` は `<HOSTNAME>.mshome.net`。手順 1 の `SERVER_FQDN` と、手順 2 の証明書の SAN に、そのまま入った。`mshome.net` は、Default Switch が配る DNS のサフィックスとみる（担当の見立て） |
| TPM | 無い（`/dev/tpm*` が無い。VM に vTPM を付けていない）。`grdctl --system` は、コマンドごとに `Init TPM credentials failed because No TPM device found, using GKeyFile as fallback.` を出した（手順 4 に 3 行、手順 6・8 に 1 行ずつ）。デーモンも、起動のたびに同じ行をログに出した。資格情報は `/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/credentials.ini`（82 バイト、`-rw-------`）に置かれた（中身は読んでいない。`guest-facts-end.txt`） |
| 画面 | コンソールは 2 台とも 1024×768。リモートログインのセッションのモニターは `Virtual remote monitor`（`Meta-0`、`1024x768@60.000`。クライアントの窓の大きさ）で、切ると無くなる。FreeRDP の窓（既定の 1024×768）は、題の帯のぶん、クライアントの画面から下がはみ出した（`screens/peer-*.png`） |
| グラフィック | 受け渡し役のデーモンが、起動のときに `MESA: error: ZINK: failed to choose pdev` などを出した（上の「サーバーのログ」）。その後に `RDP server started` が出て、画面は写った。GPU の無い VM のためとみる（担当の見立て。この通しでは `/dev/dri/` を見ていない） |
| TLS とコーデック | `TLSv1.3 TLS_AES_256_GCM_SHA384`、`selectedProtocol=0x2`。クライアントとは `RDPGFX_CAPVERSION_107`、`H264 (AVC444): false, H264 (AVC420): false` |
| 起動の時間 | クローンして SSH が通るまで、VM が 12.2 秒、クライアントが 13.9 秒（`meta.json`・`peer/meta.json`）。再起動の後の `systemd-analyze` は `660ms (kernel) + 1.781s (initrd) + 14.808s (userspace) = 17.249s`（`facts-reboot.txt`） |
| コンソールの PNG | VM のコンソールは、無操作で画面が消えているあいだ、消える前の絵を返した（20:35:27 に撮った `screens/main-01-console-during-rdp-greeter.png` の時計が 20:34）。再起動の直後に撮った `main-03-…` は、その時刻の絵。コンソールの状態は、PNG ではなく `loginctl` で読んだ |
| メモリとディスク | VM の終わりの `free -m` は、合計 2900・使用 1731・available 1168（リモートログインのセッションと、コンソールのログイン画面が動いている状態）。`/` は 39G のうち 8.1G。クライアントは、合計 1639・使用 1049・available 590（コンソールで GNOME にログインし、FreeRDP を動かした後） |
| 失敗しているユニット | `mcelog.service`（VM。初期設定の通しのときから同じ。手順には影響しない） |

- **SELinux の拒否**: VM の監査ログに、拒否の行は無い
  - 根拠は、後からの数え直し。2026-10-11 12:44 UTC に、検証の司令塔が、止めてあった VM を起動し直して、監査ログのファイル（`/var/log/audit/audit.log` と `audit.log.1`）を `sudo grep -c` で直接数えた。`type=AVC`・`type=USER_AVC`・`type=SELINUX_ERR` で始まる行は、どれも 0。`denied` を含む行も無い。`ausearch --input-logs -m AVC,USER_AVC,SELINUX_ERR` も `<no matches>`（追跡していない `.verification/campaign/hv/AVC-recheck/vmv-hv-rdp/avc.txt`）
  - ログの最初の記録は 07:23:58 UTC（クローンの元の VM の、初期設定の通しの最初の起動）、最後は 12:44:18 UTC。この通し（11:29〜11:43 UTC）と、その前の初期設定・画面オフの任意節・linger・Podman の通しを含む
  - 担当の報告の「拒否は無い（`ausearch -m avc -ts boot` は `<no matches>`）」は、根拠にしていない（[報告と証跡が食い違っていた所](#報告と証跡が食い違っていた所2026-10-11)）
  - クライアントの VM の監査ログは、数え直していない（確かめていない）

#### 過去の記録と違った所（2026-10-11）

- **TPM にかかわる AVC**: 環境 1 の記録（[常に出るが無害なログ](#常に出るが無害なログ)）には、`/dev/tpm0`・`/dev/tpmrm0` への `getattr` の拒否と、TCP ポート 2321 への `name_connect` の拒否が「常に出る」とある。この VM では、`Init TPM credentials failed …` の行は出たが、監査ログに AVC は 1 行も無い。この VM には `/dev/tpm*` が無い。環境 1 との違いの理由は、確かめていない
- **証明書の SAN**: 環境 2 は `hostname` と `hostname -f` が同じで、SAN に同じ DNS の名前が 2 つ入った。この VM は `hostname -f` が `<HOSTNAME>.mshome.net` なので、名前は 2 つとも違う（`rdp-tls.crt` は、環境 2 の 1249 バイトに対して 1261 バイト）
- **起動の順**: 2026-10-06 の VirtualBox の VM（1 vCPU）は、GDM が起動から 33.488638 秒、デーモンが 33.510534 秒。この VM（2 vCPU）は 4.978705 秒と 5.171633 秒。どちらも、GDM の後
- **再起動の後のログインの先**: 2026-10-06 の VM は、ヘッドレスのセッションが自動で起動していて、そこへ引き渡された。この VM にはヘッドレスのセッションが無く、新しいセッションができた
- **手順 8 の `firewall-cmd`**: 2026-10-06 の記録の `Authorization failed`（`sudo` の無い形）は、今の手順書（`sudo` 付き）では出なかった

#### 検証用のパスワードの扱い（2026-10-11）

何を、どの道具で入れたかの記録。値は、どこにも載せていない。

- **RDP のパスワード**（手順 6 で決めた、この検証だけの値。担当がその場で作り、追跡していない証跡のディレクトリのファイルに置いた。この付録を書くときには、そのファイルを開いていない）
  - ドライバの `rb.mjs send --text-file`（記録には伏せて残る）で、端末の入力待ちに答えた。VM の `grdctl` の `Password:` に 1 回（主の seq 10）、クライアントの `xfreerdp` の `Password:` に 3 回（クライアントの seq 7・11・16）
  - どちらの入力待ちも、打った文字を端末に出さない（担当は、答える前に、端末のエコーが切れていることを別の SSH で確かめたと報告している。その出力は、証跡に残っていない）
- **OS のパスワード**（検証用の VM の、検証用のユーザーのもの）
  - 入れたのは、検証の道具の `Login-Console.ps1` だけ。クライアントのコンソールのログイン画面に 1 回（`screens/peer-login/`）、FreeRDP の窓に出た VM のログイン画面に 3 回（1 回目のログイン・つなぎ直し・再起動の後。`screens/rdp-login/`）
  - FreeRDP の窓への 3 回は、キーの送り先をクライアントのコンソール、SSH で状態を調べる先を VM にする、道具の想定の外の組み合わせだった。担当は、決まり（パスワードをキー送信で打ってよいのは、この道具を通すときだけ）の範囲かどうかの判断を、司令塔に任せた。司令塔は、受け入れた（検証用の VM の OS のパスワードで、検証用の VM の中だけで使った）
  - FreeRDP の窓に向けて道具を呼んだのは 4 回（クライアントのコンソールのログインの 1 回は、別）。つなぎ直しのときの 1 回目の呼び出し（11:39:16 UTC）は、利用者が選ばれていなかったので、道具がパスワードを打たずに止まった（PNG は 2 枚で、どちらも利用者の一覧）。打った 3 回は、打つ前の PNG がパスワードの欄（空）、打った後の PNG がデスクトップで、打った文字は写っていない
  - 道具は、3 回とも「ログインできていない」と返した（担当の報告による。道具は `seat0` のセッションを探すので、seat の無いリモートのセッションを数えない）。ログインできたことは、`loginctl` と PNG で確かめている
- 実アカウントのパスワードは、使っていない

#### 指摘と状態（2026-10-11）

- 行番号は、コミット `114c2b2` の `docs/gnome-remote-desktop.md` のもの。直した後の手順書では、行がずれている
- 指摘は、担当の報告が挙げた 7 つ（重大度も、報告のまま）。直し方の案のうち、指摘 2 の Kerberos の行だけは、報告に無く、ほかの 2 本の手順書に合わせて足した
- 「状態」は、2026-10-11 に手順書を直した後のもの
- 手順書の指摘は 7（中 1、低 6）。直した 4（どれも箇条書きの文言だけ）、未対応 3

| 連番 | 重大度 | 場所 | 何が起きたか | 切り分け | 直し方の案 | 状態 |
|---|---|---|---|---|---|---|
| 1 | 中 | 手順 11 の 1 つ目の箇条書き（`:179`） | `xfreerdp3 /v:<SERVER_IP>:3389 /u:<システムRDPユーザー名>` の形は、AlmaLinux 10.2 のクライアントでは `bash: xfreerdp3: コマンドが見つかりませんでした...` で終わる（終了コード 127）。`xfreerdp` に読み替えると通る | 手順書の誤り。`freerdp-3.10.3-12.el10_2.14` を入れたクライアントにあるのは `/usr/bin/xfreerdp` と `/usr/bin/wlfreerdp` で、`dnf -q provides "*/xfreerdp3"` は一致が無い。[gnome-headless-session.md](../gnome-headless-session.md) の手順 10 と、[gnome-desktop-sharing.md](../gnome-desktop-sharing.md) の「再起動の後に確かめてつなぐ」の手順 3 は「AlmaLinux 10 の FreeRDP（`freerdp` パッケージ）なら `xfreerdp …`」と書いていて、この手順書だけ名前が違った。参考資料の手順 10 の補足も `xfreerdp` | ほかの 2 本と同じ言い方にそろえる | 直した（文言。箇条書きの中のコマンド名を `xfreerdp` にして、頭に「AlmaLinux 10 の FreeRDP（`freerdp` パッケージ）なら」を付けた。直した後の形は、この通しで 3 回起動して、3 回ともログインまで通っている） |
| 2 | 低 | 手順 11 の箇条書き（`:179`〜`:182`）と、手順 4 の箇条書き（`:77`） | FreeRDP が聞く 3 つ（証明書の `Do you trust the above certificate? (Y/T/N)`、`Domain:`、`Password:`）、初めての接続でも出る `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` などの 12 行、パスワードの後の Kerberos の `[ERROR]` の 2 行が、書かれていなかった。手順 4 は `TLS fingerprint` を「手順 10 で使う」と書くが、クライアントの `Thumbprint:` と照らす手順 11 でも使う | 手順書の書き落とし。出た順は、ほかの 2 本の手順書の箇条書きのとおりだった。SSH にも Hyper-V にもよらないとみる: 初めての接続の警告は、[gnome-headless-session.md の検証記録](gnome-headless-session.md)の 2026-10-01 の実機と、[gnome-desktop-sharing.md の検証記録](gnome-desktop-sharing.md)の 2026-10-07 の VirtualBox の VM にも出ている。Kerberos の `krb5_parse_name` の行も、同じ 2026-10-07 の記録にある（2 本とも、2026-10-11 の Hyper-V の VM の記録にも、両方がある） | ほかの 2 本の箇条書きを足す。手順 4 は「手順 10・11 で使う」にする | 直した（文言。手順 11 に箇条書きを 6 つ足し、手順 4 の括弧の中を直した。コードブロックは無い） |
| 3 | 低 | 手順 11 の、ログインの箇条書き（`:181`） | FreeRDP の窓に出たログイン画面は、キーボードだけだと、Enter では利用者が選ばれないことがあった（Tab で利用者に移してから Enter で選べた）。OS のパスワードの後は、クライアントがもう 1 度つなぎ直されてから、デスクトップが出る（新しいセッションができてから 6〜7 秒） | つなぎ直しのとき、Enter の後も利用者の一覧のままだった（PNG）。キーは、検証の道具でクライアントのコンソールに送ったもので、人が打ったものではない。マウスでのクリックは、見ていない。1 回目と再起動の後に、どのキーで利用者が選ばれたかは、証跡に残っていない | そのままでもよい。足すなら「利用者をクリックする（キーボードなら、Tab で移って Enter）」 | 未対応（手順書は変えていない。1 回だけの、道具を通したキーでの出来事で、手順書の文「OS アカウントでログインする」とは食い違わない。つなぎ直しの動きは、参考資料の手順 11 の補足に足した） |
| 4 | 低 | 手順 3（`:55`〜`:65`） | 「確認」の見出しがあるのに、出力を照らす箇条書きが無い（リードは「『確認』から後ろの出力を箇条書きで確かめる」） | 手順書の書き落とし。出力は、`rdp-tls.crt` が `-rw-r--r--`、`rdp-tls.key` が `-rw-------`、どちらも所有者が `gnome-remote-desktop`、コンテキストが `gnome_remote_desktop_var_lib_t`。環境 2 の出力（[手順 3 の補足](#実施手順--手順-3-補足-selinux-コンテキスト)）も同じ形 | 成功条件の箇条書きを足す | 直した（文言。箇条書きを 1 つ足した） |
| 5 | 低 | 手順 4（`:67`〜`:77`）・手順 6（`:98`〜`:106`）・手順 8（`:115`〜`:125`） | TPM の無い PC では、`grdctl --system` のたびに `Init TPM credentials failed because No TPM device found, using GKeyFile as fallback.` が出る（手順 4 で 3 行、手順 6・8 で 1 行ずつ）。実施手順には、この行の説明が無かった（[注意点](../extra/gnome-remote-desktop.md#注意点)にだけある） | `failed` と出るので、手順 4 で止まる人がいそう、というのが担当の見立て。Hyper-V だけのことではない: 環境 1 の記録（[常に出るが無害なログ](#常に出るが無害なログ)）と、2026-10-06 の VirtualBox の VM の記録にも、同じフォールバックがある。gnome-headless-session.md の手順 4 は、箇条書きでこの行に触れている | 手順 4 に箇条書きを足す | 直した（文言。手順 4 に、「TPM の無い PC では」の条件を付けた箇条書きを 1 つ足した） |
| 6 | 低 | 手順 9 のパイプの右側の `openssl sha256`（`:132`・`:133`）と、手順 10 の `['openssl', …]`（`:163`）・`python3`（`:167`） | 初期設定を通した PC では、PATH の先頭が Homebrew なので、`openssl` は Homebrew のもの（この VM では 4.0.3）、`python3` も Homebrew のもの（3.15.0）に解決される。OS のものは 3.5.8 と 3.12.15。この通しでは、どれも通った | 対話のシェルの `type -a openssl python3` が、Homebrew のものを先に返した（主の seq 16）。手順 2 の `sudo -u gnome-remote-desktop openssl` と、手順 9 の `sudo openssl` は、sudo の `secure_path` で OS の `/bin/openssl` になる（証明書は、OS の OpenSSL で作られる）。gnome-headless-session.md と gnome-desktop-sharing.md の同じプローブは、`/usr/bin/python3` と書いている | そろえるなら、手順 9 の右側と手順 10 を `/usr/bin/openssl`・`/usr/bin/python3` にする。そのままにするなら、「Homebrew の OpenSSL 4.0.3 と Python 3.15.0 でも通った」を検証記録に残す | 未対応（コードブロックを変える直しで、変えた形は VM で貼っていない。害は見ていない。Homebrew の OpenSSL 4.0.3 と Python 3.15.0 に解決される状態で通ったことを、ここと参考資料の手順 9 の補足に残した） |
| 7 | 低 | 手順 5 の `systemctl enable --now`（`:89`） | 何も出さなかった（`Created symlink` の行が出ない）。手順 4 の `grdctl --system rdp enable` が、もうデーモンを起動していた（手順 4 の直後に `Unit status: active`。journal の `Starting` が、手順 4 を貼った秒） | [手順 4 の補足](#実施手順--手順-4-補足-grdctl)の「`grdctl --system rdp enable` / `disable` はサービスの起動・停止も行う」と合う。ユニットの有効化も `grdctl` が行ったとみる（担当の見立て。手順 4 の直後に `is-enabled` を読んでいない）。手順 5 を貼った秒（20:31:42）に、`Started gnome-remote-desktop.service` の行がもう 1 つ出ている（`Starting` の行は無い。理由は確かめていない） | そのままでよい（害は無い） | 未対応（手順書は変えていない。手順 5 には、確かめる出力を書いた箇条書きが無く、食い違いは無い。この観察は、参考資料の手順 4 の補足に足した） |

環境と道具の指摘（手順書の外。このリポジトリでは直さない）:

- **`Login-Console.ps1` を、FreeRDP の窓のログイン画面に使ったとき**: ログインできても「できていない」と返す（`seat0` のセッションを探すため）。そのユーザーのリモートのセッションが既にあると、パスワードの欄になったかどうかの見分けがいつも真になり、利用者を選び直す手が働かない（つなぎ直しで、打たずに止まった）。担当の報告による
- **端末の無い SSH の `ausearch`**: `--input-logs` を付けないと、監査ログではなく標準入力を読み、`<no matches>` を返す（上の「SELinux の拒否」）
- **FreeRDP 3.10.3**: 初めての接続でも `REMOTE HOST IDENTIFICATION HAS CHANGED!`。`Password:` の後に Kerberos の `[ERROR]` が 2 行。Ctrl+C で切ると終了コードは 145
- **Hyper-V のコンソールの PNG**: 画面が消えているあいだは、消える前の絵が返る
- **ゲスト**: `mcelog.service` が、起動のたびに failed になる

#### 手順書を直した所（2026-10-11）

通した後（`114c2b2` より後）に直した。どれも箇条書きの文言だけで、コードブロックは 1 つも変えていない。VM で貼り直すものは無い。

- [手順書](../gnome-remote-desktop.md)の手順 3: 成功条件の箇条書きを 1 つ足した（指摘 4）
  - 「`rdp-tls.key` が `-rw-------`、`rdp-tls.crt` が `-rw-r--r--` で、どちらも所有者が `gnome-remote-desktop`、コンテキストに `gnome_remote_desktop_var_lib_t` が出ればよい」
- 同じ手順書の手順 4
  - 「（手順 10 で使う）」を「（手順 10・11 で使う）」にした（指摘 2）
  - TPM の無い PC で出る `Init TPM credentials failed because No TPM device found, using GKeyFile as fallback.` の箇条書きを 1 つ足した（指摘 5。手順 6・8 でも出ること、害は無いこと、注意点へのリンク）
- 同じ手順書の手順 11
  - 1 つ目の箇条書きを、「`xfreerdp3 …` の形で接続する」から「AlmaLinux 10 の FreeRDP（`freerdp` パッケージ）なら `xfreerdp /v:<SERVER_IP>:3389 /u:<システムRDPユーザー名>` の形で接続する」にした（指摘 1）
  - FreeRDP の入力待ちの箇条書きを 6 つ足した（指摘 2）: 証明書の `Thumbprint:` と `(Y/T/N)` への答え方、初めてでも出る警告、`Y` の後は聞かれないこと、`Domain:` は空のまま Enter、`Password:` には手順 6 のパスワード、Kerberos の `[ERROR]` の行
  - もとの「システム共通パスワードで RDP 認証を通過すると GDM のログイン画面が出るので、OS アカウントでログインする」と、その後ろの箇条書きは、変えていない。Windows のクライアントの案内は、足していない（この通しでは確かめていない）
- 直した後の手順 11 のコマンドの形は、この通しで起動して通っている（クライアントの seq 4・9・14 の 3 回）。足した箇条書きの元になった出力は、どれも、この通しの記録にある（主の seq 4〜6・8・13 の `session/session-001.raw` と、`peer/session/session-001.raw`）。直した後の手順書を見ながらの通しは、していない
- [参考資料](../reference/gnome-remote-desktop.md)
  - 「実施手順 / 手順 4: 補足: grdctl」に、手順 5 の `systemctl enable --now` が何も出さなかったこと（指摘 7）と、TPM を使えないときの行（指摘 5）を足した
  - 「実施手順 / 手順 9: 補足: 鍵と証明書」に、`openssl` と `python3` が Homebrew のものに解決されること（指摘 6）を足した
  - 「実施手順 / 手順 10: 補足」の TLS プローブに、この VM でプローブが残した 9 行のことを 1 行足した
  - 「実施手順 / 手順 11: 補足: クライアントからのログイン」に、AlmaLinux 10 のコマンド名（指摘 1）、FreeRDP の証明書の確認と Kerberos の行（指摘 2）、ログインまでに 2 回つなぎ直されること（指摘 3）を足した
- [ロールバックと注意点](../extra/gnome-remote-desktop.md)は、直していない（この通しでは流していない。注意点の「TPM 警告」と「リモートログインのセッション」は、この通しの結果と食い違わない）

#### 報告と証跡が食い違っていた所（2026-10-11）

- **手順 11 の数え方**: 担当の報告は「通した 11、通らなかった 0」と数え、手順 11 に「コマンド名を `xfreerdp` に読み替えた。書かれたままの `xfreerdp3` は通らない」と注を付けている。この付録は、書かれたままの形が終了コード 127 で終わったので、手順 11 を「通らなかった（読み替えて通した）」に数えた。起きたことの記述は、報告と証跡で食い違っていない
- **SELinux の拒否の読み方**: 担当の報告は「拒否は無い（再起動の前も後も `ausearch -m avc -ts boot` は `<no matches>`）」と書く（`facts-reboot.txt`・`guest-facts-end.txt` に、その `<no matches>` がある）。この `ausearch` は、端末の無い別の SSH から、`--input-logs` を付けずに流したもの。その形の `ausearch` は、監査ログではなく標準入力を読み、拒否があっても `<no matches>` を返す（[samba.md の検証記録](samba.md)にも、同じ落とし穴の記録がある）
  - 結論（拒否は無い）は、後からの数え直しで確かめ直した（上の「SELinux の拒否」）。VM については、報告と同じ結論。クライアントについては、確かめていない
- **証跡に残っていない読み**: 入力待ちの端末のエコーが切れていること（`stty`）、つなぎ直しのときのログイン画面のセッションの番号、`Login-Console.ps1` の返した値と、送ったキーの順は、担当の報告にだけある（出力のファイルが無い）。この付録では、「担当の報告による」と書いた
- **小さな数字の違い**: 報告の「再起動は、送ってから SSH がつながるまで 15 秒」は、`steps.jsonl` では 14.5 秒。報告の「ほかは 1.8〜2.0 秒」には、手順 6 の貼り付け（入力待ちと判定されるまでの 3.3 秒）が入っていない。この付録は、`steps.jsonl` の数字で書いた
- ほかの数字と出力（手順 1〜10 の出力、時刻、セッションの属性、証明書の中身、PNG）は、報告と証跡で食い違わなかった
  - PNG は 27 枚（`screens/` の直下の 13 枚と、`Login-Console.ps1` が残した `screens/peer-login/` の 3 枚・`screens/rdp-login/` の 11 枚）。書いた後の点検（さらに別の担当。VM には触れていない）で、27 枚とも開いて、この付録の書き方と合うことを見た。打ったパスワードが写っている PNG は、無かった

#### 確かめていないこと（2026-10-11）

- Windows の「リモート デスクトップ接続」・Android のクライアント・実物の別のマシンからの接続（クライアントは、同じ仮想スイッチの AlmaLinux 10 の VM の FreeRDP 3.10.3 だけ）
- クライアントからのマウスの操作（ログイン画面の利用者のクリックを含む）、クリップボード、音
- FreeRDP の証明書の確認に `T`・`N` で答えたとき。証明書を作り直した後の確認。違うパスワードでの拒否
- 手順 2 の `中断:` の側、手順 7 を行わなかったときの `Credentials are not set, denying client`、TPM のある PC の `grdctl` の出力
- 任意節「接続元を LAN に絞る」、節「設定済みのサーバーで GDM の後に起動させる」の手順 1・4・5、ロールバック、注意点の「設定レイヤーの食い違い」の確認方法
- コンソールでログイン中のユーザーと同じユーザーでのリモートログイン（VM のコンソールは、ログイン画面のままにした）
- ヘッドレスのセッション（3390）やデスクトップ共有との併用
- ログイン画面のまま長く置いたとき（この VM は、初期設定の任意節で `sleep.target` を `masked` にしてある）、長い放置、ログアウト
- VM を起動し直して Default Switch の IP が変わったときの動き
- 手順 9・10 の `openssl`・`python3` を `/usr/bin/` にした形（指摘 6。直していない）
- 直した後の手順書の箇条書きを見ながらの通し（文言だけの直し。直した後のコマンドの形と、足した文の元になった出力は、この通しの記録にある）
- クライアントの VM の SELinux の拒否
- 実機、aarch64

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
