# Windows 11 で Claude Code の Remote Control を SSH の切断後も動かす手順（タスク スケジューラ + WezTerm）のロールバックと注意点

[手順書](../windows-claude-remote-control.md)・[検証記録](../verification/windows-claude-remote-control.md)・[参考資料](../reference/windows-claude-remote-control.md)

- 「手順 N」は[手順書](../windows-claude-remote-control.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- この節は、SSH でログインした PowerShell に貼る（変数は要らない）
- タスクを消しても、`~/.claude.json` のディレクトリの信頼と Remote Control の確認、claude.ai のセッションの一覧は残る（ほかの用途でも使うので消さない）。WezTerm と Claude Code 自体も消さない

1. セッションを止めてタスクを消す。

   ```powershell
   Stop-ScheduledTask -TaskName 'claude-remote-control'
   Start-Sleep -Seconds 2
   Unregister-ScheduledTask -TaskName 'claude-remote-control' -Confirm:$false
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ScheduledTask -TaskName 'claude-remote-control' -ErrorAction SilentlyContinue
   ```

   - 最後の `Get-ScheduledTask` が何も出さなければよい

---

## 注意点

- **Remote Control の性質**
  - この PC からは外向きの HTTPS だけで、受信のポートは開けない（公式ドキュメント）
  - つないでいる間、会話の転写（メッセージ・応答・ツールの動き）は Anthropic のサーバーに保存される
  - この claude.ai のアカウントで入れる人は、スマートフォンやブラウザから `<PROJECT_DIR>` でこのユーザーとして Claude Code を動かせる。アカウントのパスワードと端末の扱いは、この PC の管理者のパスワードと同じにする。Trusted Devices（claude.ai の設定）を使うと、登録した端末からしか操作できなくなる
- **デスクトップにログオンしている必要がある**: タスクは `Interactive` で、ログオン中のデスクトップのセッションに WezTerm を開く。ログオフすると動かない
- **WezTerm の窓が見える**: タスクはデスクトップに WezTerm の窓を開く。窓を閉じると Claude Code が止まる。最小化してよい
- **Claude Code のサーバーが止まるとき**
  - ネットワークが約 10 分切れると、`claude remote-control` は自分で終わる（公式ドキュメント）。[止める・もう一度始める](../windows-claude-remote-control.md#止めるもう一度始める)の手順 2 で始め直す
  - PC がスリープすると、その間は使えない。公式ドキュメントは、復帰すれば自動でつなぎ直すと書いている（Windows の電源の設定は本書の対象外）
- **一度きりの確認**: ディレクトリの信頼（`~/.claude.json`）と Remote Control の確認（`remoteDialogSeen`）を手順 4 で受ける。別の `PROJECT_DIR` にするときは信頼を受け直す
- **`--spawn same-dir` を外さない**: 外すと `Choose [1/2]` の確認でタスクが止まる
- **Remote Control を使えない設定**: `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`・`DISABLE_GROWTHBOOK`・`ANTHROPIC_BASE_URL` が環境変数か settings.json の `env` にあると使えない（公式ドキュメント）
- **Claude Code の自動更新**: native installer は背景で更新する。動いているサーバーは古い版のままで、次に始め直したときから新しい版になる
- **起動時の自動起動**: タスクにログオンのトリガー（`New-ScheduledTaskTrigger -AtLogOn`）を足せば、ログオンで自動で始められる
