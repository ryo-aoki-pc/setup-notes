# Dropbox 公式クライアント導入手順（AlmaLinux 10 / x86_64 / headless + systemd ユーザーサービス）の参考資料

[手順書](../dropbox.md)

## 補足

### 実施手順 / 手順 5: 補足: dropbox.py について

- 公式 RPM（`nautilus-dropbox`）が `/usr/bin/dropbox` に置くのと同じ Python スクリプト（GPLv3、先頭に `This file is part of nautilus-dropbox 2026.05.06.`）。公式の案内する `https://www.dropbox.com/download?dl=packages/dropbox.py` の飛び先を直接落としている
- 署名は無く、HTTPS で落とすだけ
- デーモンとは `~/.dropbox/command_socket` で話す
- デーモンを起動する `start` と、自動起動の `autostart` もあるが、本書では使わない（起動は手順 6 のユーザーサービスが受け持つ）
  - `autostart y` は `/usr/share/applications/dropbox.desktop`（RPM が置く）をコピーするだけなので、tarball の構成では何もしない
- `~/.local/bin` は、AlmaLinux の既定の `~/.bashrc` が PATH に足している。ディレクトリが無くても足すので、作った直後から名前で呼べる

### 実施手順 / 手順 7: 補足: URL が出るまでの時間と、journal

[この節の検証記録](../verification/dropbox.md#実施手順--手順-7-補足-url-が出るまでの時間とjournal)

URL は、リンクするまで journal にも繰り返し出る。

### 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **公式の tarball**（`download?plat=lnx.x86_64`） | 270.4.3312（一部は 272.3.3756 に振り分けられる）。分離署名があり、root 権限は要らない。デーモンが自分で更新する作り | **採用** |
| 公式 RPM（`nautilus-dropbox`、`linux.dropbox.com/fedora/`） | 2026.05.06（fc44 のビルド）。`libgnome >= 2.32.1` を要求するが、AlmaLinux 10（BaseOS / AppStream / CRB）にも EPEL 10 にも無いので入らない | 不採用（入らない） |
| `dropbox start -i`（`dropbox.py` がデーモンを落とす） | 画面が無いと `[y/n]` を聞き、画面があると GTK のダイアログになる。署名の確認は `python3-gpg` があるときだけで、tarball と署名を別々に引く（手順 3 の補足の食い違いが起こりうる） | 不採用（同じ tarball を手順 3 で確かめて展開する） |
| Flathub `com.dropbox.Client` | 272.4.3731。公開元が未検証（有志がまとめたもの）で、x86_64 のみ。GNOME 50 の runtime を使う | 不採用（[導入元一覧](../tool-catalog.md#選び方)の GUI の選び方で、未検証の公開元は採らない） |
| rclone（[dropbox-rclone.md](../dropbox-rclone.md)） | x86_64 でも動くが、常駐はせず、timer で定期的に双方向同期する | x86_64 では公式を採る（Raspberry Pi 5 では rclone） |

公式 RPM について、さらに分かったこと:

- `%post` が置く `/etc/yum.repos.d/dropbox.repo` は `baseurl=http://linux.dropbox.com/fedora/$releasever/` で、リポジトリには `21/`〜`45/` と `rawhide/` などはあるが `10/` が無い（EL10 では 404）
- RPM の中身は CLI（本書と同じ `dropbox.py`）・Nautilus の拡張・`.desktop`・アイコンだけで、デーモンは結局 `~/.dropbox-dist` に落とす

起動のさせ方と画面:

- **常駐はユーザーサービス + linger にした**
  - ファイルの持ち主として動かす
  - 公式の `autostart` は、GNOME へのログインで起動する形（RPM の `.desktop` が前提）で、ログインしている間しか動かない
- **headless で動かし、トレイアイコンは出さない**
  - 公式ヘルプによると、GNOME でトレイアイコンを出すには AppIndicator の拡張と `libappindicator-gtk3` が要る
  - EPEL 10 に `gnome-shell-extension-appindicator` と `libappindicator-gtk3` があるが、本書では入れていない

### 参照

- [System requirements — Dropbox Help](https://help.dropbox.com/installs/system-requirements) — Linux の要件（64 ビット、glibc、ファイルシステム、ARM 非対応）
- [Dropbox Linux desktop app: an overview — Dropbox Help](https://help.dropbox.com/installs/dropbox-desktop-app-for-linux) — headless と、トレイアイコンに要るもの（AppIndicator、libappindicator）
- [Linux commands — Dropbox Help](https://help.dropbox.com/installs/linux-commands) — `dropbox` コマンドの一覧
- [How many devices can I use with my Dropbox account? — Dropbox Help](https://help.dropbox.com/account-access/computer-limit) — Basic の台数の上限
- [Install Dropbox for Linux](https://www.dropbox.com/install-linux) — 公式の配布ページ
- `man systemd.service`（`Restart=`）/ `man systemd.exec`（`UnsetEnvironment=`）/ `man loginctl`（`enable-linger`）/ `man gpgv`
- [linger](../linger.md) — 前提の手順書（ログアウト中もユーザーの systemd を動かす）

---
