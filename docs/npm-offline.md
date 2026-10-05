# npm をインターネットに出られないホストで使う手順（AlmaLinux 10 / AppStream の Node.js / Neovim の Mason）

## 実施手順

> [!IMPORTANT]
> - **前提**: [ssh-socks-tunnel.md](ssh-socks-tunnel.md) の手順 1〜3 で、インターネットに出られないホスト（以下、オフラインのホスト）にトンネルを張り、同書の[dnf にもトンネルを使わせる（任意）](ssh-socks-tunnel.md#dnf-にもトンネルを使わせる任意)で dnf にプロキシを設定してあること（dnf の節を飛ばしていたら、手順 1 の前に行う）
> - **前提**: 同じトンネルで、[homebrew-offline.md](homebrew-offline.md) の Homebrew と、[Neovim](neovim.md) と、Mason を使う設定（LazyVim をもとにした自分用の設定など）を入れてあること
> - **手順 1〜3 は、ssh-socks-tunnel.md の手順 3 のシェル（オフラインのホストの、`sudo` できる自分のユーザー）のまま貼る**。手順 4 で同書の[トンネルを閉じる](ssh-socks-tunnel.md#トンネルを閉じる)の手順 1・2 を行い、手順 5 はログインし直したシェルで貼る
> - **手順 3 は Neovim の画面、手順 4 は ssh のログインがある**。終わってから次の手順を貼る

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **x86_64 のクリーンインストール VM でも検証した手順書**（2026-10-06、SELinux Enforcing）で、実機では本実行していない。Mason を使う設定は、自分用の設定ではなく、上流の LazyVim の starter で確かめた（[対象と検証環境](#対象と検証環境)）。
>
> - トンネルを張っている間は、オフラインのホストのどのユーザーも `127.0.0.1:1080` を通って外に出られる（[ssh-socks-tunnel.md の注意点](ssh-socks-tunnel.md#注意点)）

1. ssh-socks-tunnel.md の手順 3 のシェルで、AppStream の Node.js と npm を入れる。

   ```bash
   sudo dnf install -y nodejs nodejs-npm
   ```

   - `nodejs`・`nodejs-npm` と不足する依存が入り、`Complete!` で終わる（以前のコンテナでは計 9 パッケージ、2026-10-06 の Workstation の VM では計 5 パッケージだった）
   - `Failed to download metadata for repo` で止まったら、dnf がトンネルを通っていない
     - `Curl error (6)`（名前を引けない）なら、ssh-socks-tunnel.md の[dnf にもトンネルを使わせる（任意）](ssh-socks-tunnel.md#dnf-にもトンネルを使わせる任意)の設定が無い
     - `Curl error (7)`（`127.0.0.1 port 1080` につながらない）なら、トンネルが無い（同書の手順 2 から張り直す）

   <details>
   <summary>補足: 入るパッケージと、ほかの Node.js</summary>

   **トンネル越しに 9 パッケージ（ダウンロード 42 MB、導入後 219 MB）が入った。** コンテナでの実測（`Installed:` の行だけ）:

   ```
   Installed:
     c-ares-1.34.6-2.el10_2.x86_64                 libbrotli-1.1.0-7.el10_1.x86_64          libuv-1:1.52.1-1.el10_2.x86_64                   nodejs-1:22.23.2-1.el10_2.x86_64          nodejs-docs-1:22.23.2-1.el10_2.noarch
     nodejs-full-i18n-1:22.23.2-1.el10_2.x86_64    nodejs-libs-1:22.23.2-1.el10_2.x86_64    nodejs-npm-1:10.9.8-1.22.23.2.1.el10_2.x86_64    openssl-1:3.5.8-1.el10_2.alma.1.x86_64
   Complete!
   ```

   - `nodejs` は `nodejs-npm` を弱い依存（`Recommends`）で引くので、`nodejs` だけでも npm は入る。`install_weak_deps=False` のホストでも入るように、2 つとも名前で挙げた
   - `npm` という名前でも入る（`nodejs-npm` が `npm` を提供する）
   - AppStream には `nodejs24`（24.19.0）もあるが、コマンドの名前が `node-24`・`npm-24` になる。Mason は `npm` という名前で探すので使わない（[選択した方針](#選択した方針)）

   </details>

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
   - `/home/linuxbrew/.linuxbrew/bin/npm` が出たら、Homebrew の node が PATH で先に来ていて、Mason もそちらを使う（[注意点](#注意点)）
   - `npm config get` の 2 行は、どちらも `null`
   - ほかの値が出たら、`~/.npmrc` などの設定が `https_proxy` より優先される（この手順の補足）
   - `npm notice PONG 148ms` のように `PONG` が出れば、npm はトンネルを通ってレジストリに届いている
   - `export` はこのシェルの中だけで有効。**トンネルを張り直したら、ssh-socks-tunnel.md の手順 3 に続けて、この手順を貼り直す**

   <details>
   <summary>補足: npm は <code>ALL_PROXY</code> を読まない</summary>

   **npm が読むプロキシの環境変数は、`https_proxy`・`http_proxy`・`proxy`・`no_proxy` だけ**（大文字でもよい）。npm 10.9 に同梱の `@npmcli/agent` の `lib/proxy.js`:

   ```
   const PROXY_ENV_KEYS = new Set(['https_proxy', 'http_proxy', 'proxy', 'no_proxy'])
   ...
       proxy = url.protocol === 'https:'
         ? PROXY_ENV.https_proxy
         : PROXY_ENV.https_proxy || PROXY_ENV.http_proxy || PROXY_ENV.proxy
   ```

   - npm のレジストリは https なので、使うのは `https_proxy` だけ。ssh-socks-tunnel.md の手順 3 の `ALL_PROXY` は読まない
   - `socks5h://` は、同梱の `socks-proxy-agent` が受け付ける（`socks`・`socks4`・`socks4a`・`socks5`・`socks5h`）。`h` を落とすと、名前をオフラインのホストで引いて失敗する（[ssh-socks-tunnel.md 手順 3](ssh-socks-tunnel.md#実施手順) の補足）

   **`ALL_PROXY` だけでは届かない。** ssh-socks-tunnel.md の手順 3 のシェルで、この手順の `export` の前に `npm ping` を実行したときの出力（70 秒かかった）:

   ```
   npm notice PING https://registry.npmjs.org/
   npm error code ENOTFOUND
   npm error syscall getaddrinfo
   npm error errno ENOTFOUND
   npm error network request to https://registry.npmjs.org/-/ping failed, reason: getaddrinfo ENOTFOUND registry.npmjs.org
   ```

   - 同じシェルの curl は、`ALL_PROXY` だけで `200` を返した
   - `export` の後の `npm ping` は、0.5 秒で `npm notice PONG 148ms` を返した

   **設定の値は、環境変数より優先される。** `https-proxy=http://127.0.0.1:9` とだけ書いた設定ファイルを `--userconfig` で読ませると、`https_proxy` があっても、その値に向かった:

   ```
   $ npm --userconfig /tmp/t.npmrc ping --fetch-retries=0 2>&1 | grep -E 'code|reason' | head -3
   npm error code ECONNREFUSED
   npm error FetchError: request to https://registry.npmjs.org/-/ping failed, reason: connect ECONNREFUSED 127.0.0.1:9
   npm error   code: 'ECONNREFUSED',
   ```

   - `npm config get` が `null` 以外を返したら、その値を書いた設定（`npm config get userconfig` の `~/.npmrc` など）を見直す

   **`https_proxy` は、curl と git も読む。** 値は `ALL_PROXY` と同じなので、このシェルの brew もそのまま通る（`brew update` が `Already up-to-date.` で終わった）。

   **`~/.bashrc` や `~/.npmrc` には書かない。** トンネルがあるのは ssh-socks-tunnel.md の手順 2 の ssh の間だけなので、このシェルにだけ入れる（[選択した方針](#選択した方針)）。

   </details>

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
   - npm 以外の理由（`unzip` が無い、など）で失敗したものは[注意点](#注意点)
   - 通知が出そろってから、`:qa` で閉じる（入れている途中で閉じると、確認無しにその導入が止まる）
   - LSP サーバーが 1 つも入らなかったら、`:qa` で閉じて、この手順をもう一度貼る（この手順の補足）
   - **次の手順は、`:qa` で Neovim を閉じてから貼る**（続けて貼ると Neovim への入力として食われる）

   <details>
   <summary>補足: Mason が npm を動かす仕組みと、ファイルを開く理由</summary>

   **Mason（2.3.1）は、npm のパッケージを `~/.local/share/nvim/mason/packages/<名前>` に入れる。** そのディレクトリで `npm init --yes --scope=mason` と `npm install <名前>@<版>` を実行し、`~/.local/share/nvim/mason/bin/` からリンクを張る。

   - npm は PATH から探し、環境変数は Neovim のものを引き継ぐ。手順 2 のシェルから開くのは、`https_proxy` を npm に渡すため
   - 入れたコマンドは `#!/usr/bin/env node` で始まるので、動かすたびに手順 1 の Node.js を使う
   - Mason のパッケージの一覧（mason-registry）は、GitHub のリリースから curl で取る。curl は `ALL_PROXY` も `https_proxy` も読む

   **npm が無いときと、`https_proxy` が無いときの失敗。** 手順 1 の前に Neovim を開いたときの `:MasonLog`（長い行は省いた）:

   ```
   [ERROR …] …InstallRunner.lua:100: Installation failed for Package(name=markdownlint-cli2) error=spawn: npm failed with exit code - and signal -. Could not find executable "npm" in PATH.
   [ERROR …] …InstallRunner.lua:100: Installation failed for Package(name=json-lsp) error=spawn: npm failed with exit code - and signal -. Could not find executable "npm" in PATH.
   ```

   - 手順 1 の後に、`https_proxy` を入れずに（`ALL_PROXY` だけで）markdown-toc を入れ直すと、`$ npm install markdown-toc@1.2.0` の行のまま 29 分かかった
   - npm は、取得のたびに `ENOTFOUND` で 3 回ずつ試し、最後は、前にトンネル越しに入れたときのキャッシュ（`~/.npm`）から入れた（付録）

   **ファイルを開くのは、LSP サーバーも入れさせるため。** LazyVim は、Mason に入れさせるものを 2 か所に持つ。

   - ツール（mason.nvim の `ensure_installed`。stylua・markdownlint-cli2 など）: Mason が読み込まれたときに入る
   - LSP サーバー（json-lsp・marksman など）: ファイルを開いて nvim-lspconfig が読み込まれたときに入る。Mason もこのときに読み込まれる
   - `nvim` だけで開いて `:Mason` を実行すると、ツールしか入らない。検証では、消しておいた markdown-toc だけが入り、json-lsp はファイルを開いたときに入った
   - `-R` は読み取り専用で開く指定。設定のファイルを書き換えないため

   **LazyVim は、入れる LSP サーバーを Mason のパッケージの一覧から選ぶ。** 開いた時点で一覧がまだ無い（初めて取るところ）と、その回は LSP サーバーを入れない。

   - 検証では、一覧を初めて取った回はツールの導入だけが始まり、閉じて開き直した回に LSP サーバー（json-lsp・lua-language-server・marksman）の導入が始まった

   **入れている途中で `:qa` すると、確認は出ず、その導入は止まる。** `:MasonLog` には `Installation failed for Package(name=json-lsp) error="Installation was aborted."` と残った。次に開いたときに、Mason がやり直す。

   </details>

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

   <details>
   <summary>補足: <code>--fetch-retries=0</code></summary>

   **npm は、つながらないと既定で 2 回試し直す。** 試し直しを切らないと、`npm ping` が失敗するまで 70 秒かかった。`--fetch-retries=0` を付けると 0.4 秒で失敗した。どちらも同じ `ENOTFOUND` のエラーを出す。

   </details>

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

---

## ロールバック

- オフラインのホストで貼る。トンネルは要らない
- `https_proxy` はどこにも書いていないので、戻すものは無い
- dnf のプロキシの行は、[ssh-socks-tunnel.md のロールバック](ssh-socks-tunnel.md#ロールバック)の手順 1 で消す
- Mason で入れたものは、`:MasonUninstall <名前>` で消せる（設定にあるものは、次にトンネルのあるシェルで開いたときに入り直す）

> [!WARNING]
> **この節の手順 1 で Node.js を消すと、Mason で入れた npm のパッケージは動かなくなる**（どれも `#!/usr/bin/env node` で始まる）。Mason を使い続けるなら、この節は行わない。

1. [手順 1](#実施手順) で入れた Node.js と npm を、ほかに使わないときだけ消す。

   ```bash
   sudo dnf remove -y nodejs nodejs-npm
   ```

   - [手順 1](#実施手順) で一緒に入った依存（`libuv`・`openssl` など）も消え、合わせて 9 パッケージが消える

1. npm のキャッシュとログを消す。

   ```bash
   rm -rf ~/.npm
   command -v node npm || echo '無い（期待どおり）'
   ```

   - `無い（期待どおり）` が出ればよい
   - Mason のパッケージ（`~/.local/share/nvim/mason/packages`）は残る

---

## 補足

### 対象と検証環境

- **目的**: インターネットに出られない AlmaLinux 10 のホストで、Neovim の Mason が、npm で配られているパッケージ（LSP サーバー・リンターなど）を入れられるようにする
  - 入れる・上げるときだけ、[ssh-socks-tunnel.md](ssh-socks-tunnel.md) のトンネルで外に出る
  - 入れたパッケージは、トンネルが無くても動く
- **進め方**: AppStream の Node.js と npm を dnf で入れ、npm には `https_proxy` でトンネル（`socks5h://127.0.0.1:1080`）を使わせる。そのシェルから Neovim を開き、Mason に入れさせる
  - この文書には変数が無い。オンラインのホストの変数は、ssh-socks-tunnel.md の手順 1 にある
- **状態**: **x86_64 のクリーンインストール VM で実施手順 1〜5を検証済み（2026-10-06、SELinux Enforcing）。設定は上流 LazyVim starter、実機・aarch64 は未実施**
  - VM の実測は[今回の付録](#付録-vm-での検証記録2026-10-06)。以下の以前の検証と未確認事項は、当時の範囲の記録。
  - このクラウドのホスト（Ubuntu 24.04）の Docker で、外に出られないネットワーク（`--internal`）だけにつないだコンテナをオフラインのホストにした（homebrew-offline.md と同じ形）
  - Mason を使う設定は、上流の [LazyVim/starter](https://github.com/LazyVim/starter) に、LazyVim の extra の `lang.json` と `lang.markdown` を足したもの。自分用の設定（LazyVimStarter）では確かめていない
  - 前提（当時の homebrew-offline.md の手順 1〜5。今の ssh-socks-tunnel.md の手順 1〜3・dnf の節と homebrew-offline.md の手順 1〜3。neovim.md の手順 1、LazyVim の starter）をトンネル越しに通した状態から、**この文書のコードブロックをそのまま**、擬似端末で開いたオンラインのホストの対話の bash に貼って、手順 1〜5、[更新](#更新)、[ロールバック](#ロールバック)を通した
  - 貼り方はブラケットペースト無し。手順 1 とロールバックの手順 1 は、ブラケットペースト有りでも通した
  - このクラウドの出口からは Mason のパッケージの一覧の版を調べる先（api.mason-registry.dev）に届かなかったので、検証のときだけ、オンラインのホストのその名前をセッションのプロキシへ中継した（[付録](#付録-コンテナでの検証記録2026-09-30)）
  - 確認したこと:
    - npm は `ALL_PROXY` だけでは届かず、`https_proxy` を入れると届くこと。設定ファイルの値が環境変数より優先されること
    - Mason が、トンネル越しに npm のパッケージ（markdownlint-cli2・markdown-toc・json-lsp）を入れること。npm が無いときと `https_proxy` が無いときの出方
    - トンネルを閉じた後も、入れたパッケージが動き（json-lsp は LSP としても動いた）、npm は外に届かないこと
    - 更新で、古い版の npm のパッケージが `U` で上がること。ロールバックで Node.js を消すと、Mason の npm のパッケージが動かなくなること
    - オフラインのまま Mason のパッケージの一覧の期限（24 時間）が切れても、入れたパッケージと LSP は使えること
  - **確認していないこと**: 実機（x86_64 の PC・Raspberry Pi 5）、aarch64、SELinux が Enforcing のホスト、自分用の設定（LazyVimStarter）、Homebrew の node が入っているホスト、install スクリプトの中で自分でファイルを取る npm のパッケージ、キャッシュが無いホストで `https_proxy` を入れ忘れたときの結末
  - 実測の記録は[付録](#付録-コンテナでの検証記録2026-09-30)

| 項目 | オンラインのホスト | オフラインのホスト |
|---|---|---|
| 実施日 | 2026-09-30 | 同左 |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64（`docker.io/library/almalinux:10` のコンテナ） | 同左 |
| ネットワーク | 外に出られるネットワークと、オフラインのホストのネットワークの両方 | `--internal` のネットワークだけ（既定の経路も、外の名前解決も無い） |
| ssh | `openssh-clients-9.9p1-27.el10_2.alma.1` | `openssh-server-9.9p1-27.el10_2.alma.1`。systemd 無しで `sshd -D -e` を動かした |
| Node.js / npm | — | `nodejs-22.23.2-1.el10_2` / `nodejs-npm-10.9.8-1.22.23.2.1.el10_2`（手順 1 で新規導入） |
| Neovim / Mason | — | Homebrew の `neovim 0.12.5_1`、LazyVim の starter、`mason.nvim` 2.3.1 |
| ユーザー | `<USER>`（uid 1000） | 同じ名前（uid 1000、NOPASSWD の sudo） |
| コンテナのホスト | Ubuntu 24.04 / x86_64 のクラウドの VM、Docker 29.3.1（cgroup v1） | 同左 |

> [!NOTE]
> この文書には変数が無い。オンラインのホストの変数（`OFFLINE_HOST`・`OFFLINE_USER`）は、[ssh-socks-tunnel.md 手順 1](ssh-socks-tunnel.md#実施手順) で設定する。
>
> 出力例・ログ・表の中の値は `<OFFLINE_HOST>` / `<USER>`（ユーザー名）のプレースホルダで書いてある。バージョン（`22.23.2` など）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

オフラインのホスト（コンテナ）で、手順 1 の前に確かめた状態:

| 項目 | 状態 |
|---|---|
| トンネルと dnf | 当時の homebrew-offline.md の手順 1〜4（今の ssh-socks-tunnel.md の手順 1〜3 と dnf の節、homebrew-offline.md の手順 1）を通した。`/etc/dnf/dnf.conf` に `proxy=socks5h://127.0.0.1:1080` がある |
| Homebrew / Neovim | 当時の homebrew-offline.md の手順 5（今の手順 3）で Homebrew 7.0.7、neovim.md の手順 1 で `neovim 0.12.5_1` |
| Neovim の設定 | `~/.config/nvim` に LazyVim の starter と、extra の `lang.json`・`lang.markdown`（`lazyvim.json`）。プラグインはトンネル越しに入れてある |
| Node.js / npm | 無い（`node`・`npm` が無く、`~/.npm` も無い） |
| Mason | 入っているのは shfmt・tree-sitter-cli・lua-language-server・marksman（GitHub のリリースから取るもの）。markdownlint-cli2・markdown-toc・json-lsp は `Could not find executable "npm" in PATH.` で、stylua は `Could not find executable "unzip" in PATH.` で失敗していた |

### 選択した方針

| 経路 | 要るもの | 採否 |
|---|---|---|
| **AppStream の `nodejs`（22 系）と、シェルの `https_proxy`** | ssh-socks-tunnel.md のトンネルと dnf のプロキシ | **採用。** 言語処理系は AppStream から入れる方針（[導入元一覧](tool-catalog.md)）で、`dnf upgrade` で上がる。npm にだけ変数を 1 つ足せば、Mason を書き換えずに npm がトンネルを通る |
| AppStream の `nodejs24`（24.19.0） | 同上 | 不採用。コマンドが `node-24`・`npm-24` で、Mason が探す `npm` が無い |
| Homebrew の `node` | homebrew-offline.md のトンネル | 不採用。Homebrew の `bin` が PATH で先に来るので、RPM の node と npm を隠す。版を選ぶなら mise（[導入元一覧](tool-catalog.md)） |
| `~/.npmrc` に `https-proxy=socks5h://127.0.0.1:1080` を書く | — | 不採用。トンネルが無いときも npm が 1080 番に向かい続ける。dnf のプロキシの行（ssh-socks-tunnel.md の[dnf にもトンネルを使わせる（任意）](ssh-socks-tunnel.md#dnf-にもトンネルを使わせる任意)）と違い、書かなくても済む |
| `ALL_PROXY` だけ | — | 動かない。npm は `ALL_PROXY` を読まない（[手順 2](#実施手順) の補足） |
| npm のキャッシュ・Mason のディレクトリを運ぶ、社内に npm のミラー（Verdaccio など）を建てる | 同じアーキのホスト、運ぶ手段、ミラーのサーバー | 本書では扱わない（ネットワークで届かないときの方法。確かめていない） |

- **Mason の導入を、`nvim --headless` のコマンドにしなかった**
  - `nvim --headless '+MasonInstall <名前>' +qa` の `:MasonInstall` は、名前を挙げたものが終わるまでしか待たない
  - LazyVim が読み込み時に始めたほかの導入は、`+qa` で止まりうる
  - 読者の設定が入れるものを 1 つずつ挙げる必要もあるので、画面で終わりを見て閉じる形にした
- **`https_proxy` を `~/.bashrc` に書かない**: ssh-socks-tunnel.md の `ALL_PROXY` と同じ理由（トンネルは同書の手順 2 の ssh の間だけ）

### 完了時点の状態

**検証のコンテナでの出力**（[手順 5](#実施手順)。転送無しでログインし直したオフラインのホストのシェル）:

```
$ env | grep -i _proxy
$ ls ~/.local/share/nvim/mason/bin
lua-language-server  markdown-toc  markdownlint-cli2  marksman  shfmt  tree-sitter  vscode-json-language-server
$ ~/.local/share/nvim/mason/bin/markdownlint-cli2 --help | head -n 1
markdownlint-cli2 v0.23.3 (markdownlint v0.41.1)
$ npm ping --fetch-retries=0 && echo '届いた（オフラインではない）' || echo '届かない（期待どおり）'
npm notice PING https://registry.npmjs.org/
npm error code ENOTFOUND
npm error syscall getaddrinfo
npm error errno ENOTFOUND
npm error network request to https://registry.npmjs.org/-/ping failed, reason: getaddrinfo ENOTFOUND registry.npmjs.org
（中略）
届かない（期待どおり）
```

- 同じシェルで JSON のファイルを開くと、json-lsp の LSP（`jsonls`）が動いた
- `/etc/dnf/dnf.conf` の `proxy=socks5h://127.0.0.1:1080` は残る（[ssh-socks-tunnel.md のロールバック](ssh-socks-tunnel.md#ロールバック)の手順 1 で消す）
- `~/.npm` に npm のキャッシュが残る（[ロールバック](#ロールバック)の手順 2 で消す）

### 注意点

- **npm だけは `ALL_PROXY` では足りない**: [手順 2](#実施手順) の `export` を飛ばすと、Mason の npm のパッケージだけが、試し直しを繰り返してなかなか終わらない（検証では 29 分。[手順 3](#実施手順) の補足）
- **`sudo` は `https_proxy` を渡さない**: `sudo printenv https_proxy` は何も出さなかった。`sudo npm install -g` のような使い方は、本書では扱わない
- **Homebrew の node が入っていると、Mason はそちらの npm を使う**: Mason は PATH の先頭の `npm` を使い、`brew shellenv` は Homebrew の `bin` を PATH の先頭に置く。[手順 2](#実施手順) の `command -v` で確かめる（本書では、Homebrew の node が入ったホストを確かめていない）
- **PyPI のパッケージは入らない**: Mason は PyPI のパッケージを、仮想環境の pip で入れる。その pip は SOCKS のプロキシを使えない
  - 検証では black が `ERROR: Could not install packages due to an OSError: Missing dependencies for SOCKS support.` で失敗した
  - GitHub のリリースから入るもの（ruff など）は、この問題が無い。検証では ruff が入った
- **npm 以外の理由でも失敗する**: stylua は、`unzip` が無くて `Could not find executable "unzip" in PATH.` で失敗した
  - 足りないコマンドは、`:checkhealth mason` の `WARNING unzip: not available` のような行で見られる
  - トンネルのシェルで `sudo dnf install -y unzip` を実行してから開き直すと、stylua も入った
- **Mason のパッケージの一覧は、24 時間ごとに取り直そうとする**: トンネルの無いときに開くと、取り直しに失敗する
  - `:Mason` の画面に `Registry installation failed with the following error:` と出る
  - 入れたパッケージはそのまま使える。検証では、一覧を 2 日前に取ったことにして開き、lua_ls が動いた
  - 一覧を取り直すのは、次にトンネルのあるシェルで開いたとき（[更新](#更新)）
- **トンネルが無いときに開くと、設定にあって入っていないパッケージの導入が毎回失敗する**: 検証では stylua が毎回 `:MasonLog` にエラーを残した。画面での編集には影響しない
- **ssh が切れると、トンネルも消える**: 途中の導入は失敗する。[ssh-socks-tunnel.md 手順 2](ssh-socks-tunnel.md#実施手順) から張り直し、[手順 2・3](#実施手順) を貼り直す

### 参照

- [npm Docs — config の `https-proxy`・`proxy`](https://docs.npmjs.com/cli/v10/using-npm/config#https-proxy) — npm のプロキシの設定と環境変数
- [npm/agent の lib/proxy.js](https://github.com/npm/agent/blob/main/lib/proxy.js) — npm が読むプロキシの環境変数と、SOCKS の扱い
- [mason.nvim](https://github.com/mason-org/mason.nvim) — `lua/mason-core/installer/managers/npm.lua`（npm のパッケージの入れ方）、`lua/mason-core/fetch.lua`（curl と wget）
- [LazyVim の LSP の設定](https://www.lazyvim.org/plugins/lsp) — mason.nvim と mason-lspconfig.nvim の `ensure_installed`
- [ssh-socks-tunnel.md](ssh-socks-tunnel.md) — 前提のトンネルと dnf のプロキシ。手順 4 で同書の「トンネルを閉じる」の手順 1・2 を使う
- [homebrew-offline.md](homebrew-offline.md) — 前提の Homebrew（Neovim をトンネル越しに入れる）
- [neovim.md](neovim.md) — 前提の Neovim と、自分用の設定への案内

---

### 付録: コンテナでの検証記録（2026-09-30）

`docker.io/library/almalinux:10`（AlmaLinux 10.2、x86_64）から 2 つのイメージを作り、x86_64 のクラウドホスト（Ubuntu 24.04）の Docker 29.3.1 でコンテナを立てた。実機で加えた変更は無い。

検証の準備（手順書の外）:

- ネットワークとコンテナは homebrew-offline.md の検証と同じ形にした
  - オフラインのホスト: `--internal` のネットワークだけ。`openssh-server`・`sudo`・`iproute` を入れ、`sshd -D -e` を動かした。ユーザー（uid 1000、NOPASSWD の sudo）を作った
  - オンラインのホスト: 外に出られるネットワークと `--internal` のネットワークの両方。`openssh-clients` と鍵を入れ、公開鍵をオフラインのホストの `authorized_keys` に置いた（鍵認証）
- このクラウドのホストの外向きの通信は、TLS を署名し直すゲートウェイを通る。そのゲートウェイの CA を、両方のコンテナの信頼ストアに足した
  - オフラインのホストの curl・git・dnf と node が使う。node（AppStream の 22）は、信頼ストアに足しただけで通った（`NODE_EXTRA_CA_CERTS` は使っていない）
  - 実際のオンラインのホストでは、この変更は要らない
- **Mason のパッケージの一覧の版を調べる先に、このクラウドの出口から届かなかった**
  - api.mason-registry.dev は、直接の接続を `403 Forbidden`（`x-vercel-mitigated: deny`）で断った。代わりに Mason が使う api.github.com も、`API rate limit exceeded` を返した
  - そのままでは、Mason は `Failed to fetch latest registry version from GitHub API.` で一覧を取れなかった
  - 検証のときだけ、オンラインのホストのコンテナの `/etc/hosts` で api.mason-registry.dev を VM の上の中継（Python の標準ライブラリで書いたもの）に向け、中継からセッションの HTTP プロキシへ `CONNECT` で渡した（`200` になった）
  - ssh の `-R 1080`、オフラインのホスト、Mason の設定は変えていない。ほかの取得先（registry.npmjs.org・github.com・ミラー・ghcr.io）には、オンラインのホストから直接届いた
- 前提は、1 組目のコンテナ（探索用）で通した
  - 当時の homebrew-offline.md の手順 1〜5（手順 4 を含む。手順 5 は homebrew.md の手順 1〜4。今の ssh-socks-tunnel.md の手順 1〜3・dnf の節と homebrew-offline.md の手順 1〜3）と、neovim.md の手順 1（`neovim 0.12.5_1`）
  - Neovim の設定: トンネルのシェルで `git clone https://github.com/LazyVim/starter ~/.config/nvim` の後に `.git` を消し、`lazyvim.json` に `{"extras":["lazyvim.plugins.extras.lang.json","lazyvim.plugins.extras.lang.markdown"],…}` を書いた
  - `nvim` を 3 回開いた。1 回目で 35 のプラグインがトンネル越しに入り、Mason の失敗が[実施前の状態](#実施前の状態)のとおりになった
  - この状態で 2 つのコンテナを `docker commit` し、そこから 2 組目のコンテナを立てて、この文書を最初から通した（下の表）
- 追加の確認（下の 2 つ目の表）は、主に 1 組目のコンテナで行った

コードブロックの流し方:

- 文書からコードブロックを抜き出し、VM の tmux で開いた `docker exec -it` のオンラインのホストの対話の bash（擬似端末、`TERM=xterm-256color`）に、手順ごとに `tmux paste-buffer` で送った（ブラケットペースト無し。改行は CR）
- 当時の homebrew-offline.md の手順 1（今の ssh-socks-tunnel.md の手順 1）の `OFFLINE_HOST` は、コンテナの名前に書き換えた。ホスト鍵の確認には `yes` を送った
- Neovim の画面は `tmux capture-pane` で読み、`:Mason`・`q`・`U`・`:qa` はキーとして送った
- ブラケットペースト有り（`tmux paste-buffer -p`）で送ると、bash は貼った行を入力の行に置いて Enter を待つ。表示を見てから Enter を送った

| 手順 | 結果 |
|---|---|
| 前提 | 当時の homebrew-offline.md の手順 1〜3（今の ssh-socks-tunnel.md の手順 1〜3 と homebrew-offline.md の手順 1）。`127.0.0.1:1080` の 1 行、`200` / `301` / `200` / `401`。`rpm -q` の 4 つは入っていた |
| 1 | 9 パッケージ（ダウンロード 42 MB、導入後 219 MB）、`Complete!` |
| 2 | `v22.23.2`、`10.9.8`、`/usr/bin/node`、`/usr/bin/npm`、`null`、`null`、`npm notice PONG 211ms` |
| 3 | 開いてすぐ Mason が stylua・markdownlint-cli2・markdown-toc・json-lsp の導入を始め、9 秒で npm の 3 つが入った（`markdown-toc was successfully installed.`・`[mason-lspconfig.nvim] jsonls was successfully installed` などの通知）。stylua は `unzip` が無くて失敗し、通知は出ず、`:MasonLog` にだけ残った。`:Mason` の画面は `Installed (7)`。`:qa` で閉じた |
| 4 | 当時の homebrew-offline.md の手順 7 で `Connection to <OFFLINE_HOST> closed.`、手順 8 でログインし直した（今の ssh-socks-tunnel.md の「トンネルを閉じる」の手順 1・2） |
| 5 | [完了時点の状態](#完了時点の状態)のとおり。続けて JSON のファイルを開くと、`jsonls` が動いた |
| 更新 | トンネルを張り直して手順 2 を貼った（`PONG 193ms`）。この節の手順 1 は `Nothing to do.`。この節の手順 2 の前に、上げるものを作るため、`:MasonInstall markdown-toc@1.1.0` で古い版にした（手順書の外）。`:MasonUpdate` の後の `:Mason` に `Press U to update 1 package (markdown-toc)` と `new version available: 1.1.0 -> 1.2.0` が出て、`U` で `$ npm install markdown-toc@1.2.0` が走り、2 秒で入った。この節の手順 3 は `Connection to <OFFLINE_HOST> closed.` |
| ロールバック | 転送無しでログインし直して貼った。この節の手順 1 は 9 パッケージを消して `Complete!`（ダウンロードは無く、トンネル無しで通った）。手順 2 は `無い（期待どおり）`。その後の markdownlint-cli2 は `env: 'node': No such file or directory` で動かなかった |
| ブラケットペースト | 手順 1（トンネルを張り直したシェル）と、ロールバックの手順 1（転送無しのシェル）を、ブラケットペースト有りで貼って Enter を送った。どちらも 9 パッケージを入れた・消した |

追加の確認（手順書の外）:

| 確認 | 結果 |
|---|---|
| `dnf repoquery` | `nodejs` は `nodejs-npm` を `Recommends` で引く。`npm` を提供するのは `nodejs-npm`。`nodejs24`（24.19.0）のコマンドは `/usr/bin/node-24`・`npm-24`・`npx-24` で、npm は `nodejs24-npm`（11.17.0） |
| `ALL_PROXY` だけの `npm ping` | `ENOTFOUND` で、70 秒かかった。同じシェルの curl は `200` |
| 設定ファイルの `https-proxy` | `--userconfig` で `https-proxy=http://127.0.0.1:9` を読ませると、`https_proxy` があっても `ECONNREFUSED 127.0.0.1:9` |
| トンネル無しの `npm ping` | `--fetch-retries=0` で 0.4 秒、付けないと 70 秒で、どちらも `ENOTFOUND` |
| npm が無いときの Mason | markdownlint-cli2・markdown-toc・json-lsp が `Could not find executable "npm" in PATH.` |
| 一覧を初めて取った回の LSP サーバー | LazyVim が mason-lspconfig に渡した `ensure_installed` が `{}` で、LSP サーバーの導入は始まらなかった。開き直した回に json-lsp（npm が無くて失敗）・lua-language-server・marksman の導入が始まった |
| `https_proxy` 無しの Mason | 手順 1 の後、`ALL_PROXY` だけのシェルで開き、markdown-toc を消して入れ直した。`$ npm install markdown-toc@1.2.0` の行のまま 29 分（09:02:25 → 09:31:39）。npm のログでは、55 の取得が `ENOTFOUND` で 3 回ずつ失敗し、前に入れたときのキャッシュから入って `exit 0` |
| ファイルを開かずに `:Mason` | markdown-toc と json-lsp を消して `nvim` だけで開き、`:Mason` を実行すると、markdown-toc（ツール）だけが入った。続けて `:e ~/.config/nvim/init.lua` でファイルを開くと、json-lsp（LSP サーバー）が入った |
| 入れている途中の `:qa` | json-lsp を入れている途中で `:qa` すると、確認無しに閉じ、`:MasonLog` に `Installation was aborted.`。次に開いたときに入った |
| PyPI のパッケージ | `:MasonInstall black` は `ERROR: Could not install packages due to an OSError: Missing dependencies for SOCKS support.` |
| GitHub のリリースのパッケージ | `:MasonInstall ruff` は入った（`pkg:github/astral-sh/ruff`） |
| `unzip` | `:checkhealth mason` に `WARNING unzip: not available`。トンネルのシェルで `sudo dnf install -y unzip` の後に開き直すと、stylua が入った |
| 期限切れの一覧（トンネル無し） | `~/.cache/nvim/mason-registry-update` の時刻を 2 日前にして開くと、`Failed to fetch latest registry version from GitHub API.` を `:MasonLog` に残し、`:Mason` の画面に `Registry installation failed with the following error:` が出た。`Installed` の一覧はそのままで、lua_ls は動いた |
| トンネル無しの起動 | 入っていない stylua の導入が毎回始まり、`:MasonLog` にエラーが残った |
| `U` の後の画面 | `markdown-toc was successfully installed.` の通知と `:MasonLog` の `Installation succeeded` の後も、開いていた画面は `Installing (1)` のまま変わらなかった。`q` で閉じて `:Mason` で開き直すと、`Installed (8)` に移っていた |
| `sudo` と `https_proxy` | `export https_proxy=…` の後の `sudo printenv https_proxy` は無出力、終了コード 1。ログインシェルの PATH は `/home/linuxbrew/.linuxbrew/bin` が先頭 |
| `https_proxy` と `ALL_PROXY` がある `brew update` | `Already up-to-date.` |
| dnf のプロキシの行が無いオフラインのホスト（使い捨てのコンテナ） | `Curl error (6): Could not resolve hostname for https://mirrors.almalinux.org/mirrorlist/10/appstream …` と `Error: Failed to download metadata for repo 'appstream'` |
| 行があってトンネルが無いとき | `Curl error (7): … [Failed to connect to 127.0.0.1 port 1080 after 0 ms: …]` と同じ `Error: …` |

#### 未確認事項

- 実機（x86_64 の PC・Raspberry Pi 5）での本実行と、aarch64
- SELinux が Enforcing のホスト
- 自分用の設定（LazyVimStarter）が Mason に入れさせるパッケージ
- Homebrew の node が入っているホスト（[手順 2](#実施手順) の `command -v`）
- install スクリプトの中で自分でファイルを取る npm のパッケージ
- キャッシュ（`~/.npm`）が無いホストで、`https_proxy` を入れ忘れたときに Mason の npm の導入がどう終わるか
- 長い導入の途中で ssh が切れたとき

---

### 付録: VM での検証記録（2026-10-06）

**環境**: [クリーンインストールからの検証記録](almalinux-vm-verification.md)のオフライン用 VM。公式 ISO から Workstation を入れた状態から始め、x86_64、SELinux Enforcing、firewalld 有効。本文のブロックを SSH の擬似端末で実行した。

- [homebrew-offline.md の今回の記録](homebrew-offline.md#付録-vm-での検証記録2026-10-06)と同じ VM で、dnf の SOCKS 設定と Neovim の導入を前提から用意した。本文の主手順を SSH の擬似端末で通した。
- 手順 1 で AppStream の Node.js 22.23.2 と npm 10.9.8 が、計 5 パッケージで入った。手順 2 のコマンドの場所は `/usr/bin/node` / `/usr/bin/npm`、プロキシの設定ファイルの値は両方 `null`。`https_proxy` を入れると `npm ping` は `PONG 384ms` だった。
- 個人用の設定は使わず、検証用に上流 LazyVim starter（commit `803bc181d7c0d6d5eeba9274d9be49b287294d99`）を取得した。Homebrew の Neovim 0.12.5、LazyVim の 32 プラグイン、Mason 2.3.1 を使用。設定の取得は手順書の外の準備。
- 手順 3 の Neovim を開き、Mason に不足していた `markdownlint-cli2` と `json-lsp` を `:MasonInstall markdownlint-cli2 json-lsp` で指定した。Mason のログは両方 `Installation succeeded`。導入中にもプロキシ無しの直接通信は終了 7 だった。
- 手順 4 では転送を保持した SSH と Neovim の端末を閉じ、転送無しで再ログインした。手順 5 でプロキシ環境変数は無く、Mason の bin に `markdownlint-cli2` / `vscode-json-language-server` / `shfmt` / `stylua` / `tree-sitter` があった。リンターのヘルプは `markdownlint-cli2 v0.23.3 (markdownlint v0.41.1)`、`npm ping --fetch-retries=0` は ENOTFOUND と `届かない（期待どおり）` だった。
- 今回は LSP として JSON を編集する動作、npm の設定ファイルに競合する値がある場合、更新・ロールバック、個人用設定、実機・aarch64 は確認していない。以前のコンテナの結果と区別する。
