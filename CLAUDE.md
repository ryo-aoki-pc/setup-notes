# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリは何か

実機で検証した構築・設定手順の記録（日本語）。成果物は `docs/*.md` の手順書で、`scripts/` はその手順書を実行可能にしたもの。「動いた手順」だけでなく**なぜ失敗したか・どう切り分けたか**を残すのが目的なので、検証していないことを「動く」と書かない。手順書の冒頭にある **状態** 行（実機で本実行済み / スタブ / network namespace のみ など）は、検証範囲が変わるたびに更新する。

ビルド・テストフレームワークは無い。ドキュメントとコミットメッセージは日本語で書く。

## よく使うコマンド

```bash
# シェルスクリプトの静的検査（手順書の付録で「警告なし」を記録している）
bash -n scripts/wireguard/wg-vpn.sh
shellcheck -x scripts/wireguard/wg-vpn.sh

# wg-vpn.sh を変更せずに実行予定を見る（root 不要なサブコマンドもある）
sudo scripts/wireguard/wg-vpn.sh -e scripts/wireguard/site.env --dry-run apply A
scripts/wireguard/wg-vpn.sh --help

# 構成図の再生成（docs/diagrams/*.diag → *.svg）。nwdiag を直接呼ばない
sudo dnf install -y google-noto-sans-cjk-vf-fonts
python3 -m pip install --user nwdiag
python3 scripts/render-diagrams.py          # 別フォントは WG_DIAG_FONT=... で指定
```

`wg-vpn.sh` の本実行を実機の設定に触れずに試す方法は、`docs/wireguard.md` の「付録: スクリプトの検証」にある。`unshare -Urm` で uid 0 の user namespace を作り、`/etc/wireguard`・`/etc/sysctl.d`・`/etc/firewalld` に tmpfs を重ね、`firewall-cmd` / `systemctl` / `ip` などのスタブを `PATH` の先頭に置く。`wg genkey` / `wg pubkey` はカーネルモジュール無しで本物が使える。

## 構成

- `README.md` — 手順書を選ぶための簡潔な一覧と記法。詳しい知見は各手順書の「補足」に置き、手順書を足す・対象環境を変えるときは一覧も更新する
- `docs/gnome-remote-desktop.md` — 変数ブロックを冒頭に置き、以降のコマンドをそのまま貼れる形式
- `docs/wireguard.md` — `wg-vpn.sh` を主役にした手順書。`site.env` に値を書き、`keygen` → `apply` → `router` → `client add` の順
- `docs/wezterm-nightly.md` — 公式 COPR の EL9 向けビルドを chroot 明示で EL10 に入れる手順。採用しなかった経路（GitHub rpm / AppImage / Flathub / ソース）の実測も補足に残す
- `docs/samba.md` — `[homes]` 共有でホームディレクトリを公開する手順書。gnome-remote-desktop.md と同じ変数ブロック方式。実機（拠点 B の WG ホスト）で公開を継続中
- `docs/wireguard-road-warrior.md` — 外出先の AlmaLinux 10 PC を WG クライアントにする手順書。鍵は PC 側で生成し、ホストの `client add --pubkey` → `client show` の conf を `nmcli connection import` で取り込む。samba.md と同じ変数ブロック方式。未検証（NetworkManager の挙動で「要確認」と付けた項目は実機の結果で更新する）
- `docs/diagrams/*.diag` — nwdiag の原本。`*.svg` は生成物なので直接編集しない
- `scripts/render-diagrams.py` — nwdiag 3.0.0 と Pillow 10 の非互換を shim で埋め、SVG に背景・CJK フォント・viewBox 幅の後処理をする
- `scripts/wireguard/wg-vpn.sh` — 約 1,250 行の bash。`site.env.example` / `clients.list.example` が入力ファイルの形式。実物の `site.env` / `clients.list` / バックアップは `.gitignore` 済み

### 手順書の構造

両手順書は同じ骨格で書いてある。新しい手順書もこれに合わせる。

1. タイトルの直後に `## 実施手順` と番号付きの手順を置く。**前半は読者が実行する操作と、その場で必要な短い注意だけ**にし、理由・実測・落とし穴は書かない
2. 環境固有の値は手順冒頭の変数ブロックまたは `site.env` だけで設定する（`${SERVER_IP}` 形式。値の置き場所は手順書ごとに 1 か所）
3. 動作確認、任意設定、`## ロールバック`（または「全部消す」）までを前半に置く
4. `## 補足` に「対象と検証環境」「実施前の状態」「選択した方針」「注意点」「参照」「付録（検証記録）」を置く。目的、環境表、変数の詳しい説明を含む背景説明はすべてここへ

出力例・ログ・表の中の値は `<HOSTNAME>` / `<SERVER_IP>` などのプレースホルダで書き、実測出力は変数に置き換えない。`<...>` を含むコマンドは bash のコードブロックに置かず、読者が値を入れるブロックは先頭で変数が空なら中断させる（README「記法の約束」）。手順書のコードブロックは検証目的でも実機で機械的に実行しない。コマンドは実際に実行したものを載せる。パスワード・鍵・トークンは private でも書かない。

### wg-vpn.sh の設計

- **入力は `site.env` 1 ファイル**。両拠点に同じファイルを置く。`select_site A|B` が `SITE_A_*` / `SITE_B_*` から `MY_*` / `PEER_*` を組み立てるので、以降の処理は拠点を意識しない。このホストの LAN 側 IP が `WG_x_LAN_IP` と一致しなければ何も変更せずに止まる
- **変更を伴うコマンドはすべて `run()` を通す**。`--dry-run` はこれで実現しているので、新しい副作用も必ず `run` 経由にする
- **検査してから変更する**。`validate_addresses`（Python の `ipaddress` で形式・重複・包含関係を検査）などの検査に 1 つでも落ちたら何も書かない
- `apply` は冪等。`clients.list` の登録簿から毎回 conf を組み立て直し、firewalld は存在確認してから追加し、最後は常に `systemctl restart`（reload では経路が変わらないため）。旧レイアウト（専用ゾーン + policy）が残っていれば policy → ゾーンの順で消す（逆順だと firewalld の設定が壊れる）
- `PrivateKey` は conf に直接書く。`PostUp` で読み込む方式は reload で鍵が消える
- `firewall-cmd --query-policy` は 2.4.3 に存在しない。存在確認は `--info-policy` の終了コードで行う

スクリプトの挙動を変えたら、`docs/wireguard.md` の「スクリプトの動作」節と `--help`（ファイル冒頭コメントを `usage()` がそのまま表示する）、必要なら README の知見リストも合わせて直す。
