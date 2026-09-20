# WireGuard VPN 構築手順（site-to-site + road warrior / wg-quick + firewalld）

- **目的**: 2 拠点の LAN を WireGuard で結び、**拠点 A の LAN 上のクライアントと拠点 B の LAN 上のクライアントが双方向に通信できる**ようにする。あわせて、外出先のノート PC やスマートフォンなど**任意の台数のクライアント**を足して、そこから両拠点の LAN に到達できるようにする
- **進め方**: **`site.env` に値を 1 度だけ書き、両拠点の WG ホストに同じファイルを置いて、`wg-vpn.sh` に `-e` で渡して実行する。** 拠点 A / B は引数で指定し、スクリプトがこのホストの LAN 側 IP と照合する（取り違えると何も変更せずに止まる）
- **状態**: 1 台のマシン上に network namespace で 2 拠点と外出先クライアントを模擬して動作確認済み（[付録](#付録-network-namespace-による検証)）。**実際に 2 拠点をインターネット越しに結んでの確認と、実機を持ち出しての確認（モバイル回線・スマートフォンの公式アプリ）はまだしていない**。**スクリプト（`wg-vpn.sh`）の `apply` / `remove` は、スタブ環境での本実行と実機での `--dry-run` までで、実機での本実行は未確認**（[付録](#付録-スクリプトの検証)）。namespace での検証は、同じ設定を手で入れて行った

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-16（初回）／ 2026-09-19（変数形の手順に書き換えて再検証、クライアントの疎通確認） |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64 |
| カーネル | 6.12.96（`wireguard.ko` を同梱） |
| `wireguard-tools` | 1.0.20250521-1.el10（appstream） |
| firewalld | 2.4.3 |
| NetworkManager | 1.56.0 |
| SELinux | Enforcing |
| クライアント | 検証は Linux の `wg-quick`。WireGuard 公式アプリ（Windows / macOS / iOS / Android）も同じ conf で使える想定 |

![構成](diagrams/wireguard-remote-client.svg)

拠点ルーターの配下に WG ホストを 1 台ずつ置き、`wg0` 同士をトンネルで結ぶ。外出先のクライアントは、どちらかの拠点の WG ホストに接続する（図は拠点 A で受ける場合。→ [補足: 構成とパケットの流れ](#構成とパケットの流れ)）。

> **注記**: 環境固有の値は**シェル変数**で書いてある。値は最初に作る `site.env` 1 ファイルに集約し、スクリプトに渡す。例は検証で使った値。
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
> | `${LAN_ZONE}` | WG ホストの LAN 側 NIC が属する firewalld ゾーン（空なら自動で検出する） | `public` |
> | `${SITE_A_PUBKEY}` / `${SITE_B_PUBKEY}` | 各拠点の WireGuard 公開鍵 | （`wg pubkey` の出力） |
> | `${WG_IFACE}` / `${WG_FW_ZONE}` | インターフェース名 / `wg0` を入れる firewalld ゾーン名 | `wg0` / `wireguard` |
> | `${WG_A_CLIENT_NET}` / `${WG_B_CLIENT_NET}` | 各拠点に接続するクライアントに割り当てるトンネル内のアドレス帯（**LAN・`${WG_TUNNEL_NET}`・互いに重複不可**、`/30` より広く。クライアントを受けない拠点は空） | `10.99.1.0/24` / （空） |
> | `${WG_CLIENT_DNS}` | クライアント用 conf に書く DNS サーバー（任意） | （空） |
>
> 秘密鍵はこの文書に載せない。公開鍵は秘密情報ではないが、検証用に作った使い捨ての値なので載せていない。

---

## 手順の流れ

**手順 1〜3 は両拠点の WG ホストで、手順 4 はクライアントを受ける拠点のホストで行う。** コマンドはすべて `<このリポジトリ>/scripts/wireguard` で実行し、`-e ~/wg/site.env` で値を渡す。拠点 B のホストでは引数の `A` を `B` に読み替える。

| 手順 | 内容 | 実施場所 |
|---|---|---|
| [1. site.env を書く](#1-siteenv-を書く) | 値を 1 度だけ書く（クライアント帯もここで決める） | 両拠点の WG ホスト |
| [2. 鍵の生成と公開鍵の交換](#2-鍵の生成と公開鍵の交換) | `keygen`。公開鍵を `site.env` に書いて両拠点でそろえる | 同上 |
| [3. 適用](#3-適用) | `apply`。`wg0.conf`・IP フォワーディング・firewalld・サービス | 同上 |
| [4. クライアントの登録](#4-クライアントの登録) | `client add` → `apply` → `client show` | クライアントを受ける拠点のホスト |
| [5. 疎通確認](#5-疎通確認) | `status` と ping / tracepath | WG ホストと各クライアント |

**OS を入れ直して同じ鍵で戻したい場合は、先に[バックアップと復旧](#バックアップと復旧os-の再インストール)を読む。** 鍵さえ残っていれば、相手拠点の設定も配布済みのクライアント conf も変えずに復旧できる。

### 1. site.env を書く

**編集するのは `~/wg/site.env` だけ。** 両拠点の WG ホストに同じ内容を置く。

```bash
mkdir -p ~/wg && chmod 700 ~/wg
cp <このリポジトリ>/scripts/wireguard/site.env.example ~/wg/site.env
chmod 600 ~/wg/site.env
vi ~/wg/site.env                      # 上の変数表のとおりに埋める（クライアント帯は受ける拠点だけ）。公開鍵は手順 2 で書き足す
```

### 2. 鍵の生成と公開鍵の交換

**両拠点の WG ホストで実施する。** `wireguard-tools` を導入し、鍵ペアを生成する（既存の鍵があれば上書きしない）。

```bash
cd <このリポジトリ>/scripts/wireguard
sudo ./wg-vpn.sh -e ~/wg/site.env keygen A        # 拠点 B のホストでは B
```

```
公開鍵: <SITE_A_PUBKEY>
site.env の SITE_A_PUBKEY に書き、同じ site.env を相手拠点にも置いてください。
```

両拠点で鍵を作ったら、**それぞれの公開鍵を `site.env` に書き、両拠点の `site.env` を同じ内容にそろえる。**

```bash
vi ~/wg/site.env                      # SITE_A_PUBKEY と SITE_B_PUBKEY を埋める
```

**相手拠点の公開鍵は必須**（空のまま `apply` すると、何も変更せずに止まる）。相手に渡すのは公開鍵だけで、秘密鍵（`/etc/wireguard/wg0.key`）は拠点の外に出さない。

### 3. 適用

**両拠点の WG ホストで実施する。** `wg0.conf` の生成、IP フォワーディング、firewalld（専用ゾーンと、拠点間・クライアント用の policy）、`wg-quick@wg0` の有効化と起動をまとめて行い、最後にルーターへ入れる値を表示する。

```bash
sudo ./wg-vpn.sh -e ~/wg/site.env --dry-run apply A   # 実行予定の内容を確認する（秘密鍵は (hidden) と表示）
sudo ./wg-vpn.sh -e ~/wg/site.env apply A             # 適用する
```

- 拠点の指定（`A` / `B`）はこのホストの LAN 側 IP（`WG_x_LAN_IP`）と照合され、違えば何も変更せずに止まる
- 再実行しても設定は重複しない。`site.env` を変えたときやクライアントを足したときも、この `apply` で反映する（最後に必ず restart する）
- **`apply` の末尾に表示される値（ポート転送と静的経路）を、両拠点のルーターに入れる。** これが無いとトンネルは張れない（→ [補足: ルーターの設定](#ルーターの設定)）

拠点間の疎通は、ここまでで確認できる（[疎通確認](#5-疎通確認)）。

→ [スクリプトの動作](#スクリプトの動作)

### 4. クライアントの登録

**クライアントを受ける拠点のホストで実施する。** 台数分繰り返す（まとめて登録して、最後に 1 回だけ `apply` してもよい）。後から台数を足すときも同じ。

```bash
sudo ./wg-vpn.sh -e ~/wg/site.env client add A laptop      # 鍵を生成し、/etc/wireguard/clients/laptop.conf を書く（トンネル IP は帯の中で最小の空き。--ip で指定できる）
sudo ./wg-vpn.sh -e ~/wg/site.env client add A phone --pubkey 'クライアントから受け取った公開鍵'   # 鍵をクライアント側で作った場合
sudo ./wg-vpn.sh -e ~/wg/site.env apply A                  # 登録した [Peer] を wg0.conf に書いて restart
sudo ./wg-vpn.sh -e ~/wg/site.env client show laptop       # PC にはこの内容をコピーする
sudo ./wg-vpn.sh -e ~/wg/site.env client show phone --qr   # スマートフォンのアプリで読み取る（qrencode が必要。EL10 では epel-release が要る場合がある）
sudo rm /etc/wireguard/clients/laptop.conf                 # 取り込んだら、秘密鍵入りの conf をホストに残さない
```

- **反映は `apply`（restart）で行う。** `reload` では新しい peer の経路が入らない（[落とし穴 2](#落とし穴-2-reload-では経路が追加されない)）
- 登録は `~/wg/clients.list` に残り、`apply` のたびに同じ conf が組み立て直される
- `--pubkey` で登録した conf の `PrivateKey` は `<CLIENT_PRIVATE_KEY>` のままなので、端末側で自分の秘密鍵に置き換える
- どちらか片方の拠点で登録すれば、そのクライアントは**両拠点の LAN に届く**（両拠点で `apply` 済みで、両拠点のルーターにクライアント帯の静的経路がある前提。[パケットの流れ](#パケットの流れremote-client--各拠点)）。同じクライアントを両拠点に登録することはできない（[理由](#1-台のクライアントは-1-つの拠点にしか接続できない)）

→ [スクリプトの動作](#スクリプトの動作)

### 5. 疎通確認

**WG ホストで:**

```bash
sudo ./wg-vpn.sh -e ~/wg/site.env status     # wg show（latest handshake が 2 分以内）、wg0 の経路、サービス、ip_forward、ゾーンと policy、クライアントの最終ハンドシェイク
```

**拠点の LAN 上のクライアント同士**（Client A から）:

```bash
ping <Client B の IP>
tracepath -n <Client B の IP>
```

**外出先のクライアントから:**

```bash
ping <接続先拠点の LAN のホスト>     # 例: 192.168.110.100
ping <相手拠点の LAN のホスト>       # 例: 192.168.120.100
tracepath -n <相手拠点の LAN のホスト>
```

**逆方向（Client B → Client A、拠点の LAN → クライアント）も必ず確認する。** 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](#症状と原因の対応実測) を見る。

→ [疎通確認の補足](#疎通確認の補足)

---

## クライアントを削除する

クライアントを受ける拠点のホストで。登録簿とクライアント用 conf を消し、`apply` で `[Peer]` を外して restart する。

```bash
sudo ./wg-vpn.sh -e ~/wg/site.env client remove laptop && sudo ./wg-vpn.sh -e ~/wg/site.env apply A
```

---

## バックアップと復旧（OS の再インストール）

OS を入れ直しても、**ホストの秘密鍵が同じなら**、相手拠点の `site.env` も、配布済みのクライアントの conf も、ルーターの設定も**そのまま使える**。逆に鍵を作り直すと、相手拠点の公開鍵の差し替えと、クライアント全台の conf 再発行が連鎖する。

**バックアップを取る**（読むだけなので、トンネルを止めずに稼働中のホストで実行できる。両拠点でそれぞれ取る）:

```bash
cd <このリポジトリ>/scripts/wireguard
sudo ./wg-vpn.sh -e ~/wg/site.env --dry-run backup          # まとめる内容を表示するだけ
sudo ./wg-vpn.sh -e ~/wg/site.env backup                    # ~/wg-backup-<ホスト名>-<日時>.tar.gz（0600）
sudo ./wg-vpn.sh -e ~/wg/site.env -o /mnt/usb/wgb.tar.gz backup
```

- **このアーカイブには秘密鍵が入っている。** `0600` のまま、リポジトリの中には置かず、このマシンの外（別のディスク、オフラインのメディア）に保管する

**クリーンインストール後に復旧する**（`keygen` は実行しない。別の鍵ができ、復旧の意味が無くなる）:

```bash
cd <このリポジトリ>/scripts/wireguard
sudo ./wg-vpn.sh --dry-run restore ~/wg-backup-<ホスト名>-<日時>.tar.gz
sudo ./wg-vpn.sh restore ~/wg-backup-<ホスト名>-<日時>.tar.gz    # wireguard-tools の導入。鍵・conf・site.env・clients.list を元の場所へ戻す
sudo ./wg-vpn.sh -e ~/wg/site.env apply B                   # sysctl・firewalld・サービス。クライアントの [Peer] も clients.list から戻る
```

- `restore` は、鍵から算出した公開鍵が `site.env` の `SITE_x_PUBKEY` と一致することを確かめてから置く。一致すれば**相手拠点もクライアント端末も設定変更は要らない**
- ルーターのポート転送と静的経路は鍵に依存しないので変更不要（WG ホストの LAN 側 IP が変わった場合だけ入れ直す）

→ [バックアップと復旧の補足](#バックアップと復旧の補足)

---

## 全部消す（ロールバック）

> **鍵を消す前に。** 同じ鍵で戻す可能性が少しでもあるなら、先に[バックアップ](#バックアップと復旧os-の再インストール)を取る。鍵を作り直すと、相手拠点の `site.env` と conf の公開鍵の差し替え、クライアント全台の conf 再発行が連鎖する。

各拠点の WG ホストで:

```bash
sudo ./wg-vpn.sh -e ~/wg/site.env remove A            # サービス停止、policy・ゾーン・ポートの削除、sysctl を戻す（conf・鍵・クライアント用 conf は残す）
sudo ./wg-vpn.sh -e ~/wg/site.env remove A --purge    # conf・鍵・クライアント用 conf も消す（clients.list は残る）
rm -rf ~/wg                                           # site.env・clients.list（不要なら）
sudo dnf remove wireguard-tools systemd-resolved      # 不要なら
```

- ルーター側のポート転送と静的経路は手で削除する

→ [全部消すときの補足](#全部消すときの補足)

---

## 補足

手順の理由・実測・落とし穴・検証記録。手順を実行するだけなら読まなくてよい。

### 構成とパケットの流れ

- **構成**: 各拠点で、既存ルーターの配下にある AlmaLinux 1 台を WireGuard ホストにする（ルーターの置き換えはしない）。外出先のクライアントは、どちらかの拠点のホストに接続する
- **設定方式**: `wg-quick` + systemd（`/etc/wireguard/wg0.conf` / `wg-quick@wg0.service`）、firewalld の専用ゾーン + policy で転送を制御。クライアントを足すときも既存の `wg0` に `[Peer]` を加えるだけで、インターフェースも待ち受けポートも増やさない
- **スクリプト**: 本書のメインの手順は、同じ `site.env` を読んで手順をまとめて実行する [`scripts/wireguard/wg-vpn.sh`](../scripts/wireguard/wg-vpn.sh) を使う（拠点間の構築、クライアントの追加、鍵と設定のバックアップ・復旧に対応。[手順の流れ](#手順の流れ)）

拠点ルーターの配下に WG ホストを 1 台ずつ置き、`wg0` 同士をトンネルで結ぶ。外出先のクライアントは、どちらかの拠点の WG ホストに接続する（図は拠点 A で受ける場合）。WG host A から見ると、拠点 B の peer とクライアントの peer が同じ `wg0` に並ぶ。ルーターには**ポート転送**（WAN の `${WG_PORT}/udp` → WG ホスト。拠点間トンネルとクライアントの両方がこれを使う）と、**相手拠点 LAN とクライアント帯宛ての静的経路**（via 自拠点の WG ホスト）が要る（[ルーターの設定](#ルーターの設定)）。

#### パケットの流れ（Client A → Client B）

1. Client A は宛先 `${SITE_B_LAN}` を知らないので、デフォルトゲートウェイの **Router A** に送る
2. Router A の**静的経路**（`${SITE_B_LAN}` via `${WG_A_LAN_IP}`）で **WG host A** に転送される
3. WG host A は `wg0` の経路（`AllowedIPs` から wg-quick が自動で追加する）で暗号化し、Router B のグローバル IP へ UDP で送る
4. Router B の**ポート転送**で WG host B に届き、復号されて LAN B の Client B へ
5. 戻りは逆順（Client B → Router B → WG host B → トンネル → WG host A → Client A）

#### パケットの流れ（Remote client → 各拠点）

**Remote client → Client A（接続先拠点の LAN）**

1. クライアントは宛先 `${SITE_A_LAN}` を `AllowedIPs` に持つので、暗号化して `${SITE_A_PUBLIC}:${WG_PORT}` へ送る
2. Router A のポート転送で WG host A に届き、復号される。送信元 `${CLIENT_TUN_IP}` はそのクライアントの `[Peer]` の `AllowedIPs` に含まれるので受け入れられる
3. WG host A は `wg0` → LAN 側 NIC に転送する（policy `clientsA-to-siteA`）
4. 戻りは Client A → デフォルトゲートウェイの Router A → **静的経路 `${WG_A_CLIENT_NET}` via `${WG_A_LAN_IP}`** → WG host A（policy `siteA-to-clientsA`）→ ハンドシェイクで覚えたクライアントの endpoint へ

**Remote client → Client B（もう一方の拠点の LAN）**

1. WG host A で復号された後、宛先 `${SITE_B_LAN}` は `wg0` 向きの経路（拠点 B の peer の `AllowedIPs`）に当たるので、**同じ `wg0` から**拠点 B の peer へ再び暗号化して出て行く（policy `clientsA-to-siteB`。ingress・egress とも `wireguard` ゾーン）
2. WG host B で復号される。送信元 `${CLIENT_TUN_IP}` は**拠点 A の peer の `AllowedIPs` に `${WG_A_CLIENT_NET}` が入っていて初めて**受け入れられる。入っていなければ、WireGuard は ICMP も返さず黙って捨てる
3. WG host B は LAN 側に転送する（policy `clientsA-to-siteB`。こちらは `wireguard` → `${LAN_ZONE}`）
4. 戻りは Client B → Router B → **静的経路 `${WG_A_CLIENT_NET}` via `${WG_B_LAN_IP}`** → WG host B（`${WG_A_CLIENT_NET}` の経路は `wg0` 向き。policy `siteB-to-clientsA`）→ 拠点間トンネル → WG host A（`${CLIENT_TUN_IP}/32` の経路は `wg0` 向き。policy `siteB-to-clientsA`）→ クライアント

この折り返し（`wg0` から入って `wg0` へ出る転送）が成立することは、ラボで確認した（[付録](#リモートクライアントの検証2026-09-19)）。

したがって、必要な設定は次のとおり。

| 場所 | 必要な設定 |
|---|---|
| WG ホスト（両拠点） | WireGuard（相手拠点の peer の `AllowedIPs` に相手 LAN と相手拠点のクライアント帯を含める）、IP フォワーディング、firewalld の転送許可（`拠点 LAN ⇔ 相手拠点 LAN`、`クライアント帯 ⇔ 自拠点 LAN`、`クライアント帯 ⇔ 相手拠点 LAN` の policy） |
| WG ホスト（クライアントを受ける拠点） | 加えて、クライアントごとの `[Peer]`（`AllowedIPs` = そのクライアントの `/32`） |
| 拠点ルーター（両拠点） | WAN → `${WG_x_LAN_IP}:${WG_PORT}/udp` の**ポート転送**、`相手 LAN` と `クライアント帯`（両拠点の帯とも）via `${WG_x_LAN_IP}` の**静的経路** |
| 拠点の LAN 上のクライアント | 変更なし |
| 外出先のクライアント | conf を取り込む（`AllowedIPs` = 両拠点の LAN + `${WG_TUNNEL_NET}`） |

### 選択した方針

- **wg-quick + systemd** — 設定が 1 ファイルで完結し、情報も多い。NetworkManager は wg-quick が作った `wg0` を `connected (externally)` として扱うだけで干渉しなかった（実測）
- **値は `site.env` に集約し、両拠点で同じファイルを使う** — `site.env` は A/B 両拠点の値を並べて持つ。スクリプトは指定された拠点を**このホストの LAN 側 IP** と照合してから、自拠点・相手拠点の値を組み立てる。拠点ごとに手順を書き分けないので、**A/B の取り違えが起きない**
- **秘密鍵は `wg0.conf` に直接書く** — `PostUp` で別ファイルから読み込む書き方もできるが、`systemctl reload` で**秘密鍵が消えてトンネルが止まる**ことを実測で確認した（[落とし穴 1](#落とし穴-1-秘密鍵を-conf-の外に出すと-reload-で消える)）
- **firewalld は wg0 専用ゾーン + policy** — `wg0` を `trusted` や `internal` に入れると、firewalld 2.4 に同梱の `gateway-lan-to-world` policy（`internal home trusted` → `external public` を ACCEPT）が効いてしまい、意図しない範囲まで転送が通る。専用ゾーンを作り、policy の rich rule で**必要な組み合わせ（`拠点 A LAN ⇔ 拠点 B LAN`、`クライアント帯 ⇔ 各拠点 LAN`）だけ**を許可する
- **トンネルも、クライアントの通信も NAT しない** — 送信元 IP がそのまま相手拠点の LAN に届くので、相手側でアクセス元を識別・制限できる。その代わり、**両拠点のルーターに相手 LAN とクライアント帯の静的経路が要る**（[注意点](#ルーターにはクライアント帯の静的経路も要る)）
- **両拠点とも `Endpoint` と `PersistentKeepalive` を設定** — どちらからでもトンネルを張り直せる。片側がグローバル IP を持たない場合は[注意点](#片側がグローバル-ip-を持たない場合cgnat-など)を参照
- **クライアントは拠点に所属させ、拠点ごとにアドレス帯を分ける** — WireGuard はインターフェースごとに「この宛先はこの peer」という対応表（cryptokey routing）を持ち、**1 つのアドレスを 2 つの peer に対応づけることはできない**。WG host B から見ると拠点 A のクライアントはすべて拠点 A の peer の向こうにいるので、帯をまとめて `AllowedIPs` に 1 行書けばよく、クライアントを追加しても拠点 B 側の設定は変わらない。同じクライアントを両拠点に直接つなげる構成にすると、各ホストでそのクライアントの IP を「直接の peer」と「相手拠点の peer」の両方に書くことになり成立しない。片方の拠点だけで受けたい場合は、もう一方の帯を空にする
- **転送は方向ごとの policy で絞る** — `wg0` から入って `wg0` へ折り返す転送（クライアント → 相手拠点 LAN）は、ingress と egress に同じ `wireguard` ゾーンを指定した policy で許可する。ゾーンの `forward` オプション（`--add-forward`）でも通せるが、それだと `wg0` 内の転送がすべて通る（クライアント同士など）。**firewalld 2.4.3 は ingress と egress が同じゾーンの policy を受理し、実際に `wg0 → wg0` の転送に効くことをラボで確認した**（その policy を外すと、クライアント → 相手拠点 LAN だけが `Packet filtered` になる。実測）
- **クライアントの conf はホスト側で生成し、QR コードかファイルで渡す** — スマートフォンではこれが実用的。秘密鍵を拠点の外で作りたい場合は、クライアント側で鍵を作って公開鍵だけを渡す
- **反映は restart で行う** — 新しい peer の `AllowedIPs` に対する経路は reload では追加されない（[落とし穴 2](#落とし穴-2-reload-では経路が追加されない) と同じ機構。実測）。まとめて登録してから 1 回 restart する運用にする
- **クライアント同士の通信と、全トラフィックの VPN 経由（`0.0.0.0/0`）は対象外** — 必要なら[注意点](#クライアント同士を通す場合)を参照

### ルーターの設定

機種ごとに画面は違うので、要件だけを書く。**両拠点のルーターで実施する。** 入力する値は `apply` の末尾に表示される。あとから見るには:

```bash
./wg-vpn.sh -e ~/wg/site.env router A
```

```
---- 拠点 A のルーターに設定する値 ----
ポート転送 : WAN（198.51.100.1）の 51820/udp → 192.168.110.2:51820
静的経路   : 宛先 192.168.120.0/24 → ゲートウェイ 192.168.110.2
静的経路   : 宛先 10.99.1.0/24 → ゲートウェイ 192.168.110.2（拠点 A のクライアント）
DHCP 予約  : 192.168.110.2 をこの WG ホストに固定
（ルーターの LAN 側 IP: 192.168.110.1）
```

- クライアント帯の静的経路は**両拠点のルーターに、両拠点の帯とも**入れる（表示される分だけ。[理由](#ルーターにはクライアント帯の静的経路も要る)）

| 設定 | 拠点 A のルーター | 拠点 B のルーター |
|---|---|---|
| ポート転送（静的 NAT / NAPT） | WAN `${WG_PORT}/udp` → `${WG_A_LAN_IP}:${WG_PORT}` | WAN `${WG_PORT}/udp` → `${WG_B_LAN_IP}:${WG_PORT}` |
| 静的経路（相手拠点 LAN） | 宛先 `${SITE_B_LAN}` → ゲートウェイ `${WG_A_LAN_IP}` | 宛先 `${SITE_A_LAN}` → ゲートウェイ `${WG_B_LAN_IP}` |
| 静的経路（クライアント帯。**両拠点の帯とも**、値のあるもの） | 宛先 `${WG_A_CLIENT_NET}`・`${WG_B_CLIENT_NET}` → ゲートウェイ `${WG_A_LAN_IP}` | 宛先 `${WG_A_CLIENT_NET}`・`${WG_B_CLIENT_NET}` → ゲートウェイ `${WG_B_LAN_IP}` |
| DHCP | `${WG_A_LAN_IP}` を固定（予約）する | `${WG_B_LAN_IP}` を固定（予約）する |

- クライアント帯の静的経路は**両拠点のルーターに、両拠点の帯とも**入れる。NAT をしない構成なので、LAN 側ホストの返事はデフォルトゲートウェイに向かい、ルーターがクライアント帯を知らないとそこで行き場を失う（[注意点](#ルーターにはクライアント帯の静的経路も要る)）
- `${WG_TUNNEL_NET}` とクライアント帯を 1 つの大きな帯（例: `10.99.0.0/16`）の中に取っておけば、ルーターの静的経路はその帯 1 本で済む。[「WG ホスト自身から相手 LAN へ送る場合」](#wg-ホスト自身から相手-lan-へ送る場合)の問題（トンネル網への経路が無い）も同時に解消する
- WG ホスト自身のデフォルトゲートウェイは拠点ルーターのままでよい。ルーターに静的経路を入れられない場合と、折り返し（ヘアピン）の注意は[注意点](#ルーターの静的経路とヘアピン非対称経路)を参照

### スクリプトの動作

[`scripts/wireguard/wg-vpn.sh`](../scripts/wireguard/wg-vpn.sh) は、パッケージの導入からクライアントの登録までを `site.env` の値で実行する。クライアントの登録簿 `clients.list`（[`clients.list.example`](../scripts/wireguard/clients.list.example)）は `client add` が `site.env` と同じディレクトリに作る（クライアントを受ける拠点のホストにあればよい）。どちらも `.gitignore` で除外している。

`apply` の動作:

- **何かを変更する前に、次を検査する。** 1 つでも失敗したら何も変更せずに止まる
  - アドレスの形式、LAN・トンネル網・クライアント帯の重複、公開鍵の形式
  - `WG_x_LAN_IP` がこのホストにあるか（A/B の取り違えを防ぐ）
- **conf を生成する場合**: `PrivateKey` を直接書く（[落とし穴 1](#落とし穴-1-秘密鍵を-conf-の外に出すと-reload-で消える)）。既存の conf と内容が違えば、`.bak-日時` に退避してから書く。相手 peer の `AllowedIPs` には相手拠点のクライアント帯が、その後ろには `clients.list` に登録したクライアントの `[Peer]` が入る
- **既存の conf を使う場合**: `Address` に `WG_x_TUN_IP` が無い、または相手 LAN を `AllowedIPs` に含む `[Peer]` が無ければ**停止**。`ListenPort` の不一致、`PostUp` での秘密鍵読み込み、パーミッション、相手 peer にクライアント帯が無いことは**警告**
- **firewalld**: 設定が既にあるかを確かめてから追加するので、再実行しても設定が重複しない。クライアント用の policy は帯が設定されている分だけ作る
- **sysctl**: `ip_forward` だけを有効にする。`rp_filter` は strict（1）のままで動く（相手 LAN への経路が `wg0` を向いているので、逆経路チェックを通る）
- **サービス**: 最後は常に `systemctl restart` する（[落とし穴 2](#落とし穴-2-reload-では経路が追加されない)）。クライアントを追加・削除したときも `apply` で反映する
- **LAN_ZONE**: 空なら `WG_x_LAN_IP` を持つ NIC のゾーンを自動で使う
- **CGNAT 構成**: `SITE_x_PUBLIC` を空にすると、その拠点に向けた `Endpoint` を書かない
- **`client add` が作る conf**: ホスト側の `[Peer]` に `Endpoint` は書かず、ハンドシェイクを受けた送信元を endpoint として覚える（`PersistentKeepalive` もクライアント側にだけ書く）。クライアント側の `AllowedIPs` に `${WG_TUNNEL_NET}` を入れるのは、WG ホスト自身がクライアントに送るパケットの送信元が `wg0` のアドレスになるため。無いとクライアント側で捨てられる

`clients.list` に登録を残すので、**`apply` を何度実行しても同じ conf が組み立て直される**。`client add` は、帯の重複・名前や IP の重複・拠点の取り違えなどを**何かを書く前に**検査する。トンネル IP は `--ip` が無ければ帯の中で最小の空きを割り当てる。`remove A` はクライアント用の policy も削除し、`--purge` を付けると `clients.list` にあるクライアントの conf も消す（`clients.list` 自体は残す）。

手で作った conf とスクリプトが作る conf が一致することは、検証で `diff` して確認した（[付録](#変数形コマンドの再検証2026-09-19)）。スクリプトの検証範囲は[付録](#付録-スクリプトの検証)を参照。

`keygen` の動作: `wireguard-tools` が無ければ dnf で入れ、鍵が無ければ生成する。**既存の鍵は上書きしない**（公開鍵だけ表示し直す）。

`restore` の動作:

- **拠点（A/B）は鍵から判定する。** `backup` に `A|B` を付けてもよいが、付けなくても `site.env` の `SITE_x_PUBKEY` と突き合わせて決まる。LAN 側 IP には依存しないので、NIC 名や IP が変わったホストでもバックアップできる
- **`restore` は `-e` を付けなければ、アーカイブに記録された元の場所**（`~/wg/site.env` など）**に戻す。** 別の場所にしたいときだけ `-e` を付ける。`wg-env.sh` と `clients.list` は `site.env` と同じディレクトリに置かれる
- **何かを置く前に検査し、1 つでも失敗したら何も変更せずに止まる**
  - アーカイブの形式（`MANIFEST` の有無・`FORMAT`・絶対パスや `..` を含むエントリ）
  - 鍵から算出した公開鍵が `MANIFEST` および `site.env` の `SITE_x_PUBKEY` と一致するか
  - 復旧先が**相手拠点のホスト**でないか（両拠点が同じ鍵になる事故を止める）
  - どちらの拠点の LAN 側 IP もこのホストに無い場合は**警告にとどめて続行**する（再インストール直後はありうるため）
- 既にあるファイルは `.bak-日時` に退避してから置き換える（内容が同じなら「変更なし」で触らない）
- **パーミッションは `MANIFEST` の値をそのまま使わない。** 鍵・conf・`site.env` は 600 に固定して置く（細工したアーカイブで秘密鍵が 0644 になるのを防ぐ）
- `site.env` と `clients.list` は**置き先ディレクトリの所有者**で置く。`sudo` で実行しても `~/wg` 配下なら自分の所有のままなので、`client list` と `router` を非 root で実行できる
- **`restore` はサービスを起動しない。** 続けて `apply` を実行する。`wg0.conf` は `clients.list` から作り直されるので、クライアントの `[Peer]` も戻る
- クライアントの秘密鍵入り conf（`/etc/wireguard/clients/*.conf`）は**含めない**。ホストに残っていれば警告する

`remove` の動作: サービスを `disable --now` し、policy → ゾーン → 待ち受けポートの順に削除して reload する（削除で残る `*.xml.old` も消す）。`/etc/sysctl.d/90-wireguard.conf` を消して `ip_forward` を 0 に戻す。`--purge` を付けたときだけ `wg0.conf`・鍵・`clients.list` にあるクライアント用 conf を消す。`clients.list`・`~/wg`・パッケージは残し、ルーター側は手で戻す。

### 疎通確認の補足

`latest handshake` が表示されない場合は、トンネルが張れていない。調べる順番は次のとおり:

1. 相手の公開鍵・`Endpoint` の書き間違い（`site.env` の `SITE_x_PUBKEY` を両拠点でそろえたか）
2. 相手ルーターのポート転送
3. 相手 WG ホストの firewalld の `${WG_PORT}/udp`

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
- 1 ホップ目が `${ROUTER_A_LAN_IP}` で、2 ホップ目に `asymm` と出るのは、Redirect を受け入れないクライアント（[ヘアピン](#ルーターの静的経路とヘアピン非対称経路)参照）

**逆方向（Client B → Client A）も必ず確認する。** 片側の firewalld policy やルーターの静的経路が抜けていると、片方向だけ失敗する。TCP も確認しておくとよい（例: 片側で `python3 -m http.server 8080`、もう片側から `curl http://<IP>:8080/`。検証では `HTTP 200` を確認した）。

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

**逆方向（拠点の LAN → クライアント）も確認する。** ルーターの静的経路か クライアント用の policy が抜けていると、片方向だけ失敗する。

### 症状と原因の対応（実測）

| 症状 | 原因 |
|---|---|
| クライアントの ping に `From ${WG_A_LAN_IP} ... Packet filtered` | WG ホストの firewalld が転送を拒否している（policy 未設定、rich rule のサブネット誤り） |
| `wg show` の handshake は成立しているのに、クライアントの ping が無応答 | 相手側の firewalld policy、相手ルーターの静的経路、**相手の `ip_forward`** のいずれか。両拠点で `apply` したか確認する |
| WG ホスト自身から相手 LAN へ ping できないのに、クライアント同士は通る | 下記「[WG ホスト自身から相手 LAN へ送る場合](#wg-ホスト自身から相手-lan-へ送る場合)」 |
| クライアントから相手の**トンネル IP** へ ping すると `Destination Net Unreachable`（送信元は自拠点ルーター） | ルーターに `${WG_TUNNEL_NET}` の経路が無いため。クライアント同士の通信には不要 |
| 自拠点から張ったトンネルは動くのに、相手側から張ろうとすると失敗する | 自拠点の firewalld で `${WG_PORT}/udp` を開け忘れている、またはルーターのポート転送が無い |
| トンネル越しに WG ホスト自身の ssh / Cockpit に `No route to host`。**同じ宛先に ping は通る** | `${WG_FW_ZONE}` ゾーンに ssh / cockpit を開けていない。policy は転送用なのでホスト自身宛てには効かない（[トンネル越しに WG ホスト自身の ssh や Cockpit へ入る場合](#トンネル越しに-wg-ホスト自身の-ssh-や-cockpit-へ入る場合)） |
| クライアントの ping に `From ${MY_TUN_IP} ... Packet filtered` で、宛先が**相手拠点 LAN のときだけ**失敗する | `wg0 → wg0` の policy（`clientsA-to-siteB`）が無い。検証では、この policy を外すと自拠点 LAN への ping は通ったまま相手拠点 LAN だけが落ちた |
| クライアントの ping に `From ${MY_LAN_IP} ... Packet filtered` | 自拠点 LAN 向けの policy（`clientsA-to-siteA`）が無い |
| ハンドシェイクは成立するのに、相手拠点 LAN へ**まったく応答が無い**（ICMP も返らない） | 相手拠点のホストの `AllowedIPs` にクライアント帯が無い。WireGuard は範囲外の送信元を黙って捨てる。両拠点の `site.env` に帯を書いて両拠点で `apply` したか確認する |
| クライアントを足したのに届かない。`wg show` には出ている | `reload` で済ませた。`restart` する（[落とし穴 2](#落とし穴-2-reload-では経路が追加されない)） |
| 拠点の LAN からクライアントへ接続できない（逆方向だけ失敗） | ルーターにクライアント帯の静的経路が無い、または クライアント用の policy が無い |
| クライアントから WG ホスト自身（`${MY_TUN_IP}`）に届かない | クライアント conf の `AllowedIPs` に `${WG_TUNNEL_NET}` が入っていない |
| OS を入れ直した後、相手拠点とハンドシェイクが成立しない | 鍵を戻していない（`wg genkey` で別の鍵を作った）。`sudo wg pubkey < /etc/wireguard/wg0.key` が `site.env` の `SITE_x_PUBKEY` と一致するか確かめる（[バックアップと復旧](#バックアップと復旧os-の再インストール)） |

### 注意点

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

`systemctl reload wg-quick@wg0` は WireGuard の設定（peer・AllowedIPs など）だけを差し替え、**`ip route` は変更しない**。`AllowedIPs` に範囲を追加して reload すると、`wg show` には新しい範囲が出るが、経路が無いのでその範囲宛てのパケットはトンネルに入らない（実測）:

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

#### 転送を片方向だけ・特定ホストだけに絞る場合

`apply` が作る policy は双方向（拠点 A → B と B → A、クライアント → LAN と LAN → クライアント）。片方向だけ許可したい場合（例: 拠点 A から B へは接続できるが B から A へは接続させない）は、逆向きの policy（`siteB-to-siteA` など）を `sudo firewall-cmd --permanent --delete-policy=<名前>` で消して `--reload` する。戻りのパケットは conntrack で許可されるので、許可した側から始めた通信は成立する。相手 LAN のうち特定ホスト・ポートだけに絞る場合は、policy の rich rule の `destination address` を `/32` にする、`port port=... protocol=tcp` を付けるなどで調整する。

#### `AllowedIPs` が cryptokey routing の要

`AllowedIPs` は次の 2 つの役割を持つ。

- **受信時**: トンネルから届いたパケットの送信元がこの範囲外なら捨てる
- **送信時**: この範囲宛てのパケットをこの peer に送る。**wg-quick はこの範囲をそのまま `wg0` への経路としても追加する**

そのため、相手の**トンネル IP だけでなく相手の LAN も**書く。クライアント帯を使う場合はそれも入る。スクリプトが相手 peer の `AllowedIPs` にこれを組み立てる。`journalctl -u wg-quick@wg0` で、起動時に経路が追加されるのを確認できる。

この対応表は **1 インターフェース内で peer ごとに排他**で、1 つのアドレスを 2 つの peer に対応づけることはできない。だからクライアントは拠点に所属させ、拠点ごとに帯を分ける（[選択した方針](#選択した方針)）。

> `0.0.0.0/0` を書くと、WG ホスト自身の通信も含めてすべてがトンネルに向かう（wg-quick が policy routing で差し替える）。拠点間接続では相手 LAN だけを書く。

#### ルーターの静的経路とヘアピン（非対称経路）

この構成では、Client A の最初のパケットは Router A に行き、**同じ LAN 側インターフェースへ折り返して**（ヘアピン）WG host A に届く。このとき:

- Linux ルーター（検証時の Router A）は **ICMP Redirect** を返し、それを受け入れたクライアントは以降 WG host A に直接送る（`ip route get` に `<redirected>` と出る）
- Redirect を受け入れないクライアントでは、毎回 Router A 経由のままになる
- いずれの場合も戻りのパケットは WG host A から Client A へ直接届くため、**Router A から見ると片方向しか通らない非対称経路**になる

検証では、Redirect を受け入れる場合・拒否する場合（`accept_redirects=0`）の両方で双方向 ping・TCP が通った。ただし **Router A には NAT やファイアウォールの状態追跡を持たせていない**。市販ルーターや UTM のなかには、LAN 内で折り返す転送を拒否するもの、戻りが見えない TCP セッションを途中で切るものがある。つながらない、あるいは TCP だけが不安定な場合は、ルーター側で折り返し転送を許可する設定を探すか、次の代替策をとる。

- **(a) クライアントに経路を追加する** — 通信するクライアントにだけ `${SITE_B_LAN} via ${WG_A_LAN_IP}` を入れる。ルーターを通らないので非対称経路も起きない。台数が多いと管理が大変になる（DHCP option 121 を配布できるルーターなら一括で配れる）
- **(b) WG ホストで NAT する（masquerade）** — 相手拠点から届いた通信の送信元を WG ホストの IP に書き換えれば、戻りは WG ホスト宛てになるので、自拠点ルーターの静的経路は不要になる。ただし **(1) 送信元のクライアントが相手からは区別できなくなり、(2) NAT した側への着信はできない**（片方向になる）。双方向に通信するという今回の要件は満たせないので、**最後の手段**としてだけ使う。本書では未検証

#### ルーターにはクライアント帯の静的経路も要る

NAT をしない構成なので、LAN 側ホストの返事はデフォルトゲートウェイ（ルーター）に向かう。ルーターがクライアント帯を知らないと、そこで行き場を失う。**両拠点のルーター**に要る。`${WG_TUNNEL_NET}` とクライアント帯を 1 つの大きな帯に取っておけば、静的経路は 1 本で済む。

#### 相手拠点のホストが帯を知らないと黙って捨てる

WireGuard は、`AllowedIPs` の範囲外から届いたパケットを **ICMP も返さずに**捨てる。相手拠点のホストの `AllowedIPs` にクライアント帯が入っていないと、ハンドシェイクも転送も正常に見えたまま届かない。**両拠点の** `site.env` に帯を書き、両拠点で `apply` すること。

#### WG ホスト自身から相手 LAN へ送る場合

WG ホスト自身が送るパケットは、`wg0` の経路により**送信元がトンネル IP（`${WG_A_TUN_IP}`）になる**。相手拠点のクライアントは `${WG_TUNNEL_NET}` への経路を持たないので、返事をデフォルトゲートウェイの Router B に送り、そこで行き場を失う。

```
$ ip route get 192.168.120.100
192.168.120.100 dev wg0 src 10.99.0.1 uid 1000
$ ping -c1 -W2 192.168.120.100
1 packets transmitted, 0 received, 100% packet loss
$ ping -c1 -W2 -I 192.168.110.2 192.168.120.100      ← 送信元を LAN 側 IP にすると通る
1 packets transmitted, 1 received, 0% packet loss
```

**クライアント同士の通信には影響しない。** WG ホスト自身からも相手 LAN を使いたい場合は、次のどちらかにする。

- **送信元を LAN 側 IP にする**（`ping -I`、アプリ側での bind など）。設定変更が要らないので簡単
- 相手ルーターに `${WG_TUNNEL_NET}` via `${WG_x_LAN_IP}` の静的経路を追加し、**あわせて両拠点の policy にトンネル網を送信元とする rich rule を足す**（下記のとおり、静的経路だけでは足りないことがある）

> **失敗の仕方は 2 通りある。** 実機（2026-09-19、拠点 B のホストから拠点 A のルーター宛て。アドレスは本書の例に合わせて書き換えてある）では、policy の rich rule が `source address` を相手拠点 LAN に限定しているため、**トンネル IP を送信元とするパケットが相手ホストの firewalld で拒否**された。ルーターには届いていない。
>
> ```
> $ ip route get 192.168.110.1
> 192.168.110.1 dev wg0 src 10.99.0.2           ← 送信元がトンネル IP になる
> $ ping -c2 -W2 192.168.110.1
> From 10.99.0.1 icmp_seq=1 Packet filtered     ← 相手 WG ホストの wg0 が ICMP admin-prohibited を返す
> $ ping -c2 -W2 -I 192.168.120.2 192.168.110.1 ← 送信元を LAN 側 IP にすると通る
> 2 packets transmitted, 2 received, 0% packet loss
> ```
>
> policy を通した場合でも、相手拠点のホストが `${WG_TUNNEL_NET}` への経路を持たなければ戻りが届かず、今度は**無応答**になる（上のラボの例）。`Packet filtered` なら policy、無応答なら経路を疑う。

#### トンネル越しに WG ホスト自身の ssh や Cockpit へ入る場合

`wg0` を入れた `${WG_FW_ZONE}` ゾーンは**何も開いていない**（スクリプトはこのゾーンに何も開けない。WireGuard の待ち受けポートは LAN 側ゾーンで開けるので、このゾーンには何も要らない）。そのため、トンネル越しに **WG ホスト自身**の ssh や Cockpit へ接続すると firewalld が拒否し、クライアントには `No route to host` と出る（ICMP admin-prohibited を受けて `connect()` が `EHOSTUNREACH` を返すため。ポートが閉じているときの `Connection refused` とは違う）。

**`ping` は通る。** firewalld はゾーンで ICMP echo を既定ではブロックしないので、「ping は通るのに ssh だけ入れない」という見え方になる。

転送用の policy は**転送**を制御するもので、**ホスト自身宛ての通信には効かない**。相手拠点 LAN の他のホストへは通るのに WG ホストにだけ入れないのは、このため。

実測（拠点 B のホストから拠点 A へ。2026-09-19）:

| 宛先 | 種別 | 結果 |
|---|---|---|
| `ping ${WG_A_LAN_IP}`（WG ホスト A 自身） | 入力 | 応答あり（ICMP は既定で通る） |
| `ssh ${WG_A_LAN_IP}` | 入力 | `No route to host`（送信元が LAN 側 IP でもトンネル IP でも同じ） |
| `http://${ROUTER_A_LAN_IP}/`（ルーター A） | 転送 | 通る（policy に一致する送信元なら） |

入れるようにするには、**入られる側のホストで**次を実行する。`${WG_FW_ZONE}` に届くのは WireGuard の鍵で認証を通った通信だけなので、ゾーンごと開ければ相手拠点の LAN からも、リモートクライアントからも入れる。

```bash
sudo firewall-cmd --permanent --zone="$WG_FW_ZONE" --add-service=ssh --add-service=cockpit
sudo firewall-cmd --reload
sudo firewall-cmd --info-zone="$WG_FW_ZONE"        # services: cockpit ssh
```

送信元を絞りたい場合は、ゾーンに rich rule を入れる（相手拠点 LAN・トンネル網・クライアント帯のうち、値のあるものだけ）。

```bash
for s in ssh cockpit; do
  for net in "$PEER_LAN" "$WG_TUNNEL_NET" "$MY_CLIENT_NET" "$PEER_CLIENT_NET"; do
    [ -n "$net" ] || continue
    sudo firewall-cmd --permanent --zone="$WG_FW_ZONE" \
      --add-rich-rule="rule family=ipv4 source address=$net service name=$s accept"
  done
done
sudo firewall-cmd --reload
sudo firewall-cmd --zone="$WG_FW_ZONE" --list-rich-rules
```

- **両拠点で入れるようにしたいなら、両拠点で実行する。** 片方だけだと、その向きにしか入れない
- rich rule 版は、あとでクライアント帯を足したときに**その帯も追加する**（ゾーンごと開ける版なら不要）
- Cockpit は `9090/tcp`（firewalld の `cockpit` サービス）。ホスト側で動いているかは `systemctl is-active cockpit.socket` で確認する。ブラウザからは `https://${WG_x_LAN_IP}:9090`
- `wg0` はゾーンに**永続**で入っているので、`--reload` しても `${WG_FW_ZONE}` から外れない（実測）
- ssh を開けると、トンネルの向こう側全体から届くようになる。公開鍵認証のみにする（`PasswordAuthentication no`）などの対策は別途行う

#### 片側がグローバル IP を持たない場合（CGNAT など）

着信を受けられない側（例: 拠点 A）が常にトンネルを張りに行く構成にする。`site.env` では、着信を受けられない拠点の `SITE_x_PUBLIC` を空にする。

| | 着信を受けられない側（A） | グローバル IP がある側（B） |
|---|---|---|
| `[Peer]` の `Endpoint` | **必須**（`${SITE_B_PUBLIC}:${WG_PORT}`） | 省略する |
| `PersistentKeepalive` | **必須**（NAT のマッピングを維持するため） | 不要 |
| ルーターのポート転送 | 不要 | **必須** |
| firewalld の `${WG_PORT}/udp` | 不要 | **必須** |

スクリプトは、相手拠点の `SITE_x_PUBLIC` が空なら `Endpoint` 行を書かない。

WireGuard は、正しく認証できたパケットの送信元を peer の endpoint として覚える。そのため、`Endpoint` を書いていない側もハンドシェイクを受けた後は返信先がわかる。付録の検証では、`Endpoint` を持たない側の `wg show` に、相手の endpoint が表示された（[付録](#待ち受けポートを開け忘れた場合)）。ただし、**着信を受けた側から先に通信を始めることはできない**。A の keepalive でトンネルが維持されている間だけ、B 側のクライアントから A 側へ接続できる。**両側とも `Endpoint` を省略すると、どちらからもトンネルを張れない。**

#### 1 台のクライアントは 1 つの拠点にしか接続できない

cryptokey routing の制約（[`AllowedIPs` が cryptokey routing の要](#allowedips-が-cryptokey-routing-の要)）。両拠点に同時に直接つなぐ構成は成立しない。接続先を変えたい場合は、その拠点用の conf を別に作って切り替える（トンネル IP も別の帯のものになる）。

#### 着信を受けられない拠点はクライアントを受けられない

クライアントは `Endpoint` を指定して接続しに行くので、接続先拠点にはグローバル IP（または DDNS 名）とポート転送が要る。CGNAT の拠点（`SITE_x_PUBLIC` が空）では `WG_x_CLIENT_NET` も空にする。

#### クライアントが拠点の LAN 内にいるとき

ノート PC を持ち帰って拠点 A の LAN 内で VPN を張ると、`${SITE_A_PUBLIC}` 宛ての通信が自拠点のルーターに出て折り返す（ヘアピン）。ルーターが対応していないと接続できない。LAN 内では VPN を切る運用にするのが簡単。

#### クライアントの秘密鍵の扱い

ホスト側で鍵を作ると、秘密鍵入りの conf が一時的にホストに残る。**クライアントに取り込んだら消す**（手順 4 の最後の `rm`）。より厳密にするなら、クライアント側で鍵を作って公開鍵だけをホストに渡す。

#### `DNS =` を書く場合

クライアント conf の `[Interface]` に `DNS = ${WG_CLIENT_DNS}` を書くと、VPN 接続中の名前解決を拠点側の DNS に向けられる。Linux の `wg-quick` はこのとき `resolvconf` を呼ぶので、`systemd-resolved` が有効である必要がある（EL10 では `wireguard-tools` の依存で入るが **disabled のまま**なので、使うなら `systemctl enable --now systemd-resolved`）。公式アプリ（Windows / macOS / iOS / Android）では追加の設定は要らない。本書の検証では `DNS =` を使っていない。

#### 全トラフィックを VPN 経由にする場合（対象外）

クライアント conf の `AllowedIPs` を `0.0.0.0/0` にすると、そのクライアントの通信がすべてトンネルに入る。拠点側で NAT（masquerade）と外向きの policy が追加で要る。本書の構成（拠点の LAN にだけ届く）とは別物なので扱わない。

#### クライアント同士を通す場合

クライアント A → クライアント B は、どちらも同じ `wg0` にぶら下がる `wg0 → wg0` の転送になる。`clientsA-to-siteB` と同じ形の policy（ingress・egress とも `wireguard`、送信元・宛先ともクライアント帯）を足せば通せる。本書では作らない（必要になる場面が少なく、クライアント同士を隔離しておくほうが安全なため）。

#### Endpoint に DDNS 名を書く場合

`Endpoint` のホスト名は **`wg-quick up` の時点で一度だけ名前解決される**（`wg(8)` の仕様）。相手のグローバル IP が変わると、再起動するまで古い IP に送り続ける。対策:

- `wireguard-tools` 同梱の `/usr/share/doc/wireguard-tools/contrib/reresolve-dns/reresolve-dns.sh` を systemd timer で定期実行する
- 片側だけでも固定 IP にし、そちらを常に接続を受ける側にする（上記の CGNAT 構成と同じ形）。動的 IP の側が張りに行くので、その側の IP が変わっても、固定 IP の側は新しい送信元を endpoint として覚え直す

クライアント conf の `Endpoint` に DDNS 名を書いた場合も同じだが、**公式アプリは接続のたびに名前解決する**ので `reresolve-dns.sh` のような仕組みは要らない。本書では未検証。

#### MTU

wg-quick は wg0 の MTU を既定で **1420** にする（IPv4/IPv6 の外側ヘッダー分を引いた値）。PPPoE（MTU 1454 / 1492 など）の回線では、トンネル内の最大サイズの通信だけが通らないことがある（ping は通るが、大きなファイル転送や一部の HTTPS が止まる）。その場合は `site.env` の `WG_MTU` に `1380` などと書いて `apply` し直す（`MTU =` の行は `WG_MTU` が空なら書かれず、書いてあれば入る）。外出先のクライアントでも、モバイル回線によっては同じことが起きる（クライアント conf の `[Interface]` に `MTU =` を書く）。本書の検証環境（MTU 1500 の veth）ではこの問題は起きていない。

#### LAN サブネットの重複

両拠点の LAN が同じサブネット（例: どちらも `192.168.1.0/24`）だと経路を区別できないので、この構成は成立しない。家庭用ルーターの初期値のままの拠点同士を結ぶ場合は、どちらかの LAN のアドレスを変える必要がある。

#### 再起動後の自動起動

`systemctl enable` 済みなので OS 起動時に `wg-quick@wg0` が上がる。検証は namespace を使っていたため、**実際の OS 再起動での確認はしていない**（`systemctl restart` と `firewall-cmd --complete-reload` の後に、ゾーン割り当て・経路・疎通が戻ることは確認済み）。

### バックアップと復旧の補足

**残しておく価値があるのは「鍵」と「値を書いたファイル」だけ。** `wg0.conf`・sysctl・firewalld は `apply` で作り直せる。

#### 何を保存し、何は手順で作り直せるか

| 対象 | 場所 | バックアップ | 失ったときの代償 |
|---|---|---|---|
| **ホストの秘密鍵** `${WG_IFACE}.key` | `/etc/wireguard/` | **必須** | 公開鍵が変わる。**相手拠点の `site.env` と conf の差し替え**、**クライアント全台の conf 再発行**が要る |
| `site.env` | `~/wg/` | **必須** | 変数表を見ながら書き直す |
| `clients.list`（スクリプトでクライアントを運用する場合） | `site.env` と同じディレクトリ | **必須** | 各クライアントの公開鍵とトンネル IP を失う。端末側の conf から読み出すか、全台登録し直す |
| `${WG_IFACE}.conf` | `/etc/wireguard/` | 入れる | `apply` が `clients.list` から作り直す |
| `${WG_IFACE}.pub` | `/etc/wireguard/` | 入れる | なし（`wg pubkey < ${WG_IFACE}.key` で再計算できる） |
| `/etc/sysctl.d/90-wireguard.conf` | — | 入れない | なし（`apply`） |
| firewalld のゾーン・policy | `/etc/firewalld/` | 入れない | なし（`apply`） |
| クライアントの秘密鍵・クライアント用 conf | **端末側**（ホストからは手順 4 で削除済み） | **入れない** | ホストの鍵が同じなら端末はそのままでよい |
| `wireguard-tools` | — | 入れない | なし（`keygen` / `apply` が入れる） |
| ルーターのポート転送・静的経路 | 拠点ルーター | 入れない（機器側に残る） | WG ホストの LAN 側 IP が変わったときだけ入れ直す（[ルーターの設定](#ルーターの設定)） |

> **鍵は「拠点の身元」そのもので、ポート転送も静的経路も鍵とは無関係。** だから OS を入れ直しても**ルーターは触らなくてよい**。ただし再インストールで WG ホストの LAN 側 IP が変わった場合は別で、ポート転送の転送先と両拠点の静的経路のゲートウェイを入れ直す（[ルーターの設定](#ルーターの設定)）。DHCP 予約を入れてあれば変わらない。

**バックアップを取るときの注意:**

- クライアントの秘密鍵入り conf は**入れない**。手順 4 で端末に渡した時点で消してあり、ホストの鍵が同じなら端末側はそのまま動く

**クリーンインストール後に復旧するときの注意:**

- **`/etc/wireguard` の外から持ってきたファイルは `install`（新規作成）で置き、`restorecon` をかける。** `mv` で持ち込むと SELinux のコンテキスト（`user_tmp_t` など）を持ち越し、`wg-quick` が鍵を読めなくなることがある
- **相手拠点は何もしなくてよい。** 公開鍵が同じなので相手の conf も `site.env` も変更不要。トンネルは `PersistentKeepalive`（既定 25 秒）で張り直される
- **配布済みのクライアント conf もそのまま。** クライアント側の `[Peer] PublicKey` はホストの公開鍵で、これが変わっていない

#### 鍵を失った場合

鍵を失ったら、その拠点の身元を作り直すことになる。手順は多いが決まっている。

1. 鍵ファイル（`/etc/wireguard/wg0.key`・`.pub`）を消して `keygen` し直し、新しい公開鍵を**両拠点の `site.env`** の `SITE_x_PUBKEY` に書く
2. **相手拠点**でも `apply`（conf の作り直しと restart）を行う。相手拠点も一度止まる
3. **クライアント全台**の conf の `[Peer] PublicKey` を書き換えて配り直す（端末側の conf の `[Peer] PublicKey` を書き換えるだけでもよい）。QR で配っている場合も全台やり直し
4. クライアントの**秘密鍵**は変わらないので、`clients.list` が残っていれば `[Peer]` の作り直しは不要（`wg-vpn.sh apply` が `clients.list` から作り直す）

`clients.list` も失った場合は、各クライアントの公開鍵を端末側の conf から読み出すか、全台を登録し直す。

### 全部消すときの補足

- **policy を消す前にゾーンを消すと firewalld が壊れる。** `wireguard` ゾーンを先に削除すると、そのゾーンを参照している policy が残るため、`--reload` が `Error: INVALID_ZONE: Policy 'clientsA-to-siteA': 'wireguard' not among existing zones` で失敗する（実測）。上のループのように policy を先に消す
- **policy の存在確認に `--query-policy` は使えない。** firewalld 2.4.3 にそのオプションは無く、`unrecognized arguments` で終了コード 2 を返すため、「存在しない」と誤判定してすべての削除が飛ばされる（実測）。`--info-policy` の終了コードで判定する
- firewalld は削除時に `/etc/firewalld/policies/*.xml.old` と `/etc/firewalld/zones/wireguard.xml.old` を残す。完全に消したい場合は手で削除する

### 参照

- [wg(8)](https://man7.org/linux/man-pages/man8/wg.8.html) / [wg-quick(8)](https://man7.org/linux/man-pages/man8/wg-quick.8.html) — `AllowedIPs` と cryptokey routing
- [WireGuard: Quick Start](https://www.wireguard.com/quickstart/)
- [WireGuard: Conceptual Overview](https://www.wireguard.com/#cryptokey-routing)
- [firewalld: Policy Objects](https://firewalld.org/2020/09/policy-objects-introduction)
- [firewalld ソース `src/firewall/core/io/policy.py`](https://github.com/firewalld/firewalld/blob/v2.4.3/src/firewall/core/io/policy.py) — ingress/egress ゾーンの検証（同一ゾーンを拒否する規則は無い。policy 名の上限は 128 文字）
- [nwdiag](http://blockdiag.com/en/nwdiag/) — 本書の構成図の記述に使っている（[付録: 構成図の再生成](#付録-構成図の再生成)）

### 付録: network namespace による検証

> 検証当時の手順書は、1 コマンドずつ貼る手動手順（手動手順 0〜10）だった。その本文はこのリポジトリの履歴（コミット `e26df03` 以前の `docs/wireguard.md`）にある。この付録と次の付録の「手動手順 N」はそれを指す。

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

### 付録: 構成図の再生成

`## 構成` の図は [nwdiag](http://blockdiag.com/en/nwdiag/) のソースから生成している。**原本は `docs/diagrams/*.diag`、`*.svg` は生成物。** 図を直すときは `.diag` を直して再生成する。

```bash
sudo dnf install -y google-noto-sans-cjk-vf-fonts   # Latin と日本語の両方を持つフォント
python3 -m ensurepip --user                         # pip が無い場合
python3 -m pip install --user nwdiag                # blockdiag / Pillow などが一緒に入る

python3 scripts/render-diagrams.py                  # docs/diagrams/*.diag → *.svg
```

`nwdiag` を直接呼ばずに [`scripts/render-diagrams.py`](../scripts/render-diagrams.py) を通すのは、**nwdiag 3.0.0 が Pillow 10 以降で動かない**ため。`ImageFont.getsize()` と `Image.ANTIALIAS` が Pillow 10 で削除されており、そのまま実行すると次で止まる（実測）。

```
ERROR: 'FreeTypeFont' object has no attribute 'getsize'
```

Pillow を 10 未満に固定する回避策は取れない。`getsize` が残っている最後の Pillow 9.5.0 は Python 3.12 に対応しておらず、**両方を満たすバージョンが存在しない**。スクリプトは削除された 2 つの API を呼び出し前に補うだけで、site-packages には手を加えない。

フォントの指定も必須。**blockdiag の自動検出は IPAfont・VL Gothic・DejaVu などのパスを決め打ちで探す**ので、このマシンのフォントは見つからず、指定しないとラベルが豆腐になる。別のフォントを使う場合は `WG_DIAG_FONT` で渡す。

スクリプトは生成後の SVG に次の 3 つの後処理も行う。いずれも blockdiag の出力そのままでは不都合があるため。

| 後処理 | 理由 |
|---|---|
| 白い背景の矩形を最初の子要素として挿入する | **blockdiag の SVG は背景が透明で、線と文字が黒**。GitHub のダークテーマに置くと図が沈んで見えなくなる。`nwdiag --no-transparency` は `(PNG only)` で SVG には効かない |
| `font-family` に CJK フォントを前置する | blockdiag は `font-family="sans-serif"` としか書かない。フォント fallback をしないレンダラではこれが Latin 専用フォントに解決され、**日本語だけが消える**（cairosvg で実際に起きた）。ブラウザは fallback するので GitHub 上では出るが、指定しておくほうが確実 |
| `viewBox` の幅を実測して広げる | blockdiag は**ノードの位置だけでキャンバス幅を決める**ので、右端のノードに付く長いラベルが canvas の外に出て切れる。実際に `${SITE_B_LAN}.100` の末尾が欠けていた |

図は**テーマに関係なく常に白地**で表示される。ダークモードでは白いカードに見えるが、GitHub のライト／ダークに加えて、VS Code のプレビュー、ブラウザでの直接表示、印刷でも同じように読める。

> 検証環境に最初から入っていた日本語フォント（Droid 系 2 つ）は、**どちらも Latin の字形を持たない**。`Client A` や `${SITE_A_LAN}` が豆腐になるため、Latin と日本語の両方を持つ Noto Sans CJK を入れている。
