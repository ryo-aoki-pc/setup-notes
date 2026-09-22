# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリは何か

実機で検証した構築・設定手順の記録（日本語）。成果物は `docs/*.md` の手順書で、`scripts/` はその手順書を実行可能にしたもの。「動いた手順」だけでなく**なぜ失敗したか・どう切り分けたか**を残すのが目的なので、検証していないことを「動く」と書かない。手順書の冒頭にある **状態** 行（実機で本実行済み / コンテナのみ / スタブ / network namespace のみ など）は、検証範囲が変わるたびに更新する。

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
- `docs/firefox.md` — Mozilla 公式 RPM リポジトリ（`packages.mozilla.org/rpm/firefox`）で最新版の Firefox を入れる手順書。AppStream の ESR 140 から `dnf install` 1 本で載せ替える。実機で本実行済み、手順は AlmaLinux 10 コンテナで再実行して確認
- `docs/claude-code.md` — 公式 dnf リポジトリ（`downloads.claude.ai/claude-code/rpm/stable`）から Claude Code を入れる手順書。Node.js 不要。実機で本実行済み（認証も済み）、手順 1〜3 はコンテナで再実行
- `docs/gh.md` — 公式 dnf リポジトリ（`cli.github.com/packages/rpm`）から gh を入れる手順書。EPEL 版は 2.97.0 と古い。実機で本実行済み、手順 1〜3 はコンテナで再実行
- `docs/homebrew.md` — Homebrew 本体を入れる手順書。以降の Homebrew 系 9 本の前提で、各手順書は `## 実施手順` のリード文からここへ誘導し、手順 1 は各ツールの導入から始まる。インストーラの `Next steps` の実測と `brew` の基本操作もここに集約した。実機で本実行済み（2026-09-20）、手順はコンテナで再実行
- `docs/yazi.md` — yazi を Homebrew で入れる手順書。COPR `lihaohong/yazi` を実機で一度入れて外した経緯と、プレビュー依存（ffmpeg など）が EL10 に揃わないことを補足に残す。`y()` シェル関数まで含む
- `docs/lazygit.md` — lazygit を Homebrew で入れる手順書。COPR（`dejan` / `atim`）は `epel-10-aarch64` の repomd が 403 で入らないことを実機とコンテナの両方で確認して不採用にしている
- `docs/neovim.md` — Neovim を Homebrew で入れる手順書（EPEL は 0.10.1 と古い）。`:checkhealth` の読み方と、`sudo nvim` が使えない理由を補足に置く
- `docs/zoxide.md` — zoxide を Homebrew で入れる手順書。EPEL にも AppStream にも RPM が無い。`~/.bashrc` の `eval "$(zoxide init bash)"` が本体で、`--cmd cd` の影響範囲も補足に書く
- `docs/bat.md` — bat を Homebrew で入れる手順書。EPEL は 0.24.0 で古い。`alias cat=bat` は勧めず、`~/.config/bat/config` と `MANPAGER` の使い方だけ案内する。**コンテナのみで検証（実機未導入）**
- `docs/eza.md` — eza を Homebrew で入れる手順書。EPEL にも AppStream にも RPM が無い（`exa` も無い）。`ls` は置き換えず `ll` / `la` / `lt` を足す形にしてある。非対話シェルでは `type -t` がエイリアスを見つけられないことも補足に書く。**コンテナのみで検証**
- `docs/git-delta.md` — git の差分表示を delta にする手順書。formula 名は `git-delta`、バイナリは `delta`。設定は `git config --global` で `~/.gitconfig` に書く（git がキー名を小文字に正規化するので読み戻しの正規表現に注意）。lazygit の `git.paging` 連携は任意節。**コンテナのみで検証**
- `docs/gdu.md` — gdu を Homebrew で入れる手順書。**brew 版の実行ファイルは `gdu-go`**（coreutils との衝突回避）。EPEL には 5.32.0 の `gdu` がある。実機には同じ brew 版 5.37.0 が 2026-09-21 から入っているが、本書の通し検証はコンテナのみ
- `docs/btop.md` — btop を EPEL の dnf で入れる手順書。**このリポジトリで唯一 Homebrew を選ばなかったツール**（EPEL と Homebrew がどちらも 1.4.7）。手順 1 は EPEL の有効化で、鍵は `epel-release` が置くローカルファイルから入る。**コンテナのみで検証**
- `docs/starship.md` — プロンプトを starship にする手順書。`~/.bashrc` の `eval "$(starship init bash)"` が本体。zoxide の初期化より後ろに置き、WezTerm のシェル統合が `PS1` に足す OSC 133 の A/B マーカーは starship に上書きされる（init スクリプトを読んだ上での推定、実挙動は未検証）。**コンテナのみで検証**
- `docs/diagrams/*.diag` — nwdiag の原本。`*.svg` は生成物なので直接編集しない
- `scripts/render-diagrams.py` — nwdiag 3.0.0 と Pillow 10 の非互換を shim で埋め、SVG に背景・CJK フォント・viewBox 幅の後処理をする
- `scripts/wireguard/wg-vpn.sh` — 約 1,250 行の bash。`site.env.example` / `clients.list.example` が入力ファイルの形式。実物の `site.env` / `clients.list` / バックアップは `.gitignore` 済み

