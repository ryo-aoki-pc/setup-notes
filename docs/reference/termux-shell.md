# Termux のシェルの参考資料

[手順書](../android.md#termux-のシェル)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/termux-shell.md)・[注意点](../extra/termux.md)

## 選択した方針

- 共通の bash 設定を使い、道具は Termux の `pkg` で入れる。`~/.bashrc` の読み込み行は bash リポジトリの `install.sh` で管理する
- yazi は custom の設定を使う。Android のパスと、Termux の yazi のゴミ箱に合わせたキーを使う

## 補足

### Termux のシェル / 手順 1: 補足: 推奨パッケージ

- Termux の apt は、推奨パッケージ（Recommends）も入れる（`APT::Install-Recommends "1"`）
- git は openssh を推奨するので、git と一緒に OpenSSH が入る。入れただけでは sshd は起動しない

### Termux のシェル / 手順 2・3: 補足: ログインシェルの読み込み

- Termux の `$PREFIX/etc/profile` は、ログインの対話シェルで `~/.bashrc` を読む。共通設定の `install.sh` は Termux では `~/.bash_profile` を作らない
- `$PREFIX/etc/bash.bashrc` は bash-completion を読む。共通設定は、入っている starship・zoxide・fzf・eza・bat・Neovim を有効にする
- 共通の bash 設定は、Termux のときだけ `~/.local/bin` を PATH の先頭に足す（Termux はこの場所を PATH に入れない）。フォルダーが無くても足すので、後から md-format が `mdfmt` を置いても、同じシェルで使える

### Termux のシェル / 手順 5: 補足: inputrc の場所

- Termux の既定の Readline の設定は `$PREFIX/etc/inputrc` にある。`/etc/inputrc` は無いので、`~/.inputrc` から Termux のパスを読み込む
- `bind -q beginning-of-line` に `"\e[1~"` が出れば、読み込んだ Home キーの割り当てを確かめられる

### Termux のシェル / Termux のシェル: yazi を入れる / 手順 1: 補足: 推奨パッケージ

- yazi は 7zip・chafa・fd・ffmpeg・fzf・imagemagick・jq・poppler・ripgrep・zoxide を推奨する。手順書の `pkg install` に書いていない chafa と imagemagick も入る

### Termux のシェル / Termux のシェル: yazi を入れる / 手順 3〜5: 補足: Android のキーとゴミ箱

- `ya env` は端末が要る。端末の無いところでは `Inappropriate ioctl for device` になる
- custom の Android 用の行では、`gT` は `$TMPDIR`、`gd` は `~/storage/downloads`、`g/` は `$PREFIX`、`gt` は `~/.local/share/Trash/files` を開く
- Termux から `/tmp` は読めない。`TMPDIR` は Termux が渡す `$PREFIX/tmp` なので、一時ファイルにはこちらを使う
- Termux の yazi は、`d` で捨てたファイルを `~/.local/share/Trash/files` に置く（Termux の yazi のゴミ箱のパッチ）
- yazi の上流の `gt`（`plugin trash`）は Termux で使えなかった。custom の Android の行でゴミ箱の場所へ直接移る

## 参照

- [共通の bash 設定](https://github.com/ryo-aoki-pc/bash)
- [yazi の custom の設定](https://github.com/ryo-aoki-pc/yazi/tree/custom)
- [Termux のパッケージ](https://github.com/termux/termux-packages)
- [シェルと端末の手順書](../shell-terminal.md)
