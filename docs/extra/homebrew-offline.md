# Homebrew をインターネットに出られないホストで使う手順（AlmaLinux 10 / ssh -R の SOCKS プロキシ）のロールバックと注意点

[手順書](../homebrew-offline.md)・[検証記録](../verification/homebrew-offline.md)・[参考資料](../reference/homebrew-offline.md)

- 「手順 N」は[手順書](../homebrew-offline.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる

## ロールバック

- オフラインのホストで貼る。トンネルは要らない
- Homebrew ごと消すなら、この節の手順 1 の代わりに、[ssh-socks-tunnel.md の手順 1〜3](../ssh-socks-tunnel.md#実施手順) でトンネルを張ったシェルで [AlmaLinux 10 の初期設定のロールバックの「Homebrew と bash-completion を消す」](almalinux-setup.md#homebrew-と-bash-completion-を消す)の手順 1〜3 を行う（アンインストーラを取得するため。本書では実行していない）
- [手順 2](../homebrew-offline.md#実施手順) で dnf にプロキシを設定したときは、[ssh-socks-tunnel.md のロールバック](ssh-socks-tunnel.md#ロールバック)で dnf の行を消す

1. 手順 4 で入れた jq を使わないときだけ、jq と、一緒に入った依存を消す。

   ```bash
   brew uninstall jq
   brew autoremove
   printf '\n\033[7m 確認 \033[0m\n'
   brew list --versions
   ```

   - `brew autoremove` は、依存として入って、もうどの formula も使っていないものを消す（[AlmaLinux 10 の初期設定の Homebrew の使い方の基本](../almalinux-setup.md#homebrew-の使い方の基本)）
   - 最後の一覧に `jq` が無ければよい

---

## 注意点

- **トンネルそのものの注意は、[ssh-socks-tunnel.md の注意点](ssh-socks-tunnel.md#注意点)**: 転送中はオフラインのホストのどのユーザーもプロキシを使える、出口はオンラインのホスト、`socks5h` の `h`、`https_proxy` が勝つ、`sudo` は `ALL_PROXY` を渡さない、dnf の行が残る
- **`sudo brew` はもともと使えない**: [AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)
- **ほかの手順書の `sudo dnf` も、手順 2 を行ったときだけ通る**: [AlmaLinux 10 の初期設定の「HackGen Console NF」](../almalinux-setup.md#hackgen-console-nf)の手順 3（`unzip`）は、dnf の設定で通った
- **トンネルが要るのは、取得するときだけ**: `brew install` / `brew update` / `brew upgrade` は要る。`brew list` / `brew uninstall` / `brew autoremove` は要らない
  - トンネル無しの `brew install hello` は、`curl: (6) Could not resolve host: ghcr.io` と `Error: Failed to download resource "hello"` で失敗した
- **brew は、依存が付くときに `[y/n]` を聞く**: ほかの Homebrew 系の手順書の `brew install` でも、端末から実行すると同じように聞かれる（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）。当時の bat.md の手順 2（依存が 8 つ）でも聞かれた（参考資料を参照）
- **ssh が切れると、トンネルも消える**: 途中の `brew install` や dnf は、取得の途中なら失敗するはず。そのときは [ssh-socks-tunnel.md 手順 2](../ssh-socks-tunnel.md#実施手順) から張り直して、同じコマンドを貼り直す
- **入れた後もネットワークを使うツールは、オフラインのホストではその部分が動かない**: たとえば [dropbox-rclone.md](../dropbox-rclone.md) の同期（Dropbox の API）や、[syncthing.md](../syncthing.md) の LAN の外の端末との同期
