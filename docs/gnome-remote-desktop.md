# GNOME Remote Desktop 有効化手順（リモートログイン方式）

- **対象ホスト**: <HOSTNAME> (<SERVER_IP>)
- **OS**: AlmaLinux 10.2 (Lavender Lion)
- **実施日**: 2026-09-08
- **方式**: リモートログイン（システムデーモン `grdctl --system`）
- **状態**: 全手順完了。接続成功を確認済み（2026-09-08 09:25）

> **注記**: 環境固有の値はプレースホルダに置換してある。自環境の値に読み替えること。
>
> | プレースホルダ | 意味 | 例 |
> |---|---|---|
> | `<HOSTNAME>` | サーバーのホスト名 | `my-server` |
> | `<HOSTNAME>.<DOMAIN>` | サーバーの FQDN | `my-server.lan` |
> | `<SERVER_IP>` | サーバーの IP アドレス | `192.168.10.100` |
> | `<LAN_SUBNET>` | LAN のサブネット | `192.168.10.0/24` |
> | `<USER>` | OS アカウント名 | `alice` |
>
> TLS fingerprint は実際に生成された自己署名証明書のものをそのまま残してある（秘密情報ではなく、差し替え時に値が変わることを示すため）。

---

## 実施前の状態

| 項目 | 状態 |
|---|---|
| `gnome-remote-desktop` | `49.3-4.el10_2` インストール済み（`/usr/bin/grdctl` あり） |
| RDP バックエンド | 無効（`Status: disabled`） |
| `gnome-remote-desktop.service` | `disabled` / `inactive` |
| TLS 証明書・鍵 | 未設定（`grdctl status` が証明書エラーを出力） |
| システム RDP 資格情報 | 未設定 |
| `gdm` | `47.0-22.el10_2` / active、`systemctl get-default` = `graphical.target` |
| firewalld | active、default zone = `public`、3389/tcp 未開放 |
| SELinux | Enforcing |
| `freerdp` | 未インストール |
| NIC | `bridge0` = <SERVER_IP>/24、`enp198s0f3u1u1`（ともに public ゾーン） |

## 選択した方針

- **リモートログイン方式**（システムデーモン）— ローカルログイン不要。RDP 接続時に GDM 経由で新規セッションを作成する。
- ファイアウォールは **public ゾーンで 3389/tcp を開放**。
- 操作権限はフル操作（リモートログイン方式に `view-only` 設定は存在せず、常にフル操作）。

### 認証は 2 段構え

1. **システム共通の RDP 資格情報**（`grdctl --system rdp set-credentials`）— GDM ログイン画面へ到達するためのゲートウェイ認証。RDP クライアントの接続時に入力する。ユーザー名は OS アカウントと一致していなくてよい。
2. **各ユーザーの OS 資格情報** — GDM のログイン画面で入力する。

---

## 実施した手順

### 1. 前提パッケージのインストール

証明書生成ツール `winpr-makecert` を得るため。

```bash
sudo dnf install -y freerdp
```

→ `freerdp-2:3.10.3-12.el10_2.10.x86_64` をインストール。

### 2. TLS 証明書・鍵の生成

`gnome-remote-desktop` ユーザー自身として生成し、所有権を最初から正しくする。

```bash
sudo -u gnome-remote-desktop mkdir -p ~gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates
sudo -u gnome-remote-desktop winpr-makecert -silent -rdp \
  -path ~gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates rdp-tls
```

生成物:

```
/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.crt
/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
```

### 3. パーミッションと SELinux コンテキストの調整

`winpr-makecert` が生成した秘密鍵が 0644 だったため 0600 に絞った（親ディレクトリ `/var/lib/gnome-remote-desktop` が 0700 のため実害はないが念のため）。

```bash
sudo chmod 600 /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
sudo restorecon -Rv /var/lib/gnome-remote-desktop
```

`restorecon` は差分なし。コンテキストは元から `gnome_remote_desktop_var_lib_t` で正しい状態だった。

### 4. grdctl でシステムデーモンを設定

```bash
CERTDIR=/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates
sudo grdctl --system rdp set-tls-key  "$CERTDIR/rdp-tls.key"
sudo grdctl --system rdp set-tls-cert "$CERTDIR/rdp-tls.crt"
sudo grdctl --system rdp enable
```

TLS fingerprint: `<FINGERPRINT>`

### 5. サービスの有効化とファイアウォール開放

```bash
sudo systemctl enable --now gnome-remote-desktop.service
sudo firewall-cmd --permanent --add-service=rdp
sudo firewall-cmd --reload
```

