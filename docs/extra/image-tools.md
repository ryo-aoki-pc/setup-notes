# 画像の道具の注意点

[手順書](../almalinux-setup.md#画像の道具)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/image-tools.md)・[参考資料](../reference/image-tools.md)

- 「手順 N」は[手順書](../almalinux-setup.md#画像の道具)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **dive の `--ci` の既定の基準は厳しい**: ベースイメージの層の無駄も数えるので、よく使われるイメージを元にしただけで `FAIL` になる（参考資料を参照）。CI で使うなら、基準を自分で決めて `.dive-ci` に書く
- **Trivy の結果は日によって変わる**: データベースは新しい脆弱性が見つかるたびに更新される。同じイメージでも、後日の結果は変わりうる
- **Trivy の `--image-src podman` は API ソケットが要る**: [Podmanの手順 7](../containers.md#podman) のソケットが止まっていると、手順 9 の補足のエラーになる
- **hadolint と Trivy の設定の検査は、見るところが違う**: 確認用の Containerfile は hadolint では指摘が無く、`trivy config` では `USER` と `HEALTHCHECK` が無いことを指摘された（[使い方の基本](../almalinux-setup.md#画像の道具-使い方の基本)）
- **Homebrew の 2 つは、そのままでは `sudo` の PATH に無い**（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）: root で使うなら、[AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う)の節を通すか、`/home/linuxbrew/.linuxbrew/bin/hadolint` のようにフルパスで呼ぶ
