# Visual Studio Code インストール手順（AlmaLinux 10 / Microsoft 公式 dnf リポジトリ）

## 実施手順

**すべて対象ホスト上で実行する。** 手順 5 の GUI 起動だけデスクトップが要る。手順 0 で変数を設定したシェルで、上から順にコードブロックを貼る。理由・実測出力・落とし穴は[補足](#補足)にまとめてあり、実行するだけなら読まなくてよい。

| 手順 | 内容 |
|---|---|
| [0. 変数を設定する](#0-変数を設定する) | 入れるチャンネルを決める（編集不要） |
| [1. 署名鍵を確かめて取り込む](#1-署名鍵を確かめて取り込む) | fingerprint を目で照合してから `rpm --import` |
| [2. リポジトリを追加する](#2-リポジトリを追加する) | `/etc/yum.repos.d/vscode.repo` を書く |
| [3. インストールする](#3-インストールする) | `dnf install code`（**318 MB / 展開後 953 MB**） |
| [4. 検証する](#4-検証する) | 版・提供元・ライブラリの解決 |
| [5. GUI を起動する](#5-gui-を起動する) | デスクトップの端末から `code` |

拡張機能は[拡張機能を入れる（任意）](#拡張機能を入れる任意)。以後の更新は[更新](#更新)、戻すときは[ロールバック](#ロールバック)。

### 0. 変数を設定する

**編集するものは無い。** 安定版を入れる。毎日更新される Insiders 版を使うときだけ `code-insiders` にする（併存できる）。新しいシェルを開いたら先にこのブロックを貼り直す。

```bash
VSC_PKG=code                    # 入れるチャンネル。code（安定版）/ code-insiders。固定。<VSC_PKG>
echo "${VSC_PKG}"
```

→ [補足](#手順-0-変数について)

### 1. 署名鍵を確かめて取り込む

まず鍵を落として、**取り込む前に** fingerprint を見る。

```bash
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc -o /tmp/microsoft.asc
gpg --show-keys --with-fingerprint /tmp/microsoft.asc
```

次の値と一致することを目で確かめる。違っていればここで止める。

- fingerprint `BC52 8686 B50D 79E3 39D3 721C EB3E 94AD BE12 29CF`
- uid `Microsoft (Release signing) <gpgsecurity@microsoft.com>`

一致したら取り込む。

```bash
sudo rpm --import /tmp/microsoft.asc
```

`sudo` のパスワードを聞かれることがある。**次のブロックは、それに答えてから貼る**（続けて貼ると答えとして食われる）。

```bash
rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i microsoft
rm -f /tmp/microsoft.asc
```

`gpg-pubkey-be1229cf-5631588c Microsoft (Release signing) ...` が出れば入っている。

→ [補足](#手順-1-鍵を先に入れる理由)

### 2. リポジトリを追加する

```bash
sudo tee /etc/yum.repos.d/vscode.repo >/dev/null <<'EOF'
[vscode]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
cat /etc/yum.repos.d/vscode.repo
```

ヒアドキュメントは `<<'EOF'`（クォート付き）。この中に展開したい変数は無い。

### 3. インストールする

先に何が入るかだけ見る（`--assumeno` は必ず中断する）。

```bash
sudo dnf install --assumeno "${VSC_PKG:?手順 0 の VSC_PKG が空のまま。値を入れて貼り直す}"
```

`code ... 318 M` と `Installed size: 953 M` が出る。よければ入れる。

```bash
sudo dnf install "${VSC_PKG}"
```

トランザクション表を見て `[y/N]` に答えてから、次のブロックを貼る。**318 MB のダウンロードと 953 MB の展開があるので数分かかる**（実測では 1 分 14 秒）。弱い依存として `socat` が一緒に入る。

→ [補足](#手順-3-318-mb-と-post-の中身)

### 4. 検証する

```bash
code --version
dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' "${VSC_PKG}"
rpm -qi "${VSC_PKG}" | sed -n '/^Vendor/p;/^Build Date/p'
ldd /usr/share/code/code | grep -c 'not found'
ls /usr/share/applications/code*.desktop
```

`1.138.0` / コミットハッシュ / `arm64` の 3 行が出て、`from_repo` が `vscode`、`Vendor` が `Microsoft Corporation` になる。**`ldd` の `not found` が `0`** なら、必要な共有ライブラリがすべて EL10 側で解決できている。

→ [補足](#手順-4-el8-タグの-rpm-が-el10-で解決できる理由)

### 5. GUI を起動する

**デスクトップにログインした端末から**実行する。アプリ一覧の「Visual Studio Code」からでも同じ。

```bash
code
```

ウィンドウが開き、初回は Welcome タブが出る。**次のブロックは、ウィンドウを閉じてから貼る**（続けて貼ると VS Code への操作として食われる）。

```bash
ls -d ~/.config/Code ~/.vscode
code --list-extensions
```

初回起動で `~/.config/Code`（設定と履歴）ができる。`~/.vscode` は起動を試みた時点で `argv.json` だけ作られる。拡張を入れていなければ `code --list-extensions` は何も返さない。

**この手順は実機で確認した**（2026-09-23、gnome-remote-desktop の RDP セッションのデスクトップから）。`~/.config/Code` が作られ、`logs/<日時>/main.log` に正常な起動が記録された。

> **一方、TTY もディスプレイも無いシェルから起動することはできなかった。** ssh や自動化から `env -i` でセッションの値を渡す方法を 6 通り試したが、いずれも子プロセスが立つだけでウィンドウもログも出なかった。**この手順はデスクトップの端末から実行すること。** 試した内容は[付録: 実機での GUI 起動試験](#付録-実機での-gui-起動試験2026-09-23)に残してある。

---

## 拡張機能を入れる（任意）

CLI から入れられる。入っているものの一覧:

```bash
code --list-extensions --show-versions
```

入れるときは `code --install-extension <publisher.name>` の形で ID を渡す。たとえば [ShellCheck](shellcheck.md) をエディタから使うなら `timonwong.shellcheck`、消すときは `code --uninstall-extension <publisher.name>`。

**本書では拡張機能を 1 つも入れていない**（[未確認事項](#未確認事項)）。Settings Sync・Remote-SSH・Marketplace の利用条件は扱わない。

---

## 更新

VS Code は通常の更新に含まれる。

```bash
sudo dnf upgrade "${VSC_PKG}"
```

システム全体なら `sudo dnf upgrade`。**rpm 版では VS Code 内蔵のアップデータは使わない**（dnf が管理しているため。[firefox.md](firefox.md) と同じ論点）。

---

## ロールバック

```bash
sudo dnf remove "${VSC_PKG}"
```

トランザクション表を見て `[y/N]` に答えてから、次のブロックを貼る。

```bash
sudo rm -f /etc/yum.repos.d/vscode.repo
rm -rf ~/.config/Code ~/.vscode      # 設定・履歴・拡張機能も消す場合
```

Microsoft の署名鍵は `gpg-pubkey-be1229cf-5631588c` として残る（`rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n'` で確認できる）。消すなら `sudo rpm -e gpg-pubkey-be1229cf-5631588c`。**ほかに Microsoft のリポジトリを使っていないことを確かめてから**にする。弱い依存で入った `socat` は他でも使うので残してよい。

本書ではロールバックは**本実行していない**。

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に [Visual Studio Code](https://code.visualstudio.com/) を Microsoft 公式の dnf リポジトリから入れる。**aarch64 のパッケージが公式に用意されている**
- **進め方**: 鍵を照合して取り込み、repo ファイルを置いて `dnf install`。**読者が書き換える変数は無い**
- **状態**: **実機で本実行済み（2026-09-23）。GUI の起動まで確認した。** 下表のホストに公式リポジトリを足して `dnf install code` し、`code-1.138.0-1789458729.el8.aarch64` が入った（318 MB / 展開後 953 MB、所要 1 分 14 秒）。`code --version` が `1.138.0` / `arm64` を返し、`ldd /usr/share/code/code` の未解決ライブラリが 0 であることまで確認した。**[手順 5](#5-gui-を起動する) のウィンドウ起動も実機で確認した**: gnome-remote-desktop の RDP セッションのデスクトップから `code` を起動してウィンドウが開き、`~/.config/Code` と `logs/<日時>/main.log` が作られた。**ただし TTY もディスプレイも無いシェルからの起動は 6 通り試して 1 つも成功していない**（[付録](#付録-実機での-gui-起動試験2026-09-23)）。**VS Code は実機に入れたまま残してある。** 手順 1〜3 は同じ日に同じ OS のコンテナで `--assumeno` まで通し、鍵の fingerprint・repo の追加・依存解決を確認した。**コンテナでは本実行していない**（GUI が無く、318 MB の取得に見合わないため）。**拡張機能・`code-insiders`・Wayland ネイティブでの常用は未検証**

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-23 | 2026-09-23 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| デスクトップ | GNOME Shell 49.4 / Wayland（gnome-remote-desktop 経由の RDP セッション） | 無し |
| 入った VS Code | `code-1.138.0-1789458729.el8.aarch64`（318 MB / 展開後 953 MB） | **入れていない**（`--assumeno` で解決だけ確認） |
| 弱い依存 | `socat 1.7.4.4-8.el10`（appstream） | 同じ解決結果 |
| GUI 起動 | **デスクトップの端末からは成功**。TTY の無いシェルからは 6 通りとも失敗（[付録](#付録-実機での-gui-起動試験2026-09-23)） | 不可（GUI が無い） |
| SELinux | Enforcing | — |

> **注記**: 環境固有の値は**シェル変数**で書いてある。[手順 0](#0-変数を設定する) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${VSC_PKG}` | 入れるパッケージ名 = チャンネル | `code`（既定）/ `code-insiders` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`1.138.0`）は実行日によって変わる。**鍵の fingerprint は公開情報なので本文に書いてある。**

手順の理由・実測・落とし穴・検証記録。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| VS Code | 未導入（`rpm -q code` が `not installed`、`code` コマンドも無い） |
| `/etc/yum.repos.d/vscode.repo` | 無し |
| Microsoft の署名鍵 | 未取り込み |
| `~/.config/Code` / `~/.vscode` | **どちらも無い** |
| ディスクの空き | 49 GB（`/`、117 GB 中 69 GB 使用） |
| デスクトップ | GNOME Shell 49.4。`loginctl` の session 20 が `Type=wayland` `Active=yes` `Remote=yes`（RDP ログイン）、`/run/user/1000/wayland-0` あり |
| 既存の GUI アプリ | `firefox 156.0`（[firefox.md](firefox.md)）、`wezterm`（[wezterm-nightly.md](wezterm-nightly.md)） |

### 選択した方針

AlmaLinux 10 aarch64 で VS Code を入れる経路を比べた（2026-09-23 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Microsoft 公式 dnf リポジトリ** | `packages.microsoft.com/yumrepos/vscode` に **aarch64 が 276 パッケージ**（`code` / `code-insiders` / `code-exploration`）。安定版は `code 1.138.0`。dnf で更新できる | **採用** |
| 公式サイトの `.rpm` を直接 `dnf install` | 同じバイナリだが、更新のたびに手で落とすことになる | 不採用 |
| Flathub `com.visualstudio.code` | このホストは flatpak にリモートが**1 つも登録されていない**（[firefox.md](firefox.md) と同じ状況）。追加と runtime の導入から始まり、サンドボックスで PATH やツールチェインの見え方が変わる | 不採用（RPM で足りる） |
| Snap | EL10 に snapd を入れることになる | 不採用 |
| VSCodium / `code-oss` | Marketplace と一部の拡張（Remote-SSH など）が使えない | 対象外（本書は Microsoft のビルドを入れる） |
| `code-insiders` | 同じリポジトリの別パッケージ。コマンド名も設定ディレクトリも別なので安定版と併存できる | [手順 0](#0-変数を設定する) で選べるようにしてあるが**未検証** |

### 手順の補足

#### 手順 0: 変数について

`${VSC_PKG}` は**パッケージ名がそのままチャンネル名**になっている。`code-insiders` は `code` と同時に入れられ、コマンドは `code-insiders`、設定は `~/.config/Code - Insiders` と別になる。`code-exploration` も同じリポジトリにあるが本書では扱わない。

#### 手順 1: 鍵を先に入れる理由

Microsoft の公式手順が「鍵 → repo」の順で、**318 MB を落とし終えた後に鍵の取り込みプロンプトで止まらずに済む**。`gpg --show-keys` は**キーリングに取り込まずに** fingerprint を表示するので、照合してから `rpm --import` できる（[gh.md](gh.md) の「`dnf install` の途中で照合する」形より一歩早い）。実測:

```
$ gpg --show-keys --with-fingerprint /tmp/microsoft.asc
pub   rsa2048 2015-10-28 [SC]
      BC52 8686 B50D 79E3 39D3  721C EB3E 94AD BE12 29CF
uid                      Microsoft (Release signing) <gpgsecurity@microsoft.com>
```

Microsoft の鍵は**この 1 本だけ**（[gh.md](gh.md) の GitHub CLI は 2 本ある）。

#### 手順 3: 318 MB と `%post` の中身

`--assumeno` で見える解決結果:

```
Installing:
 code        aarch64       1.138.0-1789458729.el8         vscode          318 M
Installing weak dependencies:
 socat       aarch64       1.7.4.4-8.el10                 appstream       301 k

Transaction Summary
Install  2 Packages
Total download size: 319 M
Installed size: 953 M
```

`socat` は弱い依存で、Remote 系の機能がトンネルを張るときに使う。本体以外の依存は 1 つも無い（GTK3 / NSS などはデスクトップ環境のぶんで既に入っている）。

**`%post` はリポジトリファイルを書かない。** 他所の手順では「rpm が勝手に `code.repo` を作る」と書かれていることがあるが、現在の rpm ではその処理が**コメントアウトされている**。実測:

```
$ rpm -q --scripts code
postinstall scriptlet (using /bin/sh):
# Remove the legacy bin command if this is the stable build
if [ "code" = "code" ]; then
	rm -f /usr/local/bin/code
fi

# Register yum repository
# TODO: #229: Enable once the yum repository is signed
#if [ "code" != "code-oss" ]; then
#	if [ -d "/etc/yum.repos.d" ]; then
#		REPO_FILE=/etc/yum.repos.d/code.repo
...
# Install the desktop entry
update-desktop-database &> /dev/null || :
update-mime-database /usr/share/mime &> /dev/null || :
```

手順 2 で書いた `/etc/yum.repos.d/vscode.repo` は、インストールの前後で **md5 も mtime も変わらなかった**。`/etc/yum.repos.d/` に別名のファイルも増えていない。実際にやるのは「古い `/usr/local/bin/code` の削除」と「デスクトップエントリと MIME の登録」だけ。

#### 手順 4: `.el8` タグの rpm が EL10 で解決できる理由

入る rpm は `code-1.138.0-1789458729.el8.aarch64` で、release の末尾が **`.el8` に固定されている**。これは「EL8 用のビルドを EL10 に流用している」のではなく、**Microsoft が EL 共通の rpm を 1 本だけ出している**ためで、EL9 / EL10 向けの別ビルドは存在しない。`baseurl` も `yumrepos/vscode` の 1 つだけでディストリ非依存になっている。

根拠は依存の下限。aarch64 向けに要求される glibc のうち最も新しいものが **2.28（EL8 の版）**で、EL10 の 2.39 が余裕で満たす:

```
$ dnf -q repoquery --requires code | grep -E 'GLIBC_2\.[0-9]+' | grep -v 'x86\|armhf' | sort -u
libc.so.6(GLIBC_2.17)(64bit)
libc.so.6(GLIBC_2.25)(64bit)
libc.so.6(GLIBC_2.28)(64bit)
$ ldd /usr/share/code/code | grep -c 'not found'
0
```

つまり **EL8 を最低ラインにして EL8 / EL9 / EL10 を 1 本でカバーする**作りで、Microsoft の公式ドキュメントも RHEL / CentOS / Fedora のすべてでこの同じリポジトリを案内している。[WezTerm](wezterm-nightly.md) の「作者が EL9 向けに出した COPR ビルドを EL10 で使う」とは事情が違う。dnf は release 文字列を比較するだけなので、`.el8` のままでも `dnf upgrade` は正しく効く。

#### 手順 5: `~/.config/code-flags.conf` は読まれない

Electron アプリに恒久的なフラグを渡す方法として `~/.config/code-flags.conf` を案内している記事があるが、**あれは Arch Linux のパッケージが持つラッパーの仕組みで、Microsoft の rpm には無い**。実測:

```
$ ls -l /usr/bin/code
lrwxrwxrwx. 1 root root 24 Sep 15 07:52 /usr/bin/code -> /usr/share/code/bin/code
$ grep -n 'flags.conf' /usr/bin/code /usr/share/code/bin/code
（何も出ない）
```

`/usr/share/code/bin/code` は POSIX sh のラッパーで、やっているのは ① リモート端末なら `remote-cli` に渡す ② WSL に入れていないか確認する ③ root なら `--user-data-dir` の指定を要求する、の 3 つだけ。フラグを恒久化したいなら次のどちらかになる:

- `~/.config/environment.d/` に `ELECTRON_OZONE_PLATFORM_HINT=auto` を置く（アプリ一覧から起動したときにも効く）
- `/usr/share/applications/code.desktop` を `~/.local/share/applications/` に複製して `Exec=` を書き換える（rpm の更新で消えない）

**デスクトップエントリは `/usr/bin/code` を経由しない**（`Exec=/usr/share/code/code %F`）点にも注意する。どちらの方法も本書では試していない（[未確認事項](#未確認事項)）。

### 完了時点の状態

**実機での出力**（GUI は起動していない）:

```
$ code --version
1.138.0
7debcd0e2acdea1c52de81bf9ee1620444407dda
arm64
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' code
code 1.138.0-1789458729.el8 vscode
$ command -v code
/usr/bin/code
$ rpm -qi code | sed -n '/^Vendor/p;/^Build Date/p'
Build Date  : Tue Sep 15 07:52:13 2026
Vendor      : Microsoft Corporation
$ rpm -ql code | wc -l
3049
$ du -sh /usr/share/code
961M	/usr/share/code
$ ldd /usr/share/code/code | grep -c 'not found'
0
$ ls /usr/share/applications/code*.desktop
/usr/share/applications/code-url-handler.desktop
/usr/share/applications/code.desktop
```

デスクトップから起動した後は `~/.config/Code` も作られている:

```
$ stat -c '%y' ~/.config/Code
2026-09-23 07:15:49
$ ls ~/.config/Code/logs
20260923T071413
20260923T071537
$ ls ~/.vscode
argv.json  extensions
$ code --list-extensions
（何も出ない。拡張は入れていない）
```

### 注意点

- **`.el8` のタグに驚かなくてよい**: Microsoft が EL 共通に 1 本だけ出している rpm で、EL10 向けの別ビルドは存在しない。`rpm -qi` の `Vendor` が `Microsoft Corporation` であることを確かめれば十分（[手順 4 の補足](#手順-4-el8-タグの-rpm-が-el10-で解決できる理由)）
- **`~/.config/code-flags.conf` は効かない**: Microsoft の rpm のラッパーは読まない（[手順 5 の補足](#手順-5-configcode-flagsconf-は読まれない)）
- **大きい**: ダウンロード 318 MB、展開後 953 MB。Raspberry Pi の microSD では取得にも展開にも時間がかかる。`sudo dnf clean packages` でキャッシュを消せる
- **内蔵のアップデータは使わない**: rpm 版は dnf が管理する。VS Code が更新を促してきても `sudo dnf upgrade code` で上げる
- **`code-insiders` と併存できる**: コマンド名も設定ディレクトリ（`~/.config/Code - Insiders`）も別。ただし本書では未検証
- **Electron なので X11 のライブラリを要求する**: `libX11` / `libXcomposite` などが rpm の requires に並ぶ。これは XWayland 経由でも動くようにするためで、**ライブラリが入っていることは「X11 で動いている」ことを意味しない**
- **root では起動できない**: ラッパーが `--user-data-dir` の指定を要求する。そもそも root で使うものではない
- **TTY もディスプレイも無いシェルからは GUI を起動できなかった**: デスクトップの端末からは起動するが、ssh や自動化から `env -i` でセッションの値を渡す方法は 6 通り試して 1 つも成功しなかった（[付録](#付録-実機での-gui-起動試験2026-09-23)）。原因は特定できていない

### 参照

- [Visual Studio Code on Linux](https://code.visualstudio.com/docs/setup/linux) — 公式のインストール手順（RHEL / CentOS / Fedora の節がこのリポジトリを案内している）
- [packages.microsoft.com/yumrepos/vscode](https://packages.microsoft.com/yumrepos/vscode/) — リポジトリの中身
- [VS Code — Command Line Interface](https://code.visualstudio.com/docs/editor/command-line) — `--list-extensions` / `--install-extension` / `--user-data-dir`
- [Electron — Ozone platform](https://www.electronjs.org/docs/latest/api/environment-variables) — `ELECTRON_OZONE_PLATFORM_HINT`
- `code --help` / `rpm -q --scripts code` — CLI のオプションと rpm のスクリプトレット

---

### 付録: 実機での GUI 起動試験（2026-09-23）

**結論から書くと、デスクトップの端末からは起動でき、TTY もディスプレイも無いシェルからは 6 通り試して 1 つも起動できなかった。**

うまくいったほう（デスクトップの端末で `code`）の証跡:

```
$ stat -c '%y' ~/.config/Code
2026-09-23 07:15:49
$ ls -d ~/.config/Code/logs/*
/home/<USER>/.config/Code/logs/20260923T071413
/home/<USER>/.config/Code/logs/20260923T071537
$ head -3 ~/.config/Code/logs/20260923T071537/main.log
2026-09-23 07:14:14.067 [info] StorageMainService: creating application shared storage
2026-09-23 07:14:14.910 [info] [shared storage] Creating shared storage database at ...
2026-09-23 07:14:16.834 [info] update#setState idle
```

`~/.config/Code/GPUCache/` も作られているので、GPU プロセスは動いている。**ただしログに表示バックエンドは記録されないので、Wayland ネイティブか XWayland 経由かはこれでは分からない**（[未確認事項](#未確認事項)）。

以下は**うまくいかなかったほう**の記録。この文書を書いているシェルには TTY もディスプレイも無いため、[wezterm-nightly.md の付録](wezterm-nightly.md#付録-appimage-の実測)と同じく `env -i` で環境を空にしてから、稼働中のセッション（`loginctl` の session 20、`Type=wayland` `Active=yes` `Remote=yes`、`/run/user/1000/wayland-0` あり、gnome-shell の pid 5615）の値を渡して起動を試みた。**設定を汚さないよう、毎回 `mktemp -d` の下に `--user-data-dir` と `--extensions-dir` を置いている。**

| # | 渡したもの | 待った時間 | 結果 |
|---|---|---|---|
| 1 | 既定（`WAYLAND_DISPLAY=wayland-0` のみ） | 60 秒 | 子プロセス（`--type=zygote` 3 つ）は立つ。`--user-data-dir` は**空のまま**、標準出力・標準エラーとも **0 バイト** |
| 2 | `--ozone-platform=wayland` | 25 秒 | 同上。`ss -xp` に `code` のソケットは現れるが `wayland-0` にも `/tmp/.X11-unix/X*` にも繋いでいない |
| 3 | `DISPLAY=:0` を追加（`/tmp/.X11-unix/X0` はこのユーザーの所有） | 45 秒 | 同上 |
| 4 | `--no-sandbox` | 30 秒 | 同上 |
| 5 | `--disable-gpu`（`~/.vscode/argv.json` が案内している回避策） | 60 秒 | 同上 |
| 6 | 既定のまま長く待つ | **180 秒** | 10 秒ごとに見たが、`logs` ディレクトリは最後まで作られず、出力も 0 バイトのまま |

分かったこと:

- **CLI は正常に動く**（`code --version` が即座に返る）。壊れているのは GUI の起動経路だけ
- プロセスは立ち上がって zygote まで進むが、**ログを 1 バイトも書かない**ため原因が追えない
- `gdbus` で GNOME Shell にウィンドウ一覧を問い合わせる方法（`org.gnome.Shell.Eval`）は、最近の GNOME では既定で無効化されていて `(false, '')` しか返らず、確認に使えなかった
- 動いている Xwayland（pid 1295、`:1024`）は **gdm（uid 42）のもの**で、このユーザーのセッションのものではない

**同じホスト・同じセッションでも、デスクトップの端末から `code` と打てば起動する。** 失敗しているのは「TTY もディスプレイも無いシェルから `env -i` でウィンドウを出す」経路だけで、VS Code そのものの問題ではない。原因は特定できていない（[未確認事項](#未確認事項)）。**自動化やリモートから GUI を上げたい場合は、この方法は当てにしないこと。**

失敗した試行では毎回 `kill -TERM -<プロセスグループ>` → `kill -KILL` で終了させ、一時ディレクトリを消し、`code` のプロセスが 0 件であること・`~/.config/Code` が作られていないこと・GNOME のセッションが `Active=yes` のままであることを確認している（`~/.config/Code` はその後、デスクトップからの起動で作られた）。

---

### 付録: コンテナでの依存解決の確認（2026-09-23）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で手順 1〜3 を `--assumeno` まで通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 **本実行はしていない**: コンテナには GUI が無いのでこの文書の中核（ウィンドウの起動）を確かめられず、318 MB の取得と 953 MB の展開に見合わないため。

| 手順 | 結果 |
|---|---|
| 1. 鍵 | `gpg --show-keys` の fingerprint が本文の値と一致。`rpm --import` 後に `gpg-pubkey-be1229cf-5631588c` を確認 |
| 2. repo | `/etc/yum.repos.d/vscode.repo` を作成。`dnf` がメタデータを取得できた |
| 3. 依存解決 | `dnf install --assumeno code` → **215 パッケージ・442 MB・展開後 1.4 GB**。デスクトップの無いコンテナでは GTK3 / NSS / mesa-dri-drivers / pipewire / xdg-desktop-portal / xkeyboard-config などを全部引いてくる。**実機（GNOME 導入済み）では `code` と弱い依存の `socat` の 2 つだけだった**ので、差の 213 パッケージはデスクトップ環境が既に持っていたぶんになる |
| チャンネル | `dnf -q list --showduplicates code` は `aarch64` / `x86_64` / `armv7hl` の 3 アーキテクチャを返す。`code-insiders 1.139.0` と `code-exploration 1.140.0` の aarch64 も存在する |
| glibc の下限 | `dnf -q repoquery --requires code` の aarch64 向けの最大が `GLIBC_2.28` |

#### 未確認事項

- **TTY もディスプレイも無いシェルから GUI を起動できない原因**（[付録](#付録-実機での-gui-起動試験2026-09-23)の 6 通りはいずれもログを 1 バイトも書かずに止まった）
- **Wayland ネイティブで動くか、XWayland 経由になるか**（起動は確認できたが、VS Code のログに表示バックエンドは記録されない。`ELECTRON_OZONE_PLATFORM_HINT=auto` / `--ozone-platform=wayland` の効果も未確認）
- `~/.config/environment.d/` と `~/.local/share/applications/code.desktop` によるフラグの恒久化
- 拡張機能の導入（`code --install-extension timonwong.shellcheck` など）
- `code-insiders` の併存
- Settings Sync / Remote-SSH / Marketplace の利用
- `dnf upgrade code` による更新（次のリリースが出ていないため未実施）
- ロールバック（`dnf remove code` と repo・鍵の削除）の本実行
