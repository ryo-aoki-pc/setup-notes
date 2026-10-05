# starship インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

- **前提**: [共通の bash 設定](../README.md#共通の-bash-設定を先に入れる)を導入する。ツール別の設定は bash リポジトリで管理し、`~/.bashrc` には追記しない

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew の導入・更新は root では行わず、共通設定とツールの設定は自分のユーザーで使うため）
> - **手順 4 は、端末を開き直す操作**。手順 5 は、開き直した端末で貼る

- 手順 1 で変数を設定したシェルで、上から順にコードブロックを貼る
- 各手順の末尾の「補足」（折り畳み）と後半の[補足](#補足)は、実行するだけなら読まなくてよい。折り畳みの中のブロックも貼らなくてよい
- 手順の後: 見た目を変えるなら[プリセットを当てる（任意）](#プリセットを当てる任意)。細かい調整は[設定ファイル](#設定ファイル)、以後は[更新](#更新)・[ロールバック](#ロールバック)

> [!WARNING]
> **コンテナでのみ検証した手順書**で、実機では本実行していない（[対象と検証環境](#対象と検証環境)）。

1. 変数を設定する。

   ```bash
   STARSHIP_PRESET=plain-text-symbols        # 任意手順で当てるプリセット。<STARSHIP_PRESET>
   printf 'STARSHIP_PRESET = %s\n' "${STARSHIP_PRESET}"
   ```

   - **編集が必須の変数は無い**。既定のままなら starship の組み込みの見た目になり、設定ファイルは作られない
   - [プリセットを当てる（任意）](#プリセットを当てる任意)まで進むときだけ、`STARSHIP_PRESET` を選び直す（候補は `starship preset --list` で出る）
   - 最後の行で値を読み戻して確かめる
   - **新しいシェルを開いたら**（SSH を張り直したあとも）、先にこのブロックを貼り直す

   <details>
   <summary>補足: 変数について</summary>

   - `${STARSHIP_PRESET}` は[プリセットを当てる（任意）](#プリセットを当てる任意)でしか使わない
   - 既定を `plain-text-symbols` にしてあるのは、Nerd Font が無い環境でも文字化けしないため

   </details>

1. brew で starship を入れる。

   ```bash
   brew install starship
   ```

   - 確認が出たら表示された導入予定を確かめて `y` と答え、処理が終わってプロンプトに戻ってから次の手順を貼る（[Homebrew の注意点](homebrew.md#注意点)）
   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - 依存の `dbus`（とその先の `expat`）、`zlib-ng-compat` も同時に入る

   <details>
   <summary>補足: 降ってくるボトル</summary>

   aarch64 で降ってくるボトルは `starship--1.26.0.arm64_linux.bottle.tar.gz`。

   </details>

1. 共通設定の初期化順を確かめる。

   ```bash
   grep -n -e 'starship init' -e 'WEZTERM_SHELL_INTEGRATION' -e 'zoxide init' ~/.config/bash/bashrc
   ```

   - starship → WezTerm → zoxide の順に出る。`~/.bashrc` の編集は不要
   - 既に開いているシェルで追加の初期化をせず、次の手順で端末を開き直す

1. 開いている端末を閉じて、開き直す。

   - プロンプトは、開き直した端末から starship に変わる
   - 今のシェルで `. ~/.bashrc` を読み直さない（starship が、そのシェルで既に読んだ WezTerm のシェル統合より後ろで初期化され、WezTerm のフックが 2 回ずつ動く。失敗したコマンドの後に `D;1` と `D;0` が続けて送られた）
   - [プリセットを当てる（任意）](#プリセットを当てる任意)まで進むなら、開き直した端末で手順 1 のブロックを貼り直す
   - **次の手順は、開き直した端末で貼る**

1. starship が入ったか確かめ、プロンプト文字列が生成されるか見る。

   ```bash
   starship --version
   brew list --versions starship
   command -v starship
   starship prompt
   starship module directory
   starship explain
   ```

   - `starship --version` は、`starship 1.26.0` とビルド情報を数行出す
   - `starship prompt` / `module` / `explain` で、プロンプト文字列が実際に生成されるか見る（**端末でなくても動く**）
   - `starship prompt` は、改行とカレントディレクトリとプロンプト記号を含む文字列を出す
   - `starship explain` は、今のプロンプトに出ている各部分の意味を 1 行ずつ説明する

   <details>
   <summary>補足: 端末が無くても確かめられる</summary>

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

   </details>

---

## プリセットを当てる（任意）

- 公式が配っている設定一式を `~/.config/starship.toml` に書き出す

> [!WARNING]
> **この節の手順 2 で、既存の設定は上書きされる**ので、自分で書いたものがあれば先に退避する。

1. 当てられるプリセットの一覧を見る。

   ```bash
   starship preset --list
   ```

   - `plain-text-symbols` と `no-nerd-font` は**Nerd Font が無い端末向け**で、記号を ASCII に置き換える
   - `nerd-font-symbols` / `pastel-powerline` / `gruvbox-rainbow` などは Nerd Font が要る
   - 実機には `font-symbols-only-nerd-font` が入っている（[yazi.md](yazi.md) 参照）
   - 既定の `plain-text-symbols` 以外にするなら、[手順 1](#実施手順) の `STARSHIP_PRESET` を選び直して貼り直す
   - **次の手順は、使うプリセットを決めてから貼る**

1. 選んだプリセットを `~/.config/starship.toml` に書き出す。

   ```bash
   mkdir -p ~/.config
   starship preset "${STARSHIP_PRESET:?手順 1 の STARSHIP_PRESET が空のまま。値を入れて貼り直す}" -o ~/.config/starship.toml
   wc -l ~/.config/starship.toml
   starship prompt
   ```

   - 設定ファイルの変更だけなら `~/.bashrc` を読み直す必要はない。starship は設定ファイルをプロンプトのたびに読むので、starship を読み込んだ端末（[手順 4](#実施手順) で開き直した端末）のプロンプトは、次のプロンプトから変わる
   - 共通設定は初期化済みの starship を再初期化しない。手で `eval "$(starship init bash)"` を重ねると `PS0` が重複するため、追加で実行しない

---

## 設定ファイル

- `~/.config/starship.toml` は**既定では存在しない**（無ければ組み込みの既定値で動く）

1. `~/.config/starship.toml` に、設定を手で書く。

   ```bash
   mkdir -p ~/.config
   cat > ~/.config/starship.toml <<'EOF'
   add_newline = false

   [directory]
   truncation_length = 3
   truncate_to_repo = false
   EOF
   starship prompt
   ```

   - `starship config` で `$EDITOR` が開く
   - 設定の場所を変えたいときは、starship 自身が読む環境変数 `STARSHIP_CONFIG` を `~/.bashrc` で `export` する

   <details>
   <summary>補足: 調べるときに使うサブコマンド</summary>

   | コマンド | 用途 |
   |---|---|
   | `starship explain` | 今のプロンプトの各部分が何を表しているか |
   | `starship timings` | モジュールごとの所要時間。プロンプトが遅いときの犯人探し |
   | `starship module <名前>` | 1 モジュールだけ描画して確かめる |
   | `starship print-config` | 実効設定を表示 |

   </details>

---

## 更新

1. brew で starship を更新する。

   ```bash
   brew upgrade starship
   ```

   - すべてまとめて上げるなら `brew upgrade`

---

## ロールバック

- 本書ではロールバックは**本実行していない**

1. starship をアンインストールして、端末を開き直す。

   ```bash
   brew uninstall starship
   ```

   - 次のシェルでは共通設定が starship の初期化を省略する。`~/.bashrc` の編集は不要

1. 設定も消すときだけ、`~/.config/starship.toml` を消す。

   ```bash
   rm -f ~/.config/starship.toml              # 設定も消す場合
   ```

1. キャッシュも消すときだけ、`~/.cache/starship` を消す。

   ```bash
   rm -rf ~/.cache/starship                   # キャッシュも消す場合
   ```

---

## 補足

- 2026-10-05: シェル設定は bash リポジトリに統一し、直接追記とその削除の手順を確認手順に変更した。変更後のコードブロックは `bash -n` で確認し、共通設定の導入・移行は bash リポジトリの一時ホームのテストで確認した。パッケージ導入・削除やサービス操作は再実行していない。以下の過去の実測・出力例は、直接追記していた時点の記録を含む。現行手順では同じ行を `~/.bashrc` に書かない

### 対象と検証環境

- **目的**: AlmaLinux 10 のシェルプロンプトを [starship](https://starship.rs/)（git の状態・言語バージョン・終了コードなどを自動で出すプロンプト）に置き換える。**EPEL にも AppStream にも RPM が無い**
- **進め方**: ツール本体とサービスは本書で導入し、シェルの設定は bash リポジトリから読む。共通設定と別の設定ファイルは、それぞれの節で扱う
- **状態**: **コンテナでのみ検証済み（2026-09-22、並びを直した手順 3〜7 とプリセットの節の手順 2 は 2026-09-30）。実機には入れていない**
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**[Homebrew の導入](homebrew.md)と手順 2・4・7、[プリセットを当てる（任意）](#プリセットを当てる任意)・[設定ファイル](#設定ファイル)を通した
  - 2026-09-30 に、並びを直した手順 3〜7 とプリセットの節の手順 2 を、x86_64 のコンテナで流し直した（[付録](#付録-並びを直した版の検証2026-09-30)）。WezTerm のシェル統合と zoxide と一緒に読んだ対話のシェルを、`script` の擬似端末で動かして生の出力を見た
  - 確認したこと: `arm64_linux` のボトルが降りる、`starship 1.26.0` が入る、`starship prompt` / `module` / `explain` / `timings` が端末なしでも文字列を返す、`~/.bashrc` への追記と差し込み（前の版の並びからの移動と、後ろにあった `brew shellenv` の行の移動も）、WezTerm のシェル統合の OSC 133 の `C` / `D`（終了コード）と、zoxide の警告が出ないこと
  - **確認していないこと**: 端末の画面でのプロンプトの見た目と、WezTerm でのプロンプトへのジャンプ・出力のコピー。コンテナには画面が無いため
  - **実機（Raspberry Pi 5）では本実行していない**（実機の `~/.bashrc` は 38 行のまま）ので、下表の実機列は「この手順を適用した結果」ではなく**現時点の状態**を書いてある

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| starship | **未導入** | `starship 1.26.0`（`arm64_linux` ボトル） |
| 一緒に入る依存 | — | `expat` / `dbus` / `zlib-ng-compat` |
| `~/.bashrc` | 38 行。26 行 `brew shellenv` / 27-33 行 yazi の `y()` / 34 行 `zoxide init` / 36-38 行 WezTerm シェル統合 | 手順 4 で `starship init` を末尾に追記 |
| Nerd Font | `font-symbols-only-nerd-font 3.5.1`（Homebrew、[yazi.md](yazi.md)） | 無し |
| 端末 | WezTerm nightly（[wezterm-nightly.md](wezterm-nightly.md)。OSC 133 のシェル統合あり） | 無し（pty を与えずに実行） |

> [!NOTE]
> 環境固有の値は**シェル変数**で書いてある。[手順 1](#実施手順) で 1 度だけ設定すれば、以降のコマンドはそのまま貼って実行できる。
>
> | 変数 | 意味 | 例 |
> |---|---|---|
> | `${STARSHIP_PRESET}` | [プリセットを当てる（任意）](#プリセットを当てる任意)で使う名前 | `plain-text-symbols`（既定）/ `no-nerd-font` / `tokyo-night` |
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

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `starship 1.26.0` の `arm64_linux` ボトルがある。upstream の最新と一致 | **採用** |
| EPEL / AppStream / CRB | **`starship` というパッケージが無い**（`dnf list --available starship` → `Error: No matching Packages to list`） | 使えない |
| 公式 install.sh（`sh -c "$(curl -sS https://starship.rs/install.sh)"`） | `/usr/local/bin` にバイナリを 1 つ置く。`sudo` が要り、更新は自分で再実行する | 不採用（Homebrew に揃える） |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-musl` のビルドがある。更新は手作業 | 不採用 |
| `cargo install starship` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

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

### 注意点

- **初期化の 1 行が本体**: `brew install` だけではプロンプトは変わらない。bash の共通設定が `starship init bash` を読むことで有効になる
- **starship の初期化は、`brew shellenv` の行より後ろ、zoxide の初期化と WezTerm のシェル統合より前に置く**: zoxide・WezTerm より後ろにあると、この設定の WezTerm のシェル統合が働くとき（COPR の公式の統合が無いとき）は、WezTerm に送る終了コード（OSC 133 の `D`）がいつも 0 になる（[bash の読む順番](https://github.com/ryo-aoki-pc/bash#読む順番)の実測）。`brew shellenv` より前にあると、`starship: command not found` になる
- **WezTerm のシェル統合の `A` / `B` は失われる**: `PS1` が毎回作り直されるため。並びによらない（[bash の読む順番](https://github.com/ryo-aoki-pc/bash#読む順番)）
- **アンインストール時に行を消し忘れると毎回エラーが出る**: [ロールバック](#ロールバック)の `sed` を忘れない
- **プロンプトごとに外部プロセスが起動する**: git の状態を調べるので、大きなリポジトリや遅いストレージ（Raspberry Pi の microSD）では体感できるほど遅くなることがある
  - `starship timings` で犯人を探し、要らないモジュールは `disabled = true` で切る
- **記号には Nerd Font が要るものがある**: 既定のプロンプト記号 `❯` は普通のフォントでも出るが、プリセットによっては Nerd Font 前提
  - 無い端末では `plain-text-symbols` / `no-nerd-font` を当てる
- **Homebrew 全般の注意は [homebrew.md の注意点](homebrew.md#注意点)**: PATH の先頭が Homebrew になる、`sudo starship` はそのままでは使えない、など
- **root は別に導入する**: root 自身にも bash の共通設定を導入した場合にだけ、root のシェルで初期化される（[homebrew.md の root の節](homebrew.md#root-のシェルでも使う任意)）

### 参照

- [starship.rs](https://starship.rs/) — 公式サイト。インストールと各シェルでの `init` の書き方
- [starship — Configuration](https://starship.rs/config/) — `starship.toml` の全モジュールと項目
- [starship — Presets](https://starship.rs/presets/) — プリセット一覧とスクリーンショット、Nerd Font が要るかどうか
- `starship --help` / `starship init bash --print-full-init` — サブコマンドと、シェルに入る初期化の中身
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](homebrew.md)と手順 2・4・7、[プリセットを当てる（任意）](#プリセットを当てる任意)・[設定ファイル](#設定ファイル)を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。[bat](bat.md) / [git-delta](git-delta.md) / [eza](eza.md) / [gdu](gdu.md) を先に入れた同じコンテナで続けている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](homebrew.md)） |
| 2. starship | `Pouring expat--2.8.5` → `dbus--1.16.2_1` → `starship--1.26.0.arm64_linux.bottle.tar.gz` の順に降り、`12 files, 11MB`。ソースビルドは発生しない |
| 4. 初期化 | `~/.bashrc` に `eval "$(starship init bash)"` を追記して読み込み直し、エラーなく通った（非対話シェルなのでプロンプト自体は描画されない） |
| 7. 検証 | `starship --version` → `1.26.0`（`build_env` に `rustc 1.96.0 ... (Homebrew)`）。`starship prompt` / `module directory` / `explain` / `timings` がいずれも文字列を返した |
| プリセット | `starship preset --list` で 12 個（`bracketed-segments` / `catppuccin-powerline` / `gruvbox-rainbow` / `jetpack` / `nerd-font-symbols` / `no-empty-icons` / `no-nerd-font` / `no-runtime-versions` / `pastel-powerline` / `plain-text-symbols` / `pure-preset` / `tokyo-night`）。`plain-text-symbols` を `-o` で書き出して 335 行の `starship.toml` が生成され、`starship explain` のプロンプト記号が `❯` から `>` に変わることを確認 |
| 初期化の中身 | `starship init bash --print-full-init` を読み、`PS1` を毎回組み立て直すこと・既存の `PROMPT_COMMAND` を `STARSHIP_PROMPT_COMMAND` に退避して呼ぶこと・`PS0` には前置きすることを確認（[手順 3 の補足](#実施手順)の根拠） |
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
