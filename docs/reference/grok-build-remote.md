# Grok Build をブラウザから操作する手順（Codeg と Caddy / AlmaLinux 10 は systemd のユーザーサービス / Windows 11 はタスク スケジューラ / LAN・VPN 内で HTTPS で使う）の参考資料

[手順書](../grok-build-remote.md)・[ロールバックと注意点](../extra/grok-build-remote.md)・[検証記録](../verification/grok-build-remote.md)

## 補足

### 実施手順 / Codeg のサーバーを入れて localhost で起動する / 手順 1: 補足: 変数

- `SERVER_IP` は、Caddy が待ち受ける IP と、firewalld の規則の宛先の両方に使う。Codeg は `127.0.0.1` のまま
- `ALLOW_FROM` は送信元 IPv4 の CIDR。空白で区切って複数を並べられ、1 つにつき規則を 1 本作る。WG ホスト自身で動かすときは、VPN のクライアントの通信が `wg0` から入り、送信元はクライアントの VPN のアドレスになる
- ポートは、Codeg が既定の 3080（ホストの中だけ）、Caddy が 3443（外から届く口）。どちらも変数にしていない
- `FW_ZONE` は自動で入る

### 実施手順 / Codeg のサーバーを入れて localhost で起動する / 手順 3: 補足: SHA-256 の照合

- `.sha256` は、配布物と同じリリースに置かれたファイル。取得の途中で壊れたものは見つけられるが、リリースそのものが書き換えられた場合は見つけられない
- GitHub のリリースの画面と API は、配布物ごとの digest（`sha256:…`）を出す。検証では、その値とも一致することを確かめた
- リリースには `.sig`（署名）もある。検証のしかたは公式の文書に無く、本書では使っていない
- 公式のインストーラー（`install.ps1`）は、SHA-256 を照合しない（スクリプトを読んで確かめた）。`install.sh` は読んでいない
- `tar -tzf` が成功したときだけ一覧を変数に入れ、`awk` で展開先を外れるパス（`/` で始まるもの、`..` を含むもの）の数を出す。一覧を読めなかった場合は `0` を出さずに中断する。数が `0` なら成功、それ以外なら終了コードも非 0 にする

### 実施手順 / Codeg のサーバーを入れて localhost で起動する / 手順 4: 補足: 置き場所

- 公式のインストーラーは、実行ファイルを `/usr/local/bin`、画面のファイルを `/usr/local/share/codeg/web` に置く。本書は `sudo` を使わず、ホームの `~/.local/opt/codeg-server` にまとめる
- `codeg-mcp` は、`codeg-server` と同じディレクトリに置く（Codeg は既定で隣を探す。`CODEG_MCP_BIN` で変えられる）
- `codeg-computer-helper` は、サーバーのデスクトップを操作させる機能（`CODEG_COMPUTER_USE`）の部品。その機能を使わないので置かない

### 実施手順 / Codeg のサーバーを入れて localhost で起動する / 手順 6: 補足: ユニットの各行

- `EnvironmentFile` は必須にしてある（`-` を付けない）。トークンのファイルが無ければ起動に失敗し、Codeg がトークンを自分で作ることは無い
- `Environment=PATH=` は、`~/.grok/bin` を足すため。systemd のユーザーの環境の PATH は `/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin` で、`grok` が見つからない
- `CODEG_BRIDGE_PORTS=off` は、プロジェクトの開発サーバーを中継するための追加のポート（既定は 3081〜3090）を開けない設定
- `CODEG_BROWSER_TUNNEL=off` は、Codeg のデスクトップアプリをつないだときに、そのアプリの内蔵ブラウザがサーバー経由で届く範囲を無くす設定（既定は `all`）
- `--supervise` は、画面から Codeg を入れ替えたときに、起動に失敗した版を前の版へ戻す仕組み（公式の文書）。本書の更新は画面を使わないが、公式の起動のしかたに合わせた
- `StandardError=null` は、起動のたびに標準エラーへ出るトークンを journal に残さないため。Codeg のログは、別に `~/.local/share/codeg/logs/` に出る
- `Restart=on-failure` と `RestartSec=5` は、異常終了したときに起動し直すため。Caddy のユニットにも同じ設定を置き、起動の時点で `SERVER_IP` がまだ付いていないときも、待ってやり直す

