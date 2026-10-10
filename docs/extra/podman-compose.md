# podman-compose インストール手順（AlmaLinux 10 / EPEL）のロールバックと注意点

[手順書](../podman-compose.md)・[検証記録](../verification/podman-compose.md)・[参考資料](../reference/podman-compose.md)

- 「手順 N」は[手順書](../podman-compose.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

- 上から順に実行する
- compose で動かしていたデータを残したいときは、この節の手順 2 の前に `~/compose-sample` から取り出しておく

1. コンテナ・pod・ネットワークを消す。

   ```bash
   cd ~/compose-sample
   podman-compose down
   podman pod ps
   ```

   - `podman pod ps` が見出しの行だけになればよい

1. 確認用の compose ファイルとページを消す。

   ```bash
   cd ~
   rm -rf ~/compose-sample
   ```

1. [podman.md の Quadlet](../podman.md#quadlet-で自動起動する任意)で同じイメージを使っていないときだけ、イメージを消す。

   ```bash
   podman rmi registry.access.redhat.com/ubi10/httpd-24:latest
   ```

   - 使っているコンテナが残っていると、消せずにエラーになる

1. podman-compose を消す。

   ```bash
   sudo dnf remove podman-compose
   ```

   - `[y/N]` で聞かれる。依存で入った Python のライブラリも、ほかに使うものが無ければ一緒に消える
   - **EPEL 自体は消さない**（ほかのパッケージが使っている可能性がある）。消すなら [AlmaLinux 10 の初期設定のロールバック](almalinux-setup.md#ロールバック)の手順 34・35

---

## 注意点

- **`podman-compose exec` が動いている間に貼った行は、コンテナへの入力になる**。`exec` が終了してプロンプトに戻ってから次の手順を貼る
  - `-T` は擬似端末を付けないだけで、標準入力はつながったままなので、入力を止める用途には使わない
  - 手順 6 のように、`exec` はブロックの最後に置く
- **PC の再起動では戻らず、linger が無いとログアウトで止まる**: compose で起動したコンテナは、ふつうの `podman run -d` と同じ（[podman.md の注意点](podman.md#注意点)）。常駐させるものは Quadlet にし、[linger](../linger.md) を有効にする
- **プロジェクトの名前はディレクトリの名前**: 同じ名前のディレクトリで別の compose ファイルを動かすと、同じ名前の pod・ネットワークを使う。`-p <名前>` で変えられる
- **`down -v` はボリュームの中身も消す**: `down` だけなら名前付きのボリュームは残る（[使い方の基本](../podman-compose.md#使い方の基本)）
- **1024 未満のポートは使えない**: rootless の podman と同じ制限（[podman.md の注意点](podman.md#注意点)）
- **`:Z` をホームやシステムのディレクトリに付けない**: 付けるのはコンテナ用のディレクトリだけ（[podman.md の注意点](podman.md#注意点)）
