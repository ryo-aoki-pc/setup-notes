# ShellCheck と shfmt の参考資料

[手順書](../almalinux-setup.md#shellcheck-と-shfmt)・[注意点](../extra/shellcheck.md)

[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shellcheck.md#補足の実測)

## 補足

### ShellCheck と shfmt / 手順 1: 補足: ボトルと依存

- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
- ShellCheck は `gmp` と `libffi` を要求する（Haskell 製のため）。shfmt に依存は無い

### ShellCheck と shfmt / 手順 2: 補足: わざと欠陥のあるコードで確かめる

- わざと欠陥のあるコードを標準入力に流して、本当に検出できることを確かめる（ファイルは作らない）。shfmt も同じように確かめる
- どちらも「指摘があれば `rc=1`」で、`rc=0` は「指摘なし」を意味する

### 選択した方針

#### ShellCheck

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `arm64_linux` ボトルを使える | **採用** |
| EPEL | **パッケージ名は大文字の `ShellCheck`**（コマンドは小文字 `shellcheck`）。dnf 管理で root でも使える | 不採用。**`sudo shellcheck` を使いたい / dnf 管理に揃えたいならこちら**（`sudo dnf install ShellCheck`） |
| 公式のバイナリ配布 | GitHub Releases に `linux.aarch64` の tar.xz がある。展開して PATH に置くだけだが、更新は手作業 | 不採用（Homebrew に揃える） |
| `cabal install` / Docker イメージ | Haskell の toolchain か podman が要る | 不採用 |

#### shfmt

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `arm64_linux` ボトルを使える | **採用** |
| GitHub Releases のバイナリ | `shfmt_v3.x.x_linux_arm64` を落として `chmod +x` するだけ。更新は手作業 | 不採用（Homebrew に揃える） |
| `go install mvdan.cc/sh/v3/cmd/shfmt@latest` | Go toolchain が要る | 不採用 |

**2 つとも Homebrew に揃える。** ShellCheck だけ EPEL にすると 1 つの文書に dnf 経路と Homebrew 経路が同居し、更新も `dnf upgrade` と `brew upgrade` の 2 本立てになる。

### 参照

[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shellcheck.md#補足の実測)

---