### 実施手順 / Codeg のサーバーを入れて localhost で起動する / 手順 7: 補足: トークンを引数に書かない

- `curl -K -` は、設定を標準入力から読む。`printf` は bash の組み込みなので、トークンがどのプロセスの引数にもならない
- `grep -cFf <(…)` は、探す文字列をファイル（プロセス置換）から読む

### 実施手順 / ブラウザで開いて Grok を動かす / 手順 4: 補足: 権限モードと config.toml の値

- Codeg の「権限モード」を保存すると、`~/.grok/config.toml` の `[ui]` の `permission_mode` が書き換わる。ほかの行は変わらなかった
- 「毎回確認」は `"default"`、「常に許可」は `"bypassPermissions"` と書かれた。Grok Build の文書では、`"always-approve"` と `"bypassPermissions"` は同じモード
- Codeg は、「常に許可」のとき `--permission-mode bypassPermissions` を付けて Grok Build を起動し、「毎回確認」のときは付けなかった
- Grok Build の文書では、既定（ask）で確認なしに動くのは、読み取り専用のツールと、決まった読み取り専用のコマンドだけ。`mkdir` はその一覧に無いが、検証では確認なしで実行された

### 実施手順 / ブラウザで開いて Grok を動かす / 手順 5: 補足: 最初の会話のモデル

- Codeg を起動して最初の会話は、モデルの欄が Grok 4.6 で、Grok Build のセッションの記録（`events.jsonl`）の `modelId` も `grok-4.6` だった。同じ時点の `grok models` の既定は `grok-4.7`
- Codeg の Issue に、Grok の ACP の接続で、後から届くモデルの一覧が反映されない不具合の報告がある（#876。2026-10-02 に閉じられている）。同じ原因かは確かめていない

### 実施手順 / HTTPS で LAN・VPN に公開する / 手順 1: 補足: Caddy の入手

- Caddy は、Codeg と同じく、GitHub の配布物を版を決めて取得し、ホームに置く。チェックサムの一覧（`caddy_<版>_checksums.txt`）は SHA-512
- GitHub のリリースが出す digest（`sha256:…`）とも一致することを、検証で確かめた
- EPEL・Homebrew・scoop にも Caddy はある。置き場所を固定するために使っていない（scoop は版ごとにディレクトリが変わり、Windows の受信の規則をプログラムに限れなくなる）
- 配布物の `caddy` は、ほかのライブラリを要らない 1 つの実行ファイル

### 実施手順 / HTTPS で LAN・VPN に公開する / 手順 2: 補足: Caddyfile の各行

- `admin off` は、Caddy の管理用の API（既定は `localhost:2019`）を開けない設定。設定を変えたら、サービスを起動し直す
- `auto_https disable_redirects` は、HTTP から HTTPS へ送るための 80 番の待ち受けを作らない設定
- `skip_install_trust` は、ルート証明書を OS の信頼の置き場へ自動で入れさせない設定（入れるには `sudo` や管理者の権限が要る）。端末には、手で入れる
- `pki` の `name` は、認証局の名前。ルート証明書の名前が `<名前> - <年> ECC Root` になる。既定の名前のままだと、2 台のホストのルート証明書が、端末の一覧で見分けられない
- `bind` は、待ち受ける IP を 1 つに絞る。`tls internal` は、Caddy の認証局で証明書を作る指定。IP アドレス宛ての証明書になる
- `handle /caddy-root.crt` は、ルート証明書（公開してよいもの）を配る口。`{$HOME}`・`{$APPDATA}` は、Caddyfile の解析より前に環境変数で置き換える。パス全体を二重引用符で囲み、空白を含むホームでも 1 つのパスとして扱う
- `reverse_proxy 127.0.0.1:3080` で、そのほかの通信を Codeg へ渡す。WebSocket も通る
- 字下げは、空白でもタブでもよい

