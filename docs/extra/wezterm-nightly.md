# WezTerm Nightly インストール手順（AlmaLinux 10 は公式 COPR の EL9 ビルドを流用 / Windows 11 は nightly のインストーラ）のロールバックと注意点

[手順書](../wezterm-nightly.md)・[検証記録](../verification/wezterm-nightly.md)・[参考資料](../reference/wezterm-nightly.md)

- 「手順 N」は[手順書](../wezterm-nightly.md#実施手順)の手順 N、「本書」「この文書」は手順書を指す

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

## Windows 11 のロールバック

- この節の手順 1 は、管理者の Windows PowerShell（5.1）に、WezTerm の窓をすべて閉じてから貼る
- [Claude Code の Remote Control（Windows）](../windows-claude-remote-control.md)は WezTerm を使う。使っているなら、先に同書の[ロールバック](windows-claude-remote-control.md#ロールバック)を行う
- 設定ファイル（`%USERPROFILE%\.wezterm.lua`・`%USERPROFILE%\.config\wezterm`）は消えない。要らなければ手で消す（自分用の設定は、その [docs/install.md のロールバック](https://github.com/ryo-aoki-pc/wezterm/blob/main/docs/install.md#ロールバック)を Git Bash で行う）
- [Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の手順 3 で入れた Visual C++ の再頒布可能パッケージは、ほかのアプリも使うので消さない

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
- **Windows 11 のインストーラと実行ファイルには署名が無い**: 本物かどうかは確かめられず、`.sha256` で分かるのは壊れていないことまで（[選択した方針](../reference/wezterm-nightly.md#選択した方針)）
  - ブラウザで取得したファイルでは SmartScreen が警告することがある。本書では `curl.exe` で取得する
- **Windows 11 の WezTerm には `VCRUNTIME140.dll` が要る**: インストーラは入れない（[Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の手順 3）
- **Windows 11 の nightly は自分では上がらず、winget・scoop の管理にも乗らない**: 上げるのは[Windows 11 の更新](../wezterm-nightly.md#windows-11-の更新)
- **Windows 11 では、stable と nightly が同じ登録を使う**: インストーラの `AppId` が同じなので、PC に入るのはどちらか 1 つ。後から入れた方が上書きするはず
- **Windows 11 で管理者の窓から起動すると、WezTerm も管理者で動く**: 起動はスタートメニューから行う
