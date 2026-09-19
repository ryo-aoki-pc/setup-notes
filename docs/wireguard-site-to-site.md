# WireGuard 拠点間 VPN 構築手順（site-to-site / wg-quick + firewalld）

- **目的**: 2 拠点の LAN を WireGuard で結び、**拠点 A の LAN 上のクライアントと拠点 B の LAN 上のクライアントが双方向に通信できる**ようにする
- **構成**: 各拠点で、既存ルーターの配下にある AlmaLinux 1 台を WireGuard ホストにする（ルーターの置き換えはしない）
- **設定方式**: `wg-quick` + systemd（`/etc/wireguard/wg0.conf` / `wg-quick@wg0.service`）、firewalld の policy で転送を制御
- **進め方**: **手順 0 で値を 1 度だけ書き、以降のコマンドブロックは編集せずにそのまま貼る。** 値はシェル変数に入れるので、**両拠点の WG ホストで同じコマンド列を実行できる**（拠点 A / B の読み替えは手順 0 が自動で行う）
- **状態**: 1 台のマシン上に network namespace で 2 拠点を模擬して動作確認済み（[付録](#付録-network-namespace-による模擬検証)）。**実際に 2 拠点をインターネット越しに結んでの確認はまだしていない**
- **スクリプト**: 同じ値（`site.env`）を読んで手順 1〜6 をまとめて実行する [`scripts/wireguard-site-to-site/`](../scripts/wireguard-site-to-site/) もある（[スクリプトでまとめて実行する場合](#スクリプトでまとめて実行する場合)）
- **拡張**: 外出先の PC・スマートフォンなど任意の台数のクライアントをこの VPN に追加する手順は [WireGuard リモートクライアント追加手順](wireguard-remote-clients.md)

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-16（初回）／ 2026-09-19（変数形の手順に書き換えて再検証） |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64 |
| カーネル | 6.12.96（`wireguard.ko` を同梱） |
| `wireguard-tools` | 1.0.20250521-1.el10（appstream） |
| firewalld | 2.4.3 |
| NetworkManager | 1.56.0 |
| SELinux | Enforcing |

> **注記**: 環境固有の値は**シェル変数**で書いてある。値は手順 0 で作る `site.env` 1 ファイルに集約し、コマンド側は編集しない。例は検証で使った値。
>
> | 変数 | 意味 | 例（検証時の値） |
> |---|---|---|
> | `${SITE_A_LAN}` / `${SITE_B_LAN}` | 各拠点の LAN サブネット（**重複不可**） | `192.168.110.0/24` / `192.168.120.0/24` |
> | `${ROUTER_A_LAN_IP}` / `${ROUTER_B_LAN_IP}` | 各拠点ルーターの LAN 側 IP | `192.168.110.1` / `192.168.120.1` |
> | `${WG_A_LAN_IP}` / `${WG_B_LAN_IP}` | 各 WireGuard ホストの LAN 側 IP（**固定にする**） | `192.168.110.2` / `192.168.120.2` |
> | `${SITE_A_PUBLIC}` / `${SITE_B_PUBLIC}` | 各拠点ルーターのグローバル IP または DDNS 名 | `198.51.100.1` / `198.51.100.2` |
> | `${WG_TUNNEL_NET}` | トンネル内のアドレス帯 | `10.99.0.0/30` |
> | `${WG_A_TUN_IP}` / `${WG_B_TUN_IP}` | 各 wg0 のアドレス | `10.99.0.1` / `10.99.0.2` |
> | `${WG_PORT}` | WireGuard の待ち受け UDP ポート | `51820` |
> | `${LAN_ZONE}` | WG ホストの LAN 側 NIC が属する firewalld ゾーン（空なら手順 0 が検出する） | `public` |
> | `${SITE_A_PUBKEY}` / `${SITE_B_PUBKEY}` | 各拠点の WireGuard 公開鍵 | （`wg pubkey` の出力） |
> | `${WG_IFACE}` / `${WG_FW_ZONE}` | インターフェース名 / `wg0` を入れる firewalld ゾーン名 | `wg0` / `wireguard` |
>
> これに加えて、手順 0 が**このホストから見た** `MY_*` / `PEER_*`（`${MY_LAN}`・`${PEER_LAN}` など）を組み立てる。手順 1〜7 のコマンドがこれを使うので、**両拠点で同じコマンドが通る**。
>
> 秘密鍵はこの文書に載せない。公開鍵は秘密情報ではないが、検証用に作った使い捨ての値なので載せていない。

---

## 構成

```
                 拠点 A                                                     拠点 B
 [Client A]                                                                          [Client B]
 ${SITE_A_LAN}.100 ─┐                                                           ┌─ ${SITE_B_LAN}.100
                    ├─ [Router A] ══ Internet (UDP ${WG_PORT}) ══ [Router B] ───┤
 [WG host A] ───────┘  ${SITE_A_PUBLIC}                       ${SITE_B_PUBLIC}  └────── [WG host B]
 ${WG_A_LAN_IP}                                                                    ${WG_B_LAN_IP}
   wg0 ${WG_A_TUN_IP}  ←────────── WireGuard トンネル ${WG_TUNNEL_NET} ──────────→  wg0 ${WG_B_TUN_IP}
```

### パケットの流れ（Client A → Client B）

1. Client A は宛先 `${SITE_B_LAN}` を知らないので、デフォルトゲートウェイの **Router A** に送る
2. Router A の**静的経路**（`${SITE_B_LAN}` via `${WG_A_LAN_IP}`）で **WG host A** に転送される
3. WG host A は `wg0` の経路（`AllowedIPs` から wg-quick が自動で追加する）で暗号化し、Router B のグローバル IP へ UDP で送る
4. Router B の**ポート転送**で WG host B に届き、復号されて LAN B の Client B へ
5. 戻りは逆順（Client B → Router B → WG host B → トンネル → WG host A → Client A）

したがって、各拠点で必要なのは次の 3 点。

| 場所 | 必要な設定 |
|---|---|
| WG ホスト | WireGuard（`AllowedIPs` に相手 LAN を含める）、IP フォワーディング、firewalld の転送許可 |
| 拠点ルーター | WAN → `${WG_x_LAN_IP}:${WG_PORT}/udp` の**ポート転送**、`相手 LAN` via `${WG_x_LAN_IP}` の**静的経路** |
| クライアント | 変更なし |

## 選択した方針

- **wg-quick + systemd** — 設定が 1 ファイルで完結し、情報も多い。NetworkManager は wg-quick が作った `wg0` を `connected (externally)` として扱うだけで干渉しなかった（実測）
- **値はシェル変数に集約し、両拠点で同じコマンドを実行する** — `site.env` は A/B 両拠点の値を並べて持つ。手順 0 が**このホストがどちらの拠点か**を LAN 側 IP から自動判定し、`MY_*` / `PEER_*` を組み立てる。拠点ごとに手順を書き分けないので、**A/B の取り違えが起きない**
- **秘密鍵は `wg0.conf` に直接書く** — `PostUp` で別ファイルから読み込む書き方もできるが、`systemctl reload` で**秘密鍵が消えてトンネルが止まる**ことを実測で確認した（[落とし穴 1](#落とし穴-1-秘密鍵を-conf-の外に出すと-reload-で消える)）
- **firewalld は wg0 専用ゾーン + policy** — `wg0` を `trusted` や `internal` に入れると、firewalld 2.4 に同梱の `gateway-lan-to-world` policy（`internal home trusted` → `external public` を ACCEPT）が効いてしまい、意図しない範囲まで転送が通る。専用ゾーンを作り、policy の rich rule で **`拠点 A LAN ⇔ 拠点 B LAN` の組み合わせだけ**を許可する
- **トンネル自体は NAT しない** — 送信元 IP がそのまま相手拠点に届くので、相手側でアクセス元を識別・制限できる
- **両拠点とも `Endpoint` と `PersistentKeepalive` を設定** — どちらからでもトンネルを張り直せる。片側がグローバル IP を持たない場合は[注意点](#片側がグローバル-ip-を持たない場合cgnat-など)を参照

---

## 実施前の状態（WG ホスト A として使ったマシン）

| 項目 | 状態 |
|---|---|
| `wireguard-tools` | 未インストール |
| `wireguard.ko` | 標準カーネルに同梱（`modinfo wireguard` で確認）。追加のカーネルモジュールは不要 |
| `net.ipv4.ip_forward` | `0` |
| `net.ipv4.conf.default.rp_filter` | `1`（新しく作られるインターフェースは strict） |
| firewalld | active、LAN 側 NIC は `public` ゾーン、ユーザー定義の policy なし |
| SELinux | Enforcing |

---
## 構築手順

**手順 0〜6 は両拠点の WG ホストで実施する。** 手順 0 で値を書いたあとは、**どちらの拠点でもまったく同じコマンドを貼る**（拠点 A / B の違いは手順 0 が変数に吸収する）。手順 7 は両拠点のルーターで行う。

| 手順 | 内容 | 実施場所 |
|---|---|---|
| 0 | 値を 1 度だけ書く（変数の定義） | 両拠点の WG ホスト |
| 1 | パッケージのインストール | 同上 |
| 2 | 鍵ペアの生成、公開鍵の交換 | 同上 |
| 3 | `wg0.conf` の作成 | 同上 |
| 4 | IP フォワーディングの有効化 | 同上 |
| 5 | firewalld の設定 | 同上 |
| 6 | サービスの有効化・起動 | 同上 |
| 7 | ポート転送と静的経路 | 両拠点のルーター |

### 0. 値を 1 度だけ書く（変数の定義）

**編集するのは `~/wg/site.env` だけ。** 以降の手順のコマンドは、この変数を参照するので書き換えない。

```bash
# (a) 値を書く。両拠点の WG ホストに同じ内容を置く
mkdir -p ~/wg && chmod 700 ~/wg
cp <このリポジトリ>/scripts/wireguard-site-to-site/site.env.example ~/wg/site.env
chmod 600 ~/wg/site.env
vi ~/wg/site.env                      # 上の変数表のとおりに埋める。公開鍵は手順 2 で書き足す
```

`site.env` は [`scripts/wireguard-site-to-site/site.env.example`](../scripts/wireguard-site-to-site/site.env.example) をそのまま使う。同じファイルをスクリプトも読むので、手動で進めても後からスクリプトに切り替えられる。WG ホストにリポジトリを置かない場合は、`site.env.example` の中身を貼って作ってもよい（変数名と値だけのファイルなので、上の変数表があれば書ける）。

```bash
# (b) このホスト視点の変数を組み立てる定義を置く（内容は両拠点で同一）
cat > ~/wg/wg-env.sh <<'EOF'
# ~/wg/site.env を読み、このホスト視点の変数（MY_* / PEER_*）を作る
set -a
. ~/wg/site.env

# このホストがどちらの拠点かを LAN 側 IP から判定する（A/B の取り違え防止）
host_has_ip() { ip -o -4 addr show | awk -v ip="$1" '$4 ~ "^"ip"/" {f=1} END {exit !f}'; }
if   host_has_ip "$WG_A_LAN_IP"; then MY_SITE=A
elif host_has_ip "$WG_B_LAN_IP"; then MY_SITE=B
else echo "WARN: WG_A_LAN_IP / WG_B_LAN_IP のどちらもこのホストに無い。MY_SITE を手で設定する" >&2
fi

if [ "$MY_SITE" = A ]; then
  PEER_SITE=B
  MY_LAN=$SITE_A_LAN;             PEER_LAN=$SITE_B_LAN
  MY_LAN_IP=$WG_A_LAN_IP;         PEER_LAN_IP=$WG_B_LAN_IP
  MY_TUN_IP=$WG_A_TUN_IP;         PEER_TUN_IP=$WG_B_TUN_IP
  MY_PUBLIC=$SITE_A_PUBLIC;       PEER_PUBLIC=$SITE_B_PUBLIC
  MY_PUBKEY=$SITE_A_PUBKEY;       PEER_PUBKEY=$SITE_B_PUBKEY
  MY_CLIENT_NET=$WG_A_CLIENT_NET; PEER_CLIENT_NET=$WG_B_CLIENT_NET
  MY_ROUTER_IP=$ROUTER_A_LAN_IP;  PEER_ROUTER_IP=$ROUTER_B_LAN_IP
else
  PEER_SITE=A
  MY_LAN=$SITE_B_LAN;             PEER_LAN=$SITE_A_LAN
  MY_LAN_IP=$WG_B_LAN_IP;         PEER_LAN_IP=$WG_A_LAN_IP
  MY_TUN_IP=$WG_B_TUN_IP;         PEER_TUN_IP=$WG_A_TUN_IP
  MY_PUBLIC=$SITE_B_PUBLIC;       PEER_PUBLIC=$SITE_A_PUBLIC
  MY_PUBKEY=$SITE_B_PUBKEY;       PEER_PUBKEY=$SITE_A_PUBKEY
  MY_CLIENT_NET=$WG_B_CLIENT_NET; PEER_CLIENT_NET=$WG_A_CLIENT_NET
  MY_ROUTER_IP=$ROUTER_B_LAN_IP;  PEER_ROUTER_IP=$ROUTER_A_LAN_IP
fi

WG_CONF=/etc/wireguard/$WG_IFACE.conf
WG_KEY=/etc/wireguard/$WG_IFACE.key
WG_PUB=/etc/wireguard/$WG_IFACE.pub
# 自拠点の公開鍵が site.env に無ければ鍵ファイルから読む（/etc/wireguard は 0700 なので sudo が要る）
[ -z "$MY_PUBKEY" ] && MY_PUBKEY=$(sudo cat "$WG_PUB" 2>/dev/null)

# 相手 peer の AllowedIPs。相手拠点のクライアント帯があれば自動で加わる
PEER_ALLOWED="$PEER_TUN_IP/32, $PEER_LAN"
[ -n "$PEER_CLIENT_NET" ] && PEER_ALLOWED="$PEER_ALLOWED, $PEER_CLIENT_NET"

# LAN 側 NIC とそのゾーン。ゾーン未割り当ての NIC では --get-zone-of-interface は
# "no zone" を stderr に出して 2 を返すので、文字列ではなく終了コードで判定する
MY_NIC=$(ip -o -4 addr show | awk -v ip="$MY_LAN_IP" '$4 ~ "^"ip"/" {print $2; exit}')
if [ -z "$LAN_ZONE" ]; then
  LAN_ZONE=$(sudo firewall-cmd --get-zone-of-interface="$MY_NIC" 2>/dev/null) ||
    LAN_ZONE=$(sudo firewall-cmd --get-default-zone)
fi

# policy 名（通信の向きで命名する。ゾーンの対応はホストごとに違う）
POL_OUT=site$MY_SITE-to-site$PEER_SITE           # 自拠点 LAN → 相手拠点 LAN
POL_IN=site$PEER_SITE-to-site$MY_SITE            # 相手拠点 LAN → 自拠点 LAN
POL_MYCL_IN=clients$MY_SITE-to-site$MY_SITE      # 自拠点のクライアント → 自拠点 LAN
POL_MYCL_OUT=site$MY_SITE-to-clients$MY_SITE     # 自拠点 LAN → 自拠点のクライアント
POL_MYCL_PEER=clients$MY_SITE-to-site$PEER_SITE  # 自拠点のクライアント → 相手拠点 LAN
POL_PEER_MYCL=site$PEER_SITE-to-clients$MY_SITE  # 相手拠点 LAN → 自拠点のクライアント
POL_PEERCL_IN=clients$PEER_SITE-to-site$MY_SITE  # 相手拠点のクライアント → 自拠点 LAN
POL_PEERCL_OUT=site$MY_SITE-to-clients$PEER_SITE # 自拠点 LAN → 相手拠点のクライアント
set +a
EOF
chmod 600 ~/wg/wg-env.sh
```

```bash
# (c) 読み込む。新しいシェルを開いたら、以降はこの 1 行だけでよい
. ~/wg/wg-env.sh
```

**何も変更する前に、組み立てられた値を読み戻して目で確かめる。**

```bash
for v in MY_SITE MY_NIC MY_LAN MY_LAN_IP MY_TUN_IP MY_PUBLIC \
         PEER_SITE PEER_LAN PEER_LAN_IP PEER_TUN_IP PEER_PUBLIC \
         PEER_ALLOWED WG_IFACE WG_PORT LAN_ZONE POL_OUT POL_IN; do
  printf '%-16s = %s\n' "$v" "${!v}"
done
```

```
MY_SITE          = A              ← 自動判定。拠点 B のホストでは B になる
MY_NIC           = end0
MY_LAN           = 192.168.110.0/24
MY_LAN_IP        = 192.168.110.2
MY_TUN_IP        = 10.99.0.1
MY_PUBLIC        = 198.51.100.1
PEER_SITE        = B
PEER_LAN         = 192.168.120.0/24
PEER_LAN_IP      = 192.168.120.2
PEER_TUN_IP      = 10.99.0.2
PEER_PUBLIC      = 198.51.100.2
PEER_ALLOWED     = 10.99.0.2/32, 192.168.120.0/24
WG_IFACE         = wg0
WG_PORT          = 51820
LAN_ZONE         = public
POL_OUT          = siteA-to-siteB
POL_IN           = siteB-to-siteA
```

> **`MY_SITE` が想定と違う、`MY_NIC` が空、`LAN_ZONE` が空のいずれかなら、ここで止めて `site.env` を直す。** ここが合っていれば、以降のコマンドは編集不要で通る。`LAN_ZONE` は `site.env` に直接書いてもよい（書いてあれば検出しない）。

### 1. パッケージのインストール

```bash
sudo dnf install -y wireguard-tools
```

`wireguard-tools` の依存関係として `systemd-resolved` も一緒に入る（`wg-quick` は `DNS =` を設定したときに `resolvconf` コマンドを使い、EL10 ではそれを `systemd-resolved` が提供する）。本書の構成では `DNS =` を使わない。**インストールされるだけで、無効（disabled / inactive）のままなので `/etc/resolv.conf` は変わらない**（実測）。

```
Installed:
  systemd-resolved-257-23.el10_2.2.alma.1.aarch64
  wireguard-tools-1.0.20250521-1.el10.aarch64
```

### 2. 鍵ペアの生成

```bash
sudo bash -c "umask 077; wg genkey | tee $WG_KEY | wg pubkey > $WG_PUB"
sudo cat "$WG_PUB"                    # この公開鍵を相手拠点に渡す
```

> **`sudo bash -c` は二重引用符で書く。** 単一引用符にすると `$WG_KEY` が展開されず、`/etc/wireguard/$WG_IFACE.key` という名前のファイルができてしまう。

- `/etc/wireguard` はパッケージが `0700` で作る。`umask 077` で鍵ファイルも `0600` になる。**ディレクトリが `0700` なので、公開鍵を読むのにも `sudo` が要る**
- 相手に渡すのは **`wg0.pub`（公開鍵）だけ**。`wg0.key` は拠点の外に出さない

両拠点で鍵を作ったら、**それぞれの公開鍵を `site.env` に書き、両拠点の `site.env` を同じ内容にそろえる。**

```bash
vi ~/wg/site.env                      # SITE_A_PUBKEY と SITE_B_PUBKEY を埋める
. ~/wg/wg-env.sh                      # 書き換えたら読み直す
printf '%-12s = %s\n' MY_PUBKEY "$MY_PUBKEY" PEER_PUBKEY "$PEER_PUBKEY"
```

自拠点の分を `site.env` に書き忘れても、`wg-env.sh` が `$WG_PUB` から読む。**相手拠点の公開鍵は必須**（空のまま進むと peer が成立しない）。

### 3. `wg0.conf` の作成

**拠点 A / B で同じブロックを貼る。** 中身は手順 0 の変数で決まる。

```bash
sudo install -m 600 /dev/null "$WG_CONF"
cat <<EOF | sudo tee "$WG_CONF" >/dev/null
[Interface]
Address = ${MY_TUN_IP}/30
ListenPort = ${WG_PORT}
PrivateKey = $(sudo cat "$WG_KEY")

[Peer]
# Site ${PEER_SITE}
PublicKey = ${PEER_PUBKEY}
Endpoint = ${PEER_PUBLIC}:${WG_PORT}
AllowedIPs = ${PEER_ALLOWED}
PersistentKeepalive = ${WG_KEEPALIVE}
EOF
sudo grep -v '^PrivateKey' "$WG_CONF"   # 秘密鍵以外を目視確認
```

```
[Interface]
Address = 10.99.0.1/30
ListenPort = 51820

[Peer]
# Site B
PublicKey = fKLlTz2eSaaxzzY9HPml9qwTNQCp44EClUxtAUNoemY=
Endpoint = 198.51.100.2:51820
AllowedIPs = 10.99.0.2/32, 192.168.120.0/24
PersistentKeepalive = 25
```

- **ヒアドキュメントの区切り語 `EOF` は引用しない。** `<<'EOF'` と書くと変数が展開されず、`${MY_TUN_IP}` がそのまま conf に入る
- 秘密鍵は `$(sudo cat "$WG_KEY")` をシェルが展開して書き込むので、**画面には出ない**
- `install -m 600 /dev/null` で先に `0600` のファイルを作る。`tee` は中身を入れ替えるだけなのでパーミッションは保たれる
- `PEER_ALLOWED` は手順 0 が組み立てる。相手拠点のクライアント帯（[リモートクライアント追加手順](wireguard-remote-clients.md)）を `site.env` に書けば、ここに自動で入る
- `Endpoint` を書かない構成（CGNAT など）、`MTU`、`PersistentKeepalive` を書かない場合は[注意点](#片側がグローバル-ip-を持たない場合cgnat-など)を参照

### 4. IP フォワーディングの有効化

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/90-wireguard.conf
sudo sysctl --system
sysctl net.ipv4.ip_forward            # = 1
```

`rp_filter` は変更不要（strict = 1 のまま動いた。相手 LAN への経路が `wg0` を向いているので、`wg0` から届く相手 LAN 発のパケットは逆経路チェックを通る）。

**両拠点で実施する。** 片方だけ有効にすると、ハンドシェイクは成立するのにクライアント同士が通らない（検証中に実際に踏んだ）。

### 5. firewalld の設定

```bash
# (a) WireGuard の待ち受けポートを LAN 側ゾーンで開ける
sudo firewall-cmd --permanent --zone="$LAN_ZONE" --add-port="$WG_PORT/udp"

# (b) wg0 専用ゾーン
sudo firewall-cmd --permanent --new-zone="$WG_FW_ZONE"
sudo firewall-cmd --permanent --zone="$WG_FW_ZONE" --add-interface="$WG_IFACE"

# (c) 自拠点 LAN → 相手拠点 LAN
sudo firewall-cmd --permanent --new-policy="$POL_OUT"
sudo firewall-cmd --permanent --policy="$POL_OUT" --add-ingress-zone="$LAN_ZONE"
sudo firewall-cmd --permanent --policy="$POL_OUT" --add-egress-zone="$WG_FW_ZONE"
sudo firewall-cmd --permanent --policy="$POL_OUT" \
  --add-rich-rule="rule family=ipv4 source address=$MY_LAN destination address=$PEER_LAN accept"

# (d) 相手拠点 LAN → 自拠点 LAN
sudo firewall-cmd --permanent --new-policy="$POL_IN"
sudo firewall-cmd --permanent --policy="$POL_IN" --add-ingress-zone="$WG_FW_ZONE"
sudo firewall-cmd --permanent --policy="$POL_IN" --add-egress-zone="$LAN_ZONE"
sudo firewall-cmd --permanent --policy="$POL_IN" \
  --add-rich-rule="rule family=ipv4 source address=$PEER_LAN destination address=$MY_LAN accept"

sudo firewall-cmd --reload
```

> **rich rule は二重引用符で書く。** 解説記事では `--add-rich-rule='rule family=ipv4 ...'` と単一引用符で書かれていることが多いが、**単一引用符だと変数が展開されず、`$MY_LAN` という文字列がそのまま rich rule に登録される**。firewalld はそれを受理してしまい、`--list-all-policies` を見るまで気づかない（[落とし穴 3](#落とし穴-3-rich-rule-を単一引用符で書くと変数が展開されない)）。

展開された結果は `set -x` で確認できる（実測）。

```
$ sudo firewall-cmd --permanent --policy=siteA-to-siteB --add-rich-rule="rule family=ipv4 source address=$MY_LAN destination address=$PEER_LAN accept"
++ sudo firewall-cmd --permanent --policy=siteA-to-siteB '--add-rich-rule=rule family=ipv4 source address=192.168.110.0/24 destination address=192.168.120.0/24 accept'
success
```

- policy 名（`siteA-to-siteB` など）は手順 0 が組み立てる。**通信の向きで命名してあるので両拠点で同じ名前**になり、ingress / egress ゾーンの対応だけがホストごとに変わる
- `wg0` はまだ存在しなくても `--add-interface` できる。wg-quick が `wg0` を作り直しても（`systemctl restart` 後も、`--complete-reload` 後も）`wireguard` ゾーンに入ったままだった（実測）
- 片方向だけ許可したい場合（例: 拠点 A から B へは接続できるが、B から A へは接続させない）は (d) を作らない。戻りのパケットは conntrack で許可されるので、A から始めた通信は成立する
- 相手 LAN のうち特定ホスト・ポートだけに絞る場合は、rich rule の `destination address` を `/32` にする、`port port=... protocol=tcp` を付けるなどで調整する

**(a) はトンネルを相手側から張るときに必要。** 自拠点側から張ったトンネルなら (a) が無くても（conntrack により戻りの UDP として）通ってしまうため、開け忘れに気づきにくい。相手側から張り直すときに初めて失敗する（[付録の実測](#待ち受けポートを開け忘れた場合)）。

### 6. サービスの有効化・起動

```bash
sudo systemctl enable --now "wg-quick@$WG_IFACE"
sudo journalctl -u "wg-quick@$WG_IFACE" --no-pager | tail -8
```

```
systemd[1]: Starting wg-quick@wg0.service - WireGuard via wg-quick(8) for wg0...
wg-quick[13990]: [#] ip link add dev wg0 type wireguard
wg-quick[13990]: [#] wg setconf wg0 /dev/fd/63
wg-quick[13990]: [#] ip -4 address add 10.99.0.1/30 dev wg0
wg-quick[13990]: [#] ip link set mtu 1420 up dev wg0
wg-quick[13990]: [#] ip -4 route add 192.168.120.0/24 dev wg0      ← AllowedIPs の相手 LAN
systemd[1]: Finished wg-quick@wg0.service - WireGuard via wg-quick(8) for wg0.
```

SELinux (Enforcing) で AVC 拒否は出なかった（`ausearch -m avc` で確認）。

### 7. 拠点ルーターの設定

機種ごとに画面は違うので、要件だけを書く。**両拠点のルーターで実施する。** 入力する値は次で印字できる。

```bash
cat <<EOF
ポート転送 : WAN（${MY_PUBLIC}）の ${WG_PORT}/udp → ${MY_LAN_IP}:${WG_PORT}
静的経路   : 宛先 ${PEER_LAN} → ゲートウェイ ${MY_LAN_IP}
DHCP 予約  : ${MY_LAN_IP} をこの WG ホストに固定
（ルーターの LAN 側 IP: ${MY_ROUTER_IP}）
EOF
```

| 設定 | 拠点 A のルーター | 拠点 B のルーター |
|---|---|---|
| ポート転送（静的 NAT / NAPT） | WAN `${WG_PORT}/udp` → `${WG_A_LAN_IP}:${WG_PORT}` | WAN `${WG_PORT}/udp` → `${WG_B_LAN_IP}:${WG_PORT}` |
| 静的経路 | 宛先 `${SITE_B_LAN}` → ゲートウェイ `${WG_A_LAN_IP}` | 宛先 `${SITE_A_LAN}` → ゲートウェイ `${WG_B_LAN_IP}` |
| DHCP | `${WG_A_LAN_IP}` を固定（予約）する | `${WG_B_LAN_IP}` を固定（予約）する |

WG ホスト自身のデフォルトゲートウェイは拠点ルーターのままでよい。ルーターに静的経路を入れられない場合と、折り返し（ヘアピン）の注意は[注意点](#ルーターの静的経路とヘアピン非対称経路)を参照。

### スクリプトでまとめて実行する場合

手順 1〜6 は [`scripts/wireguard-site-to-site/wg-s2s.sh`](../scripts/wireguard-site-to-site/wg-s2s.sh) でまとめて実行できる。**手順 0 で作った `~/wg/site.env` をそのまま読む**ので、途中からスクリプトに切り替えてもよい。

```bash
cd scripts/wireguard-site-to-site

# 新しく conf を作る場合
sudo ./wg-s2s.sh -e ~/wg/site.env keygen A              # 手順 1〜2。表示された公開鍵を site.env に書く
sudo ./wg-s2s.sh -e ~/wg/site.env --dry-run apply A     # 実行予定の内容を確認（秘密鍵は (hidden) と表示）
sudo ./wg-s2s.sh -e ~/wg/site.env apply A               # 手順 3〜6 + ルーターに入れる値を表示

# 既存の wg0.conf を使う場合（conf は書き換えない。公開鍵の変数と keygen は不要）
sudo ./wg-s2s.sh -e ~/wg/site.env --use-existing-conf apply A

./wg-s2s.sh -e ~/wg/site.env router A                   # 手順 7 の値だけを表示
sudo ./wg-s2s.sh -e ~/wg/site.env status
sudo ./wg-s2s.sh -e ~/wg/site.env remove A              # ロールバック（--purge で conf と鍵も削除）
```

`apply` の動作:

- **何かを変更する前に、次を検査する。** 1 つでも失敗したら何も変更せずに止まる
  - アドレスの形式、LAN・トンネル網の重複、公開鍵の形式
  - `WG_x_LAN_IP` がこのホストにあるか（A/B の取り違えを防ぐ。手順 0 の `MY_SITE` 判定と同じ考え方）
- **conf を生成する場合**: `PrivateKey` を直接書く（[落とし穴 1](#落とし穴-1-秘密鍵を-conf-の外に出すと-reload-で消える)）。既存の conf と内容が違えば、`.bak-日時` に退避してから書く
- **既存の conf を使う場合**: `Address` に `WG_x_TUN_IP` が無い、または相手 LAN を `AllowedIPs` に含む `[Peer]` が無ければ**停止**。`ListenPort` の不一致、`PostUp` での秘密鍵読み込み、パーミッションは**警告**
- **firewalld**: 設定が既にあるかを確かめてから追加するので、再実行しても設定が重複しない
- **サービス**: 最後は常に `systemctl restart` する（[落とし穴 2](#落とし穴-2-reload-では経路が追加されない)）
- **LAN_ZONE**: 空なら `WG_x_LAN_IP` を持つ NIC のゾーンを自動で使う（手順 0 と同じ）
- **CGNAT 構成**: `SITE_x_PUBLIC` を空にすると、その拠点に向けた `Endpoint` を書かない

手動手順とスクリプトが同じ conf を作ることは、検証で `diff` して確認した（[付録](#変数形コマンドの再検証2026-09-19)）。スクリプトの検証範囲は[付録](#スクリプトの検証ドライランのみ)を参照。

---
## 完了時点の状態（拠点 A）

```
$ sudo wg show
interface: wg0
  public key: ${SITE_A_PUBKEY}
  private key: (hidden)
  listening port: 51820

peer: ${SITE_B_PUBKEY}
  endpoint: 198.51.100.2:51820
  allowed ips: 10.99.0.2/32, 192.168.120.0/24
  latest handshake: 33 seconds ago
  transfer: 3.37 KiB received, 127.88 KiB sent
  persistent keepalive: every 25 seconds

$ ip route show dev wg0
10.99.0.0/30 proto kernel scope link src 10.99.0.1
192.168.120.0/24 scope link

$ sudo firewall-cmd --get-active-zones
public (default)
  interfaces: end0
wireguard
  interfaces: wg0

$ sudo firewall-cmd --info-policy=siteA-to-siteB
siteA-to-siteB (active)
  disable: no
  priority: -1
  target: CONTINUE
  ingress-zones: public
  egress-zones: wireguard
  ...
  rich rules:
	rule family="ipv4" source address="192.168.110.0/24" destination address="192.168.120.0/24" accept

$ systemctl is-enabled wg-quick@wg0
enabled
$ nmcli -f DEVICE,TYPE,STATE dev | grep wg0
wg0      wireguard  connected (externally)
```

---

## 検証方法

### WG ホストで確認する

```bash
. ~/wg/wg-env.sh                                  # 新しいシェルならまずこれ
sudo wg show                                      # latest handshake が 2 分以内、transfer が増えている
ip route show dev "$WG_IFACE"                     # 相手 LAN への経路がある
sysctl net.ipv4.ip_forward                        # = 1
sudo firewall-cmd --get-active-zones              # wg0 が wireguard ゾーン
sudo firewall-cmd --info-policy="$POL_OUT"        # rich rule に実際の IP が入っている（$ が残っていない）
```

`latest handshake` が表示されない場合は、トンネルが張れていない。調べる順番は次のとおり:

1. 相手の公開鍵・`Endpoint` の書き間違い（`site.env` の `SITE_x_PUBKEY` を両拠点でそろえたか）
2. 相手ルーターのポート転送
3. 相手 WG ホストの firewalld の `${WG_PORT}/udp`

### クライアント同士で確認する

Client A から:

```bash
ping <Client B の IP>
tracepath -n <Client B の IP>
```

```
$ tracepath -n 192.168.120.100
 1?: [LOCALHOST]                      pmtu 1500
 1:  192.168.110.2                                         0.088ms       ← WG host A
 1:  192.168.110.2                                         0.018ms
 2:  192.168.110.2                                         0.018ms pmtu 1420
 2:  10.99.0.2                                             0.227ms       ← トンネル越しの WG host B
 3:  192.168.120.100                                       0.145ms reached
     Resume: pmtu 1420 hops 3 back 3
```

- 経路に**相手のトンネル IP**（`${WG_B_TUN_IP}`）が出ればトンネル経由で届いている
- `pmtu 1420` は wg0 の MTU
- 1 ホップ目が `${ROUTER_A_LAN_IP}` で、2 ホップ目に `asymm` と出るのは、Redirect を受け入れないクライアント（[ヘアピン](#ルーターの静的経路とヘアピン非対称経路)参照）

**逆方向（Client B → Client A）も必ず確認する。** 片側の firewalld policy やルーターの静的経路が抜けていると、片方向だけ失敗する。TCP も確認しておくとよい（例: 片側で `python3 -m http.server 8080`、もう片側から `curl http://<IP>:8080/`。検証では `HTTP 200` を確認した）。

### 症状と原因の対応（実測）

| 症状 | 原因 |
|---|---|
| クライアントの ping に `From ${WG_A_LAN_IP} ... Packet filtered` | WG ホストの firewalld が転送を拒否している（policy 未設定、rich rule のサブネット誤り） |
| `wg show` の handshake は成立しているのに、クライアントの ping が無応答 | 相手側の firewalld policy、相手ルーターの静的経路、**相手の `ip_forward`** のいずれか。手順 4 を両拠点で実施したか確認する |
| WG ホスト自身から相手 LAN へ ping できないのに、クライアント同士は通る | 下記「[WG ホスト自身から相手 LAN へ送る場合](#wg-ホスト自身から相手-lan-へ送る場合)」 |
| クライアントから相手の**トンネル IP** へ ping すると `Destination Net Unreachable`（送信元は自拠点ルーター） | ルーターに `${WG_TUNNEL_NET}` の経路が無いため。クライアント同士の通信には不要 |
| 自拠点から張ったトンネルは動くのに、相手側から張ろうとすると失敗する | 自拠点の firewalld で `${WG_PORT}/udp` を開け忘れている、またはルーターのポート転送が無い |
| `--info-policy` の rich rule に `$MY_LAN` のような文字列が入っている | rich rule を単一引用符で書いた（[落とし穴 3](#落とし穴-3-rich-rule-を単一引用符で書くと変数が展開されない)） |
| コマンドが `--add-port=/udp` のように空の値で失敗する | `. ~/wg/wg-env.sh` を実行していないシェルでコマンドを貼った（[新しいシェルでは](#新しいシェルでは--wgwg-envsh-を先に実行する)） |

---

## 注意点

### 落とし穴 1: 秘密鍵を conf の外に出すと reload で消える

`wg0.conf` に秘密鍵を書かず、次のように別ファイルから読む書き方がよく紹介されている。

```ini
[Interface]
PostUp = wg set %i private-key /etc/wireguard/%i.key
```

`wg-quick up`（`systemctl start`）では動く。しかし `wg-quick@.service` の reload は次のとおり:

```
ExecReload=/bin/bash -c 'exec /usr/bin/wg syncconf %i <(exec /usr/bin/wg-quick strip %i)'
```

`wg-quick strip` の出力には `PrivateKey` が無い（`PostUp` は wg-quick だけが解釈する設定で、`wg` には渡らない）ため、**`systemctl reload wg-quick@wg0` や `wg syncconf` を実行すると秘密鍵が消え、トンネルが止まる**:

```
$ sudo systemctl reload wg-quick@wg0
$ sudo wg show wg0 public-key
(none)
$ sudo ip netns exec clientA ping -c2 -W1 192.168.120.100
2 packets transmitted, 0 received, 100% packet loss
```

このため本書では `PrivateKey` を `wg0.conf`（0600）に直接書く。そうすれば reload しても鍵は残る。

### 落とし穴 2: reload では経路が追加されない

`systemctl reload wg-quick@wg0` は WireGuard の設定（peer・AllowedIPs など）だけを差し替え、**`ip route` は変更しない**。`AllowedIPs` に範囲を追加して reload すると、`wg show` には新しい範囲が出るが、経路が無いのでその範囲宛てのパケットはトンネルに入らない（実測）:

```
$ sudo wg show wg0 allowed-ips
${SITE_B_PUBKEY}	10.99.0.2/32 192.168.120.0/24
J8lRu+zhFHN/C0gjsq5H0EcwlNsnnjtScnAT2AnEQww=	10.99.1.1/32
Kvt1c+GPXjQk07QMLFyGOpe8GnttKFHBZl4J6jRU2ms=	10.99.1.2/32
$ ip route show dev wg0
10.99.0.0/30 proto kernel scope link src 10.99.0.1
10.99.1.1 scope link
192.168.120.0/24 scope link                         ← 10.99.1.2 が無い
```

`systemctl restart wg-quick@wg0` すると入る:

```
$ ip route show dev wg0
10.99.0.0/30 proto kernel scope link src 10.99.0.1
10.99.1.1 scope link
10.99.1.2 scope link
192.168.120.0/24 scope link
```

`AllowedIPs`・`Address` を変えたときは **`systemctl restart wg-quick@wg0`** を使う（一瞬トンネルが切れる）。reload で済むのは、鍵・Endpoint・keepalive だけを変えたときに限られる。

### 落とし穴 3: rich rule を単一引用符で書くと変数が展開されない

firewalld の解説では `--add-rich-rule='rule family=ipv4 ...'` と**単一引用符**で書かれていることが多い。rich rule には空白が含まれるので引用は必要だが、**単一引用符の中ではシェル変数が展開されない**。本書のように値を変数で持つ場合は、必ず**二重引用符**にする。

```bash
# 誤り: $MY_LAN という文字列がそのまま登録される
sudo firewall-cmd --permanent --policy="$POL_OUT" \
  --add-rich-rule='rule family=ipv4 source address=$MY_LAN destination address=$PEER_LAN accept'

# 正しい
sudo firewall-cmd --permanent --policy="$POL_OUT" \
  --add-rich-rule="rule family=ipv4 source address=$MY_LAN destination address=$PEER_LAN accept"
```

厄介なのは、**firewalld が誤ったほうも `success` で受理する**こと。転送が通らないのに `firewall-cmd` はエラーを出さないので、`--info-policy` か `--list-all-policies` で中身を見るまで気づかない。貼る前に確認したい場合は `set -x` を有効にして、展開後のコマンドを見る。

### `AllowedIPs` が site-to-site の要

`AllowedIPs` は次の 2 つの役割を持つ。

- **受信時**: トンネルから届いたパケットの送信元がこの範囲外なら捨てる
- **送信時**: この範囲宛てのパケットをこの peer に送る。**wg-quick はこの範囲をそのまま `wg0` への経路としても追加する**

そのため、相手の**トンネル IP だけでなく相手の LAN も**書く。本書では手順 0 の `PEER_ALLOWED` がこれを組み立てる。wg-quick 起動時のログで経路が追加されるのを確認できる（[手順 6](#6-サービスの有効化起動) の出力）。

> `0.0.0.0/0` を書くと、WG ホスト自身の通信も含めてすべてがトンネルに向かう（wg-quick が policy routing で差し替える）。拠点間接続では相手 LAN だけを書く。

### ルーターの静的経路とヘアピン（非対称経路）

この構成では、Client A の最初のパケットは Router A に行き、**同じ LAN 側インターフェースへ折り返して**（ヘアピン）WG host A に届く。このとき:

- Linux ルーター（検証時の Router A）は **ICMP Redirect** を返し、それを受け入れたクライアントは以降 WG host A に直接送る（`ip route get` に `<redirected>` と出る）
- Redirect を受け入れないクライアントでは、毎回 Router A 経由のままになる
- いずれの場合も戻りのパケットは WG host A から Client A へ直接届くため、**Router A から見ると片方向しか通らない非対称経路**になる

検証では、Redirect を受け入れる場合・拒否する場合（`accept_redirects=0`）の両方で双方向 ping・TCP が通った。ただし **Router A には NAT やファイアウォールの状態追跡を持たせていない**。市販ルーターや UTM のなかには、LAN 内で折り返す転送を拒否するもの、戻りが見えない TCP セッションを途中で切るものがある。つながらない、あるいは TCP だけが不安定な場合は、ルーター側で折り返し転送を許可する設定を探すか、次の代替策をとる。

- **(a) クライアントに経路を追加する** — 通信するクライアントにだけ `${SITE_B_LAN} via ${WG_A_LAN_IP}` を入れる。ルーターを通らないので非対称経路も起きない。台数が多いと管理が大変になる（DHCP option 121 を配布できるルーターなら一括で配れる）
- **(b) WG ホストで NAT する（masquerade）** — 相手拠点から届いた通信の送信元を WG ホストの IP に書き換えれば、戻りは WG ホスト宛てになるので、自拠点ルーターの静的経路は不要になる。ただし **(1) 送信元のクライアントが相手からは区別できなくなり、(2) NAT した側への着信はできない**（片方向になる）。双方向に通信するという今回の要件は満たせないので、**最後の手段**としてだけ使う。本書では未検証

### WG ホスト自身から相手 LAN へ送る場合

WG ホスト自身が送るパケットは、`wg0` の経路により**送信元がトンネル IP（`${WG_A_TUN_IP}`）になる**。相手拠点のクライアントは `${WG_TUNNEL_NET}` への経路を持たないので、返事をデフォルトゲートウェイの Router B に送り、そこで行き場を失う。

```
$ ip route get 192.168.120.100
192.168.120.100 dev wg0 src 10.99.0.1 uid 1000
$ ping -c1 -W2 192.168.120.100
1 packets transmitted, 0 received, 100% packet loss
$ ping -c1 -W2 -I 192.168.110.2 192.168.120.100      ← 送信元を LAN 側 IP にすると通る
1 packets transmitted, 1 received, 0% packet loss
```

**クライアント同士の通信には影響しない。** WG ホスト自身からも相手 LAN を使いたい場合は、次のどちらかにする。

- 相手ルーターに `${WG_TUNNEL_NET}` via `${WG_x_LAN_IP}` の静的経路も追加する（検証で通ることを確認した）
- 送信元を LAN 側 IP にする（`ping -I`、アプリ側での bind など）

### 片側がグローバル IP を持たない場合（CGNAT など）

着信を受けられない側（例: 拠点 A）が常にトンネルを張りに行く構成にする。`site.env` では、着信を受けられない拠点の `SITE_x_PUBLIC` を空にする。

| | 着信を受けられない側（A） | グローバル IP がある側（B） |
|---|---|---|
| `[Peer]` の `Endpoint` | **必須**（`${SITE_B_PUBLIC}:${WG_PORT}`） | 省略する |
| `PersistentKeepalive` | **必須**（NAT のマッピングを維持するため） | 不要 |
| ルーターのポート転送 | 不要 | **必須** |
| firewalld の `${WG_PORT}/udp` | 不要 | **必須** |

手順 3 のヒアドキュメントは `Endpoint` 行を必ず書くので、`PEER_PUBLIC` が空の側では**その行を消してから貼る**（あるいはスクリプトを使う。`SITE_x_PUBLIC` が空なら `Endpoint` を書かない）。

WireGuard は、正しく認証できたパケットの送信元を peer の endpoint として覚える。そのため、`Endpoint` を書いていない側もハンドシェイクを受けた後は返信先がわかる。付録の検証では、`Endpoint` を持たない側の `wg show` に、相手の endpoint が表示された（[付録](#待ち受けポートを開け忘れた場合)）。ただし、**着信を受けた側から先に通信を始めることはできない**。A の keepalive でトンネルが維持されている間だけ、B 側のクライアントから A 側へ接続できる。**両側とも `Endpoint` を省略すると、どちらからもトンネルを張れない。**

### Endpoint に DDNS 名を書く場合

`Endpoint` のホスト名は **`wg-quick up` の時点で一度だけ名前解決される**（`wg(8)` の仕様）。相手のグローバル IP が変わると、再起動するまで古い IP に送り続ける。対策:

- `wireguard-tools` 同梱の `/usr/share/doc/wireguard-tools/contrib/reresolve-dns/reresolve-dns.sh` を systemd timer で定期実行する
- 片側だけでも固定 IP にし、そちらを常に接続を受ける側にする（上記の CGNAT 構成と同じ形）。動的 IP の側が張りに行くので、その側の IP が変わっても、固定 IP の側は新しい送信元を endpoint として覚え直す

本書では未検証。

### MTU

wg-quick は wg0 の MTU を既定で **1420** にする（IPv4/IPv6 の外側ヘッダー分を引いた値）。PPPoE（MTU 1454 / 1492 など）の回線では、トンネル内の最大サイズの通信だけが通らないことがある（ping は通るが、大きなファイル転送や一部の HTTPS が止まる）。その場合は `site.env` の `WG_MTU` に `1380` などと書き、手順 3 のヒアドキュメントの `[Interface]` に `MTU = ${WG_MTU}` の行を足してから貼り直し、`systemctl restart wg-quick@wg0` する。本書の検証環境（MTU 1500 の veth）ではこの問題は起きていない。

### LAN サブネットの重複

両拠点の LAN が同じサブネット（例: どちらも `192.168.1.0/24`）だと経路を区別できないので、この構成は成立しない。家庭用ルーターの初期値のままの拠点同士を結ぶ場合は、どちらかの LAN のアドレスを変える必要がある。

### 新しいシェルでは `. ~/wg/wg-env.sh` を先に実行する

本書のコマンドは手順 0 で作った変数に依存する。**読み込んでいないシェルで貼ると、変数が空のまま実行される。** 空の値でも firewalld がエラーを返すとは限らず、`--add-port=/udp` のように失敗するものもあれば、意図しない設定が入るものもある。SSH を張り直したあと、別の端末を開いたあと、再起動後は必ず次を実行する。

```bash
. ~/wg/wg-env.sh
echo "$MY_SITE $MY_LAN $PEER_LAN $LAN_ZONE"    # 空でないことを確かめる
```

`~/.bashrc` に書いてしまう手もあるが、`wg-env.sh` は `sudo firewall-cmd` を呼ぶので、ログインのたびに sudo が走る。手順の前に手で読み込むほうがよい。

### 再起動後の自動起動

`systemctl enable` 済みなので OS 起動時に `wg-quick@wg0` が上がる。検証は namespace を使っていたため、**実際の OS 再起動での確認はしていない**（`systemctl restart` と `firewall-cmd --complete-reload` の後に、ゾーン割り当て・経路・疎通が戻ることは確認済み）。

---

## ロールバック

各拠点の WG ホストで:

```bash
. ~/wg/wg-env.sh

sudo systemctl disable --now "wg-quick@$WG_IFACE"
sudo rm -f "$WG_CONF" "$WG_KEY" "$WG_PUB"

# policy はゾーンより先に消す（順序が逆だと下記の INVALID_ZONE になる）
for p in "$POL_OUT" "$POL_IN" "$POL_MYCL_IN" "$POL_MYCL_OUT" "$POL_MYCL_PEER" \
         "$POL_PEER_MYCL" "$POL_PEERCL_IN" "$POL_PEERCL_OUT"; do
  sudo firewall-cmd --permanent --info-policy="$p" >/dev/null 2>&1 &&
    sudo firewall-cmd --permanent --delete-policy="$p"
done
sudo firewall-cmd --permanent --delete-zone="$WG_FW_ZONE"
sudo firewall-cmd --permanent --zone="$LAN_ZONE" --remove-port="$WG_PORT/udp"
sudo firewall-cmd --reload

sudo rm -f /etc/sysctl.d/90-wireguard.conf
sudo sysctl -w net.ipv4.ip_forward=0

rm -rf ~/wg                                        # site.env と wg-env.sh
sudo dnf remove wireguard-tools systemd-resolved   # 不要なら
```

- **policy を消す前にゾーンを消すと firewalld が壊れる。** `wireguard` ゾーンを先に削除すると、そのゾーンを参照している policy が残るため、`--reload` が `Error: INVALID_ZONE: Policy 'clientsA-to-siteA': 'wireguard' not among existing zones` で失敗する（実測）。上のループのように policy を先に消す
- **policy の存在確認に `--query-policy` は使えない。** firewalld 2.4.3 にそのオプションは無く、`unrecognized arguments` で終了コード 2 を返すため、「存在しない」と誤判定してすべての削除が飛ばされる（実測）。`--info-policy` の終了コードで判定する
- firewalld は削除時に `/etc/firewalld/policies/*.xml.old` と `/etc/firewalld/zones/wireguard.xml.old` を残す。完全に消したい場合は手で削除する
- ルーター側のポート転送と静的経路も削除する

---

## 参照

- [wg(8)](https://man7.org/linux/man-pages/man8/wg.8.html) / [wg-quick(8)](https://man7.org/linux/man-pages/man8/wg-quick.8.html)
- [WireGuard: Quick Start](https://www.wireguard.com/quickstart/)
- [firewalld: Policy Objects](https://firewalld.org/2020/09/policy-objects-introduction)

---
# 付録: network namespace による模擬検証

WG ホスト A は**実機の root namespace**に置いた。本文の手順どおり、`/etc/wireguard/wg0.conf`・`wg-quick@wg0.service`・firewalld を実際に設定している。それ以外のノードは network namespace で作った。インターネットは、ルーター同士を直結した veth で代用した（ドキュメント用アドレス `198.51.100.0/24`）。

```
root ns (= WG host A)                     netns                                  netns
 lab-brA 192.168.110.2 ─┬─ routerA lan0 .110.1   wan0 198.51.100.1 ── wan0 198.51.100.2  routerB  lan0(br) 192.168.120.1 ─┬─ wgB     192.168.120.2
 wg0     10.99.0.1      └─ clientA     .110.100                                                                            └─ clientB 192.168.120.100
                                                                                                        wgB: wg0 10.99.0.2
```

- 両ルーターの namespace には、nftables で **UDP 51820 の DNAT**（WG ホストへ）と **LAN 発の masquerade** を設定し、**相手 LAN 宛ての静的経路**（via WG ホスト）を入れた
- WG ホスト B は `ip netns exec wgB wg-quick up <conf>` で起動した（namespace 内には firewalld が無いので、B 側のフィルタは無し）
- root namespace のデフォルトゲートウェイは実 NIC を向いているので、検証の間だけ `198.51.100.0/24 via 192.168.110.1` を追加した（実環境では不要）
- ラボのブリッジ `lab-brA` は NetworkManager の管理外なので、firewalld のゾーンに割り当てられていない（`--get-zone-of-interface` は `no zone`）。手順 0 の検出はこの場合に既定ゾーン `public` へ落ちる

## 構築スクリプト（抜粋）

```bash
for n in routerA clientA routerB wgB clientB; do ip netns add $n; ip -n $n link set lo up; done
# LAN A（root ns のブリッジ = WG host A の LAN 側 NIC）
ip link add lab-brA type bridge; ip addr add 192.168.110.2/24 dev lab-brA; ip link set lab-brA up
ip link add lab-rA type veth peer name lan0 netns routerA
ip link add lab-cA type veth peer name eth0 netns clientA
# WAN
ip -n routerA link add wan0 type veth peer name wan0 netns routerB
# LAN B（routerB 内のブリッジ）
ip -n routerB link add lan0 type bridge
ip -n routerB link add p-wg type veth peer name eth0 netns wgB
ip -n routerB link add p-cl type veth peer name eth0 netns clientB
# （アドレス付与・link up・default route は省略）

# ルーター（routerA の例。routerB は A/B を入れ替え）
ip netns exec routerA sysctl -qw net.ipv4.ip_forward=1
ip netns exec routerA nft add table ip nat
ip netns exec routerA nft add chain ip nat pre  '{ type nat hook prerouting priority dstnat; }'
ip netns exec routerA nft add chain ip nat post '{ type nat hook postrouting priority srcnat; }'
ip netns exec routerA nft add rule ip nat pre  iifname wan0 udp dport 51820 dnat to 192.168.110.2
ip netns exec routerA nft add rule ip nat post oifname wan0 ip saddr 192.168.110.0/24 masquerade
ip -n routerA route add 192.168.120.0/24 via 192.168.110.2
```

> nftables のルールを `nft -f -` のヒアドキュメントで 1 行ずつ `chain pre { type ...; rule }` と書いたところ、`syntax error, unexpected end of file` になった。上記のように `nft add` を分けて実行すれば問題ない。

## 実測結果

### firewalld の policy を入れる前

WireGuard を起動した直後は、ハンドシェイクは成立するが、クライアント同士は通らない。WG ホストの firewalld が転送を拒否し、ICMP で通知している:

```
$ ip netns exec clientA ping -c1 -W1 192.168.120.100
PING 192.168.120.100 (192.168.120.100) 56(84) bytes of data.
From 192.168.110.2 icmp_seq=1 Packet filtered
```

firewalld の `filter_FORWARD` チェインは、policy に一致しないパケットを `reject with icmpx admin-prohibited` にする。新しく作ったゾーンは `forward: no` になっていた（firewalld 2.4.3）が、ゾーンをまたぐ転送は policy で許可するので、この値は関係しない。

`lab-brA` はどのゾーンにも割り当てられていないが、firewalld は**未割り当ての NIC を既定ゾーンとして扱う**ため、`public` を ingress / egress に指定した policy がそのまま効いた（実測）。

### policy を入れた後

| 確認項目 | 結果 |
|---|---|
| Client A → Client B の ping | 成功 |
| Client B → Client A の ping | 成功 |
| Client A → Client B の TCP（HTTP） | 成功（`HTTP 200`） |
| tracepath | `WG host A → 10.99.0.2 → Client B`（逆方向も対称） |
| Client A が Redirect を受け入れる場合 | `ip route get` に `<redirected>`、以降は WG host A へ直接送る |
| Client A が Redirect を拒否する場合（`accept_redirects=0`） | 毎回 Router A 経由（tracepath に `asymm`）でも成功 |
| WG host A 自身 → Client B | **失敗**（送信元が `10.99.0.1`）。`-I 192.168.110.2` なら成功、Router B に `10.99.0.0/30` の経路を足しても成功 |
| `systemctl restart wg-quick@wg0` 後 | wg0 は `wireguard` ゾーンのまま、疎通も回復 |
| `firewall-cmd --complete-reload` 後 | 同上 |
| SELinux AVC | なし |

### 待ち受けポートを開け忘れた場合

既存の 51820 の conntrack エントリの影響を避けるため、ポートを **51821** に変えて試した。拠点 A を「`Endpoint` を持たず、着信だけを受ける側」にし、Router A には 51821 の DNAT を追加した。

```bash
# A: 待ち受けを 51821 に変え、peer B を Endpoint なしで登録し直す
wg set wg0 listen-port 51821 peer ${SITE_B_PUBKEY} remove
wg set wg0 peer ${SITE_B_PUBKEY} allowed-ips 10.99.0.2/32,192.168.120.0/24
# B: A の Endpoint を 51821 に
ip netns exec wgB wg set wg0 peer ${SITE_A_PUBKEY} endpoint 198.51.100.1:51821
```

| A の firewalld | 結果 |
|---|---|
| 51821/udp を開けていない | Client B → Client A は失敗。A の `latest-handshakes` は `0`（一度も成立していない） |
| `firewall-cmd --add-port=51821/udp` | 成功。A の `wg show` に、`Endpoint` を書いていない B の endpoint `198.51.100.2:51820` が表示された |

一方、本文の構成（両側に `Endpoint`）では、**A の firewalld で 51820/udp を開ける前から**ハンドシェイクが成立していた。A から送ったハンドシェイクへの B の応答が、conntrack で「戻りのパケット」として許可されたためである。開け忘れても、自拠点側から張れば動いてしまうので気づきにくい。

## 変数形コマンドの再検証（2026-09-19）

本書を「手順 0 で変数を定義し、以降はコピペする」形に書き換えたので、**書き換え後のコマンドブロックをそのまま貼って**同じラボを組み直し、通ることを確認した。作業前に `/etc/firewalld` をバックアップし、終了後に `diff -r` で差分が無いことを確認している。

| 確認項目 | 結果 |
|---|---|
| 手順 0 の読み戻し | `MY_SITE=A` が LAN 側 IP から自動判定され、`MY_NIC=lab-brA`、`LAN_ZONE=public`、`POL_OUT=siteA-to-siteB` が組み立てられた |
| 手順 1〜6 をコピペ実行 | **1 度も編集せずに通った** |
| 手順 3 の conf | `wg-s2s.sh --dry-run apply A` が書く予定の conf と `diff` して**完全一致**（秘密鍵行をマスクして比較） |
| 手順 5 の展開結果（`set -x`） | rich rule に `192.168.110.0/24` / `192.168.120.0/24` が入り、literal の `$` は残っていない |
| 手順 5 の後の `wg-s2s.sh --dry-run apply A` | firewalld について追加の変更を表示しない（= 手動で作った設定がスクリプトの作るものと同じ） |
| 疎通 | Client A ⇔ Client B の双方向 ping、Client A → Client B の `HTTP 200`、tracepath が `10.99.0.2` を経由 |
| `systemctl restart` / `--complete-reload` | ゾーン割り当てと疎通が維持された |
| SELinux AVC | なし |
| ロールバック | 変数形のブロックで削除でき、`/etc/firewalld` はバックアップと差分なし（`*.xml.old` を手で消した後） |

書き換えの過程で見つかった、変数化に固有の落とし穴:

| 事象 | 内容 |
|---|---|
| `LAN_ZONE` が空になる | `firewall-cmd --get-zone-of-interface` は、ゾーン未割り当ての NIC に対して `no zone` を **stderr** に出し、終了コード **2** を返す。stdout を見て `"no zone"` と比較する書き方では検出できない。終了コードで判定する |
| policy がすべて削除されない | firewalld 2.4.3 に `--query-policy` は**存在しない**（`unrecognized arguments`、終了コード 2）。存在確認には `--info-policy` を使う |
| `--reload` が `INVALID_ZONE` で失敗 | policy より先に `wireguard` ゾーンを削除すると、ゾーンを参照する policy が残って reload が壊れる。policy → ゾーンの順に消す |
| rich rule に `$MY_LAN` が入る | 単一引用符で書いた場合。firewalld は `success` を返すので気づきにくい（[落とし穴 3](#落とし穴-3-rich-rule-を単一引用符で書くと変数が展開されない)） |

## 後片付け

namespace・ブリッジ・経路を削除し、[ロールバック](#ロールバック)の手順で wg-quick・鍵・sysctl・firewalld を戻した。`/etc/firewalld` を作業前のバックアップと `diff -r` で比べ、差分が無いことを確認した（削除で生成された `*.xml.old` は手で消した）。`wireguard-tools` と `systemd-resolved` はインストールしたまま残している。

## スクリプトの検証（ドライランのみ）

`wg-s2s.sh` は、**実際の適用（`apply` / `remove` の本実行）をまだ試していない**。2026-09-19 の再検証では、手動手順と同じ conf を生成すること・手動で作った firewalld 設定に対して追加の変更を出さないことを `--dry-run` で確認したが、`apply` の本実行は行っていない。

| 確認項目 | 結果 |
|---|---|
| `bash -n` | OK |
| root 以外で `apply` | `root で実行してください` で停止 |
| `keygen` | 鍵を生成して公開鍵を表示。再実行しても既存の鍵を上書きしない。拠点指定を誤ると停止 |
| `apply A --dry-run`（conf 生成、netns 環境） | 生成予定の conf が手動手順の conf と**バイト単位で一致**（`PrivateKey = (hidden)`）。LAN 側ゾーンも `public（lab-brA から検出）` と手順 0 と同じ判定 |
| 相手の公開鍵が空 | `SITE_B_PUBKEY（相手拠点の公開鍵）が空です` で停止 |
| `--use-existing-conf --dry-run apply A`（実機の既存 conf） | 整合チェックを通過。conf は生成しない。firewalld は、既に設定済みのポート・ゾーン・interface を飛ばし、足りない rich rule と逆方向の policy だけが表示された |
| 既存 conf: `Address` 不一致 | `Address（…）に自拠点のトンネル IP … がありません` で停止 |
| 既存 conf: 相手 LAN が `AllowedIPs` に無い | `相手拠点 LAN … を AllowedIPs に含む [Peer] がありません` で停止 |
| 既存 conf: ファイルが無い | `既存の設定ファイルがありません` で停止 |
| 既存 conf: `ListenPort` ≠ `WG_PORT` | 警告を出し、conf の値を使って続行 |
| 既存 conf: 相手 peer に `Endpoint` が無い | 警告を出して続行 |
| A/B の取り違え | `このホストは拠点 A の WG ホスト（…）です` で停止 |
| 両拠点の LAN が重複 | `… と … が重複しています` で停止 |
| 実行前後の比較 | 既存 conf の sha256 が一致。`/etc/firewalld` はバックアップと `diff -r` で差分なし。`ip_forward` も変化なし |

未確認: `apply` と `remove` の本実行、適用後の疎通、再実行したときに設定が重複しないこと、conf のパーミッション警告（対象ファイルが既に 600 だったため）。

その後、リモートクライアント対応を加えた版は、`firewall-cmd` などを模したスタブ環境で `apply` / `remove` の本実行と再実行（設定が重複しないこと）まで確認した（[リモートクライアント追加手順の付録](wireguard-remote-clients.md#付録-スクリプトの検証スタブ環境)）。実機での適用は引き続き未確認。
