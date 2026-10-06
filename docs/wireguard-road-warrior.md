# WireGuard Road Warrior 設定手順（AlmaLinux 10 は NetworkManager + nmcli / Windows 11 は公式の WireGuard for Windows）

## 実施手順

- [検証記録](verification/wireguard-road-warrior.md)・[参考資料](reference/wireguard-road-warrior.md)

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 の PC のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（管理者の Windows PowerShell 5.1 に貼る。WG ホストでは、この実施手順の手順 4〜6・13 を使う）
> - **PC で実行する**。手順 4〜6 と手順 13 だけ WG ホストで実行する
> - **`sudo -i` した root のシェルではなく、自分のシェルで貼る**。`~` が自分のホームになるため
> - **手順 7 で `vi` が開く**。`client show` の出力を貼って保存し、閉じてから次の手順を貼る
> - **手順 9 で、PC を拠点の LAN の外のネットワークにつなぐ**（スマートフォンのテザリングなど）。手順 10 以降は LAN の外で行う

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
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

1. `wireguard-tools` を入れる。

   ```bash
   {
     sudo dnf install -y wireguard-tools
     rpm -q wireguard-tools NetworkManager systemd-resolved
     systemctl is-enabled systemd-resolved         # disabled（依存で入るだけ。本手順では有効にしない）
     modinfo -n wireguard                          # カーネル同梱のモジュールのパスが出る
   }
   ```

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

1. PC で、手順 6 の `client show` の出力を `vi` に貼り、`wg0.conf` に保存する。

   ```bash
   ( umask 077; vi "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.conf" )    # 手順 6 の client show の出力をそのまま貼って保存する
   ```

   - `client show` の出力は、WG ホストの端末からコピーする
   - **ファイル名は `wg0.conf` にする。** NetworkManager がファイル名から接続名とインターフェース名を決める
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

1. PC で、トンネル IP → WG ホストの LAN 側 → ルーター → 相手拠点の順に疎通を試す。

   ```bash
   for h in "${WG_HOST_TUN_IP:?手順 1 の変数が空のまま}" "${WG_HOST_LAN_IP:?}" "${ROUTER_LAN_IP:?}" "${PEER_WG_LAN_IP:?}"; do
     echo "== $h"; ping -c 3 -W 2 "$h" | tail -2
   done
   tracepath -n "${PEER_WG_LAN_IP:?}"             # <WG_HOST_TUN_IP> → <PEER_WG_LAN_IP> の順に出る
   ```

   - 相手拠点の LAN 上の別のホストへの `ping`、トンネル越しの `ssh <ユーザー>@<WG_HOST_LAN_IP>` も試しておくとよい
   - どこで止まるかで、疑う場所が変わる（→ [検証記録](verification/wireguard-road-warrior.md)・[参考資料](reference/wireguard-road-warrior.md)）

