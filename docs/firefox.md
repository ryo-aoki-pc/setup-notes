# Firefox 最新版インストール手順（AlmaLinux 10 / Mozilla 公式 RPM リポジトリ）

## 実施手順

> [!IMPORTANT]
> - **すべて対象ホスト上で実行する**。手順 7 と手順 14 の GUI の確認だけ、デスクトップセッションで行う
> - **手順 6・11・12・13 には対話入力がある**（トランザクション表の `[y/N]`。手順 12 は EPEL の鍵の確認も）。答えてから次の手順を貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- Firefox を入れ済みのホストに AAC・H.264 の再生だけ足すなら、手順 8 から貼る（手順 8 以降は変数を使わない）
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 以後は[更新](#更新)・[ロールバック](#ロールバック)

1. 変数を設定する。

   ```bash
   FF_PKG=firefox                  # 入れるチャンネル。firefox（最新版）/ firefox-esr / firefox-beta。<FF_PKG>
   FF_L10N=firefox-l10n-ja         # 日本語 UI の言語パック。要らなければ空にする。<FF_L10N>
   for v in FF_PKG FF_L10N; do printf '%-9s = %s\n' "$v" "${!v}"; done
   ```

   - **編集が必須の変数は無い**。最新版（Rapid Release）を入れるなら既定のままでよい
   - ESR や Beta にしたいときだけ `FF_PKG` を変える
   - 最後の行で値を読み戻す
   - `FF_PKG` が空なら、ここで止めて直す
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

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

   `firefox-esr` は **Mozilla の ESR（153 系）** で、AppStream の ESR 140 とは別物。並べて入れることもできる（`/usr/lib/firefox-esr`）が、本書では扱わない。

   `FF_L10N` は `firefox-l10n-<言語コード>` の形で `noarch`。本体とバージョンが揃っていないと UI に反映されないので、常に本体と一緒に入れ替える。

   </details>

1. 署名鍵を落として、取り込む前に fingerprint と uid を確かめる。

   ```bash
   curl -fsSL https://packages.mozilla.org/rpm/firefox/signing-key.gpg | gpg --show-keys
   ```

   - `pub` 行の fingerprint が `14F26682D0916CDD81E37B6D61B7B526D98F0353`
   - uid が `Mozilla Software Releases <release@mozilla.com>`
   - 違っていればここで止める
   - **次の手順は、この 2 つを目で確かめてから貼る**

1. 一致したら、鍵を rpm に取り込む。

   ```bash
   sudo rpm --import https://packages.mozilla.org/rpm/firefox/signing-key.gpg
   ```

   - `rpm --import` は期限切れの副鍵についての warning を出すが、署名に使う副鍵は別にあるので問題ない（この手順の補足）
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

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

1. 鍵が入ったか確かめる。

   ```bash
   rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i mozilla
   ```

   - `gpg-pubkey-d98f0353-55a94004 Mozilla Software Releases ...` の 1 行が出る

1. Mozilla のリポジトリを追加し、入手できる版を見る。

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

   - 一覧の下のほうに、`mozilla` リポジトリ提供の版が出る
   - このリポジトリは `baseurl` にアーキテクチャを含まないので、`x86_64` の行も一緒に並ぶ（この手順の補足）

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

   将来 AppStream 側の ESR が Mozilla 側の版を追い越す状況（Mozilla 側でリリースが巻き戻る、ESR が別番号体系になる、など）に備えた保険として残している。

   `repo_gpgcheck=0` は Mozilla の案内どおりで、**パッケージの署名は検証する（`gpgcheck=1`）がリポジトリメタデータには署名が無い**、という意味。

   このリポジトリは `baseurl` に `$basearch` を含まない**全アーキテクチャ共通**の作りなので、`dnf list` には `firefox.x86_64` の行も出る。インストールされるのは実行中のアーキテクチャのものだけ。

   </details>

1. Firefox を入れる。

   ```bash
   sudo dnf install "${FF_PKG:?手順 1 の FF_PKG が空のまま。値を入れて貼り直す}" ${FF_L10N}
   ```

   - AppStream の Firefox（ESR）が既に入っているホストでは、この 1 コマンドが `Upgrading: firefox` として解決される（この手順の補足）
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 言語パックのクォートと、ESR からの載せ替え</summary>

   `FF_L10N` を空にした場合にクォートで空文字列を渡さないよう、言語パックだけクォートしていない。

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

1. Mozilla 公式のビルドが入ったか確かめる。

   ```bash
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' "${FF_PKG}" ${FF_L10N}
   firefox --version
   rpm -qi "${FF_PKG}" | sed -n '/^Vendor/p;/^Build Date/p'
   ```

   - `from_repo` が `mozilla`、`Vendor` が `Mozilla` なら、Mozilla 公式のビルドが入っている
   - GUI はデスクトップセッションから起動し、`about:support` で次を確認する（日本語 UI の表記）
     - 「更新チャンネル」が `release`（ESR なら `esr`）
     - 「プログラムの実行ファイル」が `/usr/lib/firefox/firefox-bin`（AppStream 版の `/usr/lib64` ではない）
   - 日本語パックを入れた場合は、`about:preferences` の言語で日本語を選べる

1. RPM Fusion（free）の署名鍵を落として、取り込む前に fingerprint と uid を確かめる。

   ```bash
   curl -fsSL 'https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-el-10' | gpg --show-keys
   ```

   - `pub` 行の fingerprint が `5FC4AE73FC2B08B9DFE7EB990C8489D8DB85DDD7`
   - uid が `RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org>`
   - 違っていればここで止める
   - **次の手順は、この 2 つを目で確かめてから貼る**

   <details>
   <summary>補足: 手順 8〜14 で足すものと、鍵の出所</summary>

   手順 8〜14 では、Firefox が自前で復号できない AAC と H.264 のために、RPM Fusion（free）の FFmpeg のライブラリを入れる。理由と、EPEL の `libavcodec-free` を採らなかった経緯は[選択した方針](#選択した方針)にある。

   鍵は RPM Fusion の [keys](https://rpmfusion.org/keys) ページの添付ファイル。同じページの「RPM Fusion free for EL 10」の fingerprint（`5FC4 AE73 FC2B 08B9 DFE7 EB99 0C84 89D8 DB85 DDD7`）と一致した:

   ```
   pub   rsa4096 2025-02-07 [SC]
         5FC4AE73FC2B08B9DFE7EB990C8489D8DB85DDD7
   uid                      RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org>
   ```

   `gpg` は `gnupg2` のコマンド。素のコンテナには入っていなかったので、検証では先に入れた。

   </details>

1. 一致したら、鍵を rpm に取り込む。

   ```bash
   sudo rpm --import 'https://rpmfusion.org/keys?action=AttachFile&do=get&target=RPM-GPG-KEY-rpmfusion-free-el-10'
   ```

   - 何も表示されずに終われば、取り込めている
   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. 鍵が入ったか確かめる。

   ```bash
   rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i fusion
   ```

   - `gpg-pubkey-db85ddd7-67a63d8b RPM Fusion free repository for EL (10) ...` の 1 行が出る

1. RPM Fusion（free）のリポジトリを入れる。

   ```bash
   sudo dnf --setopt=localpkg_gpgcheck=1 install https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-10.noarch.rpm
   ```

   - `--setopt=localpkg_gpgcheck=1` を外さない（外すと、手順 9 の鍵で署名を確かめずに入る。この手順の補足）
   - EPEL がまだ無ければ、依存として `epel-release` も入る（EPEL が有効になる）
   - SELinux のポリシー（`selinux-policy`）が入っているホストでは、弱い依存として CRB の `selinux-policy-extra` と `selinux-policy-targeted-extra` も入る
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 署名の確認と、一緒に入る EPEL</summary>

   **署名の確認**: dnf 4.20 の既定は `localpkg_gpgcheck = 0` で、URL やファイルで渡したパッケージの署名を確かめない。`--setopt=localpkg_gpgcheck=1` を付けると確かめる。手順 9 の鍵が無いコンテナでは、次のように止まって何も入らなかった:

   ```
   Public key for rpmfusion-free-release-10.noarch.rpm is not installed
   The downloaded packages were saved in cache until the next successful transaction.
   You can remove cached packages by executing 'dnf clean packages'.
   Error: GPG check FAILED
   ```

   RPM Fusion の [Configuration](https://rpmfusion.org/Configuration) は EL 向けに `--nogpgcheck` で入れる例を載せている。一方 [keys](https://rpmfusion.org/keys) の「Verify GPG signatures on install」は、鍵を先に取り込んで `localpkg_gpgcheck=1` で入れる方法を案内しており、本書は後者にした。`mirrors.rpmfusion.org` はミラーへリダイレクトする（この環境では `mirrors.ustc.edu.cn`）ので、署名で確かめる意味がある。

   **一緒に入る EPEL**: `rpmfusion-free-release` は `epel-release >= 10` を要求するので、EPEL が無ければ extras から一緒に入る。[btop.md 手順 1〜3](btop.md#実施手順) の EPEL の有効化は要らない。素のコンテナでの実測:

   ```
   Installing:
    rpmfusion-free-release     noarch     10-1              @commandline      10 k
   Installing dependencies:
    epel-release               noarch     10-6.el10         extras            18 k
   Installing weak dependencies:
    dnf-plugins-core           noarch     4.7.0-10.el10     baseos            37 k
   ```

   実機（GNOME のデスクトップ、SELinux は Enforcing）では 4 パッケージになった（`dnf history`）。`dnf-plugins-core` は元から入っていた。代わりに、`epel-release` の弱い依存 `(selinux-policy-epel if selinux-policy)` を満たす `selinux-policy-extra` と、それが要る `selinux-policy-targeted-extra` が CRB から入った。素のコンテナには `selinux-policy` が無いので、この 2 つは入らない:

   ```
   Packages Altered:
       Install selinux-policy-extra-42.1.18-4.el10_2.3.noarch          @crb
       Install selinux-policy-targeted-extra-42.1.18-4.el10_2.3.noarch @crb
       Install epel-release-10-6.el10.noarch                           @extras
       Install rpmfusion-free-release-10-1.noarch                      @@commandline
   ```

   `epel-release` の scriptlet は「CRB を有効に」と表示する。AlmaLinux 10 では CRB が既定で有効（[導入元一覧](tool-catalog.md#導入経路と-el10-での注意)）なので、`crb enable` は要らない。手順 12 の依存には、CRB のものは無かった。

   </details>

1. 入手できる版を見てから、FFmpeg のライブラリを入れる。

   ```bash
   dnf -q list --showduplicates ffmpeg-libs
   sudo dnf install ffmpeg-libs
   ```

   - 版は `ffmpeg-libs.aarch64  7.1.5-1.el10  rpmfusion-free-updates` のように出る
   - 依存として、RPM Fusion の `x264-libs`・`x265-libs` などと、EPEL のライブラリが入る
   - **EPEL の署名鍵をまだ取り込んでいなければ、ここで 1 回だけ確認を求められる**
   - fingerprint が `7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158`（Fedora (epel10) &lt;epel@fedoraproject.org&gt;）であることを目で確かめてから `y` と答える。違っていれば `N` で中断する
   - `conflicts with libswresample-free` と出て止まったら、手順 13 で入れ直す。入ったときは手順 13 は飛ばす
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: 入るものと、鍵の確認の実測</summary>

   Firefox だけを入れたコンテナでは 79 パッケージが入った（ダウンロード 42 MB、展開後 137 MB）。内訳は EPEL 44・BaseOS 17・AppStream 14・RPM Fusion 4（`ffmpeg-libs`・`x264-libs`・`x265-libs`・`vvenc-libs`）で、CRB からは無い。実機（GNOME のデスクトップ）では、既に入っているものが多く 60 パッケージだった（EPEL 44・AppStream 10・RPM Fusion 4・BaseOS 2）。

   Firefox のプロセスが読み込むのは `/usr/lib64/libavcodec.so.61.19.101`（FFmpeg 7.1）だった（コンテナで `/proc/<pid>/maps` を見た）。コマンドの `ffmpeg` は入らない（要るなら `sudo dnf install ffmpeg`）。

   EPEL の鍵の確認の実測（手順 11 で EPEL が入ったコンテナ）。RPM Fusion の鍵は手順 9 で取り込んであるので聞かれない:

   ```
   Importing GPG key 0xE37ED158:
    Userid     : "Fedora (epel10) <epel@fedoraproject.org>"
    Fingerprint: 7D8D 15CB FC4E 6268 8591 FB26 33D9 8517 E37E D158
    From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-10
   ```

   </details>

1. 手順 12 が `libavcodec-free` との衝突で止まったときだけ、それを外して入れ直す。

   ```bash
   sudo dnf install --allowerasing ffmpeg-libs
   ```

   - トランザクション表の `Removing dependent packages:` に、`libavcodec-free`・`libavutil-free`・`libswresample-free` の 3 つが出る
   - この 3 つのほかにも `Removing` に出たら、`N` で止める
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: EPEL の libavcodec-free を外す理由</summary>

   EPEL の `libavcodec-free`（EPEL の `ffmpeg-free` のライブラリ）は、EPEL の Chromium や `gstreamer1-plugin-libav` など、`libavcodec.so.61` を使うパッケージの依存で入っていることがある。`ffmpeg-libs` とは同居できず、手順 12 は次のように止まる（`libavcodec-free` を入れたコンテナでの実測）:

   ```
   Error:
    Problem: problem with installed package libswresample-free-7.1.2-1.el10_2.aarch64
     - package ffmpeg-libs-7.1.5-1.el10.aarch64 from rpmfusion-free-updates conflicts with libswresample-free provided by libswresample-free-7.1.2-1.el10_2.aarch64 from @System
     - package ffmpeg-libs-7.1.5-1.el10.aarch64 from rpmfusion-free-updates conflicts with libswresample-free provided by libswresample-free-7.1.2-1.el10_2.aarch64 from epel
     - conflicting requests
   ```

   `--allowerasing` を付けると、`Removing dependent packages:` に 3 つが並んで入れ替わった。`ffmpeg-libs` は同じ共有ライブラリ（`libavcodec.so.61` など）と `libavcodec-freeworld` を提供する。入れ替えた後、Firefox は H.264 と AAC を再生できた。

   `libavcodec-free` を残したままでは、H.264 の動画が再生できない（[選択した方針](#選択した方針)）。コマンドの `ffmpeg-free` も入っているときは、RPM Fusion の [Howto/Multimedia](https://rpmfusion.org/Howto/Multimedia) が案内する `sudo dnf swap ffmpeg-free ffmpeg --allowerasing` になる（本書では試していない）。

   </details>

1. FFmpeg のライブラリが入ったか確かめ、Firefox を起動し直して再生を確かめる。

   ```bash
   dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' ffmpeg-libs rpmfusion-free-release epel-release
   ls /usr/lib64/libavcodec.so.*
   ```

   - `ffmpeg-libs 7.1.5-1.el10 rpmfusion-free-updates` の行と、`rpmfusion-free-release`・`epel-release` の行が出る
   - `/usr/lib64/libavcodec.so.61` がある
   - **起動中の Firefox は FFmpeg を読み直さないので、開いていたら全部閉じてから起動し直す**
   - `about:support` の「コーデックサポート情報」で、`H264` と `AAC` の「ソフトウェアデコーディング」が「対応」になる
   - 再生できなかった動画が再生できる

   <details>
   <summary>補足: 起動し直す理由と、about:support の表</summary>

   FFmpeg を入れる前から起動していた Firefox では、入れた後も about:support の `H264` と `AAC` は「未対応」のままで、AAC の復号も失敗した。起動し直すと「対応」になった（コンテナでの実測）。

   「コーデックサポート情報」の「ソフトウェアデコーディング」の列（「ハードウェアデコーディング」は、どちらもすべて「未対応」）:

   | コーデック名 | 入れる前 | 入れた後 |
   |---|---|---|
   | H264 | 未対応 | 対応 |
   | VP9 | 対応 | 対応 |
   | AV1 | 対応 | 対応 |
   | HEVC | 未対応 | 対応 |
   | AAC | 未対応 | 対応 |
   | Opus | 対応 | 対応 |

   この表の `H264` は FFmpeg の側だけを示す。Firefox が起動後に自動で落とす Cisco の OpenH264（プロファイルの `gmp-gmpopenh264`）で H.264 を再生できているときも、FFmpeg が無ければ「未対応」と出る。

   </details>

---

## 更新

- 通常の `dnf upgrade` に含まれる
- 手順 12 の `ffmpeg-libs`（RPM Fusion）も、`dnf upgrade` で一緒に上がる

1. Firefox だけ上げるときは、言語パックと一緒に上げる。

   ```bash
   sudo dnf upgrade "${FF_PKG}" ${FF_L10N}
   ```

   - Firefox 内蔵の自動更新機能は RPM 版では無効で（`/usr/lib/firefox` に一般ユーザーの書き込み権が無い）、更新は dnf 側で行う
   - 本体だけ上げて言語パックを取り残すと UI が英語に戻るので、両方まとめて上げる

---

## ロールバック

> [!WARNING]
> **ダウングレードした Firefox は、新しいプロファイルを読めないことがある**（[注意点](#注意点)）。

- RPM Fusion の FFmpeg を外し、AppStream の ESR に戻す
- AAC・H.264 のための FFmpeg だけ外すなら、この節の手順 1〜3 だけ行う
- EPEL は、手順 11 で一緒に入った場合も外さない（[btop.md](btop.md) などほかの手順書でも使う）
- プロファイル（`~/.mozilla/firefox`、新しく作られた場合は `~/.config/mozilla/firefox`）は、この節のどの手順でも消えない
- この節の手順 1〜3 はコンテナで本実行した
- Firefox を戻す手順（この節の手順 4〜7）は**本実行していない**
  - `dnf --assumeno distro-sync firefox` で、`firefox 140.15.0-1.el10_2 appstream` への `Downgrading` 1 パッケージに解決されることだけ確認した

1. FFmpeg のライブラリを消す。

   ```bash
   sudo dnf remove ffmpeg-libs
   ```

   - 手順 12 で一緒に入った依存も、ほかに使うものが無ければ一緒に消える
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. RPM Fusion（free）のリポジトリを消す。

   ```bash
   sudo dnf remove --noautoremove rpmfusion-free-release
   ```

   - `Removing:` が `rpmfusion-free-release` の 1 つだけになる
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: --noautoremove を付ける理由</summary>

   付けないと、手順 11 で依存として入った `epel-release` と `dnf-plugins-core` も「使われなくなった依存」として一緒に消える（コンテナでの実測）。EPEL はほかの手順書でも使い、`dnf-plugins-core` は `dnf config-manager` のパッケージなので残す。

   ```
   Removing:
    rpmfusion-free-release    noarch    10-1                @@commandline    3.8 k
   Removing unused dependencies:
    dnf-plugins-core          noarch    4.7.0-10.el10       @baseos           22 k
    epel-release              noarch    10-6.el10           @extras           25 k
   ```

   </details>

1. RPM Fusion の鍵も消すときだけ、その署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-db85ddd7-67a63d8b
   ```

   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. Mozilla の repo ファイルを消す。

   ```bash
   sudo rm -f /etc/yum.repos.d/mozilla.repo
   ```

   - **次の手順は、`sudo` のパスワードを聞かれたら答えてから貼る**（続けて貼ると答えとして食われる）

1. AppStream に無い言語パックを、ダウングレードより先に消す。

   ```bash
   sudo dnf remove ${FF_L10N}                    # 言語パックは AppStream に無いので先に消す
   ```

   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. Firefox を AppStream の ESR（140 系）にダウングレードする。

   ```bash
   sudo dnf distro-sync "${FF_PKG}"              # 140 系へダウングレードされる
   ```

   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. Mozilla の鍵も消すときだけ、その署名鍵を消す。

   ```bash
   sudo rpm -e gpg-pubkey-d98f0353-55a94004
   ```

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に Firefox の**最新版**（Rapid Release）を dnf 管理で入れ、Windows 版と同じように AAC と H.264 の動画も再生できるようにする。標準リポジトリ（AppStream）の `firefox` は ESR 140 系で、最新版より 16 メジャー古い
- **進め方**: Mozilla が公式に配っている RPM リポジトリ `packages.mozilla.org/rpm/firefox` を 1 つ足し、`dnf install` する。続けて RPM Fusion（free）を足し、FFmpeg のライブラリ `ffmpeg-libs` を入れる（手順 8〜14）。**読者が書き換えるのは冒頭の変数ブロックだけ**で、既定（最新版 + 日本語パック）ならそのまま貼れる
- **状態**
  - **手順 1〜7（Firefox）は実機で本実行済み（2026-09-21）**
    - 下表のホストで `dnf upgrade firefox` を実行し、AppStream の `140.15.0-1.el10_2` から mozilla の `156.0-1` に載せ替えて、そのまま常用している
    - 2026-09-25 に OS を入れ直した後も、手順 6 の `dnf install firefox firefox-l10n-ja` で入れ直した（`dnf history` では `Upgrade firefox-156.0.1-1.aarch64 @mozilla`）
    - 本書の手順（鍵の照合 → repo → install → 検証）は、2026-09-22 に同じ OS のコンテナで通し直した
    - 確認したこと: `156.0.1-1` が入る、ESR からの載せ替えが `Upgrading` として解決される、ロールバックが `Downgrading` に解決される
    - **コンテナでは GUI を起動していない**（実機では 156.0 が動作中）
    - **ESR / Beta チャンネルと言語パック以外の l10n は未検証**
  - **手順 8〜14（AAC・H.264）も実機で本実行済み（2026-09-28）**
    - 下表の実機で、利用者が手順どおりに入れた（[付録](#付録-実機での本実行2026-09-28)）
      - 手順 9 の鍵が登録されている
      - `dnf history` に、手順 11（4 パッケージ）と手順 12（`ffmpeg-libs` ほか 60 パッケージ）の実行が残っている
      - `libavcodec-free` は入っていなかったので、手順 13 は要らなかった
    - 利用者が、再生できなかった動画が再生できるようになったことを確かめた
    - 同じ実機で、一時プロファイルの headless の Firefox を Marionette で動かして次を確かめた
      - about:support の H264・HEVC・AAC が「対応」になる
      - AAC と H.264 の再生が通る
      - Firefox のプロセスが `/usr/lib64/libavcodec.so.61.19.101` を読み込んでいる
    - この文書の手順 1〜14 のブロックは、同じ OS の aarch64 コンテナでもそのまま流して通した（条件付きの手順 13 は、`libavcodec-free` を入れた別のコンテナで）
    - **音声が AAC だけの YouTube の動画での再生は確かめていない**（例の動画は、実機に入れる前に YouTube 側で Opus が足されていた。代わりに、AAC を MSE で流すテストを実機でも通した）
    - **x86_64 は、RPM Fusion のメタデータで `ffmpeg-libs` の依存が解決できることだけ確かめた**

| 項目 | 実機 | 検証コンテナ | 検証コンテナ（手順 8〜14） | 実機（手順 8〜14） |
|---|---|---|---|---|
| 実施日 | 2026-09-21 | 2026-09-22 | 2026-09-28 | 2026-09-28 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） | 同左 | 実機と同じホスト（2026-09-25 に入れ直した後） |
| カーネル | 6.12.96 | ホストと同じ | ホストと同じ | 6.12.96 |
| dnf | 4.20.0 | 4.20.0 | 4.20.0 | 4.20.0 |
| 実施前の Firefox | `firefox-140.15.0-1.el10_2.aarch64`（appstream、ESR 140） | 同じものを `dnf install firefox` で用意 | `firefox-156.0.1-1.aarch64`（mozilla。手順 2〜6 で用意） | `firefox-156.0.1-1.aarch64`（mozilla。2026-09-25 に手順 6 で入れ直したもの） |
| 入った Firefox | `firefox-156.0-1.aarch64`（mozilla、Vendor: Mozilla） | `firefox-156.0.1-1.aarch64` | 同左。FFmpeg は `ffmpeg-libs-7.1.5-1.el10.aarch64`（rpmfusion-free-updates） | Firefox は変わらない。FFmpeg は `ffmpeg-libs-7.1.5-1.el10.aarch64`（rpmfusion-free-updates） |
| デスクトップ | GNOME 49 / Wayland | 無し（`--version` まで） | 無し（headless の Firefox を Marionette で操作） | GNOME 49（`gnome-shell` 49.4） |
| SELinux | Enforcing | コンテナ側は無効 | コンテナ側は無効 | Enforcing |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${FF_PKG}` | 入れるチャンネルのパッケージ名。`firefox`（最新版）/ `firefox-esr` / `firefox-beta` | `firefox` |
> | `${FF_L10N}` | 言語パックのパッケージ名。空にすると英語 UI のまま | `firefox-l10n-ja` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`156.0.1-1`、`7.1.5-1.el10`）は実行日によって変わる。
>
> 鍵の fingerprint（Mozilla・RPM Fusion・EPEL）は公開情報なので本文に書いてある。プロファイルや保存されたパスワードには触れない。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| Firefox | `firefox-140.15.0-1.el10_2.aarch64`（appstream）。`firefox --version` は `Mozilla Firefox 140.15.0esr` |
| AppStream の候補 | `140.10.1-1.el10_2` 〜 `140.15.0-1.el10_2`（ESR 140 系のみ。Rapid Release は無い） |
| 有効な追加リポジトリ | epel、crb、raspberrypi（mozilla はまだ無い） |
| Flatpak | `flatpak-1.16.0` は導入済みだが**リモートが 1 つも登録されていない**（flathub 無し） |
| 鍵 | `rpm -q gpg-pubkey` に Mozilla の鍵は無し |

手順 8〜14 の前の実機（2026-09-28）。2026-09-25 に OS を入れ直し、Firefox は手順 6 で入れ直してある:

| 項目 | 状態 |
|---|---|
| Firefox | `firefox-156.0.1-1.aarch64`（mozilla） |
| FFmpeg | `/usr/lib64/libavcodec*` が無い |
| 有効な追加リポジトリ | mozilla・crb・raspberrypi など。**EPEL と RPM Fusion は無い** |
| プロファイル | `~/.config/mozilla/firefox`（`~/.mozilla` は無い）。Cisco の OpenH264（`gmp-gmpopenh264`）はまだ落ちていない |

### 選択した方針

AlmaLinux 10 で Firefox の最新版を使う経路を比べた（2026-09-22 時点）:

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Mozilla 公式 RPM リポジトリ** | `packages.mozilla.org/rpm/firefox` に `firefox` 156.0.1 / `firefox-esr` 153.3.0esr / `firefox-beta` 157.0b4 と各言語パックがあり、**aarch64 と x86_64 の両方**が揃っている。dnf 管理で更新できる | **採用** |
| AppStream の `firefox` | 140.15.0（ESR 140 系）。AlmaLinux がセキュリティ更新を出すが、最新版の機能は入らない | 不採用（最新版ではない） |
| Flathub の `org.mozilla.firefox` | Mozilla 公式ビルド。ただしこのホストは flatpak にリモートが 1 つも登録されておらず、flathub の追加と ~150 MB の runtime 導入から始まる。RPM と二重管理になる | 不採用（RPM で足りる） |
| 公式 tarball を `/opt` に展開 | `linux-aarch64` のビルドが公式にある（Firefox 136 以降）。更新は Firefox 内蔵のアップデータ任せで、`.desktop` を自作する必要がある | 不採用（dnf で管理できない） |
| ソースビルド | 実用的でない | 不採用 |

**最新版であることの確認**:

- Mozilla の `product-details` が返す `LATEST_FIREFOX_VERSION` は `156.0.1`、`FIREFOX_ESR` は `140.16.0esr`（2026-09-22）
- リポジトリの `firefox` 156.0.1 は、Rapid Release の最新と一致する

**AAC と H.264 を OS の FFmpeg で補う理由**:

- Mozilla の Linux 版 Firefox は、AAC と H.264 のデコーダを持っていない
  - 同梱の FFmpeg（`libmozavcodec.so`、62.29.101）に入っているデコーダは、flac・mp3・vorbis・opus・pcm だけだった（[付録](#付録-動画が再生できなかった件の切り分け2026-09-28)）
  - AAC と H.264 は、OS の `libavcodec.so.53`〜`.63` を探して読み込む。AlmaLinux 10 の標準リポジトリには FFmpeg が無い
- そのため、音声が AAC しか無い YouTube の動画は再生できない。同じ動画が、Windows の Firefox では再生できた（利用者の報告）
- H.264 は、Firefox が起動後に自動で落とす Cisco の OpenH264（GMP プラグイン）でも再生できる。AAC を補えるのは FFmpeg だけ

FFmpeg のライブラリの入れ方を比べた（2026-09-28 時点。aarch64 のコンテナで Firefox 156.0.1 を動かして確かめた）:

| 経路 | AAC | H.264 | 採否 |
|---|---|---|---|
| 何も足さない | 再生できない | OpenH264 が落ちるまでは再生できない。落ちた後は再生できる | —（元の状態） |
| **RPM Fusion（free）の `ffmpeg-libs` 7.1.5** | 再生できる | 再生できる（FFmpeg で復号） | **採用** |
| EPEL の `libavcodec-free` 7.1.2 | 再生できる | **再生できない**。H.264 を OpenH264 に任せる作りで、EL10 には中身の無い `noopenh264` しか無い。about:support には「対応」と出るのに `Couldn't open avcodec` で止まり、落ちてきた OpenH264 にも切り替わらない | 不採用 |
| RPM Fusion の `libavcodec-freeworld` | — | — | 不採用（EPEL の `ffmpeg-free` を使い続けるときに足すもの。RPM Fusion の Howto/Multimedia の案内による） |

- RPM Fusion の EL 10 向けには、`ffmpeg-libs` 7.1.5 が aarch64 と x86_64 の両方にある
- RPM Fusion は EPEL を前提にしている（`rpmfusion-free-release` が `epel-release` を要求する）

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

- 入るファイル: 本体は `/usr/lib/firefox/`、起動スクリプトは `/usr/bin/firefox`、`.desktop` は `/usr/share/applications/firefox.desktop`
- 本体の場所は AppStream 版（`/usr/lib64/firefox/`）と違うが、起動スクリプトと `.desktop` は同じパスなので、アプリ一覧やデフォルトブラウザの設定はそのまま引き継がれる
- 2026-09-25 に入れ直した実機では、プロファイルは `~/.config/mozilla/firefox` に作られた（`~/.mozilla` は無い）

手順 8〜14 の後（コンテナ、2026-09-28）:

```
$ dnf -q repoquery --installed --qf '%{name} %{version}-%{release} %{from_repo}\n' ffmpeg-libs rpmfusion-free-release epel-release
epel-release 10-6.el10 extras

ffmpeg-libs 7.1.5-1.el10 rpmfusion-free-updates

rpmfusion-free-release 10-1 @commandline

$ ls /usr/lib64/libavcodec.so.*
/usr/lib64/libavcodec.so.61
/usr/lib64/libavcodec.so.61.19.101
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i fusion
gpg-pubkey-db85ddd7-67a63d8b RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org> public key
```

- 有効なリポジトリに `epel` と `rpmfusion-free-updates` が加わる（`rpmfusion-free-updates-testing` の repo ファイルも置かれるが、無効）
- about:support の「コーデックサポート情報」では、H264・HEVC・AAC の「ソフトウェアデコーディング」が「対応」になる（[手順 14 の補足](#実施手順)）

実機（2026-09-28、利用者が手順どおりに入れた後）:

```
$ rpm -q ffmpeg-libs rpmfusion-free-release epel-release
ffmpeg-libs-7.1.5-1.el10.aarch64
rpmfusion-free-release-10-1.noarch
epel-release-10-6.el10.noarch
$ rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n' | grep -i -E 'fusion|epel'
gpg-pubkey-db85ddd7-67a63d8b RPM Fusion free repository for EL (10) <rpmfusion-gpg-key-el10-free@rpmfusion.org> public key
gpg-pubkey-e37ed158-65785fa9 Fedora (epel10) <epel@fedoraproject.org> public key
```

- 手順 11 で、CRB の `selinux-policy-extra` と `selinux-policy-targeted-extra` も入っている（[手順 11 の補足](#実施手順)）

### 注意点

- **チャンネルが変わる**: ESR（年 1 回のメジャー更新）から Rapid Release（4 週間ごと）に移る
  - 企業ポリシーで ESR を使っている場合は、`FF_PKG=firefox-esr`（Mozilla の ESR 153 系）か、そもそもこの手順を使わない
- **セキュリティ更新の出所が変わる**: AppStream 版は AlmaLinux が、mozilla 版は Mozilla が直接出す
  - `dnf upgrade` の対象になるのは同じだが、AlmaLinux のエラータ（`dnf updateinfo`）には載らない
- **ダウングレードするとプロファイルを読めないことがある**: 156 で開いたプロファイルを 140 で開くと、「新しいバージョンの Firefox で作成されたプロファイル」と警告が出る
  - 戻す前提があるなら、先に `~/.mozilla/firefox`（新しく作られた場合は `~/.config/mozilla/firefox`）を退避しておく
- **言語パックは本体と同時に上げる**: バージョンが食い違うと UI が英語に戻る。`dnf upgrade` 全体を流していれば自動で揃う
- **更新のたびに 107 MB 落ちてくる**: 4 週間ごとの Rapid Release なので、従量課金の回線では効いてくる
- **RPM Fusion は Fedora の外のリポジトリ**: free は「Fedora がライセンス以外の理由で配れないオープンソースのソフト」を配る（RPM Fusion の Configuration の説明）
  - 鍵は手順 8 で照合し、`rpmfusion-free-release` の署名も手順 11 で確かめる
- **FFmpeg を入れたら Firefox を起動し直す**: 起動中の Firefox は読み直さない（手順 14）
- **EPEL の `libavcodec-free` とは同居できない**: 入っていると手順 12 が止まる。残したままだと H.264 が再生できない（手順 13）
- **aarch64 の Firefox には Widevine が無い**: Firefox 156（aarch64）には `media.gmp-widevinecdm.*` の設定が無く、`media.eme.enabled` も既定で false だった
  - DRM の要る動画は、FFmpeg を入れても直らない（DRM の動画そのものは試していない）

### 参照

- [Install Firefox on Linux — Mozilla Support](https://support.mozilla.org/en-US/kb/install-firefox-linux) — 公式のインストール経路の一覧
- [Introducing Mozilla's Firefox Nightly .rpm package — Firefox Nightly News](https://blog.nightly.mozilla.org/2026/01/19/introducing-mozillas-firefox-nightly-rpm-package-for-rpm-based-linux-distributions/) — RPM リポジトリの repo ファイルの書き方（RHEL / CentOS / Rocky 向けの `tee` の例）と鍵の fingerprint
- [Firefox Developer Edition and Beta: Try out Mozilla's .rpm package! — Mozilla Hacks](https://hacks.mozilla.org/2026/03/firefox-developer-edition-and-beta-try-out-mozillas-rpm-package/) — beta / devedition チャンネルの追加
- [firefox_versions.json — Mozilla product-details](https://product-details.mozilla.org/1.0/firefox_versions.json) — その時点の最新版と ESR の版を機械可読で返す
- [Configuration — RPM Fusion](https://rpmfusion.org/Configuration) — free / nonfree の区別と、EL 向けの有効化（`--nogpgcheck` の例と、Alma・Rocky の `crb enable`）
- [Trusting Package Integrity — RPM Fusion](https://rpmfusion.org/keys) — 鍵の fingerprint と、鍵を先に取り込んで `localpkg_gpgcheck=1` で入れる方法
- [Multimedia — RPM Fusion](https://rpmfusion.org/Howto/Multimedia) — `ffmpeg-free` からの切り替え（`dnf swap`）と、`libavcodec-freeworld` の位置づけ
- `man dnf.conf`（`priority`、`gpgcheck`、`repo_gpgcheck`、`localpkg_gpgcheck`）

---

### 付録: コンテナでの検証記録（2026-09-22）

実機の設定に触れずに手順を通すため、`podman run --rm docker.io/library/almalinux:10` の使い捨てコンテナで実行した。実機で加えた変更は `dnf install podman` だけ。 最後にもう 1 つ新しいコンテナを立て、**この文書のコードブロックをそのまま抜き出したスクリプト**（`sudo` を外し、`dnf install` / `dnf upgrade` に `-y` を付けただけ）を流して、上から順に貼れば通ることを確かめている。

手順ごとの結果:

| 手順 | 結果 |
|---|---|
| 2〜4. 鍵 | `gpg --show-keys` の fingerprint が `14F26682D0916CDD81E37B6D61B7B526D98F0353` と一致。`rpm --import` は期限切れ副鍵の warning を出して成功、`gpg-pubkey-d98f0353-55a94004` が登録された |
| 5. repo | メタデータ取得に成功。`firefox` は `154.0.1-1` / `155.0-1` / `155.0.1-1` / `156.0-1` / `156.0.1-1` の 5 世代が aarch64・x86_64 の両方で見えた |
| 6. install | ESR 140.15.0 が入った状態から `dnf upgrade -y firefox` で `156.0.1-1` に載せ替え。追加の依存パッケージ無し |
| 7. 検証 | `firefox --version` → `Mozilla Firefox 156.0.1`、`rpm -qi` の `Signature` は `Key ID 678e455d76767aa3`（Mozilla の署名用副鍵） |
| 言語パック | 未導入のコンテナで `dnf install -y firefox firefox-l10n-ja` → `firefox 156.0.1-1 mozilla` と `firefox-l10n-ja 156.0.1-1 mozilla` が入る |
| ロールバック | repo ファイルを消して `dnf --assumeno distro-sync firefox` → `Downgrading firefox 140.15.0-1.el10_2 appstream` 1 パッケージ |

途中で 1 度、`packages.mozilla.org` の名前解決がコンテナ内でタイムアウトして `dnf` がメタデータ取得に失敗した（`Curl error (6): Could not resolve host`）。同じコマンドの再実行で通ったので、リポジトリ側ではなく一時的なものと判断している。

#### 未確認事項

- 実機の GUI で 156 系を起動したあとの `about:support` の記載（実機では常用しているが、`about:support` の内容を記録していない）
- `firefox-esr`（Mozilla の ESR 153 系）と `firefox-beta` の導入、および AppStream の ESR 140 との共存
- 日本語以外の言語パック、`firefox-devedition`
- ロールバック（`distro-sync` によるダウングレード）の本実行と、その後のプロファイルの読み込み
- Flathub 版との併用時の挙動（`.desktop` の重複、既定ブラウザの選択）

### 付録: 動画が再生できなかった件の切り分け（2026-09-28）

AlmaLinux 10 の Firefox（Mozilla 版 156.0.1）で YouTube の一部の動画が再生できず、同じ動画は Windows の Firefox では再生できた（利用者の報告）。原因を切り分け、手順 8〜14 をコンテナで確かめた記録。

**動画の形式**: watch ページの `ytInitialPlayerResponse` にある `adaptiveFormats` を `curl` で読んだ。同じ日に 2 回読んだところ、形式が変わっていた:

| 読んだとき | 映像 | 音声 |
|---|---|---|
| 1 回目 | 各解像度に H.264（`avc1.4d40xx`）と VP9 | **AAC（itag 140、`mp4a.40.2`）だけ** |
| 2 回目 | 720p 以上は H.264（`avc1.6400xx`）だけ、VP9 は 360p だけ | AAC と Opus（itag 251） |

1 回目の形式では、AAC を復号できない Firefox は音声を再生できない。2 回目の形式なら、FFmpeg が無くても Opus で音声を再生でき、映像は VP9 の 360p か、OpenH264 が落ちていれば H.264 になる。

**Firefox の中身**（実機の `/usr/lib/firefox`）:

- `libmozavcodec.so` を Python の ctypes で読み込んで調べた。`avcodec_version` は 62.29.101、`av_codec_iterate` で列挙したデコーダは `flac mp3 libvorbis pcm_alaw pcm_f32le pcm_mulaw pcm_s16le pcm_s24le pcm_s32le pcm_u8 libopus` だけ
- `libxul.so` の文字列にある読み込み先は、`libavcodec.so.53`〜`libavcodec.so.63` と `libavcodec-ffmpeg.so.56`〜`58`
- 実機には `/usr/lib64/libavcodec*` が無く、プロファイルに OpenH264（`gmp-gmpopenh264`）も無かった

**調べ方**:

- headless の Firefox を `--marionette -remote-allow-system-access` で起動し、Python の標準ライブラリだけで書いた Marionette のクライアントから、ページでスクリプトを動かした（一時プロファイルを使い、日本語 UI にした）
- 素材は RPM Fusion の `ffmpeg` で作った: 3 秒の AAC の m4a、断片化した AAC の m4a、H.264 Main + AAC の mp4、VP9 + Opus の webm、Opus の webm
- 調べたのは次の 5 つ
  - about:support の「コーデックサポート情報」
  - `OfflineAudioContext.decodeAudioData` での AAC の復号
  - MSE（`MediaSource`。YouTube と同じ再生の仕方）での AAC の再生
  - `<video>` での H.264 + AAC の mp4 の再生
  - YouTube の同じ動画（2 回目の形式）がどの形式で再生されるか（`getStatsForNerds().codecs`）
- コンテナは podman（rootless）の `docker.io/library/almalinux:10`（aarch64、2026-09-02 のイメージ）。Firefox は手順 2〜6 と同じ方法で入れた

**結果**:

| 状態 | about:support の H264 / AAC | AAC の復号 / MSE | H.264 + AAC の mp4 | YouTube |
|---|---|---|---|---|
| 実機、何も足さない | 未対応 / 未対応 | `EncodingError` / `addSourceBuffer` が `NotSupportedError` | `NotSupportedError` | — |
| コンテナ、何も足さない（起動直後） | 未対応 / 未対応 | 実機と同じ | `NotSupportedError` | — |
| コンテナ、何も足さない（OpenH264 2.6.0 が落ちた後） | 未対応 / 未対応 | 実機と同じ | 映像は再生された | H.264 1080p60（itag 299）+ Opus で再生された |
| コンテナ、EPEL の `libavcodec-free` 7.1.2 | 対応 / 対応 | 再生できた | `Couldn't open avcodec`（OpenH264 が落ちた後も同じ） | — |
| コンテナ、`ffmpeg-libs` 7.1.5（Firefox を起動し直す前） | 未対応 / 未対応 | 入れる前と同じ | 映像は再生された（OpenH264） | — |
| コンテナ、`ffmpeg-libs` 7.1.5（起動し直した後） | 対応 / 対応（HEVC も対応） | 再生できた | 再生できた | H.264 1080p60（itag 299）+ Opus で再生された |

- OpenH264 2.6.0 は、Firefox を起動して 1 分ほどでプロファイルの `gmp-gmpopenh264` に落ちてきた（`media.gmp-gmpopenh264.enabled` は既定で true）
- 何も足さない状態でも、起動直後は `MediaSource.isTypeSupported('audio/mp4; codecs="mp4a.40.2"')` が true を返した（`addSourceBuffer` は失敗する）。しばらく後は false になった
- EPEL の `libavcodec-free` では、`media.ffmpeg.allow-openh264`（既定で true）により H.264 が `noopenh264` に回る。about:support の「対応」は、復号できることを意味しない
- `ffmpeg-libs` を入れた後、Firefox のプロセスが `/usr/lib64/libavcodec.so.61.19.101` を読み込んでいることを `/proc/<pid>/maps` で確かめた

**文書どおりに通るか**: 新しいコンテナで `gnupg2` だけ先に入れ、この文書の `## 実施手順` の bash ブロックを抜き出したスクリプトを流した。変えたのは、`sudo` を外したことと、`dnf install` に `-y` を付けたことだけで、条件付きの手順 13 は外した。

| 手順 | 結果 |
|---|---|
| 1〜7 | `firefox` と `firefox-l10n-ja` の `156.0.1-1` が入った（197 パッケージ、ダウンロード 226 MB） |
| 8〜10. 鍵 | fingerprint が `5FC4AE73FC2B08B9DFE7EB990C8489D8DB85DDD7` と一致。`rpm --import` は何も表示せず、`gpg-pubkey-db85ddd7-67a63d8b` が登録された |
| 11. リポジトリ | `rpmfusion-free-release 10-1` と、依存の `epel-release 10-6.el10`、弱い依存の `dnf-plugins-core` の 3 パッケージ |
| 12. FFmpeg | `ffmpeg-libs 7.1.5-1.el10` ほか 79 パッケージ（ダウンロード 42 MB、展開後 137 MB）。EPEL の鍵 `0xE37ED158` の取り込みが 1 回あった |
| 13. 衝突 | 別のコンテナで、EPEL の `libavcodec-free` を入れてから手順 12 を実行すると `conflicts with libswresample-free` で止まった。`dnf install --allowerasing ffmpeg-libs` で `libavcodec-free`・`libavutil-free`・`libswresample-free` の 3 つが外れて入れ替わった |
| 14. 確認 | `ffmpeg-libs 7.1.5-1.el10 rpmfusion-free-updates` と `/usr/lib64/libavcodec.so.61`。起動した Firefox で、about:support の H264・HEVC・AAC が「対応」になり、AAC と H.264 の再生も通った |
| ロールバック 1〜3 | 手順 1 で 78 パッケージ・119 MB が消えた（手順 12 で入ったもののうち `glibc-gconv-extra` だけが残った）。手順 2 は `rpmfusion-free-release` の 1 つだけで、`epel-release` と `dnf-plugins-core` は残った。手順 3 で `gpg-pubkey-db85ddd7-67a63d8b` が消えた |

**x86_64**: `dnf --forcearch=x86_64` で `ffmpeg-libs.x86_64 7.1.5-1.el10` が見えた。空の installroot に `ffmpeg-libs` を入れる解決が、238 パッケージで通った（導入・起動はしていない）。

#### 未確認事項

- 実機（Raspberry Pi 5）への導入と、画面での再生（手順 14 の GUI の確認）
- x86_64 での導入と再生（メタデータのみ）
- 音声が AAC だけの YouTube の動画の再生（YouTube の形式が変わったので、MSE で AAC を流すテストで代えた）
- コマンドの `ffmpeg-free` が入っているホストでの切り替え（RPM Fusion の案内では `dnf swap ffmpeg-free ffmpeg --allowerasing`）
- ハードウェアでの復号（about:support ではすべて「未対応」だった）
- DRM（Widevine）の要る動画
- AppStream の ESR 140 に戻したときに、`~/.config/mozilla/firefox` のプロファイルを読むか

### 付録: 実機での本実行（2026-09-28）

前の付録の後、利用者が実機（2026-09-25 に入れ直した Raspberry Pi 5）で手順どおりに入れ、再生できなかった動画が再生できるようになった。前の付録の未確認事項のうち、実機への導入と再生はこれで済んだ。

**`dnf history`**（時刻は実機の JST）:

| ID | 日時 | コマンド | 結果 |
|---|---|---|---|
| 19 | 2026-09-28 02:13 | `--setopt=localpkg_gpgcheck=1 install https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-10.noarch.rpm` | Success。`rpmfusion-free-release`・`epel-release`（extras）・`selinux-policy-extra`・`selinux-policy-targeted-extra`（crb）の 4 パッケージ |
| 20 | 2026-09-28 02:15 | `install ffmpeg-libs` | Success（7 秒）。60 パッケージ（EPEL 44・AppStream 10・RPM Fusion 4・BaseOS 2） |

- 手順 9 の RPM Fusion の鍵（`gpg-pubkey-db85ddd7-67a63d8b`）と、手順 12 で取り込まれた EPEL の鍵（`gpg-pubkey-e37ed158-65785fa9`）が登録されていた
- `libavcodec-free` は入っておらず、`--allowerasing` の実行も無い（手順 13 は要らなかった）
- `dnf repoquery --installed --qf '%{name} %{reason}'` では、`selinux-policy-extra` が `weak-dependency`、`selinux-policy-targeted-extra` が `dependency`。`epel-release` の Recommends の `(selinux-policy-epel if selinux-policy)` を、`selinux-policy-extra` が `selinux-policy-epel` を提供して満たしている

**入れた後の Firefox**（一時プロファイルの headless の Firefox を、前の付録と同じプローブで調べた。利用者のプロファイルには触れていない）:

- about:support の「コーデックサポート情報」は、H264・HEVC・AAC の「ソフトウェアデコーディング」が「対応」。「ハードウェアデコーディング」はすべて「未対応」
- `decodeAudioData` で AAC を復号でき、MSE で AAC を流せた。H.264 + AAC の mp4 も再生できた
- Firefox のコンテンツプロセス 2 つが `/usr/lib64/libavcodec.so.61.19.101` を読み込んでいた

#### 未確認事項

- 音声が AAC だけの YouTube の動画での再生（例の動画は、実機に入れる前に YouTube 側で Opus が足されていた）
- 画面に出した about:support の表示（headless の Firefox でだけ確かめた）
- x86_64 での導入と再生（メタデータのみ）
