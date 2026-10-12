# ssh の SOCKS トンネル手順（AlmaLinux 10 / インターネットに出られないホストから ssh -R で外に出る）の検証記録

[手順書](../almalinux-setup.md#ssh-の-socks-トンネル-実施手順)・[ロールバックと注意点](../extra/ssh-socks-tunnel.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **トンネルを張っている間は、オフラインのホストのどのユーザーも `127.0.0.1:1080` を通ってインターネットに出られる**（出口はオンラインのホスト）。使い終わったら[トンネルを閉じる](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/ssh-socks-tunnel.md#トンネルを閉じる)。
>
> - Linux のオンラインのホストは、x86_64 のコンテナでのみ確かめた。Windows 11 のホストから、SELinux Enforcing のクリーンインストール VM への転送も再検証した（2026-10-06）（[対象と検証環境](#対象と検証環境)）

### 実施手順 / 手順 2: 本文中の記録

   - オンラインのホストが Windows なら、手順 1 は飛ばし、PowerShell か cmd に `ssh -o ExitOnForwardFailure=yes -o ControlPath=none -R 1080 <OFFLINE_USER>@<OFFLINE_HOST>` を打つ（Windows に最初から入っている OpenSSH のクライアントで確かめた）

### 実施手順 / 手順 2: 補足: 逆向きの動的転送と、2 つのオプション

**`-R` にポートだけを書く（転送先を書かない）と、ssh が SOCKS のプロキシとして働く。** オフラインのホストの sshd がそのポートで待ち受け、そこへ来た接続を、オンラインのホストの ssh が SOCKS の要求の宛先へつなぐ。

- OpenSSH 7.6 で入った機能で、オンラインのホストの ssh だけで実装されている。オフラインのホストの sshd の版は問わない（[参照](../reference/ssh-socks-tunnel.md#参照)のリリースノート）
- 待ち受けは、sshd の `GatewayPorts` が既定の `no` なら loopback だけ（`127.0.0.1`、IPv6 があれば `::1` も）。`yes` のホストでは LAN 全体に開くので、手順 3 の `ss` で確かめる
- オフラインのホストの sshd が転送を許しているかは、オフラインのホストで `sudo sshd -T | grep -E '^(allowtcpforwarding|gatewayports|disableforwarding|permitlisten)'` で見られる。AlmaLinux の既定は `allowtcpforwarding yes`・`gatewayports no`・`disableforwarding no`・`permitlisten any` だった（AlmaLinux Atomic Desktop の VM も同じ）

**`-o ExitOnForwardFailure=yes`: 転送を作れないときに、ログインせずに終わる。** 1080 番を別の ssh の転送でふさいでから手順 2 を貼ると、次の 1 行を出してオンラインのホストのプロンプトに戻った:

```
Error: remote port forwarding failed for listen port 1080
```

- オフラインのホストの sshd に `AllowTcpForwarding no` を入れたときも、同じ 1 行で終わった
- 付けないと、転送が無いままログインする。1080 番をふさいだまま `-o ExitOnForwardFailure=yes` を外すと、`Warning: remote port forwarding failed for listen port 1080` を出してからログインした（手順 3 で気づくことになる）

**`-o ControlPath=none`: この ssh では、接続の共有を使わない。** オンラインのホストの `~/.ssh/config` で `ControlMaster auto` と `ControlPersist` を使っていると、転送は裏に残るマスターの接続に付く。

- 検証環境で `~/.ssh/config` に `ControlMaster auto`・`ControlPath ~/.ssh/cm-%r@%h:%p`・`ControlPersist 10m` を書き、`ControlPath=none` を外して入ると、`exit` の後（`Shared connection to <OFFLINE_HOST> closed.`）も、オフラインのホストに `127.0.0.1:1080` の待ち受けが残った
- 同じ設定のまま手順 2 のとおりに入ると、[トンネルを閉じる](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/ssh-socks-tunnel.md#トンネルを閉じる)の手順 1 の `exit` で待ち受けが消えた

**Windows のオンラインのホスト**: Windows 11 の `C:\Windows\System32\OpenSSH\ssh.exe`（`OpenSSH_for_Windows_9.5p2`）で、VirtualBox の VM へ同じ転送を張れた（[virtualbox-guest-bootc.md の付録](virtualbox-guest-bootc.md#付録-ホストオンリーアダプターだけの-vm-での本実行2026-09-30)。その文書のホストオンリーアダプターの節は、その後トンネルを使わない形に変わった）。

- トンネルは Windows の外向きの接続なので、Windows の受信の規則は要らない
- オフラインのホスト（VM）が再起動すると、Windows の ssh は `Connection to <VM_IP> closed by remote host.` で終わり、待ち受けも消えた

**1080 番を変えるとき**は、手順 2 の `-R 1080`、手順 3 の `ALL_PROXY` と `ss` の `1080`、[dnf の節](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/ssh-socks-tunnel.md#dnf-にもトンネルを使わせる任意)と[ロールバック](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/extra/ssh-socks-tunnel.md#ロールバック)の `127.0.0.1:1080`、[トンネルを閉じる](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/ssh-socks-tunnel.md#トンネルを閉じる)の手順 3 の `ss` の `1080`、使う側の手順書の `127.0.0.1:1080` を、どれも同じ番号にする。

### 実施手順 / 手順 3: 補足: socks5h と ALL_PROXY

**`socks5h` の `h` は、名前をプロキシの側（オンラインのホスト）で引く指定。** オフラインのホストは外の名前を引けないので、`h` を落とすと届かない。コンテナでの実測:

```
$ curl -sS -o /dev/null --connect-timeout 10 -x socks5://127.0.0.1:1080 https://github.com
curl: (97) Could not resolve host: github.com
```

**`ALL_PROXY` を読むもの**:

- curl は、プロトコルを問わずに使う
- git は、`http.proxy` の設定も `https_proxy` も無いときに `ALL_PROXY` を使い、`socks5h` を解る。`GIT_TRACE_CURL=1 git ls-remote https://github.com/Homebrew/brew HEAD` の出力に `SOCKS5 connect to github.com:443 (remotely resolved)` が出た
- Homebrew（[homebrew-offline.md 手順 1](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/homebrew-offline.md#実施手順) の補足）
- `https_proxy`（`HTTPS_PROXY`）や git の `http.proxy` が既に入っていると、curl と git はそちらを使う。`env | grep -i proxy` と `git config --get http.proxy` が何も出さないことを確かめておく

**`ALL_PROXY` を読まないもの**:

- **`sudo` を付けたコマンド**: `sudo printenv ALL_PROXY` は何も出さず、終了コード 1 だった（AlmaLinux の `/etc/sudoers` は `env_reset` で、`env_keep` にプロキシの変数が無い）。dnf には、[dnf の節](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/ssh-socks-tunnel.md#dnf-にもトンネルを使わせる任意)で設定ファイルから渡す
- **podman**: `https_proxy`（`HTTPS_PROXY`）を読み、`ALL_PROXY` だけでは取り込めなかった。`sudo https_proxy=socks5h://127.0.0.1:1080 podman …` のように、コマンドの前に変数を置いて渡す（[virtualbox-guest-bootc.md の付録](virtualbox-guest-bootc.md#付録-ホストオンリーアダプターだけの-vm-での本実行2026-09-30)。トンネルを使っていた版の、その節の手順 4 の補足の実測）
- **npm**: `https_proxy` を読む（[npm-offline.md 手順 2](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/npm-offline.md#実施手順) の補足）。npm には、`ALL_PROXY` と同じ値の `https_proxy` を足す

### dnf にもトンネルを使わせる（任意） / 手順 1: 補足: dnf のプロキシ

**`dnf config-manager --save --setopt=proxy=…` ではなく `sed` で書く。** `dnf config-manager` は `dnf-plugins-core` が無いと使えず、実機に入っていなかったことがある（[gh.md の実施前の状態](almalinux-setup.md#github-cli-実施前の状態)）。オフラインのホストでは、それを入れるにもこの設定が要る。

- `[main]` の行の直後に 1 行足す。AlmaLinux の `/etc/dnf/dnf.conf` は `[main]` の節だけ
- `proxy` で始まる行が既にあれば止める。書き換えると、[ロールバック](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/extra/ssh-socks-tunnel.md#ロールバック)で元に戻せなくなるため

**dnf 4.20 は `socks5h://` を受け付け、リポジトリの設定は変えずに通った。** AlmaLinux のミラーの一覧（`mirrors.almalinux.org`）も、一覧が返したミラーも、トンネルを通った。コンテナでの実測（進み具合の行は省いた）:

```
2:proxy=socks5h://127.0.0.1:1080
AlmaLinux 10 - AppStream                        5.1 MB/s | 2.7 MB     00:00
AlmaLinux 10 - BaseOS                            66 MB/s |  37 MB     00:00
AlmaLinux 10 - CRB                              1.7 MB/s | 616 kB     00:00
AlmaLinux 10 - Extras                            42 kB/s |  13 kB     00:00
Metadata cache created.
```

**この行がある間は、トンネルが無いと dnf はどこにも届かない。** 転送無しでログインしたシェルで `sudo dnf makecache` を実行したときの出力（長い行は省いた）:

```
Errors during downloading metadata for repository 'appstream':
  - Curl error (7): Could not connect to server for https://mirrors.almalinux.org/mirrorlist/10/appstream [Failed to connect to 127.0.0.1 port 1080 after 0 ms: Could not connect to server]
Error: Failed to download metadata for repo 'appstream': Cannot prepare internal mirrorlist: …
```

- オフラインのホストなので、この行が無くても dnf は外に届かない。失敗の出方が変わるだけ

### 対象と検証環境

- **目的**: インターネットに出られない AlmaLinux 10 のホストから、そこへ ssh でログインしてくるインターネットに出られるホストを経由して、外に出られるようにする
  - 入れる・取り込む・上げるときだけ使う。入れたものは、トンネルが無くても動く
- **進め方**: オンラインのホストから `ssh -R 1080` でログインし、オフラインのホストにできた SOCKS の待ち受けを `ALL_PROXY` で使う（dnf は `/etc/dnf/dnf.conf` の `proxy=`、podman と npm は `https_proxy`）
  - 読者が編集するのは `OFFLINE_HOST` だけ
  - もとは [homebrew-offline.md](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/homebrew-offline.md) の手順 1〜4・7〜9 と、[virtualbox-guest-bootc.md](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/virtualbox-guest-bootc.md#ホストオンリーアダプターだけの-vm-でビルドする任意) のホストオンリーアダプターの節の手順 2・3 にあった同じ仕組みを、共有の前提として 1 本にした
  - bootc のその節は、その後トンネルを使わずにホストでビルドする形に変わった。今これを前提にするのは、homebrew-offline.md と [npm-offline.md](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/npm-offline.md)
- **状態**: **Windows 11 のオンラインのホストから、x86_64 のクリーンインストール VM への現行の転送・dnf・転送終了・dnf 設定のロールバックを再検証済み（2026-10-06、SELinux Enforcing）。Linux 発のオンラインのホストは従来のコンテナのみ**
  - これは 2026-10-06 の時点の状態
  - 現行版を新規 VM で通した範囲は[今回の再検証の付録](#付録-現行版を新規-vm-で再検証2026-10-06)。以前の VM・コンテナの付録と未確認事項は、当時の範囲の記録。
  - コマンドは、この文書に移す前に、次の検証で通したもの
    - コンテナ（[homebrew-offline.md の付録](homebrew-offline.md#付録-コンテナでの検証記録2026-09-29)、2026-09-29）: 手順 1〜3（手順 3 の確かめる URL は Homebrew の 4 つだった）、dnf の節、トンネルを閉じる節（jq の確かめを含んでいた）、ロールバック
      - 1080 番がふさがっているときと、sshd が転送を禁じているときに ssh が止まること、接続の共有（`ControlPersist`）で転送が残ること、`sudo` が `ALL_PROXY` を渡さないこと、転送中は別のユーザーもプロキシを使えること
    - Windows 11 のホストの VirtualBox の VM（[virtualbox-guest-bootc.md の付録](virtualbox-guest-bootc.md#付録-ホストオンリーアダプターだけの-vm-での本実行2026-09-30)、2026-09-30）: 手順 2 の Windows の 1 行（ただし、自動で流すために鍵でログインし、`-N` を付けた）。VM の端末での `ss` と、`curl -x socks5h://127.0.0.1:1080 https://quay.io/v2/` の `401`
    - コンテナ（[npm-offline.md の付録](npm-offline.md#付録-コンテナでの検証記録2026-09-30)、2026-09-30）: npm-offline.md の前提として、手順 1〜3・dnf の節・トンネルを閉じる節の手順 1・2（当時の homebrew-offline.md の手順）。npm は `ALL_PROXY` だけでは届かず、`https_proxy` を足すと届くこと
  - 2026-09-30 に、この文書のブロックを x86_64 のコンテナでもう一度通した（[付録](#付録-コンテナでの検証記録2026-09-30)）
    - 手順 1〜3、dnf の節、トンネルを閉じる節、ロールバックと、それを使う [homebrew-offline.md](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/homebrew-offline.md) の手順 1〜6・更新・ロールバック
  - **確認していないこと**: Linux のオンラインのホストの実機、aarch64、Linux 発で SELinux が Enforcing のオフラインのホストへの接続、IPv6、パスワード認証（検証は鍵認証）、macOS の ssh、長い取得の途中で ssh が切れたとき

| 項目 | コンテナ（2026-09-29・30） | Windows のホストの VM（2026-09-30） |
|---|---|---|
| オンラインのホスト | AlmaLinux 10.2 / x86_64 のコンテナ。`openssh-clients-9.9p1-27.el10_2.alma.1` | Windows 11 Pro 25H2 / x86_64 のノート PC。`OpenSSH_for_Windows_9.5p2` |
| オフラインのホスト | AlmaLinux 10.2 / x86_64 のコンテナ（`--internal` のネットワークだけ）。`openssh-server-9.9p1-27.el10_2.alma.1`、systemd 無しで `sshd -D -e`、設定は AlmaLinux の既定のまま | VirtualBox の VM の AlmaLinux Atomic Desktop（ホストオンリーアダプターだけ） |
| ネットワーク | オフラインのホストは既定の経路も外の名前解決も無い。オンラインのホストは両方のネットワークにつないだ | VM は既定の経路が無く、外の名前を引けない |
| コンテナのホスト | Ubuntu 24.04 / x86_64 のクラウドの VM、Docker 29.3.1（cgroup v1） | — |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/ssh-socks-tunnel.md#実施手順) で、オンラインのホストのシェルに 1 度だけ設定する。オフラインのホストには変数が無い。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${OFFLINE_HOST}` | オフラインのホストの IP アドレスかホスト名 | `192.168.1.20` |
> | `${OFFLINE_USER}` | オフラインのホストでログインするユーザー（既定はオンラインのホストのユーザー名。違えば直す） | `${USER}` |
>
> 出力例・ログ・表の中の値は `<OFFLINE_HOST>` / `<OFFLINE_USER>` / `<VM_IP>` / `<USER>` のプレースホルダで書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

- **状態（2026-10-11）**: Linux 2 台の Hyper-V VM で実施手順 1〜3・dnf の任意節・トンネルを閉じる手順 1〜3 を通した（2026-10-11、Codex）
  - loopback の待ち受け、GitHub 200、dnf のキャッシュ作成、転送終了後の通信失敗を確認。実機・aarch64・異常系は今回未実施
  - 詳細は[今回の付録](#付録-hyper-v-の-vm-で通した記録2026-10-11)

### 実施前の状態

オフラインのホスト（コンテナ）で、手順 1 の前に確かめた状態（[homebrew-offline.md の実施前の状態](homebrew-offline.md#実施前の状態)と同じ）:

| 項目 | 状態 |
|---|---|
| 経路 | `ip route` は、つないだネットワークの 1 行だけ（`default` の行が無い） |
| 名前解決 | `getent hosts github.com` は何も返さず、終了コード 2 |
| 外への接続 | `curl https://github.com` は `curl: (6) Could not resolve host: github.com`。github.com の IP アドレスを直接指定しても `curl: (7) Failed to connect to … port 443 after 0 ms: Could not connect to server` |
| sshd | `sshd -T` は `allowtcpforwarding yes`・`gatewayports no`・`disableforwarding no`・`permitlisten any`（AlmaLinux の既定） |
| `/etc/dnf/dnf.conf` | 既定のまま（`[main]` と 5 つの設定。`proxy` の行は無い） |

### 付録: コンテナでの検証記録（2026-09-30）

**環境**: Ubuntu 24.04 / x86_64 のクラウドホスト上の Docker 29.3.1 で、`quay.io/almalinuxorg/almalinux:10`（`sha256:83220192…c4c8`、AlmaLinux 10.2）から 2 つのコンテナを立てた。作りは [homebrew-offline.md の付録](homebrew-offline.md#付録-コンテナでの検証記録2026-09-29)と同じ（そちらのイメージは `docker.io/library/almalinux:10`）。実機で加えた変更は無い。

**手順書の外で行った準備**（検証環境の都合）:

- ネットワークを 2 つ作った。外に出られない `docker network create --internal` のもの（オフラインのホスト用）と、ふつうのもの。オンラインのホストのコンテナは両方につないだ
- オフラインのホスト: ふつうのネットワークにつないでいる間に `openssh-server`・`sudo`・`iproute` を入れて `ssh-keygen -A` を実行し、`--internal` のネットワークだけにつなぎ替えてから `sshd -D -e` を動かした（systemd 無し）。ユーザー（uid 1000、NOPASSWD の sudo）と 2 人目（uid 1001）を作った。`git`・`file`・`procps-ng` は入れていない
- オンラインのホスト: `openssh-clients` を入れ、同じ名前のユーザーで鍵を作り、公開鍵をオフラインのホストの `authorized_keys` に置いた（鍵認証）
- このクラウドのホストの外向きの通信は、TLS を署名し直すゲートウェイを通る。その CA を、両方のコンテナの信頼ストアに足した（実際のホストでは要らない）

**流し方**: この文書と [homebrew-offline.md](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/homebrew-offline.md)・[homebrew.md](https://github.com/ryo-aoki-pc/setup-notes/blob/83ad79eb96222754ee5ae8ff17c1fa5a027f4cb0/docs/homebrew.md#実施手順) の bash のブロックをファイルから抜き出し、`docker exec -it` で開いたオンラインのホストの対話の bash（擬似端末）に、1 ブロックずつ 1 行ごとに送った（ブラケットペースト無し）。

- 手順 1 の `OFFLINE_HOST` は、コンテナの名前に書き換えた
- ホスト鍵の確認には `yes`、インストーラの `RETURN` と brew の `[y/n]` には、表示が出てから Enter と `y` を送った

| 手順 | 結果 |
|---|---|
| 実施前 | オフラインのホストは `ip route` が 1 行だけ、`getent hosts github.com` は終了コード 2、`curl https://github.com` は `Could not resolve host`。`/etc/dnf/dnf.conf` に `proxy` の行は無い |
| 1 | `OFFLINE_HOST = <OFFLINE_HOST>` / `OFFLINE_USER = <USER>` |
| 2 | ホスト鍵の確認に `yes` → `Warning: Permanently added '<OFFLINE_HOST>' (ED25519) to the list of known hosts.` の後にログインした |
| 3 | `127.0.0.1:1080` の 1 行と `200` |
| homebrew-offline.md 1 | `200` / `301` / `200` / `401`。`rpm -q` は curl だけ入っていた |
| dnf の節（homebrew-offline.md 2） | `2:proxy=socks5h://127.0.0.1:1080`、`Metadata cache created.` |
| homebrew-offline.md 3 | homebrew.md の手順 1 で 73 パッケージを導入し 4 つを更新（`Complete!`）、手順 2 で `Press RETURN/ENTER to continue` に Enter → `==> Installation successful!`、手順 3・4 で `Homebrew 7.0.7`・`Branch: stable`・`HOMEBREW_PREFIX: /home/linuxbrew/.linuxbrew` |
| homebrew-offline.md 4 | `Would install 1 formula:`（`jq 1.8.2`）と依存の `oniguruma` の後に `[y/n]`。`y` で 2 つのボトルがトンネル越しに降りた |
| トンネルを閉じる 1〜3 | `Connection to <OFFLINE_HOST> closed.` → 転送無しでログイン → `ss` は無出力、`curl: (6) Could not resolve host: github.com` と `届かない（期待どおり）` |
| homebrew-offline.md 6 | `jq 1.8.2`、`/home/linuxbrew/.linuxbrew/bin/jq`、`offline` |
| homebrew-offline.md の更新 | 手順 2・3 でトンネルを張り直し（`200`）、homebrew.md の更新は `Already up-to-date.`、`brew outdated` と `brew upgrade` は無出力。トンネルを閉じる節の手順 1 で閉じた |
| ロールバック（homebrew-offline.md とこの文書） | トンネル無しのシェルで流した。`brew uninstall jq` が `oniguruma` も消し（`==> Autoremoving 1 unneeded formula:`）、`brew autoremove` と `brew list --versions` は無出力。この文書のロールバックは `0` で、`/etc/dnf/dnf.conf` は元の 6 行に戻った |

- 最初の試みでは、検証の道具が、ブロックを送った直後に確かめのための行（`echo`）を続けて打っていた。dnf の節の `sudo dnf makecache` がこの打ち込んだ行を読んで捨て、`echo` は実行されなかった
  - ブロックの中の行は `if … fi` で先に読まれていたので、失われなかった（[README の記法](../../README.md#記法)の `sudo` の規則と同じ現象）
  - 確かめの方法を変え、新しいコンテナで最初から流し直したのが上の表

#### 未確認事項

- Linux のオンラインのホストの実機（x86_64 の PC・Raspberry Pi 5）
- aarch64、SELinux が Enforcing のオフラインのホスト、IPv6
- パスワード認証でのログイン（検証は鍵認証）、macOS の ssh
- この日の流し直しでは、1080 番がふさがっているとき・`AllowTcpForwarding no`・接続の共有・2 人目のユーザーは試していない（2026-09-29 の [homebrew-offline.md の付録](homebrew-offline.md#付録-コンテナでの検証記録2026-09-29)による）

---

### 付録: VM での検証記録（2026-10-06）

**環境**: [クリーンインストールからの検証記録](../almalinux-vm-verification.md)のオフライン用 VM。公式 ISO から Workstation を入れた状態から始め、x86_64、SELinux Enforcing、firewalld 有効。本文のブロックを SSH の擬似端末で実行した。

- Windows の OpenSSH から、既定の経路を持たない AlmaLinux 10.2 の VM にリバース SOCKS 転送を張った。手順 2 の Windows の形に、検証用鍵・NAT の SSH ポート・ホスト鍵の固定・`-N` を足した。転送を保持する接続と、手順 3 以降の対話シェルを別にした検証で、パスワード認証は使っていない。
- オフライン状態の準備は手順書の外。NetworkManager の NAT 側の接続に `ipv4.never-default=yes` と `ipv6.method=disabled` を設定し、再起動した。IPv4 / IPv6 とも既定経路が無く、プロキシ無しで IP を指定した GitHub の HTTPS は終了 7。外の名前も引けなかった。
- 手順 3 で `127.0.0.1:1080` と `[::1]:1080` の待ち受け、SOCKS 経由の GitHub の 200 を確認。dnf の任意節を本文のまま通し、メタデータ取得と Node.js の導入も成功した。SELinux Enforcing のまま sshd を使った。
- 取得中も直接通信が失敗することを再確認した。転送を保持した SSH を終了してログインし直し、トンネルを閉じる節の手順 3 を通した。1080 の待ち受けとプロキシ環境変数は無く、curl は `届かない（期待どおり）` になった。
- Linux / macOS 発、パスワード認証、IPv6 の転送先、長い取得中の切断、ロールバックは今回通していない。IPv6 を無効にした試験と、IPv6 の接続の検証を区別する。

---

### 付録: 現行版を新規 VM で再検証（2026-10-06）

**対象**: `setup-notes` の `5da3478` 版。公式 ISO の Workstation クリーンインストールの `clean-install` スナップショットから、新規の `alma10-current-20261006-offline` を作った。AlmaLinux 10.2 / x86_64 / SELinux Enforcing / firewalld 有効。共通 bash は `3d5323e` を新規導入した。以前の付録と別の試験で、現行ブロックを SSH の擬似端末で順に実行した。

- 検証用の準備として NAT の NetworkManager 接続に `ipv4.never-default=yes` / `ipv6.method=disabled` を設定した。直接の外向き通信と名前解決は失敗し、IPv4 / IPv6 とも既定経路が無い状態から始めた。
- Windows の OpenSSH から本文の手順 2 の形で逆向きの SOCKS を張った。検証用鍵・SSH の NAT ポート・ホスト鍵の固定・`-N` を補い、転送を保持する接続と手順 3 以降の擬似端末を分けた。手順 3、dnf の任意節、トンネルを閉じる節を通し、待ち受けと HTTP 応答、メタデータ取得、転送終了後の待ち受け無し・外への接続失敗を確認した。
- Homebrew / Node.js / npm / Mason の取得を通した後、転送無しの再ログインで curl は終了 6 と `届かない（期待どおり）`。OS 再起動後も既定経路は復活しなかった。ロールバックのブロックで dnf のプロキシ行を撤去し、`grep -c` は `0`（終了 1）になった。
- Linux / macOS 発のオンラインホスト、パスワード認証、IPv6 の通信、長い取得中の切断、1080 使用中や sshd 転送禁止などの異常系は、この再検証では行っていない。

### 手順中の実測・検証状況の記録

- **転送中は、オフラインのホストのどのユーザーもプロキシを使える**: 待ち受けは loopback だけだが、ユーザーを区別しない。検証では、2 人目のユーザーの `curl` も `200` を返した。使い終わったら[トンネルを閉じる](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/ssh-socks-tunnel.md#トンネルを閉じる)

### 手順中の実測・検証状況の記録

- **Linux 発の検証では SELinux Enforcing を確かめていない**: 検証のコンテナには SELinux が無い。Windows 発で接続した Atomic Desktop の VM は Enforcing で、待ち受けは拒まれなかった

### 手順中の実測・検証状況の記録

- **ssh が切れると、トンネルも消える**: 取得の途中なら失敗するはず（確かめていない）。そのときは手順 2 から張り直して、同じコマンドを貼り直す

### 選択した方針

| **オンラインのホストから `ssh -R 1080`（逆向きの動的転送）** | オンラインのホストからオフラインのホストへ ssh でログインできること。どちらのホストにも追加のソフトは要らない | **採用。** オフラインのホストで curl・git・dnf・podman が外に届く。オフラインのホストが自分で取るので、2 台のアーキが違ってもよい（ただし x86_64 でしか確かめていない） |

| オフラインのホストから `ssh -D 1080` | オフラインのホストからオンラインのホストへ ssh でログインできること（オンラインのホストで sshd を動かす） | 不採用。ssh の向きが逆のときの代わりになる形だが、確かめていない |

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
- R6 は 2 回に分かれた。C14 は npm の前提導入中にオフライン VM が応答しなくなり中止。C15 はメモリを 2048 MB から 3072 MB にし、GNOME にログインせず続けたところ再発しなかった。原因は分かっていない（[npm の記録](npm-offline.md#付録-hyper-v-の-vm-で通した記録2026-10-11)）
- C14 のログイン後の PNG は、`screens/online/login-20261011-113934-3-after.png` がアクティビティ画面、`screens/offline/login-20261011-114023-3-after.png` がようこそ画面。本文の操作は GNOME の端末への貼り付けではない

### 手順ごとの結果

| 節・手順 | 結果 | 根拠・確認 |
|---|---|---|
| 実施手順 1 | 通した | C14 `online/session/steps.jsonl` seq 1・2、`online/session/after-confirm/0002-実施手順-1.txt`。変数を読み戻した |
| 実施手順 2 | 通した | 同 seq 3〜5、`online/session/session-001.raw`。ホスト鍵確認とパスワード入力後にオフラインのプロンプト |
| 実施手順 3 | 通した | 同 seq 6、`online/session/after-confirm/0006-実施手順-3.txt`。127.0.0.1 と [::1] の 1080、GitHub 200 |
| dnf にもトンネルを使わせる（任意）1 | 通した | 同 seq 7・8、`online/session/after-confirm/0007-dnf_にもトンネルを使わせる（任意）-1.txt`。proxy 行と日本語のキャッシュ作成完了 |
| トンネルを閉じる 1〜3 | 通した | 同 seq 18〜21、`online/session/after-confirm/0021-トンネルを閉じる-3.txt`。転送無しで再ログインし、ss 無出力・curl 終了 6 |
| Homebrew 更新・npm 前提の張り直し | 通した | C14 同 seq 24〜26・30〜32、C15 `online/session/steps.jsonl` seq 1〜5・20〜22、`online/session/after-confirm/0005-実施手順-3.txt`・`0022-実施手順-3.txt`。loopback と 200 |
| extra ロールバック | 未実施 | C14・C15 の steps に実施記録無し。dnf proxy 行は C15 にも残った |

### 通らなかった手順と見立て

- この文書の実施範囲で通らなかった手順は無い。入れ子 SSH のためドライバは foreground=ssh / waiting と表示したが、ゲストのプロンプトと確認出力で完了を判定した
- C14 の npm 前提中の応答喪失を、SSH の貼り方や Hyper-V による障害とは断定していない

### 指摘と状態・手順書を直した所

| 指摘 | 状態 | 直した所と根拠 |
|---|---|---|
| dnf の確認文が英語だけ | 直した（文言） | 任意節の手順 1 に日本語の `メタデータキャッシュを作成しました。` を併記。C14 の `0007-dnf_にもトンネルを使わせる（任意）-1.txt` で確認。ブロックは変更無し |
| 入れ子 SSH のドライバの状態表示 | 未対応（道具） | 完了の出力とプロセス名による表示を区別。手順書の実行失敗とは扱わない |

### 確かめていないこと

- 実機・aarch64・macOS 発・IPv6 の外向き通信・転送の異常系・extra のロールバックは今回未実施
- 従来の Windows 発と今回の Linux 発は別の結果。GNOME 端末への貼り付け・フォント・IME は確認していない


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
| SSH の SOCKS トンネル: 実施手順 / 1 | 通した | seq2–3。今回の `<OFFLINE_HOST>` / `<USER>` を読み戻し |
| 同じ項 / 2 | 初回は接続終了、再試行は通した | seq4–7。host-key確認後に接続終了、原因未断定。再試行でpassword欄、opaque工具で入力、offlineプロンプト到達 |
| 同じ項 / 3 | 通した | seq8。待受のlocal addressは127.0.0.1/[::1]のみ、GitHub200。ssの対向addressのwildcardを外部待受と数えない |
| dnf にもトンネルを使わせる（任意） / 1 | 既存設定で追記を飛ばした | seq9。proxy既存の原文ガード。補助seq20のmakecacheでメタデータキャッシュ作成完了、重複追記なし |
| トンネルを閉じる / 1–3 | 通した | seq44–47。offline exit→online→転送なしSSH→offline、1080無出力/curl終了6 |
| 更新時の張り直し・閉鎖 | 通した | seq58–64、65–70/80。各トンネルはloopback/200。閉鎖後の補助offline seq4/6で1080なし、実外部IPv4直接curl000/終了7 |

- 永続NM設定はnever-default/ignore-auto-dns、DNS空、IPv6 disabled。再起動後もdefault IPv4/IPv6経路なし。DNS失敗だけでなく、onlineで引いた実外部IPv4へのroute unreachableとproxy-offの固定IP curl失敗を確認した
- 入れ子SSHはdriverがforeground=ssh/waitingを返す。各実プロンプトを確認してforceを使い、driverの終了0だけで成否を決めていない
- 全セッションを閉じ、担当2VMは通常停止でOff。`after-OFFLINE-FULL-continuation-20261012` を新規保存。Hard・削除・復元・既存snapshot上書きなし
- 異常系の転送、実機、aarch64/macOS発、IPv6の外部到達、extraロールバックは今回未実施。旧応答喪失の原因は未確定のまま
