# hadolint / dive / Trivy インストール手順（AlmaLinux 10 / Homebrew + Trivy 公式 dnf リポジトリ）の検証記録

[手順書](../almalinux-setup.md#画像の道具-実施手順)・[ロールバックと注意点](../extra/image-tools.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 の VM で実施手順を検証した。dive は SSH の擬似端末で文字の表示とキー操作を確認した。デスクトップの端末での見た目と実機での実行は未確認**（[対象と検証環境](#対象と検証環境)）。

### 実施手順 / 手順 3: 補足: 鍵と、EPEL の Trivy との関係

鍵の取り込みの実測:

```
Importing GPG key 0x4FD9CA9F:
 Userid     : "trivy-repo <oss@aquasec.com>"
 Fingerprint: 825A D903 6F7C 850E 6A6F ED49 35B8 ACA4 4FD9 CA9F
 From       : https://aquasecurity.github.io/trivy-repo/rpm/public.key
Is this ok [y/N]: y
Key imported successfully
```

- この鍵は rsa4096（2026-04-16 作成、2029-04-15 まで）で、自己署名のハッシュは SHA-256（`gpg --list-packets` の `digest algo 8`）。EL10 の rpm が取り込まない SHA-1 の鍵（[ツール一覧の注意点](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/tool-catalog.md#注意点)）ではない
- 入るのは `trivy` 1 つで、ダウンロード 48 MB、展開後 161 MB（Go の静的バイナリ）

EPEL にも `trivy` がある（0.64.1）。EPEL を有効にした状態で確かめた:

- `dnf -q list --showduplicates trivy` には、EPEL の `0.64.1-2.el10_1` と公式の `0.74.0-1` の両方が出た
- 公式の 0.74.0 を入れた後の `sudo dnf upgrade trivy` は `Nothing to do.`（古い EPEL の版には下がらない）

### 実施手順 / 手順 5: 補足: 出た指摘の意味

実測:

```
-:1 DL3006 warning: Always tag the version of an image explicitly
-:2 DL3040 warning: `dnf clean all` missing after dnf command.
-:2 DL3041 warning: Specify version with `dnf install -y <package>-<version>`.
rc=1
```

| 規則 | 意味 |
|---|---|
| DL3006 | `FROM` にタグが無い。どの版のイメージを使ったか分からなくなる |
| DL3040 | `microdnf` / `dnf` の後に `dnf clean all` が無い。キャッシュが層に残って大きくなる |
| DL3041 | パッケージの版を固定していない |

- `latest` のタグを書くと、DL3007（`Using latest is prone to errors ...`）が出る（手順 6 でタグを `10.1` にした理由）
- 特定の規則を外すなら `--ignore DL3041`、いつも外すなら `~/.config/hadolint.yaml` に書く（hadolint の README）

### 実施手順 / 手順 9: 補足: データベースと、ソケットが止まっているとき

データベースは `mirror.gcr.io/aquasec/trivy-db:2` から落ち、`~/.cache/trivy` に置かれる（展開後 1.4 GB）。

`--image-src podman` の Trivy は、[podman.md 手順 7](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/podman.md#実施手順) の API ソケットでイメージを読む。ソケットを止めた状態での実測:

```
FATAL	Fatal error	run error: image scan error: ... unable to find the specified image "localhost/image-check:1" in ["podman"]: 1 error occurred:
	* podman error: unable to inspect the image (localhost/image-check:1): http error: Get "http://podman/images/localhost/image-check:1/json": dial unix /run/user/<UID>/podman/podman.sock: connect: connection refused
```

- 見つかったときに終了コードを 1 にしたい（スクリプトで止めたい）ときは `--exit-code 1` を付ける
- `--severity` を外すと、LOW・MEDIUM も含めて全部出る（検証のイメージでは、それでも `0` だった）

### ロールバック / 手順 5: 本文中の記録

   - `gpg-pubkey-4fd9ca9f-69e0b811` は、[実施手順](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/image-tools.md#実施手順)の手順 3 で取り込まれた鍵の名前（検証で確かめた値）

### 対象と検証環境

- **目的**: コンテナイメージを作るときの検査の道具を 3 つそろえる
  - hadolint: Containerfile の書き方
  - dive: 層ごとの中身と無駄
  - Trivy: 脆弱性と設定の問題
- **進め方**: hadolint と dive は Homebrew、Trivy は公式の dnf リポジトリから入れる（[選択した方針](../reference/image-tools.md#選択した方針)）。確認用のイメージを 1 つ作って、3 つを当てる。**読者が書き換える変数は無い**
- **状態**: **x86_64 の VM で実施手順 1〜10を検証済み（2026-10-06）。実機では本実行していない**
  - これは 2026-10-06 の時点の状態
  - VM の実測は[今回の付録](#付録-vm-での検証記録2026-10-06)。以下のコンテナでの結果と未確認事項は、当時の検証範囲の記録。
  - 下表の検証コンテナで、[podman.md](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/podman.md) の実施手順と [Homebrew の導入](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/almalinux-setup.md)を通したうえで、**この文書のコードブロックをそのまま端末に流して**、手順 1〜10、[更新](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/image-tools.md#更新)、[ロールバック](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/extra/image-tools.md#ロールバック)を通した
  - 確認したこと:
    - 3 つが入り、hadolint が欠陥を指摘する
    - dive が podman のイメージを直接読み、判定と画面を出す
    - Trivy が API ソケット経由でイメージを読み、データベースを取得して結果の表を出す
  - **確認していないこと**: dive の画面の見た目と操作（表示された文字を読み取っただけ）、脆弱性が見つかるイメージでの Trivy の出力
  - aarch64（Raspberry Pi 5）では通していない
  - 2026-10-02: もとの手順 3・4 と、[ロールバック](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/extra/image-tools.md#ロールバック)のもとの手順 5・6 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）
- 2026-10-11: Hyper-V の VM で Codex が再検証した（末尾の付録）。
  - 実施・確認: 導入・検査・TUI・更新を実行。手順 4 は固定版の条件と不一致。hadolint・dive の想定した失敗と Trivy の検査を確認。
  - 未確認: ほかのイメージの安全性、更新がある場合、全面ロールバック、デスクトップ端末での描画、実機・aarch64・Secure Boot 有効環境は今回未実施。dive の文字への復元には一部重なりがあり、描画全体が正しく復元されたとは扱わない。

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2`、Docker 29.3.1、`--privileged`。[podman.md](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/podman.md) と同じ作り） |
| podman | 未確認 | `podman-5.8.2-9.el10_2.alma.1`（[podman.md](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/podman.md) の実施手順で導入） |
| Homebrew | 未確認 | 7.0.6（[homebrew.md](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/almalinux-setup.md) の手順 1〜4 で導入） |
| hadolint / dive | 未導入 | 2.15.1 / 0.13.1（`x86_64_linux` のボトル） |
| Trivy | 未導入 | `trivy-0.74.0-1`（公式の dnf リポジトリ） |
| 端末 | — | pty（160 桁 × 50 行、`TERM=xterm-256color`） |

> [!NOTE]
> 出力例の値は `<USER>` / `<UID>` / `<HOSTNAME>` のプレースホルダで書いてある。バージョン（`2.15.1`・`0.13.1`・`0.74.0`）、イメージの大きさ、脆弱性の数は実行日によって変わる。**鍵の fingerprint は公開情報なので本文に書いてある。**

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（[podman.md](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/podman.md) の実施手順と Homebrew の導入の後）の状態:

| 項目 | 状態 |
|---|---|
| podman | 5.8.2。API ソケットは `active` |
| Homebrew | 7.0.6（`brew leaves` は空） |
| hadolint / dive / Trivy | 未導入 |
| EPEL | 未設定（本書では使わない） |

### 完了時点の状態

**検証コンテナでの出力**（手順 2・4・6〜9）:

```
$ hadolint --version
Haskell Dockerfile Linter 2.15.1
$ dive --version
dive 0.13.1
$ trivy --version
Version: 0.74.0
...
$ hadolint ~/image-check/Containerfile; echo "rc=$?"
rc=0
$ podman images localhost/image-check
REPOSITORY             TAG         IMAGE ID      CREATED                 SIZE
localhost/image-check  1           4ccb3959732f  Less than a second ago  283 MB
$ dive --source podman --ci localhost/image-check:1; echo "rc=$?"
...
  efficiency: 85.4470 %
  wastedBytes: 58951134 bytes (59 MB)
  userWastedPercent: 93.7985 %
...
Result:FAIL [Total:3] [Passed:0] [Failed:2] [Warn:0] [Skipped:1]
rc=1
$ trivy image --image-src podman --severity HIGH,CRITICAL localhost/image-check:1
...
Report Summary

┌───────────────────────────────────────┬────────┬─────────────────┬─────────┐
│                Target                 │  Type  │ Vulnerabilities │ Secrets │
├───────────────────────────────────────┼────────┼─────────────────┼─────────┤
│ localhost/image-check:1 (redhat 10.1) │ redhat │        0        │    -    │
└───────────────────────────────────────┴────────┴─────────────────┴─────────┘
```

手順 10 の dive の画面の `Image Details` には、次が出た。

- `Image name: localhost/image-check:1`
- `Total Image size: 275 MB`
- `Potential wasted space: 59 MB`
- `Image efficiency score: 85 %`

### 付録: コンテナでの検証記録（2026-09-27）

**環境**: [podman.md の付録](podman.md#付録-コンテナでの検証記録2026-09-27)と同じ作りの使い捨てのコンテナ。実機で加えた変更は無い。

- `quay.io/almalinuxorg/10-init:10.2` で systemd を PID 1 にし（`--privileged`）、SSH でログインした
- 同じ SSH のセッションで、先に podman.md の手順 1〜3・5〜7 と [homebrew.md](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/almalinux-setup.md) の手順 1〜4 を流した

**手順書の外で行った準備**: podman.md の付録の準備と同じ。Homebrew のインストーラは、`NONINTERACTIVE=1` を付けずに流し、`Press RETURN/ENTER to continue` に pty 越しに Enter を送った。

**流し方**: podman.md の付録と同じく、ブロックを 1 行ずつ端末に流し、`[y/N]` には `y` と答えた。手順 10 は、160 桁 × 50 行の pty（`TERM=xterm-256color`）で 15 秒待って画面の文字を読み取り、`q` を送った。

| 手順 | 結果 |
|---|---|
| 1〜2. hadolint・dive | どちらもボトル（hadolint は依存の `gmp`・`zlib-ng-compat`・`libffi`・`xz` も）。`Haskell Dockerfile Linter 2.15.1`、`dive 0.13.1`、どちらも `/home/linuxbrew/.linuxbrew/bin/` |
| 3〜4. Trivy | repo ファイルを作成。`trivy.x86_64  0.74.0-1  trivy`。`[y/N]` と鍵（`0x4FD9CA9F`、fingerprint は本文のとおり）に `y`。1 パッケージ（48 MB、展開後 161 MB）。`Version: 0.74.0`、`/usr/bin/trivy`、`trivy-0.74.0-1.x86_64` |
| 5. 欠陥の検出 | `DL3006`・`DL3040`・`DL3041` の 3 つと `rc=1` |
| 6. Containerfile | 無出力で `rc=0` |
| 7. ビルド | `ubi10/httpd-24:10.1` を取得し、`Successfully tagged localhost/image-check:1`（283 MB） |
| 8. dive の判定 | `efficiency: 85.4470 %`、`Result:FAIL`、`rc=1`（手順 8 の補足） |
| 9. Trivy | データベース（`mirror.gcr.io/aquasec/trivy-db:2`）を取得し、`redhat 10.1` と判定、`Vulnerabilities` は `0` |
| 10. dive の画面 | `Layers`・`Current Layer Contents`・`Image Details` の枠と、手順 8 と同じ値。`q` で終了した |
| 更新 | `brew upgrade hadolint dive` は `Warning: hadolint 2.15.1 already installed` など。`sudo dnf upgrade trivy` は `Nothing to do.` |
| ロールバック | イメージ 2 つを消し、`brew uninstall` で 2 つと依存の 4 つ（`==> Autoremoving 4 unneeded formulae:`）、`dnf remove` で Trivy、手順 5 で repo ファイルと鍵を消した。手順 5 の確かめの行（もとの手順 6）の一覧は AlmaLinux の鍵 1 つだけ |

**最初の試行で見つけて直したこと**: [ロールバック](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/extra/image-tools.md#ロールバック)の手順 5 は、はじめ `sudo rm`・`sudo rpm -e`・`rpm -q` の 3 行だった。

- 1 行ずつ流すと、`sudo` が後ろの 2 行を端末の入力として取り込み、2 行目以降が実行されなかった
- EL10 の sudo 1.9.17 は、既定でコマンドを擬似端末の中で動かす（`sudo -V` の `Always run commands in a pseudo-tty`）
- `&&` でつないだ 1 行と、確かめる手順に分けた

**別に確かめたこと**（同じ作りの別のコンテナで、手順書の外のコマンドとして実行）:

- `latest` のタグで DL3007、`--ignore DL3041` で DL3041 が消えること
- 層が 1 つの `quay.io/almalinuxorg/10-minimal:10.2` を元にしたイメージでは、`dive --ci` が `efficiency: 100.0000 %` で `Result:PASS`
- EPEL を有効にした状態の `dnf -q list --showduplicates trivy`（手順 3 の補足）
- API ソケットを止めた状態の `trivy image --image-src podman`（手順 9 の補足）
- `trivy image` でレジストリのイメージを直接調べること、`trivy config`（[使い方の基本](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/image-tools.md#使い方の基本)）
- 鍵の自己署名のハッシュ（`gpg --list-packets` の `digest algo 8`）

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- dive の画面の見た目と、キー操作（`q` で終わること以外）
- 脆弱性が見つかるイメージでの Trivy の出力と `--exit-code 1`
- `.dive-ci` での基準の変更
- `~/.config/hadolint.yaml` での設定
- Trivy のデータベースが古くなったときの自動の取り直し

---

### 付録: VM での検証記録（2026-10-06）

**環境**: [クリーンインストールからの検証記録](../almalinux-vm-verification.md)のコンテナ用 VM。公式 ISO から Workstation を入れた状態から始め、x86_64、SELinux Enforcing、firewalld 有効。本文のブロックを SSH の擬似端末で実行した。

- podman.md と homebrew.md を通した VM で、手順 1〜10 を本文のまま実行した。hadolint 2.15.1、dive 0.13.1、ベンダーの RPM の Trivy 0.75.0 が入った。Trivy の鍵の fingerprint も本文と一致した。
- 欠陥のある Containerfile は hadolint が DL3006 / DL3040 / DL3041 を報告して終了 1、直した Containerfile は終了 0。`localhost/image-check:1` を実際にビルドした。
- dive の CI 判定は効率 85.4470%、無駄な容量約 59 MB、ユーザーの無駄な割合 93.7985% で終了 1。意図した判定結果として確認した。手順 10 で Layers / Contents の画面が出て、矢印・Tab・Ctrl+C に応答した。
- Trivy は約 121 MiB のデータベースを取得し、RHEL 10.1 の 207 パッケージを調べた。今回の取得時点・対象イメージでは HIGH / CRITICAL が 0 件だった。将来のデータベースや別のイメージについての結果ではない。
- TUI の確認は文字とキーの応答まで。脆弱性が見つかるイメージ、実機・aarch64、更新・ロールバックは今回通していない。

---

### 付録: 現行版を新規 VM で再検証（2026-10-06）

**対象**: `setup-notes` の `5da3478` 版。公式 ISO で Workstation を入れた `clean-install` スナップショットから、新規の `alma10-current-20261006-containers` を作った。AlmaLinux 10.2 / x86_64 / SELinux Enforcing / firewalld 有効。共通 bash は `3d5323e` を新規導入した。以前の付録と別の試験で、現行ブロックを SSH の擬似端末で順に実行した。

実施手順 1〜10 を通した。hadolint 2.15.1、dive 0.13.1、Trivy 0.75.0。悪い Dockerfile の hadolint は警告と終了 1、改善後は終了 0。`localhost/image-check:1` をビルドし、dive の CI モードは本文の想定どおり効率しきい値で FAIL / 終了 1、TUI は Layers / Layer Details / filetree を表示して `q` で終了した。Trivy はソケットから取得・検査を完了した（その時点の検出は 0 件。このイメージが以後も無脆弱性という意味ではない）。

ロールバックの手順 1〜5 も通した。専用イメージ・作業ディレクトリ・Trivy キャッシュ、hadolint / dive、本体の Trivy RPM、今回追加した Trivy リポジトリと公開鍵を撤去できた。EPEL などほかの公開鍵は残った。

### 手順中の実測・検証状況の記録

- 検証では `Vulnerabilities` が `0` だった（結果は、データベースの日付とイメージの中身で変わる）

### 手順中の実測・検証状況の記録

- 脆弱性のデータベースは別もので、`trivy image` が古いと判断したときに取り直す（検証では初回に `Need to update DB` と出て取得した）

### 実施手順 / 手順 1: 補足: ボトルと依存

```
$ brew deps --tree hadolint dive
dive
hadolint
├── gmp
├── zlib-ng-compat
├── libffi
└── xz
```

x86_64 で降ってきたボトルは `hadolint--2.15.1.x86_64_linux.bottle.tar.gz` と `dive--0.13.1.x86_64_linux.bottle.2.tar.gz`。依存を含めて 5 秒ほどで入った。

### 実施手順 / 手順 8: 補足: FAIL の理由と、判定の基準

`--ci` の既定の基準は 3 つで、この 2 つに引っかかった:

```
FAIL: highestUserWastedPercent: too many bytes wasted, relative to the user bytes added (%-user-wasted-bytes=0.9379853861664853 > threshold=0.1)
SKIP: highestWastedBytes: rule disabled
FAIL: lowestEfficiency: image efficiency is too low (efficiency=0.8544699280688606 < threshold=0.9)
Result:FAIL [Total:3] [Passed:0] [Failed:2] [Warn:0] [Skipped:1]
```

層が 1 つの `quay.io/almalinuxorg/10-minimal:10.2` に `COPY` を 1 つ足しただけのイメージでは、`efficiency: 100.0000 %` で `Result:PASS` だった。

- `Inefficient Files:` の上位は `/usr/lib/sysimage/rpm/rpmdb.sqlite`（3 回、46 MB）と `/var/lib/dnf/history.sqlite-wal`（3 回、12 MB）
- `ubi10/httpd-24` は、ベース → s2i-core → httpd の 3 つの層でパッケージを入れていて、層ごとに rpm のデータベースが書き直されている
- 自分の層（`COPY` で 3.58 kB）が小さいので、「自分が足した量に対する無駄」の割合が大きく出る

### 手順内の実測・検証状況

- 1.4 GB 空く

### 手順内の実測・検証状況

- **Trivy のデータベースは大きい**: `~/.cache/trivy` が 1.4 GB になった。要らなくなったら[ロールバック](https://github.com/ryo-aoki-pc/setup-notes/blob/421be2df74f6120da0168d8e9b5cbeac9af8dda1/docs/extra/image-tools.md#ロールバック)の手順 2 で消す

## 付録: Hyper-V の VM で通した記録（2026-10-11）

- 実施したのは Codex。対象は手順書のコミット `d69f1130f94d831b60bc9bd38a568d2cfb71659e`。下表は直す前の手順を通した結果。
- 証跡は `D:\vmverify\codex\units\C13\` の下にあり、このリポジトリには入っていない。
- 表の seq は `session/steps.jsonl` の連番。
- 確認出力は `session/after-confirm/`、TUI・対話・確認見出しの無い手順は `session/session-001.raw` の rawFrom / rawTo に対応する箇所で照合した。
- VM の値は `<USER>`・`<HOSTNAME>`・`<SERVER_IP>`・`<UID>` で書く。

### 環境

| 項目 | 値 |
|---|---|
| ホスト | Windows 11 Pro、build 26300、Hyper-V |
| VM | Generation 2、構成版 12.0、2 vCPU、3072 MB、64 GiB、Default Switch・eth0 1 枚、Secure Boot 無効 |
| ゲスト | AlmaLinux 10.2 (Lavender Lion)、x86_64、kernel 6.12.0-211.64.1.el10_2.x86_64 |
| 開始状態 | after-CL1 の新規クローン（初期設定・linger・Podman・Docker API・Quadlet の後）、SELinux Enforcing・rootless=true |
| 共通 bash | 67abb84ed5601b242870841ff1da381388f5427a（一般ユーザーと今回導入した root） |
| 対象版 | hadolint 2.15.1、dive 0.13.1、公式 Trivy 0.75.0-1（EPEL 候補 0.64.1-2.el10_1） |
| 貼り方 | GNOME コンソールにログインした状態で、SSH の対話の bash にドライバでブロックを順に貼った。TUI は SSH の端末の文字とキー操作で確認した |

### 手順ごとの結果

| 節 | 項 | 手順 | 判定 | 根拠 | メモ |
|---|---|---:|---|---|---|
| 実施手順 | — | 1 | 通した | `session/steps.jsonl` seq 106 | hadolint / dive の導入完了 |
| 実施手順 | — | 2 | 通した | `session/steps.jsonl` seq 107 | hadolint 2.15.1 / dive 0.13.1 / Homebrew のパス |
| 実施手順 | — | 3 | 通した | `session/steps.jsonl` seq 108 | gpgcheck=1。公式 0.75.0 と EPEL 0.64.1 が候補。`session/steps.jsonl` seq 109 で鍵の fingerprint 一致を確認し、`session/steps.jsonl` seq 110 の y で取り込み・導入成功 |
| 実施手順 | — | 4 | 通らなかった | `session/steps.jsonl` seq 111 | Version:0.75.0、/usr/bin/trivy、trivy-0.75.0-1.x86_64。固定版 0.74.0 の成功条件とは不一致 |
| 実施手順 | — | 5 | 通した | `session/steps.jsonl` seq 112 | DL3006 / DL3040 / DL3041 の warning、rc=1（想定した失敗） |
| 実施手順 | — | 6 | 通した | `session/steps.jsonl` seq 113 | 正常例は指摘なし、rc=0 |
| 実施手順 | — | 7 | 通した | `session/steps.jsonl` seq 114 | `session/steps.jsonl` seq 115 まで待機。Successfully tagged localhost/image-check:1、283 MB |
| 実施手順 | — | 8 | 通した | `session/steps.jsonl` seq 116 | podman ソース。efficiency=85.4470%、wastedBytes=58951134（59 MB）、Result:FAIL、rc=1（想定どおり） |
| 実施手順 | — | 9 | 通した | `session/steps.jsonl` seq 117 | DB 121.04 MiB 取得。redhat 10.1、Report Summary の HIGH/CRITICAL=0 |
| 実施手順 | — | 10 | 通した | `session/steps.jsonl` seq 118 | Layers / Image Details / Current Layer Contents / 85% / 59 MB / キー案内。down で層移動、Tab で枠切替、`session/steps.jsonl` seq 121 の q で終了 |
| 更新 | — | 1 | 通した | `session/steps.jsonl` seq 122 | hadolint / dive は already installed |
| 更新 | — | 2 | 通した | `session/steps.jsonl` seq 123 | Trivy は更新なし |
| extra / ロールバック | — | 全手順 | 未実施 | 今回の対象外 | 過去のロールバック記録は保持 |

- hadolint の欠陥例は DL3006・DL3040・DL3041 と rc=1、正常例は rc=0。
- 283 MB の確認イメージを作成した。
- dive --ci は 85.4470%、58951134 bytes（59 MB）、Result:FAIL / rc=1（想定どおり）。
- Trivy は DB 121.04 MiB を取得し、redhat 10.1 の HIGH・CRITICAL は 0 件。
- この時点・このイメージ・この severity の結果。
- `dive-initial.txt`・`dive-down.txt`・`dive-tab.txt` と raw で層移動・枠切替・q 終了を確認した。

### 通らなかった手順と見立て

実施手順 4 は、導入された 0.75.0 と本文の固定版 0.74.0 が一致せず通らなかった。実行ファイルと RPM の版は一致し、後続の検査は通った。取得元の候補の差で、SSH や Hyper-V が原因とする証拠は無い。過去の 0.74.0 の記録はその時点の結果として保持する。

Homebrew は Landlock ABI 10 以上を要求し、ゲストは ABI 6 という警告を出したが導入は完了した。カーネル由来の警告で、Hyper-V 自体が原因と確かめたものではない。

### 指摘と状態

| 重大度 | 場所 | 指摘 | 状態 |
|---|---|---|---|
| 低 | docs/image-tools.md / 実施手順 / 手順 3 | 文言の直し | 直した |
| 低 | docs/image-tools.md / 実施手順 / 手順 4 | 文言の直し | 直した |
| 低 | docs/image-tools.md / 実施手順 / 手順 9 | 文言の直し | 直した |

### 手順書を直した所

- docs/image-tools.md / 実施手順 / 手順 3: 文言。根拠: C13/session/after-confirm/0108-実施手順-3.txt。対応する出力を VM の証跡で確認。文言の直しで、ブロックは変更していない。
- docs/image-tools.md / 実施手順 / 手順 4: 文言。根拠: C13/session/after-confirm/0108-実施手順-3.txt、0111-実施手順-4.txt。対応する出力を VM の証跡で確認。文言の直しで、ブロックは変更していない。
- docs/image-tools.md / 実施手順 / 手順 9: 文言。根拠: C13/session/session-001.raw seq 117。対応する出力を VM の証跡で確認。文言の直しで、ブロックは変更していない。

### 確かめていないこと

- ほかのイメージの安全性、更新がある場合、全面ロールバック、デスクトップ端末での描画、実機・aarch64・Secure Boot 有効環境は今回未実施。dive の文字への復元には一部重なりがあり、描画全体が正しく復元されたとは扱わない。
- 今回の Hyper-V の結果を、別のハイパーバイザや実機の成功範囲に広げない。過去の付録はその当時の検証範囲として残す。
