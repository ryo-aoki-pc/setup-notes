# AlmaLinux 10 の初期設定の手順（インストール直後の更新・sudo・SSH・導入元・日本語入力・GNOME・シェルのツール・Git・Firefox・WezTerm・Neovim・AI エージェント）の検証記録

[手順書](../almalinux-setup.md)・[ロールバックと注意点](../extra/almalinux-setup.md)

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 の Workstation を入れた直後の PC で、更新・sudo・ファームウェア・SSH・journal・kdump、導入元（EPEL・RPM Fusion・Flathub・Homebrew）、日本語入力と GNOME の表示・入力、共通の bash 設定とシェルのツールを、1 本の手順で整える。2026-10-10 からは、Git・Firefox・HackGen Console NF・WezTerm・git-delta・Neovim・lazygit・GitHub CLI・yazi・Claude Code・Codex CLI・Grok Build と Codex・Grok のプラグイン、Neovim・WezTerm・lazygit・yazi の自分用の設定も、同じ手順で入れる
- **方式**: 上から順に貼る 152 の手順（27 項）と、任意節・更新・ロールバック。2026-10-08 に、13 本の手順書（epel・rpmfusion・bash-settings・homebrew・flatpak・japanese-input・gnome-power・starship・zoxide・fzf・eza・bat・tmux）をこの文書にまとめた（その時点で 73 の手順・13 項）
  - 2026-10-10 に、さらに 12 本の手順書（git・firefox・hackgen・wezterm-nightly・git-delta・neovim・lazygit・gh・yazi・claude-code・codex・grok-build）の AlmaLinux 10 の部分と、[コーディングエージェントの共同作業](../coding-agents.md)の手順 9・10 を、「Git」から「Codex・Grok のプラグイン」までの 14 項にまとめた（[付録](#付録-12-本の手順書をまとめた記録2026-10-10)）
- **状態**: **2026-10-08 に、x86_64 の VirtualBox の VM（公式 ISO の Workstation のクリーンインストールから新しく作ったもの）で、その時点の 13 項を通した**（[付録](#付録-x86_64-の-virtualbox-の-vm-で通した記録2026-10-08)）
  - **2026-10-10 に足した 14 項・「再起動と確認」の手順 8・ロールバックの 4 項（「AI エージェントとプラグインを消す」から「Firefox を戻す」まで）・更新の手順 5〜9 は、この文書の順番では通していない**。コマンドは、もとの手順書で確かめたものを移した（どこまで確かめたかは、後ろの「統合前の記録」のそれぞれの節）。つなぎを直した手順と新しい順番は、静的な確認だけ（[付録](#付録-12-本の手順書をまとめた記録2026-10-10)）
  - 通したもの: 実施手順の全部（13 項。「OS とファームウェアの更新」の手順 5 と「システムの設定」の手順 4 は条件に当たらず飛ばした）、任意節 11（12 のうち、Claude Code を tmux の中で動かす節を除く）と、starship・bat の設定ファイルの節、更新、ロールバックの全部（5 項。「表示と入力を戻す」の手順 14 と「Homebrew と bash-completion を消す」の手順 4 は条件に当たらず飛ばした）。見つけて直したブロックは、同じ VM か、スナップショットに戻した VM で流し直した
  - 確認したこと: パスワードを聞くのが「ログインと sudo」の手順 3 の 1 回だけ、再起動の後も設定が残る（2 回）、GNOME の画面とキー（時計・ダークモード・ボタン・Ctrl+Alt+T・Alt+Tab・Caps Lock・拡大率・日本語入力・Files）、ロールバックの後に実施前の値へ戻る（最後に sudo がパスワードを聞く）
  - 確認していないこと: 実機・aarch64・Raspberry Pi・Server with GUI、JIS の物理キーボード、Wake on LAN の実際の起動と UEFI の設定、ファームウェアの実際の更新、Claude Code のログインが要る節、インターネットに出られないホスト
- **統合前の記録**: もとの 13 本の検証記録は、この文書の後ろの「統合前の記録」に、中身を変えずに移した（[EPEL](#統合前の記録-epelもとは-epelmd) から [tmux](#統合前の記録-tmuxもとは-tmuxmd) まで）。各節の冒頭に、当時の手順と今の手順の対応表を置いた
  - 2026-10-10 にまとめた 12 本の記録も、同じ形で移した（[Git](#統合前の記録-gitもとは-gitmd) から [Grok Build](#統合前の記録-grok-buildもとは-grok-buildmd) まで）。見出しに Windows 11 を含む節は、[Windows 11 の初期設定の検証記録](windows-setup.md)に移した

> [!NOTE]
> 出力の中の、この VM の値は `<USER>`（試験用のユーザー）・`<HOSTNAME>`（「システムの設定」の手順 2 で変えた名前）・`<OLD_HOSTNAME>`（変える前の名前）で書いた。画面の写真は、試験用の名前のまま撮った。パスワードは載せていない。

| 項目 | 内容 |
|---|---|
| ホスト | Windows 11 Pro、VirtualBox 7.2.20（Hyper-V の NEM のバックエンド） |
| VM | `clean-install` のスナップショット（AlmaLinux 10.2 の Workstation。[AlmaLinux 10 の環境構築の記録](../almalinux-vm-verification.md)と同じベース）からのリンククローン。EFI、2 vCPU、RAM 6 GiB、VMSVGA（1280×800）、NAT と SSH の転送 |
| ゲスト | AlmaLinux 10.2、kernel `6.12.0-211.61.1.el10_2.x86_64`、GNOME Shell 49.4、mutter 49.4、gdm 47.0、Nautilus 47.6、Ptyxis 47.13、fwupd 2.0.19、systemd 257、dnf 4.20.0、SELinux Enforcing、ロケール `ja_JP.UTF-8`、US キーボード |
| 入れたもの | `epel-release` 10-6（後で 10-8）、`rpmfusion-free-release` 10-1、Flatpak 1.16.0 と Flatseal 2.4.1、`gnome-shell-extension-appindicator` 61、Homebrew 7.0.8、starship 1.26.0・zoxide 0.10.0・fzf 0.74.4・eza 0.23.5・bat 0.26.1・tmux 3.7c、共通の bash 設定（`ryo-aoki-pc/bash` の `bdb64c2`） |
| 貼り方 | 文書から抜き出したブロックを、SSH の対話の bash（`xterm-256color`）にブラケットペーストで 1 つずつ貼った。画面の操作は VirtualBox のキーボード（途中から USB タブレットのポインタ）で行い、画面を撮って確かめた |

### 実施前の状態

| 項目 | 値 |
|---|---|
| sudo | `%wheel ALL=(ALL) ALL` だけ（GUI で入れたのと同じく、パスワードを聞く） |
| GNOME | まだ一度もログインしていない。`color-scheme 'default'`、`button-layout 'appmenu:close'`、時計の曜日・秒と電池の % は `false`、`enable-hot-corners true`、`xkb-options @as []`、Alt+Tab は `switch-applications`、`experimental-features @as []`、`favorite-apps` は既定の 7 つ |
| ホームのフォルダー | 無い（最初のログインで日本語の名前で作られた） |
| journal | `/var/log/journal` が無い（揮発） |
| kdump | `enabled`、`crashkernel=2G-64G:256M,64G-:512M`、予約 268435456 バイト、`auto_reset_crashkernel yes` |
| 導入元 | BaseOS・AppStream・extras・CRB。EPEL・RPM Fusion・Flathub・Homebrew は無い |
| パッケージ | `PackageKit-command-not-found`・`ibus-anthy`・`bash-completion`・`git`・`curl`・`unzip` は入っていた |

### 完了時点の状態

- 実施手順の後: 上の項目がすべて手順書の値になり、再起動の後も残った（[付録](#付録-x86_64-の-virtualbox-の-vm-で通した記録2026-10-08)の「再起動と確認」の手順 2〜7）
- ロールバックの後: sudo はパスワードを聞き、GNOME の値・フォルダーの名前（日本語）・journal（揮発）・kdump（有効）・PC の名前は実施前に戻った
  - 戻らないもの（手順書のとおり）: OS の更新、dnf-automatic で上がった 2 つ（`btrfs-progs`・`epel-release`。EPEL を消しても、入れた `btrfs-progs` は残る）、`~/.bash_history.bak`、`~/.config/bash`（共通の bash 設定の控えに戻しただけ）

---

## 付録: x86_64 の VirtualBox の VM で通した記録（2026-10-08）

### 準備（手順書の外）

- `clean-install` からリンククローン `alma10-setup-20261008` を作り、次の 3 つを行ってからスナップショット `prepped` を取った
  - `/etc/sudoers.d/verifier`（ベースの VM で検証のために置いた NOPASSWD）を消した。GUI で入れたのと同じく、sudo がパスワードを聞く
  - 試験用のユーザーに、VM だけのパスワードを付けた
  - 起動の引数を、シリアルのコンソールの無い一般的な形（`rhgb quiet`）に戻した
- 「ログインと sudo」の手順 1 と「再起動と確認」の手順 2 の GDM へのログインは、VirtualBox のキー入力で行った（Tab・Enter・パスワード・Enter）
- 「日本語入力」から「GNOME の表示と入力」までの手順の `gsettings` などのブロックは、画面にログインしたのと同じユーザーの SSH のシェルに貼った（同じユーザーの D-Bus を使うので、画面にすぐ効いた）。効いたことは画面で確かめた
- 「キー操作を試す」の手順 1〜5 のキーは、SSH の端末（`xterm-256color`）にキーの信号を送って確かめた（Ptyxis の窓には送っていない）。fzf の一覧は、端末の出力を pyte で画面に組み立てて読んだ
- **VM の止まり**: ホストの負荷が高いと、起動の途中で VM が 10〜18 分止まった（VirtualBox の `TM: Giving up catch-up attempt at a … lag`。カーネルは `rcu_preempt kthread starved` を出した）。VM を一時停止して再開する（`VBoxManage controlvm … pause` → `resume`）と、すぐに動き出した。手順書の内容とは関係しない

### 実施手順の結果

| 手順 | 結果 |
|---|---|
| 「ログインと sudo」の手順 1・2 | 最初のログインで「ようこそ」が出て、ホームに日本語の名前のフォルダーができた |
| 「ログインと sudo」の手順 3 | このユーザーで初めての `sudo` で、講習の文とパスワードの問いが出た。`正しく構文解析されました` が 3 行と `sudo はパスワードを聞かない`。以後、「Homebrew」の手順 2 の Homebrew のインストーラの `sudo -v` を含め、パスワードを聞かなかった（`verifypw=any` が効いた） |
| 「OS とファームウェアの更新」の手順 1 | 34 パッケージの更新の後に、AlmaLinux の鍵（`0xC2A1E572`、fingerprint `EE6D B7B9 8F5B F5ED D9DA 0DE5 DEE5 C11C C2A1 E572`）の取り込みを聞かれた |
| 「OS とファームウェアの更新」の手順 2・3 | `このリモートを有効にしますか? [Y\|n]:` に `Y`。`更新可能なデバイスはありません`、`No updatable devices`。スナップショットに戻した VM では、起動の直後の 1 回目が `デーモンへの接続に失敗しました: … タイムアウトしました` で、少し待って貼り直すと通った |
| 「OS とファームウェアの更新」の手順 4 | `再起動な必要ありません。`（カーネルは更新されなかった）。「OS とファームウェアの更新」の手順 5 は飛ばした |
| 「システムの設定」の手順 1・2 | `XKB_LAYOUT` は `us` が自動で入った。`変える前: <OLD_HOSTNAME>`・`変えた後: <HOSTNAME>` |
| 「システムの設定」の手順 3 | `enabled`・`active`・`yes`・`yes`（Workstation の既定）。「システムの設定」の手順 4 は飛ばした |
| 「システムの設定」の手順 5 | `drwxr-sr-x+ … root systemd-journal … /var/log/journal`。「再起動と確認」の手順 3 で前の起動のログが読めた |
| 「システムの設定」の手順 6・7 | `enabled`・`268435456`・`crashkernel=…` → 外した後の `args=` に `crashkernel=` が無く、`auto_reset_crashkernel no`。再起動の後の `kexec_crash_size` は `0` |
| 「システムの設定」の手順 8 | `PackageKit-command-not-found` の 1 つだけを消した |
| 「EPEL と RPM Fusion」の手順 1 | `epel-release-10-6.el10` と、弱い依存の `selinux-policy-extra`・`selinux-policy-targeted-extra`（CRB） |
| 「EPEL と RPM Fusion」の手順 2〜5 | 鍵の fingerprint と uid が手順書と一致。`rpmfusion-free-release-10-1` の 1 つだけ。`rpmfusion-free-updates` が有効 |
| 「Flatpak と Flathub」の手順 1〜5 | Flatpak 1.16.0。Flathub の鍵 `6E5C 05D9 79C7 6DAF 93C0 8135 4184 DD4D 907A 7CAE`。Flatseal 2.4.1 は確認が 2 回（runtime と権限）で、ダウンロードは表示の上限の合計で 1.1 GB ほど |
| 「日本語入力」の手順 1・2 | `ibus-anthy-1.5.17` は入っていた。入力ソースは `[('xkb', 'us')]` から `[('xkb', 'us'), ('ibus', 'anthy')]` へ |
| 「GNOME の表示と入力」の手順 1 | 8 つのフォルダーが英語の名前に移り、`user-dirs.dirs` と GTK のブックマークも書き換わった。再起動の後のログインで、名前を聞く窓は出なかった |
| 「GNOME の表示と入力」の手順 2〜9 | どの読み戻しも手順書の値。`experimental-features` は `['scale-monitor-framebuffer', 'xwayland-native-scaling']` |
| 「GNOME の表示と入力」の手順 10・11 | `gnome-shell-extension-appindicator-61` と依存 3 つ。この dnf で EPEL の鍵（`0xE37ED158`、fingerprint `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`）を聞かれた。再起動の後に `状態: ACTIVE` |
| 「GNOME の表示と入力」の手順 12・13 | カスタムのショートカットと `ptyxis --new-window`。Dash は 4 つ |
| 「共通の bash 設定」の手順 1〜4 | 共通の bash 設定の `install.sh` が `~/.bashrc.before-bash` に控えを取った。`. ~/.bashrc` で `__bash_config_loaded` が `1`。`bash-completion-2.11` は入っていた |
| 「Homebrew」の手順 1〜3 | 依存の 4 つは入っていた。インストーラは `Press RETURN/ENTER` を 1 回聞き、パスワードは聞かなかった。Homebrew 7.0.8 |
| 「シェルのツール」の手順 1 | 6 つの依存の一覧の後に `==> Do you want to proceed with the installation? [y/n]` を 1 回聞いた |
| 「シェルのツール」の手順 2〜10 | 開き直したシェルで starship のプロンプト。各ツールの版と確認の出力は手順書のとおり（「シェルのツール」の手順 5・8・9 は、この検証で直した） |
| 「キー操作を試す」の手順 1〜5 | Tab の補完・大文字小文字の無視・↑ の履歴の検索・`autocd`・`cdspell`・`globstar`・Homebrew の補完、Ctrl+R（行が入るだけで実行しない）、Ctrl+T（bat のプレビュー付き）、`**`+Tab、Alt+C（`builtin cd --`） |
| 「tmux を試す」の手順 1〜3 | 緑のステータス行の `[work] 0:bash*`、`[detached (from session work)]`、`[exited]`、`no server running on /tmp/tmux-<UID>/default` |
| 「再起動と確認」の手順 1・2 | 再起動の後のログインで、時計の曜日と秒・電池の %・`en`・ダークモード・Dash の 4 つ。窓に 3 つのボタン |
| 「再起動と確認」の手順 3 | `journalctl --list-boots` に 2 つの起動、`0`、`<HOSTNAME>`、`/home/<USER>/Downloads`、`anthy - Anthy`（画面の端末で。SSH のシェルでは `IBus に接続できません。`）、`状態: ACTIVE`、2 つの実験的な機能 |
| 「再起動と確認」の手順 4 | 設定の「ディスプレイ」の「スケーリング」に 100 %・125 %・133 %（1280×800）。125 % を選び、「適用」→「この表示設定を保存しますか?」の「変更を保存」で、`~/.config/monitors.xml` に `<scale>1.25</scale>`。2 回目の再起動の後も 125 % のまま |
| 「再起動と確認」の手順 5 | テキストエディターで Caps Lock+A が全部を選んだ。Caps Lock だけでは大文字にならない。Alt+Tab は窓ごと。Ctrl+Alt+T は、ログインの直後の 1 回目は効かず（設定のデーモンがまだ動いていなかった）、数秒後には新しい窓を開いた |
| 「再起動と確認」の手順 6 | Super+Space で上部バーが `あ` に。`nihongo` → Space で「日本語」、Enter で確定 |
| 「再起動と確認」の手順 7 | ホームに英語の名前のフォルダーと隠しファイル、フォルダーが先。サイドバーの `Downloads` で `/home/<USER>/Downloads` が開いた |

![上部バー。時計に曜日と秒、右に en と電池の 100%](../images/almalinux-setup/top-bar.png)

![Ctrl+Alt+T で開いた Ptyxis。タイトルバーに最小化・最大化・閉じるの 3 つのボタン](../images/almalinux-setup/ctrl-alt-t-ptyxis.png)

![125 % を適用した後の「この表示設定を保存しますか?」の窓。「設定を元に戻す」と「変更を保存」](../images/almalinux-setup/display-scaling-save.png)

![テキストエディターで nihongo を変換した「日本語」](../images/almalinux-setup/anthy-nihongo.png)

![Files のホーム。Desktop・Documents・Downloads などの英語の名前と、.cache・.config などの隠しフォルダー](../images/almalinux-setup/files-home.png)

### 任意節・更新・ロールバックの結果

| 節 | 結果 |
|---|---|
| SSH を公開鍵だけにする | 試験用の鍵（ホストで作った ed25519）を足し、鍵でログイン → `40-pubkey-only.conf` の後、パスワードは `Permission denied (publickey,gssapi-keyex,gssapi-with-mic).`、鍵は入れた → 戻して `passwordauthentication yes` |
| dnf-automatic | `dnf-automatic-install.timer` の `NEXT` が出た。`ExecStart` は `--installupdates` 付き、`automatic.conf` は `apply_updates = no`・`reboot = never`。手で 1 回動かすと、EPEL の 2 つ（`btrfs-progs`・`epel-release` 10-6 → 10-8）が上がった（鍵は聞かれなかった）。戻して `0 timers listed.` と `true` |
| 画面オフ・画面ロック・自動サスペンド | 手順 1〜5 と、戻す手順 6〜9 の読み戻しは手順書のとおり（`uint32 0`・`false`・`'nothing'`・`masked` が 5 つ・`s "ignore"` → `uint32 300`・`'suspend'`・`static`・`s "suspend"`） |
| Wake on LAN | `LAN_CON`・`LAN_IF` は `enp0s3`。接続の `802-3-ethernet.wake-on-lan` は `magic` になったが、VirtualBox の e1000 は `Supports Wake-on: umbg` なのに `Wake-on: d` のまま（`ethtool -s … wol g` も `netlink error: Operation not supported`）。`systemctl reboot --firmware-setup` で VirtualBox の UEFI の画面が開き、「Continue」で起動した。電源を切っての起動（手順 6・7）は VM ではできないので行っていない。戻して `default` |
| WezTerm と HackGen Console NF | 先に [hackgen.md](../almalinux-setup.md#hackgen-console-nf) の手順 1〜5（2.10.0。`unzip` は入っていた）と [wezterm-nightly.md](../almalinux-setup.md#wezterm) の手順 1〜4（`20261005_054844_37254829`、COPR の鍵 `FD90 9B62 88A8 4250 AD58 020F A698 91C5 CEA2 757D`）を通した。Ctrl+Alt+T で WezTerm が開き、Dash の端末が WezTerm に。Ptyxis は `use-system-font true` で等幅のフォントに従った。戻して既定の値 |
| Homebrew を root のシェルでも使う | root にも共通の bash 設定を入れて（bash の README と同じ 2 行を root で）、`sudo -i` の PATH の先頭に Homebrew、`command -v brew` が出た。bash のロールバックで戻した |
| Homebrew を sudo でも使う | `正しく構文解析されました` の 3 行、`secure_path` の末尾に Homebrew、`sudo bash -c 'type -a bat'` が Homebrew の bat。戻して `/sbin:/bin:/usr/sbin:/usr/bin` |
| starship | プリセット `plain-text-symbols` で 335 行、プロンプトが `>` に。設定ファイルの節の `cat >` は、そのプリセットを置き換えた。常に表示する節で `[username]`・`[hostname]` が足された |
| fzf で fd と bat | fd 10.5.0 は `[y/n]` を聞かなかった。開き直したシェルで `FZF_*` の 4 つ。Ctrl+T の一覧から `.git` の中が消えた（bat のプレビューは、この節の前から出ていた） |
| bat の設定ファイル | 3 行と `/home/<USER>/.config/bat/config` |
| tmux の設定ファイル | 4 行、`mouse on`・`history-limit 50000` |
| Claude Code を tmux の中で動かす | 流していない（VM で Claude のアカウントにログインできない）。統合前の tmux.md の記録を参照 |
| 更新 | `Already up to date.`（bash）、`Already up-to-date.` と空の `brew outdated`（手順 3 は飛ばした）、`Nothing to do.`（Flatpak） |
| ロールバックの「表示と入力を戻す」の手順 1〜13 | どの読み戻しも実施前の値（`'default'`・`'appmenu:close'`・`false`・`@as []`・既定の 7 つのお気に入り・`['background-logo@fedorahosted.org']`・`@a(ss) []`）。設定で 125 % を 100 % に戻してから「表示と入力を戻す」の手順 8 を行った |
| ロールバックの「表示と入力を戻す」の手順 15 | 8 つのフォルダーが日本語の名前に戻り、ブックマークも戻った |
| ロールバックの「シェルのツールと bash の設定を戻す」の手順 1〜8 | `no server running`、履歴の控え。starship を消した後のシェルは、プロンプトのたびに `…/starship: そのようなファイルやディレクトリはありません` を出した（この検証で手順書に書いた）。bash リポジトリの quick-start.md のロールバックで `~/.bashrc` を控えに戻し、開き直したシェルは OS の既定のプロンプトと `HISTSIZE` 1000 |
| ロールバックの「Homebrew と bash-completion を消す」の手順 1〜3 | `brew leaves` は `fd`（任意節の fd。この検証で、その節に戻す手順を足した）。アンインストーラの後に `/home/linuxbrew` が 308K 残った（`etc/` の証明書・openssl・dbus の設定、`lib/ld.so`、`var/lib/dbus`）ので、「Homebrew と bash-completion を消す」の手順 3 で消す形にした |
| ロールバックの「Flatpak・RPM Fusion・EPEL を消す」の手順 1〜8 | Flatseal・runtime 5 つ・Flathub、`rpmfusion-free-release`・その鍵、`epel-release`・その鍵 |
| ロールバックの「システムの設定を戻す」の手順 1〜7 | `PackageKit-command-not-found` を入れ直し、kdump は `auto_reset_crashkernel yes`・`crashkernel=…` が戻って再起動の後に `268435456`。journal は揮発、名前は `<OLD_HOSTNAME>`、`/home/<USER>/ダウンロード`。再起動の後は淡色・時計は時刻だけ・閉じるボタンだけ。最後に `sudo: パスワードが必要です` |

### 見つけて直したこと

- **「OS とファームウェアの更新」の手順 2・3**: `fwupdmgr refresh` は LVFS を有効にするかを聞き、`--assume-yes` を付けても聞いた。`refresh` と `update` を別の手順にした
- **「システムの設定」の手順 5**: 最初の版は `systemd-tmpfiles` を `journalctl --flush` の前に置いていた。新しい VM では `/var/log/journal` が `drwxr-xr-x. root root` のままだった（tmpfiles の `z`・`a+` は、すでにあるものだけを直す。ディレクトリは flush で作られる）。flush の後に移し、スナップショットに戻した VM で `drwxr-sr-x+ root systemd-journal` になることを確かめた
- **ロールバックの「システムの設定を戻す」の手順 3**: 設定を消してから `/var/log/journal` を消すと、動いている journald がすぐに作り直し、再起動の後も `Storage=auto` のままディスクに書き続けた（2 回とも）。先に `journalctl --relinquish-var` を行う形にし、`/var/log/journal` が無くなることを確かめた
- **「シェルのツール」の手順 5**: Alt+C の割り当ては `bind -X` ではなく、マクロとして `bind -s` に出る。`bind -s | grep -F '"\ec"'` を足した
- **「シェルのツール」の手順 8・9**: `rpm -q` の日本語の文と、zoxide の版（0.10.0）
- **「キー操作を試す」の手順 3・4**: `bashrc` と打つと共通の bash 設定の `.config/bash/bashrc` が先頭に来るので `.bashrc` と打つ形に。bat のプレビューは「シェルのツール」の手順 1 の後から出る。`doc/bash` の先頭は `/usr/share/doc/bash/`
- **「再起動と確認」の手順 4**: GNOME 49 の設定の名前は「拡大率」ではなく「スケーリング」。確認の窓は「この表示設定を保存しますか?」と「変更を保存」
- **「再起動と確認」の手順 7**: サイドバーのブックマークは英語の名前（`Documents`・`Downloads`）で出る
- **Wake on LAN の手順 2**: `Wake-on: d` のままのとき（アダプターが受け付けない）を足した
- **fzf の任意節**: bat のプレビューは共通の bash 設定が bat を見つけて入れるので、この節の前から出ている。fd を戻す手順が無かったので足した
- **starship の設定ファイルの節・Homebrew を sudo でも使う節**: 上書きと、root の共通設定が残すものの説明
- **ロールバック**: 「表示と入力を戻す」の手順 8 の前に 100 % に戻すこと（リード）、「シェルのツールと bash の設定を戻す」の手順 3 の後のプロンプトの表示、「Homebrew と bash-completion を消す」の手順 1 の `brew` のフルパス（「シェルのツールと bash の設定を戻す」の手順 7 の後は PATH に無い）、「Homebrew と bash-completion を消す」の手順 2・3 の残ったファイル、「システムの設定を戻す」の手順 6 の `journalctl --list-boots` の見出しの行（`wc -l` は 2 になった。`--no-legend` は `unrecognized option`）
- **手順書の外のリンク**: README の見出しが参考資料へ移っていた bash（読む順番）・lazygit（主な設定内容）・yazi（独自キーバインド）へのリンクを、移った先に直した

### 確認していないこと

- 実機（ノート PC・デスクトップ）、aarch64・Raspberry Pi、Server with GUI、JIS の物理キーボード（半角/全角キー）
- ファームウェアの実際の更新（VM に更新できる機器が無い）、「OS とファームウェアの更新」の手順 5 の再起動（再起動が要る更新が無かった）、「システムの設定」の手順 4・「日本語入力」の手順 1・「共通の bash 設定」の手順 3 と、ロールバックの「表示と入力を戻す」の手順 14・「Homebrew と bash-completion を消す」の手順 4 の入れる・消す側（どれも既にあった）
- Wake on LAN の実際の起動と UEFI の設定の項目、拡大率を高い解像度の実際の画面で見ること
- dnf-automatic のタイマーが翌日に自分で動くこと（手で 1 回動かしただけ）、GNOME Software の設定の画面
- Claude Code を tmux の中で動かす節（アカウントへのログイン）、インターネットに出られないホスト
- 使い方の基本の表（Flatpak・Homebrew・fzf・tmux）と、eza の表示の表は、この検証では流していない（統合前の記録を参照）

### 静的な確認

- 文書から抜き出した 155 の bash のブロックに `bash -n` をかけ、誤りは 0
- `sudo` の後ろに行が続くブロック（`bash -n` が通る最小の単位で区切り、`sudo` の単位の後ろにコメント以外の単位が残るもの）は 0
- ShellCheck 0.11.0（公式の静的なバイナリを VM で使った）で、誤りは 0。警告は、変数だけのブロック（SC2034 が 12）・`. ~/.bashrc`（SC1090 が 2）・`cd`（SC2164 が 2）で、どれも 1 つずつ貼る形のため
- アラートは 5 つで、どれも本文の最上位。コードフェンスは閉じている
- docs の 7 つのサブモジュールの Markdown のリンク（相対と `github.com/ryo-aoki-pc/<リポジトリ>/blob/<ブランチ>/…`）とアンカーを、GitHub の見出しの規則で確かめた
- 共通の bash 設定（`ryo-aoki-pc/bash`）のコメントの直しの後に、VM で `bash -n bashrc install.sh` と `python3 -m unittest discover -s tests`（8 件）が通った

---

## 付録: 12 本の手順書をまとめた記録（2026-10-10）

### まとめたもの

- git・firefox・hackgen・wezterm-nightly・git-delta・neovim・lazygit・gh・yazi・claude-code・codex・grok-build の AlmaLinux 10 の部分（実施手順・後ろの節・更新・ロールバック・注意点）と、[コーディングエージェントの共同作業](../coding-agents.md)の手順 9・10（Node.js・bubblewrap とプラグイン）を、手順書の 14 項・後ろの節・更新の手順 5〜9、ロールバックの 4 項と注意点に移し、もとの文書は消した
- それぞれの Windows 11 の部分は、[Windows 11 の初期設定](../windows-setup.md)に移した（[その検証記録の付録](windows-setup.md#付録-13-本の手順書をまとめた記録2026-10-10)）
- 必須にしたもの: 自分用の設定 4 つ（[ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter)・[ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)・[ryo-aoki-pc/lazygit](https://github.com/ryo-aoki-pc/lazygit)・[ryo-aoki-pc/yazi](https://github.com/ryo-aoki-pc/yazi)。clone のコマンドは載せず、それぞれの導入手順を範囲で名指しする）、もとは任意節の「WezTerm と HackGen Console NF をデスクトップで使う」、Codex・Grok のプラグイン
- 項の順番: 「tmux を試す」の後、「再起動と確認」の前（LazyVimStarter の入力ソースの変更を、「再起動と確認」の再起動でまとめて読み直すため）。git の設定は clone より前、ブラウザ（Firefox）はログインより前、自分用の設定は TUI の確かめより前

### 手順を変えたところ

- 「Git」: もとの手順 2 の `dnf install git` を外した（「Homebrew」の手順 1 で入る）
- 「Firefox」: 手順 5 に、開いている Firefox を開き直す旨を足した。手順 8 の EPEL の鍵の箇条書きを外した（「GNOME の表示と入力」の手順 10 で取り込み済み）
- 「WezTerm」: SSH のセッションから確かめる手順（もとの 5）を外し、自分用の設定を入れる手順 5 を足した。その項より後の TUI の確かめは、WezTerm のタブで行う
- 「git-delta」の手順 4: 差分を `git -C ~/.config/bash show` で出す
- 「Neovim」: もとの手順 2 の `checkhealth` の起動を外し（自分用の設定の退避より前に `nvim` を起動しないため）、LazyVimStarter の「AlmaLinux 10 に導入する」の手順 3〜6・10・11・13〜18 を通す手順 3 と、既定のエディタを確かめる手順 4 を足した。入力ソースは「英語 (US)」と Anthy になる（「日本語入力」の手順 2 の箇条書きと、「再起動と確認」の手順 5・6 を合わせ、IME 連携の確かめを手順 8 に足した）
- 「lazygit」: `LG_EDITOR` を外し、自分用の設定の手順 2 と、`~/.config/bash` で起動する手順 4 を足した
- 「yazi」: 自分用の設定の手順 3 を足し、`. ~/.bashrc` で読み直す代わりに、新しいタブで確かめる
- 「Claude Code」の手順 5: 確認用のディレクトリ `~/claude-sandbox` で起動し、止める箇条書きを足した
- コードの中の「手順 N」は、項の名前と手順番号にした（`中断: 「Git」の手順 1 の …` など）
- 外したもの: WezTerm・Neovim・lazygit の設定ファイルの最小の例、yazi の設定ディレクトリの `mkdir`、HackGen の「WezTerm で使う（任意）」、git-delta の「lazygit と組み合わせる（任意）」（どれも自分用の設定とぶつかる）
- ロールバック: 移したツールは、Homebrew・RPM Fusion・EPEL の上に乗るので、「表示と入力を戻す」より前の 4 項にした。git-delta と Git は `merge.conflictStyle` を共有するので、Git の手順 10 で戻すかを決める。Node.js は、プラグインと自分用の Neovim の設定を外した後に 1 回だけ外す
- LazyVimStarter の導入の ripgrep・fd は、dnf から Homebrew に移した（[ryo-aoki-pc/LazyVimStarter](https://github.com/ryo-aoki-pc/LazyVimStarter) の変更。「yazi」の手順 2 が Homebrew で入れるものと、二重に入れないため）

### 静的な確認

- 環境: x86_64 のクラウドのコンテナ（Linux 6.18）。AlmaLinux 10 の GNOME も仮想化（KVM）も無いので、どのブロックも AlmaLinux 10 では流していない
- 構文: この文書と extra（ロールバックと注意点）の bash のブロック 270 個（まとめるときに書き換えた・足したもの 13 個）に `bash -n` をかけ、誤りは 0
- ShellCheck 0.11.0（公式の静的なバイナリ）: 誤りは 0。警告は、変数だけのブロック（SC2034 が 19）・`. ~/.bashrc`（SC1090 が 2）・`cd`（SC2164 が 12）、情報は空にもなる変数を引用符で囲まない箇所（SC2086 が 4）で、どれも 1 つずつ貼る形のため。書き換えた・足したブロックの指摘は、このうちの SC2164 が 2 と SC2086 が 1
- `sudo` の後ろに行が続くブロック（`bash -n` が通る最小の単位で区切り、`sudo` の単位の後ろにコメント以外の単位が残るもの）は、この文書と extra では 0
- 形: アラートは 4 つ（extra は 2 つ）で、どれも本文の最上位にあり、続けて置いていない。項は 2〜15 手順、番号は `1.`、コードフェンスはすべて閉じている
- リンク: リポジトリの全 .md のリンク 5,508 本（相対リンクと、`github.com/ryo-aoki-pc/<リポジトリ>/blob/…` のリンク）を、手元の各リポジトリの見出しと GitHub の見出しの規則で照合した（main の #122〜#124 と #126 を取り込んだ後）。壊れたものは 0
- 手順の参照: 「<項>の手順 N」「この項の手順 N」などで、N がその項の手順の数を超えるものは 0（この変更の前からある virtualbox-guest-bootc.md の 1 か所を除く）。ブロックの中の中断のメッセージが指す手順は、1 つずつ中身を見た
- 中身: 消した 52 ファイルの箇条書き・表の行・引用・コードブロックが、リポジトリのどこかに残っているかを照合した。記録（検証記録・参考資料）の 26 ファイルは全部残っていた。手順書と extra の 26 ファイルで見つからなかったものは、書き換えたもの（リードの箇条書き・手順の番号・リンクの文字・窓を開く手順）と、上の「手順を変えたところ」で外したものだった。見つけて書き戻したのは、Codex CLI の前提（`CODEX_HOME`・`CODEX_INSTALL_DIR`・`CODEX_RELEASE` を変えない）と、Windows 11 の Grok に sandbox が無いという注意
- ほかのリポジトリ: ryo-aoki-pc/bash・ryo-aoki-pc/wezterm・ryo-aoki-pc/LazyVimStarter（それぞれの PR の作業ツリー）と lazygit・yazi・kvm-container・md-table-excel も、同じ照合でリンクの誤りは 0。共通の bash 設定は `bash -n bashrc install.sh` と `python3 -m unittest discover -s tests`（8 件）が通った
- LazyVimStarter の ripgrep・fd を Homebrew に移したこと: 2026-10-10 に取った AlmaLinux 10 の BaseOS・AppStream と EPEL 10 の repodata では、その導入の手順 3 に残したもののうち EPEL にしか無いのは `wl-clipboard` だけ（EPEL の手順 1・2 は残る）。formulae.brew.sh の API では、`ripgrep` 15.2.0 の依存は `pcre2` だけで、`fd` 10.5.0 には依存が無く、どちらも Linux のボトルがある
- 見直し: サブエージェント 2 つに、この文書と Windows 11 の初期設定（とそれぞれの extra）を読ませ、前提の順番・参照の中身・ロールバックの抜け・リードの一覧を点検させた。見つかったものは、次の節のとおり直した

### 見直しで直したこと

- 「再起動と確認」の手順 8: LazyVimStarter の手順 19 は `o` で行を足すので、閉じるのは `:qa!`（`:qa` は E37 で閉じない）。`/tmp/lazyvim-check.md` が無いとき（`/tmp` を tmpfs にした PC）の箇条書きも足した。AlmaLinux 10 の既定の `/tmp` は tmpfs ではない（`systemd` 257-23.el10_2.2 は `tmp.mount` を有効にするリンクを持たず、`almalinux-release` 10.2 のプリセットも `disable *`）ので、ふつうは再起動しても残る
- 「Neovim」の手順 3: LazyVimStarter の手順 18 は画面を開かない（画面が開くのは手順 17）
- 「GitHub CLI」の手順 3 と、ロールバックの「Git の道具を消す」の手順 6: `gh auth login` の Git の認証の問いに `Y` と答えると、gh が `~/.gitconfig` に Git の資格情報のヘルパーの行を書く。gh を消す前に、その行を外すようにした（もとの gh.md のロールバックにも無かった）
- 「再起動と確認」の手順 6 と、注意点の「Anthy はひらがなで始まる」: LazyVimStarter の設定（「英語 (US)」と Anthy。Anthy の Ctrl+Space・Ctrl+J を外す）では、英字と日本語の切り替えは Super+Space と Neovim の中の `<C-j>`。半角/全角キーで切り替えるという書き方をやめた
- 「日本語入力」の手順 2: 足した入力ソースも「Neovim」の手順 3 で置き換わることを書いた
- ロールバックの「端末とエディタを消す」の手順 10 と `[!CAUTION]`: 「yazi」の手順 2 の Symbols Nerd Font も `~/.local/share/fonts` に入るので、そのときの `ls` の出方と、Homebrew ごと消すときの順番を書いた
- 「WezTerm の設定ファイル」と注意点: 公式の Bash 統合（`/etc/profile.d/wezterm.sh`）と自分用の設定のシェル統合は一緒に動く（ryo-aoki-pc/wezterm の docs/install.md の手順 9 と注意点のとおり）。もとの wezterm-nightly.md の古い説明を直した
- リード: 飛ばさない手順に「HackGen Console NF」（「WezTerm と HackGen Console NF をデスクトップで使う」と自分用の WezTerm の設定が使う）を足し、画面で行う手順・対話入力の一覧を足した。WezTerm のタブに移るところの書き方を直した。「再起動と確認」の手順 2 の Dash とボタンの書き方を、WezTerm に合わせた
- 「Codex・Grok のプラグイン」の手順 1: レビューのときのエラーの箇条書きを、注意点の「Grok Build: sandbox は既定で無効」に移した
- ロールバックのリード: 項の中で入れた共通の道具を残すことを書き、`[!WARNING]` と `[!CAUTION]` を続けて置かないようにした。lazygit の clone を消す前の確かめを足した
- 後ろの節の区切りの `---` が 6 か所で 2 本続いていたのを、1 本にした
- 参考資料: 必須にした「WezTerm と HackGen Console NF をデスクトップで使う」の補足の見出しを、今の項の名前にした

### 確認していないこと

- AlmaLinux 10 の GNOME の PC での、この文書の順番の通し（新しい 14 項・「再起動と確認」の手順 8・ロールバックの 4 項・更新の手順 5〜9）。この確認を行った環境は Linux のコンテナで、AlmaLinux 10 の GNOME も、仮想化（KVM）も無い
- 自分用の設定 4 つを、この文書の順番で入れること（LazyVimStarter の入力ソースの変更を「再起動と確認」の再起動で読み直すことを含む）
- 移したコマンドの、統合前の記録の範囲を超える確かめ（統合前の記録の「確認していないこと」は、そのまま残る）

---

## 統合前の記録: EPEL（もとは epel.md）

もとの `epel.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜3 | 「EPEL と RPM Fusion」の手順 1 |
| 更新 1 | 更新のリード（OS は「OS とファームウェアの更新」の手順 1） |
| ロールバック 1・2 | ロールバックの「Flatpak・RPM Fusion・EPEL を消す」の手順 7・8 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### EPEL: 補足

#### EPEL: 実施手順 / 手順 2: 補足: 一緒に入るものと、CRB の案内

素のコンテナでは、`epel-release` と、弱い依存の `dnf-plugins-core` の 2 つが入った:

```
Installing:
 epel-release            noarch        10-6.el10            extras         18 k
Installing weak dependencies:
 dnf-plugins-core        noarch        4.7.0-10.el10        baseos         37 k
```

- `dnf-plugins-core` は `dnf config-manager` のパッケージ。元から入っているホストでは入らない
- SELinux のポリシー（`selinux-policy`）が入っているホストでは、CRB の `selinux-policy-extra` と `selinux-policy-targeted-extra` も入る
  - `epel-release` の弱い依存 `(selinux-policy-epel if selinux-policy)` を満たすため
  - aarch64 の実機で、`epel-release` が [RPM Fusion](../almalinux-setup.md) の依存として入ったときの記録（[firefox.md の付録](#firefox-付録-実機での本実行2026-09-28)）

最後に scriptlet がこのメッセージを出す:

```
Many EPEL packages require the CodeReady Builder (CRB) repository.
It is recommended that you run /usr/bin/crb enable to enable the CRB repository.
```

AlmaLinux 10 では CRB が既定で有効（素のコンテナでも `dnf repolist enabled` に `crb` がある）なので、`crb enable` は要らない。

extras の `epel-release` は `10-6.el10` で、EPEL 自身が出している `10-8.el10_2` より古い。**一度 EPEL が有効になれば、[更新](../almalinux-setup.md#更新)で EPEL の `epel-release` に上がる**ので、差は放っておいてよい。

#### EPEL: ロールバック / 手順 0: 本文中の記録

- この節の手順はコンテナと x86_64 の VM で本実行した

#### EPEL: ロールバック / 手順 1: 補足: --noautoremove を付ける理由

付けないと、手順 2 で弱い依存として入った `dnf-plugins-core` も「使われなくなった依存」として一緒に消える（コンテナでの実測）。`dnf config-manager` のパッケージで、[zoxide.md](../almalinux-setup.md) などでも使うので残す。

```
Removing:
 epel-release           noarch       10-6.el10              @extras        25 k
Removing unused dependencies:
 dnf-plugins-core       noarch       4.7.0-10.el10          @baseos        22 k
```

RPM Fusion が残っている状態では、`Removing dependent packages:` に `rpmfusion-free-release` が出た。

#### EPEL: 対象と検証環境

- **目的**: AlmaLinux 10 で EPEL（Extra Packages for Enterprise Linux。Fedora のプロジェクトが EL 向けに作る追加のパッケージ）を有効にし、AppStream / BaseOS に無い RPM を dnf で入れられるようにする
- **進め方**: AlmaLinux の `extras` にある `epel-release` を入れる。読者が編集する変数は無い
  - もとは [btop.md](../btop.md) などの手順の中にあった 3 つの手順を、共有の前提として 1 本にした
- **状態**: **手順 2 はコンテナと x86_64 の VM で検証済み（VM は 2026-10-06）。手順 1・3 は x86_64 の実機でも通した**
  - 手順 1〜3 のコマンドは、この文書に移す前に、EPEL を使う手順書の検証で通したもの
    - コンテナ: [btop.md](btop.md#付録-コンテナでの検証記録2026-09-22)（2026-09-22、aarch64）、[virtualbox.md](virtualbox.md#付録-コンテナでの検証記録2026-09-24)（2026-09-24）、[distrobox.md](distrobox.md#付録-コンテナでの検証記録2026-09-27)・[podman-compose.md](podman-compose.md#付録-コンテナでの検証記録2026-09-27)（2026-09-27）、[podman-tui.md](podman-tui.md#付録-コンテナでの検証記録2026-09-28)（2026-09-28）。aarch64 と明記したもの以外は x86_64
    - x86_64 の実機（[virtualbox.md の本実行](virtualbox.md#付録-実機での本実行2026-09-29)、2026-09-28）: EPEL が有効だったので、手順 1・3 だけ通した
  - 2026-09-29 に、この文書のブロックを x86_64 のコンテナでもう一度通した（[付録](#epel-付録-コンテナでの検証記録2026-09-29)）
    - 手順 1〜3、[更新](../almalinux-setup.md#更新)、[ロールバック](../extra/almalinux-setup.md#ロールバック)
    - [rpmfusion.md](../almalinux-setup.md) を続けて通し、そのロールバックの後にこの文書のロールバックを行った
  - **確認していないこと**: 実機での手順 2（`dnf install epel-release`）
    - aarch64 の実機では、`epel-release` は RPM Fusion の依存として入った（[firefox.md の付録](#firefox-付録-実機での本実行2026-09-28)）

| 項目 | x86_64 の実機 | 検証コンテナ（2026-09-29） |
|---|---|---|
| 実施日 | 2026-09-28（[virtualbox.md](../virtualbox.md) の中で） | 2026-09-29 |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64（AMD のノート PC） | 同左（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1） |
| dnf | 4.20.0 | 4.20.0 |
| EPEL | **有効**（`epel-release-10-8.el10_2`。手順 2 は不要） | 未設定 → 手順 2 で `epel-release-10-6.el10` を導入 → [更新](../almalinux-setup.md#更新)で `10-8.el10_2` |

> [!NOTE]
> 出力例の値は `<USER>` / `<HOSTNAME>` のプレースホルダで書いてある。`epel-release` の版は実行日によって変わる。**鍵の fingerprint は公開情報なので本文に書いてある。**

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### EPEL: 選択した方針

- **extras の `epel-release` を入れる**: AlmaLinux のリポジトリから入り（鍵の確認は出なかった）、URL を書かずに済む
  - EPEL の文書（Getting Started）は、EL10 向けに `dnf config-manager --set-enabled crb` の後、Fedora のサイトの `epel-release-latest-10.noarch.rpm` を URL で入れる方法を載せている
  - AlmaLinux では extras に `epel-release` があるので、URL の方法は使わない（試していない）
- **CRB は有効にしない**: AlmaLinux 10 では既定で有効（[導入元一覧](../tool-catalog.md#導入経路と-el10-での注意)）
- **鍵は先に取り込まない**: 最初に EPEL のパッケージを入れるときに、dnf がローカルのファイルから取り込む。確認は 1 回だけで、使う側の手順書の導入の手順にそう書いてある
- **独立した手順書にした**: EPEL を使う手順書が 5 本と [RPM Fusion](../almalinux-setup.md) になり、同じ 3 つの手順が各文書に重なっていたため

#### EPEL: 付録: コンテナでの検証記録（2026-09-29）

**環境**: Ubuntu 24.04 / x86_64 のクラウドホスト上の Docker 29.3.1 で、`quay.io/almalinuxorg/almalinux:10`（`sha256:8322019282c6f7d253888ec688d6b90675963f31c4692709177e25eb9301c4c8`、AlmaLinux 10.2）を非特権・`--network host` で立てた。実機で加えた変更は無い。

**手順書の外で行った準備**（検証環境の都合）:

- プロキシの CA を信頼ストアに足し、dnf にプロキシを設定した
- プロキシが平文の HTTP を通さないので、AlmaLinux のミラー一覧の URL に `?protocol=https`、EPEL の metalink に `&protocol=https` を足した（EPEL は手順 2 の直後）
- `sudo` と `gnupg2` を入れ、NOPASSWD の `sudo` を与えた非 root ユーザーを作った

**流し方**: 同じ作りのコンテナで 2 回通した。どちらも非 root ユーザーのログインシェルで実行し、`dnf install` / `dnf upgrade` / `dnf remove` には `-y` を付けた。

- 1 回目: 本文と同じコマンドを手で打った。手順書の外のコマンドも混ぜて、下の箇条書きのことを確かめた
- 2 回目: 新しいコンテナで、この文書と [rpmfusion.md](../almalinux-setup.md) の bash のブロックをファイルから抜き出して流した。順番は、手順 1〜3 → rpmfusion.md の手順 1〜4 → [更新](../almalinux-setup.md#更新) → rpmfusion.md のロールバック → [ロールバック](../extra/almalinux-setup.md#ロールバック)

2 回目の結果:

| 手順 | 結果 |
|---|---|
| 1. 確かめる | `EPEL は未設定`（有効なのは appstream / baseos / crb / extras の 4 つ） |
| 2. 導入 | `epel-release-10-6.el10`（extras）と、弱い依存の `dnf-plugins-core-4.7.0-10.el10`（baseos）の 2 つ。scriptlet が CRB の案内を出した |
| 3. 確かめる | `epel-release-10-6.el10.noarch` と `epel                 Extra Packages for Enterprise Linux 10 - x86_64` |
| 更新 | `epel-release` が `10-6.el10`（extras）から `10-8.el10_2`（epel）に上がった。EPEL の鍵が未登録だったので、ここで `Importing GPG key 0xE37ED158:` が出た（`-y` で取り込まれた） |
| ロールバック | 先に rpmfusion.md のロールバックを行った。手順 1 の `Removing:` は `epel-release`（`10-8.el10_2`、`@epel`）の 1 つだけで、`dnf-plugins-core` は残った。手順 2 で鍵（`gpg-pubkey-e37ed158-65785fa9`）が消え、`dnf repolist enabled` から `epel` の行が消えた |

- ロールバックで、`epel.repo` と `epel-testing.repo` が `.rpmsave` として残った。検証のために metalink を書き換えていたため（書き換えた設定ファイルを rpm が残す）

1 回目に確かめたこと:

- 手順 3 の補足の鍵の表示は、手順書の外で EPEL の btop を入れたときのもの
- `epel-release` を消した後も、EPEL から入れた btop は残った（[ロールバック](../extra/almalinux-setup.md#ロールバック)のアラート）
- `--noautoremove` を付けない `dnf remove --assumeno epel-release` では、`dnf-plugins-core` も消える表になった
- RPM Fusion を入れた状態の `dnf remove --assumeno epel-release` では、`rpmfusion-free-release` が `Removing dependent packages:` に出た

##### EPEL: 未確認事項

- 実機での手順 2 と、aarch64 での手順 2（aarch64 は、この文書に移す前の [btop.md の付録](btop.md#付録-コンテナでの検証記録2026-09-22)でコンテナでのみ通した）
- 実機での[更新](../almalinux-setup.md#更新)と[ロールバック](../extra/almalinux-setup.md#ロールバック)
- SELinux が有効なホストで、手順 2 が `selinux-policy-extra` を入れること（RPM Fusion の依存で入ったときの記録しか無い）

#### EPEL: 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を ISO から新規に入れた VirtualBox の VM（x86_64、1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で、検証用ユーザーの SSH PTY に現行のブロックを個別に貼った。利用者のアカウントは使っていない。

実施手順 1〜3、更新、ロールバック 1・2 を本実行した。未設定の状態から extras の `epel-release-10-6.el10` と CRB の `selinux-policy-extra`・`selinux-policy-targeted-extra`（ともに `42.1.18-4.el10_2.3`）の計 3 パッケージが入った。Workstation に `dnf-plugins-core` は既にあったため追加されなかった。CRB は既定で有効だった。別のクリーン VM でも同じ 3 パッケージが入った。

続けて Firefox の FFmpeg を入れるとき、EPEL 10 の署名鍵の fingerprint と uid を照合して取り込めた。更新の手順は `epel-release-10-8.el10_2` への 1 パッケージの upgrade になった。実機での手順 2 と aarch64 の今回の実行は確認していない。

ロールバックは RPM Fusion を先に外してから行い、`--noautoremove` で epel-release だけが消えた。EPEL の署名鍵も削除できた。SELinux の extra ポリシーは残した。

#### EPEL: 付録: 現行版の新規 VM での再検証（2026-10-06）

公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active）で、`5da3478` の本文を SSH 対話 PTY に渡した。試験専用のユーザー・鍵と設定値を使用し、利用者の実アカウントの資格情報は持ち込んでいない。

実施手順 1〜3 を通した。未設定の状態から extras の epel-release-10-6.el10 と、CRB の selinux-policy-extra / selinux-policy-targeted-extra が入り、epel が有効になった。CRB は OS の既定で有効で、追加の有効化は行っていない。この再検証では更新・ロールバックを実行していない。

#### EPEL: 手順中の実測・検証状況の記録

> **手順 2（`epel-release` の導入）は、コンテナとクリーンな x86_64 の VM で通した**（[対象と検証環境](#epel-対象と検証環境)）。

#### EPEL: 実施手順 / 手順 3: 補足: 出力例と、EPEL の鍵

コンテナでの出力:

```
$ rpm -q epel-release
epel-release-10-6.el10.noarch
$ dnf repolist enabled | grep -E '^epel'
epel                 Extra Packages for Enterprise Linux 10 - x86_64
```

dnf は鍵をこのローカルファイルから取り込む。**[gh.md](../almalinux-setup.md#github-cli) や [rpmfusion.md](../almalinux-setup.md) のように、公開鍵を HTTPS で取りに行く手順は要らない。** コンテナで、EPEL の btop を入れたときの途中の表示:

```
Importing GPG key 0xE37ED158:
 Userid     : "Fedora (epel10) <epel@fedoraproject.org>"
 Fingerprint: 7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10
Key imported successfully
```

#### EPEL: 手順内の実測・検証状況

> - x86_64 の実機は EPEL が有効だったので、手順 1・3 だけ通した

#### EPEL: 手順内の実測・検証状況

> - aarch64 の実機では、[RPM Fusion](../almalinux-setup.md) の依存として `epel-release` が入った

---

## 統合前の記録: RPM Fusion（もとは rpmfusion.md）

もとの `rpmfusion.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜4 | 「EPEL と RPM Fusion」の手順 2〜5 |
| ロールバック 1・2 | ロールバックの「Flatpak・RPM Fusion・EPEL を消す」の手順 5・6 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### RPM Fusion: 補足

#### RPM Fusion: 実施手順 / 手順 1: 補足: 鍵の出所

鍵は RPM Fusion の [keys](https://rpmfusion.org/keys) ページの添付ファイル。同じページの「RPM Fusion free for EL 10」の fingerprint（`5FC4 AE73 FC2B 08B9 DFE7 EB99 0C84 89D8 DB85 DDD7`）と一致した:

```
pub   rsa4096 2025-02-07 [SC]
      5FC4AE73FC2B08B9DFE7EB990C8489D8DB85DDD7
uid                      RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org>
```

`gpg` は `gnupg2` のコマンド。素のコンテナには入っていなかったので、検証では先に入れた。

`gpg` を初めて使うユーザーでは、`pub` 行の前に `~/.gnupg` を作ったという行が出る。鍵の照合には関係ない。x86_64 の実機では次の 2 行、2026-09-29 のコンテナでは 1 行目だけが出た:

```
gpg: directory '/home/<USER>/.gnupg' created
gpg: /home/<USER>/.gnupg/trustdb.gpg: trustdb created
```

#### RPM Fusion: 実施手順 / 手順 3: 補足: 署名の確認と、EPEL を前提にした理由

**署名の確認**: dnf 4.20 の既定は `localpkg_gpgcheck = 0` で、URL やファイルで渡したパッケージの署名を確かめない。`--setopt=localpkg_gpgcheck=1` を付けると確かめる。手順 2 の鍵が無いコンテナでは、次のように止まって何も入らなかった:

```
Public key for rpmfusion-free-release-10.noarch.rpm is not installed
The downloaded packages were saved in cache until the next successful transaction.
You can remove cached packages by executing 'dnf clean packages'.
Error: GPG check FAILED
```

- RPM Fusion の [Configuration](https://rpmfusion.org/Configuration) は、EL 向けに `--nogpgcheck` で入れる例を載せている
- 一方 [keys](https://rpmfusion.org/keys) の「Verify GPG signatures on install」は、鍵を先に取り込んで `localpkg_gpgcheck=1` で入れる方法を案内しており、本書は後者にした
- `mirrors.rpmfusion.org` はミラーへリダイレクトする（2026-09-28 の aarch64 のコンテナでは `mirrors.ustc.edu.cn`）ので、署名で確かめる意味がある

**EPEL を前提にした理由**: `rpmfusion-free-release` は `epel-release >= 10` を要求する。RPM Fusion の Configuration も、EL では RPM Fusion より先に EPEL を有効にするよう書いている。

EPEL が有効なホストで入るのは、`rpmfusion-free-release` の 1 つだけだった（x86_64 の実機と、2026-09-29 のコンテナ）:

```
Installing:
 rpmfusion-free-release       noarch       10-1        @commandline        10 k
```

EPEL を有効にしていないホストでも、`epel-release` が依存として extras から一緒に入るので、この手順は通る。

- 素のコンテナ（2026-09-28）では、`rpmfusion-free-release`・`epel-release`・弱い依存の `dnf-plugins-core` の 3 つが入った
- aarch64 の実機（GNOME のデスクトップ、SELinux は Enforcing）では、`dnf-plugins-core` の代わりに CRB の `selinux-policy-extra` と `selinux-policy-targeted-extra` が入り、4 パッケージになった（[epel.md 手順 2 の補足](../almalinux-setup.md#epel-と-rpm-fusion)）

```
Packages Altered:
    Install selinux-policy-extra-42.1.18-4.el10_2.3.noarch          @crb
    Install selinux-policy-targeted-extra-42.1.18-4.el10_2.3.noarch @crb
    Install epel-release-10-6.el10.noarch                           @extras
    Install rpmfusion-free-release-10-1.noarch                      @@commandline
```

依存で入った `epel-release` は、[ロールバック](../extra/almalinux-setup.md#ロールバック)で一緒に消えやすい（その手順 1 の補足）。本書では EPEL を前提にして、[epel.md](../almalinux-setup.md) で先に入れる。

#### RPM Fusion: 実施手順 / 手順 4: 補足: 出力例と、置かれるファイル

2026-09-29 のコンテナでの出力:

```
$ rpm -q rpmfusion-free-release
rpmfusion-free-release-10-1.noarch
$ dnf repolist enabled | grep -E '^rpmfusion'
rpmfusion-free-updates      RPM Fusion for EL 10 - Free - Updates
```

- repo ファイルは `/etc/yum.repos.d/rpmfusion-free-updates.repo`（有効）と `rpmfusion-free-updates-testing.repo`（無効）
- 鍵のファイル `/etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-el-10` も置かれる
- 有効になった後は、例えば `dnf -q list --showduplicates ffmpeg-libs` に `rpmfusion-free-updates` の行が出る（[firefox.md 手順 8](../almalinux-setup.md#firefox)）

#### RPM Fusion: ロールバック / 手順 0: 本文中の記録

- この節の手順はコンテナと x86_64 の VM で本実行した

#### RPM Fusion: ロールバック / 手順 1: 補足: --noautoremove を付ける理由

`epel-release` が[手順 3](../almalinux-setup.md#epel-と-rpm-fusion) の依存として入ったホスト（EPEL を先に有効にしていなかったホスト）では、付けないと `epel-release` と `dnf-plugins-core` も「使われなくなった依存」として一緒に消える（2026-09-28 のコンテナでの実測）。EPEL はほかの手順書でも使い、`dnf-plugins-core` は `dnf config-manager` のパッケージなので残す。

```
Removing:
 rpmfusion-free-release    noarch    10-1                @@commandline    3.8 k
Removing unused dependencies:
 dnf-plugins-core          noarch    4.7.0-10.el10       @baseos           22 k
 epel-release              noarch    10-6.el10           @extras           25 k
```

[epel.md](../almalinux-setup.md) で EPEL を先に入れたホストでは、付けなくても `rpmfusion-free-release` の 1 つだけだった（2026-09-29 のコンテナ）。

#### RPM Fusion: 対象と検証環境

- **目的**: AlmaLinux 10 で RPM Fusion の free のリポジトリを有効にし、FFmpeg など Fedora・EL の標準のリポジトリに無いパッケージを dnf で入れられるようにする
- **進め方**: 鍵を照合して取り込み、署名を確かめながら `rpmfusion-free-release` を入れる。前提は [EPEL](../almalinux-setup.md)。読者が編集する変数は無い
  - もとは [firefox.md](../almalinux-setup.md#firefox) の手順 8〜11 と、ロールバックの手順 2〜3 だった。Firefox の FFmpeg から、リポジトリの有効化を切り分けた
- **状態**: **手順 1〜3 は実機で本実行済み（2026-09-28）**。aarch64 と x86_64 の 2 台
  - 2026-10-06: 別の新規 VM で現行手順を再検証した。今回の実施・解除・未実施範囲は[新しい付録](#rpm-fusion-付録-現行版の新規-vm-での再検証2026-10-06)に記録した
  - 2026-10-06: クリーンな x86_64 の VM で実施手順 1〜4 とロールバック 1・2 を本実行し、Firefox の FFmpeg の導入も確認した（末尾の付録）。
  - aarch64 の実機（Raspberry Pi 5）: 利用者が手順どおりに入れた（[firefox.md の付録](#firefox-付録-実機での本実行2026-09-28)）
    - 鍵（`gpg-pubkey-db85ddd7-67a63d8b`）が登録され、`dnf history` に手順 3 の実行（4 パッケージ）が残っている
    - EPEL は無かったので、手順 3 の依存で入った
  - x86_64 の実機（AMD のノート PC）: EPEL が入ったホストで手順 1〜3 のコマンドを実行した（[firefox.md の付録](#firefox-付録-x86_64-の実機での本実行2026-09-28)）。手順 3 は `rpmfusion-free-release` の 1 つだけだった
  - コンテナ
    - 2026-09-28 の aarch64 のコンテナで、手順 1〜3 と[ロールバック](../extra/almalinux-setup.md#ロールバック)を通した（[firefox.md の付録](#firefox-付録-動画が再生できなかった件の切り分け2026-09-28)）
    - 2026-09-29 の x86_64 のコンテナで、[epel.md](../almalinux-setup.md) の後にこの文書のブロックを通した（手順 1〜4 とロールバック。[付録](#rpm-fusion-付録-コンテナでの検証記録2026-09-29)）
  - **手順 4 とロールバックは、コンテナと新規 x86_64 VM で検証**
  - **確認していないこと**: nonfree のリポジトリ、`rpmfusion-free-updates-testing`
  - 2026-10-02: もとの手順 2・3 をつないで `{ … }` で囲んだ。当時は `bash -n` のみだったが、2026-10-06 の新規 VM では現行ブロックを貼って実行した

| 項目 | aarch64 の実機 | x86_64 の実機 | 検証コンテナ（2026-09-29） |
|---|---|---|---|
| 実施日 | 2026-09-28 | 2026-09-28 | 2026-09-29 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | AlmaLinux 10.2 (Lavender Lion) / x86_64（AMD Strix Halo のノート PC） | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1） |
| dnf | 4.20.0 | 4.20.0 | 4.20.0 |
| SELinux | Enforcing | Enforcing | 無効（コンテナ） |
| 手順 3 の前の EPEL | 無し | 有効（鍵も登録済み） | [epel.md](../almalinux-setup.md) で有効にした |
| 手順 3 で入ったもの | `rpmfusion-free-release`・`epel-release`・`selinux-policy-extra`・`selinux-policy-targeted-extra` | `rpmfusion-free-release` だけ | `rpmfusion-free-release` だけ |

> [!NOTE]
> 出力例の値は `<USER>` / `<HOSTNAME>` のプレースホルダで書いてある。版（`10-1`）は実行日によって変わる。**鍵の fingerprint は公開情報なので本文に書いてある。**

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### RPM Fusion: 付録: コンテナでの検証記録（2026-09-29）

**環境**: [epel.md の付録](#epel-付録-コンテナでの検証記録2026-09-29)と同じコンテナで、epel.md の手順 1〜3 の後に行った（2 回）。実機で加えた変更は無い。

**手順書の外で行った準備**: epel.md の付録の準備に加えて、手順 3 の直後に RPM Fusion の metalink を `https://` にし、`&protocol=https` を足した（repo ファイルの metalink は `http://mirrors.rpmfusion.org/...` で、プロキシが平文の HTTP を通さないため）。

**流し方**: epel.md の付録と同じ。1 回目は本文と同じコマンドを手で打ち、2 回目は本文の bash のブロックをファイルから抜き出して流した。どちらも非 root ユーザーのログインシェルで、`dnf install` / `dnf remove` には `-y` を付けた。下の表は 2 回目で、どちらも同じ結果だった。

| 手順 | 結果 |
|---|---|
| 1. 鍵の照合 | fingerprint と uid が本文の値と一致。このユーザーは `gpg` を初めて使ったので、`gpg: directory '/home/<USER>/.gnupg' created` の 1 行が先に出た |
| 2. 取り込み | 何も表示せずに終わった |
| 2. 確かめる | `gpg-pubkey-db85ddd7-67a63d8b RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org> public key` |
| 3. リポジトリ | EPEL が有効なので、`Installing:` は `rpmfusion-free-release 10-1 @commandline` の 1 つだけ |
| 4. 確かめる | `rpmfusion-free-release-10-1.noarch` と `rpmfusion-free-updates      RPM Fusion for EL 10 - Free - Updates` |
| ロールバック | epel.md の[更新](../almalinux-setup.md#更新)の後に行った。手順 1 の `Removing:` は `rpmfusion-free-release` の 1 つだけ。手順 2 で鍵が消えた。続けて [epel.md のロールバック](../extra/almalinux-setup.md#ロールバック)を行った |

- 1 回目は、手順 4 の後に手順書の外の `dnf -q list --showduplicates ffmpeg-libs` を実行し、`ffmpeg-libs.x86_64  7.1.5-1.el10  rpmfusion-free-updates` が出た
- 1 回目は、手順 3 の後の `dnf remove --assumeno rpmfusion-free-release`（`--noautoremove` 無し）も、`rpmfusion-free-release` の 1 つだけだった。`epel-release` を epel.md で入れたので、依存として入ったものではない
- ロールバックの後、metalink を書き換えた repo ファイルが `.rpmsave` として残った（[epel.md の付録](#epel-付録-コンテナでの検証記録2026-09-29)と同じ）

##### RPM Fusion: 未確認事項

- 実機での手順 4 とロールバック
- aarch64 での手順 4
- nonfree のリポジトリと、`rpmfusion-free-updates-testing`

#### RPM Fusion: 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を ISO から新規に入れた VirtualBox の VM（x86_64、1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で、検証用ユーザーの SSH PTY に現行のブロックを個別に貼った。利用者のアカウントは使っていない。

EPEL の実施手順 1〜3 の後、実施手順 1〜4 とロールバック 1・2 を本実行した。公式の鍵の fingerprint `5FC4AE73FC2B08B9DFE7EB990C8489D8DB85DDD7` と uid を照合し、rpm に取り込んでから `localpkg_gpgcheck=1` で `rpmfusion-free-release-10-1` を入れた。入ったのはこの 1 RPM だけで、有効な `rpmfusion-free-updates` から Firefox の `ffmpeg-libs-7.1.5-1.el10` を導入できた。nonfree と aarch64 の今回の実行は確認していない。

FFmpeg を外した後のロールバックは、`--noautoremove` で rpmfusion-free-release だけが消え、EPEL は残った。RPM Fusion の署名鍵も削除できた。

---

#### RPM Fusion: 付録: 現行版の新規 VM での再検証（2026-10-06）

**環境と流し方**: `5da3478` の現行手順を、別のクリーンな AlmaLinux 10.2 Workstation / x86_64 の VM（1 vCPU、SELinux Enforcing、firewalld 稼働、US 配列）で実行した。SSH の一般ユーザーの対話 PTY に折り畳みの外のブロックを手順ごとに貼り、応答とプロンプトを待った。GUI は GNOME 49.4 のヘッドレスセッションに仮想モニターを付け、操作後の PNG を目視した。既存の実機・資格情報は使っていない。

実施手順 1〜4 を本実行した。RPM Fusion free の鍵の指紋は `5FC4 AE73 FC2B 08B9 DFE7 EB99 0C84 89D8 DB85 DDD7`。取得した release RPM の署名を確認し、`rpmfusion-free-release-10-1` と EL10 の free / free-updates を導入した。Firefox の `ffmpeg-libs-7.1.5-1.el10` の取得にも使った。

Firefox と関連の codec を先に外してから、ロールバック 1・2 を実行した。`--noautoremove` で release パッケージだけを削除し、その repo とこの鍵が残らないことを確認した。nonfree、Windows、aarch64 は今回実施していない。

---

## 統合前の記録: bash の設定（もとは bash-settings.md）

もとの `bash-settings.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「共通の bash 設定」の手順 3 |
| 実施手順 2 | 「シェルのツール」の手順 3（今のシェルへの読み込みはやめた） |
| 実施手順 3 | 「共通の bash 設定」の手順 2 と「シェルのツール」の手順 3 |
| 実施手順 4 | 「シェルのツール」の手順 3 |
| 実施手順 5 | 「共通の bash 設定」の手順 4 |
| 実施手順 6 | 「シェルのツール」の手順 2 |
| 実施手順 7 | 「シェルのツール」の手順 3 |
| 実施手順 8 | 「キー操作を試す」の手順 1 |
| ロールバック 1 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 2 |
| ロールバック 2 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 7 |
| ロールバック 3 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 6 |
| ロールバック 4 | ロールバックの「Homebrew と bash-completion を消す」の手順 4 |
| ロールバック 5 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 8 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### bash の設定: 補足

#### bash の設定: 実施手順: 検証状況の記録

> [!WARNING]
> **現行版 `5da3478` を、共通 bash を新規導入した別の x86_64 VM で再検証した**（末尾の再検証記録）。既存ホストの手動移行は実行していない。
>
> **x86_64 のクリーン VM で検証対象版の実施手順を本実行済み**（2026-10-06）で、実機では本書の手順を通していない（[対象と検証環境](#bash-の設定-対象と検証環境)）。GNOME 端末や WezTerm の画面での色と、Home / End / Ctrl+矢印のキーは確かめていない。

#### bash の設定: 実施手順 / 手順 1: 補足: bash-completion が無いとどうなるか

- bash 自身の補完は、コマンド名・ファイル名・変数名だけ。`systemctl star<Tab>` や `git checko<Tab>` のような、コマンドごとのサブコマンドやオプションの補完は bash-completion（と、各パッケージが `/usr/share/bash-completion/completions/` に置く定義）が行う
- AlmaLinux 10.2 の BaseOS の版は 2.11（2026-10-02）。コンテナの最小のイメージには入っていなかった
- 入れると `/etc/profile.d/bash_completion.sh` が置かれ、対話のシェルを開くときに `/etc/profile`（ログインシェル）か `/etc/bashrc`（それ以外）から読まれる

#### bash の設定: 実施手順 / 手順 2: 補足: . ~/.bashrc では読まれない理由

- `/etc/bashrc` は `/etc/profile.d/*.sh` を**ログインシェルでないとき**だけ読む（`if ! shopt -q login_shell`）。SSH でログインしたシェルで `. ~/.bashrc` を実行しても、`/etc/bashrc` 経由では `bash_completion.sh` に届かない
- `bash_completion.sh` 自身は、対話の bash で、まだ読んでいないとき（`BASH_COMPLETION_VERSINFO` が空）だけ本体を読む。2 回目は何もしない
- `complete -p -D` の `_completion_loader` は、コマンドの補完を最初の Tab のときに `/usr/share/bash-completion/completions/<コマンド>` から読む仕組み（遅延読み込み）。読む前の `complete -p git` は `bash: complete: git: no completion specification` になる
- AlmaLinux 10.2 Workstation のクリーン VM（2026-10-06）では、既存の `python3-argcomplete-3.2.2-4.el10` が既定の補完を `_python_argcomplete_global` にしていた。この関数は argcomplete の対象でなければ `_completion_loader` を呼ぶ。`systemctl star<Tab>` などの補完も通ったので、関数名だけで未読込とは判断しない

- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

#### bash の設定: 対象と検証環境

- **目的**: AlmaLinux 10 の bash で、履歴を多く残し、Tab の補完を広く・楽にし、↑ で打ちかけの行から履歴を探せるようにする。ツールを足すのではなく、bash と readline の設定と、bash-completion の RPM だけで行う
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **`0dbb522` の直接追記版の実施手順 1〜8 を x86_64 のクリーン VM で本実行済み（2026-10-06）。コンテナでも検証済み（2026-10-02）**。現行版 `5da3478` は、共通 bash 新規導入後の別の VM でも再検証した（末尾の再検証記録）。既存ホストの手動移行は行っていない。
  - 通したこと: SSH でログインした対話の bash に、この文書の bash のブロックをそのまま貼り、実施手順と[ロールバック](../extra/almalinux-setup.md#ロールバック)を、ブラケットペーストの無しと有りで 1 回ずつ通した（[付録](#bash-の設定-付録-コンテナでの検証記録2026-10-02)）
  - 確認したこと
    - 手順 1〜7 の出力、手順 8 のキー操作（tmux のペインにキーを送って画面を読んだ）、[ロールバック](../extra/almalinux-setup.md#ロールバック)
    - `~/.inputrc` に `$include /etc/inputrc` が無いと `/etc/inputrc` の割り当てが消えること、`~/.bashrc` の行を消した後に閉じたシェルが履歴を 1,000 行に切り詰めること
    - [fzf.md](../almalinux-setup.md) の行との並び（手順 4 の補足）
  - **確認していないこと**
    - 実機（aarch64 の Raspberry Pi 5、x86_64 の PC）、GNOME 端末・WezTerm の画面での色と Home / End / Ctrl+矢印
    - 日本語入力との組み合わせ、`python3` など bash 以外の readline のコマンドでの `~/.inputrc`

| 項目 | 検証コンテナ |
|---|---|
| 実施日 | 2026-10-02 |
| OS | AlmaLinux 10.2 (Lavender Lion)（`quay.io/almalinuxorg/10-init`。パッケージは `x86_64_v2`） |
| コンテナ | クラウドのホストの Docker 29.6.2、`--privileged` と `--network host`。systemd を PID 1 にし、sshd と systemd-logind を動かした |
| bash | 5.2.26（BaseOS）。bash-completion は 2.11-16（BaseOS。最初は入っていない） |
| Homebrew | 7.0.7（`/home/linuxbrew/.linuxbrew`）。bat 0.26.1・eza 0.23.5・fd 10.5.0・fzf 0.74.4・starship 1.26.0・zoxide 0.10.0 を入れて補完を確かめた |
| 端末 | ホストの tmux 3.4 のペイン（160x45）から `docker exec -it` で `ssh -t` し、`TERM=xterm-256color` |

> [!NOTE]
> 出力例・ログの中の値は `<USER>` / `<HOSTNAME>` / `<PID>` のプレースホルダで書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### bash の設定: 実施前の状態

| 項目 | 状態 |
|---|---|
| bash-completion | 未導入（`rpm -q bash-completion` が `not installed`） |
| `~/.bashrc` | `/etc/skel` のもの（`/etc/bashrc` を読み、`~/.bashrc.d/` があれば読む）に、[homebrew.md 手順 3](../almalinux-setup.md#homebrew) の `brew shellenv` の 1 行 |
| `~/.inputrc` | 無し（`/etc/inputrc` が読まれている） |
| 履歴 | `HISTSIZE=1000`・`HISTFILESIZE=1000`・`HISTCONTROL=ignoredups`、`histappend` は on |

#### bash の設定: 完了時点の状態

実施手順の後（Homebrew のホスト）:

```
$ tail -n 5 ~/.bashrc
HISTSIZE=100000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth
shopt -s autocd cdspell dirspell globstar
if [ -d "${HOMEBREW_PREFIX-}/etc/bash_completion.d" ]; then for __f in "${HOMEBREW_PREFIX}"/etc/bash_completion.d/*; do if [ -r "$__f" ]; then . "$__f"; fi; done; unset __f; fi
$ bind -q history-search-backward
history-search-backward can be invoked via "\eOA", "\e[5~", "\e[A".
$ complete -p -D brew
complete -F _completion_loader -D
complete -o bashdefault -o default -F _brew brew
```

- `~/.inputrc` は手順 5 の 13 行（コメント 3 行を含む）
- [fzf.md 手順 3](../almalinux-setup.md#シェルのツール) を通すと、`fzf --bash` の行が `bash_completion.d` の行の後ろに付く

#### bash の設定: 付録: コンテナでの検証記録（2026-10-02）

**環境**: [対象と検証環境](#bash-の設定-対象と検証環境)の表のとおり。コンテナには NOPASSWD の sudo を持つ一般ユーザーを作り、root から `ssh -p 2222 <USER>@127.0.0.1` でログインした。

**検証の準備**（本書の手順には含めない）:

- このホストの外向きの HTTPS はプロキシを通るので、プロキシの CA を `/etc/pki/ca-trust/source/anchors/` に置き、`/etc/dnf/dnf.conf` の `proxy=` と、ログインシェルの `HTTPS_PROXY` などを足した
- AlmaLinux の `mirrorlist=` を止めて、コメントの `baseurl=https://repo.almalinux.org/...` を有効にした
- Homebrew は `NONINTERACTIVE=1` 付きの公式インストーラで入れ、`brew install fzf fd bat eza zoxide starship` で補完の対象のコマンドを入れた

**先に調べたこと**（文書の内容を決めるため）:

- `/etc/profile` が `HISTSIZE=1000` と `HISTCONTROL=ignoredups` を、`/etc/bashrc` が `shopt -s histappend` を入れている。`/etc/bashrc` は `/etc/profile.d/*.sh` をログインシェルでないときだけ読む
- `dnf group info standard` の既定のパッケージに `bash-completion` がある。`workstation-product-environment` の必須のグループに `Standard` がある
- `brew shellenv bash` の出力は `HOMEBREW_PREFIX` / `HOMEBREW_CELLAR` / `HOMEBREW_REPOSITORY` / `PATH` / `MANPATH` / `INFOPATH` だけで、`XDG_DATA_DIRS` は無い
- `/home/linuxbrew/.linuxbrew/etc/bash_completion.d/` に `bat` `brew` `eza` `fd` `starship` `zoxide`。`bat` だけが bash-completion の `_init_completion` を使う
- `HISTTIMEFORMAT` を入れたシェルを閉じると履歴ファイルに `#1790939222` の行が付き、変数の無いシェルで `history` を見ても、その行はコマンドとして出なかった
- 2,000 行の履歴ファイルを持つシェルを既定の `HISTFILESIZE`（1000）で閉じると 1,000 行に、`100000` にして閉じると 2,001 行になった

**流し方**:

- ホストの tmux のペインで `docker exec -it … ssh -t` したログインシェルに、この文書の bash のブロック（折り畳みの外のもの）を抜き出して、手順ごとに `tmux paste-buffer` で書き込んだ
- 1 回目はブラケットペースト無しで、2 回目は `paste-buffer -p`（ブラケットペースト有り。貼った後に Enter を送った）で、実施手順から[ロールバック](../extra/almalinux-setup.md#ロールバック)まで通した。2 回の間に bash-completion を消し、`~/.bashrc` と `~/.inputrc` を実施前に戻した
- 手順 8 のキーは `tmux send-keys` で送り、`capture-pane -e` で色の制御文字ごと読んだ

| 手順 | 結果（2 回とも同じ） |
|---|---|
| 1 | `package bash-completion is not installed` に続けて dnf が `bash-completion-1:2.11-16.el10` と `pkgconf` 系 4 つを入れ、`Complete!` |
| 2 | `complete -F _completion_loader -D`、`2 11` |
| 3 | `100000` `100000` `ignoreboth`、`histappend` `autocd` `cdspell` `dirspell` `globstar` が `on` |
| 4 | `grep` は `26:eval "$(…brew shellenv bash)"` と `31:if [ -d "${HOMEBREW_PREFIX-}/etc/bash_completion.d" ]…`（fzf の行はまだ無い）。`complete -o bashdefault -o default -F _brew brew` |
| 5 | `set colored-completion-prefix on` / `set colored-stats on` / `set completion-ignore-case on` / `set show-all-if-ambiguous on`、`history-search-backward can be invoked via "\eOA", "\e[5~", "\e[A".`、`beginning-of-line can be invoked via "\C-a", "\eOH", "\e[1~", "\e[H".` |
| 6・7 | `exit` してログインし直した新しいシェルで、手順 3・5 と同じ値と `complete -F _completion_loader -D`。`complete -p brew` も同じ |
| 8 | `systemctl star<Tab>` → `systemctl start `。`ls /usr/s<Tab>` → 1 回で `sbin/  share/ src/`（`s` が紫の太字、残りが青）。`cd /usr/SH<Tab>` → `cd /usr/share/`。`printf` + ↑ → 手順 7 の `printf` の行。`/usr/share` + Enter → `cd -- /usr/share` と出てプロンプトが `share` に。`cd /usr/shaer` → `/usr/share` と出て移った。`ls /usr/share/doc/bash-completion/**/*.md` → `CONTRIBUTING.md` と `README.md`。`eza --gi<Tab>` → `--git  --git-ignore  --git-repos  --git-repos-no-status` の一覧の後に `eza --git` |
| ロールバック 1〜3 | 控えの行数（1 回目 56、2 回目 120）。`grep` は何も出さず、`rm -f ~/.inputrc` は何も出さない |
| ロールバック 4 | `Removing: bash-completion`、`Removing unused dependencies:` に `pkgconf` 系 4 つ、`Freed space: 1.2 M`、`Is this ok [y/N]:` に `y` で `Complete!` |
| ロールバック 5 | 新しいシェルで `HISTSIZE` / `HISTFILESIZE` が `1000`、`HISTCONTROL=ignoredups`、`autocd` `globstar` が `off`、`history-search-backward` は `"\e[5~"` だけ、`~/.inputrc` は無く、`~/.bashrc` の末尾は `brew shellenv` の行 |

##### bash の設定: 未確認事項

- 実機（aarch64 の Raspberry Pi 5、x86_64 の PC）での本実行
- GNOME 端末・WezTerm での色、Home / End / Ctrl+矢印、`\eOA`（アプリケーションモード）の ↑
- `python3` など bash 以外の readline のコマンドでの `~/.inputrc`
- 日本語入力との組み合わせ

---

#### bash の設定: 付録: クリーン VM での検証記録（2026-10-06）

**検証対象**: `0dbb522` の、各手順で `~/.bashrc` などへ設定を直接追記する版。以下の手順番号と「本文」はこの版を指す。検証後に共通 bash 設定へ統一された現行版（`0bc9970`）の設定リポジトリの新規導入・既存設定からの移行は、今回の VM では実行していない。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証対象版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順（`0dbb522`）**: 実施手順 1〜8。

**結果**: Workstation に既存の bash-completion 2.11 を使い、OS 既定の `~/.bashrc` に本文の履歴・shopt・Homebrew 補完を足し、`~/.inputrc` を作った。SSH を切ってログインし直した後も値が残った。手順 8 の systemctl・パス・大小文字・eza の Tab、printf の履歴検索、autocd・cdspell・globstar を全て実操作で確認した。Workstation の `python3-argcomplete-3.2.2-4.el10` は既定の補完を `_python_argcomplete_global` にする。この関数の内容で `_completion_loader` へ戻す分岐を確認し、通常の Tab も成功したため、これを失敗とは扱わず期待出力の説明を直した。

**今回の未確認範囲**: GNOME 端末・WezTerm の色と物理キー、Home/End/Ctrl+矢印の実操作、ロールバックは今回確認していない。

#### bash の設定: 付録: 現行の共通 bash 設定での再検証（2026-10-06）

- `5da3478` の実施手順 1〜5・7 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（SELinux Enforcing）で実行した。先に公開 URL から共通 bash `3d5323e` を clone して `install.sh` を実行し、既存の OS 設定へ読み込み行を 1 個設定した
- bash-completion 2.11 は OS に導入済みだった。`complete -p` でシステムの補完を、Homebrew 7.0.8 の導入後には `_brew` の補完を確認した。対話 SSH を張り直しても同じ設定が読み込まれた
- 履歴は `100000` / `100000` / `ignoreboth`、`histappend` / `autocd` / `cdspell` / `dirspell` / `globstar` はすべて on。Readline の設定 4 個と、上矢印・下矢印への履歴検索の割り当てを `bind` の出力で確認した
- 後の SSH 対話 PTY で手順 8 の Tab・大小文字・曖昧候補の一覧・上矢印の履歴検索・autocd・cdspell・globstar・eza の補完を実キーで確認した。Home / End / Ctrl+矢印の実操作と GUI 端末の色・物理キーはこの CLI 検証には含まない

#### bash の設定: 操作上の注意と併記されていた記録

> **この節の手順 2 の後に閉じたシェルは、`~/.bash_history` を既定の 1,000 行に切り詰める**（コンテナで、2,000 行の履歴ファイルが `exit` の後に 1,000 行になった）。残したい履歴があれば、この節の手順 1 で控える。

#### bash の設定: 実施手順 / 手順 5: 補足: ~/.inputrc に書く理由と、各行の意味

- readline は `~/.inputrc` があるとそれを読み、無いときだけ `/etc/inputrc` を読む。`$include` を書かずに `~/.inputrc` を置くと、`/etc/inputrc` の Home / End（`\e[1~` / `\e[4~`）、Delete（`\e[3~`）、Ctrl+←→（`\e[5C` / `\e[1;5C`）、PageUp / PageDown の履歴の検索（`\e[5~` / `\e[6~`）が消える（コンテナで、`bind -q beginning-of-line` から `"\e[1~"` が消え、`$include` を足すと戻った）
- `~/.bashrc` に `bind` で書かない理由: `bind` は対話のシェル以外では `line editing not enabled` の警告になる。`~/.inputrc` は bash のほか、readline を使うコマンド（`python3`・`psql`・`gdb` など）にも効く。`INPUTRC` の環境変数も使わない（それらすべてに別のファイルを押し付けることになる）
- `completion-ignore-case`: `cd /ET<Tab>` が `/etc/` に、`cd /usr/SH<Tab>` が `/usr/share/` になる（打った大文字も直る）
- `show-all-if-ambiguous`: 候補が複数のとき、既定では 1 回目の Tab はベルだけで 2 回目で一覧が出る。1 回で出す
- `colored-stats` / `colored-completion-prefix`: 一覧のディレクトリや実行ファイルを `LS_COLORS` の色で、打った部分を別の色で出す（コンテナでは `ls /usr/s<Tab>` の `s` が紫、残りが青の太字で出た）
- `history-search-backward` は、カーソルより前の文字で始まる履歴を探す。`ec` と打って ↑ で `echo …` の行だけが出る。何も打っていなければ既定の ↑ と同じ。カーソルは打った文字の後ろに残る（行末へは End か Ctrl+E）。`/etc/inputrc` は同じ機能を PageUp / PageDown に付けている
- `\e[A` は端末の通常のモード、`\eOA` はアプリケーションモード（`tput smkx` の後）の ↑。bash の既定は両方を `previous-history` にしているので、両方を置き換える
- `bind -f` は今のシェルだけ。新しいシェルは起動のときに `~/.inputrc` を読む

### bash の設定: 参考資料から分離した記録

#### bash の設定: 参考資料: 選択した方針

- **bash-completion はシステムの RPM にした**: BaseOS の 2.11 で足りる。Homebrew にも `bash-completion@2`（2.16 系）があるが、RPM の各パッケージが置く `/usr/share/bash-completion/completions/` を読むのはシステムのものの方が素直で、`sudo` のシェルでも同じものが効く
- **Homebrew の補完は bash リポジトリから全部読む**: 遅延読み込みの対象のディレクトリに無いため（手順 4 の補足）。`~/.local/share/bash-completion/completions/` にシンボリックリンクを置けば遅延読み込みにできるが、入れるたびに足す手間があるので採らない
- **`~/.inputrc` を使い、`~/.bashrc` の `bind` にはしない**（手順 5 の補足）
- **採らなかった設定**
  - `HISTTIMEFORMAT`（`history` に時刻を出す）: 履歴ファイルに `#<epoch>` の行が増える。bash 5.2 では、変数を外した後もその行はコマンドとして出なかった（コンテナで確認）が、本書は履歴の見え方を変えない範囲にとどめた。欲しければ `HISTTIMEFORMAT='%F %T '` を手順 3 の行に足せばよい
  - `HISTCONTROL=…:erasedups`（同じ行を全部消して 1 つにする）: 覚えている一覧の中だけを直し、ファイルの古い重複は残る。効き目が分かりにくいので入れない
  - `PROMPT_COMMAND` に `history -a`（コマンドごとにファイルへ書き、別の端末ですぐ使う）: AlmaLinux 10 の `PROMPT_COMMAND` は配列で、starship・WezTerm のシェル統合・zoxide が順番に意味を持って触っている（[starship.md 手順 3](../almalinux-setup.md#シェルのツール) の補足）。そこへ足す形は本書では扱わない
  - `set bell-style none`（ベルを消す）、`menu-complete`（Tab で候補を順に入れる）: 好みの幅が大きいので入れない
  - `shopt -s histappend`: `/etc/bashrc` が対話のシェルで入れている（手順 3 の補足）
- **atuin（履歴を SQLite に持ち、同期もする）は使わない**: 履歴の検索は [fzf](../almalinux-setup.md) の Ctrl+R で足りる。[導入元一覧](../tool-catalog.md#cli-定番の置き換え)の行のまま

---

## 統合前の記録: Homebrew（もとは homebrew.md）

もとの `homebrew.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「Homebrew」の手順 1 |
| 実施手順 2 | 「Homebrew」の手順 2 |
| 実施手順 3・4 | 「Homebrew」の手順 3 |
| 使い方の基本 | Homebrew の使い方の基本 |
| root のシェルでも使う（任意）の 1・2 | Homebrew を root のシェルでも使う（任意）の 1・2 |
| sudo でも使う（任意）の 1・2 | Homebrew を sudo でも使う（任意）の 1・2 |
| 更新 1・2 | 更新 2・3 |
| ロールバック 1〜3 | ロールバックの「Homebrew と bash-completion を消す」の手順 1〜3 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### Homebrew: 補足

#### Homebrew: 実施手順 / 手順 1: 補足: 依存パッケージの役割

| パッケージ | 用途 |
|---|---|
| `curl` | インストーラ自身と、ボトル・formula の取得 |
| `git` | `brew update` が Homebrew 本体と formula の索引を git で更新するため |
| `file` | インストーラと `brew` がバイナリの種別を判定するため |
| `procps-ng` | `pgrep` など。インストーラの事前チェックで使う |

コンテナでの実測では、`curl` は導入済みで `file` / `git` / `procps-ng` の 3 つが新規、依存を含めて 30 個ほどが入った（`git-core` / `openssh-clients` / `perl-*` など）。実機は最初から git が入っていた。

**`development-tools` グループは要らない。** インストーラの `Next steps` が勧めてくるが、あれは**ソースビルドをする場合**のもので、ボトルだけ使うなら入れなくてよい（手順 2 の補足）。

#### Homebrew: 実施手順 / 手順 2: 本文中の記録

   - 手順 3 は、その案内と同じ内容（この手順の補足に実測を載せた）

#### Homebrew: 実施手順 / 手順 2: 補足: 導入先を変えてはいけない

Homebrew の Linux 版がビルド済みのボトルを配っているのは **`/home/linuxbrew/.linuxbrew` に入っている場合だけ**。別の場所（`~/.homebrew` など）に入れると、`brew install` のたびに**すべてソースからビルドされる**。Raspberry Pi でこれをやると 1 つ入れるのに数十分かかる。

インストーラは `sudo` で `/home/linuxbrew` を作り、実行したユーザーの所有にする。したがって **root で実行してはいけないが、`sudo` できるユーザーである必要がある**。

コンテナでの実測（`NONINTERACTIVE=1` 付き。末尾の案内が本書の手順 3 の中身）:

```
==> Pouring portable-ruby-4.0.7.arm64_linux.bottle.tar.gz
Warning: /home/linuxbrew/.linuxbrew/bin is not in your PATH.
  Instructions on how to configure your shell for Homebrew
  can be found in the 'Next steps' section below.
==> Installation successful!
...
==> Next steps:
- Run these commands in your terminal to add Homebrew to your PATH:
    echo >> /home/<USER>/.bashrc
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"' >> /home/<USER>/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
- Install Homebrew's dependencies if you have sudo access:
    sudo dnf group install development-tools
  For more information, see:
    https://docs.brew.sh/Homebrew-on-Linux
- Run brew help to get started
- Further documentation:
    https://docs.brew.sh
```

Homebrew は自前の Ruby（`portable-ruby`）を持ってくるので、システムの Ruby は要らない。

`NONINTERACTIVE=1` を付けると `RETURN` の確認を飛ばす。**スクリプトやコンテナから流すとき専用**で、手で入れるときは付けない（本書の検証でだけ使っている）。

#### Homebrew: 実施手順 / 手順 4: 補足: brew config の読み方

コンテナでの実測:

```
$ brew config | head -12
HOMEBREW_VERSION: 7.0.6
ORIGIN: https://github.com/Homebrew/brew
HEAD: 570982948a8a194f0f42f43f4a5bce2d1c9f64cb
Last commit: 29 hours ago
Branch: stable
Core tap: N/A
Core cask tap: N/A
HOMEBREW_PREFIX: /home/linuxbrew/.linuxbrew
Homebrew Ruby: 4.0.7 => /home/linuxbrew/.linuxbrew/Homebrew/Library/Homebrew/vendor/portable-ruby/4.0.7/bin/ruby
CPU: quad-core 64-bit arm
Clang: N/A
Git: 2.52.0 => /bin/git
```

見るところは 3 つ:

- **`HOMEBREW_PREFIX` が `/home/linuxbrew/.linuxbrew`**（ここが違うとボトルが使えない）
- **`Branch: stable`**
- **`CPU` が `arm`**（`arm64_linux` のボトルが降りる）

`Core tap: N/A` と `Clang: N/A` は異常ではない（formula は API 経由で取得し、ボトルだけ使うならコンパイラは要らない）。

パスだけ知りたいときは `brew --prefix` / `brew --cellar` / `brew --repository`。

#### Homebrew: sudo でも使う（任意）: 検証状況の記録

> [!WARNING]
> - `/home/linuxbrew/.linuxbrew` は Homebrew を入れたユーザーの所有。`sudo` で打ったコマンドが `/usr/bin` などに無いと、そのユーザーが書き換えられるプログラムを root の権限で動かすことになる（そのユーザーを乗っ取られると、root まで取られる）
> - sudo の設定はホスト全体にかかる。このホストで `sudo` を使う、ほかのユーザーにも効く
> - この節は **x86_64 のコンテナでのみ検証した**。実機では本実行していない（[付録](#homebrew-付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)）

#### Homebrew: sudo でも使う（任意） / 手順 1: 補足: 置く 1 行と置き方、出力例

- `secure_path` は、sudo がコマンドを探す PATH で、動かすコマンドの `PATH` にもなる。AlmaLinux 10 の `/etc/sudoers` は `Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin`
- `secure_path` は 1 つの文字列の設定で、`+=` では足せない（`+=` は `env_keep` のような一覧の設定だけ）。既定の値を書き直し、その末尾に 2 つを足す
- 末尾に足すので、`/usr/bin` などにある RPM のコマンドが先に見つかる。`sudo git` や `sudo fdisk` が、Homebrew が依存として入れたものに置き換わらない
- `/etc/sudoers` の最後の行（`#includedir /etc/sudoers.d`）で、このディレクトリのファイルが後から読まれる。後から読まれた `secure_path` が勝つので、`/etc/sudoers` は書き換えない
- 先頭の `if` は、ほかで変えた `secure_path` を、この 1 行で消さないため。`sudo printenv PATH` は、sudo がコマンドに渡す PATH（`secure_path`）をそのまま出す
- ファイル名に `.` を入れない。sudo は `.` を含む名前のファイルを読まない（`homebrew.conf` は、警告も出ずに読まれなかった）
- `visudo -cf -` で 1 行の書式を確かめ、通ったときだけ置く。`"` を閉じない行は `stdin:1:35: unexpected line break in string` で止まり、ファイルは置かれなかった
- 書式を誤ったファイルを直接置いても、`sudo` は使えた。ただし、呼ぶたびに同じ誤りを表示し、その行を飛ばした
- `install -m 0440 /dev/stdin` は、root の所有でモードが 0440 の新しいファイルを作る
  - モードが 0644 だと、`sudo` は読むが、`visudo -c` が `bad permissions, should be mode 0440` で失敗した
  - 所有者が自分のユーザーだと、`sudo` は `is owned by uid <UID>, should be 0` と表示して読まなかった
- `fi` の前の `visudo -c` は、置いたファイルも含めて、書式・所有者・モードを確かめる。`/etc/sudoers.d` はモード 0750 で、自分のユーザーからは中を見られない

**出力例**: 最後の行の、コンテナでの実測（Homebrew のユーザーのシェルから）:

```
$ sudo bash -c 'printenv PATH; command -v brew'
/sbin:/bin:/usr/sbin:/usr/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin
/home/linuxbrew/.linuxbrew/bin/brew
```

ファイルを置く前は、1 行目が `/sbin:/bin:/usr/sbin:/usr/bin` だけで、2 行目は出なかった（終了コード 1）。

#### Homebrew: ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**（`--help` でオプションを確かめただけ。[付録](#homebrew-付録-コンテナでの検証記録2026-09-22)）

- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

#### Homebrew: 対象と検証環境

- **目的**: AlmaLinux 10 に [Homebrew](https://brew.sh/)（Linux 版。旧称 Linuxbrew）を入れて、**EPEL や AppStream に無い／古い CLI ツールを root 権限なしで新しい版のまま使える**ようにする
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **実機で本実行済み（2026-09-20）。`0dbb522` の直接追記版の実施手順 1〜4 を x86_64 のクリーン VM でも本実行済み（2026-10-06）**。現行版 `5da3478` の共通 bash 新規導入・実施手順 1〜4・root 自身の共通設定を、新しい VM で再検証した（[現行版の再検証](#homebrew-付録-現行の共通-bash-設定での再検証2026-10-06)）。既存ホストからの手動移行は行っていない。
  - 下表のホストに公式インストーラで `Homebrew 7.0.6` を入れ、`~/.bashrc` に `brew shellenv` を書いて常用中
  - **このリポジトリの Homebrew 系 17 本の手順書は、すべてこれを前提にしている**（実機に入っているのはそのうちの一部で、記録時点の `brew leaves` は 15 件。下表）
  - 本書の手順 1〜4 と[使い方の基本](../almalinux-setup.md#homebrew-の使い方の基本)・[更新](../almalinux-setup.md#更新)は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - 確認したこと: `Homebrew 7.0.6` が同じ場所に入る、`brew config` の `HOMEBREW_PREFIX` が一致する、`brew install jq` がボトルで入る
  - **本実行していないこと**: ロールバック（`uninstall.sh` の本実行）。実機でもコンテナでも実行していない（`--help` を見ただけ）
  - **実機の `~/.bashrc` の 1 行は `brew shellenv`（引数なし）で、本書が書く `brew shellenv bash` と違う**（[手順 3 の補足](../almalinux-setup.md#homebrew)）
  - [root のシェルでも使う](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節は、**x86_64 のコンテナでのみ検証した**（2026-09-30。[付録](#homebrew-付録-root-のシェルでも使う節のコンテナでの検証記録2026-09-30)）
    - 通したこと: その節の手順 1・2 を、この文書のコードブロックのまま流した。その節の手順 1 の `if … fi`（もとの手順 1）を重ねて実行し、その節の手順 2 の後に手順 1 をもう一度通した
    - 確認したこと: `su -`（root のパスワード）・`su`・ssh での root のログイン・`sudo -i`・`sudo -s` のどれでも Homebrew の `jq` と `nvim` が見つかる、`sudo jq` は見つからない、RPM の `jq` があると root では RPM が先、手順 2 で `/root/.bashrc` が元のファイルと同じ内容に戻る
    - 確認していないこと: 実機、aarch64、コンソールでの root のログイン、SELinux が Enforcing のホスト
    - 2026-10-02: その節のもとの手順 1・2 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）
    - 2026-10-05: 自分用の bash の設定を root のシェルにも入れたホストの箇条書き（その節の手順 1）は、その設定の検証の中で、代わりのコマンドを x86_64 のコンテナで流して確かめた（[ryo-aoki-pc/bash の docs/install.md の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-root-のシェルでも読む節の検証記録2026-10-05)）
  - [sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節は、**x86_64 のコンテナでのみ検証した**（2026-10-02。[付録](#homebrew-付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)）
    - 通したこと: その節の手順 1・2 を、この文書のコードブロックのまま、`sudo` のユーザーの端末に、ブラケットペーストの無しと有りで 1 回ずつ貼った。その節の手順 1 の `if … fi`（もとの手順 1）を重ねて貼り、その節の手順 2 の後に手順 1 をもう一度通した
    - 確認したこと: `sudo jq`・`sudo nvim`・`sudo -u`・`sudo -s`・`sudo -i`・`sudo` で動かすスクリプトで Homebrew のコマンドが見つかる、ほかの wheel のユーザーの `sudo` にも効く、RPM の `jq` があると `sudo` では RPM が先、`su -` と ssh での root のログインは変わらない、`EDITOR=nvim` の `sudoedit` と `sudo EDITOR=nvim visudo` が Homebrew の `nvim` で開く、既定と違う `secure_path` と書式の誤りではファイルを置かない、root のシェルでも使う節と両方通しても PATH が重ならない
    - 確認していないこと: 実機、aarch64、SELinux が Enforcing のホスト（置いたファイルのラベル）、LDAP などから配る sudo の設定、sudo の RPM を更新した後
    - 2026-10-02: その節のもとの手順 1・2 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | `7.0.6`（`/home/linuxbrew/.linuxbrew`、`Branch: stable`） | 同じ（`7.0.6`、同じ場所に新規導入） |
| `~/.bashrc` の行 | `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"`（**引数なし**） | `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"`（本書どおり） |
| 入れたもの | `brew leaves` が 15 件（`fd` / `ffmpeg-full` / `fzf` / `gdu` / `imagemagick-full` / `jq` / `lazygit` / `neovim` / `poppler` / `resvg` / `ripgrep` / `sevenzip` / `tree-sitter-cli` / `yazi` / `zoxide`）。その後 2026-09-23 に [ShellCheck / shfmt](../shellcheck.md) を足して 17 件 | `jq` 1 件のみ（動作確認用） |
| 占有サイズ | 2.8 GB | 216 MB |
| git | RPM の `git 2.52.0`（`/bin/git`） | 同じ |

> [!NOTE]
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`7.0.6`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### Homebrew: 実施前の状態

| 項目 | 状態 |
|---|---|
| Homebrew | 未導入（`command -v brew` が何も返さず、`/home/linuxbrew` も無い） |
| git | RPM の `git 2.52.0` が導入済み |
| EPEL | 有効（`epel-release 10-8.el10_2`） |
| `~/.bashrc` | AlmaLinux の既定のまま |

#### Homebrew: 選択した方針

AlmaLinux 10 aarch64 で「EPEL / AppStream に無い、または古い CLI ツール」を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `arm64_linux` のボトルが揃っていて**ソースビルドが要らない**。root 権限なしで upstream の最新版を追え、1 つの `brew upgrade` でまとめて上がる。占有は大きい（実機で 2.8 GB） | **採用** |
| EPEL / AppStream / CRB の RPM | root 権限で `dnf` に乗るのが利点。ただし目的のツールが**無い**（`eza` / `git-delta` / `starship` / `zoxide`）か、**古い**（`bat 0.24.0` / `neovim 0.10.1` / `fzf 0.58.0`）ことが多い。同版なら RPM を選ぶ（手順書では [btop.md](../btop.md) と、[image-tools.md](../image-tools.md) の Trivy が例。[ツール一覧](../tool-catalog.md)の fastfetch などもこの規則で RPM にした） | 併用（無い・古いときだけ Homebrew） |
| COPR | EL10 向けの chroot があるとは限らず、`epel-10-aarch64` の repomd が 403 になる例を実測している（[lazygit.md](../almalinux-setup.md#lazygit)）。zoxide の COPR（x86_64 だけ）も、Homebrew と同じ版なので 2026-10-03 に外した（[zoxide.md](#zoxide-選択した方針)）。WezTerm Nightly だけは、Homebrew の公式 tap の nightly が古く aarch64 に無いので、EL9 向けの COPR を流用している（[wezterm-nightly.md](../reference/almalinux-setup.md#wezterm-選択した方針)） | 不採用（ツールごとに当たり外れが大きい） |
| 各ツールの公式インストーラ / GitHub Releases | バイナリ 1 つで軽いが、**ツールごとに更新方法が違う**。17 本ぶん覚えることになる | 不採用（Homebrew に揃える） |
| `cargo install` / `go install` | toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

#### Homebrew: 完了時点の状態

**検証コンテナでの出力**（動作確認に `jq` を 1 つだけ入れた状態）:

```
$ brew --version
Homebrew 7.0.6
$ command -v brew
/home/linuxbrew/.linuxbrew/bin/brew
$ brew list --versions
jq 1.8.2
oniguruma 6.9.10
$ brew leaves
jq
$ brew deps --tree jq
jq
└── oniguruma
$ grep -n 'brew shellenv' ~/.bashrc
26:eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
$ du -sh /home/linuxbrew/.linuxbrew
216M	/home/linuxbrew/.linuxbrew
```

実機は同じ `7.0.6` で、`brew leaves` が 15 件、占有は 2.8 GB（`ffmpeg-full` と `imagemagick-full` が大きい）。

#### Homebrew: root のシェルで使うときの補足

[root のシェルでも使う](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節の補足。実測は x86_64 のコンテナで、その節の手順 1 の後のもの（[付録](#homebrew-付録-root-のシェルでも使う節のコンテナでの検証記録2026-09-30)）。

  root で Homebrew 版を使うときは、フルパス（`/home/linuxbrew/.linuxbrew/bin/<コマンド>`）で呼ぶ
- **`brew install` などは root では断られる**: PATH で見つかるが、通常のホストでは `Error: Running Homebrew as root is extremely dangerous and no longer supported.` で止まる（終了コード 1）
  - 断られなかったのは `brew --version`・`brew --prefix`・`brew help`・引数の無い `brew list` だけ。[使い方の基本](../almalinux-setup.md#homebrew-の使い方の基本)の表のコマンドは、どれも断られた
  - コンテナの中（`/.dockerenv` か `/run/.containerenv` がある、または `/proc/1/cgroup` に `docker` などがある）では断られない（`brew.sh` の `check-run-command-as-root`）。検証では、これらを外したコンテナで確かめた
- **設定ファイルは root のものを読む**: root で動かした Neovim の `stdpath("config")` は `/root/.config/nvim` だった。自分の `~/.config` の設定は使われない
- **シェルの初期化は `/root/.bashrc` に足さない**: [zoxide](../almalinux-setup.md) や [starship](../almalinux-setup.md) の `eval "$(… init bash)"` を書くと、root のシェルを開くたびに、Homebrew のユーザーが所有するコマンドが root で動く
  - 自分用の bash の設定を root のシェルにも入れると（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash) の [docs/install.md の「root のシェルでも読む」](https://github.com/ryo-aoki-pc/bash/blob/main/docs/install.md#root-のシェルでも読む任意)）、これらの初期化も root で動く。自分専用のマシンで、一般ユーザーを信用できるときだけにする
- **この節では sudo の `secure_path` を変えない**: [root のシェルでも使う](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節は、root のシェルが対象。`sudo <コマンド>` で使うときは、[sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通すか、フルパスで渡す（`sudo /home/linuxbrew/.linuxbrew/bin/jq --version` は `jq-1.8.2` を返した）

#### Homebrew: sudo で使うときの補足

[sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節の補足。実測は x86_64 のコンテナで、その節の手順 1 の後のもの（[付録](#homebrew-付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)）。

#### Homebrew: 注意点 / 手順 0: 本文中の記録

  - 入れるものの一覧の後に `==> Do you want to proceed with the installation? [y/n]` と聞き、答えは Enter を待たずに 1 文字で読む（[homebrew-offline.md 手順 4](../homebrew-offline.md#実施手順) の補足の実測）

#### Homebrew: 注意点 / 手順 0: 本文中の記録

  - 7.0.7 のソースで確かめた仕様。過去の付録の「依存が残った」という実測は、そのときの版と条件での記録として残している

#### Homebrew: 参照

- [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux) — `/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、要件
- [brew.sh](https://brew.sh/) — インストーラのワンライナーと概要
- [Homebrew — FAQ](https://docs.brew.sh/FAQ) — 更新・掃除・アンインストールのよくある質問
- [Homebrew/install](https://github.com/Homebrew/install) — `install.sh` と `uninstall.sh` の中身
- [Homebrew 7.0.7 の leaves](https://github.com/Homebrew/brew/blob/7.0.7/Library/Homebrew/cmd/leaves.rb) — `brew leaves` のヘルプと実装（2026-10-05 に照合）
- [Homebrew 7.0.7 の install](https://github.com/Homebrew/brew/blob/7.0.7/Library/Homebrew/cmd/install.rb)・[upgrade](https://github.com/Homebrew/brew/blob/7.0.7/Library/Homebrew/cmd/upgrade.rb)・[uninstall](https://github.com/Homebrew/brew/blob/7.0.7/Library/Homebrew/cmd/uninstall.rb)・[cleanup](https://github.com/Homebrew/brew/blob/7.0.7/Library/Homebrew/cleanup.rb) — 確認を聞く条件と、不要な依存の自動削除（2026-10-05 に照合）
- `man sudoers`（`secure_path`、`#includedir` で読まれないファイル名、`Defaults` の上書き）・`man visudo`（`-c`、`-f`） — [sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節の 1 行と確かめ方
- `brew help` / `man brew` / `brew config` — サブコマンドと環境の確認

#### Homebrew: 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で手順 1〜4 と[使い方の基本](../almalinux-setup.md#homebrew-の使い方の基本)・[更新](../almalinux-setup.md#更新)を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、インストーラだけ `NONINTERACTIVE=1` を付けている。

| 手順 | 結果 |
|---|---|
| 実施前 | `command -v brew` は無出力、`/home/linuxbrew` も無い |
| 1. 依存パッケージ | `curl` は導入済み。`file` / `git` / `procps-ng` が新規で、依存込み 30 個ほど（`git-core` / `openssh-clients` / `perl-*` / `groff-base` など）。`curl` と `openssl-libs` は `Upgrading` に解決された |
| 2. インストーラ | `portable-ruby-4.0.7.arm64_linux` を `Pouring` して `==> Installation successful!`。所要 1 分弱。`Warning: /home/linuxbrew/.linuxbrew/bin is not in your PATH.` と `==> Next steps:`（本文に全文を引用）が出た |
| 3. PATH | `~/.bashrc` の 26 行目に `eval "$(... brew shellenv bash)"` が入り、同じシェルで `brew --version` → `Homebrew 7.0.6` |
| 4. 検証 | `command -v brew` → `/home/linuxbrew/.linuxbrew/bin/brew`。`brew config` の `HOMEBREW_PREFIX` / `Branch: stable` / `CPU: quad-core 64-bit arm` を確認。`brew --prefix` / `--cellar` / `--repository` も期待どおり |
| 使い方の基本 | 導入直後は `brew list --versions` / `brew leaves` / `brew outdated` がいずれも無出力。`brew install jq` で `oniguruma` → `jq` の順にボトルが降り（`Pouring jq--1.8.2.arm64_linux.bottle.1.tar.gz`）、`brew leaves` は `jq` だけを返した。`brew deps --tree jq` は `jq └── oniguruma`。`brew autoremove --dry-run` は無出力 |
| 更新 | `brew update` → `Already up-to-date.`、`brew outdated` は無出力（導入直後なので当然） |
| ロールバック | **本実行していない。** `uninstall.sh` を落として `--help` だけ見た。`-n, --dry-run` / `-f, --force` / `-p, --path=PATH` / `--skip-cache-and-logs` があり、`NONINTERACTIVE` が非空なら `--force` 相当になることを確認 |
| 占有 | `jq` を 1 つ入れた状態で 216 MB |

実機側は読み取りだけで次を確認した: `brew --version` → `7.0.6`、`brew config` がコンテナと同じ `HEAD` / `Branch: stable`、`~/.bashrc:26` が**引数なしの `brew shellenv`**、`brew leaves` が 15 件、`brew outdated` が無出力、占有 2.8 GB、`/home/linuxbrew/.linuxbrew/Homebrew` の作成が 2026-09-20 17:26。

##### Homebrew: 未確認事項

- `--dry-run` の実出力（`uninstall.sh --help` に記載があることだけ確認した）
- `brew cleanup` の効果と、掃除後の占有
- 導入先を `/home/linuxbrew/.linuxbrew` 以外にした場合に本当にソースビルドになるか
- 複数ユーザーで共有する場合の権限
- `brew analytics off` の挙動
- bash 以外のシェル（zsh / fish）での `brew shellenv`
- **[ロールバック](../extra/almalinux-setup.md#ロールバック)の本実行**（`uninstall.sh` は `--help` を見ただけで、実機でもコンテナでも走らせていない）

#### Homebrew: 付録: root のシェルでも使う節のコンテナでの検証記録（2026-09-30）

[root のシェルでも使う（任意）](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)を足したときの記録。x86_64 のクラウドホスト上の Docker 29.3.1（cgroup v1）で、使い捨てのコンテナを立てて行った。実機で加えた変更は無い。

**環境**:

- `quay.io/almalinuxorg/almalinux:10`（AlmaLinux 10.2）を `--network host` で立て、プロキシの CA、dnf の `proxy=`、`almalinux-*.repo` の `baseurl=` を入れた
- `sudo`・`passwd`・`openssh-server` などを dnf で入れ、NOPASSWD の `sudo` を持つ非 root ユーザー（`<USER>`）を作った。root には、検証のためだけにパスワードを付けた
- Homebrew は[実施手順](../almalinux-setup.md#homebrew)の手順 1〜3 を、インストーラだけ `NONINTERACTIVE=1` を付けて通した（`Homebrew 7.0.7`）。`brew install jq` と `brew install neovim` で、`jq 1.8.2` と `neovim 0.12.5_1` を入れた
- 版: `sudo-1.9.17-10.p2.el10_2.6`、`rootfiles-8.1-54.el10`、`bash-5.2.26-6.el10`、`util-linux-2.40.2-18.el10`、`openssh-server-9.9p1-27.el10_2.alma.1`
- `/etc/sudoers` の `secure_path` は `/sbin:/bin:/usr/sbin:/usr/bin`。`/root/.bash_profile` は `~/.bashrc` を読む
- `/root/.bashrc` は `/etc/bashrc` を読み、`$HOME/.local/bin:$HOME/bin` を PATH の先頭に足し、`rm`・`cp`・`mv` の alias を置く。非対話のシェルで途中で抜ける行は無い

**流し方**: 節のコードブロックを文書から抜き出し、`<USER>` の `bash -i` の標準入力に 1 手順ずつ流した。対話のシェル（`su -`・`su`・`sudo -i`・`sudo -s`・`ssh -tt`）は Python の `pty` で開き、パスワードと `printenv PATH`・`type -a jq`・`exit` を送った。

| 手順・確認 | 結果 |
|---|---|
| 節の手順 1 の前 | `sudo -i bash -c 'printenv PATH; command -v brew'` は `/root/.local/bin:/root/bin:/usr/local/sbin:/sbin:/bin:/usr/sbin:/usr/bin` だけで、終了コード 1。`sudo su - -c 'printenv PATH'` は `/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin`。`sudo jq --version` は `sudo: jq: command not found` |
| 節の手順 1 の `if … fi`（もとの手順 1） | `/root/.bashrc` の末尾に 1 行入り（22 行から 23 行）、その行が表示された |
| 節の手順 1 の確かめの行（もとの手順 2） | その手順の補足の出力例のとおり |
| 節の手順 1 の `if … fi`（もとの手順 1）をもう一度 | `中断: /root/.bashrc に既にある`。ファイルは変わらない |
| `su -`（`<USER>` から、root のパスワード） | PATH は `/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin`。`type -a jq` は `jq is /home/linuxbrew/.linuxbrew/bin/jq` |
| `su`（`-` 無し） | PATH は `/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin` の後ろに 2 つ（`<USER>` の PATH は引き継がない）。`jq` は Homebrew 版 |
| `sudo -i`（対話） | 節の手順 1 の確かめの行（もとの手順 2）と同じ PATH。`jq` は Homebrew 版 |
| `sudo -s`（対話） | `HOME=/root`。PATH は `/root/.local/bin:/root/bin:/sbin:/bin:/usr/sbin:/usr/bin` の後ろに 2 つ。`jq` は Homebrew 版 |
| ssh での root のログイン | 公開鍵で `127.0.0.1:2222` の sshd に入った。コマンドを渡した `ssh root@… 'printenv PATH; command -v jq'` も、`ssh -tt` のログインシェルも、PATH の末尾に 2 つが付き、`jq` は Homebrew 版 |
| root の `su - -c`・`bash -l -c` | どちらも PATH の末尾に 2 つが付き、`command -v jq` は Homebrew 版 |
| `sudo jq`・`sudo nvim` | どちらも `command not found`（対象外のまま）。`sudo /home/linuxbrew/.linuxbrew/bin/jq --version` は `jq-1.8.2` |
| 入れ子のシェル | `sudo -i bash -ic 'printenv PATH'` でも 2 つは 1 回ずつ。同じシェルで `. ~/.bashrc` を 2 回読んでも、PATH の `linuxbrew` を含む要素は 2 つのまま |
| RPM の jq | AppStream の `jq-1.7.1-11.el10_2.2` を入れると、root の `type -a jq` は `/bin/jq` → `/usr/bin/jq` → Homebrew の順、`<USER>` は Homebrew → `/usr/bin/jq` → `/bin/jq` の順。RPM の `jq --version` は `jq-` とだけ出した（Homebrew 版は `jq-1.8.2`） |
| Neovim | root の `command -v nvim` は `/home/linuxbrew/.linuxbrew/bin/nvim`、`nvim --version` は `NVIM v0.12.5`、`stdpath("config")` は `/root/.config/nvim`（`<USER>` では `/home/<USER>/.config/nvim`） |
| root の `brew` | 同じ中身のコンテナを `--cgroupns=private` で立て直し、`/.dockerenv` を消して確かめた。`brew config`・`brew install tree`・`brew list --versions`・`brew leaves`・`brew info jq`・`brew deps --tree jq`・`brew outdated`・`brew autoremove --dry-run`・`brew uninstall jq`・`brew update` は `Error: Running Homebrew as root is extremely dangerous and no longer supported.`（終了コード 1）。`brew --version`・`brew --prefix`・`brew help`・引数の無い `brew list` は動いた。目印を外す前のコンテナでは、root の `brew` は断られない |
| 節の手順 2 | `0` と出た。`/root/.bashrc` の SHA-256 が、節の手順 1 の前に写したものと一致した。`sudo -i` の PATH から 2 つが消え、`command -v brew` は終了コード 1 |
| 節の手順 2 の後に手順 1 | 1 回目と同じ結果 |

##### Homebrew: 未確認事項（root の節）

- 実機（aarch64 の Raspberry Pi 5）での実行
- コンソール（仮想端末や GNOME のログイン画面）での root のログイン。検証では root の `bash -l -c` を代わりにした
- SELinux が Enforcing のホスト（検証のコンテナには SELinux が無い）
- 端末への貼り付け（検証は標準入力に流しただけ。ブラケットペーストの有無も見ていない）
- bash 以外の root のシェル（zsh など）

#### Homebrew: 付録: sudo でも使う節のコンテナでの検証記録（2026-10-02）

[sudo でも使う（任意）](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)を足したときの記録。x86_64 のクラウドホスト上の Docker 29.6.2（cgroup v1）で、使い捨てのコンテナを立てて行った。実機で加えた変更は無い。

**環境**:

- `quay.io/almalinuxorg/10-init`（AlmaLinux 10.2、`sha256:a91c1066…fd73`）を `--privileged --cgroupns=private --network host` で立て、systemd を PID 1 にして、sshd（ポート 2222）と systemd-logind を動かした
- プロキシの CA、dnf の `proxy=`、`almalinux-*.repo` の `baseurl=`、ログインシェルの `HTTPS_PROXY` を入れた
- wheel の一般ユーザーを 2 人（`<USER>`・`<USER2>`）作った。どちらの `sudo` も、既定の `%wheel ALL=(ALL) ALL` のまま。root には、検証のためだけにパスワードを付けた
- Homebrew は、`<USER>` の ssh のログインシェル（umask 0022）で[実施手順](../almalinux-setup.md#homebrew)の手順 1〜3 を通した
  - インストーラだけ `NONINTERACTIVE=1` を付け、そのときだけ NOPASSWD の `sudo` の設定を置いた（終わったら消した）
  - `Homebrew 7.0.7`。`brew install jq neovim gdu glib` で `jq 1.8.2`・`neovim 0.12.5_1`・`gdu 5.37.0`・`glib 2.90.0` を入れた
  - `docker exec` は umask が 0000 で、そこから入れた 1 回目は `/home/linuxbrew/.linuxbrew/bin` などが 0777 になった。コンテナを作り直し、ssh から入れ直した
- Homebrew の root の断り（`brew.sh` の `check-run-command-as-root`）が効くように、`/.dockerenv` を消し、`/proc/1/cgroup` に `docker` が出ないようにした（`--cgroupns=private`）
- 版: `sudo-1.9.17-10.p2.el10_2.6`、`bash-5.2.26-6.el10`、`coreutils-single-9.5-8.el10_2`、`vim-minimal-9.1.083-9.el10_2.20`、`glib2-2.80.4-12.el10_2.22`、`openssh-server-9.9p1-28.el10_2.alma.1`、`systemd-257-23.el10_2.2.alma.1`
- `/etc/sudoers` の 88 行目は `Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin`、最後の 120 行目は `#includedir /etc/sudoers.d`。`/etc/sudoers.d` は `root:root` の 0750 で、空
- `/home/linuxbrew` は `root:root` の 0755、`/home/linuxbrew/.linuxbrew/bin` と `sbin` は `<USER>` の所有の 0775

**流し方**:

- ホストの tmux 3.4 のペイン（200x50）から `docker exec -it … ssh -t -p 2222 <USER>@127.0.0.1` でログインした
- この文書から節のブロック（折り畳みの外のもの）を抜き出し、手順ごとに `tmux paste-buffer` で貼った（[tmux.md の付録](#tmux-付録-コンテナでの検証記録2026-10-01)と同じ形）
  - 1 回目はブラケットペースト無し、2 回目は `paste-buffer -p`（ブラケットペースト有り。貼った後に Enter を送った）
- 画面は `tmux capture-pane` で読んだ。エディタは、別の `docker exec` から `/proc/<PID>/exe` と `/proc/<PID>/environ` で、実体・ユーザー・`HOME`・`PATH` を見た
- `<USER2>` と、開いたままの `sudo -s` は、別の tmux のペインから同じように ssh でログインして確かめた

| 手順・確認 | 結果 |
|---|---|
| 節の手順 1 の前 | `sudo printenv PATH` は `/sbin:/bin:/usr/sbin:/usr/bin`。`sudo jq --version` と `sudo brew --version` は `sudo: …: command not found`（終了コード 1）。節の手順 1 の確かめの行（もとの手順 2）は 1 行目だけを出し、終了コード 1 |
| 節の手順 1 の前のエディタ | `EDITOR=nvim VISUAL=nvim sudoedit /etc/motd` は `/usr/bin/vi` を `<USER>` で動かした（`HOME` と `PATH` は `<USER>` のもの）。`sudo EDITOR=nvim visudo` と `sudo visudo` は `/usr/bin/vi` を root で動かした |
| 同（フルパス） | `SUDO_EDITOR=/home/linuxbrew/.linuxbrew/bin/nvim sudoedit /etc/motd` は Homebrew の `nvim` を `<USER>` で動かし、`stdpath("config")` は `/home/<USER>/.config/nvim`。`sudo EDITOR=/home/linuxbrew/.linuxbrew/bin/nvim visudo` は Homebrew の `nvim` を root で動かし、`stdpath("config")` は `/root/.config/nvim` |
| 節の手順 1 の `if … fi`（もとの手順 1） | `stdin: parsed OK`・`/etc/sudoers: parsed OK`・`/etc/sudoers.d/homebrew: parsed OK`。置いたファイルは `root:root` の 0440（116 バイト）で、中身はその手順の `line` の 1 行 |
| 節の手順 1 の確かめの行（もとの手順 2） | その手順の補足の出力例のとおり |
| 節の手順 1 の `if … fi`（もとの手順 1）をもう一度 | `中断: sudo の PATH に Homebrew が既にある`。ファイルの SHA-256 は変わらない |
| 各入口 | [sudo で使うときの補足](../reference/almalinux-setup.md#homebrew-sudo-で使うときの補足)の表のとおり。`sudo -s` は `HOME=/root`。`sudo -u nobody jq --version` は `jq-1.8.2`。`sudo su - -c 'printenv PATH'`・`su -`（root のパスワード）・ssh での root のログインは `/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin` で、`jq` は見つからない |
| `<USER2>` | 自分の PATH に Homebrew は無く、`command -v jq` は終了コード 1。`sudo jq --version` は `jq-1.8.2` |
| エディタ（節の後） | `EDITOR=nvim VISUAL=nvim sudoedit /etc/motd` は Homebrew の `nvim` を `<USER>` で動かし、`stdpath("config")` は `/home/<USER>/.config/nvim`。`sudo EDITOR=nvim visudo` は Homebrew の `nvim` を root で動かし、`stdpath("config")` は `/root/.config/nvim` |
| `EDITOR` を export したとき | `export EDITOR=nvim VISUAL=nvim` の後の `sudo visudo` は、節の前も後も `/usr/bin/vi`。節の後の `sudoedit /etc/motd` は Homebrew の `nvim` |
| `sudo nvim` | `NVIM v0.12.5`。`stdpath("config")` は `/root/.config/nvim` |
| RPM の jq | AppStream の `jq-1.7.1-11.el10_2.2` を入れると、`sudo jq --version` は `jq-`、`sudo bash -c 'type -a jq'` は `/bin/jq` → `/usr/bin/jq` → Homebrew の順。`sudo env PATH="$PATH" jq --version` は `jq-1.8.2`。消した後の `sudo jq --version` は `jq-1.8.2` |
| コマンドの数 | Homebrew の `bin` と `sbin` に 231 個。`/usr/bin`・`/usr/sbin` と同じ名前が 135 個、無いものが 96 個 |
| gdu と gsettings | `sudo gdu-go --version` は `v5.37.0`。`~/.local/bin/gdu` のリンクは `<USER>` では動き、`sudo gdu --version` は `sudo: gdu: command not found`。`sudo sh -c 'command -v gsettings'` と `sudo -u <USER2> env sh -c 'command -v gsettings'` は `/bin/gsettings`（`<USER>` の `command -v gsettings` は Homebrew の `glib` のもの） |
| root の brew | `sudo brew --version` は `Homebrew 7.0.7`。`sudo brew install tree` は `Error: Running Homebrew as root is extremely dangerous and no longer supported.`（終了コード 1）。`sudo brew services list` と `sudo brew services start jq` は `Error: Need to download https://formulae.brew.sh/api/internal/packages.x86_64_linux.jws.json but cannot as root!`（終了コード 1。`<USER>` で `brew update` した後も同じ）。`/home/linuxbrew` の下に root の所有のファイルはできなかった |
| root の節との組み合わせ | root の節の手順 1 の後、`sudo -i` と `sudo -s` の PATH で 2 つは 1 回ずつ。この節の手順 2 の後も、`sudo -i` と `sudo -s` には root の節の 2 つが残り、`sudo jq` は `command not found` |
| 同（この節だけ） | root の節の手順 1 の確かめの行（もとの手順 2）は、`/root/.bashrc` に書く前から 2 つと `brew` を出した。root の節の手順 2 の後も `sudo -i` に 2 つが残った。`sudo su - -c 'printenv PATH; command -v brew'` は、root の節の行があるときだけ `brew` を出した |
| 節の手順 2 | `/sbin:/bin:/usr/sbin:/usr/bin`。`/etc/sudoers.d` は空に戻った。この後の `sudo -E printenv PATH` は `/sbin:/bin:/usr/sbin:/usr/bin` |
| 節の手順 2 の後に手順 1 | 1 回目と同じ結果。ファイルの SHA-256 も同じ |
| 開いたままのシェル | 別のペインで開いていた `sudo -s` は、節の手順 1 の後も 2 つが無く、開き直すと付いた。節の手順 2 の後も 2 つが残り、開き直すと消えた |
| 既定と違うホスト | root で `/etc/sudoers.d/site`（`Defaults secure_path = /usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin`、0440）を置くと、節の手順 1 の `if … fi`（もとの手順 1）は `中断: sudo の PATH が AlmaLinux 10 の既定（/sbin:/bin:/usr/sbin:/usr/bin）と違う` で止まり、`homebrew` は作られなかった |
| 書式の誤り | 節の手順 1 の `line` を `'Defaults secure_path = "/sbin:/bin'` に変えた写しは、`stdin:1:35: unexpected line break in string` を出し、`homebrew` を置かなかった。同じ行のファイルを root で直接置くと、`sudo` は呼ぶたびに同じ誤りを表示したが、終了コードは 0 で、PATH は既定のままだった（`visudo -c` は終了コード 1） |
| 所有者・モード・名前 | `<USER>` の所有のファイルは `sudo: /etc/sudoers.d/zzowner is owned by uid <UID>, should be 0` と出て読まれなかった。root の所有で 0644 のファイルは読まれたが、`visudo -c` が `bad permissions, should be mode 0440`。`homebrew.conf` という名前のファイルは、何も出ずに読まれなかった |
| 日本語のロケール | コンテナのイメージは訳を入れない（`%_install_langs C.utf8`）ので、それを外して `sudo` を入れ直した。`LANG=ja_JP.UTF-8` では、`visudo -c` は `/etc/sudoers: 正しく構文解析されました`、節の前の `sudo jq --version` は `sudo: jq: コマンドが見つかりません` |
| 2 回目（ブラケットペースト有り） | 節の手順 1、手順 1 の `if … fi`（もう一度）、手順 2、手順 1、手順 2 が、1 回目と同じ結果 |

##### Homebrew: 未確認事項（sudo の節）

- 実機（aarch64 の Raspberry Pi 5、x86_64 の PC）での実行
- SELinux が Enforcing のホスト（`install` で置いたファイルのラベル。検証のコンテナには SELinux が無い）
- LDAP や SSSD から配る sudo の設定
- `sudo` の RPM を更新して、`/etc/sudoers` の既定の `secure_path` が変わったとき
- root の Homebrew の API のキャッシュがあるときの `sudo brew services`（検証では、どれも API の取得で止まった）
- bash 以外のシェル

---

#### Homebrew: 付録: クリーン VM での検証記録（2026-10-06）

**検証対象**: `0dbb522` の、各手順で `~/.bashrc` などへ設定を直接追記する版。以下の手順番号と「本文」はこの版を指す。検証後に共通 bash 設定へ統一された現行版（`0bc9970`）の設定リポジトリの新規導入・既存設定からの移行は、今回の VM では実行していない。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証対象版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順（`0dbb522`）**: 実施手順 1〜4。

**結果**: 公式インストーラーの sudo のパスワード確認と RETURN の確認に答え、Homebrew 7.0.8 が `/home/linuxbrew/.linuxbrew` に入った。本文どおり `brew shellenv bash` を `~/.bashrc` に足し、`brew --version`・`brew config`・PATH を確認した。検証用 sudo は通常のコマンドを NOPASSWD にしていたが、インストーラーの `sudo -v` はパスワードを要求した。パスワードを入力して進め、sudoers は変更しなかった。

ボトルの取得中には `Landlock ABI 10 or later is required to deny all network access; found ABI 6` という警告が出た。Homebrew は、このカーネルが対応する制限を適用すると表示し、導入は続行して成功した。警告だけで導入失敗とは扱わない。

**今回の未確認範囲**: root・sudo で Homebrew を使う任意節、更新・ロールバックは今回流していない。

#### Homebrew: 付録: 現行の共通 bash 設定での再検証（2026-10-06）

`5da3478` の実施手順 1〜4 を、公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing）で通した。先に README の共通 bash の clone と `install.sh` を実行し、OS 既定の `~/.bashrc` に読み込み口だけを設定した。SSH の対話 PTY でインストーラの VM 専用パスワードと RETURN に答えた。

Homebrew 7.0.8 が標準 prefix に入り、手順 3 の `. ~/.bashrc` で `/home/linuxbrew/.linuxbrew/bin/brew` が見つかった。インストーラの案内する `brew shellenv` の行は追加していない。`brew config` の prefix と stable branch も一致した。依存 RPM は Workstation に既にあり、追加は無かった。

一般ユーザーの共通設定の再実行で、`~/.bashrc`・元の控え・`~/.bash_profile` の SHA256 は変わらず、読み込み口は 1 行、控えは 0600 だった。root 自身にも共通 bash を新規導入し、root の対話シェルで Homebrew の PATH と版を確認した。sudo の `secure_path` を変更する任意節、Homebrew の更新・削除はこの再検証では行っていない。

#### Homebrew: 手順中の実測・検証状況の記録

- `brew upgrade` も 7.0.7 では ask mode が既定。名前を指定した場合はその名前以外も更新する計画、名前を省略した場合は更新対象があるときに、TTY で確認する（公式ソースで確認。更新対象がある状態での表示は未確認）

#### Homebrew: 手順中の実測・検証状況の記録

- **占有が大きい**: 実機で 2.8 GB。`brew cleanup` で古い版とキャッシュを掃除できる

#### Homebrew: sudo で使うときの補足

- **RPM と同じ名前のコマンドは、`sudo` でも RPM が先**: AppStream の `jq-1.7.1` も入れると、`sudo jq --version` は RPM の `jq-` を返した。`sudo bash -c 'type -a jq'` は `/bin/jq` → `/usr/bin/jq` → Homebrew の順。`sudo` で Homebrew 版を使うときは、フルパスで呼ぶ
- **依存として入ったコマンドも `sudo` で動く**: 検証では `jq`・`neovim`・`gdu`・`glib` と依存で 231 個のコマンドが入った
  - RPM と同じ名前の 135 個（`glib` の依存の util-linux の `fdisk` など）は、RPM が先
  - 残りの 96 個（`python3.14`・`sqlite3` など）が、`sudo` で動くようになった
- **`sudo` を使う、ほかのユーザーにも効く**: 自分の PATH に Homebrew の無い、別の wheel のユーザーでも、`sudo jq --version` は `jq-1.8.2` を返した
- **設定ファイルは root のものを読む**: `sudo nvim` の `stdpath("config")` は `/root/.config/nvim` だった（root のシェルと同じ）
- **`sudoedit` と `visudo` は、この節の前は黙って `vi` で開いた**: エディタを `secure_path` で探し、見つからないと `/usr/bin/vi` を使う。`EDITOR=nvim` の `sudoedit /etc/motd` も `sudo EDITOR=nvim visudo` も、エラーを出さずに `/usr/bin/vi` だった
  - `sudo visudo` は、`EDITOR` を export していても、この節の後も `/usr/bin/vi` だった（sudo が `EDITOR` を渡さない）。`nvim` で開くなら `sudo EDITOR=nvim visudo` と打つ
- **`sudoedit` だけなら、この節は要らない**: `SUDO_EDITOR=/home/linuxbrew/.linuxbrew/bin/nvim sudoedit <ファイル>` は、この節の前でも Homebrew の `nvim` を自分のユーザーで開き、`stdpath("config")` は自分の `~/.config/nvim` だった
- **`brew install` などは root では断られる**: `sudo brew install tree` は `Error: Running Homebrew as root is extremely dangerous and no longer supported.`（終了コード 1）。`sudo brew --version` は動いた
  - `brew services` は root の断りから外されている（`brew.sh` の `check-run-command-as-root`）。ただし `sudo brew services list` は `Error: Need to download https://formulae.brew.sh/api/internal/packages.x86_64_linux.jws.json but cannot as root!` で止まった（自分のユーザーで `brew update` した後も同じ）
- **[root のシェルでも使う](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節と両方通してもよい**: `/root/.bashrc` の `case` が足さないので、`sudo -i`・`sudo -s` の PATH で 2 つは重ならなかった。片方を戻しても、もう一方の 2 つは残る
- **採らなかった形**
  - `sudo -E`: PATH は `secure_path` に置き換わる（`sudo -E printenv PATH` は、この節の前は `/sbin:/bin:/usr/sbin:/usr/bin`）
  - `alias sudo='sudo env PATH="$PATH"'`: 自分の PATH を丸ごと渡すので、Homebrew が先頭になる。RPM の `jq` があっても、`sudo env PATH="$PATH" jq --version` は Homebrew の `jq-1.8.2` を返した
  - `/usr/local/bin` や `~/.local/bin` にリンクを張る: どちらも AlmaLinux 10 の `secure_path` に無い。`~/.local/bin/gdu` のリンク（[gdu.md の「gdu の名前で呼ぶ」](../gdu.md#gdu-の名前で呼ぶ任意)）は、この節を通しても `sudo gdu` で `command not found` だった
- **Homebrew を消す前に、この節を戻す**: 公式のアンインストーラ（`uninstall.sh`）は `/etc/sudoers.d` に触れない（中に `sudoers` の文字が無い）。残すと、`secure_path` に `/home/linuxbrew/.linuxbrew/bin` が残る

### Homebrew: 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

#### Homebrew: 補足

  - 7.0.7 のヘルプでは、指定した formula / cask だけを入れる計画と、TTY が無い実行では確認を省く。コンテナで確認が出なかった記録だけでは、端末でも出ないとは判断できない

---

## 統合前の記録: Flatpak（もとは flatpak.md）

もとの `flatpak.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜3 | 「Flatpak と Flathub」の手順 1 |
| 実施手順 4〜7 | 「Flatpak と Flathub」の手順 2〜5 |
| 使い方の基本 | Flatpak の使い方の基本 |
| 更新 1 | 更新 4 |
| ロールバック 1〜4 | ロールバックの「Flatpak・RPM Fusion・EPEL を消す」の手順 1〜4 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### Flatpak: 補足

#### Flatpak: 操作上の注意と併記されていた記録

     - `6E5C 05D9 79C7 6DAF 93C0 8135 4184 DD4D 907A 7CAE`（Flathub Repo Signing Key &lt;flathub@flathub.org&gt;、有効期限 2027-06-14）

#### Flatpak: 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 のコンテナと VM で検証した手順書**で、実機と aarch64 では通していない。VM ではメニューと Flatseal の実画面を確認したが、GNOME Software の検索には出なかった（[対象と検証環境](#flatpak-対象と検証環境)）。

#### Flatpak: 実施手順 / 手順 2: 補足: AlmaLinux 10 の flatpak にはリモートが無い

AlmaLinux の `flatpak` パッケージは**リモートを 1 つも登録しない**。素のコンテナに入れた直後の実測（`/var/lib/flatpak/repo` は最初のリモートを足したときに作られる）:

```
$ rpm -q flatpak
flatpak-1.16.0-9.el10_2.1.x86_64
$ flatpak --version
Flatpak 1.16.0
$ flatpak remotes --show-details
error: While opening repository /var/lib/flatpak/repo: opening repo: opendir(/var/lib/flatpak/repo): No such file or directory
```

素のコンテナでは `dnf install flatpak` が依存込みで 138 パッケージ（ダウンロード 92 MB、展開後 323 MB）を入れた。

- サンドボックスの `bubblewrap`、`ostree-libs`、`polkit`、`xdg-desktop-portal`、`gnupg2`（手順 4 で使う `gpg`）などが含まれる
- デスクトップのあるホストでは依存の多くが既に入っているので、数はこれより少ないはず（未確認）

GNOME の `gnome-software` パッケージは `flatpak` に依存し、Flatpak 用のプラグイン（`/usr/lib64/gnome-software/plugins-21/libgs_plugin_flatpak.so`）を含む（`dnf repoquery` で確認）。したがって GNOME のデスクトップには flatpak が最初から入っていることが多い（このリポジトリの 2 台とも入っていた。[実施前の状態](#flatpak-実施前の状態)）。

#### Flatpak: 実施手順 / 手順 6: 補足: 一緒に入る runtime

Flatpak のアプリは**runtime**（共通ライブラリの束）の上で動く。Flatseal は GNOME 50 の runtime（`org.gnome.Platform`）を使うので、**初回はアプリ本体（1 MB 弱）よりも runtime のほうがずっと大きい**。コンテナでの実測（プロンプトに答えた後の表示）:

```
Required runtime for com.github.tchx84.Flatseal/x86_64/stable (runtime/org.gnome.Platform/x86_64/50) found in remote flathub
Do you want to install it? [Y/n]: y

com.github.tchx84.Flatseal permissions:
    ipc       fallback-x11         wayland              x11
    dri       file access [1]      dbus access [2]

    [1] /var/lib/flatpak/app:ro, xdg-data/flatpak/app:ro,
        xdg-data/flatpak/overrides:create
    [2] org.freedesktop.impl.portal.PermissionStore, org.gnome.Software

        ID                                    Branch      Op Remote  Download
 1.     org.freedesktop.Platform.GL.default   25.08       i  flathub < 148.0 MB
 2.     org.freedesktop.Platform.GL.default   25.08-extra i  flathub < 148.1 MB
 3.     org.freedesktop.Platform.codecs-extra 25.08-extra i  flathub  < 14.6 MB
 4.     org.gnome.Platform.Locale             50          i  flathub < 386.4 MB
 5.     org.gnome.Platform                    50          i  flathub < 419.7 MB
 6.     com.github.tchx84.Flatseal            stable      i  flathub < 930.5 kB

Proceed with these changes to the system installation? [Y/n]: y
```

GL ドライバ（`GL.default`）とコーデック（`codecs-extra`）の拡張も一緒に入る。入れ終わった時点で `/var/lib/flatpak` は 2.5 GB になった。

確認用に別のアプリを入れてもよい（この手順・手順 7・[ロールバック](../extra/almalinux-setup.md#flatpakrpm-fusionepel-を消す)の手順 1 の ID を置き換える）が、Flatseal より大きいアプリは runtime と合わせて数百 MB を落とす（[注意点](../extra/almalinux-setup.md#注意点)）。

同じ runtime を使うアプリを 2 本目以降に入れるときは、runtime の取得は起きない。[ツール一覧](../tool-catalog.md#gui)の Flathub の行には、アプリごとの runtime（GNOME 50 / FDO 25.08 / FDO 26.08）を書いてある。

#### Flatpak: 実施手順 / 手順 7: 補足: メニューに出るまで

`flatpak` パッケージは `/etc/profile.d/flatpak.sh` を置き、ログインシェルの `XDG_DATA_DIRS` に `/var/lib/flatpak/exports/share` と `~/.local/share/flatpak/exports/share` を足す。

- デスクトップはこの変数からアプリの `.desktop` を探すので、**flatpak を入れる前から続いているセッションには、この 2 つが入っていない**
- flatpak を新しく入れたときは、1 度ログアウトしてログインし直す

ログインシェルで足されることは次で確かめられる。

```bash
bash -lc 'echo "$XDG_DATA_DIRS"'
```

コンテナでの実測は `/home/<USER>/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share`。コンテナに画面は無かった。2026-10-06 の Workstation VM では flatpak が既にあり、追加した Flatseal は同じセッションの Activities 検索に出た。

`--command=true` は、アプリの中身の代わりに `true` をサンドボックスの中で実行する。**画面を出さずにサンドボックス（bubblewrap）が立ち上がるかだけを確かめる**ためで、アプリそのものの動作確認ではない。

#### Flatpak: ロールバック / 手順 1: 本文中の記録

   - コンテナでの実測では、Flatseal 1 つが消えた

#### Flatpak: ロールバック / 手順 2: 本文中の記録

   - コンテナでの実測では、runtime と拡張の 5 つ（`GL.default` の 2 つ・`org.gnome.Platform`・その `Locale`・`codecs-extra`）が消えた

#### Flatpak: 対象と検証環境

- **目的**: GUI アプリの主な配布元である [Flathub](https://flathub.org/) を AlmaLinux 10 で使えるようにする。[ツール一覧](../tool-catalog.md#gui)で「Flathub」を推奨にしたアプリの前提になる（CLI にとっての [Homebrew](../almalinux-setup.md) と同じ位置づけ）
- **進め方**: AppStream の `flatpak` に Flathub をシステム全体で登録し、小さいアプリを 1 つ入れて確かめる。**読者が書き換える変数は無い**
- **状態**: **コンテナ（2026-09-24）と x86_64 の VM（2026-10-06）で検証済み。実機には入れていない**
  - 2026-10-06: 別の新規 VM で現行手順を再検証した。今回の実施・解除・未実施範囲は[新しい付録](#flatpak-付録-現行版の新規-vm-での再検証2026-10-06)に記録した
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**手順 1〜7・[更新](../almalinux-setup.md#更新)・[ロールバック](../extra/almalinux-setup.md#ロールバック)を通した
  - 確認の問い合わせ（手順 6 とロールバックの `[Y/n]`）には、端末（pty）越しに `y` を送って答えた。コマンドに `-y` は足していない
  - 確認したこと: Flathub の追加、鍵の fingerprint、Flatseal の導入、サンドボックスの起動（`--command=true`）、`.desktop` の書き出し、ロールバックで元に戻ること
  - **確認していないこと**: デスクトップのメニューへの表示、アプリの画面、GNOME Software での表示。コンテナに画面が無いため
  - 検証は x86_64 だけで、aarch64 では通していない（aarch64 向けに出ているアプリは[ツール一覧](../tool-catalog.md#aarch64-で使えないもの)を参照）
  - **これまでの手順書のコンテナ検証（実機の上の podman）と違い、x86_64 のクラウドホスト上の Docker で行った**
  - 2026-09-28: [ロールバック](../extra/almalinux-setup.md#flatpakrpm-fusionepel-を消す)の手順 4のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-02: もとの手順 5・6 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）

| 項目 | 実機（Raspberry Pi 5） | 実機（x86_64 PC） | 検証コンテナ |
|---|---|---|---|
| 実施日 | —（未実施） | —（未実施） | 2026-09-24 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64 | AlmaLinux 10.2 (Lavender Lion) / x86_64 | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1、`--privileged`） |
| flatpak | `flatpak-1.16.0` 導入済み、リモート無し（[firefox.md](../almalinux-setup.md#firefox) の 2026-09-22 の記録） | 導入済み、flathub あり（[wezterm-nightly.md](../almalinux-setup.md#wezterm) の 2026-09-21 の記録） | 未導入 → `flatpak-1.16.0-9.el10_2.1` |
| 確認用アプリ | — | — | Flatseal 2.4.1（GNOME 50 の runtime） |

- 実機の 2 列は**この手順を適用した結果ではなく、ほかの手順書が記録した時点の状態**
- Raspberry Pi 5 はその後 2026-09-24 にクリーンインストールしている（[syncthing.md](../syncthing.md)）ので、今の状態は確かめていない

> [!NOTE]
> 出力例の値は `<USER>` のプレースホルダで書いてある。バージョン（`1.16.0` / `2.4.1`）と容量は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### Flatpak: 実施前の状態

検証コンテナ（AlmaLinux 10 の素のイメージ）の状態:

| 項目 | 状態 |
|---|---|
| flatpak | 未導入（`rpm -q flatpak` → `package flatpak is not installed`） |
| gnupg2 | 未導入（`flatpak` の依存として入る） |
| `/etc/flatpak` / `/var/lib/flatpak` | 無し |

#### Flatpak: 完了時点の状態

**検証コンテナでの出力**（手順 7 の直後。ロールバック前）:

```
$ flatpak list --app --columns=application,version,branch,installation
Application ID                    Version        Branch       Installation
com.github.tchx84.Flatseal        2.4.1          stable       system
$ flatpak info com.github.tchx84.Flatseal

Flatseal - Manage Flatpak permissions

          ID: com.github.tchx84.Flatseal
         Ref: app/com.github.tchx84.Flatseal/x86_64/stable
        Arch: x86_64
      Branch: stable
     Version: 2.4.1
     License: GPL-3.0-or-later
      Origin: flathub
  Collection: org.flathub.Stable
Installation: system
   Installed: 1.4 MB
     Runtime: org.gnome.Platform/x86_64/50
         Sdk: org.gnome.Sdk/x86_64/50

      Commit: ef9fe38e9cb96c170ea579fe1bbf8c76011255d4962d7fc4b3aa4e0a6063f8ae
      Parent: 14ba14f237835365b3b5f2c8f6eee2dcaf7f248d92f3eaf51e00ab28cfe523b1
     Subject: Update to v2.4.1 (9c3eef527c28)
        Date: 2026-05-20 18:12:58 +0000
$ ls /var/lib/flatpak/exports/share/applications/
com.github.tchx84.Flatseal.desktop
```

この状態で `/var/lib/flatpak` は 2.5 GB だった（`sudo du -sh` で計測。ロールバックの後、同じコンテナで Flathub を登録し直して Flatseal だけを入れ直した時点の値）。

#### Flatpak: 操作上の注意と併記されていた記録

- **権限はアプリごとに違う**: 手順 6 の実測のように、入れる前に権限の一覧が出る

#### Flatpak: 操作上の注意と併記されていた記録

- **公開元が検証済みかを見る**: Flathub のアプリには次の 2 種類がある。[ツール一覧](../tool-catalog.md#gui)の表に書き分けてある

#### Flatpak: 操作上の注意と併記されていた記録

  - 検証済み: 公開元がアプリの作者本人だと確認されたもの

#### Flatpak: 参照

- [Flathub — Setup](https://flathub.org/setup) — ディストリごとの Flathub の登録手順
- [Flatpak documentation — Using Flatpak](https://docs.flatpak.org/en/latest/using-flatpak.html) — `install` / `update` / `uninstall` / `remote-add` などの基本操作と、system と user のインストール先
- [Flathub — Verified apps](https://docs.flathub.org/docs/for-users/verification) — 検証済みの公開元の意味
- `man flatpak` / `man flatpak-remote-add` / `man flatpak-install` — サブコマンドとオプション
- [ツール一覧](../tool-catalog.md) — Flathub で入れる GUI アプリと、RPM との比較

#### Flatpak: 付録: コンテナでの検証記録（2026-09-24）

`quay.io/almalinuxorg/almalinux:10` を `docker run --privileged` で立てた使い捨てコンテナに非 root ユーザーを作り、`docker exec` で手順 1〜7・[更新](../almalinux-setup.md#更新)・[ロールバック](../extra/almalinux-setup.md#ロールバック)を通した。実機で加えた変更は無い。実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）。確認の問い合わせに答えるため、全体を `script` で作った pty の中で流し、15 秒おきに `y` を送った。`--privileged` を付けたのは、サンドボックス（bubblewrap）がコンテナの中で名前空間を作れるようにするため。同じホストの非特権コンテナでは、試したアプリが `CanCreateUserNamespace() clone() failure: EPERM` を出して名前空間を作れなかった。flatpak を非特権のコンテナで試してはいない。

| 手順 | 結果 |
|---|---|
| 変数（当時の手順 1。今は無い） | 2 つとも既定の値が表示された |
| 1〜3. flatpak | `flatpak は未導入` → `dnf install -y flatpak` で 138 パッケージ → `Flatpak 1.16.0`。直後の `flatpak remotes --show-details` は `error: While opening repository /var/lib/flatpak/repo: ...` |
| 4. 鍵 | `gpg: directory '/home/<USER>/.gnupg' created` の後に `6E5C 05D9 79C7 6DAF 93C0  8135 4184 DD4D 907A 7CAE`（`Flathub Repo Signing Key <flathub@flathub.org>`、`expires: 2027-06-14`） |
| 5. Flathub | `remote-add` は無出力。`flatpak remotes --show-details` に `flathub` の行（`Options` が `system`） |
| 6. 確認用アプリ | runtime の確認と最終確認の 2 回に `y`。GL ドライバ 2・コーデック 1・GNOME 50 の runtime と翻訳・Flatseal の 6 つが入った |
| 7. 検証 | `flatpak list` に Flatseal 2.4.1（system）、`flatpak info` の `Origin: flathub`、`sandbox OK`、`com.github.tchx84.Flatseal.desktop`。ログインシェルの `XDG_DATA_DIRS` に 2 つの `exports/share` が入った |
| 更新 | `Looking for updates…` → `Nothing to do.` |
| ロールバック | `uninstall` で Flatseal、`--unused` で 5 つが消えた。`flatpak list --app` と、`remote-delete` 後の `flatpak remotes --show-details` はどちらも無出力 |

最初の試行では、pty を使わずに標準入力から `y` を流した。**このときは flatpak が問い合わせに自動で `n` と答えて中断した**（`Do you want to install it? [Y/n]: n`）。スクリプトから流すなら `-y` を付けるか、pty を用意する必要がある。

同じ日に、別の手順（`-y --noninteractive` 付き）で [ツール一覧](../tool-catalog.md#gui) の Flathub のアプリを含む 13 本を同じコンテナに入れた。記録は一覧の付録にある。[使い方の基本](../almalinux-setup.md#flatpak-の使い方の基本)の表のうち、`search`（と、その前に要る `update --appstream`）・`info --show-permissions`・`override --filesystem` / `--reset` はその状態で確かめた。`search` が登録直後に何も返さないことは、別の新しいコンテナで `dnf install` → `remote-add` → `search` の順に流して再現した。

##### Flatpak: 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での本実行
- aarch64 での導入（Flathub 自体は aarch64 のアプリを配っている）
- デスクトップのメニューへの表示と、ログインし直す必要があるか
- アプリの画面の表示（Wayland / XWayland、GPU の利用）
- GNOME Software での Flathub のアプリの表示と、そこからの導入・更新
- `sudo` を付けない操作での polkit の問い合わせ
- `--user` でのインストール
- RPM 版と Flatpak 版を両方入れた場合のメニュー表示
- Raspberry Pi 5 のカーネルのページサイズ（`getconf PAGESIZE`）と、Flatpak のアプリの動作への影響

#### Flatpak: 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を ISO から新規に入れた VirtualBox の VM（x86_64、1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で、検証用ユーザーの SSH PTY に現行のブロックを個別に貼った。利用者のアカウントは使っていない。

実施手順 1・3〜7、更新、ロールバック 1〜4 を本実行した。`flatpak-1.16.0-9.el10` は Workstation に既にあったため手順 2 は省略した。Flathub の署名鍵を照合し、system に Flatseal 2.4.1 と GNOME 50 の runtime・拡張の計 6 ref を入れた。`sandbox OK` と desktop エントリを確認し、ヘッドレス GNOME の実画面で Flatseal が日本語で開き、Activities の検索にも出た。このセッションは flatpak が既に入っている状態から開始したため、アプリを入れた後のログインし直しは不要だった。

`sudo flatpak update` は `Nothing to do.`。`update --appstream` 後の CLI の検索は Flatseal を返した。一方、GNOME Software 47.5 の検索は、起動し直した後も `No App Found` だった（Flatpak のプラグインは同梱）。GNOME Software で表示・導入・更新が通るとはしない。ロールバックでは Flatseal 1 ref → 使われなくなった runtime と拡張の 5 ref → flathub の登録の順に消え、アプリ一覧とリモート一覧は空になった。RPM の flatpak 本体は残した。実機、aarch64、`--user`、キーリング、GPU は今回も確認していない。

---

#### Flatpak: 付録: 現行版の新規 VM での再検証（2026-10-06）

**環境と流し方**: `5da3478` の現行手順を、別のクリーンな AlmaLinux 10.2 Workstation / x86_64 の VM（1 vCPU、SELinux Enforcing、firewalld 稼働、US 配列）で実行した。SSH の一般ユーザーの対話 PTY に折り畳みの外のブロックを手順ごとに貼り、応答とプロンプトを待った。GUI は GNOME 49.4 のヘッドレスセッションに仮想モニターを付け、操作後の PNG を目視した。既存の実機・資格情報は使っていない。

実施手順 1・3〜6 を本実行した。Flatpak `1.16.0` は OS に既存だったため導入分岐 2 は不要だった。署名鍵の指紋と有効期限を確認し、system の Flathub を追加した。Flatseal `2.4.1` と GNOME 50 の runtime / 拡張を導入し、実際の GUI で権限の画面を確認した。更新は変更なしで成功した。手順 7 の `--command=true` による独立した sandbox 確認は今回実行せず、実アプリの GUI 起動を確認した。

ロールバック 1〜4 を実行した。Flatseal と 5 つの未使用 runtime / 拡張を削除し、アプリ一覧が空になった後、Flathub を削除して remote 一覧も空になった。今回のアプリ起動は desktop ID を使ったため、Activities のメニュー掲載と GNOME Software の検索は今回の確定結果に含めていない。aarch64 と物理実機は未実施。

#### Flatpak: 操作上の注意と併記されていた記録

- Flathub を登録しただけの状態では、`flatpak search flatseal` が `No matches found` を返した（`/var/lib/flatpak/appstream/` がまだ無い）

#### Flatpak: 実施手順 / 手順 5: 補足: system に入れる理由と、出力例

**system に入れる理由**: `sudo` を付けて**システム全体のインストール先**（`/var/lib/flatpak`）に登録している。以後のアプリも同じ場所に入り、ホストの全ユーザーから使える。

自分のユーザーだけに入れたいなら、`sudo` を外して `--user` を付ける（`flatpak remote-add --user --if-not-exists flathub ...`）。

- この場合の置き場所は `~/.local/share/flatpak` で、以降の `install` / `update` / `uninstall` にも `--user` を付ける
- **system と user に同じアプリを入れると、どちらが起動されるか分かりにくくなる**ので、どちらかに揃える
- 本書は system だけを検証している

**出力例**

```
Name    Title   URL                          Collection ID Subset Filter Priority Options … … Homepage             Icon
flathub Flathub https://dl.flathub.org/repo/ -             -      -      1        system  … … https://flathub.org/ https://dl.flathub.org/repo/logo.svg
```

#### Flatpak: 選択した方針

| 選択肢 | 採否 |
|---|---|
| **system に入れる（`sudo flatpak ...`）** | **採用。** ホストの全ユーザーで共有できる。dnf と同じく `sudo` で操作する |
| user に入れる（`--user`） | 不採用。自分のユーザーだけで閉じるが、以降のすべてのコマンドに `--user` を付ける必要がある（手順 5 の補足） |
| `sudo` を付けずに system に入れる | 不採用。flatpak は polkit で認証を求めるが、端末からの操作は `sudo` に揃えた。polkit の問い合わせ（デスクトップのダイアログや端末のパスワード入力）は確かめていない |

### Flatpak: 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

#### Flatpak: 使い方の基本

検索の挙動（どちらもコンテナで確認）:

- `sudo flatpak update --appstream` の後は、`Flatseal  Manage Flatpak permissions  com.github.tchx84.Flatseal  2.4.1  stable  flathub` が出た

#### Flatpak: 補足

- **容量が大きい**: アプリ 1 つ（1 MB 弱）でも、初回は runtime・翻訳・GL ドライバ・コーデックの拡張で 2.5 GB になる

  - [ツール一覧](../tool-catalog.md#gui)の Flathub のアプリを全部入れると、runtime は GNOME 50・FDO 25.08・FDO 26.08 の 3 系統になる

  - 調査時は、ほかのアプリも合わせた 13 本で 8.1 GB になった

- **RPM と Flatpak で同じアプリを二重に入れない**: [Firefox](../almalinux-setup.md#firefox) のように RPM で入れたものを Flathub からも入れると、メニューに同じ名前が 2 つ並ぶと見込まれる（未確認。[firefox.md](../almalinux-setup.md#firefox) の未確認事項と同じ）

---

## 統合前の記録: 日本語入力（もとは japanese-input.md）

もとの `japanese-input.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1（変数） | 「システムの設定」の手順 1 |
| 実施手順 2・3 | 「日本語入力」の手順 1 |
| 実施手順 4 | 「日本語入力」の手順 2 |
| 実施手順 5（ログインし直す） | 「再起動と確認」の手順 1（再起動） |
| 実施手順 6 | 「再起動と確認」の手順 3 |
| 実施手順 7 | 「再起動と確認」の手順 6 |
| ロールバック 1・2 | ロールバックの「表示と入力を戻す」の手順 13・14 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### 日本語入力: 補足

#### 日本語入力: 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 のコンテナと VM で検証した手順書**で、実機では本実行していない。クリーンインストールの VM では、入力ソースの切り替え・上部バーの表示・WezTerm での「日本語」の確定を画面で確かめた。自動キー入力の経路による違いは[VM の検証記録](#日本語入力-付録-クリーンインストールした-vm-での検証2026-10-06)にある。

#### 日本語入力: 実施手順 / 手順 1: 補足: 配列の取り出し方

`localectl status` の `X11 Layout:` の行から、英字で始まる最初の配列の名前だけを取る。コンテナ（systemd を PID 1 にしたもの）での実測:

| `localectl status` の表示 | `XKB_LAYOUT` |
|---|---|
| `X11 Layout: (unset)` | 空 |
| `X11 Layout: jp` | `jp` |
| `X11 Layout: us,jp` | `us`（最初の 1 つ） |
| `X11 Layout: jp` と `X11 Variant: OADG109A` | `jp`（変種は取らない） |

- `localectl` が動かないとき（systemd の無い環境）は、エラーを捨てて空になる
- 変種も指定するときは、手順 1 の読み戻しの後に `XKB_LAYOUT=jp+OADG109A` のように `+` でつないだ名前を設定する（GNOME の配列の一覧で、この形の名前があることをコンテナで確かめた）

#### 日本語入力: 実施手順 / 手順 2: 補足: インストールの種類による違い

AlmaLinux 10 のパッケージのグループ（`dnf group info` とリポジトリのメタデータで確かめた）:

- **Workstation** は `workstation-product` グループで `ibus-anthy` を入れる
- **Server with GUI** は `ibus-anthy` を入れない。`ibus` 本体は GNOME の依存で入る（コンテナで、`gdm` と `gnome-control-center` を入れただけで `ibus-1.5.32-1.el10` が入った）
- 日本語のフォント `default-fonts-cjk-sans`（中身は `google-noto-sans-cjk-vf-fonts`）は、どちらも「Fonts」グループの既定のパッケージとして入る
- GNOME をパッケージを選んで入れた場合は、フォントが無いことがある（コンテナがこの状態だった）

#### 日本語入力: 実施手順 / 手順 3: 補足: 入るパッケージ

コンテナ（ibus-anthy もフォントも無い状態）での実測。8 パッケージ、ダウンロード 35 MB、導入後 96 MB:

```
Installing:
 default-fonts-cjk-sans           noarch 4.1-3.el10             appstream  13 k
 ibus-anthy                       x86_64 1.5.17-1.el10          appstream 876 k
Installing dependencies:
 anthy-unicode                    x86_64 1.0.0.20240502-12.el10 appstream 5.7 M
 google-noto-sans-cjk-vf-fonts    noarch 1:2.004-9.el10         appstream  14 M
 ibus-anthy-python                noarch 1.5.17-1.el10          appstream 179 k
 kasumi-common                    noarch 2.5-47.el10            appstream  14 k
 kasumi-unicode                   x86_64 2.5-47.el10            appstream  71 k
Installing weak dependencies:
 google-noto-sans-mono-cjk-vf-fonts
                                  noarch 1:2.004-9.el10         appstream  14 M
```

- フォントが入っている PC では、ibus-anthy と依存を合わせた 5 パッケージ（ダウンロード 6.8 MB、導入後 35 MB）だけになる（フォントを先に入れたコンテナで確認）
- 導入後の `fc-list :lang=ja family` は `Noto Sans CJK JP` と `Noto Sans Mono CJK JP` だった
- `langpacks-ja` は入れない。中身は日本語のフォントの詰め合わせで、入力のエンジンは入らない（リポジトリのメタデータで確認）

#### 日本語入力: 実施手順 / 手順 4: 補足: 並べ方

キーボードの配列を先に、Anthy を後に置く。RHEL を日本語で入れたときも、GNOME は配列と Anthy の 2 つを入力ソースにする（ibus-anthy の RHEL のパッチの説明文から）。

- 設定アプリの「キーボード」→「入力ソース」と同じキー
- Anthy のエンジンは配列を `default`（入力ソースで選ばれている配列に従う）で登録している（`/usr/share/ibus-anthy/engine/default.xml`）。JIS 配列でも US 配列でも同じ `anthy` でよい
- 配列の短い表示名は `jp` が `ja`、Anthy は `あ`（エンジンの定義の `symbol`）。VM の US 配列では、上部バーが `en` と `あ` に切り替わることを画面で確かめた（JIS 配列の画面は未確認）

#### 日本語入力: ロールバック / 手順 0: 本文中の記録

- ロールバックも、コンテナでのみ本実行した

#### 日本語入力: 対象と検証環境

- **目的**: AlmaLinux 10 の GNOME で、日本語を入力できるようにする。入力のエンジンは、RHEL 10 の文書が日本語用に挙げている Anthy（IBus）を使う
- **進め方**: AppStream の `ibus-anthy` を入れ、`gsettings` で入力ソースを「キーボードの配列 + Anthy」にして、Super+Space で切り替える。**読者が書き換える必要のある変数は無い**
- **状態**: **x86_64 のコンテナとクリーンインストールの VM で検証済み。実機では本実行していない**（コンテナ 2026-09-27、VM 2026-10-06。VM は手順 1・2・4・6・7 とロールバックの手順 1。導入済みだったので手順 3・5 は省略）
  - 2026-10-06: 別の新規 VM で現行手順を再検証した。今回の実施・解除・未実施範囲は[新しい付録](#日本語入力-付録-現行版の新規-vm-での再検証2026-10-06)に記録した
  - GNOME の一式を入れたコンテナで、`dbus-run-session` のセッションバスの中に ibus-daemon を GNOME と同じ引数（`--panel disable`）で起動し、**この文書のコードブロックをそのまま貼って**手順 1〜4・6 と[ロールバック](../extra/almalinux-setup.md#ロールバック)を通した
  - 手順 1 の `localectl` は、systemd を PID 1 にした別のコンテナで確かめた（手順 1 の補足）
  - [flatpak.md](../almalinux-setup.md) と同じ、x86_64 のクラウドホスト上の Docker で行った
  - 確認したこと:
    - `dnf install` で入るもの
    - ibus-daemon を起動し直すと `ibus list-engine` に `anthy` が出る
    - 入力ソースが `[('xkb', 'jp'), ('ibus', 'anthy')]` になり、既定値に戻せる
    - IBus の API で `nihongo` と Space と Return を送ると「日本語」が確定し、半角/全角キーで直接入力とひらがなが切り替わる（手順 7 の補足）
  - **確認していないこと**: 候補の一覧、物理キーボードからの入力、JIS 配列の画面、GTK・XWayland・VS Code での日本語入力。VM では Super+Space、上部バー、Ctrl+Space、WezTerm の入力を確認した
  - aarch64（Raspberry Pi 5）では通していない。パッケージは同じ版が aarch64 にもある（リポジトリのメタデータで確認）
  - 2026-10-05: 手順 4 とロールバックの `gsettings` を `/usr/bin/gsettings` に揃えた。変更後は構文の検査だけで、実機・コンテナでは流していない

| 項目 | 実機 | コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10.2`、Docker 29.3.1） |
| GNOME | 未確認 | `gdm-47.0-24.el10_2`、`gnome-shell-49.4-9.el10_2.alma.1`、`gsettings-desktop-schemas-47.1-4.el10`（`gdm` と `gnome-control-center` を入れて依存で揃えた） |
| IBus / Anthy | 未確認 | `ibus-1.5.32-1.el10`（GNOME の依存で入っていた）、`ibus-anthy-1.5.17-1.el10`、`anthy-unicode-1.0.0.20240502-12.el10` |
| セッションバス | — | `dbus-run-session`（GNOME のセッションの代わり） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../almalinux-setup.md#システムの設定) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${XKB_LAYOUT}` | キーボードの配列（`localectl status` から自動で入る） | `jp`（JIS 配列）/ `us`（US 配列） |
>
> 出力例の値は `<USER>` のプレースホルダで書いてある。ロールバックの `<控えた値>` は、手順 4 で控えた値に置き換える。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### 日本語入力: 実施前の状態

コンテナで、手順 1 の前に確かめた状態:

| 項目 | 状態 |
|---|---|
| `ibus` | `ibus-1.5.32-1.el10`（GNOME の依存で入っていた） |
| `ibus-anthy` | 未導入 |
| 日本語のフォント | 無い（`default-fonts-cjk-sans` は未導入で、`fc-list :lang=ja` は何も出さない） |
| 入力ソース | `@a(ss) []`（既定値） |
| 切り替えのキー | `['<Super>space', 'XF86Keyboard']` |

#### 日本語入力: 選択した方針

| 経路 | 状況（2026-09-27 時点） | 採否 |
|---|---|---|
| **IBus + Anthy**（AppStream の `ibus-anthy`） | RHEL 10 の文書が日本語用に挙げているエンジン。GNOME は IBus を組み込んでいて、入力ソースに足すだけで使える。x86_64・aarch64 の両方にある | **採用** |
| IBus + Mozc | Mozc の RPM が EL10 に無い（EPEL 10 にも、COPR の EL10 向けにも無い） | — |
| Fcitx5 + Mozc（Flathub の `org.fcitx.Fcitx5` と `org.fcitx.Fcitx5.Addon.Mozc`） | 変換は Mozc のほうが賢いが、GNOME（Wayland）には IBus の代わりに組み込む作業が要る。Mozc のアドオンは公開元が未検証 | 不採用 |
| Anthy だけを入力ソースにして、半角/全角キーでオンとオフを切り替える | Windows に近い使い方。ログイン直後からひらがなで始まる | 不採用（GNOME の標準の、配列と Anthy を Super+Space で切り替える形にした） |

#### 日本語入力: 完了時点の状態

コンテナでの出力（手順 6 の直後）:

```
$ gsettings get org.gnome.desktop.input-sources sources
[('xkb', 'jp'), ('ibus', 'anthy')]
$ ibus list-engine | grep -w anthy
  anthy - Anthy
$ rpm -q ibus ibus-anthy default-fonts-cjk-sans
ibus-1.5.32-1.el10.x86_64
ibus-anthy-1.5.17-1.el10.x86_64
default-fonts-cjk-sans-4.1-3.el10.noarch
```

#### 日本語入力: 付録: コンテナでの検証記録（2026-09-27）

x86_64 のクラウドホスト上の Docker で、使い捨てのコンテナを使った。実機で加えた変更は無い。

- `quay.io/almalinuxorg/almalinux:10.2` に `sudo`・`gdm`・`gnome-control-center` を `dnf install` で入れ、GNOME の一式を依存で揃えた（488 パッケージ）
- 非 root ユーザーを作り、NOPASSWD の sudo を与えた

実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、次の点だけ置き換えている。

- GNOME のセッションの代わりに、`dbus-run-session -- bash` の中で実行し、ibus-daemon を GNOME のユニットと同じ `ibus-daemon --panel disable` で起動した
- コンテナに `/etc/machine-id` が無く、IBus がつながらなかったので、`systemd-machine-id-setup` で作った
- 手順 1 の `localectl` はこのコンテナでは動かず `XKB_LAYOUT` が空になったので、手順 1 の案内のとおり `XKB_LAYOUT=jp` を貼った
- `dnf install` と `dnf remove` に `-y` を付けた
- 手順 5 のログインし直しの代わりに、ibus-daemon を止めて起動し直した

| 手順 | 結果 |
|---|---|
| 1. 変数 | `USER = <USER>`、`XKB_LAYOUT` は空。`XKB_LAYOUT=jp` を貼った |
| 2. 確認 | `ibus-1.5.32-1.el10` と、`ibus-anthy` / `default-fonts-cjk-sans` の `is not installed`、`未導入のものがある` |
| 3. 導入 | 8 パッケージ（手順 3 の補足）。直後の `ibus list-engine` に `anthy` は出なかった |
| 4. 入力ソース | `@a(ss) []` → `[('xkb', 'jp'), ('ibus', 'anthy')]`、切り替えのキーは `['<Super>space', 'XF86Keyboard']` |
| 6. 確認 | ibus-daemon を起動し直した後、`anthy - Anthy`。IBus の API での入力は手順 7 の補足のとおり |
| ロールバック 1 | `@a(ss) []` |
| ロールバック 2 | `ibus-anthy` と依存の 4 パッケージが消えた。`ibus` とフォントは残った |
| 比較. フォントが入っている PC | `default-fonts-cjk-sans` を先に入れた別のコンテナで手順 2・3: 手順 2 は `ibus-anthy` だけが `is not installed`。手順 3 は `Package default-fonts-cjk-sans-4.1-3.el10.noarch is already installed.` と出て、5 パッケージが入った |

##### 日本語入力: 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- Super+Space での切り替えと、上部バーの表示
- 候補の一覧の表示と、変換の操作（候補の選び直し、文節の区切り直し）
- アプリでの入力（GNOME のテキストエディタ・端末、Firefox、VS Code、WezTerm）
- `ibus restart` で、ログインし直さずに Anthy が使えるようになるか
- `ibus-setup-anthy` と `kasumi-unicode` の画面

#### 日本語入力: 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を新規に入れた x86_64 の VirtualBox VM（1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で確認した。シェルのブロックは手順書から抜き出して、検証用ユーザーの SSH の対話シェルへ個別に貼った。GUI はヘッドレスの GNOME に 1920x1080 の仮想モニターを付け、既存の `scripts/gnome-gui.py` を変更せずコピーして、操作の後に撮った PNG を見た。利用者のアカウントは使っていない。

Workstation には `ibus-1.5.32-1.el10`・`ibus-anthy-1.5.17-1.el10`・`default-fonts-cjk-sans-4.1-3.el10` が入っていたので、手順 3・5 は省略した。手順 1・2・4、デスクトップの Ptyxis 端末での手順 6、手順 7 とロールバック 1 → 再設定を確認した。入力ソースは `[('xkb', 'us'), ('ibus', 'anthy')]`、Super+Space で上部バーが `en` と `あ` に切り替わり、Ctrl+Space で Anthy の直接入力（`_A`）とひらがな（`あ`）を切り替えられた。

`gnome-gui.py` の `NotifyKeyboardKeysym` では、英字の直接入力は届いたが、Anthy のひらがなモードでは `nihongo` が本文に入らなかった。入力間隔を 0.3 秒、前後を 1 秒に広げた検証用プローブでも同じだった。原本を変更せず読み込む別のプローブで、Mutter の `NotifyKeyboardKeycode` に evdev の `n i h o n g o Space Enter` を送ると、WezTerm の実ウィンドウに「日本語」が確定した。設定と変換の成立は VM で確認できたが、既存スクリプトの keysym 経路で日本語を打てるとはしない。物理キーボード・JIS 配列・候補一覧・GTK と VS Code の日本語入力は未確認。

---

#### 日本語入力: 付録: 現行版の新規 VM での再検証（2026-10-06）

**環境と流し方**: `5da3478` の現行手順を、別のクリーンな AlmaLinux 10.2 Workstation / x86_64 の VM（1 vCPU、SELinux Enforcing、firewalld 稼働、US 配列）で実行した。SSH の一般ユーザーの対話 PTY に折り畳みの外のブロックを手順ごとに貼り、応答とプロンプトを待った。GUI は GNOME 49.4 のヘッドレスセッションに仮想モニターを付け、操作後の PNG を目視した。既存の実機・資格情報は使っていない。

実施手順 1・2・4・6・7 を確認した。IBus / Anthy は OS に既存だったため、追加導入の分岐は不要だった。入力ソースは US と Anthy、切替は Super+Space で、上部バーの `en` と `あ` を確認した。手順 6 は SSH ではセッションの IBus に届かなかったので、実際の WezTerm タブで実行し `anthy - Anthy` を確認した。

変更していない `gnome-gui.py` の keysym 経路では、Anthy に `nihongo` が揃って届かなかった。別の検証プローブで Mutter の `NotifyKeyboardKeycode` に evdev のキー押下・解放を送り、`nihongo Space Enter` で実際の WezTerm に「日本語」が確定し、保存したファイルにも同じ文字列が入った。入力経路の問題を設定の不具合とは扱っていない。LazyVim の Insert / Search の IBus 切替も別途実キー経路で確認した。

ロールバック 1 の入力ソース reset を実行し、`@a(ss) []` を読み戻した。既存の Anthy パッケージは削除していない。物理キーボード、JIS 配列、候補一覧の網羅、GTK / VS Code の日本語入力は今回実施していない。

#### 日本語入力: 実施手順 / 手順 7: 補足: コンテナでの確かめ方

画面が無いので、IBus の Python の API（`gi.repository.IBus`）で入力コンテキストを作り、GNOME Shell が入力ソースを切り替えるときと同じく全体のエンジンを `anthy` にして、キーを送った。

| 送ったキー | 結果 |
|---|---|
| `a` | 前編集の文字列が `あ`（ひらがなで始まる） |
| `n` `i` `h` `o` `n` `g` `o` | `にほんご` |
| Space | `日本語` |
| Return | `日本語` が確定した |
| 半角/全角 → `a` | Anthy が受け取らず、そのままアプリに渡る（直接入力） |
| もう一度 半角/全角 → `a` | `あ`（ひらがなに戻る） |

- ひらがなで始まるのは、RHEL の ibus-anthy のパッチで、入力モードの既定（`org.freedesktop.ibus.engine.anthy.common` の `input-mode`）が `0`（ひらがな）になっているため
- 直接入力とひらがなを切り替えるキーは、Anthy の設定（`org.freedesktop.ibus.engine.anthy.shortcut` の `on_off`）で `['Zenkaku_Hankaku', 'Ctrl+space', 'Ctrl+J']`

#### 日本語入力: 実施手順 / 手順 5: 補足: ログインし直す理由

動いている ibus-daemon は、起動した後に入れたエンジンを知らない。

- コンテナで、`dnf install` の直後の `ibus list-engine` には `anthy` が出ず、ibus-daemon を起動し直すと出た
- `ibus restart` でも起動し直せるはず。GNOME では、systemd のユーザーのユニット `org.freedesktop.IBus.session.GNOME.service` を再起動する作り（ibus 1.5.32 のソース）で、コンテナではこの経路を確かめられないので、本書はログインし直す形にした
- systemd のユーザーのインスタンスが無いコンテナでは、`ibus restart` は `error: XDG_RUNTIME_DIR is invalid or not set in the environment.` と出したうえで daemon を起動し直し、`anthy` が出るようになった

### 日本語入力: 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

#### 日本語入力: 補足

- **アプリによる違い**: GTK のアプリ・XWayland で動くアプリ・VS Code・WezTerm での入力は確かめていない

---

## 統合前の記録: 画面オフ・ロック・サスペンド（もとは gnome-power.md）

もとの `gnome-power.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜5 | 画面オフ・画面ロック・自動サスペンドを止める（任意）の 1〜5 |
| ロールバック 1〜4 | 同じ節の 6〜9 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### 画面オフ・ロック・サスペンド: 補足

#### 画面オフ・ロック・サスペンド: 操作上の注意と併記されていた記録

   - GNOME のメニュー・蓋・電源ボタンなど、どこから頼まれてもサスペンドが始まらなくなる（確かめたのは logind の答えだけ。この手順の補足）

#### 画面オフ・ロック・サスペンド: 実施手順: 検証状況の記録

> [!WARNING]
> **手順 1〜5 とロールバックは、x86_64 のコンテナとクリーンインストールの VM で本実行した**。手順 1・2 は aarch64 の実機（Raspberry Pi 5）でも本実行し、ヘッドレスの画面・ロックとサスペンド要求を 16 分余り観測した。物理モニター、サスペンドできる PC、ログイン画面・蓋・電源ボタンの実際の動きは未確認（[対象と検証環境](#画面オフロックサスペンド-対象と検証環境)）。

#### 画面オフ・ロック・サスペンド: 実施手順 / 手順 2: 補足: 変える前の値、0 にしても暗くなる理由、設定アプリの項目

**変える前の値**（コンテナの実測。`gnome-settings-daemon-server-defaults` が無い、Workstation と同じ条件）:

```
$ gsettings get org.gnome.desktop.session idle-delay
uint32 300
$ gsettings get org.gnome.desktop.screensaver lock-enabled
true
$ gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'idle-dim|sleep-inactive|power-button-action'
org.gnome.settings-daemon.plugins.power idle-dim true
org.gnome.settings-daemon.plugins.power power-button-action 'suspend'
org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 900
org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend'
org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 900
org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'
```

- 既定では、5 分で画面が消えてすぐロックし、電源につないでいても 15 分（900 秒）で眠る
- Server with GUI で入れた PC は、`gnome-settings-daemon-server-defaults` が `sleep-inactive-ac-timeout` を `0`（眠らない）にしている。電源ボタンは既定の `'suspend'` のまま（[注意点](../extra/almalinux-setup.md#注意点)）
- タイムアウトではなく方式（`sleep-inactive-*-type`）を `nothing` にするのは、設定アプリ（gnome-control-center 47.7）が「自動サスペンド」を切った状態をこの形で表すため（ソースの `cc-power-panel.c` から）

**`idle-dim` も切る理由**: gnome-settings-daemon 47.2 は、`idle-dim` が true のとき、`idle-delay` が 0 でも 60 秒の無操作で画面を暗くする（ソースの `IDLE_DIM_BLANK_DISABLED_MIN`）。

- 電源モードが省電力のときは、`idle-dim` にかかわらず 30 秒で暗くする（同じソースから。画面では確かめていない）

**設定アプリの項目**（EL10 の gnome-control-center 47.7 に入っている日本語の翻訳から）:

| キー | 設定アプリの項目 |
|---|---|
| `idle-delay` | 「電源」→「省電力」→「空白のスクリーン」、「プライバシーとセキュリティー」→「スクリーンロック」→「空白スクリーンの遅延」。0 は「なし」 |
| `idle-dim` | 「電源」→「省電力」→「スクリーンを暗くする」 |
| `sleep-inactive-ac-type` / `sleep-inactive-battery-type` | 「電源」→「省電力」→「自動サスペンド」の「プラグイン時」/「バッテリー動作時」 |
| `power-button-action` | 「電源」→「電源ボタンの挙動」（サスペンド / 電源オフ / ハイバネート / なにもしない。電源オフが `interactive`） |
| `lock-enabled` | 「プライバシーとセキュリティー」→「スクリーンロック」→「自動スクリーンロック」 |

- SSH のシェルから変えた値が、ログインし直さずヘッドレスのセッションに届くことは、2026-10-01 に時計の秒表示と放置時のサスペンド要求で確かめた（[付録](#画面オフロックサスペンド-付録-実機での検証記録2026-10-01)）。物理モニターの画面では未確認

**`gsettings` が書けなかったとき**: セッションバスに届かないシェルでは、警告を出して値を変えず、**終了コードは 0** になる。コンテナで、セッションバスを用意せずに実行したときの実測:

```
$ gsettings set org.gnome.desktop.session idle-delay 0; echo "rc=$?"

(process:2195): dconf-WARNING **: 08:33:08.265: failed to commit changes to dconf: Cannot spawn a message bus without a machine-id: Invalid machine ID in /var/lib/dbus/machine-id or /etc/machine-id
rc=0
$ gsettings get org.gnome.desktop.session idle-delay
uint32 300
```

- 警告の文面は環境で変わる。`failed to commit changes to dconf` が出たら、書けていない
- 範囲の外の値（`POWER_BUTTON=poweroff` など）は `The provided value is outside of the valid range` で失敗し、終了コードは 1 になる。値は変わらない

**Homebrew の `gsettings` のとき**: Homebrew の `gsettings` は、GNOME に効かないのに、読み戻しでは変わったように見える。

- Homebrew の glib は dconf のモジュールを持たないので、`gsettings` は dconf ではなく `~/.config/glib-2.0/settings/keyfile` に書き、同じファイルから読み戻す。警告は出ず、終了コードも 0
- Homebrew の formula の多く（cairo・ffmpeg・imagemagick など）が glib に依存するので、[homebrew.md](../almalinux-setup.md) を通したホストでは PATH の先頭の `gsettings` がこれになりやすい
- 2026-10-01 に Raspberry Pi 5 の実機で確かめた
  - `command -v gsettings` が `/home/linuxbrew/.linuxbrew/bin/gsettings`（glib 2.90.0）のホスト
  - `G_MESSAGES_DEBUG=all` を付けると `Found default implementation keyfile (GKeyfileSettingsBackend)` と出た
  - `gsettings get org.gnome.desktop.session idle-delay` が `uint32 300` を返し、`/usr/bin/gsettings` は dconf の `uint32 0` を返した
  - Homebrew の `gsettings set` で書いた値は、Homebrew の `gsettings get` では変わって見え、`/usr/bin/gsettings get` では変わっていなかった
- そのため、この手順と[ロールバック](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)の手順 1 は `/usr/bin/gsettings` で書いてある（2026-10-01 に直した。それまでのコンテナの検証は、Homebrew の無い環境で `gsettings` のまま流した）

#### 画面オフ・ロック・サスペンド: 実施手順 / 手順 3: 補足: ログイン画面の設定の置き場所と、gdm ユーザーで読む理由

**Workstation で入れた PC のログイン画面は、既定では 15 分で眠る。** GDM 47 は、ログイン画面の電源のキーを何も設定していない（上流の `data/dconf/defaults/00-upstream-settings`）。

- そのため gnome-settings-daemon の既定（電源につないでいても 900 秒でサスペンド）がそのまま効く
- Server with GUI で入れた PC は、手順 2 の補足の override がログイン画面にも効くので、電源につないでいる間は眠らない
- コンテナで、ログイン画面から見える値（この手順の `sudo -u gdm` の行と同じ読み方）がそうなっていることを確かめた。実機で眠るところは確かめていない
- 再起動した後や、GNOME Remote Desktop のリモートログインを待っている間は、ログイン画面のまま置かれる

**置き場所**: ログイン画面は `gdm` ユーザーで動き、dconf のプロファイル `/usr/share/dconf/profile/gdm` を読む。

```
user-db:user
system-db:gdm
system-db:local
system-db:site
system-db:distro
file-db:/usr/share/gdm/greeter-dconf-defaults
```

- RHEL の gdm は `system-db:gdm` などの行を足してある（CentOS Stream 10 の gdm のパッチ `0001-data-add-system-dconf-databases-to-gdm-profile.patch`）
- そのため `/etc/dconf/db/gdm.d/` に置いたファイルは、ログイン画面にだけ効く
- ファイル名の `90-` は、同じキーを書いたファイルが複数あると名前の順で後ろが勝つため、後ろに置いた（GDM の既定のファイルのコメントも、数字の大きい名前を勧めている）

**書かなかったキー**: 画面を消す（`idle-delay`）とロックのキーは書いていない。

- ログイン画面はもともとロックしない（GDM の既定で `disable-lock-screen=true`）
- 画面は 5 分で消える。消したくないなら、`[org/gnome/desktop/session]` の節に `idle-delay=uint32 0` を、電源の節に `idle-dim=false` を足す
- **`uint32` を付けずに `idle-delay=0` と書くと、エラーにならずに無視される**（コンテナで、ログイン画面から見える値が `uint32 300` のままだった）

**引用符を付けなかったとき**（コンテナの実測。`91-test` は確かめるために置いたファイル）:

```
$ sudo dconf update
/etc/dconf/db/gdm.d: 91-test: [org/gnome/settings-daemon/plugins/power]: sleep-inactive-ac-type: invalid value: nothing: 0-7:unable to infer type
error: failed to update at least one of the databases
```

- 終了コードは 1 で、`/etc/dconf/db/gdm` は作り直されず、前の内容のまま残った

**gdm ユーザーで読む理由**: `sudo -u gdm env DCONF_PROFILE=gdm` は、ログイン画面と同じユーザー・同じプロファイルで読む。

- 自分のユーザーのまま `DCONF_PROFILE=gdm` で読むと、プロファイルの先頭の `user-db:user` が自分の設定を指すので、手順 2 で変えた自分の値が見えてしまう
- コンテナで、自分の `power-button-action` を `'nothing'`、ログイン画面用のファイルを `'interactive'` にして比べると、自分で読むと `'nothing'`、`gdm` ユーザーで読むと `'interactive'` だった
- 読むと `/var/lib/gdm/.cache/dconf/user`（2 バイトの目印のファイル）が作られる。消さなくてよい
- 動いているログイン画面に、いつから効くかは確かめていない。次にログイン画面が出たとき（ログアウトか再起動の後）には読まれるはず

**`POWER_BUTTON` が空のときに `if` で止める理由**: ヒアドキュメントの中の `${POWER_BUTTON:?…}` は、空のときに `sudo tee` だけを失敗させ、`{ … }` で囲んでも後ろの行は動いた。

- 2026-10-02 に、スタブの `sudo` を置いた対話の bash（5.2、擬似端末、ブラケットペースト無し）に貼って確かめた
- `if` の形では、空のときは `中断:` だけが出て、`sudo` の行はどれも動かなかった

#### 画面オフ・ロック・サスペンド: 実施手順 / 手順 4: 補足: mask で止まるもの

`mask` は、unit のファイルを `/dev/null` へのシンボリックリンクで覆って、起動できなくする。

- logind は、mask された target を使うサスペンドを「できない」と答える
- コンテナで、logind の `CanSuspend` が mask の前の `"yes"` から、後で `"no"` に変わった
  - コンテナの `/sys/power` は、中身を偽物にした tmpfs に差し替えてある。本当には眠れない状態で確かめた（[付録](#画面オフロックサスペンド-付録-コンテナでの検証記録2026-09-27)）
- 設定アプリ（gnome-control-center 47.7）は、`CanSuspend` が `"yes"` のときだけ「自動サスペンド」の行と電源ボタンの「サスペンド」を出す
  - ハイバネートもできないときは、「電源ボタンの挙動」の行ごと出さない
  - どちらもソースから読んだもので、画面では確かめていない
- `suspend-then-hibernate.target` も systemd 257 にあるので、一緒に止める

#### 画面オフ・ロック・サスペンド: 実施手順 / 手順 5: 補足: mask とは別に蓋の設定を置く理由

手順 4 の後は、蓋を閉じても、logind は mask された target を使えないので眠らないはず（蓋のイベントは確かめていない）。それでも設定を置くのは、次の 2 つのため。

- 「蓋を閉じても何もしない」ことを設定として残す。手順 4 の mask を外したときも、蓋では眠らない
- 眠れないサスペンドを logind が試みることが無くなる

**既定の値**（コンテナの実測）:

- `HandleLidSwitchExternalPower`（電源につないでいるとき）は空で、`HandleLidSwitch` に従う
- `HandleLidSwitchDocked`（外部ディスプレイをつないでいるときなど）は `"ignore"`
- `/etc/systemd/logind.conf.d` は最初は無いので、`mkdir -p` で作る

**`systemctl reload systemd-logind` で読み直す**: systemd 257 の logind は `Type=notify-reload` で、reload すると設定ファイルを読み直す。

- journal に `Config file reloaded.` が出る

**電源ボタンの `HandlePowerKey` は変えない**: GNOME が動いている間（ログイン画面を含む）は、手順 2・3 の `power-button-action` が効く。

- `HandlePowerKey` は、GNOME が動いていないときの設定（RHEL 10 の文書の 13.1 節）

#### 画面オフ・ロック・サスペンド: ロールバック / 手順 0: 本文中の記録

- ロールバックも、コンテナとクリーンインストールの x86_64 VM で本実行した

#### 画面オフ・ロック・サスペンド: 対象と検証環境

- **目的**: 常時動かしておく PC で、GNOME が画面を消したり、ロックしたり、放置で眠ったりしないようにする。ログイン画面・蓋・OS のサスペンドも止める
  - [WireGuard](../wireguard.md)・[Samba](../samba.md)・[Syncthing](../syncthing.md)・[Dropbox](../dropbox.md)・[Dropbox（rclone）](../dropbox-rclone.md)・[GNOME Remote Desktop](../gnome-remote-desktop.md) のホストは、眠るとサービスが止まる
  - [GNOME のヘッドレスのセッション](../gnome-headless-session.md)は、手順 1・2（サスペンドできる PC では手順 3・4 も）を前提にしている。ヘッドレスのセッションでも gsd-power は、既定では 15 分の無操作でサスペンドしようとする
  - [Claude Code で GUI を確かめる](../claude-code-gui.md)は、手順 1・2 を前提にしている。ロックされると、画面の前にいない Claude Code には解けない
- **進め方**: 自分のセッションは `gsettings`、ログイン画面は dconf の `gdm.d`、OS 全体は `systemctl mask`、蓋は logind のドロップインで変える。**読者が書き換える必要のある変数は無い**
- **状態**: **x86_64 のコンテナ（2026-09-27）とクリーンインストールの VM（2026-10-06）で、手順 1〜5・ロールバックを本実行済み。手順 1・2 は aarch64 の実機（Raspberry Pi 5）でも本実行した（2026-10-01）**
  - 2026-10-06: 別の新規 VM で現行手順を再検証した。今回の実施・解除・未実施範囲は[新しい付録](#画面オフロックサスペンド-付録-現行版の新規-vm-での再検証2026-10-06)に記録した
  - 下表の 2 つのコンテナで、**この文書のコードブロックをそのまま貼って**、手順 1〜5 と[ロールバック](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)を通した
    - 手順 1〜3 とロールバックの 1・2: GNOME の一式を入れたコンテナで、`dbus-run-session` のセッションバスの中で実行
    - 手順 4・5 とロールバックの 3・4: systemd を PID 1 にしたコンテナで実行
  - [flatpak.md](../almalinux-setup.md) と同じ、x86_64 のクラウドホスト上の Docker で行った
  - 確認したこと:
    - `gsettings` で 6 つのキーが変わり、`reset` で既定値に戻る
    - ログイン画面から見える値（`gdm` ユーザーと `gdm` のプロファイルで読んだ値）が、`gdm.d` のファイルで変わり、消すと戻る
    - mask で、logind の `CanSuspend` が `"yes"` から `"no"` に変わる（本当には眠れないコンテナで）
    - logind の `HandleLidSwitch` が `"ignore"` になり、戻せる
  - **確認していないこと**: 物理モニターの画面が消えない・暗くならない・ロックしないこと、サスペンドできる PC が実際に眠らないこと、ログイン画面・蓋・電源ボタンの実際の動き、GNOME のメニューと設定アプリの表示
  - 2026-09-28: もとの手順 4〜6（今の手順 3 の `dconf update` から後と、手順 4・5）と、[ロールバック](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)のもとの手順 3〜5（今の手順 2 の `dconf update` から後と、手順 3・4）のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-01: 手順 2 と[ロールバック](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)の手順 1 の `gsettings` を `/usr/bin/gsettings` にした（Homebrew の `gsettings` は GNOME に効かないため。手順 2 の補足）
    - ロールバックの手順 1 の、`/usr/bin/gsettings` にした形は流していない
  - 2026-10-01: 手順 1・2 を aarch64 の実機（Raspberry Pi 5）で本実行した（[付録](#画面オフロックサスペンド-付録-実機での検証記録2026-10-01)）
    - GNOME のヘッドレスのセッションの手順書（今の [gnome-headless-session.md](../gnome-headless-session.md) と [claude-code-gui.md](../claude-code-gui.md) に分ける前の版）の前提として、SSH でログインしたシェルに貼った（ブラケットペーストの無しと有り）
    - 読み戻しは[完了時点の状態](#画面オフロックサスペンド-完了時点の状態)と同じ。SSH のシェルから変えた値は、動いているヘッドレスのセッションにすぐ効いた
    - 手順 2 の後は、ヘッドレスのセッションを 16 分余り放置しても、サスペンドしようとせず、画面は消えず、ロックもされなかった（`LockedHint=no`。[claude-code-gui.md の付録](claude-code-gui.md#付録-実機での検証記録2026-10-01)）。物理モニターでの観測ではない
    - 手順 3〜5 とロールバックは、実機では流していない
  - 2026-10-02: もとの手順 3・4 と、[ロールバック](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)のもとの手順 2・3 をつないだ（手順 3 は `if … fi`、ロールバックの手順 2 は `{ … }` で囲んだ）
    - 手順 3 は、スタブの `sudo` を置いた対話の bash に貼り、`POWER_BUTTON` が空なら何も動かず、値があればすべての行が動くことだけ確かめた（手順 3 の補足）
    - ロールバックの手順 2 は貼っていない。`bash -n` だけ
  - 2026-10-05: 手順 3 とロールバックの手順 2 も `/usr/bin/gsettings` に統一した。変更後は構文の検査だけで、本実行していない

| 項目 | 実機 | コンテナ（GNOME の一式） | コンテナ（systemd） |
|---|---|---|---|
| 実施日 | 2026-10-01（手順 1・2 だけ） | 2026-09-27 | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10.2`、Docker 29.3.1） | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2`） |
| GNOME | `gnome-shell-49.4-9.el10_2.alma.1`、`gnome-settings-daemon-47.2-10.el10_2.alma.1`、`glib2-2.80.4-12.el10_2.22`（ヘッドレスのセッション） | `gdm-47.0-24.el10_2`、`gnome-shell-49.4-9.el10_2.alma.1`、`gnome-settings-daemon-47.2-10.el10_2.alma.1`、`gsettings-desktop-schemas-47.1-4.el10`、`dconf-0.40.0-17.el10`（`gdm` と `gnome-control-center` を入れて依存で揃えた） | 無し |
| systemd | `systemd-257-23.el10_2.2.alma.1` | PID 1 ではない | `systemd-257-23.el10_2.2.alma.1`（`systemd-udev` も入れた） |
| セッションバス | ユーザーの systemd のセッションバス（SSH でログインしたシェルから） | `dbus-run-session`（GNOME のセッションの代わり） | — |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${IDLE_DELAY}` | 無操作で画面を消すまでの秒数（`0` は消さない） | `0`（既定）/ `300` |
> | `${LOCK_ENABLED}` | 画面が消えたときにロックするか | `false`（既定）/ `true` |
> | `${POWER_BUTTON}` | 電源ボタンを押したときの動作 | `interactive`（既定）/ `nothing` |
>
> 変数を使わない値（`nothing`、ファイル名の `90-power` / `90-lid.conf`）はコマンドに直接書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### 画面オフ・ロック・サスペンド: 実施前の状態

コンテナで、手順 1 の前に確かめた状態:

| 項目 | 状態 |
|---|---|
| 自分のセッション | `idle-delay` が `uint32 300`、`lock-enabled` が `true`、`idle-dim` が `true`、`sleep-inactive-ac-type` / `sleep-inactive-battery-type` が `'suspend'`（タイムアウトはどちらも 900 秒）、`power-button-action` が `'suspend'` |
| ログイン画面から見える値 | 自分のセッションと同じ |
| `/etc/dconf/db/gdm.d` | 空の `locks` ディレクトリだけ |
| `gnome-settings-daemon-server-defaults` | 未導入（Workstation と同じ） |
| sleep 系の target | 5 つとも `static` |
| logind | `HandleLidSwitch` が `"suspend"`、`HandlePowerKey` が `"poweroff"`。`/etc/systemd/logind.conf.d` は無い |

#### 画面オフ・ロック・サスペンド: 選択した方針

| 変えるもの | 方法 | 採否 |
|---|---|---|
| 自分のセッション | `gsettings`（自分の dconf の `~/.config/dconf/user` に書く） | **採用**。設定アプリと同じキーで、自分にだけ効く |
| 自分のセッション | dconf の `local.d` にファイルを置いて `dconf update`（RHEL 10 の文書が電源ボタンの例で使う方法） | 不採用。自分で変えた値（`gsettings` や設定アプリ）が優先されて効かないことがあるうえ、RHEL の gdm のプロファイルは `system-db:local` も読むので、ログイン画面にもかかる |
| ログイン画面 | dconf の `gdm.d` | **採用**。ログイン画面のプロファイルだけが読む |
| ログイン画面 | `gdm` ユーザーとして `gsettings set` し、`gdm` ユーザー自身の設定に書く | 不採用。値が `/var/lib/gdm` の中に隠れ、`/etc` を見ても分からない |
| OS 全体 | sleep 系の target を `systemctl mask` | **採用**。`systemctl is-enabled` で状態を確かめられ、`unmask` で戻せる |
| OS 全体 | `/etc/systemd/sleep.conf.d/` で `AllowSuspend=no` などにする | 試していない（mask で `CanSuspend` が `"no"` になることを確かめたので足りた） |
| 電源ボタン | logind の `HandlePowerKey` | 変えない。GNOME が動いている間は `power-button-action` が効く（手順 5 の補足） |
| 蓋 | logind の `HandleLidSwitch=ignore`（ドロップイン） | **採用**。RHEL 10 の文書は `/etc/systemd/logind.conf` を直接書き換えるが、ドロップインなら消すだけで戻せる |

#### 画面オフ・ロック・サスペンド: 完了時点の状態

**GNOME の一式のコンテナ**（手順 3 の直後）:

```
$ gsettings get org.gnome.desktop.session idle-delay
uint32 0
$ gsettings get org.gnome.desktop.screensaver lock-enabled
false
$ gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'idle-dim|sleep-inactive-(ac|battery)-type|power-button-action'
org.gnome.settings-daemon.plugins.power idle-dim false
org.gnome.settings-daemon.plugins.power power-button-action 'interactive'
org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
$ cat /etc/dconf/db/gdm.d/90-power
[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-type='nothing'
sleep-inactive-battery-type='nothing'
power-button-action='interactive'
$ sudo -u gdm env DCONF_PROFILE=gdm gsettings list-recursively org.gnome.settings-daemon.plugins.power | grep -E 'sleep-inactive-(ac|battery)-type|power-button-action'
org.gnome.settings-daemon.plugins.power power-button-action 'interactive'
org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
```

**systemd のコンテナ**（手順 5 の直後）:

```
$ systemctl is-enabled sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
masked
masked
masked
masked
masked
$ cat /etc/systemd/logind.conf.d/90-lid.conf
[Login]
HandleLidSwitch=ignore
$ busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager HandleLidSwitch
s "ignore"
```

#### 画面オフ・ロック・サスペンド: 操作上の注意と併記されていた記録

  - `sudo -u gdm` の行（手順 3 と[ロールバック](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意)の手順 2）も `/usr/bin/gsettings` を明示する。以前の無修飾の形も、検証した `secure_path` では RPM のものが選ばれた

#### 画面オフ・ロック・サスペンド: 操作上の注意と併記されていた記録

    - [homebrew.md の sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節を通しても、Homebrew は `secure_path` の末尾なので、`/bin/gsettings` が先に見つかる（同じ形のコマンドを、その節を通したコンテナで確かめた。[homebrew.md の付録](#homebrew-付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)）

#### 画面オフ・ロック・サスペンド: 付録: コンテナでの検証記録（2026-09-27）

x86_64 のクラウドホスト上の Docker で、使い捨てのコンテナを 2 つ使った。どちらも非 root ユーザーを作り、NOPASSWD の sudo を与えている。実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、実機で加えた変更は無い。

- **GNOME の一式のコンテナ**: `quay.io/almalinuxorg/almalinux:10.2` に `sudo`・`gdm`・`gnome-control-center` を `dnf install` で入れ、GNOME の一式を依存で揃えた（488 パッケージ）
  - GNOME のセッションの代わりに、`dbus-run-session -- bash` の中でコードブロックを実行した
  - 落とし穴の再現（引用符・`uint32`・セッションバスの無いシェル・自分のユーザーで読んだとき）と、Server with GUI との比較は、同じ構成の別のコンテナで行った
- **systemd のコンテナ**: `quay.io/almalinuxorg/10-init:10.2` に `systemd-udev`（sleep 系の target を含む）を入れ、イメージが mask している `systemd-logind` を戻して、systemd を PID 1 で動かした
  - ホストに触れないように、udev・sysctl・モジュールの読み込みなどの unit は mask した
  - `/sys/power` は、中身（`state` に `freeze mem disk` など）を書いた tmpfs に差し替えた。logind はサスペンドできると判断するが、本当には眠れない。サスペンドを呼ぶ操作は一度もしていない

| 手順 | 結果 |
|---|---|
| 1. 変数 | `USER = <USER>`、`IDLE_DELAY = 0`、`LOCK_ENABLED = false`、`POWER_BUTTON = interactive` |
| 2. 自分のセッション | 読み戻しは [完了時点の状態](#画面オフロックサスペンド-完了時点の状態) のとおり。`~/.config/dconf/user`（748 バイト）ができた。セッションバスを用意しないと `failed to commit changes to dconf` で値が変わらず、終了コードは 0 だった |
| 3. ログイン画面 | `dconf update` は無出力で終了コード 0。`gdm` ユーザーで読んだ値が `'nothing'` 2 つと `'interactive'` になった。引用符を外したファイルでは `invalid value` で終了コード 1、`idle-delay=0` は無視されて `uint32 300` のまま（手順 3 の補足） |
| 4. mask | `Created symlink` が 5 行、`masked` が 5 行。logind の `CanSuspend` は mask の前が `"yes"`、後が `"no"` |
| 5. 蓋 | reload で journal に `Config file reloaded.`。`HandleLidSwitch` は `"suspend"` から `"ignore"` に |
| ロールバック 1 | `uint32 300`・`true`・`idle-dim true`・`'suspend'` が 3 つ |
| ロールバック 2 | `gdm` ユーザーで読んだ値が 3 つとも `'suspend'` に戻った。`gdm.d` には `locks` だけが残った |
| ロールバック 3 | `Removed` が 5 行、`static` が 5 行。`CanSuspend` は `"yes"` に戻った |
| ロールバック 4 | `s "suspend"`。空の `/etc/systemd/logind.conf.d` が残った |
| 比較. Server with GUI | `gnome-settings-daemon-server-defaults` を入れると、自分のセッションとログイン画面の両方で `sleep-inactive-ac-timeout` が `0` になり、`power-button-action` は `'suspend'` のままだった（[注意点](../extra/almalinux-setup.md#注意点)）。確かめた後に消した |

##### 画面オフ・ロック・サスペンド: 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- 画面が消えない・暗くならない・ロックしないこと（GNOME のセッションで）
- 放置しても、ログイン画面のままでも眠らないこと
- 蓋を閉じたとき・電源ボタンを押したときの動き
- GNOME のメニューと設定アプリで、サスペンドの項目が消えること
- SSH で入ったシェルから `gsettings` で変えた値が、動いている GNOME のセッションに届くか
- 動いているログイン画面に、`dconf update` の後いつから効くか
- GNOME Remote Desktop のリモートログインのセッションを放置したときの動き

---

#### 画面オフ・ロック・サスペンド: 付録: 実機での検証記録（2026-10-01）

**環境**: Raspberry Pi 5（aarch64）の AlmaLinux 10.2。モニターはつながっておらず、[gnome-headless-session.md](../gnome-headless-session.md) のヘッドレスのセッションを動かした（表の「実機」の列）。PATH の先頭は Homebrew で、`command -v gsettings` は `/home/linuxbrew/.linuxbrew/bin/gsettings`（glib 2.90.0）だった。

**流し方**: GNOME のヘッドレスのセッションの手順書（分ける前の版）の検証の中で、この文書の手順 1・2 のブロックを、SSH でログインしたユーザーの `bash -i`（擬似端末）にそのまま書き込んだ。1 回目はブラケットペースト無し、2 回目はブラケットペーストで貼った（その記録は、今の [claude-code-gui.md の付録](claude-code-gui.md#付録-実機での検証記録2026-10-01)）。

| 手順 | 結果 |
|---|---|
| 1. 変数 | `USER = <USER>`、`IDLE_DELAY = 0`、`LOCK_ENABLED = false`、`POWER_BUTTON = interactive` |
| 2. 自分のセッション | `uint32 0`・`false`・`idle-dim false`・`power-button-action 'interactive'`・`sleep-inactive-ac-type 'nothing'`・`sleep-inactive-battery-type 'nothing'`（2 回とも） |

- **実施前**: dconf には前から `idle-delay` の `uint32 0` と `lock-enabled` の `false` があり、電源のキーは既定値だった
- **Homebrew の `gsettings`**: 直す前の手順 2 の形（`gsettings`）では、この PC の PATH で Homebrew の `gsettings` が動く。Homebrew の `gsettings get org.gnome.desktop.session idle-delay` は `uint32 300` を返し（dconf の値は `uint32 0`）、Homebrew の `gsettings set` の値は `~/.config/glib-2.0/settings/keyfile` に入った（手順 2 の補足）
- **動いているセッションに効くか**: ヘッドレスのセッションが動いている間に、SSH のシェルから `/usr/bin/gsettings set org.gnome.desktop.interface clock-show-seconds true` を実行すると、上部バーの時計にすぐ秒が出た（画面を撮って確かめた。`reset` で消えた）
- **放置によるサスペンド**: 手順 2 の前（`sleep-inactive-ac-type` が `'suspend'`）は、ヘッドレスのセッションを無操作で 15 分置くと、gsd-power が `Error calling suspend action: … SleepVerbNotSupported …` を出した（サスペンドしようとした。この Pi はサスペンドできない）
  - 手順 2 の後（`'nothing'`）は、同じヘッドレスのセッションを 16 分余り放置しても、`Error calling suspend action` も「Suspending soon」の通知も出ず、画面も消えなかった。SSH のシェルから変えた値が、動いているセッションに効いた

##### 画面オフ・ロック・サスペンド: 未確認事項

- 実機での手順 3〜5 とロールバック
- 画面が消えない・暗くならないこと（モニターのある PC で）
- x86_64 の PC

#### 画面オフ・ロック・サスペンド: 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を新規に入れた x86_64 の VirtualBox VM（1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で確認した。シェルのブロックは手順書から抜き出して、検証用ユーザーの SSH の対話シェルへ個別に貼った。GUI はヘッドレスの GNOME に 1920x1080 の仮想モニターを付け、既存の `scripts/gnome-gui.py` を変更せずコピーして、操作の後に撮った PNG を見た。利用者のアカウントは使っていない。

手順 1〜5 → ロールバック 1〜4 → 手順 1〜5 を通した。自分の 6 キー、GDM から見える 3 キー、5 target の mask、logind の `HandleLidSwitch` が設定値になり、戻してから再適用できた。`systemctl is-enabled` は 5 行とも `masked` で終了コード 1（期待どおり）、unmask 後は 5 行とも `static` だった。物理モニター、蓋、実際のサスペンド、電源ボタンはこの VM では確認できない。

この設定を残した VM を RDP の標準構成で 1 回、GUI の仮想モニター構成で 1 回再起動し、2 回ともヘッドレスのセッションが自動起動した。最後に `idle-delay=0`、`lock-enabled=false`、sleep / suspend / hibernate / hybrid-sleep / suspend-then-hibernate の 5 target が masked のまま残ることを読み戻した。実際の蓋・電源ボタン・サスペンド復帰は VM では測っていない。

---

#### 画面オフ・ロック・サスペンド: 付録: 現行版の新規 VM での再検証（2026-10-06）

**環境と流し方**: `5da3478` の現行手順を、別のクリーンな AlmaLinux 10.2 Workstation / x86_64 の VM（1 vCPU、SELinux Enforcing、firewalld 稼働、US 配列）で実行した。SSH の一般ユーザーの対話 PTY に折り畳みの外のブロックを手順ごとに貼り、応答とプロンプトを待った。GUI は GNOME 49.4 のヘッドレスセッションに仮想モニターを付け、操作後の PNG を目視した。既存の実機・資格情報は使っていない。

実施手順 1〜5、ロールバック 1〜4 を本実行した。画面オフ `0`、ロック `false`、自動サスペンド `nothing`、GDM の電源設定、logind の蓋設定と 5 つの sleep target の mask を読み戻した。解除後は `idle-delay=300`、ロック `true`、サスペンド `suspend`、target は `static`、蓋設定の drop-in は削除された。

今回は設定の適用・読み戻しと解除の確認であり、長時間放置による省電力動作、物理モニター、実際のサスペンド、蓋・電源ボタンの操作は実施していない。

#### 画面オフ・ロック・サスペンド: 操作上の注意と併記されていた記録

    - Raspberry Pi 5 で、`sudo -u gdm env sh -c 'command -v gsettings'` が `/bin/gsettings` を返した（手順 3 そのものは実機で流していない）

### 画面オフ・ロック・サスペンド: 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

#### 画面オフ・ロック・サスペンド: 補足

  - `power-button-action=nothing` は引用符が無いので、スキーマのコンパイルで読み飛ばされ、電源ボタンは既定の `'suspend'` のまま（コンテナで確認。同じ内容を `glib-compile-schemas --strict` に通すと `can not parse as value of type 's'` で止まる）

---

## 統合前の記録: starship（もとは starship.md）

もとの `starship.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1（変数） | starship のプリセットを当てる（任意）の 2 |
| 実施手順 2 | 「シェルのツール」の手順 1 |
| 実施手順 3・5 | 「シェルのツール」の手順 4 |
| 実施手順 4 | 「シェルのツール」の手順 2 |
| プリセットを当てる（任意）の 1・2 | starship のプリセットを当てる（任意）の 1・2 |
| 設定ファイルの 1 | starship の設定ファイルの 1 |
| ユーザー名とホスト名を常に表示するの 1 | starship でユーザー名とホスト名を常に表示する（任意）の 1 |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 3 |
| ロールバック 2・3 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 5 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### starship: 補足

#### starship: 実施手順: 検証状況の記録

> [!WARNING]
> **直接追記していた旧版の導入・プロンプト・プリセットは、コンテナと x86_64 のクリーン VM で検証済み**。現行の共通 bash 設定の新規導入・常時表示も別の新規 VM で再検証した（末尾の記録）。既存ホストの移行は今回は未実施。ユーザー切り替え時の表示条件と常時表示の設定は、aarch64 の実機で確認した（[対象と検証環境](#starship-対象と検証環境)）。

#### starship: 実施手順 / 手順 5: 補足: 端末が無くても確かめられる

starship は「プロンプト文字列を標準出力に出す」だけのコマンドなので、**pty が無い環境でも動作確認ができる**。コンテナでの実測（ANSI エスケープは除いてある）:

```
$ starship prompt

~
⬢ [podman] ❯
$ starship module directory
~
$ starship explain

 Here's a breakdown of your prompt:
 ~                     -  The current working directory
 container  [podman]   -  The container indicator, if inside a container.
 >                     -  A character (usually an arrow) beside where the text is entered in your terminal
$ starship timings

 Here are the timings of modules in your prompt (>=1ms or output):
 directory   -  <1ms  -   "~ "
 line_break  -  <1ms  -   "\n"
 container   -  <1ms  -   "\n"
 character   -  <1ms  -   "> "
```

- `container [podman]` はコンテナの中で実行したから出ているモジュールで、実機では出ない
- `explain` の 3 行目が `>` になっているのは、`plain-text-symbols` プリセットを当てた後だから（既定は `❯`）

**確かめられるのはここまで**で、`PS1` として実際に描画されたときの見た目、色、Nerd Font のグリフは端末が要る。

#### starship: ユーザー名とホスト名を常に表示する / 手順 1: 補足: ユーザーを切り替えると表示が消える理由

- 既定の `username.show_always = false` では、root・ログイン名と異なるユーザー・SSH 接続などの条件でユーザー名を出す。`hostname.ssh_only = true` では、`SSH_CONNECTION` があるときだけホスト名を出す
- `sudo` の `env_reset` と `su -` は SSH 関連の環境変数を消す。`sudo su -` → `su - 自分のユーザー` と切り替えると、一般ユーザーで `LOGNAME` も自分の名前になり、既定の表示条件を満たさなくなる
- `su - 自分のユーザー` は新しいシェルを起動する。元のシェルへ戻るには root で `exit` する。既に一般ユーザーのシェルを重ねた場合は `exit` を 2 回実行する
- この節の設定は SSH 判定に依存せず名前を出す。環境変数が消える動作自体は変えない（[実測](#starship-付録-ユーザー切り替えと常時表示の確認2026-10-06)、[公式の username 設定](https://starship.rs/config/#username)、[hostname 設定](https://starship.rs/config/#hostname)）

#### starship: ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**

- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

#### starship: 対象と検証環境

- **目的**: AlmaLinux 10 のシェルプロンプトを [starship](https://starship.rs/)（git の状態・言語バージョン・終了コードなどを自動で出すプロンプト）に置き換える。**EPEL にも AppStream にも RPM が無い**
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**:
  - **直接追記していた旧版の導入手順はコンテナで検証済み**（2026-09-22、並びを直した当時の手順 3〜7 とプリセットの節の手順 2 は 2026-09-30）
  - **x86_64 のクリーン VM では `0dbb522` 版の導入・プロンプト・プリセットを本実行済み**（2026-10-06）。共通 bash の新規導入・常時表示は別の新規 VM で再検証した（末尾の記録）。既存ホストの移行は今回は未実施（[今回の付録](#starship-付録-クリーン-vm-での検証記録2026-10-06)）
  - **ユーザー切り替え時の表示条件と常時表示の設定は aarch64 の実機で確認済み**（2026-10-06）
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**[Homebrew の導入](../almalinux-setup.md)と手順 2・4・7、[プリセットを当てる（任意）](../almalinux-setup.md#starship-のプリセットを当てる任意)・[設定ファイル](../almalinux-setup.md#starship-の設定ファイル)を通した
  - 2026-09-30 に、並びを直した手順 3〜7 とプリセットの節の手順 2 を、x86_64 のコンテナで流し直した（[付録](#starship-付録-並びを直した版の検証2026-09-30)）。WezTerm のシェル統合と zoxide と一緒に読んだ対話のシェルを、`script` の擬似端末で動かして生の出力を見た
  - 確認したこと: `arm64_linux` のボトルが降りる、`starship 1.26.0` が入る、`starship prompt` / `module` / `explain` / `timings` が端末なしでも文字列を返す、`~/.bashrc` への追記と差し込み（前の版の並びからの移動と、後ろにあった `brew shellenv` の行の移動も）、WezTerm のシェル統合の OSC 133 の `C` / `D`（終了コード）と、zoxide の警告が出ないこと
  - SSH の PTY での実際のプロンプト表示と `plain-text-symbols` プリセットは、2026-10-06 に `0dbb522` 版をクリーン VM で確認した。GNOME 端末・WezTerm の画面での色・グリフと、WezTerm でのプロンプトへのジャンプ・出力のコピーは未確認
  - 実機では導入済みの starship 1.26.0 を使い、SSH 関連の環境変数による表示の変化と、一般ユーザーの常時表示設定を確認した。導入・更新・削除は再実行していない（[付録](#starship-付録-ユーザー切り替えと常時表示の確認2026-10-06)）
  - 下表の実機列は **2026-09-22 時点の状態**で、本書の導入手順を適用した結果ではない。2026-10-06 の実機の状態は付録に記録した

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| starship | **未導入** | `starship 1.26.0`（`arm64_linux` ボトル） |
| 一緒に入る依存 | — | `expat` / `dbus` / `zlib-ng-compat` |
| `~/.bashrc` | 38 行。26 行 `brew shellenv` / 27-33 行 yazi の `y()` / 34 行 `zoxide init` / 36-38 行 WezTerm シェル統合 | 手順 4 で `starship init` を末尾に追記 |
| Nerd Font | `font-symbols-only-nerd-font 3.5.1`（Homebrew、[yazi.md](../almalinux-setup.md#yazi)） | 無し |
| 端末 | WezTerm nightly（[wezterm-nightly.md](../almalinux-setup.md#wezterm)。OSC 133 のシェル統合あり） | 無し（pty を与えずに実行） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../almalinux-setup.md#starship-のプリセットを当てる任意) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${STARSHIP_PRESET}` | [プリセットを当てる（任意）](../almalinux-setup.md#starship-のプリセットを当てる任意)で使う名前 | `plain-text-symbols`（既定）/ `no-nerd-font` / `tokyo-night` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`1.26.0`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### starship: 実施前の状態

| 項目 | 状態 |
|---|---|
| starship | 未導入 |
| Homebrew | 7.0.6 導入済み |
| プロンプト | bash の既定（`/etc/bashrc` が組み立てた `PS1`）に、WezTerm のシェル統合が OSC 133 の印を前後に足したもの |
| `~/.bashrc` | 38 行。末尾に zoxide の初期化と WezTerm シェル統合の読み込みがある |
| EPEL | 有効。ただし `starship` は無い |

#### starship: 選択した方針

AlmaLinux 10 aarch64 で starship を入れる経路を比べた（2026-09-22 時点）:

#### starship: 完了時点の状態

**検証コンテナでの出力**（実機では本実行していない）:

```
$ starship --version
starship 1.26.0
branch:
commit_hash:
build_time:2026-06-28 17:02:30 +00:00
build_env:rustc 1.96.0 (ac68faa20 2026-05-25) (Homebrew),
$ brew list --versions starship
starship 1.26.0
$ command -v starship
/home/linuxbrew/.linuxbrew/bin/starship
$ grep -n 'starship init' ~/.bashrc
28:eval "$(starship init bash)"
$ wc -l ~/.config/starship.toml
335 /home/<USER>/.config/starship.toml
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/starship/1.26.0/`（12 ファイル、11 MB）。

#### starship: 操作上の注意と併記されていた記録

- **starship の初期化は、`brew shellenv` の行より後ろ、zoxide の初期化と WezTerm のシェル統合より前に置く**: zoxide・WezTerm より後ろにあると、この設定の WezTerm のシェル統合が働くとき（COPR の公式の統合が無いとき）は、WezTerm に送る終了コード（OSC 133 の `D`）がいつも 0 になる（[bash の読む順番](https://github.com/ryo-aoki-pc/bash/blob/main/docs/reference/readme.md#読む順番)の実測）。`brew shellenv` より前にあると、`starship: command not found` になる

#### starship: 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](../almalinux-setup.md)と手順 2・4・7、[プリセットを当てる（任意）](../almalinux-setup.md#starship-のプリセットを当てる任意)・[設定ファイル](../almalinux-setup.md#starship-の設定ファイル)を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。[bat](../almalinux-setup.md) / [git-delta](../almalinux-setup.md#git-delta) / [eza](../almalinux-setup.md) / [gdu](../gdu.md) を先に入れた同じコンテナで続けている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](../almalinux-setup.md)） |
| 2. starship | `Pouring expat--2.8.5` → `dbus--1.16.2_1` → `starship--1.26.0.arm64_linux.bottle.tar.gz` の順に降り、`12 files, 11MB`。ソースビルドは発生しない |
| 4. 初期化 | `~/.bashrc` に `eval "$(starship init bash)"` を追記して読み込み直し、エラーなく通った（非対話シェルなのでプロンプト自体は描画されない） |
| 7. 検証 | `starship --version` → `1.26.0`（`build_env` に `rustc 1.96.0 ... (Homebrew)`）。`starship prompt` / `module directory` / `explain` / `timings` がいずれも文字列を返した |
| プリセット | `starship preset --list` で 12 個（`bracketed-segments` / `catppuccin-powerline` / `gruvbox-rainbow` / `jetpack` / `nerd-font-symbols` / `no-empty-icons` / `no-nerd-font` / `no-runtime-versions` / `pastel-powerline` / `plain-text-symbols` / `pure-preset` / `tokyo-night`）。`plain-text-symbols` を `-o` で書き出して 335 行の `starship.toml` が生成され、`starship explain` のプロンプト記号が `❯` から `>` に変わることを確認 |
| 初期化の中身 | `starship init bash --print-full-init` を読み、`PS1` を毎回組み立て直すこと・既存の `PROMPT_COMMAND` を `STARSHIP_PROMPT_COMMAND` に退避して呼ぶこと・`PS0` には前置きすることを確認（[手順 3 の補足](../almalinux-setup.md#シェルのツール)の根拠） |
| RPM 経路 | `dnf list --available starship` → `Error: No matching Packages to list`（EPEL を有効にした状態で） |

##### starship: 未確認事項

- 実機での本実行（本書は実機に適用していない。検証はコンテナのみ）
- 端末での実際のプロンプト表示（色、記号、git 情報、Nerd Font のグリフ）
- **WezTerm のシェル統合との相性**（OSC 133 の `A` / `B` が失われるという推定の実地確認。`C` / `D` が残るかも未確認）
- zoxide の `PROMPT_COMMAND` フックとの共存
- Raspberry Pi 5 の microSD 上の大きなリポジトリでのプロンプト遅延
- `plain-text-symbols` 以外のプリセット
- `~/.bashrc` で `export STARSHIP_CONFIG=...` して場所を変える方法
- bash 以外のシェル（zsh / fish）での `starship init`
- ロールバック（`brew uninstall` と `~/.bashrc` の行削除）の本実行

#### starship: 付録: 並びを直した版の検証（2026-09-30）

手順 3〜5 を「starship を zoxide の初期化と WezTerm のシェル統合より前に置く」に直した版を、x86_64 のクラウドホストの Docker で立てた `almalinux:10`（AlmaLinux 10.2、bash 5.2.26）で流した。Homebrew 7.0.7 で starship 1.26.0 と zoxide 0.10.0 を入れた。WezTerm と COPR の公式の統合は入れず、ryo-aoki-pc/wezterm の設定を `~/.config/wezterm` に clone した（`shell/wezterm.sh` は、印を BEL で終える直しの入ったもの）。**この文書のコードブロックを抜き出したもの**を、そのユーザーの `bash -s` に流した。

| ユーザー（実施前の `~/.bashrc` の末尾） | 流した手順 | 結果 |
|---|---|---|
| st1（実機と同じ並び: 26 行目 `brew shellenv`、27〜33 行目 `y()`、34 行目 `zoxide init bash`、36〜38 行目 WezTerm の `if [ -n "$WEZTERM_SHELL_INTEGRATION" ]; then` の 3 行） | 手順 3・5（当時の、`brew shellenv` の行を動かさない版）・7 | 手順 3 は `34:eval "$(zoxide init bash)"` と WezTerm の 2 行。手順 5 の後は `34:eval "$(starship init bash)"`・`35:eval "$(zoxide init bash)"`・`37:if [ -n "$WEZTERM_SHELL_INTEGRATION" ]; then`。手順 7 は `starship 1.26.0` などを出した |
| st2（`/etc/skel` の後ろに `brew shellenv` だけ） | 手順 3・4、手順 1 とプリセットの節の手順 2 | 手順 3 は何も出さず、手順 4 は `eval "$(starship init bash)"`。プリセットは `335 /home/<USER>/.config/starship.toml` と `starship prompt` の出力 |
| st3（前の版のこの文書の並び: `zoxide init bash --cmd z` → WezTerm の 1 行 → starship が最後） | 手順 3・5（当時の版） | 手順 3 は 27〜29 行目の 3 行。手順 5 の後は starship が 27 行目に移り、zoxide と WezTerm の行が 28・29 行目。starship の行は 1 つだけ |

- st1 と st3 で、`TERM_PROGRAM=WezTerm` と WezTerm が渡す `WEZTERM_SHELL_INTEGRATION` を付けて `script` の擬似端末の `bash -il` を開き、`false`・`sleep 3`・`cd /usr/share`・`z share` などを打ち込んで、生の出力を見た
  - OSC 133 は、コマンドごとに `C`、`false` の後は `D;1`（ほかは `D;0`）。`A` / `B` は出なかった（starship が `PS1` を作り直すため）
  - `zoxide: detected a possible configuration issue.` は出ず、`sleep 3` の後のプロンプトに `took 3s` が出た。`${STARSHIP_START_TIME:0:0}` の文字は出なかった
  - `PROMPT_COMMAND` は `([0]="__wezterm_prompt_command;__wz_mouse_off;starship_precmd" [1]="__zoxide_hook")`。環境変数で文字列の `PROMPT_COMMAND=:` を渡して開いたシェル（Git Bash と同じ形）でも、`D;1` で警告は出なかった
- 前の版の並び（starship が最後）は、同じ方法で `D` がいつも `D;0` で、文字列の `PROMPT_COMMAND` では `z` が警告を出した（自分用の bash の設定 ryo-aoki-pc/bash の README の「読む順番」）
- `. ~/.bashrc` で読み直すと、配列の `PROMPT_COMMAND` に zoxide のフックが 2 つ入った（zoxide は配列の先頭しか見ない。並びとは関係が無い）

##### starship: 手順 5 に `brew shellenv` の行の移動を足した後（2026-09-30 の夜）

手順 5 を、`brew shellenv` の行が zoxide か WezTerm の行より後ろにあれば starship の行と一緒に前へ移す形に、手順 6 を端末を開き直す手順に直した後、同じコンテナで、この文書のコードブロックを抜き出し直して流した。どのユーザーも、`/etc/skel` の `~/.bashrc` の後ろに下の行を置いてから始めた。

| ユーザー（実施前の並び） | 流した手順 | 結果（手順 5 の後の並び） |
|---|---|---|
| sa（`brew shellenv` → `zoxide init bash --cmd z` → WezTerm の 1 行） | 手順 3・5 | 26 行目 `brew shellenv` → starship → zoxide → WezTerm |
| sb（WezTerm の 1 行 → `brew shellenv` → zoxide） | 手順 3・5・5 | `brew shellenv` が WezTerm の行の上に移り、26 行目 `brew shellenv` → starship → WezTerm → zoxide。2 回目の手順 5 では変わらなかった |
| sc（前の版のこの文書の並び: `brew shellenv` → zoxide → WezTerm → starship） | 手順 5 | 26 行目 `brew shellenv` → starship → zoxide → WezTerm。starship の行は 1 つだけ |
| sd（WezTerm の 1 行 → `brew shellenv` → starship） | 手順 3・5 | 26 行目 `brew shellenv` → starship → WezTerm |
| se（`brew shellenv` → starship） | 手順 3・5 | 変わらなかった |
| sf（`brew shellenv` → WezTerm → starship → zoxide） | 手順 3・5 | 26 行目 `brew shellenv` → starship → WezTerm → zoxide |
| sg（`brew shellenv` だけ） | 手順 3・4、手順 1 とプリセットの節の手順 2 | 手順 3 は 26 行目の `brew shellenv` だけを出し、手順 4 で末尾に starship。プリセットは `335 /home/<USER>/.config/starship.toml` |

- どのユーザーも、手順の後に `su -` で開いた新しいログインシェルは何も出さなかった（`command not found` が無い）
- sa と sf で、手順 1 と手順 7 を流すと、`starship 1.26.0` と `starship prompt` の出力が出た
- 手順 6 の代わりに、`script` の擬似端末で `bash -il` を開き直し、上の表の st1・st3 と同じコマンドを打ち込んだ（sa・sb・sc・sf・sg）
  - sa・sb・sc・sf: `false` の後だけ `D;1`（ほかは `D;0`）、zoxide の警告は 0 回、`sleep 3` の後に `took` が出た。`PROMPT_COMMAND` はどれも `([0]="__wezterm_prompt_command;__wz_mouse_off;starship_precmd" [1]="__zoxide_hook")`
  - sg（WezTerm の行が無い）: OSC 133 の印は出ず、`PROMPT_COMMAND` は `([0]="starship_precmd")`
  - `. ~/.bashrc` で読み直すと、zoxide のフックが 2 つになるのは上と同じ

##### starship: 未確認事項（並びを直した版）

- 端末の画面でのプロンプトの見た目、WezTerm でのプロンプトへのジャンプ・出力のコピー
- 実機（Raspberry Pi 5）での本実行
- COPR の WezTerm の公式の統合がある実機での、この並び

#### starship: 付録: ユーザー切り替えと常時表示の確認（2026-10-06）

- **環境**: AlmaLinux 10.2 / aarch64 の実機（Raspberry Pi 5）、導入済みの starship 1.26.0、util-linux の su 2.40.2。一般ユーザーは bash の共通設定を導入済み
- **再現**: 設定ファイルが無い既定の状態で、`sudo su -` → `su - 自分のユーザー` を `-c` の子シェルで再現し、環境変数の有無と `starship module username` / `hostname` の出力を確認した

| 状態 | SSH_CONNECTION / SSH_CLIENT | USER / LOGNAME | username の出力 | hostname の出力 |
|---|---|---|---|---|
| 最初の一般ユーザー | あり / あり | 自分 / 自分 | `<USER> in ` | `🌐 <HOSTNAME> in ` |
| root へ切り替えた後 | なし / なし | root / root | `root in ` | 空 |
| 一般ユーザーのシェルを起動した後 | なし / なし | 自分 / 自分 | 空 | 空 |
| 子シェルを終了して元のシェルに戻った後 | あり / あり | 自分 / 自分 | `<USER> in ` | `🌐 <HOSTNAME> in ` |

- `SSH_TTY` は最初から未設定だった。`sudo` だけでも SSH 関連の変数が消え、対象の 3 変数を `sudo --preserve-env` で渡しても、続く `su -` で消えた
- `SSH_CONNECTION` だけを与えると両方が出た。`SSH_CLIENT` または `SSH_TTY` だけではユーザー名だけが出た
- 一般ユーザーの `~/.config/starship.toml` に `username.show_always = true` と `hostname.ssh_only = false` を設定した。`sudo su -` → `su - 自分のユーザー` を再実行し、SSH 関連の 3 変数がなくても両方のモジュールが出ることを確認した
- [常時表示の手順](../almalinux-setup.md#starship-でユーザー名とホスト名を常に表示する任意)の `starship config` は、一時設定ファイルで新規作成と更新を確認した。既存の directory・character の設定とコメントを保ち、再実行しても TOML のセクションが重複しなかった
- 確認対象はモジュールの生成文字列。端末の画面での色・記号、root の設定変更、パッケージの導入・更新・削除は今回の検証対象に含めていない

---

#### starship: 付録: クリーン VM での検証記録（2026-10-06）

**検証した版**: `0dbb522` 版（`~/.bashrc` に直接追記していた版）を検証した。後から入った共通 bash 設定の導入・移行と、[ユーザー名とホスト名を常に表示する](../almalinux-setup.md#starship-でユーザー名とホスト名を常に表示する任意)任意節は今回の VM で未実施。以下の手順番号は、現行手順ではなく、検証した `0dbb522` 版の番号を示す。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証した旧版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: `0dbb522` 版の実施手順 1・2・3・5・6・7、プリセットの任意節 1・2（zoxide が既存のため、当時の手順 4 は条件外）。

**結果**: Homebrew の starship 1.26.0 を導入した。既存の zoxide 初期化の前へ、検証した旧版の手順 5 で差し込み、`brew shellenv` → starship → zoxide の順を確認した。今のシェルでは読み直さず SSH を切り、再ログインしたシェルで実際のプロンプトと `prompt`・`module directory`・`explain` を確認した。`plain-text-symbols` プリセットを適用すると、335 行の設定が作られ、次のプロンプトから ASCII の `>` と `ssh` の表示に変わった。

**今回の未確認範囲**: 現行の共通 bash 設定の導入・移行、ユーザー名とホスト名の常時表示、WezTerm のシェル統合と OSC 133、別の並びからの移動、別のプリセット・手動設定、更新・ロールバックは今回の VM で確認していない。常時表示を確認した aarch64 の実機の記録は、前の付録に分けて残した。

#### starship: 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜5 と「ユーザー名とホスト名を常に表示する」を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で共通 bash `3d5323e` の導入後に実行した。starship 1.26.0 を導入した後は対話 SSH を張り直し、init とプロンプト・`starship explain` を確認した
- 既存の `add_newline = false` を残して `[username] show_always = true` / `[hostname] ssh_only = false` を設定した。SSH 環境変数を外したシェルでも名前・ホスト名が出た。共通設定を読み直しても `PS0` と `PROMPT_COMMAND` は増えなかった
- 任意のプリセット節と設定ファイル例も通した。既存設定への `preset -o` は上書きを拒否し、後続の `wc` / `prompt` で成功に見えたため、本文に `--force` を足し、成功時だけ後続確認へ進む `&&` でつないだ。事前に設定を控え、335 行の `plain-text-symbols` と `>` のプロンプトを確認した後、元の設定を SHA-256 の一致まで戻した
- 実際の別ユーザーへの切り替え、GUI 端末、更新・削除はこの再検証には含まない

#### starship: 操作上の注意と併記されていた記録

   - 今のシェルで `. ~/.bashrc` を読み直さない（starship が、そのシェルで既に読んだ WezTerm のシェル統合より後ろで初期化され、WezTerm のフックが 2 回ずつ動く。失敗したコマンドの後に `D;1` と `D;0` が続けて送られた）

### starship: 参考資料から分離した記録

#### starship: 参考資料: 実施手順 / 手順 2: 補足: 降ってくるボトル

aarch64 で降ってくるボトルは `starship--1.26.0.arm64_linux.bottle.tar.gz`。

#### starship: 参考資料: 選択した方針

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `starship 1.26.0` の `arm64_linux` ボトルがある。upstream の最新と一致 | **採用** |
| EPEL / AppStream / CRB | **`starship` というパッケージが無い**（`dnf list --available starship` → `Error: No matching Packages to list`） | 使えない |
| 公式 install.sh（`sh -c "$(curl -sS https://starship.rs/install.sh)"`） | `/usr/local/bin` にバイナリを 1 つ置く。`sudo` が要り、更新は自分で再実行する | 不採用（Homebrew に揃える） |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-musl` のビルドがある。更新は手作業 | 不採用 |
| `cargo install starship` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

---

## 統合前の記録: zoxide（もとは zoxide.md）

もとの `zoxide.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「共通の bash 設定」の手順 2 |
| 実施手順 2 | 「シェルのツール」の手順 1 |
| 実施手順 3・4 | 「シェルのツール」の手順 9 |
| 実施手順 5 | 「シェルのツール」の手順 10 |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 3 |
| ロールバック 2 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 8 |
| ロールバック 3 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 5 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### zoxide: 補足

#### zoxide: 実施手順 / 手順 4: 補足: データベース / 記録されるタイミング

学習結果は `~/.local/share/zoxide/db.zo`（バイナリ）に入る。中身は `zoxide query --list`（パスの一覧）や `zoxide query --list --score`（スコア付き）で読める。実機は 5 エントリ、287 バイト:

```
$ ls -l ~/.local/share/zoxide/
-rw-r--r--. 1 <USER> <USER> 287 Sep 22 18:31 db.zo
$ zoxide query --list | wc -l
5
```

特定のパスを忘れさせるには `zoxide remove`（引数はパス）。

**記録されるのは、対話シェルがプロンプトを出すときだけ**。`zoxide init` が仕込むのは `PROMPT_COMMAND` のフックで、プロンプトを出すときの今のディレクトリを 1 つ記録する。

- 非対話シェル（スクリプトや `bash -c`）で `cd` しても、データベースは増えない
- 2026-09-22 の検証コンテナで、当時の確認のブロック（`cd /tmp && cd /usr/share && cd ~` を含む）をスクリプトとして流したときは、`zoxide query --list` の出力が空になった
- 対話シェルでも、プロンプトが出るまでの間の `cd` は最後の 1 つしか記録されない。ホーム（`$HOME`）は既定で記録しない（`_ZO_EXCLUDE_DIRS` の既定値）
- ブラケットペーストで貼ると、複数行の貼り付けは 1 つの入力として実行され、プロンプトは最後に 1 回しか出ない
- そのため、`cd ~` で終わる当時のブロックは、ブラケットペーストの有無にかかわらず何も残さなかった（2026-09-29 に、当時あった dnf の経路の検証コンテナで確認）。確認を手順 4 と手順 5 に分けたのはこのため

#### zoxide: ロールバック / 手順 0: 本文中の記録

- この節の手順 1（`brew uninstall`）は**本実行していない**

#### zoxide: ロールバック / 手順 0: 本文中の記録

- この節の手順 2・3 は、x86_64 のコンテナで通した（2026-09-29。当時あった dnf の経路の検証の中で）

- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

#### zoxide: 対象と検証環境

- **目的**: AlmaLinux 10 に [zoxide](https://github.com/ajeetdsouza/zoxide)（よく行くディレクトリを覚えて短い入力で移動するツール）の最新版を入れる。**EPEL にも AppStream にも RPM が無い**（EL10 向けの RPM は COPR にしか無い）
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **実機で本実行済み（2026-09-21）。`0dbb522` の直接追記版の実施手順 1〜5 を x86_64 のクリーン VM でも本実行済み（2026-10-06）**。現行版 `5da3478` は、共通 bash 新規導入後の別の VM でも再検証した（末尾の再検証記録）。既存ホストの手動移行は行っていない。
  - 下表のホストで `brew install zoxide` を実行し、`~/.bashrc` に `eval "$(zoxide init bash)"` を書いて常用中（データベースに 5 エントリ）
  - **実機の初期化は `--cmd` 無し（コマンド名 `z`）で入れてある**
  - [Homebrew の導入](../almalinux-setup.md)と手順 2・3、それに当時の確認のブロック（今の手順 4・5 の元。`brew list --versions zoxide` と `cd /tmp && cd /usr/share && cd ~` を含む 1 つのブロック）は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - 確認したこと: ボトルが降りる、`~/.bashrc` に書いた初期化で `z` 関数が定義される（`type -t z` → `function`）
  - ただし**非対話シェルでは `cd` が記録されない**ため、そのときの `zoxide query --list` は空だった（[手順 4 の補足](../almalinux-setup.md#シェルのツール)）
  - 2026-09-29〜10-02 の版には、x86_64 だけの dnf（COPR `kray74/cli-tools`）の経路があった（2026-10-03 に外した。[選択した方針](#zoxide-選択した方針)）
    - 当時の手順 1・3〜8（3〜5 が dnf の手順で、6〜8 は今の手順 3〜5）、当時の[更新](../almalinux-setup.md#更新)の手順 2、当時の[ロールバック](../extra/almalinux-setup.md#シェルのツールと-bash-の設定を戻す)の手順 2〜5（4・5 は今の手順 2・3）を、x86_64 のコンテナで**その版のコードブロックのまま**、擬似端末の対話シェルに貼って通した（[付録](#zoxide-付録-dnf-の経路のコンテナでの検証記録2026-09-29)）
    - 今の手順 3〜5 と同じブロックで、`type -t z` → `function`、手順 5 で `/usr/share` が出る、`zi share` で `/usr/share` に移る、を確かめた（zoxide は dnf の `/usr/bin/zoxide`）
  - **確認していないこと**: `ZOXIDE_CMD=cd` の形、Homebrew の zoxide での `zi`（fzf 連携）

| 項目 | 実機 | 検証コンテナ | dnf の検証コンテナ（外した経路） |
|---|---|---|---|
| 実施日 | 2026-09-21 | 2026-09-22 | 2026-09-29 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） | AlmaLinux 10.2 (Lavender Lion) / x86_64（`docker.io/library/almalinux:10`、クラウドホスト上の Docker 29.3.1） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） | 使わない |
| 入った zoxide | `zoxide 0.10.0`（`arm64_linux` ボトル） | 同じ（`0.10.0`） | `zoxide-0.10.0-1.el10.x86_64`（COPR `kray74/cli-tools`） |
| fzf | `fzf 0.74.4`（Homebrew） | 未導入 | `fzf-0.74.4-1.el10.x86_64`（同じ COPR） |
| シェル | bash（`~/.bashrc` に `eval "$(zoxide init bash)"`） | bash（初期化は未設定） | bash（`~/.bashrc` に `eval "$(zoxide init bash --cmd z)"`） |

> [!NOTE]
> シェルのエイリアス・初期化は bash リポジトリの値を使う。本書で設定するシェル変数は無い。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### zoxide: 実施前の状態

| 項目 | 状態 |
|---|---|
| zoxide | 未導入 |
| Homebrew | 7.0.6 導入済み |
| fzf | `brew install yazi ...` の一部として同時に導入（[yazi.md](../almalinux-setup.md#yazi)） |
| EPEL | 有効。ただし `zoxide` は無い |

#### zoxide: 選択した方針

AlmaLinux 10 aarch64 で zoxide を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `zoxide 0.10.0` の `arm64_linux` ボトルがある。upstream の最新リリース（v0.10.0、2026-07-04）と一致 | **採用** |
| EPEL / AppStream / CRB | **`zoxide` というパッケージが無い**（`dnf list --available zoxide` → `Error: No matching Packages to list`） | 使えない |
| 公式 install.sh | `~/.local/bin` にバイナリを 1 つ置く。root 不要で軽いが、更新は自分で再実行する | 不採用（Homebrew に揃える） |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-musl` のビルドがある。展開して PATH に置くだけだが、更新は手作業 | 不採用 |
| `cargo install zoxide` | Rust toolchain（appstream に `rust 1.92.0` あり）が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

dnf で入れる経路は、2026-09-29 に x86_64 も含めて探し直した（EPEL はミラーのディレクトリ一覧とコンテナの `dnf list`、COPR は API とリポジトリのメタデータ）:

| 経路 | x86_64 | aarch64 | 採否 |
|---|---|---|---|
| COPR `kray74/cli-tools` | `zoxide-0.10.0-1.el10`（`epel-10-x86_64`）。spec は GitHub で公開、上流の tarball から cargo でビルド。man と補完も入る。同じ COPR の fzf は 0.74.4 | chroot が無い | 不採用（2026-09-29 に dnf の経路として採り、2026-10-03 に外した。下の箇条書き） |
| COPR `shdwchn10/AllTheTools` | `zoxide-0.10.0-1.el10` | `zoxide-0.10.0-1.el10` | 不採用（RPM に補完が無い。同じ COPR の fzf は 0.74.3） |
| COPR `faramirza/epel10` | `zoxide-0.10.0-2.el10` | `zoxide-0.10.0-2.el10` | 不採用（説明が無く、71 本の中に vim・tmux・jq・nano など BaseOS / AppStream と同じ名前のパッケージがある） |
| COPR `ldivizio/tools` | EL10 向けのビルドが無い（`fedora-44-x86_64` だけ） | 無い | 使えない |
| EPEL 10（10.0〜10.4・10z、testing も） | 無い（コンテナで EPEL を有効にしても `No matching Packages to list`） | 無い | 使えない |
| EPEL 9 | `zoxide-0.9.8-2.el9` | 調べていない | 不採用（EL9 向けで、版も古い） |
| Terra（`terrael10`） | 無い | 無い | 使えない |

- **Homebrew だけにした**（2026-10-03）。2026-09-29〜10-02 の版は、x86_64 だけの dnf の経路として `kray74/cli-tools` を載せていたが、外した
  - 版は Homebrew と同じ（zoxide 0.10.0、fzf 0.74.4。2026-10-03 の Homebrew の API）
  - x86_64 にしか無く、実機（Raspberry Pi 5）は aarch64
  - dnf の利点だった「`/usr/bin` に入り、`sudo` や root のシェルからも見える」は、homebrew.md の[root のシェルでも使う](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)・[sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節で足りる
  - COPR は個人のリポジトリで、Fedora は中身を審査しない（`dnf copr enable` の警告）。同じ COPR の chezmoi などが EPEL の同じ名前のパッケージを置き換えないよう、`includepkgs` で絞る手間も要った
- [tool-catalog.md の選び方](../tool-catalog.md#選び方)（RPM が Homebrew と同版以上なら RPM）は COPR を RPM に数えないので、一覧の推奨も Homebrew

#### zoxide: 完了時点の状態

実機:

```
$ brew list --versions zoxide
zoxide 0.10.0
$ zoxide --version
zoxide 0.10.0
$ command -v zoxide
/home/linuxbrew/.linuxbrew/bin/zoxide
$ type -t z
function
$ grep -n 'zoxide init' ~/.bashrc
34:eval "$(zoxide init bash)"
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/zoxide/0.10.0/`。データベースは `~/.local/share/zoxide/db.zo`。

#### zoxide: 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで、非 root ユーザーを作って[Homebrew の導入](../almalinux-setup.md)と手順 2・3・4 を通した（手順 4 は当時の確認のブロックで、今の手順 4・5 の元）。実機で加えた変更は `dnf install podman` だけ。 実行したのは**この文書のコードブロックをそのまま抜き出したスクリプト**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git sudo` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](../almalinux-setup.md)） |
| 2. zoxide | `Pouring zoxide--0.10.0.arm64_linux.bottle.tar.gz`。ソースビルドは発生しない |
| 3. 初期化 | `~/.bashrc` に `eval "$(zoxide init bash --cmd z)"` を追記して読み込み直し、`type -t z` → `function` |
| 4. 検証 | `zoxide --version` → `zoxide 0.10.0`。`cd` を 3 回してからの `zoxide query --list` は**空**（非対話シェルでは `PROMPT_COMMAND` のフックが走らないため） |
| fzf | `brew install zoxide fzf` で `fzf 0.74.4` と依存の `ncurses 6.6` も入った |
| RPM 経路 | EPEL を有効にしても `dnf list --available zoxide` は `Error: No matching Packages to list` |

実機側では `type -t z` が `function` を返し、`~/.bashrc` の 34 行目に `eval "$(zoxide init bash)"` があり、データベースに 5 エントリ溜まっていることを確認した（対話シェルでは記録される）。

##### zoxide: 未確認事項

- `ZOXIDE_CMD=cd`（`--cmd cd`）での動作。実機は `--cmd` 無しで入れてある
- `zi`（fzf 連携）の実動作
- bash 以外のシェル（zsh / fish）での `zoxide init`
- `_ZO_DATA_DIR` などの環境変数による挙動の変更
- ロールバック（`brew uninstall` と `~/.bashrc` の行削除）の本実行

#### zoxide: 付録: dnf の経路のコンテナでの検証記録（2026-09-29）

`docker.io/library/almalinux:10`（AlmaLinux 10.2、x86_64）のコンテナに NOPASSWD の sudo を与えた一般ユーザーを作り、**この文書のコードブロックをそのまま**、擬似端末（pty）で開いた対話の bash に貼って通した。

- 手順の番号は今の文書のものに付け替えた。「当時の」と付けたものは、2026-10-03 に外した dnf の経路の手順
- `[y/N]` には、プロンプトが出てから `y` を返した
- 通しは、ブロックを 1 行ずつ Enter で送る形（ブラケットペースト無し）で行った。手順 4・5 は、ブロックをブラケットペーストの開始と終了の制御文字で囲んで 1 回で送る形でも通した
- ブラケットペーストの有無の比較（この付録の最後）は、文書を書く前に同じコマンドで zoxide を入れた 1 つ目のコンテナで行った。ブラケットペースト有りは `TERM=xterm-256color`（`bind -v` が `enable-bracketed-paste on`）
- 検証環境だけの変更:
  - ホストの外向きの通信がプロキシ経由なので、dnf にプロキシ（`/etc/dnf/dnf.conf` の `proxy=`）とプロキシの CA を設定した
  - AlmaLinux の repo ファイルは `mirrorlist=` を止め、コメントにある `baseurl=`（`https://repo.almalinux.org/...`）を使った（ミラーリストが返す http のミラーを、プロキシが通さないため）
  - `sudo` と `procps-ng` は先に入れた（コンテナのイメージに無い）

| 手順 | 結果 |
|---|---|
| 前提 | `dnf-4.20.0-22.el10_2.alma.1` と `python3-dnf-plugins-core-4.7.0-10.el10`（`dnf copr` と `dnf config-manager` の本体）は最初から入っていた。`dnf-plugins-core` というパッケージは無いが、要らなかった |
| 当時の 3. COPR | 警告文の後の `[y/N]` に `y` → `Repository successfully enabled.`。repo ファイルの `baseurl` は `.../kray74/cli-tools/epel-10-$basearch/` |
| 当時の 4. 絞り込み | `11:includepkgs=zoxide,fzf`。COPR から見えるのは zoxide と fzf（と各 `.src`）だけ |
| 当時の 5. 導入 | `fzf-0.74.4-1.el10` と `zoxide-0.10.0-1.el10` の 2 つ（2.3 MB）。トランザクションの後に鍵 `0x405678BB` の取り込みを聞かれ、`Key imported successfully` |
| 3. 初期化 | `type -t z` → `function` |
| 4・5. 確認 | `zoxide 0.10.0`、`/usr/bin/zoxide`。手順 5 の `zoxide query --list` → `/usr/share`（ブラケットペーストの有りと無しの両方） |
| `zi` | 1 つ目のコンテナで、`zi share` で fzf が開き、Enter で `/usr/share` に移った |
| 当時の更新の手順 2 | `Nothing to do.`（COPR の最新が 0.10.0 のため） |
| ロールバックの当時の手順 2・3 と、手順 2・3（当時の 4・5） | `dnf remove` で消えたのは zoxide と fzf の 2 つだけ。`dnf copr remove` で repo ファイルが消え、鍵 `gpg-pubkey-405678bb-69063860` は残った。`sed` で `~/.bashrc` の行が消え、`~/.local/share/zoxide` も消えた |
| aarch64 | 別のコンテナで、`dnf --forcearch aarch64 copr enable kray74/cli-tools` は `Repository 'epel-10-aarch64' does not exist in project 'kray74/cli-tools'.` で止まり、repo ファイルは作られなかった |
| `includepkgs` | 別のコンテナで EPEL の fzf 0.58.0 と chezmoi 2.72.0 を入れてから COPR を有効にすると、`dnf upgrade --assumeno` の候補は、絞る前は chezmoi 2.72.2 と fzf 0.74.4（どちらも COPR）、絞った後は fzf 0.74.4 だけ |
| EPEL 10 | 別のコンテナで `epel-release` を入れても、`dnf list --available zoxide` は `Error: No matching Packages to list`（fzf 0.58.0・chezmoi 2.72.0 は EPEL にある）。検証環境だけ、EPEL の repo ファイルも `metalink=` を止めて `dl.fedoraproject.org` を直接指した |

**当時の確認のブロックが空になる理由**は、1 つ目のコンテナで確かめた。

- ブラケットペースト無し: `cd /tmp && cd /usr/share && cd ~` は 1 行なので、プロンプトは `~` に戻ってから 1 回だけ出る。ホームは既定で記録しないので、`zoxide query --list` は空
- `cd /tmp`・`cd /usr/share`・`cd ~` を別々の行で入れると、`/tmp` と `/usr/share` が記録された（行ごとにプロンプトが出る）
- ブラケットペースト有り: `cd` を別々の行に書いても、1 回の貼り付けは 1 つの入力として実行され、プロンプトは最後に 1 回しか出ないので空
- 手順 4 と手順 5 に分けて貼ると、手順 4 の後のプロンプトで `/usr/share` が記録された

##### zoxide: 未確認事項（dnf の経路）

- 実機（x86_64 の PC）での本実行
- aarch64（COPR に chroot が無い）
- `ZOXIDE_CMD=cd` の形
- COPR が次の版を出したときの `dnf upgrade`（検証の時点では 0.10.0 が最新）

---

#### zoxide: 付録: クリーン VM での検証記録（2026-10-06）

**検証対象**: `0dbb522` の、各手順で `~/.bashrc` などへ設定を直接追記する版。以下の手順番号と「本文」はこの版を指す。検証後に共通 bash 設定へ統一された現行版（`0bc9970`）の設定リポジトリの新規導入・既存設定からの移行は、今回の VM では実行していない。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証対象版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順（`0dbb522`）**: 実施手順 1〜5。

**結果**: Homebrew の zoxide 0.10.0 と fzf 0.74.4 を導入した。`~/.bashrc` に `--cmd z` の初期化を書いて読み込み、`z` が function になった。手順 4 の `cd /usr/share` の後は一度プロンプトに戻り、手順 5 でデータベースの `/usr/share` を確認した。

**今回の未確認範囲**: 別のコマンド名での初期化、更新・ロールバックは今回流していない。

#### zoxide: 付録: 現行の共通 bash 設定での再検証（2026-10-06）

- `5da3478` の 実施手順 1〜5を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で実行した。先に共通 bash `3d5323e` を新規導入した
- zoxide 0.10.0 と fzf 0.74.4 を bottle で導入した。読み直し後の z / zi は関数で、`cd /usr/share` の後に query の一覧へ /usr/share が記録された
- 任意の設定変更、更新、削除は、この再検証では実行していない

---

## 統合前の記録: fzf（もとは fzf.md）

もとの `fzf.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「シェルのツール」の手順 1 |
| 実施手順 2・3 | 「シェルのツール」の手順 5 |
| 実施手順 4〜7 | 「キー操作を試す」の手順 2〜5 |
| 使い方の基本 | fzf の使い方の基本 |
| fd と bat を候補とプレビューに使う（任意）の 1・2 | fzf で fd と bat を候補とプレビューに使う（任意）の 3・4（fd を入れる 1 と、開き直す 2 を足した） |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 4 |
| ロールバック 2 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 8 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### fzf: 補足

#### fzf: 実施手順: 検証状況の記録

> [!WARNING]
> **現行版 `5da3478` を、共通 bash 設定を新規導入した別の x86_64 VM でも再検証した**（末尾の再検証記録）。既存ホストの手動移行は今回は実行していない。
>
> **x86_64 のクリーン VM で検証対象版の実施手順を本実行済み**（2026-10-06）。コンテナでも検証したが、実機では本書の手順を通していない（[対象と検証環境](#fzf-対象と検証環境)）。VM のキーは SSH の PTY に、以前のコンテナでは tmux のペインに送って確かめたもので、GNOME 端末や WezTerm で Alt+C が届くかは確かめていない。

#### fzf: 使い方の基本 / 手順 0: 本文中の記録

- シェルのキーと環境変数、fzf の画面の中のキー、検索の書き方。どれもコンテナの fzf 0.74.4 で確かめた（[付録](#fzf-付録-コンテナでの検証記録2026-10-02)）

- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

#### fzf: 対象と検証環境

- **目的**: AlmaLinux 10 の bash に [fzf](https://github.com/junegunn/fzf)（一覧から曖昧検索で選ぶコマンド）のキー操作と補完を組み込み、履歴・パス・ディレクトリを打ちかけの文字から選べるようにする
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **`0dbb522` の直接追記版の実施手順 1〜7・fd と bat の任意節を x86_64 のクリーン VM で本実行済み（2026-10-06）。コンテナでも検証済み（2026-10-02）**。現行版 `5da3478` の共通 bash 新規導入後の再検証も、末尾に記録した。既存ホストの手動移行は今回は実行していない。
  - 通したこと: SSH でログインした対話の bash に、この文書の bash のブロックをそのまま貼り、実施手順・任意節・[更新](../almalinux-setup.md#更新)・[ロールバック](../extra/almalinux-setup.md#ロールバック)を、ブラケットペーストの無しと有りで 1 回ずつ通した（[付録](#fzf-付録-コンテナでの検証記録2026-10-02)）
  - 確認したこと
    - 手順 1〜3 の出力、手順 4〜7 のキー（tmux のペインに `C-r` / `C-t` / `M-c` / Tab を送って画面を読んだ）、[使い方の基本](../almalinux-setup.md#fzf-の使い方の基本)の表、任意節のプレビュー、[ロールバック](../extra/almalinux-setup.md#ロールバック)
    - `fzf --bash` が `PROMPT_COMMAND` などに触らないこと、非対話のシェルで何も出さないこと、2 回読んでも二重にならないこと
    - bash-completion の遅延読み込み（`git checko<Tab>`）と、[bash-settings.md 手順 4](../almalinux-setup.md#シェルのツール) の Homebrew の補完の行との並び
  - **確認していないこと**
    - 実機（aarch64 の Raspberry Pi 5、x86_64 の PC）、GNOME 端末・WezTerm から送る Alt+C
    - `kill -9 <Tab>` の fzf の一覧（コンテナでは fzf でなく通常の PID の一覧が出た。理由は追っていない）
    - Homebrew の版が上がる[更新](../almalinux-setup.md#更新)

| 項目 | 検証コンテナ |
|---|---|
| 実施日 | 2026-10-02 |
| OS | AlmaLinux 10.2 (Lavender Lion)（`quay.io/almalinuxorg/10-init`。パッケージは `x86_64_v2`） |
| コンテナ | クラウドのホストの Docker 29.6.2、`--privileged` と `--network host`。systemd を PID 1 にし、sshd と systemd-logind を動かした |
| bash | 5.2.26（BaseOS）。bash-completion 2.11-16（BaseOS）を入れた状態 |
| Homebrew | 7.0.7（`/home/linuxbrew/.linuxbrew`） |
| fzf | 0.74.4（Homebrew）。依存は `ncurses` |
| ほか | fd 10.5.0・bat 0.26.1・eza 0.23.5・zoxide 0.10.0・starship 1.26.0（Homebrew。任意節と補完の確認用） |
| 端末 | ホストの tmux 3.4 のペイン（160x45）から `docker exec -it` で `ssh -t` し、`TERM=xterm-256color` |

> [!NOTE]
> 出力例・ログの中の値は `<USER>` / `<HOSTNAME>` / `<PID>` のプレースホルダで書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### fzf: 実施前の状態

| 項目 | 状態 |
|---|---|
| fzf | 未導入（検証では、先に入れた fzf を `brew uninstall fzf` と `brew autoremove` で `ncurses` ごと消してから始めた） |
| Homebrew | 7.0.7 導入済み。fd・bat・eza・zoxide・starship が入っている |
| `~/.bashrc` | `brew shellenv` の行と、[bash-settings.md](../almalinux-setup.md) の 5 行 |

#### fzf: 選択した方針

- **Homebrew の 0.74.4 にした**（[導入元一覧](../tool-catalog.md)の規則。EPEL は 0.58.0）
  - `fzf --bash` は 0.48.0 からあるので EPEL の版でも同じ手順で動くはずだが、確かめていない。yazi・zoxide の依存ですでに Homebrew の fzf が入っているホストが多いので、揃える
- **`fzf --bash` で組み込む**: formula の caveat の案内で、fzf の `install` スクリプト（`~/.fzf.bash` と `~/.bashrc` への追記）は使わない。bash リポジトリの初期化がインストール済みの版に追従する
- **atuin は採らない**: 履歴を SQLite に持ち、別のホストと同期もできる履歴の検索ツール。Ctrl+R を取り合うので、どちらか 1 つにする。fzf は依存ですでに入っていて、履歴のほかにパスとディレクトリにも使えるので、こちらにした。atuin は[導入元一覧](../tool-catalog.md#cli-定番の置き換え)の行のまま（試していない）
- **ble.sh・mcfly も採らない**: ble.sh は行の編集そのものを置き換える大きなもの、mcfly は履歴だけ。どちらも RPM が無い。試していない
- **`kill` の補完は書かない**: コンテナでは fzf の一覧にならなかった（[対象と検証環境](#fzf-対象と検証環境)）

#### fzf: 完了時点の状態

実施手順の後:

```
$ tail -n 1 ~/.bashrc
eval "$(fzf --bash)"
$ bind -X
"\C-r": "__fzf_history__"
"\C-t": "fzf-file-widget"
$ complete -p cd vi ssh
complete -o nospace -F _fzf_dir_completion cd
complete -o bashdefault -o default -F _fzf_path_completion vi
complete -o bashdefault -o default -F _fzf_complete_ssh ssh
```

- 入るファイルは `/home/linuxbrew/.linuxbrew/Cellar/fzf/0.74.4/` の実行ファイル・man・`shell/` のスクリプトと、依存の `ncurses`
- 任意節を通すと、`~/.bashrc` に `export FZF_…` の 4 行が付く

#### fzf: 付録: コンテナでの検証記録（2026-10-02）

**環境**: [対象と検証環境](#fzf-対象と検証環境)の表のとおり。コンテナには NOPASSWD の sudo を持つ一般ユーザーを作り、root から `ssh -p 2222 <USER>@127.0.0.1` でログインした。準備（プロキシ・リポジトリ・Homebrew）は [bash-settings.md の付録](#bash-の設定-付録-コンテナでの検証記録2026-10-02)と同じ。

**先に調べたこと**（文書の内容を決めるため）:

- `fzf --bash` の出力（939 行）に `PROMPT_COMMAND` / `PS0` / `PS1` は無く、`if [[ $- =~ i ]]` が 2 か所。`bash -c 'eval "$(fzf --bash)"'` の出力は 0 バイト
- `brew deps fzf` は `ncurses`。`brew uses --installed fzf` は空（zoxide・yazi は formula の依存に fzf を持たない）
- `complete -p` は、読んだ直後に `cd` が `_fzf_dir_completion`、`cat` `vi` `git` が `_fzf_path_completion`、`ssh` が `_fzf_complete_ssh`、`kill` が `_fzf_proc_completion`。`git checko<Tab>` は `checkout` に補完され、その後の `complete -p git` に `-o nospace` が足されていた（bash-completion の遅延読み込みが `git` を読み、fzf がそれを包み直した）
- 検索の書き方の表は `printf '%s\n' apple banana cherry grape pineapple apple-pie | fzf -f '<書き方>'` の結果
- Homebrew の補完の行（bash-settings.md 手順 4）を fzf の後ろに読むと、`complete -p bat` が `_bat` に戻り `bat **<Tab>` が fzf にならなかった。前に読むと `_fzf_path_completion` のままで、`bat --the<Tab>` も `--theme` に補完された

**流し方**:

- ホストの tmux のペインで `docker exec -it … ssh -t` したログインシェルに、この文書の bash のブロック（折り畳みの外のもの）を抜き出して、手順ごとに `tmux paste-buffer` で書き込んだ（bash-settings.md を通した後の `~/.bashrc` から）
- 1 回目はブラケットペースト無しで、2 回目は `paste-buffer -p`（ブラケットペースト有り。貼った後に Enter を送った）で、実施手順から[ロールバック](../extra/almalinux-setup.md#ロールバック)まで通した。2 回の間に `brew uninstall fzf` と `brew autoremove` で実施前に戻した
- キーは `tmux send-keys` で `C-r` / `C-t` / `M-c` / Tab / Escape を送り、`capture-pane` で画面を読んだ

| 手順 | 結果（2 回とも同じ） |
|---|---|
| 1 | `Would install 1 formula: fzf 0.74.4`、`Would install 1 dependency for fzf: ncurses`、`[y/n]`。`y` で `ncurses 6.6` と `fzf 0.74.4` のボトルが入り、caveat に `To set up shell integration, see: https://github.com/junegunn/fzf#setting-up-shell-integration` |
| 2 | `0.74.4 (Homebrew)`、`/home/linuxbrew/.linuxbrew/bin/fzf`、`fzf 0.74.4` |
| 3 | `bind -X` に `"\C-r": "__fzf_history__"` と `"\C-t": "fzf-file-widget"`。`complete -p` に `_fzf_dir_completion cd`・`_fzf_path_completion vi`・`_fzf_complete_ssh ssh` |
| 4 | Ctrl+R で履歴の一覧（右上に `68/68 (0) +S`）。`fzf --v` で 5 件に絞られ、Enter で `brew list --versions fzf` がプロンプトに入った（実行されない）。もう一度 Enter で `fzf 0.74.4` |
| 5 | `cat ` の後の Ctrl+T でホームの下の一覧（1,222 件。`.cache/Homebrew/` の中も）。`bashrc` で `.bashrc` だけになり、Enter で `cat .bashrc`。Enter で中身が出た |
| 6 | `ls /usr/share/**` + Tab で 6,943 件。`doc/bash` で 24 件、Enter で `ls /usr/share/doc/bash-completion/`。`ssh **<Tab>` は `known_hosts` の 4 件、`export **<Tab>` は 32 の変数名 |
| 7 | Alt+C で 272 のディレクトリ（行には `` `__fzf_cd__` `` と表示される）。`proj-b` で 1 件、Enter で `builtin cd -- /home/<USER>/work/proj-b` と出てプロンプトが `proj-b` に。`cd -` でホーム |
| 任意節 1・2 | 4 行が読み戻された。Ctrl+T の一覧が 917 件（`fd` の結果。`.git` の中は無い）になり、右側に `bat` の行番号付きの中身が出た。`bashrc` で `.bashrc` に絞ると、プレビューも `.bashrc` の中身になった |
| 更新 | `Warning: fzf 0.74.4 already installed` |
| ロールバック 1〜3 | `grep -c` はどちらも `0`。`brew uninstall fzf` は `Uninstalling …/Cellar/fzf/0.74.4... (19 files, 6.0MB)` に続けて `==> Autoremoving 1 unneeded formula: ncurses` と出し、`ncurses` も消した。新しいシェルの `zi` は `zoxide: could not find fzf, is it installed?`、`bind -X` は何も出さず、`complete -p vi` は `no completion specification` |

##### fzf: 未確認事項

- 実機（aarch64 の Raspberry Pi 5、x86_64 の PC）での本実行
- GNOME 端末・WezTerm から送る Alt+C、Shift+Tab
- COPR の fzf（dnf の zoxide の PC）での `fzf --bash`
- `kill -9 <Tab>` が fzf の一覧にならなかった理由
- Homebrew の版が上がる `brew upgrade fzf`
- `**<Tab>` の候補を fd に変える `_fzf_compgen_path()`

---

#### fzf: 付録: クリーン VM での検証記録（2026-10-06）

**検証対象**: `0dbb522` の、各手順で `~/.bashrc` などへ設定を直接追記する版。以下の手順番号と「本文」はこの版を指す。検証後に共通 bash 設定へ統一された現行版（`0bc9970`）の設定リポジトリの新規導入・既存設定からの移行は、今回の VM では実行していない。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証対象版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順（`0dbb522`）**: 実施手順 1〜7、fd と bat を候補とプレビューに使う任意節の手順 1・2。

**結果**: zoxide の手順で入った fzf 0.74.4 は再導入不要だった。`~/.bashrc` に初期化を書き、`bind -X` と補完を読み戻した。Ctrl+R で `fzf --version` を選び、入力行への挿入と、再 Enter での実行を確認した。Ctrl+T で `.bashrc` を選び `cat`、`ls /usr/share/**` と Tab で `/usr/share/doc/bash/` を選んで `ls`、Alt+C で検証用ディレクトリへ移って `cd -` で戻った。任意節の 4 行も読み込み、Ctrl+T の候補が fd の一覧になって `.git` を除くことと、右側に bat の行番号付きプレビューが出ることを確認した。

**今回の未確認範囲**: GNOME 端末・WezTerm からのキー、更新・ロールバックは今回流していない。

#### fzf: 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜3 と「fd と bat」の任意節を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で共通 bash `3d5323e` の導入後に実行した。fzf 0.74.4、fd 10.4.2、bat 0.26.1 を使った
- SSH 対話 PTY にキーを送り、Ctrl+R で履歴の `fzf --version` を選んで実行、Ctrl+T でファイル候補と bat の本文プレビューを表示して選択、Alt+C で空白を含む `sub directory` へ移動した。共通設定の `FZF_*`、バインドと SSH ホスト候補の補完も確認した
- 実施手順 6 の `ls /usr/share/**<Tab>` も実キーで候補を開き、`doc/bash` へ絞って選択した。Enter の後に `/usr/share/doc/bash/` が入力行へ入った
- GUI 端末の物理キー、既存ホストの設定移行、更新・削除は今回は実行していない

#### fzf: 手順中の検証状況

- 端末が Alt を ESC の前置きとして送る設定のときに届く（tmux のペインでは `M-c` で届いた。GNOME 端末・WezTerm では確かめていない）

#### fzf: 実施手順 / 手順 1: 補足: 依存と、入れてあるホストで貼る意味

- fzf の依存は `ncurses` だけ（`brew deps fzf`）。コンテナで `brew install fzf fd bat eza zoxide starship` をまとめて入れたときは、fzf のボトルの前に `ncurses` が入った

- 入れてあるホストの出力:

```
Warning: fzf 0.74.4 is already installed and up-to-date.
To reinstall 0.74.4, run:
  brew reinstall fzf
```

---

## 統合前の記録: eza（もとは eza.md）

もとの `eza.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「共通の bash 設定」の手順 2 |
| 実施手順 2 | 「シェルのツール」の手順 1 |
| 実施手順 3 | 「シェルのツール」の手順 6 |
| エイリアスを足す（任意）の 1 | 「シェルのツール」の手順 6 |
| 表示を調整する | eza の表示を調整する |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 3 |
| ロールバック 2 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 8 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### eza: 補足

#### eza: 実施手順: 検証状況の記録

> [!WARNING]
> **現行版 `5da3478` を、共通 bash 設定を新規導入した別の x86_64 VM でも再検証した**（末尾の再検証記録）。既存ホストの手動移行は今回は実行していない。
>
> **x86_64 のクリーン VM で検証対象版の実施手順を本実行済み**（2026-10-06）。コンテナでも検証したが、実機では本実行していない（[対象と検証環境](#eza-対象と検証環境)）。

#### eza: 実施手順 / 手順 3: 補足: Git 列の読み方

`--git` は **git 管理下のディレクトリでしか列を出さない**。コンテナで使い捨てのリポジトリを作って確かめた実測:

```
$ eza -l --git --header .
Permissions Size User   Date Modified Git Name
.rw-r--r--@    8 <USER> 22 Sep 20:47   -M f.txt
$ eza -la --git --group-directories-first .
drwxr-xr-x@ - <USER> 22 Sep 20:47  -I .git
.rw-r--r--@ 8 <USER> 22 Sep 20:47  -M f.txt
```

- `Git` 列は 2 文字で、左がインデックスの状態、右が作業ツリーの状態
- `-M` は「インデックスは変更なし・作業ツリーで変更あり」、`-I` は ignore されているもの

git 管理下でない `/etc` では列自体が出ない:

```
$ eza -l --git /etc | head -3
.rw-r--r--@   16 root  2 Sep 10:54 adjtime
.rw-r--r--@   12 root 15 Jan 00:00 adjtime.rpmnew
.rw-r--r--@ 1.5k root 29 Nov  2023 aliases
```

パーミッション欄の末尾に付く `@` は拡張属性があることを示す（`-@` / `--extended` で中身が見られる）。SELinux を使う AlmaLinux では多くのファイルに付く。

#### eza: ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**

- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

#### eza: 対象と検証環境

- **目的**: AlmaLinux 10 に [eza](https://github.com/eza-community/eza)（`ls` の代わりになる一覧表示。git 連携・ツリー表示・色分けが付く）を入れる。**EPEL にも AppStream にも RPM が無い**
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **`0dbb522` の直接追記版の実施手順 1〜3 を x86_64 のクリーン VM で本実行済み（2026-10-06）。コンテナでも検証済み（2026-09-22）。実機には入れていない**。現行版 `5da3478` の共通 bash 新規導入後の再検証も、末尾に記録した。既存ホストの手動移行は今回は実行していない。
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**[Homebrew の導入](../almalinux-setup.md)と手順 2〜3 を通した
  - 確認したこと: `arm64_linux` のボトルが降りる、`v0.23.5 [+git]` が出る、git リポジトリで `Git` 列に `-M` / `-I` が付く
  - **確認していないこと**: 色分けの見え方とアイコン（`--icons`）。コンテナには端末が無いため
  - **実機（Raspberry Pi 5）では本実行していない**ので、下表の実機列は「この手順を適用した結果」ではなく**現時点の状態**を書いてある

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| eza | **未導入** | `eza 0.23.5`（`arm64_linux` ボトル） |
| 一緒に入る依存 | — | `libgit2` とその先 7 つ |
| Nerd Font | `font-symbols-only-nerd-font 3.5.1`（Homebrew、[yazi.md](../almalinux-setup.md#yazi)） | 無し |
| 端末 | WezTerm nightly（[wezterm-nightly.md](../almalinux-setup.md#wezterm)） | 無し（pty を与えずに実行） |

> [!NOTE]
> シェルのエイリアス・初期化は bash リポジトリの値を使う。本書で設定するシェル変数は無い。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### eza: 実施前の状態

| 項目 | 状態 |
|---|---|
| eza | 未導入 |
| Homebrew | 7.0.6 導入済み |
| EPEL | 有効。ただし `eza` も `exa` も無い |
| `ls` | `coreutils` の GNU `ls`（RPM）。置き換えない |

#### eza: 選択した方針

AlmaLinux 10 aarch64 で eza を入れる経路を比べた（2026-09-22 時点）:

コンテナで取った RPM 側の実測:

- この 1 回の実行で、eza / exa / delta / git-delta / starship のどれも無いことを確かめている
- [git-delta.md](../almalinux-setup.md#git-delta) と [starship.md](../almalinux-setup.md) でも同じ出力を使っている

#### eza: 完了時点の状態

**検証コンテナでの出力**（実機では本実行していない）:

```
$ eza --version
eza - A modern, maintained replacement for ls
v0.23.5 [+git]
https://github.com/eza-community/eza
$ brew list --versions eza
eza 0.23.5
$ command -v eza
/home/linuxbrew/.linuxbrew/bin/eza
$ alias ll la lt
alias ll='eza -l --git --group-directories-first'
alias la='eza -la --git --group-directories-first'
alias lt='eza --tree --level=2'
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/eza/0.23.5/`（15 ファイル、2.0 MB）。man ページ（`share/man/man1/eza.1`）とシェル補完も同梱される。

#### eza: 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](../almalinux-setup.md)と手順 2〜3、[エイリアスを足す（任意）](../almalinux-setup.md#実施手順)を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。[bat](../almalinux-setup.md) を先に入れた同じコンテナなので、依存の `libgit2` は取得済みだった。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](../almalinux-setup.md)） |
| 2. eza | `Pouring eza--0.23.5.arm64_linux.bottle.tar.gz` → `15 files, 2MB`。**依存は取得されなかった**（`libgit2` は bat で導入済みのため）。単独で入れた場合の依存は `brew deps --tree eza` で `libgit2` とその先 7 つ |
| 3. 検証 | `eza --version` → `v0.23.5 [+git]`。`eza -l --git --header` で `Git` 列が出て、変更ファイルに `-M`、`.git` に `-I` が付いた。`/etc`（git 管理外）では `Git` 列が出ないことも確認 |
| エイリアス | `~/.bashrc` に 3 行追記して読み込み直し、`alias ll la lt` で 3 つとも展開されることを確認。**`type -t ll` は非対話シェルでは失敗する**ことも確認した |
| 表示オプション | `--header` / `--octal-permissions` / `--tree --level=2` / `--icons=always` が動作。`EZA_COLORS=... eza -l --color=always` もエラーなく実行できたが、**色の正しさは判定していない** |
| RPM 経路 | `dnf list --available eza exa` → `Error: No matching Packages to list`（EPEL を有効にした状態で） |

##### eza: 未確認事項

- 実機での本実行（本書は実機に適用していない。検証はコンテナのみ）
- 端末での色分けの見え方（`LS_COLORS` / `EZA_COLORS` の効き方）
- アイコン表示（`--icons=always` と Nerd Font の組み合わせ）
- `--git-repos` / `--git-repos-no-status`、`--loc`、`--total-size` などの重い機能
- 大きなリポジトリでの `--git` の速度
- ロールバック（`brew uninstall` と `~/.bashrc` の行削除）の本実行

---

#### eza: 付録: クリーン VM での検証記録（2026-10-06）

**検証対象**: `0dbb522` の、各手順で `~/.bashrc` などへ設定を直接追記する版。以下の手順番号と「本文」はこの版を指す。検証後に共通 bash 設定へ統一された現行版（`0bc9970`）の設定リポジトリの新規導入・既存設定からの移行は、今回の VM では実行していない。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証対象版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順（`0dbb522`）**: 実施手順 1〜3。

**結果**: Homebrew の eza 0.23.5 を導入し、パスと版、検証用 Git リポジトリの一覧を確認した。変更したファイルの Git 列は `-M` だった。

**今回の未確認範囲**: エイリアス・アイコン、更新・ロールバックは今回流していない。

#### eza: 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜3 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で実行した。先に共通 bash `3d5323e` を新規導入した
- eza 0.23.5 の bottle・版・PATH を確認し、共通設定の `ll` / `la` / `lt` を読み直した。使い捨ての Git リポジトリで `ll` の変更記号 `-M`、隠しファイル一覧と深さ 2 の木を確認した
- 更新・削除、任意の色設定、既存ホストの設定移行は今回は実行していない

#### eza: 選択した方針

```
$ dnf list --available eza exa delta git-delta starship
Last metadata expiration check: 0:00:08 ago on Tue Sep 22 20:46:27 2026.
Error: No matching Packages to list
```

#### eza: 手順内の実測・検証状況

- 実機には `font-symbols-only-nerd-font` が入っている（[yazi.md](../almalinux-setup.md#yazi)）が、本書では見え方を確認していない

---

## 統合前の記録: bat（もとは bat.md）

もとの `bat.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1（変数） | bat の設定ファイルの 1 |
| 実施手順 2 | 「シェルのツール」の手順 1 |
| 実施手順 3 | 「シェルのツール」の手順 7 |
| ページャに使う（任意）の 1 | 「シェルのツール」の手順 7 |
| ページャに使う（任意）の 2 | fzf で fd と bat を候補とプレビューに使う（任意）の 4 の箇条書き |
| 設定ファイルの 1 | bat の設定ファイルの 1 |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 3 |
| ロールバック 2 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 5 |
| ロールバック 3 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 8 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### bat: 補足

#### bat: 操作上の注意と併記されていた記録

- `MANPAGER` は端末が要る。2026-10-06 の新規 VM の SSH 対話 PTY で `man bash` の表示と `q` での終了を確認した（末尾の再検証記録）。`fzf` のプレビューも Ctrl+T の実操作で確認した

#### bat: 実施手順: 検証状況の記録

> [!WARNING]
> **現行版 `5da3478` は、共通 bash を新規導入した別の x86_64 VM でも再検証した**（末尾の再検証記録）。既存ホストの手動移行は実行していない。
>
> **x86_64 のクリーン VM で検証対象版の実施手順を本実行済み**（2026-10-06）。コンテナでも検証したが、実機では本実行していない（[対象と検証環境](#bat-対象と検証環境)）。

#### bat: 実施手順 / 手順 3: 補足: TTY かどうかで出力が変わる

bat は出力先が端末かどうかで既定の挙動を変える。**パイプやリダイレクトに繋ぐと、色も行番号もページャも自動的に切れて素の `cat` と同じになる**。コンテナ（端末なし）での実測:

```
$ bat /etc/os-release | head -3
NAME="AlmaLinux"
VERSION="10.2 (Lavender Lion)"
RELEASE_TYPE=stable
$ bat --color=always --style=numbers /etc/os-release | head -2
   1 NAME="AlmaLinux"
   2 VERSION="10.2 (Lavender Lion)"
```

- この切り替えのおかげで、`bat` をスクリプトの中で `cat` の代わりに使っても壊れにくい
- 強制したいときは `--color=always` と `--paging=never`（または `-p`）を明示する

#### bat: ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**

- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

#### bat: 対象と検証環境

- **目的**: AlmaLinux 10 に [bat](https://github.com/sharkdp/bat)（シンタックスハイライトと git 連携が付いた `cat`）の最新版を入れる。**EPEL には 0.24.0 があるが 2 マイナー古い**
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **`0dbb522` の直接追記版の実施手順 1〜3 を x86_64 のクリーン VM で本実行済み（2026-10-06）。コンテナでも検証済み（2026-09-22）。実機には入れていない**。現行版 `5da3478` は、共通 bash 新規導入後の別の VM でも再検証した（末尾の再検証記録）。既存ホストの手動移行は行っていない。
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**[Homebrew の導入](../almalinux-setup.md)と手順 2〜3、[設定ファイル](../almalinux-setup.md#bat-の設定ファイル)の節を通した
  - 確認したこと: `arm64_linux` のボトルが降りる、`bat 0.26.1` が入る、`--color=always --style=numbers` で行番号と色が付く
  - fzf の Ctrl+T の bat プレビューは 2026-10-06 のクリーン VM で確認した（[fzf.md の付録](#fzf-付録-クリーン-vm-での検証記録2026-10-06)）。共通 bash の man ページャも別の新規 VM の実 PTY で表示・終了を確認し、SGR の断片が出る旧パイプを直接 bat の形へ修正した（末尾の再検証記録）
  - **実機（Raspberry Pi 5）では本実行していない**ので、下表の実機列は「この手順を適用した結果」ではなく**現時点の状態**を書いてある
  - 2026-10-02: [設定ファイル](../almalinux-setup.md#bat-の設定ファイル)の手順 1 を、`BAT_THEME_NAME` が空なら何もせずに止める `if … fi` にした
    - それまでは、ヒアドキュメントの中の `${BAT_THEME_NAME:?…}` が `cat` しか止めず（[gnome-power.md 手順 3](../almalinux-setup.md#画面オフ画面ロック自動サスペンドを止める任意) の補足）、先に効く `>` が既にある設定ファイルを空にし、後ろの `bat --config-file` も動いた
    - 直した形は、擬似端末の対話の bash にブラケットペースト無しで、変数を空にしたときと値を入れたときの 1 回ずつ貼って確かめた（`HOME` は使い捨てのディレクトリ、`bat` はスタブ）

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| bat | **未導入**（EPEL の `bat 0.24.0-13.el10_2` も入れていない） | `bat 0.26.1`（`arm64_linux` ボトル） |
| 一緒に入る依存 | — | `libgit2` / `oniguruma` とその先 7 つ |
| 端末 | WezTerm nightly（[wezterm-nightly.md](../almalinux-setup.md#wezterm)） | 無し（pty を与えずに実行） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../almalinux-setup.md#bat-の設定ファイル) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${BAT_THEME_NAME}` | 設定ファイルに書く `--theme` の値 | `ansi`（既定）/ `Nord` / `Dracula` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`0.26.1`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### bat: 実施前の状態

| 項目 | 状態 |
|---|---|
| bat | 未導入（Homebrew・EPEL とも） |
| Homebrew | 7.0.6 導入済み |
| EPEL | 有効（`epel-release 10-8.el10_2`）。`bat 0.24.0-13.el10_2` が入手できる状態 |
| 関連ツール | `fzf 0.74.4` / `ripgrep 15.2.0` / `fd 10.5.0` が Homebrew で導入済み（[yazi.md](../almalinux-setup.md#yazi)） |

#### bat: 選択した方針

AlmaLinux 10 aarch64 で bat を入れる経路を比べた（2026-09-22 時点）:

コンテナで取った EPEL 側の実測:

#### bat: 完了時点の状態

**検証コンテナでの出力**（実機では本実行していない）:

```
$ bat --version
bat 0.26.1
$ brew list --versions bat
bat 0.26.1
$ command -v bat
/home/linuxbrew/.linuxbrew/bin/bat
$ bat --config-file
/home/<USER>/.config/bat/config
$ bat --config-dir
/home/<USER>/.config/bat
$ bat --cache-dir
/home/<USER>/.cache/bat
$ cat ~/.config/bat/config
--theme="ansi"
--style="numbers,changes,header"
--paging=never
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/bat/0.26.1/`（15 ファイル、5.4 MB）。

#### bat: 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](../almalinux-setup.md)と手順 2〜3、[設定ファイル](../almalinux-setup.md#bat-の設定ファイル)の節を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。同じコンテナで [eza](../almalinux-setup.md) / [git-delta](../almalinux-setup.md#git-delta) / [gdu](../gdu.md) / [starship](../almalinux-setup.md) も続けて入れている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](../almalinux-setup.md)） |
| 2. bat | `Pouring bat--0.26.1.arm64_linux.bottle.tar.gz` → `15 files, 5.4MB`。依存 9 つ（`ca-certificates` / `openssl@3` / `zlib-ng-compat` / `libssh2` / `llhttp` / `bzip2` / `pcre2` / `libgit2` / `oniguruma`）もすべてボトル。ソースビルドは発生しない |
| 3. 検証 | `bat --version` → `bat 0.26.1`。`bat --color=always --style=numbers /etc/os-release` は行番号と ANSI エスケープ付きで出た。`--color` を外してパイプに繋ぐと素の出力になることも確認 |
| 設定ファイル | `~/.config/bat/config` を置いて `bat --config-file` が同じパスを返し、`--style=numbers` が効くことを確認 |
| `MANPAGER` | **確認できず**。コンテナに `man ls` のページが無く（`coreutils-common` 未導入）、`man-db` を入れて `man man` を試しても**パイプ越しでは man 自体がページャを呼ばない**ため、色が付くかは判定できなかった |
| RPM 経路 | `dnf -q list --showduplicates bat` → `0.24.0-13.el10_2 epel`。`dnf -q repoquery -l bat \| grep bin/` → `/usr/bin/bat` |

##### bat: 未確認事項

- 実機での本実行（本書は実機に適用していない）
- 端末での実際の見え方（テーマ、true color、ページャ `less` の起動）
- `MANPAGER` を設定した `man` の表示
- `bat cache --build`（自前のシンタックス・テーマの追加）
- EPEL 版（0.24.0）と併用した場合の挙動
- ロールバック（`brew uninstall` と `~/.config/bat` の削除）の本実行

---

#### bat: 付録: クリーン VM での検証記録（2026-10-06）

**検証対象**: `0dbb522` の、各手順で `~/.bashrc` などへ設定を直接追記する版。以下の手順番号と「本文」はこの版を指す。検証後に共通 bash 設定へ統一された現行版（`0bc9970`）の設定リポジトリの新規導入・既存設定からの移行は、今回の VM では実行していない。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証対象版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順（`0dbb522`）**: 実施手順 1〜3。

**結果**: Homebrew の bat 0.26.1 を導入し、パスと版、`/etc/os-release` の行番号・ANSI 色指定付き出力を確認した。

**今回の未確認範囲**: 設定ファイル・エイリアス・ページャ、更新・ロールバックは今回流していない。

#### bat: 付録: 現行の共通 bash 設定での再検証（2026-10-06）

- `5da3478` の 実施手順 1〜3 と「ページャに使う」手順 1を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で実行した。先に共通 bash `3d5323e` を新規導入した
- bat 0.26.1 の bottle・版・PATH と `/etc/os-release` の先頭 5 行の表示を確認した。共通設定の読み直しで `MANPAGER` は文書どおりになった
- 実 PTY の `man bash` では、共通 bash `3d5323e` の旧 `col -bx` パイプが SGR の断片を `1mNAME0m` 等の文字として出した。共通 bash と本文を `MANPAGER="bat -plman"` に修正し、見出し・本文が正常に表示され、`q` で終了することを確認した。旧パイプに `MANROFFOPT=-c` を付ける比較も通ったが、追加変数の要らない直接 bat を採用した
- 更新、削除、テーマ用設定ファイルの任意節は、この再検証では実行していない

#### bat: 実施手順 / 手順 2: 補足: ボトルと、一緒に入る依存

aarch64 で降ってくるボトルは `bat--0.26.1.arm64_linux.bottle.tar.gz`。

bat が直接要求するのは `libgit2`（変更行の `changes` 表示に使う）と `oniguruma`（正規表現）の 2 つだが、`libgit2` がさらに 6 つを引く。コンテナでの `brew deps --tree bat`:

```
bat
├── libgit2
│   ├── libssh2
│   │   ├── openssl@3
│   │   │   └── ca-certificates
│   │   └── zlib-ng-compat
│   ├── llhttp
│   ├── openssl@3
│   │   └── ca-certificates
│   ├── pcre2
│   │   ├── zlib-ng-compat
│   │   └── bzip2
│   └── zlib-ng-compat
└── oniguruma
```

この依存は [eza](../almalinux-setup.md)（`libgit2`）と [git-delta](../almalinux-setup.md#git-delta)（`libgit2` / `oniguruma`）と共通なので、3 つとも入れる場合は 2 本目以降の取得がほとんど無くなる。

#### bat: 選択した方針

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `bat 0.26.1` の `arm64_linux` ボトルがある。upstream の最新と一致 | **採用** |
| EPEL | `bat.aarch64 0.24.0-13.el10_2`。実行ファイルは `/usr/bin/bat`（Debian 系と違って `batcat` にはならない）。root でも使え `dnf upgrade` に乗るが、**2 マイナー古い** | 不採用（[neovim.md](../almalinux-setup.md#neovim) と同じ判断） |
| 公式のバイナリ配布 | GitHub Releases に `aarch64-unknown-linux-gnu` / `musl` のビルドがある。展開して PATH に置くだけだが、更新は手作業 | 不採用（Homebrew に揃える） |
| `cargo install bat` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

```
$ dnf -q list --showduplicates bat
Available Packages
bat.aarch64                        0.24.0-13.el10_2                         epel
$ dnf -q repoquery -l bat | grep bin/
/usr/bin/bat
```

**名前が `bat` で衝突するので、EPEL 版と Homebrew 版を両方入れてはいけない。**

- 両方入っていると、PATH の先頭にある Homebrew 版が勝つ
- `dnf upgrade` で上がるのは、使われないほうになる

---

## 統合前の記録: tmux（もとは tmux.md）

もとの `tmux.md` の検証記録を、内容を変えずに移したもの。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「シェルのツール」の手順 1 |
| 実施手順 2 | 「シェルのツール」の手順 8 |
| 実施手順 3〜5 | 「tmux を試す」の手順 1〜3 |
| 使い方の基本 | tmux の使い方の基本 |
| 設定ファイル（任意）の 1・2 | tmux の設定ファイル（任意）の 1・2 |
| Claude Code を tmux の中で動かす（任意）の 1〜8 | 同じ節の 1〜8 |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 1 |
| ロールバック 2 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 3 |
| ロールバック 3 | ロールバックの「シェルのツールと bash の設定を戻す」の手順 5 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### tmux: 補足

#### tmux: 操作上の注意と併記されていた記録

   - この節の手順 4 は、tmux の中で確認した作業ディレクトリの名前を Remote Control のセッション名にする

#### tmux: 操作上の注意と併記されていた記録

   - 前の版のサーバーへ新しい版のクライアントからつなぐと、つなげないことがある（[手順 2](../almalinux-setup.md#シェルのツール) の補足の BaseOS の tmux と同じ。Homebrew の版が上がる更新は試していない）

#### tmux: 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 のクリーン VM で実施手順を本実行済み**（2026-10-06）。コンテナでも検証したが、実機では本書の手順を通していない（[対象と検証環境](#tmux-対象と検証環境)）。[Claude Code を tmux の中で動かす（任意）](../almalinux-setup.md#claude-code-を-tmux-の中で動かす任意)の Remote Control の接続は、確かめていない。

#### tmux: 実施手順 / 手順 2: 補足: BaseOS の tmux と並べたとき

BaseOS の `tmux-3.3a-13.20230918gitb202a2f.el10` を一緒に入れて試した（コンテナ）。

- `/usr/bin/tmux -V` は `tmux next-3.4` と出る（RPM の版は 3.3a だが、中身は 3.4 の前の git の版）
- PATH では `/home/linuxbrew/.linuxbrew/bin` が先なので、`tmux` と打つと Homebrew の 3.7c が動く。`/usr/bin/tmux` と打てば BaseOS のものが動く
- 2 つは同じソケット（`/tmp/tmux-<UID>/default`）を使う。版の違うクライアントとサーバーは、うまくつながらなかった

| サーバー（セッションを始めた方） | クライアント | 結果 |
|---|---|---|
| BaseOS（3.3a） | Homebrew（3.7c） | `tmux ls` は動くが、`tmux attach` は `open terminal failed: not a terminal` |
| Homebrew（3.7c） | BaseOS（3.3a） | `ls` も `attach` も `server exited unexpectedly`（サーバーは止まらずに残った） |

- BaseOS のサーバーのセッションを閉じるときは、`/usr/bin/tmux attach` で入って中で `exit` する（全部閉じてよければ `/usr/bin/tmux kill-server`）
- BaseOS の tmux は、`/usr/bin/tmux capture-pane -p` でサーバーごと落ちた（`server exited unexpectedly`。[podman-tui.md の付録](podman-tui.md#付録-コンテナでの検証記録2026-09-28)の実機の記録と同じ）。Homebrew の 3.7c では落ちなかった

#### tmux: 使い方の基本 / 手順 0: 本文中の記録

- 表のキーとコマンドは、コンテナの tmux 3.7c で確かめた（[付録](#tmux-付録-コンテナでの検証記録2026-10-01)）

#### tmux: Claude Code を tmux の中で動かす（任意）: 検証状況の記録

> [!WARNING]
> **この節の Remote Control の接続は確かめていない**。コンテナでは claude.ai にログインできず、`claude remote-control` が `You must be logged in to use Remote Control.` で終わるところまでを確かめた（`--name` と `--spawn same-dir` での接続は、[Windows の実機](windows-claude-remote-control.md#対象と検証環境)でだけ確かめてある）。Remote Control をつなぐと、この claude.ai のアカウントで入れる人が、スマートフォンやブラウザからこのホストで、このユーザーとして Claude Code を動かせる（ファイルの読み書きとコマンドの実行）。

#### tmux: Claude Code を tmux の中で動かす（任意） / 手順 4: 補足: tmux の中のシェルで始める理由

- `tmux new-session -s claude claude remote-control …` のように、tmux に直接 `claude` を起動させると、`claude` が終わった時点でセッションも消える。コンテナ（未ログイン）では `[exited]` だけが出て、エラーの文が読めなかった
- tmux の中のシェルから起動すれば、`claude` が終わってもシェルとその表示が残り、`tmux attach -t claude` で理由を読める
- `--spawn same-dir` を付けないと、`Choose [1/2]`（`same-dir` か `worktree` か）を聞かれる（Windows の実機の実測）。本書は Windows の手順書と同じ `same-dir`（1 つのディレクトリを共有）にする
- 信頼のダイアログ・`Enable Remote Control?`・URL の表示は、Windows の実機の記録（[Windows の手順書](../windows-claude-remote-control.md#実施手順)の手順 4）。この手順書では見ていない
- セッション名を `claude` にしたのは、ステータス行の左端が既定で 10 文字までのため（`claude-rc` は `[claude-rc` で切れた）
- 対話の `claude` の中で `/remote-control` と打っても、そのセッションを Remote Control につなげる（公式ドキュメント。本書では試していない）

#### tmux: 対象と検証環境

- **目的**: AlmaLinux 10 に [tmux](https://github.com/tmux/tmux)（端末の多重化。1 つの端末の中に複数のシェルを持ち、SSH を切ってもシェルとその中のコマンドを動かし続ける）を入れ、基本の使い方と、Claude Code を SSH の切断後も動かし続ける使い方をまとめる
- **進め方**: Homebrew で入れる。**読者が書き換える変数は無い**
- **状態**: **x86_64 のクリーン VM で実施手順 1〜5 と任意設定を本実行済み（2026-10-06）。コンテナでも検証済み（2026-10-01）**
  - 通したこと: SSH でログインした対話の bash に、この文書の bash のブロックをそのまま貼り、実施手順・任意節・[更新](../almalinux-setup.md#更新)・[ロールバック](../extra/almalinux-setup.md#ロールバック)を、ブラケットペーストの無しと有りで 1 回ずつ通した（[付録](#tmux-付録-コンテナでの検証記録2026-10-01)）
  - 確認したこと
    - 実施手順 1〜5、[使い方の基本](../almalinux-setup.md#tmux-の使い方の基本)の表のキーとコマンド、[設定ファイル（任意）](../almalinux-setup.md#tmux-の設定ファイル任意)（ホイール・クリック・境界のドラッグは、マウスの信号を端末に送って確かめた）、[ロールバック](../extra/almalinux-setup.md#ロールバック)
    - SSH のクライアントを落としても tmux のセッションとその中のコマンドが残り、ログインし直して戻れること
    - BaseOS の tmux と並べたときの挙動（[手順 2](../almalinux-setup.md#シェルのツール) の補足）
    - [Claude Code を tmux の中で動かす（任意）](../almalinux-setup.md#claude-code-を-tmux-の中で動かす任意)のうち、ログインしていない `claude` で通るところ（その節の手順 1〜3・5、手順 4 のエラー。手順 4 の代わりに対話の `claude` を動かして、手順 6 で SSH を切った後も残り、手順 8 で戻れること）
  - **確認していないこと**
    - 実機（aarch64 の Raspberry Pi 5 を含む）
    - Remote Control の接続と、スマートフォン・ブラウザからの操作（claude.ai のアカウントでのログインが要る）
    - 端末（WezTerm など）から送るマウスと Shift+Enter、[更新](../almalinux-setup.md#更新)で Homebrew の版が上がるとき
  - 実機の Raspberry Pi 5 では、tmux の中で `claude remote-control` を動かしている（[claude-code-gui.md の付録](claude-code-gui.md#付録-実機での検証記録2026-10-01)）。この手順書の手順どおりには通しておらず、その tmux が BaseOS と Homebrew のどちらかも確かめていない
  - 2026-10-05: 設定の読み込みを両パスに対応させ、確認用セッションの作成に失敗した場合は後続を止めた。一時ファイルとスタブで、旧パスのみ・新パスのみ・両方・作成失敗の 4 通りを確認した
  - 同日の変更で、`-A` で既存セッションへ戻る場合は作業場所と実行中コマンドを確認する説明を追加した。変更後の TUI と Remote Control は実機で実行していない

| 項目 | 検証コンテナ |
|---|---|
| 実施日 | 2026-10-01 |
| OS | AlmaLinux 10.2 (Lavender Lion)（`quay.io/almalinuxorg/10-init`。パッケージは `x86_64_v2`） |
| コンテナ | クラウドのホストの Docker 29.6.2、`--privileged`。systemd を PID 1 にし、sshd と systemd-logind を動かした |
| Homebrew | 7.0.7（`/home/linuxbrew/.linuxbrew`） |
| tmux | 3.7c（Homebrew）。比べるために BaseOS の `tmux-3.3a-13.20230918gitb202a2f.el10` も入れて消した |
| Claude Code | `claude-code-2.1.287-1`（[claude-code.md](../almalinux-setup.md#claude-code) の `latest`）。ログインしていない |
| 端末 | ホストの tmux 3.4 のペイン（160x45）から `docker exec -it` で `ssh -t` し、`TERM=xterm-256color` |

> [!NOTE]
> 出力例・ログの中の値は `<USER>` / `<HOSTNAME>` / `<UID>` / `<PID>` / `<名前>`（tmux のセッションや Remote Control のセッションの名前）/ `<PROJECT_DIR>` / `<SESSION_ID>` のプレースホルダで書いてある。Claude のアカウント、Remote Control の URL と QR コードは載せない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### tmux: 実施前の状態

| 項目 | 状態 |
|---|---|
| tmux | 未導入（`rpm -q tmux` も `brew list tmux` も無し） |
| Homebrew | 7.0.7 導入済み。formula は無し |
| systemd-logind | `KillUserProcesses` は既定のまま（`no`） |

#### tmux: 選択した方針

- **Homebrew の 3.7c にした**（[導入元一覧](../tool-catalog.md)の規則。RPM が Homebrew より古いので Homebrew）
  - BaseOS の RPM は 3.3a（中身は `next-3.4`）。`capture-pane -p` でサーバーが落ちるのを、実機（[podman-tui.md の付録](podman-tui.md#付録-コンテナでの検証記録2026-09-28)）とコンテナの両方で見た
  - Homebrew で入れると、そのままでは `sudo tmux` では見えないが、tmux は自分のユーザーで使うものなので困らない
- **screen は使わない**: AlmaLinux 10 の BaseOS・AppStream に無い（コンテナの `dnf list --available screen` は `No matching Packages`）。EPEL は調べていない
- **zellij は手順書にしない**: [導入元一覧](../tool-catalog.md#cli-定番の置き換え)の 1 行のまま。Windows では zellij のペインで Claude Code が動かなかった（[Windows の手順書の選択した方針](windows-claude-remote-control.md#選択した方針)）。Linux では試していない
- **Claude Code の Remote Control は、tmux の中のシェルから始める**: tmux に直接起動させると、終わったときに表示が残らない（[Claude Code を tmux の中で動かす（任意）](../almalinux-setup.md#claude-code-を-tmux-の中で動かす任意)の手順 4 の補足）
- **Claude Code 自身の裏で動かす機能は試していない**: `claude --help` には、セッションを裏で始める `--bg` と、それに入る `claude attach` がある。SSH の切断後も残るかは確かめていない

#### tmux: 完了時点の状態

実施手順の後（セッションは残っていない）:

```
$ tmux -V
tmux 3.7c
$ command -v tmux
/home/linuxbrew/.linuxbrew/bin/tmux
$ brew list --versions tmux
tmux 3.7c
$ tmux ls
no server running on /tmp/tmux-<UID>/default
```

- 入るファイルは `/home/linuxbrew/.linuxbrew/Cellar/tmux/3.7c/` の 9 ファイル（実行ファイル・man・`example_tmux.conf` など）と依存の 5 つ
- [設定ファイル（任意）](../almalinux-setup.md#tmux-の設定ファイル任意)を通すと `~/.config/tmux/tmux.conf` ができる
- tmux のソケットは `/tmp/tmux-<UID>/default`

#### tmux: 操作上の注意と併記されていた記録

- **Claude Code の `Ctrl+B` は、tmux の中では 2 回押す**: Claude Code は `Ctrl+B` で動いているコマンドを裏へ回すが、tmux の中では 1 回目を tmux が取る（公式ドキュメント）。`Ctrl+b` → `Ctrl+b` で中のアプリに `Ctrl+b` が届くことは、tmux の側で確かめた（`bind-key -T prefix C-b send-prefix`）

#### tmux: 付録: コンテナでの検証記録（2026-10-01）

**環境**: [対象と検証環境](#tmux-対象と検証環境)の表のとおり。コンテナには NOPASSWD の sudo を持つ一般ユーザーを作り、root から `ssh -p 2222 <USER>@127.0.0.1` でログインした（systemd-logind は、イメージで mask されていたのを外して起動した）。

**検証の準備**（本書の手順には含めない）:

- このホストの外向きの HTTPS はプロキシを通るので、プロキシの CA を `/etc/pki/ca-trust/source/anchors/` に置き、`/etc/dnf/dnf.conf` の `proxy=` と、ログインシェルの `HTTPS_PROXY` などを足した
- AlmaLinux の `mirrorlist=` を止めて、コメントの `baseurl=https://repo.almalinux.org/...` を有効にした（[claude-code.md の付録](#claude-code-付録-latest-チャンネルの検証記録2026-09-26)と同じ）
- Homebrew は `NONINTERACTIVE=1` 付きの公式インストーラで入れた（[homebrew.md](../almalinux-setup.md)）

**流し方**:

- ホストの tmux のペインで `docker exec -it … ssh -t` したログインシェルに、この文書の bash のブロック（折り畳みの外のもの）を抜き出して、手順ごとに `tmux paste-buffer` で書き込んだ（npm-offline.md の付録と同じ形）
- 1 回目はブラケットペースト無しで、2 回目は `paste-buffer -p`（ブラケットペースト有り。貼った後に Enter を送った）で、実施手順から[ロールバック](../extra/almalinux-setup.md#ロールバック)まで通した。2 回の間に、1 回目で見つけたことを直した（下の表）
- 画面は `tmux capture-pane` で読み、`y`・`Ctrl+b d`・`exit` はキーとして送った
- 中の tmux の状態は、`tmux list-windows` / `list-panes` / `show -g` を同じユーザーで別に呼んで読んだ
- 表の「設定ファイル」と「Claude Code」は、[設定ファイル（任意）](../almalinux-setup.md#tmux-の設定ファイル任意)と[Claude Code を tmux の中で動かす（任意）](../almalinux-setup.md#claude-code-を-tmux-の中で動かす任意)の手順

| 手順 | 結果（2 回とも同じ。違ったものは書き分けた） |
|---|---|
| 1 | `Would install 5 dependencies for tmux` の後に `[y/n]`。`y` で 6 つのボトルが入り、caveat が出た |
| 2 | `tmux 3.7c`、`/home/linuxbrew/.linuxbrew/bin/tmux`、`tmux 3.7c`、`package tmux is not installed` |
| 3 | ステータス行に `[work] 0:bash*`。`Ctrl+b d` で `[detached (from session work)]` |
| 4 | `work: 1 windows (created …)`。`attach` で戻り、`exit` で `[exited]` |
| 5 | `no server running on /tmp/tmux-<UID>/default` |
| 設定ファイル 1・2 | 4 行が出た。`mouse on`、`history-limit 50000`。設定ファイルがあるときにもう一度貼ると `中断:` が出た |
| Claude Code 1 | `2.1.287 (Claude Code)`、`tmux 3.7c`、`Not logged in. Run claude auth login to authenticate.`。直す前は `claude auth status --text` が 2 行目で、1 回目は後ろの `tmux -V` が実行されなかった（この手順の補足） |
| Claude Code 2・3・4 | `cd` の後、`[claude] 0:bash*` で、プロンプトは手順 2 のディレクトリ。`claude remote-control` は `Error: You must be logged in to use Remote Control.` で終わり、tmux の中のシェルに戻った。`exit` で `[exited]` |
| Claude Code 3・5（1 回目、もう一度） | 手順 4 の代わりに対話の `claude` を起動してデタッチした。`claude: 1 windows (created …)`。`pgrep -af 'claude remote-control'` は何も出さなかった（Remote Control は動いていない） |
| Claude Code 6・8（1 回目） | `exit` で SSH が切れた後も、tmux と `claude` のプロセスは残った。ログインし直して `tmux attach -t claude` で `claude` の画面に戻った。最初の設定の画面は `Ctrl+C` では終わらなかったので、ロールバックの手順 1 で止めた |
| 更新 | `Warning: tmux 3.7c already installed`（上がる版が無かった） |
| ロールバック | `kill-server` は何も出さないか、`no server running on …`。`brew uninstall tmux` が依存の 5 つも消し（`Autoremoving 5 unneeded formulae:`）、`openssl@3` と `ca-certificates` の設定ファイルを残したという警告が出た。直す前は `brew autoremove` も並べていたが、消すものが残っていなかった。`hash -r` の後の `command -v tmux` は何も返さなかった |

**追加の確認**（手順書の外）:

- 使い方の基本のキー: `Ctrl+b` の後の `c`・`p`・`n`・`0`・`%`・`"`・`o`・`←`・`z`（2 回）・`x`→`y`・`[`→`q` を送るたびに、ウィンドウとペインの数・大きさ・選ばれているものが表のとおりに変わった。`w`・`s`・`?` の一覧、`$`・`,` の名前の変更、`:` で打った `display-message hello` も確かめた。コピーモードの PageUp・PageDown・`q` と、プレフィックスの後の `Ctrl+b`（`send-prefix`）は `tmux list-keys` で確かめた
- 使い方の基本のコマンド: `new-session -d -s bg top -d 5`・`ls`・`kill-session -t bg`・`kill-server`。2 つ目の SSH から `new-session -A -s work` で同じセッションに入り（`tmux ls` に `(attached)`）、`attach -d -t work` で 1 つ目の端末が `[detached (from session work)]` になった
- マウス: 設定ファイルの後に、SGR のマウスの信号を端末に送った。ホイールで `[5/258]` のコピーモードに入り、クリックで左のペインが選ばれ、境界のドラッグで左のペインの幅が 80 から 69 になった
- `man tmux`: コンテナに `man-db` を足すと、`man -w tmux` は `/home/linuxbrew/.linuxbrew/Cellar/tmux/3.7c/share/man/man1/tmux.1` を返した
- `history-limit`: 設定ファイルを読む前に作ったペインでも、`source-file` の後に 5000 行を出すと 4973 行をさかのぼれた
- SSH の切断: tmux の中で `top` を動かしたまま SSH のクライアントを `kill -KILL` した。tmux と `top` は残り（`loginctl` のセッションは `closing`）、ログインし直して `tmux attach -t work` で `top` の画面に戻った
- 対話の `claude`（ログインしていない）を tmux の中で起動すると、テーマを選ぶ最初の画面が出た。`pgrep -af` には起動したときの引数のまま出た（`claude --name pgtest`）
- `tmux new-session -s claude-rc claude remote-control …` と tmux に直接起動させると、`[exited]` だけが出てエラーの文が読めなかった。ステータス行の左端は `[claude-rc` で切れた

##### tmux: 未確認事項

- 実機（aarch64 の Raspberry Pi 5、x86_64 の PC）での本実行
- Remote Control の接続、スマートフォン・ブラウザからの操作、約 10 分のネットワーク断での終了と、4 時間以内の再開
- 端末（WezTerm など）からのマウスの操作と、Shift を押しながらの文字の選択
- Claude Code の `Ctrl+B` を tmux の中で 2 回押したときの動き、Shift+Enter
- Homebrew の版が上がる `brew upgrade tmux` と、前の版のサーバーへのつなぎ直し
- `claude --bg` と `claude attach`

---

#### tmux: 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜5、設定ファイル（任意）の手順 1・2。

**結果**: Homebrew の tmux 3.7c を導入した。`work` の TUI に入り、`Ctrl+b d` でデタッチ、`tmux attach -t work` で復帰し、`exit` で終了した。手順 5 は `no server running`。設定ファイルを置いた後の確認用セッションで `mouse on` と `history-limit 50000` を読み戻した。端末捕捉用ライブラリの private DSR 対応不足で初回の画面読み取りが止まったため、検証補助だけを直して同じセッションに入り直し、手順 3〜5 の操作を再確認した。

**今回の未確認範囲**: マウス・Shift+Enter・Claude Code と Remote Control の任意節、更新・ロールバックは今回確認していない。

#### tmux: 付録: 現行版の別の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜5 と設定ファイル（任意）の手順 1・2 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で共通 bash の導入後に確認した。Homebrew の tmux 3.7c の bottle・版・PATH が揃った
- 利用者のセッションを巻き込まない専用ソケットで `work` を作り、Ctrl+b d でデタッチ、一覧、attach、実キーの `exit`、`no server running` を確認した。任意設定は本文どおり新規作成し、専用の確認用セッションで `mouse on` / `history-limit 50000` を読み戻した
- マウス・Shift+Enter・Claude Code / Remote Control の任意節、SSH の切断後の維持、更新・削除はこの再検証には含めない

#### tmux: 操作上の注意と併記されていた記録

- 本書のロールバックは、x86_64 のコンテナで通した

#### tmux: 実施手順 / 手順 1: 補足: 依存と出力

コンテナ（Homebrew 7.0.7、ほかの formula が無い状態）での出力の抜粋:

```
==> Would install 1 formula:
tmux 3.7c
==> Would install 5 dependencies for tmux:
ca-certificates
openssl@3
libevent
ncurses
utf8proc
==> Do you want to proceed with the installation? [y/n]
...
==> Installing tmux
==> Pouring tmux--3.7c.x86_64_linux.bottle.1.tar.gz
🍺  /home/linuxbrew/.linuxbrew/Cellar/tmux/3.7c: 9 files, 1.8MB
==> Caveats
==> tmux
Example configuration has been installed to:
  /home/linuxbrew/.linuxbrew/opt/tmux/share/tmux
```

- 依存がすでに入っていれば、一覧は短くなる。全部入っていれば聞かれない
- `[y/n]` を聞くのは Homebrew 7.0.7 の ask mode（[homebrew.md の注意点](../extra/almalinux-setup.md#注意点)）
- `example_tmux.conf` は、プレフィックスを `Ctrl+a` に変えるなど好みの強い例なので、本書は読み込まない

#### tmux: 実施手順 / 手順 3: 補足: SSH が切れたとき

- コンテナで、SSH でログインしたシェルから tmux のセッションを作り、中で `top` を動かしたまま SSH のクライアントを `kill -KILL` で落とした。tmux のサーバーと `top` は残り、ログインし直して `tmux attach -t work` で `top` の画面に戻れた
- 残るのは、systemd-logind の `KillUserProcesses` が既定で `no` のため（`/usr/lib/systemd/logind.conf` に `#KillUserProcesses=no`、`busctl` で読んだ値も `false`）。SSH のセッション（`loginctl`）は `closing` のまま残る
- [linger](../linger.md) は要らない（tmux は systemd のユーザーのサービスではない）

### tmux: 参考資料から分離した記録

#### tmux: 参考資料: 設定ファイル（任意） / 手順 1: 補足: 読み込む場所と、足さなかった行

- 両方のファイルを置いて試すと、両方の設定が効いた（`~/.tmux.conf` の `mouse on` と `~/.config/tmux/tmux.conf` の `history-limit`）
- Homebrew の tmux のシステムの設定ファイルは `/home/linuxbrew/.linuxbrew/etc/tmux.conf`（`man tmux`）。`/etc/tmux.conf` は読まない
- `escape-time`（Esc の後に待つ時間）は、3.7c の既定ですでに 10 ミリ秒なので足さない。Neovim などのために 0〜10 にする例は、古い版の既定の 500 ミリ秒を縮めるためのもの
- Claude Code の公式ドキュメントには、tmux の設定の推奨は無かった（Shift+Enter のための `extended-keys` なども）。本書では足していない

#### tmux: 参考資料: Claude Code を tmux の中で動かす（任意） / 手順 1: 補足: claude auth status を最後に置く理由

- ブラケットペースト無しで貼ると、`claude auth status --text` は、端末に残っていた後ろの行を読んで捨てた（後ろの `tmux -V` や `echo` が実行されなかった）
- `claude --version` と `claude doctor` では、後ろの行も実行された

### tmux: 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

#### tmux: 設定ファイル（任意）

- マウスを on にすると、マウスでの文字の選択は tmux が受け取る。端末の選択を使うときは、端末の決まりに従う（WezTerm などは Shift を押しながら。本書では確かめていない）

#### tmux: 補足

- **ログアウトしてもセッションが残るのは、`KillUserProcesses=no` のとき**: AlmaLinux 10 の既定。`yes` にしたホストでは、ログアウトでセッションも止まるはず（確かめていない）

---

## 統合前の記録: Git（もとは git.md）

もとの `git.md` の検証記録を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の検証記録](windows-setup.md#統合前の記録-git-の-windows-11もとは-gitmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「Git」の手順 1 |
| 実施手順 2（`dnf install git`） | （外した。git は「Homebrew」の手順 1 で入る） |
| 実施手順 3〜11 | 「Git」の手順 2〜10 |
| 改行を変換して clone したリポジトリを直すの 1〜4 | 改行を変換して clone したリポジトリを直すの 1〜4 |
| 更新 1 | 更新のリード（OS の更新で上がる） |
| ロールバック 1〜5 | ロールバックの「Git の道具を消す」の手順 9〜13 |

### Git: 補足

#### Git: 実施手順: 検証状況の記録

> [!WARNING]
> - **AlmaLinux 10 は x86_64 のクリーン VM で実施手順を本実行済み（2026-10-06）で、コンテナでも検証した**。実機では本実行していない
> - **Windows 11 は、実機の Git Bash で `HOME` を使い捨てのディレクトリにして流した**（その PC の `~/.gitconfig` には書いていない）
> - **Git for Windows を winget で入れる・上げる・外すブロックは、Windows で流していない**（[Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)・[更新](../almalinux-setup.md#更新)の手順 2・[ロールバック](../extra/almalinux-setup.md#git-の道具を消す)の手順 6）。詳しくは[対象と検証環境](#git-対象と検証環境)

#### Git: 実施手順 / 手順 3: 補足: 設定の 3 つの場所

- git は設定を `system`（全ユーザー）→ `global`（自分のユーザー）→ `local`（リポジトリ）の順に読み、後で読んだ値を使う
- AlmaLinux 10 の `system` は `/etc/gitconfig`（RPM は置かない）、`global` は `~/.gitconfig`、`local` は各リポジトリの `.git/config`
- Windows の `system` は、Git for Windows の `C:/Program Files/Git/etc/gitconfig`。インストーラの画面で選んだ改行の扱いや `git pull` の動作が、ここに書かれる
- インストーラの改行の既定の選択（Checkout Windows-style, commit Unix-style line endings）は、`core.autocrlf=true`
- 本書は `system` を変えず、`global` に書いて上書きする（管理者の権限が要らない）
- 検証コンテナでは、git を入れた直後の 2 つ目のコマンドは何も出さなかった
- Windows の模擬（`/etc/gitconfig` に `core.autocrlf=true` などの 4 つを置いた）では、次の 4 行が出た。キーの名前は小文字で出る:

```
system	file:/etc/gitconfig	core.autocrlf=true
system	file:/etc/gitconfig	pull.rebase=false
system	file:/etc/gitconfig	pull.ff=only
system	file:/etc/gitconfig	init.defaultbranch=master
```

- Windows 11 の PC（Git for Windows 2.55.0.windows.3）の Git Bash では、`system` の行が 13 行出た
  - その PC のインストーラの選択では、改行は `core.autocrlf=false`（Checkout as-is, commit as-is）、`git pull` は `pull.rebase=true` で、`pull.ff` は無かった
  - `global` の行は出ない（検証では `HOME` を使い捨てのディレクトリにした。[付録](windows-setup.md#git-付録-windows-11-の-git-bash-での検証記録2026-09-30)）

```
system	file:C:/Program Files/Git/etc/gitconfig	diff.astextplain.textconv=astextplain
system	file:C:/Program Files/Git/etc/gitconfig	filter.lfs.clean=git-lfs clean -- %f
system	file:C:/Program Files/Git/etc/gitconfig	filter.lfs.smudge=git-lfs smudge -- %f
system	file:C:/Program Files/Git/etc/gitconfig	filter.lfs.process=git-lfs filter-process
system	file:C:/Program Files/Git/etc/gitconfig	filter.lfs.required=true
system	file:C:/Program Files/Git/etc/gitconfig	http.sslbackend=schannel
system	file:C:/Program Files/Git/etc/gitconfig	core.autocrlf=false
system	file:C:/Program Files/Git/etc/gitconfig	core.fscache=true
system	file:C:/Program Files/Git/etc/gitconfig	core.symlinks=true
system	file:C:/Program Files/Git/etc/gitconfig	pull.rebase=true
system	file:C:/Program Files/Git/etc/gitconfig	credential.helper=manager
system	file:C:/Program Files/Git/etc/gitconfig	credential.https://dev.azure.com.usehttppath=true
system	file:C:/Program Files/Git/etc/gitconfig	init.defaultbranch=master
```

#### Git: 実施手順 / 手順 5: 補足: 3 つの設定

**pull.rebase**

- 載せ直すのは、まだ push していない自分のコミットだけ。リモートの履歴は書き換えない
- `true` は、ローカルのマージコミットを平らにして載せ直す。マージコミットを残したいなら `merges` にする
- その回だけマージにするなら、`git pull --no-rebase`

**rebase.autoStash**

- `git pull` が rebase するときも、この設定で stash する（`git pull --autostash` と同じ）
- stash を戻すときに衝突したら、変更は stash に残る。検証コンテナで、自分のコミットは無く、同じ行を変えていたときの実測:

```
Updating <HASH>..<HASH>
Created autostash: <HASH>
Fast-forward
 f | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
Applying autostash resulted in conflicts.
Your changes are safe in the stash.
You can run "git stash pop" or "git stash drop" at any time.
```

- このとき `git status --short` は `UU f`、`git stash list` は `stash@{0}: autostash` だった。衝突を解いた後、`git stash drop` で消す

**core.autocrlf**

- `false` では、CRLF のファイルは CRLF のまま、LF のファイルは LF のまま、コミットもチェックアウトもされる（手順 9 で確かめる）
- リポジトリの中で改行を揃えたいときは、そのリポジトリの `.gitattributes` に書く（`* text=auto` など）。`.gitattributes` の `text` は `core.autocrlf` より優先される
- 検証コンテナで、`core.autocrlf=false` のまま `* text=auto` の `.gitattributes` を置き、CRLF のファイルを add すると、`i/lf` で入った

#### Git: 改行を変換して clone したリポジトリを直す / 手順 3: 補足: 書き直し方

- `git rm -r --cached .` で追跡を外してから `git reset --hard` すると、追跡しているファイルがすべて今の設定で書き直される。追跡していないファイルには触れない
- 検証コンテナで、`git checkout-index --force --all` も試したが、ファイルは LF になったものの `git status` に `M` が残った
- Windows 11 の Git Bash でも、`git -c core.autocrlf=true clone` した 2 ファイルのリポジトリ（CRLF の 1 行を足した）で、この節の手順 1 が ` M y.txt` と `2`、手順 3 が `0` を出し、手順 4 の後は 2 つとも `w/lf` になった

#### Git: 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 の git を、同じ `global` の設定にする。pull は rebase で autostash を有効にし、改行は変換しない（`core.autocrlf=false`）。ほかに推奨の設定を入れる
- **進め方**: AlmaLinux 10 は AppStream の `git` を入れる。Windows 11 は、Git for Windows を winget の `Git.Git` で PC 全体（`C:\Program Files\Git`）に入れ（[Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)）、Git Bash に同じブロックを貼る。どちらの OS でも `git config --global` で書く。**読者が書き換えるのは手順 1 の 2 つの変数だけ**
- **状態**: **AlmaLinux 10 は x86_64 のクリーン VM で実施手順を本実行済み（2026-10-06）、コンテナでも検証済み（2026-09-29）。Windows 11 は、実機の Git Bash で流した（2026-09-30。`global` は使い捨ての `HOME`）。Git for Windows を winget で入れる・上げる・外すブロックは、Windows で流していない（2026-10-03 に足した）**
  - 下表の検証コンテナで、**この文書のコードブロックを抜き出したもの**を、一般ユーザーで手順 1〜11 → [改行を変換して clone したリポジトリを直す](../almalinux-setup.md#改行を変換して-clone-したリポジトリを直す) → [ロールバック](../extra/almalinux-setup.md#git-の道具を消す)の順に流した
  - Windows の模擬として、`/etc/gitconfig` に Git for Windows のインストーラの選択で書かれうる値（`core.autocrlf=true` など 4 つ）を置いて、手順 1・3〜11 をもう 1 度流した
  - 確認したこと: 14 のキーが `global` で効く、`system` の値に勝つ、`pull.ff=only` が rebase を止め手順 8 で通る、CRLF のファイルが変換されずに入る、pull が rebase と autostash をする
  - 2026-09-30: 下表の Windows 11 の PC の Git Bash で、この文書のブロックを抜き出したものを流した（[付録](windows-setup.md#git-付録-windows-11-の-git-bash-での検証記録2026-09-30)）
    - `HOME` を使い捨てのディレクトリにしたので、`global` はそこに書かれた。その PC の `~/.gitconfig` は変えていない（前後で md5 が同じ）。`system` はインストーラが書いた本物
    - 手順 1・3〜7・9〜11（手順 8 は `pull.ff` が空なので飛ばした）、[改行を変換して clone したリポジトリを直す](../almalinux-setup.md#改行を変換して-clone-したリポジトリを直す)の手順 1〜4、[ロールバック](../extra/almalinux-setup.md#git-の道具を消す)の手順 1〜3・5
    - 確認したこと: インストーラが書いた `system` の値（手順 3 の補足）、`global` の場所（Git Bash・PowerShell・cmd で同じ）、日本語のファイル名がそのまま出ること、CRLF のファイルが変換されずに入ること、pull の rebase と autostash、`rerere` が覚えた解き方を当てること
  - 2026-10-03: [Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)と、[更新](../almalinux-setup.md#更新)の手順 2（winget で上げる）・[ロールバック](../extra/almalinux-setup.md#git-の道具を消す)の手順 6（winget で外す）を足した。**Windows の実機では流していない**（書いた環境のクラウドの Linux のコンテナでは、Windows を動かせない）
    - 確かめたこと: winget の定義（`Git.Git` 2.55.0.5 のスコープ・インストーラの種類・スイッチ・sha256）、インストーラの sha256 と Authenticode の署名者、上流の `install.iss`（入れる先・権限・黙って入れたときの選択・`system` に書く値・使われているときの動き）、winget のソース（Inno Setup のインストーラに渡すスイッチ・スコープの既定・削除のコマンド）（[付録](windows-setup.md#git-付録-windows-11-の配布物と資料の調査2026-10-03)）
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査、偽の `winget` に渡る引数（[付録](windows-setup.md#git-付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
    - 確かめていないこと: Windows で貼ること（その節のすべての手順・更新・削除）、UAC が出ないこと、`system` に書かれる値、Git Bash が開くこと、公式のインストーラで入れた PC を winget で上げること、arm64 の Windows
  - 2026-10-05: 元値・スコープの記録とロールバック、および改行を直す節の未追跡ファイルの分岐を修正した。クラウドの Linux の Git 2.52.0 で、一時的な `global`・`system` の設定ファイルとリポジトリだけを使って確認した
    - `pull.ff` は、両スコープそれぞれの未設定・`only`・`true`・`false` の 16 通りで、変更する場合だけ戻し、元の値とスコープが復元されることを確認した
    - 未追跡ファイルだけの場合と追跡ファイルにも変更がある場合で、改行の修正後も未追跡ファイルと以前の stash が残り、今回の変更だけを戻せることを確認した。実機の設定は変更していない
  - **確認していないこと**: AlmaLinux 10 の実機、aarch64、利用中の既存の `~/.gitconfig` との組み合わせ
    - Git for Windows のインストーラの既定の選択で書かれる値（`core.autocrlf=true` など）。検証した PC は別の選択だった（[Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)は、この既定で入る。上流のソースを読んだだけ）
    - Git Bash の端末（mintty）に貼る操作そのもの（検証では、ブロックを 1 つのシェルで順に読み込んだ）

| 項目 | 検証コンテナ | Windows 11 の PC（Git Bash） | 実機（参考。未実施） |
|---|---|---|---|
| 実施日 | 2026-09-29 | 2026-09-30 | — |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1） | Windows 11 Pro 25H2（ビルド 26200）/ x86_64 | AlmaLinux 10.2 / aarch64（Raspberry Pi 5） |
| git | `git-2.52.0-1.el10`（AppStream） | Git for Windows 2.55.0.windows.3（`C:\Program Files\Git`、GNU bash 5.3.15） | `git 2.52.0`（AppStream） |
| `system` | 無し（Windows の模擬では 4 行を置いた） | インストーラが書いた 13 行（[手順 3](../almalinux-setup.md#git) の補足） | — |
| `~/.gitconfig` | 無し（手順 4〜6 で作った） | 使い捨ての `HOME` に作った（その PC の `~/.gitconfig` には書いていない） | `[core] autocrlf` と `[user]` だけ（[git-delta.md](#git-delta-対象と検証環境) の記録） |

- 実機の列は、この手順を適用した結果ではなく、ほかの手順書に残っている現時点の状態

[Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)の節（前提にしている環境。Windows では流していない）:

| 項目 | 値 |
|---|---|
| OS | Windows 11 / x64（ほかの Windows の手順書の実機の記録と同じ PC を想定） |
| PowerShell | 管理者の Windows PowerShell 5.1 |
| winget | Windows 11 の「アプリ インストーラー」に入っているもの |
| Git for Windows | 2.55.0.5（winget の `Git.Git` の 2026-10-03 の最新の定義）。`C:\Program Files\Git` |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../almalinux-setup.md#git) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${GIT_USER_NAME}` | `user.name`。コミットの作者の名前 | `Taro Yamada` |
> | `${GIT_USER_EMAIL}` | `user.email`。コミットの作者のメールアドレス | `taro@example.com`、GitHub の noreply のアドレス |
>
> 出力例の値は `<GIT_USER_NAME>` / `<HASH>` / `<WIN_USER>`（Windows のユーザー名）などのプレースホルダで書いてある。バージョン（`2.52.0`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### Git: 実施前の状態

| 項目 | 検証コンテナ | Windows 11 の PC |
|---|---|---|
| git | 未導入（手順 2 で入れた） | Git for Windows 2.55.0.windows.3 が入っていた |
| `system`（AlmaLinux 10 は `/etc/gitconfig`） | 無し（Windows の模擬では、2 回目の前に置いた） | `C:/Program Files/Git/etc/gitconfig` に、インストーラが書いた 13 行（[手順 3](../almalinux-setup.md#git) の補足） |
| `~/.gitconfig` | 無し | その PC の `C:\Users\<WIN_USER>\.gitconfig` にはキーが 4 つあった（検証では使い捨ての `HOME` にしたので、読まれていない） |

- [Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)は、Git for Windows が入っていない PC を前提にしている（Windows では流していない）

#### Git: 選択した方針

- **git は AppStream の RPM**
  - Homebrew の git は 2.55.0 で新しいが、git はシステムの道具（dnf で入れる gh などが依存する）なので、RPM の `/usr/bin/git` に揃える
  - 本書の設定で一番新しいのは `push.autoSetupRemote`（git 2.37）で、2.52.0 で足りる
- **`global` に書き、`system` は変えない**
  - 管理者の権限が要らず、AlmaLinux 10 と Windows で同じコマンドになる
  - Windows の `system` はインストーラが書く場所なので、そこを直さず `global` で上書きする
- **Windows は Git Bash に同じ bash のブロックを貼る**
  - PowerShell 向けに書き分けない。git のコマンドは同じで、変数の書き方だけが違うため
  - Git Bash のホームは `/c/Users/<WIN_USER>`（[windows-openssh-server.md](../windows-setup.md#openssh-サーバー) の実測）で、`global` は `C:/Users/<WIN_USER>/.gitconfig` だった
    - Windows 11 の PC で、`git config --global --list --show-origin` の場所を見て確かめた（値は読んでいない）
- **pull は `pull.rebase=true`**（依頼どおり）
  - `merges` はマージコミットを残すが、ふだんのブランチでマージコミットを作らないなら `true` で足りる
  - `pull.ff=only` は分岐したときに止まるだけで、rebase の方針と合わない
- **推奨の設定は、既定を変えても困りにくく、日常の操作が楽になるものだけ**
  - 選んだもの・入れなかったものは、手順 6 の補足にある
  - エディタ・署名・認証の設定は、人や PC によって違うので入れていない

Windows 11 で Git for Windows を入れる経路を比べた（2026-10-03 時点）:

#### Git: 完了時点の状態

**検証コンテナでの `~/.gitconfig`**（Windows 11 の Git Bash の使い捨ての `HOME` でも、同じ中身だった。AlmaLinux 10 の実機では本実行していない）:

```
[user]
	name = <GIT_USER_NAME>
	email = <GIT_USER_EMAIL>
[pull]
	rebase = true
[rebase]
	autoStash = true
[core]
	autocrlf = false
	quotepath = false
[init]
	defaultBranch = main
[fetch]
	prune = true
[push]
	autoSetupRemote = true
[rerere]
	enabled = true
[merge]
	conflictStyle = zdiff3
[diff]
	algorithm = histogram
[branch]
	sort = -committerdate
[tag]
	sort = version:refname
```

- Windows の模擬では、手順 8 の `[pull]` の `ff = true` が加わった

#### Git: 注意点 / 手順 0: 本文中の記録

  - その PC では環境変数 `HOME` が `C:\Users\<WIN_USER>` に設定されていた。`HOME` の無い PC は試していない

#### Git: 注意点 / 手順 0: 本文中の記録

  - 2026-10-03 の winget の定義はまだ 2.55.0.5 で、本書では 2.56.0 を試していない

#### Git: 付録: コンテナでの検証記録（2026-09-29）

x86_64 のクラウドホストで `dockerd` を動かし、`docker run -d --network host quay.io/almalinuxorg/almalinux:10 sleep infinity` で使い捨てのコンテナを立てた（`docker.io/library/almalinux:10` は `429 Too Many Requests` で取れなかった）。実機と Windows には何も加えていない。

- 検証環境だけの変更: dnf がホストのプロキシを通るように、`/etc/dnf/dnf.conf` に `proxy=` を足し、AlmaLinux のリポジトリを `mirrorlist` から `baseurl` に変え、プロキシの CA を取り込んだ
- 実行ごとに一般ユーザー（NOPASSWD の sudo）を作り直し、**この文書の bash のコードブロックを機械的に抜き出したもの**を、そのユーザーの `bash -s` に流した。書き換えたのは手順 1 の 2 つの値（`Test User` / `test@example.com`）だけ
- `bash -s` には端末が無いので、端末での出力は別に擬似端末（`script`）の中で流して取った
- Windows の模擬の `/etc/gitconfig` は、`core.autocrlf = true`・`pull.rebase = false`・`pull.ff = only`・`init.defaultBranch = master` の 4 行

| 実行 | `/etc/gitconfig` | 流した手順 | 結果 |
|---|---|---|---|
| 1 | 無し | 手順 1〜7・9〜11（手順 8 は `pull.ff` が空なので飛ばした）、[改行を変換して clone したリポジトリを直す](../almalinux-setup.md#改行を変換して-clone-したリポジトリを直す)の手順 1〜4、[更新](../almalinux-setup.md#更新)の手順 1、[ロールバック](../extra/almalinux-setup.md#git-の道具を消す)の手順 1〜3・5 | 手順 2 は `Package git-2.52.0-1.el10.x86_64 is already installed.`（実行 1 の前に、別のユーザーで同じ `sudo dnf install -y git` を流して入れた。そのときは依存を合わせて 74 パッケージが入った）。手順 7 は 14 行が `global`、`pull.ff` は空。手順 9 は `i/crlf  w/crlf`・`main`・`branch 'main' set up to track 'origin/main'.`。手順 10 は `Created autostash` → `Applied autostash.` → `Successfully rebased`、履歴は 1 本、` M crlf.txt` が残った。直す節は、`git -c core.autocrlf=true clone` した 2 ファイルのリポジトリに、CRLF の 1 行を足してから流し、手順 1 で ` M y.txt` と `2`、手順 3 で `0`、手順 4 の後は `w/lf` で差分は足した 1 行だけ。更新は `Nothing to do.`。ロールバックの手順 5 は何も出さなかった |
| 2 | Windows の模擬 | 手順 1・3〜11 | 手順 3 で `system` の 4 行が出た。手順 7 は 14 行が `global`、`pull.ff` だけ `system	only`。手順 8 で `global	true`。手順 9・10 は実行 1 と同じ結果。`~/.gitconfig` の `[pull]` に `ff = true` が加わった |
| 3 | Windows の模擬 | 手順 1・4〜7・9〜11（手順 8 を飛ばした） | 手順 10 の `git pull` が `fatal: Not possible to fast-forward, aborting.` で止まり、履歴は分かれたまま、` M crlf.txt` は残った |
| 4 | 無し | 擬似端末の中で、手順 1・4〜6・9〜11 | 手順 9 の `git push` と手順 10 の `git pull` の、端末での出力を取った（手順 9・10 の補足） |

個別に確かめたこと（同じコンテナの使い捨てのリポジトリ。設定は主に `git -c` で 1 回ずつ変えた）:

| 確かめたこと | 結果 |
|---|---|
| 設定が無いときの `git init` | `hint:` が 13 行出て、ブランチは `refs/heads/master` |
| `core.autocrlf=true` で CRLF のファイルを add | `i/lf    w/crlf` |
| `core.quotepath=true` の `git status --short` | `?? "\346\227\245\346\234\254\350\252\236.txt"` |
| `* text=auto` の `.gitattributes` と `core.autocrlf=false` で CRLF のファイルを add | `i/lf    w/crlf  attr/text=auto` |
| autostash を戻すときの衝突 | `Applying autostash resulted in conflicts.`、`UU f`、`stash@{0}: autostash` |
| `pull.ff=false` と `pull.rebase=true` | rebase された |
| `pull.rebase=false` | `Merge made by the 'ort' strategy.` でマージコミットができた。擬似端末では、その前に `GIT_EDITOR` のエディタが `MERGE_MSG` を開いた |
| `rebase.autoStash` 無しで、未コミットの変更がある pull | `error: cannot pull with rebase: You have unstaged changes.` |
| 直す節の代わりに `git checkout-index --force --all` | ファイルは `w/lf` になったが、`git update-index --refresh` の後も `git status` に `M` が残った |
| `git config --global --unset` で、最後のキーを外す | `~/.gitconfig` からその節も消えた。無いキーの `--unset` は何も出さない（終了コード 5） |
| `user.name`・`user.email` 無しの `git commit` | `Author identity unknown` と `fatal: unable to auto-detect email address` で止まった |

##### Git: 未確認事項

- 実機（AlmaLinux 10）での本実行と、既存の `~/.gitconfig`（`[core] autocrlf` がある）との組み合わせ
- Windows 11 の Git Bash での実行（Git for Windows のインストーラが `system` に書く値、`global` の置き場所、日本語のファイル名の表示）
- Windows の PowerShell・cmd から呼ぶ git が、同じ `global` を読むこと
- aarch64 での実行
- `rerere` が覚えた解き方を当てるところ
- [更新](../almalinux-setup.md#更新)で新しい版に上がるところ（新しい版が無い状態で `sudo dnf upgrade git` を流しただけ）

---

#### Git: 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜7・9〜11。

**結果**: Git 2.52.0。テスト用の名前・メールで global の 14 設定を読み戻した。CRLF の保持、日本語のファイル名、`main`、ローカル bare リポジトリへの初回 push の upstream 設定、pull の rebase・autostash と未コミット変更の保持、手順 11 の後片付けを確認した。手順 8 は `pull.ff` が未設定だったため条件外。外部リポジトリへは push していない。

**今回の未確認範囲**: 改行を変換した clone を直す節、更新・ロールバック・Windows の手順は今回流していない。

#### Git: 付録: 現行版の新規 VM での再検証（2026-10-06）

公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active）で、`5da3478` の本文を SSH 対話 PTY に渡した。試験専用のユーザー・鍵と設定値を使用し、利用者の実アカウントの資格情報は持ち込んでいない。

実施手順 1〜7 を通し、Git 2.52.0 と全体設定の値・global の設定元を確認した。名前とメールは検証専用の値に置き換えた。GitHub への認証・push、Windows の導入は行っていない。


#### Git: 分離前の検証状況の記録

> [!WARNING]
> - **Windows 11 は、実機の Git Bash で `HOME` を使い捨てのディレクトリにして流した**（その PC の `~/.gitconfig` には書いていない）
> - **Git for Windows を winget で入れる・上げる・外すブロックは、Windows で流していない**（[Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)・[更新](../almalinux-setup.md#更新)の手順 2・[ロールバック](../extra/almalinux-setup.md#git-の道具を消す)の手順 6）。詳しくは[対象と検証環境](#git-対象と検証環境)


#### Git: 実施手順 / 手順 9: 補足: 検証コンテナでの出力

擬似端末（`script`）の中で流したときの出力。進み具合の行は、最後の表示だけを載せた:

```
?? a.txt
?? crlf.txt
?? 日本語.txt
i/crlf  w/crlf  attr/                 	crlf.txt
main
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to <N> threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (5/5), <SIZE> | <SPEED>, done.
Total 5 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
To ../remote.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

- `core.autocrlf=true`（Windows の既定）なら、`i/lf` で入る。`core.quotepath` が既定の `true` なら、`"\346\227\245\346\234\254\350\252\236.txt"` と出る
- Windows 11 の Git Bash でも、`?? 日本語.txt`・`i/crlf  w/crlf`・`main`・`branch 'main' set up to track 'origin/main'.` が出た（出力はパイプに出したので、進み具合の行は無い）



#### Git: 実施手順 / 手順 10: 補足: 検証コンテナでの出力

`a` で `a: 2` を push し、`b` では `b: b.txt` をコミットして `crlf.txt` を変えたまま pull した。擬似端末（`script`）の中で流したときの出力で、進み具合の行は最後の表示だけを載せた:

```
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0 (from 0)
Unpacking objects: 100% (3/3), <SIZE> | <SPEED>, done.
From <GIT_TEST_DIR>/remote
   <HASH>..<HASH>  main       -> origin/main
Created autostash: <HASH>
Applied autostash.
Successfully rebased and updated refs/heads/main.
* <HASH> (HEAD -> main) b: b.txt
* <HASH> (origin/main, origin/HEAD) a: 2
* <HASH> first
 M crlf.txt
```

- `Created autostash` の後に `Rebasing (1/1)` が出て、`Applied autostash.` で上書きされる
- 比べるために、`pull.rebase=false` で pull すると、`Merge made by the 'ort' strategy.` でマージコミットができ、`git log` が枝分かれした（端末ではマージのメッセージを書くエディタが開く）
- `rebase.autoStash` が無いと、pull は `error: cannot pull with rebase: You have unstaged changes.` で止まった
- Windows 11 の Git Bash でも、`Created autostash` → `Applied autostash.` → `Successfully rebased and updated refs/heads/main.` の順に出て、履歴は 1 本、` M crlf.txt` が残った



#### Git: 実施手順 / 手順 2: 補足: 入るパッケージ

- `git`（AppStream）は、本体の `git-core`、`git-core-doc`、perl のモジュール（`perl-Git` など）、`openssh-clients` を依存で連れてくる
- 検証コンテナ（最小の構成）では、依存を合わせて 74 パッケージが入った。デスクトップで入れた PC では、多くが入っている
- [gh](../almalinux-setup.md#github-cli) も git に依存するので、gh を入れた PC には git も入っている



#### Git: 実施手順 / 手順 8: 補足: pull.ff=only と pull.rebase

- `pull.ff=only` があると、`pull.rebase=true` でも、分岐した pull は rebase されずに止まる。検証コンテナで `system` に `pull.ff=only` を置き、この手順を飛ばすと、手順 10 の `git pull` が次で終わった（未コミットの変更はそのまま残った）:

```
hint: Diverging branches can't be fast-forwarded, you need to either:
hint:
hint: 	git merge --no-ff
hint:
hint: or:
hint:
hint: 	git rebase
hint:
hint: Disable this message with "git config set advice.diverging false"
fatal: Not possible to fast-forward, aborting.
```

- Git for Windows のインストーラで、`git pull` の既定の動作に「Only ever fast-forward」を選ぶと、この値が `system` に書かれる（本書では確かめていない）
- `true` は git の既定の動作（fast-forward できるときはする）。`pull.ff=false` も、rebase を止めなかった



#### Git: 改行を変換して clone したリポジトリを直す / 手順 1: 補足: 前の設定で見る理由

- `-c core.autocrlf=true` は、そのコマンドだけ前の設定で見る。付けないと、改行だけが違うファイルもすべて `M` で出る
- 検証コンテナで、LF のリポジトリを `git -c core.autocrlf=true clone` で clone すると、ファイルは `i/lf    w/crlf` になり、手順 5 の設定の `git status --short` ではすべて `M` で出た



#### Git: 更新 / 手順 2: 補足: winget での更新

- 定義の `UpgradeBehavior: install` のとおり、新しい版のインストーラを今のものの上から動かす。入れる先（`C:\Program Files\Git`）と、前に入れたときの選択（改行の扱いなど）は引き継ぐ。そのため `--scope` は付けない
- インストーラは、Git のファイル（`msys-2.0.dll` など）を使っているプロセスがあると、閉じるよう求める画面を出す。黙って動かすときはその問いが「キャンセル」で答えられ、入れ替えずに終わる（上流の `install.iss` を読んだだけで、確かめていない）
- 公式のインストーラで入れた PC でも、winget が `Git.Git` と結び付けて表示すれば、同じ形で上がるはず（確かめていない）。`winget list --exact --id Git.Git` に出なければ、[Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)の手順 3 を貼る（今のものの上から入れる）
- インストーラの部品の「毎日の更新の確認」は既定で入れないので、Git for Windows は自分では上がらない



#### Git: ロールバック / 手順 6: 補足: winget での削除

- winget は、インストーラが「アプリと機能」に書いた静かな削除のコマンド（`C:\Program Files\Git\unins000.exe /SILENT`）を動かす。Inno Setup の削除のプログラムは、`/SILENT` では確かめの問いを出さない
- Git for Windows の削除のプログラムは、`PATH` から `C:\Program Files\Git\cmd` を外す（上流の `install.iss`）
- 管理者でない窓から貼ると、削除のプログラムが UAC で昇格を求めるはず（確かめていない）

### Git: 参考資料から分離した記録

#### Git: 参考資料: 実施手順 / 手順 6: 補足: 推奨の設定と、入れなかった設定

| キー | 値 | 変わること |
|---|---|---|
| `init.defaultBranch` | `main` | `git init` の最初のブランチを `main` にする。設定が無いと git 2.52 は `master` にし、`hint:` を 13 行出した |
| `core.quotepath` | `false` | 日本語のファイル名を、`"\346\227\245…"` と書かずにそのまま出す |
| `fetch.prune` | `true` | fetch・pull のたびに、リモートで消えたブランチの追跡ブランチ（`origin/…`）を消す。ローカルのブランチは消さない |
| `push.autoSetupRemote` | `true` | 新しいブランチの最初の `git push` で、`-u origin <ブランチ>` を付けなくても追跡を設定する |
| `rerere.enabled` | `true` | 一度解いた衝突の解き方を覚え、同じ衝突に当たったら自動で当てる。rebase で同じ衝突を何度も解かずに済む |
| `merge.conflictStyle` | `zdiff3` | 衝突の表示に、共通の祖先の内容も出す（git 2.35 以降） |
| `diff.algorithm` | `histogram` | 差分の取り方。既定の `myers` より、関数を動かしたときなどに読みやすい差分になりやすい |
| `branch.sort` | `-committerdate` | `git branch` を、最近コミットしたブランチから並べる |
| `tag.sort` | `version:refname` | `git tag` を版の順（`v1.9` の後に `v1.10`）に並べる |

入れなかったもの:

- `core.editor`: 好みで決める。未設定なら、環境変数 `VISUAL`・`EDITOR` のエディタ、どちらも無ければ `vi` が開く。Windows では、インストーラで選んだエディタが `system` に入る
- `rerere.autoUpdate`: 覚えた解き方を当てた後に、`git add` までする。当てた結果を `git diff` で見てから add したいので入れない
- `fetch.pruneTags`: リモートに無いタグを、ローカルからも消す
- `pull.ff only`: 分岐したときの pull が、rebase せずに止まる（手順 8）
- `push.default`: 既定の `simple`（今のブランチを、同じ名前の追跡ブランチにだけ push する）のままでよい

#### Git: 参考資料: 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `Git.Git` を `--scope machine` で** | 上流のインストーラを、winget が sha256 を確かめてから黙って動かす。`C:\Program Files\Git` に入り、`winget upgrade` で上がる。管理者の権限が要る | **採用** |
| winget の `--scope user` | 同じインストーラで、winget はスコープのスイッチを渡さない。入る先はインストーラが権限で決める | 不採用（PC 全体に入れるので、winget にも `machine` を指定する） |
| 上流のインストーラを落として、画面で入れる | 選択を画面で選べる。版の確認と更新は手作業 | 不採用（以前の検証の PC はこの形で、もとの本書もこれを案内していた） |
| scoop の `main/git` | Git for Windows の持ち運び版（PortableGit）を `~\scoop\apps\git` に入れ、`git` などを `~\scoop\shims` に置く。`C:\Program Files\Git\bin\bash.exe` が無い | 不採用（[Windows の OpenSSH サーバー](../windows-setup.md#ssh-の既定のシェルを-git-bash-にする任意)が `C:\Program Files\Git` を前提にしている。[Windows 11 の初期設定](../windows-setup.md)も、scoop の git を入れなくなった） |

- **インストーラの選択は既定のまま**（winget の `--custom` や `--override` で `/o:` を渡さない）
  - 本書は `system` を変えず `global` で上書きするので、`system` の `core.autocrlf=true`・`pull.rebase=false`・`init.defaultBranch=master` は既定のままでよい（[実施手順](../almalinux-setup.md#git)の手順 7 で確かめる）
  - 既定の PATH の選択（`cmd` だけを足す）で、PowerShell・scoop・Claude Code から `git` が見つかる。Unix の道具まで足す選択は、Windows の `find`・`sort` を隠す（インストーラの画面の警告）
  - `--override` は、winget が渡す黙って動かすスイッチ（`/SP- /SILENT …`）ごと置き換える（winget のソース）
- **Git for Windows は、scoop の `scoop update` が使う git も兼ねる**
  - scoop は、scoop の git が入っていなければ `PATH` の `git` を使う（[Windows 11 で Git for Windows を入れる](../windows-setup.md#git-for-windows)の手順 5 の補足）

---

## 統合前の記録: Firefox（もとは firefox.md）

もとの `firefox.md` の検証記録を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の検証記録](windows-setup.md#統合前の記録-firefox-の-windows-11もとは-firefoxmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜11 | 「Firefox」の手順 1〜11 |
| 更新 1 | 更新のリード（OS の更新で上がる） |
| ロールバック 1〜5 | ロールバックの「Firefox を戻す」の手順 1〜5 |

### Firefox: 補足

#### Firefox: 実施手順 / 手順 1: 補足: 変数について

本書で導入するのは `firefox`（Rapid Release）だけ。配布の調査では、ほかのチャンネルもリポジトリにあることを確かめた:

```
$ dnf -q list --available firefox-l10n-ja firefox-esr firefox-beta | tail -6
Available Packages
firefox-beta.aarch64                     157.0b4-1                       mozilla
firefox-beta.x86_64                      157.0b4-1                       mozilla
firefox-esr.aarch64                      153.3.0esr-1                    mozilla
firefox-esr.x86_64                       153.3.0esr-1                    mozilla
firefox-l10n-ja.noarch                   156.0.1-1                       mozilla
```

`firefox-esr` は **Mozilla の ESR（153 系）** で、AppStream の ESR 140 とは別物。並べて入れることもできる（`/usr/lib/firefox-esr`）が、本書では扱わない。

`FF_L10N` は `firefox-l10n-<言語コード>` の形で `noarch`。本体とバージョンが揃っていないと UI に反映されないので、常に本体と一緒に入れ替える。

#### Firefox: 実施手順 / 手順 3: 補足: 鍵の警告

`gpg --show-keys` は主鍵 1 つと副鍵 6 つを表示する。有効な署名用副鍵は 1 つだけで、残りは期限切れ:

```
pub   rsa4096 2015-07-17 [SC]
      14F26682D0916CDD81E37B6D61B7B526D98F0353
uid                      Mozilla Software Releases <release@mozilla.com>
sub   rsa4096 2026-08-06 [S] [expires: 2028-08-05]
sub   rsa4096 2021-05-17 [S] [expired: 2023-05-17]
...
```

`rpm --import` はこの期限切れ副鍵について warning を出す。取り込み自体は成功している:

```
$ sudo rpm --import https://packages.mozilla.org/rpm/firefox/signing-key.gpg
warning: Certificate 61B7B526D98F0353:
  Subkey F1A6668FBB7D572E is expired: The subkey is not live
  Policy rejects subkey 1C69C4E55E9905DB: Policy rejected non-revocation signature (SubkeyBinding) requiring second pre-image resistance
  Subkey EBE41E90F6F12F6D is expired: The subkey is not live
  ...
```

先に `rpm --import` しておくのは、`dnf install` の途中で「この鍵を取り込むか」と聞かれたときに fingerprint を目視で照合する手間を、独立した手順に分けるため。取り込まずに進めても dnf が同じ鍵を取りに行って同じ確認を出す。

#### Firefox: 実施手順 / 手順 5: 補足: 言語パックのクォートと、ESR からの載せ替え

`FF_L10N` を空にした場合にクォートで空文字列を渡さないよう、言語パックだけクォートしていない。

実機では `dnf upgrade firefox` で載せ替えた（`dnf history` の記録）:

```
$ sudo dnf history info 16
Command Line   : upgrade firefox
Packages Altered:
    Upgrade  firefox-156.0-1.aarch64           @mozilla
    Upgraded firefox-140.15.0-1.el10_2.aarch64 @@System
```

本書では `dnf install` 1 本にしてある（未導入のホストでもそのまま使えるため）。ESR が入っている状態でも `Upgrading` として解決されることをコンテナで確認した:

```
$ dnf install --assumeno firefox firefox-l10n-ja
Package firefox-140.15.0-1.el10_2.aarch64 is already installed.
Installing:
 firefox-l10n-ja   noarch    156.0.1-1   mozilla   497 k
Upgrading:
 firefox           aarch64   156.0.1-1   mozilla   107 M
```

依存パッケージの追加は無い（ESR 版と同じ共有ライブラリで動く）。未導入のホストに新規で入れる場合は、GTK などデスクトップ側の依存で 100 以上のパッケージが付いてくる。

#### Firefox: 実施手順 / 手順 8: 補足: 手順 8〜11 で足すもの、入るもの、鍵の確認の実測

手順 8〜11 では、Firefox が自前で復号できない AAC と H.264 のために、RPM Fusion（free）の FFmpeg のライブラリを入れる。理由と、EPEL の `libavcodec-free` を採らなかった経緯は[選択した方針](../reference/almalinux-setup.md#firefox-選択した方針)にある。

Firefox だけを入れたコンテナでは 79 パッケージが入った（ダウンロード 42 MB、展開後 137 MB）。内訳は EPEL 44・BaseOS 17・AppStream 14・RPM Fusion 4（`ffmpeg-libs`・`x264-libs`・`x265-libs`・`vvenc-libs`）で、CRB からは無い。実機（GNOME のデスクトップ）では、既に入っているものが多く 60 パッケージだった（EPEL 44・AppStream 10・RPM Fusion 4・BaseOS 2）。

x86_64 の実機（GNOME のデスクトップ、EPEL は入れ済み）では 62 パッケージだった（ダウンロード 40 MB、展開後 128 MB。EPEL 47・AppStream 10・RPM Fusion 4・BaseOS 1）。弱い依存として、次のものも入った:

- `intel-vpl-gpu-rt`・`jxl-pixbuf-loader`・`vmaf-models`
- `tesseract-langpack-jpn`・`tesseract-langpack-jpn_vert`（`Supplements: (tesseract and langpacks-ja)` なので、日本語の `langpacks-ja` が入ったホストで付く）

Firefox のプロセスが読み込むのは `/usr/lib64/libavcodec.so.61.19.101`（FFmpeg 7.1）だった（コンテナで `/proc/<pid>/maps` を見た）。コマンドの `ffmpeg` は入らない（要るなら `sudo dnf install ffmpeg`）。

**`noopenh264` が入る理由**: `ffmpeg-libs` が `libopenh264.so.7` を要求し、x86_64 の実機の有効なリポジトリでそれを提供するのは、EPEL の `noopenh264`（中身の無い OpenH264）だけだった。aarch64 でも同じ（メタデータで確認）。x86_64 の実機では、Firefox のプロセスが `/usr/lib64/libopenh264.so.2.4.1` も読み込んだが、H.264 + AAC の mp4 は再生できた。EPEL の `libavcodec-free` と違い、H.264 は FFmpeg 自身のデコーダで復号される。

EPEL の鍵の確認の実測（RPM Fusion の有効化（今の [AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」](../almalinux-setup.md#epel-と-rpm-fusion)の手順 4）で、EPEL が依存として入ったコンテナ）。RPM Fusion の鍵は rpmfusion.md の手順 2 で取り込んであるので聞かれない:

```
Importing GPG key 0xE37ED158:
 Userid     : "Fedora (epel10) <epel@fedoraproject.org>"
 Fingerprint: 7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10
```

#### Firefox: 実施手順 / 手順 9: 補足: EPEL の libavcodec-free を外す理由

EPEL の `libavcodec-free`（EPEL の `ffmpeg-free` のライブラリ）は、EPEL の Chromium や `gstreamer1-plugin-libav` など、`libavcodec.so.61` を使うパッケージの依存で入っていることがある。`ffmpeg-libs` とは同居できず、手順 8 は次のように止まる（`libavcodec-free` を入れたコンテナでの実測）:

```
Error:
 Problem: problem with installed package libswresample-free-7.1.2-1.el10_2.aarch64
  - package ffmpeg-libs-7.1.5-1.el10.aarch64 from rpmfusion-free-updates conflicts with libswresample-free provided by libswresample-free-7.1.2-1.el10_2.aarch64 from @System
  - package ffmpeg-libs-7.1.5-1.el10.aarch64 from rpmfusion-free-updates conflicts with libswresample-free provided by libswresample-free-7.1.2-1.el10_2.aarch64 from epel
  - conflicting requests
```

`--allowerasing` を付けると、`Removing dependent packages:` に 3 つが並んで入れ替わった。`ffmpeg-libs` は同じ共有ライブラリ（`libavcodec.so.61` など）と `libavcodec-freeworld` を提供する。入れ替えた後、Firefox は H.264 と AAC を再生できた。

`libavcodec-free` を残したままでは、H.264 の動画が再生できない（[選択した方針](../reference/almalinux-setup.md#firefox-選択した方針)）。コマンドの `ffmpeg-free` も入っているときは、RPM Fusion の [Howto/Multimedia](https://rpmfusion.org/Howto/Multimedia) が案内する `sudo dnf swap ffmpeg-free ffmpeg --allowerasing` になる（本書では試していない）。

#### Firefox: 実施手順 / 手順 11: 補足: 起動し直す理由と、about:support の表

FFmpeg を入れる前から起動していた Firefox では、入れた後も about:support の `H264` と `AAC` は「未対応」のままで、AAC の復号も失敗した。起動し直すと「対応」になった（コンテナでの実測）。

「コーデックサポート情報」の「ソフトウェアデコーディング」の列（「ハードウェアデコーディング」は、どちらもすべて「未対応」）:

| コーデック名 | 入れる前 | 入れた後 |
|---|---|---|
| H264 | 未対応 | 対応 |
| VP9 | 対応 | 対応 |
| AV1 | 対応 | 対応 |
| HEVC | 未対応 | 対応 |
| AAC | 未対応 | 対応 |
| Opus | 対応 | 対応 |

この表の `H264` は FFmpeg の側だけを示す。Firefox が起動後に自動で落とす Cisco の OpenH264（プロファイルの `gmp-gmpopenh264`）で H.264 を再生できているときも、FFmpeg が無ければ「未対応」と出る。

#### Firefox: ロールバック / 手順 0: 本文中の記録

- この節の手順 1 はコンテナと x86_64 の VM で本実行した

#### Firefox: ロールバック / 手順 0: 本文中の記録

- Firefox を戻す手順（この節の手順 2〜5）も x86_64 の VM で本実行した（2026-10-06）。`157.0-1` から AppStream の `140.16.0-1.el10_2` に戻り、言語パック・Mozilla の repo と署名鍵も外れた

#### Firefox: 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に、Firefox の**最新版**（Rapid Release）を入れる
  - AlmaLinux 10 では dnf 管理で入れ、Windows 版と同じように AAC と H.264 の動画も再生できるようにする。標準リポジトリ（AppStream）の `firefox` は ESR 140 系で、最新版より 16 メジャー古い
  - Windows 11 では日本語版を PC 全体に入れ、既定のブラウザーにする。[Windows 11 の初期設定](../windows-setup.md)の後に通す手順書の 1 つ
- **進め方**
  - **AlmaLinux 10**（[実施手順](../almalinux-setup.md#firefox)）: Mozilla が公式に配っている RPM リポジトリ `packages.mozilla.org/rpm/firefox` を 1 つ足し、`dnf install` する。続けて、[rpmfusion.md](../almalinux-setup.md) で有効にした RPM Fusion（free）から、FFmpeg のライブラリ `ffmpeg-libs` を入れる（手順 8〜11）。**読者が書き換えるのは冒頭の変数ブロックだけ**で、既定（最新版 + 日本語パック）ならそのまま貼れる
  - **Windows 11**（[Windows 11 で使う](../windows-setup.md#firefox)）: winget の `Mozilla.Firefox.ja`（Mozilla の日本語版のインストーラ）を、管理者の Windows PowerShell 5.1 から PC 全体（`C:\Program Files\Mozilla Firefox`）に入れ、Windows の設定で既定のブラウザーにする。更新は Firefox 自身（Mozilla Maintenance Service）に任せる。変数は無く、AAC・H.264 のために足すものも無い
- **状態（AlmaLinux 10）**
  - 2026-10-06: 別の新規 VM で現行手順を再検証した。今回の実施・解除・未実施範囲は[新しい付録](#firefox-付録-現行版の新規-vm-での再検証2026-10-06)に記録した
  - **2026-10-06: クリーンな x86_64 の VM で手順 1〜8・10・11 とロールバック 1〜5 を本実行済み**。Mozilla 157 の日本語 GUI と H.264/AAC の動画再生、AppStream の ESR 140 への復元を確認した（末尾の付録）。手順 9 は衝突が無かったため省略した
  - **手順 1〜7（Firefox）は実機で本実行済み（2026-09-21）**
    - 下表のホストで `dnf upgrade firefox` を実行し、AppStream の `140.15.0-1.el10_2` から mozilla の `156.0-1` に載せ替えて、そのまま常用している
    - 2026-09-25 に OS を入れ直した後も、手順 5 の `dnf install firefox firefox-l10n-ja` で入れ直した（`dnf history` では `Upgrade firefox-156.0.1-1.aarch64 @mozilla`）
    - 本書の手順（鍵の照合 → repo → install → 検証）は、2026-09-22 に同じ OS のコンテナで通し直した
    - 確認したこと: `156.0.1-1` が入る、ESR からの載せ替えが `Upgrading` として解決される、ロールバックが `Downgrading` に解決される
    - **コンテナでは GUI を起動していない**（実機では 156.0 が動作中）
    - **ESR / Beta チャンネルと言語パック以外の l10n は未検証**
  - **手順 8〜11（AAC・H.264）と、その前の RPM Fusion の有効化も実機で本実行済み（2026-09-28）**。aarch64 と x86_64 の 2 台
    - RPM Fusion の有効化は、今の [AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」](../almalinux-setup.md#epel-と-rpm-fusion)の手順 2〜4。当時はこの文書の手順 8〜11 で、今の手順 8〜11 は手順 12〜14 だった
    - 下表の aarch64 の実機で、利用者が手順どおりに入れた（[付録](#firefox-付録-実機での本実行2026-09-28)）
      - rpmfusion.md 手順 2 の鍵が登録されている
      - `dnf history` に、rpmfusion.md 手順 3（4 パッケージ）と手順 8（`ffmpeg-libs` ほか 60 パッケージ）の実行が残っている
      - `libavcodec-free` は入っていなかったので、手順 9 は要らなかった
    - 利用者が、再生できなかった動画が再生できるようになったことを確かめた
    - 同じ実機で、一時プロファイルの headless の Firefox を Marionette で動かして次を確かめた
      - about:support の H264・HEVC・AAC が「対応」になる
      - AAC と H.264 の再生が通る
      - Firefox のプロセスが `/usr/lib64/libavcodec.so.61.19.101` を読み込んでいる
    - この文書の手順 1〜10 と rpmfusion.md の手順 1〜3 のブロックは、同じ OS の aarch64 コンテナでもそのまま流して通した（条件付きの手順 9 は、`libavcodec-free` を入れた別のコンテナで）
    - 下表の x86_64 の実機では、rpmfusion.md の手順 1〜3 と、手順 8・10 のコマンドを実行した（[付録](#firefox-付録-x86_64-の実機での本実行2026-09-28)）
      - YouTube の動画が 360p から上がらず、音声が AAC だけの動画は再生できなかったホスト
      - dnf は `--assumeno` でトランザクション表を確かめてから、`-y` を付けて入れた。手順 9 は要らなかった
      - 一時プロファイルの headless の Firefox で、about:support の H264・HEVC・AAC が「対応」になり、AAC の復号と H.264 + AAC の mp4 の再生が通ることを確かめた
      - 同じく、音声が AAC だけの YouTube の動画が VP9 1080p60 + AAC で再生された（FFmpeg を切ると「ご利用のブラウザではこの動画を再生できません。」になった）
      - 起動し直した利用者の Firefox が `/usr/lib64/libavcodec.so.61.19.101` を読み込むことを確かめた
      - 利用者が、その Firefox の画面で 2 本の動画が再生できることを確かめた（[付録](#firefox-付録-x86_64-の実機での画面の確認2026-09-28)）
    - 音声が AAC だけの YouTube の動画は、x86_64 の実機でだけ確かめた（利用者の画面と headless の Firefox。aarch64 の例の動画は、実機に入れる前に YouTube 側で Opus が足されていた。代わりに、AAC を MSE で流すテストを実機でも通した）
  - 2026-09-28: 手順 4 のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-02: もとの手順 3・4 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](windows-setup.md#firefox-付録-windows-11-の配布物と資料の調査2026-10-03)）:
    - winget の定義: `Mozilla.Firefox.ja` と `Mozilla.Firefox` の 157.0（インストーラの種類・スコープ・スイッチ・URL・sha256・`ProductCode`）と、`Mozilla.Firefox` から言語のインストーラが無くなった版（137.0.2）
    - 配布物: x64 の日本語版の `Firefox Setup 157.0.exe` の sha256（winget の定義と Mozilla の `SHA256SUMS` と一致）・Authenticode の署名者（`Mozilla Corporation`）・中身（Maintenance Service のインストーラ、Default Browser Agent、日本語の `updater.ini`）。Linux で読んだだけで、Windows の `Get-AuthenticodeSignature` は通していない
    - Mozilla の文書と Firefox のソース: インストーラの既定（場所・Maintenance Service・タスク・ショートカット）、アンインストーラが消すもの、閉じている間の更新の条件、既定のブラウザーの設定のしかた、Windows で H.264 と AAC を Media Foundation で復号すること
    - winget のソース: `--locale` の扱い、NSIS のインストーラで入れたもののアンインストールで窓が出ること、`winget list --upgrade-available`
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査（[付録](windows-setup.md#firefox-付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
  - **確かめていないこと**: Windows で貼ること（すべての手順）、winget の表示、入れた後の about:support と動画の再生、Windows の設定の画面の名前と既定のブラウザーの切り替え、Firefox 自身の更新と `winget upgrade`、アンインストールの窓、arm64 の Windows、N エディション

AlmaLinux 10:

| 項目 | 実機 | 検証コンテナ | 検証コンテナ（rpmfusion.md と手順 8〜11） | 実機（rpmfusion.md と手順 8〜11） | x86_64 の実機（rpmfusion.md と手順 8〜11） |
|---|---|---|---|---|---|
| 実施日 | 2026-09-21 | 2026-09-22 | 2026-09-28 | 2026-09-28 | 2026-09-28 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） | 同左 | 実機と同じホスト（2026-09-25 に入れ直した後） | AlmaLinux 10.2 (Lavender Lion) / x86_64（AMD Strix Halo のノート PC） |
| カーネル | 6.12.96 | ホストと同じ | ホストと同じ | 6.12.96 | 6.12.0-211.56.1.el10_2 |
| dnf | 4.20.0 | 4.20.0 | 4.20.0 | 4.20.0 | 4.20.0 |
| 実施前の Firefox | `firefox-140.15.0-1.el10_2.aarch64`（appstream、ESR 140） | 同じものを `dnf install firefox` で用意 | `firefox-156.0.1-1.aarch64`（mozilla。手順 2〜5 で用意） | `firefox-156.0.1-1.aarch64`（mozilla。2026-09-25 に手順 5 で入れ直したもの） | `firefox-156.0.1-1.x86_64`（mozilla） |
| 入った Firefox | `firefox-156.0-1.aarch64`（mozilla、Vendor: Mozilla） | `firefox-156.0.1-1.aarch64` | 同左。FFmpeg は `ffmpeg-libs-7.1.5-1.el10.aarch64`（rpmfusion-free-updates） | Firefox は変わらない。FFmpeg は `ffmpeg-libs-7.1.5-1.el10.aarch64`（rpmfusion-free-updates） | Firefox は変わらない。FFmpeg は `ffmpeg-libs-7.1.5-1.el10.x86_64`（rpmfusion-free-updates） |
| デスクトップ | GNOME 49 / Wayland | 無し（`--version` まで） | 無し（headless の Firefox を Marionette で操作） | GNOME 49（`gnome-shell` 49.4） | GNOME 49（`gnome-shell` 49.4）/ Wayland |
| SELinux | Enforcing | コンテナ側は無効 | コンテナ側は無効 | Enforcing | Enforcing |

Windows 11（前提にしている環境。ほかの Windows の手順書の実機の記録と同じ PC を想定）:

| 項目 | 値 |
|---|---|
| OS | Windows 11（x64。[Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)の PC は 25H2・26H2） |
| PowerShell | Windows PowerShell 5.1（管理者として実行） |
| ユーザー | Administrators の一員 |
| winget | Windows 11 の「アプリ インストーラー」に入っているもの |
| Firefox | 157.0（winget の `Mozilla.Firefox.ja`。Mozilla が 2026-09-29 に出した版） |

> [!NOTE]
> AlmaLinux 10 の環境固有の値は**シェル変数**で書いてある。[手順 1](../almalinux-setup.md#firefox) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。Windows 11 の節には変数が無い（winget の ID とパスはブロックに直接書いてある）。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${FF_PKG}` | 本書で導入するパッケージ名。`firefox`（最新版）から変更しない | `firefox` |
> | `${FF_L10N}` | 言語パックのパッケージ名。空にすると英語 UI のまま | `firefox-l10n-ja` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。Windows 11 のタスクの名前の末尾の番号（インストール先ごとに決まる）は `<番号>` と書いた。バージョン（`156.0.1-1`、`7.1.5-1.el10`、Windows の `157.0`）は実行日によって変わる。
>
> 鍵の fingerprint（Mozilla・RPM Fusion・EPEL）は公開情報なので本文に書いてある。プロファイルや保存されたパスワードには触れない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### Firefox: 実施前の状態

AlmaLinux 10 の実機（2026-09-21）。Windows 11 の PC は、[Windows 11 で使う](../windows-setup.md#firefox)の手順 2 で確かめる。

| 項目 | 状態 |
|---|---|
| Firefox | `firefox-140.15.0-1.el10_2.aarch64`（appstream）。`firefox --version` は `Mozilla Firefox 140.15.0esr` |
| AppStream の候補 | `140.10.1-1.el10_2` 〜 `140.15.0-1.el10_2`（ESR 140 系のみ。Rapid Release は無い） |
| 有効な追加リポジトリ | epel、crb、raspberrypi（mozilla はまだ無い） |
| Flatpak | `flatpak-1.16.0` は導入済みだが**リモートが 1 つも登録されていない**（flathub 無し） |
| 鍵 | `rpm -q gpg-pubkey` に Mozilla の鍵は無し |

rpmfusion.md と手順 8〜11 の前の実機（2026-09-28）。2026-09-25 に OS を入れ直し、Firefox は手順 5 で入れ直してある:

| 項目 | 状態 |
|---|---|
| Firefox | `firefox-156.0.1-1.aarch64`（mozilla） |
| FFmpeg | `/usr/lib64/libavcodec*` が無い |
| 有効な追加リポジトリ | mozilla・crb・raspberrypi など。**EPEL と RPM Fusion は無い** |
| プロファイル | `~/.config/mozilla/firefox`（`~/.mozilla` は無い）。Cisco の OpenH264（`gmp-gmpopenh264`）はまだ落ちていない |

rpmfusion.md と手順 8〜11 の前の x86_64 の実機（2026-09-28）:

| 項目 | 状態 |
|---|---|
| Firefox | `firefox-156.0.1-1.x86_64`（mozilla）と `firefox-l10n-ja` |
| FFmpeg | `/usr/lib64/libavcodec*` が無い |
| 有効な追加リポジトリ | mozilla・epel・crb など。**EPEL は入れ済み（鍵も登録済み）で、RPM Fusion は無い** |
| プロファイル | `~/.mozilla/firefox`。OpenH264 2.6.0（`gmp-gmpopenh264`）と Widevine（`gmp-widevinecdm`）は落ちてきている。利用者が DRM の再生（`media.eme.enabled`）を有効にしている |
| `gpg` | このユーザーでは使ったことが無く、`~/.gnupg` が無い |

#### Firefox: 選択した方針

**最新版であることの確認**:

AlmaLinux 10 で Firefox の最新版を使う経路を比べた（2026-09-22 時点）:

- Mozilla の `product-details` が返す `LATEST_FIREFOX_VERSION` は `156.0.1`、`FIREFOX_ESR` は `140.16.0esr`（2026-09-22）
- リポジトリの `firefox` 156.0.1 は、Rapid Release の最新と一致する

- Mozilla の Linux 版 Firefox は、AAC と H.264 のデコーダを持っていない
  - 同梱の FFmpeg（`libmozavcodec.so`、62.29.101）に入っているデコーダは、flac・mp3・vorbis・opus・pcm だけだった（[付録](#firefox-付録-動画が再生できなかった件の切り分け2026-09-28)）
  - AAC と H.264 は、OS の `libavcodec.so.53`〜`.63` を探して読み込む。AlmaLinux 10 の標準リポジトリには FFmpeg が無い
- そのため、音声が AAC しか無い YouTube の動画は再生できない。同じ動画が、Windows の Firefox では再生できた（利用者の報告）
  - YouTube は「ご利用のブラウザではこの動画を再生できません。」と出す（[x86_64 の付録](#firefox-付録-x86_64-の実機での本実行2026-09-28)で再現した）
- YouTube の動画には、720p 以上が H.264 だけのときがある（VP9 は 360p だけ。2 本の動画で見た）
  - H.264 を復号できない Firefox では、360p までしか選べない
  - 1 本は、14 分後に読み直すと VP9 が各解像度に揃っていた（[x86_64 の付録](#firefox-付録-x86_64-の実機での本実行2026-09-28)）
- H.264 は、Firefox が起動後に自動で落とす Cisco の OpenH264（GMP プラグイン）でも再生できる。AAC を補えるのは FFmpeg だけ
  - ただし x86_64 の実機では、OpenH264 が落ちてきているのに、利用者の Firefox で 1080p を選べず 360p のままだった
  - 同じ時刻の一時プロファイルでは、OpenH264 で H.264 の 1080p60 を再生できた。違いの原因は分かっていない
  - FFmpeg を入れると、H.264 は OpenH264 を使わずに FFmpeg で復号される

FFmpeg のライブラリの入れ方を比べた（2026-09-28 時点。aarch64 のコンテナで Firefox 156.0.1 を動かして確かめた）:

Windows 11 で Firefox を入れる経路を比べた（2026-10-03 時点。winget の定義は [付録](windows-setup.md#firefox-付録-windows-11-の配布物と資料の調査2026-10-03)）:

| Flathub の `org.mozilla.firefox` | Mozilla 公式ビルド。ただしこのホストは flatpak にリモートが 1 つも登録されておらず、flathub の追加と ~150 MB の runtime 導入から始まる。RPM と二重管理になる | 不採用（RPM で足りる） |

| winget の `Mozilla.Firefox` に `--locale ja` | 137.0.1 までは言語ごとのインストーラ（`InstallerLocale`）が 51 あったが、137.0.2 から英語（en-US）だけになり、言語ごとに `Mozilla.Firefox.<言語>` に分かれた。言語の無いインストーラは、`--locale` を付けると候補から外れるので、入らないはず（winget のソースで読んだだけ） | 不採用 |

#### Firefox: 完了時点の状態

AlmaLinux 10 の実機（2026-09-21）。Windows 11 は流していないので、記録は無い（入るものはこの節の最後の箇条書き）。

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' firefox
firefox 156.0-1 mozilla
$ firefox --version
Mozilla Firefox 156.0
$ rpm -qi firefox | sed -n '/^Vendor/p;/^Build Date/p'
Build Date  : Wed Sep  9 20:41:48 2026
Vendor      : Mozilla
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i mozilla
gpg-pubkey-d98f0353-55a94004 Mozilla Software Releases <release@mozilla.com> public key
```

- 入るファイル: 本体は `/usr/lib/firefox/`、起動スクリプトは `/usr/bin/firefox`、`.desktop` は `/usr/share/applications/firefox.desktop`
- 本体の場所は AppStream 版（`/usr/lib64/firefox/`）と違うが、起動スクリプトと `.desktop` は同じパスなので、アプリ一覧やデフォルトブラウザの設定はそのまま引き継がれる
- 2026-09-25 に入れ直した実機では、プロファイルは `~/.config/mozilla/firefox` に作られた（`~/.mozilla` は無い）

rpmfusion.md と手順 8〜11 の後（コンテナ、2026-09-28）:

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' ffmpeg-libs rpmfusion-free-release epel-release
epel-release 10-6.el10 extras

ffmpeg-libs 7.1.5-1.el10 rpmfusion-free-updates

rpmfusion-free-release 10-1 @commandline

$ ls /usr/lib64/libavcodec.so.*
/usr/lib64/libavcodec.so.61
/usr/lib64/libavcodec.so.61.19.101
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i fusion
gpg-pubkey-db85ddd7-67a63d8b RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org> public key
```

- 有効なリポジトリに `epel` と `rpmfusion-free-updates` が加わる（`rpmfusion-free-updates-testing` の repo ファイルも置かれるが、無効）
- about:support の「コーデックサポート情報」では、H264・HEVC・AAC の「ソフトウェアデコーディング」が「対応」になる（[手順 11 の補足](../almalinux-setup.md#firefox)）

実機（2026-09-28、利用者が手順どおりに入れた後）:

```
$ rpm -q ffmpeg-libs rpmfusion-free-release epel-release
ffmpeg-libs-7.1.5-1.el10.aarch64
rpmfusion-free-release-10-1.noarch
epel-release-10-6.el10.noarch
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i -E 'fusion|epel'
gpg-pubkey-db85ddd7-67a63d8b RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org> public key
gpg-pubkey-e37ed158-65785fa9 Fedora (epel10) <epel@fedoraproject.org> public key
```

- RPM Fusion の有効化で、CRB の `selinux-policy-extra` と `selinux-policy-targeted-extra` も入っている（[rpmfusion.md 手順 3 の補足](almalinux-setup.md#rpm-fusion-実施手順--手順-3-補足-署名の確認とepel-を前提にした理由)）

x86_64 の実機（2026-09-28、rpmfusion.md の手順 1〜3 と手順 8 を実行した後の手順 10）:

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' ffmpeg-libs rpmfusion-free-release epel-release
epel-release 10-8.el10_2 epel

ffmpeg-libs 7.1.5-1.el10 rpmfusion-free-updates

rpmfusion-free-release 10-1 @commandline

$ ls /usr/lib64/libavcodec.so.*
/usr/lib64/libavcodec.so.61
/usr/lib64/libavcodec.so.61.19.101
```

- EPEL が前から入っていたホストなので、`epel-release` の版と `from_repo` はコンテナと違う
- EPEL の `noopenh264` も入っている（[手順 8 の補足](../almalinux-setup.md#firefox)）

Windows 11 で入るもの（winget の定義・Mozilla の文書・Firefox のソースから。Windows では確かめていない）:

- 本体: `C:\Program Files\Mozilla Firefox`。「アプリと機能」の名前は `Mozilla Firefox (x64 ja)`
- サービス: `MozillaMaintenance`（Mozilla Maintenance Service）
- タスク スケジューラの `\Mozilla\`: `Firefox Default Browser Agent <番号>`（インストーラが作る）と `Firefox Background Update <番号>`（Firefox を起動すると作られる）
- ショートカット: デスクトップ・スタートメニュー（ふつうのものとプライベート ブラウジングのもの）・タスクバーのピン留め
- プロファイル: `%APPDATA%\Mozilla\Firefox`（設定・ブックマーク・パスワード）と `%LOCALAPPDATA%\Mozilla\Firefox`（キャッシュ）。ユーザーごとに作られる
- 更新のための作業場所: `C:\ProgramData\Mozilla-1de4eec8-1241-4177-a864-e594e8d1fb38`（Firefox のソースの `commonupdatedir.cpp`）

#### Firefox: 注意点 / 手順 0: 本文中の記録

  - DRM の要る動画は、FFmpeg を入れても直らない（DRM の動画そのものは試していない）

#### Firefox: 参照

- [Install Firefox on Linux — Mozilla Support](https://support.mozilla.org/en-US/kb/install-firefox-linux) — 公式のインストール経路の一覧
- [Introducing Mozilla's Firefox Nightly .rpm package — Firefox Nightly News](https://blog.nightly.mozilla.org/2026/01/19/introducing-mozillas-firefox-nightly-rpm-package-for-rpm-based-linux-distributions/) — RPM リポジトリの repo ファイルの書き方（RHEL / CentOS / Rocky 向けの `tee` の例）と鍵の fingerprint
- [Firefox Developer Edition and Beta: Try out Mozilla's .rpm package! — Mozilla Hacks](https://hacks.mozilla.org/2026/03/firefox-developer-edition-and-beta-try-out-mozillas-rpm-package/) — beta / devedition チャンネルの追加
- [firefox_versions.json — Mozilla product-details](https://product-details.mozilla.org/1.0/firefox_versions.json) — その時点の最新版と ESR の版を機械可読で返す
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 手順 8 の前提（「EPEL と RPM Fusion」の手順 2〜5 の RPM Fusion（free））。鍵の照合と有効化。RPM Fusion の Configuration・keys のページへのリンクは同書の参考資料
- [Multimedia — RPM Fusion](https://rpmfusion.org/Howto/Multimedia) — `ffmpeg-free` からの切り替え（`dnf swap`）と、`libavcodec-freeworld` の位置づけ
- `man dnf.conf`（`priority`、`gpgcheck`、`repo_gpgcheck`）
- [Full Installer Configuration — Firefox Source Docs](https://firefox-source-docs.mozilla.org/browser/installer/windows/installer/FullConfig.html) — Windows のフルのインストーラのスイッチと既定（場所・ショートカット・Maintenance Service・Default Browser Agent・`/PreventRebootRequired`）
- [Background Updates — Firefox Source Docs](https://firefox-source-docs.mozilla.org/toolkit/mozapps/update/docs/BackgroundUpdates.html) — 閉じている間の更新のタスクと、それが動く条件（Maintenance Service・言語パック）
- [Default Browser Agent — Firefox Source Docs](https://firefox-source-docs.mozilla.org/toolkit/mozapps/defaultagent/default-browser-agent/index.html) — インストーラが作るタスクの中身
- [Set Default — Firefox Source Docs](https://firefox-source-docs.mozilla.org/widget/windows/shell/set-default.html) — Windows で既定のブラウザーにするしかたと UCPD
- Firefox のソース（`release` の枝、2026-10-03）— `browser/installer/windows/nsis/installer.nsi`・`uninstaller.nsi`・`shared.nsh`・`postupdate_helper.nsh`（入れるもの・消すもの・アンインストールの登録）、`dom/media/platforms/wmf/WMFDecoderModule.cpp`（H.264 と AAC の Media Foundation の復号器）、`media/ffvpx/libavcodec/codec_list.c`（同梱の FFmpeg の復号器）、`toolkit/mozapps/update/common/commonupdatedir.cpp`（更新の作業場所）
- [winget-pkgs の `Mozilla.Firefox.ja`](https://github.com/microsoft/winget-pkgs/tree/master/manifests/m/Mozilla/Firefox/ja) — winget の定義（`Mozilla.Firefox` は同じ場所の 1 つ上）
- winget-cli のソース（2026-10-02）— `src/AppInstallerCommonCore/Manifest/ManifestComparator.cpp`（`--locale`）、`src/AppInstallerCLICore/Workflows/UninstallFlow.cpp` と `src/AppInstallerRepositoryCore/Microsoft/ARPHelper.cpp`（アンインストールのコマンドの選び方）
- [Windows で既定のアプリを変更する — Microsoft サポート](https://support.microsoft.com/ja-jp/windows/apps/change-default-apps-in-windows) — 設定の「既定のアプリ」と「既定に設定」
- MDN の [Web video codec guide](https://developer.mozilla.org/en-US/docs/Web/Media/Guides/Formats/Video_codecs)・[Web audio codec guide](https://developer.mozilla.org/en-US/docs/Web/Media/Guides/Formats/Audio_codecs) — Firefox は AVC と AAC を OS の復号器に頼る
- [Windows 11 の初期設定](../windows-setup.md) — この文書の Windows 11 の節の前に通す手順書

#### Firefox: 付録: コンテナでの検証記録（2026-09-22）

実機の設定に触れずに手順を通すため、`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで実行した。実機で加えた変更は `dnf install podman` だけ。 最後にもう 1 つ新しいコンテナを立て、**この文書のコードブロックをそのまま抜き出したスクリプト**（`sudo` を外し、`dnf install` / `dnf upgrade` に `-y` を付けただけ）を流して、上から順に貼れば通ることを確かめている。

手順ごとの結果:

| 手順 | 結果 |
|---|---|
| 2〜3. 鍵 | `gpg --show-keys` の fingerprint が `14F26682D0916CDD81E37B6D61B7B526D98F0353` と一致。`rpm --import` は期限切れ副鍵の warning を出して成功、`gpg-pubkey-d98f0353-55a94004` が登録された |
| 4. repo | メタデータ取得に成功。`firefox` は `154.0.1-1` / `155.0-1` / `155.0.1-1` / `156.0-1` / `156.0.1-1` の 5 世代が aarch64・x86_64 の両方で見えた |
| 5. install | ESR 140.15.0 が入った状態から `dnf upgrade -y firefox` で `156.0.1-1` に載せ替え。追加の依存パッケージ無し |
| 6. 検証 | `firefox --version` → `Mozilla Firefox 156.0.1`、`rpm -qi` の `Signature` は `Key ID 678e455d76767aa3`（Mozilla の署名用副鍵） |
| 言語パック | 未導入のコンテナで `dnf install -y firefox firefox-l10n-ja` → `firefox 156.0.1-1 mozilla` と `firefox-l10n-ja 156.0.1-1 mozilla` が入る |
| ロールバック | repo ファイルを消して `dnf --assumeno distro-sync firefox` → `Downgrading firefox 140.15.0-1.el10_2 appstream` 1 パッケージ |

途中で 1 度、`packages.mozilla.org` の名前解決がコンテナ内でタイムアウトして `dnf` がメタデータ取得に失敗した（`Curl error (6): Could not resolve host`）。同じコマンドの再実行で通ったので、リポジトリ側ではなく一時的なものと判断している。

##### Firefox: 未確認事項

- 実機の GUI で 156 系を起動したあとの `about:support` の記載（実機では常用しているが、`about:support` の内容を記録していない）
- `firefox-esr`（Mozilla の ESR 153 系）と `firefox-beta` の導入、および AppStream の ESR 140 との共存
- 日本語以外の言語パック、`firefox-devedition`
- ロールバック（`distro-sync` によるダウングレード）の本実行と、その後のプロファイルの読み込み
- Flathub 版との併用時の挙動（`.desktop` の重複、既定ブラウザの選択）

#### Firefox: 付録: 動画が再生できなかった件の切り分け（2026-09-28）

AlmaLinux 10 の Firefox（Mozilla 版 156.0.1）で YouTube の一部の動画が再生できず、同じ動画は Windows の Firefox では再生できた（利用者の報告）。原因を切り分け、RPM Fusion の有効化と手順 8〜11（当時はどちらもこの文書の手順で、手順 8〜14）をコンテナで確かめた記録。

**動画の形式**: watch ページの `ytInitialPlayerResponse` にある `adaptiveFormats` を `curl` で読んだ。同じ日に 2 回読んだところ、形式が変わっていた:

| 読んだとき | 映像 | 音声 |
|---|---|---|
| 1 回目 | 各解像度に H.264（`avc1.4d40xx`）と VP9 | **AAC（itag 140、`mp4a.40.2`）だけ** |
| 2 回目 | 720p 以上は H.264（`avc1.6400xx`）だけ、VP9 は 360p だけ | AAC と Opus（itag 251） |

1 回目の形式では、AAC を復号できない Firefox は音声を再生できない。2 回目の形式なら、FFmpeg が無くても Opus で音声を再生でき、映像は VP9 の 360p か、OpenH264 が落ちていれば H.264 になる。

**Firefox の中身**（実機の `/usr/lib/firefox`）:

- `libmozavcodec.so` を Python の ctypes で読み込んで調べた。`avcodec_version` は 62.29.101、`av_codec_iterate` で列挙したデコーダは `flac mp3 libvorbis pcm_alaw pcm_f32le pcm_mulaw pcm_s16le pcm_s24le pcm_s32le pcm_u8 libopus` だけ
- `libxul.so` の文字列にある読み込み先は、`libavcodec.so.53`〜`libavcodec.so.63` と `libavcodec-ffmpeg.so.56`〜`58`
- 実機には `/usr/lib64/libavcodec*` が無く、プロファイルに OpenH264（`gmp-gmpopenh264`）も無かった

**調べ方**:

- headless の Firefox を `--marionette -remote-allow-system-access` で起動し、Python の標準ライブラリだけで書いた Marionette のクライアントから、ページでスクリプトを動かした（一時プロファイルを使い、日本語 UI にした）
- 素材は RPM Fusion の `ffmpeg` で作った: 3 秒の AAC の m4a、断片化した AAC の m4a、H.264 Main + AAC の mp4、VP9 + Opus の webm、Opus の webm
- 調べたのは次の 5 つ
  - about:support の「コーデックサポート情報」
  - `OfflineAudioContext.decodeAudioData` での AAC の復号
  - MSE（`MediaSource`。YouTube と同じ再生の仕方）での AAC の再生
  - `<video>` での H.264 + AAC の mp4 の再生
  - YouTube の同じ動画（2 回目の形式）がどの形式で再生されるか（`getStatsForNerds().codecs`）
- コンテナは podman（rootless）の `docker.io/library/almalinux:10`（aarch64、2026-09-02 のイメージ）。Firefox は手順 2〜5 と同じ方法で入れた

**結果**:

| 状態 | about:support の H264 / AAC | AAC の復号 / MSE | H.264 + AAC の mp4 | YouTube |
|---|---|---|---|---|
| 実機、何も足さない | 未対応 / 未対応 | `EncodingError` / `addSourceBuffer` が `NotSupportedError` | `NotSupportedError` | — |
| コンテナ、何も足さない（起動直後） | 未対応 / 未対応 | 実機と同じ | `NotSupportedError` | — |
| コンテナ、何も足さない（OpenH264 2.6.0 が落ちた後） | 未対応 / 未対応 | 実機と同じ | 映像は再生された | H.264 1080p60（itag 299）+ Opus で再生された |
| コンテナ、EPEL の `libavcodec-free` 7.1.2 | 対応 / 対応 | 再生できた | `Couldn't open avcodec`（OpenH264 が落ちた後も同じ） | — |
| コンテナ、`ffmpeg-libs` 7.1.5（Firefox を起動し直す前） | 未対応 / 未対応 | 入れる前と同じ | 映像は再生された（OpenH264） | — |
| コンテナ、`ffmpeg-libs` 7.1.5（起動し直した後） | 対応 / 対応（HEVC も対応） | 再生できた | 再生できた | H.264 1080p60（itag 299）+ Opus で再生された |

- OpenH264 2.6.0 は、Firefox を起動して 1 分ほどでプロファイルの `gmp-gmpopenh264` に落ちてきた（`media.gmp-gmpopenh264.enabled` は既定で true）
- 何も足さない状態でも、起動直後は `MediaSource.isTypeSupported('audio/mp4; codecs="mp4a.40.2"')` が true を返した（`addSourceBuffer` は失敗する）。しばらく後は false になった
- EPEL の `libavcodec-free` では、`media.ffmpeg.allow-openh264`（既定で true）により H.264 が `noopenh264` に回る。about:support の「対応」は、復号できることを意味しない
- `ffmpeg-libs` を入れた後、Firefox のプロセスが `/usr/lib64/libavcodec.so.61.19.101` を読み込んでいることを `/proc/<pid>/maps` で確かめた

**文書どおりに通るか**: 新しいコンテナで `gnupg2` だけ先に入れ、この文書の `## 実施手順` の bash ブロックを抜き出したスクリプトを流した。変えたのは、`sudo` を外したことと、`dnf install` に `-y` を付けたことだけで、条件付きの手順 9 は外した。

| 手順 | 結果 |
|---|---|
| 1〜6 | `firefox` と `firefox-l10n-ja` の `156.0.1-1` が入った（197 パッケージ、ダウンロード 226 MB） |
| rpmfusion.md 1・2. 鍵 | fingerprint が `5FC4AE73FC2B08B9DFE7EB990C8489D8DB85DDD7` と一致。`rpm --import` は何も表示せず、`gpg-pubkey-db85ddd7-67a63d8b` が登録された |
| rpmfusion.md 3. リポジトリ | `rpmfusion-free-release 10-1` と、依存の `epel-release 10-6.el10`、弱い依存の `dnf-plugins-core` の 3 パッケージ |
| 8. FFmpeg | `ffmpeg-libs 7.1.5-1.el10` ほか 79 パッケージ（ダウンロード 42 MB、展開後 137 MB）。EPEL の鍵 `0xE37ED158` の取り込みが 1 回あった |
| 9. 衝突 | 別のコンテナで、EPEL の `libavcodec-free` を入れてから手順 8 を実行すると `conflicts with libswresample-free` で止まった。`dnf install --allowerasing ffmpeg-libs` で `libavcodec-free`・`libavutil-free`・`libswresample-free` の 3 つが外れて入れ替わった |
| 10〜11. 確認 | `ffmpeg-libs 7.1.5-1.el10 rpmfusion-free-updates` と `/usr/lib64/libavcodec.so.61`。起動した Firefox で、about:support の H264・HEVC・AAC が「対応」になり、AAC と H.264 の再生も通った |
| ロールバック 1 と rpmfusion.md のロールバック 1〜2 | ロールバックの手順 1 で 78 パッケージ・119 MB が消えた（手順 8 で入ったもののうち `glibc-gconv-extra` だけが残った）。rpmfusion.md のロールバックの手順 1 は `rpmfusion-free-release` の 1 つだけで、`epel-release` と `dnf-plugins-core` は残った。その手順 2 で `gpg-pubkey-db85ddd7-67a63d8b` が消えた |

**x86_64**: `dnf --forcearch=x86_64` で `ffmpeg-libs.x86_64 7.1.5-1.el10` が見えた。空の installroot に `ffmpeg-libs` を入れる解決が、238 パッケージで通った（導入・起動はしていない）。

##### Firefox: 未確認事項

- 実機（Raspberry Pi 5）への導入と、画面での再生（手順 11 の GUI の確認）
- x86_64 での導入と再生（メタデータのみ）
- 音声が AAC だけの YouTube の動画の再生（YouTube の形式が変わったので、MSE で AAC を流すテストで代えた）
- コマンドの `ffmpeg-free` が入っているホストでの切り替え（RPM Fusion の案内では `dnf swap ffmpeg-free ffmpeg --allowerasing`）
- ハードウェアでの復号（about:support ではすべて「未対応」だった）
- DRM（Widevine）の要る動画
- AppStream の ESR 140 に戻したときに、`~/.config/mozilla/firefox` のプロファイルを読むか

#### Firefox: 付録: 実機での本実行（2026-09-28）

前の付録の後、利用者が実機（2026-09-25 に入れ直した Raspberry Pi 5）で手順どおりに入れ、再生できなかった動画が再生できるようになった。前の付録の未確認事項のうち、実機への導入と再生はこれで済んだ。

**`dnf history`**（時刻は実機の JST）:

| ID | 日時 | コマンド | 結果 |
|---|---|---|---|
| 19 | 2026-09-28 02:13 | `--setopt=localpkg_gpgcheck=1 install https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-10.noarch.rpm` | Success。`rpmfusion-free-release`・`epel-release`（extras）・`selinux-policy-extra`・`selinux-policy-targeted-extra`（crb）の 4 パッケージ |
| 20 | 2026-09-28 02:15 | `install ffmpeg-libs` | Success（7 秒）。60 パッケージ（EPEL 44・AppStream 10・RPM Fusion 4・BaseOS 2） |

- rpmfusion.md 手順 2 の RPM Fusion の鍵（`gpg-pubkey-db85ddd7-67a63d8b`）と、手順 8 で取り込まれた EPEL の鍵（`gpg-pubkey-e37ed158-65785fa9`）が登録されていた
- `libavcodec-free` は入っておらず、`--allowerasing` の実行も無い（手順 9 は要らなかった）
- `dnf repoquery --installed --qf '%{name} %{reason}'` では、`selinux-policy-extra` が `weak-dependency`、`selinux-policy-targeted-extra` が `dependency`。`epel-release` の Recommends の `(selinux-policy-epel if selinux-policy)` を、`selinux-policy-extra` が `selinux-policy-epel` を提供して満たしている

**入れた後の Firefox**（一時プロファイルの headless の Firefox を、前の付録と同じプローブで調べた。利用者のプロファイルには触れていない）:

- about:support の「コーデックサポート情報」は、H264・HEVC・AAC の「ソフトウェアデコーディング」が「対応」。「ハードウェアデコーディング」はすべて「未対応」
- `decodeAudioData` で AAC を復号でき、MSE で AAC を流せた。H.264 + AAC の mp4 も再生できた
- Firefox のコンテンツプロセス 2 つが `/usr/lib64/libavcodec.so.61.19.101` を読み込んでいた

##### Firefox: 未確認事項

- 音声が AAC だけの YouTube の動画での再生（例の動画は、実機に入れる前に YouTube 側で Opus が足されていた）
- 画面に出した about:support の表示（headless の Firefox でだけ確かめた）
- x86_64 での導入と再生（メタデータのみ）

#### Firefox: 付録: x86_64 の実機での本実行（2026-09-28）

x86_64 の実機（AMD Strix Halo のノート PC）で、YouTube の動画 2 本について利用者から報告があった。1 本目は 360p から上げられず、2 本目は再生できなかった。Firefox は手順 1〜7 の mozilla 版で、FFmpeg は入れていなかった。原因を切り分け、RPM Fusion の有効化（今の AlmaLinux 10 の初期設定の「EPEL と RPM Fusion」の手順 2〜4）と、手順 8・10 のコマンド（当時はこの文書の手順 8〜12 と手順 14）を実行した記録（時刻は JST）。

**動画の形式**: 前の付録と同じく、watch ページの `adaptiveFormats` を `curl` で読んだ。どちらもライブ配信のアーカイブで、配信が終わったのは 1 本目が前日の 21:40、2 本目が当日の 02:40:

| 動画 | 読んだとき | 映像 | 音声 |
|---|---|---|---|
| 1 本目 | 02:40 | H.264 は 144p・360p・720p・720p60・1080p60。**VP9 は 360p だけ** | AAC（itag 140）と Opus（itag 251） |
| 1 本目 | 02:54 | H.264 と VP9 が 144p〜1080p60 に揃った | AAC と Opus（itag 249・250・251） |
| 2 本目 | 03:00 | H.264 と VP9 が 144p〜1080p60 に揃っている | **AAC（itag 140）だけ** |

- 1 本目の 02:40 の形式で 360p より上を選ぶには、H.264 を復号できなければならない
- 2 本目は、AAC を復号できなければ再生できない

**利用者の Firefox の状態**（02:40 ごろ。プロファイルとプロセスを読んだだけで、Firefox には触れていない）:

- `/usr/lib64/libavcodec*` が無い
- プロファイルには OpenH264 2.6.0 と Widevine が落ちてきている
- RDD プロセスが読み込んでいたのは同梱の `libmozavcodec.so` だけで、OpenH264 の GMP プロセスは立っていなかった

**FFmpeg を入れる前の再現**: 前の付録と同じく、一時プロファイルの headless の Firefox を Marionette で動かした。OpenH264 が落ちてきた後に起動し直してから調べた。

| 条件 | H.264 の `isTypeSupported` | YouTube の画質の選択肢 | 再生された形式 |
|---|---|---|---|
| 1 本目（02:44） | true | 1080p・720p・360p・144p | 1080p を選ぶと H.264 1080p60（itag 299）+ Opus。コマ落ち 0。GMP プロセスが `libgmpopenh264.so` を読み込んだ |
| 1 本目、利用者の拡張機能 7 つを既定の設定で足した（02:49） | true | 同じ | H.264 1080p60（itag 299）が選ばれた。Enhancer for YouTube が自動再生を止め、再生は始まらなかった |

- Enhancer for YouTube は `MediaSource.isTypeSupported` を包む。形式を隠すのは「60fps 以上を使わない」（`blockhfrformats`）と「WebM を使わない」（`blockwebmformats`）を有効にしたときだけで、利用者の設定ではどちらも false だった
- DRM を有効にして Widevine を落とした一時プロファイルでも、H.264 の `isTypeSupported` は true だった（02:56。FFmpeg を入れた後で、`media.ffmpeg.enabled` を false にして試した）
- 利用者のプロファイルの YouTube の localStorage は、`yt-player-performance-cap` が空で、`yt-player-quality` が 1080 だった
- SELinux の拒否と、Firefox のクラッシュの記録は無かった
- 利用者の Firefox だけが H.264 を使わなかった理由は分からなかった。一時プロファイルとの違いで確かめていないのは、YouTube へのログインと、画面のある（headless でない）Firefox であること

**入れた記録**: dnf は `--assumeno` で表を確かめてから、`-y` を付けて実行した。

| 手順 | 結果 |
|---|---|
| rpmfusion.md 1. 鍵 | fingerprint と uid が一致。このユーザーは `gpg` を初めて使ったので、`~/.gnupg` を作ったという 2 行が先に出た |
| rpmfusion.md 2. 鍵 | `rpm --import` は何も表示せず、`gpg-pubkey-db85ddd7-67a63d8b` が登録された |
| rpmfusion.md 3. リポジトリ | `rpmfusion-free-release 10-1` の 1 パッケージだけ。`epel-release`・`selinux-policy-extra`・`selinux-policy-targeted-extra`・`dnf-plugins-core` は入っていた |
| 8. FFmpeg | `ffmpeg-libs 7.1.5-1.el10` ほか 62 パッケージ（ダウンロード 40 MB、展開後 128 MB）。`noopenh264` も入った。EPEL の鍵は登録済みで、確認は出なかった |
| 9 | 要らなかった（`libavcodec-free` が無い） |
| 10. 確認 | `ffmpeg-libs 7.1.5-1.el10 rpmfusion-free-updates` と `/usr/lib64/libavcodec.so.61` |

**入れた後の確認**（一時プロファイルの headless の Firefox。利用者のプロファイルには触れていない）:

- about:support の「コーデックサポート情報」は、H264・HEVC・AAC の「ソフトウェアデコーディング」が「対応」になった
- `decodeAudioData` で AAC を復号でき（5.06 秒、48 kHz、2 ch）、MSE の `addSourceBuffer` も AAC で通った
- H.264（High）+ AAC の mp4（MDN のサンプルの `flower.mp4`、960x540）が最後まで再生された（150 フレーム、コマ落ち 0）
  - このとき、RDD とユーティリティのプロセスが `/usr/lib64/libavcodec.so.61.19.101` と、`noopenh264` の `/usr/lib64/libopenh264.so.2.4.1` を読み込んだ
  - OpenH264 の GMP プロセスは立たなかった
- 1 本目は、VP9 1080p60（itag 303）+ Opus で再生された（02:54。VP9 が揃った後なので、H.264 は使われていない）
- 2 本目は、VP9 1080p60（itag 303）+ **AAC（itag 140）** で再生された（03:02。23 秒まで再生して 1,381 フレーム、コマ落ち 0）
  - FFmpeg を切った一時プロファイル（`media.ffmpeg.enabled` が false）では、YouTube が「ご利用のブラウザではこの動画を再生できません。」を出した（03:01）
- 利用者が Firefox を起動し直した後（03:02 に起動）、その RDD とユーティリティのプロセスも `/usr/lib64/libavcodec.so.61.19.101` を読み込んでいた

##### Firefox: 未確認事項

- 起動し直した利用者の Firefox での、2 本の動画の画面での再生と about:support の表示
- 利用者の Firefox で、OpenH264 があるのに H.264 が使われなかった理由
- YouTube（MSE）の H.264 を FFmpeg で復号すること（x86_64。1 本目は、FFmpeg を入れた時点で VP9 が揃っていた）
- ハードウェアでの復号（このホストには VA-API のドライバ `mesa-va-drivers` が入っていない）

#### Firefox: 付録: x86_64 の実機での画面の確認（2026-09-28）

前の付録の後、利用者が Firefox を起動し直し、2 本の動画が画面で再生できることを確かめた（利用者の報告）。前の付録の未確認事項のうち、画面での再生はこれで済んだ。

##### Firefox: 未確認事項

- 画面に出した about:support の表示（headless の Firefox でだけ確かめた）
- 利用者の Firefox で、OpenH264 があるのに H.264 が使われなかった理由
- YouTube（MSE）の H.264 を FFmpeg で復号すること（x86_64）
- ハードウェアでの復号

---

#### Firefox: 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を新規に入れた x86_64 の VirtualBox VM（1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で確認した。シェルのブロックは手順書から抜き出して、検証用ユーザーの SSH の対話シェルへ個別に貼った。GUI はヘッドレスの GNOME に 1920x1080 の仮想モニターを付け、既存の `scripts/gnome-gui.py` を変更せずコピーして、操作の後に撮った PNG を見た。利用者のアカウントは使っていない。

実施手順 1〜8・10・11 を本実行した。手順 8 が衝突せず通ったため、条件付きの手順 9 は省略した。AppStream の ESR `140.16.0-1.el10_2` から Mozilla の `157.0-1` と `firefox-l10n-ja-157.0-1` に載せ替わり、Vendor と導入元は Mozilla。GUI の `about:support` は日本語で、更新チャンネル `release`、実行ファイル `/usr/lib/firefox/firefox-bin`、H264 と AAC のソフトウェアデコーディング「対応」だった。

前提の EPEL と RPM Fusion free もこの VM で通し、`ffmpeg-libs-7.1.5-1.el10` を入れた。隔離した検証プロファイルの GUI（headless オプション無し）で、MDN の `flower.mp4`（H.264 High + AAC LC、960x540）をローカルから再生した。画面に花の動画が写り、Marionette で `paused=false`・`error=null`、復号フレームが 8 → 750 に増えたことを確認した。`canPlayType` は H.264 と AAC の両方が `probably`。VM には音声の出力デバイスが無く、耳で音を聴く確認とハードウェアデコードはしていない。

動画の形式を調べるためだけに、検証用の `ffmpeg` CLI（6 RPM）も追加した。Firefox の導入手順に必要なのは `ffmpeg-libs` で、CLI は手順の前提に足していない。プローブが `about:support` を読む起動にだけ `--marionette --remote-allow-system-access` を使い、通常の Firefox の設定には足していない。監査ログファイルを指定した AVC の照合は `<no matches>` だった。Windows の節、Web サービスへのサインイン、音声の実出力は未確認。

続けてロールバック 1〜5 を本実行した。`ffmpeg-libs` と検証用 CLI・ほかで使われていない依存が削除され、言語パックを外してから `distro-sync firefox` で `140.16.0-1.el10_2` に戻った。Mozilla の repo と署名鍵も削除できた。新しい版のプロファイルを古い版で開くことは確認せず、動画の確認に使った隔離プロファイルを保持した。

---

#### Firefox: 付録: 現行版の新規 VM での再検証（2026-10-06）

**環境と流し方**: `5da3478` の現行手順を、別のクリーンな AlmaLinux 10.2 Workstation / x86_64 の VM（1 vCPU、SELinux Enforcing、firewalld 稼働、US 配列）で実行した。SSH の一般ユーザーの対話 PTY に折り畳みの外のブロックを手順ごとに貼り、応答とプロンプトを待った。GUI は GNOME 49.4 のヘッドレスセッションに仮想モニターを付け、操作後の PNG を目視した。既存の実機・資格情報は使っていない。

実施手順 1〜8・10 と GUI の起動を実行した。8 が衝突せず通ったため条件付きの 9 は省略した。OS の ESR `140.16.0-1.el10_2` から Mozilla の `157.0-1` / 日本語言語パックに切り替わり、鍵の指紋・導入元・依存関係を確認した。更新も成功し変更は無かった。

codec 確認では、MDN の `flower.mp4`（検証用の ffprobe で H.264 High + AAC LC と確認）を隔離プロファイルの通常 GUI で再生した。花の動画が画面に映り、Marionette で `error=null`、復号フレームが `147` → `656` に増え、再生時刻が進むことを確認した。H.264 / AAC の `canPlayType` は両方 `probably`。追加の AAC デコードは Web Audio で 2 チャンネル・44100 Hz・222970 サンプルになった。ただしこの素材の観測ピークは 0 で、耳で音を聴く試験はしていない。今回の手順 11 はこの実デコード・再生の観測で検証し、codec 導入後の about:support 表の再取得はしていない。

ロールバック 1〜5 を実行し、`ffmpeg-libs`・形式確認のためだけに追加した `ffmpeg` CLI と未使用依存、日本語言語パック、Mozilla repo / 鍵を削除した。`distro-sync` で ESR `140.16.0-1.el10_2` に戻った。隔離プロファイルは古い Firefox で開いていない。ハードウェアデコード、音声の実出力、既定ブラウザー変更、Web サービスへのサインイン、Windows は今回実施していない。

#### Firefox: 手順中の実測・検証状況の記録

- 企業ポリシーで ESR を使っている場合は、この手順を使わない。Mozilla の ESR / Beta の配布は調べたが、導入・更新・ロールバックは未検証

#### Firefox: 手順中の実測・検証状況の記録

- **AAC と H.264 のために足すものは無い**: Windows の Media Foundation で復号する（[Windows 11 で使う](../windows-setup.md#firefox)の手順 4 の補足）。N エディションの Windows では、Media Feature Pack が要るはず（確かめていない）

#### Firefox: 実施手順 / 手順 4: 補足: priority は保険

Mozilla の案内する repo ファイルには `priority` が無い。この環境では `priority=10`（数字が小さいほど優先）を足しているが、**あってもなくても解決結果は変わらなかった**。ESR 140 と最新版 156 では後者のバージョンが高く、dnf はリポジトリの優先度ではなくバージョンで選ぶため:

```
$ dnf install --assumeno firefox          # priority 行を書く前
Installing:
 firefox        aarch64  156.0.1-1   mozilla   107 M
$ printf 'priority=10\n' >> /etc/yum.repos.d/mozilla.repo
$ dnf install --assumeno firefox          # priority=10 を足した後
Installing:
 firefox        aarch64  156.0.1-1   mozilla   107 M
```

#### Firefox: 手順中の検証状況

- **注意**: 画面の名前は、Microsoft のサポートの記事（Edge を既定にする例）と Firefox の日本語の訳から取った。Windows の画面では確かめていない

#### Firefox: 手順中の検証状況

- 既定のブラウザーは、Firefox を外すと Windows が戻す（Microsoft Edge になるはず。確かめていない）。別のブラウザーにするなら、この節の手順 3

#### Firefox: 手順中の検証状況

- **英語版の `Mozilla.Firefox` と同じ `ProductCode`**: winget の定義では、`Mozilla.Firefox` と言語ごとの `Mozilla.Firefox.<言語>`（100 個）の `ProductCode` が、どれも `Mozilla Firefox` になっている。`winget upgrade --all` や UniGet UI の一括の更新で取り違えないかは、確かめていない

#### Firefox: 手順内の実測・検証状況

- **更新のたびに 107 MB 落ちてくる**: 4 週間ごとの Rapid Release なので、従量課金の回線では効いてくる

### Firefox: 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

#### Firefox: 補足

- **aarch64 の Firefox には Widevine が無い**: Firefox 156（aarch64）には `media.gmp-widevinecdm.*` の設定が無く、`media.eme.enabled` も既定で false だった

---

## 統合前の記録: HackGen Console NF（もとは hackgen.md）

もとの `hackgen.md` の検証記録を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の検証記録](windows-setup.md#統合前の記録-hackgen-console-nf-の-windows-11もとは-hackgenmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜5 | 「HackGen Console NF」の手順 1〜5 |
| WezTerm で使う（任意）の 1・2 | （外した。自分用の WezTerm の設定がこのフォントを使う） |
| 更新 1 | 更新の手順 2・3 |
| ロールバック 1 | ロールバックの「端末とエディタを消す」の手順 10 |
| ロールバック 2 | （外した。WezTerm で使う（任意）の戻し方） |

### HackGen Console NF: 補足

#### HackGen Console NF: 操作上の注意と併記されていた記録

   - 違う版なら、この文書の[Windows 11 で使う](../windows-setup.md#hackgen-console-nf)の手順 3 の `$ver` と `$sha256` を、その版の zip で確かめた値に直してから貼る（直さなければ、固定した旧版を再び入れるだけで更新にはならない）

#### HackGen Console NF: 実施手順: 検証状況の記録

> [!WARNING]
> **この実施手順（AlmaLinux 10）は x86_64 のクリーン VM で本実行済み**（2026-10-06）で、コンテナでも検証した。実機では本実行しておらず、aarch64 でも通していない。別の新規 x86_64 VM の WezTerm では日本語・Nerd Font・Powerline の表示を確認した（末尾の GUI 再検証記録）。

#### HackGen Console NF: 実施手順 / 手順 3: 補足: unzip が無いと cask の展開で止まる

素のコンテナ（`unzip` 未導入）で手順 4 を先に実行したときの実測。ダウンロードまでは進み、展開で止まる:

```
==> Fetching downloads for: font-hackgen-nerd
✘ Cask font-hackgen-nerd (2.10.0)
Error: Failure while executing; `/usr/bin/env PATH=/home/linuxbrew/.linuxbrew/opt/unzip/bin:/home/linuxbrew/.linuxbrew/Homebrew/Library/Homebrew/shims/shared:/usr/bin:/bin:/usr/sbin:/sbin unzip -qq -o /home/<USER>/.cache/Homebrew/downloads/6149807b51a48e8d677b9aea249af896c89ec43e04ea53dfb8963f6f86734ed1--HackGen_NF_v2.10.0.zip -d /var/tmp/homebrew-unpack-20260924-2020-whdcjg` exited with 127. Here's the output:
env: ‘unzip’: No such file or directory
Error: font-hackgen-nerd: Download failed for font-hackgen-nerd.
```

- `PATH` の先頭が `/home/linuxbrew/.linuxbrew/opt/unzip/bin` なので、Homebrew の `unzip`（`brew install unzip`）でも足りるはずだが、本書では BaseOS の `unzip`（`unzip-6.0-69.el10`）を入れた
- **Homebrew のインストーラも、AlmaLinux 10 の初期設定の「Homebrew」の手順 1 の依存パッケージも `unzip` を入れない**ので、formula（ボトル）だけ使ってきた環境では、cask を初めて入れるときにここで引っかかる

#### HackGen Console NF: 実施手順 / 手順 4: 補足: Linux ではフォントが ~/.local/share/fonts に入る

cask の定義（`https://formulae.brew.sh/api/cask/font-hackgen-nerd.json`）が示す置き場所は macOS の `~/Library/Fonts` だけだが、Linux の Homebrew は**実行したユーザーの `~/.local/share/fonts`** に置いた。コンテナでの実測:

```
==> Would install 1 cask:
font-hackgen-nerd
==> Fetching downloads for: font-hackgen-nerd
✔︎ Cask font-hackgen-nerd (2.10.0)
==> Installing Cask font-hackgen-nerd
==> Moving Font 'HackGen35ConsoleNF-Bold.ttf' to '/home/<USER>/.local/share/fonts/HackGen35ConsoleNF-Bold.ttf'
==> Moving Font 'HackGen35ConsoleNF-Regular.ttf' to '/home/<USER>/.local/share/fonts/HackGen35ConsoleNF-Regular.ttf'
==> Moving Font 'HackGenConsoleNF-Bold.ttf' to '/home/<USER>/.local/share/fonts/HackGenConsoleNF-Bold.ttf'
==> Moving Font 'HackGenConsoleNF-Regular.ttf' to '/home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf'
🍺  font-hackgen-nerd was successfully installed!
```

- ファイルの実体は `~/.local/share/fonts` に**移動**され、`/home/linuxbrew/.linuxbrew/Caskroom/font-hackgen-nerd/2.10.0/HackGen_NF_v2.10.0/` にはそこを指すシンボリックリンクが残る（Caskroom は 4.3 KB）
- `~/.local/share/fonts` は fontconfig が既定で探す場所なので、設定ファイルを足す必要は無い
- ダウンロードした zip（25 MB）の sha256 は `f8abd483d5edfad88a78ed511978f43c83b43c48e364aa29ebe4a68217474428` で、cask の定義の値と一致した
- zip は `~/.cache/Homebrew/downloads/` に残る（`brew cleanup` で消える）

#### HackGen Console NF: 実施手順 / 手順 5: 補足: fontconfig と、fc-cache が要らなかったこと

- `fc-list` / `fc-match` は fontconfig の `fontconfig` パッケージに入っている
- GNOME のデスクトップには最初から入っているが、素のコンテナには無かったので、検証では `sudo dnf install -y fontconfig`（`fontconfig-2.15.0-7.el10`、依存込み 12 パッケージ）で入れた

**導入直後に `fc-cache` を実行しなくても `fc-list` に出た。** fontconfig はキャッシュとディレクトリの更新時刻を比べて、古ければ読み直す。

- ロールバックでファイルを消したときも、`fc-cache` 無しで `fc-list` から消えた（[ロールバック](../extra/almalinux-setup.md#端末とエディタを消す)）
- 出てこないときは `fc-cache -f` を試す（コンテナで実行でき、終了コード 0 を確認した）

コンテナでの実測:

```
$ fc-list : family style file | grep HackGen
/home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf: HackGen Console NF:style=Regular
/home/<USER>/.local/share/fonts/HackGen35ConsoleNF-Bold.ttf: HackGen35 Console NF:style=Bold
/home/<USER>/.local/share/fonts/HackGenConsoleNF-Bold.ttf: HackGen Console NF:style=Bold
/home/<USER>/.local/share/fonts/HackGen35ConsoleNF-Regular.ttf: HackGen35 Console NF:style=Regular
$ fc-match "HackGen Console NF"
HackGenConsoleNF-Regular.ttf: "HackGen Console NF" "Regular"
$ fc-list "HackGen Console NF" family style fullname postscriptname spacing
HackGen Console NF:style=Regular:fullname=HackGen Console NF Regular:spacing=90:postscriptname=HackGenConsoleNF-Regular
HackGen Console NF:style=Bold:fullname=HackGen Console NF Bold:spacing=90:postscriptname=HackGenConsoleNF-Bold
```

`spacing=90` は fontconfig の `dual`（半角と全角の 2 つの幅を持つ等幅）。全角の文字が半角の 2 倍幅で並ぶ日本語の等幅フォントはこの値になる（[注意点](../extra/almalinux-setup.md#注意点)）。

#### HackGen Console NF: WezTerm で使う（任意） / 手順 2: 補足: wezterm ls-fonts の実測と、Powerline の三角

コンテナでの実測（画面は出していない。`wezterm ls-fonts` は画面無しで動く）:

```
$ wezterm ls-fonts --text 'aあ漢→'
LeftToRight
 0 a    \u{61}       x_adv=8  cells=1  glyph=uni0061#0#0#0#0  ,68   wezterm.font("HackGen Console NF", {weight="Regular", stretch="Normal", style="Normal"})
                                      /home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf, FontConfig
 1 あ    \u{3042}     x_adv=17 cells=2  glyph=cid01454#1       ,14050 wezterm.font("HackGen Console NF", {weight="Regular", stretch="Normal", style="Normal"})
                                      /home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf, FontConfig
 4 漢    \u{6f22}     x_adv=17 cells=2  glyph=cid24652#1       ,20417 wezterm.font("HackGen Console NF", {weight="Regular", stretch="Normal", style="Normal"})
                                      /home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf, FontConfig
 7 →    \u{2192}     x_adv=8  cells=1  glyph=arrowright#0#0#0#0  ,868  wezterm.font("HackGen Console NF", {weight="Regular", stretch="Normal", style="Normal"})
                                      /home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf, FontConfig
```

（`glyph=` の後ろの空白は出力を詰めてある。）

- Nerd Fonts のアイコン（`U+F09B`、GitHub）も同じファイルから引かれた
- Powerline の三角（`U+E0B0`）は `drawn by wezterm because custom_block_glyphs=true` で、**フォントではなく WezTerm 自身が描く**（WezTerm の既定の設定）

#### HackGen Console NF: 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に、日本語と Nerd Fonts のアイコンが 1 つで揃うプログラミング用フォント [HackGen Console NF](https://github.com/yuru7/HackGen) を入れる。eza のアイコンや starship の Nerd Font 前提のプリセット（[AlmaLinux 10 の初期設定](../almalinux-setup.md)）は、端末のフォントに Nerd Fonts のグリフが要る
- **進め方**: どちらも自分のユーザーだけに入れる。**読者が書き換える変数は無い**
  - **AlmaLinux 10**（[実施手順](../almalinux-setup.md#hackgen-console-nf)）: Homebrew の cask `font-hackgen-nerd` で自分の `~/.local/share/fonts` に入れ、fontconfig から見えることを確かめる
  - **Windows 11**（[Windows 11 で使う](../windows-setup.md#hackgen-console-nf)）: 上流の `HackGen_NF_v2.10.0.zip` を、版と sha256 をブロックに書いて確かめてから、`%LOCALAPPDATA%\Microsoft\Windows\Fonts` に置いて自分のユーザーの登録（`HKCU`）に書く。Windows PowerShell 5.1 に貼り、管理者の権限は要らない。[Windows 11 の初期設定](../windows-setup.md)の 1 項目として依頼されたもの
- **状態（AlmaLinux 10）**: **x86_64 のクリーン VM で実施手順を本実行済み（2026-10-06）。コンテナでも検証済み（2026-09-24、x86_64）。実機には入れていない**
  - 2026-10-06: 別の新規 x86_64 VM では実施手順 1〜5、更新、ロールバックを実行し、WezTerm の日本語・Nerd Font・Powerline を画面でも確認した（末尾の GUI 再検証記録）
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**手順 2〜5・[WezTerm で使う（任意）](../almalinux-setup.md#wezterm)・[更新](../almalinux-setup.md#更新)・[ロールバック](../extra/almalinux-setup.md#端末とエディタを消す)を通した
  - **これまでの手順書のコンテナ検証（実機の上の podman）と違い、x86_64 のクラウドホスト上の Docker で行った**（[flatpak.md](../almalinux-setup.md) と同じ環境）
  - 確認したこと:
    - `~/.local/share/fonts` に 4 ファイルが入る
    - `fc-list` / `fc-match` で見える
    - かな・漢字・Powerline・Nerd Fonts のアイコンが入っている
    - WezTerm がこのフォントで文字を描く設定になる（`wezterm ls-fonts`）
    - ロールバックで消える
  - 新規 x86_64 VM では日本語・Nerd Font・Powerline を実際の WezTerm に表示した。字形・太字・行の高さ・アイコンの幅の網羅的な比較はしていない
  - aarch64 でも同じ zip が使われる（cask の定義にアーキごとの分岐が無い）が、aarch64 では通していない
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**:
    - 配布物: `HackGen_NF_v2.10.0.zip` の sha256（3 か所の記録と一致）・中身・ファミリー名（[付録](windows-setup.md#hackgen-console-nf-付録-windows-11-の配布物と資料の調査2026-10-03)）
    - ほかの経路: scoop の個人のバケット（mo-san）と nerd-fonts のバケット、winget の既定のソース
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。[Windows 11 で使う](../windows-setup.md#hackgen-console-nf)の手順 3 のブロックは、Linux の pwsh で偽物の `icacls.exe` とレジストリを使って流した（[付録](windows-setup.md#hackgen-console-nf-付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
  - **確かめていないこと**: Windows で貼ること（すべての手順）、サインインし直した後に設定のフォントの一覧とアプリ（WezTerm と、Windows Terminal などのパッケージのアプリ）で使えること、更新とロールバック、arm64 の Windows

AlmaLinux 10:

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-24 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1） |
| Homebrew | Pi は 2026-09-24 のクリーンインストール後の状態を確かめていない | 7.0.6（[homebrew.md](../almalinux-setup.md) の手順 1〜3 で新規導入） |
| HackGen | 未導入 | `font-hackgen-nerd 2.10.0`（cask） |
| unzip / fontconfig | 未確認 | どちらも未導入だったので `dnf` で入れた（`unzip-6.0-69.el10` / `fontconfig-2.15.0-7.el10`） |
| WezTerm | x86_64 PC に nightly（[wezterm-nightly.md](../almalinux-setup.md#wezterm)） | `wezterm 20260921_051727_5eb03b23`（検証のため wezterm-nightly.md の手順で導入） |

Windows 11（前提にしている環境。ほかの Windows の手順書の実機の記録と同じ PC を想定）:

| 項目 | 値 |
|---|---|
| OS | Windows 11（[Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)の PC は 25H2・26H2）。x64 |
| PowerShell | Windows PowerShell 5.1（管理者でなくてよい） |
| HackGen | 2.10.0（`HackGen_NF_v2.10.0.zip`） |

> [!NOTE]
> AlmaLinux 10 の環境固有の値は**シェル変数**で書いてある。[手順 1](../almalinux-setup.md#hackgen-console-nf) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。Windows 11 の節には変数が無い（版・sha256・パスはブロックに直接書いてある）。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${HACKGEN_FAMILY}` | fontconfig と WezTerm に渡すファミリー名 | `HackGen Console NF`（既定）/ `HackGen35 Console NF` |
>
> 出力例の値は `<USER>`（AlmaLinux 10）/ `<WIN_USER>`（Windows のユーザー名）のプレースホルダで書いてある。バージョン（`2.10.0`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### HackGen Console NF: 実施前の状態

AlmaLinux 10 の検証コンテナ（Windows 11 では流していない）:

| 項目 | 状態 |
|---|---|
| HackGen | 未導入（`~/.local/share/fonts` も無い） |
| Homebrew | 7.0.6（cask は 1 つも入っていない） |
| unzip | 未導入 |
| fontconfig | 未導入（`fc-list` が無い） |

実機の Raspberry Pi 5 には、クリーンインストール前に Homebrew の cask で `font-symbols-only-nerd-font 3.5.1`（記号だけの Nerd Font）が入っていた（[yazi.md](../almalinux-setup.md#yazi) の記録）。Linux の Homebrew で font の cask を使うのは、その前例と同じ形。

#### HackGen Console NF: 選択した方針

AlmaLinux 10 で HackGen Console NF を入れる経路を比べた（2026-09-24 時点）:

Windows 11 で入れる経路を比べた（2026-10-03 時点）:

#### HackGen Console NF: 完了時点の状態

**AlmaLinux 10 の検証コンテナでの出力**（手順 5 の直後。Windows 11 では流していない）:

```
$ brew list --cask --versions font-hackgen-nerd
font-hackgen-nerd 2.10.0
$ ls -la ~/.local/share/fonts
total 51548
drwxr-xr-x 2 <USER> <USER>     4096 Sep 24 22:07 .
drwxr-xr-x 3 <USER> <USER>     4096 Sep 24 22:07 ..
-rw-r--r-- 1 <USER> <USER> 13462380 Dec 29  2024 HackGen35ConsoleNF-Bold.ttf
-rw-r--r-- 1 <USER> <USER> 12922844 Dec 29  2024 HackGen35ConsoleNF-Regular.ttf
-rw-r--r-- 1 <USER> <USER> 13464288 Dec 29  2024 HackGenConsoleNF-Bold.ttf
-rw-r--r-- 1 <USER> <USER> 12922800 Dec 29  2024 HackGenConsoleNF-Regular.ttf
```

4 ファイルで約 50 MB。ファイルの日付は zip の中の日付（2024-12-29）のまま。

#### HackGen Console NF: 付録: コンテナでの検証記録（2026-09-24）

`quay.io/almalinuxorg/almalinux:10` で立てた使い捨てのコンテナ（x86_64 のクラウドホスト上の Docker）に非 root ユーザーを作り、`docker exec` で [Homebrew の導入](../almalinux-setup.md)、手順 2〜5、[WezTerm で使う（任意）](../almalinux-setup.md#wezterm)、[更新](../almalinux-setup.md#更新)、[ロールバック](../extra/almalinux-setup.md#端末とエディタを消す)を通した。実機で加えた変更は無い。実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。検証の準備として、`fontconfig` と `dnf-plugins-core` を `dnf` で、WezTerm を [wezterm-nightly.md](../almalinux-setup.md#wezterm) の手順（COPR `rhel-9-x86_64`。鍵の取り込みを無人で通すため `dnf install -y`）で入れ、WezTerm の設定ファイルは wezterm-nightly.md の最小の例をそのまま置いた。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6` |
| 準備. fontconfig | `fontconfig-2.15.0-7.el10`（依存込み 12 パッケージ）。HackGen を入れる前の `fc-list` は 16 行 |
| 2〜3. unzip | `command -v unzip` が無出力で `unzip は未導入`。`dnf install -y unzip` → `unzip-6.0-69.el10` |
| 4. HackGen | `Moving Font` が 4 行、`font-hackgen-nerd was successfully installed!`。**この手順書を書く前に別のコンテナで `unzip` を入れずに試したときは、展開で `env: ‘unzip’: No such file or directory` になって失敗した**（手順 3 の補足。これが手順 2〜3 を足した理由） |
| 5. 検証 | `brew list --cask --versions` → `font-hackgen-nerd 2.10.0`。`fc-list` に 4 行、`fc-match` は `HackGenConsoleNF-Regular.ttf`。`U+3042` / `U+6F22` / `U+E0B0` / `U+F09B` がすべて `1`。`fc-cache` は実行していない |
| WezTerm で使う | `grep` が `3:config.font = wezterm.font 'Noto Sans Mono'`、`sed` の後は `3:config.font = wezterm.font 'HackGen Console NF'`。`wezterm ls-fonts --text 'aあ漢→'` は 4 文字とも HackGen Console NF。なお準備で置いた最小の例の `Noto Sans Mono` はコンテナに入っておらず、書き換える前は `Unable to load a font specified by your font=...` と出て組み込みの `JetBrains Mono` が Primary だった（本書の手順とは関係ない） |
| 更新 | `Warning: Not upgrading font-hackgen-nerd, the latest version is already installed`、終了コード 0 |
| ロールバック | `Backing up Font` と `Removing Font` が 4 組、`Purging files for version 2.10.0`。`ls` は空、`fc-list` の HackGen は 0 件（`fc-cache` を実行しなくても消えた）。WezTerm の行は `Noto Sans Mono` に戻った |

##### HackGen Console NF: 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での導入
- aarch64 での導入（同じ zip が使われる見込みだが通していない）
- 画面での見た目（字形、太字、行の高さ、Nerd Fonts のアイコンの幅と位置）
- 起動中のアプリ（WezTerm 以外）が、再起動しなくても新しいフォントを見つけるか
- GNOME の端末・VS Code・GNOME の設定などでのフォントの選択（`spacing=90` のフォントが一覧に出るか）
- `HackGen35 Console NF` を `${HACKGEN_FAMILY}` にした場合の手順 5 と WezTerm の節（ファイルは同じ cask で入ることだけ確認した）
- Homebrew を丸ごと消したとき（`uninstall.sh`）に `~/.local/share/fonts` のフォントが消えるか

---

#### HackGen Console NF: 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1・2・4・5（手順 3 は unzip が既存のため条件外）。

**結果**: Homebrew の cask `font-hackgen-nerd` 2.10.0 を入れ、4 つの TTF が `~/.local/share/fonts` に置かれた。`fc-list` と `fc-match` が HackGen Console NF の Regular/Bold を認識し、本文の U+3042・U+6F22・U+E0B0・U+F09B は全て件数 1 だった。

**今回の未確認範囲**: GNOME・WezTerm の画面での見た目、任意設定、Windows の手順、更新・ロールバックは今回確認していない。

#### HackGen Console NF: 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1・2・4・5 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM の SSH 対話 PTY で実行した。unzip が導入済みだったので手順 3 の分岐は不要だった
- Homebrew cask の HackGen 2.10.0 を導入し、4 フォントのファイルと `fc-match` の検索結果を確認した
- GUI アプリでの選択と見え方はこの CLI 検証には含まない。更新・削除も今回は実行していない

---

#### HackGen Console NF: 付録: 現行版の新規 VM の GUI での再検証（2026-10-06）

**環境と流し方**: `5da3478` の現行手順を、別のクリーンな AlmaLinux 10.2 Workstation / x86_64 の VM（1 vCPU、SELinux Enforcing、firewalld 稼働、US 配列）で実行した。SSH の一般ユーザーの対話 PTY に折り畳みの外のブロックを手順ごとに貼り、応答とプロンプトを待った。GUI は GNOME 49.4 のヘッドレスセッションに仮想モニターを付け、操作後の PNG を目視した。既存の実機・資格情報は使っていない。

実施手順 1〜5 を本実行した。既存 unzip への dnf は変更なし。Homebrew cask `font-hackgen-nerd` 2.10.0、4 TTF、`fc-match`、本文の日本語・Powerline・Nerd Font のコードポイントの件数 1 を確認した。WezTerm 設定 `4bdfbf1` の実ウィンドウで日本語を表示し、LazyVim の picker のアイコンと日本語検索結果も正常に描かれた。

更新は最新で変更なし。ロールバック 1 で cask と 4 TTF を削除し、`fc-list` の HackGen 件数 `0` を確認した。この grep の終了 1 は一致なしを示す期待結果である。任意の WezTerm フォント設定の書き換え、Windows と aarch64 は今回実施していない。


#### HackGen Console NF: 実施手順 / 手順 1: 補足: 入るフォントの種類

`${HACKGEN_FAMILY}` は**この文書の中だけで使うシェル変数**で、fontconfig や WezTerm が読む環境変数ではない。

[HackGen（白源）](https://github.com/yuru7/HackGen)は、英数字の Hack と、かな・漢字の源柔ゴシックを合成したプログラミング用の等幅フォント。upstream の README が挙げるファミリーは次の 4 つで、このうち Console の 2 ファミリーには Nerd Fonts のアイコンを足した **NF** 版がある。

| ファミリー | 内容（upstream の README の要約） |
|---|---|
| HackGen | 文字幅が半角 1:全角 2 の通常版。ASCII の英数字記号は Hack、それ以外の記号とかな・漢字は源柔ゴシック |
| **HackGen Console** | Hack の字体を除外せずに全部当てた版。矢印などの多くの記号が半角で出るので、コンソール向け |
| HackGen35 | 通常版の文字幅を半角 3:全角 5 にした版。英数字が大きく出る |
| HackGen35 Console | HackGen Console の文字幅を半角 3:全角 5 にした版 |

本書で入れる Homebrew の cask `font-hackgen-nerd` の中身は、upstream のリリースの `HackGen_NF_v2.10.0.zip` そのもので、**NF 版は Console の 2 ファミリーだけ**が入っている（通常版の NF は無い）。

```
$ unzip -l HackGen_NF_v2.10.0.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  12-29-2024 16:11   HackGen_NF_v2.10.0/
 13462380  12-29-2024 16:04   HackGen_NF_v2.10.0/HackGen35ConsoleNF-Bold.ttf
 12922844  12-29-2024 16:04   HackGen_NF_v2.10.0/HackGen35ConsoleNF-Regular.ttf
 13464288  12-29-2024 16:04   HackGen_NF_v2.10.0/HackGenConsoleNF-Bold.ttf
 12922800  12-29-2024 16:04   HackGen_NF_v2.10.0/HackGenConsoleNF-Regular.ttf
```

Nerd Fonts を含まない版は別の cask `font-hackgen`（HackGen / HackGen Console / HackGen35 / HackGen35 Console の 8 ファイル）にある。本書では入れていない。

### HackGen Console NF: 参考資料から分離した記録

#### HackGen Console NF: 参考資料: 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **Homebrew の cask `font-hackgen-nerd`** | 2.10.0。upstream の最新のタグ（`git ls-remote --tags` で `v2.10.0`）と一致。`brew upgrade` で上がり、`brew uninstall` で消せる。自分のユーザーにだけ入る | **採用**（Homebrew 系の手順書と揃える） |
| GitHub のリリースの zip を手で展開 | `HackGen_NF_v2.10.0.zip` を落として `~/.local/share/fonts` に置けば同じ結果になる（中身は cask と同じ zip で、sha256 も一致）。Homebrew が要らないが、**更新は手作業** | 不採用（Homebrew がある環境では cask で足りる） |
| EPEL / AppStream の RPM | 無い（EPEL と CRB を有効にした状態で `dnf repoquery` の `*hackgen*` / `*HackGen*` と、`--whatprovides` の `font(hackgen)` / `font(hackgenconsolenf)` がどれも 0 件） | — |
| COPR | 無い（COPR の API で `hackgen` を検索して、関係するプロジェクトは 0 件） | — |
| 全ユーザー向け（`/usr/local/share/fonts` に置く） | root で置けば全ユーザーから見えるが、cask は自分のホームに置く。複数ユーザーで使う機会が無いので要らない | 不採用 |

- upstream の README は、Linux 向けの導入手順を書いていない（GitHub のリリースの ttf と、Mac の Homebrew、Windows の Chocolatey を案内している）
- Homebrew の cask も README では Mac 向けとして紹介されているが、Linux の Homebrew でも入った（手順 4 の補足）

| 経路 | 状況 | 採否 |
|---|---|---|
| **上流の zip を版と sha256 を固定して、自分のユーザーに入れる** | 管理者の権限も scoop も要らず、Windows PowerShell 5.1 で動く。更新は手作業 | **採用** |
| scoop の個人のバケット mo-san の `font-hackgen-console-nf` | 同じ zip（sha256 も同じ）で、scoop と UniGet UI で上げられる。ただし、インストールのスクリプトが `Join-Path` に 3 つ以上の引数を渡していて、Windows PowerShell 5.1 の `Join-Path`（`-Path` と `-ChildPath` だけ）では失敗するはず。scoop はそのスクリプトを、`scoop` を打った PowerShell の中で動かす | 不採用（PowerShell 7 が要り、個人の保守） |
| scoop の nerd-fonts のバケット | HackGen は無い | — |
| winget | 既定のソース（winget-pkgs）に HackGen は無い。winget の一覧のサイトには `yuru7.HackGen`（第三者の `dfirr/winget-hackgen` が作り直したインストーラで、PC 全体に入れる）が載っている | 不採用 |
| Chocolatey | 上流の README が Windows 向けに案内している | 不採用（別のパッケージ マネージャーを足し、管理者が要る） |
| PC 全体（`C:\Windows\Fonts`）に入れる | 管理者が要る | 不採用（AlmaLinux 10 と同じく自分のユーザーだけ） |

- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた
  - [Windows 11 の初期設定](../windows-setup.md)（当時は scoop・UniGet UI・Caps Lock・コンテキストメニュー）の依頼の 1 つとして書き、利用者に確かめてここへ置いた

### HackGen Console NF: 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

#### HackGen Console NF: ロールバック

  - `~/.local/share/fonts` は Homebrew の外なので、Homebrew のアンインストーラがこのフォントを消すかどうかは確かめていない

#### HackGen Console NF: 補足

  - ファミリー名は NF 版だけ末尾に ` NF` が付く（`font-hackgen` は入れていないので、両方入れた状態は確かめていない）

  - `spacing=100`（`mono`）のフォントだけを選択肢に出すアプリで選べるかは、確かめていない

- **GNOME の端末や VS Code など WezTerm 以外のアプリ**: それぞれの設定でファミリー名 `HackGen Console NF` を指定することになるが、本書では確かめていない

---

## 統合前の記録: WezTerm（もとは wezterm-nightly.md）

もとの `wezterm-nightly.md` の検証記録を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の検証記録](windows-setup.md#統合前の記録-wezterm-の-windows-11もとは-wezterm-nightlymd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜4 | 「WezTerm」の手順 1〜4 |
| 実施手順 5（SSH のセッションから確かめる） | （外した。この文書はデスクトップで行う） |
| 設定ファイルの 1（最小の例） | （外した。「WezTerm」の手順 5 で自分用の設定を入れる。箇条書きは「WezTerm の設定ファイル」） |
| 更新 1 | 更新のリード（OS の更新で上がる） |
| ロールバック 1・2 | ロールバックの「端末とエディタを消す」の手順 8・9 |

### WezTerm: 補足

#### WezTerm: 実施手順 / 手順 4: 本文中の記録

   - GNOME の端末から `wezterm` で確かめたなら、手順 5 は飛ばす

#### WezTerm: 設定ファイル / 手順 0: 本文中の記録

- 置き場所は次の順で探し、**最初に見つかった 1 つだけ**を読む（[補足: 設定ファイルの探索順序](#wezterm-設定ファイルの探索順序実測)）

#### WezTerm: 設定ファイル / 手順 0: 本文中の記録

  - Windows 11 の探索順はソースと公式の文書で見ただけで、確かめていない（[付録](windows-setup.md#wezterm-付録-windows-11-の配布物と資料の調査2026-10-03)）

#### WezTerm: 設定ファイル / 手順 0: 本文中の記録

- この節の手順 1 は AlmaLinux 10 のもの（bash のブロック。Windows 11 では試していない）

#### WezTerm: ロールバック / 手順 0: 本文中の記録

- ロールバックは、クリーンインストールの x86_64 VM で本実行した（2026-10-06。消えたのは手順 1 の 4 パッケージだけ）

#### WezTerm: 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に [WezTerm](https://wezterm.org/) の nightly ビルドを入れる。AlmaLinux 10 では **dnf 管理で**入れ、以後は `dnf upgrade` で追従できるようにする
- **進め方**: どちらも**読者が書き換える変数は無い**
  - **AlmaLinux 10**（[実施手順](../almalinux-setup.md#wezterm)）: 作者が管理する公式 COPR `wezfurlong/wezterm-nightly` には **EL10 向けのビルドが無い**ので、chroot を `rhel-9-<arch>` と明示して有効化し、EL9 向けビルドをそのまま入れる（chroot は `uname -m` から自動で決まる）
  - **Windows 11**（[Windows 11 で使う](../windows-setup.md#wezterm)）: GitHub の `nightly` のリリースの `WezTerm-nightly-setup.exe`（Inno Setup）を、同じリリースの `.sha256` と比べてから黙って動かし、`C:\Program Files\WezTerm` に入れる。管理者の Windows PowerShell 5.1 に貼る。更新は同じブロックを貼り直す
    - [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)が `C:\Program Files\WezTerm\wezterm.exe` を呼ぶので、その場所に入れる
    - [Windows 11 の初期設定](../windows-setup.md)の後に通す手順書の 1 つ
  - 設定ファイルは `~/.wezterm.lua` か `~/.config/wezterm/wezterm.lua`（Windows 11 では `%USERPROFILE%` の下。[設定ファイル](../almalinux-setup.md#wezterm-の設定ファイル)）
- **状態（AlmaLinux 10）**: **x86_64 の実機（2026-09-21）とクリーンインストールの VM（2026-10-06）で本実行済み**。VM は実施手順 1〜5・CLI と GUI の起動・ロールバックを確認した
  - 2026-10-06: 別の新規 VM で現行手順を再検証した。今回の実施・解除・未実施範囲は[新しい付録](#wezterm-付録-現行版の新規-vm-での再検証2026-10-06)に記録した
  - 確認したこと: ウィンドウの起動・終了まで
  - **aarch64 は未検証**（COPR に `rhel-9-aarch64` はあるので、同じ手順で通る見込み）
  - EL9 向けビルドを EL10 で使う非公式な流用なので、更新で壊れたら[補足: 注意点](../extra/almalinux-setup.md#注意点)を見る
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - 利用者の PC には、nightly の `20260905-153129-092dcf70` が `C:\Program Files\WezTerm` に入っている（[Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)の実機の記録。入れ方の記録は無い）。その PC では、[Windows 11 で使う](../windows-setup.md#wezterm)の手順は上書きになる
  - **確かめたこと**（[付録](windows-setup.md#wezterm-付録-windows-11-の配布物と資料の調査2026-10-03)）:
    - 配布物: 2026-10-03 の `WezTerm-nightly-setup.exe` の sha256 と `.sha256` の一致、Inno Setup 6.7.0 で作られていること、Authenticode の署名が無いこと。同じ日の zip の中の実行ファイルが x64 で、`VCRUNTIME140.dll` を読み込むこと
    - インストーラの定義（`ci/windows-installer.iss`）と作り方（`ci/deploy.sh`・`gen_windows_continuous.yml`）、Inno Setup の文書とソース（引数・終了コード・アンインストールの登録・アンインストーラの動き）、WezTerm のソース（Windows の設定ファイルの探索順、更新の確認）
    - ほかの経路: winget の `wez.wezterm.nightly`（定義の sha256 の直され方）・`wez.wezterm`・`Microsoft.VCRedist.2015+.x64`、scoop の `versions/wezterm-nightly`・`extras/wezterm`、Chocolatey の `wezterm`
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。[Windows 11 で使う](../windows-setup.md#wezterm)の手順 4 と[Windows 11 のロールバック](../extra/windows-setup.md#opensshgit-for-windowsfirefoxwezterm-を外す)の手順 1 のブロックは、Linux の pwsh で偽物のインストーラとレジストリを使って流した（[付録](windows-setup.md#wezterm-付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
  - **確かめていないこと**: Windows で貼ること（すべての手順）、インストーラが黙って入ることと、`PATH`・スタートメニュー・右クリックのメニュー、`VCRUNTIME140.dll` の無い PC と[Windows 11 で使う](../windows-setup.md#wezterm)の手順 3、WezTerm の窓が開くこと、更新（上書き）とアンインストール、arm64 の Windows

AlmaLinux 10 の実機:

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-21 |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64 |
| カーネル | 6.12.0-211.56.1.el10_2 |
| dnf / dnf-plugins-core | 4.20.0 / 4.7.0-10.el10（`dnf copr` サブコマンド） |
| glibc / openssl-libs | 2.39-128.el10_2 / 3.5.8-1.el10_2 |
| デスクトップ | GNOME Shell 49.4 / Wayland セッション |
| 入った WezTerm | `wezterm-20260921_051727_5eb03b23-0.x86_64`（COPR `rhel-9-x86_64` ビルド） |
| SELinux | Enforcing |

Windows 11 の手順が前提にしている環境（ほかの Windows の手順書の実機の記録と同じ PC を想定）:

| 項目 | 値 |
|---|---|
| OS | Windows 11（[Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)の PC は 26H2）。x64 |
| PowerShell | Windows PowerShell 5.1（管理者として実行） |
| ユーザー | Administrators の一員 |
| 今の WezTerm | nightly の `20260905-153129-092dcf70`（`C:\Program Files\WezTerm`） |
| 入る WezTerm | 2026-10-03 の nightly は `20260929-043349-cab25161`（`WezTerm-nightly-setup.exe`、45,473,308 バイト） |

> [!NOTE]
> 出力例の値は `<HOSTNAME>` / `<USER>`（AlmaLinux 10）/ `<WIN_USER>`（Windows のユーザー名）のプレースホルダで書いてある。版（AlmaLinux 10 の `20260921_051727_5eb03b23`、Windows 11 の `20260929-043349-cab25161`）は実行日によって変わる。Windows 11 の節にも変数は無い（入れる先・URL はブロックに直接書いてある）。

手順書全体に関わる理由・実測・落とし穴と調査記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### WezTerm: 実施前の状態

AlmaLinux 10 の実機（2026-09-21）。Windows 11 の PC は、[Windows 11 で使う](../windows-setup.md#wezterm)の手順 2 で確かめる。

| 項目 | 状態 |
|---|---|
| WezTerm | 未導入（`rpm -q wezterm` → not installed。`~/.config/wezterm` / `~/.wezterm.lua` も無し） |
| 有効な追加リポジトリ | epel、crb、COPR 2 件（lazygit / yazi。どちらも `epel-10-$basearch` chroot）、mozilla、gh-cli、claude-code |
| `dnf copr` | `dnf-plugins-core-4.7.0-10.el10` で使える |
| Flatpak | 導入済み、flathub あり（今回は使わない） |
| FUSE2 | `fuse-libs-2.9.9-25.el10`（`/usr/lib64/libfuse.so.2`）あり。AppImage を直接実行できる |
| 依存ライブラリ | `libxcb` 1.17 / `libxkbcommon(-x11)` 1.7 / `libwayland-client` 1.24 / `fontconfig` 2.15 / `mesa-libEGL` 25.2 / `openssl-libs` 3.5.8 — すべて導入済み |
| セッション | `loginctl show-session` → `Type=wayland`、`XDG_CURRENT_DESKTOP=GNOME` |

#### WezTerm: 選択した方針

WezTerm の nightly を Linux に入れる経路は 6 つある。EL10 で使えるかを調べた結果（2026-09-21。Homebrew の行は 2026-10-03）:

| 経路 | EL10 での状況 | 採否 |
|---|---|---|
| **公式 COPR `wezfurlong/wezterm-nightly`** | chroot は `rhel-8` / `rhel-9` / `centos-stream-9` / `fedora-42〜45` / `rawhide` / `opensuse-tumbleweed`（各 x86_64 / aarch64）。**`epel-10` / `rhel-10` は無い**。ただし EL9 向けビルドの依存関係は EL10 ですべて満たせる（下記） | **採用**（chroot を `rhel-9-<arch>` と明示） |
| GitHub Releases の `nightly` タグ | `wezterm-{common,gui,mux-server}-nightly-centos9.rpm` が毎日更新される。EL10 向けは無い。手で `dnf install ./*.rpm` する形になり、更新が自動化されない | 不採用（COPR と同じ EL9 ビルドで、管理面で劣る） |
| AppImage | `WezTerm-nightly-Ubuntu24.04.AppImage` は EL10 で動く（[付録](#wezterm-付録-appimage-の実測)）。ただし更新が止まりがち（2026-08-02 版）で、最新の `Ubuntu26.04` 版は **glibc 2.42 以上を要求して EL10（2.39）では起動しない** | 不採用（dnf で管理できず、最新版が動かない） |
| Flathub `org.wezfurlong.wezterm` | stable のみ。nightly は無い | 不採用 |
| Homebrew の公式 tap `wezterm/wezterm-linuxbrew` | formula は AppImage を `bin/wezterm` に置くだけ。stable は `20240203-110809-5046fc22`、nightly（`--HEAD`）は `WezTerm-nightly-Ubuntu20.04.AppImage` で、2026-03-18 から更新されていない。aarch64 の AppImage は無い（[補足](../reference/almalinux-setup.md#wezterm-homebrew-の-tap-を採らない理由)） | 不採用（nightly が古く、aarch64 に無い） |
| ソースビルド（`cargo build --release`） | 可能だが Rust toolchain と `get-deps` の依存パッケージが要り、更新のたびにビルドする | 不採用 |

**EL9 向けビルドが EL10 で通る根拠**: 実行前に `--assumeno` で依存解決だけ試した。

- COPR を brew に置き換えられないかを、2026-10-03 に調べた。tap の formula と配布物の日付を見ただけで、入れてはいない
- Homebrew の `wezterm` は macOS だけの cask（`wezterm@nightly` も同じ）なので、Linux では公式の tap の formula を名前を全部書いて入れる（`brew install wezterm/wezterm-linuxbrew/wezterm`、nightly は `--HEAD`）
- tap の `Formula/wezterm.rb` は、AppImage を 1 つ落として `bin/wezterm` に置くだけ（`bin.install img => "wezterm"`）
  - stable は `20240203-110809-5046fc22`（tap の最後の更新も 2024-02-03）。自分用の設定は nightly が前提
  - `--HEAD` は `WezTerm-nightly-Ubuntu20.04.AppImage` を指す。GitHub の `nightly` の配布物で、この AppImage の `Last-Modified` は 2026-03-18 だった（`wezterm-gui-nightly-centos9.rpm` は 2026-10-03）
  - COPR の `rhel-9-x86_64` と `rhel-9-aarch64` は、どちらも 2026-10-02 にメタデータが更新されていた（`repomd.xml` の `revision`）
  - nightly の AppImage に aarch64 のものは無い（`*-aarch64.AppImage` は 404）
  - `.desktop` とアイコン、`wezterm-mux-server`、`/etc/profile.d/wezterm.sh` のシェル統合、補完は入らない。AppImage なので FUSE2 も要る（[付録](#wezterm-付録-appimage-の実測)）
  - nightly の更新は `brew upgrade` に乗らず、入れ直す（公式ドキュメント）

Windows 11 で WezTerm の nightly を入れる経路を比べた（2026-10-03 時点。[付録](windows-setup.md#wezterm-付録-windows-11-の配布物と資料の調査2026-10-03)）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **GitHub の `nightly` の `WezTerm-nightly-setup.exe`** | Inno Setup のインストーラ。同じリリースに `.sha256` がある。`C:\Program Files\WezTerm` に入れ、PC 全体の `PATH`・スタートメニュー・右クリックのメニュー・アンインストールの登録を作る。管理者が要る。Authenticode の署名は無い。更新は手作業（同じブロックを貼り直す） | **採用** |
| winget の `wez.wezterm.nightly` | ある（`20260929-043349-cab25161`、Inno Setup、`machine`、依存に `Microsoft.VCRedist.2015+.x64`）。中身は同じ URL のインストーラで、定義の sha256 は winget の bot が 1〜11 日おきに直す。インストーラは毎日作り直されて sha256 が変わるので、直されていない日は一致せずに入らない（2026-09-21 から 10-02 までは直されていなかった） | 不採用（入るかどうかが日による） |
| winget の `wez.wezterm` | stable の `20240203-110809-5046fc22`（2024-02-03）。WezTerm の公式の文書が案内しているのはこれ | 不採用（自分用の設定は nightly が前提） |
| scoop の `versions/wezterm-nightly` | ある（版は `nightly`）。nightly の zip を `~\scoop\apps\wezterm-nightly\current` に展開する。scoop は nightly の版の sha256 を確かめない（`Downloaded files won't be verified.`）。`current` はジャンクションで、SSH のセッションからはたどれない（[Windows の OpenSSH サーバーの scoop のツールを SSH のセッションで使う（任意）](../windows-setup.md#scoop-のツールを-ssh-のセッションで使う任意)） | 不採用（`C:\Program Files\WezTerm` に入らず、確かめられない） |
| scoop の `extras/wezterm`・Chocolatey の `wezterm` | どちらも stable の `20240203-110809-5046fc22`。Chocolatey に nightly は無い | 不採用 |
| nightly の zip（`WezTerm-windows-nightly.zip`） | インストーラと同じ実行ファイル（と `wezterm.pdb`）。どこに展開してもよく、管理者が要らない。`PATH`・スタートメニュー・アンインストールは自分で用意する | 不採用（`C:\Program Files\WezTerm` に置くなら、インストーラと同じことを手で行うことになる） |

#### WezTerm: 完了時点の状態

AlmaLinux 10 の実機の出力（Windows 11 では流していない。Windows 11 で入るものは、[Windows 11 で使う](../windows-setup.md#wezterm)の手順 4 の補足）:

```
$ rpm -q wezterm wezterm-common wezterm-gui wezterm-mux-server
wezterm-20260921_051727_5eb03b23-0.x86_64
wezterm-common-20260921_051727_5eb03b23-0.x86_64
wezterm-gui-20260921_051727_5eb03b23-0.x86_64
wezterm-mux-server-20260921_051727_5eb03b23-0.x86_64
$ dnf -q repoquery --installed --qf '%{name} %{from_repo}\n' 'wezterm*'
wezterm copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly
wezterm-common copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly
wezterm-gui copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly
wezterm-mux-server copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly
$ wezterm --version
wezterm 20260921_051727_5eb03b23
$ wezterm-mux-server --version
wezterm-mux-server 20260921_051727_5eb03b23
$ ldd /usr/bin/wezterm-gui /usr/bin/wezterm /usr/bin/wezterm-mux-server | grep -c 'not found'
0
$ sudo dnf copr list
copr.fedorainfracloud.org/dejan/lazygit
copr.fedorainfracloud.org/lihaohong/yazi
copr.fedorainfracloud.org/wezfurlong/wezterm-nightly
```

`rpm -qi wezterm-gui` の `Build Date` は `Mon 21 Sep 2026 02:21:39 PM JST`、`Vendor` は `Fedora Copr - user wezfurlong`、`Packager` は `Wez Furlong`。

入るファイル（主なもの）:

| パッケージ | ファイル |
|---|---|
| `wezterm-common` | `/usr/bin/wezterm`、`/usr/bin/strip-ansi-escapes`、`/etc/profile.d/wezterm.sh`（bash / zsh のシェル統合。OSC 7 / OSC 133 / user var を出す）、`/etc/bash_completion.d/wezterm`、`/usr/share/zsh/site-functions/_wezterm` |
| `wezterm-gui` | `/usr/bin/wezterm-gui`、`/usr/bin/open-wezterm-here`、`/usr/share/applications/org.wezfurlong.wezterm.desktop`（`Exec=wezterm start --cwd .`）、`/usr/share/icons/hicolor/128x128/apps/org.wezfurlong.wezterm.png`、`/usr/share/nautilus-python/extensions/wezterm-nautilus.py`（`nautilus-python` が無いので効かない） |
| `wezterm-mux-server` | `/usr/bin/wezterm-mux-server` |

#### WezTerm: 設定ファイルの探索順序（実測）

- 一時ディレクトリを `HOME` にして候補ファイルを組み合わせ、`wezterm ls-fonts` の `Primary font` にどのファイルの `font` が出るかで判定した（実際のホームには何も置いていない）
- `strace -f -o ... wezterm ls-fonts` で `wezterm.lua` を含む `openat` を拾うと、試した順番もわかる

| 置いたファイル | 読まれたもの |
|---|---|
| `~/.config/wezterm/wezterm.lua` のみ | それ |
| `~/.config/wezterm/wezterm.lua` + `~/.wezterm.lua` | **`~/.wezterm.lua`**（`.config` 側は `openat` すらされない） |
| `~/.config/wezterm/wezterm.lua` + `${XDG_CONFIG_HOME}/wezterm/wezterm.lua` | **`XDG_CONFIG_HOME` 側**（`~/.config` 側は試されない） |
| 上 2 つ + `~/.wezterm.lua` | `~/.wezterm.lua` |
| + 環境変数 `WEZTERM_CONFIG_FILE` | その環境変数のファイル |
| + `--config-file` | その引数のファイル |
| 何も無し / `-n` | 組み込み既定値（`JetBrains Mono`） |
| `~/.wezterm.lua` が文法エラー | `ERROR ... syntax error` を出して組み込み既定値 |

`strace` の抜粋（`~/.wezterm.lua` が無く、`XDG_CONFIG_HOME` を設定した場合）:

```
"$HOME/.wezterm.lua", O_RDONLY|O_CLOEXEC) = -1
"$XDG_CONFIG_HOME/wezterm/wezterm.lua", O_RDONLY|O_CLOEXEC) = 3
```

**公式ドキュメントのフロー図とは順序が逆**。

- [Configuration Files](https://wezterm.org/config/files.html) の図は、`$XDG_CONFIG_HOME/wezterm/wezterm.lua` → `~/.config/wezterm/wezterm.lua` → `~/.wezterm.lua` の順に見える
- `main` ブランチの `config/src/config.rs`（`load_with_overrides`）は、`~/.wezterm.lua` を先頭に置き、その後に `CONFIG_DIRS`（`XDG_CONFIG_HOME` があればそれ、無ければ `~/.config`）を並べている
- 両方に置いてある環境で「`.config` 側を直したのに反映されない」ときは、これが原因

#### WezTerm: 注意点 / 手順 0: 本文中の記録

- **Windows 11 の実行ファイルは x64 だけ**: インストーラの定義は arm64 の Windows も許す（x64 のエミュレーションで動かす）が、本書では試していない

#### WezTerm: 参照

- [Linux — WezTerm Install](https://wezterm.org/install/linux.html) — 「Installing on Fedora and rpm-based Systems via Copr」と、openSUSE 節の `dnf copr enable wezfurlong/wezterm-nightly <repository>` の形
- [wezfurlong/wezterm-nightly — Copr](https://copr.fedorainfracloud.org/coprs/wezfurlong/wezterm-nightly/) — 対応 chroot の一覧
- [wezterm/wezterm Releases: nightly](https://github.com/wezterm/wezterm/releases/tag/nightly) — centos9 rpm / AppImage / deb
- [dnf-copr(8)](https://dnf-plugins-core.readthedocs.io/en/latest/copr.html) — `enable name/project [chroot]`
- [wezterm/homebrew-wezterm-linuxbrew](https://github.com/wezterm/homebrew-wezterm-linuxbrew) — Homebrew の公式 tap（`Formula/wezterm.rb`）。導入のコマンドは [Linux — WezTerm Install](https://wezterm.org/install/linux.html) の Linuxbrew の節
- [Configuration Files — WezTerm](https://wezterm.org/config/files.html) — 設定ファイルの探索順序（本書の実測とは `~/.wezterm.lua` の優先度が異なる）
- [wezterm/wezterm config/src/config.rs `load_with_overrides`](https://github.com/wezterm/wezterm/blob/main/config/src/config.rs) — 実際の探索順序
- [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm) — 自分用の設定。導入の手順は `docs/install.md`、変える場所は README にある
- [Windows — WezTerm Install](https://wezterm.org/install/windows.html) — Windows のインストーラ（Inno Setup、Program Files と `PATH`）・zip・winget・scoop・Chocolatey
- [wezterm/wezterm ci/windows-installer.iss](https://github.com/wezterm/wezterm/blob/main/ci/windows-installer.iss) — Windows のインストーラの定義（`AppId`・入れる先・`PATH`・右クリックのメニュー）
- [wezterm/wezterm .github/workflows/gen_windows_continuous.yml](https://github.com/wezterm/wezterm/blob/main/.github/workflows/gen_windows_continuous.yml) — nightly の Windows 版のビルドと `.sha256` の作り方
- [Setup Command-Line Parameters — Inno Setup](https://jrsoftware.org/ishelp/topic_setupcmdline.htm) / [Setup Exit Codes](https://jrsoftware.org/ishelp/topic_setupexitcodes.htm) / [Uninstaller Command-Line Parameters](https://jrsoftware.org/ishelp/topic_uninstcmdline.htm) / [Uninstaller Exit Codes](https://jrsoftware.org/ishelp/topic_uninstexitcodes.htm) / [CloseApplications](https://jrsoftware.org/ishelp/topic_setup_closeapplications.htm) — インストーラとアンインストーラの引数と動き
- [Latest supported Visual C++ Redistributable downloads — Microsoft Learn](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist) — `VCRUNTIME140.dll` を入れる再頒布可能パッケージ
- [microsoft/winget-pkgs の wez.wezterm.nightly](https://github.com/microsoft/winget-pkgs/tree/master/manifests/w/wez/wezterm/nightly) — 採らなかった winget の定義
- [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md) — `C:\Program Files\WezTerm\wezterm.exe` を使う手順書
- [Windows 11 の初期設定](../windows-setup.md) — 貼り付けの設定（「貼り付けの設定」の手順 1〜4）と、この文書を通す順

#### WezTerm: 付録: AppImage の実測

採用しなかった経路の記録。GitHub Releases の `nightly` から 2 つの AppImage を `/tmp` に取得し、`--version` だけ実行した（実行後に削除）。

| ファイル | 更新日 | 結果 |
|---|---|---|
| `WezTerm-nightly-Ubuntu24.04.AppImage`（47 MB） | 2026-08-02 | `wezterm 20260802-174340-fa0a1da0`、rc=0 |
| `WezTerm-nightly-Ubuntu26.04.AppImage`（49 MB） | 2026-09-21 | 起動せず、rc=1: `/lib64/libc.so.6: version 'GLIBC_2.42' not found` / `/lib64/libm.so.6: version 'GLIBC_2.43' not found` |

AppImage は「ビルドした Ubuntu の glibc 以上」を要求する。EL10 の glibc は 2.39 なので、Ubuntu 24.04（glibc 2.39）版までしか動かない。その 24.04 版は 1 か月半更新されておらず、この日の COPR ビルド（`20260921`）より古い。FUSE2 が無い環境では `--appimage-extract` で展開して `squashfs-root/AppRun` を実行する。

---

#### WezTerm: 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を新規に入れた x86_64 の VirtualBox VM（1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で確認した。シェルのブロックは手順書から抜き出して、検証用ユーザーの SSH の対話シェルへ個別に貼った。GUI はヘッドレスの GNOME に 1920x1080 の仮想モニターを付け、既存の `scripts/gnome-gui.py` を変更せずコピーして、操作の後に撮った PNG を見た。利用者のアカウントは使っていない。

実施手順 1〜5 とロールバック 1・2 を本実行した。COPR の `rhel-9-x86_64` を明示し、署名鍵の fingerprint を照合してから `20261005_054844_37254829-0` の 4 パッケージを入れた。導入元は COPR、共有ライブラリの未解決は 0、CLI は `wezterm 20261005_054844_37254829`。`ls-fonts | head -5` の broken-pipe panic は既存の補足どおりで、手順 5 の Wayland の起動・即終了は `rc=0`。

desktop エントリから実際の WezTerm を開き、キーボードで `wezterm --version` と打った出力と、IBus で確定した「日本語」を PNG で確認した。ロールバックで消えたのは WezTerm の 4 RPM だけで、COPR の repo ファイルも削除できた。自分用の設定・aarch64・Windows の節はこの VM では通していない。

---

#### WezTerm: 付録: 現行版の新規 VM での再検証（2026-10-06）

**環境と流し方**: `5da3478` の現行手順を、別のクリーンな AlmaLinux 10.2 Workstation / x86_64 の VM（1 vCPU、SELinux Enforcing、firewalld 稼働、US 配列）で実行した。SSH の一般ユーザーの対話 PTY に折り畳みの外のブロックを手順ごとに貼り、応答とプロンプトを待った。GUI は GNOME 49.4 のヘッドレスセッションに仮想モニターを付け、操作後の PNG を目視した。既存の実機・資格情報は使っていない。

実施手順 1〜5、任意の最小設定、更新、ロールバック 1・2 を本実行した。COPR の `rhel-9-x86_64` から 4 RPM の `20261005_054844_37254829-0` が導入され、鍵の指紋、バージョン、未解決ライブラリが無いことを確認した。GNOME Wayland の実ウィンドウを起動し、後から HackGen と `ryo-aoki-pc/wezterm` の `4bdfbf1` の設定で日本語・Nerd Font・Powerline の表示と実 IME 変換を確認した。

現行の `wezterm ls-fonts | head -5` は、先に head が終了して Broken pipe の panic（終了 101）になった。実施手順 4 と最小設定の確認を `sed -n '1,5p'` に替え、パイプを最後まで読む形で両ブロックを再実行した。両方終了 0 で、既定の JetBrains Mono と最小設定の Noto Sans Mono CJK JP をそれぞれ確認した。

更新は変更なし。ロールバックで 4 RPM と COPR repo を削除できた。SSH / WSL / Windows の任意手順、aarch64、全キー割り当ての網羅は今回実施していない。

#### WezTerm: 手順中の実測・検証状況の記録

- **Windows 11 では、stable と nightly が同じ登録を使う**: インストーラの `AppId` が同じなので、PC に入るのはどちらか 1 つ。後から入れた方が上書きするはず（確かめていない）

#### WezTerm: 実施手順 / 手順 1: 補足: chroot を明示する理由

```
$ sudo dnf copr enable wezfurlong/wezterm-nightly
Error: It wasn't possible to enable this project.
Repository 'epel-10-x86_64' does not exist in project 'wezfurlong/wezterm-nightly'.
Available repositories: 'centos-stream-9-x86_64', 'fedora-43-aarch64', 'opensuse-tumbleweed-x86_64', 'fedora-44-aarch64', 'opensuse-tumbleweed-aarch64', 'rhel-9-x86_64', 'fedora-43-x86_64', 'fedora-rawhide-aarch64', 'fedora-42-x86_64', 'fedora-45-x86_64', 'rhel-9-aarch64', 'fedora-45-aarch64', 'fedora-rawhide-x86_64', 'fedora-44-x86_64', 'rhel-8-aarch64', 'centos-stream-9-aarch64', 'rhel-8-x86_64', 'fedora-42-aarch64'

If you want to enable a non-default repository, use the following command:
  'dnf copr enable wezfurlong/wezterm-nightly <repository>'
But note that the installed repo file will likely need a manual modification.
```

#### WezTerm: 選択した方針

```
$ sudo dnf install --assumeno --repofrompath=wzn,https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/rhel-9-x86_64/ wezterm
Dependencies resolved.
 Package                Arch       Version                        Repo     Size
Installing:
 wezterm                x86_64     20260921_051727_5eb03b23-0     wzn     6.4 k
Installing dependencies:
 wezterm-common         x86_64     20260921_051727_5eb03b23-0     wzn     8.2 M
 wezterm-gui            x86_64     20260921_051727_5eb03b23-0     wzn      19 M
 wezterm-mux-server     x86_64     20260921_051727_5eb03b23-0     wzn     6.9 M
Install  4 Packages
```

- インストール後の `ldd` でも、`not found` は 0 だった
- 追加で入ったパッケージは無い（4 パッケージのみ）

#### WezTerm: 手順中の検証状況

- ブラウザで取ると、SmartScreen が警告するはず（本書は `curl.exe` で取る。確かめていない）

#### WezTerm: 実施手順 / 手順 3: 補足: wezterm はメタパッケージ / 取り込まれる鍵

- `dnf repoquery --requires wezterm` に `gcc` / `*-devel` / `make` が並んで見えるのは、同名の **SRPM の BuildRequires** が一緒に表示されているため。x86_64 パッケージには入っていない（`--assumeno` の結果が 4 パッケージだけであることで確認）

### WezTerm: 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

#### WezTerm: 補足

  設定で `term = "wezterm"` にするなら、先に公式ドキュメントの手順で terminfo を入れる（本書では**未実行**）:

---

## 統合前の記録: git-delta（もとは git-delta.md）

もとの `git-delta.md` の検証記録を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の検証記録](windows-setup.md#統合前の記録-git-delta-の-windows-11もとは-git-deltamd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜4 | 「git-delta」の手順 1〜4 |
| lazygit と組み合わせる（任意）の 1 | （外した。自分用の lazygit の設定が delta を使う） |
| 設定ファイル | git-delta の設定ファイル |
| 更新 1 | 更新の手順 2・3 |
| ロールバック 1・3 | ロールバックの「Git の道具を消す」の手順 2・3 |
| ロールバック 2 | ロールバックの「Git の道具を消す」の手順 10 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### git-delta: 補足

#### git-delta: 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 のクリーン VM で実施手順を本実行済み**（2026-10-06）で、実機では本実行していない（[対象と検証環境](#git-delta-対象と検証環境)）。

#### git-delta: 実施手順 / 手順 3: 補足: キー名は小文字に正規化される

git はセクション名とキー名を小文字に正規化して扱う。`interactive.diffFilter` と書いても、`--get-regexp` や `--list` では `interactive.difffilter` と出る。**大文字の `F` を含む正規表現では引っかからない**ので、読み戻しでは小文字を使う。以前の広い正規表現でのコンテナ実測:

```
$ git config --global --get-regexp '^(core\.pager|interactive\.|delta\.|merge\.conflictstyle)'
core.pager delta
interactive.difffilter delta --color-only
delta.navigate true
delta.line-numbers true
delta.side-by-side false
merge.conflictstyle zdiff3
$ cat ~/.gitconfig
[user]
	name = <USER>
	email = <EMAIL>
[core]
	pager = delta
[interactive]
	diffFilter = delta --color-only
[delta]
	navigate = true
	line-numbers = true
	side-by-side = false
[merge]
	conflictstyle = zdiff3
```

- ファイルの中では `diffFilter` のまま残る（git が書き込むときは指定した綴りを使う）
- 値を 1 つだけ取るなら、`git config --global --get interactive.diffFilter` は大文字のままでも通る（こちらは正規表現ではなくキー名の照合で、大小を区別しないため）

#### git-delta: 実施手順 / 手順 4: 補足: パイプに繋ぐとページャは働かない

git は**標準出力が端末のときだけ** `core.pager` を起動する。したがって:

- `git diff` を素で打つ → delta が起動する（端末が要る。本書では未検証）
- `git diff | head` → ページャを通らず、素の unified diff が出る
- `git diff | delta --paging=never` → 明示的に delta に渡しているので色が付く

この手順で 3 番目の形を使っているのはこのため。コンテナでの実測（ANSI エスケープは除いてある）:

```
$ git diff | delta --paging=never | head -12

f.txt
────────────────────────────────────────────────────────────────────────────────

───┐
1: │
───┘
a
b
B
c
d
$ git diff | head -8
diff --git a/f.txt b/f.txt
index de98044..a7bc997 100644
--- a/f.txt
+++ b/f.txt
@@ -1,3 +1,4 @@
 a
-b
+B
```

#### git-delta: lazygit と組み合わせる（任意） / 手順 0: 本文中の記録

- lazygit 0.65.1 の公式設定に合わせて `git.diffRenderers` を使う（2026-10-05 に対象版の資料とソースを確認。TUI での表示は未検証）

#### git-delta: ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**

#### git-delta: 対象と検証環境

- **目的**: AlmaLinux 10 で `git diff` / `git show` / `git log -p` の表示を [delta](https://github.com/dandavison/delta)（シンタックスハイライト付きのページャ）に置き換える。**EPEL にも AppStream にも RPM が無い**
  - Windows 11 でも、Git for Windows の git の表示を delta に置き換える（[Windows 11 で使う](../windows-setup.md#git-delta)）
- **進め方**: Homebrew で入れ、`git config --global` で `~/.gitconfig` に書く。**読者が書き換えるのは冒頭の変数ブロックだけ**
  - Windows 11 は、管理者ではない Windows PowerShell 5.1 で `scoop install delta` を貼り、git の設定は WezTerm の Git Bash に[実施手順](../almalinux-setup.md#git-delta)の手順 1・3 を貼る（`C:\Users\<WIN_USER>\.gitconfig`）
- **状態（AlmaLinux 10）**: **x86_64 のクリーン VM で実施手順を本実行済み（2026-10-06）。コンテナでも検証済み（2026-09-22）。実機には入れていない**
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**[Homebrew の導入](../almalinux-setup.md)と手順 2〜4 を通した
  - 確認したこと: `arm64_linux` のボトルが降りる、`delta 0.19.2` が入る、使い捨てリポジトリの `git diff | delta --paging=never` が色付きで出る、`git config --global --get-regexp` で 6 項目が読み戻せる
  - コンテナで未確認だった `core.pager` 経由のページャ起動（`git diff` を素で打ったときの表示）と `navigate` の `n` / `N` は、2026-10-06 のクリーン VM で確認した（末尾の付録）
  - **実機（Raspberry Pi 5）では本実行していない**（実機の `~/.gitconfig` は `[core] autocrlf` と `[user]` だけのまま）ので、下表の実機列は「この手順を適用した結果」ではなく**現時点の状態**を書いてある
  - 2026-10-05: 手順 3 の空チェックを先頭に移した。一時的な Git 設定ファイルで、3 変数を 1 つずつ空にすると変更が無く、正常時には 6 項目が設定されて既存の別キーは残ることを確認した
  - lazygit 0.65.1 の任意設定は、同版の公式資料とソースに合わせて `git.diffRenderers` に訂正した。TUI での連携は未検証のまま
- **状態（Windows 11）**: **Windows の実機では未検証（2026-10-08 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](windows-setup.md#git-delta-付録-windows-11-の配布物と資料の調査2026-10-08)）:
    - 定義: scoop の main の `delta.json`（0.20.1。x64 の `delta-0.20.1-x86_64-pc-windows-msvc.zip` だけで、`delta.exe` の shim。`depends` と `suggest` は無い）と、winget の `dandavison.delta` 0.20.1（同じ zip で、sha256 も同じ。`Microsoft.VCRedist.2015+.x64` に依存）
    - 配布物: その zip の sha256 と中身、`delta.exe` のインポート表（`VCRUNTIME140.dll` と `api-ms-win-crt-*` がある）。Windows の `delta.exe` は動かしていない
    - delta 0.20.1 のソース: ページャの決まり方と、less が見つからないときに標準出力へ書くこと（`src/utils/bat/output.rs`・`src/env.rs`）、Windows の less の検索履歴の写しの場所（`src/features/navigate.rs`）
    - Git for Windows のソース: `cmd\git.exe`（git-wrapper）が `mingw64\bin`・`usr\bin` を PATH の先頭に足すこと
    - Scoop のソース: `install`・`update`・`uninstall` の表示と、arm64 で x64 の定義を使うこと
    - PowerShell のブロック 6 個: Linux の PowerShell 7.5.3 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。偽物の `scoop`・`delta` と本物の git で、[Windows 11 で使う](../windows-setup.md#git-delta)の手順 2・3、[Windows 11 の更新](../windows-setup.md#scoopwingetwsl-を上げる)、[Windows 11 のロールバック](../extra/windows-setup.md#git-の道具を消す)を流した（[付録](windows-setup.md#git-delta-付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-08)）
  - 関連する確認（この文書の手順ではない）:
    - 自分用の bash の設定の、Windows 11 の実機の Git Bash での検証（ryo-aoki-pc/bash の[2026-10-01 の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-11-の-git-bash-での検証記録2026-10-01)・[2026-10-06 の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-ホストでの設定の再検証2026-10-06)）は、delta を扱っていない（共通の bash 設定は delta を読まない）
    - `~/.gitconfig` が Git Bash・PowerShell 7・cmd で同じファイルになることは、[git.md の検証記録](windows-setup.md#git-付録-windows-11-の-git-bash-での検証記録2026-09-30)で確かめてある
  - **確かめていないこと**:
    - Windows で貼ること（すべての手順）と、`scoop install delta` が作る shim
    - VC++ ランタイムが無い PC での delta の失敗のしかた
    - WezTerm の Git Bash で[実施手順](../almalinux-setup.md#git-delta)の手順 1・3 を貼ること
    - Git Bash と PowerShell の `git diff` が、delta と Git for Windows の less で出ること。色・行番号の見え方と `n` / `N`、`git add -p`
    - [lazygit と組み合わせる（任意）](../almalinux-setup.md#lazygit)の Windows の lazygit
    - 新しい版が出た後の[Windows 11 の更新](../windows-setup.md#scoopwingetwsl-を上げる)と、[Windows 11 のロールバック](../extra/windows-setup.md#git-の道具を消す)
    - arm64 の Windows と、SSH のセッション

AlmaLinux 10:

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| git | `git 2.52.0`（AlmaLinux の RPM） | 同じ（`2.52.0`） |
| delta | **未導入** | `git-delta 0.19.2` → コマンドは `delta` |
| `~/.gitconfig` | `[core] autocrlf` と `[user]` のみ（**delta の設定は書いていない**） | 手順 3 の 6 項目を設定 |
| lazygit | `lazygit 0.65.1`（Homebrew、[lazygit.md](../almalinux-setup.md#lazygit)）。`git.paging` は未設定 | 未導入 |
| 端末 | WezTerm nightly（[wezterm-nightly.md](../almalinux-setup.md#wezterm)） | 無し（pty を与えずに実行） |

Windows 11（前提にしている環境。書いた時点の値で、実機では流していない）:

| 項目 | 値 |
|---|---|
| OS | Windows 11。x64（arm64 は確かめていない） |
| PowerShell | Windows PowerShell 5.1（管理者ではない窓） |
| scoop | main のバケット（2026-10-08 は delta 0.20.1） |
| delta | 0.20.1（`delta-0.20.1-x86_64-pc-windows-msvc.zip`。x64 だけ） |
| VC++ ランタイム | `VCRUNTIME140.dll`（[wezterm-nightly.md の Windows 11 で使う](../windows-setup.md#wezterm)の手順 3） |
| git | Git for Windows（[git.md](../windows-setup.md#git-for-windows)。`C:\Program Files\Git`、PATH には `cmd` だけ） |
| 使うシェル | WezTerm の Git Bash（git の設定を書く・差分を見る）。PowerShell の git も同じ `~/.gitconfig` を読む |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../almalinux-setup.md#git-delta) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${DELTA_NAVIGATE}` | `delta.navigate`。ページャ内の `n` / `N` を変更単位の移動にする | `true`（既定）/ `false` |
> | `${DELTA_LINE_NUMBERS}` | `delta.line-numbers`。差分の左に行番号を出す | `true`（既定）/ `false` |
> | `${DELTA_SIDE_BY_SIDE}` | `delta.side-by-side`。左右 2 面に分けて表示する | `false`（既定）/ `true` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`0.19.2`）は実行日によって変わる。Windows 11 の節に PowerShell の変数は無い（Git Bash に貼る手順 1 の変数は同じ。出力例の Windows のユーザー名は `<WIN_USER>`）。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### git-delta: 実施前の状態

AlmaLinux 10（Windows 11 の PC は、[Windows 11 で使う](../windows-setup.md#git-delta)の手順 2 で確かめる）:

| 項目 | 状態 |
|---|---|
| delta | 未導入 |
| Homebrew | 7.0.6 導入済み |
| git | 2.52.0（RPM）。ページャは既定の `less` |
| lazygit | 0.65.1 導入済み（[lazygit.md](../almalinux-setup.md#lazygit)）。ページャ設定は無し |
| EPEL | 有効。ただし `delta` も `git-delta` も無い |

#### git-delta: 選択した方針

AlmaLinux 10 aarch64 で delta を入れる経路を比べた（2026-09-22 時点）:

#### git-delta: 完了時点の状態

**AlmaLinux 10 の検証コンテナでの出力**（実機では本実行していない。Windows 11 では流していないので、記録は無い）:

```
$ delta --version
delta 0.19.2
$ brew list --versions git-delta
git-delta 0.19.2
$ command -v delta
/home/linuxbrew/.linuxbrew/bin/delta
$ git --version
git version 2.52.0
$ git config --global --get-regexp '^(core\.pager|interactive\.|delta\.|merge\.conflictstyle)'
core.pager delta
interactive.difffilter delta --color-only
delta.navigate true
delta.line-numbers true
delta.side-by-side false
merge.conflictstyle zdiff3
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/git-delta/0.19.2/`（12 ファイル、7.4 MB）。

#### git-delta: 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](../almalinux-setup.md)と手順 2〜4 を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。差分を出すために `/tmp` に 1 ファイルだけの使い捨てリポジトリを作った。[bat](../almalinux-setup.md) を先に入れた同じコンテナなので、依存は取得済みだった。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](../almalinux-setup.md)） |
| 2. git-delta | `Pouring git-delta--0.19.2.arm64_linux.bottle.tar.gz` → `12 files, 7.4MB`。**依存は取得されなかった**（`libgit2` / `oniguruma` / `zlib-ng-compat` は bat で導入済み）。`brew info git-delta` に `Aliases: delta` と出る |
| 3. git の設定 | 6 項目を `git config --global` で設定。**読み戻しで`interactive.difffilter` と小文字化される**ことが分かり、当初書いていた `interactive\.diffFilter` を含む正規表現では 1 行も出なかったため、本文の正規表現を `interactive\.` に直した |
| 4. 検証 | `delta --version` → `delta 0.19.2`。`git diff \| delta --paging=never` でファイル名ヘッダ・行番号・背景色付きの差分を確認。`git diff \| head`（パイプ）では素の unified diff になることも確認 |
| 設定の確認 | `delta --show-config` で実効値（`true-color = false` など）が出ること、`delta --list-syntax-themes` が `dark` / `light` 別に並ぶことを確認 |
| RPM 経路 | `dnf list --available delta git-delta` → `Error: No matching Packages to list`（EPEL を有効にした状態で） |

##### git-delta: 未確認事項

- 実機での本実行（本書は実機に適用していない）
- `side-by-side = true` の表示
- `git add -p`（`interactive.diffFilter`）の表示
- `merge.conflictstyle zdiff3` のコンフリクト表示
- [lazygit と組み合わせる（任意）](../almalinux-setup.md#lazygit)の `git.paging` 設定
- `core.pager` をフルパスにした場合の挙動
- ロールバック（`brew uninstall` と `git config --unset`）の本実行

---

#### git-delta: 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜4と、追加のページャ操作。

**結果**: Homebrew の git-delta 0.20.1 を導入し、6 設定を読み戻した。検証用リポジトリの差分を、パイプと `core.pager` 経由の実際の less 661 の画面で表示し、行番号を確認した。複数ファイルと離れた変更を用意し、`n` で変更へ進み `N` で前へ戻った。最初の目印より前に `N` で進もうとすると `Pattern not found` になる。初回の短いキー試験はこの境界に当たったため、前後の目印がある位置でも確認し直した。

**今回の未確認範囲**: lazygit の delta 連携、side-by-side、merge・interactive.diffFilter の実際の操作、更新・ロールバックは今回確認していない。

#### git-delta: 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜4 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM の SSH 対話 PTY で実行した。delta 0.20.1 の bottle・版・PATH と Git のページャなど 6 設定を確認した
- 使い捨ての Git リポジトリで差分を表示し、ファイル名・行番号と変更行の出力を確認した。実機のリポジトリや資格情報は使っていない
- 更新・削除と任意のテーマ選択はこの再検証では実行していない

#### git-delta: 手順中の実測・検証状況の記録

- この節はコンテナで検証していない（[未確認事項](#git-delta-未確認事項)）

---

## 統合前の記録: Neovim（もとは neovim.md）

もとの `neovim.md` の検証記録を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の検証記録](windows-setup.md#統合前の記録-neovim-の-windows-11もとは-neovimmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 「Neovim」の手順 1 |
| 実施手順 2 | 「Neovim」の手順 2（`checkhealth` の起動は外した） |
| 既定のエディタにする（任意）の 1 | 「Neovim」の手順 4 |
| 設定ファイルの 1（最小の例） | （外した。「Neovim」の手順 3 で自分用の設定を入れる。箇条書きは「Neovim の設定ファイル」） |
| 更新 1 | 更新の手順 2・3 |
| ロールバック 1・2 | ロールバックの「端末とエディタを消す」の手順 3・4 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### Neovim: 補足

#### Neovim: 実施手順 / 手順 1: 補足: ボトルが降りること

ボトルが降りたことの確認（実測、コンテナ）:

```
==> Installing neovim dependency: luajit
==> Pouring luajit--2.1.1788856981.arm64_linux.bottle.tar.gz
==> Installing neovim dependency: tree-sitter
==> Pouring tree-sitter--0.27.0.arm64_linux.bottle.tar.gz
==> Installing neovim
==> Pouring neovim--0.12.5_1.arm64_linux.bottle.tar.gz
```

`brew deps neovim` は `libuv` / `lpeg` / `luajit` / `luv` / `tree-sitter` を返す（実際の導入時は `unibilium` と `utf8proc` も入る）。

#### Neovim: ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**



- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

#### Neovim: 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に [Neovim](https://neovim.io/) の最新版（0.12 系）を入れる
  - AlmaLinux 10 では、EPEL の `neovim` が 0.10.1 で 2 マイナーぶん古いので、Homebrew で入れる
  - Windows 11 では、scoop の main の `neovim` を自分のユーザーに入れる
- **進め方**
  - **AlmaLinux 10**（[実施手順](../almalinux-setup.md#neovim)）: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
  - **Windows 11**（[Windows 11 で使う](../windows-setup.md#neovim)）: 管理者ではない Windows PowerShell 5.1 に貼る。変数は無い。VC++ のランタイムが無ければ、wezterm-nightly.md の Windows 11 の手順 3 を管理者の窓で先に行う
    - PowerShell から起動するツール向けの `EDITOR`・`VISUAL` は、[既定のエディタにする（任意）](../windows-setup.md#neovim-を既定のエディタにする任意)の手順 2・3 でユーザーの環境変数にする（Git Bash では共通の bash 設定が入れる）
- **状態（AlmaLinux 10）**: **実機で本実行済み（2026-09-20）。`0dbb522` の直接追記版の実施手順 1・2 を x86_64 のクリーン VM でも本実行済み（2026-10-06）**。現行版 `5da3478` は、共通 bash 新規導入後の別の VM でも再検証した（末尾の再検証記録）。既存ホストの手動移行は行っていない。
  - 下表のホストで `brew install neovim` を実行し、`neovim 0.12.5_1` が入って常用中
  - [Homebrew の導入](../almalinux-setup.md)と手順 1〜2、[既定のエディタにする](../windows-setup.md#neovim-を既定のエディタにする任意)・[設定ファイル](../almalinux-setup.md#neovim-の設定ファイル)の節は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - 確認したこと: ボトルが降りる、`nvim --version` が出る、`EDITOR` / `VISUAL` が `nvim` になる、`init.lua` を置いた状態で `has("nvim")` が `1` を返す
  - **コンテナでは TUI の起動と `:checkhealth` は確認していない**（端末が無いため、検証時はこの 1 行だけ除いた）
  - **実機には `~/.config/nvim` も `EDITOR` の設定も置いていない**
  - `sudo nvim`・`sudoedit`・`visudo` で開くエディタは、2026-10-02 に x86_64 のコンテナで確かめた（[homebrew.md の付録](almalinux-setup.md#homebrew-付録-sudo-でも使う節のコンテナでの検証記録2026-10-02)）
  - 2026-10-05: 既定のエディタの設定に元値の控えと追記の目印を付け、ロールバックの手順 1 を追加した。一時ファイルで、元値なし・既存値あり・`.bashrc` がリンクの 3 通りを確認し、元値・元の本文・リンクを復元できた（パッケージの導入・削除は未実行）
- **状態（Windows 11）**: **Windows 実機では未検証（2026-10-08 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**:
    - 配布物の定義: scoop の main のバケットの `neovim.json`（2026-10-08 に取得。0.12.5）と、scoop 本体のソースが出すメッセージ（[付録](windows-setup.md#neovim-付録-windows-11-の節の資料と-linux-での確認2026-10-08)）
    - 配布物: `nvim-win64.zip`（sha256 が `neovim.json` の値と一致）の中の `nvim.exe` などが `VCRUNTIME140.dll` を読み込むこと（`objdump -p` のインポート表）
    - PowerShell のブロック 8 個: Linux の PowerShell 7.5.3 の構文解析器（誤り 0）と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査（指摘 0）
    - 偽物の scoop と、ユーザーの環境変数を記録する偽物での模擬（Windows 11 で使うの手順 2〜4・更新・ロールバックの手順 1、既定のエディタにするの手順 2・3）。偽物の scoop のメッセージは scoop 本体のソースから写したもので、実際の scoop の出力ではない
    - 見直しの後に、ブロックを取り出し直して、構文・互換の検査と模擬をやり直した（[付録](windows-setup.md#neovim-付録-windows-11-の節の資料と-linux-での確認2026-10-08)の「最後の確認」）
    - 2 回目の見直しの後にも、ブロックを取り出し直して、構文・互換の検査と模擬をやり直した（[付録](windows-setup.md#neovim-付録-windows-11-の節の資料と-linux-での確認2026-10-08)の「2 回目の見直しの後の確認」）
    - Linux の Neovim 0.12.5（GitHub のリリースの `nvim-linux-x86_64.tar.gz`）で、`nvim --version` の先頭 3 行と、Windows 11 で使うの手順 4 の `stdpath` を書き出す行
  - **確かめていないこと**:
    - Windows で貼ること（すべての手順）と、scoop での導入・更新・削除
    - `VCRUNTIME140.dll` が無いときの表示（何も出さずに終わるか、システム エラーの窓が出るか）
    - Windows の `stdpath` の値と、Windows PowerShell 5.1 から `nvim` に渡る引数
    - `:checkhealth` の表示
    - ユーザーの環境変数 `EDITOR`・`VISUAL` が、新しい窓・WezTerm のタブ・lazygit の `e` キー・`git commit` に効くこと
    - winget の Neovim があるときの止め方、SSH のセッション、arm64 の Windows
    - 自分用の設定（LazyVimStarter）の Windows の導入との組み合わせ
  - 参考: Windows 11 の Git Bash で、共通の bash 設定が `EDITOR`・`VISUAL` を `nvim` にすることは、bash リポジトリの検証記録にある（[2026-10-01 の Git Bash の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-11-の-git-bash-での検証記録2026-10-01)・[2026-10-06 の Windows ホストの付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-ホストでの設定の再検証2026-10-06)）。この文書の手順としては流していない

AlmaLinux 10:

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| 入った Neovim | `neovim 0.12.5_1`（`arm64_linux` ボトル、LuaJIT 2.1.1788856981） | 同じ（`0.12.5_1`） |
| 一緒に入る依存 | `libuv` / `lpeg` / `luajit` / `luv` / `tree-sitter` / `unibilium` / `utf8proc` | 同左 |
| 追加で入れたもの | `tree-sitter-cli 0.27.0`（任意。パーサをソースからビルドする場合に使う） | 無し |

> [!NOTE]
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`0.12.5`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### Neovim: 実施前の状態

AlmaLinux 10 の実機（2026-09-20）。Windows 11 の PC は、[Windows 11 で使う](../windows-setup.md#neovim)の手順 2 で確かめる。

| 項目 | 状態 |
|---|---|
| Neovim / vim | `nvim` 未導入。`vim-minimal`（`vi`）のみ |
| Homebrew | この手順の直前に公式インストーラで導入（`brew install neovim` が最初の formula） |
| EPEL | 有効。`neovim 0.10.1-4.el10_0` が入手できる状態 |
| Node.js / Python プロバイダ | 未導入 |

#### Neovim: 選択した方針

AlmaLinux 10 aarch64 で Neovim の最新版を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `neovim 0.12.5_1` の `arm64_linux` ボトルがある。upstream の最新リリース（v0.12.5、2026-08-23）と一致。依存も同時に入る | **採用** |
| EPEL の `neovim` | `0.10.1-4.el10_0`。2 マイナーぶん古く、0.11 / 0.12 の機能（新しい LSP API など）が無い | 不採用（最新版ではない） |
| 公式 tarball（`nvim-linux-arm64.tar.gz`） | GitHub Releases に aarch64 向けがある。`/opt` に展開して PATH を通すだけ。EL10 の glibc 2.39 で動く見込みだが、更新は手作業 | 不採用（更新が手作業） |
| AppImage（`nvim-linux-arm64.appimage`） | 実行に FUSE が要る（EL10 には `fuse-libs` がある）。更新は手作業 | 不採用 |
| ソースビルド | `make CMAKE_BUILD_TYPE=Release`。依存を自分で揃える必要があり、Raspberry Pi では時間がかかる | 不採用 |

実測（EPEL 有効の状態）:

#### Neovim: 完了時点の状態

AlmaLinux 10 の実機（2026-09-20）。Windows 11 は流していないので、記録は無い（入るものは、[Windows 11 で使う](../windows-setup.md#neovim)の手順 4 の箇条書き）。

```
$ brew list --versions neovim
neovim 0.12.5_1
$ nvim --version | head -3
NVIM v0.12.5
Build type: Release
LuaJIT 2.1.1788856981
$ command -v nvim
/home/linuxbrew/.linuxbrew/bin/nvim
$ brew deps neovim
libuv
lpeg
luajit
luv
tree-sitter
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/neovim/0.12.5_1/`。設定を置くまで `~/.config/nvim` は作られない。

#### Neovim: 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで、非 root ユーザーを作って[Homebrew の導入](../almalinux-setup.md)と手順 1〜2、[既定のエディタにする](../windows-setup.md#neovim-を既定のエディタにする任意)・[設定ファイル](../almalinux-setup.md#neovim-の設定ファイル)の節を通した。実機で加えた変更は `dnf install podman` だけ。 実行したのは**この文書のコードブロックをそのまま抜き出したスクリプト**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。 端末が要る `nvim -c 'checkhealth' -c 'only'` の 1 行だけ除いている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git sudo` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](../almalinux-setup.md)） |
| 1. Neovim | `lpeg` / `luajit` / `luv` / `tree-sitter` / `unibilium` / `utf8proc` / `neovim` の順に `arm64_linux` ボトルを `Pouring`。ソースビルドは発生しない |
| 2. 検証 | `nvim --version` → `NVIM v0.12.5` / `Build type: Release` / `LuaJIT 2.1.1788856981` |
| 既定のエディタ | `~/.bashrc` に追記して読み込み直し、`EDITOR` / `VISUAL` ともに `nvim` |
| 設定ファイル | `~/.config/nvim/init.lua` を置いて `nvim -c 'echo has("nvim")' -c 'q'` → `1` |
| EPEL との比較 | `dnf list --available neovim` → `0.10.1-4.el10_0`（EPEL）。Homebrew 版と 2 マイナーぶんの差 |

##### Neovim: 未確認事項

- TUI の起動と `:checkhealth` の実出力（コンテナに端末が無いため。実機では常用している）
- [設定ファイル](../almalinux-setup.md#neovim-の設定ファイル)と[既定のエディタにする](../windows-setup.md#neovim-を既定のエディタにする任意)の節（実機では `~/.config/nvim` も `EDITOR` の設定も置いていない）
- LSP・プラグインマネージャ（lazy.nvim など）を入れた状態での動作
- 公式 tarball / AppImage 経路の実測
- ロールバック（`brew uninstall`、`brew autoremove`）の本実行

---

#### Neovim: 付録: クリーン VM での検証記録（2026-10-06）

**検証対象**: `0dbb522` の、各手順で `~/.bashrc` などへ設定を直接追記する版。以下の手順番号と「本文」はこの版を指す。検証後に共通 bash 設定へ統一された現行版（`0bc9970`）の設定リポジトリの新規導入・既存設定からの移行は、今回の VM では実行していない。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証対象版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順（`0dbb522`）**: 実施手順 1・2。

**結果**: Homebrew の neovim 0.12.5_1（`NVIM v0.12.5`）を導入し、実際の TUI で `checkhealth` を完了した。エラーは無かった。クリーン状態の `init.lua` 不在、SSH のクリップボード用コマンド不在、Node.js・Perl・Python・Ruby の任意 provider の不足で合計 8 件の警告が出た。診断の内容を取得してから `:q!` で終了した。

**今回の未確認範囲**: 任意のエディタ環境変数・設定ファイル、LazyVim・Mason・LSP・プラグイン、デスクトップのクリップボード、更新・ロールバックはこの VM では確認していない。

#### Neovim: 付録: 現行の共通 bash 設定での再検証（2026-10-06）

- `5da3478` の 実施手順 1 と「既定のエディタにする」手順 1を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で実行した。先に共通 bash `3d5323e` を新規導入した
- Neovim 0.12.5（formula 0.12.5_1）を bottle で導入した。7 個の依存も bottle だった。`EDITOR` / `VISUAL` は nvim、`vi` は nvim のエイリアスになった
- `nvim --clean` の実 TUI でテキストを開き、`:qa` で終了した。個人設定・Mason・検索・整形の検証は [LazyVimStarter の新規 CLI VM 記録](https://github.com/ryo-aoki-pc/LazyVimStarter/blob/custom/docs/verification/setup.md#付録-新規-almalinux-102-vm-での-cli-導入整形の再検証2026-10-06) へ分ける
- 本体の単独 checkhealth の全項目、更新、削除、最小 init.lua の任意節は、この再検証では実行していない

#### Neovim: 選択した方針

```
$ dnf -q list --available neovim
Available Packages
neovim.aarch64                       0.10.1-4.el10_0                        epel
```

#### Neovim: 実施手順 / 手順 2: 補足: :checkhealth の読み方

- ツールの不足: `rg`（ripgrep）、`fd`、`git`、`tree-sitter` など。このホストでは `rg` / `fd` / `git` は入っている（[yazi.md](../almalinux-setup.md#yazi) の依存ツール、および RPM の git）

---

## 統合前の記録: lazygit（もとは lazygit.md）

もとの `lazygit.md` の検証記録を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の検証記録](windows-setup.md#統合前の記録-lazygit-の-windows-11もとは-lazygitmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1（`LG_EDITOR`） | （外した。`e` キーのエディタは `EDITOR` で決まる） |
| 実施手順 2 | 「lazygit」の手順 1 |
| 実施手順 3 | 「lazygit」の手順 3・4 |
| 設定ファイルの 1（最小の例） | （外した。「lazygit」の手順 2 で自分用の設定を入れる。箇条書きは「lazygit の設定ファイル」） |
| 更新 1 | 更新の手順 2・3 |
| ロールバック 1 | ロールバックの「Git の道具を消す」の手順 1 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### lazygit: 補足

#### lazygit: 実施手順 / 手順 2: 補足: ボトルが降りること

aarch64 で降ってくるボトルは `lazygit--0.65.1.arm64_linux.bottle.tar.gz`。

ボトルが降りたことの確認（実測、コンテナ）:

```
==> Downloading bottle manifests
✔︎ Bottle Manifest lazygit (0.65.1)
==> Fetching downloads for: lazygit
✔︎ Bottle lazygit (0.65.1)
==> Pouring lazygit--0.65.1.arm64_linux.bottle.tar.gz
🍺  /home/linuxbrew/.linuxbrew/Cellar/lazygit/0.65.1: 6 files, 18.8MB
```

#### lazygit: ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**

#### lazygit: 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に、git の TUI クライアント [lazygit](https://github.com/jesseduffield/lazygit) の最新版を入れる
- **進め方**
  - **AlmaLinux 10**（[実施手順](../almalinux-setup.md#lazygit)）: Homebrew で入れる
    - **読者が書き換えるのは冒頭の変数ブロック（エディタ）だけ**
    - RPM（COPR）経路は実機でもコンテナでも通らなかった（[選択した方針](../reference/almalinux-setup.md#lazygit-選択した方針)）
  - **Windows 11**（[Windows 11 で使う](../windows-setup.md#lazygit)）: scoop の extras の `lazygit` を、管理者ではない Windows PowerShell 5.1 から自分のユーザーに入れる。extras のバケットが無ければ足す。変数は無い
    - PowerShell から起動したときの `e` キーのエディタは、[neovim.md の既定のエディタにする（任意）](../windows-setup.md#neovim-を既定のエディタにする任意)の手順 2（ユーザーの環境変数 `EDITOR`）に任せる
- **状態（AlmaLinux 10）**: **実機で本実行済み（2026-09-20）**。**x86_64 のクリーン VM でも現行の実施手順を本実行済み（2026-10-06）**
  - 下表のホストで `brew install lazygit` を実行し、`lazygit 0.65.1` が入って常用中
  - [Homebrew の導入](../almalinux-setup.md)と手順 2〜3、[設定ファイル](../almalinux-setup.md#lazygit-の設定ファイル)の節は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した
  - 確認したこと: ボトルが降りる、`lazygit --version` が出る、`config.yml` を書いた後に `lazygit --print-config-dir` が `~/.config/lazygit` を返す
  - **コンテナでは TUI の起動と `e` キーの動作は確認していない**（端末が無いため）
  - **実機には設定ファイルを置いていない**
  - 2026-10-02: [設定ファイル](../almalinux-setup.md#lazygit-の設定ファイル)の手順 1 を、`LG_EDITOR` が空なら何もせずに止める `if … fi` にした
    - それまでは、ヒアドキュメントの中の `${LG_EDITOR:?…}` が `cat` しか止めず（[gnome-power.md 手順 3 の補足](almalinux-setup.md#画面オフロックサスペンド-実施手順--手順-3-補足-ログイン画面の設定の置き場所とgdm-ユーザーで読む理由)）、`>>` が空の `config.yml` を作り、後ろの `lazygit --print-config-dir` も動いた
    - 直した形は、擬似端末の対話の bash にブラケットペースト無しで、変数を空にしたときと値を入れたときの 1 回ずつ貼って確かめた（`HOME` は使い捨てのディレクトリ、`lazygit` はスタブ）
  - 2026-10-05: 既存設定への無条件追記をやめ、エディタの存在も確かめる形にした。一時ディレクトリとスタブで、新規作成・再実行・既存 `os:` ありの 3 通りを確認した（既存内容は変わらず、`os:` は重複しない）。TUI は起動していない
- **状態（Windows 11）**: **Windows 実機では未検証（2026-10-08 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**:
    - 配布物の定義: scoop の extras のバケットの `lazygit.json`（2026-10-08 に取得。0.66.0）と、scoop 本体のソース（`scoop bucket list` がバケットごとに `Name` を持つオブジェクトを返すこと、メッセージ）（[付録](windows-setup.md#lazygit-付録-windows-11-の節の資料と-linux-での確認2026-10-08)）
    - 配布物: `lazygit_0.66.0_Windows_x86_64.zip`（sha256 が `lazygit.json` の値と一致）の `lazygit.exe` が `kernel32.dll` しか読み込まないこと（`objdump -p` のインポート表。VC++ のランタイムは要らない）
    - lazygit 0.66.0 のソース: Windows の設定の場所（`docs/Config.md`）と、`e` キーのエディタの決まり方（`pkg/config/editor_presets.go`・`pkg/commands/git_commands/file.go`）
    - PowerShell のブロック 7 個: Linux の PowerShell 7.5.3 の構文解析器（誤り 0）と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査（指摘 0）
    - 偽物の scoop・lazygit と Linux の git での模擬（Windows 11 で使うの手順 2〜6・更新・ロールバック）。偽物の scoop のメッセージは scoop 本体のソースから写したもので、実際の scoop の出力ではない
    - 見直しの後に、ブロックを取り出し直して、構文・互換の検査と模擬をやり直した（[付録](windows-setup.md#lazygit-付録-windows-11-の節の資料と-linux-での確認2026-10-08)の「最後の確認」）
    - 2 回目の見直しの後にも、ブロックを取り出し直して、構文・互換の検査と模擬をやり直した（[付録](windows-setup.md#lazygit-付録-windows-11-の節の資料と-linux-での確認2026-10-08)の「2 回目の見直しの後の確認」）
  - **確かめていないこと**:
    - Windows で貼ること（すべての手順）と、extras のバケットの追加、scoop での導入・更新・削除
    - `lazygit --version` と `--print-config-dir` の表示、TUI の起動と初回の案内
    - PowerShell から起動したときの `e` キー（ユーザーの環境変数 `EDITOR` の有無と、設定した後に開いた窓で効くこと）
    - 自分用の設定（README の Windows の例）と delta との組み合わせ
    - SSH のセッションと、arm64 の Windows
  - 参考: Windows 11 の Git Bash で、共通の bash 設定が `EDITOR`・`VISUAL` を `nvim` にすること（Git Bash から起動した lazygit の `e` キーが使う）は、bash リポジトリの検証記録にある（[2026-10-01 の Git Bash の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-11-の-git-bash-での検証記録2026-10-01)・[2026-10-06 の Windows ホストの付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-ホストでの設定の再検証2026-10-06)）。lazygit はそこで起動していない

AlmaLinux 10:

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| 入った lazygit | `lazygit 0.65.1`（`arm64_linux` ボトル、6 ファイル / 18.8 MB） | 同じ（`0.65.1`） |
| git | `git-2.52.0-1.el10.aarch64`（RPM） | `git 2.52.0`（依存で導入） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../almalinux-setup.md#lazygit) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${LG_EDITOR}` | lazygit の `e` キーで開くエディタ。[設定ファイル](../almalinux-setup.md#lazygit-の設定ファイル)でだけ使う | `nvim` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`0.65.1`）は実行日によって変わる。`<git リポジトリ>` のような `<...>` を含むコマンドは bash のコードブロックに置いていない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### lazygit: 実施前の状態

AlmaLinux 10 の実機（2026-09-20）。Windows 11 の PC は、[Windows 11 で使う](../windows-setup.md#lazygit)の手順 2 で確かめる。

| 項目 | 状態 |
|---|---|
| lazygit | 未導入（COPR から入れようとして失敗した直後） |
| Homebrew | 7.0.6 導入済み（同じ日の少し前に公式インストーラで導入） |
| git | `git-2.52.0-1.el10.aarch64` 導入済み |
| 有効な追加リポジトリ | epel、crb、raspberrypi、COPR（dejan/lazygit を有効化した状態） |

#### lazygit: 選択した方針

AlmaLinux 10 aarch64 で lazygit の最新版を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `lazygit 0.65.1` の `arm64_linux` ボトルがある。upstream の最新リリース（v0.65.1、2026-09-13）と一致 | **採用** |
| COPR `dejan/lazygit` | `epel-10-aarch64` chroot はあるが、**リポジトリメタデータを取得できない**（`repomd.xml` が 403）。`dnf install lazygit` は `No match for argument` で終わる。実機でも 2 度試して入らなかった | 不採用（入らない） |
| COPR `atim/lazygit` | 同上。`epel-10-aarch64` chroot はあるが `repomd.xml` が 403 | 不採用（入らない） |
| GitHub Releases の tarball | `lazygit_<version>_Linux_arm64.tar.gz` がある。展開して PATH に置くだけだが、更新は手作業 | 不採用 |
| EPEL / AppStream | `lazygit` は無い（`dnf list lazygit` → `No matching Packages to list`） | 使えない |
| `go install` | Go toolchain が要り、更新のたびにビルドする | 不採用 |

**COPR が通らないことの実測**（コンテナ、2026-09-22）。`dnf copr enable` 自体は成功して repo ファイルもできるが、メタデータの取得で落ちる:

#### lazygit: 完了時点の状態

AlmaLinux 10 の実機（2026-09-20）。Windows 11 は流していないので、記録は無い（入るものは、[Windows 11 で使う](../windows-setup.md#lazygit)の手順 5 の箇条書き）。

```
$ brew list --versions lazygit
lazygit 0.65.1
$ lazygit --version
commit=, build date=, build source=Homebrew, version=0.65.1, os=linux, arch=arm64, git version=2.52.0
$ command -v lazygit
/home/linuxbrew/.linuxbrew/bin/lazygit
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/lazygit/0.65.1/`（6 ファイル、18.8 MB）。`commit=` と `build date=` が空なのは Homebrew ビルドの仕様。

#### lazygit: 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで、非 root ユーザーを作って[Homebrew の導入](../almalinux-setup.md)と手順 2〜3、[設定ファイル](../almalinux-setup.md#lazygit-の設定ファイル)の節を通した。実機で加えた変更は `dnf install podman` だけ。 実行したのは**この文書のコードブロックをそのまま抜き出したスクリプト**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git sudo` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](../almalinux-setup.md)） |
| 2. lazygit | `Pouring lazygit--0.65.1.arm64_linux.bottle.tar.gz`（6 files, 18.8MB）。ソースビルドは発生しない |
| 3. 検証 | `lazygit --version` → `build source=Homebrew, version=0.65.1, os=linux, arch=arm64, git version=2.52.0` |
| 設定ファイル | `config.yml` を書いたあと `lazygit --print-config-dir` → `/home/<USER>/.config/lazygit` |
| COPR（`dejan`） | `copr enable` は成功。`dnf install lazygit` はメタデータ 403 → `No match for argument: lazygit` |
| COPR（`atim`） | 同上（403） |
| `curl` での確認 | 両プロジェクトとも `repodata/repomd.xml` が `copr-pulp-prod.s3.amazonaws.com` にリダイレクトされ、HTTP 403 |

実機でも 2026-09-20 に `dnf copr enable dejan/lazygit` → `dnf install lazygit` を 2 度試して入らず（`dnf history` にトランザクションが残っていない）、そのあと `brew install lazygit` に切り替えている。**同じ失敗が 2 日後のコンテナでも再現した。**

##### lazygit: 未確認事項

- TUI からの commit・push・pull（クリーン VM では起動・一覧と差分の表示・終了を確認）
- [設定ファイル](../almalinux-setup.md#lazygit-の設定ファイル)の節（`config.yml` を書いた状態での `e` キーの動作）
- COPR の 403 が解消したあとに `dnf install lazygit` が通るか（通れば RPM 管理に移せる）
- GitHub Releases の tarball 経路
- ロールバック（`brew uninstall`）の本実行

---

#### lazygit: 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜3。

**結果**: Homebrew の lazygit 0.66.0 を導入し、RPM の Git 2.52.0 が使われることを確認した。検証用リポジトリで起動し、初回の案内を Enter で閉じて、変更・未追跡ファイル、ブランチ、コミット、差分の画面を読み、`q` で終了した。捕捉ライブラリが private SGR を受けられず初回の画面読み取りが止まったため、検証補助だけを直して画面を取得し直した。

**今回の未確認範囲**: エディタ連携の設定、自分用の設定、リモートへの push/pull、更新・ロールバックは今回確認していない。

#### lazygit: 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜3 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM の SSH 対話 PTY で実行し、Homebrew の lazygit 0.66.0 の導入・版・PATH・TUI・`q` での終了を確認した
- 個人設定 `ryo-aoki-pc/lazygit` の `custom` (`dc3873e`) も README どおり公開 URL から clone してリンクした。0.66.0 が旧キー 4 個を自動移行し設定ファイルを書き換える問題を再現したため、当該キーを現行名・配置へ修正した。修正後の TUI で再書き換えが無いことと公式 0.66.0 JSON Schema のエラー 0 件を確認した（設定リポジトリ README の記録）
- 実リポジトリへのコミット・push、上流設定更新、パッケージの更新・削除は今回は実行していない

#### lazygit: 選択した方針

```
$ sudo dnf copr enable dejan/lazygit
Repository successfully enabled.
$ sudo dnf install lazygit
Copr repo for lazygit owned by dejan             98  B/s | 333  B     00:03
Errors during downloading metadata for repository 'copr:copr.fedorainfracloud.org:dejan:lazygit':
  - Status code: 403 for https://copr-pulp-prod.s3.amazonaws.com/artifact/...&Expires=1790097163 (IP: 52.217.69.236)
Error: Failed to download metadata for repo '...': Cannot download repomd.xml: ...
Ignoring repositories: copr:copr.fedorainfracloud.org:dejan:lazygit
No match for argument: lazygit
Error: Unable to find a match: lazygit
```

#### lazygit: 実施手順 / 手順 3: 補足: 起動時の注意

- このホストは RPM の git 2.52.0 を使っている

### lazygit: 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

#### lazygit: 実施手順 / 手順 3

   - 初回に `Thanks for using lazygit...` の案内が出たら Enter で閉じる。ファイル・変更差分・ブランチ・コミットの一覧が出ればよい（0.66.0 のクリーン VM で確認）

---

## 統合前の記録: GitHub CLI（もとは gh.md）

もとの `gh.md` の検証記録を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の検証記録](windows-setup.md#統合前の記録-github-cli-の-windows-11もとは-ghmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜5 | 「GitHub CLI」の手順 1〜5 |
| 更新 1 | 更新のリード（OS の更新で上がる） |
| ロールバック 1〜5 | ロールバックの「Git の道具を消す」の手順 4〜8 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### GitHub CLI: 補足

#### GitHub CLI: 実施手順 / 手順 2: 補足: 鍵は 2 本

`githubcli-archive-keyring.asc` には鍵が 2 本入っていて、取り込みも 2 回聞かれる。実測（コンテナ、`-y` 付きで流したときの表示）:

```
Importing GPG key 0x62313325:
 Userid     : "GitHub CLI <opensource+cli@github.com>"
 Fingerprint: 7F38 BBB5 9D06 4DBC B3D8 4D72 5612 B364 6231 3325
 From       : https://cli.github.com/packages/githubcli-archive-keyring.asc
Key imported successfully
Importing GPG key 0x75716059:
 Userid     : "GitHub CLI <opensource+cli@github.com>"
 Fingerprint: 2C61 0620 1985 B60E 6C7A C873 23F3 D4EA 7571 6059
 From       : https://cli.github.com/packages/githubcli-archive-keyring.asc
Key imported successfully
```

実機にも同じ 2 本が `gpg-pubkey-62313325-69d4e1f8` と `gpg-pubkey-75716059-63172e8a` として入っている。

gh 本体は依存の少ないパッケージだが、**git が入っていないホストでは git 一式（`git` / `git-core` / `git-core-doc` / `groff-base` など 13 パッケージ）が付いてくる**。実機は git 導入済みだったので追加は無かった。

#### GitHub CLI: ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**

#### GitHub CLI: 対象と検証環境

- **目的**: AlmaLinux 10 に [GitHub CLI](https://cli.github.com/) の最新版を **dnf 管理で**入れる。EPEL にも `gh` はあるが版が古い
- **進め方**: GitHub が配っている repo ファイルを `dnf config-manager --add-repo` で取り込み、`dnf install gh` する。**読者が書き換える値は無い**
  - Windows 11（[Windows 11 で使う](../windows-setup.md#github-cli)）では、scoop の main のバケットの gh を、管理者ではない Windows PowerShell 5.1 で入れる。トークンは資格情報マネージャーに置き、git の HTTPS の認証は Git for Windows の Git Credential Manager のままにする
- **状態（AlmaLinux 10）**: **実機で本実行済み（2026-09-20）。x86_64 のクリーン VM でも実施手順を本実行済み（2026-10-06、下の付録の範囲）**
  - 下表のホストで `dnf config-manager --add-repo` → `dnf install -y gh` を実行し、`gh-2.101.0-1.aarch64` が入って認証済み、そのまま常用中
  - 本書の手順 1・2 は 2026-09-22 に同じ OS のコンテナで通し直し、鍵 2 本の fingerprint・同じ版の導入・`gh --version` まで確認した
  - **コンテナでは認証（手順 3・4）とロールバックは実行していない**
  - 2026-09-28: もとの手順 2 のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-02: もとの手順 1・2 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）
  - 2026-10-05: 2.101.0 の公式ソースのヘルプ本文で、トークン保存先と `auth logout` の範囲を確認し、ロールバックの手順 1・2 を追加した。認証・ログアウト・失効は実行していない
- **状態（Windows 11）**: **Windows の実機では未検証（2026-10-08 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](windows-setup.md#github-cli-付録-windows-11-の節の資料と-linux-での確認2026-10-08)）:
    - 配布物の定義: scoop の main のバケットの `gh.json`（2026-10-08 に取得。2.102.0）、64bit の zip の sha256（定義と、上流の `gh_2.102.0_checksums.txt` の両方と一致）、`gh.exe` のインポート表と Authenticode の署名者の証明書（Linux で PE を読んだだけ）
    - ソース: gh 2.102.0（ログインの問いと Git の認証の扱い・トークンの置き場所・ログアウト・状態の表示・新しい版の知らせ）、go-gh 2.16.1（設定と状態の場所）、go-keyring 0.2.8（資格情報マネージャーの項目の名前）、Git for Windows の起動スクリプト（`XDG_CONFIG_HOME` を設定しない）、scoop 本体のメッセージ
    - PowerShell のブロック 10 個: Linux の PowerShell 7.5.3 の構文解析器（誤り 0）と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査と既定の規則（指摘 0）
    - 偽物の scoop・gh・Git Credential Manager と、本物の git（使い捨ての `HOME` と `system` の設定）での模擬（Windows 11 で使うの手順 2・3・6、Windows 11 の更新の手順 1、Windows 11 のロールバックの手順 1・3〜6）
  - 関連する確認（Windows 11 の実機の Git Bash。この文書の手順ではない）:
    - 自分用の bash の設定の検証（ryo-aoki-pc/bash の[2026-10-01 の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-11-の-git-bash-での検証記録2026-10-01)）で、利用者の PC の Git Bash の HTTPS の clone に、gh の資格情報を `!gh auth git-credential` の形でそのペインにだけ渡して通した。そのとき、その PC の Git Credential Manager には GitHub の資格情報が無かった（`Found 0 accounts`）
    - 共通の bash 設定は gh を扱わない
  - **確かめていないこと**
    - Windows で貼ること（すべての手順）、scoop での導入・更新・削除
    - `gh auth login` の問いの出方とキー操作、ワンタイムコードのクリップボードへのコピー、ブラウザでの認証、資格情報マネージャーへの保存（`(keyring)` の表示）と、そこに出る項目の名前
    - Git の認証に `Y` と答えたときの動き（ソースからの推論）と、そのときの[Windows 11 のロールバック](../extra/windows-setup.md#git-の道具を消す)の手順 4 で Git Credential Manager の資格情報が消えること
    - Git Bash・PowerShell 7・cmd の gh が同じ設定とログインを使うこと
    - SSH のセッション（scoop の shim と、資格情報マネージャーを読めるか）、arm64 の Windows、winget の gh が入った PC

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| dnf / dnf-plugins-core | 4.20.0 / 4.7.0-10.el10 | 同左 |
| 入った gh | `gh-2.101.0-1.aarch64`（gh-cli リポジトリ） | 同じ（`2.101.0-1`） |
| 依存で入ったもの | 無し（git 2.52.0 は導入済みだった） | `git` / `git-core` など 13 パッケージ |
| 認証 | 済み（常用中） | 未実施 |

> [!NOTE]
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。Windows 11 の値は `<WIN_USER>`（Windows のユーザー名）と `<GITHUB_USER>`（GitHub のアカウント名）。バージョン（`2.101.0`）は実行日によって変わる。
>
> **トークンは書かない。** 鍵の fingerprint は公開情報なので本文に書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### GitHub CLI: 実施前の状態

AlmaLinux 10 の実機（2026-09-20）。Windows 11 の PC は、[Windows 11 で使う](../windows-setup.md#github-cli)の手順 2 で確かめる。

| 項目 | 状態 |
|---|---|
| gh | 未導入 |
| `dnf-plugins-core` | 未導入（`dnf config-manager` が使えない） |
| git | `git-2.52.0-1.el10.aarch64` 導入済み |
| 有効な追加リポジトリ | epel、crb、raspberrypi |

#### GitHub CLI: 選択した方針

AlmaLinux 10 で gh を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **公式 dnf リポジトリ（`cli.github.com/packages/rpm`）** | `gh 2.101.0-1`。upstream の最新リリース（v2.101.0、2026-09-15）と一致。dnf 管理で更新できる | **採用** |
| EPEL の `gh` | `gh 2.97.0-2.el10_2`。4 リリースぶん古い | 不採用（最新版ではない） |
| GitHub Releases の `.rpm` を直接 `dnf install` | 同じバイナリだが、更新のたびに手で落とすことになる | 不採用 |
| Homebrew | 入るが、gh は dnf で入る最新版があるのでわざわざ二重にしない | 不採用 |

実測（EPEL と公式リポジトリを両方有効にした状態）:

#### GitHub CLI: 完了時点の状態

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' gh
gh 2.101.0-1 gh-cli
$ gh --version
gh version 2.101.0 (2026-09-15)
https://github.com/cli/cli/releases/tag/v2.101.0
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i github
gpg-pubkey-62313325-69d4e1f8 GitHub CLI <opensource+cli@github.com> public key
gpg-pubkey-75716059-63172e8a GitHub CLI <opensource+cli@github.com> public key
```

`gh` の実体は `/usr/bin/gh`、bash 補完は `/usr/share/bash-completion/completions/gh`。

#### GitHub CLI: 参照

- [Installing gh on Linux and BSD — cli/cli](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) — dnf4 / dnf5 それぞれの手順と repo ファイルの URL
- [GitHub CLI manual](https://cli.github.com/manual/) — `gh auth login` などのコマンド
- [gh 2.101.0 の login](https://github.com/cli/cli/blob/v2.101.0/pkg/cmd/auth/login/login.go)・[logout](https://github.com/cli/cli/blob/v2.101.0/pkg/cmd/auth/logout/logout.go) — 対象版のヘルプ本文。資格情報ストアと平文保存、ローカル削除とサーバー側の失効を区別する（2026-10-05 にソースを確認。認証の操作は未実行）
- `man dnf.conf`（`gpgcheck`）

#### GitHub CLI: 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで手順 1・2 を通した（手順 3 の `gh auth login` は対話なので除外）。実機で加えた変更は `dnf install podman` だけ。 最後にもう 1 つ新しいコンテナを立て、**この文書のコードブロックをそのまま抜き出したスクリプト**（`sudo` を外し、`dnf install` / `dnf upgrade` に `-y` を付けただけ）を流して、上から順に貼れば通ることを確かめている。

| 手順 | 結果 |
|---|---|
| 1. プラグイン | `dnf-plugins-core-4.7.0-10.el10` が入る |
| 1. repo | `Adding repo from: https://cli.github.com/packages/rpm/gh-cli.repo` → `/etc/yum.repos.d/gh-cli.repo` 作成 |
| 2. install | `Installing: gh aarch64 2.101.0-1 gh-cli 14 M` + 依存 13 パッケージ（`git` / `git-core` / `git-core-doc` / `groff-base` / `authselect` など）。鍵 2 本を取り込んで成功 |
| 検証 | `gh --version` → `gh version 2.101.0 (2026-09-15)`。`gh auth status` → `You are not logged into any GitHub hosts.` |
| EPEL との比較 | `epel-release` を追加して `dnf list --showduplicates gh` → EPEL 2.97.0 と gh-cli 2.101.0 の 2 系統 |

##### GitHub CLI: 未確認事項

- 手順 3・4 の認証（コンテナでは未実施。実機では 2026-09-20 に実行して以後常用）
- `gh auth login` の SSH 鍵方式、`gh auth login --with-token`、GitHub Enterprise Server への接続
- `gh extension install` で入れた拡張の扱い
- ロールバック（`dnf remove` と鍵の削除）の本実行
- dnf5 に移行した場合の `config-manager addrepo` 構文（EL10 では dnf5 が入らないため未検証）

---

#### GitHub CLI: 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1・2。

**結果**: GitHub 公式 RPM リポジトリを追加し、表示された 2 本の署名鍵の fingerprint を本文と比べて取り込んだ。gh 2.102.0 が入り、版と `/usr/bin/gh` を確認した。追加の `gh auth status` は未ログインを示した。

**今回の未確認範囲**: 手順 3・4 のアカウント認証と、更新・ロールバックは今回流していない。

#### GitHub CLI: 付録: 現行版の新規 VM での再検証（2026-10-06）

公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active）で、`5da3478` の本文を SSH 対話 PTY に渡した。試験専用のユーザー・鍵と設定値を使用し、利用者の実アカウントの資格情報は持ち込んでいない。

実施手順 1・2 を通し、公式 repo と文書に載せた 2 本の署名鍵を確認して導入した。gh 2.102.0、`gh auth status` は未ログイン（終了 1）だった。実アカウントの認証、更新・削除はこの再検証で行っていない。端末捕捉補助が問い合わせの処理で待ったため、生ログで版・未ログイン・コマンドの終了を確認し、以後の補助は生出力主体に切り替えた。手順の失敗とは扱わない。

#### GitHub CLI: 実施手順 / 手順 4: 補足: 認証

`gh auth login` は対話で進む。SSH 越しの端末でブラウザを開けない場合は、表示されるワンタイムコードを手元のブラウザの `https://github.com/login/device` に入れる形になる。**この手順はコンテナでは実行していない**（実機では認証済みで常用している）。

#### GitHub CLI: 選択した方針

```
$ dnf -q list --showduplicates gh | tail -5
gh.aarch64                        2.97.0-2.el10_2                        epel
gh.aarch64                        2.101.0-1                              gh-cli
gh.armv6hl                        2.101.0-1                              gh-cli
gh.i386                           2.101.0-1                              gh-cli
gh.x86_64                         2.101.0-1                              gh-cli
```

---

## 統合前の記録: yazi（もとは yazi.md）

もとの `yazi.md` の検証記録を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の検証記録](windows-setup.md#統合前の記録-yazi-の-windows-11もとは-yazimd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1・2 | 「yazi」の手順 1・2 |
| 実施手順 3 | 「yazi」の手順 4（`. ~/.bashrc` で読み直さず、新しいタブで確かめる） |
| 実施手順 4 | 「yazi」の手順 5 |
| 設定ファイルの 1（`mkdir`） | （外した。「yazi」の手順 3 で自分用の設定を入れる。箇条書きは「yazi の設定ファイル」） |
| 更新 1 | 更新の手順 2・3 |
| ロールバック 1 | ロールバックの「端末とエディタを消す」の手順 1 |

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

### yazi: 補足

#### yazi: 操作上の注意と併記されていた記録

- **既定値のファイルは配布物に入っていない**（実測: `brew list yazi` に含まれる `.toml` は `.crates.toml` だけ）

#### yazi: 実施手順 / 手順 2: 補足: ボトルと、依存ツールの役割

aarch64 で降ってくるボトルは `yazi--26.9.1.arm64_linux.bottle.tar.gz`。

| formula | yazi での役割 |
|---|---|
| `ffmpeg-full` | 動画のサムネイル |
| `sevenzip` | 書庫の中身の一覧・展開 |
| `jq` | JSON のプレビュー |
| `poppler` | PDF のプレビュー |
| `fd` | ファイル名検索（`s` キー） |
| `ripgrep` | 全文検索（`S` キー） |
| `fzf` | 絞り込み（`z` / `Z` キー） |
| `resvg` | SVG のプレビュー |
| `imagemagick-full` | 画像・フォントの変換 |
| `font-symbols-only-nerd-font` | アイコン表示用のフォント |

`zoxide` も yazi から使える（`z` キーでのジャンプ）。本書では別の手順（[AlmaLinux 10 の初期設定の「シェルのツール」](../almalinux-setup.md#シェルのツール)の手順 1）で入れている。

ボトルが降りたことの確認（実測、コンテナ）:

```
==> Fetching downloads for: yazi
✔︎ Bottle yazi (26.9.1)
==> Pouring yazi--26.9.1.arm64_linux.bottle.tar.gz
🍺  /home/linuxbrew/.linuxbrew/Cellar/yazi/26.9.1: 17 files, 32.5MB
==> Caveats
Bash completion has been installed to:
  /home/linuxbrew/.linuxbrew/etc/bash_completion.d
```

#### yazi: ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**



- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

#### yazi: 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に、ターミナルファイルマネージャ [yazi](https://yazi-rs.github.io/) の最新版を入れ、プレビューと検索が効く状態にする
- **進め方**
  - **AlmaLinux 10**（[実施手順](../almalinux-setup.md#yazi)）: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
    - **読者が書き換えるのは冒頭の変数ブロック（依存ツールの一覧）だけ**
    - RPM（COPR）経路も試したうえで採らなかった（[選択した方針](#yazi-選択した方針)）
  - **Windows 11**（[Windows 11 で使う](../windows-setup.md#yazi)）: scoop の main の `yazi` と `$YAZI_EXTRAS` のツールを、管理者ではない Windows PowerShell 5.1 から自分のユーザーに入れる
    - **読者が書き換えるのは、この節の手順 2 の `$YAZI_EXTRAS` だけ**（既定のままでよい）
    - ユーザーの環境変数 `YAZI_FILE_ONE` を Git for Windows の `file.exe` にする。VC++ のランタイムが無ければ、wezterm-nightly.md の Windows 11 の手順 3 を管理者の窓で先に行う
    - `y` は、WezTerm の Git Bash の共通の bash 設定で使う（Git Bash のタブを開くコマンドの無い手順 7 と、そこに貼る `bash` のブロックの手順 8）
- **状態（AlmaLinux 10）**: **実機で本実行済み（2026-09-21）。`0dbb522` 版の手順 1〜4（2026-10-01 に比べ方を直した `y` 関数を含む）は、x86_64 のクリーン VM で本実行済み（2026-10-06）。WSL の擬似端末でも確認した（実機の関数は変更前の形）**。現行 `5da3478` の共通 bash 新規導入後の再検証も、別の新規 VM で行った（末尾の記録）。既存ホストの手動移行は今回は未実施
  - 下表のホストで `brew install yazi ...` を実行し、`yazi 26.9.1` が入って常用中。`~/.bashrc` の `y()` 関数は、比べ方を直す前の形で入っている
  - [Homebrew の導入](../almalinux-setup.md)と手順 2・4 は、2026-09-22 に同じ OS のコンテナで**この文書のコードブロックをそのまま貼って**通し直した（`YAZI_EXTRAS` は空）
  - 確認したこと: ボトルが降りる、`yazi --version` / `ya --version` が出る
  - 2026-10-01: 比べ方を直した手順 3 のブロックを、WSL の AlmaLinux 10.2 の擬似端末の bash（使い捨ての `HOME`）に括弧付き貼り付けで貼り、GitHub の yazi 26.9.1 のバイナリを開いて `y` を確かめた。直す前の版と比べ、5 つの場合とも振る舞いは同じだった（[付録](#yazi-付録-y-関数の比べ方を直したときの検証2026-10-01)）
  - **コンテナでは TUI の起動とプレビューは確認していない**（端末が無いため）
  - **画像プレビュー（端末側の対応）とプラグインは未検証**
- **状態（Windows 11）**: **Windows 実機では未検証（2026-10-08 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**:
    - 配布物の定義とソース: scoop の main のバケットの `yazi.json`（2026-10-08 に取得。26.9.1）と、yazi 26.9.1 のソース（`ya env` の出力、`--version` の形、Windows の設定・状態・キャッシュの場所、既定の `[opener]`）、scoop 本体のメッセージ（[付録](windows-setup.md#yazi-付録-windows-11-の節の資料と-linux-での確認2026-10-08)）
    - 配布物: `yazi-x86_64-pc-windows-msvc.zip`（sha256 が `yazi.json` の値と一致）の `yazi.exe`・`ya.exe` が `VCRUNTIME140.dll` を読み込むこと（`objdump -p` のインポート表）
    - PowerShell のブロック 9 個: Linux の PowerShell 7.5.3 の構文解析器（誤り 0）と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査（指摘 0）
    - 偽物の scoop・yazi・ya と、ユーザーの環境変数を記録する偽物での模擬（Windows 11 で使うの手順 2〜6・更新・ロールバック）。偽物の scoop のメッセージは scoop 本体のソースから写したもので、実際の scoop の出力ではない
    - 見直しの後に、ブロックを取り出し直して、構文・互換の検査と模擬をやり直した（[付録](windows-setup.md#yazi-付録-windows-11-の節の資料と-linux-での確認2026-10-08)の「最後の確認」）
    - 2 回目の見直しの後にも、同じことをやり直した。分けて増えた手順 8 の `bash` のブロック（Git Bash に貼る）は、`bash -n` と、共通の bash 設定の `y` と偽物の yazi で、Linux の bash で流した（[付録](windows-setup.md#yazi-付録-windows-11-の節の資料と-linux-での確認2026-10-08)の「2 回目の見直しの後の確認」）
    - ロールバックの手順 2 を、`YAZI_FILE_ONE` が Git for Windows の `file.exe` のときだけ消す形に直した後にも、構文・互換の検査と、その手順の模擬をやり直した（[付録](windows-setup.md#yazi-付録-windows-11-の節の資料と-linux-での確認2026-10-08)の「ロールバックの手順 2 を直した後の確認」）
  - **確かめていないこと**:
    - Windows で貼ること（すべての手順）と、scoop での導入（`$YAZI_EXTRAS` の 9 個を含む）・更新・削除
    - `VCRUNTIME140.dll` が無いときの表示（何も出さずに終わるか、システム エラーの窓が出るか）
    - `ya env` の実際の表示（`Config` の行の `os error 3` と `os error 2`、`file -bL --mime-type` が `text/plain` になること）
    - ユーザーの環境変数 `YAZI_FILE_ONE` と、imagemagick が足す環境変数・`PATH` が、今の窓・新しい窓・WezTerm のタブに効くこと（scoop のソースでは、今の窓にも入れる）
    - TUI のプレビュー（PDF・動画・画像・書庫）と、WezTerm・Windows Terminal・conhost での画像の表示
    - この文書の手順としての、WezTerm の Git Bash の `y`（手順 7・8）
    - Enter でテキストを開いたときのエディタ（自分用の設定では `nvim`、上流の既定の設定では VS Code の `code`）
    - 自分用の設定（README の Windows の例）との組み合わせと、その元に戻し方（`config.bak`）
    - SSH のセッションと、arm64 の Windows
  - 参考: Windows 11 の Git Bash の `y`（共通の bash 設定の同じ関数）は、bash リポジトリの検証記録で、scoop の yazi 26.9.1 を開いて確かめてある（[2026-10-01 の Git Bash の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-11-の-git-bash-での検証記録2026-10-01)。[2026-10-06 の Windows ホストの付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-ホストでの設定の再検証2026-10-06)は、cwd-file を書くスタブで確かめた）。この文書の手順としては流していない

AlmaLinux 10:

| 項目 | 実機 | 検証コンテナ | WSL（`y` 関数の比べ方を直したとき） |
|---|---|---|---|
| 実施日 | 2026-09-21 | 2026-09-22 | 2026-10-01 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） | AlmaLinux 10.2 (Lavender Lion) / x86_64（Windows 11 の PC の WSL 2.7.13.0、bash 5.2.26） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） | 使っていない |
| 入った yazi | `yazi 26.9.1`（`arm64_linux` ボトル、Rustc 1.98.0 ビルド） | 同じ（`26.9.1`） | GitHub のリリースの `yazi-x86_64-unknown-linux-gnu.zip`（26.9.1。一時的な場所に展開） |
| 依存ツール | `ffmpeg-full 9.0.2` / `sevenzip 26.03` / `jq 1.8.2` / `poppler 26.09.0` / `fd 10.5.0` / `ripgrep 15.2.0` / `fzf 0.74.4` / `resvg 0.48.1` / `imagemagick-full 7.1.2-31` / `font-symbols-only-nerd-font 3.5.1` | 本体のみ（formula の存在確認だけ実施） | 無し |
| 端末 | WezTerm nightly（[wezterm-nightly.md](../almalinux-setup.md#wezterm)） | 無し | Python の `pty`（160 × 48） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../almalinux-setup.md#yazi) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${YAZI_EXTRAS}` | yazi 本体と一緒に入れる依存ツール（空白区切りの formula 名）。空なら本体だけ | `ffmpeg-full sevenzip jq poppler ...` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`26.9.1`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### yazi: 実施前の状態

AlmaLinux 10 の実機（2026-09-21）。Windows 11 の PC は、[Windows 11 で使う](../windows-setup.md#yazi)の手順 3 で確かめる。

| 項目 | 状態 |
|---|---|
| yazi | COPR `lihaohong/yazi` の RPM 版 `yazi-26.9.1-1.el10.aarch64` が入っていた（2026-09-20 に導入）。本手順の前に `dnf remove` 済み |
| Homebrew | 7.0.6 導入済み（2026-09-20 に公式インストーラで導入） |
| プレビュー用ツール | `ffmpeg` / `7z` / `magick` はいずれも未導入。`poppler-utils` は COPR 版 yazi の依存で入っていたが、削除時に一緒に消えた |
| 有効な追加リポジトリ | epel、crb、raspberrypi、COPR（lihaohong/yazi）、mozilla、gh-cli、claude-code |

#### yazi: 選択した方針

AlmaLinux 10 aarch64 で yazi の最新版を入れる経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `yazi 26.9.1` の `arm64_linux` ボトルがあり、ソースビルドにならない。upstream の最新リリース（v26.9.1、2026-09-01）と一致。依存ツールも同じ `brew install` で最新版が揃う | **採用** |
| COPR `lihaohong/yazi` | `epel-10-aarch64` chroot に成果物があり、`dnf install yazi` は通る（実機で一度導入した）。ただし EL10 側に揃っていないプレビュー依存があり、`ffmpeg` は EPEL の `ffmpeg-free` しか無い。`fd-find 10.4.2` / `ripgrep 14.1.1` / `fzf 0.58.0` も Homebrew 版より古い | 不採用（実機で導入後に削除） |
| `cargo install --force yazi-build` | Rust toolchain（appstream に `rust 1.92.0` あり）が要り、更新のたびにビルドする。Raspberry Pi では時間がかかる | 不採用 |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-gnu` / `musl` のビルドがある。展開して PATH に置くだけだが、更新は手作業 | 不採用 |
| EPEL / AppStream | `yazi` は無い（`dnf list yazi` → `No matching Packages to list`） | 使えない |

- 2026-09-20 18:56 に `dnf copr enable lihaohong/yazi` → `dnf install yazi` で `yazi-26.9.1-1.el10.aarch64` を導入
  - 同時に入ったのは `resvg-0.47.0-1.el10` と `poppler-utils-24.02.0-7.el10_2.2` の 2 つだけ
- 翌朝 09:29 に `dnf remove yazi-26.9.1-1.el10.aarch64` で 3 パッケージとも削除し、Homebrew 版に入れ替えている
- RPM 側ではプレビュー用のツールを別々に集める必要があり、`ffmpeg` に至っては EL10 の標準リポジトリにも EPEL にも無い（`ffmpeg-free` のみ）

#### yazi: 完了時点の状態

AlmaLinux 10 の実機（2026-09-21）。Windows 11 は流していないので、記録は無い（入るものは、[Windows 11 で使う](../windows-setup.md#yazi)の手順 6 の箇条書き）。

```
$ brew list --versions yazi
yazi 26.9.1
$ yazi --version
Yazi
    Version: 26.9.1 (Homebrew 2026-09-01)
    Debug  : false
    Triple : aarch64-unknown-linux-gnu (linux-aarch64)
    Rustc  : 1.98.0 (88d9e12a 2026-08-18)
$ ya --version
Ya
    Version: 26.9.1 (Homebrew 2026-09-01)
$ command -v yazi
/home/linuxbrew/.linuxbrew/bin/yazi
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/yazi/26.9.1/`（17 ファイル、32.5 MB）。bash 補完は `/home/linuxbrew/.linuxbrew/etc/bash_completion.d` に入る。

#### yazi: 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで、非 root ユーザーを作って[Homebrew の導入](../almalinux-setup.md)と手順 2・4 を通した。実機で加えた変更は `dnf install podman` だけ。 実行したのは**この文書のコードブロックをそのまま抜き出したスクリプト**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。 端末が要る `y` の 1 行と、`YAZI_EXTRAS` の中身（空にした）だけ除いている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git sudo` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6` が `/home/linuxbrew/.linuxbrew` に入った（[homebrew.md](../almalinux-setup.md)） |
| 2. yazi | `brew install yazi` → `Pouring yazi--26.9.1.arm64_linux.bottle.tar.gz`（17 files, 32.5MB）。ソースビルドは発生しない |
| 4. 検証 | `yazi --version` / `ya --version` ともに `26.9.1 (Homebrew 2026-09-01)`、`Triple: aarch64-unknown-linux-gnu` |
| 依存ツール | `ffmpeg` / `sevenzip` / `jq` / `poppler` / `fd` / `ripgrep` / `fzf` / `resvg` / `imagemagick` / `font-symbols-only-nerd-font` の formula がすべて存在することを `brew info` で確認（インストールはしていない。実機には `-full` 版が入っている） |
| 設定ファイル | 配布物に既定の `*.toml` は含まれない（`brew list yazi` の `.toml` は `.crates.toml` のみ） |
| RPM 経路 | COPR `lihaohong/yazi` を有効化して `dnf install --assumeno yazi` → 115 パッケージ・63 MB に解決。EPEL の `ffmpeg-free 7.1.2` / `fd-find 10.4.2` / `ripgrep 14.1.1` / `fzf 0.58.0` はいずれも Homebrew 版より古い |

##### yazi: 未確認事項

- TUI の追加操作（削除・外部アプリで開く操作など。クリーン VM では起動・ディレクトリ移動・終了とテキスト・ZIP のプレビューを確認）
- 画像プレビュー（WezTerm 側のグラフィックプロトコル対応）
- `ya pkg` で入れるプラグイン・テーマ
- `YAZI_EXTRAS` を空にした最小構成での動作
- ロールバック（`brew uninstall`）の本実行

---

#### yazi: 付録: y 関数の比べ方を直したときの検証（2026-10-01）

手順 3 の `y` 関数の、移ったかの比べ方を `[ "$cwd" != "$PWD" ]` から `! [ "$cwd" -ef "$PWD" ]` に直した。きっかけは、この関数を同じ文字列で読む自分用の bash の設定（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）を、Windows 11 の Git Bash で確かめたときの次の振る舞い:

- yazi（scoop の 26.9.1）は cwd-file に `C:\Users\…\Desktop` の形で書き、Git Bash の `$PWD` は `/c/Users/…/Desktop` なので、文字列では一致しない
- 動かずに `q` で閉じても `cd` し直し、`OLDPWD` が今の場所に変わった（`cd -` で前の場所へ戻れない）。`Q` では変わらなかった
- bash の組み込みの `test` の `-ef`（同じデバイスと i ノードか）は、Git Bash で `C:\Users\…\Desktop` と `/c/Users/…/Desktop` を同じ、別のディレクトリを違うと判定した

**流し方（AlmaLinux 10）**:

- Windows 11 の PC の WSL の AlmaLinux 10.2 で、Python の `pty` で `bash --norc --noprofile -i` を動かした（`HOME` は `/tmp` の下の使い捨てのディレクトリ。WSL のユーザーのホームには書いていない）
- この文書の手順 3 のブロックを機械的に抜き出し（リストの字下げを外す）、括弧付き貼り付けで貼ってから Enter を送った。直す前の版（この直しの前の yazi.md）と直した版を、別々のホームで流した
- yazi は Homebrew で入れず、GitHub のリリースの `yazi-x86_64-unknown-linux-gnu.zip`（26.9.1。sha256 をリリースに載っている値と照合）を一時的な場所に展開して、`PATH` の先頭に置いた
- yazi の画面が開いた（代替画面に切り替わった）のを待ってからキーを送り、画面が閉じてプロンプトが戻ってから、`PWD` と `OLDPWD` を書き出した

| 確かめたこと | 直す前（`!=`） | 直した版（`-ef`） |
|---|---|---|
| 手順 3 のブロックを貼った後 | `~/.bashrc` は 7 行、`type -t y` は `function` | 同じ（比べ方の行だけが違う） |
| `d1` で `y` → `l` で `share` に入って `q` | `share` へ移り、`OLDPWD` は `d1` | 同じ |
| `d1` で `y` → 動かずに `q` | 動かず、`OLDPWD` も前のまま | 同じ |
| `d1` で `y` → 動かずに `Q` | 動かず、`OLDPWD` も前のまま | 同じ |
| シンボリックリンク（`link` → `real`）の中で `y` → 動かずに `q` | `PWD` は `link` のまま | 同じ |
| `y 'd1/with space'` → `q` | `d1/with space` へ移った | 同じ |
| `/tmp/yazi-cwd.*` | 残らない | 残らない |

- `y` を通さずに `yazi --cwd-file=<ファイル>` を開いて確かめると、動かずに `q` で閉じたとき、yazi は `$PWD` と同じ形（シンボリックリンクの中では `…/link` のリンクの形）を書いた。`Q` で閉じるとファイルを作らなかった
- AlmaLinux 10 では、yazi が `$PWD` と同じ形で書くので、2 つの比べ方で振る舞いが分かれなかった

**Windows 11 の Git Bash**（参考。この文書の対象外）:

- ryo-aoki-pc/bash の `bashrc` の同じ関数を、画面を出さない WezTerm の端末（`wezterm-mux-server` のペイン）で、scoop の yazi 26.9.1 を開いて確かめた
- 直す前は、動かずに `q` で閉じると `OLDPWD` が今の場所に変わった。直した版では変わらず、中へ入って `q`・`Q`・空白と日本語を含むディレクトリは、直す前と同じだった

##### yazi: 未確認事項（2026-10-01）

- 実機（Raspberry Pi 5・aarch64・Homebrew の yazi）で、直した `y` を使うこと（実機の `~/.bashrc` は直す前の形のまま）
- WezTerm の画面での操作（擬似端末にキーを送って代えた）

---

#### yazi: 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜4。

**検証した版**: `0dbb522`。以下の手順番号と「本文」は、`y` 関数を直接追記していたこの版を指す。その後の共通 bash 設定の新規導入・移行は今回の VM では行っていない。

**結果**: Yazi/Ya 26.9.1。本文既定の `YAZI_EXTRAS` を全て指定し、この段階で新しい formula のボトル 175 個と Symbols Nerd Font の cask を導入した。ソースビルドは発生しなかった。1 vCPU の VM で手順 2 は 1,798.8 秒（約 30 分）かかった。その後の、他の CLI を含む `Cellar` は 2.6 GiB、Homebrew のダウンロードキャッシュは 838 MiB だった。この版の `y()` 関数を本文どおり書き、TUI で空白を含む `sub directory` に入り `q` で終了した。シェルの `pwd` もそのディレクトリになった。テキストと ZIP の内容一覧（`sample.txt`・29 B）のプレビューを確認した。Homebrew の sevenzip が置くコマンドは `7zz` で、`7z` は無かった。追加の確認で `7z` を呼んだ際の PackageKit の導入質問は中断し、RPM の `7zip` を追加せず、`7zz` と Yazi の ZIP プレビューで確かめ直した。初回の終了判定は、捕捉ライブラリが alternate screen を復元せず古い TUI を残したため誤判定した。生ログのプロンプト・Ctrl+L の再描画・`pwd` で切り分け、捕捉補助を直した。

**今回の未確認範囲**: 画像・動画・PDF の画面プレビュー、ファイルの削除や外部アプリを開く操作、自分用の設定、更新・ロールバックは今回確認していない。追加ツールは版の出力まで確認した。

#### yazi: 付録: 現行版と個人設定の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜4 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で共通 bash `3d5323e` の導入後に実行した。既定の `YAZI_EXTRAS` 全体を選び、yazi / ya 26.9.1、ffmpeg-full、sevenzip、jq、poppler、fd、ripgrep、fzf、resvg、imagemagick-full、Nerd Font を導入した
- 本文手順 2 は 36 分 17 秒で終了 0。145 回の bottle 展開を観測し、ソースビルドへの fallback は無かった。最後は ImageMagick 7.1.2-32 と Nerd Font 3.5.1。追加ツールは xorg-server の検証補助が先に入った共有 prefix に導入したので、まったく同じ依存集合をすべての新規ホストで要するという意味ではない
- 個人設定の README の clone URL を具体的な公開 URL に直し、`custom` / `41c5124` を通常の `~/.config/yazi` に clone した。3 ペイン・隠しファイル・サイズと更新日時・テキストのプレビューが実 TUI に出た。`l` でディレクトリへ入り、Enter で sample.txt が Neovim に開き、`:qa` で戻った
- 共通設定の `y` で終了すると `/home/verifier/cli-yazi-check/空白 日本語` へ移り、`gT` で `/tmp` へ移った後も `q` でシェルの cwd が `/tmp` になった。そこで動かず終了しても cwd は同じだった
- 最初の TUI 補助では終了時のマーカーを取り逃し、復帰前の次の入力も届かなかった。TUI の起動・復帰とシェルのプロンプトを待つ補助へ直して同じ操作を再実行した。設定の不具合とは区別する
- PDF・動画・画像・書庫の実プレビューと GUI 端末の描画、検索・複数ファイルをまとめて開く任意設定、上流設定の更新・rebase・push、パッケージ更新・削除は今回は確認していない


#### yazi: 選択した方針

**COPR 版を外した理由**（実機の記録）:

EPEL を有効にした状態で COPR 版の依存解決を採ると、EPEL 側のツールを巻き込んで 115 パッケージ・63 MB になる:

```
$ dnf install --assumeno yazi
 jq              aarch64  1.7.1-11.el10_2.2  baseos
 jxl-pixbuf-loader aarch64 1:0.10.4-1.el10_1 epel
 open-sans-fonts noarch   1.10-24.el10       appstream
 poppler-utils   aarch64  24.02.0-7.el10_2.2 appstream
 resvg           aarch64  0.47.0-1.el10      copr:copr.fedorainfracloud.org:lihaohong:yazi
 ripgrep         aarch64  14.1.1-1.el10_0    epel
Install  115 Packages
Total download size: 63 M
```

---

## 統合前の記録: Claude Code（もとは claude-code.md）

もとの `claude-code.md` の検証記録を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の検証記録](windows-setup.md#統合前の記録-claude-code-の-windows-11もとは-claude-codemd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜5 | 「Claude Code」の手順 1〜5 |
| 使い方の基本 | Claude Code の使い方の基本 |
| 更新 1 | 更新のリード（OS の更新で上がる） |
| stable チャンネルに切り替える（任意）の 1〜4 | Claude Code を stable チャンネルに切り替える（任意）の 1〜4 |
| ロールバック 1〜3 | ロールバックの「AI エージェントとプラグインを消す」の手順 2〜4 |

### Claude Code: 補足

#### Claude Code: 実施手順: 検証状況の記録

> [!WARNING]
> この実施手順（AlmaLinux 10）の既定の `latest` チャンネルは **x86_64 のクリーン VM とコンテナで検証した**（VM は 2026-10-06、認証前まで）。実機（aarch64）で本実行したのは `stable` チャンネル（[対象と検証環境](#claude-code-対象と検証環境)）。

#### Claude Code: 実施手順 / 手順 2: 補足: チャンネルは baseurl で決まる

この手順のヒアドキュメントだけ `<<EOF`（クォート無し）にしてある。`${CC_CHANNEL}` を展開して `baseurl` に埋めるため。

公式ドキュメントの dnf 向けの例と同じ形。既定の `latest` のまま貼ると、次のファイルになる（2026-09-26、コンテナ）:

```
[claude-code]
name=Claude Code
baseurl=https://downloads.claude.ai/claude-code/rpm/latest
enabled=1
gpgcheck=1
gpgkey=https://downloads.claude.ai/keys/claude-code.asc
```

実機に置いてあるのは `stable` を選んだファイルで、違いは `baseurl` の末尾（`.../rpm/stable`）だけ。

`repo_gpgcheck` は書かない（既定の 0）。パッケージ自体の署名は `gpgcheck=1` で検証される。署名鍵はどちらのチャンネルも同じ（手順 3 の補足）。

#### Claude Code: 実施手順 / 手順 3: 補足: 鍵の取り込み

`dnf install` の途中で、トランザクション表の `[y/N]` の後に鍵の取り込みを聞かれる。実測（x86_64 のコンテナ、`latest`、2026-09-26）:

```
Installing:
 claude-code         x86_64         2.1.283-1         claude-code         104 M
...
Total download size: 104 M
Installed size: 230 M
Is this ok [y/N]: y
Downloading Packages:
claude-code-2.1.283-1.x86_64.rpm                 67 MB/s | 104 MB     00:01
...
Importing GPG key 0x1A7ECACE:
 Userid     : "Anthropic Claude Code Release Signing <security@anthropic.com>"
 Fingerprint: 31DD DE24 DDFA B679 F42D 7BD2 BAA9 29FF 1A7E CACE
 From       : https://downloads.claude.ai/keys/claude-code.asc
Is this ok [y/N]: y
Key imported successfully
...
Complete!
```

2026-09-22 に `stable`（aarch64、`2.1.267-1`）で入れたときも同じ fingerprint だった。この fingerprint は公式ドキュメントに載っているものと一致する。同じ鍵が apt / apk のリポジトリとリリースの `manifest.json` の署名にも使われている。

依存は `glibc >= 2.17` だけ（`rpm -q --requires claude-code`）なので、デスクトップ系のパッケージは一切付いてこない。

#### Claude Code: 実施手順 / 手順 4: 補足: 最新版かどうかの確かめ方

- `--available` はリポジトリにある版だけを見る（入っている版は含めない）。リポジトリには古い版も残っているので、`--latest-limit 1` で一番新しいものだけに絞る
- 2026-09-26 の時点で、`latest` には 137 版、`stable` には 56 版が残っていた（x86_64 / aarch64 それぞれ）
- ネイティブインストーラが最新版として取りに行くのは `https://downloads.claude.ai/claude-code-releases/latest` が指す版で、2026-09-26 は RPM の `latest` と同じ `2.1.283` だった。RPM に届くのが遅れることはある（[注意点](../extra/almalinux-setup.md#注意点)）
- コンテナの dnf 4.20.0 では、`--qf` の末尾に `\n` を付けると結果の後に空行が 1 行増えた。本書の 2026-09-22 版はそう書いていたので外した

#### Claude Code: 実施手順 / 手順 5: 補足: 認証

`claude` を引数無しで起動すると、ブラウザでのログインに進む。SSH 越しなど、そのホストでブラウザを開けない場合は、表示される URL を手元のブラウザで開いてコードを貼る形になる。**この手順はコンテナでは実行していない**（実機では認証済みで常用している）。

認証後の状態は `claude doctor` で確認できる（インストールの健全性、設定ファイルの検証エラー、更新の結果を表示する読み取り専用の診断）。認証後の出力は本書では未確認。

`claude doctor` は未認証でも動く。x86_64 のコンテナ（`latest`、2026-09-26）で手順 4 の直後に実行した出力の抜粋:

```
Claude Code doctor

Running: package-manager (2.1.283)
Platform: linux-x64
Package manager: rpm
Path: /usr/bin/claude
Search: OK (bundled)
Auto-updates: Managed by package manager
Auto-update channel: latest
...
No installation issues found.
```

ただし、これだけで `~/.claude/` と `~/.claude.json` ができる。

#### Claude Code: 使い方の基本 / 手順 0: 本文中の記録

- 表のコマンドは、本書で実行して確かめた（[付録](#claude-code-付録-使い方の基本の検証記録2026-10-01)）。確かめていないものは、表の見出しの括弧と、その行に書いた

#### Claude Code: 使い方の基本 / 手順 0: 本文中の記録

- 確かめたのは Linux だけ。[Windows 11 で使う](../windows-setup.md#claude-code)で入れた `claude` にも、同じコマンドを Windows PowerShell で打つ（公式の CLI reference は OS で分けていない）が、Windows では確かめていない

#### Claude Code: 使い方の基本 / 手順 0: 本文中の記録

**起動と再開**（`-c`・`-r`・`-n`・`--model`・`--permission-mode`・`--add-dir` は `-p` と組み合わせて確かめた。`-r` の一覧から選ぶ画面と `claude "<最初の指示>"` は確かめていない）

#### Claude Code: 使い方の基本 / 手順 0: 本文中の記録

- ログインとログアウトは、セッションの中の `/login`・`/logout` か、`claude auth login`・`claude auth logout`（本書では試していない）

#### Claude Code: stable チャンネルに切り替える（任意） / 手順 1: 補足: キャッシュ

dnf 4.20.0 のキャッシュは `/var/cache/dnf/claude-code-<16 桁の 16 進数>` のディレクトリに置かれる。実測では、`baseurl` を書き換えた直後の dnf が `stable` のメタデータ（10 kB）を取りに行き、このディレクトリが 2 つ（チャンネルごと）になった。前のチャンネルのメタデータは使われなかった。

#### Claude Code: stable チャンネルに切り替える（任意） / 手順 2: 本文中の記録

   - トランザクション表が `Downgrading:` で、版が `stable` の最新（2026-09-26 は `2.1.274-1`）になっていることを確かめて `y` と答える

#### Claude Code: stable チャンネルに切り替える（任意） / 手順 2: 補足: distro-sync の表示

実測（2026-09-26、`2.1.283-1` から）:

```
Claude Code                                      37 kB/s |  10 kB     00:00
...
Downgrading:
 claude-code         x86_64         2.1.274-1         claude-code          98 M

Transaction Summary
================================================================================
Downgrade  1 Package

Total download size: 98 M
Is this ok [y/N]: y
...
Downgraded:
  claude-code-2.1.274-1.x86_64

Complete!
```

#### Claude Code: ロールバック / 手順 0: 本文中の記録

- ロールバックは **x86_64 のコンテナでだけ本実行した**（実機では未実行）

#### Claude Code: 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に [Claude Code](https://code.claude.com/docs/) の CLI の最新版を入れる
  - AlmaLinux 10 では **dnf 管理で**入れ、`dnf upgrade` で追従できるようにする
  - Windows 11 では公式の native installer で入れ、Claude Code 自身の自動の更新に任せる
- **進め方**: どちらも Anthropic の公式の配布物を使い、npm も Node.js も使わない。**読者が書き換えるのは変数（チャンネル）だけ**で、既定のままで通る
  - **AlmaLinux 10**（[実施手順](../almalinux-setup.md#claude-code)）: 公式の RPM リポジトリの `latest` チャンネルを 1 つ足して `dnf install` する
  - **Windows 11**（[Windows 11 で使う](../windows-setup.md#claude-code)）: 管理者ではない Windows PowerShell 5.1 で公式の `install.ps1` を動かし、`%USERPROFILE%\.local\bin\claude.exe` に入れる。`PATH` は本書で足し、署名を確かめてから、ブラウザでログインする
- **状態（AlmaLinux 10）**: **実機で本実行済み（`stable`、2026-09-20）**。既定の `latest` は x86_64 のクリーン VM（2026-10-06、認証前まで）とコンテナ（2026-09-26）で検証
  - 実機（aarch64）: `stable` チャンネルの repo ファイルを置いて `dnf install claude-code` し、`claude-code-2.1.267-1.aarch64` が入っている。認証も済んでいて常用中（本書の初版は、そのホストの Claude Code で書いた）
  - 2026-09-22: 同じ OS の aarch64 のコンテナで、`stable` の手順 2〜4 を通し直した
  - 2026-09-26: 既定を `latest` に変え、x86_64 のコンテナで手順 1〜4・[更新](../almalinux-setup.md#更新)・[stable チャンネルに切り替える（任意）](../almalinux-setup.md#claude-code-を-stable-チャンネルに切り替える任意)・[ロールバック](../extra/almalinux-setup.md#ai-エージェントとプラグインを消す)を、この文書のコードブロックのまま通した（`claude-code-2.1.283-1.x86_64`）
  - **確認していないこと**: 実機（aarch64）での `latest`（aarch64 にも同じ版があることはメタデータで確認）、コンテナでの認証（手順 5）、認証後の `claude doctor`
  - 2026-09-28: 手順 2 と、[stable チャンネルに切り替える（任意）](../almalinux-setup.md#claude-code-を-stable-チャンネルに切り替える任意)の手順 1・4のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-01: [使い方の基本](../almalinux-setup.md#claude-code-の使い方の基本)を足した（[付録](#claude-code-付録-使い方の基本の検証記録2026-10-01)）
    - ログインの要るもの（`-p`・`-c`・`-r`・`-n`・`--model`・`--permission-mode`・`--add-dir`・`--allowedTools`・`--max-turns`・`--output-format json`）は、クラウドのホスト（Ubuntu 24.04）にあったログイン済みの Claude Code 2.1.287 で確かめた
    - ログインの要らないもの（`doctor`・`auth status`・`mcp`・`update`、ログインしていないときの `-p` と `remote-control`）は、x86_64 の AlmaLinux 10 のコンテナに手順 2〜4 で入れた `claude-code-2.1.287-1` で確かめた
    - **確認していないこと**: セッションの中の操作（キーとスラッシュコマンド）、`-r` の一覧から選ぶ画面、`claude auth login` / `logout`、`claude remote-control` の接続
  - 2026-10-02: 手順 2 の `{ … }` を、`CC_CHANNEL` が空なら何もせずに止める `if … fi` にした（中のコマンドは変えていない）
    - それまでは、ヒアドキュメントの中の `${CC_CHANNEL:?…}` が `sudo tee` しか止めず（[gnome-power.md 手順 3 の補足](almalinux-setup.md#画面オフロックサスペンド-実施手順--手順-3-補足-ログイン画面の設定の置き場所とgdm-ユーザーで読む理由)）、repo ファイルは書かれずに、後ろの `cat` が `No such file or directory` を出した
    - 直した形は、擬似端末の対話の bash にブラケットペースト無しで、変数を空にしたときと値を入れたときの 1 回ずつ貼って確かめた（`sudo` はそのまま実行するスタブ、`/etc` は使い捨てのディレクトリに読み替えた）
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](windows-setup.md#claude-code-付録-windows-11-の配布物と資料の調査2026-10-03)）:
    - 公式の文書: Windows の要件（Git for Windows は任意、管理者の権限は要らない）、置き場所、チャンネル、更新、アンインストール、`PATH` の足し方、署名
    - インストーラ: `install.ps1`（`bootstrap.ps1`）の中身。sha256 は照らすが、署名は確かめず、`PATH` も変えない
    - 配布物: 2.1.288 の `manifest.json` の GPG の署名、Windows の `claude.exe`（x64）の sha256 と Authenticode の署名者・タイムスタンプ（Linux で読んだだけ）、`claude.exe` の中の文字列（`PATH` の案内、置き場所、更新のときの名前の変え方）
    - Linux の native installer の同じ版（2.1.288）: `claude install latest` / `stable` で書かれる設定と置き場所、`claude doctor`・`claude update` の出力
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。[Windows 11 で使う](../windows-setup.md#claude-code)の手順 4 は、本物の `install.ps1` を Linux の pwsh で動かし、`claude.exe` を落として sha256 が合うところまで通した（Windows の実行ファイルを動かすところで止まる）。同じ節の手順 5 と[Windows 11 のロールバック](../extra/windows-setup.md#ai-エージェントとプラグインを消す)の手順 2〜4 は、自分のユーザーの PATH とフォルダーを偽物にして流した（[付録](windows-setup.md#claude-code-付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
  - 別の手順書の実機（[windows-claude-remote-control.md](../windows-claude-remote-control.md) の Windows 11 Pro 26H2）には、native installer の 2.1.286 が `C:\Users\<WIN_USER>\.local\bin\claude.exe` に入っていて、claude.ai にログインしてあった（2026-10-01。この節の手順で入れたものではない）
  - **確かめていないこと**: Windows で貼ること（すべての手順）、`claude install` が Windows で出す文言と `PATH` の案内、`PATH` を足して開き直した PowerShell で `claude` が動くこと、`Get-AuthenticodeSignature` の結果、ブラウザでのログイン、`claude update`、ロールバック、arm64 の Windows、Git for Windows が無いとき

AlmaLinux 10:

| 項目 | 実機 | 検証コンテナ（`stable`） | 検証コンテナ（`latest`） |
|---|---|---|---|
| 実施日 | 2026-09-20 | 2026-09-22 | 2026-09-26 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1 / 非特権） |
| カーネル | 6.12.96 | ホストと同じ | クラウドのホストのもの（6.18 系。AlmaLinux のカーネルではない） |
| dnf | 4.20.0 | 4.20.0 | 4.20.0 |
| チャンネル | `stable` | `stable` | `latest`（切り替えの節で `stable` も） |
| 入った Claude Code | `claude-code-2.1.267-1.aarch64`（93 MB / 展開後 207 MB） | 同じ（`2.1.267-1`） | `claude-code-2.1.283-1.x86_64`（104 MB / 展開後 230 MB） |
| Node.js | 未導入（`node` / `npm` 無し。dnf 版は不要） | 未導入 | 未導入 |
| 認証 | 済み（常用中） | 未実施 | 未実施 |

Windows 11（前提にしている環境。ほかの Windows の手順書の実機の記録と同じ PC を想定）:

| 項目 | 値 |
|---|---|
| OS | Windows 11（[Windows の OpenSSH サーバー](../windows-setup.md#openssh-サーバー)の PC は 25H2）。x64 |
| PowerShell | Windows PowerShell 5.1（管理者でなくてよい） |
| Git for Windows | [git.md](../windows-setup.md#git-for-windows)で入れたもの（`C:\Program Files\Git`） |
| 既定のブラウザ | Firefox（[firefox.md](../windows-setup.md#firefox)） |
| Claude Code | 2.1.288（2026-10-02、`latest`。`stable` は 2.1.285） |

> [!NOTE]
> 環境固有の値は**変数**で書いてある。AlmaLinux 10 は[手順 1](../almalinux-setup.md#claude-code)のシェル変数、Windows 11 は[Windows 11 で使う](../windows-setup.md#claude-code)の手順 2 の PowerShell の変数に 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${CC_CHANNEL}` | 追従するチャンネル。`baseurl` の末尾になる | `latest` / `stable` |
> | `$CC_CHANNEL` | Windows 11 で追従するチャンネル。インストーラに渡し、設定の `autoUpdatesChannel` になる | `latest` / `stable` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` / `<WIN_USER>`（Windows のユーザー名）のプレースホルダで書いてある。バージョン（`2.1.283` など）は実行日によって変わる。`<作業したいディレクトリ>` のような `<...>` を含むコマンドは、bash と PowerShell のコードブロックに置いていない。
>
> **API キー・OAuth トークン・認証時のコードは書かない。** 鍵の fingerprint は公開情報なので本文に書いてある。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

#### Claude Code: 実施前の状態

AlmaLinux 10 の実機（2026-09-20）の状態。検証コンテナは公式イメージのまま（Claude Code も追加のリポジトリも無し）。Windows 11 の PC は、[Windows 11 で使う](../windows-setup.md#claude-code)の手順 3 で確かめる。

| 項目 | 状態 |
|---|---|
| Claude Code | 未導入（`claude` 無し、`~/.claude` も無し） |
| Node.js / npm | 未導入。`nodejs` は appstream に 22.23.2 があるが入れていない |
| 有効な追加リポジトリ | epel、crb、raspberrypi、gh-cli（claude-code はまだ無し） |
| `~/.local/bin` | PATH には入っているがディレクトリは未作成 |

#### Claude Code: 選択した方針

Linux に Claude Code を入れる経路は 3 つある（2026-09-22 時点の[公式ドキュメント](https://code.claude.com/docs/en/setup)）:

2026-09-26 に見た各チャンネルの最新版（x86_64 / aarch64 とも同じ）:

Windows 11 で Claude Code を入れる経路を比べた（2026-10-03 時点。中身はどれも公式の `claude.exe`）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **公式の native installer（PowerShell の `install.ps1`）** | `%USERPROFILE%\.local\bin\claude.exe` に入り、管理者の権限は要らない。Claude Code 自身が裏で更新する（チャンネルは `latest` / `stable`）。sha256 は照らすが署名は確かめず、`PATH` も足さない | **採用**（公式が勧める形。[windows-claude-remote-control.md](../windows-claude-remote-control.md) の前提もこの形） |
| 公式の native installer（CMD の `install.cmd`） | 同じものを CMD から入れる | 不採用（本書のブロックは Windows PowerShell にそろえる） |
| WinGet の `Anthropic.ClaudeCode` | `portable` で、公式の配布物の `claude.exe` をそのまま置く。自分では更新しない（`winget upgrade`。`CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE=1` で Claude Code に走らせられるが、動いている間は置き換えられないことがある）。2026-10-03 の winget-pkgs は 2.1.286 で、`latest` の 2.1.288 より遅れていた | 不採用（版が遅れ、更新を別に回すことになる） |
| scoop の `main/claude-code` | 2.1.288（公式の配布物と同じ sha256）。更新は `scoop update` | 不採用（公式の文書の経路ではなく、Claude Code 自身の更新との関係を確かめていない） |
| Chocolatey の `claude-code` | 2.1.285（コミュニティの保守） | 不採用 |
| npm（`@anthropic-ai/claude-code`） | Node.js が要る。PowerShell の実行ポリシーが、npm の作る `.ps1` の起動を止めることがある（公式の Troubleshoot installation） | 不採用 |
| WSL の中に Linux の手順で入れる | Linux の道具を使うなら有力（サンドボックスは WSL 2 だけ）。Windows の `claude.exe` とは別のもの | 不採用（Windows のプロジェクトで使い、[windows-claude-remote-control.md](../windows-claude-remote-control.md) の前提にもなるため） |

| npm（`npm install -g @anthropic-ai/claude-code`） | Node.js 22 以上が要る。このホストに Node.js は無く、そのために入れることになる。中身は同じネイティブバイナリ | 不採用 |

- ネイティブインストーラ（`install.sh` が取ってくる `bootstrap.sh`）も、まず `claude-code-releases/latest` が指す版を取ってくる（スクリプトを読んで確認。実行はしていない）

| 配布元 | `stable` | `latest` |
|---|---|---|
| RPM リポジトリ（`rpm/<チャンネル>` の repodata） | `2.1.274-1` | `2.1.283-1` |
| リリースのポインタ（`claude-code-releases/<チャンネル>`） | `2.1.274` | `2.1.283` |

#### Claude Code: 完了時点の状態

Windows 11 は流していないので、記録は無い。

AlmaLinux 10 の実機（`stable`、2026-09-20）:

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' claude-code
claude-code 2.1.267-1 claude-code
$ claude --version
2.1.267 (Claude Code)
$ rpm -ql claude-code
/usr/bin/claude
/usr/share/doc/claude-code/copyright
$ rpm -q --requires claude-code
glibc >= 2.17
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i anthropic
gpg-pubkey-1a7ecace-69caef70 Anthropic Claude Code Release Signing <security@anthropic.com> public key
```

x86_64 のコンテナ（`latest`、2026-09-26。最初の 4 つが手順 4 のコマンド）:

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}' claude-code
claude-code 2.1.283-1 claude-code
$ dnf -q repoquery --available --latest-limit 1 --qf '%{name} %{version}-%{release} %{reponame}' claude-code
claude-code 2.1.283-1 claude-code
$ claude --version
2.1.283 (Claude Code)
$ rpm -ql claude-code
/usr/bin/claude
/usr/share/doc/claude-code/copyright
$ rpm -q --requires claude-code
glibc >= 2.17
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i anthropic
gpg-pubkey-1a7ecace-69caef70 Anthropic Claude Code Release Signing <security@anthropic.com> public key
```

- 認証すると `~/.claude/`（設定・セッション履歴）と `~/.claude.json` ができる
- プロジェクト側の設定は `.claude/` と `.mcp.json`

#### Claude Code: 付録: コンテナでの検証記録（2026-09-22）

`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで手順 2〜4 を通した。実機で加えた変更は `dnf install podman` だけ。 最後にもう 1 つ新しいコンテナを立て、**この文書のコードブロックをそのまま抜き出したスクリプト**（`sudo` を外し、`dnf install` / `dnf upgrade` に `-y` を付けただけ）を流して、上から順に貼れば通ることを確かめている。

| 手順 | 結果 |
|---|---|
| 2. repo | `tee` で作成。`dnf` がメタデータ（9.8 kB）を取得できた |
| 3. install | `dnf install --assumeno claude-code` → `Installing: claude-code aarch64 2.1.267-1 claude-code 93 M / Installed size: 207 M`、依存パッケージ無し。本実行では鍵の fingerprint `31DD DE24 ... 1A7E CACE` が表示され `Key imported successfully` |
| 4. 検証 | `claude --version` → `2.1.267 (Claude Code)`。`rpm -ql` は `/usr/bin/claude` と copyright の 2 ファイル |

実機（2026-09-20 に `stable` チャンネルで導入）と同じ `2.1.267-1` が入った。

##### Claude Code: 未確認事項

- 手順 5 の認証（コンテナでは未実施。実機では 2026-09-20 に実行して以後常用）
- `latest` チャンネルの動作と、`stable` との切り替え（`baseurl` を書き換えたときの `dnf upgrade` / `distro-sync` の挙動）
- `claude doctor` の出力
- ロールバック（`dnf remove` と鍵の削除）の本実行
- ネイティブインストーラ版・npm 版との併存時の優先順位（`~/.local/bin/claude` が PATH の先にある場合）

#### Claude Code: 付録: latest チャンネルの検証記録（2026-09-26）

**環境**: Ubuntu 24.04 / x86_64 のクラウドホスト上の Docker 29.3.1（cgroup v1）で、`quay.io/almalinuxorg/almalinux:10`（`sha256:8322019282c6f7d253888ec688d6b90675963f31c4692709177e25eb9301c4c8`、AlmaLinux 10.2）を**非特権**・`--network host` で立て、非 root ユーザー（NOPASSWD の sudo）で実行した。実機で加えた変更は無い。

**検証の準備**（本書の手順には含めない）:

- このホストの外向きの HTTPS はプロキシを通るので、プロキシの CA を `/etc/pki/ca-trust/source/anchors/` に置いて `update-ca-trust` し、`/etc/dnf/dnf.conf` に `proxy=` を書いた
- AlmaLinux の mirrorlist が `http://` のミラーを返し、プロキシが CONNECT 以外の要求を 405 で断ったので、`almalinux-*.repo` の `mirrorlist=` を止めて、コメントになっていた `baseurl=https://repo.almalinux.org/...` を有効にした。claude-code のリポジトリは最初から https なので、この変更の影響を受けない
- `sudo` と `util-linux`（`script` のため）を dnf で入れた

**やり方**:

- 1 つ目のコンテナで、`-y` 付きの dnf で同じ操作を試して挙動を確かめた
- 新しいコンテナで、この文書の折り畳みの外にある bash のコードブロック 12 個（手順 1〜4、[更新](../almalinux-setup.md#更新)の手順 1、[stable チャンネルに切り替える（任意）](../almalinux-setup.md#claude-code-を-stable-チャンネルに切り替える任意)の手順 1〜4、[ロールバック](../extra/almalinux-setup.md#ai-エージェントとプラグインを消す)の手順 1〜3）を、上から順にそのまま抜き出したスクリプトを流した
- `sudo` も `-y` 無しの dnf もそのまま。全体を `script` で作った pty の中で流し、6 秒おきに `y` を送った。全体で 42 秒
- ブロックの間に確認のコマンドを挟んだ（下表の「追加」）

| 手順 | 結果 |
|---|---|
| 1. 変数 | `CC_CHANNEL = latest` |
| 2. repo | `baseurl=https://downloads.claude.ai/claude-code/rpm/latest`。dnf がメタデータ（23 kB）を取得した |
| 3. install | `Installing: claude-code x86_64 2.1.283-1 claude-code 104 M / Installed size: 230 M`、依存パッケージ無し。`[y/N]` はトランザクションと鍵の 2 回。fingerprint `31DD DE24 ... 1A7E CACE` が表示され `Key imported successfully` |
| 4. 確認 | repoquery の 2 行がどちらも `claude-code 2.1.283-1 claude-code`。`claude --version` → `2.1.283 (Claude Code)`。`rpm -ql` は `/usr/bin/claude` と copyright の 2 ファイル |
| 追加: `claude doctor` | 未認証のまま実行して終了コード 0。`Package manager: rpm`、`Auto-updates: Managed by package manager`、`Auto-update channel: latest`、`No installation issues found.`。これだけで `~/.claude/` と `~/.claude.json` ができた |
| 更新 1 | `Nothing to do.`（入れた直後なので） |
| 切り替え 1 | `baseurl=https://downloads.claude.ai/claude-code/rpm/stable` |
| 切り替え 2 | `stable` のメタデータ（10 kB）を取得し、`Downgrading: claude-code x86_64 2.1.274-1 claude-code 98 M` → `Downgraded: claude-code-2.1.274-1.x86_64` |
| 切り替え 3 | repoquery の 2 行がどちらも `claude-code 2.1.274-1 claude-code`。`claude --version` → `2.1.274 (Claude Code)` |
| 追加: もう一度 `distro-sync` | `Nothing to do.`。`/var/cache/dnf/` の claude-code のキャッシュが、チャンネルごとに別のディレクトリ（2 つ）になっていた |
| 切り替え 4 | `baseurl` が `latest` に戻り、`Upgrading: claude-code x86_64 2.1.283-1` → `Upgraded: claude-code-2.1.283-1.x86_64` |
| ロールバック 1 | `Removing: claude-code x86_64 2.1.283-1 @claude-code 230 M` → `Removed: claude-code-2.1.283-1.x86_64` |
| 追加: `command -v claude` | 同じシェルでは `/usr/bin/claude` を返した（ファイルはもう無い）。`hash -r` の後は何も返さず終了コード 1 |
| ロールバック 2・3 | repo ファイルが消え、`rpm -e` は終了コード 0。gpg-pubkey は AlmaLinux の鍵だけに戻った。`~/.claude/` と `~/.claude.json` は残った |

1 つ目のコンテナでも同じ版（`2.1.283-1` → `2.1.274-1` → `2.1.283-1`）で、鍵の rpm 名も実機と同じ `gpg-pubkey-1a7ecace-69caef70` だった。

##### Claude Code: 残っている未確認事項

- 2026-09-22 の未確認事項のうち、`latest` の動作・`stable` との切り替え・未認証での `claude doctor`・ロールバックの本実行は、この検証で確かめた（x86_64 のコンテナ）
- 実機（aarch64）での `latest`。aarch64 の `latest` にも `2.1.283-1` があることは repodata で確かめた
- 手順 5 の認証と、認証後の `claude doctor`（コンテナでは未認証のまま）
- ネイティブインストーラ版・npm 版との併存時の優先順位（`~/.local/bin/claude` が PATH の先にある場合）

#### Claude Code: 付録: 使い方の基本の検証記録（2026-10-01）

**ログインの要らないもの**: [tmux.md の付録](almalinux-setup.md#tmux-付録-コンテナでの検証記録2026-10-01)と同じ x86_64 の AlmaLinux 10 のコンテナ（`10-init`、systemd と sshd）に、手順 2〜4 の `latest` で `claude-code-2.1.287-1` を入れ、SSH でログインした一般ユーザー（ログインしていない）で実行した。

| コマンド | 結果 |
|---|---|
| `claude auth status --text` | `Not logged in. Run claude auth login to authenticate.`、終了コード 1。`--text` を外すと JSON（`"loggedIn": false`） |
| `claude doctor` | `Package manager: rpm`・`Auto-updates: Managed by package manager`・`No installation issues found.`。`Remote Control` の段に `Not signed in to claude.ai` など 5 行 |
| `claude update` | `Current version: 2.1.287` の後に `Claude is managed by a package manager.` と `Please use your package manager to update.`、終了コード 0 |
| `claude mcp add hello -- /usr/bin/echo hi` | `Added stdio MCP server hello with command: /usr/bin/echo hi to local config`、`File modified: ~/.claude.json [project: <PROJECT_DIR>]` |
| `claude mcp add -s user …` | `to user config`、`File modified: ~/.claude.json` |
| `claude mcp add --transport http -s project web https://mcp.example.invalid/mcp` | `.mcp.json` に `"type": "http"` と `url` が書かれた |
| `claude mcp list` / `get` | `✘ Failed to connect`（`echo` は MCP サーバーではないので）。`get` は `Scope: Local config (private to you in this project)` と、消すときの `claude mcp remove hello -s local` |
| `claude mcp remove …` | 3 つとも消え、`list` は `No MCP servers configured.` に戻った |
| `claude -p "hi"` | `Not logged in · Please run /login`、終了コード 1 |
| `claude remote-control --name proj --spawn same-dir` | `Error: You must be logged in to use Remote Control.`、終了コード 1。`claude remote-control --help` もログインしていないと同じエラーで、help は出なかった |
| `claude --name hup-test`（SSH のシェルで、tmux を使わずに起動） | SSH のクライアントを落とすと、`claude` のプロセスも消えた |
| `claude auth status --text` の後ろに `echo` の 2 行を続けて貼る（ブラケットペースト無し） | `echo` は 2 行とも実行されなかった。`claude --version` や `claude doctor \| head -3` の後ろの `echo` は実行された |

**ログインの要るもの**: クラウドのホスト（Ubuntu 24.04、x86_64）にあったログイン済みの Claude Code 2.1.287（`claude auth status --text` は `Login method: Claude API account`）で、空のディレクトリから実行した。その環境の Claude Code の環境変数を引き継がないように `env -i` で HOME・PATH・プロキシだけを渡した。

| コマンド | 結果 |
|---|---|
| `claude -p "1+1 の答えの数字だけを返して"` | `2` |
| `echo "hello tmux" \| claude -p "標準入力の文字列を大文字にして、それだけを返して"` | `HELLO TMUX` |
| `claude -p --output-format json "…" \| jq …` | `result` が `5`、`num_turns` が 1、`is_error` が false。キーは `result`・`session_id`・`total_cost_usd`・`permission_denials` など 25 個 |
| `claude -p -n tmux-test "合言葉は「りんご」です…"` → `claude -c -p "合言葉を答えて…"` → `claude -r tmux-test -p "…"` | `了解`、`りんご`、`りんご` |
| `claude -p "touch made.txt を実行して…"` | `承認が得られず、実行できませんでした。`、`permission_denials` に `Bash`。ファイルはできなかった |
| 同じ指示に `--allowedTools "Bash(touch *)"` | `成功しました。`、ファイルができた |
| `date +%Y` を実行させる指示（`--allowedTools` 無し） | 聞かずに動き、`2026` |
| 同じ指示に `--max-turns 1` | `subtype` が `error_max_turns`、`is_error` が true、終了コード 1 |
| `--model haiku` | `modelUsage` のキーが `claude-haiku-4-5-20251001` |
| `--permission-mode plan` で `touch` を実行させる指示 | プランモードのため実行しなかった、と答え、ファイルはできなかった |
| 作業ディレクトリの外のファイルを Read で読ませる指示 | `--add-dir` 無しでは `permission_denials` に `Read`。`--add-dir <そのディレクトリ>` 付きで中身（`banana`）を返した |

- 対話の `claude` は、ログインしていないコンテナではテーマを選ぶ最初の画面まで（tmux の中でも同じ）。ログイン済みのホストでも、`env -i` で起動すると最初の設定の画面からログインの方法を選ぶ画面に進んだので、そこで止めた（ログインはしていない）
- セッションの中のキーとスラッシュコマンドは、公式ドキュメントの Interactive mode と Commands の表から載せた

---

#### Claude Code: 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜4。

**結果**: 既定の `latest` チャンネルで署名鍵の fingerprint を本文と比べて取り込み、`claude-code-2.1.289-1` を導入した。導入済み版とリポジトリの版の一致、`/usr/bin/claude`、ライセンスの場所を確認した。

**今回の未確認範囲**: 認証・AI への依頼・Remote Control・Windows の手順、更新・ロールバックは今回流していない。

#### Claude Code: 付録: 現行版の新規 VM での再検証（2026-10-06）

公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active）で、`5da3478` の本文を SSH 対話 PTY に渡した。試験専用のユーザー・鍵と設定値を使用し、利用者の実アカウントの資格情報は持ち込んでいない。

実施手順 1〜4 を latest のまま通し、署名鍵の fingerprint が本文と一致することを確認した。claude-code 2.1.291-1 が入り、installed / available の最新値も一致、`claude --version` は 2.1.291 だった。実アカウントの認証・AI への依頼・stable 切替・更新・ロールバックはこの再検証で行っていない。

#### Claude Code: 手順中の実測・検証状況の記録

**セッションの中の操作**（公式ドキュメントの [Interactive mode](https://code.claude.com/docs/en/interactive-mode) と [Commands](https://code.claude.com/docs/en/commands) から。本書では確かめていない）

#### Claude Code: 手順中の実測・検証状況の記録

- **Windows PowerShell 5.1 からパイプで渡すと、ASCII でない文字は化けるはず**: native のコマンドへのパイプは `$OutputEncoding`（5.1 の既定は ASCII）で送られる（[about_Preference_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-5.1)）。日本語の指示は引数で渡す（確かめていない）

#### Claude Code: 手順中の実測・検証状況の記録

| `claude remote-control --name <名前> --spawn same-dir` | Remote Control のサーバーを始める（[tmux.md の任意節](../almalinux-setup.md#claude-code-を-tmux-の中で動かす任意)。Windows は [windows-claude-remote-control.md](../windows-claude-remote-control.md)）。本書では、ログインしていないときのエラーだけを確かめた |

#### Claude Code: ロールバック / 手順 1: 補足: 消えたかの確かめ方

`claude` を実行したことのある同じシェルでは、消した後も `command -v claude` が `/usr/bin/claude` を返した（bash がコマンドの場所を覚えているため）。`hash -r` の後か新しいシェルで確かめると、何も返さない。

---

## 統合前の記録: Codex CLI（もとは codex.md）

もとの `codex.md` の検証記録を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の検証記録](windows-setup.md#統合前の記録-codex-cli-の-windows-11もとは-codexmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜8 | 「Codex CLI」の手順 1〜8 |
| 更新 1〜3 | 更新の手順 5〜7 |
| ブラウザの無いホストでログインするの 1〜4 | Codex CLI をブラウザの無いホストでログインするの 1〜4 |
| 設定ファイル | Codex CLI の設定ファイル |
| ロールバック 1〜3 | ロールバックの「AI エージェントとプラグインを消す」の手順 5〜7 |

### Codex CLI: 現在の検証状態（2026-10-10）

- Raspberry Pi 5 / AlmaLinux 10.2 / aarch64 の実機で、専用の一般ユーザー `<TEST_USER>` に公式インストーラーで Codex 0.161.0 を導入し、0.162.1 への手動更新・再導入・新しいシェルと CLI の撤去を確認した（[今回の付録](#codex-cli-付録-raspberry-pi-5--aarch64-実機での検証2026-10-10)）。
- 起動時の実際のネットワーク問い合わせで 0.162.1 の更新キャッシュが自然生成され、次回 TUI に更新選択肢が表示された。自作 PTY ドライバーでの試験と分けて、実端末の PTY で Enter を入力し、0.161.0 → 0.162.1 の更新成功・正常終了を確認した。PATH ブロック追加と再導入時の重複防止も確認済み。
- 既存ユーザー `<USER>` の Codex 0.160.0 と Grok 1.0.50 は更新せず、既存認証を利用する確認を分けて実施した。初回ログイン・ブラウザでの承認・デバイスコード認証の操作そのものは今回の記録対象外。
- 検証後は専用ユーザーで追加した状態・ユーザー・ホームを撤去し、OS の RPM 一覧が実施前と同じことを確認した。Windows の実行、認証済みユーザーのログアウトは今回も未確認。

以下の「補足」から 2026-10-09 の付録・「本文から分離した確認範囲と実測」までは過去の記録を保持したものです。その中の実機・aarch64・認証後に関する未検証の記述は当時の状態を表します。

### Codex CLI: 補足

#### Codex CLI: 実施手順: 検証状況の記録

> [!WARNING]
> AlmaLinux 10.2 / x86_64 のクリーン VM で導入・版の確認・0.160.0 から 0.160.1 への更新を本実行した（2026-10-06、認証前まで）。以前のコンテナでは再導入・配布物の削除も検証した。実機、ログイン、AI への依頼は未検証（[検証範囲](#codex-cli-対象と検証環境)）。

#### Codex CLI: 対象と検証環境

- **目的**: Codex CLI を AlmaLinux 10 と Windows 11 に入れ、ログインと最初の起動まで進める
- **調査日**: 2026-10-05
- **状態**:
  - AlmaLinux 10: **10.2 / x86_64 のクリーン VM で実施手順 1〜4 と 0.160.1 への更新を本実行済み（2026-10-06、認証前まで）**。以前のコンテナでも検証。一般ユーザーで 0.160.0 の導入・`--version`・ヘルプ・未ログインの表示・同じ版の再導入・配布物の削除を確認
  - AlmaLinux 10（2026-10-09、コンテナ）: 起動したときの `Update available!` から 0.161.0 → 0.162.0 に上がることと、`codex update` を確認。Homebrew の cask と比べた（[付録](#codex-cli-付録-起動したときの更新とパッケージマネージャー2026-10-09)）
  - AlmaLinux の実機・aarch64・ログイン後の対話画面・sandbox 内のコマンド実行は未検証
  - Windows 11: 公式資料と `install.ps1` の読み取り、文書の PowerShell ブロック 10 個を Linux の PowerShell 7.6.6 で構文検査（エラー 0）。Windows PowerShell 5.1 での実行は未検証
  - Windows の実機でのインストール・PATH・認証・sandbox・更新・削除、ARM64 は未検証
  - 共通: ChatGPT へのログイン、デバイスコード認証、AI への依頼は未検証

#### Codex CLI: 選択した方針

- 公式 CLI のページが案内する standalone インストーラーを採る。Node.js やパッケージマネージャーの導入を増やさず、両 OS で同じ配布元を使える
- Windows は native の PowerShell で使う。Linux 用の開発環境が必要な場合の WSL は、本書の対象外
- AlmaLinux 専用の公式対応表を確認したわけではない。Linux 用配布物を AlmaLinux 10 で確認した範囲だけを検証済みとする
- 更新は、起動したときの知らせ（`1. Update now`）と、公式 CLI ページと同じインストーラーの再実行で説明する（前者は 2026-10-09 に追加）
- パッケージマネージャー（Homebrew の cask・scoop・WinGet）では入れない。理由は[参考資料](../reference/almalinux-setup.md#codex-cli-実施手順--手順-3-補足-パッケージマネージャーで入れない理由)

#### Codex CLI: 完了時点の状態

- 以下は読者が手順を終えたときの確認点。今回の検証でログイン・AI 応答まで通したという意味ではない
- 自分のユーザーで `codex --version` と `codex login status` を実行できる
- `codex-sandbox` で Codex を起動して応答を確認できる
- 実際のプロジェクトでは、そのディレクトリへ移って `codex` を起動する

#### Codex CLI: 付録: コンテナと構文の検証記録（2026-10-05）

- 検証環境はクラウドの Linux 上の Docker。`almalinux:10` は AlmaLinux 10.2 (Lavender Lion) / x86_64 だった
- Docker イメージの digest は `sha256:838c2fafefb1a8a0d7f8cdbc3b0551c2a2b1eb0cd87aad6d62aecadb18311f1b`
- 検証用の一般ユーザーを作り、そのログインシェルで実行した。ホストの Codex・設定・認証情報には触れていない
- 検証環境だけで、プロキシと CA バンドルを渡した。dnf のミラー選択が遅かったため、BaseOS / AppStream は `repo.almalinux.org` を指定した（署名検証は有効）
- インストーラーの質問を出さないため、検証時だけ `CODEX_NON_INTERACTIVE=1` を渡した。初回は取得した `install.sh` を `sh` で実行し、再導入は本文と同じ `curl … | sh` で実行した

| 確認 | 結果 |
|---|---|
| 初回導入 | `0.160.0-x86_64-unknown-linux-musl` を取得し、成功の表示まで進んだ |
| PATH と版 | ログインシェルには最初から `~/.local/bin` があり、`codex --version` は `codex-cli 0.160.0` |
| `codex --help`・`codex login --help` | 正常終了。`login status` と `--device-auth` の存在を確認 |
| `codex login status` | `Not logged in`、終了コード 1（ログインは行っていない） |
| インストーラーの再実行 | `Updating Codex CLI` と出て、同じ 0.160.0 を再選択して正常終了 |
| 確認用の作業場所 | ディレクトリ作成と `git init` が正常終了。対話の `codex` は起動していない |
| `codex logout` | 未ログインのため `Not logged in`。認証済みの資格情報を消す動作は未検証 |
| Linux のロールバック | リンク 2 本と `packages/standalone` を削除後、`command -v codex` が終了コード 1。`.codex` 自体は残った |
| bash のブロック 13 個 | `bash -n` で構文の誤り 0 |
| PowerShell のブロック 10 個 | Linux の PowerShell 7.6.6 の構文解析器で誤り 0。Windows の API・レジストリ・ジャンクションの動作や 5.1 との互換を保証する検査ではない |

読み取った公式インストーラーの SHA-256:

| ファイル | SHA-256 |
|---|---|
| `install.sh` | `150e3cf675682efeaac115aa3747add3f27887896d04ce6d0b56478d8b428bf6` |
| `install.ps1` | `3522b77d4485eac014e70fa946787c95fad3874a4e9047557c1e044eb268d13e` |

- インストーラーが PATH に行を足す分岐、別の方法で導入済みの場合の移行、Windows の処理はソースを読んだだけ
- 上のハッシュは調査対象を識別するための記録で、将来のインストーラーにそのまま適用する固定値ではない

---

#### Codex CLI: 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜4、更新の手順 2・3に相当するインストーラーの再実行と版の確認。

**結果**: 公式 standalone インストーラーで Codex CLI 0.160.0 を導入した。Workstation に curl があったため、本文の案内どおり手順 2 の `curl-minimal` は外した。同じインストーラーを再実行すると、検証中に最新が変わっており 0.160.0 から 0.160.1 へ更新された。`Start Codex now?` は `n` と答え、最終の `codex --version` は `codex-cli 0.160.1`、`codex login status` は `Not logged in`。`~/.local/bin/codex` で見つかることを確認した。

**今回の未確認範囲**: 認証・AI への依頼・対話画面・sandbox での実行、Windows の手順、ロールバックは今回確認していない。

#### Codex CLI: 付録: 現行版の新規 VM での再検証（2026-10-06）

公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active）で、`5da3478` の本文を SSH 対話 PTY に渡した。試験専用のユーザー・鍵と設定値を使用し、利用者の実アカウントの資格情報は持ち込んでいない。

実施手順 1〜4 を通した。事前の command -v は終了 1、standalone の Codex CLI 0.160.1 が入り、実行場所は自分の ~/.local/bin/codex だった。依存の curl-minimal の指定は、導入済み curl へ解決して成功し、競合は起きなかった。~/.local/bin は OS 既定の PATH にあり、インストーラも既存 PATH と表示した。起動の質問には n と答え、`codex login status` は Not logged in（終了 1）。実アカウントの認証・AI への依頼・更新・ロールバックは行っていない。

#### Codex CLI: 付録: 起動したときの更新とパッケージマネージャー（2026-10-09）

利用者の依頼（パッケージマネージャーで入れられるならその手順にする。自動で最新になるなら公式の方法でよい）を受けて、公式インストーラーの更新の動きと、Homebrew の cask を比べた。

| 項目 | 値 |
|---|---|
| 環境 | クラウドの Linux の Docker の上の `almalinux:10`（AlmaLinux 10.2、x86_64、digest `sha256:838c2fafefb1a8a0d7f8cdbc3b0551c2a2b1eb0cd87aad6d62aecadb18311f1b`）。プロキシの環境変数と CA を渡した |
| 版 | Codex CLI 0.161.0（古い版として入れた）と 0.162.0（調査時の最新） |
| 公式インストーラーの確認 | 新規の一般ユーザー（`/etc/skel` の `.bashrc`）。端末の代わりに `script` の PTY（150×40） |
| Homebrew の確認 | 別のコンテナの一般ユーザー。[共通の bash 設定](https://github.com/ryo-aoki-pc/bash)と Homebrew 7.0.9 |

**公式インストーラーで入れた Codex の起動時の更新**:

- 古い版は `curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh -s -- --release 0.161.0` で入れた（`~/.local/bin` が PATH に無いユーザーなので、`~/.bashrc` に PATH のブロックが足された）
- 対話の画面を起動すると、最新の版を `https://api.github.com/repos/openai/codex/releases/latest` に問い合わせた
- この検証環境では、その問い合わせが `403 Forbidden` で失敗し（`~/.codex/logs_2.sqlite` に `Failed to update version`）、`~/.codex/version.json` はできなかった
- そこで、`~/.codex/version.json` に `latest_version` を `0.162.0`、`last_checked_at` を今の時刻にして書き、起動した
- 画面に `Update available!`・`0.161.0 -> 0.162.0`・`1. Update now`（`sh -c 'curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh'` を動かすと表示）・`2. Skip`・`3. Skip until next version` が出た
- Enter を押すと、`Updating Codex CLI from 0.161.0 to 0.162.0` から `Codex CLI 0.162.0 installed successfully.`・`Update ran successfully! Please restart Codex.` まで進んで、画面が終わった
- その後の `codex --version` は `codex-cli 0.162.0`。`~/.codex/packages/standalone/releases` には 0.161.0 と 0.162.0 が残った
- `version.json` が新しいうちの起動では、問い合わせは行われなかった（ログに無い）
- `codex update`（最新のとき）: 同じインストーラーが動き、`Codex CLI 0.162.0 installed successfully.`・`Update ran successfully! Please restart Codex.`、終了コード 0
- 対話の画面は、終わった後も `codex app-server --listen unix:// --managed-daemon`（配布物は `~/.codex/packages/app-server-daemon/`）を残した。`codex app-server daemon stop` で止まった
- 確認していないこと: GitHub への問い合わせが通ったときの知らせ（この環境では通らない）、ログイン後の画面、Windows 11

**Homebrew の cask**（`brew install --cask codex`）:

- 0.162.0 が入り、`/home/linuxbrew/.linuxbrew/bin/codex` にリンクされた。bash の補完は `$(brew --prefix)/etc/bash_completion.d/` に入り、`~/.bashrc` は変わらなかった
- `codex update`: `Error: Could not detect the Codex installation method. Please update manually: https://developers.openai.com/codex/cli/`、終了コード 1
- `brew outdated --cask` と `brew upgrade --cask codex` は動いた（最新なので上げるものは無かった）
- `brew uninstall --cask codex` はリンクを消し、`~/.codex` は残った
- 共通の bash 設定では Homebrew の `bin` が `~/.local/bin` より PATH で先なので、standalone の Codex が残っていても Homebrew の方が動いた

**ほかの配布**（定義を読んだだけ）:

- scoop の main の `codex` は 0.162.0。extras には無い
- WinGet の `OpenAI.Codex` は 0.161.0（zip の中の実行ファイルを portable で置く）

### Codex CLI: 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### Codex CLI: 付録: Raspberry Pi 5 / aarch64 実機での検証（2026-10-10）

| 項目 | 値 |
|---|---|
| 環境 | Raspberry Pi 5、AlmaLinux 10.2 (Lavender Lion)、aarch64、kernel `6.12.96-20260724.v8.1.el10` |
| 対象 | setup-notes #117、取得時の commit `814b590` |
| 実行ユーザー | 新規の一般ユーザー `<TEST_USER>` のログインシェル。HOME・CODEX_HOME は変更せず、既存ユーザー `<USER>` の設定・認証をコピーしていない |
| 版 | 指定した旧版 0.161.0 と、実行時の最新 0.162.1（aarch64 の standalone 配布物） |
| インストーラー | `https://chatgpt.com/codex/install.sh` を取得して `sh` で実行。SHA-256 `150e3cf675682efeaac115aa3747add3f27887896d04ce6d0b56478d8b428bf6`（2026-10-10 取得） |
| 認証 | 試験ユーザーの `codex login status` は `Not logged in`、終了コード 1。既存ユーザーの初回認証・ログアウトは行っていない |

#### Codex CLI: 導入・手動更新・再導入

| 確認 | 実測結果 |
|---|---|
| 古い版の導入 | `CODEX_NON_INTERACTIVE=1 sh install.sh --release 0.161.0` が成功、終了コード 0。`codex --version` は `codex-cli 0.161.0` |
| 新しいシェル | `bash -lic` で `~/.local/bin/codex` と 0.161.0 を確認。OS 既定の PATH には最初から `.local/bin` があり、この実行では installer の PATH ブロックは追加されなかった |
| 手動更新 | 公式インストーラーを `CODEX_NON_INTERACTIVE=1` で再実行し、0.162.1 を導入。終了コード 0。更新前後の `.bashrc` の `cmp` も終了コード 0 |
| 同じ版の再導入 | インストーラーをもう一度実行し、終了コード 0 と 0.162.1 を確認 |
| 更新後の新しいシェル | `~/.local/bin/codex` と `codex-cli 0.162.1` を確認 |

#### Codex CLI: 実ネットワークの問い合わせと TUI 更新

- 古い 0.161.0 で、この試験ユーザーの更新キャッシュを外して、実際の PTY で `codex` を起動した。初回の起動後、`~/.codex/version.json` に `latest_version = 0.162.1` と `last_checked_at = 2026-10-10T02:33:19.438477340Z` が自然生成された。2026-10-09 のコンテナ記録と異なり、最新版・時刻を手で注入していない。
- 次回起動の画面に `1. Update now` と、公式インストーラーを `CODEX_NON_INTERACTIVE=1` で実行するコマンドが表示された。初回の PTY ドライバーは画面の特定文字列も同時に要求していたため Enter を送らず、120 秒後に SIGINT で終了した。内側の CLI は終了コード -2、更新前後の版は 0.161.0 のままであり、この回を TUI 更新成功とはしていない。
- 更新選択肢を固有のインストーラー URL と組み合わせて検出するようドライバーを修正して再試験した。実ネットワークの再問い合わせで `last_checked_at = 2026-10-10T02:47:04.461504665Z` のキャッシュが自然生成され、更新選択肢を検出して Enter を送ったが、120 秒後も版は 0.161.0 のまま（SIGINT、子プロセスの戻り値 -2）。入力の受理・インストーラー実行は確認できず、この回も TUI 更新成功とはしていない。初回の出力は別の控えに保存した。
- 続いて 0.161.0 を入れ直し、試験ユーザーの実端末の PTY で `TERM=xterm-256color codex` を起動した。0.161.0 → 0.162.1 の更新メニューを確認して Enter を入力すると、`Updating Codex`、aarch64 の standalone 配布物の導入、`Codex CLI 0.162.1 installed successfully.`、`Update ran successfully! Please restart Codex.` まで進み、終了コード 0 で終わった。直後の `codex --version` も `codex-cli 0.162.1`、終了コード 0。手動の再導入と分けた TUI 更新の成功として記録する。
- 実端末の初回起動は `TERM=dumb` が CLI に拒否されたため、端末種別を指定して再実行した。自作ドライバーの入力が受理されなかった原因は断定していない。画面収集用ドライバーの終了コード 0 と、内側の CLI の更新成功は分けて判定した。

#### Codex CLI: PATH ブロック追加の補助試験

- 既定のログイン PATH では `.local/bin` がすでに含まれるため、インストーラーを呼ぶときだけ `PATH=/usr/bin:/bin` として、同じ専用ユーザーの HOME で再実行した。`PATH was added to /home/<TEST_USER>/.bashrc` と成功を表示し、0.162.1 を確認した。
- Codex の開始・終了 marker がそれぞれ 1 個あり、無関係の確認用行が保持されることを確認。再実行しても `.bashrc` のバイト比較は一致した（終了コード 0）。
- Codex のブロックだけを控えに抽出し、OS のシェル設定を読み込まない `bash --noprofile --norc` で読み込むと `~/.local/bin/codex` と 0.162.1 が見つかった。既定 `.bashrc` の PATH 追加とは分けて検査した。

#### Codex CLI: CLI の撤去と残る範囲

- 試験ユーザーの `codex app-server daemon stop` は終了コード 0。リンクと `~/.codex/packages/standalone` を撤去した後、新しいログインシェルの `command -v codex` は終了コード 1。無関係の `.bashrc` の行は保持した。
- 初回の撤去補助では `rg` が試験ユーザーの PATH に無く、installer ブロック削除の条件が実行されなかった。`grep` に置き換えた再試験では、開始・終了 marker の不在を明示的に検査して終了コード 0。新しいシェルでの CLI 不在と、無関係の行・確認用リンクの保持も再確認した。
- CLI のロールバックでは `.codex` の設定・履歴等を保持する本文の方針に合わせた。その確認後、今回作成した未認証の専用ユーザーで追加した検証状態だけを片付けるため、別の最終復元操作として `.codex` を撤去した。通常の CLI ロールバックで既存ユーザーの `.codex` 全体を消す手順ではない。
- 最終復元では CLI 状態の不在・新しいシェルでの CLI 不在・無関係の確認用行とリンクの保持をすべて終了コード 0 で確認した。今回作成したユーザー・同名グループ・ホームを削除し、OS の `rpm -qa` をソートした一覧の SHA-256 は実施前後で一致した。
- 実機での導入・更新確認は、初回の ChatGPT ログイン、ブラウザ承認、デバイスコード認証の操作、Windows の実行の証明にはしない。

---

## 統合前の記録: Grok Build（もとは grok-build.md）

もとの `grok-build.md` の検証記録を、内容を変えずに移したもの（Windows 11 の節は、[Windows 11 の初期設定の検証記録](windows-setup.md#統合前の記録-grok-build-の-windows-11もとは-grok-buildmd)に移した）。見出しはこの文書の中で重ならないように、頭にツールの名前を付けて 1 段下げた。リンクは今の場所に直したが、本文の「手順 N」と、リンクの文字の文書名は、当時の手順書のまま。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜7 | 「Grok Build」の手順 1〜7 |
| 更新 1・2 | 更新の手順 5・8 |
| ブラウザの無いホストでログインするの 1〜3 | Grok Build をブラウザの無いホストでログインするの 1〜3 |
| 設定ファイル | Grok Build の設定ファイル |
| ロールバック 1〜4 | ロールバックの「AI エージェントとプラグインを消す」の手順 8〜11 |

### Grok Build: 現在の検証状態（2026-10-10）

- Raspberry Pi 5 / AlmaLinux 10.2 / aarch64 の実機で、専用の一般ユーザー `<TEST_USER>` に公式インストーラーで導入し、Grok 1.0.49 → 1.0.50 の自動更新・更新停止・手動更新・再導入・新しいシェルと CLI の撤去を確認した（[今回の付録](#grok-build-付録-raspberry-pi-5--aarch64-実機での検証2026-10-10)）。
- 既存ユーザー `<USER>` の Grok 1.0.50 と Codex 0.160.0 は更新せず、既存認証を利用する確認を分けて実施した。初回ログイン・ブラウザでの承認・デバイスコード認証の操作そのものを通した記録ではない。
- 検証後は専用ユーザーの CLI 状態・ユーザー・ホームを撤去し、OS の RPM 一覧が実施前と同じことを確認した。Windows 11 の実行、X Premium（Plus でない）での利用、認証済みユーザーのログアウトは今回も未確認。
- sandbox の追加調査では、Podman のソケット親ディレクトリの検索権限と、カーネルで Landlock が未有効であることを別々の原因として確認した。Landlock を有効にする Image のビルドと 7 項目の静的検査、検索権限だけを与える ACL の模擬試験は成功した。ユーザーの指示により実機への適用・再起動・再検証は行わず、調査と準備までで終了した。Grok の sandbox レビューの失敗は未解消（[対処の準備結果](#grok-build-sandbox-の追加原因調査と対処の準備)）。
- 同日の再起動なしの追加検証では、実ホストの `/run/podman` に検索だけの ACL を約 2 分適用し、errno 13 の解消と、一覧・作成の拒否、元の状態への復元を確認した。起動時のシステムコールの追跡で、`read-only` は Podman のソケットの確認（`EACCES`）、`workspace` は `landlock_create_ruleset` の `ENOSYS` で止まることを特定した。Landlock が有効なカーネルでの起動は今回も行っておらず、sandbox が起動した状態は未確認のまま（[再起動なしの追加検証](#grok-build-sandbox-の再起動なしの追加検証)）。

以下の「対象と検証環境」と 2026-10-09 の付録は過去の記録を保持したものです。その中の「実機・aarch64 未確認」は当時の状態を表します。

### Grok Build: 対象と検証環境

- **状態（2026-10-09 UTC）**: AlmaLinux 10.2 / x86_64 のコンテナで、ログインの前までを、手順書のコードブロックのまま本実行した。実機・VM ではない
  - 通したもの: 実施手順の手順 1〜3、手順 4（URL とコードを出して待つところまで）、手順 6（ログインしていないときの表示）、手順 7 のディレクトリの準備（`grok` の画面は起動していない）、更新の手順 2、ロールバックの手順 1〜4
  - 確かめたこと: インストーラーが置くもの、`~/.bashrc` のブロックと控え、`~/.local/bin` のリンク（Codex を先に入れたユーザーでは置かれ、入れていないユーザーでは置かれない）、2 回目のインストーラーの動き、`grok update` が `~/.bashrc` を変えないこと、ロールバックの後に Codex のリンクが残ること
  - 確かめたこと（追加の検証）: 1.0.49 から 1.0.50 への自動の更新（対話の画面の起動のとき）、`[cli] auto_update = false` で止まること、Homebrew の cask との違い（[付録](#grok-build-付録-自動の更新とパッケージマネージャー2026-10-09)）
  - 確かめたこと: `grok --trust inspect` が、ログイン無しで、読み込む指示書（AGENTS.md・CLAUDE.md・CLAUDE.local.md・`~/.claude/CLAUDE.md`）を一覧すること
  - 確かめたこと: bash の 13 ブロックの `bash -n`（エラー 0）と ShellCheck 0.9.0（指摘は手順 7 の `cd ~/grok-sandbox` の SC2164 だけ。直前の `mkdir -p` で作るので、codex.md の手順 8 と同じ形のままにした）
  - 確かめたこと: Windows 11 の節の PowerShell の 12 ブロックの構文（Linux の PowerShell 7.6.6 の構文解析器でエラー 0。PSScriptAnalyzer 1.25.0 の 5.1 互換の検査で指摘 0）
  - **確認していないこと**: grok.com でのログインと、その後（手順 5 の承認、手順 6 のログイン済みの表示、手順 7 の画面・フォルダーの信頼・AI への依頼）。X Premium（Plus でない）での利用。aarch64。実機・VM
  - **確認していないこと**: Windows 11 での実行すべて（インストーラー、PATH、ログイン、更新と自動の更新、ロールバック）

| 項目 | 値 |
|---|---|
| 実施日 | 2026-10-09 UTC |
| 環境 | クラウドの Linux の Docker 29.8.2 の上の `almalinux:10`（AlmaLinux 10.2 (Lavender Lion)、x86_64、digest `sha256:838c2fafefb1a8a0d7f8cdbc3b0551c2a2b1eb0cd87aad6d62aecadb18311f1b`） |
| Grok Build | 1.0.50（`c58f321264ba`）、stable のチャンネル |
| インストーラー | `install.sh` の SHA-256 `7fd6fdc75d9418b2e58356726fcbf1ae849416f773925da07d0ccc7a60d3e791`、`install.ps1` の SHA-256 `c83dac29885215c79137e48cbc034d3d7c8c11afba3082ff1df0e0769aa902a4`（どちらも 2026-10-09 に取得） |
| ほかに入れたもの | git 2.52.0-1.el10、curl 8.12.1（イメージにあったもの）、Codex CLI 0.162.0（[codex.md](../almalinux-setup.md#codex-cli) の手順 3 と同じインストーラー。`~/.local/bin` があるときの確認用） |
| 実行ユーザー | 新規の一般ユーザー（`/etc/skel` の `.bashrc`）。`SHELL=/bin/bash`、umask 0022 |
| PowerShell の検査 | Ubuntu 22.04 のコンテナの PowerShell 7.6.6、PSScriptAnalyzer 1.25.0 |

> [!NOTE]
> 出力の中の利用者名は `<USER>`、ログインの確認用のコードは `<CODE>` に置き換えた。ログイン情報・トークンは作っていない。

#### Grok Build: 実施前の状態

- `grok`・`agent` のコマンドと `~/.grok` は無い
- `~/.bashrc` は `/etc/skel` のもの（`~/.local/bin` と `~/bin` を PATH の先頭に足す行がある）
- Codex を先に入れたユーザーでは、`~/.local/bin/codex`（`~/.codex/packages/standalone/current/bin/codex` へのリンク）がある

#### Grok Build: 完了時点の状態

- 以下は読者が手順を終えたときの確認点。今回の検証でログイン・AI への依頼まで通したという意味ではない
- `grok --version` が新しい端末でも通り、`grok models` に `You are not authenticated.` が出ない
- `~/.bashrc` の末尾に `# >>> grok installer >>>` のブロックがある
- ロールバックの手順 1〜4 の後は、`grok`・`agent` のコマンドと `~/.grok` が無く、`~/.bashrc` は空行を除いて `~/.bashrc.bak.<数字>` と同じになる

### Grok Build: 付録: コンテナでの検証（2026-10-09）

#### Grok Build: 検証環境にだけ加えた調整

- コンテナの中から外へ出るために、プロキシの環境変数と CA を渡した（`--network host`、CA は `update-ca-trust` で取り込んだ）
- `docker exec` は `SHELL` を設定しないので、`SHELL=/bin/bash` を渡した（インストーラーは `SHELL` で書くファイルを決め、空なら何も書かない）
- umask をログインのシェルと同じ 0022 にした（`docker exec` の既定は 0000 で、最初の 1 回だけはその値で動かした）
- ログインはしないので、手順 4 と、ブラウザの無いホストでログインするの手順 1 は、8〜10 秒で `timeout` で止めた

#### Grok Build: 実施手順 / 手順 1〜3

- 手順 1: `/usr/bin/curl` だけが出て、`ls: cannot access '/home/<USER>/.grok': No such file or directory`
- 手順 2（Codex を先に入れたユーザー）:

  ```text
  Fetching latest stable version...
  Installing Grok 1.0.50 (linux-x86_64)...
    Downloading grok 1.0.50...
    Binary linked to /home/<USER>/.grok/bin/grok and /home/<USER>/.grok/bin/agent.
  Grok 1.0.50 installed to /home/<USER>/.grok/bin/grok
    Symlinked /home/<USER>/.local/bin/grok -> /home/<USER>/.grok/bin/grok
    Symlinked /home/<USER>/.local/bin/agent -> /home/<USER>/.grok/bin/agent
    Updated /home/<USER>/.grok/bin in PATH in /home/<USER>/.bashrc.

  Run 'grok' or 'agent' to get started!
  ```

- 手順 2（Codex を入れていないユーザー。`~/.local/bin` が無い）: `Symlinked …` の 2 行が無く、最後が `Restart your terminal, then run 'grok' or 'agent' to get started!` になった
- 置かれたもの: `~/.grok/{bin,completions,docs,downloads}` と `~/.grok/config.toml`（`[cli]`・`installer = "internal"`）。配布物は `~/.grok/downloads/grok-linux-x86_64`（183,493,408 バイト）、`bin/grok` と `bin/agent` は `../downloads/grok-linux-x86_64` へのリンク。文書は `~/.grok/docs/user-guide/` に 27 本
- `~/.bashrc` に足されたもの（元のファイルとの差分）:

  ```text
  
  # >>> grok installer >>>
  export PATH="$HOME/.grok/bin:$PATH"
  [[ -r "$HOME/.grok/completions/bash/grok.bash" ]] && source "$HOME/.grok/completions/bash/grok.bash"
  # <<< grok installer <<<
  ```

  - 元のファイルは `~/.bashrc.bak.<UNIX 時刻>` に控えられた
- 手順 3: `/home/<USER>/.grok/bin/grok` と `grok 1.0.50 (c58f321264ba)`。新しいログインのシェルでも同じ
- インストーラーの 2 回目（同じユーザーで再実行）: `~/.grok/bin` がすでに PATH にあるので `Symlinked …` は出ず、`~/.bashrc` のブロックは消して末尾に足し直された（差分は空行 1 つ）。控えは増えない

#### Grok Build: 実施手順 / 手順 4・6、ブラウザの無いホストでログインする / 手順 1

- 手順 4（ブラウザの無いコンテナ）:

  ```text
  To sign in, open this URL in your browser:

    https://accounts.x.ai/oauth2/device?user_code=<CODE>

    (Could not open browser automatically — open the URL above manually.)

  Confirm this code in your browser:

    <CODE>

  Only continue with a code you requested. Don't share it with anyone.

  Waiting for authorization...
  ```

- ブラウザの無いホストでログインするの手順 1（`grok login --device-auth`）も、同じ表示で待った
- 手順 6（ログインしていない）: 終了コード 0

  ```text
  You are not authenticated.

  Default model: grok-4.6

  Available models:
    * grok-4.6 (default)
    - grok-4.5
  ```

- `grok logout`（ログインしていない）: `No cached session to log out of.`、終了コード 0
- `grok login --help`: `--oauth`（既定）と `--device-auth`（別名 `--device-code`）がある

#### Grok Build: 実施手順 / 手順 7

- `mkdir`・`cd`・`git init` だけを流した。`grok` の画面はログインしていないので起動していない（フォルダーの信頼を聞く画面・`/quit` は、同梱の文書 01-getting-started・04-slash-commands による）

#### Grok Build: 更新 / 手順 2

- `grok update --check`: `Grok Build - v1.0.50 (latest: 1.0.50) [stable]`、終了コード 0
- `grok update`: `Already up to date (1.0.50).`、`grok --version` は `grok 1.0.50 (c58f321264ba) [stable]`
- `grok update --force-reinstall`: `~/.grok/downloads/grok-1.0.50-linux-x86_64` を新しく取ってきてリンクを付け替え、前の `grok-linux-x86_64` も残った（2 つで約 350 MB）
- どれも `~/.bashrc` を変えなかった

#### Grok Build: ロールバック / 手順 1〜4

- 手順 1: `No cached session to log out of.`
- 手順 2: `~/.local/bin/grok`・`agent` が消え、`~/.local/bin/codex` は残った。最後の `command -v grok agent` は何も出さず、終了コード 1
- 手順 3: 最後に `0`。`~/.bashrc` は、空行を除いて `~/.bashrc.bak.<数字>` と同じになった（末尾に空行が 1 つ残る）
- 手順 4: `ls: cannot access '/home/<USER>/.grok': No such file or directory`
- 新しいログインのシェルで、`grok`・`agent` は見つからず、`codex` は `~/.local/bin/codex` で見つかった

#### Grok Build: grok inspect とフォルダーの信頼

- AGENTS.md と、`@AGENTS.md` の 1 行だけの CLAUDE.md を置いた使い捨てのリポジトリで確かめた（ログイン無し）
- `grok inspect`（信頼していない）: `Project trusted: no`、`Project Instructions (0)`
- `grok --trust inspect`: `Project trusted: yes`、`Project Instructions (2)` に `CLAUDE.md (project, ~2 tokens)` と `AGENTS.md (project, ~6 tokens)`。`~/.grok/trusted_folders.toml` に、そのディレクトリが `trusted = true` で書かれ、その後の `grok inspect` も `Project trusted: yes` になった
- CLAUDE.local.md と `~/.claude/CLAUDE.md` を足すと、`Project Instructions (4)` に `~/.claude/CLAUDE.md (global, …) [claude]` と `CLAUDE.local.md (project, …)` が加わった
- `--trust` は `grok --help` に載っていないが、`grok --trust inspect` の形で受け付けた（`grok inspect --trust` は `unexpected argument`）

#### Grok Build: sandbox と bubblewrap

- `grok -p "x" --sandbox read-only --always-approve` は、bubblewrap が無いコンテナでは `Error: this sandbox could not enforce its deny list on Linux: bwrap exec failed: …` で起動しなかった（終了コード 1）
- bubblewrap 0.10.0（BaseOS）を入れた `--privileged` のコンテナでは、sandbox の準備を過ぎて、ログインしていないことのエラーで終わった
- AlmaLinux 10 の Flatpak と `gnome-desktop3` は bubblewrap を必要とする（`dnf repoquery --whatrequires bubblewrap`）。GNOME のデスクトップの PC には入っているはず

### Grok Build: 付録: 自動の更新とパッケージマネージャー（2026-10-09）

利用者の依頼（パッケージマネージャーで入れられるならその手順にする。自動で最新になるなら公式の方法でよい）を受けて、公式のインストーラーで入れた Grok の自動の更新と、Homebrew の cask を比べた。

| 項目 | 値 |
|---|---|
| 環境 | 上の付録と同じ `almalinux:10`（別のコンテナ）。プロキシの環境変数と CA を渡した |
| 版 | Grok Build 1.0.49（古い版として `bash -s 1.0.49` で入れた）と 1.0.50（調査時の最新） |
| 公式のインストーラーの確認 | 新規の一般ユーザー（`/etc/skel` の `.bashrc`）。端末の代わりに `script` の PTY（150×40）で `grok` を 40 秒動かし、`timeout` で止めた。ログインはしていない |
| Homebrew の確認 | 別のコンテナの一般ユーザー。[共通の bash 設定](https://github.com/ryo-aoki-pc/bash)と Homebrew 7.0.9 |

#### Grok Build: 自動の更新

| 試したこと | 結果 |
|---|---|
| 1.0.49 を入れた直後に `grok`（対話の画面）を起動 | 起動した後に `~/.grok/downloads/grok-1.0.50-linux-x86_64` が入り、`~/.grok/bin/grok`・`agent` のリンクが付け替わった。`grok --version` は `grok 1.0.50 (c58f321264ba) [stable]`。`~/.grok/version.json` に `"version": "1.0.50"` と `checked_at` が書かれた |
| 入れ直した 1.0.49 で、`grok --version` を 3 回・`grok models`・`grok -p`（ログインしていないので終了コード 1） | どれも上がらなかった |
| `checked_at` が 3 分前のまま `grok` を起動 | 確かめず、上がらなかった |
| `checked_at` を 2 日前にし、`[cli]` に `auto_update = false` を書いて起動 | 確かめず（`checked_at` も変わらず）、上がらなかった |
| `checked_at` を 2 日前にし、`auto_update` の行を消して起動 | 1.0.50 に上がり、`checked_at` が起動の時刻になった |
| 自動の更新の前後の `~/.bashrc` | 変更時刻が変わらなかった（書き換えていない） |
| 上がった後の `grok update`・`grok update --check` | `Already up to date (1.0.50).`・`Grok Build - v1.0.50 (latest: 1.0.50) [stable]` |

- ログインしていない画面は、すぐにログインの案内（`Waiting for approval...`）になり、更新の知らせは画面に出なかった
- 前の配布物（`grok-linux-x86_64`）は残り、2 つで約 350 MB になった
- 確認していないこと: ログイン後の画面での知らせ、`checked_at` から確かめるまでの間隔、Windows 11 での自動の更新

#### Grok Build: Homebrew の cask

- `brew info --cask grok-build`: 1.0.50。`grok-1.0.50-linux-x86_64` を `grok` と `agent` の名前でリンクし、補完を作る
- `brew install --cask grok-build`: `/home/linuxbrew/.linuxbrew/bin/grok`・`agent` に入り、`~/.bashrc` は変わらなかった。`~/.grok` は、最初に `grok` を動かしたときにできた（`config.toml` に `[cli]` の行は無かった）
- `grok update --check`: `Grok Build - v1.0.50 (latest: 1.0.50) [stable]`。`grok update`: `Already up to date (1.0.50).`
- `grok update --force-reinstall`: `✓ grok v1.0.50 installed successfully!` と出て、Homebrew の外の `~/.grok/bin`・`~/.grok/downloads` に別の Grok が入った（`config.toml` に `installer = "internal"`）
- そのとき、Homebrew の Caskroom の配布物はハッシュも時刻も変わらず、PATH で先の Homebrew の `grok` が動き続けた
- `brew outdated --cask` と `brew upgrade --cask grok-build` は動いた（最新なので上げるものは無かった）
- `brew uninstall --cask grok-build` はリンクと補完を消し、`~/.grok` は残った。`--zap` も、`~/.grok` は空のときだけ消す
- Homebrew の formula の `grok` は `DRY and RAD for regular expressions and then some`（Grok Build ではない）

#### Grok Build: ほかの配布

- WinGet の `xAI.GrokBuild` は 1.0.50（portable）。npm の `@xai-official/grok` は 1.0.50（`latest`）
- scoop の main と extras には無い

### Grok Build: 付録: Raspberry Pi 5 / aarch64 実機での検証（2026-10-10）

| 項目 | 値 |
|---|---|
| 環境 | Raspberry Pi 5、AlmaLinux 10.2 (Lavender Lion)、aarch64、kernel `6.12.96-20260724.v8.1.el10` |
| 対象 | setup-notes #117、取得時の commit `814b590` |
| 実行ユーザー | 新規の一般ユーザー `<TEST_USER>` を作り、そのログインシェルで実行。既存ユーザー `<USER>` の CLI・設定・認証と OS の RPM は変更対象にしていない |
| 版 | 公式インストーラーの最新 1.0.50（`c58f321264ba`）と、指定して導入した 1.0.49（`8e66fdf1fd8e`） |
| インストーラー | `https://x.ai/cli/install.sh` を取得して `bash` で実行。SHA-256 `7fd6fdc75d9418b2e58356726fcbf1ae849416f773925da07d0ccc7a60d3e791`（2026-10-10 取得） |
| 検証補助 | 実ユーザーの HOME を使い、HOME・CODEX_HOME の変更や既存認証のコピーはしていない。実際の対話 PTY を用い、ログインコマンド・認証承認の入力は行っていない |

#### Grok Build: 導入・更新・再導入

| 確認 | 実測結果 |
|---|---|
| 最新版の導入 | `bash install.sh` が `Installing Grok 1.0.50 (linux-aarch64)` と成功を表示。終了コード 0 |
| 新しいシェル | `bash -lic` で自分のホームの Grok が見つかり、1.0.50 を表示。元の `.bashrc` に加えた無関係の確認用行も残った |
| 最新確認・手動更新 | `grok update --check` は `(latest: 1.0.50)`、`grok update` は `Already up to date (1.0.50).`。いずれも終了コード 0 |
| 強制再導入 | `grok update --force-reinstall` は終了コード 0。`downloads/grok-1.0.50-linux-aarch64` を置き、`bin/grok` と `bin/agent` を付け替えた |
| 古い版の導入 | `bash install.sh 1.0.49` は終了コード 0。版を 1.0.49 と確認 |
| 自動更新の停止 | この試験ユーザーの更新キャッシュを外し、`[cli] auto_update = false` で `grok` を PTY で 60 秒起動。起動後も 1.0.49、`version.json` は生成されなかった |
| 自動更新の有効化 | `auto_update = false` の行を外し、PTY で 90 秒起動。起動後は 1.0.50、`version.json` に `version = 1.0.50` と実際の確認時刻が入り、両リンクが版付き配布物へ切り替わった。キャッシュの最新版・確認時刻を手で書いていない |
| 更新中の `.bashrc` | 手動更新・強制再導入の前後と、自動更新の前後の `cmp` は終了コード 0。インストーラーの再実行による空行増加とは分けて確認した |
| 公式インストーラーの再実行 | 最新の 1.0.50 を再導入し、終了コード 0 と版を確認 |

初回の実行シェルでは `~/.local/bin` が PATH にあったため、インストーラーは `~/.local/bin/grok`・`agent` を作った。あらかじめ置いた使い捨ての `agent` リンクは上書きされた。既存リンクを保持する動作とは扱わず、検証後は控えに従って元の確認用リンクを復元した。

#### Grok Build: CLI の撤去と認証の範囲

- 起動した CLI を終了し、今回の `.grok` 配下を指す `~/.local/bin` のリンク、`~/.grok/bin/{grok,agent}`、配布物・補完を撤去した。新しいログインシェルの `command -v grok` は終了コード 1。無関係の `.bashrc` の行を保持した。
- 初回の撤去補助では `rg` が試験ユーザーの PATH に無く、installer ブロックを消す条件が実行されなかった。`grep` に置き換え、ブロックが無いことの検査を足して再試験し、終了コード 0 でブロックの撤去・新しいシェルでの CLI 不在・無関係の行とリンクの保持を確認した。CLI が見つからない結果だけでブロック撤去まで成功と判断していない。
- CLI 撤去後は試験結果を調べるため `.grok` の設定・文書・ログ・キャッシュを一旦残した。その後、手順書の手順 4 に相当する `~/.grok` 全体の削除を専用ユーザーで実行し、不在・新しいシェルでの CLI 不在・無関係の確認用行とリンクの保持をすべて終了コード 0 で確認した。
- 最後に、今回作成した専用ユーザー・同名グループ・ホームを削除した。OS の `rpm -qa` をソートした一覧の SHA-256 は実施前後で一致。既存ユーザーの CLI・設定・認証を更新や削除の対象にしていない。
- 専用ユーザーは未認証で実行した。既存ユーザーの初回ログイン・ログアウトやブラウザでの承認を検証済みとはしていない。

#### Grok Build: sandbox の追加原因調査と対処の準備

- 同じ実機の Grok 1.0.50 で、`runtime-socket deny path /run/podman/podman.sock` の `Permission denied (os error 13)` を追加調査した。`/run/podman` は root 所有の空ディレクトリで、権限は `0700`。API ソケットは存在せず、rootful の `podman.socket` と `podman.service` は inactive だった。親ディレクトリを検索できないため、ソケットの不存在を通常ユーザーから確認できなかった。
- 原因を切り分ける試験だけで親ディレクトリを一時的に `0711` にすると、errno 13 は解消した。続いて Grok の `read-only` は、必要なカーネルの保護を適用できないため起動を拒否した。試験後は親ディレクトリを元の `0700` に戻した。ソケット本体の権限は変更していない。
- 現行カーネル `6.12.96-20260724.v8.1.el10` の設定は `CONFIG_SECURITY_LANDLOCK` が未設定。Landlock ABI を問い合わせる syscall は `ENOSYS` で失敗した。bubblewrap 0.10.0 があることと、Landlock による制限が有効であることは分けて判定した。
- 現行と同じ 6.12.96 の公式 SRPM を取得し、digest と署名の検証が成功した。`CONFIG_SECURITY_LANDLOCK=y` だけを変更した Image のビルドが完了し、カーネルの release は `6.12.96-20260724.v8.1.el10` のまま。ビルドは 1245 秒、`Image.gz` は 9,597,976 bytes、SHA-256 は `1a4a44d11d4be66f3c3db82d0bc6e3b8fabe99e92adafde8c4d40c13de683b49`。
- ビルドとは別の検証器で、次の 7 項目がすべて成功した。

| 静的検査 | 結果 |
|---|---|
| 完了したビルド記録と Image の一致 | release と Image の SHA-256 が一致 |
| 設定の差分 | `CONFIG_SECURITY_LANDLOCK` の `n` → `y` だけ |
| カーネルの release | `kernel.release` と `UTS_RELEASE` が現行と同じ |
| 組み込みカーネルの公開シンボル | 11,289 件の集合・CRC・export 種別・namespace がすべて一致。追加・削除・変更は無い |
| vmlinux の形式 | AArch64 の ELF64、little endian |
| Landlock の syscall | `create_ruleset`・`add_rule`・`restrict_self` の 3 つが `T`（strong text）のシンボルとして存在 |
| Image.gz の形式 | gzip と AArch64 Image の header が有効で、展開後はビルドした Image と一致 |

- 公開シンボルの一致は静的な ABI 検査で、既存 modules のロードや実際の動作を保証する結果ではない。`CONFIG_IKCONFIG=m` の既存 `configs.ko` を再利用すると、`/proc/config.gz` は元の設定を表示する。`uname -r` も変わらないため、この Image を将来使う場合は、起動後に Landlock ABI の問い合わせと LSM の初期化を確かめる必要がある。別版の公式カーネルへ更新するときは、対処用 Image もその版から再構築して検証する必要がある。
- ACL は専用の模擬ディレクトリとソケットで検証した。指定したユーザー UID に、親ディレクトリへの検索権限 `--x` だけを access ACL で与えた。パスの解決は成功し、ディレクトリの一覧・書き込みと root 所有のソケットへの接続は拒否された。ソケットの `0660` は変わらず、default ACL も無い。これら 6 項目がすべて成功した。
- 実ホストの `/run/podman` への ACL の永続適用は、自動承認レビューが、root が管理するコンテナ用パスへの変更には明示的な承認が必要として拒否した。実ホストへは適用していない。模擬試験の成功を、実機の Grok の起動成功とは扱わない。
- 通常起動の設定・`kernel8.img`・`initramfs8` を保持し、別名の Image と 1 回限りの `tryboot` を使う適用・復旧スクリプトを準備した。ユーザーの指示により、今回の対処は実ホストに適用せず、調査と準備までで終了した。ACL の永続適用・Image の適用・再起動・レビューの再検証は実施していない。Landlock が有効なカーネルでの起動、sandbox の再試行、プロジェクトへの書き込み拒否と Grok のレビュー成功は未確認で、Grok の sandbox レビューの失敗は未解消のまま。

#### Grok Build: sandbox の再起動なしの追加検証

- setup-notes #119 のマージ後（`cf8774d`）、同じ実機・同じ稼働カーネル・Grok 1.0.50 のまま、ユーザーの指示で再起動を伴わない範囲だけを確かめた（2026-10-10 05:35〜06:10 UTC）。Landlock を有効にした Image の適用と再起動、ACL の永続化は今回も行っていない。
- どの実行も `--no-auto-update` を付けた。sandbox の準備で終了コード 1 になり、モデルへの依頼まで進んでいない。
- SELinux は Enforcing で、起動以降の監査ログに Grok・bubblewrap に関する拒否は無かった（[共同作業の検証記録](coding-agents.md#selinux-の記録の訂正)）。
- 起動時のシステムコールを `strace -f` で追い、Landlock の 3 つのシステムコール・パスを調べるシステムコール・`execve` だけを記録した。

| プロファイル | `/run/podman` | `/run/docker.sock` | `/run/podman/podman.sock` | `landlock_create_ruleset` | 標準エラー |
|---|---|---|---|---|---|
| `read-only` | 元のまま（root 所有の `0700`） | `ENOENT` | `EACCES` | 呼ばれない | `could not resolve runtime-socket deny path /run/podman/podman.sock: Permission denied (os error 13)` |
| `workspace` | 元のまま | 調べない | 調べない | `ENOSYS`（6 回） | `could not apply the 'workspace' sandbox profile; see the warning above for the cause. Refusing to start with its protections missing.` |
| `read-only` | 検索の ACL を適用中 | `ENOENT` | `ENOENT` | `ENOSYS`（6 回） | `could not apply the 'read-only' sandbox profile; …`（上と同じ形） |
| `workspace` | 検索の ACL を適用中 | 調べない | 調べない | `ENOSYS`（6 回） | 適用前と同じ |

- `read-only` は、Docker と Podman の rootful のソケットを起動時に調べる。`/run/podman` を検索できないと、Landlock の適用より前に止まる。
- `workspace` は、この 2 つのソケットを調べない。先の付録で「`read-only` と同じ原因か断定しない」とした `workspace` の失敗は、errno 13 ではなく、Landlock が無いこと（`ENOSYS`）による。
- 検索の ACL を適用した後は、どちらのプロファイルも `/usr/bin/bwrap` の起動まで進み、その後の `landlock_create_ruleset` の `ENOSYS` で止まった。`landlock_add_rule` と `landlock_restrict_self` は 4 回の実行のどれでも呼ばれていない。
- エラーの文は `see the warning above` と案内するが、`workspace` の実行では、標準エラー・`--debug`・`RUST_LOG=warn`・`~/.grok/logs/unified.jsonl` のどこにもその警告は無かった。原因は上の追跡で確かめた。
- Landlock のエラーで起動を拒否した実行は、`~/.grok/` に空で mode `000` の `sandbox-blocked.<PID>` を 1 個ずつ残した（9 回の実行で 9 個）。errno 13 で止まった 3 回の実行は残さなかった。

#### Grok Build: 検索の ACL の実ホストへの一時適用

- `acl` のパッケージはこのホストに入っていない。先の調査で取得していた公式の `acl-2.4.0-1.el10_2.aarch64.rpm` は `rpm -K` が `digests signatures OK`、展開済みの `getfacl`・`setfacl` の SHA-256 は RPM の記録と一致したので、このコマンドを使った。OS の RPM は増やしていない。
- 適用の前に、`/run/podman` が root 所有・`0700`・空で、拡張の ACL が無く、`podman.socket`・`podman.service` が inactive であることを確かめた。
- `setfacl -m u:<UID>:--x,m::--x /run/podman` を適用した。`getfacl` は `user:<UID>:--x`・`group::---`・`mask::--x`・`other::---` で、default ACL は無い。`stat` の mode は `0710`（`drwx--x---+`）と表示された（グループの欄は mask を表す）。
- 実ディレクトリに対して、`<USER>` で次を確かめた。ソケットは作っていない。

| 確認 | 結果 |
|---|---|
| `/run/podman/podman.sock` のパスの解決 | `ENOENT`（`EACCES` ではなくなった） |
| ディレクトリの一覧 | `EACCES` |
| ファイルの作成 | `EACCES` |
| ディレクトリの作成 | `EACCES` |
| ソケットへの接続 | `ENOENT`（ソケットが無い） |

- root から見て、ディレクトリは空のまま。ソケットがあるときの接続の拒否と、ソケットの mode が変わらないことは、実ホストでは確かめていない（先の模擬試験の範囲）。
- 適用していたのは約 2 分（06:02:09〜06:03:57 UTC）。`setfacl -b` で外した後、mode・ACL・一覧（mtime を含む）・2 つの unit の状態は適用前の控えと一致し、`read-only` の errno 13 も元どおり再現した。tmpfiles などでの永続化はしていない。

#### Grok Build: 再起動なしの追加検証の片付けと残る未確認

- 片付け: `--trust` が `~/.grok/trusted_folders.toml` に足した試験用フォルダー 1 件と、今回の実行が残した `sandbox-blocked.<PID>` 9 個を消した（先の検証の 1 個は残した）。`config.toml` と `trusted_folders.toml` のハッシュ、版（1.0.50）、ログインの状態は実施前と同じ。
- 未確認のまま: Landlock が有効なカーネルでの起動、sandbox が起動した状態でのレビュー・プロジェクトへの書き込みの拒否・`workspace` でのコミット、検索の ACL の永続化。Grok の sandbox レビューの失敗は未解消のまま。
