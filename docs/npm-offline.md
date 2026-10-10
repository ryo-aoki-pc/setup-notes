# npm をインターネットに出られないホストで使う手順（AlmaLinux 10 / AppStream の Node.js / Neovim の Mason）

## 実施手順

- [検証記録](verification/npm-offline.md)・[参考資料](reference/npm-offline.md)・[ロールバックと注意点](extra/npm-offline.md)

> [!IMPORTANT]
> - **前提**: [ssh-socks-tunnel.md](ssh-socks-tunnel.md) の手順 1〜3 で、インターネットに出られないホスト（以下、オフラインのホスト）にトンネルを張り、同書の[dnf にもトンネルを使わせる（任意）](ssh-socks-tunnel.md#dnf-にもトンネルを使わせる任意)で dnf にプロキシを設定してあること（dnf の節を飛ばしていたら、手順 1 の前に行う）
> - **前提**: 同じトンネルで、[homebrew-offline.md](homebrew-offline.md) の Homebrew と、[Neovim](neovim.md) と、Mason を使う設定（LazyVim をもとにした自分用の設定など）を入れてあること
> - **手順 1〜3 は、ssh-socks-tunnel.md の手順 3 のシェル（オフラインのホストの、`sudo` できる自分のユーザー）のまま貼る**。手順 4 で同書の[トンネルを閉じる](ssh-socks-tunnel.md#トンネルを閉じる)の手順 1・2 を行い、手順 5 はログインし直したシェルで貼る
> - **手順 3 は Neovim の画面、手順 4 は ssh のログインがある**。終わってから次の手順を貼る

- 上から順にコードブロックを貼る
- 手順の後: 以後は[更新](#更新)・[ロールバック](extra/npm-offline.md#ロールバック)

> [!WARNING]
>
> - トンネルを張っている間は、オフラインのホストのどのユーザーも `127.0.0.1:1080` を通って外に出られる（[ssh-socks-tunnel.md の注意点](extra/ssh-socks-tunnel.md#注意点)）

1. ssh-socks-tunnel.md の手順 3 のシェルで、AppStream の Node.js と npm を入れる。

   ```bash
   sudo dnf install -y nodejs nodejs-npm
   ```

   - `nodejs`・`nodejs-npm` と不足する依存が入り、`Complete!` で終わる
   - `Failed to download metadata for repo` で止まったら、dnf がトンネルを通っていない
     - `Curl error (6)`（名前を引けない）なら、ssh-socks-tunnel.md の[dnf にもトンネルを使わせる（任意）](ssh-socks-tunnel.md#dnf-にもトンネルを使わせる任意)の設定が無い
     - `Curl error (7)`（`127.0.0.1 port 1080` につながらない）なら、トンネルが無い（同書の手順 2 から張り直す）

1. Node.js と npm を確かめ、npm にトンネルを使わせて、レジストリに届くか確かめる。

   ```bash
   node --version
   npm --version
   command -v node npm
   export https_proxy=socks5h://127.0.0.1:1080
   npm config get https-proxy
   npm config get proxy
   npm ping
   ```

   - `v22.23.2`、`10.9.8`、`/usr/bin/node`、`/usr/bin/npm` が出る
   - `/home/linuxbrew/.linuxbrew/bin/npm` が出たら、Homebrew の node が PATH で先に来ていて、Mason もそちらを使う（[注意点](extra/npm-offline.md#注意点)）
   - `npm config get` の 2 行は、どちらも `null`
   - ほかの値が出たら、`~/.npmrc` などの設定が `https_proxy` より優先される（参考資料を参照）
   - `npm notice PONG 148ms` のように `PONG` が出れば、npm はトンネルを通ってレジストリに届いている
   - `export` はこのシェルの中だけで有効。**トンネルを張り直したら、ssh-socks-tunnel.md の手順 3 に続けて、この手順を貼り直す**

1. 手順 2 のシェルで Neovim でファイルを開き、Mason に足りないパッケージを入れさせる。

   ```bash
   nvim -R ~/.config/nvim/init.lua
   ```

   - ファイルを開くと Mason が読み込まれ、設定にある足りないパッケージを入れ始める（LazyVim をもとにした設定なら、ツールと LSP サーバーの両方）
   - 入れ終わるたびに、`markdownlint-cli2 was successfully installed.` のような通知が出る
   - `:Mason` で画面を開くと、入れている間は `Installing` に `$ npm install markdown-toc@1.2.0` のような行が出る
   - npm のパッケージ（`markdownlint-cli2`・`json-lsp` など）が `Installed` に並べばよい
   - 手順 5 で使う `markdownlint-cli2` が設定に無ければ、`:MasonInstall markdownlint-cli2` で入れる。ほかの npm のパッケージも、同じように名前で入れられる
   - 失敗は通知が出ないことがある。`Installed` に並ばないものは、`:MasonLog` の `Installation failed for Package(name=…)` の行で理由を見る
   - npm 以外の理由（`unzip` が無い、など）で失敗したものは[注意点](extra/npm-offline.md#注意点)
   - 通知が出そろってから、`:qa` で閉じる（入れている途中で閉じると、確認無しにその導入が止まる）
   - LSP サーバーが 1 つも入らなかったら、`:qa` で閉じて、この手順をもう一度貼る（参考資料を参照）
   - **次の手順は、`:qa` で Neovim を閉じてから貼る**（続けて貼ると Neovim への入力として食われる）

1. [ssh-socks-tunnel.md の「トンネルを閉じる」](ssh-socks-tunnel.md#トンネルを閉じる)の手順 1・2 を貼り、トンネルを閉じて、転送を付けずにログインし直す。

   - その節の手順 1（`exit`）はオフラインのホストで、手順 2 はオンラインのホストで貼る
   - オンラインのホストのシェルで同書の手順 1 の変数が消えていたら（新しいシェルなど）、先に同書の手順 1 を貼る
   - **次の手順は、ログインし直してから貼る**（続けて貼るとパスワードへの答えとして食われる）

1. オフラインのホストで、トンネルが無くても Mason の npm のパッケージが動き、npm が外に出られないことを確かめる。

   ```bash
   env | grep -i _proxy
   ls ~/.local/share/nvim/mason/bin
   ~/.local/share/nvim/mason/bin/markdownlint-cli2 --help | head -n 1
   npm ping --fetch-retries=0 && echo '届いた（オフラインではない）' || echo '届かない（期待どおり）'
   ```

   - `env` は何も出さない（プロキシの変数は、手順 2 のシェルと一緒に消えた）
   - `ls` に、Mason で入れたコマンド（`markdownlint-cli2`・`vscode-json-language-server` など）が並ぶ
   - `markdownlint-cli2 v0.23.3 (markdownlint v0.41.1)` のような版の行が出る
   - 最後の行は、`ENOTFOUND` のエラーの後に `届かない（期待どおり）`

---

## 更新

- [ssh-socks-tunnel.md 手順 1〜3](ssh-socks-tunnel.md#実施手順) でトンネルを張り、そのシェルで[手順 2](#実施手順) を貼ってから、この節を貼る
- Node.js と npm は `sudo dnf upgrade` でも上がる（トンネルか、dnf が届くリポジトリが要る）

1. Node.js と npm を上げる。

   ```bash
   sudo dnf upgrade -y nodejs nodejs-npm
   ```

   - 上げるものが無ければ `Nothing to do.` で終わる

1. Neovim でファイルを開き、Mason のパッケージを上げる。

   ```bash
   nvim -R ~/.config/nvim/init.lua
   ```

   - `:MasonUpdate` で、Mason のパッケージの一覧を取り直す（`Successfully updated 1 registry.` の通知が出る）
   - `:Mason` の画面の `Installed` の見出しに `Press U to update 1 package (markdown-toc)` のような案内が出たら、`U` を押して上げる
   - 案内が無ければ、上げるものは無い
   - 上げ終わると `markdown-toc was successfully installed.` のような通知が出る。通知が出そろってから、`:qa` で閉じる
   - 画面の `Installing` の表示は、上げ終わっても残ることがある（`q` で閉じて `:Mason` で開き直すと、`Installed` に移っている）
   - **次の手順は、`:qa` で Neovim を閉じてから貼る**（続けて貼ると Neovim への入力として食われる）

1. オフラインのホストからログアウトして、トンネルを閉じる。

   ```bash
   exit
   ```
