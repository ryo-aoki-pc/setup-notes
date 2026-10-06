# WireGuard VPN 構築手順（site-to-site + road warrior / wg-quick + firewalld）

## 実施手順

- [検証記録](verification/wireguard.md)・[参考資料](reference/wireguard.md)

> [!IMPORTANT]
> - **手順 1〜8 は両拠点の WG ホストで、手順 9 は両拠点のルーターで行う**
> - **手順 10〜17 はクライアントを受ける拠点のホストで行う**。手順 15 と手順 18 は、クライアントで行う
> - コマンドはすべて `${REPO}/scripts/wireguard`（`REPO` は手順 1 で設定する clone 先）で実行し、`-e ~/wg/site.env` で値を渡す
> - **拠点 B のホストでは、引数の `A` を `B` に読み替える**
> - **手順 2 と手順 5 で `vi` が開く**。保存して閉じてから次の手順を行う
> - **OS を入れ直して同じ鍵で戻したい場合は、先に[バックアップと復旧](#バックアップと復旧os-の再インストール)を読む**。鍵さえ残っていれば、相手拠点の設定も配布済みのクライアント conf も変えずに復旧できる

- 手順 1 で `REPO` を設定したシェルで実行する。新しいシェルを開いたら設定し直す
- 手順の後: クライアントを消すなら[クライアントを削除する](#クライアントを削除する)、OS の入れ直しに備えるなら[バックアップと復旧](#バックアップと復旧os-の再インストール)、やめるなら[全部消す（ロールバック）](#全部消すロールバック)

> [!WARNING]
> **トンネル越しに ssh して作業している場合、`apply` の restart で自分のセッションが切れる。**
>
> - 該当するのは、手順 8・12 と[クライアントを削除する](#クライアントを削除する)の `apply`
> - 切り離して実行する方法は、[wireguard-road-warrior.md の落とし穴](wireguard-road-warrior.md#落とし穴-apply-は作業中の-ssh-経路そのものを切る)にある

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
   vi ~/wg/site.env                      # 公開鍵は手順 5 で書き足す
   ```

   - **編集するのは `~/wg/site.env` だけ。** 埋める値は[設定値の表](#siteenv-に書く値)にある（クライアント帯は、クライアントを受ける拠点にだけ書く）
   - 書けたら、保存して `vi` を閉じる

1. 書いた `site.env` を、両拠点の WG ホストの `~/wg/site.env` に同じ内容で置く。

   - **次の手順は、両拠点に置いてから貼る**

1. 両拠点の WG ホストで、`wireguard-tools` を入れて鍵ペアを作る。

   ```bash
   cd "${REPO:?手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
   sudo ./wg-vpn.sh -e ~/wg/site.env keygen A        # 拠点 B のホストでは B
   ```

   - 既存の鍵があれば上書きしない
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

   - 末尾に、ルーターに入れる値（ポート転送と静的経路）が表示される（手順 9）
   - 拠点の指定（`A` / `B`）はこのホストの LAN 側 IP（`WG_x_LAN_IP`）と照合され、違えば何も変更せずに止まる
   - 再実行しても設定は重複しない。`site.env` を変えたときやクライアントを足したときも、この `apply` で反映する（最後に必ず restart する）
   - 拠点間の疎通は、手順 9 の後で確認できる（手順 17・18 の疎通確認）
   - **注意**: トンネル越しの ssh で作業していると、`apply` の restart で切れる（冒頭の警告）

1. 両拠点のルーターに、手順 8 の `apply` の末尾に表示された値を入れる。

   - 入れるのは、ポート転送と静的経路
   - **これが無いとトンネルは張れない**（→ [補足: ルーターの設定](reference/wireguard.md#ルーターの設定)）
   - **次の手順は、両拠点のルーターに入れてから貼る**

1. 鍵をホストで作るときは、クライアントを受ける拠点のホストでクライアントを登録する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env client add A laptop
   ```

   - **鍵をどちらで作るかで、手順 10 か手順 11 のどちらかを選ぶ**（両方を上から順に貼るものではない）
   - `laptop` / `phone` は自分の名前に、`A` は自分の拠点に読み替える（手順 10〜17）

1. 鍵をクライアント側で作ったときは（手順 10 の代わりに）、公開鍵で登録する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env client add A phone --pubkey 'クライアントから受け取った公開鍵'
   ```

   - 公開鍵をシングルクォートの中に貼ってから実行する
   - AlmaLinux 10 の PC なら [road-warrior の手順 3〜6](wireguard-road-warrior.md#実施手順)
   - `--pubkey` で登録した conf の `PrivateKey` は `<CLIENT_PRIVATE_KEY>` のまま（手順 15 で置き換える）

1. クライアントの台数分、手順 10 か手順 11 を繰り返したら、まとめて反映する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env apply A                  # 登録した [Peer] を wg0.conf に書いて restart
   ```

   - **反映は `apply`（restart）で行う。** `reload` では新しい peer の経路が入らない（[落とし穴 2](#落とし穴-2-reload-では経路が追加されない)）
   - どちらか片方の拠点で登録すれば、そのクライアントは**両拠点の LAN に届く**（[パケットの流れ](reference/wireguard.md#パケットの流れremote-client--各拠点)）
     - 前提: 両拠点で `apply` 済みで、両拠点のルーターにクライアント帯の静的経路がある
   - 同じクライアントを両拠点に登録することはできない（[理由](#1-台のクライアントは-1-つの拠点にしか接続できない)）
   - **注意**: トンネル越しの ssh で作業していると、`apply` の restart で切れる（冒頭の警告）
   - **次の手順は、`apply` が終わってから貼る**

1. PC に渡すときは、クライアント用 conf を表示する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env client show laptop
   ```

   - 表示した内容を、手順 15 で PC に取り込む

1. スマートフォンに渡すときは、クライアント用 conf を QR コードで表示する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env client show phone --qr   # qrencode が必要。EL10 では epel-release が要る場合がある
   ```

   - 表示した QR コードを、手順 15 でスマートフォンに読み取らせる

1. クライアントで、手順 13・14 の conf を取り込む。

   - PC は、手順 13 の内容をコピーする。AlmaLinux 10 の PC で NetworkManager に取り込む手順は [wireguard-road-warrior.md](wireguard-road-warrior.md)
   - スマートフォンは、手順 14 の QR コードを読み取る
   - 手順 11 の `--pubkey` で登録したときは、conf の `PrivateKey`（`<CLIENT_PRIVATE_KEY>`）を、端末側で自分の秘密鍵に置き換える
   - **次の手順は、クライアントに取り込んでから貼る**

1. 秘密鍵入りの conf をホストから消す。

   ```bash
   sudo rm /etc/wireguard/clients/laptop.conf
   ```

   - 取り込む前に conf を消すと再発行が必要になる（`client remove` してから登録し直す）

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
   cd "${REPO:?この節の手順 1 の REPO が空のまま}/scripts/wireguard" &&
   ./wg-vpn.sh -e ~/wg/site.env client list
   ```

   - `CLIENT_NAME` の行の `SITE` がこの節の手順 1 と一致することを確かめる
   - 公開鍵は、この節の手順 3 に出る未知 peer と照合するため、行全体を手元に控える
   - 対象の行が無い、拠点が違う、別端末の登録だった場合は、ここで止める

1. 登録を消し、通常の dry-run で既存 conf に残る公開鍵を確認する。

   ```bash
   if [ -z "${CLIENT_NAME}" ] || [ -z "${SITE}" ]; then echo '中断: この節の手順 1 を貼り直す' >&2; else
     sudo ./wg-vpn.sh -e ~/wg/site.env client remove "${CLIENT_NAME}" &&
     sudo ./wg-vpn.sh -e ~/wg/site.env --dry-run apply "${SITE}"
   fi
   ```

   - `client remove` は登録簿と配布用 conf を消す。ホストの conf と動作中の peer は、まだ変わらない
   - 反映済みの登録なら、`登録簿に無い [Peer]` のエラーと、既存 conf の行番号・公開鍵が出て止まる。これは削除を確認するための停止
   - **表示された未知 peer が、この節の手順 2 で控えた公開鍵だけであることを確認する**。まだ反映していない登録なら、未知 peer は出ない
   - 未知 peer 以外のエラーが出た場合も、原因を直して通常の dry-run が検査を通るまで進まない
   - ほかの公開鍵も出たら、手順 4・5 へ進まない。残す peer を、表示された案内に従って `client add --pubkey … --ip …` で登録簿へ取り込み、通常の dry-run をやり直す
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

   - この節の手順 4 の後に登録簿や conf を変更した場合は、手順 3 の `--dry-run apply` の行だけを実行して確認し直す（`client remove` は済んでいるので繰り返さない）
   - `wg-quick@wg0 を起動しました` と出れば反映が終わった

1. 登録簿と動作中の peer から、削除対象の公開鍵が消えたことを確かめる。

   ```bash
   ./wg-vpn.sh -e ~/wg/site.env client list &&
   sudo wg show wg0 peers
   ```

   - この節の手順 2 で控えた名前が登録簿に無く、公開鍵が `wg show` に無ければよい（`WG_IFACE` を変えている場合は `wg0` も読み替える）
   - ルーターのクライアント帯の静的経路は、ほかのクライアントも使うので残す

---

## バックアップと復旧（OS の再インストール）

- OS を入れ直しても、**ホストの秘密鍵とネットワークの値が同じなら**、相手拠点の `site.env` も、配布済みのクライアントの conf も、ルーターの設定も**そのまま使える**
- 逆に鍵を作り直すと、相手拠点の公開鍵の差し替えと、クライアント全台の conf 再発行が連鎖する
- → [バックアップと復旧の補足](reference/wireguard.md#バックアップと復旧の補足)

1. 両拠点でそれぞれ、バックアップを取る。

   ```bash
   cd "${REPO:?手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
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
   cd "${REPO:?手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
   sudo ./wg-vpn.sh --dry-run restore "${BACKUP:?復旧するアーカイブを BACKUP に入れてから貼る}"
   ```

   - `keygen` は実行しない。別の鍵ができ、復旧の意味が無くなる
   - `BACKUP` が空のまま貼ると、`${BACKUP:?…}` で中断し、何も戻さない
   - **次の手順は、表示された内容でよいか確かめてから貼る**

1. 鍵・conf・`site.env`・`clients.list` を戻す。

   ```bash
   sudo ./wg-vpn.sh restore "${BACKUP:?この節の手順 3 の BACKUP が空のまま}"
   ```

   - `restore` は必要なら wireguard-tools を導入し、鍵と `site.env` の公開鍵の一致を検査してからファイルを戻す。サービスは起動しない
   - ホストの鍵が同じなら、クライアント conf の公開鍵を変更する必要は無い
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

## 全部消す（ロールバック）

- 各拠点の WG ホストで、**必要なところまで**貼る（後の手順ほど戻しにくい）
- ルーター側の設定は、この節の手順 5 で消す
- → [全部消すときの補足](reference/wireguard.md#全部消すときの補足)

> [!CAUTION]
> **鍵を消す前に。** 同じ鍵で戻す可能性が少しでもあるなら、先に[バックアップ](#バックアップと復旧os-の再インストール)を取る。**この節の手順 2 で鍵が消え、そこから先は戻せない。** 鍵を作り直すと、相手拠点の `site.env` と conf の公開鍵の差し替え、クライアント全台の conf 再発行が連鎖する。

1. サービスを止めて、firewalld と sysctl を戻す。

   ```bash
   cd "${REPO:?手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
   sudo ./wg-vpn.sh -e ~/wg/site.env remove A            # 拠点 B のホストでは B
   ```

   - conf・鍵・クライアント用 conf は残るので、この手順までなら `apply` でやり直せる

1. 鍵も消すときだけ、conf・鍵・クライアント用 conf を消す（取り戻せない）。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env remove A --purge    # conf・鍵・クライアント用 conf も消す（clients.list は残る）
   ```

1. `site.env` と `clients.list` も要らないときだけ、`~/wg` を消す。

   ```bash
   rm -rf ~/wg
   ```

1. パッケージも要らないときだけ、`wireguard-tools` と `systemd-resolved` を消す。

   ```bash
   sudo dnf remove wireguard-tools systemd-resolved
   ```

1. 両拠点のルーターから、ポート転送と静的経路を消す。

   - 消す値は、[手順 8](#実施手順) の `apply` の末尾に表示されたもの（[補足: ルーターの設定](reference/wireguard.md#ルーターの設定)）

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

それでも WG ホストで絞りたい場合は、LAN 側ゾーンに rich rule を足す（例: 拠点 B のクライアント帯から拠点 A の LAN への転送を拒否する）。実行範囲は[検証記録](verification/wireguard.md)を参照する

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

この対応表は **1 インターフェース内で peer ごとに排他**で、1 つのアドレスを 2 つの peer に対応づけることはできない。だからクライアントは拠点に所属させ、拠点ごとに帯を分ける（[選択した方針](verification/wireguard.md#選択した方針)）。

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
- 相手ルーターに `${WG_TUNNEL_NET}` via `${WG_x_LAN_IP}` の静的経路を追加する（[ルーターの設定](reference/wireguard.md#ルーターの設定)のとおり、トンネル網とクライアント帯を 1 つの大きな帯に取っておけば静的経路 1 本で済む）

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

ホスト側で鍵を作ると、秘密鍵入りの conf が一時的にホストに残る。**クライアントに取り込んだら消す**（手順 16 の `rm`）。

- より厳密にするなら、クライアント側で鍵を作って公開鍵だけをホストに渡す
- AlmaLinux 10 の PC でその流れにするなら、[Road Warrior 手順書](wireguard-road-warrior.md)の手順 3〜6

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
