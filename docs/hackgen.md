# HackGen Console NF インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は上流の zip）

## 実施手順

> [!IMPORTANT]
> - **この実施手順は AlmaLinux 10 のもの**。Windows 11 の PC は、[Windows 11 で使う](#windows-11-で使う)から通す（Windows PowerShell 5.1 に貼る。管理者の権限は要らない）
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、フォントも自分のホームの `~/.local/share/fonts` に入るため）

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 端末のフォントにするなら[WezTerm で使う（任意）](#wezterm-で使う任意)。以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **この実施手順（AlmaLinux 10）は x86_64 のクリーン VM で本実行済み**（2026-10-06）で、コンテナでも検証した。実機では本実行しておらず、aarch64 でも通していない。画面での見た目も確かめていない（[対象と検証環境](#対象と検証環境)）。

1. 変数を設定する。

   ```bash
   HACKGEN_FAMILY='HackGen Console NF'   # 確認と設定に使うファミリー名。<HACKGEN_FAMILY>
   printf '%-15s = %s\n' HACKGEN_FAMILY "${HACKGEN_FAMILY}"
   ```

   - **編集が必須の変数は無い**。確認と WezTerm の設定に使うファミリー名で、既定のまま進められる
   - 文字幅が半角 3:全角 5 の版を使いたいときだけ、`HackGen35 Console NF` に変える（同じ手順で一緒に入る。この手順の補足）
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

   <details>
   <summary>補足: 入るフォントの種類</summary>

   `${HACKGEN_FAMILY}` は**この文書の中だけで使うシェル変数**で、fontconfig や WezTerm が読む環境変数ではない。

   [HackGen（白源）](https://github.com/yuru7/HackGen)は、英数字の Hack と、かな・漢字の源柔ゴシックを合成したプログラミング用の等幅フォント。upstream の README が挙げるファミリーは次の 4 つで、このうち Console の 2 ファミリーには Nerd Fonts のアイコンを足した **NF** 版がある。

   | ファミリー | 内容（upstream の README の要約） |
   |---|---|
   | HackGen | 文字幅が半角 1:全角 2 の通常版。ASCII の英数字記号は Hack、それ以外の記号とかな・漢字は源柔ゴシック |
   | **HackGen Console** | Hack の字体を除外せずに全部当てた版。矢印などの多くの記号が半角で出るので、コンソール向け |
   | HackGen35 | 通常版の文字幅を半角 3:全角 5 にした版。英数字が大きく出る |
   | HackGen35 Console | HackGen Console の文字幅を半角 3:全角 5 にした版 |

   本書で入れる Homebrew の cask `font-hackgen-nerd` の中身は、upstream のリリースの `HackGen_NF_v2.10.0.zip` そのもので、**NF 版は Console の 2 ファミリーだけ**が入っている（通常版の NF は無い）。

   ```
   $ unzip -l HackGen_NF_v2.10.0.zip
     Length      Date    Time    Name
   ---------  ---------- -----   ----
           0  12-29-2024 16:11   HackGen_NF_v2.10.0/
    13462380  12-29-2024 16:04   HackGen_NF_v2.10.0/HackGen35ConsoleNF-Bold.ttf
    12922844  12-29-2024 16:04   HackGen_NF_v2.10.0/HackGen35ConsoleNF-Regular.ttf
    13464288  12-29-2024 16:04   HackGen_NF_v2.10.0/HackGenConsoleNF-Bold.ttf
    12922800  12-29-2024 16:04   HackGen_NF_v2.10.0/HackGenConsoleNF-Regular.ttf
   ```

   Nerd Fonts を含まない版は別の cask `font-hackgen`（HackGen / HackGen Console / HackGen35 / HackGen35 Console の 8 ファイル）にある。本書では入れていない。

   </details>

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

   <details>
   <summary>補足: unzip が無いと cask の展開で止まる</summary>

   素のコンテナ（`unzip` 未導入）で手順 4 を先に実行したときの実測。ダウンロードまでは進み、展開で止まる:

   ```
   ==> Fetching downloads for: font-hackgen-nerd
   ✘ Cask font-hackgen-nerd (2.10.0)
   Error: Failure while executing; `/usr/bin/env PATH=/home/linuxbrew/.linuxbrew/opt/unzip/bin:/home/linuxbrew/.linuxbrew/Homebrew/Library/Homebrew/shims/shared:/usr/bin:/bin:/usr/sbin:/sbin unzip -qq -o /home/<USER>/.cache/Homebrew/downloads/6149807b51a48e8d677b9aea249af896c89ec43e04ea53dfb8963f6f86734ed1--HackGen_NF_v2.10.0.zip -d /var/tmp/homebrew-unpack-20260924-2020-whdcjg` exited with 127. Here's the output:
   env: ‘unzip’: No such file or directory
   Error: font-hackgen-nerd: Download failed for font-hackgen-nerd.
   ```

   - `PATH` の先頭が `/home/linuxbrew/.linuxbrew/opt/unzip/bin` なので、Homebrew の `unzip`（`brew install unzip`）でも足りるはずだが、本書では BaseOS の `unzip`（`unzip-6.0-69.el10`）を入れた
   - **Homebrew のインストーラも `homebrew.md` の依存パッケージも `unzip` を入れない**ので、formula（ボトル）だけ使ってきた環境では、cask を初めて入れるときにここで引っかかる

   </details>

1. HackGen を Homebrew の cask で入れる。

   ```bash
   brew install --cask font-hackgen-nerd
   ```

   - `==> Moving Font 'HackGenConsoleNF-Regular.ttf' to '/home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf'` のような行が 4 つ出る
   - `font-hackgen-nerd was successfully installed!` で終わる

   <details>
   <summary>補足: Linux ではフォントが ~/.local/share/fonts に入る</summary>

   cask の定義（`https://formulae.brew.sh/api/cask/font-hackgen-nerd.json`）が示す置き場所は macOS の `~/Library/Fonts` だけだが、Linux の Homebrew は**実行したユーザーの `~/.local/share/fonts`** に置いた。コンテナでの実測:

   ```
   ==> Would install 1 cask:
   font-hackgen-nerd
   ==> Fetching downloads for: font-hackgen-nerd
   ✔︎ Cask font-hackgen-nerd (2.10.0)
   ==> Installing Cask font-hackgen-nerd
   ==> Moving Font 'HackGen35ConsoleNF-Bold.ttf' to '/home/<USER>/.local/share/fonts/HackGen35ConsoleNF-Bold.ttf'
   ==> Moving Font 'HackGen35ConsoleNF-Regular.ttf' to '/home/<USER>/.local/share/fonts/HackGen35ConsoleNF-Regular.ttf'
   ==> Moving Font 'HackGenConsoleNF-Bold.ttf' to '/home/<USER>/.local/share/fonts/HackGenConsoleNF-Bold.ttf'
   ==> Moving Font 'HackGenConsoleNF-Regular.ttf' to '/home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf'
   🍺  font-hackgen-nerd was successfully installed!
   ```

   - ファイルの実体は `~/.local/share/fonts` に**移動**され、`/home/linuxbrew/.linuxbrew/Caskroom/font-hackgen-nerd/2.10.0/HackGen_NF_v2.10.0/` にはそこを指すシンボリックリンクが残る（Caskroom は 4.3 KB）
   - `~/.local/share/fonts` は fontconfig が既定で探す場所なので、設定ファイルを足す必要は無い
   - ダウンロードした zip（25 MB）の sha256 は `f8abd483d5edfad88a78ed511978f43c83b43c48e364aa29ebe4a68217474428` で、cask の定義の値と一致した
   - zip は `~/.cache/Homebrew/downloads/` に残る（`brew cleanup` で消える）

   </details>

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

   <details>
   <summary>補足: fontconfig と、fc-cache が要らなかったこと</summary>

   - `fc-list` / `fc-match` は fontconfig の `fontconfig` パッケージに入っている
   - GNOME のデスクトップには最初から入っているが、素のコンテナには無かったので、検証では `sudo dnf install -y fontconfig`（`fontconfig-2.15.0-7.el10`、依存込み 12 パッケージ）で入れた

   **導入直後に `fc-cache` を実行しなくても `fc-list` に出た。** fontconfig はキャッシュとディレクトリの更新時刻を比べて、古ければ読み直す。

   - ロールバックでファイルを消したときも、`fc-cache` 無しで `fc-list` から消えた（[ロールバック](#ロールバック)）
   - 出てこないときは `fc-cache -f` を試す（コンテナで実行でき、終了コード 0 を確認した）

   コンテナでの実測:

   ```
   $ fc-list : family style file | grep HackGen
   /home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf: HackGen Console NF:style=Regular
   /home/<USER>/.local/share/fonts/HackGen35ConsoleNF-Bold.ttf: HackGen35 Console NF:style=Bold
   /home/<USER>/.local/share/fonts/HackGenConsoleNF-Bold.ttf: HackGen Console NF:style=Bold
   /home/<USER>/.local/share/fonts/HackGen35ConsoleNF-Regular.ttf: HackGen35 Console NF:style=Regular
   $ fc-match "HackGen Console NF"
   HackGenConsoleNF-Regular.ttf: "HackGen Console NF" "Regular"
   $ fc-list "HackGen Console NF" family style fullname postscriptname spacing
   HackGen Console NF:style=Regular:fullname=HackGen Console NF Regular:spacing=90:postscriptname=HackGenConsoleNF-Regular
   HackGen Console NF:style=Bold:fullname=HackGen Console NF Bold:spacing=90:postscriptname=HackGenConsoleNF-Bold
   ```

   `spacing=90` は fontconfig の `dual`（半角と全角の 2 つの幅を持つ等幅）。全角の文字が半角の 2 倍幅で並ぶ日本語の等幅フォントはこの値になる（[注意点](#注意点)）。

   </details>

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

   <details>
   <summary>補足: <code>wezterm ls-fonts</code> の実測と、Powerline の三角</summary>

   コンテナでの実測（画面は出していない。`wezterm ls-fonts` は画面無しで動く）:

   ```
   $ wezterm ls-fonts --text 'aあ漢→'
   LeftToRight
    0 a    \u{61}       x_adv=8  cells=1  glyph=uni0061#0#0#0#0  ,68   wezterm.font("HackGen Console NF", {weight="Regular", stretch="Normal", style="Normal"})
                                         /home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf, FontConfig
    1 あ    \u{3042}     x_adv=17 cells=2  glyph=cid01454#1       ,14050 wezterm.font("HackGen Console NF", {weight="Regular", stretch="Normal", style="Normal"})
                                         /home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf, FontConfig
    4 漢    \u{6f22}     x_adv=17 cells=2  glyph=cid24652#1       ,20417 wezterm.font("HackGen Console NF", {weight="Regular", stretch="Normal", style="Normal"})
                                         /home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf, FontConfig
    7 →    \u{2192}     x_adv=8  cells=1  glyph=arrowright#0#0#0#0  ,868  wezterm.font("HackGen Console NF", {weight="Regular", stretch="Normal", style="Normal"})
                                         /home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf, FontConfig
   ```

   （`glyph=` の後ろの空白は出力を詰めてある。）

   - Nerd Fonts のアイコン（`U+F09B`、GitHub）も同じファイルから引かれた
   - Powerline の三角（`U+E0B0`）は `drawn by wezterm because custom_block_glyphs=true` で、**フォントではなく WezTerm 自身が描く**（WezTerm の既定の設定）

   </details>

---

## 更新

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 の更新](#windows-11-の更新)

1. HackGen を上げる。

   ```bash
   brew upgrade --cask font-hackgen-nerd
   ```

   - 新しい版が無ければ `Warning: Not upgrading font-hackgen-nerd, the latest version is already installed` と出て終わる

---

## ロールバック

- この節は AlmaLinux 10 のもの。Windows 11 は[Windows 11 のロールバック](#windows-11-のロールバック)
- **Homebrew そのものを消すとき**（[homebrew.md のロールバック](homebrew.md#ロールバック)）は、先にこの節の手順 1 の `brew uninstall --cask` を実行しておく
  - `~/.local/share/fonts` は Homebrew の外なので、Homebrew のアンインストーラがこのフォントを消すかどうかは確かめていない

1. HackGen を消し、fontconfig から消えたか確かめる。

   ```bash
   brew uninstall --cask font-hackgen-nerd
   ls ~/.local/share/fonts/
   fc-list : family | grep -c HackGen
   ```

   - `==> Removing Font '/home/<USER>/.local/share/fonts/...'` が 4 行出る
   - `ls` が何も出さず、`grep -c` が `0` になれば消えている（空の `~/.local/share/fonts` は残る）

1. WezTerm で使う（任意）を通したときだけ、書き換えた行を元のフォントに戻す。

   ```bash
   sed -i "s/^config.font = wezterm.font '${HACKGEN_FAMILY:?手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}'/config.font = wezterm.font 'Noto Sans Mono'/" ~/.config/wezterm/wezterm.lua
   grep -n '^config.font = ' ~/.config/wezterm/wezterm.lua
   ```

   - [WezTerm で使う（任意）](#wezterm-で使う任意)で書き換えた行は、元のフォントに戻す
   - このコマンドは、wezterm-nightly.md の最小の例（`Noto Sans Mono`）に戻す場合

---

## Windows 11 で使う

> [!IMPORTANT]
> - **すべて Windows で行う**。この節の手順 1 で Windows PowerShell（5.1）を開き、この節の手順 2・3 と、後ろの Windows 11 の 2 節（更新・ロールバック）のブロックをそこに貼る。管理者の権限は要らない（自分のユーザーに入れる）
> - 前提: [Windows 11 の初期設定の手順 16〜19](windows-setup.md#実施手順)（GitHub のコピーボタンでコピーしたブロックを、conhost の窓に右クリックで貼ると、行が逆順になるのを防ぐ貼り付けの設定）。通していなければ、ブロックは Ctrl+V で貼る
> - **この節の手順 4 で、サインアウトしてサインインし直す**（登録したフォントは、サインインのときに読み込まれる）

- 上から順にコードブロックを貼る。変数は無い（[実施手順](#実施手順)の手順 1 の `HACKGEN_FAMILY` は AlmaLinux 10 だけで使う）
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 以後は[Windows 11 の更新](#windows-11-の更新)・[Windows 11 のロールバック](#windows-11-のロールバック)
- [Windows 11 の初期設定](windows-setup.md)と一緒に行うなら、その手順 55 の再起動より前にこの節の手順 3 までを行えば、この節の手順 4 は要らない

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、上流の zip の sha256・中身・ファミリー名、scoop と winget の定義、Linux の PowerShell 7 での構文と模擬の実行だけ（[対象と検証環境](#対象と検証環境)）。

1. Windows で、Windows PowerShell（5.1）を開く。

   - スタートメニューで「Windows PowerShell」を探し、クリックして開く（「管理者として実行」でなくてよい）

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

   <details>
   <summary>補足: 確かめていることと、入れ方</summary>

   **版と sha256 を固定した**

   - HackGen の上流は、リリースの sha256 を出していない。`HackGen_NF_v2.10.0.zip` の sha256 は、[実施手順](#実施手順)の手順 4 の補足で取った zip・Homebrew の cask `font-hackgen-nerd`・scoop の個人のバケット（mo-san）の定義の 3 つで同じ値だった（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
   - そのため版（2.10.0）と sha256 をブロックに書き、一致しなければ止める。新しい版が出たら、この文書を直してから貼る（[Windows 11 の更新](#windows-11-の更新)）
   - `curl.exe` は `C:\Windows\System32\curl.exe` を呼ぶ。Git for Windows や scoop の `curl` が `PATH` の先にある PC でも、同じものを使うため（[syncthing.md の Windows 11 で使う](syncthing.md#windows-11-で使う)の手順 4 の補足と同じ）

   **入れるもの**

   - zip の中の 4 つの ttf を全部入れる: `HackGenConsoleNF-{Regular,Bold}.ttf`（ファミリー名は `HackGen Console NF`）と `HackGen35ConsoleNF-{Regular,Bold}.ttf`（`HackGen35 Console NF`）。AlmaLinux 10 の cask と同じ 4 つ
   - アプリの設定に書くのはファミリー名（`HackGen Console NF`。スペースが入る）で、ファイル名ではない

   **自分のユーザーに入れる**（管理者の権限は要らない）

   - 置き場所は `%LOCALAPPDATA%\Microsoft\Windows\Fonts`、登録は `HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts` に `<ファイル名> (TrueType)` = ファイルのフルパス。Windows 10 1809 から、フォントをユーザーごとに入れられる
   - 書き方は、scoop の nerd-fonts のバケットの定義（`Hack-NF.json` など）と同じ。そこでは、パッケージのアプリ（Microsoft Store のアプリなど）からも読めるように、フォルダーに「すべてのアプリケーション パッケージ」（`S-1-15-2-1`）と「制限されたすべてのアプリケーション パッケージ」（`S-1-15-2-2`）の読み取りを足している。本書の `icacls` も同じ（足すだけで、ほかの許可は変えない）
   - 登録したフォントは、サインインのときに読み込まれる。そのため、使えるのはサインインし直した（か再起動した）後
   - 読み込まれているフォントのファイルは、置き換えも削除もできない。2 回目に貼るときに同じファイルなら置き直さないのは、そのため

   </details>

1. この PC でサインアウトし、サインインし直す。

   - スタートメニューのユーザーのアイコンから「サインアウト」し、サインインし直す（再起動でもよい）
   - [Windows 11 の初期設定](windows-setup.md)の手順 55 の再起動をこの後に行うなら、この手順は要らない

1. 設定のフォントの一覧で、HackGen Console NF が出ることを確かめる。

   - 設定 → 個人用設定 → フォント を開き、「HackGen」で探すと、`HackGen Console NF` と `HackGen35 Console NF` が出る
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
   - 違う版なら、この文書の[Windows 11 で使う](#windows-11-で使う)の手順 3 の `$ver` と `$sha256` を、その版の zip で確かめた値に直してから貼る（直さなければ、固定した旧版を再び入れるだけで更新にはならない）

   <details>
   <summary>補足: 更新を手作業にしている理由</summary>

   - 上流は sha256 を出していないので、版と sha256 をこの文書に書いて確かめている（[Windows 11 で使う](#windows-11-で使う)の手順 3 の補足）。新しい版の値は、この文書を直す人が確かめる
   - 2.10.0 のファイルの日付は 2024-12-29 で、2026-10-03 の時点でもこれが最新だった
   - GitHub の API は、サインインしないと 1 時間に 60 回まで

   </details>

1. 新しい版にするときだけ、今の版を外してから入れ直す。

   - [Windows 11 のロールバック](#windows-11-のロールバック)の手順 1〜3 を行う（読み込まれているファイルは置き換えられないため）
   - 続けて、直した[Windows 11 で使う](#windows-11-で使う)の手順 3〜5 を行う

---

## Windows 11 のロールバック

- この節の手順 1・3 は、Windows PowerShell（5.1）に貼る
- フォントのファイルは読み込まれている間は消せないので、登録を消してからサインインし直し、その後でファイルを消す

1. HackGen の登録を消す。

   ```powershell
   $key = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
   (Get-Item -LiteralPath $key).Property -like 'HackGen*ConsoleNF-* (TrueType)' | ForEach-Object { Remove-ItemProperty -LiteralPath $key -Name $_ }
   (Get-Item -LiteralPath $key).Property -like 'HackGen*'
   ```

   - 最後のコマンドが何も出さなければよい

1. この PC でサインアウトし、サインインし直す。

   - 再起動でもよい
   - **次の手順は、サインインし直して Windows PowerShell（5.1）を開いてから貼る**

1. フォントのファイルを消す。

   ```powershell
   Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\HackGen*ConsoleNF-*.ttf"
   Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" -Filter 'HackGen*'
   ```

   - 最後のコマンドが何も出さなければよい
   - [Windows 11 で使う](#windows-11-で使う)の手順 3 の `icacls` で足した読み取りの許可は残す（ほかのフォントにも要る）

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に、日本語と Nerd Fonts のアイコンが 1 つで揃うプログラミング用フォント [HackGen Console NF](https://github.com/yuru7/HackGen) を入れる。[eza](eza.md) のアイコンや [starship](starship.md) の Nerd Font 前提のプリセットは、端末のフォントに Nerd Fonts のグリフが要る
- **進め方**: どちらも自分のユーザーだけに入れる。**読者が書き換える変数は無い**
  - **AlmaLinux 10**（[実施手順](#実施手順)）: Homebrew の cask `font-hackgen-nerd` で自分の `~/.local/share/fonts` に入れ、fontconfig から見えることを確かめる
  - **Windows 11**（[Windows 11 で使う](#windows-11-で使う)）: 上流の `HackGen_NF_v2.10.0.zip` を、版と sha256 をブロックに書いて確かめてから、`%LOCALAPPDATA%\Microsoft\Windows\Fonts` に置いて自分のユーザーの登録（`HKCU`）に書く。Windows PowerShell 5.1 に貼り、管理者の権限は要らない。[Windows 11 の初期設定](windows-setup.md)の 1 項目として依頼されたもの
- **状態（AlmaLinux 10）**: **x86_64 のクリーン VM で実施手順を本実行済み（2026-10-06）。コンテナでも検証済み（2026-09-24、x86_64）。実機には入れていない**
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**手順 2〜5・[WezTerm で使う（任意）](#wezterm-で使う任意)・[更新](#更新)・[ロールバック](#ロールバック)を通した
  - **これまでの手順書のコンテナ検証（実機の上の podman）と違い、x86_64 のクラウドホスト上の Docker で行った**（[flatpak.md](flatpak.md) と同じ環境）
  - 確認したこと:
    - `~/.local/share/fonts` に 4 ファイルが入る
    - `fc-list` / `fc-match` で見える
    - かな・漢字・Powerline・Nerd Fonts のアイコンが入っている
    - WezTerm がこのフォントで文字を描く設定になる（`wezterm ls-fonts`）
    - ロールバックで消える
  - **確認していないこと**: 実際の見た目（字形、太字、行の高さ、アイコンの幅）。コンテナに画面が無いため
  - aarch64 でも同じ zip が使われる（cask の定義にアーキごとの分岐が無い）が、aarch64 では通していない
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**:
    - 配布物: `HackGen_NF_v2.10.0.zip` の sha256（3 か所の記録と一致）・中身・ファミリー名（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
    - ほかの経路: scoop の個人のバケット（mo-san）と nerd-fonts のバケット、winget の既定のソース
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。[Windows 11 で使う](#windows-11-で使う)の手順 3 のブロックは、Linux の pwsh で偽物の `icacls.exe` とレジストリを使って流した（[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
  - **確かめていないこと**: Windows で貼ること（すべての手順）、サインインし直した後に設定のフォントの一覧とアプリ（WezTerm と、Windows Terminal などのパッケージのアプリ）で使えること、更新とロールバック、arm64 の Windows

AlmaLinux 10:

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-24 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1） |
| Homebrew | Pi は 2026-09-24 のクリーンインストール後の状態を確かめていない | 7.0.6（[homebrew.md](homebrew.md) の手順 1〜3 で新規導入） |
| HackGen | 未導入 | `font-hackgen-nerd 2.10.0`（cask） |
| unzip / fontconfig | 未確認 | どちらも未導入だったので `dnf` で入れた（`unzip-6.0-69.el10` / `fontconfig-2.15.0-7.el10`） |
| WezTerm | x86_64 PC に nightly（[wezterm-nightly.md](wezterm-nightly.md)） | `wezterm 20260921_051727_5eb03b23`（検証のため wezterm-nightly.md の手順で導入） |

Windows 11（前提にしている環境。ほかの Windows の手順書の実機の記録と同じ PC を想定）:

| 項目 | 値 |
|---|---|
| OS | Windows 11（[Windows の OpenSSH サーバー](windows-openssh-server.md)の PC は 25H2・26H2）。x64 |
| PowerShell | Windows PowerShell 5.1（管理者でなくてよい） |
| HackGen | 2.10.0（`HackGen_NF_v2.10.0.zip`） |

> [!NOTE]
> AlmaLinux 10 の環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。Windows 11 の節には変数が無い（版・sha256・パスはブロックに直接書いてある）。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${HACKGEN_FAMILY}` | fontconfig と WezTerm に渡すファミリー名 | `HackGen Console NF`（既定）/ `HackGen35 Console NF` |
>
> 出力例の値は `<USER>`（AlmaLinux 10）/ `<WIN_USER>`（Windows のユーザー名）のプレースホルダで書いてある。バージョン（`2.10.0`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

AlmaLinux 10 の検証コンテナ（Windows 11 では流していない）:

| 項目 | 状態 |
|---|---|
| HackGen | 未導入（`~/.local/share/fonts` も無い） |
| Homebrew | 7.0.6（cask は 1 つも入っていない） |
| unzip | 未導入 |
| fontconfig | 未導入（`fc-list` が無い） |

実機の Raspberry Pi 5 には、クリーンインストール前に Homebrew の cask で `font-symbols-only-nerd-font 3.5.1`（記号だけの Nerd Font）が入っていた（[yazi.md](yazi.md) の記録）。Linux の Homebrew で font の cask を使うのは、その前例と同じ形。

### 選択した方針

AlmaLinux 10 で HackGen Console NF を入れる経路を比べた（2026-09-24 時点）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **Homebrew の cask `font-hackgen-nerd`** | 2.10.0。upstream の最新のタグ（`git ls-remote --tags` で `v2.10.0`）と一致。`brew upgrade` で上がり、`brew uninstall` で消せる。自分のユーザーにだけ入る | **採用**（Homebrew 系の手順書と揃える） |
| GitHub のリリースの zip を手で展開 | `HackGen_NF_v2.10.0.zip` を落として `~/.local/share/fonts` に置けば同じ結果になる（中身は cask と同じ zip で、sha256 も一致）。Homebrew が要らないが、**更新は手作業** | 不採用（Homebrew がある環境では cask で足りる） |
| EPEL / AppStream の RPM | 無い（EPEL と CRB を有効にした状態で `dnf repoquery` の `*hackgen*` / `*HackGen*` と、`--whatprovides` の `font(hackgen)` / `font(hackgenconsolenf)` がどれも 0 件） | — |
| COPR | 無い（COPR の API で `hackgen` を検索して、関係するプロジェクトは 0 件） | — |
| 全ユーザー向け（`/usr/local/share/fonts` に置く） | root で置けば全ユーザーから見えるが、cask は自分のホームに置く。複数ユーザーで使う機会が無いので要らない | 不採用 |

- upstream の README は、Linux 向けの導入手順を書いていない（GitHub のリリースの ttf と、Mac の Homebrew、Windows の Chocolatey を案内している）
- Homebrew の cask も README では Mac 向けとして紹介されているが、Linux の Homebrew でも入った（手順 4 の補足）

Windows 11 で入れる経路を比べた（2026-10-03 時点）:

| 経路 | 状況 | 採否 |
|---|---|---|
| **上流の zip を版と sha256 を固定して、自分のユーザーに入れる** | 管理者の権限も scoop も要らず、Windows PowerShell 5.1 で動く。更新は手作業 | **採用** |
| scoop の個人のバケット mo-san の `font-hackgen-console-nf` | 同じ zip（sha256 も同じ）で、scoop と UniGet UI で上げられる。ただし、インストールのスクリプトが `Join-Path` に 3 つ以上の引数を渡していて、Windows PowerShell 5.1 の `Join-Path`（`-Path` と `-ChildPath` だけ）では失敗するはず。scoop はそのスクリプトを、`scoop` を打った PowerShell の中で動かす | 不採用（PowerShell 7 が要り、個人の保守） |
| scoop の nerd-fonts のバケット | HackGen は無い | — |
| winget | 既定のソース（winget-pkgs）に HackGen は無い。winget の一覧のサイトには `yuru7.HackGen`（第三者の `dfirr/winget-hackgen` が作り直したインストーラで、PC 全体に入れる）が載っている | 不採用 |
| Chocolatey | 上流の README が Windows 向けに案内している | 不採用（別のパッケージ マネージャーを足し、管理者が要る） |
| PC 全体（`C:\Windows\Fonts`）に入れる | 管理者が要る | 不採用（AlmaLinux 10 と同じく自分のユーザーだけ） |

- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](syncthing.md) と同じく後ろの節に分けた
  - [Windows 11 の初期設定](windows-setup.md)（当時は scoop・UniGet UI・Caps Lock・コンテキストメニュー）の依頼の 1 つとして書き、利用者に確かめてここへ置いた

### 完了時点の状態

**AlmaLinux 10 の検証コンテナでの出力**（手順 5 の直後。Windows 11 では流していない）:

```
$ brew list --cask --versions font-hackgen-nerd
font-hackgen-nerd 2.10.0
$ ls -la ~/.local/share/fonts
total 51548
drwxr-xr-x 2 <USER> <USER>     4096 Sep 24 22:07 .
drwxr-xr-x 3 <USER> <USER>     4096 Sep 24 22:07 ..
-rw-r--r-- 1 <USER> <USER> 13462380 Dec 29  2024 HackGen35ConsoleNF-Bold.ttf
-rw-r--r-- 1 <USER> <USER> 12922844 Dec 29  2024 HackGen35ConsoleNF-Regular.ttf
-rw-r--r-- 1 <USER> <USER> 13464288 Dec 29  2024 HackGenConsoleNF-Bold.ttf
-rw-r--r-- 1 <USER> <USER> 12922800 Dec 29  2024 HackGenConsoleNF-Regular.ttf
```

4 ファイルで約 50 MB。ファイルの日付は zip の中の日付（2024-12-29）のまま。

### 注意点

- **自分のユーザーにしか入らない**: 置き場所が `~/.local/share/fonts` なので、別のユーザーや root で動くアプリからは見えない
- **`unzip` が要る**: Homebrew の formula（ボトル）は `unzip` 無しで入るが、zip で配られる cask は展開に `unzip` を使う（手順 3 の補足）
- **Console 版は記号が半角になる**: 矢印などが 1 セル幅で出る（[WezTerm で使う（任意）](#wezterm-で使う任意)の `→` が `cells=1`）
  - Console ではない通常版（HackGen / HackGen35）は NF 版の zip に入っておらず、NF 無しの cask `font-hackgen` にある
- **NF 版と NF 無しの版は別の cask**: `font-hackgen-nerd`（Console の 2 ファミリー × NF）と `font-hackgen`（4 ファミリー、アイコン無し）
  - ファミリー名は NF 版だけ末尾に ` NF` が付く（`font-hackgen` は入れていないので、両方入れた状態は確かめていない）
- **ファミリー名は `HackGen Console NF`**（スペース入り）。ファイル名（`HackGenConsoleNF-Regular.ttf`）や PostScript 名（`HackGenConsoleNF-Regular`）とは違う。アプリの設定にはファミリー名を書く
- **等幅だけを一覧に出すアプリ**: fontconfig はこのフォントを `spacing=90`（`dual`）と見なす（手順 5 の補足）
  - `spacing=100`（`mono`）のフォントだけを選択肢に出すアプリで選べるかは、確かめていない
- **GNOME の端末や VS Code など WezTerm 以外のアプリ**: それぞれの設定でファミリー名 `HackGen Console NF` を指定することになるが、本書では確かめていない
- **Powerline の記号**: WezTerm は `U+E0B0` などの一部の記号を既定で自分で描く（`custom_block_glyphs`）。ほかの端末ではフォントのグリフが使われる
- **Windows 11 では、自分のユーザーのフォントが見えないアプリがある**: ユーザーごとのフォントは Windows 10 1809 からで、古いアプリには見えないことがある。そのアプリだけ、PC 全体に入れ直す（本書では扱わない）
- **Windows 11 では、読み込まれているフォントのファイルを置き換えられない**: 入れ替え（更新）と削除は、登録を消してサインインし直してから行う（[Windows 11 のロールバック](#windows-11-のロールバック)）

### 参照

- [yuru7/HackGen](https://github.com/yuru7/HackGen) — フォントの特徴、ファミリーの種類、ライセンス、リリース
- [Homebrew Formulae — font-hackgen-nerd](https://formulae.brew.sh/cask/font-hackgen-nerd) — cask の版と中身
- [Nerd Fonts](https://www.nerdfonts.com/) — 追加されているアイコンの一覧（コードポイントの確認に使える）
- `man fc-list` / `man fc-match` / `man fc-cache` — fontconfig の照会と、キャッシュの作り直し
- [wezterm-nightly.md](wezterm-nightly.md) — WezTerm の導入と設定ファイルの置き場所
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順と `brew` の基本操作
- [HackGen v2.10.0](https://github.com/yuru7/HackGen/releases/tag/v2.10.0) — Windows 11 の節で取る `HackGen_NF_v2.10.0.zip`
- [Join-Path（5.1）— Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/join-path?view=powershell-5.1) — `-Path` と `-ChildPath` だけ（scoop の個人のバケットを採らなかった理由）
- [matthewjberger/scoop-nerd-fonts](https://github.com/matthewjberger/scoop-nerd-fonts) — Windows で自分のユーザーにフォントを入れる定義（issue #198 のアクセス権）
- [mo-san/scoop-bucket](https://github.com/mo-san/scoop-bucket) — 採らなかった scoop の個人のバケット
- [Windows 11 の初期設定](windows-setup.md) — Windows のインストール直後にまとめて行う設定（scoop・UniGet UI・Caps Lock・表示・電源・リモート デスクトップなど）。この節は、そのリードから案内される

---

### 付録: コンテナでの検証記録（2026-09-24）

`quay.io/almalinuxorg/almalinux:10` で立てた使い捨てのコンテナ（x86_64 のクラウドホスト上の Docker）に非 root ユーザーを作り、`docker exec` で [Homebrew の導入](homebrew.md)、手順 2〜5、[WezTerm で使う（任意）](#wezterm-で使う任意)、[更新](#更新)、[ロールバック](#ロールバック)を通した。実機で加えた変更は無い。実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。検証の準備として、`fontconfig` と `dnf-plugins-core` を `dnf` で、WezTerm を [wezterm-nightly.md](wezterm-nightly.md) の手順（COPR `rhel-9-x86_64`。鍵の取り込みを無人で通すため `dnf install -y`）で入れ、WezTerm の設定ファイルは wezterm-nightly.md の最小の例をそのまま置いた。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6` |
| 準備. fontconfig | `fontconfig-2.15.0-7.el10`（依存込み 12 パッケージ）。HackGen を入れる前の `fc-list` は 16 行 |
| 2〜3. unzip | `command -v unzip` が無出力で `unzip は未導入`。`dnf install -y unzip` → `unzip-6.0-69.el10` |
| 4. HackGen | `Moving Font` が 4 行、`font-hackgen-nerd was successfully installed!`。**この手順書を書く前に別のコンテナで `unzip` を入れずに試したときは、展開で `env: ‘unzip’: No such file or directory` になって失敗した**（手順 3 の補足。これが手順 2〜3 を足した理由） |
| 5. 検証 | `brew list --cask --versions` → `font-hackgen-nerd 2.10.0`。`fc-list` に 4 行、`fc-match` は `HackGenConsoleNF-Regular.ttf`。`U+3042` / `U+6F22` / `U+E0B0` / `U+F09B` がすべて `1`。`fc-cache` は実行していない |
| WezTerm で使う | `grep` が `3:config.font = wezterm.font 'Noto Sans Mono'`、`sed` の後は `3:config.font = wezterm.font 'HackGen Console NF'`。`wezterm ls-fonts --text 'aあ漢→'` は 4 文字とも HackGen Console NF。なお準備で置いた最小の例の `Noto Sans Mono` はコンテナに入っておらず、書き換える前は `Unable to load a font specified by your font=...` と出て組み込みの `JetBrains Mono` が Primary だった（本書の手順とは関係ない） |
| 更新 | `Warning: Not upgrading font-hackgen-nerd, the latest version is already installed`、終了コード 0 |
| ロールバック | `Backing up Font` と `Removing Font` が 4 組、`Purging files for version 2.10.0`。`ls` は空、`fc-list` の HackGen は 0 件（`fc-cache` を実行しなくても消えた）。WezTerm の行は `Noto Sans Mono` に戻った |

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での導入
- aarch64 での導入（同じ zip が使われる見込みだが通していない）
- 画面での見た目（字形、太字、行の高さ、Nerd Fonts のアイコンの幅と位置）
- 起動中のアプリ（WezTerm 以外）が、再起動しなくても新しいフォントを見つけるか
- GNOME の端末・VS Code・GNOME の設定などでのフォントの選択（`spacing=90` のフォントが一覧に出るか）
- `HackGen35 Console NF` を `${HACKGEN_FAMILY}` にした場合の手順 5 と WezTerm の節（ファイルは同じ cask で入ることだけ確認した）
- Homebrew を丸ごと消したとき（`uninstall.sh`）に `~/.local/share/fonts` のフォントが消えるか

---

### 付録: Windows 11 の配布物と資料の調査（2026-10-03）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、配布物と、ほかの経路の定義を読んだ記録。

`HackGen_NF_v2.10.0.zip` を GitHub のリリースから取った:

```
$ sha256sum HackGen_NF_v2.10.0.zip
f8abd483d5edfad88a78ed511978f43c83b43c48e364aa29ebe4a68217474428  HackGen_NF_v2.10.0.zip
$ unzip -l HackGen_NF_v2.10.0.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  2024-12-29 16:11   HackGen_NF_v2.10.0/
 13462380  2024-12-29 16:04   HackGen_NF_v2.10.0/HackGen35ConsoleNF-Bold.ttf
 12922844  2024-12-29 16:04   HackGen_NF_v2.10.0/HackGen35ConsoleNF-Regular.ttf
 13464288  2024-12-29 16:04   HackGen_NF_v2.10.0/HackGenConsoleNF-Bold.ttf
 12922800  2024-12-29 16:04   HackGen_NF_v2.10.0/HackGenConsoleNF-Regular.ttf
---------                     -------
 52772312                     5 files
$ fc-scan --format '%{file}: family=%{family} style=%{style}\n' HackGen_NF_v2.10.0/*.ttf
HackGen_NF_v2.10.0/HackGen35ConsoleNF-Bold.ttf: family=HackGen35 Console NF style=Bold
HackGen_NF_v2.10.0/HackGen35ConsoleNF-Regular.ttf: family=HackGen35 Console NF style=Regular
HackGen_NF_v2.10.0/HackGenConsoleNF-Bold.ttf: family=HackGen Console NF style=Bold
HackGen_NF_v2.10.0/HackGenConsoleNF-Regular.ttf: family=HackGen Console NF style=Regular
```

sha256 は、次の 3 つと同じだった:

- [実施手順](#実施手順)の手順 4 の補足（2026-09-24 にコンテナの Homebrew が取った zip）
- Homebrew の cask `font-hackgen-nerd` の定義（`https://formulae.brew.sh/api/cask/font-hackgen-nerd.json` の `sha256`。版は 2.10.0）
- scoop の個人のバケット `mo-san/scoop-bucket` の `font-hackgen-console-nf.json` の `hash`（版は 2.10.0）

scoop と winget の HackGen:

- `mo-san/scoop-bucket`（最後のコミットは 2026-09-11）の `font-hackgen-console-nf.json` は、`HackGenConsoleNF-(Regular|Bold)` の 2 つだけを入れる。`--global` が無ければ自分のユーザー（`%LOCALAPPDATA%\Microsoft\Windows\Fonts` と `HKCU`）に入れる。インストールのスクリプトに `Join-Path $env:LOCALAPPDATA Microsoft Windows Fonts` と `Join-Path SOFTWARE Microsoft 'Windows NT' CurrentVersion Fonts`（引数が 3 つ以上）がある
  - Windows PowerShell 5.1 の `Join-Path` は `-Path` と `-ChildPath` の 2 つしか取らない（Microsoft Learn の 5.1 の説明）。残りの引数を受ける `-AdditionalChildPath` は PowerShell 6 から
  - scoop 0.6.0 の `lib/install.ps1` は、定義の `installer` のスクリプトを `Invoke-Command ([scriptblock]::Create(…))` で、`scoop` を打った PowerShell の中で動かす
  - PSScriptAnalyzer の `PSUseCompatibleCommands` は、名前を付けた `-AdditionalChildPath` は 5.1 に無いと指摘したが、名前を付けずに並べた引数は指摘しなかった。Windows PowerShell 5.1 で失敗することは、Windows では確かめていない
- `matthewjberger/scoop-nerd-fonts`（367 の定義）に HackGen は無い。`Hack-NF.json` などのインストールのスクリプトが、[Windows 11 で使う](#windows-11-で使う)の手順 3 の書き方のもと（`%LOCALAPPDATA%\Microsoft\Windows\Fonts` に置き、フォルダーに `S-1-15-2-1`・`S-1-15-2-2` の `ReadAndExecute` を足し、`HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts` に `<ファイル名> (TrueType)` = フルパスを書く）
- winget-pkgs（2026-10-03 の `master`）の `manifests` の下に、名前に `hackgen` を含むものは無かった

---

### 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-03）

Linux（クラウドのコンテナ）に PowerShell 7.6.6（GitHub のリリースの `powershell-7.6.6-linux-x64.tar.gz`）と PSScriptAnalyzer 1.25.0 を入れて確かめた。

**構文と Windows PowerShell 5.1 との互換**:

- Windows 11 の 3 節の `powershell` のブロック 5 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0（ほかの規則の指摘は、ASCII でない文字を含むファイルの BOM だけ）

**[Windows 11 で使う](#windows-11-で使う)の手順 3 のブロック**を、パスの `\` を `/` に替え、`$env:WINDIR`・`$env:LOCALAPPDATA`・`$env:TEMP` を一時的なディレクトリにして流した。`System32/curl.exe` は Linux の `curl` へのリンク、`icacls.exe` は引数を記録するだけの偽物、レジストリ（`New-ItemProperty`・`Get-ItemProperty`）は値を覚えておく偽物にした:

- 1 回目: zip を取り、sha256 が一致し、4 つの ttf がフォントのフォルダーに置かれ、一時フォルダーが消えた。読み戻しに `HackGen35ConsoleNF-Bold (TrueType) : <フォントのフォルダー>/HackGen35ConsoleNF-Bold.ttf` などの 4 行が出た。`icacls.exe` には `<フォントのフォルダー> /grant *S-1-15-2-1:(OI)(CI)(RX) *S-1-15-2-2:(OI)(CI)(RX)` が渡った
- 2 回目（同じフォルダーに）: 同じ 4 行が出て、ttf の ctime は変わらなかった（置き直していない）
- `$sha256` を別の値にしたもの: `中断: HackGen_NF_v2.10.0.zip の sha256 が一致しない` で止まり、フォントのフォルダーには何も作らず、取った zip は一時フォルダーに残った
- 置けなかったとき（`Copy-Item` の失敗）の分かれ道は試していない（root で動かしたので、書き込めないフォルダーを作れなかった）

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. サインインし直した後に、設定のフォントの一覧と、アプリ（WezTerm と、Windows Terminal などのパッケージのアプリ）で `HackGen Console NF` が使えること
1. 登録を消してサインインし直した後に、ファイルを消せること（Windows 11 のロールバック）
1. scoop の個人のバケットの HackGen が、Windows PowerShell 5.1 で本当に失敗すること（採らなかった理由の確かめ）
1. arm64 の Windows

---

### 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1・2・4・5（手順 3 は unzip が既存のため条件外）。

**結果**: Homebrew の cask `font-hackgen-nerd` 2.10.0 を入れ、4 つの TTF が `~/.local/share/fonts` に置かれた。`fc-list` と `fc-match` が HackGen Console NF の Regular/Bold を認識し、本文の U+3042・U+6F22・U+E0B0・U+F09B は全て件数 1 だった。

**今回の未確認範囲**: GNOME・WezTerm の画面での見た目、任意設定、Windows の手順、更新・ロールバックは今回確認していない。
