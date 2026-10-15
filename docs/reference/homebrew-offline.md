# Homebrew のオフライン導入の参考資料

[AlmaLinux 10 の「Homebrew のオフライン導入」](../almalinux-setup.md#homebrew-のオフライン導入)・[ロールバックと注意点](../extra/homebrew-offline.md)

## 補足

### Homebrew のオフライン導入 / 手順 1: 補足: ghcr.io の 401

- ghcr.io が `401` になるのは、トークンが無いため

### Homebrew のオフライン導入 / 手順 2: 補足: dnf の設定

- AlmaLinux 10 の初期設定の「Homebrew」の手順 1 の dnf が、トンネルを通るようになる
- 足した行は、[ロールバック](../extra/homebrew-offline.md#ロールバック)のリードのとおり、ssh-socks-tunnel.md のロールバックで消す

### Homebrew のオフライン導入 / 手順 3: 補足: Homebrew の導入とトンネル

- AlmaLinux 10 の初期設定の「Homebrew」の手順 2 のインストーラも、中で使う curl と git が `ALL_PROXY` を読むので、そのまま通る
- 同書の「Homebrew」の手順 3 を共通の bash 設定を入れてあるシェルで貼るのは、`brew shellenv` を共通設定が実行するため

- GNOME で日本語入力を使う PC は、同書の「Homebrew」の手順 4 も通す。このオフライン経路での実行は未確認。

### 選択した方針

[この節の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/homebrew-offline.md#選択した方針)

| 経路 | 要るもの | 採否 |
|---|---|---|
| **ssh の SOCKS トンネル（[AlmaLinux 10 の「SSH の SOCKS トンネル」](../almalinux-setup.md#ssh-の-socks-トンネル) の `ssh -R 1080`）で、オフラインのホストから取得する** | オンラインのホストからオフラインのホストへ ssh でログインできること。どちらのホストにも追加のソフトは要らない | **採用。** オフラインのホストで curl・git・brew・dnf がそのまま外に届き、AlmaLinux 10 の初期設定の Homebrew の手順とほかの Homebrew 系の手順書を変えずに貼れる。オフラインのホストが自分のアーキのボトルを取るので、2 台のアーキが違ってもよい。トンネルの張り方どうしの比較（`-D`・HTTP プロキシ）は、SOCKS トンネルの参考資料の[選択した方針](ssh-socks-tunnel.md#選択した方針) |
| `/home/linuxbrew/.linuxbrew` を tar にして運ぶ | 同じ OS・同じアーキのホストで Homebrew と formula を入れる。上げるたびに作り直して運ぶ | 本書では扱わない（ネットワークで届かないときの方法） |
| `brew fetch` でボトルだけを運ぶ | Homebrew 本体（git のリポジトリと portable-ruby）と、formula の API の JSON も要る | 本書では扱わない |

- **Homebrew の導入（AlmaLinux 10 の初期設定の「Homebrew」の手順 1〜3）を、リードで前提として挙げるのではなく、手順 3 にした**: ほかの Homebrew 系の手順書と違い、トンネルを張ったシェルの中で貼る必要があるため
- **トンネルの手順は、AlmaLinux 10 の「SSH の SOCKS トンネル」を前提にした**: [同書の「npm のオフライン導入」](../almalinux-setup.md#npm-のオフライン導入) でも、同じトンネルを使う
  - [仮想マシンのセットアップの「VirtualBox の bootc ゲスト: ホストオンリーアダプターだけの VM でビルドする」](../virtual-machines.md#virtualbox-の-bootc-ゲスト-ホストオンリーアダプターだけの-vm-でビルドする) の現行手順は、オンラインのホストでビルドしたイメージを VM に運ぶ方式で、トンネルは使わない

### 参照

- [ssh の SOCKS トンネル](../almalinux-setup.md#ssh-の-socks-トンネル) — 前提の手順書（トンネルの張り方・dnf の設定・閉じ方。ssh・curl・git・dnf の参照もそちら）
- [Homebrew — Manpage の USING HOMEBREW BEHIND A PROXY](https://docs.brew.sh/Manpage#using-homebrew-behind-a-proxy) — Homebrew が読むプロキシの環境変数
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 手順 3 で貼る Homebrew 本体の導入手順（「Homebrew」の手順 1〜3）

---
