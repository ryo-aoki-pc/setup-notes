# btop インストール手順（AlmaLinux 10 / EPEL）の参考資料

[手順書](../btop.md)・[ロールバックと注意点](../extra/btop.md)

## 補足

### 実施手順 / 手順 1: 補足: 依存

- 依存として `hicolor-icon-theme`（デスクトップエントリのアイコン用）が、まだ無ければ一緒に入る

### 設定ファイル / 手順 1: 補足: よく使う起動オプション

`btop --help` の全文より抜粋:

| オプション | 意味 |
|---|---|
| `-p, --preset <id>` | プリセット（0-9）を指定して起動 |
| `-t, --tty` / `--no-tty` | TTY モードの強制・強制解除（16 色と ASCII 寄りの記号になる） |
| `-l, --low-color` | true color を使わず 256 色にする |
| `--force-utf` | ロケール判定を無視して UTF-8 として扱う |
| `-u, --update <ms>` | 更新間隔 |
| `-f, --filter <filter>` | プロセスの絞り込みを指定して起動 |
| `-c, --config <file>` | 設定ファイルを指定 |
| `--default-config` | 既定の設定を標準出力に出す |

### 参照

- [aristocratos/btop — README](https://github.com/aristocratos/btop) — 機能、キーバインド、設定項目、テーマの書式
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 前提の手順書（「EPEL と RPM Fusion」の手順 1 の `epel-release` の入れ方と、CRB の案内）
- `btop --help` / `btop --default-config` — 起動オプションと既定の設定
- `man btop` — RPM に同梱

---
