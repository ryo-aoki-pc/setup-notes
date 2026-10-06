# linger 有効化手順（AlmaLinux 10 / ログアウト中も自分のユーザーの systemd を動かす）の参考資料

[手順書](../linger.md)

## 補足

### 選択した方針

- **ユーザーのサービス + linger にする**: 常駐させるものを、同期するファイルやコンテナの持ち主のユーザーで動かす。root も cron も要らない
  - 代わりに root が管理するシステムのサービス（Syncthing の `syncthing@<USER>.service` など）にすれば linger は要らないが、使う側の手順書はどれもユーザーのサービスにしている（[syncthing.md の選択した方針](syncthing.md#選択した方針)）
- **確認は `loginctl show-user` で行う**: `Linger=` の値は logind が持つ状態そのもの。`/var/lib/systemd/linger/<USER>` のファイルは、その記録
- **独立した手順書にした**: linger を使う手順書が 4 本になり、同じ有効化・確認・ロールバックの手順が各文書に重なっていたため

### 参照

- `man loginctl`（`enable-linger` / `disable-linger` / `show-user`）
- `man logind.conf`（`KillUserProcesses=`）/ `man user@.service`

---
