# Windows 11 の初期設定の手順（インストール直後の更新・貼り付けの設定・scoop・UniGet UI・表示・電源・リモート・WSL・OpenSSH・Git・Firefox・WezTerm・Neovim）のロールバックと注意点

[手順書](../windows-setup.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-setup.md)・[参考資料](../reference/windows-setup.md)

- 手順書の手順は、番号付きリストを持つ見出し（項）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- 貼る窓
  - [Git の道具を消す](#git-の道具を消す)・[エディタとシェルのツールを消す](#エディタとシェルのツールを消す)・[HackGen Console NF を消す](#hackgen-console-nf-を消す)・[表示と入力を戻す](#表示と入力を戻す)・[アプリと貼り付けの設定を外す](#アプリと貼り付けの設定を外す)のすべての手順と、[サインイン・検索・キーボードを戻す](#サインイン検索キーボードを戻す)の手順 4 は、[Microsoft Store の更新](../windows-setup.md#microsoft-store-の更新)の手順 1 と同じ管理者ではない Windows PowerShell（5.1）に貼る
  - [Git Bash の設定を戻す](#git-bash-の設定を戻す)の手順 2〜8 は、同じ項の手順 1 で開く Git Bash に貼る
  - [OpenSSH・Git for Windows・Firefox・WezTerm を外す](#opensshgit-for-windowsfirefoxwezterm-を外す)の手順 2〜8 は、同じ項の手順 1 で開く管理者の Windows PowerShell に、同じ項の手順 9 はクライアントのシェルに貼る
  - [サインイン・検索・キーボードを戻す](#サインイン検索キーボードを戻す)の手順 2・3・5〜11、[ネットワークと PC 全体の設定を戻す](#ネットワークと-pc-全体の設定を戻す)のすべての手順、[再起動と PSWindowsUpdate](#再起動と-pswindowsupdate)の手順 1 は、[サインイン・検索・キーボードを戻す](#サインイン検索キーボードを戻す)の手順 1 で開く管理者の Windows PowerShell に貼る（同じ項の手順 4 の分だけ、管理者ではない窓も開いたままにしておく）
- PSWindowsUpdate だけを外すなら、[再起動と PSWindowsUpdate](#再起動と-pswindowsupdate)の手順 3・4 を行う（管理者ではない窓）。この文書で初めて入れた場合だけが対象
- Windows Update や Store の更新を一括で取り消す手順ではない。Store 本体と、ほかのモジュールも使う NuGet のプロバイダーは外さない
- 残す項目の手順は飛ばす。項目ごとのこの節の手順
  - Git: [Git の道具を消す](#git-の道具を消す)の手順で、lazygit は 1・2（自分用の設定は 1）、git-delta は 3・4、GitHub CLI は 5〜10。`~/.gitconfig` は[Git Bash の設定を戻す](#git-bash-の設定を戻す)の手順 2〜6、Git for Windows は[OpenSSH・Git for Windows・Firefox・WezTerm を外す](#opensshgit-for-windowsfirefoxwezterm-を外す)の手順 4
  - エディタとシェルのツール: [エディタとシェルのツールを消す](#エディタとシェルのツールを消す)の手順で、yazi は 1〜3（自分用の設定は 1）、自分用の Neovim の設定は 4、Neovim は 5、Node.js は 6、starship・zoxide・fzf・eza・bat は 7〜9
  - 端末とブラウザ: 自分用の WezTerm の設定は[Git Bash の設定を戻す](#git-bash-の設定を戻す)の手順 7、共通の bash 設定は同じ項の手順 8。OpenSSH サーバーは[OpenSSH・Git for Windows・Firefox・WezTerm を外す](#opensshgit-for-windowsfirefoxwezterm-を外す)の手順 2・3・9、Firefox は同じ項の手順 5〜7、WezTerm は同じ項の手順 8。HackGen Console NF は[HackGen Console NF を消す](#hackgen-console-nf-を消す)の手順 1〜3
  - 表示と入力: エクスプローラーは[表示と入力を戻す](#表示と入力を戻す)の手順 1、コンテキストメニューは同じ項の手順 2、スタートは同じ項の手順 3 と[サインイン・検索・キーボードを戻す](#サインイン検索キーボードを戻す)の手順 6、タスクバーは[表示と入力を戻す](#表示と入力を戻す)の手順 4、ダークモードは同じ項の手順 5、既定の端末は同じ項の手順 6、IME は同じ項の手順 7、キーボードは[サインイン・検索・キーボードを戻す](#サインイン検索キーボードを戻す)の手順 9・11
  - 整理: 自動で起動するアプリは[表示と入力を戻す](#表示と入力を戻す)の手順 8、標準アプリとウィジェットは同じ項の手順 9、ショートカットのポリシーは[サインイン・検索・キーボードを戻す](#サインイン検索キーボードを戻す)の手順 7
  - 入れたもの: PowerShell 7 は[アプリと貼り付けの設定を外す](#アプリと貼り付けの設定を外す)の手順 1、PowerToys は同じ項の手順 2、UniGet UI は同じ項の手順 3、scoop は同じ項の手順 4・5、WSL は同じ項の手順 8 と[サインイン・検索・キーボードを戻す](#サインイン検索キーボードを戻す)の手順 8、Autologon は同じ項の手順 3・4
  - 貼り付けの設定: [アプリと貼り付けの設定を外す](#アプリと貼り付けの設定を外す)の手順 6・7
  - PC 全体: PC の名前は[ネットワークと PC 全体の設定を戻す](#ネットワークと-pc-全体の設定を戻す)の手順 9、長いパス・開発者モード・sudo は同じ項の手順 8、電源とロックは同じ項の手順 7、アダプターは同じ項の手順 6、時計は[サインイン・検索・キーボードを戻す](#サインイン検索キーボードを戻す)の手順 10
  - ネットワークとサインイン: 配信の最適化は[ネットワークと PC 全体の設定を戻す](#ネットワークと-pc-全体の設定を戻す)の手順 1、ping は同じ項の手順 2、リモート アシスタンスは同じ項の手順 3、リモート デスクトップは同じ項の手順 4、LAN の種類は同じ項の手順 5、Windows Hello は[サインイン・検索・キーボードを戻す](#サインイン検索キーボードを戻す)の手順 5

> [!WARNING]
> [Git の道具を消す](#git-の道具を消す)の手順 6 は、**AlmaLinux 10 のホストを含め、ほかの端末の GitHub CLI のトークンもすべて失効させる。** この PC からログインの情報を消すだけなら、同じ項の手順 5 だけでよい。

- 多くは、元に戻すかを[PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 3 で控えた値で決める
- ほかの手順書で入れたもの（VirtualBox・WireGuard・Syncthing など）は、それぞれの手順書の「Windows 11 のロールバック」で先に戻す
  - [SSH クライアント（Windows）](windows-ssh-client.md#ロールバック)は「ロールバック」、[Samba の共有のネットワーク ドライブ](samba-client.md#windows-11-のロールバック)は「Windows 11 のロールバック」
  - [AI コーディングエージェントのセットアップ](ai-agents.md#windows-11-のロールバック)で入れたものは、この節の項より前に戻す
- この文書で入れたものは、この節の項を上から順に戻す。自分用の設定（Neovim・WezTerm・lazygit・yazi）は、その項の中で、それぞれのリポジトリのロールバックへ案内する
- [アプリと貼り付けの設定を外す](#アプリと貼り付けの設定を外す)の手順 4 で scoop ごと消すときも、scoop の外に残るものは、先に次の手順で外す
  - `~/.gitconfig` の `core.pager` は[Git の道具を消す](#git-の道具を消す)の手順 3、資格情報マネージャーの gh のトークンは同じ項の手順 5〜8
  - ユーザーの環境変数 `YAZI_FILE_ONE` は[エディタとシェルのツールを消す](#エディタとシェルのツールを消す)の手順 3、`EDITOR`・`VISUAL` は[Neovim を既定のエディタにする](../neovim.md#neovim-を既定のエディタにする)の手順 3
  - Claude Code のプラグインは[AI エージェントのロールバックの「Windows 11 で AI エージェントとプラグインを消す」](ai-agents.md#windows-11-で-ai-エージェントとプラグインを消す)の手順 1（プラグインは、Claude Code の起動と終了のたびに、scoop の `node` を動かす）
  - そのときは、scoop で消す手順（[Git の道具を消す](#git-の道具を消す)の手順 2・4・9、[エディタとシェルのツールを消す](#エディタとシェルのツールを消す)の手順 2・5〜8）は要らない（止めた zoxide も[アプリと貼り付けの設定を外す](#アプリと貼り付けの設定を外す)の手順 4 で消え、bat の設定は同じ項の手順 5 で `persist` ごと消える）。lazygit の設定（`%LOCALAPPDATA%\lazygit`）は scoop の外に残る（外すなら[Git の道具を消す](#git-の道具を消す)の手順 1）
  - zoxide の履歴（`%LOCALAPPDATA%\zoxide`）は scoop の外にあって残る。捨てるなら、[エディタとシェルのツールを消す](#エディタとシェルのツールを消す)の手順 9（scoop を消した後でもよい）
- この節の対象でない項で変えたものは、この節では戻さない。Windows Sandbox は[Windows Sandbox を無効にする](windows-sandbox.md#windows-sandbox-を無効にする)で、ほかはそれぞれの項の最後の「元に戻すときは、」の手順で戻す
  - 対象の項: Wake on LAN・リモートからの再起動・プライバシーと広告・表示と入力と音とストレージ・Edge の常駐・CopyQ・PowerToys・PowerShell 7 のプロファイル・Windows Terminal・WSL のネットワーク・OpenSSH サーバーの公開鍵とパスワード認証・SSH の既定のシェル・scoop のツールを SSH のセッションで使う・Neovim を既定のエディタにする
  - [SSH の既定のシェルを Git Bash にする](../windows-setup.md#ssh-の既定のシェルを-git-bash-にする)を通し、OpenSSH サーバーを残して Git for Windows を外すなら、先にその項の手順 5 で `DefaultShell` を消す
  - [アプリと貼り付けの設定を外す](#アプリと貼り付けの設定を外す)の手順 1 は PowerShell 7 のプロファイルと実行ポリシー（`Documents\PowerShell`）を残す。戻すなら、[アプリと貼り付けの設定を外す](#アプリと貼り付けの設定を外す)の手順 1 の前に（`pwsh.exe` が要る）、[PowerShell 7 のプロファイルを設定する](../shell-terminal.md#powershell-7-のプロファイルを設定する)の手順 7・8
  - [アプリと貼り付けの設定を外す](#アプリと貼り付けの設定を外す)の手順 8 と[サインイン・検索・キーボードを戻す](#サインイン検索キーボードを戻す)の手順 8 で WSL を外す前に `.wslconfig` を戻すなら、[WSL のネットワークをミラーにする](../windows-setup.md#wsl-のネットワークをミラーにする)の手順 6・7

> [!CAUTION]
> [アプリと貼り付けの設定を外す](#アプリと貼り付けの設定を外す)の手順 4 は、**scoop で入れたすべてのアプリを消す**（本書の外で入れたものも）。[アプリと貼り付けの設定を外す](#アプリと貼り付けの設定を外す)の手順 5 は**それらの設定（`~\scoop\persist`）を**、同じ項の手順 8 は **WSL の AlmaLinux 10 のファイルをすべて消す**（取り戻せない）。残すなら、その手順は行わない。[OpenSSH・Git for Windows・Firefox・WezTerm を外す](#opensshgit-for-windowsfirefoxwezterm-を外す)の手順 3 は **OpenSSH サーバーのホスト鍵と、登録した公開鍵（`C:\ProgramData\ssh`）を消す**（取り戻せない。入れ直すとホスト鍵が変わり、クライアントの `known_hosts` と合わなくなる。同じ項の手順 9 で消す）。入れ直すかもしれないなら、その手順は行わない。[エディタとシェルのツールを消す](#エディタとシェルのツールを消す)の手順 9 は、**zoxide が覚えたディレクトリの履歴（`%LOCALAPPDATA%\zoxide`）を消す**（取り戻せない）。

### Git の道具を消す

1. 自分用の lazygit の設定を外し、退避した設定に戻す。

   - lazygit をすべて閉じてから、[ryo-aoki-pc/lazygit の「lazygit の設定のロールバック」](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/extra/readme.md#windows-11-のロールバック)の手順 1・2 を貼る（手順 1 が何も出さないことを確かめてから、手順 2）
   - `%LOCALAPPDATA%\lazygit` を消し、退避した `lazygit.bak` があれば戻す

1. scoop で lazygit を消す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop uninstall lazygit
   Get-Command lazygit -All -ErrorAction SilentlyContinue | Format-Table Source
   ```

   - `'lazygit' was uninstalled.` が出て、最後のコマンドが何も出さなければよい
   - `'lazygit' isn't installed.` なら、もう入っていない
   - 動いている lazygit があると、消さずに止まる（閉じてから貼り直す）
   - `%LOCALAPPDATA%\lazygit`（設定と状態ファイル `state.yml`）は、この項の手順 1 を行わなければ残る。要らなければ手で消す
   - extras のバケットは、ほかのアプリも使うので外さない（外すなら `scoop bucket rm extras`）
   - 自分用の Neovim の設定（LazyVimStarter）は、`<leader>gg` で lazygit を使う。消すと、そのキーが使えなくなる

1. git の設定から delta を外し、消えたか確かめる。

   ```powershell
   git config --global --unset core.pager
   git config --global --unset interactive.diffFilter
   git config --global --remove-section delta
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git config --global --get-regexp '^(core\.pager|interactive\.difffilter|delta\.)'
   ```

   - 最後のコマンドが何も出さなければよい
   - もう外してあれば、`--remove-section` が `fatal: no such section: delta` を出す。そのままでよい
   - Git Bash・PowerShell・cmd のどの git も、delta を通さない表示に戻る
   - `merge.conflictstyle` は、ここでは外さない（[Git Bash の設定を戻す](#git-bash-の設定を戻す)の手順 3 で決める）

1. scoop で delta を消す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop uninstall delta
   (Get-Command delta -All -ErrorAction SilentlyContinue).Source
   ```

   - `'delta' was uninstalled.` が出て、最後のコマンドが何も出さなければよい
   - `'delta' isn't installed.` なら、もう入っていない
   - `are still running` のエラーが出たら、消えていない。開いている delta の表示（less）を `q` で閉じてから貼り直す
   - `DELTA_NAVIGATE=true` で使っていたなら、delta が `%LOCALAPPDATA%\delta`（less の検索履歴の写し）を作っている。要らなければ手で消す
   - 自分用の lazygit の設定を残すなら、その README の「前提ツール」のとおり `git.diffRenderers` を `[]` に戻す（この項の手順 1 で外したなら要らない）
   - 先に、この項の手順 3 で git の設定から delta を外しておく（`core.pager` が delta のまま delta を消すと、`git diff` などが delta を起動できない）

1. この PC のログインを外す。

   ```powershell
   gh auth logout
   ```

   - アカウントが 1 つなら、問わずに `Logged out of github.com account <GITHUB_USER>` を出す。複数あれば、ログアウトするアカウントを選ぶ
   - 資格情報マネージャー（か `hosts.yml`）から、このアカウントのトークンを外す。GitHub 側のトークンは失効しない
   - `not logged in to any hosts` が出たら、もうログアウトしている
   - **次の手順は、`gh auth logout` が終わってから行う**（続けて貼ると対話の答えとして食われる）

1. 全端末の GitHub CLI のトークンも失効させるときだけ、ブラウザで GitHub の認可を取り消す。

   - 操作は[AlmaLinux 10 の初期設定のロールバックの「Git の道具を消す」](almalinux-setup.md#git-の道具を消す)の手順 5 と同じ（OS に依らない）

1. Git の資格情報のヘルパーから gh を外す。

   ```powershell
   foreach ($k in 'credential.https://github.com.helper', 'credential.https://gist.github.com.helper') {
     if ((git config --global --get-all $k) -match 'auth git-credential') { git config --global --unset-all $k }
   }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   git config --get-regexp '^credential\..*helper$'
   ```

   - 最後のコマンドの出力に `credential.helper manager` の行（Git for Windows の既定）があり、`auth git-credential` の行が無ければよい
   - gh を書いていなければ、何も変えない。gh の行が無いキーは残す
   - gh が `~/.gitconfig` に書くのは、ログインで Git の認証に `Y` と答え、Git の資格情報のヘルパーが無かったときと、`gh auth setup-git` を使ったとき

1. ログインで Git の認証に `Y` と答えたときだけ、Git Credential Manager の資格情報を消す。

   ```powershell
   'protocol=https', 'host=github.com' | git credential reject
   ```

   - エラーが出ずにプロンプトに戻ればよい
   - `Y` と答えると、gh は自分のトークンを Git Credential Manager にも入れる（[参考資料](../reference/windows-setup.md#github-cli-windows-11-で使う--手順-4-補足-git-の認証に-n-と答える理由)）。この項の手順 5 では消えない
   - 次に git が GitHub に HTTPS でつなぐときは、Git Credential Manager のサインインになる

1. scoop で gh を消す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop uninstall gh
   (Get-Command gh -All -ErrorAction SilentlyContinue).Source
   ```

   - `'gh' was uninstalled.` が出て、最後のコマンドが何も出さなければよい
   - `'gh' isn't installed.` なら、もう入っていない
   - `are still running` のエラーが出たら、消えていない。ほかの窓で動いている gh を終えてから貼り直す
   - 先に、この項の手順 5 でログアウトしておく（gh を消した後は、資格情報マネージャーに残った gh のトークンを `gh auth logout` で消せない）

1. 設定も消すときだけ、gh の設定と状態のフォルダーを消す。

   ```powershell
   Remove-Item -LiteralPath "$env:APPDATA\GitHub CLI", "$env:LOCALAPPDATA\GitHub CLI" -Recurse -Force -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path -LiteralPath "$env:APPDATA\GitHub CLI", "$env:LOCALAPPDATA\GitHub CLI"
   ```

   - `False` が 2 行出ればよい
   - 設定（`config.yml`・`hosts.yml`。平文で置いたトークンも）と、gh の拡張機能・状態が消える
   - フォルダーを消しても、資格情報マネージャーのトークンは消えない（この項の手順 5 で外す）

### エディタとシェルのツールを消す

1. 自分用の yazi の設定を外すときだけ、clone を消して、退避した設定に戻す。

   - yazi をすべて閉じてから行う
   - 自分用の設定の clone（`%APPDATA%\yazi\config`）を消すときは、次の 2 つが、どちらも何も出さないことを先に確かめる（コミットしていない変更と、push していないコミットが無い）
     - `git -C "$env:APPDATA\yazi\config" status --short`
     - `git -C "$env:APPDATA\yazi\config" log --oneline '@{u}..'`
   - 自分用の設定の clone を消した後、`%APPDATA%\yazi\config.bak` があれば、名前を `config` に戻す（[yazi の設定を導入する](../windows-setup.md#yazi-の設定を導入する)の手順 2 が、元の設定をそこへ退避している）

1. scoop で yazi を消す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop uninstall yazi
   Get-Command yazi, ya -All -ErrorAction SilentlyContinue | Format-Table Source
   ```

   - `'yazi' was uninstalled.` が出て、最後のコマンドが何も出さなければよい
   - `'yazi' isn't installed.` なら、もう入っていない
   - 動いている yazi があると、消さずに止まる（閉じてから貼り直す）
   - 依存ツール（`$YAZI_EXTRAS` で入れたもの）は、ほかでも使うので、消すなら個別に `scoop uninstall` する（`7zip` は scoop 自身も展開に使うので残す）
   - `%APPDATA%\yazi`（`config` と `state`）と `%LOCALAPPDATA%\yazi`（キャッシュ）は残るので、要らなければ手で消す
   - Git Bash の `y` は、yazi を消した後に開いたシェルでは定義されない

1. ユーザーの環境変数 `YAZI_FILE_ONE` を消す。

   ```powershell
   if ([Environment]::GetEnvironmentVariable('YAZI_FILE_ONE', 'User') -eq 'C:\Program Files\Git\usr\bin\file.exe') { [Environment]::SetEnvironmentVariable('YAZI_FILE_ONE', $null, 'User') }
   $env:YAZI_FILE_ONE = [Environment]::GetEnvironmentVariable('YAZI_FILE_ONE', 'User')
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'YAZI_FILE_ONE = {0}' -f $env:YAZI_FILE_ONE
   ```

   - `YAZI_FILE_ONE = `（値が空）が出ればよい
   - 値が Git for Windows の `file.exe`（[yazi](../windows-setup.md#yazi)の手順 5 で入れた値）のときだけ消す。ほかの値は残り、その値が出る
   - 今の窓の値も、ユーザーの値に合わせる。ほかの開いている窓には前の値が残る（開き直すと消える）
   - [yazi](../windows-setup.md#yazi)の手順 3 で元の値を控えていたら、`[Environment]::SetEnvironmentVariable('YAZI_FILE_ONE', '<控えた値>', 'User')` を、値を入れて打って戻す

1. 自分用の Neovim の設定とプラグインを消し、退避した設定に戻す。

   - Neovim をすべて閉じてから、[LazyVimStarter の「LazyVim の設定のロールバック」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#ロールバック)の手順 5・6 を貼る
   - その手順 6 は、設定のフォルダーごと消す（push していない変更は取り戻せない）。その手順 5 で、何も出ないことを確かめてから行う
   - その手順 7（scoop の Neovim・zenhan・lazygit をまとめて消す）は行わない。Neovim はこの項の手順 5、lazygit は[Git の道具を消す](#git-の道具を消す)の手順 2 で消す（zenhan は残る。要らなければ `scoop uninstall zenhan`）

1. scoop で Neovim を消す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop uninstall neovim
   Get-Command nvim -All -ErrorAction SilentlyContinue | Format-Table Source
   ```

   - `'neovim' was uninstalled.` が出て、最後のコマンドが何も出さなければよい
   - `'neovim' isn't installed.` なら、もう入っていない
   - 動いている Neovim があると、消さずに止まる（閉じてから貼り直す）
   - `%LOCALAPPDATA%\nvim`（設定）・`%LOCALAPPDATA%\nvim-data`（プラグイン・undo・ログ）・`%TEMP%\nvim-data`（キャッシュ）は残るので、要らなければ手で消す
   - VC++ のランタイムは、ほかのアプリも使うので消さない
   - ユーザーの環境変数 `EDITOR`・`VISUAL` は、[Neovim を既定のエディタにする](../neovim.md#neovim-を既定のエディタにする)の手順 3 で消す

1. ほかに使うものが無いときだけ、scoop で入れた Node.js を外す。

   ```powershell
   scoop uninstall nodejs-lts
   ```

   - [AI エージェントのロールバックの「Windows 11 で AI エージェントとプラグインを消す」](ai-agents.md#windows-11-で-ai-エージェントとプラグインを消す)の手順 1 でプラグインを外してから行う（プラグインは Claude Code の起動と終了のたびに `node` を動かす）
   - `nodejs-lts` は、[AI エージェントの手順書の「Windows 11 で Codex・Grok のプラグインを入れる」](../ai-agents.md#windows-11-で-codexgrok-のプラグインを入れる)の手順 1 で入れたときだけある。自分用の Neovim の設定（その導入の手順 6）が入れた `nodejs` も外すなら、この項の手順 4 の後に `scoop uninstall nodejs`

1. [シェルのツールを入れる](../shell-terminal.md#シェルのツールを入れる)で入れた 5 つを scoop で消す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop uninstall fzf zoxide starship eza bat
   (Get-Command fzf, zoxide, starship, eza, bat -All -ErrorAction SilentlyContinue).Source
   [Environment]::GetEnvironmentVariable('BAT_CONFIG_DIR', 'User')
   ```

   - それぞれ `'<名前>' was uninstalled.` が出て、後の 2 つが何も出さなければよい（止めた zoxide も、そのまま消える）
   - 残すものは、名前を外してから貼る（fzf は yazi も使う）
   - `are still running` の旨のエラーが出たら、そのツールは消えていない。Git Bash で開いている一覧などを閉じてから貼り直す
   - starship の `Path` と、bat の `BAT_CONFIG_DIR` も消える。bat の設定（`~\scoop\persist\bat`）は残る（この項の手順 8）
   - 開いている Git Bash のタブと PowerShell 7 の窓は、閉じて開き直す
   - starship のログ（`~\.cache\starship`）は、要らなければ手で消す

1. [シェルのツールを入れる](../shell-terminal.md#シェルのツールを入れる)の手順 6 で書いたときだけ、bat の設定ファイルの 3 行を消す。

   ```powershell
   & {
     $f = Join-Path $env:USERPROFILE 'scoop\persist\bat\config'
     if (-not (Test-Path -LiteralPath $f)) { "無い: $f"; return }
     $text = [IO.File]::ReadAllText($f)
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not $text.Trim()) { "もう空: $f" } elseif ($text -match '\A--theme="[^"\r\n]*"\r?\n--style="numbers,changes,header"\r?\n--paging=never\r?\n?\z') {
       [IO.File]::WriteAllText($f, '')
       "空にした: $f"
     } else { "「シェルのツールを入れる」の手順 6 で書いた形ではない（変えない）: $f" }
   }
   ```

   - `空にした:` か `もう空:` が出ればよい（scoop が bat を初めて入れたときと同じ、空のファイルになる）
   - bat を残していれば、次に動かしたときから、組み込みの既定値に戻る
   - `「シェルのツールを入れる」の手順 6 で書いた形ではない` が出たら、手で書き換えた設定がある。要らない行は、手で消す

1. 履歴も捨てるときだけ、zoxide が覚えたディレクトリの履歴を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:LOCALAPPDATA\zoxide" -Recurse -Force -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path -LiteralPath "$env:LOCALAPPDATA\zoxide"
   ```

   - `False` が出ればよい
   - 消した履歴は取り戻せない。残しておけば、zoxide を入れ直したときにそのまま使える
   - PowerShell 7 の zoxide と yazi も、同じ履歴を使う

### Git Bash の設定を戻す

1. スタートメニューから Git Bash を開く。

   - スタートメニューで「Git Bash」を探して開く（管理者でなくてよい。この項の手順 7 で WezTerm の設定を消すので、WezTerm のタブは使わない）
   - Git Bash の窓に貼るときは、窓の中を右クリックして出るメニューの「Paste」を選ぶ。最後の行は、貼った後に Enter を押す
   - **次の手順は、この Git Bash に貼る**

1. 共通の Git 設定と Windows の長いパス対応で、今回追加・変更したキーだけ元に戻す（`merge.conflictStyle` を除く）。

   - [Git Bash と WezTerm の設定](../shell-terminal.md#git-bash-と-wezterm-の設定)の手順 4・5 で `global`（`C:\Users\<WIN_USER>\.gitconfig`）に書いた設定を外す。`system` と `local` の設定は変えない
   - 共通の設定は[AlmaLinux 10 の初期設定の「Git」](../almalinux-setup.md#git)の手順 2、`core.longpaths` は[Git Bash と WezTerm の設定](../shell-terminal.md#git-bash-と-wezterm-の設定)の手順 5 で控えた元の値・スコープと変更の記録を使う。変更しなかったキーは残す
   - 控えた記録で、元の `global` が未設定だったキーだけ、`git config --global --unset <キー>` の形で 1 行ずつ外す
   - 元の `global` に値があったキーは、この項の手順 5 で書き戻す。変更なしのキーと、[AlmaLinux 10 の「Git」](../almalinux-setup.md#git)の手順 7 を飛ばした場合の `pull.ff` は触らない
   - 対象は `pull.rebase`・`rebase.autoStash`・`core.autocrlf`・`init.defaultBranch`・`core.quotepath`・`fetch.prune`・`push.autoSetupRemote`・`rerere.enabled`・`diff.algorithm`・`branch.sort`・`tag.sort`・`pull.ff`
   - `core.longpaths` も今回変更したときだけ対象にする。元の `global` が未設定なら `git config --global --unset core.longpaths`、値があったなら、この項の手順 5 で戻す
   - 例: 今回初めて追加した `core.autocrlf` なら `git config --global --unset core.autocrlf`
   - 外すと何も出ない。最後のキーを外した `~/.gitconfig` の節も消える

1. git-delta も消したとき（[Git の道具を消す](#git-の道具を消す)の手順 3・4）だけ、今回変えた `merge.conflictStyle` も元に戻す。

   - git-delta を残すなら、そのまま残す（同じ設定を使う）
   - 今回追加し、元の `global` が未設定なら `git config --global --unset merge.conflictStyle` で外す
   - 元の `global` に値があったなら、この項の手順 5 で書き戻す。変更なしなら触らない

1. 名前とメールアドレスも戻すときだけ、今回変えた値を元に戻す。

   - 今回追加し、元の `global` が未設定だったものだけ、`git config --global --unset user.name` または `git config --global --unset user.email` で外す
   - 元の `global` に値があったものは、この項の手順 5 で書き戻す。変更なしのものは触らない
   - 外すと、`git commit` が `Author identity unknown` で止まることがある（検証コンテナでは止まった）

1. この項の手順 2〜4 で戻すと決めたキーのうち、元の `global` に値があったものを、控えた値で書き戻す。

   - `git config --global <キー> <元の値>` の形で、キーごとに 1 行ずつ貼る
   - 例: 元の `core.autocrlf` を戻すなら `git config --global core.autocrlf <元の値>`
   - `core.longpaths` は[Git Bash と WezTerm の設定](../shell-terminal.md#git-bash-と-wezterm-の設定)の手順 5、ほかのキーは[AlmaLinux 10 の初期設定の「Git」](../almalinux-setup.md#git)の手順 2 の記録を使う
   - 空白を含む値は引用符で囲む。元の値が `system` や `local` だけにあった場合は、それを `global` に写さない（今回追加した `global` を外せば、元のスコープの値がまた効く）
   - 残すと決めた `merge.conflictStyle`・名前・メールアドレスと、今回変更しなかったキーは書き戻さない

1. 外れたか確かめる。

   ```bash
   git config --global --list
   ```

   - 今回戻すキーが、この項の手順 2・5 が示す記録の元の `global` と一致すればよい（元が未設定なら出ない、元の値があればその値が出る）
   - 残すと決めたキーと、本書で変更しなかったキーはそのまま。元の設定が空で、今回の設定をすべて外した場合だけ、何も出ない
   - 元は `~/.gitconfig` が無かった場合も、空のファイルが残る（中身が無いので、git の動きは変わらない）

1. 自分用の WezTerm の設定を外し、退避した設定に戻す。

   - WezTerm の窓をすべて閉じてから、[ryo-aoki-pc/wezterm の「WezTerm の設定のロールバック」](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/extra/install.md#ロールバック)の手順 1〜4 を、この Git Bash に貼る
   - その手順 3 は `~/.config/wezterm` を消す（commit・push していないものは取り戻せない）。その手順 2 で確かめてから行う

1. 共通の bash 設定も外すときだけ、外す。

   - [共通の bash 設定のロールバック](https://github.com/ryo-aoki-pc/bash/blob/main/docs/extra/quick-start.md#ロールバック)を、この Git Bash に貼る（[Git Bash と WezTerm の設定](../shell-terminal.md#git-bash-と-wezterm-の設定)の手順 6 で入れたもの）
   - 設定リポジトリも消すなら、[手動移行のロールバック](https://github.com/ryo-aoki-pc/bash/blob/main/docs/extra/install.md#ロールバック)の手順 4 で確かめ、手順 5 を行う。`~/.config/bash` の未 commit・未 push の変更は取り戻せない
   - 終わったら、Git Bash の窓は閉じてよい

### OpenSSH・Git for Windows・Firefox・WezTerm を外す

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く
   - Git Bash・WezTerm・Firefox の窓は、すべて閉じておく
   - **この項の手順 2〜8 は、この窓に貼る**

1. sshd を止め、OpenSSH サーバーの機能を外す。

   ```powershell
   if ($PSVersionTable.PSEdition -ne 'Desktop') {
     Write-Error 'Windows PowerShell（5.1）で貼る'
   } else {
     Stop-Service -Name sshd
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
     Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Format-List Name, State
   }
   ```

   - `RestartNeeded : False` と `State : NotPresent` が出ればよい
   - サービス `sshd`、`sshd.exe`、受信の規則 `OpenSSH-Server-In-TCP` が消える。クライアントの `ssh.exe` などは残る
   - 機能を外しても、`C:\ProgramData\ssh` とレジストリの `HKLM:\SOFTWARE\OpenSSH` は残る（この項の手順 3 で消す）

1. 設定・ホスト鍵・登録した公開鍵と、レジストリのキーを消す（取り戻せない）。

   ```powershell
   Remove-Item -Path "$env:ProgramData\ssh" -Recurse -Force
   Remove-Item -Path HKLM:\SOFTWARE\OpenSSH -Recurse
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path "$env:ProgramData\ssh", HKLM:\SOFTWARE\OpenSSH
   ```

   - `False` が 2 行出ればよい
   - LAN の接続をパブリックに戻すのは、[ネットワークと PC 全体の設定を戻す](#ネットワークと-pc-全体の設定を戻す)の手順 5（この LAN でほかにプライベートの規則を使うもの（[Syncthing の Windows 11 の節](../syncthing.md#windows-11-で-syncthing-を使う)、リモート デスクトップなど）があれば、戻さない）

1. Git for Windows も外すときだけ、Git Bash を閉じてから winget で外す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget uninstall --exact --id Git.Git --source winget
   winget list --exact --id Git.Git --source winget
   Test-Path 'C:\Program Files\Git\bin\bash.exe'
   ```

   - `正常にアンインストールされました`（英語の Windows では `Successfully uninstalled`）と出て、`winget list` が `入力条件に一致するインストール済みのパッケージが見つかりませんでした。` を出し、`False` が出ればよい
   - **注意**: Claude Code（Windows）の Bash のツールは Git Bash を使う。外すと、PowerShell のツールだけになる
   - **注意**: [SSH の既定のシェルを Git Bash にする](../windows-setup.md#ssh-の既定のシェルを-git-bash-にする)の `DefaultShell` は `C:\Program Files\Git\bin\bash.exe` を指す。OpenSSH サーバーを残すなら、外す前にその項の手順 5 で `DefaultShell` を消す（外したままだと、無いファイルを指したままになる。この項の手順 3 を行ったなら、もう消えている）
   - scoop の git が無い PC では、`scoop update` が git を求めて止まるようになる
   - `global`（`C:\Users\<WIN_USER>\.gitconfig`）は消えない（[Git Bash の設定を戻す](#git-bash-の設定を戻す)の手順 2〜6 で外す）

1. Firefox をすべて閉じてから、winget でアンインストーラを起動する。

   ```powershell
   winget uninstall --exact --id Mozilla.Firefox.ja --source winget
   ```

   - Firefox のアンインストールの窓が開くので、案内に沿ってアンインストールを選び、最後に「完了」を押す
   - 「Firefox をリフレッシュ」を勧める画面が出ても、リフレッシュは選ばない（プロファイルを作り直すだけで、Firefox は消えない）
   - winget は Firefox のアンインストーラを、画面を出したまま起動する
   - **次の手順は、アンインストールの窓で「完了」を押してから貼る**（winget が先に終わっても、窓が閉じるまでは消し終わっていない）

1. Firefox が消えたことを確かめる。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id Mozilla.Firefox.ja --source winget
   Test-Path -LiteralPath "$env:ProgramFiles\Mozilla Firefox"
   Get-Service -Name MozillaMaintenance -ErrorAction SilentlyContinue | Format-Table Name, Status
   Get-ScheduledTask -TaskPath '\Mozilla\' -ErrorAction SilentlyContinue | Format-Table TaskName, State
   ```

   - `winget list` が見つからない旨を出し、`False` が出て、最後の 2 つが何も出さなければよい
   - Firefox が自分で更新した PC では、`C:\Program Files\Mozilla Firefox` に `update_telemetry.json` だけが残り、`True` になることがある。中がそれだけなら、フォルダーごと手で消してよい
   - `MozillaMaintenance` が残るのは、Thunderbird などほかの Mozilla のアプリが使っているとき
   - プロファイル（`%APPDATA%\Mozilla\Firefox` と `%LOCALAPPDATA%\Mozilla\Firefox`）は、この項のどの手順でも消えない
   - 入れ直すと、同じプロファイルを使う（最初の起動で「Firefox をリフレッシュ」を勧められることがある）。要らなければ手で消す（取り戻せない。ブックマークと保存したパスワードも消える）

1. 別のブラウザーを既定にするときだけ、Windows の設定で既定にする。

   - 設定 →「アプリ」→「既定のアプリ」で使うブラウザーを選び、「既定値に設定」を押す（[Firefox](../windows-setup.md#firefox)の手順 5 と同じ操作）
   - 既定のブラウザーは、Firefox を外すと Windows が戻す（Microsoft Edge になるはず）

1. WezTerm のアンインストーラを黙って動かし、消えたことを確かめる。

   ```powershell
   & {
     $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1'
     $dir = 'C:\Program Files\WezTerm'
     $u = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
     if (-not $u) { Write-Error '中断: WezTerm のアンインストールの登録が無い'; return }
     if ($u.UninstallString -notmatch '^"([^"]+\\unins\d{3}\.exe)"') { Write-Error "中断: UninstallString が想定と違う（$($u.UninstallString)）"; return }
     $unins = $Matches[1]
     if (Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue) { Write-Error '中断: WezTerm が動いている（窓をすべて閉じる）'; return }
     $p = Start-Process -FilePath $unins -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -Wait -PassThru
     if ($p.ExitCode -ne 0) { Write-Error "中断: アンインストーラが終了コード $($p.ExitCode) で終わった"; return }
     for ($i = 0; $i -lt 60 -and ((Test-Path -LiteralPath $key) -or (Test-Path -LiteralPath $dir)); $i++) { Start-Sleep -Seconds 1 }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Test-Path -LiteralPath $key, $dir
     [Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';' | Where-Object { $_ -like '*\WezTerm*' }
   }
   ```

   - `False` が 2 行出て、その後に何も出なければよい（登録・`C:\Program Files\WezTerm`・`PATH` の行が消えた）
   - `中断:` で始まるエラーが出たら、そこで止まっている（アンインストーラの終了コードのときは、途中まで消えていることがある）
   - 2 行目が `True` のまま（60 秒待ってから出る）なら、インストーラが置いていないファイル（`wezterm.lua` など）が `C:\Program Files\WezTerm` に残っている。中を見て、要らなければ消す
   - 設定のアプリ → インストールされているアプリ の「WezTerm」の「アンインストール」でも同じ
   - 設定ファイル（`%USERPROFILE%\.wezterm.lua`・`%USERPROFILE%\.config\wezterm`）は消えない。要らなければ手で消す（自分用の設定は、[Git Bash の設定を戻す](#git-bash-の設定を戻す)の手順 7 で外す）
   - [WezTerm](../shell-terminal.md#windows-11-で-wezterm-を入れる)の手順 3 で入れた Visual C++ の再頒布可能パッケージは、ほかのアプリも使うので消さない

1. クライアントの PC で、Windows のホスト鍵を `known_hosts` から消す。

   ```bash
   ssh-keygen -R "${WIN_HOST:?「SSH でログインを確かめる」の手順 4 の WIN_HOST が空のまま}"
   ```

   - `# Host <WIN_HOST> found: line N` が鍵の種類の数だけ出て、`… known_hosts updated.` で終わればよい
   - **注意**: 元の `known_hosts` は `~/.ssh/known_hosts.old` に写される。前からあった `known_hosts.old` は上書きされる
   - [SSH でログインを確かめる](../windows-setup.md#ssh-でログインを確かめる)の手順 4 の変数を設定した、クライアントのシェルに貼る（この PC の WSL の AlmaLinux 10 なら、そのシェル）

### HackGen Console NF を消す

1. HackGen の登録を消す。

   ```powershell
   $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
   (Get-Item -LiteralPath $key).Property -like 'HackGen*ConsoleNF-* (TrueType)' | ForEach-Object { Remove-ItemProperty -LiteralPath $key -Name $_ }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-Item -LiteralPath $key).Property -like 'HackGen*'
   ```

   - 最後のコマンドが何も出さなければよい
   - フォントのファイルは読み込まれている間は消せないので、登録を消してからサインインし直し、その後でファイルを消す

1. この PC でサインアウトし、サインインし直す。

   - 再起動でもよい
   - **次の手順は、サインインし直して Windows PowerShell（5.1）を開いてから貼る**

1. フォントのファイルを消す。

   ```powershell
   Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\HackGen*ConsoleNF-*.ttf"
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" -Filter 'HackGen*'
   ```

   - 最後のコマンドが何も出さなければよい
   - [HackGen Console NF](../shell-terminal.md#windows-11-で-hackgen-console-nf-を入れる)の手順 3 の `icacls` で足した読み取りの許可は残す（ほかのフォントにも要る）

### 表示と入力を戻す

1. エクスプローラーの表示を既定に戻す。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   $exp = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
   Set-ItemProperty -Path $adv -Name HideFileExt -Type DWord -Value 1
   Set-ItemProperty -Path $adv -Name Hidden -Type DWord -Value 2
   Remove-ItemProperty -Path $adv -Name LaunchTo -ErrorAction SilentlyContinue
   Set-ItemProperty -Path $adv -Name Start_TrackDocs -Type DWord -Value 1
   Set-ItemProperty -Path $exp -Name ShowRecent -Type DWord -Value 1
   Set-ItemProperty -Path $exp -Name ShowFrequent -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $adv | Format-List HideFileExt, Hidden, LaunchTo, Start_TrackDocs
   ```

   - `HideFileExt : 1`・`Hidden : 2`・`Start_TrackDocs : 1` が出て、`LaunchTo` が空ならよい
   - エクスプローラーには、開き直すか再起動の後に効く

1. 旧形式のコンテキストメニューの設定を消す。

   ```powershell
   reg.exe delete 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' /f
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path -LiteralPath 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}'
   ```

   - `False` が出ればよい
   - エクスプローラーに効くのは、サインインし直すか、[再起動と PSWindowsUpdate](#再起動と-pswindowsupdate)の手順 1 の再起動の後

1. スタートと設定の、おすすめ・提案・ヒントを既定に戻す。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
   Set-ItemProperty -Path $adv -Name Start_IrisRecommendations -Type DWord -Value 1
   Set-ItemProperty -Path $adv -Name Start_AccountNotifications -Type DWord -Value 1
   foreach ($n in 'SubscribedContent-338393Enabled', 'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled', 'SubscribedContent-338389Enabled', 'SubscribedContent-310093Enabled', 'SubscribedContent-338388Enabled', 'SystemPaneSuggestionsEnabled', 'SilentInstalledAppsEnabled') { Set-ItemProperty -Path $cdm -Name $n -Type DWord -Value 1 }
   Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Name ScoobeSystemSettingEnabled -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $cdm | Format-List SubscribedContent-338393Enabled, SubscribedContent-353694Enabled, SubscribedContent-353696Enabled, SubscribedContent-338389Enabled, SubscribedContent-310093Enabled, SubscribedContent-338388Enabled, SystemPaneSuggestionsEnabled, SilentInstalledAppsEnabled
   ```

   - 並んだ値がすべて `1` ならよい
   - スタートの検索の Web の結果は、[サインイン・検索・キーボードを戻す](#サインイン検索キーボードを戻す)の手順 6 で戻す

1. タスクバーを既定に戻す。

   ```powershell
   $adv = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
   foreach ($n in 'TaskbarAl', 'ShowTaskViewButton', 'ShowSecondsInSystemClock') { Remove-ItemProperty -Path $adv -Name $n -ErrorAction SilentlyContinue }
   Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name SearchboxTaskbarMode -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $adv | Format-List TaskbarAl, ShowTaskViewButton, ShowSecondsInSystemClock
   ```

   - 3 つの値が空ならよい（値が無いと既定の、中央・タスク ビューあり・秒なし・検索ボックス）
   - ウィジェットは、この項の手順 9 で入れ直す

1. 淡色（ライトモード）に戻す。

   ```powershell
   $p = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
   Set-ItemProperty -Path $p -Name AppsUseLightTheme -Type DWord -Value 1
   Set-ItemProperty -Path $p -Name SystemUsesLightTheme -Type DWord -Value 1
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $p | Format-List AppsUseLightTheme, SystemUsesLightTheme
   ```

   - 2 つとも `1` が出ればよい

1. 既定の端末を「Windows に任せる」に戻す。

   ```powershell
   foreach ($n in 'DelegationConsole', 'DelegationTerminal') { Remove-ItemProperty -LiteralPath 'HKCU:\Console\%%Startup' -Name $n -ErrorAction SilentlyContinue }
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -LiteralPath 'HKCU:\Console\%%Startup' -ErrorAction SilentlyContinue | Format-List DelegationConsole, DelegationTerminal
   ```

   - 2 つの値が空ならよい（Windows 11 22H2 以降は、Windows Terminal が入っていればそれを使う）

1. Microsoft IME の設定を開き、Ctrl+Space の割り当てを外す。

   ```powershell
   Start-Process 'ms-settings:regionlanguage-jpnime'
   ```

   - 「キーとタッチのカスタマイズ」で、「Ctrl + Space」を「なし」にするか、「キーの割り当て」をオフにする
   - **次の手順は、設定を閉じてから PowerShell に貼る**

1. 自動で起動するアプリ（OneDrive・Edge・Teams）を、起動するように戻す。

   ```powershell
   & {
     $ok = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
     $props = (Get-Item -LiteralPath $ok -ErrorAction SilentlyContinue).Property | Where-Object { $_ -eq 'OneDrive' -or $_ -eq 'OneDriveSetup' -or $_ -like 'MicrosoftEdgeAutoLaunch_*' }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     foreach ($n in $props) { Set-ItemProperty -LiteralPath $ok -Name $n -Type Binary -Value ([byte[]](2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)); "戻した: $n" }
     $teams = 'HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MSTeams_8wekyb3d8bbwe\TeamsTfwStartupTask'
     if (Test-Path -LiteralPath $teams) { Set-ItemProperty -LiteralPath $teams -Name State -Type DWord -Value 2; '戻した: Teams' }
   }
   ```

   - 止めていたものごとに `戻した:` が出ればよい（無ければ何も出ない）
   - 効くのは、次のサインインから。タスク マネージャーの「スタートアップ アプリ」からでも戻せる

1. 外した標準アプリとウィジェットを戻すときだけ、ストアと winget から入れ直す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   foreach ($id in '9P1J8S7CCWWT', '9WZDNCRFHVFW', '9WZDNCRFJ3Q2', '9WZDNCRFHWD2', '9WZDNCRD29V9', '9NBLGGH5R558', '9NBLGGH4R32N', '9PKDZBMV1H3T', '9NRX63209R7B', '9NFTCH6J7FHV', '9MSSGKG348SP') { winget install --exact --id $id --source msstore --accept-source-agreements --accept-package-agreements }
   winget install --exact --id Microsoft.Teams --source winget --accept-source-agreements --accept-package-agreements
   ```

   - アプリごとに、入れた旨か、もう入っている旨の行が出る
   - `No package found matching input criteria.`（ストアにその ID が無い）や `0x80073cfb` で入らないアプリは、PC に残っているものを `Add-AppxPackage -RegisterByFamilyName -MainPackage <パッケージ ファミリー名>` で登録し直す（例: `Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe`）
   - 要らないアプリは、その ID を消してから貼る（ID とアプリの対応は[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-setup.md)・[参考資料](../reference/windows-setup.md)の表。`9MSSGKG348SP` がウィジェット）

### アプリと貼り付けの設定を外す

1. PowerShell 7 を外す。

   ```powershell
   winget uninstall --exact --id Microsoft.PowerShell --source winget
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id Microsoft.PowerShell
   ```

   - 最後のコマンドが、入っているパッケージが見つからない旨の行を出せばよい
   - PowerShell 7 のプロファイル（`Documents\PowerShell`）は残る

1. PowerToys を外す。

   ```powershell
   winget uninstall --exact --id Microsoft.PowerToys --source winget
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id Microsoft.PowerToys
   ```

   - 最後のコマンドが、入っているパッケージが見つからない旨の行を出せばよい
   - 動いている PowerToys は、アンインストーラが閉じる。設定（`%LOCALAPPDATA%\Microsoft\PowerToys`）は残る

1. UniGet UI を外す。

   ```powershell
   winget uninstall --exact --id Devolutions.UniGetUI --source winget
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget list --exact --id Devolutions.UniGetUI
   ```

   - 最後のコマンドが、入っているパッケージが見つからない旨の行を出せばよい
   - 動いている UniGet UI は、アンインストーラが閉じる
   - 設定（`%LOCALAPPDATA%\UniGetUI`）は残る。要らなければ手で消す

1. scoop と、scoop で入れたすべてのアプリを外す。

   ```powershell
   Get-ChildItem -Path "$env:USERPROFILE\scoop\apps\*\current" -Force -ErrorAction SilentlyContinue | ForEach-Object { attrib.exe -R /L $_.FullName }
   scoop uninstall scoop
   ```

   - 1 行目は、scoop がアプリごとに作る `current`（ジャンクション）の読み取り専用を外す。外さないと `Couldn't remove ~\scoop\apps` で止まる
   - `Are you sure? (yN)` と聞かれるので、`y` を入れる
   - 最後に `Scoop has been uninstalled.` が出ればよい（`~\scoop\persist` は残る）
   - 消せないアプリがあると `Couldn't remove` の旨の行で止まる。そのアプリを閉じて、この手順を貼り直す
     - `scoop` が見つからない旨が出たら、scoop 本体が先に消えている。この項の手順 5 で残りを消す（`persist` も消える）
     - 途中で止まったときは、ユーザーの PATH に `~\scoop\shims` が残る。要らなければ手で外す
   - **次の手順は、`Scoop has been uninstalled.` が出てから貼る**（続けて貼ると `y` の答えとして食われる）

1. scoop の残りを消すときだけ、`persist` と設定を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\scoop", "$env:USERPROFILE\.config\scoop" -Recurse -Force -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Test-Path "$env:USERPROFILE\scoop", "$env:USERPROFILE\.config\scoop"
   ```

   - `False` が 2 行出ればよい
   - この手順を行わないと、scoop を入れ直すときに[アプリを入れる](../windows-setup.md#アプリを入れる)の手順 2 が `exists and is not empty` で止まる

1. プロファイルから、貼り付けの設定と任意のキー操作の印の行を消す。

   ```powershell
   & {
     $line = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-setup.md'
     $old = 'Set-PSReadLineKeyHandler -Chord Ctrl+Enter -Function AddLine  # windows-powershell-paste.md'
     if (-not (Test-Path -LiteralPath $PROFILE)) { "プロファイルが無い: $PROFILE"; return }
     $bytes = [System.IO.File]::ReadAllBytes($PROFILE)
     $enc = if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { [System.Text.Encoding]::Unicode } else { [System.Text.Encoding]::GetEncoding(28591) }
     $text = $enc.GetString($bytes)
     $rest = [regex]::Replace($text, '(?m)^(\uFEFF|\u00EF\u00BB\u00BF)?(' + [regex]::Escape($line) + '|' + [regex]::Escape($old) + '|[^\r\n]*  # shell-terminal\.md)\r?(\n|$)', '$1')
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if ($rest -eq $text) { "その行は無い: $PROFILE" } elseif ($rest -match '^(\uFEFF|\u00EF\u00BB\u00BF)?\s*$') { Remove-Item -LiteralPath $PROFILE; "消した: $PROFILE" } else { [System.IO.File]::WriteAllBytes($PROFILE, $enc.GetBytes($rest)); "その行だけ消した: $PROFILE" }
   }
   ```

   - プロファイルにほかの行が無ければ `消した:`、あれば `その行だけ消した:` が出る
   - 前の版の手順書（`windows-powershell-paste.md`）の印の行も消す
   - [貼り付けの設定](../windows-setup.md#貼り付けの設定)の手順 5 と、[Windows PowerShell 5.1 のキー操作を変える](../shell-terminal.md#windows-powershell-51-のキー操作を変える)の印の行を消す。印の無い行は残る
   - 開いている窓の設定（[貼り付けの設定](../windows-setup.md#貼り付けの設定)の手順 2・5）は、窓を閉じるまで残る
   - 戻した後の PowerShell のブロックは、既定の Windows モードの conhost の窓では Ctrl+V で貼る（右クリックで貼ると、行が逆順になる）
   - 印の無い Emacs モードの行が残ると、次の窓では Ctrl+V の貼り付けが使えないことがある。その場合は、Win+R で `powershell.exe -NoProfile` を開き、既定のキーで Ctrl+V を使う

1. 実行ポリシーを戻すときだけ、元の値にする（`OLD_EXECUTION_POLICY` は必ず値を入れる）。

   ```powershell
   $OLD_EXECUTION_POLICY = ''   # 「貼り付けの設定」の手順 3 で控えた CurrentUser の値（Undefined・Restricted・AllSigned・RemoteSigned・Unrestricted・Bypass）
   ```

   ```powershell
   if ($OLD_EXECUTION_POLICY -notin 'Undefined', 'Restricted', 'AllSigned', 'RemoteSigned', 'Unrestricted', 'Bypass') {
     Write-Error '中断: $OLD_EXECUTION_POLICY に「貼り付けの設定」の手順 3 で控えた CurrentUser の値を入れる'
   } else {
     Set-ExecutionPolicy -ExecutionPolicy $OLD_EXECUTION_POLICY -Scope CurrentUser -Force -ErrorAction Stop
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-ExecutionPolicy -List | Format-Table -AutoSize
   }
   ```

   - [貼り付けの設定](../windows-setup.md#貼り付けの設定)の手順 4 で値を変えなかった場合は、この手順を飛ばす。元の値を控えていなければ、推測で戻さない
   - 表の `CurrentUser` が、[貼り付けの設定](../windows-setup.md#貼り付けの設定)の手順 3 で控えた値に戻ればよい。`Undefined` は自分のユーザーの設定を消す値
   - **注意**: 戻した後の実効値が `Restricted` なら、scoop などのスクリプトやプロファイルは動かない。`AllSigned` なら署名が必要になる

1. WSL の AlmaLinux 10 を消すときだけ、登録を外す（取り戻せない）。

   ```powershell
   wsl.exe --unregister AlmaLinux-10
   $env:WSL_UTF8 = '1'
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   wsl.exe --list --verbose
   ```

   - AlmaLinux 10 の中のファイルは、すべて消える
   - 最後の一覧に `AlmaLinux-10` が無ければよい（ほかのディストリビューションが無ければ、無い旨の行）

### サインイン・検索・キーボードを戻す

1. 管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. 変数を設定する。

   ```powershell
   $LAN_IF = (Get-NetConnectionProfile | Where-Object IPv4Connectivity -eq Internet | Select-Object -First 1).InterfaceAlias   # ほかの PC とつながる LAN の接続（自動）。<LAN_IF>
   'LAN_IF = {0}' -f $LAN_IF
   ```

   - [PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 2 の 2 つ目のブロックと同じ（`LAN_IF` が違えば直す）
   - `LAN_IF` は、[ネットワークと PC 全体の設定を戻す](#ネットワークと-pc-全体の設定を戻す)の手順 5・6 で使う

1. 自動サインインを止めるときは、Autologon を起動し、`Disable` を押す。

   ```powershell
   $exe = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter Autologon64.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
   if (-not $exe) { Write-Error '中断: Autologon64.exe が見つからない' } else { Start-Process -FilePath $exe -ArgumentList '-accepteula' }
   ```

   - Autologon の窓で `Disable` を押す。自動ログオンの設定と、置いてあったパスワード（LSA のシークレット）が消える
   - **次の手順は、Autologon の窓が閉じてから貼る**

1. [表示と入力を戻す](#表示と入力を戻す)から[アプリと貼り付けの設定を外す](#アプリと貼り付けの設定を外す)までの手順の管理者ではない窓で、Autologon を外す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   winget uninstall --exact --id Microsoft.Sysinternals.Autologon --source winget
   (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon').AutoAdminLogon
   ```

   - アンインストールの成功の行と、`0` が出ればよい（自動ログオンが無効）
   - [WSL の AlmaLinux 10 と自動サインイン](../windows-setup.md#wsl-の-almalinux-10-と自動サインイン)の手順 5 で自分のユーザーに入れたので、管理者の窓では `The package installed for user scope cannot be uninstalled when running with administrator privileges.` で外れない
   - `1` が出たら、この項の手順 3 で `Disable` を押していない。外す前に戻って押す（外した後は、もう一度入れてから）

1. [PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 3 で `HelloOnly` が `2` だったときだけ、「Windows Hello サインインのみを許可する」をオンに戻す。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' -Name DevicePasswordLessBuildVersion -Type DWord -Value 2
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device' | Format-List DevicePasswordLessBuildVersion
   ```

   - `DevicePasswordLessBuildVersion : 2` が出ればよい

1. スタートの検索の Web の結果を、出すように戻す。

   ```powershell
   Remove-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name DisableSearchBoxSuggestions -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -ErrorAction SilentlyContinue).DisableSearchBoxSuggestions
   ```

   - 何も出なければよい（値が無い）

1. Edge のショートカットを消すポリシーを外す。

   ```powershell
   Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate' -Name RemoveDesktopShortcutDefault -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate' -ErrorAction SilentlyContinue).RemoveDesktopShortcutDefault
   ```

   - 何も出なければよい
   - 消したショートカットは戻らない（要れば、スタートメニューの Edge を右クリックして作る）

1. WSL も外すときだけ、WSL のパッケージと仮想マシン プラットフォームを外す。

   ```powershell
   wsl.exe --uninstall
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
   ```

   - `Disable-WindowsOptionalFeature` の結果に `RestartNeeded : True` が出る（[再起動と PSWindowsUpdate](#再起動と-pswindowsupdate)の手順 1 で再起動する）
   - ほかのディストリビューションを使っているなら、この手順は行わない
   - メモリ整合性などで、Hyper-V は動き続けることがある（VirtualBox は Hyper-V の上のまま）

1. [サインイン・検索・キーボード](../windows-setup.md#サインイン検索キーボード)の手順 7 を行ったときだけ、キーボードの種類を JIS 配列に戻す。

   ```powershell
   $k = 'HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters'
   Set-ItemProperty -Path $k -Name 'LayerDriver JPN' -Type String -Value 'kbd106.dll'
   Set-ItemProperty -Path $k -Name OverrideKeyboardIdentifier -Type String -Value 'PCAT_106KEY'
   Set-ItemProperty -Path $k -Name OverrideKeyboardType -Type DWord -Value 7
   Set-ItemProperty -Path $k -Name OverrideKeyboardSubtype -Type DWord -Value 2
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-ItemProperty -Path $k | Format-List 'LayerDriver JPN', OverrideKeyboardIdentifier, OverrideKeyboardType, OverrideKeyboardSubtype
   ```

   - `kbd106.dll`・`PCAT_106KEY`・`7`・`2` が出ればよい
   - [PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 3 の `Keyboard` が `kbd106.dll` でなかったなら、その値に直してから貼る

1. [サインイン・検索・キーボード](../windows-setup.md#サインイン検索キーボード)の手順 6 を行ったときだけ、時計の扱いを地方時に戻す。

   ```powershell
   Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name RealTimeIsUniversal -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation').RealTimeIsUniversal
   ```

   - 何も出なければよい。再起動の後に、時刻を同期し直す

1. Caps Lock を戻すときだけ、Scancode Map を消す。

   ```powershell
   & {
     $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
     $want = '00 00 00 00 00 00 00 00 02 00 00 00 1D 00 3A 00 00 00 00 00'
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない（「サインイン・検索・キーボードを戻す」の手順 1 から）'; return }
     $now = (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue).'Scancode Map'
     $nowHex = if ($now) { ($now | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' } else { '' }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     if (-not $nowHex) { 'Scancode Map は無い'; return }
     if ($nowHex -ne $want) { Write-Error "中断: 本書の値ではない Scancode Map がある（$nowHex）"; return }
     Remove-ItemProperty -Path $key -Name 'Scancode Map'
     'Scancode Map を消した'
   }
   ```

   - `Scancode Map を消した` が出ればよい
   - `中断:` が出たら、本書の後でほかの割り当てを足している。消さずに止めている

### ネットワークと PC 全体の設定を戻す

1. 配信の最適化を元に戻す（`OLD_DOWNLOAD_MODE` は必ず値を入れる）。

   ```powershell
   $OLD_DOWNLOAD_MODE = ''   # 「PC 全体の設定」の手順 3 で控えたモード（Internet・Lan・CdnOnly）
   ```

   ```powershell
   if ($OLD_DOWNLOAD_MODE -notin 'Internet', 'Lan', 'CdnOnly') {
     Write-Error '中断: $OLD_DOWNLOAD_MODE に「PC 全体の設定」の手順 3 で控えた Internet・Lan・CdnOnly のいずれかを入れる'
   } else {
     Set-DODownloadMode -DownloadMode $OLD_DOWNLOAD_MODE -ErrorAction Stop
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-DODownloadMode
   }
   ```

   - [PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 3 で控えたモードが出ればよい
   - `Lan`（既定）だったなら、この手順は飛ばしてよい。`CdnOnly` なら、ほかの PC と共有しない設定に戻る
   - 元の値を控えていない場合や、上の 3 つ以外だった場合は、推測で値を選ばず、管理元の設定を確かめる

1. ping に応える規則を消す。

   ```powershell
   Remove-NetFirewallRule -Group 'Ping (setup-notes)' -ErrorAction SilentlyContinue
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Group 'Ping (setup-notes)' -ErrorAction SilentlyContinue
   ```

   - 何も出なければよい

1. [PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 3 で `RemoteAssistance` が `1` だったときだけ、システムのプロパティでリモート アシスタンスを戻す。

   ```powershell
   SystemPropertiesRemote.exe
   ```

   - システムのプロパティの「リモート」タブが開く。「このコンピューターへのリモート アシスタンス接続を許可する」にチェックを入れて「OK」を押す
   - 「OK」を押すと窓が閉じ、`fAllowToGetHelp` が 1 になり、リモート アシスタンスの規則（パブリック向けも含む 15 個）がまとめて有効になる
   - **次の手順は、システムのプロパティを閉じてから貼る**

1. [PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 3 で `RemoteDesktop` が `1`（無効）だったときだけ、リモート デスクトップを無効に戻す。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Type DWord -Value 1
   Set-NetFirewallRule -Group '@FirewallAPI.dll,-28752' -Enabled False -Profile Any
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   Get-NetFirewallRule -Group '@FirewallAPI.dll,-28752' | Format-Table Name, Enabled, Profile
   ```

   - 規則が `False  Any` で並べばよい
   - **注意**: リモート デスクトップでつないでいるときに貼ると、その場で切れる
   - [RDP をロックせずに切断（Windows）](../windows-setup.md#rdp-をロックせずに切断)を使っているなら、この手順は飛ばす

1. LAN の接続をパブリックに戻すときだけ、パブリックにする。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '「サインイン・検索・キーボードを戻す」の手順 2 の $LAN_IF が空'
   } else {
     Set-NetConnectionProfile -InterfaceAlias $LAN_IF -NetworkCategory Public
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetConnectionProfile -InterfaceAlias $LAN_IF | Format-Table InterfaceAlias, NetworkCategory
   }
   ```

   - `<LAN_IF>  Public` が出ればよい
   - [PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 3 で `LanCategory` が `Private` だったなら（もとからプライベート）、この手順は飛ばす
   - [OpenSSH サーバー](../windows-setup.md#openssh-サーバー)・[Syncthing の Windows 11 で使う](../syncthing.md#windows-11-で-syncthing-を使う)・リモート デスクトップをこの LAN で使っているなら、この手順は飛ばす（パブリックにすると届かなくなる）

1. アダプターを、電力の節約のために止められるように戻す。

   ```powershell
   if (-not $LAN_IF) {
     Write-Error '「サインイン・検索・キーボードを戻す」の手順 2 の $LAN_IF が空'
   } else {
     $pm = Get-NetAdapterPowerManagement -Name $LAN_IF
     if ($pm.AllowComputerToTurnOffDevice -ne 'Unsupported') {
       $pm.AllowComputerToTurnOffDevice = 'Enabled'
       $pm | Set-NetAdapterPowerManagement -NoRestart
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Get-NetAdapterPowerManagement -Name $LAN_IF | Format-List Name, AllowComputerToTurnOffDevice
   }
   ```

   - `AllowComputerToTurnOffDevice : Enabled` が出ればよい（このアダプターに設定が無ければ `Unsupported` のまま）
   - 効くのは、[再起動と PSWindowsUpdate](#再起動と-pswindowsupdate)の手順 1 の再起動の後

1. 電源の設定を既定に戻し、休止状態を戻し、放置したときのロックを戻す。

   ```powershell
   powercfg /restoredefaultschemes
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   powercfg /hibernate on
   Remove-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name DelayLockInterval -ErrorAction SilentlyContinue
   'HibernateEnabled: {0}' -f (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power').HibernateEnabled
   ```

   - `HibernateEnabled: 1` が出ればよい
   - ファームウェアが休止状態に対応しない PC（VM など）では、`システム ファームウェアは休止状態をサポートしていません。` の旨が出て `HibernateEnabled: 0` のまま（もとから休止状態は使えない）
   - **注意**: `/restoredefaultschemes` は、電源プランをすべて既定に戻す（本書の外で変えた電源の設定も消える）

1. 長いパス・開発者モード・sudo を切る。

   ```powershell
   Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -Type DWord -Value 0
   Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name AllowDevelopmentWithoutDevLicense -Type DWord -Value 0
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (Get-Command sudo -ErrorAction SilentlyContinue) { sudo config --enable disable }
   Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' | Format-List LongPathsEnabled
   Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' | Format-List AllowDevelopmentWithoutDevLicense
   ```

   - `LongPathsEnabled : 0` と `AllowDevelopmentWithoutDevLicense : 0` が出ればよい
   - sudo は、無効になった旨の行を出す（日本語の Windows では `このコンピューターでは sudo が無効化されています。`）

1. PC の名前を戻すときだけ、元の名前にする（`OLD_PC_NAME` は必ず値を入れる）。

   ```powershell
   $OLD_PC_NAME = ''   # 「PC 全体の設定」の手順 3 で控えた元の名前。<HOSTNAME>
   ```

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   if (-not $OLD_PC_NAME) {
     Write-Error '中断: $OLD_PC_NAME が空'
   } elseif ($OLD_PC_NAME -notmatch '^[A-Za-z0-9]([A-Za-z0-9-]{0,13}[A-Za-z0-9])?$' -or $OLD_PC_NAME -match '^[0-9]+$') {
     Write-Error "中断: 使えない名前（15 文字まで。英字・数字・ハイフンで、先頭と末尾は英数字。数字だけは不可）: $OLD_PC_NAME"
   } elseif ($OLD_PC_NAME -eq $env:COMPUTERNAME) {
     "すでにこの名前: $OLD_PC_NAME"
   } else {
     Rename-Computer -NewName $OLD_PC_NAME
     "再起動の後に $OLD_PC_NAME になる"
   }
   ```

   - `再起動の後に <HOSTNAME> になる` が出ればよい
   - 効くのは、[再起動と PSWindowsUpdate](#再起動と-pswindowsupdate)の手順 1 の再起動の後

### 再起動と PSWindowsUpdate

1. 再起動する。

   ```powershell
   Restart-Computer
   ```

   - [サインイン・検索・キーボードを戻す](#サインイン検索キーボードを戻す)の手順 3〜11 と[ネットワークと PC 全体の設定を戻す](#ネットワークと-pc-全体の設定を戻す)の手順 1〜9 の多くは、再起動の後に効く（[表示と入力を戻す](#表示と入力を戻す)の手順 1〜9 だけなら、サインインし直すだけでよい）
   - **次の手順は、起動してサインインしてから行う**

1. 元に戻ったことを確かめる。

   - Caps Lock を押すとランプが点き、大文字になる（[サインイン・検索・キーボードを戻す](#サインイン検索キーボードを戻す)の手順 11 を行ったとき）
   - 右クリックで新しい形のメニューが出る（[表示と入力を戻す](#表示と入力を戻す)の手順 2 を行ったとき）
   - エクスプローラー・タスクバー・スタートが既定の見た目に戻る（[表示と入力を戻す](#表示と入力を戻す)の手順 1・3〜5 を行ったとき）

1. PSWindowsUpdate を外すときだけ、管理者ではない Windows PowerShell を開く。

   - PSWindowsUpdate を読み込んだ窓を閉じてから、[Microsoft Store の更新](../windows-setup.md#microsoft-store-の更新)の手順 1 と同じ方法で新しい窓を開く
   - [Windows Update](../windows-setup.md#windows-update)の手順 3 で初めて入れたモジュールが不要になった場合だけ、この項の手順 4 へ。もとから入っていた場合は消さない
   - [アプリと貼り付けの設定を外す](#アプリと貼り付けの設定を外す)の手順 6 で貼り付けの設定も外した場合は、Ctrl+V で貼る

1. この文書で初めて入れた PSWindowsUpdate が不要なときだけ、外す。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
       throw '中断: 「再起動と PSWindowsUpdate」の手順 3 で管理者ではない窓を開く'
     }
     if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Unrestricted', 'Bypass') {
       Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
     }
     Uninstall-Module -Name PSWindowsUpdate -AllVersions -Force
     if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
       throw '中断: PSWindowsUpdate が残っている。元からあった別の場所のものは消さない'
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     'PSWindowsUpdate を外した'
   }
   ```

   - `PSWindowsUpdate を外した` が出ればよい
   - 今の窓だけ実行ポリシーを変えた場合は、窓を閉じれば戻る
   - NuGet のプロバイダーと、既に適用した Windows の更新は残す

---

## SSH の降格用の実行ファイルを外す

- [SSH で管理者・非管理者の PowerShell を使う](../windows-setup.md#ssh-で管理者非管理者の-powershell-を使う)の手順 8 で配置した実行ファイルを、同じ Windows ユーザーで外す
- 非管理者の子 PowerShell を `exit` で閉じてから行う。**専用の場所に別のファイルがある場合は削除せず止まる**

1. 降格用の実行ファイルが不要なときだけ、SHA-256 を照合して外す。

   ```powershell
   & {
     $ErrorActionPreference = 'Stop'
     $exe = Join-Path $env:LOCALAPPDATA 'setup-notes\bin\busybox.exe'
     if (Test-Path -LiteralPath $exe) {
       if ((Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash -ne '07bb1e5b095b00d68a695481f9240879f33c5724b40aa2308f999d54ed78f075') { throw '中断: 別のファイルなので削除しない' }
       Remove-Item -LiteralPath $exe
     }
     "`n$([char]27)[7m 確認 $([char]27)[0m"
     Test-Path -LiteralPath $exe
   }
   ```

   - `False` が出ればよい
   - PowerShell の統合は起動コマンドで読むものなので、通常のプロファイルから削除する行は無い

---

## 注意点

- **Windows Sandbox の窓を閉じると、内部の状態が消える**: Sandbox の内部だけに置いたファイルと、インストールしたアプリは破棄される。Windows 11 22H2 以降では、Sandbox の中で Windows を再起動しただけなら状態は残る
- **Sandbox から共有したホストのファイルは残る**: ホストへコピーした結果や、`.wsb` の `MappedFolders` で共有したホスト側のファイルは、Sandbox の窓を閉じても消えない。書き込みを許可した共有フォルダーへの変更もホスト側に残る

- **重ねると、触れる人がそのまま使える PC になる**: 放置でロックしない（[PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 7）・自動サインイン（[WSL の AlmaLinux 10 と自動サインイン](../windows-setup.md#wsl-の-almalinux-10-と自動サインイン)の手順 5）は、PC の前にいる人をこのユーザー（Administrators の一員）として通す。インラインの sudo（[PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 6）・リモート デスクトップ（[ネットワークとリモート](../windows-setup.md#ネットワークとリモート)の手順 4）・Windows Hello 以外のサインイン（[サインイン・検索・キーボード](../windows-setup.md#サインイン検索キーボード)の手順 2）は、このユーザーのパスワードを知る人の入口を増やす。人が触れる場所にある PC では、[PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 7 と[WSL の AlmaLinux 10 と自動サインイン](../windows-setup.md#wsl-の-almalinux-10-と自動サインイン)の手順 5 は行わない
- **Caps Lock の働きは無くなる**: Caps Lock を左 Ctrl にするだけで、Caps Lock をほかのキーに割り当てない。大文字を続けて打つときは Shift を押す
- **Scancode Map は、すべてのユーザー・すべてのキーボードにかかる**: PC 全体の設定。この PC にサインインするほかのユーザーと、つないだ外付けのキーボードにもかかる
- **JIS 配列では「英数」のキーが Ctrl になる**: 日本語の配列のキーボードの Caps Lock は「英数」のキー（スキャン コード `0x3A`）なので、そのキーの IME の働き（英数への切り替え）も無くなるはず
- **リモート デスクトップと Scancode Map**: Microsoft の文書は、Scancode Map がターミナル サービスでは正しく働かないことがあると書いている
- **Ctrl+Space はアプリでは使えなくなる**: IME が受け取るので、PowerShell（PSReadLine の `MenuComplete`）・VS Code・Excel などの Ctrl+Space は効かなくなるはず（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-setup.md)・[参考資料](../reference/windows-setup.md)）
  - PowerShell 7 では、`MenuComplete` を Tab に割り当てられる（[PowerShell 7 のプロファイルを設定する](../shell-terminal.md#powershell-7-のプロファイルを設定する)の手順 3）
- **管理者の PowerShell は conhost の窓で開く**: 既定の端末を Windows Terminal にしても（[表示と入力](../windows-setup.md#表示と入力)の手順 7）、管理者として開いた PowerShell は conhost の窓になる。右クリックで貼れるのは、[貼り付けの設定](../windows-setup.md#貼り付けの設定)の手順 1〜5 のプロファイルの設定による
- **外したアプリと提案は、機能の更新で戻ることがある**: 自分のユーザーから外したアプリ（[自動起動と標準アプリ](../windows-setup.md#自動起動と標準アプリ)の手順 3・4）は、PC に置かれた元が残るので、Windows の大きな更新の後に戻ってくることがある。[表示と入力](../windows-setup.md#表示と入力)の手順 4 と[自動起動と標準アプリ](../windows-setup.md#自動起動と標準アプリ)の手順 1〜4 を貼り直す
- **サポート外の設定**: 旧形式のコンテキストメニュー（[表示と入力](../windows-setup.md#表示と入力)の手順 3）は Microsoft が説明していない設定で、Windows の更新で効かなくなることがある。そのときは、[貼り付けの設定](../windows-setup.md#貼り付けの設定)の手順 3 の `ClassicMenu` と[表示と入力](../windows-setup.md#表示と入力)の手順 3 の `reg.exe query` で、設定が残っているかを見る。[表示と入力](../windows-setup.md#表示と入力)の手順 2・4 と[自動起動と標準アプリ](../windows-setup.md#自動起動と標準アプリ)の手順 2 の値の多くも、Microsoft の文書には値が書かれておらず、広く使われているもの
- **SSH のセッションで scoop のツールを使うとき**: sshd の緩和策（RedirectionGuard）で、一般ユーザーの scoop が作るジャンクションをたどれない。[scoop のツールを SSH のセッションで使う](../windows-setup.md#scoop-のツールを-ssh-のセッションで使う)を、`scoop install`・`scoop update` の後に貼る
  - 非管理者の SSH の PowerShell は、[SSH で管理者・非管理者の PowerShell を使う](../windows-setup.md#ssh-で管理者非管理者の-powershell-を使う)の `drop` で開く。デスクトップでの導入や GUI 操作を検証した手順を、SSH でも通したとは扱わない
- **SSH の PowerShell の貼り付けを取り消すとき**: 正しいヘッダーの受信前は、Ctrl+C を押しても開始から 5 秒の期限を延ばさない。本文受信の開始後は、Ctrl+C で本文を挿入せず末尾まで読み捨てる。その後に配送が止まると受信待ちが続くことがあるので、そこでコマンドを貼り足さず SSH を接続し直す
  - 本文の上限は UTF-8 で 64 KiB（65,536 バイト）。大きなブロックは分け、受信中は次のコマンドを貼り足さない
- **PowerShell 7 で scoop を使うとき**: 実行ポリシーは Windows PowerShell 5.1 とは別に持つ。UniGet UI は、PowerShell 7 があればそれで scoop を動かす（`-ExecutionPolicy Bypass` 付き）
- **PowerShell 7 のプロファイルは別**: [貼り付けの設定](../windows-setup.md#貼り付けの設定)の手順 5 の行は Windows PowerShell 5.1 のプロファイルにだけ書く。PowerShell 7（[アプリを入れる](../windows-setup.md#アプリを入れる)の手順 6）は `Documents\PowerShell\Microsoft.PowerShell_profile.ps1` を読む。この文書の手順書群は、Windows PowerShell 5.1 に貼る
  - 同じ貼り付けの設定を PowerShell 7 にも足すなら、[PowerShell 7 のプロファイルを設定する](../shell-terminal.md#powershell-7-のプロファイルを設定する)
- **scoop のアプリは自分のユーザーだけ**: `~\scoop` に入るので、ほかのユーザーには見えない。scoop の `--global` は管理者が要り、本書では使わない
- **貼ったブロックは、Enter を押すまで動かない**: コピーボタンの中身は末尾に改行が無いため。[貼り付けの設定](../windows-setup.md#貼り付けの設定)の手順 1〜5 の後の conhost の窓では、ブロック全体が 1 つの入力になり、Enter で 1 回で動く
- **Ctrl+Enter で上に行を作る操作（`InsertLineAbove`）は使えなくなる**: 下に行を作る Shift+Ctrl+Enter（`InsertLineBelow`）と、Shift+Enter（`AddLine`）はそのまま
- **このユーザーの Windows PowerShell のコンソールの窓すべてに効く**: 管理者の窓も同じプロファイルを読む
- **ほかの項にもサポート外の設定がある**: ギャラリーとホームを消す値（[表示・入力・音・ストレージを控えて変える](../windows-setup.md#表示入力音ストレージを控えて変える)の手順 6）は、[表示と入力](../windows-setup.md#表示と入力)の手順 3 と同じく Microsoft が説明していない方法で、更新で効かなくなることがある。任意節のほかの値の多くも、Microsoft の文書には無く、広く使われているもの
- **Edge に「組織によって管理」と出る**: [Edge の常駐をポリシーで止める](../windows-setup.md#edge-の常駐をポリシーで止める)の手順 2 のポリシーで出る。消すには、その節の手順 5 で 2 つの値を消す（ほかの Edge のポリシーが無ければ消えるはず。[サインイン・検索・キーボード](../windows-setup.md#サインイン検索キーボード)の手順 4 の `EdgeUpdate` だけで出るかも含め、確かめていない）
- **ストレージ センサーはファイルを消す**: [表示・入力・音・ストレージを控えて変える](../windows-setup.md#表示入力音ストレージを控えて変える)の手順 11 は、ごみ箱に 30 日を超えて置いたファイルと一時ファイルを毎月消す（取り戻せない）。OneDrive のファイルは、[表示・入力・音・ストレージを控えて変える](../windows-setup.md#表示入力音ストレージを控えて変える)の手順 12 で外さないと、オンラインだけにされうる
- **CopyQ の履歴は暗号化されない**: [CopyQ を使う](../windows-setup.md#copyq-を使う)の CopyQ は、コピーしたものを平文でディスク（`%APPDATA%\copyq` など）に残す。除外の印を付けないアプリでコピーしたパスワードも残る。要らない項目は CopyQ の窓で消す
- **WSL をミラーにすると、WSL から Windows には `127.0.0.1` でつなぐ**: [WSL のネットワークをミラーにする](../windows-setup.md#wsl-のネットワークをミラーにする)の後は、WSL から Windows の sshd などに LAN の IP あてではつながらないはず
  - Windows が使っているポート（sshd の 22 番など）は、WSL の中のサーバーで使えない
- **移したツールの OS に依らない注意は、[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)**: Git・Firefox・git-delta・lazygit・GitHub CLI・yazi のもの。Neovim の注意は、両 OS とも [Neovim のセットアップの注意点](neovim.md#注意点) に、HackGen Console NF・WezTerm・Windows Terminal・シェルのツールの注意は、両 OS とも [シェルと端末のセットアップの注意点](shell-terminal.md#注意点) にある。ここには Windows 11 だけの注意を書く
- **OpenSSH サーバー: SSH のセッションは管理者の権限を持つ**
  - Administrators の一員でログインすると、`whoami /groups` で `Mandatory Label\High Mandatory Level` と、有効な `BUILTIN\Administrators` を確認する
  - このユーザーのパスワードを知る人と、登録した鍵を持つ人は、この PC の管理者として操作できる。パスワードと秘密鍵の扱いは、管理者のパスワードと同じにする
- **OpenSSH サーバー: パスワードでのログイン**
  - ユーザー名は、Microsoft アカウントでもメールアドレスではなく、`C:\Users\` の下のフォルダーの名前（[「OpenSSH サーバー」の手順 7](../windows-setup.md#openssh-サーバー)）。パスワードは、そのアカウントのパスワード（PIN ではない）
  - Microsoft アカウントのパスワードが sshd のログにエラー 1326 を残して拒否される場合は、Windows Hello 限定の設定をオフにして sshd を再起動する
  - [「サインイン・検索・キーボード」の手順 2](../windows-setup.md#サインイン検索キーボード) で、この設定はオフになっている
- **OpenSSH サーバー: パスワードを続けて間違えたとき**
  - SSH のパスワードの失敗もロックアウトの対象になる。`net accounts` でポリシーを確認し、パスワードを続けて試さない
  - ロック中は、正しいパスワードでも入れない。ロックアウトのポリシーで決まる時間を待ってから再接続する
- **OpenSSH サーバー: 鍵で入ったセッションは、ユーザーの資格情報を持たない**（Microsoft の文書）。セッションの中から、そのユーザーとしてほかのサーバーの共有などへ認証できない
- **OpenSSH サーバー: 標準ユーザーでログインするとき**
  - パスワードの認証を有効にすると、Administrators の一員でないユーザーも、パスワードがあれば SSH で入れる
  - 標準ユーザーのセッションは `Medium Mandatory Level` で、管理者の権限を持たない
  - 標準ユーザーの鍵は `C:\Users\<ユーザー>\.ssh\authorized_keys` に置く（Microsoft の文書）。[OpenSSH サーバーに公開鍵でもログインする](../windows-setup.md#openssh-サーバーに公開鍵でもログインする)の手順 6 は、Administrators の一員でなければ止まる
- **OpenSSH サーバー: LAN の外のサブネットからの接続**
  - 規則の接続元は `Any` で、プロファイルは接続を受けた LAN で決まる。LAN を通って届く接続なら、送信元が別のサブネットでも受け付ける
- **OpenSSH サーバー: WSL から、この PC につなぐとき**
  - WSL のネットワークが既定（NAT）なら、この PC の LAN の IP（`<WIN_HOST>`）あてにつなぐ
  - ミラーにした PC（[WSL のネットワークをミラーにする](../windows-setup.md#wsl-のネットワークをミラーにする)）では、`127.0.0.1` あてにつなぐ。LAN の IP あてはつながらず、sshd のログの送信元も `127.0.0.1` になるはず（`127.0.0.1` で届くことも含め、確かめていない）
- **OpenSSH サーバー: Git の ssh が先に見つかる PC**: `PATH` の順で、Windows の `ssh`・`ssh-keygen` ではなく Git のものが動く。Windows の OpenSSH のものは `C:\Windows\System32\OpenSSH\` から呼ぶ（[「OpenSSH サーバー」の手順 7](../windows-setup.md#openssh-サーバー)）
- **OpenSSH サーバー: SSH のセッションでは、一般ユーザーが作ったジャンクションをたどれない**
  - sshd に掛けてある RedirectionGuard を、セッションのプロセスが引き継ぐため。開こうとすると、エラー 448（`ERROR_UNTRUSTED_MOUNT_POINT`）になる
  - ローカルのシェルは、昇格していても RedirectionGuard が掛かっておらず、影響を受けない
  - scoop のジャンクションは、[scoop のツールを SSH のセッションで使う](../windows-setup.md#scoop-のツールを-ssh-のセッションで使う)で、管理者で作り直す
- **OpenSSH サーバー: 設定を変えたとき**: `sshd_config` を変えたら `Restart-Service sshd`（[「OpenSSH サーバー」の手順 6](../windows-setup.md#openssh-サーバー)）。レジストリの `DefaultShell` は、次のログインから使われる
- **OpenSSH サーバー: 機能を外したとき**
  - Microsoft の文書は、使っている間に外したなら Windows を再起動するよう書いている
- **OpenSSH サーバー: ログ**: イベント ビューアーの「OpenSSH」→「Operational」
- **Git: Windows の PowerShell や cmd から呼ぶ git** も、同じ `global`（`C:/Users/<WIN_USER>/.gitconfig`）を読む
  - Windows 11 の PC で、Git Bash・PowerShell・cmd の `git config --global --list --show-origin` が同じファイルを示した
- **Git: Git for Windows を上げるときは、Git の bash を使うものを閉じる**
  - Git Bash の窓、WezTerm のタブ（自分用の設定では Git Bash）、既定のシェルを Git Bash にした SSH のセッション、Claude Code の Bash のツール（Remote Control のタスクも）など。動いていると、winget で上げてもインストーラが入れ替えずに終わるはず（[Git for Windows・Firefox・WezTerm を上げる](../windows-setup.md#git-for-windowsfirefoxwezterm-を上げる)の[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md#統合前の記録-gitもとは-gitmd)・[参考資料](../reference/almalinux-setup.md#統合前の参考資料-gitもとは-gitmd)）
- **Git: Git for Windows 2.56.0 から、内部のパスが `mingw64` から `ucrt64` に変わった**（上流のリリースノート）
  - `C:\Program Files\Git\mingw64\bin\git.exe` を直接指す設定は、上げた後に見直す
- **git-delta: Windows 11 の PowerShell と cmd で打つ git も、delta を通る**: `~/.gitconfig` は Git Bash と同じファイル
  - PowerShell の `git`（`C:\Program Files\Git\cmd\git.exe`）は、Git の `usr\bin` を PATH の先頭に足してから git を動かすので、delta は Git Bash と同じ Git for Windows の less をページャに使う（ソースを読んだだけ。[参考資料](../reference/windows-setup.md#git-delta-windows-11-で使う--手順-5-補足-ページャの-less-と-powershell-の-git)）
  - そのため、scoop の less は入れていない。PowerShell で delta を直に動かす（`git diff | delta` など）ときは、PATH に less が無いので、ページャを使わずに出る
- **git-delta: Windows 11 の SSH のセッションでは、そのままでは scoop の delta が起動しないことがある**: sshd は、一般ユーザーが作った scoop の `current` のジャンクションをたどらせない（scoop の shim が `Could not create process with command …` で失敗する）
  - SSH で git を使うなら、[scoop のツールを SSH のセッションで使う](../windows-setup.md#scoop-のツールを-ssh-のセッションで使う)を通す（`scoop install`・`scoop update` の後は貼り直す）
- **GitHub CLI: Windows 11 のトークンの置き場所**: 資格情報マネージャー（Windows 資格情報の汎用資格情報）を優先し、使えない場合は `%APPDATA%\GitHub CLI\hosts.yml` に平文で保存する
- **GitHub CLI: Windows 11 では、gh と git が別々に GitHub にログインする**: git の HTTPS は、Git for Windows の Git Credential Manager が自分のサインインで行う
  - [「GitHub CLI」の手順 4](../windows-setup.md#github-cli)で、Git の認証に `n` と答えるため
  - `gh auth logout`・GitHub CLI の認可の取り消し・gh を消すことは、git の HTTPS の認証に影響しない
- **lazygit: Windows 11 では、winget の lazygit（`JesseDuffield.lazygit`）と両方入れない**: どちらが使われるかが `PATH` の順で決まり、分かりにくくなる。どちらか一方にする
- **lazygit: Windows 11 の SSH のセッションでは、そのままでは scoop の lazygit が起動しないことがある**: [scoop のツールを SSH のセッションで使う](../windows-setup.md#scoop-のツールを-ssh-のセッションで使う)を通す（`scoop install`・`scoop update` の後は貼り直す）
- **yazi: Windows 11 では、`file` を `YAZI_FILE_ONE` で渡す**: 無いと PowerShell から起動した yazi はファイルの種類が分からず、開く・プレビューの規則が効かない（[「yazi」の手順 5](../windows-setup.md#yazi)）。Git for Windows を外すと、同じことになる
  - PowerShell の `PATH` には `file` が無い（Git Bash には `/usr/bin/file` がある）
- **yazi: Windows 11 の画像プレビューは、端末と ConPTY に依存する**: WezTerm（nightly）か Windows Terminal（1.22.10352.0 以降）で出る。ConPTY の制約で、Linux と同じには出ないことがある
- **yazi: Windows 11 の SSH のセッションでは、そのままでは scoop の yazi が起動しないことがある**: [scoop のツールを SSH のセッションで使う](../windows-setup.md#scoop-のツールを-ssh-のセッションで使う)を通す（`scoop install`・`scoop update` の後は貼り直す）
- **Firefox: AAC と H.264 のために足すものは無い**: Windows の Media Foundation で復号する（[「Firefox」の手順 4](../windows-setup.md#firefox)の補足）。N エディションの Windows では、Media Feature Pack が要るはず
- **Firefox: 管理者の PowerShell から Firefox を起動しない**: Firefox が管理者の権限で動き、プロファイルに管理者の持ち物のファイルができうる。起動はスタートメニューから
- **Firefox: 言語パックを足さない**: 閉じている間の更新（Background Update）が止まる。別の言語にしたいなら、その言語の `Mozilla.Firefox.<言語>` を入れ直す
- **Firefox: Firefox を開いたまま `winget upgrade` しない**: 入れ替えが途中で終わることがある（[Git for Windows・Firefox・WezTerm を上げる](../windows-setup.md#git-for-windowsfirefoxwezterm-を上げる)の手順 5 の補足）
- **Firefox: 英語版の `Mozilla.Firefox` と同じ `ProductCode`**: winget の定義では、`Mozilla.Firefox` と言語ごとの `Mozilla.Firefox.<言語>` の `ProductCode` が同じ。言語を指定して更新する
- **Firefox: アンインストールで窓が出る**: `winget uninstall` でも、Firefox のアンインストーラが画面を出す（[OpenSSH・Git for Windows・Firefox・WezTerm を外す](#opensshgit-for-windowsfirefoxwezterm-を外す)の手順 5 の補足）
