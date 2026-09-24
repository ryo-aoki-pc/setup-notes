# HackGen Console NF インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

> [!IMPORTANT]
> - **すべて対象ホスト上で、自分のシェルで実行する。** `sudo -i` した root のシェルでは行わない（Homebrew は root で動かず、フォントも自分のホームの `~/.local/share/fonts` に入るため）
> - **前提: Homebrew が入っていること。** `command -v brew` でバージョンが出なければ、先に [Homebrew](homebrew.md) を通す

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾に折り畳んだ「補足」の中のブロックは、手順を進めるためには貼らなくてよい
- 理由・実測出力・落とし穴は各手順の「補足」と後半の[補足](#補足)にある。実行するだけなら読まなくてよい

関連する節:

- 端末のフォントにする: [WezTerm で使う（任意）](#wezterm-で使う任意)
- 以後の更新: [更新](#更新)
- 元に戻す: [ロールバック](#ロールバック)

1. **変数を設定する**

   - **編集必須の変数は無い。** 確認と WezTerm の設定に使うファミリー名で、既定のまま進められる
   - 文字幅が半角 3:全角 5 の版を使いたいときだけ `HackGen35 Console NF` に変える（同じ手順で一緒に入る。この手順の補足）
   - **新しいシェルを開いたら（SSH を張り直したあとも）先にこのブロックを貼り直す**

   ```bash
   HACKGEN_FAMILY='HackGen Console NF'   # 確認と設定に使うファミリー名。<HACKGEN_FAMILY>
   printf '%-15s = %s\n' HACKGEN_FAMILY "${HACKGEN_FAMILY}"
   ```

   <details>
   <summary>補足: 入るフォントの種類</summary>

   `${HACKGEN_FAMILY}` は**この文書の中だけで使うシェル変数**で、fontconfig や WezTerm が読む環境変数ではない。

   [HackGen（白源）](https://github.com/yuru7/HackGen)は、英数字の Hack と、かな・漢字の源柔ゴシックを合成したプログラミング用の等幅フォント。upstream の README が挙げるファミリーは次の 4 つで、それぞれに Nerd Fonts のアイコンを足した **NF** 版がある。

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

1. **unzip を用意する**

   - Homebrew は cask の zip を展開するのに `unzip` を使う
   - 入っているか見る。パスが出れば、次のブロックは飛ばしてよい

   ```bash
   command -v unzip || echo 'unzip は未導入'
   ```

   無ければ入れる。

   ```bash
   sudo dnf install -y unzip
   ```

   `sudo` のパスワードを聞かれることがある。**次のブロックは、それに答えてから貼る**（続けて貼ると答えとして食われる）。

   <details>
   <summary>補足: unzip が無いと cask の展開で止まる</summary>

   素のコンテナ（`unzip` 未導入）で手順 3 を先に実行したときの実測。ダウンロードまでは進み、展開で止まる:

   ```
   ==> Fetching downloads for: font-hackgen-nerd
   ✘ Cask font-hackgen-nerd (2.10.0)
   Error: Failure while executing; `/usr/bin/env PATH=/home/linuxbrew/.linuxbrew/opt/unzip/bin:/home/linuxbrew/.linuxbrew/Homebrew/Library/Homebrew/shims/shared:/usr/bin:/bin:/usr/sbin:/sbin unzip -qq -o /home/<USER>/.cache/Homebrew/downloads/6149807b51a48e8d677b9aea249af896c89ec43e04ea53dfb8963f6f86734ed1--HackGen_NF_v2.10.0.zip -d /var/tmp/homebrew-unpack-20260924-2020-whdcjg` exited with 127. Here's the output:
   env: ‘unzip’: No such file or directory
   Error: font-hackgen-nerd: Download failed for font-hackgen-nerd.
   ```

   `PATH` の先頭が `/home/linuxbrew/.linuxbrew/opt/unzip/bin` なので、Homebrew の `unzip`（`brew install unzip`）でも足りるはずだが、本書では BaseOS の `unzip`（`unzip-6.0-69.el10`）を入れた。**Homebrew のインストーラも `homebrew.md` の依存パッケージも `unzip` を入れない**ので、formula（ボトル）だけ使ってきた環境では、cask を初めて入れるときにここで引っかかる。

   </details>

1. **HackGen を入れる**

   ```bash
   brew install --cask font-hackgen-nerd
   ```

   `==> Moving Font 'HackGenConsoleNF-Regular.ttf' to '/home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf'` のような行が 4 つ出て、`font-hackgen-nerd was successfully installed!` で終わる。

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

   ファイルの実体は `~/.local/share/fonts` に**移動**され、`/home/linuxbrew/.linuxbrew/Caskroom/font-hackgen-nerd/2.10.0/HackGen_NF_v2.10.0/` にはそこを指すシンボリックリンクが残る（Caskroom は 4.3 KB）。`~/.local/share/fonts` は fontconfig が既定で探す場所なので、設定ファイルを足す必要は無い。

   ダウンロードした zip（25 MB）の sha256 は `f8abd483d5edfad88a78ed511978f43c83b43c48e364aa29ebe4a68217474428` で、cask の定義の値と一致した。zip は `~/.cache/Homebrew/downloads/` に残る（`brew cleanup` で消える）。

   </details>

1. **検証する**

   ```bash
   brew list --cask --versions font-hackgen-nerd
   ls ~/.local/share/fonts/
   fc-list : family style file | grep HackGen
   fc-match "${HACKGEN_FAMILY:?手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}"
   ```

   - `font-hackgen-nerd 2.10.0`、4 つの `.ttf`、`HackGen Console NF` と `HackGen35 Console NF` の Regular / Bold の 4 行が出て、`fc-match` が `HackGenConsoleNF-Regular.ttf: "HackGen Console NF" "Regular"` を返せばよい
   - `fc-match` は、名前が合わないときに別のフォントを黙って返すので、**ファイル名が HackGen であることを確かめる**

   次に、かな・漢字・Powerline 記号・Nerd Fonts のアイコンが、このフォントに入っていることを確かめる。

   ```bash
   for cp in 3042 6f22 e0b0 f09b; do printf 'U+%s: ' "${cp}"; fc-list ":charset=${cp}" family | grep -c -x -F "${HACKGEN_FAMILY:?手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}"; done
   ```

   4 行とも `1` なら入っている（`あ` / `漢` / Powerline の三角 / GitHub のアイコン）。

   <details>
   <summary>補足: fc-cache は要らなかった</summary>

   `fc-list` / `fc-match` は fontconfig の `fontconfig` パッケージに入っている。GNOME のデスクトップには最初から入っているが、素のコンテナには無かったので、検証では `sudo dnf install -y fontconfig`（`fontconfig-2.15.0-7.el10`、依存込み 12 パッケージ）で入れた。

   **導入直後に `fc-cache` を実行しなくても `fc-list` に出た。** fontconfig はキャッシュとディレクトリの更新時刻を比べて、古ければ読み直す。ロールバックでファイルを消したときも、`fc-cache` 無しで `fc-list` から消えた（[ロールバック](#ロールバック)）。出てこないときは `fc-cache -f` を試す（コンテナで実行でき、終了コード 0 を確認した）。

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

[WezTerm](wezterm-nightly.md) の端末フォントを HackGen Console NF にする。

> [!IMPORTANT]
> **[wezterm-nightly.md の設定ファイル](wezterm-nightly.md#設定ファイル)の最小の例（`~/.config/wezterm/wezterm.lua`）を置いてある前提**で、その `config.font` の行を書き換える。`~/.wezterm.lua` を使っている場合は、そちらのファイルに読み替える（両方あると `~/.wezterm.lua` だけが読まれる）。

まず書き換える行があるか見る。

- `3:config.font = wezterm.font 'Noto Sans Mono'` のように 1 行出ればよい
- 何も出なければ、`return config` の前に `config.font = wezterm.font 'HackGen Console NF'` を自分で足す

```bash
grep -n '^config.font = ' ~/.config/wezterm/wezterm.lua
```

書き換えて、WezTerm がどのフォントで文字を描くかを確かめる。

```bash
sed -i "s/^config.font = .*/config.font = wezterm.font '${HACKGEN_FAMILY:?手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}'/" ~/.config/wezterm/wezterm.lua
grep -n '^config.font = ' ~/.config/wezterm/wezterm.lua
wezterm ls-fonts --text 'aあ漢→'
```

- 4 文字とも `wezterm.font("HackGen Console NF", ...)` と `/home/<USER>/.local/share/fonts/HackGenConsoleNF-Regular.ttf, FontConfig` が出ればよい
- **`→` が `cells=1`（半角）になる**のが Console 版の特徴で、`あ` / `漢` は `cells=2`
- 起動中の WezTerm には保存した時点で反映される（wezterm-nightly.md の設定ファイルの節）

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

---

## 更新

```bash
brew upgrade --cask font-hackgen-nerd
```

新しい版が無ければ `Warning: Not upgrading font-hackgen-nerd, the latest version is already installed` と出て終わる。

---

## ロールバック

```bash
brew uninstall --cask font-hackgen-nerd
ls ~/.local/share/fonts/
fc-list : family | grep -c HackGen
```

`==> Removing Font '/home/<USER>/.local/share/fonts/...'` が 4 行出て、`ls` が何も出さず、`grep -c` が `0` になれば消えている（空の `~/.local/share/fonts` は残る）。

[WezTerm で使う（任意）](#wezterm-で使う任意)で書き換えた行は、元のフォントに戻す。次は wezterm-nightly.md の最小の例（`Noto Sans Mono`）に戻す場合。

```bash
sed -i "s/^config.font = wezterm.font '${HACKGEN_FAMILY:?手順 1 の HACKGEN_FAMILY が空のまま。値を入れて貼り直す}'/config.font = wezterm.font 'Noto Sans Mono'/" ~/.config/wezterm/wezterm.lua
grep -n '^config.font = ' ~/.config/wezterm/wezterm.lua
```

> [!NOTE]
> **Homebrew そのものを消すとき**（[homebrew.md のロールバック](homebrew.md#ロールバック)）は、先にこの節の `brew uninstall --cask` を実行しておく。`~/.local/share/fonts` は Homebrew の外なので、Homebrew のアンインストーラがこのフォントを消すかどうかは確かめていない。

---

## 補足

### 対象と検証環境

- **目的**: AlmaLinux 10 に、日本語と Nerd Fonts のアイコンが 1 つで揃うプログラミング用フォント [HackGen Console NF](https://github.com/yuru7/HackGen) を入れる。[eza](eza.md) のアイコンや [starship](starship.md) の Nerd Font 前提のプリセットは、端末のフォントに Nerd Fonts のグリフが要る
- **進め方**: Homebrew の cask `font-hackgen-nerd` で自分の `~/.local/share/fonts` に入れ、fontconfig から見えることを確かめる。**読者が書き換える変数は無い**
- **状態**: **コンテナでのみ検証済み（2026-09-24、x86_64）。実機には入れていない**
  - 下表の検証コンテナで**この文書のコードブロックをそのまま貼って**、手順 2〜4・[WezTerm で使う（任意）](#wezterm-で使う任意)・[更新](#更新)・[ロールバック](#ロールバック)を通した
  - 確認したこと: `~/.local/share/fonts` に 4 ファイルが入る / `fc-list` / `fc-match` で見える / かな・漢字・Powerline・Nerd Fonts のアイコンが入っている / WezTerm がこのフォントで文字を描く設定になる（`wezterm ls-fonts`）/ ロールバックで消える
  - **コンテナに画面が無いため、実際の見た目（字形、太字、行の高さ、アイコンの幅）は確認していない**
  - aarch64 でも同じ zip が使われる（cask の定義にアーキごとの分岐が無い）が、aarch64 では通していない
  - **これまでの手順書のコンテナ検証（実機の上の podman）と違い、x86_64 のクラウドホスト上の Docker で行った**（[flatpak.md](flatpak.md) と同じ環境）

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-24 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5）・x86_64 PC | AlmaLinux 10.2 (Lavender Lion) / x86_64（`quay.io/almalinuxorg/almalinux:10`、Docker 29.3.1） |
| Homebrew | Pi は 2026-09-24 のクリーンインストール後の状態を確かめていない | 7.0.6（[homebrew.md](homebrew.md) の手順 2〜4 で新規導入） |
| HackGen | 未導入 | `font-hackgen-nerd 2.10.0`（cask） |
| unzip / fontconfig | 未確認 | どちらも未導入だったので `dnf` で入れた（`unzip-6.0-69.el10` / `fontconfig-2.15.0-7.el10`） |
| WezTerm | x86_64 PC に nightly（[wezterm-nightly.md](wezterm-nightly.md)） | `wezterm 20260921_051727_5eb03b23`（検証のため wezterm-nightly.md の手順で導入） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${HACKGEN_FAMILY}` | fontconfig と WezTerm に渡すファミリー名 | `HackGen Console NF`（既定）/ `HackGen35 Console NF` |
>
> 出力例の値は `<USER>` のプレースホルダで書いてある。バージョン（`2.10.0`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

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

upstream の README は、Linux 向けの導入手順を書いていない（GitHub のリリースの ttf と、Mac の Homebrew、Windows の Chocolatey を案内している）。Homebrew の cask も README では Mac 向けとして紹介されているが、Linux の Homebrew でも入った（手順 3 の補足）。

### 完了時点の状態

**検証コンテナでの出力**（手順 4 の直後）:

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
- **`unzip` が要る**: Homebrew の formula（ボトル）は `unzip` 無しで入るが、zip で配られる cask は展開に `unzip` を使う（手順 2 の補足）
- **Console 版は記号が半角になる**: 矢印などが 1 セル幅で出る（[WezTerm で使う（任意）](#wezterm-で使う任意)の `→` が `cells=1`）。Console ではない通常版（HackGen / HackGen35）は NF 版の zip に入っておらず、NF 無しの cask `font-hackgen` にある
- **NF 版と NF 無しの版は別の cask**: `font-hackgen-nerd`（Console の 2 ファミリー × NF）と `font-hackgen`（4 ファミリー、アイコン無し）。ファミリー名は NF 版だけ末尾に ` NF` が付く（`font-hackgen` は入れていないので、両方入れた状態は確かめていない）
- **ファミリー名は `HackGen Console NF`**（スペース入り）。ファイル名（`HackGenConsoleNF-Regular.ttf`）や PostScript 名（`HackGenConsoleNF-Regular`）とは違う。アプリの設定にはファミリー名を書く
- **等幅だけを一覧に出すアプリ**: fontconfig はこのフォントを `spacing=90`（`dual`）と見なす（手順 4 の補足）。`spacing=100`（`mono`）のフォントだけを選択肢に出すアプリで選べるかは確かめていない
- **GNOME の端末や VS Code など WezTerm 以外のアプリ**: それぞれの設定でファミリー名 `HackGen Console NF` を指定することになるが、本書では確かめていない
- **Powerline の記号**: WezTerm は `U+E0B0` などの一部の記号を既定で自分で描く（`custom_block_glyphs`）。ほかの端末ではフォントのグリフが使われる

### 参照

- [yuru7/HackGen](https://github.com/yuru7/HackGen) — フォントの特徴、ファミリーの種類、ライセンス、リリース
- [Homebrew Formulae — font-hackgen-nerd](https://formulae.brew.sh/cask/font-hackgen-nerd) — cask の版と中身
- [Nerd Fonts](https://www.nerdfonts.com/) — 追加されているアイコンの一覧（コードポイントの確認に使える）
- `man fc-list` / `man fc-match` / `man fc-cache` — fontconfig の照会と、キャッシュの作り直し
- [wezterm-nightly.md](wezterm-nightly.md) — WezTerm の導入と設定ファイルの置き場所
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順と `brew` の基本操作

---

### 付録: コンテナでの検証記録（2026-09-24）

`quay.io/almalinuxorg/almalinux:10` で立てた使い捨てのコンテナ（x86_64 のクラウドホスト上の Docker）に非 root ユーザーを作り、`docker exec` で [Homebrew の導入](homebrew.md)、手順 2〜4、[WezTerm で使う（任意）](#wezterm-で使う任意)、[更新](#更新)、[ロールバック](#ロールバック)を通した。実機で加えた変更は無い。実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。検証の準備として、`fontconfig` と `dnf-plugins-core` を `dnf` で、WezTerm を [wezterm-nightly.md](wezterm-nightly.md) の手順（COPR `rhel-9-x86_64`。鍵の取り込みを無人で通すため `dnf install -y`）で入れ、WezTerm の設定ファイルは wezterm-nightly.md の最小の例をそのまま置いた。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `dnf install -y procps-ng curl file git` のうえで `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6` |
| 準備. fontconfig | `fontconfig-2.15.0-7.el10`（依存込み 12 パッケージ）。HackGen を入れる前の `fc-list` は 16 行 |
| 2. unzip | `command -v unzip` が無出力で `unzip は未導入`。`dnf install -y unzip` → `unzip-6.0-69.el10` |
| 3. HackGen | `Moving Font` が 4 行、`font-hackgen-nerd was successfully installed!`。**この手順書を書く前に別のコンテナで `unzip` を入れずに試したときは、展開で `env: ‘unzip’: No such file or directory` になって失敗した**（手順 2 の補足。これが手順 2 を足した理由） |
| 4. 検証 | `brew list --cask --versions` → `font-hackgen-nerd 2.10.0`。`fc-list` に 4 行、`fc-match` は `HackGenConsoleNF-Regular.ttf`。`U+3042` / `U+6F22` / `U+E0B0` / `U+F09B` がすべて `1`。`fc-cache` は実行していない |
| WezTerm で使う | `grep` が `3:config.font = wezterm.font 'Noto Sans Mono'`、`sed` の後は `3:config.font = wezterm.font 'HackGen Console NF'`。`wezterm ls-fonts --text 'aあ漢→'` は 4 文字とも HackGen Console NF。なお準備で置いた最小の例の `Noto Sans Mono` はコンテナに入っておらず、書き換える前は `Unable to load a font specified by your font=...` と出て組み込みの `JetBrains Mono` が Primary だった（本書の手順とは関係ない） |
| 更新 | `Warning: Not upgrading font-hackgen-nerd, the latest version is already installed`、終了コード 0 |
| ロールバック | `Backing up Font` と `Removing Font` が 4 組、`Purging files for version 2.10.0`。`ls` は空、`fc-list` の HackGen は 0 件（`fc-cache` を実行しなくても消えた）。WezTerm の行は `Noto Sans Mono` に戻った |

#### 未確認事項

- 実機（Raspberry Pi 5 / x86_64 PC）での導入
- aarch64 での導入（同じ zip が使われる見込みだが通していない）
- 画面での見た目（字形、太字、行の高さ、Nerd Fonts のアイコンの幅と位置）
- 起動中のアプリ（WezTerm 以外）が、再起動しなくても新しいフォントを見つけるか
- GNOME の端末・VS Code・GNOME の設定などでのフォントの選択（`spacing=90` のフォントが一覧に出るか）
- `HackGen35 Console NF` を `${HACKGEN_FAMILY}` にした場合の手順 4 と WezTerm の節（ファイルは同じ cask で入ることだけ確認した）
- Homebrew を丸ごと消したとき（`uninstall.sh`）に `~/.local/share/fonts` のフォントが消えるか
