# hadolint / dive / Trivy インストール手順（AlmaLinux 10 / Homebrew + Trivy 公式 dnf リポジトリ）の参考資料

[手順書](../image-tools.md)

## 補足

### 実施手順 / 手順 1: 補足: ボトルと依存

[この節の検証記録](../verification/image-tools.md#実施手順--手順-1-補足-ボトルと依存)

### 実施手順 / 手順 8: 補足: FAIL の理由と、判定の基準

[この節の検証記録](../verification/image-tools.md#実施手順--手順-8-補足-fail-の理由と判定の基準)

- `ubi10/httpd-24` は、複数の層でパッケージを入れるため、層ごとに rpm のデータベースが書き直される
- 自分が足した層が小さいと、「自分が足した量に対する無駄」の割合が大きく出る

- 基準は `--lowestEfficiency` などのオプションか、リポジトリに置く `.dive-ci` で変えられる（`dive --help`）
- `--source podman` の dive は podman のコマンド（`podman image save`）でイメージを取り出すので、API ソケットは要らない

### 選択した方針

| ツール | 経路 | 理由 |
|---|---|---|
| hadolint | **Homebrew（2.15.1）** | AppStream にも EPEL にも無い。公式のコンテナイメージで動かす方法もあるが、検査のたびにコンテナを起動することになる |
| dive | **Homebrew（0.13.1）** | RPM のリポジトリが無い（上流は GitHub に rpm を置いているだけで、`dnf upgrade` に乗らない） |
| Trivy | **公式の dnf リポジトリ（0.74.0）** | Homebrew と同じ版なので、[ツール一覧の選び方](../tool-catalog.md#選び方)の規則 1 で RPM にした。EPEL は 0.64.1 と古い |
| syft / grype（SBOM と脆弱性） | 対象外 | Trivy と役割が重なる |

- 3 つの経路が混ざるので、更新も `brew upgrade` と `sudo dnf upgrade` の 2 つになる（[更新](../image-tools.md#更新)）
- Trivy だけ RPM なので、`sudo trivy` がそのまま動く。hadolint と dive は Homebrew なので、root で使うなら [homebrew.md の sudo でも使う](../homebrew.md#sudo-でも使う任意)の節を通すか、フルパスで呼ぶ

### 参照

- [hadolint — README](https://github.com/hadolint/hadolint) — 規則の一覧、`--ignore`、設定ファイル（`~/.config/hadolint.yaml`）
- [dive — README](https://github.com/wagoodman/dive) — `--source`、`--ci` と `.dive-ci`、キー操作
- [Trivy — Installation](https://trivy.dev/docs/latest/getting-started/installation/) — RHEL/CentOS の公式 dnf リポジトリの登録
- [Trivy — Container Image](https://trivy.dev/docs/latest/guide/target/container_image/) — `--image-src`（podman は API ソケットを使う）
- [Homebrew](../homebrew.md) / [Podman](../podman.md) — 前提の手順書

---
