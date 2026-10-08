# WireGuard Road Warrior 設定手順（AlmaLinux 10 は NetworkManager + nmcli / Windows 11 は公式の WireGuard for Windows）の検証記録

[手順書](../wireguard-road-warrior.md)

## 最新の確認範囲（Windows 11）

- 通したこと（どれも Windows 11 Pro の同じクリーン VM。実機ではない）
  - 2026-10-06〜07: Windows 節の手順 3・4 の新規導入と署名・版、手順 6 の鍵の生成・形式・ACL、CLI による ManagerService の一時作成と削除（[付録](#付録-windows-11-pro-の-vm-での新規導入の検証2026-10-06)）
  - 2026-10-08: AlmaLinux の VM 2 台を拠点 A・B にした検証環境に向けて、手順 1〜16（窓・鍵・WG ホストへの登録・取り込み・トンネル・疎通・ハンドシェイク・切断・後片付け）、更新、ロールバック（WG ホストのクライアントの削除を含む）（[付録](#付録-windows-11-pro-の-vm-での-vpn-の通し検証2026-10-08)）
- 確認していないこと
  - インターネット越し（物理のルーターのポート転送・NAT・DDNS）、テザリングなどへのつなぎ替え、張ったままの再起動、サスペンド復帰、Wi-Fi の切り替え
  - 既存の鍵がある場合の手順 6 の分岐、arm64 の Windows、Windows の実機
- 秘密鍵の値やハッシュは記録していない。以降の既存記録は、各実施日・対象版・範囲に従う履歴として保持した

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 操作上の注意と併記されていた記録

   - **ファイル名は `wg0.conf` にする。** NetworkManager がファイル名から接続名とインターフェース名を決める（実測で確認 → 手順 8 の補足）

### 操作上の注意と併記されていた記録

   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](wireguard.md#症状と原因の対応実測)

### 操作上の注意と併記されていた記録

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と出て、`winget list` に `WireGuard.WireGuard` の行が出ればよい（版は実行した日の最新。2026-10-03 は 1.1.1）

### 操作上の注意と併記されていた記録

   - 片方向だけ失敗する、`latest handshake` が出ない、といった場合は [症状と原因の対応](wireguard.md#症状と原因の対応実測)

### 実施手順 / 手順 8: 補足: conf と秘密鍵

- `sed` の区切りを `|` にしているのは、base64 の鍵に `/` が含まれるため（`|` `&` `\` は base64 に含まれない）
- `$(cat …)` の展開結果は端末に出ない。シェルの履歴には展開前の文字列が残るので、鍵は残らない
- 2 つの `grep -c` は「置き換え前に `PrivateKey` 行がちょうど 1 行あること」と「置き換え後に 44 文字の鍵になったこと」の確認
- `sed -i` は元ファイルのモード（`umask 077` の 0600）を引き継ぐ
- ファイル名を `wg0.conf` にするのは、NetworkManager が `import` で接続名とインターフェース名をファイル名から決めるため（実測で `connection.id` / `connection.interface-name` とも `wg0` になった。有効なインターフェース名 + `.conf` でないと拒否されるかは未確認）

### 実施手順 / 手順 10: 補足: import

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

### 実施手順 / 手順 11: 補足: up

- `GENERAL.STATE` / `IP4.ROUTE[n]: dst = …, nh = …, mt = …` の書式は、NetworkManager 1.56 で確認済み
- `mt` の値（WireGuard デバイスの既定 metric）は **50**（実測。`ipv4.route-metric` は `-1` のままなので、これは WireGuard デバイスの既定）。Wi-Fi の 600 より優先される（→ [注意点](../wireguard-road-warrior.md#注意点)）
- `wireguard.peer-routes yes` が `AllowedIPs` の経路を入れる（`nm-settings-nmcli(5)`）。`ip4-auto-default-route` は `/0` の peer が無いので関係ない
- MTU は `wireguard.mtu 0` のときカーネル既定の 1420 になる（実測）。`wg-quick` と違い NetworkManager は経路から MTU を計算しない
- `wg show` の `listening port` はランダム（`wireguard.listen-port 0`）。`latest handshake` が出ない場合は、鍵の対応（ホストの `clients.list` と `wg0.pub`）、`Endpoint`、ルーターのポート転送を疑う

### 実施手順 / 手順 12: 補足: 疎通確認

4 段階の意味:

- (1) `<WG_HOST_TUN_IP>` はトンネルそのもの（届かなければハンドシェイクか `AllowedIPs`）
- (2) `<WG_HOST_LAN_IP>` は WG ホスト自身の LAN 側（届かなければ `AllowedIPs` に拠点 LAN が無い）
- (3) ルーターは `wg0 → LAN` の転送と、ルーターのクライアント帯の静的経路
- (4) 相手拠点の WG ホストは、拠点間トンネルと相手ホストの `AllowedIPs`（クライアント帯）

→ [wireguard.md: 手順 18 の補足](../wireguard.md#実施手順)、[症状と原因の対応](wireguard.md#症状と原因の対応実測)。トンネル越しの ssh は [WG ホスト自身の ssh へ入る場合](../wireguard.md#トンネル越しに-wg-ホスト自身の-ssh-や-cockpit-へ入る場合)。

### 実施手順 / 手順 14: 補足: down と日常の使い方

- `down` で NetworkManager が作ったリンク `wg0` は消える（実測: 直後の `ip link show dev wg0` が `Device "wg0" does not exist.`、経路 3 本と firewalld の active zones からも `wg0` が外れる）
- プロファイルは `nmcli connection show` に `wg0  wireguard  --  --` として残るので、次は `up` だけでよい
- GNOME の設定画面やクイック設定に VPN として出るかは未確認（`connection.type` は `vpn` ではなく `wireguard` なので、VPN の欄には出ないと思われる）

### 実施手順 / 手順 15: 補足: 後片付け

後片付けを最後にしているのは、import に失敗したときに `sudo nmcli connection delete wg0` → 手順 10 をやり直すのに conf が要るため。秘密鍵は手順 10 の時点で NetworkManager の keyfile に入っている。

**ガードの確認**（2026-09-22、この文書を書いた WG ホストで）:

- 各ブロックを `PATH` を空にした bash に変数が空のまま流し、値を使うブロックはすべて先頭のガードで止まって、ファイルを作る・書き換える・消すコマンドの起動が 1 つも試みられないことを確認した
  - 起動が試みられたのは、値を含まない読み取り系と、意図どおりの `nmcli connection up` / `down` / `delete` だけ
- 手順 3 と手順 8 のブロックは、一時ディレクトリで本物の `wg` / `sed` を使って実行し、次を確認した
  - 鍵が 0600 で作られる
  - `PrivateKey` 行だけが 44 文字の鍵に置き換わり、他の行が変わらない
  - `PrivateKey` 行が 2 行あるときと `wg0.key` が無いときに、中断してファイルが変わらない

### Windows 11 で使う: 検証状況の記録

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、winget の定義、公式の MSI の中身と署名、WireGuard for Windows のソースと文書、Linux の PowerShell 7 での構文と模擬の実行だけ（[対象と検証環境](#対象と検証環境)）。

### Windows 11 で使う / 手順 4: 補足: winget の定義と、入るもの

**winget の定義**（`WireGuard.WireGuard` 1.1.1。2026-10-03 の winget-pkgs。[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）

- `InstallerType: wix`（MSI）、`Scope: machine`。x64 のインストーラーは `https://download.wireguard.com/windows-client/wireguard-amd64-1.1.1.msi` で、winget が sha256 を確かめてから黙って入れる。x86 と arm64 の MSI もある
- `InstallerSwitches` の `Custom: DO_NOT_LAUNCH=1` を MSI に渡す。MSI は、入れ終えたときに `wireguard.exe` を起動して窓を出すが、この値があると起動しない（WireGuard の文書の「Enterprise Usage」）。そのため、マネージャーのサービスもまだ作られない（この節の手順 5）
- `UpgradeBehavior: install`（新しい版の MSI を上から入れる。[Windows 11 の更新](../wireguard-road-warrior.md#windows-11-の更新)）
- `--accept-source-agreements` と `--accept-package-agreements` は、winget を初めて使う PC で出る同意の問いに答えるため

**入るもの**（MSI の定義 `installer/wireguard.wxs` と、MSI から取り出した中身）

- `C:\Program Files\WireGuard\wireguard.exe`（窓・マネージャー・トンネルのサービスを兼ねる 1 つのプログラム。GUI のプログラムなので、PowerShell は終わるのを待たない）と `wg.exe`（wireguard-tools の `wg`。コンソールのプログラム）。どちらも WireGuard LLC の署名付き
- スタートメニューの「WireGuard」
- PC 全体の `PATH` の末尾に `C:\Program Files\WireGuard\` が足される。開いている PowerShell には効かないので、この文書のブロックはフルパスで呼ぶ
- 管理者の PowerShell から動かすので、UAC の確認は出ないはず

### Windows 11 で使う / 手順 6: 補足: 鍵ペアと置き場所

- [実施手順](../wireguard-road-warrior.md#実施手順)の手順 3 と同じく、既に `wg0.key` があれば止まる（上書きすると、WG ホストに登録済みの公開鍵と対応しなくなる）
- 秘密鍵は、ブロックを囲む `& { … }` の中の変数で受けて、ファイルに書くだけ。ブロックが終わると変数は消える。PowerShell の履歴に残るのはコマンドの文字列で、鍵は残らない
- ファイルは `[IO.File]::WriteAllText` で ASCII（BOM 無し）で書く。Windows PowerShell 5.1 の `>` と `Out-File` は UTF-16 で書く
- `$priv | & $wg pubkey` は、末尾に CR LF を付けて ASCII で送る（Windows PowerShell 5.1 のパイプ）。`wg pubkey` は鍵の 44 文字の後ろの空白（CR と LF を含む）を読み飛ばす（wireguard-tools のソースの `pubkey.c` と `ctype.h`。Linux の `wg` で、CR LF 付きの入力から同じ公開鍵が出た。[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
- `wg genkey` / `wg pubkey` は、トンネルのドライバー無しで動く
- アクセス権は、[Windows の OpenSSH サーバー](../windows-openssh-server.md)の `administrators_authorized_keys` と同じ考え方で、`/inheritance:r` で `C:\Users\<WIN_USER>` から受け継ぐ自分のユーザーの許可を外し、Administrators（`S-1-5-32-544`）と SYSTEM（`S-1-5-18`）だけにする。管理者ではない窓（UAC で権限を落としたもの）で動くプログラムからは読めない
- 管理者の PowerShell で作ったフォルダーの所有者は `BUILTIN\Administrators` になる

### Windows 11 で使う / 手順 9: 補足: conf と秘密鍵

- [実施手順](../wireguard-road-warrior.md#実施手順)の手順 7・8（`vi` に貼って保存し、`sed` で `PrivateKey` 行を置き換える）を、この節の手順 7 の関数にまとめた。エディタを開かずに、クリップボードの中身を読む（`Get-Clipboard -Raw` は、複数行を 1 つの文字列で返す。Windows PowerShell 5.1 にもある）
- 先頭が `[Interface]` でなければ止めるのは、端末からコピーしたときにプロンプトの行が入りやすいため。行の末尾の空白は落とす
- 2 つの確かめは、AlmaLinux 10 と同じ「置き換え前に `PrivateKey` 行がちょうど 1 行あること」と「置き換え後に 44 文字の鍵になったこと」
- ASCII（BOM 無し）・CR LF で書く。WireGuard の読み込みは行を LF で分けて前後の空白を落とすので、CR LF でも読める（ソースの `conf/parser.go`）。BOM 付きの UTF-8 は、先頭の行が `[Interface]` と見なされずに読めない（その読み込みの部分を Linux で動かして確かめた。[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
- `client show` の出力は ASCII だけでできている（クライアントの名前は英数字・`-`・`_` だけ）。ASCII でない文字があれば、書くときに `?` に変わるので先に止める
- `wg0.conf` は、`%USERPROFILE%\wg-client` のアクセス権を受け継ぐ（Administrators と SYSTEM だけ）

### Windows 11 の更新 / 手順 1: 補足: 更新の動き

- winget の定義は `UpgradeBehavior: install` で、新しい版の MSI を上から入れる（MSI のメジャー アップグレード）。トンネルの設定（`Data`）は消えない（MSI が `Data` を消すのは、アンインストールのときだけ。ソースの `installer/customactions.c`）
- MSI は、入れる前に動いている WireGuard のサービス（`WireGuardManager` と `WireGuardTunnel$…`）を止め、入れ終えると起動し直す（同じソースの `EvaluateWireGuardServices`）。winget は `DO_NOT_LAUNCH=1` を渡すが、サービスの起動し直しには関係しないはず
- 窓の「今すぐ更新」と、コマンドの `& "$env:ProgramFiles\WireGuard\wireguard.exe" /update 2>&1 | ForEach-Object { "$_" }` は、`https://download.wireguard.com/windows-client/latest.sig`（Ed25519 の署名付きの、MSI の BLAKE2b の一覧）を確かめてから、その MSI を取って入れる（ソースの `updater/`、WireGuard の文書の「Enterprise Usage」）
- 本書では、新しい版が出ていないので、更新を試していない

### 対象と検証環境

- **目的**: [WireGuard VPN 構築手順](../wireguard.md)で建てた拠点の WG ホストに、外出先の AlmaLinux 10 または Windows 11 のノート PC から接続し、両拠点の LAN に届くようにする
  - 鍵は PC で作り、**公開鍵だけ**を WG ホストに登録する
  - AlmaLinux 10 では、トンネルを NetworkManager のプロファイル `wg0` として持ち、`nmcli connection up wg0` / `down wg0` で張る・切る（`wg-quick` は使わない。→ [代替](../reference/wireguard-road-warrior.md#代替-wg-quick-で張る場合)）
  - Windows 11 では、公式の WireGuard for Windows のトンネル `wg0` として持ち、`wireguard.exe /installtunnelservice` / `/uninstalltunnelservice`（窓の「有効化」「無効化」と同じ）で張る・切る
- **進め方**: **冒頭の変数ブロックに値を 1 度書き、以降のコマンドをそのまま貼る**
  - 手順 4〜6 と手順 13 だけは WG ホスト上で実行する（WG ホスト側の変数は手順 4 で設定する）
  - WG ホスト側は `wg-vpn.sh` の `client add --pubkey` → `apply` → `client show` で、[wireguard.md の手順 11〜13](../wireguard.md#実施手順) と同じ
  - **Windows 11**（[Windows 11 で使う](../wireguard-road-warrior.md#windows-11-で使う)）: WireGuard for Windows を winget で入れ、鍵はその `wg.exe` で作る。`client show` の conf をクリップボードから読んで秘密鍵を入れ、WireGuard の設定の置き場所に写して暗号化させてから張る。管理者の Windows PowerShell 5.1 で関数を先に定義し、conf コピー後に関数名を手入力する。WG ホストでは同じ手順 4〜6・13 を使う
- **状態（AlmaLinux 10）**: **実機で本実行済み（2026-09-22）。クリーンインストールした x86_64 の VM でも現行ブロックを本実行した（2026-10-06）**
  - 2026-10-06: 先行検証とは別の新規 VM で現行本文を再検証した（[今回の記録](#付録-新規-vm-での現行手順の再検証2026-10-06)）。検証専用のアカウント・鍵・隔離 LAN を使った
  - 拠点 A の LAN にあるノート PC を**スマートフォンのテザリング回線に移してから**、拠点 B の WG ホストへ手順 1〜15 を通した
  - 確認したこと: 両拠点の LAN への ping、トンネル越しの ssh、拠点側からの逆方向 ping
  - NetworkManager の挙動として推定で書いていた項目は、1〜9 が実測で確定した
  - **確認していないこと**: サスペンド復帰・Wi-Fi の切り替え・`Endpoint` が DDNS 名のとき・GNOME の UI・`DNS =` がある場合など（→ [残っている未確認事項](#残っている未確認事項)）
  - **拠点の LAN の中からトンネルを張ることは、意図的に試していない**（[注意点](../wireguard-road-warrior.md#注意点)のとおり LAN の経路を奪うため）
  - 実測の記録は[付録](#付録-実機での検証記録)
  - 2026-09-28: 手順 2・10・11 と、[ロールバック](../wireguard-road-warrior.md#ロールバック)の手順 1のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-05: 手順 5 とロールバックの手順 3 を、公開鍵を照合してから削除を反映する共通手順への案内に変更した。新しい削除・鍵交換の順序は隔離したスタブで確認し、実機では流していない
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）:
    - 配布物: winget の `WireGuard.WireGuard` 1.1.1 の定義、公式の MSI（amd64）の sha256（winget の定義と一致）・BLAKE2b（公式の署名付きの `latest.sig` と一致。その署名も）・Authenticode の署名者、MSI の中の `wireguard.exe`（GUI のプログラム）と `wg.exe`（コンソールのプログラム）
    - WireGuard for Windows 1.1.1 のソースと文書: MSI の定義（`DO_NOT_LAUNCH`、アンインストールで `Data` を消す）、設定の置き場所への取り込みと暗号化・アクセス権、`/installtunnelservice` と窓の「有効化」が同じこと、トンネルの経路・MTU・キルスイッチの条件
    - `wg pubkey` が CR LF 付きの入力を受けること（Linux の wireguard-tools 1.0.20210914 と、ソースで）
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。[Windows 11 で使う](../wireguard-road-warrior.md#windows-11-で使う)の手順 6・9（現在は手順 7 の関数内）・10・12・13・15・16 と[Windows 11 のロールバック](../wireguard-road-warrior.md#windows-11-のロールバック)の手順 1 のブロックは、Linux の pwsh で偽物のコマンドを使って流した（手順 12・15 は、`wireguard.exe` と Windows のネットワークのコマンドレットも偽物。[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
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
| WG ホスト側 | [wireguard.md](../wireguard.md) の構成（`wg-vpn.sh`。AlmaLinux 10.2 aarch64、カーネル 6.12 系）。**実測では拠点 B がクライアントを受ける**（`WG_B_CLIENT_NET` を設定、`WG_A_CLIENT_NET` は空）。本文の例の値は `site.env.example`（拠点 A が受ける構成）のままにしてある |

Windows 11 の手順が前提にしている環境（流していない）:

| 項目 | 値 |
|---|---|
| OS | Windows 11（x64） |
| PowerShell | Windows PowerShell 5.1（管理者として実行） |
| ユーザー | Administrators の一員（Microsoft アカウントでもローカル アカウントでもよい） |
| WireGuard for Windows | 1.1.1（2026-09-20。winget の `WireGuard.WireGuard`、`wireguard-amd64-1.1.1.msi`。中の `wg.exe` は wireguard-tools 1.0.20260223） |
| 接続時の回線 | AlmaLinux 10 と同じく、拠点の LAN の外（スマートフォンのテザリングなど） |
| WG ホスト側 | AlmaLinux 10 の PC と同じ（変えるものは無い） |

![構成](../diagrams/wireguard-remote-client.svg)

図の Remote client が本書の PC。接続先拠点（図では拠点 A）の WG ホストにトンネルを張り、拠点 A・B の LAN に届く（→ [パケットの流れ](../reference/wireguard.md#パケットの流れremote-client--各拠点)）。

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。PC 側は[手順 1](../wireguard-road-warrior.md#実施手順)、WG ホスト側は[手順 4](../wireguard-road-warrior.md#実施手順)の先頭で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。例は `site.env.example`（拠点 A がクライアントを受ける構成）の値。Windows 11 の PC は、[Windows 11 で使う](../wireguard-road-warrior.md#windows-11-で使う)の手順 2 で、同じ名前の PowerShell の変数（`$WG_HOST_TUN_IP` など 4 つ）を設定する（鍵と conf の一時置き場は `%USERPROFILE%\wg-client` に決めてあり、変数にしていない）。
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

AlmaLinux 10 の実機で、2026-09-22、手順 2 の前に採取（採取コマンドは[付録](#付録-実機での検証記録)の「記録用ブロック」）。Windows 11 の PC は、[Windows 11 で使う](../wireguard-road-warrior.md#windows-11-で使う)の手順 3 で確かめる（流していないので記録は無い）。

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
  - RHEL 10 のドキュメントは `nmcli connection add` で組む方式（→ [代替](../reference/wireguard-road-warrior.md#代替-nmcli-connection-add-で組む場合rhel-のドキュメントの方式)）
- **鍵は PC で作り、公開鍵だけをホストに渡す**（→ [wireguard.md: クライアントの秘密鍵の扱い](../wireguard.md#クライアントの秘密鍵の扱い)）
  - 秘密鍵が PC から出ない
  - `client show` の出力に秘密が無いので、渡す経路を選ばない
  - ホストに秘密鍵入りの conf が残らないので、wireguard.md 手順 16 の `rm` も要らない（`--pubkey` で作った conf はプレースホルダのまま残してよい）
- **ファイル名は `wg0.conf`** — NetworkManager の importer はファイル名（`.conf` を除いた部分）を接続名とインターフェース名にする（実測）。`wg0` なら WG ホスト側と同じ呼び名になる
- **スプリットトンネル、`DNS =` 無し** — ホストが出す conf のとおり
  - `AllowedIPs` は両拠点の LAN とトンネル網だけで、それ以外の通信は今いるネットワークにそのまま出る
  - `site.env` の `WG_CLIENT_DNS` が空なので、resolv.conf にも触らない
  - 全トラフィックを通す構成（`0.0.0.0/0`）は[対象外](../wireguard.md#全トラフィックを-vpn-経由にする場合対象外)
- **autoconnect は無効** — 拠点の LAN 内で自動的に張られると、ヘアピンと経路の奪い合いになる（→ [注意点](../wireguard-road-warrior.md#注意点)）
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
  - WG ホストの[バックアップ](../wireguard.md#バックアップと復旧os-の再インストール)に、クライアントの鍵は含まれない

Windows 11 で WireGuard を入れる経路を比べた（2026-10-03 時点。どれも中身は公式の MSI）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `WireGuard.WireGuard`** | 1.1.1（2026-09-20）。公式の `download.wireguard.com` の MSI を、winget が sha256 を確かめて黙って入れる。`DO_NOT_LAUNCH=1` を付けるので、入れた後に何も起動しない。PC 全体（`C:\Program Files\WireGuard`）に入る | **採用**（ほかの Windows の手順書と同じく winget） |
| 公式の `wireguard-installer.exe` | 構成に合う MSI を選び、署名を確かめて実行する（WireGuard の文書の「Enterprise Usage」）。公式のサイトが一般の利用者に案内する形 | 不採用（ブラウザと画面の操作になる。入るものは同じ） |
| scoop の `nonportable/wireguard-np` | 1.1.1（同じ MSI。sha256 も同じ）。管理者の権限で `msiexec /qn` を動かし、起動した `wireguard.exe` を止める | 不採用（[Windows 11 の初期設定](../windows-setup.md)の scoop は、管理者ではない窓で使う） |

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

- `DNS =` を書くなら `resolvconf` 経由で `systemd-resolved` が要る（→ [wireguard.md: `DNS =` を書く場合](../wireguard.md#dns--を書く場合)）
- 起動時に張るなら `systemctl enable wg-quick@wg0`。ただし Wi-Fi より先に走り、`Endpoint` が名前なら解決に失敗しうる。拠点の LAN 内でも張られる
- NetworkManager からは `connected (externally)` として見え、同名の一時プロファイルが作られる（WG ホストで実測）
- wireguard.md の namespace ラボはクライアント側をこの経路で動かして疎通を確認している（→ [リモートクライアントの検証](wireguard.md#リモートクライアントの検証2026-09-19)）。本書の NetworkManager の手順は実機でも確認済み（[対象と検証環境](#対象と検証環境)）。この wg-quick の代替手順を PC の実機で通すことは未確認

### 操作上の注意と併記されていた記録

- **拠点の LAN 内では切る**: 手順 10 以降は**どちらの拠点の LAN の外でも**行い、import 直後に自動で張られるので（実測）すぐ切る

### 操作上の注意と併記されていた記録

  - それに加えて、NetworkManager が入れる拠点 LAN の経路（**metric 50**。実測）が Wi-Fi の直結経路（metric 600）に勝ち、LAN 宛ての通信がすべてトンネルに入る

### 操作上の注意と併記されていた記録

- **MTU**: `wireguard.mtu 0` のときカーネル既定の 1420（実測）。PPPoE やモバイル回線で大きい通信だけ止まるなら `sudo nmcli connection modify wg0 wireguard.mtu 1380` して down / up（→ [wireguard.md: MTU](../wireguard.md#mtu)）

### 操作上の注意と併記されていた記録

- **サスペンド復帰・Wi-Fi の切り替え**: **2026-09-22 の実機ではどちらも試していない**（セッションを落とさずに確認する手順が無かった）

### 操作上の注意と併記されていた記録

  - **ローカルのコンソールにログイン中のユーザーは、`sudo` 無しでも読める**（実測。polkit の既定 `allow_active=yes`）

### 注意点 / 手順 0: 本文中の記録

  - 2026-09-22 の実機は `DNS =` 無しの構成で、`ipv4.dns` は `--`、接続中も `/etc/resolv.conf` は変わらなかった

### 注意点 / 手順 0: 本文中の記録

  - 実測の内容: 非 root で `nmcli -s -g wireguard.private-key connection show wg0 | wc -c` が 45 を返し、その値のハッシュは手順 3 で作った `wg0.key` と一致した（アクティブな Wayland セッション、`wheel` 所属のユーザー）

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
- **トンネル越しの ssh** で WG ホストに入れた（`SSH_CONNECTION` の送信元が `<CLIENT_TUN_IP>`）。新レイアウト（`wg0` を LAN 側ゾーンに入れる）では、ホスト自身宛ての ssh も LAN と同じ扱いになるため（→ [wireguard.md](../wireguard.md#トンネル越しに-wg-ホスト自身の-ssh-や-cockpit-へ入る場合)）
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

加えて、[注意点](../wireguard-road-warrior.md#注意点)に書いていた「非 root で秘密鍵が読める」も確認した。アクティブなローカルセッション（Wayland、`wheel` 所属）の非 root ユーザーで `nmcli -s -g wireguard.private-key connection show wg0 | wc -c` が `45` を返し、その値のハッシュは手順 3 で作った `wg0.key` と一致した。

#### 残っている未確認事項

1. `Endpoint` が DDNS 名のときの再解決（今回の `site.env` は生のグローバル IP）
1. サスペンド復帰後・Wi-Fi 切り替え後にトンネルが戻るか（作業セッションを落とさずに確認する手立てが無く、実施していない）
1. GNOME の設定画面・クイック設定に出るか（`connection.type` は `vpn` ではなく `wireguard`）
1. `DNS =` がある構成での resolv.conf の扱い（今回は `DNS =` 無し）
1. 有効なインターフェース名 + `.conf` でないファイル名を `import` が拒否するか
1. **拠点の LAN の中からトンネルを張ったときの挙動**（metric 50 の経路が LAN の直結経路を奪うことが確定したので、意図的に試していない）
1. [代替: wg-quick](../reference/wireguard-road-warrior.md#代替-wg-quick-で張る場合) と [代替: nmcli connection add](../reference/wireguard-road-warrior.md#代替-nmcli-connection-add-で組む場合rhel-のドキュメントの方式) は未検証のまま
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

Linux（クラウドのコンテナ）の PowerShell 7.6.6 と PSScriptAnalyzer 1.25.0 で確かめた（[hackgen.md](../hackgen.md) の付録と同じ環境）。この付録の手順の番号は、[Windows 11 で使う](../wireguard-road-warrior.md#windows-11-で使う)のもの。

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
- 手順 16 と[Windows 11 のロールバック](../wireguard-road-warrior.md#windows-11-のロールバック)の手順 1
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

### 付録: 新規 VM での現行手順の再検証（2026-10-06）

同日の先行検証に使った VM と分け、ISO 導入直後の AlmaLinux 10.2 Workstation から新しい x86_64 VM を用意して、`5da3478` の現行本文を再検証した。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active。一般ユーザーの SSH PTY にブラケットペースト無しで貼り、手順ごとに結果を確認した。

同じ新規 ISO 環境の 3 台目を PC にし、2 台の検証用 WG ホストとは別の帯から NetworkManager で接続した。PC で鍵を作る経路を選び、公開鍵をホストに登録・apply して発行されたテンプレートを SCP で PC へ写した。秘密鍵は VM 内で手順 8 により入れ、画面やログへ出していない。実ルーターやテザリングを使う手順 9 の検証ではない。

- 手順 10 の import 直後は activated、自動接続を no にして down した。手順 11 の up、12 の ping が成功した。アドレスは /32、ipv6 は disabled、MTU 1420、経路の metric 50、DNS 指定無し。NM の keyfile は root の 0600 で秘密は hidden だった
- A/B の両 LAN の端末役へ HTTP/TCP が 200、tracepath は A/B の WG ホストを通る。両拠点と双方の LAN の端末役から PC への ping も成功した
- A のトンネル IP を Samba の接続先として [samba-client.md](../samba-client.md) の手順 1〜5 を通し、SMB 3.1.1 で作成・読み戻し・削除・unmount が成功した。経路は wg0 だった。WireGuard 越しの fstab 自動マウントは行っていない
- ホストの登録削除は wireguard.md の 6 手順で未知 peer の公開鍵を照合して反映した。PC の手順 14・15 とロールバック 1 でリンク・平文の鍵/conf・NM プロファイル・作業ディレクトリが消えた。ロールバック 2 の対話 dnf で新規 wireguard-tools と追加依存の resolved だけが消えた

クライアント VM の OS 再起動、サスペンド、Wi-Fi 切り替え、DDNS、DNS 指定、GNOME の VPN 表示、Windows の節はこの再検証の対象外。自動接続 no の読み戻しを、再起動で張られないことの実測とはしていない。


### Windows 11 で使う / 手順 12: 補足: 張ったときに WireGuard がすること

- `/installtunnelservice <.conf.dpapi のパス>` は、トンネルのサービス `WireGuardTunnel$wg0`（自動で起動する）を作って起動する。窓の「有効化」も、同じパスで同じことをする（ソースの `manager/ipc_server.go` の `Start` と `manager/install.go` の `InstallTunnel`）
- `wireguard.exe` は GUI のプログラムなので、PowerShell は、出力をパイプでつないだときだけ終わるのを待つ。`2>&1 | ForEach-Object { "$_" }` で待ち、失敗したときのエラー（`Error: …`）を文字で出す
- アダプターの名前はトンネルの名前（`wg0`）。経路は `AllowedIPs` のとおりに、ルートのメトリック 0 で入る（ソースの `tunnel/addressconfig.go`）。インターフェースのメトリックは自動のまま（`/0` があるときだけ 0 にする）
- MTU は、conf に `MTU =` が無いと、既定の経路のインターフェースの MTU から 80 を引いた値にする（WireGuard の文書の「Network Configuration Quirks」）
- `AllowedIPs` に `/0` が無いので、キルスイッチ（トンネルを通らない通信を止めるファイアウォールの規則）は掛からない。WireGuard のパケットを通す規則を 1 つ足すだけ（同じ文書）
- アダプターの GUID は設定から決まるので、ネットワークの種類（パブリック / プライベート）は、設定を変えない限り同じものが使われる（同じ文書）。識別されないネットワークは、Windows の既定ではパブリックになるはず（確かめていない）
- `Endpoint` に名前を書いたときは、張るたびに名前を引く（ソースの `tunnel/service.go`）
- `wg.exe show` は、`.conf.dpapi` のトンネルでは管理者の権限が要る（同じ「Enterprise Usage」）



### Windows 11 のロールバック / 手順 2: 補足: アンインストールで消えるもの

- MSI のアンインストールは、WireGuard のサービス（マネージャーと、すべてのトンネル）を止めて消し、アダプターを消し、`C:\Program Files\WireGuard\Data`（トンネルの設定・ログ）と `HKLM\Software\WireGuard` を消す（ソースの `installer/customactions.c` の `EvaluateWireGuardServices`・`RemoveAdapters`・`RemoveConfigFolder`）
- PC 全体の `PATH` に足した `C:\Program Files\WireGuard\` も外れる（MSI の定義の `Permanent="no"`）
- `C:\Program Files\WireGuard` そのものも消えるはず（確かめていない）

## 参考資料から分離した記録

### 参考資料: 実施手順 / 手順 6: 補足: WG ホストでの登録

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
- `apply` は `wg0.conf` を作り直して `systemctl restart` するので、他のクライアントと拠点間トンネルが数秒切れる（`reload` では経路が入らない。→ [落とし穴 2](../wireguard.md#落とし穴-2-reload-では経路が追加されない)）
- `apply` の末尾に出るルーターの設定（クライアント帯の静的経路）は、既に入っていれば変更不要
- トンネル IP は帯の中で最小の空きが割り当たる（`--ip` で指定できる）

### 参考資料: 代替: wg-quick で張る場合

NetworkManager を使わない場合（未検証）。

- 手順 8 までは同じで、conf を `/etc/wireguard/wg0.conf` に置いて `wg-quick` で張る
- NetworkManager の `wg0` プロファイルが無いこと（同じ ifname で併用しない）

```bash
sudo install -m 600 -o root -g root "${WG_DIR:?手順 1 の WG_DIR が空のまま}/wg0.conf" /etc/wireguard/wg0.conf &&
sudo restorecon /etc/wireguard/wg0.conf &&
sudo wg-quick up wg0                     # 切るのは sudo wg-quick down wg0
```

### 参考資料: 代替: nmcli connection add で組む場合（RHEL のドキュメントの方式）

conf を import せず、値を手で写す方式（未検証）。最初から `autoconnect no` にできるのが利点。

1. `nmcli connection add type wireguard con-name wg0 ifname wg0 autoconnect no`
1. `nmcli connection modify wg0 ipv4.method manual ipv4.addresses <CLIENT_TUN_IP>/32`
1. `wireguard.private-key`（秘密鍵）
1. `wireguard.peers '<SITE_A_PUBKEY> endpoint=<SITE_A_PUBLIC>:<WG_PORT> allowed-ips=<SITE_A_LAN>;<SITE_B_LAN>;<WG_TUNNEL_NET> persistent-keepalive=25'`（`allowed-ips` は `;` 区切り。`nm-settings-nmcli(5)`）
1. `nmcli connection up wg0`

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 補足 / 手順 9

  - NetworkManager では `ipv4.dns` になり、接続中は resolv.conf を NetworkManager が書き換えるので、`systemd-resolved` は要らない（未確認）

- **`Endpoint` が DDNS 名のとき**: NetworkManager が再解決するかは未確認（→ [wireguard.md](../wireguard.md#endpoint-に-ddns-名を書く場合)）。本書の例は IP リテラル

  - `autoconnect no` のプロファイルをスリープ復帰後に NetworkManager が張り直すかは要確認（張り直さない可能性が高い。復帰後に `nmcli device status` を見る）

  - Wi-Fi が変わっても、WireGuard は送信元の変化に追従するはず（要確認）。`PersistentKeepalive = 25` が NAT の穴を維持する

- **GNOME の UI**: NetworkManager のプロファイルなので設定画面から up / down できる可能性があるが未確認

- **Windows 11 の注意点**（どれも Windows では確かめていない）

  - **`Endpoint` が DDNS 名のとき**: トンネルを張るたびに名前を引く（ソースの `tunnel/service.go`）。張っている間に相手の IP が変わったときは確かめていない

  - **サスペンド復帰・Wi-Fi の切り替え**: 確かめていない

---

### 付録: Windows 11 Pro の VM での新規導入の検証（2026-10-06）

[Windows 11 の初期設定](windows-setup.md#付録-windows-11-pro-の-vm-での導入検証2026-10-06)を検証中の専用 VM で、[Windows 11 で使う](../wireguard-road-warrior.md#windows-11-で使う)の手順 3・4 のコードブロックを抜き出して、そのまま実行した。本体の新規導入だけを検証し、鍵やトンネルの設定は作っていない。

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro 26H2 / ビルド 26300.9457 / x64 |
| VM | VirtualBox 7.2.20。Rufus で作った媒体からクリーンインストールした専用 VM |
| PowerShell | Windows PowerShell 5.1.26100.9444 / Desktop / x64。ログオン中のユーザーの管理者権限（Session 1） |
| WinGet | 1.29.380。`WireGuard.WireGuard` を `--source winget` で新規導入 |
| 検証時の本文の SHA256 | `82D40978DB8C534EB0DE3785A8E315A61E1D1ECCEE74E0D65FA820DB376E64C7`（この追記より前） |
| 抜き出したブロックの manifest の SHA256 | `5AB55CD6E33EAA94C087E02D756F1DBE6F1E2FD84A1D5EA628232E10C57B2FF0` |

**確認したこと**（バッチ `20261006-111858Z-dd62f552`、完了 11:19:15 UTC）:

- 手順 3 の一覧は `No installed package found matching input criteria.`、ユーザーの鍵の置き場所は `False`。WireGuard のサービスと設定ファイルの一覧には出力がなかった
- 未導入を確認する winget の終了コード `-1978335212` は、この手順で期待する結果だった
- 手順 4 は公式の `wireguard-amd64-1.1.1.msi` を取り、インストーラーのハッシュ検証が成功し、`Successfully installed` が出た。続く一覧は `WireGuard.WireGuard 1.1.1`
- `C:\Program Files\WireGuard\wireguard.exe` と `wg.exe` は、どちらも Authenticode の署名が `Valid`、署名者が `CN=WireGuard LLC` だった
- `wg --version` は `wireguard-tools v1.0.20260223 - https://git.zx2c4.com/wireguard-tools/` だった
- 全ブロックの PowerShell のエラーは 0、最後の終了コードは 0

**確認していないこと**:

- 手順 1 の端末を開く画面操作と、手で貼る操作。端末の起動は検証用の処理で代替した
- 手順 2 の 4 つの実際の IP、WG ホストの接続設定、鍵の作成と登録。接続先の実設定は提供されていない
- 手順 5 以降のマネージャーの画面、設定の取り込み、トンネルの起動、経路・MTU・DNS・ネットワークの種類、拠点との疎通と外部の SSH 接続
- トンネルを張ったままの再起動、更新とロールバック、サスペンド復帰、Wi-Fi の切り替え、DDNS、arm64 の Windows

---

### 付録: Windows 11 Pro の VM でのマネージャーのサービスと鍵生成の検証（2026-10-07）

前の新規導入と同じ専用 VM で、[Windows 11 で使う](../wireguard-road-warrior.md#windows-11-で使う)の手順 6 のコードブロックを変更せず、管理者の Windows PowerShell 5.1 で実行した。手順 5 のマネージャーの画面は操作せず、[公式の CLI](https://git.zx2c4.com/wireguard-windows/about/docs/enterprise.md) による一時的なサービスの作成・確認・削除で代替した。

| 項目 | 値 |
|---|---|
| 環境 | Windows 11 Pro の同じ専用 VM。ログオンユーザー r-aoki の管理者権限 |
| PowerShell | Windows PowerShell 5.1.26100.9444 / Desktop。`USERPROFILE`・`HOME`・`CODEX_HOME` は変更していない |
| 実行時刻 | 2026-10-07 09:47:01〜09:47:25 UTC |
| 実行した manifest が記録する本文の SHA256 | `82D40978DB8C534EB0DE3785A8E315A61E1D1ECCEE74E0D65FA820DB376E64C7` |
| 実行した source manifest の SHA256 | `5AB55CD6E33EAA94C087E02D756F1DBE6F1E2FD84A1D5EA628232E10C57B2FF0` |
| 手順 6 のコードの SHA256 | `7A80E2789044868A2424D623BD945F871E9CAA2005F8E97141C185453377C166` |

**確認したこと**（証跡 `remaining-wireguard-local-20261007-094630-d8f8efb9`）:

- `wireguard.exe` と `wg.exe` の Authenticode の署名は `Valid / WireGuard LLC` だった。実行前は WireGuard のサービス・プロセス・設定のディレクトリ・`wg-client` と既存の `wg0` がなく、スキップせず検証した
- `/installmanagerservice` の終了コードは 0。`WireGuardManager` は `Running`・`Auto` で、サービスのパスは `"C:\Program Files\WireGuard\wireguard.exe" /managerservice`、PID は 6948 だった。PID の実行ファイルも一致した
- 手順 6 は終了コード 0。`wg0.key` と `wg0.pub` はともに 45 バイトの ASCII、末尾は LF のみで、鍵は Base64 の 32 バイト形式だった。秘密鍵を標準入力に渡したローカルの `wg pubkey` は終了コード 0、保存された公開鍵と一致した
- `wg-client` の ACL は継承を遮断し、Administrators（`S-1-5-32-544`）と SYSTEM（`S-1-5-18`）の FullControl の 2 件だけだった。両ファイルも同じ 2 件を継承し、所有者は Administrators だった
- source の出力は全ストリームを破棄し、証跡には鍵の値や秘密鍵のハッシュを載せていない。今回作成した `C:\Users\r-aoki\wg-client` だけを削除し、不在を確認した
- `/uninstallmanagerservice` は終了コード 0。サービスの不在と WireGuard のプロセス 0 件を確認し、元の状態へ戻した。新しくできた `C:\Program Files\WireGuard\Data` は残し、設定の置き場所のファイルは 0 件だった
- 補助検証は `passed=true`。検証用の管理者タスクと結果のコピーの終了コードは 0 で、一時的な実行要求も元のハッシュへ復元された
- `guest-result.json` と `source-manifest-executed.json` は `.verification/evidence/remaining-wireguard-local-20261007-094630-d8f8efb9` に保存した

**確認していないこと**:

- 手順 5 のマネージャーの起動・表示・操作と、Windows の端末へ手で貼る操作
- 既存の鍵がある場合の手順 6 の分岐。今回の鍵生成は、置き場所が完全に存在しない場合だけで、既存の設定や鍵は使っていない
- 実際の IP・WG ホストの設定、公開鍵の登録、conf の作成・取り込み、トンネルの起動、拠点との疎通と外部の SSH 接続
- VPN 全体の動作、張ったままの再起動、更新・ロールバック、サスペンド復帰、Wi-Fi の切り替え、DDNS、arm64 の Windows

---

### 付録: Windows 11 Pro の VM での VPN の通し検証（2026-10-08）

上の付録と同じ Windows の VM（[windows-setup.md の検証記録の 2026-10-08 の付録](windows-setup.md#付録-pr-104-の未検証項目を同じ-vm-で確かめた記録2026-10-08)の環境）で、[Windows 11 で使う](../wireguard-road-warrior.md#windows-11-で使う)の手順 1〜16 と更新・ロールバックを、2 拠点の WG ホストの検証環境に向けて通した。物理のルーター・NAT・DDNS・インターネット越しの接続は使っていない。

**検証環境**:

| 項目 | 値 |
|---|---|
| WG ホスト（拠点 A・B） | 同じホストの AlmaLinux 10.2 の VM 2 台（`alma10-pr100-client-20261007` を拠点 A、`alma10-pr100-pc-20261007` を拠点 B）。ホストオンリーのネットワークの 192.168.56.82・.81 を `SITE_A_PUBLIC`・`SITE_B_PUBLIC` にした |
| 拠点の LAN | それぞれの VM に veth の対を作り、片方を拠点の LAN 側（`lanA` 192.168.110.2/24・`lanB` 192.168.120.2/24）、もう片方を network namespace のルーター役（`routerA` 192.168.110.1・`routerB` 192.168.120.1、既定の経路は WG ホスト）にした。`lanA`・`lanB` は firewalld の public ゾーンに入れた（一時的な設定） |
| WG ホストの手順 | このリポジトリの 8a79aff を clone し、`site.env.example` から `site.env` を作って `SITE_A_PUBLIC`・`SITE_B_PUBLIC` だけを直し、[wireguard.md](../wireguard.md#実施手順) の `keygen` → 公開鍵を `site.env` に書く → `--dry-run apply` → `apply` を両拠点で行った（`wireguard-tools` 1.0.20250521 と `systemd-resolved` が入った）。`routerA` から `routerB` まで届いた（経路 MTU 1420、3 ホップ） |
| Windows の PC | 2 枚目の NIC（「イーサネット 3」、192.168.56.107）で拠点 A の WG ホストに届く。拠点の LAN（192.168.110.0/24・192.168.120.0/24）の外にいる形 |
| 変数 | 手順 2 の本文の例の値（`10.99.0.1`・`192.168.110.2`・`192.168.110.1`・`192.168.120.2`）が、検証環境の値と同じだったので、そのまま貼った |

**確認したこと**（手順はすべて Windows 11 で使うの番号）:

| 手順 | 結果 |
|---|---|
| 1 | スタートから管理者の Windows PowerShell（conhost）を開いた |
| 3 | WireGuard 1.1.1 が入っている状態（上の付録で入れたもの） |
| 4 | winget は新しい版なしの旨。署名は `Valid`・WireGuard LLC。`wg.exe --version` は `wireguard-tools v1.0.20260223` |
| 5 | WireGuard の窓（「トンネル」「ログ」のタブ）が開き、`WireGuardManager` は `Running`・`Automatic` |
| 6 | `%USERPROFILE%\wg-client` の ACL は SYSTEM と Administrators だけ。鍵ファイルは 45 バイト。鍵の値はこの記録に載せない |
| 7 | `Import-WgClientConf` を定義した（何も出ない） |
| 8 | 拠点 A の WG ホストで実施手順 4・6（`client add A win-pr104 --pubkey …` → `apply A` → `client show win-pr104`）。トンネル IP は 10.99.1.1。表示した conf を Windows のクリップボードに置いた |
| 9 | `Import-WgClientConf` を手で打って Enter（検証ではホストからのキーで打った）。`1` と、`PrivateKey` 以外の行が `client show` のとおりに出た |
| 10 | `wg0.conf.dpapi`（540 バイト）の 1 行だけ。写した `wg0.conf` は消えた |
| 11 | この PC はもとから拠点の LAN の外（ホストオンリーのネットワーク）にいるので、つなぎ替えはしていない |
| 12 | `WireGuardTunnel$wg0  Running  Automatic`、`wg0` に `10.99.1.1`/`32`、`AllowedIPs` の経路 3 つ（`RouteMetric` 0）、`NlMtu` 1420、`NetworkCategory` は `Public`、`ServerAddresses` は `{}`、`latest handshake` は 7 秒前 |
| 13 | 4 つのあて先とも `0% の損失`。`tracert` は `10.99.0.1` → `192.168.120.2` |
| 14 | 拠点 A の WG ホストで実施手順 13: `client list` の `win-pr104` の `LAST_HANDSHAKE` が 49 秒前。拠点 → PC の `ping` は 100% の損失（本文のとおり、Windows のファイアウォールが受けない） |
| 15 | トンネルのサービスとアダプター `wg0` が消えた |
| 16 | `wg0.pub` だけが残った |

- Windows 11 の更新: winget は `No available upgrade found.`、マネージャーは `Running` のまま
- Windows 11 のロールバックの手順 1: 最後に `False` だけが出た
- Windows 11 のロールバックの手順 2（WG ホストの手順 3 の後に行った）: `Found WireGuard [WireGuard.WireGuard]`・`Starting package uninstall...`・`Successfully uninstalled`、`winget list` は `No installed package found matching input criteria.`、サービスは何も出ず、`False`。WireGuard の窓と `wireguard.exe` のプロセスも消えた
- Windows 11 のロールバックの手順 3（WG ホストで、[wireguard.md のクライアントを削除する](../wireguard.md#クライアントを削除する)の手順 1〜6）: 手順 3 は `client remove` の後の dry-run が、その公開鍵の未知の peer だけを挙げて終了コード 1 で止まった。手順 4 の `--drop-unknown-peers --dry-run`、手順 5 の本適用の後、手順 6 でクライアントは無く、`wg show wg0 peers` は拠点 B だけ
- 検証環境は、両拠点で [wireguard.md の全部消す](../wireguard.md#全部消すロールバック)の手順 1〜4 と、veth・namespace・clone の削除で片付けた。拠点 A の `remove A --purge` の後も `/etc/wireguard` に `wg0.conf.bak-<日時>` の 2 つ（`client add`・`client remove` の `apply` が作った控えで、秘密鍵を含む）が残った。`--purge` は控えを消さない（`scripts/wireguard/wg-vpn.sh` の `cmd_remove`）。検証用の鍵なので手で消した

**確認していないこと**:

- インターネット越し（物理のルーターのポート転送・NAT・DDNS）と、テザリングなどへのつなぎ替え
- トンネル越しの SSH、相手拠点の LAN 上の別のホスト、張ったままの再起動、サスペンド復帰、Wi-Fi の切り替え、arm64 の Windows、Windows の実機
