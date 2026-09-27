# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリは何か

実機で検証した構築・設定手順の記録（日本語）。成果物は `docs/*.md` の手順書で、`scripts/` はその手順書を実行可能にしたもの。「動いた手順」だけでなく**なぜ失敗したか・どう切り分けたか**を残すのが目的なので、検証していないことを「動く」と書かない。手順書の冒頭にある **状態** 行（実機で本実行済み / コンテナのみ / スタブ / network namespace のみ など）は、検証範囲が変わるたびに更新する。

ビルド・テストフレームワークは無い。ドキュメントとコミットメッセージは日本語で書く。

## よく使うコマンド

```bash
# シェルスクリプトの静的検査（導入は docs/shellcheck.md。最新の実測は同書の手順 4 の末尾に折り畳んだ補足）
bash -n scripts/wireguard/wg-vpn.sh
shellcheck -x scripts/wireguard/wg-vpn.sh

# wg-vpn.sh を変更せずに実行予定を見る（root 不要なサブコマンドもある）
sudo scripts/wireguard/wg-vpn.sh -e scripts/wireguard/site.env --dry-run apply A
scripts/wireguard/wg-vpn.sh --help

# 図の再生成（docs/diagrams/*.diag → *.svg）。nwdiag / seqdiag を直接呼ばない
sudo dnf install -y google-noto-sans-cjk-vf-fonts
python3 -m pip install --user nwdiag seqdiag
python3 scripts/render-diagrams.py          # 別フォントは WG_DIAG_FONT=... で指定
```

`wg-vpn.sh` の本実行を実機の設定に触れずに試す方法は、`docs/wireguard.md` の「付録: スクリプトの検証」にある。`unshare -Urm` で uid 0 の user namespace を作り、`/etc/wireguard`・`/etc/sysctl.d`・`/etc/firewalld` に tmpfs を重ね、`firewall-cmd` / `systemctl` / `ip` などのスタブを `PATH` の先頭に置く。`wg genkey` / `wg pubkey` はカーネルモジュール無しで本物が使える。

## 構成

