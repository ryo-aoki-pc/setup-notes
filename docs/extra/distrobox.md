# Distrobox の注意点

[手順書](../containers.md#distrobox)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/distrobox.md)・[参考資料](../reference/distrobox.md)

- 「手順 N」は[手順書](../containers.md#distrobox)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **ボックスは隔離ではない**: ホームを共有し、ホストのファイルシステム全体が `/run/host` に見え、ネットワークとプロセスもホストと同じ（参考資料を参照）。信用できないソフトを試す場所にはしない
- **ボックスの `sudo` はホストの root ではない**: 本書の `--userns keep-id` では、ボックスの root はホストの subordinate UID に対応する。自分の UID はボックス内の同じ UID に対応し、ホストの root の権限は得られない
- **`distrobox enter` の実行中に新たに貼った文字は、ボックスへの入力になる**: 同じ入力として最初に貼った後ろの行は、`enter` の終了後に元のシェルで動く
  - `distrobox enter <名前> -- <コマンド>` と同じ入力に続けたホスト用のコマンドは、その処理が終わってからホストで動く
  - 次をボックス内で動かす場合は、ボックスのプロンプトが出てから別に貼る
- **書き出したスクリプトの名前が、ホストのコマンドと重なることがある**: `~/.local/bin` は PATH の途中にある
  - 同じ名前のコマンドがほかの場所にもあると、どちらが呼ばれるかは PATH の順で決まる
  - Homebrew の `brew shellenv` は、自分の場所を PATH の先頭に足す
- **`podman system reset` でボックスも消える**: ボックスは podman のコンテナなので、一緒に消える
- 必要な空き容量は、導入予定のパッケージとトランザクション表で確かめる
