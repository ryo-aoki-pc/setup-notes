# AGENTS.md

このリポジトリで作業するコーディングエージェント（Claude Code・Codex・Grok Build）への指示。Claude Code は CLAUDE.md の `@AGENTS.md` で、Codex と Grok Build はこのファイルを直接読む。

利用者への回答・質問・報告は、常に日本語で書く（コードのコメントなどの言語は、このファイルのほかの決まりに従う）。

## このリポジトリは何か

実機で検証した構築・設定手順の記録（日本語）。成果物は `docs/*.md` の手順書で、`scripts/` はその手順書を実行可能にしたもの。手順書には操作・前提・成功条件と、操作を変える短い注意だけを書く。実施日・対象版・環境・結果・失敗の記録は `docs/verification/<手順書名>.md`、背景・採用理由・比較・参照資料は `docs/reference/<手順書名>.md`、ロールバック（「全部消す」などを含む）と注意点は `docs/extra/<手順書名>.md` に分ける（extra は 2026-10-10 に本体から移した。手順書の本体には、ふだん見る実施手順・任意節・使い方・更新・Windows 11 で使うを残す）。検証していないことを「動く」と書かず、状態と検証範囲は検証記録で管理する。

ビルド・テストフレームワークは無い。ドキュメントとコミットメッセージは日本語で書く。

共通の bash 設定は、README の「共通の bash 設定を先に入れる」から clone + `install.sh` で導入する（AlmaLinux 10 では、同じブロックが `docs/almalinux-setup.md` の「共通の bash 設定」の手順 1・2 にある）。`~/.bashrc` への標準の追記は bash リポジトリに集約済み。各ツールの実施手順では共通設定を前提にし、直接追記・削除のブロックは置かない。読み込みと確認のコマンドだけを書く。`docs/dev/structure.md` の各文書の説明に残る直接追記の内容は、2026-10-05 の統一前の履歴。現行の手順を優先する。共通設定の変更時は bash の `docs/quick-start.md` の対応表も合わせる。ツールの導入・ソケットの有効化・`~/.inputrc`・別形式の設定ファイルは従来どおり各手順書で扱う。

2026-10-06 の現行版再検証では、公式 ISO の Workstation クリーンインストールのスナップショットから 6 台の VM を新規作成し、`5da3478` の手順と共通 bash `3d5323e`、設定サブモジュールを前提から通した。結果は `docs/almalinux-vm-verification.md` の後半と各文書の `docs/verification/` の今回の付録にある。前半の `0dbb522` の結果と、従来の実機・コンテナの付録は別の履歴。実アカウント、Windows / bootc 固有の手順、VM が条件を満たさない入れ子の仮想化や MOK 登録は実施済みと扱わない。

2026-10-06〜07 UTC の Windows 検証は、Rufus のインストールメディアから入れた Windows 11 Pro の VM で行った。記録は `docs/verification/windows-setup.md` と各後続ツールの Windows VM の付録に集約する。CLI・値の読み戻し・利用者の手動確認を区別し、windows-setup.md の「WSL の AlmaLinux 10 と自動サインイン」の手順 5 の起動要求取消、WSL 2 と入れ子の VM の失敗、Git の初回通信 timeout、スタートアップの最初の確認不能も保持する。実機での通し実行・残る GUI・認証・VPN と RDP ログイン・ping は未確認。今回の VM の検証から任意のリモート再起動節などへ成功範囲を広げない。

2026-10-08 UTC に、同じ VM で PR #104 の未検証の項目を追加で確かめた。GitHub のコピーボタンからの貼り付け（管理者の conhost・Windows Terminal・mintty）、残る画面と分岐、2 枚目の NIC での ping と RDP ログイン、AlmaLinux の VM 2 台を拠点にした WireGuard の VPN の通し、任意節（Wake on LAN の一部・リモートからの再起動）、更新とロールバックを通した。VirtualBox の手順 6 だけはホストの実機で流した。別の Windows からの再起動のトリガー（SMB の `net use` と `shutdown /m`、WinRM の `TrustedHosts` と `Invoke-Command`）は、利用者の許可を得てホストの実機を送る側にして確かめた（相手の VM のクローンは正しい資格情報でも NTLM が拒否され、送る側に使えなかった。マシンの SID の重複が原因とみたが、確かめていない）。記録は `docs/verification/windows-setup.md` と各後続ツールの 2026-10-08 の付録。WSL 2・Claude Code のログイン・インターネット越しの VPN・Wake on LAN の起動・Store の更新の適用と Windows Update の再起動の分岐（この VM では対象の更新が無かった）と、実機での通し実行は未確認。

## よく使うコマンド

```bash
# シェルスクリプトの静的検査（導入は docs/shellcheck.md。最新の実測は docs/verification/shellcheck.md）
bash -n scripts/wireguard/wg-vpn.sh
shellcheck -x scripts/wireguard/wg-vpn.sh

# wg-vpn.sh を変更せずに実行予定を見る（root 不要なサブコマンドもある）
sudo scripts/wireguard/wg-vpn.sh -e scripts/wireguard/site.env --dry-run apply A
scripts/wireguard/wg-vpn.sh --help

# 図の再生成（docs/diagrams/*.diag → *.svg）。nwdiag / seqdiag を直接呼ばない
sudo dnf install -y google-noto-sans-cjk-vf-fonts
python3 -m pip install --user nwdiag seqdiag
python3 scripts/render-diagrams.py          # 別フォントは WG_DIAG_FONT=... で指定

# GUI の動作を確かめる（docs/claude-code-gui.md を通したホストで。撮った PNG を開いて見る）
scripts/gnome-gui.py shot /tmp/gnome-gui.png
scripts/gnome-gui.py key Escape                 # セッションを始めた直後に開いているアクティビティ画面を閉じる
scripts/gnome-gui.py launch org.gnome.TextEditor
scripts/gnome-gui.py type 'hello'
scripts/gnome-gui.py click 70 15                # 座標は shot の PNG の画素
scripts/gnome-gui.py windows
```

