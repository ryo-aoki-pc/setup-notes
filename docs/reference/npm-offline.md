# npm をインターネットに出られないホストで使う手順（AlmaLinux 10 / AppStream の Node.js / Neovim の Mason）の参考資料

[手順書](../npm-offline.md)・[ロールバックと注意点](../extra/npm-offline.md)

## 補足

### 実施手順 / 手順 2: 補足: npm は ALL_PROXY を読まない

[この節の検証記録](../verification/npm-offline.md#実施手順--手順-2-補足-npm-は-all_proxy-を読まない)

**npm が読むプロキシの環境変数は、`https_proxy`・`http_proxy`・`proxy`・`no_proxy` だけ**（大文字でもよい）。npm 10.9 に同梱の `@npmcli/agent` の `lib/proxy.js`:

```
const PROXY_ENV_KEYS = new Set(['https_proxy', 'http_proxy', 'proxy', 'no_proxy'])
...
    proxy = url.protocol === 'https:'
      ? PROXY_ENV.https_proxy
      : PROXY_ENV.https_proxy || PROXY_ENV.http_proxy || PROXY_ENV.proxy
```

- npm のレジストリは https なので、使うのは `https_proxy` だけ。ssh-socks-tunnel.md の手順 3 の `ALL_PROXY` は読まない
- `socks5h://` は、同梱の `socks-proxy-agent` が受け付ける（`socks`・`socks4`・`socks4a`・`socks5`・`socks5h`）。`h` を落とすと、名前をオフラインのホストで引いて失敗する（[ssh-socks-tunnel.md 手順 3](../ssh-socks-tunnel.md#実施手順) の補足）

**設定の値は、環境変数より優先される。**

**`https_proxy` は、curl と git も読む。** 値は `ALL_PROXY` と同じなので、このシェルの brew も同じプロキシを使う。

**`~/.bashrc` や `~/.npmrc` には書かない。** トンネルがあるのは ssh-socks-tunnel.md の手順 2 の ssh の間だけなので、このシェルにだけ入れる（[選択した方針](#選択した方針)）。

### 実施手順 / 手順 3: 補足: Mason が npm を動かす仕組みと、ファイルを開く理由

[この節の検証記録](../verification/npm-offline.md#実施手順--手順-3-補足-mason-が-npm-を動かす仕組みとファイルを開く理由)

**Mason（2.3.1）は、npm のパッケージを `~/.local/share/nvim/mason/packages/<名前>` に入れる。** そのディレクトリで `npm init --yes --scope=mason` と `npm install <名前>@<版>` を実行し、`~/.local/share/nvim/mason/bin/` からリンクを張る。

- npm は PATH から探し、環境変数は Neovim のものを引き継ぐ。手順 2 のシェルから開くのは、`https_proxy` を npm に渡すため
- 入れたコマンドは `#!/usr/bin/env node` で始まるので、動かすたびに手順 1 の Node.js を使う
- Mason のパッケージの一覧（mason-registry）は、GitHub のリリースから curl で取る。curl は `ALL_PROXY` も `https_proxy` も読む

**ファイルを開くのは、LSP サーバーも入れさせるため。** LazyVim は、Mason に入れさせるものを 2 か所に持つ。

- ツール（mason.nvim の `ensure_installed`。stylua・markdownlint-cli2 など）: Mason が読み込まれたときに入る
- LSP サーバー（json-lsp・marksman など）: ファイルを開いて nvim-lspconfig が読み込まれたときに入る。Mason もこのときに読み込まれる

**LazyVim は、入れる LSP サーバーを Mason のパッケージの一覧から選ぶ。** 開いた時点で一覧がまだ無い（初めて取るところ）と、その回は LSP サーバーを入れない。

**入れている途中で `:qa` すると、確認は出ず、その導入は止まる。** 次に開いたときに、Mason がやり直す。

### 選択した方針

[この節の検証記録](../verification/npm-offline.md#選択した方針)

| 経路 | 要るもの | 採否 |
|---|---|---|
| **AppStream の `nodejs`（22 系）と、シェルの `https_proxy`** | ssh-socks-tunnel.md のトンネルと dnf のプロキシ | **採用。** 言語処理系は AppStream から入れる方針（[導入元一覧](../tool-catalog.md)）で、`dnf upgrade` で上がる。npm にだけ変数を 1 つ足せば、Mason を書き換えずに npm がトンネルを通る |
| AppStream の `nodejs24`（24.19.0） | 同上 | 不採用。コマンドが `node-24`・`npm-24` で、Mason が探す `npm` が無い |
| Homebrew の `node` | homebrew-offline.md のトンネル | 不採用。Homebrew の `bin` が PATH で先に来るので、RPM の node と npm を隠す。版を選ぶなら mise（[導入元一覧](../tool-catalog.md)） |
| `~/.npmrc` に `https-proxy=socks5h://127.0.0.1:1080` を書く | — | 不採用。トンネルが無いときも npm が 1080 番に向かい続ける。dnf のプロキシの行（ssh-socks-tunnel.md の[dnf にもトンネルを使わせる（任意）](../ssh-socks-tunnel.md#dnf-にもトンネルを使わせる任意)）と違い、書かなくても済む |
| `ALL_PROXY` だけ | — | 動かない。npm は `ALL_PROXY` を読まない（[手順 2](../npm-offline.md#実施手順) の補足） |
| npm のキャッシュ・Mason のディレクトリを運ぶ、社内に npm のミラー（Verdaccio など）を建てる | 同じアーキのホスト、運ぶ手段、ミラーのサーバー | 本書では扱わない（ネットワークで届かないときの方法） |

- **Mason の導入を、`nvim --headless` のコマンドにしなかった**
  - `nvim --headless '+MasonInstall <名前>' +qa` の `:MasonInstall` は、名前を挙げたものが終わるまでしか待たない
  - LazyVim が読み込み時に始めたほかの導入は、`+qa` で止まりうる
  - 読者の設定が入れるものを 1 つずつ挙げる必要もあるので、画面で終わりを見て閉じる形にした
- **`https_proxy` を `~/.bashrc` に書かない**: ssh-socks-tunnel.md の `ALL_PROXY` と同じ理由（トンネルは同書の手順 2 の ssh の間だけ）

### 参照

- [npm Docs — config の `https-proxy`・`proxy`](https://docs.npmjs.com/cli/v10/using-npm/config#https-proxy) — npm のプロキシの設定と環境変数
- [npm/agent の lib/proxy.js](https://github.com/npm/agent/blob/main/lib/proxy.js) — npm が読むプロキシの環境変数と、SOCKS の扱い
- [mason.nvim](https://github.com/mason-org/mason.nvim) — `lua/mason-core/installer/managers/npm.lua`（npm のパッケージの入れ方）、`lua/mason-core/fetch.lua`（curl と wget）
- [LazyVim の LSP の設定](https://www.lazyvim.org/plugins/lsp) — mason.nvim と mason-lspconfig.nvim の `ensure_installed`
- [ssh-socks-tunnel.md](../ssh-socks-tunnel.md) — 前提のトンネルと dnf のプロキシ。手順 4 で同書の「トンネルを閉じる」の手順 1・2 を使う
- [homebrew-offline.md](../homebrew-offline.md) — 前提の Homebrew（Neovim をトンネル越しに入れる）
- [neovim.md](../neovim.md) — 前提の Neovim と、自分用の設定への案内

---
