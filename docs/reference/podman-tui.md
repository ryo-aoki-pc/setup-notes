# podman-tui インストール手順（AlmaLinux 10 / EPEL）の参考資料

[手順書](../podman-tui.md)

## 補足

### 実施手順 / 手順 1: 補足: 依存と、podman との関係

podman-tui は Go で書かれた 1 つの実行ファイルで、`rpm -q --requires podman-tui` に出る依存は glibc（`libc.so.6`・`libresolv.so.2`）だけ。

### 実施手順 / 手順 4: 補足: 画面の中身と、つながらないとき

[この節の検証記録](../verification/podman-tui.md#実施手順--手順-4-補足-画面の中身とつながらないとき)

- `localhost` は、podman-tui が `XDG_RUNTIME_DIR` から作る既定の接続。設定ファイルは要らない
- `unix://run/...` とスラッシュが 2 つなのは podman-tui の書き方で、つながっている
- `m` のメニューは、`attach`・`checkpoint`・`commit`・`create`・`diff`・`exec`・`healthcheck`・`inspect`・`kill`・`logs`・`pause`・`port`・`prune`・`rename`・`restore`・`rm`・`run`・`start`・`stats`・`stop`・`top`・`unpause` の順。1.10.0 には、項目を選ぶキーの割り当ては無い

API ソケットが止まっていると、`Connection:` が `❌ STATUS_ERROR` に、`localhost` が `❌ connection error` になり、次のエラーの枠が出る:

```
unable to connect to Podman socket: Get "http://d/v5.7.1/
libpod/_ping": dial unix /run//user/<UID>/podman/
podman.sock: connect: connection refused
```

- `Ctrl+C` で終了し、`systemctl --user start podman.socket` で起動し直す
- `v5.7.1` は、podman-tui が使っている podman の API の版（1.10.0 は podman 5.7.1 の部品で作られている）

### 参照

- [containers/podman-tui — README（v1.10.0）](https://github.com/containers/podman-tui/blob/v1.10.0/docs/README.md) — 互換表、API ソケットの前提、キーの一覧
- [podman-tui v2.0.0 のリリースノート](https://github.com/containers/podman-tui/releases/tag/v2.0.0) — podman v6 への対応、接続を podman の設定からだけ読むこと
- `podman-tui --help`、画面の `F1`
- [Podman](../podman.md) — 前提の rootless の podman と API ソケット
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 前提の EPEL の有効化（手順 17）

---
