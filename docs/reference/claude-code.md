# Claude Code 最新版インストール手順（AlmaLinux 10 は公式 dnf リポジトリ / Windows 11 は公式の native installer）の参考資料

[手順書](../claude-code.md)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- `CC_CHANNEL` は `baseurl` の末尾に埋まるだけ。入れた後でチャンネルを変えるときは、[stable チャンネルに切り替える（任意）](../claude-code.md#stable-チャンネルに切り替える任意)の手順で repo ファイルを書き換える（`stable` へ移るときは版が下がるので、`upgrade` ではなく `distro-sync` を使う）
- ネイティブインストーラ版にある `autoUpdatesChannel` / `minimumVersion` の設定は dnf 版では効かない（更新を行うのが dnf のため）

### Windows 11 で使う / 手順 3: 補足: 確かめていることと、Git for Windows の役割

- `[Environment]::Is64BitProcess` は、インストーラが最初に見る値と同じ。スタートメニューの「Windows PowerShell (x86)」は、64 ビットの Windows でも 32 ビットで動く（公式の Troubleshoot installation）
- native installer の置き場所は `%USERPROFILE%\.local\bin\claude.exe` に決まっている（公式の文書）。同じ名前のコマンドがほかにもあると、`PATH` の順で先のものが動き、版が食い違う（公式の Check for conflicting installations）
- Git for Windows は任意（公式の Set up on Windows）。入っていれば、Claude Code は Git Bash を Bash のツールと Monitor のツールに使う。無ければ PowerShell のツールでコマンドを動かす
- Claude Code が Git Bash を探す順は、`C:\Program Files\Git`・`C:\Program Files (x86)\Git` → `PATH` の `git` の `bin\bash.exe`（公式の Troubleshoot installation）。ほかの場所に入れたときは、設定の `env` の `CLAUDE_CODE_GIT_BASH_PATH` に `bash.exe` のパスを書く

### Windows 11 で使う / 手順 5: 補足: PATH の足し方

[この節の検証記録](../verification/claude-code.md#windows-11-で使う--手順-5-補足-path-の足し方)

- native installer は `PATH` を変えない（この節の手順 4 の補足）。公式の文書（Troubleshoot installation の Verify your PATH）は、Windows PowerShell に `[Environment]::SetEnvironmentVariable('PATH', "$currentPath;$env:USERPROFILE\.local\bin", 'User')` を貼る形で足す。この手順も同じ書き方で、あれば足さないようにしただけ
- `SetEnvironmentVariable` の `User` は、レジストリの `HKCU\Environment` の `Path` に書き、開いているウィンドウに環境が変わったことを知らせる。そのため、この後に開いた PowerShell に効く（サインインし直さなくてよい）
- 読むときに `%USERPROFILE%` のような書き方は展開され、書き戻すと展開した形（`C:\Users\<WIN_USER>\...`）で残る（.NET Framework の `Environment` の動き）。自分のユーザーの PATH なので、困ることは無いはず
- 足すのは自分のユーザーの PATH だけで、システムの PATH（管理者の権限が要る）は変えない
- 公式の文書は、画面からでも同じことができるとしている（システムのプロパティ → 環境変数 → ユーザー環境変数の `Path` → 新規）

### Windows 11 で使う / 手順 8: 補足: ログインの流れと、ログインの情報の置き場所

[この節の検証記録](../verification/claude-code.md#windows-11-で使う--手順-8-補足-ログインの流れとログインの情報の置き場所)

- 公式の文書（Authentication）: 最初の起動でブラウザが開く。`ANTHROPIC_API_KEY` を設定していると、ブラウザの代わりにその鍵を使ってよいか 1 度だけ聞かれる。ブラウザが Claude Code の待ち受けに戻れないとき（SSH のセッションなど）は、ブラウザに出たコードを端末に貼る

- 開き直した PowerShell は `C:\Users\<WIN_USER>` で始まる。ホームのフォルダーの信頼は保存されない（[windows-claude-remote-control.md](../windows-claude-remote-control.md)）ので、起動のたびに聞かれる。作業したいディレクトリに `cd` してから起動してもよい
- ログインの情報は `%USERPROFILE%\.claude\.credentials.json` に置かれ、ユーザーのプロファイルのアクセス権を引き継ぐ（公式の文書）
- Remote Control（[windows-claude-remote-control.md](../windows-claude-remote-control.md)）は claude.ai のアカウントでのログインが要る（API キーでは使えない）

### Windows 11 のロールバック / 手順 2: 補足: 消すもの

[この節の検証記録](../verification/claude-code.md#windows-11-のロールバック--手順-2-補足-消すもの)

- 公式の文書の Windows PowerShell の手順が消すのは、`%USERPROFILE%\.local\bin\claude.exe` と `%USERPROFILE%\.local\share\claude`（版のファイル）の 2 つ
- 本書は、更新の名残の `claude.exe.old.*`（[Windows 11 の更新](../claude-code.md#windows-11-の更新)の補足）と、`%USERPROFILE%\.local\state\claude`（ロック）・`%USERPROFILE%\.cache\claude`（更新の途中のファイル）も消す。消去対象の根拠と検証範囲は検証記録に置く
- 空になった `%USERPROFILE%\.local\share` などは残る

### 選択した方針

[この節の検証記録](../verification/claude-code.md#選択した方針)

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **公式 dnf リポジトリ** | `downloads.claude.ai/claude-code/rpm/{stable,latest}`。aarch64 の RPM があり、署名鍵で検証される。更新は `dnf upgrade`（**自動更新はしない**） | **採用**（他のツールと同じ dnf 管理に揃う） |
| ネイティブインストーラ（`curl -fsSL https://claude.ai/install.sh \| bash`） | `~/.local/bin/claude` に入り、**バックグラウンドで自動更新する**。root 不要。ただし更新経路が dnf の外になり、`~/.local/share/claude/versions/` に版が積まれる | 不採用（自動更新が要るなら有力） |
| npm（`npm install -g @anthropic-ai/claude-code`） | Node.js 22 以上が要る。中身は同じネイティブバイナリ | 不採用 |

- どれを選んでも入るのは同じネイティブバイナリで、Node.js は実行時に使わない
- `ripgrep` は同梱されている（Alpine など musl 系以外では別途入れなくてよい）

**`stable` と `latest` の違い**:

- `stable` は 1 週間ほど遅れて、大きな不具合のある版を飛ばす
- `latest` は出た版をすぐ配る
- リポジトリが別 URL になっているだけで、切り替えは `baseurl` の書き換え（[stable チャンネルに切り替える（任意）](../claude-code.md#stable-チャンネルに切り替える任意)）

**既定を `latest` にした理由**:

- 本書の目的が最新版を入れることだから。`stable` のままだと 1 週間ほど遅れる
- ネイティブインストーラ（`install.sh` が取ってくる `bootstrap.sh`）も、まず `claude-code-releases/latest` が指す版を取ってくる
- 不具合に当たったときの逃げ道として、`stable` へ下げる節を用意した

- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた
- **インストーラは `& ([scriptblock]::Create(...)) <チャンネル>` の形で動かす**: 公式の文書がチャンネルを選ぶときに使う形。既定の `irm … | iex` は、インストーラの設定（`Set-StrictMode` など）を、入れた後の PowerShell に残す（[Windows 11 で使う](../claude-code.md#windows-11-で使う)の手順 4 の補足）
- **`PATH` は本書で足す**: インストーラも `claude install` も足さず、足し方を出すだけなので、公式の文書の Verify your PATH と同じ書き方で、自分のユーザーの PATH に足す（同じ節の手順 5）
- **署名は入れた後に確かめる**: インストーラは sha256 しか照らさないので、公式の文書の `Get-AuthenticodeSignature` で `claude.exe` の署名を見る（同じ節の手順 7）。インストーラの中で動く前の確かめにはならない
- **Git for Windows を前提にした**: 公式の文書では任意だが、Claude Code の Bash のツール（と Monitor のツール）が Git Bash を使う。[Windows 11 の初期設定](../windows-setup.md)のリードの順で、先に入れる

### 参照

- [Advanced setup — Claude Code Docs](https://code.claude.com/docs/en/setup) — dnf / apt / apk リポジトリの設定、チャンネル、アンインストール、署名の検証。Windows 11 の節は、Set up on Windows・Install a specific version（チャンネルを選ぶ形）・Update manually・Binary integrity and code signing・Uninstall の Windows PowerShell
- [Troubleshoot installation and login — Claude Code Docs](https://code.claude.com/docs/en/troubleshoot-install) — インストールが失敗したときの切り分け。Windows 11 の節は、Verify your PATH・Check for conflicting installations・`claude.exe` missing after an update on Windows・Claude Code does not support 32-bit Windows・Git Bash を探す順
- [CLI reference — Claude Code Docs](https://code.claude.com/docs/en/cli-reference) — `claude` のオプションとサブコマンド（[使い方の基本](../claude-code.md#使い方の基本)）
- [Interactive mode](https://code.claude.com/docs/en/interactive-mode) / [Commands](https://code.claude.com/docs/en/commands) — セッションの中のキーとスラッシュコマンド
- [Run Claude Code programmatically](https://code.claude.com/docs/en/headless) — `-p` と `--output-format`
- [Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp) — `claude mcp` とスコープ
- [Continue local sessions from any device with Remote Control](https://code.claude.com/docs/en/remote-control) — `claude remote-control`
- `man dnf.conf`（`gpgcheck`、`baseurl`）
- [Authentication — Claude Code Docs](https://code.claude.com/docs/en/authentication) — 最初の起動のログインの流れと、Windows のログインの情報の置き場所（`.credentials.json`）
- [winget-pkgs の Anthropic.ClaudeCode](https://github.com/microsoft/winget-pkgs/tree/master/manifests/a/Anthropic/ClaudeCode) / [scoop の main/claude-code](https://github.com/ScoopInstaller/Main/blob/master/bucket/claude-code.json) — Windows 11 で採らなかった経路の定義
- [about_Preference_Variables（`$OutputEncoding`）— Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-5.1) — Windows PowerShell 5.1 が native のコマンドへパイプで渡す文字コード
- [Windows 11 の初期設定](../windows-setup.md) — 同じ PC で先に行う設定（貼り付けの設定と、この文書を通す順）
- [windows-claude-remote-control.md](../windows-claude-remote-control.md) — Windows 11 の節で入れた Claude Code を、SSH の切断後も Remote Control で使う

---
