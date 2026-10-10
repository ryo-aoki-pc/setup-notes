# Forgejo 構築手順（AlmaLinux 10 / rootless Podman + Quadlet / LAN・VPN 内で使う）の参考資料

[手順書](../forgejo.md)・[ロールバック](../extra/forgejo.md)・[検証記録](../verification/forgejo.md)

## 補足

### 実施手順 / イメージを取得して localhost で起動する / 手順 1: 補足: 変数

- `SERVER_IP` は、Forgejo の Web・Git の接続先にも使う
- `FW_ZONE` は自動で入る

### 実施手順 / イメージを取得して localhost で起動する / 手順 2: 補足: 同じシェルで続ける理由

- 「イメージを取得して localhost で起動する」の手順 3 を同じシェルに続けて貼るのは、同じ項の手順 2 で調べた `FORGEJO_VERSION` を使うため

### 実施手順 / イメージを取得して localhost で起動する / 手順 3: 補足: イメージの行

- イメージの行には、「イメージを取得して localhost で起動する」の手順 2 で調べた版の番号が入る

### 実施手順 / イメージを取得して localhost で起動する / 手順 5: 補足: まだ公開しない

- この時点では LAN に公開しない

### 実施手順 / 自動更新を有効にする / 手順 1: 補足: 貼り直したとき

- 「自動更新を有効にする」の手順 1 を貼り直すと、プログラムだけを置き直す。Quadlet とデータは変えない

### 実施手順 / 自動更新を有効にする / 手順 2: 補足: ユニットの役割

- `.service` がプログラムを 1 回動かす。`.timer` は、毎日 4:00〜4:30（サーバーの時刻）のどこかで `.service` を起動する

### 実施手順 / 自動更新を有効にする / 手順 3: 補足: linger

- [linger](../linger.md) が有効なので、ログアウトしていてもタイマーは動く

### 使い方の基本 / 手順 1: 補足: アカウント

- アカウントを管理者に作ってもらうのは、自己登録が無効なため

### バックアップから復元する / 手順 5: 補足: SELinux のラベル

- SELinux のラベルは、専用 bind mount の `:Z` で反映される

### バックアップから復元する / 手順 7: 補足: 保留した版

- 自動更新はその版を飛ばし、journal に `保留中:` を出す（終了コード 1）。さらに新しい版が出たら、自動で更新する

## 選択した方針

- 既存の [Podman の手順](../podman.md)と同じく、ホストの一般ユーザーで rootless Podman を動かす。常駐は Quadlet と [linger](../linger.md)を使う
- Forgejo は公式の `-rootless` イメージを使い、コンテナ内も UID・GID 1000 で動かす。ホストの一般ユーザーとコンテナのユーザーを `keep-id` で対応させる
- DB は SQLite にする。小規模で同時操作が多くない構成では外部 DB の導入・保守が不要になる。Forgejo の公式バイナリとイメージは SQLite に対応している。高い同時負荷では PostgreSQL または MySQL / MariaDB を検討するが、既存 DB の変更は単純な設定変更だけではできない
- HTTP 3000 と Git 用 SSH 2222 を、初期設定中は localhost、管理者作成後は指定した LAN / VPN の IPv4 に公開する。ホストの OpenSSH と OS のユーザー認証はそのまま使う
- 公式の最新安定版を導入時に自動で調べて入れ、以後は毎日のユーザータイマーで最新の安定版へ自動で更新する（利用者の指定）。Quadlet には調べた版の番号を書き、停止バックアップ・更新・確認・失敗時の自動の戻しを組にする

### 実施手順 / イメージを取得して localhost で起動する / 手順 2・3: 最新安定版とイメージの選択

