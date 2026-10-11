# Grok Build をブラウザから操作する手順（Codeg と Caddy）の検証記録

[手順書](../grok-build-remote.md)・[ロールバックと注意点](../extra/grok-build-remote.md)・[参考資料](../reference/grok-build-remote.md)

## 対象と検証環境

共同レビュー後に変えた部分の確認範囲は、末尾の「PR #132 の共同レビューでの修正と静的確認」に記録する。その修正の確認と、Windows 11 を IP が変わっても使える形にした変更は、その次の付録に記録する。変更後の更新・ロールバックを、実機で通した結果はまだ無い。以前の記録の手順番号は、実施当時の番号として残す。

- **状態（AlmaLinux 10。2026-10-11 JST）**: Raspberry Pi 5 の AlmaLinux 10.2 / aarch64 に Codeg の `codeg-server` v0.35.0 を入れ、localhost での起動、ブラウザからの Grok Build の操作、VPN への公開、スマートフォンからの操作、v0.35.1 への更新、送信元への LAN の帯の追加、Caddy 2.11.7 での HTTPS への切り替えを通した。詳細は末尾の付録
  - 通したこと: 「Codeg のサーバーを入れて localhost で起動する」の手順 2〜7、「ブラウザで開いて Grok を動かす」の手順 1〜3・5〜7、「HTTPS で LAN・VPN に公開する」の手順 1〜8、「端末にルート証明書を入れる」の手順 1・3〜6、「端末の grok のセッションを取り込む」の手順 1〜3、「更新」の手順 2〜4 に当たる操作
  - 公開の順は、手順書と違う。はじめは HTTP のまま VPN の帯だけに公開し（そのときの手順書の形）、その後に LAN の帯を足し、最後に HTTPS へ切り替えた。手順書は、はじめから HTTPS で公開する形に書き直してある
  - 確認したこと: aarch64 の配布物の SHA-256 と起動、ユーザーサービスと linger、SELinux Enforcing で拒否が無いこと、待ち受ける IP、トークン無しの拒否、トークンが journal・プロセスの一覧・Codeg のログ・DB に出ないこと
  - 確認したこと: 既存の Grok Build 1.0.50 での会話、承認の確認（ファイルの作成と `rm`）への許可と拒否、`mkdir` が確認なしで実行されること、端末のセッションの取り込みと継続
  - 確認したこと: firewalld の runtime / permanent の rich rule、許可していない送信元（LAN の PC。LAN の帯を足す前）からの拒否、サービスの再起動と更新の後に会話が残ること
  - 確認したこと: Caddy の配布物の SHA-512、TLS 1.3 と IP アドレス宛ての証明書、ルート証明書での検証、信頼していない相手としての検証の失敗、HTTPS 越しのトークンの確認、以前の HTTP が外から届かないこと
  - 利用者が確認したこと: スマートフォン（Android）で WireGuard を張り、ブラウザで開いてログインし、Grok に指示を送れた（HTTP の時点）。HTTPS にした後、スマートフォンと Windows の PC にルート証明書を入れて、問題なく使えた。エージェントによる端末の直接操作ではなく、利用者の報告として記録する
  - **確認していないこと**: すべてのセッションを閉じた後の稼働、OS の再起動の後の自動起動、x86_64、ロールバック、権限モードの設定の画面（Windows 11 のホストの画面でだけ操作した）、もう一方の拠点の LAN の帯からの接続、サーバーの証明書の期限（12 時間）をまたいだ後の動き、Caddy の更新

- **Windows 11 では（2026-10-11 JST）**: Windows 11 Pro（x64）の PC に同じ v0.35.0 を入れ、タスク スケジューラでの起動、ブラウザからの Grok Build の操作、権限モードの切り替え、VPN への公開、スマートフォンからの操作、v0.35.1 への更新、送信元への LAN の帯の追加、Caddy 2.11.7 での HTTPS への切り替えを通した。詳細は末尾の付録
  - 共同レビュー後の変更: パスの引用、Caddy の再試行、Codeg の子プロセスだけを止める形は、末尾の「PR #132 の共同レビューでの修正と静的確認」で静的検査とモック検査を行った。修正した停止・更新・ロールバックと、サインイン後の再試行を実機で通したわけではない
  - その後の変更（同日）: 再試行は、使い捨てのタスクで働かないことを確かめて外した。Caddy が待ち受ける IP を決めない形にし、受信の規則を 3 本にして、この PC を入れ替えた。有線 LAN から届くことと、VPN のアドレス宛てには届かないことを確かめた。再起動してサインインした後に 2 つのタスクが始まることも確かめた。詳細は末尾の付録
  - 通したこと: 「Windows 11 で Codeg のサーバーを入れて起動する」の手順 3〜9、「Windows 11 で HTTPS で LAN・VPN に公開する」の手順 1〜8、「端末にルート証明書を入れる」の手順 2〜6、「Windows 11 で止める・もう一度始める」の手順 1・2、「Windows 11 の更新」の手順 2・3 に当たる操作。公開の順は、AlmaLinux 10 と同じく手順書と違う（HTTP → LAN の帯を追加 → HTTPS）
  - 確認したこと: 配布物の SHA-256、タスクが管理者ではない権限・デスクトップのセッションで動くこと、待ち受ける IP、トークン無しの拒否、受信の規則が 1 本だけであること、許可していない送信元（LAN のサーバー）からの拒否
  - 確認したこと: Grok Build 1.0.46 と 1.0.50 での会話、権限モード「常に許可」と「毎回確認」の違い、Codeg の設定が `config.toml` を書き換えること、端末のセッションの取り込みと継続
  - 確認したこと: Caddy の配布物の SHA-512、Caddy のタスクが管理者ではない権限・デスクトップのセッションで動くこと、受信の規則が `caddy.exe` 宛ての 1 本だけであること、IP アドレス宛ての証明書、以前の HTTP が外から届かないこと
  - 利用者が確認したこと: トークンの作成（値はエージェントに渡していない）、受信の規則の追加と入れ替え、スマートフォンからのログインと指示。Windows 側のトークンは、SSH 経由の `qrencode` の QR コードで渡した。HTTPS にした後、スマートフォンと、この PC 自身に、ルート証明書を入れて、問題なく使えた
  - **確認していないこと**: サインアウト・再起動の後の自動起動、ロック・RDP の切断の後の稼働、Windows PowerShell 5.1 での実行（検証は PowerShell 7 で行った。5.1 では、構文の解析と、3 つのブロックの動きだけを確かめた）、ロールバック、arm64 の Windows、Caddy の更新

- **手順書のブロックの形について**: 検証では、同じコマンドを、値を直接書いた形や、複数の手順をまとめた形で実行した。手順書の変数つきのブロックを、そのままの形で上から通してはいない。ブロックは、下の「文書の静的な確認」で構文を確かめた
- **確かめていない機能**: Codeg のデスクトップアプリ・Android のアプリからの接続、Codeg の画面からの入れ替え（Software Update）、Grok Build 以外のエージェント、AlmaLinux 10 の PC（つなぐ側）へのルート証明書の取り込み

### 検証環境

| 項目 | AlmaLinux 10 | Windows 11 |
|---|---|---|
| 実施日 | 2026-10-11 JST | 2026-10-11 JST |
| ホスト | Raspberry Pi 5 Model B Rev 1.0、AlmaLinux 10.2、aarch64 | Windows 11 Pro ビルド 26300、AMD64 |
| Codeg | `codeg-server` v0.35.0 → v0.35.1 | `codeg-server` v0.35.0 → v0.35.1 |
| Caddy | v2.11.7（`caddy_2.11.7_linux_arm64.tar.gz`） | v2.11.7（`caddy_2.11.7_windows_amd64.zip`） |
| Grok Build | 1.0.50 | 1.0.46 → 1.0.50 |
| Node.js | v22.23.2 | v26.10.0 |
| 常駐 | systemd のユーザーサービス、`Linger=yes` | タスク スケジューラ（`Interactive`・`Limited`） |
| ファイアウォール | firewalld、`public` ゾーン、SELinux は Enforcing | Windows Defender ファイアウォール、`Private` |
| つないだ端末 | Windows 11 の PC のブラウザ（SSH のトンネル。HTTPS にした後は LAN から）、Android のスマートフォン（WireGuard） | この PC のブラウザ、Android のスマートフォン（WireGuard） |

> [!NOTE]
> 出力・接続先は `<USER>`・`<HOST>`・`<SERVER_IP>`・`<PC_IP>`・`<ALLOW_FROM>`・`<TOKEN>`・`<UUID>`・`<PROJECT_DIR>` などで表す。アクセストークンの値は、エージェントは読まず、記録もしていない（長さ・権限・含まれるかどうかだけを確かめた）。画面の操作は、利用者がブラウザにトークンを入れた後、利用者の了承を得てエージェントが行った。

### 実施前の状態

- どちらのホストにも、Codeg の配置先・データ・ユニット（タスク）・規則は無く、3080〜3090 番の待ち受けも無かった
- Grok Build は、どちらも公式のインストーラーで入れてログイン済みだった

### 完了時点の状態

- どちらのホストも、Codeg v0.35.1 が `127.0.0.1:3080` で、Caddy v2.11.7 がホストの IPv4 の 3443 番（HTTPS）で常駐している。外から届くのは 3443/tcp だけで、送信元は、VPN のクライアントの帯と、2 つの拠点の LAN の帯の、3 つに絞ってある
- スマートフォンと Windows 11 の PC に、2 台のホストのルート証明書が入っている
- Windows 11 の Grok Build の `config.toml` は、検証の前と同じ内容に戻した（SHA-256 の一致を確かめた）
- 試験用のプロジェクト（AlmaLinux 10 は `~/codeg-test-project`、Windows 11 はエージェントの作業用の場所）と、その会話が残っている

## 付録: Windows 11 の PC での検証（2026-10-11 JST）

### 対象と実施前の状態

| 項目 | 値 |
|---|---|
| ホスト | Windows 11 Pro ビルド 26300、AMD64。LAN の接続は `Private` |
| Codeg | `codeg-server` v0.35.0（`codeg-server-windows-x64.zip`、58,111,224 バイト） |
| 配布物の SHA-256 | `866f359b948b684c7f75a8326d5a9d9cc984ead5f2ea249b6a1bde346b2d498d` |
| Grok Build | `%USERPROFILE%\.grok\bin\grok.exe`。はじめは `grok 1.0.46 (2765805b9442) [stable]`、途中で `grok 1.0.50 (c58f321264ba) [stable]` に更新した（下の「Grok Build を 1.0.50 に更新してからの再確認」） |
| Node.js | v26.10.0（scoop） |
| ブラウザ | Claude のデスクトップアプリの組み込みブラウザ（この PC 自身から `127.0.0.1` を開いた） |
| 実行したシェル | 管理者でない PowerShell（整合性レベル Medium） |

- 実施前に Codeg の配置先・データ・タスクは無く、3080〜3090 番の待ち受けも無かった
- Grok の `%USERPROFILE%\.grok\config.toml` は `[ui] permission_mode = "always-approve"` だった（利用者の設定）
- 別の端末（LAN・VPN・スマートフォン）からの接続は、この付録の範囲に含めない

### 配布物の取得と照合

- `gh release download v0.35.0 -R spacering-net/codeg` で zip と `.sha256` を取得した
- `Get-FileHash` の値は、GitHub のリリースが記録する digest と `.sha256` の両方に一致した
- zip の中身は `codeg-server.exe`・`codeg-mcp.exe`・`codeg-computer-helper.exe` と `web`（1051 ファイル）。3 つの exe は Authenticode の署名が無い（`NotSigned`）
- 公式の `install.ps1` は SHA-256 を照合せず、`%LOCALAPPDATA%\codeg-server` に置いて利用者の PATH に足す（スクリプトを読んで確かめた。実行はしていない）

### 配置と起動用のスクリプト

- `%LOCALAPPDATA%\codeg-server` に `codeg-server.exe`・`codeg-mcp.exe`・`web` を置いた。`codeg-computer-helper.exe` は置かず、PATH は変えていない
- `codeg-server.exe --version` は `0.35.0`（終了コード 0）。`codeg-mcp.exe --version` は `unknown arg` で終了コード 2
- トークンは利用者が作った。`token.txt` は 64 文字の 16 進で、ACL は利用者だけの `Modify`（継承なし）
- 起動用のスクリプトは、`token.txt` が無いと `abort: token file not found` を出して終了コード 1 で止まった

### 起動と待ち受け

- 待ち受けは `127.0.0.1:3080` だけ。起動の出力に `Port bridge for dev servers: off` と `Listening on: http://127.0.0.1:3080` が出た
- **`CODEG_TOKEN` を指定していても、標準エラーに `[SERVER] Token: <TOKEN>` の 1 行が出た**。公式の文書の「自分で指定すれば出ない」と違う
- Codeg 自身のログ（`%APPDATA%\codeg\logs\codeg-server.<日付>.log`、JSON の行）と `codeg.db` には、トークンは含まれなかった。どのプロセスのコマンドラインにも含まれなかった
- 初回の起動で `%APPDATA%\codeg`（`codeg.db`・`logs`）と `%USERPROFILE%\.codeg\skills`（156 ファイル）ができた
- `GET /` と `GET /login` は、トークン無しで HTTP 200（画面の静的なファイル）
- `POST /api/health` は、トークン無しと誤ったトークンで HTTP 401、正しいトークンで HTTP 200 の `{"status":"ok","version":"0.35.0"}`
- 応答に `Access-Control-Allow-Origin: *` が付く。別のオリジンからのプリフライトにも、メソッドとヘッダを `*` で許す応答を返した

### ブラウザで開いて Grok を動かす

- ログインの画面は日本語（「アクセストークン」の入力欄と「接続」）。利用者がトークンを入れた。以後の画面の操作は、利用者の了承を得てエージェントが行った
- 「フォルダを開く」は、サーバー側のファイルシステムをたどる。パスの入力欄に `<PROJECT_DIR>` を入れて開けた
- エージェントの一覧で Grok を選ぶと「エージェント接続: 接続済み」になり、モデルと推論の強さの選択が出た。追加の導入は要らなかった
- Codeg が起動した Grok は `"…\.grok\bin\grok.exe" --no-auto-update --permission-mode bypassPermissions agent stdio`
- Grok の子に `codeg-mcp.exe` が動く。引数は `--socket-path \\.\pipe\codeg-delegation-<PID> --token <UUID> --features ask,sessions`（この内部用の値は、プロセスの一覧に見える）
- 「hello.txt を作り 1 行書く」指示で、会話に「ファイルを 1 回編集」「変更されたファイル +1 -0」が出て、ファイルが作られた。承認の確認は出なかった
- この最初の会話は、モデルの欄が「Grok 4.6」だった。2 つ目以降の会話は「Grok 4.7」になった（サーバー側の付録の「最初の会話のモデル」と同じ現れ方）
- 作ったセッションは、同じディレクトリの `grok sessions list` に出た

### 権限モードと承認の確認