### 実施手順 / HTTPS で LAN・VPN に公開する / 手順 3・4: 補足: 待ち受けと規則

- Codeg は `127.0.0.1` のままにする。暗号化されない HTTP は、ホストの外に出ない
- 規則は、[Forgejo](../forgejo.md) と同じ形（送信元・宛先・ポートを絞った rich rule）。zone の既定の拒否はそのままで、指定した送信元だけを通す
- サーバー自身から `SERVER_IP` へつなぐ通信は、firewalld の規則にかからない
- `curl` の終了コード 60 は、相手の証明書を検証できなかったことを示す

### 端末にルート証明書を入れる / 手順 3〜5: 補足: 指紋の照合

- ルート証明書は、まだ信頼していない相手から取る（Android は警告を進み、Windows は `curl -k`）。途中で差し替えられていないことは、ホストに出した指紋と比べて確かめる
- Android は、取り込む画面に指紋が出ないので、取り込んだ後に「信頼できる認証情報」で確かめる。違っていたら、すぐに削除する
- 共同レビューでは、PC で照合したファイルを USB で Android に渡す形（取り込む前に照合できる）も挙がった。利用者の指定で、ブラウザで取得する形にしている
- Windows の取り込み先は `Cert:\CurrentUser\Root`。このユーザーが使う Edge・Chrome が信じる。Firefox は、設定によっては自分の置き場だけを使う（確かめていない）

### Windows 11 で使う / Windows 11 で Codeg のサーバーを入れて起動する / 手順 6・7: 補足: スクリプトとタスク

- 環境変数を利用者の環境（レジストリ）に入れると、すべてのプロセスにトークンが渡る。起動用のスクリプトの中だけで設定する
- スクリプトは ASCII で書く。Windows PowerShell 5.1 は、BOM の無いスクリプトを既定のコードページで読む
- タスクは、管理者ではない窓から、ログオン時のトリガー付きで登録できた。`-RunLevel Limited` で、Codeg はデスクトップのセッションの、管理者ではない権限で動く
- `-WindowStyle Hidden` で、窓を隠して起動する。標準エラーに出るトークンは、ファイルにも journal にも残らない

### Windows 11 で使う / Windows 11 で HTTPS で LAN・VPN に公開する / 手順 2: 補足: 待ち受ける IP を決めない設定

- サイトのアドレスを `https://:3443` にして `bind` を書かないと、Caddy は、すべてのアドレスの 3443 番で待ち受ける
- `tls internal` の `on_demand` は、TLS の接続が来たときに、その宛先の証明書を作る指定。IP アドレスで開いた接続は名前（SNI）を持たず、Caddy は、接続を受けたローカルの IP 宛ての証明書を作った
- 認証局は変わらない。端末のルート証明書は、PC の IP が変わっても入れ直さない
- Caddy は、起動のときに `on-demand TLS is enabled, but no protections are in place` の警告を出す。証明書を作ってよい名前を尋ねる先（`ask`）を置いていないため。本書では、受信の規則で送信元を絞ることで抑える
- AlmaLinux 10 のサーバーは IP が固定なので、IP 宛てのサイトと `bind` のままにしてある

### Windows 11 で使う / Windows 11 で HTTPS で LAN・VPN に公開する / 手順 3・4: 補足: 規則とタスク

