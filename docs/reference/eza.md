# eza インストール手順（AlmaLinux 10 / Homebrew）の参考資料

[手順書](../eza.md)

## 補足

### 実施手順 / 手順 2: 補足: 降ってくるボトル

aarch64 で降ってくるボトルは `eza--0.23.5.arm64_linux.bottle.tar.gz`。

### 選択した方針

[この節の検証記録](../verification/eza.md#選択した方針)

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `eza 0.23.5` の `arm64_linux` ボトルがある。upstream の最新と一致 | **採用** |
| EPEL / AppStream / CRB | **`eza` も、前身の `exa` も無い**（`dnf list --available eza exa` → `Error: No matching Packages to list`） | 使えない |
| 公式の deb リポジトリ | eza は Debian/Ubuntu 向けの apt リポジトリを配っているが、**RPM 版の配布は無い** | 使えない |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-gnu` / `musl` のビルドがある。展開して PATH に置くだけだが、更新は手作業 | 不採用（Homebrew に揃える） |
| `cargo install eza` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

### 参照

- [eza-community/eza — README](https://github.com/eza-community/eza) — 使い方、各ディストリビューションでの入手方法、`ls` との違い
- [eza.rocks](https://eza.rocks) — 公式サイト。スクリーンショットと機能一覧
- `eza --help` / `man eza` — 全オプション（`--help` は 86 行）
- [Homebrew](../homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---
