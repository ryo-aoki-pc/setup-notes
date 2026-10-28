# ユーザーサービスの常駐の注意点

[手順書](../almalinux-setup.md#ユーザーサービスの常駐)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/linger.md)・[参考資料](../reference/linger.md)

- 「手順 N」は[手順書](../almalinux-setup.md#ユーザーサービスの常駐)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **linger はユーザーごとに 1 つで、使う側の手順書で共有する**: どれか 1 本で有効にすれば、ほかの手順書では手順 1 で `Linger=yes` を確かめるだけでよい。切るのは、どれも使わなくなったときだけ
- **ログアウト中も動かすなら、PC を眠らせない**: linger はサスペンドを止めない（[AlmaLinux 10 の初期設定の「画面オフ・画面ロック・自動サスペンドを止める」](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める)。Workstation で入れた PC は、ログイン画面のまま 15 分で眠る）
- **`sudo -iu` で切り替えたシェルでは、`systemctl --user` が失敗する**: `XDG_RUNTIME_DIR` が無いため（[Podman の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/podman.md)・[参考資料](../reference/podman.md)）。常駐させるユーザーで、直接ログインしたシェルを使う
