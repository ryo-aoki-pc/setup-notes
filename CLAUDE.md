# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## このリポジトリは何か

実機で検証した構築・設定手順の記録（日本語）。成果物は `docs/*.md` の手順書で、`scripts/` はその手順書を実行可能にしたもの。「動いた手順」だけでなく**なぜ失敗したか・どう切り分けたか**を残すのが目的なので、検証していないことを「動く」と書かない。手順書の冒頭にある **状態** 行（実機で本実行済み / コンテナのみ / VM のみ / スタブ / network namespace のみ など）は、検証範囲が変わるたびに更新する。

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
- `docs/wezterm-nightly.md` — 公式 COPR の EL9 向けビルドを chroot 明示で EL10 に入れる手順。採用しなかった経路（GitHub rpm / AppImage / Flathub / ソース）の実測も補足に残す。「設定ファイル」の節から自分用の設定（`ryo-aoki-pc/wezterm`）の導入手順書 `docs/install.md`（この文書群と同じ書式で、検証範囲は同書の状態行）と README へリンクで案内する（clone のコマンドは載せない。RPM の `/etc/profile.d/wezterm.sh` があると設定のシェル統合が完了通知を出さないことも書いた）
- `docs/samba.md` — `[homes]` 共有でホームディレクトリを公開する手順書。gnome-remote-desktop.md と同じ変数ブロック方式。実機（拠点 B の WG ホスト）で公開を継続中。`{ … }` で囲んだ後の手順 1〜14 とロールバックは、x86_64 の VM にブラケットペースト無しで貼って通した（2026-09-28。手順 3 の smb.conf の字下げは TAB から空白に変えた。TAB は bash の補完で `.` に置き換わった）。任意節「root のホームも公開する」は、smb.conf の末尾に `[root]` 共有（`path = /root`・`valid users = <USER>`・`force user = root`・`browseable = No`）を足し、root の Samba ユーザーは作らない（Windows のエラー 1219 を避け、root にパスワードで入る口を作らない）。`/root` の `admin_home_t` は `samba_enable_home_dirs` の対象（`user_home_type`）に入っていないので、boolean が `user_home_type` に許すのと同じ許可を `admin_home_t` に足す CIL のモジュール `samba_root_home` を `semodule -i` で入れる（`/root/.ssh` などの `user_home_type` のラベルは boolean で既に許されているので、`.ssh/authorized_keys` も読み書きできる。WARNING に root と同じ重みと書いた）。戻すのは節の最後の手順（`sed` で `[root]` の節を消し `semodule -r`）と、ロールバックの手順 2。この節は **x86_64 の VM のみで検証**（2026-09-29。手順 1〜14 の後に、ブラケットペーストの有りと無しで 1 回ずつ。samba-client.md の手でのマウントも `SHARE=root` で通した）
- `docs/samba-client.md` — samba.md の共有を AlmaLinux 10 の PC から使う手順書。samba.md と同じ変数ブロック方式（必須は `SERVER` だけ。`SMB_USER` / `SHARE` / `MOUNT_POINT` の既定は `${USER}` / `${SMB_USER}` / `/mnt/${SHARE}`。samba.md の `[root]` には `SHARE=root` だけを変えてつなぐ）。`cifs-utils` を入れ、資格情報を `/root/smb-<SMB_USER>@<SERVER>.cred`（root の 0600）に置き、手で 1 度マウントして確かめてから、`/etc/fstab` に `x-systemd.automount,x-systemd.idle-timeout=1min` の行を足す（`_netdev` と `nofail` は付けない。理由は同書の「選択した方針」）。`sudo` の後ろに行が続くブロックは、どれも 1 つのコマンド（`if … fi` や `{ … }`）にしてある（ブラケットペースト無しで貼ると、sudo 1.9.17 の `use_pty` が残りの行を吸い、手順 6 の `umount` が実行されなかった）。変数が空のときの中断は、ブロックの先頭の `if [ -z … ]` で行う（パイプや `$(…)` の中の `${VAR:?}` はブロックを止めず、直す前の手順 5 は空の `/root/smb-@<SERVER>.cred` を作った）。GNOME Files（`gio mount`、gvfs-smb）は任意節。**x86_64 の VM のみで検証**（このホストのカーネルに CIFS が無いので、QEMU の TCG で AlmaLinux 10.2 の GenericCloud を動かした。SELinux は Enforcing、サーバーは samba.md 手順 3 の `smb.conf` を置いたコンテナ。ブラケットペーストの有りと無しで 1 回ずつ通した）。GNOME Files の画面・キーリング・実機・WireGuard 越しのマウントは未確認
- `docs/wireguard-road-warrior.md` — 外出先の AlmaLinux 10 PC を WG クライアントにする手順書。鍵は PC 側で生成し、ホストの `client add --pubkey` → `client show` の conf を `nmcli connection import` で取り込む。samba.md と同じ変数ブロック方式。実機で本実行済み（2026-09-22、テザリング回線から拠点 B へ）。サスペンド復帰・Wi-Fi の切り替えなど、付録の「残っている未確認事項」は実機の結果で更新する
- `docs/windows-openssh-server.md` — **Windows だけを対象にした唯一の手順書**（git.md は AlmaLinux 10 と Windows の両方）。Windows 11 のオプション機能 `OpenSSH.Server~~~~0.0.1.0` を入れ、LAN の AlmaLinux 10 などから Windows のユーザーのパスワードで SSH ログインできるようにする。Windows 側（手順 2〜7）は管理者の **Windows PowerShell 5.1** に貼る（Microsoft Store の PowerShell 7.6.6 では `Add-WindowsCapability` が `クラスが登録されていません` で失敗した）。機能が作る規則 `OpenSSH-Server-In-TCP` はプライベートだけで有効なので、LAN の接続をプライベートにする（パブリックのままでは捨てられた）。手順 6 で `sshd_config` の `#PasswordAuthentication yes` の行を `PasswordAuthentication yes` に置き換える（既定でも有効だが、切った PC も同じ手順で戻す。末尾が `Match` のブロックなので追記しない）。確認の手順 9 は `ssh -o PubkeyAuthentication=no`。Microsoft アカウントのパスワードは、設定の「Windows Hello サインインのみを許可する」がオンのままで通った（オンだとエラー 1326 で拒否されるという Microsoft Q&A の報告とは違った）。任意節「公開鍵でもログインする」で、鍵はクライアントで作り、公開鍵の 1 行をその節の `$PUBKEY` に貼って `C:\ProgramData\ssh\administrators_authorized_keys` に足す（Administrators の一員は `sshd_config` 末尾の `Match Group administrators` でこのファイルを使う。ACL は `icacls` で SID の `*S-1-5-32-544` と `*S-1-5-18` だけ）。任意節「パスワード認証を切る」で、同じ行を `no` に置き換える（2026-09-29 の版はこれを主にしていた）。`ssh-keygen` などは Git の `usr\bin` が `PATH` で先に来るので `System32\OpenSSH\` から呼ぶ。任意節で `HKLM:\SOFTWARE\OpenSSH` の `DefaultShell` を Git Bash にする（再起動不要、`bash -c` で起動される）。sshd には IFEO の `MitigationOptions` で RedirectionGuard が掛かっていて、SSH のセッションは一般ユーザーが作ったジャンクション（scoop の `current` と persist）をたどれない（エラー 448。所有者を Administrators に変えても通らず、管理者で作り直すと通る）ので、2 つ目の任意節で scoop のジャンクションを管理者で作り直す（`scoop install`・`update` の後は貼り直す。sshd の緩和策は外さない）。機能を外しても `C:\ProgramData\ssh` とレジストリのキーは残る。**実機で本実行済み**（2026-09-29 は公開鍵が主の版。x86_64 のノート PC の Windows 11 Pro 25H2、クライアントは同じ PC の WSL の AlmaLinux 10。1 回目の後にロールバックし、この文書から抜き出したブロックで 2 回目を通した。2026-09-30 は今の版を、その後の同じ PC に適用し〔手順 2・6 で `no` を `yes` に。パスワードでのログインは利用者がスマートフォンの SSH のアプリから WireGuard 越しに〕、続けて `C:\ProgramData\ssh` をアクセス権ごと控えてからロールバックし、実施前の状態から手順 2〜9・公開鍵の任意節・パスワード認証を切る任意節を通して、控えから戻した。手順 8・9 は試験用のローカル アカウントの標準ユーザー〔Medium Mandatory Level〕、公開鍵の任意節は WSL の試験用の Linux ユーザーのパスフレーズ付きの新しい鍵で流し、どちらのユーザーも消した）。Administrators の一員の SSH のセッションは High Mandatory Level（管理者）。ローカル アカウントでは SSH のパスワードの失敗もロックアウトに数えられ、10 回目でロックされ、ロック中はパスワードを聞かずに `Connection reset` になる。再起動の後の自動起動は、利用者の再起動のログで確かめた。WSL から LAN の IP あての接続は、sshd には送信元がこの PC の LAN の IP として届く。Microsoft アカウントのパスワードを OpenSSH の `ssh` で入れること・LAN の別の PC から手順どおりに入ること・端末への貼り付け・標準ユーザーの鍵・既定の UAC・Microsoft アカウントのロックアウトは未確認
- `docs/syncthing.md` — Syncthing を Homebrew（2.1.5、上流最新と同版）で入れ、`brew services` の systemd ユーザーサービス + `loginctl enable-linger` で常駐させる手順書。EPEL 10 は 2.1.3 で、公式の RPM リポジトリは存在しない（公式は apt のみ）。GUI の認証を入れてから待ち受けを LAN に広げ、firewalld の定義済みサービス `syncthing` / `syncthing-gui` を開ける順にしてある。実機で本実行済み（2026-09-24）。firewalld 越しの到達は samba.md と同じ network namespace の手法で確認したが、**別デバイスとの実同期と再起動後の自動起動は未検証**。任意節の「設定を自動でバックアップする」（`~/.local/bin/syncthing-backup` を systemd のユーザーの path + timer で走らせ、`~/syncthing-backup` を送信専用フォルダにして別の端末へ複製）と「バックアップから戻す」（OS を入れ直したホストは、アーカイブを戻してから実施手順を手順 1 から通す。`syncthing generate` は既存の鍵を使う）は **x86_64 のコンテナのみで検証**（相手は同じコンテナの 2 つ目の Syncthing）。`systemd-analyze --user verify` はユーザーの systemd の private ソケットを置き換えて `systemctl --user` を壊すので使わない
- `docs/firefox.md` — Mozilla 公式 RPM リポジトリ（`packages.mozilla.org/rpm/firefox`）で最新版の Firefox を入れる手順書。AppStream の ESR 140 から `dnf install` 1 本で載せ替える。**Mozilla の Linux 版は AAC と H.264 を OS の FFmpeg（`libavcodec.so.53`〜`.63`）に頼り、AAC を補う手段は他に無い**ので、手順 9〜12 で RPM Fusion（free）の `ffmpeg-libs` を入れる（RPM Fusion の有効化は前提の rpmfusion.md。もとはこの文書の手順 8〜11 だった）。EPEL の `libavcodec-free` は H.264 を中身の無い `noopenh264` に回して再生に失敗するので採らず、入っていれば手順 10 で `--allowerasing` で入れ替える。本体の場所は `/usr/lib/firefox`（AppStream 版は `/usr/lib64/firefox`）。手順 1〜8 は実機で本実行済み、手順はコンテナで再実行して確認。手順 9〜12 も、RPM Fusion の有効化と合わせて実機で本実行済み（2026-09-28。aarch64 の実機は利用者が再生を確認し、headless の Firefox を Marionette で動かして about:support と AAC・H.264 の再生も確かめた）。**x86_64 の実機（AMD のノート PC）でも同じ日に本実行した**。YouTube が 360p から上がらず、音声が AAC だけの動画が再生できなかったホストで、起動し直した Firefox の画面で利用者が 2 本の動画の再生を確かめた。headless の Firefox でも、音声が AAC だけの YouTube の動画が VP9 1080p60 + AAC で再生された。OpenH264 があるのに利用者の Firefox で H.264 が使われなかった理由は未特定。`ffmpeg-libs` は EPEL の `noopenh264` も依存で入れるが、H.264 は FFmpeg 自身のデコーダで復号される
- `docs/claude-code.md` — 公式 dnf リポジトリの `latest` チャンネル（`downloads.claude.ai/claude-code/rpm/latest`）から最新版の Claude Code を入れる手順書。Node.js 不要。`CC_CHANNEL` で `stable` も選べ、入れた後の `stable` への切り替え（版が下がるので `distro-sync`）を任意節に置く。`stable` は実機で本実行済み（認証も済み）。**既定の `latest` は x86_64 のコンテナのみで検証**（手順 1〜4・更新・切り替え・ロールバックを文書のコードブロックのまま通した）
- `docs/gh.md` — 公式 dnf リポジトリ（`cli.github.com/packages/rpm`）から gh を入れる手順書。EPEL 版は 2.97.0 と古い。実機で本実行済み、手順 1〜3 はコンテナで再実行
- `docs/git.md` — git 本体と `global` の基本の設定の手順書。**AlmaLinux 10 と Windows 11 の Git for Windows が対象**で、Windows では Git Bash に同じ bash のブロックを貼る（手順 2 の `dnf install` だけ飛ばす）。git は AppStream の RPM（Homebrew は 2.55.0 で新しいが、gh などが RPM の git に依存する）。変数は必須の `GIT_USER_NAME` / `GIT_USER_EMAIL` だけで、既定は空（手順 4 の `if [ -z … ]` で止める）。依頼で決めた 3 つ（`pull.rebase true`・`rebase.autoStash true`・`core.autocrlf false`）と推奨の 9 つ（`init.defaultBranch main`・`core.quotepath false`・`fetch.prune`・`push.autoSetupRemote`・`rerere.enabled`・`merge.conflictStyle zdiff3`・`diff.algorithm histogram`・`branch.sort -committerdate`・`tag.sort version:refname`）を `git config --global` で書き、`system`（Windows はインストーラが書く `C:/Program Files/Git/etc/gitconfig`）は変えない。**`system` に `pull.ff=only` があると `pull.rebase=true` でも分岐した pull が止まる**ので、手順 7 で `--show-scope --get` の出どころを見て、手順 8 で `global` の `true` で上書きする。使い捨てのリポジトリ（`mktemp -d`）で CRLF・`main`・日本語のファイル名・最初の push・rebase と autostash を確かめる。後ろの節で、`core.autocrlf=true` のときに clone したリポジトリを `git rm -r --cached .` と `git reset --hard` で書き直す（未コミットの変更は `git -c core.autocrlf=true stash` で退避。`git checkout-index --force --all` では `M` が残った）。`merge.conflictStyle` は git-delta.md と共有。**x86_64 のコンテナのみで検証**（`/etc/gitconfig` に Git for Windows のインストーラの選択で書かれうる値と `pull.ff=only` を置いた模擬を含む）。Windows の Git Bash・実機・aarch64 は未確認
- `docs/homebrew.md` — Homebrew 本体を入れる手順書。以降の Homebrew 系 15 本の前提で、各手順書は `## 実施手順` のリード文からここへ誘導し、変数の設定（手順 1。変数の無い文書には無い）の次の手順から各ツールの導入が始まる。インストーラの `Next steps` の実測と `brew` の基本操作もここに集約した。任意節「root のシェルでも使う」は、`/root/.bashrc` に 1 行足して PATH の**末尾**に `/home/linuxbrew/.linuxbrew/bin` と `sbin` を足す（`su -`・root のログイン・`sudo -i`・`sudo -s` で使える。RPM と同じ名前なら RPM が先。`brew shellenv` は先頭に足し、root のシェルを開くたびに利用者の所有する `brew` を動かすので使わない。`sudo <コマンド>` は `secure_path` のままで対象外。`brew install` などは root では断られる）。実機で本実行済み（2026-09-20）、手順はコンテナで再実行。任意節は **x86_64 のコンテナのみで検証**（2026-09-30。`su -`・`su`・ssh での root のログイン・`sudo -i`・`sudo -s` を確認。コンソールでのログインと実機は未確認）。インターネットに出られないホストでは homebrew-offline.md から通す（`> [!IMPORTANT]` と更新・ロールバックのリードで案内）
- `docs/homebrew-offline.md` — インターネットに出られないホスト（オフラインのホスト）で Homebrew を使う手順書。出られるホスト（オンラインのホスト）から `ssh -o ExitOnForwardFailure=yes -o ControlPath=none -R 1080` でログインすると、オフラインのホストの `127.0.0.1:1080` に SOCKS の待ち受けができる（OpenSSH 7.6 以上の逆向きの動的転送。出口はオンラインのホスト）。それを `export ALL_PROXY=socks5h://127.0.0.1:1080` で curl・git・brew に使わせ、手順 5 で homebrew.md の手順 1〜4 をそのシェルのまま貼る（`h` を外すと名前解決がオフラインのホストで行われて失敗する）。`sudo` は `ALL_PROXY` を渡さないので、足りないパッケージがあるときだけ、手順 4 で `/etc/dnf/dnf.conf` の `[main]` に `proxy=socks5h://127.0.0.1:1080` を `sed` で足す（`dnf config-manager` は実機に無いことがあった。ロールバックで消す）。変数はオンラインのホストの `OFFLINE_HOST`（必須）と `OFFLINE_USER`（既定 `${USER}`）だけで、ポートは固定。最後に転送無しでログインし直し、jq が動いて curl が外に届かないことを確かめる。ほかの Homebrew 系の手順書も、手順 1〜3 でトンネルを張ったシェルで貼る（Homebrew 系 15 本の数には入れない）。**x86_64 のコンテナのみで検証**（Docker の `--internal` のネットワークだけにつないだコンテナをオフラインのホストにし、別のコンテナから ssh した）。実機・aarch64・SELinux が Enforcing のホストは未確認。Homebrew 7.0.7 の `brew install` は、端末では依存が付くときに `[y/n]` を 1 文字で読むので、手順 6 は `brew install jq` だけにしてある
- `docs/yazi.md` — yazi を Homebrew で入れる手順書。COPR `lihaohong/yazi` を実機で一度入れて外した経緯と、プレビュー依存（ffmpeg など）が EL10 に揃わないことを補足に残す。`y()` シェル関数まで含む。「設定ファイル」の節から自分用の設定（`ryo-aoki-pc/yazi`）の README へリンクで案内する（clone のコマンドは載せない）
- `docs/lazygit.md` — lazygit を Homebrew で入れる手順書。COPR（`dejan` / `atim`）は `epel-10-aarch64` の repomd が 403 で入らないことを実機とコンテナの両方で確認して不採用にしている。「設定ファイル」の節から自分用の設定（`ryo-aoki-pc/lazygit`）の README へリンクで案内し、その設定を使うなら手順 1 の `cat >>` を貼らない（`os:` が 2 つになる）と書いた
- `docs/neovim.md` — Neovim を Homebrew で入れる手順書（EPEL は 0.10.1 と古い）。`:checkhealth` の読み方と、`sudo nvim` が使えない理由を補足に置く。「設定ファイル」の節から自分用の設定（`ryo-aoki-pc/LazyVimStarter`）の `docs/setup.md` へリンクで案内する（Homebrew と Neovim の導入もそちらに含まれる）
- `docs/zoxide.md` — zoxide を Homebrew（既定。手順 2）か、x86_64 なら COPR `kray74/cli-tools` の dnf（手順 3〜5）で入れる手順書。EPEL にも AppStream にも Terra にも RPM が無く、EL10 向けは COPR だけ（候補の比較は「選択した方針」）。dnf の経路は `dnf config-manager --save --setopt=…includepkgs=zoxide,fzf` で COPR から入るものを絞る（同じ COPR の chezmoi などが EPEL の同名パッケージを置き換えないように）。`~/.bashrc` の `eval "$(zoxide init bash)"` が本体で、`--cmd cd` の影響範囲も補足に書く。zoxide はプロンプトを出すときに今のディレクトリを記録し、ホームは記録しないので、確認は `cd /usr/share`（手順 7）と `zoxide query --list`（手順 8）の 2 回に分けて貼る（`cd ~` で終わる旧版の 1 つのブロックは、ブラケットペーストの有無にかかわらず空だった）。Homebrew の経路は実機で本実行済み。**dnf の経路は x86_64 のコンテナのみで検証**（手順 1・3〜8、更新とロールバックの dnf の手順）
- `docs/bat.md` — bat を Homebrew で入れる手順書。EPEL は 0.24.0 で古い。`alias cat=bat` は勧めず、`~/.config/bat/config` と `MANPAGER` の使い方だけ案内する。**コンテナのみで検証（実機未導入）**
- `docs/eza.md` — eza を Homebrew で入れる手順書。EPEL にも AppStream にも RPM が無い（`exa` も無い）。`ls` は置き換えず `ll` / `la` / `lt` を足す形にしてある。非対話シェルでは `type -t` がエイリアスを見つけられないことも補足に書く。**コンテナのみで検証**
- `docs/git-delta.md` — git の差分表示を delta にする手順書。formula 名は `git-delta`、バイナリは `delta`。設定は `git config --global` で `~/.gitconfig` に書く（git がキー名を小文字に正規化するので読み戻しの正規表現に注意）。lazygit の `git.paging` 連携は任意節。**コンテナのみで検証**
- `docs/gdu.md` — gdu を Homebrew で入れる手順書。**brew 版の実行ファイルは `gdu-go`**（coreutils との衝突回避）。EPEL には 5.32.0 の `gdu` がある。実機には同じ brew 版 5.37.0 が 2026-09-21 から入っているが、本書の通し検証はコンテナのみ
- `docs/btop.md` — btop を EPEL の dnf で入れる手順書。**Homebrew と同じ版なので EPEL の RPM を選んだ手順書**（EPEL と Homebrew がどちらも 1.4.7。`docs/tool-catalog.md` では fastfetch などもこの規則で EPEL にしている。image-tools.md の Trivy も同じ規則で公式の dnf リポジトリ。distrobox・podman-compose・podman-tui の EPEL は、版ではなく podman と組むため）。変数は無く、前提は epel.md（もとは手順 1〜3 が EPEL の有効化だった）。**コンテナのみで検証**
- `docs/shellcheck.md` — ShellCheck と shfmt を Homebrew で入れる手順書。**この CLAUDE.md の「よく使うコマンド」が前提にしている `shellcheck` の導入元**。EPEL にも 0.10.0 があるが**パッケージ名が大文字の `ShellCheck`** で 1 マイナー古く、shfmt は RPM がどこにも無いので両方 Homebrew に揃えた。`wg-vpn.sh` を 0.11.0 で検査した実測を手順 4 の補足に置く（**SC2034 が 1 件出たので同じ変更で `wg-vpn.sh` の未使用変数 `MY_LAN` を消して 0 件にした**。`-x` はこのスクリプトでは結果を変えない）。`shfmt -w` はリポジトリのファイルに掛けず、一時ディレクトリの複製で確認している。実機で本実行済み、手順はコンテナで再実行
- `docs/vscode.md` — Microsoft 公式 dnf リポジトリ（`packages.microsoft.com/yumrepos/vscode`）から VS Code を入れる手順書。rpm の release は `.el8` 固定だが、これは**MS が EL 共通に 1 本だけ出している**ためで WezTerm の EL9 流用とは事情が違う。`~/.config/code-flags.conf` が読まれないことも実測で書いた。実機で本実行済みで、デスクトップの端末からの GUI 起動まで確認した。**ただし TTY もディスプレイも無いシェルからは 6 通り試して起動できず**、その記録を付録に残してある。コンテナでは依存解決のみ
- `docs/starship.md` — プロンプトを starship にする手順書。`~/.bashrc` の `eval "$(starship init bash)"` が本体。zoxide の初期化より後ろに置き、WezTerm のシェル統合が `PS1` に足す OSC 133 の A/B マーカーは starship に上書きされる（init スクリプトを読んだ上での推定、実挙動は未検証）。**コンテナのみで検証**
- `docs/hackgen.md` — プログラミング用フォント HackGen Console NF を Homebrew の cask `font-hackgen-nerd` で入れる手順書。**Linux の Homebrew は font の cask を `~/.local/share/fonts` に置く**（cask の定義は macOS の `~/Library/Fonts` しか示さないので実測で確かめた）。cask の展開に `unzip` が要り、Homebrew のインストーラも `homebrew.md` の依存パッケージも入れないので、変数の設定（手順 1）の次の手順 2〜3 を `unzip` の用意にしてある（使うのは hackgen.md だけなので、epel.md のような前提の手順書にはしていない）。NF 版の zip には Console の 2 ファミリー（`HackGen Console NF` / `HackGen35 Console NF`）しか無い。確認は `fc-list` / `fc-match` / `fc-list :charset=` と、任意節の `wezterm ls-fonts --text`。**x86_64 のコンテナのみで検証**（flatpak.md と同じ Docker の環境）。見た目は未確認
- `docs/flatpak.md` — AppStream の flatpak に Flathub を system で登録する手順書。**GUI アプリにとっての `docs/homebrew.md`** で、今のところ `docs/tool-catalog.md` の GUI の Flathub 行だけがこれを前提にしている（Firefox / VS Code は Flathub を採らず RPM）。入れた直後の `flatpak remotes` がエラーを出すこと、確認が 2 回あること、最初の 1 本で `/var/lib/flatpak` が 2.5 GB になることを書いた。**x86_64 のコンテナのみで検証**（クラウドホスト上の Docker、`--privileged`。これまでの「実機上の podman」とは別の環境）。画面の表示は未確認
- `docs/epel.md` — EPEL を有効にする手順書（extras の `epel-release`）。**EPEL の RPM を使う 5 本（btop・distrobox・podman-compose・podman-tui・VirtualBox）と rpmfusion.md の共有前提**で、各手順書は `## 実施手順` のリード文からここへ誘導する（もとは btop.md などの中に同じ 3 つの手順があった）。変数は無く、手順は「有効か確かめる → `sudo dnf install -y epel-release` → 有効になったか確かめる」。EPEL の鍵は先に取り込まず、最初に EPEL のパッケージを入れる手順で dnf が 1 回聞く（fingerprint は手順 3 にあり、使う側の導入の手順にも書く。`dnf upgrade epel-release` で extras の `10-6` から EPEL の版に上がるときにも聞かれた）。ロールバックの `dnf remove` は `--noautoremove` を付け（付けないと `dnf-plugins-core` も消える）、RPM Fusion が入っていれば `rpmfusion-free-release` も一緒に消えるので、先に rpmfusion.md のロールバックを行う。**手順 2 はコンテナのみで検証**（手順 1・3 は x86_64 の実機でも通した。2026-09-29 に x86_64 のコンテナで、更新・ロールバックと rpmfusion.md との組み合わせを通した）
- `docs/rpmfusion.md` — RPM Fusion（free）を有効にする手順書。前提は epel.md（`rpmfusion-free-release` が `epel-release` を要求し、RPM Fusion の Configuration も EPEL を先に有効にする順）。鍵を `gpg --show-keys` で照合してから `rpm --import` し、`--setopt=localpkg_gpgcheck=1` で `rpmfusion-free-release` を入れる（Configuration の `--nogpgcheck` は採らない）。firefox.md の手順 9〜12（`ffmpeg-libs`）の前提（もとは firefox.md の手順 8〜11）。nonfree は扱わない。**手順 1〜4 は実機で本実行済み**（2026-09-28、aarch64 と x86_64。記録は firefox.md の付録）。手順 5 とロールバックはコンテナのみ（2026-09-29）
- `docs/virtualbox.md` — Oracle 公式 dnf リポジトリ（`download.virtualbox.org/virtualbox/rpm/el/10/x86_64`）から VirtualBox 7.2 を入れる手順書。**x86_64 のみ**（Linux の arm64 版が無い）で、パッケージ名に系列が入る（`VirtualBox-7.2`）。依存の `liblzf` が EPEL にしか無いので、前提は epel.md（もとは手順 2〜4 が EPEL の有効化だった）。メタデータにも署名がある（`repo_gpgcheck=1`）ので、鍵の確認を `sudo` 付きと無しの dnf で 1 回ずつ通す（通さないと `sudo` 無しの dnf が無関係なパッケージでも失敗する）。rpm の `%post` がモジュールをその場でビルドし、**失敗しても `Complete!` で終わる**ので、ビルドの道具（`perl` ではなく `perl-interpreter` で足りる）と Secure Boot の MOK（鍵は `/var/lib/shim-signed/mok/MOK.{der,priv}` 固定、判定は `mokutil --sb-state` だけ）をインストールより先に用意する。EL10 の 6.12 系カーネルでは VirtualBox の KVM 共存の仕組み（6.16 以上だけ）が効かず、kvm.ko も既定で読み込み時に VT-x / AMD-V を取るので、`options kvm enable_virt_at_load=0` を modprobe.d に置く。系列の切り替えは remove → install（`dnf swap` は新しい系列のモジュールと設定を消した）。**実機で本実行済み**（2026-09-28〜29、AMD のノート PC）。ただし Secure Boot が有効な分岐は、手順 14 の MokManager でキーボードが効かず鍵を登録できなかったので、Secure Boot を無効にして無効の分岐で最後まで通した（モジュールの読み込み・`vboxdrv.service`・`enable_virt_at_load=0` の効き目・VM の起動・XWayland で開く GUI を確認。KVM が AMD-V を取っていると `VERR_SVM_IN_USE` で起動に失敗することも実物で見た）。MokManager の最初の画面は 10 秒で消え、手順 15 の `mokutil --test-key` は `sudo` が要る（鍵のディレクトリが 0700）。署名したモジュールの受け入れ・カーネル更新・更新・ロールバックは実機では未検証（手順はコンテナで通した）
- `docs/virtualbox-guest-bootc.md` — VirtualBox の VM で動く AlmaLinux Atomic Desktop（GNOME の bootc イメージ。公式の ISO で入れると `quay.io/almalinuxorg/atomic-desktop-gnome:latest` を追うので、`BASE_IMAGE` の既定も `:latest`）に Guest Additions を入れる手順書。**dnf でも `.run` の直接実行でも入らない**（`/usr`・`/opt` が読み取り専用で、EL10 のカーネルにも AppStream・EPEL 10・ELRepo にも vboxguest が無い）ので、ホストの「Guest Additions CD イメージの挿入」の `VBoxLinuxAdditions.run` を VM の上で `sudo podman build` する派生イメージに焼き込み、`bootc switch --apply --transport containers-storage` で切り替える。インストーラをビルドの中でそのまま動かすと bootc では 4 か所が困るので、Containerfile で直す（systemd が PID 1 でないと SysV のスクリプトしか置かない → 同梱の `routines.sh` の `systemd_wrap_init_script` で unit を作って enable、`/var/lib/VBoxGuestAdditions/config` は `/usr/share/factory` と tmpfiles の `L+`、ユーザーとグループは sysusers.d、カーネルの版は `TARGET_VER`）。Secure Boot のときは `/var/lib/shim-signed/mok/` の鍵を `--secret` で渡して `sign-file` で署名し（`ARG MOK_SIGN` でキャッシュを分け、鍵を作り直したら `--no-cache`）、MokManager で登録する。切り替えた後は `bootc upgrade` だけでは OS が上がらない（ビルドし直す）。任意の変数は `BASE_IMAGE` だけ。RUN は `set -x` でコマンドを `+` 付きで表示し、最後の結果の行の前で `set +x` にする。カーネルの版はイメージの `/usr/lib/modules` から取り、道具は `kernel-devel-uname-r = <版>` の指定で入れる（dnf の `--repo` は付けず、イメージで有効なリポジトリを使う。自作の kernel-rt のイメージは版の末尾が `+rt` で、`kernel-rt-devel` は `rt` のリポジトリにしか無いので、そのイメージで `rt` を有効にしておく）。**イメージに `libXt` も入れる**（GNOME のセッションでは VBoxClient が XWayland の経路で `libXt.so.6` を `dlopen` し、無いと `--clipboard` が SIGTRAP で 5 秒ごとに落ち続けた）。元のイメージに戻す `bootc switch` には `--enforce-container-sigpolicy` を付けない（Atomic Desktop の `policy.json` の既定が `insecureAcceptAnything` で断られる。付けなくても署名は `policy.json` どおりに確かめられた）。GNOME は CD を入れても何も表示しない（EL10 の `autorun-never` の既定が true）。**VirtualBox の VM で本実行済み**（2026-09-29。x86_64 の実機の VirtualBox 7.2.20 の上で、公式の ISO で入れた VM、Secure Boot 有効。ホスト側のメニューの操作は、同じ働きの `VBoxManage` で行った）。MokManager での登録と削除（見送ったときの失敗も）、`bootc switch`・`upgrade`・`rollback`、モジュールの読み込み、VBoxService の時刻の同期、VBoxClient のクリップボード（両方向）と画面の大きさ、共有フォルダーを確認した。それ以前にコンテナでも検証済み。`set -x` と kernel-rt の対応は VM の後に足したもので、x86_64 のコンテナ（クラウドホスト上の Docker）で手順 1・3〜5・7・8 を通した後、同じ実機の VirtualBox の VM で、検証用の kernel-rt のイメージに切り替えてから通した（2026-09-29。kernel を入れ替えたイメージをホストの rootless の podman で作り、`127.0.0.1:5000` のレジストリに置いて NAT の `10.0.2.2:5000` から取り込んだ。Secure Boot 無効で手順 1〜12、有効で手順 1〜13・共有フォルダー・更新〔ベースとカーネルが新しくなる場合も〕・ロールバック、切り替えた直後の `bootc rollback`）。**kernel-rt では、起動のたびに `vboxguest` の読み込みの直後にカーネルの WARNING（`rcu_sched_clock_irq`）が 1 回出る**（Guest Additions の働きには影響が見えない）。カーネルも新しくなる更新では `installer exit=1`。スナップショットに戻しても VM の NVRAM の Secure Boot は戻らなかった（`modifynvram` で戻した）。GUI のメニューそのもの・KDE / COSMIC・直した Containerfile の既定のカーネルでの VM 実行・認証の要るレジストリは未検証
- `docs/gnome-power.md` — GNOME の画面オフ・画面ロック・自動サスペンドを止める手順書（既定は「画面を消さない・ロックしない・眠らない」で、`IDLE_DELAY` などの変数で変えられる）。自分のセッションは `gsettings`（`idle-delay`・`lock-enabled`・`idle-dim`・`sleep-inactive-*-type`・`power-button-action`）、ログイン画面は dconf の `/etc/dconf/db/gdm.d/90-power` と `dconf update`（RHEL の gdm のプロファイルは `system-db:gdm` を読む）、OS 全体は sleep 系の target 5 つの `systemctl mask`、蓋は logind のドロップインで変える。**gdm 47 のログイン画面は電源のキーを持たないので、Workstation で入れた PC はログイン画面のまま 15 分で眠る**（Server with GUI は override で眠らないが、その電源ボタンの行は引用符が無くて効いていない）。dconf のファイルの文字列は引用符で囲み、uint32 は `uint32 0` と書く（引用符が無いと `dconf update` が失敗し、`uint32` が無いと黙って無視される）。`idle-delay` が 0 でも `idle-dim` が true だと 60 秒で暗くなる。**x86_64 のコンテナのみで検証**（`dbus-run-session` のコンテナと、systemd を PID 1 にして `/sys/power` を tmpfs に差し替えたコンテナ。mask で `CanSuspend` が `"yes"` から `"no"` になる）。画面・実際のサスペンド・蓋は未検証
- `docs/japanese-input.md` — GNOME で日本語を入力する手順書。EL10 には Mozc の RPM が無い（EPEL 10 にも COPR にも無い）ので、AppStream の `ibus-anthy`（RHEL 10 の文書が日本語用に挙げるエンジン）を使う。入力ソースを `[('xkb', '<配列>'), ('ibus', 'anthy')]` にして Super+Space で切り替え、配列は `localectl status` から自動で取る。`ibus-anthy` を入れた後は、ibus-daemon が読み直すまで使えないのでログインし直す。**x86_64 のコンテナのみで検証**（IBus の API にキーを送り、`nihongo` →「日本語」と半角/全角キーの切り替えを確認）。画面とアプリでの入力は未検証
- `docs/dropbox.md` — x86_64 の PC で Dropbox の公式クライアントを headless で動かす手順書。**公式 RPM（`nautilus-dropbox`）は EL10 に入らない**（`libgnome` が AlmaLinux 10 にも EPEL 10 にも無く、`%post` が置く `.repo` も `$releasever` が 10 で 404）ので、公式の tarball を `gpgv` で署名を確かめてから `~/.dropbox-dist` に展開し、`dropbox.py` を `~/.local/bin/dropbox` に置く。**`download?plat=lnx.x86_64` は呼ぶたびに版を振り分ける**ので、飛び先を 1 回だけ引いて tarball と `.asc` を落とす（2 つの URL を別々に引くと版が食い違い、`BAD signature` になった）。常駐は自分で書くユーザーサービス（`Restart=always`・`UnsetEnvironment=DISPLAY WAYLAND_DISPLAY`）と linger。変数は無い。**x86_64 のコンテナのみで検証**（リンク用の URL が出るところまで。検証のときだけサービスにプロキシを渡した）。アカウントのリンク・リンク後の同期・自己更新は未検証
- `docs/dropbox-rclone.md` — Raspberry Pi 5（aarch64。Dropbox の公式クライアントが無い）で、Homebrew の rclone の `bisync` を systemd のユーザータイマーで 15 分ごとに回し、`~/Dropbox` と Dropbox を双方向同期する手順書（Homebrew 系の 1 本）。`rclone config create` は登録が終わるとトークン入りの設定を標準出力に出すので `>/dev/null` を付ける。フィルタのファイル（`~/.config/rclone/dropbox-filters.txt`）はいつも `--filters-file` で渡し、変えたら `--resync`。強制終了で残る書きかけ（`*.partial`）が次の回で上がったので、フィルタの既定に `- *.partial` を入れた。変数は無い。**x86_64 のコンテナのみで検証**（OAuth は URL が出るまで、手順 4 以降は `alias` の代役のリモート）。aarch64 はボトルがあることだけ確かめた
- `docs/podman.md` — AppStream の podman を自分のユーザー（rootless）で使う手順書。**コンテナ系の手順書（distrobox・podman-compose・image-tools・podman-tui・lazydocker）の共有前提**で、各手順書は `## 実施手順` のリード文からここへ誘導する。subuid / subgid の確認（無ければ登録済みの範囲の後ろから計算して割り当てる）、`podman info` の要点、完全な名前のイメージ（`quay.io/podman/hello`）での確認、API ソケット（`podman.socket`、手順 8）まで。任意節は `DOCKER_HOST`（Docker の API を使うツール用。lazydocker.md の前提）と Quadlet（linger と `~/.config/containers/systemd/*.container`。生成された unit には `systemctl --user enable` を使えない）。`sudo -iu` で切り替えたシェルには `XDG_RUNTIME_DIR` が無く `systemctl --user` が失敗する（`su -` は動いた）。**x86_64 のコンテナのみで検証**（`10-init` を `--privileged` で立てて systemd を PID 1 にし、入れ子の rootless podman を SSH のログインシェルから動かした。cgroup v2 に pids のコントローラが無いので、検証環境だけ `containers.conf.d` で PID 数の制限を外した。再起動は中の `sudo systemctl reboot` と `docker start`）。SELinux の `:Z` と資源の制限は未検証
- `docs/distrobox.md` — EPEL の distrobox で Ubuntu 24.04 のボックス（`quay.io/toolbx/ubuntu-toolbox:24.04`）を作る手順書。前提は podman.md と epel.md（もとは手順 2〜4 が EPEL の有効化だった）。`distrobox enter` は動いている間に貼った行をボックスへの入力として取り込むので、`enter` で終わる手順はそこで止める。任意節で、AppStream・EPEL に無い ffmpeg を apt で入れ、`distrobox-export --bin` でホストから呼ぶ。ボックスは `--privileged`・`label=disable` で、ホーム・ネットワーク・プロセスをホストと共有する（隔離ではない）。**x86_64 のコンテナのみで検証**（distrobox が渡す `--pids-limit=-1` を、検証環境だけ podman のラッパーで読み替えた）
- `docs/podman-compose.md` — EPEL の podman-compose で compose ファイルを動かす手順書。前提は podman.md と epel.md（もとは手順 1〜3 が EPEL の有効化だった）。確認用の `compose.yaml` は、`ubi10/httpd-24` を 127.0.0.1:8081 で公開する `web` と、サービス名で届くかを確かめる `check`（`init: true` が無いと `down` が 10 秒待つ）。`podman compose` は docker-compose が入っていればそちらを優先する（podman の `man podman-compose`）。`podman-compose exec` は `-T` でも標準入力につながるので、手順の最後に置く。常駐は podman.md の Quadlet へ誘導する。**x86_64 のコンテナのみで検証**
- `docs/image-tools.md` — イメージの検査の道具 3 つの手順書（hadolint・dive は Homebrew、Trivy は公式の dnf リポジトリ `aquasecurity.github.io/trivy-repo`。Trivy は Homebrew と同版なので規則 1 で RPM）。前提は homebrew.md と podman.md（手順 8 のソケットまで。Trivy の `--image-src podman` がソケットを使う。dive の `--source podman` はソケットを使わない）。わざと欠陥のある Containerfile で hadolint を確かめ、`ubi10/httpd-24:10.1` を元に `podman build` したイメージに dive と Trivy を当てる。dive の `--ci` は、既定の基準ではベースイメージの層の無駄で `FAIL` になる。Trivy の鍵は `825A D903 … 4FD9 CA9F`（自己署名が SHA-256 なので EL10 が取り込める）。**x86_64 のコンテナのみで検証**（dive の TUI は、pty に出た画面の文字を読み取っただけ）
- `docs/podman-tui.md` — podman の TUI（podman-tui）を EPEL の 1.10.0 で入れる手順書。前提は podman.md（手順 8 のソケットまで）と epel.md（もとは手順 1〜3 が EPEL の有効化だった）。**上流の互換表で 1.x は podman 5、2.x は podman 6 向け**なので、Homebrew の 2.0.0 は採らない（接続を podman の設定からだけ読み、podman.md を通しただけの PC では `❌ DISCONNECTED`。`podman system connection add` の後は 5.8.2 でも動いた）。確認用のコンテナ `podman-tui-web` を、`F4` の画面の `m` のメニューの `stop` で止め、`podman ps -a` で `Exited` を確かめる。終了は `Ctrl+C`（`q` では終わらない）。podman に依存せず、ホームにファイルを作らない。**x86_64 のコンテナのみで検証**（実機の rootless の podman の上の `10-init` に、入れ子の rootless podman。subuid は検証環境だけ `1:999`・`1001:64535`。実機の tmux は `capture-pane -p` で落ちるので、擬似端末と pyte で画面の文字を読んだ）
- `docs/lazydocker.md` — lazydocker を Homebrew の 0.25.2 で入れる手順書（RPM は無い）。前提は homebrew.md と podman.md（手順 8 と、Docker 向けの節の `DOCKER_HOST`）。**lazydocker はコンテナの `name` ラベルを名前として出し、UBI のイメージは `name=ubi10/httpd-24` を持つ**ので、確認用のコンテナ `lazydocker-web` に `--label name=lazydocker-web` を付ける（付けないと同じイメージのコンテナが同じ名前で並び、検証では `r` で別のコンテナを再起動した）。`s`（確認あり）で止めて、`podman ps -a` で確かめる。**`E`（シェル）と `a`（アタッチ）は `docker` コマンドを直接呼び、podman だけの PC では何も起きない**ので、任意節で `customCommands` に `podman exec` を足す。compose の枠は、任意節の `dockerCompose: podman-compose` で出る（podman-compose.md が前提）。設定は `cat >>` で足し、同じトップレベルのキーを重ねると後ろだけが効く。`podman-docker` を入れる代案は、選択した方針に実測を置く。**x86_64 のコンテナのみで検証**（podman-tui.md と同じ環境）
- `docs/tool-catalog.md` — **手順書ではなく一覧**。CLI・GUI 約 45 本の推奨導入元・版・導入コマンド・ほかの経路・aarch64 での提供を 1 行ずつ比べ、個別の手順書があるものはそこへ誘導する。選び方は CLI が「RPM が Homebrew と同版以上なら RPM」（podman 本体と podman と組むものは RPM）、GUI が「ベンダーの dnf → AppStream/EPEL → Flathub の検証済み」。x86_64 はコンテナで表の導入コマンドを実行済み、aarch64 は `dnf --forcearch` / Homebrew の JSON / `flatpak remote-ls --arch` のメタデータのみ。版は調査日（2026-09-24。CLI: コンテナと GUI のコンテナの節は 2026-09-27 で、付録も別に足した）の値なので、更新するときは状態行・表・付録の調査日をまとめて直す。行を足す・消す、推奨の導入元を変えたときは README の「手順書の無いツール」の表も直す
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
   - **後ろの節も、貼るコマンドか読者が行う操作があれば同じ形の番号付きリストにする**（節ごとに 1 から数える。コマンドの無い操作は下の「手順の形」）
   - 節の中の並びは「リード（短い箇条書きとアラート）→ 番号付きリスト → `---`」にし、リストの後ろには何も置かない
   - 操作の無い参照の節（表だけの「使い方の基本」など）はリストにしない
   - `##` 見出しは、ほかの文書からアンカーで参照されるので変えない
