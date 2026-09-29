# RPM Fusion（free）有効化手順（AlmaLinux 10）

## 実施手順

> [!IMPORTANT]
> - **前提**: [EPEL](epel.md) を有効にしてあること。`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す
> - **すべて対象ホスト上で実行する**
> - **手順 2・4 には対話入力がある**（手順 2 は `sudo` のパスワード、手順 4 はトランザクション表の `[y/N]`）。答えてから次の手順を貼る

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 以後は[更新](#更新)・[ロールバック](#ロールバック)
- 有効にするのは free だけ。nonfree は扱わない
- 通すと使えるようになるもの: [Firefox の AAC・H.264](firefox.md#実施手順)（firefox.md の手順 8 から。RPM Fusion の `ffmpeg-libs` を入れる）

1. RPM Fusion（free）の署名鍵を落として、取り込む前に fingerprint と uid を確かめる。

   ```bash
   curl -fsSL 'https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-el-10' | gpg --show-keys
   ```

   - `pub` 行の fingerprint が `5FC4AE73FC2B08B9DFE7EB990C8489D8DB85DDD7`
   - uid が `RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org>`
   - 違っていればここで止める
   - **次の手順は、この 2 つを目で確かめてから貼る**

   <details>
   <summary>補足: 鍵の出所</summary>

   鍵は RPM Fusion の [keys](https://rpmfusion.org/keys) ページの添付ファイル。同じページの「RPM Fusion free for EL 10」の fingerprint（`5FC4 AE73 FC2B 08B9 DFE7 EB99 0C84 89D8 DB85 DDD7`）と一致した:

   ```
   pub   rsa4096 2025-02-07 [SC]
         5FC4AE73FC2B08B9DFE7EB990C8489D8DB85DDD7
   uid                      RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org>
   ```

   `gpg` は `gnupg2` のコマンド。素のコンテナには入っていなかったので、検証では先に入れた。

   `gpg` を初めて使うユーザーでは、`pub` 行の前に `~/.gnupg` を作ったという行が出る。鍵の照合には関係ない。x86_64 の実機では次の 2 行、2026-09-29 のコンテナでは 1 行目だけが出た:

   ```
   gpg: directory '/home/<USER>/.gnupg' created
   gpg: /home/<USER>/.gnupg/trustdb.gpg: trustdb created
   ```

   </details>

1. 一致したら、鍵を rpm に取り込む。

   ```bash
   sudo rpm --import 'https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-el-10'
   ```

   - 何も表示されずに終われば、取り込めている
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. 鍵が入ったか確かめる。

   ```bash
   rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i fusion
   ```

   - `gpg-pubkey-db85ddd7-67a63d8b RPM Fusion free repository for EL (10) ...` の 1 行が出る

1. RPM Fusion（free）のリポジトリを入れる。

   ```bash
   sudo dnf --setopt=localpkg_gpgcheck=1 install https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-10.noarch.rpm
   ```

   - `--setopt=localpkg_gpgcheck=1` を外さない（外すと、手順 2 の鍵で署名を確かめずに入る。この手順の補足）
   - EPEL が有効なホストでは、`Installing:` が `rpmfusion-free-release` の 1 つだけになる
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 署名の確認と、EPEL を前提にした理由</summary>

   **署名の確認**: dnf 4.20 の既定は `localpkg_gpgcheck = 0` で、URL やファイルで渡したパッケージの署名を確かめない。`--setopt=localpkg_gpgcheck=1` を付けると確かめる。手順 2 の鍵が無いコンテナでは、次のように止まって何も入らなかった:

   ```
   Public key for rpmfusion-free-release-10.noarch.rpm is not installed
   The downloaded packages were saved in cache until the next successful transaction.
   You can remove cached packages by executing 'dnf clean packages'.
   Error: GPG check FAILED
   ```

   - RPM Fusion の [Configuration](https://rpmfusion.org/Configuration) は、EL 向けに `--nogpgcheck` で入れる例を載せている
   - 一方 [keys](https://rpmfusion.org/keys) の「Verify GPG signatures on install」は、鍵を先に取り込んで `localpkg_gpgcheck=1` で入れる方法を案内しており、本書は後者にした
   - `mirrors.rpmfusion.org` はミラーへリダイレクトする（2026-09-28 の aarch64 のコンテナでは `mirrors.ustc.edu.cn`）ので、署名で確かめる意味がある

   **EPEL を前提にした理由**: `rpmfusion-free-release` は `epel-release >= 10` を要求する。RPM Fusion の Configuration も、EL では RPM Fusion より先に EPEL を有効にするよう書いている。

   EPEL が有効なホストで入るのは、`rpmfusion-free-release` の 1 つだけだった（x86_64 の実機と、2026-09-29 のコンテナ）:

   ```
   Installing:
    rpmfusion-free-release       noarch       10-1        @commandline        10 k
   ```

   EPEL を有効にしていないホストでも、`epel-release` が依存として extras から一緒に入るので、この手順は通る。

   - 素のコンテナ（2026-09-28）では、`rpmfusion-free-release`・`epel-release`・弱い依存の `dnf-plugins-core` の 3 つが入った
   - aarch64 の実機（GNOME のデスクトップ、SELinux は Enforcing）では、`dnf-plugins-core` の代わりに CRB の `selinux-policy-extra` と `selinux-policy-targeted-extra` が入り、4 パッケージになった（[epel.md 手順 2 の補足](epel.md#実施手順)）

   ```
   Packages Altered:
       Install selinux-policy-extra-42.1.18-4.el10_2.3.noarch          @crb
       Install selinux-policy-targeted-extra-42.1.18-4.el10_2.3.noarch @crb
       Install epel-release-10-6.el10.noarch                           @extras
       Install rpmfusion-free-release-10-1.noarch                      @@commandline
   ```

   依存で入った `epel-release` は、[ロールバック](#ロールバック)で一緒に消えやすい（その手順 1 の補足）。本書では EPEL を前提にして、[epel.md](epel.md) で先に入れる。

   </details>

1. RPM Fusion（free）が有効になったか確かめる。

   ```bash
   rpm -q rpmfusion-free-release
   dnf repolist enabled | grep -E '^rpmfusion'
   ```

   - `rpmfusion-free-release` の版と、`rpmfusion-free-updates` の行が出れば有効になっている

   <details>
   <summary>補足: 出力例と、置かれるファイル</summary>

   2026-09-29 のコンテナでの出力:

   ```
   $ rpm -q rpmfusion-free-release
   rpmfusion-free-release-10-1.noarch
   $ dnf repolist enabled | grep -E '^rpmfusion'
   rpmfusion-free-updates      RPM Fusion for EL 10 - Free - Updates
   ```

   - repo ファイルは `/etc/yum.repos.d/rpmfusion-free-updates.repo`（有効）と `rpmfusion-free-updates-testing.repo`（無効）
   - 鍵のファイル `/etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-el-10` も置かれる
   - 有効になった後は、例えば `dnf -q list --showduplicates ffmpeg-libs` に `rpmfusion-free-updates` の行が出る（[firefox.md 手順 8](firefox.md#実施手順)）

   </details>

---

## 更新

- `rpmfusion-free-release` と、RPM Fusion から入れたパッケージ（Firefox の `ffmpeg-libs` など）は、通常の `sudo dnf upgrade` に含まれる

---

## ロールバック

- RPM Fusion から入れたパッケージを先に消す。Firefox の FFmpeg なら、[firefox.md のロールバック](firefox.md#ロールバック)の手順 1
  - 残したまま RPM Fusion を消すと、そのパッケージは更新されなくなる
- EPEL は、この節では消さない（消すなら [epel.md のロールバック](epel.md#ロールバック)）
- この節の手順はコンテナで本実行した

1. RPM Fusion（free）のリポジトリを消す。

   ```bash
   sudo dnf remove --noautoremove rpmfusion-free-release
   ```

   - `Removing:` が `rpmfusion-free-release` の 1 つだけになる
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: --noautoremove を付ける理由</summary>

   `epel-release` が[手順 4](#実施手順) の依存として入ったホスト（EPEL を先に有効にしていなかったホスト）では、付けないと `epel-release` と `dnf-plugins-core` も「使われなくなった依存」として一緒に消える（2026-09-28 のコンテナでの実測）。EPEL はほかの手順書でも使い、`dnf-plugins-core` は `dnf config-manager` のパッケージなので残す。

   ```
   Removing:
    rpmfusion-free-release    noarch    10-1                @@commandline    3.8 k
   Removing unused dependencies:
    dnf-plugins-core          noarch    4.7.0-10.el10       @baseos           22 k
    epel-release              noarch    10-6.el10           @extras           25 k
   ```

   [epel.md](epel.md) で EPEL を先に入れたホストでは、付けなくても `rpmfusion-free-release` の 1 つだけだった（2026-09-29 のコンテナ）。

   </details>

1. RPM Fusion の鍵も消すときだけ、その署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-db85ddd7-67a63d8b
   ```

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 で RPM Fusion の free のリポジトリを有効にし、FFmpeg など Fedora・EL の標準のリポジトリに無いパッケージを dnf で入れられるようにする
- **進め方**: 鍵を照合して取り込み、署名を確かめながら `rpmfusion-free-release` を入れる。前提は [EPEL](epel.md)。読者が編集する変数は無い
  - もとは [firefox.md](firefox.md) の手順 8〜11 と、ロールバックの手順 2〜3 だった。Firefox の FFmpeg から、リポジトリの有効化を切り分けた
