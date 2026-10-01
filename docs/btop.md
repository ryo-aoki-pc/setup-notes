# btop インストール手順（AlmaLinux 10 / EPEL）

## 実施手順

> [!IMPORTANT]
> - **前提**: [EPEL](epel.md) を有効にしてあること。`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す
> - **すべて対象ホスト上で実行する**
> - **手順 1 には対話入力がある**（トランザクション表の `[y/N]` と鍵の確認）。答えてから手順 2 を貼る
> - **手順 2 で TUI が開く**。`q` で終了してから手順 3 を貼る

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 設定を書く場所は[設定ファイル](#設定ファイル)、以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **コンテナでのみ検証した手順書**で、実機では本実行していない（[対象と検証環境](#対象と検証環境)）。

1. 入手できる版を見てから、btop を入れる。

   ```bash
   dnf -q list --showduplicates btop
   sudo dnf install btop
   ```

   - 版は `btop.aarch64  1.4.7-1.el10_2  epel` のように 1 つだけ出る
   - 依存として `hicolor-icon-theme`（デスクトップエントリのアイコン用）が一緒に入る
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを目で確かめてから `y` と答える。違っていれば `N` で中断する
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

1. btop が入ったか確かめ、起動する。

   ```bash
   btop --version
   command -v btop
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' btop
   btop
   ```

   - `btop version: 1.4.7` と `/usr/bin/btop` が出てから、btop の画面が開く
   - 画面が出たら `q` で終了する
   - **次の手順は、`q` で終了してから貼る**（続けて貼ると btop への操作として食われる）

1. 初回の起動で `~/.config/btop/btop.conf` が作られたか確かめる。

   ```bash
   ls -l ~/.config/btop
   ```

   - `btop.conf` と `themes/` があればよい

   <details>
   <summary>補足: 設定は初回起動まで作られない</summary>

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

   </details>

---

## 設定ファイル

- `~/.config/btop/btop.conf` は**初回起動時に既定値で作られる**（約 9.8 KB、項目ごとにコメント付き）
- アプリ内では `Esc` または `m` でメニューが開き、`Options` からほとんどの項目を GUI で変えられる（保存も btop がやる）
- テーマは 2 か所から読む。`btop.conf` の `color_theme` にファイル名を書くと切り替わる（`"Default"` と `"TTY"` は組み込み）
  - `/usr/share/btop/themes/`: RPM が入れる既定のテーマ（`dracula` / `nord` / `gruvbox-*` / `adwaita-dark` など）
  - `~/.config/btop/themes/`: 自分で足すテーマ

1. 起動せずに、既定の設定だけを見る。

   ```bash
   btop --default-config | head -20
   ```

   <details>
   <summary>補足: よく使う起動オプション</summary>

   `btop --help` の全文より抜粋:

   | オプション | 意味 |
   |---|---|
   | `-p, --preset <id>` | プリセット（0-9）を指定して起動 |
   | `-t, --tty` / `--no-tty` | TTY モードの強制・強制解除（16 色と ASCII 寄りの記号になる） |
   | `-l, --low-color` | true color を使わず 256 色にする |
   | `--force-utf` | ロケール判定を無視して UTF-8 として扱う |
   | `-u, --update <ms>` | 更新間隔 |
   | `-f, --filter <filter>` | プロセスの絞り込みを指定して起動 |
   | `-c, --config <file>` | 設定ファイルを指定 |
   | `--default-config` | 既定の設定を標準出力に出す |

   </details>

---

## 更新

- btop は通常の更新に含まれる

1. btop を更新する。

   ```bash
   sudo dnf upgrade btop
   ```

   - システム全体なら `sudo dnf upgrade`
   - EPEL が新しい版を出すまでは上がらない（[注意点](#注意点)）

---

## ロールバック

- 本書ではロールバックは**本実行していない**

1. btop を消す。

   ```bash
   sudo dnf remove btop
   ```

   - 依存で入った `hicolor-icon-theme` は他のパッケージも使うので、残しておいてよい（不要なものだけ消すなら `sudo dnf autoremove`）
   - **EPEL 自体は消さない**（他のパッケージが依存している可能性がある）。消すなら [epel.md のロールバック](epel.md#ロールバック)
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. 設定とユーザーテーマも消すときだけ、`~/.config/btop` を消す。

   ```bash
   rm -rf ~/.config/btop        # 設定とユーザーテーマも消す場合
   ```

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [btop](https://github.com/aristocratos/btop)（CPU・メモリ・ディスク・ネットワーク・プロセスをまとめて見る TUI。`htop` の後継的な位置づけ）を入れる
- **進め方**: **Homebrew ではなく EPEL の dnf で入れる**。同じ版が両方にあるため（[選択した方針](#選択した方針)）。EPEL の有効化は前提の [epel.md](epel.md) に任せる。読者が編集する変数は無い
- **状態**: **コンテナでのみ検証済み（2026-09-22）。実機には入れていない**
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**、EPEL の有効化（今の [epel.md](epel.md) の手順 1〜3。当時はこの文書の手順だった）と手順 1〜3 を通した
  - 確認したこと: `epel-release` が `extras` から入る、`btop 1.4.7-1.el10_2` が EPEL から解決される、署名鍵の fingerprint が本文の値と一致する、pty を与えた起動で `btop.conf` が生成される
  - **確認していないこと**: 画面の描画内容・操作・テーマの見え方。コンテナには本物の端末が無いため
  - **実機（Raspberry Pi 5）では本実行していない**ので、下表の実機列は「この手順を適用した結果」ではなく**現時点の状態**を書いてある

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| EPEL | **有効**（`epel-release 10-8.el10_2`。[epel.md](epel.md) の手順 2 は不要） | 未設定 → [epel.md](epel.md) の手順 2 で `epel-release 10-6.el10` を導入 |
| 有効なリポジトリ | baseos / appstream / crb / extras / epel / raspberrypi ほか | baseos / appstream / crb / extras（→ epel を追加） |
| btop | **未導入** | `btop 1.4.7-1.el10_2`（epel） |
| 一緒に入る依存 | — | `hicolor-icon-theme 0.17-20.el10`（appstream） |
| 端末 | WezTerm nightly（[wezterm-nightly.md](wezterm-nightly.md)） | 無し（`script` で pty を与えた起動のみ） |

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

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **EPEL（dnf）** | `btop.aarch64 1.4.7-1.el10_2`。**Homebrew と同じ 1.4.7**。RPM 管理なので `dnf upgrade` に乗り、root でもそのまま使える | **採用** |
| Homebrew | `btop 1.4.7` の `arm64_linux` ボトルがある。依存は無い。ただし**版が同じ**で、PATH が通っているユーザーでしか使えない | 不採用（同版なら RPM が有利） |
| GitHub Releases のバイナリ | `aarch64` の tar がある。更新は手作業 | 不採用 |
| ソースビルド | `make` 1 本で済むが、GCC 14 以降が要る | 不採用 |
| `htop` で代用 | EPEL に `3.3.0-5.el10_0` がある。軽いが、ディスク・ネットワークのグラフは無い | 対象外（併用できる） |

**この文書が Homebrew を使わないのは、EPEL 版が upstream に追いついているため。**

- ほかの Homebrew 系の手順書（[homebrew.md](homebrew.md) の冒頭に挙げた 16 本）は、どれも RPM（BaseOS・AppStream・EPEL）に無いか古いので Homebrew を選んでいる
- 同じ規則（同版なら RPM）で、[image-tools.md](image-tools.md) の Trivy は公式の dnf リポジトリにした
- [distrobox](distrobox.md)・[podman-compose](podman-compose.md)・[podman-tui](podman-tui.md) も EPEL だが、理由は版ではなく、システムの podman と組むため（[ツール一覧の選び方](tool-catalog.md#選び方)の規則 3）
- EPEL が遅れ始めたら Homebrew に移せるが、**そのときは片方だけにする**（[注意点](#注意点)）

版の比較に使った実測:

```
$ dnf -q list --showduplicates btop
Available Packages
btop.aarch64                         1.4.7-1.el10_2                         epel
$ brew info btop | head -2
==> btop: stable 1.4.7 (bottled), HEAD
Resource monitor that shows usage and stats for processor, memory, disks, network and processes
```

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

### 注意点

- **EPEL 版は `GPU_SUPPORT=false` でビルドされている**: `btop --version` の 3 行目にそう出る。GPU の使用率パネルは出ない
  - Raspberry Pi では元々使えないので実害は無いが、GPU 監視が目的なら別経路を検討する
- **EPEL が遅れると版が止まる**: 今は upstream と同じ 1.4.7 だが、EPEL の更新が止まれば古いままになる。そのときは Homebrew 版に移せる
  - **ただし `/usr/bin/btop` と Homebrew 版を両方入れると、PATH の先頭にある Homebrew 版が勝ち、`dnf upgrade` で上がるのは使われないほうになる。片方だけにする**
- **表示は端末の UTF-8 とカラーに依存する**: 記号が崩れるときは `--force-utf`、色がおかしいときは `-l`（256 色）や `-t`（TTY モード）を試す
- **root で起動しなくても動く**: ただし他ユーザーのプロセスの詳細（コマンドライン全体など）は見えないことがある
  - 全部見たいなら `sudo btop`（RPM なので root の PATH にも入っている。ここが Homebrew 版との違い）
- **設定は初回起動まで作られない**: [手順 3 の補足](#実施手順)
- **`htop` とは別物**: 同時に入れても衝突しない

### 参照

- [aristocratos/btop — README](https://github.com/aristocratos/btop) — 機能、キーバインド、設定項目、テーマの書式
- [EPEL](epel.md) — 前提の手順書（`epel-release` の入れ方と、CRB の案内）
- `btop --help` / `btop --default-config` — 起動オプションと既定の設定
- `man btop` — RPM に同梱

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で、EPEL の有効化（今の [epel.md](epel.md) の手順 1〜3。当時はこの文書の手順 1〜3）と手順 1〜3 を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、`dnf install` に `-y` を付け、起動の 1 行だけ `timeout 5 script -qec "btop" /dev/null` に置き換えている。

| 手順 | 結果 |
|---|---|
| epel.md 1〜3. EPEL | 導入前の `dnf repolist enabled` は baseos / appstream / crb / extras の 4 つで、`dnf list --available btop` は `Error: No matching Packages to list`。`dnf install -y epel-release` で `epel-release-10-6.el10`（extras）と弱い依存の `dnf-plugins-core-4.7.0-10.el10`（baseos）が入り、`epel` が有効になった |
| 1. btop | `dnf -q list --showduplicates btop` → `1.4.7-1.el10_2 epel` の 1 行だけ。`dnf install` で EPEL の鍵（`0xE37ED158`、fingerprint は本文のとおり）を `/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10` から取り込み、`btop` と `hicolor-icon-theme` の 2 つを導入（597 KB / 展開後 1.4 MB） |
| 2〜3. 検証 | `btop --version` → `1.4.7`、`GPU_SUPPORT=false`。`command -v btop` → `/usr/bin/btop`。`repoquery --installed` の `from_repo` が `epel` |
| 起動 | `script` で pty を与えて 5 秒で切ったところ、`~/.config/btop/btop.conf`（9819 バイト）と `themes/` が生成された。**画面の内容は確認していない**（出力は捨てている） |
| テーマ | `/usr/share/btop/themes/` に 30 個以上の `.theme` が入ることを確認 |
| Homebrew 側 | 別コンテナの `brew info btop` は `stable 1.4.7 (bottled)`、依存なし。**EPEL と同版** |

#### 未確認事項

- 実機での本実行（本書は実機に適用していない。検証はコンテナのみ）
- 端末での実際の描画（グラフ、色、レイアウト、テーマの見え方）
- キー操作（メニュー、プロセスの絞り込み、シグナル送信）
- `-t` / `--force-utf` / `-l` の効果
- `-p`（プリセット）と `btop.conf` の書き換え
- `sudo btop` で他ユーザーのプロセスがどこまで見えるか
- Raspberry Pi 5 での CPU 温度・周波数の表示
- ロールバック（`dnf remove btop` と `~/.config/btop` の削除）の本実行
