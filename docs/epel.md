# EPEL 有効化手順（AlmaLinux 10 / extras の epel-release）

## 実施手順

- [検証記録](verification/epel.md)・[参考資料](reference/epel.md)

> [!IMPORTANT]
> - **すべて対象ホスト上で実行する**

- 上から順にコードブロックを貼る
- 手順の後: 以後は[更新](#更新)・[ロールバック](#ロールバック)
- 通すと使えるようになるもの:
  - [btop](btop.md)、[distrobox](distrobox.md)、[podman-compose](podman-compose.md)、[podman-tui](podman-tui.md)、[VirtualBox](virtualbox.md)（依存の `liblzf`）
  - [RPM Fusion（free）](rpmfusion.md)と、それを使う [Firefox の AAC・H.264](firefox.md#実施手順)
  - [導入元一覧](tool-catalog.md)で導入元が EPEL の行（fastfetch・duf・mosh・restic・Chromium・KeePassXC・Meld・GNOME Tweaks・Remmina）

1. EPEL が有効になっているか確かめる。

   ```bash
   dnf repolist enabled | grep -E '^epel' || echo 'EPEL は未設定'
   ```

   - `epel` の行が出れば、手順 2 は飛ばす
   - `EPEL は未設定` と出たら、手順 2 で入れる

1. EPEL が未設定のときだけ、`epel-release` を入れる。

   ```bash
   sudo dnf install -y epel-release
   ```

   - AlmaLinux の `extras` リポジトリに入っているので、追加のリポジトリ設定は要らない
   - 最後に出る「CRB を有効にすることを推奨」は、AlmaLinux 10 では既定で有効なので気にしなくてよい（[導入元一覧](tool-catalog.md#導入経路と-el10-での注意)）

1. EPEL が有効になったか確かめる。

   ```bash
   rpm -q epel-release
   dnf repolist enabled | grep -E '^epel'
   ```

   - `epel-release` の版と、`epel` の行が出れば有効になっている
   - EPEL の署名鍵は、EPEL からパッケージを最初に入れるとき（各手順書の導入の手順）に、dnf が 1 回だけ確認を求める
   - そのときは、fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y` と答える。違っていれば `N` で中断する

---

## 更新

- `epel-release` と、EPEL から入れたパッケージは、通常の `sudo dnf upgrade` に含まれる

1. EPEL の設定（`epel-release`）を更新する。

   ```bash
   sudo dnf upgrade epel-release
   ```

   - extras から入れた直後なら、`10-6.el10` が EPEL の `10-8.el10_2` などに上がる
   - EPEL の署名鍵をまだ取り込んでいなければ、ここで確認を求められる（[手順 3](#実施手順) の fingerprint と照らす）
   - 更新が無ければ `Nothing to do.` で終わる

---

## ロールバック

> [!WARNING]
> **EPEL を消しても、EPEL から入れたパッケージ（btop・distrobox・podman-compose・podman-tui・VirtualBox の `liblzf` など）は残り、更新されなくなる**。要らないものは、先に各手順書のロールバックで消す。

- [RPM Fusion](rpmfusion.md) を入れたホストでは、先に [rpmfusion.md のロールバック](rpmfusion.md#ロールバック)を行う（残っていると、この節の手順 1 で `rpmfusion-free-release` も一緒に消える）

1. `epel-release` を消す。

   ```bash
   sudo dnf remove --noautoremove epel-release
   ```

   - `Removing:` が `epel-release` の 1 つだけになる
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. EPEL の鍵も消すときだけ、その署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-e37ed158-65785fa9
   ```

   - 鍵は、EPEL からパッケージを入れたことがあるときだけ登録されている（参考資料を参照）

---

## 注意点

- **Homebrew と同じ名前の実行ファイルは二重に入れない**: 例えば EPEL の `fd-find` は `/usr/bin/fd` を置く。Homebrew の `fd` と両方入れると、PATH の先頭の Homebrew 版が使われ、`dnf upgrade` で上がるのは使われないほうになる（[導入元一覧](tool-catalog.md#導入経路と-el10-での注意)、[btop.md の注意点](btop.md#注意点)）
- **EPEL は AlmaLinux の配布物ではない**: Fedora のプロジェクトが作るリポジトリ。AppStream / BaseOS にあるパッケージは、そちらを使う
- **ほかの手順書のロールバックでは EPEL を消さない**: EPEL を使う手順書が複数ある。消すときはこの文書の[ロールバック](#ロールバック)で行う
