# WezTerm Nightly インストール手順（AlmaLinux 10 / 公式 COPR の EL9 ビルドを流用）

- **目的**: AlmaLinux 10 に [WezTerm](https://wezterm.org/) の nightly ビルドを **dnf 管理で**入れ、以後は `dnf upgrade` で追従できるようにする
- **進め方**: 作者が管理する公式 COPR `wezfurlong/wezterm-nightly` には **EL10 向けのビルドが無い**ので、chroot を `rhel-9-<arch>` と明示して有効化し、EL9 向けビルドをそのまま入れる。**読者が書き換えるのは冒頭の変数ブロックだけ**（実際には `uname -m` から自動で入る）
- **状態**: 2026-09-21 にこのホスト（x86_64 / GNOME 49 Wayland）で**本実行済み**。ウィンドウの起動・終了まで確認した。**aarch64 は未検証**（COPR に `rhel-9-aarch64` はあるので同じ手順で通る見込み）。EL9 向けビルドを EL10 で使う非公式な流用なので、更新で壊れたら[補足: 注意点](#注意点)を見る

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

> **注記**: 環境固有の値は**シェル変数**で書いてある。[手順 0](#0-変数を設定する) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${WZ_CHROOT}` | COPR の chroot 名。EL10 向けが無いので EL9 向けを指定する。`uname -m` から自動で入る | `rhel-9-x86_64` / `rhel-9-aarch64` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。パッケージのバージョン（`20260921_051727_5eb03b23`）は実行日によって変わる。

---

## 手順の流れ

**すべて対象ホスト上で実行する。** 手順 0 で変数を設定したシェルで、上から順にコードブロックを貼る。理由・実測出力・落とし穴は[補足](#補足)にまとめてあり、実行するだけなら読まなくてよい。

| 手順 | 内容 |
|---|---|
| [0. 変数を設定する](#0-変数を設定する) | `WZ_CHROOT` を確認する |
| [1. COPR を有効化する](#1-copr-を有効化する) | chroot を明示して `dnf copr enable` |
| [2. インストールする](#2-インストールする) | `dnf install wezterm`（サブパッケージ 3 つが付いてくる） |
| [3. 検証する](#3-検証する) | バージョン、ライブラリ解決、Wayland でウィンドウを開いて閉じる |

以後の更新は[更新](#更新)、戻すときは[ロールバック](#ロールバック)。

### 0. 変数を設定する

**編集するものは無い。** `uname -m` から chroot 名を組み立てるだけ。新しいシェルを開いたら先にこのブロックを貼り直す。

```bash
WZ_CHROOT="rhel-9-$(uname -m)"     # COPR に EL10 向けが無いので EL9 向けを使う。<WZ_CHROOT>
echo "${WZ_CHROOT}"
```

`rhel-9-x86_64` または `rhel-9-aarch64` になっていることを確認する。それ以外（`rhel-9-` で終わる、など）なら止める。

### 1. COPR を有効化する

```bash
sudo dnf copr enable wezfurlong/wezterm-nightly "${WZ_CHROOT}"
cat /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly.repo
```

`baseurl` が `.../wezterm-nightly/rhel-9-$basearch/`、`gpgcheck=1` になっていればよい。

### 2. インストールする

```bash
sudo dnf install wezterm
```

途中で COPR の GPG 鍵の取り込みを聞かれる。fingerprint は `FD90 9B62 88A8 4250 AD58 020F A698 91C5 CEA2 757D`（`wezfurlong_wezterm-nightly`）。

### 3. 検証する

```bash
rpm -q wezterm wezterm-common wezterm-gui wezterm-mux-server
dnf -q repoquery --installed --qf '%{name} %{from_repo}\n' 'wezterm*'
wezterm --version
ldd /usr/bin/wezterm-gui /usr/bin/wezterm /usr/bin/wezterm-mux-server | grep -c 'not found'   # 0 なら OK
wezterm ls-fonts | head -5
```

GUI をデスクトップ上で開く。**GNOME にログイン済みの端末（GNOME 端末や ssh 越しではなく実セッション）から** `wezterm` を起動すればウィンドウが開く。ssh などグラフィカルでないシェルから確認する場合は、ログイン中の Wayland セッションを指定して、ウィンドウを開いて即終了させる:

```bash
env -i HOME="$HOME" USER="$USER" PATH=/usr/bin:/bin \
    WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR="/run/user/$(id -u)" XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=GNOME \
    timeout 30 wezterm start --always-new-process -- sh -c 'exit 0'; echo "rc=$?"
```

`rc=0` ならウィンドウが開いて閉じている（`exit_behavior` の既定が `Close` なので、子プロセスが終わるとウィンドウも閉じる）。アプリ一覧には「WezTerm」が出る（`/usr/share/applications/org.wezfurlong.wezterm.desktop`）。

---

## 更新

COPR は `main` ブランチに追従して毎日〜数日おきにビルドされる。通常の `dnf upgrade` に含まれるが、WezTerm だけ上げるなら:

```bash
sudo dnf upgrade wezterm
```

---

## ロールバック

```bash
sudo dnf remove wezterm wezterm-common wezterm-gui wezterm-mux-server
sudo dnf copr remove wezfurlong/wezterm-nightly      # repo ファイルを消す
```

`~/.config/wezterm/` や `~/.wezterm.lua`（自分で作った設定）は消えないので、不要なら手で消す。COPR の GPG 鍵は `gpg-pubkey-cea2757d-651b2a3e` として残る（`rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n'` で確認できる）。消すなら `sudo rpm -e gpg-pubkey-cea2757d-651b2a3e`。

本書ではロールバックは**本実行していない**。`dnf remove --assumeno` で、消えるのが上記 4 パッケージだけ（巻き添えの依存パッケージ無し）であることは確認した。

---

## 補足

手順の理由・実測・落とし穴・調査記録。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| WezTerm | 未導入（`rpm -q wezterm` → not installed。`~/.config/wezterm` / `~/.wezterm.lua` も無し） |
| 有効な追加リポジトリ | epel、crb、COPR 2 件（lazygit / yazi。どちらも `epel-10-$basearch` chroot）、mozilla、gh-cli、claude-code |
| `dnf copr` | `dnf-plugins-core-4.7.0-10.el10` で使える |
| Flatpak | 導入済み、flathub あり（今回は使わない） |
| FUSE2 | `fuse-libs-2.9.9-25.el10`（`/usr/lib64/libfuse.so.2`）あり。AppImage を直接実行できる |
| 依存ライブラリ | `libxcb` 1.17 / `libxkbcommon(-x11)` 1.7 / `libwayland-client` 1.24 / `fontconfig` 2.15 / `mesa-libEGL` 25.2 / `openssl-libs` 3.5.8 — すべて導入済み |
| セッション | `loginctl show-session` → `Type=wayland`、`XDG_CURRENT_DESKTOP=GNOME` |

### 選択した方針

WezTerm の nightly を Linux に入れる経路は 5 つある。EL10 で使えるかを調べた結果（2026-09-21）:

| 経路 | EL10 での状況 | 採否 |
|---|---|---|
| **公式 COPR `wezfurlong/wezterm-nightly`** | chroot は `rhel-8` / `rhel-9` / `centos-stream-9` / `fedora-42〜45` / `rawhide` / `opensuse-tumbleweed`（各 x86_64 / aarch64）。**`epel-10` / `rhel-10` は無い**。ただし EL9 向けビルドの依存関係は EL10 ですべて満たせる（下記） | **採用**（chroot を `rhel-9-<arch>` と明示） |
| GitHub Releases の `nightly` タグ | `wezterm-{common,gui,mux-server}-nightly-centos9.rpm` が毎日更新される。EL10 向けは無い。手で `dnf install ./*.rpm` する形になり、更新が自動化されない | 不採用（COPR と同じ EL9 ビルドで、管理面で劣る） |
| AppImage | `WezTerm-nightly-Ubuntu24.04.AppImage` は EL10 で動く（[付録](#付録-appimage-の実測)）。ただし更新が止まりがち（2026-08-02 版）で、最新の `Ubuntu26.04` 版は **glibc 2.42 以上を要求して EL10（2.39）では起動しない** | 不採用（dnf で管理できず、最新版が動かない） |
| Flathub `org.wezfurlong.wezterm` | stable のみ。nightly は無い | 不採用 |
| ソースビルド（`cargo build --release`） | 可能だが Rust toolchain と `get-deps` の依存パッケージが要り、更新のたびにビルドする | 不採用 |

**EL9 向けビルドが EL10 で通る根拠**: 実行前に `--assumeno` で依存解決だけ試した。

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

`wezterm-gui` が要求するのは `libc.so.6(GLIBC_2.34)`、`libssl.so.3(OPENSSL_3.0.0)` / `libcrypto.so.3`、`libwayland-client.so.0` / `libwayland-egl.so.1`、`libxkbcommon.so.0(V_0.6.0)` / `libxkbcommon-x11.so.0`、`libxcb.so.1` / `libxcb-image.so.0` / `libxcb-util.so.1`、`libX11.so.6` / `libX11-xcb.so.1`、`libfontconfig.so.1`、`mesa-libEGL`、`dbus`（`dnf repoquery --requires wezterm-gui`）。EL10 は glibc 2.39 / OpenSSL 3.5（`libssl.so.3` の soname と `OPENSSL_3.0.0` シンボルバージョンを両方提供）なので、EL9 向けバイナリがそのまま動く。インストール後の `ldd` でも `not found` は 0 だった。追加で入ったパッケージは無い（4 パッケージのみ）。

### 手順の補足

#### 手順 1: chroot を明示する理由

`dnf copr enable` は chroot を省略すると `/etc/os-release` から推定する。EL 系は `epel-<major>-<arch>` になる（`/usr/lib/python3.12/site-packages/dnf-plugins/copr.py` の `_guess_chroot`）。このプロジェクトに `epel-10-x86_64` は無いので失敗する:

```
$ sudo dnf copr enable wezfurlong/wezterm-nightly
Error: It wasn't possible to enable this project.
Repository 'epel-10-x86_64' does not exist in project 'wezfurlong/wezterm-nightly'.
Available repositories: 'centos-stream-9-x86_64', 'fedora-43-aarch64', 'opensuse-tumbleweed-x86_64', 'fedora-44-aarch64', 'opensuse-tumbleweed-aarch64', 'rhel-9-x86_64', 'fedora-43-x86_64', 'fedora-rawhide-aarch64', 'fedora-42-x86_64', 'fedora-45-x86_64', 'rhel-9-aarch64', 'fedora-45-aarch64', 'fedora-rawhide-x86_64', 'fedora-44-x86_64', 'rhel-8-aarch64', 'centos-stream-9-aarch64', 'rhel-8-x86_64', 'fedora-42-aarch64'

If you want to enable a non-default repository, use the following command:
  'dnf copr enable wezfurlong/wezterm-nightly <repository>'
But note that the installed repo file will likely need a manual modification.
```

エラーメッセージの言うとおり第 2 引数に chroot を渡せば通る。「repo ファイルの手直しが要るかも」とあるが、生成された repo ファイルは `baseurl` が `rhel-9-$basearch` を指すだけで、そのまま使えた:

```
[copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly]
name=Copr repo for wezterm-nightly owned by wezfurlong
baseurl=https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/rhel-9-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
```

公式ドキュメントの openSUSE 向け手順が同じ `dnf copr enable wezfurlong/wezterm-nightly <repository>` の形なので、想定内の使い方ではある。

#### 手順 2: `wezterm` はメタパッケージ

`wezterm` 本体（6.4 KB、`rpm -ql wezterm` は空）は `wezterm-common`（CLI の `wezterm`、シェル統合、補完）/ `wezterm-gui`（`wezterm-gui`、desktop ファイル、アイコン）/ `wezterm-mux-server` を Requires で束ねているだけ。`dnf repoquery --requires wezterm` に `gcc` / `*-devel` / `make` が並んで見えるのは、同名の **SRPM の BuildRequires** が一緒に表示されているためで、x86_64 パッケージには入っていない（`--assumeno` の結果が 4 パッケージだけであることで確認）。

GPG 鍵はインストール時に COPR の `pubkey.gpg` から取り込まれる:

```
Importing GPG key 0xCEA2757D:
 Userid     : "wezfurlong_wezterm-nightly (None) <wezfurlong#wezterm-nightly@copr.fedorahosted.org>"
 Fingerprint: FD90 9B62 88A8 4250 AD58 020F A698 91C5 CEA2 757D
 From       : https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/pubkey.gpg
```

### 完了時点の状態

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

### 検証の補足

- **Wayland セッションでの起動試験**: この検証は Claude Code のシェル（TTY もディスプレイも無い）から行ったので、`env -i` で環境を空にしてから、ログイン中の GNOME セッションの `WAYLAND_DISPLAY=wayland-0` と `XDG_RUNTIME_DIR` を渡した。値は `/proc/$(pgrep -u "$USER" -x gnome-shell)/environ` から取れる。`wezterm start -- sh -c 'exit 0'` はウィンドウを開いて `sh` を走らせ、終了と同時にウィンドウを閉じる。結果 `rc=0`。`timeout 30` は、描画に失敗してウィンドウが残った場合の保険
- **`wezterm ls-fonts`** は GUI 無しでフォント解決を確認できる。既定のフォントは組み込みの `JetBrains Mono` で、フォールバックに `Noto Color Emoji`（fontconfig 経由）と組み込みの `Symbols Nerd Font Mono` が並ぶ。`| head` で切ると `rc=101`（Rust の panic 終了コード）になるが、パイプが閉じたためで異常ではない。単体で実行すると `rc=0`
- **`wezterm-gui --version` は `wezterm-gui someone forgot to call assign_version_info` と出る**（rc=0）。COPR ビルドでは GUI バイナリにバージョン情報が埋め込まれていない。バージョンは `wezterm --version` で見る

### 注意点

- **EL9 向けバイナリを EL10 で使っている。** 作者はこの組み合わせを保証していない。いまは EL9/EL10 のライブラリ soname がすべて一致しているので動くが、将来 COPR 側のビルド環境（EL9）と EL10 の間で soname が食い違えば、`dnf upgrade` が依存関係で止まるか、入っても起動しなくなる。止まったときは `dnf upgrade --exclude='wezterm*'` で他を先に上げ、COPR に `epel-10` chroot が追加されていないか[プロジェクトページ](https://copr.fedorainfracloud.org/coprs/wezfurlong/wezterm-nightly/)を見る。追加されていたら `sudo dnf copr remove wezfurlong/wezterm-nightly` → `sudo dnf copr enable wezfurlong/wezterm-nightly`（chroot 省略）で乗り換えられる
- **nightly は毎日変わる。** `dnf upgrade` のたびに WezTerm も更新される。安定版に固定したければ、COPR ではなく GitHub Releases の安定版 rpm（`wezterm-<version>-1.centos9.rpm`、こちらも EL10 向けは無い）か Flathub を使う
- **`TERM` は既定の `xterm-256color` のまま**。EL10 の `ncurses-base` に `wezterm` の terminfo は無い（`infocmp wezterm` → rc=1、`ncurses-term` も未導入）。設定で `term = "wezterm"` にするなら、先に公式ドキュメントの手順で terminfo を入れる（本書では**未実行**）:

  ```bash
  tempfile=$(mktemp) \
    && curl -o "$tempfile" https://raw.githubusercontent.com/wezterm/wezterm/main/termwiz/data/wezterm.terminfo \
    && tic -x -o ~/.terminfo "$tempfile" \
    && rm "$tempfile"
  ```

- **`/etc/profile.d/wezterm.sh` は全ユーザーの対話シェルに読み込まれる。** WezTerm 以外の端末でも OSC シーケンスを出す（大半の端末は無視する）。`bash-preexec` を内蔵しているので、`PROMPT_COMMAND` や `DEBUG` trap を自前で使っている環境では干渉に注意。無効化は `WEZTERM_SHELL_SKIP_ALL=1`
- **既存の `_copr:...yazi.repo` など EL10 向け COPR と混在させても問題ない。** repo ごとに `baseurl` の chroot が違うだけ

### 参照

- [Linux — WezTerm Install](https://wezterm.org/install/linux.html) — 「Installing on Fedora and rpm-based Systems via Copr」と、openSUSE 節の `dnf copr enable wezfurlong/wezterm-nightly <repository>` の形
- [wezfurlong/wezterm-nightly — Copr](https://copr.fedorainfracloud.org/coprs/wezfurlong/wezterm-nightly/) — 対応 chroot の一覧
- [wezterm/wezterm Releases: nightly](https://github.com/wezterm/wezterm/releases/tag/nightly) — centos9 rpm / AppImage / deb
- [dnf-copr(8)](https://dnf-plugins-core.readthedocs.io/en/latest/copr.html) — `enable name/project [chroot]`

---

### 付録: AppImage の実測

採用しなかった経路の記録。GitHub Releases の `nightly` から 2 つの AppImage を `/tmp` に取得し、`--version` だけ実行した（実行後に削除）。

| ファイル | 更新日 | 結果 |
|---|---|---|
| `WezTerm-nightly-Ubuntu24.04.AppImage`（47 MB） | 2026-08-02 | `wezterm 20260802-174340-fa0a1da0`、rc=0 |
| `WezTerm-nightly-Ubuntu26.04.AppImage`（49 MB） | 2026-09-21 | 起動せず、rc=1: `/lib64/libc.so.6: version 'GLIBC_2.42' not found` / `/lib64/libm.so.6: version 'GLIBC_2.43' not found` |

AppImage は「ビルドした Ubuntu の glibc 以上」を要求する。EL10 の glibc は 2.39 なので、Ubuntu 24.04（glibc 2.39）版までしか動かない。その 24.04 版は 1 か月半更新されておらず、この日の COPR ビルド（`20260921`）より古い。FUSE2 が無い環境では `--appimage-extract` で展開して `squashfs-root/AppRun` を実行する。
