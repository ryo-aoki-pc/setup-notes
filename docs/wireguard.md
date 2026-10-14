# WireGuard のセットアップ（AlmaLinux 10・Windows 11）

- 2 つの拠点の AlmaLinux 10 の PC（WG ホスト）を WireGuard の VPN でつなぎ、外出先の AlmaLinux 10・Windows 11 の PC から、どちらかの拠点へつなぐ
- 検証記録・参考資料・ロールバックと注意点は、各項のリードから開く

> [!IMPORTANT]
> - **前提と実行場所（どのホスト・どの窓か）は、各項のリードに従う**。AlmaLinux 10 の項は自分のユーザーの bash で行い、`sudo -i`・`su -` のシェルでは行わない
> - AlmaLinux 10 の項は、[AlmaLinux 10 のセットアップ](almalinux-setup.md)と同じく、パスワードを聞かない `sudo` を前提に書いてある。各項のリードの前提に無くても、その項を行うユーザーで[ログインと sudo](almalinux-setup.md#ログインと-sudo)を先に通す
> - Windows 11 の項は、[Windows 11 のセットアップ](windows-setup.md)と同じく、**この PC のデスクトップで、Administrators のユーザーが行う**。PowerShell のブロックは **Windows PowerShell 5.1** に貼る。管理者・通常（管理者ではない）の窓は、各項のリードに従う
> - Windows 11 で[貼り付けの設定](windows-setup.md#貼り付けの設定)より前は **Ctrl+V で貼る**。設定後は GitHub のコピーボタンでコピーし、右クリックで貼れる

- どの項も単独で通せる。目的の項のリードの前提を先に満たす
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 新しい端末では、使う項の変数の手順を貼り直す
- Windows 11 で GitHub のコピーボタンでコピーしたブロックは末尾に改行が無いので、貼った後に Enter を押す
- AlmaLinux 10 の `wireguard-tools` は、[AlmaLinux 10 のセットアップの「更新」](almalinux-setup.md#更新)の OS の更新で上がる。Windows 11 の WireGuard は、[WireGuard: Windows 11 の更新](#wireguard-windows-11-の更新)で上げる

## AlmaLinux 10 で使う

- WG ホスト（拠点）の設定とクライアントの登録、AlmaLinux 10 の PC からの接続

### WireGuard

- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/wireguard.md)・[参考資料](reference/wireguard.md)・[ロールバックと注意点](extra/wireguard.md)

> [!IMPORTANT]
> - **拠点の WG ホスト用の手順**。外出先の PC は[AlmaLinux](#wireguard-almalinux-10-の-pc-からつなぐ)・[Windows](#windows-11-で-wireguard-を使う)の手順から通す
> - [site.env を作る](#wireguard-siteenv-を作る)の手順 1〜3 と[鍵を作って適用する](#wireguard-鍵を作って適用する)の手順 1〜6 は**両拠点の WG ホストで**、同じ項の手順 7 は**両拠点のルーターで行う**
> - [クライアント登録](#wireguard-クライアントを登録する)の手順 1〜7・9 と[疎通確認](#wireguard-状態と疎通を確かめる)の手順 1・2 は**受ける拠点のホストで行う**
> - [クライアント登録](#wireguard-クライアントを登録する)の手順 8 と[疎通確認](#wireguard-状態と疎通を確かめる)の手順 3 はクライアントで行う
> - コマンドはすべて `${REPO}/scripts/wireguard`（`REPO` は、各項の手順 1 で設定する clone 先）で実行し、`-e ~/wg/site.env` で値を渡す
> - **拠点 B のホストでは、引数の `A` を `B` に読み替える**
> - [site.env を作る](#wireguard-siteenv-を作る)の手順 2 と[鍵を作って適用する](#wireguard-鍵を作って適用する)の手順 3 で、**`vi` が開く**。保存して閉じてから次の手順を行う
> - **OS を入れ直して同じ鍵で戻したい場合は、先に[バックアップと復旧](#wireguard-バックアップと復旧os-の再インストール)を読む**。鍵さえ残っていれば、相手拠点の設定も配布済みのクライアント conf も変えずに復旧できる

- `REPO` を使う項は、その項の手順 1 で `REPO` を設定したシェルで実行する。新しいシェルを開いたら、その項の手順 1 を貼り直す
  - `./wg-vpn.sh` で始まるブロックは、その項の中で先に貼った `cd` で移った先（`<REPO>/scripts/wireguard`）で貼る
  - 項の途中でシェルを開き直したら、その項の手順 1 を貼り直した後に `cd "$REPO/scripts/wireguard"` を打ってから続ける。`sudo: ./wg-vpn.sh: コマンドが見つかりません` と出たら、これが抜けている

> [!WARNING]
> **トンネル越しに ssh して作業している場合、`apply` の restart で自分のセッションが切れる。**
>
> - 対象は[鍵の適用](#wireguard-鍵を作って適用する)の手順 6 と[クライアント登録](#wireguard-クライアントを登録する)の手順 5
> - [MTU の変更](#wireguard-回線に合わせて-mtu-を下げる)と[クライアント削除](#wireguard-クライアントを削除する)の `apply` も対象
> - 切り離して実行する方法は、[落とし穴](#wireguard-落とし穴-apply-は作業中の-ssh-経路そのものを切る)にある

#### WireGuard: site.env を作る

- 両拠点の WG ホストで、`wg-vpn.sh` に渡す値を書いた `~/wg/site.env` を作り、両拠点に同じ内容で置く
- 前提: 両拠点の WG ホストに、このリポジトリ（setup-notes）を clone してある
- 実行場所: 両拠点の WG ホストの、自分のユーザーのシェル（bash）

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
   vi ~/wg/site.env                      # 公開鍵は「鍵を作って適用する」の手順 3 で書き足す
   ```

   - **編集するのは `~/wg/site.env` だけ。** 埋める値は[設定値の表](#wireguard-siteenv-に書く値)にある（クライアント帯は、クライアントを受ける拠点にだけ書く）
   - 書けたら、保存して `vi` を閉じる

1. 書いた `site.env` を、両拠点の WG ホストの `~/wg/site.env` に同じ内容で置く。

   - **次の手順は、両拠点に置いてから貼る**

#### WireGuard: 鍵を作って適用する

- 両拠点の WG ホストで、WG ホストの鍵ペアを作り、`site.env` の設定を適用する（つなぐ側の AlmaLinux 10 の PC の鍵は、[鍵を作る](#wireguard-鍵を作る)で作る）
- 前提: 両拠点の WG ホストで、[ログインと sudo](almalinux-setup.md#ログインと-sudo)と[site.env を作る](#wireguard-siteenv-を作る)を通してある
- 実行場所: 両拠点の WG ホストの、自分のユーザーのシェル（bash）。この項の手順 7 は、両拠点のルーターで行う

1. 変数を設定する。

   ```bash
   REPO=~/setup-notes                    # このリポジトリを clone した場所（「site.env を作る」の手順 1 と同じ）
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'REPO = %s\n' "${REPO}"
   ```

   - clone 先が `~/setup-notes` なら、既定のままでよい。[site.env を作る](#wireguard-siteenv-を作る)の手順 1 と同じ値にする
   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**、この項の手順 1 を貼り直してから先へ進む

1. 両拠点の WG ホストで、`wireguard-tools` を入れて鍵ペアを作る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   cd "${REPO:?この項の手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
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
   printf '\n\033[7m 確認 \033[0m\n'
   cd "${REPO:?この項の手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
   sudo ./wg-vpn.sh -e ~/wg/site.env --dry-run apply A   # 拠点 B のホストでは B。秘密鍵は (hidden) と表示
   ```

   - **次の手順は、表示された内容でよいか確かめてから貼る**

1. 両拠点の WG ホストで、設定を適用する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env apply A             # 拠点 B のホストでは B
   ```

   - 末尾に、ルーターに入れる値（ポート転送と静的経路）が表示される（この項の手順 7）
   - 拠点の指定（`A` / `B`）はこのホストの LAN 側 IP（`WG_x_LAN_IP`）と照合され、違えば何も変更せずに止まる
   - **注意**: トンネル越しの ssh で作業していると、`apply` の restart で切れる（冒頭の警告）

1. 両拠点のルーターに、この項の手順 6 の `apply` の末尾に表示された値を入れる。

   - 入れるのは、ポート転送と静的経路
   - **次の手順は、両拠点のルーターに入れてから貼る**

#### WireGuard: クライアントを登録する

- クライアントを受ける拠点の WG ホストで、クライアント（PC・スマートフォン）を登録して反映し、クライアント用 conf を渡す
- 前提: 両拠点の WG ホストで、[鍵を作って適用する](#wireguard-鍵を作って適用する)を通してある
- 実行場所: クライアントを受ける拠点の WG ホストの、自分のユーザーのシェル（bash）。この項の手順 8 は、クライアント（PC・スマートフォン）で行う

1. クライアントを受ける拠点の WG ホストで変数を設定し、登録済みのクライアントを確かめる（`SITE` と `CLIENT_NAME` は必ず値を入れる）。

   ```bash
   SITE=A                               # クライアントを受ける拠点（A または B）
   ```

   ```bash
   CLIENT_NAME=laptop                   # 登録簿（clients.list）に載せる名前。英数字・-・_ のみ
   ```

   ```bash
   CLIENT_PUBKEY=                       # クライアント側で鍵を作ったときだけ、その公開鍵（44 文字）を貼る。鍵をホストで作るときは空のまま
   ```

   ```bash
   REPO=~/setup-notes                   # WG ホスト上でこのリポジトリを clone した場所（「site.env を作る」の手順 1 と同じ）
   printf '\n\033[7m 確認 \033[0m\n'
   cd "${REPO:?REPO が空のまま}/scripts/wireguard" && ./wg-vpn.sh -e ~/wg/site.env client list
   ```

   - 編集が必須なのは、`SITE` と `CLIENT_NAME` の 2 ブロック。`CLIENT_PUBKEY` は、クライアント側で鍵を作ったとき（この項の手順 4）だけ入れる
   - `REPO` は、clone 先が `~/setup-notes` なら既定のままでよい
   - 最後に、登録済みのクライアントを一覧で確認する
   - `CLIENT_NAME` と同じ名前が一覧に無ければ、この項の手順 2 は飛ばす
   - 変数はそのシェルの中だけで有効。WG ホストのシェルを開き直したら、この手順のブロックを貼り直す
   - 複数のクライアントを登録するときは、1 台ごとにこの手順から貼り直す

1. `CLIENT_NAME` と同じ名前が一覧にあるときだけ、旧登録を消して反映する。

   - [クライアントを削除する](#wireguard-クライアントを削除する)の手順 1〜6 を行う。`CLIENT_NAME`・`SITE`・`REPO` はこの項の手順 1 と同じ値にする
   - 削除前の公開鍵を控え、未知 peer がその鍵だけであることを確かめてから、削除を明示的に許可する。無関係の peer が出たら止める
   - 削除が反映されると、その旧鍵では接続できなくなる。トンネル越しの ssh で作業していた場合は、別の経路から WG ホストに入り直す
   - この項の手順 4 の `CLIENT_PUBKEY` は、クライアントで作った新しい鍵の公開鍵のままにする。WG ホストのシェルを開き直したらこの項の手順 1 の変数を設定し直す

1. 鍵をホストで作るときは、クライアントを登録する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env client add "${SITE:?この項の手順 1 の SITE が空のまま}" "${CLIENT_NAME:?この項の手順 1 の CLIENT_NAME が空のまま}"
   ```

   - **鍵をどちらで作るかで、この項の手順 3・4 のどちらかを選ぶ**（両方を上から順に貼るものではない）

1. 鍵をクライアント側で作ったときは（この項の手順 3 の代わりに）、公開鍵で登録する。

   ```bash
   if [ -z "${CLIENT_PUBKEY}" ]; then echo '中断: CLIENT_PUBKEY が空のまま。クライアントで作った公開鍵を、この項の手順 1 に入れて貼り直す' >&2; else
     sudo ./wg-vpn.sh -e ~/wg/site.env client add "${SITE:?この項の手順 1 の SITE が空のまま}" "${CLIENT_NAME:?この項の手順 1 の CLIENT_NAME が空のまま}" --pubkey "${CLIENT_PUBKEY}"
   fi
   ```

   - 公開鍵は[AlmaLinux の鍵作成](#wireguard-鍵を作る)の手順 3、[Windows の鍵作成](#wireguard-windows-11-で-wireguard-と鍵を用意する)の手順 5 で用意する

1. クライアントの台数分、この項の手順 1〜4 を繰り返したら、まとめて反映する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env apply "${SITE:?この項の手順 1 の SITE が空のまま}"      # 登録した [Peer] を wg0.conf に書いて restart
   ```

   - 同じクライアントを両拠点に登録することはできない（[理由](extra/wireguard.md#1-台のクライアントは-1-つの拠点にしか接続できない)）
   - **注意**: トンネル越しの ssh で作業していると、`apply` の restart で切れる（冒頭の警告）
   - **次の手順は、`apply` が終わってから貼る**

1. PC に渡すときは、クライアント用 conf を表示する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env client show "${CLIENT_NAME:?この項の手順 1 の CLIENT_NAME が空のまま}"
   ```

   - 表示した内容を、この項の手順 8 で PC に取り込む
   - この項の手順 4 の `--pubkey` で登録した conf は、`PrivateKey` がプレースホルダのままなので、**秘密情報を含まない**

1. スマートフォンに渡すときは、クライアント用 conf を QR コードで表示する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env client show "${CLIENT_NAME:?この項の手順 1 の CLIENT_NAME が空のまま}" --qr   # qrencode が必要。EL10 では epel-release が要る場合がある
   ```

   - 表示した QR コードを、この項の手順 8 でスマートフォンに読み取らせる
   - `ERROR: qrencode がありません` と出て止まったら、`sudo dnf install -y qrencode` で入れてから、この手順を貼り直す
     - AlmaLinux 10 では、`qrencode` は EPEL にある（EPEL は、[EPEL と RPM Fusion](almalinux-setup.md#epel-と-rpm-fusion)の手順 1 で有効にする）

1. クライアントで、この項の手順 6・7 の conf を取り込む。

   - AlmaLinux 10 の PC は、[conf を取り込む](#wireguard-conf-を取り込む)の手順 1〜5
   - Windows 11 の PC は、[Windows 11 で WG ホストに登録して取り込む](#wireguard-windows-11-で-wg-ホストに登録して取り込む)の手順 1・2・4・5（手順 2 で関数を定義した後に、この項の `client show` の出力をコピーし直してから、手順 4 を行う）
   - スマートフォンは、この項の手順 7 の QR コードを読み取る
   - この項の手順 4 の `--pubkey` で登録したときは、conf の `PrivateKey`（`<CLIENT_PRIVATE_KEY>`）を、端末側で自分の秘密鍵に置き換える
   - **次の手順は、クライアントに取り込んでから貼る**

1. 鍵をホストで作ったときは、秘密鍵入りの conf をホストから消す。

   ```bash
   sudo rm "/etc/wireguard/clients/${CLIENT_NAME:?この項の手順 1 の CLIENT_NAME が空のまま}.conf"
   ```

   - 取り込む前に conf を消すと再発行が必要になる（`client remove` してから登録し直す）

#### WireGuard: 状態と疎通を確かめる

- 受ける拠点の WG ホストで WireGuard の状態を見て、クライアントから疎通を確かめる
- 前提: 両拠点の WG ホストで、[鍵を作って適用する](#wireguard-鍵を作って適用する)を通してある。外出先のクライアントからも確かめるときは、[クライアントを登録する](#wireguard-クライアントを登録する)を通してある
- 実行場所: 受ける拠点の WG ホストの、自分のユーザーのシェル（bash）。この項の手順 3 は、クライアントで行う

1. 変数を設定する。

   ```bash
   REPO=~/setup-notes                    # WG ホスト上でこのリポジトリを clone した場所（「site.env を作る」の手順 1 と同じ）
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'REPO = %s\n' "${REPO}"
   ```

   - clone 先が `~/setup-notes` なら、既定のままでよい。[site.env を作る](#wireguard-siteenv-を作る)の手順 1 と同じ値にする
   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**、この項の手順 1 を貼り直してから先へ進む

1. WG ホストで状態を見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   cd "${REPO:?この項の手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
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
   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [検証記録の症状と原因の対応](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/wireguard.md#症状と原因の対応実測) を見る

#### WireGuard: AlmaLinux 10 の PC からつなぐ

> [!IMPORTANT]
> - **この項は AlmaLinux 10 の PC のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で-wireguard-を使う)から通す（管理者の Windows PowerShell 5.1 に貼る）
> - **PC で実行する**。[WG ホストに登録する](#wireguard-wg-ホストに登録する)の手順と、[トンネルを確かめる](#wireguard-トンネルを確かめる)の WG ホストで確かめる手順だけ、WG ホストで実行する
> - **`sudo -i` した root のシェルではなく、自分のシェルで貼る**。`~` が自分のホームになるため
> - [conf を取り込む](#wireguard-conf-を取り込む)の手順 2 で **`vi` が開く**。`client show` の出力を貼って保存し、閉じてから次の手順を貼る
> - [conf を取り込む](#wireguard-conf-を取り込む)の手順 4 で、**PC を拠点の LAN の外のネットワークにつなぐ**（スマートフォンのテザリングなど）。その後の手順は LAN の外で行う

- 変数のある項は、その項の手順 1 で変数を設定したシェルに貼る

##### WireGuard: 鍵を作る

- つなぐ側の AlmaLinux 10 の PC で、`wireguard-tools` を入れ、この PC の鍵ペアを作る（拠点の WG ホストの鍵は、[鍵を作って適用する](#wireguard-鍵を作って適用する)で作る）
- 前提: この PC で[ログインと sudo](almalinux-setup.md#ログインと-sudo)を通してある。拠点の WG ホストで、[状態と疎通を確かめる](#wireguard-状態と疎通を確かめる)まで通してある
- 実行場所: つなぐ側の AlmaLinux 10 の PC の、自分のユーザーの端末（bash）

1. 変数を設定する。

   ```bash
   WG_DIR=~/wg-client                   # 鍵と conf の一時置き場（「トンネルを確かめる」の手順 7 で秘密鍵と conf を消す）
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'WG_DIR = %s\n' "${WG_DIR}"
   ```

   - 鍵と conf の一時置き場（`WG_DIR`）は既定のままでよい
   - 最後に値を読み戻して確かめる
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**（SSH を張り直したあとも）、この項の手順 1 を貼り直してから先へ進む

1. `wireguard-tools` を入れる。

   ```bash
   {
     sudo dnf install -y wireguard-tools
     printf '\n\033[7m 確認 \033[0m\n'
     rpm -q wireguard-tools NetworkManager systemd-resolved
     systemctl is-enabled systemd-resolved         # disabled（依存で入るだけ。本手順では有効にしない）
     modinfo -n wireguard                          # カーネル同梱のモジュールのパスが出る
   }
   ```

1. 鍵ペアを作る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -e "${WG_DIR:?この項の手順 1 の WG_DIR が空のまま}/wg0.key" ]; then echo '中断: wg0.key が既にある（作り直すなら先に消す。WG ホストに登録済みの公開鍵と対応しなくなる）' >&2; else
     mkdir -p "${WG_DIR}" && chmod 700 "${WG_DIR}" &&
     ( umask 077; wg genkey | tee "${WG_DIR}/wg0.key" | wg pubkey > "${WG_DIR}/wg0.pub" ) &&
     ls -l "${WG_DIR}/wg0.key" "${WG_DIR}/wg0.pub" &&           # どちらも -rw------- で 45 バイト
     cat "${WG_DIR}/wg0.pub"                                     # この 1 行（公開鍵）を WG ホストへ渡す。秘密鍵（.key）は渡さない
   fi
   ```

   - 表示された公開鍵（44 文字）だけを、[WG ホストに登録する](#wireguard-wg-ホストに登録する)の手順 1 で WG ホストに渡す

##### WireGuard: WG ホストに登録する

- クライアントを受ける拠点の WG ホストで、この PC の公開鍵を登録して反映し、クライアント用 conf を PC へ持っていく
- 前提: [鍵を作る](#wireguard-鍵を作る)を通し、この PC の公開鍵を表示してある
- 実行場所: クライアントを受ける拠点の WG ホストの、自分のユーザーのシェル（bash）

1. WG ホストで、[クライアントを登録する](#wireguard-クライアントを登録する)の手順 1・2・4・5 を行い、この PC の公開鍵を登録して反映する。

   - 同じ項の手順 1 の `CLIENT_PUBKEY` には、[鍵を作る](#wireguard-鍵を作る)の手順 3 で PC に表示された公開鍵（44 文字）を貼る
   - 同じ項の手順 1 の `CLIENT_NAME` は、この PC だけの名前にする（例 `laptop`）
   - **トンネル越しの ssh は、同じ項の手順 5 の `apply` の restart で切れる**。切り離して実行する方法は[落とし穴](#wireguard-落とし穴-apply-は作業中の-ssh-経路そのものを切る)を参照する

1. WG ホストで、[クライアントを登録する](#wireguard-クライアントを登録する)の手順 6 の `client show` の出力をコピーし、PC へ持っていく。

   - `PrivateKey` はプレースホルダのままなので、**秘密情報を含まない**。どの経路で運んでもよい
   - **次の手順は、`client show` の出力を PC に持ってきてから貼る**

##### WireGuard: conf を取り込む

- つなぐ側の AlmaLinux 10 の PC で、クライアント用 conf に秘密鍵を入れ、拠点の LAN の外で NetworkManager に取り込む
- 前提: [WG ホストに登録する](#wireguard-wg-ホストに登録する)を通し、`client show` の出力を PC に持ってきてある
- 実行場所: つなぐ側の AlmaLinux 10 の PC の、自分のユーザーの端末（bash）

1. 変数を設定する。

   ```bash
   WG_DIR=~/wg-client                   # 鍵と conf の一時置き場（「鍵を作る」の手順 1 と同じ）
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'WG_DIR = %s\n' "${WG_DIR}"
   ```

   - [鍵を作る](#wireguard-鍵を作る)の手順 1 と同じ値にする（既定のままなら、変えなくてよい）
   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**、この項の手順 1 を貼り直してから先へ進む

1. PC で、[WG ホストに登録する](#wireguard-wg-ホストに登録する)の手順 2 の `client show` の出力を `vi` に貼り、`wg0.conf` に保存する。

   ```bash
   ( umask 077; vi "${WG_DIR:?この項の手順 1 の WG_DIR が空のまま}/wg0.conf" )    # 「WG ホストに登録する」の手順 2 の client show の出力をそのまま貼って保存する
   ```

   - `client show` の出力は、WG ホストの端末からコピーする
   - **ファイル名は `wg0.conf` にする**
   - ファイルで渡すなら、WG ホストで `client show` の出力をファイルに書き出し、`scp` で `${WG_DIR}/wg0.conf` に置く
   - **次の手順は、保存して `vi` を閉じてから貼る**（続けて貼ると `vi` への入力として食われる）

1. `PrivateKey` 行だけを、[鍵を作る](#wireguard-鍵を作る)の手順 3 の秘密鍵に置き換える（鍵は表示しない）。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ "$(grep -c '^PrivateKey *=' "${WG_DIR:?この項の手順 1 の WG_DIR が空のまま}/wg0.conf" 2>/dev/null)" != 1 ] || [ ! -s "${WG_DIR}/wg0.key" ]; then
     echo '中断: wg0.conf の PrivateKey 行が 1 行ちょうどでないか、wg0.key が無い' >&2
   else
     sed -i "s|^PrivateKey *=.*|PrivateKey = $(cat "${WG_DIR}/wg0.key")|" "${WG_DIR}/wg0.conf" &&
     grep -c '^PrivateKey = [A-Za-z0-9+/]\{43\}=$' "${WG_DIR}/wg0.conf" &&    # 1（置き換わった。鍵そのものは表示しない）
     grep -v '^PrivateKey' "${WG_DIR}/wg0.conf"                                # 残りの行を目で確かめる（Address / PublicKey / Endpoint / AllowedIPs。拠点が WG_MTU を書いていれば MTU も）
   fi
   ```

1. PC を、拠点の LAN の外のネットワークにつなぐ（スマートフォンのテザリングなど）。

   - LAN 内でこの項の手順 5 を貼ると、そこで通信が切れる
   - **次の手順は、LAN の外につないでから貼る**

1. 拠点の LAN の外で、conf を NetworkManager に取り込み、自動で張られたトンネルをすぐ切る。

   ```bash
   {
     sudo nmcli connection import type wireguard file "${WG_DIR:?この項の手順 1 の WG_DIR が空のまま}/wg0.conf" &&
     sudo nmcli connection modify wg0 connection.autoconnect no &&
     nmcli -f NAME,TYPE,DEVICE,STATE,AUTOCONNECT connection show | grep -E '^(NAME|wg0 )'    # STATE は activated（import 直後に張られる）。AUTOCONNECT は no
     nmcli -t -f NAME,STATE connection show | grep -qx 'wg0:activated' && sudo nmcli connection down wg0    # 張られていたら切る（「トンネルを確かめる」の手順 2 で改めて張る）
     printf '\n\033[7m 確認 \033[0m\n'
     nmcli -f connection.id,connection.interface-name,connection.autoconnect,connection.zone,ipv4.method,ipv4.addresses,ipv4.dns,ipv6.method,wireguard connection show wg0
     sudo ls -l /etc/NetworkManager/system-connections/wg0.nmconnection     # -rw------- root root。秘密鍵はこの中（表示はしない）
   }
   ```

   - **注意**: LAN 内でこの手順を貼ってしまうと、そこで通信が切れて、その後の手順を貼れなくなる。その場合は PC のコンソールで `sudo nmcli connection down wg0`
   - 日本語の表示では、コメントの `activated` は `アクティベート済み`、`no` は `いいえ` と出る
   - 最後に、プロファイルの内容と秘密鍵の保存先を確認する。見るところは次のとおり
     - `ipv4.method` が `manual`
     - `ipv4.addresses` が `<CLIENT_TUN_IP>/32`
     - `ipv4.dns` が `--`
     - `wireguard.private-key` が `<hidden>`
     - `wireguard.peer-routes` が `yes`（日本語の表示では `はい`）
     - `wireguard.peers` に接続先拠点の公開鍵

##### WireGuard: トンネルを確かめる

- つなぐ側の AlmaLinux 10 の PC でトンネルを張り、拠点への疎通と、拠点から PC への逆方向を確かめる
- 前提: [conf を取り込む](#wireguard-conf-を取り込む)を通してある
- 実行場所: 拠点の LAN の外につないだ、つなぐ側の AlmaLinux 10 の PC の、自分のユーザーの端末（bash）。この項の手順 4・5 は、クライアントを受ける拠点の WG ホストの、自分のユーザーのシェルで行う

1. PC で、変数を設定する（4 つの IP は必ず値を入れる）。

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
   WG_DIR=~/wg-client                   # 鍵と conf の一時置き場（「鍵を作る」の手順 1 と同じ）
   printf '\n\033[7m 確認 \033[0m\n'
   for v in WG_HOST_TUN_IP WG_HOST_LAN_IP ROUTER_LAN_IP PEER_WG_LAN_IP WG_DIR; do
     printf '%-15s = %s\n' "$v" "${!v}"
   done
   ```

   - 編集が必須なのは、1 行ずつの 4 ブロック
   - `WG_DIR` は、[鍵を作る](#wireguard-鍵を作る)の手順 1 と同じ値にする（既定のままなら、変えなくてよい）
   - 最後に値を読み戻して確かめる
   - 例の値は拠点 A がクライアントを受ける構成のもの。拠点 B が受ける構成なら、`site.env` の `*_B_*` 側の値が入っていること
   - **既定値のままでもエラーにならない**ので、4 つの IP を書き換えたか必ずここで確かめる
   - 変数はそのシェルの中だけで有効。**新しいシェルを開いたら**（SSH を張り直したあとも）、この項の手順 1 の 5 つのブロックを貼り直してから先へ進む

1. 拠点の LAN の外で、トンネルを張る。

   ```bash
   {
     printf '\n\033[7m 確認 \033[0m\n'
     sudo nmcli connection up wg0 &&
     nmcli device status | grep -E '^(DEVICE|wg0 )' &&                            # wireguard  connected  wg0
     nmcli -f GENERAL.STATE,IP4.ADDRESS,IP4.ROUTE,IP4.DNS connection show wg0 &&   # activated。IP4.ROUTE に AllowedIPs の 3 経路（mt = 50）
     ip -4 route show dev wg0 &&                                                  # 同じ 3 経路と metric
     ip link show dev wg0 | grep -o 'mtu [0-9]*' &&                               # 1420（conf に MTU = があれば、その値）
     sudo wg show wg0                                                             # latest handshake が数秒前、transfer の received が 0 でない
     sudo firewall-cmd --get-active-zones           # wg0 が既定ゾーン public に入る
     cat /etc/resolv.conf                           # 「鍵を作る」の手順 2 の前と同じ（DNS = が無いので変わらない）
     sudo ausearch -m AVC -ts recent                # <no matches>
   }
   ```

   - 日本語の表示では、コメントの `connected` は `接続済み`、`activated` は `アクティベート済み` と出る

1. PC で、トンネル IP → WG ホストの LAN 側 → ルーター → 相手拠点の順に疎通を試す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   for h in "${WG_HOST_TUN_IP:?この項の手順 1 の変数が空のまま}" "${WG_HOST_LAN_IP:?}" "${ROUTER_LAN_IP:?}" "${PEER_WG_LAN_IP:?}"; do
     echo "== $h"; ping -c 3 -W 2 "$h" | tail -2
   done
   tracepath -n "${PEER_WG_LAN_IP:?}"             # <WG_HOST_TUN_IP> → <PEER_WG_LAN_IP> の順に出る
   ```

   - `tracepath` の `<PEER_WG_LAN_IP>` の行が `!H` で終わっても、4 つの `ping` が `0% packet loss` なら届いている
   - 相手拠点の LAN 上の別のホストへの `ping`、トンネル越しの `ssh <ユーザー>@<WG_HOST_LAN_IP>` も試しておくとよい
   - どこで止まるかで、疑う場所が変わる（→ [検証記録の補足](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/wireguard.md#road-warrior-実施手順--トンネルを確かめる--手順-2-補足-疎通確認)）

1. WG ホストで、変数を設定する（`CLIENT_NAME` は必ず値を入れる）。

   ```bash
   CLIENT_NAME=laptop                   # この PC を登録簿（clients.list）に載せた名前（「クライアントを登録する」の手順 1 と同じ）
   ```

   ```bash
   REPO=~/setup-notes                   # WG ホスト上でこのリポジトリを clone した場所（「site.env を作る」の手順 1 と同じ）
   printf '\n\033[7m 確認 \033[0m\n'
   for v in CLIENT_NAME REPO; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - 編集が必須なのは `CLIENT_NAME` の 1 ブロック。[クライアントを登録する](#wireguard-クライアントを登録する)の手順 1 で、この PC に付けた名前を入れる
   - `REPO` は、clone 先が `~/setup-notes` なら既定のままでよい
   - 最後に値を読み戻して確かめる
   - WG ホストのシェルを開き直したら、この項の手順 4 を貼り直す

1. WG ホストで、ハンドシェイクと逆方向（拠点 → PC）を確かめる。

   ```bash
   if [ -z "${REPO}" ] || [ -z "${CLIENT_NAME}" ]; then echo '中断: この項の手順 4 の REPO と CLIENT_NAME を設定してから貼り直す' >&2; else
     printf '\n\033[7m 確認 \033[0m\n'
     cd "${REPO}/scripts/wireguard" &&
     sudo ./wg-vpn.sh -e ~/wg/site.env client list &&                                        # LAST_HANDSHAKE が「N 秒前」
     CLIENT_TUN_IP=$(awk -v n="${CLIENT_NAME}" '$1 == n { print $3 }' ~/wg/clients.list) &&
     ping -c 3 "${CLIENT_TUN_IP:?clients.list にその名前が無い}"                              # 拠点 → PC（PC の public ゾーンは ping に応答する）
   fi
   ```

   - 接続先拠点の LAN 上の別のホストから `ping <CLIENT_TUN_IP>` も通る（ルーターにクライアント帯の静的経路がある前提）
   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/wireguard.md#症状と原因の対応実測)

1. PC で、トンネルを切る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   sudo nmcli connection down wg0 &&
   nmcli device status | grep -E '^(DEVICE|wg0 )'         # wg0 の行が消える
   ```

   - 日常は、外出先で `sudo nmcli connection up wg0`、拠点に戻る前に `sudo nmcli connection down wg0`

1. PC で、平文の鍵と conf を消す。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   rm -f "${WG_DIR:?この項の手順 1 の WG_DIR が空のまま}/wg0.key" "${WG_DIR}/wg0.conf" &&
   ls -l "${WG_DIR}"                                       # wg0.pub だけ残る
   ```

#### WireGuard: 回線に合わせて MTU を下げる

- 両拠点の WG ホストで、`wg0` の MTU を回線に合わせて下げ、配布済みのクライアントにも同じ値を入れる
- 小さい通信は通るのに、大きい通信だけ遅い・止まるときに行う（ssh の画面の描き直し、ファイル転送、一部の HTTPS）
- 前提: 両拠点の WG ホストで、[鍵を作って適用する](#wireguard-鍵を作って適用する)を通してある
- 実行場所: 両拠点の WG ホストの、自分のユーザーのシェル（bash）。この項の手順 9 は、クライアントで行う
- `WG_MTU` は両拠点で同じ値にする
- **トンネル越しに ssh して作業している場合、この項の手順 7 の restart で自分のセッションが切れる**（→ [落とし穴](#wireguard-落とし穴-apply-は作業中の-ssh-経路そのものを切る)）
- 配布済みのクライアントの MTU は、`apply` では変わらない（この項の手順 9 で入れる。→ [注意点の MTU](extra/wireguard.md#mtu)）
- → [補足](reference/wireguard.md#回線に合わせて-mtu-を下げる--手順-2-補足-wg_mtu-に書く値)

1. 変数を設定する。

   ```bash
   REPO=~/setup-notes                    # WG ホスト上でこのリポジトリを clone した場所（「site.env を作る」の手順 1 と同じ）
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'REPO = %s\n' "${REPO}"
   ```

   - clone 先が `~/setup-notes` なら、既定のままでよい。[site.env を作る](#wireguard-siteenv-を作る)の手順 1 と同じ値にする
   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**、この項の手順 1 を貼り直してから先へ進む

1. 両拠点の WG ホストで、回線の MTU と今の `wg0` の MTU を調べる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   tracepath -n -m 8 1.1.1.1 | grep -o 'pmtu [0-9]*' | tail -n 1
   ip -o link show dev wg0 | grep -o 'mtu [0-9]*'
   ```

   - `pmtu` の値を、両拠点の分とも控える
   - `WG_MTU` に書く値は、両拠点の `pmtu` の小さいほうから 60 を引いた値以下にする（1454 なら 1394 以下。例: `1380`）
   - `Endpoint` が IPv6 のアドレスのときは、60 ではなく 80 を引く
   - その値が今の `wg0` の `mtu` 以上なら、下げなくてよい（この項はここで終える）

1. `site.env` の `WG_MTU` に、この項の手順 2 で決めた値を書く。

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
   - この項の手順 6・7 も、切れてよいときに必ず行う（行わないと、`wg-quick@wg0` の restart や OS の再起動で元の MTU に戻る）

1. 両拠点の WG ホストで、`apply` の実行予定の内容を見る。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   cd "${REPO:?この項の手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
   sudo ./wg-vpn.sh -e ~/wg/site.env --dry-run apply A   # 拠点 B のホストでは B。秘密鍵は (hidden) と表示
   ```

   - `[Interface]` に `MTU =` の行があり、値がこの項の手順 3 で書いたものになっている
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
   - 後ろの ping（`wg0` の MTU いっぱいの大きさ）だけ落ちるなら、`WG_MTU` をさらに下げて、この項の手順 3 からやり直す
   - `WG_IFACE` を変えている場合は、この項の `wg0` を読み替える

1. 配布済みのクライアントに、この項の手順 3 と同じ値の MTU を入れる。

   - この項の手順 3 より後に `client add` で登録したクライアントは、conf に同じ `MTU =` が入っているので、何もしなくてよい
   - AlmaLinux 10 は `sudo nmcli connection modify wg0 wireguard.mtu 1380` を貼る（`1380` はこの項の手順 3 の値）
   - 続けて `sudo nmcli connection down wg0` と `sudo nmcli connection up wg0` を貼る
   - Windows 11 の PC は、トンネルを切ってから、WireGuard の窓の「編集」で `[Interface]` に `MTU = 1380` を足す（同じく読み替える）
   - スマートフォンは、公式アプリのトンネルの編集で、インターフェースの MTU に同じ値を入れる
   - PC の MTU は[AlmaLinux](extra/wireguard.md#almalinux-10-の-pc-からつなぐときの注意点)・[Windows](extra/wireguard.md#windows-11-の注意点)の注意点を参照する

#### WireGuard: クライアントを削除する

- クライアントを受ける拠点のホストで行う。登録簿から消しただけでは、動いているトンネルの接続許可は残る
- 前提: [クライアントを登録する](#wireguard-クライアントを登録する)で、消すクライアントを登録してある
- 実行場所: クライアントを受ける拠点の WG ホストの、自分のユーザーのシェル（bash）
- 鍵の交換や PC のロールバックでも、この項を使う
- `WG_USE_EXISTING_CONF=0`（既定）の、登録簿から conf を生成する構成が対象。`1` のままでは `apply` が peer を書き換えないので、この項では削除できない
- **トンネル越しに ssh して作業している場合、この項の手順 5 の restart で自分のセッションが切れる**（→ [落とし穴](#wireguard-落とし穴-apply-は作業中の-ssh-経路そのものを切る)）

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

   - [クライアントを登録する](#wireguard-クライアントを登録する)の手順 2 から来た場合は、同じ項の手順 1 で設定した `CLIENT_NAME`・`SITE`・`REPO` と同じ値にする

1. 登録簿を表示し、削除対象の名前・拠点・IP・公開鍵を控える。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   cd "${REPO:?この項の手順 1 の REPO が空のまま}/scripts/wireguard" &&
   ./wg-vpn.sh -e ~/wg/site.env client list
   ```

   - `CLIENT_NAME` の行の `SITE` がこの項の手順 1 と一致することを確かめる
   - 公開鍵は、この項の手順 3 に出る未知 peer と照合するため、行全体を手元に控える
   - 対象の行が無い、拠点が違う、別端末の登録だった場合は、ここで止める

1. 登録を消し、通常の dry-run で既存 conf に残る公開鍵を確認する。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   if [ -z "${CLIENT_NAME}" ] || [ -z "${SITE}" ]; then echo '中断: この項の手順 1 を貼り直す' >&2; else
     sudo ./wg-vpn.sh -e ~/wg/site.env client remove "${CLIENT_NAME}" &&
     sudo ./wg-vpn.sh -e ~/wg/site.env --dry-run apply "${SITE}"
   fi
   ```

   - 反映済みの登録なら、`登録簿に無い [Peer]` のエラーと、既存 conf の行番号・公開鍵が出て止まる。これは削除を確認するための停止
   - **表示された未知 peer が、この項の手順 2 で控えた公開鍵だけであることを確認する**。まだ反映していない登録なら、未知 peer は出ない
   - 未知 peer 以外のエラーが出た場合も、原因を直して通常の dry-run が検査を通るまで進まない
   - ほかの公開鍵も出たら、この項の手順 4・5 へ進まない。残す peer を、表示された案内に従って `client add --pubkey … --ip …` で登録簿へ取り込み、通常の dry-run をやり直す
   - **次の手順は、未知 peer が削除対象だけ、または未知 peer が無いことを確かめてから貼る**

1. 未知 peer の確認が済んだ場合だけ、削除を許可した dry-run の全変更を確認する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env --drop-unknown-peers --dry-run apply "${SITE:?この項の手順 1 の SITE が空のまま}"
   ```

   - `--drop-unknown-peers` は、登録簿に無い peer をすべて消す指定。削除対象以外の公開鍵が警告に出たら、本実行しない
   - **次の手順は、表示された公開鍵と変更内容でよいか確かめてから貼る**

1. 確認した削除をホストへ反映する。

   ```bash
   sudo ./wg-vpn.sh -e ~/wg/site.env --drop-unknown-peers apply "${SITE:?この項の手順 1 の SITE が空のまま}"
   ```

   - この項の手順 4 の後に登録簿や conf を変更した場合は、この項の手順 3 の `--dry-run apply` の行だけを実行して確認し直す（`client remove` は済んでいるので繰り返さない）
   - `wg-quick@wg0 を起動しました` と出れば反映が終わった

1. 登録簿と動作中の peer から、削除対象の公開鍵が消えたことを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   ./wg-vpn.sh -e ~/wg/site.env client list &&
   sudo wg show wg0 peers
   ```

   - この項の手順 2 で控えた名前が登録簿に無く、公開鍵が `wg show` に無ければよい（`WG_IFACE` を変えている場合は `wg0` も読み替える）
   - ルーターのクライアント帯の静的経路は残す

#### WireGuard: バックアップと復旧（OS の再インストール）

- WG ホストの鍵と設定をバックアップし、OS を入れ直したホストに同じ鍵で戻す
- 前提: 両拠点の WG ホストで、[鍵を作って適用する](#wireguard-鍵を作って適用する)を通してある。復旧先のホストでは、OS を入れ直した後に[ログインと sudo](almalinux-setup.md#ログインと-sudo)を通し、このリポジトリを clone してある
- 実行場所: WG ホストの、自分のユーザーのシェル（bash）。この項の手順 1〜3 は OS を入れ直す前の両拠点のホストで、手順 4〜9 は OS を入れ直した復旧先のホストで（この項の手順 1 を貼り直してから）行う。手順 10 は、その拠点のルーターで行う
- OS を入れ直しても、**ホストの秘密鍵とネットワークの値が同じなら**、相手拠点の `site.env` も、配布済みのクライアントの conf も、ルーターの設定も**そのまま使える**
- 逆に鍵を作り直すと、相手拠点の公開鍵の差し替えと、クライアント全台の conf 再発行が連鎖する
- → [バックアップと復旧の補足](reference/wireguard.md#バックアップと復旧の補足)

1. 変数を設定する。

   ```bash
   REPO=~/setup-notes                    # WG ホスト上でこのリポジトリを clone した場所（「site.env を作る」の手順 1 と同じ）
   printf '\n\033[7m 確認 \033[0m\n'
   printf 'REPO = %s\n' "${REPO}"
   ```

   - clone 先が `~/setup-notes` なら、既定のままでよい。[site.env を作る](#wireguard-siteenv-を作る)の手順 1 と同じ値にする
   - 最後に値を読み戻して確かめる
   - **新しいシェルを開いたら**（OS を入れ直した復旧先のホストでも）、この項の手順 1 を貼り直してから先へ進む

1. 両拠点でそれぞれ、バックアップを取る。

   ```bash
   cd "${REPO:?この項の手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
   sudo ./wg-vpn.sh -e ~/wg/site.env --dry-run backup &&       # まとめる内容を表示するだけ
   sudo ./wg-vpn.sh -e ~/wg/site.env backup                    # ~/wg-backup-<ホスト名>-<日時>.tar.gz（0600）
   ```

   - 読むだけなので、トンネルを止めずに稼働中のホストで実行できる
   - 出力先を変えるときは、`backup` の前に `-o /mnt/usb/wgb.tar.gz` のように付ける

1. この項の手順 2 のアーカイブを、このマシンの外（別のディスク、オフラインのメディア）に保管する。

   - **このアーカイブには秘密鍵が入っている。** `0600` のまま、リポジトリの中には置かない

1. クリーンインストール後のホストで、戻す内容を見る（`BACKUP` は必ず値を入れる）。

   ```bash
   BACKUP=                              # ← 復旧に使うアーカイブ（例: ~/wg-backup-<ホスト名>-<日時>.tar.gz）
   ```

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   cd "${REPO:?この項の手順 1 の REPO を設定してから貼る}/scripts/wireguard" &&
   sudo ./wg-vpn.sh --dry-run restore "${BACKUP:?復旧するアーカイブを BACKUP に入れてから貼る}"
   ```

   - `keygen` は実行しない。別の鍵ができ、復旧の意味が無くなる
   - `BACKUP` が空のまま貼ると、`${BACKUP:?…}` で中断し、何も戻さない
   - **次の手順は、表示された内容でよいか確かめてから貼る**

1. 鍵・conf・`site.env`・`clients.list` を戻す。

   ```bash
   sudo ./wg-vpn.sh restore "${BACKUP:?この項の手順 4 の BACKUP が空のまま}"
   ```

   - WG ホストの LAN 側 IP が変わっていなければ、この項の手順 6・7・10 は飛ばす

1. WG ホストの LAN 側 IP が変わったときだけ、`site.env` を直す。

   ```bash
   vi ~/wg/site.env
   ```

   - このホストに対応する `WG_A_LAN_IP` または `WG_B_LAN_IP` を、実際に割り当てた固定 IP に直す
   - `LAN_ZONE` を明示していて NIC のゾーンが変わった場合も見直す
   - **次の手順は、保存してエディタを閉じてから行う**（続けて貼るとエディタへの入力になる）

1. WG ホストの LAN 側 IP が変わったときだけ、更新した `site.env` を相手拠点にも置く。

   - この項の手順 6 で更新したファイルと同じ内容にそろえる。相手拠点の公開鍵は変えない
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
   - 入れる値は、この項の手順 9 の `apply` の末尾に表示される（[補足: ルーターの設定](reference/wireguard.md#ルーターの設定)）
   - 相手拠点の WG ホストの LAN 側 IP が同じなら、相手拠点のルーターのゲートウェイは変更しない

#### WireGuard: 落とし穴: `apply` は作業中の ssh 経路そのものを切る

- WG ホストで、`apply` を、作業中の ssh のセッションから切り離して実行する
- 前提: `apply` を使う項（[鍵を作って適用する](#wireguard-鍵を作って適用する)・[クライアントを登録する](#wireguard-クライアントを登録する)・[回線に合わせて MTU を下げる](#wireguard-回線に合わせて-mtu-を下げる)・[クライアントを削除する](#wireguard-クライアントを削除する)）を、`apply` の手前まで通してある
- 実行場所: トンネル越しに ssh でログインした、WG ホストの自分のユーザーのシェル（bash）
- `apply` は最後に `wg-quick@wg0` を再起動する。トンネル越しに WG ホストへ ssh して作業すると、その接続が切れる
- 切れたまま戻らない場合に備えて、LAN 側の ssh やコンソールなど別の経路を用意しておく

1. WG ホストで、`apply` を SSH セッションから切り離して実行する。

   - `sudo systemd-run --unit=wg-apply-rw -p Type=oneshot /bin/bash <REPO>/scripts/wireguard/wg-vpn.sh -e <ENV_FILE> apply B` を使う
   - `<REPO>`・`<ENV_FILE>` と拠点 `B` は対象の値に合わせる
   - ホーム配下のスクリプトは、パスを直接渡さず `/bin/bash` の引数にする
   - 再接続したら `journalctl -u wg-apply-rw` で結果を読み、`systemctl show wg-apply-rw -p Result -p ExecMainStatus` で終了状態を確認する
   - 戻れない場合は、用意した LAN 側の ssh またはコンソールで状態を確認する

#### WireGuard: site.env に書く値

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
| `${WG_MTU}` | `wg0` の MTU（任意。空なら wg-quick が決める。書く値は[回線に合わせて MTU を下げる](#wireguard-回線に合わせて-mtu-を下げる)の手順 2）。値があれば、`client add` が作るクライアント用 conf にも同じ `MTU =` を書く |

---

## Windows 11 で使う

- Windows 11 の PC から WG ホストへの接続

### Windows 11 で WireGuard を使う

- Windows のクライアントから、拠点の WireGuard に接続する
- [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/wireguard.md)・[参考資料](reference/wireguard.md)・[ロールバックと注意点](extra/wireguard.md)

- Windows の操作は管理者の Windows PowerShell（5.1）で行う。各項で窓を開く
- WG ホストで行う操作は、各項の説明に従って拠点の bash に貼る

- WireGuard は PC 全体に入り、トンネルは Windows のサービスとして動く
- [登録と取り込み](#wireguard-windows-11-で-wg-ホストに登録して取り込む)の手順 4 だけは、関数名を手入力する

#### WireGuard: Windows 11 で WireGuard と鍵を用意する

- 外出先からつなぐ Windows の PC に WireGuard を入れ、この PC の鍵を作る
- 前提: [Microsoft Store の更新](windows-setup.md#microsoft-store-の更新)で winget を用意し、拠点の WG ホストで[状態と疎通を確かめる](#wireguard-状態と疎通を確かめる)まで通してある
- 実行場所: この PC の管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

1. Windows で、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. この PC の WireGuard の状態を確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id WireGuard.WireGuard --accept-source-agreements --source winget
   Get-Service -Name 'WireGuard*' -ErrorAction SilentlyContinue | Format-Table Name, Status, StartType
   Get-ChildItem -LiteralPath "$env:ProgramFiles\WireGuard\Data\Configurations" -ErrorAction SilentlyContinue | Format-Table Name
   Test-Path -LiteralPath "$env:USERPROFILE\wg-client"
   ```

   - `入力条件に一致するインストール済みのパッケージが見つかりませんでした。`（英語の Windows では `No installed package found matching input criteria.`）と、`False` だけが出れば、まだ入っていない
   - `WireGuardTunnel$wg0` か `wg0.conf.dpapi` が出たら、同名のトンネルがある。[ロールバック](extra/wireguard.md#windows-11-のロールバック)の手順 1 で消してから始める（鍵は取り戻せない）
   - 最後が `True` なら、前に作った鍵が残っている（この項の手順 5 で止まる）。使わないなら、[Windows 11 のロールバック](extra/wireguard.md#windows-11-のロールバック)の手順 1 で消す
   - `winget` が見つからないというエラーになったら、Microsoft Store で「アプリ インストーラー」を更新してから始める

1. WireGuard を winget で入れる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget install --exact --id WireGuard.WireGuard --source winget --scope machine --accept-source-agreements --accept-package-agreements
   winget list --exact --id WireGuard.WireGuard --source winget
   Get-AuthenticodeSignature -FilePath "$env:ProgramFiles\WireGuard\wireguard.exe", "$env:ProgramFiles\WireGuard\wg.exe" | Format-Table Status, @{ Label = 'Signer'; Expression = { $_.SignerCertificate.Subject.Split(',')[0] } }, Path -AutoSize
   & "$env:ProgramFiles\WireGuard\wg.exe" --version
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と出て、`winget list` に `WireGuard.WireGuard` の行が出ればよい
   - 2 つのファイルの署名が `Valid` で、署名者が `CN=WireGuard LLC`
   - 最後に `wireguard-tools v1.0.20260223 - https://git.zx2c4.com/wireguard-tools/` の形の 1 行が出る
   - インストーラーの画面は出ず、入れた後に WireGuard の窓も開かない（窓は、この項の手順 4 で開く）

1. WireGuard の窓を開く（マネージャーを起動する）。

   ```powershell
   & "$env:ProgramFiles\WireGuard\wireguard.exe"
   ```

   - WireGuard の窓が開き、タスク バーの通知領域に WireGuard のアイコンが出る（トンネルの一覧はまだ空）
   - スタートメニューの「WireGuard」から開いても同じ
   - 窓は開いたままでよい
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
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     icacls.exe $dir
     Get-ChildItem -LiteralPath $dir | Format-Table Name, Length
     $pub
   }
   ```

   - `icacls` に `NT AUTHORITY\SYSTEM:(OI)(CI)(F)` と `BUILTIN\Administrators:(OI)(CI)(F)` の 2 行だけが出る
   - `wg0.key` と `wg0.pub` がどちらも 45 バイト
   - 最後の 1 行（公開鍵、44 文字）だけを、[Windows 11 で WG ホストに登録して取り込む](#wireguard-windows-11-で-wg-ホストに登録して取り込む)の手順 3 で WG ホストに渡す。秘密鍵（`wg0.key`）は渡さない
   - **注意**: `%USERPROFILE%\wg-client` は、管理者の PowerShell からしか読めない（管理者ではない PowerShell やエクスプローラーでは開けない）

#### WireGuard: Windows 11 で WG ホストに登録して取り込む

- この PC の公開鍵を拠点の WG ホストに登録し、Windows に conf を取り込む
- 前提: [WireGuard と鍵を用意する](#wireguard-windows-11-で-wireguard-と鍵を用意する)を通し、鍵と公開鍵が残っている。WireGuard のマネージャーが動いている
- 実行場所: この PC の管理者の Windows PowerShell（5.1）と、拠点の WG ホストの bash。PowerShell はこの項の手順 1 で開く

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリック →「管理者として実行」を選ぶ
   - UAC の確認で「はい」を押す。窓の名前が「管理者: Windows PowerShell」になる

1. Windows の PowerShell で、conf を取り込む関数を定義する。

   ```powershell
   function Import-WgClientConf {
     $dir = "$env:USERPROFILE\wg-client"
     $text = Get-Clipboard -Raw
     if (-not $text) { Write-Error '中断: クリップボードが空（この項の手順 3 の client show の出力をコピーし直す）'; return }
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
   - PowerShell を開き直した場合は、この項の手順 1 で管理者の窓を開き、この項の手順 2 の関数の定義を貼り直す

1. WG ホストで、[クライアントを登録する](#wireguard-クライアントを登録する)の手順 1・2・4〜6 を行い、この PC の公開鍵を登録して conf を表示する。

   - ホスト側の手順 1 の `CLIENT_PUBKEY` に、[鍵の用意](#wireguard-windows-11-で-wireguard-と鍵を用意する)の手順 5 の公開鍵を貼る
   - `CLIENT_NAME` はこの PC だけの名前（例 `win-laptop`）にする。同名の端末は、ホスト側の手順 2 で登録を消してしまう
   - ホスト側の手順 6 の `client show` から、`[Interface]`〜`PersistentKeepalive` をこの PC のクリップボードにコピーする
   - `PrivateKey` はプレースホルダのままなので、**秘密情報を含まない**。どの経路で運んでもよい
   - **次の手順は、`client show` の出力をこの PC でコピーしてから行う**。コピー後は、コードブロックなど別の文字列をコピーしない

1. Windows の PowerShell で、`Import-WgClientConf` と手入力して Enter を押す。

   - 関数名はコピーせず手で打つ。クリップボードには、この項の手順 3 の conf を残しておく
   - `1`（置き換わった）と、`PrivateKey` 以外の行（`Address`・`PublicKey`・`Endpoint`・`AllowedIPs` など）が出ればよい
   - 残りの行が `client show` の出力のとおりで、途中で折り返されていないことを目で確かめる
   - `中断:` で始まるエラーが出たら、何も書いていない
   - conf をコピーし直し、この関数をもう一度呼んでもよい（`wg0.conf` を書き直す）

1. `wg0.conf` を WireGuard に取り込む。

   ```powershell
   & {
     $dir = "$env:USERPROFILE\wg-client"
     $store = "$env:ProgramFiles\WireGuard\Data\Configurations"
     if ((Get-Service -Name WireGuardManager -ErrorAction SilentlyContinue).Status -ne 'Running' -or -not (Test-Path -LiteralPath $store)) { Write-Error '中断: WireGuard のマネージャーが動いていない（「Windows 11 で WireGuard と鍵を用意する」の手順 4 からやり直す）'; return }
     if (-not (Test-Path -LiteralPath "$dir\wg0.conf")) { Write-Error '中断: wg0.conf が無い（この項の手順 4）'; return }
     if (Test-Path -LiteralPath "$store\wg0.conf.dpapi") { Write-Error '中断: wg0 というトンネルが既にある'; return }
     Copy-Item -LiteralPath "$dir\wg0.conf" -Destination "$store\wg0.conf"
     for ($i = 0; $i -lt 30 -and (Test-Path -LiteralPath "$store\wg0.conf"); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ChildItem -LiteralPath $store | Format-Table Name, Length, LastWriteTime
   }
   ```

   - `wg0.conf.dpapi` の 1 行だけが出ればよい
   - WireGuard の窓のトンネルの一覧に `wg0` が出る（無効のまま）
   - この手順は LAN の中で貼ってよい
   - `wg0.conf` が残ったら取り込み失敗。理由を確かめ、`Remove-Item -LiteralPath "$env:ProgramFiles\WireGuard\Data\Configurations\wg0.conf"` で消す
   - この項の手順 3・4 からやり直す
   - （この手順の代わりに）窓の「トンネルをファイルからインポート…」で `%USERPROFILE%\wg-client\wg0.conf` を選んでも、同じ `wg0.conf.dpapi` ができるはず

#### WireGuard: Windows 11 でトンネルを確かめる

- 外出先からつなぐ Windows の PC でトンネルを張り、拠点への疎通を確かめる
- 前提: [WG ホストに登録して取り込む](#wireguard-windows-11-で-wg-ホストに登録して取り込む)を通し、wg0 を取り込んである
- 実行場所: この PC の管理者の Windows PowerShell（5.1）と、拠点の WG ホストの bash。PowerShell はこの項の手順 1 で開く

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリック →「管理者として実行」を選ぶ
   - UAC の確認で「はい」を押す。窓の名前が「管理者: Windows PowerShell」になる

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
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($v in 'WG_HOST_TUN_IP', 'WG_HOST_LAN_IP', 'ROUTER_LAN_IP', 'PEER_WG_LAN_IP') {
     '{0,-15} = {1}' -f $v, (Get-Variable -Name $v -ValueOnly -ErrorAction SilentlyContinue)
   }
   ```

   - 編集が必須なのは、1 行ずつの 4 ブロック。接続先拠点と相手拠点の IP を入れる
   - 最後に値を読み戻して確かめる
   - **例の値のままでもエラーにならない**ので、4 つの IP を書き換えたか必ずここで確かめる
   - 変数はその PowerShell の中だけで有効。**新しい PowerShell を開いたら**、この項の手順 2 の 5 つのブロックを貼り直してから先へ進む

1. PC を、拠点の LAN の外のネットワークにつなぐ（スマートフォンのテザリングなど）。

   - LAN 内でこの項の手順 4 を貼ると、そこで LAN の通信が切れる
   - **次の手順は、LAN の外につないでから貼る**

1. 拠点の LAN の外で、トンネルを張る。

   ```powershell
   & {
     $conf = "$env:ProgramFiles\WireGuard\Data\Configurations\wg0.conf.dpapi"
     if (-not (Test-Path -LiteralPath $conf)) { Write-Error '中断: wg0.conf.dpapi が無い（「Windows 11 で WG ホストに登録して取り込む」の手順 5）'; return }
     & "$env:ProgramFiles\WireGuard\wireguard.exe" /installtunnelservice $conf 2>&1 | ForEach-Object { "$_" }
     for ($i = 0; $i -lt 30 -and -not (Get-NetIPAddress -InterfaceAlias wg0 -AddressFamily IPv4 -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
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
   - `NlMtu` は、conf に `MTU =` があればその値、無ければ `1420`（今の回線の MTU が 1500 のとき）
   - `NetworkCategory` は `Public` のはず（変えない。行が出なければ、Windows がまだネットワークを識別している）
   - `ServerAddresses` が空（`{}`）
   - `wg show` の `latest handshake` が数秒前で、`transfer` の received が 0 でない。まだ出ていなければ、この項の手順 5 の通信で出る
   - 窓で `wg0` を選び「有効化」を押しても同じ
   - **注意**: LAN 内で貼ってしまったら、そこで LAN の通信が切れる。PC の画面の WireGuard の窓で「無効化」を押す

1. PC で、トンネル IP → WG ホストの LAN 側 → ルーター → 相手拠点の順に疎通を試す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not ($WG_HOST_TUN_IP -and $WG_HOST_LAN_IP -and $ROUTER_LAN_IP -and $PEER_WG_LAN_IP)) {
     Write-Error '中断: この項の手順 2 の変数が空のまま'
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
   - どこで止まるかで、疑う場所が変わる（[トンネルを確かめる](#wireguard-トンネルを確かめる)の手順 3 と同じ）

1. WG ホストで変数を設定し、ハンドシェイクを確かめる。

   - [クライアントを登録する](#wireguard-クライアントを登録する)の手順 1 で、`SITE`・`CLIENT_NAME`・`REPO` をこの PC を登録したときと同じ値に設定する
   - その WG ホストの bash に、[トンネルを確かめる](#wireguard-トンネルを確かめる)の手順 5 を貼る

   - `client list` の、この PC の名前の `LAST_HANDSHAKE` が「N 秒前」なら届いている
   - 最後の `ping`（拠点 → PC）は、応答が無くてよい
   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/wireguard.md#症状と原因の対応実測)
   - **次の手順は、WG ホストで確かめてから、この PC で貼る**

1. PC で、トンネルを切る。

   ```powershell
   & "$env:ProgramFiles\WireGuard\wireguard.exe" /uninstalltunnelservice wg0 2>&1 | ForEach-Object { "$_" }
   for ($i = 0; $i -lt 30 -and (Get-Service -Name 'WireGuardTunnel$wg0' -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Seconds 1 }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-Service -Name 'WireGuardTunnel$wg0' -ErrorAction SilentlyContinue
   Get-NetAdapter -Name wg0 -ErrorAction SilentlyContinue
   ```

   - 最後の 2 つが何も出さなければよい
   - 窓で `wg0` を選び「無効化」を押しても同じ
   - 日常は、外出先で窓（か、通知領域の WireGuard のアイコン）から `wg0` を有効化し、拠点に戻る前に無効化する（この項の手順 4・7 のコマンドでも同じ）
   - **張ったまま再起動すると、起動したときにまた張られる**。拠点の LAN に戻る前に切る

1. 平文の鍵と conf を消す。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\wg-client\wg0.key", "$env:USERPROFILE\wg-client\wg0.conf"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ChildItem -LiteralPath "$env:USERPROFILE\wg-client" | Format-Table Name, Length
   ```

   - `wg0.pub` だけが残る
   - 取り込みをやり直すときは、後片付けの前に[登録と取り込み](#wireguard-windows-11-で-wg-ホストに登録して取り込む)の手順 5 を行う（`wg0.conf` が必要）

#### WireGuard: Windows 11 の更新

- この PC の WireGuard を winget で更新する
- 前提: [WireGuard と鍵を用意する](#wireguard-windows-11-で-wireguard-と鍵を用意する)で本体を入れ、[Microsoft Store の更新](windows-setup.md#microsoft-store-の更新)で winget を用意してある
- 実行場所: この PC の管理者の Windows PowerShell（5.1）。この項の手順 1 で開く

- WireGuard のマネージャーは、1 時間ごとに新しい版を確かめる（起動した直後は数分待ってから）。新しい版があると、窓に「更新が利用できます！」のタブが出て、そこの「今すぐ更新」で上がる（Administrators の一員だけ）
- 窓からの更新は、公式の署名付きの一覧（`latest.sig`）で MSI を確かめてから入れる。winget で上げても、入るのは同じ公式の MSI
- 更新の間、マネージャーと、張っているトンネルのサービスは止まり、入れ終えると起動し直す（張っていれば数秒切れる）

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、右クリック →「管理者として実行」を選ぶ
   - UAC の確認で「はい」を押す。窓の名前が「管理者: Windows PowerShell」になる

1. WireGuard を winget で上げる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget upgrade --exact --id WireGuard.WireGuard --source winget --accept-source-agreements --accept-package-agreements
   winget list --exact --id WireGuard.WireGuard --source winget
   Get-Service -Name 'WireGuard*' | Format-Table Name, Status, StartType
   ```

   - 上がったら `インストールが完了しました` と出て、`winget list` の `WireGuard.WireGuard` の版が新しくなる
   - 新しい版が無ければ、`利用可能なアップグレードが見つかりませんでした。`（英語の Windows では `No available upgrade found.`）と出る
   - 最後に `WireGuardManager` が `Running` で出る（張っていれば `WireGuardTunnel$wg0` も）
   - 窓が更新を知らせているのに winget で上がらないときは、窓の「今すぐ更新」で上げる

---
