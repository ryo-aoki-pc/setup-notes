# WireGuard VPN 構築手順（site-to-site + road warrior / wg-quick + firewalld）の検証記録

[手順書](../wireguard.md)・[ロールバックと注意点](../extra/wireguard.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順 / 状態と疎通を確かめる / 手順 2: 本文中の記録

   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](#症状と原因の対応実測) を見る

### 実施手順 / 状態と疎通を確かめる / 手順 2: 補足: 疎通確認

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
    - AlmaLinux 10 の PC クライアント（拠点 B に接続）から拠点 A の LAN への折り返し（2026-09-22。→ [wireguard-road-warrior.md の付録](#road-warrior-付録-実機での検証記録)）
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
  - 2026-10-10: 任意節[回線に合わせて MTU を下げる](../wireguard.md#回線に合わせて-mtu-を下げる任意)を足した（[付録](#付録-実機の-2-拠点で-wg0-の-mtu-を下げた記録2026-10-10)）
    - 実機の 2 拠点で通したこと: この節の手順 1・4〜7 のブロック（本文の形のまま。手順 6 の `apply` は、拠点 A では落とし穴の節の `systemd-run` で ssh から切り離した）と、手順 2・3 に当たる `site.env` の書き換え（`vi` ではなく `sed`）
    - 確認したこと: 下げる前は拠点 B から拠点 A への MTU いっぱいの ping だけが約 5% 落ち、両拠点の `wg0` を 1380 にした後は落ちないこと、動いている `wg0` の MTU を変えてもトンネルと ssh が切れないこと、`apply` が conf に `MTU = 1380` を書き、restart で作り直された `wg0` が 1380 になること
    - **確認していないこと**: 手順 2 の `vi` での編集、OS の再起動、クライアント側の MTU、`Endpoint` が IPv6 の構成
    - 同じ日に、`client add` が作るクライアント用 conf にも `MTU =` を書くようスクリプトを変え、この節に手順 8（配布済みのクライアントに MTU を入れる）を足した（[付録](#付録-クライアント用-conf-に-mtu-を書く変更の検証2026-10-10)）
      - スタブ環境と、実機の dry-run で確かめた
      - `MTU =` 入りの conf をクライアントに取り込むことと、手順 8 の操作は、どのクライアントでも流していない
  - 2026-10-11: Road Warrior の手順書（`wireguard-road-warrior.md`）を、この手順書に統合した（[付録](#付録-road-warrior-の手順書を統合した記録2026-10-11)）
    - 外出先の PC の手順は、[AlmaLinux 10 の PC からつなぐ](../wireguard.md#almalinux-10-の-pc-からつなぐ)・[Windows 11 で使う](../wireguard.md#windows-11-で使う)などの節に、コマンドを変えずに移した。検証範囲は変えていない
      - AlmaLinux 10 の PC は、実機（2026-09-22）と新規の VM（2026-10-06）で通している。Windows 11 は VM だけで、実機では流していない
      - もとの検証記録は、[統合前の記録: Road Warrior](#統合前の記録-road-warriorもとは-wireguard-road-warriormd)に中身を変えずに移した
    - ホスト側の登録は、実施手順の[クライアントを登録する](../wireguard.md#クライアントを登録する)の 9 手順に作り直した
      - **作り直した形で通したのは、スタブ環境だけ**（鍵をホストで作る経路と、クライアントの公開鍵で登録する経路）
      - 実機・VM で通してあるのは、統合前の形（この手順書の手順 1〜7 と、Road Warrior の「WG ホストに登録する」の手順 1〜3）。作り直した手順は、その同じコマンドの組み替え
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
| クライアント | 検証は Linux の `wg-quick`。WireGuard 公式アプリ（Windows / macOS / iOS / Android）も同じ conf で使える想定。AlmaLinux 10 の PC を NetworkManager でつなぐ手順は [wireguard-road-warrior.md](../wireguard.md#almalinux-10-の-pc-からつなぐ)（2026-09-22 に実機で本実行） |

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
- forward 方式でも、2026-09-22 に拠点 B のホストで実機確認した。PC クライアントから相手拠点（拠点 A）の LAN へ届き、これが `wg0` から入って `wg0` へ出る転送にあたる（→ [wireguard-road-warrior.md の付録](#road-warrior-付録-実機での検証記録)）

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
  - **トンネル越しに WG ホストへ ssh して作業しているときは、この restart が自分のセッションの足元を切る**（切り離して実行する方法は [wireguard-road-warrior.md の付録](#road-warrior-落とし穴-apply-は作業中の-ssh-経路そのものを切る)）
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

未確認: 拠点 A の実機での移行、クライアント同士の疎通、トンネル越しの Cockpit。**`wg0 → wg0` の折り返しと、トンネル越しの WG ホスト自身への ssh は、2026-09-22 に PC クライアントから確認した**（→ [wireguard-road-warrior.md の付録](#road-warrior-付録-実機での検証記録)）。

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

これで**スマートフォンの公式アプリ + モバイル回線**という組み合わせが実機で通ることも確認できた。未確認: この端末（スマートフォン）から拠点 A の LAN への折り返し。ただし**別の PC クライアントからは 2026-09-22 に届くことを確認した**（拠点 A は旧レイアウトのまま）（→ [wireguard-road-warrior.md の付録](#road-warrior-付録-実機での検証記録)）。

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
- 「鍵を作って適用する」の手順 1 の `keygen` で `wireguard-tools 1.0.20250521-1.el10` と `systemd-resolved` が入り、ホストの鍵ができた。resolved は disabled のまま
- 「鍵を作って適用する」の手順 4・5 の dry-run と apply が通り、`wg-quick@wg0` は enabled/active。実カーネルの WireGuard がハンドシェイクし、firewalld は LAN と wg0 を public に入れた
- LAN 上の相手は、それぞれの VM 内の network namespace と veth で用意した。試験用の veth も public に入れ、相手 LAN への往復経路を設定した。両 LAN の間の ping は双方向 0% 損失、tracepath は相手 wg0 を経由する 3 ホップ、MTU 1420。TCP の HTTP 応答も 200
- 3 台目の VM を Road Warrior にし、クライアント生成の公開鍵登録・apply・conf 発行・両 LAN への通信・LAN からの逆方向を確認した（[同日の Road Warrior の記録](#road-warrior-付録-クリーンインストールした-vm-での検証2026-10-06)）
- 登録を消した後の通常の dry-run は、削除したクライアントの鍵だけを未知 peer として列挙して停止した。控えた鍵と照合してから `--drop-unknown-peers` の dry-run と apply を通し、登録簿と動作中の peer から消えた
- 両 VM で backup → remove → purge → restore の dry-run → restore → apply を通した。元と復元後のホスト秘密鍵が一致し、鍵と conf は root の 0600、site.env は元の一般ユーザーの 0600。サービスとハンドシェイクも戻った。同じ VM で設定を全削除して戻した確認で、OS 自体の入れ直しは行っていない

- 両 VM の再起動後、`wg-quick@wg0` は SSH ログイン前に active になり、`ip_forward=1` とハンドシェイクが復帰した。トンネル IP と相手のホストの LAN IP への ping が双方向 0% 損失だった。試験用 namespace は再起動で消えるため、この起動後の確認は LAN の端末役への通信ではない

`router A` のルーター向け案内表示、「クライアントを登録する」の手順 9 のホスト上のクライアント用 conf 削除と、「状態と疎通を確かめる」の手順 1 の status も通した。status は経路・enabled/active・ip_forward・public ゾーン・登録したクライアントの一覧を表示した。秘密鍵をクライアント側で生成する経路を選んだため、この conf の PrivateKey は置き換え前のプレースホルダーだった。

#### 間欠的な終了 141 の原因と修正

クライアントを登録する Road Warrior の「WG ホストに登録する」の手順 3（今の「クライアントを登録する」の手順 4・5）で、`client add` は成功したが、続く apply が出力なしで終了 141 になった。`iface_of_ip` の `ip -o -4 addr show | awk ... { print $2; exit }` が、最初の一致でパイプを閉じ、`ip` が SIGPIPE で終わることが原因。`set -o pipefail` により関数全体が失敗する。実 VM でこの読み取りだけを 1000 回繰り返し、117 回が 141、883 回が成功だった。

最初の一致を変数に控え、最後まで読んで `END` で表示する形に直した。同じ VM の 1000 回はすべて成功。`bash -n` と ShellCheck 0.11.0 の `shellcheck -x` は指摘なし。登録の無い状態に戻したうえで、クライアント登録 → apply → conf 表示のブロックも終了 0 で通した。

物理ルーターのポート転送・静的経路、インターネットの NAT/CGNAT、スマートフォンの QR 読み込み、実機の起動は今回の検証に含めていない。「鍵を作って適用する」の手順 6 の実ルーター操作が不要な隔離 LAN での確認であり、その手順を検証済みにはしていない。

### 付録: 新規 VM での現行手順の再検証（2026-10-06）

同日の先行検証に使った VM と分け、ISO 導入直後の AlmaLinux 10.2 Workstation から新しい x86_64 VM を用意して、`5da3478` の現行本文を再検証した。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active。一般ユーザーの SSH PTY にブラケットペースト無しで貼り、手順ごとに結果を確認した。

新しい VM 2 台を A/B とし、管理用 NAT NIC と検証 VM 間だけの隔離 LAN を使った。現行スクリプトを LF のまま VM に配置し、`site.env.example` に新規公開鍵・隔離 LAN の Endpoint を入れて両側へ写した。エディター操作と実ルーターの設定は含めていない。

- `keygen`、「鍵を作って適用する」の手順 4 の dry-run の目視確認、同じ項の手順 5 の apply、「状態と疎通を確かめる」の手順 1 の status が成功した。wireguard-tools は `1.0.20250521-1.el10`、resolved は追加依存として入り disabled のまま。public の自動検出・wg0 の所属・ゾーン内転送・51820/udp・ip_forward=1・サービスの enabled/active を確認した
- 各 VM 内に veth と network namespace で LAN の端末役を用意した。両 LAN の間の ping は双方向 0% 損失。HTTP/TCP は双方 200、tracepath は相手 wg0 を含む 3 ホップ・PMTU 1420、経路は wg0 だった。実カーネルでハンドシェイクと送受信を確認した
- 3 台目の VM では Road Warrior のクライアント生成の公開鍵を登録した。両 LAN の ICMP/TCP と、両拠点・端末役からの逆方向 ping も成功した（[今回の Road Warrior の記録](#road-warrior-付録-新規-vm-での現行手順の再検証2026-10-06)）
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

- [wireguard-road-warrior.md の検証記録の 2026-10-08 の付録](#road-warrior-付録-windows-11-pro-の-vm-での-vpn-の通し検証2026-10-08)の検証環境（AlmaLinux 10.2 の VM 2 台を拠点 A・B にした）を片付けたとき、[全部消す](../extra/wireguard.md#全部消すロールバック)の手順 1〜4 を両拠点で行った
- 拠点 A（`client add`・`client remove` の後の `apply` を行った方）では、`remove A --purge` の後も `/etc/wireguard` に `wg0.conf.bak-<日時>` の 2 つが残った（秘密鍵を含む conf の控え）。拠点 B（`apply` を 1 回だけ行った方）は `/etc/wireguard` ごと消えた
- `scripts/wireguard/wg-vpn.sh` の `cmd_remove` は、`--purge` で `$CONF`・`$KEY`・`$PUB` と登録簿にあるクライアント用 conf だけを消す。控え（`write_conf` と `restore_file` が作る `.bak-<日時>`）は消さない
- 本文の手順 2 に、控えが残る旨の箇条書きを足した。検証用の鍵なので、検証では手で消した。スクリプトは変えていない

### 付録: 実機の 2 拠点で wg0 の MTU を下げた記録（2026-10-10）

- 拠点 B の WG ホストへ外出先の PC から ssh すると操作が非常に遅い、という症状から調べた
- ホスト自体（CPU・メモリ・ディスク）に問題は無く、トンネルの中の MTU いっぱいのパケットだけが落ちていた
- 両拠点の `wg0` の MTU を 1420 から 1380 に下げ、落ちなくなることを確かめた
- この記録をもとに、手順書に[回線に合わせて MTU を下げる](../wireguard.md#回線に合わせて-mtu-を下げる任意)の節を足した。以下の「手順 N」は、この節の手順を指す

| 項目 | 値 |
|---|---|
| 実施日 | 2026-10-10 |
| 機器 | 両拠点とも Raspberry Pi 5 Model B Rev 1.0（実機） |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64、カーネル 6.12.96-20260724.v8.1.el10、SELinux Enforcing |
| `wireguard-tools` | 1.0.20250521-1.el10 |
| 拠点 A | `SITE_A_PUBLIC` が空（この拠点からトンネルを張る）。`tracepath` の `pmtu` は 1460 |
| 拠点 B | グローバル IP があり、ルーターのポート転送で受ける。クライアントも受ける。`tracepath` の `pmtu` は 1454 |
| `Endpoint` | IPv4 |
| 下げる前の `wg0` の MTU | 両拠点とも 1420（`WG_MTU` は空） |
| 測定中の通信 | 拠点 B から拠点 A へ、Syncthing がファイルを送り続けていた |

IP アドレス・ホスト名・鍵は載せていない。`<WG_A_TUN_IP>` / `<WG_B_TUN_IP>` は各拠点の `wg0` のアドレス。

#### 下げる前の実測

拠点 B のホストから、分割を禁じた ping を大きさを変えて打った（`ping -c <回数> -i 0.2 -q -M do -s <大きさ> <WG_A_TUN_IP>`）。表の 3 つの組は、それぞれ組の中を同時に打った。外側の大きさは、16 バイトの倍数に詰めた中身に 60 を足した計算値（パケットは採っていない）。

| 組 | IP パケットの大きさ（`-s` の値） | 外側の大きさ（計算） | 落ちた数 / 打った数 |
|---|---|---|---|
| 1 | 84（指定なし。`-M do` も無し） | 156 | 0 / 200 |
| 1 | 1228（1200） | 1292 | 0 / 200 |
| 1 | 1368（1340） | 1436 | 0 / 200 |
| 1 | 1420（1392） | 1480 | 10 / 200 |
| 2 | 1394（1366） | 1468 | 11 / 200 |
| 2 | 1396（1368） | 1468 | 7 / 200 |
| 2 | 1408（1380） | 1468 | 8 / 200 |
| 3 | 1392（1364） | 1452 | 0 / 250 |
| 3 | 1393（1365） | 1468 | 12 / 250 |

- 落ちるかどうかの境は、中身 1392 バイト（外側 1452）と 1393 バイト（外側 1468）の間で、拠点 B の `pmtu` 1454 をまたぐ（[参考資料の計算](../reference/wireguard.md#回線に合わせて-mtu-を下げる任意--手順-1-補足-wg_mtu-に書く値)と合う）
- 外側が 1454 を超える大きさは、どれも 3.5〜5.5% 落ちた。超えない大きさは、合わせて 850 回のうち 0 回
- トンネルの外（`ping -c 100 -i 0.2 -q -s 1400 1.1.1.1`）は 0 / 100 で、回線そのものの損失ではなかった
- 拠点 B のホストの `nstat -az`（起動から約 20 分）: `IpReasmReqds` 9772、`IpReasmOKs` 4886、`IpReasmFails` 0、`IpFragCreates` 0
  - 分割されたパケットを受け取って組み立てていた。このホスト自身は分割していない（外へ出る分はルーターが分割している、とみた。ルーターでは確かめていない）
- TCP の接続（`ss -tin`）:
  - 拠点 B から拠点 A への Syncthing の接続（20 秒間）: 送った 31.6 MB のうち再送 0.80 MB（2.54%）。`wg0` の送信は 1.68 MB/s、`cwnd` は 4〜27
  - 拠点 B に接続した外出先の PC からの ssh（拠点 B のホストから PC への向き）: 送った 455,457 バイトのうち再送 149,076 バイト（33%）。`cwnd` 3、`rtt` 95 ms
  - 同じ PC との Syncthing の接続 2 本: 届いたのは 2,601 バイトと 5,719 バイトで、再送は 8,208 バイトと 9,576 バイト（1,368 バイトのセグメント 6 個分と 7 個分）
  - 同じ時間帯の、拠点 B の LAN からの ssh は再送 0

#### 行ったこと

- 拠点 B、拠点 A の順に、`sudo ip link set dev wg0 mtu 1380` で動いている `wg0` の MTU を下げた（手順 4 に当たる。このときは値を直接書いた）
  - トンネルは切れなかった。拠点 A へは、拠点 B からトンネル越しの ssh で入ったまま行った
- 次の起動に備えて、両拠点の `/etc/wireguard/wg0.conf` の `[Interface]` の直後に `MTU = 1380` の行を手で足した
  - 元の conf は `wg0.conf.bak-20261010` に控えた（秘密鍵を含む）。`wg-quick strip wg0` が通ることだけ確かめた
- 両拠点の `~/wg/site.env` の `WG_MTU` を `1380` にした（手順 2・3 に当たる。`vi` ではなく `sed` で書き、両拠点の sha256 が一致することを確かめた）
- 手順 1・4・5・7 のブロックを、本文に載せた形のまま両拠点で流した（拠点 B では `A` と `WG_B_TUN_IP` を読み替えた。手順 4 は同じ値の入れ直し）
  - 手順 1: 拠点 A は `pmtu 1460`、拠点 B は `pmtu 1454`（どちらも、流したときの `mtu` は下げた後の 1380）
  - 手順 5: 両拠点とも `[Interface]` に `MTU = 1380` が出て、終了コードは 0。未知 peer の停止は無かった。スクリプトは、拠点 B が `2697a08`、拠点 A が `cf8774d`
  - 手順 7: 両拠点とも `mtu 1380`、小さい ping も MTU いっぱいの ping（`1352(1380) bytes`）も 0 / 100
- 手順 6 の `apply` は、ここまでを確かめた後、同じ日に両拠点で流した（下の「手順 6 の apply の本実行」）

#### 下げた後の実測

| 時点 | 向き | ping（`-c <回数> -i 0.2 -q -M do`） | 結果 |
|---|---|---|---|
| 拠点 B だけ下げた直後 | B → A | `-s 1352`（1380 バイト）を 250 回 | 0 / 250 |
| 同 | B → A | `-s 1353` | `ping: sendmsg: Message too long` |
| 同（拠点 A は 1420 のまま） | A → B | `-s 1392`（1420 バイト）を 200 回、`-s 1364` を 200 回 | 0 / 200、0 / 200 |
| 両拠点を下げた後 | A → B | `-s 1352` を 200 回 | 0 / 200 |
| 同（Syncthing が 24.7 MB/s で送信中） | B → A | `-s 1352` を 150 回 | 1 / 150 |

- 拠点 A を下げる前の A → B は、外側が 1480 バイトになる ping でも落ちなかった。落ちていたのは、拠点 B から出ていく向きの分割されたパケットとみた（どこで落ちたかは確かめていない）
- `nstat` の `IpReasmReqds` の増分は、両拠点を下げた後の 30 秒間（Syncthing の送信中）で、拠点 A・拠点 B とも 0
- TCP の接続:
  - 拠点 B から拠点 A への Syncthing（拠点 B だけ下げた直後の 20 秒間）: 送った 379.3 MB のうち再送 0.37 MB（0.10%）。`wg0` の送信は 20.18 MB/s、`cwnd` は 156〜194
  - 同（両拠点を下げた後の 30 秒間）: 送った 739.6 MB のうち再送 0.52 MB（0.07%）
  - 拠点 A の LAN から拠点 B のホストへ張ってあった ssh の接続は、切れずに `mss:1380 pmtu:1420` から `mss:1340 pmtu:1380` に変わった
- 送信が増えた状態での ping（90 回ずつ）: `1.1.1.1` は 0 / 90・平均 6.6 ms、`<WG_A_TUN_IP>` は 0 / 90・平均 14.8 ms

#### 手順 6 の apply の本実行

上の実測の後、同じ日に、手順 6 の `apply` を両拠点で流した。流す前の状態は、両拠点とも動いている `wg0` が 1380、conf は手で足した `MTU = 1380`、`site.env` は `WG_MTU=1380`。

- **拠点 B**（22:03 JST、スクリプトは `2697a08`）: 本文の形のまま `sudo ./wg-vpn.sh -e ~/wg/site.env apply B` を流した。終了コード 0、5 秒
  - 出力は、既存の conf を `wg0.conf.bak-<日時>` に退避 → conf の書き込み → `90-wireguard.conf は変更なし` → `LAN 側ゾーン: public` → `success`（`firewall-cmd --reload`）→ `wg-quick@wg0 を起動しました`
  - restart で `wg0` は作り直され（`ip link` の番号が 4 から 5 に変わった）、MTU は 1380 になった
  - 拠点 A とのハンドシェイクは、`apply` を始めてから 20 秒で戻った（拠点 B は拠点 A の `Endpoint` を持たないので、拠点 A から張り直されるのを待つ）
  - 拠点 B の LAN からの ssh は切れなかった。拠点 A の LAN からトンネル越しに張ってあった ssh は、送信元のポートが変わっていた（切れて、つなぎ直されたとみた）
  - クライアントのスマートフォンは、約 2 分でハンドシェイクし直した
- **拠点 A**（22:05 JST、スクリプトは `cf8774d`。`2697a08` との違いはヘッダーのコメントだけ）: 拠点 B からトンネル越しの ssh で入り、[落とし穴の節](../wireguard.md#落とし穴-apply-は作業中の-ssh-経路そのものを切る)の `sudo systemd-run --unit=wg-apply-rw -p Type=oneshot /bin/bash <REPO>/scripts/wireguard/wg-vpn.sh -e <ENV_FILE> apply A` で切り離して流した
  - `journalctl -u wg-apply-rw` に拠点 B と同じ並びの出力が残り、`systemctl show wg-apply-rw -p Result -p ExecMainStatus` は `Result=success`・`ExecMainStatus=0`。始まりから終わりまで 4.5 秒
  - この ssh は切れず、5 秒後に `systemd-run` が戻った（この 1 回の結果で、切れない保証ではない）
- 両拠点の適用後:
  - conf は `[Interface]` の `PrivateKey` の後ろに `MTU = 1380` が入った。行の集合は、手で足した conf と同じ（並びだけが違う）
  - `wg-quick@wg0` は enabled / active。public ゾーンの interfaces（LAN 側の NIC と `wg0`）・ports・`forward: yes` は、適用の前と同じ
  - 手順 7 のブロックを流し直し、両拠点とも `mtu 1380`、小さい ping も MTU いっぱいの ping も 0 / 100
  - `nstat` の `IpReasmReqds` は、拠点 B の 20 秒間の増分が 0、拠点 A は適用の前から変わらなかった
  - 拠点間の Syncthing の TCP の接続は、両拠点の restart をまたいで同じ接続のまま続いた
  - `apply` の控え `wg0.conf.bak-<日時>` が、両拠点に 1 つずつ増えた（秘密鍵を含む）

#### 確かめていないこと

- OS の再起動の後に `wg0` の MTU が 1380 になること（`apply` の restart で、conf の `MTU =` から 1380 になることは確かめた）
- 手順 2 の `vi` での編集
- 外出先の PC からの ssh が直ったか（調べている間に PC がトンネルから外れ、下げた後は測れなかった）。クライアント側の MTU は 1420 のまま
- 分割されたパケットがどこで落ちていたか（拠点 B のルーター・回線・拠点 A の側のどれか）
- `Endpoint` が IPv6 の構成（80 を引く計算）と、1380 以外の値（計算上の上限の 1394 など）

#### 従来の記述との違い

- 上の[手順中の実測・検証状況の記録](#手順中の実測検証状況の記録-7)（MTU の 2 つ）と注意点にあった「wg-quick は `MTU` を指定しない場合、外側の経路の MTU から自動で決める」は、`/usr/bin/wg-quick` の `set_mtu_up` を読み、「出口の NIC の MTU から 80 を引いた値にする。ルーターの先の回線の MTU は見ない」に改めた（[注意点の MTU](../extra/wireguard.md#mtu)。過去の記録の文は書き換えていない）

### 付録: クライアント用 conf に MTU を書く変更の検証（2026-10-10）

- 上の付録の後、`client add` が作るクライアント用 conf にも `MTU =` を書くよう、`wg-vpn.sh` を変えた
  - 変えたのは `render_client_conf` だけ。`WG_MTU` に値があれば、`[Interface]` の `PrivateKey` の後ろに `MTU = <値>` を書く（拠点の conf と同じ位置）
  - 外出先のクライアントも拠点の回線を通るので、同じ MTU が要る（[参考資料の補足](../reference/wireguard.md#回線に合わせて-mtu-を下げる任意--手順-8-補足-クライアントにも入れる理由)）

#### スタブ環境

[スタブ環境での本実行](#スタブ環境での本実行)・[LAN 側ゾーン + forward 版のスタブ検証](#lan-側ゾーン--forward-版のスタブ検証2026-09-20)と同じやり方で、拠点 B の実機の上で、実機の設定に触れずに流した。

- `unshare -Urm` の中で `/etc/wireguard`・`/etc/sysctl.d`・`/etc/firewalld` に tmpfs を重ね、`ip`・`firewall-cmd`・`systemctl`・`dnf`・`sysctl`・`restorecon` のスタブを `PATH` の先頭に置いた。`wg`・`wg-quick`・`qrencode`・`python3`・`rpm` は本物
- `site.env` は、`site.env.example` に相手拠点の公開鍵と、下の表の値を入れたもの
- 変更前（`b2861e0`）と変更後のスクリプトを、条件ごとに新しい tmpfs で、同じ順に流した
  - `keygen A` → `client add A alice --dry-run` → `client add A alice` → `client show alice` → `client show alice --qr` → `client add A bob --pubkey … --ip 10.99.1.50` → `client show bob` → `client list` → `wg-quick strip`（alice の conf）→ `client remove bob`
- 出力は、鍵とパスを伏せてから比べた

| 条件 | 結果 |
|---|---|
| `WG_MTU` が空 | 変更前と変更後で、出力と作られた conf が同じ |
| `WG_MTU=1380` | 変更後だけ、dry-run の表示・alice の conf・bob の conf（`--pubkey`）に `MTU = 1380` が 1 行ずつ増えた。ほかの行は同じ |
| `WG_MTU=1380`・`WG_CLIENT_DNS=192.168.110.1` | `[Interface]` は `Address` → `PrivateKey` → `MTU` → `DNS` の順 |
| `WG_MTU=1200`（範囲の外） | 変更前と同じく `ERROR: WG_MTU=1200: 1280〜1500 で指定してください` で止まり、登録も conf も作らない |
| 権限と副作用（`WG_MTU=1380`） | `clients/` は 700、conf は 600。dry-run はファイルを作らない。スタブが受けた呼び出しは `ip -o -4 addr show` と `restorecon` だけ |
| `wg-quick strip`（`WG_MTU=1380`） | `MTU = 1380` 入りの conf を読めて、終了 0 |
| `client show alice --qr`（`WG_MTU=1380`） | QR コードが出る |

#### 実機の dry-run

拠点 B の実機（`WG_MTU=1380`）で、変更前と変更後のスクリプトの dry-run を比べた。どちらも何も書かない。

- `--dry-run apply B`: 出力の 41 行が同じ（拠点の conf は変わらない）
- `--dry-run client add B mtu-check`: 変更後だけ、`[Interface]` に `MTU = 1380` の 1 行が増えた。`/etc/wireguard/clients` も、登録簿の行もできていない

#### クライアントが conf の MTU を読むこと

ソースで確かめただけで、取り込みは流していない。

- NetworkManager 1.56.0 の `nm_conn_wireguard_import`（`src/libnm-client-impl/nm-conn-utils.c`）は、conf の `MTU` を `wireguard.mtu` にする
- WireGuard for Windows の `conf/parser.go` と、Android の公式アプリの `config/Interface.java` は、`[Interface]` の `mtu` を読む（どちらも master を見た）
- 拠点 B の実機の `nmcli -f wireguard.mtu connection show wg0`（wg-quick が作った `wg0`）は、`wireguard.mtu: 0` と出た

#### この変更で確かめていないこと

- `MTU =` 入りの conf をクライアントに取り込むこと（AlmaLinux 10・Windows 11・スマートフォンのどれも）
- 手順 8 の、配布済みのクライアントへの操作（実機の 3 台のクライアントは、この時点で 1420 のまま）
- `shellcheck -x`（このホストに入っていないので流していない。`bash -n` は通った）

### 付録: Road Warrior の手順書を統合した記録（2026-10-11）

- 利用者の依頼で、`wireguard-road-warrior.md` と、その extra・参考資料・検証記録を、この手順書の 4 ファイルに統合して消した（[almalinux-setup.md の統合](almalinux-setup.md)と同じ形）
- 節の移動とリンクの書き換えは一時的なスクリプトで行い、統合の前後を機械的に比べた。実機の設定には触れていない
- 当時の手順と今の手順の対応は、[統合前の記録: Road Warrior](#統合前の記録-road-warriorもとは-wireguard-road-warriormd)の冒頭の表

#### 移したもの

- 手順書: 外出先の PC の節（[AlmaLinux 10 の PC からつなぐ](../wireguard.md#almalinux-10-の-pc-からつなぐ)・[Windows 11 で使う](../wireguard.md#windows-11-で使う)・[Windows 11 の更新](../wireguard.md#windows-11-の更新)）と[落とし穴](../wireguard.md#落とし穴-apply-は作業中の-ssh-経路そのものを切る)を、実施手順の後ろの節にした
  - コードブロックは、次の 2 つを除いて 1 字も変えていない
  - 「クライアントを登録する」に吸収した、もとの「WG ホストに登録する」の手順 1・3 のブロック（下の「作り直した項」）
  - 「conf を取り込む」の手順 1 の `vi` の行のコメントにある手順番号（「WG ホストに登録する」の手順 3 → 手順 2）
- extra: もとの「ロールバック」は「AlmaLinux 10 の PC のロールバック」に名前を変え、「Windows 11 のロールバック」と並べた。注意点は、「AlmaLinux 10 の PC からつなぐときの注意点」と「Windows 11 の注意点」の見出しを付けて、注意点の節の末尾に置いた
- 参考資料: 補足の見出しを、今の節・項・手順番号に付け替えた。「選択した方針」は「外出先の PC で選択した方針」に名前を変え、「参照」は 1 つの一覧にまとめた
- 検証記録: [統合前の記録: Road Warrior](#統合前の記録-road-warriorもとは-wireguard-road-warriormd)に、中身を変えずに移した
- ほかの文書（README・windows-setup.md・samba-client.md の extra など）のリンクを、今の場所に直した。過去の検証記録の中の文書名（リンクの文字）は、当時のまま

#### 作り直した項

ホスト側の登録が、この手順書の「クライアントを登録する」と、Road Warrior の「WG ホストに登録する」の 2 か所にあったので、「クライアントを登録する」の 9 手順にまとめた。

| 今の手順 | もと |
|---|---|
| 1（変数と `client list`） | Road Warrior の「WG ホストに登録する」の手順 1 |
| 2（同名の旧登録を消す。コマンド無し） | 同じ項の手順 2 |
| 3（`client add`） | この手順書の手順 1 |
| 4（`client add --pubkey`） | この手順書の手順 2 と、Road Warrior の同じ項の手順 3 の 1 行目 |
| 5（`apply`） | この手順書の手順 3 と、同 2 行目 |
| 6（`client show`） | この手順書の手順 4 と、同 3 行目 |
| 7（`client show --qr`） | この手順書の手順 5 |
| 8（クライアントでの取り込み。コマンド無し） | この手順書の手順 6 |
| 9（ホストに残った conf を消す） | この手順書の手順 7 |

- 拠点とクライアントの名前は、コマンドに直接書く形（`A`・`laptop`）から、手順 1 の変数（`SITE`・`CLIENT_NAME`）に変えた
- 「AlmaLinux 10 の PC からつなぐ」の「WG ホストに登録する」は、この項を名指しする、コマンドの無い 2 手順になった

#### 機械的な点検

- コードブロック: 統合前の 8 ファイルに 111 個、統合後の 4 ファイルに 110 個。違いは次の 2 つだけ
  - 作り直した項: もとの 9 個（この手順書の 6 個と、Road Warrior の 3 個）が、今の 8 個になった（`SITE` と `CLIENT_NAME` の変数のブロックは、もとのまま）
  - コメントの手順番号を付け替えた 1 個
- リンク: リポジトリ全体の Markdown のローカルリンクを、ファイルと見出しのアンカーに突き合わせた。統合で切れたものは無い
- 見出し: 統合後の 4 ファイルで、統合によって新しく重なった見出しは無い
- `docs/wireguard.md` の `bash` のブロック 53 個と extra の 10 個の `bash -n`、`wg-vpn.sh` の `bash -n` と `--help` の表示

#### スタブ環境で流した結果

- [スタブ環境での本実行](#スタブ環境での本実行)と同じやり方で、拠点 B の実機の上で、実機の設定に触れずに流した
  - `unshare -Urm` の中で `/etc/wireguard`・`/etc/sysctl.d`・`/etc/firewalld` に tmpfs を重ね、スタブを `PATH` の先頭に置いた
  - スタブ: `ip`、`firewall-cmd`（ゾーンの ports・interfaces・forward を持つ）、`systemctl`、`dnf`、`sysctl`、`restorecon`、`sudo`（uid 0 の中なので、引数をそのまま実行する）
  - `site.env` は `site.env.example` に相手拠点の公開鍵を入れたもの。`~/setup-notes` は作業中のリポジトリへのリンク。先に `keygen A` を流した
- ブロックは、本文から抜き出した形のまま、1 つのシェルで順に流した

| 流したブロック | 結果 |
|---|---|
| 手順 1 → 3 → 5 → 6 → 7 → 9（鍵をホストで作る経路。変数は既定の `SITE=A`・`CLIENT_NAME=laptop`） | `client list` は `登録済みクライアントはありません`。`laptop` が `10.99.1.1` で登録された。`apply` は `wg0.conf`（相手拠点と `laptop` の `[Peer]`）と sysctl のファイルを書き、firewalld のスタブに `--add-port=51820/udp`・`--add-interface=wg0`・`--add-forward`・`--reload`、systemctl のスタブに `enable`・`restart` が届いた。`client show` に秘密鍵入りの conf、`--qr` に QR コードが出た。手順 9 の後、`/etc/wireguard/clients` は空 |
| 手順 1 → 4 → 5 → 6（クライアントの公開鍵で登録する経路。`CLIENT_NAME` と `CLIENT_PUBKEY` の値だけ書き換えた） | `win-laptop` が登録され、`apply` には同じ呼び出しが届いた。`client show` の `PrivateKey` は `<CLIENT_PRIVATE_KEY>` |
| 手順 4（`CLIENT_PUBKEY` が空のまま） | `中断: CLIENT_PUBKEY が空のまま。クライアントで作った公開鍵を、この項の手順 1 に入れて貼り直す` と出て、登録されない |
| 手順 3（`SITE` を空にして） | `SITE: この項の手順 1 の SITE が空のまま` で止まり、登録されない |

#### 統合で確かめていないこと

- 作り直した「クライアントを登録する」を、実機・VM の WG ホストで通すこと（実機の登録簿と `wg0.conf` には触れていない）
- 同じ項の手順 2（同名の旧登録を消す流れ。「クライアントを削除する」の節は変えていない）と、手順 8（クライアントでの取り込み）
- 移した節（AlmaLinux 10 の PC・Windows 11・ロールバック）の流し直し。コマンドを変えていないので、検証範囲は統合前のまま
- `shellcheck`（このホストに入っていない。スクリプトは `--help` に出るコメントの手順番号だけを変えた）

## 統合前の記録: Road Warrior（もとは wireguard-road-warrior.md）

もとの `wireguard-road-warrior.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭に `Road Warrior:` を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [WireGuard VPN 構築手順](../wireguard.md)の手順の対応は次のとおり。

| 当時の手順（wireguard-road-warrior.md） | 今の手順（wireguard.md） |
|---|---|
| 実施手順の「鍵を作る」の手順 1〜3 | 「AlmaLinux 10 の PC からつなぐ」の「鍵を作る」の手順 1〜3 |
| 実施手順の「WG ホストに登録する」の手順 1・2 | 実施手順の「クライアントを登録する」の手順 1・2 |
| 実施手順の「WG ホストに登録する」の手順 3 | 実施手順の「クライアントを登録する」の手順 4・5・6（`client add --pubkey` → `apply` → `client show`。1 つのブロックを 3 手順に分けた） |
| 実施手順の「conf を取り込む」の手順 1〜4 | 「AlmaLinux 10 の PC からつなぐ」の「conf を取り込む」の手順 1〜4 |
| 実施手順の「トンネルを確かめる」の手順 1〜5 | 「AlmaLinux 10 の PC からつなぐ」の「トンネルを確かめる」の手順 1〜5 |
| Windows 11 で使う（3 項）・Windows 11 の更新 | 同じ名前の節と項（手順番号も同じ） |
| ロールバックの手順 1〜3 | extra の「AlmaLinux 10 の PC のロールバック」の手順 1〜3 |
| Windows 11 のロールバックの手順 1〜3 | extra の「Windows 11 のロールバック」の手順 1〜3 |
| 注意点 | extra の注意点の「AlmaLinux 10 の PC からつなぐときの注意点」と「Windows 11 の注意点」 |
| wireguard.md の「クライアントを登録する」の手順 1〜7 | 同じ項の手順 3〜9 |

### Road Warrior: 最新の確認範囲（Windows 11）

- 通したこと（どれも Windows 11 Pro の同じクリーン VM。実機ではない）
  - 2026-10-06〜07: Windows 節の「Windows 11 で WireGuard と鍵を用意する」の手順 3・4 の新規導入と署名・版、同じ項の手順 6 の鍵の生成・形式・ACL、CLI による ManagerService の一時作成と削除（[付録](#road-warrior-付録-windows-11-pro-の-vm-での新規導入の検証2026-10-06)）
  - 2026-10-08: AlmaLinux の VM 2 台を拠点 A・B にした検証環境に向けて、Windows 11 で使うの 3 項の全部（窓・鍵・WG ホストへの登録・取り込み・トンネル・疎通・ハンドシェイク・切断・後片付け）、更新、ロールバック（WG ホストのクライアントの削除を含む）（[付録](#road-warrior-付録-windows-11-pro-の-vm-での-vpn-の通し検証2026-10-08)）
- 確認していないこと
  - インターネット越し（物理のルーターのポート転送・NAT・DDNS）、テザリングなどへのつなぎ替え、張ったままの再起動、サスペンド復帰、Wi-Fi の切り替え
  - 既存の鍵がある場合の「Windows 11 で WireGuard と鍵を用意する」の手順 6 の分岐、arm64 の Windows、Windows の実機
- 秘密鍵の値やハッシュは記録していない。以降の既存記録は、各実施日・対象版・範囲に従う履歴として保持した

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### Road Warrior: 補足

#### Road Warrior: 操作上の注意と併記されていた記録

   - **ファイル名は `wg0.conf` にする。** NetworkManager がファイル名から接続名とインターフェース名を決める（実測で確認 → 「conf を取り込む」の手順 2 の補足）

#### Road Warrior: 操作上の注意と併記されていた記録

   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](#症状と原因の対応実測)

#### Road Warrior: 操作上の注意と併記されていた記録

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と出て、`winget list` に `WireGuard.WireGuard` の行が出ればよい（版は実行した日の最新。2026-10-03 は 1.1.1）

#### Road Warrior: 操作上の注意と併記されていた記録

   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](#症状と原因の対応実測)

#### Road Warrior: 実施手順 / conf を取り込む / 手順 2: 補足: conf と秘密鍵

- `sed` の区切りを `|` にしているのは、base64 の鍵に `/` が含まれるため（`|` `&` `\` は base64 に含まれない）
- `$(cat …)` の展開結果は端末に出ない。シェルの履歴には展開前の文字列が残るので、鍵は残らない
- 2 つの `grep -c` は「置き換え前に `PrivateKey` 行がちょうど 1 行あること」と「置き換え後に 44 文字の鍵になったこと」の確認
- `sed -i` は元ファイルのモード（`umask 077` の 0600）を引き継ぐ
- ファイル名を `wg0.conf` にするのは、NetworkManager が `import` で接続名とインターフェース名をファイル名から決めるため（実測で `connection.id` / `connection.interface-name` とも `wg0` になった。有効なインターフェース名 + `.conf` でないと拒否されるかは未確認）

#### Road Warrior: 実施手順 / conf を取り込む / 手順 4: 補足: import

- `nmcli(1)` の man は `connection import` を「VPN 設定のみ」と書いているが、WireGuard の wg-quick 形式も読む。`client show` が出す形式（`#` で始まるコメント行・空行・`PersistentKeepalive`）はそのまま読めた（実測）
- `/usr/share/doc/NetworkManager/NEWS` の WireGuard の項:
  - 1.16 で WireGuard に対応（nmcli は当時 peer の設定・表示だけ未対応）
  - 1.34 で「wg-quick 形式の import が負の排他的な `dns-priority` を設定しなくなった」「DNS ドメインとアドレスファミリ無効の import の修正」
  - 1.56 で「nmcli が WireGuard の peer の表示・管理に対応」
- 対応: `Address` → `ipv4.method manual` + `ipv4.addresses`、`DNS` → `ipv4.dns`（本手順では無し）、`PublicKey` / `Endpoint` / `AllowedIPs` / `PersistentKeepalive` → `wireguard.peers`
- `connection.autoconnect` は既定 `yes`。NetworkManager は autoconnect のプロファイルがあるとソフトウェアデバイスを作って張るので、import 直後に up になる（実測。`import` の直後に `connection show` を見ると `activating`、続けて `activated`）
- それを止める `import` のオプションは無いので、直後に `modify` で無効にし、張られていれば切る
- `-f` に `wireguard` を書くと `wireguard.*` の全項目が出る（この書式は NetworkManager 1.56 で確認済み）
- `wireguard.peers` には `allowed-ips=` / `endpoint=` / `persistent-keepalive=` まで 1 行で出る（実測）。この文書を書いた WG ホストの外部管理プロファイルでは公開鍵だけだったが、`import` した通常のプロファイルでは全項目が出る

#### Road Warrior: 実施手順 / トンネルを確かめる / 手順 1: 補足: up

- `GENERAL.STATE` / `IP4.ROUTE[n]: dst = …, nh = …, mt = …` の書式は、NetworkManager 1.56 で確認済み
- `mt` の値（WireGuard デバイスの既定 metric）は **50**（実測。`ipv4.route-metric` は `-1` のままなので、これは WireGuard デバイスの既定）。Wi-Fi の 600 より優先される（→ [注意点](../extra/wireguard.md#almalinux-10-の-pc-からつなぐときの注意点)）
- `wireguard.peer-routes yes` が `AllowedIPs` の経路を入れる（`nm-settings-nmcli(5)`）。`ip4-auto-default-route` は `/0` の peer が無いので関係ない
- MTU は `wireguard.mtu 0` のときカーネル既定の 1420 になる（実測）。`wg-quick` と違い NetworkManager は経路から MTU を計算しない
- `wg show` の `listening port` はランダム（`wireguard.listen-port 0`）。`latest handshake` が出ない場合は、鍵の対応（ホストの `clients.list` と `wg0.pub`）、`Endpoint`、ルーターのポート転送を疑う

#### Road Warrior: 実施手順 / トンネルを確かめる / 手順 2: 補足: 疎通確認

4 段階の意味:

- (1) `<WG_HOST_TUN_IP>` はトンネルそのもの（届かなければハンドシェイクか `AllowedIPs`）
- (2) `<WG_HOST_LAN_IP>` は WG ホスト自身の LAN 側（届かなければ `AllowedIPs` に拠点 LAN が無い）
- (3) ルーターは `wg0 → LAN` の転送と、ルーターのクライアント帯の静的経路
- (4) 相手拠点の WG ホストは、拠点間トンネルと相手ホストの `AllowedIPs`（クライアント帯）

→ [wireguard.md の「状態と疎通を確かめる」の手順 2 の補足](../wireguard.md#状態と疎通を確かめる)、[症状と原因の対応](#症状と原因の対応実測)。トンネル越しの ssh は [WG ホスト自身の ssh へ入る場合](../extra/wireguard.md#トンネル越しに-wg-ホスト自身の-ssh-や-cockpit-へ入る場合)。

#### Road Warrior: 実施手順 / トンネルを確かめる / 手順 4: 補足: down と日常の使い方

- `down` で NetworkManager が作ったリンク `wg0` は消える（実測: 直後の `ip link show dev wg0` が `Device "wg0" does not exist.`、経路 3 本と firewalld の active zones からも `wg0` が外れる）
- プロファイルは `nmcli connection show` に `wg0  wireguard  --  --` として残るので、次は `up` だけでよい
- GNOME の設定画面やクイック設定に VPN として出るかは未確認（`connection.type` は `vpn` ではなく `wireguard` なので、VPN の欄には出ないと思われる）

#### Road Warrior: 実施手順 / トンネルを確かめる / 手順 5: 補足: 後片付け

後片付けを最後にしているのは、import に失敗したときに `sudo nmcli connection delete wg0` → 「conf を取り込む」の手順 4 をやり直すのに conf が要るため。秘密鍵は「conf を取り込む」の手順 4 の時点で NetworkManager の keyfile に入っている。

**ガードの確認**（2026-09-22、この文書を書いた WG ホストで）:

- 各ブロックを `PATH` を空にした bash に変数が空のまま流し、値を使うブロックはすべて先頭のガードで止まって、ファイルを作る・書き換える・消すコマンドの起動が 1 つも試みられないことを確認した
  - 起動が試みられたのは、値を含まない読み取り系と、意図どおりの `nmcli connection up` / `down` / `delete` だけ
- 「鍵を作る」の手順 3 と「conf を取り込む」の手順 2 のブロックは、一時ディレクトリで本物の `wg` / `sed` を使って実行し、次を確認した
  - 鍵が 0600 で作られる
  - `PrivateKey` 行だけが 44 文字の鍵に置き換わり、他の行が変わらない
  - `PrivateKey` 行が 2 行あるときと `wg0.key` が無いときに、中断してファイルが変わらない

#### Road Warrior: Windows 11 で使う: 検証状況の記録

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、winget の定義、公式の MSI の中身と署名、WireGuard for Windows のソースと文書、Linux の PowerShell 7 での構文と模擬の実行だけ（[対象と検証環境](#road-warrior-対象と検証環境)）。

#### Road Warrior: Windows 11 で使う / Windows 11 で WireGuard と鍵を用意する / 手順 4: 補足: winget の定義と、入るもの

**winget の定義**（`WireGuard.WireGuard` 1.1.1。2026-10-03 の winget-pkgs。[付録](#road-warrior-付録-windows-11-の配布物と資料の調査2026-10-03)）

- `InstallerType: wix`（MSI）、`Scope: machine`。x64 のインストーラーは `https://download.wireguard.com/windows-client/wireguard-amd64-1.1.1.msi` で、winget が sha256 を確かめてから黙って入れる。x86 と arm64 の MSI もある
- `InstallerSwitches` の `Custom: DO_NOT_LAUNCH=1` を MSI に渡す。MSI は、入れ終えたときに `wireguard.exe` を起動して窓を出すが、この値があると起動しない（WireGuard の文書の「Enterprise Usage」）。そのため、マネージャーのサービスもまだ作られない（「Windows 11 で WireGuard と鍵を用意する」の手順 5）
- `UpgradeBehavior: install`（新しい版の MSI を上から入れる。[Windows 11 の更新](../wireguard.md#windows-11-の更新)）
- `--accept-source-agreements` と `--accept-package-agreements` は、winget を初めて使う PC で出る同意の問いに答えるため

**入るもの**（MSI の定義 `installer/wireguard.wxs` と、MSI から取り出した中身）

- `C:\Program Files\WireGuard\wireguard.exe`（窓・マネージャー・トンネルのサービスを兼ねる 1 つのプログラム。GUI のプログラムなので、PowerShell は終わるのを待たない）と `wg.exe`（wireguard-tools の `wg`。コンソールのプログラム）。どちらも WireGuard LLC の署名付き
- スタートメニューの「WireGuard」
- PC 全体の `PATH` の末尾に `C:\Program Files\WireGuard\` が足される。開いている PowerShell には効かないので、この文書のブロックはフルパスで呼ぶ
- 管理者の PowerShell から動かすので、UAC の確認は出ないはず

#### Road Warrior: Windows 11 で使う / Windows 11 で WireGuard と鍵を用意する / 手順 6: 補足: 鍵ペアと置き場所

- 実施手順の[鍵を作る](../wireguard.md#鍵を作る)の手順 3 と同じく、既に `wg0.key` があれば止まる（上書きすると、WG ホストに登録済みの公開鍵と対応しなくなる）
- 秘密鍵は、ブロックを囲む `& { … }` の中の変数で受けて、ファイルに書くだけ。ブロックが終わると変数は消える。PowerShell の履歴に残るのはコマンドの文字列で、鍵は残らない
- ファイルは `[IO.File]::WriteAllText` で ASCII（BOM 無し）で書く。Windows PowerShell 5.1 の `>` と `Out-File` は UTF-16 で書く
- `$priv | & $wg pubkey` は、末尾に CR LF を付けて ASCII で送る（Windows PowerShell 5.1 のパイプ）。`wg pubkey` は鍵の 44 文字の後ろの空白（CR と LF を含む）を読み飛ばす（wireguard-tools のソースの `pubkey.c` と `ctype.h`。Linux の `wg` で、CR LF 付きの入力から同じ公開鍵が出た。[付録](#road-warrior-付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
- `wg genkey` / `wg pubkey` は、トンネルのドライバー無しで動く
- アクセス権は、[Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)の `administrators_authorized_keys` と同じ考え方で、`/inheritance:r` で `C:\Users\<WIN_USER>` から受け継ぐ自分のユーザーの許可を外し、Administrators（`S-1-5-32-544`）と SYSTEM（`S-1-5-18`）だけにする。管理者ではない窓（UAC で権限を落としたもの）で動くプログラムからは読めない
- 管理者の PowerShell で作ったフォルダーの所有者は `BUILTIN\Administrators` になる

#### Road Warrior: Windows 11 で使う / Windows 11 で WG ホストに登録して取り込む / 手順 3: 補足: conf と秘密鍵

- 実施手順の[conf を取り込む](../wireguard.md#conf-を取り込む)の手順 1・2（`vi` に貼って保存し、`sed` で `PrivateKey` 行を置き換える）を、「Windows 11 で WG ホストに登録して取り込む」の手順 1 の関数にまとめた。エディタを開かずに、クリップボードの中身を読む（`Get-Clipboard -Raw` は、複数行を 1 つの文字列で返す。Windows PowerShell 5.1 にもある）
- 先頭が `[Interface]` でなければ止めるのは、端末からコピーしたときにプロンプトの行が入りやすいため。行の末尾の空白は落とす
- 2 つの確かめは、AlmaLinux 10 と同じ「置き換え前に `PrivateKey` 行がちょうど 1 行あること」と「置き換え後に 44 文字の鍵になったこと」
- ASCII（BOM 無し）・CR LF で書く。WireGuard の読み込みは行を LF で分けて前後の空白を落とすので、CR LF でも読める（ソースの `conf/parser.go`）。BOM 付きの UTF-8 は、先頭の行が `[Interface]` と見なされずに読めない（その読み込みの部分を Linux で動かして確かめた。[付録](#road-warrior-付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
- `client show` の出力は ASCII だけでできている（クライアントの名前は英数字・`-`・`_` だけ）。ASCII でない文字があれば、書くときに `?` に変わるので先に止める
- `wg0.conf` は、`%USERPROFILE%\wg-client` のアクセス権を受け継ぐ（Administrators と SYSTEM だけ）

#### Road Warrior: Windows 11 の更新 / 手順 1: 補足: 更新の動き

- winget の定義は `UpgradeBehavior: install` で、新しい版の MSI を上から入れる（MSI のメジャー アップグレード）。トンネルの設定（`Data`）は消えない（MSI が `Data` を消すのは、アンインストールのときだけ。ソースの `installer/customactions.c`）
- MSI は、入れる前に動いている WireGuard のサービス（`WireGuardManager` と `WireGuardTunnel$…`）を止め、入れ終えると起動し直す（同じソースの `EvaluateWireGuardServices`）。winget は `DO_NOT_LAUNCH=1` を渡すが、サービスの起動し直しには関係しないはず
- 窓の「今すぐ更新」と、コマンドの `& "$env:ProgramFiles\WireGuard\wireguard.exe" /update 2>&1 | ForEach-Object { "$_" }` は、`https://download.wireguard.com/windows-client/latest.sig`（Ed25519 の署名付きの、MSI の BLAKE2b の一覧）を確かめてから、その MSI を取って入れる（ソースの `updater/`、WireGuard の文書の「Enterprise Usage」）
- 本書では、新しい版が出ていないので、更新を試していない

#### Road Warrior: 対象と検証環境

- **目的**: [WireGuard VPN 構築手順](../wireguard.md)で建てた拠点の WG ホストに、外出先の AlmaLinux 10 または Windows 11 のノート PC から接続し、両拠点の LAN に届くようにする
  - 鍵は PC で作り、**公開鍵だけ**を WG ホストに登録する
  - AlmaLinux 10 では、トンネルを NetworkManager のプロファイル `wg0` として持ち、`nmcli connection up wg0` / `down wg0` で張る・切る（`wg-quick` は使わない。→ [代替](../reference/wireguard.md#代替-wg-quick-で張る場合)）
  - Windows 11 では、公式の WireGuard for Windows のトンネル `wg0` として持ち、`wireguard.exe /installtunnelservice` / `/uninstalltunnelservice`（窓の「有効化」「無効化」と同じ）で張る・切る
- **進め方**: **冒頭の変数ブロックに値を 1 度書き、以降のコマンドをそのまま貼る**
  - 「WG ホストに登録する」の手順 1〜3 と「トンネルを確かめる」の手順 3 だけは WG ホスト上で実行する（WG ホスト側の変数は「WG ホストに登録する」の手順 1 で設定する）
  - WG ホスト側は `wg-vpn.sh` の `client add --pubkey` → `apply` → `client show` で、[wireguard.md の「クライアントを登録する」の手順 2〜4](../wireguard.md#クライアントを登録する) と同じ
  - **Windows 11**（[Windows 11 で使う](../wireguard.md#windows-11-で使う)）: WireGuard for Windows を winget で入れ、鍵はその `wg.exe` で作る。`client show` の conf をクリップボードから読んで秘密鍵を入れ、WireGuard の設定の置き場所に写して暗号化させてから張る。管理者の Windows PowerShell 5.1 で関数を先に定義し、conf コピー後に関数名を手入力する。WG ホストでは同じ「WG ホストに登録する」の手順 1〜3 と「トンネルを確かめる」の手順 3 を使う
- **状態（AlmaLinux 10）**: **実機で本実行済み（2026-09-22）。クリーンインストールした x86_64 の VM でも現行ブロックを本実行した（2026-10-06）**
  - 2026-10-06: 先行検証とは別の新規 VM で現行本文を再検証した（[今回の記録](#road-warrior-付録-新規-vm-での現行手順の再検証2026-10-06)）。検証専用のアカウント・鍵・隔離 LAN を使った
  - 拠点 A の LAN にあるノート PC を**スマートフォンのテザリング回線に移してから**、拠点 B の WG ホストへ実施手順の全部（4 項）を通した
  - 確認したこと: 両拠点の LAN への ping、トンネル越しの ssh、拠点側からの逆方向 ping
  - NetworkManager の挙動として推定で書いていた項目は、1〜9 が実測で確定した
  - **確認していないこと**: サスペンド復帰・Wi-Fi の切り替え・`Endpoint` が DDNS 名のとき・GNOME の UI・`DNS =` がある場合など（→ [残っている未確認事項](#road-warrior-残っている未確認事項)）
  - **拠点の LAN の中からトンネルを張ることは、意図的に試していない**（[注意点](../extra/wireguard.md#almalinux-10-の-pc-からつなぐときの注意点)のとおり LAN の経路を奪うため）
  - 実測の記録は[付録](#road-warrior-付録-実機での検証記録)
  - 2026-09-28: 「鍵を作る」の手順 2、「conf を取り込む」の手順 4、「トンネルを確かめる」の手順 1 と、[ロールバック](../extra/wireguard.md#almalinux-10-の-pc-のロールバック)の手順 1のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-05: 「WG ホストに登録する」の手順 2 とロールバックの手順 3 を、公開鍵を照合してから削除を反映する共通手順への案内に変更した。新しい削除・鍵交換の順序は隔離したスタブで確認し、実機では流していない
  - 2026-10-10: 拠点が `WG_MTU` を下げているときは PC も同じ値にする案内を、注意点「MTU」に足した（[wireguard.md の検証記録の付録](#付録-クライアント用-conf-に-mtu-を書く変更の検証2026-10-10)）
    - `wg-vpn.sh` の `client add` が、`WG_MTU` に値があればクライアント用 conf に `MTU =` を書くようになった。「conf を取り込む」の手順 2 のコメントと、「トンネルを確かめる」の手順 1 の `mtu` のコメントを、それに合わせた（コマンドは変えていない）
    - **どれも PC では流していない**。NetworkManager 1.56.0 が取り込みで `MTU =` を `wireguard.mtu` にすることは、ソースを読んで確かめただけ。注意点の `nmcli connection modify wg0 wireguard.mtu 1380` も流していない
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](#road-warrior-付録-windows-11-の配布物と資料の調査2026-10-03)）:
    - 配布物: winget の `WireGuard.WireGuard` 1.1.1 の定義、公式の MSI（amd64）の sha256（winget の定義と一致）・BLAKE2b（公式の署名付きの `latest.sig` と一致。その署名も）・Authenticode の署名者、MSI の中の `wireguard.exe`（GUI のプログラム）と `wg.exe`（コンソールのプログラム）
    - WireGuard for Windows 1.1.1 のソースと文書: MSI の定義（`DO_NOT_LAUNCH`、アンインストールで `Data` を消す）、設定の置き場所への取り込みと暗号化・アクセス権、`/installtunnelservice` と窓の「有効化」が同じこと、トンネルの経路・MTU・キルスイッチの条件
    - `wg pubkey` が CR LF 付きの入力を受けること（Linux の wireguard-tools 1.0.20210914 と、ソースで）
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。[Windows 11 で WireGuard と鍵を用意する](../wireguard.md#windows-11-で-wireguard-と鍵を用意する)の手順 6、[Windows 11 で WG ホストに登録して取り込む](../wireguard.md#windows-11-で-wg-ホストに登録して取り込む)の手順 3（現在は同じ項の手順 1 の関数内）・4、[Windows 11 でトンネルを確かめる](../wireguard.md#windows-11-でトンネルを確かめる)の手順 2・3・5・6 と[Windows 11 のロールバック](../extra/wireguard.md#windows-11-のロールバック)の手順 1 のブロックは、Linux の pwsh で偽物のコマンドを使って流した（「Windows 11 でトンネルを確かめる」の手順 2・5 は、`wireguard.exe` と Windows のネットワークのコマンドレットも偽物。[付録](#road-warrior-付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
    - 「Windows 11 で WG ホストに登録して取り込む」の手順 3 で書いた `wg0.conf` が、WireGuard for Windows 1.1.1 の conf の読み込みの部分（Linux でビルドできるように写したもの）で読めること（BOM 付きの UTF-8 は読めないことも。同じ付録）
  - 2026-10-05: 取込みを、「Windows 11 で WG ホストに登録して取り込む」の手順 1 で関数定義 → 同じ項の手順 2 で conf をコピー → 同じ項の手順 3 で関数名を手入力、に分けた。18 ブロックの構文と、この操作順、空・コード・非 ASCII・PrivateKey 重複の拒否を Linux の PowerShell 7.6.6 とクリップボードのスタブで確認した。Windows の端末では貼っていない
  - 2026-10-10: 「Windows 11 でトンネルを確かめる」の手順 2 の `NlMtu` の箇条書きと注意点「MTU」を、conf に `MTU =` がある場合に合わせた。WireGuard for Windows の `conf/parser.go` が `mtu` を読むことを見ただけで、Windows では流していない
  - **確かめていないこと**: Windows で貼ること（すべての手順）、マネージャーの起動と窓、取り込みで `wg0.conf.dpapi` ができること、トンネルの経路・MTU・ネットワークの種類、拠点との疎通、張ったまま再起動したときに張られること、更新とアンインストール、サスペンド復帰と Wi-Fi の切り替え、arm64 の Windows

下表は実機（AlmaLinux 10 の PC 側）で採取した値。

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) x86_64 |
| カーネル | 6.12.0-211.56.1.el10_2.x86_64（`wireguard.ko` を同梱） |
| NetworkManager | 1.56.0-2.el10_2（Wi-Fi を NetworkManager が管理） |
| `wireguard-tools` | 1.0.20250521-1.el10（appstream。依存で `systemd-resolved` 257-23.el10_2.2.alma.1 が入るが `disabled` / `inactive` のまま） |
| firewalld | 2.4.3-4.el10_2（既定ゾーン `public`） |
| SELinux | Enforcing |
| 接続時の回線 | スマートフォンのテザリング（`<TETHER_NET>` を受領。両拠点の LAN・トンネル網と重ならないことを確認してから張った） |
| WG ホスト側 | [wireguard.md](../wireguard.md) の構成（`wg-vpn.sh`。AlmaLinux 10.2 aarch64、カーネル 6.12 系）。**実測では拠点 B がクライアントを受ける**（`WG_B_CLIENT_NET` を設定、`WG_A_CLIENT_NET` は空）。本文の例の値は `site.env.example`（拠点 A が受ける構成）のままにしてある |

Windows 11 の手順が前提にしている環境（流していない）:

| 項目 | 値 |
|---|---|
| OS | Windows 11（x64） |
| PowerShell | Windows PowerShell 5.1（管理者として実行） |
| ユーザー | Administrators の一員（Microsoft アカウントでもローカル アカウントでもよい） |
| WireGuard for Windows | 1.1.1（2026-09-20。winget の `WireGuard.WireGuard`、`wireguard-amd64-1.1.1.msi`。中の `wg.exe` は wireguard-tools 1.0.20260223） |
| 接続時の回線 | AlmaLinux 10 と同じく、拠点の LAN の外（スマートフォンのテザリングなど） |
| WG ホスト側 | AlmaLinux 10 の PC と同じ（変えるものは無い） |

![構成](../diagrams/wireguard-remote-client.svg)

図の Remote client が本書の PC。接続先拠点（図では拠点 A）の WG ホストにトンネルを張り、拠点 A・B の LAN に届く（→ [パケットの流れ](../reference/wireguard.md#パケットの流れremote-client--各拠点)）。

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。PC 側は[「鍵を作る」の手順 1](../wireguard.md#鍵を作る)、WG ホスト側は[「WG ホストに登録する」の手順 1](../wireguard.md#wg-ホストに登録する)の先頭で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。例は `site.env.example`（拠点 A がクライアントを受ける構成）の値。Windows 11 の PC は、[Windows 11 で WireGuard と鍵を用意する](../wireguard.md#windows-11-で-wireguard-と鍵を用意する)の手順 2 で、同じ名前の PowerShell の変数（`$WG_HOST_TUN_IP` など 4 つ）を設定する（鍵と conf の一時置き場は `%USERPROFILE%\wg-client` に決めてあり、変数にしていない）。
>
> | 変数 | 設定する場所 | 意味 | 例 |
> |---|---|---|---|
> | `${WG_DIR}` | PC | 鍵と conf の一時置き場。取り込んだら秘密鍵と conf は消す（「トンネルを確かめる」の手順 5）。WG ホストの `~/wg` と取り違えないよう別の名前にしてある | `~/wg-client` |
> | `${WG_HOST_TUN_IP}` | PC | 接続先拠点の WG ホストの `wg0` アドレス（`site.env` の `WG_A_TUN_IP`） | `10.99.0.1` |
> | `${WG_HOST_LAN_IP}` | PC | 同じホストの LAN 側 IP（`WG_A_LAN_IP`） | `192.168.110.2` |
> | `${ROUTER_LAN_IP}` | PC | 接続先拠点のルーターの LAN 側 IP（`ROUTER_A_LAN_IP`） | `192.168.110.1` |
> | `${PEER_WG_LAN_IP}` | PC | 相手拠点の WG ホストの LAN 側 IP（`WG_B_LAN_IP`） | `192.168.120.2` |
> | `${REPO}` / `${SITE}` | WG ホスト | このリポジトリの clone 先 / クライアントを受ける拠点（`A` か `B`） | `~/setup-notes` / `A` |
> | `${CLIENT_NAME}` / `${CLIENT_PUBKEY}` | WG ホスト | 登録簿（`clients.list`）に載せる名前 / 「鍵を作る」の手順 3 で PC に表示された公開鍵 | `laptop` /（`wg pubkey` の出力） |
>
> 出力例・表の中の値は `<CLIENT_NAME>` / `<CLIENT_TUN_IP>`（ホストが割り当てるトンネル IP）/ `<CLIENT_PUBKEY>` / `<SITE_A_PUBKEY>` / `<SITE_A_PUBLIC>` / `<WG_PORT>` / `<WG_HOST_TUN_IP>` / `<WIN_USER>`（Windows のユーザー名）などのプレースホルダで書いてある。
>
> - **`<...>` を含むコマンドは bash のコードブロックには置かない**（本文中のインラインコードで示し、値に読み替える）
> - 読者が値を入れる必要があるコードブロックは、先頭で変数が空なら中断するようにしてあり、値を入れずに貼っても何も実行されない
>
> 秘密鍵はこの文書に載せず、手順の中でも端末に表示しない。公開鍵も検証用の使い捨ての値なので載せない。

手順書全体に関わる理由・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### Road Warrior: 実施前の状態

AlmaLinux 10 の実機で、2026-09-22、「鍵を作る」の手順 2 の前に採取（採取コマンドは[付録](#road-warrior-付録-実機での検証記録)の「記録用ブロック」）。Windows 11 の PC は、[Windows 11 で WireGuard と鍵を用意する](../wireguard.md#windows-11-で-wireguard-と鍵を用意する)の手順 3 で確かめる（流していないので記録は無い）。

| 項目 | 状態 |
|---|---|
| OS / カーネル | AlmaLinux 10.2 (Lavender Lion) / `6.12.0-211.56.1.el10_2.x86_64 x86_64` |
| NetworkManager / `wireguard-tools` / `systemd-resolved` | `1.56.0-2.el10_2` / **未インストール** / **未インストール** |
| firewalld（既定ゾーン、active zones） | `2.4.3-4.el10_2`。既定 `public`、`public (default) interfaces: <WIFI_IF> bridge0` |
| SELinux | `Enforcing` |
| Wi-Fi デバイスと経路の metric | `<WIFI_IF>` が拠点 A の LAN に接続。`default via <ROUTER_A_LAN_IP> dev <WIFI_IF> proto dhcp metric 600` と `<SITE_A_LAN> dev <WIFI_IF> proto kernel scope link metric 600` の 2 本だけ |
| `/etc/resolv.conf` | `# Generated by NetworkManager` / `search lan` / `nameserver <ROUTER_A_LAN_IP>`（+ IPv6 の link-local が 1 行） |
| `nmcli connection show`（`wg0` が無いこと） | Wi-Fi・`bridge0`・`lo`・未使用のプロファイルのみ。`wg0` 無し |
| `/etc/wireguard`（無いこと）/ `lsmod`（未ロード） | `ls: cannot access '/etc/wireguard': No such file or directory` / `lsmod \| grep -c wireguard` が `0` |

#### Road Warrior: 選択した方針

- **NetworkManager（`nmcli connection import`）で張る**
  - PC の Wi-Fi を NetworkManager が管理しているので、トンネルも同じ管理下に置く。管理者が 2 つになるのを避ける
  - `wg-quick` が作った `wg0` は NetworkManager から `connected (externally)` に見え、NetworkManager が同名の一時プロファイル（`autoconnect yes`）を作る
    - この文書を書いた WG ホストで実測: `nmcli device status` に `wg0  wireguard  connected (externally)  wg0`
  - `import` はホストが出す conf をそのまま読むので、手で写すのは秘密鍵の 1 行だけ
  - RHEL 10 のドキュメントは `nmcli connection add` で組む方式（→ [代替](../reference/wireguard.md#代替-nmcli-connection-add-で組む場合rhel-のドキュメントの方式)）
- **鍵は PC で作り、公開鍵だけをホストに渡す**（→ [wireguard.md: クライアントの秘密鍵の扱い](../extra/wireguard.md#クライアントの秘密鍵の扱い)）
  - 秘密鍵が PC から出ない
  - `client show` の出力に秘密が無いので、渡す経路を選ばない
  - ホストに秘密鍵入りの conf が残らないので、wireguard.md の「クライアントを登録する」の手順 7 の `rm` も要らない（`--pubkey` で作った conf はプレースホルダのまま残してよい）
- **ファイル名は `wg0.conf`** — NetworkManager の importer はファイル名（`.conf` を除いた部分）を接続名とインターフェース名にする（実測）。`wg0` なら WG ホスト側と同じ呼び名になる
- **スプリットトンネル、`DNS =` 無し** — ホストが出す conf のとおり
  - `AllowedIPs` は両拠点の LAN とトンネル網だけで、それ以外の通信は今いるネットワークにそのまま出る
  - `site.env` の `WG_CLIENT_DNS` が空なので、resolv.conf にも触らない
  - 全トラフィックを通す構成（`0.0.0.0/0`）は[対象外](../extra/wireguard.md#全トラフィックを-vpn-経由にする場合対象外)
- **autoconnect は無効** — 拠点の LAN 内で自動的に張られると、ヘアピンと経路の奪い合いになる（→ [注意点](../extra/wireguard.md#almalinux-10-の-pc-からつなぐときの注意点)）
  - 外出先で手で `up` する
  - 常に外にある端末なら、`sudo nmcli connection modify wg0 connection.autoconnect yes` に戻してもよい
- **firewalld は触らない** — PC 側で開けるものは無い（外向きの UDP は既定で通る）
  - `connection.zone` を設定しないので、`wg0` は既定ゾーン `public` に入る（実測。`connection.zone` は `--` のまま）
  - 拠点側からトンネル越しに PC へ入れるのは、`public` で許可済みのもの（`ssh` など）だけ
- **`nmcli` の変更系は `sudo` で統一**
  - polkit の既定（`/usr/share/polkit-1/actions/org.freedesktop.NetworkManager.policy`）では、`settings.modify.system` / `network-control` が `allow_active=yes`
  - ローカルのコンソールなら `sudo` 無しで通るが、SSH 越し（`allow_any=auth_admin_keep`）では認証エージェントが要る
  - どちらでも同じ結果にするため、`sudo` を付ける
- **秘密鍵の置き場所は NetworkManager のプロファイルだけ** — `/etc/NetworkManager/system-connections/wg0.nmconnection`（root の 0600）
  - 取り出すときは `sudo nmcli -s -g wireguard.private-key connection show wg0`
  - バックアップは取らず、失ったら「鍵を作る」の手順 3 からやり直す（ホスト側は「WG ホストに登録する」の手順 2 の共通の削除手順で反映した後、同じ項の手順 3 で `client add --pubkey`）
  - WG ホストの[バックアップ](../wireguard.md#バックアップと復旧os-の再インストール)に、クライアントの鍵は含まれない

Windows 11 で WireGuard を入れる経路を比べた（2026-10-03 時点。どれも中身は公式の MSI）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `WireGuard.WireGuard`** | 1.1.1（2026-09-20）。公式の `download.wireguard.com` の MSI を、winget が sha256 を確かめて黙って入れる。`DO_NOT_LAUNCH=1` を付けるので、入れた後に何も起動しない。PC 全体（`C:\Program Files\WireGuard`）に入る | **採用**（ほかの Windows の手順書と同じく winget） |
| 公式の `wireguard-installer.exe` | 構成に合う MSI を選び、署名を確かめて実行する（WireGuard の文書の「Enterprise Usage」）。公式のサイトが一般の利用者に案内する形 | 不採用（ブラウザと画面の操作になる。入るものは同じ） |
| scoop の `nonportable/wireguard-np` | 1.1.1（同じ MSI。sha256 も同じ）。管理者の権限で `msiexec /qn` を動かし、起動した `wireguard.exe` を止める | 不採用（[Windows 11 の初期設定](../windows-setup.md)の scoop は、管理者ではない窓で使う） |

#### Road Warrior: 完了時点の状態

AlmaLinux 10 の実機で、2026-09-22、「トンネルを確かめる」の手順 5 の後（元の Wi-Fi に戻した状態）。Windows 11 は流していないので、記録は無い。

| 項目 | 状態 |
|---|---|
| パッケージ | `wireguard-tools-1.0.20250521-1.el10`、`systemd-resolved-257-23.el10_2.2.alma.1`（`disabled` / `inactive` のまま） |
| プロファイル | `wg0  wireguard  --  --`（`AUTOCONNECT` が `no`、未接続）。`/etc/NetworkManager/system-connections/wg0.nmconnection` が `-rw------- root root`、SELinux ラベル `system_u:object_r:NetworkManager_etc_rw_t:s0` |
| `${WG_DIR}` | `wg0.pub` だけ（`wg0.key` と `wg0.conf` は削除済み） |
| firewalld | `public (default) interfaces: bridge0 <WIFI_IF>`（`wg0` は入っていない） |
| `/etc/resolv.conf` | 実施前と同じ |
| カーネルモジュール | `wireguard` がロード済み（参照カウント 0）。実施前は未ロード |
| `/etc/wireguard` | パッケージが作ったディレクトリが存在し、非 root では `Permission denied`（クライアント側には何も置いていない） |
| WG ホスト側 | 登録簿に `<CLIENT_NAME>` の 1 行が増え、`/etc/wireguard/wg0.conf` に `[Peer] # Client <CLIENT_NAME>` が入った。旧 conf は `wg0.conf.bak-<日時>` に退避されている |

#### Road Warrior: 代替: wg-quick で張る場合

- `DNS =` を書くなら `resolvconf` 経由で `systemd-resolved` が要る（→ [wireguard.md: `DNS =` を書く場合](../extra/wireguard.md#dns--を書く場合)）
- 起動時に張るなら `systemctl enable wg-quick@wg0`。ただし Wi-Fi より先に走り、`Endpoint` が名前なら解決に失敗しうる。拠点の LAN 内でも張られる
- NetworkManager からは `connected (externally)` として見え、同名の一時プロファイルが作られる（WG ホストで実測）
- wireguard.md の namespace ラボはクライアント側をこの経路で動かして疎通を確認している（→ [リモートクライアントの検証](#リモートクライアントの検証2026-09-19)）。本書の NetworkManager の手順は実機でも確認済み（[対象と検証環境](#road-warrior-対象と検証環境)）。この wg-quick の代替手順を PC の実機で通すことは未確認

#### Road Warrior: 操作上の注意と併記されていた記録

- **拠点の LAN 内では切る**: 「conf を取り込む」の手順 4 と「トンネルを確かめる」の全部は**どちらの拠点の LAN の外でも**行い、import 直後に自動で張られるので（実測）すぐ切る

#### Road Warrior: 操作上の注意と併記されていた記録

  - それに加えて、NetworkManager が入れる拠点 LAN の経路（**metric 50**。実測）が Wi-Fi の直結経路（metric 600）に勝ち、LAN 宛ての通信がすべてトンネルに入る

#### Road Warrior: 操作上の注意と併記されていた記録

- **MTU**: `wireguard.mtu 0` のときカーネル既定の 1420（実測）。PPPoE やモバイル回線で大きい通信だけ止まるなら `sudo nmcli connection modify wg0 wireguard.mtu 1380` して down / up（→ [wireguard.md: MTU](../extra/wireguard.md#mtu)）

#### Road Warrior: 操作上の注意と併記されていた記録

- **サスペンド復帰・Wi-Fi の切り替え**: **2026-09-22 の実機ではどちらも試していない**（セッションを落とさずに確認する手順が無かった）

#### Road Warrior: 操作上の注意と併記されていた記録

  - **ローカルのコンソールにログイン中のユーザーは、`sudo` 無しでも読める**（実測。polkit の既定 `allow_active=yes`）

#### Road Warrior: 注意点 / 手順 0: 本文中の記録

  - 2026-09-22 の実機は `DNS =` 無しの構成で、`ipv4.dns` は `--`、接続中も `/etc/resolv.conf` は変わらなかった

#### Road Warrior: 注意点 / 手順 0: 本文中の記録

  - 実測の内容: 非 root で `nmcli -s -g wireguard.private-key connection show wg0 | wc -c` が 45 を返し、その値のハッシュは「鍵を作る」の手順 3 で作った `wg0.key` と一致した（アクティブな Wayland セッション、`wheel` 所属のユーザー）

#### Road Warrior: 付録: 実機での検証記録

2026-09-22、AlmaLinux 10.2 x86_64 のノート PC から拠点 B の WG ホスト（AlmaLinux 10.2 aarch64）へ、実施手順の全部（4 項）を本実行した。鍵・グローバル IP・ホスト名・クライアント名はプレースホルダに置き換えてある。

実施時の位置関係が手順書の書きぶりと違う点を先に書く:

- PC は**拠点 A の LAN**にいた。拠点 B の WG ホストへは拠点間トンネル越しに ssh で届く状態だった
- クライアント conf の `AllowedIPs` には**両拠点の LAN** が入るので、拠点 A の LAN にいるままトンネルを張ると自分の LAN 経路を奪う。そこで、**「conf を取り込む」の手順 4 の前に**スマートフォンのテザリング回線へ移した（検証時の手順書は「トンネルを張る手順（今の「トンネルを確かめる」の手順 1）以降は LAN の外で」としていたが、import 直後に自動で張られるので 1 手順早く移す方が安全。今の手順書はこれに合わせて「conf を取り込む」の手順 4 から LAN の外にしている）
- 拠点 B がクライアントを受ける構成（`WG_B_CLIENT_NET` を設定、`WG_A_CLIENT_NET` は空）なので、「鍵を作る」の手順 1 の変数には `WG_B_TUN_IP` / `WG_B_LAN_IP` / `ROUTER_B_LAN_IP` / `WG_A_LAN_IP` を入れ、「WG ホストに登録する」の手順 1 の `SITE` は `B` にした

##### Road Warrior: 手順書から変えて実行した点

| 変えた点 | 理由 |
|---|---|
| 「WG ホストに登録する」の手順 1〜3 の WG ホスト側のコマンドを、PC から ssh 越しに実行した | 手順書は WG ホストで直接実行する前提。コマンドと結果は同じ |
| 「conf を取り込む」の手順 1 の `vi` への貼り付けの代わりに、`client show` の出力を ssh のリダイレクトで `${WG_DIR}/wg0.conf` に直接書き出した（`umask 077` 付き） | 鍵も conf も端末に出さずに済む。`client show` の出力に秘密は無いので安全性は変わらない |
| `apply` を `systemd-run` で切り離して実行した | 次節 |

##### Road Warrior: 落とし穴: `apply` は作業中の ssh 経路そのものを切る

`wg-vpn.sh` の `apply` は最後に必ず `systemctl restart wg-quick@wg0` する（reload では経路が変わらないため）。**トンネル越しに WG ホストへ ssh して作業していると、その restart が自分のセッションの足元を切る**。切り離して実行した:

```
sudo systemd-run --unit=wg-apply-rw -p Type=oneshot \
  /bin/bash <REPO>/scripts/wireguard/wg-vpn.sh -e <ENV_FILE> apply B
```

- **`/bin/bash` を挟むのが必要**。スクリプトのパスを直接 `systemd-run` に渡すと `Failed at step EXEC spawning …: Permission denied`（`status=203/EXEC`）で失敗する。ホームディレクトリが `0700` で systemd が実行ファイルを解決できないため。SELinux の AVC は出ない（`ausearch -m AVC -ts recent` が `<no matches>`）ので、ラベルの問題と誤診しないこと
- 結果は `journalctl -u wg-apply-rw` で読む。終了状態は `systemctl show wg-apply-rw -p Result -p ExecMainStatus`
- 実測では restart 後、ssh は**1 回目の再接続で復帰**し、拠点間トンネルのハンドシェイクも 23 秒以内に再確立した。とはいえ切れたまま戻らない場合に備えて、LAN 側の ssh やコンソールなど別の経路を用意しておく

##### Road Warrior: 手順ごとの実測

**「鍵を作る」の手順 2**: `wireguard-tools-1.0.20250521-1.el10` の 1 パッケージに対し、依存で `systemd-resolved-257-23.el10_2.2.alma.1` が入る（2 パッケージ、437 k）。導入後も `systemctl is-enabled systemd-resolved` は `disabled`、`is-active` は `inactive` のまま。`modinfo -n wireguard` はカーネル同梱モジュールのパスを返す。

**「鍵を作る」の手順 3**: `wg0.key` / `wg0.pub` とも `-rw-------` の 45 バイト。

**「WG ホストに登録する」の手順 1〜3**: `client add` は `==> クライアント <CLIENT_NAME> を登録しました（拠点 B、<CLIENT_TUN_IP>）` と `==> クライアント用 conf を書き込みました: /etc/wireguard/clients/<CLIENT_NAME>.conf` を出し、`conf の PrivateKey は <CLIENT_PRIVATE_KEY> のままです` と続ける。トンネル IP は登録簿の空きから最小のものが自動で割り当てられた。

- `--dry-run apply B` で予定を見ると、変わるのは `/etc/wireguard/wg0.conf` に `[Peer] # Client <CLIENT_NAME>` が 1 つ増えるところだけ。firewalld は `--reload` のみ（port / interface / forward は既に入っている）。LAN 側ゾーンは WG ホストの LAN 側 NIC から `public` を自動検出
- `apply B` は既存の conf を `wg0.conf.bak-<日時>` に退避してから書き直し、`wg-quick@wg0` を再起動する。実行後の `wg show` で peer が 1 つ増えた
- **restart の副作用**: 既存クライアントの `LAST_HANDSHAKE` が `なし` に戻る（peer を作り直すため、接続が無ければ再度つながるまで表示されない）
- **登録簿の列ずれ**: `client add` は `printf '%-12s'` で書くので、13 文字以上の名前だと `clients.list` の列が揃わない。空白区切りなので `awk` での読み取りには影響しない

**「conf を取り込む」の手順 1〜2**: `grep -c '^PrivateKey = [A-Za-z0-9+/]\{43\}=$'` が `1`。他の行は `client show` の出力のまま。

**「conf を取り込む」の手順 4**: `import` は `Connection 'wg0' (<UUID>) successfully added.` の 1 行だけを出す。

- **その直後**に `connection show` を見ると `wg0  wireguard  wg0  activating  yes`、`device status` は `connecting (checking IP connectivity)`。`ip -4 route show` には既に `AllowedIPs` の 3 経路が `proto static scope link metric 50` で入っている（＝**未確認事項 2 と 3 はここで同時に確定した**）
- `connection.autoconnect no` の後は `activated  no`。`down` すると 3 経路とも消える
- `connection show wg0` の値: `connection.id` / `connection.interface-name` とも `wg0`、`connection.zone` は `--`、`ipv4.method` は `manual`、`ipv4.addresses` は `<CLIENT_TUN_IP>/32`、`ipv4.dns` は `--`、`ipv4.route-metric` は `-1`、`ipv6.method` は `disabled`、`wireguard.peer-routes` は `yes`、`wireguard.mtu` は `0`、`wireguard.private-key` は `<hidden>`
- `wireguard.peers` は 1 行に `<SITE_B_PUBKEY> allowed-ips=<SITE_A_LAN>;<SITE_B_LAN>;<WG_TUNNEL_NET> endpoint=<SITE_B_PUBLIC>:<WG_PORT> persistent-keepalive=25` まで出る
- keyfile は `-rw------- root root` の 477 バイト、SELinux ラベルは `system_u:object_r:NetworkManager_etc_rw_t:s0`

**「トンネルを確かめる」の手順 1**: `up` の直後、`device status` は `wg0  wireguard  connected  wg0`、MTU は `1420`。

- `IP4.ROUTE[1..3]` はいずれも `mt = 50`。経路全体で見ると、テザリングの `default` と直結経路が metric 600 なので、**拠点 LAN 宛てだけがトンネルに入る**
- `wg show wg0` の `listening port` はランダム（NetworkManager は `wireguard.listen-port 0` のまま）。この時点では `latest handshake` の行がまだ無く、`transfer: 0 B received, 148 B sent`。**最初のハンドシェイクは「トンネルを確かめる」の手順 2 の通信で起きる**
- `firewall-cmd --get-active-zones` の `public (default)` の `interfaces` に `wg0` が加わる
- `/etc/resolv.conf` は「鍵を作る」の手順 2 の前と同じ。`ausearch -m AVC -ts recent` は `<no matches>`
- 細かい点: `nmcli -f GENERAL.STATE,IP4.ADDRESS,IP4.ROUTE,IP4.DNS connection show wg0` では `IP4.ADDRESS` の行が出ない。`nmcli -f IP4 connection show wg0` なら `IP4.ADDRESS[1]: <CLIENT_TUN_IP>/32` が出る

**「トンネルを確かめる」の手順 2〜3**: 4 段階すべて `0% packet loss`。

| 宛先 | 結果（rtt avg） |
|---|---|
| `<WG_HOST_TUN_IP>`（接続先拠点の WG ホストの `wg0`） | 26 ms |
| `<WG_HOST_LAN_IP>`（同じホストの LAN 側） | 23 ms |
| `<ROUTER_LAN_IP>`（接続先拠点のルーター） | 23 ms |
| `<PEER_WG_LAN_IP>`（**相手拠点**の WG ホスト） | 46 ms |

- `tracepath -n <PEER_WG_LAN_IP>` は `pmtu 1420` で `1: <WG_HOST_TUN_IP>` → `2: <PEER_WG_LAN_IP>`
- WG ホスト側の `client list` で `LAST_HANDSHAKE` が `35 秒前`、逆方向の `ping <CLIENT_TUN_IP>`（拠点 → PC）も `0% packet loss`。PC 側の firewalld は既定の `public` のままで ping に応答した
- **トンネル越しの ssh** で WG ホストに入れた（`SSH_CONNECTION` の送信元が `<CLIENT_TUN_IP>`）。新レイアウト（`wg0` を LAN 側ゾーンに入れる）では、ホスト自身宛ての ssh も LAN と同じ扱いになるため（→ [wireguard.md](../extra/wireguard.md#トンネル越しに-wg-ホスト自身の-ssh-や-cockpit-へ入る場合)）
- 追加で確認したこと: **相手拠点のルーター**（`<ROUTER_A_LAN_IP>`、WG ホストではない LAN 上の機器）への ping も通り、接続先拠点の `445/tcp`（Samba）へも TCP が張れた。クライアント → 接続先拠点 → 拠点間トンネル → 相手拠点 LAN の折り返しが実際に動いている

**「トンネルを確かめる」の手順 4**: `down` の直後に `ip link show dev wg0` が `Device "wg0" does not exist.`（終了コード 1）。経路 3 本と firewalld の `wg0` も消える。プロファイルは `wg0  wireguard  --  --` で残る。

**「トンネルを確かめる」の手順 5**: `${WG_DIR}` に `wg0.pub` だけが残る。

##### Road Warrior: 確認できたこと（この文書を書いた時点の「未確認事項」1〜9）

| # | 項目 | 実測 |
|---|---|---|
| 1 | `import` の接続名・インターフェース名がファイル名になる | そのとおり（`wg0.conf` → `connection.id` / `connection.interface-name` とも `wg0`） |
| 2 | `import` 直後に autoconnect でトンネルが張られる | 張られる（`activating` → `activated`。経路も即座に入る） |
| 3 | `peer-routes` が入れる 3 経路の metric | **50**（想定どおり。`ipv4.route-metric` は `-1` のままなので WireGuard デバイスの既定値） |
| 4 | `import` で `ipv6.method` が `disabled` になる | そのとおり |
| 5 | `wireguard.peers` に endpoint / allowed-ips まで出るか | 出る（`persistent-keepalive` も） |
| 6 | `wireguard.mtu 0` のとき MTU が 1420 | そのとおり |
| 7 | `wg0` が firewalld の既定ゾーン `public` に入る | そのとおり（`connection.zone` は `--` のまま） |
| 8 | `down` でリンク `wg0` が消える | 消える |
| 9 | `DNS =` が無いので resolv.conf が変わらない | 変わらない（`ipv4.dns` も `--`） |

加えて、[注意点](../extra/wireguard.md#almalinux-10-の-pc-からつなぐときの注意点)に書いていた「非 root で秘密鍵が読める」も確認した。アクティブなローカルセッション（Wayland、`wheel` 所属）の非 root ユーザーで `nmcli -s -g wireguard.private-key connection show wg0 | wc -c` が `45` を返し、その値のハッシュは「鍵を作る」の手順 3 で作った `wg0.key` と一致した。

##### Road Warrior: 残っている未確認事項

1. `Endpoint` が DDNS 名のときの再解決（今回の `site.env` は生のグローバル IP）
1. サスペンド復帰後・Wi-Fi 切り替え後にトンネルが戻るか（作業セッションを落とさずに確認する手立てが無く、実施していない）
1. GNOME の設定画面・クイック設定に出るか（`connection.type` は `vpn` ではなく `wireguard`）
1. `DNS =` がある構成での resolv.conf の扱い（今回は `DNS =` 無し）
1. 有効なインターフェース名 + `.conf` でないファイル名を `import` が拒否するか
1. **拠点の LAN の中からトンネルを張ったときの挙動**（metric 50 の経路が LAN の直結経路を奪うことが確定したので、意図的に試していない）
1. [代替: wg-quick](../reference/wireguard.md#代替-wg-quick-で張る場合) と [代替: nmcli connection add](../reference/wireguard.md#代替-nmcli-connection-add-で組む場合rhel-のドキュメントの方式) は未検証のまま
1. クライアント同士（`wg0 → wg0` の折り返し）の疎通。今回はクライアントが 1 台しか接続していない

##### Road Warrior: 記録用ブロック（再検証するとき、「鍵を作る」の手順 2 の前に PC で）

```bash
head -2 /etc/os-release; uname -rm
rpm -q NetworkManager wireguard-tools systemd-resolved firewalld
nmcli general status; nmcli device status; nmcli -f NAME,TYPE,DEVICE,STATE,AUTOCONNECT connection show
ip -4 route show
cat /etc/resolv.conf
sudo firewall-cmd --get-default-zone; sudo firewall-cmd --get-active-zones
getenforce; ls /etc/wireguard; lsmod | grep -c wireguard
```

---

#### Road Warrior: 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物とソースと資料を読んだ記録。

##### Road Warrior: リリースのファイル

- WireGuard for Windows の最新は 1.1.1（タグ `v1.1.1` は 2026-09-20 の `version: bump to 1.1.1`。`git ls-remote --tags` で、その後のタグは無い）
- `https://download.wireguard.com/windows-client/` には `wireguard-installer.exe` と `wireguard-{amd64,arm64,x86}-1.1.1.msi` だけがある。amd64 の MSI の `Last-Modified` は 2026-09-20 14:24:05 GMT

`latest.sig`（窓の更新の確認が読む、署名付きの一覧。2 行目の署名は省いた）:

```
untrusted comment: verify with wireguard-windows-release.pub
<署名>
f64b88dea419f57cd8068c3a2284aedd2f33fb5656985dbdaf4bb6001168ac8b  wireguard-amd64-1.1.1.msi
1390d251ff4630f7cd32e06aa138105c6ededfbdac043efd11c7168b3876af2c  wireguard-arm64-1.1.1.msi
b76929b5b6bd654665e606ebfcd1430455cf36d56b2f825ff6a00afd7a69c1b2  wireguard-x86-1.1.1.msi
```

- 署名は、ソースの `updater/constants.go` の公開鍵（`RWRNqGKtBXftKTKPpBPGDMe8jHLnFQ0EdRy8Wg0apV6vTDFLAODD83G4`）の Ed25519 で確かめられた（`updater/signify.go` と同じ読み方を、Python の `cryptography` で）
- 取ってきた amd64 の MSI（3,293,184 バイト）の BLAKE2b-256（`b2sum -l 256`）は `f64b88de…1168ac8b` で一覧と一致し、sha256 は `7bfed60ad61b785c914b38b61555a975488e1d3ec472dbfb2fcdf498fca75242` で winget の定義と一致した

##### Road Warrior: MSI の署名と中身

`osslsigncode verify` の要点:

```
Subject: /serialNumber=4227913/jurisdictionC=US/jurisdictionST=Ohio/businessCategory=Private Organization/C=US/ST=Colorado/O=WireGuard LLC/CN=WireGuard LLC
Issuer : /C=GB/O=Sectigo Limited/CN=Sectigo Public Code Signing CA EV R36
Timestamp time: Sep 20 14:15:55 2026 GMT
```

- タイムスタンプは DigiCert（`DigiCert Trusted G4 TimeStamping RSA4096 SHA256 2025 CA1`）で、その検証は通った。署名者の証明書の連なりは、このコンテナに Sectigo の上のルート（`AAA Certificate Services`）が無いので、最後まではたどれなかった
- `msiextract` で取り出した中身は `WireGuard/wireguard.exe`（9,354,360 バイト）と `WireGuard/wg.exe`（140,408 バイト）の 2 つ。どちらも同じ署名者の署名とタイムスタンプ（2026-09-20 14:15:24 GMT）付き
- PE のヘッダーのサブシステムは、`wireguard.exe` が 2（GUI）、`wg.exe` が 3（コンソール）。どちらも x64
- 版の情報は、`wireguard.exe` が `1.1.1`（中に WireGuardNT のドライバー 1.1 を持つ）、`wg.exe` が `1.0.20260223`。`wg --version` の書式は `wireguard-tools v%s - https://git.zx2c4.com/wireguard-tools/`

##### Road Warrior: winget の定義（`WireGuard.WireGuard` 1.1.1）

`manifests/w/WireGuard/WireGuard/1.1.1/WireGuard.WireGuard.installer.yaml`（2026-10-03 の winget-pkgs）の要点:

```
PackageIdentifier: WireGuard.WireGuard
PackageVersion: 1.1.1
InstallerType: wix
Scope: machine
InstallerSwitches:
  Custom: DO_NOT_LAUNCH=1
UpgradeBehavior: install
ReleaseDate: 2026-09-20
Installers:
- Architecture: x64
  InstallerUrl: https://download.wireguard.com/windows-client/wireguard-amd64-1.1.1.msi
  InstallerSha256: 7BFED60AD61B785C914B38B61555A975488E1D3EC472DBFB2FCDF498FCA75242
  ProductCode: '{5D46ED04-DEA2-47D0-A957-F82C3EF577FE}'
```

- x86 と arm64 の MSI も同じ形で載っている（sha256 は `latest.sig` の一覧の MSI と同じもの）
- 同じディレクトリには、1.1.1 のほかに 1.1・1.0.1・1.0・0.6.1・0.5.3 などの版がある
- scoop の `nonportable/wireguard-np` 1.1.1 は、同じ 3 つの MSI（sha256 も同じ）を使い、`installer` は管理者でなければ止まり、`msiexec /i … /qn /norestart` の後に起動した `wireguard` のプロセスを止める

##### Road Warrior: ソース（`v1.1.1` のタグ）と文書

- `installer/wireguard.wxs`: `InstallScope="perMachine"`。入る先は `ProgramFiles64Folder`（x86 版は `ProgramFilesFolder`）の `WireGuard`。`wg.exe` の部品が、PC 全体の `PATH` の末尾に入る先を足す（`Permanent="no"`）。入れ終えたときの `LaunchApplication` は `NOT DO_NOT_LAUNCH` のときだけ動く。`MajorUpgrade` は `Schedule="afterInstallExecute"`
- `installer/customactions.c`: `EvaluateWireGuardServices` が、`WireGuardManager` と `WireGuardTunnel$…` のサービスを、更新では止めて（動いていたものは）起動し直し、アンインストールでは止めて消すように登録する。アンインストールのときだけ、`RemoveConfigFolder` が `Data` と `HKLM\Software\WireGuard` を消す
- `main.go`: 引数無しは、マネージャーが動いていれば窓を出し、無ければ `/installmanagerservice` を管理者で動かす。コマンドラインは `/installmanagerservice`・`/installtunnelservice CONFIG_PATH`・`/uninstallmanagerservice`・`/uninstalltunnelservice TUNNEL_NAME`・`/managerservice`・`/tunnelservice CONFIG_PATH`・`/ui …`・`/dumplog [/tail]`・`/update`・`/removedriver`。ログは標準エラー（無ければ標準出力）に書き、どちらも無いとエラーをメッセージ ボックスで出す。窓は Administrators の一員にしか出さない（`checkForAdminGroup`）
- `manager/install.go`: マネージャーとトンネルのサービスは、どちらも `StartAutomatic`。トンネルのサービスの名前は `WireGuardTunnel$<名前>`、依存は `Nsi` と `TcpIp`
- `manager/ipc_server.go`: 窓の「有効化」は、重なるトンネルを止めてから `InstallTunnel(<設定の置き場所>\<名前>.conf.dpapi)`、「無効化」は `UninstallTunnel(<名前>)`
- `conf/path_windows.go`: `Data` のアクセス権は `O:SYG:SYD:PAI(A;OICI;FA;;;SY)(A;OICI;FA;;;BA)`（SYSTEM と Administrators のフル コントロール。上から受け継がない）
- `manager/service.go`・`conf/migration_windows.go`: マネージャーは設定の置き場所が変わるたびに `MigrateUnencryptedConfigs` を呼び、`.conf` を読めたら `.conf.dpapi` に書いて元を消す。読めなければ `Unable to ingest and encrypt` をログに出して残す
- `conf/filewriter_windows.go`・`conf/dpapi/dpapi_windows.go`: `.conf.dpapi` は `CryptProtectData`（フラグは `CRYPTPROTECT_UI_FORBIDDEN` だけ）で暗号化し、アクセス権は `O:SYG:SYD:PAI(A;;FA;;;SY)(A;;SD;;;BA)`（SYSTEM のフル コントロールと、Administrators の削除だけ）
- `conf/parser.go`・`conf/name.go`: 読み込みは LF で行を分け、前後の空白を落とし、`#` から後ろはコメント。読めなければ UTF-16 などとして読み直す。トンネルの名前は `^[a-zA-Z0-9_=+.-]{1,32}$` で、`CON` などの予約語は使えない
- `tunnel/addressconfig.go`: `AllowedIPs` の経路はメトリック 0。`/0` があるときだけ、インターフェースのメトリックを自動から 0 に変える。キルスイッチ（ファイアウォールの制限）は、peer が 1 つで `/0` を持つときだけ
- `tunnel/service.go`: 張るたびに `ResolveEndpoints` で `Endpoint` の名前を引き、アダプターをトンネルの名前で作る
- `ui/editdialog.go`: 「トンネルを通らないトラフィックのブロック（キルスイッチ）」の項目は、peer が 1 つで `/0` を含むときだけ出る。窓の日本語の表示は `locales/ja/messages.gotext.json` から（「有効化」「無効化」「トンネルをファイルからインポート…」「選択したトンネルの削除」「すべてのトンネルをzipにエクスポート」「今すぐ更新」「更新が利用できます！」）
- `updater/`・`manager/updatestate.go`: `latest.sig` を Ed25519 で確かめ、MSI の BLAKE2b-256 を比べてから入れる。マネージャーは 1 時間ごとに確かめる（PC の起動で始まったときは、最初に 2〜5 分待つ）
- `docs/enterprise.md`・`docs/netquirk.md`: 本文の補足に引いたとおり（`DO_NOT_LAUNCH`、`.conf.dpapi`、設定の置き場所の見張り、`/update`・`/dumplog`、経路と MTU、キルスイッチ、決まった GUID）

##### Road Warrior: そのほかのソース

- wireguard-tools の `src/pubkey.c` と `src/ctype.h`（2026-10-03 の master）: `wg pubkey` は鍵の 44 文字を読んだ後、`char_is_space` に当たる文字（タブ・LF・VT・FF・CR・空白）と NUL を読み飛ばし、ほかの文字があれば `Trailing characters found after key` で止まる
- PowerShell の `src/System.Management.Automation/engine/NativeCommandProcessor.cs`（2026-10-03 の master）: パイプラインの最後にある GUI のプログラムは終わるのを待たず、後ろにパイプでつないだときは待つ。Windows PowerShell 5.1 も同じ作りのはず（確かめていない）

---

#### Road Warrior: 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-03）

Linux（クラウドのコンテナ）の PowerShell 7.6.6 と PSScriptAnalyzer 1.25.0 で確かめた（[hackgen.md](windows-setup.md#統合前の記録-hackgen-console-nf-の-windows-11もとは-hackgenmd) の付録と同じ環境）。この付録の手順は、どれも[Windows 11 で使う](../wireguard.md#windows-11-で使う)のもの。

**構文と Windows PowerShell 5.1 との互換**:

- Windows 11 の 3 節の `powershell` のブロック 18 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0。ほかの規則の指摘は、「Windows 11 で WireGuard と鍵を用意する」の手順 2 の 4 つの変数をそのブロックの中では使っていないことへの 4 つだけ（「Windows 11 でトンネルを確かめる」の手順 3 で使う）

**模擬の実行**（パスの `\` を `/` に替え、`$env:ProgramFiles`・`$env:USERPROFILE` を一時的なディレクトリにして流した。`wg.exe` は Linux の `wg`〔wireguard-tools 1.0.20210914〕へのリンク、`icacls.exe` は引数を記録するだけの偽物）:

- 「Windows 11 で WireGuard と鍵を用意する」の手順 6: `wg0.key` と `wg0.pub` が 45 バイトで書かれ、`wg pubkey < wg0.key` が `wg0.pub` と一致した。`icacls.exe` には `<置き場所> /inheritance:r /grant *S-1-5-32-544:(OI)(CI)F /grant *S-1-5-18:(OI)(CI)F` が渡った。2 回目は `中断: wg0.key が既にある…` で止まった
- Linux の `wg pubkey` は、`<鍵>\r\n` を渡しても `<鍵>\n` と同じ公開鍵を出した（`<鍵>\r\nx` は `Trailing characters found after key`）
- 「Windows 11 で WG ホストに登録して取り込む」の手順 3: `Get-Clipboard` を、決めた文字列を返す偽物にした
  - `client show` の形（CR LF、`PrivateKey` の行の末尾に空白、先頭に空行）から、`1` と残りの行が出て、`wg0.conf` の `PrivateKey` が `wg0.key` の鍵になり、ほかの行は変わらなかった（CR LF の 11 行、ASCII）
  - 先頭にプロンプトの行があるもの・`PrivateKey` の行が 2 つあるもの・ASCII でない文字を含むもの・空のものは、それぞれの `中断:` で止まり、`wg0.conf` を作らなかった
- 「Windows 11 で WG ホストに登録して取り込む」の手順 3 で書いた `wg0.conf` を、WireGuard for Windows 1.1.1 の `conf/parser.go`・`config.go`・`name.go` を Linux でビルドできるように写したもの（Windows だけの部分を外した）で読んだ
  - `Address`・`AllowedIPs` の 3 つ・`Endpoint`・`PersistentKeepalive = 25` が読めた
  - 先頭に UTF-8 の BOM を付けると `Line must occur in a section: "﻿[Interface]"` で読めず、UTF-16 LE（BOM 付き）にすると読めた
  - `PrivateKey = <CLIENT_PRIVATE_KEY>` のままだと `Invalid key` で読めなかった。トンネルの名前 `win laptop` と `CON` は `Tunnel name is not valid`
- 「Windows 11 で WG ホストに登録して取り込む」の手順 4: `Get-Service` を偽物にし、マネージャーの代わりに、写された `.conf` を 2 秒後に（上の読み込みで読めたら）`.conf.dpapi` に変えて元を消すスクリプトを動かした
  - `wg0.conf.dpapi` の 1 行が出た
  - もう 1 度貼ると `中断: wg0 というトンネルが既にある`、マネージャーが `Stopped` なら `中断: WireGuard のマネージャーが動いていない…` で止まった
  - 読めない conf（`PrivateKey` がプレースホルダのまま）では、30 秒待ってから、`wg0.conf` が残った一覧を出した
- 「Windows 11 でトンネルを確かめる」の手順 2・5: `wireguard.exe` を、引数を記録して印のファイルを作る・消す偽物にし、`Get-Service` と `Get-Net*`・`Get-DnsClientServerAddress` を偽物にした
  - 「Windows 11 でトンネルを確かめる」の手順 2 は表を順に出した。印が残ったままもう 1 度貼ると、偽物が標準エラーに書いた `Error: Tunnel already installed and running` が文字で出た
  - 「Windows 11 でトンネルを確かめる」の手順 5 は、偽物が 2 秒後に印を消すまで待ってから、何も出さずに終わった
- 「Windows 11 でトンネルを確かめる」の手順 3: 偽物の `ping.exe`（日本語の Windows の出力を真似たもの）と `tracert.exe` で、4 つの宛先の最後の 3 行と、`tracert.exe -d -h 5 -w 2000 <PEER_WG_LAN_IP>` が出た。変数が空なら `手順 2 の変数が空のまま` で止まった
- 「Windows 11 でトンネルを確かめる」の手順 6 と[Windows 11 のロールバック](../extra/wireguard.md#windows-11-のロールバック)の手順 1
  - 「Windows 11 でトンネルを確かめる」の手順 6 の後は `wg0.pub` だけが残った
  - ロールバックの手順 1 は、トンネルの印があれば `/uninstalltunnelservice wg0` を渡し、`wg0.conf.dpapi` と置き場所を消して `False` を出した。置き場所にほかのファイル（`notes.txt`）があると、それを残して `True` を出した
- PowerShell 7 は、Linux ではパイプの改行が LF で、ネイティブのコマンドの `2>&1` の扱いも Windows PowerShell 5.1 と同じではない。winget・`Get-AuthenticodeSignature`・本物の `Get-Net*` と `wireguard.exe` を使うブロック（「Windows 11 で WireGuard と鍵を用意する」の手順 3〜5、「Windows 11 でトンネルを確かめる」の手順 2・5 の本当の動き、更新、ロールバックの手順 2）は流せていない

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. winget で入れた後に窓が開かないこと（`DO_NOT_LAUNCH=1`）と、引数無しの `wireguard.exe` でマネージャーが入って窓が開くこと
1. 設定の置き場所に写した `wg0.conf` が、`wg0.conf.dpapi` になって消えること
1. 張ったときの経路（メトリック 0 の 3 つ）・MTU（1420）・ネットワークの種類（パブリック）・DNS が変わらないこと、拠点との疎通、拠点からの ping が返らないこと
1. 張ったまま再起動すると、起動のときに張られること
1. 拠点の LAN の中で張ったときに LAN の通信を奪うこと（AlmaLinux 10 と同じく、意図して試すものではない）
1. winget での更新と窓の「今すぐ更新」、アンインストールで `Data` が消えること
1. サスペンド復帰・Wi-Fi の切り替え・`Endpoint` が DDNS 名のとき
1. arm64 の Windows

#### Road Warrior: 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を ISO から入れた x86_64 VM をクライアントにし、別の 2 VM で wireguard.md の WG ホストを構築した。SELinux Enforcing、NetworkManager 1.56.0、カーネル `6.12.0-211.61.1.el10_2.x86_64`。一般ユーザーの SSH PTY から現行ブロックを実行した。

- 「鍵を作る」の手順 1〜3 でツールと、0600 のクライアントの鍵ペアができた。WG ホストの「WG ホストに登録する」の手順 1・3 はこの公開鍵で通し、conf は公開鍵とプレースホルダだけの状態でクライアント VM へファイル転送した（「conf を取り込む」の手順 1 の vi の操作は行っていない）
- 初回のホストの apply は終了 141 で止まった。IP を調べるパイプの SIGPIPE を修正し、登録の無い状態から「WG ホストに登録する」の手順 3 を再実行すると、登録・apply・conf 表示まで通った（[原因と修正](#間欠的な終了-141-の原因と修正)）
- クライアントの「conf を取り込む」の手順 2 で秘密鍵の行だけが置き換わった。「conf を取り込む」の手順 4 の新規 import 直後は activated、autoconnect を no にして切断できた。日本語ロケールの表示は「アクティベート済み」「いいえ」
- 「トンネルを確かめる」の手順 1 の up で 3 経路（metric 50）・MTU 1420・ハンドシェイク・送受信・public の wg0 が確認できた。resolved は有効にしていない。末尾の `ausearch` は `<no matches>`（この場合の終了コードは 1）
- 接続先の wg0・両 WG ホストの LAN IP・両 LAN の namespace に ping が通り、namespace からクライアントへの逆方向も双方向 0% 損失。相手 LAN への tracepath は `10.99.0.1` → `10.99.0.2` → 相手 LAN の 3 ホップ、TCP の HTTP も 200
- LAN の namespace の試験用 veth は firewalld に明示している。WG ホストの設定を再適用すると firewalld が reload するため、試験の veth は permanent にも入れた。追加前は仮想ルーターへの ping だけが拒否され、追加後に通った
- 「トンネルを確かめる」の手順 4・5 の down と平文鍵/conf の削除、ロールバック 1 のプロファイル・公開鍵・作業ディレクトリの削除、ロールバック 2 の対話でのパッケージ削除が通った。wireguard-tools と、この試験で依存として入った resolved が消えた

Endpoint は隔離された仮想 LAN であり、テザリング回線、実ルーター、Wi-Fi 切り替え、サスペンド復帰の検証ではない。クライアント VM の再起動は今回行っていないので、autoconnect no の読み戻しを再起動時の実証とはしていない。Windows の節は今回の確認に含めていない。

#### Road Warrior: 付録: 新規 VM での現行手順の再検証（2026-10-06）

同日の先行検証に使った VM と分け、ISO 導入直後の AlmaLinux 10.2 Workstation から新しい x86_64 VM を用意して、`5da3478` の現行本文を再検証した。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active。一般ユーザーの SSH PTY にブラケットペースト無しで貼り、手順ごとに結果を確認した。

同じ新規 ISO 環境の 3 台目を PC にし、2 台の検証用 WG ホストとは別の帯から NetworkManager で接続した。PC で鍵を作る経路を選び、公開鍵をホストに登録・apply して発行されたテンプレートを SCP で PC へ写した。秘密鍵は VM 内で「conf を取り込む」の手順 2 により入れ、画面やログへ出していない。実ルーターやテザリングを使う「conf を取り込む」の手順 3 の検証ではない。

- 「conf を取り込む」の手順 4 の import 直後は activated、自動接続を no にして down した。「トンネルを確かめる」の手順 1 の up、同じ項の手順 2 の ping が成功した。アドレスは /32、ipv6 は disabled、MTU 1420、経路の metric 50、DNS 指定無し。NM の keyfile は root の 0600 で秘密は hidden だった
- A/B の両 LAN の端末役へ HTTP/TCP が 200、tracepath は A/B の WG ホストを通る。両拠点と双方の LAN の端末役から PC への ping も成功した
- A のトンネル IP を Samba の接続先として [samba-client.md](../samba-client.md) の手順 1〜5 を通し、SMB 3.1.1 で作成・読み戻し・削除・unmount が成功した。経路は wg0 だった。WireGuard 越しの fstab 自動マウントは行っていない
- ホストの登録削除は wireguard.md の 6 手順で未知 peer の公開鍵を照合して反映した。PC の「トンネルを確かめる」の手順 4・5 とロールバック 1 でリンク・平文の鍵/conf・NM プロファイル・作業ディレクトリが消えた。ロールバック 2 の対話 dnf で新規 wireguard-tools と追加依存の resolved だけが消えた

クライアント VM の OS 再起動、サスペンド、Wi-Fi 切り替え、DDNS、DNS 指定、GNOME の VPN 表示、Windows の節はこの再検証の対象外。自動接続 no の読み戻しを、再起動で張られないことの実測とはしていない。


#### Road Warrior: Windows 11 で使う / Windows 11 でトンネルを確かめる / 手順 2: 補足: 張ったときに WireGuard がすること

- `/installtunnelservice <.conf.dpapi のパス>` は、トンネルのサービス `WireGuardTunnel$wg0`（自動で起動する）を作って起動する。窓の「有効化」も、同じパスで同じことをする（ソースの `manager/ipc_server.go` の `Start` と `manager/install.go` の `InstallTunnel`）
- `wireguard.exe` は GUI のプログラムなので、PowerShell は、出力をパイプでつないだときだけ終わるのを待つ。`2>&1 | ForEach-Object { "$_" }` で待ち、失敗したときのエラー（`Error: …`）を文字で出す
- アダプターの名前はトンネルの名前（`wg0`）。経路は `AllowedIPs` のとおりに、ルートのメトリック 0 で入る（ソースの `tunnel/addressconfig.go`）。インターフェースのメトリックは自動のまま（`/0` があるときだけ 0 にする）
- MTU は、conf に `MTU =` が無いと、既定の経路のインターフェースの MTU から 80 を引いた値にする（WireGuard の文書の「Network Configuration Quirks」）
- `AllowedIPs` に `/0` が無いので、キルスイッチ（トンネルを通らない通信を止めるファイアウォールの規則）は掛からない。WireGuard のパケットを通す規則を 1 つ足すだけ（同じ文書）
- アダプターの GUID は設定から決まるので、ネットワークの種類（パブリック / プライベート）は、設定を変えない限り同じものが使われる（同じ文書）。識別されないネットワークは、Windows の既定ではパブリックになるはず（確かめていない）
- `Endpoint` に名前を書いたときは、張るたびに名前を引く（ソースの `tunnel/service.go`）
- `wg.exe show` は、`.conf.dpapi` のトンネルでは管理者の権限が要る（同じ「Enterprise Usage」）



#### Road Warrior: Windows 11 のロールバック / 手順 2: 補足: アンインストールで消えるもの

- MSI のアンインストールは、WireGuard のサービス（マネージャーと、すべてのトンネル）を止めて消し、アダプターを消し、`C:\Program Files\WireGuard\Data`（トンネルの設定・ログ）と `HKLM\Software\WireGuard` を消す（ソースの `installer/customactions.c` の `EvaluateWireGuardServices`・`RemoveAdapters`・`RemoveConfigFolder`）
- PC 全体の `PATH` に足した `C:\Program Files\WireGuard\` も外れる（MSI の定義の `Permanent="no"`）
- `C:\Program Files\WireGuard` そのものも消えるはず（確かめていない）

### Road Warrior: 参考資料から分離した記録

#### Road Warrior: 参考資料: 実施手順 / WG ホストに登録する / 手順 3: 補足: WG ホストでの登録

**出力例**（`client show` が表示する内容）

```
[Interface]
# Client <CLIENT_NAME> (site A)
Address = <CLIENT_TUN_IP>/32
PrivateKey = <CLIENT_PRIVATE_KEY>

[Peer]
# Site A
PublicKey = <SITE_A_PUBKEY>
Endpoint = <SITE_A_PUBLIC>:<WG_PORT>
AllowedIPs = <SITE_A_LAN>, <SITE_B_LAN>, <WG_TUNNEL_NET>
PersistentKeepalive = 25
```

- `client add` は同じ名前・同じ公開鍵・同じトンネル IP を拒否する（`wg-vpn.sh` の `cmd_client_add`）
- `--pubkey` で登録した conf の `PrivateKey` は、文字列 `<CLIENT_PRIVATE_KEY>` のまま書かれる（`client add` の末尾にもその旨が出る）
- `apply` は `wg0.conf` を作り直して `systemctl restart` するので、他のクライアントと拠点間トンネルが数秒切れる（`reload` では経路が入らない。→ [落とし穴 2](../extra/wireguard.md#落とし穴-2-reload-では経路が追加されない)）
- `apply` の末尾に出るルーターの設定（クライアント帯の静的経路）は、既に入っていれば変更不要
- トンネル IP は帯の中で最小の空きが割り当たる（`--ip` で指定できる）

#### Road Warrior: 参考資料: 代替: wg-quick で張る場合

NetworkManager を使わない場合（未検証）。

- 「鍵を作る」から「conf を取り込む」の手順 2 までは同じで、conf を `/etc/wireguard/wg0.conf` に置いて `wg-quick` で張る
- NetworkManager の `wg0` プロファイルが無いこと（同じ ifname で併用しない）

```bash
sudo install -m 600 -o root -g root "${WG_DIR:?「鍵を作る」の手順 1 の WG_DIR が空のまま}/wg0.conf" /etc/wireguard/wg0.conf &&
sudo restorecon /etc/wireguard/wg0.conf &&
sudo wg-quick up wg0                     # 切るのは sudo wg-quick down wg0
```

#### Road Warrior: 参考資料: 代替: nmcli connection add で組む場合（RHEL のドキュメントの方式）

conf を import せず、値を手で写す方式（未検証）。最初から `autoconnect no` にできるのが利点。

1. `nmcli connection add type wireguard con-name wg0 ifname wg0 autoconnect no`
1. `nmcli connection modify wg0 ipv4.method manual ipv4.addresses <CLIENT_TUN_IP>/32`
1. `wireguard.private-key`（秘密鍵）
1. `wireguard.peers '<SITE_A_PUBKEY> endpoint=<SITE_A_PUBLIC>:<WG_PORT> allowed-ips=<SITE_A_LAN>;<SITE_B_LAN>;<WG_TUNNEL_NET> persistent-keepalive=25'`（`allowed-ips` は `;` 区切り。`nm-settings-nmcli(5)`）
1. `nmcli connection up wg0`

### Road Warrior: 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

#### Road Warrior: 補足 / 手順 9

  - NetworkManager では `ipv4.dns` になり、接続中は resolv.conf を NetworkManager が書き換えるので、`systemd-resolved` は要らない（未確認）

- **`Endpoint` が DDNS 名のとき**: NetworkManager が再解決するかは未確認（→ [wireguard.md](../extra/wireguard.md#endpoint-に-ddns-名を書く場合)）。本書の例は IP リテラル

  - `autoconnect no` のプロファイルをスリープ復帰後に NetworkManager が張り直すかは要確認（張り直さない可能性が高い。復帰後に `nmcli device status` を見る）

  - Wi-Fi が変わっても、WireGuard は送信元の変化に追従するはず（要確認）。`PersistentKeepalive = 25` が NAT の穴を維持する

- **GNOME の UI**: NetworkManager のプロファイルなので設定画面から up / down できる可能性があるが未確認

- **Windows 11 の注意点**（どれも Windows では確かめていない）

  - **`Endpoint` が DDNS 名のとき**: トンネルを張るたびに名前を引く（ソースの `tunnel/service.go`）。張っている間に相手の IP が変わったときは確かめていない

  - **サスペンド復帰・Wi-Fi の切り替え**: 確かめていない

---

#### Road Warrior: 付録: Windows 11 Pro の VM での新規導入の検証（2026-10-06）

[Windows 11 の初期設定](windows-setup.md#付録-windows-11-pro-の-vm-での導入検証2026-10-06)を検証中の専用 VM で、[Windows 11 で WireGuard と鍵を用意する](../wireguard.md#windows-11-で-wireguard-と鍵を用意する)の手順 3・4 のコードブロックを抜き出して、そのまま実行した。本体の新規導入だけを検証し、鍵やトンネルの設定は作っていない。

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro 26H2 / ビルド 26300.9457 / x64 |
| VM | VirtualBox 7.2.20。Rufus で作った媒体からクリーンインストールした専用 VM |
| PowerShell | Windows PowerShell 5.1.26100.9444 / Desktop / x64。ログオン中のユーザーの管理者権限（Session 1） |
| WinGet | 1.29.380。`WireGuard.WireGuard` を `--source winget` で新規導入 |
| 検証時の本文の SHA256 | `82D40978DB8C534EB0DE3785A8E315A61E1D1ECCEE74E0D65FA820DB376E64C7`（この追記より前） |
| 抜き出したブロックの manifest の SHA256 | `5AB55CD6E33EAA94C087E02D756F1DBE6F1E2FD84A1D5EA628232E10C57B2FF0` |

**確認したこと**（バッチ `20261006-111858Z-dd62f552`、完了 11:19:15 UTC）:

- 「Windows 11 で WireGuard と鍵を用意する」の手順 3 の一覧は `No installed package found matching input criteria.`、ユーザーの鍵の置き場所は `False`。WireGuard のサービスと設定ファイルの一覧には出力がなかった
- 未導入を確認する winget の終了コード `-1978335212` は、この手順で期待する結果だった
- 「Windows 11 で WireGuard と鍵を用意する」の手順 4 は公式の `wireguard-amd64-1.1.1.msi` を取り、インストーラーのハッシュ検証が成功し、`Successfully installed` が出た。続く一覧は `WireGuard.WireGuard 1.1.1`
- `C:\Program Files\WireGuard\wireguard.exe` と `wg.exe` は、どちらも Authenticode の署名が `Valid`、署名者が `CN=WireGuard LLC` だった
- `wg --version` は `wireguard-tools v1.0.20260223 - https://git.zx2c4.com/wireguard-tools/` だった
- 全ブロックの PowerShell のエラーは 0、最後の終了コードは 0

**確認していないこと**:

- 「Windows 11 で WireGuard と鍵を用意する」の手順 1 の端末を開く画面操作と、手で貼る操作。端末の起動は検証用の処理で代替した
- 「Windows 11 で WireGuard と鍵を用意する」の手順 2 の 4 つの実際の IP、WG ホストの接続設定、鍵の作成と登録。接続先の実設定は提供されていない
- 「Windows 11 で WireGuard と鍵を用意する」の手順 5 以降（「Windows 11 でトンネルを確かめる」まで）のマネージャーの画面、設定の取り込み、トンネルの起動、経路・MTU・DNS・ネットワークの種類、拠点との疎通と外部の SSH 接続
- トンネルを張ったままの再起動、更新とロールバック、サスペンド復帰、Wi-Fi の切り替え、DDNS、arm64 の Windows

---

#### Road Warrior: 付録: Windows 11 Pro の VM でのマネージャーのサービスと鍵生成の検証（2026-10-07）

前の新規導入と同じ専用 VM で、[Windows 11 で WireGuard と鍵を用意する](../wireguard.md#windows-11-で-wireguard-と鍵を用意する)の手順 6 のコードブロックを変更せず、管理者の Windows PowerShell 5.1 で実行した。「Windows 11 で WireGuard と鍵を用意する」の手順 5 のマネージャーの画面は操作せず、[公式の CLI](https://git.zx2c4.com/wireguard-windows/about/docs/enterprise.md) による一時的なサービスの作成・確認・削除で代替した。

| 項目 | 値 |
|---|---|
| 環境 | Windows 11 Pro の同じ専用 VM。ログオンユーザー `<WIN_USER>` の管理者権限 |
| PowerShell | Windows PowerShell 5.1.26100.9444 / Desktop。`USERPROFILE`・`HOME`・`CODEX_HOME` は変更していない |
| 実行時刻 | 2026-10-07 09:47:01〜09:47:25 UTC |
| 実行した manifest が記録する本文の SHA256 | `82D40978DB8C534EB0DE3785A8E315A61E1D1ECCEE74E0D65FA820DB376E64C7` |
| 実行した source manifest の SHA256 | `5AB55CD6E33EAA94C087E02D756F1DBE6F1E2FD84A1D5EA628232E10C57B2FF0` |
| 「Windows 11 で WireGuard と鍵を用意する」の手順 6 のコードの SHA256 | `7A80E2789044868A2424D623BD945F871E9CAA2005F8E97141C185453377C166` |

**確認したこと**（証跡 `remaining-wireguard-local-20261007-094630-d8f8efb9`）:

- `wireguard.exe` と `wg.exe` の Authenticode の署名は `Valid / WireGuard LLC` だった。実行前は WireGuard のサービス・プロセス・設定のディレクトリ・`wg-client` と既存の `wg0` がなく、スキップせず検証した
- `/installmanagerservice` の終了コードは 0。`WireGuardManager` は `Running`・`Auto` で、サービスのパスは `"C:\Program Files\WireGuard\wireguard.exe" /managerservice`、PID は 6948 だった。PID の実行ファイルも一致した
- 「Windows 11 で WireGuard と鍵を用意する」の手順 6 は終了コード 0。`wg0.key` と `wg0.pub` はともに 45 バイトの ASCII、末尾は LF のみで、鍵は Base64 の 32 バイト形式だった。秘密鍵を標準入力に渡したローカルの `wg pubkey` は終了コード 0、保存された公開鍵と一致した
- `wg-client` の ACL は継承を遮断し、Administrators（`S-1-5-32-544`）と SYSTEM（`S-1-5-18`）の FullControl の 2 件だけだった。両ファイルも同じ 2 件を継承し、所有者は Administrators だった
- source の出力は全ストリームを破棄し、証跡には鍵の値や秘密鍵のハッシュを載せていない。今回作成した `C:\Users\<WIN_USER>\wg-client` だけを削除し、不在を確認した
- `/uninstallmanagerservice` は終了コード 0。サービスの不在と WireGuard のプロセス 0 件を確認し、元の状態へ戻した。新しくできた `C:\Program Files\WireGuard\Data` は残し、設定の置き場所のファイルは 0 件だった
- 補助検証は `passed=true`。検証用の管理者タスクと結果のコピーの終了コードは 0 で、一時的な実行要求も元のハッシュへ復元された
- `guest-result.json` と `source-manifest-executed.json` は `.verification/evidence/remaining-wireguard-local-20261007-094630-d8f8efb9` に保存した

**確認していないこと**:

- 「Windows 11 で WireGuard と鍵を用意する」の手順 5 のマネージャーの起動・表示・操作と、Windows の端末へ手で貼る操作
- 既存の鍵がある場合の「Windows 11 で WireGuard と鍵を用意する」の手順 6 の分岐。今回の鍵生成は、置き場所が完全に存在しない場合だけで、既存の設定や鍵は使っていない
- 実際の IP・WG ホストの設定、公開鍵の登録、conf の作成・取り込み、トンネルの起動、拠点との疎通と外部の SSH 接続
- VPN 全体の動作、張ったままの再起動、更新・ロールバック、サスペンド復帰、Wi-Fi の切り替え、DDNS、arm64 の Windows

---

#### Road Warrior: 付録: Windows 11 Pro の VM での VPN の通し検証（2026-10-08）

上の付録と同じ Windows の VM（[windows-setup.md の検証記録の 2026-10-08 の付録](windows-setup.md#付録-pr-104-の未検証項目を同じ-vm-で確かめた記録2026-10-08)の環境）で、[Windows 11 で使う](../wireguard.md#windows-11-で使う)の 3 項の全部と更新・ロールバックを、2 拠点の WG ホストの検証環境に向けて通した。物理のルーター・NAT・DDNS・インターネット越しの接続は使っていない。

**検証環境**:

| 項目 | 値 |
|---|---|
| WG ホスト（拠点 A・B） | 同じホストの AlmaLinux 10.2 の VM 2 台（`alma10-pr100-client-20261007` を拠点 A、`alma10-pr100-pc-20261007` を拠点 B）。ホストオンリーのネットワークの 192.168.56.82・.81 を `SITE_A_PUBLIC`・`SITE_B_PUBLIC` にした |
| 拠点の LAN | それぞれの VM に veth の対を作り、片方を拠点の LAN 側（`lanA` 192.168.110.2/24・`lanB` 192.168.120.2/24）、もう片方を network namespace のルーター役（`routerA` 192.168.110.1・`routerB` 192.168.120.1、既定の経路は WG ホスト）にした。`lanA`・`lanB` は firewalld の public ゾーンに入れた（一時的な設定） |
| WG ホストの手順 | このリポジトリの 8a79aff を clone し、`site.env.example` から `site.env` を作って `SITE_A_PUBLIC`・`SITE_B_PUBLIC` だけを直し、[wireguard.md](../wireguard.md#実施手順) の `keygen` → 公開鍵を `site.env` に書く → `--dry-run apply` → `apply` を両拠点で行った（`wireguard-tools` 1.0.20250521 と `systemd-resolved` が入った）。`routerA` から `routerB` まで届いた（経路 MTU 1420、3 ホップ） |
| Windows の PC | 2 枚目の NIC（「イーサネット 3」、192.168.56.107）で拠点 A の WG ホストに届く。拠点の LAN（192.168.110.0/24・192.168.120.0/24）の外にいる形 |
| 変数 | 「Windows 11 で WireGuard と鍵を用意する」の手順 2 の本文の例の値（`10.99.0.1`・`192.168.110.2`・`192.168.110.1`・`192.168.120.2`）が、検証環境の値と同じだったので、そのまま貼った |

**確認したこと**（表の手順は、項に分ける前の Windows 11 で使うの通し番号。「Windows 11 で WireGuard と鍵を用意する」の手順 1〜6 が表の 1〜6、「Windows 11 で WG ホストに登録して取り込む」の手順 1〜4 が表の 7〜10、「Windows 11 でトンネルを確かめる」の手順 1〜6 が表の 11〜16）:

| 手順 | 結果 |
|---|---|
| 1 | スタートから管理者の Windows PowerShell（conhost）を開いた |
| 3 | WireGuard 1.1.1 が入っている状態（上の付録で入れたもの） |
| 4 | winget は新しい版なしの旨。署名は `Valid`・WireGuard LLC。`wg.exe --version` は `wireguard-tools v1.0.20260223` |
| 5 | WireGuard の窓（「トンネル」「ログ」のタブ）が開き、`WireGuardManager` は `Running`・`Automatic` |
| 6 | `%USERPROFILE%\wg-client` の ACL は SYSTEM と Administrators だけ。鍵ファイルは 45 バイト。鍵の値はこの記録に載せない |
| 7 | `Import-WgClientConf` を定義した（何も出ない） |
| 8 | 拠点 A の WG ホストで実施手順の「WG ホストに登録する」の手順 1・3（`client add A win-pr104 --pubkey …` → `apply A` → `client show win-pr104`）。トンネル IP は 10.99.1.1。表示した conf を Windows のクリップボードに置いた |
| 9 | `Import-WgClientConf` を手で打って Enter（検証ではホストからのキーで打った）。`1` と、`PrivateKey` 以外の行が `client show` のとおりに出た |
| 10 | `wg0.conf.dpapi`（540 バイト）の 1 行だけ。写した `wg0.conf` は消えた |
| 11 | この PC はもとから拠点の LAN の外（ホストオンリーのネットワーク）にいるので、つなぎ替えはしていない |
| 12 | `WireGuardTunnel$wg0  Running  Automatic`、`wg0` に `10.99.1.1`/`32`、`AllowedIPs` の経路 3 つ（`RouteMetric` 0）、`NlMtu` 1420、`NetworkCategory` は `Public`、`ServerAddresses` は `{}`、`latest handshake` は 7 秒前 |
| 13 | 4 つのあて先とも `0% の損失`。`tracert` は `10.99.0.1` → `192.168.120.2` |
| 14 | 拠点 A の WG ホストで実施手順の「トンネルを確かめる」の手順 3: `client list` の `win-pr104` の `LAST_HANDSHAKE` が 49 秒前。拠点 → PC の `ping` は 100% の損失（本文のとおり、Windows のファイアウォールが受けない） |
| 15 | トンネルのサービスとアダプター `wg0` が消えた |
| 16 | `wg0.pub` だけが残った |

- Windows 11 の更新: winget は `No available upgrade found.`、マネージャーは `Running` のまま
- Windows 11 のロールバックの手順 1: 最後に `False` だけが出た
- Windows 11 のロールバックの手順 2（WG ホストの手順 3 の後に行った）: `Found WireGuard [WireGuard.WireGuard]`・`Starting package uninstall...`・`Successfully uninstalled`、`winget list` は `No installed package found matching input criteria.`、サービスは何も出ず、`False`。WireGuard の窓と `wireguard.exe` のプロセスも消えた
- Windows 11 のロールバックの手順 3（WG ホストで、[wireguard.md のクライアントを削除する](../wireguard.md#クライアントを削除する)の手順 1〜6）: 手順 3 は `client remove` の後の dry-run が、その公開鍵の未知の peer だけを挙げて終了コード 1 で止まった。手順 4 の `--drop-unknown-peers --dry-run`、手順 5 の本適用の後、手順 6 でクライアントは無く、`wg show wg0 peers` は拠点 B だけ
- 検証環境は、両拠点で [wireguard.md の全部消す](../extra/wireguard.md#全部消すロールバック)の手順 1〜4 と、veth・namespace・clone の削除で片付けた。拠点 A の `remove A --purge` の後も `/etc/wireguard` に `wg0.conf.bak-<日時>` の 2 つ（`client add`・`client remove` の `apply` が作った控えで、秘密鍵を含む）が残った。`--purge` は控えを消さない（`scripts/wireguard/wg-vpn.sh` の `cmd_remove`）。検証用の鍵なので手で消した

**確認していないこと**:

- インターネット越し（物理のルーターのポート転送・NAT・DDNS）と、テザリングなどへのつなぎ替え
- トンネル越しの SSH、相手拠点の LAN 上の別のホスト、張ったままの再起動、サスペンド復帰、Wi-Fi の切り替え、arm64 の Windows、Windows の実機
