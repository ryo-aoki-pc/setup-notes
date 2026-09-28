# VirtualBox インストール手順（AlmaLinux 10 / Oracle 公式 dnf リポジトリ）

## 実施手順

> [!IMPORTANT]
> - **対象ホスト（x86_64 の PC）上で実行する**。VirtualBox には Linux の arm64 版が無いので、Raspberry Pi 5（aarch64）には入らない
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない
> - **途中で再起動が 1 回（Secure Boot が有効なら 2 回）入る**（手順 24 と、Secure Boot なら手順 16）。再起動した後は新しい端末を開いて続ける
> - **手順 8・9・15・18 には対話入力がある**（鍵の確認・一時パスワード・`[y/N]`）。答えてから次の手順を貼る
> - **手順 28 で GUI のウィンドウが開く**（デスクトップにログインした端末から行う）。閉じてから手順 29 を貼る

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: カーネルを更新したときは[カーネルを更新したとき](#カーネルを更新したとき)、以後の VirtualBox の更新は[更新](#更新)、戻すときは[ロールバック](#ロールバック)

> [!WARNING]
> **x86_64 のコンテナでのみ検証した手順書**で、実機には入れていない（[対象と検証環境](#対象と検証環境)）。
>
> - `uname -r` と `mokutil` はスタブにした
> - モジュールの読み込み・MokManager での鍵の登録・VM の起動・GUI の表示などは確かめていない

1. この PC に入るかを確かめる。

   ```bash
   uname -m
   lscpu | grep -E '^Virtualization:' || echo 'CPU の仮想化支援が見えない'
   ```

   - `uname -m` が `x86_64` で、`Virtualization:` の行に `VT-x`（Intel）か `AMD-V`（AMD）が出ればよい
   - **`aarch64` なら VirtualBox は入らないので、ここで止める**
   - `CPU の仮想化支援が見えない` と出たら、PC の UEFI（BIOS）の設定で Intel VT-x / AMD-V（SVM）を有効にしてから始める

   <details>
   <summary>補足: コンテナでの表示</summary>

   検証コンテナでは `lscpu` に `Virtualization:` の行が出なかった（コンテナを動かしているクラウドのホストに仮想化支援が無い）。**VT-x / AMD-V がある PC での `lscpu` の表示は確かめていない**（[未確認事項](#未確認事項)）。

   </details>

1. 依存の `liblzf` のために、EPEL が有効になっているか確かめる。

   ```bash
   dnf repolist enabled | grep -E '^epel' || echo 'EPEL は未設定'
   ```

   - VirtualBox が使うライブラリ `liblzf` は EPEL にしか無い（手順 3 の補足）
   - `epel` の行が出れば、手順 3 は飛ばす
   - `EPEL は未設定` と出たら、手順 3 で入れる

1. EPEL が未設定のときだけ、`epel-release` を入れる。

   ```bash
   sudo dnf install -y epel-release
   ```

   - AlmaLinux の `extras` リポジトリに入っているので、追加のリポジトリ設定は要らない
   - 最後に出る「CRB を有効にすることを推奨」は、AlmaLinux 10 では既定で有効なので気にしなくてよい（[tool-catalog.md](tool-catalog.md) の「導入経路と EL10 での注意」）
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: <code>liblzf</code> は EPEL にしか無い</summary>

   - Oracle の EL10 向け rpm は `liblzf.so.1()(64bit)` を要求するが、これを持つ `liblzf-3.6-28.el10_0` は **EPEL 10 にしかない**（BaseOS / AppStream / CRB / extras の一覧に無いことを確かめた）
   - ほかの依存（Qt 6、`libtpms`、`libvpx`、`vulkan-loader` など）は AppStream / BaseOS にある

   EPEL 無しで手順 10 の下見をしたときの実測:

   ```
   Error: 
    Problem: cannot install the best candidate for the job
     - nothing provides liblzf.so.1()(64bit) needed by VirtualBox-7.2-7.2.20_175154_el10-1.x86_64 from virtualbox
   ```

   EPEL の鍵は、最初に EPEL のパッケージを入れるとき（手順 18）に `/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10` から取り込まれる（[btop.md](btop.md) 手順 2 の補足と同じ）。

   </details>

1. EPEL が有効になったか確かめる。

   ```bash
   rpm -q epel-release
   dnf repolist enabled | grep -E '^epel'
   ```

   - `epel-release` の版と、`epel` の行が出れば有効になっている

1. Oracle の署名鍵を落として、取り込む前に fingerprint を見る。

   ```bash
   curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc -o /tmp/oracle_vbox_2016.asc
   gpg --show-keys --with-fingerprint /tmp/oracle_vbox_2016.asc
   ```

   - `gpg` が無ければ、`sudo dnf install -y gnupg2` で入れてから貼り直す（GNOME のデスクトップには入っている）
   - 次の値と一致することを目で確かめる
     - fingerprint `B9F8 D658 297A F3EF C18D 5CDF A2F6 83C5 2980 AECF`
     - uid `Oracle Corporation (VirtualBox archive signing key) <info@virtualbox.org>`
   - 違っていればここで止める
   - **次の手順は、fingerprint と uid が一致するのを確かめてから貼る**

1. 一致したら、鍵を rpm に取り込む。

   ```bash
   sudo rpm --import /tmp/oracle_vbox_2016.asc
   ```

   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 鍵は EL10 の rpm に受け入れられる</summary>

   `gpg --show-keys` の実測（鍵束には取り込まれない。`~/.gnupg` が無ければ最初の実行で作られる）:

   ```
   pub   rsa4096 2016-04-22 [SC]
         B9F8 D658 297A F3EF C18D  5CDF A2F6 83C5 2980 AECF
   uid                      Oracle Corporation (VirtualBox archive signing key) <info@virtualbox.org>
   sub   rsa4096 2016-04-22 [E]
   ```

   - **自己署名のハッシュは SHA-512**（`gpg --list-packets` で `digest algo 10`）なので、EL10 の rpm が SHA-1 の自己署名を拒む問題（[tool-catalog.md の注意点](tool-catalog.md#注意点)）には当たらず、`rpm --import` は何も出さずに終了コード 0 で終わった
   - 7.2.20 の EL10 向け rpm の署名と、リポジトリのメタデータの署名（`repomd.xml.asc`）は、どちらもこの鍵（`A2F683C52980AECF`、SHA-256）で作られていた（rpm のヘッダとメタデータを直接読んで確認）

   Oracle は 2010 年の古い鍵 `oracle_vbox.asc`（dsa1024）も配っているが、これは古いパッケージ用で、本書では使わない。

   </details>

1. 鍵が入ったか確かめ、落としたファイルを消す。

   ```bash
   rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i virtualbox
   rm -f /tmp/oracle_vbox_2016.asc
   ```

   - `gpg-pubkey-2980aecf-5719f4e1 Oracle Corporation (VirtualBox archive signing key) ...` が出れば入っている

1. repo ファイルを置き、`sudo` の dnf でメタデータの鍵を受け入れる。

   ```bash
   {
     sudo tee /etc/yum.repos.d/virtualbox.repo >/dev/null <<'EOF'
   [virtualbox]
   name=Oracle VirtualBox for EL$releasever - $basearch
   baseurl=https://download.virtualbox.org/virtualbox/rpm/el/$releasever/$basearch
   enabled=1
   gpgcheck=1
   repo_gpgcheck=1
   gpgkey=https://www.virtualbox.org/download/oracle_vbox_2016.asc
   EOF
     cat /etc/yum.repos.d/virtualbox.repo
     sudo dnf makecache --repo virtualbox
   }
   ```

   - ヒアドキュメントは `<<'EOF'`（クォート付き）。`$releasever` / `$basearch` は dnf が展開するので、シェルに展開させない
   - このリポジトリは**メタデータにも署名がある**（`repo_gpgcheck=1`）
   - dnf はそれを確かめるための鍵を rpm とは別に持つので、最初の 1 回だけ鍵の取り込みを聞かれる
   - `Importing GPG key 0x2980AECF:` の `Fingerprint:` が、手順 5 と同じ `B9F8 D658 297A F3EF C18D 5CDF A2F6 83C5 2980 AECF` であることを確かめて `y` と答える
   - `Metadata cache created.` で終わる
   - **次の手順は、鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: repo ファイルは Oracle 公式のものとほぼ同じ</summary>

   **repo ファイルは Oracle 公式のもの（`https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo`）とほぼ同じ**。

   - 変えたのは、`baseurl` の `http://` を `https://` にしたこと（同じホストが HTTPS でも応答する）と、`name` だけ
   - `gpgcheck` / `repo_gpgcheck` / `gpgkey` は公式どおり
   - `$releasever` は AlmaLinux 10 では `10` に展開される（dnf の設定を Python から読んで確認）ので、`.../rpm/el/10/x86_64` を見に行く
   - `.../rpm/el/10/aarch64/` は 404 を返す

   </details>

1. `sudo` を付けない dnf にも、同じ鍵の確認を 1 回だけ通す。

   ```bash
   dnf makecache --repo virtualbox
   ```

   - こちらはユーザーごとの別のキャッシュを使う
   - 通しておかないと、`sudo` を付けない `dnf list` などが**関係の無いパッケージでも**失敗する（この手順の補足）
   - 手順 8 と同じ fingerprint を確かめて `y` と答える
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 鍵の確認が 2 回要る理由</summary>

   `repo_gpgcheck=1` のリポジトリでは、dnf はメタデータの署名を**リポジトリごとの鍵束**で確かめる。

   - この鍵束は rpm のデータベース（手順 6 の `rpm --import`）とは別物
   - root の dnf は `/var/cache/dnf/virtualbox-<ハッシュ>/pubring`、`sudo` を付けない dnf はユーザーのキャッシュ（`/var/tmp/dnf-<USER>-<ランダム>/`）に持つ
   - どちらも最初に使うときに鍵の取り込みを聞き、**答えないと（`--assumeno` で断っても）メタデータ全体の読み込みに失敗する**

   実測（`sudo` 無しで、無関係な `tmux` を調べた場合）:

   ```
   $ dnf -q list --showduplicates tmux
   Importing GPG key 0x2980AECF:
    Userid     : "Oracle Corporation (VirtualBox archive signing key) <info@virtualbox.org>"
    Fingerprint: B9F8 D658 297A F3EF C18D 5CDF A2F6 83C5 2980 AECF
    From       : https://www.virtualbox.org/download/oracle_vbox_2016.asc
   Is this ok [y/N]: Error: Failed to download metadata for repo 'virtualbox': repomd.xml GPG signature verification error: Signing key not found
   ```

   - `sudo dnf makecache` の前に `sudo dnf install --assumeno` を実行したときも、同じ `Signing key not found` で止まった
   - ユーザー側で 1 回 `y` と答えた後は、`dnf -q list --showduplicates tmux` が普通に結果を返した
   - **ユーザー側のキャッシュは `/var/tmp` にあり、30 日使わないと systemd-tmpfiles に消される**（`/usr/lib/tmpfiles.d/tmp.conf` の `q /var/tmp 1777 root root 30d`）ので、そのときはまた聞かれる
   - ほかのユーザーがこの PC で `sudo` 無しの dnf を使うときも、それぞれ 1 回聞かれる

   ほかの手順書のリポジトリ（[firefox.md](firefox.md) / [claude-code.md](claude-code.md) など）はメタデータに署名が無く `repo_gpgcheck` を使っていないので、この 2 回の確認は本書だけの手順になる。

   </details>

1. 何が入るかを見る（`--assumeno` は必ず中断する）。

   ```bash
   sudo dnf install --assumeno VirtualBox-7.2
   ```

   - `VirtualBox-7.2 ... 7.2.20_175154_el10-1 ... virtualbox ... 105 M` と、依存の中に `liblzf ... epel` が出れば解決できている
   - `nothing provides liblzf.so.1()(64bit)` と出たら、手順 2〜4 が済んでいない

   <details>
   <summary>補足: パッケージ名と下見の結果</summary>

   **パッケージ名に系列（7.2）が入っている**（Oracle のリポジトリでの名前）。

   - 系列の無い `VirtualBox` という名前は無く、`sudo dnf install --assumeno VirtualBox` は `No match for argument: VirtualBox` で終わる（実測）
   - 調査日（2026-09-24）のリポジトリには `VirtualBox-7.2`（7.2.0〜7.2.20）と `VirtualBox-7.1`（7.1.10〜7.1.18）がある
   - **7.1 と 7.2 は同時には入れられない**（[更新](#更新)）。本書は 7.2 だけを検証している

   **下見の結果**（素のコンテナ。デスクトップの PC では多くが入っているので、数はずっと少ないはず。未確認）:

   ```
   Installing:
    VirtualBox-7.2             x86_64  7.2.20_175154_el10-1      virtualbox  105 M
   Installing dependencies:
    alsa-lib                   x86_64  1.2.15.3-2.el10           appstream   517 k
    ...
    liblzf                     x86_64  3.6-28.el10_0             epel         28 k
    ...
    qt6-qtbase                 x86_64  6.10.1-1.el10.alma.1      appstream   4.2 M
    ...
   Transaction Summary
   Install  89 Packages
   Total download size: 223 M
   Installed size: 719 M
   ```

   - GUI は **AppStream の Qt 6**（6.10.1）を使う（rpm の要求は `Qt_6.9` の版の記号）
   - gcc や kernel-devel は依存に含まれないので、手順 12 で別に入れる

   </details>

1. 動いているカーネルが、入っている中で一番新しいものかを見る。

   ```bash
   uname -r
   rpm -q --last kernel-core | head -1
   ```

   - 2 つの版が同じならよい
   - **違っていれば（更新したカーネルでまだ起動していなければ）、再起動してから続ける**（この手順の補足）
   - **次の手順は、2 つの版が同じなのを確かめてから貼る**

   <details>
   <summary>補足: 動いているカーネルを最新にしておく理由</summary>

   `kernel-devel` は動いているカーネル（`uname -r`）と同じ版を入れ、モジュールもその版向けにビルドされる。更新済みのカーネルでまだ起動していないと、次の起動で新しいカーネル用のモジュールを作り直すことになる（[カーネルを更新したとき](#カーネルを更新したとき)）。

   </details>

1. カーネルモジュールのビルドに要るものを、VirtualBox より先に入れる。

   ```bash
   sudo dnf install -y gcc make perl-interpreter mokutil openssl "kernel-devel-$(uname -r)"
   ```

   - VirtualBox は、自分のカーネルモジュール（`vboxdrv` / `vboxnetflt` / `vboxnetadp`）を**インストールの途中で、この PC の上でビルドする**
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: なぜ先に入れるのか、何が要るのか</summary>

   **rpm のインストール後スクリプト（`%post`）が、その場でモジュールをビルドして読み込む。**

   - そのときに道具が無いと、ビルドは失敗するのに `dnf install` は `Complete!` で終わる（手順 18 の補足）
   - VirtualBox 自身の確認スクリプト（`/usr/lib/virtualbox/check_module_dependencies.sh`）が見ているのは、コマンドの `gcc` `make` `perl` と、`/lib/modules/$(uname -r)/build/include` の 2 点だけ

   道具が無いまま入れたときの実測（`%post` が標準エラーに出したもの）:

   ```
   This system is currently not set up to build kernel modules.
   Please install the gcc make perl packages from your distribution.
   Please install the Linux kernel "header" files matching the current kernel
   for adding new hardware support to the system.
   The distribution packages containing the headers are probably:
       kernel-devel kernel-devel-6.12.0-211.56.1.el10_2.x86_64
   ```

   **`perl` ではなく `perl-interpreter` にしてある。**

   - 確認スクリプトが見るのは、`perl` コマンドがあるかだけ
   - `perl`（メタパッケージ）は素のコンテナで 269 パッケージ・300 MB を連れてくるのに対し、`perl-interpreter` は 60 パッケージ・26 MB だった
   - `perl-interpreter` だけで、ビルドも、Secure Boot のときに vboxdrv.sh がモジュールの署名を確かめる処理（kernel-devel の `scripts/extract-module-sig.pl` と openssl。同じコマンドを手で流して `Verified OK`）も通った
   - `elfutils-libelf-devel` も要らなかった

   **`mokutil` と `openssl` は Secure Boot のときに要る。**

   - VirtualBox のスクリプト（`/usr/lib/virtualbox/vboxdrv.sh`）は **`mokutil --sb-state` の出力だけで Secure Boot を判定する**。mokutil が無いと Secure Boot が有効でも「無効」と扱い、署名していないモジュールを作る（読み込みは拒否される）
   - openssl は、手順 15 の鍵の作成と、スクリプトの署名の確認に使う
   - Secure Boot が無効でも、入れておいて害は無い

   **`kernel-devel` は installonly**（`installonlypkg(kernel)` を提供する）なので、`sudo dnf upgrade` で新しいカーネルが来ると、同じ版の kernel-devel が**古いものと並べて**入る。

   - 古い `kernel-devel` を入れた状態で `sudo dnf upgrade --assumeno kernel-devel` を実行し、新しい版が `Upgrading` ではなく `Installing` として出ることを確かめた
   - `/lib/modules/<版>/build` のリンクは kernel-devel ではなく、そのカーネルの `kernel-modules-core` が持っている（動いているカーネルなら必ず入っている）

   </details>

1. ビルドの道具がそろったか確かめる。

   ```bash
   rpm -q gcc make perl-interpreter mokutil openssl "kernel-devel-$(uname -r)"
   ls -d "/lib/modules/$(uname -r)/build/include"
   ```

   - 6 つとも版が出て、最後の行がディレクトリを返せばよい
   - `No such file or directory` なら、kernel-devel の版が合っていない

1. Secure Boot が有効かを見る。

   ```bash
   mokutil --sb-state
   ```

   - **`SecureBoot disabled`（または `EFI variables are not supported on this system`）なら、手順 15〜17 は飛ばす**
   - `SecureBoot enabled` のときだけ、手順 15〜17 でモジュールの署名鍵を登録する

1. Secure Boot が有効なときだけ、署名用の鍵を作り、MOK への登録を予約する。

   ```bash
   {
     sudo mkdir -m 0700 -p /var/lib/shim-signed/mok
     sudo openssl req -nodes -new -x509 -newkey rsa:2048 -outform DER -addext "extendedKeyUsage=codeSigning" -subj "/CN=VirtualBox module signing key/" -days 36500 -keyout /var/lib/shim-signed/mok/MOK.priv -out /var/lib/shim-signed/mok/MOK.der
     sudo ls -l /var/lib/shim-signed/mok
     sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
   }
   ```

   - 鍵を作る間は `.....+++` のような行が流れる
   - `MOK.priv`（秘密鍵。`-rw-------`）と `MOK.der`（公開鍵の証明書）ができる
   - **場所とファイル名は変えない**（VirtualBox のスクリプトがこの 2 つを決め打ちで使う）
   - 最後の `mokutil --import` で、公開鍵を UEFI の MOK に登録する予約をする
   - **一時パスワードを 2 回聞かれる**（次の起動の登録画面で 1 回だけ使う。本書には残さない）
   - **次の手順は、一時パスワードに答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: VirtualBox のスクリプトがこの鍵をどう使うか</summary>

   `/usr/lib/virtualbox/vboxdrv.sh` は、次の 2 つがそろうと、ビルドしたモジュールを **`/var/lib/shim-signed/mok/MOK.priv` と `MOK.der` で署名する**（道具は kernel-devel の `scripts/sign-file`）。

   - `mokutil --sb-state` が `SecureBoot enabled` を返す
   - カーネルの設定が署名を求める（EL10 のカーネルは `CONFIG_MODULE_SIG=y`・`CONFIG_LOCK_DOWN_IN_EFI_SECURE_BOOT=y`・`CONFIG_MODULE_SIG_HASH="sha512"`。kernel-devel の `.config` で確認）

   鍵が無いと、ビルドまでして署名で止まり、この案内を出す（`mokutil` を「Secure Boot 有効」と答えるスタブに差し替えたコンテナでの実測）:

   ```
   vboxdrv.sh: Signing VirtualBox kernel modules.
   vboxdrv.sh: failed: 

   System is running in Secure Boot mode, however your distribution
   does not provide tools for automatic generation of keys needed for
   modules signing. Please consider to generate and enroll them manually:

       sudo mkdir -m 0700 -p /var/lib/shim-signed/mok
       sudo openssl req -nodes -new -x509 -newkey rsa:2048 -outform DER -addext "extendedKeyUsage=codeSigning" -keyout /var/lib/shim-signed/mok/MOK.priv -out /var/lib/shim-signed/mok/MOK.der
       sudo mokutil --import /var/lib/shim-signed/mok/MOK.der
       sudo reboot

   Restart "rcvboxdrv setup" after system is rebooted
   ```

   本書の鍵の作り方は、この案内に **`-subj` と `-days` を足しただけ**。

   - 案内のままだと `Country Name (2 letter code) [XX]:` から始まる対話になり、有効期限も既定の 30 日になる（どちらも実測）
   - カーネルが署名の確認で証明書の期限を見るかは確かめていないので、100 年にしてある

   本書の鍵で作ったモジュールの実測（コンテナ）:

   ```
   $ modinfo -F signer /lib/modules/6.12.0-211.56.1.el10_2.x86_64/misc/vboxdrv.ko
   VirtualBox module signing key
   $ modinfo -F sig_hashalgo /lib/modules/6.12.0-211.56.1.el10_2.x86_64/misc/vboxdrv.ko
   sha512
   ```

   **インストールより先に登録しておく理由**: 鍵が登録済みなら、手順 18 の `%post` がビルド → 署名 → 読み込みまで一度に済ませる。

   - 登録前に入れると、鍵があっても読み込みで失敗し、`vboxdrv.sh: You must sign these kernel modules before using VirtualBox:` と `modprobe vboxdrv failed` が出る（スタブで「未登録」と答えさせたときの実測）
   - 登録の確認は、`mokutil --test-key` の出力に `is already` が含まれるかで見ている

   **登録した鍵は `.platform` キーリングに入る見込み。**

   - EL10 のカーネルは `CONFIG_INTEGRITY_CA_MACHINE_KEYRING=y`・`CONFIG_INTEGRITY_CA_MACHINE_KEYRING_MAX=y`
   - kernel-devel に入っている Kconfig の説明によれば、MOK の鍵のうち CA の条件（CA ビットと `keyCertSign`）を満たすものだけが `.machine` に入り、残りは `.platform` に入る
   - 本書の証明書は `CA:TRUE` だが `keyUsage` を持たない（`openssl x509 -text` で確認）ので、`.platform` 側になる
   - RHEL 10 のドキュメント（[参照](#参照)）は「モジュールを読み込むとき、カーネルは `.builtin_trusted_keys` と `.platform` の鍵で署名を確かめる。`.platform` には独自の公開鍵も入る」と書いており、登録後の確認に `keyctl list %:.platform`（`keyutils` パッケージ）を使っている

   **本書では実機で確かめていない。** 読み込めないときは、`sudo keyctl list %:.platform` に `VirtualBox module signing key` があるか、`sudo dmesg | grep -i vboxdrv` に `Key was rejected by service` が出ていないかを見る（[未確認事項](#未確認事項)）。

   **`MOK.priv` はこの PC が信頼するモジュールを作れる鍵になる。** root 以外に読ませず、ほかの PC にも持ち出さない。消し方は[ロールバック](#ロールバック)。

   </details>

1. Secure Boot が有効なときだけ、再起動して MokManager で鍵を登録する。

   ```bash
   sudo systemctl reboot
   ```

   - 起動の途中で青い **MokManager** の画面が出る
   - `Enroll MOK` → `Continue` → `Yes` → 一時パスワード → `Reboot` と進む
   - **何もしないで進むと登録されない**。そのときは手順 15 の `sudo mokutil --import ...` からやり直す
   - **次の手順は、起動したら新しい端末を開いてから貼る**

1. Secure Boot が有効なときだけ、鍵が登録されたか確かめる。

   ```bash
   mokutil --test-key /var/lib/shim-signed/mok/MOK.der
   ```

   - `/var/lib/shim-signed/mok/MOK.der is already enrolled` が出れば、登録できている
   - **MokManager での登録から先は実機でしか確かめられず、本書では未確認**

1. VirtualBox を入れる。

   ```bash
   sudo dnf install VirtualBox-7.2
   ```

   - トランザクション表を見て、`[y/N]` に `y` と答える
   - **EPEL の署名鍵をまだ取り込んでいなければ、続けて 1 回だけ確認を求められる**（[btop.md 手順 4](btop.md#実施手順) と同じ）
     - `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`、Fedora (epel10) &lt;epel@fedoraproject.org&gt;
   - 最後に `Creating group 'vboxusers'. VM users must be member of that group!` が出て、続けてモジュールのビルドが走る
   - **次の手順は、`[y/N]` と鍵の確認に答え、`Complete!` が出てから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: <code>%post</code> がやること</summary>

   rpm の `%post` は、`vboxusers` グループを作ったあと `/usr/lib/virtualbox/postinst-common.sh > /dev/null || true` を実行する。

   - これが systemd の unit `vboxdrv.service` を**その場で生成して enable し**、`/usr/lib/virtualbox/vboxdrv.sh setup` でモジュールをビルド・署名・読み込みする
   - 標準出力は捨てられ、失敗も `|| true` で無視されるので、**dnf から見るとどんな場合も成功になる**
   - 失敗の内容は標準エラーに出る（手順 12 の補足の実測）ので、`dnf install` の出力は最後まで見る
   - **`/sbin/vboxconfig`** は `postinst-common.sh` へのリンクで、同じ処理を最初からやり直す（実測で `/sbin/vboxconfig -> /usr/lib/virtualbox/postinst-common.sh`、`/sbin/rcvboxdrv -> /usr/lib/virtualbox/vboxdrv.sh`）
   - **`/usr/lib/systemd/system/vboxdrv.service` は rpm の持ち物ではない**（`%post` が書き、削除時に `%preun` が消す）
     - 中身は `ExecStart=/usr/lib/virtualbox/vboxdrv.sh start`・`TimeoutSec=5min`・`WantedBy=multi-user.target`
     - **unit の生成と有効化はスクリプトを読んだだけで、動作は確かめていない**（検証コンテナで systemd を PID 1 にできなかった。[付録](#付録-コンテナでの検証記録2026-09-24)）
   - **ビルドは数十秒**: コンテナでは 3 つのモジュールを 11 秒でビルドした。`/lib/modules/$(uname -r)/misc/` に `vboxdrv.ko` / `vboxnetflt.ko` / `vboxnetadp.ko` ができる
   - **`/dev/vboxdrv` は `root:root` の `0600`**（`%post` が書く `/etc/udev/rules.d/60-vboxdrv.rules` の実測）。VM を動かす `VirtualBoxVM` と `VBoxHeadless` が setuid root（`-r-s--x--x`）なので、一般ユーザーは直接触らない
   - **`vboxdrv.sh setup`（= `vboxconfig`）は、ほかのカーネル用も含めて vbox のモジュールを全部消してから、動いているカーネル用だけを作り直す**。別のカーネル用に作る目的では使わない
   - SELinux のラベルは `chcon` で付けている（`restorecon` で戻る可能性がある。未確認）

   </details>

1. `Complete!` だけでは成功とは限らないので、モジュールが動いているか確かめる。

   ```bash
   systemctl is-enabled vboxdrv
   systemctl is-active vboxdrv
   lsmod | grep -E '^vbox'
   ls -l /dev/vboxdrv
   sudo tail -n 5 /var/log/vbox-setup.log
   ```

   - モジュールのビルドや読み込みに失敗しても、dnf は `Complete!` で終わる（手順 18 の補足）
   - `enabled` と `active`、`vboxnetadp` / `vboxnetflt` / `vboxdrv` の 3 行、root だけが読み書きできる `/dev/vboxdrv` が出ればよい
   - `dnf install` の途中で `There were problems setting up VirtualBox.` が出ていた、または `active` にならないときは、ログ（`/var/log/vbox-setup.log`）で原因を見る
   - 原因を直してから、`sudo /sbin/vboxconfig` を実行し直す

1. KVM が仮想化支援を先に取らないように、modprobe.d に設定を置く。

   ```bash
   echo 'options kvm enable_virt_at_load=0' | sudo tee /etc/modprobe.d/kvm-virtualbox.conf
   ```

   - **EL10 のカーネル（6.12 系）では、KVM のモジュールが読み込まれた時点で VT-x / AMD-V を確保し、VirtualBox の VM が起動できなくなる**（この手順の補足）
   - KVM を使っていなくても、VT-x / AMD-V のある PC では起動時に自動で読み込まれる
   - この設定で、KVM が自分の VM を動かす間だけ確保するように変える
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 6.12 系のカーネルでは VirtualBox と KVM が同居できない</summary>

   - VirtualBox の変更履歴（7.1.4）に「カーネル 6.12 では KVM がモジュールの読み込み時に仮想化を初期化するので VirtualBox の VM が起動しない。`kvm.enable_virt_at_load=0` をカーネルの引数に足すか、kvm_XXX のモジュールを外す」とある
   - 7.2.2 で「6.16 以降のカーネルでは KVM の API で VT-x を取得・解放する」ようになったが、**EL10 は 6.12 系なのでこの仕組みは使われない**

   確かめたこと:

   - **ソースの条件**: rpm が入れる `/usr/share/virtualbox/src/vboxhost/vboxdrv/linux/SUPDrv-linux.c` で、KVM と共存する仕組み（`/dev/kvm` に空の VM を作って KVM に VT-x を任せる）は `#if RTLNX_VER_MIN(6,16,0) && ...` の中にしか無い
   - **ビルドされたモジュール**: EL10 のカーネル向けに作った `vboxdrv.ko` は `modinfo -F softdep` が空（6.16 以降の仕組みなら `pre: kvm_intel kvm_amd` が付く）で、`/dev/kvm` という文字列も 0 件だった
   - **EL10 の kvm.ko**: `modinfo -p` に `enable_virt_at_load: (bool)` があり、変数の初期値は `1`（有効）だった（`kernel-modules-core-6.12.0-211.56.1.el10_2` の kvm.ko の `.data` 節を読んだ）
   - Intel（`kvm_intel`）でも AMD（`kvm_amd`）でも同じで、この設定は両方が使う共通の `kvm` モジュールのもの（`modinfo -F depends` が `kvm`）
   - **自動で読み込まれる理由**: `kvm-intel.ko` は `cpu:type:x86,ven*fam*mod*:feature:*0085*`、`kvm-amd.ko` は `...feature:*00C2*` という別名（`modinfo -F alias`）を持つ
     - `0x85` と `0xC2` は kernel-devel の `cpufeatures.h` で `X86_FEATURE_VMX` と `X86_FEATURE_SVM` に当たるので、VT-x / AMD-V のある CPU なら起動時に udev が読み込む

   衝突したときのエラー文は `/usr/lib/virtualbox/VBoxVMM.so` にある（手順 27 の補足の表も見る）:

   - Intel は `VirtualBox can't operate in VMX root mode. Please disable the KVM kernel extension, recompile your kernel and reboot`
   - AMD は `VirtualBox can't enable the AMD-V extension. ...`

   **カーネル引数ではなく modprobe.d にした理由**: Oracle の変更履歴の案内はカーネル引数で、EL10 に当てはめると `sudo grubby --update-kernel=ALL --args=kvm.enable_virt_at_load=0` になる。

   - kvm は読み込み可能なモジュール（`CONFIG_KVM=m`）なので、modprobe.d の設定でも効く見込み
   - こちらは起動エントリを書き換えず、カーネルの更新にも左右されない
   - **この設定で実際に VM が起動するようになるかは確かめていない**（コンテナには KVM も VT-x も無い）
   - 手順 25 で `N` にならないとき、または手順 27 で VM が起動しないときは、grubby の方法を試す（こちらも未確認）

   </details>

1. 設定が modprobe に読まれているか確かめる。

   ```bash
   cat /etc/modprobe.d/kvm-virtualbox.conf
   modprobe -c | grep enable_virt_at_load
   ```

   - どちらにも `options kvm enable_virt_at_load=0` が出ればよい（後者は modprobe が読んだ設定）
   - **効くのは次に kvm が読み込まれたとき**なので、手順 24 の再起動で反映させる
   - KVM（libvirt / GNOME Boxes など）はこの後も使えるが、**KVM の VM と VirtualBox の VM は同時には動かせない**

1. USB 機器を VM に渡すときだけ、自分を `vboxusers` に入れる。

   ```bash
   sudo usermod -aG vboxusers "${USER}"
   ```

   - **VM を動かすだけなら要らない**（手順 22・23 は飛ばして手順 24 へ）
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: グループが効くのは USB だけ</summary>

   - `%post` は「VM users must be member of that group!」と出すが、7.2 の rpm では `/dev/vboxdrv` が `root:root 0600` で、VM は setuid の `VirtualBoxVM` / `VBoxHeadless` から動く（手順 18 の補足）
   - `vboxusers` が使われるのは USB の機器ノード。udev ルールが呼ぶ `/usr/lib/virtualbox/VBoxCreateUSBNode.sh` が、`/dev/vboxusb/<バス>/<機器>` を `root:vboxusers` の `0660` で作る（スクリプトの既定のグループが `vboxusers`）
   - Oracle のマニュアルも「USB 機器を使うユーザーは vboxusers に入れる」と書いている
   - **USB を実際に VM に渡すことは確かめていない**（`VBoxManage list usbhost` で見える機器の一覧など）

   </details>

1. USB 機器を VM に渡すときだけ、`vboxusers` に入ったか確かめる。

   ```bash
   getent group vboxusers
   ```

   - `vboxusers:x:<GID>:<USER>` のように、自分の名前が出ればよい
   - **効くのはログインし直してから**（手順 24 の再起動で済む）

1. 再起動して、手順 20 の KVM の設定と、手順 22 のグループを反映させる。

   ```bash
   sudo systemctl reboot
   ```

   - **次の手順は、起動したら新しい端末を開いてから貼る**

1. VirtualBox の版と、モジュールと KVM の状態を確かめる。

   ```bash
   VBoxManage --version
   systemctl is-active vboxdrv
   lsmod | grep -E '^vbox'
   cat /sys/module/kvm/parameters/enable_virt_at_load 2>/dev/null || echo 'kvm は未ロード'
   id -nG | tr ' ' '\n' | grep -x vboxusers || echo 'vboxusers には入っていない'
   ```

   - `7.2.20r175154` のような版、`active`、vbox の 3 行、`N`（または `kvm は未ロード`）が出ればよい
   - 最後の行は、手順 22 を行ったときだけ `vboxusers` になる
   - **版の前に `WARNING: The vboxdrv kernel module is not loaded.` が出たら、モジュールが読み込まれていない**（手順 19 に戻る）

1. Secure Boot が有効なときだけ、モジュールの署名を見る。

   ```bash
   modinfo -F signer vboxdrv
   ```

   - `VirtualBox module signing key` が出れば、手順 15 の鍵で署名したモジュールが使われている

1. 使い捨ての VM を画面無しで起動し、状態を見てから止めて消す。

   ```bash
   VBoxManage createvm --name vbox-selftest --ostype Other_64 --register
   VBoxManage modifyvm vbox-selftest --memory 64 --nic1 none --audio-enabled off
   VBoxManage startvm vbox-selftest --type headless
   VBoxManage showvminfo vbox-selftest --machinereadable | grep -E '^VMState='
   VBoxManage controlvm vbox-selftest poweroff
   VBoxManage unregistervm vbox-selftest --delete
   ```

   - VirtualBox が VT-x / AMD-V を取れるか（KVM とぶつからないか）は、ここで初めて分かる
   - `VM "vbox-selftest" has been successfully started.` が出れば動いている（起動するディスクが無いので、中では何も動かない）
   - `VMState="running"` なら動いていた
   - `controlvm ... poweroff` で止まり、`unregistervm ... --delete` は `0%...10%...` と進んで、VM のファイルごと消える
   - **VM の起動は実機でしか確かめられず、本書では未確認**（コンテナにはモジュールを読み込めないので、`startvm` は失敗した。この手順の補足）

   <details>
   <summary>補足: 出るエラーと対処</summary>

   | 出るもの | 意味 | 対処 |
   |---|---|---|
   | `WARNING: The vboxdrv kernel module is not loaded. Either there is no module available for the current kernel (...) or it failed to load.` | モジュールが無いか、読み込めていない。`VBoxManage` などを包むスクリプト（`VBox.sh`）が、コマンドの前に標準出力へ出す | `sudo tail -n 20 /var/log/vbox-setup.log` で原因を見て `sudo /sbin/vboxconfig`。Secure Boot なら手順 14〜17 |
   | `VirtualBox can't operate in VMX root mode. Please disable the KVM kernel extension, recompile your kernel and reboot`（`VERR_VMX_IN_VMX_ROOT_MODE`） | Intel: KVM が VT-x を確保している | `enable_virt_at_load` が `N` か見る（手順 20・21）。KVM の VM が動いていれば止める |
   | `VirtualBox can't enable the AMD-V extension. Please disable the KVM kernel extension, recompile your kernel and reboot`（`VERR_SVM_IN_USE`） | AMD: 同上 | 同上 |
   | `Key was rejected by service`（`sudo modprobe vboxdrv` や `dmesg`） | Secure Boot で署名が受け入れられない | `mokutil --test-key`（手順 17）。**この文は一般的なカーネルのエラーで、本書では出していない** |
   | `There were problems setting up VirtualBox.  To re-start the set-up process, run /sbin/vboxconfig as root.` | `dnf install` の途中でビルド・署名・読み込みのどこかが失敗した | `/var/log/vbox-setup.log` を見る |

   - KVM とぶつかったときの 2 つの文は、実機で出したものではなく `/usr/lib/virtualbox/VBoxVMM.so` の中の文字列から写した
   - 本文の成功したときの表示（`VM "vbox-selftest" has been successfully started.`）も、`VBoxManage` の中の `VM "%s" has been successfully started.` から写したもので、本書では実際には出ていない
   - 既に `vbox-selftest` という名前の VM があるなら、この手順の 6 行の名前を別のものに置き換えて貼る

   コンテナ（モジュールが無い）での `startvm` の実測は次のとおりで、実機での失敗の出方とは違う可能性がある:

   ```
   VBoxManage: error: The virtual machine 'vbox-selftest' has terminated unexpectedly during startup with exit code 1 (0x1)
   VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005), component MachineWrap, interface IMachine
   ```

   - `--ostype Other_64` は、`VBoxManage list ostypes` の `Other_64 -- Other/Unknown (64-bit)`（x86 の 64 ビット）
   - VM の置き場所は既定の `~/VirtualBox VMs/<VM 名>` で、`unregistervm --delete` がそのディレクトリごと消す（`~/VirtualBox VMs` 自体は残る）
   - `createvm` などの設定だけの操作は、モジュールが無くても動いた（コンテナで `createvm` → `modifyvm` → `unregistervm --delete` が成功）
   - 最初の `VBoxManage` で `~/.config/VirtualBox`（`VirtualBox.xml` と `VBoxSVC.log`）ができる

   </details>

1. デスクトップにログインした端末から、GUI を起動する。

   ```bash
   VirtualBox
   ```

   - アプリ一覧の「Oracle VirtualBox」からでも同じ
   - VirtualBox マネージャーのウィンドウが開く（手順 27 の VM は消してあるので一覧は空）
   - **この手順は実機でもコンテナでも確かめていない**（コンテナには画面が無く、`No active display server, X11 or Wayland, detected. Exiting.` で終わった）
   - **次の手順は、ウィンドウを閉じてから貼る**（続けて貼ると VirtualBox への操作として食われる）

   <details>
   <summary>補足: GUI のライブラリ</summary>

   - GUI は AppStream の Qt 6（`/lib64/libQt6*.so.6`）を使う
   - `/usr/lib/virtualbox` の下の ELF ファイル 48 個すべてで、`ldd` の `not found` が 0 だった（コンテナで確認）
   - Qt の表示の土台は xcb（X11）と wayland の両方のプラグインが入り、VirtualBox の実行ファイルには `QT_QPA_PLATFORM` と `wayland` の文字列がある
   - **GNOME の Wayland セッションで Wayland のまま動くか XWayland 経由になるかは確かめていない**（[未確認事項](#未確認事項)）

   </details>

1. `~/.config/VirtualBox` に設定ができたか確かめる。

   ```bash
   ls ~/.config/VirtualBox
   ```

   - `VirtualBox.xml` などが並ぶ

---

## カーネルを更新したとき

- `sudo dnf upgrade` で新しいカーネルが入ると、同じ版の `kernel-devel` も一緒に入る（installonly。[手順 12](#実施手順) の補足）
- **新しいカーネルで起動すると、`vboxdrv.service` がその場でモジュールをビルドし直す**（Secure Boot なら手順 15 の鍵で署名もする）。そのぶん、その 1 回の起動が遅くなる
  - これは `/usr/lib/virtualbox/vboxdrv.sh` の `start` を読んだ結果で、**本書ではカーネルの更新と再起動を試していない**
  - スクリプトは、動いているカーネル用の vbox のモジュールが無ければ、その場でビルドする
  - 最後に「もう入っていないカーネル」用のモジュールを消す

1. 新しいカーネルで起動した後に、モジュールが作り直されたか確かめる。

   ```bash
   uname -r
   systemctl is-active vboxdrv
   modinfo -F vermagic vboxdrv
   ```

   - `modinfo` の先頭が `uname -r` と同じ版で、`active` ならよい
   - そうでなければ `sudo tail -n 20 /var/log/vbox-setup.log` で原因を見て、`sudo /sbin/vboxconfig` を実行する

---

## 更新

- VirtualBox の VM と GUI をすべて閉じてから上げる
  - VirtualBox の裏のプロセス `VBoxSVC` が動いていると、rpm の `%pre` が `A copy of VirtualBox is currently running.  Please close it and try again.` で止める
- **系列を変えるとき（7.2 → 7.3 など）は、先に消してから入れる**（この節の手順 2・3）
  - 系列ごとにパッケージ名が違うので `dnf upgrade` では移らず、2 つを同時に入れることもできない
  - **7.3 系はまだ出ていないので、本書では 7.1 と 7.2 で試した**（コンテナ。[更新の補足](#更新の補足)）
- VM の設定（`~/.config/VirtualBox` と `~/VirtualBox VMs`）は、rpm の操作では消えない

> [!WARNING]
> 系列の切り替え（この節の手順 2・3）に **`dnf swap` は使わない**。`Complete!` で終わるが、コンテナで試したときは新しい系列のモジュールと設定が消え、動かない状態になった（[更新の補足](#更新の補足)）。

1. 同じ系列の中で、新しい版に上げる。

   ```bash
   sudo dnf upgrade VirtualBox-7.2
   ```

   - トランザクション表を見て `[y/N]` に答える
   - **更新のたびに `%post` がモジュールをビルドし直す**ので、[手順 19](#実施手順) と同じ確認をする
   - コンテナで 7.2.18 → 7.2.20 を上げたときは、`%post` が新規導入のときと同じ表示を出した
   - モジュールは 7.2.20 用に作り直された（`modinfo -F version` が `7.2.18 r175117` → `7.2.20 r175154`）
   - `/sbin/vboxconfig` と udev のルールも残った
   - **[手順 19](#実施手順) の確認は、`[y/N]` に答えて `Complete!` が出てから貼る**（続けて貼ると答えとして食われる）

1. 系列を変えるときは（この節の手順 1 の代わりに）、[ロールバック](#ロールバック)の手順 1 だけを行う。

   - VM と GUI をすべて閉じてから行う
   - [ロールバック](#ロールバック)の手順 1 は `sudo dnf remove VirtualBox-7.2`
   - `[y/N]` に答えてから、この節の手順 3 に進む

1. 系列を変えるときは、パッケージ名を新しい系列に置き換えて、[手順 10](#実施手順) の下見と手順 18 からやり直す。

   - 手順 10・18 の `VirtualBox-7.2` を、新しい系列の名前（`VirtualBox-7.3` など）に置き換えて貼る
   - 以後は、この節の手順 1 と[ロールバック](#ロールバック)の手順 1 も同じく置き換える
   - repo ファイル・鍵・EPEL・ビルドの道具・MOK・KVM の設定はそのまま使える

---

## ロールバック

- この節の手順では消えないもの:
  - **Oracle の署名鍵** `gpg-pubkey-2980aecf-5719f4e1`: 消すなら `sudo rpm -e gpg-pubkey-2980aecf-5719f4e1`
  - **Secure Boot の MOK**（手順 15〜17 を行った場合）: 次の順で消す
    - `sudo mokutil --delete /var/lib/shim-signed/mok/MOK.der`（一時パスワードを 2 回）→ 再起動 → MokManager で `Delete MOK` → パスワード → `Reboot`
    - そのあと `sudo rm -rf /var/lib/shim-signed`
    - **MOK の削除は本書では試していない**
  - **ログ** `/var/log/vbox-setup.log`（と `.1`〜`.4`）: 要らなければ手で消す
  - **手順 3 の EPEL と、手順 12 の gcc / kernel-devel など**: ほかでも使うので消さない
- 本書ではロールバックを**コンテナでのみ本実行した**（MOK の削除を除く）

> [!CAUTION]
> **この節の手順 3 で、VM とその設定（`~/.config/VirtualBox` と `~/VirtualBox VMs`）が消える**。消した VM は取り戻せない。

1. VM をすべて止めてから、VirtualBox を消す。

   ```bash
   sudo dnf remove VirtualBox-7.2
   ```

   - **依存で入ったもの（Qt 6 など）も一緒に消える**
     - 素のコンテナでは、本体と合わせて 86 パッケージ・712 MB。依存の `xml-common` を消したときに、`/etc/xml/catalog.rpmsave` が残った
   - モジュール・`vboxdrv.service`・udev のルール・`/sbin/vboxconfig`・`/etc/vbox` は、これで消える
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. repo ファイル・KVM の設定・`vboxusers` グループ・dnf のキャッシュを消す。

   ```bash
   {
     sudo rm -f /etc/yum.repos.d/virtualbox.repo /etc/modprobe.d/kvm-virtualbox.conf
     sudo groupdel vboxusers
     sudo rm -rf /var/cache/dnf/virtualbox*
     rm -rf /var/tmp/dnf-"${USER}"-*/virtualbox*
   }
   ```

   - `vboxusers` グループは rpm を消しても残るので、ここで消す（手順 22 で自分を入れていても、グループごと消える）
   - 最後の 2 行は、手順 8・9 で取り込んだメタデータ用の鍵（`pubring/A2F683C52980AECF.pub`）を含む dnf のキャッシュを消す（root の分とユーザーの分）
   - **`dnf clean all` ではこの鍵は消えなかった**（コンテナで確認）
   - KVM の設定を消したことは、次の起動から効く

1. VM とその設定も消すときだけ、`~/.config/VirtualBox` と `~/VirtualBox VMs` を消す（取り戻せない）。

   ```bash
   rm -rf ~/.config/VirtualBox ~/"VirtualBox VMs"
   ```

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 の x86_64 の PC に [Oracle VirtualBox](https://www.virtualbox.org/) 7.2 を Oracle 公式の dnf リポジトリから入れ、カーネルモジュールをこの PC でビルドして VM を動かせるようにする
  - **Linux の arm64 版は無い**ので、Raspberry Pi 5 は対象外
- **進め方**: EPEL を有効にし（依存の `liblzf` のため）、鍵を照合して取り込み、repo ファイルを置いて解決を確かめ、ビルドの道具（と Secure Boot なら MOK の鍵）を用意してから `dnf install` する
  - 最後に KVM の設定を足して再起動する
  - **読者が書き換える値は無い**
- **状態**: **x86_64 のコンテナでのみ検証済み（2026-09-24）。実機には入れていない**
  - 下表の検証コンテナで、**この文書のコードブロックを上から順にそのまま貼って**手順 1〜15・17〜23・25〜29、[カーネルを更新したとき](#カーネルを更新したとき)・[更新](#更新)・[ロールバック](#ロールバック)を通した（手順 16・24 の再起動は実行していない）
  - 確認したこと:
    - 鍵の fingerprint
    - 依存の `liblzf` のために EPEL が要ること
    - `repo_gpgcheck` の鍵の確認が `sudo` の有無で 1 回ずつ要ること
    - `VirtualBox-7.2 7.2.20` の依存解決と導入
    - **EL10 のカーネル（`6.12.0-211.56.1.el10_2`）向けに `%post` が 3 つのモジュールをビルドし、手順 15 の鍵で署名すること**
    - そのモジュールに KVM と共存する仕組みが入らないこと
    - 更新・系列の切り替え・ロールバックの結果
  - **コンテナのカーネルは別物なので `uname -r` を、Secure Boot の状態は `mokutil` をスタブにした**（[付録](#付録-コンテナでの検証記録2026-09-24)）
  - **確認していないこと**: モジュールの読み込み、`vboxdrv.service`、MokManager での鍵の登録と署名の受け入れ、`enable_virt_at_load=0` の効果、VM の起動、USB、GUI の表示、カーネル更新後の自動ビルド（コンテナではできない）
  - `--privileged` は付けていない（`modprobe` がホストのカーネルに触れないように）
  - 2026-09-28: 手順 8・15 と、[ロールバック](#ロールバック)の手順 2のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../README.md#記法)）
    - 中のコマンドは変えていない。囲んだ形は構文の検査だけで、流していない

| 項目 | 実機（x86_64 PC） | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-24 |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64 | 同左（`quay.io/almalinuxorg/almalinux:10`、`sha256:83220192…c4c8`） |
| カーネル | `6.12.0-211.56.1.el10_2.x86_64`（[wireguard-road-warrior.md](wireguard-road-warrior.md) の 2026-09-22 の記録） | クラウドのホスト（6.18 系）のカーネルを共有。`uname -r` だけスタブで `6.12.0-211.56.1.el10_2.x86_64` を返させ、その版の `kernel-core` / `kernel-modules-core` を先に入れた（`kernel-devel` は手順 12 で入る） |
| デスクトップ | GNOME Shell 49.4 / Wayland（[wezterm-nightly.md](wezterm-nightly.md) の記録） | 無し |
| EPEL | 有効（同記録） | 手順 3 で有効化 |
| CPU の仮想化支援 / KVM | 未確認 | 無し（`/dev/kvm` が無く、`lscpu` に `Virtualization:` の行が無い） |
| Secure Boot | 未確認 | 無し（`mokutil --sb-state` → `EFI variables are not supported on this system`）。分岐は `mokutil` のスタブで確かめた |
| SELinux | Enforcing（同記録） | 無効（コンテナ） |
| 入った VirtualBox | — | `VirtualBox-7.2-7.2.20_175154_el10-1.x86_64` |

実機の列は**この手順を適用した結果ではなく、ほかの手順書が記録した時点の状態**。CPU が Intel か AMD か、Secure Boot が有効か、KVM を使っているかは記録が無い。

> [!NOTE]
> 出力例の値は `<USER>` / `<GID>` などのプレースホルダで書いてある。バージョン（`7.2.20`）とカーネルの版（`6.12.0-211.56.1.el10_2`）は実行日によって変わる。**鍵の fingerprint は公開情報なので本文に書いてある。** MOK の秘密鍵と一時パスワードは載せない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

検証コンテナ（AlmaLinux 10 の素のイメージに、デスクトップの PC に合わせた準備をした後）の状態:

| 項目 | 状態 |
|---|---|
| VirtualBox | 未導入（`rpm -qa 'VirtualBox*'` が空） |
| `/etc/yum.repos.d/virtualbox.repo` / Oracle の鍵 | どちらも無し |
| EPEL | 未設定（baseos / appstream / crb / extras の 4 つ） |
| gcc / make / perl-interpreter / mokutil / openssl / kernel-devel | どれも未導入 |
| `which` / `gnupg2` / `systemd-udev` / `kmod` | 導入済み（GNOME の PC に合わせて先に入れた。[付録](#付録-コンテナでの検証記録2026-09-24)） |
| `vboxusers` グループ | 無し |

### 選択した方針

AlmaLinux 10 の x86_64 で VirtualBox を入れる経路を比べた（2026-09-24 時点）:

| 経路 | EL10 での状況 | 採否 |
|---|---|---|
| **Oracle 公式 dnf リポジトリ** | `download.virtualbox.org/virtualbox/rpm/el/10/x86_64/` に **EL10 向けのビルド**（`_el10`）がある。7.2 系は 7.2.0〜7.2.20 の 11 個、7.1 系は 5 個。メタデータにもパッケージにも署名がある。`dnf upgrade` で上がる | **採用** |
| 公式サイトの `.rpm` を直接入れる | 同じ rpm だが、更新のたびに手で落とすことになる | 不採用 |
| 汎用インストーラ（`VirtualBox-7.2.20-175154-Linux_amd64.run`） | `/opt/VirtualBox` に入り、dnf の管理外になる | 不採用 |
| Oracle Linux の `ol10_developer` チャンネル | Oracle Linux 専用 | 対象外 |
| RPM Fusion | EL10 には VirtualBox が無い（EL9 に 7.1.18） | 不採用 |
| Flathub | 無い（カーネルモジュールが要るため） | — |
| 7.1 系（`VirtualBox-7.1`） | 同じリポジトリにある保守版。7.2 と同時には入らない | 対象外 |
| KVM（libvirt / virt-manager / GNOME Boxes） | AlmaLinux 標準の仮想化。カーネルに組み込み済みでモジュールのビルドも署名も要らない | 対象外（本書は VirtualBox を入れる）。VirtualBox と同時には動かない（手順 20・21） |

aarch64 には入らない:

- Oracle のリポジトリの `.../el/10/aarch64/` が 404
- 7.2.20 の配布物にも Linux の arm64 版が無い（arm64 向けは macOS の Apple Silicon 版と、Windows の実験的な対応だけ）
- マニュアルの対応ホストの一覧も、Linux はすべて x86_64 になっている

### 完了時点の状態

**検証コンテナでの出力**（手順 27 の後。ロールバック前。コンテナではモジュールを読み込めないので、`VBoxManage` の前に `WARNING` が出ている）:

```
$ rpm -q VirtualBox-7.2
VirtualBox-7.2-7.2.20_175154_el10-1.x86_64
$ VBoxManage --version
WARNING: The vboxdrv kernel module is not loaded. Either there is no module
         available for the current kernel (6.12.0-211.56.1.el10_2.x86_64) or it failed to
         load. Please recompile the kernel module and install it by

           sudo /sbin/vboxconfig

         You will not be able to start VMs until this problem is fixed.
7.2.20r175154
$ ls -l /lib/modules/6.12.0-211.56.1.el10_2.x86_64/misc/
total 5992
-rw-r--r-- 1 root root 4340763 Sep 24 23:44 vboxdrv.ko
-rw-r--r-- 1 root root  702427 Sep 24 23:44 vboxnetadp.ko
-rw-r--r-- 1 root root 1086115 Sep 24 23:44 vboxnetflt.ko
$ modinfo -F vermagic /lib/modules/6.12.0-211.56.1.el10_2.x86_64/misc/vboxdrv.ko
6.12.0-211.56.1.el10_2.x86_64 SMP preempt mod_unload modversions 
$ modinfo -F version /lib/modules/6.12.0-211.56.1.el10_2.x86_64/misc/vboxdrv.ko
7.2.20 r175154 (0x00390002)
$ modinfo -F signer /lib/modules/6.12.0-211.56.1.el10_2.x86_64/misc/vboxdrv.ko
VirtualBox module signing key
$ ls -l /sbin/vboxconfig /sbin/rcvboxdrv
lrwxrwxrwx 1 root root 30 Sep 24 23:44 /sbin/rcvboxdrv -> /usr/lib/virtualbox/vboxdrv.sh
lrwxrwxrwx 1 root root 38 Sep 24 23:44 /sbin/vboxconfig -> /usr/lib/virtualbox/postinst-common.sh
$ head -3 /etc/udev/rules.d/60-vboxdrv.rules
KERNEL=="vboxdrv", OWNER="root", GROUP="root", MODE="0600"
KERNEL=="vboxdrvu", OWNER="root", GROUP="root", MODE="0666"
KERNEL=="vboxnetctl", OWNER="root", GROUP="root", MODE="0600"
$ getent group vboxusers
vboxusers:x:<GID>:<USER>
$ rpm -ql VirtualBox-7.2 | wc -l
865
$ du -sh /usr/lib/virtualbox /usr/share/virtualbox
144M	/usr/lib/virtualbox
74M	/usr/share/virtualbox
$ ls ~/.config/VirtualBox
VBoxSVC.log
VirtualBox.xml
VirtualBox.xml-prev
compreg.dat
xpti.dat
```

- `modinfo` をファイルの場所で指定しているのは、コンテナでは `modinfo vboxdrv`（名前で引く形）が別のカーネルの置き場所を見に行って `Module vboxdrv not found.` になるため（[付録](#付録-コンテナでの検証記録2026-09-24)）。実機では手順 26 の書き方でよい
- 3 つのモジュールとも vermagic と版は同じで、signer はどれも `VirtualBox module signing key`、`sig_hashalgo` は `sha512`、`softdep` は空だった

### 注意点

- **EPEL が要る**: 依存の `liblzf` が EPEL にしか無い（[手順 3](#実施手順) の補足）
- **`Complete!` でもモジュールができていないことがある**: `%post` は失敗を無視する。`systemctl is-active vboxdrv` と `/var/log/vbox-setup.log` で確かめる（[手順 18・19](#実施手順)）
- **sudo を付けない dnf にも鍵の確認が要る**: `repo_gpgcheck=1` のため。確認を通すまで、`sudo` 無しの dnf はどのパッケージでも失敗する（[手順 9](#実施手順) の補足）
- **Secure Boot では `mokutil` が要る**: vboxdrv.sh は `mokutil --sb-state` の出力だけで判定する。鍵の場所は `/var/lib/shim-signed/mok/` 固定。MokManager の画面を逃すと登録されない（[手順 14〜17](#実施手順)）
- **EL10 のカーネルでは KVM と同居できない**: `enable_virt_at_load=0` が要り、それでも KVM の VM と VirtualBox の VM は同時に動かない（[手順 20・21](#実施手順)）
- **カーネルを更新した後の最初の起動は遅くなる**: `vboxdrv.service` がモジュールをビルドし直す（[カーネルを更新したとき](#カーネルを更新したとき)）
- **系列がパッケージ名に入っている**: 7.2 → 7.3 は `dnf upgrade` では移らない（[更新](#更新)）
- **vboxusers は USB のためだけ**: VM の起動には要らない（[手順 22](#実施手順)）
- **Extension Pack は本書では扱わない**: 追加機能（マニュアルによれば VRDP のサーバー、ホストの Web カメラの受け渡し、Intel の PXE ブート ROM、ディスクイメージの暗号化、クラウド連携）をまとめた別配布
  - ライセンスは GPL ではなく **PUEL（個人利用と教育利用に限って無償）**
  - rpm の `%postun` が `/usr/lib/virtualbox/ExtensionPacks` を消すので、入れた場合は **VirtualBox の更新のたびに入れ直す**ことになる（rpm のスクリプトを読んだ結果。未確認）
- **Guest Additions はゲスト側の話で対象外**: ISO は rpm に同梱されている（`/usr/share/virtualbox/VBoxGuestAdditions.iso`）。ゲストが AlmaLinux の bootc（Atomic Desktop）なら [virtualbox-guest-bootc.md](virtualbox-guest-bootc.md)
- **公式の repo ファイルは `http://`**: 本書の repo ファイルは `https://` にしてある。署名の検証はどちらでも行われる

### 更新の補足

**7.2 を入れたまま 7.1 を入れようとすると、ファイルの衝突で止まる。** 依存の解決（`--assumeno`）は `Install  1 Package` で通ってしまい、実際に入れようとした段階で初めて分かる:

```
Error: Transaction test error:
  file /usr/bin/VBox from install of VirtualBox-7.1-7.1.18_173720_el10-1.x86_64 conflicts with file from package VirtualBox-7.2-7.2.20_175154_el10-1.x86_64
  ...
```

衝突は 501 件だった。**`sudo dnf swap VirtualBox-7.2 VirtualBox-7.1` は `Complete!` で終わるが、入れ替えた後の 7.1 は動かない状態になった**。

新しい系列の `%post` がモジュールを作った後に、古い系列の削除処理（`%preun` の `prerm-common.sh`）が走り、モジュール・`/sbin/vboxconfig`・`/sbin/rcvboxdrv`・udev のルールを消していた:

```
$ rpm -qa 'VirtualBox*'
VirtualBox-7.1-7.1.18_173720_el10-1.x86_64
$ ls -l /lib/modules/6.12.0-211.56.1.el10_2.x86_64/misc/
total 0
$ ls -l /sbin/vboxconfig /etc/udev/rules.d/60-vboxdrv.rules
ls: cannot access '/sbin/vboxconfig': No such file or directory
ls: cannot access '/etc/udev/rules.d/60-vboxdrv.rules': No such file or directory
```

- `sudo dnf remove VirtualBox-7.1` の後に `sudo dnf install VirtualBox-7.2` とした場合は、モジュール（`7.2.20 r175154`）・`/sbin/vboxconfig`・udev のルールがすべて揃った
- `vboxusers` グループは消えずに残るので、手順 22・23 をやり直す必要は無い

### 参照

- [VirtualBox — Linux_Downloads](https://www.virtualbox.org/wiki/Linux_Downloads) — ディストリごとの rpm、鍵の fingerprint、`virtualbox.repo`
- [Oracle VirtualBox User Guide 7.2 — Installing on Linux Hosts](https://docs.oracle.com/en/virtualization/virtualbox/7.2/user/installation.html) — 対応ホストの一覧、前提（gcc / make / カーネルのヘッダ）、`vboxusers`、`/etc/default/virtualbox`
- [Oracle VirtualBox User Guide 7.2 — Introduction](https://docs.oracle.com/en/virtualization/virtualbox/7.2/user/Introduction.html) — Extension Pack に入る機能
- [RHEL 10 — Managing, monitoring, and updating the kernel](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html-single/managing_monitoring_and_updating_the_kernel/index) — 「Requirements for authenticating kernel modules with X.509 keys」（モジュールの署名を `.builtin_trusted_keys` と `.platform` で確かめる）、`mokutil --import` と `keyctl list %:.platform`
- [VirtualBox — Changelog 7.2](https://www.virtualbox.org/wiki/Changelog-7.2) / [Changelog 7.1](https://www.virtualbox.org/wiki/Changelog-7.1) — 6.12 の KVM の注意（7.1.4）、6.16 以降の KVM の API（7.2.2）、RHEL 10.x のカーネルへの対応
- [VirtualBox — Downloads](https://www.virtualbox.org/wiki/Downloads) / [PUEL](https://www.virtualbox.org/wiki/VirtualBox_PUEL) — Extension Pack とそのライセンス
- `/usr/lib/virtualbox/vboxdrv.sh` / `/usr/lib/virtualbox/postinst-common.sh` / `/usr/lib/virtualbox/check_module_dependencies.sh` / `/usr/share/virtualbox/src/vboxhost/vboxdrv/linux/SUPDrv-linux.c` — 本書の説明の元にした、rpm が入れるスクリプトとソース
- `man dnf.conf`（`repo_gpgcheck`）/ `man modprobe.d` / `man mokutil`

---

### 付録: コンテナでの検証記録（2026-09-24）

**環境**: Ubuntu 24.04 / x86_64 のクラウドホスト上の Docker 29.3.1（cgroup v1）で、`quay.io/almalinuxorg/almalinux:10`（`sha256:8322019282c6f7d253888ec688d6b90675963f31c4692709177e25eb9301c4c8`、AlmaLinux 10.2）を**非特権**・`--network host` で立て、非 root ユーザー（NOPASSWD の sudo）で実行した。実機で加えた変更は無い。**`--privileged` を付けなかったのは、`%post` の `modprobe` などがクラウドのホストのカーネルに触れないようにするため**（コンテナからは `/proc/modules` も見えなかった）。

**手順書の外で行った準備**（検証環境の都合）:

- プロキシの CA を信頼ストアに足し、dnf にプロキシを設定した。プロキシが平文の HTTP を通さないので、AlmaLinux のミラー一覧の URL に `?protocol=https`、EPEL の metalink に `&protocol=https` を足した（EPEL は手順 4 の直後）
- GNOME のデスクトップの PC に合わせて、`which`・`gnupg2`・`systemd-udev`・`kmod`（Workstation / Server with GUI の必須グループ「Standard」などに入っているもの）と、動いているカーネルの `kernel-core` / `kernel-modules-core`（`6.12.0-211.56.1.el10_2`）を先に入れた。`/lib/modules/<版>/build` のリンクは `kernel-modules-core` が持っている

**スタブ**:

| スタブ | 返すもの | 理由 |
|---|---|---|
| `/usr/bin/uname` | `-r` のときだけ `6.12.0-211.56.1.el10_2.x86_64`。ほかの引数は本物に渡す | コンテナはクラウドのホストのカーネル（6.18 系）を共有する。`%post`・vboxdrv.sh・`check_module_dependencies.sh` と手順 12・13 の `kernel-devel-$(uname -r)` が `uname -r` の版を使う |
| `/usr/bin/mokutil`（手順 12 で本物を入れた後に差し替えた） | `--sb-state` → `SecureBoot enabled`。`--test-key` → 未登録（登録の印のファイルを置いた後は `is already enrolled`）。`--import` / `--list-new` は何もしない | コンテナには UEFI の変数が無い（本物は `EFI variables are not supported on this system`）。Secure Boot の分岐（署名）を通すため |

`modinfo`・`modprobe`・`depmod` はコマンドの `uname` ではなくカーネルに版を聞くので、コンテナではホストの版の置き場所（`/lib/modules/6.18…`。無い）を見に行き、`modinfo vboxdrv` は `Module vboxdrv not found.`、`depmod -a` は `could not open directory` になった。モジュールはファイルの場所を指定して確かめた。

**流し方**: 本文の `bash` のコードブロックを上から順に抜き出し、1 つずつ新しい `docker exec` で実行した（手順 1 の 2 つの変数を各ブロックの先頭に足した。本文の「新しいシェルを開いたら手順 1 を貼り直す」と同じ）。確認を聞くブロック（手順 8・9 の `makecache` 2 つ、手順 18 の `dnf install`、更新、ロールバックの `dnf remove`）は `script` で作った pty の中で流し、間を置いて `y` を送った。コマンドに `-y` は足していない。

| 手順 | 結果 |
|---|---|
| 1. 変数 | 2 つの値、`x86_64`、`CPU の仮想化支援が見えない`（クラウドのホストに VT-x が無い） |
| 2〜4. EPEL | `EPEL は未設定` → `epel-release-10-6.el10`（extras）と `dnf-plugins-core` → `epel` の行 |
| 5〜7. 鍵 | fingerprint が本文の値と一致。`rpm --import` は無出力で終了コード 0。`gpg-pubkey-2980aecf-5719f4e1` |
| 8〜10. リポジトリ | repo ファイルを作成。`sudo dnf makecache` と `dnf makecache` のどちらも `Importing GPG key 0x2980AECF:` → `y` → `Metadata cache created.`。下見は 89 パッケージ（223 MB / 展開後 719 MB）で、`liblzf` は epel から |
| 11〜13. ビルドの道具 | `uname -r` と `rpm -q --last kernel-core` が同じ版。`gcc` / `make` / `perl-interpreter` / `mokutil` / `openssl` / `kernel-devel-6.12.0-211.56.1.el10_2` を導入。途中で 1 つのミラーが証明書のホスト名の不一致で失敗したが、dnf が別のミラーから取り直した |
| 14〜17. MOK（スタブ） | `SecureBoot enabled` → 鍵の生成（`MOK.priv` が `-rw-------`）→ `--import` はスタブ → **再起動は実行せず**、登録の印を置いて `is already enrolled` |
| 18〜19. 導入 | `[y/N]` と EPEL の鍵（`0xE37ED158`）に `y`。`Creating group 'vboxusers'...` の後、`%post` がモジュールを 3 つビルドして手順 15 の鍵で署名し、`modprobe vboxdrv failed` と `There were problems setting up VirtualBox.` を出して `Complete!`（コンテナでは読み込めないため）。`systemctl` は `System has not been booted with systemd`、`/dev/vboxdrv` は無し、ログは `Building the main VirtualBox module.` など 3 行 |
| 20〜21. KVM | ファイルの中身と `modprobe -c` の両方に `options kvm enable_virt_at_load=0` |
| 22〜23. vboxusers | `vboxusers:x:<GID>:<USER>` |
| 24. 再起動 | **実行していない**。以降は新しい `docker exec` で行った（新しいログインと同じく、グループが反映される） |
| 25〜27. 検証 | `7.2.20r175154`（前に `WARNING`）、`kvm は未ロード`、`vboxusers`。`modinfo -F signer vboxdrv` は `Module vboxdrv not found.`（上記の理由）。`createvm` と `modifyvm` は成功、`startvm` は `terminated unexpectedly during startup with exit code 1`、`VMState="poweroff"`、`controlvm poweroff` は `is not currently running`、`unregistervm --delete` は `0%...100%` |
| 28〜29. GUI | `No active display server, X11 or Wayland, detected. Exiting.`（30 秒の timeout を付けて実行）。`~/.config/VirtualBox` に `VirtualBox.xml` など 5 つ |
| カーネル更新 | `uname -r` だけ通った。`systemctl` と `modinfo` は上と同じ理由で失敗 |
| 更新 | `Nothing to do.` |
| ロールバック | `Remove  86 Packages`・`Freed space: 712 M`・`/etc/xml/catalog.rpmsave`。repo ファイル・modprobe.d・`vboxusers` が消えた。**このときの版は `dnf clean all` を使っていて、メタデータ用の鍵（`pubring`）が残った**ので、本文の 2 行（`rm -rf .../virtualbox*`）に直した。直した後のロールバックの 3 ブロックは、同じ版の VirtualBox を入れ直した別のコンテナで流し直し、パッケージ・`vboxusers`・鍵を含む dnf のキャッシュ・repo ファイル・modprobe.d のファイル・VM の設定がどれも残らないことを確かめた |

**手順書を流す前に、別のコンテナで確かめたこと**:

| 確認 | 結果 |
|---|---|
| EPEL 無しの下見 | `nothing provides liblzf.so.1()(64bit) needed by VirtualBox-7.2-7.2.20_175154_el10-1.x86_64 from virtualbox` |
| 系列の無い名前 | `sudo dnf install --assumeno VirtualBox` → `No match for argument: VirtualBox` |
| `sudo` 無しの dnf | 鍵を受け入れる前は、無関係な `dnf -q list --showduplicates tmux` まで `Signing key not found` で失敗。受け入れた後は成功。ユーザーのキャッシュは `/var/tmp/dnf-<USER>-<ランダム>/` |
| ビルドの道具が無いとき | `%post` が `This system is currently not set up to build kernel modules.` などを出し、`dnf install` は `Complete!`（手順 12 の補足） |
| `perl` と `perl-interpreter` | 素のコンテナで 269 パッケージ・300 MB と 60 パッケージ・26 MB。`perl-interpreter` だけでビルドと署名の確認（`Verified OK`）が通った。`elfutils-libelf-devel` 無しでビルドできた |
| Secure Boot（スタブ）で、鍵無し / 鍵ありで未登録 / 登録済み | 署名で止まって鍵の作り方を案内 / 署名はするが `You must sign these kernel modules` と `modprobe vboxdrv failed` / 署名して読み込みに進む（コンテナなので `modprobe` で失敗） |
| Oracle の案内どおりの `openssl req` | `-subj` が無いと `Country Name (2 letter code) [XX]:` で対話になり、`-days` が無いと有効期限は 30 日（OpenSSL 3.5.8） |
| EL10 のカーネルの設定 | `CONFIG_MODULE_SIG=y`・`CONFIG_MODULE_SIG_HASH="sha512"`・`CONFIG_LOCK_DOWN_IN_EFI_SECURE_BOOT=y`・`CONFIG_INTEGRITY_CA_MACHINE_KEYRING=y`・`CONFIG_INTEGRITY_CA_MACHINE_KEYRING_MAX=y`・`CONFIG_KVM=m`（kernel-devel の `.config`） |
| EL10 の kvm.ko | `modinfo -p` に `enable_virt_at_load: (bool)`。`readelf` で変数が `.data` 節にあり、その 1 バイトが `01` |
| KVM と共存する仕組み | `SUPDrv-linux.c` の `#if RTLNX_VER_MIN(6,16,0) && ...` の中だけ。ビルドした `vboxdrv.ko` は `softdep` が空で、`/dev/kvm` の文字列が 0 件 |
| KVM と衝突したときの文 | `VBoxVMM.so` の文字列に `VirtualBox can't operate in VMX root mode. ...` と `VirtualBox can't enable the AMD-V extension. ...` |
| setuid と udev | `VirtualBoxVM` / `VBoxHeadless` / `VBoxNetAdpCtl` が `-r-s--x--x root root`。`/dev/vboxdrv` の udev ルールは `root` の `0600`、USB の機器ノードは `VBoxCreateUSBNode.sh` が `root:vboxusers` の `0660` で作る |
| GUI のライブラリ | `/usr/lib/virtualbox` の ELF 48 個すべてで `ldd` の `not found` が 0。Qt 6 は `/lib64/libQt6*.so.6`（AppStream） |
| `kernel-devel` の installonly | 古い `kernel-devel-6.12.0-211.55.1.el10_2` を入れた状態で `dnf upgrade --assumeno kernel-devel` → `Installing: kernel-devel 6.12.0-211.56.1.el10_2` |
| 更新 | 7.2.18 → 7.2.20 の `dnf upgrade` でモジュールが `7.2.20 r175154` になり、`/sbin/vboxconfig` と udev のルールが残った |
| 系列の切り替え | 7.2 を入れたまま 7.1 → ファイルの衝突 501 件。`dnf swap` → 新しい系列のモジュールと設定が消えた。remove → install → 揃った（[更新の補足](#更新の補足)） |
| ロールバックの残り物 | 本体と依存を消した後に、`vboxusers` グループ・`/var/log/vbox-setup.log`・`~/.config/VirtualBox`・dnf のキャッシュ（鍵を含む）・rpm の鍵・MOK の鍵のファイルが残った。本文のロールバックはこれを消す形にしてある |
| systemd を PID 1 にしたコンテナ | 立ち上がらなかった（ログを出さずに終了コード 255。ホストは cgroup v1 で、EL10 の systemd 257 は cgroup v1 では起動しない見込み）。そのため `vboxdrv.service` の生成と有効化は確かめていない |

**読んだファイル**: rpm と同じ 7.2.20 の汎用インストーラ（`VirtualBox-7.2.20-175154-Linux_amd64.run`）の中の `vboxdrv.sh`・`postinst-common.sh`・`prerm-common.sh`・`routines.sh`・`check_module_dependencies.sh`・`VBox.sh`・`src/vboxhost/vboxdrv/linux/SUPDrv-linux.c` と、rpm のヘッダの `%pre` / `%post` / `%preun` / `%postun`。rpm が入れる `/usr/lib/virtualbox/` と `/usr/share/virtualbox/src/vboxhost/` の同じ名前のファイルも、コンテナで確かめた。

#### 未確認事項

- 実機（x86_64 PC）での本実行（本書は実機に適用していない。検証はコンテナのみ）
- VT-x / AMD-V のある PC での `lscpu` の `Virtualization:` の表示
- モジュールの読み込みと、`vboxdrv.service` の生成・有効化・起動時の動作
- Secure Boot: MokManager での登録、鍵が `.platform` に入ること（`keyctl list %:.platform`）、署名したモジュールが受け入れられること、MOK の削除
- `enable_virt_at_load=0`（modprobe.d）が起動時に効くことと、KVM を使う PC（libvirt / GNOME Boxes）で VirtualBox の VM が起動すること。効かないときのカーネル引数（`grubby`）の方法
- 使い捨ての VM の起動（`startvm --type headless`）と、KVM とぶつかったときのエラーの実際の出方（本文の文は `VBoxVMM.so` の文字列から写しただけ）
- USB の受け渡し（`vboxusers`、`VBoxManage list usbhost`）
- GUI の表示（Wayland のままか XWayland 経由か、HiDPI、日本語入力）
- カーネルを更新して再起動したときの自動ビルドと、起動の遅れ
- デスクトップの PC での依存の数（コンテナでは 89 パッケージ）と、ロールバックで消える数
- SELinux（Enforcing）の下での動作（`%post` の `chcon` と、`restorecon` の影響）
- 実際の 7.2 → 7.3 の切り替え（7.3 はまだ出ていない）
- Extension Pack と Guest Additions（本書の対象外）
