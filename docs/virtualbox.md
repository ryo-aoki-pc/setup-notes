# VirtualBox インストール手順（AlmaLinux 10 は Oracle 公式 dnf リポジトリ / Windows 11 は winget）

## 実施手順

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（管理者の Windows PowerShell 5.1 に貼る。下の EPEL と Secure Boot の前提、KVM の設定は要らない）
> - **前提**: [EPEL](epel.md) を有効にしてあること（依存の `liblzf` が EPEL にしか無い）。`dnf repolist enabled | grep -E '^epel'` で何も出なければ、先に通す
> - **前提（Secure Boot が有効な PC）**: [secure-boot-mok.md](secure-boot-mok.md) で、モジュールの署名鍵を MOK に登録してあること（VirtualBox を入れるより前に。同書で再起動し、起動の途中の MokManager を操作する）。Secure Boot が有効かは、同書の手順 3 で分かる
> - **対象ホスト（x86_64 の PC）上で実行する**。VirtualBox には Linux の arm64 版が無いので、Raspberry Pi 5（aarch64）には入らない
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない
> - **途中で再起動が 1 回入る**（手順 13）。再起動した後は新しい端末を開いて続ける
> - **手順 4・5・9 には対話入力がある**（鍵の確認・`[y/N]`）。答えてから次の手順を貼る
> - **手順 17 で GUI のウィンドウが開く**（デスクトップにログインした端末から行う）。閉じてから手順 18 を貼る

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: カーネルを更新したときは[カーネルを更新したとき](#カーネルを更新したとき)、以後の VirtualBox の更新は[更新](#更新)、戻すときは[ロールバック](#ロールバック)

> [!WARNING]
> **Secure Boot が有効な分岐（前提の [secure-boot-mok.md](secure-boot-mok.md) と手順 15）は、実機では最後まで通せていない**（[対象と検証環境](#対象と検証環境)）。
>
> - 検証した PC では、secure-boot-mok.md の手順 6 の MokManager でキーボードが効かず、鍵を登録できなかった
> - UEFI の設定で Secure Boot を無効にし、無効の分岐で手順 9 から最後まで本実行した

1. この PC に入るかを確かめる。

   ```bash
   uname -m
   lscpu | grep -E '^Virtualization:' || echo 'CPU の仮想化支援が見えない'
   ```

   - `uname -m` が `x86_64` で、`Virtualization:` の行に `VT-x`（Intel）か `AMD-V`（AMD）が出ればよい
   - **`aarch64` なら VirtualBox は入らないので、ここで止める**
   - `CPU の仮想化支援が見えない` と出たら、PC の UEFI（BIOS）の設定で Intel VT-x / AMD-V（SVM）を有効にしてから始める

   <details>
   <summary>補足: 実機とコンテナでの表示</summary>

   - 実機（AMD のノート PC）では、`x86_64` と `Virtualization:                          AMD-V` が出た
   - 検証コンテナでは `lscpu` に `Virtualization:` の行が出なかった（コンテナを動かしているクラウドのホストに仮想化支援が無い）

   </details>

1. Oracle の署名鍵を落として、取り込む前に fingerprint を見る。

   ```bash
   curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc -o /tmp/oracle_vbox_2016.asc
   gpg --show-keys --with-fingerprint /tmp/oracle_vbox_2016.asc
   ```

   - `gpg` が無ければ、`sudo dnf install -y gnupg2` で入れてから貼り直す（GNOME のデスクトップには入っている）
   - 次の値と一致することを目で確かめる
     - fingerprint `B9F8 D658 297A F3EF C18D 5CDF A2F6 83C5 2980 AECF`
     - uid `Oracle Corporation (VirtualBox archive signing key) <info@virtualbox.org>`
   - `sub` の下にも fingerprint が出ることがある（Homebrew の gnupg が先に見つかる PC。手順 3 の補足）。照らし合わせるのは `pub` の下の行
   - 違っていればここで止める
   - **次の手順は、fingerprint と uid が一致するのを確かめてから貼る**

1. 一致したら、鍵を rpm に取り込み、入ったか確かめて、落としたファイルを消す。

   ```bash
   {
     sudo rpm --import /tmp/oracle_vbox_2016.asc
     rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i virtualbox
     rm -f /tmp/oracle_vbox_2016.asc
   }
   ```

   - `gpg-pubkey-2980aecf-5719f4e1 Oracle Corporation (VirtualBox archive signing key) ...` が出れば入っている

   <details>
   <summary>補足: 鍵は EL10 の rpm に受け入れられる</summary>

   `gpg --show-keys` の実測（鍵束には取り込まれない。`~/.gnupg` が無ければ最初の実行で作られる）:

   ```
   pub   rsa4096 2016-04-22 [SC]
         B9F8 D658 297A F3EF C18D  5CDF A2F6 83C5 2980 AECF
   uid                      Oracle Corporation (VirtualBox archive signing key) <info@virtualbox.org>
   sub   rsa4096 2016-04-22 [E]
   ```

   - 実機では `gpg` が Homebrew の gnupg 2.5.24 で、`sub` の下に副鍵の fingerprint（`31DD 01EB 8C64 DF3D 12E7  BC97 AD18 C79D 920E 471F`）の行も出た。`/usr/bin/gpg`（EL10 の 2.4.5）の表示は上と同じ
   - **自己署名のハッシュは SHA-512**（`gpg --list-packets` で `digest algo 10`）なので、EL10 の rpm が SHA-1 の自己署名を拒む問題（[tool-catalog.md の注意点](tool-catalog.md#注意点)）には当たらず、`rpm --import` は何も出さずに終了コード 0 で終わった（実機でも同じ）
   - 7.2.20 の EL10 向け rpm の署名と、リポジトリのメタデータの署名（`repomd.xml.asc`）は、どちらもこの鍵（`A2F683C52980AECF`、SHA-256）で作られていた（rpm のヘッダとメタデータを直接読んで確認）

   Oracle は 2010 年の古い鍵 `oracle_vbox.asc`（dsa1024）も配っているが、これは古いパッケージ用で、本書では使わない。

   </details>

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
   - `Importing GPG key 0x2980AECF:` の `Fingerprint:` が、手順 2 と同じ `B9F8 D658 297A F3EF C18D 5CDF A2F6 83C5 2980 AECF` であることを確かめて `y` と答える
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
   - 手順 4 と同じ fingerprint を確かめて `y` と答える
   - **次の手順は、答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 鍵の確認が 2 回要る理由</summary>

   `repo_gpgcheck=1` のリポジトリでは、dnf はメタデータの署名を**リポジトリごとの鍵束**で確かめる。

   - この鍵束は rpm のデータベース（手順 3 の `rpm --import`）とは別物
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
   - `nothing provides liblzf.so.1()(64bit)` と出たら、[EPEL](epel.md) が有効になっていない（この手順の補足）

   <details>
   <summary>補足: パッケージ名と下見の結果、EPEL が要る理由</summary>

   **パッケージ名に系列（7.2）が入っている**（Oracle のリポジトリでの名前）。

   - 系列の無い `VirtualBox` という名前は無く、`sudo dnf install --assumeno VirtualBox` は `No match for argument: VirtualBox` で終わる（実測）
   - 調査日（2026-09-24）のリポジトリには `VirtualBox-7.2`（7.2.0〜7.2.20）と `VirtualBox-7.1`（7.1.10〜7.1.18）がある
   - **7.1 と 7.2 は同時には入れられない**（[更新](#更新)）。本書は 7.2 だけを検証している

   **デスクトップの実機（GNOME）での下見**: 16 パッケージ（ダウンロード 135 M、展開後 350 M）だった。

   - `VirtualBox-7.2` のほかは、`libXt`・`libglvnd-opengl`・`liblzf`（epel）・`libtpms`・`xcb-util-cursor` と、Qt 6 の 10 個（`qt6-qttranslations` は弱い依存）

   **下見の結果**（素のコンテナ）:

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
   - gcc や kernel-devel は依存に含まれないので、手順 8 で別に入れる

   **`liblzf` は EPEL にしか無い**（前提を [EPEL](epel.md) にした理由）:

   - Oracle の EL10 向け rpm は `liblzf.so.1()(64bit)` を要求するが、これを持つ `liblzf-3.6-28.el10_0` は **EPEL 10 にしかない**（BaseOS / AppStream / CRB / extras の一覧に無いことを確かめた）
   - ほかの依存（Qt 6、`libtpms`、`libvpx`、`vulkan-loader` など）は AppStream / BaseOS にある

   EPEL 無しでこの下見をしたときの実測:

   ```
   Error: 
    Problem: cannot install the best candidate for the job
     - nothing provides liblzf.so.1()(64bit) needed by VirtualBox-7.2-7.2.20_175154_el10-1.x86_64 from virtualbox
   ```

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

1. カーネルモジュールのビルドに要るものを、VirtualBox より先に入れて確かめる。

   ```bash
   {
     sudo dnf install -y gcc make perl-interpreter mokutil openssl "kernel-devel-$(uname -r)"
     rpm -q gcc make perl-interpreter mokutil openssl "kernel-devel-$(uname -r)"
     ls -d "/lib/modules/$(uname -r)/build/include"
   }
   ```

   - VirtualBox は、自分のカーネルモジュール（`vboxdrv` / `vboxnetflt` / `vboxnetadp`）を**インストールの途中で、この PC の上でビルドする**
   - 6 つとも版が出て、最後の行がディレクトリを返せばよい
   - `No such file or directory` なら、kernel-devel の版が合っていない

   <details>
   <summary>補足: なぜ先に入れるのか、何が要るのか</summary>

   **rpm のインストール後スクリプト（`%post`）が、その場でモジュールをビルドして読み込む。**

   - そのときに道具が無いと、ビルドは失敗するのに `dnf install` は `Complete!` で終わる（手順 9 の補足）
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
   - openssl は、[secure-boot-mok.md 手順 4](secure-boot-mok.md#実施手順) の鍵の作成と、スクリプトの署名の確認に使う（Secure Boot が有効な PC では、前提の同書で入っている）
   - Secure Boot が無効でも、入れておいて害は無い

   **`kernel-devel` は installonly**（`installonlypkg(kernel)` を提供する）なので、`sudo dnf upgrade` で新しいカーネルが来ると、同じ版の kernel-devel が**古いものと並べて**入る。

   - 古い `kernel-devel` を入れた状態で `sudo dnf upgrade --assumeno kernel-devel` を実行し、新しい版が `Upgrading` ではなく `Installing` として出ることを確かめた
   - `/lib/modules/<版>/build` のリンクは kernel-devel ではなく、そのカーネルの `kernel-modules-core` が持っている（動いているカーネルなら必ず入っている）

   </details>

1. VirtualBox を入れる。

   ```bash
   sudo dnf install VirtualBox-7.2
   ```

   - トランザクション表を見て、`[y/N]` に `y` と答える
   - **EPEL の署名鍵をまだ取り込んでいなければ、続けて 1 回だけ確認を求められる**（[epel.md 手順 3](epel.md#実施手順) に書いた鍵）
     - `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`、Fedora (epel10) &lt;epel@fedoraproject.org&gt;
   - 最後に `Creating group 'vboxusers'. VM users must be member of that group!` が出て、続けてモジュールのビルドが走る
   - **次の手順は、`[y/N]` と鍵の確認に答え、`Complete!` が出てから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: <code>%post</code> がやること</summary>

   rpm の `%post` は、`vboxusers` グループを作ったあと `/usr/lib/virtualbox/postinst-common.sh > /dev/null || true` を実行する。

   - これが systemd の unit `vboxdrv.service` を**その場で生成して enable し**、`/usr/lib/virtualbox/vboxdrv.sh setup` でモジュールをビルド・署名・読み込みする
   - 標準出力は捨てられ、失敗も `|| true` で無視されるので、**dnf から見るとどんな場合も成功になる**
   - 失敗の内容は標準エラーに出る（手順 8 の補足の実測）ので、`dnf install` の出力は最後まで見る
   - **`/sbin/vboxconfig`** は `postinst-common.sh` へのリンクで、同じ処理を最初からやり直す（実測で `/sbin/vboxconfig -> /usr/lib/virtualbox/postinst-common.sh`、`/sbin/rcvboxdrv -> /usr/lib/virtualbox/vboxdrv.sh`）
   - **`/usr/lib/systemd/system/vboxdrv.service` は rpm の持ち物ではない**（`%post` が書き、削除時に `%preun` が消す）
     - 中身は `ExecStart=/usr/lib/virtualbox/vboxdrv.sh start`・`TimeoutSec=5min`・`WantedBy=multi-user.target`
     - 実機では、`rpm -qf` が `is not owned by any package` を返し、`systemctl cat vboxdrv` に上の 3 行（と `SourcePath=/usr/lib/virtualbox/vboxdrv.sh`・`Type=forking`）があり、`enabled` / `active` になった
   - **ビルドは数十秒**: コンテナでは 3 つのモジュールを 11 秒でビルドした。実機では、`[y/N]` に答えてから `Complete!` まで約 20 秒（ダウンロードを含む）。`/lib/modules/$(uname -r)/misc/` に `vboxdrv.ko` / `vboxnetflt.ko` / `vboxnetadp.ko` ができる
   - 実機での表示は、`Creating group 'vboxusers'. VM users must be member of that group!` の後に空行が続き、`Installed:` の一覧と `Complete!` が出ただけだった（ビルドの経過は標準出力なので出ない）
   - **Secure Boot が無効なら署名しない**: 実機では、[secure-boot-mok.md](secure-boot-mok.md) の手順 4 の鍵のファイルがあっても、3 つのモジュールの `modinfo -F signer` は空だった
   - **`/dev/vboxdrv` は `root:root` の `0600`**（`%post` が書く `/etc/udev/rules.d/60-vboxdrv.rules` の実測）。VM を動かす `VirtualBoxVM` と `VBoxHeadless` が setuid root（`-r-s--x--x`）なので、一般ユーザーは直接触らない
   - **`vboxdrv.sh setup`（= `vboxconfig`）は、ほかのカーネル用も含めて vbox のモジュールを全部消してから、動いているカーネル用だけを作り直す**。別のカーネル用に作る目的では使わない
   - SELinux のラベルは `chcon` で付けている。実機（Enforcing）では、モジュールが `modules_object_t` になり、`sudo restorecon -nv` は何も変えなかった（`restorecon` で戻ってもラベルは同じ）。VirtualBox にかかわる AVC の拒否も無かった

   **Secure Boot のときは、[secure-boot-mok.md](secure-boot-mok.md) の鍵で署名する。** `/usr/lib/virtualbox/vboxdrv.sh` は、次の 2 つがそろうと、ビルドしたモジュールを `/var/lib/shim-signed/mok/MOK.priv` と `MOK.der` で署名する（道具は kernel-devel の `scripts/sign-file`）。

   - `mokutil --sb-state` が `SecureBoot enabled` を返す
   - カーネルの設定が署名を求める（EL10 のカーネルは `CONFIG_MODULE_SIG=y`・`CONFIG_LOCK_DOWN_IN_EFI_SECURE_BOOT=y`・`CONFIG_MODULE_SIG_HASH="sha512"`。kernel-devel の `.config` で確認）

   鍵が無いと、ビルドまでして署名で止まり、この案内を出す（`mokutil` を「Secure Boot 有効」と答えるスタブに差し替えたコンテナでの実測。secure-boot-mok.md の手順 4 は、この案内に `-subj` と `-days` を足したもの）:

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

   鍵で署名したモジュールの実測（コンテナ。このときの鍵の CN は `VirtualBox module signing key`。今の secure-boot-mok.md の鍵なら `Local kernel module signing key` が出る）:

   ```
   $ modinfo -F signer /lib/modules/6.12.0-211.56.1.el10_2.x86_64/misc/vboxdrv.ko
   VirtualBox module signing key
   $ modinfo -F sig_hashalgo /lib/modules/6.12.0-211.56.1.el10_2.x86_64/misc/vboxdrv.ko
   sha512
   ```

   - **インストールより先に鍵を登録しておく理由**: 鍵が登録済みなら、`%post` がビルド → 署名 → 読み込みまで一度に済ませる
   - 登録前に入れると、鍵があっても読み込みで失敗し、`vboxdrv.sh: You must sign these kernel modules before using VirtualBox:` と `modprobe vboxdrv failed` が出る（スタブで「未登録」と答えさせたときの実測）
   - `vboxdrv.sh` は、登録を `mokutil --test-key` の出力に `is already` が含まれるかで見ている
   - Secure Boot を後で有効に戻すと、署名の無いモジュールは読み込まれず、VM が動かなくなる見込み。そのときは secure-boot-mok.md で鍵を登録し、`sudo /sbin/vboxconfig` でモジュールを作り直す（どちらも未確認）

   </details>

1. `Complete!` だけでは成功とは限らないので、モジュールが動いているか確かめる。

   ```bash
   systemctl is-enabled vboxdrv
   systemctl is-active vboxdrv
   lsmod | grep -E '^vbox'
   ls -l /dev/vboxdrv
   sudo tail -n 5 /var/log/vbox-setup.log
   ```

   - モジュールのビルドや読み込みに失敗しても、dnf は `Complete!` で終わる（手順 9 の補足）
   - `enabled` と `active`、`vboxnetadp` / `vboxnetflt` / `vboxdrv` の 3 行、root だけが読み書きできる `/dev/vboxdrv` が出ればよい
   - `dnf install` の途中で `There were problems setting up VirtualBox.` が出ていた、または `active` にならないときは、ログ（`/var/log/vbox-setup.log`）で原因を見る
   - 原因を直してから、`sudo /sbin/vboxconfig` を実行し直す

1. KVM が仮想化支援を先に取らないように、modprobe.d に設定を置いて確かめる。

   ```bash
   {
     echo 'options kvm enable_virt_at_load=0' | sudo tee /etc/modprobe.d/kvm-virtualbox.conf
     cat /etc/modprobe.d/kvm-virtualbox.conf
     modprobe -c | grep enable_virt_at_load
   }
   ```

   - **EL10 のカーネル（6.12 系）では、KVM のモジュールが読み込まれた時点で VT-x / AMD-V を確保し、VirtualBox の VM が起動できなくなる**（この手順の補足）
   - KVM を使っていなくても、VT-x / AMD-V のある PC では起動時に自動で読み込まれる
   - この設定で、KVM が自分の VM を動かす間だけ確保するように変える
   - `cat` と `modprobe -c` のどちらにも `options kvm enable_virt_at_load=0` が出ればよい（後者は modprobe が読んだ設定）
   - `modprobe -c` には `alias symbol:enable_virt_at_load kvm` の行も出る（モジュールの別名の一覧の行で、気にしなくてよい）
   - **効くのは次に kvm が読み込まれたとき**なので、手順 13 の再起動で反映させる
   - KVM（libvirt / GNOME Boxes など）はこの後も使えるが、**KVM の VM と VirtualBox の VM は同時には動かせない**

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

   衝突したときのエラー文は `/usr/lib/virtualbox/VBoxVMM.so` にある（手順 16 の補足の表も見る）:

   - Intel は `VirtualBox can't operate in VMX root mode. Please disable the KVM kernel extension, recompile your kernel and reboot`
   - AMD は `VirtualBox can't enable the AMD-V extension. ...`
   - 実機（AMD）では、この手順の設定をして再起動する前に手順 16 を貼ると、AMD の文で起動に失敗した（手順 16 の補足）

   **カーネル引数ではなく modprobe.d にした理由**: Oracle の変更履歴の案内はカーネル引数で、EL10 に当てはめると `sudo grubby --update-kernel=ALL --args=kvm.enable_virt_at_load=0` になる。

   - kvm は読み込み可能なモジュール（`CONFIG_KVM=m`）なので、modprobe.d の設定でも効く
   - こちらは起動エントリを書き換えず、カーネルの更新にも左右されない
   - 実機では、手順 13 の再起動の後に `enable_virt_at_load` が `N` になり（`kvm_amd` は起動時に読み込まれたまま）、手順 16 の VM が起動した
   - 手順 14 で `N` にならないとき、または手順 16 で VM が起動しないときは、grubby の方法を試す（こちらは未確認）

   </details>

1. USB 機器を VM に渡すときだけ、自分を `vboxusers` に入れて確かめる。

   ```bash
   {
     sudo usermod -aG vboxusers "${USER}"
     getent group vboxusers
   }
   ```

   - **VM を動かすだけなら要らない**（この手順は飛ばして手順 13 へ）
   - `vboxusers:x:<GID>:<USER>` のように、自分の名前が出ればよい
   - **効くのはログインし直してから**（手順 13 の再起動で済む）

   <details>
   <summary>補足: グループが効くのは USB だけ</summary>

   - `%post` は「VM users must be member of that group!」と出すが、7.2 の rpm では `/dev/vboxdrv` が `root:root 0600` で、VM は setuid の `VirtualBoxVM` / `VBoxHeadless` から動く（手順 9 の補足）
   - `vboxusers` が使われるのは USB の機器ノード。udev ルールが呼ぶ `/usr/lib/virtualbox/VBoxCreateUSBNode.sh` が、`/dev/vboxusb/<バス>/<機器>` を `root:vboxusers` の `0660` で作る（スクリプトの既定のグループが `vboxusers`）
   - Oracle のマニュアルも「USB 機器を使うユーザーは vboxusers に入れる」と書いている
   - **USB を実際に VM に渡すことは確かめていない**（`VBoxManage list usbhost` で見える機器の一覧など）

   </details>

1. 再起動して、手順 11 の KVM の設定と、手順 12 のグループを反映させる。

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
   - 最後の行は、手順 12 を行ったときだけ `vboxusers` になる
   - **版の前に `WARNING: The vboxdrv kernel module is not loaded.` が出たら、モジュールが読み込まれていない**（手順 10 に戻る）

1. Secure Boot が有効なときだけ、モジュールの署名を見る。

   ```bash
   modinfo -F signer vboxdrv
   ```

   - `Local kernel module signing key` が出れば、[secure-boot-mok.md](secure-boot-mok.md) の鍵で署名したモジュールが使われている（2026-09-30 より前にこの文書で作った鍵なら `VirtualBox module signing key`）

1. 使い捨ての VM を画面無しで起動し、状態を見てから止めて消す。

   ```bash
   if VBoxManage showvminfo vbox-selftest >/dev/null 2>&1; then
     echo 'vbox-selftest はすでにある。変更せずに中断する' >&2
   elif VBoxManage createvm --name vbox-selftest --ostype Other_64 --register; then
     if VBoxManage modifyvm vbox-selftest --memory 64 --nic1 none --audio-enabled off &&
        VBoxManage startvm vbox-selftest --type headless; then
       VBoxManage showvminfo vbox-selftest --machinereadable | grep -E '^VMState='
       VBoxManage controlvm vbox-selftest poweroff
     fi
     VBoxManage unregistervm vbox-selftest --delete
   else
     echo 'VM を作れなかった。変更・起動・削除は行わない' >&2
   fi
   ```

   - VirtualBox が VT-x / AMD-V を取れるか（KVM とぶつからないか）は、ここで初めて分かる
   - 既に `vbox-selftest` があれば、変更せず中断する。別の名前で試すなら、ブロック中の `vbox-selftest` をすべて同じ名前に変える
   - 作成に失敗したときも、変更・起動・削除には進まない。削除するのは、このブロックで作成できた VM だけ
   - `VM "vbox-selftest" has been successfully started.` が出れば動いている（起動するディスクが無いので、中では何も動かない）
   - `VMState="running"` なら動いていた
   - `controlvm ... poweroff` で止まり、`unregistervm ... --delete` は `0%...10%...` と進んで、VM のファイルごと消える（実機では、`poweroff` と `unregistervm` のそれぞれが `0%...100%` の行を出した）

   <details>
   <summary>補足: 出るエラーと対処</summary>

   | 出るもの | 意味 | 対処 |
   |---|---|---|
   | `WARNING: The vboxdrv kernel module is not loaded. Either there is no module available for the current kernel (...) or it failed to load.` | モジュールが無いか、読み込めていない。`VBoxManage` などを包むスクリプト（`VBox.sh`）が、コマンドの前に標準出力へ出す | `sudo tail -n 20 /var/log/vbox-setup.log` で原因を見て `sudo /sbin/vboxconfig`。Secure Boot なら [secure-boot-mok.md 手順 3〜7](secure-boot-mok.md#実施手順) |
   | `VirtualBox can't operate in VMX root mode. Please disable the KVM kernel extension, recompile your kernel and reboot`（`VERR_VMX_IN_VMX_ROOT_MODE`） | Intel: KVM が VT-x を確保している | `enable_virt_at_load` が `N` か見る（手順 11）。KVM の VM が動いていれば止める |
   | `AMD-V is being used by another hypervisor (VERR_SVM_IN_USE).` と、続けて `VirtualBox can't enable the AMD-V extension. Please disable the KVM kernel extension, recompile your kernel and reboot (VERR_SVM_IN_USE)` | AMD: 同上 | 同上 |
   | `Key was rejected by service`（`sudo modprobe vboxdrv` や `dmesg`） | Secure Boot で署名が受け入れられない | `sudo mokutil --test-key`（[secure-boot-mok.md 手順 7](secure-boot-mok.md#実施手順)）。**この文は一般的なカーネルのエラーで、本書では出していない**。鍵が登録されていないときの EL10 の文は `Loading of module with unavailable key is rejected`（VM の中で出た） |
   | `There were problems setting up VirtualBox.  To re-start the set-up process, run /sbin/vboxconfig as root.` | `dnf install` の途中でビルド・署名・読み込みのどこかが失敗した | `/var/log/vbox-setup.log` を見る |

   - AMD の 2 行は、実機（AMD）で手順 11 の設定を再起動で効かせる前に、この手順を貼って出した（後ろに `Details: code NS_ERROR_FAILURE (0x80004005), component ConsoleWrap, interface IConsole`、`VMState="poweroff"`、`Machine 'vbox-selftest' is not currently running.` が続いた）
   - Intel の文は、実機で出したものではなく `/usr/lib/virtualbox/VBoxVMM.so` の中の文字列から写した

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
   - VirtualBox マネージャーのウィンドウが開く（手順 16 の VM は消してあるので一覧は空）
   - 端末に `Qt WARNING: QObject::disconnect: wildcard call disconnects from destroyed signal of UIInvisibleWindow::unnamed` が何行か出るが、気にしなくてよい
   - ウィンドウを閉じると、端末がプロンプトに戻る
   - **次の手順は、ウィンドウを閉じてから貼る**（続けて貼ると VirtualBox への操作として食われる）

   <details>
   <summary>補足: GUI のライブラリ</summary>

   - GUI は AppStream の Qt 6（`/lib64/libQt6*.so.6`）を使う
   - `/usr/lib/virtualbox` の下の ELF ファイル 48 個すべてで、`ldd` の `not found` が 0 だった（コンテナで確認）
   - Qt の表示の土台は xcb（X11）と wayland の両方のプラグインが入り、VirtualBox の実行ファイルには `QT_QPA_PLATFORM` と `wayland` の文字列がある
   - **実機の GNOME の Wayland セッションでは、XWayland 経由で動いた**（プロセスが読み込んでいたのは `platforms/libqxcb.so`。`WAYLAND_DISPLAY` はあり、`QT_QPA_PLATFORM` は無かった）
   - 実機では、利用者がウィンドウの表示を確かめて閉じた（`Qt WARNING` は 3 行）
   - コンテナには画面が無く、`No active display server, X11 or Wayland, detected. Exiting.` で終わった
   - メニューの名前（手順書の本文の日本語と英語）は、`/usr/share/virtualbox/nls/VirtualBox_ja.qm` と `/usr/lib/virtualbox/UICommon.so` の文字列で確かめた（[virtualbox-guest-bootc.md](virtualbox-guest-bootc.md) の付録）

   </details>

1. `~/.config/VirtualBox` に設定ができたか確かめる。

   ```bash
   ls ~/.config/VirtualBox
   ```

   - `VirtualBox.xml` などが並ぶ（実機では `compreg.dat`・`selectorwindow.log`・`VBoxSVC.log`（と `.1`・`.2`）・`VirtualBox.xml`・`VirtualBox.xml-prev`・`xpti.dat`）

---

## カーネルを更新したとき

- この節は AlmaLinux 10 だけのもの（Windows 11 のドライバーは、ビルド済みのものをインストーラが入れる）
- `sudo dnf upgrade` で新しいカーネルが入ると、同じ版の `kernel-devel` も一緒に入る（installonly。[手順 8](#実施手順) の補足）
- **新しいカーネルで起動すると、`vboxdrv.service` がその場でモジュールをビルドし直す**（Secure Boot なら [secure-boot-mok.md](secure-boot-mok.md) の鍵で署名もする）。そのぶん、その 1 回の起動が遅くなる
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

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 の更新](#windows-11-の更新)
- **系列を変えるとき（7.2 → 7.3 など）は、先に消してから入れる**（この節の手順 3・4）
  - 系列ごとにパッケージ名が違うので `dnf upgrade` では移らず、2 つを同時に入れることもできない
  - **7.3 系はまだ出ていないので、本書では 7.1 と 7.2 で試した**（コンテナ。[更新の補足](#更新の補足)）
- VM の設定（`~/.config/VirtualBox` と `~/VirtualBox VMs`）は、rpm の操作では消えない

> [!WARNING]
> 系列の切り替え（この節の手順 3・4）に **`dnf swap` は使わない**。`Complete!` で終わるが、コンテナで試したときは新しい系列のモジュールと設定が消え、動かない状態になった（[更新の補足](#更新の補足)）。

1. VirtualBox の VM と GUI をすべて閉じる。

   - VirtualBox の裏のプロセス `VBoxSVC` が動いていると、rpm の `%pre` が `A copy of VirtualBox is currently running.  Please close it and try again.` で止める

1. 同じ系列の中で、新しい版に上げる。

   ```bash
   sudo dnf upgrade VirtualBox-7.2
   ```

   - トランザクション表を見て `[y/N]` に答える
   - **更新のたびに `%post` がモジュールをビルドし直す**ので、[手順 10](#実施手順) と同じ確認をする
   - コンテナで 7.2.18 → 7.2.20 を上げたときは、`%post` が新規導入のときと同じ表示を出した
   - モジュールは 7.2.20 用に作り直された（`modinfo -F version` が `7.2.18 r175117` → `7.2.20 r175154`）
   - `/sbin/vboxconfig` と udev のルールも残った
   - **[手順 10](#実施手順) の確認は、`[y/N]` に答えて `Complete!` が出てから貼る**（続けて貼ると答えとして食われる）

1. 系列を変えるときは（この節の手順 2 の代わりに）、[ロールバック](#ロールバック)の手順 2 だけを行う。

   - [ロールバック](#ロールバック)の手順 2 は `sudo dnf remove VirtualBox-7.2`
   - `[y/N]` に答えてから、この節の手順 4 に進む

1. 系列を変えるときは、パッケージ名を新しい系列に置き換えて、[手順 6](#実施手順) の下見と手順 9 からやり直す。

   - 手順 6・9 の `VirtualBox-7.2` を、新しい系列の名前（`VirtualBox-7.3` など）に置き換えて貼る
   - 以後は、この節の手順 2 と[ロールバック](#ロールバック)の手順 2 も同じく置き換える
   - repo ファイル・鍵・EPEL・ビルドの道具・MOK・KVM の設定はそのまま使える

---

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)
- この節の手順では消えないもの:
  - **Oracle の署名鍵** `gpg-pubkey-2980aecf-5719f4e1`: 消すなら `sudo rpm -e gpg-pubkey-2980aecf-5719f4e1`
  - **Secure Boot の MOK**（前提の [secure-boot-mok.md](secure-boot-mok.md) で登録した場合）: ほかにその鍵で署名したモジュールを使っていなければ、[secure-boot-mok.md のロールバック](secure-boot-mok.md#ロールバック)で消す
  - **ログ** `/var/log/vbox-setup.log`（と `.1`〜`.4`）: 要らなければ手で消す
  - **前提の EPEL と、手順 8 の gcc / kernel-devel など**: ほかでも使うので消さない
- 本書ではロールバックを**コンテナでのみ本実行した**

> [!CAUTION]
> **この節の手順 4 で、VM とその設定（`~/.config/VirtualBox` と `~/VirtualBox VMs`）が消える**。消した VM は取り戻せない。

1. VirtualBox の VM と GUI をすべて閉じる。

   - VM は、それぞれのウィンドウを閉じるか、VirtualBox マネージャーから止める

1. VirtualBox を消す。

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

   - `vboxusers` グループは rpm を消しても残るので、ここで消す（手順 12 で自分を入れていても、グループごと消える）
   - 最後の 2 行は、手順 4・5 で取り込んだメタデータ用の鍵（`pubring/A2F683C52980AECF.pub`）を含む dnf のキャッシュを消す（root の分とユーザーの分）
   - **`dnf clean all` ではこの鍵は消えなかった**（コンテナで確認）
   - KVM の設定を消したことは、次の起動から効く

1. VM とその設定も消すときだけ、`~/.config/VirtualBox` と `~/VirtualBox VMs` を消す（取り戻せない）。

   ```bash
   rm -rf ~/.config/VirtualBox ~/"VirtualBox VMs"
   ```

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows 11 の PC のデスクトップで行う**。SSH やリモート デスクトップのセッションからは行わない（この節の手順 3 の途中でネットワークがいったん切れ、手順 7 は画面で行う）
> - この節の手順 1 で**管理者の** Windows PowerShell（5.1）を開き、この節の手順 2〜4 と、後ろの Windows 11 の 2 節（更新・ロールバック）のブロックをそこに貼る。この節の手順 5 で**管理者ではない** Windows PowerShell を開き、手順 6・8 をそこに貼る
> - ログインするユーザーは Administrators の一員（VirtualBox は PC 全体に入り、ドライバーを入れる）
> - 前提: [Windows 11 の初期設定の手順 16〜19](windows-setup.md#実施手順)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - **AlmaLinux 10 の前提（EPEL・Secure Boot の MOK の鍵）と KVM の設定は要らない**。Windows のドライバーは、Microsoft の署名付きでインストーラに入っている

- 上から順にコードブロックを貼る。変数は無い
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](#windows-11-のロールバック)
- VM に AlmaLinux の Atomic Desktop を入れて Guest Additions を使うなら、[virtualbox-guest-bootc.md](virtualbox-guest-bootc.md)（Windows のホストでも同じ手順で入った）

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、winget の定義、インストーラの中身と署名、VirtualBox のソースと同梱のマニュアル、Linux の PowerShell 7 での構文と模擬の実行だけ（[対象と検証環境](#対象と検証環境)）。
>
> - 同じ版（7.2.20）は利用者の Windows 11 の PC に入っていて、[virtualbox-guest-bootc.md](virtualbox-guest-bootc.md) の VM を動かした（入れた方法の記録は無い）
> - **その PC では Hyper-V が動いていて（WSL 2 を使う PC）、VM は Hyper-V の上で動き、重い処理の間に 1〜7 分ずつ止まった**。この節の手順 6 で、VM が Hyper-V の上で動くかが分かる（[注意点](#注意点)）

1. Windows のデスクトップで、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く

1. この PC に入るか、今の状態を確かめる。

   ```powershell
   [pscustomobject]@{
     Admin        = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Arch         = $env:PROCESSOR_ARCHITECTURE
     Winget       = (Get-Command winget -ErrorAction SilentlyContinue).Source
     VirtualBox   = Test-Path -LiteralPath "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
     Hypervisor   = (Get-CimInstance -ClassName Win32_ComputerSystem).HypervisorPresent
     VirtFirmware = (Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1).VirtualizationFirmwareEnabled
   } | Format-List
   Get-WindowsOptionalFeature -Online | Where-Object FeatureName -in 'Microsoft-Hyper-V-All', 'VirtualMachinePlatform', 'HypervisorPlatform' | Format-Table FeatureName, State
   ```

   - `Admin : True` と `Arch : AMD64` が出ればよい
   - `Admin` が `False` なら、管理者ではない窓に貼っている。閉じて、この節の手順 1 から
   - `Arch` が `ARM64` なら、この節は扱わない（試していない）
   - `Winget` が空なら、Microsoft Store で「アプリ インストーラー」を更新してから始める
   - `Hypervisor` が `True` なら、Hyper-V のハイパーバイザーが動いている（WSL 2 を使う PC など）。VirtualBox の VM は Hyper-V の上で動き、遅くなる（[注意点](#注意点)）
   - `Hypervisor` が `False` で `VirtFirmware` も `False` なら、PC の UEFI（BIOS）の設定で Intel VT-x / AMD-V（SVM）を有効にしてから始める
   - 最後の表は、Hyper-V を使う Windows の機能の状態（`Enabled` / `Disabled`）。一覧を作るのに数秒かかる
   - `VirtualBox` が `True` なら、もう入っている。この節の手順 3 は飛ばす（新しい版にするなら[Windows 11 の更新](#windows-11-の更新)）

   <details>
   <summary>補足: 見ているもの</summary>

   - `Hypervisor` は `Win32_ComputerSystem` の `HypervisorPresent`（Microsoft の説明は「True なら、ハイパーバイザーがある」）
   - `VirtFirmware` は `Win32_Processor` の `VirtualizationFirmwareEnabled`（「True なら、ファームウェアが仮想化の拡張を有効にしている」）。`Hypervisor` が `True` の PC では、Hyper-V が仮想化支援を使っているので、この値で判断しない
   - 最後の表の 3 つは、Hyper-V Platform・Virtual Machine Platform・Windows Hypervisor Platform
     - VirtualBox のマニュアルのトラブルシューティング（13.7.6.7）は、Hyper-V と一緒に使うと遅くなるので、この 3 つを切って再起動するよう勧めている。本書は切らない（[選択した方針](#選択した方針)）
     - Home のエディションには `Microsoft-Hyper-V-All` の行が無い
     - マニュアルの 11.30 は、Hyper-V の上で VM を動かすには Windows Hypervisor Platform（`HypervisorPlatform`）も要ると書いている。利用者の PC でそれが有効だったかは、記録が無い

   </details>

1. VirtualBox が入っていないときだけ、winget で入れる。

   ```powershell
   winget install --exact --id Oracle.VirtualBox --source winget --accept-source-agreements --accept-package-agreements
   ```

   - 依存の Microsoft Visual C++ の再頒布可能パッケージ（`Microsoft.VCRedist.2015+.x64`）が無ければ、先にそれが入る
   - **途中でネットワークがいったん切れる**（VirtualBox のネットワークのドライバーを入れるため）
   - インストーラの画面は出ず、進み具合だけが出る。最後に、入れ終えた旨の行（英語の表示では `Successfully installed`）が出ればよい
   - デスクトップとスタートメニューに「Oracle VirtualBox」のショートカットができる
   - **次の手順は、winget が終わってプロンプトに戻ってから貼る**（続けて貼ると、winget が何か聞いたときの答えとして食われる）

   <details>
   <summary>補足: winget の定義と、インストーラがすること</summary>

   **winget の定義（7.2.20）**（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）

   - `InstallerType: exe`、`Scope: machine`。インストーラは `download.virtualbox.org` の `VirtualBox-7.2.20-175154-Win.exe` で、winget が sha256 を確かめてから動かす（公式の `SHA256SUMS` と同じ値）
   - 渡すスイッチは `--silent` と `-msiparams REBOOT=ReallySuppress`（自分では再起動しない）。終了コード 3010（再起動が要る）も成功として扱う
   - 依存は `Microsoft.VCRedist.2015+.x64` だけ。winget は依存を既定で先に入れる（`--skip-dependencies` で止める）
     - VirtualBox の MSI は、Visual C++ 2019 以上の再頒布可能パッケージが無いと「needs the Microsoft Visual C++ 2019 Redistributable Package being installed first」で止まる
   - Python は依存に無い。Python のバインディング（任意の機能）は、Python が無ければ入れずに進む
     - ソースの `InstallPythonAPI` は、失敗しても成功を返す。画面で入れるときは「Missing Dependencies」の確認が出る
   - `--accept-source-agreements` と `--accept-package-agreements` は、winget を初めて使う PC で出る同意の問いに答えるため（続けて貼った行が答えとして食われないように）

   **インストーラがすること**

   - PC 全体に入れる。置き場所は `C:\Program Files\Oracle\VirtualBox`
   - 入れる機能は、既定ですべて: 本体・USB のドライバー・ブリッジ接続のドライバー（`VBoxNetLwf`）・ホストオンリーのアダプター（`VirtualBox Host-Only Ethernet Adapter` を 1 つ作る）・Python のバインディング
   - ネットワークが切れるのは、MSI の画面の警告（「During the installation of [ProductName] Networking, your network will be disconnected.」）に書いてあること。winget はこの画面を出さない
   - `--silent` のときは、Oracle の証明書を PC の「信頼された発行元」に入れてから MSI を動かす（ドライバーを入れるときの確認を出さないため。ソースの `InstallCertificates`）
   - ドライバーのカタログは Microsoft（Windows Hardware Compatibility Publisher）の署名付きで、インストーラは Oracle America, Inc. の署名付き。そのため、AlmaLinux 10 のような MOK の鍵の登録は要らない
   - MSI に再起動を予約する処理は無い。使用中のファイルがあるなどで再起動が要るときは、終了コード 3010 になる
   - 入れた後に VirtualBox マネージャーは起動しない（MSI の `VBOX_START` は、最後の画面の「完了」のボタンでだけ使われる）

   </details>

1. 入ったか、ドライバーとホストオンリーのアダプターができたかを確かめる。

   ```powershell
   winget list --exact --id Oracle.VirtualBox
   & "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" --version
   Get-CimInstance -ClassName Win32_SystemDriver -Filter "Name LIKE 'VBox%'" | Format-Table Name, State, StartMode
   Get-NetAdapter -InterfaceDescription 'VirtualBox Host-Only Ethernet Adapter*' | Format-Table Name, InterfaceDescription, Status
   ```

   - `Oracle.VirtualBox` の `7.2.20` の行と、`7.2.20r175154` が出ればよい（版は実行した日の最新）
   - `VBoxManage` は `PATH` に入らないので、場所を付けて呼ぶ
   - ドライバーは `VBoxSup`・`VBoxNetLwf`・`VBoxNetAdp`・`VBoxUSBMon` などが出て、`VBoxSup` が `Running` ならよい
   - ホストオンリーのアダプターが 1 つ出る（`Name` は `イーサネット 2` のように PC で違う）

   <details>
   <summary>補足: VBoxManage の場所と、ドライバーの名前</summary>

   - インストーラが足す環境変数は `VBOX_MSI_INSTALL_PATH`（PC 全体。インストール先）だけで、`PATH` は変えない（MSI の `Environment` の表）
   - `VBoxManage --version` は、VirtualBox のサービス（`VBoxSVC`）を起動せずに版を出して終わる（ソースで、COM の初期化より前に版を出す）。そのため、この管理者の窓で呼んでよい
   - ドライバーの名前は、INF の `AddService` の名前: `VBoxSup`（VM を動かす支援のドライバー。Linux の `vboxdrv` に当たる）・`VBoxNetLwf`（ブリッジ接続）・`VBoxNetAdp`（ホストオンリー）・`VBoxUSBMon` と `VBoxUSB`（USB）
   - ほかに、サービスの `VBoxSDS`（VirtualBox system service、手動で起動）が入る
   - ホストオンリーのアダプターの接続が、パブリックとプライベートのどちらになるかは確かめていない

   </details>

1. Windows のデスクトップで、管理者ではない Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（右クリックの「管理者として実行」にはしない）
   - VM と VirtualBox マネージャーは、自分のユーザー（管理者ではない権限）で動かす（この手順の補足）
   - この節の手順 1 の管理者の窓は、後ろの Windows 11 の 2 節で使う。閉じてもよい

   <details>
   <summary>補足: 管理者ではない窓で動かす理由</summary>

   - 管理者の窓から起動したもの（`VBoxManage`・`VirtualBox.exe`）は、管理者の権限で動く。AlmaLinux 10 で VM を root ではなく自分のユーザーで動かすのと同じく、VM は自分のユーザーで動かす
   - VirtualBox のマニュアルは、管理者の権限で動かした VirtualBox と、普通の権限で動くエクスプローラーの間では、ドラッグ＆ドロップができないと書いている
   - VM と設定の場所（`%USERPROFILE%\VirtualBox VMs` と `%USERPROFILE%\.VirtualBox`）はユーザーごと。管理者の窓でも同じユーザーなので、場所は変わらない

   </details>

1. 使い捨ての VM を画面無しで起動し、Hyper-V の上で動くかを見てから止めて消す。

   ```powershell
   $vbm = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
   if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
     Write-Error '管理者の PowerShell に貼っている（この節の手順 5 で開いた窓に貼る）'
   } else {
     & $vbm showvminfo vbox-selftest *> $null
     if ($LASTEXITCODE -eq 0) {
       Write-Error 'vbox-selftest はすでにある。変更せずに中断する'
     } else {
       & $vbm createvm --name vbox-selftest --ostype Other_64 --register
       if ($LASTEXITCODE -eq 0) {
         & $vbm modifyvm vbox-selftest --memory 64 --nic1 none --audio-enabled off
         if ($LASTEXITCODE -eq 0) {
           & $vbm startvm vbox-selftest --type headless
           if ($LASTEXITCODE -eq 0) {
             & $vbm showvminfo vbox-selftest --machinereadable | Select-String -Pattern '^VMState='
             & $vbm showvminfo vbox-selftest --log 0 | Select-String -Pattern 'fall back to NEM|Snail execution mode'
             & $vbm controlvm vbox-selftest poweroff
           }
         }
         & $vbm unregistervm vbox-selftest --delete
       } else {
         Write-Error 'VM を作れなかった。変更・起動・削除は行わない'
       }
     }
   }
   ```

   - VirtualBox が VT-x / AMD-V（か Hyper-V）を使えるかは、ここで初めて分かる
   - `VM "vbox-selftest" has been successfully started.` と `VMState="running"` が出れば動いている（起動するディスクが無いので、中では何も動かない）
   - **`fall back to NEM` か `Snail execution mode` を含む行が出たら、VM は Hyper-V の上で動いている**（遅くなる。[注意点](#注意点)）
   - その行が出なければ、VirtualBox は VT-x / AMD-V を直接使っているはず
   - `poweroff` と `unregistervm` は `0%...100%` の行を出し、VM のファイルごと消える
   - 既に `vbox-selftest` があれば、変更せず中断する。別の名前で試すなら、ブロック中の `vbox-selftest` をすべて同じ名前に変える
   - 作成に失敗したときも、変更・起動・削除には進まない。削除するのは、このブロックで作成できた VM だけ

   <details>
   <summary>補足: Hyper-V の上かの見分け方と、出るエラー</summary>

   AlmaLinux 10 の[手順 16](#実施手順)と同じ VM で、VM のログ（`showvminfo --log 0` は VM の `VBox.log` を出す。マニュアルの 15.44.2.2）から 1 行を探すところだけが違う。

   **Hyper-V の上かの見分け方**

   - NEM は、Hyper-V の API（Windows Hypervisor Platform）で VM を動かす形
   - 利用者の Windows 11 の PC（Hyper-V が動いていた）の VM のログには、`HM: HMR3Init: Attempting fall back to NEM: AMD-V is not available` が出た（[virtualbox-guest-bootc.md の付録](virtualbox-guest-bootc.md#付録-windows-のホストの-virtualbox-の-vm-での本実行2026-09-30)）
   - `Snail execution mode` は、7.2.20 の `VBoxVMM.dll` の中の文字列 `NEM: NEMR3Init: Snail execution mode is active!` から取った
     - 続く行は「この形では VirtualBox は全速で動けない。全速にするには Hyper-V を使う Windows の機能をすべて切る」という注意
   - 窓のある VM では、状態バーのプロセッサーのアイコンに緑の亀が出る（マニュアルの「A green turtle icon indicates that a native hypervisor, such as Hyper-V, is running on the host.」）
   - 利用者の PC では、状態バーの「機能」のアイコンの説明に `実行エンジン: native API` と出た

   **出るエラー**（7.2.20 の `VBoxVMM.dll` の中の文字列から写した。Windows では出していない）

   | 出るもの | 意味 | 対処 |
   |---|---|---|
   | `VT-x is disabled in the BIOS` / `AMD-V is disabled in the BIOS (or by the host OS)` | UEFI の設定で仮想化支援が切れている | UEFI で Intel VT-x / AMD-V（SVM）を有効にする |
   | `WHvCapabilityCodeHypervisorPresent is FALSE! Make sure you have enabled the 'Windows Hypervisor Platform' feature.` | Hyper-V の上で動かそうとしたが、Windows Hypervisor Platform が使えない | マニュアルの 11.30 のとおり、Windows の機能の Windows Hypervisor Platform を有効にする（確かめていない） |

   - VM の置き場所は既定の `%USERPROFILE%\VirtualBox VMs\<VM 名>` で、`unregistervm --delete` がそのフォルダーごと消す

   </details>

1. スタートメニューの「Oracle VirtualBox」で VirtualBox マネージャーを開き、閉じる。

   - デスクトップのショートカットでも、この節の手順 6 の窓で `& "$env:ProgramFiles\Oracle\VirtualBox\VirtualBox.exe"` を打っても同じ
   - VirtualBox マネージャーのウィンドウが開く（この節の手順 6 の VM は消してあるので、一覧は空）
   - 右クリックの「管理者として実行」では開かない
   - **次の手順は、ウィンドウを閉じてから貼る**

1. `%USERPROFILE%\.VirtualBox` に設定ができたか確かめる。

   ```powershell
   Get-ChildItem -LiteralPath "$env:USERPROFILE\.VirtualBox" | Format-Table Name, Length
   ```

   - `VirtualBox.xml`・`VBoxSVC.log` などが並べばよい
   - Windows の VirtualBox は、全体の設定を `%USERPROFILE%\.VirtualBox` に置く（AlmaLinux 10 の `~/.config/VirtualBox` に当たる。マニュアルの 13.1.2「Global Settings」）

---

## Windows 11 の更新

- この節は、[Windows 11 で使う](#windows-11-で使う)の手順 1 と同じ管理者の Windows PowerShell（5.1）に貼る
- 7.2 の中の更新も、系列が変わる更新（7.3 など。まだ出ていない）も、winget の同じ ID（`Oracle.VirtualBox`）で上がる。AlmaLinux 10 と違い、名前に系列が入らない
- VirtualBox マネージャーも、決まった間隔で新しい版を確かめる（環境設定の Update のタブ。マニュアル）。入れ替えは、この節の手順で行う
- **更新の途中でも、ネットワークがいったん切れるはず**（ドライバーを入れ直すため）
- VM の中の Guest Additions は、この節では上がらない（Atomic Desktop の VM は [virtualbox-guest-bootc.md の更新](virtualbox-guest-bootc.md#更新)）

1. VirtualBox の VM と VirtualBox マネージャーをすべて閉じる。

   - VM は、それぞれのウィンドウを閉じるか、VirtualBox マネージャーから止める
   - **次の手順は、すべて閉じてから貼る**

1. VirtualBox が動いていないことと、新しい版があるかを確かめる。

   ```powershell
   Get-Process -Name VirtualBox, VirtualBoxVM, VBoxHeadless, VBoxSVC -ErrorAction SilentlyContinue | Format-Table Id, ProcessName
   winget list --exact --id Oracle.VirtualBox --source winget
   ```

   - プロセスは何も出なければよい
   - `VBoxSVC` だけが出たら、数秒待って貼り直す（VirtualBox マネージャーや VM を閉じた後、しばらく残る。ソースでは、使われなくなってから 5 秒で終わる）
   - `winget list` の版の列の右に、新しい版の列（英語の表示では `Available`）が出たら、新しい版がある
   - 新しい版の列が無ければ、この節の手順 3・4 は飛ばす

1. 新しい版があるときだけ、winget で上げる。

   ```powershell
   winget upgrade --exact --id Oracle.VirtualBox --source winget --accept-source-agreements --accept-package-agreements
   ```

   - 新しい版のインストーラを、今の版の上から動かす（winget の定義の `UpgradeBehavior: install`）。VM と設定は残る
   - 途中でネットワークがいったん切れるはず
   - **次の手順は、winget が終わってプロンプトに戻ってから貼る**（続けて貼ると、winget が何か聞いたときの答えとして食われる）

1. 新しい版にしたときだけ、新しい版になったか確かめる。

   ```powershell
   & "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe" --version
   winget list --exact --id Oracle.VirtualBox --source winget
   ```

   - 新しい版の番号が出て、`winget list` の新しい版の列が消えればよい

---

## Windows 11 のロールバック

- 上から順に、[Windows 11 で使う](#windows-11-で使う)の手順 1 と同じ管理者の Windows PowerShell（5.1）に貼る
- この節の手順では消えないもの:
  - **VM とその設定**（`%USERPROFILE%\VirtualBox VMs` と `%USERPROFILE%\.VirtualBox`）: 消すなら、この節の手順 4
  - **依存で入った Microsoft Visual C++ の再頒布可能パッケージ**: ほかのアプリも使うので消さない
  - **Oracle の証明書**（インストーラが `--silent` のときに「信頼された発行元」に入れたもの）: インストーラと MSI に、消す処理は見当たらない
- **アンインストールの途中でも、ネットワークがいったん切れるはず**（ドライバーを外すため）

> [!CAUTION]
> **この節の手順 4 で、VM とその設定（`%USERPROFILE%\VirtualBox VMs` と `%USERPROFILE%\.VirtualBox`）が消える**。消した VM は取り戻せない。

1. VirtualBox の VM と VirtualBox マネージャーをすべて閉じる。

   - VM は、それぞれのウィンドウを閉じるか、VirtualBox マネージャーから止める
   - **次の手順は、すべて閉じてから貼る**

1. VirtualBox が動いていなければ、winget で消す。

   ```powershell
   if (Get-Process -Name VirtualBox, VirtualBoxVM, VBoxHeadless, VBoxSVC -ErrorAction SilentlyContinue) {
     Write-Error '中断: VirtualBox が動いている（この節の手順 1 で閉じ、数秒待って貼り直す）'
   } else {
     winget uninstall --exact --id Oracle.VirtualBox --source winget
   }
   ```

   - `中断:` で始まるエラーが出たら、何も消していない
   - 途中でネットワークがいったん切れるはず
   - **次の手順は、winget が終わってプロンプトに戻ってから貼る**（続けて貼ると、winget が何か聞いたときの答えとして食われる）

1. 消えたか確かめる。

   ```powershell
   winget list --exact --id Oracle.VirtualBox
   Test-Path -LiteralPath "$env:ProgramFiles\Oracle\VirtualBox"
   Get-CimInstance -ClassName Win32_SystemDriver -Filter "Name LIKE 'VBox%'" | Format-Table Name, State
   Get-NetAdapter -InterfaceDescription 'VirtualBox Host-Only Ethernet Adapter*' -ErrorAction SilentlyContinue
   ```

   - `winget list` は、入っているパッケージが見つからない旨を出す
   - `False` が出て、最後の 2 つは何も出さなければよい
   - ドライバーの行が残ったら、再起動してから貼り直す（確かめていない）

1. VM とその設定も消すときだけ、`%USERPROFILE%\VirtualBox VMs` と `%USERPROFILE%\.VirtualBox` を消す（取り戻せない）。

   ```powershell
   Remove-Item -LiteralPath "$env:USERPROFILE\VirtualBox VMs", "$env:USERPROFILE\.VirtualBox" -Recurse -Force -ErrorAction SilentlyContinue
   Test-Path -LiteralPath "$env:USERPROFILE\VirtualBox VMs", "$env:USERPROFILE\.VirtualBox"
   ```

   - `False` が 2 行出ればよい
   - VM の置き場所を既定から変えていたら（VirtualBox マネージャーの環境設定）、そのフォルダーは別に消す

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 の x86_64 の PC と Windows 11 の PC に [Oracle VirtualBox](https://www.virtualbox.org/) 7.2 を入れ、VM を動かせるようにする
  - AlmaLinux 10 では、Oracle 公式の dnf リポジトリから入れ、カーネルモジュールをこの PC でビルドする
  - **Linux の arm64 版は無い**ので、Raspberry Pi 5 は対象外
- **進め方**: **読者が書き換える値は無い**
  - **AlmaLinux 10**（[実施手順](#実施手順)）: 前提の [EPEL](epel.md) を有効にしたうえで（依存の `liblzf` のため）、鍵を照合して取り込み、repo ファイルを置いて解決を確かめ、ビルドの道具を用意してから `dnf install` する
    - Secure Boot なら、前提の [secure-boot-mok.md](secure-boot-mok.md) で MOK の鍵も先に登録する
    - 最後に KVM の設定を足して再起動する
  - **Windows 11**（[Windows 11 で使う](#windows-11-で使う)）: winget の `Oracle.VirtualBox` を管理者の Windows PowerShell 5.1 で入れる（PC 全体の `C:\Program Files\Oracle\VirtualBox`）。使い捨ての VM は、管理者ではない窓で動かす
    - ドライバーは Microsoft の署名付きで配られるので、MOK の鍵も KVM の設定も要らない
- **状態（AlmaLinux 10）**: **実機で本実行済み（2026-09-28〜29）。ただし Secure Boot が有効な分岐は、MokManager で鍵を登録できず、最後まで通せていない**。その前に x86_64 のコンテナで検証した（2026-09-24）
  - 2026-10-06 の[クリーンインストール VM](almalinux-vm-verification.md)では、手順 1 の `lscpu` に仮想化支援が出なかった。本文の条件に従ってそこで止め、AlmaLinux のゲスト内への VirtualBox の導入・入れ子の VM 起動は行っていない。この試験を導入成功とは扱わない
  - 下表の実機で、**この文書のコードブロックを 1 つずつ中身を確かめてから貼った**（[実機の付録](#付録-実機での本実行2026-09-29)）
    - 手順 1、EPEL の有効化の確認（今の [epel.md](epel.md) の手順 1・3。手順 2 は EPEL が有効なので飛ばした）、手順 2〜8、MOK の手順（今の [secure-boot-mok.md](secure-boot-mok.md) の手順 3〜6。当時はこの文書の手順 11〜14）。同書の手順 3 で Secure Boot が有効だったので、手順 4 で鍵を作って登録を予約し、手順 5 で再起動した
    - secure-boot-mok.md の手順 6 の MokManager でキーボードが効かず、登録できなかった。利用者が UEFI の設定で Secure Boot を無効にした
    - 以降は無効の分岐で、手順 9〜11・13・14・16〜18（secure-boot-mok.md の手順 7 と手順 15 は無効の分岐で飛ばし、手順 12 は USB を使わないので飛ばした）
    - 入れた VirtualBox で、[virtualbox-guest-bootc.md](virtualbox-guest-bootc.md) の VM（Secure Boot 有効）も動かした
  - 確認したこと:
    - `lscpu` の `Virtualization: AMD-V`、鍵の確認が `sudo` の有無で 1 回ずつ要ること、デスクトップの PC での依存（16 パッケージ）
    - `%post` が `vboxdrv.service` を作って有効にし、3 つのモジュールをビルドして読み込むこと（Secure Boot が無効なら署名しない）
    - `enable_virt_at_load=0` を modprobe.d に置いて再起動すると `N` になり、VM が起動すること。置く前は `VERR_SVM_IN_USE` で起動に失敗すること
    - GUI が XWayland 経由で開くこと、SELinux（Enforcing）で AVC の拒否が無いこと
    - MOK の確認（今の secure-boot-mok.md の手順 7）は `sudo` が無いと `Failed to open` になること（`sudo` を付けた形に直した）
  - **確認していないこと**: MokManager での鍵の登録と、署名したモジュールの受け入れ（この PC ではキーボードが効かなかった。VM の中では確かめた）、手順 15、USB（手順 12）、[カーネルを更新したとき](#カーネルを更新したとき)、[更新](#更新)（新しい版が無い）、[ロールバック](#ロールバック)（VirtualBox を残した）、MOK の削除
  - コンテナでの検証（2026-09-24。[付録](#付録-コンテナでの検証記録2026-09-24)）: 手順 1、EPEL の有効化（今の [epel.md](epel.md) の手順 1〜3）、手順 2〜8、MOK の手順（今の [secure-boot-mok.md](secure-boot-mok.md) の手順 3・4・7）、手順 9〜12・14〜18、[カーネルを更新したとき](#カーネルを更新したとき)・[更新](#更新)・[ロールバック](#ロールバック)を、コードブロックのまま通した
    - コンテナのカーネルは別物なので `uname -r` を、Secure Boot の状態は `mokutil` をスタブにした。`--privileged` は付けていない（`modprobe` がホストのカーネルに触れないように）
    - 確かめたのは、依存の解決と導入、スタブの Secure Boot での署名、KVM と共存する仕組みが入らないこと、更新・系列の切り替え・ロールバックの結果
  - 2026-09-28: 手順 4 と、鍵を作るブロック（今の secure-boot-mok.md の手順 4）と、[ロールバック](#ロールバック)の手順 3 のブロックを `{ … }` で囲んだ
    - ブラケットペーストが効かない端末で貼っても、`sudo` の後ろの行が失われないようにするため（[README の記法](../README.md#記法)）
    - 中のコマンドは変えていない。実機では、手順 4 と鍵を作るブロックを囲む前の形で流し、手順 4 は囲んだ形でもう 1 回流した（どちらもブラケットペーストの効く端末で）。ロールバックの手順 2 は流していない
  - 2026-10-02: もとの手順 3・4、手順 9・10、手順 13・14、手順 15・16 をそれぞれつないで `{ … }` で囲んだ（今の手順 3・8・11・12。つないだ形は貼っていない。`bash -n` だけ）
  - 2026-10-05: 手順 16 に、既存の `vbox-selftest` と作成失敗を弾く条件を加えた
    - `bash -n` と VBoxManage のスタブで、既存 VM・作成失敗時に変更や削除をしないこと、変更・起動の失敗時も新規作成分だけを片付けることを確認した。変更後のブロックは実機では流していない
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 2026-10-05: 使い捨て VM のブロックにも既存 VM と作成失敗の条件を加え、Linux の PowerShell 7.6.6 で構文とスタブを確認した。Windows の権限判定はスタブで代え、本物の VM は動かしていない
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - 利用者の Windows 11 の PC には同じ 7.2.20 が入っていて、Hyper-V の上で VM を動かした（[virtualbox-guest-bootc.md の付録](virtualbox-guest-bootc.md#付録-windows-のホストの-virtualbox-の-vm-での本実行2026-09-30)）。入れた方法の記録は無い
  - **確かめたこと**（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）:
    - winget の定義: `Oracle.VirtualBox` 7.2.20 と、依存の `Microsoft.VCRedist.2015+.x64`
    - 配布物: インストーラの sha256（winget の定義と公式の `SHA256SUMS`）と Authenticode の署名。中の MSI の機能・起動の条件・カスタム アクション・環境変数・サービス・画面の文言、ドライバーの INF とカタログの署名、`VBoxVMM.dll` の中の文字列、同梱のマニュアル（PDF）
    - VirtualBox 7.2.20 のソース: インストーラ（`--silent` と証明書）、MSI の補助（Visual C++ と Python の確かめ方）、`VBoxManage --version`、`VBoxSVC` が終わるまでの時間
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。[Windows 11 で使う](#windows-11-で使う)の手順 2・6 と[Windows 11 のロールバック](#windows-11-のロールバック)の手順 2 は、偽物のコマンドで流した（[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
  - **確かめていないこと**: Windows で貼ること（すべての手順）、winget の表示と、依存の入り方、ネットワークが切れる長さ、ドライバーとアダプターの出方、管理者ではない窓での VM の起動、`showvminfo --log` に NEM の行が出ること、VirtualBox マネージャーの表示と更新の知らせ、更新とロールバック、Hyper-V が動いていない PC、Intel の CPU、arm64 の Windows

AlmaLinux 10:

| 項目 | 実機（x86_64 PC） | 検証コンテナ |
|---|---|---|
| 実施日 | 2026-09-28〜29 | 2026-09-24 |
| PC | ASUS ROG Flow Z13（GZ302EA、AMD Strix Halo、BIOS 311） | — |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64 | 同左（`quay.io/almalinuxorg/almalinux:10`、`sha256:83220192…c4c8`） |
| カーネル | `6.12.0-211.56.1.el10_2.x86_64` | クラウドのホスト（6.18 系）のカーネルを共有。`uname -r` だけスタブで `6.12.0-211.56.1.el10_2.x86_64` を返させ、その版の `kernel-core` / `kernel-modules-core` を先に入れた（`kernel-devel` は手順 8 で入る） |
| デスクトップ | GNOME Shell 49.4 / Wayland（ロケールは en_US.UTF-8） | 無し |
| EPEL | 有効（`epel-release-10-8.el10_2`。鍵も取り込み済み） | [epel.md](epel.md) の手順 2 で有効化 |
| CPU の仮想化支援 / KVM | AMD-V。`kvm_amd` が起動時に読み込まれていた（KVM の VM は使っていない） | 無し（`/dev/kvm` が無く、`lscpu` に `Virtualization:` の行が無い） |
| Secure Boot | 有効 → secure-boot-mok.md の手順 6 の後に無効にした | 無し（`mokutil --sb-state` → `EFI variables are not supported on this system`）。分岐は `mokutil` のスタブで確かめた |
| SELinux | Enforcing | 無効（コンテナ） |
| sudo | パスワード無し（NOPASSWD） | NOPASSWD |
| 入った VirtualBox | `VirtualBox-7.2-7.2.20_175154_el10-1.x86_64` | 同左 |

Windows 11（前提にしている環境。[virtualbox-guest-bootc.md](virtualbox-guest-bootc.md) の Windows のホストと同じ PC を想定）:

| 項目 | 値 |
|---|---|
| OS | Windows 11（その PC は Windows 11 Pro 25H2、x64、AMD Ryzen AI MAX+ 395） |
| PowerShell | Windows PowerShell 5.1（入れる・上げる・消すのは管理者の窓、VM は管理者ではない窓） |
| ユーザー | Administrators の一員 |
| VirtualBox | 7.2.20（winget の `Oracle.VirtualBox`。`VirtualBox-7.2.20-175154-Win.exe`） |
| Hyper-V | その PC では動いている（WSL 2）。VM は Hyper-V の上で動いた |

> [!NOTE]
> 出力例の値は `<USER>` / `<GID>` などのプレースホルダで書いてある。バージョン（`7.2.20`）とカーネルの版（`6.12.0-211.56.1.el10_2`）は実行日によって変わる。**鍵の fingerprint とインストーラの sha256 は公開情報なので本文に書いてある。** MOK の秘密鍵と一時パスワードは載せない。
>
> Windows 11 の節にも変数は無い（パスと名前はブロックに直接書いてある）。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)の手順 2 で確かめる（流していないので、記録は無い）。

検証コンテナ（AlmaLinux 10 の素のイメージに、デスクトップの PC に合わせた準備をした後）の状態:

| 項目 | 状態 |
|---|---|
| VirtualBox | 未導入（`rpm -qa 'VirtualBox*'` が空） |
| `/etc/yum.repos.d/virtualbox.repo` / Oracle の鍵 | どちらも無し |
| EPEL | 未設定（baseos / appstream / crb / extras の 4 つ） |
| gcc / make / perl-interpreter / mokutil / openssl / kernel-devel | どれも未導入 |
| `which` / `gnupg2` / `systemd-udev` / `kmod` | 導入済み（GNOME の PC に合わせて先に入れた。[付録](#付録-コンテナでの検証記録2026-09-24)） |
| `vboxusers` グループ | 無し |

実機（2026-09-28、手順 1 の前）の状態:

| 項目 | 状態 |
|---|---|
| VirtualBox | 未導入（`VBoxManage` が無い） |
| `/etc/yum.repos.d/virtualbox.repo` / Oracle の鍵 | どちらも無し |
| EPEL | 有効（`epel-release-10-8.el10_2`） |
| gcc / make / perl-interpreter / mokutil / openssl / kernel-devel | どれも導入済み（`kernel-devel` は動いているカーネルと同じ版） |
| `gpg` | Homebrew の gnupg 2.5.24 が、`/usr/bin/gpg`（2.4.5）より先に見つかる |
| KVM | `kvm_amd` と `kvm` が読み込まれていた（参照 0）。`/etc/modprobe.d` に kvm の設定は無い |
| Secure Boot | 有効。`/var/lib/shim-signed/mok` は無く、MOK には AlmaLinux の鍵 3 つだけ |
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
| KVM（libvirt / virt-manager / GNOME Boxes） | AlmaLinux 標準の仮想化。カーネルに組み込み済みでモジュールのビルドも署名も要らない | 対象外（本書は VirtualBox を入れる）。VirtualBox と同時には動かない（手順 11） |

aarch64 には入らない:

- Oracle のリポジトリの `.../el/10/aarch64/` が 404
- 7.2.20 の配布物にも Linux の arm64 版が無い（arm64 向けは macOS の Apple Silicon 版と、Windows の実験的な対応だけ）
- マニュアルの対応ホストの一覧も、Linux はすべて x86_64 になっている

Windows 11 で VirtualBox を入れる経路を比べた（2026-10-03 時点。中身はどれも公式の `VirtualBox-7.2.20-175154-Win.exe`）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **winget の `Oracle.VirtualBox`** | 7.2.20（2026-09-22）。公式のインストーラを sha256 を確かめて `--silent` で動かし、依存の Visual C++ の再頒布可能パッケージも入れる。`winget upgrade` で上がる | **採用** |
| 公式サイトの exe を手で入れる | 同じインストーラ。画面で機能と置き場所を選べる。更新のたびに手で落とす | 不採用 |
| scoop の `nonportable/virtualbox-np` | 7.2.20（同じ sha256）。管理者の権限で scoop を動かす必要があり、MSI を直接 `/qn` で入れる（ショートカットは作らない） | 不採用（[Windows 11 の初期設定](windows-setup.md)の scoop は管理者ではない窓で使う） |
| Chocolatey の `virtualbox` | 7.2.20（コミュニティの保守） | 不採用（別のパッケージ マネージャーを足す） |

- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](syncthing.md) と同じく後ろの節に分けた
- **Windows 11 でも Extension Pack は入れない**: ライセンスが PUEL（個人利用・教育利用・評価に限って無償。[注意点](#注意点)）
  - winget に Extension Pack のパッケージは無い（winget-pkgs の `manifests/o/Oracle` の下は `VirtualBox` だけ）
  - scoop には、本体と一緒に入れる `nonportable/virtualbox-with-extension-pack-np` がある
- **入れる・上げる・消すのは管理者の窓、VM は管理者ではない窓にした**
  - winget の定義は PC 全体（`Scope: machine`）なので、管理者の窓なら UAC の確認が出ない
  - VM は自分のユーザーで動かす（AlmaLinux 10 で root ではなく自分で動かすのと同じ。[Windows 11 で使う](#windows-11-で使う)の手順 5 の補足）
- **機能は既定のまま、すべて入れた**: ブリッジ接続とホストオンリーのアダプターは、[virtualbox-guest-bootc.md](virtualbox-guest-bootc.md) のホストオンリーアダプターの節などで使う
  - 要らない機能は、マニュアルの `ADDLOCAL`（`-msiparams ADDLOCAL=VBoxApplication,VBoxUSB` など）で外せるが、本書では試していない
- **Hyper-V は止めない**: VirtualBox のマニュアルは、Hyper-V と一緒に使うと遅くなるので、Hyper-V を使う Windows の機能を切るよう勧めている（[注意点](#注意点)）
  - 本書は切らない。WSL 2 が Virtual Machine Platform を使うため（[Windows 11 の初期設定](windows-setup.md)で WSL を入れた PC も）
  - 切ると VM が速くなるかは、試していない

### 完了時点の状態

Windows 11 は流していないので、記録は無い。

**検証コンテナでの出力**（手順 16 の後。ロールバック前。コンテナではモジュールを読み込めないので、`VBoxManage` の前に `WARNING` が出ている）:

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

- `modinfo` をファイルの場所で指定しているのは、コンテナでは `modinfo vboxdrv`（名前で引く形）が別のカーネルの置き場所を見に行って `Module vboxdrv not found.` になるため（[付録](#付録-コンテナでの検証記録2026-09-24)）。実機では手順 15 の書き方でよい
- 3 つのモジュールとも vermagic と版は同じで、signer はどれも `VirtualBox module signing key`、`sig_hashalgo` は `sha512`、`softdep` は空だった

**実機での出力**（2026-09-29、手順 18 の後。Secure Boot は無効で、検証用の VM が 1 つ動いている。`modinfo` から下は手順書の外のコマンド）:

```
$ VBoxManage --version
7.2.20r175154
$ systemctl is-enabled vboxdrv; systemctl is-active vboxdrv
enabled
active
$ lsmod | grep -E '^vbox'
vboxnetadp             32768  0
vboxnetflt             40960  0
vboxdrv               712704  3 vboxnetadp,vboxnetflt
$ ls -l /dev/vboxdrv
crw-------. 1 root root 10, 120 Sep 29 00:31 /dev/vboxdrv
$ cat /sys/module/kvm/parameters/enable_virt_at_load
N
$ modinfo -F signer vboxdrv

$ rpm -qf /usr/lib/systemd/system/vboxdrv.service
file /usr/lib/systemd/system/vboxdrv.service is not owned by any package
$ ls -Z /lib/modules/6.12.0-211.56.1.el10_2.x86_64/misc/
unconfined_u:object_r:modules_object_t:s0 vboxdrv.ko
unconfined_u:object_r:modules_object_t:s0 vboxnetadp.ko
unconfined_u:object_r:modules_object_t:s0 vboxnetflt.ko
$ getent group vboxusers
vboxusers:x:<GID>:
```

- `modinfo -F signer` が空なのは、Secure Boot が無効で `vboxdrv.sh` が署名しなかったため（secure-boot-mok.md 手順 4 の鍵のファイルはある）

### 注意点

- **EPEL が要る**: 依存の `liblzf` が EPEL にしか無い（[手順 6](#実施手順) の補足）。前提の [epel.md](epel.md) で有効にする
- **`Complete!` でもモジュールができていないことがある**: `%post` は失敗を無視する。`systemctl is-active vboxdrv` と `/var/log/vbox-setup.log` で確かめる（[手順 9・10](#実施手順)）
- **sudo を付けない dnf にも鍵の確認が要る**: `repo_gpgcheck=1` のため。確認を通すまで、`sudo` 無しの dnf はどのパッケージでも失敗する（[手順 5](#実施手順) の補足）
- **Secure Boot では `mokutil` と、登録した鍵が要る**: vboxdrv.sh は `mokutil --sb-state` の出力だけで判定する。鍵の場所は `/var/lib/shim-signed/mok/` 固定で、前提の [secure-boot-mok.md](secure-boot-mok.md) で作って登録する
- **MokManager でキーボードが効かない PC がある**: 検証した PC では登録できず、Secure Boot を無効にして進めた（[secure-boot-mok.md 手順 6](secure-boot-mok.md#実施手順) の補足）。無効のままならモジュールは署名されない。後で有効に戻すなら、鍵を登録して `sudo /sbin/vboxconfig` を実行する（[手順 9](#実施手順) の補足）
- **EL10 のカーネルでは KVM と同居できない**: `enable_virt_at_load=0` が要り、それでも KVM の VM と VirtualBox の VM は同時に動かない（[手順 11](#実施手順)）
- **カーネルを更新した後の最初の起動は遅くなる**: `vboxdrv.service` がモジュールをビルドし直す（[カーネルを更新したとき](#カーネルを更新したとき)）
- **系列がパッケージ名に入っている**: 7.2 → 7.3 は `dnf upgrade` では移らない（[更新](#更新)）
- **vboxusers は USB のためだけ**: VM の起動には要らない（[手順 12](#実施手順)）
- **Extension Pack は本書では扱わない**: 追加機能（マニュアルによれば VRDP のサーバー、ホストの Web カメラの受け渡し、Intel の PXE ブート ROM、ディスクイメージの暗号化、クラウド連携）をまとめた別配布
  - ライセンスは GPL ではなく **PUEL（個人利用と教育利用に限って無償）**
  - rpm の `%postun` が `/usr/lib/virtualbox/ExtensionPacks` を消すので、入れた場合は **VirtualBox の更新のたびに入れ直す**ことになる（rpm のスクリプトを読んだ結果。未確認）
- **Guest Additions はゲスト側の話で対象外**: ISO は rpm に同梱されている（`/usr/share/virtualbox/VBoxGuestAdditions.iso`）。ゲストが AlmaLinux の bootc（Atomic Desktop）なら [virtualbox-guest-bootc.md](virtualbox-guest-bootc.md)
- **公式の repo ファイルは `http://`**: 本書の repo ファイルは `https://` にしてある。署名の検証はどちらでも行われる
- **Windows 11 の注意点**
  - **Hyper-V が動いている PC では、VM が Hyper-V の上で動き、遅くなる**（WSL 2 を使う PC など）
    - VirtualBox のマニュアル（11.30）は、Hyper-V が動いていると Hyper-V を仮想化の土台に使い、大きく遅くなることがあると書いている
    - マニュアルのトラブルシューティング（13.7.6.7）は、Hyper-V Platform・Virtual Machine Platform・Windows Hypervisor Platform を切って再起動するよう勧めている（本書は切らない。[選択した方針](#選択した方針)）
    - 利用者の Windows 11 の PC（AMD、Hyper-V が動いている）では、VM の中の重い処理（ネットワークとディスク）の間に、VM が 1〜7 分ずつ止まった。VM のウィンドウでキーを押すと動き出した（[virtualbox-guest-bootc.md の注意点](virtualbox-guest-bootc.md#注意点)）
    - 止まっている間に VM の中の systemd の watchdog が `systemd-logind` などを止め、GNOME がログイン画面に戻った回もあった
    - 同じ PC の VM では、ゲストのカーネルが `vboxguest` を読み込んだ直後に警告を出し、1 度は RCU が止まって起動が進まなかった（同じ注意点）。同じ警告は AlmaLinux 10 のホストの kernel-rt の VM でも出ていて、Hyper-V との関係は分かっていない
    - VM が Hyper-V の上かは、VM のログ（[Windows 11 で使う](#windows-11-で使う)の手順 6）か、VM のウィンドウの状態バー（プロセッサーのアイコンに緑の亀）で分かる
    - Hyper-V が動いていない PC と、Intel の CPU の PC は試していない
  - **入れる・上げる・消すときに、ネットワークがいったん切れる**: ブリッジ接続のドライバーを入れるため（MSI の画面の警告。上げる・消すときも切れるはずだが、確かめていない）。SSH やリモート デスクトップでつないでいる PC では行わない
  - **VirtualBox は管理者ではない窓で動かす**: 管理者の窓から起動すると、VM も管理者の権限で動く（[Windows 11 で使う](#windows-11-で使う)の手順 5 の補足）
  - **`VBoxManage` は `PATH` に入らない**: `C:\Program Files\Oracle\VirtualBox\VBoxManage.exe` を場所ごと呼ぶ（インストーラが足す環境変数は `VBOX_MSI_INSTALL_PATH` だけ）
  - **Secure Boot の MOK は要らない**: ドライバーは Microsoft の署名付きで配られる。[secure-boot-mok.md](secure-boot-mok.md) は Linux だけのもの
  - **ロールバックで残るもの**: 依存で入った Visual C++ の再頒布可能パッケージと、インストーラが「信頼された発行元」に入れた Oracle の証明書（[Windows 11 のロールバック](#windows-11-のロールバック)）

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
- `vboxusers` グループは消えずに残るので、手順 12 をやり直す必要は無い

### 参照

- [VirtualBox — Linux_Downloads](https://www.virtualbox.org/wiki/Linux_Downloads) — ディストリごとの rpm、鍵の fingerprint、`virtualbox.repo`
- [Oracle VirtualBox User Guide 7.2 — Installing on Linux Hosts](https://docs.oracle.com/en/virtualization/virtualbox/7.2/user/installation.html) — 対応ホストの一覧、前提（gcc / make / カーネルのヘッダ）、`vboxusers`、`/etc/default/virtualbox`
- [Oracle VirtualBox User Guide 7.2 — Introduction](https://docs.oracle.com/en/virtualization/virtualbox/7.2/user/Introduction.html) — Extension Pack に入る機能
- [RHEL 10 — Managing, monitoring, and updating the kernel](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html-single/managing_monitoring_and_updating_the_kernel/index) — 「Requirements for authenticating kernel modules with X.509 keys」（モジュールの署名を `.builtin_trusted_keys` と `.platform` で確かめる）、`mokutil --import` と `keyctl list %:.platform`
- [VirtualBox — Changelog 7.2](https://www.virtualbox.org/wiki/Changelog-7.2) / [Changelog 7.1](https://www.virtualbox.org/wiki/Changelog-7.1) — 6.12 の KVM の注意（7.1.4）、6.16 以降の KVM の API（7.2.2）、RHEL 10.x のカーネルへの対応
- [VirtualBox — Downloads](https://www.virtualbox.org/wiki/Downloads) / [PUEL](https://www.virtualbox.org/wiki/VirtualBox_PUEL) — Extension Pack とそのライセンス
- `/usr/lib/virtualbox/vboxdrv.sh` / `/usr/lib/virtualbox/postinst-common.sh` / `/usr/lib/virtualbox/check_module_dependencies.sh` / `/usr/share/virtualbox/src/vboxhost/vboxdrv/linux/SUPDrv-linux.c` — 本書の説明の元にした、rpm が入れるスクリプトとソース
- `man dnf.conf`（`repo_gpgcheck`）/ `man modprobe.d` / `man mokutil`
- [EPEL](epel.md) — 前提の EPEL の有効化（依存の `liblzf`）
- [winget-pkgs の `Oracle.VirtualBox`](https://github.com/microsoft/winget-pkgs/tree/master/manifests/o/Oracle/VirtualBox) — Windows 11 の節で使う winget の定義
- [winget の install — Microsoft Learn](https://learn.microsoft.com/en-us/windows/package-manager/winget/install) — `--accept-source-agreements`・`--accept-package-agreements`、依存を止める `--skip-dependencies`、既定は進み具合を出す
- Oracle VirtualBox User Guide 7.2（インストーラに同梱の `UserManual.pdf`）— 2.2 Installing on Windows Hosts（機能・`ADDLOCAL`・公開プロパティ）、11.30 Using Hyper-V with Oracle VirtualBox、13.1.2 Global Settings（Windows は `$HOME/.VirtualBox`）、13.7.6.7 Poor performance when using Oracle VirtualBox and Hyper-V on the same host、15.44.2.2 Viewing Virtual Machine Log Contents（`showvminfo --log`）、15.52 VBoxManage updatecheck
- [Oracle VirtualBox User Guide 7.2 — Working with Virtual Machines](https://docs.oracle.com/en/virtualization/virtualbox/7.2/user/working-with-vms.html) — 状態バーのプロセッサーのアイコンの緑の亀（Hyper-V などが動いている）
- [VirtualBox/virtualbox の v7.2.20](https://github.com/VirtualBox/virtualbox/tree/v7.2.20) — `src/VBox/Installer/win/Stub/VBoxStub.cpp`（`--silent` と証明書）、`src/VBox/Installer/win/InstallHelper/VBoxInstallHelper.cpp`（Visual C++ 2019 以上の確かめ方、Python のバインディング）、`src/VBox/Frontends/VBoxManage/VBoxManage.cpp`（`--version`）、`src/VBox/Main/src-server/win/svcmain.cpp`（`VBoxSVC` が 5 秒で終わる）
- [Win32_ComputerSystem](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-computersystem)（`HypervisorPresent`）・[Win32_Processor](https://learn.microsoft.com/en-us/windows/win32/cimwin32prov/win32-processor)（`VirtualizationFirmwareEnabled`）— Microsoft Learn
- [virtualbox-guest-bootc.md](virtualbox-guest-bootc.md) — Windows のホストで VirtualBox の VM を動かした記録（Hyper-V の上で止まる現象）

---

### 付録: コンテナでの検証記録（2026-09-24）

**環境**: Ubuntu 24.04 / x86_64 のクラウドホスト上の Docker 29.3.1（cgroup v1）で、`quay.io/almalinuxorg/almalinux:10`（`sha256:8322019282c6f7d253888ec688d6b90675963f31c4692709177e25eb9301c4c8`、AlmaLinux 10.2）を**非特権**・`--network host` で立て、非 root ユーザー（NOPASSWD の sudo）で実行した。実機で加えた変更は無い。**`--privileged` を付けなかったのは、`%post` の `modprobe` などがクラウドのホストのカーネルに触れないようにするため**（コンテナからは `/proc/modules` も見えなかった）。

**手順書の外で行った準備**（検証環境の都合）:

- プロキシの CA を信頼ストアに足し、dnf にプロキシを設定した。プロキシが平文の HTTP を通さないので、AlmaLinux のミラー一覧の URL に `?protocol=https`、EPEL の metalink に `&protocol=https` を足した（EPEL は、EPEL の有効化の確認（今の [epel.md](epel.md) の手順 3）の直後）
- GNOME のデスクトップの PC に合わせて、`which`・`gnupg2`・`systemd-udev`・`kmod`（Workstation / Server with GUI の必須グループ「Standard」などに入っているもの）と、動いているカーネルの `kernel-core` / `kernel-modules-core`（`6.12.0-211.56.1.el10_2`）を先に入れた。`/lib/modules/<版>/build` のリンクは `kernel-modules-core` が持っている

**スタブ**:

| スタブ | 返すもの | 理由 |
|---|---|---|
| `/usr/bin/uname` | `-r` のときだけ `6.12.0-211.56.1.el10_2.x86_64`。ほかの引数は本物に渡す | コンテナはクラウドのホストのカーネル（6.18 系）を共有する。`%post`・vboxdrv.sh・`check_module_dependencies.sh` と手順 8 の `kernel-devel-$(uname -r)` が `uname -r` の版を使う |
| `/usr/bin/mokutil`（手順 8 で本物を入れた後に差し替えた） | `--sb-state` → `SecureBoot enabled`。`--test-key` → 未登録（登録の印のファイルを置いた後は `is already enrolled`）。`--import` / `--list-new` は何もしない | コンテナには UEFI の変数が無い（本物は `EFI variables are not supported on this system`）。Secure Boot の分岐（署名）を通すため |

`modinfo`・`modprobe`・`depmod` はコマンドの `uname` ではなくカーネルに版を聞くので、コンテナではホストの版の置き場所（`/lib/modules/6.18…`。無い）を見に行き、`modinfo vboxdrv` は `Module vboxdrv not found.`、`depmod -a` は `could not open directory` になった。モジュールはファイルの場所を指定して確かめた。

**流し方**: 本文の `bash` のコードブロックを上から順に抜き出し、1 つずつ新しい `docker exec` で実行した（手順 1 の 2 つの変数を各ブロックの先頭に足した。本文の「新しいシェルを開いたら手順 1 を貼り直す」と同じ）。確認を聞くブロック（手順 4・5 の `makecache` 2 つ、手順 9 の `dnf install`、更新、ロールバックの `dnf remove`）は `script` で作った pty の中で流し、間を置いて `y` を送った。コマンドに `-y` は足していない。

| 手順 | 結果 |
|---|---|
| 1. 変数 | 2 つの値、`x86_64`、`CPU の仮想化支援が見えない`（クラウドのホストに VT-x が無い） |
| epel.md 1〜3. EPEL | `EPEL は未設定` → `epel-release-10-6.el10`（extras）と `dnf-plugins-core` → `epel` の行 |
| 2〜3. 鍵 | fingerprint が本文の値と一致。`rpm --import` は無出力で終了コード 0。`gpg-pubkey-2980aecf-5719f4e1` |
| 4〜6. リポジトリ | repo ファイルを作成。`sudo dnf makecache` と `dnf makecache` のどちらも `Importing GPG key 0x2980AECF:` → `y` → `Metadata cache created.`。下見は 89 パッケージ（223 MB / 展開後 719 MB）で、`liblzf` は epel から |
| 7〜8. ビルドの道具 | `uname -r` と `rpm -q --last kernel-core` が同じ版。`gcc` / `make` / `perl-interpreter` / `mokutil` / `openssl` / `kernel-devel-6.12.0-211.56.1.el10_2` を導入。途中で 1 つのミラーが証明書のホスト名の不一致で失敗したが、dnf が別のミラーから取り直した |
| secure-boot-mok.md 3・4・7. MOK（スタブ。当時はこの文書の手順 11〜15） | `SecureBoot enabled` → 鍵の生成（`MOK.priv` が `-rw-------`）→ `--import` はスタブ → **再起動は実行せず**、登録の印を置いて `is already enrolled` |
| 9〜10. 導入 | `[y/N]` と EPEL の鍵（`0xE37ED158`）に `y`。`Creating group 'vboxusers'...` の後、`%post` がモジュールを 3 つビルドして MOK の鍵で署名し、`modprobe vboxdrv failed` と `There were problems setting up VirtualBox.` を出して `Complete!`（コンテナでは読み込めないため）。`systemctl` は `System has not been booted with systemd`、`/dev/vboxdrv` は無し、ログは `Building the main VirtualBox module.` など 3 行 |
| 11. KVM | ファイルの中身と `modprobe -c` の両方に `options kvm enable_virt_at_load=0` |
| 12. vboxusers | `vboxusers:x:<GID>:<USER>` |
| 13. 再起動 | **実行していない**。以降は新しい `docker exec` で行った（新しいログインと同じく、グループが反映される） |
| 14〜16. 検証 | `7.2.20r175154`（前に `WARNING`）、`kvm は未ロード`、`vboxusers`。`modinfo -F signer vboxdrv` は `Module vboxdrv not found.`（上記の理由）。`createvm` と `modifyvm` は成功、`startvm` は `terminated unexpectedly during startup with exit code 1`、`VMState="poweroff"`、`controlvm poweroff` は `is not currently running`、`unregistervm --delete` は `0%...100%` |
| 17〜18. GUI | `No active display server, X11 or Wayland, detected. Exiting.`（30 秒の timeout を付けて実行）。`~/.config/VirtualBox` に `VirtualBox.xml` など 5 つ |
| カーネル更新 | `uname -r` だけ通った。`systemctl` と `modinfo` は上と同じ理由で失敗 |
| 更新 | `Nothing to do.` |
| ロールバック | `Remove  86 Packages`・`Freed space: 712 M`・`/etc/xml/catalog.rpmsave`。repo ファイル・modprobe.d・`vboxusers` が消えた。**このときの版は `dnf clean all` を使っていて、メタデータ用の鍵（`pubring`）が残った**ので、本文の 2 行（`rm -rf .../virtualbox*`）に直した。直した後のロールバックの 3 ブロックは、同じ版の VirtualBox を入れ直した別のコンテナで流し直し、パッケージ・`vboxusers`・鍵を含む dnf のキャッシュ・repo ファイル・modprobe.d のファイル・VM の設定がどれも残らないことを確かめた |

**手順書を流す前に、別のコンテナで確かめたこと**:

| 確認 | 結果 |
|---|---|
| EPEL 無しの下見 | `nothing provides liblzf.so.1()(64bit) needed by VirtualBox-7.2-7.2.20_175154_el10-1.x86_64 from virtualbox` |
| 系列の無い名前 | `sudo dnf install --assumeno VirtualBox` → `No match for argument: VirtualBox` |
| `sudo` 無しの dnf | 鍵を受け入れる前は、無関係な `dnf -q list --showduplicates tmux` まで `Signing key not found` で失敗。受け入れた後は成功。ユーザーのキャッシュは `/var/tmp/dnf-<USER>-<ランダム>/` |
| ビルドの道具が無いとき | `%post` が `This system is currently not set up to build kernel modules.` などを出し、`dnf install` は `Complete!`（手順 8 の補足） |
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

---

### 付録: 実機での本実行（2026-09-29）

前の付録の後、実機で本実行した（手順 1〜8、MOK の手順〔今の [secure-boot-mok.md](secure-boot-mok.md) の手順 3〜6〕、EPEL の有効化の確認〔今の [epel.md](epel.md) の手順 1・3〕は 2026-09-28、MOK の確認〔同書の手順 7〕と手順 9 から後は 2026-09-29）。この付録の手順番号は今の番号で、MOK の手順は secure-boot-mok.md の番号で書いた。前の付録の未確認事項のうち、次のものはこれで済んだ。

- 実機での本実行（Secure Boot が有効な分岐は、MokManager での登録〔今の secure-boot-mok.md の手順 6〕まで）
- VT-x / AMD-V のある PC での `lscpu` の表示、デスクトップの PC での依存の数
- モジュールの読み込みと、`vboxdrv.service` の生成・有効化・起動時の動作
- `enable_virt_at_load=0`（modprobe.d）が起動時に効くこと、VM の起動、KVM とぶつかったときの AMD の文の実際の出方
- GUI の表示（XWayland 経由）、SELinux（Enforcing）の下での動作

**環境**: [対象と検証環境](#対象と検証環境)の表の実機の列のとおり。

**流し方**:

- 本文の `bash` のコードブロックを抜き出し（リストの字下げだけ外す）、自分のログインシェル（擬似端末の上の bash。ブラケットペーストが効く）に 1 つずつ貼って Enter を送った
  - 1 ブロックごとに中身と出力を確かめてから、次を貼った
- 確認を聞くブロック（手順 4・5 の鍵の確認、secure-boot-mok.md 手順 4 の一時パスワード、手順 9 の `[y/N]`）は、入力待ちが出てから答えを送った
  - 手順 4・5 の fingerprint は、手順 2 と同じであることを確かめてから `y` と答えた
- secure-boot-mok.md 手順 5 と手順 13 の再起動では、利用者がログインし直した。同書の手順 6 の MokManager も利用者が操作した
- 手順 1〜8、MOK の手順（同書の手順 3〜6。当時はこの文書の手順 11〜14）と EPEL の確認は 8835dd5 の版（手順 4 と鍵を作るブロックを `{ … }` で囲む前。EPEL の確認は、当時はこの文書の手順 2〜4）、MOK の確認（同書の手順 7）と手順 9 から後は 52299ac の版を貼った。手順 4 は、囲んだ形でもう 1 回流した

| 手順 | 結果 |
|---|---|
| 1. 確認 | `x86_64`、`Virtualization:                          AMD-V` |
| epel.md 1〜3. EPEL | `epel` の行が出たので、手順 2 は飛ばした。`epel-release-10-8.el10_2` と `epel` の行 |
| 2〜3. 鍵 | fingerprint と uid が一致（副鍵の fingerprint の行も出た。手順 3 の補足）。`rpm --import` は無出力。`gpg-pubkey-2980aecf-5719f4e1 Oracle Corporation (VirtualBox archive signing key) <info@virtualbox.org> public key` |
| 4〜5. リポジトリ | `Importing GPG key 0x2980AECF:`（fingerprint は手順 2 と同じ）に `y` → `Metadata cache created.`。`sudo` 無しの dnf も同じ確認に `y`。囲んだ形の手順 4 をもう 1 回流すと、確認は出ずに `Metadata cache created.` |
| 6. 下見 | 16 パッケージ（135 M / 350 M）、`liblzf` は epel。`Operation aborted.` |
| 7〜8. 道具 | 2 つの版が同じ。6 つとも導入済みで `Nothing to do.`。6 つの版と `build/include` |
| secure-boot-mok.md 3. Secure Boot | `SecureBoot enabled` |
| secure-boot-mok.md 4. 鍵 | `MOK.der`（844 バイト）と `MOK.priv`（1704 バイト、`-rw-------`）。一時パスワード 2 回で無出力。`sudo mokutil --list-new` に `CN=VirtualBox module signing key`。登録前の `.platform` は 9 個（UEFI の db と、MOK の AlmaLinux の鍵） |
| secure-boot-mok.md 5〜6. 再起動 | MokManager の画面は出たが、キーボードが効かず登録できなかった（利用者の報告）。利用者が UEFI の設定で Secure Boot を無効にした。起動した後は `SecureBoot disabled`、予約は消え、鍵は登録されていない。`.platform` は UEFI の db の 6 個だけになった |
| secure-boot-mok.md 7. 確認 | Secure Boot が無効なので飛ばした。前の版の形（`sudo` 無し）は `Failed to open /var/lib/shim-signed/mok/MOK.der`、`sudo` 付きは `is not enrolled`（終了コード 1） |
| 9. 導入 | `[y/N]` に `y`（EPEL の鍵の確認は出なかった。取り込み済み）。約 20 秒で `Creating group 'vboxusers'. VM users must be member of that group!` → `Installed:` → `Complete!`。エラーの表示は無し |
| 10. 確認 | `enabled`、`active`、vbox の 3 行、`crw------- root root`、ログは `Building the main VirtualBox module.` など 3 行 |
| 11. KVM | どちらにも `options kvm enable_virt_at_load=0`（`modprobe -c` には `alias symbol:enable_virt_at_load kvm` も）。この時点の値は `Y` |
| 手順 16 を先に 1 回（手順書の外） | `AMD-V is being used by another hypervisor (VERR_SVM_IN_USE).` → `VirtualBox can't enable the AMD-V extension. ...` → `VMState="poweroff"` → `Machine 'vbox-selftest' is not currently running.` → `unregistervm` は `0%...100%` |
| 12. vboxusers | USB を使わないので飛ばした |
| 13. 再起動 | 利用者がログインし直した。`enable_virt_at_load` は `N` |
| 14. 確認 | `7.2.20r175154`（前に `WARNING` 無し）、`active`、vbox の 3 行、`N`、`vboxusers には入っていない` |
| 15. 署名 | Secure Boot が無効なので飛ばした（`modinfo -F signer vboxdrv` は空） |
| 16. VM | `VM "vbox-selftest" has been successfully started.`、`VMState="running"`。`poweroff` と `unregistervm` がそれぞれ `0%...100%` |
| 17. GUI | 利用者がウィンドウの表示を確かめて閉じた。`platforms/libqxcb.so`（XWayland）。端末に `Qt WARNING: QObject::disconnect: ...` が 3 行 |
| 18. 設定 | `compreg.dat`・`selectorwindow.log`・`VBoxSVC.log`（と `.1`・`.2`）・`VirtualBox.xml`・`VirtualBox.xml-prev`・`xpti.dat` |

**手順書の外で確かめたこと**:

| 確認 | 結果 |
|---|---|
| `vboxdrv.service` | `rpm -qf` は `not owned by any package`。`systemctl cat` に `SourcePath=/usr/lib/virtualbox/vboxdrv.sh`・`Type=forking`・`ExecStart=/usr/lib/virtualbox/vboxdrv.sh start`・`ExecStop=/usr/lib/virtualbox/vboxdrv.sh stop`・`TimeoutSec=5min`・`WantedBy=multi-user.target` |
| 署名 | Secure Boot が無効なので、MOK の鍵のファイル（secure-boot-mok.md の手順 4）があっても、3 つとも `signer` が空 |
| SELinux | モジュールは `modules_object_t`、`sudo restorecon -nv` は何も変えない。VirtualBox にかかわる AVC は 0 件（gnome-remote-desktop の無関係な AVC はあった） |
| setuid | `VirtualBoxVM`・`VBoxHeadless` が `-r-s--x--x root root` |
| MOK の予約 | `mokutil --list-new` は、`sudo` が無いと何も出さない |
| `gpg` | `type -a gpg` は `/home/linuxbrew/.linuxbrew/bin/gpg`、`/usr/bin/gpg` の順 |
| VM を動かす | 入れた VirtualBox で、Atomic Desktop の VM（UEFI・Secure Boot 有効、4 vCPU・8 GB）を GUI のウィンドウで動かした（[virtualbox-guest-bootc.md](virtualbox-guest-bootc.md) の付録）。VM の中の MokManager の登録と削除も確かめた |

#### 未確認事項

- Secure Boot が有効なままでの MokManager での登録（この PC ではキーボードが効かなかった）と、署名したモジュールが実機のカーネルに受け入れられること
- 別のキーボードや、UEFI の設定（Fast Boot など）で MokManager のキーが効くか
- Secure Boot を後で有効に戻したときの動作と、登録し直して `sudo /sbin/vboxconfig` を実行したときの動作
- 手順 15、USB の受け渡し（手順 12）
- EPEL の鍵の確認（取り込み済みだった）
- カーネルを更新して再起動したときの自動ビルド、[更新](#更新)、[ロールバック](#ロールバック)（実機では行っていない）
- Intel の PC（VT-x）で KVM とぶつかったときの文の実際の出方
- GUI の HiDPI と日本語の表示、日本語入力

---

### 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、winget の定義と、配布物と、ソースと資料を読んだ記録。

#### winget の定義

winget-pkgs（2026-10-03 の `master`、`c6128933`）の `manifests/o/Oracle/VirtualBox` には 6.1.0〜7.2.20 の定義があり、7.2 系は 7.2.0〜7.2.20 の 11 個（Oracle の EL10 の dnf リポジトリと同じ数）。7.2.20 の `Oracle.VirtualBox.installer.yaml` の要点:

```
PackageVersion: 7.2.20
InstallerType: exe
Scope: machine
InstallModes:
- interactive
- silent
InstallerSwitches:
  Silent: --silent
  SilentWithProgress: --silent
  InstallLocation: --msiparams "INSTALLDIR="<INSTALLPATH>""
  Custom: -msiparams REBOOT=ReallySuppress
InstallerSuccessCodes:
- 3010
UpgradeBehavior: install
Dependencies:
  PackageDependencies:
  - PackageIdentifier: Microsoft.VCRedist.2015+.x64
ReleaseDate: 2026-09-22
AppsAndFeaturesEntries:
- UpgradeCode: '{C4BAD770-BFE8-4D2C-A592-693028A7215B}'
  InstallerType: wix
InstallationMetadata:
  DefaultInstallLocation: '%ProgramFiles%\Oracle\VirtualBox'
Installers:
- Architecture: x64
  InstallerUrl: https://download.virtualbox.org/virtualbox/7.2.20/VirtualBox-7.2.20-175154-Win.exe
  InstallerSha256: A81777D2B36380CE042A29E9C554CF032EB46A793F62E3CC82E7411E535C2C26
```

- ロケールの定義は `License: GPL-3.0-only`。Python は依存に無い
- 依存の `Microsoft.VCRedist.2015+.x64` の最新は 14.51.36247.0（`InstallerType: burn`、`Scope: machine`、`ElevationRequirement: elevatesSelf`。Microsoft の `VC_redist.x64.exe`）
- `manifests/o/Oracle` の下は `InstantClient`・`JDK`・`JavaRuntimeEnvironment`・`MySQL` 系・`OCI-CLI`・`OracleLinux`・`SQLDeveloper`・`SQLcl`・`VirtualBox`・`WebLogicRemoteConsole` で、Extension Pack の定義は無い
- Microsoft Learn の `winget install` の説明: 依存は `--skip-dependencies` を付けない限り処理される。`--silent` を付けなくても既定は進み具合を出す形（スイッチはこの定義ではどちらも `--silent`）

#### インストーラ

`https://download.virtualbox.org/virtualbox/7.2.20/VirtualBox-7.2.20-175154-Win.exe`（178,192,488 バイト）を取った。`LATEST-STABLE.TXT` と `LATEST.TXT` はどちらも `7.2.20`:

```
$ sha256sum VirtualBox-7.2.20-175154-Win.exe
a81777d2b36380ce042a29e9c554cf032eb46a793f62e3cc82e7411e535c2c26  VirtualBox-7.2.20-175154-Win.exe
$ curl -fsSL https://download.virtualbox.org/virtualbox/7.2.20/SHA256SUMS | grep -i win
a81777d2b36380ce042a29e9c554cf032eb46a793f62e3cc82e7411e535c2c26 *VirtualBox-7.2.20-175154-Win.exe
```

Authenticode の署名（`osslsigncode verify`。Windows の `Get-AuthenticodeSignature` は通していない）:

```
Subject: /C=US/ST=California/L=Redwood City/O=Oracle America, Inc./CN=Oracle America, Inc.
Issuer : /C=US/O=DigiCert, Inc./CN=DigiCert Trusted G4 Code Signing RSA4096 SHA384 2021 CA1
Timestamp time: Sep 22 11:02:39 2026 GMT
Signature verification: ok
```

- リソースに、`VirtualBox-7.2.20-r175154-MultiArch_amd64.msi`・`VirtualBox-7.2.20-r175154-MultiArch_arm64.msi`・`common.cab`（マニュアル・Guest Additions の ISO・翻訳・Python のバインディングの材料）が入っていた
- 版の情報は `FileDescription: VirtualBox Installer`、`ProductVersion: 7.2.20.175154`

#### 中の MSI（amd64）

`msiinfo`（msitools）で表を読んだ。WiX Toolset 4.0.5 で作られている。

- 機能（`Feature`）: `VBoxApplication`（本体）・`VBoxUSB`・`VBoxNetwork`（その下に `VBoxNetworkFlt`〔NDIS6 Bridged Networking〕と `VBoxNetworkAdp`〔NDIS6 Host-Only Networking〕）・`VBoxPython`。どれも `Level` は 1（既定で入る）
- 起動の条件（`LaunchCondition`）: 64 ビットの Windows、管理者の権限（「You need to have administrator rights to (un)install [ProductName]!」）、Visual C++ の再頒布可能パッケージ（「[ProductName] needs the Microsoft Visual C++ 2019 Redistributable Package being installed first.」）、新しい版が入っていないこと
- プロパティ: `ALLUSERS=1`、`VBOX_INSTALLDESKTOPSHORTCUT=1`、`VBOX_INSTALLSTARTMENUENTRIES=1`、`VBOX_REGISTERFILEEXTENSIONS=1`、`VBOX_START=1`、`NETWORKTYPE=NDIS6`
  - `VBOX_START` を使う `ca_StartVBox`（`[INSTALLDIR]VirtualBox.exe` を起動する）は、最後の画面（`VBoxExitDlg`）の `Finish` のボタンからだけ呼ばれる
- 環境変数（`Environment`）: `VBOX_MSI_INSTALL_PATH`（PC 全体、インストール先）だけ。`PATH` は変えない
- サービス（`ServiceInstall`）: `VBoxSDS`（`VirtualBox system service`、手動で起動）
- ショートカット: スタートメニューの「Oracle VirtualBox」・「User manual (PDF, English)」・「License (English)」と、デスクトップの「Oracle VirtualBox」
- 画面の文言:
  - `VBoxWarnDisconNetIfacesDlg`: 「During the installation of [ProductName] Networking, your network will be disconnected. Ensure any operations requiring network connection are complete before continuing.」
  - `VBoxWarnPythonDlg`: 「Installing the [ProductName] Python bindings requires the Python Core package and the win32api bindings to be installed.」
- `InstallExecuteSequence` に `ScheduleReboot` と `ForceReboot` は無い。ドライバーを入れるカスタム アクション（`ca_VBoxSupDrvInst`・`ca_InstallNetLwf`・`ca_CreateHostOnlyInterfaceNetAdp`・`ca_VBoxUSBMonDrvInst` など）と、Python のバインディングを入れる `ca_InstallPythonAPI` がある

ドライバー（MSI の中のファイル）:

| INF | `AddService` の名前 | 説明 |
|---|---|---|
| `VBoxSup.inf` | `VBoxSup` | VM を動かす支援のドライバー |
| `VBoxNetLwf.inf` | `VBoxNetLwf` | `VirtualBox NDIS6 Bridged Networking Driver` |
| `VBoxNetAdp6.inf` | `VBoxNetAdp` | `VirtualBox Host-Only Ethernet Adapter` |
| `VBoxUSBMon.inf` / `VBoxUSB.inf` | `VBoxUSBMon` / `VBoxUSB` | USB |

- カタログ（`VBoxSup.cat`・`VBoxNetLwf_W10.cat`・`VBoxNetAdp6_W10.cat`・`VBoxUSB_W10.cat` など）の署名者は `CN = Microsoft Windows Hardware Compatibility Publisher`（`Microsoft Windows Third Party Component CA 2014` の下）。`.sys` の埋め込みの署名は Oracle America, Inc.

`VBoxVMM.dll` の中の文字列（NEM と仮想化支援にかかわるもの）:

```
HM: HMR3Init: Attempting fall back to NEM: %s
HM: HMR3Init: Attempting fall back to NEM: The host kernel does not support VT-x - %s
NEM: NEMR3Init: Snail execution mode is active!
NEM: Note! VirtualBox is not able to run at its full potential in this execution mode.
NEM:       To see VirtualBox run at max speed you need to disable all Windows features
NEM:       making use of Hyper-V.  That is a moving target, so google how and carefully
NEM:       consider the consequences of disabling these features.
WHvCapabilityCodeHypervisorPresent is FALSE! Make sure you have enabled the 'Windows Hypervisor Platform' feature.
VT-x is disabled in the BIOS
AMD-V is disabled in the BIOS (or by the host OS)
```

#### 同梱のマニュアル（`UserManual.pdf`、User Guide for Release 7.2）

- 2.2 Installing on Windows Hosts: 機能（USB support・Networking・Python support〔動いている Windows の Python が要る。Python 3〕）、既定では全ユーザーに入ること、`ADDLOCAL` の機能の名前、公開プロパティ（`VBOX_INSTALLDESKTOPSHORTCUT` など）。アンインストールはコントロール パネルのプログラムの一覧から
- 5 章の状態バーのプロセッサーのアイコン: 「A green turtle icon indicates that a native hypervisor, such as Hyper-V, is running on the host.」
- 11.30 Using Hyper-V with Oracle VirtualBox: 「Oracle VirtualBox can be used on a Windows host where Hyper-V is running but host systems might experience significant Oracle VirtualBox performance degradation.」「Note: In Windows, Windows Hypervisor Platform must be enabled in addition to Hyper-V.」
- 13.1.2 Global Settings: Windows の全体の設定は `$HOME/.VirtualBox`。VM の既定の置き場所は `$HOME/VirtualBox VMs`
- 13.7.6.7 Poor performance when using Oracle VirtualBox and Hyper-V on the same host: 「Always disable Hyper-V when running VirtualBox.」、対処は「Turn off the Windows features Hyper-V Platform, Virtual Machine Platform and Windows Hypervisor Platform, and then reboot the host.」
- 15.44.2.2: `VBoxManage showvminfo <VM> --log <番号>` は VM のログを出す（0 が `VBox.log`）
- 15.52: `VBoxManage updatecheck perform` / `list` / `modify`（新しい版の確かめ）

#### ソース（GitHub の `VirtualBox/virtualbox` の `v7.2.20`）

- `src/VBox/Installer/win/Stub/VBoxStub.cpp`:
  - `--silent` で MSI の画面を出さない（`MsiSetInternalUI(INSTALLUILEVEL_NONE)`）
  - `--silent` のときは、`--no-silent-cert` が無ければ、`InstallCertificates` が Oracle の証明書を `CERT_SYSTEM_STORE_LOCAL_MACHINE` の `TrustedPublisher` に入れる（コメントは「so the installer won't prompt the user during silent installs」）
  - `-msiparams` は `--msiparams` と同じ。`--ignore-reboot` を付けなければ、再起動が要るときの終了コードは 3010
- `src/VBox/Installer/win/InstallHelper/VBoxInstallHelper.cpp`: `IsMSCRTInstalled` は、14.0 の再頒布可能パッケージの版が 14.20 以上（2019 以上）なら `VBOX_MSCRT_INSTALLED` を立てる。`InstallPythonAPI` は、Python が無いときも失敗したときも `ERROR_SUCCESS` を返す（「Do not fail here.」）
- `src/VBox/Frontends/VBoxManage/VBoxManage.cpp`: `--version` は `com::Initialize()` より前に版を出して終わる
- `src/VBox/Main/src-server/win/svcmain.cpp`: `VBoxSVC` は、使われなくなってから `dwNormalTimeout = 5000`（5 秒）で終わる
- `src/VBox/Main/src-global/win/VirtualBoxSDSImpl.cpp`: `VBoxSDS` は、ユーザーの SID ごとに 1 つの `VBoxSVC` を選ぶ

#### ほかの経路の定義（採らなかったもの）

- scoop の `ScoopInstaller/Nonportable` の `virtualbox-np.json`: 7.2.20、同じ exe（sha256 も同じ）。`pre_install` で管理者でなければ止め、`-extract` した MSI を `msiexec /i … /qn /norestart VBOX_START=0 VBOX_INSTALLDESKTOPSHORTCUT=0 VBOX_INSTALLQUICKLAUNCHSHORTCUT=0 VBOX_INSTALLSTARTMENUENTRIES=0` で入れる。依存は `extras/vcredist2022`
- 同じバケットの `virtualbox-with-extension-pack-np.json`: 同じ 7.2.20 に、`Oracle_VirtualBox_Extension_Pack-7.2.20.vbox-extpack` を足したもの（`notes` に、Extension Pack は個人・教育・評価の利用に限って無償とある）
- Chocolatey の `virtualbox`: 7.2.20（community.chocolatey.org の API で最新の版だけを見た）

---

### 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-03）

Linux（クラウドのコンテナ）の PowerShell 7.6.6 と PSScriptAnalyzer 1.25.0 で確かめた。

**構文と Windows PowerShell 5.1 との互換**:

- Windows 11 の 3 節の `powershell` のブロック 11 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。指摘は 0
  - このプロファイルが `Get-NetAdapter` と `Get-WindowsOptionalFeature` を知っていることは、わざと無い引数（`Get-NetAdapter -NoSuchParam`）を渡したファイルで指摘が出ることで確かめた

**条件で止まるブロックの模擬**（パスの `\` を `/` に替え、`$env:ProgramFiles` を一時的なディレクトリにして流した。管理者かどうかの式は `$true` / `$false` に置き換え、`Get-CimInstance`・`Get-WindowsOptionalFeature`・`Get-Process`・`winget` は値を返すだけの偽物の関数、`VBoxManage.exe` は引数を記録して決まった文字列を返す bash のスクリプトにした）:

- [Windows 11 で使う](#windows-11-で使う)の手順 2: `Admin`・`Arch`・`Winget`・`VirtualBox`・`Hypervisor`・`VirtFirmware` の 6 行と、偽物の 5 つの機能から 3 つ（`Microsoft-Hyper-V-All`・`VirtualMachinePlatform`・`HypervisorPlatform`）だけの表が出た
- [Windows 11 で使う](#windows-11-で使う)の手順 6:
  - 管理者でないとき: `VBoxManage` に `createvm` → `modifyvm` → `startvm` → `showvminfo --machinereadable` → `showvminfo --log 0` → `controlvm … poweroff` → `unregistervm … --delete` の 7 回が、本文の引数のまま渡った
  - `showvminfo --machinereadable` の出力からは `VMState="running"` の行だけが残った
  - 偽物のログに NEM の 2 行（`HM: HMR3Init: Attempting fall back to NEM: AMD-V is not available` と `NEM: NEMR3Init: Snail execution mode is active!`）を入れたときはその 2 行が出て、入れないときは何も出なかった
  - 管理者のとき: `管理者の PowerShell に貼っている（この節の手順 5 で開いた窓に貼る）` で止まり、`VBoxManage` は 1 度も呼ばれなかった
- [Windows 11 のロールバック](#windows-11-のロールバック)の手順 2: 偽物の `Get-Process` が何も返さないときは `winget uninstall --exact --id Oracle.VirtualBox --source winget` が呼ばれ、`VBoxSVC` を返すときは `中断: VirtualBox が動いている（…）` で止まって `winget` は呼ばれなかった

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと（winget の表示、依存の Visual C++ の入り方、ネットワークが切れる長さ）
1. ドライバー（`Win32_SystemDriver`）とホストオンリーのアダプターの一覧の出方、アダプターの接続がパブリックとプライベートのどちらになるか
1. 管理者ではない窓での使い捨ての VM の起動と、Hyper-V の上のときに `showvminfo --log 0` に NEM の行が出ること
1. VirtualBox マネージャーの表示と、新しい版の知らせ
1. `winget upgrade` と `winget uninstall`（ネットワークが切れるか、ドライバーとアダプターが消えるか、Oracle の証明書が残るか）
1. Hyper-V が動いていない PC（VirtualBox が VT-x / AMD-V を直接使う形）、Intel の CPU、arm64 の Windows

---

### 付録: 現行版を新規 VM で再検証（2026-10-06）

**対象**: `setup-notes` の `5da3478` 版。公式 ISO で Workstation を入れた `clean-install` スナップショットから、新規の `alma10-current-20261006-containers` を作った。AlmaLinux 10.2 / x86_64 / SELinux Enforcing / firewalld 有効。共通 bash は `3d5323e` を新規導入した。以前の付録と別の試験で、実行対象の現行ブロックを SSH の擬似端末で順に実行した。

実施手順 1 は `x86_64` / `CPU の仮想化支援が見えない`。外側が Hyper-V NEM のホストで、ゲストへ SVM / VT-x が提供されていない。本文の前提を満たさないため、この VM での VirtualBox 導入・入れ子の VM 起動は実施していない。手順の失敗とハードウェアの不足を分けた記録で、以前の実機検証を置き換えない。
