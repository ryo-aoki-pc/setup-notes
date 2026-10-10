# Neovim 最新版インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は scoop）のロールバックと注意点

[手順書](../neovim.md)・[検証記録](../verification/neovim.md)・[参考資料](../reference/neovim.md)

- 「手順 N」は[手順書](../neovim.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)
- 自分用の bash 設定で Neovim を指定している場合は、先にそちらの `EDITOR`・`VISUAL`・`vi` を変更する

1. 既定のエディタの扱いを確認する。

   - 本書ではエディタ設定を `~/.bashrc` に書かないので、追記の削除は不要
   - この節の手順 2 の後に端末を開き直すと、Neovim が無ければ共通設定はエディタを変更しない
   - 別の場所にも `nvim` がある場合は引き続き使われる。個別の変更は共通設定側で行う

1. brew で Neovim を消す。

   ```bash
   brew uninstall neovim
   ```

   - 他の formula が使う依存は残る。不要になった依存は Homebrew が自動で削除する場合がある（[Homebrew の注意点](almalinux-setup.md#注意点)）。残った不要な依存を整理する操作は `brew autoremove`
   - `~/.config/nvim`、`~/.local/share/nvim`（プラグイン）、`~/.local/state/nvim`（undo・swap）は残るので、要らなければ手で消す
   - 自分用の設定（LazyVimStarter）を入れていれば、その [docs/setup.md の「ロールバック」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#ロールバック)で、退避した設定に戻す

---

## Windows 11 のロールバック

- この節で貼るブロックは、管理者ではない Windows PowerShell（5.1）に、Neovim をすべて閉じてから貼る
- 自分用の設定（LazyVimStarter）を入れていれば、先にその [docs/setup.md の「ロールバック」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/setup.md#ロールバック)の手順 5・6 を行う（設定を消して退避分を戻す）
  - その節の手順 6 は、設定のフォルダーごと消す（push していない変更は取り戻せない）。その節の手順 5 で、何も出ないことを確かめてから行う
  - その節の手順 7 は、scoop の Neovim・lazygit・zenhan をまとめて消す。lazygit を残すなら手順 7 は行わず、この節の手順 1 で Neovim だけを消す（zenhan は残る。要らなければ `scoop uninstall zenhan`）
- `%LOCALAPPDATA%\nvim`（設定）・`%LOCALAPPDATA%\nvim-data`（プラグイン・undo・ログ）・`%TEMP%\nvim-data`（キャッシュ）は残るので、要らなければ手で消す
- VC++ のランタイムは、ほかのアプリも使うので消さない

1. scoop で Neovim を消す。

   ```powershell
   "`n$([char]27)[7m 確認 $([char]27)[0m"
   scoop uninstall neovim
   Get-Command nvim -All -ErrorAction SilentlyContinue | Format-Table Source
   ```

   - `'neovim' was uninstalled.` が出て、最後のコマンドが何も出さなければよい
   - `'neovim' isn't installed.` なら、もう入っていない
   - 動いている Neovim があると、消さずに止まる（閉じてから貼り直す）

1. [既定のエディタにする（任意）](../neovim.md#既定のエディタにする任意)の手順 2 を行ったときだけ、`EDITOR`・`VISUAL` を消す。

   - [既定のエディタにする（任意）](../neovim.md#既定のエディタにする任意)の手順 3 を貼る

---

## 注意点

- **EPEL の `neovim` と両方入れない**: PATH の先頭が Homebrew なので、Homebrew 版が勝つ（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）。どちらか一方にする
- **`sudo nvim` は、そのままでは動かない**: sudo の PATH に Homebrew が無い（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）
  - [AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通すと動く。root の Neovim は `/root/.config/nvim` を読む
  - root のファイルを自分の設定で編集するなら、`sudo nvim` ではなく `sudoedit` を使う（その節を通すか、`SUDO_EDITOR` にフルパスを渡す。[既定のエディタにする](../neovim.md#既定のエディタにする任意)）
  - root のシェル（`su -`、root のログイン、`sudo -i`）で使うなら、[AlmaLinux 10 の初期設定の Homebrew を root のシェルでも使う](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節を通す（`sudo nvim` は、その節だけでは動かない）
- **プロバイダは別途**: Python / Node.js のプラグインを使うなら、それぞれ `pynvim` / `neovim` パッケージを入れる。このホストには Node.js が無い
- **設定とプラグインは更新に追従しない**: `brew upgrade neovim` でメジャー版が上がると、古い API を使うプラグインが壊れることがある
- **`vi` は RPM の `vim-minimal`**: 別物が `/usr/bin/vi` として残っている。エイリアスを張らない限り `vi` は Neovim にならない
- **Windows 11 では、winget などで入れた Neovim と両方入れない**: winget の `Neovim.Neovim` は PC 全体（`C:\Program Files\Neovim`）に入り、PC 全体の `PATH` はユーザーの `PATH` より先に引かれるので、そちらが使われる。どちらか一方にする
- **Windows 11 の SSH のセッションでは、そのままでは scoop の nvim が起動しないことがある**: [windows-openssh-server.md の scoop のツールを SSH のセッションで使う（任意）](../windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)を通す（`scoop install`・`scoop update` の後は貼り直す）
- **Windows 11 で自分用の設定（LazyVimStarter）を使うと、`:!` や `:terminal` のシェルは PowerShell になる**: `pwsh` を実行ファイルとして見つけられれば PowerShell 7、見つけられなければ Windows PowerShell 5.1。素の Neovim の既定は `cmd.exe`
  - [Windows 11 の初期設定の「アプリを入れる」の手順 5](../windows-setup.md#アプリを入れる) の PowerShell 7（MSIX）は、pwsh の中から起動した Neovim でだけ使われる（[LazyVimStarter の参考資料の「Windows の外部コマンド」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/reference/setup.md#windows-の外部コマンド)）
