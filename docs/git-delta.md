# git-delta（delta）インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- [検証記録](verification/git-delta.md)・[参考資料](reference/git-delta.md)

> [!IMPORTANT]
> - **前提**: [AlmaLinux 10 の初期設定の手順 46〜48](almalinux-setup.md#実施手順) で Homebrew を入れてあること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。Homebrew の導入・管理は一般ユーザーで行い、設定も自分の `~/.gitconfig` に書く
> - **手順 2 で Homebrew の確認が出る場合がある**。答えて導入が完了してから手順 3 を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: lazygit を使っているなら[lazygit と組み合わせる（任意）](#lazygit-と組み合わせる任意)。設定項目の一覧は[設定ファイル](#設定ファイル)、以後は[更新](#更新)・[ロールバック](#ロールバック)

1. 変数を設定する。

   ```bash
   DELTA_NAVIGATE=true       # ページャ内で n / N を「次の変更・前の変更」にする。<DELTA_NAVIGATE>
   DELTA_LINE_NUMBERS=true   # 差分の左に行番号を出す。<DELTA_LINE_NUMBERS>
   DELTA_SIDE_BY_SIDE=false  # true にすると左右 2 面に分けて表示する。<DELTA_SIDE_BY_SIDE>
   for v in DELTA_NAVIGATE DELTA_LINE_NUMBERS DELTA_SIDE_BY_SIDE; do printf '%-19s = %s\n' "$v" "${!v}"; done
   ```

   - **編集が必須の変数は無い**。3 つとも表示の好みなので、既定のままで進められる
   - 広い画面で左右に並べたいなら、`DELTA_SIDE_BY_SIDE=true` にする
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. brew で git-delta を入れる。

   ```bash
   brew install git-delta
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - **formula 名は `git-delta` だが、入るコマンドは `delta`**（`brew install delta` でも同じ formula に解決される）
   - **次の手順は、Homebrew の確認が出たら答え、導入が成功してプロンプトに戻ってから貼る**（続けて貼ると確認の答えとして食われる）

1. `git config --global` で git の設定を書き、読み戻す。

   ```bash
   if [ -z "${DELTA_NAVIGATE}" ] || [ -z "${DELTA_LINE_NUMBERS}" ] || [ -z "${DELTA_SIDE_BY_SIDE}" ]; then
     echo '中断: 手順 1 の変数が空。3 つとも設定してから貼り直す' >&2
   else
     git config --global core.pager delta &&
       git config --global interactive.diffFilter 'delta --color-only' &&
       git config --global delta.navigate "${DELTA_NAVIGATE}" &&
       git config --global delta.line-numbers "${DELTA_LINE_NUMBERS}" &&
       git config --global delta.side-by-side "${DELTA_SIDE_BY_SIDE}" &&
       git config --global merge.conflictstyle zdiff3 &&
       git config --global --get-regexp '^(core\.pager|interactive\.difffilter|delta\.(navigate|line-numbers|side-by-side)|merge\.conflictstyle)$'
   fi
   ```

   - `~/.gitconfig` を直接編集せず、`git config --global` で書く（既にある `[user]` や `[core]` を壊さない）
   - 最後の行で、書けたか読み戻す
   - 設定した 6 項目が出る。`中断:` が出た場合は、どの設定も書き換えていない
   - **`interactive.difffilter` と小文字で表示される**のが正しい（git がキー名を正規化するため。`~/.gitconfig` の中では `diffFilter` のまま）
   - `merge.conflictstyle zdiff3` は delta とは独立した設定だが、コンフリクト表示が読みやすくなるので一緒に入れている
   - `zdiff3` は git 2.35 以降で使える（AlmaLinux 10 の RPM は 2.52.0）
   - [git.md 手順 6](git.md#実施手順) でも同じ値を入れる。先に通していても、同じキーが書き直されるだけ

1. 変更のあるリポジトリに `cd` してから、delta の版と差分の表示を確かめる。

   ```bash
   delta --version
   brew list --versions git-delta
   command -v delta
   git diff | delta --paging=never | head -20
   ```

   - 版は `delta 0.19.2` / `git-delta 0.19.2` のように出る
   - 最後の行で、変更のあるリポジトリの差分を出す
   - ファイル名のヘッダと、行ごとに背景色の付いた差分が出る
   - **`git diff` を単体で打ったときは、端末に直接出る場合だけ delta を通る**。`git diff | head` のようにパイプに繋ぐと git はページャを呼ばないので、素の差分が出る

---

## lazygit と組み合わせる（任意）

- lazygit は自前のページャ設定を持っているので、`~/.gitconfig` の `core.pager` は見ない

- lazygit の設定には `git.diffRenderers` を使う
> [!WARNING]
> **この節の手順 1 で、`~/.config/lazygit/config.yml` に既に `git:` があるなら、`cat >>` で追記せずに手で中身を併合する。** 同じトップレベルキーを 2 回書くと YAML として壊れる。

1. [lazygit.md](lazygit.md#設定ファイル) の設定ファイルに、delta をページャにする設定を足す。

   ```yaml
   git:
     diffRenderers:
       - type: stdinFilter
         colorArg: always
         command: delta --dark --paging=never
   ```

   - 現在の中身は、`lazygit --print-config-dir` で場所を確かめてから開く

---

## 設定ファイル

設定の実体は `~/.gitconfig` の `[delta]` セクション。手順 3 で書いた 3 つのほかによく使うもの:

| キー | 意味 |
|---|---|
| `features` | 名前付き設定のまとめ読み（`[delta "<名前>"]` を作って指定する） |
| `syntax-theme` | シンタックスハイライトの配色。一覧は `delta --list-syntax-themes` |
| `hyperlinks` | ファイル名を端末のハイパーリンクにする |
| `true-color` | 24 bit 色を使うか（既定は端末から自動判定） |
| `file-style` / `minus-style` / `plus-style` | ファイル名行・削除行・追加行の色 |

- 今の実効値は `delta --show-config` で全部出る
- `delta --help` にはオプションとして同じ名前が並んでおり、コマンドラインで一時的に上書きできる

---

## 更新

1. brew で git-delta を更新する。

   ```bash
   brew upgrade git-delta
   ```

   - すべてまとめて上げるなら `brew upgrade`
   - **ほかのコマンドは、Homebrew の確認が出たら答え、更新が終わってから貼る**（続けて貼ると確認の答えとして食われる）

---

## ロールバック

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

   - [git.md](git.md) を通したなら外さない（同じ設定を使う）

1. delta の設定が消えたか確かめる。

   ```bash
   git config --global --get-regexp '^(core\.pager|interactive\.difffilter|delta\.)'   # 何も出なければ消えている
   ```

   - 何も出なければ消えている
   - lazygit の `git.diffRenderers` に delta の項目を足していた場合は、その項目も消す（ほかの renderer は残す）。以前の `git.paging` を使っていた場合は、そちらの delta 設定を外す

---

## 注意点

- **`core.pager` は PATH に `delta` がある文脈でしか動かない**
  - Homebrew の PATH は `~/.bashrc` の `brew shellenv` で通っているので、`~/.bashrc` を読まない文脈（cron、一部の非対話シェル、他ユーザー、`sudo -i` しない root）で `git diff` を打つと `delta: command not found` になる
  - 固くしたいなら、フルパスで指定する: `git config --global core.pager /home/linuxbrew/.linuxbrew/bin/delta`
- **表示だけを変える。差分の中身は変わらない**: `git diff > patch.diff` はページャを通らないので従来どおりのパッチが出る。`git apply` や CI の挙動には影響しない
- **`sudo git` には効かない**: root は root の `~/.gitconfig` を読むので、この設定は入っていない
- **`interactive.diffFilter` が変えるのは `git add -p` の表示だけ**: 選択の操作自体は git のまま
- **lazygit は `core.pager` を見ない**: 0.65.1 では別途 `git.diffRenderers` を設定する（[lazygit と組み合わせる（任意）](#lazygit-と組み合わせる任意)）
- **Homebrew 全般の注意は [AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)**: PATH の先頭が Homebrew になる、`~/.bashrc` を読まない文脈では見えない、など