- 設定 → エージェント → Grok の「権限モード」は「デフォルトを使用／毎回確認／編集を自動承認／スマート自動承認／常に許可」。開いた時点では「常に許可」
- 「毎回確認」にして保存すると、`config.toml` の `permission_mode` が `"default"` になった（変わったのはこの 1 行だけ）。画面に「既存のセッションは再接続すると変更が適用されます」と出た
- 新しい会話の Grok は `grok.exe --no-auto-update agent stdio`（`--permission-mode` なし）で起動した
- ファイルの書き込みは、承認の確認が出た。見出しは「Write `<パス>`」、差分つき。選択肢は「Yes, allow all edits during this session」「Yes」「No, and tell Grok what to do differently」。「Yes」で実行された
- **`mkdir sample-dir` は、承認の確認なしで実行された**。Codeg のログには、承認の要求は書き込みの 1 件しか無い（Grok が要求を出していない）
- 「ファイルとコマンドをエージェント自身に処理させる」を有効（環境変数は `CODEG_ACP_HOST_TOOLS=agent`）にした新しい会話でも、`mkdir sample-dir2` は確認なしで実行された
- `rm -r sample-dir2` は、承認の確認が出た。見出しは「Execute `rm -r sample-dir2`」。選択肢は「Yes, and don't ask again for bash commands」「Yes, proceed」「No, and tell Grok what to do differently」「No, and don't ask again for this command」。「No, and tell Grok what to do differently」で「1 件失敗」と出て、ディレクトリは残った
- 「常に許可」に戻して保存すると、`permission_mode` は `"bypassPermissions"` になった（元は `"always-approve"`）。取っておいた写しで元のファイルに戻し、SHA-256 の一致を確かめた。「エージェント自身に処理させる」も無効に戻した
- Codeg のログに `[ACP] fs policy read=unrestricted write=<~\.grok>, <%TEMP%>, <PROJECT_DIR>…` が出た

### タスク スケジューラでの起動

- 管理者でない PowerShell から、ログオン時のトリガー付きで登録できた（`RunLevel: Limited`・`LogonType: Interactive`）
- 開始すると `State` は `Running`。`codeg-server.exe` はセッション 1（`quser` の `console`）で、整合性レベルは Medium
- ヘルスチェックは `{"status":"ok","version":"0.35.0"}`。コマンドラインにトークンは含まれなかった
- 手で起動したサーバーを止めてタスクで起動し直した後も、会話は残り、ブラウザは入り直さずに使えた

### 端末の grok のセッションを取り込む

- `<PROJECT_DIR>` で `grok -p "…"` を実行して、端末側のセッションを 1 つ作った
- 「ローカルセッションをインポート」の画面は、ほかのエージェントとプロジェクトのセッションも一覧に出す。試験用の 1 件だけを選んで取り込み、結果は「1 インポート・失敗 0」
- 取り込んだセッションを開くと、端末側の指示と応答が表示された。続きの指示を送ると、前の応答を踏まえて答えた

### Grok Build を 1.0.50 に更新してからの再確認

- ここまでの「ブラウザで開いて Grok を動かす」「権限モードと承認の確認」「端末の grok のセッションを取り込む」は、Grok 1.0.46 での結果
- `grok update --check --json` は `{"currentVersion":"1.0.46","latestVersion":"1.0.50","updateAvailable":true,…,"channel":"stable"}` を返した。Codeg は Grok を `--no-auto-update` 付きで起動するので、Codeg 経由では上がらない
- Codeg のタスクと、その下の Grok のプロセスを止めてから `grok update` を実行し、`grok 1.0.50 (c58f321264ba) [stable]` になった。`config.toml` は変わらなかった
- タスクを起動し直すと、設定 → エージェント → Grok の「バージョン状態」は「推奨: 1.0.51 · ローカル: 1.0.50」になった
- 権限モードを「毎回確認」にした新しい会話（`grok.exe --no-auto-update agent stdio`）で、1.0.46 と同じ結果になった
  - ファイルの書き込み: 承認の確認が出て、「Yes」で実行された
  - `mkdir sample-dir3`: 承認の確認なしで実行された
  - `rm -r sample-dir3`: 承認の確認が出て、「No, and tell Grok what to do differently」で「1 件失敗」と出た。ディレクトリは残った
- Codeg のログの承認の要求は、この日の合計で 4 件（1.0.46 と 1.0.50 で、書き込みと `rm` が 1 件ずつ）。`mkdir` の分は無い
- 終わった後、`config.toml` を写しで元に戻し、SHA-256 の一致を確かめた（`permission_mode = "always-approve"`）

### そのほか

- 画面の右下に「新バージョン v0.35.1」が出た（検証は v0.35.0 のまま）
- 設定 → エージェント → Grok の「バージョン状態」は `WARN`。Codeg の画面からのアップグレード（推奨の 1.0.51 への入れ替え）はしていない

### LAN と VPN から開く

- この項は、HTTP のまま VPN の帯だけに公開していた、はじめの形の記録。その後の HTTPS への切り替えは、末尾の付録
- 切り替える前、`codeg-server.exe` 向けの受信の規則と、3080 番の規則は無かった
- 利用者が、管理者の PowerShell で受信の規則 `codeg-server-in` を足した（`Allow`・`Private`・TCP 3080・`LocalAddress` は `<PC_IP>`・`RemoteAddress` は `<ALLOW_FROM>`・`Program` は `codeg-server.exe`）
- 規則を確かめてから、起動用のスクリプトの `CODEG_HOST` を `127.0.0.1` から `<PC_IP>` に変え、タスクを起動し直した
- 待ち受けは `<PC_IP>:3080` だけになった。PC 自身から、`127.0.0.1:3080` は接続できず（curl の終了コード 7）、`<PC_IP>:3080` はトークン無しで HTTP 401、トークン付きで HTTP 200
- 起動し直した後も、`codeg-server.exe` 向けの規則は `codeg-server-in` の 1 本だけだった（Windows が自動で作る規則は増えなかった）
- 許可していない送信元の確認: LAN の AlmaLinux 10 のサーバーから、`<PC_IP>` の 3080/tcp は届かず（curl は時間切れで終了コード 28）、22/tcp は届いた
- 利用者が確認したこと: スマートフォン（Android）で WireGuard を張ったまま、ブラウザで `http://<PC_IP>:3080` を開いてログインし、試験用のプロジェクトで Grok に指示を送って、できたと回答した
- エージェントが PC 側で確かめたこと: `phone-win.txt` ができ、中身は指示どおりの 1 行。Grok のセッションが `grok sessions list` に出た。3080 番への確立済みの接続は、`<ALLOW_FROM>` の帯からのものだけだった
- このときの Grok は `--permission-mode bypassPermissions` で起動していた（`config.toml` は `always-approve` のまま）。承認の確認は出ない設定
- PC の LAN のアドレスは DHCP で取得したもの（`PrefixOrigin: Dhcp`）

### 確認していないこと

- ログオフ・再起動の後の自動起動、ロック・RDP の切断の後の稼働
- スマートフォンでの表示・入力の細かな使い勝手（利用者の回答は「できた」だけ）
- デスクトップアプリ・Android のアプリからの接続
- ロールバック

## 付録: Raspberry Pi 5 の AlmaLinux 10 での検証（2026-10-11 JST）

### 対象と実施前の状態

| 項目 | 値 |
|---|---|
| ホスト | Raspberry Pi 5 Model B Rev 1.0、AlmaLinux 10.2、aarch64、カーネル 6.12.96 |
| Codeg | `codeg-server` v0.35.0（`codeg-server-linux-arm64.tar.gz`、56,137,619 バイト） |
| 配布物の SHA-256 | `f5522330a324a4b62a1efe5116b1a7972f657b6af54314d20c58e32afee8ceef` |
| Grok Build | `grok 1.0.50 (c58f321264ba) [stable]`、`~/.grok/bin/grok`。`config.toml` に `permission_mode` の行は無い |
| Node.js | v22.23.2（`/usr/bin/node`） |
| SELinux / firewalld | Enforcing / running。`public` ゾーンに `wg0` と LAN の NIC |
| 操作した経路 | Windows 11 の PC から SSH（鍵だけ）。画面は SSH のトンネル（PC の `127.0.0.1:3081` → サーバーの `127.0.0.1:3080`）越しに、PC のブラウザで開いた |