- `README.md` — 手順書とツールを選ぶための一覧と記法。一覧は役割ごとの `###` 節に分け、節ごとの表の列で同じ役割の手順書を比べる（検証範囲の列は置かない）。手順書を足すときは役割の合う節の表に行を足し（合う節が無ければ節を足す）、導入元・設定の置き場所など表に載せた値を変えたときも直す。導入元一覧（`docs/tool-catalog.md`）のツールは、手順書の表の後ろに置く 2 つ目の表（`手順書の無いツール` / 用途 / 導入元）に役割で振り分けて 1 行ずつ載せ、名前は導入元一覧のその行がある節へリンクする（手順書の無い役割は、この表だけの節にする。手順書を作ったツールは手順書の表へ移す）。版は載せない（導入元一覧だけで管理する）。詳しい知見は各手順書の「補足」に置く
- `docs/gnome-remote-desktop.md` — 変数ブロックを冒頭に置き、以降のコマンドをそのまま貼れる形式
- `docs/wireguard.md` — `wg-vpn.sh` を主役にした手順書。`site.env` に値を書き、`keygen` → `apply` → `router` → `client add` の順
- `docs/wezterm-nightly.md` — 公式 COPR の EL9 向けビルドを chroot 明示で EL10 に入れる手順。採用しなかった経路（GitHub rpm / AppImage / Flathub / ソース）の実測も補足に残す
- `docs/samba.md` — `[homes]` 共有でホームディレクトリを公開する手順書。gnome-remote-desktop.md と同じ変数ブロック方式。実機（拠点 B の WG ホスト）で公開を継続中
- `docs/wireguard-road-warrior.md` — 外出先の AlmaLinux 10 PC を WG クライアントにする手順書。鍵は PC 側で生成し、ホストの `client add --pubkey` → `client show` の conf を `nmcli connection import` で取り込む。samba.md と同じ変数ブロック方式。実機で本実行済み（2026-09-22、テザリング回線から拠点 B へ）。サスペンド復帰・Wi-Fi の切り替えなど、付録の「残っている未確認事項」は実機の結果で更新する
- `docs/syncthing.md` — Syncthing を Homebrew（2.1.5、上流最新と同版）で入れ、`brew services` の systemd ユーザーサービス + `loginctl enable-linger` で常駐させる手順書。EPEL 10 は 2.1.3 で、公式の RPM リポジトリは存在しない（公式は apt のみ）。GUI の認証を入れてから待ち受けを LAN に広げ、firewalld の定義済みサービス `syncthing` / `syncthing-gui` を開ける順にしてある。実機で本実行済み（2026-09-24）。firewalld 越しの到達は samba.md と同じ network namespace の手法で確認したが、**別デバイスとの実同期と再起動後の自動起動は未検証**。任意節の「設定を自動でバックアップする」（`~/.local/bin/syncthing-backup` を systemd のユーザーの path + timer で走らせ、`~/syncthing-backup` を送信専用フォルダにして別の端末へ複製）と「バックアップから戻す」（OS を入れ直したホストは、アーカイブを戻してから実施手順を手順 1 から通す。`syncthing generate` は既存の鍵を使う）は **x86_64 のコンテナのみで検証**（相手は同じコンテナの 2 つ目の Syncthing）。`systemd-analyze --user verify` はユーザーの systemd の private ソケットを置き換えて `systemctl --user` を壊すので使わない
- `docs/firefox.md` — Mozilla 公式 RPM リポジトリ（`packages.mozilla.org/rpm/firefox`）で最新版の Firefox を入れる手順書。AppStream の ESR 140 から `dnf install` 1 本で載せ替える。**Mozilla の Linux 版は AAC と H.264 を OS の FFmpeg（`libavcodec.so.53`〜`.63`）に頼り、AAC を補う手段は他に無い**ので、手順 8〜14 で RPM Fusion（free）を足して `ffmpeg-libs` を入れる（鍵を照合してから `localpkg_gpgcheck=1` で `rpmfusion-free-release` を入れると、`epel-release` も付いてくる）。EPEL の `libavcodec-free` は H.264 を中身の無い `noopenh264` に回して再生に失敗するので採らず、入っていれば手順 13 で `--allowerasing` で入れ替える。本体の場所は `/usr/lib/firefox`（AppStream 版は `/usr/lib64/firefox`）。手順 1〜7 は実機で本実行済み、手順はコンテナで再実行して確認。手順 8〜14 も実機で本実行済み（2026-09-28。利用者が再生を確認し、headless の Firefox を Marionette で動かして about:support と AAC・H.264 の再生も確かめた）。SELinux のポリシーが入ったホストでは、手順 11 で CRB の `selinux-policy-extra` も入る。**x86_64 はメタデータのみ**で、音声が AAC だけの YouTube の動画での再生は確かめていない（例の動画は、入れる前に Opus が足された）
- `docs/claude-code.md` — 公式 dnf リポジトリの `latest` チャンネル（`downloads.claude.ai/claude-code/rpm/latest`）から最新版の Claude Code を入れる手順書。Node.js 不要。`CC_CHANNEL` で `stable` も選べ、入れた後の `stable` への切り替え（版が下がるので `distro-sync`）を任意節に置く。`stable` は実機で本実行済み（認証も済み）。**既定の `latest` は x86_64 のコンテナのみで検証**（手順 1〜4・更新・切り替え・ロールバックを文書のコードブロックのまま通した）
- `docs/gh.md` — 公式 dnf リポジトリ（`cli.github.com/packages/rpm`）から gh を入れる手順書。EPEL 版は 2.97.0 と古い。実機で本実行済み、手順 1〜3 はコンテナで再実行
- `docs/homebrew.md` — Homebrew 本体を入れる手順書。以降の Homebrew 系 13 本の前提で、各手順書は `## 実施手順` のリード文からここへ誘導し、変数の設定（手順 1。変数の無い文書には無い）の次の手順から各ツールの導入が始まる。インストーラの `Next steps` の実測と `brew` の基本操作もここに集約した。実機で本実行済み（2026-09-20）、手順はコンテナで再実行
- `docs/yazi.md` — yazi を Homebrew で入れる手順書。COPR `lihaohong/yazi` を実機で一度入れて外した経緯と、プレビュー依存（ffmpeg など）が EL10 に揃わないことを補足に残す。`y()` シェル関数まで含む
- `docs/lazygit.md` — lazygit を Homebrew で入れる手順書。COPR（`dejan` / `atim`）は `epel-10-aarch64` の repomd が 403 で入らないことを実機とコンテナの両方で確認して不採用にしている
- `docs/neovim.md` — Neovim を Homebrew で入れる手順書（EPEL は 0.10.1 と古い）。`:checkhealth` の読み方と、`sudo nvim` が使えない理由を補足に置く
- `docs/zoxide.md` — zoxide を Homebrew で入れる手順書。EPEL にも AppStream にも RPM が無い。`~/.bashrc` の `eval "$(zoxide init bash)"` が本体で、`--cmd cd` の影響範囲も補足に書く
- `docs/bat.md` — bat を Homebrew で入れる手順書。EPEL は 0.24.0 で古い。`alias cat=bat` は勧めず、`~/.config/bat/config` と `MANPAGER` の使い方だけ案内する。**コンテナのみで検証（実機未導入）**
- `docs/eza.md` — eza を Homebrew で入れる手順書。EPEL にも AppStream にも RPM が無い（`exa` も無い）。`ls` は置き換えず `ll` / `la` / `lt` を足す形にしてある。非対話シェルでは `type -t` がエイリアスを見つけられないことも補足に書く。**コンテナのみで検証**
- `docs/git-delta.md` — git の差分表示を delta にする手順書。formula 名は `git-delta`、バイナリは `delta`。設定は `git config --global` で `~/.gitconfig` に書く（git がキー名を小文字に正規化するので読み戻しの正規表現に注意）。lazygit の `git.paging` 連携は任意節。**コンテナのみで検証**
- `docs/gdu.md` — gdu を Homebrew で入れる手順書。**brew 版の実行ファイルは `gdu-go`**（coreutils との衝突回避）。EPEL には 5.32.0 の `gdu` がある。実機には同じ brew 版 5.37.0 が 2026-09-21 から入っているが、本書の通し検証はコンテナのみ
- `docs/btop.md` — btop を EPEL の dnf で入れる手順書。**手順書では唯一 Homebrew を選ばなかったツール**（EPEL と Homebrew がどちらも 1.4.7。`docs/tool-catalog.md` では fastfetch などもこの規則で EPEL にしている）。変数は無く、手順 1〜3 が EPEL の有効化で、鍵は `epel-release` が置くローカルファイルから入る。**コンテナのみで検証**
- `docs/shellcheck.md` — ShellCheck と shfmt を Homebrew で入れる手順書。**この CLAUDE.md の「よく使うコマンド」が前提にしている `shellcheck` の導入元**。EPEL にも 0.10.0 があるが**パッケージ名が大文字の `ShellCheck`** で 1 マイナー古く、shfmt は RPM がどこにも無いので両方 Homebrew に揃えた。`wg-vpn.sh` を 0.11.0 で検査した実測を手順 4 の補足に置く（**SC2034 が 1 件出たので同じ変更で `wg-vpn.sh` の未使用変数 `MY_LAN` を消して 0 件にした**。`-x` はこのスクリプトでは結果を変えない）。`shfmt -w` はリポジトリのファイルに掛けず、一時ディレクトリの複製で確認している。実機で本実行済み、手順はコンテナで再実行
- `docs/vscode.md` — Microsoft 公式 dnf リポジトリ（`packages.microsoft.com/yumrepos/vscode`）から VS Code を入れる手順書。rpm の release は `.el8` 固定だが、これは**MS が EL 共通に 1 本だけ出している**ためで WezTerm の EL9 流用とは事情が違う。`~/.config/code-flags.conf` が読まれないことも実測で書いた。実機で本実行済みで、デスクトップの端末からの GUI 起動まで確認した。**ただし TTY もディスプレイも無いシェルからは 6 通り試して起動できず**、その記録を付録に残してある。コンテナでは依存解決のみ
- `docs/starship.md` — プロンプトを starship にする手順書。`~/.bashrc` の `eval "$(starship init bash)"` が本体。zoxide の初期化より後ろに置き、WezTerm のシェル統合が `PS1` に足す OSC 133 の A/B マーカーは starship に上書きされる（init スクリプトを読んだ上での推定、実挙動は未検証）。**コンテナのみで検証**
- `docs/hackgen.md` — プログラミング用フォント HackGen Console NF を Homebrew の cask `font-hackgen-nerd` で入れる手順書。**Linux の Homebrew は font の cask を `~/.local/share/fonts` に置く**（cask の定義は macOS の `~/Library/Fonts` しか示さないので実測で確かめた）。cask の展開に `unzip` が要り、Homebrew のインストーラも `homebrew.md` の依存パッケージも入れないので、変数の設定（手順 1）の次の手順 2〜3 を `unzip` の用意にしてある（btop.md の EPEL と同じ扱い）。NF 版の zip には Console の 2 ファミリー（`HackGen Console NF` / `HackGen35 Console NF`）しか無い。確認は `fc-list` / `fc-match` / `fc-list :charset=` と、任意節の `wezterm ls-fonts --text`。**x86_64 のコンテナのみで検証**（flatpak.md と同じ Docker の環境）。見た目は未確認
- `docs/flatpak.md` — AppStream の flatpak に Flathub を system で登録する手順書。**GUI アプリにとっての `docs/homebrew.md`** で、今のところ `docs/tool-catalog.md` の GUI の Flathub 行だけがこれを前提にしている（Firefox / VS Code は Flathub を採らず RPM）。入れた直後の `flatpak remotes` がエラーを出すこと、確認が 2 回あること、最初の 1 本で `/var/lib/flatpak` が 2.5 GB になることを書いた。**x86_64 のコンテナのみで検証**（クラウドホスト上の Docker、`--privileged`。これまでの「実機上の podman」とは別の環境）。画面の表示は未確認
- `docs/virtualbox.md` — Oracle 公式 dnf リポジトリ（`download.virtualbox.org/virtualbox/rpm/el/10/x86_64`）から VirtualBox 7.2 を入れる手順書。**x86_64 のみ**（Linux の arm64 版が無い）で、パッケージ名に系列が入る（`VirtualBox-7.2`）。依存の `liblzf` が EPEL にしか無いので手順 2〜4 が EPEL の有効化（btop.md と同じ扱い）。メタデータにも署名がある（`repo_gpgcheck=1`）ので、鍵の確認を `sudo` 付きと無しの dnf で 1 回ずつ通す（通さないと `sudo` 無しの dnf が無関係なパッケージでも失敗する）。rpm の `%post` がモジュールをその場でビルドし、**失敗しても `Complete!` で終わる**ので、ビルドの道具（`perl` ではなく `perl-interpreter` で足りる）と Secure Boot の MOK（鍵は `/var/lib/shim-signed/mok/MOK.{der,priv}` 固定、判定は `mokutil --sb-state` だけ）をインストールより先に用意する。EL10 の 6.12 系カーネルでは VirtualBox の KVM 共存の仕組み（6.16 以上だけ）が効かず、kvm.ko も既定で読み込み時に VT-x / AMD-V を取るので、`options kvm enable_virt_at_load=0` を modprobe.d に置く。系列の切り替えは remove → install（`dnf swap` は新しい系列のモジュールと設定を消した）。**x86_64 のコンテナのみで検証**（`uname -r` と `mokutil` はスタブ。モジュールの読み込み・MOK の登録・VM の起動・GUI は未検証）
- `docs/gnome-power.md` — GNOME の画面オフ・画面ロック・自動サスペンドを止める手順書（既定は「画面を消さない・ロックしない・眠らない」で、`IDLE_DELAY` などの変数で変えられる）。自分のセッションは `gsettings`（`idle-delay`・`lock-enabled`・`idle-dim`・`sleep-inactive-*-type`・`power-button-action`）、ログイン画面は dconf の `/etc/dconf/db/gdm.d/90-power` と `dconf update`（RHEL の gdm のプロファイルは `system-db:gdm` を読む）、OS 全体は sleep 系の target 5 つの `systemctl mask`、蓋は logind のドロップインで変える。**gdm 47 のログイン画面は電源のキーを持たないので、Workstation で入れた PC はログイン画面のまま 15 分で眠る**（Server with GUI は override で眠らないが、その電源ボタンの行は引用符が無くて効いていない）。dconf のファイルの文字列は引用符で囲み、uint32 は `uint32 0` と書く（引用符が無いと `dconf update` が失敗し、`uint32` が無いと黙って無視される）。`idle-delay` が 0 でも `idle-dim` が true だと 60 秒で暗くなる。**x86_64 のコンテナのみで検証**（`dbus-run-session` のコンテナと、systemd を PID 1 にして `/sys/power` を tmpfs に差し替えたコンテナ。mask で `CanSuspend` が `"yes"` から `"no"` になる）。画面・実際のサスペンド・蓋は未検証
- `docs/japanese-input.md` — GNOME で日本語を入力する手順書。EL10 には Mozc の RPM が無い（EPEL 10 にも COPR にも無い）ので、AppStream の `ibus-anthy`（RHEL 10 の文書が日本語用に挙げるエンジン）を使う。入力ソースを `[('xkb', '<配列>'), ('ibus', 'anthy')]` にして Super+Space で切り替え、配列は `localectl status` から自動で取る。`ibus-anthy` を入れた後は、ibus-daemon が読み直すまで使えないのでログインし直す。**x86_64 のコンテナのみで検証**（IBus の API にキーを送り、`nihongo` →「日本語」と半角/全角キーの切り替えを確認）。画面とアプリでの入力は未検証
- `docs/dropbox.md` — x86_64 の PC で Dropbox の公式クライアントを headless で動かす手順書。**公式 RPM（`nautilus-dropbox`）は EL10 に入らない**（`libgnome` が AlmaLinux 10 にも EPEL 10 にも無く、`%post` が置く `.repo` も `$releasever` が 10 で 404）ので、公式の tarball を `gpgv` で署名を確かめてから `~/.dropbox-dist` に展開し、`dropbox.py` を `~/.local/bin/dropbox` に置く。**`download?plat=lnx.x86_64` は呼ぶたびに版を振り分ける**ので、飛び先を 1 回だけ引いて tarball と `.asc` を落とす（2 つの URL を別々に引くと版が食い違い、`BAD signature` になった）。常駐は自分で書くユーザーサービス（`Restart=always`・`UnsetEnvironment=DISPLAY WAYLAND_DISPLAY`）と linger。変数は無い。**x86_64 のコンテナのみで検証**（リンク用の URL が出るところまで。検証のときだけサービスにプロキシを渡した）。アカウントのリンク・リンク後の同期・自己更新は未検証
- `docs/dropbox-rclone.md` — Raspberry Pi 5（aarch64。Dropbox の公式クライアントが無い）で、Homebrew の rclone の `bisync` を systemd のユーザータイマーで 15 分ごとに回し、`~/Dropbox` と Dropbox を双方向同期する手順書（Homebrew 系の 1 本）。`rclone config create` は登録が終わるとトークン入りの設定を標準出力に出すので `>/dev/null` を付ける。フィルタのファイル（`~/.config/rclone/dropbox-filters.txt`）はいつも `--filters-file` で渡し、変えたら `--resync`。強制終了で残る書きかけ（`*.partial`）が次の回で上がったので、フィルタの既定に `- *.partial` を入れた。変数は無い。**x86_64 のコンテナのみで検証**（OAuth は URL が出るまで、手順 3 以降は `alias` の代役のリモート）。aarch64 はボトルがあることだけ確かめた
- `docs/tool-catalog.md` — **手順書ではなく一覧**。CLI・GUI 約 40 本の推奨導入元・版・導入コマンド・ほかの経路・aarch64 での提供を 1 行ずつ比べ、個別の手順書があるものはそこへ誘導する。選び方は CLI が「RPM が Homebrew と同版以上なら RPM」（podman と組むものは RPM）、GUI が「ベンダーの dnf → AppStream/EPEL → Flathub の検証済み」。x86_64 はコンテナで表の導入コマンドを実行済み、aarch64 は `dnf --forcearch` / Homebrew の JSON / `flatpak remote-ls --arch` のメタデータのみ。版は調査日（2026-09-24）の値なので、更新するときは状態行・表・付録の調査日をまとめて直す。行を足す・消す、推奨の導入元を変えたときは README の「手順書の無いツール」の表も直す
- `docs/diagrams/*.diag` — nwdiag（構成図）と seqdiag（パケットの流れ）の原本。`*.svg` は生成物なので直接編集しない
- `scripts/render-diagrams.py` — 先頭のキーワードで方言（nwdiag / seqdiag）を選び、blockdiag 3.0.0 と Pillow 10 の非互換を shim で埋め、SVG に背景・CJK フォント・viewBox 幅の後処理をする
- `scripts/wireguard/wg-vpn.sh` — 約 1,250 行の bash。`site.env.example` / `clients.list.example` が入力ファイルの形式。実物の `site.env` / `clients.list` / バックアップは `.gitignore` 済み

