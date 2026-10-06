# starship インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- [検証記録](verification/starship.md)・[参考資料](reference/starship.md)

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、共通設定とツールの設定は自分のユーザーで使うため）
> - **手順 4 は、端末を開き直す操作**。手順 5 は、開き直した端末で貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: 見た目を変えるなら[プリセットを当てる（任意）](#プリセットを当てる任意)。細かい調整は[設定ファイル](#設定ファイル)
- ユーザーを切り替えても名前を出すなら[ユーザー名とホスト名を常に表示する](#ユーザー名とホスト名を常に表示する)。以後は[更新](#更新)・[ロールバック](#ロールバック)

1. 変数を設定する。

   ```bash
   STARSHIP_PRESET=plain-text-symbols        # 任意手順で当てるプリセット。<STARSHIP_PRESET>
   printf 'STARSHIP_PRESET = %s\n' "${STARSHIP_PRESET}"
   ```

   - **編集が必須の変数は無い**。既定のままなら starship の組み込みの見た目になり、設定ファイルは作られない
   - [プリセットを当てる（任意）](#プリセットを当てる任意)まで進むときだけ、`STARSHIP_PRESET` を選び直す（候補は `starship preset --list` で出る）
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. brew で starship を入れる。

   ```bash
   brew install starship
   ```

   - 確認が出たら表示された導入予定を確かめて `y` と答え、処理が終わってプロンプトに戻ってから次の手順を貼る（[Homebrew の注意点](homebrew.md#注意点)）
   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - 依存の `dbus`（とその先の `expat`）、`zlib-ng-compat` も同時に入る

1. 共通設定の初期化順を確かめる。

   ```bash
   grep -n -e 'starship init' -e 'WEZTERM_SHELL_INTEGRATION' -e 'zoxide init' ~/.config/bash/bashrc
   ```

   - starship → WezTerm → zoxide の順に出る。`~/.bashrc` の編集は不要
   - 既に開いているシェルで追加の初期化をせず、次の手順で端末を開き直す

1. 開いている端末を閉じて、開き直す。

   - プロンプトは、開き直した端末から starship に変わる
   - 今のシェルで `. ~/.bashrc` を読み直さない（starship が、そのシェルで既に読んだ WezTerm のシェル統合より後ろで初期化され、WezTerm のフックが 2 回ずつ動く）
   - [プリセットを当てる（任意）](#プリセットを当てる任意)まで進むなら、開き直した端末で手順 1 のブロックを貼り直す
   - **次の手順は、開き直した端末で貼る**

1. starship が入ったか確かめ、プロンプト文字列が生成されるか見る。

   ```bash
   starship --version
   brew list --versions starship
   command -v starship
   starship prompt
   starship module directory
   starship explain
   ```

   - `starship --version` は、`starship 1.26.0` とビルド情報を数行出す
   - `starship prompt` / `module` / `explain` で、プロンプト文字列が実際に生成されるか見る（**端末でなくても動く**）
   - `starship prompt` は、改行とカレントディレクトリとプロンプト記号を含む文字列を出す
   - `starship explain` は、今のプロンプトに出ている各部分の意味を 1 行ずつ説明する

---

## プリセットを当てる（任意）

- 公式が配っている設定一式を `~/.config/starship.toml` に書き出す

> [!WARNING]
> **この節の手順 2 で、既存の設定は上書きされる**ので、自分で書いたものがあれば先に退避する。

1. 当てられるプリセットの一覧を見る。

   ```bash
   starship preset --list
   ```

   - `plain-text-symbols` と `no-nerd-font` は**Nerd Font が無い端末向け**で、記号を ASCII に置き換える
   - `nerd-font-symbols` / `pastel-powerline` / `gruvbox-rainbow` などは Nerd Font が要る
   - 実機には `font-symbols-only-nerd-font` が入っている（[yazi.md](yazi.md) 参照）
   - 既定の `plain-text-symbols` 以外にするなら、[手順 1](#実施手順) の `STARSHIP_PRESET` を選び直して貼り直す
   - **次の手順は、使うプリセットを決めてから貼る**

1. 選んだプリセットを `~/.config/starship.toml` に書き出す。

   ```bash
   mkdir -p ~/.config
   starship preset "${STARSHIP_PRESET:?手順 1 の STARSHIP_PRESET が空のまま。値を入れて貼り直す}" -o ~/.config/starship.toml --force &&
     wc -l ~/.config/starship.toml &&
     starship prompt
   ```

   - 設定ファイルの変更だけなら `~/.bashrc` を読み直す必要はない。starship は設定ファイルをプロンプトのたびに読むので、starship を読み込んだ端末（[手順 4](#実施手順) で開き直した端末）のプロンプトは、次のプロンプトから変わる
   - `--force` は既存のファイルを置き換える。付けないと既存設定がある場合に拒否されるので、節の先頭の注意どおり先に退避する
   - 共通設定は初期化済みの starship を再初期化しない。手で `eval "$(starship init bash)"` を重ねると `PS0` が重複するため、追加で実行しない

---

## 設定ファイル

- `~/.config/starship.toml` は**既定では存在しない**（無ければ組み込みの既定値で動く）

1. `~/.config/starship.toml` に、設定を手で書く。

   ```bash
   mkdir -p ~/.config
   cat > ~/.config/starship.toml <<'EOF'
   add_newline = false

   [directory]
   truncation_length = 3
   truncate_to_repo = false
   EOF
   starship prompt
   ```

   - `starship config` で `$EDITOR` が開く
   - 設定の場所を変えたいときは、starship 自身が読む環境変数 `STARSHIP_CONFIG` を `~/.bashrc` で `export` する

---

## ユーザー名とホスト名を常に表示する

- 自分のユーザーのシェルで実行する。root の設定は別のファイルになる
- プリセットや[設定ファイル](#設定ファイル)の例を使う場合は、先に適用する

1. ユーザー名とホスト名を常に表示する設定を入れる。

   ```bash
   mkdir -p ~/.config
   starship config username.show_always true
   starship config hostname.ssh_only false
   starship module username
   starship module hostname
   ```

   - 既存の設定を保ち、常時表示に必要な 2 項目だけを更新する。設定ファイルが無ければ作られる
   - ユーザー名とホスト名が出ることを確かめる
   - 次のプロンプトから反映される。端末の開き直しや `~/.bashrc` の読み直しは不要
   - 設定後にプリセットや設定ファイルを上書きした場合は、この節の手順をもう一度実行する

---

## 更新

1. brew で starship を更新する。

   ```bash
   brew upgrade starship
   ```

   - すべてまとめて上げるなら `brew upgrade`

---

## ロールバック

1. starship をアンインストールして、端末を開き直す。

   ```bash
   brew uninstall starship
   ```

   - 次のシェルでは共通設定が starship の初期化を省略する。`~/.bashrc` の編集は不要

1. 設定も消すときだけ、`~/.config/starship.toml` を消す。

   ```bash
   rm -f ~/.config/starship.toml              # 設定も消す場合
   ```

1. キャッシュも消すときだけ、`~/.cache/starship` を消す。

   ```bash
   rm -rf ~/.cache/starship                   # キャッシュも消す場合
   ```

---

## 注意点

- **初期化の 1 行が本体**: `brew install` だけではプロンプトは変わらない。bash の共通設定が `starship init bash` を読むことで有効になる
- **starship の初期化は、`brew shellenv` の行より後ろ、zoxide の初期化と WezTerm のシェル統合より前に置く**。WezTerm へ正しい終了コードを渡すため、この順番を維持する
- **WezTerm のシェル統合の `A` / `B` は失われる**: `PS1` が毎回作り直されるため。並びによらない（[bash の読む順番](https://github.com/ryo-aoki-pc/bash#読む順番)）
- **アンインストール時に行を消し忘れると毎回エラーが出る**: [ロールバック](#ロールバック)の `sed` を忘れない
- **プロンプトごとに外部プロセスが起動する**: git の状態を調べるので、大きなリポジトリや遅いストレージ（Raspberry Pi の microSD）では体感できるほど遅くなることがある
  - `starship timings` で犯人を探し、要らないモジュールは `disabled = true` で切る
- **記号には Nerd Font が要るものがある**: 既定のプロンプト記号 `❯` は普通のフォントでも出るが、プリセットによっては Nerd Font 前提
  - 無い端末では `plain-text-symbols` / `no-nerd-font` を当てる
- **Homebrew 全般の注意は [homebrew.md の注意点](homebrew.md#注意点)**: PATH の先頭が Homebrew になる、`sudo starship` はそのままでは使えない、など
- **root は別に導入する**: root 自身にも bash の共通設定を導入した場合にだけ、root のシェルで初期化される（[homebrew.md の root の節](homebrew.md#root-のシェルでも使う任意)）
