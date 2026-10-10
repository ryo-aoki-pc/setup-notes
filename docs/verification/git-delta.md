# git-delta（delta）インストール手順（AlmaLinux 10 は Homebrew / Windows 11 は scoop）の検証記録

[手順書](../git-delta.md)・[ロールバックと注意点](../extra/git-delta.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **x86_64 のクリーン VM で実施手順を本実行済み**（2026-10-06）で、実機では本実行していない（[対象と検証環境](#対象と検証環境)）。

### 実施手順 / 手順 3: 補足: キー名は小文字に正規化される

git はセクション名とキー名を小文字に正規化して扱う。`interactive.diffFilter` と書いても、`--get-regexp` や `--list` では `interactive.difffilter` と出る。**大文字の `F` を含む正規表現では引っかからない**ので、読み戻しでは小文字を使う。以前の広い正規表現でのコンテナ実測:

```
$ git config --global --get-regexp '^(core\.pager|interactive\.|delta\.|merge\.conflictstyle)'
core.pager delta
interactive.difffilter delta --color-only
delta.navigate true
delta.line-numbers true
delta.side-by-side false
merge.conflictstyle zdiff3
$ cat ~/.gitconfig
[user]
	name = <USER>
	email = <EMAIL>
[core]
	pager = delta
[interactive]
	diffFilter = delta --color-only
[delta]
	navigate = true
	line-numbers = true
	side-by-side = false
[merge]
	conflictstyle = zdiff3
```

- ファイルの中では `diffFilter` のまま残る（git が書き込むときは指定した綴りを使う）
- 値を 1 つだけ取るなら、`git config --global --get interactive.diffFilter` は大文字のままでも通る（こちらは正規表現ではなくキー名の照合で、大小を区別しないため）

### 実施手順 / 手順 4: 補足: パイプに繋ぐとページャは働かない

git は**標準出力が端末のときだけ** `core.pager` を起動する。したがって:

- `git diff` を素で打つ → delta が起動する（端末が要る。本書では未検証）
- `git diff | head` → ページャを通らず、素の unified diff が出る
- `git diff | delta --paging=never` → 明示的に delta に渡しているので色が付く

この手順で 3 番目の形を使っているのはこのため。コンテナでの実測（ANSI エスケープは除いてある）:

```
$ git diff | delta --paging=never | head -12

f.txt
────────────────────────────────────────────────────────────────────────────────

───┐
1: │
───┘
a
b
B
c
d
$ git diff | head -8
diff --git a/f.txt b/f.txt
index de98044..a7bc997 100644
--- a/f.txt
+++ b/f.txt
@@ -1,3 +1,4 @@
 a
-b
+B
```

### lazygit と組み合わせる（任意） / 手順 0: 本文中の記録

- lazygit 0.65.1 の公式設定に合わせて `git.diffRenderers` を使う（2026-10-05 に対象版の資料とソースを確認。TUI での表示は未検証）

### ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**

### Windows 11 で使う: 検証状況の記録

> [!WARNING]
> **[Windows 11 で使う](../git-delta.md#windows-11-で使う)と、後ろの Windows 11 の 2 節（更新・ロールバック）は、Windows の実機では未検証**（2026-10-08 に書いた。Windows を動かせないクラウドの Linux のコンテナで書き、どのブロックも Windows では貼っていない）。確かめたのは、scoop と winget の定義、配布物の中身と sha256、delta・Git for Windows・Scoop のソース、PowerShell の構文と偽物のコマンドでの模擬だけ（[対象と検証環境](#対象と検証環境)の「状態（Windows 11）」）。

### 対象と検証環境

- **目的**: AlmaLinux 10 で `git diff` / `git show` / `git log -p` の表示を [delta](https://github.com/dandavison/delta)（シンタックスハイライト付きのページャ）に置き換える。**EPEL にも AppStream にも RPM が無い**
  - Windows 11 でも、Git for Windows の git の表示を delta に置き換える（[Windows 11 で使う](../git-delta.md#windows-11-で使う)）
- **進め方**: Homebrew で入れ、`git config --global` で `~/.gitconfig` に書く。**読者が書き換えるのは冒頭の変数ブロックだけ**
  - Windows 11 は、管理者ではない Windows PowerShell 5.1 で `scoop install delta` を貼り、git の設定は WezTerm の Git Bash に[実施手順](../git-delta.md#実施手順)の手順 1・3 を貼る（`C:\Users\<WIN_USER>\.gitconfig`）
- **状態（AlmaLinux 10）**: **x86_64 のクリーン VM で実施手順を本実行済み（2026-10-06）。コンテナでも検証済み（2026-09-22）。実機には入れていない**
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**[Homebrew の導入](../almalinux-setup.md)と手順 2〜4 を通した
  - 確認したこと: `arm64_linux` のボトルが降りる、`delta 0.19.2` が入る、使い捨てリポジトリの `git diff | delta --paging=never` が色付きで出る、`git config --global --get-regexp` で 6 項目が読み戻せる
  - コンテナで未確認だった `core.pager` 経由のページャ起動（`git diff` を素で打ったときの表示）と `navigate` の `n` / `N` は、2026-10-06 のクリーン VM で確認した（末尾の付録）
  - **実機（Raspberry Pi 5）では本実行していない**（実機の `~/.gitconfig` は `[core] autocrlf` と `[user]` だけのまま）ので、下表の実機列は「この手順を適用した結果」ではなく**現時点の状態**を書いてある
  - 2026-10-05: 手順 3 の空チェックを先頭に移した。一時的な Git 設定ファイルで、3 変数を 1 つずつ空にすると変更が無く、正常時には 6 項目が設定されて既存の別キーは残ることを確認した
  - lazygit 0.65.1 の任意設定は、同版の公式資料とソースに合わせて `git.diffRenderers` に訂正した。TUI での連携は未検証のまま
- **状態（Windows 11）**: **Windows の実機では未検証（2026-10-08 に書いた）**
  - 書いた環境（クラウドの Linux のコンテナ）では Windows を動かせなかった。どのブロックも Windows では貼っていない
  - **確かめたこと**（[付録](#付録-windows-11-の配布物と資料の調査2026-10-08)）:
    - 定義: scoop の main の `delta.json`（0.20.1。x64 の `delta-0.20.1-x86_64-pc-windows-msvc.zip` だけで、`delta.exe` の shim。`depends` と `suggest` は無い）と、winget の `dandavison.delta` 0.20.1（同じ zip で、sha256 も同じ。`Microsoft.VCRedist.2015+.x64` に依存）
    - 配布物: その zip の sha256 と中身、`delta.exe` のインポート表（`VCRUNTIME140.dll` と `api-ms-win-crt-*` がある）。Windows の `delta.exe` は動かしていない
    - delta 0.20.1 のソース: ページャの決まり方と、less が見つからないときに標準出力へ書くこと（`src/utils/bat/output.rs`・`src/env.rs`）、Windows の less の検索履歴の写しの場所（`src/features/navigate.rs`）
    - Git for Windows のソース: `cmd\git.exe`（git-wrapper）が `mingw64\bin`・`usr\bin` を PATH の先頭に足すこと
    - Scoop のソース: `install`・`update`・`uninstall` の表示と、arm64 で x64 の定義を使うこと
    - PowerShell のブロック 6 個: Linux の PowerShell 7.5.3 の構文解析器と、PSScriptAnalyzer 1.25.0 の Windows PowerShell 5.1 との互換の検査。偽物の `scoop`・`delta` と本物の git で、[Windows 11 で使う](../git-delta.md#windows-11-で使う)の手順 2・3、[Windows 11 の更新](../git-delta.md#windows-11-の更新)、[Windows 11 のロールバック](../extra/git-delta.md#windows-11-のロールバック)を流した（[付録](#付録-windows-11-の-powershell-のブロックの-linux-での確認2026-10-08)）
  - 関連する確認（この文書の手順ではない）:
    - 自分用の bash の設定の、Windows 11 の実機の Git Bash での検証（ryo-aoki-pc/bash の[2026-10-01 の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-11-の-git-bash-での検証記録2026-10-01)・[2026-10-06 の付録](https://github.com/ryo-aoki-pc/bash/blob/main/docs/verification/install.md#付録-windows-ホストでの設定の再検証2026-10-06)）は、delta を扱っていない（共通の bash 設定は delta を読まない）
    - `~/.gitconfig` が Git Bash・PowerShell 7・cmd で同じファイルになることは、[git.md の検証記録](git.md#付録-windows-11-の-git-bash-での検証記録2026-09-30)で確かめてある
  - **確かめていないこと**:
    - Windows で貼ること（すべての手順）と、`scoop install delta` が作る shim
    - VC++ ランタイムが無い PC での delta の失敗のしかた
    - WezTerm の Git Bash で[実施手順](../git-delta.md#実施手順)の手順 1・3 を貼ること
    - Git Bash と PowerShell の `git diff` が、delta と Git for Windows の less で出ること。色・行番号の見え方と `n` / `N`、`git add -p`
    - [lazygit と組み合わせる（任意）](../git-delta.md#lazygit-と組み合わせる任意)の Windows の lazygit
    - 新しい版が出た後の[Windows 11 の更新](../git-delta.md#windows-11-の更新)と、[Windows 11 のロールバック](../extra/git-delta.md#windows-11-のロールバック)
    - arm64 の Windows と、SSH のセッション

AlmaLinux 10:

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| git | `git 2.52.0`（AlmaLinux の RPM） | 同じ（`2.52.0`） |
| delta | **未導入** | `git-delta 0.19.2` → コマンドは `delta` |
| `~/.gitconfig` | `[core] autocrlf` と `[user]` のみ（**delta の設定は書いていない**） | 手順 3 の 6 項目を設定 |
| lazygit | `lazygit 0.65.1`（Homebrew、[lazygit.md](../lazygit.md)）。`git.paging` は未設定 | 未導入 |
| 端末 | WezTerm nightly（[wezterm-nightly.md](../wezterm-nightly.md)） | 無し（pty を与えずに実行） |

Windows 11（前提にしている環境。書いた時点の値で、実機では流していない）:

| 項目 | 値 |
|---|---|
| OS | Windows 11。x64（arm64 は確かめていない） |
| PowerShell | Windows PowerShell 5.1（管理者ではない窓） |
| scoop | main のバケット（2026-10-08 は delta 0.20.1） |
| delta | 0.20.1（`delta-0.20.1-x86_64-pc-windows-msvc.zip`。x64 だけ） |
| VC++ ランタイム | `VCRUNTIME140.dll`（[wezterm-nightly.md の Windows 11 で使う](../wezterm-nightly.md#windows-11-で使う)の手順 3） |
| git | Git for Windows（[git.md](../git.md#windows-11-で-git-for-windows-を入れる)。`C:\Program Files\Git`、PATH には `cmd` だけ） |
| 使うシェル | WezTerm の Git Bash（git の設定を書く・差分を見る）。PowerShell の git も同じ `~/.gitconfig` を読む |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../git-delta.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${DELTA_NAVIGATE}` | `delta.navigate`。ページャ内の `n` / `N` を変更単位の移動にする | `true`（既定）/ `false` |
> | `${DELTA_LINE_NUMBERS}` | `delta.line-numbers`。差分の左に行番号を出す | `true`（既定）/ `false` |
> | `${DELTA_SIDE_BY_SIDE}` | `delta.side-by-side`。左右 2 面に分けて表示する | `false`（既定）/ `true` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`0.19.2`）は実行日によって変わる。Windows 11 の節に PowerShell の変数は無い（Git Bash に貼る手順 1 の変数は同じ。出力例の Windows のユーザー名は `<WIN_USER>`）。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

AlmaLinux 10（Windows 11 の PC は、[Windows 11 で使う](../git-delta.md#windows-11-で使う)の手順 2 で確かめる）:

| 項目 | 状態 |
|---|---|
| delta | 未導入 |
| Homebrew | 7.0.6 導入済み |
| git | 2.52.0（RPM）。ページャは既定の `less` |
| lazygit | 0.65.1 導入済み（[lazygit.md](../lazygit.md)）。ページャ設定は無し |
| EPEL | 有効。ただし `delta` も `git-delta` も無い |

### 選択した方針

AlmaLinux 10 aarch64 で delta を入れる経路を比べた（2026-09-22 時点）:

### 完了時点の状態

**AlmaLinux 10 の検証コンテナでの出力**（実機では本実行していない。Windows 11 では流していないので、記録は無い）:

```
$ delta --version
delta 0.19.2
$ brew list --versions git-delta
git-delta 0.19.2
$ command -v delta
/home/linuxbrew/.linuxbrew/bin/delta
$ git --version
git version 2.52.0
$ git config --global --get-regexp '^(core\.pager|interactive\.|delta\.|merge\.conflictstyle)'
core.pager delta
interactive.difffilter delta --color-only
delta.navigate true
delta.line-numbers true
delta.side-by-side false
merge.conflictstyle zdiff3
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/git-delta/0.19.2/`（12 ファイル、7.4 MB）。

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](../almalinux-setup.md)と手順 2〜4 を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。差分を出すために `/tmp` に 1 ファイルだけの使い捨てリポジトリを作った。[bat](../almalinux-setup.md) を先に入れた同じコンテナなので、依存は取得済みだった。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](../almalinux-setup.md)） |
| 2. git-delta | `Pouring git-delta--0.19.2.arm64_linux.bottle.tar.gz` → `12 files, 7.4MB`。**依存は取得されなかった**（`libgit2` / `oniguruma` / `zlib-ng-compat` は bat で導入済み）。`brew info git-delta` に `Aliases: delta` と出る |
| 3. git の設定 | 6 項目を `git config --global` で設定。**読み戻しで`interactive.difffilter` と小文字化される**ことが分かり、当初書いていた `interactive\.diffFilter` を含む正規表現では 1 行も出なかったため、本文の正規表現を `interactive\.` に直した |
| 4. 検証 | `delta --version` → `delta 0.19.2`。`git diff \| delta --paging=never` でファイル名ヘッダ・行番号・背景色付きの差分を確認。`git diff \| head`（パイプ）では素の unified diff になることも確認 |
| 設定の確認 | `delta --show-config` で実効値（`true-color = false` など）が出ること、`delta --list-syntax-themes` が `dark` / `light` 別に並ぶことを確認 |
| RPM 経路 | `dnf list --available delta git-delta` → `Error: No matching Packages to list`（EPEL を有効にした状態で） |

#### 未確認事項

- 実機での本実行（本書は実機に適用していない）
- `side-by-side = true` の表示
- `git add -p`（`interactive.diffFilter`）の表示
- `merge.conflictstyle zdiff3` のコンフリクト表示
- [lazygit と組み合わせる（任意）](../git-delta.md#lazygit-と組み合わせる任意)の `git.paging` 設定
- `core.pager` をフルパスにした場合の挙動
- ロールバック（`brew uninstall` と `git config --unset`）の本実行

---

### 付録: クリーン VM での検証記録（2026-10-06）

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、この文書の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: 実施手順 1〜4と、追加のページャ操作。

**結果**: Homebrew の git-delta 0.20.1 を導入し、6 設定を読み戻した。検証用リポジトリの差分を、パイプと `core.pager` 経由の実際の less 661 の画面で表示し、行番号を確認した。複数ファイルと離れた変更を用意し、`n` で変更へ進み `N` で前へ戻った。最初の目印より前に `N` で進もうとすると `Pattern not found` になる。初回の短いキー試験はこの境界に当たったため、前後の目印がある位置でも確認し直した。

**今回の未確認範囲**: lazygit の delta 連携、side-by-side、merge・interactive.diffFilter の実際の操作、更新・ロールバックは今回確認していない。

### 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜4 を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM の SSH 対話 PTY で実行した。delta 0.20.1 の bottle・版・PATH と Git のページャなど 6 設定を確認した
- 使い捨ての Git リポジトリで差分を表示し、ファイル名・行番号と変更行の出力を確認した。実機のリポジトリや資格情報は使っていない
- 更新・削除と任意のテーマ選択はこの再検証では実行していない

### 手順中の実測・検証状況の記録

- この節はコンテナで検証していない（[未確認事項](#未確認事項)）

---

### 付録: Windows 11 の配布物と資料の調査（2026-10-08）

Windows を動かせない環境（クラウドの Linux のコンテナ）で、scoop と winget の定義・配布物・delta と Git for Windows と Scoop のソースを読んだ記録。**Windows の実機では未検証**。

**定義**（2026-10-08 の `ScoopInstaller/Main` と `microsoft/winget-pkgs` の `master`）:

- scoop の `bucket/delta.json`: `version` は `0.20.1`。`architecture` は `64bit` だけで、URL は `https://github.com/dandavison/delta/releases/download/0.20.1/delta-0.20.1-x86_64-pc-windows-msvc.zip`、hash は `c9af7484b33f1dbc1312a892fc7d5753a6d3365140a4000d49e575a2de742c25`、`extract_dir` は `delta-0.20.1-x86_64-pc-windows-msvc`
  - `bin` は `delta.exe` の 1 つ。`depends` と `suggest` は無い（VC++ ランタイムも less も入れない）
- winget の `manifests/d/dandavison/delta/0.20.1/dandavison.delta.installer.yaml`: `InstallerType: zip`・`NestedInstallerType: portable`・`ReleaseDate: 2026-10-04`。`InstallerSha256` は scoop と同じ値。`Dependencies` に `Microsoft.VCRedist.2015+.x64`
- 上流のタグ（`git ls-remote --tags https://github.com/dandavison/delta`）の版の最新は `0.20.1`（その前は `0.20.0`）

**配布物**（scoop の定義の URL から取った zip）:

```
$ sha256sum delta-win.zip
c9af7484b33f1dbc1312a892fc7d5753a6d3365140a4000d49e575a2de742c25  delta-win.zip
$ unzip -l delta-win.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
  7618048  2026-10-04 19:35   delta-0.20.1-x86_64-pc-windows-msvc/delta.exe
     1058  2026-10-04 19:35   delta-0.20.1-x86_64-pc-windows-msvc/LICENSE
     7991  2026-10-04 19:35   delta-0.20.1-x86_64-pc-windows-msvc/README.md
---------                     -------
  7627097                     3 files
$ objdump -p delta-0.20.1-x86_64-pc-windows-msvc/delta.exe | grep 'DLL Name' | awk '{print $3}' | sort -fu | tr '\n' ' '
advapi32.dll api-ms-win-core-handle-l1-1-0.dll api-ms-win-core-synch-l1-2-0.dll api-ms-win-crt-convert-l1-1-0.dll api-ms-win-crt-filesystem-l1-1-0.dll api-ms-win-crt-heap-l1-1-0.dll api-ms-win-crt-locale-l1-1-0.dll api-ms-win-crt-math-l1-1-0.dll api-ms-win-crt-runtime-l1-1-0.dll api-ms-win-crt-stdio-l1-1-0.dll api-ms-win-crt-string-l1-1-0.dll api-ms-win-crt-time-l1-1-0.dll bcryptprimitives.dll combase.dll iphlpapi.dll kernel32.dll netapi32.dll ntdll.dll ole32.dll oleaut32.dll pdh.dll powrprof.dll psapi.dll Secur32.dll shell32.dll VCRUNTIME140.dll ws2_32.dll
```

- `delta.exe` は `PE32+ executable (console) x86-64`（`file` の表示）。インポート表に `VCRUNTIME140.dll` がある（msvc のビルドで、CRT を静的にリンクしていない）。`api-ms-win-crt-*` は Windows 10 以降に付いている UCRT
- PE のセキュリティのディレクトリは空で、Authenticode の署名は無い

**delta 0.20.1 のソース**（`0.20.1` のタグ）:

- `src/env.rs`: ページャの候補は、`DELTA_PAGER` と、bat の `get_pager_executable`（`BAT_PAGER`、無ければ `PAGER`）
- `src/utils/bat/output.rs`: `delta.pager`（`--pager`）があればそれを、無ければ環境変数の候補を、どれも無ければ `less` を使う。`grep_cli::resolve_binary` で PATH から探し、見つからなければ、ページャを起動せずに標準出力へ書く。`less` には `--RAW-CONTROL-CHARS` と（1 画面に収まれば終わる）`--quit-if-one-screen` を渡し、Windows では less の版が 558 より前なら `--no-init` も足す
- `src/features/navigate.rs`: `navigate` が `true` のとき、less の検索履歴の写しを作って `LESSHISTFILE` で渡す。場所は、Windows では `dirs::data_local_dir()` の下の `delta\delta.lesshst`（`%LOCALAPPDATA%\delta\delta.lesshst`）、Linux では XDG の data の下の `delta/lesshst`
- 上流の文書（`manual/src/tips-and-tricks/using-delta-on-windows.md`）: Windows では新しい `less.exe` が要る（`jftuga/less-Windows` を案内）。色が崩れたり変な文字が出たりするときは、古い `less.exe` を拾っている

**Git for Windows のソース**（`git-for-windows/MINGW-packages` の `main` の `mingw-w64-git`、2026-10-08）:

- `mingw-w64-git.mak`: `cmd/git.exe` は、`git-wrapper.o` と `git.res`（版の情報）から作る
- `git-wrapper.c`: `main` の `full_path` の既定は 1 で、`MINIMAL_PATH=1 ` の文字列のリソースがあるときだけ 0 になる。`setup_environment` は、`full_path` が 1 なら PATH の先頭に `<Git>\mingw64\bin;<Git>\usr\bin;<HOME>\bin;` を足してから、本体の git を動かす（0 なら `<Git>\cmd;` だけ）
- そのため、PowerShell の PATH に Git の `cmd` しか無くても（Git for Windows の既定の `Path Option=Cmd`。[git.md の検証記録](git.md#付録-windows-11-の配布物と資料の調査2026-10-03)）、git が起動する delta には `usr\bin` の less が見えるはず

**Scoop のソース**（`ScoopInstaller/Scoop` の `master`、2026-09-30 のコミット `e6aa3b3`）:

- `lib/install.ps1`: 入れ終わると `'<名前>' (<版>) was installed successfully!`。そのアプリのフォルダーのプロセスが動いていると `The following instances of "<名前>" are still running. Close them and try again.`
- `libexec/scoop-install.ps1`: 名前を 1 つだけ渡し、そのアプリが入っていれば、`'<名前>' (<版>) is already installed.` と `Use 'scoop update <名前>' to install a new version.` の警告を出して終わる（`$apps.length -eq 1` の分かれ）。`'<名前>' (<版>) is already installed. Skipping.` は名前を並べたときの分かれのもので、main のアプリには出ない（[windows-setup.md の付録](windows-setup.md#付録-シェルのツールの任意節のブロックの確認2026-10-08)）
- `libexec/scoop-update.ps1`: `scoop update` は `Scoop was updated successfully!`。名前を付けて新しい版が無いと `<名前>: <版> (latest version)`。動いているときは `Running process detected, skip updating.` で飛ばす
- `libexec/scoop-uninstall.ps1`・`lib/core.ps1`: 成功は `'<名前>' was uninstalled.`、入っていなければ `'<名前>' isn't installed.`
- `lib/manifest.ps1` の `Get-SupportedArchitecture`: arm64 の定義が無いアプリは、Windows 11（ビルド 22000 以降）では `64bit` の定義を使う

**残っている未確認事項**:

1. Windows で、すべての手順を貼って通すこと
1. `scoop install delta` が `delta.exe` の shim を作り、`(Get-Command delta -All).Source` が scoop の shims の 1 行になること
1. VC++ ランタイムが無い PC で、delta がどう失敗するか（[Windows 11 で使う](../git-delta.md#windows-11-で使う)の手順 2 で止める前提）
1. WezTerm の Git Bash で、[実施手順](../git-delta.md#実施手順)の手順 1・3 が通り、6 項目が読み戻せること
1. Git Bash と PowerShell の `git diff` が、delta と Git for Windows の less で出ること（PowerShell の git が `usr\bin` を足すのはソースから）。色・行番号の見え方、`n` / `N`（`%LOCALAPPDATA%\delta\delta.lesshst`）
1. `git add -p`（`interactive.diffFilter`）と、Windows の lazygit の `git.diffRenderers`
1. 新しい版が出た後の[Windows 11 の更新](../git-delta.md#windows-11-の更新)、less を開いたままの `Running process detected`、[Windows 11 のロールバック](../extra/git-delta.md#windows-11-のロールバック)
1. arm64 の Windows（x64 の版をエミュレーションで動かす）と、SSH のセッション（scoop の shim と RedirectionGuard）

---

### 付録: Windows 11 の PowerShell のブロックの Linux での確認（2026-10-08）

Linux（クラウドのコンテナ）の PowerShell 7.5.3 と PSScriptAnalyzer 1.25.0、git 2.43.0 で確かめた。**Windows の実機では未検証**。

**構文と Windows PowerShell 5.1 との互換**:

- 手順書の Windows 11 の 3 節の `powershell` のブロック 6 個（Windows 11 で使うの手順 2・3、更新の手順 1、ロールバックの手順 1〜3）を取り出し、PowerShell 7.5.3 の構文解析器に通した（構文の誤り 0）
- PSScriptAnalyzer の `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows 10 1809 の Windows PowerShell 5.1 のプロファイル）と、既定の規則の Error・Warning を当てた（指摘 0）
  - 同じ設定で、`??` を書いたファイル・`Get-Content -AsByteStream` を書いたファイル・`}` の足りないファイルは、それぞれ指摘された
- 最後に（2026-10-08、手順書の今のブロックを取り出し直して）、6 個を構文解析器にもう一度通し（誤り 0）、互換の規則を `PSUseCompatibleSyntax`（5.1）・`PSUseCompatibleCommands`・`PSUseCompatibleTypes`（同梱の Windows PowerShell 5.1 のプロファイル 3 つ。Windows Server 2016・Windows Server 2019・Windows 10 Pro）・`PSUseCompatibleCmdlets`（`desktop-5.1.14393.206-windows`）にして当てた。互換の指摘も既定の規則の指摘も 0 個（[windows-setup.md の付録](windows-setup.md#付録-シェルのツールの任意節のブロックの確認2026-10-08)と同じ回）

**模擬**:

- 偽物: `scoop`（渡った引数を記録し、`install` で偽物の `delta` を shims のフォルダーに置き、`update` と `uninstall` は Scoop のソースと同じ形の行を返すシェルスクリプト）と、`--version` に `delta 0.20.1` を返す `delta`
- `HOME` は使い捨てのフォルダー（`[user]` だけの `.gitconfig`）、`WINDIR` は `System32\vcruntime140.dll` だけを置いた使い捨てのフォルダーにした。管理者の判定（`WindowsPrincipal`）は Linux では使えないので `$false` に置き換え、出力は `Out-String -Width 200` で受けた
- Windows 11 で使うの手順 2: 入れる前は `Admin : False`・`VCRuntime : True`・`Delta` が空。入れた後は `Delta` が shims の `delta` の 1 つ。`vcruntime140.dll` を消すと `VCRuntime : False`。git を PATH から外すと `Git` が空になり、エラーは出なかった
- 手順 3: 1 回目は偽物の `'delta' (0.20.1) was installed successfully!` の後に `delta 0.20.1` と shims の `delta` の 1 行。2 回目は偽物の `is already installed. Skipping.` の後に同じ 2 行
  - 偽物の警告を、名前 1 つのときの形（`WARN  'delta' (0.20.1) is already installed.` と `Use 'scoop update delta' to install a new version.`）に直して流し直した（2026-10-08 の 2 回目）。2 回目はその 2 行の後に、同じ 2 行が出た
- 手順 4 の代わりに、[実施手順](../git-delta.md#実施手順)の手順 1・3 の bash のブロックを手順書から取り出して bash で流した: 変数の 3 行と、`core.pager delta`・`interactive.difffilter delta --color-only`・`delta.navigate true`・`delta.line-numbers true`・`delta.side-by-side false`・`merge.conflictstyle zdiff3` の 6 行。`.gitconfig` の `[user]` は残った
- 更新の手順 1: 偽物の `Scoop was updated successfully!` と `delta: 0.20.1 (latest version)` の後、`delta 0.20.1`
- ロールバックの手順 1: 何も出さず、`.gitconfig` には `[user]` と `[merge] conflictstyle = zdiff3` だけが残った。もう一度貼ると、`fatal: no such section: delta` の 1 行だけ
- ロールバックの手順 2: 何も出さず、`[merge]` も消えて `[user]` だけが残った
- ロールバックの手順 3: 偽物の `'delta' was uninstalled.` の後、2 行目は何も出さなかった。もう一度貼ると偽物の `'delta' isn't installed.`
- 最後に（2026-10-08、手順書の今のブロックを取り出し直して）、偽物を作り直して全部を流し直した（偽物の `scoop` の警告は、名前 1 つのときの形）。手順 2（入れる前・`vcruntime140.dll` が無いとき・git が PATH に無いとき・入れた後）、手順 3 の 1 回目と 2 回目、[実施手順](../git-delta.md#実施手順)の手順 1・3 の 6 行、更新の手順 1、ロールバックの手順 1〜3 と 2 回目は、上と同じ結果だった。`.gitconfig` には、同じ使い捨ての `HOME` で先に流した gh の模擬の `[credential "https://example.com"]` も残った（delta の手順は触らなかった）
- 本物の scoop の表示、Windows の `Get-Command` が返す shim のパス、Windows の git・less・delta での表示は、Windows で動かしていないので確かめていない
