# WireGuard Road Warrior 設定手順（AlmaLinux 10 は NetworkManager + nmcli / Windows 11 は公式の WireGuard for Windows）の参考資料

[手順書](../wireguard-road-warrior.md)

[検証記録](../verification/wireguard-road-warrior.md#参考資料から分離した記録)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- 変数名は PC 視点（`WG_HOST_*` = 接続先拠点、`PEER_*` = 相手拠点）
- 拠点 B がクライアントを受ける構成なら、`site.env` の `WG_B_TUN_IP` / `WG_B_LAN_IP` / `ROUTER_B_LAN_IP` と `WG_A_LAN_IP` を入れる
- `WG_DIR` を WG ホストの `~/wg`（`site.env` と `clients.list` の置き場）と別の名前にしてあるのは、同じ人が両方のマシンを触るときに、ロールバックの `rm` を取り違えても登録簿が消えないようにするため

### 実施手順 / 手順 2: 補足: パッケージ

- `wireguard-tools` は `wg` / `wg-quick` と、依存の `systemd-resolved` を入れる
- `systemd-resolved` は有効にしない。有効にすると NetworkManager の DNS 処理が resolved 経由に切り替わる（`DNS =` を使わない本手順では不要）
- `modinfo -n` はモジュールの存在確認だけで、ロードは `nmcli connection up` の時点で NetworkManager が行う

### 実施手順 / 手順 3: 補足: 鍵ペア

- `umask 077` で `wg0.key` / `wg0.pub` を 0600 にする
- `tee` で秘密鍵をファイルに落としつつ `wg pubkey` に流すので、秘密鍵は端末に出ない
- `wg genkey` / `wg pubkey` はカーネルモジュール無しで動く
- 既に `wg0.key` があるときに中断するのは、上書きするとホストに登録済みの公開鍵と対応しなくなるため

### 実施手順 / 手順 6: 補足: WG ホストでの登録

- `client add` は同じ名前・同じ公開鍵・同じトンネル IP を拒否する（`wg-vpn.sh` の `cmd_client_add`）
- `--pubkey` で登録した conf の `PrivateKey` は、文字列 `<CLIENT_PRIVATE_KEY>` のまま書かれる（`client add` の末尾にもその旨が出る）
- `apply` は `wg0.conf` を作り直して `systemctl restart` するので、他のクライアントと拠点間トンネルが数秒切れる（`reload` では経路が入らない。→ [落とし穴 2](../wireguard.md#落とし穴-2-reload-では経路が追加されない)）
- `apply` の末尾に出るルーターの設定（クライアント帯の静的経路）は、既に入っていれば変更不要
- トンネル IP は帯の中で最小の空きが割り当たる（`--ip` で指定できる）

### Windows 11 で使う / 手順 2: 補足: 変数について

- 変数の名前と意味は、AlmaLinux 10 の[手順 1](../wireguard-road-warrior.md#実施手順)と同じ（PC 視点。`WG_HOST_*` = 接続先拠点、`PEER_*` = 相手拠点）。拠点 B がクライアントを受ける構成なら、`site.env` の `*_B_*` 側の値を入れる
- 使うのは、この節の手順 13 の疎通の確認だけ
- 鍵と conf の一時置き場は `%USERPROFILE%\wg-client`（`C:\Users\<WIN_USER>\wg-client`）に決めてあり、変数にしていない。WG ホストの `~/wg`（`site.env` と `clients.list` の置き場）とは別の名前

### Windows 11 で使う / 手順 3: 補足: 見ているもの

- `WireGuardManager` は WireGuard の窓（マネージャー）のサービス、`WireGuardTunnel$<名前>` は張っているトンネルごとのサービス（[WireGuard for Windows の文書](https://git.zx2c4.com/wireguard-windows/about/docs/enterprise.md)）
- `C:\Program Files\WireGuard\Data\Configurations` は、WireGuard が取り込んだトンネルの設定（`<名前>.conf.dpapi`）の置き場所。アクセス権が SYSTEM と Administrators だけなので、管理者の PowerShell でないと何も出ない
- `--source winget` を付けた `winget list` は、入っているアプリを winget のカタログと照合し、確認に要らない Microsoft Store のソースの初回同意を避ける
- `--accept-source-agreements` は、winget を初めて使う PC で出るソースの同意の問いに答えるため（続けて貼った行が答えとして食われないように）

### Windows 11 で使う / 手順 5: 補足: マネージャーのサービス

- 引数無しの `wireguard.exe` は、マネージャーが動いていれば窓を出し、動いていなければマネージャーのサービス `WireGuardManager` を作って起動してから窓を出す（ソースの `main.go`、WireGuard の文書の「Enterprise Usage」）。スタートメニューの「WireGuard」も同じ
- `WireGuardManager` は自動で起動するサービスになる。以後は、Administrators の一員がサインインするたびに、通知領域に WireGuard のアイコンが出る
- マネージャーは、この節の手順 10 の取り込み（設定の置き場所を見張って暗号化する）と、更新の知らせ（[Windows 11 の更新](../wireguard-road-warrior.md#windows-11-の更新)）に要る
- 窓は Administrators の一員にしか出ない（ソースの `main.go` の `checkForAdminGroup`）
- 管理者の PowerShell から開くので、UAC の確認は出ないはず
- `wireguard.exe` は GUI のプログラムなので、PowerShell は窓が開くのを待たずにプロンプトに戻る

### Windows 11 で使う / 手順 10: 補足: 取り込みと、理由の見方

- マネージャーは `C:\Program Files\WireGuard\Data\Configurations` を見張っていて、`.conf` のファイルが来ると、読んで `<名前>.conf.dpapi` に暗号化して書き、元のファイルを消す（WireGuard の文書の「Enterprise Usage」、ソースの `conf/migration_windows.go`）。トンネルの名前はファイル名から決まる（`wg0`）
- `.conf.dpapi` は LocalSystem の DPAPI で暗号化され、アクセス権は SYSTEM だけが読み書きでき、Administrators は消せるだけ（ソースの `conf/filewriter_windows.go`）。秘密鍵の置き場所は、以後これだけになる（AlmaLinux 10 の `/etc/NetworkManager/system-connections/wg0.nmconnection` に当たる）
- `Data` のフォルダーのアクセス権は SYSTEM と Administrators のフル コントロールなので、管理者の PowerShell から写せる（ソースの `conf/path_windows.go`）
- 読めなかったときは、マネージャーのログに `Unable to ingest and encrypt` の行が出て、`wg0.conf` が残る。ログは `& "$env:ProgramFiles\WireGuard\wireguard.exe" /dumplog | Select-String -SimpleMatch 'wg0.conf'` で見られる（窓の「ログ」のタブでも見られる）
- 同じ名前の `wg0.conf.dpapi` があると上書きしない（取り込めずに残る）ので、ブロックの先頭で止めている

### Windows 11 で使う / 手順 15: 補足: 切ったときと、日常の使い方

- `/uninstalltunnelservice wg0` は、トンネルのサービスを止めて消す。窓の「無効化」も同じ（ソースの `manager/ipc_server.go` の `Stop`）。アダプターは、トンネルが止まると消える
- トンネルの設定（`wg0.conf.dpapi`）は残るので、次は有効化だけでよい
- サービスは消されてもすぐには無くならないことがあるので、消えるまで 30 秒まで待つ
- NetworkManager の `autoconnect no` に当たる設定は無い。張ったまま（サービスが残ったまま）再起動すると、起動のときに張られ、拠点の LAN の中なら LAN の通信を奪う

### 選択した方針

Windows 11 で conf を取り込んで張る方法を比べた:

| 方法 | 状況 | 採否 |
|---|---|---|
| **設定の置き場所（`C:\Program Files\WireGuard\Data\Configurations`）に `wg0.conf` を写し、マネージャーに暗号化させる。張る・切るは `wireguard.exe /installtunnelservice` / `/uninstalltunnelservice`** | マネージャーが `wg0.conf.dpapi` に暗号化して、写した平文を消す（WireGuard の文書の「Enterprise Usage」）。窓の一覧にも出て、窓と通知領域のアイコンからも張る・切るができる。2 つのコマンドは、窓の「有効化」「無効化」がすることと同じ | **採用**（ブロックで写して、できたことを確かめられる） |
| 窓の「トンネルをファイルからインポート…」 | 結果は同じ（`wg0.conf.dpapi` になる）。ファイルを選ぶ画面の操作になり、確かめをブロックにまとめられない | 不採用（[Windows 11 で使う](../wireguard-road-warrior.md#windows-11-で使う)の手順 10 の代わりにしてよい） |
| `/installtunnelservice` に作業用の `wg0.conf` を直接渡す | すぐ張られるが、トンネルのサービスは起動のたびにそのファイルを読むので、秘密鍵入りの平文のファイルを消せない | 不採用 |

- **Windows 11 でも、鍵は PC で作り、公開鍵だけを WG ホストに渡す**（AlmaLinux 10 と同じ）
  - 秘密鍵は、`wg.exe genkey` の出力をブロックの中の変数で受け、画面に出さずにファイルに書く
  - `client show` の conf は、ファイルにせずクリップボードから読む（`vi` を開く手順の代わり）。秘密は入っていないので、運ぶ経路を選ばない
- **Windows 11 の秘密鍵の置き場所は、WireGuard の設定（`wg0.conf.dpapi`）だけ**
  - LocalSystem（マネージャー）の DPAPI で暗号化され、アクセス権は SYSTEM だけが読み書きでき、Administrators は消せるだけ（ソースの `conf/filewriter_windows.go`）
  - 作業用の置き場所（`%USERPROFILE%\wg-client`）は、アクセス権を Administrators と SYSTEM だけにし（管理者の PowerShell からだけ読める）、[Windows 11 で使う](../wireguard-road-warrior.md#windows-11-で使う)の手順 16 で平文の鍵と conf を消す
  - バックアップは取らず、失ったら作り直す（AlmaLinux 10 と同じ。ホスト側は[実施手順](../wireguard-road-warrior.md#実施手順)の手順 5 の共通の削除手順で反映した後、手順 6 で `client add --pubkey`）
- **Windows 11 では、拠点の LAN に戻る前に手で切る**
  - トンネルのサービスは自動で起動するので、張ったまま再起動すると、起動のときに張られる。NetworkManager の `autoconnect no` に当たる設定は無い
  - 取り込みだけではトンネルは張られない（NetworkManager の `import` と違う）
- **Windows 11 のファイアウォールとネットワークの種類は変えない**
  - PC 側で開けるものは無い（外向きの UDP は既定で通る）。WireGuard は自分のパケットを通す規則を自分で足す
  - `wg0` のネットワークはパブリックのはず（識別されないネットワーク）。プライベートにすると、プライベート向けの受信の規則（[Windows の OpenSSH サーバー](../windows-openssh-server.md)など）が、拠点からトンネル越しに届くようになる
  - 拠点から PC への ping（[実施手順](../wireguard-road-warrior.md#実施手順)の手順 13 の最後）は、Windows の既定のファイアウォールが ICMP のエコー要求を受けないので、返らないはず。トンネルが動いているかは、WG ホストの `client list` の `LAST_HANDSHAKE` で見る
- **Windows 11 ではキルスイッチは出ない**: `AllowedIPs` に `/0` が無いので、窓の編集の「トンネルを通らないトラフィックのブロック（キルスイッチ）」は出ず、ファイアウォールの制限も掛からない（WireGuard の文書の「Network Configuration Quirks」）。全トラフィックを通す構成は、AlmaLinux 10 と同じく対象外
- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた。WG ホストの手順は共通なので、[実施手順](../wireguard-road-warrior.md#実施手順)の手順 4〜6・13 と[ロールバック](../wireguard-road-warrior.md#ロールバック)の手順 3 をそのまま使う

### 代替: wg-quick で張る場合

NetworkManager を使わない場合。実行の範囲は[検証記録](../verification/wireguard-road-warrior.md#参考資料から分離した記録)を参照。

- 手順 8 までは同じで、conf を `/etc/wireguard/wg0.conf` に置いて `wg-quick` で張る
- NetworkManager の `wg0` プロファイルが無いこと（同じ ifname で併用しない）

```bash
sudo install -m 600 -o root -g root "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.conf" /etc/wireguard/wg0.conf &&
sudo restorecon /etc/wireguard/wg0.conf &&
sudo wg-quick up wg0                     # 切るのは sudo wg-quick down wg0
```

### 代替: WG ホスト側で鍵を作る場合

wireguard.md 手順 10〜16 の元の流れ（→ [wireguard.md 手順 10〜16](../wireguard.md#実施手順)、[秘密鍵の扱い](../wireguard.md#クライアントの秘密鍵の扱い)）。

1. ホストで `client add A NAME`（`--pubkey` 無し）→ `apply A` → `client show NAME`（拠点 B なら `A` を `B` に読み替える）。`apply` でホストに反映してから表示する。この出力に秘密鍵が入っている
1. LAN 内の `scp` など安全な経路で、PC の `${WG_DIR}/wg0.conf` に置く（手順 8 の `sed` は不要）
1. 手順 9 以降は同じ
1. 取り込んだら、ホストで `sudo rm /etc/wireguard/clients/NAME.conf`

- 端末のスクロールバックとクリップボードに鍵が残る点に注意
- スマートフォンは `client show NAME --qr` で、こちらの流れになる

### 代替: nmcli connection add で組む場合（RHEL のドキュメントの方式）

conf を import せず、値を手で写す方式。最初から `autoconnect no` にできるのが利点。実行の範囲は[検証記録](../verification/wireguard-road-warrior.md#参考資料から分離した記録)を参照。

1. `nmcli connection add type wireguard con-name wg0 ifname wg0 autoconnect no`
1. `nmcli connection modify wg0 ipv4.method manual ipv4.addresses <CLIENT_TUN_IP>/32`
1. `wireguard.private-key`（秘密鍵）
1. `wireguard.peers '<SITE_A_PUBKEY> endpoint=<SITE_A_PUBLIC>:<WG_PORT> allowed-ips=<SITE_A_LAN>;<SITE_B_LAN>;<WG_TUNNEL_NET> persistent-keepalive=25'`（`allowed-ips` は `;` 区切り。`nm-settings-nmcli(5)`）
1. `nmcli connection up wg0`

### 参照

- [Chapter 7. Setting up a WireGuard VPN — Configuring and managing networking (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/configuring_and_managing_networking/setting-up-a-wireguard-vpn)（7.10 "Configuring a WireGuard client by using nmcli" は `nmcli connection add` で組む方式）
- [WireGuard VPN 構築手順](../wireguard.md)（手順 10〜18、症状と原因の対応、各注意点）
- `man nmcli`（`connection import`。man は「VPN のみ」と書くが WireGuard も読める）
- `man nm-settings-nmcli`（`wireguard` setting: `peers`、`peer-routes`、`mtu`、`ip4-auto-default-route`。`connection.autoconnect`、`ipv4.route-metric`）
- `/usr/share/doc/NetworkManager/NEWS`（1.16 / 1.34 / 1.56 の WireGuard の項）
- `man wg`（cryptokey routing、endpoint roaming）/ `man wg-quick`（`DNS`、`MTU`）
- `/usr/share/polkit-1/actions/org.freedesktop.NetworkManager.policy`（`sudo` を付ける根拠）
- [`scripts/wireguard/wg-vpn.sh`](../../scripts/wireguard/wg-vpn.sh) の `render_client_conf` / `cmd_client_add` / `cmd_client_show`
- [WireGuard のインストールのページ](https://www.wireguard.com/install/) — Windows の公式の配布物（`wireguard-installer.exe` と MSI）
- [Enterprise Usage — WireGuard for Windows](https://git.zx2c4.com/wireguard-windows/about/docs/enterprise.md) — `DO_NOT_LAUNCH`、`/installtunnelservice`・`/uninstalltunnelservice`、`.conf.dpapi`、マネージャーが設定の置き場所の `.conf` を暗号化すること、`/update`・`/dumplog`
- [Network Configuration Quirks — WireGuard for Windows](https://git.zx2c4.com/wireguard-windows/about/docs/netquirk.md) — 経路と MTU、キルスイッチの条件、ネットワークの種類（決まった GUID）
- WireGuard for Windows 1.1.1 のソース（`v1.1.1` のタグ）— `installer/wireguard.wxs`・`installer/customactions.c`（MSI）、`main.go`（コマンドライン）、`manager/install.go`・`manager/ipc_server.go`（サービスと、窓の有効化・無効化）、`conf/migration_windows.go`・`conf/filewriter_windows.go`・`conf/path_windows.go`（取り込み・暗号化・アクセス権）、`conf/parser.go`・`conf/name.go`（conf の読み方とトンネルの名前）、`tunnel/addressconfig.go`・`tunnel/service.go`（経路・名前解決）、`updater/`（更新）
- winget-pkgs の `manifests/w/WireGuard/WireGuard/1.1.1/` — `WireGuard.WireGuard` の定義
- wireguard-tools のソースの `src/pubkey.c`・`src/ctype.h` — `wg pubkey` が鍵の後ろの空白（CR を含む）を読み飛ばすこと
- [Get-Clipboard（5.1）— Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-clipboard?view=powershell-5.1) — `-Raw`
- [Windows 11 の初期設定](../windows-setup.md) — Windows の PowerShell の貼り付けの設定（前提）と、この文書を通す順番

---
