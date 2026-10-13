# AI コーディングエージェントのセットアップ（AlmaLinux 10・Windows 11）の参考資料

[手順書](../ai-agents.md)・[ロールバックと注意点](../extra/ai-agents.md)・[検証記録](../verification/ai-agents.md)

## 選択した方針

### 手順書を分ける範囲

- 2026-10-14、利用者の決定で、AI コーディングエージェントの手順を [AlmaLinux 10](../almalinux-setup.md)・[Windows 11](../windows-setup.md) の 2 冊から [ai-agents.md](../ai-agents.md) へ分けた
  - それまでは、操作を 2 冊へ集約する方針だった（PR #138。[集約時の検証記録](../verification/consolidation.md)）
  - Claude Code・Codex CLI・Grok Build の導入・更新、Remote Control・tmux・GNOME 操作・共同作業・Grok Build のブラウザ操作（Codeg）を対象にした
  - 両 OS を 1 冊にし、「実施手順」を AlmaLinux 10、「Windows 11 で使う」を Windows 11 の手順にした
- ロールバックと注意点は [extra/ai-agents.md](../extra/ai-agents.md) へ移した
- 任意の構成の付属文書は、`coding-agents`・`grok-build-remote`・`claude-code-gui`・`windows-claude-remote-control` の旧名を保ち、手順へのリンク先だけを直した
- 導入 3 ツールの以前の参考資料と検証記録は移さず、両 OS の文書の「統合前の…」の節に残した
  - 参考資料は[以前の参考資料の場所](#以前の参考資料の場所)、検証記録は[以前の記録の場所](../verification/ai-agents.md#以前の記録の場所)で案内する
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
  - windows-setup.md の「リモートから再起動する手段を増やす（任意）」と「Git for Windows・Firefox・WezTerm を上げる」の、Remote Control のタスクの手順
  - almalinux-setup.md の「GNOME のヘッドレスセッション: リモートログインだけにする（併用をやめる）」の、仮想モニターのドロップインを外す手順
- 旧見出しと現在の節の対応は、[集約対応表の追補](../dev/consolidation-map.md#ai-エージェントの手順を-ai-agentsmd-へ分けたときの追補)で管理する

### 長いコードブロックの折りたたみ

- 利用者の決定で、ai-agents.md の長いコードブロックを `<details>` で包んだ。説明と確認の箇条書きが離れるのを避けるため
  - フェンスを除いて 20 行以上の 18 ブロック（bash 7、PowerShell 11）が対象
  - 20 行以上が全ブロックの上位 1 割ほどで、既存の唯一の前例（[WireGuard の検証記録](../verification/wireguard.md)の 21 行）とも合うため、しきい値を 20 行にした
  - 変数のブロック、手で打つ `text` のブロック、1 行の説明に「（取り戻せない）」とある手順のブロックは折りたたまない
- タグは手順の本文と同じ 3 スペース字下げにし、`</summary>` の後と `</details>` の前後に空行を置く
  - 空行を崩すと GitHub がコードを地の文として出し、字下げを崩すと番号付きリストが切れることを、GitHub の Markdown API で確かめて決めた
  - `<summary>` は「貼るコマンド（PowerShell・50 行）」の形にし、言語とフェンスを除いた行数を示す
- GitHub の Web での開閉とコードブロックは[公式の説明](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/organizing-information-with-collapsed-sections)を参照した
  - 今回の描画の確認と、モバイルアプリなどの未確認範囲は[検証記録の付録](../verification/ai-agents.md#付録-ai-エージェントの手順を分けたときの静的な確認2026-10-14)に分ける

### スクリーンショットと Windows 11 の Codeg

- 利用者の決定で、手順書にスクリーンショットを貼ることにした
  - コマンドの無い手順の最後の箇条書き（「次の手順は、〜してから貼る」があれば、その直前）に 1 枚までとし、押す場所や成功の表示を示す
  - 本当のユーザー名・ホスト名・IP、入力済みの認証欄、証明書の画面は載せない
  - 撮影した環境と対象の版を節のリードに書き、画面内の値が試験用であることを断る
- Windows 11 の Codeg は、ランダムなトークンをブラウザへ入れずに、共通パスワードで使い始められるよう、分岐の箇条書きを 4 つ足した。コマンドは変えていない
  - Codeg の標準の認証に、トークンと別のパスワード専用設定があるという意味ではない（[Grok Build の調査](../verification/ai-agents.md#grok-build-の調査)）

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

2026-10-14 の Grok Build の調査で参照した一次情報。調査結果は[検証記録](../verification/ai-agents.md#grok-build-の調査)に記録する。

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