- `-Program` で `caddy.exe` 宛てに限る。同じ PC のほかのプログラムが 3443 番で待ち受けても、この規則では通らない
- `-Profile Private` と `-InterfaceType Wired` で、プライベートにした有線 LAN から届く通信だけを通す。PC の IP が変わるので、`-LocalAddress` は付けない
- `Block` の 2 本は、パブリック・ドメインのネットワークと、プライベートの Wi-Fi を、`caddy.exe` 宛てに遮断する。Windows のファイアウォールでは、遮断の規則が許可の規則より優先する
- どのネットワークにいても `caddy.exe` 宛ての規則がある状態にして、Caddy が待ち受けを始めたときに Windows が許可を尋ねる画面を出さないようにする狙いもある（パブリックのネットワークで Caddy を起動しての確認は、していない）
- Wi-Fi からも使うなら、`codeg-caddy-block-wifi` を作らず、`codeg-caddy-in` から `-InterfaceType Wired` を外す（確かめていない）
- VPN のクライアントの通信は、WG ホストが LAN へ転送する。PC から見た送信元は、クライアントの VPN のアドレスだった
- Caddy のタスクも、Codeg と同じく、サインイン中に管理者ではない権限で動かす。`curl.exe` の `--ssl-no-revoke` は、失効の確認ができない自前の認証局のために付ける
- Caddy の起動コマンドへ入れるパスは、単引用符を 2 つに置き換える。ユーザーのパスに `'` があっても、PowerShell の文字列を途中で閉じない
- Caddy の終了コードをタスクへ返す（`exit $LASTEXITCODE`）。タスクの「前回の実行結果」で、Caddy が失敗したことが分かる
- タスク スケジューラの「失敗時の再起動」（`-RestartCount`・`-RestartInterval`）は使わない。終了コード 1 で終わる使い捨てのタスクで試すと、再起動されなかった（検証記録）
- 待ち受ける IP を決めないので、サインインの時点で LAN につながっていなくても、Caddy は起動する
- Windows の停止・更新・ロールバックは、配置先が一致する Codeg の PID に `taskkill /T /F` を使う。タスクを止めるより先に子プロセスごと終了し、ほかの ACP クライアントの Grok を巻き込まない

## 方法のまとめ

Grok Build を、離れた場所からデスクトップアプリかブラウザで操作する方法を比べた（2026-10-11 時点）。「この手順書」の列が「採った」のものを、手順書で手順にした。

