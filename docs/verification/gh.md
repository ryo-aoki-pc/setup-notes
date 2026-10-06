# GitHub CLI（gh）インストール手順（AlmaLinux 10 / 公式 dnf リポジトリ）の検証記録

[手順書](../gh.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順 / 手順 2: 補足: 鍵は 2 本

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

### ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**

### 対象と検証環境

- **目的**: AlmaLinux 10 に [GitHub CLI](https://cli.github.com/) の最新版を **dnf 管理で**入れる。EPEL にも `gh` はあるが版が古い
- **進め方**: GitHub が配っている repo ファイルを `dnf config-manager --add-repo` で取り込み、`dnf install gh` する。**読者が書き換える値は無い**
- **状態**: **実機で本実行済み（2026-09-20）。x86_64 のクリーン VM でも実施手順を本実行済み（2026-10-06、下の付録の範囲）**
  - 下表のホストで `dnf config-manager --add-repo` → `dnf install -y gh` を実行し、`gh-2.101.0-1.aarch64` が入って認証済み、そのまま常用中
  - 本書の手順 1・2 は 2026-09-22 に同じ OS のコンテナで通し直し、鍵 2 本の fingerprint・同じ版の導入・`gh --version` まで確認した
  - **コンテナでは認証（手順 3・4）とロールバックは実行していない**
  - 2026-09-28: もとの手順 2 のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-02: もとの手順 1・2 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）
  - 2026-10-05: 2.101.0 の公式ソースのヘルプ本文で、トークン保存先と `auth logout` の範囲を確認し、ロールバックの手順 1・2 を追加した。認証・ログアウト・失効は実行していない

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| dnf / dnf-plugins-core | 4.20.0 / 4.7.0-10.el10 | 同左 |
| 入った gh | `gh-2.101.0-1.aarch64`（gh-cli リポジトリ） | 同じ（`2.101.0-1`） |
| 依存で入ったもの | 無し（git 2.52.0 は導入済みだった） | `git` / `git-core` など 13 パッケージ |
| 認証 | 済み（常用中） | 未実施 |

> [!NOTE]
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`2.101.0`）は実行日によって変わる。
>
> **トークンは書かない。** 鍵の fingerprint は公開情報なので本文に書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

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

### 参照

- [Installing gh on Linux and BSD — cli/cli](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) — dnf4 / dnf5 それぞれの手順と repo ファイルの URL
- [GitHub CLI manual](https://cli.github.com/manual/) — `gh auth login` などのコマンド
- [gh 2.101.0 の login](https://github.com/cli/cli/blob/v2.101.0/pkg/cmd/auth/login/login.go)・[logout](https://github.com/cli/cli/blob/v2.101.0/pkg/cmd/auth/logout/logout.go) — 対象版のヘルプ本文。資格情報ストアと平文保存、ローカル削除とサーバー側の失効を区別する（2026-10-05 にソースを確認。認証の操作は未実行）
- `man dnf.conf`（`gpgcheck`）

### 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで手順 1・2 を通した（手順 3 の `gh auth login` は対話なので除外）。実機で加えた変更は `dnf install podman` だけ。 最後にもう 1 つ新しいコンテナを立て、**この文書のコードブロックをそのまま抜き出したスクリプト**（`sudo` を外し、`dnf install` / `dnf upgrade` に `-y` を付けただけ）を流して、上から順に貼れば通ることを確かめている。

| 手順 | 結果 |
|---|---|
| 1. プラグイン | `dnf-plugins-core-4.7.0-10.el10` が入る |
| 1. repo | `Adding repo from: https://cli.github.com/packages/rpm/gh-cli.repo` → `/etc/yum.repos.d/gh-cli.repo` 作成 |
| 2. install | `Installing: gh aarch64 2.101.0-1 gh-cli 14 M` + 依存 13 パッケージ（`git` / `git-core` / `git-core-doc` / `groff-base` / `authselect` など）。鍵 2 本を取り込んで成功 |
| 検証 | `gh --version` → `gh version 2.101.0 (2026-09-15)`。`gh auth status` → `You are not logged into any GitHub hosts.` |
| EPEL との比較 | `epel-release` を追加して `dnf list --showduplicates gh` → EPEL 2.97.0 と gh-cli 2.101.0 の 2 系統 |

#### 未確認事項

- 手順 3・4 の認証（コンテナでは未実施。実機では 2026-09-20 に実行して以後常用）
- `gh auth login` の SSH 鍵方式、`gh auth login --with-token`、GitHub Enterprise Server への接続
- `gh extension install` で入れた拡張の扱い
- ロールバック（`dnf remove` と鍵の削除）の本実行
- dnf5 に移行した場合の `config-manager addrepo` 構文（EL10 では dnf5 が入らないため未検証）

---

### 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1・2。

**結果**: GitHub 公式 RPM リポジトリを追加し、表示された 2 本の署名鍵の fingerprint を本文と比べて取り込んだ。gh 2.102.0 が入り、版と `/usr/bin/gh` を確認した。追加の `gh auth status` は未ログインを示した。

**今回の未確認範囲**: 手順 3・4 のアカウント認証と、更新・ロールバックは今回流していない。

### 付録: 現行版の新規 VM での再検証（2026-10-06）

公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active）で、`5da3478` の本文を SSH 対話 PTY に渡した。試験専用のユーザー・鍵と設定値を使用し、利用者の実アカウントの資格情報は持ち込んでいない。

実施手順 1・2 を通し、公式 repo と文書に載せた 2 本の署名鍵を確認して導入した。gh 2.102.0、`gh auth status` は未ログイン（終了 1）だった。実アカウントの認証、更新・削除はこの再検証で行っていない。端末捕捉補助が問い合わせの処理で待ったため、生ログで版・未ログイン・コマンドの終了を確認し、以後の補助は生出力主体に切り替えた。手順の失敗とは扱わない。

### 実施手順 / 手順 4: 補足: 認証

`gh auth login` は対話で進む。SSH 越しの端末でブラウザを開けない場合は、表示されるワンタイムコードを手元のブラウザの `https://github.com/login/device` に入れる形になる。**この手順はコンテナでは実行していない**（実機では認証済みで常用している）。

### 選択した方針

```
$ dnf -q list --showduplicates gh | tail -5
gh.aarch64                        2.97.0-2.el10_2                        epel
gh.aarch64                        2.101.0-1                              gh-cli
gh.armv6hl                        2.101.0-1                              gh-cli
gh.i386                           2.101.0-1                              gh-cli
gh.x86_64                         2.101.0-1                              gh-cli
```
