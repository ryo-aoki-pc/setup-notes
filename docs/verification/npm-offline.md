# npm をインターネットに出られないホストで使う手順（AlmaLinux 10 / AppStream の Node.js / Neovim の Mason）の検証記録

[手順書](../almalinux-setup.md#npm-のオフライン導入-実施手順)・[ロールバックと注意点](../extra/npm-offline.md)

## 最新の追加確認（2026-10-13 UTC）

- **状態**: OFFLINE-FIRSTINSTALL で AppStream の Node.js 22.23.2／npm 10.9.8 を初回導入し、同じオフラインシェルのプロキシ経路と npm PONG を確認した（[追加付録](#付録-ssh-承認後の初回取得と-mason-の部分確認2026-10-13-utc)）
  - 初回 Mason の実 TUI で Installed 11件、現在の通知、11実コマンド・checkhealth を確認。Installing 中の npm 実コマンドは未観測で、原文の手順 3 は部分確認
  - 切断後の対照と再起動後の実Anthy変換は未実施。共通台帳61件の42通過・4条件外・3部分確認・1失敗・11未実施を用途別に再加算しない

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 のクリーンインストール VM でも検証した手順書**（2026-10-06、SELinux Enforcing）で、実機では本実行していない。Mason は、上流の LazyVim starter に加え、今回の新規 VM では自分用の LazyVimStarter でも確かめた（[対象と検証環境](#対象と検証環境)）。
>
> - トンネルを張っている間は、オフラインのホストのどのユーザーも `127.0.0.1:1080` を通って外に出られる（[ssh-socks-tunnel.md の注意点](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/extra/ssh-socks-tunnel.md#注意点)）

### 実施手順 / 手順 1: 本文中の記録

   - `nodejs`・`nodejs-npm` と不足する依存が入り、`Complete!` で終わる（以前のコンテナでは計 9 パッケージ、2026-10-06 の Workstation の VM では計 5 パッケージだった）

### 実施手順 / 手順 1: 補足: 入るパッケージと、ほかの Node.js

**トンネル越しに 9 パッケージ（ダウンロード 42 MB、導入後 219 MB）が入った。** コンテナでの実測（`Installed:` の行だけ）:

```
Installed:
  c-ares-1.34.6-2.el10_2.x86_64                 libbrotli-1.1.0-7.el10_1.x86_64          libuv-1:1.52.1-1.el10_2.x86_64                   nodejs-1:22.23.2-1.el10_2.x86_64          nodejs-docs-1:22.23.2-1.el10_2.noarch
  nodejs-full-i18n-1:22.23.2-1.el10_2.x86_64    nodejs-libs-1:22.23.2-1.el10_2.x86_64    nodejs-npm-1:10.9.8-1.22.23.2.1.el10_2.x86_64    openssl-1:3.5.8-1.el10_2.alma.1.x86_64
Complete!
```

- `nodejs` は `nodejs-npm` を弱い依存（`Recommends`）で引くので、`nodejs` だけでも npm は入る。`install_weak_deps=False` のホストでも入るように、2 つとも名前で挙げた
- `npm` という名前でも入る（`nodejs-npm` が `npm` を提供する）
- AppStream には `nodejs24`（24.19.0）もあるが、コマンドの名前が `node-24`・`npm-24` になる。Mason は `npm` という名前で探すので使わない（[選択した方針](../reference/npm-offline.md#選択した方針)）

### 対象と検証環境

- **目的**: インターネットに出られない AlmaLinux 10 のホストで、Neovim の Mason が、npm で配られているパッケージ（LSP サーバー・リンターなど）を入れられるようにする
  - 入れる・上げるときだけ、[ssh-socks-tunnel.md](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/ssh-socks-tunnel.md) のトンネルで外に出る
  - 入れたパッケージは、トンネルが無くても動く
- **進め方**: AppStream の Node.js と npm を dnf で入れ、npm には `https_proxy` でトンネル（`socks5h://127.0.0.1:1080`）を使わせる。そのシェルから Neovim を開き、Mason に入れさせる
  - この文書には変数が無い。オンラインのホストの変数は、ssh-socks-tunnel.md の手順 1 にある
- **状態**: **x86_64 のクリーンインストール VM で現行の実施手順 1〜5 とロールバック 1・2 を検証済み（2026-10-06、SELinux Enforcing）。個人用 LazyVimStarter `ae7f049` の Mason 11 ツールも導入完了。実機・aarch64 は未実施**
  - これは 2026-10-06 の時点の状態
  - 現行版を新規 VM で通した範囲は[今回の再検証の付録](#付録-現行版を新規-vm-で再検証2026-10-06)。以前の VM・コンテナの付録と未確認事項は、当時の範囲の記録。
  - このクラウドのホスト（Ubuntu 24.04）の Docker で、外に出られないネットワーク（`--internal`）だけにつないだコンテナをオフラインのホストにした（homebrew-offline.md と同じ形）
  - Mason を使う設定は、上流の [LazyVim/starter](https://github.com/LazyVim/starter) に、LazyVim の extra の `lang.json` と `lang.markdown` を足したもの。自分用の設定（LazyVimStarter）では確かめていない
  - 前提（当時の homebrew-offline.md の手順 1〜5。今の ssh-socks-tunnel.md の手順 1〜3・dnf の節と homebrew-offline.md の手順 1〜3。neovim.md の手順 1（今の AlmaLinux 10 の初期設定の「Neovim」の手順 1）、LazyVim の starter）をトンネル越しに通した状態から、**この文書のコードブロックをそのまま**、擬似端末で開いたオンラインのホストの対話の bash に貼って、手順 1〜5、[更新](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/npm-offline.md#更新)、[ロールバック](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/extra/npm-offline.md#ロールバック)を通した
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
> この文書には変数が無い。オンラインのホストの変数（`OFFLINE_HOST`・`OFFLINE_USER`）は、[ssh-socks-tunnel.md 手順 1](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/ssh-socks-tunnel.md#実施手順) で設定する。
>
> 出力例・ログ・表の中の値は `<OFFLINE_HOST>` / `<USER>`（ユーザー名）のプレースホルダで書いてある。バージョン（`22.23.2` など）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

- **状態（2026-10-11）**: Hyper-V の R6 を C14 の途中終了と C15 の続行に分けて記録した（2026-10-11、Codex）
  - C14 は前提導入中に応答喪失し本文・更新未実施。C15 は実施手順 1〜5・更新 1〜3を通し、npm 4 件と更新時の Mason 11 件を確認。ロールバック・実機・aarch64 は今回未実施
  - 詳細は[今回の付録](#付録-hyper-v-の-vm-で通した記録2026-10-11)

### 実施前の状態

オフラインのホスト（コンテナ）で、手順 1 の前に確かめた状態:

| 項目 | 状態 |
|---|---|
| トンネルと dnf | 当時の homebrew-offline.md の手順 1〜4（今の ssh-socks-tunnel.md の手順 1〜3 と dnf の節、homebrew-offline.md の手順 1）を通した。`/etc/dnf/dnf.conf` に `proxy=socks5h://127.0.0.1:1080` がある |
| Homebrew / Neovim | 当時の homebrew-offline.md の手順 5（今の手順 3）で Homebrew 7.0.7、neovim.md の手順 1 で `neovim 0.12.5_1` |
| Neovim の設定 | `~/.config/nvim` に LazyVim の starter と、extra の `lang.json`・`lang.markdown`（`lazyvim.json`）。プラグインはトンネル越しに入れてある |
| Node.js / npm | 無い（`node`・`npm` が無く、`~/.npm` も無い） |
| Mason | 入っているのは shfmt・tree-sitter-cli・lua-language-server・marksman（GitHub のリリースから取るもの）。markdownlint-cli2・markdown-toc・json-lsp は `Could not find executable "npm" in PATH.` で、stylua は `Could not find executable "unzip" in PATH.` で失敗していた |

### 完了時点の状態

**検証のコンテナでの出力**（[手順 5](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/npm-offline.md#実施手順)。転送無しでログインし直したオフラインのホストのシェル）:

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
- `/etc/dnf/dnf.conf` の `proxy=socks5h://127.0.0.1:1080` は残る（[ssh-socks-tunnel.md のロールバック](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/extra/ssh-socks-tunnel.md#ロールバック)の手順 1 で消す）
- `~/.npm` に npm のキャッシュが残る（[ロールバック](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/extra/npm-offline.md#ロールバック)の手順 2 で消す）

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
- Homebrew の node が入っているホスト（[手順 2](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/npm-offline.md#実施手順) の `command -v`）
- install スクリプトの中で自分でファイルを取る npm のパッケージ
- キャッシュ（`~/.npm`）が無いホストで、`https_proxy` を入れ忘れたときに Mason の npm の導入がどう終わるか
- 長い導入の途中で ssh が切れたとき

---

### 付録: VM での検証記録（2026-10-06）

**環境**: [クリーンインストールからの検証記録](../almalinux-vm-verification.md)のオフライン用 VM。公式 ISO から Workstation を入れた状態から始め、x86_64、SELinux Enforcing、firewalld 有効。本文のブロックを SSH の擬似端末で実行した。

- [homebrew-offline.md の今回の記録](homebrew-offline.md#付録-vm-での検証記録2026-10-06)と同じ VM で、dnf の SOCKS 設定と Neovim の導入を前提から用意した。本文の主手順を SSH の擬似端末で通した。
- 手順 1 で AppStream の Node.js 22.23.2 と npm 10.9.8 が、計 5 パッケージで入った。手順 2 のコマンドの場所は `/usr/bin/node` / `/usr/bin/npm`、プロキシの設定ファイルの値は両方 `null`。`https_proxy` を入れると `npm ping` は `PONG 384ms` だった。
- 個人用の設定は使わず、検証用に上流 LazyVim starter（commit `803bc181d7c0d6d5eeba9274d9be49b287294d99`）を取得した。Homebrew の Neovim 0.12.5、LazyVim の 32 プラグイン、Mason 2.3.1 を使用。設定の取得は手順書の外の準備。
- 手順 3 の Neovim を開き、Mason に不足していた `markdownlint-cli2` と `json-lsp` を `:MasonInstall markdownlint-cli2 json-lsp` で指定した。Mason のログは両方 `Installation succeeded`。導入中にもプロキシ無しの直接通信は終了 7 だった。
- 手順 4 では転送を保持した SSH と Neovim の端末を閉じ、転送無しで再ログインした。手順 5 でプロキシ環境変数は無く、Mason の bin に `markdownlint-cli2` / `vscode-json-language-server` / `shfmt` / `stylua` / `tree-sitter` があった。リンターのヘルプは `markdownlint-cli2 v0.23.3 (markdownlint v0.41.1)`、`npm ping --fetch-retries=0` は ENOTFOUND と `届かない（期待どおり）` だった。
- 今回は LSP として JSON を編集する動作、npm の設定ファイルに競合する値がある場合、更新・ロールバック、個人用設定、実機・aarch64 は確認していない。以前のコンテナの結果と区別する。

---

### 付録: 現行版を新規 VM で再検証（2026-10-06）

**対象**: `setup-notes` の `5da3478` 版。公式 ISO の Workstation クリーンインストールの `clean-install` スナップショットから、新規の `alma10-current-20261006-offline` を作った。AlmaLinux 10.2 / x86_64 / SELinux Enforcing / firewalld 有効。共通 bash は `3d5323e` を新規導入した。以前の付録と別の試験で、現行ブロックを SSH の擬似端末で順に実行した。

- 実施手順 1〜5 を通した。AppStream の Node.js 22.23.2 / npm 10.9.8 が入り、設定ファイルの proxy / https-proxy はともに `null`。`https_proxy=socks5h://127.0.0.1:1080` を足すと `npm ping` が通った。
- 今回はサブモジュールと同じ個人用 LazyVimStarter `ae7f049` を公開リポジトリから取得した。Neovim 0.12.5_1 を導入し、プラグインを初回取得・lock に復元した後、本文の `nvim -R ~/.config/nvim/init.lua` を実際の端末で開いた。Mason の実画面は `Installed (11)`、導入中は 0 件。npm の bash-language-server / json-lsp / markdownlint-cli2 / yaml-language-server を含む 11 ツールの導入完了を receipt とログでも確認した。上流 starter のみだった以前の VM 試験を置き換えず、追加した範囲である。
- Neovim と転送を保持した接続を終了し、転送無しで再ログインした。Mason bin は 11 コマンドを保持し、`markdownlint-cli2 --help` は `v0.23.3 (markdownlint v0.41.1)`。`npm ping --fetch-retries=0` は ENOTFOUND と `届かない（期待どおり）`、IPv4 / IPv6 の既定経路と 1080 の待ち受けも無かった。
- ロールバック 1・2 をトンネル無しで通し、Node.js / npm の RPM と `~/.npm` が無くなった。Mason のファイルは残るが、npm 系ツールの実行には Node.js が必要である。更新、プロキシ設定ファイルとの競合、JSON の編集・LSP 動作、PyPI の追加ツール、実機・aarch64 はこのオフライン再検証では行っていない。

### 手順中の実測・検証状況の記録

- **npm だけは `ALL_PROXY` では足りない**: [手順 2](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/npm-offline.md#実施手順) の `export` を飛ばすと、Mason の npm のパッケージだけが、試し直しを繰り返してなかなか終わらない（検証では 29 分。[手順 3](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/npm-offline.md#実施手順) の補足）

### 手順中の実測・検証状況の記録

- **Homebrew の node が入っていると、Mason はそちらの npm を使う**: Mason は PATH の先頭の `npm` を使い、`brew shellenv` は Homebrew の `bin` を PATH の先頭に置く。[手順 2](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/npm-offline.md#実施手順) の `command -v` で確かめる（本書では、Homebrew の node が入ったホストを確かめていない）

### 手順中の実測・検証状況の記録

- 検証では black が `ERROR: Could not install packages due to an OSError: Missing dependencies for SOCKS support.` で失敗した

### 手順中の実測・検証状況の記録

- GitHub のリリースから入るもの（ruff など）は、この問題が無い。検証では ruff が入った

### 手順中の実測・検証状況の記録

- **npm 以外の理由でも失敗する**: stylua は、`unzip` が無くて `Could not find executable "unzip" in PATH.` で失敗した

### 手順中の実測・検証状況の記録

- トンネルのシェルで `sudo dnf install -y unzip` を実行してから開き直すと、stylua も入った

### 手順中の実測・検証状況の記録

- 入れたパッケージはそのまま使える。検証では、一覧を 2 日前に取ったことにして開き、lua_ls が動いた

### 手順中の実測・検証状況の記録

- **トンネルが無いときに開くと、設定にあって入っていないパッケージの導入が毎回失敗する**: 検証では stylua が毎回 `:MasonLog` にエラーを残した。画面での編集には影響しない

### 実施手順 / 手順 2: 補足: npm は ALL_PROXY を読まない

**設定の値は、環境変数より優先される。** `https-proxy=http://127.0.0.1:9` とだけ書いた設定ファイルを `--userconfig` で読ませると、`https_proxy` があっても、その値に向かった:

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

```
$ npm --userconfig /tmp/t.npmrc ping --fetch-retries=0 2>&1 | grep -E 'code|reason' | head -3
npm error code ECONNREFUSED
npm error FetchError: request to https://registry.npmjs.org/-/ping failed, reason: connect ECONNREFUSED 127.0.0.1:9
npm error   code: 'ECONNREFUSED',
```

- `npm config get` が `null` 以外を返したら、その値を書いた設定（`npm config get userconfig` の `~/.npmrc` など）を見直す

**`https_proxy` は、curl と git も読む。** 値は `ALL_PROXY` と同じなので、このシェルの brew もそのまま通る（`brew update` が `Already up-to-date.` で終わった）。

### 実施手順 / 手順 3: 補足: Mason が npm を動かす仕組みと、ファイルを開く理由

**npm が無いときと、`https_proxy` が無いときの失敗。** 手順 1 の前に Neovim を開いたときの `:MasonLog`（長い行は省いた）:

```
[ERROR …] …InstallRunner.lua:100: Installation failed for Package(name=markdownlint-cli2) error=spawn: npm failed with exit code - and signal -. Could not find executable "npm" in PATH.
[ERROR …] …InstallRunner.lua:100: Installation failed for Package(name=json-lsp) error=spawn: npm failed with exit code - and signal -. Could not find executable "npm" in PATH.
```

- 手順 1 の後に、`https_proxy` を入れずに（`ALL_PROXY` だけで）markdown-toc を入れ直すと、`$ npm install markdown-toc@1.2.0` の行のまま 29 分かかった
- npm は、取得のたびに `ENOTFOUND` で 3 回ずつ試し、最後は、前にトンネル越しに入れたときのキャッシュ（`~/.npm`）から入れた（付録）

- ツール（mason.nvim の `ensure_installed`。stylua・markdownlint-cli2 など）: Mason が読み込まれたときに入る
- LSP サーバー（json-lsp・marksman など）: ファイルを開いて nvim-lspconfig が読み込まれたときに入る。Mason もこのときに読み込まれる
- `nvim` だけで開いて `:Mason` を実行すると、ツールしか入らない。検証では、消しておいた markdown-toc だけが入り、json-lsp はファイルを開いたときに入った
- `-R` は読み取り専用で開く指定。設定のファイルを書き換えないため

- 検証では、一覧を初めて取った回はツールの導入だけが始まり、閉じて開き直した回に LSP サーバー（json-lsp・lua-language-server・marksman）の導入が始まった

**入れている途中で `:qa` すると、確認は出ず、その導入は止まる。** `:MasonLog` には `Installation failed for Package(name=json-lsp) error="Installation was aborted."` と残った。次に開いたときに、Mason がやり直す。

### 実施手順 / 手順 5: 補足: --fetch-retries=0

**npm は、つながらないと既定で 2 回試し直す。** 試し直しを切らないと、`npm ping` が失敗するまで 70 秒かかった。`--fetch-retries=0` を付けると 0.4 秒で失敗した。どちらも同じ `ENOTFOUND` のエラーを出す。

### 選択した方針

| npm のキャッシュ・Mason のディレクトリを運ぶ、社内に npm のミラー（Verdaccio など）を建てる | 同じアーキのホスト、運ぶ手段、ミラーのサーバー | 本書では扱わない（ネットワークで届かないときの方法。確かめていない） |

## 付録: Hyper-V の VM で通した記録（2026-10-11）

### 環境

| 項目 | 値 |
|---|---|
| 実施 | Codex、2026-10-11 UTC。対象は setup-notes `d69f113` |
| ホスト | Windows 11 Pro、Hyper-V |
| VM | Generation 2、構成版 12.0、各 2 vCPU・64 GB・Default Switch の eth0 1 枚、Secure Boot disabled |
| メモリ | オンライン 1536 MB。オフラインは C14 が 2048 MB、C15 が 3072 MB |
| ゲスト | AlmaLinux 10.2 (Lavender Lion)、x86_64、kernel `6.12.0-211.64.1.el10_2.x86_64` |
| 開始 | オンライン `<HOSTNAME>` は after-AS4、オフライン `<OFFLINE_HOST>` は clean-install（依頼の前提）。C15 は C14 終了時の partial-R6 を保存した既存ディスクから続行し、復元・再作成はしていない |
| 状態 | オフラインの SELinux Enforcing・firewalld active。既定経路・DNS を外し、IPv6 を無効にしたのは手順書の外の準備 |
| 導入版 | Homebrew 7.0.9、jq 1.8.2、Neovim 0.12.6、LazyVimStarter `8e4a074`、Mason 2.3.1、共通 bash `67abb84` |
| 貼り方 | SSH の対話の bash にドライバでブロックを順に貼り、オンラインからオフラインの `<USER>` にパスワード SSH。C14 は両 VM の GNOME に画面操作でログインし、C15 は GNOME にログインしなかった |

- 証跡はリポジトリに入らない `D:\vmverify\codex\units\C14\`・`C15\` の下。表の C14・C15 はその単位からの相対パスで、seq は `session/steps.jsonl` の番号
- `meta.json` の snapshot はどちらも clean-install と書くが、Existing 呼出しの既定値。開始元の復元を裏付ける値ではない
- R6 は 2 回に分かれた。C14 は npm の前提導入中にオフライン VM が応答しなくなり中止。C15 はメモリを 2048 MB から 3072 MB にし、GNOME にログインせず続けたところ再発しなかった。原因は分かっていない（[npm の記録](#付録-hyper-v-の-vm-で通した記録2026-10-11)）
- C14 のログイン後の PNG は、`screens/online/login-20261011-113934-3-after.png` がアクティビティ画面、`screens/offline/login-20261011-114023-3-after.png` がようこそ画面。本文の操作は GNOME の端末への貼り付けではない

### 手順ごとの結果

| 回・節・手順 | 結果 | 根拠・確認 |
|---|---|---|
| C14 前提 / Neovim 1・2 | 通した | C14 `online/session/steps.jsonl` seq 33〜35、`online/session/after-confirm/0035-実施手順-Neovim-2.txt`。0.12.6 の bottle と場所 |
| C14 前提 / 設定の依存導入 | 初回は通らなかった、補完後は通した | 同 seq 36〜42、`online/session/session-001.raw`。EPEL 無しで wl-clipboard が見つからず、参照先の EPEL 1・2 を補い、同じ依存ブロックが完了 |
| C14 前提 / 設定配置・プラグイン取得 | 通した | 同 seq 43〜52、`offline/session/steps.jsonl` seq 5。設定 HEAD `8e4a074`、headless 取得と lock 復元 |
| C14 前提 / LazyVimStarter 手順 17 | 通らなかった | 同 seq 53〜56、`online/session/session-001.raw`、`offline/session/steps.jsonl` seq 6・7。Mason Installed 5 / Installing 4 / Queued 2、操作応答を失った |
| C14 実施手順 1〜5・更新 1〜3 | 未実施 | C14 の steps は前提で終了。Node/npm が依存として入ったことと、本文を貼ったことは別 |
| C15 実施手順 1 | 通した | C15 `online/session/steps.jsonl` seq 6・7、`online/session/session-001.raw`。Node/npm 導入済み、「行うべきことはありません」「完了しました!」 |
| C15 実施手順 2 | 通した | 同 seq 8、`online/session/after-confirm/0008-実施手順-2.txt`。v22.23.2 / 10.9.8、/usr/bin/node・npm、null 2 行、PONG 233ms |
| C15 実施手順 3 | 通した（npm 4 件） | 同 seq 9〜13、`online/session/session-001.raw`。Installed 9、bash-language-server・json-lsp・markdownlint-cli2・yaml-language-server の成功ログ。lua-language-server・marksman は残存 lockfile で失敗 |
| C15 実施手順 4 | 通した | 同 seq 14〜16・18。参照先の exit と転送無し再ログインを実施。seq 18 は手順を行ったことの後からの記録で、操作は手順 5 の前 |
| C15 実施手順 5 | 通した | 同 seq 17、`online/session/after-confirm/0017-実施手順-5.txt`。env 無出力、bin 9 コマンド、markdownlint-cli2 v0.23.3 (markdownlint v0.41.1)、ENOTFOUND と「届かない（期待どおり）」 |
| C15 更新 1 | 通した | 同 seq 24・25、raw。Node/npm の更新対象無し |
| C15 更新 2 | 通した（一覧更新） | 同 seq 26〜32、raw、`mason-update-notice.txt`。Successfully updated 1 registry.、Installed 11。U の案内無しで、パッケージ更新は条件に当たらず飛ばした |
| C15 更新 3 | 通した | 同 seq 33、raw。exit でオンラインに戻った |
| extra ロールバック | 未実施 | C14・C15 の steps に実施記録無し |

### 通らなかった手順と見立て

- C14 は EPEL 未導入で依存導入に失敗した。EPEL を補うと同じブロックが通ったため、clean-install と初期設定の「EPEL 済み」の仮定の違いと判断した
- C14 の Mason は ALL_PROXY がある一方、本文手順 2 の https_proxy はまだ無かった。npm が使うプロキシの順序に問題がある見立てだが、npm のエラーを読む要求も timeout になったので、今回の通信失敗の理由は確定していない
- C14 の応答喪失後の `screens/offline-mason-state.png` は黒い画面。Mason の確認には使えない。新規 SSH の banner timeout は C14 の報告にあり、steps にその診断の出力は無い。停止原因を SSH の貼り方・Hyper-V・OOM のいずれとも断定しない
- C15 `offline/session/session-001.raw` の前回起動の journal 読み取りは `no persistent journal was found`。OOM の有無は確かめられなかった。3072 MB・GNOME 未ログインで再発しなかったことだけを確認した
- C15 は設定導入済みを前提にして開始した。開始時の Mason packages は 5 件で、本文で npm 4 件が加わった。残存ロックの 2 件は更新で開き直すと自動で成功した。手動削除はしていない。C14 の前提導入の失敗判定を上書きしない
- TUI の件数・通知は raw の画面文字で確認。GNOME の PNG による Mason の確認ではない。C15 の報告末尾の負の所要時間は記録時刻と整合しないので、所要時間の根拠にしない

### 指摘と状態・手順書を直した所

| 指摘 | 状態 | 直した所と根拠 |
|---|---|---|
| 前提で npm の導入完了まで必要に見える | 直した（文言） | 実施手順のリードに「Mason の npm のパッケージは、まだ入っていなくてよい」を追加。C15 `offline/session/steps.jsonl` seq 2 と本文 seq 9〜13 で、設定のみの開始と後からの npm 導入を確認 |
| dnf の導入済み・更新無しの出力が英語だけ | 直した（文言） | 実施手順 1・更新 1 に日本語の完了・更新無しを併記。C15 raw の seq 6・24 に対応する出力。ブロックは変更無し |
| 初期設定の EPEL 前提と clean-install の違い・Neovim の版の例 | 未対応（司令塔に渡す） | 対象外の初期設定の修正案として報告 |
| 初期設定の Neovim 参照で npm の導入を先に要求する順序 | 未対応（司令塔に渡す） | 本文の前提の一文だけでは参照先の成功条件は変わらない |
| 応答喪失の原因・入れ子 SSH の状態表示 | 未対応 | 原因未確定。道具の表示はゲストの確認出力と区別 |

### 確かめていないこと

- LazyVimStarter の手順 18、初期設定の Neovim 手順 4、JSON 編集の LSP 動作、GUI のフォント・IME、実機・aarch64・PyPI・Homebrew の node が先にある環境は今回未実施
- 更新対象を用意した Node/npm・Mason の更新、ロールバック、設定ファイル競合、キャッシュ無しの取得、長い取得中の意図的切断は未実施
- 従来の VM の 11 件導入・撤去と、今回の 5→9→11 件および残存ロックの結果は別の履歴


## 付録: 既存2VMでオフライン経路を継続した記録（2026-10-12、OFFLINE-FULL）

- **状態**: 旧workerの停止と所有旧ロックの解放後、既存の専用2VMから継続した。新規clean-installからの通し実行ではない
  - 原文は setup-notes `6a4520d` と開始前からの案内2箇所。main集約後の [AlmaLinux本文](../almalinux-setup.md)を原文ドライバで実行した
  - 公開本文・工具35件、固定snapshot ID・親鎖・全Hyper-V参照、停止親5ファイルを開始時と終了時に照合。元の安定性baselineと一致し、expectedは変更していない
  - 過去との歴史的内容一致はこのbaselineだけでは証明しない。旧C14/C15の失敗・未確認範囲、旧workerの記録と前回承認拒否の履歴を保持した

| 環境 | 内容 |
|---|---|
| ホスト・VM | Windows 11 Pro / Hyper-V / Generation 2 / 構成版12.0。online 2 vCPU・2048MB、offline 4 vCPU・4096MB、各64GiB、Default SwitchのNIC、Secure Boot disabled |
| ゲスト | AlmaLinux10.2 / x86_64 / kernel 6.12.0-211.64.1.el10_2.x86_64 |
| 起点 | onlineの元固定snapshotはafter-AS4、offlineはclean-install。今回はその子の既存状態を続け、復元・再作成していない |
| 貼付 | onlineの対話bashからofflineの `<USER>` へ入れ子SSH。同じシェルでALL_PROXY/https_proxyを設定。54貼付中、51は原文一致、3は許可されたOFFLINE_HOSTの単一変数置換 |
| 証跡 | `verification-work/queued-units/OFFLINE-FULL/recovery-after-lock-20261012/`。表のseqはonline-session/steps.jsonl、補助観測はoffline-observe/steps.jsonl。rawは公開・commitしない |

| 現行の項 / 手順 | 判定 | 根拠と確認 |
|---|---|---|
| npm のオフライン導入: 実施手順 / 1 | 既存導入を確認 | seq24。AppStream nodejs/nodejs-npmが既存、Nothing to do/完了 |
| 同じ項 / 2 | 通した | seq25。Node22.23.2/npm10.9.8、/usr/bin、設定null/null、PONG232ms。今回最初のNeovim取得より前に同じshellでhttps_proxy設定 |
| 同じ項 / 3 | 実TUIの導入完了状態を確認 | seq41–43。原文nvim -R init.lua、:MasonのInstalled11にmarkdownlint/json等、:qaでoffline shell。Installing→Installed遷移と新規取得通知は未捕捉、初回取得の成功にしない |
| 同じ項 / 4 | 通した | seq44–46の原文閉鎖1/2。続くseq47で1080なし/curl失敗。Homebrew実施5と共用 |
| 同じ項 / 5 | 通した | seq49。proxy環境出力なし、Mason11コマンド、markdownlint-cli2 v0.23.3、npm ENOTFOUND後に期待どおり失敗 |
| npm のオフライン導入: 更新 / 1 | 更新対象なしで完了 | seq71。dnf upgradeはNothing to do/完了。新版導入はしていない |
| 同じ項 / 2 | レジストリ更新を確認、package更新は条件スキップ | seq72–79。:MasonでInstalled11/U案内なし。driver表示が重なったため表示中の公開Noice通知bufferだけを実抽出し、補助offline seq5でSuccessfully updated 1 registry.を確認 |
| 同じ項 / 3 | 通した | seq80のexitでonline復帰。補助offline seq6で1080/proxyなし、実IPv4直接curl000/終了7、ローカル版と設定git status空を確認 |

- 前提: EPEL1はseq21でenabled。Neovim1/2はseq22–23で既存0.12.6。既存LazyVim設定はf1d5363c624280bf863893324a1b7954f8a884de/custom、公開docs/setup.mdの集約先を確認した
- 現Alma「LazyVim の設定を導入する」1/2・4–12を継続し、依存12RPMと4Homebrew実行パス、us/Anthy、on_off、lock restore、実Mason Installed11、healthの許容fzf警告だけを確認。3の既存データ退避と初回cloneは再実行せず、初期Neovim3全体の新規導入成功にしない
- 開始前からの案内2箇所を採用: 初期Neovim3からnpm1/2を先行させ、npm用途節も初回headless起動より先に経路を設定する案内へ揃える。今回seq25→36の順で検証した。過去実行やキャッシュなし初回取得を証明するものではない
- E1568の端末応答警告と通知の重複は道具/表示上の問題として残す。成功通知は推測せず実公開bufferで確認し、旧privateログやMasonLogを読んでいない
- 旧C14/C15と旧workerの応答喪失原因は未確定。今回のメモリ/依存順序/GNOME条件から、昔の原因や修正効果を断定しない
- 全セッションを閉じ担当2VMは通常停止でOff、継続名の新snapshotを保存。更新対象ありのNode/npm/Mason更新、キャッシュなし初回取得、PyPI、JSON編集LSP、Neovim内IME、フォント、ロールバック、実機/aarch64/他列は今回未実施

## 付録: 初回オフライン試行の中断記録（2026-10-12 11:17 UTC）

OFFLINE-FIRSTINSTALL は凍結原文 `27857989d9f0b492b6bd6396fed3a8c2155ea7cf` で、新しい online/offline の 2 VM を専用 D 差分に作成した。固定した停止親 5 件の全体 SHA と親鎖は保持 baseline に一致。offline の実 GUI で「ログインと sudo」手順 1・2 を確認したが、手順 3 の NOPASSWD ALL 永続設定は自動承認審査が拒否し、未送信・設定不変更だった。

対象 61 番号のうち 2 確認・59 未実施。npm のオフライン導入の実施手順 1〜5・更新、初回 LazyVim clone、Mason の新規取得・Installing から Installed への遷移・通知・実コマンドは未実施。GUI 前提の 2 件を npm や LazyVim の導入成功へ数えず、既存 Installed 11・レジストリ更新の継続記録と区別する。

2 VM は通常 Off、自己 lock 解放、6 GiB 返却。通常の sudo 認証で続ける案は準備だけで、認証・取得成功ではない。根拠は今回専用 `verification-work/queued-units/OFFLINE-FIRSTINSTALL/parallel-20261012` の公開判定表・画面、拒否と終了の公開記録。この中断を後日の成功で置き換えず、同じ 2/61 を他の検証記録と重複加算しない。

## 付録: 通常sudo認証で前提を追加確認した記録（2026-10-12 12:27 UTC）

凍結原文 `2785798` で、11:17に停止した同じ専用2VMを続行した。旧GUI2件に、システムの設定1の変数読み戻し・同3のSSH待受とfirewall確認・SOCKSトンネル実施手順1の変数読み戻しを追加した。計61番号は5通過／1条件skip／1未達partial／54未実施（元sudo3を含む）。追加3件はSSH TTY搬送で、GNOME/Ptyxisへの原文貼付成功ではない。

設定3の通常sudo対話認証は、実TTY・前面sudo・echo無効を確認して既存masked helperで通した。元sudo3のNOPASSWD ALL設定は未実施。SOCKS2のSSHパスワード送信は「前面sudo限定の許可がSSH認証を含まない」と自動審査が拒否し、秘密未送信で中断した。

Homebrew・jq・npm・初回LazyVim clone・Mason取得は未開始。npmオフライン実施1〜5・更新、Installing→Installed・通知・実コマンドは未実施で、旧Installed11／レジストリ更新の継続結果へ加算しない。2VMを通常Off、自己lock解放、6GiB返却。旧11:17の付録は当時の記録として保持する。

根拠は専用 `verification-work/queued-units/OFFLINE-FIRSTINSTALL/parallel-20261012/normal-auth-20261012T115622Z/` の公開番号台帳・completion、通常sudoのauth-facts、`nested-ssh-auto-approval-rejection.json`、終了時照合・解放receipt。原文132MD／工具20／停止親5件の全体SHA・親鎖は開始・終了とも保持baselineに一致し、expectedは変更していない。

## 付録: SSH 承認後の初回取得と Mason の部分確認（2026-10-13 UTC）

OFFLINE-FIRSTINSTALL の公開 `ssh-approved-20261013T0325Z` result・completion に基づく追記。凍結原文は `27857989d9f0b492b6bd6396fed3a8c2155ea7cf`。現在の対応先は [npm のオフライン導入: 実施手順](../almalinux-setup.md#npm-のオフライン導入-実施手順)で、以前の既存 Installed 11件や registry 更新とは別の初回取得である。

| 原文の項／手順 | 今回の確認と残件 |
|---|---|
| npm のオフライン導入: 実施手順／1・2 | 初回 AppStream Node.js 22.23.2／npm 10.9.8 の取得・導入、npm設定 null／null と PONG を確認。初回 LazyVim 手順10より先に実施 |
| 同じ項／3（npm3） | 初回 Mason の実 TUI で Installed 11件の実名、現在の UI 通知で LSP 導入開始・成功、11実コマンドを確認。**Installing 中の npm 実コマンドは未観測のため partial** |
| 同じ項／4・5（npm4・npm5） | 切断後の再ログイン・プロキシなし対照は未実施。初回 PONG を切断後の通信失敗やオフライン実行の成功へ代用しない |

- **Mason と Neovim**: 初期不在を実観測し、LazyVimStarter の初回 clone、38 plugin directory、lock復元後の tracked dirty0、checkhealth の ERRORなしを確認した
  - WARNING は原文が許容する fzf 未導入だけ。registry更新と package導入は分けて判定した。Installing時の実コマンドは Installed／通知／実行コマンドから遡って補完せず、別の真正な初回機会での観測が残る
  - 原文 Neovim 手順3（nvim3）も RPM Fusion 前提と後続全条件が揃わず partial。[Neovim の記録](neovim-offline.md#判定表と残件)に条件差・IME未確認を分ける
- **閉鎖と停止**: 原文 `exit` だけでは forward channel／listener が残った（close1 partial）。自己transportの通常切断では外側driverも切れ、原文のオンラインprompt復帰・切断後対照には数えない
  - 04:53:29 UTC の監視metadata例外で自己2VMを通常Off。原文132MD・工具20・停止親5件は一致、expected不変更。05:14:21にOff・割当0・自己lock不存在を再確認し、6144 MiB返却

共通台帳は61件中42通過・4条件外・3部分確認・1失敗・11未実施で、旧5通過を含む。[時点別集計と失敗理由](../hypervisor-verification.md#付録-公開結果の追加確認2026-10-13-utc)を参照し、Homebrew／Neovim／本書の同一導入を重複加算しない。旧2/61・5/61、中断・承認拒否、過去の切断後成功はそれぞれ当時の記録として残す。
