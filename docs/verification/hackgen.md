# HackGen Console NF インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は上流の zip）の検証記録

[手順書](../hackgen.md)・[ロールバックと注意点](../extra/hackgen.md)

## 最新の確認範囲（Windows 11）

- 通したこと（どれも Windows 11 Pro の同じクリーン VM。実機ではない）
  - 2026-10-06〜07: Windows 節の手順 2・3 による 4 ファイル・ユーザー登録・アプリ用の読み取り許可、再サインイン後の登録、WezTerm CLI でのフォント解決とラスタ生成（[付録](#付録-windows-11-pro-の-vm-での新規導入の検証2026-10-06)）
  - 2026-10-08: 手順 5 の設定のフォントの一覧（2 ファミリーのタイルと見本）、WezTerm の窓での表示、更新の手順 1、ロールバック（[付録](#付録-windows-11-pro-の-vm-での追加検証2026-10-08)）
- 確認していないこと
  - メモ帳・Windows Terminal などほかのアプリでの選択、太字・行の高さの見た目の比べ
  - 新しい版への更新、arm64 の Windows、Windows の実機
- 以降の既存記録は、各実施日・対象版・範囲に従う履歴として保持した

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 操作上の注意と併記されていた記録

   - 違う版なら、この文書の[Windows 11 で使う](../hackgen.md#windows-11-で使う)の手順 3 の `$ver` と `$sha256` を、その版の zip で確かめた値に直してから貼る（直さなければ、固定した旧版を再び入れるだけで更新にはならない）

### 実施手順: 検証状況の記録

> [!WARNING]
> **この実施手順（AlmaLinux 10）は x86_64 のクリーン VM で本実行済み**（2026-10-06）で、コンテナでも検証した。実機では本実行しておらず、aarch64 でも通していない。別の新規 x86_64 VM の WezTerm では日本語・Nerd Font・Powerline の表示を確認した（末尾の GUI 再検証記録）。

### 実施手順 / 手順 3: 補足: unzip が無いと cask の展開で止まる

素のコンテナ（`unzip` 未導入）で手順 4 を先に実行したときの実測。ダウンロードまでは進み、展開で止まる:

```
==> Fetching downloads for: font-hackgen-nerd
✘ Cask font-hackgen-nerd (2.10.0)
Error: Failure while executing; `/usr/bin/env PATH=/home/linuxbrew/.linuxbrew/opt/unzip/bin:/home/linuxbrew/.linuxbrew/Homebrew/Library/Homebrew/shims/shared:/usr/bin:/bin:/usr/sbin:/sbin unzip -qq -o /home/<USER>/.cache/Homebrew/downloads/6149807b51a48e8d677b9aea249af896c89ec43e04ea53dfb8963f6f86734ed1--HackGen_NF_v2.10.0.zip -d /var/tmp/homebrew-unpack-20260924-2020-whdcjg` exited with 127. Here's the output:
env: ‘unzip’: No such file or directory
Error: font-hackgen-nerd: Download failed for font-hackgen-nerd.
```

- `PATH` の先頭が `/home/linuxbrew/.linuxbrew/opt/unzip/bin` なので、Homebrew の `unzip`（`brew install unzip`）でも足りるはずだが、本書では BaseOS の `unzip`（`unzip-6.0-69.el10`）を入れた
- **Homebrew のインストーラも、AlmaLinux 10 の初期設定の手順 46 の依存パッケージも `unzip` を入れない**ので、formula（ボトル）だけ使ってきた環境では、cask を初めて入れるときにここで引っかかる

### 実施手順 / 手順 4: 補足: Linux ではフォントが ~/.local/share/fonts に入る

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

### 実施手順 / 手順 5: 補足: fontconfig と、fc-cache が要らなかったこと

- `fc-list` / `fc-match` は fontconfig の `fontconfig` パッケージに入っている
- GNOME のデスクトップには最初から入っているが、素のコンテナには無かったので、検証では `sudo dnf install -y fontconfig`（`fontconfig-2.15.0-7.el10`、依存込み 12 パッケージ）で入れた

**導入直後に `fc-cache` を実行しなくても `fc-list` に出た。** fontconfig はキャッシュとディレクトリの更新時刻を比べて、古ければ読み直す。

- ロールバックでファイルを消したときも、`fc-cache` 無しで `fc-list` から消えた（[ロールバック](../extra/hackgen.md#ロールバック)）
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

`spacing=90` は fontconfig の `dual`（半角と全角の 2 つの幅を持つ等幅）。全角の文字が半角の 2 倍幅で並ぶ日本語の等幅フォントはこの値になる（[注意点](../extra/hackgen.md#注意点)）。

### WezTerm で使う（任意） / 手順 2: 補足: wezterm ls-fonts の実測と、Powerline の三角

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

### Windows 11 で使う: 検証状況の記録

> [!WARNING]
> **この節と、後ろの Windows 11 の 2 節は、Windows の実機で流していない**（Windows を動かせない環境で書いた）。確かめたのは、上流の zip の sha256・中身・ファミリー名、scoop と winget の定義、Linux の PowerShell 7 での構文と模擬の実行だけ（[対象と検証環境](#対象と検証環境)）。

### Windows 11 で使う / 手順 3: 補足: 確かめていることと、入れ方

**版と sha256 を固定した**

- HackGen の上流は、リリースの sha256 を出していない。`HackGen_NF_v2.10.0.zip` の sha256 は、[実施手順](../hackgen.md#実施手順)の手順 4 の補足で取った zip・Homebrew の cask `font-hackgen-nerd`・scoop の個人のバケット（mo-san）の定義の 3 つで同じ値だった（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
- そのため版（2.10.0）と sha256 をブロックに書き、一致しなければ止める。新しい版が出たら、この文書を直してから貼る（[Windows 11 の更新](../hackgen.md#windows-11-の更新)）
- `curl.exe` は `C:\Windows\System32\curl.exe` を呼ぶ。Git for Windows や scoop の `curl` が `PATH` の先にある PC でも、同じものを使うため（[syncthing.md の Windows 11 で使う](../syncthing.md#windows-11-で使う)の手順 4 の補足と同じ）

**入れるもの**

- zip の中の 4 つの ttf を全部入れる: `HackGenConsoleNF-{Regular,Bold}.ttf`（ファミリー名は `HackGen Console NF`）と `HackGen35ConsoleNF-{Regular,Bold}.ttf`（`HackGen35 Console NF`）。AlmaLinux 10 の cask と同じ 4 つ
- アプリの設定に書くのはファミリー名（`HackGen Console NF`。スペースが入る）で、ファイル名ではない

**自分のユーザーに入れる**（管理者の権限は要らない）

- 置き場所は `%LOCALAPPDATA%\Microsoft\Windows\Fonts`、登録は `HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts` に `<ファイル名> (TrueType)` = ファイルのフルパス。Windows 10 1809 から、フォントをユーザーごとに入れられる
- 書き方は、scoop の nerd-fonts のバケットの定義（`Hack-NF.json` など）と同じ。そこでは、パッケージのアプリ（Microsoft Store のアプリなど）からも読めるように、フォルダーに「すべてのアプリケーション パッケージ」（`S-1-15-2-1`）と「制限されたすべてのアプリケーション パッケージ」（`S-1-15-2-2`）の読み取りを足している。本書の `icacls` も同じ（足すだけで、ほかの許可は変えない）
- 登録したフォントは、サインインのときに読み込まれる。そのため、使えるのはサインインし直した（か再起動した）後
- 読み込まれているフォントのファイルは、置き換えも削除もできない。2 回目に貼るときに同じファイルなら置き直さないのは、そのため

### Windows 11 の更新 / 手順 1: 補足: 更新を手作業にしている理由

- 上流は sha256 を出していないので、版と sha256 をこの文書に書いて確かめている（[Windows 11 で使う](../hackgen.md#windows-11-で使う)の手順 3 の補足）。新しい版の値は、この文書を直す人が確かめる
- 2.10.0 のファイルの日付は 2024-12-29 で、2026-10-03 の時点でもこれが最新だった
- GitHub の API は、サインインしないと 1 時間に 60 回まで

### 対象と検証環境

- **目的**: AlmaLinux 10 と Windows 11 に、日本語と Nerd Fonts のアイコンが 1 つで揃うプログラミング用フォント [HackGen Console NF](https://github.com/yuru7/HackGen) を入れる。eza のアイコンや starship の Nerd Font 前提のプリセット（[AlmaLinux 10 の初期設定](../almalinux-setup.md)）は、端末のフォントに Nerd Fonts のグリフが要る
- **進め方**: どちらも自分のユーザーだけに入れる。**読者が書き換える変数は無い**
  - **AlmaLinux 10**（[実施手順](../hackgen.md#実施手順)）: Homebrew の cask `font-hackgen-nerd` で自分の `~/.local/share/fonts` に入れ、fontconfig から見えることを確かめる
  - **Windows 11**（[Windows 11 で使う](../hackgen.md#windows-11-で使う)）: 上流の `HackGen_NF_v2.10.0.zip` を、版と sha256 をブロックに書いて確かめてから、`%LOCALAPPDATA%\Microsoft\Windows\Fonts` に置いて自分のユーザーの登録（`HKCU`）に書く。Windows PowerShell 5.1 に貼り、管理者の権限は要らない。[Windows 11 の初期設定](../windows-setup.md)の 1 項目として依頼されたもの
- **状態（AlmaLinux 10）**: **x86_64 のクリーン VM で実施手順を本実行済み（2026-10-06）。コンテナでも検証済み（2026-09-24、x86_64）。実機には入れていない**
  - 2026-10-06: 別の新規 x86_64 VM では実施手順 1〜5、更新、ロールバックを実行し、WezTerm の日本語・Nerd Font・Powerline を画面でも確認した（末尾の GUI 再検証記録）
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**手順 2〜5・[WezTerm で使う（任意）](../hackgen.md#wezterm-で使う任意)・[更新](../hackgen.md#更新)・[ロールバック](../extra/hackgen.md#ロールバック)を通した
  - **これまでの手順書のコンテナ検証（実機の上の podman）と違い、x86_64 のクラウドホスト上の Docker で行った**（[flatpak.md](../almalinux-setup.md) と同じ環境）
  - 確認したこと:
    - `~/.local/share/fonts` に 4 ファイルが入る
    - `fc-list` / `fc-match` で見える
    - かな・漢字・Powerline・Nerd Fonts のアイコンが入っている
    - WezTerm がこのフォントで文字を描く設定になる（`wezterm ls-fonts`）
    - ロールバックで消える
  - 新規 x86_64 VM では日本語・Nerd Font・Powerline を実際の WezTerm に表示した。字形・太字・行の高さ・アイコンの幅の網羅的な比較はしていない
  - aarch64 でも同じ zip が使われる（cask の定義にアーキごとの分岐が無い）が、aarch64 では通していない
- **状態（Windows 11）**: **Windows の実機では流していない（未検証。2026-10-03 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**:
    - 配布物: `HackGen_NF_v2.10.0.zip` の sha256（3 か所の記録と一致）・中身・ファミリー名（[付録](#付録-windows-11-の配布物と資料の調査2026-10-03)）
    - ほかの経路: scoop の個人のバケット（mo-san）と nerd-fonts のバケット、winget の既定のソース
    - PowerShell のブロック: Linux の PowerShell 7.6.6 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。[Windows 11 で使う](../hackgen.md#windows-11-で使う)の手順 3 のブロックは、Linux の pwsh で偽物の `icacls.exe` とレジストリを使って流した（[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-03)）
  - **確かめていないこと**: Windows で貼ること（すべての手順）、サインインし直した後に設定のフォントの一覧とアプリ（WezTerm と、Windows Terminal などのパッケージのアプリ）で使えること、更新とロールバック、arm64 の Windows

AlmaLinux 10:

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-24 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1） |
| Homebrew | Pi は 2026-09-24 のクリーンインストール後の状態を確かめていない | 7.0.6（[homebrew.md](../almalinux-setup.md) の手順 1〜3 で新規導入） |
| HackGen | 未導入 | `font-hackgen-nerd 2.10.0`（cask） |
| unzip / fontconfig | 未確認 | どちらも未導入だったので `dnf` で入れた（`unzip-6.0-69.el10` / `fontconfig-2.15.0-7.el10`） |
| WezTerm | x86_64 PC に nightly（[wezterm-nightly.md](../wezterm-nightly.md)） | `wezterm 20260921_051727_5eb03b23`（検証のため wezterm-nightly.md の手順で導入） |

Windows 11（前提にしている環境。ほかの Windows の手順書の実機の記録と同じ PC を想定）:

| 項目 | 値 |
|---|---|
| OS | Windows 11（[Windows の OpenSSH サーバー](../windows-openssh-server.md)の PC は 25H2・26H2）。x64 |
| PowerShell | Windows PowerShell 5.1（管理者でなくてよい） |
| HackGen | 2.10.0（`HackGen_NF_v2.10.0.zip`） |

> [!NOTE]
> AlmaLinux 10 の環境固有の値は**シェル変数**で書いてある。[手順 1](../hackgen.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。Windows 11 の節には変数が無い（版・sha256・パスはブロックに直接書いてある）。
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

実機の Raspberry Pi 5 には、クリーンインストール前に Homebrew の cask で `font-symbols-only-nerd-font 3.5.1`（記号だけの Nerd Font）が入っていた（[yazi.md](../yazi.md) の記録）。Linux の Homebrew で font の cask を使うのは、その前例と同じ形。

### 選択した方針

AlmaLinux 10 で HackGen Console NF を入れる経路を比べた（2026-09-24 時点）:

Windows 11 で入れる経路を比べた（2026-10-03 時点）:

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

### 付録: コンテナでの検証記録（2026-09-24）

`quay.io/almalinuxorg/almalinux:10` で立てた使い捨てのコンテナ（x86_64 のクラウドホスト上の Docker）に非 root ユーザーを作り、`docker exec` で [Homebrew の導入](../almalinux-setup.md)、手順 2〜5、[WezTerm で使う（任意）](../hackgen.md#wezterm-で使う任意)、[更新](../hackgen.md#更新)、[ロールバック](../extra/hackgen.md#ロールバック)を通した。実機で加えた変更は無い。実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。検証の準備として、`fontconfig` と `dnf-plugins-core` を `dnf` で、WezTerm を [wezterm-nightly.md](../wezterm-nightly.md) の手順（COPR `rhel-9-x86_64`。鍵の取り込みを無人で通すため `dnf install -y`）で入れ、WezTerm の設定ファイルは wezterm-nightly.md の最小の例をそのまま置いた。

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

- [実施手順](../hackgen.md#実施手順)の手順 4 の補足（2026-09-24 にコンテナの Homebrew が取った zip）
- Homebrew の cask `font-hackgen-nerd` の定義（`https://formulae.brew.sh/api/cask/font-hackgen-nerd.json` の `sha256`。版は 2.10.0）
- scoop の個人のバケット `mo-san/scoop-bucket` の `font-hackgen-console-nf.json` の `hash`（版は 2.10.0）

scoop と winget の HackGen:

- `mo-san/scoop-bucket`（最後のコミットは 2026-09-11）の `font-hackgen-console-nf.json` は、`HackGenConsoleNF-(Regular|Bold)` の 2 つだけを入れる。`--global` が無ければ自分のユーザー（`%LOCALAPPDATA%\Microsoft\Windows\Fonts` と `HKCU`）に入れる。インストールのスクリプトに `Join-Path $env:LOCALAPPDATA Microsoft Windows Fonts` と `Join-Path SOFTWARE Microsoft 'Windows NT' CurrentVersion Fonts`（引数が 3 つ以上）がある
  - Windows PowerShell 5.1 の `Join-Path` は `-Path` と `-ChildPath` の 2 つしか取らない（Microsoft Learn の 5.1 の説明）。残りの引数を受ける `-AdditionalChildPath` は PowerShell 6 から
  - scoop 0.6.0 の `lib/install.ps1` は、定義の `installer` のスクリプトを `Invoke-Command ([scriptblock]::Create(…))` で、`scoop` を打った PowerShell の中で動かす
  - PSScriptAnalyzer の `PSUseCompatibleCommands` は、名前を付けた `-AdditionalChildPath` は 5.1 に無いと指摘したが、名前を付けずに並べた引数は指摘しなかった。Windows PowerShell 5.1 で失敗することは、Windows では確かめていない
- `matthewjberger/scoop-nerd-fonts`（367 の定義）に HackGen は無い。`Hack-NF.json` などのインストールのスクリプトが、[Windows 11 で使う](../hackgen.md#windows-11-で使う)の手順 3 の書き方のもと（`%LOCALAPPDATA%\Microsoft\Windows\Fonts` に置き、フォルダーに `S-1-15-2-1`・`S-1-15-2-2` の `ReadAndExecute` を足し、`HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts` に `<ファイル名> (TrueType)` = フルパスを書く）
- winget-pkgs（2026-10-03 の `master`）の `manifests` の下に、名前に `hackgen` を含むものは無かった

---

### 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-03）

Linux（クラウドのコンテナ）に PowerShell 7.6.6（GitHub のリリースの `powershell-7.6.6-linux-x64.tar.gz`）と PSScriptAnalyzer 1.25.0 を入れて確かめた。

**構文と Windows PowerShell 5.1 との互換**:

- Windows 11 の 3 節の `powershell` のブロック 5 個を、PowerShell 7.6.6 の構文解析器に通した（構文の誤りは 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）を当てた。互換の指摘は 0（ほかの規則の指摘は、ASCII でない文字を含むファイルの BOM だけ）

**[Windows 11 で使う](../hackgen.md#windows-11-で使う)の手順 3 のブロック**を、パスの `\` を `/` に替え、`$env:WINDIR`・`$env:LOCALAPPDATA`・`$env:TEMP` を一時的なディレクトリにして流した。`System32/curl.exe` は Linux の `curl` へのリンク、`icacls.exe` は引数を記録するだけの偽物、レジストリ（`New-ItemProperty`・`Get-ItemProperty`）は値を覚えておく偽物にした:

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

### 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1・2・4・5 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM の SSH 対話 PTY で実行した。unzip が導入済みだったので手順 3 の分岐は不要だった
- Homebrew cask の HackGen 2.10.0 を導入し、4 フォントのファイルと `fc-match` の検索結果を確認した
- GUI アプリでの選択と見え方はこの CLI 検証には含まない。更新・削除も今回は実行していない

---

### 付録: 現行版の新規 VM の GUI での再検証（2026-10-06）

**環境と流し方**: `5da3478` の現行手順を、別のクリーンな AlmaLinux 10.2 Workstation / x86_64 の VM（1 vCPU、SELinux Enforcing、firewalld 稼働、US 配列）で実行した。SSH の一般ユーザーの対話 PTY に折り畳みの外のブロックを手順ごとに貼り、応答とプロンプトを待った。GUI は GNOME 49.4 のヘッドレスセッションに仮想モニターを付け、操作後の PNG を目視した。既存の実機・資格情報は使っていない。

実施手順 1〜5 を本実行した。既存 unzip への dnf は変更なし。Homebrew cask `font-hackgen-nerd` 2.10.0、4 TTF、`fc-match`、本文の日本語・Powerline・Nerd Font のコードポイントの件数 1 を確認した。WezTerm 設定 `4bdfbf1` の実ウィンドウで日本語を表示し、LazyVim の picker のアイコンと日本語検索結果も正常に描かれた。

更新は最新で変更なし。ロールバック 1 で cask と 4 TTF を削除し、`fc-list` の HackGen 件数 `0` を確認した。この grep の終了 1 は一致なしを示す期待結果である。任意の WezTerm フォント設定の書き換え、Windows と aarch64 は今回実施していない。


### 実施手順 / 手順 1: 補足: 入るフォントの種類

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

## 参考資料から分離した記録

### 参考資料: 選択した方針

| 経路 | 状況 | 採否 |
|---|---|---|
| **Homebrew の cask `font-hackgen-nerd`** | 2.10.0。upstream の最新のタグ（`git ls-remote --tags` で `v2.10.0`）と一致。`brew upgrade` で上がり、`brew uninstall` で消せる。自分のユーザーにだけ入る | **採用**（Homebrew 系の手順書と揃える） |
| GitHub のリリースの zip を手で展開 | `HackGen_NF_v2.10.0.zip` を落として `~/.local/share/fonts` に置けば同じ結果になる（中身は cask と同じ zip で、sha256 も一致）。Homebrew が要らないが、**更新は手作業** | 不採用（Homebrew がある環境では cask で足りる） |
| EPEL / AppStream の RPM | 無い（EPEL と CRB を有効にした状態で `dnf repoquery` の `*hackgen*` / `*HackGen*` と、`--whatprovides` の `font(hackgen)` / `font(hackgenconsolenf)` がどれも 0 件） | — |
| COPR | 無い（COPR の API で `hackgen` を検索して、関係するプロジェクトは 0 件） | — |
| 全ユーザー向け（`/usr/local/share/fonts` に置く） | root で置けば全ユーザーから見えるが、cask は自分のホームに置く。複数ユーザーで使う機会が無いので要らない | 不採用 |

- upstream の README は、Linux 向けの導入手順を書いていない（GitHub のリリースの ttf と、Mac の Homebrew、Windows の Chocolatey を案内している）
- Homebrew の cask も README では Mac 向けとして紹介されているが、Linux の Homebrew でも入った（手順 4 の補足）

| 経路 | 状況 | 採否 |
|---|---|---|
| **上流の zip を版と sha256 を固定して、自分のユーザーに入れる** | 管理者の権限も scoop も要らず、Windows PowerShell 5.1 で動く。更新は手作業 | **採用** |
| scoop の個人のバケット mo-san の `font-hackgen-console-nf` | 同じ zip（sha256 も同じ）で、scoop と UniGet UI で上げられる。ただし、インストールのスクリプトが `Join-Path` に 3 つ以上の引数を渡していて、Windows PowerShell 5.1 の `Join-Path`（`-Path` と `-ChildPath` だけ）では失敗するはず。scoop はそのスクリプトを、`scoop` を打った PowerShell の中で動かす | 不採用（PowerShell 7 が要り、個人の保守） |
| scoop の nerd-fonts のバケット | HackGen は無い | — |
| winget | 既定のソース（winget-pkgs）に HackGen は無い。winget の一覧のサイトには `yuru7.HackGen`（第三者の `dfirr/winget-hackgen` が作り直したインストーラで、PC 全体に入れる）が載っている | 不採用 |
| Chocolatey | 上流の README が Windows 向けに案内している | 不採用（別のパッケージ マネージャーを足し、管理者が要る） |
| PC 全体（`C:\Windows\Fonts`）に入れる | 管理者が要る | 不採用（AlmaLinux 10 と同じく自分のユーザーだけ） |

- **Windows 11 の手順もこの文書に置いた**: 同じツールを AlmaLinux 10 と Windows 11 に入れる手順は、OS ごとにファイルを分けない。手順が OS で違うので、[syncthing.md](../syncthing.md) と同じく後ろの節に分けた
  - [Windows 11 の初期設定](../windows-setup.md)（当時は scoop・UniGet UI・Caps Lock・コンテキストメニュー）の依頼の 1 つとして書き、利用者に確かめてここへ置いた

## 本文から分離した確認範囲と実測

以下は文書分離前の本文に記載されていた記録です。新たな検証結果ではありません。

### ロールバック

  - `~/.local/share/fonts` は Homebrew の外なので、Homebrew のアンインストーラがこのフォントを消すかどうかは確かめていない

### 補足

  - ファミリー名は NF 版だけ末尾に ` NF` が付く（`font-hackgen` は入れていないので、両方入れた状態は確かめていない）

  - `spacing=100`（`mono`）のフォントだけを選択肢に出すアプリで選べるかは、確かめていない

- **GNOME の端末や VS Code など WezTerm 以外のアプリ**: それぞれの設定でファミリー名 `HackGen Console NF` を指定することになるが、本書では確かめていない

---

### 付録: Windows 11 Pro の VM での新規導入の検証（2026-10-06）

[Windows 11 の初期設定](windows-setup.md#付録-windows-11-pro-の-vm-での導入検証2026-10-06)を検証中の専用 VM で、[Windows 11 で使う](../hackgen.md#windows-11-で使う)の手順 2・3 のコードブロックを抜き出して、そのまま実行した。画面で端末を開いて貼る操作は試していない。

| 項目 | 値 |
|---|---|
| OS | Windows 11 Pro 26H2 / ビルド 26300.9457 / x64 |
| VM | VirtualBox 7.2.20。Rufus で作った媒体からクリーンインストールした専用 VM |
| PowerShell | Windows PowerShell 5.1.26100.9444 / Desktop / x64。ログオン中のユーザーの通常権限（Session 1） |
| 配布物 | `HackGen_NF_v2.10.0.zip` |
| zip の SHA256 | `F8ABD483D5EDFAD88A78ED511978F43C83B43C48E364AA29EBE4A68217474428` |
| 検証時の本文の SHA256 | `27F32F24DB057AE78FDA4C2B4783DA1572CF28A8843975F6108FCC78024D00A8`（この追記より前） |
| 抜き出したブロックの manifest の SHA256 | `C6CABB3918DD87333CBD94E4CB4C06A0BBE29CCF99FDAD3FBC0CC5947DF6EFF1` |

**確認したこと**:

- 手順 2・3（バッチ `20261006-110024Z-28d92065`、完了 11:00:28 UTC）:
  - 手順 2 は出力がなく、既存の HackGen のファイルと登録は見つからなかった
  - 手順 3 は zip の SHA256 一致の検査を通過し、ユーザーのフォントフォルダーに 4 つの ttf を置き、対応する `HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts` の登録を出した
  - PowerShell のエラーは 0、最後の終了コードと検証用タスクの終了コードは 0。要求したバッチと完了記録が対応した
- 独立した読み戻し（11:05:43 UTC）:
  - `HackGenConsoleNF-Regular.ttf`・`HackGenConsoleNF-Bold.ttf`・`HackGen35ConsoleNF-Regular.ttf`・`HackGen35ConsoleNF-Bold.ttf` の 4 ファイルが存在し、サイズはいずれも 0 より大きかった。4 つとも登録パスが実ファイルと一致した
  - `PrivateFontCollection` で `HackGen Console NF` と `HackGen35 Console NF` を読み込めた
  - フォントフォルダーの `ALL APPLICATION PACKAGES`（`S-1-15-2-1`）と `ALL RESTRICTED APPLICATION PACKAGES`（`S-1-15-2-2`）への許可を確認した。どちらも `ReadAndExecute, Synchronize`、`ObjectInherit, ContainerInherit` だった
  - 最初の追加検査はアカウント名を SID に変換する処理で失敗したため、raw SDDL と SID を読む方法で確認し直した。本文の導入ブロックの失敗ではない
- 再サインイン後の追加検査（2026-10-07 04:04:16〜04:04:23 UTC）:
  - 同じ VM の通常権限の PowerShell 7.6.6・Session 1 で、`InstalledFontCollection` が `HackGen Console NF` と `HackGen35 Console NF` を認識した
  - 設定やメモ帳のフォント一覧の確認は利用者に依頼済みで、回答待ち。GUI の選択・描画は未確認。証跡は `.verification/evidence/remaining-local-20261007-040410-0e3dc87e/guest-result.json`

**確認していないこと**:

- 手順 5 の設定のフォント一覧。Windows の初期設定で再起動・サインインは済んでいるが、フォントの GUI 確認は回答待ち
- WezTerm や Windows Terminal などのアプリでの利用と見た目。`PrivateFontCollection` と `InstalledFontCollection` の認識だけでは、アプリで選択・描画できると判定しない
- 更新、ロールバック、arm64 の Windows

---

### 付録: Windows 11 Pro の VM での WezTerm CLI によるフォント利用の検証（2026-10-07）

前の導入と同じ VM の通常権限の PowerShell 7.6.6・Session 1 で、WezTerm の `ls-fonts --codepoints 61,3042,6f22,2192,e0b0,f07c --rasterize-ascii` を実行した。各ファミリーを指定した使い捨ての設定を `--config-file` で渡し、フォントサイズは 12.0、`custom_block_glyphs=false` と `check_for_updates=false` にした。GUI のウィンドウは検査していない。

| ファミリー | DirectWrite が使ったユーザーフォント | ラスタのピクセル数 | alpha が 0 でないピクセル数 |
|---|---|---:|---:|
| HackGen Console NF | `HackGenConsoleNF-Regular.ttf` | 974 | 639 |
| HackGen35 Console NF | `HackGen35ConsoleNF-Regular.ttf` | 1031 | 665 |

**確認したこと**:

- 両ファミリーの `a`・`あ`・`漢`・`→`・Powerline の U+E0B0・Nerd Fonts の U+F07C、計 12 glyph を確認した。glyph ID はすべて 0 以外で `notdef` がなく、セル幅は両ファミリーとも順に `1/2/2/1/1/1`。別のフォントへの fallback や WezTerm の独自 glyph ではなかった
- stdout の ANSI `38:6` の RGBA を文字ごとに集計し、bearing・offset、ラスタの幅・高さ、各チャンネルの 0〜255 の範囲と、alpha が 0 でない領域を確認した。計 2005 ピクセル中 1304 は alpha が 0 以外、359 は 255。HackGen35 の矢印だけ最大 alpha が 254 で、すべての glyph に 255 を要求する判定はしていない
- 2 回の CLI 終了コードは 0、stderr は空、作業フォルダーの cleanup は成功した。実ユーザーとインストール先の WezTerm 設定 3 パスは前後とも存在せず、実設定は不変だった
- 実行時刻は 2026-10-07 09:20:26〜09:20:46 UTC。証跡は `.verification/evidence/remaining-wezterm-font-20261007-092017-4d5448f6` の `guest-result.json` と独立した `glyph-assessment.json` に保存した。raw stdout の NUL padding と ANSI は解析用のコピーだけで処理し、元の JSON は保持した
- raw JSON の SHA256 は `9B2C1DC0A426F36FF2971561FCC041077D62EFE718D8D85403C68CB1E6A40475`、評価 JSON は `C12A3BF87D1FD9BE9C9061AD12DB6F6866B2A4141E993CC3F80221184E753C68`。文字ごとの寸法と alpha の領域は評価 JSON と[WezTerm の付録](wezterm-nightly.md#付録-windows-11-pro-の-vm-での-hackgen-の-cli-ラスタ生成の検証2026-10-07)に記録した

**確認していないこと**:

- Windows の設定・メモ帳・WezTerm GUI のフォント一覧と選択、画面上の描画や字形・太字・行の高さ。今回の CLI ラスタ生成をスクリーン上の見た目の確認へ広げない
- Windows Terminal などのパッケージのアプリでの利用、選んだ 6 文字以外、更新・ロールバック、arm64 の Windows。以前の付録の未確認事項はその時点の履歴として保持した

---

### 付録: Windows 11 Pro の VM での追加検証（2026-10-08）

上の付録と同じ VM（[windows-setup.md の検証記録の 2026-10-08 の付録](windows-setup.md#付録-pr-104-の未検証項目を同じ-vm-で確かめた記録2026-10-08)の環境）で、画面のフォントの一覧と WezTerm の窓での表示、更新の確認を行った。手順は [Windows 11 で使う](../hackgen.md#windows-11-で使う)の番号。

- 手順 5:
  - 設定 → 個人用設定 → フォント は、ライセンス認証していないこの VM でも開いた。ただし、画面の検索欄は使えなかった（UI Automation で `IsEnabled` が `False`）
  - 一覧をスクロールすると、「HackGen Console NF」と「HackGen35 Console NF」のタイルが、どちらも「2 フォント フェイス」で、見本の文がこのフォントで描かれて並んだ
  - 本文の手順 5 に、検索欄が使えないときは一覧をスクロールする旨を足した
- WezTerm の窓での表示: 一時的な `%USERPROFILE%\.wezterm.lua` で `HackGen Console NF` を指定すると、英字・かな・漢字・矢印・Powerline の記号・Nerd Font のフォルダーのアイコン・日本語の文が表示された（[wezterm-nightly.md の検証記録](wezterm-nightly.md)の 2026-10-08 の付録。この VM では `prefer_egl` も要った）
- Windows 11 の更新の手順 1: `v2.10.0`。新しい版は無いので、この節の手順 2 は行っていない
- Windows 11 のロールバック（管理者ではない窓。Windows Terminal の中に開き、複数行の警告で「強制的に貼り付け」を押した）:
  - この節の手順 1: 最後のコマンドは何も出さなかった
  - この節の手順 2: サインアウトの代わりに再起動した（自動サインインで戻った）
  - この節の手順 3: 最後のコマンドは何も出さなかった（4 つの ttf が消えた）

**確認していないこと**:

- メモ帳・Windows Terminal などほかのアプリでの選択、太字・行の高さの見た目の比べ、新しい版への更新、arm64 の Windows、Windows の実機