### 手順書の構造

各手順書は同じ骨格で書いてある。新しい手順書もこれに合わせる。

1. タイトルの直後に `## 実施手順` を置き、手順はその中の**番号付きリスト 1 つ**で振る（`### 1. 〜` のような番号付きの見出しにしない）。マーカーは手順以外のリストも含めてすべて `1.` にし、番号は自動で振らせる。手順番号は 1 から数える（変数ブロックがあればそれが手順 1）。各手順は下の「手順の形」に揃え、本文は 3 スペース字下げにする。**前半は読者が実行する操作と、その場で必要な短い注意だけ**にする
1. その手順だけにかかわる理由・実測・落とし穴・出力例は、項目の末尾に `<details>` / `<summary>補足: 〜</summary>` で折り畳んで置く（`<summary>` の行の後と `</details>` の前に空行を入れないと中の Markdown が描画されない）。折り畳みの中では見出しを使わず太字の段落にし、手順を進めるのに貼る必要のあるコマンドは置かない（リード文で「折り畳みの中のブロックは貼らなくてよい」と案内する）
1. 環境固有の値は手順冒頭の変数ブロックまたは `site.env` だけで設定する（`${SERVER_IP}` 形式。値の置き場所は手順書ごとに 1 か所）。**変更が必須の変数は 1 変数ずつのコードブロックに分け、変更が任意の変数（既定のままでよい・自動で入るが違えば直す）は 1 つのブロックにまとめて必須ブロックの後に置く。** 値の読み戻しは任意の変数のブロックの末尾に入れる。シェルに貼って編集する手間を減らすため
   - **変える必要の無い値は変数にせず、コマンドに直接書く。** 固定の URL・パス・パッケージ名、ツールが既定の場所からしか読まないパス（`~/.config/bat/config` など。変数を変えても読み込み先は変わらない）、動作確認にだけ使う名前、`${USER}` や `$(uname -m)` の言い換えがこれに当たる
   - 変数が 1 つも無い文書には変数の手順を置かず、手順 1 から主題を始める
