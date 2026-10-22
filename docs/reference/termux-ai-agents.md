# Termux の AI エージェントの参考資料

[手順書](../android.md#termux-の-ai-エージェント)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux-ai-agents.md)・[注意点](../extra/termux-ai-agents.md)

## 選択した方針

- Codex CLI は Termux の `pkg` で入れ、Claude Code は proot-distro の Ubuntu に公式のインストーラーで入れる（利用者の決定）
- Claude Code は v2.1.113 からネイティブのバイナリになり、glibc が要る。Termux のネイティブの環境では動かないので Ubuntu を使う（[anthropics/claude-code#50270](https://github.com/anthropics/claude-code/issues/50270)）
- Claude Code のために Termux 全体を proot へ入れず、glibc が要るものだけを分ける（[Termux の方針](termux.md#選択した方針)）

## 補足

### Termux の AI エージェント / 手順 1: 補足: Codex CLI の導入とサンドボックス

- `pkg install codex` で Termux の Codex CLI が入った。`codex --version` と `codex doctor` は未ログインでも起動した
- Android で `codex sandbox` を実行すると、`not supported on this operating system` になる。`codex doctor` の `linux helper` は `none` だった
- Codex が動かすコマンドは OS のサンドボックスで囲まれない。`doctor` の設定の表示だけで、OS の制限が働くと判断しない
- ログイン後の操作は確かめていない
<!-- Claude Code が確かめる: Codex CLI のログインと、使い捨てのリポジトリでの codex exec。確かめてから実行手順と成功条件を書く。 -->

### Termux の AI エージェント / Termux の AI エージェント: proot の Ubuntu で Claude Code を使う / 手順 3・4: 補足: インストール先と PATH

- 公式のインストーラーは `~/.local/bin/claude` にリンクを置く。Ubuntu の中で Claude Code の `--version` が動いた
- Ubuntu の root のログインシェルでは `~/.local/bin` が PATH に無かった。`~/.bashrc` に PATH の行を置いて、新しいシェルでも見つかるようにする
- `--isolated` で Termux のホームが見えない Ubuntu でも、Claude Code の `--version` が動いた。ログイン後の操作は確かめていない
<!-- Claude Code が確かめる: proot の Ubuntu での Claude Code のログインと、その後の操作。 -->

### Termux の AI エージェント / Termux の AI エージェント: 更新 / 手順 3: 補足: Claude Code の更新

- proot の Ubuntu の中の `claude update` は確かめていない
<!-- Claude Code が確かめる: proot の Ubuntu で claude update を実行し、成功条件を確定する。 -->

## 参照

- [Termux の Codex パッケージ](https://github.com/termux/termux-packages/tree/master/packages/codex)
- [Codex](https://github.com/openai/codex)
- [Claude Code のセットアップ](https://code.claude.com/docs/en/setup)
- [anthropics/claude-code#50270](https://github.com/anthropics/claude-code/issues/50270)
- [proot-distro](https://github.com/termux/proot-distro)
