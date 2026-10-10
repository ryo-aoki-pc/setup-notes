# HackGen Console NF インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は上流の zip）

## 実施手順

- [検証記録](verification/hackgen.md)・[参考資料](reference/hackgen.md)・[ロールバックと注意点](extra/hackgen.md)

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（Windows PowerShell 5.1 に貼る。管理者の権限は要らない）
> - **前提**: [AlmaLinux 10 の初期設定の手順 46〜48](almalinux-setup.md#実施手順) で Homebrew を入れてあること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、フォントも自分のホームの `~/.local/share/fonts` に入るため）

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 手順の後: 端末のフォントにするなら[WezTerm で使う（任意）](#wezterm-で使う任意)。以後は[更新](#更新)・[ロールバック](extra/hackgen.md#ロールバック)

1. 変数を設定する。

   ```bash
   HACKGEN_FAMILY='HackGen Console NF'   # 確認と設定に使うファミリー名。<HACKGEN_FAMILY>
   printf '%-15s = %s\n' HACKGEN_FAMILY "${HACKGEN_FAMILY}"
   ```

   - **編集が必須の変数は無い**。確認と WezTerm の設定に使うファミリー名で、既定のまま進められる
   - 文字幅が半角 3:全角 5 の版を使いたいときだけ、`HackGen35 Console NF` に変える（同じ手順で一緒に入る。[検証記録](verification/hackgen.md)・[参考資料](reference/hackgen.md)）
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

1. `unzip` が入っているか確かめる。

   ```bash
   command -v unzip || echo 'unzip は未導入'
   ```

   - Homebrew は cask の zip を展開するのに `unzip` を使う
   - パスが出れば、手順 3 は飛ばす
   - `unzip は未導入` と出たら、手順 3 で入れる

1. `unzip` が未導入のときだけ、`unzip` を入れる。

   ```bash
   sudo dnf install -y unzip
   ```

1. HackGen を Homebrew の cask で入れる。

   ```bash
   brew install --cask font-hackgen-nerd
   ```

   - `==> Moving Font 'HackGenConsoleNF-Regular.ttf' to '/home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf'` のような行が 4 つ出る
   - `font-hackgen-nerd was successfully installed!` で終わる

1. HackGen が入ったか確かめ、かな・漢字・記号・アイコンが入っているかも見る。

   ```bash
   brew list --cask --versions font-hackgen-nerd
   ls ~/.local/share/fonts/
   fc-list : family style file | grep HackGen
   fc-match "${HACKGEN_FAMILY:?手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}"
   for cp in 3042 6f22 e0b0 f09b; do printf 'U+%s: ' "${cp}"; fc-list ":charset=${cp}" family | grep -c -x -F "${HACKGEN_FAMILY:?手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}"; done
   ```

   - `font-hackgen-nerd 2.10.0`、4 つの `.ttf`、`HackGen Console NF` と `HackGen35 Console NF` の Regular / Bold の 4 行が出る
   - `fc-match` が `HackGenConsoleNF-Regular.ttf: "HackGen Console NF" "Regular"` を返せばよい
   - `fc-match` は、名前が合わないときに別のフォントを黙って返すので、**ファイル名が HackGen であることを確かめる**
   - 最後の `for` で、かな・漢字・Powerline 記号・Nerd Fonts のアイコンが、このフォントに入っていることを確かめる
   - 4 行とも `1` なら入っている（`あ` / `漢` / Powerline の三角 / GitHub のアイコン）

---

## WezTerm で使う（任意）

- [WezTerm](wezterm-nightly.md) の端末フォントを HackGen Console NF にする
- **[wezterm-nightly.md の設定ファイル](wezterm-nightly.md#設定ファイル)の最小の例（`~/.config/wezterm/wezterm.lua`）を置いてある前提**で、その `config.font` の行を書き換える
- `~/.wezterm.lua` を使っている場合は、そちらのファイルに読み替える（両方あると `~/.wezterm.lua` だけが読まれる）
- 自分用の設定（[ryo-aoki-pc/wezterm](https://github.com/ryo-aoki-pc/wezterm)。[wezterm-nightly.md の設定ファイル](wezterm-nightly.md#設定ファイル)）はフォントの候補の先頭が HackGen Console NF なので、この節は要らない

1. 書き換える `config.font` の行があるか見る。

   ```bash
   grep -n '^config.font = ' ~/.config/wezterm/wezterm.lua
   ```

   - `3:config.font = wezterm.font 'Noto Sans Mono'` のように 1 行出ればよい
   - 何も出なければ、`return config` の前に `config.font = wezterm.font 'HackGen Console NF'` を自分で足す
   - **次の手順は、行があるのを確かめてから貼る**

1. 行を書き換えて、WezTerm がどのフォントで文字を描くかを確かめる。

   ```bash
   sed -i "s/^config.font = .*/config.font = wezterm.font '${HACKGEN_FAMILY:?手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}'/" ~/.config/wezterm/wezterm.lua
   grep -n '^config.font = ' ~/.config/wezterm/wezterm.lua
   wezterm ls-fonts --text 'aあ漢→'
   ```

   - 4 文字とも `wezterm.font("HackGen Console NF", ...)` と `/home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf, FontConfig` が出ればよい
   - **`→` が `cells=1`（半角）になる**のが Console 版の特徴で、`あ` / `漢` は `cells=2`
   - 起動中の WezTerm には、保存した時点で反映される（wezterm-nightly.md の設定ファイルの節）

---

## 更新

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 の更新](#windows-11-の更新)

1. HackGen を上げる。

   ```bash
   brew upgrade --cask font-hackgen-nerd
   ```

   - 新しい版が無ければ `Warning: Not upgrading font-hackgen-nerd, the latest version is already installed` と出て終わる

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows で行う**。この節の手順 1 で Windows PowerShell（5.1）を開き、この節の手順 2・3 と、[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/hackgen.md#windows-11-のロールバック)のブロックをそこに貼る。管理者の権限は要らない（自分のユーザーに入れる）
> - 前提: [Windows 11 の初期設定の手順 16〜19](windows-setup.md#実施手順)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - **この節の手順 4 で、サインアウトしてサインインし直す**（登録したフォントは、サインインのときに読み込まれる）

- 上から順にコードブロックを貼る。変数は無い（[実施手順](#実施手順)の手順 1 の `HACKGEN_FAMILY` は AlmaLinux 10 だけで使う）
- 手順の後: 以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](extra/hackgen.md#windows-11-のロールバック)
- [Windows 11 の初期設定](windows-setup.md)と一緒に行うなら、その手順 55 の再起動より前にこの節の手順 3 までを行えば、この節の手順 4 は要らない

1. Windows で、Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」でなくてよい）
   - Windows Terminal の中に開いた窓に複数行のブロックを貼ると出る警告では、「強制的に貼り付け」を押す

1. HackGen がまだ入っていないことを確かめる。

   ```powershell
   Get-Item -LiteralPath 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' -ErrorAction SilentlyContinue | ForEach-Object { $_.Property -like 'HackGen*' }
   Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts", "$env:WINDIR\Fonts" -Filter 'HackGen*' -ErrorAction SilentlyContinue | Format-Table Name, DirectoryName
   ```

   - どちらも何も出なければ、入っていない
   - 自分のユーザーの登録と `%LOCALAPPDATA%` のファイルが出たら、この節の手順で入れたもの（この節の手順 3 は何度貼ってもよい）
   - `C:\Windows\Fonts` のファイルが出たら、PC 全体に入っている（ほかの方法で入れたもの）。そのまま使えるので、この節は要らない

1. HackGen Console NF の zip を取り、sha256 を確かめて自分のユーザーのフォントに入れる。

   ```powershell
   & {
     $ver = '2.10.0'
     $sha256 = 'F8ABD483D5EDFAD88A78ED511978F43C83B43C48E364AA29EBE4A68217474428'
     $fonts = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
     $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
     $tmp = "$env:TEMP\hackgen-setup"
     $zip = "$tmp\HackGen_NF_v$ver.zip"
     Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
     New-Item -ItemType Directory -Path $tmp | Out-Null
     & "$env:WINDIR\System32\curl.exe" -fsSL -o $zip "https://github.com/yuru7/HackGen/releases/download/v$ver/HackGen_NF_v$ver.zip"
     if ($LASTEXITCODE -ne 0) { Write-Error "中断: HackGen_NF_v$ver.zip を取れない"; return }
     if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $sha256) { Write-Error "中断: HackGen_NF_v$ver.zip の sha256 が一致しない"; return }
     Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
     $ttf = @(Get-ChildItem -LiteralPath "$tmp\HackGen_NF_v$ver" -Filter '*.ttf')
     if ($ttf.Count -ne 4) { Write-Error "中断: zip の中の ttf が 4 つではない（$($ttf.Count)）"; return }
     New-Item -ItemType Directory -Force -Path $fonts | Out-Null
     icacls.exe $fonts /grant '*S-1-15-2-1:(OI)(CI)(RX)' '*S-1-15-2-2:(OI)(CI)(RX)' | Out-Null
     if (-not (Test-Path -LiteralPath $key)) { New-Item -Path $key | Out-Null }
     foreach ($f in $ttf) {
       $dst = Join-Path $fonts $f.Name
       if (-not (Test-Path -LiteralPath $dst) -or (Get-FileHash -LiteralPath $dst).Hash -ne (Get-FileHash -LiteralPath $f.FullName).Hash) {
         try { Copy-Item -LiteralPath $f.FullName -Destination $dst -Force -ErrorAction Stop } catch { Write-Error "中断: $($f.Name) を置けない（$($_.Exception.Message)）"; return }
       }
       New-ItemProperty -Path $key -Name "$($f.BaseName) (TrueType)" -Value $dst -PropertyType String -Force | Out-Null
     }
     Remove-Item -LiteralPath $tmp -Recurse -Force
     Get-ItemProperty -LiteralPath $key | Select-Object -Property 'HackGen*' | Format-List
   }
   ```

   - `HackGen35ConsoleNF-Bold (TrueType) : C:\Users\<WIN_USER>\AppData\Local\Microsoft\Windows\Fonts\HackGen35ConsoleNF-Bold.ttf` の形の行が 4 つ出ればよい
   - `中断:` で始まるエラーが出たら、そこで止まっている（取ってきたものは `%TEMP%\hackgen-setup` に残る。次に貼ったときに消して作り直す）
   - 何度貼ってもよい（同じファイルは置き直さない）
   - アプリで使えるのは、この節の手順 4 でサインインし直した後

1. この PC でサインアウトし、サインインし直す。

   - スタートメニューのユーザーのアイコンから「サインアウト」し、サインインし直す（再起動でもよい）
   - [Windows 11 の初期設定](windows-setup.md)の手順 55 の再起動をこの後に行うなら、この手順は要らない

1. 設定のフォントの一覧で、HackGen Console NF が出ることを確かめる。

   - 設定 → 個人用設定 → フォント を開き、「HackGen」で探すと、`HackGen Console NF` と `HackGen35 Console NF` が出る（どちらも「2 フォント フェイス」）
   - ライセンス認証していない Windows では、フォントの画面の検索欄が使えないことがある。そのときは一覧をスクロールして探す
   - メモ帳のフォントの一覧に出ても同じ
   - 端末のフォントにするなら、アプリの設定にファミリー名 `HackGen Console NF` を書く（WezTerm は `config.font = wezterm.font 'HackGen Console NF'`。自分用の設定（`ryo-aoki-pc/wezterm`）は、もうこのフォントを使う）

---

## Windows 11 の更新

- 上流は sha256 を出していないので、この文書の版と sha256（[Windows 11 で使う](#windows-11-で使う)の手順 3）を確かめて上げてから入れ直す
- この節の手順 1 は、Windows PowerShell（5.1）に貼る

1. HackGen の新しい版が出ているかを確かめる。

   ```powershell
   (Invoke-RestMethod -Uri https://api.github.com/repos/yuru7/HackGen/releases/latest).tag_name
   ```

   - `v2.10.0` なら、新しい版は無い。この節の手順 2 は行わない
   - 違う版なら、この文書の[Windows 11 で使う](#windows-11-で使う)の手順 3 の `$ver` と `$sha256` を、その版の zip と、その zip から計算して確認したハッシュ値に合わせて直してから貼る（直さなければ、固定した旧版を再び入れるだけで更新にはならない）

1. 新しい版にするときだけ、今の版を外してから入れ直す。

   - [Windows 11 のロールバック](extra/hackgen.md#windows-11-のロールバック)の手順 1〜3 を行う（読み込まれているファイルは置き換えられないため）
   - 続けて、直した[Windows 11 で使う](#windows-11-で使う)の手順 3〜5 を行う