- 実施前に Codeg の配置先・データ・ユニットは無く、3080〜3090 番の待ち受けも無かった
- 実施前は `Linger=no` だった。利用者が `sudo loginctl enable-linger` で有効にした
- サーバーの再起動、WireGuard・sshd の再起動はしていない。待ち受けは `127.0.0.1` のままで、ファイアウォールの規則は変えていない
- 別の端末（LAN・VPN・スマートフォン）からの接続は、この付録の範囲に含めない

### 配布物の取得・照合・配置

- `curl -fsSL -O` で `tar.gz` と `.sha256` を取得した。`sha256sum -c` は `OK`、GitHub のリリースが記録する digest とも一致した
- tar の中身は 1105 エントリ。先頭は `codeg-server-linux-arm64/` で、絶対パスと `..` を含むエントリは無い。実行ファイルは `codeg-server`・`codeg-mcp`・`codeg-computer-helper`
- `~/.local/opt/codeg-server` に `codeg-server`・`codeg-mcp`（0755）と `web`（1051 ファイル）を置いた。`codeg-computer-helper` は置いていない
- `codeg-server --version` は `0.35.0`。`ldd` で足りないライブラリは無い（`libssl.so.3`・`libcrypto.so.3`・`libz.so.1` など）
- SELinux のラベルは `unconfined_u:object_r:gconf_home_t:s0`。起動後の AVC の拒否は 0 件

### ユーザーサービスと起動

- `~/.config/systemd/user/codeg-server.service` を置いた。`EnvironmentFile` はトークンのファイル、`Environment=PATH=` で `~/.grok/bin` を先頭に足し、`StandardError=null`、`ExecStart` は `codeg-server --supervise`
- systemd のユーザーの環境の PATH は `/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin` で、`~/.grok/bin` を含まない。ユニットの PATH で `~/.grok/bin/grok` が使われた
- トークンは利用者が作った。`~/.config/codeg-server` は 0700、`token.env` は 0600・77 バイト・`CODEG_TOKEN=` と 64 文字の 16 進の 1 行
- `start` の後は `active`。待ち受けは `127.0.0.1:3080` だけ。プロセスは `codeg-server --supervise` と、その子の `codeg-server`
- `POST /api/health` は、トークン無しと誤ったトークンで HTTP 401、正しいトークンで HTTP 200 の `{"status":"ok","version":"0.35.0"}`
- トークンは、プロセスのコマンドライン・ユニットの journal・Codeg のログ・`codeg.db` のどこにも含まれなかった。`/proc/<PID>/environ` は持ち主だけが読める
- 委任用のソケットは `/tmp/codeg-delegation-<PID>.sock`（`srwxr-xr-x`）
- `enable` で `default.target.wants` にリンクができ、`enabled` になった。`restart` の後も `active`・`127.0.0.1:3080`・ヘルスチェック 200。会話は残り、ブラウザは入り直さずに使えた

**確認のしかたの誤りと訂正**: はじめの確認では、トークンを `grep -cF "$TOK"` と `curl -H "Authorization: Bearer $TOK"` の引数に渡した。このため `ps` の結果に `grep` 自身が 1 件として数えられ、確認のコマンドがトークンをプロセスの一覧に出していた。`grep -cFf <(…)` と、`curl -K -` に標準入力でヘッダを渡す形に直して数え直し、0 件を確かめた。

### systemd-analyze --user verify で systemctl --user が繋がらなくなった件

- ユニットの書式の確認に `systemd-analyze --user verify <ユニット>` を実行した直後から、`systemctl --user …` が `Failed to connect to user scope bus via local transport: Connection refused` になった
- `/run/user/<UID>/systemd/private` の作成時刻が、そのコマンドの実行時刻になっていた。直前の `systemctl --user daemon-reload` と `systemctl --user cat` は成功していた
- ユーザーの systemd 本体は動き続け（PID は変わらず、失敗したユニットは 0）、`systemctl --user --machine=<USER>@.host …` では操作できた
- 利用者の了承を得て `systemctl --user --machine=<USER>@.host daemon-reexec` を実行した。専用ソケットが作り直され、`systemctl --user is-system-running` は `running` に戻った。PID と SSH のセッションは変わらなかった
- このコマンドは手順書に載せない

### ブラウザで開いて Grok を動かす

- ログインの画面で、利用者がサーバー側のトークンを入れた。以後の画面の操作は、利用者の了承を得てエージェントが行った
- 「フォルダを開く」の一覧から `~/codeg-test-project` を選んで開けた
- Codeg が起動した Grok は `~/.grok/bin/grok --no-auto-update agent stdio`（`--permission-mode` なし）
- ファイルの作成は、承認の確認が出た。見出しは「Edit `<パス>/hello.txt`」、差分つき。選択肢は Windows と同じ 3 つ。「Yes」で実行された
- **`mkdir sample-dir` は、承認の確認なしで実行された**
- `rm -r sample-dir` は、承認の確認が出た（「Execute `rm -r sample-dir`」、選択肢は 4 つ）。「No, and tell Grok what to do differently」で「1 件失敗」と出て、ディレクトリは残った
- Codeg のログの承認の要求は 2 件（作成と `rm`）。`[ACP] fs policy read=unrestricted write=<~/.grok>, <PROJECT_DIR>, /tmp, /var/tmp | host tools codeg (fs + terminal advertised)` が出た
- Grok の `config.toml` は変わらなかった

### 最初の会話のモデル

- Codeg を起動して最初の Grok の会話は、モデルの欄が「Grok 4.6」だった。セッションの記録（`events.jsonl`）の `modelId` も `grok-4.6` だった
- 同じ時点の `grok models` の既定は `grok-4.7`。端末で `grok -p` を実行して作ったセッションの `modelId` は `grok-4.7` だった
- 2 つ目以降の会話は、モデルの欄が「Grok 4.7」になった。Windows 11 の PC でも同じ現れ方だった（最初の会話だけ「Grok 4.6」）

### 端末の grok のセッションを取り込む

- `~/codeg-test-project` で `grok -p "…"` を実行して、端末側のセッションを 1 つ作った
- 「ローカルセッションをインポート」で試験用の 1 件だけを選び、結果は「1 インポート・失敗 0」
- 取り込んだセッションを開いて続きの指示を送ると、前の応答を踏まえて答えた

### VPN に公開する

- この項は、HTTP のまま VPN の帯だけに公開していた、はじめの形の記録。その後の HTTPS への切り替えは、末尾の付録
- 利用者が、`public` ゾーンの runtime と permanent に、送信元 `<ALLOW_FROM>`・宛先 `<SERVER_IP>`・3080/tcp の rich rule を 1 本ずつ足した（`priority="100"`）。足す前の rich rule は 0 本だった
- 規則が両方にあることを確かめてから、ユニットの `CODEG_HOST` を `127.0.0.1` から `<SERVER_IP>` に変え、`daemon-reload` と `restart` をした
- 待ち受けは `<SERVER_IP>:3080` だけになった。サーバー自身から、`127.0.0.1:3080` は接続できず（curl の終了コード 7）、`<SERVER_IP>:3080` はトークン無しで HTTP 401、トークン付きで HTTP 200
- 許可していない送信元の確認: LAN の Windows 11 の PC から、`<SERVER_IP>` の 3080/tcp は届かず（`Test-NetConnection` は `False`、curl は時間切れで終了コード 28）、22/tcp は届いた
- 利用者が確認したこと: スマートフォン（Android）で WireGuard を張り、ブラウザで `http://<SERVER_IP>:3080` を開いてログインし、試験用のプロジェクトで Grok に指示を送って、うまくいったと回答した。トークンは、サーバーの端末に `qrencode -t ansiutf8` で出した QR コードで渡す手順を案内した
- エージェントがサーバー側で確かめたこと: `phone.txt` ができ、中身は指示どおりの 1 行。Grok のセッションが `grok sessions list` に出た。Codeg のログに、再起動の後の承認の要求と回答が 1 件ずつあった。3080 番への接続に、`<ALLOW_FROM>` の帯からのものが 1 本あった
- PC のブラウザ（SSH のトンネル越し）で、スマートフォンから送った指示と会話が表示された

