# Homebrew をインターネットに出られないホストで使う手順（AlmaLinux 10 / ssh -R の SOCKS プロキシ）

## 実施手順

- [検証記録](verification/homebrew-offline.md)・[参考資料](reference/homebrew-offline.md)

> [!IMPORTANT]
> - **前提**: [ssh-socks-tunnel.md](ssh-socks-tunnel.md) の手順 1〜3 で、インターネットに出られるホスト（以下、オンラインのホスト）からトンネルを付けて、インターネットに出られないホスト（以下、オフラインのホスト）にログインしてあること。**この文書は、同書の手順 3 のシェルのまま貼る**（Homebrew の通信もトンネルを通すため）
> - **オフラインのホストには、`sudo` できる自分のユーザーでログインする**（同書の手順 1 の `OFFLINE_USER`）。root ではログインしない（Homebrew の導入・更新は root では行わない）
> - **手順 3 で [AlmaLinux 10 の初期設定の手順 46〜48](almalinux-setup.md#実施手順)（Homebrew）を、同じシェルのまま貼る**
> - **手順 3・4 には対話入力がある**（インストーラの `RETURN`、brew の `[y/n]`）。終わってから次の手順を貼る
> - **手順 5 はトンネルを閉じてログインし直す**（オンラインのホストで行う操作がある）

- 上から順に、ssh-socks-tunnel.md の手順 3 のシェルで貼る
- 手順の後: ほかの Homebrew 系の手順（[AlmaLinux 10 の初期設定の手順 49](almalinux-setup.md#実施手順)や [yazi](yazi.md) など）は、ssh-socks-tunnel.md の手順 1〜3 でトンネルを張ったシェルで貼る。以後は[更新](#更新)・[ロールバック](#ロールバック)
- Neovim の Mason に npm のパッケージを入れるなら、手順 5 でトンネルを閉じる前に、このシェルで [npm-offline.md](npm-offline.md) を貼る（npm は `ALL_PROXY` を読まない）

> [!WARNING]
>
> - トンネルを張っている間は、オフラインのホストのどのユーザーもインターネットに出られる（出口はオンラインのホスト。[ssh-socks-tunnel.md の注意点](ssh-socks-tunnel.md#注意点)）。使い終わったら手順 5 で閉じる

1. トンネルのシェルで、Homebrew の取得先に届くかと、Homebrew が使うパッケージを確かめる。

   ```bash
   for u in https://github.com https://raw.githubusercontent.com https://formulae.brew.sh https://ghcr.io/v2/; do
     printf '%-34s %s\n' "$u" "$(curl -sS -o /dev/null --connect-timeout 10 -w '%{http_code}' "$u")"
   done
   rpm -q procps-ng curl file git
   ```

   - 4 つの URL の数字が、どれも `000` 以外なら届いている（ghcr.io はトークンが無いので `401`）
   - `000` と `Failed to connect to 127.0.0.1 port 1080` が出たら、トンネルが無いか、`ALL_PROXY` を入れていないシェルで貼っている（[ssh-socks-tunnel.md 手順 2](ssh-socks-tunnel.md#実施手順) からやり直す）
   - `rpm -q` の 4 つがどれも入っていれば、**手順 2 は飛ばし、手順 3 でも AlmaLinux 10 の初期設定の手順 46 を飛ばす**
   - dnf がトンネル無しで届くリポジトリ（社内のミラーなど）を使うホストなら、手順 2 は飛ばす

1. 手順 1 で入っていないパッケージがあったときだけ、[ssh-socks-tunnel.md の「dnf にもトンネルを使わせる（任意）」](ssh-socks-tunnel.md#dnf-にもトンネルを使わせる任意)を行う。

   - AlmaLinux 10 の初期設定の手順 46 の dnf が、トンネルを通るようになる
   - 足した行は、[ロールバック](#ロールバック)のリードのとおり、ssh-socks-tunnel.md のロールバックで消す
   - **次の手順は、同書の節の `Metadata cache created.` が出てから貼る**

1. 手順 1 のシェルのまま、[AlmaLinux 10 の初期設定の手順 46〜48](almalinux-setup.md#実施手順) を貼る。

   - `command -v brew` が `/home/linuxbrew/.linuxbrew/bin/brew` を返すなら、Homebrew は入っているので、この手順は飛ばす
   - 同書の手順 46 の dnf は、手順 2 の設定で通る（手順 1 で 4 つとも入っていたなら飛ばす）
   - 同書の手順 47 のインストーラも、中で使う curl と git が `ALL_PROXY` を読むので、そのまま通る
   - 同書の手順 48 は、共通の bash 設定（同書の手順 42・43）を入れてあるシェルで貼る（`brew shellenv` は共通設定が実行する）
   - **次の手順は、同書の手順 48 まで終えてから貼る**（同書の手順 47 に `RETURN` の確認がある）

1. 確かめるために、brew で jq をトンネル越しに入れる。

   ```bash
   brew install jq
   ```

   - 入れるものの一覧の後に `==> Do you want to proceed with the installation? [y/n]` と聞かれたら、`y` を押す（Enter は要らない）
   - `==> Pouring jq--…bottle…tar.gz` と出て、ソースからのビルドにならない
   - ほかの Homebrew 系の手順書も、手順 5 の前に、このシェルで貼る
   - **次の手順は、確認が出たら `y` を押し、入れ終わってから貼る**（続けて貼ると、後ろの行の文字が答えとして読まれる）

1. [ssh-socks-tunnel.md の「トンネルを閉じる」](ssh-socks-tunnel.md#トンネルを閉じる)の手順 1〜3 で、トンネルを閉じて、転送を付けずにログインし直す。

   - 同書のその節の手順 1 の `exit` の後、手順 2 のログインはオンラインのホストで行う
   - 同書のその節の手順 3 で、`ss` が何も出さず、`届かない（期待どおり）` になることを確かめる
   - **次の手順は、ログインし直したオフラインのホストのシェルで貼る**

1. オフラインのホストで、トンネルが無くても jq が動くことを確かめる。

   ```bash
   brew list --versions jq
   command -v jq
   echo '{"host": "offline"}' | jq -r .host
   ```

   - `jq 1.8.2` のような版、`/home/linuxbrew/.linuxbrew/bin/jq`、`offline` が出る

---

## 更新

- [ssh-socks-tunnel.md の手順 1〜3](ssh-socks-tunnel.md#実施手順) でトンネルを張り、同書の手順 3 のシェルで貼る

1. [AlmaLinux 10 の初期設定の更新](almalinux-setup.md#更新)の手順 2・3 を貼る。

   - `brew outdated` が何も出さなければ、上げるものは無いので、同書の更新の手順 3 は飛ばす
   - `brew upgrade` が `[y/n]` と聞いたら、`y` を押す（[手順 4](#実施手順) と同じ確認）
   - **次の手順は、上げ終わってから行う**（続けて貼ると、後ろの行の文字が答えとして読まれる）

1. [ssh-socks-tunnel.md の「トンネルを閉じる」](ssh-socks-tunnel.md#トンネルを閉じる)の手順 1 で、トンネルを閉じる。

---

## ロールバック

- オフラインのホストで貼る。トンネルは要らない
- Homebrew ごと消すなら、この節の手順 1 の代わりに、[ssh-socks-tunnel.md の手順 1〜3](ssh-socks-tunnel.md#実施手順) でトンネルを張ったシェルで [AlmaLinux 10 の初期設定のロールバック](almalinux-setup.md#ロールバック)の手順 24〜26 を行う（アンインストーラを取得するため。本書では実行していない）
- [手順 2](#実施手順) で dnf にプロキシを設定したときは、[ssh-socks-tunnel.md のロールバック](ssh-socks-tunnel.md#ロールバック)で dnf の行を消す

1. 手順 4 で入れた jq を使わないときだけ、jq と、一緒に入った依存を消す。

   ```bash
   brew uninstall jq
   brew autoremove
   brew list --versions
   ```

   - `brew autoremove` は、依存として入って、もうどの formula も使っていないものを消す（[AlmaLinux 10 の初期設定の Homebrew の使い方の基本](almalinux-setup.md#homebrew-の使い方の基本)）
   - 最後の一覧に `jq` が無ければよい

---

## 注意点

- **トンネルそのものの注意は、[ssh-socks-tunnel.md の注意点](ssh-socks-tunnel.md#注意点)**: 転送中はオフラインのホストのどのユーザーもプロキシを使える、出口はオンラインのホスト、`socks5h` の `h`、`https_proxy` が勝つ、`sudo` は `ALL_PROXY` を渡さない、dnf の行が残る
- **`sudo brew` はもともと使えない**: [AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)
- **ほかの手順書の `sudo dnf` も、手順 2 を行ったときだけ通る**: hackgen.md の手順 3（`unzip`）は、dnf の設定で通った
- **トンネルが要るのは、取得するときだけ**: `brew install` / `brew update` / `brew upgrade` は要る。`brew list` / `brew uninstall` / `brew autoremove` は要らない
  - トンネル無しの `brew install hello` は、`curl: (6) Could not resolve host: ghcr.io` と `Error: Failed to download resource "hello"` で失敗した
- **brew は、依存が付くときに `[y/n]` を聞く**: ほかの Homebrew 系の手順書の `brew install` でも、端末から実行すると同じように聞かれる（[AlmaLinux 10 の初期設定の注意点](almalinux-setup.md#注意点)）。当時の bat.md の手順 2（依存が 8 つ）でも聞かれた（参考資料を参照）
- **ssh が切れると、トンネルも消える**: 途中の `brew install` や dnf は、取得の途中なら失敗するはず。そのときは [ssh-socks-tunnel.md 手順 2](ssh-socks-tunnel.md#実施手順) から張り直して、同じコマンドを貼り直す
- **入れた後もネットワークを使うツールは、オフラインのホストではその部分が動かない**: たとえば [dropbox-rclone.md](dropbox-rclone.md) の同期（Dropbox の API）や、[syncthing.md](syncthing.md) の LAN の外の端末との同期
