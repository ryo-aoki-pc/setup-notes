# ssh の SOCKS トンネル手順（AlmaLinux 10 / インターネットに出られないホストから ssh -R で外に出る）の参考資料

[手順書](../ssh-socks-tunnel.md)

## 補足

### 実施手順 / 手順 1: 補足: 変数について

- オフラインのホストには変数が無い。ポート（1080）は変える必要が無いので、変数にせずコマンドに直接書いた（変えるときは手順 2 の補足）
- `OFFLINE_USER` は、トンネルを使う手順書が決める。[homebrew-offline.md](../homebrew-offline.md) なら、Homebrew を使うユーザー（root ではログインしない）

### 選択した方針

[この節の検証記録](../verification/ssh-socks-tunnel.md#選択した方針)

| 経路 | 要るもの | 採否 |
|---|---|---|
| **オンラインのホストから `ssh -R 1080`（逆向きの動的転送）** | オンラインのホストからオフラインのホストへ ssh でログインできること。どちらのホストにも追加のソフトは要らない | **採用。** オフラインのホストで curl・git・dnf・podman が外に届く。オフラインのホストが自分で取るので、2 台のアーキが違ってもよい |
| オフラインのホストから `ssh -D 1080` | オフラインのホストからオンラインのホストへ ssh でログインできること（オンラインのホストで sshd を動かす） | 不採用。ssh の向きが逆のときの代わりになる形だ |
| オンラインのホストに HTTP プロキシ（squid など）を建てる | オンラインのホストにデーモン、待ち受けのポート、アクセス制御 | 不採用。ssh の転送で足りる |

- **`ALL_PROXY` を `~/.bashrc` に書かない**: トンネルがあるのは手順 2 の ssh のセッションの間だけなので、手順 3 でそのシェルにだけ入れる
- **dnf には、`sudo` に環境変数を渡す（`sudo --preserve-env=ALL_PROXY`）のではなく、設定ファイルで渡す**: ほかの手順書の `sudo dnf install` を、書き換えずに貼れるようにするため
- **独立した手順書にした**: [homebrew-offline.md](../homebrew-offline.md) と [virtualbox-guest-bootc.md](../virtualbox-guest-bootc.md) のホストオンリーアダプターの節で、同じトンネルの張り方・確かめ方・閉じ方が重なっていたため（今は homebrew-offline.md と npm-offline.md が使う）

### 参照

- [OpenSSH 7.6 のリリースノート](https://www.openssh.org/txt/release-7.6) — `ssh -R` の逆向きの動的転送（SOCKS）が入った版。クライアントだけで実装されている（オフラインのホストの sshd の版は問わない）
- [ssh(1)](https://man.openbsd.org/ssh) — `-R`、`-o ExitOnForwardFailure`、`-o ControlPath`
- [sshd_config(5)](https://man.openbsd.org/sshd_config) — `AllowTcpForwarding`、`GatewayPorts`、`PermitListen`、`DisableForwarding`
- [curl(1) の ENVIRONMENT](https://curl.se/docs/manpage.html#ENVIRONMENT) — `ALL_PROXY` と `socks5h://`
- [git-config(1) の http.proxy](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpproxy) — git がプロキシを読む順番
- `man dnf.conf` — `proxy`

---
