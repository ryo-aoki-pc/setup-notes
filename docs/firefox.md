# Firefox 最新版インストール手順（AlmaLinux 10 / Mozilla 公式 RPM リポジトリ）

## 実施手順

**すべて対象ホスト上で実行する。** 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る（各手順の末尾で折り畳んである「補足」の中のブロックは、手順を進めるためには貼らなくてよい）。理由・実測出力・落とし穴は、手順ごとのものはその手順の「補足」に、全体に関わるものは後半の[補足](#補足)にまとめてあり、実行するだけなら読まなくてよい。

以後の更新は[更新](#更新)、戻すときは[ロールバック](#ロールバック)。

1. **変数を設定する**

   **このブロックは編集必須の変数が無い。** 最新版（Rapid Release）を入れるなら既定のままでよい。ESR や Beta にしたいときだけ `FF_PKG` を変える。**新しいシェルを開いたら（SSH を張り直したあとも）先にこのブロックを貼り直す。**

   ```bash
   FF_PKG=firefox                  # 入れるチャンネル。firefox（最新版）/ firefox-esr / firefox-beta。<FF_PKG>
   FF_L10N=firefox-l10n-ja         # 日本語 UI の言語パック。要らなければ空にする。<FF_L10N>
   ```

   **値を読み戻して確かめる。** `FF_PKG` が空なら、ここで止めて直す。

   ```bash
   for v in FF_PKG FF_L10N; do printf '%-9s = %s\n' "$v" "${!v}"; done
   ```

   <details>
   <summary>補足: 変数について</summary>

   `FF_PKG` はチャンネルの選択そのもの。リポジトリに入っている 3 つを実測した:

   ```
   $ dnf -q list --available firefox-l10n-ja firefox-esr firefox-beta | tail -6
   Available Packages
   firefox-beta.aarch64                     157.0b4-1                       mozilla
   firefox-beta.x86_64                      157.0b4-1                       mozilla
   firefox-esr.aarch64                      153.3.0esr-1                    mozilla
   firefox-esr.x86_64                       153.3.0esr-1                    mozilla
   firefox-l10n-ja.noarch                   156.0.1-1                       mozilla
   ```

   `firefox-esr` は **Mozilla の ESR（153 系）** で、AppStream の ESR 140 とは別物。並べて入れることもできる（`/usr/lib64/firefox-esr`）が、本書では扱わない。

   `FF_L10N` は `firefox-l10n-<言語コード>` の形で `noarch`。本体とバージョンが揃っていないと UI に反映されないので、常に本体と一緒に入れ替える。

   </details>

1. **署名鍵を確かめて取り込む**

   ```bash
   curl -fsSL https://packages.mozilla.org/rpm/firefox/signing-key.gpg | gpg --show-keys
   ```

   `pub` 行の fingerprint が `14F26682D0916CDD81E37B6D61B7B526D98F0353`、uid が `Mozilla Software Releases <release@mozilla.com>` であることを**目で確かめてから**取り込む。違っていればここで止める。

   ```bash
   sudo rpm --import https://packages.mozilla.org/rpm/firefox/signing-key.gpg
   rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i mozilla
   ```

   `gpg-pubkey-d98f0353-55a94004 Mozilla Software Releases ...` の 1 行が出る。期限切れの副鍵についての warning が一緒に出るが、署名に使う副鍵は別にあるので問題ない（この手順の補足）。

   <details>
   <summary>補足: 鍵の警告</summary>

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

   </details>

1. **リポジトリを追加する**

   ```bash
   sudo tee /etc/yum.repos.d/mozilla.repo >/dev/null <<'EOF'
   [mozilla]
   name=Mozilla Packages
   baseurl=https://packages.mozilla.org/rpm/firefox
   enabled=1
   gpgcheck=1
   repo_gpgcheck=0
   gpgkey=https://packages.mozilla.org/rpm/firefox/signing-key.gpg
   priority=10
   EOF
   dnf -q list --showduplicates "${FF_PKG}" | tail -6
   ```

   一覧の下のほうに `mozilla` リポジトリ提供の版が出る。このリポジトリは `baseurl` にアーキテクチャを含まないので、`x86_64` の行も一緒に並ぶ（この手順の補足）。

   <details>
   <summary>補足: priority は保険</summary>

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

   将来 AppStream 側の ESR が Mozilla 側の版を追い越す状況（Mozilla 側でリリースが巻き戻る、ESR が別番号体系になる、など）に備えた保険として残している。`repo_gpgcheck=0` は Mozilla の案内どおりで、**パッケージの署名は検証する（`gpgcheck=1`）がリポジトリメタデータには署名が無い**、という意味。

   このリポジトリは `baseurl` に `$basearch` を含まない**全アーキテクチャ共通**の作りなので、`dnf list` には `firefox.x86_64` の行も出る。インストールされるのは実行中のアーキテクチャのものだけ。

   </details>

1. **インストールする**

   `FF_L10N` を空にした場合にクォートで空文字列を渡さないよう、言語パックだけクォートしていない。

   ```bash
   sudo dnf install "${FF_PKG:?手順 1 の FF_PKG が空のまま。値を入れて貼り直す}" ${FF_L10N}
   ```

   AppStream の Firefox（ESR）が既に入っているホストでは、この 1 コマンドが `Upgrading: firefox` として解決される（この手順の補足）。

   <details>
   <summary>補足: ESR からの載せ替え</summary>

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

   </details>

1. **検証する**

   ```bash
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' "${FF_PKG}" ${FF_L10N}
   firefox --version
   rpm -qi "${FF_PKG}" | sed -n '/^Vendor/p;/^Build Date/p'
   ```

   `from_repo` が `mozilla`、`Vendor` が `Mozilla` なら Mozilla 公式のビルドが入っている。

   GUI はデスクトップセッションから起動する。`about:support` の「更新チャンネル」が `release`（ESR なら `esr`）、「アプリケーションのバイナリ」が `/usr/lib64/firefox/firefox` であることを確認する。日本語パックを入れた場合は `about:preferences` の言語で日本語を選べる。

---

## 更新

通常の `dnf upgrade` に含まれる。Firefox だけ上げるなら:

```bash
sudo dnf upgrade "${FF_PKG}" ${FF_L10N}
```

Firefox 内蔵の自動更新機能は RPM 版では無効で（`/usr/lib64/firefox` に一般ユーザーの書き込み権が無い）、更新は dnf 側で行う。本体だけ上げて言語パックを取り残すと UI が英語に戻るので、両方まとめて上げる。

---

## ロールバック

AppStream の ESR に戻す:

```bash
sudo rm -f /etc/yum.repos.d/mozilla.repo
sudo dnf remove ${FF_L10N}                    # 言語パックは AppStream に無いので先に消す
sudo dnf distro-sync "${FF_PKG}"              # 140 系へダウングレードされる
```

鍵も消すなら:

```bash
sudo rpm -e gpg-pubkey-d98f0353-55a94004
```

プロファイル（`~/.mozilla/firefox`）はどちらの操作でも消えない。**ダウングレードした Firefox は、新しいプロファイルを読めないことがある**（[注意点](#注意点)）。本書ではロールバックは**本実行していない**。`dnf --assumeno distro-sync firefox` で、`firefox 140.15.0-1.el10_2 appstream` への `Downgrading` 1 パッケージに解決されることだけ確認した。

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に Firefox の**最新版（Rapid Release）**を dnf 管理で入れる。標準リポジトリ（AppStream）の `firefox` は ESR 140 系で、最新版より 16 メジャー古い
- **進め方**: Mozilla が公式に配っている RPM リポジトリ `packages.mozilla.org/rpm/firefox` を 1 つ足し、`dnf install` するだけ。**読者が書き換えるのは冒頭の変数ブロックだけ**で、既定（最新版 + 日本語パック）ならそのまま貼れる
- **状態**: **実機で本実行済み（2026-09-21）。** 下表のホストで `dnf upgrade firefox` を実行し、AppStream の `140.15.0-1.el10_2` から mozilla の `156.0-1` に載せ替えて、そのまま常用している。本書の手順（鍵の照合 → repo → install → 検証）は 2026-09-22 に同じ OS のコンテナで通し直し、`156.0.1-1` が入ること・ESR からの載せ替えが `Upgrading` として解決されること・ロールバックが `Downgrading` に解決されることを確認した。**コンテナでは GUI を起動していない**（実機では 156.0 が動作中）。**ESR / Beta チャンネルと言語パック以外の l10n は未検証**

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-21 | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| カーネル | 6.12.96 | ホストと同じ |
| dnf | 4.20.0 | 4.20.0 |
| 実施前の Firefox | `firefox-140.15.0-1.el10_2.aarch64`（appstream、ESR 140） | 同じものを `dnf install firefox` で用意 |
| 入った Firefox | `firefox-156.0-1.aarch64`（mozilla、Vendor: Mozilla） | `firefox-156.0.1-1.aarch64` |
| デスクトップ | GNOME 49 / Wayland | 無し（`--version` まで） |
| SELinux | Enforcing | コンテナ側は無効 |

> **注記**: 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${FF_PKG}` | 入れるチャンネルのパッケージ名。`firefox`（最新版）/ `firefox-esr` / `firefox-beta` | `firefox` |
> | `${FF_L10N}` | 言語パックのパッケージ名。空にすると英語 UI のまま | `firefox-l10n-ja` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`156.0.1-1`）は実行日によって変わる。
>
> 鍵の fingerprint は公開情報なので本文に書いてある。プロファイルや保存されたパスワードには触れない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| Firefox | `firefox-140.15.0-1.el10_2.aarch64`（appstream）。`firefox --version` は `Mozilla Firefox 140.15.0esr` |
| AppStream の候補 | `140.10.1-1.el10_2` 〜 `140.15.0-1.el10_2`（ESR 140 系のみ。Rapid Release は無い） |
| 有効な追加リポジトリ | epel、crb、raspberrypi（mozilla はまだ無い） |
| Flatpak | `flatpak-1.16.0` は導入済みだが**リモートが 1 つも登録されていない**（flathub 無し） |
| 鍵 | `rpm -q gpg-pubkey` に Mozilla の鍵は無し |

### 選択した方針

AlmaLinux 10 で Firefox の最新版を使う経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Mozilla 公式 RPM リポジトリ** | `packages.mozilla.org/rpm/firefox` に `firefox` 156.0.1 / `firefox-esr` 153.3.0esr / `firefox-beta` 157.0b4 と各言語パックがあり、**aarch64 と x86_64 の両方**が揃っている。dnf 管理で更新できる | **採用** |
| AppStream の `firefox` | 140.15.0（ESR 140 系）。AlmaLinux がセキュリティ更新を出すが、最新版の機能は入らない | 不採用（最新版ではない） |
| Flathub の `org.mozilla.firefox` | Mozilla 公式ビルド。ただしこのホストは flatpak にリモートが 1 つも登録されておらず、flathub の追加と ~150 MB の runtime 導入から始まる。RPM と二重管理になる | 不採用（RPM で足りる） |
| 公式 tarball を `/opt` に展開 | `linux-aarch64` のビルドが公式にある（Firefox 136 以降）。更新は Firefox 内蔵のアップデータ任せで、`.desktop` を自作する必要がある | 不採用（dnf で管理できない） |
| ソースビルド | 実用的でない | 不採用 |

**最新版であることの確認**: Mozilla の `product-details` が返す `LATEST_FIREFOX_VERSION` は `156.0.1`、`FIREFOX_ESR` は `140.16.0esr`（2026-09-22）。リポジトリの `firefox` 156.0.1 は Rapid Release の最新と一致する。

### 完了時点の状態

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

入るファイル: 本体は `/usr/lib64/firefox/`、起動スクリプトは `/usr/bin/firefox`、`.desktop` は `/usr/share/applications/firefox.desktop`。AppStream 版と同じ場所なので、アプリ一覧やデフォルトブラウザの設定はそのまま引き継がれる。

### 注意点

- **チャンネルが変わる**: ESR（年 1 回のメジャー更新）から Rapid Release（4 週間ごと）に移る。企業ポリシーで ESR を使っている場合は `FF_PKG=firefox-esr`（Mozilla の ESR 153 系）か、そもそもこの手順を使わない
- **セキュリティ更新の出所が変わる**: AppStream 版は AlmaLinux が、mozilla 版は Mozilla が直接出す。`dnf upgrade` の対象になるのは同じだが、AlmaLinux のエラータ（`dnf updateinfo`）には載らない
- **ダウングレードするとプロファイルを読めないことがある**: 156 で開いたプロファイルを 140 で開くと「新しいバージョンの Firefox で作成されたプロファイル」と警告が出る。戻す前提があるなら、先に `~/.mozilla/firefox` を退避しておく
- **言語パックは本体と同時に上げる**: バージョンが食い違うと UI が英語に戻る。`dnf upgrade` 全体を流していれば自動で揃う
- **更新のたびに 107 MB 落ちてくる**: 4 週間ごとの Rapid Release なので、従量課金の回線では効いてくる

### 参照

- [Install Firefox on Linux — Mozilla Support](https://support.mozilla.org/en-US/kb/install-firefox-linux) — 公式のインストール経路の一覧
- [Introducing Mozilla's Firefox Nightly .rpm package — Firefox Nightly News](https://blog.nightly.mozilla.org/2026/01/19/introducing-mozillas-firefox-nightly-rpm-package-for-rpm-based-linux-distributions/) — RPM リポジトリの repo ファイルの書き方（RHEL / CentOS / Rocky 向けの `tee` の例）と鍵の fingerprint
- [Firefox Developer Edition and Beta: Try out Mozilla's .rpm package! — Mozilla Hacks](https://hacks.mozilla.org/2026/03/firefox-developer-edition-and-beta-try-out-mozillas-rpm-package/) — beta / devedition チャンネルの追加
- [firefox_versions.json — Mozilla product-details](https://product-details.mozilla.org/1.0/firefox_versions.json) — その時点の最新版と ESR の版を機械可読で返す
- `man dnf.conf`（`priority`、`gpgcheck`、`repo_gpgcheck`）

---

### 付録: コンテナでの検証記録（2026-09-22）

実機の設定に触れずに手順を通すため、`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで実行した。実機で加えた変更は `dnf install podman` だけ。 最後にもう 1 つ新しいコンテナを立て、**この文書のコードブロックをそのまま抜き出したスクリプト**（`sudo` を外し、`dnf install` / `dnf upgrade` に `-y` を付けただけ）を流して、上から順に貼れば通ることを確かめている。

手順ごとの結果:

| 手順 | 結果 |
|---|---|
| 2. 鍵 | `gpg --show-keys` の fingerprint が `14F26682D0916CDD81E37B6D61B7B526D98F0353` と一致。`rpm --import` は期限切れ副鍵の warning を出して成功、`gpg-pubkey-d98f0353-55a94004` が登録された |
| 3. repo | メタデータ取得に成功。`firefox` は `154.0.1-1` / `155.0-1` / `155.0.1-1` / `156.0-1` / `156.0.1-1` の 5 世代が aarch64・x86_64 の両方で見えた |
| 4. install | ESR 140.15.0 が入った状態から `dnf upgrade -y firefox` で `156.0.1-1` に載せ替え。追加の依存パッケージ無し |
| 5. 検証 | `firefox --version` → `Mozilla Firefox 156.0.1`、`rpm -qi` の `Signature` は `Key ID 678e455d76767aa3`（Mozilla の署名用副鍵） |
| 言語パック | 未導入のコンテナで `dnf install -y firefox firefox-l10n-ja` → `firefox 156.0.1-1 mozilla` と `firefox-l10n-ja 156.0.1-1 mozilla` が入る |
| ロールバック | repo ファイルを消して `dnf --assumeno distro-sync firefox` → `Downgrading firefox 140.15.0-1.el10_2 appstream` 1 パッケージ |

途中で 1 度、`packages.mozilla.org` の名前解決がコンテナ内でタイムアウトして `dnf` がメタデータ取得に失敗した（`Curl error (6): Could not resolve host`）。同じコマンドの再実行で通ったので、リポジトリ側ではなく一時的なものと判断している。

#### 未確認事項

- 実機の GUI で 156 系を起動したあとの `about:support` の記載（実機では常用しているが、`about:support` の内容を記録していない）
- `firefox-esr`（Mozilla の ESR 153 系）と `firefox-beta` の導入、および AppStream の ESR 140 との共存
- 日本語以外の言語パック、`firefox-devedition`
- ロールバック（`distro-sync` によるダウングレード）の本実行と、その後のプロファイルの読み込み
- Flathub 版との併用時の挙動（`.desktop` の重複、既定ブラウザの選択）