GUI の動作を確かめるときは、`docs/claude-code-gui.md`（前提は `docs/gnome-headless-session.md` の手順 1・2）で仮想モニターを付けたヘッドレスのセッションを `scripts/gnome-gui.py`（Mutter の ScreenCast / RemoteDesktop。GNOME Shell の unsafe mode は使わない）で撮って操作する。操作のたびに `shot` で確かめ、利用者に見せるときはその PNG を送る。アクティビティ画面が開いているときに `launch` した窓にはフォーカスが移らないので先に `key Escape`、画面が動くキーの後は `sleep 1` を挟む。キー配列に無い文字は打てない（日本語は IBus でローマ字を打つ形になるはずだが、確かめていない）。PATH の先頭が Homebrew だと `gsettings`・`gdbus`・`gio`・`python3` が Homebrew のものになるので、`/usr/bin/` を付ける（Homebrew の `gsettings` は GNOME の dconf に書かない）。 実機の Raspberry Pi 5 では 2026-10-08 にヘッドレスのセッションと仮想モニターのドロップインを外した（リモートログインだけにした）ので、この仕組みは無い。使うなら、利用者に確かめてから gnome-headless-session.md の手順 1・2 と claude-code-gui.md の手順 1〜3 を通す（リモートログインのセッションにも仮想モニターが付く）。

`wg-vpn.sh` の本実行を実機の設定に触れずに試す方法は、`docs/verification/wireguard.md` の「付録: スクリプトの検証」にある。`unshare -Urm` で uid 0 の user namespace を作り、`/etc/wireguard`・`/etc/sysctl.d`・`/etc/firewalld` に tmpfs を重ね、`firewall-cmd` / `systemctl` / `ip` などのスタブを `PATH` の先頭に置く。`wg genkey` / `wg pubkey` はカーネルモジュール無しで本物が使える。

## 文書を書く・直すとき

書き方の規則と文書ごとのメモは大きい（合わせて約 245 KB）ので、`docs/dev/` に分けてある（Codex が読む AGENTS.md は合計 32 KiB まで）。次のときに読む。

- 手順書・検証記録・参考資料・extra を書いたり直したりする前に、[docs/dev/writing-rules.md](docs/dev/writing-rules.md)（手順書の構造・手順の形・表現の規則）を読む
- ある文書やスクリプトを直す前に、[docs/dev/structure.md](docs/dev/structure.md) で、そのファイルの項（`` - `docs/<名前>.md` — `` などで始まる行と、その下の入れ子の行）を読む
- 文書を足したときや、状態（検証範囲）を変えたときは、`docs/dev/structure.md` の項も直す

## wg-vpn.sh の設計

- **入力は `site.env` 1 ファイル**。両拠点に同じファイルを置く。`select_site A|B` が `SITE_A_*` / `SITE_B_*` から `MY_*` / `PEER_*` を組み立てるので、以降の処理は拠点を意識しない。このホストの LAN 側 IP が `WG_x_LAN_IP` と一致しなければ何も変更せずに止まる
- **変更を伴うコマンドはすべて `run()` を通す**。`--dry-run` はこれで実現しているので、新しい副作用も必ず `run` 経由にする
- **各段階で検査してから変更する**。`validate_addresses` は Python の `ipaddress` で形式・重複・包含関係を検査する。入力や未知 peer の事前検査で止まれば設定は反映しないが、`apply` の後半で失敗すると、それ以前に行った設定変更は残りうる。すべての検査失敗で無変更になるとは案内しない
- `apply` は冪等。`clients.list` の登録簿から毎回 conf を組み立て直し、firewalld は存在確認してから追加し、最後は常に `systemctl restart`（reload では経路が変わらないため）。旧レイアウト（専用ゾーン + policy）が残っていれば policy → ゾーンの順で消す（逆順だと firewalld の設定が壊れる）
- `PrivateKey` は conf に直接書く。`PostUp` で読み込む方式は reload で鍵が消える
- `firewall-cmd --query-policy` は 2.4.3 に存在しない。存在確認は `--info-policy` の終了コードで行う

スクリプトの挙動を変えたら、`docs/wireguard.md` の「スクリプトの動作」節と `--help`（ファイル冒頭コメントを `usage()` がそのまま表示する）、必要なら README の知見リストも合わせて直す。

## 共同作業の規則

このリポジトリでは、Claude Code・Codex・Grok Build が同じ規則で作業する。分担と `main` への取り込みは人が決める。

- 起動された worktree（作業ディレクトリ）の中だけでファイルを変える。ほかの worktree のファイルは変えない
- 今のブランチにだけコミットする。`main` にはコミットも push もしない
- 頼まれた範囲のファイルだけを変える。範囲の外を変えるときは、変える前に理由を書いて確かめる
- 終わったら、テストとリンターを通してから、目的ごとにコミットする。通らなければコミットせずに、結果を報告する
- コミットしたら、今のブランチを push し、`main` への Pull Request を作る（既にあれば足す）。`main` への取り込み（マージ）とブランチの削除は人が行う。今のブランチに `main` を取り込むのは、頼まれたときと、Pull Request が競合したときだけ
- 秘密情報（`.env`・鍵・トークン・パスワード）を読まない・書かない・出力しない
- レビューを頼まれたら、ファイルを変えずに、指摘を「重大度・場所（ファイル:行）・理由・直し方」で挙げる
- ほかの担当の変更は、`git diff main...agent/codex` のように git で読む（ほかの worktree へ移らない）
