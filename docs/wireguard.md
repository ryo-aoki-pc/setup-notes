# WireGuard VPN 構築手順（site-to-site + road warrior / wg-quick + firewalld）

- **目的**: 2 拠点の LAN を WireGuard で結び、**拠点 A の LAN 上のクライアントと拠点 B の LAN 上のクライアントが双方向に通信できる**ようにする。さらに、外出先のノート PC やスマートフォンなど**任意の台数のクライアント**を足して、そこから両拠点の LAN に到達できるようにする（手順 8 以降。使わないなら飛ばせる）
- **構成**: 各拠点で、既存ルーターの配下にある AlmaLinux 1 台を WireGuard ホストにする（ルーターの置き換えはしない）。外出先のクライアントは、どちらかの拠点のホストに接続する
- **設定方式**: `wg-quick` + systemd（`/etc/wireguard/wg0.conf` / `wg-quick@wg0.service`）、firewalld の専用ゾーン + policy で転送を制御。クライアントを足すときも既存の `wg0` に `[Peer]` を加えるだけで、インターフェースも待ち受けポートも増やさない
- **進め方**: **手順 0 で値を 1 度だけ書き、以降のコマンドブロックは編集せずにそのまま貼る。** 値はシェル変数に入れるので、**両拠点の WG ホストで同じコマンド列を実行できる**（拠点 A / B の読み替えは手順 0 が自動で行う）
- **状態**: 1 台のマシン上に network namespace で 2 拠点と外出先クライアントを模擬して動作確認済み（[付録](#付録-network-namespace-による検証)）。**実際に 2 拠点をインターネット越しに結んでの確認と、実機を持ち出しての確認（モバイル回線・スマートフォンの公式アプリ）はまだしていない**
- **スクリプト**: 同じ `site.env` を読んで手順をまとめて実行する [`scripts/wireguard-site-to-site/`](../scripts/wireguard-site-to-site/) もある（拠点間の構築とクライアントの追加の両方に対応。[スクリプトでまとめて実行する場合](#スクリプトでまとめて実行する場合)）

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-16（初回）／ 2026-09-19（変数形の手順に書き換えて再検証、クライアントの疎通確認） |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64 |
| カーネル | 6.12.96（`wireguard.ko` を同梱） |
| `wireguard-tools` | 1.0.20250521-1.el10（appstream） |
| firewalld | 2.4.3 |
| NetworkManager | 1.56.0 |
| SELinux | Enforcing |
| クライアント | 検証は Linux の `wg-quick`。WireGuard 公式アプリ（Windows / macOS / iOS / Android）も同じ conf で使える想定 |

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
> | `${WG_A_CLIENT_NET}` / `${WG_B_CLIENT_NET}` | 各拠点に接続するクライアントに割り当てるトンネル内のアドレス帯（**LAN・`${WG_TUNNEL_NET}`・互いに重複不可**、`/30` より広く。手順 8 以降で使う） | `10.99.1.0/24` / （空） |
> | `${WG_CLIENT_DNS}` | クライアント用 conf に書く DNS サーバー（任意） | （空） |
> | `${CLIENT_NAME}` | クライアントの名前（英数字・`-`・`_`） | `laptop` |
> | `${CLIENT_TUN_IP}` | クライアントのトンネル IP（`${WG_x_CLIENT_NET}` の中） | `10.99.1.1` |
> | `${CLIENT_PUBKEY}` | クライアントの公開鍵（手順 11 が鍵ファイルから読む） | （`wg pubkey` の出力） |
>
> これに加えて、手順 0 が**このホストから見た** `MY_*` / `PEER_*`（`${MY_LAN}`・`${PEER_LAN}`・`${MY_CLIENT_NET}` など）と、firewalld の policy 名（`${POL_OUT}`・`${POL_MYCL_IN}` など）を組み立てる。手順 1〜13 のコマンドがこれを使うので、**両拠点で同じコマンドが通る**。
>
> クライアントを受けない拠点の `${WG_x_CLIENT_NET}` は空にする（片方の拠点だけで受けるハブ構成になる）。検証では拠点 A だけで受けた。
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

### リモートクライアントを加えた場合

```
  外出先                                   拠点 A                                            拠点 B
 [Remote client] ═══ Internet ═══ [Router A] ─┬─ [WG host A] ══ 拠点間トンネル ${WG_TUNNEL_NET} ══ [WG host B] ─┬─ [Router B]
 ${CLIENT_TUN_IP}   (UDP ${WG_PORT},          │   wg0 ${WG_A_TUN_IP}                         wg0 ${WG_B_TUN_IP}  │
 ∈ ${WG_A_CLIENT_NET}  ポート転送は拠点間と共用)└─ [Client A] ${SITE_A_LAN}                 ${SITE_B_LAN} [Client B] ─┘
```

外出先のクライアントは、拠点間トンネルのためにルーター A に入れたポート転送（`${WG_PORT}/udp` → WG host A）をそのまま使って WG host A に接続する。WG host A から見ると、拠点 B の peer とクライアントの peer が同じ `wg0` に並ぶ。

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

### パケットの流れ（Remote client → 各拠点）

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

この折り返し（`wg0` から入って `wg0` へ出る転送）が成立することは、ラボで確認した（[付録](#リモートクライアントの検証2026-09-19)）。

したがって、拠点間の構築（手順 0〜7）に加えて必要なのは次のとおり。

| 場所 | 追加で必要な設定 |
|---|---|
| WG ホスト（クライアントを受ける拠点） | クライアントごとの `[Peer]`（`AllowedIPs` = そのクライアントの `/32`）、policy 4 つ（クライアント帯 ⇔ 自拠点 LAN、クライアント帯 ⇔ 相手拠点 LAN） |
| WG ホスト（もう一方の拠点） | 拠点間 peer の `AllowedIPs` に相手拠点のクライアント帯を追加、policy 2 つ（相手拠点のクライアント帯 ⇔ 自拠点 LAN） |
| 両拠点のルーター | **クライアント帯 via WG ホスト**の静的経路（両拠点の帯とも） |
| クライアント | conf を取り込む（`AllowedIPs` = 両拠点の LAN + `${WG_TUNNEL_NET}`） |

## 選択した方針

- **wg-quick + systemd** — 設定が 1 ファイルで完結し、情報も多い。NetworkManager は wg-quick が作った `wg0` を `connected (externally)` として扱うだけで干渉しなかった（実測）
- **値はシェル変数に集約し、両拠点で同じコマンドを実行する** — `site.env` は A/B 両拠点の値を並べて持つ。手順 0 が**このホストがどちらの拠点か**を LAN 側 IP から自動判定し、`MY_*` / `PEER_*` を組み立てる。拠点ごとに手順を書き分けないので、**A/B の取り違えが起きない**
- **秘密鍵は `wg0.conf` に直接書く** — `PostUp` で別ファイルから読み込む書き方もできるが、`systemctl reload` で**秘密鍵が消えてトンネルが止まる**ことを実測で確認した（[落とし穴 1](#落とし穴-1-秘密鍵を-conf-の外に出すと-reload-で消える)）
- **firewalld は wg0 専用ゾーン + policy** — `wg0` を `trusted` や `internal` に入れると、firewalld 2.4 に同梱の `gateway-lan-to-world` policy（`internal home trusted` → `external public` を ACCEPT）が効いてしまい、意図しない範囲まで転送が通る。専用ゾーンを作り、policy の rich rule で **`拠点 A LAN ⇔ 拠点 B LAN` の組み合わせだけ**を許可する
- **トンネルも、クライアントの通信も NAT しない** — 送信元 IP がそのまま相手拠点の LAN に届くので、相手側でアクセス元を識別・制限できる。その代わり、**両拠点のルーターに相手 LAN とクライアント帯の静的経路が要る**（[注意点](#ルーターにはクライアント帯の静的経路も要る)）
- **両拠点とも `Endpoint` と `PersistentKeepalive` を設定** — どちらからでもトンネルを張り直せる。片側がグローバル IP を持たない場合は[注意点](#片側がグローバル-ip-を持たない場合cgnat-など)を参照

外出先クライアントを足す場合は、これに次が加わる。

- **クライアントは拠点に所属させ、拠点ごとにアドレス帯を分ける** — WireGuard はインターフェースごとに「この宛先はこの peer」という対応表（cryptokey routing）を持ち、**1 つのアドレスを 2 つの peer に対応づけることはできない**。WG host B から見ると拠点 A のクライアントはすべて拠点 A の peer の向こうにいるので、帯をまとめて `AllowedIPs` に 1 行書けばよく、クライアントを追加しても拠点 B 側の設定は変わらない。同じクライアントを両拠点に直接つなげる構成にすると、各ホストでそのクライアントの IP を「直接の peer」と「相手拠点の peer」の両方に書くことになり成立しない。片方の拠点だけで受けたい場合は、もう一方の帯を空にする
- **転送は方向ごとの policy で絞る** — `wg0` から入って `wg0` へ折り返す転送（クライアント → 相手拠点 LAN）は、ingress と egress に同じ `wireguard` ゾーンを指定した policy で許可する。ゾーンの `forward` オプション（`--add-forward`）でも通せるが、それだと `wg0` 内の転送がすべて通る（クライアント同士など）。**firewalld 2.4.3 は ingress と egress が同じゾーンの policy を受理し、実際に `wg0 → wg0` の転送に効くことをラボで確認した**（その policy を外すと、クライアント → 相手拠点 LAN だけが `Packet filtered` になる。実測）
- **クライアントの conf はホスト側で生成し、QR コードかファイルで渡す** — スマートフォンではこれが実用的。秘密鍵を拠点の外で作りたい場合は、クライアント側で鍵を作って公開鍵だけを渡す
- **反映は restart で行う** — 新しい peer の `AllowedIPs` に対する経路は reload では追加されない（[落とし穴 2](#落とし穴-2-reload-では経路が追加されない) と同じ機構。実測）。まとめて登録してから 1 回 restart する運用にする
- **クライアント同士の通信と、全トラフィックの VPN 経由（`0.0.0.0/0`）は対象外** — 必要なら[注意点](#クライアント同士を通す場合)を参照

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

**手順 8 以降は、外出先のクライアントを使う場合だけ。** 拠点間だけで使うなら手順 7 で完成する。

| 手順 | 内容 | 実施場所 | |
|---|---|---|---|
| 0 | 値を 1 度だけ書く（変数の定義） | 両拠点の WG ホスト | 必須 |
| 1 | パッケージのインストール | 同上 | 必須 |
| 2 | 鍵ペアの生成、公開鍵の交換 | 同上 | 必須 |
| 3 | `wg0.conf` の作成 | 同上 | 必須 |
| 4 | IP フォワーディングの有効化 | 同上 | 必須 |
| 5 | firewalld の設定 | 同上 | 必須 |
| 6 | サービスの有効化・起動 | 同上 | 必須 |
| 7 | ポート転送と静的経路 | 両拠点のルーター | 必須 |
| 8 | クライアント用の帯を決めて conf を作り直す | 両拠点の WG ホスト | 任意 |
| 9 | firewalld にクライアント用の policy を足す | 同上 | 任意 |
| 10 | サービスの再起動 | 同上 | 任意 |
| 11 | クライアントを登録する | クライアントを受ける拠点のホスト | 任意 |
| 12 | クライアントに conf を渡す | 同上 | 任意 |
| 13 | クライアント帯の静的経路を追加する | 両拠点のルーター | 任意 |

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
- `PEER_ALLOWED` は手順 0 が組み立てる。相手拠点のクライアント帯（[手順 8](#8-クライアント用の帯を決めて-conf-を作り直す)）を `site.env` に書けば、ここに自動で入る
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

**拠点間だけで使うなら、ここで完成。** 検証は[検証方法](#検証方法)へ。

---

**手順 8 以降は、外出先のクライアントを使う場合だけ。** 拠点 A / B のどちらか（または両方）でクライアントを受けられる。

### 8. クライアント用の帯を決めて conf を作り直す

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

帯を書いたら、**[手順 3](#3-wg0conf-の作成) のヒアドキュメントをもう一度貼る。** `PEER_ALLOWED` は手順 0 が組み立て直しているので、相手拠点のクライアント帯が自動で入る。**両拠点で実行する。**

拠点 B のホストで実行すると、拠点 A の peer に拠点 A のクライアント帯が入る（実測）。

```
[Peer]
# Site A
PublicKey = ByZIklVIeAJxMyzitWu6FWNPFHk1eb1/Q6ejJfsC1U0=
Endpoint = 198.51.100.1:51820
AllowedIPs = 10.99.0.1/32, 192.168.110.0/24, 10.99.1.0/24
PersistentKeepalive = 25
```

> **conf を作り直すので、登録済みのクライアントの `[Peer]` は消える。** クライアントを登録した後にこの手順をやり直した場合は、[手順 11](#11-クライアントを登録する) の `[Peer]` を足し直す（または `wg-s2s.sh apply` を使う。こちらは `clients.list` から毎回組み立てる）。

### 9. firewalld にクライアント用の policy を足す

policy の作り方は[手順 5](#5-firewalld-の設定) と同じ（新規 policy → ingress/egress ゾーン → rich rule）。**自拠点のクライアント用**と**相手拠点のクライアント用**で ingress / egress の組み合わせが違うだけなので、共通の関数にまとめて、帯が設定されている分だけ作る。

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
- rich rule は**二重引用符**で書く（[落とし穴 3](#落とし穴-3-rich-rule-を単一引用符で書くと変数が展開されない)）
- 片方向だけにしたい場合（クライアントからは拠点に入れるが、拠点からクライアントへは接続させない）は、(b)・(d)・(f) を作らない。戻りは conntrack で通る
- 待ち受けポート `${WG_PORT}/udp` は拠点間 VPN で開けてある。クライアントも同じポートに接続する

### 10. サービスの再起動

両拠点で:

```bash
sudo systemctl restart "wg-quick@$WG_IFACE"
ip route show dev "$WG_IFACE"
```

`reload` では `wg0.conf` の peer は反映されるが、**新しい peer の `AllowedIPs` に対する経路（`${CLIENT_TUN_IP}/32`、拠点 B では `${WG_A_CLIENT_NET}`）が追加されない**（[落とし穴 2](#落とし穴-2-reload-では経路が追加されない) に実測を載せた）。経路が無いとクライアント宛てのパケットがトンネルに入らない。

拠点 B 側では、クライアント帯への経路が増えているはずである（実測）。

```
10.99.0.0/30 proto kernel scope link src 10.99.0.2
10.99.1.0/24 scope link                             ← 拠点 A のクライアント帯
192.168.110.0/24 scope link
```

### 11. クライアントを登録する

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

### 12. クライアントに conf を渡す

```bash
sudo cat "/etc/wireguard/clients/$CLIENT_NAME.conf"        # PC にはこの内容をコピーする
sudo dnf install -y qrencode                               # スマートフォン用（EL10 では epel-release が要る場合がある）
sudo cat "/etc/wireguard/clients/$CLIENT_NAME.conf" | qrencode -t ansiutf8
sudo rm -f "/etc/wireguard/clients/$CLIENT_NAME.conf" "/etc/wireguard/clients/$CLIENT_NAME.key"
```

**取り込んだら、秘密鍵入りの conf と鍵をホストに残さない。** 公開鍵（`.pub`）は残しておくと、後で `wg0.conf` の `[Peer]` と突き合わせられる。

### 13. クライアント帯の静的経路を追加する

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

`${WG_TUNNEL_NET}` とクライアント帯を 1 つの大きな帯（例: `10.99.0.0/16`）の中に取っておけば、ルーターの静的経路はその帯 1 本で済む。[「WG ホスト自身から相手 LAN へ送る場合」](#wg-ホスト自身から相手-lan-へ送る場合)の問題（トンネル網への経路が無い）も同時に解消する。

### スクリプトでまとめて実行する場合

手順 1〜6 と、クライアントの追加（手順 8〜11）は [`scripts/wireguard-site-to-site/wg-s2s.sh`](../scripts/wireguard-site-to-site/wg-s2s.sh) でまとめて実行できる。**手順 0 で作った `~/wg/site.env` をそのまま読む**ので、途中からスクリプトに切り替えてもよい。

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

手動手順とスクリプトが同じ conf を作ることは、検証で `diff` して確認した（[付録](#変数形コマンドの再検証2026-09-19)）。スクリプトの検証範囲は[付録](#付録-スクリプトの検証)を参照。

---

#### クライアントを追加する場合

クライアントを追加する場合も値は同じ `~/wg/site.env` に書く。クライアントの登録簿 `clients.list`（[`clients.list.example`](../scripts/wireguard-site-to-site/clients.list.example)）は `client add` が作り、クライアントを受ける拠点のホストにあればよい。どちらも `.gitignore` で除外している。

```bash
cd scripts/wireguard-site-to-site

# 手順 8〜10: 両拠点のホストで apply する（相手 peer の AllowedIPs とクライアント用 policy が入る。restart するので一瞬切れる）
sudo ./wg-s2s.sh -e ~/wg/site.env apply A                  # 拠点 B のホストでは apply B

# 手順 11: クライアントを受ける拠点のホストで登録する（何台でも）
sudo ./wg-s2s.sh -e ~/wg/site.env client add A laptop      # 鍵を生成し、/etc/wireguard/clients/laptop.conf を書く
sudo ./wg-s2s.sh -e ~/wg/site.env client add A phone --pubkey 'クライアントから受け取った公開鍵'   # 鍵をクライアント側で作った場合
sudo ./wg-s2s.sh -e ~/wg/site.env apply A                  # 登録した [Peer] を wg0.conf に書いて restart

# 手順 12: クライアントに conf を渡す
sudo ./wg-s2s.sh -e ~/wg/site.env client show laptop --qr  # スマートフォンのアプリで読み取る（qrencode が必要）
sudo rm /etc/wireguard/clients/laptop.conf                 # 取り込んだら残さない

# 手順 13: 両拠点のルーターに静的経路を追加する
./wg-s2s.sh -e ~/wg/site.env router A

./wg-s2s.sh -e ~/wg/site.env client list
sudo ./wg-s2s.sh -e ~/wg/site.env client remove laptop && sudo ./wg-s2s.sh -e ~/wg/site.env apply A
```

手動手順との違いは、`clients.list` に登録を残すので **`apply` を何度実行しても同じ conf が組み立て直される**こと（手順 8 で conf を作り直してもクライアントの `[Peer]` が消えない）。`client add` は、帯の重複・名前や IP の重複・拠点の取り違えなどを**何かを書く前に**検査する。トンネル IP は `--ip` が無ければ帯の中で最小の空きを割り当てる。

`remove A` はクライアント用の policy も削除する。`--purge` を付けると `clients.list` にあるクライアントの conf も消す（`clients.list` 自体は残す）。

---

## 完了時点の状態（拠点 A、クライアント 1 台）

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

$ ip route show dev wg0
10.99.0.0/30 proto kernel scope link src 10.99.0.1
10.99.1.1 scope link
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

拠点間だけで使う場合（手順 7 で完成）は、`wg show` にクライアントの peer が並ばず、`ip route` に `10.99.1.1` も出ない。

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

手順 8 以降を実施した場合は、あわせて次を見る。

```bash
sudo wg show                                      # クライアントの peer に endpoint と handshake が出る
ip route show dev "$WG_IFACE"                     # クライアントの /32、拠点 B では相手のクライアント帯
sudo firewall-cmd --info-policy="$POL_MYCL_PEER"  # ingress・egress とも wireguard
```

### 拠点の LAN 上のクライアント同士で確認する

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

### 外出先のクライアントから確認する

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
| クライアントの ping に `From ${WG_A_LAN_IP} ... Packet filtered` | WG ホストの firewalld が転送を拒否している（policy 未設定、rich rule のサブネット誤り） |
| `wg show` の handshake は成立しているのに、クライアントの ping が無応答 | 相手側の firewalld policy、相手ルーターの静的経路、**相手の `ip_forward`** のいずれか。手順 4 を両拠点で実施したか確認する |
| WG ホスト自身から相手 LAN へ ping できないのに、クライアント同士は通る | 下記「[WG ホスト自身から相手 LAN へ送る場合](#wg-ホスト自身から相手-lan-へ送る場合)」 |
| クライアントから相手の**トンネル IP** へ ping すると `Destination Net Unreachable`（送信元は自拠点ルーター） | ルーターに `${WG_TUNNEL_NET}` の経路が無いため。クライアント同士の通信には不要 |
| 自拠点から張ったトンネルは動くのに、相手側から張ろうとすると失敗する | 自拠点の firewalld で `${WG_PORT}/udp` を開け忘れている、またはルーターのポート転送が無い |
| `--info-policy` の rich rule に `$MY_LAN` のような文字列が入っている | rich rule を単一引用符で書いた（[落とし穴 3](#落とし穴-3-rich-rule-を単一引用符で書くと変数が展開されない)） |
| コマンドが `--add-port=/udp` のように空の値で失敗する | `. ~/wg/wg-env.sh` を実行していないシェルでコマンドを貼った（[新しいシェルでは](#新しいシェルでは--wgwg-envsh-を先に実行する)） |
| クライアントの ping に `From ${MY_TUN_IP} ... Packet filtered` で、宛先が**相手拠点 LAN のときだけ**失敗する | `wg0 → wg0` の policy（`clientsA-to-siteB`）が無い。検証では、この policy を外すと自拠点 LAN への ping は通ったまま相手拠点 LAN だけが落ちた |
| クライアントの ping に `From ${MY_LAN_IP} ... Packet filtered` | 自拠点 LAN 向けの policy（`clientsA-to-siteA`）が無い |
| ハンドシェイクは成立するのに、相手拠点 LAN へ**まったく応答が無い**（ICMP も返らない） | 相手拠点のホストの `AllowedIPs` にクライアント帯が無い。WireGuard は範囲外の送信元を黙って捨てる。手順 8 を相手拠点でも実行したか確認する |
| クライアントを足したのに届かない。`wg show` には出ている | `reload` で済ませた。`restart` する（[落とし穴 2](#落とし穴-2-reload-では経路が追加されない)） |
| 拠点の LAN からクライアントへ接続できない（逆方向だけ失敗） | ルーターにクライアント帯の静的経路が無い、または `(b)`・`(d)`・`(f)` の policy が無い |
| クライアントから WG ホスト自身（`${MY_TUN_IP}`）に届かない | クライアント conf の `AllowedIPs` に `${WG_TUNNEL_NET}` が入っていない |
| 手順 8 をやり直したらクライアントが全部切れた | conf を作り直したので `[Peer]` が消えた。手順 11 の追記をやり直すか、`wg-s2s.sh apply` を使う |

（下 7 行は手順 8 以降を実施した場合。）

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

### `AllowedIPs` が cryptokey routing の要

`AllowedIPs` は次の 2 つの役割を持つ。

- **受信時**: トンネルから届いたパケットの送信元がこの範囲外なら捨てる
- **送信時**: この範囲宛てのパケットをこの peer に送る。**wg-quick はこの範囲をそのまま `wg0` への経路としても追加する**

そのため、相手の**トンネル IP だけでなく相手の LAN も**書く。クライアント帯を使う場合はそれも入る。本書では手順 0 の `PEER_ALLOWED` がこれを組み立てる。wg-quick 起動時のログで経路が追加されるのを確認できる（[手順 6](#6-サービスの有効化起動) の出力）。

この対応表は **1 インターフェース内で peer ごとに排他**で、1 つのアドレスを 2 つの peer に対応づけることはできない。だからクライアントは拠点に所属させ、拠点ごとに帯を分ける（[選択した方針](#選択した方針)）。

> `0.0.0.0/0` を書くと、WG ホスト自身の通信も含めてすべてがトンネルに向かう（wg-quick が policy routing で差し替える）。拠点間接続では相手 LAN だけを書く。

### ルーターの静的経路とヘアピン（非対称経路）

この構成では、Client A の最初のパケットは Router A に行き、**同じ LAN 側インターフェースへ折り返して**（ヘアピン）WG host A に届く。このとき:

- Linux ルーター（検証時の Router A）は **ICMP Redirect** を返し、それを受け入れたクライアントは以降 WG host A に直接送る（`ip route get` に `<redirected>` と出る）
- Redirect を受け入れないクライアントでは、毎回 Router A 経由のままになる
- いずれの場合も戻りのパケットは WG host A から Client A へ直接届くため、**Router A から見ると片方向しか通らない非対称経路**になる

検証では、Redirect を受け入れる場合・拒否する場合（`accept_redirects=0`）の両方で双方向 ping・TCP が通った。ただし **Router A には NAT やファイアウォールの状態追跡を持たせていない**。市販ルーターや UTM のなかには、LAN 内で折り返す転送を拒否するもの、戻りが見えない TCP セッションを途中で切るものがある。つながらない、あるいは TCP だけが不安定な場合は、ルーター側で折り返し転送を許可する設定を探すか、次の代替策をとる。

- **(a) クライアントに経路を追加する** — 通信するクライアントにだけ `${SITE_B_LAN} via ${WG_A_LAN_IP}` を入れる。ルーターを通らないので非対称経路も起きない。台数が多いと管理が大変になる（DHCP option 121 を配布できるルーターなら一括で配れる）
- **(b) WG ホストで NAT する（masquerade）** — 相手拠点から届いた通信の送信元を WG ホストの IP に書き換えれば、戻りは WG ホスト宛てになるので、自拠点ルーターの静的経路は不要になる。ただし **(1) 送信元のクライアントが相手からは区別できなくなり、(2) NAT した側への着信はできない**（片方向になる）。双方向に通信するという今回の要件は満たせないので、**最後の手段**としてだけ使う。本書では未検証

### ルーターにはクライアント帯の静的経路も要る

NAT をしない構成なので、LAN 側ホストの返事はデフォルトゲートウェイ（ルーター）に向かう。ルーターがクライアント帯を知らないと、そこで行き場を失う。**両拠点のルーター**に要る。`${WG_TUNNEL_NET}` とクライアント帯を 1 つの大きな帯に取っておけば、静的経路は 1 本で済む。

### 相手拠点のホストが帯を知らないと黙って捨てる

WireGuard は、`AllowedIPs` の範囲外から届いたパケットを **ICMP も返さずに**捨てる。相手拠点のホストの `AllowedIPs` にクライアント帯が入っていないと、ハンドシェイクも転送も正常に見えたまま届かない。手順 8 を**両拠点で**実行すること。

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

### 1 台のクライアントは 1 つの拠点にしか接続できない

cryptokey routing の制約（[`AllowedIPs` が cryptokey routing の要](#allowedips-が-cryptokey-routing-の要)）。両拠点に同時に直接つなぐ構成は成立しない。接続先を変えたい場合は、その拠点用の conf を別に作って切り替える（トンネル IP も別の帯のものになる）。

### 着信を受けられない拠点はクライアントを受けられない

クライアントは `Endpoint` を指定して接続しに行くので、接続先拠点にはグローバル IP（または DDNS 名）とポート転送が要る。CGNAT の拠点（`SITE_x_PUBLIC` が空）では `WG_x_CLIENT_NET` も空にする。

### クライアントが拠点の LAN 内にいるとき

ノート PC を持ち帰って拠点 A の LAN 内で VPN を張ると、`${SITE_A_PUBLIC}` 宛ての通信が自拠点のルーターに出て折り返す（ヘアピン）。ルーターが対応していないと接続できない。LAN 内では VPN を切る運用にするのが簡単。

### クライアントの秘密鍵の扱い

ホスト側で鍵を作ると、秘密鍵入りの conf が一時的にホストに残る。**クライアントに取り込んだら消す**（手順 12）。より厳密にするなら、クライアント側で鍵を作って公開鍵だけをホストに渡す。

### `DNS =` を書く場合

クライアント conf の `[Interface]` に `DNS = ${WG_CLIENT_DNS}` を書くと、VPN 接続中の名前解決を拠点側の DNS に向けられる。Linux の `wg-quick` はこのとき `resolvconf` を呼ぶので、`systemd-resolved` が有効である必要がある（EL10 では `wireguard-tools` の依存で入るが **disabled のまま**なので、使うなら `systemctl enable --now systemd-resolved`）。公式アプリ（Windows / macOS / iOS / Android）では追加の設定は要らない。本書の検証では `DNS =` を使っていない。

### 全トラフィックを VPN 経由にする場合（対象外）

クライアント conf の `AllowedIPs` を `0.0.0.0/0` にすると、そのクライアントの通信がすべてトンネルに入る。拠点側で NAT（masquerade）と外向きの policy が追加で要る。本書の構成（拠点の LAN にだけ届く）とは別物なので扱わない。

### クライアント同士を通す場合

クライアント A → クライアント B は、どちらも同じ `wg0` にぶら下がる `wg0 → wg0` の転送になる。`clientsA-to-siteB` と同じ形の policy（ingress・egress とも `wireguard`、送信元・宛先ともクライアント帯）を足せば通せる。本書では作らない（必要になる場面が少なく、クライアント同士を隔離しておくほうが安全なため）。

### Endpoint に DDNS 名を書く場合

`Endpoint` のホスト名は **`wg-quick up` の時点で一度だけ名前解決される**（`wg(8)` の仕様）。相手のグローバル IP が変わると、再起動するまで古い IP に送り続ける。対策:

- `wireguard-tools` 同梱の `/usr/share/doc/wireguard-tools/contrib/reresolve-dns/reresolve-dns.sh` を systemd timer で定期実行する
- 片側だけでも固定 IP にし、そちらを常に接続を受ける側にする（上記の CGNAT 構成と同じ形）。動的 IP の側が張りに行くので、その側の IP が変わっても、固定 IP の側は新しい送信元を endpoint として覚え直す

クライアント conf の `Endpoint` に DDNS 名を書いた場合も同じだが、**公式アプリは接続のたびに名前解決する**ので `reresolve-dns.sh` のような仕組みは要らない。本書では未検証。

### MTU

wg-quick は wg0 の MTU を既定で **1420** にする（IPv4/IPv6 の外側ヘッダー分を引いた値）。PPPoE（MTU 1454 / 1492 など）の回線では、トンネル内の最大サイズの通信だけが通らないことがある（ping は通るが、大きなファイル転送や一部の HTTPS が止まる）。その場合は `site.env` の `WG_MTU` に `1380` などと書き、手順 3 のヒアドキュメントの `[Interface]` に `MTU = ${WG_MTU}` の行を足してから貼り直し、`systemctl restart wg-quick@wg0` する。外出先のクライアントでも、モバイル回線によっては同じことが起きる（クライアント conf の `[Interface]` に `MTU =` を書く）。本書の検証環境（MTU 1500 の veth）ではこの問題は起きていない。

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

### クライアント 1 台だけ削除する

クライアントを受ける拠点のホストで:

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

### クライアント機能をやめて拠点間だけに戻す

両拠点で:

```bash
vi ~/wg/site.env        # WG_A_CLIENT_NET / WG_B_CLIENT_NET を空にする
. ~/wg/wg-env.sh

# 手順 3 のヒアドキュメントを貼り直す（相手 peer からクライアント帯が消え、クライアントの [Peer] も消える）

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
- ルーターのクライアント帯の静的経路も削除する

### 拠点間 VPN ごと全部消す

各拠点の WG ホストで（クライアント用の policy もまとめて消える）:

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

- [wg(8)](https://man7.org/linux/man-pages/man8/wg.8.html) / [wg-quick(8)](https://man7.org/linux/man-pages/man8/wg-quick.8.html) — `AllowedIPs` と cryptokey routing
- [WireGuard: Quick Start](https://www.wireguard.com/quickstart/)
- [WireGuard: Conceptual Overview](https://www.wireguard.com/#cryptokey-routing)
- [firewalld: Policy Objects](https://firewalld.org/2020/09/policy-objects-introduction)
- [firewalld ソース `src/firewall/core/io/policy.py`](https://github.com/firewalld/firewalld/blob/v2.4.3/src/firewall/core/io/policy.py) — ingress/egress ゾーンの検証（同一ゾーンを拒否する規則は無い。policy 名の上限は 128 文字）

---

# 付録: network namespace による検証

## ラボの構成

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

## 拠点間の実測結果

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

## リモートクライアントの検証（2026-09-19）

[上のラボ](#ラボの構成)に、外出先クライアントの namespace（`clientR`）を 1 つ足して検証した。WAN セグメントをブリッジにし、`clientR` を `198.51.100.3` として置いている（拠点 A のグローバル IP `198.51.100.1` に接続する）。拠点 A だけがクライアントを受ける構成（`WG_A_CLIENT_NET=10.99.1.0/24`、`WG_B_CLIENT_NET` は空）。

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

## 後片付け

namespace・ブリッジ・経路を削除し、[ロールバック](#ロールバック)の手順で wg-quick・鍵・sysctl・firewalld を戻した。`/etc/firewalld` を作業前のバックアップと `diff -r` で比べ、差分が無いことを確認した（削除で生成された `*.xml.old` は手で消した）。`wireguard-tools` と `systemd-resolved` はインストールしたまま残している。

# 付録: スクリプトの検証

## 実機でのドライラン

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

その後、リモートクライアント対応を加えた版は、`firewall-cmd` などを模したスタブ環境で `apply` / `remove` の本実行と再実行（設定が重複しないこと）まで確認した（[スタブ環境での本実行](#スタブ環境での本実行)）。実機での適用は引き続き未確認。

## スタブ環境での本実行

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

このスタブ検証で未確認だった「実機での `firewall-cmd`（ingress と egress が同じゾーンの policy）」「`wg-quick` がクライアント peer の `/32` 経路を追加すること」「クライアントからの疎通」は、2026-09-19 の network namespace 検証で確認した（[リモートクライアントの検証](#リモートクライアントの検証2026-09-19)）。スクリプト自体の実機での `apply` 本実行は引き続き未確認。
