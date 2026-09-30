# Homebrew をインターネットに出られないホストで使う手順（AlmaLinux 10 / ssh -R の SOCKS プロキシ）

## 実施手順

> [!IMPORTANT]
> - **前提**: [ssh-socks-tunnel.md](ssh-socks-tunnel.md) の手順 1〜3 で、インターネットに出られるホスト（以下、オンラインのホスト）からトンネルを付けて、インターネットに出られないホスト（以下、オフラインのホスト）にログインしてあること。**この文書は、同書の手順 3 のシェルのまま貼る**（Homebrew の通信もトンネルを通すため）
> - **オフラインのホストには、`sudo` できる自分のユーザーでログインする**（同書の手順 1 の `OFFLINE_USER`）。root ではログインしない（Homebrew は root で動かない）
> - **手順 3 で [homebrew.md](homebrew.md) の手順 1〜4 を、同じシェルのまま貼る**
> - **手順 2〜4 には対話入力がある**（`sudo` のパスワード、インストーラの `RETURN`、brew の `[y/n]`）。終わってから次の手順を貼る
> - **手順 5 はトンネルを閉じてログインし直す**（オンラインのホストで行う操作がある）

- 上から順に、ssh-socks-tunnel.md の手順 3 のシェルで貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: ほかの Homebrew 系の手順書（[bat](bat.md) など）は、ssh-socks-tunnel.md の手順 1〜3 でトンネルを張ったシェルで貼る。以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **x86_64 のコンテナでのみ検証した手順書**で、実機では本実行していない。オフラインのホストは、外に出られない Docker のネットワークだけにつないだコンテナ（[対象と検証環境](#対象と検証環境)）。
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
   - `rpm -q` の 4 つがどれも入っていれば、**手順 2 は飛ばし、手順 3 でも homebrew.md の手順 1 を飛ばす**
   - dnf がトンネル無しで届くリポジトリ（社内のミラーなど）を使うホストなら、手順 2 は飛ばす

   <details>
   <summary>補足: 4 つの URL と、brew のプロキシ</summary>

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

   **brew も `ALL_PROXY` を読む**（curl と git は [ssh-socks-tunnel.md 手順 3](ssh-socks-tunnel.md#実施手順) の補足）。Homebrew の `bin/brew` は、環境変数を絞ってから動くが、`all_proxy` と `ALL_PROXY` は通す（307 行目: `http_proxy https_proxy ftp_proxy no_proxy all_proxy HTTPS_PROXY FTP_PROXY ALL_PROXY`）。`man brew` の「USING HOMEBREW BEHIND A PROXY」も、SOCKS5 のプロキシには `all_proxy` を使う例を挙げている。

   **`ALL_PROXY` を入れずに brew を使うと、外に届かない。** トンネルのシェルで `( unset ALL_PROXY; brew update )` を実行したときの出力:

   ```
   ==> Updating Homebrew...
   fatal: unable to access 'https://github.com/Homebrew/brew/': Could not resolve host: github.com
   Error: Fetching /home/linuxbrew/.linuxbrew/Homebrew failed!
   Failed to download https://formulae.brew.sh/api/internal/packages.x86_64_linux.jws.json!
   ```

   </details>

1. 手順 1 で入っていないパッケージがあったときだけ、[ssh-socks-tunnel.md の「dnf にもトンネルを使わせる（任意）」](ssh-socks-tunnel.md#dnf-にもトンネルを使わせる任意)を行う。

   - homebrew.md の手順 1 の dnf が、トンネルを通るようになる
   - 足した行は、[ロールバック](#ロールバック)のリードのとおり、ssh-socks-tunnel.md のロールバックで消す
   - **次の手順は、同書の節の `sudo` のパスワードに答え、`Metadata cache created.` が出てから貼る**

1. 手順 1 のシェルのまま、[homebrew.md 手順 1〜4](homebrew.md#実施手順) を貼る。

   - `command -v brew` が `/home/linuxbrew/.linuxbrew/bin/brew` を返すなら、Homebrew は入っているので、この手順は飛ばす
   - homebrew.md の手順 1 の dnf は、手順 2 の設定で通る（手順 1 で 4 つとも入っていたなら飛ばす）
   - homebrew.md の手順 2 のインストーラも、中で使う curl と git が `ALL_PROXY` を読むので、そのまま通る
   - **次の手順は、homebrew.md の手順 4 まで終えてから貼る**（homebrew.md の手順 1・2 に `sudo` のパスワードと `RETURN` の確認がある）

1. 確かめるために、brew で jq をトンネル越しに入れる。

   ```bash
   brew install jq
   ```

   - 入れるものの一覧の後に `==> Do you want to proceed with the installation? [y/n]` と聞かれるので、`y` を押す（Enter は要らない）
   - `==> Pouring jq--…bottle…tar.gz` と出て、ソースからのビルドにならない
   - ほかの Homebrew 系の手順書も、手順 5 の前に、このシェルで貼る
   - **次の手順は、`y` を押して入れ終わってから貼る**（続けて貼ると、後ろの行の文字が答えとして読まれる）

   <details>
   <summary>補足: brew の確認（ask mode）と、トンネル越しの取得</summary>

   **Homebrew 7.0.7 の `brew install` は、端末から実行すると、入れるものの一覧を出してから `[y/n]` を聞く**（ask mode。[homebrew.md の注意点](homebrew.md#注意点)）。

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

1. [homebrew.md の更新](homebrew.md#更新)の手順 1・2 を貼る。

   - `brew outdated` が何も出さなければ、上げるものは無いので、homebrew.md の更新の手順 2 は飛ばす
   - `brew upgrade` が `[y/n]` と聞いたら、`y` を押す（[手順 4](#実施手順) と同じ確認）
   - **次の手順は、上げ終わってから行う**（続けて貼ると、後ろの行の文字が答えとして読まれる）

1. [ssh-socks-tunnel.md の「トンネルを閉じる」](ssh-socks-tunnel.md#トンネルを閉じる)の手順 1 で、トンネルを閉じる。

---

## ロールバック

- オフラインのホストで貼る。トンネルは要らない
- Homebrew ごと消すなら、この節の手順 1 の代わりに、[ssh-socks-tunnel.md の手順 1〜3](ssh-socks-tunnel.md#実施手順) でトンネルを張ったシェルで [homebrew.md のロールバック](homebrew.md#ロールバック)を行う（アンインストーラを取得するため。本書では実行していない）
- [手順 2](#実施手順) で dnf にプロキシを設定したときは、[ssh-socks-tunnel.md のロールバック](ssh-socks-tunnel.md#ロールバック)で dnf の行を消す

1. 手順 4 で入れた jq を使わないときだけ、jq と、一緒に入った依存を消す。

   ```bash
   brew uninstall jq
   brew autoremove
   brew list --versions
   ```

   - `brew autoremove` は、依存として入って、もうどの formula も使っていないものを消す（[homebrew.md の使い方の基本](homebrew.md#使い方の基本)）
   - 検証では [bat](bat.md) も入れていたので、jq の依存の `oniguruma` は bat の依存として残った
   - 最後の一覧に `jq` が無ければよい

---

## 補足

### 対象と検証環境

- **目的**: インターネットに出られない AlmaLinux 10 のホストで、Homebrew と、Homebrew で入れるコマンドを使えるようにする
  - 入れる・上げるときだけ、そのホストへ ssh でログインしてくるオンラインのホストを経由して外に出る
  - 入れたコマンドは、トンネルが無くても動く
- **進め方**: 前提の [ssh-socks-tunnel.md](ssh-socks-tunnel.md) で、オンラインのホストから `ssh -R 1080` でログインし、オフラインのホストにできた SOCKS の待ち受けを `ALL_PROXY` で使う。Homebrew の導入は、homebrew.md をそのシェルのまま貼る
  - この文書には変数が無い。読者が編集するのは、ssh-socks-tunnel.md の `OFFLINE_HOST` だけ
  - トンネルの張り方・dnf の設定・閉じ方は、もとはこの文書の手順 1〜4・7〜9 だった（[virtualbox-guest-bootc.md](virtualbox-guest-bootc.md) と共有するため、ssh-socks-tunnel.md に移した）
- **状態**: **x86_64 のコンテナでのみ検証済み（2026-09-29）。実機では本実行していない**
  - このクラウドのホスト（Ubuntu 24.04）の Docker で、外に出られないネットワーク（`--internal`）だけにつないだコンテナをオフラインのホストにした
  - オンラインのホストは、外に出られるネットワークと、その `--internal` のネットワークの両方につないだ別のコンテナ
  - **この文書のコードブロックをそのまま**、擬似端末で開いたオンラインのホストの対話の bash に貼って、当時の手順 1〜9、[更新](#更新)、[ロールバック](#ロールバック)を通した
    - 当時の手順 1〜9 は、今の ssh-socks-tunnel.md の手順 1〜3・dnf の節・トンネルを閉じる節と、この文書の手順 1・3〜6（手順 3 は homebrew.md の手順 1〜4）。今の手順 2 は、当時の手順 4（dnf の設定）に当たる
  - 貼り方はブラケットペースト無し。dnf の設定とその行の削除（当時の手順 4 とロールバックの手順 2）は、ブラケットペースト有りでも通した
  - 2026-09-30 に、ssh-socks-tunnel.md に移した後のブロックで、同じ作りのコンテナでもう一度通した（[ssh-socks-tunnel.md の付録](ssh-socks-tunnel.md#付録-コンテナでの検証記録2026-09-30)）
  - 確認したこと:
    - トンネルを張る前は、オフラインのホストから外の名前を引けず、IP アドレスでもつながらない
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
| Homebrew | 入れていない | `7.0.7`（手順 3 で新規導入） |
| ユーザー | `<USER>`（uid 1000） | 同じ名前（uid 1000、NOPASSWD の sudo）と、確かめ用の 2 人目（uid 1001） |
| コンテナのホスト | Ubuntu 24.04 / x86_64 のクラウドの VM、Docker 29.3.1（cgroup v1） | 同左 |

> [!NOTE]
> この文書には変数が無い。オフラインのホストの名前とユーザーは、[ssh-socks-tunnel.md 手順 1](ssh-socks-tunnel.md#実施手順) の変数で設定する。
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

### 選択した方針

| 経路 | 要るもの | 採否 |
|---|---|---|
| **ssh の SOCKS トンネル（[ssh-socks-tunnel.md](ssh-socks-tunnel.md) の `ssh -R 1080`）で、オフラインのホストから取得する** | オンラインのホストからオフラインのホストへ ssh でログインできること。どちらのホストにも追加のソフトは要らない | **採用。** オフラインのホストで curl・git・brew・dnf がそのまま外に届き、homebrew.md とほかの Homebrew 系の手順書を変えずに貼れる。オフラインのホストが自分のアーキのボトルを取るので、2 台のアーキが違ってもよい（ただし本書は x86_64 でしか確かめていない）。トンネルの張り方どうしの比較（`-D`・HTTP プロキシ）は、同書の[選択した方針](ssh-socks-tunnel.md#選択した方針) |
| `/home/linuxbrew/.linuxbrew` を tar にして運ぶ | 同じ OS・同じアーキのホストで Homebrew と formula を入れる。上げるたびに作り直して運ぶ | 本書では扱わない（ネットワークで届かないときの方法。確かめていない） |
| `brew fetch` でボトルだけを運ぶ | Homebrew 本体（git のリポジトリと portable-ruby）と、formula の API の JSON も要る | 本書では扱わない（確かめていない） |

- **homebrew.md を、リードで前提として挙げるのではなく、手順 3 にした**: ほかの Homebrew 系の手順書と違い、トンネルを張ったシェルの中で貼る必要があるため
- **トンネルの手順は、ssh-socks-tunnel.md を前提にした**: [virtualbox-guest-bootc.md](virtualbox-guest-bootc.md#ホストオンリーアダプターだけの-vm-でビルドする任意) でも、同じトンネルを使うため

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

- 手順 2 で dnf の設定をしたときは、`/etc/dnf/dnf.conf` に `proxy=socks5h://127.0.0.1:1080` が 2 行目に残る（[ssh-socks-tunnel.md のロールバック](ssh-socks-tunnel.md#ロールバック)で消す）
- オンラインのホストに残るのは、`~/.ssh/known_hosts` のオフラインのホストの行だけ
- `/home/linuxbrew/.linuxbrew` は、検証の最後（bat と HackGen が入り、jq を消した状態）で 286 MB

### 注意点

- **トンネルそのものの注意は、[ssh-socks-tunnel.md の注意点](ssh-socks-tunnel.md#注意点)**: 転送中はオフラインのホストのどのユーザーもプロキシを使える、出口はオンラインのホスト、`socks5h` の `h`、`https_proxy` が勝つ、`sudo` は `ALL_PROXY` を渡さない、dnf の行が残る、SELinux は確かめていない
- **`sudo brew` はもともと使えない**: [homebrew.md の注意点](homebrew.md#注意点)
- **ほかの手順書の `sudo dnf` も、手順 2 を行ったときだけ通る**: hackgen.md の手順 3（`unzip`）は、dnf の設定で通った
- **トンネルが要るのは、取得するときだけ**: `brew install` / `brew update` / `brew upgrade` は要る。`brew list` / `brew uninstall` / `brew autoremove` は要らない
  - トンネル無しの `brew install hello` は、`curl: (6) Could not resolve host: ghcr.io` と `Error: Failed to download resource "hello"` で失敗した
- **brew は、依存が付くときに `[y/n]` を聞く**: ほかの Homebrew 系の手順書の `brew install` でも、端末から実行すると同じように聞かれる（[homebrew.md の注意点](homebrew.md#注意点)）。bat.md の手順 2（依存が 8 つ）でも聞かれた（手順 4 の補足）
- **ssh が切れると、トンネルも消える**: 途中の `brew install` や dnf は、取得の途中なら失敗するはず（本書では確かめていない）。そのときは [ssh-socks-tunnel.md 手順 2](ssh-socks-tunnel.md#実施手順) から張り直して、同じコマンドを貼り直す
- **入れた後もネットワークを使うツールは、オフラインのホストではその部分が動かない**: たとえば [dropbox-rclone.md](dropbox-rclone.md) の同期（Dropbox の API）や、[syncthing.md](syncthing.md) の LAN の外の端末との同期（本書では確かめていない）

### 参照

- [ssh の SOCKS トンネル](ssh-socks-tunnel.md) — 前提の手順書（トンネルの張り方・dnf の設定・閉じ方。ssh・curl・git・dnf の参照もそちら）
- [Homebrew — Manpage の USING HOMEBREW BEHIND A PROXY](https://docs.brew.sh/Manpage#using-homebrew-behind-a-proxy) — Homebrew が読むプロキシの環境変数
- [Homebrew](homebrew.md) — 手順 3 で貼る Homebrew 本体の導入手順

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
- オフラインのホストからの `ssh -D`（[選択した方針](#選択した方針)の代わりの形）
- homebrew.md のロールバック（`uninstall.sh`）をトンネル越しに実行すること
- `brew upgrade` の `[y/n]`（検証の時点では上げるものが無かった）
