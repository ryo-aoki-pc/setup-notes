# hadolint / dive / Trivy インストール手順（AlmaLinux 10 / Homebrew + Trivy 公式 dnf リポジトリ）のロールバックと注意点

[手順書](../image-tools.md)・[検証記録](../verification/image-tools.md)・[参考資料](../reference/image-tools.md)

- 「手順 N」は[手順書](../image-tools.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- 上から順に実行する

1. 確認用のイメージとファイルを消す。

   ```bash
   podman rmi localhost/image-check:1 registry.access.redhat.com/ubi10/httpd-24:10.1
   rm -rf ~/image-check
   ```

1. Trivy のデータベースを消す。

   ```bash
   rm -rf ~/.cache/trivy
   ```

   - Trivy のキャッシュも消す場合は、キャッシュの置き場所を確かめてから削除する

1. hadolint と dive を消す。

   ```bash
   brew uninstall hadolint dive
   ```

   - 依存として入った `gmp` など 4 つも、ほかに使うものが無ければ一緒に消える（`==> Autoremoving 4 unneeded formulae:`）

1. Trivy を消す。

   ```bash
   sudo dnf remove trivy
   ```

   - `[y/N]` で聞かれる
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. Trivy のリポジトリの登録と、取り込んだ鍵を消して、消えたか確かめる。

   ```bash
   {
     sudo rm /etc/yum.repos.d/trivy.repo && sudo rpm -e gpg-pubkey-4fd9ca9f-69e0b811
     printf '\n\033[7m 確認 \033[0m\n'
     rpm -q gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n'
   }
   ```

   - 一覧から `trivy-repo <oss@aquasec.com>` の行が消えていればよい

---

## 注意点

- **dive の `--ci` の既定の基準は厳しい**: ベースイメージの層の無駄も数えるので、よく使われるイメージを元にしただけで `FAIL` になる（参考資料を参照）。CI で使うなら、基準を自分で決めて `.dive-ci` に書く
- **Trivy の結果は日によって変わる**: データベースは新しい脆弱性が見つかるたびに更新される。同じイメージでも、後日の結果は変わりうる
- Trivy のキャッシュも消す場合は、キャッシュの置き場所を確かめてから削除する
- **Trivy の `--image-src podman` は API ソケットが要る**: [podman.md 手順 7](../podman.md#実施手順) のソケットが止まっていると、手順 9 の補足のエラーになる
- **hadolint と Trivy の設定の検査は、見るところが違う**: 確認用の Containerfile は hadolint では指摘が無く、`trivy config` では `USER` と `HEALTHCHECK` が無いことを指摘された（[使い方の基本](../image-tools.md#使い方の基本)）
- **Homebrew の 2 つは、そのままでは `sudo` の PATH に無い**（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）: root で使うなら、[AlmaLinux 10 の初期設定の Homebrew を sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通すか、`/home/linuxbrew/.linuxbrew/bin/hadolint` のようにフルパスで呼ぶ