`gdm` は既に active、`systemctl get-default` も既に `graphical.target` だったため、RHEL 標準手順にある `systemctl enable --now gdm` / `systemctl set-default graphical.target` は不要だった。

`--add-service=rdp` は firewalld 定義済みサービスで 3389/tcp を開放する（`--add-port=3389/tcp` と等価）。

### 6. システム共通 RDP 資格情報の設定（**未実施**）

パスワードをシェル履歴・ログに残さないため、引数なしで対話入力する。

```bash
sudo grdctl --system rdp set-credentials
```

> Claude Code のプロンプトからは `! sudo grdctl --system rdp set-credentials` で実行できる。

---

## 完了時点の状態

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
	Username: (empty)        ← 手順 6 で設定する
	Password: (empty)

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
gnome-remote-de[19584]: RDP server started
systemd[1]: Started gnome-remote-desktop.service - GNOME Remote Desktop.
```

---

## 検証方法

サーバー側:

```bash
sudo grdctl --system status              # Status: enabled / Username に設定値
systemctl status gnome-remote-desktop    # active (running)
ss -lntp | grep 3389                     # *:3389 で LISTEN
firewall-cmd --list-services             # rdp が含まれる
```

クライアント側（LAN 内の別マシン、または本機から）:

```bash
xfreerdp3 /v:<SERVER_IP>:3389 /u:<システムRDPユーザー名> /cert:ignore
```

1. システム共通パスワードで RDP 認証を通過
2. GDM ログイン画面が表示される
3. `<USER>` などの OS アカウントでログイン → 新規 GNOME セッションが起動

問題があれば以下を並行して確認する:

```bash
journalctl -u gnome-remote-desktop -f
journalctl -u gdm -f
```

---

## 注意点

- **TPM 警告**: `grdctl --system` 実行時と service 起動時に毎回
  `Init TPM credentials failed ... using GKeyFile as fallback` が出るが、この機体では TPM が使えないための正常なフォールバック。資格情報は `/etc/gnome-remote-desktop/` 配下の GKeyFile に保存される。
- **既存ローカルセッションとの併存**: `<USER>` が tty2 で Wayland セッションにログイン中。リモートログインは常に**新規セッション**を作るため、同一ユーザーで接続すると GDM が既存セッションの扱い（切替 or 拒否）を求める場合がある。既存デスクトップをそのまま見たい場合は「画面共有」方式（ユーザーデーモン `systemctl --user enable --now gnome-remote-desktop`）が必要 — 今回は採用していない。
- **自己署名証明書**: クライアント側で証明書警告が出る。信頼できる CA の証明書がある場合は手順 2〜4 でそちらのパスを指定する。
- **public ゾーンでの開放**: `bridge0` と `enp198s0f3u1u1` の両方が public ゾーンに属するため、両 NIC で 3389/tcp が開く。LAN 限定に絞る場合は後から次に変更できる。

  ```bash
  sudo firewall-cmd --permanent --remove-service=rdp
  sudo firewall-cmd --permanent --add-rich-rule='rule family=ipv4 source address=<LAN_SUBNET> port port=3389 protocol=tcp accept'
  sudo firewall-cmd --reload
  ```

---

## ロールバック

```bash
sudo systemctl disable --now gnome-remote-desktop.service
sudo grdctl --system rdp disable
sudo grdctl --system rdp clear-credentials
sudo firewall-cmd --permanent --remove-service=rdp && sudo firewall-cmd --reload
```

---

## 参照

- [Chapter 1. Remotely accessing the desktop — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/remotely-accessing-the-desktop)
- [GNOME/gnome-remote-desktop README.md](https://github.com/GNOME/gnome-remote-desktop/blob/master/README.md)

---

# 付録: ログインできなかった原因の調査記録（2026-09-08）

## 判明した 2 つの落とし穴

### 落とし穴 1: `grdctl` の対話入力は TTY 必須

`grdctl --system rdp set-credentials` を引数なしで実行すると `Username: ` / `Password: ` のプロンプトが出るが、これは **stdin ではなく制御端末（TTY）から直接読む**（`getpass` 相当）。

そのため以下はいずれも**失敗する（しかも exit 0 で成功したように見える）**:

```bash
# NG: TTY がない実行環境（スクリプト、Claude Code の ! 実行など）
sudo grdctl --system rdp set-credentials

# NG: パイプで流し込む
printf 'user\npass\n' | sudo grdctl --system rdp set-credentials
```

対処は次のいずれか:

```bash
# OK: 本物の端末エミュレータ上で対話入力（パスワードが記録に残らないため推奨）
sudo grdctl --system rdp set-credentials

