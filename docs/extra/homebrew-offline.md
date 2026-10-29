# Homebrew のオフライン導入の注意点

[手順書](../almalinux-setup.md#homebrew-のオフライン導入)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/homebrew-offline.md)・[参考資料](../reference/homebrew-offline.md)

- 「手順 N」は[手順書](../almalinux-setup.md#homebrew-のオフライン導入)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## 注意点

- **トンネルそのものの注意は、[SSH の SOCKS トンネル の注意点](ssh-socks-tunnel.md#注意点)**: 転送中はオフラインのホストのどのユーザーもプロキシを使える、出口はオンラインのホスト、`socks5h` の `h`、`https_proxy` が勝つ、`sudo` は `ALL_PROXY` を渡さない、dnf の行が残る
- **`sudo brew` はもともと使えない**: [AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)
- **ほかの手順書の `sudo dnf` も、手順 2 を行ったときだけ通る**: [シェルと端末のセットアップの「HackGen Console NF」](../shell-terminal.md#hackgen-console-nf)の手順 3（`unzip`）は、dnf の設定で通った
- **トンネルが要るのは、取得するときだけ**: `brew install` / `brew update` / `brew upgrade` は要る。`brew list` / `brew uninstall` / `brew autoremove` は要らない
  - トンネル無しの `brew install hello` は、`curl: (6) Could not resolve host: ghcr.io` と `Error: Failed to download resource "hello"` で失敗した
- **brew は、依存が付くときに `[y/n]` を聞く**: ほかの Homebrew 系の手順書の `brew install` でも、端末から実行すると同じように聞かれる（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）
- **ssh が切れると、トンネルも消える**: 途中の `brew install` や dnf は、取得の途中なら失敗するはず。そのときは [SSH の SOCKS トンネルの手順 2](../almalinux-setup.md#ssh-の-socks-トンネル) から張り直して、同じコマンドを貼り直す
- **入れた後もネットワークを使うツールは、オフラインのホストではその部分が動かない**: たとえば外部の API を呼ぶ処理や、LAN の外の端末との同期
