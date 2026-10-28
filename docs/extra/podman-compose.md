# podman-compose の注意点

[手順書](../containers.md#podman-compose)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/podman-compose.md)・[参考資料](../reference/podman-compose.md)

- 「手順 N」は[手順書](../containers.md#podman-compose)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **`podman-compose exec` が動いている間に貼った行は、コンテナへの入力になる**。`exec` が終了してプロンプトに戻ってから次の手順を貼る
  - `-T` は擬似端末を付けないだけで、標準入力はつながったままなので、入力を止める用途には使わない
  - 手順 6 のように、`exec` はブロックの最後に置く
- **PC の再起動では戻らず、linger が無いとログアウトで止まる**: compose で起動したコンテナは、ふつうの `podman run -d` と同じ（[Podman の注意点](podman.md#注意点)）。常駐させるものは Quadlet にし、[linger](../almalinux-setup.md#ユーザーサービスの常駐) を有効にする
- **プロジェクトの名前はディレクトリの名前**: 同じ名前のディレクトリで別の compose ファイルを動かすと、同じ名前の pod・ネットワークを使う。`-p <名前>` で変えられる
- **`down -v` はボリュームの中身も消す**: `down` だけなら名前付きのボリュームは残る（[使い方の基本](../containers.md#podman-compose-使い方の基本)）
- **1024 未満のポートは使えない**: rootless の podman と同じ制限（[Podman の注意点](podman.md#注意点)）
- **`:Z` をホームやシステムのディレクトリに付けない**: 付けるのはコンテナ用のディレクトリだけ（[Podman の注意点](podman.md#注意点)）
