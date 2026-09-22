# setup-notes

実機で検証した構築・設定手順の記録。

「動いた手順」だけでなく、**なぜ失敗したか・どう切り分けたか**も残すことを重視している。同じ作業を別の環境でやり直すとき、あるいは同じ症状に再び出くわしたときに、調査をやり直さずに済むようにするのが目的。

## 手順書一覧

| ドキュメント | 対象 | 概要 |
|---|---|---|
| [GNOME Remote Desktop 有効化手順](docs/gnome-remote-desktop.md) | AlmaLinux 10.2 (x86_64 / aarch64) / gnome-remote-desktop 49.3 | リモートログイン方式（システムデーモン）の CLI 設定。**冒頭の変数ブロックに値を 1 度書けば、以降のコマンドはそのまま貼れる。前半は実行するコマンドだけで、理由・実測・落とし穴は後半の補足にまとめてある。** openssl による TLS 証明書生成（SAN 付き）、FreeRDP 無しでの TLS 検証、ログイン失敗の原因調査、winpr-makecert との比較を含む |
| [WireGuard VPN 構築手順](docs/wireguard.md) | AlmaLinux 10.2 (aarch64) / wireguard-tools 1.0.20250521 / firewalld 2.4.3 | ルーター配下の WG ホスト同士で 2 拠点の LAN を相互接続し（wg-quick + systemd）、外出先の PC・スマートフォンも任意の台数つないで両拠点の LAN に到達させる。**値を `site.env` に 1 度書けば、`wg-vpn.sh` の `keygen` → `apply` → `router` → `client add` で構築できる**手順書。firewalld は `wg0` を LAN 側ゾーンに入れてゾーン内転送で通す（policy 無し。絞るのは宛先ホスト側。旧レイアウトからは `apply` が自動で移行）、ルーター側の要件（ポート転送・静的経路・ヘアピン）、reload と引用符の落とし穴を含む。network namespace で両拠点とクライアントの疎通まで確認。スクリプトは [`scripts/wireguard/`](scripts/wireguard/)（既存 conf の流用可）。**OS をクリーンインストールしても同じ鍵で復旧できる**バックアップ・復旧手順も収録 |
| [WezTerm Nightly インストール手順](docs/wezterm-nightly.md) | AlmaLinux 10.2 (x86_64) / dnf-plugins-core 4.7.0 / WezTerm nightly (COPR `rhel-9` ビルド) | 公式 COPR `wezfurlong/wezterm-nightly` に EL10 向けが無いので、**chroot を `rhel-9-<arch>` と明示して有効化し、EL9 向けビルドを `dnf install wezterm` で入れる**。EL9 ビルドが EL10 で依存解決できる根拠、chroot 未指定時のエラー、GitHub rpm / AppImage / Flathub / ソースビルドを選ばなかった理由、AppImage の glibc 要件の実測、設定ファイルの置き場所と探索順序の実測（公式の図と `~/.wezterm.lua` の優先度が逆）を含む。Wayland セッションでの起動確認まで実施 |
| [Samba でホームディレクトリを公開する手順](docs/samba.md) | AlmaLinux 10.2 (aarch64) / samba 4.23.5 / firewalld 2.4.3 | ローカルユーザーが自分のホームディレクトリに LAN と WireGuard 越しの両方から SMB3 で読み書きできるようにする。`[homes]` だけの最小 `smb.conf`（印刷・NetBIOS 無し、445/tcp のみ）、SELinux boolean 1 つ、firewalld は public ゾーンに 445/tcp。**冒頭の変数ブロックに値を 1 度書けば、以降のコマンドはそのまま貼れる。** サーバー自身からの `smbclient` / `mount.cifs` と network namespace から firewalld 越しの到達を検証済み。SELinux boolean 無しの失敗の署名（AVC が出ない）、`create mask` 無しで x ビットが付く実測、`smbpasswd` の TTY の挙動を含む。実クライアントからの接続は未検証 |
| [WireGuard Road Warrior 設定手順](docs/wireguard-road-warrior.md) | AlmaLinux 10.2 / NetworkManager 1.56.0 / wireguard-tools 1.0.20250521 | [WireGuard VPN 構築手順](docs/wireguard.md)で建てた拠点の WG ホストに、外出先の AlmaLinux 10 ノート PC から接続する側の手順。鍵は PC で作って公開鍵だけをホストに `client add --pubkey` で登録し、ホストが出す conf を **`nmcli connection import type wireguard` で NetworkManager のプロファイルにして `nmcli connection up` / `down` で張る・切る**（wg-quick は補足の代替）。スプリットトンネル（両拠点の LAN だけ）、autoconnect 無効、拠点の LAN 内では切る運用。**冒頭の変数ブロックに値を 1 度書けば、以降のコマンドはそのまま貼れる。** **2026-09-22 に実機で本実行**（拠点 A の LAN にある PC をテザリング回線へ移してから拠点 B に接続し、両拠点の LAN への ping・トンネル越しの ssh・逆方向の ping まで確認）。NetworkManager の挙動（import 直後の自動接続、経路の metric 50、MTU 1420、既定ゾーン、resolv.conf）を実測で確定させた付録付き |

