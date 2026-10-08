# WezTerm Nightly インストール手順（AlmaLinux 10 は公式 COPR の EL9 ビルドを流用 / Windows 11 は nightly のインストーラ）

## 実施手順

- [検証記録](verification/wezterm-nightly.md)・[参考資料](reference/wezterm-nightly.md)

- [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入したホストでは、参照先の WezTerm 導入手順で、通常のシェル統合の `~/.bashrc` への追記は不要。WezTerm の設定リポジトリの clone は必要。WSL で Windows 側のパスを直接読む場合は参照先の任意節を行う

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（管理者の Windows PowerShell 5.1 に貼る）
> - **すべて対象ホスト上で実行する**
> - **手順 1 と手順 3 には対話入力がある**（COPR の有効化の `[y/N]` と、COPR の GPG 鍵の取り込み）。答えてから次の手順を貼る

- 上から順にコードブロックを貼る
- 手順の後: 設定を書く場所と、自分用の設定（`ryo-aoki-pc/wezterm`）への案内は[設定ファイル](#設定ファイル)。以後は[更新](#更新)・[ロールバック](#ロールバック)

1. chroot を明示して、COPR を有効化する。

   ```bash
   sudo dnf copr enable wezfurlong/wezterm-nightly "rhel-9-$(uname -m)"
   ```

   - chroot は `uname -m` から `rhel-9-x86_64` か `rhel-9-aarch64` になる（COPR に EL10 向けが無いので EL9 向けを使う）
   - 有効化してよいか `[y/N]` で聞かれる
   - **次の手順は、`[y/N]` に答えてから貼る**（続けて貼ると答えとして食われる）

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

   - GNOME の端末から `wezterm` で動作を確認した場合は、手順 5 は飛ばす
1. ssh などグラフィカルでないシェルから確かめるときだけ、ウィンドウを開いて即終了させる。

   ```bash
   env -i HOME="$HOME" USER="$USER" PATH=/usr/bin:/bin \
       WAYLAND_DISPLAY=wayland-0 XDG_RUNTIME_DIR="/run/user/$(id -u)" XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=GNOME \
       timeout 30 wezterm start --always-new-process -- sh -c 'exit 0'; echo "rc=$?"
   ```

   - ログイン中の Wayland セッションを指定して、ウィンドウを開く
   - `rc=0` なら、ウィンドウが開いて閉じている（`exit_behavior` の既定が `Close` なので、子プロセスが終わるとウィンドウも閉じる）

---

## 設定ファイル

- パッケージ（Windows 11 ではインストーラ）は設定ファイルを置かない。無ければ組み込みの既定値で動く

| 優先 | 場所 | 用途 |
|---|---|---|
| 1 | `wezterm --config-file <path>` | 一時的に別の設定で起動する |
| 2 | 環境変数 `WEZTERM_CONFIG_FILE` | 同上（環境ごとに切り替える） |
| 3 | `~/.wezterm.lua` | **1 ファイルで済む設定はここ**（公式の推奨） |
| 4 | `${XDG_CONFIG_HOME}/wezterm/wezterm.lua`（`XDG_CONFIG_HOME` を設定している場合のみ） | 複数ファイルに分ける設定 |
| 5 | `~/.config/wezterm/wezterm.lua`（`XDG_CONFIG_HOME` 未設定のとき） | 同上 |

- **Windows 11 では**、`~` は `%USERPROFILE%`（`C:\Users\<WIN_USER>`）。置くのは `%USERPROFILE%\.wezterm.lua` か `%USERPROFILE%\.config\wezterm\wezterm.lua`
  - 表の 2 と 3 の間に、`wezterm.exe` と同じフォルダーの `wezterm.lua`（`C:\Program Files\WezTerm\wezterm.lua`）が入る。USB メモリで持ち運ぶとき用で、公式は勧めていない
- **自分用の設定**は [ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm) にある（Tokyo Night 系の配色・ピル型タブ・ステータスバー・シェル統合の設定）
  - 入れ方は、その [docs/install.md](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md)（本書と同じ書式の手順書）。`~/.config/wezterm` に clone する。シェル統合は bash の共通設定が読むので、参照先の手順 5〜7（直接追記）は行わず、手順 8 で端末を開き直す
  - Windows 11 では、同じブロックを Git for Windows の Git Bash（[git.md](git.md)）に貼る（docs/install.md のとおり）
  - どこを変えればよいかは [設定参照の「カスタマイズの勘所」](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/reference/configuration.md#カスタマイズの勘所)
  - nightly が前提（stable では未知のオプションで設定エラーになる）。本書で入れるのは、AlmaLinux 10 も Windows 11 も nightly
  - フォントは HackGen Console NF（[hackgen.md](hackgen.md)。Windows 11 は同書の[Windows 11 で使う](hackgen.md#windows-11-で使う)）
  - AlmaLinux 10 だけ: 本書の RPM が置く `/etc/profile.d/wezterm.sh` の公式 Bash 統合を保ち、この設定が Starship の後でプロンプトの区切りと完了通知を補う（[シェル統合の仕様](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/reference/shell-integration.md#シェル統合)）
    - 公式統合は無効にせず、共通の bash 設定の順序で読み、新しいタブを開く（[導入手順の注意点](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#注意点)）
  - Windows 11 のインストーラはシェル統合を入れない。設定が無いときに開くシェルは `cmd.exe`（`%COMSPEC%`）で、この設定は Git Bash を既定にし、Git Bash と PowerShell のシェル統合を設定の中から読ませる（[シェル統合の仕様](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/reference/shell-integration.md#シェル統合)）
  - この設定を入れるなら、この節の手順 1 は貼らない（`~/.config/wezterm` が空でないと clone できない）
  - `~/.wezterm.lua` があると、clone した設定は読まれない

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
- 手順の後: 設定ファイルの置き場所と自分用の設定は[設定ファイル](#設定ファイル)。以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](#windows-11-のロールバック)
- もう WezTerm が `C:\Program Files\WezTerm` に入っている PC でも、同じ手順で今の nightly に上書きできる

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

1. `VCRUNTIME140.dll` が無いときだけ、Visual C++ の再頒布可能パッケージを入れる。

   ```powershell
   winget install --exact --id Microsoft.VCRedist.2015+.x64 --source winget --scope machine --accept-source-agreements --accept-package-agreements
   Test-Path -LiteralPath "$env:WINDIR\System32\vcruntime140.dll"
   ```

   - `インストールが完了しました`（英語の Windows では `Successfully installed`）と、`True` が出ればよい
   - winget が再起動を求めたら、再起動してから、この節の手順 1 からやり直す
   - `winget` が見つからないというエラーになったら、Microsoft Store で「アプリ インストーラー」を更新してから始める

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
   - `取れない` と `sha256 が一致しない` は、nightly が入れ替わる最中に取ったときにも出る。少し待って貼り直す
   - 何度貼ってもよい（同じ場所に上書きする）

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

1. スタートメニューから WezTerm を起動し、窓が開くことを確かめる。

   - スタートメニューで「WezTerm」を探し、クリックして開く
   - 窓が開き、中でシェルが動けばよい。設定ファイルが無ければ `cmd.exe` が開く（自分用の設定では Git Bash。[設定ファイル](#設定ファイル)）
   - 窓の中で `wezterm --version` を打つと、この節の手順 5 と同じ版が出る
   - 窓が開かずに終わったら、`%USERPROFILE%\.local\share\wezterm\wezterm-gui.exe-log-<番号>.txt` を見る
     - `The OpenGL implementation is too old to work with glium` なら、3D の描画の無い VM などで OpenGL が使えない
     - その場で開くなら、`& 'C:\Program Files\WezTerm\wezterm-gui.exe' --config prefer_egl=true` で開く
     - いつも開くようにするなら、設定の `config` に `config.prefer_egl = true` を足す。設定ファイルが無ければ、`%USERPROFILE%\.wezterm.lua` に `local wezterm = require 'wezterm'`・`local config = wezterm.config_builder()`・`config.prefer_egl = true`・`return config` の 4 行を書く
     - 自分用の設定（`~/.config/wezterm`）を使うなら、`~/.wezterm.lua` は作らない（[設定ファイル](#設定ファイル)のとおり、clone した設定が読まれなくなる）
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

---

## 注意点

- **EL9 向けバイナリを EL10 で使っている。** 作者はこの組み合わせを保証していない
  - いまは EL9/EL10 のライブラリ soname がすべて一致しているので動く
  - 将来 COPR 側のビルド環境（EL9）と EL10 の間で soname が食い違えば、`dnf upgrade` が依存関係で止まるか、入っても起動しなくなる
  - 止まったときは `dnf upgrade --exclude='wezterm*'` で他を先に上げ、COPR に `epel-10` chroot が追加されていないか[プロジェクトページ](https://copr.fedorainfracloud.org/coprs/wezfurlong/wezterm-nightly/)を見る
  - 追加されていたら、`sudo dnf copr remove wezfurlong/wezterm-nightly` → `sudo dnf copr enable wezfurlong/wezterm-nightly`（chroot 省略）で乗り換えられる
- **nightly は毎日変わる。** `dnf upgrade` のたびに WezTerm も更新される
  - 安定版に固定したければ、COPR ではなく GitHub Releases の安定版 rpm（`wezterm-<version>-1.centos9.rpm`、こちらも EL10 向けは無い）か Flathub を使う
- **`TERM` は既定の `xterm-256color` のまま**。EL10 の `ncurses-base` に `wezterm` の terminfo は無い（`infocmp wezterm` → rc=1、`ncurses-term` も未導入）

  設定で `term = "wezterm"` にするなら、先に公式ドキュメントの手順で terminfo を入れる:

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
- **Windows 11 のインストーラと実行ファイルには署名が無い**: 本物かどうかは確かめられず、`.sha256` で分かるのは壊れていないことまで（[選択した方針](reference/wezterm-nightly.md#選択した方針)）
  - ブラウザで取得したファイルでは SmartScreen が警告することがある。本書では `curl.exe` で取得する
- **Windows 11 の WezTerm には `VCRUNTIME140.dll` が要る**: インストーラは入れない（[Windows 11 で使う](#windows-11-で使う)の手順 3）
- **Windows 11 の nightly は自分では上がらず、winget・scoop の管理にも乗らない**: 上げるのは[Windows 11 の更新](#windows-11-の更新)
- **Windows 11 では、stable と nightly が同じ登録を使う**: インストーラの `AppId` が同じなので、PC に入るのはどちらか 1 つ。後から入れた方が上書きするはず
- **Windows 11 で管理者の窓から起動すると、WezTerm も管理者で動く**: 起動はスタートメニューから行う
