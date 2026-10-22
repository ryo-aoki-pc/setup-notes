# Termux の AI エージェントの注意点

[手順書の「Termux の AI エージェント」](../android.md#termux-の-ai-エージェント)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux-ai-agents.md)・[参考資料](../reference/termux-ai-agents.md)

- 手順番号は、名前を付けた手順書の項の番号を指す

## 注意点

- Android の Codex CLI は、動かすコマンドを OS のサンドボックスで囲まない。`codex sandbox` は `not supported on this operating system` になり、`codex doctor` の `linux helper` は `none`
- Codex CLI が操作する Termux のファイルと、実行を許可するコマンドを確かめる。ログイン後の操作は確かめていない
- Claude Code は proot の Ubuntu の中で root として動く。Ubuntu のファイルを変えられるので、実行を許可するコマンドを確かめる
- Ubuntu には `--isolated` を付けて入り、Termux のホームと共有のストレージをつながない（[proot-distro の注意点](termux-proot.md#注意点)）
- ワンタイムコード・認証の URL・トークンを文書や画面の画像に載せない
