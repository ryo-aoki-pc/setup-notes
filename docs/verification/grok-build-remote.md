# Grok Build をブラウザから操作する手順（Codeg と Caddy）の検証記録

[手順書](https://github.com/ryo-aoki-pc/setup-notes/blob/497bb823606053e5c08d4f7d59bde4e3274707e8/docs/grok-build-remote.md)・[ロールバックと注意点](../extra/grok-build-remote.md)・[参考資料](../reference/grok-build-remote.md)

現行手順: AlmaLinux 10 の [Codeg 導入](../almalinux-setup.md#grok-build-のブラウザ操作-実施手順)・[Claude Code・Codex CLI 操作](../almalinux-setup.md#grok-build-のブラウザ操作-claude-code-と-codex-cli-も操作する)・[共通パスワードの変更](../almalinux-setup.md#grok-build-のブラウザ操作-codeg-の共通パスワードを設定変更する)、Windows 11 の [Codeg 導入](../windows-setup.md#grok-build-のブラウザ操作-windows-11-で使う)・[Claude Code・Codex CLI 操作](../windows-setup.md#grok-build-のブラウザ操作-claude-code-と-codex-cli-も操作する)・[共通パスワードの変更](../windows-setup.md#grok-build-のブラウザ操作-codeg-の共通パスワードを設定変更する)。

## 対象と検証環境

- **AlmaLinux 10 の接続・共通パスワードの状態（2026-10-13 JST）**: [実機の追加検証](#付録-almalinux-102-の3エージェント接続と共通パスワードの検証2026-10-13-jst)に、今回の範囲を記録する
  - aarch64 の既存ホストで、Codeg v0.35.1 の配布物と配置済み本体の一致、3 エージェントの ACP 接続、Codex・Grok の短文の応答を確認した。Claude は `Auto` の設定まで成功し、週の利用上限で応答未確認
  - 公式の共同作業プラグインの setup/check と、補助スクリプトからの Codex・Grok の応答を確認した。Codeg の委譲設定を反映したが、画面からの実際の委譲と承認の設定は未確認
  - 宛先の LAN IPv4 と 3443/tcp を残し、送信元の制限を外した。両サービスの enabled・active、待ち受け、TLS を検証した HTTPS の未認証 401 を確認した
  - Linux のパスワード変更スクリプトは公開 fixture 11 件・構文検査・実ホストの `--check` が成功した。本人は HTTPS のパスワードログイン成功を報告した。本人の変更時の 200/401/401 の出力は受領していない

- **Windows 11 の共通パスワードの状態（2026-10-13 JST）**: [変更用スクリプトの付録](#付録-windows-11-の共通パスワード変更スクリプトの検証2026-10-13-jst)に、確認済みの範囲を記録する
  - 実ホストの Windows PowerShell 5.1 で `-CheckOnly` を通し、本人が入力する補助スクリプトの変更成功を、秘密を含まない今回の結果で確認した。新認証 200・未認証 401・誤入力 401
  - Codeg の再起動と専用の待ち受け、Caddy の継続を確認した。本人は変更後の HTTPS ログインの完了を報告した。公開 fixture の模擬結果・エージェントの直接確認・本人の手動確認を分ける

- **Claude Code・Codex の追加の状態（2026-10-12 JST）**: [追加時の付録](#付録-claude-codecodex-の操作手順の追加2026-10-12-jst)と [Windows 11 の付録](#付録-windows-11-の-claude-codecodex-の追加検証2026-10-12-jst)に、実施した範囲を記録する
  - AlmaLinux 10 の隔離試験では、両エージェントの接続と会話の作成、Codex の短文の応答を確認した。Claude の応答はエラーで未確認
  - Windows 11 の画面で両アダプターの導入・診断・接続を確認した。Codex は短文の応答、専用ファイルの作成、中断、開き直した会話と取り込んだ CLI 会話の文脈の継続も確認した
  - Windows 11 の Claude は `Auto`・`Opus 5.5` の選択と接続を確認した。最初の指示は契約の週の利用上限で失敗し、応答・編集・中断・文脈の継続は未確認
  - 両 OS の自動審査の拒否、承認カードへの許可・拒否、AlmaLinux 10 の画面での両エージェントの操作は未確認。各付録の成功の範囲を分ける

共同レビュー後に変えた部分の確認範囲は、末尾の「PR #132 の共同レビューでの修正と静的確認」に記録する。その修正の確認と、Windows 11 を IP が変わっても使える形にした変更は、その次の付録に記録する。2026-10-12 の Windows 11 Home への新規導入と Private の全送信元への変更は、末尾の今回の付録に記録する。変更後の更新・ロールバックを、実機で通した結果はまだ無い。以前の記録の手順番号は、実施当時の番号として残す。

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

- **Windows 11 の非表示起動への切り替え（2026-10-11 JST）**:
  - 確認したこと: ランチャーをコンパイルし、既存の両タスクの Action だけを変更して再開した。新しい Terminal は開かず、以前の自動起動の Terminal も残らなかった。両タスクは `Running`、HTTPS は 200、トークン無しの API は 401
  - 確認したこと: ログオンのトリガーが 1 個ずつ、有効、権限は `Limited` のまま。以前の Action は XML に控えた
  - **確認していないこと**: 切り替え後の OS 再起動・サインアウト後の起動、更新とロールバックの通し、新規導入からの全手順の通し

- **Windows 11 Home への新規導入（2026-10-12 JST）**:
  - 通したこと: Codeg v0.35.1 と Caddy v2.11.7 の配布物の取得・照合、非表示ランチャーのコンパイル、管理者ではないタスクの登録、Private の全送信元・全接続種別を許可する受信規則の作成、両タスクの起動、Grok 4.7 での会話
  - 確認したこと: 起動用スクリプトの Windows PowerShell 5.1 での構文解析、Caddy の設定解析、両タスクの `Interactive`・`Limited`・`Running`、Private の Allow と Public・Domain の Block の読み戻し、待ち受け、トークン無しの API の 401、ルート証明書で検証した HTTPS の 200
  - 配置の訂正: Codex から通常の AppData に見えたファイルの実体は、Codex の MSIX パッケージの LocalCache にあった。通常の PowerShell から公開ファイルだけを配置する補助手順に直し、利用者が実行した。最後に `CIM_DataFile` で通常の AppData の本体・ランチャー・スクリプトの存在を確かめた
  - 画面で確認したこと: 利用者の HTTP ログイン後、Grok の「スマート自動承認」を保存し、保存後に開いた新しい会話で「Grok 4.7」と接続済みの表示・応答を確認した。秘密の設定ファイルは読んでいない
  - 利用者が確認したこと: 通常の Windows PowerShell での本体の配置とトークンの作成、ルート証明書の本人の信頼ストアへの取り込み、この PC の通常のブラウザでの HTTPS ログイン、自宅 Wi-Fi の別端末からの HTTPS のログイン画面の表示。トークンの値はエージェントに渡していない
  - **確認していないこと**: 別端末でのログイン・Grok への指示送信、スマート自動承認でのファイル変更・コマンド実行
  - **確認していないこと**: 既存規則の移行の実行、Public・Domain での接続拒否、有線 LAN・VPN・IPv6 の接続、再起動・サインアウト後の起動、更新・ロールバック

- **手順書のブロックの形について**: 検証では、同じコマンドを、値を直接書いた形や、複数の手順をまとめた形で実行した。手順書の変数つきのブロックを、そのままの形で上から通してはいない。ブロックは、下の「文書の静的な確認」で構文を確かめた
- **確かめていない機能**:
  - Codeg のデスクトップアプリ・Android のアプリからの接続、Codeg の画面からの入れ替え（Software Update）、Grok Build・Claude Code・Codex 以外のエージェント
  - AlmaLinux 10 の PC（つなぐ側）へのルート証明書の取り込み

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

### 完了時点の状態（2026-10-11 の 2 ホスト）

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

## 付録: Windows Terminal を開かない自動起動への切り替え（2026-10-11 JST）

### 実施前の状態

- 利用者から、OS 起動時に Codeg の Windows Terminal が開くと報告された
- `codeg-server` と `codeg-caddy` は `Running`。どちらも `powershell.exe -NoProfile -WindowStyle Hidden` をタスクから直接始める形だった
- Codeg の PowerShell はログオン時に始まり、その直後に Terminal が起動していた。Terminal のタイトルは `powershell.exe` のパスだった
- スタートアップの登録に、Codeg と Caddy の別の項目は無かった

### ランチャーの確認

- ソースは、手順書の「Windows 11 で Codeg のサーバーを入れて起動する」の手順 7 に記載したもの。Windows 標準の .NET Framework の `csc.exe` で `/target:winexe` にコンパイルした
- `UseShellExecute=false`・`CreateNoWindow=true` とし、標準出力と標準エラーを非同期に読み捨てる。スクリプトが終わるまで待ち、その終了コードを返す
- 試験用の PowerShell スクリプトから `cmd.exe` を起動し、2 秒待って終了コード 37 で終える確認を行った。ランチャーの終了コードは 37、新しい Terminal の PID は 0 個だった
- 試験用のスクリプトと生成物は、確認後に作業場所から消した。トークンは使用していない

### 実機への反映

- `%LOCALAPPDATA%\codeg-server\` に、`HiddenLauncher.cs` と `codeg-hidden-launcher.exe` を置いた
- `%LOCALAPPDATA%\codeg-caddy\start-caddy-hidden.ps1` を作り、同じフォルダーの Caddy と Caddyfile を指定して起動し、終了コードを返す形にした
- 両タスクの XML を `%LOCALAPPDATA%\codeg-server\startup-backup-<日時>\` に控えた
- 配置先が一致する Codeg と Caddy のプロセスを、子プロセスごと終了し、両タスクを止めた。Action をランチャーとスクリプトのパスへ変え、両タスクを開始した
- 変更したのは、起動用のファイルとタスクの Action。トークン・受信の規則・認証局は変えていない
- 両タスクは `Running`・`Limited`。新しい Terminal の PID は 0 個で、以前の Terminal も閉じた（Terminal のプロセスは 0 個）
- HTTPS の `GET /` は HTTP 200、トークン無しの `POST /api/health` は HTTP 401。ルート証明書を信頼する Windows の curl で確認した
- ログオンのトリガーは 1 個ずつ、有効のまま。Codeg と Caddy のプロセスも確認した

### 文書への反映と範囲

- 新規導入のタスク登録をランチャー経由へ変更し、既存のタスクの切り替え節、設定ファイルの表、参考資料、撤去時に消すファイルの案内を更新した
- 過去の検証記録は当時の形を残した。この付録より前の「Windows 11 で Codeg のサーバーを入れて起動する」の手順 7〜9 は、ランチャーを足す前の番号
- OS は再起動していない。ログオン時にも窓が出ないこと、サインアウト後の動作、文書の手順全体の通し、切り替え後の更新・ロールバックは未確認

### 今回の文書の静的な確認

- PowerShell のブロック 29 個を、Windows PowerShell 5.1.26100.9444 と PowerShell 7.6.5 で構文解析し、エラー 0
- bash のブロック 23 個は変更していない。Git Bash の `bash -n` は失敗 0
- 変更した 5 文書の相対リンクと見出しのアンカー 89 件、太字の閉じ方の検査は問題なし。`git diff --check` は出力なし
- 手順書からランチャーのソースを取り出し、実機に配置したソースと一致することを確かめ、作業場所でコンパイルした
- 既存タスクの切り替えブロックを、ファイル操作・タスク・プロセスをスタブにした 3 ケースで検査した（両 PowerShell）。Codeg だけ、Codeg と Caddy、2 本目の Action の変更失敗を通した
- 選別で別の配置先の Codeg と別の Grok が停止対象に入らず、両タスクの控えと再開、スクリプトのパスの引用、失敗時の旧 Action の復元を確認した
- 手順書のブロックをそのまま実機で流した検証ではない。実機への切り替えは、上の記録の作業として行った

## 付録: Windows 11 Home への新規導入と Private の全送信元への変更（2026-10-12 JST）

### 対象と実施前の状態

| 項目 | 値 |
|---|---|
| ホスト | Windows 11 Home ビルド 26300、AMD64、Intel Core i5-1235U。Wi-Fi は Private、有線 LAN・VPN の接続は無し |
| 手順書 | `setup-notes` の `main`、`ae1981a48fee0e26540d82224d4c195492bae782` を取得して参照 |
| Codeg | v0.35.1（`codeg-server-windows-x64.zip`） |
| 配布物の SHA-256 | `6e610a4a8d214bc15951e082dd05765ac51d02fdb5d657de5aa9162b35446262` |
| Caddy | v2.11.7（`caddy_2.11.7_windows_amd64.zip`） |
| 配布物の SHA-512 | `c308154504e53755958ffc62d8a2657ab17eefd6dd25c45dbb2c3d93d29519971f77ca652f7d0f2bcb7f980b9ba3822478865e29969d0272d7613550a43152b1` |
| Grok Build | 1.0.50（`c58f321264ba`）、既存のログインを使用 |
| Node.js | v24.21.0（scoop） |
| 実行 | デスクトップの管理者ではないユーザー。ファイアウォールの作成だけ UAC で昇格 |

- Codeg の配置先・データ・タスク、Caddy の配置先・受信規則、3080〜3090 と 3443 の待ち受けは無かった
- 利用者の指定は、Private の IPv4・IPv6 の全送信元・全接続種別を許可し、Public・Domain は遮断すること。Grok の権限モードはスマート自動承認（`auto`）
- 旧 Windows 11 Pro の検証とは別のホスト。この付録では、以前の端末接続・再起動の成功を引き継がない

### 配置・タスク・受信規則の確認

- Codeg の ZIP はリリース付属の SHA-256、Caddy の ZIP は公式のチェックサムの SHA-512 と一致した。`codeg-computer-helper.exe` は置かず、PATH は変更していない
- Codex からは、本体を `%LOCALAPPDATA%\codeg-server` と `%LOCALAPPDATA%\codeg-caddy` に配置したように見えた。後の配置監査で、実体は MSIX パッケージの LocalCache にあると分かった。通常の AppData に配置できたという判断は誤りだった
- Codex から見えた配布本体の `codeg-server.exe --version` は `0.35.1`、`caddy.exe version` は `v2.11.7`。`caddy adapt` は成功した（整形の警告は出た）。この時点では通常の AppData への配置を確認できていなかった。後の利用者による配置・起動は、下に記録する
- 起動用の 2 スクリプトは Windows PowerShell 5.1 で構文解析し、エラー 0。ランチャーは .NET Framework の `csc.exe /target:winexe` でコンパイルし、PE の Subsystem は 2（Windows GUI）だった
- 両タスクの登録は確認した。`Interactive`・`Limited`、本人のログオンをトリガーにし、実行期限は `PT0S`、バッテリーでの開始・継続を許可し、重複した開始は `IgnoreNew`
- タスクの読み戻しで本人との SID の一致、有効なログオントリガー 1 個ずつを確認した。失敗時の再試行は設定していない（`RestartCount=0`）。Action は通常の AppData のランチャーと、それぞれの起動スクリプトを指す。登録時はその場所への配置が未完了で、稼働は利用者による配置後に確認した
- 受信規則は、Public・Domain の遮断を先に作り、Private の許可を作った。読み戻しでは両方が有効で、Caddy の規則はこの 2 本だけだった
- Allow は `Private`・TCP 3443・`LocalAddress Any`・`RemoteAddress Any`・`InterfaceType Any`・`InterfaceAlias Any`・`EdgeTraversalPolicy Block`、Block は `Domain, Public`・プロトコルとポートはすべて `Any`。Program は通常の AppData の `caddy.exe` のパスを指す。配置後にも同じ条件と、Caddy の規則がこの 2 本だけであることを読み戻した
- このホストは新規導入のため、既存規則の XML の控えと切り替えは実行していない
- Private の InterfaceIndex から有効な IPv4 を表示する新しい URL の確認ブロックは、Wi-Fi の接続名と `https://<PC_IP>:3443` を出した。到達できた結果ではなく、アドレスの読み戻し

### 配置先の誤判定と利用者側の失敗

- 利用者が通常の Windows PowerShell で起動した補助スクリプトは、初回に `Codeg is not installed yet` で止まった。通常の AppData の固定パスを指定し直した後の実行も、同じエラーで止まった。どちらもトークンを作る前の停止だった
- 固定パスへの変更は原因を確かめるための試行で、この失敗だけでは配置先を特定できない。後の配置監査は、Codex の `Get-Item` だけで存在を判断せず、`CIM_DataFile` で通常の論理パスと MSIX 配下の物理パスを区別して行った
- 監査した既知の 8 ファイルは、Codex の `Get-Item` では通常の AppData のパスで見えた。`CIM_DataFile` では、その論理パスに対応するファイルは無く、`<USER_LOCALAPPDATA>\Packages\<CODEX_PACKAGE>\LocalCache\Local` 配下の物理パスでは存在を確認した。ユーザー名・ホスト名・パッケージ ID・SID の値は記録しない
- この結果から、その時点では通常の AppData への配置は完了していないと訂正した。タスクと受信規則の登録メタデータだけでは、起動対象の実在と稼働を判断できない
- 対処として、公開の本体・web・ランチャー・起動用スクリプトだけ（1,061 ファイル）を、作業用の `codeg-user-steps/payload` に用意した。チェックサムを照合した配布物から作り、各ファイルの SHA-256 のマニフェストを付けた。既存のファイルを上書きせず、利用者が通常の PowerShell で配置・照合した後にトークンを作る補助手順に直した
- 最初の配置用の補助スクリプトは、Windows PowerShell 5.1 で JSON 配列を外側の配列に包んだため、Group の検査で `Invalid public payload manifest` になった。`ConvertFrom-Json` の結果をそのまま変数に入れる形に直し、5.1 で 1,061 件・不正な Group 0 件を確かめた
- 修正後、利用者は補助スクリプトの正常終了を報告した。`CIM_DataFile` で通常の AppData の既知の公開ファイル 8 個の存在と、`token.txt` の存在・64 バイトを確かめた。トークンの内容は読んでいない

### 起動・画面・接続の状態

- トークンは利用者が通常の Windows PowerShell で作り、メモ帳からコピーしてブラウザに入力した。エージェントは値を作成・閲覧・記録していない。起動時の標準出力・標準エラーは非表示ランチャーで読み捨て、取得していない
- 両タスクは `Running`。配置後も `Interactive`・`Limited`、有効なログオントリガー 1 個、期限 `PT0S`、バッテリーでの開始・継続、`IgnoreNew`、`RestartCount=0` を読み戻した
- 待ち受けは Codeg の `127.0.0.1:3080` と Caddy の `::3443`。3081〜3090 の待ち受けは無い。HTTP の `GET /` は 200、トークン無しの `POST /api/health` は 401
- 公開の `/caddy-root.crt` から得たルート証明書で検証し、`https://127.0.0.1:3443/api/health` のトークン無しの `POST` は 401、Wi-Fi の `https://<PC_IP>:3443/` の `GET` は 200。ルート証明書は `CN=Codeg <HOST> - 2026 ECC Root`、期限は 2036-08-20。秘密鍵は取得していない
- 利用者がルート証明書の SHA-256 を突き合わせ、`Cert:\CurrentUser\Root` に取り込んだと報告した。取り込み後、`--cacert` を指定しない Windows の curl でも、Wi-Fi の HTTPS が証明書検証を通って 200 になった。これはこの PC 自身からの確認で、別端末から届いた結果ではない
- Codex の組み込みブラウザでは、HTTPS を開くと `ERR_CERT_AUTHORITY_INVALID` になった。警告をエージェントが通過させる操作はしていない。利用者は通常のブラウザで HTTPS を開き、ログイン後の画面が表示されたと報告した
- Codeg の HTTP 画面では、利用者のログイン後にエージェントが Grok の「スマート自動承認」を保存し、保存完了の表示を確認した。保存後に開いた新しい会話は「Grok 4.7」・接続済みになった。初回は接続に数分かかり、Codeg → Grok → codeg-mcp の起動をプロセス名と親子関係で確かめた。秘密の設定ファイル・ログ・コマンドラインは読んでいない
- ツール・ファイル・設定を使わない短文の接続確認に「Grok Build の接続確認ができました。」と応答した。スマート自動承認でのファイル変更やコマンドの実行は、このホストでは試していない
- 利用者は、同じ自宅 Wi-Fi の別端末からも HTTPS のログイン画面が開いたと報告した。別端末での認証・Grok への指示送信や証明書検証の詳細は確認していない
- 別端末でのログイン・Grok への指示送信、再起動・サインアウト・ロック・RDP 切断、Public・Domain での接続拒否、有線 LAN・VPN・IPv6、更新・ロールバックは未確認

### 共同レビューと文書の確認

- Grok Build 1.0.50 の `grok-4.7` と、公開仕様だけを用いた読み取り専用の共同レビューを行った。受信規則の移行順、Private の URL の抽出、接続確認の範囲を手順へ反映した
- 文書の変更差分を追加で送る操作は、当初は自動承認レビューで拒否された。その後、利用者が送信を明示的に許可し、5 文書の差分を `--tools=`（全ツール無効）・`--model grok-4.7`・計画モード・1 ターンで送信した。ホスト名・ユーザー名・実機 IP は置き換え、Grok にファイルの閲覧や変更はさせていない。終了コードは 0
- 差分レビューの 5 指摘のうち、受信 NIC と IP ごとの接続確認、旧 Wi-Fi 遮断規則の削除前の読み戻し、現在の URL の参照、Private の LAN・VPN の条件を反映した。`InterfaceAlias Any` を無効とする指摘は、Microsoft の公式資料の使用例と合わないため採用しなかった。複数の規則名を指定し、旧規則が無いと取得全体が失敗するという指摘も、Windows PowerShell 5.1 で既存 2 本が返ることを確かめて採用しなかった
- 既存の Public・Domain 遮断規則のプロトコルとポートは、変更前にすべて `Any` と検査する形にした。通常と違う条件なら無変更で中断し、既存規則の更新では不要なポートの再指定を外した
- 今回変更した 6 文書の相対リンクと見出しのアンカー 330 件は不一致 0。PowerShell の 29 ブロックは Windows PowerShell 5.1.26100.9444 で構文解析し、エラー 0。`git diff --check` は出力なし
- 本体と extra のコード付きの操作 49 手順を、説明から最後の箇条書きまで点検し、「説明 → コード → 確認・分岐・注意」の順序違反は無かった
- URL のモック検査では Private の Wi-Fi・有線 LAN・VPN を表示し、Disconnected・Public・Domain・loopback・link-local・SkipAsSource・Tentative を除外した。移行は Windows PowerShell 5.1 で 7 ケースを検査し、控えと変更の順、手順 1 で旧 Wi-Fi 遮断を残すこと、独立した手順 2 でだけ削除すること、通常と違う規則と Program 不一致で無変更中断、削除直前の Program の再検査、旧規則が無い場合のスキップを確認した。モック検査で実機の規則は変更していない
- 手順書のブロックをそのまま実機で機械的に流した検証ではない。同じ操作を、新規導入用のスクリプトと個別のコマンドで行った

## 付録: Claude Code・Codex の操作手順の追加（2026-10-12 JST）

### 対象と変更の範囲

| 項目 | 値 |
|---|---|
| 手順書の基点 | `setup-notes` の `main`、`421be2d`。独立 clone の `codex/codeg-claude-codex-guide` で文書だけを変更 |
| 対象の Codeg | v0.35.1。対応版の確認は公開タグ `e21eb6b38eea9405cdfa3b2d99df216d101d1344` |
| 試験ホスト | AlmaLinux 10.2、aarch64。Windows 11 は今回の試験に使用していない |
| Node.js / npm | `v26.11.0` / `11.20.0`。ホストで版の確認を実行 |
| 既存の CLI | Claude Code `2.1.296`、Codex CLI `0.160.0`。本人のサブスクリプションでログイン済み |
| 隔離導入したもの | Claude ACP `0.89.1` / Agent SDK `0.3.293` / 付属 CLI `2.1.293`、Codex ACP `2.2.2` / 付属 CLI `0.160.1` |

- 本体に両 OS 共通の任意節「Claude Code と Codex CLI も操作する」を追加し、参考資料・注意点・README・共同作業の案内・構成のメモを同期した
- Caddy・Codeg のアクセストークン・公開範囲・既存の Grok 手順は変更していない。親リポジトリと既存のサブモジュールの checkout も変更していない
- 操作に要る認証方法とモデル・モード、接続失敗の分岐、元の会話を閉じてから同じエージェントで再開することを案内した。ログイン・設定・履歴の共有と、設定を保存したときの CLI への影響を参考資料と注意点に記録した

### 公式資料と対応版の確認

- [Codeg の認証方式](https://docs.codeg.app/guide/authentication)で、Claude の既存ログインの再利用と、Codex の ChatGPT ログインを確認した。「公式サブスクリプション」を使い、API キー・モデルプロバイダーを追加しない形にした
- [Claude の契約での SDK 利用](https://support.claude.com/en/articles/15036540-use-the-claude-agent-sdk-with-your-claude-plan)の 2026-10-07 更新と [OpenAI の認証の説明](https://learn.chatgpt.com/docs/auth)を確認し、本人の契約の利用枠を消費することを明記した
- Codeg v0.35.1 のレジストリで対応アダプター版を、各アダプターのソースで依存ランタイムとモード名を確認した。Claude の `Auto` が使えないときの警告と `Accept edits` への切り替え、手動運用時の `Manual` を区別した
- 履歴の取り込みは、公式の [Conversation Aggregation](https://docs.codeg.app/guide/aggregation)と、Codeg v0.35.1 の画面・取り込み処理のソースを確認した。接続先ホストの履歴を同じエージェントで再開する仕様の確認で、画面での実測ではない
- Codeg・CloudCLI・Happy の比較は公開ソースと公式案内の確認。CloudCLI の Codex の非対話実行による承認の制約、Happy の外部 relay と従来 CLI の保守モードを[参考資料](../reference/grok-build-remote.md#claude-codecodex-を遠隔操作する-oss-の比較)に記録した。両候補の導入・実機試験は行っていない

### 隔離した ACP 接続試験

- `/tmp` の専用 npm prefix・cache・空の作業ディレクトリを使用し、固定版を `--ignore-scripts` で導入した。既存の npm の設定を読ませず、userconfig は `/dev/null`、globalconfig は専用の空ファイルにした
- 最初は userconfig と globalconfig を両方 `/dev/null` にしたが、npm 11 が二重読み込みとして停止した。別の空ファイルに分けると導入できた。123 パッケージが入り、両アダプターと依存ランタイムの版を確認した
- API キーの環境を継承せず、各ランタイムの通常の機構で既存の本人の認証を再利用した。エージェントが認証ファイルの中身を閲覧・コピー・出力する操作は行っていない
- Claude は試験の session options でツールと設定の読み込み元を空にし、`Manual` を選んだ。Codex は `Read-only` を選び、フック・MCP を無効にする設定値を指定した。有効設定や MCP の起動状態の読み戻しは行っていない
- クライアント側もツール・承認の要求を拒否する構成にし、空の場所で「ツールを使わず OK のみ」と 1 回ずつ指示した
- ツール・承認の要求は両方とも 0 件。通常の Codeg の設定や `Auto`・`Auto review` を使う試験ではない。既存のグローバル npm・Codeg の設定は変更していない
- 試験後に専用 prefix・cache・作業ディレクトリを削除した。通常の仕組みで各 CLI の会話の履歴が残る可能性はある。秘密情報を含む生のログは記録していない

| 操作・機能 | AlmaLinux 10 の Claude | AlmaLinux 10 の Codex | Windows 11 の両エージェント |
|---|---|---|---|
| 付属ランタイムで本人の契約の認証を再利用 | 確認済み | 確認済み | 未確認 |
| ACP の `initialize`・新しい会話の作成 | 成功 | 成功 | 未確認 |
| 試験用の手動・読み取りモードの選択 | `Manual` の選択成功 | `Read-only` の選択成功 | 未確認 |
| ツールを使わない短文の応答 | RPC `-32603` で失敗。応答未確認 | `OK` と応答、`end_turn` で終了 | 未確認 |
| Codeg の画面でのアダプター導入・接続・応答 | 未確認 | 未確認 | 未確認 |
| `Auto`・`Auto review` の自動審査、承認・拒否・中断 | 未確認 | 未確認 | 未確認 |
| CLI 履歴の取り込み・同じエージェントでの再開 | 未確認 | 未確認 | 未確認 |

- Claude の応答のエラーには `limit` の語があった。原因を確定する情報が無いため、利用枠の上限と断定しない。再試行や API キーを追加する回避は行わなかった
- Claude が返した `Manual`・`Accept edits`・`Plan`・`Auto`、Codex が返した `Read-only`・`Workspace access`・`Auto review`・`Full access` のモード名を確認した。モードの一覧を取得できたことは、自動審査の判断の成功とは扱わない
- HTTPS 越しの画面、スマートフォン、Windows 11、新しい節の実機での通しは未確認。以前の Grok の成功を、今回の両エージェントの成功へ読み替えない

### 文書の静的な確認

- 本体の bash 21 ブロックと extra の 3 ブロック、計 24 ブロックを Bash 5.2.26 の `bash -n` で確認し、構文エラー 0
- ShellCheck 0.11.0 で新規の bash ブロックの指摘は 0。全体の既存 7 件（SC2034 が 6 件、SC2009 が 1 件）は変更前の `421be2d` と一致し、新たな指摘は無かった
- 本体の PowerShell 27 ブロックと extra の 3 ブロック、計 30 ブロックを Linux arm64 の PowerShell 7.6.6 の `Parser.ParseFile` で確認し、構文エラー 0。Windows PowerShell 5.1 の実行と PSScriptAnalyzer は今回の検査に含めない
- 変更した 8 文書の相対リンク・見出しのアンカー 435 件を確認し、不一致 0。変更前の見出しが同じ名前・順序で残っていることも確認した
- 本体と extra の操作 83 手順（コード付きは 51 手順）を、説明から最後の箇条書きまで点検し、「説明 → コード → 確認・分岐・注意」の順序違反は無かった。共同作業の手順書は案内をリードに追加し、操作の順序は変更していない
- `git diff --check` は出力なし。掲載したブロックを実機で機械的に流す検査は行っていない。AlmaLinux 10 の版の確認だけは、同じコマンドを別途実行した

### Grok Build との共同レビュー

- Grok Build 1.0.50 の `grok-4.7` に、公開文書 8 ファイルの差分を渡した。計画モード・1 ターン、ツール・Web 検索・subagent を無効にした読み取り専用のレビューで、終了コードは 0
- 本体の警告が Grok だけを指していた点と、構成のメモの共通見出しの並びが本体と違った点の 2 指摘を反映した。任意節からも、同じトークンで Claude・Codex を操作できることが分かる注意点へ案内した
- 本人のサブスクリプションの再利用、契約枠の消費、API キーの非追加、ACP 試験と画面での未実測の区別、OS・機能ごとの未確認、Claude の手動運用、履歴の同時再開を避ける案内には、追加の指摘は無かった

## 付録: Windows 11 の Claude Code・Codex の追加検証（2026-10-12 JST）

### 対象と変更の範囲

| 項目 | 値 |
|---|---|
| 文書の基点 | `setup-notes` の `main`、`cd044b9b`。独立 clone の `agent/codex-codeg-claude-codex` で文書を変更 |
| 実機 | Windows 11。既存の Codeg と Caddy を使用 |
| Codeg | v0.35.1。対応版と履歴走査の確認は公開ソース `e21eb6b38eea9405cdfa3b2d99df216d101d1344` |
| Node.js / npm | `v24.21.0` / `11.19.0` |
| Claude のアダプター | `claude-agent-acp` `0.89.1` / Agent SDK `0.3.293` |
| Codex のアダプター | `codex-acp` `2.2.2` / 付属 Codex CLI `0.160.1` |

- 操作の範囲は、両 OS の「Claude Code と Codex CLI も操作する」の手順 2〜10 に当たる。アダプター導入と画面での操作は Windows 11 の実機で行った
- 認証方法は両方とも既に「公式サブスクリプション」だった。本人の既存ログインを再利用し、認証方式の変更・保存し直しは行わなかった
- 履歴の本人による終了確認、全プロジェクトの選別、エージェントごとの反復、取り込みと再開の区別を両 OS の正本と参考資料へ追記した
- この付録では、私的な会話本文・作業パス・ホスト名・認証情報を掲載しない。Codeg の表示と、本人の終了報告、公開ソースの仕様確認を区別する

### 導入・接続・操作の結果

| 操作・機能 | Windows 11 の Claude | Windows 11 の Codex |
|---|---|---|
| 画面で対応版を導入し、診断で検出 | 成功。導入直後は一度検出に失敗し、次の再チェックで `PASS` | 成功。導入後に `PASS` |
| 本人の契約の認証の再利用 | 既存のログインを確認 | 既存のログインを確認 |
| 新しい会話での接続・モデル・モードの選択 | `Opus 5.5`・`Auto` で接続し、表示を確認 | `6.1 Sol`・`Auto review`・`Ultra` で接続し、表示を確認 |
| ツールを使わない短文の応答 | 契約の週の利用上限で失敗。応答未確認 | 成功 |
| 専用の検証フォルダでファイルを 1 件作成 | 未確認 | 成功。20 バイト、UTF-8・BOM 無しをホスト側で確認 |
| 応答中の停止 | 未確認 | 「キャンセル済み」の表示を確認 |
| 停止後に同じ Codeg 会話を開き直し、元の文脈で応答 | 未確認 | 成功。先に作ったファイル名を正しく回答 |
| 終了した本人の CLI 会話の取り込み | 試験用の 1 件を取り込み、見つからず・失敗とも 0 | 試験用の 1 件を取り込み、見つからず・失敗とも 0 |
| 取り込んだ CLI 会話を同じエージェントで再開 | 未確認 | 成功。モデル・モードを確認してから、元の文脈で応答 |
| 自動審査の拒否、承認カードへの個別の許可・拒否 | 未確認 | 未確認 |

- Claude の最初の検出失敗では、`npm prefix -g` が約 1.6 秒かかり、Codeg の約 1.5 秒の検出時間を超えた。次の「再チェック」で回復した。PATH の変更やタスクの再起動は行わなかった
- npm の導入完了ログと Codeg の検出を分け、手順 2 に完了後の「再チェック」を明記した。パッケージが入った結果だけを接続成功として扱わない
- Claude の `Auto` とモデルの選択は維持されたが、短文の指示は週の利用上限で失敗した。接続・選択の確認を、応答・編集・自動審査の成功へ広げない
- Codex のファイル作成は、最初のコマンドの実行先が検証フォルダと一致せず失敗した。絶対パスを使った指示で回復し、指定した単独のファイルを確認した
- Codex の画面は一時 `Reconnecting 2/5` と MCP の停止を表示した。Codeg・Caddy の既存プロセスと起動時刻、タスクの `Running`、待ち受けが続くことを確かめ、その後自然に復帰した
- 停止後に同じ会話を開き直したときは `Auto review` が表示された。その後、`/workspace` への移動と再読み込みで `Workspace access` に変わった。モードが恒久的に維持されるとは扱わない
- 手順 7・10 に、開き直した後も送信前にモデル・モードを確かめ、今回使うものを選ぶ操作を追加した。取り込んだ Codex 会話の再開でも `Auto review`・`6.1 Sol`・`Ultra` を確かめてから送信した

### 履歴の取り込みの範囲

- 利用者は、ほかの Claude・Codex の会話を閉じたと報告した。実行中のこの作業の会話は明示的に対象から外した。試験用の CLI 会話は終了後に取り込んだ
- フォルダから取り込みを開く操作は組み込みブラウザで画面が変わらず、既存の `/import-sessions` の案内で画面を開いた。別のウィンドウを開く動作との関係は未確定
- 全体の件数は Grok を含む全エージェントの集計だった。Claude・Codex の絞り込み後の件数、選択した対象、取り込み結果を分けて確認した
- エージェントごとに選択・取り込み・結果確認を行い、「続けてインポート」で再スキャンしてから次へ進んだ。Claude・Codex とも試験用の 1 件が取り込まれ、「見つからず 0」「失敗 0」だった
- Codeg の既存会話は「インポート済み」で、再度選ぶ対象ではなかった。進行中の自動除外や終了済みの表示は無いため、終了の確認は元の CLI・アプリで行う
- Codex の取り込んだ会話では、同じエージェントで元の文脈を使った応答を確認した。Claude の取り込んだ会話の再開は、週の利用上限のため未確認
- 公開ソースでは、Codex の通常の走査先は `CODEX_HOME` 配下の `sessions` だけで、`archived_sessions` は対象外だった。subagent の会話も取り込み対象から除外される。既存のアーカイブ済み会話の取り込み成功へは広げない
- 既存のアーカイブ済み会話は、本人による解除の判断待ちで、未取り込みのまま保持した

### 既存の Grok Build の回帰確認

- 両アダプターの追加後に、既存の Grok の会話を `Chat`・`Grok 4.7`・`High` で開き、ツールを使わない短文の指示への応答を確認した
- この確認は既存会話の接続と応答だけ。Grok の自動審査による変更・危険操作・停止の検証を追加したものではない

### 共同レビューと文書の確認

- Grok Build の `grok-4.7` に、最初の公開文書 4 ファイルの差分を渡した。計画モード・1 ターン、全ツールを拒否し、Web 検索・subagent を無効にした。終了コードは 0、レビュー完了の印を確認した
- 「すべて選択」による手動選択の置換、アダプターの検出の成功条件、Claude の再開時のモード継承、再スキャン後の反復範囲の 4 指摘を反映した
- 公開ソースと画面の日本語表示を照合し、取り込み結果の「見つからず」と「失敗」を別に確認する形にした。停止後のモード確認とアーカイブの制約は、その後の実機・ソース確認に基づく追記
- 初回の 4 文書では、既存の見出し・リンク・コードブロックを保持し、両 OS の履歴の手順が一致することと、各節の 10 手順を確認した。`git diff --check` は出力なし

### 残る未確認

- Windows 11 の Claude の応答・ファイル変更・中断・文脈の継続、自動審査の許可・拒否、承認カードへの個別の許可・拒否
- Codex の自動審査での拒否と、承認カードへの個別の許可・拒否。専用ファイルの作成成功から、すべての操作の審査が成功する範囲へ広げない
- 両アダプターを追加した後の OS 再起動・サインアウト・ロック・RDP 切断、別端末からの両エージェントの操作、アダプターの更新・ロールバック
- AlmaLinux 10 の Codeg の画面での両エージェントの通し操作。先の隔離した ACP 試験とは分ける

## 付録: Windows 11 の共通パスワード変更スクリプトの検証（2026-10-13 JST）

### 対象と状態

- Windows 11 の既存の Codeg v0.35.1・非表示ランチャー・`codeg-server` タスクを対象に、標準認証の共有値を本人が指定する任意節を追加した
- 公開スクリプトは `scripts/grok-build-remote/set-codeg-password.ps1`。本人の Windows PowerShell 5.1 で `-CheckOnly` を付けて前提を確認し、引数無しの実行では伏せ字で 2 回入力する
- 実ホストで変更を実行した版の SHA-256 は `83FF702360D87CA3A5D02C10EDB20C0962E3B2858B6E5D0C2AE9CA5DE1DFA1A1`。コピーした前後に一致を確認した
- 実ホストで `-CheckOnly` は成功した。その後、本人への伏せ字入力を経た今回の結果を、秘密の値を含まない JSON で確認した
- 今回の結果は `Outcome=success`、新認証 200・未認証 401・誤入力 401、`CleanupFailed=false` だった
- Codeg は起動し直され、専用の `127.0.0.1:3080` とタスクの `Running` を確認した。Caddy の既存プロセス・起動時刻は変わらず、タスクの `Running` が継続した
- 今回の控えの実ファイルも存在した。認証値や控えの本文は読んでいない。既存の組み込みブラウザは、Codeg の再起動中に接続切断を表示した。旧認証の 401 を画面で直接確認した結果ではない
- 認証ファイルと今回の控えは、存在・本人の所有・継承無し・許可ルール 1 個・本人だけの権限を、秘密の本文を読まずに確認した
- 利用者は、設定といつもの HTTPS の Codeg へのログインが完了したと報告した。エージェントが新しい認証値で画面へログインした結果ではない。パスワードはエージェントに渡していない
- 一時配布先で本人からファイル不存在の報告があった。存在・Win32 実体・前提確認は成功し、原因は未特定。同じ hash の短い配布先から本人が設定と HTTPS ログインを完了した
- パスワード・旧認証値・個人のパス・ホスト名を掲載しない。スクリプトの結果 JSON も秘密の値を含めない

### 静的な確認と復元の扱い

- Windows PowerShell `5.1.26100.9444` で公開スクリプトと任意節の呼出ブロック 2 個を構文解析し、エラー無しを確認した。手順には、実ホストの前提確認で不要だった実行ポリシーの指定を追加しない
- 本番で実行した `83FF` で始まる版の公開 fixture は、Windows PowerShell 5.1 で全 9 項目・終了コード 0 を確認した
- その時点の fixture の SHA-256 は `59875E1191A08865EB4629F708412D31AAF76F9B7E915F3039744DAC1D367406`。その後の最終版の試験とは分ける
- 共同レビューの 3 指摘への改修後のスクリプトの SHA-256 は `58FC566F9F2BE70EE7E962C1BE1A66B75A55F3ED1176340DE8B88B504D374199`。公開配置へコピーした前後に一致を確認した
- この版は実ホストの `-CheckOnly` と構文解析で成功した。本人への入力・本番の認証変更は再実行せず、先の本番成功の結果 JSON も保持した
- この版の公開 fixture は `scripts/grok-build-remote/test-codeg-password.ps1`。Windows PowerShell 5.1 で全 20 項目・終了コード 0 を確認した
- その fixture のコピー元の SHA-256 は `522466772BFDA9DB136D6793145E084B90BEAC745DD8F08793A59474030B6762`。コピー後に末尾の空行 2 行だけを除き、元のコードは保持した
- 20 項目を通した公開 fixture の SHA-256 は `C12C8B8869993BD5CBF7DBEACB9BF057E9840DFFEDBF8361AC1624C8BA93609F`。末尾の空行以外が同一であることを確認した
- 最後に、不明状態をコンソールへ `null` と明記する改善を加えた。最終スクリプトの SHA-256 は `8E143B77EF89A4456DAC4EA0330CC6ECDE021B1F4BBFACF6CA56C3EB3F85578C`
- 最終版も実ホストの `-CheckOnly` で成功した。本人への入力・認証の変更・結果 JSON の更新は行わず、先の本番成功の結果を保持した
- 最終 fixture は Windows PowerShell 5.1 で全 21 項目・終了コード 0、両スクリプトの構文エラー 0 を確認した
- 最終 fixture の SHA-256 は `7D3027189B6C9FAB0E4352C2666A8CEE6533ABD139D62DF68DB45CCF733FA533`
- 最終 fixture は AST から関数 10 個だけを取り出し、本人への入力部分を実行しない。専用 GUID ディレクトリの公開データを使い、プロセス・タスク・HTTP は模擬する。後始末の対象は、その専用ディレクトリ内に限る
- 文字の検査は 31・32・512・513 文字、表示可能 ASCII の端、空白・TAB・LF・CR・CRLF・DEL・非 ASCII を確認した。実ファイルの原子的な置換、旧控えの保持、所有者・継承無し・本人の `Modify` ACL も確認した
- 新認証の接続確認失敗・起動要求失敗からの復元、復元後の確認失敗でファイルとサービスの状態を分けること、停止失敗時の未変更、置換先のロック時の旧ファイル保持を確認した
- 不正な入力を変更前に拒否すること、一時ファイルを消せない場合も主な失敗状態を保ち、そのファイル名を結果に残すことを確認した。本番の認証値・サービス・HTTP を使う試験ではない
- `-CheckOnly` は、入力・認証ファイルの変更・結果 JSON の保存より前に終了する。通常の実行は 32〜512 文字の表示可能な ASCII・空白無し・入力の一致を確かめる
- 文字の検査は文字列全体に `\A[\x21-\x7e]+\z` を使う。末尾の改行を許し得る `$` の境界は、公開 fixture の独立レビューで見つかり、修正した
- 置換完了・未変更・控えの復元・サービスの復帰を独立した結果に分ける。未変更時は控え無しのままサービスだけ復旧し、変更の有無が `null` なら未変更と断定しない
- 前提・入力の失敗は、今回の時刻と未変更の結果を保存する。結果 JSON を保存できない場合も、控え・失敗段階・後始末・今回の時刻をコンソールに残すことを公開 fixture で確認した
- 新認証・未認証・誤値・復元時の要求の前後と連続する確認で、専用プロセスの PID・開始時刻・実行パスを固定した。確認中や要求間の PID の置換を成功にしないことを公開 fixture で確認した
- 復元コピー直前に、専用タスクの `Ready` と 3080 番の解放を確認する。タスクが稼働中、または別の待ち受けがある場合はコピーせず、`FileRestored=false` になることを公開 fixture で確認した
- 旧認証を読み出さないため、`OldPasswordVerified` は `false` のままで、失敗後の復旧で旧認証の 200 は未確認
- 手動復元は extra に判定と復旧時の条件を記載した。ファイル未変更のままサービスだけを戻す分岐を分ける。控えから戻す必要があるのに実体が無い場合は中断し、専用以外のプロセスや子プロセスは止めない

### 共同レビューと最終確認

- Grok Build に、前回の 3 指摘への公開コードの修正差分、状態の定義、公開 fixture の結果だけを渡して再確認した。全ツール・Web 検索・subagent は無効にし、秘密・私的履歴・ホスト識別子を渡していない
- 終了コード 0 と完了の印を確認し、3 指摘は解消したとの報告を得た。追加の軽微な指摘は、不明状態の `null` がコンソールで空欄になることだった
- コンソールは文字列 `null` と表示し、JSON は実際の `null` を維持する形へ直した。JSON 保存不能時と保存成功時の公開 fixture を追加し、独立した差分レビューでも追加の指摘は無かった
- 両 OS の正本と extra の変更した手順を、説明から最後の箇条書きまで点検した。操作・コード・確認と分岐の順序、相対リンク・アンカー、両 OS の履歴手順の一致、既存の見出し・コード・過去の検証付録の保持を確認した
- `git diff --check` は出力無し。公開 fixture の末尾の空行も除いた。Windows PowerShell 5.1 で呼出ブロック 2 個の構文エラー 0、公開スクリプト 2 個の UTF-8 BOM を確認した

### 残る未確認

- エージェントによる変更後の HTTPS ログインの直接操作。本人の完了報告を、エージェントが画面で直接確認した結果として扱わない
- 実ホストでの変更失敗からの復元と、変更前の認証による本人の HTTPS ログイン。公開 fixture の模擬した結果とは分ける

## 付録: AlmaLinux 10.2 の3エージェント接続と共通パスワードの検証（2026-10-13 JST）

### 対象と実施前の状態

| 項目 | 値 |
|---|---|
| 実機 | AlmaLinux 10.2、aarch64。既存の Codeg・Caddy と本人の CLI のログインを使用 |
| Codeg | `codeg-server`・`codeg-mcp` v0.35.1 |
| Caddy | v2.11.7 |
| 本人の CLI | Claude Code 2.1.296、Codex 0.160.0、Grok Build 1.0.50 |
| 固定した ACP アダプター | Claude `0.89.1`、Codex `2.2.2` |
| 公式の Claude Code 用プラグイン | `codex@openai-codex` 1.0.6、`grok-build@xai-grok-build` 0.2.1 |
| 待ち受け | Codeg は `127.0.0.1:3080`、Caddy は `<SERVER_IP>:3443` |
| 常駐 | `codeg-server.service`・`codeg-caddy.service`、systemd のユーザーサービス |

- Codeg と Caddy は既に導入され、3 CLI も存在した。新規導入からの通しではなく、既存ホストへのアダプター・共同作業・パスワード変更の追加を検証した
- 公式の v0.35.1 の archive を公表された digest と照合し、展開した `codeg-server`・`codeg-mcp` と配置済みバイナリの SHA-256 が一致することを確認した
- 既存の認証ファイル・鍵・トークン・パスワードの本文、プロセスの引数と環境、サービスのログは読んでいない。CLI の本人のログインを再利用した
- 今回の実行は、手順書のブロック全体をそのまま上から通した結果ではない。公開スクリプトの試験、実ホストの直接確認、本人の報告を分ける

### ACP の接続と会話

| 確認 | Claude Code | Codex | Grok Build |
|---|---|---|---|
| ACP の初期化と新しいセッション | 成功 | 成功 | native ACP で成功 |
| セッションのモード設定 | `Auto` の設定成功 | `agent` の設定成功 | 接続成立 |
| ツールを使わない短文の応答 | 週の利用上限で未確認 | 成功 | 成功 |

- Claude と Codex は固定版のアダプターを使用した。Codeg の Grok は native ACP を使い、共同作業プラグイン向けの補助スクリプトとは接続経路を分けた
- Claude の初期化・会話作成・`Auto` の設定は成功したが、応答は本人の週の利用上限で失敗した。接続と設定の成功を、応答・編集・自動承認の成功へ広げない
- Codex・Grok の短文の応答は直接確認した。ファイル変更、危険な操作の承認・拒否、履歴の取り込みと再開を追加で検証したものではない

### 共同作業プラグインと Grok の読み取り専用実行

- 公式プラグインの setup/check は `ready` になった。補助スクリプトから Codex・Grok を直接呼び、短文の応答に検証用の印が含まれることも確認した
- Grok の内側の sandbox は Podman ソケットの `EACCES` で起動できなかった。Landlock の syscall が `ENOSYS` を返すことも別に確認した。ホストのソケット権限やカーネルは変えず、外側の bubblewrap で読み取り専用にした専用の起動経路を追加した
- 専用の起動元プロセスを使い、Grok の読み取り専用経路で `--write` を拒否した。Codeg が使う native ACP はこの補助スクリプトへ切り替えていない
- Codeg の DB の公開設定で、委譲の有効化（`delegation.enabled=true`）、深さ 1、worker の既定モード（Claude は `auto`、Codex は `agent`）を反映した
- 設定値の反映と直接呼出しの成功は、Codeg の画面からの実際の委譲の成功とは分ける。親エージェントの承認設定を画面で確かめた結果も無い

### 公開範囲とサービスの確認

- 利用者の指定で、firewalld の `public` ゾーンから以前の送信元付き rich rule 3 本を削除し、ホストの LAN IPv4 を宛先とする 3443/tcp の accept 1 本へ変更した
- runtime と permanent の両方で、宛先・ポートの一致と送信元指定が無いことを確認した。以前の 3 本は残っていない
- 両サービスが enabled・active で、Codeg は `127.0.0.1:3080`、Caddy は `<SERVER_IP>:3443` に限って待ち受けることを確認した
- Caddy の公開ルート証明書で TLS を検証し、認証を付けない HTTPS の `POST /api/health` が 401 を返すことを確認した。秘密を含むリクエストは送っていない
- `systemctl --user` の通常の接続は sandbox 内で失敗した。読み取りを許可した実行で `--machine=<USER>@.host` を使い、サービスの状態と非秘密の属性だけを確認した

### 共通パスワードの補助スクリプト

- Linux 用の公開スクリプトは `scripts/grok-build-remote/set-codeg-password.py`、公開 fixture は `scripts/grok-build-remote/test-codeg-password.py`。本人の端末で伏せ字の 2 回入力を行う方式を追加した
- 固定した公開値と一時ディレクトリを使う fixture 11 件が成功した。引用符・バックスラッシュ、不正な文字と権限、symlink 拒否、同時実行の拒否、置換と旧控えの保持を確認した
- fixture では、起動・認証確認・置換の失敗、rename 完了直後の割込みからの復帰、状態不明時の控え保持、秘密出力が journal に向く構成の起動拒否も確認した。実ホストのサービスと認証は模擬している
- `py_compile` は成功した。実ホストでは `--check` が成功し、設定の metadata、専用サービス、単一の loopback の worker、未認証 401 を確認した。既存の認証本文は読んでいない
- 公開版は、実ホストに置いた版の固定ユーザー・ホームを実行者の値へ一般化し、fixture は同じディレクトリのスクリプトを参照する形にした。公開版でも 11 件の fixture・Python の構文解析・実ホストの `--check` が成功した
- Codeg は監督プロセスと worker に分かれるため、MainPID だけを待ち受けの所有者とは扱わない。専用サービスの cgroup から worker を特定し、PID・開始時刻・実行ファイル・socket の同一性を確認する
- Codeg の起動時の秘密出力を保存しないため、`StandardError=null` と対象の `EnvironmentFiles` を、前提確認・本人の入力後・起動直前に検査する
- **本人報告**: 共通パスワードで HTTPS の Codeg にログインできた。本人のパスワードと、変更時のスクリプトが表示した新認証 200・未認証 401・誤入力 401 の結果はエージェントに渡されていない
- エージェントは通常の認証変更を実行していない。実変更のコードは公開 fixture の検証だけで、実機で認証変更の 3 条件すべてを直接確認した結果とは扱わない

### 共同レビューと記録の範囲

- Grok Build から、接続と秘密の取扱いに関する一般的な設計のレビューを得た。その一般レビューの入力には、ローカルの具体的なファイル・秘密・ホスト識別子を含めていない
- それ以前に、秘密を含まない補助スクリプトと設定の具体的なレビューも依頼したが、応答待ちを打ち切った。具体的な差分レビューの完了結果としては扱わない
- この一般レビューは、今回追加した公開ファイルの具体的な差分を検査した結果ではない。プラグインの `ready`、直接呼出し、ACP の接続、本人の画面操作を別々の結果として記録した
- `claude-agents.sh` の Bash の構文と、Grok の公開補助スクリプトの実ホストでの self-test も成功した。これらは native ACP の実際の委譲を確かめた結果ではない
- extra の Bash 5 ブロックは構文検査が成功した。firewalld・sudo を公開スタブに置き換えた 8 条件で、旧規則の追加・再照合より先に全送信元の規則を削除しないこと、照会失敗・送信元未設定時の停止、`ALLOW_FROM` 無しでの任意規則の撤去を確認した
- 接続元制限を戻す 2 手順と、変更した撤去ブロックは実ホストで実行していない。extra の変更した手順を説明から最後の箇条書きまで点検し、操作・コード・確認と分岐の順序を確認した。担当 3 文書の `git diff --check` は出力無し

### 残る未確認

- 本人のパスワード変更時の新認証 200・未認証 401・誤入力 401 の出力、実ホストでの変更失敗からの復帰、復帰後の旧認証によるログイン
- Claude の応答・編集と自動承認、Codeg の画面からの実際の委譲、親エージェントの承認設定、承認カードへの許可・拒否
- 3 エージェントの画面での通し操作、今回の変更後の OS 再起動・ログアウト、別端末・別拠点からの接続、証明書の期限をまたいだ稼働、アダプター・Caddy の更新とロールバック
