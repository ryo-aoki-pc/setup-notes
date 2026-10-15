# ユーザーサービスの常駐の参考資料

[手順書](../almalinux-setup.md#ユーザーサービスの常駐)・[ロールバックと注意点](../extra/linger.md)

## 補足

### ユーザーサービスの常駐 / 手順 1: 補足: 有効になっているとき

- `Linger=yes` が出るのは、ほかの手順書で有効にしてあるとき

### ユーザーサービスの常駐 / 手順 2: 補足: linger

- linger を有効にすると、ログインしていない間もユーザーの systemd が動き続ける

### 選択した方針

- **ユーザーのサービス + linger にする**: 常駐させるものを、同期するファイルやコンテナの持ち主のユーザーで動かす。root も cron も要らない
  - 代わりに root が管理するシステムのサービス（Syncthing の `syncthing@<USER>.service` など）にすれば linger は要らないが、使う側の手順書はどれもユーザーのサービスにしている（[Syncthing の選択した方針](syncthing.md#選択した方針)）
- **確認は `loginctl show-user` で行う**: `Linger=` の値は logind が持つ状態そのもの。`/var/lib/systemd/linger/<USER>` のファイルは、その記録

### 参照

- `man loginctl`（`enable-linger` / `disable-linger` / `show-user`）
- `man logind.conf`（`KillUserProcesses=`）/ `man user@.service`

---