| 目的 | 方法 | この手順書 | 要るもの・制約 |
|---|---|---|---|
| 画面から Grok Build を動かす | Codeg のサーバー（`codeg-server`）を同じホストに置き、ブラウザで開く | 採った | Apache-2.0。Grok は内蔵の対応エージェント。Linux の x64・arm64 と Windows の x64 の配布物がある。外部のサーバーを通らない。Codeg 自身は TLS を持たない |
| 画面から Grok Build を動かす | Paseo のデーモンを同じホストに置く | 採らない（Codeg が動かなかったときの代わりとして調べた） | Apache-2.0。Grok は ACP のカタログの扱い。Windows で端末のコマンドの引用が壊れる不具合の報告（#5947）がある。実機では試していない |
| 画面から Grok Build を動かす | Grok UI | 採らない | MIT。Grok Build 専用だが、Windows と aarch64 の対応が文書に無い。個人の小規模なプロジェクト |
| 画面から Grok Build を動かす | Happier | 採らない | MIT。Web の画面に HTTPS が必須。プッシュ通知が第三者（Expo）を通る。Grok ではセッションの一覧が使えない |
| 画面から Grok Build を動かす | Zed の外部エージェント（SSH のリモート） | 採らない | PC のデスクトップアプリだけ。スマートフォンから使えない |
| 画面から Grok Build を動かす | Grok Build の `grok agent serve` に直接つなぐ | 採らない | つなぎ方の仕様が公式の文書に無い。公式の例は always-approve 付き |
| 端末をそのまま使う | SSH のアプリと tmux | 採らない（[共同作業の手順書](../coding-agents.md#スマートフォンから指示する)にある） | 画面で扱いたい、という目的に合わない。AlmaLinux 10 だけ |
| 端末をそのまま使う | ttyd などの Web の端末 | 採らない | 端末がそのままブラウザに出る。スマートフォンで Ctrl・Esc・矢印が打ちにくい |
| 端末をそのまま使う | zellij の Web クライアント | 採らない | Windows 版に未解決の不具合がある（[Claude Code の Remote Control（Windows）の検証記録](../verification/windows-claude-remote-control.md)） |
| Codeg の置き方 | 配布物を取得して SHA-256 を照合し、ホームに置く | 採った | 版を決めて入れる。`sudo` を使わない |
| Codeg の置き方 | 公式のインストーラー（`curl … \| bash`・`irm … \| iex`） | 採らない | SHA-256 を照合しない。`/usr/local` に置く（Linux） |
| Codeg の置き方 | 公式の Docker イメージ | 採らない | コンテナの中で動くので、ホストの Grok Build のログイン・Git・道具をそのまま使えない |
| Codeg の置き方（Windows 11） | Codeg のデスクトップアプリの「Web サービス」 | 採らない | すべての NIC で待ち受ける。待ち受ける IP を選べない |
| 常駐（AlmaLinux 10） | systemd のユーザーサービスと linger | 採った | Codeg はユニットを同梱しない |
| 常駐（Windows 11） | タスク スケジューラ（サインイン中、管理者ではない権限） | 採った | SSH のセッションから始めると管理者の権限で動くので、タスクにした |
| つなぐ側 | ブラウザ | 採った | スマートフォンと PC で同じ画面 |
| つなぐ側 | Codeg のデスクトップアプリ（リモートのワークスペース） | 採らない（確かめていない） | Windows の署名が無い。サーバーの `CODEG_BROWSER_TUNNEL` を見直す必要がある |
| つなぐ側 | Codeg の Android のアプリ | 採らない（確かめていない） | Apache-2.0。APK を GitHub から入れる。testing の段階 |
| 経路 | LAN と VPN の、指定した帯だけに開ける | 採った | 送信元を CIDR で絞る（複数を並べられる）。はじめは VPN の帯だけにしていたが、LAN からも使うために広げた |
| 通信の暗号化 | 同じホストの Caddy が HTTPS で受けて、Codeg へ渡す。証明書は Caddy の認証局（`tls internal`） | 採った | Apache-2.0。ドメインも外部のサービスも要らない。端末にルート証明書を入れる |
| 通信の暗号化 | 公的な証明書（Let's Encrypt の DNS-01） | 採らない | 自分のドメインと、DNS 事業者の API トークンが要る |
| 通信の暗号化 | HTTP のまま使う | 採らない（はじめの形） | VPN の区間しか暗号化されない。LAN の区間は、トークンも平文で流れる |
| 通信の暗号化 | ルート証明書を入れず、ブラウザの警告を進んで使う | 採らない | 暗号化はされるが、相手が本物かを確かめられない |
| Caddy の置き方 | GitHub の配布物を SHA-512 で照合して、ホームに置く | 採った | 置き場所が版で変わらない。`sudo` を使わない |
| Caddy の置き方 | EPEL・Homebrew・scoop | 採らない | scoop は版ごとにディレクトリが変わり、Windows の受信の規則をプログラムに限れない |
| 経路 | インターネットへ公開する | 採らない | トークン 1 つが、ホストでコマンドを実行できる鍵になる |

## 選択した方針

- Grok Build には、Claude Code の Remote Control に当たる公式の遠隔操作の画面が無い。Grok Build は ACP（Agent Client Protocol）のエージェントとして動かせる（`grok agent stdio`）ので、ACP で Grok Build を動かす OSS の画面を、Grok Build と同じホストに置く
- 画面は、端末をそのまま映すものではなく、会話・承認・変更されたファイルを扱うチャット形式のものにする（利用者の指定）
- Codeg は、Grok Build 自身のセッションの置き場（`~/.grok/sessions`）を使う。端末の `grok` で始めた会話を取り込めて、Codeg で作った会話は `grok sessions list` に出る
- 既存の Grok Build（`~/.grok/bin/grok`）とログインをそのまま使う。Codeg からは Grok Build を入れ替えない
- まず localhost で起動して確かめ、それから待ち受ける IP と送信元を絞って公開する（[Forgejo](../forgejo.md) と同じ順）
- Windows 11 の PC は、ノート PC を複数の拠点の有線 LAN につなぐ使い方に合わせ、待ち受ける IP を決めない（利用者の指定）。届く範囲は、受信の規則（プライベートのネットワーク・有線・送信元）で絞る
- 外に出す口は HTTPS だけにする（利用者の指定）。Codeg は `127.0.0.1` のままにし、同じホストの Caddy が TLS を受け持つ。証明書は Caddy の認証局で作り、端末にルート証明書を入れて、警告なしで開く
- 認証局は、ホストごとに別にする。鍵は Caddy が作り、エージェントは読まない
- トークンは、エージェントに作らせず・読ませず、利用者が作る。確認は、値を表示しないコマンドで行う
- 承認を自動で通す設定は、離れた場所から使うなら勧めない。ただし、確認が出ることを安全の境界にはしない（`mkdir` は確認なしで実行された）
- 両 OS を 1 本の手順書にまとめ、Windows 11 は後ろの節に置く（[Syncthing](../syncthing.md) と同じ形）

## 参照

- [spacering-net/codeg](https://github.com/spacering-net/codeg)（Codeg。Apache-2.0）
- [Codeg: Supported Agents](https://docs.codeg.app/guide/supported-agents)・[Working with Agents](https://docs.codeg.app/guide/agents)
- [Codeg: Deployment](https://docs.codeg.app/getting-started/deployment)・[Configuration](https://docs.codeg.app/getting-started/configuration)・[Installation](https://docs.codeg.app/getting-started/installation)・[Privacy & Security](https://docs.codeg.app/reference/privacy)
- [Codeg の Issue #436](https://github.com/spacering-net/codeg/issues/436)（Grok の拒否の規則と sandbox が、Codeg の下で効かなかった報告）・[#876](https://github.com/spacering-net/codeg/issues/876)（Grok のモデルの一覧）
- [caddyserver/caddy](https://github.com/caddyserver/caddy)（Caddy。Apache-2.0）・[Caddyfile の `tls`](https://caddyserver.com/docs/caddyfile/directives/tls)・[Caddyfile の全体の設定（`admin`・`auto_https`・`skip_install_trust`・`pki`）](https://caddyserver.com/docs/caddyfile/options)
- [Caddyfile の環境変数と引用](https://caddyserver.com/docs/caddyfile/concepts#environment-variables)・[待ち受ける IP の指定（`bind`）](https://caddyserver.com/docs/caddyfile/directives/bind)・[On-Demand TLS](https://caddyserver.com/docs/automatic-https#on-demand-tls)
- [Microsoft: New-ScheduledTaskSettingsSet](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtasksettingsset)・[taskkill](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/taskkill)（`/T` は子プロセスも止める）・[New-NetFirewallRule](https://learn.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule)（`-Profile`・`-InterfaceType`）
- [xai-org/grok-build](https://github.com/xai-org/grok-build)（Grok Build。Apache-2.0）
- Grok Build の同梱の文書（`~/.grok/docs/user-guide/`）: `15-agent-mode.md`（ACP）・`22-permissions-and-safety.md`（権限モード）
- [Agent Client Protocol](https://agentclientprotocol.com)
- [getpaseo/paseo](https://github.com/getpaseo/paseo)・[joeynyc/Grok-UI](https://github.com/joeynyc/Grok-UI)・[Happier の Grok 対応](https://docs.happier.dev/agents/grok)・[Zed の外部エージェント](https://zed.dev/docs/ai/external-agents)（比べた候補）