1. 動作確認を含む実行手順を `## 実施手順` の番号付きの手順にし、任意設定・設定ファイル・更新・`## ロールバック`（または「全部消す」）は `## 実施手順` の後ろの `##` 見出しに置く。ここまでが前半
   - **後ろの節も、貼るコマンドがあれば同じ形の番号付きリストにする**（節ごとに 1 から数える）
   - 節の中の並びは「リード（短い箇条書きとアラート）→ 番号付きリスト → `---`」にし、リストの後ろには何も置かない
   - 貼るコマンドの無い参照の節（表だけの「使い方の基本」など）はリストにしない
   - `##` 見出しは、ほかの文書からアンカーで参照されるので変えない
1. `## 補足` には手順書全体にかかわるものだけを置く: 「対象と検証環境」「実施前の状態」「選択した方針」「完了時点の状態」「注意点」「参照」「付録（検証記録）」。目的、環境表、変数表（「対象と検証環境」の注記）などの背景説明、任意節の補足、複数の手順にまたがる説明（wireguard.md の「スクリプトの動作」など）もここへ。`### 手順の補足` は作らない（1 つの手順だけにかかわる補足は、変数ブロックの補足も含めてその項目の折り畳みへ）
1. **複数の手順書が共有する前提は独立した手順書にし、各手順書は手順に含めず冒頭のリード文から参照する。** 変数の設定（手順 1。変数が無ければ無い）の次の手順は、その手順書の主題（ツールの導入）から始める。Homebrew 系 13 本が `docs/homebrew.md` を参照しているのがこの形
1. 対話入力（パスワード、`[y/N]`、エディタ・TUI・GUI の起動、再起動）があるコマンドは、**その手順の最後のコマンド**にする。後ろに続くコマンドは次の手順に分け、止める手順の最後の箇条書きを「**次の手順は、〜してから貼る**（続けて貼ると〜として食われる）」にする。続けて貼ると後続行が入力として食われるため。`sudo` のパスワードを聞かれうる手順（その文書で最初の `sudo` で終わる手順など）も、同じ箇条書きで終える
1. `## 実施手順` の直下（手順 1 の前）のリードは箇条書きにする。先頭の `> [!IMPORTANT]` に、実行する場所とユーザーの制約・前提の手順書・対話入力のある手順・別の場所で行う手順を挙げる（どれも無い文書には置かない）。続けて、読み方（上から順に貼る、折り畳みは読まなくてよい）と手順の後ろの節への案内を箇条書きで置く

