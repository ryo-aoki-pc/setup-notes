# hadolint / dive / Trivy インストール手順（AlmaLinux 10 / Homebrew + Trivy 公式 dnf リポジトリ）

## 実施手順

- [検証記録](verification/image-tools.md)・[参考資料](reference/image-tools.md)

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) と、[Podman](podman.md) の実施手順（手順 7 の API ソケットまで）を通してあること。`command -v brew podman` が 2 行を返し、`systemctl --user is-active podman.socket` が `active` を返さなければ、先に通す
> - **自分のユーザーでログインしたシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、イメージも自分のユーザーの podman に作るため）
> - **手順 3 には対話入力がある**（トランザクション表の `[y/N]` と Trivy の鍵の確認）。答えてから次の手順を貼る
> - **手順 10 で dive の画面（TUI）が開く**。`q` で終了する

- 上から順にコードブロックを貼る
- 手順の後: 日々の操作は[使い方の基本](#使い方の基本)、以後は[更新](#更新)・[ロールバック](#ロールバック)

1. brew で hadolint と dive を入れる。

   ```bash
   brew install hadolint dive
   ```

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - hadolint は `gmp` など 4 つの依存を連れてくる（Haskell 製のため）。dive に依存は無い
   - **次の手順は、確認が出たら答え、インストールが終わってシェルのプロンプトに戻ってから貼る**（依存の追加を確認する `[y/n]` が出る版では、続けて貼ると回答として食われる）

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
   - **既定の基準では `Result:FAIL` と `rc=1` になる**。無駄の元はベースイメージの層で、手順 6 の `COPY` の層ではない（参考資料を参照）

1. Trivy で、イメージの脆弱性を調べる。

   ```bash
   trivy image --image-src podman --severity HIGH,CRITICAL localhost/image-check:1
   ```

   - 初回は脆弱性のデータベース（117.64 MiB）を落とす
   - `Detected OS  family="redhat" version="10.1"` の後に、`Report Summary` の表が出る
   - 脆弱性の結果は、データベースの日付とイメージの中身で変わる

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
   - 脆弱性のデータベースは別もので、`trivy image` が古いと判断したときに取り直す

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

   - Trivy のキャッシュも消す場合は、キャッシュの置き場所を確かめてから削除する

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

   - 一覧から `trivy-repo <oss@aquasec.com>` の行が消えていればよい

---

## 注意点

- **dive の `--ci` の既定の基準は厳しい**: ベースイメージの層の無駄も数えるので、よく使われるイメージを元にしただけで `FAIL` になる（参考資料を参照）。CI で使うなら、基準を自分で決めて `.dive-ci` に書く
- **Trivy の結果は日によって変わる**: データベースは新しい脆弱性が見つかるたびに更新される。同じイメージでも、後日の結果は変わりうる
- Trivy のキャッシュも消す場合は、キャッシュの置き場所を確かめてから削除する
- **Trivy の `--image-src podman` は API ソケットが要る**: [podman.md 手順 7](podman.md#実施手順) のソケットが止まっていると、手順 9 の補足のエラーになる
- **hadolint と Trivy の設定の検査は、見るところが違う**: 確認用の Containerfile は hadolint では指摘が無く、`trivy config` では `USER` と `HEALTHCHECK` が無いことを指摘された（[使い方の基本](#使い方の基本)）
- **Homebrew の 2 つは、そのままでは `sudo` の PATH に無い**（[homebrew.md の注意点](homebrew.md#注意点)）: root で使うなら、[homebrew.md の sudo でも使う](homebrew.md#sudo-でも使う任意)の節を通すか、`/home/linuxbrew/.linuxbrew/bin/hadolint` のようにフルパスで呼ぶ
