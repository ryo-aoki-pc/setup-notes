# WireGuard 拠点間 VPN へのリモートクライアント追加手順（road warrior / wg-quick + firewalld）

- **目的**: [拠点間 VPN](wireguard-site-to-site.md) に、外出先のノート PC やスマートフォンなど**任意の台数のクライアント**を追加し、**両拠点の LAN に到達できる**ようにする
- **構成**: クライアントは拠点 A / B のどちらかの WireGuard ホストに接続する。接続先拠点の LAN へは直接、もう一方の拠点の LAN へは拠点間トンネルを経由して届く。拠点ごとにクライアント用のアドレス帯を持つ
- **設定方式**: 拠点間 VPN と同じ（`wg-quick` + systemd、firewalld の専用ゾーン + policy）。既存の `wg0` に `[Peer]` を足すだけで、インターフェースも待ち受けポートも増やさない
- **進め方**: 拠点間 VPN の[手順 0](wireguard-site-to-site.md#0-値を-1-度だけ書く変数の定義)で作った `~/wg/site.env` にクライアント用の値を**足すだけ**。以降のコマンドブロックは編集せずにそのまま貼る（拠点 A / B の違いは変数が吸収する）
- **状態**: 拠点間 VPN と同じ network namespace のラボに外出先クライアントを 1 台足して、**両拠点の LAN への双方向疎通まで確認済み**（2026-09-19、[付録](#付録-network-namespace-による検証2026-09-19)）。**実機を持ち出しての確認（実際のモバイル回線・スマートフォンアプリ）はしていない**
- **スクリプト**: 拠点間 VPN と同じ [`scripts/wireguard-site-to-site/wg-s2s.sh`](../scripts/wireguard-site-to-site/wg-s2s.sh) の `client` コマンドで行う（[スクリプトで実行する場合](#スクリプトで実行する場合)）

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-16（設計）／ 2026-09-19（network namespace で疎通確認） |
| WG ホスト | 拠点間 VPN の手順書と同じ環境（AlmaLinux 10.2 / wireguard-tools 1.0.20250521 / firewalld 2.4.3） |
| クライアント | 検証は Linux の `wg-quick`。WireGuard 公式アプリ（Windows / macOS / iOS / Android）も同じ conf で使える想定 |
| 前提 | [拠点間 VPN](wireguard-site-to-site.md) が構築済み、または同時に構築する |

> **注記**: 変数は拠点間 VPN の手順書のものに加えて次を使う。値は同じ `~/wg/site.env` に書く。例は検証で使った値。
>
> | 変数 | 意味 | 例（検証時の値） |
> |---|---|---|
> | `${WG_A_CLIENT_NET}` / `${WG_B_CLIENT_NET}` | 各拠点に接続するクライアントに割り当てるトンネル内のアドレス帯（**LAN・`${WG_TUNNEL_NET}`・互いに重複不可**、`/30` より広く） | `10.99.1.0/24` / （空） |
> | `${WG_CLIENT_DNS}` | クライアント用 conf に書く DNS サーバー（任意） | （空） |
> | `${CLIENT_NAME}` | クライアントの名前（英数字・`-`・`_`） | `laptop` |
> | `${CLIENT_TUN_IP}` | クライアントのトンネル IP（`${WG_x_CLIENT_NET}` の中） | `10.99.1.1` |
> | `${CLIENT_PUBKEY}` | クライアントの公開鍵（手順 4 が鍵ファイルから読む） | （`wg pubkey` の出力） |
>
> 手順 0 を読み直すと、このホスト視点の `${MY_CLIENT_NET}` / `${PEER_CLIENT_NET}` と、クライアント用の policy 名（`${POL_MYCL_IN}` など）が組み立てられる。
>
> クライアントを受けない拠点の `${WG_x_CLIENT_NET}` は空にする（片方の拠点だけで受けるハブ構成になる）。検証では拠点 A だけで受けた。

---

## 構成

```
  外出先                                   拠点 A                                            拠点 B
 [Remote client] ═══ Internet ═══ [Router A] ─┬─ [WG host A] ══ 拠点間トンネル ${WG_TUNNEL_NET} ══ [WG host B] ─┬─ [Router B]
 ${CLIENT_TUN_IP}   (UDP ${WG_PORT},          │   wg0 ${WG_A_TUN_IP}                         wg0 ${WG_B_TUN_IP}  │
 ∈ ${WG_A_CLIENT_NET}  ポート転送は拠点間と共用)└─ [Client A] ${SITE_A_LAN}                 ${SITE_B_LAN} [Client B] ─┘
```

拠点 A のクライアントは、拠点間 VPN のためにルーター A に入れたポート転送（`${WG_PORT}/udp` → WG host A）をそのまま使って WG host A に接続する。WG host A から見ると、拠点 B の peer とクライアントの peer が同じ `wg0` に並ぶ。

### パケットの流れ

**Remote client → Client A（接続先拠点の LAN）**

1. クライアントは宛先 `${SITE_A_LAN}` を `AllowedIPs` に持つので、暗号化して `${SITE_A_PUBLIC}:${WG_PORT}` へ送る
2. Router A のポート転送で WG host A に届き、復号される。送信元 `${CLIENT_TUN_IP}` はそのクライアントの `[Peer]` の `AllowedIPs` に含まれるので受け入れられる
3. WG host A は `wg0` → LAN 側 NIC に転送する（policy `clientsA-to-siteA`）
4. 戻りは Client A → デフォルトゲートウェイの Router A → **静的経路 `${WG_A_CLIENT_NET}` via `${WG_A_LAN_IP}`** → WG host A（policy `siteA-to-clientsA`）→ ハンドシェイクで覚えたクライアントの endpoint へ

**Remote client → Client B（もう一方の拠点の LAN）**

1. WG host A で復号された後、宛先 `${SITE_B_LAN}` は `wg0` 向きの経路（拠点 B の peer の `AllowedIPs`）に当たるので、**同じ `wg0` から**拠点 B の peer へ再び暗号化して出て行く（policy `clientsA-to-siteB`。ingress・egress とも `wireguard` ゾーン）
2. WG host B で復号される。送信元 `${CLIENT_TUN_IP}` は**拠点 A の peer の `AllowedIPs` に `${WG_A_CLIENT_NET}` が入っていて初めて**受け入れられる。入っていなければ、WireGuard は ICMP も返さず黙って捨てる
3. WG host B は LAN 側に転送する（policy `clientsA-to-siteB`。こちらは `wireguard` → `${LAN_ZONE}`）
4. 戻りは Client B → Router B → **静的経路 `${WG_A_CLIENT_NET}` via `${WG_B_LAN_IP}`** → WG host B（`${WG_A_CLIENT_NET}` の経路は `wg0` 向き。policy `siteB-to-clientsA`）→ 拠点間トンネル → WG host A（`${CLIENT_TUN_IP}/32` の経路は `wg0` 向き。policy `siteB-to-clientsA`）→ クライアント

この折り返し（`wg0` から入って `wg0` へ出る転送）が成立することは、ラボで確認した（[付録](#付録-network-namespace-による検証2026-09-19)）。

したがって、拠点間 VPN に加えて必要なのは次のとおり。

| 場所 | 追加で必要な設定 |
|---|---|
| WG ホスト（クライアントを受ける拠点） | クライアントごとの `[Peer]`（`AllowedIPs` = そのクライアントの `/32`）、policy 4 つ（クライアント帯 ⇔ 自拠点 LAN、クライアント帯 ⇔ 相手拠点 LAN） |
| WG ホスト（もう一方の拠点） | 拠点間 peer の `AllowedIPs` に相手拠点のクライアント帯を追加、policy 2 つ（相手拠点のクライアント帯 ⇔ 自拠点 LAN） |
| 両拠点のルーター | **クライアント帯 via WG ホスト**の静的経路（両拠点の帯とも） |
| クライアント | conf を取り込む（`AllowedIPs` = 両拠点の LAN + `${WG_TUNNEL_NET}`） |

## 選択した方針

- **クライアントは拠点に所属させ、拠点ごとにアドレス帯を分ける** — WireGuard はインターフェースごとに「この宛先はこの peer」という対応表（cryptokey routing）を持ち、**1 つのアドレスを 2 つの peer に対応づけることはできない**。WG host B から見ると拠点 A のクライアントはすべて拠点 A の peer の向こうにいるので、帯をまとめて `AllowedIPs` に 1 行書けばよく、クライアントを追加しても拠点 B 側の設定は変わらない。同じクライアントを両拠点に直接つなげる構成にすると、各ホストでそのクライアントの IP を「直接の peer」と「相手拠点の peer」の両方に書くことになり成立しない。片方の拠点だけで受けたい場合は、もう一方の帯を空にする
- **既存の `wg0` に peer を足す** — インターフェースを分けると待ち受けポート・ポート転送・ゾーンが増える。拠点間 VPN の「専用ゾーン + policy」の枠組みをそのまま広げるほうが見通しがよい
- **NAT しない**（拠点間 VPN と同じ） — 送信元がクライアントのトンネル IP のまま LAN に届くので、LAN 側で識別・制限できる。その代わり、**両拠点のルーターにクライアント帯の静的経路が要る**（[注意点](#ルーターにはクライアント帯の静的経路も要る)）
- **転送は方向ごとの policy で絞る** — `wg0` から入って `wg0` へ折り返す転送（クライアント → 相手拠点 LAN）は、ingress と egress に同じ `wireguard` ゾーンを指定した policy で許可する。ゾーンの `forward` オプション（`--add-forward`）でも通せるが、それだと `wg0` 内の転送がすべて通る（クライアント同士など）。**firewalld 2.4.3 は ingress と egress が同じゾーンの policy を受理し、実際に `wg0 → wg0` の転送に効くことをラボで確認した**（その policy を外すと、クライアント → 相手拠点 LAN だけが `Packet filtered` になる。実測）
- **クライアントの conf はホスト側で生成し、QR コードかファイルで渡す** — スマートフォンではこれが実用的。秘密鍵を拠点の外で作りたい場合は、クライアント側で鍵を作って公開鍵だけを渡す
- **反映は restart で行う** — 新しい peer の `AllowedIPs` に対する経路は reload では追加されない（[拠点間 VPN の落とし穴 2](wireguard-site-to-site.md#落とし穴-2-reload-では経路が追加されない) と同じ機構。実測）。まとめて登録してから 1 回 restart する運用にする
- **クライアント同士の通信と、全トラフィックの VPN 経由（`0.0.0.0/0`）は対象外** — 必要なら[注意点](#クライアント同士を通す場合)を参照

---
## 構築手順

**手順 0〜3 は両拠点の WG ホストで実施する。** 手順 4〜5 はクライアントを受ける拠点のホストだけ、手順 6 は両拠点のルーターで行う。コマンドは拠点 A / B で同じものを貼る。

| 手順 | 内容 | 実施場所 |
|---|---|---|
| 0 | 帯を決めて `site.env` に書き足す | 両拠点の WG ホスト |
| 1 | 相手 peer の `AllowedIPs` を更新する | 同上 |
| 2 | firewalld の設定 | 同上 |
| 3 | サービスの再起動 | 同上 |
| 4 | クライアントを登録する | クライアントを受ける拠点のホスト |
| 5 | クライアントに conf を渡す | 同上 |
| 6 | 静的経路の追加 | 両拠点のルーター |

### 0. 帯を決めて `site.env` に書き足す

拠点ごとにクライアント用の帯を 1 つ決める。**LAN・`${WG_TUNNEL_NET}`・もう一方の帯と重ならないこと。** `${WG_TUNNEL_NET}`（`/30`）は変えない。

```bash
vi ~/wg/site.env        # WG_A_CLIENT_NET / WG_B_CLIENT_NET（必要なら WG_CLIENT_DNS）を書く
. ~/wg/wg-env.sh        # 書き換えたら読み直す
```

**両拠点の `site.env` を同じ内容にそろえる。** 片側だけに書くと、相手拠点のホストが帯を知らず、パケットを黙って捨てる（[注意点](#相手拠点のホストが帯を知らないと黙って捨てる)）。

読み戻して確認する。

```bash
for v in MY_SITE MY_CLIENT_NET PEER_CLIENT_NET PEER_ALLOWED \
         POL_MYCL_IN POL_MYCL_OUT POL_MYCL_PEER POL_PEER_MYCL POL_PEERCL_IN POL_PEERCL_OUT; do
  printf '%-16s = %s\n' "$v" "${!v}"
done
```

```
MY_SITE          = A
MY_CLIENT_NET    = 10.99.1.0/24
PEER_CLIENT_NET  =                                 ← 拠点 B ではクライアントを受けない構成
PEER_ALLOWED     = 10.99.0.2/32, 192.168.120.0/24  ← 相手拠点に帯があれば自動で加わる
POL_MYCL_IN      = clientsA-to-siteA
POL_MYCL_OUT     = siteA-to-clientsA
POL_MYCL_PEER    = clientsA-to-siteB
POL_PEER_MYCL    = siteB-to-clientsA
POL_PEERCL_IN    = clientsB-to-siteA
POL_PEERCL_OUT   = siteA-to-clientsB
```

帯が重なっていないかは、値を見て確かめる。`10.99.0.0/16` のような大きな帯の中にトンネル網とクライアント帯をまとめて取っておくと、ルーターの静的経路が 1 本で済む（[注意点](#ルーターにはクライアント帯の静的経路も要る)）。

### 1. 相手 peer の `AllowedIPs` を更新する

**拠点間 VPN の[手順 3](wireguard-site-to-site.md#3-wg0conf-の作成) のヒアドキュメントをもう一度貼るだけ。** `PEER_ALLOWED` は手順 0 が組み立て直しているので、相手拠点にクライアント帯があれば自動で入る。

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
sudo grep -v '^PrivateKey' "$WG_CONF"
```

拠点 B のホストで実行すると、拠点 A の peer に拠点 A のクライアント帯が入る（実測）。

```
[Peer]
# Site A
PublicKey = ByZIklVIeAJxMyzitWu6FWNPFHk1eb1/Q6ejJfsC1U0=
Endpoint = 198.51.100.1:51820
AllowedIPs = 10.99.0.1/32, 192.168.110.0/24, 10.99.1.0/24
PersistentKeepalive = 25
```

> **conf を作り直すので、登録済みのクライアントの `[Peer]` は消える。** クライアントを登録した後にこのブロックを貼り直した場合は、手順 4 の `[Peer]` を足し直す（または `wg-s2s.sh apply` を使う。こちらは `clients.list` から毎回組み立てる）。

### 2. firewalld の設定

policy の作り方は拠点間 VPN と同じ（新規 policy → ingress/egress ゾーン → rich rule）。**自拠点のクライアント用**と**相手拠点のクライアント用**で ingress / egress の組み合わせが違うだけなので、共通の関数にまとめて、帯が設定されている分だけ作る。

```bash
mkpol() { # $1=policy 名 $2=ingress $3=egress $4=送信元 $5=宛先
  sudo firewall-cmd --permanent --new-policy="$1"
  sudo firewall-cmd --permanent --policy="$1" --add-ingress-zone="$2"
  sudo firewall-cmd --permanent --policy="$1" --add-egress-zone="$3"
  sudo firewall-cmd --permanent --policy="$1" \
    --add-rich-rule="rule family=ipv4 source address=$4 destination address=$5 accept"
}

# (a)(b) 自拠点のクライアント ⇔ 自拠点 LAN
[ -n "$MY_CLIENT_NET" ] && mkpol "$POL_MYCL_IN"   "$WG_FW_ZONE" "$LAN_ZONE"   "$MY_CLIENT_NET" "$MY_LAN"
[ -n "$MY_CLIENT_NET" ] && mkpol "$POL_MYCL_OUT"  "$LAN_ZONE"   "$WG_FW_ZONE" "$MY_LAN"        "$MY_CLIENT_NET"

# (c)(d) 自拠点のクライアント ⇔ 相手拠点 LAN（wg0 から入って wg0 へ折り返す）
[ -n "$MY_CLIENT_NET" ] && mkpol "$POL_MYCL_PEER" "$WG_FW_ZONE" "$WG_FW_ZONE" "$MY_CLIENT_NET" "$PEER_LAN"
[ -n "$MY_CLIENT_NET" ] && mkpol "$POL_PEER_MYCL" "$WG_FW_ZONE" "$WG_FW_ZONE" "$PEER_LAN"      "$MY_CLIENT_NET"

# (e)(f) 相手拠点のクライアント ⇔ 自拠点 LAN（自分は中継側なのでゾーンが違う）
[ -n "$PEER_CLIENT_NET" ] && mkpol "$POL_PEERCL_IN"  "$WG_FW_ZONE" "$LAN_ZONE"   "$PEER_CLIENT_NET" "$MY_LAN"
[ -n "$PEER_CLIENT_NET" ] && mkpol "$POL_PEERCL_OUT" "$LAN_ZONE"   "$WG_FW_ZONE" "$MY_LAN"          "$PEER_CLIENT_NET"

sudo firewall-cmd --reload
sudo firewall-cmd --get-policies | tr ' ' '\n' | grep -E 'clients|site[AB]'
```

```
clientsA-to-siteA
clientsA-to-siteB
siteA-to-clientsA
siteA-to-siteB
siteB-to-clientsA
siteB-to-siteA
```

- **`mkpol` はこのブロックの中で定義する**（`wg-env.sh` には入れない）。手順を 1 ブロックで完結させるため
- policy 名は両拠点で同じにしてある（`clientsA-to-siteB` は、拠点 A では `wireguard → wireguard`、拠点 B では `wireguard → ${LAN_ZONE}`）。**通信の向きで名前を付け、ゾーンはホストごとに違う**
- 帯を設定していない拠点では、対応する policy は作られない（上の `[ -n ... ]`）。検証では拠点 B の帯が空なので、(e)(f) は作られなかった
- rich rule は**二重引用符**で書く（[拠点間 VPN の落とし穴 3](wireguard-site-to-site.md#落とし穴-3-rich-rule-を単一引用符で書くと変数が展開されない)）
- 片方向だけにしたい場合（クライアントからは拠点に入れるが、拠点からクライアントへは接続させない）は、(b)・(d)・(f) を作らない。戻りは conntrack で通る
- 待ち受けポート `${WG_PORT}/udp` は拠点間 VPN で開けてある。クライアントも同じポートに接続する

### 3. サービスの再起動

両拠点で:

```bash
sudo systemctl restart "wg-quick@$WG_IFACE"
ip route show dev "$WG_IFACE"
```

`reload` では `wg0.conf` の peer は反映されるが、**新しい peer の `AllowedIPs` に対する経路（`${CLIENT_TUN_IP}/32`、拠点 B では `${WG_A_CLIENT_NET}`）が追加されない**（[拠点間 VPN の落とし穴 2](wireguard-site-to-site.md#落とし穴-2-reload-では経路が追加されない) に実測を載せた）。経路が無いとクライアント宛てのパケットがトンネルに入らない。

拠点 B 側では、クライアント帯への経路が増えているはずである（実測）。

```
10.99.0.0/30 proto kernel scope link src 10.99.0.2
10.99.1.0/24 scope link                             ← 拠点 A のクライアント帯
192.168.110.0/24 scope link
```

### 4. クライアントを登録する

**クライアントを受ける拠点のホストで実施する。編集するのは最初の 2 行だけ。**

```bash
CLIENT_NAME=laptop
CLIENT_TUN_IP=10.99.1.1                 # ${MY_CLIENT_NET} の中の空きアドレス

# 使用済みでないことを確かめる
sudo grep -q "AllowedIPs = ${CLIENT_TUN_IP}/32" "$WG_CONF" && echo "使用済み: 別の IP にする" || echo "未使用: 進める"
```

```bash
# 鍵を作り、クライアント用 conf を書く（秘密鍵は画面に出ない）
sudo install -d -m 700 /etc/wireguard/clients
sudo bash -c "umask 077; wg genkey | tee /etc/wireguard/clients/$CLIENT_NAME.key | wg pubkey > /etc/wireguard/clients/$CLIENT_NAME.pub"
CLIENT_PUBKEY=$(sudo cat "/etc/wireguard/clients/$CLIENT_NAME.pub")

sudo install -m 600 /dev/null "/etc/wireguard/clients/$CLIENT_NAME.conf"
cat <<EOF | sudo tee "/etc/wireguard/clients/$CLIENT_NAME.conf" >/dev/null
[Interface]
Address = ${CLIENT_TUN_IP}/32
PrivateKey = $(sudo cat "/etc/wireguard/clients/$CLIENT_NAME.key")

[Peer]
# Site ${MY_SITE}
PublicKey = ${MY_PUBKEY}
Endpoint = ${MY_PUBLIC}:${WG_PORT}
AllowedIPs = ${MY_LAN}, ${PEER_LAN}, ${WG_TUNNEL_NET}
PersistentKeepalive = ${WG_KEEPALIVE}
EOF

# WG ホストの wg0.conf にこのクライアントの [Peer] を足す
cat <<EOF | sudo tee -a "$WG_CONF" >/dev/null

[Peer]
# Client ${CLIENT_NAME}
PublicKey = ${CLIENT_PUBKEY}
AllowedIPs = ${CLIENT_TUN_IP}/32
EOF

sudo systemctl restart "wg-quick@$WG_IFACE"
ip route show dev "$WG_IFACE"           # ${CLIENT_TUN_IP} の /32 経路が増えている
```

```
10.99.0.0/30 proto kernel scope link src 10.99.0.1
10.99.1.1 scope link                                ← 登録したクライアント
192.168.120.0/24 scope link
```

- **WG ホスト側の `[Peer]` に `Endpoint` は書かない。** クライアントの場所は変わるので、ハンドシェイクを受けた送信元を endpoint として覚える（`wg show` に出る）。`PersistentKeepalive` もクライアント側にだけ書く
- クライアント側 `AllowedIPs` に `${WG_TUNNEL_NET}` を入れるのは、WG ホスト自身がクライアントに送るパケットの送信元が `wg0` のアドレス（`${MY_TUN_IP}`）になるため。無いとクライアント側で捨てられ、WG ホストからの ping や、ホストで動くサービスへの接続ができない
- `DNS =` を書きたい場合は[注意点](#dns--を書く場合)を参照
- 複数台をまとめて登録し、最後に 1 回 restart すればよい
- 鍵をクライアント側で作りたい場合は、クライアントで `wg genkey | tee client.key | wg pubkey` として**公開鍵だけ**をホストに渡し、`CLIENT_PUBKEY=<渡された公開鍵>` としてから上の後半（`wg0.conf` への追記）だけを実行する

### 5. クライアントに conf を渡す

```bash
sudo cat "/etc/wireguard/clients/$CLIENT_NAME.conf"        # PC にはこの内容をコピーする
sudo dnf install -y qrencode                               # スマートフォン用（EL10 では epel-release が要る場合がある）
sudo cat "/etc/wireguard/clients/$CLIENT_NAME.conf" | qrencode -t ansiutf8
sudo rm -f "/etc/wireguard/clients/$CLIENT_NAME.conf" "/etc/wireguard/clients/$CLIENT_NAME.key"
```

**取り込んだら、秘密鍵入りの conf と鍵をホストに残さない。** 公開鍵（`.pub`）は残しておくと、後で `wg0.conf` の `[Peer]` と突き合わせられる。

### 6. 拠点ルーターの設定

```bash
cat <<EOF
静的経路（追加）: 宛先 ${MY_CLIENT_NET} → ゲートウェイ ${MY_LAN_IP}
（相手拠点のルーターには 宛先 ${MY_CLIENT_NET} → ゲートウェイ ${PEER_LAN_IP} を入れる）
EOF
```

| 設定 | 拠点 A のルーター | 拠点 B のルーター |
|---|---|---|
| 静的経路（追加） | 宛先 `${WG_A_CLIENT_NET}` → ゲートウェイ `${WG_A_LAN_IP}` | 宛先 `${WG_A_CLIENT_NET}` → ゲートウェイ `${WG_B_LAN_IP}` |
| 静的経路（拠点 B でも受ける場合） | 宛先 `${WG_B_CLIENT_NET}` → ゲートウェイ `${WG_A_LAN_IP}` | 宛先 `${WG_B_CLIENT_NET}` → ゲートウェイ `${WG_B_LAN_IP}` |
| ポート転送 | 変更なし（拠点間 VPN のものを共用） | 変更なし |

`${WG_TUNNEL_NET}` とクライアント帯を 1 つの大きな帯（例: `10.99.0.0/16`）の中に取っておけば、ルーターの静的経路はその帯 1 本で済む。拠点間 VPN の[「WG ホスト自身から相手 LAN へ送る場合」](wireguard-site-to-site.md#wg-ホスト自身から相手-lan-へ送る場合)の問題（トンネル網への経路が無い）も同時に解消する。

### スクリプトで実行する場合

値は同じ `~/wg/site.env` に書く。クライアントの登録簿 `clients.list`（[`clients.list.example`](../scripts/wireguard-site-to-site/clients.list.example)）は `client add` が作り、クライアントを受ける拠点のホストにあればよい。どちらも `.gitignore` で除外している。

```bash
cd scripts/wireguard-site-to-site

# 1. 両拠点のホストで apply する（相手 peer の AllowedIPs とクライアント用 policy が入る。restart するので一瞬切れる）
sudo ./wg-s2s.sh -e ~/wg/site.env apply A                  # 拠点 B のホストでは apply B

# 2. クライアントを受ける拠点のホストで登録する（何台でも）
sudo ./wg-s2s.sh -e ~/wg/site.env client add A laptop      # 鍵を生成し、/etc/wireguard/clients/laptop.conf を書く
sudo ./wg-s2s.sh -e ~/wg/site.env client add A phone --pubkey 'クライアントから受け取った公開鍵'   # 鍵をクライアント側で作った場合
sudo ./wg-s2s.sh -e ~/wg/site.env apply A                  # 登録した [Peer] を wg0.conf に書いて restart

# 3. クライアントに conf を渡す
sudo ./wg-s2s.sh -e ~/wg/site.env client show laptop --qr  # スマートフォンのアプリで読み取る（qrencode が必要）
sudo rm /etc/wireguard/clients/laptop.conf                 # 取り込んだら残さない

# 4. 両拠点のルーターに静的経路を追加する
./wg-s2s.sh -e ~/wg/site.env router A

./wg-s2s.sh -e ~/wg/site.env client list
sudo ./wg-s2s.sh -e ~/wg/site.env client remove laptop && sudo ./wg-s2s.sh -e ~/wg/site.env apply A
```

手動手順との違いは、`clients.list` に登録を残すので **`apply` を何度実行しても同じ conf が組み立て直される**こと（手順 1 で conf を作り直してもクライアントの `[Peer]` が消えない）。`client add` は、帯の重複・名前や IP の重複・拠点の取り違えなどを**何かを書く前に**検査する。トンネル IP は `--ip` が無ければ帯の中で最小の空きを割り当てる。

`remove A` はクライアント用の policy も削除する。`--purge` を付けると `clients.list` にあるクライアントの conf も消す（`clients.list` 自体は残す）。

---
## 検証方法

### WG ホストで確認する

```bash
. ~/wg/wg-env.sh
sudo wg show                                      # クライアントの peer に endpoint と handshake が出る
ip route show dev "$WG_IFACE"                     # クライアントの /32、拠点 B では相手のクライアント帯
sudo firewall-cmd --info-policy="$POL_MYCL_PEER"  # ingress・egress とも wireguard
```

```
$ sudo wg show
interface: wg0
  public key: ${SITE_A_PUBKEY}
  private key: (hidden)
  listening port: 51820

peer: ${CLIENT_PUBKEY}
  endpoint: 198.51.100.3:37301                    ← ハンドシェイクで覚えた（conf には書いていない）
  allowed ips: 10.99.1.1/32
  latest handshake: 19 seconds ago
  transfer: 7.89 KiB received, 3.68 KiB sent

peer: ${SITE_B_PUBKEY}
  endpoint: 198.51.100.2:51820
  allowed ips: 10.99.0.2/32, 192.168.120.0/24
  latest handshake: 37 seconds ago
  transfer: 2.37 KiB received, 4.93 KiB sent
  persistent keepalive: every 25 seconds
```

### クライアントから確認する

```bash
ping <接続先拠点の LAN のホスト>     # 例: 192.168.110.100
ping <相手拠点の LAN のホスト>       # 例: 192.168.120.100
tracepath -n <相手拠点の LAN のホスト>
```

相手拠点への tracepath には、**両方の WG ホストのトンネル IP**が順に出る（実測）。

```
$ tracepath -n 192.168.120.100
 1?: [LOCALHOST]                      pmtu 1420
 1:  10.99.0.1                                             0.247ms       ← WG host A（折り返し）
 1:  10.99.0.1                                             0.105ms
 2:  10.99.0.2                                             0.208ms       ← WG host B
 3:  192.168.120.100                                       0.165ms reached
     Resume: pmtu 1420 hops 3 back 3
```

**逆方向（拠点の LAN → クライアント）も確認する。** ルーターの静的経路か `(b)`・`(d)`・`(f)` の policy が抜けていると、片方向だけ失敗する。

### 症状と原因の対応（実測）

| 症状 | 原因 |
|---|---|
| クライアントの ping に `From ${MY_TUN_IP} ... Packet filtered` で、宛先が**相手拠点 LAN のときだけ**失敗する | `wg0 → wg0` の policy（`clientsA-to-siteB`）が無い。検証では、この policy を外すと自拠点 LAN への ping は通ったまま相手拠点 LAN だけが落ちた |
| クライアントの ping に `From ${MY_LAN_IP} ... Packet filtered` | 自拠点 LAN 向けの policy（`clientsA-to-siteA`）が無い |
| ハンドシェイクは成立するのに、相手拠点 LAN へ**まったく応答が無い**（ICMP も返らない） | 相手拠点のホストの `AllowedIPs` にクライアント帯が無い。WireGuard は範囲外の送信元を黙って捨てる。手順 1 を相手拠点でも実行したか確認する |
| クライアントを足したのに届かない。`wg show` には出ている | `reload` で済ませた。`restart` する（[落とし穴 2](wireguard-site-to-site.md#落とし穴-2-reload-では経路が追加されない)） |
| 拠点の LAN からクライアントへ接続できない（逆方向だけ失敗） | ルーターにクライアント帯の静的経路が無い、または `(b)`・`(d)`・`(f)` の policy が無い |
| クライアントから WG ホスト自身（`${MY_TUN_IP}`）に届かない | クライアント conf の `AllowedIPs` に `${WG_TUNNEL_NET}` が入っていない |
| 手順 1 を貼り直したらクライアントが全部切れた | conf を作り直したので `[Peer]` が消えた。手順 4 の追記をやり直すか、`wg-s2s.sh apply` を使う |

---

## 注意点

### 新しいクライアントの経路は reload では入らない

`AllowedIPs` に対する経路が追加されるのは `wg-quick up` のときだけ。クライアントを足したら `systemctl restart`（[拠点間 VPN の落とし穴 2](wireguard-site-to-site.md#落とし穴-2-reload-では経路が追加されない)）。まとめて登録して 1 回で済ませる。

### ルーターにはクライアント帯の静的経路も要る

NAT をしない構成なので、LAN 側ホストの返事はデフォルトゲートウェイ（ルーター）に向かう。ルーターがクライアント帯を知らないと、そこで行き場を失う。**両拠点のルーター**に要る。`${WG_TUNNEL_NET}` とクライアント帯を 1 つの大きな帯に取っておけば、静的経路は 1 本で済む。

### 相手拠点のホストが帯を知らないと黙って捨てる

WireGuard は、`AllowedIPs` の範囲外から届いたパケットを **ICMP も返さずに**捨てる。相手拠点のホストの `AllowedIPs` にクライアント帯が入っていないと、ハンドシェイクも転送も正常に見えたまま届かない。手順 1 を**両拠点で**実行すること。

### 1 台のクライアントは 1 つの拠点にしか接続できない

cryptokey routing の制約（[選択した方針](#選択した方針)）。両拠点に同時に直接つなぐ構成は成立しない。接続先を変えたい場合は、その拠点用の conf を別に作って切り替える（トンネル IP も別の帯のものになる）。

### 着信を受けられない拠点はクライアントを受けられない

クライアントは `Endpoint` を指定して接続しに行くので、接続先拠点にはグローバル IP（または DDNS 名）とポート転送が要る。CGNAT の拠点（`SITE_x_PUBLIC` が空）では `WG_x_CLIENT_NET` も空にする。

### クライアントが拠点の LAN 内にいるとき

ノート PC を持ち帰って拠点 A の LAN 内で VPN を張ると、`${SITE_A_PUBLIC}` 宛ての通信が自拠点のルーターに出て折り返す（ヘアピン）。ルーターが対応していないと接続できない。LAN 内では VPN を切る運用にするのが簡単。

### 秘密鍵の扱い

ホスト側で鍵を作ると、秘密鍵入りの conf が一時的にホストに残る。**クライアントに取り込んだら消す**（手順 5）。より厳密にするなら、クライアント側で鍵を作って公開鍵だけをホストに渡す。

### `DNS =` を書く場合

クライアント conf の `[Interface]` に `DNS = ${WG_CLIENT_DNS}` を書くと、VPN 接続中の名前解決を拠点側の DNS に向けられる。Linux の `wg-quick` はこのとき `resolvconf` を呼ぶので、`systemd-resolved` が有効である必要がある（EL10 では `wireguard-tools` の依存で入るが **disabled のまま**なので、使うなら `systemctl enable --now systemd-resolved`）。公式アプリ（Windows / macOS / iOS / Android）では追加の設定は要らない。本書の検証では `DNS =` を使っていない。

### 全トラフィックを VPN 経由にする場合（対象外）

クライアント conf の `AllowedIPs` を `0.0.0.0/0` にすると、そのクライアントの通信がすべてトンネルに入る。拠点側で NAT（masquerade）と外向きの policy が追加で要る。本書の構成（拠点の LAN にだけ届く）とは別物なので扱わない。

### クライアント同士を通す場合

クライアント A → クライアント B は、どちらも同じ `wg0` にぶら下がる `wg0 → wg0` の転送になる。`clientsA-to-siteB` と同じ形の policy（ingress・egress とも `wireguard`、送信元・宛先ともクライアント帯）を足せば通せる。本書では作らない（必要になる場面が少なく、クライアント同士を隔離しておくほうが安全なため）。

### Endpoint の DDNS 名・MTU

クライアント conf の `Endpoint` に DDNS 名を書いた場合の再解決、モバイル回線での MTU は、拠点間 VPN の[注意点](wireguard-site-to-site.md#endpoint-に-ddns-名を書く場合)と同じ。公式アプリは接続のたびに名前解決するので、`reresolve-dns.sh` のような仕組みは要らない。

---

## ロールバック

クライアント 1 台（クライアントを受ける拠点のホストで）:

```bash
. ~/wg/wg-env.sh
CLIENT_NAME=laptop
sudo python3 -c "
import re,sys
p=sys.argv[1]; s=open(p).read()
s=re.sub(r'\n\[Peer\]\n# Client $CLIENT_NAME\n[^\[]*', '\n', s)
open(p,'w').write(s.rstrip()+'\n')
" "$WG_CONF"
sudo rm -f "/etc/wireguard/clients/$CLIENT_NAME."{key,pub,conf}
sudo systemctl restart "wg-quick@$WG_IFACE"
```

クライアント機能をやめて拠点間 VPN だけに戻す（両拠点で）:

```bash
vi ~/wg/site.env        # WG_A_CLIENT_NET / WG_B_CLIENT_NET を空にする
. ~/wg/wg-env.sh

# 手順 1 を貼り直す（相手 peer からクライアント帯が消え、クライアントの [Peer] も消える）
# …拠点間 VPN の手順 3 のヒアドキュメント…

# クライアント用の policy を消す（ゾーンより先に。存在するものだけ）
for p in "$POL_MYCL_IN" "$POL_MYCL_OUT" "$POL_MYCL_PEER" \
         "$POL_PEER_MYCL" "$POL_PEERCL_IN" "$POL_PEERCL_OUT"; do
  sudo firewall-cmd --permanent --info-policy="$p" >/dev/null 2>&1 &&
    sudo firewall-cmd --permanent --delete-policy="$p"
done
sudo firewall-cmd --reload
sudo rm -rf /etc/wireguard/clients
sudo systemctl restart "wg-quick@$WG_IFACE"
```

- 帯を空にしてから `~/wg/wg-env.sh` を読み直すと、`POL_MYCL_*` などの変数自体は組み立てられたままなので、上のループでそのまま消せる
- policy の存在確認に `--query-policy` は使えない（firewalld 2.4.3 に無い）。`--info-policy` の終了コードで判定する
- 拠点間 VPN ごと削除する場合は[拠点間 VPN のロールバック](wireguard-site-to-site.md#ロールバック)（クライアント用の policy もまとめて消す）
- ルーターのクライアント帯の静的経路も削除する

---

## 参照

- [wg(8)](https://man7.org/linux/man-pages/man8/wg.8.html) — `AllowedIPs` と cryptokey routing
- [WireGuard: Conceptual Overview](https://www.wireguard.com/#cryptokey-routing)
- [firewalld: Policy Objects](https://firewalld.org/2020/09/policy-objects-introduction)
- [firewalld ソース `src/firewall/core/io/policy.py`](https://github.com/firewalld/firewalld/blob/v2.4.3/src/firewall/core/io/policy.py) — ingress/egress ゾーンの検証（同一ゾーンを拒否する規則は無い。policy 名の上限は 128 文字）

---

# 付録: network namespace による検証（2026-09-19）

拠点間 VPN の[付録のラボ](wireguard-site-to-site.md#付録-network-namespace-による模擬検証)に、外出先クライアントの namespace（`clientR`）を 1 つ足して検証した。WAN セグメントをブリッジにし、`clientR` を `198.51.100.3` として置いている（拠点 A のグローバル IP `198.51.100.1` に接続する）。拠点 A だけがクライアントを受ける構成（`WG_A_CLIENT_NET=10.99.1.0/24`、`WG_B_CLIENT_NET` は空）。

WG host A は実機の root namespace なので、**firewalld の policy は実物で動作している**。WG host B は namespace 内で `wg-quick` だけを動かしており、B 側のフィルタは無い。

| 確認項目 | 結果 |
|---|---|
| ingress・egress が同じゾーン（`wireguard`）の policy | firewalld 2.4.3 が**受理した**（`success`）。`--info-policy` にも `ingress-zones: wireguard` / `egress-zones: wireguard` と出る |
| その policy が実際に効くか | **効く。** `clientsA-to-siteB` を削除すると、クライアント → 相手拠点 LAN だけが `From 10.99.0.1 Packet filtered` になり、クライアント → 自拠点 LAN は通ったまま。作り直すと復旧した |
| クライアント peer の `/32` 経路 | `systemctl restart` で `10.99.1.1 scope link` が `wg0` に入った |
| 拠点 B 側の帯の経路 | 拠点 B の conf の `AllowedIPs` に `10.99.1.0/24` を足して restart すると、`10.99.1.0/24 scope link` が入った |
| クライアント → 接続先拠点の LAN（Client A） | 成功 |
| クライアント → 相手拠点の LAN（Client B） | 成功。tracepath は `10.99.0.1 → 10.99.0.2 → 192.168.120.100` |
| Client A → クライアント（逆方向） | 成功 |
| Client B → クライアント（相手拠点から） | 成功 |
| 拠点間の疎通 | クライアント追加後も維持された |
| `Endpoint` を書かないクライアント peer | ハンドシェイク後、`wg show` に `198.51.100.3:37301` と表示された |
| `reload` と `restart` の違い | 2 台目の `[Peer]` を足して `reload` すると `wg show` には出るが経路は入らず、`restart` で入った |
| ルーターの静的経路 | 両拠点のルーターに `10.99.1.0/24 via <WG ホスト>` を入れて成立。入れる前は戻りが届かない |

未確認: 実際のモバイル回線・NAT 越しの挙動、スマートフォンの公式アプリからの接続、`DNS =` を書いた場合、`qrencode` の EL10 での入手先、クライアントが拠点の LAN 内にいるとき（ヘアピン）、SELinux での `/etc/wireguard/clients` の扱い。

---

# 付録: スクリプトの検証（スタブ環境）

2026-09-16 時点では、作業に使えた環境に `wg` 以外の対象コマンドが無く（`firewall-cmd`・`systemctl`・`ip` が無い。network namespace も作れない）、実機も無かった。そこで、次のスタブを `PATH` の先頭に置いてスクリプトを root で実行し、**呼び出されるコマンドと生成されるファイルの内容**を確認した。

| コマンド | スタブの動作 |
|---|---|
| `firewall-cmd` | ゾーン・policy・ポート・interface・rich rule を JSON ファイルに保持する。`--query-*` はその状態で 0/1 を返し、`--new-*` / `--add-*` / `--delete-*` は状態を更新してログに残す。既にあるものを追加すると失敗する |
| `systemctl` | `is-active firewalld` は常に 0。`wg-quick@wg0` の enable / restart / disable --now を状態ファイルで追う |
| `ip` | `-o -4 addr show` で `eth0` に `${WG_A_LAN_IP}`（または `${WG_B_LAN_IP}`）を返す |
| `rpm` / `dnf` / `sysctl` / `restorecon` | 何もしない（`rpm -q wireguard-tools` は 0） |
| `wg` / `qrencode` / `python3` | 本物（`wg genkey` / `wg pubkey` はカーネルモジュール不要） |

鍵は `keygen A` で作り、拠点 B の鍵は別に作って公開鍵だけを `site.env` に書いた。`site.env` は `site.env.example` の値に `WG_A_CLIENT_NET=10.99.1.0/24`、`WG_B_CLIENT_NET=10.99.2.0/24`、`WG_CLIENT_DNS=192.168.110.1` を足したもの。

| 確認項目 | 結果 |
|---|---|
| `bash -n` / `shellcheck -x` | 警告なし |
| `apply A --dry-run` | 生成予定の conf の相手 peer が `AllowedIPs = 10.99.0.2/32, 192.168.120.0/24, 10.99.2.0/24`。firewalld は拠点間の 2 policy に加えて 6 policy（`clientsA-to-siteA` … `siteA-to-clientsB`）が `[dry-run]` で表示。ルーターの値にクライアント帯 2 本の静的経路 |
| `client add A alice --dry-run` | 生成予定のクライアント conf（`Address = 10.99.1.1/32`、`PrivateKey = (hidden)`、`DNS =`、`AllowedIPs = 192.168.110.0/24, 192.168.120.0/24, 10.99.0.0/30`）と、追記予定の行を表示。ファイルは書かない |
| `client add A alice` | `/etc/wireguard/clients/alice.conf`（0600、ディレクトリ 0700）と `clients.list` の行が作られる。秘密鍵は画面に出ない |
| `client add A bob --pubkey … --ip 10.99.1.50` | 指定 IP で登録。conf の `PrivateKey` は `<CLIENT_PRIVATE_KEY>` |
| `client list` / `client show alice` / `client show alice --qr` | 一覧（ハンドシェイクは `-`）、conf の内容、QR コードを表示 |
| `apply A`（本実行） | `wg0.conf` に相手 peer（クライアント帯入り）とクライアント 2 台の `[Peer]`。firewalld のログに 8 policy の作成と reload、`systemctl enable` / `restart` |
| `apply A` を再実行 | `wg0.conf は変更なし`。firewalld への変更は `reload` だけ（重複追加なし） |
| `client remove bob` → `apply A --dry-run` | 行と conf が消え、生成予定の conf からも bob の `[Peer]` が消える |
| `--use-existing-conf --dry-run apply A`（相手 peer にクライアント帯が無い conf） | 帯が無い警告と、書き込まないクライアント `[Peer]` ブロックの表示を出して続行 |
| 拠点 B のホストとして `apply B --dry-run` / `client add B carol` | 拠点 A の peer が `AllowedIPs = 10.99.0.1/32, 192.168.110.0/24, 10.99.1.0/24`。carol は `10.99.2.1` で登録され、拠点 A の `apply A --dry-run` には含まれない |
| `remove A` | 8 policy・`wireguard` ゾーン・`51820/udp` が削除される。conf・鍵・クライアント conf は残る |
| `remove A --purge` | conf・鍵・クライアント conf・`clients/` ディレクトリが消え、`clients.list` は残る |
| クライアント帯を空にした `site.env` | `apply A --dry-run` と `router B` の出力が、変更前のスクリプト（main）と 1 行も違わない |
| 非 root | `client list` と `router` は動く。`client show` は `root で実行してください` で停止 |
| 異常系 | 名前の重複 / `--ip` が帯の外・ネットワークアドレス・使用中・不正 / `--pubkey` が不正・拠点の鍵と同じ・登録済み / 名前に空白 / 拠点 B のクライアントを拠点 A のホストで登録 / 帯が空の拠点への登録 / `SITE_A_PUBLIC` が空 / 帯が LAN と重複・帯同士が重複・帯が `/31` / `clients.list` の列不足・拠点 C・IP と公開鍵の重複・不正な IP — いずれも `ERROR:` を出して何も変更せずに停止（複数の誤りは一度に列挙） |

このスタブ検証で未確認だった「実機での `firewall-cmd`（ingress と egress が同じゾーンの policy）」「`wg-quick` がクライアント peer の `/32` 経路を追加すること」「クライアントからの疎通」は、2026-09-19 の network namespace 検証で確認した（[上の付録](#付録-network-namespace-による検証2026-09-19)）。スクリプト自体の実機での `apply` 本実行は引き続き未確認。
