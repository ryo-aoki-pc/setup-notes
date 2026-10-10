# WireGuard VPN 構築手順（site-to-site + road warrior / wg-quick + firewalld）

## 実施手順

- [検証記録](verification/wireguard.md)・[参考資料](reference/wireguard.md)・[ロールバックと注意点](extra/wireguard.md)

> [!IMPORTANT]
> - [site.env を作る](#siteenv-を作る)の手順 1〜3 と[鍵を作って適用する](#鍵を作って適用する)の手順 1〜5 は**両拠点の WG ホストで**、同じ項の手順 6 は**両拠点のルーターで行う**
> - [クライアントを登録する](#クライアントを登録する)の手順 1〜7 と[状態と疎通を確かめる](#状態と疎通を確かめる)の手順 1 は、**クライアントを受ける拠点のホストで行う**。[クライアントを登録する](#クライアントを登録する)の手順 6 と[状態と疎通を確かめる](#状態と疎通を確かめる)の手順 2 は、クライアントで行う
> - コマンドはすべて `${REPO}/scripts/wireguard`（`REPO` は[site.env を作る](#siteenv-を作る)の手順 1 で設定する clone 先）で実行し、`-e ~/wg/site.env` で値を渡す
> - **拠点 B のホストでは、引数の `A` を `B` に読み替える**
> - [site.env を作る](#siteenv-を作る)の手順 2 と[鍵を作って適用する](#鍵を作って適用する)の手順 2 で、**`vi` が開く**。保存して閉じてから次の手順を行う
> - **OS を入れ直して同じ鍵で戻したい場合は、先に[バックアップと復旧](#バックアップと復旧os-の再インストール)を読む**。鍵さえ残っていれば、相手拠点の設定も配布済みのクライアント conf も変えずに復旧できる

- [site.env を作る](#siteenv-を作る)の手順 1 で `REPO` を設定したシェルで実行する。新しいシェルを開いたら設定し直す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 手順の後: 大きい通信だけ遅い・止まるなら[回線に合わせて MTU を下げる](#回線に合わせて-mtu-を下げる任意)、クライアントを消すなら[クライアントを削除する](#クライアントを削除する)、OS の入れ直しに備えるなら[バックアップと復旧](#バックアップと復旧os-の再インストール)、やめるなら[全部消す（ロールバック）](extra/wireguard.md#全部消すロールバック)

> [!WARNING]
> **トンネル越しに ssh して作業している場合、`apply` の restart で自分のセッションが切れる。**
>
> - 該当するのは、[鍵を作って適用する](#鍵を作って適用する)の手順 5、[クライアントを登録する](#クライアントを登録する)の手順 3 と、[回線に合わせて MTU を下げる](#回線に合わせて-mtu-を下げる任意)・[クライアントを削除する](#クライアントを削除する)の `apply`
> - 切り離して実行する方法は、[wireguard-road-warrior.md の落とし穴](wireguard-road-warrior.md#落とし穴-apply-は作業中の-ssh-経路そのものを切る)にある

### site.env を作る

1. 変数を設定する。

   ```bash
   REPO=~/setup-notes                    # このリポジトリを clone した場所に合わせる。新しいシェルを開いたら設定し直す
   ```

   - clone 先が `~/setup-notes` なら、既定のままでよい

1. `~/wg/site.env` を作って編集する。

   ```bash
   mkdir -p ~/wg && chmod 700 ~/wg
   cp "${REPO:?このリポジトリの場所を REPO に入れてから貼る}/scripts/wireguard/site.env.example" ~/wg/site.env
   chmod 600 ~/wg/site.env
   vi ~/wg/site.env                      # 公開鍵は「鍵を作って適用する」の手順 2 で書き足す
   ```

   - **編集するのは `~/wg/site.env` だけ。** 埋める値は[設定値の表](#siteenv-に書く値)にある（クライアント帯は、クライアントを受ける拠点にだけ書く）
   - 書けたら、保存して `vi` を閉じる

1. 書いた `site.env` を、両拠点の WG ホストの `~/wg/site.env` に同じ内容で置く。

   - **次の手順は、両拠点に置いてから貼る**

### 鍵を作って適用する

1. 両拠点の WG ホストで、`wireguard-tools` を入れて鍵ペアを作る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   cd "${REPO:?「site.env を作る」の手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
   sudo ./wg-vpn.sh -e ~/wg/site.env keygen A        # 拠点 B のホストでは B
   ```

   - `公開鍵:` の行に、このホストの公開鍵が出る
   - **次の手順は、両拠点で鍵を作ってから貼る**（両拠点の公開鍵を `site.env` に書くため）

1. それぞれの公開鍵を `site.env` に書く。

   ```bash
   vi ~/wg/site.env                      # SITE_A_PUBKEY と SITE_B_PUBKEY を埋める
   ```

   - **相手拠点の公開鍵は必須**。空のまま `apply` すると、何も変更せずに止まる
   - 相手に渡すのは公開鍵だけ。秘密鍵（`/etc/wireguard/wg0.key`）は拠点の外に出さない
   - 書けたら、保存して `vi` を閉じる

1. 両拠点の `~/wg/site.env` を、公開鍵を書いた同じ内容にそろえる。

   - **次の手順は、両拠点でそろえてから貼る**

1. 両拠点の WG ホストで、`apply` の実行予定の内容を見る。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env --dry-run apply A   # 拠点 B のホストでは B。秘密鍵は (hidden) と表示
   ```

   - **次の手順は、表示された内容でよいか確かめてから貼る**

1. 両拠点の WG ホストで、設定を適用する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env apply A             # 拠点 B のホストでは B
   ```

   - 末尾に、ルーターに入れる値（ポート転送と静的経路）が表示される（この項の手順 6）
   - 拠点の指定（`A` / `B`）はこのホストの LAN 側 IP（`WG_x_LAN_IP`）と照合され、違えば何も変更せずに止まる
   - **注意**: トンネル越しの ssh で作業していると、`apply` の restart で切れる（冒頭の警告）

1. 両拠点のルーターに、この項の手順 5 の `apply` の末尾に表示された値を入れる。

   - 入れるのは、ポート転送と静的経路
   - **次の手順は、両拠点のルーターに入れてから貼る**

### クライアントを登録する

1. 鍵をホストで作るときは、クライアントを受ける拠点のホストでクライアントを登録する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env client add A laptop
   ```

   - **鍵をどちらで作るかで、この項の手順 1・2 のどちらかを選ぶ**（両方を上から順に貼るものではない）
   - `laptop` / `phone` は自分の名前に、`A` は自分の拠点に読み替える（この項の手順 1〜7 と[状態と疎通を確かめる](#状態と疎通を確かめる)の手順 1）

1. 鍵をクライアント側で作ったときは（この項の手順 1 の代わりに）、公開鍵で登録する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env client add A phone --pubkey 'クライアントから受け取った公開鍵'
   ```

   - 公開鍵をシングルクォートの中に貼ってから実行する
   - AlmaLinux 10 の PC なら [road-warrior の「鍵を作る」の手順 3](wireguard-road-warrior.md#鍵を作る)と[「WG ホストに登録する」の手順 1〜3](wireguard-road-warrior.md#wg-ホストに登録する)

1. クライアントの台数分、この項の手順 1・2 のどちらかを繰り返したら、まとめて反映する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env apply A                  # 登録した [Peer] を wg0.conf に書いて restart
   ```

   - 同じクライアントを両拠点に登録することはできない（[理由](extra/wireguard.md#1-台のクライアントは-1-つの拠点にしか接続できない)）
   - **注意**: トンネル越しの ssh で作業していると、`apply` の restart で切れる（冒頭の警告）
   - **次の手順は、`apply` が終わってから貼る**

1. PC に渡すときは、クライアント用 conf を表示する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env client show laptop
   ```

   - 表示した内容を、この項の手順 6 で PC に取り込む

1. スマートフォンに渡すときは、クライアント用 conf を QR コードで表示する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env client show phone --qr   # qrencode が必要。EL10 では epel-release が要る場合がある
   ```

   - 表示した QR コードを、この項の手順 6 でスマートフォンに読み取らせる

1. クライアントで、この項の手順 4・5 の conf を取り込む。

   - PC は、この項の手順 4 の内容をコピーする。AlmaLinux 10 の PC で NetworkManager に取り込む手順は [wireguard-road-warrior.md](wireguard-road-warrior.md)
   - スマートフォンは、この項の手順 5 の QR コードを読み取る
   - この項の手順 2 の `--pubkey` で登録したときは、conf の `PrivateKey`（`<CLIENT_PRIVATE_KEY>`）を、端末側で自分の秘密鍵に置き換える
   - **次の手順は、クライアントに取り込んでから貼る**

1. 秘密鍵入りの conf をホストから消す。

   ```bash
   sudo rm /etc/wireguard/clients/laptop.conf
   ```

   - 取り込む前に conf を消すと再発行が必要になる（`client remove` してから登録し直す）

### 状態と疎通を確かめる

1. WG ホストで状態を見る。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env status
   ```

   - `status` には次が出る
     - `wg show`（`latest handshake` が 2 分以内）
     - `wg0` の経路、サービス、`ip_forward`
     - `wg0` が属するゾーンの内容（interfaces / ports / forward）
     - クライアントの最終ハンドシェイク

1. クライアントから、疎通を確かめる。

   - 拠点の LAN 上のクライアント同士は、Client A から次を試す（`<...>` は値に読み替える）
     - `ping <Client B の IP>`
     - `tracepath -n <Client B の IP>`
   - 外出先のクライアントからは、次を試す（同じく値に読み替える）
     - `ping <接続先拠点の LAN のホスト>`（例: `192.168.110.100`）
     - `ping <相手拠点の LAN のホスト>`（例: `192.168.120.100`）
     - `tracepath -n <相手拠点の LAN のホスト>`
   - **逆方向（Client B → Client A、拠点の LAN → クライアント）も必ず確認する**
   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [検証記録の症状と原因の対応](verification/wireguard.md#症状と原因の対応実測) を見る

---

## 回線に合わせて MTU を下げる（任意）

- 小さい通信は通るのに、大きい通信だけ遅い・止まるときに行う（ssh の画面の描き直し、ファイル転送、一部の HTTPS）
- この節の手順 1〜7 は両拠点の WG ホストで、手順 8 はクライアントで行う。`WG_MTU` は両拠点で同じ値にする
- **トンネル越しに ssh して作業している場合、この節の手順 6 の restart で自分のセッションが切れる**（→ [落とし穴](wireguard-road-warrior.md#落とし穴-apply-は作業中の-ssh-経路そのものを切る)）
- 配布済みのクライアントの MTU は、`apply` では変わらない（この節の手順 8 で入れる。→ [注意点の MTU](extra/wireguard.md#mtu)）
- → [補足](reference/wireguard.md#回線に合わせて-mtu-を下げる任意--手順-1-補足-wg_mtu-に書く値)

1. 両拠点の WG ホストで、回線の MTU と今の `wg0` の MTU を調べる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   tracepath -n -m 8 1.1.1.1 | grep -o 'pmtu [0-9]*' | tail -n 1
   ip -o link show dev wg0 | grep -o 'mtu [0-9]*'
   ```

   - `pmtu` の値を、両拠点の分とも控える
   - `WG_MTU` に書く値は、両拠点の `pmtu` の小さいほうから 60 を引いた値以下にする（1454 なら 1394 以下。例: `1380`）
   - `Endpoint` が IPv6 のアドレスのときは、60 ではなく 80 を引く
   - その値が今の `wg0` の `mtu` 以上なら、下げなくてよい（この節はここで終える）

1. `site.env` の `WG_MTU` に、この節の手順 1 で決めた値を書く。

   ```bash
   vi ~/wg/site.env                      # WG_MTU= の右に値を書く（例: WG_MTU=1380）
   ```

   - 書けたら、保存して `vi` を閉じる

1. 両拠点の `~/wg/site.env` を、`WG_MTU` を書いた同じ内容にそろえる。

   - **次の手順は、両拠点でそろえてから貼る**

1. トンネルを切らずに先に効かせるときだけ、両拠点の WG ホストで動いている `wg0` の MTU を下げる。

   ```bash
   . ~/wg/site.env
   if [ -z "${WG_MTU}" ]; then echo '中断: site.env の WG_MTU が空のまま' >&2; else
     sudo ip link set dev wg0 mtu "${WG_MTU}"
     printf '\n\033[7m 確認 \033[0m\n'
     ip -o link show dev wg0 | grep -o 'mtu [0-9]*'
   fi
   ```

   - `mtu` が `WG_MTU` の値になっていればよい
   - この節の手順 5・6 も、切れてよいときに必ず行う（行わないと、`wg-quick@wg0` の restart や OS の再起動で元の MTU に戻る）

1. 両拠点の WG ホストで、`apply` の実行予定の内容を見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   cd "${REPO:?「site.env を作る」の手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
   sudo ./wg-vpn.sh -e ~/wg/site.env --dry-run apply A   # 拠点 B のホストでは B。秘密鍵は (hidden) と表示
   ```

   - `[Interface]` に `MTU =` の行があり、値がこの節の手順 2 で書いたものになっている
   - **次の手順は、表示された内容でよいか確かめてから貼る**

1. 両拠点の WG ホストで、設定を適用する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env apply A             # 拠点 B のホストでは B
   ```

   - `wg-quick@wg0 を起動しました` と出ればよい
   - **注意**: トンネル越しの ssh で作業していると、`apply` の restart で切れる（冒頭の警告）

1. 両拠点の WG ホストで、`wg0` の MTU と、相手拠点への ping の損失を確かめる。

   ```bash
   . ~/wg/site.env
   printf '\n\033[7m 確認 \033[0m\n'
   ip -o link show dev wg0 | grep -o 'mtu [0-9]*'
   ping -c 100 -i 0.2 -q "$WG_B_TUN_IP"                                                        # 拠点 B のホストでは WG_A_TUN_IP
   ping -c 100 -i 0.2 -q -M do -s "$(( $(cat /sys/class/net/wg0/mtu) - 28 ))" "$WG_B_TUN_IP"   # 同上
   ```

   - `mtu` が `WG_MTU` の値になっている
   - 2 つの ping が、どちらも `0% packet loss`
   - 後ろの ping（`wg0` の MTU いっぱいの大きさ）だけ落ちるなら、`WG_MTU` をさらに下げて、この節の手順 2 からやり直す
   - `WG_IFACE` を変えている場合は、この節の `wg0` を読み替える

1. 配布済みのクライアントに、この節の手順 2 と同じ値の MTU を入れる。

   - この節の手順 2 より後に `client add` で登録したクライアントは、conf に同じ `MTU =` が入っているので、何もしなくてよい
   - AlmaLinux 10 の PC は、`sudo nmcli connection modify wg0 wireguard.mtu 1380` の後、`sudo nmcli connection down wg0` と `sudo nmcli connection up wg0`（`1380` は手順 2 の値に読み替える）
   - Windows 11 の PC は、トンネルを切ってから、WireGuard の窓の「編集」で `[Interface]` に `MTU = 1380` を足す（同じく読み替える）
   - スマートフォンは、公式アプリのトンネルの編集で、インターフェースの MTU に同じ値を入れる
   - PC の注意は、[road-warrior の注意点](extra/wireguard-road-warrior.md#注意点)の「MTU」

---

## クライアントを削除する

- クライアントを受ける拠点のホストで行う。登録簿から消しただけでは、動いているトンネルの接続許可は残る
- 鍵の交換や PC のロールバックでも、この節を使う
- `WG_USE_EXISTING_CONF=0`（既定）の、登録簿から conf を生成する構成が対象。`1` のままでは `apply` が peer を書き換えないので、この節では削除できない
- **トンネル越しに ssh して作業している場合、この節の手順 5 の restart で自分のセッションが切れる**（→ [落とし穴](wireguard-road-warrior.md#落とし穴-apply-は作業中の-ssh-経路そのものを切る)）

1. 変数を設定する（`CLIENT_NAME` と `SITE` は削除する登録に合わせる）。

   ```bash
   CLIENT_NAME=laptop                  # 消すクライアントの名前。鍵交換なら交換前の登録名
   ```

   ```bash
   SITE=A                              # このクライアントを受ける拠点（A または B）
   ```

   ```bash
   REPO=~/setup-notes                   # WG ホスト上の clone 先
   ```

   - Road Warrior 手順書から来た場合は、そこで設定した `CLIENT_NAME`・`SITE`・`REPO` と同じ値にする

1. 登録簿を表示し、削除対象の名前・拠点・IP・公開鍵を控える。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   cd "${REPO:?この節の手順 1 の REPO が空のまま}/scripts/wireguard" &&
   ./wg-vpn.sh -e ~/wg/site.env client list
   ```

   - `CLIENT_NAME` の行の `SITE` がこの節の手順 1 と一致することを確かめる
   - 公開鍵は、この節の手順 3 に出る未知 peer と照合するため、行全体を手元に控える
   - 対象の行が無い、拠点が違う、別端末の登録だった場合は、ここで止める

1. 登録を消し、通常の dry-run で既存 conf に残る公開鍵を確認する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${CLIENT_NAME}" ] || [ -z "${SITE}" ]; then echo '中断: この節の手順 1 を貼り直す' >&2; else
     sudo ./wg-vpn.sh -e ~/wg/site.env client remove "${CLIENT_NAME}" &&
     sudo ./wg-vpn.sh -e ~/wg/site.env --dry-run apply "${SITE}"
   fi
   ```

   - 反映済みの登録なら、`登録簿に無い [Peer]` のエラーと、既存 conf の行番号・公開鍵が出て止まる。これは削除を確認するための停止
   - **表示された未知 peer が、この節の手順 2 で控えた公開鍵だけであることを確認する**。まだ反映していない登録なら、未知 peer は出ない
   - 未知 peer 以外のエラーが出た場合も、原因を直して通常の dry-run が検査を通るまで進まない
   - ほかの公開鍵も出たら、この節の手順 4・5 へ進まない。残す peer を、表示された案内に従って `client add --pubkey … --ip …` で登録簿へ取り込み、通常の dry-run をやり直す
   - **次の手順は、未知 peer が削除対象だけ、または未知 peer が無いことを確かめてから貼る**

1. 未知 peer の確認が済んだ場合だけ、削除を許可した dry-run の全変更を確認する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env --drop-unknown-peers --dry-run apply "${SITE:?この節の手順 1 の SITE が空のまま}"
   ```

   - `--drop-unknown-peers` は、登録簿に無い peer をすべて消す指定。削除対象以外の公開鍵が警告に出たら、本実行しない
   - **次の手順は、表示された公開鍵と変更内容でよいか確かめてから貼る**

1. 確認した削除をホストへ反映する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env --drop-unknown-peers apply "${SITE:?この節の手順 1 の SITE が空のまま}"
   ```

   - この節の手順 4 の後に登録簿や conf を変更した場合は、この節の手順 3 の `--dry-run apply` の行だけを実行して確認し直す（`client remove` は済んでいるので繰り返さない）
   - `wg-quick@wg0 を起動しました` と出れば反映が終わった

1. 登録簿と動作中の peer から、削除対象の公開鍵が消えたことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   ./wg-vpn.sh -e ~/wg/site.env client list &&
   sudo wg show wg0 peers
   ```

   - この節の手順 2 で控えた名前が登録簿に無く、公開鍵が `wg show` に無ければよい（`WG_IFACE` を変えている場合は `wg0` も読み替える）
   - ルーターのクライアント帯の静的経路は残す

---

## バックアップと復旧（OS の再インストール）

- OS を入れ直しても、**ホストの秘密鍵とネットワークの値が同じなら**、相手拠点の `site.env` も、配布済みのクライアントの conf も、ルーターの設定も**そのまま使える**
- 逆に鍵を作り直すと、相手拠点の公開鍵の差し替えと、クライアント全台の conf 再発行が連鎖する
- → [バックアップと復旧の補足](reference/wireguard.md#バックアップと復旧の補足)

1. 両拠点でそれぞれ、バックアップを取る。

   ```bash
   cd "${REPO:?「site.env を作る」の手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
   sudo ./wg-vpn.sh -e ~/wg/site.env --dry-run backup &&       # まとめる内容を表示するだけ
   sudo ./wg-vpn.sh -e ~/wg/site.env backup                    # ~/wg-backup-<ホスト名>-<日時>.tar.gz（0600）
   ```

   - 読むだけなので、トンネルを止めずに稼働中のホストで実行できる
   - 出力先を変えるときは、`backup` の前に `-o /mnt/usb/wgb.tar.gz` のように付ける

1. この節の手順 1 のアーカイブを、このマシンの外（別のディスク、オフラインのメディア）に保管する。

   - **このアーカイブには秘密鍵が入っている。** `0600` のまま、リポジトリの中には置かない

1. クリーンインストール後のホストで、戻す内容を見る（`BACKUP` は必ず値を入れる）。

   ```bash
   BACKUP=                              # ← 復旧に使うアーカイブ（例: ~/wg-backup-<ホスト名>-<日時>.tar.gz）
   ```

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   cd "${REPO:?「site.env を作る」の手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
   sudo ./wg-vpn.sh --dry-run restore "${BACKUP:?復旧するアーカイブを BACKUP に入れてから貼る}"
   ```

   - `keygen` は実行しない。別の鍵ができ、復旧の意味が無くなる
   - `BACKUP` が空のまま貼ると、`${BACKUP:?…}` で中断し、何も戻さない
   - **次の手順は、表示された内容でよいか確かめてから貼る**

1. 鍵・conf・`site.env`・`clients.list` を戻す。

   ```bash
   sudo ./wg-vpn.sh restore "${BACKUP:?この節の手順 3 の BACKUP が空のまま}"
   ```

   - WG ホストの LAN 側 IP が変わっていなければ、この節の手順 5・6・9 は飛ばす

1. WG ホストの LAN 側 IP が変わったときだけ、`site.env` を直す。

   ```bash
   vi ~/wg/site.env
   ```

   - このホストに対応する `WG_A_LAN_IP` または `WG_B_LAN_IP` を、実際に割り当てた固定 IP に直す
   - `LAN_ZONE` を明示していて NIC のゾーンが変わった場合も見直す
   - **次の手順は、保存してエディタを閉じてから行う**（続けて貼るとエディタへの入力になる）

1. WG ホストの LAN 側 IP が変わったときだけ、更新した `site.env` を相手拠点にも置く。

   - この節の手順 5 で更新したファイルと同じ内容にそろえる。相手拠点の公開鍵は変えない
   - **次の手順は、両拠点に同じ設定を置いてから貼る**

1. 復旧先のホストで、適用する内容を確認する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env --dry-run apply B          # このホストの拠点に読み替える（例は拠点 B）
   ```

   - ホストの LAN 側 IP の検査が通り、戻した鍵と登録簿を使うことを確かめる
   - **次の手順は、表示された内容でよいか確かめてから貼る**

1. 復旧先のホストで、設定を適用する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env apply B                   # このホストの拠点に読み替える（例は拠点 B）
   ```

   - `wg-quick@wg0 を起動しました` と出ればよい

1. WG ホストの LAN 側 IP が変わったときだけ、その拠点のルーターの転送先を直す。

   - ポート転送の宛先と、相手 LAN・クライアント帯の静的経路のゲートウェイを新しい LAN 側 IP にする
   - 入れる値は、この節の手順 8 の `apply` の末尾に表示される（[補足: ルーターの設定](reference/wireguard.md#ルーターの設定)）
   - 相手拠点の WG ホストの LAN 側 IP が同じなら、相手拠点のルーターのゲートウェイは変更しない

---

## site.env に書く値

- 両拠点の値を同じ `site.env` に書き、両拠点のホストへ同じファイルを置く
- 各帯は互いに重ならないように設定する

| 変数 | 意味 |
|---|---|
| `${SITE_A_LAN}` / `${SITE_B_LAN}` | 各拠点の LAN サブネット（**重複不可**） |
| `${ROUTER_A_LAN_IP}` / `${ROUTER_B_LAN_IP}` | 各拠点ルーターの LAN 側 IP |
| `${WG_A_LAN_IP}` / `${WG_B_LAN_IP}` | 各 WireGuard ホストの LAN 側 IP（**固定にする**） |
| `${SITE_A_PUBLIC}` / `${SITE_B_PUBLIC}` | 各拠点ルーターのグローバル IP または DDNS 名 |
| `${WG_TUNNEL_NET}` | トンネル内のアドレス帯 |
| `${WG_A_TUN_IP}` / `${WG_B_TUN_IP}` | 各 wg0 のアドレス |
| `${WG_PORT}` | WireGuard の待ち受け UDP ポート |
| `${LAN_ZONE}` | WG ホストの LAN 側 NIC が属する firewalld ゾーン。**`wg0` もここに入れる**（空なら自動で検出する） |
| `${SITE_A_PUBKEY}` / `${SITE_B_PUBKEY}` | 各拠点の WireGuard 公開鍵 |
| `${WG_IFACE}` / `${WG_FW_ZONE}` | インターフェース名 / 旧レイアウトで `wg0` を入れていた専用ゾーン名（残っていれば `apply` / `remove` が消す。[移行](reference/wireguard.md#旧レイアウト専用ゾーン--policyからの移行)） |
| `${WG_A_CLIENT_NET}` / `${WG_B_CLIENT_NET}` | 各拠点に接続するクライアントに割り当てるトンネル内のアドレス帯（**LAN・`${WG_TUNNEL_NET}`・互いに重複不可**、`/30` またはそれより広く。クライアントを受けない拠点は空） |
| `${WG_CLIENT_DNS}` | クライアント用 conf に書く DNS サーバー（任意） |
| `${WG_MTU}` | `wg0` の MTU（任意。空なら wg-quick が決める。書く値は[回線に合わせて MTU を下げる](#回線に合わせて-mtu-を下げる任意)の手順 1）。値があれば、`client add` が作るクライアント用 conf にも同じ `MTU =` を書く |