### 確認していないこと

- すべてのセッションを閉じた後の稼働（linger）、OS の再起動の後の自動起動
- スマートフォンでの表示・入力の細かな使い勝手（利用者の回答は「うまくいった」だけ）
- デスクトップアプリ・Android のアプリからの接続
- 画面からの入れ替え（Software Update）と、ロールバック

## 付録: v0.35.1 への更新（2026-10-11 JST）

### AlmaLinux 10

- `curl -fsSL -O` で v0.35.1 の `codeg-server-linux-arm64.tar.gz`（56,217,410 バイト）と `.sha256` を取得した。`sha256sum -c` は `OK`、GitHub の digest（`2a97353b919c13ec76212970f50b2184123492ca7b2ce983fe9db0eece7b1ff6`）とも一致した
- `systemctl --user stop` → 今の配置を `codeg-server.prev` に移す → 新しい `codeg-server`・`codeg-mcp`・`web` を置く → `start` の順で置き換えた
- `codeg-server --version` とヘルスチェックの `version` は `0.35.1`。`active`、待ち受けは `<SERVER_IP>:3080` のまま、トークン無しは HTTP 401、AVC の拒否は 0 件
- `codeg.db` はそのまま残り、ブラウザ（SSH のトンネル越し）で、会話の一覧が残っていること・入り直しが要らないこと・「新バージョン」の表示が消えたことを確かめた
- 確かめた後、`codeg-server.prev` と取得用のディレクトリを消した

### Windows 11

- `gh release download v0.35.1` で `codeg-server-windows-x64.zip`（58,166,819 バイト）と `.sha256` を取得し、SHA-256 が GitHub の digest（`6e610a4a8d214bc15951e082dd05765ac51d02fdb5d657de5aa9162b35446262`）と `.sha256` の両方に一致した
- 手順書の形（`curl.exe` で取得し、`.sha256` の先頭の値と `Get-FileHash` を比べ、`Expand-Archive` する）でも、同じ版の取得・照合・展開が通ることを別に確かめた
- タスクと Codeg を止める → `codeg-server.exe`・`codeg-mcp.exe`・`web` を `codeg-server.prev` に移す → 新しい 3 つを置く → タスクを開始、の順で置き換えた
- `codeg-server.exe --version` とヘルスチェックの `version` は `0.35.1`。タスクは `Running`、待ち受けは `<PC_IP>:3080` のまま、トークン無しは HTTP 401、受信の規則は `codeg-server-in` の 1 本のまま
- `codeg.db` はそのまま残った。更新の後の画面は、確かめていない（この PC のブラウザは、待ち受けを変えた後に入り直していない）
- 確かめた後、`codeg-server.prev` と取得用のディレクトリを消した

## 付録: 送信元への LAN の帯の追加と、HTTPS への切り替え（2026-10-11 JST）

### 送信元に LAN の帯を足す（HTTP の時点）

- 利用者の指定で、送信元に 2 つの拠点の LAN の帯を足した。利用者が、サーバーでは帯ごとの rich rule を足し（`read -r -a` と `for` で 1 本ずつ。3080/tcp）、Windows 11 では `Set-NetFirewallRule` で `RemoteAddress` を 3 つにした
- サーバーの規則は、runtime と permanent に 3 本ずつ。Windows 11 の規則の `RemoteAddress` は 3 つ
- LAN 越しに、Windows 11 の PC からサーバーへ、サーバーから Windows 11 の PC へ、どちらも `GET /` が HTTP 200、トークン無しの `POST /api/health` が HTTP 401
- もう一方の拠点の LAN の帯からの接続は、確かめていない

### Caddy の取得と配置

- AlmaLinux 10: `curl -fsSL -O` で `caddy_2.11.7_linux_arm64.tar.gz`（16,485,181 バイト）と `caddy_2.11.7_checksums.txt` を取得した。一覧の SHA-512 で `sha512sum -c` が `OK`、GitHub の digest（`d8fc6d179a5d283028a472a5618564f6ad8a86fed513e64f032b3b0b7cc45e42`）とも一致した。tar の中身は `LICENSE`・`README.md`・`caddy`。`~/.local/opt/caddy/caddy` に置き、`caddy version` は `v2.11.7`。足りないライブラリは無い
- Windows 11: `curl.exe` で `caddy_2.11.7_windows_amd64.zip`（18,479,498 バイト）と一覧を取得した。`Get-FileHash -Algorithm SHA512` が一覧の値と一致し、GitHub の digest（`0a1edc0b799512051c57071ce0e798d3f2cf67dc98171366f1d2b326072e3b06`）とも一致した。`%LOCALAPPDATA%\codeg-caddy\caddy.exe` に置き、`caddy version` は `v2.11.7`。Authenticode の署名は無い
- `brew info caddy` と `scoop search caddy` で、Homebrew と scoop にも 2.11.7 があることは確かめた（使っていない）

### 設定と起動

- `Caddyfile` は、`admin off`・`auto_https disable_redirects`・`skip_install_trust`・`pki` の `name`、サイトは `https://<ホストの IP>:3443` で `bind`・`tls internal`・`/caddy-root.crt` の配布・`reverse_proxy 127.0.0.1:3080`。`caddy validate` は `Valid configuration`
- AlmaLinux 10: Codeg の `CODEG_HOST` を `127.0.0.1` に戻して起動し直し、`codeg-caddy.service` を `enable --now` した。待ち受けは `127.0.0.1:3080` と `<SERVER_IP>:3443` の 2 つだけで、80 番と 2019 番は無い。AVC の拒否は 0 件、Caddy の journal に warn・error は無い
- Windows 11: 起動用のスクリプトの `CODEG_HOST` を `127.0.0.1` に戻してタスクを起動し直し、Caddy のタスク `codeg-caddy`（`Interactive`・`Limited`・ログオン時）を登録して開始した。待ち受けは `127.0.0.1:3080` と `<PC_IP>:3443` の 2 つだけ。`caddy.exe` はセッション 1 で動いた
- Caddy のデータ（`~/.local/share/caddy`）と認証局のディレクトリは 0700、`root.key`・`root.crt` などは 0600 だった（中身は読んでいない。`root.crt` は公開してよい証明書なので、名前・期限・指紋だけを `openssl x509` で読んだ）

### 証明書

- どちらも TLS 1.3。サーバーの証明書の SAN は、ホストの IP アドレス 1 つ。期限は、作ってから 12 時間後だった
- ルート証明書の期限は 2036-08-19（10 年後）
- ルート証明書を `--cacert` に渡すと、検証が通り（`Verify return code: 0 (ok)`）、トークン無しの `POST /api/health` は HTTP 401、トークン付きは HTTP 200（AlmaLinux 10。トークンは `curl -K -` で渡した）
- ルート証明書を渡さないと、`curl` は終了コード 60 で止まった
- `https://<ホストの IP>:3443/caddy-root.crt` の中身は、ホストの `root.crt` と同じだった
- はじめは `pki` の `name` を書かず、2 台のルート証明書がどちらも `Caddy Local Authority - 2026 ECC Root` になった。端末に入れる前に、Caddy を止めてデータを消し、`name` を足して作り直した（`Codeg <ホスト名> - 2026 ECC Root`）。はじめの認証局は、どの端末にも入れていない

### ファイアウォールの規則の入れ替え

