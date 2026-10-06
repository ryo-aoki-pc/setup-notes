# GNOME Remote Desktop 有効化手順（リモートログイン方式）の参考資料

[手順書](../gnome-remote-desktop.md)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- `LAN_SUBNET` は[接続元を LAN に絞る](../gnome-remote-desktop.md#接続元を-lan-に絞る任意)の rich rule でしか使わないので、手順 1 ではなくその節の冒頭で設定する
- 接続元を制限しない場合は、手順 5 で public ゾーンに `rdp` サービスを開放した状態が完成形
- `SERVER_IP` が空のまま進むと、手順 2 の `openssl` が SAN の空エントリで `invalid null value` のエラーになる

### 実施手順 / 手順 4: 補足: grdctl

- `disable` 後は `inactive`、`enable` 後は `active` になる
- このため、この時点でデーモンが起動し、**後から設定する資格情報は再起動するまで反映されない**（手順 6・7）

### 実施手順 / 手順 6: 補足: 資格情報

[この節の検証記録](../verification/gnome-remote-desktop.md#実施手順--手順-6-補足-資格情報)

### 実施手順 / 手順 8: 補足: サーバー側の状態

- `Unit status: active` なのに `Status: disabled` で 3389 が LISTEN していない場合は、後半の補足「注意点」の**設定レイヤーの食い違い**を疑う

### 実施手順 / 手順 9: 補足: 鍵と証明書

[この節の検証記録](../verification/gnome-remote-desktop.md#実施手順--手順-9-補足-鍵と証明書)

- `openssl pkey` には `-modulus` が無い。鍵側は `openssl rsa` を使う

### 実施手順 / 手順 10: 補足: TLS プローブと、FreeRDP クライアントでの確かめ方

[この節の検証記録](../verification/gnome-remote-desktop.md#実施手順--手順-10-補足-tls-プローブとfreerdp-クライアントでの確かめ方)

**TLS プローブ**

RDP の TLS は接続直後ではなく X.224 のネゴシエーション後に始まるため、`openssl s_client` では確認できない。

- 手順 10 の `rdp_tls_probe.py` は Python 標準ライブラリだけで書いてあり、X.224 のネゴシエーションを済ませてから TLS を張り、提示された証明書の fingerprint と SAN を表示する
- サーバーに FreeRDP クライアントが無くても使え、RDP のパスワードは不要

確認するポイント:

- `selectedProtocol=0x2`（HYBRID = NLA）でネゴシエーションが成立する
- TLS ハンドシェイクが完了し、**fingerprint が `grdctl --system status` の TLS fingerprint と完全一致**する
- SAN に接続に使う名前が DNS エントリとして含まれている

スクリプトは TLS 確立直後に切断するため、サーバー側には次のログが出るが正常（NLA の途中でクライアントが切断しただけ）:

```
[ERROR][com.freerdp.core.nla] - [nla_server_recv_stream]: nla_recv() error: -1
[ERROR][com.freerdp.core.transport] - [transport_accept_nla]: client authentication failure
[RDP] Network or intentional disconnect, stopping session
```

逆に、次が出る場合はプローブの前段で失敗している:

| ログ | 意味 |
|---|---|
| `[RDP] Credentials are not set, denying client` | 資格情報が未設定／未反映。ネゴシエーション前に切断される（スクリプトは `Connection reset by peer`） |
| `BIO_do_handshake failed` | TLS 失敗（証明書・鍵の不備） |
| `[x509_utils_from_pem]: BIO_new failed` | 証明書／鍵が PEM として読めない |

**FreeRDP クライアントがある場合の検証**

TLS の可否: **存在しないユーザー名**でループバック接続する。TLS が正常なら NLA 段階まで到達して `Could not find user in SAM database` が出る。TLS が壊れていればその手前の `BIO_do_handshake failed` で止まる。

```bash
timeout 20 xfreerdp /v:127.0.0.1:3389 /u:__probe__ /p:__probe__ /cert:ignore /auth-only >/dev/null 2>&1
sudo journalctl -u gnome-remote-desktop --since "-1min" --no-pager \
  | grep -E "SAM database|BIO_do_handshake"
```

クライアントに届く証明書: `/cert:ignore` を付けずに実行すると、実際に提示された証明書の詳細が表示される。Thumbprint が TLS fingerprint と一致し、`CERTIFICATE NAME MISMATCH` が出ないことを確認する。

```bash
echo "n" | timeout 20 xfreerdp /v:${SERVER_IP}:3389 /u:__probe__ /p:__probe__ /auth-only 2>&1 \
  | grep -iE "Common Name|Subject:|Issuer:|Thumbprint|MISMATCH"
```

### 実施手順 / 手順 11: 補足: クライアントからのログイン

1. システム共通パスワードで RDP 認証を通過
1. GDM ログイン画面が表示される
1. `<USER>` などの OS アカウントでログイン → そのユーザーのセッションが無ければ新規作成、既存のリモートセッションやヘッドレスのセッションがあればそこへ引き渡す（[注意点](../gnome-remote-desktop.md#注意点)）

問題があれば以下を並行して確認する:

```bash
journalctl -u gnome-remote-desktop -f
journalctl -u gdm -f
```

### 設定済みのサーバーで GDM の後に起動させる / 手順 2: 補足: すれ違ったときのログ

[この節の検証記録](../verification/gnome-remote-desktop.md#設定済みのサーバーで-gdm-の後に起動させる--手順-2-補足-すれ違ったときのログ)

- 今のデーモンのプロセス（MainPID）のログだけを数える。起動の後にデーモンを再起動していれば `0` になる

### 選択した方針

- **リモートログイン方式**（システムデーモン）— ローカルログイン不要。GDM で認証し、そのユーザーのセッションが無ければ新規作成する。切断後のリモートセッションや常駐するヘッドレスのセッションがあれば、そこへ引き渡す
- **TLS 証明書は openssl で生成する** — GNOME 本家の README が記載している方法
  - 追加パッケージ不要で、SAN の付与や有効期間の指定もできる
  - RHEL 10 のドキュメントは `freerdp` の `winpr-makecert` を使うが、GRD 側の要件ではない（[付録](#付録-winpr-makecert-で証明書を作る場合rhel-10-公式手順)参照）
- ファイアウォールは **public ゾーンで 3389/tcp を開放**
- 操作権限はフル操作（リモートログイン方式に `view-only` 設定は存在せず、常にフル操作）

#### 認証は 2 段構え

1. **システム共通の RDP 資格情報**（`grdctl --system rdp set-credentials`）— GDM ログイン画面へ到達するためのゲートウェイ認証。RDP クライアントの接続時に入力する。ユーザー名は OS アカウントと一致していなくてよい
1. **各ユーザーの OS 資格情報** — GDM のログイン画面で入力する

---

### 参照

- [Chapter 1. Remotely accessing the desktop — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/remotely-accessing-the-desktop)
- [GNOME/gnome-remote-desktop README.md](https://github.com/GNOME/gnome-remote-desktop/blob/master/README.md)

---

### 付録: winpr-makecert で証明書を作る場合（RHEL 10 公式手順）

[証明書生成時の表示の記録](../verification/gnome-remote-desktop.md#参考資料の証明書生成で確認した表示)

[この節の検証記録](../verification/gnome-remote-desktop.md#付録-winpr-makecert-で証明書を作る場合rhel-10-公式手順)

RHEL 10 のドキュメントは `freerdp` パッケージの `winpr-makecert` で証明書を作る手順を載せている。これは Red Hat のドキュメントがそのツールを採用しているだけで、GRD の要件ではない。**GNOME 本家の README は openssl による生成を正規の手順として記載しており、機能的にも openssl の方が上位**（SAN・有効期間を指定できる）。本書のメイン手順が openssl を使うのはこのため。

`winpr-makecert --help` では `-eku` や `-b`/`-e` が "Unsupported" と明記されており、SAN を付けるオプションは存在しない。

<a id="方式-1-ホストに-freerdp-をインストールする環境-1-で当初実施"></a>

#### 方式 1: ホストに freerdp をインストールする

```bash
sudo dnf install -y freerdp
```

[手順 1](../gnome-remote-desktop.md#実施手順) の変数を設定したうえで:

```bash
sudo -u gnome-remote-desktop mkdir -p /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates
sudo -u gnome-remote-desktop winpr-makecert -silent -rdp -path /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates rdp-tls
sudo chmod 600 /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/rdp-tls.key
sudo restorecon -Rv /var/lib/gnome-remote-desktop
```

以降はメイン手順 4〜7 と同じ。

#### 方式 2: podman コンテナで winpr-makecert を使う

ホストにパッケージを入れずに winpr-makecert 製の証明書が必要な場合。[手順 1](../gnome-remote-desktop.md#実施手順) の変数を設定したうえで:

```bash
OUT=$(mktemp -d)
podman run --rm --hostname "${SERVER_NAME}" -v "${OUT}:/out:Z" \
  docker.io/library/almalinux:10 \
  bash -c 'dnf install -y freerdp >/dev/null 2>&1 && winpr-makecert -silent -rdp -path /out rdp-tls'

sudo install -o gnome-remote-desktop -g gnome-remote-desktop -m 644 "${OUT}/rdp-tls.crt" /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/
sudo install -o gnome-remote-desktop -g gnome-remote-desktop -m 600 "${OUT}/rdp-tls.key" /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/certificates/
sudo restorecon -Rv /var/lib/gnome-remote-desktop
rm -rf "${OUT}"
```

- **`--hostname "${SERVER_NAME}"` は必須。** 渡さないとコンテナのランダム ID が CN になる
- **`-n "CN=..."` は使ってはいけない。** winpr-makecert の `-n` は解析が壊れており、subject が破損する。`--hostname` だけで正しい CN になるので `-n` は不要
- **`:Z`** は SELinux ラベル付け替え。rootless podman で必須
- rootless podman ではコンテナ内 root がホストの呼び出しユーザーにマップされるため、生成物は呼び出しユーザー所有になる。**ホストへ配置する際に `install -o` で所有者を付け直すこと**
- winpr-makecert が出力する鍵は **0644**（コンテナ内でもホスト側でも）。`install -m 600` で絞る手順を省略しないこと
- イメージ pull のダウンロードが発生する

IP で接続したときに名前不一致になるのは、SAN が無いことが原因。openssl 製の証明書では SAN を付けられる。