- 手順書に版の番号を書かない。「イメージを取得して localhost で起動する」の手順 2 で、Codeberg の API（`/api/v1/repos/forgejo/forgejo/releases?draft=false&pre-release=false&limit=50`）から、`v<数>.<数>.<数>` の形で下書きとプレリリースでないものの最も大きい番号を選ぶ
- `/releases/latest` は、最後に公開したリリースを返す。LTS（15.x・11.x）のパッチは通常版と前後して公開される（2026-09-17 は v15.0.9 の 3 分後に v16.0.5）ので、公開順では LTS の版を選ぶことがある。番号の大きさで選ぶ
- 通常系列は次のメジャー版が出た 2 週間後にサポートを終える（16 系の期限は 2026-10-29）。最も大きい番号を選び、毎日更新するので、新しいメジャー版が出ると数日のうちにそちらへ移る。予定は[公式の予定](https://forgejo.org/docs/latest/admin/release-schedule/)と[リリース一覧](https://forgejo.org/releases/)にある
- `16-rootless`・`16.0-rootless` は対応する系列のパッチ版へ動くタグで、`16.0.5-rootless` は版を指定するタグ。本書は取得・起動・バックアップ・復元で同じ版を指すため、調べた番号の後者を Quadlet に書く
- 2026-10-10 の確認時点でも、公式レジストリには `latest`・`latest-rootless` の汎用タグが無い（418 個のタグの中で、動くタグは系列ごとの `16`・`16.0` など）
- 「イメージを取得して localhost で起動する」の手順 2 と自動更新のプログラムの版を選ぶ関数は、同じ文字列にしてある。片方を直すときは、もう片方も直す
- 公式の Podman 例は root 管理の `/etc/containers/systemd` とホストポート 222 を使う。本書は rootless Podman のユーザー unit に変え、1024 以上のホストポートを使う

### 実施手順 / イメージを取得して localhost で起動する / 手順 3: rootless の 2 つの意味とデータ

| 項目 | 本書の指定 | 役割 |
|---|---|---|
| ホストの実行権限 | 一般ユーザーの rootless Podman | ホストの root 権限でコンテナを動かさない |
| イメージ | 公式の `-rootless` | コンテナ内で非 root の Forgejo を動かす |
| `User=1000` / `Group=1000` | Quadlet の `[Container]` | コンテナ内の実行 UID・GID |
| `UserNS=keep-id:uid=1000,gid=1000` | コンテナ用ユーザー名前空間 | Podman を動かすホストユーザーをコンテナの 1000 に対応させる |
| bind mount | `%h/.local/share/forgejo:/var/lib/gitea:Z` | 自分が所有する専用ディレクトリを永続化する |

- rootless Podman で root ユーザーを含むイメージを動かすことと、rootless イメージをホストの root で動かすことは、それぞれ別の選択になる
- 通常の Forgejo イメージは `/data` とコンテナ内部 SSH 22、rootless イメージは `/var/lib/gitea` と内部 SSH 2222 を使う。本書ではホストの 2222 から内部の 2222 へ公開する
- 通常イメージの `USER_UID` / `USER_GID` とホストの所有者変更を、そのまま rootless Podman に流用しない。本書は Quadlet の実行ユーザーとユーザー名前空間を指定する
- `:Z` はマウント元の SELinux ラベルを付け替える。ホーム全体や既存の共有ディレクトリを指定せず、Forgejo 専用の場所だけに付ける
- `/var/lib/gitea/custom/conf/app.ini` は永続データの中にある。v15 で以前の `/etc/gitea/app.ini` 向けの互換処理が取り除かれ、v16 もこの配置を使う。Gitea の rootless 構築例のパスは写さない
- `Restart=on-failure` は異常終了時の再起動、`TimeoutStartSec=300` は初回のイメージ取得などを待つ時間。起動時の生成は `WantedBy=default.target` が受け持つ。生成 unit に `systemctl --user enable` は使わない

### 実施手順 / イメージを取得して localhost で起動する / 手順 3、初期設定と管理者の作成 / 手順 2・3、LAN に公開する / 手順 2: 初期設定と設定の反映

- コンテナ起動時の `FORGEJO__[SECTION]__[KEY]` は `app.ini` へ反映される。画面で変更した同じ項目が再起動後に元へ戻る場合は、Quadlet 側の値を確認する
- `ROOT_URL` はブラウザに見える URL、`HTTP_ADDR` / `HTTP_PORT` はコンテナ内の待ち受け。host の `PublishPort` は外部へ公開するアドレスと番号。これらは別々に指定する
- 初期設定のトンネルではクライアントとサーバーの両方を `127.0.0.1` に限定し、クライアント側でも最終的な Web ポートと同じ番号を使う。初期の `ROOT_URL` とブラウザの接続先をそろえた後、公開時に LAN の URL へ切り替える
- `DISABLE_REGISTRATION=true` は通常の自己登録を無効にする。初期設定画面の管理者作成まで省略する指定ではない。管理者作成と初期設定の保存を終えてから公開する
- OpenID を使わない構成なので、`openid.ENABLE_OPENID_SIGNIN` と `openid.ENABLE_OPENID_SIGNUP` も明示して無効にする。通常の自己登録の設定だけで外部認証の入口まで同じ表示になるとは扱わない
- `INSTALL_LOCK` は初期設定が終わったときに `app.ini` に保存される。環境変数で `false` を指定し続けると再起動で反映されるため、本書の Quadlet には置かない
- `REQUIRE_SIGNIN_VIEW=true` はログイン前の閲覧を制限する。リポジトリの公開範囲は、それぞれのリポジトリの設定でも決まる
- v16 では、コンテナの `security.REVERSE_PROXY_TRUSTED_PROXIES=*` の既定指定が廃止された。本書も信頼するプロキシを localhost に明示し、リバースプロキシ認証を有効にしない
- `app.ini` には最初のセクション見出しより前に root のキーがある。確認コマンドの Python は、読み取り時に `[DEFAULT]` を付けて `configparser` で扱う。設定内容全体は表示しない

### 実施手順 / LAN に公開する / 手順 1・3: 通信の範囲

- 本書の rich rule は `family=ipv4`・送信元 CIDR・宛先 IPv4・対象ポート・`priority=100` を組にする。最初から存在する同じ規則には重ねず、撤去ではその組に一致する規則だけを外す
- runtime と permanent の両方へ追加・削除する。既存のほかの runtime の設定も保存してしまう `--runtime-to-permanent` は使わない
- 許可の規則を追加しても、既存の `trusted` zone や `target=ACCEPT`、ポートやサービスへの広い許可を打ち消すものにはならない。許可外の送信元から接続できないことの確認を別に行う
- rootful Podman の Netavark はコンテナ向けに転送の許可を設定する。本書の rootless Podman は別の経路で、rootful 用の firewalld 転送ポリシーや `StrictForwardPorts` を採用しない
- LAN の IPv4 を待ち受けたまま VPN のクライアントから使うときは、VPN にその LAN への経路があり、サーバーから見える送信元が許可 CIDR に入る必要がある。VPN 経由の SNAT があると送信元は変わる
- HTTP の内容は暗号化されない。VPN や SSH トンネルの外で Web を使う運用へ広げるときは、HTTPS の構築と公開範囲を別に設計する

### 実施手順 / Git の接続を確かめる / 手順 1〜5: Git とアカウント

- OS のユーザーは rootless Podman とユーザーサービスを動かす。Forgejo のユーザーは Web 上のアカウント。clone URL の `git` はコンテナ内の SSH 接続用ユーザーで、これらは同じ名前である必要がない
- `SSH_PORT` は clone URL に表示するホストの番号、`SSH_LISTEN_PORT` は内蔵 SSH の内部番号。本書では後者を 2222 に固定する
- SSH のホスト鍵は永続データに保存される。サービス再起動やコンテナ再作成で変わらないことを確認する。初回の確認でホストの OpenSSH 22 の鍵と取り違えない

### 実施手順 / 自動更新を有効にする / 手順 1〜3・更新: 自動更新

- Podman の自動更新（`AutoUpdate=registry` と `podman auto-update`）は採らない
  - 動くタグは系列の中だけなので、メジャー版をまたいで最新版へ進めない
  - 失敗時の戻しは旧イメージの再起動だけで、DB の移行の後は元に戻らない（この節の下の「バックアップ・…・更新」）
- 代わりに、ユーザーの systemd の `oneshot` サービスとタイマーで自前のプログラム（`~/.local/bin/forgejo-auto-update`、Python の標準ライブラリだけ）を動かす。プログラムは手順書の「自動更新を有効にする」の手順 1 のブロックにだけ置き、リポジトリに別のファイルを置かない
- 流れ
  - Quadlet の目印・イメージの行・Web と Git 用 SSH の `PublishPort` が 1 行ずつあることを確かめてから、最新の安定版を調べる
  - 新しい版があれば、イメージを取得して版を確かめ、空き容量（データの 2 倍と 1 GiB）と、データとバックアップが同じファイルシステムにあることを確かめる。ここまでは何も止めない
  - 止めて、手動のバックアップと同じ `tar` の中身でアーカイブを作り、イメージの行だけを書き換えて起動する
  - Web の `/api/healthz` が `pass`、Git 用 SSH が `SSH-2.0-` を返し、動いている版が新しい版で、`doctor check --all` が成功すれば終わり。DB の移行を待つため、応答は 15 分まで待つ。doctor は、起動直後の一時的な失敗で戻さないよう 30 秒おきに 3 回まで試す
- 失敗したときは、展開してから止め、今のデータと新しい定義を `failed-update-<日時>` へ `rename` で退避し、展開したデータと前の定義へ入れ替えて起動・確認する。退避と入れ替えは同じファイルシステムの中の `rename` だけで行う
- 戻した版は `skip-version` に書いて保留する。同じ版で毎晩失敗と戻しを繰り返さないため。さらに新しい版が出たら、その版は試す。保留中は終了コード 1 にして、`systemctl --user` の結果で気付けるようにした
- Forgejo が `inactive` のときは、手作業（バックアップ・復元）の途中とみなして何もせずに終わる。手作業の側は、自動更新が `activating` の間は止める（`is-active` は `activating` を active として扱わないので、`ActiveState` を見る）。プログラムは `flock` で重ねて動かさない
- 時刻は毎日 4:00 から 30 分の間。`Persistent=true` は付けない。止めていた PC を起動した直後（昼間）に更新が走るのと、ユーザーのユニットからシステムの `network-online.target` を待てないため
- サービスの `PATH` は `/usr/bin` に固定する（GNOME のセッションから Homebrew の `PATH` を受け取らないため）。`TimeoutStartSec=2h` で、止まったままの実行が次の実行を塞ぎ続けないようにする
- `/api/healthz` は、`REQUIRE_SIGNIN_VIEW=true` でもログイン無しで `pass` を返す（2026-10-10 に確認。検証記録）。プロキシの環境変数があっても、確認の通信はプロキシを通さない
- 古いものの整理
  - 自動更新のアーカイブ（`forgejo-auto-*`）は新しい 3 つを残し、手動のバックアップには触れない
  - イメージは、今の版と直前の版以外の `codeberg.org/forgejo/forgejo:<x.y.z>-rootless` を消す。復元の手順 2 は、バックアップの版のイメージが無ければ取得し直す
- 限界
  - 自動の確認（起動・応答・版・doctor）で見つからない不具合は戻さない。気付いたら手動の復元と保留を使う
  - 更新の途中で OS ごと止まったとき（停電など）は、書き換えた定義のまま次の起動を迎えることがある。次の実行は、その版を最新とみなして何もしない
  - 復元の節の手順 5（起動）と手順 7（保留）の間にタイマーが動くと、また更新することがある。4 時台を避けて復元する
- 採らなかったもの
  - 新しい版が出てから数日待つ・1 回に上げるメジャー版を 1 つに限る: 「常に最新版を使う」と食い違うため
  - 失敗の通知（メールなど）: 宛先の設定が要るため。`systemctl --user` の結果と journal で確かめる

### バックアップ・バックアップから復元する・更新

- SQLite の DB・リポジトリ・添付などは同じ時点にそろえる必要がある。単純なファイルコピーをする本書では Forgejo を停止してディレクトリ全体を保存する
- 設定と SSH のホスト鍵も保存するため、復元後は同じアカウントと指紋を使える。Quadlet も保存し、その時点のイメージ版・パス・URL・待ち受けへ戻す
- `forgejo dump` などで稼働中の状態を集める方法は本書の経路には入れない。外部 DB や S3、Redis などを追加した構成では、それらのバックアップも同じ時点へそろえる必要がある
- 復元は空の作業場所へ展開してから、停止中のデータ全体と入れ替える。元のデータは退避し、既存 DB と復元 DB のファイルを混ぜない
- DB の移行を伴う更新後に、旧イメージだけを起動しても元へは戻らない。旧イメージの定義と更新前データをセットで復元する。更新後に受け付けた操作は、更新前バックアップには含まれない
- 初回作成用の上書きガードと、更新用の置き換えは用途が異なる。既存の導入へ実施手順の「イメージを取得して localhost で起動する」の手順 3 を再実行するのではなく、後ろの更新・復元の節を使う
- 自動更新のアーカイブも、手動のバックアップと同じ中身なので、復元の節でそのまま使える

## 参照

- [Forgejo 16.x releases](https://forgejo.org/releases/16.x/) — 通常系列の最新安定版とサポート期限
- [Forgejo releases](https://forgejo.org/releases/) — 新しい通常系列を含むリリース一覧
- [Forgejo release schedule](https://forgejo.org/docs/latest/admin/release-schedule/) — 通常版の更新・期限
- [Installation with Docker（v16）](https://forgejo.org/docs/v16.0/admin/installation/docker/) — 公式イメージ、Podman の Quadlet 例、rootless イメージのパスと内部 SSH、環境変数
- [Forgejo v16.0 is available](https://forgejo.org/2026-07-release-v16-0/) — コンテナの信頼するプロキシの既定変更と主要な変更
- [Forgejo v15.0 is available](https://forgejo.org/2026-04-release-v15-0/) — rootless イメージの旧設定パスの互換処理撤去
- [Configuration Cheat Sheet（v16）](https://forgejo.org/docs/v16.0/admin/config-cheat-sheet/) — URL・ポート・初期設定ロック・自己登録・ログイン前の閲覧・DB
- [Database Preparation（v16）](https://forgejo.org/docs/v16.0/admin/installation/database-preparation/) — SQLite と対応する外部 DB
- [Recommended Settings and Tips（v16）](https://forgejo.org/docs/v16.0/admin/setup/recommendations/) — 負荷に応じた DB の選択
- [Installation from binary（v16）](https://forgejo.org/docs/v16.0/admin/installation/binary/) — 初期設定画面と管理者作成
- [Upgrade guide（v16）](https://forgejo.org/docs/v16.0/admin/upgrade/) — 停止を含む整合したバックアップ、更新と診断
- [Forgejo API（Codeberg の swagger）](https://codeberg.org/api/swagger) — リリースの一覧（`draft`・`pre-release`・`limit`）
- [systemd.timer](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html) — `OnCalendar`・`RandomizedDelaySec`・`Persistent`
- [podman-systemd.unit](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html) — rootless Quadlet の配置・ユーザー名前空間・生成 unit の自動起動
- [podman run](https://docs.podman.io/en/latest/markdown/podman-run.1.html) — `--userns=keep-id`、`--user`、bind mount の所有者と SELinux の `:Z`
- [firewalld rich language](https://firewalld.org/documentation/man-pages/firewalld.richlanguage.html) — 送信元・宛先・ポート・priority と許可の規則
- [Netavark / firewalld の相互作用](https://github.com/containers/netavark/blob/main/docs/netavark-firewalld.7.md) — rootful の転送経路と rootless との違い
- [Podman](../podman.md)・[linger](../linger.md)・[Git](../git.md) — 本書の前提

---
