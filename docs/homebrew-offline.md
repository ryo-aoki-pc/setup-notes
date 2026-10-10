# Homebrew をインターネットに出られないホストで使う手順（AlmaLinux 10 / ssh -R の SOCKS プロキシ）

## 実施手順

- [検証記録](verification/homebrew-offline.md)・[参考資料](reference/homebrew-offline.md)・[ロールバックと注意点](extra/homebrew-offline.md)

> [!IMPORTANT]
> - **前提**: [ssh-socks-tunnel.md](ssh-socks-tunnel.md) の手順 1〜3 で、インターネットに出られるホスト（以下、オンラインのホスト）からトンネルを付けて、インターネットに出られないホスト（以下、オフラインのホスト）にログインしてあること。**この文書は、同書の手順 3 のシェルのまま貼る**（Homebrew の通信もトンネルを通すため）
> - **オフラインのホストには、`sudo` できる自分のユーザーでログインする**（同書の手順 1 の `OFFLINE_USER`）。root ではログインしない（Homebrew の導入・更新は root では行わない）
> - **手順 3 で [AlmaLinux 10 の初期設定の「Homebrew」の手順 1〜3](almalinux-setup.md#homebrew)（Homebrew）を、同じシェルのまま貼る**
> - **手順 3・4 には対話入力がある**（インストーラの `RETURN`、brew の `[y/n]`）。終わってから次の手順を貼る
> - **手順 5 はトンネルを閉じてログインし直す**（オンラインのホストで行う操作がある）

- 上から順に、ssh-socks-tunnel.md の手順 3 のシェルで貼る
- 貼った後は、反転表示の「確認」から後ろの出力を箇条書きで確かめる
- 手順の後: ほかの Homebrew 系の手順（[AlmaLinux 10 の初期設定の「シェルのツール」の手順 1](almalinux-setup.md#シェルのツール)や [yazi](almalinux-setup.md#yazi) など）は、ssh-socks-tunnel.md の手順 1〜3 でトンネルを張ったシェルで貼る。以後は[更新](#更新)・[ロールバック](extra/homebrew-offline.md#ロールバック)
- Neovim の Mason に npm のパッケージを入れるなら、手順 5 でトンネルを閉じる前に、このシェルで [npm-offline.md](npm-offline.md) を貼る（npm は `ALL_PROXY` を読まない）

> [!WARNING]
>
> - トンネルを張っている間は、オフラインのホストのどのユーザーもインターネットに出られる（出口はオンラインのホスト。[ssh-socks-tunnel.md の注意点](extra/ssh-socks-tunnel.md#注意点)）。使い終わったら手順 5 で閉じる

1. トンネルのシェルで、Homebrew の取得先に届くかと、Homebrew が使うパッケージを確かめる。

   ```bash
   printf '\n\033[7m 確認 \033[0m\n'
   for u in https://github.com https://raw.githubusercontent.com https://formulae.brew.sh https://ghcr.io/v2/; do
     printf '%-34s %s\n' "$u" "$(curl -sS -o /dev/null --connect-timeout 10 -w '%{http_code}' "$u")"
   done
   rpm -q procps-ng curl file git
   ```

   - 4 つの URL の数字が、どれも `000` 以外なら届いている（ghcr.io は `401`）
   - `000` と `Failed to connect to 127.0.0.1 port 1080` が出たら、トンネルが無いか、`ALL_PROXY` を入れていないシェルで貼っている（[ssh-socks-tunnel.md 手順 2](ssh-socks-tunnel.md#実施手順) からやり直す）
   - `rpm -q` の 4 つがどれも入っていれば、**手順 2 は飛ばし、手順 3 でも AlmaLinux 10 の初期設定の「Homebrew」の手順 1 を飛ばす**
   - dnf がトンネル無しで届くリポジトリ（社内のミラーなど）を使うホストなら、手順 2 は飛ばす

1. 手順 1 で入っていないパッケージがあったときだけ、[ssh-socks-tunnel.md の「dnf にもトンネルを使わせる（任意）」](ssh-socks-tunnel.md#dnf-にもトンネルを使わせる任意)を行う。

   - **次の手順は、同書の節の `Metadata cache created.` が出てから貼る**

1. 手順 1 のシェルのまま、[AlmaLinux 10 の初期設定の「Homebrew」の手順 1〜3](almalinux-setup.md#homebrew) を貼る。

   - `command -v brew` が `/home/linuxbrew/.linuxbrew/bin/brew` を返すなら、Homebrew は入っているので、この手順は飛ばす
   - 同書の「Homebrew」の手順 1 の dnf は、手順 2 の設定で通る（手順 1 で 4 つとも入っていたなら飛ばす）
   - 同書の「Homebrew」の手順 3 は、共通の bash 設定（同書の「共通の bash 設定」の手順 1・2）を入れてあるシェルで貼る
   - **次の手順は、同書の「Homebrew」の手順 3 まで終えてから貼る**（同じ項の手順 2 に `RETURN` の確認がある）

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
   printf '\n\033[7m 確認 \033[0m\n'
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
