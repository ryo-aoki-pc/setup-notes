# btop インストール手順（AlmaLinux 10 / EPEL）

## 実施手順

> [!IMPORTANT]
> - **すべて対象ホスト上で実行する**
> - **手順 3 には対話入力がある**（トランザクション表の `[y/N]` と鍵の確認）。そのブロックだけ続けて貼らない
> - **手順 4 で TUI が開く**。`q` で終了してから次のブロックを貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 設定を書く場所は[設定ファイル](#設定ファイル)、以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **コンテナでのみ検証した手順書**で、実機では本実行していない（[対象と検証環境](#対象と検証環境)）。

1. **変数を設定する**

   - **編集するものは無い**。btop が設定とテーマを置く場所を変数にしてあるだけで、既定の場所そのまま
   - **新しいシェルを開いたら**、先にこのブロックを貼り直す

   ```bash
   BTOP_CONFIG=~/.config/btop      # btop.conf とユーザーテーマの置き場所。既定。<BTOP_CONFIG>
   printf 'BTOP_CONFIG = %s\n' "${BTOP_CONFIG}"
   ```

   <details>
   <summary>補足: 変数について</summary>

   `${BTOP_CONFIG}` は**この文書の中だけで使うシェル変数**で、btop 自身が読む環境変数ではない。別の場所に置きたいときは起動時に `btop -c <ファイル>` を渡す。

   </details>

1. **EPEL を有効にする**

   まず有効になっているか見る。`epel` の行が出れば手順 3 へ飛ぶ。

   ```bash
   dnf repolist enabled | grep -E '^epel' || echo 'EPEL は未設定'
   ```

   無ければ入れる。AlmaLinux の `extras` リポジトリに入っているので、追加のリポジトリ設定は要らない。

   ```bash
   sudo dnf install -y epel-release
   ```

   `sudo` のパスワードを聞かれることがある。**次のブロックは、それに答えてから貼る**（続けて貼ると答えとして食われる）。

   ```bash
   rpm -q epel-release
   dnf repolist enabled | grep -E '^epel'
   ```

   - `epel-release` の版と、`epel` の行が出れば有効になっている
   - インストールの最後に「CRB を有効にすることを推奨」というメッセージが出る。btop には CRB は要らない
   - 他の EPEL パッケージのために CRB を有効にしておくなら、`sudo /usr/bin/crb enable`

   <details>
   <summary>補足: EPEL の鍵はローカルファイルから入る</summary>

   EPEL は AlmaLinux の `extras` リポジトリにある `epel-release` パッケージを入れるだけで有効になる。**[gh.md](gh.md) や [firefox.md](firefox.md) のように、公開鍵を HTTPS で取りに行く手順は要らない。**

   `epel-release` が `/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10` を置き、そのローカルファイルから取り込まれる。コンテナでの実測（手順 3 の `dnf install btop` の途中）:

   ```
   Extra Packages for Enterprise Linux 10 - aarch6 1.6 MB/s | 1.6 kB     00:00
   Importing GPG key 0xE37ED158:
    Userid     : "Fedora (epel10) <epel@fedoraproject.org>"
    Fingerprint: 7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158
    From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10
   Key imported successfully
   ```

   `epel-release` の導入時には、弱い依存として `dnf-plugins-core` も一緒に入る。最後に scriptlet がこのメッセージを出す:

   ```
   Many EPEL packages require the CodeReady Builder (CRB) repository.
   It is recommended that you run /usr/bin/crb enable to enable the CRB repository.
   ```

   btop は CRB を使わないので、この手順では有効化していない（実機ではもともと CRB が有効）。

   なお、コンテナに入った `epel-release` は `10-6.el10`（extras 版）で、実機の `10-8.el10_2` より古い。**一度 EPEL が有効になれば `dnf upgrade` で EPEL 自身の新しい `epel-release` に上がる**ので、差は放っておいてよい。

   </details>

1. **btop を入れる**

   入手できる版を先に見る。

   ```bash
   dnf -q list --showduplicates btop
   ```

   `btop.aarch64  1.4.7-1.el10_2  epel` のように 1 つだけ出る。入れる:

   ```bash
   sudo dnf install btop
   ```

   - 依存として `hicolor-icon-theme`（デスクトップエントリのアイコン用）が一緒に入る

   **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる。** fingerprint が次の値であることを目で確かめてから `y` と答え、違っていれば `N` で中断する。

   - `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）

   トランザクション表の `[y/N]` と鍵の確認に答えるまで終わらないので、**次のブロックはそれから貼る**。

1. **検証する**

   ```bash
   btop --version
   command -v btop
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' btop
   ```

   `btop version: 1.4.7` と `/usr/bin/btop` が出る。次に起動して確認する。

   ```bash
   btop
   ```

   画面が出たら **`q` で終了する。次のブロックは終了してから貼る**（続けて貼ると btop への操作として食われる）。

   初回の起動時に `${BTOP_CONFIG}/btop.conf` が作られるので、作られたか見る:

   ```bash
   ls -l "${BTOP_CONFIG:?手順 1 の BTOP_CONFIG が空のまま。値を入れて貼り直す}"
   ```

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

`${BTOP_CONFIG}/btop.conf` は**初回起動時に既定値で作られる**（約 9.8 KB、項目ごとにコメント付き）。起動せずに既定値だけ見たいなら:

```bash
btop --default-config | head -20
```

アプリ内では `Esc` または `m` でメニューが開き、`Options` からほとんどの項目を GUI で変えられる（保存も btop がやる）。

テーマは 2 か所から読む:

| 置き場所 | 中身 |
|---|---|
| `/usr/share/btop/themes/` | RPM が入れる既定のテーマ（`dracula` / `nord` / `gruvbox-*` / `adwaita-dark` など） |
| `${BTOP_CONFIG}/themes/` | 自分で足すテーマ |

- `btop.conf` の `color_theme` にファイル名を書くと切り替わる
- `"Default"` と `"TTY"` は組み込み

よく使う起動オプション（`btop --help` の全文より抜粋）:

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

---

## 更新

btop は通常の更新に含まれる。

```bash
sudo dnf upgrade btop
```

- システム全体なら `sudo dnf upgrade`
- EPEL が新しい版を出すまでは上がらない（[注意点](#注意点)）

---

## ロールバック

```bash
sudo dnf remove btop
```

トランザクション表を見て `[y/N]` に答えてから、次のブロックを貼る。

```bash
rm -rf ~/.config/btop        # 設定とユーザーテーマも消す場合
```

- 依存で入った `hicolor-icon-theme` は他のパッケージも使うので、残しておいてよい（不要なものだけ消すなら `sudo dnf autoremove`）
- **EPEL 自体は消さない**（他のパッケージが依存している可能性がある）。消すなら `sudo dnf remove epel-release`
- 本書ではロールバックは**本実行していない**

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [btop](https://github.com/aristocratos/btop)（CPU・メモリ・ディスク・ネットワーク・プロセスをまとめて見る TUI。`htop` の後継的な位置づけ）を入れる
- **進め方**: **Homebrew ではなく EPEL の dnf で入れる**。同じ版が両方にあるため（[選択した方針](#選択した方針)）。読者が編集する変数は無い
- **状態**: **コンテナでのみ検証済み（2026-09-22）。実機には入れていない**
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**手順 2〜4（EPEL の有効化を含む）を通した
  - 確認したこと: `epel-release` が `extras` から入る、`btop 1.4.7-1.el10_2` が EPEL から解決される、署名鍵の fingerprint が本文の値と一致する、pty を与えた起動で `btop.conf` が生成される
  - **確認していないこと**: 画面の描画内容・操作・テーマの見え方。コンテナには本物の端末が無いため
  - **実機（Raspberry Pi 5）では本実行していない**ので、下表の実機列は「この手順を適用した結果」ではなく**現時点の状態**を書いてある

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| EPEL | **有効**（`epel-release 10-8.el10_2`。手順 2 は不要） | 未設定 → 手順 2 で `epel-release 10-6.el10` を導入 |
| 有効なリポジトリ | baseos / appstream / crb / extras / epel / raspberrypi ほか | baseos / appstream / crb / extras（→ epel を追加） |
| btop | **未導入** | `btop 1.4.7-1.el10_2`（epel） |
| 一緒に入る依存 | — | `hicolor-icon-theme 0.17-20.el10`（appstream） |
| 端末 | WezTerm nightly（[wezterm-nightly.md](wezterm-nightly.md)） | 無し（`script` で pty を与えた起動のみ） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${BTOP_CONFIG}` | `btop.conf` とユーザーテーマの置き場所 | `~/.config/btop`（既定） |
>
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

**この文書だけ Homebrew を使わないのは、EPEL 版が upstream に追いついているため。**

- 既存の [yazi](yazi.md) / [lazygit](lazygit.md) / [neovim](neovim.md) / [zoxide](zoxide.md) / [bat](bat.md) / [eza](eza.md) / [git-delta](git-delta.md) / [gdu](gdu.md) は、EPEL に無いか古いので Homebrew を選んでいる
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
- **設定は初回起動まで作られない**: [手順 4 の補足](#実施手順)
- **`htop` とは別物**: 同時に入れても衝突しない

### 参照

- [aristocratos/btop — README](https://github.com/aristocratos/btop) — 機能、キーバインド、設定項目、テーマの書式
- [EPEL — Fedora Project Wiki](https://docs.fedoraproject.org/en-US/epel/) — `epel-release` の入れ方と CRB が要る理由
- `btop --help` / `btop --default-config` — 起動オプションと既定の設定
- `man btop` — RPM に同梱

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で手順 2〜4 を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、`dnf install` に `-y` を付け、起動の 1 行だけ `timeout 5 script -qec "btop" /dev/null` に置き換えている。

| 手順 | 結果 |
|---|---|
| 2. EPEL | 導入前の `dnf repolist enabled` は baseos / appstream / crb / extras の 4 つで、`dnf list --available btop` は `Error: No matching Packages to list`。`dnf install -y epel-release` で `epel-release-10-6.el10`（extras）と弱い依存の `dnf-plugins-core-4.7.0-10.el10`（baseos）が入り、`epel` が有効になった |
| 3. btop | `dnf -q list --showduplicates btop` → `1.4.7-1.el10_2 epel` の 1 行だけ。`dnf install` で EPEL の鍵（`0xE37ED158`、fingerprint は本文のとおり）を `/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10` から取り込み、`btop` と `hicolor-icon-theme` の 2 つを導入（597 KB / 展開後 1.4 MB） |
| 4. 検証 | `btop --version` → `1.4.7`、`GPU_SUPPORT=false`。`command -v btop` → `/usr/bin/btop`。`repoquery --installed` の `from_repo` が `epel` |
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
