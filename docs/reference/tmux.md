# tmux インストール手順（AlmaLinux 10 / Homebrew）の参考資料

[手順書](../tmux.md)

[検証記録](../verification/tmux.md#参考資料から分離した記録)

## 補足

### 設定ファイル（任意） / 手順 1: 補足: 読み込む場所と、足さなかった行

- Homebrew の tmux のシステムの設定ファイルは `/home/linuxbrew/.linuxbrew/etc/tmux.conf`（`man tmux`）。`/etc/tmux.conf` は読まない
- `escape-time`（Esc の後に待つ時間）は、3.7c の既定ですでに 10 ミリ秒なので足さない。Neovim などのために 0〜10 にする例は、古い版の既定の 500 ミリ秒を縮めるためのもの
- Claude Code の公式ドキュメントには、tmux の設定の推奨は無かった（Shift+Enter のための `extended-keys` なども）。本書では足していない

### Claude Code を tmux の中で動かす（任意） / 手順 1: 補足: claude auth status を最後に置く理由

- ブラケットペースト無しで貼ると、`claude auth status --text` は、端末に残っていた後ろの行を読んで捨てた（後ろの `tmux -V` や `echo` が実行されなかった）
### 参照

- [tmux — Getting Started](https://github.com/tmux/tmux/wiki/Getting-Started) — セッション・ウィンドウ・ペインとキーの説明
- `man tmux`（`new-session` の `-A` と `-d`、`attach-session` の `-d`、`history-limit`、`mouse`、設定ファイルを読む場所）
- [Homebrew の tmux の formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/t/tmux.rb)
- [Continue local sessions from any device with Remote Control](https://code.claude.com/docs/en/remote-control) — `claude remote-control`、`--spawn`、Limitations（SSH の切断後も残すには tmux か screen、10 分の終了）、4 時間以内の再開
- [Interactive mode](https://code.claude.com/docs/en/interactive-mode) — `Ctrl+B`（tmux では 2 回）
- [Claude Code](../claude-code.md) — 導入とログイン、`claude` のコマンドラインの使い方
- [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md) — 同じことを Windows で行う手順書
- [Homebrew](../homebrew.md) — Homebrew 本体の導入と、Homebrew 系に共通の注意

---
