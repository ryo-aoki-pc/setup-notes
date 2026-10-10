# gdu インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- [検証記録](verification/gdu.md)・[参考資料](reference/gdu.md)・[ロールバックと注意点](extra/gdu.md)

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **前提**: [AlmaLinux 10 の初期設定の手順 46〜48](almalinux-setup.md#実施手順) で Homebrew を入れてあること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、共通設定も自分のユーザーに導入するため）

- 上から順にコードブロックを貼る
- 手順の後: `gdu` という名前で呼びたいなら[gdu の名前で呼ぶ（任意）](#gdu-の名前で呼ぶ任意)。以後は[更新](#更新)・[ロールバック](extra/gdu.md#ロールバック)

1. brew で gdu を入れる。

   ```bash
   brew install gdu
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - 依存は無い（Go の静的バイナリ 1 つ、約 20 MB）
   - **入るコマンドは `gdu` ではなく `gdu-go`**
   - `brew install` の最後に ``To avoid a conflict with `coreutils`, `gdu` has been installed as `gdu-go`.`` という caveat が出る（出力例は[検証記録](verification/gdu.md)・[参考資料](reference/gdu.md)）

1. `gdu-go` が入ったことと、TUI を起動せずに走査できることを確かめる。

   ```bash
   gdu-go --version
   brew list --versions gdu
   command -v gdu-go
   command -v gdu || echo 'gdu という名前のコマンドは無い'
   gdu-go -n /usr/share | tail -5
   ```

   - `Version: v5.37.0` と出る
   - `command -v gdu` の行は `gdu という名前のコマンドは無い` になる。[gdu の名前で呼ぶ（任意）](#gdu-の名前で呼ぶ任意)をやるまでは、これが正しい状態
   - 最後の `gdu-go -n` では、サイズの大きい順に並んだ一覧が出る
   - **TUI で使うときは引数にディレクトリを渡すだけ**（`gdu-go ~` など。`q` で終了）

---

## gdu の名前で呼ぶ（任意）

1. 共通設定を読み直し、gdu のエイリアスを確かめる。

   ```bash
   . ~/.bashrc
   alias gdu
   ```

   - `alias gdu='gdu-go'` が出ればよい。`~/.bashrc` への追記は不要

1. スクリプトや他のツールからも `gdu` で呼びたいときだけ、シンボリックリンクにする。

   ```bash
   mkdir -p ~/.local/bin && ln -sfn /home/linuxbrew/.linuxbrew/bin/gdu-go ~/.local/bin/gdu
   ```

   - `~/.local/bin` は AlmaLinux の既定の `~/.bashrc` で PATH に入っている
   - リンク先を Cellar ではなく `/home/linuxbrew/.linuxbrew/bin` にしてあるので、`brew upgrade` で版が上がってもリンクは張り直さなくてよい
   - ただし **PATH の順序では Homebrew のほうが先**なので、EPEL 版の `/usr/bin/gdu` を同時に入れている場合はどちらが呼ばれるか変わる（[注意点](extra/gdu.md#注意点)）
   - `sudo gdu` には効かない（`~/.local/bin` は sudo の PATH に無い）。`sudo` では `gdu-go` と打つ（[AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節が要る）

---

## 更新

1. brew で gdu を更新する。

   ```bash
   brew upgrade gdu
   ```

   - すべてまとめて上げるなら `brew upgrade`
