# GitHub CLI（gh）インストール手順（AlmaLinux 10 / 公式 dnf リポジトリ）の参考資料

[手順書](../gh.md)

## 補足

### 実施手順 / 手順 1: 補足: 生成される repo ファイルと、dnf4 と dnf5 の構文の違い

追加するのは公式が配っている repo ファイルで、生成される `/etc/yum.repos.d/gh-cli.repo` は次のとおり:

```
[gh-cli]
name=packages for the GitHub CLI
baseurl=https://cli.github.com/packages/rpm
enabled=1
gpgcheck=1
gpgkey=https://cli.github.com/packages/githubcli-archive-keyring.asc
```

AlmaLinux 10.2 の dnf は **4.20.0**（`dnf5` パッケージは未導入）なので `--add-repo` を使う。Fedora 41 以降の dnf5 では構文が変わり、`sudo dnf install dnf5-plugins` のうえで:

```
sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
```

になる。公式ドキュメントは両方を併記している。EL10 でも将来 dnf5 に移れば後者になる。

### 実施手順 / 手順 4: 補足: 認証

トークンは OS の資格情報ストアに保存される。ストアを使えない場合は `~/.config/gh/hosts.yml` の平文保存に切り替わる。保存先は `gh auth status` で確認する。`gh auth token` の出力は**記録しない**。

### 選択した方針

- 両方が有効なら、dnf はバージョンの高い `gh-cli` 側を選ぶ
- `armv6hl` や `i386` の行が見えるのは、このリポジトリが `baseurl` にアーキテクチャを含まない**全アーキテクチャ共通**の作りだから（Mozilla のリポジトリと同じ）

### 参照

---