# OK: 引数で渡す（履歴・ps・会話ログに残る点に注意）
sudo grdctl --system rdp set-credentials <username> <password>
```

設定できたかは次で確認する。`(empty)` / `(null)` なら未設定、`(hidden)` なら設定済み:

```bash
sudo grdctl --system status | grep Username
```

> `--show-credentials` を付けるとパスワードが**平文で表示される**。設定の有無を見るだけなら付けないこと。

### 落とし穴 2: 資格情報の変更にはデーモンの再起動が必要

デーモンは**起動時に資格情報を読み込んでキャッシュする**。稼働中に `grdctl` で設定・変更しても反映されず、ログには次が出続ける:

```
[RDP] Credentials are not set, denying client
```

`grdctl --system status` 側は設定済みに見えるため紛らわしい。設定・変更のたびに再起動する:

```bash
sudo systemctl restart gnome-remote-desktop.service
```

## ログによる失敗原因の切り分け

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

## ユーザー名の照合仕様（実測）

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

## 常に出るが無害なログ

以下は環境要因による既知の出力で、RDP 接続の成否とは無関係:

- `Init TPM credentials failed ... using GKeyFile as fallback` — TPM 非対応環境でのフォールバック
- SELinux AVC: `/dev/tpm0`・`/dev/tpmrm0` への `getattr` 拒否、TCP ポート 2321 への `name_connect` 拒否 — いずれも上記 TPM 初期化試行に伴うもの
- `kerberos_AcquireCredentialsHandleA: krb5_init_context ...` — Kerberos 未設定環境で NTLM にフォールバックする際の出力

---

# 決着: 原因はクライアント側のユーザー名の誤り

## 結論

接続失敗の原因は、**Android クライアントに入力していたユーザー名が、サーバーに設定した値（`<USER>`）と違っていた**こと。クライアント側で正しいユーザー名に修正して解決した。

サーバー側の設定（TLS 証明書・サービス・ファイアウォール・GDM ハンドオーバー）はすべて当初から正常だった。

## 成功時のログ

```
09:25:42  [RDP] Client cannot handle graphics and audio simultaneously. Disabling audio output redirection
09:25:43  [RDP] Sending server redirection          ← GDM へのハンドオーバー成功
09:25:43  ERRINFO_LOGOFF_BY_USER                    ← 利用者によるログオフ
```

`Sending server redirection` が出れば、1 段目の RDP 認証を通過して GDM／ユーザーセッションへの引き渡しに成功している。

## 設定済みユーザー名の確認方法

`grdctl --system status` は `(hidden)` としか表示せず、`--show-credentials` を使うとパスワードまで平文で出てしまう。**ユーザー名だけ**を確認したい場合は資格情報ストアから該当フィールドのみ抽出する:

```bash
sudo grep -oP "'username':\s*<'\K[^']*" \
  /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/credentials.ini
```

資格情報は GVariant 形式で `credentials=` という 1 つのキーにまとめて格納されている（`/etc/gnome-remote-desktop/grd.conf` の方には TLS 設定と `enabled` しか無い）。

## デバッグ用の詳細ログ（必要時のみ）

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

## 教訓

ログの署名を最初に確認していれば早く切り分けられた。順に:

1. `Credentials are not set` → 未設定、または設定後にデーモンを再起動していない
2. `Could not find user in SAM database` → **ユーザー名**が違う
3. `SEC_E_MESSAGE_ALTERED` → **パスワード**が違う
4. `Sending server redirection` → 認証成功

今回は一貫して 2 が出ていた（3 は一度も出ていない）ため、パスワードの再設定を繰り返しても解決しなかった。

---

# TLS 証明書の生成方法（`winpr-*` が使えない環境）

RHEL 10 の公式手順は `freerdp` パッケージの `winpr-makecert` を使うが、パッケージ導入が制限された環境では使えない。以下は実機で検証した代替手段。

## 前提: GRD が実際に要求するもの

`winpr-makecert` は GRD の要件ではなく、Red Hat のドキュメントがそのツールを採用しているだけ。**GNOME 本家の README は openssl による生成を正規の手順として記載している。**

GRD 側の要件は 3 つだけ:

- **PEM 形式**であること（OpenSSH 形式の鍵は不可。`grdctl status` が `[x509_utils_from_pem]: BIO_new failed` を出す）
- システムデーモン用は **`gnome-remote-desktop` ユーザー/グループ所有**で読めること
- SELinux コンテキストが `gnome_remote_desktop_var_lib_t`（`/var/lib/gnome-remote-desktop` 配下に置けば自動で付く）

特殊な拡張や独自形式の要求は無い。

## winpr-makecert 製証明書のプロファイル（実測）

| 項目 | 値 |
|---|---|
| 種別 | X.509 v3、自己署名（Issuer = Subject） |
| Subject | `CN=<hostname>` |
| 鍵 | RSA 2048 bit、PKCS#8 PEM（`-----BEGIN PRIVATE KEY-----`） |
| 署名 | sha256WithRSAEncryption |
| 有効期間 | 1 年 |
| 拡張 | `Extended Key Usage: TLS Web Server Authentication` のみ |
| SAN | **なし** |

`winpr-makecert --help` では `-eku` や `-b`/`-e` が "Unsupported" と明記されており、SAN を付けるオプションは存在しない。**openssl の方が機能的に上位。**

## 方式 A: openssl で生成（推奨）

追加ソフトウェア不要。既存ファイルを温存したいので別名で生成する。

```bash
CERTDIR=/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates

