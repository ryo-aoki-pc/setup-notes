# VirtualBox Guest Additions 導入手順（AlmaLinux 10 bootc / Atomic Desktop のゲスト）の参考資料

[手順書](../virtualbox-guest-bootc.md)

## 補足

### 実施手順 / 手順 5: 補足: CD の中身と確かめ方

[この節の検証記録](../verification/virtualbox-guest-bootc.md#実施手順--手順-5-補足-cd-の中身と確かめ方)

### 実施手順 / 手順 7: 補足: 切り替えで起きること

[この節の検証記録](../verification/virtualbox-guest-bootc.md#実施手順--手順-7-補足-切り替えで起きること)

- `/usr` と `/opt` は、新しいイメージのものになる
- `/etc` は、手元の変更を残しつつ新しいイメージとマージされる（ostree の 3-way マージ）。イメージで足したファイル（udev のルール、`vboxclient.desktop`、unit を有効にするリンク）は、手元に無いので足される
- 手元で変更済みの `/etc/passwd`・`/etc/group` は手元のものが残るので、Guest Additions のユーザーとグループは入らない。最初の起動で `systemd-sysusers` が作る
- `/var` はそのまま残る。`/var/lib/VBoxGuestAdditions` のリンクは、起動のたびに `systemd-tmpfiles` が張る
- 起動時の `vboxadd.service` は、イメージのカーネル向けのモジュールがそろっているので作り直さず、読み込むだけにする

### ホストオンリーアダプターだけの VM でビルドする（任意） / 手順 3: 補足: 鍵をホストに置く理由と扱い

[この節の検証記録](../verification/virtualbox-guest-bootc.md#ホストオンリーアダプターだけの-vm-でビルドする任意--手順-3-補足-鍵をホストに置く理由と扱い)

- モジュールに署名するのは、この節の手順 7 のビルド（ホスト）なので、秘密鍵もホストに置く。VM には公開鍵の証明書だけを送る
- 鍵の作り方（CN も）は [secure-boot-mok.md 手順 4](../secure-boot-mok.md#実施手順) と同じで、置き場所と持ち主（自分のユーザー）だけが違う
- `~/vbox-ga-mok` は、ビルドの文脈（`~/vbox-ga-host/vbox-ga-image`）の外に置く。文脈のディレクトリは、まるごと podman に渡るため
- `MOK.priv` は、この鍵を登録した VM が信頼するモジュールを作れる鍵になる。ホストのほかのユーザーに読ませず、ほかのマシンに持ち出さない
- AlmaLinux 10 のホストでは、ホストの VirtualBox のモジュールの鍵（`/var/lib/shim-signed/mok/`。[secure-boot-mok.md](../secure-boot-mok.md) で作るもの）とは別のもの
- **鍵を作り直したら**、この節の手順 7 のビルドに `--no-cache` を足す（[更新](../virtualbox-guest-bootc.md#更新)のリードと同じ）

- 初めてつなぐときは、ホスト鍵の確認に答えると `known_hosts` に登録され、パスワードを聞かれる

### ロールバック / 手順 3: 補足: これらが自然には消えない理由

[この節の検証記録](../verification/virtualbox-guest-bootc.md#ロールバック--手順-3-補足-これらが自然には消えない理由)

- ユーザーとグループは、`systemd-sysusers` が手元の `/etc/passwd`・`/etc/group` に書いたもの。元のイメージに戻しても、手元で変更済みのファイルは 3-way マージで残る
- `/var` は、イメージを切り替えても戻らない
- 一方、イメージが足した `/etc` のファイルは、手元で変えていなければ、元のイメージに戻したときに消える（ostree の `/etc` のマージの仕組み）

### 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **派生イメージに焼き込み、`bootc switch` する** | bootc の想定どおりの形。モジュールをイメージのカーネル向けにビルドし、署名もビルドの中でできる | **採用** |
| VM の上で `VBoxLinuxAdditions.run` を実行する | `/usr`・`/opt` が読み取り専用で入らない | 不可 |
| `bootc usr-overlay` の上で実行する | 一時的な書き込み層なので、再起動で消える | 不採用 |
| dnf / rpm-ostree で RPM を入れる | EL10 には Guest Additions の RPM が無い（AppStream・EPEL 10・ELRepo el10 のどれにも無い）。Fedora の `virtualbox-guest-additions` は Fedora 43〜Rawhide だけ | 不可 |
| カーネルのモジュール（`vboxguest`）を使う | Fedora の方式。EL10 のカーネルは `CONFIG_VBOXGUEST` が無効 | 不可 |

Guest Additions の入手元とビルドの場所:

- **ホストの CD（採用）**: ホストの VirtualBox に同梱の ISO なので、必ず同じ版になる（Linux のホストでは、Oracle の rpm の署名で守られた配布物）。代わりに、VM のウィンドウで CD を入れる操作が 1 回要る
- 公式サイトの ISO（不採用）: 版を自分で合わせる必要がある
- **VM の上でビルドする（採用）**: レジストリが要らない。代わりに VM に 10 GB ほどの空きが要り、OS の更新のたびに VM でビルドし直す
- 別のマシンでビルドしてレジストリに置く（不採用）: 複数の VM で使うなら向くが、レジストリと認証の準備が要る

### 参照

- [bootc — Booting local builds](https://bootc-dev.github.io/bootc/booting-local-builds.html) — `podman build` と `bootc switch --transport containers-storage`
- [bootc — Filesystem](https://bootc-dev.github.io/bootc/filesystem.html) — `/var` の中身は最初のインストールでしか展開されない（Docker の `VOLUME` と同じ）、`/opt` は読み取り専用
- [bootc — Users and groups](https://bootc-dev.github.io/bootc/building/users-and-groups.html) — `/etc/passwd` の 3-way マージと `systemd-sysusers`
- [bootc-switch(8)](https://bootc-dev.github.io/bootc/man/bootc-switch.8.html) / [bootc-upgrade(8)](https://bootc-dev.github.io/bootc/man/bootc-upgrade.8.html) — `--apply`・`--transport`・`--enforce-container-sigpolicy`
- [AlmaLinux Atomic Desktop](https://github.com/AlmaLinux/atomic-desktop) — ベースのイメージの作り方（`/opt`・`/usr/local`・`policy.json`・`bootc-fetch-apply-updates` のドロップイン）、ISO の `iso.toml`（キックスタートの `%post` の `bootc switch --mutate-in-place`）とビルドの設定（`LATEST_TAG=latest`）
- [Oracle VirtualBox User Guide 7.2 — Guest Additions](https://docs.oracle.com/en/virtualization/virtualbox/7.2/user/guestadditions.html) — Guest Additions の機能と、Linux のゲストへの導入
- [VirtualBox — Changelog 7.2](https://www.virtualbox.org/wiki/Changelog-7.2) — RHEL 10.1・10.2（7.2.8）と RHEL 10.3（7.2.18）のカーネルへの対応、Wayland のクリップボード
- [VirtualBox のソース（GitHub の v7.2.20）](https://github.com/VirtualBox/virtualbox/tree/v7.2.20/src/VBox/Additions/linux/installer) — `vboxadd.sh`・`install.sh.in`・`vboxadd-x11.sh` と `src/VBox/Installer/linux/routines.sh`
- `man tmpfiles.d`（`L+`）/ `man sysusers.d`（`uid:gid`）/ `man Containerfile`（`RUN --mount=type=secret`）
- [Secure Boot の MOK 登録](../secure-boot-mok.md) — Secure Boot の VM の前提の手順書（署名鍵の作成と MokManager での登録）

---
