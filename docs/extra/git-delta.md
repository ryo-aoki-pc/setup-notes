# git-delta（delta）インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は scoop）のロールバックと注意点

[手順書](../git-delta.md)・[検証記録](../verification/git-delta.md)・[参考資料](../reference/git-delta.md)

- 「手順 N」は[手順書](../git-delta.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)

1. brew で git-delta を消し、git から delta の設定を外す。

   ```bash
   brew uninstall git-delta
   git config --global --unset core.pager
   git config --global --unset interactive.diffFilter
   git config --global --remove-section delta
   ```

   - **`core.pager` を消し忘れると、`git diff` のたびに `delta: command not found` になる**

1. `zdiff3` も戻すときだけ、`merge.conflictstyle` を外す。

   ```bash
   git config --global --unset merge.conflictstyle     # zdiff3 も戻す場合
   ```

   - [git.md](../git.md) を通したなら外さない（同じ設定を使う）

1. delta の設定が消えたか確かめる。

   ```bash
   git config --global --get-regexp '^(core\.pager|interactive\.difffilter|delta\.)'   # 何も出なければ消えている
   ```

   - 何も出なければ消えている
   - lazygit の `git.diffRenderers` に delta の項目を足していた場合は、その項目も消す（ほかの renderer は残す）。以前の `git.paging` を使っていた場合は、そちらの delta 設定を外す

---

## Windows 11 のロールバック

- この節のブロックは、管理者ではない Windows PowerShell（5.1）に、上から順に貼る
- **先に git の設定から delta を外してから（この節の手順 1）、delta を消す（この節の手順 3）**。`core.pager` が delta のまま delta を消すと、`git diff` などが delta を起動できない
- [Windows 11 の初期設定のロールバックの「アプリと貼り付けの設定を外す」](windows-setup.md#アプリと貼り付けの設定を外す)の手順 4 で scoop ごと外すときも、先にこの節の手順 1 を行う（scoop を外しても `~/.gitconfig` の `core.pager` は残る）。そのときは、この節の手順 3 は要らない（delta も一緒に消える）

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

1. `zdiff3` も戻すときだけ、`merge.conflictstyle` を外す。

   ```powershell
   git config --global --unset merge.conflictstyle
   ```

   - [git.md](../git.md) を通したなら外さない（同じ設定を使う）

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
   - lazygit の `git.diffRenderers` に delta の項目があれば（[lazygit と組み合わせる（任意）](../git-delta.md#lazygit-と組み合わせる任意)で足したものと、自分用の lazygit の設定）、その項目も外す（自分用の設定は、その README の「前提ツール」のとおり `git.diffRenderers` を `[]` に戻す）

---

## 注意点

- **`core.pager` は PATH に `delta` がある文脈でしか動かない**
  - Homebrew の PATH は `~/.bashrc` の `brew shellenv` で通っているので、`~/.bashrc` を読まない文脈（cron、一部の非対話シェル、他ユーザー、`sudo -i` しない root）で `git diff` を打つと `delta: command not found` になる
  - 固くしたいなら、フルパスで指定する: `git config --global core.pager /home/linuxbrew/.linuxbrew/bin/delta`
- **表示だけを変える。差分の中身は変わらない**: `git diff > patch.diff` はページャを通らないので従来どおりのパッチが出る。`git apply` や CI の挙動には影響しない
- **`sudo git` には効かない**: root は root の `~/.gitconfig` を読むので、この設定は入っていない
- **`interactive.diffFilter` が変えるのは `git add -p` の表示だけ**: 選択の操作自体は git のまま
- **lazygit は `core.pager` を見ない**: 0.65.1 では別途 `git.diffRenderers` を設定する（[lazygit と組み合わせる（任意）](../git-delta.md#lazygit-と組み合わせる任意)）
- **Homebrew 全般の注意は [AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)**: PATH の先頭が Homebrew になる、`~/.bashrc` を読まない文脈では見えない、など
- **Windows 11 の PowerShell と cmd で打つ git も、delta を通る**: `~/.gitconfig` は Git Bash と同じファイル
  - PowerShell の `git`（`C:\Program Files\Git\cmd\git.exe`）は、Git の `usr\bin` を PATH の先頭に足してから git を動かすので、delta は Git Bash と同じ Git for Windows の less をページャに使う（ソースを読んだだけ。[参考資料](../reference/git-delta.md#windows-11-で使う--手順-5-補足-ページャの-less-と-powershell-の-git)）
  - そのため、scoop の less は入れていない。PowerShell で delta を直に動かす（`git diff | delta` など）ときは、PATH に less が無いので、ページャを使わずに出る
- **Windows 11 の SSH のセッションでは、そのままでは scoop の delta が起動しないことがある**: sshd は、一般ユーザーが作った scoop の `current` のジャンクションをたどらせない（scoop の shim が `Could not create process with command …` で失敗する）
  - SSH で git を使うなら、[windows-openssh-server.md の scoop のツールを SSH のセッションで使う（任意）](../windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)を通す（`scoop install`・`scoop update` の後は貼り直す）
