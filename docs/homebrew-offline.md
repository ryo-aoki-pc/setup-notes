# Homebrew をインターネットに出られないホストで使う手順（AlmaLinux 10 / ssh -R の SOCKS プロキシ）

## 実施手順

> [!IMPORTANT]
> - **2 台のホストで行う**。手順 1・2・8 はインターネットに出られるホスト（以下、オンラインのホスト）で、ほかはインターネットに出られないホスト（以下、オフラインのホスト）で貼る
> - 前提: オンラインのホストからオフラインのホストへ ssh でログインできること（LAN や VPN で）。オンラインのホストの OpenSSH は 7.6 以上
> - **オフラインのホストでは、`sudo` できる自分のユーザーでログインする**。root ではログインしない（Homebrew は root で動かない）
> - **手順 5 で [homebrew.md](homebrew.md) の手順 1〜4 を、手順 3 のシェルのまま貼る**（Homebrew の通信もトンネルを通すため）
> - **手順 2・8 は ssh のログイン、手順 4〜6 には対話入力がある**（`sudo` のパスワード、インストーラの `RETURN`、brew の `[y/n]`）。終わってから次の手順を貼る

- 手順 1 はオンラインのホストのシェルで貼る。手順 2 の後は、ログインしたオフラインのホストのシェルで上から順に貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: ほかの Homebrew 系の手順書（[bat](bat.md) など）は、手順 1〜3 でトンネルを張ったシェルで貼る。以後は[更新](#更新)・[ロールバック](#ロールバック)
- Neovim の Mason に npm のパッケージを入れるなら、手順 7 の前に、このシェルで [npm-offline.md](npm-offline.md) を貼る（npm は `ALL_PROXY` を読まない）

> [!WARNING]
> **x86_64 のコンテナでのみ検証した手順書**で、実機では本実行していない。オフラインのホストは、外に出られない Docker のネットワークだけにつないだコンテナ（[対象と検証環境](#対象と検証環境)）。
>
> - 手順 2 の ssh を開いている間は、オフラインのホストのどのユーザーも `127.0.0.1:1080` を通ってインターネットに出られる（出口はオンラインのホスト）。使い終わったら手順 7 で閉じる

1. オンラインのホストで、変数を設定する（`OFFLINE_HOST` は必ず値を入れる）。

   ```bash
   OFFLINE_HOST=192.168.1.20            # ← 自分の値に書き換える。オフラインのホストの IP アドレスかホスト名。<OFFLINE_HOST>
   ```

   ```bash
   OFFLINE_USER=${USER}                 # オフラインのホストでログインするユーザー（Homebrew を使うユーザー）。<OFFLINE_USER>
   for v in OFFLINE_HOST OFFLINE_USER; do
     printf '%-12s = %s\n' "$v" "${!v}"
   done
   ```

   - 編集が必須なのは `OFFLINE_HOST` だけ
   - オフラインのホストのユーザー名がオンラインのホストと違うときは、`OFFLINE_USER` も書き換える
   - 最後に値を読み戻して確かめる
   - **既定値のままでもエラーにならない**ので、`OFFLINE_HOST` を書き換えたかをここで確かめる
   - 変数はオンラインのホストのシェルの中だけで使う。**新しいシェルを開いたら**、手順 1 の 2 つのブロックを貼り直す

   <details>
   <summary>補足: 変数について</summary>

   - オフラインのホストには変数が無い。ポート（1080）は変える必要が無いので、変数にせずコマンドに直接書いた（変えるときは手順 2 の補足）
   - `OFFLINE_USER` は、Homebrew を使うユーザーにする。`/home/linuxbrew/.linuxbrew` は、homebrew.md の手順 2 を実行したユーザーの持ち物になる
   - root でログインしない。`brew` は root では動かない（[homebrew.md の注意点](homebrew.md#注意点)）

   </details>

1. オンラインのホストから、SOCKS の転送を付けて ssh でログインする。

   ```bash
   ssh -o ExitOnForwardFailure=yes -o ControlPath=none -R 1080 "${OFFLINE_USER:?手順 1 の OFFLINE_USER が空のまま}@${OFFLINE_HOST:?手順 1 の OFFLINE_HOST が空のまま}"
   ```

   - ログインすると、オフラインのホストの `127.0.0.1:1080` が SOCKS プロキシになる。そこへの接続は、オンラインのホストから外へ出る
   - 転送は、この ssh のセッションが続く間だけ有効
   - `Error: remote port forwarding failed for listen port 1080` で終わったら、オフラインのホストで 1080 番がふさがっているか、sshd が転送を禁じている（この手順の補足）
   - 初めてつなぐホストでは、ホスト鍵の確認に `yes` と答える
   - **次の手順は、オフラインのホストにログインしてから貼る**（続けて貼るとホスト鍵の確認やパスワードへの答えとして食われる）

   <details>
   <summary>補足: 逆向きの動的転送と、2 つのオプション</summary>

   **`-R` にポートだけを書く（転送先を書かない）と、ssh が SOCKS のプロキシとして働く。** オフラインのホストの sshd がそのポートで待ち受け、そこへ来た接続を、オンラインのホストの ssh が SOCKS の要求の宛先へつなぐ。

   - OpenSSH 7.6 で入った機能で、オンラインのホストの ssh だけで実装されている。オフラインのホストの sshd の版は問わない（[参照](#参照)のリリースノート）
   - 待ち受けは、sshd の `GatewayPorts` が既定の `no` なら loopback だけ（`127.0.0.1`、IPv6 があれば `::1` も）。`yes` のホストでは LAN 全体に開くので、手順 3 の `ss` で確かめる
   - オフラインのホストの sshd が転送を許しているかは、オフラインのホストで `sudo sshd -T | grep -E '^(allowtcpforwarding|gatewayports|disableforwarding|permitlisten)'` で見られる。AlmaLinux の既定は `allowtcpforwarding yes`・`gatewayports no`・`disableforwarding no`・`permitlisten any` だった

   **`-o ExitOnForwardFailure=yes`: 転送を作れないときに、ログインせずに終わる。** 1080 番を別の ssh の転送でふさいでから手順 2 を貼ると、次の 1 行を出してオンラインのホストのプロンプトに戻った:

   ```
   Error: remote port forwarding failed for listen port 1080
   ```

   - オフラインのホストの sshd に `AllowTcpForwarding no` を入れたときも、同じ 1 行で終わった
   - 付けないと、転送が無いままログインする。1080 番をふさいだまま `-o ExitOnForwardFailure=yes` を外すと、`Warning: remote port forwarding failed for listen port 1080` を出してからログインした（手順 3 で気づくことになる）

   **`-o ControlPath=none`: この ssh では、接続の共有を使わない。** オンラインのホストの `~/.ssh/config` で `ControlMaster auto` と `ControlPersist` を使っていると、転送は裏に残るマスターの接続に付く。

   - 検証環境で `~/.ssh/config` に `ControlMaster auto`・`ControlPath ~/.ssh/cm-%r@%h:%p`・`ControlPersist 10m` を書き、`ControlPath=none` を外して入ると、`exit` の後（`Shared connection to <OFFLINE_HOST> closed.`）も、オフラインのホストに `127.0.0.1:1080` の待ち受けが残った
   - 同じ設定のまま手順 2 のとおりに入ると、手順 7 の `exit` で待ち受けが消えた

   **1080 番を変えるとき**は、手順 2 の `-R 1080`、手順 3 の `ALL_PROXY` と `ss` の `1080`、手順 9 の `ss` の `1080`、手順 4 と[ロールバック](#ロールバック)の手順 2 の `127.0.0.1:1080` を、どれも同じ番号にする。

   </details>

1. オフラインのホストで、プロキシを環境変数に入れ、インターネットに届くか確かめる。

   ```bash
   export ALL_PROXY=socks5h://127.0.0.1:1080
   ss -Hltn 'sport = :1080'
   for u in https://github.com https://raw.githubusercontent.com https://formulae.brew.sh https://ghcr.io/v2/; do
     printf '%-34s %s\n' "$u" "$(curl -sS -o /dev/null --connect-timeout 10 -w '%{http_code}' "$u")"
   done
   rpm -q procps-ng curl file git
   ```

   - `ss` の行は `127.0.0.1:1080`（IPv6 があれば `[::1]:1080` も）だけ
   - `0.0.0.0:1080` や `*:1080` が出たら、LAN 全体にプロキシが開いている。`exit` で抜けて、ここで止める（手順 2 の補足）
   - 4 つの URL の数字が、どれも `000` 以外なら届いている（ghcr.io はトークンが無いので `401`）
   - `000` と `Failed to connect to 127.0.0.1 port 1080` が出たら、手順 2 の転送が無い
   - `export` はこのシェルの中だけで有効。**ssh を張り直したら、手順 2 からやり直す**
   - dnf がトンネル無しで届くリポジトリ（社内のミラーなど）を使うホストなら、手順 4 は飛ばす
   - `rpm -q` の 4 つがどれも入っていれば、**手順 4 は飛ばし、手順 5 でも homebrew.md の手順 1 を飛ばす**

   <details>
   <summary>補足: <code>socks5h</code> と <code>ALL_PROXY</code></summary>

   **`socks5h` の `h` は、名前をプロキシの側（オンラインのホスト）で引く指定。** オフラインのホストは外の名前を引けないので、`h` を落とすと届かない。コンテナでの実測:

   ```
   $ curl -sS -o /dev/null --connect-timeout 10 -x socks5://127.0.0.1:1080 https://github.com
   curl: (97) Could not resolve host: github.com
   ```

   **`ALL_PROXY` は、curl・git・brew がどれも読む。**

   - curl は、プロトコルを問わずに使う
   - git は、`http.proxy` の設定も `https_proxy` も無いときに `ALL_PROXY` を使い、`socks5h` を解る。`GIT_TRACE_CURL=1 git ls-remote https://github.com/Homebrew/brew HEAD` の出力に `SOCKS5 connect to github.com:443 (remotely resolved)` が出た
   - Homebrew の `bin/brew` は、環境変数を絞ってから動くが、`all_proxy` と `ALL_PROXY` は通す（307 行目: `http_proxy https_proxy ftp_proxy no_proxy all_proxy HTTPS_PROXY FTP_PROXY ALL_PROXY`）。`man brew` の「USING HOMEBREW BEHIND A PROXY」も、SOCKS5 のプロキシには `all_proxy` を使う例を挙げている
   - `https_proxy`（`HTTPS_PROXY`）や git の `http.proxy` が既に入っていると、curl と git はそちらを使う。`env | grep -i proxy` と `git config --get http.proxy` が何も出さないことを確かめておく
   - npm は `ALL_PROXY` を読まない（`https_proxy` を読む。[npm-offline.md 手順 2](npm-offline.md#実施手順) の補足）

   **`sudo` は `ALL_PROXY` を引き継がない。** `sudo printenv ALL_PROXY` は何も出さず、終了コード 1 だった（AlmaLinux の `/etc/sudoers` は `env_reset` で、`env_keep` にプロキシの変数が無い）。dnf に手順 4 の設定が要るのはこのため。

   **`ALL_PROXY` を入れずに brew を使うと、外に届かない。** 手順 3 の後に、このシェルで `( unset ALL_PROXY; brew update )` を実行したときの出力:

   ```
   ==> Updating Homebrew...
   fatal: unable to access 'https://github.com/Homebrew/brew/': Could not resolve host: github.com
   Error: Fetching /home/linuxbrew/.linuxbrew/Homebrew failed!
   Failed to download https://formulae.brew.sh/api/internal/packages.x86_64_linux.jws.json!
   ```

   **確かめる 4 つの URL は、Homebrew が使う取得先。** インストーラ（raw.githubusercontent.com）、Homebrew 本体の git（github.com）、formula の API（formulae.brew.sh）、ボトルと portable-ruby（ghcr.io）。コンテナでの実測:

   ```
   LISTEN 0      128    127.0.0.1:1080 0.0.0.0:*
   https://github.com                 200
   https://raw.githubusercontent.com  301
   https://formulae.brew.sh           200
   https://ghcr.io/v2/                401
   package procps-ng is not installed
   curl-8.12.1-4.el10_2.4.x86_64
   package file is not installed
   package git is not installed
   ```

   - raw.githubusercontent.com の `/` は `301`、ghcr.io はトークンが無いので `401`。届いているかだけを見るので、`200` でなくてよい
   - `curl -I`（HEAD）だと、ghcr.io は `405` を返した。`curl -f` を付けると、どちらも失敗扱いになる
   - 検証のコンテナには IPv6 が無く、待ち受けは `127.0.0.1:1080` だけだった

   </details>

1. 手順 3 で入っていないパッケージがあったときだけ、dnf にもプロキシを設定する。

   ```bash
   if grep -q '^proxy' /etc/dnf/dnf.conf; then echo '中断: /etc/dnf/dnf.conf に proxy の行が既にある（この手順は行わない）' >&2; else
     sudo sed -i '/^\[main\]$/a proxy=socks5h://127.0.0.1:1080' /etc/dnf/dnf.conf
     grep -n '^proxy' /etc/dnf/dnf.conf
     sudo dnf makecache
   fi
   ```

   - `sudo` は `ALL_PROXY` を引き継がないので、dnf には `/etc/dnf/dnf.conf` で渡す
   - `2:proxy=socks5h://127.0.0.1:1080` と `Metadata cache created.` が出ればよい
   - この行は[ロールバック](#ロールバック)の手順 2 で消すまで残る。転送が無い間は、dnf がどのリポジトリにも届かなくなる
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: dnf のプロキシ</summary>

   **`dnf config-manager --save --setopt=proxy=…` ではなく `sed` で書く。** `dnf config-manager` は `dnf-plugins-core` が無いと使えず、実機に入っていなかったことがある（[gh.md の実施前の状態](gh.md#実施前の状態)）。オフラインのホストでは、それを入れるにもこの設定が要る。

   - `[main]` の行の直後に 1 行足す。AlmaLinux の `/etc/dnf/dnf.conf` は `[main]` の節だけ
   - `proxy` で始まる行が既にあれば止める。書き換えると、[ロールバック](#ロールバック)の手順 2 で元に戻せなくなるため

   **dnf 4.20 は `socks5h://` を受け付け、リポジトリの設定は変えずに通った。** AlmaLinux のミラーの一覧（`mirrors.almalinux.org`）も、一覧が返したミラーも、トンネルを通った。コンテナでの実測（進み具合の行は省いた）:

   ```
   2:proxy=socks5h://127.0.0.1:1080
   AlmaLinux 10 - AppStream                        5.1 MB/s | 2.7 MB     00:00
   AlmaLinux 10 - BaseOS                            66 MB/s |  37 MB     00:00
   AlmaLinux 10 - CRB                              1.7 MB/s | 616 kB     00:00
   AlmaLinux 10 - Extras                            42 kB/s |  13 kB     00:00
   Metadata cache created.
   ```

   **この行がある間は、トンネルが無いと dnf はどこにも届かない。** 手順 8 のように転送無しでログインしたシェルで `sudo dnf makecache` を実行したときの出力（長い行は省いた）:

   ```
   Errors during downloading metadata for repository 'appstream':
     - Curl error (7): Could not connect to server for https://mirrors.almalinux.org/mirrorlist/10/appstream [Failed to connect to 127.0.0.1 port 1080 after 0 ms: Could not connect to server]
   Error: Failed to download metadata for repo 'appstream': Cannot prepare internal mirrorlist: …
   ```

   - オフラインのホストなので、この行が無くても dnf は外に届かない。失敗の出方が変わるだけ
   - 社内のミラーなど、トンネル無しで届くリポジトリを使うホストでは、その通信もトンネルに向かってしまうので、手順 4 を行わない

   </details>

1. 手順 3 のシェルのまま、[homebrew.md 手順 1〜4](homebrew.md#実施手順) を貼る。

   - `command -v brew` が `/home/linuxbrew/.linuxbrew/bin/brew` を返すなら、Homebrew は入っているので、この手順は飛ばす
   - homebrew.md の手順 1 の dnf は、手順 4 の設定で通る（手順 3 で 4 つとも入っていたなら飛ばす）
   - homebrew.md の手順 2 のインストーラも、中で使う curl と git が `ALL_PROXY` を読むので、そのまま通る
   - **次の手順は、homebrew.md の手順 4 まで終えてから貼る**（homebrew.md の手順 1・2 に `sudo` のパスワードと `RETURN` の確認がある）

1. 確かめるために、brew で jq をトンネル越しに入れる。

   ```bash
   brew install jq
   ```

   - 入れるものの一覧の後に `==> Do you want to proceed with the installation? [y/n]` と聞かれるので、`y` を押す（Enter は要らない）
   - `==> Pouring jq--…bottle…tar.gz` と出て、ソースからのビルドにならない
   - ほかの Homebrew 系の手順書も、手順 7 の前に、このシェルで貼る
   - **次の手順は、`y` を押して入れ終わってから貼る**（続けて貼ると、後ろの行の文字が答えとして読まれる）

   <details>
   <summary>補足: brew の確認（ask mode）と、トンネル越しの取得</summary>

   **Homebrew 7.0.7 の `brew install` は、端末から実行すると、入れるものの一覧を出してから `[y/n]` を聞く**（ask mode）。

   - `brew` の環境変数の説明（`Library/Homebrew/env_config.rb` の `HOMEBREW_ASK`）: 既定で有効。一覧に依存など、名前を挙げたもの以外が入るときだけ聞き、端末でない（TTY が無い）ときは聞かない
   - 答えは Enter を待たずに 1 文字で読む（`Library/Homebrew/ask.rb` の `$stdin.getch`）。`y` で続け、`n`・Esc・Ctrl+C・Ctrl+D で中止、ほかの文字は `Invalid input` と出して読み直す
   - 最初に書いた手順（`brew install jq` の後ろに `jq --version` と `brew list --versions jq` を続けたブロック）を貼ったら、`jq --version` の文字が 1 文字ずつ答えとして読まれた。`Invalid input` が 11 回出た後、`version` の `n` で中止になり、jq は入らなかった
   - 聞かせないようにするには `HOMEBREW_NO_ASK=1` を入れる（本書では使っていない）

   コンテナでの実測（進み具合の表示は省いた）:

   ```
   ==> Downloading bottle manifests
   ==> Would install 1 formula:
   jq 1.8.2
   ==> Would install 1 dependency for jq:
   oniguruma
   ==> Do you want to proceed with the installation? [y/n]
   ==> Fetching downloads for: jq
   ==> Installing jq dependency: oniguruma
   ==> Pouring oniguruma--6.9.10.x86_64_linux.bottle.tar.gz
   🍺  /home/linuxbrew/.linuxbrew/Cellar/oniguruma/6.9.10: 16 files, 1.8MB
   ==> Installing jq
   ==> Pouring jq--1.8.2.x86_64_linux.bottle.1.tar.gz
   🍺  /home/linuxbrew/.linuxbrew/Cellar/jq/1.8.2: 21 files, 1.5MB
   ```

   - ボトルと、その一覧（bottle manifest）は ghcr.io から降りる。どちらもトンネルを通った

   </details>

1. オフラインのホストからログアウトして、トンネルを閉じる。

   ```bash
   exit
   ```

   - ssh のセッションが終わると、`127.0.0.1:1080` の待ち受けも消える
   - **次の手順は、オンラインのホストのプロンプトに戻ってから貼る**

1. オンラインのホストから、転送を付けずにログインし直す。

   ```bash
   ssh "${OFFLINE_USER:?手順 1 の OFFLINE_USER が空のまま}@${OFFLINE_HOST:?手順 1 の OFFLINE_HOST が空のまま}"
   ```

   - **次の手順は、ログインしてから貼る**（続けて貼るとパスワードへの答えとして食われる）

1. オフラインのホストで、トンネルが無くても jq が動き、外に出られないことを確かめる。

   ```bash
   brew list --versions jq
   command -v jq
   echo '{"host": "offline"}' | jq -r .host
   ss -Hltn 'sport = :1080'
   curl -sS -o /dev/null --connect-timeout 10 https://github.com && echo '届いた（オフラインではない）' || echo '届かない（期待どおり）'
   ```

   - `jq 1.8.2` のような版、`/home/linuxbrew/.linuxbrew/bin/jq`、`offline` が出る
   - `ss` は何も出さない（トンネルが無い）
   - 最後の行は `届かない（期待どおり）`

---

## 更新

- [手順 1〜3](#実施手順) でトンネルを張り、手順 3 のシェルで貼る（手順 1 の変数が残っているシェルなら、手順 2 から）

1. Homebrew 自身と formula の索引を更新し、上げられるものを見る。

   ```bash
   brew update
   brew outdated
   ```

   - `brew outdated` が何も出さなければ、上げるものは無いので、この節の手順 2 は飛ばす

1. 上げるものがあるときだけ、入れたものを上げる。

   ```bash
   brew upgrade
   ```

   - `[y/n]` と聞かれたら、`y` を押す（[手順 6](#実施手順)と同じ確認。Homebrew の説明では `brew upgrade` にも出る）
   - **次の手順は、上げ終わってから貼る**（続けて貼ると、後ろの行の文字が答えとして読まれる）

1. オフラインのホストからログアウトして、トンネルを閉じる。

   ```bash
   exit
   ```

---

## ロールバック

- オフラインのホストで貼る。トンネルは要らない
- Homebrew ごと消すなら、この節の手順 1 の代わりに、[手順 1〜3](#実施手順) でトンネルを張ったシェルで [homebrew.md のロールバック](homebrew.md#ロールバック)を行う（アンインストーラを取得するため。本書では実行していない）
- オンラインのホストには、`~/.ssh/known_hosts` のオフラインのホストの行だけが残る

1. 手順 6 で入れた jq を使わないときだけ、jq と、一緒に入った依存を消す。

   ```bash
   brew uninstall jq
   brew autoremove
   brew list --versions
   ```

   - `brew autoremove` は、依存として入って、もうどの formula も使っていないものを消す（[homebrew.md の使い方の基本](homebrew.md#使い方の基本)）
   - 検証では [bat](bat.md) も入れていたので、jq の依存の `oniguruma` は bat の依存として残った
   - 最後の一覧に `jq` が無ければよい

1. 手順 4 を行ったときだけ、dnf のプロキシの行を消す。

   ```bash
   {
     sudo sed -i '/^proxy=socks5h:\/\/127\.0\.0\.1:1080$/d' /etc/dnf/dnf.conf
     grep -c '^proxy' /etc/dnf/dnf.conf
   }
   ```

   - `0` が出ればよい

---

## 補足

### 対象と検証環境

- **目的**: インターネットに出られない AlmaLinux 10 のホストで、Homebrew と、Homebrew で入れるコマンドを使えるようにする
  - 入れる・上げるときだけ、そのホストへ ssh でログインしてくるオンラインのホストを経由して外に出る
  - 入れたコマンドは、トンネルが無くても動く
- **進め方**: オンラインのホストから `ssh -R 1080` でログインし、オフラインのホストにできた SOCKS の待ち受けを `ALL_PROXY` で使う。Homebrew の導入は、homebrew.md をそのシェルのまま貼る
  - 読者が編集するのは `OFFLINE_HOST` だけ
- **状態**: **x86_64 のコンテナでのみ検証済み（2026-09-29）。実機では本実行していない**
  - このクラウドのホスト（Ubuntu 24.04）の Docker で、外に出られないネットワーク（`--internal`）だけにつないだコンテナをオフラインのホストにした
  - オンラインのホストは、外に出られるネットワークと、その `--internal` のネットワークの両方につないだ別のコンテナ
  - **この文書のコードブロックをそのまま**、擬似端末で開いたオンラインのホストの対話の bash に貼って、手順 1〜9（手順 5 は homebrew.md の手順 1〜4）、[更新](#更新)、[ロールバック](#ロールバック)を通した
  - 貼り方はブラケットペースト無し。手順 4 とロールバックの手順 2 は、ブラケットペースト有りでも通した
  - 確認したこと:
    - 手順 2 の前は、オフラインのホストから外の名前を引けず、IP アドレスでもつながらない
    - トンネル越しに、dnf（homebrew.md の手順 1 の 73 パッケージを含む）、Homebrew のインストーラ、`brew install`、`brew update` が通る
    - トンネルを閉じた後も jq が動き、外には届かない
    - ほかの手順書も、トンネルのシェルでそのまま通る（[bat.md](bat.md) の手順 1〜3、[hackgen.md](hackgen.md) の手順 1〜5。hackgen.md の手順 3 は dnf、手順 4 は GitHub からの cask の取得）
    - 1080 番がふさがっているときと、sshd が転送を禁じている（`AllowTcpForwarding no`）ときに ssh が止まること、接続の共有（`ControlPersist`）で転送が残ること
    - `sudo` が `ALL_PROXY` を渡さないこと、転送中は別のユーザーもプロキシを使えること、トンネルが無いときの dnf と brew の失敗の出方
  - **確認していないこと**: 実機（x86_64 の PC・Raspberry Pi 5）、aarch64、SELinux が Enforcing のホスト（コンテナに SELinux が無い）、IPv6、パスワード認証（検証は鍵認証）、Windows・macOS の ssh、長い導入の途中で ssh が切れたとき、homebrew.md のロールバック
  - 実測の記録は[付録](#付録-コンテナでの検証記録2026-09-29)

| 項目 | オンラインのホスト | オフラインのホスト |
|---|---|---|
| 実施日 | 2026-09-29 | 同左 |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64（`docker.io/library/almalinux:10` のコンテナ） | 同左 |
| ネットワーク | 外に出られるネットワークと、オフラインのホストのネットワークの両方 | `--internal` のネットワークだけ（既定の経路も、外の名前解決も無い） |
| ssh | `openssh-clients-9.9p1-27.el10_2.alma.1`（`OpenSSH_9.9p1`） | `openssh-server-9.9p1-27.el10_2.alma.1`。systemd 無しで `sshd -D -e` を動かした。設定は AlmaLinux の既定のまま |
| sudo / dnf / curl | — | `sudo-1.9.17-10.p2.el10_2.6` / `dnf-4.20.0-22.el10_2.alma.1` / `curl-8.12.1-4.el10_2.4`（homebrew.md の手順 1 で `.6` に上がった） |
| Homebrew | 入れていない | `7.0.7`（手順 5 で新規導入） |
| ユーザー | `<USER>`（uid 1000） | 同じ名前（uid 1000、NOPASSWD の sudo）と、確かめ用の 2 人目（uid 1001） |
| コンテナのホスト | Ubuntu 24.04 / x86_64 のクラウドの VM、Docker 29.3.1（cgroup v1） | 同左 |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で、オンラインのホストのシェルに 1 度だけ設定する。オフラインのホストには変数が無い。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${OFFLINE_HOST}` | オフラインのホストの IP アドレスかホスト名 | `192.168.1.20` |
> | `${OFFLINE_USER}` | オフラインのホストでログインするユーザー（既定はオンラインのホストのユーザー名。違えば直す） | `${USER}` |
>
> 出力例・ログ・表の中の値は `<OFFLINE_HOST>` / `<USER>`（ユーザー名）のプレースホルダで書いてある。バージョン（`7.0.7` など）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

オフラインのホスト（コンテナ）で、手順 1 の前に確かめた状態:

| 項目 | 状態 |
|---|---|
| 経路 | `ip route` は、つないだネットワークの 1 行だけ（`default` の行が無い） |
| 名前解決 | `getent hosts github.com` は何も返さず、終了コード 2 |
| 外への接続 | `curl https://github.com` は `curl: (6) Could not resolve host: github.com`。github.com の IP アドレスを直接指定しても `curl: (7) Failed to connect to … port 443 after 0 ms: Could not connect to server` |
| パッケージ | `curl-8.12.1-4.el10_2.4` は入っている。`procps-ng`・`file`・`git` は無い |
| Homebrew | 無い（`/home/linuxbrew` が無い） |
| sshd | `sshd -T` は `allowtcpforwarding yes`・`gatewayports no`・`disableforwarding no`・`permitlisten any`（AlmaLinux の既定） |
| `/etc/dnf/dnf.conf` | 既定のまま（`[main]` と 5 つの設定。`proxy` の行は無い） |
| オンラインのホストの `~/.ssh` | 鍵だけ（`known_hosts` も `config` も無い） |

### 選択した方針

| 経路 | 要るもの | 採否 |
|---|---|---|
| **オンラインのホストから `ssh -R 1080`（逆向きの動的転送）** | オンラインのホストからオフラインのホストへ ssh でログインできること。どちらのホストにも追加のソフトは要らない | **採用。** オフラインのホストで curl・git・brew・dnf がそのまま外に届き、homebrew.md とほかの Homebrew 系の手順書を変えずに貼れる。オフラインのホストが自分のアーキのボトルを取るので、2 台のアーキが違ってもよい（ただし本書は x86_64 でしか確かめていない） |
| オフラインのホストから `ssh -D 1080` | オフラインのホストからオンラインのホストへ ssh でログインできること（オンラインのホストで sshd を動かす） | 不採用。ssh の向きが逆のときの代わりになる形だが、本書では確かめていない |
| オンラインのホストに HTTP プロキシ（squid など）を建てる | オンラインのホストにデーモン、待ち受けのポート、アクセス制御 | 不採用。ssh の転送で足りる |
| `/home/linuxbrew/.linuxbrew` を tar にして運ぶ | 同じ OS・同じアーキのホストで Homebrew と formula を入れる。上げるたびに作り直して運ぶ | 本書では扱わない（ネットワークで届かないときの方法。確かめていない） |
| `brew fetch` でボトルだけを運ぶ | Homebrew 本体（git のリポジトリと portable-ruby）と、formula の API の JSON も要る | 本書では扱わない（確かめていない） |

- **`ALL_PROXY` を `~/.bashrc` に書かない**: トンネルがあるのは手順 2 の ssh のセッションの間だけなので、手順 3 でそのシェルにだけ入れる
- **homebrew.md を、リードで前提として挙げるのではなく、手順 5 にした**: ほかの Homebrew 系の手順書と違い、トンネルを張ったシェルの中で貼る必要があるため
- **dnf には、`sudo` に環境変数を渡す（`sudo --preserve-env=ALL_PROXY`）のではなく、設定ファイルで渡す**: homebrew.md の手順 1 や、ほかの手順書の `sudo dnf install` を、書き換えずに貼れるようにするため

### 完了時点の状態

**検証のコンテナでの出力**（手順 9。転送無しでログインし直したオフラインのホストのシェル）:

```
$ brew list --versions jq
jq 1.8.2
$ command -v jq
/home/linuxbrew/.linuxbrew/bin/jq
$ echo '{"host": "offline"}' | jq -r .host
offline
$ ss -Hltn 'sport = :1080'
$ curl -sS -o /dev/null --connect-timeout 10 https://github.com && echo '届いた（オフラインではない）' || echo '届かない（期待どおり）'
curl: (6) Could not resolve host: github.com
届かない（期待どおり）
```

- `/etc/dnf/dnf.conf` には、手順 4 の `proxy=socks5h://127.0.0.1:1080` が 2 行目に残る（[ロールバック](#ロールバック)の手順 2 で消す）
- オンラインのホストに残るのは、`~/.ssh/known_hosts` のオフラインのホストの行だけ
- `/home/linuxbrew/.linuxbrew` は、検証の最後（bat と HackGen が入り、jq を消した状態）で 286 MB

### 注意点

- **転送中は、オフラインのホストのどのユーザーもプロキシを使える**: 待ち受けは loopback だけだが、ユーザーを区別しない。検証では、2 人目のユーザーの `curl` も `200` を返した。使い終わったら手順 7 で閉じる
- **外への通信の出口はオンラインのホスト**: オンラインのホストのネットワークの規則（社内のプロキシ、ファイアウォール）に従う。オンラインのホストの ssh が知るのは宛先の名前とポートで、HTTPS の中身は暗号化されたまま通る
- **`socks5h` の `h` を落とさない**: 落とすと名前を引けない（手順 3 の補足）
- **`https_proxy` や git の `http.proxy` が入っていると、そちらが勝つ**: 手順 3 の補足
- **`sudo` は `ALL_PROXY` を渡さない**: dnf は手順 4 の設定で通す。`sudo brew` はもともと使えない（[homebrew.md の注意点](homebrew.md#注意点)）
- **手順 4 の行は残る**: トンネルが無い間は、dnf が `127.0.0.1 port 1080` につながらずに失敗する（手順 4 の補足）。dnf で外のリポジトリを使わなくなったら、[ロールバック](#ロールバック)の手順 2 で消す
- **ほかの手順書の `sudo dnf` も、手順 4 を行ったときだけ通る**: hackgen.md の手順 3（`unzip`）は、手順 4 の設定で通った
- **トンネルが要るのは、取得するときだけ**: `brew install` / `brew update` / `brew upgrade` は要る。`brew list` / `brew uninstall` / `brew autoremove` は要らない
  - トンネル無しの `brew install hello` は、`curl: (6) Could not resolve host: ghcr.io` と `Error: Failed to download resource "hello"` で失敗した
- **brew は、依存が付くときに `[y/n]` を聞く**: ほかの Homebrew 系の手順書の `brew install` でも、端末から実行すると同じように聞かれる。bat.md の手順 2（依存が 8 つ）でも聞かれた（手順 6 の補足）
- **ssh が切れると、トンネルも消える**: 途中の `brew install` や dnf は、取得の途中なら失敗するはず（本書では確かめていない）。そのときは手順 2 から張り直して、同じコマンドを貼り直す
- **入れた後もネットワークを使うツールは、オフラインのホストではその部分が動かない**: たとえば [dropbox-rclone.md](dropbox-rclone.md) の同期（Dropbox の API）や、[syncthing.md](syncthing.md) の LAN の外の端末との同期（本書では確かめていない）
- **SELinux が Enforcing のホストでは確かめていない**: 検証のコンテナには SELinux が無い。sshd の 1080/tcp の待ち受けが拒まれないかは未確認

### 参照

- [OpenSSH 7.6 のリリースノート](https://www.openssh.org/txt/release-7.6) — `ssh -R` の逆向きの動的転送（SOCKS）が入った版。クライアントだけで実装されている（オフラインのホストの sshd の版は問わない）
- [ssh(1)](https://man.openbsd.org/ssh) — `-R`、`-o ExitOnForwardFailure`、`-o ControlPath`
- [sshd_config(5)](https://man.openbsd.org/sshd_config) — `AllowTcpForwarding`、`GatewayPorts`、`PermitListen`、`DisableForwarding`
- [curl(1) の ENVIRONMENT](https://curl.se/docs/manpage.html#ENVIRONMENT) — `ALL_PROXY` と `socks5h://`
- [git-config(1) の http.proxy](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpproxy) — git がプロキシを読む順番
- [Homebrew — Manpage の USING HOMEBREW BEHIND A PROXY](https://docs.brew.sh/Manpage#using-homebrew-behind-a-proxy) — Homebrew が読むプロキシの環境変数
- `man dnf.conf` — `proxy`
- [Homebrew](homebrew.md) — 手順 5 で貼る Homebrew 本体の導入手順

---

### 付録: コンテナでの検証記録（2026-09-29）

`docker.io/library/almalinux:10`（AlmaLinux 10.2、x86_64、`sha256:95773870…9677`）から 2 つのイメージを作り、x86_64 のクラウドホスト（Ubuntu 24.04）の Docker 29.3.1 でコンテナを立てた。実機で加えた変更は無い。

検証の準備（手順書の外）:

- ネットワークを 2 つ作った。外に出られない `docker network create --internal` のもの（オフラインのホスト用）と、ふつうのもの（オンラインのホスト用）。オンラインのホストのコンテナは両方につないだ
- オフラインのホスト: `openssh-server`・`sudo`・`iproute` を入れ、`ssh-keygen -A` のうえで `sshd -D -e` を動かした（systemd 無し）。ユーザー（uid 1000、NOPASSWD の sudo）と、確かめ用の 2 人目（uid 1001）を作った。`git`・`file`・`procps-ng` は入れていない
- オンラインのホスト: `openssh-clients` を入れ、同じ名前のユーザーで鍵を作り、公開鍵をオフラインのホストの `authorized_keys` に置いた（鍵認証なので、パスワードは聞かれない）
- このクラウドのホストの外向きの通信は、TLS を署名し直すゲートウェイを通る。そのゲートウェイの CA を、オフラインのホストの信頼ストアに足した
  - オンラインのホストの ssh は TCP を中継するだけなので、CA が要るのはオフラインのホストの curl・git・dnf
  - 実際のオンラインのホストでは、この変更は要らない
- hackgen.md の手順 5 の前に、`fontconfig` を dnf で入れた（hackgen.md の検証と同じ。トンネルと手順 4 の設定で入った）

コードブロックの流し方:

- 文書からコードブロックを抜き出し、`docker exec -it` で開いたオンラインのホストの対話の bash（擬似端末、`TERM=xterm-256color`）に、手順ごとに 1 回で送った（ブラケットペースト無し。改行は CR）
- 手順 1 の `OFFLINE_HOST` は、コンテナの名前に書き換えた
- ホスト鍵の確認には `yes`、インストーラの `RETURN` と brew の `[y/n]` には、表示が出てから Enter と `y` を送った
- 手順 4 とロールバックの手順 2 は、ブラケットペーストの開始と終了の制御文字で囲んだ形でも送った

| 手順 | 結果 |
|---|---|
| 実施前 | [実施前の状態](#実施前の状態)のとおり。外の名前も引けず、IP アドレスでもつながらない |
| 1 | `OFFLINE_HOST = <OFFLINE_HOST>` / `OFFLINE_USER = <USER>` |
| 2 | ホスト鍵の確認に `yes` → `Warning: Permanently added '<OFFLINE_HOST>' (ED25519) to the list of known hosts.` の後にログインした |
| 3 | `127.0.0.1:1080` の 1 行、`200` / `301` / `200` / `401`。`rpm -q` は curl だけ入っていた |
| 4 | `2:proxy=socks5h://127.0.0.1:1080`、`Metadata cache created.` |
| 5（homebrew.md 手順 1） | `file`・`git`・`procps-ng` と依存で 73 パッケージを導入し、4 つ（`curl`・`libcurl-minimal`・`openssl-libs`・`openssl-fips-provider`）を更新した（ダウンロード 21 MB）。`Complete!` |
| 5（homebrew.md 手順 2） | `NONINTERACTIVE` を付けずに実行し、`Press RETURN/ENTER to continue` で Enter。Homebrew/brew の git の取得と、`portable-ruby-4.0.7.x86_64_linux` の取得がトンネルを通り、`==> Installation successful!` |
| 5（homebrew.md 手順 3・4） | `Homebrew 7.0.7`、`HOMEBREW_PREFIX: /home/linuxbrew/.linuxbrew`、`Branch: stable` |
| 6（最初の版） | `brew install jq` の後ろに `jq --version` と `brew list --versions jq` を続けたブロックだった。`[y/n]` の確認に後ろの行の文字が読まれ、`Invalid input` が 11 回出た後、`n` で中止になった。jq は入らず、手順 9 で `jq: command not found`。手順 6 を `brew install jq` だけにし、確かめは手順 9 に移した |
| 6 | `[y/n]` に `y`。`oniguruma` と `jq 1.8.2` のボトルがトンネル越しに降りた |
| 7 | `Connection to <OFFLINE_HOST> closed.` |
| 8 | 転送無しでログインした |
| 9 | `jq 1.8.2`、`/home/linuxbrew/.linuxbrew/bin/jq`、`offline`。`ss` は無出力。curl は `Could not resolve host: github.com` で、`届かない（期待どおり）` |
| ほかの手順書 | 手順 1〜3 のシェルで、bat.md の手順 1〜3（`[y/n]` に `y`。依存 8 つと `bat 0.26.1`）と、hackgen.md の手順 1〜5（手順 3 の `sudo dnf install -y unzip` は手順 4 の設定で通り、手順 4 の cask は GitHub から取得）が通った |
| 更新 | `Already up-to-date.`。`brew outdated` と `brew upgrade` は無出力（入れた直後のため）。この節の手順 3 の `exit` で、`127.0.0.1:1080` の待ち受けが消えた |
| ロールバック | トンネル無しのシェルで通した。この節の手順 1 は `Uninstalling …/jq/1.8.2... (21 files, 1.5MB)` で、`brew autoremove` は無出力。この節の手順 2 は `0` で、`/etc/dnf/dnf.conf` は手順 4 の前と同じ内容に戻った |
| ブラケットペースト | 手順 4 は `2:proxy=…` と `Metadata cache created.`。続けて手順 4 をもう一度貼ると `中断: …`。ロールバックの手順 2 は `0` |

追加の確認（手順書の外）:

| 確認 | 結果 |
|---|---|
| `socks5`（`h` 無し） | `curl: (97) Could not resolve host: github.com` |
| `sudo printenv ALL_PROXY` | 無出力、終了コード 1 |
| 別のユーザー | 2 人目のユーザーの `curl`（`ALL_PROXY` を付けた）が `200` |
| `bin/brew` | 307 行目で `all_proxy` と `ALL_PROXY` を通す |
| git | `GIT_TRACE_CURL=1` の出力に `SOCKS5 connect to github.com:443 (remotely resolved)` |
| `ALL_PROXY` 無しの `brew update` | `Could not resolve host: github.com` で `Error: Fetching /home/linuxbrew/.linuxbrew/Homebrew failed!`、終了コード 1 |
| `sudo dnf upgrade --refresh --assumeno` | トンネル越しにメタデータを取り直し、9 パッケージの更新を示して `Operation aborted.`（`--assumeno` のため） |
| 1080 番がふさがっている | 手順 2 は `Error: remote port forwarding failed for listen port 1080` で、ログインせずに戻った。`-o ExitOnForwardFailure=yes` を外すと、`Warning: …` を出してからログインした |
| sshd が転送を禁じている | オフラインのホストの `/etc/ssh/sshd_config.d/` に `AllowTcpForwarding no` を置いて sshd に読み直させると、手順 2 のコマンドは同じ `Error: …` で終わった（終了コード 255）。確かめた後に消した |
| 接続の共有 | `ControlMaster auto`・`ControlPersist 10m` の設定で `ControlPath=none` を外すと、`exit` の後も待ち受けが残った。手順 2 のままなら、手順 7 で消えた |
| トンネル無しの `sudo dnf makecache` | `Failed to connect to 127.0.0.1 port 1080`、終了コード 1 |
| トンネル無しの `brew install hello` | `curl: (6) Could not resolve host: ghcr.io` と `Error: Failed to download resource "hello"`、終了コード 1 |
| トンネル無しの `brew list --versions` | 入れたものがすべて出た |

#### 未確認事項

- 実機（x86_64 の PC・Raspberry Pi 5）での本実行
- aarch64 のオフラインのホスト
- SELinux が Enforcing のホストでの、1080/tcp の待ち受け
- IPv6 のあるホスト（`[::1]:1080` の待ち受け）
- パスワード認証でのログイン（検証は鍵認証）
- Windows・macOS の ssh をオンラインのホストにしたとき
- `AllowTcpForwarding no` 以外の禁じ方（`DisableForwarding yes`、`PermitListen`、`authorized_keys` の `restrict`）での出方
- 長い導入の途中で ssh が切れたとき
- オフラインのホストからの `ssh -D`（[選択した方針](#選択した方針)の代わりの形）
- homebrew.md のロールバック（`uninstall.sh`）をトンネル越しに実行すること
- `brew upgrade` の `[y/n]`（検証の時点では上げるものが無かった）
