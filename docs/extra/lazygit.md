# lazygit 最新版インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は scoop）のロールバックと注意点

[手順書](../lazygit.md)・[検証記録](../verification/lazygit.md)・[参考資料](../reference/lazygit.md)

- 「手順 N」は[手順書](../lazygit.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)

1. brew で lazygit を消す。

   ```bash
   brew uninstall lazygit
   ```

   - `~/.config/lazygit/` と `~/.local/state/lazygit/` は残るので、要らなければ手で消す
   - 自分用の設定を clone していれば、その clone（README の例では `~/lazygit-config`）も残る

---

## Windows 11 のロールバック

- この節の手順 1 は、管理者ではない Windows PowerShell（5.1）に、lazygit をすべて閉じてから貼る
- `%LOCALAPPDATA%\lazygit`（設定と状態ファイル `state.yml`）は残るので、要らなければ手で消す。自分用の設定を clone していれば、その [README の「導入方法」](https://github.com/ryo-aoki-pc/lazygit#導入方法)の元に戻すブロックで、退避した設定に戻す
- extras のバケットは、ほかのアプリも使うので外さない（外すなら `scoop bucket rm extras`）
- 自分用の Neovim の設定（LazyVimStarter）は、`<leader>gg` で lazygit を使う。消すと、そのキーが使えなくなる

1. scoop で lazygit を消す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop uninstall lazygit
   Get-Command lazygit -All -ErrorAction SilentlyContinue | Format-Table Source
   ```

   - `'lazygit' was uninstalled.` が出て、最後のコマンドが何も出さなければよい
   - `'lazygit' isn't installed.` なら、もう入っていない
   - 動いている lazygit があると、消さずに止まる（閉じてから貼り直す）

---

## 注意点

- **Homebrew 全般の注意は [AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)**: PATH の先頭が Homebrew になる、`sudo lazygit` はそのままでは使えない、など
  - RPM 版と両方入れると分かりにくくなるので、どちらか一方にする
- **COPR 経路は「有効化は成功するのに入らない」**: `dnf copr enable` が通っても、メタデータが取れなければ `dnf install` は `No match for argument` になるだけで、原因は警告行にしか出ない
  - COPR を使う前に `curl -sS -o /dev/null -w '%{http_code}\n' -L <chroot の repodata/repomd.xml>` で 200 が返るか確かめると早い
- **git が要る**: lazygit は git のラッパーなので、git の設定（`user.name` / `user.email`、認証）はそのまま効く
- **設定ファイルは自分で作る**: `lazygit --print-config-dir` が返すディレクトリは、初回起動時には空のことがある
- **Windows 11 では、winget の lazygit（`JesseDuffield.lazygit`）と両方入れない**: どちらが使われるかが `PATH` の順で決まり、分かりにくくなる。どちらか一方にする
- **Windows 11 の SSH のセッションでは、そのままでは scoop の lazygit が起動しないことがある**: [windows-openssh-server.md の scoop のツールを SSH のセッションで使う（任意）](../windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)を通す（`scoop install`・`scoop update` の後は貼り直す）
