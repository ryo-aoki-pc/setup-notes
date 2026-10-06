# RPM Fusion（free）有効化手順（AlmaLinux 10）

## 実施手順

- [検証記録](verification/rpmfusion.md)・[参考資料](reference/rpmfusion.md)

> [!IMPORTANT]
> - **前提**: [EPEL](epel.md) を有効にしてあること。`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す
> - **すべて対象ホスト上で実行する**
> - **手順 3 には対話入力がある**（トランザクション表の `[y/N]`）。答えてから次の手順を貼る

- 上から順にコードブロックを貼る
- 手順の後: 以後は[更新](#更新)・[ロールバック](#ロールバック)
- 有効にするのは free だけ。nonfree は扱わない
- 通すと使えるようになるもの: [Firefox の AAC・H.264](firefox.md#実施手順)（firefox.md の手順 8 から。RPM Fusion の `ffmpeg-libs` を入れる）

1. RPM Fusion（free）の署名鍵を落として、取り込む前に fingerprint と uid を確かめる。

   ```bash
   curl -fsSL 'https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-el-10' | gpg --show-keys
   ```

   - `gpg` が無ければ、`sudo dnf install -y gnupg2` で入れてから貼り直す
   - `pub` 行の fingerprint が `5FC4AE73FC2B08B9DFE7EB990C8489D8DB85DDD7`
   - uid が `RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org>`
   - 違っていればここで止める
   - **次の手順は、この 2 つを目で確かめてから貼る**

1. 一致したら、鍵を rpm に取り込み、入ったか確かめる。

   ```bash
   {
     sudo rpm --import 'https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-el-10'
     rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i fusion
   }
   ```

   - `rpm --import` は何も表示しない
   - `gpg-pubkey-db85ddd7-67a63d8b RPM Fusion free repository for EL (10) ...` の 1 行が出れば、取り込めている

1. RPM Fusion（free）のリポジトリを入れる。

   ```bash
   sudo dnf --setopt=localpkg_gpgcheck=1 install https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-10.noarch.rpm
   ```

   - `--setopt=localpkg_gpgcheck=1` を外さない（外すと、手順 2 の鍵で署名を確かめずに入る。[検証記録](verification/rpmfusion.md)・[参考資料](reference/rpmfusion.md)）
   - EPEL が有効なホストでは、`Installing:` が `rpmfusion-free-release` の 1 つだけになる
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. RPM Fusion（free）が有効になったか確かめる。

   ```bash
   rpm -q rpmfusion-free-release
   dnf repolist enabled | grep -E '^rpmfusion'
   ```

   - `rpmfusion-free-release` の版と、`rpmfusion-free-updates` の行が出れば有効になっている

---

## 更新

- `rpmfusion-free-release` と、RPM Fusion から入れたパッケージ（Firefox の `ffmpeg-libs` など）は、通常の `sudo dnf upgrade` に含まれる

---

## ロールバック

- RPM Fusion から入れたパッケージを先に消す。Firefox の FFmpeg なら、[firefox.md のロールバック](firefox.md#ロールバック)の手順 1
  - 残したまま RPM Fusion を消すと、そのパッケージは更新されなくなる
- EPEL は、この節では消さない（消すなら [epel.md のロールバック](epel.md#ロールバック)）

1. RPM Fusion（free）のリポジトリを消す。

   ```bash
   sudo dnf remove --noautoremove rpmfusion-free-release
   ```

   - `Removing:` が `rpmfusion-free-release` の 1 つだけになる
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. RPM Fusion の鍵も消すときだけ、その署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-db85ddd7-67a63d8b
   ```

---

## 注意点

- **RPM Fusion は Fedora の外のリポジトリ**: free は「Fedora がライセンス以外の理由で配れないオープンソースのソフト」を配る（RPM Fusion の Configuration の説明）
  - 鍵は手順 1 で照合し、`rpmfusion-free-release` の署名も手順 3 で確かめる
- **EL10 向けは中身が少ない**: 調べた範囲では、free に `ffmpeg` 7.1.5 と `gstreamer1-plugins-bad-freeworld`、nonfree に `steam`（i686）がある。mpv は無い（[導入元一覧](tool-catalog.md#導入経路と-el10-での注意)）
- **EPEL の FFmpeg（`ffmpeg-free` 系）と同居できないものがある**: RPM Fusion の `ffmpeg-libs` は、EPEL の `libavcodec-free` と衝突する（[firefox.md 手順 9](firefox.md#実施手順)）
