# AI コーディングエージェントのセットアップ（AlmaLinux 10・Windows 11）の検証記録

[手順書](../ai-agents.md)・[ロールバックと注意点](../extra/ai-agents.md)・[参考資料](../reference/ai-agents.md)

## 対象と検証環境

- **状態**（2026-10-14）: AI エージェントの手順を 2 冊から ai-agents.md へ分けた変更を、静的に確認した
  - 通したこと: 相対リンク・見出しアンカーと移動の同一性の検査、折りたたみの描画、PowerShell と bash の構文解析
  - 確認したこと: 移動前後のコードブロック数と手順数、過去の検証本文の保持、GitHub のページでの折りたたみと画像の表示、2 回のレビューの指摘への修正
  - 確認していないこと: 今回の AlmaLinux 10 の手順の実行、ShellCheck、GitHub のモバイルアプリでの折りたたみ表示
  - この静的な確認では、手順を実行していない。Windows 11 の実機で Codeg を入れ直した結果は、[grok-build-remote.md の 2026-10-14 の付録](grok-build-remote.md#付録-windows-11-の入れ直しと共通パスワード3-エージェントの接続の検証2026-10-14-jst)に分けて記録した
- 分離は文書の移動で、新たな実機検証を意味しない。移した手順の検証範囲は、移す前の各記録のまま
- 旧見出しと現在の節は、[集約対応表の追補](../dev/consolidation-map.md#ai-エージェントの手順を-ai-agentsmd-へ分けたときの追補)で対応させる

| 項目 | 値 |
| --- | --- |
| 実施日 | 2026-10-14 |
| 検査した PC | Windows 11 |
| 基準コミット | main の `89f9712b56f018a993fe9bf12f5a4bb2f9e4a976` |
| Claude Code の検査対象 | `e6b95c412ac50cf481e79d5b410dd8a5ea0aa601` |
| Codex の独立検査対象 | 1 回目は `05f5998d1039925ca444219e10cabb27cb2af8cc`、2 回目は `0fe813e`（2 回目のレビューの時点の先頭） |
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

- 対象は `e6b95c4`、基準は `89f9712`。リポジトリに入れない一時スクリプトで、文書の移動と表示を検査した
- 相対リンク 6,071 本（うち画像 61）と見出しアンカーの切れは 0
  - 基準 `89f9712` でも切れは 0
  - 3 冊（almalinux-setup.md・windows-setup.md・ai-agents.md）と extra/ai-agents.md の重複アンカーは 0
- 移動の同一性は、基準の 4 ファイル（2 冊と extra 2 つ）と、移動後の 6 ファイルを照合した
  - コードブロックは 1,391 個のまま、行頭 `1. ` の手順は 1,681 個のまま
  - 中身が変わったコードブロックは 4 個で、どれも中断のメッセージの 1 行
  - 「Windows 11 で Claude Code を入れる」の 2 行は、「「Claude Code」の手順 N」を「この項の手順 N」に直した
  - 共同作業の「分担して作業する」の手順 1・2 の 2 行は、「実施手順」「Windows 11 で使う」を項の名前に直した
- 過去の検証記録は、リンク先（`](…)` の中）だけの変更だった
  - 対象は docs/verification/ の既存のファイルと docs/almalinux-vm-verification.md・docs/hypervisor-verification.md
  - grok-build-remote.md だけは、2026-10-14 の付録と状態行の追記があり、状態の段落の 1 文を今回の結果に合わせて直した。ほかの既存の行は変えていない
- 折りたたみは 18 個とも、`<summary>` の言語と行数が実数と一致した
  - GitHub の Markdown API（gfm）で、折りたたみを含む 12 の項を描画した
  - 18 個とも `<details>` の直下に色付きのコードが出た
  - 各項の番号付きリストは 1 つの `<ol>` のままで、地の文にコードフェンスが残らなかった
- ai-agents.md と extra/ai-agents.md の構文を解析した。手順のコマンドは実行していない
  - PowerShell 87 ブロックは、Windows PowerShell 5.1.26100.9444 と PowerShell 7.6.6 の `Parser::ParseFile` でエラー 0
  - bash 110 ブロックは、Git Bash（GNU bash 5.3.15）の `bash -n` でエラー 0
- `git diff --check` は通過した
- ShellCheck はこの PC に無く、流していない

### GitHub のページでの確認

push したブランチの ai-agents.md を、GitHub の Web のページで開いて確かめた（`0fe813e` の時点。デスクトップのブラウザ）。

- `<details>` は 18 個で、どれも番号付きリストの項目の中にあり、中にコードブロックがあった
- 50 行の PowerShell のブロックの `<summary>` を押すと開き、コードとコピーボタンが出た。その手順は、10 手順のリストの 7 番目のままだった
- 画像 5 枚は読み込まれ、幅は 960 px が 1 枚、1,440 px が 4 枚だった
- ページは最後の項まで描画され、地の文にコードフェンスは残っていなかった

### Codex の独立検査

- Claude Code の一時スクリプトとは別の実装で、オフラインで 2 回検査した
  - 検査器と出力はリポジトリに入れていない（作業用 clone の未追跡のディレクトリに置き、作業の後に消した）。検査対象の文書は作業ツリーではなく、`git show commit:path` で読んだ
  - Claude Code の検査とは対象コミットが異なるため、数値を分けて記録する
- 1 回目は `05f5998`（移動のコミット）を検査した
  - 相対リンク・画像は 5,976 本（画像は 56 本）、見出しアンカーの照合は 5,081 件で、切れは 0。基準側でも切れは 0
  - 3 冊と extra/ai-agents.md の重複アンカーは 0
  - 基準の 4 ファイルと移動後の 6 ファイルで、コードブロック 1,391 個、行頭 `1. ` の手順 1,681 個が一致した。この時点では、コードブロックの多重集合の差は 0
  - 対象 6 ファイル以外の Markdown 129 ファイルを比較し、許容外の本文差は 0（無変更 93、リンク先変更または指定例外 36）
  - 全 1,681 手順（コマンド付き 1,325 手順）で、箇条書きがコードの前や間にある違反は 0
  - Windows PowerShell 5.1.26100.9444 の `ParseInput` で、対象 87 ブロックと基準 508 ブロックのエラーは 0。Git Bash の `bash -n` で、対象 110 ブロックと基準 875 ブロックのエラーは 0
- 2 回目は `0fe813e` を検査した
  - 相対リンク・画像は 6,068 本、見出しの参照は 5,137 件で、切れは 0。重複アンカーは 0
  - コードブロック 1,391 個と手順 1,681 個を保ち、中身が変わったコードブロックは 4 個で、どれも中断のメッセージの 1 行だった
  - 過去の記録は、既存の 45 ファイルのうち無変更 28、リンク先だけの変更 16、追記 1。リンク先を除く既存の本文の変更・削除は 0 だった
  - 折りたたみ 18 個は、言語・行数・字下げ・空行とも決まりに合い、漏れも、折りたたんではいけないブロックの折りたたみも 0 だった
  - 画像 5 枚を開いて見て、幅は最大 1,440 px、本当のユーザー名・ホスト名・IP・認証値の露出は 0 と判定した。ぼかしを戻せるかの検査はしていない
  - 差分の全体（52 ファイル）で、トークン・パスワード・鍵・実在のホスト名・LAN の IP・ユーザー名のパスの混入は 0 と判定した
- PowerShell 7 は、2 回とも実行ファイルを見つけられず未検査。PowerShell 7.6.6 の解析結果は、前の「Claude Code の検査」のもの

### レビューの指摘と対応（1 回目）

Codex は移動のコミット `05f5998`、Grok Build は `82a0743` を読んだ。手順番号は指摘時のもの。

| 担当 | 重大度 | 指摘 | 対応 |
| --- | --- | --- | --- |
| Codex | 中 | 取り戻せない削除（AlmaLinux 10 の手順 11、Windows 11 の手順 5・14）の `[!CAUTION]` が、旧 extra 2 冊に残り、新しい extra に無かった | `27e2d20` で、extra/ai-agents.md の[ロールバック](../extra/ai-agents.md#ロールバック)と[Windows 11 のロールバック](../extra/ai-agents.md#windows-11-のロールバック)のリードへ移した |
| Codex | 中 | ai-agents.md の「使う OS の初期設定の「Claude Code」」が、移動済みの項を旧文書の項として案内していた | `f20385f` で、現在の手順を指すよう直した |
| Codex | 低 | ai-agents.md の表示名 18 か所に、旧文書名が残っていた | `f20385f` で直した |
| Codex | 低 | AGENTS.md と windows-setup.md の「同書の」が、分かれた別の本を指していた | `b8d3bc9`・`a21d707` で、指す本の名前に直した |
| Grok Build | 高 | Windows 11 のサーバーの項の手順 10 で、`token.txt` を開く箇条書きと「開かない」が並んでいた | `0592e5a` で、共通パスワードのときとトークンのままのときに分けた |
| Grok Build | 高 | 新規構築では HTTPS がまだ無いのに、共通パスワードの項の手順 2 の次が HTTPS のログインだった | `0592e5a` で、サーバーの項の手順 10 へ戻ると書いた |
| Grok Build | 中 | HTTPS の手順 7 を飛ばした読者が、手順 8 で貼る 64 文字を持たない | `0592e5a` で、入れる値を 1 つの箇条書きにまとめた |
| Grok Build | 中 | Windows 11 のリードが共通パスワードに触れず、リポジトリの clone が要ることも前提に無かった | `0592e5a` で、道順と clone を足した |
| Grok Build | 中 | AlmaLinux 10 のリードが、Windows 11 の節の Remote Control を任意の構成に挙げていた | `fa228d6` で tmux の節に直した |
| Grok Build | 中 | 共同作業の「後ろの節のコマンド」「実施手順の手順 N」が、両 OS の本では指す先が分からない | `fa228d6` で、項の名前とリンクを付け、Windows 11 の手順番号を併記した。中断のメッセージ 2 行も項の名前に直した |
| Grok Build | 中 | 「両 OS」と書きながら、AlmaLinux 10 の項だけへ張ったリンクが 3 か所あった | `fa228d6` で、OS ごとのリンクに分けた |
| Grok Build | 低 | OS が見出しから分からない項、項の名前の無い「手順 1」、extra の表示名 | `fa228d6` で、「対象:」と項の名前を足し、表示名を直した |
| Grok Build | 低 | GNOME 操作の「仮想モニターの大きさを変える」の中断のメッセージの「手順 1」に、項の名前が無い | 採用しなかった。同じ節の中の参照で、手順の本文にリンクがあり、検証済みのコードブロックを変えないため |

### レビューの指摘と対応（2 回目）

Codex と Grok Build は `0fe813e` を読んだ。

| 担当 | 重大度 | 指摘 | 対応 |
| --- | --- | --- | --- |
| Codex | 低 | HTTPS の手順 7 の飛ばす条件が、1 行の説明に無い | `155cc74` で、説明に書いた |
| Codex | 低 | 「Claude Code と Codex CLI も操作する」の手順 3 の箇条書きが 150 字を超えていた | `155cc74` で、2 つに分けた |
| Grok Build | 中 | Windows 11 のリードの「手順後は端末にルート証明書を入れる」が、どの手順の後か分からない | `e6b95c4` で、HTTPS の手順 6 と書いた |
| Grok Build | 中 | サーバーの項の手順 10 へ戻ると、最初の文がまた共通パスワードの設定を求める | `e6b95c4` で、「まだ設定していなければ」と書いた |
| Grok Build | 中 | Windows 11 の手順が、AlmaLinux 10 のものと断った項へ送っている | `e6b95c4` で、参照先が AlmaLinux 10 の項であることと、Windows 11 での置き場所を書いた |
| Grok Build | 中 | スクリプトが成功時に出す HTTPS の案内に、新規構築では従わないことが書かれていない | `e6b95c4` で書いた |
| Grok Build | 中 | 手順 2 の画像の説明が、成功の位置に `FAIL` を置いている | `e6b95c4` で、押す前の画面と分かる説明にし、押した後に `PASS` になることを足した |
| Grok Build | 中 | 入力欄の下の項目の名前は、画面ではなくソースで確かめたもの | `e6b95c4` で、手順書から参考資料へ移した |
| Grok Build | 中 | 検証記録の状態の段落に「ロールバックは実機で未実施」が残っていた | `e6b95c4` で、今回の結果に合わせた |
| Grok Build | 中 | 付録が、手順 2 の変数を後の手順へ持ち回した方法を書いていない | `e6b95c4` で、各ファイルに変数のブロックを並べたことを書いた |
| Grok Build | 低 | 共通パスワードの項の、実行する場所・入力欄の名前・項の名前の無い「手順 N」 | `e6b95c4` で直した |
| Grok Build | 低 | 既存の受信規則の切り替えが、新規導入でも必須に読める。証明書の手順番号が端末で分かれていない | `e6b95c4` で、条件と端末ごとの番号を書いた |
| Grok Build | 低 | 画面の表示名（`Codex CLI`、「認証方式」）と手順の文言の差、画像が Claude Code の例であることの断り | `e6b95c4` で、表示に合わせ、項のリードに断りを足した |
| Grok Build | 低 | 付録の表の証明書の手順、状態行の未確認、ログインの順の書き方 | `e6b95c4` で、通した番号と未確認を足した |
| Grok Build | 低 | AGENTS.md に 2 冊へ残す例外が無い。参考資料と規則の言い回しの差 | `e6b95c4` で揃えた |
| Grok Build | 中 | HTTPS の手順 8 にも、Windows 11 の確認の見出しの違いを書く | 採用しなかった。手順 8 はスマートフォンのブラウザの操作で、見出しの違いはサーバーの項の手順 10 に書いてあるため |

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
  - モバイルアプリでの表示、Safari で閉じた中身をページ内検索できるかは未確認

### 残る未確認

- AlmaLinux 10 の手順は今回流していない。分離前の実機・VM・コンテナの検証範囲を、今回の静的な確認から広げない
- GitHub のモバイルアプリでの折りたたみの表示、Safari で閉じた中身のページ内検索
- ShellCheck、Codex の側での PowerShell 7 の構文解析
