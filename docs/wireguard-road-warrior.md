# WireGuard Road Warrior 設定手順（AlmaLinux 10 は NetworkManager + nmcli / Windows 11 は公式の WireGuard for Windows）

## 実施手順

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 の PC のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（管理者の Windows PowerShell 5.1 に貼る。WG ホストでは、この実施手順の手順 4〜6・13 を使う）
> - **PC で実行する**。手順 4〜6 と手順 13 だけ WG ホストで実行する
> - **`sudo -i` した root のシェルではなく、自分のシェルで貼る**。`~` が自分のホームになるため
> - **手順 7 で `vi` が開く**。`client show` の出力を貼って保存し、閉じてから次の手順を貼る
> - **手順 9 で、PC を拠点の LAN の外のネットワークにつなぐ**（スマートフォンのテザリングなど）。手順 10 以降は LAN の外で行う

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 戻すときは[ロールバック](#ロールバック)

1. 変数を設定する（4 つの IP は必ず値を入れる）。

   ```bash
   WG_HOST_TUN_IP=10.99.0.1             # 接続先拠点の WG ホストの wg0 アドレス（site.env の WG_A_TUN_IP）。<WG_HOST_TUN_IP>
   ```

   ```bash
   WG_HOST_LAN_IP=192.168.110.2         # 同じホストの LAN 側 IP（WG_A_LAN_IP）。<WG_HOST_LAN_IP>
   ```

   ```bash
   ROUTER_LAN_IP=192.168.110.1          # 接続先拠点のルーターの LAN 側 IP（ROUTER_A_LAN_IP）。<ROUTER_LAN_IP>
   ```

   ```bash
   PEER_WG_LAN_IP=192.168.120.2         # 相手拠点の WG ホストの LAN 側 IP（WG_B_LAN_IP）。<PEER_WG_LAN_IP>
   ```

   ```bash
   WG_DIR=~/wg-client                   # 鍵と conf の一時置き場（手順 15 で秘密鍵と conf を消す）
   for v in WG_HOST_TUN_IP WG_HOST_LAN_IP ROUTER_LAN_IP PEER_WG_LAN_IP WG_DIR; do
     printf '%-15s = %s\n' "$v" "${!v}"
   done
   ```

   - 編集が必須なのは、1 行ずつの 4 ブロック
   - 鍵と conf の一時置き場（`WG_DIR`）は既定のままでよい
   - 最後に値を読み戻して確かめる
   - 例の値は拠点 A がクライアントを受ける構成のもの。拠点 B が受ける構成なら、`site.env` の `*_B_*` 側の値が入っていること
   - **既定値のままでもエラーにならない**ので、4 つの IP を書き換えたか必ずここで確かめる
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**（SSH を張り直したあとも）、手順 1 の 5 つのブロックを貼り直してから先へ進む

   <details>
   <summary>補足: 変数について</summary>

   - 変数名は PC 視点（`WG_HOST_*` = 接続先拠点、`PEER_*` = 相手拠点）
   - 拠点 B がクライアントを受ける構成なら、`site.env` の `WG_B_TUN_IP` / `WG_B_LAN_IP` / `ROUTER_B_LAN_IP` と `WG_A_LAN_IP` を入れる
   - `WG_DIR` を WG ホストの `~/wg`（`site.env` と `clients.list` の置き場）と別の名前にしてあるのは、同じ人が両方のマシンを触るときに、ロールバックの `rm` を取り違えても登録簿が消えないようにするため

   </details>

1. `wireguard-tools` を入れる。

   ```bash
   {
     sudo dnf install -y wireguard-tools
     rpm -q wireguard-tools NetworkManager systemd-resolved
     systemctl is-enabled systemd-resolved         # disabled（依存で入るだけ。本手順では有効にしない）
     modinfo -n wireguard                          # カーネル同梱のモジュールのパスが出る
   }
   ```

   <details>
   <summary>補足: パッケージ</summary>

   - `wireguard-tools` は `wg` / `wg-quick` と、依存の `systemd-resolved` を入れる
   - `systemd-resolved` は有効にしない。有効にすると NetworkManager の DNS 処理が resolved 経由に切り替わる（`DNS =` を使わない本手順では不要）
   - `modinfo -n` はモジュールの存在確認だけで、ロードは `nmcli connection up` の時点で NetworkManager が行う

   </details>

1. 鍵ペアを作る。

   ```bash
   if [ -e "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.key" ]; then echo '中断: wg0.key が既にある（作り直すなら先に消す。WG ホストに登録済みの公開鍵と対応しなくなる）' >&2; else
     mkdir -p "${WG_DIR}" && chmod 700 "${WG_DIR}" &&
     ( umask 077; wg genkey | tee "${WG_DIR}/wg0.key" | wg pubkey > "${WG_DIR}/wg0.pub" ) &&
     ls -l "${WG_DIR}/wg0.key" "${WG_DIR}/wg0.pub" &&           # どちらも -rw------- で 45 バイト
     cat "${WG_DIR}/wg0.pub"                                     # この 1 行（公開鍵）を WG ホストへ渡す。秘密鍵（.key）は渡さない
   fi
   ```

   - 秘密鍵は `wg0.key` に書き、端末には表示しない
   - 表示された公開鍵（44 文字）だけを、手順 4 で WG ホストに渡す

   <details>
   <summary>補足: 鍵ペア</summary>

   - `umask 077` で `wg0.key` / `wg0.pub` を 0600 にする
   - `tee` で秘密鍵をファイルに落としつつ `wg pubkey` に流すので、秘密鍵は端末に出ない
   - `wg genkey` / `wg pubkey` はカーネルモジュール無しで動く
   - 既に `wg0.key` があるときに中断するのは、上書きするとホストに登録済みの公開鍵と対応しなくなるため

   </details>

1. WG ホストで変数を設定し、登録済みのクライアントを確かめる（`REPO` 以外は必ず値を入れる）。

   ```bash
   SITE=A                               # クライアントを受ける拠点（A または B）
   ```

   ```bash
   CLIENT_NAME=laptop                   # 登録簿（clients.list）に載せる名前。英数字・-・_ のみ
   ```

   ```bash
   CLIENT_PUBKEY=                       # 手順 3 で PC に表示された公開鍵（44 文字）を貼る
   ```

   ```bash
   REPO=~/setup-notes                   # WG ホスト上でこのリポジトリを clone した場所（wireguard.md の手順 1 と同じ）
   cd "${REPO:?REPO が空のまま}/scripts/wireguard" && ./wg-vpn.sh -e ~/wg/site.env client list
   ```

   - 手順 4〜6 は WG ホストのシェルで実行する。PC とは別のシェルなので、この手順で変数を設定し直す
   - 編集が必須なのは、1 行ずつの 3 ブロック
   - `REPO` は、clone 先が `~/setup-notes` なら既定のままでよい
   - [wireguard.md の手順 1・2](wireguard.md#実施手順) の `REPO` と `~/wg/site.env` がある前提
   - 最後に、登録済みのクライアントを一覧で確認する
   - 登録簿は名前で一意。`CLIENT_NAME` と同じ名前が一覧に無ければ、手順 5 は飛ばす

1. `CLIENT_NAME` と同じ名前が一覧にあるときだけ、WG ホストで旧登録を消して反映する。

   - [wireguard.md のクライアントを削除する](wireguard.md#クライアントを削除する)の手順 1〜6 を行う。`CLIENT_NAME`・`SITE`・`REPO` は手順 4 と同じ値にする
   - 削除前の公開鍵を控え、未知 peer がその鍵だけであることを確かめてから、削除を明示的に許可する。無関係の peer が出たら止める
   - 削除が反映されると、その旧鍵では接続できなくなる。トンネル越しの ssh で作業していた場合は、別の経路から WG ホストに入り直す
   - 次の手順の `CLIENT_PUBKEY` は、手順 3 で PC に作った新しい鍵の公開鍵のままにする。WG ホストのシェルを開き直したら手順 4 の変数を設定し直す

1. WG ホストで公開鍵を登録し、ホストに反映して、クライアント用 conf を表示する。

   ```bash
   if [ -z "${CLIENT_PUBKEY}" ]; then echo '中断: CLIENT_PUBKEY が空のまま。手順 3 の公開鍵を入れて貼り直す' >&2; else
     cd "${REPO:?REPO が空のまま}/scripts/wireguard" &&
     sudo ./wg-vpn.sh -e ~/wg/site.env client add "${SITE:?SITE が空のまま}" "${CLIENT_NAME:?CLIENT_NAME が空のまま}" --pubkey "${CLIENT_PUBKEY}" &&
     sudo ./wg-vpn.sh -e ~/wg/site.env apply "${SITE}" &&
     sudo ./wg-vpn.sh -e ~/wg/site.env client show "${CLIENT_NAME}"      # この出力を PC へ持っていく（秘密鍵は含まれない）
   fi
   ```

   - **注意**: トンネル越しに WG ホストへ ssh して作業している場合、`apply` の restart で自分のセッションが切れる（→ [落とし穴](#落とし穴-apply-は作業中の-ssh-経路そのものを切る)。切り離して実行する方法もそこにある）
   - `client show` の出力を、端末からコピーして PC に持っていく
   - `PrivateKey` はプレースホルダのままなので、**秘密情報を含まない**

   <details>
   <summary>補足: WG ホストでの登録</summary>

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
   - `apply` は `wg0.conf` を作り直して `systemctl restart` するので、他のクライアントと拠点間トンネルが数秒切れる（`reload` では経路が入らない。→ [落とし穴 2](wireguard.md#落とし穴-2-reload-では経路が追加されない)）
   - `apply` の末尾に出るルーターの設定（クライアント帯の静的経路）は、既に入っていれば変更不要
   - トンネル IP は帯の中で最小の空きが割り当たる（`--ip` で指定できる）

   </details>

1. PC で、手順 6 の `client show` の出力を `vi` に貼り、`wg0.conf` に保存する。

   ```bash
   ( umask 077; vi "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.conf" )    # 手順 6 の client show の出力をそのまま貼って保存する
   ```

   - `client show` の出力は、WG ホストの端末からコピーする
   - **ファイル名は `wg0.conf` にする。** NetworkManager がファイル名から接続名とインターフェース名を決める（実測で確認 → 手順 8 の補足）
   - ファイルで渡すなら、WG ホストで `client show` の出力をファイルに書き出し（秘密鍵は入っていないので平文でよい）、`scp` で `${WG_DIR}/wg0.conf` に置く
   - **次の手順は、保存して `vi` を閉じてから貼る**（続けて貼ると `vi` への入力として食われる）

1. `PrivateKey` 行だけを、手順 3 の秘密鍵に置き換える（鍵は表示しない）。

   ```bash
   if [ "$(grep -c '^PrivateKey *=' "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.conf" 2>/dev/null)" != 1 ] || [ ! -s "${WG_DIR}/wg0.key" ]; then
     echo '中断: wg0.conf の PrivateKey 行が 1 行ちょうどでないか、wg0.key が無い' >&2
   else
     sed -i "s|^PrivateKey *=.*|PrivateKey = $(cat "${WG_DIR}/wg0.key")|" "${WG_DIR}/wg0.conf" &&
     grep -c '^PrivateKey = [A-Za-z0-9+/]\{43\}=$' "${WG_DIR}/wg0.conf" &&    # 1（置き換わった。鍵そのものは表示しない）
     grep -v '^PrivateKey' "${WG_DIR}/wg0.conf"                                # 残りの行を目で確かめる（Address / PublicKey / Endpoint / AllowedIPs）
   fi
   ```

   <details>
   <summary>補足: conf と秘密鍵</summary>

   - `sed` の区切りを `|` にしているのは、base64 の鍵に `/` が含まれるため（`|` `&` `\` は base64 に含まれない）
   - `$(cat …)` の展開結果は端末に出ない。シェルの履歴には展開前の文字列が残るので、鍵は残らない
   - 2 つの `grep -c` は「置き換え前に `PrivateKey` 行がちょうど 1 行あること」と「置き換え後に 44 文字の鍵になったこと」の確認
   - `sed -i` は元ファイルのモード（`umask 077` の 0600）を引き継ぐ
   - ファイル名を `wg0.conf` にするのは、NetworkManager が `import` で接続名とインターフェース名をファイル名から決めるため（実測で `connection.id` / `connection.interface-name` とも `wg0` になった。有効なインターフェース名 + `.conf` でないと拒否されるかは未確認）

   </details>

1. PC を、拠点の LAN の外のネットワークにつなぐ（スマートフォンのテザリングなど）。

   - クライアント conf の `AllowedIPs` には両拠点の LAN が入るので、LAN 内で手順 10 を貼ると、そこで通信が切れる
   - **次の手順は、LAN の外につないでから貼る**

1. 拠点の LAN の外で、conf を NetworkManager に取り込み、自動で張られたトンネルをすぐ切る。

   ```bash
   {
     sudo nmcli connection import type wireguard file "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.conf" &&
     sudo nmcli connection modify wg0 connection.autoconnect no &&
     nmcli -f NAME,TYPE,DEVICE,STATE,AUTOCONNECT connection show | grep -E '^(NAME|wg0 )'    # STATE は activated（import 直後に張られる）。AUTOCONNECT は no
     nmcli -t -f NAME,STATE connection show | grep -qx 'wg0:activated' && sudo nmcli connection down wg0    # 張られていたら切る（手順 11 で改めて張る）
     nmcli -f connection.id,connection.interface-name,connection.autoconnect,connection.zone,ipv4.method,ipv4.addresses,ipv4.dns,ipv6.method,wireguard connection show wg0
     sudo ls -l /etc/NetworkManager/system-connections/wg0.nmconnection     # -rw------- root root。秘密鍵はこの中（表示はしない）
   }
   ```

   - `import` した直後に、NetworkManager が `wg0` を**自動で張る**（`connection.autoconnect` の既定が `yes` のため）。張られた時点で拠点 LAN 宛ての経路が入れ替わる
   - **注意**: LAN 内でこの手順を貼ってしまうと、そこで通信が切れて、その後の手順を貼れなくなる。その場合は PC のコンソールで `sudo nmcli connection down wg0`
   - 張られたトンネルは、取り込んだ直後に切る（手順 11 で改めて張る）
   - 最後に、プロファイルの内容と秘密鍵の保存先を確認する。見るところは次のとおり
     - `ipv4.method` が `manual`
     - `ipv4.addresses` が `<CLIENT_TUN_IP>/32`
     - `ipv4.dns` が `--`
     - `wireguard.private-key` が `<hidden>`
     - `wireguard.peer-routes` が `yes`
     - `wireguard.peers` に接続先拠点の公開鍵

   <details>
   <summary>補足: import</summary>

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

   </details>

1. 拠点の LAN の外で、トンネルを張る。

   ```bash
   {
     sudo nmcli connection up wg0 &&
     nmcli device status | grep -E '^(DEVICE|wg0 )' &&                            # wireguard  connected  wg0
     nmcli -f GENERAL.STATE,IP4.ADDRESS,IP4.ROUTE,IP4.DNS connection show wg0 &&   # activated。IP4.ROUTE に AllowedIPs の 3 経路（mt = 50）
     ip -4 route show dev wg0 &&                                                  # 同じ 3 経路と metric
     ip link show dev wg0 | grep -o 'mtu [0-9]*' &&                               # 1420
     sudo wg show wg0                                                             # latest handshake が数秒前、transfer の received が 0 でない
     sudo firewall-cmd --get-active-zones           # wg0 が既定ゾーン public に入る
     cat /etc/resolv.conf                           # 手順 2 の前と同じ（DNS = が無いので変わらない）
     sudo ausearch -m AVC -ts recent                # <no matches>
   }
   ```

   <details>
   <summary>補足: up</summary>

   - `GENERAL.STATE` / `IP4.ROUTE[n]: dst = …, nh = …, mt = …` の書式は、NetworkManager 1.56 で確認済み
   - `mt` の値（WireGuard デバイスの既定 metric）は **50**（実測。`ipv4.route-metric` は `-1` のままなので、これは WireGuard デバイスの既定）。Wi-Fi の 600 より優先される（→ [注意点](#注意点)）
   - `wireguard.peer-routes yes` が `AllowedIPs` の経路を入れる（`nm-settings-nmcli(5)`）。`ip4-auto-default-route` は `/0` の peer が無いので関係ない
   - MTU は `wireguard.mtu 0` のときカーネル既定の 1420 になる（実測）。`wg-quick` と違い NetworkManager は経路から MTU を計算しない
   - `wg show` の `listening port` はランダム（`wireguard.listen-port 0`）。`latest handshake` が出ない場合は、鍵の対応（ホストの `clients.list` と `wg0.pub`）、`Endpoint`、ルーターのポート転送を疑う

   </details>

1. PC で、トンネル IP → WG ホストの LAN 側 → ルーター → 相手拠点の順に疎通を試す。

   ```bash
   for h in "${WG_HOST_TUN_IP:?手順 1 の変数が空のまま}" "${WG_HOST_LAN_IP:?}" "${ROUTER_LAN_IP:?}" "${PEER_WG_LAN_IP:?}"; do
     echo "== $h"; ping -c 3 -W 2 "$h" | tail -2
   done
   tracepath -n "${PEER_WG_LAN_IP:?}"             # <WG_HOST_TUN_IP> → <PEER_WG_LAN_IP> の順に出る
   ```

   - 相手拠点の LAN 上の別のホストへの `ping`、トンネル越しの `ssh <ユーザー>@<WG_HOST_LAN_IP>` も試しておくとよい
   - どこで止まるかで、疑う場所が変わる（→ この手順の補足）

   <details>
   <summary>補足: 疎通確認</summary>

   4 段階の意味:

   - (1) `<WG_HOST_TUN_IP>` はトンネルそのもの（届かなければハンドシェイクか `AllowedIPs`）
   - (2) `<WG_HOST_LAN_IP>` は WG ホスト自身の LAN 側（届かなければ `AllowedIPs` に拠点 LAN が無い）
   - (3) ルーターは `wg0 → LAN` の転送と、ルーターのクライアント帯の静的経路
   - (4) 相手拠点の WG ホストは、拠点間トンネルと相手ホストの `AllowedIPs`（クライアント帯）

   → [wireguard.md: 手順 18 の補足](wireguard.md#実施手順)、[症状と原因の対応](wireguard.md#症状と原因の対応実測)。トンネル越しの ssh は [WG ホスト自身の ssh へ入る場合](wireguard.md#トンネル越しに-wg-ホスト自身の-ssh-や-cockpit-へ入る場合)。

   </details>

1. WG ホストで（手順 4 のシェルで）、ハンドシェイクと逆方向（拠点 → PC）を確かめる。

   ```bash
   cd "${REPO:?REPO が空のまま}/scripts/wireguard" &&
   sudo ./wg-vpn.sh -e ~/wg/site.env client list &&                                        # LAST_HANDSHAKE が「N 秒前」
   CLIENT_TUN_IP=$(awk -v n="${CLIENT_NAME:?CLIENT_NAME が空のまま}" '$1 == n { print $3 }' ~/wg/clients.list) &&
   ping -c 3 "${CLIENT_TUN_IP:?clients.list にその名前が無い}"                              # 拠点 → PC（PC の public ゾーンは ping に応答する）
   ```

   - 接続先拠点の LAN 上の別のホストから `ping <CLIENT_TUN_IP>` も通る（ルーターにクライアント帯の静的経路がある前提）
   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](wireguard.md#症状と原因の対応実測)

1. PC で、トンネルを切る。

   ```bash
   sudo nmcli connection down wg0 &&
   nmcli device status | grep -E '^(DEVICE|wg0 )'         # wg0 の行が消える
   ```

   - 日常は、外出先で `sudo nmcli connection up wg0`、拠点に戻る前に `sudo nmcli connection down wg0`
   - autoconnect を無効にしてあるので、再起動しても勝手には張られない

   <details>
   <summary>補足: down と日常の使い方</summary>

   - `down` で NetworkManager が作ったリンク `wg0` は消える（実測: 直後の `ip link show dev wg0` が `Device "wg0" does not exist.`、経路 3 本と firewalld の active zones からも `wg0` が外れる）
   - プロファイルは `nmcli connection show` に `wg0  wireguard  --  --` として残るので、次は `up` だけでよい
   - GNOME の設定画面やクイック設定に VPN として出るかは未確認（`connection.type` は `vpn` ではなく `wireguard` なので、VPN の欄には出ないと思われる）

   </details>

1. 平文の鍵と conf を消す。

   ```bash
   rm -f "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.key" "${WG_DIR}/wg0.conf" &&
   ls -l "${WG_DIR}"                                       # wg0.pub だけ残る
   ```

   - 秘密鍵は手順 10 で NetworkManager のプロファイルに入っているので、平文のファイルを残さない（`wg0.pub` は公開鍵なので残してよい）

   <details>
   <summary>補足: 後片付け</summary>

   後片付けを最後にしているのは、import に失敗したときに `sudo nmcli connection delete wg0` → 手順 10 をやり直すのに conf が要るため。秘密鍵は手順 10 の時点で NetworkManager の keyfile に入っている。

   **ガードの確認**（2026-09-22、この文書を書いた WG ホストで）:

   - 各ブロックを `PATH` を空にした bash に変数が空のまま流し、値を使うブロックはすべて先頭のガードで止まって、ファイルを作る・書き換える・消すコマンドの起動が 1 つも試みられないことを確認した
     - 起動が試みられたのは、値を含まない読み取り系と、意図どおりの `nmcli connection up` / `down` / `delete` だけ
   - 手順 3 と手順 8 のブロックは、一時ディレクトリで本物の `wg` / `sed` を使って実行し、次を確認した
     - 鍵が 0600 で作られる
     - `PrivateKey` 行だけが 44 文字の鍵に置き換わり、他の行が変わらない
     - `PrivateKey` 行が 2 行あるときと `wg0.key` が無いときに、中断してファイルが変わらない

   </details>

---

## ロールバック

- この節は AlmaLinux 10 の PC のもの。Windows 11 の PC は[Windows 11 のロールバック](#windows-11-のロールバック)
- **PC で、手順 1 の変数を設定したシェルで貼る**（`WG_DIR` が空だと `${WG_DIR:?…}` で止まる）
- この節の手順 3 だけは WG ホストで貼る

> [!CAUTION]
> **この節の手順 1 で、秘密鍵の置き場所である NetworkManager のプロファイル `wg0` を消す。** 鍵のバックアップは取っていないので、消した鍵は取り戻せない（[選択した方針](#選択した方針)）。

1. PC で、プロファイル `wg0` と鍵・conf の一時置き場を消す（取り戻せない）。

   ```bash
   {
     sudo nmcli connection down wg0 2>/dev/null; sudo nmcli connection delete wg0
     rm -f "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.key" "${WG_DIR}/wg0.conf" "${WG_DIR}/wg0.pub" && rmdir "${WG_DIR}"
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

   - [wireguard.md のクライアントを削除する](wireguard.md#クライアントを削除する)の手順 1〜6 を行う。対象は、手順 4 で登録した `CLIENT_NAME` と `SITE`
   - 削除前の公開鍵を控え、未知 peer と照合する。`--drop-unknown-peers` を確認なしに付けない
   - ルーターの静的経路（クライアント帯）は、他のクライアントも使うので触らない

---

## Windows 11 で使う

> [!IMPORTANT]
> - **Windows で行う**。この節の手順 1 で管理者の Windows PowerShell（5.1）を開き、この節の手順 2〜7・10・12・13・15・16 と、後ろの Windows 11 の 2 節（更新・ロールバック）のブロックをそこに貼る。ログインするユーザーは Administrators の一員（WireGuard は PC 全体に入り、トンネルを Windows のサービスとして動かす）
> - 前提: [Windows 11 の初期設定の手順 16〜19](windows-setup.md#実施手順)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - **この節の手順 8 と手順 14 は WG ホストで行う**（[実施手順](#実施手順)の手順 4〜6・13 を参照する）
> - **この節の手順 5 で WireGuard の窓が開く**。開いてから手順 6 を貼る
> - **この節の手順 11 で、PC を拠点の LAN の外のネットワークにつなぐ**（スマートフォンのテザリングなど）。手順 12 以降は LAN の外で行う

- 上から順に進める。コードブロックは、この節の手順 2 で変数を設定した PowerShell に貼る。この節の手順 9 だけは、関数名を手入力する
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](#windows-11-のロールバック)
- WG ホストの側は、AlmaLinux 10 の PC と同じ（`client add --pubkey` で公開鍵を登録して `apply` するだけで、ほかに変えるものは無い）

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、winget の定義、公式の MSI の中身と署名、WireGuard for Windows のソースと文書、Linux の PowerShell 7 での構文と模擬の実行だけ（[対象と検証環境](#対象と検証環境)）。

1. Windows で、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. 変数を設定する（4 つの IP は必ず値を入れる）。

   ```powershell
   $WG_HOST_TUN_IP = '10.99.0.1'         # 接続先拠点の WG ホストの wg0 アドレス（site.env の WG_A_TUN_IP）。<WG_HOST_TUN_IP>
   ```

   ```powershell
   $WG_HOST_LAN_IP = '192.168.110.2'     # 同じホストの LAN 側 IP（WG_A_LAN_IP）。<WG_HOST_LAN_IP>
   ```

   ```powershell
   $ROUTER_LAN_IP = '192.168.110.1'      # 接続先拠点のルーターの LAN 側 IP（ROUTER_A_LAN_IP）。<ROUTER_LAN_IP>
   ```

   ```powershell
   $PEER_WG_LAN_IP = '192.168.120.2'     # 相手拠点の WG ホストの LAN 側 IP（WG_B_LAN_IP）。<PEER_WG_LAN_IP>
   ```

   ```powershell
   foreach ($v in 'WG_HOST_TUN_IP', 'WG_HOST_LAN_IP', 'ROUTER_LAN_IP', 'PEER_WG_LAN_IP') {
     '{0,-15} = {1}' -f $v, (Get-Variable -Name $v -ValueOnly -ErrorAction SilentlyContinue)
   }
   ```

   - 編集が必須なのは、1 行ずつの 4 ブロック（入れる値は、[実施手順](#実施手順)の手順 1 と同じ）
   - 最後に値を読み戻して確かめる
   - **既定値のままでもエラーにならない**ので、4 つの IP を書き換えたか必ずここで確かめる
   - 変数はその PowerShell の中だけで有効。**新しい PowerShell を開いたら**、この節の手順 2 の 5 つのブロックを貼り直してから先へ進む

   <details>
   <summary>補足: 変数について</summary>

   - 変数の名前と意味は、AlmaLinux 10 の[手順 1](#実施手順)と同じ（PC 視点。`WG_HOST_*` = 接続先拠点、`PEER_*` = 相手拠点）。拠点 B がクライアントを受ける構成なら、`site.env` の `*_B_*` 側の値を入れる
   - 使うのは、この節の手順 13 の疎通の確認だけ
   - 鍵と conf の一時置き場は `%USERPROFILE%\wg-client`（`C:\Users\<WIN_USER>\wg-client`）に決めてあり、変数にしていない。WG ホストの `~/wg`（`site.env` と `clients.list` の置き場）とは別の名前

   </details>

1. この PC の WireGuard の状態を確かめる。

   ```powershell
   winget list --exact --id WireGuard.WireGuard --accept-source-agreements
   Get-Service -Name 'WireGuard*' -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType
   Get-ChildItem -LiteralPath "$env:ProgramFiles\WireGuard\Data\Configurations" -ErrorAction SilentlyContinue | Format-Table Name
   Test-Path -LiteralPath "$env:USERPROFILE\wg-client"
   ```

   - `入力条件に一致するインストール済みのパッケージが見つかりませんでした。`（英語の Windows では `No installed package found matching input criteria.`）と、`False` だけが出れば、まだ入っていない
   - `WireGuard.WireGuard` の行が出たら、WireGuard はもう入っている（公式のインストーラーで入れたものも出るはず）。そのまま進めてよい（この節の手順 4 は、新しい版があれば上げる）
   - `WireGuardTunnel$wg0` の行か `wg0.conf.dpapi` が出たら、同じ名前のトンネルがある。[Windows 11 のロールバック](#windows-11-のロールバック)の手順 1 で消してから始める（その鍵は取り戻せない）
   - 最後が `True` なら、前に作った鍵が残っている（この節の手順 6 で止まる）。使わないなら、[Windows 11 のロールバック](#windows-11-のロールバック)の手順 1 で消す
   - `winget` が見つからないというエラーになったら、Microsoft Store で「アプリ インストーラー」を更新してから始める

   <details>
   <summary>補足: 見ているもの</summary>

   - `WireGuardManager` は WireGuard の窓（マネージャー）のサービス、`WireGuardTunnel$<名前>` は張っているトンネルごとのサービス（[WireGuard for Windows の文書](https://git.zx2c4.com/wireguard-windows/about/docs/enterprise.md)）
   - `C:\Program Files\WireGuard\Data\Configurations` は、WireGuard が取り込んだトンネルの設定（`<名前>.conf.dpapi`）の置き場所。アクセス権が SYSTEM と Administrators だけなので、管理者の PowerShell でないと何も出ない
   - `--accept-source-agreements` は、winget を初めて使う PC で出るソースの同意の問いに答えるため（続けて貼った行が答えとして食われないように）

   </details>

1. WireGuard を winget で入れる。

   ```powershell
   winget install --exact --id WireGuard.WireGuard --source winget --scope machine --accept-source-agreements --accept-package-agreements
   winget list --exact --id WireGuard.WireGuard
   Get-AuthenticodeSignature -FilePath "$env:ProgramFiles\WireGuard\wireguard.exe", "$env:ProgramFiles\WireGuard\wg.exe" | Format-Table Status, @{ Label = 'Signer'; Expression = { $_.SignerCertificate.Subject.Split(',')[0] } }, Path -AutoSize
   & "$env:ProgramFiles\WireGuard\wg.exe" --version
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と出て、`winget list` に `WireGuard.WireGuard` の行が出ればよい（版は実行した日の最新。2026-10-03 は 1.1.1）
   - 2 つのファイルの署名が `Valid` で、署名者が `CN=WireGuard LLC`
   - 最後に `wireguard-tools v1.0.20260223 - https://git.zx2c4.com/wireguard-tools/` の形の 1 行が出る
   - インストーラーの画面は出ず、入れた後に WireGuard の窓も開かない（窓は、この節の手順 5 で開く）

   <details>
   <summary>補足: winget の定義と、入るもの</summary>

   **winget の定義**（`WireGuard.WireGuard` 1.1.1。2026-10-03 の winget-pkgs。[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）

   - `InstallerType: wix`（MSI）、`Scope: machine`。x64 のインストーラーは `https://download.wireguard.com/windows-client/wireguard-amd64-1.1.1.msi` で、winget が sha256 を確かめてから黙って入れる。x86 と arm64 の MSI もある
   - `InstallerSwitches` の `Custom: DO_NOT_LAUNCH=1` を MSI に渡す。MSI は、入れ終えたときに `wireguard.exe` を起動して窓を出すが、この値があると起動しない（WireGuard の文書の「Enterprise Usage」）。そのため、マネージャーのサービスもまだ作られない（この節の手順 5）
   - `UpgradeBehavior: install`（新しい版の MSI を上から入れる。[Windows 11 の更新](#windows-11-の更新)）
   - `--accept-source-agreements` と `--accept-package-agreements` は、winget を初めて使う PC で出る同意の問いに答えるため

   **入るもの**（MSI の定義 `installer/wireguard.wxs` と、MSI から取り出した中身）

   - `C:\Program Files\WireGuard\wireguard.exe`（窓・マネージャー・トンネルのサービスを兼ねる 1 つのプログラム。GUI のプログラムなので、PowerShell は終わるのを待たない）と `wg.exe`（wireguard-tools の `wg`。コンソールのプログラム）。どちらも WireGuard LLC の署名付き
   - スタートメニューの「WireGuard」
   - PC 全体の `PATH` の末尾に `C:\Program Files\WireGuard\` が足される。開いている PowerShell には効かないので、この文書のブロックはフルパスで呼ぶ
   - 管理者の PowerShell から動かすので、UAC の確認は出ないはず

   </details>

1. WireGuard の窓を開く（マネージャーを起動する）。

   ```powershell
   & "$env:ProgramFiles\WireGuard\wireguard.exe"
   ```

   - WireGuard の窓が開き、タスク バーの通知領域に WireGuard のアイコンが出る（トンネルの一覧はまだ空）
   - スタートメニューの「WireGuard」から開いても同じ
   - 窓は開いたままでよい（閉じても、マネージャーは動き続ける）
   - **次の手順は、WireGuard の窓が開いてから、PowerShell の窓をクリックして貼る**（窓が開く前に貼ると、開いた窓に入力が移ることがある）

   <details>
   <summary>補足: マネージャーのサービス</summary>

   - 引数無しの `wireguard.exe` は、マネージャーが動いていれば窓を出し、動いていなければマネージャーのサービス `WireGuardManager` を作って起動してから窓を出す（ソースの `main.go`、WireGuard の文書の「Enterprise Usage」）。スタートメニューの「WireGuard」も同じ
   - `WireGuardManager` は自動で起動するサービスになる。以後は、Administrators の一員がサインインするたびに、通知領域に WireGuard のアイコンが出る
   - マネージャーは、この節の手順 10 の取り込み（設定の置き場所を見張って暗号化する）と、更新の知らせ（[Windows 11 の更新](#windows-11-の更新)）に要る
   - 窓は Administrators の一員にしか出ない（ソースの `main.go` の `checkForAdminGroup`）
   - 管理者の PowerShell から開くので、UAC の確認は出ないはず
   - `wireguard.exe` は GUI のプログラムなので、PowerShell は窓が開くのを待たずにプロンプトに戻る

   </details>

1. 鍵ペアを作る。

   ```powershell
   & {
     $wg = "$env:ProgramFiles\WireGuard\wg.exe"
     $dir = "$env:USERPROFILE\wg-client"
     if (Test-Path -LiteralPath "$dir\wg0.key") { Write-Error '中断: wg0.key が既にある（作り直すなら先に消す。WG ホストに登録済みの公開鍵と対応しなくなる）'; return }
     New-Item -ItemType Directory -Force -Path $dir | Out-Null
     icacls.exe $dir /inheritance:r /grant '*S-1-5-32-544:(OI)(CI)F' /grant '*S-1-5-18:(OI)(CI)F' | Out-Null
     $priv = & $wg genkey
     if ($LASTEXITCODE -ne 0 -or $priv -cnotmatch '^[A-Za-z0-9+/]{43}=$') { Write-Error '中断: 鍵を作れない'; return }
     $pub = $priv | & $wg pubkey
     if ($LASTEXITCODE -ne 0 -or $pub -cnotmatch '^[A-Za-z0-9+/]{43}=$') { Write-Error '中断: 公開鍵を出せない'; return }
     [IO.File]::WriteAllText("$dir\wg0.key", "$priv`n", [Text.Encoding]::ASCII)
     [IO.File]::WriteAllText("$dir\wg0.pub", "$pub`n", [Text.Encoding]::ASCII)
     icacls.exe $dir
     Get-ChildItem -LiteralPath $dir | Format-Table Name, Length
     $pub
   }
   ```

   - 秘密鍵は `wg0.key` に書き、画面には出さない
   - `icacls` に `NT AUTHORITY\SYSTEM:(OI)(CI)(F)` と `BUILTIN\Administrators:(OI)(CI)(F)` の 2 行だけが出る
   - `wg0.key` と `wg0.pub` がどちらも 45 バイト
   - 最後の 1 行（公開鍵、44 文字）だけを、この節の手順 8 で WG ホストに渡す。秘密鍵（`wg0.key`）は渡さない
   - **注意**: `%USERPROFILE%\wg-client` は、管理者の PowerShell からしか読めない（管理者ではない PowerShell やエクスプローラーでは開けない）

   <details>
   <summary>補足: 鍵ペアと置き場所</summary>

   - [実施手順](#実施手順)の手順 3 と同じく、既に `wg0.key` があれば止まる（上書きすると、WG ホストに登録済みの公開鍵と対応しなくなる）
   - 秘密鍵は、ブロックを囲む `& { … }` の中の変数で受けて、ファイルに書くだけ。ブロックが終わると変数は消える。PowerShell の履歴に残るのはコマンドの文字列で、鍵は残らない
   - ファイルは `[IO.File]::WriteAllText` で ASCII（BOM 無し）で書く。Windows PowerShell 5.1 の `>` と `Out-File` は UTF-16 で書く
   - `$priv | & $wg pubkey` は、末尾に CR LF を付けて ASCII で送る（Windows PowerShell 5.1 のパイプ）。`wg pubkey` は鍵の 44 文字の後ろの空白（CR と LF を含む）を読み飛ばす（wireguard-tools のソースの `pubkey.c` と `ctype.h`。Linux の `wg` で、CR LF 付きの入力から同じ公開鍵が出た。[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
   - `wg genkey` / `wg pubkey` は、トンネルのドライバー無しで動く
   - アクセス権は、[Windows の OpenSSH サーバー](windows-openssh-server.md)の `administrators_authorized_keys` と同じ考え方で、`/inheritance:r` で `C:\Users\<WIN_USER>` から受け継ぐ自分のユーザーの許可を外し、Administrators（`S-1-5-32-544`）と SYSTEM（`S-1-5-18`）だけにする。管理者ではない窓（UAC で権限を落としたもの）で動くプログラムからは読めない
   - 管理者の PowerShell で作ったフォルダーの所有者は `BUILTIN\Administrators` になる

   </details>

1. Windows の PowerShell で、conf を取り込む関数を定義する。

   ```powershell
   function Import-WgClientConf {
     $dir = "$env:USERPROFILE\wg-client"
     $text = Get-Clipboard -Raw
     if (-not $text) { Write-Error '中断: クリップボードが空（手順 8 の client show の出力をコピーし直す）'; return }
     $lines = @($text.Trim() -split '\r?\n' | ForEach-Object { $_.TrimEnd() })
     if ($lines[0] -cne '[Interface]') { Write-Error '中断: クリップボードの先頭が [Interface] ではない（client show の出力だけをコピーし直す）'; return }
     if (@($lines -cnotmatch '^[\t\x20-\x7e]*$').Count -ne 0) { Write-Error '中断: クリップボードに ASCII でない文字がある'; return }
     if (@($lines -cmatch '^PrivateKey *=').Count -ne 1 -or -not (Test-Path -LiteralPath "$dir\wg0.key")) { Write-Error '中断: PrivateKey の行が 1 行ちょうどでないか、wg0.key が無い'; return }
     $key = (Get-Content -LiteralPath "$dir\wg0.key" -Raw).Trim()
     $conf = $lines -creplace '^PrivateKey *=.*', "PrivateKey = $key"
     [IO.File]::WriteAllText("$dir\wg0.conf", ($conf -join "`r`n") + "`r`n", [Text.Encoding]::ASCII)
     @(Get-Content -LiteralPath "$dir\wg0.conf" | Where-Object { $_ -cmatch '^PrivateKey = [A-Za-z0-9+/]{43}=$' }).Count
     Get-Content -LiteralPath "$dir\wg0.conf" | Where-Object { $_ -cnotmatch '^PrivateKey' }
   }
   ```

   - この手順は関数を定義するだけで、何も表示せず、conf もまだ書かない
   - この節の手順 9 で `Import-WgClientConf` と手入力すると、クリップボードを読み込む
   - PowerShell を開き直した場合は、この節の手順 2 と、この関数の定義を貼り直す

1. WG ホストで、[実施手順](#実施手順)の手順 4〜6 を行い、この PC の公開鍵を登録して conf を表示する。

   - [実施手順](#実施手順)の手順 4 の `CLIENT_PUBKEY` には、この節の手順 6 で出た公開鍵を貼る
   - 手順 4 の `CLIENT_NAME` は、この PC だけの名前にする（例 `win-laptop`）。ほかの端末（AlmaLinux 10 の PC など）と同じ名前にすると、手順 5 でその端末の登録を消してしまう
   - 手順 6 の `client show` の出力を、`[Interface]` の行から `PersistentKeepalive` の行まで、この PC のクリップボードにコピーする（WG ホストに SSH でつないだ端末で選んでコピーする、など）
   - `PrivateKey` はプレースホルダのままなので、**秘密情報を含まない**。どの経路で運んでもよい
   - **次の手順は、`client show` の出力をこの PC でコピーしてから行う**。コピー後は、コードブロックなど別の文字列をコピーしない

1. Windows の PowerShell で、`Import-WgClientConf` と手入力して Enter を押す。

   - 関数名はコピーせず手で打つ。クリップボードには、この節の手順 8 の conf を残しておく
   - `1`（置き換わった）と、`PrivateKey` 以外の行（`Address`・`PublicKey`・`Endpoint`・`AllowedIPs` など）が出ればよい。鍵そのものは表示しない
   - 残りの行が `client show` の出力のとおりで、途中で折り返されていないことを目で確かめる
   - `中断:` で始まるエラーが出たら、何も書いていない
   - conf をコピーし直し、この関数をもう一度呼んでもよい（`wg0.conf` を書き直す）

   <details>
   <summary>補足: conf と秘密鍵</summary>

   - [実施手順](#実施手順)の手順 7・8（`vi` に貼って保存し、`sed` で `PrivateKey` 行を置き換える）を、この節の手順 7 の関数にまとめた。エディタを開かずに、クリップボードの中身を読む（`Get-Clipboard -Raw` は、複数行を 1 つの文字列で返す。Windows PowerShell 5.1 にもある）
   - 先頭が `[Interface]` でなければ止めるのは、端末からコピーしたときにプロンプトの行が入りやすいため。行の末尾の空白は落とす
   - 2 つの確かめは、AlmaLinux 10 と同じ「置き換え前に `PrivateKey` 行がちょうど 1 行あること」と「置き換え後に 44 文字の鍵になったこと」
   - ASCII（BOM 無し）・CR LF で書く。WireGuard の読み込みは行を LF で分けて前後の空白を落とすので、CR LF でも読める（ソースの `conf/parser.go`）。BOM 付きの UTF-8 は、先頭の行が `[Interface]` と見なされずに読めない（その読み込みの部分を Linux で動かして確かめた。[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
   - `client show` の出力は ASCII だけでできている（クライアントの名前は英数字・`-`・`_` だけ）。ASCII でない文字があれば、書くときに `?` に変わるので先に止める
   - `wg0.conf` は、`%USERPROFILE%\wg-client` のアクセス権を受け継ぐ（Administrators と SYSTEM だけ）

   </details>

1. `wg0.conf` を WireGuard に取り込む。

   ```powershell
   & {
     $dir = "$env:USERPROFILE\wg-client"
     $store = "$env:ProgramFiles\WireGuard\Data\Configurations"
     if ((Get-Service -Name WireGuardManager -ErrorAction SilentlyContinue).Status -ne 'Running' -or -not (Test-Path -LiteralPath $store)) { Write-Error '中断: WireGuard のマネージャーが動いていない（手順 5 からやり直す）'; return }
     if (-not (Test-Path -LiteralPath "$dir\wg0.conf")) { Write-Error '中断: wg0.conf が無い（手順 9）'; return }
     if (Test-Path -LiteralPath "$store\wg0.conf.dpapi") { Write-Error '中断: wg0 というトンネルが既にある'; return }
     Copy-Item -LiteralPath "$dir\wg0.conf" -Destination "$store\wg0.conf"
     for ($i = 0; $i -lt 30 -and (Test-Path -LiteralPath "$store\wg0.conf"); $i++) { Start-Sleep -Seconds 1 }
     Get-ChildItem -LiteralPath $store | Format-Table Name, Length, LastWriteTime
   }
   ```

   - `wg0.conf.dpapi` の 1 行だけが出ればよい（写した `wg0.conf` は、WireGuard が暗号化して消す）
   - WireGuard の窓のトンネルの一覧に `wg0` が出る（無効のまま）
   - 取り込んでもトンネルは張られない（NetworkManager の `import` と違う）。この手順は LAN の中で貼ってよい
   - `wg0.conf` が残ったら、取り込めていない。理由を見て（この手順の補足）、残った `wg0.conf` を `Remove-Item -LiteralPath "$env:ProgramFiles\WireGuard\Data\Configurations\wg0.conf"` で消し、この節の手順 8・9 からやり直す
   - （この手順の代わりに）窓の「トンネルをファイルからインポート…」で `%USERPROFILE%\wg-client\wg0.conf` を選んでも、同じ `wg0.conf.dpapi` ができるはず

   <details>
   <summary>補足: 取り込みと、理由の見方</summary>

   - マネージャーは `C:\Program Files\WireGuard\Data\Configurations` を見張っていて、`.conf` のファイルが来ると、読んで `<名前>.conf.dpapi` に暗号化して書き、元のファイルを消す（WireGuard の文書の「Enterprise Usage」、ソースの `conf/migration_windows.go`）。トンネルの名前はファイル名から決まる（`wg0`）
   - `.conf.dpapi` は LocalSystem の DPAPI で暗号化され、アクセス権は SYSTEM だけが読み書きでき、Administrators は消せるだけ（ソースの `conf/filewriter_windows.go`）。秘密鍵の置き場所は、以後これだけになる（AlmaLinux 10 の `/etc/NetworkManager/system-connections/wg0.nmconnection` に当たる）
   - `Data` のフォルダーのアクセス権は SYSTEM と Administrators のフル コントロールなので、管理者の PowerShell から写せる（ソースの `conf/path_windows.go`）
   - 読めなかったときは、マネージャーのログに `Unable to ingest and encrypt` の行が出て、`wg0.conf` が残る。ログは `& "$env:ProgramFiles\WireGuard\wireguard.exe" /dumplog | Select-String -SimpleMatch 'wg0.conf'` で見られる（窓の「ログ」のタブでも見られる）
   - 同じ名前の `wg0.conf.dpapi` があると上書きしない（取り込めずに残る）ので、ブロックの先頭で止めている

   </details>

1. PC を、拠点の LAN の外のネットワークにつなぐ（スマートフォンのテザリングなど）。

   - クライアント conf の `AllowedIPs` には両拠点の LAN が入るので、LAN 内でこの節の手順 12 を貼ると、そこで LAN の通信が切れる
   - **次の手順は、LAN の外につないでから貼る**

1. 拠点の LAN の外で、トンネルを張る。

   ```powershell
   & {
     $conf = "$env:ProgramFiles\WireGuard\Data\Configurations\wg0.conf.dpapi"
     if (-not (Test-Path -LiteralPath $conf)) { Write-Error '中断: wg0.conf.dpapi が無い（手順 10）'; return }
     & "$env:ProgramFiles\WireGuard\wireguard.exe" /installtunnelservice $conf 2>&1 | ForEach-Object { "$_" }
     for ($i = 0; $i -lt 30 -and -not (Get-NetIPAddress -InterfaceAlias wg0 -AddressFamily IPv4 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     Get-Service -Name 'WireGuardTunnel$wg0' | Format-Table Name, Status, StartType
     Get-NetIPAddress -InterfaceAlias wg0 -AddressFamily IPv4 | Format-Table InterfaceAlias, IPAddress, PrefixLength
     Get-NetRoute -InterfaceAlias wg0 -AddressFamily IPv4 | Format-Table DestinationPrefix, NextHop, RouteMetric
     Get-NetIPInterface -InterfaceAlias wg0 -AddressFamily IPv4 | Format-Table InterfaceAlias, NlMtu, InterfaceMetric
     Get-NetConnectionProfile -InterfaceAlias wg0 -ErrorAction SilentlyContinue | Format-Table InterfaceAlias, NetworkCategory
     Get-DnsClientServerAddress -InterfaceAlias wg0 -AddressFamily IPv4 | Format-Table InterfaceAlias, ServerAddresses
     & "$env:ProgramFiles\WireGuard\wg.exe" show wg0
   }
   ```

   - `WireGuardTunnel$wg0  Running  Automatic` と、`wg0` に `<CLIENT_TUN_IP>` / `32` が出ればよい
   - 経路に、`AllowedIPs` の 3 つ（`RouteMetric` が `0`）がある
   - `NlMtu` は `1420`（今の回線の MTU が 1500 のとき）
   - `NetworkCategory` は `Public` のはず（変えない。行が出なければ、Windows がまだネットワークを識別している）
   - `ServerAddresses` が空（`{}`）。DNS は変わらない（conf に `DNS =` が無い）
   - `wg show` の `latest handshake` が数秒前で、`transfer` の received が 0 でない。まだ出ていなければ、この節の手順 13 の通信で出る
   - 窓で `wg0` を選び「有効化」を押しても同じ
   - **注意**: LAN 内で貼ってしまったら、そこで LAN の通信が切れる。PC の画面の WireGuard の窓で「無効化」を押す

   <details>
   <summary>補足: 張ったときに WireGuard がすること</summary>

   - `/installtunnelservice <.conf.dpapi のパス>` は、トンネルのサービス `WireGuardTunnel$wg0`（自動で起動する）を作って起動する。窓の「有効化」も、同じパスで同じことをする（ソースの `manager/ipc_server.go` の `Start` と `manager/install.go` の `InstallTunnel`）
   - `wireguard.exe` は GUI のプログラムなので、PowerShell は、出力をパイプでつないだときだけ終わるのを待つ。`2>&1 | ForEach-Object { "$_" }` で待ち、失敗したときのエラー（`Error: …`）を文字で出す
   - アダプターの名前はトンネルの名前（`wg0`）。経路は `AllowedIPs` のとおりに、ルートのメトリック 0 で入る（ソースの `tunnel/addressconfig.go`）。インターフェースのメトリックは自動のまま（`/0` があるときだけ 0 にする）
   - MTU は、conf に `MTU =` が無いと、既定の経路のインターフェースの MTU から 80 を引いた値にする（WireGuard の文書の「Network Configuration Quirks」）
   - `AllowedIPs` に `/0` が無いので、キルスイッチ（トンネルを通らない通信を止めるファイアウォールの規則）は掛からない。WireGuard のパケットを通す規則を 1 つ足すだけ（同じ文書）
   - アダプターの GUID は設定から決まるので、ネットワークの種類（パブリック / プライベート）は、設定を変えない限り同じものが使われる（同じ文書）。識別されないネットワークは、Windows の既定ではパブリックになるはず（確かめていない）
   - `Endpoint` に名前を書いたときは、張るたびに名前を引く（ソースの `tunnel/service.go`）
   - `wg.exe show` は、`.conf.dpapi` のトンネルでは管理者の権限が要る（同じ「Enterprise Usage」）

   </details>

1. PC で、トンネル IP → WG ホストの LAN 側 → ルーター → 相手拠点の順に疎通を試す。

   ```powershell
   if (-not ($WG_HOST_TUN_IP -and $WG_HOST_LAN_IP -and $ROUTER_LAN_IP -and $PEER_WG_LAN_IP)) {
     Write-Error '手順 2 の変数が空のまま'
   } else {
     foreach ($h in $WG_HOST_TUN_IP, $WG_HOST_LAN_IP, $ROUTER_LAN_IP, $PEER_WG_LAN_IP) {
       "== $h"
       ping.exe -n 3 -w 2000 $h | Select-Object -Last 3
     }
     tracert.exe -d -h 5 -w 2000 $PEER_WG_LAN_IP
   }
   ```

   - 4 つとも、損失が 0%（`0% の損失`）ならよい
   - `tracert` は `<WG_HOST_TUN_IP>` → `<PEER_WG_LAN_IP>` の順に出る
   - 相手拠点の LAN 上の別のホストへの `ping`、トンネル越しの `ssh <ユーザー>@<WG_HOST_LAN_IP>`（Windows 11 の OpenSSH クライアント）も試しておくとよい
   - どこで止まるかで、疑う場所が変わる（[実施手順](#実施手順)の手順 12 の補足と同じ）

1. WG ホストで、[実施手順](#実施手順)の手順 13 を（手順 4 のシェルで）貼り、ハンドシェイクを確かめる。

   - `client list` の、この PC の名前の `LAST_HANDSHAKE` が「N 秒前」なら届いている
   - 最後の `ping`（拠点 → PC）は、応答が無くてよい。Windows の既定のファイアウォールは、ICMP のエコー要求を受けないはず（[選択した方針](#選択した方針)のとおり、変えない）
   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](wireguard.md#症状と原因の対応実測)
   - **次の手順は、WG ホストで確かめてから、この PC で貼る**

1. PC で、トンネルを切る。

   ```powershell
   & "$env:ProgramFiles\WireGuard\wireguard.exe" /uninstalltunnelservice wg0 2>&1 | ForEach-Object { "$_" }
   for ($i = 0; $i -lt 30 -and (Get-Service -Name 'WireGuardTunnel$wg0' -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
   Get-Service -Name 'WireGuardTunnel$wg0' -ErrorAction SilentlyContinue
   Get-NetAdapter -Name wg0 -ErrorAction SilentlyContinue
   ```

   - 最後の 2 つが何も出さなければよい（トンネルのサービスとアダプター `wg0` が消える）
   - 窓で `wg0` を選び「無効化」を押しても同じ
   - 日常は、外出先で窓（か、通知領域の WireGuard のアイコン）から `wg0` を有効化し、拠点に戻る前に無効化する（この節の手順 12・15 のコマンドでも同じ）
   - **張ったまま再起動すると、起動したときにまた張られる**（トンネルのサービスは自動で起動する）。拠点の LAN に戻る前に切る

   <details>
   <summary>補足: 切ったときと、日常の使い方</summary>

   - `/uninstalltunnelservice wg0` は、トンネルのサービスを止めて消す。窓の「無効化」も同じ（ソースの `manager/ipc_server.go` の `Stop`）。アダプターは、トンネルが止まると消える
   - トンネルの設定（`wg0.conf.dpapi`）は残るので、次は有効化だけでよい
   - サービスは消されてもすぐには無くならないことがあるので、消えるまで 30 秒まで待つ
   - NetworkManager の `autoconnect no` に当たる設定は無い。張ったまま（サービスが残ったまま）再起動すると、起動のときに張られ、拠点の LAN の中なら LAN の通信を奪う

   </details>

1. 平文の鍵と conf を消す。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\wg-client\wg0.key", "$env:USERPROFILE\wg-client\wg0.conf"
   Get-ChildItem -LiteralPath "$env:USERPROFILE\wg-client" | Format-Table Name, Length
   ```

   - `wg0.pub` だけが残る
   - 秘密鍵は、この節の手順 10 で WireGuard の設定（`wg0.conf.dpapi`）に入っているので、平文のファイルを残さない（`wg0.pub` は公開鍵なので残してよい）
   - 後片付けを最後にしているのは、取り込みに失敗したときに、この節の手順 10 をやり直すのに `wg0.conf` が要るため（[実施手順](#実施手順)の手順 15 と同じ）

---

## Windows 11 の更新

- WireGuard のマネージャーは、1 時間ごとに新しい版を確かめる（起動した直後は数分待ってから）。新しい版があると、窓に「更新が利用できます！」のタブが出て、そこの「今すぐ更新」で上がる（Administrators の一員だけ）
- 窓からの更新は、公式の署名付きの一覧（`latest.sig`）で MSI を確かめてから入れる。winget で上げても、入るのは同じ公式の MSI
- 更新の間、マネージャーと、張っているトンネルのサービスは止まり、入れ終えると起動し直す（張っていれば数秒切れる）
- この節の手順 1 は、管理者の Windows PowerShell（5.1）に貼る

1. WireGuard を winget で上げる。

   ```powershell
   winget upgrade --exact --id WireGuard.WireGuard --source winget --accept-source-agreements --accept-package-agreements
   winget list --exact --id WireGuard.WireGuard
   Get-Service -Name 'WireGuard*' | Format-Table Name, Status, StartType
   ```

   - 上がったら `インストールが完了しました` と出て、`winget list` の `WireGuard.WireGuard` の版が新しくなる
   - 新しい版が無ければ、`利用可能なアップグレードが見つかりませんでした。`（英語の Windows では `No available upgrade found.`）と出る
   - 最後に `WireGuardManager` が `Running` で出る（張っていれば `WireGuardTunnel$wg0` も）
   - winget の定義は、公式の版より遅れて出ることがある。窓が更新を知らせているのに winget で上がらないときは、窓の「今すぐ更新」で上げる

   <details>
   <summary>補足: 更新の動き</summary>

   - winget の定義は `UpgradeBehavior: install` で、新しい版の MSI を上から入れる（MSI のメジャー アップグレード）。トンネルの設定（`Data`）は消えない（MSI が `Data` を消すのは、アンインストールのときだけ。ソースの `installer/customactions.c`）
   - MSI は、入れる前に動いている WireGuard のサービス（`WireGuardManager` と `WireGuardTunnel$…`）を止め、入れ終えると起動し直す（同じソースの `EvaluateWireGuardServices`）。winget は `DO_NOT_LAUNCH=1` を渡すが、サービスの起動し直しには関係しないはず
   - 窓の「今すぐ更新」と、コマンドの `& "$env:ProgramFiles\WireGuard\wireguard.exe" /update 2>&1 | ForEach-Object { "$_" }` は、`https://download.wireguard.com/windows-client/latest.sig`（Ed25519 の署名付きの、MSI の BLAKE2b の一覧）を確かめてから、その MSI を取って入れる（ソースの `updater/`、WireGuard の文書の「Enterprise Usage」）
   - 本書では、新しい版が出ていないので、更新を試していない

   </details>

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
   winget uninstall --exact --id WireGuard.WireGuard --source winget
   winget list --exact --id WireGuard.WireGuard
   Get-Service -Name 'WireGuard*' -ErrorAction SilentlyContinue
   Test-Path -LiteralPath "$env:ProgramFiles\WireGuard"
   ```

   - `正常にアンインストールされました`（英語の Windows では `Successfully uninstalled`）と出て、`winget list` が `入力条件に一致するインストール済みのパッケージが見つかりませんでした。` を出し、サービスが何も出ず、`False` が出ればよい
   - WireGuard の窓と、通知領域のアイコンも消える

   <details>
   <summary>補足: アンインストールで消えるもの</summary>

   - MSI のアンインストールは、WireGuard のサービス（マネージャーと、すべてのトンネル）を止めて消し、アダプターを消し、`C:\Program Files\WireGuard\Data`（トンネルの設定・ログ）と `HKLM\Software\WireGuard` を消す（ソースの `installer/customactions.c` の `EvaluateWireGuardServices`・`RemoveAdapters`・`RemoveConfigFolder`）
   - PC 全体の `PATH` に足した `C:\Program Files\WireGuard\` も外れる（MSI の定義の `Permanent="no"`）
   - `C:\Program Files\WireGuard` そのものも消えるはず（確かめていない）

   </details>

1. WG ホストで、[ロールバック](#ロールバック)の手順 3 の案内に従い、登録を消して反映する。

   - 手順 4 の `CLIENT_NAME` は、[Windows 11 で使う](#windows-11-で使う)の手順 8 で登録した、この PC の名前にする
   - ルーターの静的経路（クライアント帯）は、他のクライアントも使うので触らない

---

## 補足

### 対象と検証環境

- **目的**: [WireGuard VPN 構築手順](wireguard.md)で建てた拠点の WG ホストに、外出先の AlmaLinux 10 または Windows 11 のノート PC から接続し、両拠点の LAN に届くようにする
  - 鍵は PC で作り、**公開鍵だけ**を WG ホストに登録する
  - AlmaLinux 10 では、トンネルを NetworkManager のプロファイル `wg0` として持ち、`nmcli connection up wg0` / `down wg0` で張る・切る（`wg-quick` は使わない。→ [代替](#代替-wg-quick-で張る場合)）
  - Windows 11 では、公式の WireGuard for Windows のトンネル `wg0` として持ち、`wireguard.exe /installtunnelservice` / `/uninstalltunnelservice`（窓の「有効化」「無効化」と同じ）で張る・切る
- **進め方**: **冒頭の変数ブロックに値を 1 度書き、以降のコマンドをそのまま貼る**
  - 手順 4〜6 と手順 13 だけは WG ホスト上で実行する（WG ホスト側の変数は手順 4 で設定する）
  - WG ホスト側は `wg-vpn.sh` の `client add --pubkey` → `apply` → `client show` で、[wireguard.md の手順 11〜13](wireguard.md#実施手順) と同じ
  - **Windows 11**（[Windows 11 で使う](#windows-11-で使う)）: WireGuard for Windows を winget で入れ、鍵はその `wg.exe` で作る。`client show` の conf をクリップボードから読んで秘密鍵を入れ、WireGuard の設定の置き場所に写して暗号化させてから張る。管理者の Windows PowerShell 5.1 で関数を先に定義し、conf コピー後に関数名を手入力する。WG ホストでは同じ手順 4〜6・13 を使う
- **状態（AlmaLinux 10）**: **実機で本実行済み（2026-09-22）。クリーンインストールした x86_64 の VM でも現行ブロックを本実行した（2026-10-06）**
  - 拠点 A の LAN にあるノート PC を**スマートフォンのテザリング回線に移してから**、拠点 B の WG ホストへ手順 1〜15 を通した
  - 確認したこと: 両拠点の LAN への ping、トンネル越しの ssh、拠点側からの逆方向 ping
  - NetworkManager の挙動として推定で書いていた項目は、1〜9 が実測で確定した
  - **確認していないこと**: サスペンド復帰・Wi-Fi の切り替え・`Endpoint` が DDNS 名のとき・GNOME の UI・`DNS =` がある場合など（→ [残っている未確認事項](#残っている未確認事項)）
  - **拠点の LAN の中からトンネルを張ることは、意図的に試していない**（[注意点](#注意点)のとおり LAN の経路を奪うため）
  - 実測の記録は[付録](#付録-実機での検証記録)
  - 2026-09-28: 手順 2・10・11 と、[ロールバック](#ロールバック)の手順 1のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-05: 手順 5 とロールバックの手順 3 を、公開鍵を照合してから削除を反映する共通手順への案内に変更した。新しい削除・鍵交換の順序は隔離したスタブで確認し、実機では流していない
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）:
    - 配布物: winget の `WireGuard.WireGuard` 1.1.1 の定義、公式の MSI（amd64）の sha256（winget の定義と一致）・BLAKE2b（公式の署名付きの `latest.sig` と一致。その署名も）・Authenticode の署名者、MSI の中の `wireguard.exe`（GUI のプログラム）と `wg.exe`（コンソールのプログラム）
    - WireGuard for Windows 1.1.1 のソースと文書: MSI の定義（`DO_NOT_LAUNCH`、アンインストールで `Data` を消す）、設定の置き場所への取り込みと暗号化・アクセス権、`/installtunnelservice` と窓の「有効化」が同じこと、トンネルの経路・MTU・キルスイッチの条件
    - `wg pubkey` が CR LF 付きの入力を受けること（Linux の wireguard-tools 1.0.20210914 と、ソースで）
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。[Windows 11 で使う](#windows-11-で使う)の手順 6・9（現在は手順 7 の関数内）・10・12・13・15・16 と[Windows 11 のロールバック](#windows-11-のロールバック)の手順 1 のブロックは、Linux の pwsh で偽物のコマンドを使って流した（手順 12・15 は、`wireguard.exe` と Windows のネットワークのコマンドレットも偽物。[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
    - 手順 9 で書いた `wg0.conf` が、WireGuard for Windows 1.1.1 の conf の読み込みの部分（Linux でビルドできるように写したもの）で読めること（BOM 付きの UTF-8 は読めないことも。同じ付録）
  - 2026-10-05: 取込みを「手順 7 で関数定義 → 手順 8 で conf をコピー → 手順 9 で関数名を手入力」に分けた。18 ブロックの構文と、この操作順、空・コード・非 ASCII・PrivateKey 重複の拒否を Linux の PowerShell 7.6.6 とクリップボードのスタブで確認した。Windows の端末では貼っていない
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
| WG ホスト側 | [wireguard.md](wireguard.md) の構成（`wg-vpn.sh`。AlmaLinux 10.2 aarch64、カーネル 6.12 系）。**実測では拠点 B がクライアントを受ける**（`WG_B_CLIENT_NET` を設定、`WG_A_CLIENT_NET` は空）。本文の例の値は `site.env.example`（拠点 A が受ける構成）のままにしてある |

Windows 11 の手順が前提にしている環境（流していない）:

| 項目 | 値 |
|---|---|
| OS | Windows 11（x64） |
| PowerShell | Windows PowerShell 5.1（管理者として実行） |
| ユーザー | Administrators の一員（Microsoft アカウントでもローカル アカウントでもよい） |
| WireGuard for Windows | 1.1.1（2026-09-20。winget の `WireGuard.WireGuard`、`wireguard-amd64-1.1.1.msi`。中の `wg.exe` は wireguard-tools 1.0.20260223） |
| 接続時の回線 | AlmaLinux 10 と同じく、拠点の LAN の外（スマートフォンのテザリングなど） |
| WG ホスト側 | AlmaLinux 10 の PC と同じ（変えるものは無い） |

![構成](diagrams/wireguard-remote-client.svg)

図の Remote client が本書の PC。接続先拠点（図では拠点 A）の WG ホストにトンネルを張り、拠点 A・B の LAN に届く（→ [パケットの流れ](wireguard.md#パケットの流れremote-client--各拠点)）。

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。PC 側は[手順 1](#実施手順)、WG ホスト側は[手順 4](#実施手順)の先頭で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。例は `site.env.example`（拠点 A がクライアントを受ける構成）の値。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)の手順 2 で、同じ名前の PowerShell の変数（`$WG_HOST_TUN_IP` など 4 つ）を設定する（鍵と conf の一時置き場は `%USERPROFILE%\wg-client` に決めてあり、変数にしていない）。
>
> | 変数 | 設定する場所 | 意味 | 例 |
> |---|---|---|---|
> | `${WG_DIR}` | PC | 鍵と conf の一時置き場。取り込んだら秘密鍵と conf は消す（手順 15）。WG ホストの `~/wg` と取り違えないよう別の名前にしてある | `~/wg-client` |
> | `${WG_HOST_TUN_IP}` | PC | 接続先拠点の WG ホストの `wg0` アドレス（`site.env` の `WG_A_TUN_IP`） | `10.99.0.1` |
> | `${WG_HOST_LAN_IP}` | PC | 同じホストの LAN 側 IP（`WG_A_LAN_IP`） | `192.168.110.2` |
> | `${ROUTER_LAN_IP}` | PC | 接続先拠点のルーターの LAN 側 IP（`ROUTER_A_LAN_IP`） | `192.168.110.1` |
> | `${PEER_WG_LAN_IP}` | PC | 相手拠点の WG ホストの LAN 側 IP（`WG_B_LAN_IP`） | `192.168.120.2` |
> | `${REPO}` / `${SITE}` | WG ホスト | このリポジトリの clone 先 / クライアントを受ける拠点（`A` か `B`） | `~/setup-notes` / `A` |
> | `${CLIENT_NAME}` / `${CLIENT_PUBKEY}` | WG ホスト | 登録簿（`clients.list`）に載せる名前 / 手順 3 で PC に表示された公開鍵 | `laptop` /（`wg pubkey` の出力） |
>
> 出力例・表の中の値は `<CLIENT_NAME>` / `<CLIENT_TUN_IP>`（ホストが割り当てるトンネル IP）/ `<CLIENT_PUBKEY>` / `<SITE_A_PUBKEY>` / `<SITE_A_PUBLIC>` / `<WG_PORT>` / `<WG_HOST_TUN_IP>` / `<WIN_USER>`（Windows のユーザー名）などのプレースホルダで書いてある。
>
> - **`<...>` を含むコマンドは bash のコードブロックには置かない**（本文中のインラインコードで示し、値に読み替える）
> - 読者が値を入れる必要があるコードブロックは、先頭で変数が空なら中断するようにしてあり、値を入れずに貼っても何も実行されない
>
> 秘密鍵はこの文書に載せず、手順の中でも端末に表示しない。公開鍵も検証用の使い捨ての値なので載せない。

手順書全体に関わる理由・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

AlmaLinux 10 の実機で、2026-09-22、手順 2 の前に採取（採取コマンドは[付録](#付録-実機での検証記録)の「記録用ブロック」）。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)の手順 3 で確かめる（流していないので記録は無い）。

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

### 選択した方針

- **NetworkManager（`nmcli connection import`）で張る**
  - PC の Wi-Fi を NetworkManager が管理しているので、トンネルも同じ管理下に置く。管理者が 2 つになるのを避ける
  - `wg-quick` が作った `wg0` は NetworkManager から `connected (externally)` に見え、NetworkManager が同名の一時プロファイル（`autoconnect yes`）を作る
    - この文書を書いた WG ホストで実測: `nmcli device status` に `wg0  wireguard  connected (externally)  wg0`
  - `import` はホストが出す conf をそのまま読むので、手で写すのは秘密鍵の 1 行だけ
  - RHEL 10 のドキュメントは `nmcli connection add` で組む方式（→ [代替](#代替-nmcli-connection-add-で組む場合rhel-のドキュメントの方式)）
- **鍵は PC で作り、公開鍵だけをホストに渡す**（→ [wireguard.md: クライアントの秘密鍵の扱い](wireguard.md#クライアントの秘密鍵の扱い)）
  - 秘密鍵が PC から出ない
  - `client show` の出力に秘密が無いので、渡す経路を選ばない
  - ホストに秘密鍵入りの conf が残らないので、wireguard.md 手順 16 の `rm` も要らない（`--pubkey` で作った conf はプレースホルダのまま残してよい）
- **ファイル名は `wg0.conf`** — NetworkManager の importer はファイル名（`.conf` を除いた部分）を接続名とインターフェース名にする（実測）。`wg0` なら WG ホスト側と同じ呼び名になる
- **スプリットトンネル、`DNS =` 無し** — ホストが出す conf のとおり
  - `AllowedIPs` は両拠点の LAN とトンネル網だけで、それ以外の通信は今いるネットワークにそのまま出る
  - `site.env` の `WG_CLIENT_DNS` が空なので、resolv.conf にも触らない
  - 全トラフィックを通す構成（`0.0.0.0/0`）は[対象外](wireguard.md#全トラフィックを-vpn-経由にする場合対象外)
- **autoconnect は無効** — 拠点の LAN 内で自動的に張られると、ヘアピンと経路の奪い合いになる（→ [注意点](#注意点)）
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
  - バックアップは取らず、失ったら手順 3 からやり直す（ホスト側は手順 5 の共通の削除手順で反映した後、手順 6 で `client add --pubkey`）
  - WG ホストの[バックアップ](wireguard.md#バックアップと復旧os-の再インストール)に、クライアントの鍵は含まれない

Windows 11 で WireGuard を入れる経路を比べた（2026-10-03 時点。どれも中身は公式の MSI）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `WireGuard.WireGuard`** | 1.1.1（2026-09-20）。公式の `download.wireguard.com` の MSI を、winget が sha256 を確かめて黙って入れる。`DO_NOT_LAUNCH=1` を付けるので、入れた後に何も起動しない。PC 全体（`C:\Program Files\WireGuard`）に入る | **採用**（ほかの Windows の手順書と同じく winget） |
| 公式の `wireguard-installer.exe` | 構成に合う MSI を選び、署名を確かめて実行する（WireGuard の文書の「Enterprise Usage」）。公式のサイトが一般の利用者に案内する形 | 不採用（ブラウザと画面の操作になる。入るものは同じ） |
| scoop の `nonportable/wireguard-np` | 1.1.1（同じ MSI。sha256 も同じ）。管理者の権限で `msiexec /qn` を動かし、起動した `wireguard.exe` を止める | 不採用（[Windows 11 の初期設定](windows-setup.md)の scoop は、管理者ではない窓で使う） |

Windows 11 で conf を取り込んで張る方法を比べた:

| 方法 | 状況 | 採否 |
|---|---|---|
| **設定の置き場所（`C:\Program Files\WireGuard\Data\Configurations`）に `wg0.conf` を写し、マネージャーに暗号化させる。張る・切るは `wireguard.exe /installtunnelservice` / `/uninstalltunnelservice`** | マネージャーが `wg0.conf.dpapi` に暗号化して、写した平文を消す（WireGuard の文書の「Enterprise Usage」）。窓の一覧にも出て、窓と通知領域のアイコンからも張る・切るができる。2 つのコマンドは、窓の「有効化」「無効化」がすることと同じ | **採用**（ブロックで写して、できたことを確かめられる） |
| 窓の「トンネルをファイルからインポート…」 | 結果は同じ（`wg0.conf.dpapi` になる）。ファイルを選ぶ画面の操作になり、確かめをブロックにまとめられない | 不採用（[Windows 11 で使う](#windows-11-で使う)の手順 10 の代わりにしてよい） |
| `/installtunnelservice` に作業用の `wg0.conf` を直接渡す | すぐ張られるが、トンネルのサービスは起動のたびにそのファイルを読むので、秘密鍵入りの平文のファイルを消せない | 不採用 |

- **Windows 11 でも、鍵は PC で作り、公開鍵だけを WG ホストに渡す**（AlmaLinux 10 と同じ）
  - 秘密鍵は、`wg.exe genkey` の出力をブロックの中の変数で受け、画面に出さずにファイルに書く
  - `client show` の conf は、ファイルにせずクリップボードから読む（`vi` を開く手順の代わり）。秘密は入っていないので、運ぶ経路を選ばない
- **Windows 11 の秘密鍵の置き場所は、WireGuard の設定（`wg0.conf.dpapi`）だけ**
  - LocalSystem（マネージャー）の DPAPI で暗号化され、アクセス権は SYSTEM だけが読み書きでき、Administrators は消せるだけ（ソースの `conf/filewriter_windows.go`）
  - 作業用の置き場所（`%USERPROFILE%\wg-client`）は、アクセス権を Administrators と SYSTEM だけにし（管理者の PowerShell からだけ読める）、[Windows 11 で使う](#windows-11-で使う)の手順 16 で平文の鍵と conf を消す
  - バックアップは取らず、失ったら作り直す（AlmaLinux 10 と同じ。ホスト側は[実施手順](#実施手順)の手順 5 の共通の削除手順で反映した後、手順 6 で `client add --pubkey`）
- **Windows 11 では、拠点の LAN に戻る前に手で切る**
  - トンネルのサービスは自動で起動するので、張ったまま再起動すると、起動のときに張られる。NetworkManager の `autoconnect no` に当たる設定は無い
  - 取り込みだけではトンネルは張られない（NetworkManager の `import` と違う）
- **Windows 11 のファイアウォールとネットワークの種類は変えない**
  - PC 側で開けるものは無い（外向きの UDP は既定で通る）。WireGuard は自分のパケットを通す規則を自分で足す
  - `wg0` のネットワークはパブリックのはず（識別されないネットワーク）。プライベートにすると、プライベート向けの受信の規則（[Windows の OpenSSH サーバー](windows-openssh-server.md)など）が、拠点からトンネル越しに届くようになる
  - 拠点から PC への ping（[実施手順](#実施手順)の手順 13 の最後）は、Windows の既定のファイアウォールが ICMP のエコー要求を受けないので、返らないはず。トンネルが動いているかは、WG ホストの `client list` の `LAST_HANDSHAKE` で見る
- **Windows 11 ではキルスイッチは出ない**: `AllowedIPs` に `/0` が無いので、窓の編集の「トンネルを通らないトラフィックのブロック（キルスイッチ）」は出ず、ファイアウォールの制限も掛からない（WireGuard の文書の「Network Configuration Quirks」）。全トラフィックを通す構成は、AlmaLinux 10 と同じく対象外
- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](syncthing.md) と同じく後ろの節に分けた。WG ホストの手順は共通なので、[実施手順](#実施手順)の手順 4〜6・13 と[ロールバック](#ロールバック)の手順 3 をそのまま使う

### 完了時点の状態

AlmaLinux 10 の実機で、2026-09-22、手順 15 の後（元の Wi-Fi に戻した状態）。Windows 11 は流していないので、記録は無い。

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

### 代替: wg-quick で張る場合

NetworkManager を使わない場合（未検証）。

- 手順 8 までは同じで、conf を `/etc/wireguard/wg0.conf` に置いて `wg-quick` で張る
- NetworkManager の `wg0` プロファイルが無いこと（同じ ifname で併用しない）

```bash
sudo install -m 600 -o root -g root "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.conf" /etc/wireguard/wg0.conf &&
sudo restorecon /etc/wireguard/wg0.conf &&
sudo wg-quick up wg0                     # 切るのは sudo wg-quick down wg0
```

- `DNS =` を書くなら `resolvconf` 経由で `systemd-resolved` が要る（→ [wireguard.md: `DNS =` を書く場合](wireguard.md#dns--を書く場合)）
- 起動時に張るなら `systemctl enable wg-quick@wg0`。ただし Wi-Fi より先に走り、`Endpoint` が名前なら解決に失敗しうる。拠点の LAN 内でも張られる
- NetworkManager からは `connected (externally)` として見え、同名の一時プロファイルが作られる（WG ホストで実測）
- wireguard.md の namespace ラボはクライアント側をこの経路で動かして疎通を確認している（→ [リモートクライアントの検証](wireguard.md#リモートクライアントの検証2026-09-19)）。本書の NetworkManager の手順は実機でも確認済み（[対象と検証環境](#対象と検証環境)）。この wg-quick の代替手順を PC の実機で通すことは未確認

### 代替: WG ホスト側で鍵を作る場合

wireguard.md 手順 10〜16 の元の流れ（→ [wireguard.md 手順 10〜16](wireguard.md#実施手順)、[秘密鍵の扱い](wireguard.md#クライアントの秘密鍵の扱い)）。

1. ホストで `client add A NAME`（`--pubkey` 無し）→ `apply A` → `client show NAME`（拠点 B なら `A` を `B` に読み替える）。`apply` でホストに反映してから表示する。この出力に秘密鍵が入っている
1. LAN 内の `scp` など安全な経路で、PC の `${WG_DIR}/wg0.conf` に置く（手順 8 の `sed` は不要）
1. 手順 9 以降は同じ
1. 取り込んだら、ホストで `sudo rm /etc/wireguard/clients/NAME.conf`

- 端末のスクロールバックとクリップボードに鍵が残る点に注意
- スマートフォンは `client show NAME --qr` で、こちらの流れになる

### 代替: nmcli connection add で組む場合（RHEL のドキュメントの方式）

conf を import せず、値を手で写す方式（未検証）。最初から `autoconnect no` にできるのが利点。

1. `nmcli connection add type wireguard con-name wg0 ifname wg0 autoconnect no`
1. `nmcli connection modify wg0 ipv4.method manual ipv4.addresses <CLIENT_TUN_IP>/32`
1. `wireguard.private-key`（秘密鍵）
1. `wireguard.peers '<SITE_A_PUBKEY> endpoint=<SITE_A_PUBLIC>:<WG_PORT> allowed-ips=<SITE_A_LAN>;<SITE_B_LAN>;<WG_TUNNEL_NET> persistent-keepalive=25'`（`allowed-ips` は `;` 区切り。`nm-settings-nmcli(5)`）
1. `nmcli connection up wg0`

### 注意点

- **拠点の LAN 内では切る**: 手順 10 以降は**どちらの拠点の LAN の外でも**行い、import 直後に自動で張られるので（実測）すぐ切る
  - `Endpoint` 宛ての通信が、ルーターで折り返す[ヘアピン](wireguard.md#クライアントが拠点の-lan-内にいるとき)になる
  - それに加えて、NetworkManager が入れる拠点 LAN の経路（**metric 50**。実測）が Wi-Fi の直結経路（metric 600）に勝ち、LAN 宛ての通信がすべてトンネルに入る
  - `AllowedIPs` には**両拠点の LAN**が入るので、接続先ではない方の拠点の LAN にいるときも同じことが起きる（その LAN のデフォルトゲートウェイに届かなくなり、`Endpoint` 自体も見えなくなってトンネルごと死ぬ）
- **`DNS =` の扱いが wg-quick と違う**: 本書は `DNS =` 無し
  - NetworkManager では `ipv4.dns` になり、接続中は resolv.conf を NetworkManager が書き換えるので、`systemd-resolved` は要らない（未確認）
  - 2026-09-22 の実機は `DNS =` 無しの構成で、`ipv4.dns` は `--`、接続中も `/etc/resolv.conf` は変わらなかった
  - wg-quick は `resolvconf` 経由で resolved が要る（→ [wireguard.md](wireguard.md#dns--を書く場合)）
- **MTU**: `wireguard.mtu 0` のときカーネル既定の 1420（実測）。PPPoE やモバイル回線で大きい通信だけ止まるなら `sudo nmcli connection modify wg0 wireguard.mtu 1380` して down / up（→ [wireguard.md: MTU](wireguard.md#mtu)）
- **全トラフィックを VPN に通す構成は対象外**: NetworkManager 側は `wireguard.ip4-auto-default-route`（`/0` の peer で自動有効）、拠点側は NAT が要る（→ [wireguard.md](wireguard.md#全トラフィックを-vpn-経由にする場合対象外)）
- **`Endpoint` が DDNS 名のとき**: NetworkManager が再解決するかは未確認（→ [wireguard.md](wireguard.md#endpoint-に-ddns-名を書く場合)）。本書の例は IP リテラル
- **サスペンド復帰・Wi-Fi の切り替え**: **2026-09-22 の実機ではどちらも試していない**（セッションを落とさずに確認する手順が無かった）
  - `autoconnect no` のプロファイルをスリープ復帰後に NetworkManager が張り直すかは要確認（張り直さない可能性が高い。復帰後に `nmcli device status` を見る）
  - Wi-Fi が変わっても、WireGuard は送信元の変化に追従するはず（要確認）。`PersistentKeepalive = 25` が NAT の穴を維持する
- **1 台のクライアントは 1 つの拠点だけ**（→ [wireguard.md](wireguard.md#1-台のクライアントは-1-つの拠点にしか接続できない)）。別拠点用は別名のプロファイルを作り、同時には張らない
- **同じ ifname で wg-quick と NetworkManager を併用しない**: `/etc/wireguard/wg0.conf` と NetworkManager の `wg0` を両方置くと、どちらが `wg0` を持つかで衝突する
- **同名クライアントの登録があれば先に `client remove`**: `client add` は同名を拒否する
- **秘密鍵は `nmcli -s` で読める**: PC のログインパスワードが鍵の守りになる
  - root なら常に読める
  - **ローカルのコンソールにログイン中のユーザーは、`sudo` 無しでも読める**（実測。polkit の既定 `allow_active=yes`）
  - 実測の内容: 非 root で `nmcli -s -g wireguard.private-key connection show wg0 | wc -c` が 45 を返し、その値のハッシュは手順 3 で作った `wg0.key` と一致した（アクティブな Wayland セッション、`wheel` 所属のユーザー）
- **GNOME の UI**: NetworkManager のプロファイルなので設定画面から up / down できる可能性があるが未確認
- **Windows 11 の注意点**（どれも Windows では確かめていない）
  - **拠点の LAN 内では張らない**: `AllowedIPs` の経路は、ルートのメトリック 0 で `wg0` に入る（ソースの `tunnel/addressconfig.go`）。LAN の直結の経路（Windows の既定ではルートのメトリック 256）より優先されるはずなので、AlmaLinux 10 と同じく LAN 宛ての通信がトンネルに入る
  - **張ったまま再起動すると、また張られる**: トンネルのサービスは自動で起動する（ソースの `manager/install.go`）。拠点の LAN に戻る前に切る
  - **ほかの端末と同じ名前で登録しない**: [実施手順](#実施手順)の手順 5 は、`CLIENT_NAME` と同じ名前の登録を消す。AlmaLinux 10 の PC と両方使うなら、別々の名前と鍵で登録する
  - **秘密鍵は、管理者なら読める**: 張っている間の `wg.exe show wg0 private-key`、窓の「編集」（設定の全文を出す）と「すべてのトンネルをzipにエクスポート」。WireGuard の窓は Administrators の一員にしか出ない。Windows のサインインのパスワードが鍵の守りになる
  - **WireGuard を外すと、ほかのトンネルの設定も消える**: MSI のアンインストールは `C:\Program Files\WireGuard\Data` を丸ごと消す（ソースの `installer/customactions.c` の `RemoveConfigFolder`）
  - **MTU**: conf に `MTU =` が無いと、既定の経路のインターフェースの MTU から 80 を引いた値になる（1500 なら 1420。WireGuard の文書の「Network Configuration Quirks」）。大きい通信だけ止まるなら、トンネルを切ってから窓の「編集」で `[Interface]` に `MTU = 1380` を足す
  - **`DNS =` を書いた場合**: `wg0` の DNS サーバーになり、Windows の通常の名前解決の扱い（複数の DNS サーバーを使う）に任される。DNS を絞る規則は、キルスイッチが掛かる構成（`/0` の peer が 1 つ）でだけ入る（同じ文書）。本書は `DNS =` 無し
  - **`Endpoint` が DDNS 名のとき**: トンネルを張るたびに名前を引く（ソースの `tunnel/service.go`）。張っている間に相手の IP が変わったときは確かめていない
  - **サスペンド復帰・Wi-Fi の切り替え**: 確かめていない
  - **トンネルの名前はファイル名から決まる**: `wg0.conf` → `wg0`（英数字と `_=+.-` の 32 文字まで。ソースの `conf/name.go`）。サービスの名前は `WireGuardTunnel$wg0`、アダプターの名前も `wg0`

### 参照

- [Chapter 7. Setting up a WireGuard VPN — Configuring and managing networking (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/configuring_and_managing_networking/setting-up-a-wireguard-vpn)（7.10 "Configuring a WireGuard client by using nmcli" は `nmcli connection add` で組む方式）
- [WireGuard VPN 構築手順](wireguard.md)（手順 10〜18、症状と原因の対応、各注意点）
- `man nmcli`（`connection import`。man は「VPN のみ」と書くが WireGuard も読める）
- `man nm-settings-nmcli`（`wireguard` setting: `peers`、`peer-routes`、`mtu`、`ip4-auto-default-route`。`connection.autoconnect`、`ipv4.route-metric`）
- `/usr/share/doc/NetworkManager/NEWS`（1.16 / 1.34 / 1.56 の WireGuard の項）
- `man wg`（cryptokey routing、endpoint roaming）/ `man wg-quick`（`DNS`、`MTU`）
- `/usr/share/polkit-1/actions/org.freedesktop.NetworkManager.policy`（`sudo` を付ける根拠）
- [`scripts/wireguard/wg-vpn.sh`](../scripts/wireguard/wg-vpn.sh) の `render_client_conf` / `cmd_client_add` / `cmd_client_show`
- [WireGuard のインストールのページ](https://www.wireguard.com/install/) — Windows の公式の配布物（`wireguard-installer.exe` と MSI）
- [Enterprise Usage — WireGuard for Windows](https://git.zx2c4.com/wireguard-windows/about/docs/enterprise.md) — `DO_NOT_LAUNCH`、`/installtunnelservice`・`/uninstalltunnelservice`、`.conf.dpapi`、マネージャーが設定の置き場所の `.conf` を暗号化すること、`/update`・`/dumplog`
- [Network Configuration Quirks — WireGuard for Windows](https://git.zx2c4.com/wireguard-windows/about/docs/netquirk.md) — 経路と MTU、キルスイッチの条件、ネットワークの種類（決まった GUID）
- WireGuard for Windows 1.1.1 のソース（`v1.1.1` のタグ）— `installer/wireguard.wxs`・`installer/customactions.c`（MSI）、`main.go`（コマンドライン）、`manager/install.go`・`manager/ipc_server.go`（サービスと、窓の有効化・無効化）、`conf/migration_windows.go`・`conf/filewriter_windows.go`・`conf/path_windows.go`（取り込み・暗号化・アクセス権）、`conf/parser.go`・`conf/name.go`（conf の読み方とトンネルの名前）、`tunnel/addressconfig.go`・`tunnel/service.go`（経路・名前解決）、`updater/`（更新）
- winget-pkgs の `manifests/w/WireGuard/WireGuard/1.1.1/` — `WireGuard.WireGuard` の定義
- wireguard-tools のソースの `src/pubkey.c`・`src/ctype.h` — `wg pubkey` が鍵の後ろの空白（CR を含む）を読み飛ばすこと
- [Get-Clipboard（5.1）— Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-clipboard?view=powershell-5.1) — `-Raw`
- [Windows 11 の初期設定](windows-setup.md) — Windows の PowerShell の貼り付けの設定（前提）と、この文書を通す順番

---

### 付録: 実機での検証記録

2026-09-22、AlmaLinux 10.2 x86_64 のノート PC から拠点 B の WG ホスト（AlmaLinux 10.2 aarch64）へ、手順 1〜15 を本実行した。鍵・グローバル IP・ホスト名・クライアント名はプレースホルダに置き換えてある。

実施時の位置関係が手順書の書きぶりと違う点を先に書く:

- PC は**拠点 A の LAN**にいた。拠点 B の WG ホストへは拠点間トンネル越しに ssh で届く状態だった
- クライアント conf の `AllowedIPs` には**両拠点の LAN** が入るので、拠点 A の LAN にいるままトンネルを張ると自分の LAN 経路を奪う。そこで**手順 10 の前に**スマートフォンのテザリング回線へ移した（検証時の手順書は「トンネルを張る手順（今の手順 11）以降は LAN の外で」としていたが、import 直後に自動で張られるので 1 手順早く移す方が安全。今の手順書はこれに合わせて手順 10 から LAN の外にしている）
- 拠点 B がクライアントを受ける構成（`WG_B_CLIENT_NET` を設定、`WG_A_CLIENT_NET` は空）なので、手順 1 の変数には `WG_B_TUN_IP` / `WG_B_LAN_IP` / `ROUTER_B_LAN_IP` / `WG_A_LAN_IP` を入れ、手順 4 の `SITE` は `B` にした

#### 手順書から変えて実行した点

| 変えた点 | 理由 |
|---|---|
| 手順 4〜6 の WG ホスト側のコマンドを、PC から ssh 越しに実行した | 手順書は WG ホストで直接実行する前提。コマンドと結果は同じ |
| 手順 7 の `vi` への貼り付けの代わりに、`client show` の出力を ssh のリダイレクトで `${WG_DIR}/wg0.conf` に直接書き出した（`umask 077` 付き） | 鍵も conf も端末に出さずに済む。`client show` の出力に秘密は無いので安全性は変わらない |
| `apply` を `systemd-run` で切り離して実行した | 次節 |

#### 落とし穴: `apply` は作業中の ssh 経路そのものを切る

`wg-vpn.sh` の `apply` は最後に必ず `systemctl restart wg-quick@wg0` する（reload では経路が変わらないため）。**トンネル越しに WG ホストへ ssh して作業していると、その restart が自分のセッションの足元を切る**。切り離して実行した:

```
sudo systemd-run --unit=wg-apply-rw -p Type=oneshot \
  /bin/bash <REPO>/scripts/wireguard/wg-vpn.sh -e <ENV_FILE> apply B
```

- **`/bin/bash` を挟むのが必要**。スクリプトのパスを直接 `systemd-run` に渡すと `Failed at step EXEC spawning …: Permission denied`（`status=203/EXEC`）で失敗する。ホームディレクトリが `0700` で systemd が実行ファイルを解決できないため。SELinux の AVC は出ない（`ausearch -m AVC -ts recent` が `<no matches>`）ので、ラベルの問題と誤診しないこと
- 結果は `journalctl -u wg-apply-rw` で読む。終了状態は `systemctl show wg-apply-rw -p Result -p ExecMainStatus`
- 実測では restart 後、ssh は**1 回目の再接続で復帰**し、拠点間トンネルのハンドシェイクも 23 秒以内に再確立した。とはいえ切れたまま戻らない場合に備えて、LAN 側の ssh やコンソールなど別の経路を用意しておく

#### 手順ごとの実測

**手順 2**: `wireguard-tools-1.0.20250521-1.el10` の 1 パッケージに対し、依存で `systemd-resolved-257-23.el10_2.2.alma.1` が入る（2 パッケージ、437 k）。導入後も `systemctl is-enabled systemd-resolved` は `disabled`、`is-active` は `inactive` のまま。`modinfo -n wireguard` はカーネル同梱モジュールのパスを返す。

**手順 3**: `wg0.key` / `wg0.pub` とも `-rw-------` の 45 バイト。

**手順 4〜6**: `client add` は `==> クライアント <CLIENT_NAME> を登録しました（拠点 B、<CLIENT_TUN_IP>）` と `==> クライアント用 conf を書き込みました: /etc/wireguard/clients/<CLIENT_NAME>.conf` を出し、`conf の PrivateKey は <CLIENT_PRIVATE_KEY> のままです` と続ける。トンネル IP は登録簿の空きから最小のものが自動で割り当てられた。

- `--dry-run apply B` で予定を見ると、変わるのは `/etc/wireguard/wg0.conf` に `[Peer] # Client <CLIENT_NAME>` が 1 つ増えるところだけ。firewalld は `--reload` のみ（port / interface / forward は既に入っている）。LAN 側ゾーンは WG ホストの LAN 側 NIC から `public` を自動検出
- `apply B` は既存の conf を `wg0.conf.bak-<日時>` に退避してから書き直し、`wg-quick@wg0` を再起動する。実行後の `wg show` で peer が 1 つ増えた
- **restart の副作用**: 既存クライアントの `LAST_HANDSHAKE` が `なし` に戻る（peer を作り直すため、接続が無ければ再度つながるまで表示されない）
- **登録簿の列ずれ**: `client add` は `printf '%-12s'` で書くので、13 文字以上の名前だと `clients.list` の列が揃わない。空白区切りなので `awk` での読み取りには影響しない

**手順 7〜8**: `grep -c '^PrivateKey = [A-Za-z0-9+/]\{43\}=$'` が `1`。他の行は `client show` の出力のまま。

**手順 10**: `import` は `Connection 'wg0' (<UUID>) successfully added.` の 1 行だけを出す。

- **その直後**に `connection show` を見ると `wg0  wireguard  wg0  activating  yes`、`device status` は `connecting (checking IP connectivity)`。`ip -4 route show` には既に `AllowedIPs` の 3 経路が `proto static scope link metric 50` で入っている（＝**未確認事項 2 と 3 はここで同時に確定した**）
- `connection.autoconnect no` の後は `activated  no`。`down` すると 3 経路とも消える
- `connection show wg0` の値: `connection.id` / `connection.interface-name` とも `wg0`、`connection.zone` は `--`、`ipv4.method` は `manual`、`ipv4.addresses` は `<CLIENT_TUN_IP>/32`、`ipv4.dns` は `--`、`ipv4.route-metric` は `-1`、`ipv6.method` は `disabled`、`wireguard.peer-routes` は `yes`、`wireguard.mtu` は `0`、`wireguard.private-key` は `<hidden>`
- `wireguard.peers` は 1 行に `<SITE_B_PUBKEY> allowed-ips=<SITE_A_LAN>;<SITE_B_LAN>;<WG_TUNNEL_NET> endpoint=<SITE_B_PUBLIC>:<WG_PORT> persistent-keepalive=25` まで出る
- keyfile は `-rw------- root root` の 477 バイト、SELinux ラベルは `system_u:object_r:NetworkManager_etc_rw_t:s0`

**手順 11**: `up` の直後、`device status` は `wg0  wireguard  connected  wg0`、MTU は `1420`。

- `IP4.ROUTE[1..3]` はいずれも `mt = 50`。経路全体で見ると、テザリングの `default` と直結経路が metric 600 なので、**拠点 LAN 宛てだけがトンネルに入る**
- `wg show wg0` の `listening port` はランダム（NetworkManager は `wireguard.listen-port 0` のまま）。この時点では `latest handshake` の行がまだ無く、`transfer: 0 B received, 148 B sent`。**最初のハンドシェイクは手順 12 の通信で起きる**
- `firewall-cmd --get-active-zones` の `public (default)` の `interfaces` に `wg0` が加わる
- `/etc/resolv.conf` は手順 2 の前と同じ。`ausearch -m AVC -ts recent` は `<no matches>`
- 細かい点: `nmcli -f GENERAL.STATE,IP4.ADDRESS,IP4.ROUTE,IP4.DNS connection show wg0` では `IP4.ADDRESS` の行が出ない。`nmcli -f IP4 connection show wg0` なら `IP4.ADDRESS[1]: <CLIENT_TUN_IP>/32` が出る

**手順 12〜13**: 4 段階すべて `0% packet loss`。

| 宛先 | 結果（rtt avg） |
|---|---|
| `<WG_HOST_TUN_IP>`（接続先拠点の WG ホストの `wg0`） | 26 ms |
| `<WG_HOST_LAN_IP>`（同じホストの LAN 側） | 23 ms |
| `<ROUTER_LAN_IP>`（接続先拠点のルーター） | 23 ms |
| `<PEER_WG_LAN_IP>`（**相手拠点**の WG ホスト） | 46 ms |

- `tracepath -n <PEER_WG_LAN_IP>` は `pmtu 1420` で `1: <WG_HOST_TUN_IP>` → `2: <PEER_WG_LAN_IP>`
- WG ホスト側の `client list` で `LAST_HANDSHAKE` が `35 秒前`、逆方向の `ping <CLIENT_TUN_IP>`（拠点 → PC）も `0% packet loss`。PC 側の firewalld は既定の `public` のままで ping に応答した
- **トンネル越しの ssh** で WG ホストに入れた（`SSH_CONNECTION` の送信元が `<CLIENT_TUN_IP>`）。新レイアウト（`wg0` を LAN 側ゾーンに入れる）では、ホスト自身宛ての ssh も LAN と同じ扱いになるため（→ [wireguard.md](wireguard.md#トンネル越しに-wg-ホスト自身の-ssh-や-cockpit-へ入る場合)）
- 追加で確認したこと: **相手拠点のルーター**（`<ROUTER_A_LAN_IP>`、WG ホストではない LAN 上の機器）への ping も通り、接続先拠点の `445/tcp`（Samba）へも TCP が張れた。クライアント → 接続先拠点 → 拠点間トンネル → 相手拠点 LAN の折り返しが実際に動いている

**手順 14**: `down` の直後に `ip link show dev wg0` が `Device "wg0" does not exist.`（終了コード 1）。経路 3 本と firewalld の `wg0` も消える。プロファイルは `wg0  wireguard  --  --` で残る。

**手順 15**: `${WG_DIR}` に `wg0.pub` だけが残る。

#### 確認できたこと（この文書を書いた時点の「未確認事項」1〜9）

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

加えて、[注意点](#注意点)に書いていた「非 root で秘密鍵が読める」も確認した。アクティブなローカルセッション（Wayland、`wheel` 所属）の非 root ユーザーで `nmcli -s -g wireguard.private-key connection show wg0 | wc -c` が `45` を返し、その値のハッシュは手順 3 で作った `wg0.key` と一致した。

#### 残っている未確認事項

1. `Endpoint` が DDNS 名のときの再解決（今回の `site.env` は生のグローバル IP）
1. サスペンド復帰後・Wi-Fi 切り替え後にトンネルが戻るか（作業セッションを落とさずに確認する手立てが無く、実施していない）
1. GNOME の設定画面・クイック設定に出るか（`connection.type` は `vpn` ではなく `wireguard`）
1. `DNS =` がある構成での resolv.conf の扱い（今回は `DNS =` 無し）
1. 有効なインターフェース名 + `.conf` でないファイル名を `import` が拒否するか
1. **拠点の LAN の中からトンネルを張ったときの挙動**（metric 50 の経路が LAN の直結経路を奪うことが確定したので、意図的に試していない）
1. [代替: wg-quick](#代替-wg-quick-で張る場合) と [代替: nmcli connection add](#代替-nmcli-connection-add-で組む場合rhel-のドキュメントの方式) は未検証のまま
1. クライアント同士（`wg0 → wg0` の折り返し）の疎通。今回はクライアントが 1 台しか接続していない

#### 記録用ブロック（再検証するとき、手順 2 の前に PC で）

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

### 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物とソースと資料を読んだ記録。

#### リリースのファイル

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

#### MSI の署名と中身

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

#### winget の定義（`WireGuard.WireGuard` 1.1.1）

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

#### ソース（`v1.1.1` のタグ）と文書

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

#### そのほかのソース

- wireguard-tools の `src/pubkey.c` と `src/ctype.h`（2026-10-03 の master）: `wg pubkey` は鍵の 44 文字を読んだ後、`char_is_space` に当たる文字（タブ・LF・VT・FF・CR・空白）と NUL を読み飛ばし、ほかの文字があれば `Trailing characters found after key` で止まる
- PowerShell の `src/System.Management.Automation/engine/NativeCommandProcessor.cs`（2026-10-03 の master）: パイプラインの最後にある GUI のプログラムは終わるのを待たず、後ろにパイプでつないだときは待つ。Windows PowerShell 5.1 も同じ作りのはず（確かめていない）

---

### 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-03）

Linux（クラウドのコンテナ）の PowerShell 7.6.6 と PSScriptAnalyzer 1.25.0 で確かめた（[hackgen.md](hackgen.md) の付録と同じ環境）。この付録の手順の番号は、[Windows 11 で使う](#windows-11-で使う)のもの。

**構文と Windows PowerShell 5.1 との互換**:

- Windows 11 の 3 節の `powershell` のブロック 18 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0。ほかの規則の指摘は、手順 2 の 4 つの変数をそのブロックの中では使っていないことへの 4 つだけ（手順 13 で使う）

**模擬の実行**（パスの `\` を `/` に替え、`$env:ProgramFiles`・`$env:USERPROFILE` を一時的なディレクトリにして流した。`wg.exe` は Linux の `wg`〔wireguard-tools 1.0.20210914〕へのリンク、`icacls.exe` は引数を記録するだけの偽物）:

- 手順 6: `wg0.key` と `wg0.pub` が 45 バイトで書かれ、`wg pubkey < wg0.key` が `wg0.pub` と一致した。`icacls.exe` には `<置き場所> /inheritance:r /grant *S-1-5-32-544:(OI)(CI)F /grant *S-1-5-18:(OI)(CI)F` が渡った。2 回目は `中断: wg0.key が既にある…` で止まった
- Linux の `wg pubkey` は、`<鍵>\r\n` を渡しても `<鍵>\n` と同じ公開鍵を出した（`<鍵>\r\nx` は `Trailing characters found after key`）
- 手順 9: `Get-Clipboard` を、決めた文字列を返す偽物にした
  - `client show` の形（CR LF、`PrivateKey` の行の末尾に空白、先頭に空行）から、`1` と残りの行が出て、`wg0.conf` の `PrivateKey` が `wg0.key` の鍵になり、ほかの行は変わらなかった（CR LF の 11 行、ASCII）
  - 先頭にプロンプトの行があるもの・`PrivateKey` の行が 2 つあるもの・ASCII でない文字を含むもの・空のものは、それぞれの `中断:` で止まり、`wg0.conf` を作らなかった
- 手順 9 で書いた `wg0.conf` を、WireGuard for Windows 1.1.1 の `conf/parser.go`・`config.go`・`name.go` を Linux でビルドできるように写したもの（Windows だけの部分を外した）で読んだ
  - `Address`・`AllowedIPs` の 3 つ・`Endpoint`・`PersistentKeepalive = 25` が読めた
  - 先頭に UTF-8 の BOM を付けると `Line must occur in a section: "﻿[Interface]"` で読めず、UTF-16 LE（BOM 付き）にすると読めた
  - `PrivateKey = <CLIENT_PRIVATE_KEY>` のままだと `Invalid key` で読めなかった。トンネルの名前 `win laptop` と `CON` は `Tunnel name is not valid`
- 手順 10: `Get-Service` を偽物にし、マネージャーの代わりに、写された `.conf` を 2 秒後に（上の読み込みで読めたら）`.conf.dpapi` に変えて元を消すスクリプトを動かした
  - `wg0.conf.dpapi` の 1 行が出た
  - もう 1 度貼ると `中断: wg0 というトンネルが既にある`、マネージャーが `Stopped` なら `中断: WireGuard のマネージャーが動いていない…` で止まった
  - 読めない conf（`PrivateKey` がプレースホルダのまま）では、30 秒待ってから、`wg0.conf` が残った一覧を出した
- 手順 12・15: `wireguard.exe` を、引数を記録して印のファイルを作る・消す偽物にし、`Get-Service` と `Get-Net*`・`Get-DnsClientServerAddress` を偽物にした
  - 手順 12 は表を順に出した。印が残ったままもう 1 度貼ると、偽物が標準エラーに書いた `Error: Tunnel already installed and running` が文字で出た
  - 手順 15 は、偽物が 2 秒後に印を消すまで待ってから、何も出さずに終わった
- 手順 13: 偽物の `ping.exe`（日本語の Windows の出力を真似たもの）と `tracert.exe` で、4 つの宛先の最後の 3 行と、`tracert.exe -d -h 5 -w 2000 <PEER_WG_LAN_IP>` が出た。変数が空なら `手順 2 の変数が空のまま` で止まった
- 手順 16 と[Windows 11 のロールバック](#windows-11-のロールバック)の手順 1
  - 手順 16 の後は `wg0.pub` だけが残った
  - ロールバックの手順 1 は、トンネルの印があれば `/uninstalltunnelservice wg0` を渡し、`wg0.conf.dpapi` と置き場所を消して `False` を出した。置き場所にほかのファイル（`notes.txt`）があると、それを残して `True` を出した
- PowerShell 7 は、Linux ではパイプの改行が LF で、ネイティブのコマンドの `2>&1` の扱いも Windows PowerShell 5.1 と同じではない。winget・`Get-AuthenticodeSignature`・本物の `Get-Net*` と `wireguard.exe` を使うブロック（手順 3〜5、手順 12・15 の本当の動き、更新、ロールバックの手順 2）は流せていない

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

### 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を ISO から入れた x86_64 VM をクライアントにし、別の 2 VM で wireguard.md の WG ホストを構築した。SELinux Enforcing、NetworkManager 1.56.0、カーネル `6.12.0-211.61.1.el10_2.x86_64`。一般ユーザーの SSH PTY から現行ブロックを実行した。

- 手順 1〜3 でツールと、0600 のクライアントの鍵ペアができた。WG ホストの手順 4・6 はこの公開鍵で通し、conf は公開鍵とプレースホルダだけの状態でクライアント VM へファイル転送した（手順 7 の vi の操作は行っていない）
- 初回のホストの apply は終了 141 で止まった。IP を調べるパイプの SIGPIPE を修正し、登録の無い状態から手順 6 を再実行すると、登録・apply・conf 表示まで通った（[原因と修正](wireguard.md#間欠的な終了-141-の原因と修正)）
- クライアントの手順 8 で秘密鍵の行だけが置き換わった。手順 10 の新規 import 直後は activated、autoconnect を no にして切断できた。日本語ロケールの表示は「アクティベート済み」「いいえ」
- 手順 11 の up で 3 経路（metric 50）・MTU 1420・ハンドシェイク・送受信・public の wg0 が確認できた。resolved は有効にしていない。末尾の `ausearch` は `<no matches>`（この場合の終了コードは 1）
- 接続先の wg0・両 WG ホストの LAN IP・両 LAN の namespace に ping が通り、namespace からクライアントへの逆方向も双方向 0% 損失。相手 LAN への tracepath は `10.99.0.1` → `10.99.0.2` → 相手 LAN の 3 ホップ、TCP の HTTP も 200
- LAN の namespace の試験用 veth は firewalld に明示している。WG ホストの設定を再適用すると firewalld が reload するため、試験の veth は permanent にも入れた。追加前は仮想ルーターへの ping だけが拒否され、追加後に通った
- 手順 14・15 の down と平文鍵/conf の削除、ロールバック 1 のプロファイル・公開鍵・作業ディレクトリの削除、ロールバック 2 の対話でのパッケージ削除が通った。wireguard-tools と、この試験で依存として入った resolved が消えた

Endpoint は隔離された仮想 LAN であり、テザリング回線、実ルーター、Wi-Fi 切り替え、サスペンド復帰の検証ではない。クライアント VM の再起動は今回行っていないので、autoconnect no の読み戻しを再起動時の実証とはしていない。Windows の節は今回の確認に含めていない。
