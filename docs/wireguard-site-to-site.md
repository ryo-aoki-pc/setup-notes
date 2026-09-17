# WireGuard 拠点間 VPN 構築手順（site-to-site / wg-quick + firewalld）

- **目的**: 2 拠点の LAN を WireGuard で結び、**拠点 A の LAN 上のクライアントと拠点 B の LAN 上のクライアントが双方向に通信できる**ようにする
- **構成**: 各拠点で、既存ルーターの配下にある AlmaLinux 1 台を WireGuard ホストにする（ルーターの置き換えはしない）
- **設定方式**: `wg-quick` + systemd（`/etc/wireguard/wg0.conf` / `wg-quick@wg0.service`）、firewalld の policy で転送を制御
- **状態**: 1 台のマシン上に network namespace で 2 拠点を模擬して動作確認済み（[付録](#付録-network-namespace-による模擬検証)）。**実際に 2 拠点をインターネット越しに結んでの確認はまだしていない**
- **スクリプト**: プレースホルダの値を 1 ファイルに書いて手順 1〜6 を実行する [`scripts/wireguard-site-to-site/`](../scripts/wireguard-site-to-site/) を用意した（[スクリプトで一括実行する場合](#スクリプトで一括実行する場合)）。**ドライランと事前検査までの確認で、実際の適用はまだ試していない**
- **拡張**: 外出先の PC・スマートフォンなど任意の台数のクライアントをこの VPN に追加する手順は [WireGuard リモートクライアント追加手順](wireguard-remote-clients.md)。同じスクリプトの `client` コマンドで行う

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-16 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64 |
| カーネル | 6.12.96（`wireguard.ko` を同梱） |
| `wireguard-tools` | 1.0.20250521-1.el10（appstream） |
| firewalld | 2.4.3 |
| NetworkManager | 1.56.0 |
| SELinux | Enforcing |

> **注記**: 環境固有の値はプレースホルダに置換してある。自環境の値に読み替えること。例は検証で使った値。
>
> | プレースホルダ | 意味 | 例（検証時の値） |
> |---|---|---|
> | `<SITE_A_LAN>` / `<SITE_B_LAN>` | 各拠点の LAN サブネット（**重複不可**） | `192.168.110.0/24` / `192.168.120.0/24` |
> | `<ROUTER_A_LAN_IP>` / `<ROUTER_B_LAN_IP>` | 各拠点ルーターの LAN 側 IP | `192.168.110.1` / `192.168.120.1` |
> | `<WG_A_LAN_IP>` / `<WG_B_LAN_IP>` | 各 WireGuard ホストの LAN 側 IP（**固定にする**） | `192.168.110.2` / `192.168.120.2` |
> | `<SITE_A_PUBLIC>` / `<SITE_B_PUBLIC>` | 各拠点ルーターのグローバル IP または DDNS 名 | `198.51.100.1` / `198.51.100.2` |
> | `<WG_TUNNEL_NET>` | トンネル内のアドレス帯 | `10.99.0.0/30` |
> | `<WG_A_TUN_IP>` / `<WG_B_TUN_IP>` | 各 wg0 のアドレス | `10.99.0.1` / `10.99.0.2` |
> | `<WG_PORT>` | WireGuard の待ち受け UDP ポート | `51820` |
> | `<LAN_ZONE>` | WireGuard ホストの LAN 側 NIC が属する firewalld ゾーン | `public` |
> | `<SITE_A_PUBKEY>` / `<SITE_B_PUBKEY>` | 各拠点の WireGuard 公開鍵 | （`wg pubkey` の出力） |
>
> 秘密鍵はこの文書に載せない。公開鍵は秘密情報ではないが、検証用に作った使い捨ての値なので載せていない。

---

## 構成

```
                 拠点 A                                                     拠点 B
 [Client A]                                                                          [Client B]
 <SITE_A_LAN>.100 ─┐                                                            ┌─ <SITE_B_LAN>.100
                   ├─ [Router A] ══ Internet (UDP <WG_PORT>) ══ [Router B] ─────┤
 [WG host A] ──────┘  <SITE_A_PUBLIC>                          <SITE_B_PUBLIC>  └────── [WG host B]
 <WG_A_LAN_IP>                                                                     <WG_B_LAN_IP>
   wg0 <WG_A_TUN_IP>  ←──────────── WireGuard トンネル <WG_TUNNEL_NET> ────────────→  wg0 <WG_B_TUN_IP>
```

### パケットの流れ（Client A → Client B）

1. Client A は宛先 `<SITE_B_LAN>` を知らないので、デフォルトゲートウェイの **Router A** に送る
2. Router A の**静的経路**（`<SITE_B_LAN>` via `<WG_A_LAN_IP>`）で **WG host A** に転送される
3. WG host A は `wg0` の経路（`AllowedIPs` から wg-quick が自動で追加する）で暗号化し、Router B のグローバル IP へ UDP で送る
4. Router B の**ポート転送**で WG host B に届き、復号されて LAN B の Client B へ
5. 戻りは逆順（Client B → Router B → WG host B → トンネル → WG host A → Client A）

したがって、各拠点で必要なのは次の 3 点。

| 場所 | 必要な設定 |
|---|---|
| WG ホスト | WireGuard（`AllowedIPs` に相手 LAN を含める）、IP フォワーディング、firewalld の転送許可 |
| 拠点ルーター | WAN → `<WG_x_LAN_IP>:<WG_PORT>/udp` の**ポート転送**、`相手 LAN` via `<WG_x_LAN_IP>` の**静的経路** |
| クライアント | 変更なし |

## 選択した方針

- **wg-quick + systemd** — 設定が 1 ファイルで完結し、情報も多い。NetworkManager は wg-quick が作った `wg0` を `connected (externally)` として扱うだけで干渉しなかった（実測）
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

### スクリプトで一括実行する場合

以下の手順 1〜6 は、[`scripts/wireguard-site-to-site/wg-s2s.sh`](../scripts/wireguard-site-to-site/wg-s2s.sh) でまとめて実行できる。値は [`site.env.example`](../scripts/wireguard-site-to-site/site.env.example) を `site.env` にコピーして書く。変数名はこの文書のプレースホルダと同じで、**両拠点で同じ `site.env` を使う**（`site.env` は `.gitignore` で除外している）。

```bash
cd scripts/wireguard-site-to-site
cp site.env.example site.env && vi site.env

# 新しく conf を作る場合
sudo ./wg-s2s.sh keygen A                 # 手順 1〜2。表示された公開鍵を site.env の SITE_A_PUBKEY に書く（拠点 B でも同様）
sudo ./wg-s2s.sh --dry-run apply A        # 実行予定の内容を確認（秘密鍵は (hidden) と表示）
sudo ./wg-s2s.sh apply A                  # 手順 3〜6 + ルーターに入れる値を表示

# 既存の wg0.conf を使う場合（conf は書き換えない。公開鍵の変数と keygen は不要）
sudo ./wg-s2s.sh --use-existing-conf --dry-run apply A
sudo ./wg-s2s.sh --use-existing-conf apply A      # site.env に WG_USE_EXISTING_CONF=1 と書いても同じ

./wg-s2s.sh router A                      # 手順 7 の値だけを表示
sudo ./wg-s2s.sh status
sudo ./wg-s2s.sh remove A                 # ロールバック（--purge で conf と鍵も削除）

# リモートクライアントの追加（site.env の WG_A_CLIENT_NET などを設定してから。詳細は wireguard-remote-clients.md）
sudo ./wg-s2s.sh client add A laptop && sudo ./wg-s2s.sh apply A
```

`apply` の動作:

- **何かを変更する前に、次を検査する。** 1 つでも失敗したら何も変更せずに止まる
  - アドレスの形式
  - LAN・トンネル網の重複
  - `WG_x_LAN_IP` がこのホストにあるか（A/B の取り違えを防ぐ）
  - 公開鍵の形式
- **conf を生成する場合**: `PrivateKey` を直接書く（[落とし穴 1](#落とし穴-1-秘密鍵を-conf-の外に出すと-reload-で消える)）。既存の conf と内容が違えば、`.bak-日時` に退避してから書く
- **既存の conf を使う場合**: conf を読むだけで、次の整合チェックを行う
  - `Address` に `WG_x_TUN_IP` が無い、または相手 LAN を `AllowedIPs` に含む `[Peer]` が無い → **停止**
  - `ListenPort` が `WG_PORT` と違う → **警告**して conf の値を使う
  - `PrivateKey` を `PostUp` で読み込んでいる、パーミッションが 600 でない → **警告**
- **firewalld**: 設定が既にあるかを確かめてから追加するので、再実行しても設定が重複しない
- **サービス**: 最後は常に `systemctl restart` する（[落とし穴 2](#落とし穴-2-reload-では経路が追加されない)）
- **LAN_ZONE**: 空なら `WG_x_LAN_IP` を持つ NIC のゾーンを自動で使う
- **CGNAT 構成**: `SITE_x_PUBLIC` を空にすると、その拠点に向けた `Endpoint` を書かない（[CGNAT の構成](#片側がグローバル-ip-を持たない場合cgnat-など)）
- **リモートクライアント**: `WG_A_CLIENT_NET` / `WG_B_CLIENT_NET` を設定すると、相手 peer の `AllowedIPs` にその帯を加え、`clients.list` に登録したクライアントの `[Peer]` とクライアント用の policy も作る（[リモートクライアント追加手順](wireguard-remote-clients.md)）。空なら本書の構成と同じ

スクリプトの検証範囲は[付録](#スクリプトの検証ドライランのみ)を参照。

### 手動で実施する場合

**手順 1〜6 は両拠点の WG ホストで実施する。** コマンドは拠点 A 用に書いてある。拠点 B では A と B を入れ替える。

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
sudo bash -c 'umask 077; wg genkey | tee /etc/wireguard/wg0.key | wg pubkey > /etc/wireguard/wg0.pub'
sudo cat /etc/wireguard/wg0.pub     # この公開鍵を相手拠点に渡す
```

- `/etc/wireguard` はパッケージが `0700` で作る。`umask 077` で鍵ファイルも `0600` になる
- 相手に渡すのは **`wg0.pub`（公開鍵）だけ**。`wg0.key` は拠点の外に出さない
- `wg0.key` は次の手順で `wg0.conf` に書き写す。書き写した後は削除してもよい（再生成すると公開鍵が変わるので、相手側の設定も変更が必要になる）

### 3. `/etc/wireguard/wg0.conf` の作成

拠点 A:

```ini
[Interface]
Address = <WG_A_TUN_IP>/30
ListenPort = <WG_PORT>
PrivateKey = <拠点 A の wg0.key の中身>

[Peer]
# Site B
PublicKey = <SITE_B_PUBKEY>
Endpoint = <SITE_B_PUBLIC>:<WG_PORT>
AllowedIPs = <WG_B_TUN_IP>/32, <SITE_B_LAN>
PersistentKeepalive = 25
```

拠点 B:

```ini
[Interface]
Address = <WG_B_TUN_IP>/30
ListenPort = <WG_PORT>
PrivateKey = <拠点 B の wg0.key の中身>

[Peer]
# Site A
PublicKey = <SITE_A_PUBKEY>
Endpoint = <SITE_A_PUBLIC>:<WG_PORT>
AllowedIPs = <WG_A_TUN_IP>/32, <SITE_A_LAN>
PersistentKeepalive = 25
```

秘密鍵を画面に表示せずに書き込むには、`PrivateKey` の行を `PrivateKey = __KEY__` にしておいて次を実行する:

```bash
sudo bash -c 'umask 077; sed -i "s|^PrivateKey = __KEY__|PrivateKey = $(cat /etc/wireguard/wg0.key)|" /etc/wireguard/wg0.conf'
sudo chmod 600 /etc/wireguard/wg0.conf
```

#### `AllowedIPs` が site-to-site の要

`AllowedIPs` は次の 2 つの役割を持つ。

- **受信時**: トンネルから届いたパケットの送信元がこの範囲外なら捨てる
- **送信時**: この範囲宛てのパケットをこの peer に送る。**wg-quick はこの範囲をそのまま `wg0` への経路としても追加する**

そのため、相手の**トンネル IP だけでなく相手の LAN も**書く。wg-quick 起動時のログで経路が追加されるのを確認できる:

```
[#] ip link add dev wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.99.0.1/30 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] ip -4 route add 192.168.120.0/24 dev wg0      ← AllowedIPs の相手 LAN
```

> `0.0.0.0/0` を書くと、WG ホスト自身の通信も含めてすべてがトンネルに向かう（wg-quick が policy routing で差し替える）。拠点間接続では相手 LAN だけを書く。

### 4. IP フォワーディングの有効化

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/90-wireguard.conf
sudo sysctl --system
```

`rp_filter` は変更不要（strict = 1 のまま動いた。相手 LAN への経路が `wg0` を向いているので、`wg0` から届く相手 LAN 発のパケットは逆経路チェックを通る）。

### 5. firewalld の設定

```bash
# (a) WireGuard の待ち受けポートを LAN 側ゾーンで開ける
sudo firewall-cmd --permanent --zone=<LAN_ZONE> --add-port=<WG_PORT>/udp

# (b) wg0 専用ゾーン
sudo firewall-cmd --permanent --new-zone=wireguard
sudo firewall-cmd --permanent --zone=wireguard --add-interface=wg0

# (c) 自拠点 LAN → 相手拠点 LAN
sudo firewall-cmd --permanent --new-policy=siteA-to-siteB
sudo firewall-cmd --permanent --policy=siteA-to-siteB --add-ingress-zone=<LAN_ZONE>
sudo firewall-cmd --permanent --policy=siteA-to-siteB --add-egress-zone=wireguard
sudo firewall-cmd --permanent --policy=siteA-to-siteB \
  --add-rich-rule='rule family=ipv4 source address=<SITE_A_LAN> destination address=<SITE_B_LAN> accept'

# (d) 相手拠点 LAN → 自拠点 LAN
sudo firewall-cmd --permanent --new-policy=siteB-to-siteA
sudo firewall-cmd --permanent --policy=siteB-to-siteA --add-ingress-zone=wireguard
sudo firewall-cmd --permanent --policy=siteB-to-siteA --add-egress-zone=<LAN_ZONE>
sudo firewall-cmd --permanent --policy=siteB-to-siteA \
  --add-rich-rule='rule family=ipv4 source address=<SITE_B_LAN> destination address=<SITE_A_LAN> accept'

sudo firewall-cmd --reload
```

- `<LAN_ZONE>` は `sudo firewall-cmd --get-zone-of-interface=<LAN側NIC>` で確認する
- `wg0` はまだ存在しなくても `--add-interface` できる。wg-quick が `wg0` を作り直しても（`systemctl restart` 後も、`--complete-reload` 後も）`wireguard` ゾーンに入ったままだった（実測）
- 片方向だけ許可したい場合（例: 拠点 A から B へは接続できるが、B から A へは接続させない）は (d) を作らない。戻りのパケットは conntrack で許可されるので、A から始めた通信は成立する
- 相手 LAN のうち特定ホスト・ポートだけに絞る場合は、rich rule の `destination address` を `/32` にする、`port port=... protocol=tcp` を付けるなどで調整する

**(a) はトンネルを相手側から張るときに必要。** 自拠点側から張ったトンネルなら (a) が無くても（conntrack により戻りの UDP として）通ってしまうため、開け忘れに気づきにくい。相手側から張り直すときに初めて失敗する（[付録の実測](#待ち受けポートを開け忘れた場合)）。

### 6. サービスの有効化・起動

```bash
sudo systemctl enable --now wg-quick@wg0
```

```
$ sudo journalctl -u wg-quick@wg0 --no-pager
systemd[1]: Starting wg-quick@wg0.service - WireGuard via wg-quick(8) for wg0...
wg-quick[6423]: [#] ip link add dev wg0 type wireguard
wg-quick[6423]: [#] wg setconf wg0 /dev/fd/63
wg-quick[6423]: [#] ip -4 address add 10.99.0.1/30 dev wg0
wg-quick[6423]: [#] ip link set mtu 1420 up dev wg0
wg-quick[6423]: [#] ip -4 route add 192.168.120.0/24 dev wg0
systemd[1]: Finished wg-quick@wg0.service - WireGuard via wg-quick(8) for wg0.
```

SELinux (Enforcing) で AVC 拒否は出なかった（`ausearch -m avc` で確認）。

### 7. 拠点ルーターの設定

機種ごとに画面は違うので、要件だけを書く。**両拠点のルーターで実施する。**

| 設定 | 拠点 A のルーター | 拠点 B のルーター |
|---|---|---|
| ポート転送（静的 NAT / NAPT） | WAN `<WG_PORT>/udp` → `<WG_A_LAN_IP>:<WG_PORT>` | WAN `<WG_PORT>/udp` → `<WG_B_LAN_IP>:<WG_PORT>` |
| 静的経路 | 宛先 `<SITE_B_LAN>` → ゲートウェイ `<WG_A_LAN_IP>` | 宛先 `<SITE_A_LAN>` → ゲートウェイ `<WG_B_LAN_IP>` |
| DHCP | `<WG_A_LAN_IP>` を固定（予約）する | `<WG_B_LAN_IP>` を固定（予約）する |

WG ホスト自身のデフォルトゲートウェイは拠点ルーターのままでよい。

#### ルーターの静的経路とヘアピン（非対称経路）

この構成では、Client A の最初のパケットは Router A に行き、**同じ LAN 側インターフェースへ折り返して**（ヘアピン）WG host A に届く。このとき:

- Linux ルーター（検証時の Router A）は **ICMP Redirect** を返し、それを受け入れたクライアントは以降 WG host A に直接送る（`ip route get` に `<redirected>` と出る）
- Redirect を受け入れないクライアントでは、毎回 Router A 経由のままになる
- いずれの場合も戻りのパケットは WG host A から Client A へ直接届くため、**Router A から見ると片方向しか通らない非対称経路**になる

検証では、Redirect を受け入れる場合・拒否する場合（`accept_redirects=0`）の両方で双方向 ping・TCP が通った。ただし **Router A には NAT やファイアウォールの状態追跡を持たせていない**。市販ルーターや UTM のなかには、LAN 内で折り返す転送を拒否するもの、戻りが見えない TCP セッションを途中で切るものがある。つながらない、あるいは TCP だけが不安定な場合は、ルーター側で折り返し転送を許可する設定を探すか、次の代替策をとる。

#### ルーターに静的経路を入れられない場合

- **(a) クライアントに経路を追加する** — 通信するクライアントにだけ `<SITE_B_LAN> via <WG_A_LAN_IP>` を入れる。ルーターを通らないので非対称経路も起きない。台数が多いと管理が大変になる（DHCP option 121 を配布できるルーターなら一括で配れる）
- **(b) WG ホストで NAT する（masquerade）** — 相手拠点から届いた通信の送信元を WG ホストの IP に書き換えれば、戻りは WG ホスト宛てになるので、自拠点ルーターの静的経路は不要になる。ただし **(1) 送信元のクライアントが相手からは区別できなくなり、(2) NAT した側への着信はできない**（片方向になる）。双方向に通信するという今回の要件は満たせないので、**最後の手段**としてだけ使う。本書では未検証

---

## 完了時点の状態（拠点 A）

```
$ sudo wg show
interface: wg0
  public key: <SITE_A_PUBKEY>
  private key: (hidden)
  listening port: 51820

peer: <SITE_B_PUBKEY>
  endpoint: 198.51.100.2:51820
  allowed ips: 10.99.0.2/32, 192.168.120.0/24
  latest handshake: 3 seconds ago
  transfer: 5300 B received, 5356 B sent
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
sudo wg show                          # latest handshake が 2 分以内、transfer が増えている
ip route show dev wg0                 # 相手 LAN への経路がある
sysctl net.ipv4.ip_forward            # = 1
sudo firewall-cmd --get-active-zones  # wg0 が wireguard ゾーン
sudo firewall-cmd --list-all-policies # siteA-to-siteB / siteB-to-siteA の rich rule
```

`latest handshake` が表示されない場合は、トンネルが張れていない。調べる順番は次のとおり:

1. 相手の公開鍵・`Endpoint` の書き間違い
2. 相手ルーターのポート転送
3. 相手 WG ホストの firewalld の `<WG_PORT>/udp`

### クライアント同士で確認する

Client A から:

```bash
ping <Client B の IP>
tracepath -n <Client B の IP>
```

```
$ tracepath -n 192.168.120.100
 1?: [LOCALHOST]                      pmtu 1500
 1:  192.168.110.2                                         0.125ms       ← WG host A
 1:  192.168.110.2                                         0.024ms
 2:  192.168.110.2                                         0.019ms pmtu 1420
 2:  10.99.0.2                                             0.233ms       ← トンネル越しの WG host B
 3:  192.168.120.100                                       0.146ms reached
     Resume: pmtu 1420 hops 3 back 3
```

- 経路に**相手のトンネル IP**（`<WG_B_TUN_IP>`）が出ればトンネル経由で届いている
- `pmtu 1420` は wg0 の MTU
- 1 ホップ目が `<ROUTER_A_LAN_IP>` で、2 ホップ目に `asymm` と出るのは、Redirect を受け入れないクライアント（上記「ヘアピン」参照）

**逆方向（Client B → Client A）も必ず確認する。** 片側の firewalld policy やルーターの静的経路が抜けていると、片方向だけ失敗する。TCP も確認しておくとよい（例: 片側で `python3 -m http.server 8080`、もう片側から `curl http://<IP>:8080/`）。

### 症状と原因の対応（実測）

| 症状 | 原因 |
|---|---|
| クライアントの ping に `From <WG_A_LAN_IP> ... Packet filtered` | WG ホストの firewalld が転送を拒否している（policy 未設定、rich rule のサブネット誤り） |
| `wg show` の handshake は成立しているのに、クライアントの ping が無応答 | 相手側の firewalld policy、相手ルーターの静的経路、相手の `ip_forward` のいずれか |
| WG ホスト自身から相手 LAN へ ping できないのに、クライアント同士は通る | 下記「WG ホスト自身から相手 LAN へ送る場合」 |
| クライアントから相手の**トンネル IP** へ ping すると `Destination Net Unreachable`（送信元は自拠点ルーター） | ルーターに `<WG_TUNNEL_NET>` の経路が無いため。クライアント同士の通信には不要 |
| 自拠点から張ったトンネルは動くのに、相手側から張ろうとすると失敗する | 自拠点の firewalld で `<WG_PORT>/udp` を開け忘れている、またはルーターのポート転送が無い |

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

`systemctl reload wg-quick@wg0` は WireGuard の設定（peer・AllowedIPs など）だけを差し替え、**`ip route` は変更しない**。`AllowedIPs` に LAN を追加して reload すると、`wg show` には新しい範囲が出るが、経路が無いのでその範囲宛てのパケットはトンネルに入らない:

```
$ sudo wg show wg0 allowed-ips
<SITE_B_PUBKEY>	10.99.0.2/32 192.168.120.0/24 192.168.130.0/24
$ ip route show dev wg0
10.99.0.0/30 proto kernel scope link src 10.99.0.1
192.168.120.0/24 scope link                         ← 192.168.130.0/24 が無い
```

`AllowedIPs`・`Address` を変えたときは **`systemctl restart wg-quick@wg0`** を使う（一瞬トンネルが切れる）。reload で済むのは、鍵・Endpoint・keepalive だけを変えたときに限られる。

### WG ホスト自身から相手 LAN へ送る場合

WG ホスト自身が送るパケットは、`wg0` の経路により**送信元がトンネル IP（`<WG_A_TUN_IP>`）になる**。相手拠点のクライアントは `<WG_TUNNEL_NET>` への経路を持たないので、返事をデフォルトゲートウェイの Router B に送り、そこで行き場を失う。

```
$ ip route get 192.168.120.100
192.168.120.100 dev wg0 src 10.99.0.1
$ ping -c1 -W1 192.168.120.100
1 packets transmitted, 0 received, 100% packet loss
$ ping -c1 -W1 -I 192.168.110.2 192.168.120.100      ← 送信元を LAN 側 IP にすると通る
1 packets transmitted, 1 received, 0% packet loss
```

**クライアント同士の通信には影響しない。** WG ホスト自身からも相手 LAN を使いたい場合は、次のどちらかにする。

- 相手ルーターに `<WG_TUNNEL_NET>` via `<WG_x_LAN_IP>` の静的経路も追加する（検証で通ることを確認した）
- 送信元を LAN 側 IP にする（`ping -I`、アプリ側での bind など）

### 片側がグローバル IP を持たない場合（CGNAT など）

着信を受けられない側（例: 拠点 A）が常にトンネルを張りに行く構成にする。

| | 着信を受けられない側（A） | グローバル IP がある側（B） |
|---|---|---|
| `[Peer]` の `Endpoint` | **必須**（`<SITE_B_PUBLIC>:<WG_PORT>`） | 省略する |
| `PersistentKeepalive` | **必須**（NAT のマッピングを維持するため） | 不要 |
| ルーターのポート転送 | 不要 | **必須** |
| firewalld の `<WG_PORT>/udp` | 不要 | **必須** |

WireGuard は、正しく認証できたパケットの送信元を peer の endpoint として覚える。そのため、`Endpoint` を書いていない側もハンドシェイクを受けた後は返信先がわかる。付録の検証では、`Endpoint` を持たない側の `wg show` に、相手の endpoint が表示された（[付録](#待ち受けポートを開け忘れた場合)）。ただし、**着信を受けた側から先に通信を始めることはできない**。A の keepalive でトンネルが維持されている間だけ、B 側のクライアントから A 側へ接続できる。**両側とも `Endpoint` を省略すると、どちらからもトンネルを張れない。**

### Endpoint に DDNS 名を書く場合

`Endpoint` のホスト名は **`wg-quick up` の時点で一度だけ名前解決される**（`wg(8)` の仕様）。相手のグローバル IP が変わると、再起動するまで古い IP に送り続ける。対策:

- `wireguard-tools` 同梱の `/usr/share/doc/wireguard-tools/contrib/reresolve-dns/reresolve-dns.sh` を systemd timer で定期実行する
- 片側だけでも固定 IP にし、そちらを常に接続を受ける側にする（上記の CGNAT 構成と同じ形）。動的 IP の側が張りに行くので、その側の IP が変わっても、固定 IP の側は新しい送信元を endpoint として覚え直す

本書では未検証。

### MTU

wg-quick は wg0 の MTU を既定で **1420** にする（IPv4/IPv6 の外側ヘッダー分を引いた値）。PPPoE（MTU 1454 / 1492 など）の回線では、トンネル内の最大サイズの通信だけが通らないことがある（ping は通るが、大きなファイル転送や一部の HTTPS が止まる）。その場合は `[Interface]` に `MTU = 1380` などと明示し、`systemctl restart wg-quick@wg0` する。本書の検証環境（MTU 1500 の veth）ではこの問題は起きていない。

### LAN サブネットの重複

両拠点の LAN が同じサブネット（例: どちらも `192.168.1.0/24`）だと経路を区別できないので、この構成は成立しない。家庭用ルーターの初期値のままの拠点同士を結ぶ場合は、どちらかの LAN のアドレスを変える必要がある。

### 再起動後の自動起動

`systemctl enable` 済みなので OS 起動時に `wg-quick@wg0` が上がる。検証は namespace を使っていたため、**実際の OS 再起動での確認はしていない**（`systemctl restart` と `firewall-cmd --complete-reload` の後に、ゾーン割り当て・経路・疎通が戻ることは確認済み）。

---

## ロールバック

各拠点の WG ホストで:

```bash
sudo systemctl disable --now wg-quick@wg0
sudo rm -f /etc/wireguard/wg0.conf /etc/wireguard/wg0.key /etc/wireguard/wg0.pub

sudo firewall-cmd --permanent --delete-policy=siteA-to-siteB
sudo firewall-cmd --permanent --delete-policy=siteB-to-siteA
sudo firewall-cmd --permanent --delete-zone=wireguard
sudo firewall-cmd --permanent --zone=<LAN_ZONE> --remove-port=<WG_PORT>/udp
sudo firewall-cmd --reload

sudo rm -f /etc/sysctl.d/90-wireguard.conf
sudo sysctl -w net.ipv4.ip_forward=0

sudo dnf remove wireguard-tools systemd-resolved   # 不要なら
```

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

### 構築スクリプト（抜粋）

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

### policy を入れた後

| 確認項目 | 結果 |
|---|---|
| Client A → Client B の ping | 成功 |
| Client B → Client A の ping | 成功 |
| Client A → Client B の TCP（HTTP） | 成功（`200`） |
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
wg set wg0 listen-port 51821 peer <SITE_B_PUBKEY> remove
wg set wg0 peer <SITE_B_PUBKEY> allowed-ips 10.99.0.2/32,192.168.120.0/24
# B: A の Endpoint を 51821 に
ip netns exec wgB wg set wg0 peer <SITE_A_PUBKEY> endpoint 198.51.100.1:51821
```

| A の firewalld | 結果 |
|---|---|
| 51821/udp を開けていない | Client B → Client A は失敗。A の `latest-handshakes` は `0`（一度も成立していない） |
| `firewall-cmd --add-port=51821/udp` | 成功。A の `wg show` に、`Endpoint` を書いていない B の endpoint `198.51.100.2:51820` が表示された |

一方、本文の構成（両側に `Endpoint`）では、**A の firewalld で 51820/udp を開ける前から**ハンドシェイクが成立していた。A から送ったハンドシェイクへの B の応答が、conntrack で「戻りのパケット」として許可されたためである。開け忘れても、自拠点側から張れば動いてしまうので気づきにくい。

### 後片付け

namespace・ブリッジ・経路を削除し、[ロールバック](#ロールバック)の手順で wg-quick・鍵・sysctl・firewalld を戻した。`/etc/firewalld` を作業前のバックアップと `diff -r` で比べ、差分が無いことを確認した（削除で生成された `*.xml.old` は手で消した）。`wireguard-tools` と `systemd-resolved` はインストールしたまま残している。

## スクリプトの検証（ドライランのみ）

`wg-s2s.sh` は、**実際の適用（`apply` / `remove` の本実行）をまだ試していない**。途中で、検証に使っていたマシンが実運用向けの WireGuard 設定（別途作成した `wg0.conf`・sysctl・firewalld）を持つ環境だとわかった。そのため、既存の設定を変える操作は取りやめ、読み取りだけで済む範囲で確認した。

| 確認項目 | 結果 |
|---|---|
| `bash -n` | OK（shellcheck は未導入のため未実施） |
| root 以外で `apply` | `root で実行してください` で停止 |
| `keygen` | 鍵を生成して公開鍵を表示。再実行しても既存の鍵を上書きしない。拠点指定を誤ると停止 |
| `apply A --dry-run`（conf 生成、netns 環境） | 生成予定の conf が手動手順の conf と同じ内容（`PrivateKey = (hidden)`）。firewalld は、未設定の項目だけが実行予定として表示された |
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
