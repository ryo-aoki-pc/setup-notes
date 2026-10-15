# Grok Build をブラウザから操作する手順（Codeg と Caddy / AlmaLinux 10 は systemd のユーザーサービス / Windows 11 はタスク スケジューラ / LAN・VPN 内で HTTPS で使う）の参考資料

[AlmaLinux 10 の手順](../ai-agents.md#grok-build-のブラウザ操作-実施手順)・[Windows 11 の手順](../ai-agents.md#grok-build-のブラウザ操作-windows-11-で使う)・[ロールバックと注意点](../extra/grok-build-remote.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/grok-build-remote.md)

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
- 本書では、対話の承認を減らして使う用途として「スマート自動承認」（`"auto"`）を選ぶ。Grok Build の文書では、自動審査が許可した操作は実行され、許可しない操作は確認へ回るか拒否される。保存した値は端末の `grok` にも反映され、次の会話から効く
- Codeg での保存と、そのモードで新しい会話を動かす確認は分ける。機能を選べない・保存できない・まだ使っていない場合は、対応する確認を未完了として記録する
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
- 規則は、[Forgejo](../forgejo.md#forgejo) と同じ形（送信元・宛先・ポートを絞った rich rule）。zone の既定の拒否はそのままで、指定した送信元だけを通す
- サーバー自身から `SERVER_IP` へつなぐ通信は、firewalld の規則にかからない
- `curl` の終了コード 60 は、相手の証明書を検証できなかったことを示す

### 端末にルート証明書を入れる / 手順 3〜5: 補足: 指紋の照合

- ルート証明書は、まだ信頼していない相手から取る（Android は警告を進み、Windows は `curl -k`）。途中で差し替えられていないことは、ホストに出した指紋と比べて確かめる
- Android は、取り込む画面に指紋が出ないので、取り込んだ後に「信頼できる認証情報」で確かめる。違っていたら、すぐに削除する
- 共同レビューでは、PC で照合したファイルを USB で Android に渡す形（取り込む前に照合できる）も挙がった。利用者の指定で、ブラウザで取得する形にしている
- Windows の取り込み先は `Cert:\CurrentUser\Root`。このユーザーが使う Edge・Chrome が信じる。Firefox は、設定によっては自分の置き場だけを使う（確かめていない）

### 接続元の制限を外す / 手順 1〜4: 補足: 宛先限定の規則

- [AlmaLinux 10 の任意節](../ai-agents.md#grok-build-のブラウザ操作-接続元の制限を外す)は、既存の `ALLOW_FROM` による制限を、宛先 IPv4 と 3443/tcp だけの rich rule へ切り替える。基本の導入手順は送信元を絞ったまま
- runtime と permanent の両方へ新規則を追加してから、証明書を検証した未認証の要求が 401 になることを確かめ、元の送信元付き規則だけを外す。認証の共有値や Codeg・Caddy の待ち受けは変更しない
- 送信元を指定しない規則は、LAN・VPN に属することを判定しない。宛先へ届く経路があれば、ほかのネットワークからも接続の対象になる
- 自ホストの HTTPS 検査は、証明書と認証の検査で、別の端末からの到達確認ではない。別端末からのログインや、不要な経路を公開していないことの確認とは分ける

### Windows 11 で使う / Windows 11 で Codeg のサーバーを入れて起動する / 手順 6〜8: 補足: スクリプトとタスク

- 環境変数を利用者の環境（レジストリ）に入れると、すべてのプロセスにトークンが渡る。起動用のスクリプトの中だけで設定する
- スクリプトは ASCII で書く。Windows PowerShell 5.1 は、BOM の無いスクリプトを既定のコードページで読む
- タスクは、管理者ではない窓から、ログオン時のトリガー付きで登録できた。`-RunLevel Limited` で、Codeg はデスクトップのセッションの、管理者ではない権限で動く
- PowerShell をタスクから直接起動する形では、`-WindowStyle Hidden` を指定していても、このホストで Terminal が開いた
- Windows 標準の .NET Framework の `csc.exe` で、`/target:winexe` のランチャーを作る。タスクはこの実行ファイルを起動する
- ランチャーは `UseShellExecute=false`・`CreateNoWindow=true` で PowerShell を始める。標準出力と標準エラーは読み捨て、Codeg が出すトークンを表示・保存しない
- 子プロセスが終わるまで待ち、その終了コードを返す。ログオンのトリガーと `Limited` の権限は変えない
- コンソールを作らない指定は [ProcessStartInfo.CreateNoWindow](https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.processstartinfo.createnowindow?view=netframework-4.8.1) を使う

### Windows 11 で使う / Windows 11 で HTTPS で LAN・VPN に公開する / 手順 2: 補足: 待ち受ける IP を決めない設定

- サイトのアドレスを `https://:3443` にして `bind` を書かないと、Caddy は、すべてのアドレスの 3443 番で待ち受ける
- `tls internal` の `on_demand` は、TLS の接続が来たときに、その宛先の証明書を作る指定。IP アドレスで開いた接続は名前（SNI）を持たず、Caddy は、接続を受けたローカルの IP 宛ての証明書を作った
- 認証局は変わらない。端末のルート証明書は、PC の IP が変わっても入れ直さない
- Caddy は、起動のときに `on-demand TLS is enabled, but no protections are in place` の警告を出す。証明書を作ってよい名前を尋ねる先（`ask`）を置いていないため。Windows の新構成では送信元を制限せず、受信インターフェースの Private という条件だけで公開するので、その接続へ届く端末は任意の名前の証明書を要求できる
- AlmaLinux 10 のサーバーは IP が固定なので、IP 宛てのサイトと `bind` のままにしてある

### Windows 11 で使う / Windows 11 で Codeg のサーバーを入れて起動する / 手順 1: 補足: MSIX からの配置

- MSIX のパッケージは、AppData への書き込みを、パッケージ専用の `LocalCache` へ転送することがある。パッケージ内では元のパスに見えても、通常の Windows のプロセスからは見えない
- 今回の Codex からの配置はこの形になった。通常の AppData の `Get-Item` の結果だけでは、タスクが起動する本体の存在を確認できなかった。既知のファイルの実体パスと、システム側の `CIM_DataFile` の存在確認で区別した（実測は検証記録）
- 手順書は、スタートメニューから開いた Windows PowerShell で行う形にしてある。Grok Build を動かすタスクは、通常の AppData にあるランチャーとスクリプトを使う

### Windows 11 で使う / Windows 11 で HTTPS で LAN・VPN に公開する / 手順 3・4: 補足: 規則とタスク

- `-Program` で `caddy.exe` 宛てに限る。同じ PC のほかのプログラムが 3443 番で待ち受けても、この規則では通らない
- `-Profile Private`・`-RemoteAddress Any`・`-InterfaceType Any` で、ホスト側の受信インターフェースが Private なら、IPv4・IPv6 の全送信元、有線 LAN・Wi-Fi・VPN を含む全接続種別を通す。PC の IP が変わるので、宛先 IP は絞らない。`-EdgeTraversalPolicy Block` で Edge Traversal は許可しない
- `Block` の 1 本は、Public・Domain のネットワークを、`caddy.exe` 宛てに遮断する。Windows のファイアウォールでは、遮断の規則が許可の規則より優先する
- どのネットワークにいても `caddy.exe` 宛ての規則がある状態にして、Caddy が待ち受けを始めたときに Windows が許可を尋ねる画面を出さないようにする狙いもある（パブリックのネットワークで Caddy を起動しての確認は、していない）
- 既存構成の切り替えでは、規則とフィルターを XML に控える。Public・Domain の遮断を固定し、Allow を Private に限定してから、送信元と接続種別を Any にする。読み戻しがすべて一致したことを確かめ、別の手順で旧 `codeg-caddy-block-wifi` だけを消す。控えの XML は読み戻し用で、`Import-Clixml` は規則を復元しない
- 既存の Public・Domain 遮断規則は、手順書由来の全プロトコル・全ポートの規則だけを扱う。`Protocol`・`LocalPort`・`RemotePort` がすべて `Any` であることを変更前に確認し、異なる条件なら中断する。設定時は `Protocol Any` を指定し、ポートの条件は変更しない
- URL の表示は、接続中の Private のプロファイルに対応する InterfaceIndex から、有効な IPv4 を拾う。接続名を添え、loopback・link-local・SkipAsSource のアドレスは出さない。物理アダプターだけには絞らない
- Private の URL に接続できた結果は、その受信インターフェースの許可を示す。Public・Domain の遮断は、それぞれの受信インターフェースと現在の IP、接続経路、サーバーの稼働を別に確認して試す。タイムアウトだけでは遮断の確認にならない
- VPN のクライアントの通信は、WG ホストが LAN へ転送する。PC から見た送信元は、クライアントの VPN のアドレスだった
- VPN からの通信にも、ホスト側で実際に受信するインターフェースの Private が必要。WG ホストが LAN へ転送する場合は LAN 側、PC 自身で VPN を受ける場合はその VPN 側の種類で判定する。信頼する接続だけを Private にし、公衆 Wi-Fi などほかの接続は Public のままにする
- Caddy のタスクも、Codeg と同じく、サインイン中に管理者ではない権限で動かす。`curl.exe` の `--ssl-no-revoke` は、失効の確認ができない自前の認証局のために付ける
- タスクの引数は、スクリプトのパスを二重引用符で囲む。ランチャーは、そのパスを 1 個の引数として受け取り、PowerShell の `-File` に渡す
- Caddy は `start-caddy-hidden.ps1` から始め、Codeg と同じランチャーを使う。`exit $LASTEXITCODE` とランチャーを通して、Caddy の終了コードをタスクへ返す
- タスク スケジューラの「失敗時の再起動」（`-RestartCount`・`-RestartInterval`）は使わない。終了コード 1 で終わる使い捨てのタスクで試すと、再起動されなかった（検証記録）
- 待ち受ける IP を決めないので、サインインの時点で LAN につながっていなくても、Caddy は起動する
- Windows の停止・更新・ロールバックは、配置先が一致する Codeg の PID に `taskkill /T /F` を使う。タスクを止めるより先に子プロセスごと終了し、ほかの ACP クライアントの Grok を巻き込まない

### Codeg の共通パスワードを設定・変更する / 手順 1〜3: 補足: 標準認証

- 本人が決めた共通パスワードを、Codeg の標準認証の `CODEG_TOKEN` の値として使う。[公式の Web Service 設定](https://docs.codeg.app/reference/settings/web-service)と[サーバーの読取箇所](https://github.com/spacering-net/codeg/blob/e21eb6b38eea9405cdfa3b2d99df216d101d1344/src-tauri/src/bin/codeg_server.rs#L205)を参照
- 画面のトークン名と、内部の bearer による認証は維持する。[認証の実装](https://github.com/spacering-net/codeg/blob/e21eb6b38eea9405cdfa3b2d99df216d101d1344/src-tauri/src/web/auth.rs#L21)は、受け取った値を設定値と照合する
- 標準認証は 1 個の共有値を使う。同じ Codeg を使う利用者は同じ値で入り、利用者ごとの区別や有効期限は無い。Claude・Codex の本人の契約の認証とは別に、サーバーへのアクセスに使う
- [ログイン画面](https://github.com/spacering-net/codeg/blob/e21eb6b38eea9405cdfa3b2d99df216d101d1344/src/app/login/page.tsx#L31)は入力した値を localStorage に保存する。値を変更した後は、以前の値を覚えたブラウザ・端末でログインし直す
- Windows のスクリプトは `Read-Host -AsSecureString` で 2 回入力を受け、32〜512 文字の表示可能な ASCII・空白無し・一致を確かめる。既存の起動用スクリプトの最低 32 文字は維持する
- Windows の控えは同じディレクトリの `token.before-password-<unique>.txt` へ、本人だけの ACL で保存する。保存は原子的な置換で行い、認証を確かめる。結果の JSON はパスワードの値を含めない
- `password-change-result.json` の `CredentialReplaced` は今回の置換が完了した履歴で、復元後も `true`。`FileUnchanged` は置換前のまま元ファイルを保っている状態
- `FileRestored` は置換後に控えから戻した場合だけ `true`。未置換の場合は `false` のまま。`ServiceRestored` は専用サービスの復帰の結果で、ファイルの状態とは別
- `Restored` は、ファイル未変更または復元済みに加え、サービスの復帰も確認できたときだけ `true`。前提確認・入力の未変更終了と、変更処理を始めた後の失敗も分けて扱う
- 変更処理で結果自体を得られない失敗では、`CredentialReplaced`・`FileUnchanged` は `null`。未変更と断定せず、認証ファイルと専用サービスの状態を確認してから復旧する
- 旧認証での 200 は確認しないため、`OldPasswordVerified` は `false` のまま。本人がブラウザで確かめる

### Codeg の共通パスワードを設定・変更する / 手順 1〜4: 補足: AlmaLinux の対話スクリプト

- [AlmaLinux 10 の共通パスワード手順](../ai-agents.md#grok-build-のブラウザ操作-codeg-の共通パスワードを設定変更する)は、`scripts/grok-build-remote/set-codeg-password.py` を本人の端末で使う。Python の `getpass` で 2 回入力し、Windows と同じ文字条件と一致を確かめる
- `--check` は認証ファイルの本文を読まない。所有者と権限、`EnvironmentFile` の参照先、`StandardError=null`、専用サービスの実行ファイルと待ち受け、未認証 401 を確認する
- 入力値は本人のローカルプロセスのメモリ内で扱う。コマンド引数・ログ・結果の表示には出さない。保存時は systemd の `EnvironmentFile` に合わせて引用し、`\` と `"` をエスケープする
- `~/.config/codeg-server/` は 0700、`token.env` と新規の一時ファイル・控えは 0600。既存ファイルをハードリンクで控え、本文を読み出さずに新ファイルへ原子的に置き換える
- 控えは成功時にも保持する。複数の変更を同時に実行しないためのロックを使い、変更後の失敗では旧設定の復元と Codeg の再起動を別に確かめる。不明な結果では、控えを消したり未変更と断定したりしない
- Codeg の `--supervise` の MainPID と、3080 番を待ち受ける worker は別になる。サービスの cgroup 内の worker を特定し、PID・開始時刻・実行ファイルと socket inode を各要求の前後で照合する
- 新しい値での 200 と `status=ok`、未認証 401、誤った値 401 を同じ worker で確認する。失敗後の旧認証による 200 と、本人の HTTPS ログインは自動では確認しない

### Claude Code のプラグインから Grok に読み取り専用で頼む / 手順 1〜5: 補足: 外側の sandbox

- [AlmaLinux 10 の任意節](../ai-agents.md#grok-build-のブラウザ操作-claude-code-のプラグインから-grok-に読み取り専用で頼む)は、Grok の内側の sandbox が Landlock 非対応で起動しないホストを対象にする。通常の Grok の起動先や、Codeg の native Grok ACP の起動方法は置き換えない
- xAI の [Grok Build プラグイン](https://github.com/xai-org/grok-build-plugin-cc)が参照する `GROK_BINARY` に、`codeg-grok-readonly` を指定する。Codeg の Claude の接続はサービスの環境から、端末の Claude は `claude-agents` から、この値を継承する
- 起動用スクリプトは読み取り専用の非対話依頼だけを受け付ける。`--sandbox read-only` を必須にし、書き込み用の指定・worktree の作成・コードの復元・外部 leader socket の指定を拒否する
- 外側では bubblewrap の読み取り専用マウント、user/PID namespace、能力の削除を使う。この境界の内側でだけ Grok の sandbox を `off` にし、Landlock と Podman のソケットのエラーを回避する。bubblewrap が起動できなければ Grok も起動しない
- `/tmp` と `/run` は私有化し、既存の Grok leader socket を隠す。新しい leader は私有の `/tmp` に置き、ホスト側の既存 leader にツールの実行を渡さない
- `~/.grok/sessions/` と `~/.grok/logs/` は保存用に書き込みを許す。読み取りを特定の worktree やホーム内の一部へ限定する仕組みではなく、ネットワークも遮断しない。秘密情報を読まない規則は引き続き守る
- バージョンとモデル一覧の照会は、外側の sandbox を経由せず Grok を直接呼ぶ。`--self-test` は、本来読み取り専用の場所への書き込み拒否と、セッションの保存先への書き込みを確認する

### Codeg のエージェント同士で共同作業する / 手順 1〜3: 補足: 委譲と作業ディレクトリ

- Codeg の [Collaboration 設定](https://docs.codeg.app/reference/settings/collaboration)は、Claude Code の Codex・Grok プラグインとは別の委譲機能。Codeg の `codeg-mcp` が委譲のツールを接続中のエージェントへ渡す
- 設定の保存後に始めるエージェントへ適用される。最大の委譲深度 `1` では、委譲先からの追加の委譲を許さない。有効なエージェントが委譲先として表示される
- 委譲先は親の作業ディレクトリを共有するのが既定で、別の worktree は自動では作られない。読み取り専用のレビューと、編集を行う担当の会話を分け、編集の担当ごとに worktree とブランチを明示する
- エージェントごとの既定値は委譲先に使うモード・設定で、親の会話の権限モードを変更するものではない。設定を保存したことと、各エージェントの組合せで応答を得たことは別に確認する

### Claude Code と Codex CLI も操作する / 補足

「Claude Code と Codex CLI も操作する」（[AlmaLinux 10](../ai-agents.md#grok-build-のブラウザ操作-claude-code-と-codex-cli-も操作する)・[Windows 11](../ai-agents.md#grok-build-のブラウザ操作-windows-11-で-claude-code-と-codex-cli-も操作する)）は、構築済みの Codeg にエージェントを足す任意の節。Caddy・アクセストークン・公開範囲は変えない。以下は 2026-10-12 に公式資料と Codeg v0.35.1 のソースを確認した内容。

### Claude Code と Codex CLI も操作する / 手順 2: 補足: 接続アダプターとランタイム

| エージェント | Codeg v0.35.1 の対応アダプター | アダプターが使うランタイム |
|---|---|---|
| Claude Code | `@agentclientprotocol/claude-agent-acp@0.89.1` | Claude Agent SDK `0.3.293` と、それに付属する Claude Code `2.1.293` |
| Codex | `@agentclientprotocol/codex-acp@2.2.2` | 依存する `@openai/codex`。今回の隔離導入では `0.160.1` |

- ACP は、Codeg の画面とエージェントをつなぐ通信の仕様。Claude Code・Codex は、それぞれの接続アダプターを介して動く
- Claude のアダプターは Node.js 22 以上、Codex は 20.3 以上が必要。両方を使うこの節では 22 以上にそろえる
- 初期設定で入れた CLI を置き換えるものではない。Codeg 用には別のランタイムが入り、同じ OS ユーザーのホームにあるログイン・設定・履歴を共有する。既存 CLI と Codeg 側の版は別に確認する
- Codex の依存指定は `^0.160.1`。同じアダプター版でも、導入時に入る Codex の版が変わり得る。Codeg の対応版を、すべての依存が固定されたものとは扱わない
- Codeg は npm のグローバル領域へ導入を試み、権限不足なら `~/.codeg/npm-global` を使う。アダプターの更新は、同じ実行ファイルを使うほかの ACP クライアントにも影響し得る

対応版は [Codeg v0.35.1 のレジストリ](https://github.com/spacering-net/codeg/blob/e21eb6b38eea9405cdfa3b2d99df216d101d1344/src-tauri/src/acp/registry.rs)で確認した。実際に導入した版と試験条件は[今回の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/grok-build-remote.md#付録-claude-codecodex-の操作手順の追加2026-10-12-jst)に分ける。

### Claude Code と Codex CLI も操作する / 手順 3: 補足: 本人の契約と共有設定

- Codeg の「公式サブスクリプション」は、Claude の既存の CLI ログイン、Codex の本人の ChatGPT ログインを使う方式。Codeg 用の API キーは追加しない（[Codeg の認証方式](https://docs.codeg.app/guide/authentication)）
- Claude の公式案内（2026-10-07 更新）では、Claude Agent SDK・`claude -p`・第三者のアプリを契約の利用枠で引き続き使える。この手順はその方式を使う（[Claude の契約での SDK 利用](https://support.claude.com/en/articles/15036540-use-the-claude-agent-sdk-with-your-claude-plan)）
- Codex の ChatGPT ログインは契約による利用、API キーのログインは API の従量課金として区別される。この手順は本人の ChatGPT の利用枠を消費する（[OpenAI の認証の説明](https://learn.chatgpt.com/docs/auth)）
- API キーを設定しないことは、外部へのモデル通信が無い・無料・無制限という意味ではない。利用枠に達した場合も、API キーを入れて回避する手順にはしない
- Codeg で Claude の設定を保存すると `~/.claude/settings.json`、Codex の設定を保存すると `~/.codex/config.toml` など、端末の CLI と共有する設定にも反映される。認証方法の変更では、以前の API 用の設定が削除・変更されることもある
- ログインのやり直しも同じユーザーの CLI に効く。別のアカウントへ切り替える操作は、Codeg の会話だけに閉じない（[共有設定と履歴の注意](../extra/grok-build-remote.md#claude-codecodex-の共有設定と履歴)）

### Claude Code と Codex CLI も操作する / 手順 4〜7: 補足: モードと中断

- Claude のアダプターが返すモードは `Manual`・`Accept edits`・`Plan`・`Auto`。環境・管理設定などで許可される場合にだけ `Bypass permissions` も出る。手順では `Auto` を選ぶ
- モデルが対応せず「Auto mode unavailable」になったときは、`Accept edits` に切り替わる実装がある
- `Accept edits` は `Auto` の確認完了と扱わない。手動運用を選ぶときは `Manual` に変える。`Auto` の可否は、最初の応答とモデルの変更後にも確かめる
- Codex のモードは `Read-only`・`Workspace access`・`Auto review`・`Full access`。手順では `Auto review` を選ぶ。開始時のモードは、既存の Codex 設定や Windows の sandbox の状態にも左右される
- 自動審査は、すべての操作への確認を省く指定ではない。審査結果に応じて確認・拒否が残る。停止ボタンを押しても、既に行ったファイル変更やコマンドの効果は巻き戻らない
- Claude Code を選んだとき、入力欄の下の並びは、左から Mode・Model・Effort・Fast mode（`On`・`Off`）・Agent（`Default` は標準の Claude Code）
  - 画面に項目の名前は出ない。2026-10-14 の Windows 11 の実機では `Manual`・`Opus 5.5`・`Xhigh`・`Off`・`Default` と並んでいた
  - 項目の名前は、画面ではなく、Codeg が入れた `claude-agent-acp` 0.89.1 のソースで確かめた

表示名と切り替えの条件は、[Claude のモードの実装](https://github.com/agentclientprotocol/claude-agent-acp/blob/4e1fc1e8df2b9af3b1b2d6880ba90c5862283ba8/src/session-mode.ts)と [Codex のモードの実装](https://github.com/agentclientprotocol/codex-acp/blob/202e66e63343ec4f5a5e35ab590251d813d129ca/src/AgentMode.ts)で確認した。Codeg の画面での自動審査・拒否・中断の実測とは区別する。

### Claude Code と Codex CLI も操作する / 手順 8〜10: 補足: 履歴の取り込みと再開

- ブラウザで操作していても、取り込むのは Codeg のサーバーが動くホストの履歴。ブラウザを開く PC の履歴や、もう一方の OS の履歴は同期されない
- 一覧は、開いたフォルダだけでなく、このホストの各エージェント・各プロジェクトの履歴を走査する。全プロジェクトを対象にする場合も、一覧の作業ディレクトリごとに本人の終了済みセッションを選別する
- 「すべて選択」は、その時点の絞り込みに合う対象で選択を置き換える。Claude と Codex を順に取り込む場合は、エージェントごとに取り込みを終えてから絞り込みを切り替える。進行中の会話は自動で除外されない
- Codeg は元の会話の ID とエージェントを使って再開する。取り込みで元の CLI の履歴は削除されない。別のエージェントへ履歴を変換する操作ではない
- 履歴の取り込みと会話の再開は別の操作。取り込みだけなら、会話を開いて続きを送る必要はない
- Claude の再開では、元の会話のモードを引き継ぐ場合がある。続きを送る前に、表示中のモデル・モードを確かめ、今回使うものを選ぶ
- Codeg v0.35.1 の Codex の走査対象は、`CODEX_HOME` 配下の `sessions`。アーカイブ済みの `archived_sessions` は含まれない。必要な会話は元の Codex でアーカイブ解除してから再スキャンする（[Codex の走査対象](https://github.com/spacering-net/codeg/blob/e21eb6b38eea9405cdfa3b2d99df216d101d1344/src-tauri/src/parsers/codex.rs#L207)・[取り込み処理](https://github.com/spacering-net/codeg/blob/e21eb6b38eea9405cdfa3b2d99df216d101d1344/src-tauri/src/db/service/import_service.rs#L43)）
- 取り込み後に再度アーカイブすると、Codeg の表示や再開に影響する場合がある。取り込み後に自動で元の場所へ戻す手順にはしない
- 同じ会話を元の CLI・アプリと Codeg で同時に進めない。元の会話を閉じてから再開する。元の履歴が削除された、またはセッションが使えなくなった場合は、一覧にあっても再開できないことがある（[Codeg の会話の取り込み](https://docs.codeg.app/guide/aggregation)）

### Windows 11 で Antigravity も操作する / 補足: CLI と ACP サーバー

- [Windows 11 で Antigravity も操作する](../ai-agents.md#grok-build-のブラウザ操作-windows-11-で-antigravity-も操作する)では、Codeg 組み込みの「Google Antigravity」を使う
- Codeg v0.35.1 では、Google 純正の ACP サーバー `agy_acp_server` 1.3.0 を入れる。`agy` 1.3.5 とは別の製品
- CLI のログインは資格情報マネージャーの `gemini:antigravity` にあり、ACP サーバーはそれを使わない
- Codeg 用のログインは `%USERPROFILE%\.gemini\antigravity-acp\acp_token.json` に保存される。ファイルの中身は読んでいない
- 非公式の ACP ラッパーは、利用規約上の注意があるため使わない
- 「ファイルとコマンドをエージェント自身に処理させる」をオフのままにするのは、オンにすると Codeg がファイル操作と端末を代行しなくなり、ほかのエージェントからの委譲も無効になるため（Codeg の設定の画面の説明）

### Windows 11 で Antigravity も操作する / 補足: サインインの方式

- 自動のサインインは接続のやり直しのたびにブラウザのタブを開き、5 分で時間切れになる。待っていた古い接続が時間切れで終わるときに、保存済みのトークンが消えた
- このため、「ブラウザのないマシンでサインイン」を使う。Antigravity の会話のタブを閉じて ACP サーバーを終了してから始めることで、古い接続の待ち手を残さない
- この PC では、利用者がブラウザで承認した戻り先を Codeg の待ち手が受け取り、トークンが保存された。後から「サインインを完了」に貼る操作で待ち時間切れの表示が出ても、サインインは済んでいた

### Windows 11 で Antigravity も操作する / 補足: 作業フォルダーと規則の制約

- Active Workspaces は `%USERPROFILE%\.gemini\antigravity-cli\skills`・`%USERPROFILE%\.gemini\config\skills`・作業フォルダーの順だった
- エージェントは先頭を作業フォルダーとみなし、ファイル作成の承認カードも `antigravity-cli\skills` の下を指した
- 会話のメタデータの `cwd` が正しくても、作業フォルダーの `AGENTS.md` は読み込まれなかった。共同作業の規則を自動で読む前提では使えない
- Codeg で未レビューの ACP サーバー 1.4.0 でも同じ制約があり、1.3.0 に戻した。同じ worktree の `agy -p` では、Active Workspaces はその worktree だけで、規則も読み込まれた
- Codeg から Claude Code が Antigravity へ委譲した場合も、作業ディレクトリは親と同じで、別の worktree は作られなかった。CLI の読み取り専用レビューとは分けて扱う

### Windows 11 で Antigravity も操作する / 補足: 初期化の待ち時間

- ACP サーバーは PyInstaller の onefile で、起動のたびに `%TEMP%\codeg-acp\<pid>-<id>\_MEI…` へ展開する。この初期化に時間がかかる
- Initialize の応答に 32〜56 秒かかり、60 秒の接続ハンドシェイクの制限を超えることもあった。1.4.0 の初回も同じで、その後の再接続で接続できた

## Claude Code・Codex を遠隔操作する OSS の比較

2026-10-12 に公式資料と実装を比較した。今回は、既に Grok Build で使う Codeg と Caddy を共用できる Codeg を推奨する。CloudCLI と Happy の導入・実機での操作は試していない。既存の表にある Happier と、ここで比べる Happy は別のツール。

| ツール | ライセンス | 向く用途・今回の判断 |
|---|---|---|
| Codeg | Apache-2.0 | Claude Code・Codex を同じ画面から操作でき、Linux arm64 と Windows の配布物がある。既存の HTTPS 構成を使えるので、今回の手順に採用する |
| CloudCLI（Claude Code UI） | AGPL-3.0-or-later | Claude・Codex の Web UI を簡単に用意したい場合の候補。Codex のチャットは SDK の非対話実行で、対話的な承認要求に答える操作に制約がある |
| Happy | MIT | スマートフォンや Web からの遠隔操作が中心。標準では外部の relay を使う。従来の CLI は保守モードで、新機能は desktop へ移っているため、今回の主手順にはしない |

- CloudCLI の [Codex の実装（確認したコミット）](https://github.com/siteboon/claudecodeui/blob/7c3049fe8e157f12b7add3e496d8d2fe6fa5c014/server/modules/providers/list/codex/codex-runtime.provider.ts#L247)には、`exec` から対話的な承認要求へ許可を返せないと記載がある。今回の承認・拒否を含む用途では、この制約を先に確かめる必要がある
- Happy は [CLI の relay の説明](https://github.com/slopus/happy/blob/99f415fa0d12d233a80a77fd88122bfb19b17477/packages/happy-cli/README.md#L128)と[公式案内](https://happy.engineering/docs/)を確認した。self-host もできるが、中継サーバーの準備と保守が追加で必要になる
- OSS なのは画面・接続ツール。Claude・ChatGPT のサービスを無料・無制限で使えるという意味ではない

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
| 端末をそのまま使う | SSH のアプリと tmux | 採らない（[共同作業の手順書](../ai-agents.md#コーディングエージェントの共同作業-スマートフォンから指示する)にある） | 画面で扱いたい、という目的に合わない。AlmaLinux 10 だけ |
| 端末をそのまま使う | ttyd などの Web の端末 | 採らない | 端末がそのままブラウザに出る。スマートフォンで Ctrl・Esc・矢印が打ちにくい |
| 端末をそのまま使う | zellij の Web クライアント | 採らない | Windows 版に未解決の不具合がある（[Claude Code の Remote Control（Windows）の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-claude-remote-control.md)） |
| Codeg の置き方 | 配布物を取得して SHA-256 を照合し、ホームに置く | 採った | 版を決めて入れる。`sudo` を使わない |
| Codeg の置き方 | 公式のインストーラー（`curl … \| bash`・`irm … \| iex`） | 採らない | SHA-256 を照合しない。`/usr/local` に置く（Linux） |
| Codeg の置き方 | 公式の Docker イメージ | 採らない | コンテナの中で動くので、ホストの Grok Build のログイン・Git・道具をそのまま使えない |
| Codeg の置き方（Windows 11） | Codeg のデスクトップアプリの「Web サービス」 | 採らない | すべての NIC で待ち受ける。待ち受ける IP を選べない |
| 常駐（AlmaLinux 10） | systemd のユーザーサービスと linger | 採った | Codeg はユニットを同梱しない |
| 常駐（Windows 11） | タスク スケジューラ（サインイン中、管理者ではない権限） | 採った | SSH のセッションから始めると管理者の権限で動くので、タスクにした |
| つなぐ側 | ブラウザ | 採った | スマートフォンと PC で同じ画面 |
| つなぐ側 | Codeg のデスクトップアプリ（リモートのワークスペース） | 採らない（確かめていない） | Windows の署名が無い。サーバーの `CODEG_BROWSER_TUNNEL` を見直す必要がある |
| つなぐ側 | Codeg の Android のアプリ | 採らない（確かめていない） | Apache-2.0。APK を GitHub から入れる。testing の段階 |
| 経路（AlmaLinux 10） | LAN と VPN の、指定した帯だけに開ける | 採った | 送信元を CIDR で絞る（複数を並べられる）。はじめは VPN の帯だけにしていたが、LAN からも使うために広げた |
| 経路（Windows 11） | Private の全送信元・全接続種別に開ける | 採った | IPv4・IPv6 と、有線 LAN・Wi-Fi・VPN を区別しない。Public・Domain と Edge Traversal は遮断する（利用者の指定） |
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
- まず localhost で起動して確かめ、それから公開する。AlmaLinux 10 は待ち受ける IP と送信元を絞る（[Forgejo](../forgejo.md#forgejo) と同じ順）
- Windows 11 の PC は待ち受ける IP を決めない。利用者の指定で、受信インターフェースが Private なら全送信元・全接続種別を許可し、Public・Domain は遮断する。送信元 CIDR と有線限定は使わない
- 外に出す口は HTTPS だけにする（利用者の指定）。Codeg は `127.0.0.1` のままにし、同じホストの Caddy が TLS を受け持つ。証明書は Caddy の認証局で作り、端末にルート証明書を入れて、警告なしで開く
- 認証局は、ホストごとに別にする。鍵は Caddy が作り、エージェントは読まない
- トークンは、エージェントに作らせず・読ませず、利用者が作る。確認は、値を表示しないコマンドで行う
- 利用者の指定で、承認を減らして使う用途にはスマート自動承認（`auto`）を選ぶ。Grok の審査で確認や拒否になる操作は残る。確認が出ることを安全の境界にはしない（`mkdir` は確認なしで実行された）
- 両 OS の操作は OS 別の正本へ集約する（[AlmaLinux 10](../ai-agents.md#grok-build-のブラウザ操作-実施手順)・[Windows 11](../ai-agents.md#grok-build-のブラウザ操作-windows-11-で使う)）

## 参照

- [spacering-net/codeg](https://github.com/spacering-net/codeg)（Codeg。Apache-2.0）
- [Codeg: Supported Agents](https://docs.codeg.app/guide/supported-agents)・[Working with Agents](https://docs.codeg.app/guide/agents)
- [Codeg: Deployment](https://docs.codeg.app/getting-started/deployment)・[Configuration](https://docs.codeg.app/getting-started/configuration)・[Installation](https://docs.codeg.app/getting-started/installation)・[Privacy & Security](https://docs.codeg.app/reference/privacy)
- [Codeg の Issue #436](https://github.com/spacering-net/codeg/issues/436)（Grok の拒否の規則と sandbox が、Codeg の下で効かなかった報告）・[#876](https://github.com/spacering-net/codeg/issues/876)（Grok のモデルの一覧）
- [caddyserver/caddy](https://github.com/caddyserver/caddy)（Caddy。Apache-2.0）・[Caddyfile の `tls`](https://caddyserver.com/docs/caddyfile/directives/tls)・[Caddyfile の全体の設定（`admin`・`auto_https`・`skip_install_trust`・`pki`）](https://caddyserver.com/docs/caddyfile/options)
- [Caddyfile の環境変数と引用](https://caddyserver.com/docs/caddyfile/concepts#environment-variables)・[待ち受ける IP の指定（`bind`）](https://caddyserver.com/docs/caddyfile/directives/bind)・[On-Demand TLS](https://caddyserver.com/docs/automatic-https#on-demand-tls)
- [Microsoft: New-ScheduledTaskSettingsSet](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtasksettingsset)・[taskkill](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/taskkill)（`/T` は子プロセスも止める）・[New-NetFirewallRule](https://learn.microsoft.com/en-us/powershell/module/netsecurity/new-netfirewallrule)（`-Profile`・`-InterfaceType`）
- [Microsoft: MSIX のデスクトップアプリの実行環境](https://learn.microsoft.com/en-us/windows/msix/desktop/desktop-to-uwp-behind-the-scenes)・[Flexible virtualization](https://learn.microsoft.com/en-us/windows/msix/desktop/flexible-virtualization)（AppData への書き込みの転送）
- [xai-org/grok-build](https://github.com/xai-org/grok-build)（Grok Build。Apache-2.0）
- Grok Build の同梱の文書（`~/.grok/docs/user-guide/`）: `15-agent-mode.md`（ACP）・`22-permissions-and-safety.md`（権限モード）
- [Agent Client Protocol](https://agentclientprotocol.com)
- [getpaseo/paseo](https://github.com/getpaseo/paseo)・[joeynyc/Grok-UI](https://github.com/joeynyc/Grok-UI)・[Happier の Grok 対応](https://docs.happier.dev/agents/grok)・[Zed の外部エージェント](https://zed.dev/docs/ai/external-agents)（比べた候補）
