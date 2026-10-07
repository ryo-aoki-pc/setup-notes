# VirtualBox インストール手順（AlmaLinux 10 は Oracle 公式 dnf リポジトリ / Windows 11 は winget）の参考資料

[手順書](../virtualbox.md)

[検証記録](../verification/virtualbox.md#参考資料から分離した記録)

## 補足

### 実施手順 / 手順 4: 補足: repo ファイルは Oracle 公式のものとほぼ同じ

**repo ファイルは Oracle 公式のもの（`https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo`）とほぼ同じ**。

- 変えたのは、`baseurl` の `http://` を `https://` にしたこと（同じホストが HTTPS でも応答する）と、`name` だけ
- `gpgcheck` / `repo_gpgcheck` / `gpgkey` は公式どおり
- `$releasever` は AlmaLinux 10 では `10` に展開されるので、`.../rpm/el/10/x86_64` を見に行く

### 実施手順 / 手順 7: 補足: 動いているカーネルを最新にしておく理由

`kernel-devel` は動いているカーネル（`uname -r`）と同じ版を入れ、モジュールもその版向けにビルドされる。更新済みのカーネルでまだ起動していないと、次の起動で新しいカーネル用のモジュールを作り直すことになる（[カーネルを更新したとき](../virtualbox.md#カーネルを更新したとき)）。

### Windows 11 で使う / 手順 4: 補足: winget のソースを限定する理由

- `--source winget` を付けた `winget list` は、入っているアプリを winget のカタログと照合し、確認に要らない Microsoft Store のソースの初回同意を避ける

### Windows 11 で使う / 手順 5: 補足: 管理者ではない窓で動かす理由

- 管理者の窓から起動したもの（`VBoxManage`・`VirtualBox.exe`）は、管理者の権限で動く。AlmaLinux 10 で VM を root ではなく自分のユーザーで動かすのと同じく、VM は自分のユーザーで動かす
- VirtualBox のマニュアルは、管理者の権限で動かした VirtualBox と、普通の権限で動くエクスプローラーの間では、ドラッグ＆ドロップができないと書いている
- VM と設定の場所（`%USERPROFILE%\VirtualBox VMs` と `%USERPROFILE%\.VirtualBox`）はユーザーごと。管理者の窓でも同じユーザーなので、場所は変わらない

### 選択した方針

| 経路 | EL10 での状況 | 採否 |
|---|---|---|
| **Oracle 公式 dnf リポジトリ** | EL10 向けのビルド（`_el10`）があり、メタデータにもパッケージにも署名がある。`dnf upgrade` で上がる | **採用** |
| 公式サイトの `.rpm` を直接入れる | 同じ rpm だが、更新のたびに手で落とすことになる | 不採用 |
| 汎用インストーラ（`VirtualBox-7.2.20-175154-Linux_amd64.run`） | `/opt/VirtualBox` に入り、dnf の管理外になる | 不採用 |
| Oracle Linux の `ol10_developer` チャンネル | Oracle Linux 専用 | 対象外 |
| RPM Fusion | EL10 には VirtualBox が無い（EL9 に 7.1.18） | 不採用 |
| Flathub | 無い（カーネルモジュールが要るため） | — |
| 7.1 系（`VirtualBox-7.1`） | 同じリポジトリにある保守版。7.2 と同時には入らない | 対象外 |
| KVM（libvirt / virt-manager / GNOME Boxes） | AlmaLinux 標準の仮想化。カーネルに組み込み済みでモジュールのビルドも署名も要らない | 対象外（本書は VirtualBox を入れる）。VirtualBox と同時には動かない（手順 11） |

aarch64 には入らない:

- 7.2.20 の配布物にも Linux の arm64 版が無い（arm64 向けは macOS の Apple Silicon 版と、Windows の実験的な対応だけ）
- マニュアルの対応ホストの一覧も、Linux はすべて x86_64 になっている

