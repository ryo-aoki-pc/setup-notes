# WireGuard 拠点間 VPN へのリモートクライアント追加手順（road warrior / wg-quick + firewalld）

- **目的**: [拠点間 VPN](wireguard-site-to-site.md) に、外出先のノート PC やスマートフォンなど**任意の台数のクライアント**を追加し、**両拠点の LAN に到達できる**ようにする
- **構成**: クライアントは拠点 A / B のどちらかの WireGuard ホストに接続する。接続先拠点の LAN へは直接、もう一方の拠点の LAN へは拠点間トンネルを経由して届く。拠点ごとにクライアント用のアドレス帯を持つ
- **設定方式**: 拠点間 VPN と同じ（`wg-quick` + systemd、firewalld の専用ゾーン + policy）。既存の `wg0` に `[Peer]` を足すだけで、インターフェースも待ち受けポートも増やさない
- **状態**: **実機・network namespace での疎通確認はまだしていない。** スクリプトは shellcheck と、`firewall-cmd`・`systemctl`・`ip` を模したスタブ環境での実行（ドライラン・本実行とも）まで確認した（[付録](#付録-スクリプトの検証スタブ環境)）。設計は拠点間 VPN の実測結果（`AllowedIPs` による経路追加、policy による転送制御、reload の挙動）から導いている。実機で確認したら本書を更新する
- **スクリプト**: 拠点間 VPN と同じ [`scripts/wireguard-site-to-site/wg-s2s.sh`](../scripts/wireguard-site-to-site/wg-s2s.sh) の `client` コマンドで行う（[スクリプトで実行する場合](#スクリプトで実行する場合)）

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-16 |
| WG ホスト | 拠点間 VPN の手順書と同じ環境を前提にする（AlmaLinux 10.2 / wireguard-tools 1.0.20250521 / firewalld 2.4.3） |
| クライアント | WireGuard 公式アプリ（Windows / macOS / iOS / Android）または `wg-quick`（Linux）を想定 |
| 前提 | [拠点間 VPN](wireguard-site-to-site.md) が構築済み、または同時に構築する |

> **注記**: プレースホルダは拠点間 VPN の手順書のものに加えて次を使う。例は検証で使った値。
>
> | プレースホルダ | 意味 | 例（検証時の値） |
> |---|---|---|
> | `<WG_A_CLIENT_NET>` / `<WG_B_CLIENT_NET>` | 各拠点に接続するクライアントに割り当てるトンネル内のアドレス帯（**LAN・`<WG_TUNNEL_NET>`・互いに重複不可**、`/30` より広く） | `10.99.1.0/24` / `10.99.2.0/24` |
> | `<WG_CLIENT_DNS>` | クライアント用 conf に書く DNS サーバー（任意） | `192.168.110.1` |
> | `<CLIENT_NAME>` | クライアントの名前（英数字・`-`・`_`） | `laptop` |
> | `<CLIENT_TUN_IP>` | クライアントのトンネル IP（`<WG_x_CLIENT_NET>` の中） | `10.99.1.1` |
> | `<CLIENT_PUBKEY>` / `<CLIENT_PRIVATE_KEY>` | クライアントの鍵ペア | （`wg genkey` / `wg pubkey` の出力） |
>
> クライアントを受けない拠点の `<WG_x_CLIENT_NET>` は空にする（片方の拠点だけで受けるハブ構成になる）。

---

## 構成

```
  外出先                                   拠点 A                                            拠点 B
 [Remote client] ═══ Internet ═══ [Router A] ─┬─ [WG host A] ══ 拠点間トンネル <WG_TUNNEL_NET> ══ [WG host B] ─┬─ [Router B]
 <CLIENT_TUN_IP>   (UDP <WG_PORT>,            │   wg0 <WG_A_TUN_IP>                          wg0 <WG_B_TUN_IP>  │
 ∈ <WG_A_CLIENT_NET>  ポート転送は拠点間と共用) └─ [Client A] <SITE_A_LAN>                   <SITE_B_LAN> [Client B] ─┘
```

拠点 A のクライアントは、拠点間 VPN のためにルーター A に入れたポート転送（`<WG_PORT>/udp` → WG host A）をそのまま使って WG host A に接続する。WG host A から見ると、拠点 B の peer とクライアントの peer が同じ `wg0` に並ぶ。

### パケットの流れ

**Remote client → Client A（接続先拠点の LAN）**

1. クライアントは宛先 `<SITE_A_LAN>` を `AllowedIPs` に持つので、暗号化して `<SITE_A_PUBLIC>:<WG_PORT>` へ送る
2. Router A のポート転送で WG host A に届き、復号される。送信元 `<CLIENT_TUN_IP>` はそのクライアントの `[Peer]` の `AllowedIPs` に含まれるので受け入れられる
3. WG host A は `wg0` → LAN 側 NIC に転送する（policy `clientsA-to-siteA`）
4. 戻りは Client A → デフォルトゲートウェイの Router A → **静的経路 `<WG_A_CLIENT_NET>` via `<WG_A_LAN_IP>`** → WG host A（policy `siteA-to-clientsA`）→ ハンドシェイクで覚えたクライアントの endpoint へ

**Remote client → Client B（もう一方の拠点の LAN）**

1. WG host A で復号された後、宛先 `<SITE_B_LAN>` は `wg0` 向きの経路（拠点 B の peer の `AllowedIPs`）に当たるので、**同じ `wg0` から**拠点 B の peer へ再び暗号化して出て行く（policy `clientsA-to-siteB`。ingress・egress とも `wireguard` ゾーン）
2. WG host B で復号される。送信元 `<CLIENT_TUN_IP>` は**拠点 A の peer の `AllowedIPs` に `<WG_A_CLIENT_NET>` が入っていて初めて**受け入れられる。入っていなければ、WireGuard は ICMP も返さず黙って捨てる
3. WG host B は LAN 側に転送する（policy `clientsA-to-siteB`。こちらは `wireguard` → `<LAN_ZONE>`）
4. 戻りは Client B → Router B → **静的経路 `<WG_A_CLIENT_NET>` via `<WG_B_LAN_IP>`** → WG host B（`<WG_A_CLIENT_NET>` の経路は `wg0` 向き。policy `siteB-to-clientsA`）→ 拠点間トンネル → WG host A（`<CLIENT_TUN_IP>/32` の経路は `wg0` 向き。policy `siteB-to-clientsA`）→ クライアント

したがって、拠点間 VPN に加えて必要なのは次のとおり。

| 場所 | 追加で必要な設定 |
|---|---|
| WG ホスト（クライアントを受ける拠点） | クライアントごとの `[Peer]`（`AllowedIPs` = そのクライアントの `/32`）、policy 4 つ（クライアント帯 ⇔ 自拠点 LAN、クライアント帯 ⇔ 相手拠点 LAN） |
| WG ホスト（もう一方の拠点） | 拠点間 peer の `AllowedIPs` に相手拠点のクライアント帯を追加、policy 2 つ（相手拠点のクライアント帯 ⇔ 自拠点 LAN） |
| 両拠点のルーター | **クライアント帯 via WG ホスト**の静的経路（両拠点の帯とも） |
| クライアント | conf を取り込む（`AllowedIPs` = 両拠点の LAN + `<WG_TUNNEL_NET>`） |

## 選択した方針

- **クライアントは拠点に所属させ、拠点ごとにアドレス帯を分ける** — WireGuard はインターフェースごとに「この宛先はこの peer」という対応表（cryptokey routing）を持ち、**1 つのアドレスを 2 つの peer に対応づけることはできない**。WG host B から見ると拠点 A のクライアントはすべて拠点 A の peer の向こうにいるので、帯をまとめて `AllowedIPs` に 1 行書けばよく、クライアントを追加しても拠点 B 側の設定は変わらない。同じクライアントを両拠点に直接つなげる構成にすると、各ホストでそのクライアントの IP を「直接の peer」と「相手拠点の peer」の両方に書くことになり成立しない。片方の拠点だけで受けたい場合は、もう一方の帯を空にする
- **既存の `wg0` に peer を足す** — インターフェースを分けると待ち受けポート・ポート転送・ゾーンが増える。拠点間 VPN の「専用ゾーン + policy」の枠組みをそのまま広げるほうが見通しがよい
- **NAT しない**（拠点間 VPN と同じ） — 送信元がクライアントのトンネル IP のまま LAN に届くので、LAN 側で識別・制限できる。その代わり、**両拠点のルーターにクライアント帯の静的経路が要る**（[注意点](#ルーターにはクライアント帯の静的経路も要る)）
- **転送は方向ごとの policy で絞る** — `wg0` から入って `wg0` へ折り返す転送（クライアント → 相手拠点 LAN）は、ingress と egress に同じ `wireguard` ゾーンを指定した policy で許可する。ゾーンの `forward` オプション（`--add-forward`）でも通せるが、それだと `wg0` 内の転送がすべて通る（クライアント同士など）。firewalld のソース（`core/io/policy.py`）には ingress と egress が同じゾーンであることを拒否する検証は無く、nftables への展開も iifname → oifname の 2 段で振り分けるので `wg0`/`wg0` の組も対象になる（**実機では未確認**）
- **クライアントの conf はホスト側で生成し、QR コードかファイルで渡す** — スマートフォンではこれが実用的。秘密鍵を拠点の外で作りたい場合は `client add --pubkey` で公開鍵だけを登録できる
- **反映は `apply`（restart）で行う** — 新しい peer の `AllowedIPs` に対する経路は reload では追加されない（[拠点間 VPN の落とし穴 2](wireguard-site-to-site.md#落とし穴-2-reload-では経路が追加されない) と同じ機構）。まとめて登録してから 1 回 restart する運用にする
- **クライアント同士の通信と、全トラフィックの VPN 経由（`0.0.0.0/0`）は対象外** — 必要なら[注意点](#クライアント同士を通す場合)を参照

---

## 構築手順

### スクリプトで実行する場合

値は拠点間 VPN と同じ `site.env` に書く（[`site.env.example`](../scripts/wireguard-site-to-site/site.env.example) の「リモートクライアント」の項）。**両拠点で同じ `site.env` を使う。** クライアントの登録簿 `clients.list`（[`clients.list.example`](../scripts/wireguard-site-to-site/clients.list.example)）は `client add` が作り、クライアントを受ける拠点のホストにあればよい。どちらも `.gitignore` で除外している。

```bash
cd scripts/wireguard-site-to-site
vi site.env        # WG_A_CLIENT_NET / WG_B_CLIENT_NET（必要なら WG_CLIENT_DNS）を書き、両拠点に置く

# 1. 両拠点のホストで apply する（相手 peer の AllowedIPs とクライアント用 policy が入る。restart するので拠点間トンネルが一瞬切れる）
sudo ./wg-s2s.sh --dry-run apply A
sudo ./wg-s2s.sh apply A                                   # 拠点 B のホストでは apply B

# 2. クライアントを受ける拠点のホストで登録する（何台でも）
sudo ./wg-s2s.sh client add A laptop                       # 鍵を生成し、/etc/wireguard/clients/laptop.conf を書く
sudo ./wg-s2s.sh client add A phone --pubkey '<CLIENT_PUBKEY>'   # 鍵をクライアント側で作った場合。--ip でトンネル IP も指定できる
sudo ./wg-s2s.sh apply A                                   # 登録したクライアントの [Peer] を wg0.conf に書いて restart

# 3. クライアントに conf を渡す
sudo ./wg-s2s.sh client show laptop --qr                   # スマートフォンのアプリで読み取る（qrencode が必要）
sudo ./wg-s2s.sh client show laptop                        # PC には内容をコピーする
sudo rm /etc/wireguard/clients/laptop.conf                 # 取り込んだら、秘密鍵入りの conf をホストに残さない

# 4. 両拠点のルーターに静的経路を追加する（router / apply の出力にクライアント帯の分が増えている）
./wg-s2s.sh router A

./wg-s2s.sh client list                                    # 登録一覧。root で実行すれば最終ハンドシェイクも出る
sudo ./wg-s2s.sh client remove laptop && sudo ./wg-s2s.sh apply A   # 削除も apply で反映する
```

`client add A NAME` の動作:

- **何かを書く前に検査する。** 1 つでも失敗したら何も変更しない
  - `site.env` の検査（拠点間 VPN と同じ）に加え、クライアント帯の形式と、LAN・トンネル網・もう一方の帯との重複
  - `clients.list` の全行（4 列か、拠点が A/B か、IP が所属拠点の帯に含まれるか、名前・IP・公開鍵が重複していないか）
  - `WG_A_CLIENT_NET` と `SITE_A_PUBLIC` が空でないこと（着信を受けられない拠点にクライアントは接続できない）
  - このホストが拠点 A の WG ホストであること（`WG_A_LAN_IP` を持つか）
  - 名前の重複、`--ip` が帯の中で未使用か、`--pubkey` が形式どおりで未登録か
- トンネル IP は `--ip` が無ければ帯の中で最小の空きアドレスを割り当てる
- 鍵は `wg genkey` で作る（`--pubkey` のときは作らない）。`/etc/wireguard/clients/NAME.conf` を 0600 で書き、`clients.list` に `NAME A IP 公開鍵` の行を追記する。秘密鍵は画面に出さない（`client show` だけが出す）
- 拠点 A の公開鍵は `site.env` の `SITE_A_PUBKEY`、空なら `/etc/wireguard/wg0.key` から算出する。両方あって食い違えば止まる

`apply` に増えた動作:

- 相手拠点の帯が設定されていれば、相手 peer の `AllowedIPs` に加える（`10.99.0.2/32, 192.168.120.0/24, 10.99.2.0/24`）
- `clients.list` にある自拠点のクライアントごとに `[Peer]` を書く
- 設定されている帯に応じて policy を作る（[手動手順の 5](#5-firewalld-の設定) と同じ 6 つ。既存の policy には手を加えない）
- `router` の出力にクライアント帯の静的経路が増える
- `--use-existing-conf` のときは conf に触らない。相手 peer に相手拠点の帯が無ければ**警告**し、自拠点にクライアントが登録されていれば追加すべき `[Peer]` ブロックを表示する

`remove A` はクライアント用の policy も削除する。`--purge` を付けると `clients.list` にあるクライアントの conf も消す（`clients.list` 自体は残す）。

### 手動で実施する場合

コマンドは「拠点 A でクライアントを受ける」場合で書く。拠点 B でも受けるなら、A と B を入れ替えてもう一度行う。

### 1. アドレス帯を決める

拠点ごとにクライアント用の帯を 1 つ決める（例: `<WG_A_CLIENT_NET>` = `10.99.1.0/24`）。LAN・`<WG_TUNNEL_NET>` と重ならないこと。`<WG_TUNNEL_NET>`（`/30`）は変えない。

### 2. WG ホストの `wg0.conf`

拠点 A（クライアントを受ける側）。クライアント 1 台につき `[Peer]` を 1 つ足す:

```ini
[Peer]
# Client <CLIENT_NAME>
PublicKey = <CLIENT_PUBKEY>
AllowedIPs = <CLIENT_TUN_IP>/32
```

- `Endpoint` は書かない（クライアントの場所は変わる。ハンドシェイクを受けた送信元を endpoint として覚える）
- `PersistentKeepalive` も不要（クライアント側に書く）

拠点 B（もう一方）。拠点 A の peer の `AllowedIPs` に拠点 A のクライアント帯を足す:

```ini
[Peer]
# Site A
PublicKey = <SITE_A_PUBKEY>
Endpoint = <SITE_A_PUBLIC>:<WG_PORT>
AllowedIPs = <WG_A_TUN_IP>/32, <SITE_A_LAN>, <WG_A_CLIENT_NET>
PersistentKeepalive = 25
```

### 3. クライアントの conf

```ini
[Interface]
Address = <CLIENT_TUN_IP>/32
PrivateKey = <CLIENT_PRIVATE_KEY>
DNS = <WG_CLIENT_DNS>            # 任意

[Peer]
# Site A
PublicKey = <SITE_A_PUBKEY>
Endpoint = <SITE_A_PUBLIC>:<WG_PORT>
AllowedIPs = <SITE_A_LAN>, <SITE_B_LAN>, <WG_TUNNEL_NET>
PersistentKeepalive = 25
```

- `AllowedIPs` に `<WG_TUNNEL_NET>` を入れるのは、WG ホスト自身がクライアントに送るパケットの送信元が `wg0` のアドレス（`<WG_A_TUN_IP>`）になるため。無いとクライアント側で捨てられ、WG ホストからの ping や、ホストで動くサービスへの接続ができない
- `PersistentKeepalive` は、クライアントが NAT の内側にいるときに LAN 側から届くように NAT のマッピングを維持するためのもの。クライアントから始める通信だけなら無くても動く
- 鍵はクライアント側で `wg genkey | tee client.key | wg pubkey` として作ってもよい（公開鍵だけをホストに渡す）

### 4. IP フォワーディング

拠点間 VPN で有効化済み（`net.ipv4.ip_forward = 1`）。追加の設定は無い。

### 5. firewalld の設定

拠点 A（クライアントを受ける側）。policy はどれも拠点間 VPN と同じ作り方（新規 policy → ingress/egress ゾーン → rich rule）:

```bash
# (a) クライアント → 自拠点 LAN
sudo firewall-cmd --permanent --new-policy=clientsA-to-siteA
sudo firewall-cmd --permanent --policy=clientsA-to-siteA --add-ingress-zone=wireguard
sudo firewall-cmd --permanent --policy=clientsA-to-siteA --add-egress-zone=<LAN_ZONE>
sudo firewall-cmd --permanent --policy=clientsA-to-siteA \
  --add-rich-rule='rule family=ipv4 source address=<WG_A_CLIENT_NET> destination address=<SITE_A_LAN> accept'

# (b) 自拠点 LAN → クライアント
sudo firewall-cmd --permanent --new-policy=siteA-to-clientsA
sudo firewall-cmd --permanent --policy=siteA-to-clientsA --add-ingress-zone=<LAN_ZONE>
sudo firewall-cmd --permanent --policy=siteA-to-clientsA --add-egress-zone=wireguard
sudo firewall-cmd --permanent --policy=siteA-to-clientsA \
  --add-rich-rule='rule family=ipv4 source address=<SITE_A_LAN> destination address=<WG_A_CLIENT_NET> accept'

# (c) クライアント → 相手拠点 LAN（wg0 から入って wg0 へ折り返す。ingress・egress とも wireguard）
sudo firewall-cmd --permanent --new-policy=clientsA-to-siteB
sudo firewall-cmd --permanent --policy=clientsA-to-siteB --add-ingress-zone=wireguard
sudo firewall-cmd --permanent --policy=clientsA-to-siteB --add-egress-zone=wireguard
sudo firewall-cmd --permanent --policy=clientsA-to-siteB \
  --add-rich-rule='rule family=ipv4 source address=<WG_A_CLIENT_NET> destination address=<SITE_B_LAN> accept'

# (d) 相手拠点 LAN → クライアント
sudo firewall-cmd --permanent --new-policy=siteB-to-clientsA
sudo firewall-cmd --permanent --policy=siteB-to-clientsA --add-ingress-zone=wireguard
sudo firewall-cmd --permanent --policy=siteB-to-clientsA --add-egress-zone=wireguard
sudo firewall-cmd --permanent --policy=siteB-to-clientsA \
  --add-rich-rule='rule family=ipv4 source address=<SITE_B_LAN> destination address=<WG_A_CLIENT_NET> accept'

sudo firewall-cmd --reload
```

拠点 B（もう一方）。拠点 A のクライアントは拠点間トンネルから届くので、`wireguard` ⇔ `<LAN_ZONE>` の policy を 2 つ作る:

```bash
# (e) 拠点 A のクライアント → 拠点 B の LAN
sudo firewall-cmd --permanent --new-policy=clientsA-to-siteB
sudo firewall-cmd --permanent --policy=clientsA-to-siteB --add-ingress-zone=wireguard
sudo firewall-cmd --permanent --policy=clientsA-to-siteB --add-egress-zone=<LAN_ZONE>
sudo firewall-cmd --permanent --policy=clientsA-to-siteB \
  --add-rich-rule='rule family=ipv4 source address=<WG_A_CLIENT_NET> destination address=<SITE_B_LAN> accept'

# (f) 拠点 B の LAN → 拠点 A のクライアント
sudo firewall-cmd --permanent --new-policy=siteB-to-clientsA
sudo firewall-cmd --permanent --policy=siteB-to-clientsA --add-ingress-zone=<LAN_ZONE>
sudo firewall-cmd --permanent --policy=siteB-to-clientsA --add-egress-zone=wireguard
sudo firewall-cmd --permanent --policy=siteB-to-clientsA \
  --add-rich-rule='rule family=ipv4 source address=<SITE_B_LAN> destination address=<WG_A_CLIENT_NET> accept'

sudo firewall-cmd --reload
```

- policy 名は両拠点で同じにしてある（`clientsA-to-siteB` は、拠点 A では `wireguard → wireguard`、拠点 B では `wireguard → <LAN_ZONE>`）。通信の向きで名前を付け、ゾーンはホストごとに違う
- 片方向だけにしたい場合（クライアントからは拠点に入れるが、拠点からクライアントへは接続させない）は、(b)・(d)・(f) を作らない。戻りは conntrack で通る
- 待ち受けポート `<WG_PORT>/udp` は拠点間 VPN で開けてある。クライアントも同じポートに接続する

### 6. サービスの再起動

両拠点で:

```bash
sudo systemctl restart wg-quick@wg0
```

`reload` では `wg0.conf` の peer は反映されるが、**新しい peer の `AllowedIPs` に対する経路（`<CLIENT_TUN_IP>/32 dev wg0`、拠点 B では `<WG_A_CLIENT_NET> dev wg0`）が追加されない**。経路が無いとクライアント宛てのパケットがトンネルに入らない。

### 7. 拠点ルーターの設定

| 設定 | 拠点 A のルーター | 拠点 B のルーター |
|---|---|---|
| 静的経路（追加） | 宛先 `<WG_A_CLIENT_NET>` → ゲートウェイ `<WG_A_LAN_IP>` | 宛先 `<WG_A_CLIENT_NET>` → ゲートウェイ `<WG_B_LAN_IP>` |
| 静的経路（拠点 B でも受ける場合） | 宛先 `<WG_B_CLIENT_NET>` → ゲートウェイ `<WG_A_LAN_IP>` | 宛先 `<WG_B_CLIENT_NET>` → ゲートウェイ `<WG_B_LAN_IP>` |
| ポート転送 | 変更なし（拠点間 VPN のものを共用） | 変更なし |

`<WG_TUNNEL_NET>` とクライアント帯を 1 つの大きな帯（例: `10.99.0.0/16`）の中に取っておけば、ルーターの静的経路はその帯 1 本で済む。拠点間 VPN の[「WG ホスト自身から相手 LAN へ送る場合」](wireguard-site-to-site.md#wg-ホスト自身から相手-lan-へ送る場合)の問題（トンネル網への経路が無い）も同時に解消する。

---

## 検証方法（想定。実機では未実施）

### WG ホストで確認する

```bash
sudo wg show                                 # クライアントの peer に latest handshake が出る（接続中のもの）
ip route show dev wg0                        # 拠点 A: <CLIENT_TUN_IP>/32 が並ぶ。拠点 B: <WG_A_CLIENT_NET> がある
sudo firewall-cmd --list-all-policies        # clients*-to-site* / site*-to-clients* の rich rule
./wg-s2s.sh client list                      # 登録簿と最終ハンドシェイク（root で実行）
```

### クライアントから確認する

```bash
ping <Client A の IP>          # 接続先拠点の LAN
ping <Client B の IP>          # もう一方の拠点の LAN（拠点間トンネル経由）
ping <WG_A_TUN_IP>             # WG host A 自身（AllowedIPs に <WG_TUNNEL_NET> を入れた効果）
tracepath -n <Client B の IP>  # <WG_A_TUN_IP> → <WG_B_TUN_IP> → Client B の順に出るはず
```

### 症状と原因の対応（想定）

| 症状 | 調べる順番 |
|---|---|
| `wg show` に latest handshake が出ない | クライアント conf の `Endpoint`・公開鍵、ルーター A のポート転送、WG host A の firewalld の `<WG_PORT>/udp`（拠点間 VPN と同じ） |
| ハンドシェイクは成立するが、接続先拠点の LAN に届かない | WG host A の policy (a)、ルーター A の静的経路（クライアント帯）、`ip route show dev wg0` に `/32` があるか（reload だけで済ませていないか） |
| 接続先拠点の LAN には届くが、もう一方の拠点の LAN に届かない | WG host A の policy (c)、**WG host B の拠点 A peer の `AllowedIPs` に `<WG_A_CLIENT_NET>` があるか**（無いと黙って捨てられ、`wg show` の transfer も増えない）、WG host B の policy (e)、ルーター B の静的経路 |
| LAN 側からクライアントに接続できない（クライアントからは通る） | policy (b)/(d)/(f)、ルーターの静的経路、クライアントの `PersistentKeepalive`（NAT の内側にいるとき） |
| WG ホストからクライアントに ping できない | クライアント conf の `AllowedIPs` に `<WG_TUNNEL_NET>` が無い |

---

## 注意点

### 新しいクライアントの経路は reload では入らない

拠点間 VPN の[落とし穴 2](wireguard-site-to-site.md#落とし穴-2-reload-では経路が追加されない) と同じ。`wg syncconf` は peer と `AllowedIPs` を差し替えるが `ip route` は触らない。クライアントを足したら `systemctl restart wg-quick@wg0`（スクリプトでは `apply`）を使う。restart で拠点間トンネルが一瞬切れるので、複数のクライアントはまとめて登録してから 1 回 restart する。

### ルーターにはクライアント帯の静的経路も要る

NAT しない構成なので、LAN 側ホストから見た通信相手はクライアントのトンネル IP（`<WG_x_CLIENT_NET>` の中）になる。LAN 側ホストはその帯への経路を持たないので、返事はデフォルトゲートウェイのルーターに向かう。ルーターに「クライアント帯 via WG ホスト」の静的経路が無いと、行きは届くのに戻りが返らない。**もう一方の拠点のルーターにも要る**（相手拠点のクライアントの帯は、相手拠点ホストではなく自拠点の WG ホスト向き）。

ルーターに静的経路を入れられない場合の代替は、拠点間 VPN の[同名の節](wireguard-site-to-site.md#ルーターに静的経路を入れられない場合)と同じ（クライアント側に経路を入れる、または WG ホストで masquerade する）。

### 相手拠点のホストが帯を知らないと黙って捨てる

WireGuard は、復号したパケットの送信元がその peer の `AllowedIPs` に無ければ ICMP を返さずに捨てる。拠点 B のホストの拠点 A peer に `<WG_A_CLIENT_NET>` が無いと、拠点 A のクライアントから拠点 B への通信は、ハンドシェイクも転送も正常に見えたまま届かない。スクリプトは `--use-existing-conf` のとき、この不足を警告する。

### 1 台のクライアントは 1 つの拠点にしか接続できない

[方針](#選択した方針)のとおり、`AllowedIPs` の排他による。拠点を変えるときは `client remove` して、もう一方の拠点で `client add` し直す（IP も鍵も変わる）。

### 着信を受けられない拠点はクライアントを受けられない

`<SITE_x_PUBLIC>` が空の拠点（CGNAT など）は、拠点間 VPN でも自分から張りに行く側になっている。クライアントも同様に接続できないので、もう一方の拠点に登録する。スクリプトは `client add` を拒否する。

### クライアントが拠点の LAN 内にいるとき

クライアント conf の `AllowedIPs` に `<SITE_A_LAN>` が入っているので、拠点 A の LAN 内で VPN を有効にすると LAN 宛ての通信が `wg0` に向かい、近くのホストにも届かなくなる。LAN 内では VPN を切る。常時接続にしたい端末は、`AllowedIPs` から自拠点 LAN を外した conf を別に用意する（その conf では自拠点 LAN へは直接、相手拠点 LAN へは VPN 経由になる）。

### 秘密鍵の扱い

- `client add` が作る `/etc/wireguard/clients/NAME.conf` にはクライアントの秘密鍵が入る。端末に取り込んだら削除する（`client show` は conf を読むだけなので、削除後は表示できない。再発行は `client remove` → `client add`）
- 拠点の外に秘密鍵を出したくない場合は、クライアント側で `wg genkey` し、公開鍵だけを `client add --pubkey` で登録する。conf の `PrivateKey` は `<CLIENT_PRIVATE_KEY>` のままになるので、クライアント側で置き換える
- `clients.list` には公開鍵と割り当て IP しか無いが、環境固有の値なのでコミットしない（`.gitignore` 済み）

### `DNS =` を書く場合

`WG_CLIENT_DNS` を設定するとクライアント conf に `DNS =` が入る。公式アプリはそのまま使う。Linux の `wg-quick` は `resolvconf` コマンドを呼ぶので、EL10 では `systemd-resolved` が動いている必要がある（拠点間 VPN の[手順 1](wireguard-site-to-site.md#1-パッケージのインストール)の注記）。

### 全トラフィックを VPN 経由にする場合（対象外）

クライアントの `AllowedIPs` を `0.0.0.0/0` にすると、インターネット向けの通信も WG ホストに届く。通すには WG ホストで `wireguard` → `<LAN_ZONE>` の masquerade（または拠点ルーターにクライアント帯の経路 + ルーターの NAT）が必要で、本書の「NAT しない」方針の外になる。未検証。

### クライアント同士を通す場合

既定では、同じ拠点のクライアント同士も policy が無いので通らない（firewalld が `admin-prohibited` で拒否する）。通すには、ingress・egress とも `wireguard` の policy に `source address=<WG_A_CLIENT_NET> destination address=<WG_A_CLIENT_NET>` の rich rule を足し、クライアント conf の `AllowedIPs` に `<WG_A_CLIENT_NET>` を加える。未検証。

### Endpoint の DDNS 名・MTU

拠点間 VPN の[注意点](wireguard-site-to-site.md#endpoint-に-ddns-名を書く場合)と同じ。クライアント側の `Endpoint` の名前解決はアプリが接続のたびに行うが、`wg-quick` では起動時の一度だけになる。PPPoE 回線で大きな転送だけが止まる場合は、クライアント conf の `[Interface]` に `MTU = 1380` などを書く。

---

## ロールバック

クライアント 1 台:

```bash
sudo ./wg-s2s.sh client remove <CLIENT_NAME>
sudo ./wg-s2s.sh apply A
```

クライアント機能をやめて拠点間 VPN だけに戻す（両拠点で）:

```bash
# 登録簿を空にし（または clients.list を削除し）、site.env の WG_A_CLIENT_NET / WG_B_CLIENT_NET を空にしてから
sudo ./wg-s2s.sh apply A                    # conf からクライアントの [Peer] と相手 peer のクライアント帯が消える

# apply は policy を消さないので、クライアント用の policy は手で削除する（拠点 A の例。存在するものだけ）
sudo firewall-cmd --permanent --delete-policy=clientsA-to-siteA
sudo firewall-cmd --permanent --delete-policy=siteA-to-clientsA
sudo firewall-cmd --permanent --delete-policy=clientsA-to-siteB
sudo firewall-cmd --permanent --delete-policy=siteB-to-clientsA
sudo firewall-cmd --permanent --delete-policy=clientsB-to-siteA
sudo firewall-cmd --permanent --delete-policy=siteA-to-clientsB
sudo firewall-cmd --reload
sudo rm -rf /etc/wireguard/clients
```

- 拠点間 VPN ごと削除する `remove A` は、クライアント用の policy も消す。`--purge` でクライアント用 conf も消える
- ルーターのクライアント帯の静的経路も削除する

---

## 参照

- [wg(8)](https://man7.org/linux/man-pages/man8/wg.8.html) — `AllowedIPs` と cryptokey routing
- [WireGuard: Conceptual Overview](https://www.wireguard.com/#cryptokey-routing)
- [firewalld: Policy Objects](https://firewalld.org/2020/09/policy-objects-introduction)
- [firewalld ソース `src/firewall/core/io/policy.py`](https://github.com/firewalld/firewalld/blob/v2.4.3/src/firewall/core/io/policy.py) — ingress/egress ゾーンの検証（同一ゾーンを拒否する規則は無い。policy 名の上限は 128 文字）

---

# 付録: スクリプトの検証（スタブ環境）

作業に使えた環境には `wg` 以外の対象コマンドが無く（`firewall-cmd`・`systemctl`・`ip` が無い。network namespace も作れない）、実機も無かった。そこで、次のスタブを `PATH` の先頭に置いてスクリプトを root で実行し、**呼び出されるコマンドと生成されるファイルの内容**を確認した。

| コマンド | スタブの動作 |
|---|---|
| `firewall-cmd` | ゾーン・policy・ポート・interface・rich rule を JSON ファイルに保持する。`--query-*` はその状態で 0/1 を返し、`--new-*` / `--add-*` / `--delete-*` は状態を更新してログに残す。既にあるものを追加すると失敗する |
| `systemctl` | `is-active firewalld` は常に 0。`wg-quick@wg0` の enable / restart / disable --now を状態ファイルで追う |
| `ip` | `-o -4 addr show` で `eth0` に `<WG_A_LAN_IP>`（または `<WG_B_LAN_IP>`）を返す |
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

未確認: 実機での `firewall-cmd`（特に ingress と egress が同じゾーンの policy が受理され、`wg0 → wg0` の転送に効くこと）、`wg-quick` がクライアント peer の `/32` 経路を追加すること、クライアントからの疎通、SELinux での `/etc/wireguard/clients` の扱い、EL10 での `qrencode` パッケージの入手先。