- **状態**: **手順 1〜4 は実機で本実行済み（2026-09-28）**。aarch64 と x86_64 の 2 台
  - aarch64 の実機（Raspberry Pi 5）: 利用者が手順どおりに入れた（[firefox.md の付録](firefox.md#付録-実機での本実行2026-09-28)）
    - 鍵（`gpg-pubkey-db85ddd7-67a63d8b`）が登録され、`dnf history` に手順 4 の実行（4 パッケージ）が残っている
    - EPEL は無かったので、手順 4 の依存で入った
  - x86_64 の実機（AMD のノート PC）: EPEL が入ったホストで手順 1〜4 のコマンドを実行した（[firefox.md の付録](firefox.md#付録-x86_64-の実機での本実行2026-09-28)）。手順 4 は `rpmfusion-free-release` の 1 つだけだった
  - コンテナ
    - 2026-09-28 の aarch64 のコンテナで、手順 1〜4 と[ロールバック](#ロールバック)を通した（[firefox.md の付録](firefox.md#付録-動画が再生できなかった件の切り分け2026-09-28)）
    - 2026-09-29 の x86_64 のコンテナで、[epel.md](epel.md) の後にこの文書のブロックを通した（手順 1〜5 とロールバック。[付録](#付録-コンテナでの検証記録2026-09-29)）
  - **手順 5 とロールバックは、コンテナでのみ検証**
  - **確認していないこと**: nonfree のリポジトリ、`rpmfusion-free-updates-testing`

| 項目 | aarch64 の実機 | x86_64 の実機 | 検証コンテナ（2026-09-29） |
|---|---|---|---|
| 実施日 | 2026-09-28 | 2026-09-28 | 2026-09-29 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | AlmaLinux 10.2 (Lavender Lion) / x86_64（AMD Strix Halo のノート PC） | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1） |
| dnf | 4.20.0 | 4.20.0 | 4.20.0 |
| SELinux | Enforcing | Enforcing | 無効（コンテナ） |
| 手順 4 の前の EPEL | 無し | 有効（鍵も登録済み） | [epel.md](epel.md) で有効にした |
| 手順 4 で入ったもの | `rpmfusion-free-release`・`epel-release`・`selinux-policy-extra`・`selinux-policy-targeted-extra` | `rpmfusion-free-release` だけ | `rpmfusion-free-release` だけ |

> [!NOTE]
> 出力例の値は `<USER>` / `<HOSTNAME>` のプレースホルダで書いてある。版（`10-1`）は実行日によって変わる。**鍵の fingerprint は公開情報なので本文に書いてある。**

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 選択した方針

- **署名を確かめて入れる**: Configuration の `--nogpgcheck` の例は使わず、keys ページの方法（鍵を先に取り込み、`localpkg_gpgcheck=1`）にした（手順 4 の補足）
- **free だけ**: 本書を使う [Firefox の AAC・H.264](firefox.md#実施手順) は、free の `ffmpeg-libs` で足りる。nonfree は有効にしない
- **EPEL を前提にする**: `rpmfusion-free-release` が `epel-release` を要求し、RPM Fusion の Configuration も EPEL を先に有効にする順で書いている（手順 4 の補足）
- **独立した手順書にした**: リポジトリの有効化と、Firefox のために FFmpeg を入れることを分けた。EPEL の [epel.md](epel.md) と同じ扱い

### 注意点

- **RPM Fusion は Fedora の外のリポジトリ**: free は「Fedora がライセンス以外の理由で配れないオープンソースのソフト」を配る（RPM Fusion の Configuration の説明）
  - 鍵は手順 1 で照合し、`rpmfusion-free-release` の署名も手順 4 で確かめる
- **EL10 向けは中身が少ない**: 調べた範囲では、free に `ffmpeg` 7.1.5 と `gstreamer1-plugins-bad-freeworld`、nonfree に `steam`（i686）がある。mpv は無い（[導入元一覧](tool-catalog.md#導入経路と-el10-での注意)）
- **EPEL の FFmpeg（`ffmpeg-free` 系）と同居できないものがある**: RPM Fusion の `ffmpeg-libs` は、EPEL の `libavcodec-free` と衝突する（[firefox.md 手順 9](firefox.md#実施手順)）

### 参照

- [Configuration — RPM Fusion](https://rpmfusion.org/Configuration) — free / nonfree の区別と、EL 向けの有効化（EPEL を先に有効にすること、`--nogpgcheck` の例、Alma・Rocky の `crb enable`）
- [Trusting Package Integrity — RPM Fusion](https://rpmfusion.org/keys) — 鍵の fingerprint と、鍵を先に取り込んで `localpkg_gpgcheck=1` で入れる方法
- `man dnf.conf`（`localpkg_gpgcheck`）
- [EPEL](epel.md) — 前提の手順書

---

### 付録: コンテナでの検証記録（2026-09-29）

**環境**: [epel.md の付録](epel.md#付録-コンテナでの検証記録2026-09-29)と同じコンテナで、epel.md の手順 1〜3 の後に行った（2 回）。実機で加えた変更は無い。

**手順書の外で行った準備**: epel.md の付録の準備に加えて、手順 4 の直後に RPM Fusion の metalink を `https://` にし、`&protocol=https` を足した（repo ファイルの metalink は `http://mirrors.rpmfusion.org/...` で、プロキシが平文の HTTP を通さないため）。

**流し方**: epel.md の付録と同じ。1 回目は本文と同じコマンドを手で打ち、2 回目は本文の bash のブロックをファイルから抜き出して流した。どちらも非 root ユーザーのログインシェルで、`dnf install` / `dnf remove` には `-y` を付けた。下の表は 2 回目で、どちらも同じ結果だった。

| 手順 | 結果 |
|---|---|
| 1. 鍵の照合 | fingerprint と uid が本文の値と一致。このユーザーは `gpg` を初めて使ったので、`gpg: directory '/home/<USER>/.gnupg' created` の 1 行が先に出た |
| 2. 取り込み | 何も表示せずに終わった |
| 3. 確かめる | `gpg-pubkey-db85ddd7-67a63d8b RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org> public key` |
| 4. リポジトリ | EPEL が有効なので、`Installing:` は `rpmfusion-free-release 10-1 @commandline` の 1 つだけ |
| 5. 確かめる | `rpmfusion-free-release-10-1.noarch` と `rpmfusion-free-updates      RPM Fusion for EL 10 - Free - Updates` |
| ロールバック | epel.md の[更新](epel.md#更新)の後に行った。手順 1 の `Removing:` は `rpmfusion-free-release` の 1 つだけ。手順 2 で鍵が消えた。続けて [epel.md のロールバック](epel.md#ロールバック)を行った |

- 1 回目は、手順 5 の後に手順書の外の `dnf -q list --showduplicates ffmpeg-libs` を実行し、`ffmpeg-libs.x86_64  7.1.5-1.el10  rpmfusion-free-updates` が出た
- 1 回目は、手順 4 の後の `dnf remove --assumeno rpmfusion-free-release`（`--noautoremove` 無し）も、`rpmfusion-free-release` の 1 つだけだった。`epel-release` を epel.md で入れたので、依存として入ったものではない
- ロールバックの後、metalink を書き換えた repo ファイルが `.rpmsave` として残った（[epel.md の付録](epel.md#付録-コンテナでの検証記録2026-09-29)と同じ）

#### 未確認事項

- 実機での手順 5 とロールバック
- aarch64 での手順 5
- nonfree のリポジトリと、`rpmfusion-free-updates-testing`
