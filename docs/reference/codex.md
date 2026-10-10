# Codex CLI を AlmaLinux 10・Windows 11 に入れるの参考資料

[手順書](../codex.md)・[ロールバック](../extra/codex.md)

## 補足

### 実施手順 / 手順 3: 補足: インストーラーが置くもの

- Node.js・npm・Homebrew は不要。CPU に合う公式の配布物を取り、SHA-256 と導入後の版を確認する
- `~/.local/bin/codex` と `~/.local/bin/codex-code-mode-host` にリンクを置き、配布物は `~/.codex/packages/standalone/` に保存する
- `~/.local/bin` が PATH に無い場合、bash では `~/.bashrc` に `# >>> Codex installer >>>` から `# <<< Codex installer <<<` までのブロックを足す
- 自分用の [bash の設定](https://github.com/ryo-aoki-pc/bash)を入れたホストでも、追加の設定を手書きする必要は無い

### 実施手順 / 手順 3: 補足: パッケージマネージャーで入れない理由

- 配布はある: Homebrew の cask `codex`（Linux でも入る）、scoop の main の `codex`、WinGet の `OpenAI.Codex`
- どれも、そのパッケージマネージャーのコマンド（`brew upgrade --cask codex`・`scoop update codex`・`winget upgrade`）を打たないと上がらない
- Homebrew の cask で入れた Codex（AlmaLinux 10）では、`codex update` が `Could not detect the Codex installation method.` で止まった（[検証記録](../verification/codex.md#付録-起動したときの更新とパッケージマネージャー2026-10-09)）
- standalone のインストーラーで入れたものは、起動したときの知らせから Enter 1 回で上がる（[更新: 補足](#更新-補足-起動したときの知らせ)）。利用者の希望（自動で最新になるなら公式の方法でよい）に近いので、こちらを採る

### 更新: 補足: 起動したときの知らせ

- 端末の Codex は、起動したときに、最新の版を GitHub（`api.github.com/repos/openai/codex/releases/latest`）に問い合わせ、`~/.codex/version.json` に控える。控えが無いか古いときだけ問い合わせる
- 控えた版が今の版より新しいと、起動の画面に `Update available!` を出す。`1. Update now` は、入れ方に合う更新のコマンドを動かす
- standalone のインストーラーで入れたものでは、`sh -c 'curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh'` を動かす
- Windows 用の `install.ps1` を使う同じ形のコマンドも、配布物の中にある
- `codex update` も、同じインストーラーを動かす

### Windows 11 で使う / 手順 2: 補足: 置き場所と PowerShell の設定

- 実行ファイルの入口は `%LOCALAPPDATA%\Programs\OpenAI\Codex\bin\codex.exe`。`bin` は `%USERPROFILE%\.codex\packages\standalone\` 内の配布物を指すジャンクションになる
- インストーラーがユーザー用 PATH と、今の PowerShell の PATH の両方を設定する
- `&` でスクリプトブロックとして呼び、インストーラーの StrictMode・エラー処理の設定を呼び出し元に残さない
- PowerShell 全体の ExecutionPolicy を変更する手順は不要

### 参照

- [OpenAI: Codex CLI](https://learn.chatgpt.com/docs/codex/cli) — 導入・起動・更新
- [公式 Linux/macOS インストーラー](https://chatgpt.com/codex/install.sh)
- [公式 Windows インストーラー](https://chatgpt.com/codex/install.ps1)
- [OpenAI: Authentication](https://learn.chatgpt.com/docs/auth) — ChatGPT・API キー・デバイスコード・資格情報の保存
- [OpenAI: Windows sandbox](https://learn.chatgpt.com/docs/windows/windows-sandbox) — Windows 11、初回の管理者承認
- [OpenAI: Config basics](https://developers.openai.com/codex/config-basic) — ユーザー設定
- [Homebrew: codex](https://formulae.brew.sh/cask/codex) — Homebrew の cask（使わなかった経路）