#### 手順の形

手順（`## 実施手順` と、その後ろの節の番号付きリストの項目）は、次の 4 つをこの順に置く。

````
1. 1 行の説明。

   ```bash
   コマンド
   ```

   - 確認・分岐・注意（補足。表示する）
   - **次の手順は、〜してから貼る**（続けて貼ると〜として食われる）   ← 止める手順だけ

   <details>
   <summary>補足: …</summary>

   理由・実測・出力例（補足。折り畳む）

   </details>
````

- **1 行の説明**
  - 太字にしない 1 文で、「〜する。」で終える（目安は 60 字まで）
  - 実行する場所・条件・前提はここに書く（「WG ホストで、公開鍵を登録する。」「Secure Boot が有効なときだけ、署名鍵を登録する。」）
  - 変数の手順は「変数を設定する（`SERVER_IP` は必ず値を入れる）。」のように、必須の変数を括弧で示す
- **コマンド**
  - 説明の直後に置き、ブロックの間に何も挟まない
  - 並べてよいのは「1 変数だけのブロック（0 個以上）→ ほかのブロック 1 つ」だけ
  - 言語は bash。手で書き足す設定の断片（lazygit の yaml など）だけは、その言語のブロックでよい
  - `<...>` を含む別マシン用のコマンドは、ブロックにせず箇条書きのインラインコードにする
