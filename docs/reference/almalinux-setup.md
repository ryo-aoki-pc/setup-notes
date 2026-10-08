# AlmaLinux 10 の初期設定の手順（インストール直後の更新・sudo・SSH・導入元・日本語入力・GNOME・シェルのツール）の参考資料

[手順書](../almalinux-setup.md)

## 補足

### 選択した方針

- **1 本の手順書にまとめた**: インストールした直後に行う作業を、上から順に貼れば終わる形にした（利用者の依頼。Windows 11 の [windows-setup.md](../windows-setup.md) と同じ形）
  - もとは、更新・sudo・SSH などの OS の作業はどの手順書にも無く、導入元（EPEL・RPM Fusion・Flathub・Homebrew）・日本語入力・電源・シェルのツールは、13 本の手順書に分かれていた
  - 13 本（epel・rpmfusion・bash-settings・homebrew・flatpak・japanese-input・gnome-power・starship・zoxide・fzf・eza・bat・tmux）は、この文書に入れて消した。もとの参考資料は、この文書の[統合前の参考資料](#統合前の参考資料-epelもとは-epelmd)以下に、中身を変えずに移した
  - ほかの手順書が前提にしていたもの（EPEL・RPM Fusion・Homebrew・Flathub・画面オフの設定）は、使う側の手順書がこの文書の手順番号か節を名指しする
  - AlmaLinux 10 と Windows 11 の両方を対象にする手順書（git・firefox・hackgen・wezterm-nightly・claude-code・codex）は、OS ごとの節があるので残し、リードから順に案内する
- **sudo をパスワード無しにする（手順 3）**: このリポジトリの手順書は、`sudo` の後ろに続く行がパスワードの入力に食われないように、NOPASSWD を前提に書いてある（README の記法）。それを設定する手順が無かったので、最初に置いた
  - `/etc/sudoers.d/nopasswd` に、このユーザーだけの 2 行を置く。`/etc/sudoers` の `%wheel ALL=(ALL) ALL` は残す（ロールバックで、ファイルを消せば元に戻る）
  - `Defaults:<USER> verifypw=any` も置く。`sudo -v`（`-v` は資格を更新するだけ）は、`verifypw` の既定の `all` では、そのユーザーに当たるすべての行が NOPASSWD のときだけパスワードを聞かない。`%wheel` の行が残るので、`verifypw=any` が無いと Homebrew のインストーラの `sudo -v` がパスワードを聞いた（sudoers(5) の `verifypw`）
  - 書く前に `visudo -cf -` で確かめ、`install -m 0440` で置き、最後に `visudo -c` で全体を確かめる（書式の誤りがあると `sudo` そのものが使えなくなるため）
- **ファームウェアは fwupd（手順 5・6）**: Workstation に入っている `fwupdmgr` で、LVFS から入れる。AlmaLinux 10 の既定では LVFS のリモートが無効で、`refresh` が有効にするかを聞く
  - `--assume-yes` を付けても、この問いは出た。問いに答える手順として、`refresh` と `update` を分けた
- **journal を永続にする（手順 13）**: `/etc/systemd/journald.conf.d/` のドロップインで `Storage=persistent` にする（`/etc/systemd/journald.conf` は書き換えない）
  - journald が作った `/var/log/journal` には、`systemd-journal` のグループと ACL が付かなかった。`systemd-tmpfiles --create --prefix /var/log/journal` で、パッケージの tmpfiles の定義どおりに付け直す
  - tmpfiles の定義（`/usr/lib/tmpfiles.d/systemd.conf` の `z`・`a+`）は、すでにあるものだけを直す。`/var/log/journal` は `journalctl --flush` のときに作られるので、tmpfiles はその後に行う（前に行うと、何も直らなかった）
  - 元に戻すときは、`journalctl --relinquish-var` で journald に `/var/log/journal` を手放させてから消す。手放させずに消すと、動いている journald がすぐに作り直し、`Storage=auto` のまま書き続けた
- **kdump を止める（手順 14・15）**: カーネルが落ちたときの記録が要らない PC では、予約されるメモリー（`crashkernel=`）を空ける
  - `/etc/kdump.conf` の `auto_reset_crashkernel` を `no` にする。`yes` のままだと、カーネルを入れたときに kernel-install の `92-crashkernel.install` が `crashkernel=` を付け直す
  - `crashkernel=` は `grubby --update-kernel=ALL --remove-args=crashkernel` で、入っているすべてのカーネルの起動の項目から外す
- **PackageKit-command-not-found を外す（手順 16）**: 無いコマンドを打つたびにリポジトリを探して待たされるため。パッケージは `dnf provides` で探す
- **ホームのフォルダーの名前を英語にする（手順 29）**: 端末で打ちやすく、Homebrew・WezTerm などの既定の場所と合わせるため
  - `xdg-user-dirs-update --force` は空のフォルダーを作り直すだけで、中身を移さない。中身を残すために、フォルダーを `mv` してから `xdg-user-dirs-update --set` で場所を書き換える
  - Files のサイドバーのブックマーク（`~/.config/gtk-3.0/bookmarks`）も、日本語の名前の URI のままになるので書き換える
  - `~/.config/user-dirs.locale` を今のロケールに合わせる。xdg-user-dirs-gtk は、このファイルのロケールが今のロケールと違うときに、ログインで「標準フォルダーの名前を現在の言語に合わせて更新しますか?」の窓を出す（xdg-user-dirs-gtk のソース）
- **GNOME の設定は `gsettings` の読み戻しで確かめる**: `gsettings` は書けなかったときも終了コード 0 で終わる。`/usr/bin/gsettings` で呼ぶ（Homebrew の glib の `gsettings` は dconf に書かない。統合前の[画面オフ・ロック・サスペンドの記録](../verification/almalinux-setup.md#画面オフロックサスペンド-実施手順--手順-2-補足-変える前の値0-にしても暗くなる理由設定アプリの項目)）
  - 一覧の値（`xkb-options`・`experimental-features`・`custom-keybindings`）は、まるごと置き換えず、無ければ足す。ほかの設定で入っている値を消さないため
- **Caps Lock を Ctrl に（手順 31）**: XKB の `ctrl:nocaps`（xkeyboard-config の説明は「Caps Lock as Ctrl」）を `xkb-options` に足す。Caps Lock の働きは無くなる。自分のセッションの設定なので、ログイン画面と仮想コンソールは変わらない
- **拡大率（手順 37）**: GNOME の設定に 125%・150% などの拡大率を出すのは、mutter の実験的な機能 `scale-monitor-framebuffer`。`xwayland-native-scaling` は、X11 のアプリをぼやけさせずに拡大する（mutter 49 の gschema の説明）。AlmaLinux 10.2 の mutter 49.4 の既定は `[]`
- **トレイアイコン（手順 38・39）**: EPEL の `gnome-shell-extension-appindicator`（AppIndicator と KStatusNotifierItem を扱う）。AppStream の `gnome-shell-extension-status-icons` は、旧来の XEmbed のトレイアイコンだけを扱い、今のアプリが使う AppIndicator / KStatusNotifierItem を出さない
- **Ctrl+Alt+T（手順 40）**: GNOME 49 の media-keys には端末を開くキーが無いので、カスタムのショートカットにする。コマンドは、新しい窓を開く `ptyxis --new-window`
- **シェルのツールは 1 回の `brew install` にまとめた（手順 49）**: 依存の確認（`[y/n]`）が 1 回で済む。初期化は共通の bash 設定が持つので、入れた後は端末を開き直すだけ
- **SSH を公開鍵だけにする（任意節）**: ドロップインのファイル名を `40-pubkey-only.conf` にする。sshd は最初に読んだ値を使い、Workstation の `50-redhat.conf` より前に読ませるため
- **dnf-automatic（任意節）**: `dnf-automatic-install.timer` で、毎日更新を入れる（再起動はしない）。GNOME Software の自動の更新（`download-updates`）は切る。2 つの仕組みが同じ更新を落とし合わないようにするため
- **Wake on LAN（任意節）**: NetworkManager の接続の `802-3-ethernet.wake-on-lan` に `magic` を入れる。`ethtool -s` で変えた値は再起動で消えるが、接続の設定は接続を上げるたびに入る

### 参照

- [sudoers(5)](https://www.sudo.ws/docs/man/sudoers.man/) — `verifypw`（`sudo -v` のときの認証の条件）と `NOPASSWD`、`/etc/sudoers.d` の読み込み
- [AlmaLinux の Security のページ](https://almalinux.org/security/) — AlmaLinux 10 の署名鍵の fingerprint
- `man fwupdmgr`（`refresh`・`update`）と [LVFS](https://fwupd.org/) — ファームウェアを配るサービス
- `man journald.conf`（`Storage=`）と `man systemd-tmpfiles`
- `man kdump.conf`（`auto_reset_crashkernel`）と `/usr/lib/kernel/install.d/92-crashkernel.install` — カーネルを入れたときに `crashkernel=` を付け直す仕組み
- [xdg-user-dirs](https://www.freedesktop.org/wiki/Software/xdg-user-dirs/) と [xdg-user-dirs-gtk](https://gitlab.gnome.org/GNOME/xdg-user-dirs-gtk) — `user-dirs.dirs`・`user-dirs.locale` と、名前を更新するかを聞く窓
- mutter 49.4 の `/usr/share/glib-2.0/schemas/org.gnome.mutter.gschema.xml` — `experimental-features` の `scale-monitor-framebuffer` と `xwayland-native-scaling` の説明
- [gnome-shell-extension-appindicator](https://github.com/ubuntu/gnome-shell-extension-appindicator) — AppIndicator / KStatusNotifierItem のトレイアイコン（EPEL のパッケージの上流）
- [dnf-automatic](https://dnf.readthedocs.io/en/latest/automatic.html) — `dnf-automatic-install.timer` と `/etc/dnf/automatic.conf`
- `man sshd_config`（最初に読んだ値が使われる）と `man nm-settings-nmcli`（`802-3-ethernet.wake-on-lan`）
- [README の共通の bash 設定を先に入れる](../../README.md#共通の-bash-設定を先に入れる) と [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash) — 手順 42〜45 の共通の bash 設定
- [Windows 11 の初期設定](../windows-setup.md) — Windows 11 側の同じ形の手順書

---

## 統合前の参考資料: EPEL（もとは epel.md）

もとの `epel.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜3 | 実施手順 17 |
| 更新 1 | 更新のリード（OS は実施手順 4） |
| ロールバック 1・2 | ロールバック 34・35 |

### EPEL: 補足

#### EPEL: 実施手順 / 手順 3: 補足: 出力例と、EPEL の鍵

`epel-release` は、repo ファイル（`/etc/yum.repos.d/epel.repo` と、無効の `epel-testing.repo`）と、鍵のファイル `/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10` を置く。

取り込んだ鍵は、`rpm -q gpg-pubkey` に `gpg-pubkey-e37ed158-65785fa9` として出る（[ロールバック](../almalinux-setup.md#ロールバック)の手順 2 で使う）。

#### EPEL: 参照

- [EPEL — Fedora Docs](https://docs.fedoraproject.org/en-US/epel/) — EPEL とは何か。入れ方は同じ文書の [Getting Started](https://docs.fedoraproject.org/en-US/epel/getting-started/)（CRB と `epel-release`）
- `man dnf`（`remove` の `--noautoremove`）
- [導入元一覧の導入経路と EL10 での注意](../tool-catalog.md#導入経路と-el10-での注意) — EPEL とほかの導入元の比較

---

## 統合前の参考資料: RPM Fusion（もとは rpmfusion.md）

もとの `rpmfusion.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜4 | 実施手順 18〜21 |
| ロールバック 1・2 | ロールバック 32・33 |

### RPM Fusion: 補足

#### RPM Fusion: 選択した方針

- **署名を確かめて入れる**: Configuration の `--nogpgcheck` の例は使わず、keys ページの方法（鍵を先に取り込み、`localpkg_gpgcheck=1`）にした（手順 3 の補足）
- **free だけ**: 本書を使う [Firefox の AAC・H.264](../firefox.md#実施手順) は、free の `ffmpeg-libs` で足りる。nonfree は有効にしない
- **EPEL を前提にする**: `rpmfusion-free-release` が `epel-release` を要求し、RPM Fusion の Configuration も EPEL を先に有効にする順で書いている（手順 3 の補足）
- **独立した手順書にした**: リポジトリの有効化と、Firefox のために FFmpeg を入れることを分けた。EPEL の [epel.md](../almalinux-setup.md) と同じ扱い

#### RPM Fusion: 参照

- [Configuration — RPM Fusion](https://rpmfusion.org/Configuration) — free / nonfree の区別と、EL 向けの有効化（EPEL を先に有効にすること、`--nogpgcheck` の例、Alma・Rocky の `crb enable`）
- [Trusting Package Integrity — RPM Fusion](https://rpmfusion.org/keys) — 鍵の fingerprint と、鍵を先に取り込んで `localpkg_gpgcheck=1` で入れる方法
- `man dnf.conf`（`localpkg_gpgcheck`）
- [EPEL](../almalinux-setup.md) — 前提の手順書

---

## 統合前の参考資料: bash の設定（もとは bash-settings.md）

もとの `bash-settings.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 実施手順 44 |
| 実施手順 2 | 実施手順 51（今のシェルへの読み込みはやめた） |
| 実施手順 3 | 実施手順 43・51 |
| 実施手順 4 | 実施手順 51 |
| 実施手順 5 | 実施手順 45 |
| 実施手順 6 | 実施手順 50 |
| 実施手順 7 | 実施手順 51 |
| 実施手順 8 | 実施手順 59 |
| ロールバック 1 | ロールバック 17 |
| ロールバック 2 | ロールバック 22 |
| ロールバック 3 | ロールバック 21 |
| ロールバック 4 | ロールバック 27 |
| ロールバック 5 | ロールバック 23 |

### bash の設定: 補足

#### bash の設定: 選択した方針

- **bash-completion はシステムの RPM にした**: BaseOS の 2.11 で足りる。Homebrew にも `bash-completion@2`（2.16 系）があるが、RPM の各パッケージが置く `/usr/share/bash-completion/completions/` を読むのはシステムのものの方が素直で、`sudo` のシェルでも同じものが効く
- **Homebrew の補完は bash リポジトリから全部読む**: 遅延読み込みの対象のディレクトリに無いため（手順 4 の補足）。`~/.local/share/bash-completion/completions/` にシンボリックリンクを置けば遅延読み込みにできるが、入れるたびに足す手間があるので採らない
- **`~/.inputrc` を使い、`~/.bashrc` の `bind` にはしない**（手順 5 の補足）
- **採らなかった設定**
  - `HISTTIMEFORMAT`（`history` に時刻を出す）: 履歴ファイルに `#<epoch>` の行が増える。本書は履歴の見え方を変えない範囲にとどめる。欲しければ `HISTTIMEFORMAT='%F %T '` を手順 3 の行に足せばよい
  - `HISTCONTROL=…:erasedups`（同じ行を全部消して 1 つにする）: 覚えている一覧の中だけを直し、ファイルの古い重複は残る。効き目が分かりにくいので入れない
  - `PROMPT_COMMAND` に `history -a`（コマンドごとにファイルへ書き、別の端末ですぐ使う）: AlmaLinux 10 の `PROMPT_COMMAND` は配列で、starship・WezTerm のシェル統合・zoxide が順番に意味を持って触っている（[starship.md 手順 3](../almalinux-setup.md#実施手順) の補足）。そこへ足す形は本書では扱わない
  - `set bell-style none`（ベルを消す）、`menu-complete`（Tab で候補を順に入れる）: 好みの幅が大きいので入れない
  - `shopt -s histappend`: `/etc/bashrc` が対話のシェルで入れている（手順 3 の補足）
- **atuin（履歴を SQLite に持ち、同期もする）は使わない**: 履歴の検索は [fzf](../almalinux-setup.md) の Ctrl+R で足りる。[導入元一覧](../tool-catalog.md#cli-定番の置き換え)の行のまま

#### bash の設定: 参照

- [Bash Reference Manual — Bash Variables](https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html)（`HISTSIZE`・`HISTFILESIZE`・`HISTCONTROL`・`HISTTIMEFORMAT`）
- [Bash Reference Manual — The Shopt Builtin](https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html)（`autocd`・`cdspell`・`dirspell`・`globstar`・`histappend`）
- [Bash Reference Manual — Readline Init File](https://www.gnu.org/software/bash/manual/html_node/Readline-Init-File.html)（`$include`、`completion-ignore-case`、`show-all-if-ambiguous`、`colored-stats`、`colored-completion-prefix`、`history-search-backward`）
- [bash-completion](https://github.com/scop/bash-completion)（`_completion_loader`、`BASH_COMPLETION_USER_DIR`、`XDG_DATA_DIRS`）
- [Homebrew — Shell Completion](https://docs.brew.sh/Shell-Completion)（`etc/bash_completion.d` を読む形）
- [fzf](../almalinux-setup.md) — Ctrl+R の履歴の検索と `**<Tab>`。Homebrew の補完の行との並び
- [Homebrew](../almalinux-setup.md) — `brew shellenv` の行（手順 3）

---

## 統合前の参考資料: Homebrew（もとは homebrew.md）

もとの `homebrew.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 実施手順 46 |
| 実施手順 2 | 実施手順 47 |
| 実施手順 3・4 | 実施手順 48 |
| 使い方の基本 | Homebrew の使い方の基本 |
| root のシェルでも使う（任意）の 1・2 | Homebrew を root のシェルでも使う（任意）の 1・2 |
| sudo でも使う（任意）の 1・2 | Homebrew を sudo でも使う（任意）の 1・2 |
| 更新 1・2 | 更新 2・3 |
| ロールバック 1〜3 | ロールバック 24〜26 |

### Homebrew: 補足

#### Homebrew: 選択した方針

**Homebrew に揃える判断の実質は「更新の一元化」**。`brew upgrade` 1 本で、17 本の手順書（統合前の数。今はこの文書の手順 49 と、11 本の手順書）で Homebrew から入れたものがまとめて上がる。

#### Homebrew: root のシェルで使うときの補足

| 入口 | 読むファイル | Homebrew のコマンド |
|---|---|---|
| `su -`、ssh での root のログイン | `/etc/profile` → `/root/.bash_profile` → `/root/.bashrc` | 使える（PATH の末尾） |
| `sudo -i` | 同上。PATH の始まりは sudo の `secure_path` | 使える（PATH の末尾） |
| `sudo -s`、`su`（`-` 無し） | `/root/.bashrc`（`sudo -s` でも `HOME` は `/root`） | 使える（PATH の末尾） |
| `sudo <コマンド>` | 読まない。PATH は `secure_path` の `/sbin:/bin:/usr/sbin:/usr/bin` | 使えない（`sudo: jq: command not found`）。[sudo でも使う](../almalinux-setup.md#homebrew-を-sudo-でも使う任意)の節で使える |

- **`su`（`-` 無し）も、Homebrew のユーザーの PATH を引き継がない**: PATH は root のものに置き換わり、その末尾に足される
- **cron や systemd の unit では見えない**: `~/.bashrc` を読まないため（[注意点](../almalinux-setup.md#注意点)の「`~/.bashrc` を読まない文脈」と同じ）。フルパスで書く
- **RPM と同じ名前のコマンドは、root では RPM が先**: AppStream の `jq` も入れると、`type -a jq` の並びが root と Homebrew のユーザーで逆になる

  ```
  # root のシェル
  jq is /bin/jq
  jq is /usr/bin/jq
  jq is /home/linuxbrew/.linuxbrew/bin/jq
  # Homebrew のユーザーのシェル
  jq is /home/linuxbrew/.linuxbrew/bin/jq
  jq is /usr/bin/jq
  jq is /bin/jq
  ```

#### Homebrew: sudo で使うときの補足

| 入口 | PATH | Homebrew のコマンド |
|---|---|---|
| `sudo <コマンド>`、`sudo -u <ユーザー> <コマンド>`、`sudo bash <スクリプト>` | `secure_path`（`/sbin:/bin:/usr/sbin:/usr/bin` の後ろに 2 つ） | 使える（`sudo jq --version` は `jq-1.8.2`） |
| `sudo -E <コマンド>` | 同上（`-E` でも、自分の PATH は渡らない） | 使える |
| `sudo -s` | `/root/.local/bin:/root/bin` の後ろに `secure_path` | 使える（PATH の末尾） |
| `sudo -i` | `/root/.local/bin:/root/bin:/usr/local/sbin` の後ろに `secure_path` | 使える（PATH の末尾） |
| `sudoedit`（`EDITOR=nvim`） | エディタを `secure_path` で探し、自分のユーザーと自分の環境で動かす | Homebrew の `nvim`。設定は自分の `~/.config/nvim` |
| `sudo EDITOR=nvim visudo` | エディタを `secure_path` で探し、root で動かす | Homebrew の `nvim`。設定は `/root/.config/nvim` |
| `su -`、`sudo su -`、ssh での root のログイン | sudo の `secure_path` を通らない | 使えない（[root のシェルでも使う](../almalinux-setup.md#homebrew-を-root-のシェルでも使う任意)の節で使える） |

#### Homebrew: 参照

---

## 統合前の参考資料: Flatpak（もとは flatpak.md）

もとの `flatpak.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜3 | 実施手順 22 |
| 実施手順 4〜7 | 実施手順 23〜26 |
| 使い方の基本 | Flatpak の使い方の基本 |
| 更新 1 | 更新 4 |
| ロールバック 1〜4 | ロールバック 28〜31 |

### Flatpak: 補足

#### Flatpak: 実施手順 / 手順 4: 補足: 鍵は登録ファイルの中にある

`flathub.flatpakrepo` は鍵を**本文に base64 で埋め込んで**いて、`flatpak remote-add` はこの鍵をリモートの設定に取り込む。以後の取得はすべてこの鍵で署名を検証する。したがって、確かめるべきは「登録ファイルの中の鍵が Flathub のものか」の 1 点になる（[VS Code](../vscode.md) の手順で rpm の鍵を確かめているのと同じ考え方）。

`gpg --show-keys` は鍵を**鍵束に取り込まずに表示するだけ**。ただし `~/.gnupg` が無ければ最初の実行で作られる（`gpg: directory '/home/<USER>/.gnupg' created`）。

#### Flatpak: 参照

---

## 統合前の参考資料: 日本語入力（もとは japanese-input.md）

もとの `japanese-input.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1（変数） | 実施手順 9 |
| 実施手順 2・3 | 実施手順 27 |
| 実施手順 4 | 実施手順 28 |
| 実施手順 5（ログインし直す） | 実施手順 67（再起動） |
| 実施手順 6 | 実施手順 69 |
| 実施手順 7 | 実施手順 72 |
| ロールバック 1・2 | ロールバック 13・14 |

### 日本語入力: 補足

#### 日本語入力: 参照

- [Enabling Chinese, Japanese, or Korean text input — Using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_the_gnome_desktop_environment/customizing-the-desktop-environment) — 8.2 節。日本語は `ibus-anthy`、切り替えは Super+Space
- [ibus/ibus-anthy](https://github.com/ibus/ibus-anthy) — Anthy のエンジン
- [CentOS Stream 10 の ibus-anthy](https://gitlab.com/redhat/centos-stream/rpms/ibus-anthy) — RHEL のビルドの設定（配列 `default`、切り替えのキー）と、ひらがなで始めるパッチ

---

## 統合前の参考資料: 画面オフ・ロック・サスペンド（もとは gnome-power.md）

もとの `gnome-power.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1〜5 | 画面オフ・画面ロック・自動サスペンドを止める（任意）の 1〜5 |
| ロールバック 1〜4 | 同じ節の 6〜9 |

### 画面オフ・ロック・サスペンド: 補足

#### 画面オフ・ロック・サスペンド: 実施手順 / 手順 1: 補足: 変数について

- 画面を消したいなら、`IDLE_DELAY` に秒数を入れる（`300` で 5 分）。消えたときにロックもするなら `LOCK_ENABLED=true`
- 放置したときにサスペンドするかどうかは変数にしていない。手順 2・3 で `nothing`（何もしない）を直接書く
  - 手順 4 でサスペンドとハイバネートを OS ごと止めるので、ほかに選べる値が無いため
- `POWER_BUTTON` も同じ理由で、`suspend` / `hibernate` は選ばない
  - `interactive` は、設定アプリの「電源ボタンの挙動」の「電源オフ」にあたる
  - 押すと何をするかを聞く画面が出て、何も選ばなければ 60 秒で電源が切れる（RHEL 10 の文書の 13.1.2 節）

#### 画面オフ・ロック・サスペンド: 参照

- [Changing system power settings — Administering RHEL by using the GNOME desktop environment (RHEL 10)](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/administering_rhel_by_using_the_gnome_desktop_environment/changing-system-power-settings) — 電源ボタン（dconf と logind）と蓋（logind）の設定
- [gnome-settings-daemon 47.2 の電源のスキーマ](https://gitlab.gnome.org/GNOME/gnome-settings-daemon/-/blob/47.2/data/org.gnome.settings-daemon.plugins.power.gschema.xml.in) — `sleep-inactive-*`・`idle-dim`・`power-button-action` の既定値と説明
- [GDM 47.0 のログイン画面の既定の設定](https://gitlab.gnome.org/GNOME/gdm/-/blob/47.0/data/dconf/defaults/00-upstream-settings) — 電源のキーが無いこと
- `man dconf`（`dconf update` とプロファイル）/ `man 5 logind.conf`（`HandleLidSwitch`）/ `man systemctl`（`mask`）

---

## 統合前の参考資料: starship（もとは starship.md）

もとの `starship.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1（変数） | starship のプリセットを当てる（任意）の 2 |
| 実施手順 2 | 実施手順 49 |
| 実施手順 3・5 | 実施手順 52 |
| 実施手順 4 | 実施手順 50 |
| プリセットを当てる（任意）の 1・2 | starship のプリセットを当てる（任意）の 1・2 |
| 設定ファイルの 1 | starship の設定ファイルの 1 |
| ユーザー名とホスト名を常に表示するの 1 | starship でユーザー名とホスト名を常に表示する（任意）の 1 |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバック 18 |
| ロールバック 2・3 | ロールバック 20 |

### starship: 補足

#### starship: 実施手順 / 手順 1: 補足: 変数について

- `${STARSHIP_PRESET}` は[プリセットを当てる（任意）](../almalinux-setup.md#starship-のプリセットを当てる任意)でしか使わない
- 既定を `plain-text-symbols` にしてあるのは、Nerd Font が無い環境でも文字化けしないため

#### starship: 実施手順 / 手順 2: 補足: 降ってくるボトル

[検証記録](../verification/almalinux-setup.md#starship-参考資料から分離した記録)

#### starship: 設定ファイル / 手順 1: 補足: 調べるときに使うサブコマンド

| コマンド | 用途 |
|---|---|
| `starship explain` | 今のプロンプトの各部分が何を表しているか |
| `starship timings` | モジュールごとの所要時間。プロンプトが遅いときの犯人探し |
| `starship module <名前>` | 1 モジュールだけ描画して確かめる |
| `starship print-config` | 実効設定を表示 |

#### starship: 選択した方針

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `arm64_linux` ボトルを使える | **採用** |
| 公式 install.sh（`sh -c "$(curl -sS https://starship.rs/install.sh)"`） | `/usr/local/bin` にバイナリを 1 つ置く。`sudo` が要り、更新は自分で再実行する | 不採用（Homebrew に揃える） |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-musl` のビルドがある。更新は手作業 | 不採用 |
| `cargo install starship` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

#### starship: 参照

- [starship.rs](https://starship.rs/) — 公式サイト。インストールと各シェルでの `init` の書き方
- [starship — Configuration](https://starship.rs/config/) — `starship.toml` の全モジュールと項目
- [starship — Presets](https://starship.rs/presets/) — プリセット一覧とスクリーンショット、Nerd Font が要るかどうか
- `starship --help` / `starship init bash --print-full-init` — サブコマンドと、シェルに入る初期化の中身
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

## 統合前の参考資料: zoxide（もとは zoxide.md）

もとの `zoxide.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 実施手順 43 |
| 実施手順 2 | 実施手順 49 |
| 実施手順 3・4 | 実施手順 57 |
| 実施手順 5 | 実施手順 58 |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバック 18 |
| ロールバック 2 | ロールバック 23 |
| ロールバック 3 | ロールバック 20 |

### zoxide: 補足

#### zoxide: 参照

- [ajeetdsouza/zoxide — README](https://github.com/ajeetdsouza/zoxide) — 各 OS のインストール方法、シェルごとの `zoxide init` の書き方、`--cmd` の説明
- [zoxide — Installation](https://github.com/ajeetdsouza/zoxide#installation) — 公式 install.sh と各ディストリビューションの状況
- `zoxide --help` / `zoxide query --help` — `query --list` / `--score`、`remove`
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作
- [kray74/cli-tools — Copr](https://copr.fedorainfracloud.org/coprs/kray74/cli-tools/) — chroot（`epel-10-x86_64` と `fedora-44-x86_64`）とビルドの履歴
- [kray74/cli-tools — GitHub](https://github.com/kray74/cli-tools) — COPR の spec（`zoxide/zoxide.spec`）

---

## 統合前の参考資料: fzf（もとは fzf.md）

もとの `fzf.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 実施手順 49 |
| 実施手順 2・3 | 実施手順 53 |
| 実施手順 4〜7 | 実施手順 60〜63 |
| 使い方の基本 | fzf の使い方の基本 |
| fd と bat を候補とプレビューに使う（任意）の 1・2 | fzf で fd と bat を候補とプレビューに使う（任意）の 3・4（fd を入れる 1 と、開き直す 2 を足した） |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバック 19 |
| ロールバック 2 | ロールバック 23 |

### fzf: 補足

#### fzf: 実施手順 / 手順 1: 補足: 依存と、入れてあるホストで貼る意味

[この節の検証記録](../verification/almalinux-setup.md#fzf-実施手順--手順-1-補足-依存と入れてあるホストで貼る意味)

- fzf の依存は `ncurses` だけ（`brew deps fzf`）
- yazi.md や zoxide.md で入れた fzf は、`brew install zoxide fzf` のように名前を挙げて入れているので、Homebrew の「頼まれて入れた」印（`installed_on_request`）が付いている。`brew install fzf` を貼り直しても害は無く、印が無かったホストでは付く（印が無いと、zoxide や yazi を `brew uninstall` した際の自動削除や、明示的な `brew autoremove` で fzf も消えうる）

#### fzf: 参照

- [fzf — README](https://github.com/junegunn/fzf#readme)（Key bindings for command-line、Fuzzy completion for bash、Search syntax、Environment variables）
- [fzf — ADVANCED.md](https://github.com/junegunn/fzf/blob/master/ADVANCED.md)（プレビューの例）
- `man fzf`（`--preview`・`--line-range` は bat 側）
- [Homebrew の fzf の formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/f/fzf.rb)（caveat の `fzf --bash`）
- [bash の履歴・補完・キー操作](../almalinux-setup.md) — bash-completion と Homebrew の補完、`~/.inputrc`。fzf の行との並び
- [zoxide](../almalinux-setup.md) — `zi` が fzf を使う。[yazi](../yazi.md) — `z` / `Z` キーが fzf を使う
- [bat](../almalinux-setup.md) — プレビューに使う。[Homebrew](../almalinux-setup.md) — Homebrew 本体の導入と、Homebrew 系に共通の注意

---

## 統合前の参考資料: eza（もとは eza.md）

もとの `eza.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 実施手順 43 |
| 実施手順 2 | 実施手順 49 |
| 実施手順 3 | 実施手順 54 |
| エイリアスを足す（任意）の 1 | 実施手順 54 |
| 表示を調整する | eza の表示を調整する |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバック 18 |
| ロールバック 2 | ロールバック 23 |

### eza: 補足

#### eza: 実施手順 / 手順 2: 補足: 降ってくるボトル

aarch64 で降ってくるボトルは `eza--0.23.5.arm64_linux.bottle.tar.gz`。

#### eza: 選択した方針

[この節の検証記録](../verification/almalinux-setup.md#eza-選択した方針)

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `eza 0.23.5` の `arm64_linux` ボトルがある。upstream の最新と一致 | **採用** |
| EPEL / AppStream / CRB | **`eza` も、前身の `exa` も無い**（`dnf list --available eza exa` → `Error: No matching Packages to list`） | 使えない |
| 公式の deb リポジトリ | eza は Debian/Ubuntu 向けの apt リポジトリを配っているが、**RPM 版の配布は無い** | 使えない |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-gnu` / `musl` のビルドがある。展開して PATH に置くだけだが、更新は手作業 | 不採用（Homebrew に揃える） |
| `cargo install eza` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

#### eza: 参照

- [eza-community/eza — README](https://github.com/eza-community/eza) — 使い方、各ディストリビューションでの入手方法、`ls` との違い
- [eza.rocks](https://eza.rocks) — 公式サイト。スクリーンショットと機能一覧
- `eza --help` / `man eza` — 全オプション（`--help` は 86 行）
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

## 統合前の参考資料: bat（もとは bat.md）

もとの `bat.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1（変数） | bat の設定ファイルの 1 |
| 実施手順 2 | 実施手順 49 |
| 実施手順 3 | 実施手順 55 |
| ページャに使う（任意）の 1 | 実施手順 55 |
| ページャに使う（任意）の 2 | fzf で fd と bat を候補とプレビューに使う（任意）の 4 の箇条書き |
| 設定ファイルの 1 | bat の設定ファイルの 1 |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバック 18 |
| ロールバック 2 | ロールバック 20 |
| ロールバック 3 | ロールバック 23 |

### bat: 補足

#### bat: 実施手順 / 手順 1: 補足: 変数について

- `ansi` は「端末が設定している 16 色をそのまま使う」テーマで、端末の配色を変えたときに追従する。固定の配色にしたいなら `bat --list-themes` から選ぶ

#### bat: 参照

- [sharkdp/bat — README](https://github.com/sharkdp/bat) — 使い方、テーマ、`MANPAGER` や `fzf` との組み合わせ、他ツールとの連携例
- [bat — Customization](https://github.com/sharkdp/bat#customization) — 設定ファイルの書式、テーマとシンタックスの追加手順
- `bat --help` / `bat --list-themes` / `bat --list-languages` — フラグとテーマ・言語の一覧
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

## 統合前の参考資料: tmux（もとは tmux.md）

もとの `tmux.md` の参考資料を、内容を変えずに移したもの。見出しの付け方とリンクの直し方は、[検証記録](../verification/almalinux-setup.md)の統合前の記録と同じ。当時の手順と今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順の対応は次のとおり。

| 当時の手順 | 今の手順 |
|---|---|
| 実施手順 1 | 実施手順 49 |
| 実施手順 2 | 実施手順 56 |
| 実施手順 3〜5 | 実施手順 64〜66 |
| 使い方の基本 | tmux の使い方の基本 |
| 設定ファイル（任意）の 1・2 | tmux の設定ファイル（任意）の 1・2 |
| Claude Code を tmux の中で動かす（任意）の 1〜8 | 同じ節の 1〜8 |
| 更新 1 | 更新 3 |
| ロールバック 1 | ロールバック 16 |
| ロールバック 2 | ロールバック 18 |
| ロールバック 3 | ロールバック 20 |

### tmux: 補足

#### tmux: 設定ファイル（任意） / 手順 1: 補足: 読み込む場所と、足さなかった行

- Homebrew の tmux のシステムの設定ファイルは `/home/linuxbrew/.linuxbrew/etc/tmux.conf`（`man tmux`）。`/etc/tmux.conf` は読まない
- `escape-time`（Esc の後に待つ時間）は、3.7c の既定ですでに 10 ミリ秒なので足さない。Neovim などのために 0〜10 にする例は、古い版の既定の 500 ミリ秒を縮めるためのもの
- Claude Code の公式ドキュメントには、tmux の設定の推奨は無かった（Shift+Enter のための `extended-keys` なども）。本書では足していない

#### tmux: Claude Code を tmux の中で動かす（任意） / 手順 1: 補足: claude auth status を最後に置く理由

- ブラケットペースト無しで貼ると、`claude auth status --text` は、端末に残っていた後ろの行を読んで捨てた（後ろの `tmux -V` や `echo` が実行されなかった）
#### tmux: 参照

- [tmux — Getting Started](https://github.com/tmux/tmux/wiki/Getting-Started) — セッション・ウィンドウ・ペインとキーの説明
- `man tmux`（`new-session` の `-A` と `-d`、`attach-session` の `-d`、`history-limit`、`mouse`、設定ファイルを読む場所）
- [Homebrew の tmux の formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/t/tmux.rb)
- [Continue local sessions from any device with Remote Control](https://code.claude.com/docs/en/remote-control) — `claude remote-control`、`--spawn`、Limitations（SSH の切断後も残すには tmux か screen、10 分の終了）、4 時間以内の再開
- [Interactive mode](https://code.claude.com/docs/en/interactive-mode) — `Ctrl+B`（tmux では 2 回）
- [Claude Code](../claude-code.md) — 導入とログイン、`claude` のコマンドラインの使い方
- [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md) — 同じことを Windows で行う手順書
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入と、Homebrew 系に共通の注意