### 手順書の構造

各手順書は同じ骨格で書いてある。新しい手順書もこれに合わせる。

1. タイトルの直後に `## 実施手順` と番号付きの手順を置く。**前半は読者が実行する操作と、その場で必要な短い注意だけ**にし、理由・実測・落とし穴は書かない
2. 環境固有の値は手順冒頭の変数ブロックまたは `site.env` だけで設定する（`${SERVER_IP}` 形式。値の置き場所は手順書ごとに 1 か所）。**変更が必須の変数は 1 変数ずつのコードブロックに分け、変更が任意の変数（既定のままでよい・自動で入る・固定）は 1 つのブロックにまとめて必須ブロックの後に置く。** シェルに貼って編集する手間を減らすため
3. 動作確認、任意設定、`## ロールバック`（または「全部消す」）までを前半に置く
4. `## 補足` に「対象と検証環境」「実施前の状態」「選択した方針」「注意点」「参照」「付録（検証記録）」を置く。目的、環境表、変数の詳しい説明を含む背景説明はすべてここへ
5. **複数の手順書が共有する前提は独立した手順書にし、各手順書は手順に含めず冒頭のリード文から参照する。** 手順 1 はその手順書の主題（ツールの導入）から始める。Homebrew 系 9 本が `docs/homebrew.md` を参照しているのがこの形
6. 対話入力（パスワード、`[y/N]`、TUI の起動）があるコマンドは**単独のコードブロック**にし、直後に「次のブロックは〜してから貼る」と書く。続けて貼ると後続行が入力として食われるため

出力例・ログ・表の中の値は `<HOSTNAME>` / `<SERVER_IP>` などのプレースホルダで書き、実測出力は変数に置き換えない。`<...>` を含むコマンドは bash のコードブロックに置かず、読者が値を入れるブロックは先頭で変数が空なら中断させる（README「記法の約束」）。手順書のコードブロックは検証目的でも実機で機械的に実行しない。コマンドは実際に実行したものを載せる。パスワード・鍵・トークンは private でも書かない。

### wg-vpn.sh の設計

- **入力は `site.env` 1 ファイル**。両拠点に同じファイルを置く。`select_site A|B` が `SITE_A_*` / `SITE_B_*` から `MY_*` / `PEER_*` を組み立てるので、以降の処理は拠点を意識しない。このホストの LAN 側 IP が `WG_x_LAN_IP` と一致しなければ何も変更せずに止まる
- **変更を伴うコマンドはすべて `run()` を通す**。`--dry-run` はこれで実現しているので、新しい副作用も必ず `run` 経由にする
- **検査してから変更する**。`validate_addresses`（Python の `ipaddress` で形式・重複・包含関係を検査）などの検査に 1 つでも落ちたら何も書かない
- `apply` は冪等。`clients.list` の登録簿から毎回 conf を組み立て直し、firewalld は存在確認してから追加し、最後は常に `systemctl restart`（reload では経路が変わらないため）。旧レイアウト（専用ゾーン + policy）が残っていれば policy → ゾーンの順で消す（逆順だと firewalld の設定が壊れる）
- `PrivateKey` は conf に直接書く。`PostUp` で読み込む方式は reload で鍵が消える
- `firewall-cmd --query-policy` は 2.4.3 に存在しない。存在確認は `--info-policy` の終了コードで行う

スクリプトの挙動を変えたら、`docs/wireguard.md` の「スクリプトの動作」節と `--help`（ファイル冒頭コメントを `usage()` がそのまま表示する）、必要なら README の知見リストも合わせて直す。