- 利用者が、サーバーでは 3080/tcp の rich rule 3 本を外して 3443/tcp の 3 本を足し、Windows 11 では `caddy.exe` 宛ての規則 `codeg-caddy-in`（TCP 3443・`LocalAddress` は `<PC_IP>`・`RemoteAddress` は 3 つ・`Private`）を足して、`codeg-server-in` を消した
- 入れ替えの後、サーバーの規則は 3443/tcp の 3 本だけ（runtime と permanent）。Windows 11 の `codeg-*` の規則は `codeg-caddy-in` の 1 本だけで、Caddy を起動した後も増えなかった
- Windows 11 では、規則を足してから Caddy を起動した

### 互いのホストから HTTPS で確かめる

- Windows 11 の PC からサーバーへ、サーバーから Windows 11 の PC へ、LAN 越しに、相手のルート証明書を `--cacert` に渡して `GET /` が HTTP 200、トークン無しの `POST /api/health` が HTTP 401（Windows の `curl.exe` には `--ssl-no-revoke` を付けた）
- ルート証明書を渡さないと、どちらも終了コード 60
- 以前の HTTP（`http://<ホストの IP>:3080/`）は、どちらも届かなかった（時間切れで終了コード 28）

### 端末にルート証明書を入れる

- 利用者が確認したこと: スマートフォン（Android）に 2 台のルート証明書を入れ、問題なかったと回答した
- 利用者が確認したこと: Windows 11 の PC に、サーバーのルート証明書を入れて、問題なかった。この PC 自身のルート証明書は、1 回目は失敗し、2 回目に入った
  - 1 回目の失敗は、エージェントの案内のしかたが原因。URL とファイル名を手で書き換える案内にしたため、1 行目の保存先だけが元の名前のまま残り、2・3 行目が探すファイルが無かった
  - 書き換えずに貼れるブロックを渡して、入った。手順書は、URL を 1 つの変数に入れ、保存先をそこから作る形にした
- エージェントが確かめたこと: `Cert:\CurrentUser\Root` に、2 台のルート証明書（指紋が、ホストに出したものと同じ）が入っている。`--cacert` を付けない `Invoke-WebRequest` で、2 台の `https://<ホストの IP>:3443/` がどちらも HTTP 200

### 手順書の形での確認

- 空白で字下げした `Caddyfile`（手順書の形）を、サーバーの一時的な写しで `caddy validate` に通した（`Valid configuration`）。動いている設定は、タブで字下げしたもの
- Windows 11 の「Caddy の設定を書いて、検査する」のブロック（ヒア文字列の形）を、Windows PowerShell 5.1 で、一時的な場所に書いて `caddy validate` に通した
- 「端末にルート証明書を入れる」の手順 4 のブロックを、Windows PowerShell 5.1 で実行し、名前と指紋が出ることを確かめた（取り込みは、利用者が 3 行の形で行った）
- 手順書の「Caddy の配布物を取得して…」のブロックは、`tar -xzf` の後に `install` する形。検証では、一時ディレクトリに展開してから `install` した

### 確認していないこと

- もう一方の拠点の LAN の帯からの接続
- サーバーの証明書の期限（12 時間）をまたいだ後の動き（Caddy が自動で作り直すかどうか）
- はじめから HTTPS で公開する、手順書の順での通し（検証では、HTTP で公開してから切り替えた）
- Caddy の更新、ロールバック、OS の再起動やサインアウトの後の Caddy の自動起動
- AlmaLinux 10 の PC（つなぐ側）と、Firefox へのルート証明書の取り込み

## 付録: そのほかの確認（2026-10-11 JST）

### トークンを替える

- AlmaLinux 10 のサーバーで、使い捨てのインスタンス（別のデータ置き場、`127.0.0.1:3090`、試験用の 2 つの値）を立てて確かめた。本番のトークン・データ・待ち受けには触れていない
- 値 A で起動: A は HTTP 200、B は HTTP 401
- 同じデータ置き場のまま、値 B で起動し直す: A は HTTP 401、B は HTTP 200
- 本番のサービスでトークンを替える操作そのものは、行っていない

### Windows 11 で止める・もう一度始める

- 手順書の形（`Stop-ScheduledTask` → `Stop-Process` → `agent stdio` の `grok.exe` と `codeg-mcp.exe` を止める）で止めると、プロセスと待ち受けが無くなり、タスクは `Ready` になった
- `Start-ScheduledTask` で、`Running` と `<PC_IP>:3080` の待ち受けに戻った
- このとき、Codeg の下で動いている Grok Build のプロセスは無かった（Grok Build を止める行が効くことは、この形では確かめていない。検証の途中では、プロセスの親子をたどって止めた）

### 文書の静的な確認

- HTTPS に書き直した後の文書で行った（2026-10-11 JST）
- 手順書と extra の `bash` のブロック 23 個を抜き出し、`bash -n` に通した（Windows の Git Bash の bash 5.3.15 と、AlmaLinux 10 の bash 5.2.26。失敗 0）
- 同じ 23 個を、AlmaLinux 10 の ShellCheck 0.11.0（`-s bash`）に通した。指摘は 7 件で、どれも直していない
  - SC2034 が 6 件: 別の手順のブロックで使う変数（`SERVER_IP`・`ALLOW_FROM`・`CODEG_VERSION`）が 3 件と、待つためだけのループの変数 `i` が 3 件
  - SC2009 が 1 件: `ps -eo args | grep -cFf <(…)`。トークンを引数に書かずに数えるための形で、`pgrep` では代えられない
- `powershell` のブロック 27 個を、Windows PowerShell 5.1.26100.9444 と PowerShell 7.6.6 の構文解析（`Parser.ParseInput`）に通した（エラー 0）。PSScriptAnalyzer には通していない
- Windows PowerShell 5.1 で動きを確かめたブロックは 3 つ: 起動用のスクリプトの `CODEG_HOST` を書き換える `-replace` の式（HTTP で公開していたときの形。今の手順書には無い）、「Caddy の設定を書いて、検査する」のヒア文字列、「端末にルート証明書を入れる」の手順 4
- 新しい 4 つの文書と、案内を足した 6 つの文書（`README.md`・`docs/linger.md`・`docs/coding-agents.md`・`docs/reference/coding-agents.md`・`docs/almalinux-setup.md`・`docs/windows-setup.md`）の相対リンクと見出しのアンカーを突き合わせた（不一致 0）
- アラートは、手順書が 4 つ（OS ごとに 2 つ）、extra が 2 つ。`[!TIP]` は無い
- `git diff --check` は出力なし

## 付録: PR #132 の共同レビューでの修正と静的確認（2026-10-11 JST）

