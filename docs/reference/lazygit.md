# lazygit 最新版インストール手順（AlmaLinux 10 / Homebrew）の参考資料

[手順書](../lazygit.md)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- `LG_EDITOR` を使うのは[設定ファイル](../lazygit.md#設定ファイル)の節だけ
- lazygit は設定が無ければ `EDITOR` 環境変数を見るので、`~/.bashrc` に `export EDITOR=nvim` があれば設定ファイルは要らない

### 実施手順 / 手順 3: 補足: 起動時の注意

[この節の検証記録](../verification/lazygit.md#実施手順--手順-3-補足-起動時の注意)

`lazygit --version` の `git version` 欄には、lazygit が呼ぶ git のバージョンが出る。

**git が入っていないと lazygit は起動しない。**

- Homebrew 版は git を依存に持たないので、RPM の git か `brew install git` のどちらかが要る

git 管理下でないディレクトリで起動すると `Would you like to create a new repository?` と聞かれる。意図せず `.git` を作らないよう、リポジトリのルートで起動する。

### 選択した方針

- `atim/lazygit` でも同じ 403
- dnf を介さず `curl -L` で `repomd.xml` を取っても同じ。COPR の配信元（`download.copr.fedorainfracloud.org`）が S3 の署名付き URL にリダイレクトし、その署名が期限切れになっている
- 一方で COPR 全体が落ちているわけではない。同じ日に `lihaohong/yazi` の `epel-10-aarch64` はメタデータを取得できている（[yazi.md](../yazi.md)）
- **プロジェクトごとの問題で、いずれ直る可能性がある**

### 参照

- [jesseduffield/lazygit — README](https://github.com/jesseduffield/lazygit) — 各 OS のインストール方法と機能一覧
- [lazygit Config Docs](https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md) — `config.yml` の項目（`os.edit` など）
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 手順 46〜48 が Homebrew 本体の導入手順。`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件は参考資料、`brew` の基本操作は同書の「Homebrew の使い方の基本」
- [atim/lazygit — Copr](https://copr.fedorainfracloud.org/coprs/atim/lazygit/) / [dejan/lazygit — Copr](https://copr.fedorainfracloud.org/coprs/dejan/lazygit/) — chroot の一覧（`epel-10-aarch64` はある）
- [ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit) — 自分用の設定（`config.yml`）。導入方法と変えた項目は README にある

---
