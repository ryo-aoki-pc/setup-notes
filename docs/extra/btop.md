# btop インストール手順（AlmaLinux 10 / EPEL）のロールバックと注意点

[手順書](../btop.md)・[検証記録](../verification/btop.md)・[参考資料](../reference/btop.md)

- 「手順 N」は[手順書](../btop.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

1. btop を消す。

   ```bash
   sudo dnf remove btop
   ```

   - 依存で入った `hicolor-icon-theme` は他のパッケージも使うので、残しておいてよい（不要なものだけ消すなら `sudo dnf autoremove`）
   - **EPEL 自体は消さない**（他のパッケージが依存している可能性がある）。消すなら [AlmaLinux 10 の初期設定のロールバックの「Flatpak・RPM Fusion・EPEL を消す」](almalinux-setup.md#flatpakrpm-fusionepel-を消す)の手順 7・8
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
- **設定は初回起動まで作られない**: [検証記録](../verification/btop.md)・[参考資料](../reference/btop.md)
- **`htop` とは別物**: 同時に入れても衝突しない
