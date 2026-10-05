# hadolint / dive / Trivy インストール手順（AlmaLinux 10 / Homebrew + Trivy 公式 dnf リポジトリ）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) と、[Podman](podman.md) の実施手順（手順 7 の API ソケットまで）を通してあること。`command -v brew podman` が 2 行を返し、`systemctl --user is-active podman.socket` が `active` を返さなければ、先に通す
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、イメージも自分のユーザーの podman に作るため）
> - **手順 3 には対話入力がある**（トランザクション表の `[y/N]` と Trivy の鍵の確認）。答えてから次の手順を貼る
> - **手順 10 で dive の画面（TUI）が開く**。`q` で終了する

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 日々の操作は[使い方の基本](#使い方の基本)、以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **x86_64 のコンテナでのみ検証した手順書**で、実機では本実行していない。dive の画面は、表示された文字を読み取って確かめただけで、見た目と操作は確かめていない（[対象と検証環境](#対象と検証環境)）。

1. brew で hadolint と dive を入れる。

   ```bash
   brew install hadolint dive
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - hadolint は `gmp` など 4 つの依存を連れてくる（Haskell 製のため）。dive に依存は無い
   - **次の手順は、確認が出たら答え、インストールが終わってシェルのプロンプトに戻ってから貼る**（依存の追加を確認する `[y/n]` が出る版では、続けて貼ると回答として食われる）

   <details>
   <summary>補足: ボトルと依存</summary>

   x86_64 で降ってきたボトルは `hadolint--2.15.1.x86_64_linux.bottle.tar.gz` と `dive--0.13.1.x86_64_linux.bottle.2.tar.gz`。依存を含めて 5 秒ほどで入った。

   ```
   $ brew deps --tree hadolint dive
   dive
   hadolint
   ├── gmp
   ├── zlib-ng-compat
   ├── libffi
   └── xz
   ```

   </details>

1. hadolint と dive が入ったか確かめる。

   ```bash
   hadolint --version
   dive --version
   command -v hadolint dive
   ```

   - `Haskell Dockerfile Linter 2.15.1` と `dive 0.13.1` が出る
   - どちらも `/home/linuxbrew/.linuxbrew/bin/` の下にある

1. Trivy の公式 dnf リポジトリを登録し、ファイルと版を確かめてから Trivy を入れる。

   ```bash
   {
     sudo tee /etc/yum.repos.d/trivy.repo >/dev/null <<'EOF'
   [trivy]
   name=Trivy repository
   baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$basearch/
   gpgcheck=1
   enabled=1
   gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
   EOF
     cat /etc/yum.repos.d/trivy.repo
     dnf -q list --showduplicates trivy
     sudo dnf install trivy
   }
   ```

   - 中身は Trivy の公式の導入手順（RHEL/CentOS）と同じ
   - `<<'EOF'` と引用符を付けているので、`$basearch` はそのままファイルに書かれ、dnf が `x86_64` / `aarch64` に置き換える
   - ファイルに `gpgcheck=1` があることを確かめる
   - 版は `trivy.x86_64  0.74.0-1  trivy` のように出る
   - 初回は署名鍵の取り込みを 1 回聞かれる
   - fingerprint が `825A D903 6F7C 850E 6A6F ED49 35B8 ACA4 4FD9 CA9F`（`trivy-repo <oss@aquasec.com>`）であることを確かめてから `y` と答える。違っていれば `N` で中断する
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 鍵と、EPEL の Trivy との関係</summary>

   鍵の取り込みの実測:

   ```
   Importing GPG key 0x4FD9CA9F:
    Userid     : "trivy-repo <oss@aquasec.com>"
    Fingerprint: 825A D903 6F7C 850E 6A6F ED49 35B8 ACA4 4FD9 CA9F
    From       : https://aquasecurity.github.io/trivy-repo/rpm/public.key
   Is this ok [y/N]: y
   Key imported successfully
   ```

   - この鍵は rsa4096（2026-04-16 作成、2029-04-15 まで）で、自己署名のハッシュは SHA-256（`gpg --list-packets` の `digest algo 8`）。EL10 の rpm が取り込まない SHA-1 の鍵（[ツール一覧の注意点](tool-catalog.md#注意点)）ではない
   - 入るのは `trivy` 1 つで、ダウンロード 48 MB、展開後 161 MB（Go の静的バイナリ）

   EPEL にも `trivy` がある（0.64.1）。EPEL を有効にした状態で確かめた:

   - `dnf -q list --showduplicates trivy` には、EPEL の `0.64.1-2.el10_1` と公式の `0.74.0-1` の両方が出た
   - 公式の 0.74.0 を入れた後の `sudo dnf upgrade trivy` は `Nothing to do.`（古い EPEL の版には下がらない）

   </details>

1. Trivy が入ったか確かめる。

   ```bash
   trivy --version
   command -v trivy
   rpm -q trivy
   ```

   - 1 行目が `Version: 0.74.0` で、`/usr/bin/trivy` と `trivy-0.74.0-1.x86_64` が出る
   - RPM なので、Homebrew の 2 つと違い、何も足さずに root の PATH にも入っている

1. わざと欠陥のある Containerfile を hadolint に渡し、指摘が出ることを確かめる。

   ```bash
   printf 'FROM registry.access.redhat.com/ubi10/ubi-minimal\nRUN microdnf install -y httpd\n' | hadolint -; echo "rc=$?"
   ```

   - `DL3006`・`DL3040`・`DL3041` の 3 つの `warning` と、`rc=1` が出ればよい
   - 末尾の `-` は、標準入力の Containerfile を読む指定

   <details>
   <summary>補足: 出た指摘の意味</summary>

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

   </details>

1. 確認用の Containerfile とページを置き、hadolint が何も指摘しないことを確かめる。

   ```bash
   mkdir -p ~/image-check
   echo 'hello from image-check' > ~/image-check/index.html
   cat > ~/image-check/Containerfile <<'EOF'
   FROM registry.access.redhat.com/ubi10/httpd-24:10.1
   COPY index.html /var/www/html/index.html
   EOF
   hadolint ~/image-check/Containerfile; echo "rc=$?"
   ```

   - 何も出ずに `rc=0` ならよい
   - `ubi10/httpd-24`（Apache）に、ページを 1 つ足すだけのイメージ

1. イメージを作る。

   ```bash
   podman build -t localhost/image-check:1 ~/image-check
   podman images localhost/image-check
   ```

   - `Successfully tagged localhost/image-check:1` が出る
   - `podman images` に `localhost/image-check  1` の行が出る（283 MB）
   - `podman build` は podman に入っている。buildah を別に入れる必要は無い

1. dive の判定のモード（`--ci`）で、イメージの無駄を数える。

   ```bash
   dive --source podman --ci localhost/image-check:1; echo "rc=$?"
   ```

   - `Image Source: podman://localhost/image-check:1` が出れば、podman のイメージを直接読めている
   - `efficiency: 85.4470 %` と `wastedBytes: 58951134 bytes (59 MB)` が出る
   - **既定の基準では `Result:FAIL` と `rc=1` になる**。無駄の元はベースイメージの層で、手順 6 の `COPY` の層ではない（この手順の補足）

   <details>
   <summary>補足: FAIL の理由と、判定の基準</summary>

   `--ci` の既定の基準は 3 つで、この 2 つに引っかかった:

   ```
   FAIL: highestUserWastedPercent: too many bytes wasted, relative to the user bytes added (%-user-wasted-bytes=0.9379853861664853 > threshold=0.1)
   SKIP: highestWastedBytes: rule disabled
   FAIL: lowestEfficiency: image efficiency is too low (efficiency=0.8544699280688606 < threshold=0.9)
   Result:FAIL [Total:3] [Passed:0] [Failed:2] [Warn:0] [Skipped:1]
   ```

   - `Inefficient Files:` の上位は `/usr/lib/sysimage/rpm/rpmdb.sqlite`（3 回、46 MB）と `/var/lib/dnf/history.sqlite-wal`（3 回、12 MB）
   - `ubi10/httpd-24` は、ベース → s2i-core → httpd の 3 つの層でパッケージを入れていて、層ごとに rpm のデータベースが書き直されている
   - 自分の層（`COPY` で 3.58 kB）が小さいので、「自分が足した量に対する無駄」の割合が大きく出る

   層が 1 つの `quay.io/almalinuxorg/10-minimal:10.2` に `COPY` を 1 つ足しただけのイメージでは、`efficiency: 100.0000 %` で `Result:PASS` だった。

   - 基準は `--lowestEfficiency` などのオプションか、リポジトリに置く `.dive-ci` で変えられる（`dive --help`）
   - `--source podman` の dive は podman のコマンド（`podman image save`）でイメージを取り出すので、API ソケットは要らない

   </details>

1. Trivy で、イメージの脆弱性を調べる。

   ```bash
   trivy image --image-src podman --severity HIGH,CRITICAL localhost/image-check:1
   ```

   - 初回は脆弱性のデータベース（117.64 MiB）を落とす
   - `Detected OS  family="redhat" version="10.1"` の後に、`Report Summary` の表が出る
   - 検証では `Vulnerabilities` が `0` だった（結果は、データベースの日付とイメージの中身で変わる）

   <details>
   <summary>補足: データベースと、ソケットが止まっているとき</summary>

   データベースは `mirror.gcr.io/aquasec/trivy-db:2` から落ち、`~/.cache/trivy` に置かれる（展開後 1.4 GB）。

   `--image-src podman` の Trivy は、[podman.md 手順 7](podman.md#実施手順) の API ソケットでイメージを読む。ソケットを止めた状態での実測:

   ```
   FATAL	Fatal error	run error: image scan error: ... unable to find the specified image "localhost/image-check:1" in ["podman"]: 1 error occurred:
   	* podman error: unable to inspect the image (localhost/image-check:1): http error: Get "http://podman/images/localhost/image-check:1/json": dial unix /run/user/<UID>/podman/podman.sock: connect: connection refused
   ```

   - 見つかったときに終了コードを 1 にしたい（スクリプトで止めたい）ときは `--exit-code 1` を付ける
   - `--severity` を外すと、LOW・MEDIUM も含めて全部出る（検証のイメージでは、それでも `0` だった）

   </details>

1. dive の画面で、層の中身を見る。

   ```bash
   dive --source podman localhost/image-check:1
   ```

   - 左に `Layers`（層の一覧）と `Image Details`、右に `Current Layer Contents`（その層のファイルの木）が出る
   - `Image Details` の `Image efficiency score: 85 %` と `Potential wasted space: 59 MB` は、手順 8 と同じ値
   - いちばん下の行に、キーの案内（`Quit`・`Tab Switch view`・`^F Filter` など）が出る
   - `q` で終了する
   - **後ろの節の手順は、`q` で終了してから貼る**（続けて貼ると dive への操作として食われる）

---

## 使い方の基本

| コマンド | 用途 |
|---|---|
| `hadolint <Containerfile>` | Containerfile（Dockerfile）の書き方を検査する |
| `hadolint --ignore <規則> <Containerfile>` | 特定の規則を外して検査する |
| `dive --source podman <イメージ>` | 層ごとの中身と無駄を画面で見る |
| `dive --source podman --ci <イメージ>` | 無駄の量を基準で判定する（`PASS` / `FAIL` と終了コード） |
| `trivy image --image-src podman <イメージ>` | 手元の podman のイメージの脆弱性を調べる |
| `trivy image <レジストリのイメージ>` | 手元に取らずに、レジストリのイメージを調べる |
| `trivy config <ディレクトリ>` | Containerfile などの設定の問題を調べる |

- `trivy image registry.access.redhat.com/ubi10/ubi-minimal:latest --severity CRITICAL` は、手元に取らずに `redhat 10.2` と判定し、`0` を返した
- 確認用の Containerfile に `trivy config ~/image-check` を使うと、hadolint が何も言わなかったのに対して、2 つが出た
  - `DS-0002 (HIGH)`: `USER` が無い（ベースイメージが root 以外で動くことは見ていない）
  - `DS-0026 (LOW)`: `HEALTHCHECK` が無い

---

## 更新

1. hadolint と dive を更新する。

   ```bash
   brew upgrade hadolint dive
   ```

   - 新しい版が無ければ `Warning: hadolint 2.15.1 already installed` のように出て、何もしない
   - すべてまとめて上げるなら `brew upgrade`

1. Trivy を更新する。

   ```bash
   sudo dnf upgrade trivy
   ```

   - 更新があると `[y/N]` で聞かれる。無ければ `Nothing to do.` で終わる
   - 脆弱性のデータベースは別もので、`trivy image` が古いと判断したときに取り直す（検証では初回に `Need to update DB` と出て取得した）

---

## ロールバック

- 上から順に実行する

1. 確認用のイメージとファイルを消す。

   ```bash
   podman rmi localhost/image-check:1 registry.access.redhat.com/ubi10/httpd-24:10.1
   rm -rf ~/image-check
   ```

1. Trivy のデータベースを消す。

   ```bash
   rm -rf ~/.cache/trivy
   ```

   - 1.4 GB 空く

1. hadolint と dive を消す。

   ```bash
   brew uninstall hadolint dive
   ```

   - 依存として入った `gmp` など 4 つも、ほかに使うものが無ければ一緒に消える（`==> Autoremoving 4 unneeded formulae:`）

1. Trivy を消す。

   ```bash
   sudo dnf remove trivy
   ```

   - `[y/N]` で聞かれる
   - **次の手順は、答えて完了してから貼る**（続けて貼ると答えとして食われる）

1. Trivy のリポジトリの登録と、取り込んだ鍵を消して、消えたか確かめる。

   ```bash
   {
     sudo rm /etc/yum.repos.d/trivy.repo && sudo rpm -e gpg-pubkey-4fd9ca9f-69e0b811
     rpm -q gpg-pubkey --qf '%{NAME}-%{VERSION}-%{RELEASE}\t%{SUMMARY}\n'
   }
   ```

   - `gpg-pubkey-4fd9ca9f-69e0b811` は、[実施手順](#実施手順)の手順 3 で取り込まれた鍵の名前（検証で確かめた値）
   - 一覧から `trivy-repo <oss@aquasec.com>` の行が消えていればよい

---

## 補足

### 対象と検証環境

- **目的**: コンテナイメージを作るときの検査の道具を 3 つそろえる
  - hadolint: Containerfile の書き方
  - dive: 層ごとの中身と無駄
  - Trivy: 脆弱性と設定の問題
- **進め方**: hadolint と dive は Homebrew、Trivy は公式の dnf リポジトリから入れる（[選択した方針](#選択した方針)）。確認用のイメージを 1 つ作って、3 つを当てる。**読者が書き換える変数は無い**
- **状態**: **x86_64 のコンテナでのみ検証済み（2026-09-27）。実機では本実行していない**
  - 下表の検証コンテナで、[podman.md](podman.md) の実施手順と [Homebrew の導入](homebrew.md)を通したうえで、**この文書のコードブロックをそのまま端末に流して**、手順 1〜10、[更新](#更新)、[ロールバック](#ロールバック)を通した
  - 確認したこと:
    - 3 つが入り、hadolint が欠陥を指摘する
    - dive が podman のイメージを直接読み、判定と画面を出す
    - Trivy が API ソケット経由でイメージを読み、データベースを取得して結果の表を出す
  - **確認していないこと**: dive の画面の見た目と操作（表示された文字を読み取っただけ）、脆弱性が見つかるイメージでの Trivy の出力
  - aarch64（Raspberry Pi 5）では通していない
  - 2026-10-02: もとの手順 3・4 と、[ロールバック](#ロールバック)のもとの手順 5・6 をつないで `{ … }` で囲んだ（つないだ形は貼っていない。`bash -n` だけ）

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-27 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/10-init:10.2`、Docker 29.3.1、`--privileged`。[podman.md](podman.md) と同じ作り） |
| podman | 未確認 | `podman-5.8.2-9.el10_2.alma.1`（[podman.md](podman.md) の実施手順で導入） |
| Homebrew | 未確認 | 7.0.6（[homebrew.md](homebrew.md) の手順 1〜4 で導入） |
| hadolint / dive | 未導入 | 2.15.1 / 0.13.1（`x86_64_linux` のボトル） |
| Trivy | 未導入 | `trivy-0.74.0-1`（公式の dnf リポジトリ） |
| 端末 | — | pty（160 桁 × 50 行、`TERM=xterm-256color`） |

> [!NOTE]
> 出力例の値は `<USER>` / `<UID>` / `<HOSTNAME>` のプレースホルダで書いてある。バージョン（`2.15.1`・`0.13.1`・`0.74.0`）、イメージの大きさ、脆弱性の数は実行日によって変わる。**鍵の fingerprint は公開情報なので本文に書いてある。**

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（[podman.md](podman.md) の実施手順と Homebrew の導入の後）の状態:

| 項目 | 状態 |
|---|---|
| podman | 5.8.2。API ソケットは `active` |
| Homebrew | 7.0.6（`brew leaves` は空） |
| hadolint / dive / Trivy | 未導入 |
| EPEL | 未設定（本書では使わない） |

### 選択した方針

| ツール | 経路 | 理由 |
|---|---|---|
| hadolint | **Homebrew（2.15.1）** | AppStream にも EPEL にも無い。公式のコンテナイメージで動かす方法もあるが、検査のたびにコンテナを起動することになる |
| dive | **Homebrew（0.13.1）** | RPM のリポジトリが無い（上流は GitHub に rpm を置いているだけで、`dnf upgrade` に乗らない） |
| Trivy | **公式の dnf リポジトリ（0.74.0）** | Homebrew と同じ版なので、[ツール一覧の選び方](tool-catalog.md#選び方)の規則 1 で RPM にした。EPEL は 0.64.1 と古い |
| syft / grype（SBOM と脆弱性） | 対象外 | Trivy と役割が重なる |

- 3 つの経路が混ざるので、更新も `brew upgrade` と `sudo dnf upgrade` の 2 つになる（[更新](#更新)）
- Trivy だけ RPM なので、`sudo trivy` がそのまま動く。hadolint と dive は Homebrew なので、root で使うなら [homebrew.md の sudo でも使う](homebrew.md#sudo-でも使う任意)の節を通すか、フルパスで呼ぶ

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

### 注意点

- **dive の `--ci` の既定の基準は厳しい**: ベースイメージの層の無駄も数えるので、よく使われるイメージを元にしただけで `FAIL` になる（手順 8 の補足）。CI で使うなら、基準を自分で決めて `.dive-ci` に書く
- **Trivy の結果は日によって変わる**: データベースは新しい脆弱性が見つかるたびに更新される。同じイメージでも、後日の結果は変わりうる
- **Trivy のデータベースは大きい**: `~/.cache/trivy` が 1.4 GB になった。要らなくなったら[ロールバック](#ロールバック)の手順 2 で消す
- **Trivy の `--image-src podman` は API ソケットが要る**: [podman.md 手順 7](podman.md#実施手順) のソケットが止まっていると、手順 9 の補足のエラーになる
- **hadolint と Trivy の設定の検査は、見るところが違う**: 確認用の Containerfile は hadolint では指摘が無く、`trivy config` では `USER` と `HEALTHCHECK` が無いことを指摘された（[使い方の基本](#使い方の基本)）
- **Homebrew の 2 つは、そのままでは `sudo` の PATH に無い**（[homebrew.md の注意点](homebrew.md#注意点)）: root で使うなら、[homebrew.md の sudo でも使う](homebrew.md#sudo-でも使う任意)の節を通すか、`/home/linuxbrew/.linuxbrew/bin/hadolint` のようにフルパスで呼ぶ

### 参照

- [hadolint — README](https://github.com/hadolint/hadolint) — 規則の一覧、`--ignore`、設定ファイル（`~/.config/hadolint.yaml`）
- [dive — README](https://github.com/wagoodman/dive) — `--source`、`--ci` と `.dive-ci`、キー操作
- [Trivy — Installation](https://trivy.dev/docs/latest/getting-started/installation/) — RHEL/CentOS の公式 dnf リポジトリの登録
- [Trivy — Container Image](https://trivy.dev/docs/latest/guide/target/container_image/) — `--image-src`（podman は API ソケットを使う）
- [Homebrew](homebrew.md) / [Podman](podman.md) — 前提の手順書

---

### 付録: コンテナでの検証記録（2026-09-27）

**環境**: [podman.md の付録](podman.md#付録-コンテナでの検証記録2026-09-27)と同じ作りの使い捨てのコンテナ。実機で加えた変更は無い。

- `quay.io/almalinuxorg/10-init:10.2` で systemd を PID 1 にし（`--privileged`）、SSH でログインした
- 同じ SSH のセッションで、先に podman.md の手順 1〜3・5〜7 と [homebrew.md](homebrew.md) の手順 1〜4 を流した

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

**最初の試行で見つけて直したこと**: [ロールバック](#ロールバック)の手順 5 は、はじめ `sudo rm`・`sudo rpm -e`・`rpm -q` の 3 行だった。

- 1 行ずつ流すと、`sudo` が後ろの 2 行を端末の入力として取り込み、2 行目以降が実行されなかった
- EL10 の sudo 1.9.17 は、既定でコマンドを擬似端末の中で動かす（`sudo -V` の `Always run commands in a pseudo-tty`）
- `&&` でつないだ 1 行と、確かめる手順に分けた

**別に確かめたこと**（同じ作りの別のコンテナで、手順書の外のコマンドとして実行）:

- `latest` のタグで DL3007、`--ignore DL3041` で DL3041 が消えること
- 層が 1 つの `quay.io/almalinuxorg/10-minimal:10.2` を元にしたイメージでは、`dive --ci` が `efficiency: 100.0000 %` で `Result:PASS`
- EPEL を有効にした状態の `dnf -q list --showduplicates trivy`（手順 3 の補足）
- API ソケットを止めた状態の `trivy image --image-src podman`（手順 9 の補足）
- `trivy image` でレジストリのイメージを直接調べること、`trivy config`（[使い方の基本](#使い方の基本)）
- 鍵の自己署名のハッシュ（`gpg --list-packets` の `digest algo 8`）

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での実行と、aarch64 での実行
- dive の画面の見た目と、キー操作（`q` で終わること以外）
- 脆弱性が見つかるイメージでの Trivy の出力と `--exit-code 1`
- `.dive-ci` での基準の変更
- `~/.config/hadolint.yaml` での設定
- Trivy のデータベースが古くなったときの自動の取り直し
