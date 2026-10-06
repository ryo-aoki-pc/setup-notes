# RPM Fusion（free）有効化手順（AlmaLinux 10）の参考資料

[手順書](../rpmfusion.md)

## 補足

### 選択した方針

- **署名を確かめて入れる**: Configuration の `--nogpgcheck` の例は使わず、keys ページの方法（鍵を先に取り込み、`localpkg_gpgcheck=1`）にした（手順 3 の補足）
- **free だけ**: 本書を使う [Firefox の AAC・H.264](../firefox.md#実施手順) は、free の `ffmpeg-libs` で足りる。nonfree は有効にしない
- **EPEL を前提にする**: `rpmfusion-free-release` が `epel-release` を要求し、RPM Fusion の Configuration も EPEL を先に有効にする順で書いている（手順 3 の補足）
- **独立した手順書にした**: リポジトリの有効化と、Firefox のために FFmpeg を入れることを分けた。EPEL の [epel.md](../epel.md) と同じ扱い

### 参照

- [Configuration — RPM Fusion](https://rpmfusion.org/Configuration) — free / nonfree の区別と、EL 向けの有効化（EPEL を先に有効にすること、`--nogpgcheck` の例、Alma・Rocky の `crb enable`）
- [Trusting Package Integrity — RPM Fusion](https://rpmfusion.org/keys) — 鍵の fingerprint と、鍵を先に取り込んで `localpkg_gpgcheck=1` で入れる方法
- `man dnf.conf`（`localpkg_gpgcheck`）
- [EPEL](../epel.md) — 前提の手順書

---
