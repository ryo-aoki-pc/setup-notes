# Dropbox を rclone で同期する手順（AlmaLinux 10 / Raspberry Pi 5 / Homebrew + systemd ユーザータイマー）の参考資料

[手順書](../dropbox-rclone.md)

[検証記録](../verification/dropbox-rclone.md#参考資料から分離した記録)

## 補足

### 実施手順 / 手順 5: 補足: フィルタの中身

- 前の 6 行は、rclone の bisync の文書にある「Example filters file for Dropbox」の、Dropbox が同期しないファイルの行をそのまま使った（Office の一時ファイル、Windows の `desktop.ini` など）
- **`- *.partial` は本書で足した**。rclone は転送中のファイルを `<名前>.<16 進>.partial` として書き、終わってから名前を変える
  - `kill -9` や電源断で止まると書きかけが残るため、`*.partial` を除外する
- このファイルは、手順 7・8 と手順 9 の timer から、いつも `--filters-file` で渡す。bisync は中身のハッシュを `~/.config/rclone/dropbox-filters.txt.md5` に覚えていて、変えたのに `--resync` をしないと止まる（[同期するフォルダを変える（任意）](../dropbox-rclone.md#同期するフォルダを変える任意)）

### 実施手順 / 手順 7: 補足: Path1 と Path2、--resync の意味

- `dropbox:` が Path1、`~/Dropbox` が Path2。`--resync` は、両方にあって中身が違うファイルでは Path1（Dropbox）を正とし（`--resync-mode path1`）、片方にしか無いファイルはもう片方へコピーする
- `--resync` は最初の 1 回と、フィルタを変えたときだけ使う。ふだんの同期（手順 9 の timer）には付けない
- `--max-lock 2m` は、途中で止まったときに残るロックを 2 分で切らせる（手順 8 の補足）
- アカウントが大きいと、ファイルの数だけ行が出る

### 実施手順 / 手順 9: 補足: unit の中身の理由

- **rclone は絶対パスで書く**。systemd は `~/.bashrc` を読まないので、Homebrew の PATH が無い。`/home/linuxbrew/.linuxbrew/bin/rclone` は `brew upgrade` で付け替わるリンクなので、更新しても書き換えなくてよい
- `%h` は systemd がホームディレクトリに置き換える
- `Type=oneshot` なので、`systemctl --user start` は同期が終わるまで戻らない。timer は、前の回が動いている間は次を始めない
- フラグは、rclone の bisync の文書が無人で回すときに勧めている組み合わせ
  - `--resilient`: 軽いエラーのあと、`--resync` をしなくても次の回で続けられる
  - `--recover`: 途中で止まっても、次の回で自動で回復する
  - `--max-lock 2m`: 途中で止まって残ったロックを 2 分で切らせる
  - `--conflict-resolve newer`: 両方で変わったファイルは新しい方を残す（古い方は `<名前>.conflict1` として残る）
- `OnBootSec=5min` は起動から 5 分後、`OnUnitInactiveSec=15min` は前の同期が終わってから 15 分後に動かす
  - `OnUnitInactiveSec` は 1 回動いた後から効く。手順 10 で 1 回動かしておく
  - 動く時刻は最大 1 分ずれる（systemd の既定の `AccuracySec=1min`）
- ユーザーの systemd からは `network-online.target` を使えないので、起動直後はつながっていないことがある。`OnBootSec` で 5 分待ち、失敗しても `--resilient` で次の回に続ける

### 選択した方針

同期の仕方:

### 参照

- [Bisync — rclone](https://rclone.org/bisync/) — `--resync`、`--resilient` / `--recover` / `--max-lock`、フィルタの例（Dropbox）、ロックと graceful shutdown
- [Dropbox — rclone](https://rclone.org/dropbox/) — 認証、自分の app key、batch のアップロード
- [Remote Setup — rclone](https://rclone.org/remote_setup/) — 画面の無いマシンでの認証（`rclone authorize`、SSH のトンネル）
- [Filtering — rclone](https://rclone.org/filtering/) — フィルタのファイルの書き方
- [Homebrew Formulae — rclone](https://formulae.brew.sh/formula/rclone) — 版とボトル（`arm64_linux`）
- `man systemd.timer`（`OnBootSec=` / `OnUnitInactiveSec=` / `AccuracySec=`）/ `man systemd.service`（`Type=oneshot`）/ `man loginctl`（`enable-linger`）
- [linger](../linger.md) — 前提の手順書（ログアウト中もユーザーの systemd を動かす）

---