## 記法の約束

- **環境固有の値はシェル変数で書き、手順書の冒頭で 1 度だけ設定する。** 本文のコマンドは `${SERVER_IP}` / `${SITE_A_LAN}` の形で参照し、値を書き換えずにそのまま貼れるようにする。各ドキュメントの冒頭に変数の対応表を置く
- **値の置き場所は手順書ごとに 1 か所。** GNOME Remote Desktop・WezTerm・Samba は本文冒頭の変数ブロック、WireGuard は `site.env` 1 ファイル。読者が編集するのはそこだけ
- **出力例・ログ・表の中の値はプレースホルダで書く。** `<HOSTNAME>` / `<HOSTNAME>.<DOMAIN>` / `<SERVER_IP>` / `<USER>` など。実測出力は変数に置き換えない
- **`<...>` プレースホルダを含むコマンドは bash のコードブロックに置かない。** インラインコードか説明文で示す。読者が値を入れるコードブロックは値を変数にし、先頭で `${VAR:?メッセージ}` か `if [ -z "${VAR}" ]` を使って、空のまま貼っても（機械的に実行されても）何も変更しないようにする。ロールバック節の `<旧ファイル>` がそのまま `grdctl --system rdp set-tls-cert` に渡って設定を壊し、次の再起動で RDP が起動しなくなった実例がある
- **検証した環境のバージョンを明記する。** ディストリビューション、対象パッケージ、関連ツールのバージョンを冒頭に書く
- **コマンドは実際に実行したものを載せる。** 出力やログも、切り分けの根拠になるものは引用する
- **構成図は nwdiag のソースから生成する。** `docs/diagrams/*.diag` が原本で、同名の `*.svg` は生成物。図を直すときはソースを直して `python3 scripts/render-diagrams.py` で作り直す（前提は手順書の[付録](docs/wireguard.md#付録-構成図の再生成)）
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
- **firewalld 2.4 同梱の `gateway-lan-to-world` などの policy は `<disable/>` 付きで既定では無効** — `internal` / `home` / `trusted` から `public` / `external` への転送を ACCEPT する policy だが、`--get-policies` には出ても `--get-active-policies` には出ない。有効化した環境でトンネルのインターフェースをこれらのゾーンに入れると意図せず転送が通るので、LAN 側ゾーンがそれらなら `--get-active-policies` で確認する
- **待ち受けポートの開け忘れは、自拠点から張ると気づかない** — 自分から送ったハンドシェイクへの応答は conntrack で通る。相手側から張り直すときに初めて失敗する
- **WG ホスト自身から相手 LAN へは、送信元がトンネル IP になる** — 相手 LAN がトンネル網への経路を知らないと応答が戻らない。クライアント同士の通信は問題ないため、見落としやすい
- **ルーター配下に置いた VPN ホストはヘアピン（非対称経路）になる** — Linux ルーターでは ICMP Redirect の有無にかかわらず通ったが、状態追跡をするルーターでは TCP が切られる可能性がある
- **`firewall-cmd --add-rich-rule` に変数を使うなら二重引用符にする** — 解説の多くは単一引用符で書いているが、それだと `${VAR}` が展開されず、`$MY_LAN` という文字列がそのまま rich rule に登録される。**firewalld はそれを `success` で受理する**ので、`--info-policy` を見るまで気づかない
- **A/B 対称な構成は「自分視点」の派生変数に畳める** — 両拠点の値を 1 ファイルに持ち、自ホストの IP からどちらの拠点かを判定して `MY_*` / `PEER_*` を組み立てれば、手順のコマンドが両拠点で完全に同じになる。拠点ごとの書き分けが消え、A/B の取り違えも構造的に起きなくなる
- **`firewall-cmd --get-zone-of-interface` はゾーン未割り当てのとき `no zone` を stderr に出して 2 を返す** — stdout を `"no zone"` と比較する書き方では検出できず、変数が空のまま次のコマンドに渡る。終了コードで判定して既定ゾーンに落とす
- **firewalld 2.4.3 に `--query-policy` は無い** — `--query-service` などがあるので類推で書くと `unrecognized arguments` で終了コード 2 になり、「存在しない」と誤判定してロールバックが丸ごと空振りする。存在確認は `--info-policy` の終了コードか `--get-policies` の一覧で行う（旧レイアウトの自動削除で `apply` / `remove` がこの判定を使う）
- **policy はゾーンより先に削除する** — 参照されているゾーンを先に消すと、`--reload` が `INVALID_ZONE: Policy '…': 'wireguard' not among existing zones` で失敗し、firewalld の設定が壊れた状態になる（旧レイアウトの自動削除で `apply` / `remove` がこの順序を守る）
- **`AllowedIPs` は 1 インターフェース内で peer ごとに排他** — 1 つのアドレスを 2 つの peer に対応づけられない（cryptokey routing）。クライアントは拠点に所属させ、拠点ごとに帯を分ければ、相手拠点のホストには「その帯は拠点 peer の向こう」と 1 行書くだけで済み、クライアントを増やしても相手拠点の設定は変わらない
- **相手拠点のホストの `AllowedIPs` にクライアント帯が無いと、黙って捨てられる** — WireGuard は送信元が `AllowedIPs` 外のパケットを ICMP なしで捨てる。ハンドシェイクも転送も正常に見えたまま届かない
- **登録簿から conf を作り直す仕組みでは、登録簿に無い `[Peer]` が黙って消える** — 手で組んだ conf から移行するとき、最初の `client add` が登録簿を新規作成し、続く `apply` が手書きの peer をまとめて落とす。peer を失った端末はハンドシェイクから成立しなくなるので、拠点 LAN どころか VPN ホスト自身にも届かない（切り分けではクライアント側の表示より、ホストの `wg show` と待ち受けポートの `tcpdump` が早い）。「登録簿が唯一の真実」にするなら、それ以外の peer を見つけた時点で止める検査を入れる
- **NAT しない構成では、ルーターにクライアント帯の静的経路も要る** — LAN 側ホストの返事はデフォルトゲートウェイに向かう。相手拠点のルーターにも要る。トンネル網とクライアント帯を 1 つの大きな帯に取っておけば、静的経路は 1 本で済む
- **firewalld の policy は ingress と egress に同じゾーンを指定でき、実際に効く** — `wg0` から入って `wg0` へ折り返す転送（クライアント → 相手拠点 LAN）を rich rule で絞れる。ゾーンの `forward` オプションだと `wg0` 内の転送がすべて通る（ゾーン内の全 interface に `oifname <iface> accept` が入る）。network namespace のラボで、その policy を外すと折り返しだけが `Packet filtered` になることを確認した（2.4.3）。**現在はその「すべて通る」側を採用**し、絞るのは宛先ホストに任せた
- **VPN ホストで転送を絞らないと決めると、firewalld は port・interface・forward の 3 コマンドで済む** — `wg0` を LAN 側 NIC と同じゾーンに入れるだけで、policy は 1 つも要らず、ホスト自身宛ての ssh / cockpit も LAN と同じ扱いになる。専用ゾーン + 8 policy の構成は「WG ホストで絞る」という前提から来ていた。旧レイアウトが残っていても、policy → ゾーンの順に消してから入れ直せば 1 回の reload で移行できる
- **VPN ホストの再構築で本当に要るのは「鍵 1 本と値のファイル」だけ** — 秘密鍵さえ同じなら、相手拠点の設定も、配布済みのクライアント conf も、ルーターのポート転送・静的経路も**一切変更せずに**戻せる。鍵は「拠点の身元」そのもので、経路や NAT の設定とは無関係だから。逆に鍵を作り直すと、相手拠点の公開鍵差し替えと全クライアントの conf 再発行が連鎖する。conf・sysctl・firewalld は手順で作り直せるので、退避すべきは鍵・`site.env`・クライアント登録簿の 3 つに絞れる
- **`sudo` で復元したファイルの所有者に注意** — `sudo` 下の `~` は `/root` を指し、root で置いたファイルは `root:root` になる。非 root でも読むファイル（このリポジトリでは `site.env` と `clients.list`）は、**置き先ディレクトリの所有者**に合わせ直す必要がある。「既にある同名ファイルの所有者を引き継ぐ」実装にすると、一度 root 所有で置かれたものが直らなくなる。書き込み自体は成功するので、後から「非 root で読めない」と気づく
- **`/tmp` 経由で持ち込んだファイルは SELinux のコンテキストを持ち越す** — `mv` ではなく `install`（新規作成）で置き、`restorecon` をかける。同じディレクトリ内の `mktemp` → `mv` なら型変換が効くので問題ない
- **退避ファイルは `.gitignore` の既存パターンから漏れる** — `site.env` を除外していても `site.env.bak-20260919-212000` は一致しない。`.bak-日時` を作る仕組みを入れるなら、除外パターンも同時に足す
- **クライアント conf の `AllowedIPs` にはトンネル網も入れる** — WG ホスト自身がクライアントに送るパケットの送信元は `wg0` のアドレスになる。無いとクライアント側で捨てられる

### [WezTerm Nightly](docs/wezterm-nightly.md)

- **COPR に自分の EL メジャーの chroot が無くても、`dnf copr enable <owner>/<project> <chroot>` で他の chroot を指せる** — 省略時は `/etc/os-release` から `epel-<major>-<arch>` を推定するので、EL10 では「Repository 'epel-10-x86_64' does not exist」で止まる。エラーに候補一覧が出るので、そこから `rhel-9-x86_64` を選ぶ。生成される repo ファイルは `baseurl` の chroot が違うだけで手直し不要だった
- **EL9 向けバイナリは EL10 でそのまま動くことが多い** — glibc 2.34 → 2.39、OpenSSL は `libssl.so.3` の soname が同じで `OPENSSL_3.0.0` のシンボルバージョンも提供されている。入れる前に `dnf install --assumeno --repofrompath=<name>,<url> <pkg>` で依存解決だけ試せば、何も変えずに可否がわかる
- **`dnf repoquery --requires` は同名 SRPM の BuildRequires も混ぜて表示する** — メタパッケージに `gcc` / `*-devel` が要るように見えて驚くが、`--assumeno` のトランザクション表を見れば実際に入るものがわかる
- **AppImage は「ビルド元ディストリの glibc 以上」を要求する** — `Ubuntu26.04` 版は `GLIBC_2.42 not found` で EL10（2.39）では起動しない。EL で使うなら glibc が同じか古い Ubuntu 版を選ぶ。ファイル名の Ubuntu バージョンが実質的な最低 glibc 要件
- **WezTerm は `~/.wezterm.lua` を `~/.config/wezterm/wezterm.lua` より先に読む** — 公式ドキュメントのフロー図は逆順に見えるが、`main` のコードは `~/.wezterm.lua` を候補の先頭に置く。読まれるのは最初に見つかった 1 つだけなので、両方あると `.config` 側の変更が効かない。どのファイルを読んだかは `strace -f -o /tmp/st wezterm ls-fonts` で `openat(... wezterm.lua) = 3` を探すと確実。一時ディレクトリを `HOME` にすれば実際のホームを汚さずに試せる
- **ディスプレイの無いシェルから GUI アプリの起動試験ができる** — `env -i` で環境を空にし、ログイン中の GNOME セッションの `WAYLAND_DISPLAY` / `XDG_RUNTIME_DIR`（`/proc/<gnome-shell の pid>/environ` から取れる）を渡して、子プロセスが即終了するコマンドで起動する。`timeout` を付けておけばウィンドウが残っても戻ってくる

### [Samba](docs/samba.md)

- **`samba_enable_home_dirs` が off のときの拒否は監査ログに出ない** — 認証は通り `smbclient -L` の一覧にも出るのに、`ls` だけが `NT_STATUS_ACCESS_DENIED listing \*` になる。`ausearch -m AVC` は `<no matches>`（dontaudit）なので、SELinux を疑う根拠がログに無い。boolean を on にすれば smbd の再起動なしで直後から通る
- **SMB 経由で作ったファイルには owner の x ビットが付く** — 既定の `create mask = 0744` と `map archive = Yes` の組み合わせで、DOS の archive 属性が owner の x に写る。`smbclient` の `put` でも `mount.cifs` 上の `touch` でも `-rwxr--r--` になった。`[homes]` に `create mask = 0644` を書く
- **`smbpasswd` は TTY が無いと exit 1 で止まる** — `grdctl` と違って黙って成功扱いにはならない（`Unable to get new password.`）。非対話で登録するなら `-s` で stdin から 2 行渡す。Samba ユーザーの追加・削除・パスワード変更は smbd の再起動なしで次の接続から効く
- **`testparm -s` は既定と同じ値を表示しない** — `workgroup = WORKGROUP` や `read only = No` を書いても出力に現れない。書き漏れかどうかは `testparm -sv` で見る。存在しないファイルの `include` も警告なしに通る
- **自ホストからの接続は firewalld を通らない** — `filter_INPUT` の `iifname "lo" accept` が先に効くため、`smbclient //localhost/` はもちろん `//<自分の LAN IP>/` でも 445 の開け忘れを検出できない。veth で結んだ network namespace（ゾーン未割り当ての veth は既定ゾーン扱い）から接続すると、閉じているときは `NT_STATUS_HOST_UNREACHABLE` になって区別がつく
- **`smbstatus` で交渉されたプロトコル・暗号化・署名がサーバー側から分かる** — `mount.cifs` の既定は SMB 3.1.1、署名は `partial(AES-128-CMAC)`、暗号化は `-`（LAN 上は平文）。クライアント側では見えにくい
- **`server smb transports = tcp` で 139 を listen しなくなる** — nmbd を起動せず firewalld も 445/tcp だけで済む。4.23 では `smb ports` はこの同義語。`smb.service` は `nmb.service` を `Wants` していないので単独で動く
- **`NT_STATUS_ACCESS_DENIED` は出る段階で原因が分かる** — `tree connect failed:` なら `valid users` で弾かれた（他人のホーム）、`listing \*` なら共有には入れたがファイルシステムで拒否された（SELinux）。`NT_STATUS_LOGON_FAILURE` はユーザー名違いもパスワード違いも同じ

### [WireGuard Road Warrior](docs/wireguard-road-warrior.md)

- **`nmcli connection import` は取り込んだ瞬間にトンネルを張る** — `connection.autoconnect` の既定が `yes` で、それを抑える `import` のオプションは無い。スプリットトンネルの `AllowedIPs` に**今いる LAN** が含まれていると、NetworkManager が入れる metric 50 の経路が Wi-Fi の直結経路（metric 600）に勝ち、デフォルトゲートウェイごと見えなくなってトンネル自身も死ぬ。「トンネルを張るのは LAN の外で」という注意は `up` ではなく **`import` の時点から**効く
- **VPN の設定を反映する restart は、その VPN 越しに入っている作業セッションを切る** — トンネル越しに ssh して設定コマンドを流すときは、`systemd-run --unit=… -p Type=oneshot` などで切り離し、結果は `journalctl` で読む。このとき **0700 のホーム配下のスクリプトを `systemd-run` に直接渡すと `203/EXEC`（`Permission denied`）で失敗する**。`/bin/bash <script>` を挟めば通る。SELinux の AVC は出ないので、ラベルの問題と誤診しやすい
- **NetworkManager のプロファイルに入れた秘密鍵は、ローカルにログイン中の非 root ユーザーが読める** — keyfile が `root:root` の 0600 でも、polkit の既定が `allow_active=yes` なので `nmcli -s -g wireguard.private-key connection show wg0` が通る。鍵の守りは実質 PC のログインパスワード
- **クライアント側で鍵を作ると、ホストへ渡すものから秘密が消える** — `client add --pubkey` で登録すれば、ホストが出すクライアント用 conf の `PrivateKey` はプレースホルダのまま。受け渡し経路を選ばなくてよく、ホストにクライアントの秘密鍵が残らないので消し忘れも起きない。クライアント側は conf の 1 行を `sed` で差し替えるだけで済む
