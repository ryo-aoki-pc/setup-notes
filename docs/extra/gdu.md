# gdu インストール手順（AlmaLinux 10 / Homebrew）のロールバックと注意点

[手順書](../gdu.md)・[検証記録](../verification/gdu.md)・[参考資料](../reference/gdu.md)

- 「手順 N」は[手順書](../gdu.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

1. brew で gdu を消す。

   ```bash
   brew uninstall gdu
   ```

1. 端末を閉じて開き直す。

   - 削除したツールの設定は、次のシェルでは共通設定から読み込まれない
   - `~/.bashrc` にツール別の行は書いていないので、削除も不要

1. シンボリックリンクを作っていたときだけ、`~/.local/bin/gdu` を消す。

   ```bash
   rm -f ~/.local/bin/gdu                    # シンボリックリンクを作っていた場合
   ```

1. 設定ファイルを作っていたときだけ、`~/.gdu.yaml` を消す。

   ```bash
   rm -f ~/.gdu.yaml                         # 設定ファイルを作っていた場合
   ```

---

## 注意点

- **コマンド名が `gdu-go`**: これが最大の引っかかりどころ。`gdu` と打って `command not found` になったら、まず `command -v gdu-go` を見る
- **エイリアスの確認に `type -t` は使えない**: bash は非対話シェルでエイリアスを展開しないため、`type -t gdu` はエイリアスを見つけられない（`alias gdu` なら確認できる）
  - 関数を定義する [zoxide](../almalinux-setup.md#実施手順) / [yazi](../yazi.md) の `y()` は、この制約を受けない
- **EPEL 版と同時に入れると版が 2 つ並ぶ**: 名前が違う（`/usr/bin/gdu` と `gdu-go`）ので上書きされず、**共存してしまう**
  - `gdu` と打つと EPEL の 5.32.0、`gdu-go` と打つと Homebrew の 5.37.0 という状態になる
  - どちらか片方にする
- **エイリアスは対話シェルだけ**: スクリプトや `sudo` からは `gdu-go`。スクリプトからも揃えたいならシンボリックリンク（`sudo` には効かない）
- **走査は I/O が重い**: Raspberry Pi の microSD で `/` 全体を走らせると時間がかかる。`-x`（ファイルシステムを跨がない）や対象ディレクトリの限定を併用する
- **TUI からファイルを消せる**: `d` で削除できるので、root 権限で起動するときは特に注意する（`sudo gdu-go` は、[AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通さないと、フルパスが要る。[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）
