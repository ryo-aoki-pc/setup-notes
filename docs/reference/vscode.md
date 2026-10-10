# Visual Studio Code インストール手順（AlmaLinux 10 / Microsoft 公式 dnf リポジトリ）の参考資料

[手順書](../vscode.md)・[ロールバックと注意点](../extra/vscode.md)

## 補足

### 実施手順 / 手順 5: 補足: .el8 タグの rpm が EL10 で解決できる理由

入る rpm は `code-1.138.0-1789458729.el8.aarch64` で、release の末尾が **`.el8` に固定されている**。

- これは「EL8 用のビルドを EL10 に流用している」のではなく、**Microsoft が EL 共通の rpm を 1 本だけ出している**ためで、EL9 / EL10 向けの別ビルドは存在しない
- `baseurl` も `yumrepos/vscode` の 1 つだけで、ディストリ非依存になっている

根拠は依存の下限。aarch64 向けに要求される glibc のうち最も新しいものが **2.28**（EL8 の版）で、EL10 の 2.39 が余裕で満たす:

- つまり **EL8 を最低ラインにして EL8 / EL9 / EL10 を 1 本でカバーする**作りで、Microsoft の公式ドキュメントも RHEL / CentOS / Fedora のすべてでこの同じリポジトリを案内している
- [WezTerm](../wezterm-nightly.md) の「作者が EL9 向けに出した COPR ビルドを EL10 で使う」とは事情が違う
- dnf は release 文字列を比較するだけなので、`.el8` のままでも `dnf upgrade` は正しく効く

### 選択した方針

[この節の検証記録](../verification/vscode.md#選択した方針)

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Microsoft 公式 dnf リポジトリ** | `packages.microsoft.com/yumrepos/vscode` に **aarch64 が 276 パッケージ**（`code` / `code-insiders` / `code-exploration`）。安定版は `code 1.138.0`。dnf で更新できる | **採用** |
| 公式サイトの `.rpm` を直接 `dnf install` | 同じバイナリだが、更新のたびに手で落とすことになる | 不採用 |
| Flathub `com.visualstudio.code` | リモートと runtime の導入が必要で、サンドボックスで PATH やツールチェインの見え方が変わる | 不採用（RPM で足りる） |
| Snap | EL10 に snapd を入れることになる | 不採用 |
| VSCodium / `code-oss` | Marketplace と一部の拡張（Remote-SSH など）が使えない | 対象外（本書は Microsoft のビルドを入れる） |
| `code-insiders` | 同じリポジトリの別パッケージ。コマンド名も設定ディレクトリ（`~/.config/Code - Insiders`）も別なので安定版と併存できる | 使うなら [手順 4](../vscode.md#実施手順) 以降の `code` を `code-insiders` に読み替える |

### 参照

- [Visual Studio Code on Linux](https://code.visualstudio.com/docs/setup/linux) — 公式のインストール手順（RHEL / CentOS / Fedora の節がこのリポジトリを案内している）
- [packages.microsoft.com/yumrepos/vscode](https://packages.microsoft.com/yumrepos/vscode/) — リポジトリの中身
- [VS Code — Command Line Interface](https://code.visualstudio.com/docs/editor/command-line) — `--list-extensions` / `--install-extension` / `--user-data-dir`
- [Electron — Ozone platform](https://www.electronjs.org/docs/latest/api/environment-variables) — `ELECTRON_OZONE_PLATFORM_HINT`
- `code --help` / `rpm -q --scripts code` — CLI のオプションと rpm のスクリプトレット

---
