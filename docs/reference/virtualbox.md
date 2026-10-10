# VirtualBox インストール手順（AlmaLinux 10 は Oracle 公式 dnf リポジトリ / Windows 11 は winget）の参考資料

[手順書](../virtualbox.md)・[ロールバックと注意点](../extra/virtualbox.md)

[検証記録](../verification/virtualbox.md#参考資料から分離した記録)

## 補足

### 実施手順 / 手順 2: 補足: gpg と sub の fingerprint

- `gpg`（`gnupg2`）は、GNOME のデスクトップには入っている
- `sub` の下にも fingerprint が出るのは、Homebrew の gnupg が先に見つかる PC（[検証記録](../verification/virtualbox.md)）

### 実施手順 / 手順 4: 補足: repo ファイルは Oracle 公式のものとほぼ同じ

**repo ファイルは Oracle 公式のもの（`https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo`）とほぼ同じ**。

- 変えたのは、`baseurl` の `http://` を `https://` にしたこと（同じホストが HTTPS でも応答する）と、`name` だけ
- `gpgcheck` / `repo_gpgcheck` / `gpgkey` は公式どおり
- `$releasever` は AlmaLinux 10 では `10` に展開されるので、`.../rpm/el/10/x86_64` を見に行く
- ヒアドキュメントは `<<'EOF'`（クォート付き）。`$releasever` / `$basearch` は dnf が展開するので、シェルに展開させない

### 実施手順 / 手順 4: 補足: メタデータの署名と鍵の確認

- このリポジトリは、メタデータにも署名がある（`repo_gpgcheck=1`）
- dnf はそれを確かめるための鍵を rpm とは別に持つので、最初の 1 回だけ鍵の取り込みを聞かれる

### 実施手順 / 手順 5: 補足: sudo を付けない dnf にも通す理由

- `sudo` を付けない dnf は、ユーザーごとの別のキャッシュを使う
- 通しておかないと、`sudo` を付けない `dnf list` などが関係の無いパッケージでも失敗する

### 実施手順 / 手順 7: 補足: 動いているカーネルを最新にしておく理由

`kernel-devel` は動いているカーネル（`uname -r`）と同じ版を入れ、モジュールもその版向けにビルドされる。更新済みのカーネルでまだ起動していないと、次の起動で新しいカーネル用のモジュールを作り直すことになる（[カーネルを更新したとき](../virtualbox.md#カーネルを更新したとき)）。

### 実施手順 / 手順 8: 補足: 先に入れる理由

- VirtualBox は、自分のカーネルモジュール（`vboxdrv` / `vboxnetflt` / `vboxnetadp`）をインストールの途中で、この PC の上でビルドする

### 実施手順 / 手順 10: 補足: Complete! だけでは成功とは限らない理由

- モジュールのビルドや読み込みに失敗しても、dnf は `Complete!` で終わる

### 実施手順 / 手順 11: 補足: KVM の設定

- EL10 のカーネル（6.12 系）では、KVM のモジュールが読み込まれた時点で VT-x / AMD-V を確保し、VirtualBox の VM が起動できなくなる
- KVM を使っていなくても、VT-x / AMD-V のある PC では起動時に自動で読み込まれる
- この設定で、KVM が自分の VM を動かす間だけ確保するように変える
- `modprobe -c` が出すのは、modprobe が読んだ設定
- 効くのは次に kvm が読み込まれたとき。同じ節の手順 13 の再起動で反映させる
- KVM（libvirt / GNOME Boxes など）はこの後も使えるが、KVM の VM と VirtualBox の VM は同時には動かせない

### 実施手順 / 手順 12: 補足: 効く時期

- `vboxusers` に入ったことが効くのはログインし直してから（同じ節の手順 13 の再起動で済む）

### 実施手順 / 手順 16: 補足: 使い捨ての VM

- VirtualBox が VT-x / AMD-V を取れるか（KVM とぶつからないか）は、ここで初めて分かる
- 作成に失敗したときも、変更・起動・削除には進まない。削除するのは、このブロックで作成できた VM だけ
- 起動するディスクが無いので、VM の中では何も動かない

### 実施手順 / 手順 17: 補足: 一覧が空の理由

- VirtualBox マネージャーの一覧が空なのは、同じ節の手順 16 の VM を消してあるため

### 更新 / 手順 2: 補足: 同じ系列の中で上げたとき

- 更新のたびに `%post` がモジュールをビルドし直すので、[実施手順](../virtualbox.md#実施手順)の手順 10 と同じ確認をする
- コンテナで 7.2.18 → 7.2.20 を上げたときは、`%post` が新規導入のときと同じ表示を出した
- モジュールは 7.2.20 用に作り直された（`modinfo -F version` が `7.2.18 r175117` → `7.2.20 r175154`）
- `/sbin/vboxconfig` と udev のルールも残った

### 更新 / 手順 4: 補足: そのまま使えるもの

- 系列を変えても、repo ファイル・鍵・EPEL・ビルドの道具・MOK・KVM の設定はそのまま使える

### Windows 11 で使う / 手順 2: 補足: 確かめる値の意味

- `Hypervisor` が `True` なら、Hyper-V のハイパーバイザーが動いている（WSL 2 を使う PC など）。VirtualBox の VM は Hyper-V の上で動き、遅くなる（[注意点](../extra/virtualbox.md#注意点)）
- 最後の表は、Hyper-V を使う Windows の機能の状態（`Enabled` / `Disabled`）。一覧を作るのに数秒かかる

### Windows 11 で使う / 手順 3: 補足: winget で入れるときに起きること

- 依存の Microsoft Visual C++ の再頒布可能パッケージ（`Microsoft.VCRedist.2015+.x64`）が無ければ、先にそれが入る
- 途中でネットワークがいったん切れるのは、VirtualBox のネットワークのドライバーを入れるため
- デスクトップとスタートメニューに「Oracle VirtualBox」のショートカットができる

### Windows 11 で使う / 手順 4: 補足: winget のソースを限定する理由

- `--source winget` を付けた `winget list` は、入っているアプリを winget のカタログと照合し、確認に要らない Microsoft Store のソースの初回同意を避ける

### Windows 11 で使う / 手順 4: 補足: 版と VBoxManage の場所

- 版は、実行した日の最新
- `VBoxManage` は `PATH` に入らないので、場所を付けて呼ぶ

### Windows 11 で使う / 手順 5: 補足: 管理者ではない窓で動かす理由

- 管理者の窓から起動したもの（`VBoxManage`・`VirtualBox.exe`）は、管理者の権限で動く。AlmaLinux 10 で VM を root ではなく自分のユーザーで動かすのと同じく、VM は自分のユーザーで動かす
- VirtualBox のマニュアルは、管理者の権限で動かした VirtualBox と、普通の権限で動くエクスプローラーの間では、ドラッグ＆ドロップができないと書いている
- VM と設定の場所（`%USERPROFILE%\VirtualBox VMs` と `%USERPROFILE%\.VirtualBox`）はユーザーごと。管理者の窓でも同じユーザーなので、場所は変わらない

### Windows 11 で使う / 手順 6: 補足: 使い捨ての VM

- VirtualBox が VT-x / AMD-V（か Hyper-V）を使えるかは、ここで初めて分かる
- 起動するディスクが無いので、VM の中では何も動かない
- 作成に失敗したときも、変更・起動・削除には進まない。削除するのは、このブロックで作成できた VM だけ

### Windows 11 で使う / 手順 7: 補足: 一覧が空の理由

- VirtualBox マネージャーの一覧が空なのは、同じ節の手順 6 の VM を消してあるため

### Windows 11 で使う / 手順 8: 補足: 設定の場所

- Windows の VirtualBox は、全体の設定を `%USERPROFILE%\.VirtualBox` に置く（AlmaLinux 10 の `~/.config/VirtualBox` に当たる。マニュアルの 13.1.2「Global Settings」）

### Windows 11 の VirtualBox を Android からリモート デスクトップで使う（任意） / 手順 1: 補足: 文字が別のキーになる理由

- RDP のクライアントは、キーを 2 通りで送れる
  - キーの位置（スキャンコード）を送る Keyboard Event と、文字を送る Unicode Keyboard Event（MS-RDPBCGR）
  - Windows の RDP サーバーは、Input Capability Set の `INPUT_FLAG_UNICODE` で Unicode を受け付けると知らせる
- Android の Windows App は、既定で Unicode で送る（Microsoft の文書。前のアプリの Remote Desktop も同じ）。「使用可能な場合にスキャンコード入力を使用する」をオンにすると、スキャンコードで送る
- Windows は、Unicode の入力を仮想キー `VK_PACKET` のキーとしてアプリに渡す。`KEYBDINPUT` の文書では、Unicode のときはスキャンコードの欄（`wScan`）に文字が入る
- VirtualBox 7.2.20 の VM のウィンドウ（Windows 版の `UIKeyboardHandler.cpp`）は、スキャンコードの欄をそのままゲストのスキャンコードにする
  - VM の画面にフォーカスが来ると、低レベルのキーボード フック（`WH_KEYBOARD_LL`）を入れる（1405〜1416 行）
  - キーボードを捕捉している間は、フックが受けた `scanCode & 0xFF` をメッセージに入れて処理し（1657 行）、イベントを Windows に返さない（1574 行）
  - 処理は `(lParam >> 16) & 0x7F` をスキャンコードとし、0 だけを捨てる（951〜957 行）。仮想キーが `VK_PACKET` かは見ない
- そのため、文字コードがそのままキーになる
  - `1`（0x31）は N、`2`（0x32）は M、`.`（0x2E）は C、`,`（0x2C）は Z（2026-10-08 に確かめた）
  - コードの上では、英小文字（0x61〜0x7A）はふつうのキーに当たらないか、かな（0x70）・変換（0x79）などのキーになる。`8` は左 Alt（0x38）、`9` はスペース（0x39）、`A`〜`D` は F7〜F10 になる
- 同じ症状の報告がある: Microsoft Q&A（Android の RDP から Windows の上の VirtualBox で `1` が `n`、`2` が `m`）、Dell のフォーラム（`.` が `c`、`,` が `z`）
- Microsoft の文書は、Qt で作ったアプリ（VirtualBox の GUI は Qt）・Hyper-V の VMConnect・VMware Remote Console では、スキャンコードのモードを使うよう書いている
- スキャンコードのモードでは、クライアントがキーの位置を送り、VirtualBox はそれをそのままゲストに渡す。どの文字になるかは、ゲストのキー配列で決まる
- Android の IME は、Unicode のモードでしか使えない（Microsoft の文書）

### Windows 11 の更新 / 手順 2: 補足: VBoxSVC が残る理由

- `VBoxSVC` は、VirtualBox マネージャーや VM を閉じた後、しばらく残る。ソースでは、使われなくなってから 5 秒で終わる

### Windows 11 の更新 / 手順 3: 補足: 今の版の上から入れる

- 新しい版のインストーラを、今の版の上から動かす（winget の定義の `UpgradeBehavior: install`）。VM と設定は残る

### 選択した方針

| 経路 | EL10 での状況 | 採否 |
|---|---|---|
| **Oracle 公式 dnf リポジトリ** | EL10 向けのビルド（`_el10`）があり、メタデータにもパッケージにも署名がある。`dnf upgrade` で上がる | **採用** |
| 公式サイトの `.rpm` を直接入れる | 同じ rpm だが、更新のたびに手で落とすことになる | 不採用 |
| 汎用インストーラ（`VirtualBox-7.2.20-175154-Linux_amd64.run`） | `/opt/VirtualBox` に入り、dnf の管理外になる | 不採用 |
| Oracle Linux の `ol10_developer` チャンネル | Oracle Linux 専用 | 対象外 |
| RPM Fusion | EL10 には VirtualBox が無い（EL9 に 7.1.18） | 不採用 |
| Flathub | 無い（カーネルモジュールが要るため） | — |
| 7.1 系（`VirtualBox-7.1`） | 同じリポジトリにある保守版。7.2 と同時には入らない | 対象外 |
| KVM（libvirt / virt-manager / GNOME Boxes） | AlmaLinux 標準の仮想化。カーネルに組み込み済みでモジュールのビルドも署名も要らない | 対象外（本書は VirtualBox を入れる）。VirtualBox と同時には動かない（手順 11） |

aarch64 には入らない:

- 7.2.20 の配布物にも Linux の arm64 版が無い（arm64 向けは macOS の Apple Silicon 版と、Windows の実験的な対応だけ）
- マニュアルの対応ホストの一覧も、Linux はすべて x86_64 になっている

Android からリモート デスクトップでつないで、PC の上の VM に打つ方法を比べた（2026-10-08）:

| 方法 | 状況 | 採否 |
|---|---|---|
| **Windows App の「使用可能な場合にスキャンコード入力を使用する」をオンにする** | Android の設定 1 つで、PC と VirtualBox は変えない。物理キーボードは記号まで正しく出て、画面のキーボードは Shift で打つ記号だけが出ない | **採用** |
| VirtualBox のソフトキーボード | VM のウィンドウに出るキーをタップして打つ。画面のキーボードで出ない Shift の記号に使う | 併用 |
| Extension Pack の VRDE（VM の画面に直接 RDP でつなぐ） | Extension Pack が要る（ライセンスが PUEL。本書では扱わない） | 不採用 |
| PC の上で、Unicode の入力をスキャンコードに直す常駐 | VirtualBox のフックは、VM の画面にフォーカスが来るたびに入れ直されて先に呼ばれ、捕捉中は入力をそこで使ってしまう | 不採用 |
| VM の中の RDP サーバーに直接つなぐ（Windows のリモート デスクトップ、[gnome-remote-desktop](../gnome-remote-desktop.md)） | VM ごとに設定とネットワークの口が要る | 対象外（本書は PC の上の VirtualBox の窓を使う） |

- PC（RDP サーバー）の側で、クライアントに Unicode を使わせない設定は見つからなかった
- 設定は Windows App のすべての接続にかかる。PC の上のアプリでも、画面のキーボードの Shift の記号が出なくなる。Android の IME で日本語を打ちたいときは、オフに戻す

### 参照

- [Use keyboard, mouse, touch, and pen in Windows App — Microsoft Learn](https://learn.microsoft.com/en-us/windows-app/input-keyboard-mouse-touch-pen?tabs=android) — Android の「Keyboard modes」。「Use scancode input when available」と、スキャンコードのモードを使うアプリ（Qt のアプリなど）
- [Use features of the Remote Desktop client for Android and Chrome OS — Microsoft Learn](https://learn.microsoft.com/en-us/previous-versions/remote-desktop-client/client-features-android-chrome-os) — 前のアプリの文書。既定は Unicode で、IME は Unicode のモードでだけ使える
- [Input Capability Set (TS_INPUT_CAPABILITYSET) — MS-RDPBCGR](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-rdpbcgr/b3bc76ae-9ee5-454f-b197-ede845ca69cc) — `INPUT_FLAG_SCANCODES` と `INPUT_FLAG_UNICODE`
- [KEYBDINPUT structure — Microsoft Learn](https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-keybdinput) — `KEYEVENTF_UNICODE` のときの `wScan` と `VK_PACKET`
- [UIKeyboardHandler.cpp（VirtualBox 7.2.20）— GitHub](https://github.com/VirtualBox/virtualbox/blob/v7.2.20/src/VBox/Frontends/VirtualBox/src/runtime/UIKeyboardHandler.cpp) — 951〜957・1405〜1416・1574・1657 行
- [android rdp client keyboard not passing to hyper v — Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/838239/android-rdp-client-keyboard-not-passing-to-hyper-v) — Android の RDP から Windows の上の VirtualBox で `1` が `n`、`2` が `m`
- [Keyboard not working when connecting via rdp to run guest os's in virtualbox on win7 — Dell Community](https://www.dell.com/community/en/conversations/wyse-pocketcloud-for-android/keyboard-not-working-when-connecting-via-rdp-to-run-guest-oss-in-virtualbox-on-win7/647f5784f4ccf8a8de18b4a3) — `.` が `c`、`,` が `z`

