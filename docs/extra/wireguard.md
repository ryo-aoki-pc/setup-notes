# WireGuard VPN 構築手順（site-to-site + road warrior / wg-quick + firewalld）のロールバックと注意点

[手順書](../wireguard.md)・[検証記録](../verification/wireguard.md)・[参考資料](../reference/wireguard.md)

- 手順書の実施手順は項（###）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

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

## AlmaLinux 10 の PC のロールバック

- この節は AlmaLinux 10 の PC のもの。Windows 11 の PC は[Windows 11 のロールバック](#windows-11-のロールバック)
- **PC で、「鍵を作る」の手順 1 の変数を設定したシェルで貼る**（`WG_DIR` が空だと `${WG_DIR:?…}` で止まる）
- この節の手順 3 だけは WG ホストで貼る

> [!CAUTION]
> **この節の手順 1 で、秘密鍵の置き場所である NetworkManager のプロファイル `wg0` を消す。** 鍵のバックアップは取っていないので、消した鍵は取り戻せない（[選択した方針](../reference/wireguard.md#外出先の-pc-で選択した方針)）。

1. PC で、プロファイル `wg0` と鍵・conf の一時置き場を消す（取り戻せない）。

   ```bash
   {
     sudo nmcli connection down wg0 2>/dev/null; sudo nmcli connection delete wg0
     rm -f "${WG_DIR:?「鍵を作る」の手順 1 の WG_DIR が空のまま}/wg0.key" "${WG_DIR}/wg0.conf" "${WG_DIR}/wg0.pub" && rmdir "${WG_DIR}"
     printf '\n\033[7m 確認 \033[0m\n'
     sudo ls /etc/NetworkManager/system-connections/             # wg0.nmconnection が無い
   }
   ```

   - `rm -rf` を使わないのは、`WG_DIR` を WG ホストの `~/wg` と取り違えて貼っても登録簿を消さないため

1. パッケージも消すときだけ、`wireguard-tools` を消す。

   ```bash
   sudo dnf remove wireguard-tools     # 依存で入った systemd-resolved も一緒に消える（dnf.conf の clean_requirements_on_remove=True）。トランザクション表を見てから y
   ```

   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. WG ホストで、登録を消して反映する。

   - [クライアントを削除する](../wireguard.md#クライアントを削除する)の手順 1〜6 を行う。対象は、「クライアントを登録する」の手順 1 で登録した `CLIENT_NAME` と `SITE`
   - 削除前の公開鍵を控え、未知 peer と照合する。`--drop-unknown-peers` を確認なしに付けない
   - ルーターの静的経路（クライアント帯）は、他のクライアントも使うので触らない

---

## Windows 11 のロールバック

- 上から順に、管理者の Windows PowerShell（5.1）に貼る。この節の手順 3 だけは WG ホストで行う
- トンネルを張っていれば、この節の手順 1 で切る

> [!CAUTION]
> **この節の手順 1 で、秘密鍵の置き場所であるトンネルの設定（`wg0.conf.dpapi`）を消す。** 鍵のバックアップは取っていないので、消した鍵は取り戻せない。この節の手順 2 の WireGuard のアンインストールは、`C:\Program Files\WireGuard\Data`（ほかのトンネルの設定も）を丸ごと消す。

1. PC で、トンネル `wg0` と、鍵・conf の一時置き場を消す（取り戻せない）。

   ```powershell
   & {
     $dir = "$env:USERPROFILE\wg-client"
     if (Get-Service -Name 'WireGuardTunnel$wg0' -ErrorAction SilentlyContinue) {
       & "$env:ProgramFiles\WireGuard\wireguard.exe" /uninstalltunnelservice wg0 2>&1 | ForEach-Object { "$_" }
       for ($i = 0; $i -lt 30 -and (Get-Service -Name 'WireGuardTunnel$wg0' -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     }
     Remove-Item -LiteralPath "$env:ProgramFiles\WireGuard\Data\Configurations\wg0.conf.dpapi" -ErrorAction SilentlyContinue
     Remove-Item -LiteralPath "$dir\wg0.key", "$dir\wg0.conf", "$dir\wg0.pub" -ErrorAction SilentlyContinue
     if ((Test-Path -LiteralPath $dir) -and -not (Get-ChildItem -LiteralPath $dir -Force)) { Remove-Item -LiteralPath $dir }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-Service -Name 'WireGuardTunnel$wg0' -ErrorAction SilentlyContinue
     Get-ChildItem -LiteralPath "$env:ProgramFiles\WireGuard\Data\Configurations" -Filter 'wg0.*' -ErrorAction SilentlyContinue
     Test-Path -LiteralPath $dir
   }
   ```

   - 最後に `False` だけが出ればよい
   - 置き場所に、この文書が作ったもの以外のファイルがあれば、置き場所は消さない（`True` が出る。`-Recurse` を使わないのは、取り違えて大事なものを消さないため）
   - 窓で `wg0` を選び「選択したトンネルの削除」を押しても、トンネルの設定は消える

1. WireGuard も消すときだけ、WireGuard を外す（取り戻せない）。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget uninstall --exact --id WireGuard.WireGuard --source winget
   winget list --exact --id WireGuard.WireGuard --source winget
   Get-Service -Name 'WireGuard*' -ErrorAction SilentlyContinue
   Test-Path -LiteralPath "$env:ProgramFiles\WireGuard"
   ```

   - `正常にアンインストールされました`（英語の Windows では `Successfully uninstalled`）と出て、`winget list` が `入力条件に一致するインストール済みのパッケージが見つかりませんでした。` を出し、サービスが何も出ず、`False` が出ればよい
   - WireGuard の窓と、通知領域のアイコンも消える

1. WG ホストで、[AlmaLinux 10 の PC のロールバック](#almalinux-10-の-pc-のロールバック)の手順 3 の案内に従い、登録を消して反映する。

   - 「クライアントを登録する」の手順 1 の `CLIENT_NAME` は、[Windows 11 で WG ホストに登録して取り込む](../wireguard.md#windows-11-で-wg-ホストに登録して取り込む)の手順 2 で登録した、この PC の名前にする
   - ルーターの静的経路（クライアント帯）は、他のクライアントも使うので触らない

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
- しかも NetworkManager は `import` した時点でトンネルを張るので、`up` する前から起きる（[AlmaLinux 10 の PC からつなぐときの注意点](#almalinux-10-の-pc-からつなぐときの注意点)）

#### クライアントの秘密鍵の扱い

ホスト側で鍵を作ると、秘密鍵入りの conf が一時的にホストに残る。**クライアントに取り込んだら消す**（「クライアントを登録する」の手順 9 の `rm`）。

- より厳密にするなら、クライアント側で鍵を作って公開鍵だけをホストに渡す
- AlmaLinux 10 の PC でその流れにするなら、[「鍵を作る」の手順 3](../wireguard.md#鍵を作る)と[「WG ホストに登録する」の手順 1・2](../wireguard.md#wg-ホストに登録する)

#### `DNS =` を書く場合

クライアント conf の `[Interface]` に `DNS = ${WG_CLIENT_DNS}` を書くと、VPN 接続中の名前解決を拠点側の DNS に向けられる。

- **Linux の `wg-quick`**: このとき `resolvconf` を呼ぶので、`systemd-resolved` が有効である必要がある
  - EL10 では `wireguard-tools` の依存で入るが **disabled のまま**なので、使うなら `systemctl enable --now systemd-resolved`
- **公式アプリ**（Windows / macOS / iOS / Android）: 追加の設定は要らない
- **NetworkManager に `nmcli connection import` で取り込む場合**: `DNS =` が `ipv4.dns` になり resolv.conf は NetworkManager が書くので、`systemd-resolved` は要らないはず（要確認。[AlmaLinux 10 の PC からつなぐときの注意点](#almalinux-10-の-pc-からつなぐときの注意点)）

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

wg-quick は `MTU` を指定しない場合、出口の NIC の MTU から 80 を引いた値にする（1500 なら 1420）。ルーターの先の回線の MTU は見ない

- PPPoE（MTU 1454 / 1492 など）のように MTU が 1500 より小さい回線では、トンネル内の最大サイズのパケットが回線の MTU を超え、分割されて送られる
- 分割されたパケットが途中で落ちると、**小さい通信は通るのに、大きい通信だけ遅い・止まる**（ping と ssh のキー入力は通るが、ssh の画面の描き直し・大きなファイル転送・一部の HTTPS が再送待ちになる）
- 調べ方と直し方は、[回線に合わせて MTU を下げる](../wireguard.md#回線に合わせて-mtu-を下げる任意)（`site.env` の `WG_MTU` に `1380` などと書いて `apply` し直す。`MTU =` の行は `WG_MTU` が空なら書かれず、書いてあれば入る）
- 外出先のクライアントも、接続先の拠点の回線を通るので同じことが起きる。モバイル回線の側で起きることもある（クライアント conf の `[Interface]` に `MTU =` を書く）
  - `WG_MTU` に値を書いた後に `client add` で作る conf には、同じ `MTU =` が入る
  - 配布済みのクライアントは作り直されないので、[回線に合わせて MTU を下げる](../wireguard.md#回線に合わせて-mtu-を下げる任意)の手順 8 で入れる

#### LAN サブネットの重複

両拠点の LAN が同じサブネット（例: どちらも `192.168.1.0/24`）だと経路を区別できないので、この構成は成立しない。家庭用ルーターの初期値のままの拠点同士を結ぶ場合は、どちらかの LAN のアドレスを変える必要がある。

#### 再起動後の自動起動

`systemctl enable` 済みなので、OS 起動時に `wg-quick@wg0` が上がる。

#### AlmaLinux 10 の PC からつなぐときの注意点

- **拠点の LAN 内では切る**: 「conf を取り込む」の手順 4 と「トンネルを確かめる」の全部は**どちらの拠点の LAN の外でも**行い、import 直後に自動で張られるので、すぐ切る
  - `Endpoint` 宛ての通信が、ルーターで折り返す[ヘアピン](#クライアントが拠点の-lan-内にいるとき)になる
  - NetworkManager が入れる拠点 LAN の経路が Wi-Fi の直結経路より優先されると、LAN 宛ての通信がすべてトンネルに入る
  - `AllowedIPs` には**両拠点の LAN**が入るので、接続先ではない方の拠点の LAN にいるときも同じことが起きる（その LAN のデフォルトゲートウェイに届かなくなり、`Endpoint` 自体も見えなくなってトンネルごと死ぬ）
- **`DNS =` の扱いが wg-quick と違う**: 本書は `DNS =` 無し
  - NetworkManager では `ipv4.dns` になり、接続中は resolv.conf を NetworkManager が書き換えるので、`systemd-resolved` は不要と考えられる
  - wg-quick は `resolvconf` 経由で resolved が要る（→ [wireguard.md](#dns--を書く場合)）
- **MTU**: 拠点が `WG_MTU` を下げているとき（[wireguard.md の「回線に合わせて MTU を下げる」](../wireguard.md#回線に合わせて-mtu-を下げる任意)）は、PC も同じ値にする
  - 拠点が `WG_MTU` を書いた後に `client add` で登録した conf には `MTU =` が入っていて、取り込むと `wireguard.mtu` になる
  - それより前に取り込んだプロファイルは、`sudo nmcli connection modify wg0 wireguard.mtu 1380` して down / up（`1380` は拠点の値に読み替える）
  - 拠点が下げていなくても、PPPoE やモバイル回線で大きい通信だけ遅い・止まるなら、同じ操作で下げる（→ [wireguard.md: MTU](#mtu)）
- **全トラフィックを VPN に通す構成は対象外**: NetworkManager 側は `wireguard.ip4-auto-default-route`（`/0` の peer で自動有効）、拠点側は NAT が要る（→ [wireguard.md](#全トラフィックを-vpn-経由にする場合対象外)）
- **`Endpoint` が DDNS 名のとき**: 本書の例は IP リテラルを使う。DDNS を使う場合は [wireguard.md](#endpoint-に-ddns-名を書く場合)を参照する
- **サスペンド復帰・Wi-Fi の切り替え**: 復帰後に `nmcli device status` でトンネルの状態を見る
  - `autoconnect no` のプロファイルは、復帰後に `nmcli device status` を見て、切れていたら接続し直す
  - Wi-Fi が変わっても、WireGuard は送信元の変化に追従するはず。`PersistentKeepalive = 25` が NAT の穴を維持する
- **1 台のクライアントは 1 つの拠点だけ**（→ [wireguard.md](#1-台のクライアントは-1-つの拠点にしか接続できない)）。別拠点用は別名のプロファイルを作り、同時には張らない
- **同じ ifname で wg-quick と NetworkManager を併用しない**: `/etc/wireguard/wg0.conf` と NetworkManager の `wg0` を両方置くと、どちらが `wg0` を持つかで衝突する
- **同名クライアントの登録があれば先に `client remove`**: `client add` は同名を拒否する
- **秘密鍵は `nmcli -s` で読める**: PC のログインパスワードが鍵の守りになる
  - root なら常に読める
  - **ローカルのコンソールにログイン中のユーザーは、`sudo` 無しでも秘密鍵を読める**（polkit の既定 `allow_active=yes`）

#### Windows 11 の注意点

- **拠点の LAN 内では張らない**: `AllowedIPs` の経路は、ルートのメトリック 0 で `wg0` に入る（ソースの `tunnel/addressconfig.go`）。LAN の直結の経路（Windows の既定ではルートのメトリック 256）より優先されるはずなので、AlmaLinux 10 と同じく LAN 宛ての通信がトンネルに入る
- **張ったまま再起動すると、また張られる**: トンネルのサービスは自動で起動する（ソースの `manager/install.go`）。拠点の LAN に戻る前に切る
- **ほかの端末と同じ名前で登録しない**: [クライアントを登録する](../wireguard.md#クライアントを登録する)の手順 2 は、`CLIENT_NAME` と同じ名前の登録を消す。AlmaLinux 10 の PC と両方使うなら、別々の名前と鍵で登録する
- **秘密鍵は、管理者なら読める**: 張っている間の `wg.exe show wg0 private-key`、窓の「編集」（設定の全文を出す）と「すべてのトンネルをzipにエクスポート」。WireGuard の窓は Administrators の一員にしか出ない。Windows のサインインのパスワードが鍵の守りになる
- **WireGuard を外すと、ほかのトンネルの設定も消える**: MSI のアンインストールは `C:\Program Files\WireGuard\Data` を丸ごと消す（ソースの `installer/customactions.c` の `RemoveConfigFolder`）
- **MTU**: conf に `MTU =` が無いと、既定の経路のインターフェースの MTU から 80 を引いた値になる（1500 なら 1420。WireGuard の文書の「Network Configuration Quirks」）
  - 拠点が `WG_MTU` を下げているとき（[wireguard.md の「回線に合わせて MTU を下げる」](../wireguard.md#回線に合わせて-mtu-を下げる任意)）は、PC も同じ値にする。拠点が `WG_MTU` を書いた後に `client add` で登録した conf には、はじめから `MTU =` が入っている
  - それより前に取り込んだトンネルと、大きい通信だけ遅い・止まるときは、トンネルを切ってから窓の「編集」で `[Interface]` に `MTU = 1380` を足す（`1380` は拠点の値に読み替える）
- **`DNS =` を書いた場合**: `wg0` の DNS サーバーになり、Windows の通常の名前解決の扱い（複数の DNS サーバーを使う）に任される。DNS を絞る規則は、キルスイッチが掛かる構成（`/0` の peer が 1 つ）でだけ入る（同じ文書）。本書は `DNS =` 無し
- **`Endpoint` が DDNS 名のとき**: トンネルを張るたびに名前を引く（ソースの `tunnel/service.go`）
- **トンネルの名前はファイル名から決まる**: `wg0.conf` → `wg0`（英数字と `_=+.-` の 32 文字まで。ソースの `conf/name.go`）。サービスの名前は `WireGuardTunnel$wg0`、アダプターの名前も `wg0`
