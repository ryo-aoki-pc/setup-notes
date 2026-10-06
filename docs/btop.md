# btop インストール手順（AlmaLinux 10 / EPEL）

## 実施手順

- [検証記録](verification/btop.md)・[参考資料](reference/btop.md)

> [!IMPORTANT]
> - **前提**: [EPEL](epel.md) を有効にしてあること。`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す
> - **すべて対象ホスト上で実行する**
> - **手順 1 には対話入力がある**（トランザクション表の `[y/N]` と鍵の確認）。答えてから手順 2 を貼る
> - **手順 2 で TUI が開く**。`q` で終了してから手順 3 を貼る

- 上から順にコードブロックを貼る
- 手順の後: 設定を書く場所は[設定ファイル](#設定ファイル)、以後は[更新](#更新)・[ロールバック](#ロールバック)

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
   - EPEL が新しい版を出すまでは上がらない（[注意点](#注意点)）

---

## ロールバック

1. btop を消す。

   ```bash
   sudo dnf remove btop
   ```

   - 依存で入った `hicolor-icon-theme` は他のパッケージも使うので、残しておいてよい（不要なものだけ消すなら `sudo dnf autoremove`）
   - **EPEL 自体は消さない**（他のパッケージが依存している可能性がある）。消すなら [epel.md のロールバック](epel.md#ロールバック)
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. 設定とユーザーテーマも消すときだけ、`~/.config/btop` を消す。

   ```bash
   rm -rf ~/.config/btop        # 設定とユーザーテーマも消す場合
   ```

---

## 注意点

- **EPEL 版は `GPU_SUPPORT=false` でビルドされている**: `btop --version` の 3 行目にそう出る。GPU の使用率パネルは出ない
  - Raspberry Pi では元々使えないので実害は無いが、GPU 監視が目的なら別経路を検討する
- **EPEL が遅れると版が止まる**: 今は upstream と同じ 1.4.7 だが、EPEL の更新が止まれば古いままになる。そのときは Homebrew 版に移せる
  - **ただし `/usr/bin/btop` と Homebrew 版を両方入れると、PATH の先頭にある Homebrew 版が勝ち、`dnf upgrade` で上がるのは使われないほうになる。片方だけにする**
- **表示は端末の UTF-8 とカラーに依存する**: 記号が崩れるときは `--force-utf`、色がおかしいときは `-l`（256 色）や `-t`（TTY モード）を試す
- **root で起動しなくても動く**: ただし他ユーザーのプロセスの詳細（コマンドライン全体など）は見えないことがある
  - 全部見たいなら `sudo btop`（RPM なので、何も足さずに root の PATH にも入っている。ここが Homebrew 版との違い）
- **設定は初回起動まで作られない**: [検証記録](verification/btop.md)・[参考資料](reference/btop.md)
- **`htop` とは別物**: 同時に入れても衝突しない