1. `## 補足` には手順書全体にかかわるものだけを置く: 「対象と検証環境」「実施前の状態」「選択した方針」「完了時点の状態」「注意点」「参照」「付録（検証記録）」。目的、環境表、変数表（「対象と検証環境」の注記）などの背景説明、任意節の補足、複数の手順にまたがる説明（wireguard.md の「スクリプトの動作」など）もここへ。`### 手順の補足` は作らない（1 つの手順だけにかかわる補足は、変数ブロックの補足も含めてその項目の折り畳みへ）
1. **複数の手順書が共有する前提は独立した手順書にし、各手順書は手順に含めず冒頭のリード文から参照する。** 変数の設定（手順 1。変数が無ければ無い）の次の手順は、その手順書の主題（ツールの導入）から始める。Homebrew 系 15 本が `docs/homebrew.md` を、コンテナ系 5 本（distrobox・podman-compose・image-tools・podman-tui・lazydocker）が `docs/podman.md` を、EPEL の RPM を使う 5 本（btop・distrobox・podman-compose・podman-tui・VirtualBox）と rpmfusion.md が `docs/epel.md` を参照しているのがこの形。firefox.md は、手順 9 から先の前提として `docs/rpmfusion.md` を参照する
1. 対話入力（パスワード、`[y/N]`、エディタ・TUI・GUI の起動、再起動）があるコマンドは、**その手順の最後のコマンド**にする。後ろに続くコマンドは次の手順に分け、止める手順の最後の箇条書きを「**次の手順は、〜してから貼る**（続けて貼ると〜として食われる）」にする。続けて貼ると後続行が入力として食われるため。`sudo` のパスワードを聞かれうる手順（その文書で最初の `sudo` で終わる手順など）も、同じ箇条書きで終える
1. `## 実施手順` の直下（手順 1 の前）のリードは箇条書きにする。先頭の `> [!IMPORTANT]` に、実行する場所とユーザーの制約・前提の手順書・対話入力のある手順・別の場所で行う手順を挙げる（どれも無い文書には置かない）。続けて、読み方（上から順に貼る、折り畳みは読まなくてよい）と手順の後ろの節への案内を箇条書きで置く

