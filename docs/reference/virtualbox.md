# VirtualBox インストール手順（AlmaLinux 10 は Oracle 公式 dnf リポジトリ / Windows 11 は winget）の参考資料

[手順書](../virtualbox.md)

[検証記録](../verification/virtualbox.md#参考資料から分離した記録)

## 補足

### 実施手順 / 手順 4: 補足: repo ファイルは Oracle 公式のものとほぼ同じ

**repo ファイルは Oracle 公式のもの（`https://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo`）とほぼ同じ**。

- 変えたのは、`baseurl` の `http://` を `https://` にしたこと（同じホストが HTTPS でも応答する）と、`name` だけ
- `gpgcheck` / `repo_gpgcheck` / `gpgkey` は公式どおり
- `$releasever` は AlmaLinux 10 では `10` に展開されるので、`.../rpm/el/10/x86_64` を見に行く

### 実施手順 / 手順 7: 補足: 動いているカーネルを最新にしておく理由

`kernel-devel` は動いているカーネル（`uname -r`）と同じ版を入れ、モジュールもその版向けにビルドされる。更新済みのカーネルでまだ起動していないと、次の起動で新しいカーネル用のモジュールを作り直すことになる（[カーネルを更新したとき](../virtualbox.md#カーネルを更新したとき)）。

### Windows 11 で使う / 手順 4: 補足: winget のソースを限定する理由

- `--source winget` を付けた `winget list` は、入っているアプリを winget のカタログと照合し、確認に要らない Microsoft Store のソースの初回同意を避ける

### Windows 11 で使う / 手順 5: 補足: 管理者ではない窓で動かす理由

- 管理者の窓から起動したもの（`VBoxManage`・`VirtualBox.exe`）は、管理者の権限で動く。AlmaLinux 10 で VM を root ではなく自分のユーザーで動かすのと同じく、VM は自分のユーザーで動かす
- VirtualBox のマニュアルは、管理者の権限で動かした VirtualBox と、普通の権限で動くエクスプローラーの間では、ドラッグ＆ドロップができないと書いている
- VM と設定の場所（`%USERPROFILE%\VirtualBox VMs` と `%USERPROFILE%\.VirtualBox`）はユーザーごと。管理者の窓でも同じユーザーなので、場所は変わらない

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

