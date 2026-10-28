# Neovim のセットアップ（AlmaLinux 10・Windows 11）の注意点

[手順書](../neovim.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/neovim.md)・[参考資料](../reference/neovim.md)

- 手順書の手順は、番号付きリストを持つ見出し（項）ごとに 1 から数える。「<項>の手順 N」は手順書のその項の手順を指す

## 注意点

- **GitLab プレビューに「公式スタイル未導入」と出る**: [LazyVimStarter の注意点](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/extra/setup.md#注意点)で取得先への通信と導入状態を確かめる
  - `近似表示` は Markdown をどこで描いたかを示す表示で、公式スタイルの導入状態とは別
- **Neovim: EPEL の `neovim` と両方入れない**: PATH の先頭が Homebrew なので、Homebrew 版が勝つ。どちらか一方にする
- **Neovim: `sudo nvim` は、そのままでは動かない**: sudo の PATH に Homebrew が無い
  - [Homebrew を sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う)の節を通すと動く。root の Neovim は `/root/.config/nvim` を読む
  - root のファイルを自分の設定で編集するなら、`sudo nvim` ではなく `sudoedit` を使う（その節を通すか、`SUDO_EDITOR` にフルパスを渡す。[「Neovim」の手順 4](../neovim.md#neovim)）
  - root のシェル（`su -`、root のログイン、`sudo -i`）で使うなら、[Homebrew を root のシェルでも使う](../almalinux-setup.md#homebrew-を-root-のシェルでも使う)の節を通す（`sudo nvim` は、その節だけでは動かない）
- **Neovim: プロバイダは別途**: Python / Node.js のプラグインを使うなら、それぞれ `pynvim` / `neovim` パッケージを入れる。Node.js 本体は、[「Neovim」の手順 3](../neovim.md#neovim) の自分用の設定の導入で入る
- **Neovim: 設定とプラグインは更新に追従しない**: `brew upgrade neovim` でメジャー版が上がると、古い API を使うプラグインが壊れることがある
- **Neovim: `vi` は RPM の `vim-minimal`**: 別物が `/usr/bin/vi` として残っている。エイリアスを張らない限り `vi` は Neovim にならない
- **Neovim: Windows 11 では、winget などで入れた Neovim と両方入れない**: winget の `Neovim.Neovim` は PC 全体（`C:\Program Files\Neovim`）に入り、PC 全体の `PATH` はユーザーの `PATH` より先に引かれるので、そちらが使われる。どちらか一方にする
- **Neovim: Windows 11 の SSH のセッションでは、そのままでは scoop の nvim が起動しないことがある**: [scoop のツールを SSH のセッションで使う](../windows-setup.md#scoop-のツールを-ssh-のセッションで使う)を通す（`scoop install`・`scoop update` の後は貼り直す）
- **Neovim: Windows 11 で自分用の設定（LazyVimStarter）を使うと、`:!` や `:terminal` のシェルは PowerShell になる**: `pwsh` を実行ファイルとして見つけられれば PowerShell 7、見つけられなければ Windows PowerShell 5.1。素の Neovim の既定は `cmd.exe`
  - [「アプリを入れる」の手順 6](../windows-setup.md#アプリを入れる) の PowerShell 7（MSIX）は、pwsh の中から起動した Neovim でだけ使われる（[LazyVimStarter の参考資料の「Windows の外部コマンド」](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/reference/setup.md#windows-11-で-lazyvim-の設定を導入する--手順-5-補足-windows-の外部コマンド)）
- **Neovim: treesitter のパーサーが入らない**: `Lock file '…' appears stale` が出たら、次の順で鍵を消す
  - Neovim をすべて閉じ、tree-sitter が動いていないことを確かめる
    - AlmaLinux 10 は `pgrep -a tree-sitter`、Windows 11 は `Get-Process tree-sitter -ErrorAction SilentlyContinue` が何も出さなければよい
  - 鍵は、AlmaLinux 10 は `~/.cache/tree-sitter/lock/`、Windows 11 は `%LOCALAPPDATA%\tree-sitter\lock\` にある。表示された鍵のファイルを消す
  - 手順書の手順で出たときは、その手順のブロックを貼り直す。それ以外のときは、Neovim を開き、`Language installed` が出るまで閉じない
  - Windows 11 では、`Compiling parser` が出ている間に Neovim を閉じると、同じ鍵が残ることがある