#### 手順の形

手順（`## 実施手順` と、その後ろの節の番号付きリストの項目）は、次の 4 つをこの順に置く。コマンドの無い手順（下の「コマンドの無い操作」）は、コマンドを除いた 3 つを置く。

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
  - 説明の直後に置き、ブロックの間に何も挟まない。コマンドの無い手順には置かない
  - 並べてよいのは「1 変数だけのブロック（0 個以上）→ ほかのブロック 1 つ」だけ
  - 言語は bash。手で書き足す設定の断片（lazygit の yaml など）だけは、その言語のブロックでよい
  - Windows で実行する手順（windows-openssh-server.md）のブロックは `powershell` にし、管理者の Windows PowerShell 5.1 に貼る前提で書く。下の `sudo` と `{ }` の規則はかからない。変数の空は `if (-not $X) { Write-Error '…' } else { … }` で弾き、`}` と `else` / `elseif` は同じ行に書く（1 行ずつ読まれると、`}` で終わった行で if 文が閉じるため）
  - git.md は例外で、Windows でも Git for Windows の Git Bash に AlmaLinux 10 と同じ `bash` のブロックを貼る（PowerShell 向けに書き分けない）。Windows だけで飛ばす手順は、1 行の説明に「AlmaLinux 10 のときだけ」と書く
  - `<...>` を含む別マシン用のコマンドは、ブロックにせず箇条書きのインラインコードにする
  - `sudo` の後ろに別のコマンドが続くブロックは、全体を `{` と `}` の行で囲む（中は 2 スペース字下げ。ヒアドキュメントの本文と終端の行は字下げしない）。手順の外の節や tool-catalog.md のブロックも同じ
    - ブラケットペーストが効かないときに貼ると、`sudo`（1.9.17 の `use_pty`）が端末に残った行を読んで捨てる。ヒアドキュメントやパイプから読む `sudo` も、パスワードを聞くときは捨てる（実測は [samba-client.md の付録](docs/samba-client.md#付録-sudo-の後ろの行が失われる条件2026-09-28)）
    - bash は `}` まで読んでから実行するので、捨てられる行が残らない。変数の空を弾くブロックは `if … fi` でもよい（samba-client.md）
    - 目視で確かめてから次を実行するもの（dry-run の後の本番など）は、囲まずに手順（手順の外ならブロック）を分ける
    - 点検は、ブロックを bash が 1 回に読む単位（`bash -n` が通る最小の行のまとまり）に区切り、`sudo` を含む単位の後ろにコメント以外の行が残らないかで見る
- **補足（表示）**
  - 箇条書きだけにする（入れ子は可）。段落・表・コードブロックは置かない
  - 出力例は折り畳みへ移し、箇条書きには判定に要る 1 行だけを引く
  - 「次のブロック」「上の 2 つのブロック」のような位置の言い方はせず、手順番号で言う
- **補足（折り畳み）**: 手順の最後に 1 つまで
- **手順を分けるところ**
  - 止める箇所（上の骨格の対話入力、完了待ち、目視の確認）
  - 別のホストや端末で行う操作
  - コマンドの無い操作（下）
  - 条件付きの操作（「〜なら」「〜ときは」「〜も消すなら」）
  - 別々の操作や確認（太字の小見出しで区切るような）
- **ブロックをまとめるところ**
  - 条件の無いつなぎの文（「値を読み戻して確かめる」「次に〜を確かめる」）だけで分かれるブロックは、コマンドを変えずに 1 つにつなぐ
  - ただし、新しいシェルで貼り直す変数のブロックには、読み戻し以外のコマンドを足さない（貼り直すたびに実行されるため）
- **条件付きの手順**
  - 条件は 1 行の説明に書く。1 つの条件が複数の手順にかかるなら、それぞれに書く
  - 判定する手順の最後の箇条書きに「〜なら、手順 N は飛ばす」と書く
  - 代わりに行う手順は「（この節の手順 1 の代わりに）」と書く。元に戻す手順は最後に置き、「元に戻すときは、」で始める
- **コマンドの無い操作**は、独立した番号付きの手順にする（コマンドのブロックを置かず、1 行の説明 → 補足（表示）→ 折り畳み）
  - 当たるもの
    - 画面の操作: GUI、ブラウザ（ログイン・リンクの承認・Web の設定）、起動途中の画面（MokManager）、VM のウィンドウのメニュー
    - 別のマシン・端末・機器での操作: ルーター、スマートフォン、相手のデバイス、LAN の外へのつなぎ替え、別のマシンにファイルを置く
    - 自分で行う切り替え: ログアウトしてログインし直す、アプリや VM を閉じる、閉じて起動し直す
  - 1 行の説明に、どこで何をするかを書く（「VM のウィンドウのメニューで、Guest Additions の CD を入れる。」「ブラウザで URL を開き、この PC を Dropbox に接続する。」）。メニューの順や押すキーは箇条書きに書く
  - `<...>` を含む別マシン用のコマンドは、箇条書きのインラインコードにする（上の「コマンド」）
  - 「**次の手順は、〜してから貼る**」は、次にコマンドを貼る手順の直前（コマンドの無い手順）の最後に置き、その前のコマンドの手順には置かない
  - 次のものは手順にせず、その手順の箇条書きに書く
    - その手順のコマンドが開いた対話への入力: パスワード・`[y/N]`・エディタ・TUI・開いたウィンドウ・`ssh` や `distrobox enter` の先のシェル（上の骨格の対話入力と同じく、「次の手順は、〜してから貼る」で止める）
    - コマンドが起こしたことの完了待ち（`sudo systemctl reboot` の後に起動してログインし、新しい端末を開く、など）
    - 同じ操作を画面から行う別の方法（「アプリ一覧からでも同じ」）
    - 前提を直して始め直す案内（「〜なら、UEFI で有効にしてから始める」）、任意の後片付け（「要らなければ手で消す」）、次の手順に貼る値の受け渡し（公開鍵の 1 行）
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

出力例・ログ・表の中の値は `<HOSTNAME>` / `<SERVER_IP>` などのプレースホルダで書き、実測出力は変数に置き換えない。`<...>` を含むコマンドは bash のコードブロックに置かず、読者が値を入れるブロックは先頭で変数が空なら中断させる（README「記法」）。手順書のコードブロックは検証目的でも実機で機械的に実行しない。コマンドは実際に実行したものを載せる。パスワード・鍵・トークンは private でも書かない。

### wg-vpn.sh の設計

- **入力は `site.env` 1 ファイル**。両拠点に同じファイルを置く。`select_site A|B` が `SITE_A_*` / `SITE_B_*` から `MY_*` / `PEER_*` を組み立てるので、以降の処理は拠点を意識しない。このホストの LAN 側 IP が `WG_x_LAN_IP` と一致しなければ何も変更せずに止まる
- **変更を伴うコマンドはすべて `run()` を通す**。`--dry-run` はこれで実現しているので、新しい副作用も必ず `run` 経由にする
- **検査してから変更する**。`validate_addresses`（Python の `ipaddress` で形式・重複・包含関係を検査）などの検査に 1 つでも落ちたら何も書かない
- `apply` は冪等。`clients.list` の登録簿から毎回 conf を組み立て直し、firewalld は存在確認してから追加し、最後は常に `systemctl restart`（reload では経路が変わらないため）。旧レイアウト（専用ゾーン + policy）が残っていれば policy → ゾーンの順で消す（逆順だと firewalld の設定が壊れる）
- `PrivateKey` は conf に直接書く。`PostUp` で読み込む方式は reload で鍵が消える
- `firewall-cmd --query-policy` は 2.4.3 に存在しない。存在確認は `--info-policy` の終了コードで行う

スクリプトの挙動を変えたら、`docs/wireguard.md` の「スクリプトの動作」節と `--help`（ファイル冒頭コメントを `usage()` がそのまま表示する）、必要なら README の知見リストも合わせて直す。
