# lazygit 最新版インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- [検証記録](verification/lazygit.md)・[参考資料](reference/lazygit.md)

> [!IMPORTANT]
> - **前提**: [AlmaLinux 10 の初期設定の手順 46〜48](almalinux-setup.md#実施手順) で Homebrew を入れてあること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。Homebrew の導入・管理は一般ユーザーで行い、設定も自分のホームに書く
> - **手順 2 で Homebrew の確認が出る場合がある**。答えて導入が完了してから手順 3 を貼る
> - **手順 3 で TUI が開く**。`q` で終了してから、ほかのコマンドを貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: 設定を書く場所と、自分用の設定（`ryo-aoki-pc/lazygit`）への案内は[設定ファイル](#設定ファイル)。以後は[更新](#更新)・[ロールバック](#ロールバック)

1. 変数を設定する。

   ```bash
   LG_EDITOR=nvim                  # lazygit の e キーで開くエディタ。vim / code など。<LG_EDITOR>
   printf 'LG_EDITOR = %s\n' "${LG_EDITOR}"
   ```

   - **編集が必須の変数は無い**。`e` キーで開くエディタを変えたいときだけ書き換える
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. brew で lazygit を入れる。

   ```bash
   brew install lazygit
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. lazygit が入ったか確かめ、git リポジトリで起動してみる。

   ```bash
   lazygit --version
   brew list --versions lazygit
   command -v lazygit
   ```

   - `build source=Homebrew, version=0.65.1, os=linux, arch=arm64` のように出る
   - 次に、git リポジトリのルートに `cd` してから `lazygit` を起動して確認する（`q` で終了）
   - 初回に `Thanks for using lazygit...` の案内が出たら Enter で閉じる。ファイル・変更差分・ブランチ・コミットの一覧が出ればよい
   - **注意**: git 管理下でないディレクトリで起動すると、リポジトリを作るか聞かれる
   - **ほかのコマンドは、`q` で終了してから貼る**（続けて貼ると lazygit への操作として食われる）

---

## 設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は `~/.config/lazygit/config.yml`（`lazygit --print-config-dir` で確認できる）
- **自分用の設定**は [ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit) にある（公式の既定の全項目に、あいまい検索・Nerd Fonts のアイコン・マウス無効などの変更を載せた `config.yml`）
  - 入れ方は [README の「導入方法」](https://github.com/ryo-aoki-pc/lazygit#導入方法)。clone した `config.yml` を `~/.config/lazygit/config.yml` にリンクする
  - 何を変えたかは [設定のリポジトリの参考資料の「主な設定内容」](https://github.com/ryo-aoki-pc/lazygit/blob/custom/docs/reference/readme.md#主な設定内容)
  - アイコンに Nerd Fonts が要る（`gui.nerdFontsVersion: "3"`）。端末のフォントを HackGen Console NF（[hackgen.md](hackgen.md)）にする
  - `e` キーで開くエディタは、`EDITOR` などから自動で決まる（手順 1 の `LG_EDITOR` は使わない。[neovim.md の既定のエディタにする](neovim.md#既定のエディタにする任意)）
  - この設定を入れるなら、この節の手順 1 は貼らない（リンク先の clone したファイルを使う）
- この節の手順 1 は、設定が無いか空の通常ファイルの場合だけ作成する。既存の設定がある場合は、`os:` があればその中の `edit` を編集し、無ければ `os:` を 1 つだけ追加する
- `LG_EDITOR` に指定したエディタを先に入れる。既定の `nvim` は [Neovim](neovim.md) を通す

1. エディタだけを指定する、最小の `config.yml` を書く。

   ```bash
   if [ -z "${LG_EDITOR}" ]; then
     echo '中断: 手順 1 の LG_EDITOR が空のまま。値を入れて貼り直す' >&2
   elif ! command -v "${LG_EDITOR}" >/dev/null 2>&1; then
     echo '中断: LG_EDITOR のエディタが見つからない。導入するか値を直す' >&2
   elif [ -L ~/.config/lazygit/config.yml ] || [ -s ~/.config/lazygit/config.yml ]; then
     echo '中断: 設定がすでにある。既存の os 節へ edit を併合する' >&2
   else
     mkdir -p ~/.config/lazygit
     cat > ~/.config/lazygit/config.yml <<EOF
   os:
     edit: '${LG_EDITOR} {{filename}}'
   EOF
     lazygit --print-config-dir
   fi
   ```

   - 既定値の全体は `lazygit --config` で表示できる
   - アプリ内では `x` でキーバインド一覧が出る
   - `中断:` と出たら、何も書いていない

---

## 更新

1. brew で lazygit を更新する。

   ```bash
   brew upgrade lazygit
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - **ほかのコマンドは、Homebrew の確認が出たら答え、更新が終わってから貼る**（続けて貼ると確認の答えとして食われる）

---

## ロールバック

1. brew で lazygit を消す。

   ```bash
   brew uninstall lazygit
   ```

   - `~/.config/lazygit/` と `~/.local/state/lazygit/` は残るので、要らなければ手で消す
   - 自分用の設定を clone していれば、その clone（README の例では `~/lazygit-config`）も残る

---

## 注意点

- **Homebrew 全般の注意は [AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)**: PATH の先頭が Homebrew になる、`sudo lazygit` はそのままでは使えない、など
  - RPM 版と両方入れると分かりにくくなるので、どちらか一方にする
- **COPR 経路は「有効化は成功するのに入らない」**: `dnf copr enable` が通っても、メタデータが取れなければ `dnf install` は `No match for argument` になるだけで、原因は警告行にしか出ない
  - COPR を使う前に `curl -sS -o /dev/null -w '%{http_code}\n' -L <chroot の repodata/repomd.xml>` で 200 が返るか確かめると早い
- **git が要る**: lazygit は git のラッパーなので、git の設定（`user.name` / `user.email`、認証）はそのまま効く
- **設定ファイルは自分で作る**: `lazygit --print-config-dir` が返すディレクトリは、初回起動時には空のことがある