- Codex と Grok Build が、PR #132 の差分を別の会話で確認した。元の対象は `de113d659dd91718fa297832c00a02dce9930f36`
- 修正したこと: Caddyfile の証明書の配布元のパスを引用し、空白を含むホームでも解析できる形にした。Windows のタスクに入れるパスの単引用符もエスケープした
- 修正したこと: Caddy の終了コードをタスクへ返し、失敗時は 1 分おきに最大 999 回やり直す形にした。サインイン時に IP がまだ付いていない場合を扱う
- 修正したこと: Windows の停止・更新・ロールバックで、配置先の実行ファイルが一致する Codeg の PID に `taskkill /T /F` を使う形にした。`agent stdio` の Grok をすべて止める選別は外した
- Caddy 2.11.7 の Windows x64 の公式配布物を SHA-512 と照合し、`caddy adapt` だけで、空白と単引用符を含む試験用のパスを確認した。修正前は解析に失敗し、修正後は成功してパス全体が 1 つの値になった（PowerShell 7.6.5 と Windows PowerShell 5.1.26100.9444）
- 両 PowerShell で 21 項目のモック検査を通した。Caddy のタスク引数の実行ファイルと設定のパス、失敗の終了コードの伝播、再試行の指定、停止する Codeg の選別と停止の順番を確認した。ほかの配置先の Codeg と、別の ACP クライアントの Grok は停止対象に入らなかった
- タスクを登録せず、`New-ScheduledTaskSettingsSet` で設定オブジェクトだけを作り、`RestartCount=999`・`RestartInterval=PT1M`・`ExecutionTimeLimit=PT0S`・`MultipleInstances=IgnoreNew` を確認した
- 修正後の `bash` のブロック 23 個は `bash -n` に成功し、`powershell` のブロック 27 個は両 PowerShell の構文解析でエラー 0。変更した 12 文書の相対リンクと見出しのアンカー 1120 件は不一致 0、`git diff --check` は出力なし。ShellCheck 0.11.0 は、先の静的確認と同じ 7 件（SC2034 が 6 件・SC2009 が 1 件）で、追加の指摘は無かった
- 確認していないこと: 修正したタスクの実登録、サインインや IP の付与後の再試行、実プロセスの停止、修正後の更新・ロールバックの通し。今回の検査では、本番の Codeg・Caddy・Grok、ファイアウォール、認証局、トークンには触れていない
- Grok Build の追加指摘に合わせ、ルート証明書の照合を取り込み前に必須とした。共通の証明書の節を並べ替え、PC での取得・照合を手順 3、照合したファイルを USB で Android に渡して取り込む操作を手順 4 にした。上の過去の記録の「手順 4」は、当時の PC での取得・照合の番号を表す
- Grok Build の追加指摘に合わせ、ロールバックでほかの用途と共有する Caddy の本体・設定・認証局を残す場合は、削除と確認の両方から外す形にした。認証局を残す場合は、端末のルート証明書の削除も飛ばす
- Grok Build の追加指摘に合わせ、AlmaLinux 10 の更新が途中で失敗したときは中断を表示し、置換と起動が成功したときだけ確認を出す形にした。前の本体の退避先が無ければ、現行の本体を消さないことも明記した
- 追加修正後、更新ブロックのコマンドをスタブに置き換えた 8 ケースを確認した。`mktemp`・`tar`・停止・`mv`・ディレクトリ作成・本体配置・開始の失敗では、確認の出力をせず終了コード 1。`mv` の失敗では、現行の本体を保持し、退避先は無く、削除は実行されなかった。成功したケースだけ、版・サービス・待ち受けの確認に進んだ。`HOME` は変更せず、実サービスと実ファイルの置換は行っていない
- 追加修正後の `powershell` のブロック 27 個も、PowerShell 7.6.5 と Windows PowerShell 5.1.26100.9444 の構文解析でエラー 0。Android への USB 転送と取り込み、共有する Caddy のパスを残す撤去、更新失敗からの実際の復旧は未検証
- Grok Build の追加指摘に合わせ、Codeg の配布物の一覧検査は、`tar -tzf` が成功してからパスを数える形にした。以前の `tar | grep -c` では、一覧を読めないときにも `0` が出た。スタブの 5 ケースでは、正常な一覧は `0` かつ終了コード 0、`../` と絶対パスは `1` かつ終了コード 1、一覧の取得失敗と部分一覧の後の失敗は数値を出さず終了コード 1 になった
- Grok Build の追加指摘に合わせ、journal の検査も、読み取りが成功してから件数を出す形にした。公開のダミー値を使ったスタブ 3 ケースでは、成功時は一致の無いログで `0`、一致するログで `1`、読み取り失敗時は中断を表示し数値を出さなかった。実トークンと実ログは読んでいない
- Grok Build の追加指摘に合わせ、Windows の更新ブロックは子スコープで `$ErrorActionPreference='Stop'` を設定し、配布物の 3 点が揃ってから停止へ進む形にした。`taskkill` の非 0 も中断する。復旧元が揃っている場合だけ現行の 3 点を消して戻し、揃っていなければ両方を保持する。再開の成功条件も、localhost だけの構成と HTTPS 公開済みの構成で分けた
- Grok Build 1.0.50（既定モデル `grok-4.7-build`）は、元の対象の 12 ファイルすべてを確認した。公開の本文を分割して渡し、最終回答の末尾確認文字列で読了範囲を突き合わせた。Codex の指摘・修正結果は、独立レビューの入力に含めていない
- Windows の更新ブロックを抜き出し、ファイル操作・タスク・プロセス・配布物の取得をスタブにした 13 ケースを、PowerShell 7.6.5 と Windows PowerShell 5.1.26100.9444 の両方で通した。展開失敗、3 点それぞれの不足、`taskkill` 非 0、タスクの停止、部分的な移動、本体と `web` のコピー、一時ファイルの削除、タスクの開始の失敗では、その後の処理と成功表示が止まった。配布物不足はプロセス停止前、`taskkill` の失敗は退避前に止まった。成功時は確認へ進み、呼び出し元のエラー設定（`Continue`・`SilentlyContinue`）も保持された。実際の更新・復旧は未検証
- 最後の修正後も、bash 23 ブロックと PowerShell 27 ブロックは構文エラー 0、12 文書の相対リンクと見出しのアンカー 1120 件は不一致 0。ShellCheck は先と同じ 7 件で、追加は無かった

## 付録: 共同レビューの修正の確認と、Windows 11 を IP が変わっても使える形にした変更（2026-10-11 JST）

### 共同レビューの修正の確認

- 対象は `31d5d7b`。Claude Code が差分を読み、次を確かめた
- `bash` のブロック 23 個の `bash -n`（Windows の Git Bash と AlmaLinux 10。失敗 0）、ShellCheck 0.11.0（先と同じ 7 件）、`powershell` のブロック 27 個の構文解析（Windows PowerShell 5.1.26100.9444 と PowerShell 7.6.6。エラー 0）、相対リンクと見出しのアンカー（不一致 0）
- Caddyfile のパスの引用: この PC の `caddy.exe`（2.11.7）で、手順書のヒア文字列の形の設定を `caddy adapt` に通した。`APPDATA` に空白を含む値を入れても、`root` は 1 つのパスになった（両 PowerShell）
- タスクの引数: 単引用符と空白を含むパスで組み立て、内側のコマンドを構文解析して、実行ファイルと設定のパスが、それぞれ 1 つの文字列になることを確かめた（両 PowerShell）
- 配布物の一覧の検査: AlmaLinux 10 の GNU Awk 5.3.0 で、スタブの一覧 5 つを通した。正常な一覧は `0` で終了コード 0、`../`・絶対パス・途中の `..` は `1` で終了コード 1、一覧の取得の失敗は、数値を出さずに終了コード 1
- **タスクの再試行は働かなかった**。`-RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)` を付けた使い捨てのタスク（一時ファイルに時刻を 1 行足して、終了コード 1 で終わる。`Interactive`・`Limited`）を登録して確かめた
  - `Start-ScheduledTask` で始めた場合は 170 秒、時刻のトリガーで始まった場合は 200 秒待った。どちらも実行は 1 回だけで、`LastTaskResult` は 1、状態は `Ready` のままだった
  - タスクは、確かめた後に消した。ログオンのトリガーでは試していない
- この結果から、手順書の再試行の設定と記述を外した。下の変更で、待ち受ける IP が無くても Caddy が起動する形にした

### 実機で起きたこと（再起動の後）

- この PC は、18:42 に、拠点の外（パブリックの Wi-Fi。有線のアダプタは無い）で再起動された。サインインの後、Codeg のタスクは始まり、Codeg のログに `Listening on:` と `http://127.0.0.1:3080` が残った（18:42:26）
- Caddy のタスクは、`LastTaskResult` が 1 で、`Ready` に戻っていた。待ち受ける IP（`192.168.0.40`）が、この PC に無かった。共同レビューが指摘した不具合が、実機で起きていた
- 20:24 の時点で、Codeg のプロセスも無かった。タスクの `LastTaskResult` は 0。18:42:28 より後のログは無く、止まった時刻と原因は分かっていない
- 22:18 に、拠点の有線 LAN で再起動された。サインインの後、2 つのタスクは `Running` で、待ち受けは `127.0.0.1:3080` と `192.168.0.40:3443` だった（この時点では、IP を決めた設定のまま）
- 再起動してサインインした後に 2 つのタスクが始まることは、この 2 回で確かめた。サインアウトしてサインインし直した後は、確かめていない

