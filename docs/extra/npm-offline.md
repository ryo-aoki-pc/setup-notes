# npm をインターネットに出られないホストで使う手順（AlmaLinux 10 / AppStream の Node.js / Neovim の Mason）のロールバックと注意点

[手順書](../npm-offline.md)・[検証記録](../verification/npm-offline.md)・[参考資料](../reference/npm-offline.md)

- 「手順 N」は[手順書](../npm-offline.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

## ロールバック

- オフラインのホストで貼る。トンネルは要らない
- `https_proxy` はどこにも書いていないので、戻すものは無い
- dnf のプロキシの行は、[ssh-socks-tunnel.md のロールバック](ssh-socks-tunnel.md#ロールバック)の手順 1 で消す
- Mason で入れたものは、`:MasonUninstall <名前>` で消せる（設定にあるものは、次にトンネルのあるシェルで開いたときに入り直す）

> [!WARNING]
> **この節の手順 1 で Node.js を消すと、Mason で入れた npm のパッケージは動かなくなる**（どれも `#!/usr/bin/env node` で始まる）。Mason を使い続けるなら、この節は行わない。

1. [手順 1](../npm-offline.md#実施手順) で入れた Node.js と npm を、ほかに使わないときだけ消す。

   ```bash
   sudo dnf remove -y nodejs nodejs-npm
   ```

   - [手順 1](../npm-offline.md#実施手順) で一緒に入った依存（`libuv`・`openssl` など）も消え、合わせて 9 パッケージが消える

1. npm のキャッシュとログを消す。

   ```bash
   rm -rf ~/.npm
   command -v node npm || echo '無い（期待どおり）'
   ```

   - `無い（期待どおり）` が出ればよい
   - Mason のパッケージ（`~/.local/share/nvim/mason/packages`）は残る

---

## 注意点

- **npm だけは `ALL_PROXY` では足りない**: [手順 2](../npm-offline.md#実施手順) の `export` を飛ばさない。Mason の npm パッケージが導入に失敗して再試行を繰り返す
- **`sudo` は `https_proxy` を渡さない**: `sudo printenv https_proxy` は何も出さなかった。`sudo npm install -g` のような使い方は、本書では扱わない
- **Homebrew の node が入っていると、Mason はそちらの npm を使う**: Mason は PATH の先頭の `npm` を使い、`brew shellenv` は Homebrew の `bin` を PATH の先頭に置く。[手順 2](../npm-offline.md#実施手順) の `command -v` で確かめる
- **PyPI のパッケージは入らない**: Mason は PyPI のパッケージを、仮想環境の pip で入れる。その pip は SOCKS のプロキシを使えない
  - GitHub のリリースから入るもの（ruff など）は、この問題が無い
- **npm 以外の理由でも失敗する**: `unzip` が無い場合もパッケージを導入できない。足りないコマンドを確認する
  - 足りないコマンドは、`:checkhealth mason` の `WARNING unzip: not available` のような行で見られる
  - トンネルのシェルで `sudo dnf install -y unzip` を実行してから開き直す
- **Mason のパッケージの一覧は、24 時間ごとに取り直そうとする**: トンネルの無いときに開くと、取り直しに失敗する
  - `:Mason` の画面に `Registry installation failed with the following error:` と出る
  - 入れたパッケージはそのまま使える
  - 一覧を取り直すのは、次にトンネルのあるシェルで開いたとき（[更新](../npm-offline.md#更新)）
- **トンネルが無いときに開くと、設定にあって入っていないパッケージの導入が毎回失敗する**: 画面での編集には影響しない
- **ssh が切れると、トンネルも消える**: 途中の導入は失敗する。[ssh-socks-tunnel.md 手順 2](../ssh-socks-tunnel.md#実施手順) から張り直し、[手順 2・3](../npm-offline.md#実施手順) を貼り直す
