# WezTerm Nightly インストール手順（AlmaLinux 10 は公式 COPR の EL9 ビルドを流用 / Windows 11 は nightly のインストーラ）

## 実施手順

- [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入したホストでは、参照先の WezTerm 導入手順で、通常のシェル統合の `~/.bashrc` への追記は不要。WezTerm の設定リポジトリの clone は必要。WSL で Windows 側のパスを直接読む場合は参照先の任意節を行う

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（管理者の Windows PowerShell 5.1 に貼る）
> - **すべて対象ホスト上で実行する**
> - **手順 1 と手順 3 には対話入力がある**（COPR の有効化の `[y/N]` と、COPR の GPG 鍵の取り込み）。答えてから次の手順を貼る

- 上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 設定を書く場所と、自分用の設定（`ryo-aoki-pc/wezterm`）への案内は[設定ファイル](#設定ファイル)。以後は[更新](#更新)・[ロールバック](#ロールバック)

1. chroot を明示して、COPR を有効化する。

   ```bash
   sudo dnf copr enable wezfurlong/wezterm-nightly "rhel-9-$(uname -m)"
   ```

   - chroot は `uname -m` から `rhel-9-x86_64` か `rhel-9-aarch64` になる（COPR に EL10 向けが無いので EL9 向けを使う）
   - 有効化してよいか `[y/N]` で聞かれる
   - **次の手順は、`[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: chroot を明示する理由</summary>

   `dnf copr enable` は chroot を省略すると `/etc/os-release` から推定する。EL 系は `epel-<major>-<arch>` になる（`/usr/lib/python3.12/site-packages/dnf-plugins/copr.py` の `_guess_chroot`）。このプロジェクトに `epel-10-x86_64` は無いので失敗する:

   ```
   $ sudo dnf copr enable wezfurlong/wezterm-nightly
   Error: It wasn't possible to enable this project.
   Repository 'epel-10-x86_64' does not exist in project 'wezfurlong/wezterm-nightly'.
   Available repositories: 'centos-stream-9-x86_64', 'fedora-43-aarch64', 'opensuse-tumbleweed-x86_64', 'fedora-44-aarch64', 'opensuse-tumbleweed-aarch64', 'rhel-9-x86_64', 'fedora-43-x86_64', 'fedora-rawhide-aarch64', 'fedora-42-x86_64', 'fedora-45-x86_64', 'rhel-9-aarch64', 'fedora-45-aarch64', 'fedora-rawhide-x86_64', 'fedora-44-x86_64', 'rhel-8-aarch64', 'centos-stream-9-aarch64', 'rhel-8-x86_64', 'fedora-42-aarch64'

   If you want to enable a non-default repository, use the following command:
     'dnf copr enable wezfurlong/wezterm-nightly <repository>'
   But note that the installed repo file will likely need a manual modification.
   ```

   エラーメッセージの言うとおり第 2 引数に chroot を渡せば通る。「repo ファイルの手直しが要るかも」とあるが、生成された repo ファイルは `baseurl` が `rhel-9-$basearch` を指すだけで、そのまま使えた:

   ```
   [copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly]
   name=Copr repo for wezterm-nightly owned by wezfurlong
   baseurl=https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/rhel-9-$basearch/
   type=rpm-md
   skip_if_unavailable=True
   gpgcheck=1
   gpgkey=https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/pubkey.gpg
   repo_gpgcheck=0
   enabled=1
   enabled_metadata=1
   ```

   公式ドキュメントの openSUSE 向け手順が同じ `dnf copr enable wezfurlong/wezterm-nightly <repository>` の形なので、想定内の使い方ではある。

   </details>

1. できた repo ファイルを確かめる。

   ```bash
   cat /etc/yum.repos.d/_copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly.repo
   ```

   - `baseurl` が `.../wezterm-nightly/rhel-9-$basearch/`、`gpgcheck=1` になっていればよい

1. WezTerm を入れる。

   ```bash
   sudo dnf install wezterm
   ```

   - 途中で COPR の GPG 鍵の取り込みを聞かれる
   - fingerprint は `FD90 9B62 88A8 4250 AD58 020F A698 91C5 CEA2 757D`（`wezfurlong_wezterm-nightly`）
   - **次の手順は、トランザクション表の `[y/N]` と鍵の確認に答えてから貼る**（続けて貼ると答えとして食われる）

   <details>
   <summary>補足: <code>wezterm</code> はメタパッケージ / 取り込まれる鍵</summary>

   - `wezterm` 本体（6.4 KB、`rpm -ql wezterm` は空）は、`wezterm-common`（CLI の `wezterm`、シェル統合、補完）/ `wezterm-gui`（`wezterm-gui`、desktop ファイル、アイコン）/ `wezterm-mux-server` を Requires で束ねているだけ
   - `dnf repoquery --requires wezterm` に `gcc` / `*-devel` / `make` が並んで見えるのは、同名の **SRPM の BuildRequires** が一緒に表示されているため。x86_64 パッケージには入っていない（`--assumeno` の結果が 4 パッケージだけであることで確認）

   GPG 鍵はインストール時に COPR の `pubkey.gpg` から取り込まれる:

   ```
   Importing GPG key 0xCEA2757D:
    Userid     : "wezfurlong_wezterm-nightly (None) <wezfurlong#wezterm-nightly@copr.fedorahosted.org>"
    Fingerprint: FD90 9B62 88A8 4250 AD58 020F A698 91C5 CEA2 757D
    From       : https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/pubkey.gpg
   ```

   </details>

1. WezTerm が入ったか確かめる。

   ```bash
   rpm -q wezterm wezterm-common wezterm-gui wezterm-mux-server
   dnf -q repoquery --installed --qf '%{name} %{from_repo}\n' 'wezterm*'
   wezterm --version
   ldd /usr/bin/wezterm-gui /usr/bin/wezterm /usr/bin/wezterm-mux-server | grep -c 'not found'   # 0 なら OK
   wezterm ls-fonts | sed -n '1,5p'
   ```

   - GUI は、**GNOME にログイン済みの実セッションの端末から** `wezterm` を起動すれば開く
   - アプリ一覧には「WezTerm」が出る（`/usr/share/applications/org.wezfurlong.wezterm.desktop`）
   - ssh などグラフィカルでないシェルから確かめる場合は、手順 5 でログイン中の Wayland セッションを指定して、ウィンドウを開いて即終了させる
   - GNOME の端末から `wezterm` で確かめたなら、手順 5 は飛ばす

   <details>
   <summary>補足: <code>wezterm ls-fonts</code> と <code>wezterm-gui --version</code></summary>

   - **`wezterm ls-fonts`** は GUI 無しでフォント解決を確認できる
     - 既定のフォントは組み込みの `JetBrains Mono` で、フォールバックに `Noto Color Emoji`（fontconfig 経由）と組み込みの `Symbols Nerd Font Mono` が並ぶ
     - `| head` で切ると `rc=101`（Rust の panic 終了コード）になるが、パイプが閉じたためで異常ではない。単体で実行すると `rc=0`
   - **`wezterm-gui --version` は `wezterm-gui someone forgot to call assign_version_info` と出る**（rc=0）
     - COPR ビルドでは GUI バイナリにバージョン情報が埋め込まれていない。バージョンは `wezterm --version` で見る

   </details>

1. ssh などグラフィカルでないシェルから確かめるときだけ、ウィンドウを開いて即終了させる。

   ```bash
   env -i HOME="$HOME" USER="$USER" PATH=/usr/bin:/bin \
       WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR="/run/user/$(id -u)" XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=GNOME \
       timeout 30 wezterm start --always-new-process -- sh -c 'exit 0'; echo "rc=$?"
   ```

   - ログイン中の Wayland セッションを指定して、ウィンドウを開く
   - `rc=0` なら、ウィンドウが開いて閉じている（`exit_behavior` の既定が `Close` なので、子プロセスが終わるとウィンドウも閉じる）

   <details>
   <summary>補足: Wayland セッションでの起動試験</summary>

   - **Wayland セッションでの起動試験**: この検証は Claude Code のシェル（TTY もディスプレイも無い）から行ったので、`env -i` で環境を空にしてから、ログイン中の GNOME セッションの `WAYLAND_DISPLAY=wayland-0` と `XDG_RUNTIME_DIR` を渡した
     - 値は `/proc/$(pgrep -u "$USER" -x gnome-shell)/environ` から取れる
     - `wezterm start -- sh -c 'exit 0'` はウィンドウを開いて `sh` を走らせ、終了と同時にウィンドウを閉じる。結果 `rc=0`
     - `timeout 30` は、描画に失敗してウィンドウが残った場合の保険

   </details>

---

## 設定ファイル

- パッケージ（Windows 11 ではインストーラ）は設定ファイルを置かない。無ければ組み込みの既定値で動く
- 置き場所は次の順で探し、**最初に見つかった 1 つだけ**を読む（[補足: 設定ファイルの探索順序](#設定ファイルの探索順序実測)）

| 優先 | 場所 | 用途 |
|---|---|---|
| 1 | `wezterm --config-file <path>` | 一時的に別の設定で起動する |
| 2 | 環境変数 `WEZTERM_CONFIG_FILE` | 同上（環境ごとに切り替える） |
| 3 | `~/.wezterm.lua` | **1 ファイルで済む設定はここ**（公式の推奨） |
| 4 | `${XDG_CONFIG_HOME}/wezterm/wezterm.lua`（`XDG_CONFIG_HOME` を設定している場合のみ） | 複数ファイルに分ける設定 |
| 5 | `~/.config/wezterm/wezterm.lua`（`XDG_CONFIG_HOME` 未設定のとき） | 同上 |

- **Windows 11 では**、`~` は `%USERPROFILE%`（`C:\Users\<WIN_USER>`）。置くのは `%USERPROFILE%\.wezterm.lua` か `%USERPROFILE%\.config\wezterm\wezterm.lua`
  - 表の 2 と 3 の間に、`wezterm.exe` と同じフォルダーの `wezterm.lua`（`C:\Program Files\WezTerm\wezterm.lua`）が入る。USB メモリで持ち運ぶとき用で、公式は勧めていない
  - Windows 11 の探索順はソースと公式の文書で見ただけで、確かめていない（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
- **自分用の設定**は [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm) にある（Tokyo Night 系の配色・ピル型タブ・ステータスバー・シェル統合の設定）
  - 入れ方は、その [docs/install.md](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md)（本書と同じ書式の手順書）。`~/.config/wezterm` に clone する。シェル統合は bash の共通設定が読むので、参照先の手順 5〜7（直接追記）は行わず、手順 8 で端末を開き直す
  - Windows 11 では、同じブロックを Git for Windows の Git Bash（[git.md](git.md)）に貼る（docs/install.md のとおり）
  - どこを変えればよいかは [README の「カスタマイズの勘所」](https://github.com/ryo-aoki-pc/wezterm#カスタマイズの勘所)
  - nightly が前提（stable では未知のオプションで設定エラーになる）。本書で入れるのは、AlmaLinux 10 も Windows 11 も nightly
  - フォントは HackGen Console NF（[hackgen.md](hackgen.md)。Windows 11 は同書の[Windows 11 で使う](hackgen.md#windows-11-で使う)）
  - AlmaLinux 10 だけ: 本書の RPM が置く `/etc/profile.d/wezterm.sh` が読まれていると、設定のシェル統合は迷子のマウス報告よけだけになり、完了通知は動かない（[docs/install.md の注意点](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#注意点)）
  - Windows 11 のインストーラはシェル統合を入れない。設定が無いときに開くシェルは `cmd.exe`（`%COMSPEC%`）で、この設定は Git Bash を既定にし、Git Bash と PowerShell のシェル統合を設定の中から読ませる（[README の「シェル統合」](https://github.com/ryo-aoki-pc/wezterm#シェル統合)）
  - この設定を入れるなら、この節の手順 1 は貼らない（`~/.config/wezterm` が空でないと clone できない）
  - `~/.wezterm.lua` があると、clone した設定は読まれない
- この節の手順 1 は AlmaLinux 10 のもの（bash のブロック。Windows 11 では試していない）

> [!WARNING]
> **この節の**手順 1 は、既存の `~/.config/wezterm/wezterm.lua` を**上書きする**。自分の設定がある人は貼らない。

1. AlmaLinux 10 で自分の設定が無いときだけ、最小の例を `~/.config/wezterm/wezterm.lua` に書く。

   ```bash
   mkdir -p ~/.config/wezterm
   cat > ~/.config/wezterm/wezterm.lua <<'LUA'
   local wezterm = require 'wezterm'
   local config = wezterm.config_builder()
   config.font = wezterm.font 'Noto Sans Mono'
   config.font_size = 12
   return config
   LUA
   wezterm ls-fonts | sed -n '1,5p'     # Primary font に書いたフォントが出れば読めている
   ```

   - **`~/.wezterm.lua` が既にあるとそちらが優先されて読まれない**ので、どちらか一方にする
   - 保存すれば、起動中の WezTerm にも自動で反映される（`automatically_reload_config` の既定が true。効かなければ `Ctrl+Shift+R`）
   - Lua の文法エラーがあると、起動時に `ERROR wezterm_gui > syntax error: ...` を出して**組み込みの既定値で起動する**（別の候補ファイルには進まない）
   - `wezterm -n`（`--skip-config`）で、設定を読まずに起動できる
   - `wezterm --config 'font_size=14'` のように、1 項目だけ上書きもできる

---

## 更新

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 の更新](#windows-11-の更新)
- COPR は `main` ブランチに追従して毎日〜数日おきにビルドされる
- 通常の `dnf upgrade` に含まれる

1. WezTerm だけ上げるときは、名前を指定して上げる。

   ```bash
   sudo dnf upgrade wezterm
   ```

---

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)
- ロールバックは、クリーンインストールの x86_64 VM で本実行した（2026-10-06。消えたのは手順 1 の 4 パッケージだけ）

1. WezTerm の 4 パッケージを消す。

   ```bash
   sudo dnf remove wezterm wezterm-common wezterm-gui wezterm-mux-server
   ```

   - 消えるのはこの 4 パッケージだけで、巻き添えの依存パッケージは無い
   - **次の手順は、トランザクション表を見て `[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

1. COPR の repo ファイルを消す。

   ```bash
   sudo dnf copr remove wezfurlong/wezterm-nightly      # repo ファイルを消す
   ```

   - `~/.config/wezterm/` や `~/.wezterm.lua`（自分で作った設定）は消えないので、不要なら手で消す
   - 自分用の設定（`ryo-aoki-pc/wezterm`）を入れていれば、`~/.bashrc` に足したシェル統合の 1 行も残る（消し方は、その [docs/install.md のロールバック](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#ロールバック)）
   - COPR の GPG 鍵は `gpg-pubkey-cea2757d-651b2a3e` として残る（`rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} %{summary}\n'` で確認できる）
   - 消すなら `sudo rpm -e gpg-pubkey-cea2757d-651b2a3e`

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて、この PC のデスクトップで行う**。この節の手順 1 で管理者の Windows PowerShell（5.1）を開き、この節の手順 2〜5 と、後ろの Windows 11 の 2 節（更新・ロールバック）のブロックをそこに貼る。ログインするユーザーは Administrators の一員（インストーラが `C:\Program Files\WezTerm` に入れ、PC 全体の `PATH` に書くため）
> - 前提: [Windows 11 の初期設定の手順 16〜19](windows-setup.md#実施手順)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - **WezTerm の窓をすべて閉じてから始める**（動いていると、この節の手順 4 が止まる）。[Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)のタスクが動いていれば、先に同書の[止める・もう一度始める](windows-claude-remote-control.md#止めるもう一度始める)の手順 1 で止める
> - **この節の手順 6 は画面で行う**（スタートメニューから WezTerm を起動する）

- 上から順にコードブロックを貼る。変数は無い（入れる先と URL はブロックに直接書いてある）
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 設定ファイルの置き場所と自分用の設定は[設定ファイル](#設定ファイル)。以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](#windows-11-のロールバック)
- もう WezTerm が `C:\Program Files\WezTerm` に入っている PC でも、同じ手順で今の nightly に上書きできる

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、配布物（インストーラの sha256・Inno Setup の版・署名の有無・中の実行ファイル）、インストーラの定義と作り方、Inno Setup の文書とソース、Linux の PowerShell 7 での構文と模擬の実行だけ（[対象と検証環境](#対象と検証環境)）。

1. Windows のデスクトップで、管理者の Windows PowerShell（5.1）を開く。

   - スタートメニューの「Windows PowerShell」を右クリックし、「管理者として実行」で開く
   - WezTerm の中の PowerShell は使わない（WezTerm が動いていると、この節の手順 4 が止まる）

1. 管理者であることと、今の WezTerm と `VCRUNTIME140.dll` があるかを確かめる。

   ```powershell
   $u = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1' -ErrorAction SilentlyContinue
   [pscustomobject]@{
     Admin     = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     Version   = $u.DisplayVersion
     Location  = $u.InstallLocation
     OnPath    = (Get-Command wezterm.exe -All -ErrorAction SilentlyContinue).Source -join ' '
     Running   = (Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue).ProcessName -join ' '
     VCRuntime = Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
   } | Format-List
   ```

   - `Admin : True` であること（`False` なら、この節の手順 1 で開き直す）
   - 初めて入れる PC では、`Version`・`Location`・`OnPath`・`Running` が空
   - `Version` に版が出たら、もう入っている（`20260905-153129-092dcf70` など）。この節の手順 4 で今の nightly に上書きする
     - `Location` は `C:\Program Files\WezTerm\` のはず。違う場所なら、インストーラはそこに上書きするので、先に[Windows 11 のロールバック](#windows-11-のロールバック)で外す
     - `20240203-110809-5046fc22` なら stable（winget の `wez.wezterm` など）。同じ登録なので、nightly で上書きされる
   - `OnPath` に `C:\Program Files\WezTerm\wezterm.exe` 以外（scoop の `shims` など）が出たら、ほかの方法で入れた WezTerm がある。混ざらないよう、外してから始める
   - `Running` に名前が出たら、その WezTerm の窓を閉じる（Remote Control のタスクは、この節のリードのとおりに止める）
   - `VCRuntime : True` なら、この節の手順 3 は飛ばす。`False` なら、この節の手順 3 で入れる

   <details>
   <summary>補足: 確かめていること</summary>

   - レジストリのキーは、WezTerm のインストーラ（Inno Setup）がアンインストールのために作る登録。名前の `{BCF6F0DA-…}` はインストーラの定義の `AppId` で、stable と nightly で同じ（winget の `wez.wezterm` と `wez.wezterm.nightly` の `ProductCode` も同じ値）。`DisplayVersion` が WezTerm の版
   - WezTerm の実行ファイル（`wezterm.exe`・`wezterm-gui.exe`・`wezterm-mux-server.exe`）は `VCRUNTIME140.dll`（Visual C++ の再頒布可能パッケージ）を読み込むが、インストーラはこれを入れない（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）。無いと起動できないはず（確かめていない）
   - `Get-Process` は、ほかのユーザーやセッションの WezTerm も数える

   </details>

1. `VCRUNTIME140.dll` が無いときだけ、Visual C++ の再頒布可能パッケージを入れる。

   ```powershell
   winget install --exact --id Microsoft.VCRedist.2015+.x64 --source winget --scope machine --accept-source-agreements --accept-package-agreements
   Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と、`True` が出ればよい
   - winget が再起動を求めたら、再起動してから、この節の手順 1 からやり直す
   - `winget` が見つからないというエラーになったら、Microsoft Store で「アプリ インストーラー」を更新してから始める

   <details>
   <summary>補足: winget の定義</summary>

   - `Microsoft.VCRedist.2015+.x64` は、2026-10-03 の winget-pkgs で 14.51.36247.0。インストーラは Microsoft の `VC_redist.x64.exe`（`download.visualstudio.microsoft.com`）で、winget は定義の sha256 を確かめてから動かす。PC 全体に入る（`Scope: machine`）
   - winget の `wez.wezterm.nightly` の定義も、これを依存に書いている（winget で入れると先にこれが入る。本書は winget で WezTerm を入れないので、ここで入れる）
   - 定義は、終了コード 3010（再起動が要る）も成功として扱う
   - Microsoft の文書では、x64 のパッケージには arm64 の分も入っている。arm64 の Windows では試していない

   </details>

1. nightly のインストーラを取り、sha256 を確かめて、黙って入れる。

   ```powershell
   & {
     $dir = 'C:\Program Files\WezTerm'
     $curl = "$env:WINDIR\System32\curl.exe"
     $url = 'https://github.com/wezterm/wezterm/releases/download/nightly/WezTerm-nightly-setup.exe'
     $tmp = "$env:TEMP\wezterm-setup"
     $setup = "$tmp\WezTerm-nightly-setup.exe"
     $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
     if (-not $admin) { Write-Error '中断: 管理者の PowerShell ではない'; return }
     if (-not (Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll")) { Write-Error '中断: VCRUNTIME140.dll が無い（この節の手順 3）'; return }
     if (Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue) { Write-Error '中断: WezTerm が動いている（窓をすべて閉じる）'; return }
     Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & $curl -fsSL -o "$setup.sha256" "$url.sha256"
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: WezTerm-nightly-setup.exe.sha256 を取れない'; return }
     & $curl -fsSL -o $setup $url
     if ($LASTEXITCODE -ne 0) { Write-Error '中断: WezTerm-nightly-setup.exe を取れない'; return }
     $m = Select-String -LiteralPath "$setup.sha256" -Pattern '^([0-9a-f]{64})  WezTerm-nightly-setup\.exe$' | Select-Object -First 1
     if (-not $m) { Write-Error '中断: WezTerm-nightly-setup.exe.sha256 に sha256 の行が無い'; return }
     if ((Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash -ne $m.Matches[0].Groups[1].Value) { Write-Error '中断: WezTerm-nightly-setup.exe の sha256 が一致しない'; return }
     $p = Start-Process -FilePath $setup -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCLOSEAPPLICATIONS /LOG=`"$tmp\setup.log`"" -Wait -PassThru
     if ($p.ExitCode -ne 0) { Write-Error "中断: インストーラが終了コード $($p.ExitCode) で終わった（ログは $tmp\setup.log）"; return }
     Remove-Item -LiteralPath $tmp -Recurse -Force
     'WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0'
     & "$dir\wezterm.exe" --version
   }
   ```

   - `WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0` と、`wezterm 20260929-043349-cab25161` の形の 1 行が出ればよい（版は実行した日の nightly）
   - インストーラの画面は出ない。終わるまでプロンプトが戻らない
   - `中断:` で始まるエラーが出たら、そこで止まっている（取ってきたものとログは `%TEMP%\wezterm-setup` に残る。次に貼ったときに消して作り直す）
   - `取れない` と `sha256 が一致しない` は、nightly が入れ替わる最中に取ったときにも出る（毎日の入れ替えは日本時間の昼ごろで、2026-10-03 は 13 時 13 分。main が変わったときにも入れ替わる）。少し待って貼り直す
   - 何度貼ってもよい（同じ場所に上書きする）

   <details>
   <summary>補足: 確かめていることと、インストーラの引数</summary>

   **sha256**

   - `WezTerm-nightly-setup.exe.sha256` は、同じ nightly のリリースに置かれた sha256（`<64 桁>  WezTerm-nightly-setup.exe` の 1 行）。上流の CI が、ビルドしたファイルからリリースに上げる直前に作る（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
   - 同じ場所から取るので、分かるのは壊れていないこと（途中で切れていない、入れ替えの最中のものではない）まで。インストーラにも中の `wezterm*.exe` にも Authenticode の署名は無く、本物かどうかは確かめられない（[注意点](#注意点)）
   - sha256 を先に、インストーラを後に取る。間で nightly が入れ替わると、一致せずに止まる
   - `-ne` の比較は大文字と小文字を区別しない（`.sha256` は小文字、`Get-FileHash` は大文字）
   - `curl.exe` は `C:\Windows\System32\curl.exe` を呼ぶ（[hackgen.md の Windows 11 で使う](hackgen.md#windows-11-で使う)の手順 3 の補足と同じ）
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

   </details>

1. 入ったものと、`PATH`・スタートメニューを確かめる。

   ```powershell
   Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1' | Format-List DisplayName, DisplayVersion, InstallLocation, UninstallString
   & 'C:\Program Files\WezTerm\wezterm.exe' --version
   [Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';' | Where-Object { $_ -like '*\WezTerm*' }
   Test-Path -LiteralPath "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\WezTerm.lnk"
   Get-ChildItem -LiteralPath 'C:\Program Files\WezTerm' -Name
   ```

   - `DisplayVersion` と `wezterm --version` の版が同じ（`20260929-043349-cab25161` の形）
   - `UninstallString` は `"C:\Program Files\WezTerm\unins000.exe"`
   - PC 全体の `PATH` に `C:\Program Files\WezTerm` が 1 行と、スタートメニューの `True` が出る
   - 最後に `wezterm.exe`・`wezterm-gui.exe`・`unins000.exe` などのファイルの名前が並ぶ
   - 開いていた PowerShell の `PATH` には入らない。新しく開いた窓（WezTerm の中も）では、`wezterm` を名前で呼べる

   <details>
   <summary>補足: 版の読み方</summary>

   - 版は、ビルドした日ではなく、もとにした main の最後のコミットの日時と、そのコミットの頭 8 桁（`<年月日>-<時分秒>-<コミット>`）
   - nightly は毎日ビルドし直されるが、コミットの無い日は同じ版になる（2026-10-03 のビルドは `20260929-043349-cab25161`）
   - `DisplayName` は `WezTerm <版>`（Inno Setup の既定の形）
   - `UninstallString` は、[Windows 11 のロールバック](#windows-11-のロールバック)の手順 1 が使う

   </details>

1. スタートメニューから WezTerm を起動し、窓が開くことを確かめる。

   - スタートメニューで「WezTerm」を探し、クリックして開く
   - 窓が開き、中でシェルが動けばよい。設定ファイルが無ければ `cmd.exe` が開く（自分用の設定では Git Bash。[設定ファイル](#設定ファイル)）
   - 窓の中で `wezterm --version` を打つと、この節の手順 5 と同じ版が出る
   - **注意**: 管理者の PowerShell から `wezterm-gui.exe` を起動しない（WezTerm と中のシェルが管理者で動く）
   - エクスプローラーでフォルダーを右クリックすると「Open WezTerm here」がある（Windows 11 の新しいメニューでは「その他のオプションを確認」の中）

---

## Windows 11 の更新

- WezTerm は自分では更新しない。nightly の新しい版が出ても知らせない（WezTerm の更新の確認が見るのは stable のリリースだけで、nightly の版の方が新しいので何も出ない）
- 上げるには、[Windows 11 で使う](#windows-11-で使う)の手順 4 を貼り直す。同じ場所（`C:\Program Files\WezTerm`）に上書きし、設定ファイルはそのまま
- nightly は毎日ビルドし直される。版は main の最後のコミットで決まり、コミットの無い日は同じ版になる
- この節の手順 2・3 は、管理者の Windows PowerShell（5.1）に貼る

1. Remote Control のタスクを動かしているときだけ、タスクを止める。

   - [windows-claude-remote-control.md の止める・もう一度始める](windows-claude-remote-control.md#止めるもう一度始める)の手順 1 を行う
   - 上げた後に、この節の手順 4 で始め直す

1. 今の版を確かめ、WezTerm が動いていないことを確かめる。

   ```powershell
   (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1').DisplayVersion
   Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue | Format-Table Id, ProcessName
   ```

   - 1 行目に今の版が出る
   - プロセスが出たら、その WezTerm の窓をすべて閉じる（動いていると、この節の手順 3 が止まる）

1. [Windows 11 で使う](#windows-11-で使う)の手順 4 のブロックを貼る。

   - 最後に出る `wezterm <版>` が、この節の手順 2 の版より新しければ上がった
   - 同じ版なら、main に新しいコミットが無かった（同じ版を入れ直しただけ）

1. この節の手順 1 でタスクを止めたときだけ、タスクを始め直す。

   - [windows-claude-remote-control.md の止める・もう一度始める](windows-claude-remote-control.md#止めるもう一度始める)の手順 2 を行う

---

## Windows 11 のロールバック

- この節の手順 1 は、管理者の Windows PowerShell（5.1）に、WezTerm の窓をすべて閉じてから貼る
- [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)は WezTerm を使う。使っているなら、先に同書の[ロールバック](windows-claude-remote-control.md#ロールバック)を行う
- 設定ファイル（`%USERPROFILE%\.wezterm.lua`・`%USERPROFILE%\.config\wezterm`）は消えない。要らなければ手で消す（自分用の設定は、その [docs/install.md のロールバック](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#ロールバック)を Git Bash で行う）
- [Windows 11 で使う](#windows-11-で使う)の手順 3 で入れた Visual C++ の再頒布可能パッケージは、ほかのアプリも使うので消さない

1. WezTerm のアンインストーラを黙って動かし、消えたことを確かめる。

   ```powershell
   & {
     $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{BCF6F0DA-5B9A-408D-8562-F680AE6E1EAF}_is1'
     $dir = 'C:\Program Files\WezTerm'
     $u = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
     if (-not $u) { Write-Error '中断: WezTerm のアンインストールの登録が無い'; return }
     if ($u.UninstallString -notmatch '^"([^"]+\\unins\d{3}\.exe)"') { Write-Error "中断: UninstallString が想定と違う（$($u.UninstallString)）"; return }
     $unins = $Matches[1]
     if (Get-Process -Name wezterm, wezterm-gui, wezterm-mux-server -ErrorAction SilentlyContinue) { Write-Error '中断: WezTerm が動いている（窓をすべて閉じる）'; return }
     $p = Start-Process -FilePath $unins -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -Wait -PassThru
     if ($p.ExitCode -ne 0) { Write-Error "中断: アンインストーラが終了コード $($p.ExitCode) で終わった"; return }
     for ($i = 0; $i -lt 60 -and ((Test-Path -LiteralPath $key) -or (Test-Path -LiteralPath $dir)); $i++) { Start-Sleep -Seconds 1 }
     Test-Path -LiteralPath $key, $dir
     [Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';' | Where-Object { $_ -like '*\WezTerm*' }
   }
   ```

   - `False` が 2 行出て、その後に何も出なければよい（登録・`C:\Program Files\WezTerm`・`PATH` の行が消えた）
   - `中断:` で始まるエラーが出たら、そこで止まっている（アンインストーラの終了コードのときは、途中まで消えていることがある）
   - 2 行目が `True` のまま（60 秒待ってから出る）なら、インストーラが置いていないファイル（`wezterm.lua` など）が `C:\Program Files\WezTerm` に残っている。中を見て、要らなければ消す
   - 設定のアプリ → インストールされているアプリ の「WezTerm」の「アンインストール」でも同じ

   <details>
   <summary>補足: アンインストーラの動き</summary>

   - アンインストーラは `C:\Program Files\WezTerm\unins000.exe`（Inno Setup）。場所は登録の `UninstallString` から読む
   - 引数の `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART` は、Inno Setup のアンインストーラの標準の引数（確認の窓も完了の窓も出さない）
   - アンインストーラは自分の写しを `%TEMP%` に作り、写しの方が消す。終了コードが返った時点では片付けがまだ続いていることがある（Inno Setup の文書）ので、登録とフォルダーが消えるまで 60 秒まで待つ
   - 消えるもの: インストーラが置いたファイルとフォルダー、スタートメニューの「WezTerm」、右クリックの「Open WezTerm here」、PC 全体の `PATH` の `C:\Program Files\WezTerm`、アンインストールの登録
   - 残るもの: 設定ファイルと、WezTerm が作る作業用のフォルダー（ソースでは `%USERPROFILE%\.local\share\wezterm`・`%APPDATA%\wezterm`・`%LOCALAPPDATA%\wezterm`。作られていれば）

   </details>

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に [WezTerm](https://wezterm.org/) の nightly ビルドを入れる。AlmaLinux 10 では **dnf 管理で**入れ、以後は `dnf upgrade` で追従できるようにする
- **進め方**: どちらも**読者が書き換える変数は無い**
  - **AlmaLinux 10**（[実施手順](#実施手順)）: 作者が管理する公式 COPR `wezfurlong/wezterm-nightly` には **EL10 向けのビルドが無い**ので、chroot を `rhel-9-<arch>` と明示して有効化し、EL9 向けビルドをそのまま入れる（chroot は `uname -m` から自動で決まる）
  - **Windows 11**（[Windows 11 で使う](#windows-11-で使う)）: GitHub の `nightly` のリリースの `WezTerm-nightly-setup.exe`（Inno Setup）を、同じリリースの `.sha256` と比べてから黙って動かし、`C:\Program Files\WezTerm` に入れる。管理者の Windows PowerShell 5.1 に貼る。更新は同じブロックを貼り直す
    - [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)が `C:\Program Files\WezTerm\wezterm.exe` を呼ぶので、その場所に入れる
    - [Windows 11 の初期設定](windows-setup.md)の後に通す手順書の 1 つ
  - 設定ファイルは `~/.wezterm.lua` か `~/.config/wezterm/wezterm.lua`（Windows 11 では `%USERPROFILE%` の下。[設定ファイル](#設定ファイル)）
- **状態（AlmaLinux 10）**: **x86_64 の実機（2026-09-21）とクリーンインストールの VM（2026-10-06）で本実行済み**。VM は実施手順 1〜5・CLI と GUI の起動・ロールバックを確認した
  - 2026-10-06: 別の新規 VM で現行手順を再検証した。今回の実施・解除・未実施範囲は[新しい付録](#付録-現行版の新規-vm-での再検証2026-10-06)に記録した
  - 確認したこと: ウィンドウの起動・終了まで
  - **aarch64 は未検証**（COPR に `rhel-9-aarch64` はあるので、同じ手順で通る見込み）
  - EL9 向けビルドを EL10 で使う非公式な流用なので、更新で壊れたら[補足: 注意点](#注意点)を見る
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - 利用者の PC には、nightly の `20260905-153129-092dcf70` が `C:\Program Files\WezTerm` に入っている（[Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)の実機の記録。入れ方の記録は無い）。その PC では、[Windows 11 で使う](#windows-11-で使う)の手順は上書きになる
  - **確かめたこと**（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）:
    - 配布物: 2026-10-03 の `WezTerm-nightly-setup.exe` の sha256 と `.sha256` の一致、Inno Setup 6.7.0 で作られていること、Authenticode の署名が無いこと。同じ日の zip の中の実行ファイルが x64 で、`VCRUNTIME140.dll` を読み込むこと
    - インストーラの定義（`ci/windows-installer.iss`）と作り方（`ci/deploy.sh`・`gen_windows_continuous.yml`）、Inno Setup の文書とソース（引数・終了コード・アンインストールの登録・アンインストーラの動き）、WezTerm のソース（Windows の設定ファイルの探索順、更新の確認）
    - ほかの経路: winget の `wez.wezterm.nightly`（定義の sha256 の直され方）・`wez.wezterm`・`Microsoft.VCRedist.2015+.x64`、scoop の `versions/wezterm-nightly`・`extras/wezterm`、Chocolatey の `wezterm`
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。[Windows 11 で使う](#windows-11-で使う)の手順 4 と[Windows 11 のロールバック](#windows-11-のロールバック)の手順 1 のブロックは、Linux の pwsh で偽物のインストーラとレジストリを使って流した（[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
  - **確かめていないこと**: Windows で貼ること（すべての手順）、インストーラが黙って入ることと、`PATH`・スタートメニュー・右クリックのメニュー、`VCRUNTIME140.dll` の無い PC と[Windows 11 で使う](#windows-11-で使う)の手順 3、WezTerm の窓が開くこと、更新（上書き）とアンインストール、arm64 の Windows

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
| OS | Windows 11（[Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)の PC は 26H2）。x64 |
| PowerShell | Windows PowerShell 5.1（管理者として実行） |
| ユーザー | Administrators の一員 |
| 今の WezTerm | nightly の `20260905-153129-092dcf70`（`C:\Program Files\WezTerm`） |
| 入る WezTerm | 2026-10-03 の nightly は `20260929-043349-cab25161`（`WezTerm-nightly-setup.exe`、45,473,308 バイト） |

> [!NOTE]
> 出力例の値は `<HOSTNAME>` / `<USER>`（AlmaLinux 10）/ `<WIN_USER>`（Windows のユーザー名）のプレースホルダで書いてある。版（AlmaLinux 10 の `20260921_051727_5eb03b23`、Windows 11 の `20260929-043349-cab25161`）は実行日によって変わる。Windows 11 の節にも変数は無い（入れる先・URL はブロックに直接書いてある）。

手順書全体に関わる理由・実測・落とし穴と調査記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

AlmaLinux 10 の実機（2026-09-21）。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)の手順 2 で確かめる。

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
| Homebrew の公式 tap `wezterm/wezterm-linuxbrew` | formula は AppImage を `bin/wezterm` に置くだけ。stable は `20240203-110809-5046fc22`、nightly（`--HEAD`）は `WezTerm-nightly-Ubuntu20.04.AppImage` で、2026-03-18 から更新されていない。aarch64 の AppImage は無い（[補足](#homebrew-の-tap-を採らない理由)） | 不採用（nightly が古く、aarch64 に無い） |
| ソースビルド（`cargo build --release`） | 可能だが Rust toolchain と `get-deps` の依存パッケージが要り、更新のたびにビルドする | 不採用 |

**EL9 向けビルドが EL10 で通る根拠**: 実行前に `--assumeno` で依存解決だけ試した。

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

`wezterm-gui` が要求するのは次のもの（`dnf repoquery --requires wezterm-gui`）:

- `libc.so.6(GLIBC_2.34)`
- `libssl.so.3(OPENSSL_3.0.0)` / `libcrypto.so.3`
- `libwayland-client.so.0` / `libwayland-egl.so.1`
- `libxkbcommon.so.0(V_0.6.0)` / `libxkbcommon-x11.so.0`
- `libxcb.so.1` / `libxcb-image.so.0` / `libxcb-util.so.1`
- `libX11.so.6` / `libX11-xcb.so.1`
- `libfontconfig.so.1`、`mesa-libEGL`、`dbus`

EL10 は glibc 2.39 / OpenSSL 3.5（`libssl.so.3` の soname と `OPENSSL_3.0.0` シンボルバージョンを両方提供）なので、EL9 向けバイナリがそのまま動く。

- インストール後の `ldd` でも、`not found` は 0 だった
- 追加で入ったパッケージは無い（4 パッケージのみ）

#### Homebrew の tap を採らない理由

- COPR を brew に置き換えられないかを、2026-10-03 に調べた。tap の formula と配布物の日付を見ただけで、入れてはいない
- Homebrew の `wezterm` は macOS だけの cask（`wezterm@nightly` も同じ）なので、Linux では公式の tap の formula を名前を全部書いて入れる（`brew install wezterm/wezterm-linuxbrew/wezterm`、nightly は `--HEAD`）
- tap の `Formula/wezterm.rb` は、AppImage を 1 つ落として `bin/wezterm` に置くだけ（`bin.install img => "wezterm"`）
  - stable は `20240203-110809-5046fc22`（tap の最後の更新も 2024-02-03）。自分用の設定は nightly が前提
  - `--HEAD` は `WezTerm-nightly-Ubuntu20.04.AppImage` を指す。GitHub の `nightly` の配布物で、この AppImage の `Last-Modified` は 2026-03-18 だった（`wezterm-gui-nightly-centos9.rpm` は 2026-10-03）
  - COPR の `rhel-9-x86_64` と `rhel-9-aarch64` は、どちらも 2026-10-02 にメタデータが更新されていた（`repomd.xml` の `revision`）
  - nightly の AppImage に aarch64 のものは無い（`*-aarch64.AppImage` は 404）
  - `.desktop` とアイコン、`wezterm-mux-server`、`/etc/profile.d/wezterm.sh` のシェル統合、補完は入らない。AppImage なので FUSE2 も要る（[付録](#付録-appimage-の実測)）
  - nightly の更新は `brew upgrade` に乗らず、入れ直す（公式ドキュメント）

#### Windows 11 で入れる経路

Windows 11 で WezTerm の nightly を入れる経路を比べた（2026-10-03 時点。[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **GitHub の `nightly` の `WezTerm-nightly-setup.exe`** | Inno Setup のインストーラ。同じリリースに `.sha256` がある。`C:\Program Files\WezTerm` に入れ、PC 全体の `PATH`・スタートメニュー・右クリックのメニュー・アンインストールの登録を作る。管理者が要る。Authenticode の署名は無い。更新は手作業（同じブロックを貼り直す） | **採用** |
| winget の `wez.wezterm.nightly` | ある（`20260929-043349-cab25161`、Inno Setup、`machine`、依存に `Microsoft.VCRedist.2015+.x64`）。中身は同じ URL のインストーラで、定義の sha256 は winget の bot が 1〜11 日おきに直す。インストーラは毎日作り直されて sha256 が変わるので、直されていない日は一致せずに入らない（2026-09-21 から 10-02 までは直されていなかった） | 不採用（入るかどうかが日による） |
| winget の `wez.wezterm` | stable の `20240203-110809-5046fc22`（2024-02-03）。WezTerm の公式の文書が案内しているのはこれ | 不採用（自分用の設定は nightly が前提） |
| scoop の `versions/wezterm-nightly` | ある（版は `nightly`）。nightly の zip を `~\scoop\apps\wezterm-nightly\current` に展開する。scoop は nightly の版の sha256 を確かめない（`Downloaded files won't be verified.`）。`current` はジャンクションで、SSH のセッションからはたどれない（[Windows の OpenSSH サーバーの scoop のツールを SSH のセッションで使う（任意）](windows-openssh-server.md#scoop-のツールを-ssh-のセッションで使う任意)） | 不採用（`C:\Program Files\WezTerm` に入らず、確かめられない） |
| scoop の `extras/wezterm`・Chocolatey の `wezterm` | どちらも stable の `20240203-110809-5046fc22`。Chocolatey に nightly は無い | 不採用 |
| nightly の zip（`WezTerm-windows-nightly.zip`） | インストーラと同じ実行ファイル（と `wezterm.pdb`）。どこに展開してもよく、管理者が要らない。`PATH`・スタートメニュー・アンインストールは自分で用意する | 不採用（`C:\Program Files\WezTerm` に置くなら、インストーラと同じことを手で行うことになる） |

- **Windows 11 では、インストーラを直接取って、`.sha256` と比べてから黙って動かす方式を採用した**
  - [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md)が前提にしている `C:\Program Files\WezTerm` に、公式の形のまま入る
  - `.sha256` は同じリリースに置かれたものなので、分かるのは壊れていないことまで。署名が無いので、ほかに本物かを確かめる手立ては無い（winget の定義の sha256 も、同じファイルから bot が取ったもの）
  - winget の `wez.wezterm.nightly` は、入れられる日なら 1 行で済み `VCRUNTIME140.dll` の依存も入るが、入るかどうかが日によるので採らなかった。依存の再頒布可能パッケージだけは winget で入れる（[Windows 11 で使う](#windows-11-で使う)の手順 3）
- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](syncthing.md) と同じく後ろの節に分けた

### 完了時点の状態

AlmaLinux 10 の実機の出力（Windows 11 では流していない。Windows 11 で入るものは、[Windows 11 で使う](#windows-11-で使う)の手順 4 の補足）:

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

### 注意点

- **EL9 向けバイナリを EL10 で使っている。** 作者はこの組み合わせを保証していない
  - いまは EL9/EL10 のライブラリ soname がすべて一致しているので動く
  - 将来 COPR 側のビルド環境（EL9）と EL10 の間で soname が食い違えば、`dnf upgrade` が依存関係で止まるか、入っても起動しなくなる
  - 止まったときは `dnf upgrade --exclude='wezterm*'` で他を先に上げ、COPR に `epel-10` chroot が追加されていないか[プロジェクトページ](https://copr.fedorainfracloud.org/coprs/wezfurlong/wezterm-nightly/)を見る
  - 追加されていたら、`sudo dnf copr remove wezfurlong/wezterm-nightly` → `sudo dnf copr enable wezfurlong/wezterm-nightly`（chroot 省略）で乗り換えられる
- **nightly は毎日変わる。** `dnf upgrade` のたびに WezTerm も更新される
  - 安定版に固定したければ、COPR ではなく GitHub Releases の安定版 rpm（`wezterm-<version>-1.centos9.rpm`、こちらも EL10 向けは無い）か Flathub を使う
- **`TERM` は既定の `xterm-256color` のまま**。EL10 の `ncurses-base` に `wezterm` の terminfo は無い（`infocmp wezterm` → rc=1、`ncurses-term` も未導入）

  設定で `term = "wezterm"` にするなら、先に公式ドキュメントの手順で terminfo を入れる（本書では**未実行**）:

  ```bash
  tempfile=$(mktemp) \
    && curl -o "$tempfile" https://raw.githubusercontent.com/wezterm/wezterm/main/termwiz/data/wezterm.terminfo \
    && tic -x -o ~/.terminfo "$tempfile" \
    && rm "$tempfile"
  ```

- **`/etc/profile.d/wezterm.sh` は全ユーザーの対話シェルに読み込まれる。** WezTerm 以外の端末でも OSC シーケンスを出す（大半の端末は無視する）
  - `bash-preexec` を内蔵しているので、`PROMPT_COMMAND` や `DEBUG` trap を自前で使っている環境では干渉に注意
  - 無効化は `WEZTERM_SHELL_SKIP_ALL=1`
- **既存の `_copr:...yazi.repo` など EL10 向け COPR と混在させても問題ない。** repo ごとに `baseurl` の chroot が違うだけ
- **Windows 11 のインストーラと実行ファイルには署名が無い**: 本物かどうかは確かめられず、`.sha256` で分かるのは壊れていないことまで（[選択した方針](#選択した方針)）
  - ブラウザで取ると、SmartScreen が警告するはず（本書は `curl.exe` で取る。確かめていない）
- **Windows 11 の WezTerm には `VCRUNTIME140.dll` が要る**: インストーラは入れない（[Windows 11 で使う](#windows-11-で使う)の手順 3）
- **Windows 11 の nightly は自分では上がらず、winget・scoop の管理にも乗らない**: 上げるのは[Windows 11 の更新](#windows-11-の更新)
- **Windows 11 では、stable と nightly が同じ登録を使う**: インストーラの `AppId` が同じなので、PC に入るのはどちらか 1 つ。後から入れた方が上書きするはず（確かめていない）
- **Windows 11 で管理者の窓から起動すると、WezTerm も管理者で動く**: 起動はスタートメニューから行う
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
- [Claude Code の Remote Control（Windows）](windows-claude-remote-control.md) — `C:\Program Files\WezTerm\wezterm.exe` を使う手順書
- [Windows 11 の初期設定](windows-setup.md) — 貼り付けの設定（手順 16〜19）と、この文書を通す順

---

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

**[Windows 11 で使う](#windows-11-で使う)の手順 4 のブロック**を、パスの `\` を `/` に替え、`$env:WINDIR`・`$env:TEMP`・`C:\Program Files\WezTerm` を一時的なディレクトリにして流した。`System32/curl.exe` は Linux の `curl` を呼ぶ小さなスクリプト（失敗・壊れたファイル・中身の違う `.sha256` を作れる）、`Get-Process` と `Start-Process` は偽物（`Start-Process` は引数を出し、`wezterm.exe` の代わりに版を出すスクリプトを置く）、管理者の判定は値に置き換えた:

- 通常: 本物の `.sha256` とインストーラを取り、sha256 が一致し、`Start-Process` に `-FilePath <一時フォルダー>/WezTerm-nightly-setup.exe` と `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOCLOSEAPPLICATIONS /LOG="<一時フォルダー>/setup.log"` が渡った。`WezTerm-nightly-setup.exe: sha256 一致、インストーラの終了コード 0` と `wezterm 20260929-043349-cab25161` が出て、一時フォルダーが消えた
- 管理者でない・`vcruntime140.dll` が無い・WezTerm が動いている: それぞれの `中断:` で止まり、何も取らなかった
- `curl` の失敗: `中断: WezTerm-nightly-setup.exe.sha256 を取れない`
- 取ったインストーラに 1 バイト足したもの: `中断: WezTerm-nightly-setup.exe の sha256 が一致しない`（`Start-Process` は呼ばれず、取ったものは一時フォルダーに残った）
- `.sha256` の中身が `Not Found`: `中断: WezTerm-nightly-setup.exe.sha256 に sha256 の行が無い`
- インストーラの終了コードが 4: `中断: インストーラが終了コード 4 で終わった（ログは <一時フォルダー>/setup.log）`

**[Windows 11 のロールバック](#windows-11-のロールバック)の手順 1 のブロック**を、`C:\Program Files\WezTerm` を一時的なディレクトリにして流した。`Get-ItemProperty`・`Test-Path`（登録のキーだけ）・`Get-Process`・`Start-Process` を偽物にし、`Start-Process` は 3 秒後に登録とフォルダーを消す（アンインストーラの写しが後から消すのをまねる）:

- 通常: `Start-Process` に `-FilePath C:\Program Files\WezTerm\unins000.exe`（`UninstallString` の引用符の中）と `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART` が渡り、3 秒待ってから `False` が 2 行出た
- 登録が無い・`UninstallString` が別の形（`MsiExec.exe /X{0000}`）・WezTerm が動いている・アンインストーラの終了コードが 1: それぞれの `中断:` で止まった
- フォルダーに `wezterm.lua` が残るとき: 60 秒待ってから `False` と `True` が出た

[Windows 11 で使う](#windows-11-で使う)の手順 2 のブロックも、管理者の判定を値に置き換えて流し、`VCRuntime` が偽物の `vcruntime140.dll` の有無で `True` と `False` になることを見た。

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. インストーラが黙って入り、`PATH`・スタートメニュー・右クリックのメニュー・アンインストールの登録ができること。前の版が入っている PC で上書きできること
1. `VCRUNTIME140.dll` の無い PC で WezTerm が起動しないことと、[Windows 11 で使う](#windows-11-で使う)の手順 3 で起動するようになること
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