sudo -u gnome-remote-desktop openssl req -x509 -newkey rsa:2048 -noenc -days 3650 \
  -subj "/CN=$(hostname)" \
  -addext "subjectAltName=DNS:$(hostname),DNS:$(hostname -f),DNS:<SERVER_IP>,IP:<SERVER_IP>" \
  -addext "extendedKeyUsage=serverAuth" \
  -keyout "$CERTDIR/rdp-tls-openssl.key" \
  -out    "$CERTDIR/rdp-tls-openssl.crt"

sudo chmod 600 "$CERTDIR/rdp-tls-openssl.key"
sudo chmod 644 "$CERTDIR/rdp-tls-openssl.crt"
sudo restorecon -Rv /var/lib/gnome-remote-desktop

sudo grdctl --system rdp set-tls-key  "$CERTDIR/rdp-tls-openssl.key"
sudo grdctl --system rdp set-tls-cert "$CERTDIR/rdp-tls-openssl.crt"
sudo systemctl restart gnome-remote-desktop.service
```

> OpenSSL 3.x では `-nodes` は deprecated。`-noenc` を使う。
> `systemctl restart` は接続中の RDP セッションを切断するので、利用者がいないタイミングで実行する。

### winpr 版との意図的な差分

- **SAN を付与** — winpr 版には無い。付けないとクライアントで毎回「名前が一致しない」警告が出る
- **有効期間 10 年** — winpr 版は 1 年で、毎年の更新作業が必要になる

### 落とし穴: FreeRDP は SAN の `IP:` を見ない

**FreeRDP 3.10 は SAN の DNS エントリしか照合せず、`IP:` エントリを無視する。** IP アドレスで接続する運用なら、IP を **DNS エントリとしても併記**する必要がある。

`DNS:<SERVER_IP>` を入れずに `IP:<SERVER_IP>` だけにした場合、`<SERVER_IP>` で接続すると:

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

`DNS:<SERVER_IP>` を追加すると警告は消える（実測で確認済み）。

## 方式 B: podman コンテナで winpr-makecert を使う

ホストにパッケージを入れずに winpr-makecert 製の証明書が必要な場合。rootless podman で動作確認済み。

```bash
OUT=$(mktemp -d)
podman run --rm --hostname "$(hostname)" -v "$OUT:/out:Z" \
  docker.io/library/almalinux:10 \
  bash -c 'dnf install -y freerdp >/dev/null 2>&1 && winpr-makecert -silent -rdp -path /out rdp-tls'

