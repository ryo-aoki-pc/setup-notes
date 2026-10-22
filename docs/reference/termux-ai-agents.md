# Termux の AI エージェントの参考資料

[手順書](../android.md#termux-の-ai-エージェント)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux-ai-agents.md)・[注意点](../extra/termux-ai-agents.md)

## 選択した方針

- Codex CLI は Termux の `pkg` で入れ、Claude Code は proot-distro の Ubuntu に公式のインストーラーで入れる（利用者の決定）
- Claude Code は v2.1.113 からネイティブのバイナリになり、glibc が要る。Termux のネイティブの環境では動かないので Ubuntu を使う（[anthropics/claude-code#50270](https://github.com/anthropics/claude-code/issues/50270)）
- Claude Code のために Termux 全体を proot へ入れず、glibc が要るものだけを分ける（[Termux の方針](termux.md#選択した方針)）

## 補足

### Termux の AI エージェント / 手順 1: 補足: Codex CLI の導入とサンドボックス

- `pkg install codex` で Termux の Codex CLI が入った（取得 88.3 MB、展開後 355 MB）。`codex --version` と `codex doctor` は未ログインでも起動した
- Android で `codex sandbox` を実行すると、`not supported on this operating system` になる。`codex doctor` の `linux helper` は `none` だった
- Codex が動かすコマンドは OS のサンドボックスで囲まれない。`doctor` の `sandbox` の行（`restricted fs + restricted network`）は設定の表示で、OS の制限が働くとは判断しない
- ログインの前の `codex doctor` は、`✗ auth`（資格情報が無い）と、`⚠ websocket`（`401 Unauthorized`）を出した

### Termux の AI エージェント / 手順 2〜4: 補足: デバイス認証

- `codex login --device-auth` は、`https://auth.openai.com/codex/device` と 15 分で切れるワンタイムコードを出して待った。`Ctrl+C` で止まり、`codex login status` は `Not logged in` を出した（終了コード 1）
- ログインと、ログインの後の操作（`codex exec` など）は確かめていない

### Termux の AI エージェント / Termux の AI エージェント: proot の Ubuntu で Claude Code を使う / 手順 3〜5: 補足: インストール先・PATH・初めての起動

- 公式のインストーラーは `~/.local/bin/claude` にリンクを置く。Ubuntu の中で Claude Code の `--version` が動いた
- Ubuntu の root のログインシェルでは `~/.local/bin` が PATH に無かった。`~/.bashrc` に PATH の行を置いて、新しいシェルでも見つかるようにする
- `--isolated` で Termux のホームが見えない Ubuntu でも、Claude Code の `--version` が動いた
- インストーラーの取得が `502` で失敗したことが 1 回あり、少し置いて貼り直すと入った
- 初めての起動では、文字の色の選択の後に、ログインの方法の選択が出た。ログインと、ログインの後の操作は確かめていない

### Termux の AI エージェント / Termux の AI エージェント: 更新 / 手順 3: 補足: Claude Code の更新

- proot の Ubuntu の中の `claude update` は、`Current version: 2.1.308` の後に `Claude Code is up to date (2.1.308)` を出した。新しい版へ上げる動きは確かめていない

## 参照

- [Termux の Codex パッケージ](https://github.com/termux/termux-packages/tree/master/packages/codex)
- [Codex](https://github.com/openai/codex)
- [Claude Code のセットアップ](https://code.claude.com/docs/en/setup)
- [anthropics/claude-code#50270](https://github.com/anthropics/claude-code/issues/50270)
- [proot-distro](https://github.com/termux/proot-distro)
