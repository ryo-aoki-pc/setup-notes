# starship インストール手順（AlmaLinux 10 / Homebrew）

## 実施手順

> [!IMPORTANT]
> - **前提**: [Homebrew](homebrew.md) が入っていること。`command -v brew` で何も出なければ、先に通す
> - **自分のシェルで実行する**。`sudo -i` した root のシェルでは行わない（Homebrew は root で動かず、設定も自分の `~/.bashrc` と `~/.config` に書くため）

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

   - ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
   - 依存の `dbus`（とその先の `expat`）、`zlib-ng-compat` も同時に入る

   <details>
   <summary>補足: 降ってくるボトル</summary>

   aarch64 で降ってくるボトルは `starship--1.26.0.arm64_linux.bottle.tar.gz`。

   </details>

1. `~/.bashrc` のいちばん最後に、starship の初期化の 1 行を書く。

   ```bash
   echo 'eval "$(starship init bash)"' >> ~/.bashrc
   . ~/.bashrc
   tail -1 ~/.bashrc
   ```

   - **この 1 行を書かないとプロンプトは変わらない**（`starship` コマンド自体は文字列を出すだけ）
   - `~/.bashrc` に [zoxide](zoxide.md) の初期化や端末のシェル統合（[wezterm-nightly.md](wezterm-nightly.md)）がある場合は、**それらより後ろ**に置く
   - **注意**: WezTerm のシェル統合の一部が失われる見込み（未検証）。順序とあわせて、この手順の補足を読む

   <details>
   <summary>補足: <code>~/.bashrc</code> の並びと WezTerm シェル統合</summary>

   `starship init bash` が出すのは 1 行だけで、中身はさらに長い初期化を読み込む `eval` になっている:

   ```
   $ starship init bash
   eval -- "$(/home/linuxbrew/.linuxbrew/bin/starship init bash --print-full-init)"
   ```

   その本体（`--print-full-init` の出力）が `PS1` と `PROMPT_COMMAND` に何をするかを読むと、次のことが分かる。

   - **`PS1` は毎回まるごと組み立て直される**: `PS1="$(starship prompt ...)"` を `PROMPT_COMMAND` の中で実行する
   - **既存の `PROMPT_COMMAND` は保存される**: `STARSHIP_PROMPT_COMMAND` に退避して `starship_precmd` の中から `eval` する。「前に足すとコマンド実行時間が壊れ、後ろに足すと `$?` が壊れる」という理由がコメントに書いてある
   - **`PS0` には前に足す**: 既存の `PS0` は残る

   実機の `~/.bashrc` は 36-38 行目で WezTerm のシェル統合（`~/.config/wezterm/shell/wezterm.sh`）を読み込んでいる。この統合は OSC 133 の印を 4 か所に置く:

   | 印 | 置き場所 | starship を入れた後 |
   |---|---|---|
   | `A`（プロンプト開始） | `PS1` の先頭に追加 | **失われる**（`PS1` が毎回上書きされるため） |
   | `B`（入力開始） | `PS1` の末尾に追加 | **失われる**（同上） |
   | `C`（コマンド開始） | `PS0` の先頭に追加 | 残る見込み（starship も `PS0` には前に足すだけ） |
   | `D`（コマンド終了） | `PROMPT_COMMAND` の関数 | 残る見込み（starship が退避して呼ぶため） |

   つまり**プロンプト単位のジャンプや、プロンプト部分を除いた出力の選択といった WezTerm の機能は劣化しうる**。

   - 避けるなら、starship 側の `format` に自分で `\033]133;A` / `B` を埋め込むか、シェル統合を使わないか、どちらかになる
   - **これは初期化スクリプトを読んだ上での推定で、実挙動は端末が無いと確かめられないため本書では未検証**（[未確認事項](#未確認事項)）

   並び順については、**zoxide より後ろ、WezTerm シェル統合より後ろ**に置くのが安全。

   zoxide も starship も「`~/.bashrc` の最後に置け」と案内しているが、両者の `PROMPT_COMMAND` の扱い方が違う（zoxide は自分のフックを足すだけ、starship は既存を退避して呼ぶ）ので、starship を後にすると zoxide のフックが退避側に入って呼ばれ続ける。

   </details>

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

1. 選んだプリセットを `~/.config/starship.toml` に書き出し、シェルに読み込み直す。

   ```bash
   mkdir -p ~/.config
   starship preset "${STARSHIP_PRESET:?手順 1 の STARSHIP_PRESET が空のまま。値を入れて貼り直す}" -o ~/.config/starship.toml
   wc -l ~/.config/starship.toml
   . ~/.bashrc
   starship prompt
   ```

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

1. brew で starship を消し、`~/.bashrc` から初期化の行を消す。

   ```bash
   brew uninstall starship
   sed -i '/starship init/d' ~/.bashrc        # ~/.bashrc に書いた 1 行を消す
   ```

   - **`~/.bashrc` の行を消し忘れると、新しいシェルを開くたびに `starship: command not found` が出る**（[zoxide](zoxide.md#ロールバック) と同じ落とし穴）

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

### 対象と検証環境

- **目的**: AlmaLinux 10 のシェルプロンプトを [starship](https://starship.rs/)（git の状態・言語バージョン・終了コードなどを自動で出すプロンプト）に置き換える。**EPEL にも AppStream にも RPM が無い**
- **進め方**: Homebrew で入れ、`~/.bashrc` に初期化の 1 行を足す。**読者が書き換えるのは冒頭の変数ブロックだけ**
- **状態**: **コンテナでのみ検証済み（2026-09-22）。実機には入れていない**
  - 下表の検証コンテナで、**この文書のコードブロックをそのまま貼って**[Homebrew の導入](homebrew.md)と手順 2〜4、[プリセットを当てる（任意）](#プリセットを当てる任意)・[設定ファイル](#設定ファイル)を通した
  - 確認したこと: `arm64_linux` のボトルが降りる、`starship 1.26.0` が入る、`starship prompt` / `module` / `explain` / `timings` が端末なしでも文字列を返す、`~/.bashrc` への追記が読み込める
  - **確認していないこと**: 実際のプロンプト表示と、WezTerm のシェル統合との相性（[手順 3 の補足](#実施手順)）。コンテナには端末が無いため
  - **実機（Raspberry Pi 5）では本実行していない**（実機の `~/.bashrc` は 38 行のまま）ので、下表の実機列は「この手順を適用した結果」ではなく**現時点の状態**を書いてある

| 項目 | 実機 | 検証コンテナ |
|---|---|---|
| 実施日 | —（未実施） | 2026-09-22 |
| OS | AlmaLinux 10.2 (Lavender Lion) / aarch64（Raspberry Pi 5） | 同左（`docker.io/library/almalinux:10`、podman 5.8.2 / rootless） |
| Homebrew | 7.0.6（`/home/linuxbrew/.linuxbrew`） | 7.0.6（同じ場所に新規導入） |
| starship | **未導入** | `starship 1.26.0`（`arm64_linux` ボトル） |
| 一緒に入る依存 | — | `expat` / `dbus` / `zlib-ng-compat` |
| `~/.bashrc` | 38 行。26 行 `brew shellenv` / 27-33 行 yazi の `y()` / 34 行 `zoxide init` / 36-38 行 WezTerm シェル統合 | 手順 3 で `starship init` を末尾に追記 |
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

- **初期化の 1 行が本体**: `brew install` だけではプロンプトは変わらない。`~/.bashrc` に `eval "$(starship init bash)"` を書いて初めて効く
- **WezTerm のシェル統合の一部が失われる見込み**: `PS1` が毎回作り直されるため、OSC 133 の `A` / `B` マーカーが消える。[手順 3 の補足](#実施手順)。**未検証**
- **アンインストール時に行を消し忘れると毎回エラーが出る**: [ロールバック](#ロールバック)の `sed` を忘れない
- **プロンプトごとに外部プロセスが起動する**: git の状態を調べるので、大きなリポジトリや遅いストレージ（Raspberry Pi の microSD）では体感できるほど遅くなることがある
  - `starship timings` で犯人を探し、要らないモジュールは `disabled = true` で切る
- **記号には Nerd Font が要るものがある**: 既定のプロンプト記号 `❯` は普通のフォントでも出るが、プリセットによっては Nerd Font 前提
  - 無い端末では `plain-text-symbols` / `no-nerd-font` を当てる
- **Homebrew 全般の注意は [homebrew.md の注意点](homebrew.md#注意点)**: PATH の先頭が Homebrew になる、`sudo starship` は使えない、など
- **root のシェルには効かない**: `sudo -i` した root は root の `~/.bashrc` を読むので、手順 3 の初期化の行が無い（homebrew.md の[root のシェルでも使う](homebrew.md#root-のシェルでも使う任意)の節も、PATH を足すだけ）

### 参照

- [starship.rs](https://starship.rs/) — 公式サイト。インストールと各シェルでの `init` の書き方
- [starship — Configuration](https://starship.rs/config/) — `starship.toml` の全モジュールと項目
- [starship — Presets](https://starship.rs/presets/) — プリセット一覧とスクリーンショット、Nerd Font が要るかどうか
- `starship --help` / `starship init bash --print-full-init` — サブコマンドと、シェルに入る初期化の中身
- [Homebrew](homebrew.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

---

### 付録: コンテナでの検証記録（2026-09-22）

`podman run -d docker.io/library/almalinux:10 sleep infinity` で立てた使い捨てコンテナに非 root ユーザーを作り、`podman exec` で[Homebrew の導入](homebrew.md)と手順 2〜4、[プリセットを当てる（任意）](#プリセットを当てる任意)・[設定ファイル](#設定ファイル)を通した。実機で加えた変更は無い（`podman` は以前から導入済み）。 実行したのは**この文書のコードブロックをそのまま抜き出したもの**で、`sudo` はそのまま（コンテナ内のユーザーに NOPASSWD の sudo を与えた）、Homebrew のインストーラだけ `NONINTERACTIVE=1` を付けている。[bat](bat.md) / [git-delta](git-delta.md) / [eza](eza.md) / [gdu](gdu.md) を先に入れた同じコンテナで続けている。

| 手順 | 結果 |
|---|---|
| 前提. Homebrew | `NONINTERACTIVE=1` 付きの公式インストーラ → `Homebrew 7.0.6`（[homebrew.md](homebrew.md)） |
| 2. starship | `Pouring expat--2.8.5` → `dbus--1.16.2_1` → `starship--1.26.0.arm64_linux.bottle.tar.gz` の順に降り、`12 files, 11MB`。ソースビルドは発生しない |
| 3. 初期化 | `~/.bashrc` に `eval "$(starship init bash)"` を追記して読み込み直し、エラーなく通った（非対話シェルなのでプロンプト自体は描画されない） |
| 4. 検証 | `starship --version` → `1.26.0`（`build_env` に `rustc 1.96.0 ... (Homebrew)`）。`starship prompt` / `module directory` / `explain` / `timings` がいずれも文字列を返した |
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
