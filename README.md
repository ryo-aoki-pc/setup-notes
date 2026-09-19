# setup-notes

実機で検証した構築・設定手順の記録。

「動いた手順」だけでなく、**なぜ失敗したか・どう切り分けたか**も残すことを重視している。同じ作業を別の環境でやり直すとき、あるいは同じ症状に再び出くわしたときに、調査をやり直さずに済むようにするのが目的。

## 手順書一覧

| ドキュメント | 対象 | 概要 |
|---|---|---|
| [GNOME Remote Desktop 有効化手順](docs/gnome-remote-desktop.md) | AlmaLinux 10.2 (x86_64 / aarch64) / gnome-remote-desktop 49.3 | リモートログイン方式（システムデーモン）の CLI 設定。openssl による TLS 証明書生成（SAN 付き）、FreeRDP 無しでの TLS 検証、ログイン失敗の原因調査、winpr-makecert との比較を含む |
| [WireGuard VPN 構築手順](docs/wireguard.md) | AlmaLinux 10.2 (aarch64) / wireguard-tools 1.0.20250521 / firewalld 2.4.3 | ルーター配下の WG ホスト同士で 2 拠点の LAN を相互接続し（wg-quick + systemd）、さらに外出先の PC・スマートフォンを任意の台数追加して両拠点の LAN に到達させる。**値を `site.env` に 1 度書けば、以降は編集せずにコピペで実行できる**手順書（手順 0〜7 が拠点間、8〜13 がクライアント追加。拠点 A / B の読み替えは自動）。firewalld の専用ゾーン + policy による転送制御、`wg0 → wg0` 折り返しの policy、ルーター側の要件（ポート転送・静的経路・ヘアピン）、reload と引用符の落とし穴を含む。network namespace で両拠点とクライアントの疎通まで確認。同じ `site.env` を読むスクリプト（[`scripts/wireguard-site-to-site/`](scripts/wireguard-site-to-site/)、既存 conf の流用可）付き |

## 記法の約束

- **環境固有の値はプレースホルダで書く。** `<HOSTNAME>` / `<HOSTNAME>.<DOMAIN>` / `<SERVER_IP>` / `<LAN_SUBNET>` / `<USER>` など。各ドキュメントの冒頭に対応表を置く
- **コピペで実行できる手順書は、プレースホルダの代わりにシェル変数を使う。** WireGuard の手順書は `${SITE_A_LAN}` の形で書き、値は `site.env` 1 ファイルに集約して冒頭で読み込む。読者が編集するのはその 1 ファイルだけで、コマンドブロックは書き換えない
- **検証した環境のバージョンを明記する。** ディストリビューション、対象パッケージ、関連ツールのバージョンを冒頭に書く
- **コマンドは実際に実行したものを載せる。** 出力やログも、切り分けの根拠になるものは引用する
- **秘密情報は書かない。** パスワード・鍵・トークンの類は、たとえ private リポジトリでも残さない

## 収録内容から: 再利用価値の高い知見

収録している手順書から、他の作業でも効いてきそうなものを抜粋する。

### [GNOME Remote Desktop](docs/gnome-remote-desktop.md)

- **`grdctl` の対話入力は TTY 必須** — 引数なしの `set-credentials` は stdin ではなく制御端末から読む。スクリプトやパイプ経由では**何も設定されないまま exit 0 で終わる**ため、失敗に気づきにくい
- **資格情報の変更にはデーモンの再起動が必要** — 設定ファイルには書けているのに拒否され続ける。`grdctl status` 側は設定済みに見えるため紛らわしい
- **ログの署名で失敗原因が切り分けられる** — `Credentials are not set`（未設定/未再起動）/ `Could not find user in SAM database`（ユーザー名不一致）/ `SEC_E_MESSAGE_ALTERED`（パスワード不一致）/ `Sending server redirection`（成功）。ユーザー名とパスワードで別のエラーが出るのが決め手
- **openssl は「代替」ではなく upstream 公式の証明書生成方法** — `winpr-makecert` は Red Hat のドキュメントが採用しているだけで、GRD 側の要件ではない。要件は PEM 形式・所有者・SELinux コンテキストの 3 点のみ。追加パッケージ不要なのでメイン手順に採用している
- **`grdctl --system rdp enable` はサービスも起動する** — その後に設定した資格情報は再起動まで反映されない。また `disable` → `enable` の後に `~gnome-remote-desktop/.local/share/gnome-remote-desktop/grd.conf` に `enabled=false` が残り、再起動しても無効のままになったことがある
- **FreeRDP は SAN の `IP:` エントリを照合しない** — DNS エントリしか見ない。IP で接続する運用なら、IP を `DNS:` としても併記する必要がある
- **TLS の可否だけをパスワード無しで検証できる** — 存在しないユーザー名で接続し、認証段階のエラーまで到達するか、その手前の TLS ハンドシェイクで落ちるかを見る。FreeRDP が無くても、X.224 ネゴシエーション後に TLS を張る Python スクリプト（標準ライブラリのみ）で提示証明書の fingerprint と SAN を確認できる

