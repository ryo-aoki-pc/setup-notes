# Homebrew をインターネットに出られないホストで使う手順（AlmaLinux 10 / ssh -R の SOCKS プロキシ）の検証記録

[手順書](../homebrew-offline.md)・[ロールバックと注意点](../extra/homebrew-offline.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 のクリーンインストール VM でも検証した手順書**（2026-10-06、SELinux Enforcing）で、実機では本実行していない。今回のオフラインのホストは、既定経路を無くした VM（[対象と検証環境](#対象と検証環境)）。
>
> - トンネルを張っている間は、オフラインのホストのどのユーザーもインターネットに出られる（出口はオンラインのホスト。[ssh-socks-tunnel.md の注意点](../extra/ssh-socks-tunnel.md#注意点)）。使い終わったら手順 5 で閉じる

### 実施手順 / 手順 1: 補足: 4 つの URL と、brew のプロキシ

**確かめる 4 つの URL は、Homebrew が使う取得先。** インストーラ（raw.githubusercontent.com）、Homebrew 本体の git（github.com）、formula の API（formulae.brew.sh）、ボトルと portable-ruby（ghcr.io）。コンテナでの実測:

```
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

**brew も `ALL_PROXY` を読む**（curl と git は [ssh-socks-tunnel.md 手順 3](../ssh-socks-tunnel.md#実施手順) の補足）。Homebrew の `bin/brew` は、環境変数を絞ってから動くが、`all_proxy` と `ALL_PROXY` は通す（307 行目: `http_proxy https_proxy ftp_proxy no_proxy all_proxy HTTPS_PROXY FTP_PROXY ALL_PROXY`）。`man brew` の「USING HOMEBREW BEHIND A PROXY」も、SOCKS5 のプロキシには `all_proxy` を使う例を挙げている。

**`ALL_PROXY` を入れずに brew を使うと、外に届かない。** トンネルのシェルで `( unset ALL_PROXY; brew update )` を実行したときの出力:

```
==> Updating Homebrew...
fatal: unable to access 'https://github.com/Homebrew/brew/': Could not resolve host: github.com
Error: Fetching /home/linuxbrew/.linuxbrew/Homebrew failed!
Failed to download https://formulae.brew.sh/api/internal/packages.x86_64_linux.jws.json!
```

### 実施手順 / 手順 4: 補足: brew の確認（ask mode）と、トンネル越しの取得

**Homebrew 7.0.7 の `brew install` は、依存なども含む計画なら、端末で一覧を出してから `[y/n]` を聞く**（ask mode。[AlmaLinux 10 の初期設定の注意点](../extra/almalinux-setup.md#注意点)）。

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

### 対象と検証環境

- **目的**: インターネットに出られない AlmaLinux 10 のホストで、Homebrew と、Homebrew で入れるコマンドを使えるようにする
  - 入れる・上げるときだけ、そのホストへ ssh でログインしてくるオンラインのホストを経由して外に出る
  - 入れたコマンドは、トンネルが無くても動く
- **進め方**: 前提の [ssh-socks-tunnel.md](../ssh-socks-tunnel.md) で、オンラインのホストから `ssh -R 1080` でログインし、オフラインのホストにできた SOCKS の待ち受けを `ALL_PROXY` で使う。Homebrew の導入は、homebrew.md をそのシェルのまま貼る
  - この文書には変数が無い。読者が編集するのは、ssh-socks-tunnel.md の `OFFLINE_HOST` だけ
  - トンネルの張り方・dnf の設定・閉じ方は、もとはこの文書の手順 1〜4・7〜9 だった（[virtualbox-guest-bootc.md](../virtualbox-guest-bootc.md) と共有するため、ssh-socks-tunnel.md に移した）
- **状態**: **x86_64 のクリーンインストール VM で現行の実施手順と jq のロールバックを再検証済み（2026-10-06、SELinux Enforcing）。実機の AlmaLinux・aarch64 は未実施**
  - 現行版を新規 VM で通した範囲は[今回の再検証の付録](#付録-現行版を新規-vm-で再検証2026-10-06)。以前の VM・コンテナの付録と未確認事項は、当時の範囲の記録。
  - このクラウドのホスト（Ubuntu 24.04）の Docker で、外に出られないネットワーク（`--internal`）だけにつないだコンテナをオフラインのホストにした
  - オンラインのホストは、外に出られるネットワークと、その `--internal` のネットワークの両方につないだ別のコンテナ
  - **この文書のコードブロックをそのまま**、擬似端末で開いたオンラインのホストの対話の bash に貼って、当時の手順 1〜9、[更新](../homebrew-offline.md#更新)、[ロールバック](../extra/homebrew-offline.md#ロールバック)を通した
    - 当時の手順 1〜9 は、今の ssh-socks-tunnel.md の手順 1〜3・dnf の節・トンネルを閉じる節と、この文書の手順 1・3〜6（手順 3 は homebrew.md の手順 1〜4）。今の手順 2 は、当時の手順 4（dnf の設定）に当たる
  - 貼り方はブラケットペースト無し。dnf の設定とその行の削除（当時の手順 4 とロールバックの手順 2）は、ブラケットペースト有りでも通した
  - 2026-09-30 に、ssh-socks-tunnel.md に移した後のブロックで、同じ作りのコンテナでもう一度通した（[ssh-socks-tunnel.md の付録](ssh-socks-tunnel.md#付録-コンテナでの検証記録2026-09-30)）
  - 確認したこと:
    - トンネルを張る前は、オフラインのホストから外の名前を引けず、IP アドレスでもつながらない
    - トンネル越しに、dnf（homebrew.md の手順 1 の 73 パッケージを含む）、Homebrew のインストーラ、`brew install`、`brew update` が通る
    - トンネルを閉じた後も jq が動き、外には届かない
    - ほかの手順書も、トンネルのシェルでそのまま通る（[bat.md](../almalinux-setup.md) の手順 1〜3、[hackgen.md](../hackgen.md) の手順 1〜5。hackgen.md の手順 3 は dnf、手順 4 は GitHub からの cask の取得）
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
| Homebrew | 入れていない | `7.0.7`（手順 3 で新規導入） |
| ユーザー | `<USER>`（uid 1000） | 同じ名前（uid 1000、NOPASSWD の sudo）と、確かめ用の 2 人目（uid 1001） |
| コンテナのホスト | Ubuntu 24.04 / x86_64 のクラウドの VM、Docker 29.3.1（cgroup v1） | 同左 |

> [!NOTE]
> この文書には変数が無い。オフラインのホストの名前とユーザーは、[ssh-socks-tunnel.md 手順 1](../ssh-socks-tunnel.md#実施手順) の変数で設定する。
>
> 出力例・ログ・表の中の値は `<OFFLINE_HOST>` / `<USER>`（ユーザー名）のプレースホルダで書いてある。バージョン（`7.0.7` など）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

オフラインのホスト（コンテナ）で、トンネルを張る前に確かめた状態:

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

### 完了時点の状態

**検証のコンテナでの出力**（当時の手順 9。今の手順 6 と、ssh-socks-tunnel.md のトンネルを閉じる節の手順 3。転送無しでログインし直したオフラインのホストのシェル）:

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

- 手順 2 で dnf の設定をしたときは、`/etc/dnf/dnf.conf` に `proxy=socks5h://127.0.0.1:1080` が 2 行目に残る（[ssh-socks-tunnel.md のロールバック](../extra/ssh-socks-tunnel.md#ロールバック)で消す）
- オンラインのホストに残るのは、`~/.ssh/known_hosts` のオフラインのホストの行だけ
- `/home/linuxbrew/.linuxbrew` は、検証の最後（bat と HackGen が入り、jq を消した状態）で 286 MB

### 付録: コンテナでの検証記録（2026-09-29）

`docker.io/library/almalinux:10`（AlmaLinux 10.2、x86_64、`sha256:95773870…9677`）から 2 つのイメージを作り、x86_64 のクラウドホスト（Ubuntu 24.04）の Docker 29.3.1 でコンテナを立てた。実機で加えた変更は無い。

検証の準備（手順書の外）:

- ネットワークを 2 つ作った。外に出られない `docker network create --internal` のもの（オフラインのホスト用）と、ふつうのもの（オンラインのホスト用）。オンラインのホストのコンテナは両方につないだ
- オフラインのホスト: `openssh-server`・`sudo`・`iproute` を入れ、`ssh-keygen -A` のうえで `sshd -D -e` を動かした（systemd 無し）。ユーザー（uid 1000、NOPASSWD の sudo）と、確かめ用の 2 人目（uid 1001）を作った。`git`・`file`・`procps-ng` は入れていない
- オンラインのホスト: `openssh-clients` を入れ、同じ名前のユーザーで鍵を作り、公開鍵をオフラインのホストの `authorized_keys` に置いた（鍵認証なので、パスワードは聞かれない）
- このクラウドのホストの外向きの通信は、TLS を署名し直すゲートウェイを通る。そのゲートウェイの CA を、オフラインのホストの信頼ストアに足した
  - オンラインのホストの ssh は TCP を中継するだけなので、CA が要るのはオフラインのホストの curl・git・dnf
  - 実際のオンラインのホストでは、この変更は要らない
- hackgen.md の手順 5 の前に、`fontconfig` を dnf で入れた（hackgen.md の検証と同じ。トンネルと dnf の設定で入った）

コードブロックの流し方:

- 文書からコードブロックを抜き出し、`docker exec -it` で開いたオンラインのホストの対話の bash（擬似端末、`TERM=xterm-256color`）に、手順ごとに 1 回で送った（ブラケットペースト無し。改行は CR）
- 当時の手順 1（今の ssh-socks-tunnel.md の手順 1）の `OFFLINE_HOST` は、コンテナの名前に書き換えた
- ホスト鍵の確認には `yes`、インストーラの `RETURN` と brew の `[y/n]` には、表示が出てから Enter と `y` を送った
- dnf の設定とその行の削除（当時の手順 4 とロールバックの手順 2）は、ブラケットペーストの開始と終了の制御文字で囲んだ形でも送った

| 手順（当時の番号と、今の場所） | 結果 |
|---|---|
| 実施前 | [実施前の状態](#実施前の状態)のとおり。外の名前も引けず、IP アドレスでもつながらない |
| 1（ssh-socks-tunnel.md 1） | `OFFLINE_HOST = <OFFLINE_HOST>` / `OFFLINE_USER = <USER>` |
| 2（ssh-socks-tunnel.md 2） | ホスト鍵の確認に `yes` → `Warning: Permanently added '<OFFLINE_HOST>' (ED25519) to the list of known hosts.` の後にログインした |
| 3（ssh-socks-tunnel.md 3 と、この文書の 1） | `127.0.0.1:1080` の 1 行、`200` / `301` / `200` / `401`。`rpm -q` は curl だけ入っていた |
| 4（ssh-socks-tunnel.md の dnf の節。この文書の 2） | `2:proxy=socks5h://127.0.0.1:1080`、`Metadata cache created.` |
| 5（今の 3。homebrew.md 手順 1） | `file`・`git`・`procps-ng` と依存で 73 パッケージを導入し、4 つ（`curl`・`libcurl-minimal`・`openssl-libs`・`openssl-fips-provider`）を更新した（ダウンロード 21 MB）。`Complete!` |
| 5（今の 3。homebrew.md 手順 2） | `NONINTERACTIVE` を付けずに実行し、`Press RETURN/ENTER to continue` で Enter。Homebrew/brew の git の取得と、`portable-ruby-4.0.7.x86_64_linux` の取得がトンネルを通り、`==> Installation successful!` |
| 5（今の 3。homebrew.md 手順 3・4） | `Homebrew 7.0.7`、`HOMEBREW_PREFIX: /home/linuxbrew/.linuxbrew`、`Branch: stable` |
| 6（今の 4。最初の版） | `brew install jq` の後ろに `jq --version` と `brew list --versions jq` を続けたブロックだった。`[y/n]` の確認に後ろの行の文字が読まれ、`Invalid input` が 11 回出た後、`n` で中止になった。jq は入らず、当時の手順 9 で `jq: command not found`。この手順を `brew install jq` だけにし、確かめは当時の手順 9（今の手順 6）に移した |
| 6（今の 4） | `[y/n]` に `y`。`oniguruma` と `jq 1.8.2` のボトルがトンネル越しに降りた |
| 7（ssh-socks-tunnel.md のトンネルを閉じる節の 1） | `Connection to <OFFLINE_HOST> closed.` |
| 8（同じ節の 2） | 転送無しでログインした |
| 9（今の 6 と、同じ節の 3） | `jq 1.8.2`、`/home/linuxbrew/.linuxbrew/bin/jq`、`offline`。`ss` は無出力。curl は `Could not resolve host: github.com` で、`届かない（期待どおり）` |
| ほかの手順書 | 当時の手順 1〜3 のシェルで、bat.md の手順 1〜3（`[y/n]` に `y`。依存 8 つと `bat 0.26.1`）と、hackgen.md の手順 1〜5（hackgen.md の手順 3 の `sudo dnf install -y unzip` は dnf の設定で通り、手順 4 の cask は GitHub から取得）が通った |
| 更新 | `Already up-to-date.`。`brew outdated` と `brew upgrade` は無出力（入れた直後のため）。当時のこの節の手順 3 の `exit`（今は ssh-socks-tunnel.md のトンネルを閉じる節の手順 1）で、`127.0.0.1:1080` の待ち受けが消えた |
| ロールバック | トンネル無しのシェルで通した。この節の手順 1 は `Uninstalling …/jq/1.8.2... (21 files, 1.5MB)` で、`brew autoremove` は無出力。当時のこの節の手順 2（今は ssh-socks-tunnel.md のロールバック）は `0` で、`/etc/dnf/dnf.conf` は dnf の設定の前と同じ内容に戻った |
| ブラケットペースト | dnf の設定（当時の手順 4）は `2:proxy=…` と `Metadata cache created.`。続けてもう一度貼ると `中断: …`。その行の削除（当時のロールバックの手順 2）は `0` |

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
| 1080 番がふさがっている | 当時の手順 2（今の ssh-socks-tunnel.md の手順 2）は `Error: remote port forwarding failed for listen port 1080` で、ログインせずに戻った。`-o ExitOnForwardFailure=yes` を外すと、`Warning: …` を出してからログインした |
| sshd が転送を禁じている | オフラインのホストの `/etc/ssh/sshd_config.d/` に `AllowTcpForwarding no` を置いて sshd に読み直させると、当時の手順 2 のコマンドは同じ `Error: …` で終わった（終了コード 255）。確かめた後に消した |
| 接続の共有 | `ControlMaster auto`・`ControlPersist 10m` の設定で `ControlPath=none` を外すと、`exit` の後も待ち受けが残った。当時の手順 2 のままなら、当時の手順 7 で消えた |
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
- オフラインのホストからの `ssh -D`（[選択した方針](../reference/homebrew-offline.md#選択した方針)の代わりの形）
- homebrew.md のロールバック（`uninstall.sh`）をトンネル越しに実行すること
- `brew upgrade` の `[y/n]`（検証の時点では上げるものが無かった）

---

### 付録: VM での検証記録（2026-10-06）

**環境**: [クリーンインストールからの検証記録](../almalinux-vm-verification.md)のオフライン用 VM。公式 ISO から Workstation を入れた状態から始め、x86_64、SELinux Enforcing、firewalld 有効。本文のブロックを SSH の擬似端末で実行した。

- [ssh-socks-tunnel.md の今回の記録](ssh-socks-tunnel.md#付録-vm-での検証記録2026-10-06)と同じ、既定経路を無くして再起動した新しい VM を使った。Homebrew は未導入で、取得先に直接つながらない状態から始めた。
- 手順 1 の 4 URL は SOCKS 経由で順に 200 / 301 / 200 / 401。必要な RPM は Workstation に既に入っていたため、本文の条件に従って手順 2 と homebrew.md の手順 1 は飛ばした。
- 手順 3 が参照する homebrew.md の手順 2〜4 を本文のまま通し、Return と sudo の問い合わせに答えた。Homebrew 7.0.8 が新規に入り、PATH と prefix の確認も成功した。
- 手順 4 で jq 1.8.2 と依存の oniguruma をボトルから取得した。ask mode の問い合わせに `y` を押して完了を待った。
- 手順 5 では転送を保持した SSH を終了し、転送無しで再ログインした。外への通信が失敗することを確認した後、手順 6 で版、コマンドの場所、JSON の読み取り結果 `offline` を確認した。
- 最初の試験では、`ip route del` で消した経路が DHCP / RA によって戻った。試験環境の問題としてその結果をオフライン成功とは扱わず、NetworkManager の永続設定をしたクリーン VM で取り直した。
- 更新・ロールバック、ほかの Homebrew 文書をすべてオフラインで通すこと、実機・aarch64 は今回未確認。

---

### 付録: 現行版を新規 VM で再検証（2026-10-06）

**対象**: `setup-notes` の `5da3478` 版。公式 ISO の Workstation クリーンインストールの `clean-install` スナップショットから、新規の `alma10-current-20261006-offline` を作った。AlmaLinux 10.2 / x86_64 / SELinux Enforcing / firewalld 有効。共通 bash は `3d5323e` を新規導入した。以前の付録と別の試験で、現行ブロックを SSH の擬似端末で順に実行した。

- 実施手順 1〜6 を通した。Homebrew の取得先 4 つは `200` / `301` / `200` / `401`。Workstation の依存は導入済みだが、npm 用に dnf のプロキシ設定も通した。前提の共通 bash を導入したシェルで Homebrew 7.0.8 を新規導入し、本文の jq の導入で 1.8.2 のボトルを取得した。
- トンネル終了後に再ログインすると、jq の場所は `/home/linuxbrew/.linuxbrew/bin/jq`、JSON の抽出結果は `offline`。同時に直接通信と npm の通信は失敗した。導入したコマンドの実行にトンネルが不要なことを確認した。
- ロールバックのブロックで jq と不要な依存を撤去し、最後の一覧に jq が無かった。Homebrew 自体と別途導入した Neovim は残した。更新、Homebrew 本体のアンインストール、実機・aarch64 はこの再検証では行っていない。

### 手順中の実測・検証状況の記録

- 検証では [bat](../almalinux-setup.md) も入れていたので、jq の依存の `oniguruma` は bat の依存として残った

### 手順中の実測・検証状況の記録

- **ssh が切れると、トンネルも消える**: 途中の `brew install` や dnf は、取得の途中なら失敗するはず（本書では確かめていない）。そのときは [ssh-socks-tunnel.md 手順 2](../ssh-socks-tunnel.md#実施手順) から張り直して、同じコマンドを貼り直す

### 手順中の実測・検証状況の記録

- **入れた後もネットワークを使うツールは、オフラインのホストではその部分が動かない**: たとえば [dropbox-rclone.md](../dropbox-rclone.md) の同期（Dropbox の API）や、[syncthing.md](../syncthing.md) の LAN の外の端末との同期（本書では確かめていない）

### 手順中の検証状況

- **トンネルそのものの注意は、[ssh-socks-tunnel.md の注意点](../extra/ssh-socks-tunnel.md#注意点)**: 転送中はオフラインのホストのどのユーザーもプロキシを使える、出口はオンラインのホスト、`socks5h` の `h`、`https_proxy` が勝つ、`sudo` は `ALL_PROXY` を渡さない、dnf の行が残る、SELinux は確かめていない

### 選択した方針

| **ssh の SOCKS トンネル（[ssh-socks-tunnel.md](../ssh-socks-tunnel.md) の `ssh -R 1080`）で、オフラインのホストから取得する** | オンラインのホストからオフラインのホストへ ssh でログインできること。どちらのホストにも追加のソフトは要らない | **採用。** オフラインのホストで curl・git・brew・dnf がそのまま外に届き、homebrew.md とほかの Homebrew 系の手順書を変えずに貼れる。オフラインのホストが自分のアーキのボトルを取るので、2 台のアーキが違ってもよい（ただし本書は x86_64 でしか確かめていない）。トンネルの張り方どうしの比較（`-D`・HTTP プロキシ）は、同書の[選択した方針](ssh-socks-tunnel.md#選択した方針) |

| `/home/linuxbrew/.linuxbrew` を tar にして運ぶ | 同じ OS・同じアーキのホストで Homebrew と formula を入れる。上げるたびに作り直して運ぶ | 本書では扱わない（ネットワークで届かないときの方法。確かめていない） |

| `brew fetch` でボトルだけを運ぶ | Homebrew 本体（git のリポジトリと portable-ruby）と、formula の API の JSON も要る | 本書では扱わない（確かめていない） |