- **補足（表示）**
  - 箇条書きだけにする（入れ子は可）。段落・表・コードブロックは置かない
  - 出力例は折り畳みへ移し、箇条書きには判定に要る 1 行だけを引く
  - 「次のブロック」「上の 2 つのブロック」のような位置の言い方はせず、手順番号で言う
- **補足（折り畳み）**: 手順の最後に 1 つまで
- **手順を分けるところ**
  - 止める箇所（上の骨格の対話入力、完了待ち、目視の確認）
  - 別のホストや端末で行う操作
  - 条件付きの操作（「〜なら」「〜ときは」「〜も消すなら」）
  - 別々の操作や確認（太字の小見出しで区切るような）
- **ブロックをまとめるところ**
  - 条件の無いつなぎの文（「値を読み戻して確かめる」「次に〜を確かめる」）だけで分かれるブロックは、コマンドを変えずに 1 つにつなぐ
  - ただし、新しいシェルで貼り直す変数のブロックには、読み戻し以外のコマンドを足さない（貼り直すたびに実行されるため）
- **条件付きの手順**
  - 条件は 1 行の説明に書く。1 つの条件が複数の手順にかかるなら、それぞれに書く
  - 判定する手順の最後の箇条書きに「〜なら、手順 N は飛ばす」と書く
  - 代わりに行う手順は「（この節の手順 1 の代わりに）」と書く。元に戻す手順は最後に置き、「元に戻すときは、」で始める
