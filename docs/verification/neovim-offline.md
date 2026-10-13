# Neovim・LazyVim の初回オフライン取得の検証記録

[Neovim の実施手順](../almalinux-setup.md#neovim)・[LazyVim の設定を導入する](../almalinux-setup.md#lazyvim-の設定を導入する)・[npm のオフライン導入](../almalinux-setup.md#npm-のオフライン導入-実施手順)

## 対象と判定

- **状態**: OFFLINE-FIRSTINSTALL の初回不在から Neovim・LazyVim・Mason の取得を確認したが、原文全条件の通しは partial
  - Neovim 0.12.6、初回 LazyVimStarter clone・plugin取得、Masonの実 Installed 11件・現在の通知・実コマンド・checkhealthを確認
  - Installing中のnpm実コマンド、切断後対照・再起動後の実Anthy変換は未確認。原文「Neovim」の手順3と「npm のオフライン導入: 実施手順」の手順3は部分確認
  - 共通台帳61件は42通過・4条件外・3部分確認・1失敗・11未実施。旧5通過を含み、[Homebrew](homebrew-offline.md)・[npm](npm-offline.md)・本書で同じ取得を再加算しない

公開 `ssh-approved-20261013T0325Z` の result・completion に基づく記録。原文は凍結 `27857989d9f0b492b6bd6396fed3a8c2155ea7cf`、設定の実 HEAD は `f1d5363c624280bf863893324a1b7954f8a884de`。前日の中断と同じ専用 online／offline 2VMを、通常sudo対話認証と利用者承認後のSSH認証で続行した。CLI／TUIはSSH TTY搬送で、GNOME端末での原文貼付成功とは区別する。

## 判定表と残件

| 範囲 | 実確認／未達 |
|---|---|
| 初回取得の前提 | 初期不在10項目、SOCKS listener・同じシェルの経路、Homebrew初回導入とNeovim 0.12.6を確認。npm実施1・2の取得・PONGを初回LazyVim手順10より先に実施 |
| LazyVim | 自分用設定の初回clone、38 plugin directory、原文lock復元後のtracked dirty0を確認。cacheを消して初回状態を捏造していない |
| Mason | 実TUIのInstalled11件の実名、現在のUI通知でLSP開始・成功、11実コマンドを確認。registry更新はpackage導入とは別判定 |
| checkhealth | ERRORなし。原文で許容するfzf未導入WARNINGのみ |
| Neovim手順3（nvim3） | RPM Fusion前提と後続の全条件が揃わずpartial。参照先の取得成立だけで手順全体を成功へ更新しない |
| npm手順3（npm3） | 初回Installing中のnpm実コマンド未観測でpartial。Installed11件や通知から遡って証明しない |
| 日本語・GUI | Anthy設定の読戻しは成立。再boot後の実変換、原文手順8の全検索・整形・IME条件、GNOME原文Unicode条件は未確認 |

- **失敗と条件差**: 「EPEL と RPM Fusion」手順3（epel3）の `sudo rpm --import URL` が curl(6) DNS失敗。公開指紋一致とrpm登録成功は別で、同じ項の手順4・5は未実施
  - 原文「ログインと sudo」手順3の永続 NOPASSWD ALL は未承認・未実施。通常sudo認証による条件差を保持し、今回の取得成功で拒否履歴を上書きしない
  - 「SSH の SOCKS トンネル: トンネルを閉じる」手順1（close1）は `exit` 後も転送が残りpartial。通常切断後はlistener0・自己PID不存在を確認したが、外側driverも切れたためオンラインprompt復帰の成功には数えない
- **停止と残件**: 2026-10-13 04:53:29 UTC の公開process metadata取得例外で自己2VMを通常Off。失敗snapshotが欠け、特定peerの状態を原因と断定しない
  - 04:58:44までに凍結132MD・工具20件・停止親5件のwhole SHA／ID／親鎖一致を確認し、expected不変更。05:14:21にOff・割当0・自己lock不存在を再確認、6144 MiB返却・runtime0
  - 監視の限定修正と新runtime枠、切断後対照・再起動・実Anthy、epel3前提の修正・再検証が残る。Installing中の実コマンドは別の真正な初回機会が必要

## 以前の結果との対応

前日の2/61・5/61と承認拒否は [Homebrew の旧付録](homebrew-offline.md)・[npm の旧付録](npm-offline.md)に保持する。今回42通過は旧5件と新規37件で、2＋5＋42とは合算しない。[横断報告の時点別集計](../hypervisor-verification.md#付録-公開結果の追加確認2026-10-13-utc)と同じ台帳である。

既存 OFFLINE-FULL の Installed11件・registry更新・再起動後GUI日本語変換、旧 AS／N1／V2／Windows の成功範囲は別履歴。今回の初回取得を、そのGUI成功や原文全通しの代替にはしない。今回の文書編集でVM・ディスク・秘密・raw／認証記録を読取・操作していない。