CERTDIR=/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates
sudo install -o gnome-remote-desktop -g gnome-remote-desktop -m 644 "$OUT/rdp-tls.crt" "$CERTDIR/"
sudo install -o gnome-remote-desktop -g gnome-remote-desktop -m 600 "$OUT/rdp-tls.key" "$CERTDIR/"
sudo restorecon -Rv /var/lib/gnome-remote-desktop
rm -rf "$OUT"
```

### 注意点（すべて実測で確認）

- **`--hostname "$(hostname)"` は必須。** 渡さないとコンテナのランダム ID が CN になる:
  ```
  subject=CN=f4fd0ab7095a        ← --hostname なしの場合
  subject=CN=<HOSTNAME>       ← --hostname あり
  ```
- **`-n "CN=..."` は使ってはいけない。** winpr-makecert の `-n` は解析が壊れており、subject が破損する:
  ```
  subject=L=<HOSTNAME の一部>, O=<HOSTNAME の一部>, CN=CN=<HOSTNAME>
  ```
  `--hostname` だけで正しい CN になるので `-n` は不要。
- **`:Z`** は SELinux ラベル付け替え。rootless podman で必須
- rootless podman ではコンテナ内 root がホストの呼び出しユーザーにマップされるため、生成物は呼び出しユーザー所有になる。**ホストへ配置する際に `install -o` で所有者を付け直すこと**
- イメージ pull に約 200 MB のダウンロードが発生する。方式 A で足りるならそちらを使う

### 差し替えの実測結果

実機で方式 B の証明書に差し替えて動作確認済み（確認後は方式 A に戻してある）。

| 確認項目 | 結果 |
|---|---|
| `grdctl --system status` の fingerprint | `8a:24:8a:40:…` に切り替わった |
| クライアントに届く Thumbprint | `8a:24:8a:40:…` で **grdctl の表示と完全一致** |
| TLS ハンドシェイク | 成功（NLA 段階の `SAM database` まで到達、`BIO_do_handshake` は出ない） |
| ホスト名 `<HOSTNAME>` で接続 | 名前不一致なし |
| IP `<SERVER_IP>` で接続 | **名前不一致の警告あり** |

IP で接続したときの警告は SAN が無いことが原因で、方式 A との実質的な差はここだけ:

```
The hostname used for this connection (<SERVER_IP>:3389)
does not match the name given in the certificate:      ← 単数形。SAN が無く CN のみ
Common Name (CN):
	<HOSTNAME>
```

方式 A では「Alternative names」の一覧が出るのに対し、方式 B（winpr-makecert 製）は SAN 自体が無いため CN だけで照合される。**ホスト名で接続する運用なら方式 B でも実用上問題ない。IP で接続するなら方式 A を使う。**

また、winpr-makecert が出力する鍵は **0644**（コンテナ内でもホスト側でも）。`install -m 600` で絞る手順を省略しないこと。

## 検証方法

### 1. GRD が証明書を解釈できたか

```bash
sudo grdctl --system status | grep -A1 "TLS certificate"
```

fingerprint が表示されれば GRD が PEM を解析できている。差し替え時は値が変わることを確認する。

### 2. 鍵と証明書が対応しているか

```bash
sudo openssl x509 -in "$CERTDIR/rdp-tls-openssl.crt" -noout -modulus | openssl sha256
sudo openssl rsa  -in "$CERTDIR/rdp-tls-openssl.key" -noout -modulus | openssl sha256
```

2 つのハッシュが一致すればペアとして正しい。

> `openssl pkey` には `-modulus` が無い（OpenSSL 3.5 で確認）。鍵側は `openssl rsa` を使う。

### 3. TLS ハンドシェイクが通るか（RDP パスワード不要）

**存在しないユーザー名**でループバック接続する。TLS が正常なら NLA 段階まで到達して `Could not find user in SAM database` が出る。TLS が壊れていればその手前の `BIO_do_handshake failed` で止まる。この違いだけで証明書の可否を切り分けられるため、**RDP のパスワードを知らなくても検証できる**。

```bash
timeout 20 xfreerdp /v:127.0.0.1:3389 /u:__probe__ /p:__probe__ /cert:ignore /auth-only >/dev/null 2>&1
sudo journalctl -u gnome-remote-desktop --since "-1min" --no-pager \
  | grep -E "SAM database|BIO_do_handshake"
```

### 4. クライアントに届く証明書を確認する

`/cert:ignore` を付けずに実行すると、実際に提示された証明書の詳細が表示される:

```bash
echo "n" | timeout 20 xfreerdp /v:<SERVER_IP>:3389 /u:__probe__ /p:__probe__ /auth-only 2>&1 \
  | grep -iE "Common Name|Subject:|Issuer:|Thumbprint|MISMATCH"
```

Thumbprint が `grdctl --system status` の TLS fingerprint と一致すること、`CERTIFICATE NAME MISMATCH` が出ないことを確認する。

## 証明書を差し替えたときのクライアント側の対応

自己署名証明書が変わると、クライアントは保存済みの旧証明書と照合して警告を出す。**クライアント側で保存された証明書の信頼を一度削除する**か、変更の警告を承認する必要がある。

## ロールバック

旧証明書を消さずに残しておけば、パスを戻して再起動するだけでよい。

```bash
CERTDIR=/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates
sudo grdctl --system rdp set-tls-key  "$CERTDIR/rdp-tls.key"
sudo grdctl --system rdp set-tls-cert "$CERTDIR/rdp-tls.crt"
sudo systemctl restart gnome-remote-desktop.service
```
