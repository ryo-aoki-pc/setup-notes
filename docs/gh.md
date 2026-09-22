# GitHub CLI（gh）インストール手順（AlmaLinux 10 / 公式 dnf リポジトリ）

## 実施手順

**すべて対象ホスト上で実行する。** 手順 4 の認証だけブラウザを使う。手順 0 で変数を設定したシェルで、上から順にコードブロックを貼る。理由・実測出力・落とし穴は[補足](#補足)にまとめてあり、実行するだけなら読まなくてよい。

| 手順 | 内容 |
|---|---|
| [0. 変数を設定する](#0-変数を設定する) | repo ファイルの URL を確認する（編集不要） |
| [1. config-manager を使えるようにする](#1-config-manager-を使えるようにする) | `dnf-plugins-core` を入れる |
| [2. リポジトリを追加する](#2-リポジトリを追加する) | `dnf config-manager --add-repo` |
| [3. インストールする](#3-インストールする) | `dnf install gh`。鍵 2 本の fingerprint を照合する |
| [4. 認証する](#4-認証する) | `gh auth login`（トークンは記録しない） |

以後の更新は[更新](#更新)、戻すときは[ロールバック](#ロールバック)。

### 0. 変数を設定する

**編集するものは無い。** 公式が配っている repo ファイルの URL を入れるだけ。新しいシェルを開いたら先にこのブロックを貼り直す。

```bash
GH_REPOFILE=https://cli.github.com/packages/rpm/gh-cli.repo   # 公式の repo ファイル。固定。<GH_REPOFILE>
echo "${GH_REPOFILE}"
```

→ [補足](#手順-0-変数について)

### 1. config-manager を使えるようにする

```bash
sudo dnf install -y 'dnf-command(config-manager)'
```

AlmaLinux 10 の dnf は 4 系（dnf5 ではない）なので、この後の手順も dnf4 の構文を使う（[補足](#手順-2-dnf4-と-dnf5-で構文が違う)）。

### 2. リポジトリを追加する

```bash
sudo dnf config-manager --add-repo "${GH_REPOFILE:?手順 0 の GH_REPOFILE が空のまま。値を入れて貼り直す}"
cat /etc/yum.repos.d/gh-cli.repo
```

`Adding repo from: ...` と出て `/etc/yum.repos.d/gh-cli.repo` ができる。`gpgcheck=1` になっていることを確認する。

### 3. インストールする

```bash
sudo dnf install gh
```

初回は署名鍵の取り込みを **2 回**聞かれる（鍵が 2 本ある）。fingerprint が次の 2 つであることを目で確かめてから `y` と答える。

- `7F38 BBB5 9D06 4DBC B3D8 4D72 5612 B364 6231 3325`
- `2C61 0620 1985 B60E 6C7A C873 23F3 D4EA 7571 6059`

どちらも Userid は `GitHub CLI <opensource+cli@github.com>`。違っていれば `N` で中断する。

→ [補足](#手順-3-鍵は-2-本)

### 4. 認証する

```bash
gh auth login
```

対話で GitHub.com / HTTPS / ブラウザ認証を選ぶ。終わったら確認する:

```bash
gh auth status
gh --version
```

**トークン（`gh auth token` の出力）や、認証中に表示されるワンタイムコードはこの文書に載せない。** 認証前の `gh auth status` は `You are not logged into any GitHub hosts.` を返す。

→ [補足](#手順-4-認証)

---

## 更新

通常の `dnf upgrade` に含まれる。gh だけ上げるなら:

```bash
sudo dnf upgrade gh
```

---

## ロールバック

```bash
sudo dnf remove gh
sudo rm -f /etc/yum.repos.d/gh-cli.repo
sudo rpm -e gpg-pubkey-62313325-69d4e1f8 gpg-pubkey-75716059-63172e8a   # 鍵も消す場合
```

設定（`~/.config/gh/hosts.yml` に保存されたトークン）は残る。消すなら先に `gh auth logout` でトークンを失効させてから `rm -rf ~/.config/gh`。

本書ではロールバックは**本実行していない**。

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [GitHub CLI](https://cli.github.com/) の最新版を **dnf 管理で**入れる。EPEL にも `gh` はあるが版が古い
- **進め方**: GitHub が配っている repo ファイルを `dnf config-manager --add-repo` で取り込み、`dnf install gh` する。**読者が書き換える値は無い**
- **状態**: **実機で本実行済み（2026-09-20）。** 下表のホストで `dnf config-manager --add-repo` → `dnf install -y gh` を実行し、`gh-2.101.0-1.aarch64` が入って認証済み、そのまま常用中。本書の手順 1〜3 は 2026-09-22 に同じ OS のコンテナで通し直し、鍵 2 本の fingerprint・同じ版の導入・`gh --version` まで確認した。**コンテナでは認証（手順 4）とロールバックは実行していない**

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| dnf / dnf-plugins-core | 4.20.0 / 4.7.0-10.el10 | 同左 |
| 入った gh | `gh-2.101.0-1.aarch64`（gh-cli リポジトリ） | 同じ（`2.101.0-1`） |
| 依存で入ったもの | 無し（git 2.52.0 は導入済みだった） | `git` / `git-core` など 13 パッケージ |
| 認証 | 済み（常用中） | 未実施 |

> **注記**: 環境固有の値は**シェル変数**で書いてある。[手順 0](#0-変数を設定する) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${GH_REPOFILE}` | 公式が配っている repo ファイルの URL。固定 | `https://cli.github.com/packages/rpm/gh-cli.repo` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`2.101.0`）は実行日によって変わる。
>
> **トークンは書かない。** 鍵の fingerprint は公開情報なので本文に書いてある。

手順の理由・実測・落とし穴・検証記録。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| gh | 未導入 |
| `dnf-plugins-core` | 未導入（`dnf config-manager` が使えない） |
| git | `git-2.52.0-1.el10.aarch64` 導入済み |
| 有効な追加リポジトリ | epel、crb、raspberrypi |

### 選択した方針

AlmaLinux 10 で gh を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **公式 dnf リポジトリ（`cli.github.com/packages/rpm`）** | `gh 2.101.0-1`。upstream の最新リリース（v2.101.0、2026-09-15）と一致。dnf 管理で更新できる | **採用** |
| EPEL の `gh` | `gh 2.97.0-2.el10_2`。4 リリースぶん古い | 不採用（最新版ではない） |
| GitHub Releases の `.rpm` を直接 `dnf install` | 同じバイナリだが、更新のたびに手で落とすことになる | 不採用 |
| Homebrew | 入るが、gh は dnf で入る最新版があるのでわざわざ二重にしない | 不採用 |

実測（EPEL と公式リポジトリを両方有効にした状態）:

```
$ dnf -q list --showduplicates gh | tail -5
gh.aarch64                        2.97.0-2.el10_2                        epel
gh.aarch64                        2.101.0-1                              gh-cli
gh.armv6hl                        2.101.0-1                              gh-cli
gh.i386                           2.101.0-1                              gh-cli
gh.x86_64                         2.101.0-1                              gh-cli
```

両方が有効なら dnf はバージョンの高い `gh-cli` 側を選ぶ。`armv6hl` や `i386` の行が見えるのは、このリポジトリが `baseurl` にアーキテクチャを含まない**全アーキテクチャ共通**の作りだから（Mozilla のリポジトリと同じ）。

### 手順の補足

#### 手順 0: 変数について

repo ファイルの URL を変数にしているのは、[手順 2](#2-リポジトリを追加する) のコマンドを空のまま貼っても何も起きないようにするため（`${GH_REPOFILE:?...}`）。中身は固定なので編集する必要はない。生成される repo ファイルは次のとおり:

```
[gh-cli]
name=packages for the GitHub CLI
baseurl=https://cli.github.com/packages/rpm
enabled=1
gpgcheck=1
gpgkey=https://cli.github.com/packages/githubcli-archive-keyring.asc
```

#### 手順 2: dnf4 と dnf5 で構文が違う

AlmaLinux 10.2 の dnf は **4.20.0**（`dnf5` パッケージは未導入）なので `--add-repo` を使う。Fedora 41 以降の dnf5 では構文が変わり、`sudo dnf install dnf5-plugins` のうえで:

```
sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
```

になる。公式ドキュメントは両方を併記している。EL10 でも将来 dnf5 に移れば後者になる。

#### 手順 3: 鍵は 2 本

`githubcli-archive-keyring.asc` には鍵が 2 本入っていて、取り込みも 2 回聞かれる。実測（コンテナ、`-y` 付きで流したときの表示）:

```
Importing GPG key 0x62313325:
 Userid     : "GitHub CLI <opensource+cli@github.com>"
 Fingerprint: 7F38 BBB5 9D06 4DBC B3D8 4D72 5612 B364 6231 3325
 From       : https://cli.github.com/packages/githubcli-archive-keyring.asc
Key imported successfully
Importing GPG key 0x75716059:
 Userid     : "GitHub CLI <opensource+cli@github.com>"
 Fingerprint: 2C61 0620 1985 B60E 6C7A C873 23F3 D4EA 7571 6059
 From       : https://cli.github.com/packages/githubcli-archive-keyring.asc
Key imported successfully
```

実機にも同じ 2 本が `gpg-pubkey-62313325-69d4e1f8` と `gpg-pubkey-75716059-63172e8a` として入っている。

gh 本体は依存の少ないパッケージだが、**git が入っていないホストでは git 一式（`git` / `git-core` / `git-core-doc` / `groff-base` など 13 パッケージ）が付いてくる**。実機は git 導入済みだったので追加は無かった。

#### 手順 4: 認証

`gh auth login` は対話で進む。SSH 越しの端末でブラウザを開けない場合は、表示されるワンタイムコードを手元のブラウザの `https://github.com/login/device` に入れる形になる。**この手順はコンテナでは実行していない**（実機では認証済みで常用している）。

トークンは `~/.config/gh/hosts.yml` に保存される。`gh auth token` で表示できるが、**記録しない**。

### 完了時点の状態

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' gh
gh 2.101.0-1 gh-cli
$ gh --version
gh version 2.101.0 (2026-09-15)
https://github.com/cli/cli/releases/tag/v2.101.0
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i github
gpg-pubkey-62313325-69d4e1f8 GitHub CLI <opensource+cli@github.com> public key
gpg-pubkey-75716059-63172e8a GitHub CLI <opensource+cli@github.com> public key
```

`gh` の実体は `/usr/bin/gh`、bash 補完は `/usr/share/bash-completion/completions/gh`。

### 注意点

- **EPEL と公式リポジトリが両方有効だと、更新のたびに両者を比較する**: バージョンが高い公式側が選ばれるので実害は無いが、EPEL 側だけを使いたいなら `exclude=gh` を `gh-cli` 側に書くか、リポジトリを無効にする
- **トークンの置き場所**: `~/.config/gh/hosts.yml` は平文。バックアップや共有に混ぜない。`gh auth logout` で失効させられる
- **`gh` は git を呼ぶ**: `gh repo clone` などは git に依存する。最小構成のホストでは git 一式が付いてくる
- **全アーキ共通リポジトリ**: `dnf list gh` に `i386` / `armv6hl` の行が出るのは正常

### 参照

- [Installing gh on Linux and BSD — cli/cli](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) — dnf4 / dnf5 それぞれの手順と repo ファイルの URL
- [GitHub CLI manual](https://cli.github.com/manual/) — `gh auth login` などのコマンド
- `man dnf.conf`（`gpgcheck`）

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで手順 1〜3 を通した（手順 4 の `gh auth login` は対話なので除外）。実機で加えた変更は `dnf install podman` だけ。 最後にもう 1 つ新しいコンテナを立て、**この文書のコードブロックをそのまま抜き出したスクリプト**（`sudo` を外し、`dnf install` / `dnf upgrade` に `-y` を付けただけ）を流して、上から順に貼れば通ることを確かめている。

| 手順 | 結果 |
|---|---|
| 1. プラグイン | `dnf-plugins-core-4.7.0-10.el10` が入る |
| 2. repo | `Adding repo from: https://cli.github.com/packages/rpm/gh-cli.repo` → `/etc/yum.repos.d/gh-cli.repo` 作成 |
| 3. install | `Installing: gh aarch64 2.101.0-1 gh-cli 14 M` + 依存 13 パッケージ（`git` / `git-core` / `git-core-doc` / `groff-base` / `authselect` など）。鍵 2 本を取り込んで成功 |
| 検証 | `gh --version` → `gh version 2.101.0 (2026-09-15)`。`gh auth status` → `You are not logged into any GitHub hosts.` |
| EPEL との比較 | `epel-release` を追加して `dnf list --showduplicates gh` → EPEL 2.97.0 と gh-cli 2.101.0 の 2 系統 |

#### 未確認事項

- 手順 4 の認証（コンテナでは未実施。実機では 2026-09-20 に実行して以後常用）
- `gh auth login` の SSH 鍵方式、`gh auth login --with-token`、GitHub Enterprise Server への接続
- `gh extension install` で入れた拡張の扱い
- ロールバック（`dnf remove` と鍵の削除）の本実行
- dnf5 に移行した場合の `config-manager addrepo` 構文（EL10 では dnf5 が入らないため未検証）
