# WezTerm Nightly インストール手順（AlmaLinux 10 / 公式 COPR の EL9 ビルドを流用）

## 実施手順

> [!IMPORTANT]
> - **すべて対象ホスト上で実行する**
> - **手順 1 と手順 3 には対話入力がある**（COPR の有効化の `[y/N]` と、COPR の GPG 鍵の取り込み）。答えてから次の手順を貼る

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 設定を書く場所と、自分用の設定（`ryo-aoki-pc/wezterm`）への案内は[設定ファイル](#設定ファイル)。以後は[更新](#更新)・[ロールバック](#ロールバック)

1. chroot を明示して、COPR を有効化する。

   ```bash
   sudo dnf copr enable wezfurlong/wezterm-nightly "rhel-9-$(uname -m)"
   ```

   - chroot は `uname -m` から `rhel-9-x86_64` か `rhel-9-aarch64` になる（COPR に EL10 向けが無いので EL9 向けを使う）
   - 有効化してよいか `[y/N]` で聞かれる
   - **次の手順は、`[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: chroot を明示する理由</summary>

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

   </details>

1. できた repo ファイルを確かめる。

   ```bash
   cat /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly.repo
   ```

   - `baseurl` が `.../wezterm-nightly/rhel-9-$basearch/`、`gpgcheck=1` になっていればよい

1. WezTerm を入れる。

   ```bash
   sudo dnf install wezterm
   ```

   - 途中で COPR の GPG 鍵の取り込みを聞かれる
   - fingerprint は `FD90 9B62 88A8 4250 AD58 020F A698 91C5 CEA2 757D`（`wezfurlong_wezterm-nightly`）
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: <code>wezterm</code> はメタパッケージ / 取り込まれる鍵</summary>

   - `wezterm` 本体（6.4 KB、`rpm -ql wezterm` は空）は、`wezterm-common`（CLI の `wezterm`、シェル統合、補完）/ `wezterm-gui`（`wezterm-gui`、desktop ファイル、アイコン）/ `wezterm-mux-server` を Requires で束ねているだけ
   - `dnf repoquery --requires wezterm` に `gcc` / `*-devel` / `make` が並んで見えるのは、同名の **SRPM の BuildRequires** が一緒に表示されているため。x86_64 パッケージには入っていない（`--assumeno` の結果が 4 パッケージだけであることで確認）

   GPG 鍵はインストール時に COPR の `pubkey.gpg` から取り込まれる:

   ```
   Importing GPG key 0xCEA2757D:
    Userid     : "wezfurlong_wezterm-nightly (None) <wezfurlong#wezterm-nightly@copr.fedorahosted.org>"
    Fingerprint: FD90 9B62 88A8 4250 AD58 020F A698 91C5 CEA2 757D
    From       : https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/pubkey.gpg
   ```

   </details>

1. WezTerm が入ったか確かめる。

   ```bash
   rpm -q wezterm wezterm-common wezterm-gui wezterm-mux-server
   dnf -q repoquery --installed --qf '%{name} %{from_repo}\n' 'wezterm*'
   wezterm --version
   ldd /usr/bin/wezterm-gui /usr/bin/wezterm /usr/bin/wezterm-mux-server | grep -c 'not found'   # 0 なら OK
   wezterm ls-fonts | head -5
   ```

   - GUI は、**GNOME にログイン済みの実セッションの端末から** `wezterm` を起動すれば開く
   - アプリ一覧には「WezTerm」が出る（`/usr/share/applications/org.wezfurlong.wezterm.desktop`）
   - ssh などグラフィカルでないシェルから確かめる場合は、手順 5 でログイン中の Wayland セッションを指定して、ウィンドウを開いて即終了させる
   - GNOME の端末から `wezterm` で確かめたなら、手順 5 は飛ばす

   <details>
   <summary>補足: <code>wezterm ls-fonts</code> と <code>wezterm-gui --version</code></summary>

   - **`wezterm ls-fonts`** は GUI 無しでフォント解決を確認できる
     - 既定のフォントは組み込みの `JetBrains Mono` で、フォールバックに `Noto Color Emoji`（fontconfig 経由）と組み込みの `Symbols Nerd Font Mono` が並ぶ
     - `| head` で切ると `rc=101`（Rust の panic 終了コード）になるが、パイプが閉じたためで異常ではない。単体で実行すると `rc=0`
   - **`wezterm-gui --version` は `wezterm-gui someone forgot to call assign_version_info` と出る**（rc=0）
     - COPR ビルドでは GUI バイナリにバージョン情報が埋め込まれていない。バージョンは `wezterm --version` で見る

   </details>

1. ssh などグラフィカルでないシェルから確かめるときだけ、ウィンドウを開いて即終了させる。

   ```bash
   env -i HOME="$HOME" USER="$USER" PATH=/usr/bin:/bin \
       WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR="/run/user/$(id -u)" XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=GNOME \
       timeout 30 wezterm start --always-new-process -- sh -c 'exit 0'; echo "rc=$?"
   ```

   - ログイン中の Wayland セッションを指定して、ウィンドウを開く
   - `rc=0` なら、ウィンドウが開いて閉じている（`exit_behavior` の既定が `Close` なので、子プロセスが終わるとウィンドウも閉じる）

   <details>
   <summary>補足: Wayland セッションでの起動試験</summary>

   - **Wayland セッションでの起動試験**: この検証は Claude Code のシェル（TTY もディスプレイも無い）から行ったので、`env -i` で環境を空にしてから、ログイン中の GNOME セッションの `WAYLAND_DISPLAY=wayland-0` と `XDG_RUNTIME_DIR` を渡した
     - 値は `/proc/$(pgrep -u "$USER" -x gnome-shell)/environ` から取れる
     - `wezterm start -- sh -c 'exit 0'` はウィンドウを開いて `sh` を走らせ、終了と同時にウィンドウを閉じる。結果 `rc=0`
     - `timeout 30` は、描画に失敗してウィンドウが残った場合の保険

   </details>

---

## 設定ファイル

- パッケージは設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は次の順で探し、**最初に見つかった 1 つだけ**を読む（[補足: 設定ファイルの探索順序](#設定ファイルの探索順序実測)）

| 優先 | 場所 | 用途 |
|---|---|---|
| 1 | `wezterm --config-file <path>` | 一時的に別の設定で起動する |
| 2 | 環境変数 `WEZTERM_CONFIG_FILE` | 同上（環境ごとに切り替える） |
| 3 | `~/.wezterm.lua` | **1 ファイルで済む設定はここ**（公式の推奨） |
| 4 | `${XDG_CONFIG_HOME}/wezterm/wezterm.lua`（`XDG_CONFIG_HOME` を設定している場合のみ） | 複数ファイルに分ける設定 |
| 5 | `~/.config/wezterm/wezterm.lua`（`XDG_CONFIG_HOME` 未設定のとき） | 同上 |

- **自分用の設定**は [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm) にある（Tokyo Night 系の配色・ピル型タブ・ステータスバー・シェル統合の設定）
  - 入れ方は、その [docs/install.md](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md)（本書と同じ書式の手順書）。`~/.config/wezterm` に clone し、`~/.bashrc` にシェル統合の 1 行を足す
  - どこを変えればよいかは [README の「カスタマイズの勘所」](https://github.com/ryo-aoki-pc/wezterm#カスタマイズの勘所)
  - nightly が前提（stable では未知のオプションで設定エラーになる）。本書で入れるのは nightly
  - フォントは HackGen Console NF（[hackgen.md](hackgen.md)）
  - 本書の RPM が置く `/etc/profile.d/wezterm.sh` が読まれていると、設定のシェル統合は迷子のマウス報告よけだけになり、完了通知は動かない（[docs/install.md の注意点](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#注意点)）
  - この設定を入れるなら、この節の手順 1 は貼らない（`~/.config/wezterm` が空でないと clone できない）
  - `~/.wezterm.lua` があると、clone した設定は読まれない

> [!WARNING]
> **この節の**手順 1 は、既存の `~/.config/wezterm/wezterm.lua` を**上書きする**。自分の設定がある人は貼らない。

1. 自分の設定が無いときだけ、最小の例を `~/.config/wezterm/wezterm.lua` に書く。

   ```bash
   mkdir -p ~/.config/wezterm
   cat > ~/.config/wezterm/wezterm.lua <<'LUA'
   local wezterm = require 'wezterm'
   local config = wezterm.config_builder()
   config.font = wezterm.font 'Noto Sans Mono'
   config.font_size = 12
   return config
   LUA
   wezterm ls-fonts | head -5     # Primary font に書いたフォントが出れば読めている
   ```

   - **`~/.wezterm.lua` が既にあるとそちらが優先されて読まれない**ので、どちらか一方にする
   - 保存すれば、起動中の WezTerm にも自動で反映される（`automatically_reload_config` の既定が true。効かなければ `Ctrl+Shift+R`）
   - Lua の文法エラーがあると、起動時に `ERROR wezterm_gui > syntax error: ...` を出して**組み込みの既定値で起動する**（別の候補ファイルには進まない）
   - `wezterm -n`（`--skip-config`）で、設定を読まずに起動できる
   - `wezterm --config 'font_size=14'` のように、1 項目だけ上書きもできる

---

## 更新

- COPR は `main` ブランチに追従して毎日〜数日おきにビルドされる
- 通常の `dnf upgrade` に含まれる

1. WezTerm だけ上げるときは、名前を指定して上げる。

   ```bash
   sudo dnf upgrade wezterm
   ```

---

## ロールバック

- 本書ではロールバックを**本実行していない**（`dnf remove --assumeno` で、消えるのがこの節の手順 1 の 4 パッケージだけであることまで確認した）

1. WezTerm の 4 パッケージを消す。

   ```bash
   sudo dnf remove wezterm wezterm-common wezterm-gui wezterm-mux-server
   ```

   - 消えるのはこの 4 パッケージだけで、巻き添えの依存パッケージは無い
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. COPR の repo ファイルを消す。

   ```bash
   sudo dnf copr remove wezfurlong/wezterm-nightly      # repo ファイルを消す
   ```

   - `~/.config/wezterm/` や `~/.wezterm.lua`（自分で作った設定）は消えないので、不要なら手で消す
   - 自分用の設定（`ryo-aoki-pc/wezterm`）を入れていれば、`~/.bashrc` に足したシェル統合の 1 行も残る（消し方は、その [docs/install.md のロールバック](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#ロールバック)）
   - COPR の GPG 鍵は `gpg-pubkey-cea2757d-651b2a3e` として残る（`rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n'` で確認できる）
   - 消すなら `sudo rpm -e gpg-pubkey-cea2757d-651b2a3e`

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [WezTerm](https://wezterm.org/) の nightly ビルドを **dnf 管理で**入れ、以後は `dnf upgrade` で追従できるようにする
- **進め方**: 作者が管理する公式 COPR `wezfurlong/wezterm-nightly` には **EL10 向けのビルドが無い**ので、chroot を `rhel-9-<arch>` と明示して有効化し、EL9 向けビルドをそのまま入れる
  - **読者が書き換える変数は無い**（chroot は `uname -m` から自動で決まる）
  - 設定ファイルは `~/.wezterm.lua` か `~/.config/wezterm/wezterm.lua`（[設定ファイル](#設定ファイル)）
- **状態**: **2026-09-21 にこのホスト（x86_64 / GNOME 49 Wayland）で本実行済み**
  - 確認したこと: ウィンドウの起動・終了まで
  - **aarch64 は未検証**（COPR に `rhel-9-aarch64` はあるので、同じ手順で通る見込み）
  - EL9 向けビルドを EL10 で使う非公式な流用なので、更新で壊れたら[補足: 注意点](#注意点)を見る

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

> [!NOTE]
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。パッケージのバージョン（`20260921_051727_5eb03b23`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と調査記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

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

`wezterm-gui` が要求するのは次のもの（`dnf repoquery --requires wezterm-gui`）:

- `libc.so.6(GLIBC_2.34)`
- `libssl.so.3(OPENSSL_3.0.0)` / `libcrypto.so.3`
- `libwayland-client.so.0` / `libwayland-egl.so.1`
- `libxkbcommon.so.0(V_0.6.0)` / `libxkbcommon-x11.so.0`
- `libxcb.so.1` / `libxcb-image.so.0` / `libxcb-util.so.1`
- `libX11.so.6` / `libX11-xcb.so.1`
- `libfontconfig.so.1`、`mesa-libEGL`、`dbus`

EL10 は glibc 2.39 / OpenSSL 3.5（`libssl.so.3` の soname と `OPENSSL_3.0.0` シンボルバージョンを両方提供）なので、EL9 向けバイナリがそのまま動く。

- インストール後の `ldd` でも、`not found` は 0 だった
- 追加で入ったパッケージは無い（4 パッケージのみ）

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

### 設定ファイルの探索順序（実測）

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

### 注意点

- **EL9 向けバイナリを EL10 で使っている。** 作者はこの組み合わせを保証していない
  - いまは EL9/EL10 のライブラリ soname がすべて一致しているので動く
  - 将来 COPR 側のビルド環境（EL9）と EL10 の間で soname が食い違えば、`dnf upgrade` が依存関係で止まるか、入っても起動しなくなる
  - 止まったときは `dnf upgrade --exclude='wezterm*'` で他を先に上げ、COPR に `epel-10` chroot が追加されていないか[プロジェクトページ](https://copr.fedorainfracloud.org/coprs/wezfurlong/wezterm-nightly/)を見る
  - 追加されていたら、`sudo dnf copr remove wezfurlong/wezterm-nightly` → `sudo dnf copr enable wezfurlong/wezterm-nightly`（chroot 省略）で乗り換えられる
- **nightly は毎日変わる。** `dnf upgrade` のたびに WezTerm も更新される
  - 安定版に固定したければ、COPR ではなく GitHub Releases の安定版 rpm（`wezterm-<version>-1.centos9.rpm`、こちらも EL10 向けは無い）か Flathub を使う
- **`TERM` は既定の `xterm-256color` のまま**。EL10 の `ncurses-base` に `wezterm` の terminfo は無い（`infocmp wezterm` → rc=1、`ncurses-term` も未導入）

  設定で `term = "wezterm"` にするなら、先に公式ドキュメントの手順で terminfo を入れる（本書では**未実行**）:

  ```bash
  tempfile=$(mktemp) \
    && curl -o "$tempfile" https://raw.githubusercontent.com/wezterm/wezterm/main/termwiz/data/wezterm.terminfo \
    && tic -x -o ~/.terminfo "$tempfile" \
    && rm "$tempfile"
  ```

- **`/etc/profile.d/wezterm.sh` は全ユーザーの対話シェルに読み込まれる。** WezTerm 以外の端末でも OSC シーケンスを出す（大半の端末は無視する）
  - `bash-preexec` を内蔵しているので、`PROMPT_COMMAND` や `DEBUG` trap を自前で使っている環境では干渉に注意
  - 無効化は `WEZTERM_SHELL_SKIP_ALL=1`
- **既存の `_copr:...yazi.repo` など EL10 向け COPR と混在させても問題ない。** repo ごとに `baseurl` の chroot が違うだけ

### 参照

- [Linux — WezTerm Install](https://wezterm.org/install/linux.html) — 「Installing on Fedora and rpm-based Systems via Copr」と、openSUSE 節の `dnf copr enable wezfurlong/wezterm-nightly <repository>` の形
- [wezfurlong/wezterm-nightly — Copr](https://copr.fedorainfracloud.org/coprs/wezfurlong/wezterm-nightly/) — 対応 chroot の一覧
- [wezterm/wezterm Releases: nightly](https://github.com/wezterm/wezterm/releases/tag/nightly) — centos9 rpm / AppImage / deb
- [dnf-copr(8)](https://dnf-plugins-core.readthedocs.io/en/latest/copr.html) — `enable name/project [chroot]`
- [Configuration Files — WezTerm](https://wezterm.org/config/files.html) — 設定ファイルの探索順序（本書の実測とは `~/.wezterm.lua` の優先度が異なる）
- [wezterm/wezterm config/src/config.rs `load_with_overrides`](https://github.com/wezterm/wezterm/blob/main/config/src/config.rs) — 実際の探索順序
- [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm) — 自分用の設定。導入の手順は `docs/install.md`、変える場所は README にある

---

### 付録: AppImage の実測

採用しなかった経路の記録。GitHub Releases の `nightly` から 2 つの AppImage を `/tmp` に取得し、`--version` だけ実行した（実行後に削除）。

| ファイル | 更新日 | 結果 |
|---|---|---|
| `WezTerm-nightly-Ubuntu24.04.AppImage`（47 MB） | 2026-08-02 | `wezterm 20260802-174340-fa0a1da0`、rc=0 |
| `WezTerm-nightly-Ubuntu26.04.AppImage`（49 MB） | 2026-09-21 | 起動せず、rc=1: `/lib64/libc.so.6: version 'GLIBC_2.42' not found` / `/lib64/libm.so.6: version 'GLIBC_2.43' not found` |

AppImage は「ビルドした Ubuntu の glibc 以上」を要求する。EL10 の glibc は 2.39 なので、Ubuntu 24.04（glibc 2.39）版までしか動かない。その 24.04 版は 1 か月半更新されておらず、この日の COPR ビルド（`20260921`）より古い。FUSE2 が無い環境では `--appimage-extract` で展開して `squashfs-root/AppRun` を実行する。
