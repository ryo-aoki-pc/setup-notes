# podman-tui の注意点

[手順書](../containers.md#podman-tui)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/podman-tui.md)・[参考資料](../reference/podman-tui.md)

- 「手順 N」は[手順書](../containers.md#podman-tui)の手順 N、「本書」「この文書」は手順書を指す

## 注意点

- **終了は `Ctrl+C`**: `q` を押しても何も起きない
- **API ソケットが止まっていると、つながらない**: `❌ STATUS_ERROR` とエラーの枠が出る（参考資料を参照）。`systemctl --user start podman.socket` で直る
- **podman に接続を登録していると、そちらを使う**: `podman system connection add` で登録した接続があると、podman-tui は `localhost` の代わりにそれを出す
  - 接続を消す（`podman system connection remove`）と、`localhost` に戻る
- **Homebrew の 2.x と二重に入れない**: `brew install podman-tui` の 2.0.0 は `/home/linuxbrew/.linuxbrew/bin` に入り、PATH の先頭で `/usr/bin/podman-tui` を隠す
  - 2.0.0 は接続を podman の設定からだけ読むため、使う場合は先に接続を登録する
  - 2.0.0 と podman 5.8.2 は上流の互換表の外の組み合わせなので、互換表に合う版を選ぶ
- **EPEL が 2.x に上がったら、互換表を確かめる**: 2.x は podman 6 向け。AlmaLinux の podman が 5.x のうちに EPEL だけが上がったら、動きを確かめてから使う
