# btop インストール手順（AlmaLinux 10 / EPEL）

## 実施手順

- [検証記録](verification/btop.md)・[参考資料](reference/btop.md)・[ロールバックと注意点](extra/btop.md)

> [!IMPORTANT]
> - **前提**: [AlmaLinux 10 の初期設定の手順 17](almalinux-setup.md#実施手順) で EPEL を有効にしてあること。`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す
> - **すべて対象ホスト上で実行する**
> - **手順 1 には対話入力がある**（トランザクション表の `[y/N]` と鍵の確認）。答えてから手順 2 を貼る
> - **手順 2 で TUI が開く**。`q` で終了してから手順 3 を貼る

- 上から順にコードブロックを貼る
- 手順の後: 設定を書く場所は[設定ファイル](#設定ファイル)、以後は[更新](#更新)・[ロールバック](extra/btop.md#ロールバック)

1. 入手できる版を見てから、btop を入れる。

   ```bash
   dnf -q list --showduplicates btop
   sudo dnf install btop
   ```

   - 版は `btop.aarch64  1.4.7-1.el10_2  epel` のように 1 つだけ出る
   - 依存として `hicolor-icon-theme`（デスクトップエントリのアイコン用）が、まだ無ければ一緒に入る
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを目で確かめてから `y` と答える。違っていれば `N` で中断する
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. btop が入ったか確かめ、起動する。

   ```bash
   btop --version
   command -v btop
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' btop
   btop
   ```

   - `btop version: 1.4.7` と `/usr/bin/btop` が出てから、btop の画面が開く
   - 画面が出たら `q` で終了する
   - **次の手順は、`q` で終了してから貼る**（続けて貼ると btop への操作として食われる）

1. 初回の起動で `~/.config/btop/btop.conf` が作られたか確かめる。

   ```bash
   ls -l ~/.config/btop
   ```

   - `btop.conf` と `themes/` があればよい

---

## 設定ファイル

- `~/.config/btop/btop.conf` は**初回起動時に既定値で作られる**（約 9.8 KB、項目ごとにコメント付き）
- アプリ内では `Esc` または `m` でメニューが開き、`Options` からほとんどの項目を GUI で変えられる（保存も btop がやる）
- テーマは 2 か所から読む。`btop.conf` の `color_theme` にファイル名を書くと切り替わる（`"Default"` と `"TTY"` は組み込み）
  - `/usr/share/btop/themes/`: RPM が入れる既定のテーマ（`dracula` / `nord` / `gruvbox-*` / `adwaita-dark` など）
  - `~/.config/btop/themes/`: 自分で足すテーマ

1. 起動せずに、既定の設定だけを見る。

   ```bash
   btop --default-config | head -20
   ```

---

## 更新

- btop は通常の更新に含まれる

1. btop を更新する。

   ```bash
   sudo dnf upgrade btop
   ```

   - システム全体なら `sudo dnf upgrade`
   - EPEL が新しい版を出すまでは上がらない（[注意点](extra/btop.md#注意点)）