- **コマンドの無い操作**（GUI の操作、起動途中の画面、別の端末）
  - 直前の手順の箇条書きに書く
  - 独立した手順にするのは、前に手順が無いとき、別の手順書に任せるとき、最後に別のマシンから確かめるときだけ
- **手順の参照**
  - 手順には見出しのアンカーが無いので、リンクは `[手順 N](#実施手順)`（別文書は `[x.md 手順 N](x.md#実施手順)`）にする。`## 実施手順` の中ではリンクにせず「手順 N の補足」「この手順の補足」と書く
  - 単に「手順 N」と書いたら `## 実施手順` の手順を指す。後ろの節の手順は、その節の中では「この節の手順 N」、ほかからは「[ロールバック](#ロールバック)の手順 N」と書く
  - 手順を分けたりまとめたりしたら、本文・補足・付録・リードの `> [!IMPORTANT]`・ほかの文書・この CLAUDE.md・`scripts/wireguard/` のヘッダコメントにある番号を付け替える。検証の記録（状態行・付録）は同じコマンドを指すように付け替え、範囲を広げない

#### 表現の規則（箇条書きとアラート）

- **手順の本文は「操作 → 確認」だけにする。** コマンドの後は箇条書き（1 項目に 1 つの事実。末尾に「。」を付けない）だけにし、理由・実測・背景はその手順の折り畳みへ移す。リードや後半の補足でも、150 字を超える段落を残さない
- **アラート（`> [!NOTE]` など）は本文の最上位にだけ置く。** GitHub は番号付きリストや `<details>` の中のアラートを描画しない（公式ドキュメントの「Alerts cannot be nested within other elements」）。手順の中の注意は `- **注意**: …` の箇条書きにし、複数の手順にかかわる注意はリードのアラートにまとめる。`## 実施手順` の後ろの節の手順にかかわるアラートは、その節のリードに置いて手順を名指しする（「**この節の**手順 3 で〜」）
- 使い分け:
  - `[!IMPORTANT]`: リードの前提（上の骨格の最後の項目）
  - `[!WARNING]`: 実機で本実行していない（コンテナのみの）文書の検証範囲（リードに 1 行）、複数の手順にかかわる危険（wireguard.md の `apply` の restart で ssh が切れる、など）、手順の外の節（任意節・更新・ロールバック）で事故につながる注意（同期対象にホームを丸ごと入れない、など）
  - `[!CAUTION]`: 取り戻せない削除（鍵・デバイス ID・プロファイル・パスワード DB・Homebrew 全体など）をする手順のある節の、リスト直前のリード。どの手順かを名指しし、その手順の 1 行の説明にも「（取り戻せない）」と書く。軽い設定ファイルの削除には付けない
  - `[!NOTE]`: 補足の「対象と検証環境」の注記（変数表・プレースホルダ・秘密情報）
  - `[!TIP]` は使わない。1 文書に 5 つまでにし、アラート同士を空行だけで続けて置かない
- **補足の「状態」行は入れ子の箇条書きに割る**（何を通したか・確認したこと・確認していないこと）。「選択した方針」「注意点」なども、150 字を超える段落は箇条書きに割る。付録（最初の `### 付録` から後）は検証記録なので書き直さない（手順番号の付け替えだけは行う。昔の手作業を指す「手動手順 N」は付け替えない）
- **太字の `**` を約物に接して閉じない。** 閉じの `**` の直前が `）`・`。`・`` ` `` などの約物で、直後が文字だと太字にならない（CommonMark の規則。`**最新版（Rapid Release）**を` は記号のまま出る）。約物を太字の外に出すか、太字の後ろを約物か空白にする
- **状態（検証範囲）を変えたら**、補足の状態行とこの CLAUDE.md の構成欄を合わせて直す。「コンテナのみ」の文書は、リードの `> [!WARNING]` も直す

`docs/tool-catalog.md` は手順書ではなく一覧なので、この骨格（`## 実施手順`・変数ブロック・手順ごとの折り畳み）に従わない。冒頭に状態と調査日を `> [!WARNING]` の箇条書きで置き、表の各行に確認の深さ（起動 / 導入 / メタデータ）を書く。表に載せる導入コマンドはコンテナなどで実行したものだけにし、実行していない行はコマンドを書かない。プレースホルダと秘密情報の規則はそのまま適用する。

出力例・ログ・表の中の値は `<HOSTNAME>` / `<SERVER_IP>` などのプレースホルダで書き、実測出力は変数に置き換えない。`<...>` を含むコマンドは bash のコードブロックに置かず、読者が値を入れるブロックは先頭で変数が空なら中断させる（README「記法の約束」）。手順書のコードブロックは検証目的でも実機で機械的に実行しない。コマンドは実際に実行したものを載せる。パスワード・鍵・トークンは private でも書かない。

### wg-vpn.sh の設計

- **入力は `site.env` 1 ファイル**。両拠点に同じファイルを置く。`select_site A|B` が `SITE_A_*` / `SITE_B_*` から `MY_*` / `PEER_*` を組み立てるので、以降の処理は拠点を意識しない。このホストの LAN 側 IP が `WG_x_LAN_IP` と一致しなければ何も変更せずに止まる
- **変更を伴うコマンドはすべて `run()` を通す**。`--dry-run` はこれで実現しているので、新しい副作用も必ず `run` 経由にする
- **検査してから変更する**。`validate_addresses`（Python の `ipaddress` で形式・重複・包含関係を検査）などの検査に 1 つでも落ちたら何も書かない
- `apply` は冪等。`clients.list` の登録簿から毎回 conf を組み立て直し、firewalld は存在確認してから追加し、最後は常に `systemctl restart`（reload では経路が変わらないため）。旧レイアウト（専用ゾーン + policy）が残っていれば policy → ゾーンの順で消す（逆順だと firewalld の設定が壊れる）
- `PrivateKey` は conf に直接書く。`PostUp` で読み込む方式は reload で鍵が消える
- `firewall-cmd --query-policy` は 2.4.3 に存在しない。存在確認は `--info-policy` の終了コードで行う

スクリプトの挙動を変えたら、`docs/wireguard.md` の「スクリプトの動作」節と `--help`（ファイル冒頭コメントを `usage()` がそのまま表示する）、必要なら README の知見リストも合わせて直す。