### [WireGuard VPN](docs/wireguard.md)

- **`AllowedIPs` に書いた範囲は wg-quick が経路としても追加する** — 拠点間ではトンネル IP だけでなく相手 LAN を書くのが要。ただし経路が追加されるのは `up` の時だけで、**`systemctl reload` では経路は変わらない**。`AllowedIPs` や `Address` を変えたら、クライアントの peer を足したときも含めて restart する
- **秘密鍵を `PostUp = wg set %i private-key ...` で読み込むと、reload で鍵が消える** — `wg-quick@.service` の reload は `wg syncconf` + `wg-quick strip` で、strip の出力に `PrivateKey` が無いため。`PrivateKey` は conf に直接書く
- **firewalld 2.4 には `gateway-lan-to-world` などの policy が最初から入っている** — `internal` / `home` / `trusted` ゾーンから `public` / `external` への転送を ACCEPT する。トンネルのインターフェースをこれらのゾーンに入れると意図せず転送が通るので、専用ゾーンを作って policy で許可する
- **待ち受けポートの開け忘れは、自拠点から張ると気づかない** — 自分から送ったハンドシェイクへの応答は conntrack で通る。相手側から張り直すときに初めて失敗する
- **WG ホスト自身から相手 LAN へは、送信元がトンネル IP になる** — 相手 LAN がトンネル網への経路を知らないと応答が戻らない。クライアント同士の通信は問題ないため、見落としやすい
- **ルーター配下に置いた VPN ホストはヘアピン（非対称経路）になる** — Linux ルーターでは ICMP Redirect の有無にかかわらず通ったが、状態追跡をするルーターでは TCP が切られる可能性がある
- **`firewall-cmd --add-rich-rule` に変数を使うなら二重引用符にする** — 解説の多くは単一引用符で書いているが、それだと `${VAR}` が展開されず、`$MY_LAN` という文字列がそのまま rich rule に登録される。**firewalld はそれを `success` で受理する**ので、`--info-policy` を見るまで気づかない
- **A/B 対称な構成は「自分視点」の派生変数に畳める** — 両拠点の値を 1 ファイルに持ち、自ホストの IP からどちらの拠点かを判定して `MY_*` / `PEER_*` を組み立てれば、手順のコマンドが両拠点で完全に同じになる。拠点ごとの書き分けが消え、A/B の取り違えも構造的に起きなくなる
- **`firewall-cmd --get-zone-of-interface` はゾーン未割り当てのとき `no zone` を stderr に出して 2 を返す** — stdout を `"no zone"` と比較する書き方では検出できず、変数が空のまま次のコマンドに渡る。終了コードで判定して既定ゾーンに落とす
- **firewalld 2.4.3 に `--query-policy` は無い** — `--query-service` などがあるので類推で書くと `unrecognized arguments` で終了コード 2 になり、「存在しない」と誤判定してロールバックが丸ごと空振りする。存在確認は `--info-policy` の終了コードで行う
- **policy はゾーンより先に削除する** — 参照されているゾーンを先に消すと、`--reload` が `INVALID_ZONE: Policy '…': 'wireguard' not among existing zones` で失敗し、firewalld の設定が壊れた状態になる
- **`AllowedIPs` は 1 インターフェース内で peer ごとに排他** — 1 つのアドレスを 2 つの peer に対応づけられない（cryptokey routing）。クライアントは拠点に所属させ、拠点ごとに帯を分ければ、相手拠点のホストには「その帯は拠点 peer の向こう」と 1 行書くだけで済み、クライアントを増やしても相手拠点の設定は変わらない
- **相手拠点のホストの `AllowedIPs` にクライアント帯が無いと、黙って捨てられる** — WireGuard は送信元が `AllowedIPs` 外のパケットを ICMP なしで捨てる。ハンドシェイクも転送も正常に見えたまま届かない
- **NAT しない構成では、ルーターにクライアント帯の静的経路も要る** — LAN 側ホストの返事はデフォルトゲートウェイに向かう。相手拠点のルーターにも要る。トンネル網とクライアント帯を 1 つの大きな帯に取っておけば、静的経路は 1 本で済む
- **firewalld の policy は ingress と egress に同じゾーンを指定でき、実際に効く** — `wg0` から入って `wg0` へ折り返す転送（クライアント → 相手拠点 LAN）を rich rule で絞れる。ゾーンの `forward` オプションだと `wg0` 内の転送がすべて通る。network namespace のラボで、その policy を外すと折り返しだけが `Packet filtered` になることを確認した（2.4.3）
- **クライアント conf の `AllowedIPs` にはトンネル網も入れる** — WG ホスト自身がクライアントに送るパケットの送信元は `wg0` のアドレスになる。無いとクライアント側で捨てられる
