# Codeg の参考資料

[AlmaLinux 10 の手順](../ai-agents.md#codeg-almalinux-10-で使う)・[Windows 11 の手順](../ai-agents.md#codeg-windows-11-で使う)・[ロールバックと注意点](../extra/codeg.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/codeg.md)

## 補足

### Codeg / サーバーを入れて localhost で起動する / 手順 1: 補足: 変数

- `SERVER_IP` は、Caddy が待ち受ける IP と、firewalld の規則の宛先の両方に使う。Codeg は `127.0.0.1` のまま
- `ALLOW_FROM` は送信元 IPv4 の CIDR。空白で区切って複数を並べられ、1 つにつき規則を 1 本作る。WG ホスト自身で動かすときは、VPN のクライアントの通信が `wg0` から入り、送信元はクライアントの VPN のアドレスになる
- ポートは、Codeg が既定の 3080（ホストの中だけ）、Caddy が 3443（外から届く口）。どちらも変数にしていない
- `FW_ZONE` は自動で入る

### Codeg / サーバーを入れて localhost で起動する / 手順 3: 補足: SHA-256 の照合

- `.sha256` は、配布物と同じリリースに置かれたファイル。取得の途中で壊れたものは見つけられるが、リリースそのものが書き換えられた場合は見つけられない
- GitHub のリリースの画面と API は、配布物ごとの digest（`sha256:…`）を出す。検証では、その値とも一致することを確かめた
- リリースには `.sig`（署名）もある。検証のしかたは公式の文書に無く、本書では使っていない
- 公式のインストーラー（`install.ps1`）は、SHA-256 を照合しない（スクリプトを読んで確かめた）。`install.sh` は読んでいない
- `tar -tzf` が成功したときだけ一覧を変数に入れ、`awk` で展開先を外れるパス（`/` で始まるもの、`..` を含むもの）の数を出す。一覧を読めなかった場合は `0` を出さずに中断する。数が `0` なら成功、それ以外なら終了コードも非 0 にする

### Codeg / サーバーを入れて localhost で起動する / 手順 4: 補足: 置き場所

- 公式のインストーラーは、実行ファイルを `/usr/local/bin`、画面のファイルを `/usr/local/share/codeg/web` に置く。本書は `sudo` を使わず、ホームの `~/.local/opt/codeg-server` にまとめる
- `codeg-mcp` は、`codeg-server` と同じディレクトリに置く（Codeg は既定で隣を探す。`CODEG_MCP_BIN` で変えられる）
- `codeg-computer-helper` は、サーバーのデスクトップを操作させる機能（`CODEG_COMPUTER_USE`）の部品。その機能を使わないので置かない

### Codeg / サーバーを入れて localhost で起動する / 手順 6: 補足: ユニットの各行

- `EnvironmentFile` は必須にしてある（`-` を付けない）。トークンのファイルが無ければ起動に失敗し、Codeg がトークンを自分で作ることは無い
- `Environment=PATH=` は、本人が入れたエージェントの CLI を探すため。`~/.grok/bin` も残し、Grok Build を使うときに `grok` を見つけられるようにする
- `CODEG_BRIDGE_PORTS=off` は、プロジェクトの開発サーバーを中継するための追加のポート（既定は 3081〜3090）を開けない設定
- `CODEG_BROWSER_TUNNEL=off` は、Codeg のデスクトップアプリをつないだときに、そのアプリの内蔵ブラウザがサーバー経由で届く範囲を無くす設定（既定は `all`）
- `--supervise` は、画面からの自己更新を監視する仕組み（公式の文書）。自動更新は専用のプログラムが本体と DB の退避・起動確認・復元を行い、画面からは入れ替えない
- `StandardError=null` は、起動のたびに標準エラーへ出るトークンを journal に残さないため。Codeg のログは、別に `~/.local/share/codeg/logs/` に出る
- `Restart=on-failure` と `RestartSec=5` は、異常終了したときに起動し直すため。共通の Caddy の起動し直しは [Caddy の参考資料](caddy.md)を参照する

### Codeg / サーバーを入れて localhost で起動する / 手順 7: 補足: トークンを引数に書かない

- `curl -K -` は、設定を標準入力から読む。`printf` は bash の組み込みなので、トークンがどのプロセスの引数にもならない
- `grep -cFf <(…)` は、探す文字列をファイル（プロセス置換）から読む

### Codeg / Grok Build を使う / 手順 1: 補足: 権限モードと config.toml の値

- Codeg の「権限モード」を保存すると、`~/.grok/config.toml` の `[ui]` の `permission_mode` が書き換わる。ほかの行は変わらなかった
- 「毎回確認」は `"default"`、「常に許可」は `"bypassPermissions"` と書かれた。Grok Build の文書では、`"always-approve"` と `"bypassPermissions"` は同じモード
- 本書では、対話の承認を減らして使う用途として「スマート自動承認」（`"auto"`）を選ぶ。Grok Build の文書では、自動審査が許可した操作は実行され、許可しない操作は確認へ回るか拒否される。保存した値は端末の `grok` にも反映され、次の会話から効く
- Codeg での保存と、そのモードで新しい会話を動かす確認は分ける。機能を選べない・保存できない・まだ使っていない場合は、対応する確認を未完了として記録する
- Codeg は、「常に許可」のとき `--permission-mode bypassPermissions` を付けて Grok Build を起動し、「毎回確認」のときは付けなかった
- Grok Build の文書では、既定（ask）で確認なしに動くのは、読み取り専用のツールと、決まった読み取り専用のコマンドだけ。`mkdir` はその一覧に無いが、検証では確認なしで実行された

### Codeg / Grok Build を使う / 手順 2: 補足: 最初の会話のモデル

- Codeg を起動して最初の会話は、モデルの欄が Grok 4.6 で、Grok Build のセッションの記録（`events.jsonl`）の `modelId` も `grok-4.6` だった。同じ時点の `grok models` の既定は `grok-4.7`
- Codeg の Issue に、Grok の ACP の接続で、後から届くモデルの一覧が反映されない不具合の報告がある（#876。2026-10-02 に閉じられている）。同じ原因かは確かめていない

### Codeg / HTTPS で LAN・VPN に公開する / 手順 1: 補足: Codeg のサイト

- AlmaLinux 10 は、[共通の Caddy](../almalinux-setup.md#caddy)に `sites/codeg.caddy` を足す。本体の入手・共通設定・サービス・指紋の照合は [Caddy の参考資料](caddy.md)にまとめる
- `bind` は、待ち受ける IP を限定する。`tls internal` はホスト共通の認証局でその IP 用の証明書を作る。`import root-crt` は共通の `root.crt` を配る
- `handle` の `reverse_proxy 127.0.0.1:3080` は残りの通信を Codeg に渡す。WebSocket も通る
- Windows 11 は専用の本体・Caddyfile・タスクを使う。グローバル設定の各行の意味は [共通の説明](caddy.md#caddy-入れて起動する--手順-4-共通の-caddyfile)と同じ

### Codeg / HTTPS で LAN・VPN に公開する / 手順 3・4: 補足: 待ち受けと規則

- Codeg は `127.0.0.1` のままにする。暗号化されない HTTP は、ホストの外に出ない
- 規則は、[Forgejo](../forgejo.md#forgejo) と同じ形（送信元・宛先・ポートを絞った rich rule）。zone の既定の拒否はそのままで、指定した送信元だけを通す
- サーバー自身から `SERVER_IP` へつなぐ通信は、firewalld の規則にかからない
- `curl` の終了コード 60 は、相手の証明書を検証できなかったことを示す

### Codeg / 端末にルート証明書を入れる / 指紋の照合

- [Caddy の参考資料](caddy.md#caddy-端末にルート証明書を入れる--指紋の照合)を参照する。AlmaLinux 10 は Forgejo などと同じ認証局を共有し、同じホストのために取り込み済みの端末には入れ直さない
- Windows 11 の認証局は Codeg 専用。信頼先を選ぶ指紋の照合は同じ操作で行う

### Codeg / 接続元の制限を外す / 手順 1〜4: 補足: 宛先限定の規則

- [AlmaLinux 10 の任意節](../ai-agents.md#codeg-接続元の制限を外す)は、既存の `ALLOW_FROM` による制限を、宛先 IPv4 と 3443/tcp だけの rich rule へ切り替える。基本の導入手順は送信元を絞ったまま
- runtime と permanent の両方へ新規則を追加してから、証明書を検証した未認証の要求が 401 になることを確かめ、元の送信元付き規則だけを外す。認証の共有値や Codeg・Caddy の待ち受けは変更しない
- 送信元を指定しない規則は、LAN・VPN に属することを判定しない。宛先へ届く経路があれば、ほかのネットワークからも接続の対象になる
- 自ホストの HTTPS 検査は、証明書と認証の検査で、別の端末からの到達確認ではない。別端末からのログインや、不要な経路を公開していないことの確認とは分ける

### Codeg / Windows 11 でサーバーを入れて起動する / 手順 6〜8: 補足: スクリプトとタスク

- 環境変数を利用者の環境（レジストリ）に入れると、すべてのプロセスにトークンが渡る。起動用のスクリプトの中だけで設定する
- スクリプトは ASCII で書く。Windows PowerShell 5.1 は、BOM の無いスクリプトを既定のコードページで読む
- タスクは、管理者ではない窓から、ログオン時のトリガー付きで登録できた。`-RunLevel Limited` で、Codeg はデスクトップのセッションの、管理者ではない権限で動く
- PowerShell をタスクから直接起動する形では、`-WindowStyle Hidden` を指定していても、このホストで Terminal が開いた
- Windows 標準の .NET Framework の `csc.exe` で、`/target:winexe` のランチャーを作る。タスクはこの実行ファイルを起動する
- ランチャーは `UseShellExecute=false`・`CreateNoWindow=true` で PowerShell を始める。標準出力と標準エラーは読み捨て、Codeg が出すトークンを表示・保存しない
- 子プロセスが終わるまで待ち、その終了コードを返す。ログオンのトリガーと `Limited` の権限は変えない
- コンソールを作らない指定は [ProcessStartInfo.CreateNoWindow](https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.processstartinfo.createnowindow?view=netframework-4.8.1) を使う

### Codeg / Windows 11 で HTTPS で LAN・VPN に公開する / 手順 2: 補足: 待ち受ける IP を決めない設定

- サイトのアドレスを `https://:3443` にして `bind` を書かないと、Caddy は、すべてのアドレスの 3443 番で待ち受ける
- `tls internal` の `on_demand` は、TLS の接続が来たときに、その宛先の証明書を作る指定。IP アドレスで開いた接続は名前（SNI）を持たず、Caddy は、接続を受けたローカルの IP 宛ての証明書を作った
- 認証局は変わらない。端末のルート証明書は、PC の IP が変わっても入れ直さない
- Caddy は、起動のときに `on-demand TLS is enabled, but no protections are in place` の警告を出す。証明書を作ってよい名前を尋ねる先（`ask`）を置いていないため。Windows では送信元を制限せず、受信インターフェースの Private という条件だけで公開するので、その接続へ届く端末は任意の名前の証明書を要求できる
- AlmaLinux 10 のサーバーは IP が固定なので、IP 宛てのサイトと `bind` のままにしてある

### Codeg / Windows 11 でサーバーを入れて起動する / 手順 1: 補足: MSIX からの配置

- MSIX のパッケージは、AppData への書き込みを、パッケージ専用の `LocalCache` へ転送することがある。パッケージ内では元のパスに見えても、通常の Windows のプロセスからは見えない
- 今回の Codex からの配置はこの形になった。通常の AppData の `Get-Item` の結果だけでは、タスクが起動する本体の存在を確認できなかった。既知のファイルの実体パスと、システム側の `CIM_DataFile` の存在確認で区別した（実測は検証記録）
- 手順書は、スタートメニューから開いた Windows PowerShell で行う形にしてある。Codeg を動かすタスクは、通常の AppData にあるランチャーとスクリプトを使う

### Codeg / Windows 11 で HTTPS で LAN・VPN に公開する / 手順 3・4: 補足: 規則とタスク

- `-Program` で `caddy.exe` 宛てに限る。同じ PC のほかのプログラムが 3443 番で待ち受けても、この規則では通らない
- `-Profile Private`・`-RemoteAddress Any`・`-InterfaceType Any` で、ホスト側の受信インターフェースが Private なら、IPv4・IPv6 の全送信元、有線 LAN・Wi-Fi・VPN を含む全接続種別を通す。PC の IP が変わるので、宛先 IP は絞らない。`-EdgeTraversalPolicy Block` で Edge Traversal は許可しない
- `Block` の 1 本は、Public・Domain のネットワークを、`caddy.exe` 宛てに遮断する。Windows のファイアウォールでは、遮断の規則が許可の規則より優先する
- どのネットワークにいても `caddy.exe` 宛ての規則がある状態にして、Caddy が待ち受けを始めたときに Windows が許可を尋ねる画面を出さないようにする狙いもある（パブリックのネットワークで Caddy を起動しての確認は、していない）
- URL の表示は、接続中の Private のプロファイルに対応する InterfaceIndex から、有効な IPv4 を拾う。接続名を添え、loopback・link-local・SkipAsSource のアドレスは出さない。物理アダプターだけには絞らない
- Private の URL に接続できた結果は、その受信インターフェースの許可を示す。Public・Domain の遮断は、それぞれの受信インターフェースと現在の IP、接続経路、サーバーの稼働を別に確認して試す。タイムアウトだけでは遮断の確認にならない
- VPN のクライアントの通信は、WG ホストが LAN へ転送する。PC から見た送信元は、クライアントの VPN のアドレスだった
- VPN からの通信にも、ホスト側で実際に受信するインターフェースの Private が必要。WG ホストが LAN へ転送する場合は LAN 側、PC 自身で VPN を受ける場合はその VPN 側の種類で判定する。信頼する接続だけを Private にし、公衆 Wi-Fi などほかの接続は Public のままにする
- Caddy のタスクも、Codeg と同じく、サインイン中に管理者ではない権限で動かす。`curl.exe` の `--ssl-no-revoke` は、失効の確認ができない自前の認証局のために付ける
- タスクの引数は、スクリプトのパスを二重引用符で囲む。ランチャーは、そのパスを 1 個の引数として受け取り、PowerShell の `-File` に渡す
- Caddy は `start-caddy-hidden.ps1` から始め、Codeg と同じランチャーを使う。`exit $LASTEXITCODE` とランチャーを通して、Caddy の終了コードをタスクへ返す
- タスク スケジューラの「失敗時の再起動」（`-RestartCount`・`-RestartInterval`）は使わない。終了コード 1 で終わる使い捨てのタスクで試すと、再起動されなかった（検証記録）
- 待ち受ける IP を決めないので、サインインの時点で LAN につながっていなくても、Caddy は起動する
- Windows の停止・更新・ロールバックは、配置先が一致する Codeg の PID に `taskkill /T /F` を使う。タスクを止めるより先に子プロセスごと終了し、ほかの ACP クライアントのエージェントを巻き込まない

### Codeg / 共通パスワードを設定・変更する / 手順 1〜3: 補足: 標準認証

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

### Codeg / 共通パスワードを設定・変更する / 手順 1〜4: 補足: AlmaLinux の対話スクリプト

- [AlmaLinux 10 の共通パスワード手順](../ai-agents.md#codeg-共通パスワードを設定変更する)は、`scripts/codeg/set-codeg-password.py` を本人の端末で使う。Python の `getpass` で 2 回入力し、Windows と同じ文字条件と一致を確かめる
- `--check` は認証ファイルの本文を読まない。所有者と権限、`EnvironmentFile` の参照先、`StandardError=null`、専用サービスの実行ファイルと待ち受け、未認証 401 を確認する
- 入力値は本人のローカルプロセスのメモリ内で扱う。コマンド引数・ログ・結果の表示には出さない。保存時は systemd の `EnvironmentFile` に合わせて引用し、`\` と `"` をエスケープする
- `~/.config/codeg-server/` は 0700、`token.env` と新規の一時ファイル・控えは 0600。既存ファイルをハードリンクで控え、本文を読み出さずに新ファイルへ原子的に置き換える
- 控えは成功時にも保持する。複数の変更を同時に実行しないためのロックを使い、変更後の失敗では旧設定の復元と Codeg の再起動を別に確かめる。不明な結果では、控えを消したり未変更と断定したりしない
- Codeg の `--supervise` の MainPID と、3080 番を待ち受ける worker は別になる。サービスの cgroup 内の worker を特定し、PID・開始時刻・実行ファイルと socket inode を各要求の前後で照合する
- 新しい値での 200 と `status=ok`、未認証 401、誤った値 401 を同じ worker で確認する。失敗後の旧認証による 200 と、本人の HTTPS ログインは自動では確認しない

### Codeg / Claude Code のプラグインから Grok に読み取り専用で頼む / 手順 1〜5: 補足: 外側の sandbox

- [AlmaLinux 10 の任意節](../ai-agents.md#codeg-claude-code-のプラグインから-grok-に読み取り専用で頼む)は、Grok の内側の sandbox が Landlock 非対応で起動しないホストを対象にする。通常の Grok の起動先や、Codeg の native Grok ACP の起動方法は置き換えない
- xAI の [Grok Build プラグイン](https://github.com/xai-org/grok-build-plugin-cc)が参照する `GROK_BINARY` に、`codeg-grok-readonly` を指定する。Codeg の Claude の接続はサービスの環境から、端末の Claude は `claude-agents` から、この値を継承する
- 起動用スクリプトは読み取り専用の非対話依頼だけを受け付ける。`--sandbox read-only` を必須にし、書き込み用の指定・worktree の作成・コードの復元・外部 leader socket の指定を拒否する
- 外側では bubblewrap の読み取り専用マウント、user/PID namespace、能力の削除を使う。この境界の内側でだけ Grok の sandbox を `off` にし、Landlock と Podman のソケットのエラーを回避する。bubblewrap が起動できなければ Grok も起動しない
- `/tmp` と `/run` は私有化し、既存の Grok leader socket を隠す。新しい leader は私有の `/tmp` に置き、ホスト側の既存 leader にツールの実行を渡さない
- `~/.grok/sessions/` と `~/.grok/logs/` は保存用に書き込みを許す。読み取りを特定の worktree やホーム内の一部へ限定する仕組みではなく、ネットワークも遮断しない。秘密情報を読まない規則は引き続き守る
- バージョンとモデル一覧の照会は、外側の sandbox を経由せず Grok を直接呼ぶ。`--self-test` は、本来読み取り専用の場所への書き込み拒否と、セッションの保存先への書き込みを確認する

### Codeg / エージェント同士で共同作業する / 手順 1〜4: 補足: 委譲と作業ディレクトリ

- Codeg の [Collaboration 設定](https://docs.codeg.app/reference/settings/collaboration)は、Claude Code の Codex・Grok プラグインとは別の委譲機能。Codeg の `codeg-mcp` が委譲のツールを接続中のエージェントへ渡す
- 設定の保存後に始めるエージェントへ適用される。最大の委譲深度 `1` では、委譲先からの追加の委譲を許さない。有効なエージェントが委譲先として表示される
- 最大の委譲深度 `1` でも、Codex は委譲先で自分の組み込みのサブエージェント（`spawn_agent`）を起動した。Codeg の委譲のツールを通らない
- 委譲先は親の作業ディレクトリを共有するのが既定で、別の worktree は自動では作られない。読み取り専用のレビューと、編集を行う担当の会話を分け、編集の担当ごとに worktree とブランチを明示する
- 「サブエージェント設定」のエージェントごとの既定値は、委譲先に使うモード・設定で、親の会話の権限モードを変更するものではない。親の会話のモードと、委譲先の起動時の設定は別に扱う
- Claude Code のエージェント既定の `Manual` では、委譲先の書き込みやコマンドの実行で承認を待ち、親も委譲の結果を待ち続ける。この用途では Claude Code を `Auto`、Codex を `Auto review` にする
- Claude Code の `Auto` では、作業フォルダーへの書き込みとコマンドが承認無しで通った。`Auto` が確認や拒否に回す場面は確かめていない
- Codex の `Auto review` は、サンドボックス（作業フォルダーへの書き込み、ネットワーク無し）の中の操作を承認無しで進め、外に出る操作を自動レビューに回す設定。外に出る操作が無かったので、自動レビューが許可・拒否する場面は確かめていない
- 確認が出ることや、自動審査が止めることを、安全の境界にしない（[注意点](../extra/codeg.md#委譲先のモードと自動承認)）
- Google Antigravity の ACP サーバーは、ファイル作成の書き先に `antigravity-cli\skills` を選んだ（[作業フォルダーと規則の制約](#codeg--windows-11-で-antigravity-を使う--補足-作業フォルダーと規則の制約)）。読み取りの作業だけを頼み、`Session Mode` は `Default` のままにする
- Windows 11 の Codeg では、親の Grok の `run_terminal_command` は cmd.exe で動く。PowerShell のコマンドは「内部コマンドまたは外部コマンド…として認識されていません」になった
- `cmd.exe /c "…"` は、`"` が `\"` として cmd.exe に渡って失敗した。`git commit -m "…"` は、メッセージが空白で分かれ、末尾に `"` の残った pathspec のエラーになった。`git commit -F` はメッセージをファイルから読むので、引数に `"` を書かずに済む
- 1 回目の Claude Code の委譲先は、自分の PowerShell のツールで `"` を含むコマンドを通した（Codeg の端末を通らない）。Codex の委譲先が自分のツールで `"` を通すかは確かめていない
- 親のシェルの注意を委譲先への依頼にも書くと、委譲先がコマンドを cmd.exe に渡した。Codex はそこで `"` を含むコマンドに一度失敗した

設定の保存と、各エージェントの組合せでの応答・承認は別に確認する。Windows 11 で Grok を親にした委譲とモードの確認範囲は、[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/codeg.md#付録-grok-を親にした委譲と委譲先の既定のモード2026-10-16-jst)に分ける。

### Codeg / Claude Code と Codex CLI を使う / 補足

「Codeg: Claude Code と Codex CLI を使う」（[AlmaLinux 10](../ai-agents.md#codeg-claude-code-と-codex-cli-を使う)・[Windows 11](../ai-agents.md#codeg-windows-11-で-claude-code-と-codex-cli-を使う)）は、構築済みの Codeg で使うエージェントを設定する任意の項。Caddy・アクセストークン・公開範囲は変えない。以下は 2026-10-12 に公式資料と Codeg v0.35.1 のソースを確認した内容。

### Codeg / Claude Code と Codex CLI を使う / 手順 2: 補足: 接続アダプターとランタイム

| エージェント | Codeg v0.35.1 の対応アダプター | アダプターが使うランタイム |
|---|---|---|
| Claude Code | `@agentclientprotocol/claude-agent-acp@0.89.1` | Claude Agent SDK `0.3.293` と、それに付属する Claude Code `2.1.293` |
| Codex | `@agentclientprotocol/codex-acp@2.2.2` | 依存する `@openai/codex`。今回の隔離導入では `0.160.1` |

- ACP は、Codeg の画面とエージェントをつなぐ通信の仕様。Claude Code・Codex は、それぞれの接続アダプターを介して動く
- Claude のアダプターは Node.js 22 以上、Codex は 20.3 以上が必要。両方を使うこの節では 22 以上にそろえる
- 初期設定で入れた CLI を置き換えるものではない。Codeg 用には別のランタイムが入り、同じ OS ユーザーのホームにあるログイン・設定・履歴を共有する。既存 CLI と Codeg 側の版は別に確認する
- Codex の依存指定は `^0.160.1`。同じアダプター版でも、導入時に入る Codex の版が変わり得る。Codeg の対応版を、すべての依存が固定されたものとは扱わない
- Codeg は npm のグローバル領域へ導入を試み、権限不足なら `~/.codeg/npm-global` を使う。アダプターの更新は、同じ実行ファイルを使うほかの ACP クライアントにも影響し得る

Codeg v0.35.2 の AlmaLinux 10 の実機では、Claude Code の推奨アダプターは `0.90.0`、Codex CLI は `2.2.2` と表示され、両方を入れて応答を確認した（[実機の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/codeg.md#付録-almalinux-10-で-claude-codecodexantigravity-を設定した記録2026-10-16-jst)）。

表の対応版は [Codeg v0.35.1 のレジストリ](https://github.com/spacering-net/codeg/blob/e21eb6b38eea9405cdfa3b2d99df216d101d1344/src-tauri/src/acp/registry.rs)で確認した。実際に導入した版と試験条件は[今回の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/codeg.md#付録-claude-codecodex-の操作手順の追加2026-10-12-jst)に分ける。

### Codeg / Claude Code と Codex CLI を使う / 手順 3: 補足: 本人の契約と共有設定

- Codeg の「公式サブスクリプション」は、Claude の既存の CLI ログイン、Codex の本人の ChatGPT ログインを使う方式。Codeg 用の API キーは追加しない（[Codeg の認証方式](https://docs.codeg.app/guide/authentication)）
- Claude の公式案内（2026-10-07 更新）では、Claude Agent SDK・`claude -p`・第三者のアプリを契約の利用枠で引き続き使える。この手順はその方式を使う（[Claude の契約での SDK 利用](https://support.claude.com/en/articles/15036540-use-the-claude-agent-sdk-with-your-claude-plan)）
- Codex の ChatGPT ログインは契約による利用、API キーのログインは API の従量課金として区別される。この手順は本人の ChatGPT の利用枠を消費する（[OpenAI の認証の説明](https://learn.chatgpt.com/docs/auth)）
- API キーを設定しないことは、外部へのモデル通信が無い・無料・無制限という意味ではない。利用枠に達した場合も、API キーを入れて回避する手順にはしない
- Codeg で Claude の設定を保存すると `~/.claude/settings.json`、Codex の設定を保存すると `~/.codex/config.toml` など、端末の CLI と共有する設定にも反映される。認証方法の変更では、以前の API 用の設定が削除・変更されることもある
- ログインのやり直しも同じユーザーの CLI に効く。別のアカウントへ切り替える操作は、Codeg の会話だけに閉じない（[共有設定と履歴の注意](../extra/codeg.md#claude-codecodex-の共有設定と履歴)）

### Codeg / Claude Code と Codex CLI を使う / 手順 4〜7: 補足: モードと中断

- Claude のアダプターが返すモードは `Manual`・`Accept edits`・`Plan`・`Auto`。環境・管理設定などで許可される場合にだけ `Bypass permissions` も出る。手順では `Auto` を選ぶ
- モデルが対応せず「Auto mode unavailable」になったときは、`Accept edits` に切り替わる実装がある
- `Accept edits` は `Auto` の確認完了と扱わない。手動運用を選ぶときは `Manual` に変える。`Auto` の可否は、最初の応答とモデルの変更後にも確かめる
- Codex のモードは `Read-only`・`Workspace access`・`Auto review`・`Full access`。手順では `Auto review` を使う
  - 2026-10-16 の AlmaLinux 10 の実機では初めから `Auto review` だった。ほかの環境では、既存の Codex 設定や Windows の sandbox の状態にも左右される
- 自動審査は、すべての操作への確認を省く指定ではない。審査結果に応じて確認・拒否が残る。停止ボタンを押しても、既に行ったファイル変更やコマンドの効果は巻き戻らない
- Claude Code を選んだとき、入力欄の下の並びは、左から Mode・Model・Effort・Fast mode（`On`・`Off`）・Agent（`Default` は標準の Claude Code）
  - 2026-10-16 の AlmaLinux 10 の実機では、初めのモード `Manual` を `Auto` に変え、`Opus 5.5` で応答を確認した
  - 画面に項目の名前は出ない。2026-10-14 の Windows 11 の実機では `Manual`・`Opus 5.5`・`Xhigh`・`Off`・`Default` と並んでいた
  - 項目の名前は、画面ではなく、Codeg が入れた `claude-agent-acp` 0.89.1 のソースで確かめた

表示名と切り替えの条件は、[Claude のモードの実装](https://github.com/agentclientprotocol/claude-agent-acp/blob/4e1fc1e8df2b9af3b1b2d6880ba90c5862283ba8/src/session-mode.ts)と [Codex のモードの実装](https://github.com/agentclientprotocol/codex-acp/blob/202e66e63343ec4f5a5e35ab590251d813d129ca/src/AgentMode.ts)で確認した。Codeg の画面での自動審査・拒否・中断の実測とは区別する。

### Codeg / Claude Code と Codex CLI を使う / 手順 8〜10: 補足: 履歴の取り込みと再開

- ブラウザで操作していても、取り込むのは Codeg のサーバーが動くホストの履歴。ブラウザを開く PC の履歴や、もう一方の OS の履歴は同期されない
- 一覧は、開いたフォルダだけでなく、このホストの各エージェント・各プロジェクトの履歴を走査する。全プロジェクトを対象にする場合も、一覧の作業ディレクトリごとに本人の終了済みセッションを選別する
- 「すべて選択」は、その時点の絞り込みに合う対象で選択を置き換える。Claude と Codex を順に取り込む場合は、エージェントごとに取り込みを終えてから絞り込みを切り替える。進行中の会話は自動で除外されない
- Codeg は元の会話の ID とエージェントを使って再開する。取り込みで元の CLI の履歴は削除されない。別のエージェントへ履歴を変換する操作ではない
- 履歴の取り込みと会話の再開は別の操作。取り込みだけなら、会話を開いて続きを送る必要はない
- Claude の再開では、元の会話のモードを引き継ぐ場合がある。続きを送る前に、表示中のモデル・モードを確かめ、今回使うものを選ぶ
- Codeg v0.35.1 の Codex の走査対象は、`CODEX_HOME` 配下の `sessions`。アーカイブ済みの `archived_sessions` は含まれない。必要な会話は元の Codex でアーカイブ解除してから再スキャンする（[Codex の走査対象](https://github.com/spacering-net/codeg/blob/e21eb6b38eea9405cdfa3b2d99df216d101d1344/src-tauri/src/parsers/codex.rs#L207)・[取り込み処理](https://github.com/spacering-net/codeg/blob/e21eb6b38eea9405cdfa3b2d99df216d101d1344/src-tauri/src/db/service/import_service.rs#L43)）
- 取り込み後に再度アーカイブすると、Codeg の表示や再開に影響する場合がある。取り込み後に自動で元の場所へ戻す手順にはしない
- 同じ会話を元の CLI・アプリと Codeg で同時に進めない。元の会話を閉じてから再開する。元の履歴が削除された、またはセッションが使えなくなった場合は、一覧にあっても再開できないことがある（[Codeg の会話の取り込み](https://docs.codeg.app/guide/aggregation)）

### Codeg / AlmaLinux 10 で Antigravity を使う / 手順 1: 補足: 仮想アドレスが 39 ビットの arm64

- Codeg の「Google Antigravity」は、Google の ACP サーバー `agy_acp_server` を使う。Antigravity CLI（`agy`）とは別の製品で、CLI が動いても ACP サーバーが動くことにはならない
- Antigravity CLI 1.0.4 より前の linux_arm64 版にも、39 ビットの仮想アドレスのカーネルで TCMalloc が起動時に落ちる報告がある。開発者は CLI 1.0.4 から標準の malloc に変えたと説明している（[antigravity-cli#64](https://github.com/google-antigravity/antigravity-cli/issues/64)・[CLI の補足](ai-agents.md#almalinux-10-で使う--antigravity-cli--手順-3-補足-仮想アドレスが-39-ビットの-arm64)）
- Raspberry Pi 5 の AlmaLinux 10.2（aarch64、`CONFIG_ARM64_VA_BITS_39=y`）では、ACP サーバーの 1.4.0 は使えない。起動時に TCMalloc で落ちた
  - 標準の malloc に変わって動く CLI とは状態が異なる（[実機の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/codeg.md#付録-almalinux-10-で-claude-codecodexantigravity-を設定した記録2026-10-16-jst)）
- 推奨版が 1.4.0 以外になったときの動作は確かめていない
- 非公式のバイナリの書き換えはせず、直った版を待つ。39 ビット以外のカーネルや x86_64 など、ほかの Linux では確かめていない

### Codeg / Windows 11 で Antigravity を使う / 補足: CLI と ACP サーバー

- [Windows 11 で Antigravity を使う](../ai-agents.md#codeg-windows-11-で-antigravity-を使う)では、Codeg 組み込みの「Google Antigravity」を使う
- Codeg の「バージョン状態」で示す対応版の、Google 純正 ACP サーバー `agy_acp_server` を使う。端末の CLI `agy` とは別の製品
- CLI のログインは資格情報マネージャーの `gemini:antigravity` にあり、ACP サーバーはそれを使わない
- Codeg 用のログインは `%USERPROFILE%\.gemini\antigravity-acp\acp_token.json` に保存される。ファイルの中身は読んでいない
- 非公式の ACP ラッパーは、利用規約上の注意があるため使わない
- 「ファイルとコマンドをエージェント自身に処理させる」をオフのままにするのは、オンにすると Codeg がファイル操作と端末を代行しなくなり、ほかのエージェントからの委譲も無効になるため（Codeg の設定の画面の説明）

### Codeg / Windows 11 で Antigravity を使う / 補足: サインインの方式

- 自動のサインインは接続のやり直しのたびにブラウザのタブを開き、5 分で時間切れになる。待っていた古い接続が時間切れで終わるときに、保存済みのトークンが消えた
- このため、「ブラウザのないマシンでサインイン」を使う。Antigravity の会話のタブを閉じて ACP サーバーを終了してから始めることで、古い接続の待ち手を残さない
- この PC では、利用者がブラウザで承認した戻り先を Codeg の待ち手が受け取り、トークンが保存された。後から「サインインを完了」に貼る操作で待ち時間切れの表示が出ても、サインインは済んでいた

### Codeg / Windows 11 で Antigravity を使う / 補足: 作業フォルダーと規則の制約

- Active Workspaces は `%USERPROFILE%\.gemini\antigravity-cli\skills`・`%USERPROFILE%\.gemini\config\skills`・作業フォルダーの順だった
- エージェントは先頭を作業フォルダーとみなし、ファイル作成の承認カードも `antigravity-cli\skills` の下を指した
- 会話のメタデータの `cwd` が正しくても、作業フォルダーの `AGENTS.md` は読み込まれなかった。共同作業の規則を自動で読む前提では使えない
- Codeg で未レビューの ACP サーバー 1.4.0 でも同じ制約があり、1.3.0 に戻した。同じ worktree の `agy -p` では、Active Workspaces はその worktree だけで、規則も読み込まれた
- Codeg から Claude Code が Antigravity へ委譲した場合も、作業ディレクトリは親と同じで、別の worktree は作られなかった。CLI の読み取り専用レビューとは分けて扱う

### Codeg / Windows 11 で Antigravity を使う / 補足: 初期化の待ち時間

- ACP サーバーは PyInstaller の onefile で、起動のたびに `%TEMP%\codeg-acp\<pid>-<id>\_MEI…` へ展開する。この初期化に時間がかかる
- Initialize の応答に 32〜56 秒かかり、60 秒の接続ハンドシェイクの制限を超えることもあった。1.4.0 の初回も同じで、その後の再接続で接続できた

### Codeg / 自動更新を有効にする / 手順 1: 補足: 安定版と画面の自己更新

- Codeg は常に最新の安定版を使う（2026-10-16、利用者の決定）。GitHub のリリース 50 件から、タグが `^v[0-9]+\.[0-9]+\.[0-9]+$` に一致し、`draft`・`prerelease` の両キーが存在して値が `false`、対象の配布物と `.sha256` がそろうものを選ぶ
- 版の数字は ASCII の `0`〜`9` に限る。数値の 3 要素で最大を取るので、公開の順や古い系列への追加パッチには左右されない。導入時と自動更新時の両 OS で、同じ選択条件を使う
- 画面の右下の「新バージョン」は通知として見る。画面からの自己更新ではなく、同じ照合・停止・起動確認・復元の条件を両 OS で管理できる専用のプログラムを使う。Windows 11 でも、画面から本体を入れ替えない
- ダウンロードした配布物の SHA-256 は、同じリリースの `.sha256` と、API の配布物の `digest`（`sha256:<hex>`）の両方に照合する。API に digest が無い配布物は `.sha256` だけと照合し、そのことをログへ残す。これは取得物の照合であり、リリースそのものへの署名の検証ではない
- 本体のディレクトリ内に `.codeg-upgrade-staged` や名前が `.bak` で終わる項目を見つけたら中断する。AlmaLinux 10 も `~/.local/opt/codeg-server/` の直下だけを調べる。別の更新が残す本体を、自動更新が上から入れ替えないため
- AlmaLinux 10 の API・配布物の取得は、最初の URL と転送先を HTTPS に限る。転送先のホスト名は固定せず、各転送先の方式を検査する
- Windows 11 のリリース JSON は `curl.exe --output` で一時ファイルへ保存し、UTF-8 を指定して読む。中国語や絵文字を含む本文を、コンソールの出力コードページで読み違えないため
- JSON の一時ファイルは、自動更新では状態の作業用フォルダー、導入では `$env:TEMP` に置き、取得や解析が失敗しても消す。HTTP の状態コードは ASCII のため、標準出力で受け取る
- AlmaLinux 10 は自動更新のロックに加え、パスワード変更と同じロックを取る。認証ファイルの変更中に Codeg を入れ替えない。トークンのファイルは、どちらの OS の自動更新も開かない

### Codeg / 自動更新を有効にする / 手順 1: 補足: 本体の版だけを調べる

- 本体へ渡す引数は `--version` だけにする。v0.35.1 の Windows 11 の実機で `--help` がサーバーを起動した（2026-10-16）。v0.35.2 のソースでは `--version` を起動処理より先に扱う
- 自動更新・復元プログラムの版確認では、想定どおりに終了しない版でも本人の DB・設定・トークンに触れないよう、データ・ホーム・一時ファイル・XDG の場所を使い捨てのディレクトリへ向ける。Windows 11 は `USERPROFILE`・`APPDATA`・`LOCALAPPDATA` も置き換える
- 待ち受けは localhost の空いているポート、トークンは使い捨ての乱数にし、追加のブリッジとブラウザのトンネルを無効にする。親の `CODEG_TOKEN` は引き継がない
- 10 秒以内に終わらなければ、AlmaLinux 10 はプロセスグループ、Windows 11 はプロセスの木を終了する。標準出力の `X.Y.Z` の行だけを版とし、トークンが出る可能性のある標準エラーは捨てる
- Windows 11 の開始合図は ASCII のバイト列、環境の JSON は UTF-8 の Base64 として標準入力へ渡す。中継はバイトで読み、先頭の UTF-8 BOM を除く。コンソールの入力エンコーディングで合図や日本語のパスが変わらないようにする

### Codeg / 自動更新を有効にする / 手順 1: 補足: 停止と起動の確認

- 取得・ハッシュの照合・アーカイブの検査・展開・新しい本体の版・空き容量の確認を、Codeg を止める前に済ませる。ネットワークの失敗や不正な配布物で、動いている Codeg を止めないため
- アーカイブは通常のファイルとディレクトリだけを受け入れる。展開先を外れるパス・リンク・デバイスを拒み、同じファイルシステムまたはボリューム上で本体を入れ替える
- 起動確認は、待ち受けの所有者が配置した本体であることと、HTTP の `/` が 200、`/api/version` が 401 であることを組み合わせる。プロキシを通さず、認証トークンを使わない。認証なしの画面と、保護された API の両方が動くことを確かめる
- `/health` や `/healthz` の 200 は、画面の SPA が返るだけだった（2026-10-16、Windows 11 の v0.35.1）。健康確認には使わない
- 30 秒続けて正常であることを、最大 120 秒待つ。AlmaLinux 10 はサービスの `ActiveState` と `NRestarts` も照合し、再起動の繰り返しを成功にしない
- Windows 11 は `Stopwatch` で最大 120 秒と安定した 30 秒を測る。タスクが `Running` でない、既に確認した待ち受けの PID・開始時刻が変わる、本体の版が一致しない場合は、その場で失敗とする

### Codeg / 自動更新を有効にする / 手順 3: 補足: 専用ログ

- 両 OS のプログラムは、状態のディレクトリの `codeg-auto-update.log` に追記する。AlmaLinux 10 は `~/.local/state/codeg-auto-update/`、Windows 11 は `%LOCALAPPDATA%\codeg-auto-update\` に置く。AlmaLinux 10 は標準出力への表示も続ける
- ログは UTF-8 で、各行の先頭に UTC の ISO 8601 の日時を付ける。1 MB を超えたら `codeg-auto-update.log.1` へ回し、現行と合わせて 2 世代を保持する
- AlmaLinux 10 は本人の journal を読めない環境でも、専用ログの末尾で結果を確認できる。Windows 11 の隠しランチャーは標準出力と標準エラーを捨てるので、タスクからの実行結果も専用ログで確認する
- Windows 11 はログ本体と `.1` の再解析ポイントを拒み、リンク先へ追記・退避しない。初回にログを開けなければ、操作前に終了コード 1 で中断する
- Windows 11 の処理開始後にログへ書き込めない場合は、標準出力へ警告を出す。更新済みの 0・巻き戻し済みの 2 など、更新・復元の終了コードをログの失敗で上書きしない

### Codeg / 更新 / 手順 2: 補足: 本体と DB を一緒に戻す

- Codeg は起動時に DB を移行する。本体だけを旧版へ戻すと、その版で読めない DB が残ることがあるため、停止してから本体と同じ時点の DB を退避する
- DB の対象は `codeg.db*` の全通常ファイル。`codeg.db`・`-wal`・`-shm`・`-journal` と、存在するロックファイルもまとめて扱う。復元前に新しい版が作った対象を全部退かし、旧 DB に新しい WAL を残さない
- Windows 11 は DB を退避・復元するとき、コピーした各ファイルで `Flush(true)` を呼んで書き込みを完了する
- 自動の復元で通るのは、旧版でも同じ起動確認が成功した場合だけ。成功なら終了コード 2、確認できなければ 3 とし、控えと `in-progress` を残す。途中で止まった実行は、次回も終了コード 3 で止めて復旧を促す
- 正常な更新の控えは新しい 2 世代を保持する。`failed-*` は調査と復元用に残し、自動では消さない。控えを戻すと更新後の会話が失われるため、画面で会話の一覧や再開も確かめる

### Codeg / 自動更新の控えから前の版と DB に戻す / 手順 3: 補足: 復元プログラム

- [AlmaLinux 10 の復旧](../extra/codeg.md#almalinux-10-で自動更新の控えから前の版と-db-に戻す)は `codeg-auto-update --restore <控え名> --hold <問題版>`、[Windows 11 の復旧](../extra/codeg.md#windows-11-で自動更新の控えから前の版と-db-に戻す)はスクリプトの `-Restore` と `-Hold` で行う。停止・本体と DB の復元・旧版の起動確認を同じプログラムにまとめる
- 控え名・保留する版・`in-progress` の段階と記録・本体の配置・排他を、停止前に照合する。不一致は何も変えずに終了コード 1 にする
- ファイルを移す前の停止に失敗した場合は、停止前の現行版を起動し直して同じ起動確認を行う。再開できれば目印を解除して終了コード 1。通常の復元では停止前の現行版、元 DB を保持する復元では旧版を再開する
- 元の本体を再開できない場合や、ファイルを移し始めてから復元・起動確認に失敗した場合は、退避物と目印を保全して終了コード 3 にする
- 通常の控えを戻すときは、現在の本体と全 `codeg.db*` を `failed-manual-<UTC日時>` へ退避してから、控えの本体と DB を戻す。`backing-up` と、本体・DB を変える前の再開失敗を記録する `restart-failed` は、元の DB を保持して旧本体だけを揃える。部分的な DB 控えは使わない
- 旧版でも、自動更新と同じ待ち受け・HTTP・30 秒の安定した起動・本体の版を確認する。通った場合だけ問題の版を保留し、`in-progress` を解除して終了コード 0 にする。タイマーやタスクの再開は、ブラウザで会話を確かめてから行う

### Codeg / 自動更新を有効にする / 手順 2〜3: 補足: 毎日の時刻と会話の切断

- AlmaLinux 10 は毎日 04:30 から最大 30 分ずらして実行する。Forgejo の 04:00 から最大 30 分の更新と時間帯を分ける
- 更新中は Codeg が数十秒止まり、動いている会話は切れる。利用者はこの動きを受け入れ、常に最新の安定版を使うことを選んだ（2026-10-16）
- Codeg を意図して止めている間は更新しない。取得した版は起動中のサービスだけに反映し、停止中の本体や DB を変更しない

### Codeg / Windows 11 で自動更新を有効にする / 手順 2〜3: 補足: タスクとログ

- 毎日 04:30 のトリガーに `StartWhenAvailable` を付け、スリープなどで逃した更新は起きて実行可能になった後に行う。`RunOnlyIfNetworkAvailable` でネットワークが利用できるときに動かす。実行には本人のサインインが必要
- `WakeToRun` は付けない。更新のために眠っているノート PC を起こさない。`AtLogOn` も付けず、ログオンのたびに毎日の予定とは別の更新を始めない。取り逃した分は `StartWhenAvailable` で扱う
- バッテリーでの開始を許し、バッテリーへ切り替わっても途中で止めない。入れ替えの途中で止まる機会を減らすため。1 時間の実行時間制限と `MultipleInstances IgnoreNew` で長時間の滞留と重複を制限する
- `codeg-server` と同じ本人・`Interactive`・`Limited` のプリンシパルで、既存の隠しランチャーへ自動更新スクリプトのパス 1 つを渡す。ランチャーは標準出力と標準エラーを捨てるため、スクリプトが UTF-8 の専用ログへ日時付きで追記する
- ログは共通の[専用ログの形式](#codeg--自動更新を有効にする--手順-3-補足-専用ログ)で記録する。タスクにはランチャーを通してスクリプトの終了コードが返る

## Claude Code・Codex を遠隔操作する OSS の比較

Codeg は、Grok Build・Claude Code・Codex CLI・Google Antigravity などを同じチャットの画面から動かせる。2026-10-12 に Claude Code・Codex を遠隔操作する OSS の公式資料と実装を比較し、Linux arm64 と Windows の配布物があり、複数のエージェントで HTTPS の構成を共用できる Codeg を選んだ。CloudCLI と Happy の導入・実機での操作は試していない。既存の表にある Happier と、ここで比べる Happy は別のツール。

| ツール | ライセンス | 向く用途・今回の判断 |
|---|---|---|
| Codeg | Apache-2.0 | Claude Code・Codex を同じ画面から操作でき、Linux arm64 と Windows の配布物がある。既存の HTTPS 構成を使えるので、今回の手順に採用する |
| CloudCLI（Claude Code UI） | AGPL-3.0-or-later | Claude・Codex の Web UI を簡単に用意したい場合の候補。Codex のチャットは SDK の非対話実行で、対話的な承認要求に答える操作に制約がある |
| Happy | MIT | スマートフォンや Web からの遠隔操作が中心。標準では外部の relay を使う。従来の CLI は保守モードで、新機能は desktop へ移っているため、今回の主手順にはしない |

- CloudCLI の [Codex の実装（確認したコミット）](https://github.com/siteboon/claudecodeui/blob/7c3049fe8e157f12b7add3e496d8d2fe6fa5c014/server/modules/providers/list/codex/codex-runtime.provider.ts#L247)には、`exec` から対話的な承認要求へ許可を返せないと記載がある。今回の承認・拒否を含む用途では、この制約を先に確かめる必要がある
- Happy は [CLI の relay の説明](https://github.com/slopus/happy/blob/99f415fa0d12d233a80a77fd88122bfb19b17477/packages/happy-cli/README.md#L128)と[公式案内](https://happy.engineering/docs/)を確認した。self-host もできるが、中継サーバーの準備と保守が追加で必要になる
- OSS なのは画面・接続ツール。Claude・ChatGPT のサービスを無料・無制限で使えるという意味ではない

## 方法のまとめ

Codeg は、使うエージェントと同じホストにサーバーを置き、ブラウザから複数の ACP エージェントを選んで動かす。この構成と、Grok Build を遠隔操作するほかの方法を比べた（2026-10-11 時点）。「この手順書」の列が「採った」のものを、手順書で手順にした。

| 目的 | 方法 | この手順書 | 要るもの・制約 |
|---|---|---|---|
| 複数のエージェントを画面から動かす | Codeg のサーバー（`codeg-server`）を使うエージェントと同じホストに置き、ブラウザで開く | 採った | Apache-2.0。Grok Build・Claude Code・Codex CLI・Google Antigravity などに対応する。Linux の x64・arm64 と Windows の x64 の配布物がある。外部のサーバーを通らない。Codeg 自身は TLS を持たない |
| 画面から Grok Build を動かす | Paseo のデーモンを同じホストに置く | 採らない（Codeg が動かなかったときの代わりとして調べた） | Apache-2.0。Grok は ACP のカタログの扱い。Windows で端末のコマンドの引用が壊れる不具合の報告（#5947）がある。実機では試していない |
| 画面から Grok Build を動かす | Grok UI | 採らない | MIT。Grok Build 専用だが、Windows と aarch64 の対応が文書に無い。個人の小規模なプロジェクト |
| 画面から Grok Build を動かす | Happier | 採らない | MIT。Web の画面に HTTPS が必須。プッシュ通知が第三者（Expo）を通る。Grok ではセッションの一覧が使えない |
| 画面から Grok Build を動かす | Zed の外部エージェント（SSH のリモート） | 採らない | PC のデスクトップアプリだけ。スマートフォンから使えない |
| 画面から Grok Build を動かす | Grok Build の `grok agent serve` に直接つなぐ | 採らない | つなぎ方の仕様が公式の文書に無い。公式の例は always-approve 付き |
| 端末をそのまま使う | SSH のアプリと tmux | 採らない（[共同作業の手順書](../ai-agents.md#コーディングエージェントの共同作業-スマートフォンから指示する)にある） | 画面で扱いたい、という目的に合わない。AlmaLinux 10 だけ |
| 端末をそのまま使う | ttyd などの Web の端末 | 採らない | 端末がそのままブラウザに出る。スマートフォンで Ctrl・Esc・矢印が打ちにくい |
| 端末をそのまま使う | zellij の Web クライアント | 採らない | Windows 版に未解決の不具合がある（[Claude Code の Remote Control（Windows）の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-claude-remote-control.md)） |
| Codeg の置き方 | 最新の安定版の配布物を取得して SHA-256 を照合し、ホームに置く | 採った | 毎日自動で更新する。`sudo` を使わない |
| Codeg の置き方 | 公式のインストーラー（`curl … \| bash`・`irm … \| iex`） | 採らない | SHA-256 を照合しない。`/usr/local` に置く（Linux） |
| Codeg の置き方 | 公式の Docker イメージ | 採らない | コンテナの中で動くので、ホストのエージェントのログイン・Git・道具をそのまま使えない |
| Codeg の置き方（Windows 11） | Codeg のデスクトップアプリの「Web サービス」 | 採らない | すべての NIC で待ち受ける。待ち受ける IP を選べない |
| 常駐（AlmaLinux 10） | systemd のユーザーサービスと linger | 採った | Codeg はユニットを同梱しない |
| 常駐（Windows 11） | タスク スケジューラ（サインイン中、管理者ではない権限） | 採った | SSH のセッションから始めると管理者の権限で動くので、タスクにした |
| つなぐ側 | ブラウザ | 採った | スマートフォンと PC で同じ画面 |
| つなぐ側 | Codeg のデスクトップアプリ（リモートのワークスペース） | 採らない（確かめていない） | Windows の署名が無い。サーバーの `CODEG_BROWSER_TUNNEL` を見直す必要がある |
| つなぐ側 | Codeg の Android のアプリ | 採らない（確かめていない） | Apache-2.0。APK を GitHub から入れる。testing の段階 |
| 経路（AlmaLinux 10） | LAN と VPN の、指定した帯だけに開ける | 採った | 送信元を CIDR で絞る（複数を並べられる）。はじめは VPN の帯だけにしていたが、LAN からも使うために広げた |
| 経路（Windows 11） | Private の全送信元・全接続種別に開ける | 採った | IPv4・IPv6 と、有線 LAN・Wi-Fi・VPN を区別しない。Public・Domain と Edge Traversal は遮断する（利用者の指定） |
| 通信の暗号化 | AlmaLinux 10 はホスト共通の Caddy が HTTPS で受けて Codeg へ渡す（Windows 11 は専用）。証明書は Caddy の認証局（`tls internal`） | 採った | Apache-2.0。ドメインも外部のサービスも要らない。端末にルート証明書を入れる |
| 通信の暗号化 | 公的な証明書（Let's Encrypt の DNS-01） | 採らない | 自分のドメインと、DNS 事業者の API トークンが要る |
| 通信の暗号化 | HTTP のまま使う | 採らない（はじめの形） | VPN の区間しか暗号化されない。LAN の区間は、トークンも平文で流れる |
| 通信の暗号化 | ルート証明書を入れず、ブラウザの警告を進んで使う | 採らない | 暗号化はされるが、相手が本物かを確かめられない |
| Caddy の置き方 | AlmaLinux 10 はホスト共通の本体・認証局・サービスを使う。Windows 11 は Codeg 専用の配置 | 採った | 置き場所が版で変わらない。`sudo` を使わない |
| Caddy の置き方 | EPEL・Homebrew・scoop | 採らない | scoop は版ごとにディレクトリが変わり、Windows の受信の規則をプログラムに限れない |
| 経路 | インターネットへ公開する | 採らない | トークン 1 つが、ホストでコマンドを実行できる鍵になる |

## 選択した方針

- Codeg は、ACP で動く複数のコーディングエージェントを使う Web UI として書く（2026-10-16、利用者の決定）
  - Grok Build・Claude Code・Codex CLI・Google Antigravity などを、ブラウザやスマートフォンのチャットの画面から動かす OSS
  - サーバーは使うエージェントと同じホストに置く
- 任意の構成として、サーバーの導入後に使うエージェントの項を選ぶ。Raspberry Pi 5 の AlmaLinux 10 では、仮想アドレスが 39 ビットの arm64 のカーネルで Antigravity の ACP サーバーの 1.4.0 は使えない。推奨版がほかの版になったときの動作は確かめていない
- Codeg は常に自動で最新の安定版にする（2026-10-16、利用者の決定）。両 OS とも毎日確認し、照合して準備してから入れ替える。失敗時は本体と DB を戻してその版を保留する。更新中の数十秒の停止と会話の切断は受け入れる。Caddy の更新は対象外
- Grok Build に、Claude Code の Remote Control に当たる公式の遠隔操作の画面が無いことも、Codeg を選んだ理由の 1 つ
  - Grok Build は ACP（Agent Client Protocol）のエージェントとして動かせる（`grok agent stdio`）
- 画面は、端末をそのまま映すものではなく、会話・承認・変更されたファイルを扱うチャット形式のものにする（利用者の指定）
- Grok Build を使うときは、Codeg から Grok Build 自身のセッションの置き場（`~/.grok/sessions`）を使う。端末の `grok` で始めた会話を取り込めて、Codeg で作った会話は `grok sessions list` に出る
- Grok Build を使うときは、既存の Grok Build（`~/.grok/bin/grok`）とログインをそのまま使う。Codeg からは Grok Build を入れ替えない
- まず localhost で起動して確かめ、それから公開する。AlmaLinux 10 は待ち受ける IP と送信元を絞る（[Forgejo](../forgejo.md#forgejo) と同じ順）
- Windows 11 の PC は待ち受ける IP を決めない。利用者の指定で、受信インターフェースが Private なら全送信元・全接続種別を許可し、Public・Domain は遮断する。送信元 CIDR と有線限定は使わない
- 外に出す口は HTTPS だけにする（利用者の指定）。Codeg は `127.0.0.1` のままにし、AlmaLinux 10 はホスト共通の Caddy が TLS を受け持つ（Windows 11 は専用）。証明書は Caddy の認証局で作り、端末にルート証明書を入れて、警告なしで開く
- 認証局はホストごとに別で、AlmaLinux 10 は Forgejo などと共有する。端末に入れるルート証明書は同じホストに 1 つ。鍵は Caddy が作り、エージェントは読まない
- トークンは、エージェントに作らせず・読ませず、利用者が作る。確認は、値を表示しないコマンドで行う
- 利用者の指定で、Grok Build の承認を減らして使う用途にはスマート自動承認（`auto`）を選ぶ。Grok の審査で確認や拒否になる操作は残る。確認が出ることを安全の境界にはしない（`mkdir` は確認なしで実行された）
- 両 OS の操作は AI エージェントの手順書の OS 別の項で扱う（[AlmaLinux 10](../ai-agents.md#codeg-almalinux-10-で使う)・[Windows 11](../ai-agents.md#codeg-windows-11-で使う)）

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
