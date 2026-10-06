# starship インストール手順（AlmaLinux 10 / Homebrew）の参考資料

[手順書](../starship.md)

[検証記録](../verification/starship.md#参考資料から分離した記録)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- `${STARSHIP_PRESET}` は[プリセットを当てる（任意）](../starship.md#プリセットを当てる任意)でしか使わない
- 既定を `plain-text-symbols` にしてあるのは、Nerd Font が無い環境でも文字化けしないため

### 実施手順 / 手順 2: 補足: 降ってくるボトル

[検証記録](../verification/starship.md#参考資料から分離した記録)

### 設定ファイル / 手順 1: 補足: 調べるときに使うサブコマンド

| コマンド | 用途 |
|---|---|
| `starship explain` | 今のプロンプトの各部分が何を表しているか |
| `starship timings` | モジュールごとの所要時間。プロンプトが遅いときの犯人探し |
| `starship module <名前>` | 1 モジュールだけ描画して確かめる |
| `starship print-config` | 実効設定を表示 |

### 選択した方針

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `arm64_linux` ボトルを使える | **採用** |
| 公式 install.sh（`sh -c "$(curl -sS https://starship.rs/install.sh)"`） | `/usr/local/bin` にバイナリを 1 つ置く。`sudo` が要り、更新は自分で再実行する | 不採用（Homebrew に揃える） |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-musl` のビルドがある。更新は手作業 | 不採用 |
| `cargo install starship` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

### 参照

- [starship.rs](https://starship.rs/) — 公式サイト。インストールと各シェルでの `init` の書き方
- [starship — Configuration](https://starship.rs/config/) — `starship.toml` の全モジュールと項目
- [starship — Presets](https://starship.rs/presets/) — プリセット一覧とスクリーンショット、Nerd Font が要るかどうか
- `starship --help` / `starship init bash --print-full-init` — サブコマンドと、シェルに入る初期化の中身
- [Homebrew](../homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---