### 試験用の Caddy での確認

- 実サービスとは別のデータの置き場（`storage file_system`）を使い、`127.0.0.1:3445` だけで待ち受ける試験用の設定で、サイトのアドレスを `https://:3445`、`tls internal` に `on_demand` を付けた。`caddy validate` は `Valid configuration`
- `127.0.0.1` へ TLS でつなぐと、TLS 1.3、発行者は試験用の認証局の中間証明書、SAN は `IP Address=127.0.0.1`、期限は 12 時間だった。`/caddy-root.crt` で取ったルート証明書を `--cacert` に渡すと、検証が通って HTTP 200
- Caddy は、起動のときに `YOUR SERVER MAY BE VULNERABLE TO ABUSE: on-demand TLS is enabled, but no protections are in place` の警告を出した
- 試験用の Caddy は止め、待ち受けが残っていないことを確かめた

### 受信の規則の入れ替え（利用者）

- 利用者が、管理者の窓で、`codeg-caddy-in` を消し、手順書の「Windows 11 で HTTPS で LAN・VPN に公開する」の手順 3 と同じ 3 本の `New-NetFirewallRule` を実行した。拠点の外にいる間で、Caddy は止まっていた
- 読み戻し: `codeg-caddy-in` は `Allow`・`Private`・`Wired`・TCP 3443・`RemoteAddress` は 3 つ・`LocalAddress` は `Any`。`codeg-caddy-block-public` は `Block`・`Domain, Public`。`codeg-caddy-block-wifi` は `Block`・`Private`・`Wireless`。どれも `caddy.exe` 宛て
- 手順書のブロックのうち、変数の検査・同じ名前の規則の検査・確認の表示は、利用者は実行していない。確認の表示の行と、同じ名前の規則の検査の式は、エージェントが、管理者ではない Windows PowerShell 5.1 で実行した
- エージェントは、事前に 3 本を `-WhatIf` で実行し、引数が受け付けられて、規則が作られないことを確かめた

### Caddy の入れ替え（この PC）

- Caddy のタスクを止め、以前の `Caddyfile`（`https://192.168.0.40:3443` と `bind`）を退避し、以前のタスクを消した。認証局のデータ（`%APPDATA%\Caddy`）は、そのまま使った
- 手順書の「Caddy の設定を書いて、検査する」と「Caddy のタスクを登録して開始し、この PC 自身から HTTPS を確かめる」のブロックを、ファイルに写して、管理者ではない Windows PowerShell 5.1 で実行した。手順書のブロックと、実行したファイルの中身が同じことも突き合わせた
- 結果は、`Valid configuration`、`Running`、待ち受けは `127.0.0.1` の 3080 と `::` の 3443、`https://127.0.0.1:3443/api/health` へのトークン無しの `POST` が HTTP 401（ルート証明書で検証。`127.0.0.1` 宛ての証明書が、その場で作られた）、`caddy.exe` 宛ての規則は 3 本のまま、最後に `https://192.168.0.40:3443`
- ルート証明書の指紋は、入れ替えの前と同じ（端末に入れ直していない）。タスクは `Interactive`・`Limited`、`RestartCount` は 0、`caddy.exe` はセッション 1 で動いた
- Codeg のタスクは、22:18 のサインインで始まったまま（`Running`）で、触れていない

### 届く範囲

- サーバー（`192.168.0.10`。有線 LAN）から、PC の `192.168.0.40:3443` へ: ルート証明書を `--cacert` に渡して、`GET /` が HTTP 200、トークン無しの `POST /api/health` が HTTP 401。TLS 1.3、`Verify return code: 0 (ok)`、SAN は `IP Address:192.168.0.40`。渡さないと、`curl` は終了コード 60。`/caddy-root.crt` の指紋は、PC に出したものと同じ
- サーバーから `http://192.168.0.40:3080/` は、時間切れ（終了コード 28）
- サーバーから、PC の VPN のアドレス（`10.99.2.2`。WireGuard のインターフェースで、ネットワークの種類は `Public`）の 3443 番へは、時間切れ（終了コード 28）。このとき、PC から VPN の相手（`10.99.0.1`）への `ping` は通っていた。サーバーの送信元（`10.99.0.1`）は、`ALLOW_FROM` にも入っていない
- PC 自身から、`192.168.0.40`・`192.168.56.1`（VirtualBox のホストオンリー）・`10.99.2.2`・`127.0.0.1` の 3443 番へ: どれも、ルート証明書で検証が通って、`GET /` が HTTP 200、トークン無しの `POST /api/health` が HTTP 401。`192.168.56.1` の証明書の SAN は `IP Address=192.168.56.1` で、設定を変えずに作られた
- `--cacert` を付けない `Invoke-WebRequest`（PC の信頼の置き場を使う）で、`https://192.168.0.40:3443/` が HTTP 200
- 「PC の IP が変わったとき…」の手順のブロックは、`https://192.168.0.40:3443` と、接続ごとのネットワークの種類（有線 LAN は `Private`、WireGuard は `Public`）を出した

### そのほかの変更

- 利用者の指定で、Android へのルート証明書の入れ方を、ブラウザで取得する形に戻した。共同レビューで USB で渡す形に変えていたが、その形は実機で通していなかった。節の手順の順も、利用者が実際に通したときの順に戻した。上の過去の記録の手順番号は、今の手順書の番号と同じになる
- 利用者の指定で、ロールバックの「貼る前に」の箇条書き（3 か所）を、コードブロックの前から、節のリードへ移した（規約では、手順の中の箇条書きは、コマンドの後に置く）
- Windows 11 のロールバックの、受信の規則を消す手順を、3 本を消す形にした（流していない。確認の `Get-NetFirewallRule -Name 'codeg-caddy-*'` が 3 本を出すことだけ確かめた）

### 文書の静的な確認（この変更の後）

- `bash` のブロック 23 個は、`bash -n` に成功（Windows の Git Bash と AlmaLinux 10）。ShellCheck 0.11.0 は、先と同じ 7 件
- `powershell` のブロックは 26 個になった（変数のブロックが 2 つ減り、URL を表示するブロックが 1 つ増えた）。Windows PowerShell 5.1.26100.9444 と PowerShell 7.6.6 の構文解析で、エラー 0
- 新しい 4 つの文書と、案内や列挙のある 8 つの文書の、相対リンクと見出しのアンカーは不一致 0。太字の閉じ方の点検は 0 件。`git diff --check` は出力なし

### 確認していないこと

- 別の拠点の有線 LAN での接続（IP が実際に変わった後の接続）と、もう一方の LAN の帯からの接続
- 入れ替えの後の、スマートフォンからの接続
- パブリックのネットワークや、プライベートの Wi-Fi にいるときに Caddy が待ち受けを始めた場合の動き（Windows が許可を尋ねる画面を出さないこと、規則が増えないこと）。入れ替えは、有線 LAN に戻ってから行った
- Wi-Fi のインターフェースから届かないこと（届かないことは、VPN のインターフェースでだけ確かめた）
- IP が違う URL で、ブラウザがトークンを入れ直させること
- 証明書の期限（12 時間）をまたいだ後の動き、サインアウトの後の自動起動、Codeg が止まっていた原因
- ログオンのトリガーで始まったタスクの再試行
- 手順書の「受信の規則を 3 本追加する」のブロックを、そのままの形で管理者の窓に貼ること
