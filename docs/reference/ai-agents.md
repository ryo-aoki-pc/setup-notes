# AI コーディングエージェントのセットアップ（AlmaLinux 10・Windows 11）の参考資料

[手順書](../ai-agents.md)・[ロールバックと注意点](../extra/ai-agents.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md)

## 選択した方針

### 手順書を分ける範囲

- 2026-10-14、利用者の決定で、AI コーディングエージェントの手順を [AlmaLinux 10](../almalinux-setup.md)・[Windows 11](../windows-setup.md) の 2 冊から [ai-agents.md](../ai-agents.md) へ分けた
  - それまでは、操作を 2 冊へ集約する方針だった（PR #138。[集約時の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/consolidation.md)）
  - Claude Code・Codex CLI・Grok Build の導入・更新、Remote Control・tmux・GNOME 操作・共同作業・Grok Build のブラウザ操作（Codeg）を対象にした
  - 両 OS を 1 冊にし、「実施手順」を AlmaLinux 10、「Windows 11 で使う」を Windows 11 の手順にした
- ロールバックと注意点は [extra/ai-agents.md](../extra/ai-agents.md) へ移した
- 任意の構成の付属文書は、`coding-agents`・`grok-build-remote`・`claude-code-gui`・`windows-claude-remote-control` の旧名を保ち、手順へのリンク先だけを直した
- 導入 3 ツールの以前の参考資料と検証記録は移さず、両 OS の文書の「統合前の…」の節に残した
  - 参考資料は[以前の参考資料の場所](#以前の参考資料の場所)、検証記録は[以前の記録の場所](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md#以前の記録の場所)で案内する
- 分離は文書の移動で、新たな実機検証を意味しない。移した手順の検証範囲は、移す前の各記録のまま

### 見出しと共通の項

- 見出しの名前は保った。2 冊で同名の見出しは、AlmaLinux 10 側を保ち、Windows 11 側に「Windows 11 で」を付けた
  - 改名は 7 つ。たとえば「Claude Code」は、Windows 11 側を「Windows 11 で Claude Code を入れる」にした
- 「Grok Build のブラウザ操作: …」は「Codeg: …」へ改めなかった
  - アンカーの付け替えを最小にし、過去の検証記録の項名と一致させ続けるため。改名は別の変更に回した
- 同名の「コーディングエージェントの共同作業（任意）」「Grok Build のブラウザ操作（任意）」は、それぞれ 1 つにした
  - 両 OS 共通の項（ルート証明書、使い方の基本、設定ファイル、分担・レビュー・取り込み）を 1 か所に置けるため
- AlmaLinux 10 の「更新」は手順 5〜9 だけを移し、新しい本の[更新](../ai-agents.md#更新)の手順 1〜5 にした
- AI エージェントの状態で分岐する手順は、節の手順番号と検証記録を保つため、2 冊に残した
  - windows-setup.md の「リモートから再起動する手段を増やす」と「Git for Windows・Firefox・WezTerm を上げる」の、Remote Control のタスクの手順
  - almalinux-setup.md（2026-10-15 からは gnome-remote.md）の「GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）」の、仮想モニターのドロップインを外す手順
- 旧見出しと現在の節の対応は、[集約対応表の追補](../dev/consolidation-map.md#ai-エージェントの手順を-ai-agentsmd-へ分けたときの追補)で管理する

### 長いコードブロックの折りたたみ

- 利用者の決定で、ai-agents.md の長いコードブロックを `<details>` で包んだ。説明と確認の箇条書きが離れるのを避けるため
  - フェンスを除いて 20 行以上の 18 ブロック（bash 7、PowerShell 11）が対象
  - 20 行以上が全ブロックの上位 1 割ほどで、既存の唯一の前例（[WireGuard の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/wireguard.md)の 21 行）とも合うため、しきい値を 20 行にした
  - 変数のブロック、手で打つ `text` のブロック、1 行の説明に「（取り戻せない）」とある手順のブロックは折りたたまない
- タグは手順の本文と同じ 3 スペース字下げにし、`</summary>` の後と `</details>` の前後に空行を置く
  - 空行を崩すと GitHub がコードを地の文として出し、字下げを崩すと番号付きリストが切れることを、GitHub の Markdown API で確かめて決めた
  - `<summary>` は「貼るコマンド（PowerShell・50 行）」の形にし、言語とフェンスを除いた行数を示す
- GitHub の Web での開閉とコードブロックは[公式の説明](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/organizing-information-with-collapsed-sections)を参照した
  - 今回の描画の確認と、モバイルアプリなどの未確認範囲は[検証記録の付録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md#付録-ai-エージェントの手順を分けたときの静的な確認2026-10-14)に分ける

### スクリーンショットと Windows 11 の Codeg

- 利用者の決定で、手順書にスクリーンショットを貼ることにした
  - コマンドの無い手順の最後の箇条書き（「次の手順は、〜してから貼る」があれば、その直前）に 1 枚までとし、押す場所や成功の表示を示す
  - 本当のユーザー名・ホスト名・IP、入力済みの認証欄、証明書の画面は載せない
  - 撮影した環境と対象の版を節のリードに書き、画面内の値が試験用であることを断る
- Windows 11 の Codeg は、ランダムなトークンをブラウザへ入れずに、共通パスワードで使い始められるよう、分岐の箇条書きを 4 つ足した。コマンドは変えていない
  - Codeg の標準の認証に、トークンと別のパスワード専用設定があるという意味ではない（[Grok Build の調査](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md#grok-build-の調査)）

### Windows 11 の Antigravity CLI

- Windows 11 では、Google 公式の [PowerShell のインストーラー](https://antigravity.google/cli/install.ps1)で Antigravity CLI（`agy`）を入れる
  - WinGet・npm には無いので、公式の配布物を公式のインストーラーで入れる形にした
- Gemini CLI は、2026-06-18 に個人アカウントへの提供を終え、Antigravity CLI が後継になった
- AlmaLinux 10 では扱わない。Windows 11 の [導入](../ai-agents.md#windows-11-で-antigravity-cli-を入れる)・[設定ファイル](../ai-agents.md#antigravity-cli-の設定ファイル)・更新を対象にする
- 更新はバックグラウンドの自動更新と `agy update` を使う。公式インストーラーは、既に入っていれば入れ直さず、自動更新を案内する
- Codeg の「Google Antigravity」は、CLI とは別の製品の ACP サーバーで、ログインも別になる。[Codeg の参考資料](grok-build-remote.md)で分けて扱う

### Windows 11 の Antigravity アプリの Remote Control

- 2026-10-15、利用者の決定で、Windows 11 ではデスクトップアプリの [Remote Control](../ai-agents.md#antigravity-アプリの-remote-control任意) を使うことにした。Antigravity CLI は前提にしない
- 公式文書には、CLI の常駐デーモン（`agy remote-control start`）という別の方法もある。この PC では登録しておらず、使っていない
  - アプリは動いている間だけ接続できる。CLI のデーモンは、公式文書で説明されている常駐する別の入口
  - 共有の `%USERPROFILE%\.gemini\config\config.json` でも、アプリの名前は `userSettings.remoteControlHostname`、CLI のデーモンの名前は `cliRemoteControlHostname` と、別のキーを使う
- この PC ではアプリの導入後に自動起動が登録されなかったため、利用者の決定で、ログオン時の起動用にスタートアップのフォルダーへショートカットを置いた
  - ショートカットから手で起動できることは確かめた。サインアウト・再起動後の自動起動は確かめていない
- 窓を閉じても動かすため Keep In Menu Bar をオンにし、公式の説明に沿って Prevent Sleep もオンにする
  - Keep In Menu Bar がオンの状態では、窓を閉じた後も接続できた。Prevent Sleep が実際にスリープを防ぐことは確かめていない
- インストーラーを実行する前に、有効な署名と、署名者が Google LLC であることを確かめる。版を含む URL は固定し、新しい版の URL は公式のダウンロードのページで取り直す

## 補足

### Windows 11 で使う / Windows 11 で Antigravity CLI を入れる / 手順 2: 補足: 公式インストーラーの照合

- 公式インストーラーは、マニフェストにある URL から本体を取り、SHA-512 を照合して `%LOCALAPPDATA%\agy\bin\agy.exe` に置き、`agy.exe install` を呼ぶ
- ユーザーの PATH に `%LOCALAPPDATA%\agy\bin` を足す。既に開いている窓の PATH には反映されないため、[Windows 11 で Antigravity CLI を入れる](../ai-agents.md#windows-11-で-antigravity-cli-を入れる)の手順 4 で窓を開き直す

### Windows 11 で使う / Windows 11 で Antigravity CLI を入れる / 手順 3: 補足: staging の一時ファイル

- 今回、保存したインストーラーを scriptblock の形で実行したところ、`%LOCALAPPDATA%\antigravity\staging\agy.exe` が残った。本体と同じハッシュの一時ファイルだった
- 残る理由は、scriptblock で実行したとき、`finally` が見る `$stagingPayload` と、関数が書く `$script:stagingPayload` が別の変数になるためと推定した
- `irm | iex` の形では同じ変数になるはずだが、確認していない

### Windows 11 で使う / Windows 11 で Antigravity CLI を入れる / 手順 6: 補足: ログインの保存先

- 個人の Google アカウントでブラウザからログインする。CLI の資格情報は Windows の資格情報マネージャーの `gemini:antigravity` に保存される
- ログイン後の設定・ログ・会話・更新の情報などは `%USERPROFILE%\.gemini\antigravity-cli`、共通の設定は `%USERPROFILE%\.gemini\config` に作られる

### Antigravity アプリの Remote Control / 実施手順 / 手順 2: 補足: 署名と版の確認

- ダウンロードの URL には版が入っている。新しい版へ変えるときは、公式のダウンロードのページから、その版の URL を取り直す
- 実行前に `Get-AuthenticodeSignature` の `Status` と `SignerCertificate.Subject` を見て、有効な Google LLC の署名を持つ配布物であることを確かめる。`VersionInfo` では製品名と版を確かめる

### Antigravity アプリの Remote Control / 実施手順 / 手順 5: 補足: CLI とは別のログイン

- アプリの Google アカウントへのログインは、Antigravity CLI とは別になる。CLI にログイン済みでも、アプリでログインする
- アプリのログイン画面の細部と、ログイン情報の保存先は確かめていない

### Antigravity アプリの Remote Control / 実施手順 / 手順 6: 補足: 設定画面と自動の名前

- 公式文書は設定の節を App と書くが、画面の名前は Application。PC のアプリの Remote Control の正確な項目名と Nickname の変え方は、Claude は画面で確かめていない
- 公式文書の Nickname を変えなかった場合、この PC では `<ホスト名>-<2 語>` の名前が自動で付いた。手順書では設定ファイルから名前を読み、ブラウザで接続先を選ぶときに使う
- Keep In Menu Bar は、すべての窓を閉じてもアプリを動かす設定。Prevent Sleep は、アプリが動いている間のスリープを防ぐ設定として説明されているが、実際に防ぐかは確かめていない

### Antigravity アプリの Remote Control / 実施手順 / 手順 7: 補足: 設定の表示を絞る理由

- 設定ファイル全体には、ログインしたアカウントなども入る。手順書では Remote Control の有効・無効と名前、バックグラウンド動作とスリープ抑止の 4 つの値だけを表示する
- `%USERPROFILE%\.gemini\config\config.json` は CLI と共有する場所だが、アプリの Remote Control は `userSettings.remoteControlEnabled` と `remoteControlHostname` を使う

### Antigravity アプリの Remote Control / 実施手順 / 手順 8: 補足: スタートアップのショートカット

- この PC では、アプリの導入後に HKCU の Run・スタートアップのフォルダー・タスク スケジューラのいずれにも自動起動が登録されなかった。利用者の決定でスタートアップのショートカットを使う
- ショートカットからの手動起動では窓が開く。ログオン後に自動で起動し、一覧が Online に戻ることまでは確かめていない

### Antigravity アプリの Remote Control / 実施手順 / 手順 10: 補足: ブラウザとモバイル

- 公式文書では、ブラウザはアプリと同じ Google アカウントでサインインする。`Remote control is not enabled for your account.` は、アカウントや組織で機能が有効でないときの表示として説明されている
- モバイルでは Web アプリをホーム画面へ追加すると、エージェントの完了時と入力待ちにプッシュ通知を受け取れると公式文書にある。スマートフォンでのアクセス、ホーム画面への追加、プッシュ通知は実機で確かめていない

## 以前の参考資料の場所

導入の参考資料は、両 OS の文書の「統合前の参考資料」の節に残してある。任意の構成の参考資料は、旧名のファイルを使う。

| 対象 | 参考資料 |
| --- | --- |
| Claude Code の導入 | [AlmaLinux 10 の統合前の参考資料](almalinux-setup.md#統合前の参考資料-claude-codeもとは-claude-codemd)・[Windows 11 の統合前の参考資料](windows-setup.md#統合前の参考資料-claude-code-の-windows-11もとは-claude-codemd) |
| Codex CLI の導入 | [AlmaLinux 10 の統合前の参考資料](almalinux-setup.md#統合前の参考資料-codex-cliもとは-codexmd)・[Windows 11 の統合前の参考資料](windows-setup.md#統合前の参考資料-codex-cli-の-windows-11もとは-codexmd) |
| Grok Build の導入 | [AlmaLinux 10 の統合前の参考資料](almalinux-setup.md#統合前の参考資料-grok-buildもとは-grok-buildmd)・[Windows 11 の統合前の参考資料](windows-setup.md#統合前の参考資料-grok-build-の-windows-11もとは-grok-buildmd) |
| コーディングエージェントの共同作業 | [coding-agents.md](coding-agents.md) |
| Grok Build のブラウザ操作（Codeg） | [grok-build-remote.md](grok-build-remote.md) |
| Claude Code の GNOME 操作 | [claude-code-gui.md](claude-code-gui.md) |
| Windows 11 の Claude Code の Remote Control | [windows-claude-remote-control.md](windows-claude-remote-control.md) |

## 参照

2026-10-14 の Grok Build の調査で参照した一次情報。調査結果は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md#grok-build-の調査)に記録する。

| 資料 | 参照した内容 |
| --- | --- |
| [Codeg v0.35.1](https://github.com/spacering-net/codeg/releases/tag/v0.35.1) | 公開日・配布物 |
| [Codeg Configuration](https://docs.codeg.app/getting-started/configuration) | `CODEG_*` の環境変数・トークンの設定 |
| [Codeg v0.35.1: src/app/login/page.tsx](https://github.com/spacering-net/codeg/blob/v0.35.1/src/app/login/page.tsx) | ログイン画面の保存先 `codeg_token` |
| [Codeg v0.35.1: src/lib/transport/web-auth.ts](https://github.com/spacering-net/codeg/blob/v0.35.1/src/lib/transport/web-auth.ts) | localStorage のキー `codeg_token` の読み書き |
| [Codeg v0.35.1: src-tauri/src/web/auth.rs](https://github.com/spacering-net/codeg/blob/v0.35.1/src-tauri/src/web/auth.rs) | 共有トークンの Bearer 照合 |
| [Codeg v0.35.1: src-tauri/src/acp/registry.rs](https://github.com/spacering-net/codeg/blob/v0.35.1/src-tauri/src/acp/registry.rs) | Claude Code・Codex CLI のアダプターの版 |
| [Caddy v2.11.7](https://github.com/caddyserver/caddy/releases/tag/v2.11.7) | 公開日 |
| [Caddyfile: Global options](https://caddyserver.com/docs/caddyfile/options) | HTTPS・信頼ストア・ローカル CA の設定 |
| [Caddyfile: tls](https://caddyserver.com/docs/caddyfile/directives/tls) | 内部 CA とオンデマンドの TLS |
| [GitHub: Organizing information with collapsed sections](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/organizing-information-with-collapsed-sections) | `<details>`・`<summary>` と内部のコードブロック |

Windows 11 の Antigravity アプリの Remote Control は、2026-10-15 に読んだ次の一次情報を参照した。実機で確かめた範囲は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/ai-agents.md#付録-windows-11-の-antigravity-アプリの-remote-control2026-10-15-jst)に記録する。

| 資料 | 参照した内容 |
| --- | --- |
| [Antigravity: Remote Control](https://antigravity.google/docs/remote-control/) | アプリの設定・接続、CLI の別の入口、モバイルのホーム画面への追加とプッシュ通知 |
| [Antigravity: Download](https://antigravity.google/download) | Windows のアプリの配布物・要件、別製品の Antigravity IDE |
| [Remote Control for Antigravity（2026-08-21）](https://antigravity.google/blog/remote-control-for-antigravity/) | Remote Control の案内 |
| [Antigravity: Permissions](https://antigravity.google/docs/permissions) | Windows のアプリの権限、ターミナルのコマンドの承認、プロジェクトの中の読み書き |
