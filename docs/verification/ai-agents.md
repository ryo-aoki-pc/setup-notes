# AI コーディングエージェントのセットアップ（AlmaLinux 10・Windows 11）の検証記録

[手順書](../ai-agents.md)・[ロールバックと注意点](../extra/ai-agents.md)・[参考資料](../reference/ai-agents.md)

## 対象と検証環境

- **状態**（2026-10-14）: AI エージェントの手順を 2 冊から ai-agents.md へ分けた変更を、静的に確認した
  - 通したこと: 相対リンク・見出しアンカーと移動の同一性の検査、折りたたみの描画、PowerShell と bash の構文解析
  - 確認したこと: 移動前後のコードブロック数と手順数、過去の検証本文の保持、レビューの指摘への修正
  - 確認していないこと: 今回の AlmaLinux 10 の手順の実行、Windows 11 の実機での Codeg の入れ直し、ShellCheck、GitHub のモバイルアプリでの折りたたみ表示
- 分離は文書の移動で、新たな実機検証を意味しない。移した手順の検証範囲は、移す前の各記録のまま
- 旧見出しと現在の節は、[集約対応表の追補](../dev/consolidation-map.md#ai-エージェントの手順を-ai-agentsmd-へ分けたときの追補)で対応させる

| 項目 | 値 |
| --- | --- |
| 実施日 | 2026-10-14 |
| 検査した PC | Windows 11 |
| 基準コミット | main の `89f9712b56f018a993fe9bf12f5a4bb2f9e4a976` |
| Claude Code の検査対象 | `a21d707a04eb2dd61633d0281411ad27705aa8db` |
| Codex の独立検査対象 | `05f5998d1039925ca444219e10cabb27cb2af8cc` |
| PowerShell（Claude Code） | Windows PowerShell 5.1.26100.9444、PowerShell 7.6.6 |
| bash（Claude Code） | Git Bash の GNU bash 5.3.15 |
| PowerShell（Codex） | Windows PowerShell 5.1.26100.9444。PowerShell 7 は実行ファイルを見つけられず未確認 |
| 検査の形 | Claude Code はリポジトリに入れない一時スクリプト、Codex は別の実装によるオフラインの検査 |

> [!NOTE]
> 本当のホスト名・ユーザー名・IP と秘密情報は記録しない。パスワード・鍵・トークンの値は載せない。コードブロックは構文解析だけで、実行していない。

## 実施前の状態

- 基準コミットでは、AI エージェントの操作は [AlmaLinux 10](../almalinux-setup.md)・[Windows 11](../windows-setup.md) の 2 冊へ集約されていた（PR #138）
- ロールバックと注意点は、両 OS の extra にあった
- 導入 3 ツールの過去の参考資料・検証記録と、任意の構成の付属文書は、それぞれの既存ファイルにあった

## 完了時点の状態

- 導入・更新・Remote Control・tmux・GNOME 操作・共同作業・Grok Build のブラウザ操作（Codeg）は ai-agents.md、ロールバックと注意点は extra/ai-agents.md に分かれた
- 導入の過去の記録と、任意の構成の付属文書は元の場所に残り、リンク先だけが現在の手順を指す
- 静的な確認とレビューの修正は付録に記録する。実機での成功範囲は広げていない

## 以前の記録の場所

導入の検証記録は、両 OS の文書の「統合前の記録」の節に残してある。任意の構成の検証記録は旧名を保ち、本文と当時の手順番号を変えていない。

| 対象 | 検証記録 |
| --- | --- |
| Claude Code の導入 | [AlmaLinux 10 の統合前の記録](almalinux-setup.md#統合前の記録-claude-codeもとは-claude-codemd)・[Windows 11 の統合前の記録](windows-setup.md#統合前の記録-claude-code-の-windows-11もとは-claude-codemd) |
| Codex CLI の導入 | [AlmaLinux 10 の統合前の記録](almalinux-setup.md#統合前の記録-codex-cliもとは-codexmd)・[Windows 11 の統合前の記録](windows-setup.md#統合前の記録-codex-cli-の-windows-11もとは-codexmd) |
| Grok Build の導入 | [AlmaLinux 10 の統合前の記録](almalinux-setup.md#統合前の記録-grok-buildもとは-grok-buildmd)・[Windows 11 の統合前の記録](windows-setup.md#統合前の記録-grok-build-の-windows-11もとは-grok-buildmd) |
| コーディングエージェントの共同作業 | [coding-agents.md](coding-agents.md) |
| Grok Build のブラウザ操作（Codeg） | [grok-build-remote.md](grok-build-remote.md) |
| Claude Code の GNOME 操作 | [claude-code-gui.md](claude-code-gui.md) |
| Windows 11 の Claude Code の Remote Control | [windows-claude-remote-control.md](windows-claude-remote-control.md) |

## 付録: AI エージェントの手順を分けたときの静的な確認（2026-10-14）

### Claude Code の検査

- 対象は `a21d707`、基準は `89f9712`。一時スクリプトで、文書の移動と表示を検査した
- 相対リンク 5,994 本（うち画像 56）と見出しアンカーの切れは 0
  - 基準 `89f9712` でも切れは 0
  - 3 冊（almalinux-setup.md・windows-setup.md・ai-agents.md）と extra/ai-agents.md の重複アンカーは 0
- 移動の同一性は、基準の 4 ファイル（2 冊と extra 2 つ）と、移動後の 6 ファイルを照合した
  - コードブロックは 1,391 個のまま、行頭 `1. ` の手順は 1,681 個のまま
  - 中身が変わったコードブロックは 2 個だけ
  - 「Windows 11 で Claude Code を入れる」のメッセージの 2 行で、「「Claude Code」の手順 N」を「この項の手順 N」に直した
- 過去の検証記録は、リンク先（`](…)` の中）だけの変更だった
  - 対象は docs/verification/ の全ファイルと docs/almalinux-vm-verification.md・docs/hypervisor-verification.md
  - 本文と当時の手順番号は変えていない
- 折りたたみは 18 個とも、`<summary>` の言語と行数が実数と一致した
  - GitHub の Markdown API（gfm）で、折りたたみを含む 12 の項を描画した
  - 18 個とも `<details>` の直下に色付きのコードが出た
  - 各項の番号付きリストは 1 つの `<ol>` のままで、地の文にコードフェンスが残らなかった
- ai-agents.md と extra/ai-agents.md の構文を解析した。手順のコマンドは実行していない
  - PowerShell 87 ブロックは、Windows PowerShell 5.1.26100.9444 と PowerShell 7.6.6 の `Parser::ParseFile` でエラー 0
  - bash 110 ブロックは、Git Bash（GNU bash 5.3.15）の `bash -n` でエラー 0
- `git diff --check` は通過した
- ShellCheck はこの PC に無く、流していない

### Codex の独立検査

- 対象は `05f5998`、基準は `89f9712`。Claude Code の一時スクリプトとは別の実装で、オフラインで検査した
  - 検査器と出力はリポジトリに入れていない（作業用 clone の未追跡のディレクトリに置き、作業の後に消した）。検査対象の文書は作業ツリーではなく、`git show commit:path` で読んだ
  - Claude Code の検査とは対象コミットが異なるため、数値を分けて記録する
- 相対リンク・画像は 5,976 本、見出しアンカーの照合は 5,081 件で、切れは 0
  - 画像は 56 本。基準側でもリンク・アンカーの切れは 0
  - 3 冊と extra/ai-agents.md の重複アンカーは 0
- 基準の 4 ファイルと移動後の 6 ファイルで、コードブロック 1,391 個、行頭 `1. ` の手順 1,681 個が一致した
  - この時点では、言語と本文を比べたコードブロックの多重集合の差は 0
- 対象 6 ファイル以外の Markdown 129 ファイルを比較し、許容外の本文差は 0
  - 無変更 93、リンク先変更または指定例外 36
  - 指定例外は、AGENTS.md のコメントの文書名 1 か所と、consolidation-map.md 末尾の追補 84 行
- 手順の並び順を、基準 4 ファイルと対象 6 ファイルの全 1,681 手順（コマンド付き 1,325 手順）で自動点検した
  - 箇条書きがコードの前や間にある違反は 0
  - 実行前の `[!CAUTION]` の欠落は、この順序点検とは別の問題として指摘した
- 構文解析だけを行い、手順のコマンドは実行していない
  - Windows PowerShell 5.1.26100.9444 の `ParseInput` で、対象 87 ブロックと基準 508 ブロックのエラーは 0
  - Git Bash の `bash -n` で、対象 110 ブロックと基準 875 ブロックの構文エラーは 0
  - PowerShell 7 は実行ファイルを見つけられず未確認。その後の Claude Code の PowerShell 7.6.6 の解析結果は、前の節に分けた

### レビューの指摘と対応（1 回目）

Codex の指摘と、`a21d707` までの対応を記録する。手順番号は指摘時のもの。

| 重大度 | 指摘 | 対応 |
| --- | --- | --- |
| 中 | 取り戻せない削除（AlmaLinux 10 の手順 11、Windows 11 の手順 5・14）の `[!CAUTION]` が、旧 extra 2 冊に残り、新しい extra に無かった | `27e2d20` で、extra/ai-agents.md の[ロールバック](../extra/ai-agents.md#ロールバック)と[Windows 11 のロールバック](../extra/ai-agents.md#windows-11-のロールバック)のリードへ移した |
| 中 | ai-agents.md の「使う OS の初期設定の「Claude Code」」が、移動済みの項を旧文書の項として案内していた | `f20385f` で、現在の手順を指すよう直した |
| 低 | ai-agents.md の表示名 18 か所に、旧文書名が残っていた | `f20385f` で直した |
| 低 | AGENTS.md と windows-setup.md の「同書の」が、分かれた別の本を指していた | `b8d3bc9`・`a21d707` で、指す本の名前に直した |

### Grok Build の調査

2026-10-14、Grok Build が Web の一次情報で確認した内容。手順を実機で実行した結果とは分ける。

- Codeg の最新の安定版は v0.35.1（2026-10-11 公開）で、調査時点でより新しいリリースは無かった（[リリース](https://github.com/spacering-net/codeg/releases/tag/v0.35.1)）
  - 配布物の名前、`CODEG_*` の環境変数、共有トークン 1 個の Bearer 照合、認証付きの `POST /api/health` に、手順書と食い違う変更は無かった（[Configuration](https://docs.codeg.app/getting-started/configuration)）
- 標準の認証に、トークン以外のパスワード専用設定は無かった
  - ログイン画面は入力値を localStorage のキー `codeg_token` に保存する（[v0.35.1 のログイン画面](https://github.com/spacering-net/codeg/blob/v0.35.1/src/app/login/page.tsx)・[保存先の読み書き](https://github.com/spacering-net/codeg/blob/v0.35.1/src/lib/transport/web-auth.ts)）
- v0.35.1 がピンするアダプターは `claude-agent-acp 0.89.1` と `codex-acp 2.2.2`（[registry.rs](https://github.com/spacering-net/codeg/blob/v0.35.1/src-tauri/src/acp/registry.rs)）
- Caddy の最新の安定版は v2.11.7（2026-10-03 公開）だった（[リリース](https://github.com/caddyserver/caddy/releases/tag/v2.11.7)）
  - `tls internal { on_demand }`・`auto_https disable_redirects`・`skip_install_trust`・`pki { ca local { name … } }` の書き方に、破壊的な変更は無かった（[全体設定](https://caddyserver.com/docs/caddyfile/options)・[TLS 設定](https://caddyserver.com/docs/caddyfile/directives/tls)）
- GitHub の Web では `<details>` を開閉でき、中のコードブロックも使える（[公式の説明](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/organizing-information-with-collapsed-sections)）
  - モバイルアプリでの表示、Safari で閉じた中身をページ内検索できるか、閉じた状態でのコピーボタンは未確認

### 残る未確認

- AlmaLinux 10 の手順は今回流していない。分離前の実機・VM・コンテナの検証範囲を、今回の静的な確認から広げない
- Windows 11 の実機での Codeg の入れ直しは、[grok-build-remote.md](grok-build-remote.md) の新しい付録に別に記録する
- GitHub のモバイルアプリでの折りたたみの表示、Safari で閉じた中身のページ内検索、閉じた状態でのコピーボタン
- ShellCheck は未実施
