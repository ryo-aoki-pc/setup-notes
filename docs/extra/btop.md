# btop の注意点

[手順書](../almalinux-setup.md#btop)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/btop.md)・[参考資料](../reference/btop.md)

- 「手順 N」は[手順書](../almalinux-setup.md#btop)の手順 N、「本書」「この文書」は手順書を指す

## 注意点

- **EPEL 版は `GPU_SUPPORT=false` でビルドされている**: `btop --version` の 3 行目にそう出る。GPU の使用率パネルは出ない
  - Raspberry Pi では元々使えないので実害は無いが、GPU 監視が目的なら別経路を検討する
- **EPEL が遅れると版が止まる**: 今は upstream と同じ 1.4.7 だが、EPEL の更新が止まれば古いままになる。そのときは Homebrew 版に移せる
  - **ただし `/usr/bin/btop` と Homebrew 版を両方入れると、PATH の先頭にある Homebrew 版が勝ち、`dnf upgrade` で上がるのは使われないほうになる。片方だけにする**
- **表示は端末の UTF-8 とカラーに依存する**: 記号が崩れるときは `--force-utf`、色がおかしいときは `-l`（256 色）や `-t`（TTY モード）を試す
- **root で起動しなくても動く**: ただし他ユーザーのプロセスの詳細（コマンドライン全体など）は見えないことがある
  - 全部見たいなら `sudo btop`（RPM なので、何も足さずに root の PATH にも入っている。ここが Homebrew 版との違い）
- **設定は初回起動まで作られない**: [検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/btop.md)・[参考資料](../reference/btop.md)
- **`htop` とは別物**: 同時に入れても衝突しない
