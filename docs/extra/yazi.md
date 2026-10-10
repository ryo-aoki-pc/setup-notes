# yazi 最新版インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は scoop）のロールバックと注意点

[手順書](../yazi.md)・[検証記録](../verification/yazi.md)・[参考資料](../reference/yazi.md)

- 「手順 N」は[手順書](../yazi.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)

1. brew で yazi を消す。

   ```bash
   brew uninstall yazi
   ```

   - 依存ツール（`YAZI_EXTRAS` で入れたもの）は他でも使うので、消すなら個別に指定する
   - 端末を開き直すと、yazi が無ければ共通設定は `y()` を定義しない。`~/.config/yazi/` は残るので、不要な場合だけ別に消す

---

## Windows 11 のロールバック

- この節の手順 1・2 は、管理者ではない Windows PowerShell（5.1）に、yazi をすべて閉じてから貼る
- 依存ツール（`$YAZI_EXTRAS` で入れたもの）は、ほかでも使うので、消すなら個別に `scoop uninstall` する（`7zip` は scoop 自身も展開に使うので残す）
- `%APPDATA%\yazi`（`config` と `state`）と `%LOCALAPPDATA%\yazi`（キャッシュ）は残るので、要らなければ手で消す
- 自分用の設定の clone（`%APPDATA%\yazi\config`）を消すときは、次の 2 つが、どちらも何も出さないことを先に確かめる（コミットしていない変更と、push していないコミットが無い）
  - `git -C "$env:APPDATA\yazi\config" status --short`
  - `git -C "$env:APPDATA\yazi\config" log --oneline '@{u}..'`
- 自分用の設定の clone を消した後、`%APPDATA%\yazi\config.bak` があれば、名前を `config` に戻す（README の Windows の例が、元の設定をそこへ退避している）
- Git Bash の `y` は、yazi を消した後に開いたシェルでは定義されない

1. scoop で yazi を消す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop uninstall yazi
   Get-Command yazi, ya -All -ErrorAction SilentlyContinue | Format-Table Source
   ```

   - `'yazi' was uninstalled.` が出て、最後のコマンドが何も出さなければよい
   - `'yazi' isn't installed.` なら、もう入っていない
   - 動いている yazi があると、消さずに止まる（閉じてから貼り直す）

1. ユーザーの環境変数 `YAZI_FILE_ONE` を消す。

   ```powershell
   if ([Environment]::GetEnvironmentVariable('YAZI_FILE_ONE', 'User') -eq 'C:\Program Files\Git\usr\bin\file.exe') { [Environment]::SetEnvironmentVariable('YAZI_FILE_ONE', $null, 'User') }
   $env:YAZI_FILE_ONE = [Environment]::GetEnvironmentVariable('YAZI_FILE_ONE', 'User')
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   'YAZI_FILE_ONE = {0}' -f $env:YAZI_FILE_ONE
   ```

   - `YAZI_FILE_ONE = `（値が空）が出ればよい
   - 値が Git for Windows の `file.exe`（[Windows 11 で使う](../yazi.md#windows-11-で使う)の手順 5 で入れた値）のときだけ消す。ほかの値は残り、その値が出る
   - 今の窓の値も、ユーザーの値に合わせる。ほかの開いている窓には前の値が残る（開き直すと消える）
   - [Windows 11 で使う](../yazi.md#windows-11-で使う)の手順 3 で元の値を控えていたら、`[Environment]::SetEnvironmentVariable('YAZI_FILE_ONE', '<控えた値>', 'User')` を、値を入れて打って戻す

---

## 注意点

- **Homebrew 全般の注意は [AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)**: PATH の先頭が Homebrew になる（同名のコマンドは RPM 版より Homebrew 版が勝つ）、`sudo yazi` はそのままでは使えない（root で使うなら、[AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通すか、フルパスで呼ぶ）、など
  - RPM 版と両方入れると分かりにくくなるので、どちらか一方にする
- **画像プレビューは端末に依存する**: Kitty / WezTerm / foot などのグラフィックプロトコル、または Überzug++ が要る。GNOME 端末では文字ベースの表示になる
- **`q` と `Q`**: `y` 関数経由なら `q` で終了時にそのディレクトリへ移動し、`Q` なら移動しない
- **Homebrew の更新は自分の責任で**: `brew upgrade` は指定しなければ全 formula を上げる。yazi だけ上げるなら `brew upgrade yazi`
- **Windows 11 では、`file` を `YAZI_FILE_ONE` で渡す**: 無いと PowerShell から起動した yazi はファイルの種類が分からず、開く・プレビューの規則が効かない（[Windows 11 で使う](../yazi.md#windows-11-で使う)の手順 5）。Git for Windows を外すと、同じことになる
  - PowerShell の `PATH` には `file` が無い（Git Bash には `/usr/bin/file` がある）
- **Windows 11 の画像プレビューは、端末と ConPTY に依存する**: WezTerm（nightly）か Windows Terminal（1.22.10352.0 以降）で出る。ConPTY の制約で、Linux と同じには出ないことがある
- **Windows 11 の SSH のセッションでは、そのままでは scoop の yazi が起動しないことがある**: [windows-openssh-server.md の scoop のツールを SSH のセッションで使う（任意）](../windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)を通す（`scoop install`・`scoop update` の後は貼り直す）
