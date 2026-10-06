# EPEL 有効化手順（AlmaLinux 10 / extras の epel-release）の参考資料

[手順書](../epel.md)

## 補足

### 実施手順 / 手順 3: 補足: 出力例と、EPEL の鍵

`epel-release` は、repo ファイル（`/etc/yum.repos.d/epel.repo` と、無効の `epel-testing.repo`）と、鍵のファイル `/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10` を置く。

取り込んだ鍵は、`rpm -q gpg-pubkey` に `gpg-pubkey-e37ed158-65785fa9` として出る（[ロールバック](../epel.md#ロールバック)の手順 2 で使う）。

### 参照

- [EPEL — Fedora Docs](https://docs.fedoraproject.org/en-US/epel/) — EPEL とは何か。入れ方は同じ文書の [Getting Started](https://docs.fedoraproject.org/en-US/epel/getting-started/)（CRB と `epel-release`）
- `man dnf`（`remove` の `--noautoremove`）
- [導入元一覧の導入経路と EL10 での注意](../tool-catalog.md#導入経路と-el10-での注意) — EPEL とほかの導入元の比較

---
