# WireGuard Road Warrior 設定手順（AlmaLinux 10 クライアント / NetworkManager + nmcli）

## 実施手順

> [!IMPORTANT]
> - **PC で実行する**。手順 4 と手順 8 の後半だけ WG ホストで実行する
> - **手順 6 以降は拠点の LAN の外で行う**（スマートフォンのテザリングなど）

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 戻すときは[ロールバック](#ロールバック)

1. **変数を設定する**

   - 編集が必須なのは、次の 1 行ずつの 4 ブロック
   - **`sudo -i` した root のシェルではなく、自分のシェルで貼る**。`~` が自分のホームになるため

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

   鍵と conf の一時置き場は既定のままでよい:

   ```bash
   WG_DIR=~/wg-client                   # 鍵と conf の一時置き場（手順 10 で秘密鍵と conf を消す）
   ```

   値を読み戻して確かめる。

   ```bash
   for v in WG_HOST_TUN_IP WG_HOST_LAN_IP ROUTER_LAN_IP PEER_WG_LAN_IP WG_DIR; do
     printf '%-15s = %s\n' "$v" "${!v}"
   done
   ```

   - 例の値は拠点 A がクライアントを受ける構成のもの。拠点 B が受ける構成なら、`site.env` の `*_B_*` 側の値が入っていること
   - **既定値のままでもエラーにならない**ので、4 つの IP を書き換えたか必ずここで確かめる
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**（SSH を張り直したあとも）、上のブロックを貼り直してから先へ進む

   <details>
   <summary>補足: 変数について</summary>

   - 変数名は PC 視点（`WG_HOST_*` = 接続先拠点、`PEER_*` = 相手拠点）
   - 拠点 B がクライアントを受ける構成なら、`site.env` の `WG_B_TUN_IP` / `WG_B_LAN_IP` / `ROUTER_B_LAN_IP` と `WG_A_LAN_IP` を入れる
   - `WG_DIR` を WG ホストの `~/wg`（`site.env` と `clients.list` の置き場）と別の名前にしてあるのは、同じ人が両方のマシンを触るときに、ロールバックの `rm` を取り違えても登録簿が消えないようにするため

   </details>

1. **パッケージのインストール**

   ```bash
   sudo dnf install -y wireguard-tools
   rpm -q wireguard-tools NetworkManager systemd-resolved
   systemctl is-enabled systemd-resolved         # disabled（依存で入るだけ。本手順では有効にしない）
   modinfo -n wireguard                          # カーネル同梱のモジュールのパスが出る
   ```

   <details>
   <summary>補足: パッケージ</summary>

   - `wireguard-tools` は `wg` / `wg-quick` と、依存の `systemd-resolved` を入れる
   - `systemd-resolved` は有効にしない。有効にすると NetworkManager の DNS 処理が resolved 経由に切り替わる（`DNS =` を使わない本手順では不要）
   - `modinfo -n` はモジュールの存在確認だけで、ロードは `nmcli connection up` の時点で NetworkManager が行う

   </details>

1. **鍵ペアの生成**

   秘密鍵は `wg0.key` に書き、端末には表示しない。

   ```bash
   if [ -e "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.key" ]; then echo '中断: wg0.key が既にある（作り直すなら先に消す。WG ホストに登録済みの公開鍵と対応しなくなる）' >&2; else
     mkdir -p "${WG_DIR}" && chmod 700 "${WG_DIR}" &&
     ( umask 077; wg genkey | tee "${WG_DIR}/wg0.key" | wg pubkey > "${WG_DIR}/wg0.pub" ) &&
     ls -l "${WG_DIR}/wg0.key" "${WG_DIR}/wg0.pub" &&           # どちらも -rw------- で 45 バイト
     cat "${WG_DIR}/wg0.pub"                                     # この 1 行（公開鍵）を WG ホストへ渡す。秘密鍵（.key）は渡さない
   fi
   ```

   - 表示された公開鍵（44 文字）だけを、手順 4 で WG ホストに渡す

   <details>
   <summary>補足: 鍵ペア</summary>

   - `umask 077` で `wg0.key` / `wg0.pub` を 0600 にする
   - `tee` で秘密鍵をファイルに落としつつ `wg pubkey` に流すので、秘密鍵は端末に出ない
   - `wg genkey` / `wg pubkey` はカーネルモジュール無しで動く
   - 既に `wg0.key` があるときに中断するのは、上書きするとホストに登録済みの公開鍵と対応しなくなるため

   </details>

1. **WG ホストに公開鍵を登録する（WG ホストで実行）**

   **ここだけ WG ホストのシェルで実行する。** 別のシェルなので、先頭で変数を設定し直す。

   - 編集が必須なのは、1 行ずつの 3 ブロック
   - [wireguard.md の手順 1](wireguard.md#実施手順) の `REPO` と `~/wg/site.env` がある前提

   ```bash
   SITE=A                               # クライアントを受ける拠点（A または B）
   ```

   ```bash
   CLIENT_NAME=laptop                   # 登録簿（clients.list）に載せる名前。英数字・-・_ のみ
   ```

   ```bash
   CLIENT_PUBKEY=                       # 手順 3 で PC に表示された公開鍵（44 文字）を貼る
   ```

   clone 先が `~/setup-notes` なら既定のままでよい:

   ```bash
   REPO=~/setup-notes                   # WG ホスト上でこのリポジトリを clone した場所（wireguard.md の手順 1 と同じ）
   ```

   登録済みのクライアントを確認する:

   ```bash
   cd "${REPO:?REPO が空のまま}/scripts/wireguard" && ./wg-vpn.sh -e ~/wg/site.env client list
   ```

   登録簿は名前で一意なので、**`CLIENT_NAME` と同じ名前が一覧にあるときだけ**次のブロックを貼って消す。

   - 無ければ「登録されていません」で止まる
   - `apply` は、その次の登録のブロックでまとめて行う

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env client remove "${CLIENT_NAME:?CLIENT_NAME が空のまま}"
   ```

   公開鍵で登録し、ホストに反映して、クライアント用 conf を表示する。

   - **注意**: トンネル越しに WG ホストへ ssh して作業している場合、`apply` の restart で自分のセッションが切れる（→ [落とし穴](#落とし穴-apply-は作業中の-ssh-経路そのものを切る)。切り離して実行する方法もそこにある）

   ```bash
   if [ -z "${CLIENT_PUBKEY}" ]; then echo '中断: CLIENT_PUBKEY が空のまま。手順 3 の公開鍵を入れて貼り直す' >&2; else
     cd "${REPO:?REPO が空のまま}/scripts/wireguard" &&
     sudo ./wg-vpn.sh -e ~/wg/site.env client add "${SITE:?SITE が空のまま}" "${CLIENT_NAME:?CLIENT_NAME が空のまま}" --pubkey "${CLIENT_PUBKEY}" &&
     sudo ./wg-vpn.sh -e ~/wg/site.env apply "${SITE}" &&
     sudo ./wg-vpn.sh -e ~/wg/site.env client show "${CLIENT_NAME}"      # この出力を PC へ持っていく（秘密鍵は含まれない）
   fi
   ```

   - `client show` の出力を、端末からコピーして PC に持っていく
   - `PrivateKey` はプレースホルダのままなので、**秘密情報を含まない**

   `client show` が表示する内容:

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

   <details>
   <summary>補足: WG ホストでの登録</summary>

   - `client add` は同じ名前・同じ公開鍵・同じトンネル IP を拒否する（`wg-vpn.sh` の `cmd_client_add`）
   - `--pubkey` で登録した conf の `PrivateKey` は、文字列 `<CLIENT_PRIVATE_KEY>` のまま書かれる（`client add` の末尾にもその旨が出る）
   - `apply` は `wg0.conf` を作り直して `systemctl restart` するので、他のクライアントと拠点間トンネルが数秒切れる（`reload` では経路が入らない。→ [落とし穴 2](wireguard.md#落とし穴-2-reload-では経路が追加されない)）
   - `apply` の末尾に出るルーターの設定（クライアント帯の静的経路）は、既に入っていれば変更不要
   - トンネル IP は帯の中で最小の空きが割り当たる（`--ip` で指定できる）

   </details>

1. **conf を PC に置き、秘密鍵を入れる**

   手順 4 の `client show` の出力を、端末からコピーして `vi` に貼る。

   ```bash
   ( umask 077; vi "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.conf" )    # 手順 4 の client show の出力をそのまま貼って保存する
   ```

   - **ファイル名は `wg0.conf` にする。** NetworkManager がファイル名から接続名とインターフェース名を決める（実測で確認 → この手順の補足）
   - ファイルで渡すなら、WG ホストで `client show` の出力をファイルに書き出し（秘密鍵は入っていないので平文でよい）、`scp` で `${WG_DIR}/wg0.conf` に置く

   `PrivateKey` 行だけを手順 3 の秘密鍵に置き換える（鍵は表示しない）:

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

1. **NetworkManager に取り込む**

   **この手順から拠点の LAN の外で行う。**

   - `import` した直後に、NetworkManager が `wg0` を**自動で張る**（`connection.autoconnect` の既定が `yes` のため）。張られた時点で拠点 LAN 宛ての経路が入れ替わる
   - **注意**: LAN 内で次のブロックを貼ってしまうと、そこで通信が切れて、その後のブロックを貼れなくなる。その場合は PC のコンソールで `sudo nmcli connection down wg0`

   ```bash
   sudo nmcli connection import type wireguard file "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.conf" &&
   sudo nmcli connection modify wg0 connection.autoconnect no &&
   nmcli -f NAME,TYPE,DEVICE,STATE,AUTOCONNECT connection show | grep -E '^(NAME|wg0 )'    # STATE は activated（import 直後に張られる）。AUTOCONNECT は no
   ```

   次のブロックで即座に切る:

   ```bash
   nmcli -t -f NAME,STATE connection show | grep -qx 'wg0:activated' && sudo nmcli connection down wg0    # 張られていたら切る（手順 7 で改めて張る）
   ```

   プロファイルの内容と、秘密鍵の保存先を確認する:

   ```bash
   nmcli -f connection.id,connection.interface-name,connection.autoconnect,connection.zone,ipv4.method,ipv4.addresses,ipv4.dns,ipv6.method,wireguard connection show wg0
   sudo ls -l /etc/NetworkManager/system-connections/wg0.nmconnection     # -rw------- root root。秘密鍵はこの中（表示はしない）
   ```

   見るところ:

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

1. **トンネルを張る**

   **拠点の LAN の外で行う。**

   ```bash
   sudo nmcli connection up wg0 &&
   nmcli device status | grep -E '^(DEVICE|wg0 )' &&                            # wireguard  connected  wg0
   nmcli -f GENERAL.STATE,IP4.ADDRESS,IP4.ROUTE,IP4.DNS connection show wg0 &&   # activated。IP4.ROUTE に AllowedIPs の 3 経路（mt = 50）
   ip -4 route show dev wg0 &&                                                  # 同じ 3 経路と metric
   ip link show dev wg0 | grep -o 'mtu [0-9]*' &&                               # 1420
   sudo wg show wg0                                                             # latest handshake が数秒前、transfer の received が 0 でない
   ```

   ```bash
   sudo firewall-cmd --get-active-zones           # wg0 が既定ゾーン public に入る
   cat /etc/resolv.conf                           # 手順 2 の前と同じ（DNS = が無いので変わらない）
   sudo ausearch -m AVC -ts recent                # <no matches>
   ```

   <details>
   <summary>補足: up</summary>

   - `GENERAL.STATE` / `IP4.ROUTE[n]: dst = …, nh = …, mt = …` の書式は、NetworkManager 1.56 で確認済み
   - `mt` の値（WireGuard デバイスの既定 metric）は **50**（実測。`ipv4.route-metric` は `-1` のままなので、これは WireGuard デバイスの既定）。Wi-Fi の 600 より優先される（→ [注意点](#注意点)）
   - `wireguard.peer-routes yes` が `AllowedIPs` の経路を入れる（`nm-settings-nmcli(5)`）。`ip4-auto-default-route` は `/0` の peer が無いので関係ない
   - MTU は `wireguard.mtu 0` のときカーネル既定の 1420 になる（実測）。`wg-quick` と違い NetworkManager は経路から MTU を計算しない
   - `wg show` の `listening port` はランダム（`wireguard.listen-port 0`）。`latest handshake` が出ない場合は、鍵の対応（ホストの `clients.list` と `wg0.pub`）、`Endpoint`、ルーターのポート転送を疑う

   </details>

1. **疎通確認**

   **PC で。** トンネル IP → WG ホストの LAN 側 → ルーター → 相手拠点の順に試す。

   ```bash
   for h in "${WG_HOST_TUN_IP:?手順 1 の変数が空のまま}" "${WG_HOST_LAN_IP:?}" "${ROUTER_LAN_IP:?}" "${PEER_WG_LAN_IP:?}"; do
     echo "== $h"; ping -c 3 -W 2 "$h" | tail -2
   done
   tracepath -n "${PEER_WG_LAN_IP:?}"             # <WG_HOST_TUN_IP> → <PEER_WG_LAN_IP> の順に出る
   ```

   - 相手拠点の LAN 上の別のホストへの `ping`、トンネル越しの `ssh <ユーザー>@<WG_HOST_LAN_IP>` も試しておくとよい
   - どこで止まるかで、疑う場所が変わる（→ この手順の補足）

   **WG ホストで**（手順 4 のシェル）。ハンドシェイクと、**逆方向**（拠点 → PC）を確認する:

   ```bash
   cd "${REPO:?REPO が空のまま}/scripts/wireguard" &&
   sudo ./wg-vpn.sh -e ~/wg/site.env client list &&                                        # LAST_HANDSHAKE が「N 秒前」
   CLIENT_TUN_IP=$(awk -v n="${CLIENT_NAME:?CLIENT_NAME が空のまま}" '$1 == n { print $3 }' ~/wg/clients.list) &&
   ping -c 3 "${CLIENT_TUN_IP:?clients.list にその名前が無い}"                              # 拠点 → PC（PC の public ゾーンは ping に応答する）
   ```

   - 接続先拠点の LAN 上の別のホストから `ping <CLIENT_TUN_IP>` も通る（ルーターにクライアント帯の静的経路がある前提）
   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](wireguard.md#症状と原因の対応実測)

   <details>
   <summary>補足: 疎通確認</summary>

   4 段階の意味:

   - (1) `<WG_HOST_TUN_IP>` はトンネルそのもの（届かなければハンドシェイクか `AllowedIPs`）
   - (2) `<WG_HOST_LAN_IP>` は WG ホスト自身の LAN 側（届かなければ `AllowedIPs` に拠点 LAN が無い）
   - (3) ルーターは `wg0 → LAN` の転送と、ルーターのクライアント帯の静的経路
   - (4) 相手拠点の WG ホストは、拠点間トンネルと相手ホストの `AllowedIPs`（クライアント帯）

   → [wireguard.md: 手順 5 の補足](wireguard.md#実施手順)、[症状と原因の対応](wireguard.md#症状と原因の対応実測)。トンネル越しの ssh は [WG ホスト自身の ssh へ入る場合](wireguard.md#トンネル越しに-wg-ホスト自身の-ssh-や-cockpit-へ入る場合)。

   </details>

1. **トンネルを切る・日常の使い方**

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

1. **平文の鍵と conf を消す**

   秘密鍵は手順 6 で NetworkManager のプロファイルに入っているので、平文のファイルを残さない（`wg0.pub` は公開鍵なので残してよい）。

   ```bash
   rm -f "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.key" "${WG_DIR}/wg0.conf" &&
   ls -l "${WG_DIR}"                                       # wg0.pub だけ残る
   ```

   <details>
   <summary>補足: 後片付け</summary>

   後片付けを最後にしているのは、import に失敗したときに `sudo nmcli connection delete wg0` → 手順 6 をやり直すのに conf が要るため。秘密鍵は手順 6 の時点で NetworkManager の keyfile に入っている。

   **ガードの確認**（2026-09-22、この文書を書いた WG ホストで）:

   - 各ブロックを `PATH` を空にした bash に変数が空のまま流し、値を使うブロックはすべて先頭のガードで止まって、ファイルを作る・書き換える・消すコマンドの起動が 1 つも試みられないことを確認した
     - 起動が試みられたのは、値を含まない読み取り系と、意図どおりの `nmcli connection up` / `down` / `delete` だけ
   - 手順 3 と手順 5 のブロックは、一時ディレクトリで本物の `wg` / `sed` を使って実行し、次を確認した
     - 鍵が 0600 で作られる
     - `PrivateKey` 行だけが 44 文字の鍵に置き換わり、他の行が変わらない
     - `PrivateKey` 行が 2 行あるときと `wg0.key` が無いときに、中断してファイルが変わらない

   </details>

---

## ロールバック

**PC で、手順 1 の変数を設定したシェルで貼る**（`WG_DIR` が空だと `${WG_DIR:?…}` で止まる）。

> [!CAUTION]
> 次のブロックは、秘密鍵の置き場所である NetworkManager のプロファイル `wg0` を消す。鍵のバックアップは取っていないので、消した鍵は取り戻せない（[選択した方針](#選択した方針)）。

```bash
sudo nmcli connection down wg0 2>/dev/null; sudo nmcli connection delete wg0
rm -f "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.key" "${WG_DIR}/wg0.conf" "${WG_DIR}/wg0.pub" && rmdir "${WG_DIR}"
sudo ls /etc/NetworkManager/system-connections/             # wg0.nmconnection が無い
```

- `rm -rf` を使わないのは、`WG_DIR` を WG ホストの `~/wg` と取り違えて貼っても登録簿を消さないため

パッケージも消すなら:

```bash
sudo dnf remove wireguard-tools     # 依存で入った systemd-resolved も一緒に消える（dnf.conf の clean_requirements_on_remove=True）。トランザクション表を見てから y
```

WG ホストで（手順 4 の変数を設定したシェルで）:

```bash
cd "${REPO:?REPO が空のまま}/scripts/wireguard" &&
sudo ./wg-vpn.sh -e ~/wg/site.env client remove "${CLIENT_NAME:?CLIENT_NAME が空のまま}" &&
sudo ./wg-vpn.sh -e ~/wg/site.env apply "${SITE:?SITE が空のまま}"
```

- ルーターの静的経路（クライアント帯）は、他のクライアントも使うので触らない

---

## 補足

### 対象と検証環境

- **目的**: [WireGuard VPN 構築手順](wireguard.md)で建てた拠点の WG ホストに、外出先の AlmaLinux 10 ノート PC から接続し、両拠点の LAN に届くようにする
  - 鍵は PC で作り、**公開鍵だけ**を WG ホストに登録する
  - トンネルは NetworkManager のプロファイル `wg0` として持ち、`nmcli connection up wg0` / `down wg0` で張る・切る（`wg-quick` は使わない。→ [代替](#代替-wg-quick-で張る場合)）
- **進め方**: **冒頭の変数ブロックに値を 1 度書き、以降のコマンドをそのまま貼る**
  - 手順 4 と手順 8 の後半だけは WG ホスト上で実行する（そのブロックの先頭にも変数がある）
  - WG ホスト側は `wg-vpn.sh` の `client add --pubkey` → `apply` → `client show` で、[wireguard.md の手順 4](wireguard.md#実施手順) と同じ
- **状態**: **実機で本実行済み（2026-09-22）**
  - 拠点 A の LAN にあるノート PC を**スマートフォンのテザリング回線に移してから**、拠点 B の WG ホストへ手順 1〜10 を通した
  - 確認したこと: 両拠点の LAN への ping、トンネル越しの ssh、拠点側からの逆方向 ping
  - NetworkManager の挙動として推定で書いていた項目は、1〜9 が実測で確定した
  - **確認していないこと**: サスペンド復帰・Wi-Fi の切り替え・`Endpoint` が DDNS 名のとき・GNOME の UI・`DNS =` がある場合など（→ [残っている未確認事項](#残っている未確認事項)）
  - **拠点の LAN の中からトンネルを張ることは、意図的に試していない**（[注意点](#注意点)のとおり LAN の経路を奪うため）
  - 実測の記録は[付録](#付録-実機での検証記録)

下表は実機（PC 側）で採取した値。

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

![構成](diagrams/wireguard-remote-client.svg)

図の Remote client が本書の PC。接続先拠点（図では拠点 A）の WG ホストにトンネルを張り、拠点 A・B の LAN に届く（→ [パケットの流れ](wireguard.md#パケットの流れremote-client--各拠点)）。

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。PC 側は[手順 1](#実施手順)、WG ホスト側は[手順 4](#実施手順)の先頭で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。例は `site.env.example`（拠点 A がクライアントを受ける構成）の値。
>
> | 変数 | 設定する場所 | 意味 | 例 |
> |---|---|---|---|
> | `${WG_DIR}` | PC | 鍵と conf の一時置き場。取り込んだら秘密鍵と conf は消す（手順 10）。WG ホストの `~/wg` と取り違えないよう別の名前にしてある | `~/wg-client` |
> | `${WG_HOST_TUN_IP}` | PC | 接続先拠点の WG ホストの `wg0` アドレス（`site.env` の `WG_A_TUN_IP`） | `10.99.0.1` |
> | `${WG_HOST_LAN_IP}` | PC | 同じホストの LAN 側 IP（`WG_A_LAN_IP`） | `192.168.110.2` |
> | `${ROUTER_LAN_IP}` | PC | 接続先拠点のルーターの LAN 側 IP（`ROUTER_A_LAN_IP`） | `192.168.110.1` |
> | `${PEER_WG_LAN_IP}` | PC | 相手拠点の WG ホストの LAN 側 IP（`WG_B_LAN_IP`） | `192.168.120.2` |
> | `${REPO}` / `${SITE}` | WG ホスト | このリポジトリの clone 先 / クライアントを受ける拠点（`A` か `B`） | `~/setup-notes` / `A` |
> | `${CLIENT_NAME}` / `${CLIENT_PUBKEY}` | WG ホスト | 登録簿（`clients.list`）に載せる名前 / 手順 3 で PC に表示された公開鍵 | `laptop` /（`wg pubkey` の出力） |
>
> 出力例・表の中の値は `<CLIENT_NAME>` / `<CLIENT_TUN_IP>`（ホストが割り当てるトンネル IP）/ `<CLIENT_PUBKEY>` / `<SITE_A_PUBKEY>` / `<SITE_A_PUBLIC>` / `<WG_PORT>` / `<WG_HOST_TUN_IP>` などのプレースホルダで書いてある。
>
> - **`<...>` を含むコマンドは bash のコードブロックには置かない**（本文中のインラインコードで示し、値に読み替える）
> - 読者が値を入れる必要があるコードブロックは、先頭で変数が空なら中断するようにしてあり、値を入れずに貼っても何も実行されない
>
> 秘密鍵はこの文書に載せず、手順の中でも端末に表示しない。公開鍵も検証用の使い捨ての値なので載せない。

手順書全体に関わる理由・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

2026-09-22、手順 2 の前に採取（採取コマンドは[付録](#付録-実機での検証記録)の「記録用ブロック」）。

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
  - ホストに秘密鍵入りの conf が残らないので、wireguard.md 手順 4 の最後の `rm` も要らない（`--pubkey` で作った conf はプレースホルダのまま残してよい）
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
  - バックアップは取らず、失ったら手順 3 からやり直す（ホスト側は `client remove` → `client add --pubkey`）
  - WG ホストの[バックアップ](wireguard.md#バックアップと復旧os-の再インストール)に、クライアントの鍵は含まれない

### 完了時点の状態

2026-09-22、手順 10 の後（元の Wi-Fi に戻した状態）。

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

- 手順 5 までは同じで、conf を `/etc/wireguard/wg0.conf` に置いて `wg-quick` で張る
- NetworkManager の `wg0` プロファイルが無いこと（同じ ifname で併用しない）

```bash
sudo install -m 600 -o root -g root "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.conf" /etc/wireguard/wg0.conf &&
sudo restorecon /etc/wireguard/wg0.conf &&
sudo wg-quick up wg0                     # 切るのは sudo wg-quick down wg0
```

- `DNS =` を書くなら `resolvconf` 経由で `systemd-resolved` が要る（→ [wireguard.md: `DNS =` を書く場合](wireguard.md#dns--を書く場合)）
- 起動時に張るなら `systemctl enable wg-quick@wg0`。ただし Wi-Fi より先に走り、`Endpoint` が名前なら解決に失敗しうる。拠点の LAN 内でも張られる
- NetworkManager からは `connected (externally)` として見え、同名の一時プロファイルが作られる（WG ホストで実測）
- wireguard.md の namespace ラボはクライアント側をこの経路で動かして疎通を確認している（→ [リモートクライアントの検証](wireguard.md#リモートクライアントの検証2026-09-19)）。本書の時点で検証済みなのはこちらだけ

### 代替: WG ホスト側で鍵を作る場合

wireguard.md 手順 4 の元の流れ（→ [wireguard.md 手順 4](wireguard.md#実施手順)、[秘密鍵の扱い](wireguard.md#クライアントの秘密鍵の扱い)）。

1. ホストで `client add A NAME`（`--pubkey` 無し）→ `client show NAME`。この出力に秘密鍵が入っている
1. LAN 内の `scp` など安全な経路で、PC の `${WG_DIR}/wg0.conf` に置く（手順 5 の `sed` は不要）
1. 手順 6 以降は同じ
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

- **拠点の LAN 内では切る**: 手順 6 以降は**どちらの拠点の LAN の外でも**行い、import 直後に自動で張られるので（実測）すぐ切る
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

### 参照

- [Chapter 7. Setting up a WireGuard VPN — Configuring and managing networking (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/configuring_and_managing_networking/setting-up-a-wireguard-vpn)（7.10 "Configuring a WireGuard client by using nmcli" は `nmcli connection add` で組む方式）
- [WireGuard VPN 構築手順](wireguard.md)（手順 4・5、症状と原因の対応、各注意点）
- `man nmcli`（`connection import`。man は「VPN のみ」と書くが WireGuard も読める）
- `man nm-settings-nmcli`（`wireguard` setting: `peers`、`peer-routes`、`mtu`、`ip4-auto-default-route`。`connection.autoconnect`、`ipv4.route-metric`）
- `/usr/share/doc/NetworkManager/NEWS`（1.16 / 1.34 / 1.56 の WireGuard の項）
- `man wg`（cryptokey routing、endpoint roaming）/ `man wg-quick`（`DNS`、`MTU`）
- `/usr/share/polkit-1/actions/org.freedesktop.NetworkManager.policy`（`sudo` を付ける根拠）
- [`scripts/wireguard/wg-vpn.sh`](../scripts/wireguard/wg-vpn.sh) の `render_client_conf` / `cmd_client_add` / `cmd_client_show`

---

### 付録: 実機での検証記録

2026-09-22、AlmaLinux 10.2 x86_64 のノート PC から拠点 B の WG ホスト（AlmaLinux 10.2 aarch64）へ、手順 1〜10 を本実行した。鍵・グローバル IP・ホスト名・クライアント名はプレースホルダに置き換えてある。

実施時の位置関係が手順書の書きぶりと違う点を先に書く:

- PC は**拠点 A の LAN**にいた。拠点 B の WG ホストへは拠点間トンネル越しに ssh で届く状態だった
- クライアント conf の `AllowedIPs` には**両拠点の LAN** が入るので、拠点 A の LAN にいるままトンネルを張ると自分の LAN 経路を奪う。そこで**手順 6 の前に**スマートフォンのテザリング回線へ移した（検証時の手順書は「トンネルを張る手順（今の手順 7）以降は LAN の外で」としていたが、import 直後に自動で張られるので 1 手順早く移す方が安全。今の手順書はこれに合わせて手順 6 から LAN の外にしている）
- 拠点 B がクライアントを受ける構成（`WG_B_CLIENT_NET` を設定、`WG_A_CLIENT_NET` は空）なので、手順 1 の変数には `WG_B_TUN_IP` / `WG_B_LAN_IP` / `ROUTER_B_LAN_IP` / `WG_A_LAN_IP` を入れ、手順 4 の `SITE` は `B` にした

#### 手順書から変えて実行した点

| 変えた点 | 理由 |
|---|---|
| 手順 4 の WG ホスト側のコマンドを、PC から ssh 越しに実行した | 手順書は WG ホストで直接実行する前提。コマンドと結果は同じ |
| 手順 5 の `vi` への貼り付けの代わりに、`client show` の出力を ssh のリダイレクトで `${WG_DIR}/wg0.conf` に直接書き出した（`umask 077` 付き） | 鍵も conf も端末に出さずに済む。`client show` の出力に秘密は無いので安全性は変わらない |
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

**手順 4**: `client add` は `==> クライアント <CLIENT_NAME> を登録しました（拠点 B、<CLIENT_TUN_IP>）` と `==> クライアント用 conf を書き込みました: /etc/wireguard/clients/<CLIENT_NAME>.conf` を出し、`conf の PrivateKey は <CLIENT_PRIVATE_KEY> のままです` と続ける。トンネル IP は登録簿の空きから最小のものが自動で割り当てられた。

- `--dry-run apply B` で予定を見ると、変わるのは `/etc/wireguard/wg0.conf` に `[Peer] # Client <CLIENT_NAME>` が 1 つ増えるところだけ。firewalld は `--reload` のみ（port / interface / forward は既に入っている）。LAN 側ゾーンは WG ホストの LAN 側 NIC から `public` を自動検出
- `apply B` は既存の conf を `wg0.conf.bak-<日時>` に退避してから書き直し、`wg-quick@wg0` を再起動する。実行後の `wg show` で peer が 1 つ増えた
- **restart の副作用**: 既存クライアントの `LAST_HANDSHAKE` が `なし` に戻る（peer を作り直すため、接続が無ければ再度つながるまで表示されない）
- **登録簿の列ずれ**: `client add` は `printf '%-12s'` で書くので、13 文字以上の名前だと `clients.list` の列が揃わない。空白区切りなので `awk` での読み取りには影響しない

**手順 5**: `grep -c '^PrivateKey = [A-Za-z0-9+/]\{43\}=$'` が `1`。他の行は `client show` の出力のまま。

**手順 6**: `import` は `Connection 'wg0' (<UUID>) successfully added.` の 1 行だけを出す。

- **その直後**に `connection show` を見ると `wg0  wireguard  wg0  activating  yes`、`device status` は `connecting (checking IP connectivity)`。`ip -4 route show` には既に `AllowedIPs` の 3 経路が `proto static scope link metric 50` で入っている（＝**未確認事項 2 と 3 はここで同時に確定した**）
- `connection.autoconnect no` の後は `activated  no`。`down` すると 3 経路とも消える
- `connection show wg0` の値: `connection.id` / `connection.interface-name` とも `wg0`、`connection.zone` は `--`、`ipv4.method` は `manual`、`ipv4.addresses` は `<CLIENT_TUN_IP>/32`、`ipv4.dns` は `--`、`ipv4.route-metric` は `-1`、`ipv6.method` は `disabled`、`wireguard.peer-routes` は `yes`、`wireguard.mtu` は `0`、`wireguard.private-key` は `<hidden>`
- `wireguard.peers` は 1 行に `<SITE_B_PUBKEY> allowed-ips=<SITE_A_LAN>;<SITE_B_LAN>;<WG_TUNNEL_NET> endpoint=<SITE_B_PUBLIC>:<WG_PORT> persistent-keepalive=25` まで出る
- keyfile は `-rw------- root root` の 477 バイト、SELinux ラベルは `system_u:object_r:NetworkManager_etc_rw_t:s0`

**手順 7**: `up` の直後、`device status` は `wg0  wireguard  connected  wg0`、MTU は `1420`。

- `IP4.ROUTE[1..3]` はいずれも `mt = 50`。経路全体で見ると、テザリングの `default` と直結経路が metric 600 なので、**拠点 LAN 宛てだけがトンネルに入る**
- `wg show wg0` の `listening port` はランダム（NetworkManager は `wireguard.listen-port 0` のまま）。この時点では `latest handshake` の行がまだ無く、`transfer: 0 B received, 148 B sent`。**最初のハンドシェイクは手順 8 の通信で起きる**
- `firewall-cmd --get-active-zones` の `public (default)` の `interfaces` に `wg0` が加わる
- `/etc/resolv.conf` は手順 2 の前と同じ。`ausearch -m AVC -ts recent` は `<no matches>`
- 細かい点: `nmcli -f GENERAL.STATE,IP4.ADDRESS,IP4.ROUTE,IP4.DNS connection show wg0` では `IP4.ADDRESS` の行が出ない。`nmcli -f IP4 connection show wg0` なら `IP4.ADDRESS[1]: <CLIENT_TUN_IP>/32` が出る

**手順 8**: 4 段階すべて `0% packet loss`。

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

**手順 9**: `down` の直後に `ip link show dev wg0` が `Device "wg0" does not exist.`（終了コード 1）。経路 3 本と firewalld の `wg0` も消える。プロファイルは `wg0  wireguard  --  --` で残る。

**手順 10**: `${WG_DIR}` に `wg0.pub` だけが残る。

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
