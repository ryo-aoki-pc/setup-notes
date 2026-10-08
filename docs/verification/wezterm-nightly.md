# WezTerm Nightly インストール手順（AlmaLinux 10 は公式 COPR の EL9 ビルドを流用 / Windows 11 は nightly のインストーラ）の検証記録

[手順書](../wezterm-nightly.md)

## 最新の確認範囲（Windows 11）

- 通したこと（どれも Windows 11 Pro の同じクリーン VM。実機ではない）
  - 2026-10-06〜07: Windows 節の手順 2・4・5 による新規導入、CLI の版と登録・PATH・ショートカット、CLI でのフォント解決とラスタ生成（[付録](#付録-windows-11-pro-の-vm-での導入検証2026-10-06)）
  - 2026-10-08: 手順 6 のスタートからの起動（この VM では OpenGL のエラーで開かず、`prefer_egl` で開いた）、「Open WezTerm here」の実クリックと HackGen Console NF の表示、更新（同じ版の入れ直し）、ロールバック（[付録](#付録-windows-11-pro-の-vm-での追加検証2026-10-08)）
- 確認していないこと
  - 3D の描画がある環境で、設定ファイル無しに手順 6 で窓が開くこと
  - 自分用の設定と Git Bash、Visual C++ Runtime の新規導入、新しい版に上がる更新、arm64 の Windows、Windows の実機
- 以降の既存記録は、各実施日・対象版・範囲に従う履歴として保持した

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順 / 手順 4: 本文中の記録

   - GNOME の端末から `wezterm` で確かめたなら、手順 5 は飛ばす

### 設定ファイル / 手順 0: 本文中の記録

- 置き場所は次の順で探し、**最初に見つかった 1 つだけ**を読む（[補足: 設定ファイルの探索順序](#設定ファイルの探索順序実測)）

### 設定ファイル / 手順 0: 本文中の記録

  - Windows 11 の探索順はソースと公式の文書で見ただけで、確かめていない（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）

### 設定ファイル / 手順 0: 本文中の記録

- この節の手順 1 は AlmaLinux 10 のもの（bash のブロック。Windows 11 では試していない）

### ロールバック / 手順 0: 本文中の記録

- ロールバックは、クリーンインストールの x86_64 VM で本実行した（2026-10-06。消えたのは手順 1 の 4 パッケージだけ）

### Windows 11 で使う: 検証状況の記録

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、配布物（インストーラの sha256・Inno Setup の版・署名の有無・中の実行ファイル）、インストーラの定義と作り方、Inno Setup の文書とソース、Linux の PowerShell 7 での構文と模擬の実行だけ（[対象と検証環境](#対象と検証環境)）。

### Windows 11 で使う / 手順 2: 補足: 確かめていること

- レジストリのキーは、WezTerm のインストーラ（Inno Setup）がアンインストールのために作る登録。名前の `{BCF6F0DA-…}` はインストーラの定義の `AppId` で、stable と nightly で同じ（winget の `wez.wezterm` と `wez.wezterm.nightly` の `ProductCode` も同じ値）。`DisplayVersion` が WezTerm の版
- WezTerm の実行ファイル（`wezterm.exe`・`wezterm-gui.exe`・`wezterm-mux-server.exe`）は `VCRUNTIME140.dll`（Visual C++ の再頒布可能パッケージ）を読み込むが、インストーラはこれを入れない（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）。無いと起動できないはず（確かめていない）
- `Get-Process` は、ほかのユーザーやセッションの WezTerm も数える

### Windows 11 で使う / 手順 3: 補足: winget の定義

- `Microsoft.VCRedist.2015+.x64` は、2026-10-03 の winget-pkgs で 14.51.36247.0。インストーラは Microsoft の `VC_redist.x64.exe`（`download.visualstudio.microsoft.com`）で、winget は定義の sha256 を確かめてから動かす。PC 全体に入る（`Scope: machine`）
- winget の `wez.wezterm.nightly` の定義も、これを依存に書いている（winget で入れると先にこれが入る。本書は winget で WezTerm を入れないので、ここで入れる）
- 定義は、終了コード 3010（再起動が要る）も成功として扱う
- Microsoft の文書では、x64 のパッケージには arm64 の分も入っている。arm64 の Windows では試していない

### Windows 11 で使う / 手順 4: 本文中の記録

   - `取れない` と `sha256 が一致しない` は、nightly が入れ替わる最中に取ったときにも出る（毎日の入れ替えは日本時間の昼ごろで、2026-10-03 は 13 時 13 分。main が変わったときにも入れ替わる）。少し待って貼り直す

### Windows 11 で使う / 手順 4: 補足: 確かめていることと、インストーラの引数

**sha256**

- `WezTerm-nightly-setup.exe.sha256` は、同じ nightly のリリースに置かれた sha256（`<64 桁>  WezTerm-nightly-setup.exe` の 1 行）。上流の CI が、ビルドしたファイルからリリースに上げる直前に作る（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
- 同じ場所から取るので、分かるのは壊れていないこと（途中で切れていない、入れ替えの最中のものではない）まで。インストーラにも中の `wezterm*.exe` にも Authenticode の署名は無く、本物かどうかは確かめられない（[注意点](../wezterm-nightly.md#注意点)）
- sha256 を先に、インストーラを後に取る。間で nightly が入れ替わると、一致せずに止まる
- `-ne` の比較は大文字と小文字を区別しない（`.sha256` は小文字、`Get-FileHash` は大文字）
- `curl.exe` は `C:\Windows\System32\curl.exe` を呼ぶ（[hackgen.md の Windows 11 で使う](../hackgen.md#windows-11-で使う)の手順 3 の補足と同じ）
- `curl.exe` で取ったファイルには「インターネットから来た」印（Mark of the Web）が付かないので、署名の無いインストーラでも SmartScreen の確認は出ないはず（確かめていない）

**インストーラの引数**（Inno Setup の標準の引数。WezTerm の公式の文書も、これで動かせると書いている）

- `/VERYSILENT`: 画面も進み具合の窓も出さない
- `/SUPPRESSMSGBOXES`: メッセージボックスを出さず、既定の答えで進む
- `/NORESTART`: 再起動しない
- `/NOCLOSEAPPLICATIONS`: 使っているファイルを持つアプリを閉じない。Inno Setup は、黙って動かすと既定では動いている WezTerm を閉じる（中の Claude Code なども止まる）。このブロックは WezTerm が動いていれば先に止まるので、念のため
- `/LOG="…"`: ログを `%TEMP%\wezterm-setup\setup.log` に書く（失敗したときに読む）
- 終了コードは 0 が成功で、0 以外は失敗（Inno Setup の文書）
- 管理者で入れる定義（`PrivilegesRequired` が既定の `admin`）。管理者の窓から動かすので、UAC の確認は出ないはず
- 定義の最後の「WezTerm を起動する」は `skipifsilent` なので、黙って入れたときは WezTerm を起動しない

**入るもの**（インストーラの定義 `ci/windows-installer.iss`）

- `C:\Program Files\WezTerm` に、`wezterm.exe`（CLI）・`wezterm-gui.exe`（窓）・`wezterm-mux-server.exe`・`strip-ansi-escapes.exe`・`conpty.dll` と `OpenConsole.exe`（Microsoft の署名付き）・`libEGL.dll` と `libGLESv2.dll`・`mesa\opengl32.dll`。アンインストーラの `unins000.exe` と `unins000.dat`
- PC 全体の `PATH`（`HKLM` の環境変数）の末尾に `C:\Program Files\WezTerm`
- スタートメニューの「WezTerm」（全ユーザー）。デスクトップのアイコンは既定で作らない
- エクスプローラーの右クリックの「Open WezTerm here」（フォルダー・フォルダーの背景・ドライブ。`HKLM\Software\Classes`）
- 前に入れた WezTerm があれば、同じ場所に上書きする（Inno Setup の既定の `UsePreviousAppDir`）
- シェル統合のスクリプトと補完は入らない（AlmaLinux 10 の RPM の `/etc/profile.d/wezterm.sh` に当たるものは無い）

### Windows 11 で使う / 手順 5: 補足: 版の読み方

- 版は、ビルドした日ではなく、もとにした main の最後のコミットの日時と、そのコミットの頭 8 桁（`<年月日>-<時分秒>-<コミット>`）
- nightly は毎日ビルドし直されるが、コミットの無い日は同じ版になる（2026-10-03 のビルドは `20260929-043349-cab25161`）
- `DisplayName` は `WezTerm <版>`（Inno Setup の既定の形）
- `UninstallString` は、[Windows 11 のロールバック](../wezterm-nightly.md#windows-11-のロールバック)の手順 1 が使う

### 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に [WezTerm](https://wezterm.org/) の nightly ビルドを入れる。AlmaLinux 10 では **dnf 管理で**入れ、以後は `dnf upgrade` で追従できるようにする
- **進め方**: どちらも**読者が書き換える変数は無い**
  - **AlmaLinux 10**（[実施手順](../wezterm-nightly.md#実施手順)）: 作者が管理する公式 COPR `wezfurlong/wezterm-nightly` には **EL10 向けのビルドが無い**ので、chroot を `rhel-9-<arch>` と明示して有効化し、EL9 向けビルドをそのまま入れる（chroot は `uname -m` から自動で決まる）
  - **Windows 11**（[Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)）: GitHub の `nightly` のリリースの `WezTerm-nightly-setup.exe`（Inno Setup）を、同じリリースの `.sha256` と比べてから黙って動かし、`C:\Program Files\WezTerm` に入れる。管理者の Windows PowerShell 5.1 に貼る。更新は同じブロックを貼り直す
    - [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)が `C:\Program Files\WezTerm\wezterm.exe` を呼ぶので、その場所に入れる
    - [Windows 11 の初期設定](../windows-setup.md)の後に通す手順書の 1 つ
  - 設定ファイルは `~/.wezterm.lua` か `~/.config/wezterm/wezterm.lua`（Windows 11 では `%USERPROFILE%` の下。[設定ファイル](../wezterm-nightly.md#設定ファイル)）
- **状態（AlmaLinux 10）**: **x86_64 の実機（2026-09-21）とクリーンインストールの VM（2026-10-06）で本実行済み**。VM は実施手順 1〜5・CLI と GUI の起動・ロールバックを確認した
  - 2026-10-06: 別の新規 VM で現行手順を再検証した。今回の実施・解除・未実施範囲は[新しい付録](#付録-現行版の新規-vm-での再検証2026-10-06)に記録した
  - 確認したこと: ウィンドウの起動・終了まで
  - **aarch64 は未検証**（COPR に `rhel-9-aarch64` はあるので、同じ手順で通る見込み）
  - EL9 向けビルドを EL10 で使う非公式な流用なので、更新で壊れたら[補足: 注意点](../wezterm-nightly.md#注意点)を見る
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - 利用者の PC には、nightly の `20260905-153129-092dcf70` が `C:\Program Files\WezTerm` に入っている（[Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)の実機の記録。入れ方の記録は無い）。その PC では、[Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の手順は上書きになる
  - **確かめたこと**（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）:
    - 配布物: 2026-10-03 の `WezTerm-nightly-setup.exe` の sha256 と `.sha256` の一致、Inno Setup 6.7.0 で作られていること、Authenticode の署名が無いこと。同じ日の zip の中の実行ファイルが x64 で、`VCRUNTIME140.dll` を読み込むこと
    - インストーラの定義（`ci/windows-installer.iss`）と作り方（`ci/deploy.sh`・`gen_windows_continuous.yml`）、Inno Setup の文書とソース（引数・終了コード・アンインストールの登録・アンインストーラの動き）、WezTerm のソース（Windows の設定ファイルの探索順、更新の確認）
    - ほかの経路: winget の `wez.wezterm.nightly`（定義の sha256 の直され方）・`wez.wezterm`・`Microsoft.VCRedist.2015+.x64`、scoop の `versions/wezterm-nightly`・`extras/wezterm`、Chocolatey の `wezterm`
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。[Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の手順 4 と[Windows 11 のロールバック](../wezterm-nightly.md#windows-11-のロールバック)の手順 1 のブロックは、Linux の pwsh で偽物のインストーラとレジストリを使って流した（[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
  - **確かめていないこと**: Windows で貼ること（すべての手順）、インストーラが黙って入ることと、`PATH`・スタートメニュー・右クリックのメニュー、`VCRUNTIME140.dll` の無い PC と[Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の手順 3、WezTerm の窓が開くこと、更新（上書き）とアンインストール、arm64 の Windows

AlmaLinux 10 の実機:

| 項目 | 値 |
|---|---|
| 実施日 | 2026-09-21 |
| OS | AlmaLinux 10.2 (Lavender Lion) / x86_64 |
| カーネル | 6.12.0-211.56.1.el10_2 |
| dnf / dnf-plugins-core | 4.20.0 / 4.7.0-10.el10（`dnf copr` サブコマンド） |
| glibc / openssl-libs | 2.39-128.el10_2 / 3.5.8-1.el10_2 |
| デスクトップ | GNOME Shell 49.4 / Wayland セッション |
| 入った WezTerm | `wezterm-20260921_051727_5eb03b23-0.x86_64`（COPR `rhel-9-x86_64` ビルド） |
| SELinux | Enforcing |

Windows 11 の手順が前提にしている環境（ほかの Windows の手順書の実機の記録と同じ PC を想定）:

| 項目 | 値 |
|---|---|
| OS | Windows 11（[Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)の PC は 26H2）。x64 |
| PowerShell | Windows PowerShell 5.1（管理者として実行） |
| ユーザー | Administrators の一員 |
| 今の WezTerm | nightly の `20260905-153129-092dcf70`（`C:\Program Files\WezTerm`） |
| 入る WezTerm | 2026-10-03 の nightly は `20260929-043349-cab25161`（`WezTerm-nightly-setup.exe`、45,473,308 バイト） |

> [!NOTE]
> 出力例の値は `<HOSTNAME>` / `<USER>`（AlmaLinux 10）/ `<WIN_USER>`（Windows のユーザー名）のプレースホルダで書いてある。版（AlmaLinux 10 の `20260921_051727_5eb03b23`、Windows 11 の `20260929-043349-cab25161`）は実行日によって変わる。Windows 11 の節にも変数は無い（入れる先・URL はブロックに直接書いてある）。

手順書全体に関わる理由・実測・落とし穴と調査記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

AlmaLinux 10 の実機（2026-09-21）。Windows 11 の PC は、[Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の手順 2 で確かめる。

| 項目 | 状態 |
|---|---|
| WezTerm | 未導入（`rpm -q wezterm` → not installed。`~/.config/wezterm` / `~/.wezterm.lua` も無し） |
| 有効な追加リポジトリ | epel、crb、COPR 2 件（lazygit / yazi。どちらも `epel-10-$basearch` chroot）、mozilla、gh-cli、claude-code |
| `dnf copr` | `dnf-plugins-core-4.7.0-10.el10` で使える |
| Flatpak | 導入済み、flathub あり（今回は使わない） |
| FUSE2 | `fuse-libs-2.9.9-25.el10`（`/usr/lib64/libfuse.so.2`）あり。AppImage を直接実行できる |
| 依存ライブラリ | `libxcb` 1.17 / `libxkbcommon(-x11)` 1.7 / `libwayland-client` 1.24 / `fontconfig` 2.15 / `mesa-libEGL` 25.2 / `openssl-libs` 3.5.8 — すべて導入済み |
| セッション | `loginctl show-session` → `Type=wayland`、`XDG_CURRENT_DESKTOP=GNOME` |

### 選択した方針

WezTerm の nightly を Linux に入れる経路は 6 つある。EL10 で使えるかを調べた結果（2026-09-21。Homebrew の行は 2026-10-03）:

| 経路 | EL10 での状況 | 採否 |
|---|---|---|
| **公式 COPR `wezfurlong/wezterm-nightly`** | chroot は `rhel-8` / `rhel-9` / `centos-stream-9` / `fedora-42〜45` / `rawhide` / `opensuse-tumbleweed`（各 x86_64 / aarch64）。**`epel-10` / `rhel-10` は無い**。ただし EL9 向けビルドの依存関係は EL10 ですべて満たせる（下記） | **採用**（chroot を `rhel-9-<arch>` と明示） |
| GitHub Releases の `nightly` タグ | `wezterm-{common,gui,mux-server}-nightly-centos9.rpm` が毎日更新される。EL10 向けは無い。手で `dnf install ./*.rpm` する形になり、更新が自動化されない | 不採用（COPR と同じ EL9 ビルドで、管理面で劣る） |
| AppImage | `WezTerm-nightly-Ubuntu24.04.AppImage` は EL10 で動く（[付録](#付録-appimage-の実測)）。ただし更新が止まりがち（2026-08-02 版）で、最新の `Ubuntu26.04` 版は **glibc 2.42 以上を要求して EL10（2.39）では起動しない** | 不採用（dnf で管理できず、最新版が動かない） |
| Flathub `org.wezfurlong.wezterm` | stable のみ。nightly は無い | 不採用 |
| Homebrew の公式 tap `wezterm/wezterm-linuxbrew` | formula は AppImage を `bin/wezterm` に置くだけ。stable は `20240203-110809-5046fc22`、nightly（`--HEAD`）は `WezTerm-nightly-Ubuntu20.04.AppImage` で、2026-03-18 から更新されていない。aarch64 の AppImage は無い（[補足](../reference/wezterm-nightly.md#homebrew-の-tap-を採らない理由)） | 不採用（nightly が古く、aarch64 に無い） |
| ソースビルド（`cargo build --release`） | 可能だが Rust toolchain と `get-deps` の依存パッケージが要り、更新のたびにビルドする | 不採用 |

**EL9 向けビルドが EL10 で通る根拠**: 実行前に `--assumeno` で依存解決だけ試した。

- COPR を brew に置き換えられないかを、2026-10-03 に調べた。tap の formula と配布物の日付を見ただけで、入れてはいない
- Homebrew の `wezterm` は macOS だけの cask（`wezterm@nightly` も同じ）なので、Linux では公式の tap の formula を名前を全部書いて入れる（`brew install wezterm/wezterm-linuxbrew/wezterm`、nightly は `--HEAD`）
- tap の `Formula/wezterm.rb` は、AppImage を 1 つ落として `bin/wezterm` に置くだけ（`bin.install img => "wezterm"`）
  - stable は `20240203-110809-5046fc22`（tap の最後の更新も 2024-02-03）。自分用の設定は nightly が前提
  - `--HEAD` は `WezTerm-nightly-Ubuntu20.04.AppImage` を指す。GitHub の `nightly` の配布物で、この AppImage の `Last-Modified` は 2026-03-18 だった（`wezterm-gui-nightly-centos9.rpm` は 2026-10-03）
  - COPR の `rhel-9-x86_64` と `rhel-9-aarch64` は、どちらも 2026-10-02 にメタデータが更新されていた（`repomd.xml` の `revision`）
  - nightly の AppImage に aarch64 のものは無い（`*-aarch64.AppImage` は 404）
  - `.desktop` とアイコン、`wezterm-mux-server`、`/etc/profile.d/wezterm.sh` のシェル統合、補完は入らない。AppImage なので FUSE2 も要る（[付録](#付録-appimage-の実測)）
  - nightly の更新は `brew upgrade` に乗らず、入れ直す（公式ドキュメント）

Windows 11 で WezTerm の nightly を入れる経路を比べた（2026-10-03 時点。[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **GitHub の `nightly` の `WezTerm-nightly-setup.exe`** | Inno Setup のインストーラ。同じリリースに `.sha256` がある。`C:\Program Files\WezTerm` に入れ、PC 全体の `PATH`・スタートメニュー・右クリックのメニュー・アンインストールの登録を作る。管理者が要る。Authenticode の署名は無い。更新は手作業（同じブロックを貼り直す） | **採用** |
| winget の `wez.wezterm.nightly` | ある（`20260929-043349-cab25161`、Inno Setup、`machine`、依存に `Microsoft.VCRedist.2015+.x64`）。中身は同じ URL のインストーラで、定義の sha256 は winget の bot が 1〜11 日おきに直す。インストーラは毎日作り直されて sha256 が変わるので、直されていない日は一致せずに入らない（2026-09-21 から 10-02 までは直されていなかった） | 不採用（入るかどうかが日による） |
| winget の `wez.wezterm` | stable の `20240203-110809-5046fc22`（2024-02-03）。WezTerm の公式の文書が案内しているのはこれ | 不採用（自分用の設定は nightly が前提） |
| scoop の `versions/wezterm-nightly` | ある（版は `nightly`）。nightly の zip を `~\scoop\apps\wezterm-nightly\current` に展開する。scoop は nightly の版の sha256 を確かめない（`Downloaded files won't be verified.`）。`current` はジャンクションで、SSH のセッションからはたどれない（[Windows の OpenSSH サーバーの scoop のツールを SSH のセッションで使う（任意）](../windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)） | 不採用（`C:\Program Files\WezTerm` に入らず、確かめられない） |
| scoop の `extras/wezterm`・Chocolatey の `wezterm` | どちらも stable の `20240203-110809-5046fc22`。Chocolatey に nightly は無い | 不採用 |
| nightly の zip（`WezTerm-windows-nightly.zip`） | インストーラと同じ実行ファイル（と `wezterm.pdb`）。どこに展開してもよく、管理者が要らない。`PATH`・スタートメニュー・アンインストールは自分で用意する | 不採用（`C:\Program Files\WezTerm` に置くなら、インストーラと同じことを手で行うことになる） |

### 完了時点の状態

AlmaLinux 10 の実機の出力（Windows 11 では流していない。Windows 11 で入るものは、[Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の手順 4 の補足）:

```
$ rpm -q wezterm wezterm-common wezterm-gui wezterm-mux-server
wezterm-20260921_051727_5eb03b23-0.x86_64
wezterm-common-20260921_051727_5eb03b23-0.x86_64
wezterm-gui-20260921_051727_5eb03b23-0.x86_64
wezterm-mux-server-20260921_051727_5eb03b23-0.x86_64
$ dnf -q repoquery --installed --qf '%{name} %{from_repo}\n' 'wezterm*'
wezterm copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly
wezterm-common copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly
wezterm-gui copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly
wezterm-mux-server copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly
$ wezterm --version
wezterm 20260921_051727_5eb03b23
$ wezterm-mux-server --version
wezterm-mux-server 20260921_051727_5eb03b23
$ ldd /usr/bin/wezterm-gui /usr/bin/wezterm /usr/bin/wezterm-mux-server | grep -c 'not found'
0
$ sudo dnf copr list
copr.fedorainfracloud.org/dejan/lazygit
copr.fedorainfracloud.org/lihaohong/yazi
copr.fedorainfracloud.org/wezfurlong/wezterm-nightly
```

`rpm -qi wezterm-gui` の `Build Date` は `Mon 21 Sep 2026 02:21:39 PM JST`、`Vendor` は `Fedora Copr - user wezfurlong`、`Packager` は `Wez Furlong`。

入るファイル（主なもの）:

| パッケージ | ファイル |
|---|---|
| `wezterm-common` | `/usr/bin/wezterm`、`/usr/bin/strip-ansi-escapes`、`/etc/profile.d/wezterm.sh`（bash / zsh のシェル統合。OSC 7 / OSC 133 / user var を出す）、`/etc/bash_completion.d/wezterm`、`/usr/share/zsh/site-functions/_wezterm` |
| `wezterm-gui` | `/usr/bin/wezterm-gui`、`/usr/bin/open-wezterm-here`、`/usr/share/applications/org.wezfurlong.wezterm.desktop`（`Exec=wezterm start --cwd .`）、`/usr/share/icons/hicolor/128x128/apps/org.wezfurlong.wezterm.png`、`/usr/share/nautilus-python/extensions/wezterm-nautilus.py`（`nautilus-python` が無いので効かない） |
| `wezterm-mux-server` | `/usr/bin/wezterm-mux-server` |

### 設定ファイルの探索順序（実測）

- 一時ディレクトリを `HOME` にして候補ファイルを組み合わせ、`wezterm ls-fonts` の `Primary font` にどのファイルの `font` が出るかで判定した（実際のホームには何も置いていない）
- `strace -f -o ... wezterm ls-fonts` で `wezterm.lua` を含む `openat` を拾うと、試した順番もわかる

| 置いたファイル | 読まれたもの |
|---|---|
| `~/.config/wezterm/wezterm.lua` のみ | それ |
| `~/.config/wezterm/wezterm.lua` + `~/.wezterm.lua` | **`~/.wezterm.lua`**（`.config` 側は `openat` すらされない） |
| `~/.config/wezterm/wezterm.lua` + `${XDG_CONFIG_HOME}/wezterm/wezterm.lua` | **`XDG_CONFIG_HOME` 側**（`~/.config` 側は試されない） |
| 上 2 つ + `~/.wezterm.lua` | `~/.wezterm.lua` |
| + 環境変数 `WEZTERM_CONFIG_FILE` | その環境変数のファイル |
| + `--config-file` | その引数のファイル |
| 何も無し / `-n` | 組み込み既定値（`JetBrains Mono`） |
| `~/.wezterm.lua` が文法エラー | `ERROR ... syntax error` を出して組み込み既定値 |

`strace` の抜粋（`~/.wezterm.lua` が無く、`XDG_CONFIG_HOME` を設定した場合）:

```
"$HOME/.wezterm.lua", O_RDONLY|O_CLOEXEC) = -1
"$XDG_CONFIG_HOME/wezterm/wezterm.lua", O_RDONLY|O_CLOEXEC) = 3
```

**公式ドキュメントのフロー図とは順序が逆**。

- [Configuration Files](https://wezterm.org/config/files.html) の図は、`$XDG_CONFIG_HOME/wezterm/wezterm.lua` → `~/.config/wezterm/wezterm.lua` → `~/.wezterm.lua` の順に見える
- `main` ブランチの `config/src/config.rs`（`load_with_overrides`）は、`~/.wezterm.lua` を先頭に置き、その後に `CONFIG_DIRS`（`XDG_CONFIG_HOME` があればそれ、無ければ `~/.config`）を並べている
- 両方に置いてある環境で「`.config` 側を直したのに反映されない」ときは、これが原因

### 注意点 / 手順 0: 本文中の記録

- **Windows 11 の実行ファイルは x64 だけ**: インストーラの定義は arm64 の Windows も許す（x64 のエミュレーションで動かす）が、本書では試していない

### 参照

- [Linux — WezTerm Install](https://wezterm.org/install/linux.html) — 「Installing on Fedora and rpm-based Systems via Copr」と、openSUSE 節の `dnf copr enable wezfurlong/wezterm-nightly <repository>` の形
- [wezfurlong/wezterm-nightly — Copr](https://copr.fedorainfracloud.org/coprs/wezfurlong/wezterm-nightly/) — 対応 chroot の一覧
- [wezterm/wezterm Releases: nightly](https://github.com/wezterm/wezterm/releases/tag/nightly) — centos9 rpm / AppImage / deb
- [dnf-copr(8)](https://dnf-plugins-core.readthedocs.io/en/latest/copr.html) — `enable name/project [chroot]`
- [wezterm/homebrew-wezterm-linuxbrew](https://github.com/wezterm/homebrew-wezterm-linuxbrew) — Homebrew の公式 tap（`Formula/wezterm.rb`）。導入のコマンドは [Linux — WezTerm Install](https://wezterm.org/install/linux.html) の Linuxbrew の節
- [Configuration Files — WezTerm](https://wezterm.org/config/files.html) — 設定ファイルの探索順序（本書の実測とは `~/.wezterm.lua` の優先度が異なる）
- [wezterm/wezterm config/src/config.rs `load_with_overrides`](https://github.com/wezterm/wezterm/blob/main/config/src/config.rs) — 実際の探索順序
- [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm) — 自分用の設定。導入の手順は `docs/install.md`、変える場所は README にある
- [Windows — WezTerm Install](https://wezterm.org/install/windows.html) — Windows のインストーラ（Inno Setup、Program Files と `PATH`）・zip・winget・scoop・Chocolatey
- [wezterm/wezterm ci/windows-installer.iss](https://github.com/wezterm/wezterm/blob/main/ci/windows-installer.iss) — Windows のインストーラの定義（`AppId`・入れる先・`PATH`・右クリックのメニュー）
- [wezterm/wezterm .github/workflows/gen_windows_continuous.yml](https://github.com/wezterm/wezterm/blob/main/.github/workflows/gen_windows_continuous.yml) — nightly の Windows 版のビルドと `.sha256` の作り方
- [Setup Command-Line Parameters — Inno Setup](https://jrsoftware.org/ishelp/topic_setupcmdline.htm) / [Setup Exit Codes](https://jrsoftware.org/ishelp/topic_setupexitcodes.htm) / [Uninstaller Command-Line Parameters](https://jrsoftware.org/ishelp/topic_uninstcmdline.htm) / [Uninstaller Exit Codes](https://jrsoftware.org/ishelp/topic_uninstexitcodes.htm) / [CloseApplications](https://jrsoftware.org/ishelp/topic_setup_closeapplications.htm) — インストーラとアンインストーラの引数と動き
- [Latest supported Visual C++ Redistributable downloads — Microsoft Learn](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist) — `VCRUNTIME140.dll` を入れる再頒布可能パッケージ
- [microsoft/winget-pkgs の wez.wezterm.nightly](https://github.com/microsoft/winget-pkgs/tree/master/manifests/w/wez/wezterm/nightly) — 採らなかった winget の定義
- [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md) — `C:\Program Files\WezTerm\wezterm.exe` を使う手順書
- [Windows 11 の初期設定](../windows-setup.md) — 貼り付けの設定（手順 16〜19）と、この文書を通す順

### 付録: AppImage の実測

採用しなかった経路の記録。GitHub Releases の `nightly` から 2 つの AppImage を `/tmp` に取得し、`--version` だけ実行した（実行後に削除）。

| ファイル | 更新日 | 結果 |
|---|---|---|
| `WezTerm-nightly-Ubuntu24.04.AppImage`（47 MB） | 2026-08-02 | `wezterm 20260802-174340-fa0a1da0`、rc=0 |
| `WezTerm-nightly-Ubuntu26.04.AppImage`（49 MB） | 2026-09-21 | 起動せず、rc=1: `/lib64/libc.so.6: version 'GLIBC_2.42' not found` / `/lib64/libm.so.6: version 'GLIBC_2.43' not found` |

AppImage は「ビルドした Ubuntu の glibc 以上」を要求する。EL10 の glibc は 2.39 なので、Ubuntu 24.04（glibc 2.39）版までしか動かない。その 24.04 版は 1 か月半更新されておらず、この日の COPR ビルド（`20260921`）より古い。FUSE2 が無い環境では `--appimage-extract` で展開して `squashfs-root/AppRun` を実行する。

---

### 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物とソースと資料を読んだ記録。

#### nightly のリリースのファイル

GitHub の `nightly` のリリースの Windows のファイルは 4 つ（`.asc`・`.sig`・`.sha512` は 404）:

| ファイル | 大きさ | `Last-Modified` |
|---|---|---|
| `WezTerm-nightly-setup.exe` | 45,473,308 バイト | 2026-10-03 04:13:07 UTC |
| `WezTerm-nightly-setup.exe.sha256` | 92 バイト | 2026-10-03 04:13:06 UTC |
| `WezTerm-windows-nightly.zip` | 70,856,196 バイト | 2026-10-03 04:13:08 UTC |
| `WezTerm-windows-nightly.zip.sha256` | 94 バイト | 2026-10-03 04:13:06 UTC |

```
$ cat WezTerm-nightly-setup.exe.sha256
1e52712f6111c3583e37eabeeef6c8d2896fe67ec8ce1ef38585e65ca01a923c  WezTerm-nightly-setup.exe
$ sha256sum WezTerm-nightly-setup.exe
1e52712f6111c3583e37eabeeef6c8d2896fe67ec8ce1ef38585e65ca01a923c  WezTerm-nightly-setup.exe
$ strings -n 8 WezTerm-nightly-setup.exe | grep 'Inno Setup' | sort -u
Inno Setup Messages (6.5.0) (u)
Inno Setup Setup Data (6.7.0)
```

- `.sha256` の改行は LF だけで、ハッシュとファイル名の間は空白 2 つ（`sha256sum` の形）
- インストーラは 32 ビットの PE（Inno Setup の起動部）で、PE の証明書テーブル（Authenticode の署名）は大きさ 0。署名は無い
- innoextract 1.9（Ubuntu 24.04 の）は、Inno Setup 6.7 の中身を読めなかった（`Could not determine setup data version!`）。入るファイルは、下のインストーラの定義と zip で見た

zip の中（版のフォルダー名が `20260929-043349-cab25161`。`git ls-remote` の main の先頭も `cab25161…` だった）:

```
WezTerm-windows-20260929-043349-cab25161/conpty.dll
WezTerm-windows-20260929-043349-cab25161/libEGL.dll
WezTerm-windows-20260929-043349-cab25161/libGLESv2.dll
WezTerm-windows-20260929-043349-cab25161/mesa/opengl32.dll
WezTerm-windows-20260929-043349-cab25161/OpenConsole.exe
WezTerm-windows-20260929-043349-cab25161/strip-ansi-escapes.exe
WezTerm-windows-20260929-043349-cab25161/wezterm-gui.exe
WezTerm-windows-20260929-043349-cab25161/wezterm-mux-server.exe
WezTerm-windows-20260929-043349-cab25161/wezterm.exe
WezTerm-windows-20260929-043349-cab25161/wezterm.pdb
```

PE を pefile で読んだ結果:

- どれも x64（`Machine` が `0x8664`）。arm64 のものは無い
- 証明書テーブルがあるのは `conpty.dll` と `OpenConsole.exe`（Microsoft のもの）だけで、`wezterm*.exe`・`strip-ansi-escapes.exe`・`libEGL.dll`・`libGLESv2.dll`・`mesa\opengl32.dll` には無い
- `wezterm.exe`・`wezterm-gui.exe`・`wezterm-mux-server.exe`・`strip-ansi-escapes.exe` の読み込むものに `VCRUNTIME140.dll` がある（ほかは `api-ms-win-crt-*`。Windows に入っている UCRT）

#### インストーラの定義と作り方（main の 2026-10-03 の時点）

`ci/windows-installer.iss`:

- `AppId={{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}`、`DefaultDirName={autopf}\WezTerm`、`ArchitecturesAllowed=x64 arm64`、`ArchitecturesInstallIn64BitMode=x64 arm64`、`MinVersion=10.0.17763`、`ChangesEnvironment=true`
- `PrivilegesRequired=lowest` はコメントにしてあり、既定の `admin`（管理者で入れ、`{autopf}` は `C:\Program Files`）
- `[Tasks]` の `desktopicon` は `Flags: unchecked`。`[Icons]` は `{autoprograms}\WezTerm`（`AppUserModelID: "org.wezfurlong.wezterm"`）
- `[Run]` の `wezterm-gui.exe` の起動は `Flags: nowait postinstall skipifsilent`
- `[Registry]` は `HKA` の `Software\Classes\{Drive,Directory\Background,Directory}\shell\Open WezTerm here`（`uninsdeletekey`）
- `[Code]` の `CurStepChanged(ssPostInstall)` が `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment` の `Path` の末尾に `{app}` を足し、`CurUninstallStepChanged(usPostUninstall)` が消す。`InitializeSetup` で、arm64 の Windows では x64 のエミュレーションがあるかを確かめる
- `[Files]` に Visual C++ の再頒布可能パッケージは無い

`ci/deploy.sh` と `.github/workflows/gen_windows_continuous.yml`:

- 毎日 03:10 UTC（と、main の Rust のファイルなどが変わったとき）に `windows-2025` でビルドし、`BUILD_REASON=Schedule` のときファイル名を `WezTerm-windows-nightly.zip`・`WezTerm-nightly-setup` にする。版（`MyAppVersion`）は `git show -s --format=%cd-%h --date=format:%Y%m%d-%H%M%S`（`core.abbrev=8`）
- 別のジョブ（`ubuntu-latest`）が、ビルドのファイルを受け取って `sha256sum $f > $f.sha256` で `.sha256` を作り、`gh release upload --clobber nightly` で上げる
- Windows の版に署名の手順は無い（`codesign` があるのは macOS の版だけ）

#### Inno Setup（文書と、`jrsoftware/issrc` の 2026-10-03 のソース）

- 黙って動かす引数: `/VERYSILENT`・`/SUPPRESSMSGBOXES`・`/NORESTART`・`/NOCLOSEAPPLICATIONS`・`/LOG="filename"`。終了コードは 0 が成功、1〜8 が失敗の種類
- `CloseApplications` の既定は `yes` で、黙って動かしているときは「使用中のファイルを持つアプリを、コマンドラインで止められない限りいつも閉じて起動し直す」
- アンインストールの登録（`Setup.Install.pas`）: `DisplayName`（`AppVerName` が無ければ `<AppName> <AppVersion>`）・`DisplayVersion`・`InstallLocation`・`UninstallString`（`"<…>\unins000.exe"`）・`QuietUninstallString`（同じものに ` /SILENT`）。キーの名前は `<AppId>_is1`
- アンインストーラ（`unins???.exe`、既定の置き場所は `{app}`）は `/VERYSILENT`・`/SUPPRESSMSGBOXES`・`/NORESTART` を受け付け、`%TEMP%` に自分の写しを作って、写しが消す。「終了コードを受け取った時点では、アンインストールの処理がまだ動いていることがある」

#### winget・scoop・Chocolatey

- winget の `wez.wezterm.nightly`（`manifests/w/wez/wezterm/nightly/`）: `20260929-043349-cab25161` と `20260917-114457-b09b56c2` の 2 つ。どちらも `InstallerUrl` は `…/releases/download/nightly/WezTerm-nightly-setup.exe`、`InstallerType: inno`、`Scope: machine`、`ProductCode: '{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1'`、依存は `Microsoft.VCRedist.2015+.x64`
  - `20260929-043349-cab25161` の `InstallerSha256` は、2026-10-02 06:51 UTC のコミットで `6438C905…DA474`、2026-10-03 06:02 UTC のコミットで `1E52712F…A923C`（この日のインストーラと同じ）に変わった。同じ版でも、ビルドのたびに sha256 が変わる
  - `20260917-114457-b09b56c2` の `InstallerSha256` は `513C4271…530EA` のまま（同じ URL の今のファイルとは合わない）
  - コミットの履歴（2026-08-21〜10-03）では、bot の更新は 1〜11 日おきで、毎日ではない（2026-09-21 の次は 10-02）
- winget の `wez.wezterm`: 最新は `20240203-110809-5046fc22`。`ProductCode` は nightly と同じ
- winget の `Microsoft.VCRedist.2015+.x64`: 最新は `14.51.36247.0`（`InstallerType: burn`、`Scope: machine`、`InstallerSuccessCodes: 3010`）
- scoop の `versions/wezterm-nightly`: `"version": "nightly"`、`url` は `…/releases/download/nightly/WezTerm-windows-nightly.zip`、`hash` は無い。scoop の `lib/install.ps1` は、版が `nightly` のとき `This is a nightly version. Downloaded files won't be verified.` と出して確かめない
- scoop の `extras/wezterm`: `20240203-110809-5046fc22`
- Chocolatey の `wezterm`: `20240203.110809.0`。`wezterm-nightly` は無い

#### WezTerm のソース（main）

- `config/src/config.rs` の `load_with_overrides`: `~/.wezterm.lua` → `CONFIG_DIRS` の `wezterm.lua` の順に並べ、Windows だけ `current_exe()` のフォルダーの `wezterm.lua` を先頭に入れ、その前に `WEZTERM_CONFIG_FILE`、さらに前に `--config-file`。`HOME_DIR` は `dirs_next::home_dir()`（Windows では `%USERPROFILE%`）、`CONFIG_DIRS` は `XDG_CONFIG_HOME` があれば `<それ>\wezterm`、無ければ `<HOME>\.config\wezterm`
- 作業用のフォルダー: `RUNTIME_DIR` は `dirs_next::runtime_dir()` が無い Windows では `<HOME>\.local\share\wezterm`、`DATA_DIR` は `dirs_next::data_dir()`（`%APPDATA%`）の `wezterm`、`CACHE_DIR` は `dirs_next::cache_dir()`（`%LOCALAPPDATA%`）の `wezterm`
- `wezterm-gui/src/update.rs`: 更新の確認は `releases/latest`（stable）の `tag_name` と今の版を文字列で比べ、新しいときだけ知らせる
- 公式の文書（`docs/install/windows.md`）: インストーラは Inno Setup で、Program Files に入れて `PATH` に登録する。Inno Setup の標準の引数で動かせる。nightly の setup.exe と zip へのリンクがある。winget・scoop・Chocolatey の案内は stable（`wez.wezterm`・`extras/wezterm`・`wezterm`）
- 公式の文書（`docs/config/launch.md`）: Windows で `default_prog` が無いときは `%COMSPEC%`、無ければ `cmd.exe`

---

### 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-03）

Linux（クラウドのコンテナ）の PowerShell 7.6.6 と PSScriptAnalyzer 1.25.0 で確かめた。

**構文と Windows PowerShell 5.1 との互換**:

- Windows 11 の 3 節の `powershell` のブロック 6 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）と、既定の規則を当てた。指摘は 0

**[Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の手順 4 のブロック**を、パスの `\` を `/` に替え、`$env:WINDIR`・`$env:TEMP`・`C:\Program Files\WezTerm` を一時的なディレクトリにして流した。`System32/curl.exe` は Linux の `curl` を呼ぶ小さなスクリプト（失敗・壊れたファイル・中身の違う `.sha256` を作れる）、`Get-Process` と `Start-Process` は偽物（`Start-Process` は引数を出し、`wezterm.exe` の代わりに版を出すスクリプトを置く）、管理者の判定は値に置き換えた:

- 通常: 本物の `.sha256` とインストーラを取り、sha256 が一致し、`Start-Process` に `-FilePath <一時フォルダー>/WezTerm-nightly-setup.exe` と `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCLOSEAPPLICATIONS /LOG="<一時フォルダー>/setup.log"` が渡った。`WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0` と `wezterm 20260929-043349-cab25161` が出て、一時フォルダーが消えた
- 管理者でない・`vcruntime140.dll` が無い・WezTerm が動いている: それぞれの `中断:` で止まり、何も取らなかった
- `curl` の失敗: `中断: WezTerm-nightly-setup.exe.sha256 を取れない`
- 取ったインストーラに 1 バイト足したもの: `中断: WezTerm-nightly-setup.exe の sha256 が一致しない`（`Start-Process` は呼ばれず、取ったものは一時フォルダーに残った）
- `.sha256` の中身が `Not Found`: `中断: WezTerm-nightly-setup.exe.sha256 に sha256 の行が無い`
- インストーラの終了コードが 4: `中断: インストーラが終了コード 4 で終わった（ログは <一時フォルダー>/setup.log）`

**[Windows 11 のロールバック](../wezterm-nightly.md#windows-11-のロールバック)の手順 1 のブロック**を、`C:\Program Files\WezTerm` を一時的なディレクトリにして流した。`Get-ItemProperty`・`Test-Path`（登録のキーだけ）・`Get-Process`・`Start-Process` を偽物にし、`Start-Process` は 3 秒後に登録とフォルダーを消す（アンインストーラの写しが後から消すのをまねる）:

- 通常: `Start-Process` に `-FilePath C:\Program Files\WezTerm\unins000.exe`（`UninstallString` の引用符の中）と `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART` が渡り、3 秒待ってから `False` が 2 行出た
- 登録が無い・`UninstallString` が別の形（`MsiExec.exe /X{0000}`）・WezTerm が動いている・アンインストーラの終了コードが 1: それぞれの `中断:` で止まった
- フォルダーに `wezterm.lua` が残るとき: 60 秒待ってから `False` と `True` が出た

[Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の手順 2 のブロックも、管理者の判定を値に置き換えて流し、`VCRuntime` が偽物の `vcruntime140.dll` の有無で `True` と `False` になることを見た。

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. インストーラが黙って入り、`PATH`・スタートメニュー・右クリックのメニュー・アンインストールの登録ができること。前の版が入っている PC で上書きできること
1. `VCRUNTIME140.dll` の無い PC で WezTerm が起動しないことと、[Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の手順 3 で起動するようになること
1. スタートメニューから起動した WezTerm の窓と、自分用の設定での Git Bash
1. アンインストーラが黙って消すこと
1. arm64 の Windows

### 付録: クリーンインストールした VM での検証（2026-10-06）

AlmaLinux 10.2 Workstation を新規に入れた x86_64 の VirtualBox VM（1 vCPU、メモリ 6 GiB、SELinux Enforcing、日本語 UI、US 配列）で確認した。シェルのブロックは手順書から抜き出して、検証用ユーザーの SSH の対話シェルへ個別に貼った。GUI はヘッドレスの GNOME に 1920x1080 の仮想モニターを付け、既存の `scripts/gnome-gui.py` を変更せずコピーして、操作の後に撮った PNG を見た。利用者のアカウントは使っていない。

実施手順 1〜5 とロールバック 1・2 を本実行した。COPR の `rhel-9-x86_64` を明示し、署名鍵の fingerprint を照合してから `20261005_054844_37254829-0` の 4 パッケージを入れた。導入元は COPR、共有ライブラリの未解決は 0、CLI は `wezterm 20261005_054844_37254829`。`ls-fonts | head -5` の broken-pipe panic は既存の補足どおりで、手順 5 の Wayland の起動・即終了は `rc=0`。

desktop エントリから実際の WezTerm を開き、キーボードで `wezterm --version` と打った出力と、IBus で確定した「日本語」を PNG で確認した。ロールバックで消えたのは WezTerm の 4 RPM だけで、COPR の repo ファイルも削除できた。自分用の設定・aarch64・Windows の節はこの VM では通していない。

---

### 付録: 現行版の新規 VM での再検証（2026-10-06）

**環境と流し方**: `5da3478` の現行手順を、別のクリーンな AlmaLinux 10.2 Workstation / x86_64 の VM（1 vCPU、SELinux Enforcing、firewalld 稼働、US 配列）で実行した。SSH の一般ユーザーの対話 PTY に折り畳みの外のブロックを手順ごとに貼り、応答とプロンプトを待った。GUI は GNOME 49.4 のヘッドレスセッションに仮想モニターを付け、操作後の PNG を目視した。既存の実機・資格情報は使っていない。

実施手順 1〜5、任意の最小設定、更新、ロールバック 1・2 を本実行した。COPR の `rhel-9-x86_64` から 4 RPM の `20261005_054844_37254829-0` が導入され、鍵の指紋、バージョン、未解決ライブラリが無いことを確認した。GNOME Wayland の実ウィンドウを起動し、後から HackGen と `ryo-aoki-pc/wezterm` の `4bdfbf1` の設定で日本語・Nerd Font・Powerline の表示と実 IME 変換を確認した。

現行の `wezterm ls-fonts | head -5` は、先に head が終了して Broken pipe の panic（終了 101）になった。実施手順 4 と最小設定の確認を `sed -n '1,5p'` に替え、パイプを最後まで読む形で両ブロックを再実行した。両方終了 0 で、既定の JetBrains Mono と最小設定の Noto Sans Mono CJK JP をそれぞれ確認した。

更新は変更なし。ロールバックで 4 RPM と COPR repo を削除できた。SSH / WSL / Windows の任意手順、aarch64、全キー割り当ての網羅は今回実施していない。

### 手順中の実測・検証状況の記録

- **Windows 11 では、stable と nightly が同じ登録を使う**: インストーラの `AppId` が同じなので、PC に入るのはどちらか 1 つ。後から入れた方が上書きするはず（確かめていない）

### 実施手順 / 手順 1: 補足: chroot を明示する理由

```
$ sudo dnf copr enable wezfurlong/wezterm-nightly
Error: It wasn't possible to enable this project.
Repository 'epel-10-x86_64' does not exist in project 'wezfurlong/wezterm-nightly'.
Available repositories: 'centos-stream-9-x86_64', 'fedora-43-aarch64', 'opensuse-tumbleweed-x86_64', 'fedora-44-aarch64', 'opensuse-tumbleweed-aarch64', 'rhel-9-x86_64', 'fedora-43-x86_64', 'fedora-rawhide-aarch64', 'fedora-42-x86_64', 'fedora-45-x86_64', 'rhel-9-aarch64', 'fedora-45-aarch64', 'fedora-rawhide-x86_64', 'fedora-44-x86_64', 'rhel-8-aarch64', 'centos-stream-9-aarch64', 'rhel-8-x86_64', 'fedora-42-aarch64'

If you want to enable a non-default repository, use the following command:
  'dnf copr enable wezfurlong/wezterm-nightly <repository>'
But note that the installed repo file will likely need a manual modification.
```

### 選択した方針

```
$ sudo dnf install --assumeno --repofrompath=wzn,https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/rhel-9-x86_64/ wezterm
Dependencies resolved.
 Package                Arch       Version                        Repo     Size
Installing:
 wezterm                x86_64     20260921_051727_5eb03b23-0     wzn     6.4 k
Installing dependencies:
 wezterm-common         x86_64     20260921_051727_5eb03b23-0     wzn     8.2 M
 wezterm-gui            x86_64     20260921_051727_5eb03b23-0     wzn      19 M
 wezterm-mux-server     x86_64     20260921_051727_5eb03b23-0     wzn     6.9 M
Install  4 Packages
```

- インストール後の `ldd` でも、`not found` は 0 だった
- 追加で入ったパッケージは無い（4 パッケージのみ）

### 手順中の検証状況

- ブラウザで取ると、SmartScreen が警告するはず（本書は `curl.exe` で取る。確かめていない）

### 実施手順 / 手順 3: 補足: wezterm はメタパッケージ / 取り込まれる鍵

- `dnf repoquery --requires wezterm` に `gcc` / `*-devel` / `make` が並んで見えるのは、同名の **SRPM の BuildRequires** が一緒に表示されているため。x86_64 パッケージには入っていない（`--assumeno` の結果が 4 パッケージだけであることで確認）

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### 補足

  設定で `term = "wezterm"` にするなら、先に公式ドキュメントの手順で terminfo を入れる（本書では**未実行**）:

---

### 付録: Windows 11 Pro の VM での導入検証（2026-10-06）

Rufus で作ったインストールメディアからクリーンインストールした専用 VM で、[Windows 11 の初期設定](windows-setup.md#付録-windows-11-pro-の-vm-での導入検証2026-10-06)の後に実行した。本文の PowerShell のブロックを抽出して、サインイン中の同じユーザーの管理者の Windows PowerShell に実行した。GUI のコピー・貼り付けや WezTerm の起動は試していない。

| 項目 | 確認した値 |
|---|---|
| OS | Windows 11 Pro 26H2、26300.9457、x64 |
| PowerShell | Windows PowerShell 5.1.26100.9444、64 ビット、管理者、セッション 1 |
| 初回導入前 | `Version`・`Location`・`OnPath`・`Running` は空、`Admin: True`、`VCRuntime: True` |
| Visual C++ Runtime | Windows 初期設定の手順 22 の依存関係として導入済み。この節の手順 3 は条件により飛ばした |
| 作業フォルダー | 実行前に `%TEMP%\wezterm-setup` が無いことを確認 |
| 入った版 | `20261005-054844-37254829` |

**初回導入と確認（この節の手順 2・4・5）**:

- 実行記録は `20261006-110954Z-cd78c35a`。2026-10-06 11:10:17.710 UTC に完了し、手順ごとのエラーは 0、最後の CLI とタスクの終了値は 0、開始と完了の対応も確認した
- 手順 4 は `WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0` と `wezterm 20261005-054844-37254829` を出した。本文の `.sha256` とインストーラの照合を通して初回導入された
- 手順 5 の登録は `DisplayName: WezTerm version 20261005-054844-37254829`、`DisplayVersion: 20261005-054844-37254829`、`InstallLocation: C:\Program Files\WezTerm\`。`UninstallString` は `"C:\Program Files\WezTerm\unins000.exe"` だった
- CLI の版も登録と一致した。PC 全体の `PATH` の `C:\Program Files\WezTerm` は 1 行だけで、全ユーザーのスタートメニューの `WezTerm.lnk` は `True`
- 導入先に `wezterm.exe`・`wezterm-gui.exe`・`wezterm-mux-server.exe`・`unins000.exe`・`unins000.dat`、`conpty.dll`・`OpenConsole.exe`・`strip-ansi-escapes.exe`・`libEGL.dll`・`libGLESv2.dll`・`mesa` が並ぶことを確認した
- 2026-10-07 04:04:16〜04:04:23 UTC の追加読み取りは、通常権限の PowerShell 7.6.6・Session 1 で行った。`HKCR\Directory\shell\Open WezTerm here` と `HKCR\Directory\Background\shell\Open WezTerm here` のコマンド項目が存在した。メニューをクリックして実際に起動することは未確認。証跡は `.verification/evidence/remaining-local-20261007-040410-0e3dc87e/guest-result.json`

**未検証の範囲**:

- 手順 1 の GUI での管理者の PowerShell の開き方とコピー・貼り付け、手順 6 の WezTerm の窓・既定のシェル、「Open WezTerm here」の動作。ショートカットやファイルがあることと、GUI が動くことは別に確認する必要がある
- 自分用の設定と Git Bash、設定ファイルの探索順、新しい PowerShell が PC 全体の `PATH` を読むこと
- `VCRUNTIME140.dll` が無い場合と手順 3 による導入、前の版への上書き、更新・アンインストール、arm64。Windows の実機での通し実行

2026-10-03 以前の付録は当時の確認範囲を記した履歴として保持した。今回も本文のコマンドは変更していない。

---

### 付録: Windows 11 Pro の VM での HackGen の CLI ラスタ生成の検証（2026-10-07）

前の初回導入と同じ VM の通常権限の PowerShell 7.6.6・Session 1 で、導入済みの `wezterm.exe` の `ls-fonts` を使った。`--config-file` で scratch の設定だけを渡し、`--codepoints 61,3042,6f22,2192,e0b0,f07c --rasterize-ascii` の stdout を採取した。設定はファミリーだけを替えた 2 通りで、フォントサイズは 12.0、`custom_block_glyphs=false` と `check_for_updates=false`。本文の導入コードと実ユーザーの設定は変更していない。

**フォント解決と数値ラスタ**:

- `HackGen Console NF` は `HackGenConsoleNF-Regular.ttf`、`HackGen35 Console NF` は `HackGen35ConsoleNF-Regular.ttf` を、ユーザーのフォントフォルダーから DirectWrite で使った。計 12 glyph はすべて ID が 0 以外、`notdef` なし。フォントの fallback と WezTerm の独自 glyph は出なかった
- 各文字の bearing と offset、ANSI `38:6` の RGBA を記録した。NUL padding は解析用のコピーだけから除き、元の stdout と JSON は変更していない。glyph 名中の `#0` を ID 0 と誤認せず、カンマ後の数値を glyph ID として判定した
- 下表のセル幅は両ファミリーで一致した。ラスタ欄は幅×高さと、alpha が 0 でないピクセル数／全ピクセル数。すべての文字に透明でないピクセルがあり、各 RGBA の値は 0〜255 に収まった

| 文字・コードポイント | セル幅 | HackGen Console NF | HackGen35 Console NF |
|---|---:|---|---|
| a / U+0061 | 1 | 8×8、52/64 | 8×9、61/72 |
| あ / U+3042 | 2 | 13×14、117/182 | 14×14、117/196 |
| 漢 / U+6F22 | 2 | 15×16、144/240 | 16×16、150/256 |
| → / U+2192 | 1 | 10×9、39/90 | 10×9、38/90 |
| Powerline / U+E0B0 | 1 | 10×19、117/190 | 11×19、137/209 |
| Nerd Fonts / U+F07C | 1 | 16×13、170/208 | 16×13、162/208 |

- 計 2005 ピクセル中、alpha が 0 以外は 1304、255 は 359。HackGen35 の U+2192 は最大 alpha 254、他の 11 glyph は最大 255 だった。各文字に 255 のピクセルが必要という判定はしていない
- 両 CLI の終了コードは 0、stderr は空、09:20:26〜09:20:46 UTC に実行した。scratch の削除は成功し、実ユーザーとインストール先の WezTerm 設定 3 パスの存在状態は前後不変だった
- 証跡は `.verification/evidence/remaining-wezterm-font-20261007-092017-4d5448f6` の `guest-result.json` と `glyph-assessment.json`。raw の SHA256 は `9B2C1DC0A426F36FF2971561FCC041077D62EFE718D8D85403C68CB1E6A40475`、独立した評価 JSON は `C12A3BF87D1FD9BE9C9061AD12DB6F6866B2A4141E993CC3F80221184E753C68`。文字ごとの RGBA の範囲・透明でない領域・ラスタの SHA256 も評価 JSON に保存した

**確認していないこと**:

- スタートからの WezTerm GUI 起動、既定のシェル、GUI のフォントメニューと選択、スクリーン上の字形・太字・行の高さ、右クリックのメニューの実クリック。CLI の数値ラスタを画面上の描画の確認へ広げない
- 自分用の設定と Git Bash、設定ファイルの探索順、選んだ文字以外、Visual C++ Runtime が無い場合、更新・上書き・アンインストール、arm64 の Windows。以前の付録はその時点の履歴として保持した

---

### 付録: Windows 11 Pro の VM での追加検証（2026-10-08）

上の付録と同じ VM（[windows-setup.md の検証記録の 2026-10-08 の付録](windows-setup.md#付録-pr-104-の未検証項目を同じ-vm-で確かめた記録2026-10-08)の環境）で、GUI の起動・右クリックの項目・更新を確かめた。手順は [Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の番号。WezTerm は 20261005-054844-37254829。

**手順 6（スタートメニューから起動）**:

- スタートメニューの「WezTerm」から起動すると、窓が開かずにプロセスが終わった。`%USERPROFILE%\.local\share\wezterm\wezterm-gui.exe-log-<番号>.txt` に `ERROR  wezterm_gui::frontend > Failed to create window: The OpenGL implementation is too old to work with glium`
  - この VM の画面のアダプターは VirtualBox の VBoxSVGA で、3D の描画を使っていない
  - `wezterm-gui.exe --config front_end="Software"` でも同じエラー
  - `wezterm-gui.exe --config prefer_egl=true` では窓が開き、中で `cmd.exe` が動いた（設定ファイルが無いときのシェル。`%COMSPEC%`）。窓の中の `wezterm --version` は `wezterm 20261005-054844-37254829`
  - 本文の手順 6 に、ログの場所と `config.prefer_egl = true` の箇条書きを足した
- エクスプローラーでフォルダーの背景を右クリックすると、旧形式のメニュー（windows-setup.md の手順 26）に「Open WezTerm here」がそのまま出た。レジストリのコマンドは `wezterm-gui.exe start --no-auto-connect --cwd "%V"`
  - 設定ファイルが無いままでは、同じ OpenGL のエラーで開かなかった
  - 一時的に `%USERPROFILE%\.wezterm.lua`（`config.prefer_egl = true` と `config.font = wezterm.font 'HackGen Console NF'` だけ）を置くと、`C:\verify\gui-fixtures` で窓が開いた。英字・かな・漢字・矢印・Powerline の記号・Nerd Font のフォルダーのアイコン・日本語の文が、HackGen Console NF で表示された（画面で確かめた）
  - 一時的な設定と試験用の文のファイルは、確かめた後に消した

**Windows 11 の更新**:

- この節の手順 2: 1 行目は `20261005-054844-37254829`、WezTerm のプロセスは無し
- この節の手順 3（手順 4 の貼り直し）: `WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0` と `wezterm 20261005-054844-37254829`。版は同じで、本文の「同じ版なら、main に新しいコミットが無かった」に当たる
- この節の手順 1・4 は、Remote Control のタスクが無いので飛ばした

**Windows 11 のロールバック**:

- この節の手順 1（WezTerm の窓は無い状態）: `False` が 2 行出て、その後は何も出なかった（登録・`C:\Program Files\WezTerm`・`PATH` の行が消えた）

**確認していないこと**:

- 3D の描画がある環境（実機の GPU）で、設定ファイル無しに手順 6 で窓が開くこと
- 自分用の設定（`ryo-aoki-pc/wezterm`）と Git Bash、新しい版に上がる更新、arm64 の Windows、Windows の実機
