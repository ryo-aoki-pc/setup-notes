# EPEL 有効化手順（AlmaLinux 10 / extras の epel-release）

## 実施手順

> [!IMPORTANT]
> - **すべて対象ホスト上で実行する**

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 以後は[更新](#更新)・[ロールバック](#ロールバック)
- 通すと使えるようになるもの:
  - [btop](btop.md)、[distrobox](distrobox.md)、[podman-compose](podman-compose.md)、[podman-tui](podman-tui.md)、[VirtualBox](virtualbox.md)（依存の `liblzf`）
  - [RPM Fusion（free）](rpmfusion.md)と、それを使う [Firefox の AAC・H.264](firefox.md#実施手順)
  - [導入元一覧](tool-catalog.md)で導入元が EPEL の行（fastfetch・duf・mosh・restic・Chromium・KeePassXC・Meld・GNOME Tweaks・Remmina）

> [!WARNING]
> **手順 2（`epel-release` の導入）は、コンテナとクリーンな x86_64 の VM で通した**（[対象と検証環境](#対象と検証環境)）。
>
> - x86_64 の実機は EPEL が有効だったので、手順 1・3 だけ通した
> - aarch64 の実機では、[RPM Fusion](rpmfusion.md) の依存として `epel-release` が入った

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

   <details>
   <summary>補足: 一緒に入るものと、CRB の案内</summary>

   素のコンテナでは、`epel-release` と、弱い依存の `dnf-plugins-core` の 2 つが入った:

   ```
   Installing:
    epel-release            noarch        10-6.el10            extras         18 k
   Installing weak dependencies:
    dnf-plugins-core        noarch        4.7.0-10.el10        baseos         37 k
   ```

   - `dnf-plugins-core` は `dnf config-manager` のパッケージ。元から入っているホストでは入らない
   - SELinux のポリシー（`selinux-policy`）が入っているホストでは、CRB の `selinux-policy-extra` と `selinux-policy-targeted-extra` も入る
     - `epel-release` の弱い依存 `(selinux-policy-epel if selinux-policy)` を満たすため
     - aarch64 の実機で、`epel-release` が [RPM Fusion](rpmfusion.md) の依存として入ったときの記録（[firefox.md の付録](firefox.md#付録-実機での本実行2026-09-28)）

   最後に scriptlet がこのメッセージを出す:

   ```
   Many EPEL packages require the CodeReady Builder (CRB) repository.
   It is recommended that you run /usr/bin/crb enable to enable the CRB repository.
   ```

   AlmaLinux 10 では CRB が既定で有効（素のコンテナでも `dnf repolist enabled` に `crb` がある）なので、`crb enable` は要らない。

   extras の `epel-release` は `10-6.el10` で、EPEL 自身が出している `10-8.el10_2` より古い。**一度 EPEL が有効になれば、[更新](#更新)で EPEL の `epel-release` に上がる**ので、差は放っておいてよい。

   </details>

1. EPEL が有効になったか確かめる。

   ```bash
   rpm -q epel-release
   dnf repolist enabled | grep -E '^epel'
   ```

   - `epel-release` の版と、`epel` の行が出れば有効になっている
   - EPEL の署名鍵は、EPEL からパッケージを最初に入れるとき（各手順書の導入の手順）に、dnf が 1 回だけ確認を求める
   - そのときは、fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを確かめてから `y` と答える。違っていれば `N` で中断する

   <details>
   <summary>補足: 出力例と、EPEL の鍵</summary>

   コンテナでの出力:

   ```
   $ rpm -q epel-release
   epel-release-10-6.el10.noarch
   $ dnf repolist enabled | grep -E '^epel'
   epel                 Extra Packages for Enterprise Linux 10 - x86_64
   ```

   `epel-release` は、repo ファイル（`/etc/yum.repos.d/epel.repo` と、無効の `epel-testing.repo`）と、鍵のファイル `/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10` を置く。

   dnf は鍵をこのローカルファイルから取り込む。**[gh.md](gh.md) や [rpmfusion.md](rpmfusion.md) のように、公開鍵を HTTPS で取りに行く手順は要らない。** コンテナで、EPEL の btop を入れたときの途中の表示:

   ```
   Importing GPG key 0xE37ED158:
    Userid     : "Fedora (epel10) <epel@fedoraproject.org>"
    Fingerprint: 7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158
    From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10
   Key imported successfully
   ```

   取り込んだ鍵は、`rpm -q gpg-pubkey` に `gpg-pubkey-e37ed158-65785fa9` として出る（[ロールバック](#ロールバック)の手順 2 で使う）。

   </details>

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
- この節の手順はコンテナと x86_64 の VM で本実行した

1. `epel-release` を消す。

   ```bash
   sudo dnf remove --noautoremove epel-release
   ```

   - `Removing:` が `epel-release` の 1 つだけになる
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: --noautoremove を付ける理由</summary>

   付けないと、手順 2 で弱い依存として入った `dnf-plugins-core` も「使われなくなった依存」として一緒に消える（コンテナでの実測）。`dnf config-manager` のパッケージで、[zoxide.md](zoxide.md) などでも使うので残す。

   ```
   Removing:
    epel-release           noarch       10-6.el10              @extras        25 k
   Removing unused dependencies:
    dnf-plugins-core       noarch       4.7.0-10.el10          @baseos        22 k
   ```

   RPM Fusion が残っている状態では、`Removing dependent packages:` に `rpmfusion-free-release` が出た。

   </details>

1. EPEL の鍵も消すときだけ、その署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-e37ed158-65785fa9
   ```

   - 鍵は、EPEL からパッケージを入れたことがあるときだけ登録されている（手順 3 の補足）

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 で EPEL（Extra Packages for Enterprise Linux。Fedora のプロジェクトが EL 向けに作る追加のパッケージ）を有効にし、AppStream / BaseOS に無い RPM を dnf で入れられるようにする
- **進め方**: AlmaLinux の `extras` にある `epel-release` を入れる。読者が編集する変数は無い
  - もとは [btop.md](btop.md) などの手順の中にあった 3 つの手順を、共有の前提として 1 本にした
- **状態**: **手順 2 はコンテナと x86_64 の VM で検証済み（VM は 2026-10-06）。手順 1・3 は x86_64 の実機でも通した**
  - 手順 1〜3 のコマンドは、この文書に移す前に、EPEL を使う手順書の検証で通したもの
    - コンテナ: [btop.md](btop.md#付録-コンテナでの検証記録2026-09-22)（2026-09-22、aarch64）、[virtualbox.md](virtualbox.md#付録-コンテナでの検証記録2026-09-24)（2026-09-24）、[distrobox.md](distrobox.md#付録-コンテナでの検証記録2026-09-27)・[podman-compose.md](podman-compose.md#付録-コンテナでの検証記録2026-09-27)（2026-09-27）、[podman-tui.md](podman-tui.md#付録-コンテナでの検証記録2026-09-28)（2026-09-28）。aarch64 と明記したもの以外は x86_64
    - x86_64 の実機（[virtualbox.md の本実行](virtualbox.md#付録-実機での本実行2026-09-29)、2026-09-28）: EPEL が有効だったので、手順 1・3 だけ通した
  - 2026-09-29 に、この文書のブロックを x86_64 のコンテナでもう一度通した（[付録](#付録-コンテナでの検証記録2026-09-29)）
    - 手順 1〜3、[更新](#更新)、[ロールバック](#ロールバック)
    - [rpmfusion.md](rpmfusion.md) を続けて通し、そのロールバックの後にこの文書のロールバックを行った
  - **確認していないこと**: 実機での手順 2（`dnf install epel-release`）
    - aarch64 の実機では、`epel-release` は RPM Fusion の依存として入った（[firefox.md の付録](firefox.md#付録-実機での本実行2026-09-28)）

| 項目 | x86_64 の実機 | 検証コンテナ（2026-09-29） |
|---|---|---|
| 実施日 | 2026-09-28（[virtualbox.md](virtualbox.md) の中で） | 2026-09-29 |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64（AMD のノート PC） | 同左（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1） |
| dnf | 4.20.0 | 4.20.0 |
| EPEL | **有効**（`epel-release-10-8.el10_2`。手順 2 は不要） | 未設定 → 手順 2 で `epel-release-10-6.el10` を導入 → [更新](#更新)で `10-8.el10_2` |

> [!NOTE]
> 出力例の値は `<USER>` / `<HOSTNAME>` のプレースホルダで書いてある。`epel-release` の版は実行日によって変わる。**鍵の fingerprint は公開情報なので本文に書いてある。**

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 選択した方針

- **extras の `epel-release` を入れる**: AlmaLinux のリポジトリから入り（鍵の確認は出なかった）、URL を書かずに済む
  - EPEL の文書（Getting Started）は、EL10 向けに `dnf config-manager --set-enabled crb` の後、Fedora のサイトの `epel-release-latest-10.noarch.rpm` を URL で入れる方法を載せている
  - AlmaLinux では extras に `epel-release` があるので、URL の方法は使わない（試していない）
- **CRB は有効にしない**: AlmaLinux 10 では既定で有効（[導入元一覧](tool-catalog.md#導入経路と-el10-での注意)）
- **鍵は先に取り込まない**: 最初に EPEL のパッケージを入れるときに、dnf がローカルのファイルから取り込む。確認は 1 回だけで、使う側の手順書の導入の手順にそう書いてある
- **独立した手順書にした**: EPEL を使う手順書が 5 本と [RPM Fusion](rpmfusion.md) になり、同じ 3 つの手順が各文書に重なっていたため

### 注意点

- **Homebrew と同じ名前の実行ファイルは二重に入れない**: 例えば EPEL の `fd-find` は `/usr/bin/fd` を置く。Homebrew の `fd` と両方入れると、PATH の先頭の Homebrew 版が使われ、`dnf upgrade` で上がるのは使われないほうになる（[導入元一覧](tool-catalog.md#導入経路と-el10-での注意)、[btop.md の注意点](btop.md#注意点)）
- **EPEL は AlmaLinux の配布物ではない**: Fedora のプロジェクトが作るリポジトリ。AppStream / BaseOS にあるパッケージは、そちらを使う
- **ほかの手順書のロールバックでは EPEL を消さない**: EPEL を使う手順書が複数ある。消すときはこの文書の[ロールバック](#ロールバック)で行う

### 参照

- [EPEL — Fedora Docs](https://docs.fedoraproject.org/en-US/epel/) — EPEL とは何か。入れ方は同じ文書の [Getting Started](https://docs.fedoraproject.org/en-US/epel/getting-started/)（CRB と `epel-release`）
- `man dnf`（`remove` の `--noautoremove`）
- [導入元一覧の導入経路と EL10 での注意](tool-catalog.md#導入経路と-el10-での注意) — EPEL とほかの導入元の比較

---

### 付録: コンテナでの検証記録（2026-09-29）

**環境**: Ubuntu 24.04 / x86_64 のクラウドホスト上の Docker 29.3.1 で、`quay.io/almalinuxorg/almalinux:10`（`sha256:8322019282c6f7d253888ec688d6b90675963f31c4692709177e25eb9301c4c8`、AlmaLinux 10.2）を非特権・`--network host` で立てた。実機で加えた変更は無い。

**手順書の外で行った準備**（検証環境の都合）:

- プロキシの CA を信頼ストアに足し、dnf にプロキシを設定した
- プロキシが平文の HTTP を通さないので、AlmaLinux のミラー一覧の URL に `?protocol=https`、EPEL の metalink に `&protocol=https` を足した（EPEL は手順 2 の直後）
- `sudo` と `gnupg2` を入れ、NOPASSWD の `sudo` を与えた非 root ユーザーを作った

**流し方**: 同じ作りのコンテナで 2 回通した。どちらも非 root ユーザーのログインシェルで実行し、`dnf install` / `dnf upgrade` / `dnf remove` には `-y` を付けた。

- 1 回目: 本文と同じコマンドを手で打った。手順書の外のコマンドも混ぜて、下の箇条書きのことを確かめた
- 2 回目: 新しいコンテナで、この文書と [rpmfusion.md](rpmfusion.md) の bash のブロックをファイルから抜き出して流した。順番は、手順 1〜3 → rpmfusion.md の手順 1〜4 → [更新](#更新) → rpmfusion.md のロールバック → [ロールバック](#ロールバック)

2 回目の結果:

| 手順 | 結果 |
|---|---|
| 1. 確かめる | `EPEL は未設定`（有効なのは appstream / baseos / crb / extras の 4 つ） |
| 2. 導入 | `epel-release-10-6.el10`（extras）と、弱い依存の `dnf-plugins-core-4.7.0-10.el10`（baseos）の 2 つ。scriptlet が CRB の案内を出した |
| 3. 確かめる | `epel-release-10-6.el10.noarch` と `epel                 Extra Packages for Enterprise Linux 10 - x86_64` |
| 更新 | `epel-release` が `10-6.el10`（extras）から `10-8.el10_2`（epel）に上がった。EPEL の鍵が未登録だったので、ここで `Importing GPG key 0xE37ED158:` が出た（`-y` で取り込まれた） |
| ロールバック | 先に rpmfusion.md のロールバックを行った。手順 1 の `Removing:` は `epel-release`（`10-8.el10_2`、`@epel`）の 1 つだけで、`dnf-plugins-core` は残った。手順 2 で鍵（`gpg-pubkey-e37ed158-65785fa9`）が消え、`dnf repolist enabled` から `epel` の行が消えた |

- ロールバックで、`epel.repo` と `epel-testing.repo` が `.rpmsave` として残った。検証のために metalink を書き換えていたため（書き換えた設定ファイルを rpm が残す）

1 回目に確かめたこと:

- 手順 3 の補足の鍵の表示は、手順書の外で EPEL の btop を入れたときのもの
- `epel-release` を消した後も、EPEL から入れた btop は残った（[ロールバック](#ロールバック)のアラート）
- `--noautoremove` を付けない `dnf remove --assumeno epel-release` では、`dnf-plugins-core` も消える表になった
- RPM Fusion を入れた状態の `dnf remove --assumeno epel-release` では、`rpmfusion-free-release` が `Removing dependent packages:` に出た

#### 未確認事項

- 実機での手順 2 と、aarch64 での手順 2（aarch64 は、この文書に移す前の [btop.md の付録](btop.md#付録-コンテナでの検証記録2026-09-22)でコンテナでのみ通した）
- 実機での[更新](#更新)と[ロールバック](#ロールバック)
- SELinux が有効なホストで、手順 2 が `selinux-policy-extra` を入れること（RPM Fusion の依存で入ったときの記録しか無い）

### 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を ISO から新規に入れた VirtualBox の VM（x86_64、1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で、検証用ユーザーの SSH PTY に現行のブロックを個別に貼った。利用者のアカウントは使っていない。

実施手順 1〜3、更新、ロールバック 1・2 を本実行した。未設定の状態から extras の `epel-release-10-6.el10` と CRB の `selinux-policy-extra`・`selinux-policy-targeted-extra`（ともに `42.1.18-4.el10_2.3`）の計 3 パッケージが入った。Workstation に `dnf-plugins-core` は既にあったため追加されなかった。CRB は既定で有効だった。別のクリーン VM でも同じ 3 パッケージが入った。

続けて Firefox の FFmpeg を入れるとき、EPEL 10 の署名鍵の fingerprint と uid を照合して取り込めた。更新の手順は `epel-release-10-8.el10_2` への 1 パッケージの upgrade になった。実機での手順 2 と aarch64 の今回の実行は確認していない。

ロールバックは RPM Fusion を先に外してから行い、`--noautoremove` で epel-release だけが消えた。EPEL の署名鍵も削除できた。SELinux の extra ポリシーは残した。

### 付録: 現行版の新規 VM での再検証（2026-10-06）

公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active）で、`5da3478` の本文を SSH 対話 PTY に渡した。試験専用のユーザー・鍵と設定値を使用し、利用者の実アカウントの資格情報は持ち込んでいない。

実施手順 1〜3 を通した。未設定の状態から extras の epel-release-10-6.el10 と、CRB の selinux-policy-extra / selinux-policy-targeted-extra が入り、epel が有効になった。CRB は OS の既定で有効で、追加の有効化は行っていない。この再検証では更新・ロールバックを実行していない。
