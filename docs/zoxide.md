# zoxide 最新版インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- [検証記録](verification/zoxide.md)・[参考資料](reference/zoxide.md)

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、共通設定も自分のユーザーに導入するため）

- 上から順にコードブロックを貼る
- 手順の後: 以後は[更新](#更新)・[ロールバック](#ロールバック)

1. 共通の bash 設定が導入済みか確かめる。

   ```bash
   echo "${__bash_config_loaded-読まれていない}"
   ```

   - `1` が出ればよい。未導入なら [共通設定の導入](../README.md#共通の-bash-設定を先に入れる)を行い、端末を開き直す

1. brew で zoxide と fzf を入れる。

   ```bash
   brew install zoxide fzf
   ```

   - 確認が出たら表示された導入予定を確かめて `y` と答え、処理が終わってプロンプトに戻ってから次の手順を貼る（[Homebrew の注意点](homebrew.md#注意点)）
   - `fzf` は必須ではないが、入れておくと候補から選ぶ `zi` が使える（fzf 自身のキー操作と補完を bash に組み込むのは [fzf.md](fzf.md)）
   - aarch64 でもビルド済みのボトルが降ってくる

1. 共通設定を読み直し、z と zi を確かめる。

   ```bash
   . ~/.bashrc
   type -t z zi
   ```

   - `function` が 2 行出ればよい
   - 共通設定が starship → WezTerm → zoxide の順に読む。`~/.bashrc` への追記は不要
   - コマンド名は `z`。共通の初期化方法は bash リポジトリ側で管理する

1. zoxide が入ったか確かめ、記録を試すディレクトリへ移る。

   ```bash
   zoxide --version
   command -v zoxide
   cd /usr/share
   ```

   - `command -v zoxide` は `/home/linuxbrew/.linuxbrew/bin/zoxide`
   - **注意**: 対話シェル（端末に貼る）で実行する。スクリプトの中では記録されない
   - **次の手順は、プロンプトが戻ってから貼る**（zoxide はプロンプトを出すときに今のディレクトリを記録する。ブラケットペーストで続けて貼ると、プロンプトが出る前に手順 5 が走り、`/usr/share` がまだ無い）

1. データベースに記録されたか確かめ、ホームに戻る。

   ```bash
   zoxide query --list
   cd ~
   ```

   - `/usr/share` が出れば動いている
   - 以後は `z share` のように末尾の一部を書けば `/usr/share` に飛ぶ
   - `fzf` を入れた場合は、`zi` で候補を対話的に選べる

---

## 更新

- データベース（`~/.local/share/zoxide/db.zo`）は更新で消えない

1. brew で zoxide を更新する。

   ```bash
   brew upgrade zoxide
   ```

   - すべてまとめて上げるなら `brew upgrade`

---

## ロールバック

1. brew で zoxide を消す。

   ```bash
   brew uninstall zoxide
   ```

1. 端末を閉じて開き直す。

   - 削除したツールの設定は、次のシェルでは共通設定から読み込まれない
   - `~/.bashrc` にツール別の行は書いていないので、削除も不要

1. 学習したディレクトリの履歴も捨てるときだけ、`~/.local/share/zoxide` を消す。

   ```bash
   rm -rf ~/.local/share/zoxide
   ```

   - 履歴は `~/.local/share/zoxide/db.zo` に入っている
   - **残しておけば、入れ直したときにそのまま使える**

---

## 注意点

- **初期化の 1 行が本体**: `brew install` だけでは `z` は増えない。bash の共通設定が `zoxide init bash` を読む。インストール後はシェルを開き直す
- **`--cmd cd` は影響範囲が広い**: `cd` を置き換えると、シェル関数やエイリアス経由の `cd` の挙動も変わる。既定の `z` から始めるのが無難
- **root は別に導入する**: root 自身にも bash の共通設定を導入した場合にだけ、root のシェルで初期化される（[homebrew.md の root の節](homebrew.md#root-のシェルでも使う任意)）
- **学習はプロンプトを出すたびに走る**: `PROMPT_COMMAND` にフックが入り、そのときの今のディレクトリを記録する。プロンプトを自前で組んでいる場合は順序に注意する
- **アンインストール時に行を消し忘れると毎回エラーが出る**: [ロールバック](#ロールバック)の `sed` を忘れない
- **他のツールとの連携**: yazi の `z` キーと、zoxide の対話関数 `zi`（fzf で候補を選ぶ）はこのデータベースを共有する
