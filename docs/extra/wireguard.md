# WireGuard VPN 構築手順（site-to-site + road warrior / wg-quick + firewalld）のロールバックと注意点

[手順書](../wireguard.md)・[検証記録](../verification/wireguard.md)・[参考資料](../reference/wireguard.md)

- 手順書の実施手順は項（###）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順、「本書」「この文書」は手順書を指す

## 全部消す（ロールバック）

- 各拠点の WG ホストで、**必要なところまで**貼る（後の手順ほど戻しにくい）
- ルーター側の設定は、この節の手順 5 で消す
- → [全部消すときの補足](../reference/wireguard.md#全部消すときの補足)

> [!CAUTION]
> **鍵を消す前に。** 同じ鍵で戻す可能性が少しでもあるなら、先に[バックアップ](../wireguard.md#バックアップと復旧os-の再インストール)を取る。**この節の手順 2 で鍵が消え、そこから先は戻せない。** 鍵を作り直すと、相手拠点の `site.env` と conf の公開鍵の差し替え、クライアント全台の conf 再発行が連鎖する。

1. サービスを止めて、firewalld と sysctl を戻す。

   ```bash
   cd "${REPO:?「site.env を作る」の手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
   sudo ./wg-vpn.sh -e ~/wg/site.env remove A            # 拠点 B のホストでは B
   ```

   - conf・鍵・クライアント用 conf は残るので、この手順までなら `apply` でやり直せる

1. 鍵も消すときだけ、conf・鍵・クライアント用 conf を消す（取り戻せない）。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env remove A --purge    # conf・鍵・クライアント用 conf も消す（clients.list は残る）
   ```

   - `apply` が控えた `/etc/wireguard/wg0.conf.bak-<日時>`（秘密鍵を含む）は、`--purge` でも残る。要らなければ手で消す

1. `site.env` と `clients.list` も要らないときだけ、`~/wg` を消す。

   ```bash
   rm -rf ~/wg
   ```

1. パッケージも要らないときだけ、`wireguard-tools` と `systemd-resolved` を消す。

   ```bash
   sudo dnf remove wireguard-tools systemd-resolved
   ```

1. 両拠点のルーターから、ポート転送と静的経路を消す。

   - 消す値は、[鍵を作って適用する](../wireguard.md#鍵を作って適用する)の手順 5 の `apply` の末尾に表示されたもの（[補足: ルーターの設定](../reference/wireguard.md#ルーターの設定)）

---

## 注意点

#### 落とし穴 1: 秘密鍵を conf の外に出すと reload で消える

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

#### 落とし穴 2: reload では経路が追加されない

```
$ sudo wg show wg0 allowed-ips
${SITE_B_PUBKEY}	10.99.0.2/32 192.168.120.0/24
<CLIENT1_PUBKEY>	10.99.1.1/32
<CLIENT2_PUBKEY>	10.99.1.2/32
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

#### 落とし穴 3: 登録簿に無い peer は apply で消える

`apply` は `clients.list` からクライアントの `[Peer]` を**毎回組み立て直す**。手で `wg0.conf` に書いた `[Peer]` は、登録簿に無ければ書き換えのときに消える。手で組んだ構成から `wg-vpn.sh` に移るときは、`apply` の前に既存のクライアントを登録簿へ写す:

```
sudo ./wg-vpn.sh -e ~/wg/site.env client add B <名前> \
  --pubkey <クライアントの公開鍵> --ip <そのクライアントのトンネル IP>
```

- `--pubkey` を付けると秘密鍵はホストで作らないので、**クライアント端末の設定はそのままでよい**（`--ip` に既存のトンネル IP を指定すること）
- 生成される `<名前>.conf` の `PrivateKey` は、プレースホルダのままになる

現在は、既存の `wg0.conf` に登録簿にも相手拠点にも無い `[Peer]` があると、`apply` は鍵と行番号を表示して**何も変更せずに止まる**。消してよい場合だけ `--drop-unknown-peers` を付ける。

#### 転送を絞りたい場合

本書の方針は **WG ホストでは絞らない**。

- 誰がどこへ入れるかは、宛先ホストのファイアウォール（`firewalld` のゾーンや rich rule、アプリの認証）で決める
- トンネル越しの通信は送信元 IP がそのまま届く（NAT しない）ので、宛先ホストで送信元の帯（相手拠点 LAN、クライアント帯）ごとに許可・拒否できる

それでも WG ホストで絞りたい場合は、LAN 側ゾーンに rich rule を足す（例: 拠点 B のクライアント帯から拠点 A の LAN への転送を拒否する）。実行範囲は[検証記録](../verification/wireguard.md)を参照する

```bash
{
  sudo firewall-cmd --permanent --zone="$LAN_ZONE" \
    --add-rich-rule="rule family=ipv4 source address=$WG_B_CLIENT_NET destination address=$SITE_A_LAN reject"
  sudo firewall-cmd --reload
}
```

方向ごと・組み合わせごとに細かく絞る構成が要るなら、専用ゾーン + policy の旧レイアウト（履歴 `d364840` 以前の `docs/wireguard.md` と `wg-vpn.sh`）が参考になる。

#### `AllowedIPs` が cryptokey routing の要

`AllowedIPs` は次の 2 つの役割を持つ。

- **受信時**: トンネルから届いたパケットの送信元がこの範囲外なら捨てる
- **送信時**: この範囲宛てのパケットをこの peer に送る。**wg-quick はこの範囲をそのまま `wg0` への経路としても追加する**

そのため、相手の**トンネル IP だけでなく相手の LAN も**書く。

- クライアント帯を使う場合は、それも入る。スクリプトが相手 peer の `AllowedIPs` にこれを組み立てる
- `journalctl -u wg-quick@wg0` で、起動時に経路が追加されるのを確認できる

この対応表は **1 インターフェース内で peer ごとに排他**で、1 つのアドレスを 2 つの peer に対応づけることはできない。だからクライアントは拠点に所属させ、拠点ごとに帯を分ける（[選択した方針](../verification/wireguard.md#選択した方針)）。

> `0.0.0.0/0` を書くと、WG ホスト自身の通信も含めてすべてがトンネルに向かう（wg-quick が policy routing で差し替える）。拠点間接続では相手 LAN だけを書く。

#### ルーターの静的経路とヘアピン（非対称経路）

この構成では、Client A の最初のパケットは Router A に行き、**同じ LAN 側インターフェースへ折り返して**（ヘアピン）WG host A に届く。このとき:

- ICMP Redirect を返すルーターでは、それを受け入れたクライアントが以降 WG host A に直接送る（`ip route get` に `<redirected>` と出る）
- Redirect を受け入れないクライアントでは、毎回 Router A 経由のままになる
- いずれの場合も戻りのパケットは WG host A から Client A へ直接届くため、**Router A から見ると片方向しか通らない非対称経路**になる

市販ルーターや UTM のなかには、LAN 内で折り返す転送を拒否するもの、戻りが見えない TCP セッションを途中で切るものがある。つながらない、あるいは TCP だけが不安定な場合は、ルーター側で折り返し転送を許可する設定を探すか、次の代替策をとる。

- **(a) クライアントに経路を追加する** — 通信するクライアントにだけ `${SITE_B_LAN} via ${WG_A_LAN_IP}` を入れる。ルーターを通らないので非対称経路も起きない
  - 台数が多いと管理が大変になる（DHCP option 121 を配布できるルーターなら一括で配れる）
- **(b) WG ホストで NAT する（masquerade）** — 相手拠点から届いた通信の送信元を WG ホストの IP に書き換えれば、戻りは WG ホスト宛てになるので、自拠点ルーターの静的経路は不要になる
  - ただし **(1) 送信元のクライアントが相手からは区別できなくなり、(2) NAT した側への着信はできない**（片方向になる）
  - 双方向に通信する要件は満たせないので、**最後の手段**としてだけ使う

#### ルーターにはクライアント帯の静的経路も要る

NAT をしない構成なので、LAN 側ホストの返事はデフォルトゲートウェイ（ルーター）に向かう。ルーターがクライアント帯を知らないと、そこで行き場を失う。

- **両拠点のルーター**に要る
- `${WG_TUNNEL_NET}` とクライアント帯を 1 つの大きな帯に取っておけば、静的経路は 1 本で済む

#### 相手拠点のホストが帯を知らないと黙って捨てる

WireGuard は、`AllowedIPs` の範囲外から届いたパケットを **ICMP も返さずに**捨てる。相手拠点のホストの `AllowedIPs` にクライアント帯が入っていないと、ハンドシェイクも転送も正常に見えたまま届かない。**両拠点の** `site.env` に帯を書き、両拠点で `apply` すること。

#### WG ホスト自身から相手 LAN へ送る場合

WG ホスト自身が送るパケットは、`wg0` の経路により**送信元がトンネル IP（`${WG_A_TUN_IP}`）になる**。相手拠点のクライアントは `${WG_TUNNEL_NET}` への経路を持たないので、返事をデフォルトゲートウェイの Router B に送り、そこで行き場を失う。

**クライアント同士の通信には影響しない。** WG ホスト自身からも相手 LAN を使いたい場合は、次のどちらかにする。

- **送信元を LAN 側 IP にする**（`ping -I`、アプリ側での bind など）。設定変更が要らないので簡単
- 相手ルーターに `${WG_TUNNEL_NET}` via `${WG_x_LAN_IP}` の静的経路を追加する（[ルーターの設定](../reference/wireguard.md#ルーターの設定)のとおり、トンネル網とクライアント帯を 1 つの大きな帯に取っておけば静的経路 1 本で済む）

#### トンネル越しに WG ホスト自身の ssh や Cockpit へ入る場合

`wg0` は LAN 側ゾーン（`${LAN_ZONE}`）に入っているので、**LAN から入れるものはトンネル越しにも入れる**。

- `public` の既定なら ssh・cockpit・dhcpv6-client が開いている
- WG ホスト自身も「宛先ホストのファイアウォールだけを気にする」の例外ではなく、開ける・絞るは LAN と同じゾーン操作で行う

```bash
sudo firewall-cmd --info-zone="$LAN_ZONE"   # interfaces に wg0、services に ssh / cockpit があるか
```

`services` に `cockpit` が無ければ、開けて読み直す（LAN からも開く）。

```bash
sudo firewall-cmd --permanent --zone="$LAN_ZONE" --add-service=cockpit && sudo firewall-cmd --reload
```

送信元を絞りたい場合は、LAN 側ゾーンの rich rule で行う（例: ssh はトンネル網からだけ拒否する）。

```bash
{
  sudo firewall-cmd --permanent --zone="$LAN_ZONE" \
    --add-rich-rule="rule family=ipv4 source address=$WG_A_CLIENT_NET service name=ssh reject"
  sudo firewall-cmd --reload
}
```

- Cockpit は `9090/tcp`（firewalld の `cockpit` サービス）。ホスト側で動いているかは `systemctl is-active cockpit.socket` で確認する。ブラウザからは `https://${WG_x_LAN_IP}:9090`
- 旧レイアウトでは、`wg0` を入れた専用ゾーンが**何も開いていなかった**
  - 転送用の policy は**ホスト自身宛ての通信には効かない**ので、専用ゾーンに service を開ける必要があった
- ssh はトンネルの向こう側全体から届く。公開鍵認証のみにする（`PasswordAuthentication no`）などの対策は別途行う

#### 片側がグローバル IP を持たない場合（CGNAT など）

着信を受けられない側（例: 拠点 A）が常にトンネルを張りに行く構成にする。`site.env` では、着信を受けられない拠点の `SITE_x_PUBLIC` を空にする。

| | 着信を受けられない側（A） | グローバル IP がある側（B） |
|---|---|---|
| `[Peer]` の `Endpoint` | **必須**（`${SITE_B_PUBLIC}:${WG_PORT}`） | 省略する |
| `PersistentKeepalive` | **必須**（NAT のマッピングを維持するため） | 不要 |
| ルーターのポート転送 | 不要 | **必須** |
| firewalld の `${WG_PORT}/udp` | 不要 | **必須** |

スクリプトは、相手拠点の `SITE_x_PUBLIC` が空なら `Endpoint` 行を書かない。

WireGuard は、正しく認証できたパケットの送信元を peer の endpoint として覚える。そのため、`Endpoint` を書いていない側もハンドシェイクを受けた後は返信先がわかる。

- ただし、**着信を受けた側から先に通信を始めることはできない**。A の keepalive でトンネルが維持されている間だけ、B 側のクライアントから A 側へ接続できる
- **両側とも `Endpoint` を省略すると、どちらからもトンネルを張れない**

#### 1 台のクライアントは 1 つの拠点にしか接続できない

cryptokey routing の制約（[`AllowedIPs` が cryptokey routing の要](#allowedips-が-cryptokey-routing-の要)）。両拠点に同時に直接つなぐ構成は成立しない。接続先を変えたい場合は、その拠点用の conf を別に作って切り替える（トンネル IP も別の帯のものになる）。

#### 着信を受けられない拠点はクライアントを受けられない

クライアントは `Endpoint` を指定して接続しに行くので、接続先拠点にはグローバル IP（または DDNS 名）とポート転送が要る。CGNAT の拠点（`SITE_x_PUBLIC` が空）では `WG_x_CLIENT_NET` も空にする。

#### クライアントが拠点の LAN 内にいるとき

ノート PC を持ち帰って拠点 A の LAN 内で VPN を張ると、`${SITE_A_PUBLIC}` 宛ての通信が自拠点のルーターに出て折り返す（ヘアピン）。

- ルーターが対応していないと接続できない。LAN 内では VPN を切る運用にするのが簡単
- しかも NetworkManager は `import` した時点でトンネルを張るので、`up` する前から起きる（[Road Warrior 手順書の注意点](wireguard-road-warrior.md#注意点)）

#### クライアントの秘密鍵の扱い

ホスト側で鍵を作ると、秘密鍵入りの conf が一時的にホストに残る。**クライアントに取り込んだら消す**（「クライアントを登録する」の手順 7 の `rm`）。

- より厳密にするなら、クライアント側で鍵を作って公開鍵だけをホストに渡す
- AlmaLinux 10 の PC でその流れにするなら、[Road Warrior 手順書の「鍵を作る」の手順 3](../wireguard-road-warrior.md#鍵を作る)と[「WG ホストに登録する」の手順 1〜3](../wireguard-road-warrior.md#wg-ホストに登録する)

#### `DNS =` を書く場合

クライアント conf の `[Interface]` に `DNS = ${WG_CLIENT_DNS}` を書くと、VPN 接続中の名前解決を拠点側の DNS に向けられる。

- **Linux の `wg-quick`**: このとき `resolvconf` を呼ぶので、`systemd-resolved` が有効である必要がある
  - EL10 では `wireguard-tools` の依存で入るが **disabled のまま**なので、使うなら `systemctl enable --now systemd-resolved`
- **公式アプリ**（Windows / macOS / iOS / Android）: 追加の設定は要らない
- **NetworkManager に `nmcli connection import` で取り込む場合**: `DNS =` が `ipv4.dns` になり resolv.conf は NetworkManager が書くので、`systemd-resolved` は要らないはず（要確認。[Road Warrior 手順書](wireguard-road-warrior.md#注意点)）

#### 全トラフィックを VPN 経由にする場合（対象外）

クライアント conf の `AllowedIPs` を `0.0.0.0/0` にすると、そのクライアントの通信がすべてトンネルに入る。拠点側で NAT（masquerade）と外向きの転送許可（例: `external` ゾーンへの policy）が追加で要る。本書の構成（拠点の LAN にだけ届く）とは別物なので扱わない。

#### クライアント同士を通す場合

クライアント A → クライアント B は、どちらも同じ `wg0` にぶら下がる `wg0 → wg0` の転送になる。

- ホストのゾーンの forward はこれも許可するが、**生成したクライアント conf の `AllowedIPs` は両拠点 LAN とホスト間のトンネル帯だけ**で、クライアント帯は含まない
- 通すには、通信する各クライアントの `AllowedIPs` に必要なクライアント帯を追加して、経路と受信元の許可をそろえる必要がある
- 隔離したい場合は、LAN 側ゾーンに rich rule を足す（例: `rule family=ipv4 source address=$WG_A_CLIENT_NET destination address=$WG_A_CLIENT_NET reject`）
- 旧レイアウトでは、policy を作らない限り通らなかった

#### Endpoint に DDNS 名を書く場合

`Endpoint` のホスト名は **`wg-quick up` の時点で一度だけ名前解決される**（`wg(8)` の仕様）。相手のグローバル IP が変わると、再起動するまで古い IP に送り続ける。対策:

- `wireguard-tools` 同梱の `/usr/share/doc/wireguard-tools/contrib/reresolve-dns/reresolve-dns.sh` を systemd timer で定期実行する
- 片側だけでも固定 IP にし、そちらを常に接続を受ける側にする（上記の CGNAT 構成と同じ形）。動的 IP の側が張りに行くので、その側の IP が変わっても、固定 IP の側は新しい送信元を endpoint として覚え直す

クライアント conf の `Endpoint` に DDNS 名を書いた場合も同じだが、**公式アプリは接続のたびに名前解決する**ので `reresolve-dns.sh` のような仕組みは要らない

#### MTU

wg-quick は `MTU` を指定しない場合、外側の経路の MTU から自動で決める

- PPPoE（MTU 1454 / 1492 など）の回線では、トンネル内の最大サイズの通信だけが通らないことがある（ping は通るが、大きなファイル転送や一部の HTTPS が止まる）
- その場合は `site.env` の `WG_MTU` に `1380` などと書いて `apply` し直す（`MTU =` の行は `WG_MTU` が空なら書かれず、書いてあれば入る）
- 外出先のクライアントでも、モバイル回線によっては同じことが起きる（クライアント conf の `[Interface]` に `MTU =` を書く）

#### LAN サブネットの重複

両拠点の LAN が同じサブネット（例: どちらも `192.168.1.0/24`）だと経路を区別できないので、この構成は成立しない。家庭用ルーターの初期値のままの拠点同士を結ぶ場合は、どちらかの LAN のアドレスを変える必要がある。

#### 再起動後の自動起動

`systemctl enable` 済みなので、OS 起動時に `wg-quick@wg0` が上がる。
