# Flatpak / Flathub 導入手順（AlmaLinux 10）の検証記録

[手順書](../flatpak.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 操作上の注意と併記されていた記録

     - `6E5C 05D9 79C7 6DAF 93C0 8135 4184 DD4D 907A 7CAE`（Flathub Repo Signing Key &lt;flathub@flathub.org&gt;、有効期限 2027-06-14）

### 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 のコンテナと VM で検証した手順書**で、実機と aarch64 では通していない。VM ではメニューと Flatseal の実画面を確認したが、GNOME Software の検索には出なかった（[対象と検証環境](#対象と検証環境)）。

### 実施手順 / 手順 2: 補足: AlmaLinux 10 の flatpak にはリモートが無い

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

GNOME の `gnome-software` パッケージは `flatpak` に依存し、Flatpak 用のプラグイン（`/usr/lib64/gnome-software/plugins-21/libgs_plugin_flatpak.so`）を含む（`dnf repoquery` で確認）。したがって GNOME のデスクトップには flatpak が最初から入っていることが多い（このリポジトリの 2 台とも入っていた。[実施前の状態](#実施前の状態)）。

### 実施手順 / 手順 6: 補足: 一緒に入る runtime

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

確認用に別のアプリを入れてもよい（この手順・手順 7・[ロールバック](../flatpak.md#ロールバック)の手順 1 の ID を置き換える）が、Flatseal より大きいアプリは runtime と合わせて数百 MB を落とす（[注意点](../flatpak.md#注意点)）。

同じ runtime を使うアプリを 2 本目以降に入れるときは、runtime の取得は起きない。[ツール一覧](../tool-catalog.md#gui)の Flathub の行には、アプリごとの runtime（GNOME 50 / FDO 25.08 / FDO 26.08）を書いてある。

### 実施手順 / 手順 7: 補足: メニューに出るまで

`flatpak` パッケージは `/etc/profile.d/flatpak.sh` を置き、ログインシェルの `XDG_DATA_DIRS` に `/var/lib/flatpak/exports/share` と `~/.local/share/flatpak/exports/share` を足す。

- デスクトップはこの変数からアプリの `.desktop` を探すので、**flatpak を入れる前から続いているセッションには、この 2 つが入っていない**
- flatpak を新しく入れたときは、1 度ログアウトしてログインし直す

ログインシェルで足されることは次で確かめられる。

```bash
bash -lc 'echo "$XDG_DATA_DIRS"'
```

コンテナでの実測は `/home/<USER>/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share`。コンテナに画面は無かった。2026-10-06 の Workstation VM では flatpak が既にあり、追加した Flatseal は同じセッションの Activities 検索に出た。

`--command=true` は、アプリの中身の代わりに `true` をサンドボックスの中で実行する。**画面を出さずにサンドボックス（bubblewrap）が立ち上がるかだけを確かめる**ためで、アプリそのものの動作確認ではない。

### ロールバック / 手順 1: 本文中の記録

   - コンテナでの実測では、Flatseal 1 つが消えた

### ロールバック / 手順 2: 本文中の記録

   - コンテナでの実測では、runtime と拡張の 5 つ（`GL.default` の 2 つ・`org.gnome.Platform`・その `Locale`・`codecs-extra`）が消えた

### 対象と検証環境

- **目的**: GUI アプリの主な配布元である [Flathub](https://flathub.org/) を AlmaLinux 10 で使えるようにする。[ツール一覧](../tool-catalog.md#gui)で「Flathub」を推奨にしたアプリの前提になる（CLI にとっての [Homebrew](../homebrew.md) と同じ位置づけ）
- **進め方**: AppStream の `flatpak` に Flathub をシステム全体で登録し、小さいアプリを 1 つ入れて確かめる。**読者が書き換える変数は無い**
- **状態**: **コンテナ（2026-09-24）と x86_64 の VM（2026-10-06）で検証済み。実機には入れていない**
  - 2026-10-06: 別の新規 VM で現行手順を再検証した。今回の実施・解除・未実施範囲は[新しい付録](#付録-現行版の新規-vm-での再検証2026-10-06)に記録した
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**手順 1〜7・[更新](../flatpak.md#更新)・[ロールバック](../flatpak.md#ロールバック)を通した
  - 確認の問い合わせ（手順 6 とロールバックの `[Y/n]`）には、端末（pty）越しに `y` を送って答えた。コマンドに `-y` は足していない
  - 確認したこと: Flathub の追加、鍵の fingerprint、Flatseal の導入、サンドボックスの起動（`--command=true`）、`.desktop` の書き出し、ロールバックで元に戻ること
  - **確認していないこと**: デスクトップのメニューへの表示、アプリの画面、GNOME Software での表示。コンテナに画面が無いため
  - 検証は x86_64 だけで、aarch64 では通していない（aarch64 向けに出ているアプリは[ツール一覧](../tool-catalog.md#aarch64-で使えないもの)を参照）
  - **これまでの手順書のコンテナ検証（実機の上の podman）と違い、x86_64 のクラウドホスト上の Docker で行った**
  - 2026-09-28: [ロールバック](../flatpak.md#ロールバック)の手順 4のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない
  - 2026-10-02: もとの手順 5・6 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）

| 項目 | 実機（Raspberry Pi 5） | 実機（x86_64 PC） | 検証コンテナ |
|---|---|---|---|
| 実施日 | —（未実施） | —（未実施） | 2026-09-24 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64 | AlmaLinux 10.2 (Lavender Lion) / x86_64 | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1、`--privileged`） |
| flatpak | `flatpak-1.16.0` 導入済み、リモート無し（[firefox.md](../firefox.md) の 2026-09-22 の記録） | 導入済み、flathub あり（[wezterm-nightly.md](../wezterm-nightly.md) の 2026-09-21 の記録） | 未導入 → `flatpak-1.16.0-9.el10_2.1` |
| 確認用アプリ | — | — | Flatseal 2.4.1（GNOME 50 の runtime） |

- 実機の 2 列は**この手順を適用した結果ではなく、ほかの手順書が記録した時点の状態**
- Raspberry Pi 5 はその後 2026-09-24 にクリーンインストールしている（[syncthing.md](../syncthing.md)）ので、今の状態は確かめていない

> [!NOTE]
> 出力例の値は `<USER>` のプレースホルダで書いてある。バージョン（`1.16.0` / `2.4.1`）と容量は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（AlmaLinux 10 の素のイメージ）の状態:

| 項目 | 状態 |
|---|---|
| flatpak | 未導入（`rpm -q flatpak` → `package flatpak is not installed`） |
| gnupg2 | 未導入（`flatpak` の依存として入る） |
| `/etc/flatpak` / `/var/lib/flatpak` | 無し |

### 完了時点の状態

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

### 操作上の注意と併記されていた記録

- **権限はアプリごとに違う**: 手順 6 の実測のように、入れる前に権限の一覧が出る

### 操作上の注意と併記されていた記録

- **公開元が検証済みかを見る**: Flathub のアプリには次の 2 種類がある。[ツール一覧](../tool-catalog.md#gui)の表に書き分けてある

### 操作上の注意と併記されていた記録

  - 検証済み: 公開元がアプリの作者本人だと確認されたもの

### 参照

- [Flathub — Setup](https://flathub.org/setup) — ディストリごとの Flathub の登録手順
- [Flatpak documentation — Using Flatpak](https://docs.flatpak.org/en/latest/using-flatpak.html) — `install` / `update` / `uninstall` / `remote-add` などの基本操作と、system と user のインストール先
- [Flathub — Verified apps](https://docs.flathub.org/docs/for-users/verification) — 検証済みの公開元の意味
- `man flatpak` / `man flatpak-remote-add` / `man flatpak-install` — サブコマンドとオプション
- [ツール一覧](../tool-catalog.md) — Flathub で入れる GUI アプリと、RPM との比較

### 付録: コンテナでの検証記録（2026-09-24）

`quay.io/almalinuxorg/almalinux:10` を `docker run --privileged` で立てた使い捨てコンテナに非 root ユーザーを作り、`docker exec` で手順 1〜7・[更新](../flatpak.md#更新)・[ロールバック](../flatpak.md#ロールバック)を通した。実機で加えた変更は無い。実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）。確認の問い合わせに答えるため、全体を `script` で作った pty の中で流し、15 秒おきに `y` を送った。`--privileged` を付けたのは、サンドボックス（bubblewrap）がコンテナの中で名前空間を作れるようにするため。同じホストの非特権コンテナでは、試したアプリが `CanCreateUserNamespace() clone() failure: EPERM` を出して名前空間を作れなかった。flatpak を非特権のコンテナで試してはいない。

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

同じ日に、別の手順（`-y --noninteractive` 付き）で [ツール一覧](../tool-catalog.md#gui) の Flathub のアプリを含む 13 本を同じコンテナに入れた。記録は一覧の付録にある。[使い方の基本](../flatpak.md#使い方の基本)の表のうち、`search`（と、その前に要る `update --appstream`）・`info --show-permissions`・`override --filesystem` / `--reset` はその状態で確かめた。`search` が登録直後に何も返さないことは、別の新しいコンテナで `dnf install` → `remote-add` → `search` の順に流して再現した。

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

### 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を ISO から新規に入れた VirtualBox の VM（x86_64、1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で、検証用ユーザーの SSH PTY に現行のブロックを個別に貼った。利用者のアカウントは使っていない。

実施手順 1・3〜7、更新、ロールバック 1〜4 を本実行した。`flatpak-1.16.0-9.el10` は Workstation に既にあったため手順 2 は省略した。Flathub の署名鍵を照合し、system に Flatseal 2.4.1 と GNOME 50 の runtime・拡張の計 6 ref を入れた。`sandbox OK` と desktop エントリを確認し、ヘッドレス GNOME の実画面で Flatseal が日本語で開き、Activities の検索にも出た。このセッションは flatpak が既に入っている状態から開始したため、アプリを入れた後のログインし直しは不要だった。

`sudo flatpak update` は `Nothing to do.`。`update --appstream` 後の CLI の検索は Flatseal を返した。一方、GNOME Software 47.5 の検索は、起動し直した後も `No App Found` だった（Flatpak のプラグインは同梱）。GNOME Software で表示・導入・更新が通るとはしない。ロールバックでは Flatseal 1 ref → 使われなくなった runtime と拡張の 5 ref → flathub の登録の順に消え、アプリ一覧とリモート一覧は空になった。RPM の flatpak 本体は残した。実機、aarch64、`--user`、キーリング、GPU は今回も確認していない。

---

### 付録: 現行版の新規 VM での再検証（2026-10-06）

**環境と流し方**: `5da3478` の現行手順を、別のクリーンな AlmaLinux 10.2 Workstation / x86_64 の VM（1 vCPU、SELinux Enforcing、firewalld 稼働、US 配列）で実行した。SSH の一般ユーザーの対話 PTY に折り畳みの外のブロックを手順ごとに貼り、応答とプロンプトを待った。GUI は GNOME 49.4 のヘッドレスセッションに仮想モニターを付け、操作後の PNG を目視した。既存の実機・資格情報は使っていない。

実施手順 1・3〜6 を本実行した。Flatpak `1.16.0` は OS に既存だったため導入分岐 2 は不要だった。署名鍵の指紋と有効期限を確認し、system の Flathub を追加した。Flatseal `2.4.1` と GNOME 50 の runtime / 拡張を導入し、実際の GUI で権限の画面を確認した。更新は変更なしで成功した。手順 7 の `--command=true` による独立した sandbox 確認は今回実行せず、実アプリの GUI 起動を確認した。

ロールバック 1〜4 を実行した。Flatseal と 5 つの未使用 runtime / 拡張を削除し、アプリ一覧が空になった後、Flathub を削除して remote 一覧も空になった。今回のアプリ起動は desktop ID を使ったため、Activities のメニュー掲載と GNOME Software の検索は今回の確定結果に含めていない。aarch64 と物理実機は未実施。


### 操作上の注意と併記されていた記録

- Flathub を登録しただけの状態では、`flatpak search flatseal` が `No matches found` を返した（`/var/lib/flatpak/appstream/` がまだ無い）


### 実施手順 / 手順 5: 補足: system に入れる理由と、出力例

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



### 選択した方針

| 選択肢 | 採否 |
|---|---|
| **system に入れる（`sudo flatpak ...`）** | **採用。** ホストの全ユーザーで共有できる。dnf と同じく `sudo` で操作する |
| user に入れる（`--user`） | 不採用。自分のユーザーだけで閉じるが、以降のすべてのコマンドに `--user` を付ける必要がある（手順 5 の補足） |
| `sudo` を付けずに system に入れる | 不採用。flatpak は polkit で認証を求めるが、端末からの操作は `sudo` に揃えた。polkit の問い合わせ（デスクトップのダイアログや端末のパスワード入力）は確かめていない |

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 使い方の基本

検索の挙動（どちらもコンテナで確認）:

- `sudo flatpak update --appstream` の後は、`Flatseal  Manage Flatpak permissions  com.github.tchx84.Flatseal  2.4.1  stable  flathub` が出た

### 補足

- **容量が大きい**: アプリ 1 つ（1 MB 弱）でも、初回は runtime・翻訳・GL ドライバ・コーデックの拡張で 2.5 GB になる

  - [ツール一覧](../tool-catalog.md#gui)の Flathub のアプリを全部入れると、runtime は GNOME 50・FDO 25.08・FDO 26.08 の 3 系統になる

  - 調査時は、ほかのアプリも合わせた 13 本で 8.1 GB になった

- **RPM と Flatpak で同じアプリを二重に入れない**: [Firefox](../firefox.md) のように RPM で入れたものを Flathub からも入れると、メニューに同じ名前が 2 つ並ぶと見込まれる（未確認。[firefox.md](../firefox.md) の未確認事項と同じ）
