# Codex CLI を AlmaLinux 10・Windows 11 に入れるの参考資料

[手順書](../codex.md)

## 補足

### 実施手順 / 手順 3: 補足: インストーラーが置くもの

- Node.js・npm・Homebrew は不要。CPU に合う公式の配布物を取り、SHA-256 と導入後の版を確認する
- `~/.local/bin/codex` と `~/.local/bin/codex-code-mode-host` にリンクを置き、配布物は `~/.codex/packages/standalone/` に保存する
- `~/.local/bin` が PATH に無い場合、bash では `~/.bashrc` に `# >>> Codex installer >>>` から `# <<< Codex installer <<<` までのブロックを足す
- 自分用の [bash の設定](https://github.com/ryo-aoki-pc/bash)を入れたホストでも、追加の設定を手書きする必要は無い

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