1. WG ホストで（手順 4 のシェルで）、ハンドシェイクと逆方向（拠点 → PC）を確かめる。

   ```bash
   cd "${REPO:?REPO が空のまま}/scripts/wireguard" &&
   sudo ./wg-vpn.sh -e ~/wg/site.env client list &&                                        # LAST_HANDSHAKE が「N 秒前」
   CLIENT_TUN_IP=$(awk -v n="${CLIENT_NAME:?CLIENT_NAME が空のまま}" '$1 == n { print $3 }' ~/wg/clients.list) &&
   ping -c 3 "${CLIENT_TUN_IP:?clients.list にその名前が無い}"                              # 拠点 → PC（PC の public ゾーンは ping に応答する）
   ```

   - 接続先拠点の LAN 上の別のホストから `ping <CLIENT_TUN_IP>` も通る（ルーターにクライアント帯の静的経路がある前提）
   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](verification/wireguard.md#症状と原因の対応実測)

1. PC で、トンネルを切る。

   ```bash
   sudo nmcli connection down wg0 &&
   nmcli device status | grep -E '^(DEVICE|wg0 )'         # wg0 の行が消える
   ```

   - 日常は、外出先で `sudo nmcli connection up wg0`、拠点に戻る前に `sudo nmcli connection down wg0`
   - autoconnect を無効にしてあるので、再起動しても勝手には張られない

1. 平文の鍵と conf を消す。

   ```bash
   rm -f "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.key" "${WG_DIR}/wg0.conf" &&
   ls -l "${WG_DIR}"                                       # wg0.pub だけ残る
   ```

   - 秘密鍵は手順 10 で NetworkManager のプロファイルに入っているので、平文のファイルを残さない（`wg0.pub` は公開鍵なので残してよい）

---

## ロールバック

- この節は AlmaLinux 10 の PC のもの。Windows 11 の PC は[Windows 11 のロールバック](#windows-11-のロールバック)
- **PC で、手順 1 の変数を設定したシェルで貼る**（`WG_DIR` が空だと `${WG_DIR:?…}` で止まる）
- この節の手順 3 だけは WG ホストで貼る

> [!CAUTION]
> **この節の手順 1 で、秘密鍵の置き場所である NetworkManager のプロファイル `wg0` を消す。** 鍵のバックアップは取っていないので、消した鍵は取り戻せない（[選択した方針](reference/wireguard-road-warrior.md#選択した方針)）。

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
- 手順の後: 以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](#windows-11-のロールバック)
- WG ホストの側は、AlmaLinux 10 の PC と同じ（`client add --pubkey` で公開鍵を登録して `apply` するだけで、ほかに変えるものは無い）

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

1. WireGuard を winget で入れる。

   ```powershell
   winget install --exact --id WireGuard.WireGuard --source winget --scope machine --accept-source-agreements --accept-package-agreements
   winget list --exact --id WireGuard.WireGuard
   Get-AuthenticodeSignature -FilePath "$env:ProgramFiles\WireGuard\wireguard.exe", "$env:ProgramFiles\WireGuard\wg.exe" | Format-Table Status, @{ Label = 'Signer'; Expression = { $_.SignerCertificate.Subject.Split(',')[0] } }, Path -AutoSize
   & "$env:ProgramFiles\WireGuard\wg.exe" --version
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と出て、`winget list` に `WireGuard.WireGuard` の行が出ればよい（版は実行した日の最新）
   - 2 つのファイルの署名が `Valid` で、署名者が `CN=WireGuard LLC`
   - 最後に `wireguard-tools v1.0.20260223 - https://git.zx2c4.com/wireguard-tools/` の形の 1 行が出る
   - インストーラーの画面は出ず、入れた後に WireGuard の窓も開かない（窓は、この節の手順 5 で開く）

1. WireGuard の窓を開く（マネージャーを起動する）。

   ```powershell
   & "$env:ProgramFiles\WireGuard\wireguard.exe"
   ```

   - WireGuard の窓が開き、タスク バーの通知領域に WireGuard のアイコンが出る（トンネルの一覧はまだ空）
   - スタートメニューの「WireGuard」から開いても同じ
   - 窓は開いたままでよい（閉じても、マネージャーは動き続ける）
   - **次の手順は、WireGuard の窓が開いてから、PowerShell の窓をクリックして貼る**（窓が開く前に貼ると、開いた窓に入力が移ることがある）

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
   - `wg0.conf` が残ったら、取り込めていない。理由を見て、残った `wg0.conf` を `Remove-Item -LiteralPath "$env:ProgramFiles\WireGuard\Data\Configurations\wg0.conf"` で消し、この節の手順 8・9 からやり直す
   - （この手順の代わりに）窓の「トンネルをファイルからインポート…」で `%USERPROFILE%\wg-client\wg0.conf` を選んでも、同じ `wg0.conf.dpapi` ができるはず

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
   - どこで止まるかで、疑う場所が変わる（[実施手順](#実施手順)の[検証記録](verification/wireguard-road-warrior.md)・[参考資料](reference/wireguard-road-warrior.md)と同じ）

1. WG ホストで、[実施手順](#実施手順)の手順 13 を（手順 4 のシェルで）貼り、ハンドシェイクを確かめる。

   - `client list` の、この PC の名前の `LAST_HANDSHAKE` が「N 秒前」なら届いている
   - 最後の `ping`（拠点 → PC）は、応答が無くてよい。Windows の既定のファイアウォールは、ICMP のエコー要求を受けないはず（[選択した方針](reference/wireguard-road-warrior.md#選択した方針)のとおり、変えない）
   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](verification/wireguard.md#症状と原因の対応実測)
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

1. WG ホストで、[ロールバック](#ロールバック)の手順 3 の案内に従い、登録を消して反映する。

   - 手順 4 の `CLIENT_NAME` は、[Windows 11 で使う](#windows-11-で使う)の手順 8 で登録した、この PC の名前にする
   - ルーターの静的経路（クライアント帯）は、他のクライアントも使うので触らない

---

## 注意点

- **拠点の LAN 内では切る**: 手順 10 以降は**どちらの拠点の LAN の外でも**行い、import 直後に自動で張られるので、すぐ切る
  - `Endpoint` 宛ての通信が、ルーターで折り返す[ヘアピン](wireguard.md#クライアントが拠点の-lan-内にいるとき)になる
  - NetworkManager が入れる拠点 LAN の経路が Wi-Fi の直結経路より優先されると、LAN 宛ての通信がすべてトンネルに入る
  - `AllowedIPs` には**両拠点の LAN**が入るので、接続先ではない方の拠点の LAN にいるときも同じことが起きる（その LAN のデフォルトゲートウェイに届かなくなり、`Endpoint` 自体も見えなくなってトンネルごと死ぬ）
- **`DNS =` の扱いが wg-quick と違う**: 本書は `DNS =` 無し
  - NetworkManager では `ipv4.dns` になり、接続中は resolv.conf を NetworkManager が書き換えるので、`systemd-resolved` は不要と考えられる
  - wg-quick は `resolvconf` 経由で resolved が要る（→ [wireguard.md](wireguard.md#dns--を書く場合)）
- **MTU**: PPPoE やモバイル回線で大きい通信だけ止まるなら `sudo nmcli connection modify wg0 wireguard.mtu 1380` して down / up（→ [wireguard.md: MTU](wireguard.md#mtu)）
- **全トラフィックを VPN に通す構成は対象外**: NetworkManager 側は `wireguard.ip4-auto-default-route`（`/0` の peer で自動有効）、拠点側は NAT が要る（→ [wireguard.md](wireguard.md#全トラフィックを-vpn-経由にする場合対象外)）
- **`Endpoint` が DDNS 名のとき**: 本書の例は IP リテラルを使う。DDNS を使う場合は [wireguard.md](wireguard.md#endpoint-に-ddns-名を書く場合)を参照する
- **サスペンド復帰・Wi-Fi の切り替え**: 復帰後に `nmcli device status` でトンネルの状態を見る
  - `autoconnect no` のプロファイルは、復帰後に `nmcli device status` を見て、切れていたら接続し直す
  - Wi-Fi が変わっても、WireGuard は送信元の変化に追従するはず。`PersistentKeepalive = 25` が NAT の穴を維持する
- **1 台のクライアントは 1 つの拠点だけ**（→ [wireguard.md](wireguard.md#1-台のクライアントは-1-つの拠点にしか接続できない)）。別拠点用は別名のプロファイルを作り、同時には張らない
- **同じ ifname で wg-quick と NetworkManager を併用しない**: `/etc/wireguard/wg0.conf` と NetworkManager の `wg0` を両方置くと、どちらが `wg0` を持つかで衝突する
- **同名クライアントの登録があれば先に `client remove`**: `client add` は同名を拒否する
- **秘密鍵は `nmcli -s` で読める**: PC のログインパスワードが鍵の守りになる
  - root なら常に読める
  - **ローカルのコンソールにログイン中のユーザーは、`sudo` 無しでも秘密鍵を読める**（polkit の既定 `allow_active=yes`）
- **Windows 11 の注意点**
  - **拠点の LAN 内では張らない**: `AllowedIPs` の経路は、ルートのメトリック 0 で `wg0` に入る（ソースの `tunnel/addressconfig.go`）。LAN の直結の経路（Windows の既定ではルートのメトリック 256）より優先されるはずなので、AlmaLinux 10 と同じく LAN 宛ての通信がトンネルに入る
  - **張ったまま再起動すると、また張られる**: トンネルのサービスは自動で起動する（ソースの `manager/install.go`）。拠点の LAN に戻る前に切る
  - **ほかの端末と同じ名前で登録しない**: [実施手順](#実施手順)の手順 5 は、`CLIENT_NAME` と同じ名前の登録を消す。AlmaLinux 10 の PC と両方使うなら、別々の名前と鍵で登録する
  - **秘密鍵は、管理者なら読める**: 張っている間の `wg.exe show wg0 private-key`、窓の「編集」（設定の全文を出す）と「すべてのトンネルをzipにエクスポート」。WireGuard の窓は Administrators の一員にしか出ない。Windows のサインインのパスワードが鍵の守りになる
  - **WireGuard を外すと、ほかのトンネルの設定も消える**: MSI のアンインストールは `C:\Program Files\WireGuard\Data` を丸ごと消す（ソースの `installer/customactions.c` の `RemoveConfigFolder`）
  - **MTU**: conf に `MTU =` が無いと、既定の経路のインターフェースの MTU から 80 を引いた値になる（1500 なら 1420。WireGuard の文書の「Network Configuration Quirks」）。大きい通信だけ止まるなら、トンネルを切ってから窓の「編集」で `[Interface]` に `MTU = 1380` を足す
  - **`DNS =` を書いた場合**: `wg0` の DNS サーバーになり、Windows の通常の名前解決の扱い（複数の DNS サーバーを使う）に任される。DNS を絞る規則は、キルスイッチが掛かる構成（`/0` の peer が 1 つ）でだけ入る（同じ文書）。本書は `DNS =` 無し
  - **`Endpoint` が DDNS 名のとき**: トンネルを張るたびに名前を引く（ソースの `tunnel/service.go`）
  - **トンネルの名前はファイル名から決まる**: `wg0.conf` → `wg0`（英数字と `_=+.-` の 32 文字まで。ソースの `conf/name.go`）。サービスの名前は `WireGuardTunnel$wg0`、アダプターの名前も `wg0`


## 落とし穴: `apply` は作業中の ssh 経路そのものを切る

- `apply` は最後に `wg-quick@wg0` を再起動する。トンネル越しに WG ホストへ ssh して作業すると、その接続が切れる
- 切れたまま戻らない場合に備えて、LAN 側の ssh やコンソールなど別の経路を用意しておく

1. WG ホストで、`apply` を SSH セッションから切り離して実行する。

   - `sudo systemd-run --unit=wg-apply-rw -p Type=oneshot /bin/bash <REPO>/scripts/wireguard/wg-vpn.sh -e <ENV_FILE> apply B` を使う。`<REPO>`・`<ENV_FILE>` と拠点 `B` は対象の値に合わせる
   - ホーム配下のスクリプトは、パスを直接渡さず `/bin/bash` の引数にする
   - 再接続したら `journalctl -u wg-apply-rw` で結果を読み、`systemctl show wg-apply-rw -p Result -p ExecMainStatus` で終了状態を確認する
   - 戻れない場合は、用意した LAN 側の ssh またはコンソールで状態を確認する

---
