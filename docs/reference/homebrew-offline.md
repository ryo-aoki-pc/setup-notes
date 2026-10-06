# Homebrew をインターネットに出られないホストで使う手順（AlmaLinux 10 / ssh -R の SOCKS プロキシ）の参考資料

[手順書](../homebrew-offline.md)

## 補足

### 選択した方針

[この節の検証記録](../verification/homebrew-offline.md#選択した方針)

| 経路 | 要るもの | 採否 |
|---|---|---|
| **ssh の SOCKS トンネル（[ssh-socks-tunnel.md](../ssh-socks-tunnel.md) の `ssh -R 1080`）で、オフラインのホストから取得する** | オンラインのホストからオフラインのホストへ ssh でログインできること。どちらのホストにも追加のソフトは要らない | **採用。** オフラインのホストで curl・git・brew・dnf がそのまま外に届き、homebrew.md とほかの Homebrew 系の手順書を変えずに貼れる。オフラインのホストが自分のアーキのボトルを取るので、2 台のアーキが違ってもよい。トンネルの張り方どうしの比較（`-D`・HTTP プロキシ）は、同書の[選択した方針](ssh-socks-tunnel.md#選択した方針) |
| `/home/linuxbrew/.linuxbrew` を tar にして運ぶ | 同じ OS・同じアーキのホストで Homebrew と formula を入れる。上げるたびに作り直して運ぶ | 本書では扱わない（ネットワークで届かないときの方法） |
| `brew fetch` でボトルだけを運ぶ | Homebrew 本体（git のリポジトリと portable-ruby）と、formula の API の JSON も要る | 本書では扱わない |

- **homebrew.md を、リードで前提として挙げるのではなく、手順 3 にした**: ほかの Homebrew 系の手順書と違い、トンネルを張ったシェルの中で貼る必要があるため
- **トンネルの手順は、ssh-socks-tunnel.md を前提にした**: [npm-offline.md](../npm-offline.md) でも、同じトンネルを使う
  - [virtualbox-guest-bootc.md](../virtualbox-guest-bootc.md#ホストオンリーアダプターだけの-vm-でビルドする任意) の現行手順は、オンラインのホストでビルドしたイメージを VM に運ぶ方式で、トンネルは使わない

### 参照

- [ssh の SOCKS トンネル](../ssh-socks-tunnel.md) — 前提の手順書（トンネルの張り方・dnf の設定・閉じ方。ssh・curl・git・dnf の参照もそちら）
- [Homebrew — Manpage の USING HOMEBREW BEHIND A PROXY](https://docs.brew.sh/Manpage#using-homebrew-behind-a-proxy) — Homebrew が読むプロキシの環境変数
- [Homebrew](../homebrew.md) — 手順 3 で貼る Homebrew 本体の導入手順

---
