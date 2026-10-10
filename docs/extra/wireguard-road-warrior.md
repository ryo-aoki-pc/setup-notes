# WireGuard Road Warrior 設定手順（AlmaLinux 10 は NetworkManager + nmcli / Windows 11 は公式の WireGuard for Windows）のロールバックと注意点

[手順書](../wireguard-road-warrior.md)・[検証記録](../verification/wireguard-road-warrior.md)・[参考資料](../reference/wireguard-road-warrior.md)

- 手順書の実施手順は項（###）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- この節は AlmaLinux 10 の PC のもの。Windows 11 の PC は[Windows 11 のロールバック](#windows-11-のロールバック)
- **PC で、「鍵を作る」の手順 1 の変数を設定したシェルで貼る**（`WG_DIR` が空だと `${WG_DIR:?…}` で止まる）
- この節の手順 3 だけは WG ホストで貼る

> [!CAUTION]
> **この節の手順 1 で、秘密鍵の置き場所である NetworkManager のプロファイル `wg0` を消す。** 鍵のバックアップは取っていないので、消した鍵は取り戻せない（[選択した方針](../reference/wireguard-road-warrior.md#選択した方針)）。

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

   - [wireguard.md のクライアントを削除する](../wireguard.md#クライアントを削除する)の手順 1〜6 を行う。対象は、「WG ホストに登録する」の手順 1 で登録した `CLIENT_NAME` と `SITE`
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

1. WG ホストで、[ロールバック](#ロールバック)の手順 3 の案内に従い、登録を消して反映する。

   - 「WG ホストに登録する」の手順 1 の `CLIENT_NAME` は、[Windows 11 で WG ホストに登録して取り込む](../wireguard-road-warrior.md#windows-11-で-wg-ホストに登録して取り込む)の手順 2 で登録した、この PC の名前にする
   - ルーターの静的経路（クライアント帯）は、他のクライアントも使うので触らない

---

## 注意点

- **拠点の LAN 内では切る**: 「conf を取り込む」の手順 4 と「トンネルを確かめる」の全部は**どちらの拠点の LAN の外でも**行い、import 直後に自動で張られるので、すぐ切る
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
  - **ほかの端末と同じ名前で登録しない**: 実施手順の[WG ホストに登録する](../wireguard-road-warrior.md#wg-ホストに登録する)の手順 2 は、`CLIENT_NAME` と同じ名前の登録を消す。AlmaLinux 10 の PC と両方使うなら、別々の名前と鍵で登録する
  - **秘密鍵は、管理者なら読める**: 張っている間の `wg.exe show wg0 private-key`、窓の「編集」（設定の全文を出す）と「すべてのトンネルをzipにエクスポート」。WireGuard の窓は Administrators の一員にしか出ない。Windows のサインインのパスワードが鍵の守りになる
  - **WireGuard を外すと、ほかのトンネルの設定も消える**: MSI のアンインストールは `C:\Program Files\WireGuard\Data` を丸ごと消す（ソースの `installer/customactions.c` の `RemoveConfigFolder`）
  - **MTU**: conf に `MTU =` が無いと、既定の経路のインターフェースの MTU から 80 を引いた値になる（1500 なら 1420。WireGuard の文書の「Network Configuration Quirks」）。大きい通信だけ止まるなら、トンネルを切ってから窓の「編集」で `[Interface]` に `MTU = 1380` を足す
  - **`DNS =` を書いた場合**: `wg0` の DNS サーバーになり、Windows の通常の名前解決の扱い（複数の DNS サーバーを使う）に任される。DNS を絞る規則は、キルスイッチが掛かる構成（`/0` の peer が 1 つ）でだけ入る（同じ文書）。本書は `DNS =` 無し
  - **`Endpoint` が DDNS 名のとき**: トンネルを張るたびに名前を引く（ソースの `tunnel/service.go`）
  - **トンネルの名前はファイル名から決まる**: `wg0.conf` → `wg0`（英数字と `_=+.-` の 32 文字まで。ソースの `conf/name.go`）。サービスの名前は `WireGuardTunnel$wg0`、アダプターの名前も `wg0`
