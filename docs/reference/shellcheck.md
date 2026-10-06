# ShellCheck / shfmt インストール手順（AlmaLinux 10 / Homebrew）の参考資料

[手順書](../shellcheck.md)

[検証記録](../verification/shellcheck.md#参考資料から分離した記録)

## 補足

### shfmt で整形を確かめる（任意） / 手順 2: 補足: よく使うオプション

| オプション | 意味 |
|---|---|
| `-i N` | インデント幅。`0` はタブ（既定） |
| `-ci` | `case` の分岐を字下げする |
| `-bn` | 二項演算子の前で改行する |
| `-sr` | リダイレクトの後に空白を入れる |
| `-s` | 冗長な書き方を簡略化する |
| `-d` / `-l` / `-w` | 差分を出す / 対象を列挙する / 上書きする |
| `-ln bash\|posix\|mksh` | 方言を明示する（既定はシェバンから判定） |

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

[検証記録](../verification/shellcheck.md#参考資料から分離した記録)

---
