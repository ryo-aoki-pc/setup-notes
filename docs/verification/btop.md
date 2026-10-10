# btop インストール手順（AlmaLinux 10 / EPEL）の検証記録

[手順書](../btop.md)・[ロールバックと注意点](../extra/btop.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 操作上の注意と併記されていた記録

   - 依存として `hicolor-icon-theme`（デスクトップエントリのアイコン用）が、まだ無ければ一緒に入る。x86_64 では `rocm-smi` も入った（2026-10-06 の Workstation VM。GPU の無い VM でも依存として解決された）

### 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 のクリーン VM で実施手順を本実行済み**（2026-10-06）。実機では本実行していない（[対象と検証環境](#対象と検証環境)）。

### 実施手順 / 手順 3: 補足: 設定は初回起動まで作られない

`dnf install` の直後は `~/.config/btop` が存在しない。**1 回起動して初めて** `btop.conf` と空の `themes/` が作られる。コンテナで `script` を使って pty を与え、5 秒で切った実測:

```
$ timeout 5 script -qec "btop" /dev/null >/dev/null 2>&1
$ ls -l ~/.config/btop/
total 16
-rw-r--r--. 1 <USER> <USER> 9819 Sep 22 20:46 btop.conf
drwxr-xr-x. 2 <USER> <USER> 4096 Sep 22 20:46 themes
$ head -6 ~/.config/btop/btop.conf
#? Config file for btop v.1.4.7

#* Name of a btop++/bpytop/bashtop formatted ".theme" file, "Default" and "TTY" for builtin themes.
#* Themes should be placed in "../share/btop/themes" relative to binary or "$HOME/.config/btop/themes"
color_theme = "Default"
```

**この確認で分かるのは「起動してファイルが作られた」ところまで**で、画面がどう描画されたかは見ていない（`script` の出力は捨てている）。

### ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**

### 対象と検証環境

- **目的**: AlmaLinux 10 に [btop](https://github.com/aristocratos/btop)（CPU・メモリ・ディスク・ネットワーク・プロセスをまとめて見る TUI。`htop` の後継的な位置づけ）を入れる
- **進め方**: **Homebrew ではなく EPEL の dnf で入れる**。同じ版が両方にあるため（[選択した方針](../verification/btop.md#選択した方針)）。EPEL の有効化は前提の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順 17 に任せる。読者が編集する変数は無い
- **状態**: **x86_64 のクリーン VM で実施手順 1〜3 を本実行済み（2026-10-06）。コンテナでも検証済み（2026-09-22）。実機には入れていない**
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**、EPEL の有効化（今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順 17。当時はこの文書の手順だった）と手順 1〜3 を通した
  - 確認したこと: `epel-release` が `extras` から入る、`btop 1.4.7-1.el10_2` が EPEL から解決される、署名鍵の fingerprint が本文の値と一致する、pty を与えた起動で `btop.conf` が生成される
  - コンテナで未確認だった TUI の各欄の表示と `q` での終了は、2026-10-06 のクリーン VM で確認した。テーマを変えた見え方は未確認
  - **実機（Raspberry Pi 5）では本実行していない**ので、下表の実機列は「この手順を適用した結果」ではなく**現時点の状態**を書いてある

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| EPEL | **有効**（`epel-release 10-8.el10_2`。[epel.md](../almalinux-setup.md) の手順 2 は不要） | 未設定 → [epel.md](../almalinux-setup.md) の手順 2 で `epel-release 10-6.el10` を導入 |
| 有効なリポジトリ | baseos / appstream / crb / extras / epel / raspberrypi ほか | baseos / appstream / crb / extras（→ epel を追加） |
| btop | **未導入** | `btop 1.4.7-1.el10_2`（epel） |
| 一緒に入る依存 | — | `hicolor-icon-theme 0.17-20.el10`（appstream） |
| 端末 | WezTerm nightly（[wezterm-nightly.md](../wezterm-nightly.md)） | 無し（`script` で pty を与えた起動のみ） |

> [!NOTE]
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`1.4.7-1.el10_2`）は実行日によって変わる。**鍵の fingerprint は公開情報なので本文に書いてある。**

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| btop | 未導入 |
| htop | 未導入（EPEL に `3.3.0-5.el10_0` がある） |
| EPEL | 有効（`epel-release 10-8.el10_2`） |
| CRB | 有効 |
| Homebrew | 7.0.6 導入済み（本書では使わない） |

### 選択した方針

AlmaLinux 10 aarch64 で btop を入れる経路を比べた（2026-09-22 時点）:

版の比較に使った実測:

### 完了時点の状態

**検証コンテナでの出力**（実機では本実行していない）:

```
$ btop --version
btop version: 1.4.7
Compiled with: g++ (14.3.1)
Configured with: /usr/bin/make STATIC= GPU_SUPPORT=false RSMI_STATIC=
$ command -v btop
/usr/bin/btop
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' btop
btop 1.4.7-1.el10_2 epel
$ rpm -ql btop | head -5
/usr/bin/btop
/usr/lib/.build-id
/usr/lib/.build-id/98
/usr/lib/.build-id/98/c5a902ac5048f00d5d14b25437fb58d30294c8
/usr/share/applications/btop.desktop
$ ls /usr/share/btop/themes/ | head -5
HotPurpleTrafficLight.theme
adapta.theme
adwaita-dark.theme
adwaita.theme
ayu.theme
```

インストールサイズは 1.4 MB（ダウンロードは依存込みで 597 KB）。

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で、EPEL の有効化（今の [AlmaLinux 10 の初期設定](../almalinux-setup.md)の手順 17。当時はこの文書の手順 1〜3）と手順 1〜3 を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、`dnf install` に `-y` を付け、起動の 1 行だけ `timeout 5 script -qec "btop" /dev/null` に置き換えている。

| 手順 | 結果 |
|---|---|
| epel.md 1〜3. EPEL | 導入前の `dnf repolist enabled` は baseos / appstream / crb / extras の 4 つで、`dnf list --available btop` は `Error: No matching Packages to list`。`dnf install -y epel-release` で `epel-release-10-6.el10`（extras）と弱い依存の `dnf-plugins-core-4.7.0-10.el10`（baseos）が入り、`epel` が有効になった |
| 1. btop | `dnf -q list --showduplicates btop` → `1.4.7-1.el10_2 epel` の 1 行だけ。`dnf install` で EPEL の鍵（`0xE37ED158`、fingerprint は本文のとおり）を `/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10` から取り込み、`btop` と `hicolor-icon-theme` の 2 つを導入（597 KB / 展開後 1.4 MB） |
| 2〜3. 検証 | `btop --version` → `1.4.7`、`GPU_SUPPORT=false`。`command -v btop` → `/usr/bin/btop`。`repoquery --installed` の `from_repo` が `epel` |
| 起動 | `script` で pty を与えて 5 秒で切ったところ、`~/.config/btop/btop.conf`（9819 バイト）と `themes/` が生成された。**画面の内容は確認していない**（出力は捨てている） |
| テーマ | `/usr/share/btop/themes/` に 30 個以上の `.theme` が入ることを確認 |
| Homebrew 側 | 別コンテナの `brew info btop` は `stable 1.4.7 (bottled)`、依存なし。**EPEL と同版** |

#### 未確認事項

- 実機での本実行（本書は実機に適用していない）
- GNOME 端末・WezTerm の画面での色と、テーマを変えた見え方
- キー操作（メニュー、プロセスの絞り込み、シグナル送信）
- `-t` / `--force-utf` / `-l` の効果
- `-p`（プリセット）と `btop.conf` の書き換え
- `sudo btop` で他ユーザーのプロセスがどこまで見えるか
- Raspberry Pi 5 での CPU 温度・周波数の表示
- ロールバック（`dnf remove btop` と `~/.config/btop` の削除）の本実行

---

### 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜3（先に epel.md 手順 1〜3）。

**結果**: btop 1.4.7 が EPEL から入り、署名鍵の fingerprint が本文と一致した。x86_64 の依存として `rocm-smi-7.1.1-2.el10_2` も入った。`hicolor-icon-theme` は Workstation に最初からあった。実際の TUI で CPU・メモリー・ディスク・ネットワーク・プロセスの欄を読み、`q` で終了した。`~/.config/btop/btop.conf` と `themes` が生成された。

**今回の未確認範囲**: テーマを変える任意節、実機の GPU、更新・ロールバックは今回確認していない。

### 付録: 現行版の新規 VM での再検証（2026-10-06）

公式 ISO から新規導入した AlmaLinux 10.2 Workstation の x86_64 VM（kernel `6.12.0-211.61.1.el10_2.x86_64`、SELinux Enforcing、firewalld active）で、`5da3478` の本文を SSH 対話 PTY に渡した。試験専用のユーザー・鍵と設定値を使用し、利用者の実アカウントの資格情報は持ち込んでいない。

実施手順 1・2 を通した。EPEL の btop 1.4.7 と依存 rocm-smi が入り、/usr/bin/btop、RPM の導入元を確認した。対話 PTY に CPU・メモリ・ネットワーク・プロセスの画面が描画され、q で終了 0 に戻った。物理端末での色・GPU・更新・ロールバックはこの再検証で行っていない。


### 選択した方針

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **EPEL（dnf）** | `btop.aarch64 1.4.7-1.el10_2`。**Homebrew と同じ 1.4.7**。RPM 管理なので `dnf upgrade` に乗り、root でもそのまま使える | **採用** |
| Homebrew | `btop 1.4.7` の `arm64_linux` ボトルがある。依存は無い。ただし**版が同じ**で、PATH が通っているユーザーでしか使えない | 不採用（同版なら RPM が有利） |
| GitHub Releases のバイナリ | `aarch64` の tar がある。更新は手作業 | 不採用 |
| ソースビルド | `make` 1 本で済むが、GCC 14 以降が要る | 不採用 |
| `htop` で代用 | EPEL に `3.3.0-5.el10_0` がある。軽いが、ディスク・ネットワークのグラフは無い | 対象外（併用できる） |

**この文書が Homebrew を使わないのは、EPEL 版が upstream に追いついているため。**

- ほかの Homebrew 系の手順書（当時の homebrew.md の冒頭に挙げた 17 本）は、どれも RPM（BaseOS・AppStream・EPEL）に無いか古いので Homebrew を選んでいる
- 同じ規則（同版なら RPM）で、[image-tools.md](../image-tools.md) の Trivy は公式の dnf リポジトリにした
- [distrobox](../distrobox.md)・[podman-compose](../podman-compose.md)・[podman-tui](../podman-tui.md) も EPEL だが、理由は版ではなく、システムの podman と組むため（[ツール一覧の選び方](../tool-catalog.md#選び方)の規則 3）
- EPEL が遅れ始めたら Homebrew に移せるが、**そのときは片方だけにする**（[注意点](../extra/btop.md#注意点)）

```
$ dnf -q list --showduplicates btop
Available Packages
btop.aarch64                         1.4.7-1.el10_2                         epel
$ brew info btop | head -2
==> btop: stable 1.4.7 (bottled), HEAD
Resource monitor that shows usage and stats for processor, memory, disks, network and processes
```

