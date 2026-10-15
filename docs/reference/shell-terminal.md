# シェルと端末のセットアップ（AlmaLinux 10・Windows 11）の参考資料

[手順書](../shell-terminal.md)・[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shell-terminal.md)・[注意点](../extra/shell-terminal.md)

- PowerShell 7 のプロファイルの行の印は `# windows-setup.md`、Windows Terminal の控えは `settings.json.windows-setup.bak`
- PowerShell 7 のプロファイルと Windows Terminal の資料（文書・コード）は、[Windows 11 の初期設定の参考資料の「参照」](windows-setup.md#参照)にある

## 補足

### 共通の bash 設定 / 手順 1: 補足: 共通の bash 設定

- [README の共通の bash 設定を先に入れる](../../README.md#共通の-bash-設定を先に入れる)と同じ（Workstation には git が最初から入っている）
- 元の `~/.bashrc` は `~/.bashrc.before-bash` に残る
- `~/.bashrc` の末尾に、`~/.config/bash/bashrc` を読む 1 行が足される。ツールごとの設定（Homebrew・starship・zoxide・fzf・eza・bat の `MANPAGER`・履歴と `shopt` など）は、この設定がまとめて読む。この文書では `~/.bashrc` に追記しない

### 共通の bash 設定 / 手順 3: 補足: 入っているときと入れたとき

- Workstation で入れた PC は、bash-completion が最初から入っている
- BaseOS から入れるときは、依存の `pkgconf` 系 4 つも入る

### シェルのツール / 手順 1: 補足: 確認とボトル

- 依存も入れる計画なので、`[y/n]` と聞かれる
- ビルド済みのボトルが降ってくる。aarch64 でもソースからのビルドにはならない
- 要らないツールの名前を外してよいのは、共通の bash 設定が、入っているものだけを読むため

### シェルのツール / 手順 1: 補足: starship のボトル

[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shell-terminal.md#starship-補足の実測)

### シェルのツール / 手順 1: 補足: fzf の依存と、入れてあるホストで貼る意味

[この節の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shell-terminal.md#fzf-実施手順--手順-1-補足-依存と入れてあるホストで貼る意味)

- fzf の依存は `ncurses` だけ（`brew deps fzf`）
- [yazi](../almalinux-setup.md#yazi)や[シェルのツール](../shell-terminal.md#シェルのツール)で入れた fzf は、`brew install zoxide fzf` のように名前を挙げて入れているので、Homebrew の「頼まれて入れた」印（`installed_on_request`）が付いている。`brew install fzf` を貼り直しても害は無く、印が無かったホストでは付く（印が無いと、zoxide や yazi を `brew uninstall` した際の自動削除や、明示的な `brew autoremove` で fzf も消えうる）

### シェルのツール / 手順 1: 補足: eza のボトル

aarch64 で降ってくるボトルは `eza--0.23.5.arm64_linux.bottle.tar.gz`。

### シェルのツール / 手順 2: 補足: 開き直した端末で効く理由

- 開き直した端末で starship・zoxide・fzf・eza・bat が効くのは、共通の bash 設定が、入っているツールを読むため

### シェルのツール / 手順 3: 補足: 補完の順

- `-F _brew brew` が出るのは、共通の bash 設定が Homebrew の補完を fzf より前に読むため

### シェルのツール / 手順 4: 補足: 初期化の順と starship explain

- starship → WezTerm → zoxide の順は、共通の bash 設定が初期化の順番を持つ。`~/.bashrc` の編集は不要
- `starship explain` は、今のプロンプトに出ている各部分の意味を 1 行ずつ説明する
- 見た目を変えるなら[starship のプリセットを当てる](../shell-terminal.md#starship-のプリセットを当てる)、細かい調整は[starship の設定ファイル](../shell-terminal.md#starship-の設定ファイル)

### シェルのツール / 手順 6: 補足: 出力の意味

- `[+git]` は git の連携込みのビルド
- `Git` の列が出るのは、`~/.config/bash` が git のリポジトリだから
- `ll`・`la`・`lt` は共通の bash 設定が足す。`ls` は置き換えない

### シェルのツール / 手順 7: 補足: bat の出力と MANPAGER

- `--color=always` を外してパイプに繋ぐと、装飾の無い `cat` と同じ出力になる
- `MANPAGER` の `bat -plman` は共通の bash 設定が持つ。`man bash` が bat の色で開く（`q` で閉じる）

### シェルのツール / 手順 8: 補足: BaseOS の tmux

- BaseOS の tmux で始めたセッションに Homebrew の tmux からはつなげない（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shell-terminal.md#tmux-実施手順--手順-2-補足-baseos-の-tmux-と並べたとき)）

### シェルのツール / 手順 10: 補足: z と zi の使い方

- 以後は `z share` のように末尾の一部を書けば `/usr/share` に飛ぶ。`zi` で候補を fzf で選べる

### キー操作を試す / 手順 3: 補足: プレビューと複数の選択

- 右側のプレビューは、共通の bash 設定が、bat があるときに入れる
- Tab で複数を選べる（選んだ行に印が付き、Enter で全部入る）

### キー操作を試す / 手順 4: 補足: ** の補完

- `**` を付けなければ、今までどおりの補完
- `ssh **<Tab>` は `~/.ssh/config` と `known_hosts` のホスト名、`export **<Tab>` は変数名の一覧になる

### starship のプリセットを当てる / 手順 2: 補足: --force と再初期化

- starship は設定ファイルをプロンプトのたびに読む
- `--force` は既存のファイルを置き換える。付けないと既存設定がある場合に拒否されるので、節の先頭のとおり先に退避する
- 共通設定は初期化済みの starship を再初期化しない。手で `eval "$(starship init bash)"` を重ねると `PS0` が重複するため、追加で実行しない

### starship のプリセットを当てる / 手順 2: 補足: 変数について

- `${STARSHIP_PRESET}` は[プリセットを当てる](../shell-terminal.md#starship-のプリセットを当てる)でしか使わない
- 既定を `plain-text-symbols` にしてあるのは、Nerd Font が無い環境でも文字化けしないため

### starship の設定ファイル / 手順 1: 補足: 編集と置き場所

- `starship config` で `$EDITOR` が開く
- 設定の場所を変えたいときは、starship 自身が読む環境変数 `STARSHIP_CONFIG` を `~/.bashrc` で `export` する

### starship の設定ファイル / 手順 1: 補足: 調べるときに使うサブコマンド

| コマンド | 用途 |
|---|---|
| `starship explain` | 今のプロンプトの各部分が何を表しているか |
| `starship timings` | モジュールごとの所要時間。プロンプトが遅いときの犯人探し |
| `starship module <名前>` | 1 モジュールだけ描画して確かめる |
| `starship print-config` | 実効設定を表示 |

### starship でユーザー名とホスト名を常に表示する / 手順 1: 補足: starship config

- 既存の設定を保ち、常時表示に必要な 2 項目だけを更新する。設定ファイルが無ければ作られる

### fzf で fd と bat を候補とプレビューに使う / 手順 1: 補足: fd-find と二重に入れない理由

- EPEL の `fd-find` も Homebrew の fd も `fd` で、PATH の先頭の Homebrew 版が使われる

### fzf で fd と bat を候補とプレビューに使う / 手順 2: 補足: 変数を入れる時期

- 共通の bash 設定は、端末を開くときに fd と bat を見つけて変数を入れる

### fzf で fd と bat を候補とプレビューに使う / 手順 4: 補足: コマンドの中のプレビュー

- コマンドの中で同じプレビューを使うなら、`fzf --preview 'bat --color=always --style=numbers {}'`

### fzf で fd と bat を候補とプレビューに使う / 手順 5: 補足: 消した後

- 開き直した端末から、共通の bash 設定は候補の 3 つの変数を入れず、候補は fzf の既定の一覧に戻る
- [yazi](../almalinux-setup.md#yazi)の `YAZI_EXTRAS` で入れた fd を消さないのは、yazi の検索が使うため

### bat の設定ファイル / 手順 1: 補足: テーマと言語とキャッシュ

- テーマの一覧は `bat --list-themes`、認識する言語の一覧は `bat --list-languages`
- 自前のシンタックス定義やテーマを足したときだけ `bat cache --build` が要る（キャッシュの場所は `bat --cache-dir`）

### bat の設定ファイル / 手順 1: 補足: 変数について

- `ansi` は「端末が設定している 16 色をそのまま使う」テーマで、端末の配色を変えたときに追従する。固定の配色にしたいなら `bat --list-themes` から選ぶ

### tmux を試す / 手順 1: 補足: デタッチ

- デタッチしても、セッションの中のシェルと、そこで動かしているコマンドは動き続ける

### tmux を試す / 手順 2: 補足: tmux の使い方

- キーとコマンドは[tmux の使い方の基本](../shell-terminal.md#tmux-の使い方の基本)

### tmux を試す / 手順 3: 補足: tmux のサーバー

- セッションが 1 つも無くなると、tmux のサーバーも終わる

### tmux の設定ファイル / 手順 1: 補足: 読み込む場所と、足さなかった行

- Homebrew の tmux のシステムの設定ファイルは `/home/linuxbrew/.linuxbrew/etc/tmux.conf`（`man tmux`）。`/etc/tmux.conf` は読まない
- `escape-time`（Esc の後に待つ時間）は、3.7c の既定ですでに 10 ミリ秒なので足さない。Neovim などのために 0〜10 にする例は、古い版の既定の 500 ミリ秒を縮めるためのもの
- Claude Code の公式ドキュメントには、tmux の設定の推奨は無かった（Shift+Enter のための `extended-keys` なども）。本書では足していない

### tmux の設定ファイル / 手順 2: 補足: 読み込みとホイール

- 既存・新規のどちらの設定ファイルも、起動時と同じ順で読み込む。既存セッションのマウス設定にも反映する
- tmux の中でホイールを上へ回すと、さかのぼって読める（右上に `[5/258]` のような位置が出る）。下まで回すか `q` で戻る

### Claude Code を tmux の中で動かす（任意） / 手順 1: 補足: claude auth status を最後に置く理由

- ブラケットペースト無しで貼ると、`claude auth status --text` は、端末に残っていた後ろの行を読んで捨てた（後ろの `tmux -V` や `echo` が実行されなかった）

### Claude Code を tmux の中で動かす（任意） / 手順 2: 補足: ディレクトリ

- ホームを選ばないのは、Claude Code がホームの信頼を保存しないため（[Windows の手順書](../ai-agents.md#claude-code-の-remote-control-実施手順)の手順 2）
- 同じ節の手順 4 は、tmux の中で見た作業ディレクトリの名前を Remote Control のセッション名にする

### Claude Code を tmux の中で動かす（任意） / 手順 6: 補足: 切った後

- tmux のセッションと、その中の Claude Code は、このホストで動き続ける

### HackGen Console NF / 手順 1: 補足: HackGen35 Console NF

[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shell-terminal.md#hackgen-console-nf-補足の実測)

- 文字幅が半角 3:全角 5 の版 `HackGen35 Console NF` も、同じ手順で一緒に入る（[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shell-terminal.md#hackgen-console-nf-の記録)）

### HackGen Console NF / 手順 2: 補足: unzip が要る理由

- Homebrew は cask の zip を展開するのに `unzip` を使う

### HackGen Console NF / 手順 5: 補足: fc-match と文字の確かめ方

- `fc-match` は、名前が合わないときに別のフォントを黙って返すので、ファイル名が HackGen であることを確かめる
- 最後の `for` で、かな・漢字・Powerline 記号・Nerd Fonts のアイコンが、このフォントに入っていることを確かめる

### WezTerm / 手順 1: 補足: chroot を明示する理由

`dnf copr enable` は chroot を省略すると `/etc/os-release` から推定する。EL 系は `epel-<major>-<arch>` になる（`/usr/lib/python3.12/site-packages/dnf-plugins/copr.py` の `_guess_chroot`）。このプロジェクトに `epel-10-x86_64` は無いので失敗する:

エラーメッセージの言うとおり第 2 引数に chroot を渡せば通る。「repo ファイルの手直しが要るかも」とあるが、生成された repo ファイルは `baseurl` が `rhel-9-$basearch` を指すだけで、そのまま使えた:

```
[copr:copr.fedorainfracloud.org:wezfurlong:wezterm-nightly]
name=Copr repo for wezterm-nightly owned by wezfurlong
baseurl=https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/rhel-9-$basearch/
type=rpm-md
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/pubkey.gpg
repo_gpgcheck=0
enabled=1
enabled_metadata=1
```

公式ドキュメントの openSUSE 向け手順が同じ `dnf copr enable wezfurlong/wezterm-nightly <repository>` の形なので、想定内の使い方ではある。

- chroot は `uname -m` から `rhel-9-x86_64` か `rhel-9-aarch64` になる（COPR に EL10 向けが無いので EL9 向けを使う）

### WezTerm / 手順 3: 補足: wezterm はメタパッケージ / 取り込まれる鍵

[この節の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shell-terminal.md#wezterm-実施手順--手順-3-補足-wezterm-はメタパッケージ--取り込まれる鍵)

- `wezterm` 本体（6.4 KB、`rpm -ql wezterm` は空）は、`wezterm-common`（CLI の `wezterm`、シェル統合、補完）/ `wezterm-gui`（`wezterm-gui`、desktop ファイル、アイコン）/ `wezterm-mux-server` を Requires で束ねているだけ
- `dnf repoquery --requires wezterm` に `gcc` / `*-devel` / `make` が並んで見えるのは、同名の **SRPM の BuildRequires** が一緒に表示されているため。x86_64 パッケージには入っていない

GPG 鍵はインストール時に COPR の `pubkey.gpg` から取り込まれる:

```
Importing GPG key 0xCEA2757D:
 Userid     : "wezfurlong_wezterm-nightly (None) <wezfurlong#wezterm-nightly@copr.fedorahosted.org>"
 Fingerprint: FD90 9B62 88A8 4250 AD58 020F A698 91C5 CEA2 757D
 From       : https://download.copr.fedorainfracloud.org/results/wezfurlong/wezterm-nightly/pubkey.gpg
```

### WezTerm / 手順 4: 補足: wezterm ls-fonts と wezterm-gui --version

- **`wezterm ls-fonts`** は GUI 無しでフォント解決を確認できる
  - 既定のフォントは組み込みの `JetBrains Mono` で、フォールバックに `Noto Color Emoji`（fontconfig 経由）と組み込みの `Symbols Nerd Font Mono` が並ぶ
  - `| head` で切ると `rc=101`（Rust の panic 終了コード）になるが、パイプが閉じたためで異常ではない。単体で実行すると `rc=0`
- **`wezterm-gui --version` は `wezterm-gui someone forgot to call assign_version_info` と出る**（rc=0）
  - COPR ビルドでは GUI バイナリにバージョン情報が埋め込まれていない。バージョンは `wezterm --version` で見る

### WezTerm / 手順 4: 補足: アプリ一覧の項目

- アプリ一覧の「WezTerm」は、`/usr/share/applications/org.wezfurlong.wezterm.desktop` から出る

### WezTerm と HackGen Console NF をデスクトップで使う / 手順 1: 補足: 等幅のフォント

- 等幅のフォントは、端末の Ptyxis などが使う
- 最初の `get` は変える前の値（AlmaLinux 10 の既定は `'Red Hat Mono Regular 10'`）
- Ptyxis は既定でこのフォントを使うので、開いている端末もすぐに変わる

### Windows 11 で HackGen Console NF を入れる / 手順 2: 補足: 出た結果の意味

[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-setup.md)

- 自分のユーザーの登録と `%LOCALAPPDATA%` のファイルが出たら、この節の手順で入れたもの（同じ節の手順 3 は何度貼ってもよい）
- `C:\Windows\Fonts` のファイルが出たら、PC 全体に入っていて、そのまま使える

### Windows 11 で HackGen Console NF を入れる / 手順 3: 補足: 中断したときと貼り直したとき

- `中断:` で止まったとき、取ってきたものは `%TEMP%\hackgen-setup` に残る。次に貼ったときに消して作り直す
- 何度貼ってもよいのは、同じファイルは置き直さないため

### HackGen Console NF を上げる / 手順 2: 補足: 版と sha256 を直す理由

- `$ver` と `$sha256` を直さなければ、固定した旧版を再び入れるだけで更新にはならない

### HackGen Console NF を上げる / 手順 3: 補足: 外してから入れ直す理由

- [Windows 11 のロールバック](../extra/windows-setup.md#hackgen-console-nf-を消す)の手順 1〜3 を先に行うのは、読み込まれているファイルは置き換えられないため

### Windows Terminal のフォントと貼り付けの警告を変える / 手順 2: 補足: 設定ファイルの読み書き

- 場所は、Store（MSIX）版の `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`（Microsoft の文書）
- Windows Terminal は、初めて起動したときにコメントの無い `settings.json` を書く。設定の画面でリセットすると、コメント入りの `userDefaults.json` をそのまま書く（`CascadiaSettingsSerialization.cpp`）。5.1 の `ConvertFrom-Json` はコメントを読めないので、文字列を除いた残りにコメントか末尾のカンマがあれば、書かずに止める
- Windows Terminal は BOM の無い UTF-8 で書き、ASCII 以外の文字（訳したプロファイルの名前）も入る。5.1 の `Get-Content` は BOM の無いファイルを ANSI として読むので、`[IO.File]::ReadAllText` で読む
- `ConvertTo-Json` は `-Depth 100`（既定の 2 では深い入れ子が潰れる）。字下げと、`<`・`>`・`&`・`'` の書き方（`\u003c` など）が変わるが、JSON の中身は同じで、Windows Terminal が次に保存するときに整える
- `profiles` が配列なのは古い形式で、この節のブロックは扱わない
- 保存すると、Windows Terminal がファイルの変化を見て読み直し、開いているタブにも効く
- fragment（`%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments`）に書けるのは、プロファイル・配色・アクション（キーを除く）だけで、全体の設定と `profiles.defaults` は読まれない（`_parseFragment`）
- 控えは、控えが無いときだけ作る（2 回目に貼っても、元の設定が残る）。この節の手順 6 で書き戻すと消すので、次にこの節を通すときは、そのときの設定を控え直す
- 書き戻しは `Move-Item` にせず、`Copy-Item` の後に控えを消す。Windows Terminal が見張る `settings.json` が、途中で無くならないようにするため

### Windows Terminal のフォントと貼り付けの警告を変える / 手順 3: 補足: フォント

- `profiles.defaults.font.face`。既定は `Cascadia Mono`（見つからなければ Consolas）、大きさは 12（WezTerm の自分用の設定も 12）
- 「表示と入力」の手順 7 で既定の端末にしたので、スタートメニューから開いた管理者ではない窓は Windows Terminal に渡される。Windows Terminal は、コマンド ラインが一致するプロファイル（Windows PowerShell など）を使い、無ければ `profiles.defaults` を使う（`CascadiaSettings.cpp`）。新しく作る設定の Windows PowerShell とコマンド プロンプトのプロファイルは、自分のフォントを持たない（`userDefaults.json`）ので、`profiles.defaults` が効く
- 管理者として開いた窓（conhost）のフォントは、`HKCU\Console` などの別の設定で、この節では扱わない
- hackgen.md は自分のユーザーのフォントに入れ、パッケージのアプリ向けに読み取りの権限（`S-1-15-2-1`・`S-1-15-2-2`）を足す。MSIX の Windows Terminal から見えるかは確かめていない
- 見つからないと、設定の画面に「見つからないフォント:」、端末に「次のフォントが見つかりません: …」が出る（`Resources.resw` の日本語の訳）

### Windows Terminal のフォントと貼り付けの警告を変える / 手順 4: 補足: 複数行の貼り付けの警告

- 値は版で変わった。1.22 以前は `multiLinePasteWarning`（真偽値）、1.23 は `warning.multiLinePaste`（真偽値）、1.24 から `warning.multiLinePaste` が `automatic`・`always`・`never`（既定は `automatic`。`true` は `automatic`、`false` は `never` として読む）。古い名前も読み、新しい名前に直して書き直す。Microsoft の文書（interaction のページ）は、まだ古い名前だけを書いている
- `automatic` は、シェルが角かっこで囲む貼り付け（bracketed paste）を有効にしていないときに、改行を含む文字を貼ると警告する（`TerminalPage.cpp`）。Windows PowerShell 5.1 の PSReadLine 2.0.0 も ConPTY もこれを有効にしないので、5.1 の窓では毎回出るはず（コードからの推測。確かめていない）
- 画面では「操作」→「改行を貼り付ける際に警告する」（「"角かっこで囲まれた貼り付け" がオフの場合」・「常時」・「なし」）。ダイアログの題は「警告」で、ボタンは「強制的に貼り付け」と「キャンセル」
- 出るダイアログは 1 つだけ。複数行の警告が出ないときに、5 KiB（UTF-16 で 5,120 文字）を超えると `warning.largePaste`（既定 true）の警告が出る
- Windows Terminal は、貼るときに改行を Enter として送る。PSReadLine は、閉じていない文（`& {` など）の行を続きとして受けるので、1 行ずつ届いても、この文書のブロックは正しく動く
- `trimPaste`（既定 true）は、1 行の貼り付けの末尾の空白だけを削る。貼った後に Enter が要るのは、コピーボタンの中身に末尾の改行が無いため

### Windows Terminal で選択した文字をコピーする / 手順 2: 補足: copyOnSelect と貼り付け

- `copyOnSelect` は `settings.json` の最上位の値（[Windows Terminal の文書](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/interaction#automatically-copy-selection-to-clipboard)）。true では、選んだだけでクリップボードへコピーされ、右クリックは貼り付けになる
- 読み書きは親の項と同じく、コメントと末尾のカンマがあれば止め、BOM の無い UTF-8 で書く。控えの `settings.json.windows-setup.bak` は、あれば上書きしない
- 選択で、手順書からコピーしたブロックも置き換わる。親の[Windows Terminal のフォントと貼り付けの警告を変える](../shell-terminal.md#windows-terminal-のフォントと貼り付けの警告を変える)の手順 4 で複数行の警告を切っていれば、管理者の Windows Terminal の窓でも複数行が確かめずに動くおそれがある
- ソースと文書での確認で、実機では確かめていない

### Windows Terminal で選択した文字をコピーする / 手順 3: 補足: キー単位で戻す

- この項では `copyOnSelect` を false に戻す。親の[Windows Terminal のフォントと貼り付けの警告を変える](../shell-terminal.md#windows-terminal-のフォントと貼り付けの警告を変える)の手順 6 で控えを書き戻すと、この設定も控えを取ったときの状態へ戻る

### Windows 11 で WezTerm を入れる / 手順 1: 補足: WezTerm の中の PowerShell を使わない理由

[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-setup.md)

- WezTerm が動いていると、同じ節の手順 4 が止まる

### Windows 11 で WezTerm を入れる / 手順 2: 補足: 確かめる値の意味

- `Version` が `20240203-110809-5046fc22` なら stable（winget の `wez.wezterm` など）。同じ登録なので、nightly で上書きされる
- ほかの方法で入れた WezTerm を外すのは、混ざらないようにするため

### Windows 11 で WezTerm を入れる / 手順 4: 補足: 版と、中断・貼り直し

- 最後に出る `wezterm <版>` の版は、実行した日の nightly
- `中断:` で止まったとき、取ってきたものとログは `%TEMP%\wezterm-setup` に残る。次に貼ったときに消して作り直す
- 何度貼ってもよいのは、同じ場所に上書きするため

### Windows 11 で WezTerm を入れる / 手順 6: 補足: 右クリックのメニュー

- エクスプローラーでフォルダーを右クリックすると「Open WezTerm here」がある（Windows 11 の新しいメニューでは「その他のオプションを確認」の中）

### Git Bash と WezTerm の設定 / 手順 5: 補足: Git for Windows の長いパス対応

- `core.longpaths=true` は Git for Windows の C で実装されたコマンドの長いパス対応を有効にする。初期設定の clone より前に、自分のユーザーの `global` に設定する
- [PC 全体の設定](../windows-setup.md#pc-全体の設定)の手順 6 の `LongPathsEnabled=1` とは別の設定。Windows の一般的な長いパス対応には、OS 側の値に加えてアプリ側の対応も必要
- Git for Windows の公式資料は、スクリプトで実装された Git のコマンドや、エクスプローラー・IDE などには制限が残ると説明している。この設定だけで周辺ツールも長いパスを扱えるとは限らない
- リポジトリの `local` は `global` より優先される。ホームでの設定確認に加え、既存のリポジトリでは有効な値と出どころを確かめる
- `--global --includes` で、`global` のファイルが読み込む別の設定も含めて判定する。真偽値がすでに `true` なら書き換えず、元の表記と設定ファイルを保つ
- [Git for Windows: Git cannot create a file or directory with a long path](https://gitforwindows.org/git-cannot-create-a-file-or-directory-with-a-long-path.html)
- [Microsoft Learn: Maximum Path Length Limitation](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation)

### Git Bash と WezTerm の設定 / 手順 6: 補足: ログインシェルの読み込み

- 自分用の WezTerm の設定は、Git Bash を `-i -l`（対話・ログインシェル）で開く。ログインシェルの bash は、`~/.bash_profile`・`~/.bash_login`・`~/.profile` のうち最初にあるものだけを読む（bash の man の INVOCATION）。そのファイルが `~/.bashrc` を読み、その `~/.bashrc` が共通の bash 設定を読む
- Git for Windows の [`bash_profile.sh`](https://github.com/git-for-windows/build-extra/blob/main/git-extra/bash_profile.sh) は、最初のログイン時に `~/.bash_profile` を作る
  - 条件は、`~/.bashrc` があり、`~/.bash_profile`・`~/.bash_login`・`~/.profile` がどれも無いこと
  - 生成する内容は `# generated by Git for Windows` と、`~/.profile`・`~/.bashrc` があれば読む行。`~/.bash_profile` が無いという条件だけでは生成されない
- 共通の bash 設定の `install.sh`（[ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)）は、`~/.bash_profile`・`~/.bash_login`・`~/.profile` のどれも無ければ、`~/.bashrc` を読む `~/.bash_profile` を作る（`~/.bash_profile: 作成済み`）。どれかがあれば書き換えず、`~/<ファイル>: 既存の内容を維持。ログインシェルから ~/.bashrc を読むことを確認する` と出す（その確かめが、[Windows 11 で bash のログイン時の読み込みを確かめる](../shell-terminal.md#windows-11-で-bash-のログイン時の読み込みを確かめる)）
- [Windows 11 で bash のログイン時の読み込みを確かめる](../shell-terminal.md#windows-11-で-bash-のログイン時の読み込みを確かめる)は、既存のファイルを確かめ、読む行が無い場合だけ追記する。実機では確かめていない

### Windows 11 で bash のログイン時の読み込みを確かめる / 手順 3: 補足: 既存のファイルを残す

- ファイル全体は置き換えない。`~/.profile` を読む行など、Git for Windows が作った内容や利用者が足した内容を残す
- 戻すときも、この項で付けた印のある行だけを消し、印の無い `~/.bashrc` の読み込みは残す

### シェルのツールを入れる / 手順 2: 補足: 確かめる値

- `Tools` が空なら、どれも入っていない
- ほかの方法で入れたものを外してから始めるのは、混ざらないようにするため

### シェルのツールを入れる / 手順 4: 補足: scoop がすることと、zoxide を 0.9.9 に止める理由

- 5 つとも scoop の main のバケットの定義で、上流の Windows の zip を、定義の sha256 で確かめて置く（2026-10-08 の定義は fzf 0.74.4・zoxide 0.10.0・starship 1.26.0・eza 0.23.5・bat 0.26.1）
  - `was installed successfully!` の行の版は、入れた日の最新（zoxide は `0.9.9`）
  - fzf・zoxide・eza・bat は、`~\scoop\shims` に shim を作る（eza は `exa` の名前の shim も）
  - starship は shim を作らず、定義の `env_add_path` で `~\scoop\apps\starship\current` を自分のユーザーの `Path` の先頭に足す。scoop は、今の窓の `$env:PATH` にも足す（Scoop の `lib/system.ps1` の `Add-Path`）
  - bat は、定義の `env_set` で、自分のユーザーの環境変数 `BAT_CONFIG_DIR` を `~\scoop\apps\bat\current` にし、今の窓にも入れる。`config`・`syntaxes`・`themes` は `~\scoop\persist\bat` に控える（ファイルはハードリンク、フォルダーはジャンクション）。控えに `config` が無い最初の導入では、`%APPDATA%\bat\config` があれば写し、無ければ空のファイルを作る（定義の `pre_install`）
- **zoxide を 0.9.9 に止める理由**
  - 0.10.0 の bash の初期化は、Windows では `__zoxide_pwd` が `\command cygpath -w "\builtin pwd -L"` になり、コマンド置換が無い（`templates/bash.txt`）。今のディレクトリではなく、`<ドライブ>:\builtin pwd -L` の形の文字列を返すので、プロンプトのフックが移動に気付かず、Git Bash からは何も記録しない（上流の issue #1259）
  - 直すコミット（`1f484a4`、PR #1260、2026-07-07）は `main` にあり、`CHANGELOG.md` の `[Unreleased]` に「Bash/Zsh: fix `z` failing on Cygwin/MSYS2 due to `cygpath` being passed a bad string.」とある。2026-10-08 の時点で、タグの最新は `v0.10.0` で、このコミットを含むタグは無い
  - 0.9.9 の初期化は `\command cygpath -w "$(\builtin pwd -P)"`（Windows の `zoxide.exe` の中の文字列でも確かめた）。共通の bash 設定の Git Bash での検証（ryo-aoki-pc/bash の 2026-10-01・2026-10-06 の付録）も、0.9.9 で通っている
  - PowerShell の初期化は、この不具合に当たらない。PowerShell 7 の zoxide も Git Bash と同じ実行ファイルなので、0.9.9 にそろう
  - データベースの形は、0.9.9 と 0.10.0 で同じ（版 3 の `db.zo`。`src/db/mod.rs`）。0.10.0 から 0.9.9 に戻しても、覚えた履歴はそのまま読む
  - `main` には、データベースを平文の `db.txt` に変え、`db.zo` があれば読んで移す変更もある（`c479cc8`、#1288、2026-10-03。版になっていない）。直った版に上げると、履歴はその形に移るはず。上げた後に 0.9.9 に戻すと、上げた後に覚えたものは読まないはず
- **版の指定と止め方**（Scoop v0.6.0 のソース）
  - `scoop install zoxide@0.9.9` は、バケットの今の定義と版が違うと、バケットの git の履歴から `0.9.9` の定義を探し（`git log --follow -n 1 -G …` で見つけたコミットと、その親）、`~\scoop\workspace\zoxide.json` に書いてから入れる（v0.6.0 の #6370）。見つからなければ `WARN` の行を出して、定義の `autoupdate` で作る
  - 履歴を探すのは、main のバケットが git のリポジトリのときだけ（`lib/manifest.ps1` の `Find-HistoricalManifestInGit`）。そうでなければ `WARN  Bucket 'main' is not a git repository. Cannot search historical versions.` を出して `autoupdate` に移り、hash はバケットの履歴の定義のものではなく、そのときに取ったものになる。`autoupdate` も失敗すると、`Could not install: zoxide@0.9.9` で止まる
  - 本書の「アプリを入れる」の手順 2・3 は Git for Windows より前に scoop を入れるので、main のバケットは zip で置かれる（ScoopInstaller/Install の `install.ps1`）。git の形になるのは、最初の `scoop update`（`scoop-update.ps1` の `Sync-Bucket` の `Converting 'main' bucket to git repo...`）。`scoop install` が自分で `scoop update` を動かすのは、前の更新から 3 時間たったとき（`is_scoop_outdated`）だけなので、この節の手順 4 の先頭で `scoop update` を貼る
  - main のバケットでは、`73b1eafab`（2026-01-31）で 0.9.9 に、`f8683b6ce`（2026-07-04）で 0.10.0 になった。`f8683b6ce` の親の定義が 0.9.9
  - こうして入れたものは、`install.json` に `bucket` が無く、`url` が `workspace` の定義を指す。`scoop status` と `scoop update` は、その定義の版（0.9.9）を最新とみなすので、それだけでも上がらない。`scoop list` の `Source` は `<auto-generated>`
  - そのうえで `scoop hold` を付けた（`install.json` に `hold` を書く）。`scoop list` の `Info` が `Held package` になり、止めてあることが見える。`scoop update * --force` でも、止めたものは上げない
  - 直った版に上げるときは、`scoop unhold` の後に `scoop update zoxide --force` にする。`--force` は、版を指定して入れたもの（`bucket` が無く、`url` が `workspace` の定義）を、バケットの今の定義で入れ直す（v0.6.0 の #6730）。`--force` が無ければ、`zoxide: 0.9.9 (latest version)` の形の行を出して何もしない
  - 先に `scoop update` を貼るのは、バケットを新しくするため（`scoop update <名前>` は、前の更新から 3 時間たっていなければバケットを新しくしない）
  - 版を指定したものは、`~\scoop\workspace\zoxide.json` の場所として扱われ、`prune_installed` は入っているとみなさない（`installed` が `zoxide.json` の名前で探す）。0.10.0 が入っていても 0.9.9 を並べて入れ、`current` を 0.9.9 に付け替え、0.10.0 のフォルダーを残す。そのため、この節の手順 3 で先に外す
  - 同じ 0.9.9 がもう入っていると、`'zoxide' (0.9.9) is already installed.` の警告の後の `continue`（`scoop-install.ps1` の `ForEach-Object` の中で、囲むループが無い）が `bin/scoop.ps1` の `switch` まで抜け、同じ行のほかの名前を入れずに終わる。そのため、この節の手順 4 では zoxide だけを別の `scoop install` にした
  - 版を指定しない名前を並べたとき（この項の手順 4 の `scoop install fzf starship eza bat`）は、もう入っているものを `prune_installed` で飛ばす。`'<名前>' (<版>) is already installed. Skipping.` の警告は出ない（`Get-Dependency` が名前を `main/<名前>` の形に変えるので、警告を出す前の、指定した名前との突き合わせに当たらない）
  - 名前を 1 つだけ渡したときは、もう入っていれば `'<名前>' (<版>) is already installed.` と `Use 'scoop update <名前>' to install a new version.` の警告を出して終わる（`$apps.length -eq 1` の分かれ）
  - [scoop・winget・WSL を上げる](../windows-setup.md#scoopwingetwsl-を上げる)の手順 8 で、先に main のバケットの `bucket\zoxide.json` の版を見るのは、`scoop update zoxide --force` が Releases ではなく、main のバケットの今の定義を入れるため（`update` の `$pin_broken` から `Find-AppBucket`）。バケットの定義は、Releases に出てから自動の更新で上がるまで遅れる。0.10.0 のまま上げると、止めるのをやめた 0.10.0 になる
  - `scoop uninstall` は、止めてあっても消す（`hold` を見ない）。そのため、[ロールバックの「エディタとシェルのツールを消す」](../extra/windows-setup.md#エディタとシェルのツールを消す)の手順 7 に `scoop unhold` は要らない
- **VC++ ランタイム**: 5 つの Windows の実行ファイル（x64）の DLL の読み込みの表（PE のインポート表）で、`VCRUNTIME140.dll` を使うのは bat だけだった
  - fzf（Go）は `kernel32.dll` だけ。zoxide と starship は MSVC のビルドだが、C のランタイムを静的にリンクする（zoxide の `.cargo/config.toml`、starship の `release.yml` の `+crt-static`）。eza は MinGW のビルドで、Windows に付いている `msvcrt.dll` を使う
  - bat の定義の `suggest` は、extras の `vcredist2022` と `less` を勧める表示だけで、入れはしない。本書では [WezTerm](../shell-terminal.md#windows-11-で-wezterm-を入れる)の手順 3（winget の `Microsoft.VCRedist.2015+.x64`、PC 全体）を前提にした。starship の定義の `suggest`（`vcredist2022`）は、入れなくてよい
- starship の定義の `notes` は、PowerShell の `$PROFILE` に `Invoke-Expression (&starship init powershell)` を足すよう案内するが、従わない。Windows PowerShell 5.1 の `$PROFILE` は、手順書を貼る窓（管理者の窓も）が読むプロファイル。PowerShell 7 には、[PowerShell 7 のプロファイルを設定する](../shell-terminal.md#powershell-7-のプロファイルを設定する)が、zoxide と starship の行を 1 回だけ置く

### シェルのツールを入れる / 手順 6: 補足: bat の設定ファイル

- Windows の bat は、`BAT_CONFIG_PATH` が無ければ `BAT_CONFIG_DIR` の下の `config` を、それも無ければ `%APPDATA%\bat\config` を読む（bat 0.26.1 の `src/bin/bat/directories.rs`・`config.rs`。`XDG_CONFIG_HOME` も `~/.config` も見ない）。scoop で入れると `BAT_CONFIG_DIR` の下になる
  - そのため、AlmaLinux 10 の [bat の設定ファイル](../shell-terminal.md#bat-の設定ファイル)の bash のブロックを Git Bash に貼っても効かない
  - `C:\ProgramData\bat\config`（PC 全体）があれば、bat はその後ろに自分の設定をつないで読む。本書では作らない
- 書く場所は、bat が探すのと同じ順（`BAT_CONFIG_PATH`、無ければ `BAT_CONFIG_DIR` の下の `config`）で決める。`BAT_CONFIG_PATH` を自分で決めていても、bat が読む場所に書ける。どちらも無ければ（scoop の bat が入っていない）、`%APPDATA%` には書かずに止める
- `bat --config-file` の出力は使わない。bat はパイプに UTF-8 で書く（bat 0.26.1 の `src/bin/bat/main.rs` の `println!`）が、Windows PowerShell 5.1 は外部コマンドの出力を `[Console]::OutputEncoding`（日本語の Windows では OEM のコードページ 932）で読む。ユーザーのフォルダー名に ASCII 以外の文字があると、場所の文字が化けて書けない（Windows では確かめていない）
- 「無いときだけ」ではなく「空のときだけ」書く。scoop は最初の導入で空の `config` を作る（定義の `pre_install`）。`%APPDATA%\bat\config` から写されたものや、手で書いたものは変えない
- `-Encoding ASCII` にしたのは、BOM を付けないため
  - Windows PowerShell 5.1 の `-Encoding UTF8` は BOM を付ける。bat は設定の各行の前後の空白を削ってから読むが、BOM は削らず、1 行目をファイルの名前として読んで失敗する（Linux の bat 0.26.1 で確かめた。[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/windows-setup.md#付録-シェルのツールの任意節のブロックの確認2026-10-08)）
  - テーマの名前と 3 行の中身は ASCII だけ。改行は CRLF になるが、bat は行末の `\r` も削る（同じ記録）
- `current\config` に書いた中身は、ハードリンクのもう一方の控え（`persist`）にも入るはず（Linux のハードリンクと PowerShell 7.5.3 では、同じ中身になった。Windows の NTFS と 5.1 では確かめていない）
- 戻す（[ロールバックの「エディタとシェルのツールを消す」](../extra/windows-setup.md#エディタとシェルのツールを消す)の手順 8）のは控えのファイルで、この節で書いた形（1 行目がテーマ、後の 2 行が同じ）のときだけ、空にする。ハードリンクのもう一方（`current\config`）も空になるので、bat を残していても組み込みの既定値に戻る。scoop の最初の導入と同じ空のファイルなので、入れ直しても困らない

### シェルのツールを入れる / 手順 7・8: 補足: Git Bash での確かめ方

- AlmaLinux 10 の初期設定の「シェルのツール」の手順 4〜7・9・10 と「キー操作を試す」の手順 2〜5 は、`brew` の行を含まず、共通の bash 設定が読んだ結果を確かめるだけなので、Git Bash でもそのまま使える。この節には bash のブロックを足さず、Windows で違うところだけを箇条書きにした（同じブロックを書き写すと、片方だけ直したときに食い違う）
  - 「シェルのツール」の手順 8（tmux）は、Windows では入れない。「キー操作を試す」の手順 1 は bash-completion と `~/.inputrc`（AlmaLinux 10 の「共通の bash 設定」の手順 3・4）を確かめるもので、この節では入れていない
- WezTerm は Windows で新しいタブを開くたびに、レジストリのシステムとユーザーの環境変数を読み直す（WezTerm の `pty/src/cmdbuilder.rs` の `get_base_env`）。そのため、この項の手順 3 の後に開いた新しいタブには、WezTerm を起動し直さなくても、starship の `Path` と `BAT_CONFIG_DIR` が入るはず（確かめていない）。起動し直すのは、プロンプトが starship にならなかったときだけにした
- 違うところの出どころ
  - `bind -X` のコロンと、WezTerm のシェル統合のマウス報告よけの行: ryo-aoki-pc/bash の `docs/install.md`（Git Bash の bash 5.3 の記録）
  - eza の見出し: eza 0.23.5 の `src/output/table.rs`。Windows では `Permissions` の見出しが `Mode` になり、`User` の列は Unix のときだけ作る
  - Git for Windows の `ll`（`/etc/profile.d/aliases.sh`。ログインシェルだけ）は `~/.bashrc` より先に読まれるので、共通の bash 設定の `ll` が上書きする。`MANPAGER` は bat があれば入るが、Git Bash に `man` は無い（ryo-aoki-pc/bash の `docs/reference/readme.md`）
  - zoxide: Windows の zoxide は、Git Bash ではプロンプトのたびに `cygpath -w` を動かし、Windows の形のパスで記録する。データベースは `HOME` の下ではなく `%LOCALAPPDATA%\zoxide`（zoxide の README の `_ZO_DATA_DIR` の表と、scoop の定義の `notes`）
  - fzf の ASCII 以外の文字: fzf の `CHANGELOG.md` の 0.54.2 に、Windows では全画面（`--no-height`）で開いたときしか ASCII 以外の文字を読めず、必要なら `FZF_DEFAULT_OPTS` に `--no-height` を足すよう書いてある。キー操作と `**<Tab>` は画面の一部（`--height`）に開く
  - fzf は Windows でも `$SHELL` で外部のコマンド（プレビューの bat など）を動かし、`/` を含むパスは `cygpath -w` で直す（fzf 0.74.4 の `src/util/util_windows.go`）。Git Bash の `SHELL` は bash なので、プレビューは bash で動くはず
- スタートメニューの「Git Bash」（mintty）でも同じ共通の bash 設定を読むが、fzf は winpty の連携で動く（fzf の CHANGELOG の 0.53.0）ので、WezTerm（ConPTY）と動きが違いうる。確かめは WezTerm で行う
- 覚えたディレクトリは `%LOCALAPPDATA%\zoxide` に入る（PowerShell 7 の zoxide も同じものを使う）

### Windows 11 で starship の表示を変える / 手順 2: 補足: Git Bash と PowerShell 7 が読む場所

- `%USERPROFILE%\.config\starship.toml` は、Git Bash の `~/.config/starship.toml` と同じファイル
- `STARSHIP_CONFIG` を指定していなければ、Windows の starship が既定で読む（starship の `src/context.rs`）
- Git Bash は共通の bash 設定の初期化、PowerShell 7 は[PowerShell 7 のプロファイルを設定する](../shell-terminal.md#powershell-7-のプロファイルを設定する)の手順 2 の starship の行で読む。設定ファイルだけを置いても、PowerShell 7 への初期化は増えない
- 書く 5 つの値は、AlmaLinux 10 の[starship の設定ファイル](../shell-terminal.md#starship-の設定ファイル)と[starship でユーザー名とホスト名を常に表示する](../shell-terminal.md#starship-でユーザー名とホスト名を常に表示する)と同じ。プロンプトの前の空行を省き、ディレクトリを最大 3 階層にし、リポジトリで切らず、ユーザー名とホスト名を常に表示する
- ファイル全体を書き換えるので、既存のモジュール・配色・プリセットも置き換わる
- 既存のファイルは `~/.config/starship.toml.shell-terminal.bak` に控える。元が無い場合は `~/.config/starship.toml.shell-terminal.new` で記録する
- 既存の控えは上書きしない
- Windows の Git Bash と PowerShell 7 で共有される見た目は、実機では確かめていない

### Windows 11 で starship の表示を変える / 手順 5: 補足: 書く前の状態に戻す

- 控えがあればその内容を書き戻し、元が無い記録があればこの項で作った `starship.toml` を消す。控えか記録を残すことで、再実行でも最初の状態へ戻せる
- Git Bash と PowerShell 7 の両方に効く。控えを取った後に加えた設定は、書き戻すと残らない

### PowerShell 7 のプロファイルを設定する / 手順 2: 補足: 足す行

- プロファイルは PowerShell 7 の `$PROFILE`（CurrentUserCurrentHost）で、ドキュメントの既知のフォルダーの下の `PowerShell\Microsoft.PowerShell_profile.ps1`（`CorePsPlatform.cs`・about_Profiles）。5.1 から書くので、`[Environment]::GetFolderPath('MyDocuments')` で求める。PowerShell はプロファイルを自分では作らない。MSIX の PowerShell 7 は、全ユーザーのプロファイル（`$PSHOME`）を使えない
- Ctrl+Enter: PowerShell 7.5 の PSReadLine 2.3.6 と、7.6 の 2.4.5 も、Windows モードの Ctrl+Enter は `InsertLineAbove`（`KeyBindings.cs`）
  - スタートメニューから管理者として開いた PowerShell 7 は conhost の窓になり（「表示と入力」の手順 7 の補足）、右クリックで貼ると 5.1 と同じく行が逆順になるはず
  - Windows Terminal は、貼るときに LF を CR に直す（`ControlCore::PasteText`）ので起きない。WezTerm（Windows では、貼るときに改行を CRLF に直す）は確かめていない
- ↑/↓: `HistorySearchBackward`・`HistorySearchForward`（既定は F8・Shift+F8 に割り当て）。[共通の bash 設定](../shell-terminal.md#共通の-bash-設定)の `~/.inputrc` の `history-search-backward` と同じく、打った文字で始まる履歴だけを出す
  - `-HistorySearchCursorMovesToEnd` は付けない（既定の False で、カーソルは打った文字の後ろに残る。bash と同じ）。Microsoft の `SamplePSReadLineProfile.ps1` は付けている
  - 予測の一覧（ListView）が出ているときは、候補を選ぶ。複数行の入力の中では、ほかの行へ移る
  - 履歴のファイル（`%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`）は 5.1 と共有する
- 各行を `if (Get-Module -Name PSReadLine) { … }` で囲むのは、`pwsh -Command`・`-File` では PSReadLine が読み込まれず（`ConsoleHost.cs` の `LoadPSReadline`）、囲まないと `Set-PSReadLineKeyHandler` が PSReadLine を自動で読み込むため。`-NoExit` 付きの起動（WezTerm の起動メニューの PowerShell 7）では読み込まれる
- 行は ASCII の文字だけにする。5.1 の `Add-Content` は新しいファイルを ANSI で書き、PowerShell 7 は BOM の無いファイルを UTF-8 として読むので、日本語を書くと化ける
- 予測（Predictive IntelliSense）は書かない。PSReadLine 2.2.6 から既定で有効で、PowerShell 7 では `HistoryAndPlugin`・`InlineView`（`Cmdlets.cs`。about_PSReadLine の「既定で無効」は古い記述）。F2 で一覧（ListView）に切り替わる。予測のプラグインを入れていなければ、候補は履歴だけ
- EditMode は Windows（既定）のまま。[PowerShell 7 で Emacs モードを使う](../shell-terminal.md#powershell-7-で-emacs-モードを使う)を選ぶときだけ変える
  - `EditMode` を変えると、それより前に `Set-PSReadLineKeyHandler` で付けたキーは既定に戻る。このため、EditMode の行をキーの割り当てより前に置く
  - Emacs の既定のキーには Ctrl+V の `Paste` が無いので、割り当て直す。Ctrl+Enter は、この項の手順 2 の `AddLine` の行を後から読む
- プロファイルが無ければ作る。同じ行は足さない。プロファイルにほかの行があれば、そのまま残る

### PowerShell 7 のプロファイルを設定する / 手順 2: 補足: zoxide と starship の順

- zoxide の初期化は、その時点の `prompt` を `$__zoxide_prompt_old` に入れて包み、プロンプトのたびに `__zoxide_hook` を呼ぶ。既定の `--hook pwd` では、ディレクトリが変わったときだけ `zoxide add` する（zoxide の `templates/powershell.txt`。0.9.9 と 0.10.0 で同じ）
- starship の初期化は `prompt` を定義し直すので、zoxide の後に読むと zoxide の包みを捨てる。starship の `prompt` は、最初に `$?` を控えた後に、`Invoke-Starship-PreCommand` があれば呼ぶ（starship 1.26.0 の `starship.ps1`）。この節の行は、そこで `__zoxide_hook` を呼ぶ
- 両方の README の形（starship → zoxide）では、zoxide の包みが starship の `prompt` を呼ぶ前に `if` を評価して `$?` を真に戻し、失敗したコマンドの後もプロンプトが成功の印になるおそれがある（コードからの推測。確かめていない）。WezTerm の自分用の設定の `shell/wezterm.ps1` は、元の `prompt` を呼ぶ直前に `$?` を戻している
- 初期化の行は、ツールが無ければ（`Get-Command -CommandType Application`）読まない。scoop の zoxide は shim、starship は `PATH` に足したフォルダーから見つかる
- `Invoke-Starship-PreCommand` はプロンプトのたびに呼ばれるので、`__zoxide_hook` があるかは `Test-Path -Path Function:\__zoxide_hook` で見る（starship の `starship.ps1` も `Test-Path` の形）
  - `Get-Command` は、無い名前のときに `PATH` とモジュールを探すので、zoxide を入れていない PC で、プロンプトのたびに遅くなる
- zoxide と starship の行を、それぞれの手順書から 1 行ずつ足す形にしないのは、通す順で行の順が変わるため（bash の共通設定が順を管理するのと同じ考え）

### PowerShell 7 のプロファイルを設定する / 手順 3: 補足: Tab の一覧

- 既定の Tab は、候補を 1 つずつ入れ替える
- 一覧を出す既定のキーの Ctrl+Space は、[「表示と入力」](../windows-setup.md#表示と入力)の手順 8 で IME が受け取るので、Tab がその代わりになる

### PowerShell 7 のプロファイルを設定する / 手順 4: 補足: 5.1 から確かめる形と実行ポリシー

- 5.1 から `pwsh.exe -Command { … }` にスクリプト ブロックを渡すと、5.1 が `-EncodedCommand` に変えて渡し、結果をオブジェクトで受け取る（5.1 の `NativeCommandProcessor.cs` の minishell）。Windows では確かめていない
- 結果は、子の pwsh で `Out-String` にして文字列で受け取る。オブジェクトのまま受け取ると、5.1 は最初に届いた実行ポリシーの列で表を作るので、キーの行が空になる
  - `-Width 120` を付けるのは、子が端末の幅を取れないと、`Out-String` が空の行だけを返すため
- `-NoProfile` でも `$PROFILE` は設定される（`ConsoleHost.cs`）ので、`. $PROFILE` で読む
- Windows 版の PowerShell 7 は、`$PSHOME\powershell.config.json` に `RemoteSigned` を持って配られ、これが `LocalMachine` の値になる（`build.psm1`。MSIX の `$PSHOME` にもあるかは推測）。「貼り付けの設定」の手順 4 の 5.1 の値（レジストリ）は効かない
- すべてが `Undefined` なら `Restricted` になり、プロファイルが読まれない。そのときだけ、この節の手順 5 で `CurrentUser` を `RemoteSigned` にする（`Documents\PowerShell\powershell.config.json` に書かれる）。MSIX では `LocalMachine` に書けない
- `Set-ExecutionPolicy` に `-Force` を付けるのは、確認の問いで止まらないようにするため
- UniGet UI は scoop を `-NoProfile -ExecutionPolicy Bypass` で動かすので、このプロファイルと実行ポリシーに依らない

### PowerShell 7 のプロファイルを設定する / 手順 7: 補足: 印の行だけを消す

- [ロールバックの「アプリと貼り付けの設定を外す」](../extra/windows-setup.md#アプリと貼り付けの設定を外す)の手順 6 と同じく、ファイルをバイトのまま読み、消す行のほかのバイトを変えずに書き戻す（[ロールバックの「アプリと貼り付けの設定を外す」の手順 6 の補足](windows-setup.md#ロールバック--アプリと貼り付けの設定を外す--手順-6-補足-文字コードを変えずに消す)）
- 消すのは、行末が `  # windows-setup.md` または `  # shell-terminal.md` の行。印が行の途中にある行は消さない
- PowerToys の Command Not Found が足した行は、印が無いので残る
- `Documents\PowerShell` のフォルダーは消さない（モジュールや `powershell.config.json` が入ることがある）

### PowerShell 7 で Emacs モードを使う / 手順 2: 補足: 設定する行と挿入位置

- [Set-PSReadLineOption の `EditMode`](https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlineoption?view=powershell-7.6#-editmode)は、それより前に付けたキーを既定に戻す。任意の行は、最初の `Set-PSReadLineKeyHandler` を含む文より前、`using`・`param`・`#Requires` などの先頭の宣言より後に入れる
- Emacs の既定のキーには Ctrl+V の `Paste` が無い（[PSReadLine の Paste](https://learn.microsoft.com/en-us/powershell/module/psreadline/about/about_psreadline_functions?view=powershell-7.6#paste)）。2 行目で Ctrl+V を割り当て直し、その後に親の項の Ctrl+Enter と ↑↓ の行を読む
- 印の無い EditMode の行がキーの割り当てより後にあれば、後から割り当てを消すので、書かずに止める。前にある行は残す。任意の 2 行を再実行で増やさず、既存の文字コードと、ほかの行のバイトを保つ
- 複合文の中の EditMode が挿入位置より後になる場合も、書かずに止める。モードとキーの設定を別の行へ分け、モードを先に置いてからやり直す
- バイトを保つための文字列と、構文解析する文字列を分ける。解析時だけ先頭の BOM を除き、挿入位置にはその長さを足して書き戻す
- 開いている窓では EditMode を変えない。貼り付けに使うキーの割り当てまで変わるため、プロファイルに書くだけにして、新しい窓で確かめる。実機では確かめていない

### PowerShell 7 で Emacs モードを使う / 手順 5: 補足: この項だけを戻す

- 行末が `  # shell-terminal.md` の行だけを消す。親の[PowerShell 7 のプロファイルを設定する](../shell-terminal.md#powershell-7-のプロファイルを設定する)の手順 7 は、`  # windows-setup.md` の行も含めて消す
- 印の無い EditMode の行は残る。利用者が先に Emacs にしていたときは、任意の行を消しても Windows モードへは戻らない

### Windows PowerShell 5.1 のキー操作を変える / 手順 2: 補足: 適用範囲と貼り付け

- 5.1 の CurrentUserCurrentHost は、ドキュメントの既知のフォルダーの下の `WindowsPowerShell\Microsoft.PowerShell_profile.ps1`。通常の窓と、同じユーザーで開いた管理者の conhost の窓の両方で読まれる
- プロファイルは、全ユーザー・全ホスト → 全ユーザー・現在のホスト → 現在のユーザー・全ホスト → 現在のユーザー・現在のホストの順に読まれる（[about_Profiles](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-5.1#profile-types-and-locations)）。先に読まれた `$PSHOME\profile.ps1` などが付けたキーも、EditMode を変えると既定に戻る
- 書く順は Emacs → Ctrl+V の `Paste` → ↑↓ の履歴検索 → 既存のキーの行。[貼り付けの設定](../windows-setup.md#貼り付けの設定)の手順 5 の Ctrl+Enter の `AddLine` は、後から読むので残る
- 挿入する位置、印の無い EditMode が後ろにあるときの中断、バイトを保った書き込みは、[PowerShell 7 で Emacs モードを使う](../shell-terminal.md#powershell-7-で-emacs-モードを使う)の手順 2 と同じ考え方
- `if (Get-Module -Name PSReadLine)` で囲み、PSReadLine が読み込まれていない起動では何もしない
- conhost の右クリックの貼り付けは、PSReadLine の `Paste` を呼ばず、クリップボードの文字をキー入力へ変えて入力バッファへ書く
  - [Clipboard.cpp](https://github.com/microsoft/terminal/blob/main/src/interactivity/win32/Clipboard.cpp)の `Clipboard::Paste` → `StringPaste` → `TextToKeyEvents` → `pInputBuffer->Write`
  - キーとして届くので、Ctrl+Enter の割り当てには依る。コピーボタンの中身の LF は Ctrl+Enter として届き、Windows モードの既定の `InsertLineAbove` では行が逆順になる（[貼り付けの設定の手順 2 の補足](windows-setup.md#貼り付けの設定--手順-2-補足-行を足す理由)）。EditMode を変えると、それより前に付けた `AddLine` は消えるので、この項の行は、貼り付けの設定の Ctrl+Enter の行より前に入れる
  - Emacs モードの管理者の conhost で、右クリックと複数行の貼り付けは実機では確かめていない

### Windows PowerShell 5.1 のキー操作を変える / 手順 5: 補足: この項と貼り付けの設定を戻す

- この項では、行末が `  # shell-terminal.md` の行だけを消す。印の無い行と、貼り付けの設定の `  # windows-setup.md` の行は残す
- [ロールバックの「アプリと貼り付けの設定を外す」](../extra/windows-setup.md#アプリと貼り付けの設定を外す)の手順 6 は、両方の印の行を消す。どちらも、既存の文字コードとほかのバイトを変えずに書き戻す
- プロファイルの変更は、新しく開く窓で効く。開いている窓へ読み直して EditMode を変える確かめ方はしない。実機では確かめていない

### Git for Windows・Firefox・WezTerm を上げる / 手順 6: 補足: 窓を閉じる理由

- WezTerm が動いていると、同じ項の手順 7（[Windows 11 で使う](../shell-terminal.md#windows-11-で-wezterm-を入れる)の手順 4 のブロック）が止まる

### ロールバック / OpenSSH・Git for Windows・Firefox・WezTerm を外す / 手順 8: 補足: アンインストーラの動き

- アンインストーラは `C:\Program Files\WezTerm\unins000.exe`（Inno Setup）。場所は登録の `UninstallString` から読む
- 引数の `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART` は、Inno Setup のアンインストーラの標準の引数（確認の窓も完了の窓も出さない）
- アンインストーラは自分の写しを `%TEMP%` に作り、写しの方が消す。終了コードが返った時点では片付けがまだ続いていることがある（Inno Setup の文書）ので、登録とフォルダーが消えるまで 60 秒まで待つ
- 消えるもの: インストーラが置いたファイルとフォルダー、スタートメニューの「WezTerm」、右クリックの「Open WezTerm here」、PC 全体の `PATH` の `C:\Program Files\WezTerm`、アンインストールの登録
- 残るもの: 設定ファイルと、WezTerm が作る作業用のフォルダー（ソースでは `%USERPROFILE%\.local\share\wezterm`・`%APPDATA%\wezterm`・`%LOCALAPPDATA%\wezterm`。作られていれば）

### 選択した方針

#### 共通の bash 設定

- **bash-completion はシステムの RPM にした**: BaseOS の 2.11 で足りる。Homebrew にも `bash-completion@2`（2.16 系）があるが、RPM の各パッケージが置く `/usr/share/bash-completion/completions/` を読むのはシステムのものの方が素直で、`sudo` のシェルでも同じものが効く
- **Homebrew の補完は bash リポジトリから全部読む**: 遅延読み込みの対象のディレクトリに無いため（「シェルのツール」の手順 3 の補足）。`~/.local/share/bash-completion/completions/` にシンボリックリンクを置けば遅延読み込みにできるが、入れるたびに足す手間があるので採らない
- **`~/.inputrc` を使い、`~/.bashrc` の `bind` にはしない**（「共通の bash 設定」の手順 4 の補足）
- **採らなかった設定**
  - `HISTTIMEFORMAT`（`history` に時刻を出す）: 履歴ファイルに `#<epoch>` の行が増える。本書は履歴の見え方を変えない範囲にとどめる
  - `HISTCONTROL=…:erasedups`（同じ行を全部消して 1 つにする）: 覚えている一覧の中だけを直し、ファイルの古い重複は残る。効き目が分かりにくいので入れない
  - `PROMPT_COMMAND` に `history -a`（コマンドごとにファイルへ書き、別の端末ですぐ使う）: AlmaLinux 10 の `PROMPT_COMMAND` は配列で、starship・WezTerm のシェル統合・zoxide が順番に意味を持って触っている（[シェルのツールの手順 4](../shell-terminal.md#シェルのツール) の補足）。そこへ足す形は本書では扱わない
  - `set bell-style none`（ベルを消す）、`menu-complete`（Tab で候補を順に入れる）: 好みの幅が大きいので入れない
  - `shopt -s histappend`: `/etc/bashrc` が対話のシェルで入れている（「共通の bash 設定」の手順 2）
- **atuin（履歴を SQLite に持ち、同期もする）は使わない**: 履歴の検索は [fzf](../almalinux-setup.md) の Ctrl+R で足りる。[導入元一覧](../tool-catalog.md#cli-定番の置き換え)の行のまま

[検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/almalinux-setup.md)

#### シェルのツール

- **シェルのツールは 1 回の `brew install` で入れる（「シェルのツール」の手順 1）**: 依存の確認（`[y/n]`）が 1 回で済む。初期化は共通の bash 設定が持つので、入れた後は端末を開き直すだけ

##### starship

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `arm64_linux` ボトルを使える | **採用** |
| 公式 install.sh（`sh -c "$(curl -sS https://starship.rs/install.sh)"`） | `/usr/local/bin` にバイナリを 1 つ置く。`sudo` が要り、更新は自分で再実行する | 不採用（Homebrew に揃える） |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-musl` のビルドがある。更新は手作業 | 不採用 |
| `cargo install starship` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

##### eza

[この節の検証記録](https://github.com/ryo-aoki-pc/setup-notes-verification/blob/main/docs/verification/shell-terminal.md#eza-選択した方針)

| 経路 | EL10 aarch64 での状況 | 採否 |
|---|---|---|
| **Homebrew** | `eza 0.23.5` の `arm64_linux` ボトルがある。upstream の最新と一致 | **採用** |
| EPEL / AppStream / CRB | **`eza` も、前身の `exa` も無い**（`dnf list --available eza exa` → `Error: No matching Packages to list`） | 使えない |
| 公式の deb リポジトリ | eza は Debian/Ubuntu 向けの apt リポジトリを配っているが、**RPM 版の配布は無い** | 使えない |
| GitHub Releases のバイナリ | `aarch64-unknown-linux-gnu` / `musl` のビルドがある。展開して PATH に置くだけだが、更新は手作業 | 不採用（Homebrew に揃える） |
| `cargo install eza` | Rust toolchain が要り、Raspberry Pi ではビルドに時間がかかる | 不採用 |

#### HackGen Console NF

| 経路 | 状況 | 採否 |
|---|---|---|
| **Homebrew の cask `font-hackgen-nerd`** | `brew upgrade` で上がり、`brew uninstall` で消せる。自分のユーザーにだけ入る | **採用**（Homebrew 系の手順書と揃える） |
| GitHub のリリースの zip を手で展開 | `~/.local/share/fonts` に置く。Homebrew が要らないが、**更新は手作業** | 不採用（Homebrew がある環境では cask で足りる） |
| 全ユーザー向け（`/usr/local/share/fonts` に置く） | root で置けば全ユーザーから見えるが、cask は自分のホームに置く。複数ユーザーで使う機会が無いので要らない | 不採用 |

- upstream の README は、Linux 向けの導入手順を書いていない（GitHub のリリースの ttf と、Mac の Homebrew、Windows の Chocolatey を案内している）
- Homebrew の cask は upstream の README では Mac 向けとして紹介されている

#### WezTerm

`wezterm-gui` が要求するのは次のもの（`dnf repoquery --requires wezterm-gui`）:

- `libc.so.6(GLIBC_2.34)`
- `libssl.so.3(OPENSSL_3.0.0)` / `libcrypto.so.3`
- `libwayland-client.so.0` / `libwayland-egl.so.1`
- `libxkbcommon.so.0(V_0.6.0)` / `libxkbcommon-x11.so.0`
- `libxcb.so.1` / `libxcb-image.so.0` / `libxcb-util.so.1`
- `libX11.so.6` / `libX11-xcb.so.1`
- `libfontconfig.so.1`、`mesa-libEGL`、`dbus`

EL10 は glibc 2.39 / OpenSSL 3.5（`libssl.so.3` の soname と `OPENSSL_3.0.0` シンボルバージョンを両方提供）なので、EL9 向けバイナリがそのまま動く。

#### Windows 11 で HackGen Console NF を入れる

| 経路 | 状況 | 採否 |
|---|---|---|
| **上流の zip を版と sha256 を固定して、自分のユーザーに入れる** | 管理者の権限も scoop も要らず、Windows PowerShell 5.1 で動く。更新は手作業 | **採用** |
| scoop の個人のバケット mo-san の `font-hackgen-console-nf` | リリースの zip を使い、scoop と UniGet UI で上げられる。ただし、インストールのスクリプトが `Join-Path` に 3 つ以上の引数を渡していて、Windows PowerShell 5.1 の `Join-Path`（`-Path` と `-ChildPath` だけ）では失敗するはず。scoop はそのスクリプトを、`scoop` を打った PowerShell の中で動かす | 不採用（PowerShell 7 が要り、個人の保守） |
| scoop の nerd-fonts のバケット | HackGen は無い | — |
| winget | 既定のソース（winget-pkgs）に HackGen は無い。winget の一覧のサイトには `yuru7.HackGen`（第三者の `dfirr/winget-hackgen` が作り直したインストーラで、PC 全体に入れる）が載っている | 不採用 |
| Chocolatey | 上流の README が Windows 向けに案内している | 不採用（別のパッケージ マネージャーを足し、管理者が要る） |
| PC 全体（`C:\Windows\Fonts`）に入れる | 管理者が要る | 不採用（AlmaLinux 10 と同じく自分のユーザーだけ） |

#### Windows Terminal のフォントと貼り付けの警告を変える

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| 書く場所 | `settings.json`（コメントがあれば止める） | fragment: 全体の設定と `profiles.defaults` を読まない |
| フォント | `profiles.defaults`（全プロファイル） | プロファイルごと（fragment の `updates`）: 一致するプロファイルの無い窓に効かない |
| 複数行の警告 | 既定（`automatic`）。切るのは条件付き（この節の手順 4） | 無条件に `never`: 信用できない複数行も、確かめずに動く |
| 既定のプロファイル | Windows PowerShell のまま | PowerShell 7: 5.1 でだけ動く手順を貼り違えやすい（[PowerShell 7 のプロファイルの選択した方針](#powershell-7-のプロファイルを設定する)） |
| `copyOnSelect` | 既定（false）のまま。任意の手順で true にできる | true: 選ぶとクリップボードが置き換わり、右クリックが貼り付けになる。複数行の警告を切っている窓では、意図しない貼り付け（実行）になりやすい |
| 起動の大きさ | 既定（120×30）のまま | 好みなので扱わない |
| 管理者の窓（conhost）のフォント | 扱わない | 別の設定（`HKCU\Console`・ショートカットごと） |
| 戻し方 | 控えのファイルを書き戻す | 足した値だけを消す: 控えのほうが、書く前の状態に確実に戻る（その後に画面で変えたものは消える） |

#### Windows 11 で WezTerm を入れる

- **Windows 11 では、インストーラを直接取って、`.sha256` と比べてから黙って動かす方式を採用した**
  - [Claude Code の Remote Control（Windows）](../ai-agents.md#claude-code-の-remote-control-実施手順)が前提にしている `C:\Program Files\WezTerm` に、公式の形のまま入る
  - `.sha256` は同じリリースに置かれたものなので、分かるのは壊れていないことまで。署名が無いので、ほかに本物かを確かめる手立ては無い（winget の定義の sha256 も、同じファイルから bot が取ったもの）
  - winget の `wez.wezterm.nightly` は、入れられる日なら 1 行で済み `VCRUNTIME140.dll` の依存も入るが、入るかどうかが日によるので採らなかった。依存の再頒布可能パッケージだけは winget で入れる（[Windows 11 で使う](../shell-terminal.md#windows-11-で-wezterm-を入れる)の手順 3）

#### シェルのツールを入れる

- **5 つのツールを 1 つの手順で入れる**: `scoop install` は、版を指定しない 4 つと zoxide の 2 回に分ける
  - git-delta と GitHub CLI は、Windows 11 のセットアップの項（[git-delta](../windows-setup.md#git-delta)・[GitHub CLI](../windows-setup.md#github-cli)）にある
- **導入元は scoop の main のバケット**（README の「導入の基盤」の、CLI ツールは scoop）
  - 管理者が要らず、[更新](../windows-setup.md#更新)の `scoop update *` と UniGet UI で上がる
  - zoxide の README は、Windows では winget を勧めている。0.10.0 の不具合は zoxide の初期化（実行ファイルの中）にあるので、どちらで入れても避けられず、版を止められる scoop にそろえた
- **シェルとの組み込み方は、[PowerShell 7 のプロファイルを設定するの選択した方針](#powershell-7-のプロファイルを設定する)と同じ**: Git Bash が主、PowerShell 7 は補助（starship と zoxide だけ）、Windows PowerShell 5.1 にはシェルのツールを入れない、WSL の AlmaLinux 10 は Linux のホストとして扱う
  - Git Bash では共通の bash 設定が読むので、この節は入れて確かめるだけにし、`~/.bashrc` には書かない
  - PowerShell 7 の fzf のキー操作（PSFzf）と eza の関数は入れない（主の Git Bash に同じものがある）
- **`XDG_CONFIG_HOME` などの環境変数は足さない**: Windows の bat と eza は `XDG_CONFIG_HOME` を見ない（bat の設定は `BAT_CONFIG_DIR` か `%APPDATA%`、eza のテーマは `%APPDATA%\eza\theme.yml`。eza 0.23.5 の `src/options/theme.rs`）。starship は `STARSHIP_CONFIG` が無ければ `~\.config\starship.toml` を読む（starship 1.26.0 の `src/context.rs`。Git Bash と PowerShell 7 で 1 つ）。zoxide は `%LOCALAPPDATA%\zoxide`。足すと、gh などほかのツールの設定の置き場所まで変わる
- **bat の設定は AlmaLinux 10 と同じ 3 行**: テーマも同じ名前の変数（`BAT_THEME_NAME`）で決める。書く場所だけが違う
- **Windows の starship の表示は、任意の[Windows 11 で starship の表示を変える](../shell-terminal.md#windows-11-で-starship-の表示を変える)で設定する**: Windows で動くコマンドだけを置き、Git Bash と PowerShell 7 が共有する `~/.config/starship.toml` に書く。実機では確かめていない
- **使い方と、そのほかの設定は AlmaLinux 10 の項を参照する**: fzf の候補の fd は共通の bash 設定が `command -v fd` で見つける（ryo-aoki-pc/bash の `bashrc`）。fd の入れ方と bat の設定ファイルは Windows で違うので、この項の手順を使う。Linux 専用のコマンドは Git Bash に貼らない

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| zoxide の版 | 0.9.9 に止める（`zoxide@0.9.9` と `scoop hold`）。上げるのは、main のバケットの定義が 0.10.0 より新しくなってから | 0.10.0: Git Bash で記録しない。共通の bash 設定で `__zoxide_pwd` を上書きする: 上流の初期化に合わせた上書きを持ち、直った版が出たら外す手間が要る |
| 入れる単位 | 1 つの手順で、版を指定しない 4 つを 1 回の `scoop install`、zoxide の 0.9.9 を別の 1 回 | ツールごとの節: 確かめる場所が同じ Git Bash のタブで、まとめたほうが短い。5 つを 1 回の `scoop install`: zoxide の 0.9.9 がもう入っていると、scoop がほかの 4 つを入れずに終わる |
| Git Bash での確かめ | AlmaLinux 10 の初期設定の手順を指す | 同じ bash のブロックを書き写す: 片方だけ直したときに食い違う |
| bat の設定 | `BAT_CONFIG_PATH` か `BAT_CONFIG_DIR` の下（scoop の中）に、空のときだけ書く | `BAT_CONFIG_PATH` で `~/.config/bat/config` を読ませる: scoop の定義が向ける場所と二重になる。`bat --config-file` の出力を使う: 5.1 では、ASCII 以外の文字のフォルダー名が化ける |
| VC++ ランタイム | 無ければ「Windows 11 で WezTerm を入れる」の手順 3（管理者の窓） | extras の `vcredist2022` を scoop で入れる: extras のバケットを足す手順が増える |
| fzf の ASCII 以外の文字 | 変えない（手順 8 の補足だけ） | `FZF_DEFAULT_OPTS` に `--no-height`: 全画面で開き、AlmaLinux 10 と見た目が変わる。実機で確かめてから決める |

#### PowerShell 7 のプロファイルを設定する

- **Windows で CLI ツールを組み込むシェルは、Git Bash を主にする**
  - WezTerm の自分用の設定の Windows の `default_prog` は Git Bash（`C:/Program Files/Git/bin/bash.exe -i -l`。`lua/shells.lua`）。PowerShell 7・Windows PowerShell・WSL は、起動メニュー（Ctrl+Shift+M）から開く
  - 共通の bash 設定（README の「共通の bash 設定を先に入れる」）が、fzf・starship・zoxide・eza・bat・fd を `command -v` で見つけたときだけ読むので、Git Bash では、各ツールを入れるだけで効く。`~/.bashrc` には書かない
  - Claude Code の Bash ツールと、sshd の `DefaultShell`（[SSH の既定のシェルを Git Bash にする](../windows-setup.md#ssh-の既定のシェルを-git-bash-にする)）も Git Bash なので、bash の設定 1 つで済む
- **PowerShell 7 は補助**: この節で、starship と zoxide だけを、入っているときだけ読む。PSFzf・eza の関数・gh の補完・yazi の `y` は入れない（主のシェルの Git Bash に同じ機能がある。PSFzf はコミュニティのモジュール）
- **Windows PowerShell 5.1 は、既定では貼り付けの設定の行だけにする**: 任意の[Windows PowerShell 5.1 のキー操作を変える](../shell-terminal.md#windows-powershell-51-のキー操作を変える)で、Emacs と ↑↓ の履歴検索を足せる
  - プロファイルは、手順書を貼る管理者の conhost の窓でも読まれ、キーの操作が変わる。実機では確かめていない
  - starship と zoxide は 5.1 に足さない。見た目と起動の時間が変わり、SSH のセッションでは scoop の shim が RedirectionGuard で起動できないことがある
- **WSL の AlmaLinux 10 は Linux のホストとして扱う**: 各手順書の AlmaLinux 10 の実施手順と共通の bash 設定を、WSL の中で通す
- **Windows Terminal の既定のプロファイルは Windows PowerShell のまま**: PowerShell 7（`{574e775e-4f2a-5b96-ac1e-a2962a402336}`）にすると、Win+X の「ターミナル」などで開く窓が PowerShell 7 になり、5.1 でだけ動く手順（Windows の OpenSSH サーバーの `Add-WindowsCapability` など）を貼り違えやすい。PowerShell 7 は実行ポリシーとプロファイルも別に持つ。「Microsoft Store の更新」の手順 1 の窓で Windows Terminal が先に設定を作るので、「アプリを入れる」の手順 6 の後も既定は Windows PowerShell のままのはず（コードからの推測）

| 項目 | 採った方法 | 採らなかった方法と理由 |
|---|---|---|
| Tab の補完 | 条件付きの手順（この節の手順 3） | 既定で入れる: 好みが分かれる。bash に近い動き（共通する部分まで補完し、もう 1 回で一覧）が好みなら、`MenuComplete` の代わりに `Complete` |
| 予測 | 既定のまま（F2 で一覧に切り替え） | プロファイルに `-PredictionViewStyle ListView`: 既定で候補が出るので要らない |
| EditMode | 既定は Windows のまま。任意の手順で Emacs にできる | 先に付けたキーが既定に戻るので、EditMode の行をキーの割り当てより前に置く。Emacs に Ctrl+V の `Paste` が無いので割り当て直す |
| 履歴の件数 | 既定（4096） | `-MaximumHistoryCount 100000`（bash の `HISTSIZE` に合わせる）: 窓を開くたびに読む量が増える |
| 起動の更新の通知・テレメトリ | 変えない | `POWERSHELL_UPDATECHECK`・`POWERSHELL_TELEMETRY_OPTOUT`: プロファイルではなく環境変数。更新の通知はバナーを出す起動だけで、WezTerm の `-NoLogo` の起動には出ない |

### 参照

#### 共通の bash 設定

- [README の共通の bash 設定を先に入れる](../../README.md#共通の-bash-設定を先に入れる) と [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash) — 「共通の bash 設定」の手順 1〜4

- [Bash Reference Manual — Bash Variables](https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html)（`HISTSIZE`・`HISTFILESIZE`・`HISTCONTROL`・`HISTTIMEFORMAT`）
- [Bash Reference Manual — The Shopt Builtin](https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html)（`autocd`・`cdspell`・`dirspell`・`globstar`・`histappend`）
- [Bash Reference Manual — Readline Init File](https://www.gnu.org/software/bash/manual/html_node/Readline-Init-File.html)（`$include`、`completion-ignore-case`、`show-all-if-ambiguous`、`colored-stats`、`colored-completion-prefix`、`history-search-backward`）
- [bash-completion](https://github.com/scop/bash-completion)（`_completion_loader`、`BASH_COMPLETION_USER_DIR`、`XDG_DATA_DIRS`）
- [Homebrew — Shell Completion](https://docs.brew.sh/Shell-Completion)（`etc/bash_completion.d` を読む形）
- [fzf](../almalinux-setup.md) — Ctrl+R の履歴の検索と `**<Tab>`。Homebrew の補完の行との並び
- [Homebrew](../almalinux-setup.md) — `brew shellenv` の行（手順 3）

#### シェルのツール

##### starship

- [starship.rs](https://starship.rs/) — 公式サイト。インストールと各シェルでの `init` の書き方
- [starship — Configuration](https://starship.rs/config/) — `starship.toml` の全モジュールと項目
- [starship — Presets](https://starship.rs/presets/) — プリセット一覧とスクリーンショット、Nerd Font が要るかどうか
- `starship --help` / `starship init bash --print-full-init` — サブコマンドと、シェルに入る初期化の中身
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

##### zoxide

- [ajeetdsouza/zoxide — README](https://github.com/ajeetdsouza/zoxide) — 各 OS のインストール方法、シェルごとの `zoxide init` の書き方、`--cmd` の説明
- [zoxide — Installation](https://github.com/ajeetdsouza/zoxide#installation) — 公式 install.sh と各ディストリビューションの状況
- `zoxide --help` / `zoxide query --help` — `query --list` / `--score`、`remove`
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作
- [kray74/cli-tools — Copr](https://copr.fedorainfracloud.org/coprs/kray74/cli-tools/) — chroot（`epel-10-x86_64` と `fedora-44-x86_64`）とビルドの履歴
- [kray74/cli-tools — GitHub](https://github.com/kray74/cli-tools) — COPR の spec（`zoxide/zoxide.spec`）

##### fzf

- [fzf — README](https://github.com/junegunn/fzf#readme)（Key bindings for command-line、Fuzzy completion for bash、Search syntax、Environment variables）
- [fzf — ADVANCED.md](https://github.com/junegunn/fzf/blob/master/ADVANCED.md)（プレビューの例）
- `man fzf`（`--preview`・`--line-range` は bat 側）
- [Homebrew の fzf の formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/f/fzf.rb)（caveat の `fzf --bash`）
- [bash の履歴・補完・キー操作](../almalinux-setup.md) — bash-completion と Homebrew の補完、`~/.inputrc`。fzf の行との並び
- [zoxide](../almalinux-setup.md) — `zi` が fzf を使う。[yazi](../almalinux-setup.md#yazi) — `z` / `Z` キーが fzf を使う
- [bat](../almalinux-setup.md) — プレビューに使う。[Homebrew](../almalinux-setup.md) — Homebrew 本体の導入と、Homebrew 系に共通の注意

##### eza

- [eza-community/eza — README](https://github.com/eza-community/eza) — 使い方、各ディストリビューションでの入手方法、`ls` との違い
- [eza.rocks](https://eza.rocks) — 公式サイト。スクリーンショットと機能一覧
- `eza --help` / `man eza` — 全オプション（`--help` は 86 行）
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

##### bat

- [sharkdp/bat — README](https://github.com/sharkdp/bat) — 使い方、テーマ、`MANPAGER` や `fzf` との組み合わせ、他ツールとの連携例
- [bat — Customization](https://github.com/sharkdp/bat#customization) — 設定ファイルの書式、テーマとシンタックスの追加手順
- `bat --help` / `bat --list-themes` / `bat --list-languages` — フラグとテーマ・言語の一覧
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入手順、`/home/linuxbrew/.linuxbrew` に入れる理由、ボトルの条件、`brew` の基本操作

##### tmux

- [tmux — Getting Started](https://github.com/tmux/tmux/wiki/Getting-Started) — セッション・ウィンドウ・ペインとキーの説明
- `man tmux`（`new-session` の `-A` と `-d`、`attach-session` の `-d`、`history-limit`、`mouse`、設定ファイルを読む場所）
- [Homebrew の tmux の formula](https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/t/tmux.rb)
- [Continue local sessions from any device with Remote Control](https://code.claude.com/docs/en/remote-control) — `claude remote-control`、`--spawn`、Limitations（SSH の切断後も残すには tmux か screen、10 分の終了）、4 時間以内の再開
- [Interactive mode](https://code.claude.com/docs/en/interactive-mode) — `Ctrl+B`（tmux では 2 回）
- [Claude Code](../ai-agents.md#claude-code) — 導入とログイン、`claude` のコマンドラインの使い方
- [Claude Code の Remote Control（Windows）](../ai-agents.md#claude-code-の-remote-control-実施手順) — 同じことを Windows で行う手順書
- [Homebrew](../almalinux-setup.md) — Homebrew 本体の導入と、Homebrew 系に共通の注意

#### HackGen Console NF

- [yuru7/HackGen](https://github.com/yuru7/HackGen) — フォントの特徴、ファミリーの種類、ライセンス、リリース
- [Homebrew Formulae — font-hackgen-nerd](https://formulae.brew.sh/cask/font-hackgen-nerd) — cask の版と中身
- [Nerd Fonts](https://www.nerdfonts.com/) — 追加されているアイコンの一覧（コードポイントの確認に使える）
- `man fc-list` / `man fc-match` / `man fc-cache` — fontconfig の照会と、キャッシュの作り直し
- [WezTerm](../shell-terminal.md#wezterm) — WezTerm の導入と設定ファイルの置き場所
- [AlmaLinux 10 の初期設定](../almalinux-setup.md) — 「Homebrew」の手順 1〜3 が Homebrew 本体の導入手順。`brew` の基本操作は同書の「Homebrew の使い方の基本」
- [HackGen v2.10.0](https://github.com/yuru7/HackGen/releases/tag/v2.10.0) — Windows 11 の節で取る `HackGen_NF_v2.10.0.zip`
- [Join-Path（5.1）— Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/join-path?view=powershell-5.1) — `-Path` と `-ChildPath` だけ（scoop の個人のバケットを採らなかった理由）
- [matthewjberger/scoop-nerd-fonts](https://github.com/matthewjberger/scoop-nerd-fonts) — Windows で自分のユーザーにフォントを入れる定義（issue #198 のアクセス権）
- [mo-san/scoop-bucket](https://github.com/mo-san/scoop-bucket) — 採らなかった scoop の個人のバケット
- [Windows 11 の初期設定](../windows-setup.md) — Windows のインストール直後にまとめて行う設定（scoop・UniGet UI・Caps Lock・表示・電源・リモート デスクトップなど）。この節は、そのリードから案内される


#### シェルのツールを入れる

シェルのツールを入れる項の資料。「コード」の区別は上と同じ。

- コード: [ScoopInstaller/Main](https://github.com/ScoopInstaller/Main)（`bucket/fzf.json`・`zoxide.json`・`starship.json`・`eza.json`・`bat.json`。zoxide の 0.9.9 の定義は `f8683b6ce` の親）
- コード: [ScoopInstaller/Scoop](https://github.com/ScoopInstaller/Scoop)（v0.6.0。`lib/manifest.ps1` の `Find-HistoricalManifestInGit`・`generate_user_manifest`、`lib/install.ps1` の `env_add_path`・`env_set`・`persist_data`・`show_suggestions`・`test_running_process`・`prune_installed`、`lib/core.ps1` の `installed`、`lib/depends.ps1` の `Get-Dependency`、`lib/system.ps1` の `Add-Path`、`bin/scoop.ps1`、`libexec/scoop-install.ps1`・`scoop-update.ps1`（`Sync-Bucket`・`update`）・`scoop-hold.ps1`・`scoop-unhold.ps1`・`scoop-list.ps1`・`scoop-uninstall.ps1`、`CHANGELOG.md` の #6370・#6730）と [ScoopInstaller/Install](https://github.com/ScoopInstaller/Install)（`install.ps1`。git が無いときは、本体と main のバケットを zip で置く）
- コード: [ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide)（`templates/bash.txt` の v0.9.9・v0.10.0・`main`、`CHANGELOG.md`（`main`）、`src/db/mod.rs`、`.cargo/config.toml`、README の Windows の導入と `_ZO_DATA_DIR`）と、[issue #1259](https://github.com/ajeetdsouza/zoxide/issues/1259)・[PR #1260](https://github.com/ajeetdsouza/zoxide/pull/1260)・[Releases](https://github.com/ajeetdsouza/zoxide/releases)
- コード: [sharkdp/bat](https://github.com/sharkdp/bat)（v0.26.1 の `src/bin/bat/directories.rs`・`config.rs`）・[eza-community/eza](https://github.com/eza-community/eza)（v0.23.5 の `src/options/theme.rs`・`src/output/table.rs`・`src/fs/feature/git.rs`）・[junegunn/fzf](https://github.com/junegunn/fzf)（v0.74.4 の `CHANGELOG.md`・`src/util/util_windows.go`）・[starship/starship](https://github.com/starship/starship)（v1.26.0 の `src/context.rs`・`src/init/starship.ps1`・`.github/workflows/release.yml`）
- コード: [wezterm/wezterm](https://github.com/wezterm/wezterm)（`pty/src/cmdbuilder.rs` の `get_base_env`）と、自分用の設定の [ryo-aoki-pc/bash](https://github.com/ryo-aoki-pc/bash)（`bashrc`・`docs/install.md`・`docs/reference/readme.md` の「Windows 11 の Git Bash での違い」）
