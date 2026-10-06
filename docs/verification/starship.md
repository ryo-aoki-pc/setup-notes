# starship インストール手順（AlmaLinux 10 / Homebrew）の検証記録

[手順書](../starship.md)

以下は文書分離前から保存されている記録です。実施日・対象版・実行範囲は各記録に従います。

## 補足

### 実施手順: 検証状況の記録

> [!WARNING]
> **直接追記していた旧版の導入・プロンプト・プリセットは、コンテナと x86_64 のクリーン VM で検証済み**。現行の共通 bash 設定の新規導入・常時表示も別の新規 VM で再検証した（末尾の記録）。既存ホストの移行は今回は未実施。ユーザー切り替え時の表示条件と常時表示の設定は、aarch64 の実機で確認した（[対象と検証環境](#対象と検証環境)）。

### 実施手順 / 手順 5: 補足: 端末が無くても確かめられる

starship は「プロンプト文字列を標準出力に出す」だけのコマンドなので、**pty が無い環境でも動作確認ができる**。コンテナでの実測（ANSI エスケープは除いてある）:

```
$ starship prompt

~
⬢ [podman] ❯
$ starship module directory
~
$ starship explain

 Here's a breakdown of your prompt:
 ~                     -  The current working directory
 container  [podman]   -  The container indicator, if inside a container.
 >                     -  A character (usually an arrow) beside where the text is entered in your terminal
$ starship timings

 Here are the timings of modules in your prompt (>=1ms or output):
 directory   -  <1ms  -   "~ "
 line_break  -  <1ms  -   "\n"
 container   -  <1ms  -   "\n"
 character   -  <1ms  -   "> "
```

- `container [podman]` はコンテナの中で実行したから出ているモジュールで、実機では出ない
- `explain` の 3 行目が `>` になっているのは、`plain-text-symbols` プリセットを当てた後だから（既定は `❯`）

**確かめられるのはここまで**で、`PS1` として実際に描画されたときの見た目、色、Nerd Font のグリフは端末が要る。

### ユーザー名とホスト名を常に表示する / 手順 1: 補足: ユーザーを切り替えると表示が消える理由

- 既定の `username.show_always = false` では、root・ログイン名と異なるユーザー・SSH 接続などの条件でユーザー名を出す。`hostname.ssh_only = true` では、`SSH_CONNECTION` があるときだけホスト名を出す
- `sudo` の `env_reset` と `su -` は SSH 関連の環境変数を消す。`sudo su -` → `su - 自分のユーザー` と切り替えると、一般ユーザーで `LOGNAME` も自分の名前になり、既定の表示条件を満たさなくなる
- `su - 自分のユーザー` は新しいシェルを起動する。元のシェルへ戻るには root で `exit` する。既に一般ユーザーのシェルを重ねた場合は `exit` を 2 回実行する
- この節の設定は SSH 判定に依存せず名前を出す。環境変数が消える動作自体は変えない（[実測](#付録-ユーザー切り替えと常時表示の確認2026-10-06)、[公式の username 設定](https://starship.rs/config/#username)、[hostname 設定](https://starship.rs/config/#hostname)）

### ロールバック / 手順 0: 本文中の記録

- 本書ではロールバックは**本実行していない**



- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

### 対象と検証環境

- **目的**: AlmaLinux 10 のシェルプロンプトを [starship](https://starship.rs/)（git の状態・言語バージョン・終了コードなどを自動で出すプロンプト）に置き換える。**EPEL にも AppStream にも RPM が無い**
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**:
  - **直接追記していた旧版の導入手順はコンテナで検証済み**（2026-09-22、並びを直した当時の手順 3〜7 とプリセットの節の手順 2 は 2026-09-30）
  - **x86_64 のクリーン VM では `0dbb522` 版の導入・プロンプト・プリセットを本実行済み**（2026-10-06）。共通 bash の新規導入・常時表示は別の新規 VM で再検証した（末尾の記録）。既存ホストの移行は今回は未実施（[今回の付録](#付録-クリーン-vm-での検証記録2026-10-06)）
  - **ユーザー切り替え時の表示条件と常時表示の設定は aarch64 の実機で確認済み**（2026-10-06）
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**[Homebrew の導入](../homebrew.md)と手順 2・4・7、[プリセットを当てる（任意）](../starship.md#プリセットを当てる任意)・[設定ファイル](../starship.md#設定ファイル)を通した
  - 2026-09-30 に、並びを直した手順 3〜7 とプリセットの節の手順 2 を、x86_64 のコンテナで流し直した（[付録](#付録-並びを直した版の検証2026-09-30)）。WezTerm のシェル統合と zoxide と一緒に読んだ対話のシェルを、`script` の擬似端末で動かして生の出力を見た
  - 確認したこと: `arm64_linux` のボトルが降りる、`starship 1.26.0` が入る、`starship prompt` / `module` / `explain` / `timings` が端末なしでも文字列を返す、`~/.bashrc` への追記と差し込み（前の版の並びからの移動と、後ろにあった `brew shellenv` の行の移動も）、WezTerm のシェル統合の OSC 133 の `C` / `D`（終了コード）と、zoxide の警告が出ないこと
  - SSH の PTY での実際のプロンプト表示と `plain-text-symbols` プリセットは、2026-10-06 に `0dbb522` 版をクリーン VM で確認した。GNOME 端末・WezTerm の画面での色・グリフと、WezTerm でのプロンプトへのジャンプ・出力のコピーは未確認
  - 実機では導入済みの starship 1.26.0 を使い、SSH 関連の環境変数による表示の変化と、一般ユーザーの常時表示設定を確認した。導入・更新・削除は再実行していない（[付録](#付録-ユーザー切り替えと常時表示の確認2026-10-06)）
  - 下表の実機列は **2026-09-22 時点の状態**で、本書の導入手順を適用した結果ではない。2026-10-06 の実機の状態は付録に記録した

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| starship | **未導入** | `starship 1.26.0`（`arm64_linux` ボトル） |
| 一緒に入る依存 | — | `expat` / `dbus` / `zlib-ng-compat` |
| `~/.bashrc` | 38 行。26 行 `brew shellenv` / 27-33 行 yazi の `y()` / 34 行 `zoxide init` / 36-38 行 WezTerm シェル統合 | 手順 4 で `starship init` を末尾に追記 |
| Nerd Font | `font-symbols-only-nerd-font 3.5.1`（Homebrew、[yazi.md](../yazi.md)） | 無し |
| 端末 | WezTerm nightly（[wezterm-nightly.md](../wezterm-nightly.md)。OSC 133 のシェル統合あり） | 無し（pty を与えずに実行） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](../starship.md#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${STARSHIP_PRESET}` | [プリセットを当てる（任意）](../starship.md#プリセットを当てる任意)で使う名前 | `plain-text-symbols`（既定）/ `no-nerd-font` / `tokyo-night` |
>
> 出力例の値は `<HOSTNAME>` / `<USER>` のプレースホルダで書いてある。バージョン（`1.26.0`）は実行日によって変わる。

手順書全体に関わる理由・実測・落とし穴と検証記録（手順ごとのものは各手順の末尾の「補足」にある）。手順を実行するだけなら読まなくてよい。

### 実施前の状態

| 項目 | 状態 |
|---|---|
| starship | 未導入 |
| Homebrew | 7.0.6 導入済み |
| プロンプト | bash の既定（`/etc/bashrc` が組み立てた `PS1`）に、WezTerm のシェル統合が OSC 133 の印を前後に足したもの |
| `~/.bashrc` | 38 行。末尾に zoxide の初期化と WezTerm シェル統合の読み込みがある |
| EPEL | 有効。ただし `starship` は無い |

### 選択した方針

AlmaLinux 10 aarch64 で starship を入れる経路を比べた（2026-09-22 時点）:

### 完了時点の状態

**検証コンテナでの出力**（実機では本実行していない）:

```
$ starship --version
starship 1.26.0
branch:
commit_hash:
build_time:2026-06-28 17:02:30 +00:00
build_env:rustc 1.96.0 (ac68faa20 2026-05-25) (Homebrew),
$ brew list --versions starship
starship 1.26.0
$ command -v starship
/home/linuxbrew/.linuxbrew/bin/starship
$ grep -n 'starship init' ~/.bashrc
28:eval "$(starship init bash)"
$ wc -l ~/.config/starship.toml
335 /home/<USER>/.config/starship.toml
```

実体は `/home/linuxbrew/.linuxbrew/Cellar/starship/1.26.0/`（12 ファイル、11 MB）。

### 操作上の注意と併記されていた記録

- **starship の初期化は、`brew shellenv` の行より後ろ、zoxide の初期化と WezTerm のシェル統合より前に置く**: zoxide・WezTerm より後ろにあると、この設定の WezTerm のシェル統合が働くとき（COPR の公式の統合が無いとき）は、WezTerm に送る終了コード（OSC 133 の `D`）がいつも 0 になる（[bash の読む順番](https://github.com/ryo-aoki-pc/bash#読む順番)の実測）。`brew shellenv` より前にあると、`starship: command not found` になる

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](../homebrew.md)と手順 2・4・7、[プリセットを当てる（任意）](../starship.md#プリセットを当てる任意)・[設定ファイル](../starship.md#設定ファイル)を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。[bat](../bat.md) / [git-delta](../git-delta.md) / [eza](../eza.md) / [gdu](../gdu.md) を先に入れた同じコンテナで続けている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](../homebrew.md)） |
| 2. starship | `Pouring expat--2.8.5` → `dbus--1.16.2_1` → `starship--1.26.0.arm64_linux.bottle.tar.gz` の順に降り、`12 files, 11MB`。ソースビルドは発生しない |
| 4. 初期化 | `~/.bashrc` に `eval "$(starship init bash)"` を追記して読み込み直し、エラーなく通った（非対話シェルなのでプロンプト自体は描画されない） |
| 7. 検証 | `starship --version` → `1.26.0`（`build_env` に `rustc 1.96.0 ... (Homebrew)`）。`starship prompt` / `module directory` / `explain` / `timings` がいずれも文字列を返した |
| プリセット | `starship preset --list` で 12 個（`bracketed-segments` / `catppuccin-powerline` / `gruvbox-rainbow` / `jetpack` / `nerd-font-symbols` / `no-empty-icons` / `no-nerd-font` / `no-runtime-versions` / `pastel-powerline` / `plain-text-symbols` / `pure-preset` / `tokyo-night`）。`plain-text-symbols` を `-o` で書き出して 335 行の `starship.toml` が生成され、`starship explain` のプロンプト記号が `❯` から `>` に変わることを確認 |
| 初期化の中身 | `starship init bash --print-full-init` を読み、`PS1` を毎回組み立て直すこと・既存の `PROMPT_COMMAND` を `STARSHIP_PROMPT_COMMAND` に退避して呼ぶこと・`PS0` には前置きすることを確認（[手順 3 の補足](../starship.md#実施手順)の根拠） |
| RPM 経路 | `dnf list --available starship` → `Error: No matching Packages to list`（EPEL を有効にした状態で） |

#### 未確認事項

- 実機での本実行（本書は実機に適用していない。検証はコンテナのみ）
- 端末での実際のプロンプト表示（色、記号、git 情報、Nerd Font のグリフ）
- **WezTerm のシェル統合との相性**（OSC 133 の `A` / `B` が失われるという推定の実地確認。`C` / `D` が残るかも未確認）
- zoxide の `PROMPT_COMMAND` フックとの共存
- Raspberry Pi 5 の microSD 上の大きなリポジトリでのプロンプト遅延
- `plain-text-symbols` 以外のプリセット
- `~/.bashrc` で `export STARSHIP_CONFIG=...` して場所を変える方法
- bash 以外のシェル（zsh / fish）での `starship init`
- ロールバック（`brew uninstall` と `~/.bashrc` の行削除）の本実行

### 付録: 並びを直した版の検証（2026-09-30）

手順 3〜5 を「starship を zoxide の初期化と WezTerm のシェル統合より前に置く」に直した版を、x86_64 のクラウドホストの Docker で立てた `almalinux:10`（AlmaLinux 10.2、bash 5.2.26）で流した。Homebrew 7.0.7 で starship 1.26.0 と zoxide 0.10.0 を入れた。WezTerm と COPR の公式の統合は入れず、ryo-aoki-pc/wezterm の設定を `~/.config/wezterm` に clone した（`shell/wezterm.sh` は、印を BEL で終える直しの入ったもの）。**この文書のコードブロックを抜き出したもの**を、そのユーザーの `bash -s` に流した。

| ユーザー（実施前の `~/.bashrc` の末尾） | 流した手順 | 結果 |
|---|---|---|
| st1（実機と同じ並び: 26 行目 `brew shellenv`、27〜33 行目 `y()`、34 行目 `zoxide init bash`、36〜38 行目 WezTerm の `if [ -n "$WEZTERM_SHELL_INTEGRATION" ]; then` の 3 行） | 手順 3・5（当時の、`brew shellenv` の行を動かさない版）・7 | 手順 3 は `34:eval "$(zoxide init bash)"` と WezTerm の 2 行。手順 5 の後は `34:eval "$(starship init bash)"`・`35:eval "$(zoxide init bash)"`・`37:if [ -n "$WEZTERM_SHELL_INTEGRATION" ]; then`。手順 7 は `starship 1.26.0` などを出した |
| st2（`/etc/skel` の後ろに `brew shellenv` だけ） | 手順 3・4、手順 1 とプリセットの節の手順 2 | 手順 3 は何も出さず、手順 4 は `eval "$(starship init bash)"`。プリセットは `335 /home/<USER>/.config/starship.toml` と `starship prompt` の出力 |
| st3（前の版のこの文書の並び: `zoxide init bash --cmd z` → WezTerm の 1 行 → starship が最後） | 手順 3・5（当時の版） | 手順 3 は 27〜29 行目の 3 行。手順 5 の後は starship が 27 行目に移り、zoxide と WezTerm の行が 28・29 行目。starship の行は 1 つだけ |

- st1 と st3 で、`TERM_PROGRAM=WezTerm` と WezTerm が渡す `WEZTERM_SHELL_INTEGRATION` を付けて `script` の擬似端末の `bash -il` を開き、`false`・`sleep 3`・`cd /usr/share`・`z share` などを打ち込んで、生の出力を見た
  - OSC 133 は、コマンドごとに `C`、`false` の後は `D;1`（ほかは `D;0`）。`A` / `B` は出なかった（starship が `PS1` を作り直すため）
  - `zoxide: detected a possible configuration issue.` は出ず、`sleep 3` の後のプロンプトに `took 3s` が出た。`${STARSHIP_START_TIME:0:0}` の文字は出なかった
  - `PROMPT_COMMAND` は `([0]="__wezterm_prompt_command;__wz_mouse_off;starship_precmd" [1]="__zoxide_hook")`。環境変数で文字列の `PROMPT_COMMAND=:` を渡して開いたシェル（Git Bash と同じ形）でも、`D;1` で警告は出なかった
- 前の版の並び（starship が最後）は、同じ方法で `D` がいつも `D;0` で、文字列の `PROMPT_COMMAND` では `z` が警告を出した（自分用の bash の設定 ryo-aoki-pc/bash の README の「読む順番」）
- `. ~/.bashrc` で読み直すと、配列の `PROMPT_COMMAND` に zoxide のフックが 2 つ入った（zoxide は配列の先頭しか見ない。並びとは関係が無い）

#### 手順 5 に `brew shellenv` の行の移動を足した後（2026-09-30 の夜）

手順 5 を、`brew shellenv` の行が zoxide か WezTerm の行より後ろにあれば starship の行と一緒に前へ移す形に、手順 6 を端末を開き直す手順に直した後、同じコンテナで、この文書のコードブロックを抜き出し直して流した。どのユーザーも、`/etc/skel` の `~/.bashrc` の後ろに下の行を置いてから始めた。

| ユーザー（実施前の並び） | 流した手順 | 結果（手順 5 の後の並び） |
|---|---|---|
| sa（`brew shellenv` → `zoxide init bash --cmd z` → WezTerm の 1 行） | 手順 3・5 | 26 行目 `brew shellenv` → starship → zoxide → WezTerm |
| sb（WezTerm の 1 行 → `brew shellenv` → zoxide） | 手順 3・5・5 | `brew shellenv` が WezTerm の行の上に移り、26 行目 `brew shellenv` → starship → WezTerm → zoxide。2 回目の手順 5 では変わらなかった |
| sc（前の版のこの文書の並び: `brew shellenv` → zoxide → WezTerm → starship） | 手順 5 | 26 行目 `brew shellenv` → starship → zoxide → WezTerm。starship の行は 1 つだけ |
| sd（WezTerm の 1 行 → `brew shellenv` → starship） | 手順 3・5 | 26 行目 `brew shellenv` → starship → WezTerm |
| se（`brew shellenv` → starship） | 手順 3・5 | 変わらなかった |
| sf（`brew shellenv` → WezTerm → starship → zoxide） | 手順 3・5 | 26 行目 `brew shellenv` → starship → WezTerm → zoxide |
| sg（`brew shellenv` だけ） | 手順 3・4、手順 1 とプリセットの節の手順 2 | 手順 3 は 26 行目の `brew shellenv` だけを出し、手順 4 で末尾に starship。プリセットは `335 /home/<USER>/.config/starship.toml` |

- どのユーザーも、手順の後に `su -` で開いた新しいログインシェルは何も出さなかった（`command not found` が無い）
- sa と sf で、手順 1 と手順 7 を流すと、`starship 1.26.0` と `starship prompt` の出力が出た
- 手順 6 の代わりに、`script` の擬似端末で `bash -il` を開き直し、上の表の st1・st3 と同じコマンドを打ち込んだ（sa・sb・sc・sf・sg）
  - sa・sb・sc・sf: `false` の後だけ `D;1`（ほかは `D;0`）、zoxide の警告は 0 回、`sleep 3` の後に `took` が出た。`PROMPT_COMMAND` はどれも `([0]="__wezterm_prompt_command;__wz_mouse_off;starship_precmd" [1]="__zoxide_hook")`
  - sg（WezTerm の行が無い）: OSC 133 の印は出ず、`PROMPT_COMMAND` は `([0]="starship_precmd")`
  - `. ~/.bashrc` で読み直すと、zoxide のフックが 2 つになるのは上と同じ

#### 未確認事項（並びを直した版）

- 端末の画面でのプロンプトの見た目、WezTerm でのプロンプトへのジャンプ・出力のコピー
- 実機（Raspberry Pi 5）での本実行
- COPR の WezTerm の公式の統合がある実機での、この並び

### 付録: ユーザー切り替えと常時表示の確認（2026-10-06）

- **環境**: AlmaLinux 10.2 / aarch64 の実機（Raspberry Pi 5）、導入済みの starship 1.26.0、util-linux の su 2.40.2。一般ユーザーは bash の共通設定を導入済み
- **再現**: 設定ファイルが無い既定の状態で、`sudo su -` → `su - 自分のユーザー` を `-c` の子シェルで再現し、環境変数の有無と `starship module username` / `hostname` の出力を確認した

| 状態 | SSH_CONNECTION / SSH_CLIENT | USER / LOGNAME | username の出力 | hostname の出力 |
|---|---|---|---|---|
| 最初の一般ユーザー | あり / あり | 自分 / 自分 | `<USER> in ` | `🌐 <HOSTNAME> in ` |
| root へ切り替えた後 | なし / なし | root / root | `root in ` | 空 |
| 一般ユーザーのシェルを起動した後 | なし / なし | 自分 / 自分 | 空 | 空 |
| 子シェルを終了して元のシェルに戻った後 | あり / あり | 自分 / 自分 | `<USER> in ` | `🌐 <HOSTNAME> in ` |

- `SSH_TTY` は最初から未設定だった。`sudo` だけでも SSH 関連の変数が消え、対象の 3 変数を `sudo --preserve-env` で渡しても、続く `su -` で消えた
- `SSH_CONNECTION` だけを与えると両方が出た。`SSH_CLIENT` または `SSH_TTY` だけではユーザー名だけが出た
- 一般ユーザーの `~/.config/starship.toml` に `username.show_always = true` と `hostname.ssh_only = false` を設定した。`sudo su -` → `su - 自分のユーザー` を再実行し、SSH 関連の 3 変数がなくても両方のモジュールが出ることを確認した
- [常時表示の手順](../starship.md#ユーザー名とホスト名を常に表示する)の `starship config` は、一時設定ファイルで新規作成と更新を確認した。既存の directory・character の設定とコメントを保ち、再実行しても TOML のセクションが重複しなかった
- 確認対象はモジュールの生成文字列。端末の画面での色・記号、root の設定変更、パッケージの導入・更新・削除は今回の検証対象に含めていない

---

### 付録: クリーン VM での検証記録（2026-10-06）

**検証した版**: `0dbb522` 版（`~/.bashrc` に直接追記していた版）を検証した。後から入った共通 bash 設定の導入・移行と、[ユーザー名とホスト名を常に表示する](../starship.md#ユーザー名とホスト名を常に表示する)任意節は今回の VM で未実施。以下の手順番号は、現行手順ではなく、検証した `0dbb522` 版の番号を示す。

**環境**: AlmaLinux 10.2 Workstation の新規インストールを clone した x86_64 の VirtualBox VM。カーネルは `6.12.0-211.61.1.el10_2.x86_64`、SELinux は Enforcing、ロケールは `ja_JP.UTF-8`。一般ユーザーの SSH 対話 PTY（`TERM=xterm-256color`、120×40）に、検証した旧版の折り畳みの外のブロックを手順ごとにブラケットペーストで送り、プロンプトに戻ってから次へ進めた。専用 SSH 鍵・sudo・LAN は検証補助として用意し、GDM は停止した。自分用の bash 設定は導入せず、OS 既定の `~/.bashrc` から始めた。実機の設定・資格情報は使っていない。

**通した手順**: `0dbb522` 版の実施手順 1・2・3・5・6・7、プリセットの任意節 1・2（zoxide が既存のため、当時の手順 4 は条件外）。

**結果**: Homebrew の starship 1.26.0 を導入した。既存の zoxide 初期化の前へ、検証した旧版の手順 5 で差し込み、`brew shellenv` → starship → zoxide の順を確認した。今のシェルでは読み直さず SSH を切り、再ログインしたシェルで実際のプロンプトと `prompt`・`module directory`・`explain` を確認した。`plain-text-symbols` プリセットを適用すると、335 行の設定が作られ、次のプロンプトから ASCII の `>` と `ssh` の表示に変わった。

**今回の未確認範囲**: 現行の共通 bash 設定の導入・移行、ユーザー名とホスト名の常時表示、WezTerm のシェル統合と OSC 133、別の並びからの移動、別のプリセット・手動設定、更新・ロールバックは今回の VM で確認していない。常時表示を確認した aarch64 の実機の記録は、前の付録に分けて残した。

### 付録: 現行版の新規 VM での再検証（2026-10-06）

- `5da3478` の実施手順 1〜5 と「ユーザー名とホスト名を常に表示する」を、新規導入した AlmaLinux 10.2 Workstation の x86_64 VM で共通 bash `3d5323e` の導入後に実行した。starship 1.26.0 を導入した後は対話 SSH を張り直し、init とプロンプト・`starship explain` を確認した
- 既存の `add_newline = false` を残して `[username] show_always = true` / `[hostname] ssh_only = false` を設定した。SSH 環境変数を外したシェルでも名前・ホスト名が出た。共通設定を読み直しても `PS0` と `PROMPT_COMMAND` は増えなかった
- 任意のプリセット節と設定ファイル例も通した。既存設定への `preset -o` は上書きを拒否し、後続の `wc` / `prompt` で成功に見えたため、本文に `--force` を足し、成功時だけ後続確認へ進む `&&` でつないだ。事前に設定を控え、335 行の `plain-text-symbols` と `>` のプロンプトを確認した後、元の設定を SHA-256 の一致まで戻した
- 実際の別ユーザーへの切り替え、GUI 端末、更新・削除はこの再検証には含まない


### 操作上の注意と併記されていた記録

   - 今のシェルで `. ~/.bashrc` を読み直さない（starship が、そのシェルで既に読んだ WezTerm のシェル統合より後ろで初期化され、WezTerm のフックが 2 回ずつ動く。失敗したコマンドの後に `D;1` と `D;0` が続けて送られた）

## 参考資料から分離した記録

### 参考資料: 実施手順 / 手順 2: 補足: 降ってくるボトル

aarch64 で降ってくるボトルは `starship--1.26.0.arm64_linux.bottle.tar.gz`。

### 参考資料: 選択した方針

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `starship 1.26.0` の `arm64_linux` ボトルがある。upstream の最新と一致 | **採用** |
| EPEL / AppStream / CRB | **`starship` というパッケージが無い**（`dnf list --available starship` → `Error: No matching Packages to list`） | 使えない |
| 公式 install.sh（`sh -c "$(curl -sS https://starship.rs/install.sh)"`） | `/usr/local/bin` にバイナリを 1 つ置く。`sudo` が要り、更新は自分で再実行する | 不採用（Homebrew に揃える） |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-musl` のビルドがある。更新は手作業 | 不採用 |
| `cargo install starship` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |
