# Flatpak / Flathub 導入手順（AlmaLinux 10）

## 実施手順

> [!IMPORTANT]
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（アプリは `sudo` でシステム全体に入れるが、起動は自分のユーザーで行う）
> - **手順 5 には対話入力がある**（確認が 2 回）。そのブロックだけ続けて貼らない

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: [ツール一覧](tool-catalog.md#gui)の「Flathub」の行にある GUI アプリが入れられるようになる。日々の操作は[使い方の基本](#使い方の基本)、以後は[更新](#更新)・[ロールバック](#ロールバック)
- [Firefox](firefox.md) と [VS Code](vscode.md) は Flathub を使わず RPM で入れている（理由はそれぞれの「選択した方針」）

> [!WARNING]
> **x86_64 のコンテナでのみ検証した手順書**で、実機では本実行しておらず、aarch64 でも通していない。デスクトップのメニュー・アプリの画面・GNOME Software での表示も確かめていない（[対象と検証環境](#対象と検証環境)）。

1. **変数を設定する**

   - **編集するものは無い**。Flathub の登録ファイルの URL は固定
   - 動作確認に入れるアプリは、小さい [Flatseal](https://flathub.org/apps/com.github.tchx84.Flatseal)（Flatpak アプリの権限を GUI で変えるツール。手順 5 の補足）にしてある
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

   ```bash
   FLATHUB_REPO_URL=https://dl.flathub.org/repo/flathub.flatpakrepo   # Flathub の登録ファイル。固定。<FLATHUB_REPO_URL>
   FP_TEST_APP=com.github.tchx84.Flatseal                               # 動作確認に入れるアプリの ID。<FP_TEST_APP>
   for v in FLATHUB_REPO_URL FP_TEST_APP; do printf '%-16s = %s\n' "$v" "${!v}"; done
   ```

   <details>
   <summary>補足: 変数について</summary>

   - どちらも**この文書の中だけで使うシェル変数**で、flatpak が読む環境変数ではない
   - `${FP_TEST_APP}` を別のアプリ ID に変えてもよいが、Flatseal より大きいアプリは runtime と合わせて数百 MB を落とす（[注意点](#注意点)）

   </details>

1. **flatpak を入れる**

   まず入っているか見る。バージョンが出れば、次のブロックは飛ばしてよい。

   ```bash
   rpm -q flatpak || echo 'flatpak は未導入'
   ```

   無ければ AppStream から入れる。

   ```bash
   sudo dnf install -y flatpak
   ```

   `sudo` のパスワードを聞かれることがある。**次のブロックは、それに答えてから貼る**（続けて貼ると答えとして食われる）。

   ```bash
   flatpak --version
   flatpak remotes --show-details
   ```

   - `Flatpak 1.16.0` のように出る
   - **入れた直後は `flatpak remotes` が `error: While opening repository /var/lib/flatpak/repo: ...` を出すが、壊れているわけではない**。リモートがまだ無いだけ（この手順の補足）
   - 何も出ない場合も、リモートが無い状態
   - **`flathub` の行が既にあれば、手順 4 は何もしない**（`--if-not-exists` のため）

   <details>
   <summary>補足: AlmaLinux 10 の flatpak にはリモートが無い</summary>

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

   - サンドボックスの `bubblewrap`、`ostree-libs`、`polkit`、`xdg-desktop-portal`、`gnupg2`（手順 3 で使う `gpg`）などが含まれる
   - デスクトップのあるホストでは依存の多くが既に入っているので、数はこれより少ないはず（未確認）

   GNOME の `gnome-software` パッケージは `flatpak` に依存し、Flatpak 用のプラグイン（`/usr/lib64/gnome-software/plugins-21/libgs_plugin_flatpak.so`）を含む（`dnf repoquery` で確認）。したがって GNOME のデスクトップには flatpak が最初から入っていることが多い（このリポジトリの 2 台とも入っていた。[実施前の状態](#実施前の状態)）。

   </details>

1. **Flathub の鍵を確かめる**

   登録ファイルに埋め込まれた公開鍵の fingerprint を見る。

   ```bash
   curl -fsSL "${FLATHUB_REPO_URL:?手順 1 の FLATHUB_REPO_URL が空のまま。値を入れて貼り直す}" | sed -n 's/^GPGKey=//p' | base64 -d | gpg --show-keys --with-fingerprint
   ```

   次の値と一致することを目で確かめる。違っていれば先へ進まない。

   - `6E5C 05D9 79C7 6DAF 93C0 8135 4184 DD4D 907A 7CAE`（Flathub Repo Signing Key &lt;flathub@flathub.org&gt;、有効期限 2027-06-14）

   <details>
   <summary>補足: 鍵は登録ファイルの中にある</summary>

   `flathub.flatpakrepo` は鍵を**本文に base64 で埋め込んで**いて、`flatpak remote-add` はこの鍵をリモートの設定に取り込む。以後の取得はすべてこの鍵で署名を検証する。したがって、確かめるべきは「登録ファイルの中の鍵が Flathub のものか」の 1 点になる（[VS Code](vscode.md) の手順で rpm の鍵を確かめているのと同じ考え方）。

   `gpg --show-keys` は鍵を**鍵束に取り込まずに表示するだけ**。ただし `~/.gnupg` が無ければ最初の実行で作られる（`gpg: directory '/home/<USER>/.gnupg' created`）。

   </details>

1. **Flathub を追加する**

   ```bash
   sudo flatpak remote-add --if-not-exists flathub "${FLATHUB_REPO_URL:?手順 1 の FLATHUB_REPO_URL が空のまま。値を入れて貼り直す}"
   ```

   ```bash
   flatpak remotes --show-details
   ```

   `flathub` の行が出て、`Options` の列が `system` になっていればよい。

   ```
   Name    Title   URL                          Collection ID Subset Filter Priority Options … … Homepage             Icon
   flathub Flathub https://dl.flathub.org/repo/ -             -      -      1        system  … … https://flathub.org/ https://dl.flathub.org/repo/logo.svg
   ```

   <details>
   <summary>補足: system に入れる理由</summary>

   `sudo` を付けて**システム全体のインストール先**（`/var/lib/flatpak`）に登録している。以後のアプリも同じ場所に入り、ホストの全ユーザーから使える。

   自分のユーザーだけに入れたいなら、`sudo` を外して `--user` を付ける（`flatpak remote-add --user --if-not-exists flathub ...`）。

   - この場合の置き場所は `~/.local/share/flatpak` で、以降の `install` / `update` / `uninstall` にも `--user` を付ける
   - **system と user に同じアプリを入れると、どちらが起動されるか分かりにくくなる**ので、どちらかに揃える
   - 本書は system だけを検証している

   </details>

1. **確認用のアプリを入れる**

   ```bash
   sudo flatpak install flathub "${FP_TEST_APP:?手順 1 の FP_TEST_APP が空のまま。値を入れて貼り直す}"
   ```

   **確認を 2 回聞かれる。** どちらも `y` で進める。

   - 1 回目: runtime を入れるか（`Do you want to install it? [Y/n]`）
   - 2 回目: アプリの権限と入れるものの一覧を見せたうえでの最終確認（`Proceed with these changes to the system installation? [Y/n]`）

   **次のブロックは、完了してから貼る。**

   <details>
   <summary>補足: 一緒に入る runtime</summary>

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

   同じ runtime を使うアプリを 2 本目以降に入れるときは、runtime の取得は起きない。[ツール一覧](tool-catalog.md#gui)の Flathub の行には、アプリごとの runtime（GNOME 50 / FDO 25.08 / FDO 26.08）を書いてある。

   </details>

1. **検証する**

   ```bash
   flatpak list --app --columns=application,version,branch,installation
   flatpak info "${FP_TEST_APP:?手順 1 の FP_TEST_APP が空のまま。値を入れて貼り直す}"
   flatpak run --command=true "${FP_TEST_APP}" && echo 'sandbox OK'
   ls /var/lib/flatpak/exports/share/applications/
   ```

   - `flatpak list` に `com.github.tchx84.Flatseal  2.4.1  stable  system` のように出る
   - `sandbox OK` が出れば、アプリのサンドボックスが起動できている
   - 最後の行に `com.github.tchx84.Flatseal.desktop` が出れば、デスクトップのメニューに載せるためのファイルができている
   - **メニューに載るのはログインし直してから**（この手順の補足）

   <details>
   <summary>補足: メニューに出るまで</summary>

   `flatpak` パッケージは `/etc/profile.d/flatpak.sh` を置き、ログインシェルの `XDG_DATA_DIRS` に `/var/lib/flatpak/exports/share` と `~/.local/share/flatpak/exports/share` を足す。

   - デスクトップはこの変数からアプリの `.desktop` を探すので、**flatpak を入れる前から続いているセッションには、この 2 つが入っていない**
   - flatpak を新しく入れたときは、1 度ログアウトしてログインし直す

   ログインシェルで足されることは次で確かめられる。

   ```bash
   bash -lc 'echo "$XDG_DATA_DIRS"'
   ```

   コンテナでの実測は `/home/<USER>/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share`。**デスクトップのメニューに実際に出るかは確かめていない**（コンテナに画面が無い）。

   `--command=true` は、アプリの中身の代わりに `true` をサンドボックスの中で実行する。**画面を出さずにサンドボックス（bubblewrap）が立ち上がるかだけを確かめる**ためで、アプリそのものの動作確認ではない。

   </details>

---

## 使い方の基本

| コマンド | 用途 |
|---|---|
| `sudo flatpak update --appstream` | 検索用のアプリ一覧（appstream）を取り直す。**Flathub を登録した直後は、先にこれを 1 回実行しないと `flatpak search` が何も返さない** |
| `flatpak search <キーワード>` | Flathub のアプリを探す（ID が分かる） |
| `flatpak remote-info flathub <ID>` | 入れる前に大きさ・runtime・更新日を見る |
| `flatpak remote-ls flathub --app --arch=aarch64` | aarch64 向けに出ているアプリの一覧（Raspberry Pi で使えるか） |
| `sudo flatpak install flathub <ID>` | 入れる |
| `flatpak run <ID>` | 起動する（ふつうはデスクトップのメニューから起動する） |
| `flatpak list --app` | 入っているアプリ |
| `flatpak info --show-permissions <ID>` | アプリに与えられている権限（ファイル・デバイス・ネットワーク） |
| `sudo flatpak override <ID> --filesystem=<パス>` | 権限を足す（GUI でやるなら Flatseal） |
| `sudo flatpak override --reset <ID>` | 足した権限を元に戻す |
| `sudo flatpak uninstall <ID>` | 消す |
| `sudo flatpak uninstall --unused` | もう誰も使っていない runtime を消す |

`flatpak` の読み取り系（`search` / `list` / `info` / `remote-ls`）は `sudo` 無しで動く。

検索の挙動（どちらもコンテナで確認）:

- Flathub を登録しただけの状態では、`flatpak search flatseal` が `No matches found` を返した（`/var/lib/flatpak/appstream/` がまだ無い）
- `sudo flatpak update --appstream` の後は、`Flatseal  Manage Flatpak permissions  com.github.tchx84.Flatseal  2.4.1  stable  flathub` が出た

`sudo flatpak update` を 1 度実行したあとも、同じように検索できるようになる。

---

## 更新

```bash
sudo flatpak update
```

- 更新が無ければ `Nothing to do.` で終わる
- **`dnf upgrade` では Flatpak のアプリは上がらない**（別の仕組み）

---

## ロールバック

確認用のアプリを消し、使われなくなった runtime を掃除する。

```bash
sudo flatpak uninstall "${FP_TEST_APP:?手順 1 の FP_TEST_APP が空のまま。値を入れて貼り直す}"
sudo flatpak uninstall --unused
```

どちらも消す前に `[Y/n]` で聞かれる。**次のブロックは、答えて完了してから貼る。**

Flathub の登録自体を消す。**Flathub から入れたアプリが残っていると消せない**ので、先に `flatpak list --app --columns=application,origin` で `flathub` のものが無いことを確かめる。

```bash
flatpak list --app --columns=application,origin
sudo flatpak remote-delete flathub
flatpak remotes --show-details
```

- 最後の `flatpak remotes --show-details` が何も出さなければ、リモートが無い状態に戻っている
- アプリが自分のホームに作ったデータ（`~/.var/app/<ID>`）は `uninstall` では消えない。要らなければ手で消す
- `flatpak` パッケージ自体は消さない（GNOME のデスクトップでは `gnome-software` が依存している）
- コンテナでの実測では、次のものが消えた。どちらも確認に答えてから消える
  - 1 行目の `uninstall`: Flatseal 1 つ
  - `--unused`: runtime と拡張の 5 つ（`GL.default` の 2 つ・`org.gnome.Platform`・その `Locale`・`codecs-extra`）

---

## 補足

### 対象と検証環境

- **目的**: GUI アプリの主な配布元である [Flathub](https://flathub.org/) を AlmaLinux 10 で使えるようにする。[ツール一覧](tool-catalog.md#gui)で「Flathub」を推奨にしたアプリの前提になる（CLI にとっての [Homebrew](homebrew.md) と同じ位置づけ）
- **進め方**: AppStream の `flatpak` に Flathub をシステム全体で登録し、小さいアプリを 1 つ入れて確かめる。**読者が書き換える変数は無い**
- **状態**: **コンテナでのみ検証済み（2026-09-24）。実機には入れていない**
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**手順 2〜6・[更新](#更新)・[ロールバック](#ロールバック)を通した
  - 確認の問い合わせ（手順 5 とロールバックの `[Y/n]`）には、端末（pty）越しに `y` を送って答えた。コマンドに `-y` は足していない
  - 確認したこと: Flathub の追加、鍵の fingerprint、Flatseal の導入、サンドボックスの起動（`--command=true`）、`.desktop` の書き出し、ロールバックで元に戻ること
  - **確認していないこと**: デスクトップのメニューへの表示、アプリの画面、GNOME Software での表示。コンテナに画面が無いため
  - 検証は x86_64 だけで、aarch64 では通していない（aarch64 向けに出ているアプリは[ツール一覧](tool-catalog.md#aarch64-で使えないもの)を参照）
  - **これまでの手順書のコンテナ検証（実機の上の podman）と違い、x86_64 のクラウドホスト上の Docker で行った**

| 項目 | 実機（Raspberry Pi 5） | 実機（x86_64 PC） | 検証コンテナ |
|---|---|---|---|
| 実施日 | —（未実施） | —（未実施） | 2026-09-24 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64 | AlmaLinux 10.2 (Lavender Lion) / x86_64 | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1、`--privileged`） |
| flatpak | `flatpak-1.16.0` 導入済み、リモート無し（[firefox.md](firefox.md) の 2026-09-22 の記録） | 導入済み、flathub あり（[wezterm-nightly.md](wezterm-nightly.md) の 2026-09-21 の記録） | 未導入 → `flatpak-1.16.0-9.el10_2.1` |
| 確認用アプリ | — | — | Flatseal 2.4.1（GNOME 50 の runtime） |

- 実機の 2 列は**この手順を適用した結果ではなく、ほかの手順書が記録した時点の状態**
- Raspberry Pi 5 はその後 2026-09-24 にクリーンインストールしている（[syncthing.md](syncthing.md)）ので、今の状態は確かめていない

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${FLATHUB_REPO_URL}` | Flathub の登録ファイル（`.flatpakrepo`）の URL | `https://dl.flathub.org/repo/flathub.flatpakrepo`（固定） |
> | `${FP_TEST_APP}` | 動作確認に入れるアプリの ID | `com.github.tchx84.Flatseal`（既定） |
>
> 出力例の値は `<USER>` のプレースホルダで書いてある。バージョン（`1.16.0` / `2.4.1`）と容量は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（AlmaLinux 10 の素のイメージ）の状態:

| 項目 | 状態 |
|---|---|
| flatpak | 未導入（`rpm -q flatpak` → `package flatpak is not installed`） |
| gnupg2 | 未導入（`flatpak` の依存として入る） |
| `/etc/flatpak` / `/var/lib/flatpak` | 無し |

### 選択した方針

| 選択肢 | 採否 |
|---|---|
| **system に入れる（`sudo flatpak ...`）** | **採用。** ホストの全ユーザーで共有できる。dnf と同じく `sudo` で操作する |
| user に入れる（`--user`） | 不採用。自分のユーザーだけで閉じるが、以降のすべてのコマンドに `--user` を付ける必要がある（手順 4 の補足） |
| `sudo` を付けずに system に入れる | 不採用。flatpak は polkit で認証を求めるが、端末からの操作は `sudo` に揃えた。polkit の問い合わせ（デスクトップのダイアログや端末のパスワード入力）は確かめていない |

### 完了時点の状態

**検証コンテナでの出力**（手順 6 の直後。ロールバック前）:

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

### 注意点

- **容量が大きい**: アプリ 1 つ（1 MB 弱）でも、初回は runtime・翻訳・GL ドライバ・コーデックの拡張で 2.5 GB になる
  - [ツール一覧](tool-catalog.md#gui)の Flathub のアプリ 13 本をすべて入れると 8.1 GB になった（runtime は GNOME 50・FDO 25.08・FDO 26.08 の 3 系統）
  - `sudo flatpak uninstall --unused` で、使われなくなった runtime を消せる
- **`dnf upgrade` では上がらない**: [更新](#更新)の `sudo flatpak update` を別に実行する
- **権限はアプリごとに違う**: 手順 5 の実測のように、入れる前に権限の一覧が出る
  - 入れた後は `flatpak info --show-permissions <ID>` で見られ、Flatseal か `sudo flatpak override` で変えられる
- **公開元が検証済みかを見る**: Flathub のアプリには次の 2 種類がある。[ツール一覧](tool-catalog.md#gui)の表に書き分けてある
  - 検証済み: 公開元がアプリの作者本人だと確認されたもの
  - 未検証: 確認されていないもの。第三者が包んでいる場合がある
- **aarch64 に無いアプリがある**: OBS・Slack・Discord・Zoom・Spotify・Edge などは Flathub でも x86_64 だけ（[ツール一覧](tool-catalog.md#aarch64-で使えないもの)）
- **RPM と Flatpak で同じアプリを二重に入れない**: [Firefox](firefox.md) のように RPM で入れたものを Flathub からも入れると、メニューに同じ名前が 2 つ並ぶと見込まれる（未確認。[firefox.md](firefox.md) の未確認事項と同じ）
- **`sudo -i` した root のシェルで実行しない**: `flatpak run` はふつうのユーザーで行うもので、root で起動したアプリの設定は root のホームにできる

### 参照

- [Flathub — Setup](https://flathub.org/setup) — ディストリごとの Flathub の登録手順
- [Flatpak documentation — Using Flatpak](https://docs.flatpak.org/en/latest/using-flatpak.html) — `install` / `update` / `uninstall` / `remote-add` などの基本操作と、system と user のインストール先
- [Flathub — Verified apps](https://docs.flathub.org/docs/for-users/verification) — 検証済みの公開元の意味
- `man flatpak` / `man flatpak-remote-add` / `man flatpak-install` — サブコマンドとオプション
- [ツール一覧](tool-catalog.md) — Flathub で入れる GUI アプリと、RPM との比較

---

### 付録: コンテナでの検証記録（2026-09-24）

`quay.io/almalinuxorg/almalinux:10` を `docker run --privileged` で立てた使い捨てコンテナに非 root ユーザーを作り、`docker exec` で手順 2〜6・[更新](#更新)・[ロールバック](#ロールバック)を通した。実機で加えた変更は無い。実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）。確認の問い合わせに答えるため、全体を `script` で作った pty の中で流し、15 秒おきに `y` を送った。`--privileged` を付けたのは、サンドボックス（bubblewrap）がコンテナの中で名前空間を作れるようにするため。同じホストの非特権コンテナでは、Thunderbird が `CanCreateUserNamespace() clone() failure: EPERM` を出して名前空間を作れなかった。flatpak を非特権のコンテナで試してはいない。

| 手順 | 結果 |
|---|---|
| 1. 変数 | 2 つとも既定の値が表示された |
| 2. flatpak | `flatpak は未導入` → `dnf install -y flatpak` で 138 パッケージ → `Flatpak 1.16.0`。直後の `flatpak remotes --show-details` は `error: While opening repository /var/lib/flatpak/repo: ...` |
| 3. 鍵 | `gpg: directory '/home/<USER>/.gnupg' created` の後に `6E5C 05D9 79C7 6DAF 93C0  8135 4184 DD4D 907A 7CAE`（`Flathub Repo Signing Key <flathub@flathub.org>`、`expires: 2027-06-14`） |
| 4. Flathub | `remote-add` は無出力。`flatpak remotes --show-details` に `flathub` の行（`Options` が `system`） |
| 5. 確認用アプリ | runtime の確認と最終確認の 2 回に `y`。GL ドライバ 2・コーデック 1・GNOME 50 の runtime と翻訳・Flatseal の 6 つが入った |
| 6. 検証 | `flatpak list` に Flatseal 2.4.1（system）、`flatpak info` の `Origin: flathub`、`sandbox OK`、`com.github.tchx84.Flatseal.desktop`。ログインシェルの `XDG_DATA_DIRS` に 2 つの `exports/share` が入った |
| 更新 | `Looking for updates…` → `Nothing to do.` |
| ロールバック | `uninstall` で Flatseal、`--unused` で 5 つが消えた。`flatpak list --app` と、`remote-delete` 後の `flatpak remotes --show-details` はどちらも無出力 |

最初の試行では、pty を使わずに標準入力から `y` を流した。**このときは flatpak が問い合わせに自動で `n` と答えて中断した**（`Do you want to install it? [Y/n]: n`）。スクリプトから流すなら `-y` を付けるか、pty を用意する必要がある。

同じ日に、別の手順（`-y --noninteractive` 付き）で [ツール一覧](tool-catalog.md#gui) の Flathub のアプリ 13 本を同じコンテナに入れた。記録は一覧の付録にある。[使い方の基本](#使い方の基本)の表のうち、`search`（と、その前に要る `update --appstream`）・`info --show-permissions`・`override --filesystem` / `--reset` はその状態で確かめた。`search` が登録直後に何も返さないことは、別の新しいコンテナで `dnf install` → `remote-add` → `search` の順に流して再現した。

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での本実行
- aarch64 での導入（Flathub 自体は aarch64 のアプリを配っている）
- デスクトップのメニューへの表示と、ログインし直す必要があるか
- アプリの画面の表示（Wayland / XWayland、GPU の利用）
- GNOME Software での Flathub のアプリの表示と、そこからの導入・更新
- `sudo` を付けない操作での polkit の問い合わせ
- `--user` でのインストール
- RPM 版と Flatpak 版を両方入れた場合のメニュー表示
- Raspberry Pi 5 のカーネルのページサイズ（`getconf PAGESIZE`）と、Flatpak のアプリの動作への影響
