# WireGuard VPN 構築手順（site-to-site + road warrior / wg-quick + firewalld）の検証記録

[手順書](../wireguard.md)・[ロールバックと注意点](../extra/wireguard.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順 / 手順 18: 本文中の記録

   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](#症状と原因の対応実測) を見る

### 実施手順 / 手順 18: 補足: 疎通確認

`latest handshake` が表示されない場合は、トンネルが張れていない。調べる順番は次のとおり:

1. 相手の公開鍵・`Endpoint` の書き間違い（`site.env` の `SITE_x_PUBKEY` を両拠点でそろえたか）
1. 相手ルーターのポート転送
1. 相手 WG ホストの firewalld の `${WG_PORT}/udp`

**拠点の LAN 上のクライアント同士**（Client A から）の `tracepath` の例:

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
- 1 ホップ目が `${ROUTER_A_LAN_IP}` で、2 ホップ目に `asymm` と出るのは、Redirect を受け入れないクライアント（[ヘアピン](../extra/wireguard.md#ルーターの静的経路とヘアピン非対称経路)参照）

**逆方向（Client B → Client A）も必ず確認する。**

- 片側の firewalld（`wg0` のゾーン・forward）やルーターの静的経路が抜けていると、片方向だけ失敗する
- TCP も確認しておくとよい（例: 片側で `python3 -m http.server 8080`、もう片側から `curl http://<IP>:8080/`。検証では `HTTP 200` を確認した）

**外出先のクライアントから**:

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

**逆方向（拠点の LAN → クライアント）も確認する。** ルーターの静的経路が抜けていると、片方向だけ失敗する。

### 対象と検証環境

- **目的**: 2 拠点の LAN を WireGuard で結び、**拠点 A の LAN 上のクライアントと拠点 B の LAN 上のクライアントが双方向に通信できる**ようにする
  - あわせて、外出先のノート PC やスマートフォンなど**任意の台数のクライアント**を足して、そこから両拠点の LAN に到達できるようにする
- **進め方**: **`site.env` に値を 1 度だけ書き、両拠点の WG ホストに同じファイルを置いて、`wg-vpn.sh` に `-e` で渡して実行する**
  - 拠点 A / B は引数で指定し、スクリプトがこのホストの LAN 側 IP と照合する（取り違えると何も変更せずに止まる）
- **状態**: **network namespace のラボと、クリーンインストールした x86_64 の AlmaLinux 10 の VM 2 台で本実行済み（2026-10-06）。実機では一部を確認した**
  - 2026-10-06: 先行検証とは別の新規 VM で現行本文を再検証した（[今回の記録](#付録-新規-vm-での現行手順の再検証2026-10-06)）。検証専用のアカウント・鍵・隔離 LAN を使った
  - 1 台のマシン上に network namespace で 2 拠点と外出先クライアントを模擬して、動作を確認した（[付録](#付録-network-namespace-による検証)）。namespace での検証は、同じ設定を手で入れて行った
  - 実機で確認したこと:
    - 外出先のスマートフォン（公式アプリ・モバイル回線）から拠点 B の LAN への疎通（2026-09-21。[付録](#登録簿に無い-peer-の消失2026-09-21拠点-b)）
    - AlmaLinux 10 の PC クライアント（拠点 B に接続）から拠点 A の LAN への折り返し（2026-09-22。→ [wireguard-road-warrior.md の付録](wireguard-road-warrior.md#付録-実機での検証記録)）
    - スクリプト（`wg-vpn.sh`）の `apply` の本実行（2026-09-20、拠点 B。旧 firewalld レイアウトからの移行。[付録](#付録-スクリプトの検証)）
  - **firewalld は 2026-09-20 に「`wg0` を LAN 側ゾーンに入れてゾーン内転送で通す」方式に変えた**（policy を作らない）
    - この方式はスタブ環境で `apply` / `remove` を確認したうえで、**拠点 B の実機で `apply` を本実行して旧レイアウトから移行し、拠点間の疎通が維持されることを確認した**（[付録](#実機での移行2026-09-20拠点-b)）
    - **拠点 A の実機はまだ旧レイアウトのまま**
  - **確認していないこと**: 両拠点の実機を現行の firewalld レイアウトにそろえた構成、`remove` の実機での本実行、クライアント同士の疎通
  - 2026-09-28: 補足の firewalld のブロックを、貼り方で行が失われない形に直した（[README の記法](../../README.md#記法)）
    - `{ … }` で囲んだ（中のコマンドは変えていない）: [転送を絞りたい場合](../extra/wireguard.md#転送を絞りたい場合)と[Cockpit へ入る場合](../extra/wireguard.md#トンネル越しに-wg-ホスト自身の-ssh-や-cockpit-へ入る場合)の rich rule の例、[旧レイアウトからの移行](../reference/wireguard.md#旧レイアウト専用ゾーン--policyからの移行)を手で行うブロック
    - 2 つに分けた（目視で確かめてから次を貼るため）: `--info-zone` の後の Cockpit の開放、`--dry-run` の後の `apply`
    - Cockpit の開放は、`--add-service` と `--reload` を `&&` でつないだ 1 行にした
    - どのブロックも、直した後は構文の検査だけで、流していない
  - 2026-10-05: クライアント削除と鍵交換の反映、無関係の未知 peer による停止、LAN 側 IP の変更前後の検査を、一時ファイルとホスト操作のスタブで確認した。稼働中の WireGuard・firewalld・systemd には適用していない

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-16（初回）／ 2026-09-19（変数形の手順に書き換えて再検証、クライアントの疎通確認） |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64 |
| カーネル | 6.12.96（`wireguard.ko` を同梱） |
| `wireguard-tools` | 1.0.20250521-1.el10（appstream） |
| firewalld | 2.4.3 |
| NetworkManager | 1.56.0 |
| SELinux | Enforcing |
| クライアント | 検証は Linux の `wg-quick`。WireGuard 公式アプリ（Windows / macOS / iOS / Android）も同じ conf で使える想定。AlmaLinux 10 の PC を NetworkManager でつなぐ手順は [wireguard-road-warrior.md](../wireguard-road-warrior.md)（2026-09-22 に実機で本実行） |

![構成](../diagrams/wireguard-remote-client.svg)

拠点ルーターの配下に WG ホストを 1 台ずつ置き、`wg0` 同士をトンネルで結ぶ。外出先のクライアントは、どちらかの拠点の WG ホストに接続する（図は拠点 A で受ける場合。→ [補足: 構成とパケットの流れ](../reference/wireguard.md#構成とパケットの流れ)）。

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。値は最初に作る `site.env` 1 ファイルに集約し、スクリプトに渡す。例は検証で使った値。
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
> | `${LAN_ZONE}` | WG ホストの LAN 側 NIC が属する firewalld ゾーン。**`wg0` もここに入れる**（空なら自動で検出する） | `public` |
> | `${SITE_A_PUBKEY}` / `${SITE_B_PUBKEY}` | 各拠点の WireGuard 公開鍵 | （`wg pubkey` の出力） |
> | `${WG_IFACE}` / `${WG_FW_ZONE}` | インターフェース名 / 旧レイアウトで `wg0` を入れていた専用ゾーン名（残っていれば `apply` / `remove` が消す。[移行](../reference/wireguard.md#旧レイアウト専用ゾーン--policyからの移行)） | `wg0` / `wireguard` |
> | `${WG_A_CLIENT_NET}` / `${WG_B_CLIENT_NET}` | 各拠点に接続するクライアントに割り当てるトンネル内のアドレス帯（**LAN・`${WG_TUNNEL_NET}`・互いに重複不可**、`/30` またはそれより広く。クライアントを受けない拠点は空） | `10.99.1.0/24` / （空） |
> | `${WG_CLIENT_DNS}` | クライアント用 conf に書く DNS サーバー（任意） | （空） |
>
> 図と補足に出てくる `${CLIENT_TUN_IP}` は、`client add` がクライアントに割り当てるトンネル IP（`${WG_A_CLIENT_NET}` の中の 1 つ。クライアント conf の `Address`。検証では `10.99.1.1`）。`site.env` の変数ではない。
>
> 秘密鍵はこの文書に載せない。公開鍵は秘密情報ではないが、検証用に作った使い捨ての値なので載せていない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 構成とパケットの流れ

この折り返し（`wg0` から入って `wg0` へ出る転送）が成立することは、ラボで確認した（[付録](#リモートクライアントの検証2026-09-19)。当時は policy で許可していた）。

- ゾーンの forward は、ゾーン内の**すべての** interface について `oifname <iface> accept` を入れる（firewalld 2.4.3 の `firewall/core/nftables.py`、`build_zone_forward_rules`）。そのため、`wg0` から入って `wg0` へ出る転送も同じ経路で通る
- forward 方式でも、2026-09-22 に拠点 B のホストで実機確認した。PC クライアントから相手拠点（拠点 A）の LAN へ届き、これが `wg0` から入って `wg0` へ出る転送にあたる（→ [wireguard-road-warrior.md の付録](wireguard-road-warrior.md#付録-実機での検証記録)）

### 選択した方針

- **wg-quick + systemd** — 設定が 1 ファイルで完結し、情報も多い。NetworkManager は wg-quick が作った `wg0` を `connected (externally)` として扱うだけで干渉しなかった（実測）
- **値は `site.env` に集約し、両拠点で同じファイルを使う** — `site.env` は A/B 両拠点の値を並べて持つ
  - スクリプトは指定された拠点を**このホストの LAN 側 IP** と照合してから、自拠点・相手拠点の値を組み立てる
  - 拠点ごとに手順を書き分けないので、**A/B の取り違えが起きない**
- **秘密鍵は `wg0.conf` に直接書く** — `PostUp` で別ファイルから読み込む書き方もできるが、`systemctl reload` で**秘密鍵が消えてトンネルが止まる**ことを実測で確認した（[落とし穴 1](../extra/wireguard.md#落とし穴-1-秘密鍵を-conf-の外に出すと-reload-で消える)）
- **firewalld は `wg0` を LAN 側ゾーンに入れ、ゾーン内転送で無条件に通す** — トンネルを通る通信は WireGuard の鍵で認証済みなので、WG ホストでは絞らず、絞るのは**宛先ホストのファイアウォール**に任せる
  - Road Warrior からも拠点の LAN からも、どのホストへ行くときも気にするのは宛先の設定だけになる
  - firewalld の設定は「LAN 側ゾーンに待ち受けポート・`wg0`・forward」の 3 点で、policy は作らない
  - ゾーンの forward は `wg0` 内の転送（`wg0` → `wg0` の折り返し、クライアント同士）も通す
  - WG ホスト自身宛ての通信も LAN からと同じ扱いになる（LAN 側ゾーンで開いているものはトンネル越しにも開く）
  - 以前は専用ゾーン `wireguard` + 方向ごとの policy 8 本で組み合わせを絞っていた（履歴 `d364840` 以前。残っていれば `apply` が消す → [移行](../reference/wireguard.md#旧レイアウト専用ゾーン--policyからの移行)）
- **トンネルも、クライアントの通信も NAT しない** — 送信元 IP がそのまま相手拠点の LAN に届くので、相手側でアクセス元を識別・制限できる
  - その代わり、**両拠点のルーターに相手 LAN とクライアント帯の静的経路が要る**（[注意点](../extra/wireguard.md#ルーターにはクライアント帯の静的経路も要る)）
- **両拠点とも `Endpoint` と `PersistentKeepalive` を設定** — どちらからでもトンネルを張り直せる。片側がグローバル IP を持たない場合は[注意点](../extra/wireguard.md#片側がグローバル-ip-を持たない場合cgnat-など)を参照
- **クライアントは拠点に所属させ、拠点ごとにアドレス帯を分ける** — WireGuard はインターフェースごとに「この宛先はこの peer」という対応表（cryptokey routing）を持ち、**1 つのアドレスを 2 つの peer に対応づけることはできない**
  - WG host B から見ると拠点 A のクライアントはすべて拠点 A の peer の向こうにいるので、帯をまとめて `AllowedIPs` に 1 行書けばよく、クライアントを追加しても拠点 B 側の設定は変わらない
  - 同じクライアントを両拠点に直接つなげる構成にすると、各ホストでそのクライアントの IP を「直接の peer」と「相手拠点の peer」の両方に書くことになり成立しない
  - 片方の拠点だけで受けたい場合は、もう一方の帯を空にする
- **クライアントの conf はホスト側で生成し、QR コードかファイルで渡す** — スマートフォンではこれが実用的。秘密鍵を拠点の外で作りたい場合は、クライアント側で鍵を作って公開鍵だけを渡す
- **反映は restart で行う** — 新しい peer の `AllowedIPs` に対する経路は reload では追加されない（[落とし穴 2](../extra/wireguard.md#落とし穴-2-reload-では経路が追加されない) と同じ機構。実測）
  - まとめて登録してから 1 回 restart する運用にする
  - **トンネル越しに WG ホストへ ssh して作業しているときは、この restart が自分のセッションの足元を切る**（切り離して実行する方法は [wireguard-road-warrior.md の付録](wireguard-road-warrior.md#落とし穴-apply-は作業中の-ssh-経路そのものを切る)）
- **ホストの転送規則はクライアント同士を隔離しないが、生成したクライアント conf はクライアント帯を含まない。全トラフィックの VPN 経由（`0.0.0.0/0`）は対象外** — [注意点](../extra/wireguard.md#クライアント同士を通す場合)を参照

### スクリプトの動作

- **変更前に、次を検査する。** この段階で失敗したら変更せずに止まる
  - アドレスの形式、LAN・トンネル網・クライアント帯の重複、登録簿の公開鍵の形式
    - `WG_x_LAN_IP` がこのホストにあるか（A/B の取り違えを防ぐ）
      - IP の一覧は最後まで読み、最初に一致するインターフェースを使う。途中で awk を終えると、`pipefail` の下で `ip` の SIGPIPE により apply が間欠的に終了 141 になるため（[VM の実測](#間欠的な終了-141-の原因と修正)）
  - 既存の conf に、登録簿にも相手拠点にも無い `[Peer]` が無いか（あれば鍵と行番号を出して停止。消してよい場合は `--drop-unknown-peers`）
- その後、必要なパッケージを導入し、ホストの鍵または既存 conf を検査する。ここで失敗しても導入済みパッケージは戻さない
- **conf を生成する場合**: `PrivateKey` を直接書く（[落とし穴 1](../extra/wireguard.md#落とし穴-1-秘密鍵を-conf-の外に出すと-reload-で消える)）
  - 既存の conf と内容が違えば、`.bak-日時` に退避してから書く
  - 相手 peer の `AllowedIPs` には相手拠点のクライアント帯が、その後ろには `clients.list` に登録したクライアントの `[Peer]` が入る
- **既存の conf を使う場合**:
  - `Address` に `WG_x_TUN_IP` が無い、または相手 LAN を `AllowedIPs` に含む `[Peer]` が無ければ**停止**
  - `ListenPort` の不一致、`PostUp` での秘密鍵読み込み、パーミッション、相手 peer にクライアント帯が無いことは**警告**
- **firewalld**: LAN 側ゾーンに `${WG_PORT}/udp`・`wg0`・forward の 3 点を、存在確認してから追加する（再実行しても重複しない）
  - 旧レイアウト（`${WG_FW_ZONE}` ゾーンと `siteA-to-siteB` などの policy）が残っていれば、その前に policy → ゾーンの順に消す
  - `wg0` が旧ゾーンでも LAN 側ゾーンでもない別のゾーンにあれば、firewalld を変更せずに止まる。ただし、その前に conf と sysctl が変更されている場合がある
- **sysctl**: `ip_forward` だけを有効にする。`rp_filter` は strict（1）のままで動く（相手 LAN への経路が `wg0` を向いているので、逆経路チェックを通る）
- **サービス**: 最後は常に `systemctl restart` する（[落とし穴 2](../extra/wireguard.md#落とし穴-2-reload-では経路が追加されない)）。クライアントを追加・削除したときも `apply` で反映する
- **LAN_ZONE**: 空なら `WG_x_LAN_IP` を持つ NIC のゾーンを自動で使う
- **CGNAT 構成**: `SITE_x_PUBLIC` を空にすると、その拠点に向けた `Endpoint` を書かない
- **`client add` が作る conf**: ホスト側の `[Peer]` に `Endpoint` は書かず、ハンドシェイクを受けた送信元を endpoint として覚える（`PersistentKeepalive` もクライアント側にだけ書く）
  - クライアント側の `AllowedIPs` に `${WG_TUNNEL_NET}` を入れるのは、WG ホスト自身がクライアントに送るパケットの送信元が `wg0` のアドレスになるため。無いとクライアント側で捨てられる

手で作った conf とスクリプトが作る conf が一致することは、検証で `diff` して確認した（[付録](#変数形コマンドの再検証2026-09-19)）。スクリプトの検証範囲は[付録](#付録-スクリプトの検証)を参照。

### 症状と原因の対応（実測）

| 症状 | 原因 |
|---|---|
| クライアントの ping に `From ${WG_A_LAN_IP} ... Packet filtered` | WG ホストの firewalld が転送を拒否している。`wg0` が LAN 側ゾーンに入っていない、またはそのゾーンの forward が `no`（`status` の `--info-zone` で確認。`apply` で直る） |
| `wg show` の handshake は成立しているのに、クライアントの ping が無応答 | 相手側の firewalld（`wg0` のゾーン・forward）、相手ルーターの静的経路、**相手の `ip_forward`** のいずれか。両拠点で `apply` したか確認する |
| WG ホスト自身から相手 LAN へ ping できないのに、クライアント同士は通る | 下記「[WG ホスト自身から相手 LAN へ送る場合](../extra/wireguard.md#wg-ホスト自身から相手-lan-へ送る場合)」 |
| クライアントから相手の**トンネル IP** へ ping すると `Destination Net Unreachable`（送信元は自拠点ルーター） | ルーターに `${WG_TUNNEL_NET}` の経路が無いため。クライアント同士の通信には不要 |
| 自拠点から張ったトンネルは動くのに、相手側から張ろうとすると失敗する | 自拠点の firewalld で `${WG_PORT}/udp` を開け忘れている、またはルーターのポート転送が無い |
| トンネル越しに WG ホスト自身の ssh / Cockpit に `No route to host`。**同じ宛先に ping は通る** | `wg0` が属するゾーンでその service が開いていない。`wg0` は LAN 側ゾーンにあるので、同じホストに LAN からも入れないはず。旧レイアウト（空の専用ゾーン）が残っている場合も同じ症状（[トンネル越しに WG ホスト自身の ssh や Cockpit へ入る場合](../extra/wireguard.md#トンネル越しに-wg-ホスト自身の-ssh-や-cockpit-へ入る場合)） |
| ハンドシェイクは成立するのに、相手拠点 LAN へ**まったく応答が無い**（ICMP も返らない） | 相手拠点のホストの `AllowedIPs` にクライアント帯が無い。WireGuard は範囲外の送信元を黙って捨てる。両拠点の `site.env` に帯を書いて両拠点で `apply` したか確認する |
| クライアントを足したのに届かない。`wg show` には出ている | `reload` で済ませた。`restart` する（[落とし穴 2](../extra/wireguard.md#落とし穴-2-reload-では経路が追加されない)） |
| その端末だけハンドシェイクが成立しない（`wg show` に `[Peer]` が出ない、クライアント側は送信だけ増えて受信が 0） | ホストにその端末の公開鍵の `[Peer]` が無い。拠点 LAN どころか WG ホストのトンネル IP まで**すべて無応答**になる。`client list` と `sudo wg show` を突き合わせる |
| 手で `wg0.conf` に書いた `[Peer]` が、`apply` の後で消えている | `clients.list` が唯一の登録簿で、`apply` はそこから `[Peer]` を毎回組み立て直す（[落とし穴 3](../extra/wireguard.md#落とし穴-3-登録簿に無い-peer-は-apply-で消える)） |
| 拠点の LAN からクライアントへ接続できない（逆方向だけ失敗） | ルーターにクライアント帯の静的経路が無い |
| クライアントから WG ホスト自身（`${MY_TUN_IP}`）に届かない | クライアント conf の `AllowedIPs` に `${WG_TUNNEL_NET}` が入っていない |
| OS を入れ直した後、相手拠点とハンドシェイクが成立しない | 鍵を戻していない（`wg genkey` で別の鍵を作った）。`sudo wg pubkey < /etc/wireguard/wg0.key` が `site.env` の `SITE_x_PUBKEY` と一致するか確かめる（[バックアップと復旧](../wireguard.md#バックアップと復旧os-の再インストール)） |

### 落とし穴 2: reload では経路が追加されない / 手順 0: 本文中の記録

`systemctl reload wg-quick@wg0` は WireGuard の設定（peer・AllowedIPs など）だけを差し替え、**`ip route` は変更しない**。`AllowedIPs` に範囲を追加して reload すると、`wg show` には新しい範囲が出るが、経路が無いのでその範囲宛てのパケットはトンネルに入らない（実測）:

### 落とし穴 3: 登録簿に無い peer は apply で消える / 手順 0: 本文中の記録

この落とし穴で実際にクライアントが 1 台つながらなくなった（[付録](#登録簿に無い-peer-の消失2026-09-21拠点-b)）。

### WG ホスト自身から相手 LAN へ送る場合: 検証状況の記録

> 現在の方式では WG ホストの firewalld は転送を絞らないので、トンネル IP を送信元とするパケットも相手 WG ホストを通る。失敗するとすれば経路（**無応答**）だけ。
>
> 旧レイアウトでは policy の rich rule が `source address` を相手拠点 LAN に限定していたため、相手 WG ホストの firewalld で拒否され `From 10.99.0.1 icmp_seq=1 Packet filtered` になった（2026-09-19、実機で確認。履歴）。

### トンネル越しに WG ホスト自身の ssh や Cockpit へ入る場合 / 手順 0: 本文中の記録

- `wg0` はゾーンに**永続**で入っているので、`--reload` しても外れない（旧レイアウトで実測）

### トンネル越しに WG ホスト自身の ssh や Cockpit へ入る場合 / 手順 0: 本文中の記録

  - そのため、トンネル越しに WG ホスト自身の ssh や Cockpit へ接続すると `No route to host`（ICMP admin-prohibited を受けて `connect()` が `EHOSTUNREACH` を返す）になり、ping だけは通った（2026-09-19、実機で確認。履歴）

### クライアントが拠点の LAN 内にいるとき / 手順 0: 本文中の記録

- NetworkManager で張る PC では、これに加えて LAN 宛ての経路が `wg0` 側（**metric 50**。2026-09-22 に実測）に奪われる

### クライアント同士を通す場合 / 手順 0: 本文中の記録

- 通すには、通信する各クライアントの `AllowedIPs` に必要なクライアント帯を追加して、経路と受信元の許可をそろえる必要がある。この追加構成の疎通は未検証（2026-09-22 の実機検証でも同時接続は 1 台だけ）

### 全部消すときの補足

2026-09-20 より前の `apply`（履歴 `d364840` 以前）は、専用ゾーン `${WG_FW_ZONE}`（既定 `wireguard`）に `wg0` を入れ、`siteA-to-siteB` / `clientsB-to-siteA` など方向ごとの policy（最大 8 本）で転送を絞っていた。

- **policy → ゾーンの順に消す理由**: ゾーンを先に削除すると、そのゾーンを参照する policy が残り、`--reload` が `Error: INVALID_ZONE: Policy 'clientsA-to-siteA': 'wireguard' not among existing zones` で失敗する（実測）
- **policy の存在確認に `--query-policy` は使えない。** firewalld 2.4.3 にそのオプションは無く、`unrecognized arguments` で終了コード 2 を返す（実測）。スクリプトは `--get-policies` の一覧で判定する
- 旧 `site.env` に `WG_FW_ZONE` が残っていれば、その名前を旧専用ゾーンとして使う。`LAN_ZONE` と同じ名前になっていると止まる（LAN 側ゾーンを消してしまうため）
- `wg0` が旧専用ゾーンでも LAN 側ゾーンでもない別のゾーンにある場合は、何も変えずに止まる
- 通信が止まるのは reload の一瞬だが、**移行は LAN かコンソールから行う**（トンネル越しに作業していて途中で失敗すると戻れない）
- スクリプトを使わずに手で行う場合は、同じ順序で:

拠点 B の実機（`public` に `end0`、`wireguard` に `wg0`、policy 6 本）では、この `apply` で移行済み（2026-09-20。[付録](#実機での移行2026-09-20拠点-b)）。

- 片方だけだと、未移行の側の policy が rich rule で送信元を相手拠点 LAN に限定したままになる
- そのため、トンネル IP を送信元とする通信（WG ホスト自身から相手 LAN へ）がそちらで `Packet filtered` になる（拠点 B 移行後、未移行の拠点 A に対して実測）

### 付録: network namespace による検証

> 検証当時の手順書は、1 コマンドずつ貼る手動手順（手動手順 0〜10）だった。その本文はこのリポジトリの履歴（コミット `e26df03` 以前の `docs/wireguard.md`）にある。この付録と次の付録の「手動手順 N」はそれを指す。
>
> **この付録の記録は、firewalld を専用ゾーン `wireguard` + 方向ごとの policy で組んでいた当時（2026-09-16 / 19）のもの。** firewalld の部分は現在の方式（`wg0` を LAN 側ゾーンに入れてゾーン内転送で通す。[選択した方針](#選択した方針)）と異なるが、ルーター・`AllowedIPs`・経路に関する結果はそのまま有効。記録は当時のまま残している。

#### ラボの構成

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
- ラボのブリッジ `lab-brA` は NetworkManager の管理外なので、firewalld のゾーンに割り当てられていない（`--get-zone-of-interface` は `no zone`）。手動手順 0 の検出はこの場合に既定ゾーン `public` へ落ちる

#### 構築スクリプト（抜粋）

<details>
<summary>namespace の構築スクリプト（21 行）</summary>

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

</details>

> nftables のルールを `nft -f -` のヒアドキュメントで 1 行ずつ `chain pre { type ...; rule }` と書いたところ、`syntax error, unexpected end of file` になった。上記のように `nft add` を分けて実行すれば問題ない。

#### 拠点間の実測結果

##### firewalld の policy を入れる前

WireGuard を起動した直後は、ハンドシェイクは成立するが、クライアント同士は通らない。WG ホストの firewalld が転送を拒否し、ICMP で通知している:

```
$ ip netns exec clientA ping -c1 -W1 192.168.120.100
PING 192.168.120.100 (192.168.120.100) 56(84) bytes of data.
From 192.168.110.2 icmp_seq=1 Packet filtered
```

firewalld の `filter_FORWARD` チェインは、policy に一致しないパケットを `reject with icmpx admin-prohibited` にする。新しく作ったゾーンは `forward: no` になっていた（firewalld 2.4.3）が、ゾーンをまたぐ転送は policy で許可するので、この値は関係しない。

`lab-brA` はどのゾーンにも割り当てられていないが、firewalld は**未割り当ての NIC を既定ゾーンとして扱う**ため、`public` を ingress / egress に指定した policy がそのまま効いた（実測）。

##### policy を入れた後

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

##### 待ち受けポートを開け忘れた場合

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

#### 変数形コマンドの再検証（2026-09-19）

本書を「手動手順 0 で変数を定義し、以降はコピペする」形に書き換えたので、**書き換え後のコマンドブロックをそのまま貼って**同じラボを組み直し、通ることを確認した。作業前に `/etc/firewalld` をバックアップし、終了後に `diff -r` で差分が無いことを確認している。

| 確認項目 | 結果 |
|---|---|
| 手動手順 0 の読み戻し | `MY_SITE=A` が LAN 側 IP から自動判定され、`MY_NIC=lab-brA`、`LAN_ZONE=public`、`POL_OUT=siteA-to-siteB` が組み立てられた |
| 手動手順 1〜6 をコピペ実行 | **1 度も編集せずに通った** |
| 手動手順 3 の conf | `wg-vpn.sh --dry-run apply A` が書く予定の conf と `diff` して**完全一致**（秘密鍵行をマスクして比較） |
| 手動手順 5 の展開結果（`set -x`） | rich rule に `192.168.110.0/24` / `192.168.120.0/24` が入り、literal の `$` は残っていない |
| 手動手順 5 の後の `wg-vpn.sh --dry-run apply A` | firewalld について追加の変更を表示しない（= 手動で作った設定がスクリプトの作るものと同じ） |
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
| rich rule に `$MY_LAN` が入る | 単一引用符で書いた場合。firewalld は `success` を返すので気づきにくい（当時の手順書の落とし穴 3） |

#### リモートクライアントの検証（2026-09-19）

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

#### 後片付け

namespace・ブリッジ・経路を削除し、当時の手動手順のロールバックの手順で wg-quick・鍵・sysctl・firewalld を戻した。`/etc/firewalld` を作業前のバックアップと `diff -r` で比べ、差分が無いことを確認した（削除で生成された `*.xml.old` は手で消した）。`wireguard-tools` と `systemd-resolved` はインストールしたまま残している。

### 付録: スクリプトの検証

> 「実機でのドライラン」「`backup` / `restore` の検証」「スタブ環境での本実行」は、専用ゾーン + policy だった当時のスクリプトに対する記録。現在の firewalld の方式については、最後の「LAN 側ゾーン + forward 版のスタブ検証」を参照。

#### 実機でのドライラン

`wg-vpn.sh` は、**実際の適用（`apply` / `remove` の本実行）をまだ試していない**。2026-09-19 の再検証では、手動手順と同じ conf を生成すること・手動で作った firewalld 設定に対して追加の変更を出さないことを `--dry-run` で確認したが、`apply` の本実行は行っていない。

| 確認項目 | 結果 |
|---|---|
| `bash -n` | OK |
| root 以外で `apply` | `root で実行してください` で停止 |
| `keygen` | 鍵を生成して公開鍵を表示。再実行しても既存の鍵を上書きしない。拠点指定を誤ると停止 |
| `apply A --dry-run`（conf 生成、netns 環境） | 生成予定の conf が手動手順の conf と**バイト単位で一致**（`PrivateKey = (hidden)`）。LAN 側ゾーンも `public（lab-brA から検出）` と手動手順 0 と同じ判定 |
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

##### `backup` / `restore` の検証（2026-09-19、実機）

`backup` は**読み取りしか行わない**ので、稼働中の拠点 B の WG ホスト（`wg-quick@wg0` が active）で**本実行して確認した**。`restore` は、`/etc/wireguard` を mount namespace 内の tmpfs に差し替え（`unshare -m` + `mount -t tmpfs`）、実機の設定に触れずに**本実行**まで確認した。

| 確認項目 | 結果 |
|---|---|
| `bash -n` | OK（`shellcheck` はこのマシンに無いため未実施） |
| `--dry-run backup` | まとめる予定のファイルと元のパスだけを表示。何も作らない |
| `backup`（本実行） | `~/wg-backup-<ホスト名>-<日時>.tar.gz` が 0600・実行ユーザー所有で作られる。中身は `MANIFEST` と `wg0.key` / `wg0.pub` / `wg0.conf` / `site.env` / `wg-env.sh`。**クライアント用 conf は入らない** |
| `backup` 前後の実機 | `/etc/wireguard` の `ls -l` と `wg show` に差分なし（トンネルは張られたまま） |
| 拠点の判定 | `A`/`B` を付けなくても、鍵から算出した公開鍵と `site.env` の `SITE_x_PUBKEY` を突き合わせて `SITE=B` と記録された。LAN 側 IP には依存しない |
| `--dry-run restore`（同じ内容） | 公開鍵の照合まで通り、全ファイルが「変更なし」。何も書かない |
| `restore` 本実行（namespace 内の空の `/etc/wireguard` へ） | 5 ファイルが戻り、公開鍵が退避前と一致。`/etc/wireguard/*` は `root:root 0600`、`site.env` と `wg-env.sh` は**実行ユーザー所有**（`sudo` で実行しても root 所有にならない） |
| 往復（`keygen` → `client add` → `backup` → 全消し → `restore` → `apply --dry-run`） | `apply` が生成する `wg0.conf` が退避前と**バイト単位で一致**。`clients.list` からクライアントの `[Peer]` も復元され、非 root の `client list` が読めた |
| `-e` の指定あり / なし | あり → `-e` の位置に戻し、元の場所との違いを表示。なし → `MANIFEST` に記録された元の場所（`~/wg/site.env`）に戻る |
| 手動手順で作ったアーカイブ | 当時の手動手順「バックアップを取る」のブロックをそのまま実行して作ったアーカイブを、`wg-vpn.sh restore` がそのまま受理した（形式が同じ） |
| 手動手順での復旧 | 当時の手動手順「クリーンインストール後に復旧する」の (a)〜(e) を namespace 内でそのまま実行し、`wg pubkey` の出力が `MY_PUBKEY` と一致した |
| 異常系 | `MANIFEST` 無し / ディレクトリ名が違う / 絶対パスを含む tar / 未知の `FORMAT` / 鍵と `MANIFEST` の公開鍵が不一致 / 鍵が `site.env` の `SITE_x_PUBKEY` のどちらとも不一致 / `site.env` の `WG_IFACE` と不一致 / `MANIFEST` のパーミッション欄が 8 進数でない — いずれも `ERROR:` を出して**何も書かずに**停止 |
| 相手拠点のホストへの復旧 | `このホストは拠点 A の WG ホスト（…）です。拠点 B の鍵を戻すと両拠点が同じ鍵になります` で停止 |
| どちらの拠点の LAN 側 IP も無いホスト | 警告を出して続行（再インストール直後を想定） |

未確認: 実機の `/etc/wireguard` に対する `restore` の本実行（namespace で代替した）、実際に OS を入れ直した後の復旧と復旧後の疎通、SELinux のラベルが `restorecon` で正しく付くこと。

その後、リモートクライアント対応を加えた版は、`firewall-cmd` などを模したスタブ環境で `apply` / `remove` の本実行と再実行（設定が重複しないこと）まで確認した（[スタブ環境での本実行](#スタブ環境での本実行)）。実機での適用は引き続き未確認。

#### スタブ環境での本実行

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

#### LAN 側ゾーン + forward 版のスタブ検証（2026-09-20）

firewalld の方式を「`wg0` を LAN 側ゾーンに入れてゾーン内転送で通す」に変えたスクリプトを、稼働中の拠点 B ホスト上で**実機の設定に触れずに**検証した。`unshare -Urm` で uid 0 の user namespace を作り、`/etc/wireguard`・`/etc/sysctl.d`・`/etc/firewalld` に tmpfs を重ね、上と同様のスタブ（`firewall-cmd` はゾーンの forward / interfaces / ports と policy 一覧を状態ファイルに持ち、未知のオプションは `unrecognized arguments` で終了コード 2）を `PATH` の先頭に置いて root として実行した。拠点 B（`WG_B_CLIENT_NET=10.99.2.0/24`、`LAN_ZONE` は空で自動検出）として実行。`shellcheck` はこのマシンに無いため未実施（`bash -n` は OK）。

| 確認項目 | 結果 |
|---|---|
| `--dry-run apply B`（`public` が既定、forward 有効、`eth0` のみ） | firewalld は `--zone=public --add-port=51820/udp`・`--add-interface=wg0`・`--reload` の 3 行だけ。`--add-forward`・policy・`--new-zone` は出ない。`LAN 側ゾーン: public（eth0 から検出）` |
| `apply B` 本実行 | 上の 3 コマンドが呼ばれ、`public` の interfaces が `eth0 wg0`、ports が `51820/udp` に。`wg0.conf`（0600）の相手 peer は `AllowedIPs = 10.99.0.1/32, 192.168.110.0/24, 10.99.1.0/24`。sysctl ファイル生成、`systemctl enable` / `restart` |
| `apply B` 再実行 | firewalld への呼び出しは `--reload` だけ。`wg0.conf は変更なし` |
| `public` の forward が無効 | `--add-forward` が追加で呼ばれる。再実行では呼ばれない |
| **旧レイアウトからの移行**（`wireguard` に `wg0`、policy 6 本 + 無関係な `allow-host-ipv6`、`*.xml.old` あり） | `--delete-policy` × 6 → `--delete-zone=wireguard` → `--add-port` → `--add-interface=wg0` → `--reload` の順。`allow-host-ipv6` と `public.xml.old` は残り、旧レイアウト由来の `*.xml.old` は消える。`旧レイアウト（ゾーン wireguard と policy）を削除しました` を表示。再実行は `--reload` のみ。`--dry-run` では同じ順序の `[dry-run]` 行が出て状態は変わらない |
| `wg0` が `work` ゾーン（旧専用ゾーンでも LAN 側でもない）にある | `wg0 は既にゾーン work に割り当てられています` で停止。firewalld への変更なし |
| `site.env` の `WG_FW_ZONE` が `LAN_ZONE` と同じ | `WG_FW_ZONE（旧専用ゾーン名）が LAN_ZONE と同じです` で停止。firewalld への変更なし |
| `status` | `zone public (wg0)` に続けて `--info-zone` の出力（`forward: yes`、`interfaces: eth0 wg0`、`ports: 51820/udp`） |
| `remove B` | `--remove-interface=wg0` → `--remove-port=51820/udp` → `--reload`。`--remove-forward` は呼ばれない。sysctl ファイル削除、`disable --now` |
| 旧レイアウトの状態で `remove B` | `--delete-policy` × 6 → `--delete-zone=wireguard` → `--reload`（ポートは元々無いので `--remove-port` は無し）。`wg0` が `work` にある状態では警告を出して `--reload` のみ |
| `client add B carol` → `apply B` → `remove B --purge` | `[Peer]` が増え、firewalld は `--reload` だけ。purge で conf・鍵・`clients/` が消え `clients.list` は残る |
| `--use-existing-conf --dry-run apply B` | 変更前と同じ挙動（conf は生成せず、firewalld は `--reload` のみ） |

未確認（このスタブ検証の時点）: 新方式での実際の nftables 挙動と、実機での移行。次の節で拠点 B の実機について確認した。

#### 実機での移行（2026-09-20、拠点 B）

稼働中の拠点 B の WG ホスト（旧レイアウト: `public` に `end0`、`wireguard` に `wg0`、policy 6 本。拠点 A は CGNAT で常にこちらへ張りに来る）で、`apply B` を本実行して移行した。作業は LAN 側からの ssh で行い（トンネル越しではない）、事前に `/etc/firewalld` を `cp -a` で退避した。

| 確認項目 | 結果 |
|---|---|
| `--dry-run apply B` | 生成予定の `wg0.conf` が稼働中の conf と**一致**（秘密鍵行をマスクして `diff`。peer は拠点 A と クライアント 1 台）。firewalld は policy 6 本の削除 → `wireguard` ゾーンの削除 → `--zone=public --add-interface=wg0` → `--reload` の順で表示。`51820/udp` と forward は `public` に既にあるので追加されない |
| `apply B` 本実行 | `wg0.conf は変更なし`、firewalld の各コマンドが `success`、`旧レイアウト（ゾーン wireguard と policy）を削除しました`、`wg-quick@wg0` restart。終了コード 0。firewalld のジャーナルに警告なし |
| 移行後の firewalld | `--get-active-zones`: `public` に `wg0 end0`。`--get-active-policies`: 同梱の `allow-host-ipv6` だけ。permanent 側からも `wireguard` ゾーンと 6 policy が消え、`/etc/firewalld/policies/` は空、`zones/wireguard.xml.old` も無い（`public.xml.old` は残る） |
| nftables | `filter_FWD_public_allow` に `oifname "wg0" accept` と `oifname "end0" accept` が入った（`wg0` から入って `wg0` へ出る折り返しもこれで通る） |
| トンネルの復旧 | restart から約 40 秒で拠点 A（CGNAT 側、keepalive 25 秒）とのハンドシェイクが再成立。`wg0` の経路（相手トンネル IP・相手 LAN・クライアント `/32`）も戻った |
| 拠点間の疎通 | WG ホスト B から拠点 A のトンネル IP と Router A へ `ping -I ${WG_B_LAN_IP}` が 3/3 応答 |
| 送信元がトンネル IP の場合 | `ping ${ROUTER_A_LAN_IP}`（送信元 `${WG_B_TUN_IP}`）は `From ${WG_A_TUN_IP} Packet filtered`。**未移行の拠点 A** の policy が rich rule で送信元を拠点 B LAN に限定しているため。拠点 A を移行すれば消える見込み |

未確認: 拠点 A の実機での移行、クライアント同士の疎通、トンネル越しの Cockpit。**`wg0 → wg0` の折り返しと、トンネル越しの WG ホスト自身への ssh は、2026-09-22 に PC クライアントから確認した**（→ [wireguard-road-warrior.md の付録](wireguard-road-warrior.md#付録-実機での検証記録)）。

#### 登録簿に無い peer の消失（2026-09-21、拠点 B）

稼働中の拠点 B のホストで、外出先のスマートフォンから拠点の LAN（ルーターと WG ホスト自身）に届かなくなった。**ホスト側の設定には問題が無く、原因はその端末の `[Peer]` が `wg0.conf` から消えていたこと**だった。

| 時刻（2026-09-20） | 起きたこと |
|---|---|
| 07:42 | 手動手順で `wg0.conf` にクライアント 2 台の `[Peer]` を直接書き、`wg-quick` を restart（ジャーナルに 2 台分の `ip -4 route add <CLIENT_TUN_IP>/32 dev wg0` が残っていた） |
| 12:28 | `wg-vpn.sh client add B <名前>` を実行。このとき `clients.list` が**新規作成**され、そのクライアント 1 台だけの登録簿になった |
| 12:29 | `apply B` が登録簿から `wg0.conf` を作り直し、**手で書いた 2 つの `[Peer]` が消えた**（直前に退避された `wg0.conf.bak-<日時>` には残っていた） |

切り分けに使った確認（すべて読み取りのみ。ホスト側は問題なしと分かった）:

| 確認項目 | 結果 |
|---|---|
| `ip route` / `sysctl net.ipv4.ip_forward` | クライアントの `/32` と相手拠点 LAN の経路あり、`ip_forward = 1` |
| `firewall-cmd --zone=public --list-all` | `end0` と `wg0` が同じゾーン、`forward: yes`、旧 policy なし（移行済み） |
| `nft list ruleset` | `filter_FWD_public_allow` に `oifname "wg0" accept` と `oifname "end0" accept`、`filter_IN_public` の末尾に `meta l4proto { icmp, ipv6-icmp } accept`（ホスト自身への ping も通る） |
| ルーターの静的経路 | `ping -I <WG ホストのトンネル IP> <ROUTER_B_LAN_IP>` が 2/2 応答（ルーターはトンネル網の経路を持っている） |
| `wg show` と `clients.list` の突き合わせ | 両者は一致するが、**端末が持っている公開鍵（`/etc/wireguard/clients/<名前>.pub` に残っていた）がどちらにも無い** |

`[Peer]` が無い相手とはハンドシェイクが成立しないので、拠点 LAN だけでなく WG ホストのトンネル IP を含めて**すべて無応答**になる。クライアント側アプリの「最新のハンドシェイク」は消える前の時刻を表示したままのことがあるので、ホストでの `sudo wg show`（`latest handshake` と受信バイト）と `tcpdump -ni <LAN 側 NIC> udp port <WG_PORT>` で見るほうが早い。

再発防止として `apply` に検査を足し、`unshare -Urm` + tmpfs + スタブ（[スタブ環境での本実行](#スタブ環境での本実行)と同じ方法）で動作を確認した:

| 確認項目 | 結果 |
|---|---|
| 登録簿に無い `[Peer]` がある conf に `--dry-run apply B` | `ERROR: 既存の /etc/wireguard/wg0.conf に、登録簿（…/clients.list）に無い [Peer] が 1 個あります。このまま apply すると消えます` と `<conf>:<行番号>  Client <名前>  <CLIENT_PUBKEY>` を表示して終了コード 1。conf は書かない |
| `--drop-unknown-peers` を付ける | 同じ内容を `WARN:` で出して続行し、生成予定の conf を表示 |
| その `[Peer]` を登録簿に足してから実行 | `ERROR` も `WARN` も出さずに通る |
| `bash -n` | OK（`shellcheck` はこのマシンに無いため未実施） |

復旧（2026-09-21、拠点 B の実機）: `client add B <名前>`（鍵を作り直し）→ `apply B` → `client show --qr` で端末に取り込み直した。

| 確認項目 | 結果 |
|---|---|
| `client list` / `wg0.conf` | クライアント 2 台になり、`ip route` に `<CLIENT_TUN_IP>` の `/32` が 2 本入った |
| `wg show` | その端末の `[Peer]` の `latest handshake` が 1 分前、`transfer` は受信・送信とも増える（endpoint はモバイル回線のグローバル IP） |
| 端末からの疎通 | 拠点 B の LAN（`<ROUTER_B_LAN_IP>` と `<WG_B_LAN_IP>`）に到達 |

これで**スマートフォンの公式アプリ + モバイル回線**という組み合わせが実機で通ることも確認できた。未確認: この端末（スマートフォン）から拠点 A の LAN への折り返し。ただし**別の PC クライアントからは 2026-09-22 に届くことを確認した**（拠点 A は旧レイアウトのまま）（→ [wireguard-road-warrior.md の付録](wireguard-road-warrior.md#付録-実機での検証記録)）。

### 付録: 構成図の再生成

`nwdiag` / `seqdiag` を直接呼ばずに [`scripts/render-diagrams.py`](../../scripts/render-diagrams.py) を通すのは、**両方が載っている blockdiag 3.0.0 が Pillow 10 以降で動かない**ため。`ImageFont.getsize()` と `Image.ANTIALIAS` が Pillow 10 で削除されており、そのまま実行するとどちらも次で止まる（実測。seqdiag は Pillow 12.3 で確認）。

| 後処理 | 理由 |
|---|---|
| 白い背景の矩形を最初の子要素として挿入する | **blockdiag の SVG は背景が透明で、線と文字が黒**。GitHub のダークテーマに置くと図が沈んで見えなくなる。`nwdiag --no-transparency` は `(PNG only)` で SVG には効かない |
| `font-family` に CJK フォントを前置する | blockdiag は `font-family="sans-serif"` としか書かない。フォント fallback をしないレンダラではこれが Latin 専用フォントに解決され、**日本語だけが消える**（cairosvg で実際に起きた）。ブラウザは fallback するので GitHub 上では出るが、指定しておくほうが確実 |
| `viewBox` の幅を実測して広げる | blockdiag は**ノードの位置だけでキャンバス幅を決める**ので、右端のノードに付く長いラベルが canvas の外に出て切れる。実際に `${SITE_B_LAN}.100` の末尾が欠けていた |

### 付録: クリーンインストールした VM 2 台での本実行（2026-10-06）

ISO から入れた AlmaLinux 10.2 Workstation の x86_64 VM 2 台で、現行の `wg-vpn.sh` を本実行した。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active。管理用の NAT NIC を残し、隔離 LAN の別 NIC に検証用の LAN IP を足した。鍵・登録名・IP はすべて検証用。

- `site.env` の編集は、例をコピーしたあと検証専用の値を入れ、両 VM に同じファイルを置いた。Endpoint は隔離 LAN の IP、拠点 LAN・トンネル・クライアント帯は例と同じ別々の帯にした。エディター操作の検証は含めていない
- 手順 4 の `keygen` で `wireguard-tools 1.0.20250521-1.el10` と `systemd-resolved` が入り、ホストの鍵ができた。resolved は disabled のまま
- 手順 7・8 の dry-run と apply が通り、`wg-quick@wg0` は enabled/active。実カーネルの WireGuard がハンドシェイクし、firewalld は LAN と wg0 を public に入れた
- LAN 上の相手は、それぞれの VM 内の network namespace と veth で用意した。試験用の veth も public に入れ、相手 LAN への往復経路を設定した。両 LAN の間の ping は双方向 0% 損失、tracepath は相手 wg0 を経由する 3 ホップ、MTU 1420。TCP の HTTP 応答も 200
- 3 台目の VM を Road Warrior にし、クライアント生成の公開鍵登録・apply・conf 発行・両 LAN への通信・LAN からの逆方向を確認した（[同日の Road Warrior の記録](wireguard-road-warrior.md#付録-クリーンインストールした-vm-での検証2026-10-06)）
- 登録を消した後の通常の dry-run は、削除したクライアントの鍵だけを未知 peer として列挙して停止した。控えた鍵と照合してから `--drop-unknown-peers` の dry-run と apply を通し、登録簿と動作中の peer から消えた
- 両 VM で backup → remove → purge → restore の dry-run → restore → apply を通した。元と復元後のホスト秘密鍵が一致し、鍵と conf は root の 0600、site.env は元の一般ユーザーの 0600。サービスとハンドシェイクも戻った。同じ VM で設定を全削除して戻した確認で、OS 自体の入れ直しは行っていない

- 両 VM の再起動後、`wg-quick@wg0` は SSH ログイン前に active になり、`ip_forward=1` とハンドシェイクが復帰した。トンネル IP と相手のホストの LAN IP への ping が双方向 0% 損失だった。試験用 namespace は再起動で消えるため、この起動後の確認は LAN の端末役への通信ではない

`router A` のルーター向け案内表示、手順 16 のホスト上のクライアント用 conf 削除と、手順 17 の status も通した。status は経路・enabled/active・ip_forward・public ゾーン・登録したクライアントの一覧を表示した。秘密鍵をクライアント側で生成する経路を選んだため、この conf の PrivateKey は置き換え前のプレースホルダーだった。

#### 間欠的な終了 141 の原因と修正

クライアントを登録する Road Warrior の手順 6 で、`client add` は成功したが、続く apply が出力なしで終了 141 になった。`iface_of_ip` の `ip -o -4 addr show | awk ... { print $2; exit }` が、最初の一致でパイプを閉じ、`ip` が SIGPIPE で終わることが原因。`set -o pipefail` により関数全体が失敗する。実 VM でこの読み取りだけを 1000 回繰り返し、117 回が 141、883 回が成功だった。

最初の一致を変数に控え、最後まで読んで `END` で表示する形に直した。同じ VM の 1000 回はすべて成功。`bash -n` と ShellCheck 0.11.0 の `shellcheck -x` は指摘なし。登録の無い状態に戻したうえで、クライアント登録 → apply → conf 表示のブロックも終了 0 で通した。

物理ルーターのポート転送・静的経路、インターネットの NAT/CGNAT、スマートフォンの QR 読み込み、実機の起動は今回の検証に含めていない。手順 9 の実ルーター操作が不要な隔離 LAN での確認であり、その手順を検証済みにはしていない。

### 付録: 新規 VM での現行手順の再検証（2026-10-06）

同日の先行検証に使った VM と分け、ISO 導入直後の AlmaLinux 10.2 Workstation から新しい x86_64 VM を用意して、`5da3478` の現行本文を再検証した。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active。一般ユーザーの SSH PTY にブラケットペースト無しで貼り、手順ごとに結果を確認した。

新しい VM 2 台を A/B とし、管理用 NAT NIC と検証 VM 間だけの隔離 LAN を使った。現行スクリプトを LF のまま VM に配置し、`site.env.example` に新規公開鍵・隔離 LAN の Endpoint を入れて両側へ写した。エディター操作と実ルーターの設定は含めていない。

- `keygen`、手順 7 の dry-run の目視確認、8 の apply、17 の status が成功した。wireguard-tools は `1.0.20250521-1.el10`、resolved は追加依存として入り disabled のまま。public の自動検出・wg0 の所属・ゾーン内転送・51820/udp・ip_forward=1・サービスの enabled/active を確認した
- 各 VM 内に veth と network namespace で LAN の端末役を用意した。両 LAN の間の ping は双方向 0% 損失。HTTP/TCP は双方 200、tracepath は相手 wg0 を含む 3 ホップ・PMTU 1420、経路は wg0 だった。実カーネルでハンドシェイクと送受信を確認した
- 3 台目の VM では Road Warrior のクライアント生成の公開鍵を登録した。両 LAN の ICMP/TCP と、両拠点・端末役からの逆方向 ping も成功した（[今回の Road Warrior の記録](wireguard-road-warrior.md#付録-新規-vm-での現行手順の再検証2026-10-06)）
- 削除 1〜3 の通常 dry-run は、削除した検証用クライアントの公開鍵だけを未知 peer として表示して終了 1 になった。鍵を照合して 4 の明示的な dry-run を確認し、5・6 の適用・一覧で登録簿と動作中の peer から消えた
- 両 VM のバックアップと復旧 1・3・4・7・8 が成功した。さらに archive を確認してサービスを止め、ホスト鍵・公開鍵・現行 conf・site.env の 4 ファイルを実際に除去し、3・4・7・8 で戻した。元の 4 ファイルの sha256 がすべて一致し、サービスとハンドシェイクが戻った。OS の入れ直しではない

OS 再起動後、A の WG サービスは 14:00:52 JST（SSH セッション 14:00:57）、B は 14:03:25（SSH 14:03:28）に active になった。相手のトンネル IP と WG ホストの LAN IP への ping は双方 0% 損失。端末役の namespace は再起動で消えるため、再起動後の ping は LAN の端末役への確認ではない。

ロールバック 1〜4 を A/B の両方で通した。wg0・現行 conf と鍵・~/wg・sysctl ファイル・51820/udp の開放が消え、ip_forward は 0、追加の wireguard-tools/resolved も削除された。取得したバックアップ archive は保持した。`router A/B` は表示のみで、実ルーター・NAT 越しの Endpoint・DDNS・実機の現行レイアウトはこの再検証の対象外。

### 手順中の実測・検証状況の記録

それでも WG ホストで絞りたい場合は、LAN 側ゾーンに rich rule を足す（例: 拠点 B のクライアント帯から拠点 A の LAN への転送を拒否する。本書では未検証）。

### 手順中の実測・検証状況の記録

- Linux ルーター（検証時の Router A）は **ICMP Redirect** を返し、それを受け入れたクライアントは以降 WG host A に直接送る（`ip route get` に `<redirected>` と出る）

### 手順中の実測・検証状況の記録

検証では、Redirect を受け入れる場合・拒否する場合（`accept_redirects=0`）の両方で双方向 ping・TCP が通った。ただし **Router A には NAT やファイアウォールの状態追跡を持たせていない**。

### 手順中の実測・検証状況の記録

- 双方向に通信するという今回の要件は満たせないので、**最後の手段**としてだけ使う。本書では未検証

### 手順中の実測・検証状況の記録

- 付録の検証では、`Endpoint` を持たない側の `wg show` に、相手の endpoint が表示された（[付録](#待ち受けポートを開け忘れた場合)）

### 手順中の実測・検証状況の記録

本書の検証では `DNS =` を使っていない。

### 手順中の実測・検証状況の記録

クライアント conf の `Endpoint` に DDNS 名を書いた場合も同じだが、**公式アプリは接続のたびに名前解決する**ので `reresolve-dns.sh` のような仕組みは要らない。本書では未検証。

### 手順中の実測・検証状況の記録

wg-quick は `MTU` を指定しない場合、外側の経路の MTU から自動で決める。本書の検証環境（MTU 1500 の veth）では **1420** だった。

### 手順中の実測・検証状況の記録

- 本書の検証環境（MTU 1500 の veth）では、この問題は起きていない

### 手順中の実測・検証状況の記録

- 検証は namespace を使っていたため、**実際の OS 再起動での確認はしていない**

### 手順中の実測・検証状況の記録

- `systemctl restart` と `firewall-cmd --complete-reload` の後に、ゾーン割り当て・経路・疎通が戻ることは確認済み

### 手順中の実測・検証状況の記録

```
$ ip route get 192.168.120.100
192.168.120.100 dev wg0 src 10.99.0.1 uid 1000
$ ping -c1 -W2 192.168.120.100
1 packets transmitted, 0 received, 100% packet loss
$ ping -c1 -W2 -I 192.168.110.2 192.168.120.100      ← 送信元を LAN 側 IP にすると通る
1 packets transmitted, 1 received, 0% packet loss
```

### 全部消すときの補足

- **`remove` はゾーンの forward を戻さない。** `apply` 前に有効だったかが分からず、組み込みゾーン（`public` など）は firewalld 1.0 以降 forward が既定で有効なため
  - LAN 側 NIC 1 枚のホストでは、forward が有効でも転送先が無いので実害はない
  - 戻したければ `sudo firewall-cmd --permanent --zone="$LAN_ZONE" --remove-forward && sudo firewall-cmd --reload`
- firewalld はゾーンを書き換えるたびに `/etc/firewalld/zones/<ゾーン名>.xml.old` を残す（削除時だけではない）
  - LAN 側ゾーンの `.xml.old` は通常のバックアップなので、消さなくてよい
  - 旧レイアウト由来の `policies/*.xml.old` と `zones/wireguard.xml.old` は、`apply` / `remove` が消す

- `/usr/lib/firewalld/policies/gateway-lan-to-world.xml` にあり、`firewall-cmd --get-policies` には出るが `--get-active-policies` には出ない（実機で確認）
- 旧レイアウトの説明で「`trusted` や `internal` に入れると効いてしまう」と書いていたのは、素の 2.4.3 では当てはまらない

### 付録: 構成図の再生成

> 検証環境に最初から入っていた日本語フォント（Droid 系 2 つ）は、**どちらも Latin の字形を持たない**。`Client A` や `${SITE_A_LAN}` が豆腐になるため、Latin と日本語の両方を持つ Noto Sans CJK を入れている。

---

### 付録: 全部消すの手順 2 の後に残る控え（2026-10-08）

- [wireguard-road-warrior.md の検証記録の 2026-10-08 の付録](wireguard-road-warrior.md#付録-windows-11-pro-の-vm-での-vpn-の通し検証2026-10-08)の検証環境（AlmaLinux 10.2 の VM 2 台を拠点 A・B にした）を片付けたとき、[全部消す](../extra/wireguard.md#全部消すロールバック)の手順 1〜4 を両拠点で行った
- 拠点 A（`client add`・`client remove` の後の `apply` を行った方）では、`remove A --purge` の後も `/etc/wireguard` に `wg0.conf.bak-<日時>` の 2 つが残った（秘密鍵を含む conf の控え）。拠点 B（`apply` を 1 回だけ行った方）は `/etc/wireguard` ごと消えた
- `scripts/wireguard/wg-vpn.sh` の `cmd_remove` は、`--purge` で `$CONF`・`$KEY`・`$PUB` と登録簿にあるクライアント用 conf だけを消す。控え（`write_conf` と `restore_file` が作る `.bak-<日時>`）は消さない
- 本文の手順 2 に、控えが残る旨の箇条書きを足した。検証用の鍵なので、検証では手で消した。スクリプトは変えていない
