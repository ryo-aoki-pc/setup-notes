# eza インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- [検証記録](verification/eza.md)・[参考資料](reference/eza.md)

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、共通設定も自分のユーザーに導入するため）

- 上から順にコードブロックを貼る
- 手順の後: 普段使いにするなら[エイリアスを足す（任意）](#エイリアスを足す任意)。列や時刻の書式は[表示を調整する](#表示を調整する)、以後は[更新](#更新)・[ロールバック](#ロールバック)

1. 共通の bash 設定が導入済みか確かめる。

   ```bash
   echo "${__bash_config_loaded-読まれていない}"
   ```

   - `1` が出ればよい。未導入なら [共通設定の導入](../README.md#共通の-bash-設定を先に入れる)を行い、端末を開き直す

1. brew で eza を入れる。

   ```bash
   brew install eza
   ```

   - 確認が出たら表示された導入予定を確かめて `y` と答え、処理が終わってプロンプトに戻ってから次の手順を貼る（[Homebrew の注意点](homebrew.md#注意点)）
   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - 依存は `libgit2` 1 つだけ（`--git` 列のため）

1. git 管理下のディレクトリに `cd` してから、eza の版と `Git` 列を確かめる。

   ```bash
   eza --version
   brew list --versions eza
   command -v eza
   eza -l --git --header .
   ```

   - `cd` する先は自分のリポジトリでよい
   - `eza --version` は `v0.23.5 [+git]` を含む 3 行を出す
   - `[+git]` が付いていれば、git 連携込みでビルドされている
   - 最後の行で、`Git` 列が出ることを確かめる
   - `Permissions Size User Date Modified Git Name` という見出しが出る
   - 変更したファイルの `Git` 列に `-M` が付く
   - **git 管理下でないディレクトリでは、`Git` 列そのものが出ない**

---

## エイリアスを足す（任意）

- **`ls` は置き換えない**。`ll` / `la` / `lt` を足す形にする（理由は[注意点](#注意点)）

1. 共通設定を読み直し、ll / la / lt を確かめる。

   ```bash
   . ~/.bashrc
   alias ll la lt
   ```

   - `ll` は `eza -l --git --group-directories-first`、`la` は `-la`、`lt` は `eza --tree --level=2`
   - 共通のオプションは bash リポジトリで管理する。`EZA_OPTS` の設定や `~/.bashrc` への追記は不要

---

## 表示を調整する

設定ファイルは無く、すべてコマンドラインオプションと環境変数で決める。よく使うもの:

| やりたいこと | オプション |
|---|---|
| 列の見出しを出す | `--header`（`-h`） |
| 時刻の書式を変える | `--time-style=long-iso` / `iso` / `relative` / `+%Y-%m-%d` |
| 8 進数のパーミッション | `--octal-permissions`（`-o`） |
| アイコンを出す | `--icons=always`（**Nerd Font が要る**） |
| ディレクトリを先に並べる | `--group-directories-first` |
| `.gitignore` のファイルを隠す | `--git-ignore` |
| git 連携を切る | `--no-git` |

- 色は `LS_COLORS` と `EZA_COLORS` を見る
- 全オプションは `eza --help`（86 行）と `man eza`

---

## 更新

1. brew で eza を更新する。

   ```bash
   brew upgrade eza
   ```

   - すべてまとめて上げるなら `brew upgrade`

---

## ロールバック

1. brew で eza を消す。

   ```bash
   brew uninstall eza
   ```

   - 依存の `libgit2` は [bat](bat.md) / [git-delta](git-delta.md) が必要とする間は残る。Homebrew 7 では、不要になった依存は `brew uninstall` の後に自動で削除される。自動削除を無効にしていた場合は、`brew autoremove --dry-run` で対象を確認してから `brew autoremove` を使う

1. 端末を閉じて開き直す。

   - 削除したツールの設定は、次のシェルでは共通設定から読み込まれない
   - `~/.bashrc` にツール別の行は書いていないので、削除も不要

---

## 注意点

- **`alias ls=eza` は勧めない**。`ll` / `la` を足すだけにしておくと、`ls` はいつでも GNU のものとして残る
  - eza は GNU `ls` の全オプションを実装していない
  - `-G` の意味が違い（`ls` は「グループを出さない」、eza は「グリッド表示」）、`--time-style` に渡せる値も別物
  - エイリアスは対話シェルにしか効かないのでスクリプトは壊れないが、**壊れないぶん、手が覚えたフラグが通らないときに原因が分かりにくい**
- **エイリアスの確認に `type -t` は使えない**: bash は非対話シェルでエイリアスを展開しないため、`type -t ll` はエイリアスを見つけられない（`alias ll` なら確認できる）
  - 関数を定義する [zoxide](zoxide.md) / [yazi](yazi.md) の `y()` は、この制約を受けない
- **アイコンには Nerd Font が要る**: `--icons=always` はグリフを出すだけなので、フォントが無い端末では豆腐になる
  - Nerd Font を導入するなら [yazi.md](yazi.md) を参照する
- **`--git` は大きなリポジトリで遅くなる**: 毎回 git の状態を引くため。気になるなら `--no-git`、リポジトリの一覧だけなら `--git-repos-no-status`
- **Homebrew 全般の注意は [homebrew.md の注意点](homebrew.md#注意点)**: PATH の先頭が Homebrew になる、`sudo eza` はそのままでは使えない、など
